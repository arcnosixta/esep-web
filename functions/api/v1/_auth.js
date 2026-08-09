// Cloudflare Pages Function — общие хелперы API v1 (не маршрутизируется).
//
// Аутентификация: заголовок X-API-Key. Ключи живут в Supabase (таблица
// api_keys), в БД хранится ТОЛЬКО SHA-256 хэш ключа — сам ключ не хранится.
// Проверка выполняется серверной функцией (service role key из env),
// RLS на таблице api_keys для владельца сохраняется.

export async function sha256hex(s) {
  const data = new TextEncoder().encode(s);
  const buf = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    },
  });
}

export function jsonError(message, status) {
  return json({ error: message }, status);
}

/**
 * Проверяет X-API-Key. Возвращает:
 *   { ok: true, key: {id, name, scopes} }  — ключ валиден
 *   { ok: false, error, status }           — отклонено
 */
export async function requireApiKey(request, env) {
  const key = request.headers.get('x-api-key');
  if (!key) return { ok: false, error: 'Missing X-API-Key header', status: 401 };

  const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = env;
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return { ok: false, error: 'Server not configured (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY)', status: 500 };
  }

  const hash = await sha256hex(key);
  const url = `${SUPABASE_URL}/rest/v1/api_keys?select=id,name,scopes,revoked&key_hash=eq.${hash}`;
  let res;
  try {
    res = await fetch(url, {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    });
  } catch (e) {
    return { ok: false, error: 'Auth backend unreachable', status: 500 };
  }
  if (!res.ok) return { ok: false, error: 'Auth backend error', status: 500 };

  const rows = await res.json();
  if (!rows.length) return { ok: false, error: 'Invalid API key', status: 401 };
  const row = rows[0];
  if (row.revoked) return { ok: false, error: 'API key revoked', status: 401 };

  // Обновляем last_used_at (best-effort, не блокирует запрос).
  await fetch(`${SUPABASE_URL}/rest/v1/api_keys?id=eq.${row.id}`, {
    method: 'PATCH',
    headers: {
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify({ last_used_at: new Date().toISOString() }),
  }).catch(() => {});

  return { ok: true, key: { id: row.id, name: row.name, scopes: row.scopes ?? [] } };
}

/** Валидация ИИН/БИН РК (12 цифр, контрольная цифра mod 11, дата). */
export function validateIin(raw) {
  const s = String(raw ?? '').replace(/[\s-]/g, '');
  if (!s) return { valid: false, error: 'Введите ИИН/БИН' };
  if (!/^\d{12}$/.test(s)) return { valid: false, error: 'ИИН/БИН — 12 цифр' };

  const month = parseInt(s.slice(2, 4), 10);
  const day = parseInt(s.slice(4, 6), 10);
  if (month < 1 || month > 12) return { valid: false, error: 'Некорректный месяц в номере' };
  if (day < 1 || day > 31) return { valid: false, error: 'Некорректный день в номере' };

  const w1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  const w2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
  const d = s.split('').map(Number);
  let check = d.slice(0, 11).reduce((acc, x, i) => acc + x * w1[i], 0) % 11;
  if (check === 10) check = d.slice(0, 11).reduce((acc, x, i) => acc + x * w2[i], 0) % 11;
  if (check !== d[11]) return { valid: false, error: 'Контрольная цифра не совпадает' };

  // Подсказка: у ИИН 7-я цифра — код века/пола (1-8), у БИН — десятки кода
  // региона. Однозначно на БИН указывают 0 и 9 (у ИИН таких кодов нет).
  return { valid: true, isOrg: d[6] === 0 || d[6] === 9 };
}
