// Временная диагностика: реальные лимиты flash-lite (удалить после проверки).
const GEMINI_BASE = 'https://generativelanguage.googleapis.com/v1beta';

export async function onRequest(context) {
  const { env } = context;
  const key = env.GEMINI_API_KEY;
  const out = { hasGemini: !!key };
  if (!key) return new Response(JSON.stringify(out), { headers: { 'Content-Type': 'application/json' } });

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  async function test(name, body) {
    try {
      const r = await fetch(`${GEMINI_BASE}/models/gemini-flash-lite-latest:generateContent?key=${encodeURIComponent(key)}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
      });
      const j = await r.json();
      if (r.ok) {
        const parts = ((j.candidates || [])[0]?.content?.parts) || [];
        out[name] = { status: r.status, answer: parts.map((p) => p.text || '').join('').slice(0, 40) };
      } else {
        out[name] = { status: r.status, error: JSON.stringify(j).slice(0, 160) };
      }
    } catch (e) {
      out[name] = { status: 'FETCH_ERR', error: String(e).slice(0, 160) };
    }
  }

  const pngB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  const textBody = { contents: [{ role: 'user', parts: [{ text: '2+2?' }] }] };
  const visionBody = { contents: [{ role: 'user', parts: [{ text: 'Что на фото? Одно слово.' }, { inline_data: { mime_type: 'image/png', data: pngB64 } }] }] };

  out.start = new Date().toISOString();
  await test('t1_text', textBody);
  await sleep(4000);
  await test('t2_vision', visionBody);
  await sleep(4000);
  await test('t3_text_again', textBody);
  await sleep(4000);
  await test('t4_vision_again', visionBody);

  return new Response(JSON.stringify(out, null, 1), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
}
