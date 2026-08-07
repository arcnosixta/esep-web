// Диагностика env + реальный тестовый вызов Gemini (временный, удалить после проверки).
// Ключи НЕ выводятся — только флаги наличия и результат/ошибка тестового запроса.
const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta';

export async function onRequest(context) {
  const { env } = context;
  const out = {
    hasGeminiApiKey: !!env.GEMINI_API_KEY,
    hasOpenRouterApiKey: !!env.OPENROUTER_API_KEY,
    envKeys: Object.keys(env).filter((k) => /KEY|TOKEN|SECRET|API|MODEL/i.test(k)).sort(),
  };

  const key = env.GEMINI_API_KEY;
  if (key) {
    // 1. Список доступных моделей (проверка валидности ключа + наличие flash-lite)
    try {
      const r = await fetch(`${GEMINI_BASE}/models?key=${encodeURIComponent(key)}`);
      const j = await r.json();
      out.modelsStatus = r.status;
      const names = (j.models || []).map((m) => m.name.replace('models/', ''));
      out.hasFlashLite = names.includes('gemini-2.5-flash-lite');
      out.hasFlash = names.includes('gemini-2.5-flash');
      out.someModels = names.slice(0, 12);
      out.totalModels = names.length;
      if (!r.ok) out.modelsError = JSON.stringify(j).slice(0, 300);
    } catch (e) {
      out.modelsFetchError = String(e).slice(0, 200);
    }

    // 2. Тест кандидатов моделей (какие реально отвечают новому ключу)
    const candidates = ['gemini-flash-lite-latest', 'gemini-2.0-flash-lite', 'gemini-2.5-flash', 'gemini-flash-latest'];
    out.modelTests = [];
    for (const m of candidates) {
      try {
        const body = {
          contents: [{ role: 'user', parts: [{ text: 'Ответь одним словом: 2+2?' }] }],
        };
        const r = await fetch(
          `${GEMINI_BASE}/models/${encodeURIComponent(m)}:generateContent?key=${encodeURIComponent(key)}`,
          { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }
        );
        const j = await r.json();
        if (r.ok) {
          const cands = j.candidates || [];
          const parts = (cands[0] && cands[0].content && cands[0].content.parts) || [];
          out.modelTests.push({ model: m, status: r.status, answer: parts.map((p) => p.text || '').join('').slice(0, 50) });
        } else {
          out.modelTests.push({ model: m, status: r.status, error: JSON.stringify(j).slice(0, 160) });
        }
      } catch (e) {
        out.modelTests.push({ model: m, status: 'FETCH_ERR', error: String(e).slice(0, 160) });
      }
    }

    // 3. Тестовый generateContent с google_search (как в chat.js)
    try {
      const body = {
        contents: [{ role: 'user', parts: [{ text: 'Какая столица Казахстана? Ответь одним словом.' }] }],
        tools: [{ google_search: {} }],
      };
      const r = await fetch(
        `${GEMINI_BASE}/models/gemini-2.5-flash:generateContent?key=${encodeURIComponent(key)}`,
        { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }
      );
      const j = await r.json();
      out.testStatus = r.status;
      if (r.ok) {
        const cands = j.candidates || [];
        const parts = (cands[0] && cands[0].content && cands[0].content.parts) || [];
        out.testAnswer = parts.map((p) => p.text || '').join('').slice(0, 200);
        out.hasGrounding = !!(cands[0] && cands[0].groundingMetadata);
      } else {
        out.testError = JSON.stringify(j).slice(0, 400);
      }
    } catch (e) {
      out.testFetchError = String(e).slice(0, 200);
    }
  }

  return new Response(JSON.stringify(out, null, 2), {
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });
}
