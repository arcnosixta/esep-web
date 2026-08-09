// GET /api/v1/ping — публичный: проверка живости API и версия.
import { json } from './_auth.js';

export async function onRequest(context) {
  return json({
    service: 'esep-api',
    version: 'v1',
    time: new Date().toISOString(),
  });
}

export async function onRequestOptions() {
  return json({});
}
