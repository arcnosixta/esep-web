// Диагностика env для Pages Functions (временный, удалить после проверки).
// Возвращает ТОЛЬКО имена и флаги наличия — значения секретов НЕ выводятся.
export async function onRequest(context) {
  const { env } = context;
  const names = Object.keys(env).filter((k) => /KEY|TOKEN|SECRET|API|MODEL/i.test(k)).sort();
  return new Response(
    JSON.stringify({
      hasGeminiApiKey: !!env.GEMINI_API_KEY,
      hasOpenRouterApiKey: !!env.OPENROUTER_API_KEY,
      geminiVisionModel: env.GEMINI_VISION_MODEL || null,
      geminiTextModel: env.GEMINI_TEXT_MODEL || null,
      envKeys: names,
      allKeys: Object.keys(env).sort(),
    }, null, 2),
    { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
  );
}
