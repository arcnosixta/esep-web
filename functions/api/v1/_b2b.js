// Cloudflare Pages Function — B2B helpers for /api/v1/*.
// Uses Supabase REST via service role from env.
// Company API-key contract:
//   - api_keys.company_id = companies.id
//   - companies.verified = true
//   - rate_limit_per_min = 100 default
export async function b2bCompanyAuth(request, env) {
  const keyResult = await requireApiKey(request, env);
  if (!keyResult.ok) return keyResult;

  const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = env;
  const apiKey = keyResult.key;

  const companyRes = await fetch(
    `${SUPABASE_URL}/rest/v1/companies?id=eq.${apiKey.companyId}&select=id,name,verified,rate_limit_per_min`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    }
  );

  if (!companyRes.ok) {
    return { ok: false, error: 'Company lookup failed', status: 500 };
  }

  const rows = await companyRes.json();
  const company = rows[0];
  if (!company) {
    return { ok: false, error: 'Company not found for API key', status: 403 };
  }
  if (!company.verified) {
    return { ok: false, error: 'Company is not verified', status: 403 };
  }

  return { ok: true, company };
}

export function rateLimitHeaders(limit) {
  return {
    'X-RateLimit-Limit': String(limit ?? 100),
    'X-RateLimit-Window': '60',
  };
}
