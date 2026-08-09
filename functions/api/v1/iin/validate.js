// POST /api/v1/iin/validate — публичный: проверка ИИН/БИН (контрольная цифра).
// Полезно интеграторам для предварительной валидации на своей стороне.
// Тело: { "iin": "900101123456" } (или bin / id).
import { json, jsonError, validateIin } from '../_auth.js';

export async function onRequestPost(context) {
  const { request } = context;
  let body;
  try {
    body = await request.json();
  } catch (e) {
    return jsonError('Invalid JSON body', 400);
  }
  const raw = body?.iin ?? body?.bin ?? body?.id;
  if (typeof raw !== 'string') return jsonError('Missing field: iin (or bin)', 400);
  return json(validateIin(raw));
}

export async function onRequestOptions() {
  return json({});
}
