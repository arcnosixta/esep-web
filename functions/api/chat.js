// Cloudflare Pages Function — прокси для OpenRouter.
// Ключ OPENROUTER_API_KEY живёт ТОЛЬКО на сервере (Pages → Settings →
// Environment variables → Production secret). Клиентский код его не знает.
//
// Маршрут:  POST /api/chat
// Тело:     {model, messages, stream, ...} — пробрасывается как есть.
// Ответ:    обычный JSON или SSE-поток (text/event-stream), если stream=true.

const UPSTREAM = 'https://openrouter.ai/api/v1/chat/completions';

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

export async function onRequestPost(context) {
  const { request, env } = context;

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }

  const apiKey = env.OPENROUTER_API_KEY;
  if (!apiKey) {
    return json({ error: 'OPENROUTER_API_KEY is not configured on the server' }, 500, corsHeaders(request));
  }

  let body;
  try {
    body = await request.json();
  } catch (_) {
    return json({ error: 'Invalid JSON body' }, 400, corsHeaders(request));
  }

  const upstream = await fetch(UPSTREAM, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      'HTTP-Referer': env.SITE_URL || 'https://esep.pages.dev',
      'X-OpenRouter-Title': 'ESEP Appraiser',
    },
    body: JSON.stringify(body),
  });

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

export async function onRequest(context) {
  const { request } = context;
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }
  return json({ error: 'Method not allowed. Use POST /api/chat' }, 405, corsHeaders(request));
}
