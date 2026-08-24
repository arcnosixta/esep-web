// Cloudflare Pages Function — XPayment (ЗАГЛУШКА).
//
// Сюда потом встроим интеграцию с XPayment:
//   POST /api/xpayment/create     — создать сессию оплаты
//   POST /api/xpayment/webhook    — приём статуса от XPayment
//   GET  /api/xpayment/checkout   — заглушка checkout-страницы (при необходимости)
//
// Env-переменные (добавить в Pages Settings, когда появится провайдер):
//   XPAYMENT_API_KEY / XPAYMENT_SECRET / SUPABASE_* ...

const JSON_HEADERS = {
  'Content-Type': 'application/json; charset=utf-8',
  'Cache-Control': 'no-store',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: JSON_HEADERS });
}
function jsonError(message, status) {
  return json({ error: message }, status);
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: JSON_HEADERS });
    }

    if (url.pathname === '/api/xpayment/create' && request.method === 'POST') {
      return jsonError('Not implemented', 501);
    }

    if (url.pathname === '/api/xpayment/webhook' && request.method === 'POST') {
      return jsonError('Not implemented', 501);
    }

    return jsonError('Not found', 404);
  },
};
