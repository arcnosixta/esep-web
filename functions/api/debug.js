// Временная диагностика: flash-lite с tools google_search и без (удалить после проверки).
const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta';

export async function onRequest(context) {
  const { env } = context;
  const key = env.GEMINI_API_KEY;
  const out = { hasGemini: !!key };
  if (!key) return new Response(JSON.stringify(out), { headers: { 'Content-Type': 'application/json' } });

  async function test(name, model, withTools, withConfig) {
    const body = { contents: [{ role: 'user', parts: [{ text: 'Ответь одним словом: 2+2?' }] }] };
    if (withTools) body.tools = [{ google_search: {} }];
    if (withConfig) body.generationConfig = { maxOutputTokens: 4096, temperature: 0.7, topP: 0.9 };
    try {
      const r = await fetch(`${GEMINI_BASE}/models/${model}:generateContent?key=${encodeURIComponent(key)}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
      });
      const j = await r.json();
      if (r.ok) {
        const parts = ((j.candidates || [])[0]?.content?.parts) || [];
        out[name] = { status: r.status, answer: parts.map((p) => p.text || '').join('').slice(0, 60), grounding: !!(j.candidates?.[0]?.groundingMetadata) };
      } else {
        out[name] = { status: r.status, error: JSON.stringify(j).slice(0, 200) };
      }
    } catch (e) {
      out[name] = { status: 'FETCH_ERR', error: String(e).slice(0, 200) };
    }
  }

  await test('lite_no_tools', 'gemini-flash-lite-latest', false, false);
  await test('lite_tools', 'gemini-flash-lite-latest', true, false);
  await test('lite_tools_config', 'gemini-flash-lite-latest', true, true);
  await test('flash_tools_config', 'gemini-2.5-flash', true, true);

  return new Response(JSON.stringify(out, null, 1), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
}
