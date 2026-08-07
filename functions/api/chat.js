// Cloudflare Pages Function — прокси-роутер для ИИ-чата ESEP.
//
// РОУТИНГ (экономия токенов на продакшене):
//   - Сообщения БЕЗ картинок (просто текст) -> дешёвая текстовая модель:
//       GEMINI_TEXT_MODEL (по умолчанию gemini-2.5-flash-lite, есть поиск)
//   - Сообщения С картинками (фото страховки/объекта) -> vision-модель:
//       GEMINI_VISION_MODEL (по умолчанию gemini-2.5-flash, vision + google_search)
//   - Если GEMINI_API_KEY не задан — прозрачный фолбэк на OpenRouter
//     (клиентские model id вида 'gemini-*' заменяются на бесплатные
//     google/gemma-4-*-it:free, всё остальное пробрасывается как раньше).
//
// СЕКРЕТЫ (только на сервере, Pages -> Settings -> Environment variables):
//   OPENROUTER_API_KEY  — был раньше, остаётся как фолбэк.
//   GEMINI_API_KEY      — новый основной ключ (бесплатный, aistudio.google.com/apikey).
//   GEMINI_TEXT_MODEL    — опционально: текстовая модель (default gemini-2.5-flash-lite).
//   GEMINI_VISION_MODEL  — опционально: vision-модель (default gemini-2.5-flash).
//
// Маршрут:  POST /api/chat
// Тело:     OpenAI-формат {model, messages, stream, ...} — клиент НЕ меняется.
// Ответ:    OpenAI-формат (JSON или SSE text/event-stream), клиент парсит как раньше.

const OR_BASE = 'https://openrouter.ai/api/v1/chat/completions';
const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

// OpenRouter-фолбэки, когда GEMINI_API_KEY не задан, а клиент прислал 'gemini-*' id.
const OR_TEXT_FALLBACK = 'google/gemma-4-31b-it:free';
const OR_VISION_FALLBACK = 'google/gemma-4-26b-a4b-it:free';

// Устаревшие имена моделей -> актуальные (Google выводит старые модели из доступа
// для новых ключей: gemini-2.5-flash-lite -> 404 "no longer available to new users").
const GEMINI_MODEL_ALIASES = {
  'gemini-2.5-flash-lite': 'gemini-flash-lite-latest',
  'gemini-2.0-flash-lite': 'gemini-flash-lite-latest',
};

function json(obj, status, extra = {}) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json', ...extra },
  });
}

