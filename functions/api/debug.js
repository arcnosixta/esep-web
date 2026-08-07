// Временная диагностика: vision на flash-lite vs flash (удалить после проверки).
const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta';

export async function onRequest(context) {
  const { env } = context;
  const key = env.GEMINI_API_KEY;
  const out = { hasGemini: !!key };
  if (!key) return new Response(JSON.stringify(out), { headers: { 'Content-Type': 'application/json' } });

  // 1x1 зелёный PNG (валидный inline_data)
  const pngB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

  async function test(name, model, withTools) {
    const body = {
      contents: [{ role: 'user', parts: [
        { text: 'Что на фото? Одно слово.' },
        { inline_data: { mime_type: 'image/png', data: pngB64 } },
      ] }],
    };
    if (withTools) body.tools = [{ google_search: {} }];
    try {
      const r = await fetch(`${GEMINI_BASE}/models/${model}:generateContent?key=${encodeURIComponent(key)}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
      });
      const j = await r.json();
      if (r.ok) {
        const parts = ((j.candidates || [])[0]?.content?.parts) || [];
        out[name] = { status: r.status, answer: parts.map((p) => p.text || '').join('').slice(0, 80), grounding: !!(j.candidates?.[0]?.groundingMetadata) };
      } else {
        out[name] = { status: r.status, error: JSON.stringify(j).slice(0, 220) };
      }
    } catch (e) {
      out[name] = { status: 'FETCH_ERR', error: String(e).slice(0, 200) };
    }
  }

  await test('lite_vision', 'gemini-flash-lite-latest', false);
  await test('flash_vision_tools', 'gemini-2.5-flash', true);
  await test('flash_text', 'gemini-2.5-flash', false);

  return new Response(JSON.stringify(out, null, 1), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
}
