// Cloudflare Pages Function — Kaspi Pay (ЗАГЛУШКА/СТАБ).
//
// Статус: интеграция в режиме разработки. Реальный Kaspi Pay (merchant API)
// подключается после договора с Kaspi; пока работают два эндпоинта:
//
//   POST /api/kaspi/create     — клиент из приложения: создаёт платёж
//                                (status=pending, provider='kaspi') и
//                                возвращает checkout_url на мок-страницу.
//   GET  /api/kaspi/checkout   — мок-страница оплаты (тестовый режим).
//   POST /api/kaspi/webhook    — сюда Kaspi (или мок-страница) шлёт статус
//                                платежа; при success помечаем платёж paid
//                                и заявку paid.
//
// Env-переменные:
//   SUPABASE_URL, SUPABASE_ANON_KEY   — JWT-авторизация (как в chat.js)
//   SUPABASE_SERVICE_ROLE_KEY         — серверная запись (confirmPayment)
//   KASPI_MERCHANT_ID                 — TODO: id мерчанта Kaspi (заглушка)
//   KASPI_SECRET_KEY                  — TODO: секрет Kaspi для проверки
//                                       подписи вебхука (заглушка)
//
// БЕЗОПАСНОСТЬ: в production вебхук обязан проверять подпись Kaspi.
// Пока секрет не задан — вебхук работает только в тестовом режиме
// (KASPI_TEST_MODE=1) и отвечает 503 всем остальным запросам.

const JSON_HEADERS = {
  'Content-Type': 'application/json; charset=utf-8',
  'Cache-Control': 'no-store',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Kaspi-Signature',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: JSON_HEADERS });
}
function jsonError(message, status) {
  return json({ error: message }, status);
}

