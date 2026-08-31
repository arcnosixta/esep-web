// /api/v1/b2b/webhooks — управление webhook-подпиской компании
// GET  => текущий webhook
// POST => сохранить/обновить webhook
// DELETE => удалить webhook
import { json, jsonError } from '../../_auth.js';
import { b2bCompanyAuth, rateLimitHeaders } from '../_b2b.js';

function mapWebhook(row) {
  return {
    id: row.id,
    url: row.url,
    secret: row.secret ? '***' : null,
    events: row.events ?? [],
    active: row.active ?? true,
    updated_at: row.updated_at,
  };
}

export async function onRequestGet(context) {
  const { request, env } = context;
  const auth = await b2bCompanyAuth(request, env);
  if (!auth.ok) return jsonError(auth.error, auth.status);

  const res = await fetch(
    `${env.SUPABASE_URL}/rest/v1/webhooks?company_id=eq.${auth.company.id}&select=*`,
    {
      headers: {
        apikey: env.SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
    }
  );

  const rows = await res.json();
  if (!res.ok) return jsonError('Failed to load webhook', 500);
  const item = rows[0] ?? null;
  return json(
    { item },
    200,
    { ...rateLimitHeaders(auth.company.rate_limit_per_min) }
  );
}

export async function onRequestPost(context) {
  const { request, env } = context;
  const auth = await b2bCompanyAuth(request, env);
  if (!auth.ok) return jsonError(auth.error, auth.status);

  let body;
  try {
    body = await request.json();
  } catch (e) {
    return jsonError('Invalid JSON', 400);
  }

  const url = String(body?.url ?? '').trim();
  if (!url) return jsonError('url is required', 400);
  const secret = body?.secret ? String(body.secret).trim() : null;
  const events = Array.isArray(body?.events) ? body.events.filter((x) => typeof x === 'string') : [];

  const now = new Date().toISOString();
  const payload = {
    company_id: auth.company.id,
    url,
    secret,
    events,
    active: body?.active ?? true,
    updated_at: now,
  };

  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/webhooks`, {
    method: 'POST',
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    body: JSON.stringify(payload),
  });

  const rows = await res.json();
  if (!res.ok || !rows.length) return jsonError('Failed to save webhook', 500);
  return json(
    { item: mapWebhook(rows[0]) },
    200,
    { ...rateLimitHeaders(auth.company.rate_limit_per_min) }
  );
}

export async function onRequestDelete(context) {
  const { request, env } = context;
  const auth = await b2bCompanyAuth(request, env);
  if (!auth.ok) return jsonError(auth.error, auth.status);

  const res = await fetch(
    `${env.SUPABASE_URL}/rest/v1/webhooks?company_id=eq.${auth.company.id}`,
    {
      method: 'DELETE',
      headers: {
        apikey: env.SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
    }
  );

  if (!res.ok) return jsonError('Failed to delete webhook', 500);
  return json({ ok: true }, 200, rateLimitHeaders(auth.company.rate_limit_per_min));
}

export async function onRequestOptions() {
  return json({});
}