function corsHeaders(request) {
  const origin = request.headers.get('Origin') || '*';
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

function hasImages(messages) {
  return (messages || []).some((m) => {
    const c = m && m.content;
    return Array.isArray(c) && c.some((p) => p && p.type === 'image_url');
  });
}

// ============================================================
// GEMINI: конвертация OpenAI-формата в нативный Gemini
// ============================================================

function pickGeminiModel(body, hasImg, env) {
  const clientModel = (body.model || '').trim();
  if (clientModel.startsWith('gemini-')) {
    return GEMINI_MODEL_ALIASES[clientModel] || clientModel;
  }
  return hasImg
    ? (env.GEMINI_VISION_MODEL || 'gemini-2.5-flash')
    : (env.GEMINI_TEXT_MODEL || 'gemini-flash-lite-latest');
}

function toGeminiParts(content) {
  if (typeof content === 'string') {
    return content ? [{ text: content }] : [];
  }
  const parts = [];
  for (const p of content || []) {
    if (!p) continue;
    if (p.type === 'text' && p.text) {
      parts.push({ text: p.text });
    } else if (p.type === 'image_url' && p.image_url && p.image_url.url) {
      const m = /^data:(image\/[a-z0-9+.-]+);base64,(.+)$/s.exec(p.image_url.url);
      if (m) {
        parts.push({ inline_data: { mime_type: m[1], data: m[2] } });
      } else if (/^https?:\/\//.test(p.image_url.url)) {
        parts.push({ file_data: { mime_type: 'image/jpeg', file_uri: p.image_url.url } });
      }
    }
  }
  return parts;
}

function toGeminiBody(body) {
  const systemParts = [];
  const contents = [];
  for (const m of body.messages || []) {
    if (!m) continue;
    if (m.role === 'system') {
      if (typeof m.content === 'string' && m.content) systemParts.push({ text: m.content });
      continue;
    }
    const role = m.role === 'assistant' ? 'model' : 'user';
    const parts = toGeminiParts(m.content);
    if (parts.length) contents.push({ role, parts });
  }
  const gem = {
    contents,
    // Живой поиск в интернете: ссылки-доказательства (krisha/olx/kn и др.)
    tools: [{ google_search: {} }],
    generationConfig: {
      maxOutputTokens: body.max_tokens || 4096,
      temperature: body.temperature ?? 0.7,
      topP: body.top_p ?? 0.9,
    },
  };
  if (systemParts.length) gem.systemInstruction = { parts: systemParts };
  return gem;
}

function sourcesFromGrounding(gm) {
  if (!gm || !Array.isArray(gm.groundingChunks)) return '';
  const lines = [];
  for (const ch of gm.groundingChunks) {
    const w = ch && ch.web;
    if (w && w.uri) lines.push(`- ${w.title ? w.title : w.uri}: ${w.uri}`);
  }
  return lines.length ? '\n\n📎 Источники:\n' + lines.join('\n') : '';
}

function textFromGeminiPayload(payload) {
  const cands = payload.candidates || [];
  const parts = cands[0] && cands[0].content && cands[0].content.parts;
  return parts ? parts.map((p) => p.text || '').join('') : '';
}

async function callGemini(model, gemBody, apiKey, stream) {
  const url = `${GEMINI_BASE}/${encodeURIComponent(model)}:${stream ? 'streamGenerateContent?alt=sse' : 'generateContent'}`;
  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
    body: JSON.stringify(gemBody),
  });
  if (!resp.ok) {
    let detail = '';
    try { detail = await resp.text(); } catch (_) {}
    throw new Error(`Gemini HTTP ${resp.status}: ${detail.slice(0, 300)}`);
  }
  return resp;
}

// ============================================================
// OPENROUTER: прежний прозрачный проброс
// ============================================================

async function proxyOpenRouter(body, env, request, overrideModel) {
  const apiKey = env.OPENROUTER_API_KEY;
  if (!apiKey) throw new Error('OPENROUTER_API_KEY is not configured');
  const payload = { ...body };
  if (overrideModel) payload.model = overrideModel;
  const upstream = await fetch(OR_BASE, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      'HTTP-Referer': env.SITE_URL || 'https://esep.pages.dev',
      'X-OpenRouter-Title': 'ESEP Appraiser',
    },
    body: JSON.stringify(payload),
  });
  return upstream;
}

function wrapOpenRouterResponse(upstream, body, request) {
  const headers = new Headers(upstream.headers);
  const cors = corsHeaders(request);
  for (const [k, v] of Object.entries(cors)) headers.set(k, v);
  if (body.stream === true) {
    headers.set('Content-Type', 'text/event-stream');
    headers.set('Cache-Control', 'no-cache');
    headers.set('Connection', 'keep-alive');
  }
  return new Response(upstream.body, { status: upstream.status, headers });
}

// ============================================================
// GEMINI -> OpenAI-совместимый ответ (SSE и JSON)
// ============================================================

