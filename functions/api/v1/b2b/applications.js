// /api/v1/b2b/applications — заявки компании
// GET  => свои заявки
// POST => создать заявку от клиента
import { json, jsonError } from '../../_auth.js';
import { b2bCompanyAuth, rateLimitHeaders } from '../_b2b.js';

function ok(data, headers) {
  return json(data, 200, { ...(headers ?? {}) });
}

function badRequest(message) {
  return jsonError(message, 400);
}

function mapAppRow(row) {
  return {
    id: row.id,
    status: row.status,
    client_name: row.client_name ?? row.full_name,
    client_iin: row.client_iin,
    property_type: row.property_type,
    address: row.address,
    estimated_price: row.estimated_price,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export async function onRequestGet(context) {
  const { request, env } = context;
  const auth = await b2bCompanyAuth(request, env);
  if (!auth.ok) return jsonError(auth.error, auth.status);

  const url = new URL(request.url);
  const status = url.searchParams.get('status');

  let q = `${env.SUPABASE_URL}/rest/v1/applications?select=*&company_id=eq.${auth.company.id}&order=created_at.desc`;
  if (status && ['new', 'in_progress', 'completed', 'cancelled'].includes(status)) {
    q += `&status=eq.${status}`;
  }

  const res = await fetch(q, {
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    },
  });

  const rows = await res.json();
  if (!res.ok) return jsonError('Failed to load applications', 500);

  return ok(
    { items: rows.map(mapAppRow) },
    rateLimitHeaders(auth.company.rate_limit_per_min)
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
    return badRequest('Invalid JSON');
  }

  const clientName = String(body?.client_name ?? '').trim();
  const propertyType = String(body?.property_type ?? '').trim();
  const address = String(body?.address ?? '').trim();

  if (!clientName || !propertyType || !address) {
    return badRequest('client_name, property_type, address required');
  }

  const now = new Date().toISOString();
  const payload = {
    company_id: auth.company.id,
    client_name: clientName,
    client_iin: body?.client_iin ? String(body.client_iin).trim() : null,
    phone: body?.phone ? String(body.phone).trim() : null,
    email: body?.email ? String(body.email).trim() : null,
    property_type: propertyType,
    address: address,
    area: body?.area ? Number(body.area) : null,
    rooms: body?.rooms ? Number(body.rooms) : null,
    floor: body?.floor != null ? Number(body.floor) : null,
    year: body?.year != null ? Number(body.year) : null,
    condition: body?.condition ? String(body.condition).trim() : null,
    note: body?.note ? String(body.note).trim() : null,
    estimated_price: null,
    status: 'new',
    created_at: now,
    updated_at: now,
  };

  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/applications`, {
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
  if (!res.ok || !rows.length) return jsonError('Failed to create application', 500);

  return ok({ item: mapAppRow(rows[0]) }, rateLimitHeaders(auth.company.rate_limit_per_min));
}

export async function onRequestOptions() {
  return json({});
}
