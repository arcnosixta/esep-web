// GET /api/v1/b2b/ping — проверка живых ключа компании.
import { json, jsonError } from '../../_auth.js';
import { b2bCompanyAuth, rateLimitHeaders } from '../_b2b.js';

export async function onRequestGet(context) {
  const { request, env } = context;
  const auth = await companyAuth(request, env);
  if (!auth.ok) return jsonError(auth.error, auth.status);

  return json(
    {
      ok: true,
      company: {
        id: auth.company.id,
        name: auth.company.name,
        verified: !!auth.company.verified,
        limit: Number(auth.company.rate_limit_per_min ?? 100),
      },
    },
    200,
    { ...rlHeaders(auth.company.rate_limit_per_min) }
  );
}

export async function onRequestOptions() {
  return json({});
}
