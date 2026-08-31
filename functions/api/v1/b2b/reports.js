// /api/v1/b2b/reports — отчёты по заявкам компании
// GET /:applicationId/report — получить отчёт/PDF
// GET /:applicationId/pdf    — прямой PDF, если есть
import { json, jsonError } from '../../_auth.js';
import { b2bCompanyAuth, rateLimitHeaders } from '../_b2b.js';

function ok(data, headers) {
  return json(data, 200, { ...(headers ?? {}) });
}

function appUrl(env, appId) {
  return `${env.SUPABASE_URL}/rest/v1/applications?id=eq.${appId}&select=id,status,company_id,report_id,report_url,report_pdf_url,updated_at`;
}

async function ensureOwn(env, appId, companyId) {
  const res = await fetch(appUrl(env, appId), {
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    },
  });

  const rows = await res.json();
  if (!res.ok || !rows.length) return null;
  const row = rows[0];
  if (row.company_id !== companyId) return null;
  return row;
}

function mapReport(row) {
  return {
    application_id: row.id,
    status: row.status,
    report_id: row.report_id,
    report_url: row.report_url,
    report_pdf_url: row.report_pdf_url,
    updated_at: row.updated_at,
  };
}

export async function onRequestGet(context) {
  const { request, env } = context;
  const auth = await b2bCompanyAuth(request, env);
  if (!auth.ok) return jsonError(auth.error, auth.status);

  const parts = new URL(request.url).pathname.split('/').filter(Boolean);
  const appId = parts[parts.length - 1] || '';

  const wantPdf = parts[parts.length - 2] === 'pdf';
  const row = await ensureOwn(env, appId, auth.company.id);
  if (!row) return jsonError('Application not found', 404);

  const resolvedPdf = row.report_pdf_url || (row.report_url ? row.report_url.replace(/[?].*$/, '') + '?download=1' : null);
  if (wantPdf) {
    if (!resolvedPdf) return jsonError('PDF not ready', 404);
    return json({ pdf_url: resolvedPdf });
  }

  return ok({ item: mapReport(row) }, rateLimitHeaders(auth.company.rate_limit_per_min));
}

export async function onRequestOptions() {
  return json({});
}