function geminiStreamToOpenAI(resp, request) {
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const encoder = new TextEncoder();

  (async () => {
    const reader = resp.body.getReader();
    const decoder = new TextDecoder();
    let buf = '';
    let sources = '';
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += decoder.decode(value, { stream: true });
        const lines = buf.split('\n');
        buf = lines.pop();
        for (const line of lines) {
          const t = line.trim();
          if (!t.startsWith('data: ')) continue;
          const data = t.slice(6);
          if (data === '[DONE]') continue;
          let payload;
          try { payload = JSON.parse(data); } catch (_) { continue; }
          if (payload.candidates && payload.candidates[0] && payload.candidates[0].groundingMetadata) {
            sources = sourcesFromGrounding(payload.candidates[0].groundingMetadata);
          }
          const text = textFromGeminiPayload(payload);
          if (text) {
            await writer.write(encoder.encode(
              `data: ${JSON.stringify({ choices: [{ index: 0, delta: { content: text }, finish_reason: null }] })}\n\n`
            ));
          }
        }
      }
      if (sources) {
        await writer.write(encoder.encode(
          `data: ${JSON.stringify({ choices: [{ index: 0, delta: { content: sources }, finish_reason: null }] })}\n\n`
        ));
      }
      await writer.write(encoder.encode('data: [DONE]\n\n'));
    } catch (e) {
      try {
        await writer.write(encoder.encode(
          `data: ${JSON.stringify({ choices: [{ index: 0, delta: { content: `\n[Ошибка] ${String(e).slice(0, 200)}` }, finish_reason: null }] })}\n\n`
        ));
        await writer.write(encoder.encode('data: [DONE]\n\n'));
      } catch (_) {}
    } finally {
      try { await writer.close(); } catch (_) {}
    }
  })();

  return new Response(readable, {
    status: 200,
    headers: {
      ...corsHeaders(request),
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}

// ============================================================
// ENTRY POINT
// ============================================================

export async function onRequestPost(context) {
  const { request, env } = context;

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }

  let body;
  try {
    body = await request.json();
  } catch (_) {
    return json({ error: 'Invalid JSON body' }, 400, corsHeaders(request));
  }

  const hasImg = hasImages(body.messages);
  const geminiKey = env.GEMINI_API_KEY;

  // --- Основной путь: Gemini (vision+поиск для фото, лайт для текста) ---
  if (geminiKey) {
    try {
      const model = pickGeminiModel(body, hasImg, env);
      const gemBody = toGeminiBody(body);
      const stream = body.stream === true;
      const resp = await callGemini(model, gemBody, geminiKey, stream);

      if (stream) {
        return geminiStreamToOpenAI(resp, request);
      }

      const raw = await resp.text();
      let gem;
      try { gem = JSON.parse(raw); } catch (_) { throw new Error('Bad Gemini JSON'); }
      let content = textFromGeminiPayload(gem);
      if (gem.candidates && gem.candidates[0] && gem.candidates[0].groundingMetadata) {
        content += sourcesFromGrounding(gem.candidates[0].groundingMetadata);
      }
      return json({
        id: 'chatcmpl-gemini',
        object: 'chat.completion',
        created: Math.floor(Date.now() / 1000),
        model,
        choices: [{ index: 0, message: { role: 'assistant', content }, finish_reason: 'stop' }],
      }, 200, corsHeaders(request));
    } catch (e) {
      // Gemini недоступен/лимит -> фолбэк на OpenRouter
      console.error('[chat.js] Gemini failed, fallback to OpenRouter:', String(e).slice(0, 300));
    }
  }

  // --- Фолбэк: OpenRouter (как работало раньше) ---
  const apiKey = env.OPENROUTER_API_KEY;
  if (!apiKey) {
    return json({ error: 'Neither GEMINI_API_KEY nor OPENROUTER_API_KEY configured' }, 500, corsHeaders(request));
  }

  let overrideModel = null;
  if ((body.model || '').startsWith('gemini-')) {
    // Клиент просит Gemini, но ключа нет — подменяем на бесплатный OpenRouter-аналог
    overrideModel = hasImg ? OR_VISION_FALLBACK : OR_TEXT_FALLBACK;
  }

  try {
    const upstream = await proxyOpenRouter(body, env, request, overrideModel);
    return wrapOpenRouterResponse(upstream, body, request);
  } catch (e) {
    return json({ error: String(e) }, 500, corsHeaders(request));
  }
}

export async function onRequest(context) {
  const { request } = context;
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }
  return json({ error: 'Method not allowed. Use POST /api/chat' }, 405, corsHeaders(request));
}