// ── JWT-авторизация пользователя (тот же паттерн, что в chat.js) ──────
async function authorizeRequest(request, env) {
  if (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) return null;
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return { status: 401, message: 'Unauthorized: missing Bearer token' };
  const token = auth.slice(7).trim();
  if (!token) return { status: 401, message: 'Unauthorized: empty token' };
  try {
    const resp = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${token}`, apikey: env.SUPABASE_ANON_KEY },
    });
    if (!resp.ok) return { status: 401, message: 'Unauthorized: invalid token' };
  } catch (_) {
    return { status: 503, message: 'Auth service unavailable' };
  }
  return null;
}

// ── Вспомогательные вызовы Supabase REST (service role) ────────────────
function sbHeaders(env) {
  return {
    apikey: env.SUPABASE_SERVICE_ROLE_KEY,
    Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    'Content-Type': 'application/json',
  };
}

async function confirmPaymentServerSide(env, paymentId) {
  // 1) Платёж → paid
  const payRes = await fetch(
    `${env.SUPABASE_URL}/rest/v1/payments?id=eq.${paymentId}&select=application_id`,
    {
      method: 'PATCH',
      headers: { ...sbHeaders(env), Prefer: 'return=representation' },
      body: JSON.stringify({
        status: 'paid',
        confirmed_at: new Date().toISOString(),
        confirmed_by: 'kaspi_webhook',
      }),
    },
  );
  if (!payRes.ok) return { ok: false, error: 'payments update failed' };
  const rows = await payRes.json();
  const appId = rows?.[0]?.application_id;
  if (!appId) return { ok: true }; // платёж без заявки — нечего подтверждать

  // 2) Заявка → paid
  await fetch(`${env.SUPABASE_URL}/rest/v1/applications?id=eq.${appId}`, {
    method: 'PATCH',
    headers: { ...sbHeaders(env), Prefer: 'return=minimal' },
    body: JSON.stringify({ status: 'paid' }),
  });

  // 3) Отчёт заявки → paid (клиент получает официальный PDF)
  const repRes = await fetch(
    `${env.SUPABASE_URL}/rest/v1/reports?application_id=eq.${appId}&select=id`,
    { headers: sbHeaders(env) },
  );
  if (repRes.ok) {
    const reps = await repRes.json();
    for (const r of reps) {
      await fetch(`${env.SUPABASE_URL}/rest/v1/reports?id=eq.${r.id}`, {
        method: 'PATCH',
        headers: { ...sbHeaders(env), Prefer: 'return=minimal' },
        body: JSON.stringify({ is_paid: true, status: 'paid' }),
      });
    }
  }
  return { ok: true };
}

// ── Роутер ─────────────────────────────────────────────────────────────
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: JSON_HEADERS });

    // ── POST /api/kaspi/create ─────────────────────────────────────────
    if (pathname === '/api/kaspi/create' && request.method === 'POST') {
      const authErr = await authorizeRequest(request, env);
      if (authErr) return jsonError(authErr.message, authErr.status);

      let body;
      try { body = await request.json(); } catch (_) { return jsonError('Invalid JSON', 400); }
      const { application_id: appId, amount } = body;
      if (!appId || !amount) return jsonError('application_id and amount required', 400);

      // Создаём платёж как pending (provider='kaspi').
      const insRes = await fetch(`${env.SUPABASE_URL}/rest/v1/payments`, {
        method: 'POST',
        headers: { ...sbHeaders(env), Prefer: 'return=representation' },
        body: JSON.stringify({
          application_id: appId,
          amount,
          method: 'kaspi_online',
          status: 'pending',
          provider: 'kaspi',
        }),
      });
      if (!insRes.ok) return jsonError('Failed to create payment', 502);
      const created = (await insRes.json())?.[0];

      // Заявка → pending_payment
      await fetch(`${env.SUPABASE_URL}/rest/v1/applications?id=eq.${appId}`, {
        method: 'PATCH',
        headers: { ...sbHeaders(env), Prefer: 'return=minimal' },
        body: JSON.stringify({ status: 'pending_payment' }),
      });

      // TODO: реальный Kaspi Pay — здесь создаём платёж в Kaspi API:
      //   fetch('https://kaspi.kz/merchant/v2/orders', {
      //     headers: { Authorization: `Bearer ${env.KASPI_SECRET_KEY}` },
      //     body: { amount, currency: 'KZT', merchantId: env.KASPI_MERCHANT_ID,
      //             merchantUid: paymentId, ... }
      //   }) → возвращает kaspi_url.
      const origin = url.origin;
      return json({
        payment_id: created.id,
        checkout_url: `${origin}/api/kaspi/checkout?payment_id=${created.id}&amount=${amount}`,
        test_mode: !env.KASPI_SECRET_KEY,
      });
    }

    // ── GET /api/kaspi/checkout (мок-страница оплаты) ──────────────────
    if (pathname === '/api/kaspi/checkout' && request.method === 'GET') {
      const paymentId = url.searchParams.get('payment_id') || '';
      const amount = url.searchParams.get('amount') || '0';
      const testMode = !env.KASPI_SECRET_KEY;
      const html = `<!doctype html><html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kaspi Pay — ESEP</title><style>
body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:#f6f6f6;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
.card{background:#fff;border-radius:16px;padding:32px;max-width:400px;width:90%;box-shadow:0 4px 24px rgba(0,0,0,.08);text-align:center}
.logo{font-size:22px;font-weight:700;color:#1a1a1a;margin-bottom:4px}
.sub{color:#666;font-size:13px;margin-bottom:24px}
.amount{font-size:34px;font-weight:700;color:#1a1a1a;margin-bottom:24px}
.badge{display:inline-block;background:#fff4e5;color:#b45309;font-size:12px;padding:4px 10px;border-radius:99px;margin-bottom:16px}
.btn{background:#f14635;color:#fff;border:none;border-radius:12px;padding:14px 0;width:100%;font-size:16px;font-weight:600;cursor:pointer}
.btn:disabled{opacity:.6;cursor:wait}
.status{margin-top:16px;font-size:14px;color:#16a34a;display:none}
.err{margin-top:16px;font-size:14px;color:#dc2626;display:none}
</style></head><body>
<div class="card">
  <div class="logo">ESEP</div>
  <div class="sub">Официальный отчёт об оценке · ТОО «GaMa Group»</div>
  ${testMode ? '<div class="badge">ТЕСТОВЫЙ РЕЖИМ — реальный Kaspi Pay будет подключён после договора с Kaspi</div>' : ''}
  <div class="amount">${Number(amount).toLocaleString('ru-RU')} ₸</div>
  <button class="btn" id="pay">Оплатить через Kaspi Pay</button>
  <div class="status" id="status">✅ Платёж подтверждён! Можете закрыть вкладку.</div>
  <div class="err" id="err"></div>
</div>
<script>
const payBtn = document.getElementById('pay');
const statusEl = document.getElementById('status');
const errEl = document.getElementById('err');
payBtn.onclick = async () => {
  payBtn.disabled = true; payBtn.textContent = 'Обработка…';
  try {
    const r = await fetch('/api/kaspi/webhook', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({payment_id: ${JSON.stringify(paymentId)}, test: true}),
    });
    if (!r.ok) throw new Error((await r.json()).error || 'Ошибка');
    statusEl.style.display = 'block';
    payBtn.style.display = 'none';
  } catch (e) {
    errEl.textContent = 'Ошибка: ' + e.message;
    errEl.style.display = 'block';
    payBtn.disabled = false; payBtn.textContent = 'Оплатить через Kaspi Pay';
  }
};
</script></body></html>`;
      return new Response(html, { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' } });
    }

    // ── POST /api/kaspi/webhook ────────────────────────────────────────
    if (pathname === '/api/kaspi/webhook' && request.method === 'POST') {
      let body;
      try { body = await request.json(); } catch (_) { return jsonError('Invalid JSON', 400); }
      const { payment_id: paymentId, test } = body;
      if (!paymentId) return jsonError('payment_id required', 400);

      // Проверка подписи Kaspi (TODO): реальная схема — HMAC-SHA256 от тела
      // с KASPI_SECRET_KEY (заголовок X-Kaspi-Signature). Заглушка:
      //   - если KASPI_SECRET_KEY задан → сверяем сигнатуру;
      //   - если не задан → принимаем только test-запросы.
      const signature = request.headers.get('X-Kaspi-Signature') || '';
      if (env.KASPI_SECRET_KEY) {
        const expected = await crypto.subtle
          .digest('SHA-256', new TextEncoder().encode(JSON.stringify(body) + env.KASPI_SECRET_KEY))
          .then((b) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, '0')).join(''));
        if (signature !== expected) return jsonError('Invalid signature', 401);
      } else if (test !== true) {
        return jsonError('Webhook not configured (KASPI_SECRET_KEY missing)', 503);
      }

      if (body.status === 'failed') {
        await fetch(`${env.SUPABASE_URL}/rest/v1/payments?id=eq.${paymentId}`, {
          method: 'PATCH',
          headers: { ...sbHeaders(env), Prefer: 'return=minimal' },
          body: JSON.stringify({ status: 'failed' }),
        });
        return json({ ok: true, status: 'failed' });
      }

      const res = await confirmPaymentServerSide(env, paymentId);
      if (!res.ok) return jsonError(res.error, 502);
      return json({ ok: true, status: 'paid' });
    }

    return jsonError('Not found', 404);
  },
};
