# ESEP Public API — v1 (черновик/фундамент)

> Статус: фундамент заложен (2026-08-09). Рабочие эндпоинты: `ping`, `iin/validate`.
> Остальное — план. Данные меняются до первого стабильного релиза v1.

## Базовый URL

```
https://<esep>.pages.dev/api/v1
```

Все ответы — JSON. Ошибки:

```json
{ "error": "человекочитаемое сообщение" }
```

HTTP-статусы: `400` невалидный запрос, `401` нет/неверный ключ, `404` нет
эндпоинта, `500` серверная ошибка.

## Аутентификация

Заголовок `X-API-Key: <ключ>`.

- Ключи создаются владельцем (таблица `api_keys` в Supabase, см.
  `supabase_b2b_foundation.sql`).
- В БД хранится только SHA-256 хэш ключа (`key_hash`) + префикс для UI.
- Ключ имеет `scopes` (например `{'estimates:read'}`) — проверка scope
  добавляется по мере появления защищённых эндпоинтов.
- Отозвать ключ: `UPDATE api_keys SET revoked = true WHERE id = '...'`.

Создать ключ (SQL, выполнить с правами владельца в Supabase SQL Editor):

```sql
-- 1) сгенерируйте ключ: например openssl rand -hex 24
-- 2) вставьте запись:
INSERT INTO api_keys (name, key_hash, key_prefix, owner_id, scopes)
VALUES (
  'my-integration',
  encode(sha256('СЮДА_ВАШ_КЛЮЧ'::bytea), 'hex'),  -- хэш ключа
  left('СЮДА_ВАШ_КЛЮЧ', 8),                       -- префикс
  (SELECT id FROM auth.users LIMIT 1),            -- владелец
  '{}'
);
```

Проверка ключа выполняется серверной функцией
(`functions/api/v1/_auth.js`) с `SUPABASE_SERVICE_ROLE_KEY` — переменные
окружения в Cloudflare Pages:

| Переменная | Тип | Назначение |
|---|---|---|
| `SUPABASE_URL` | Secret | URL проекта Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Secret | Сервисный ключ (только на сервере!) |

## Аутентификация B2B

- Для B2B используется отдельный под-путь `/api/v1/b2b/*`.
- Ключ обязан принадлежать `api_keys.company_id`, а компания должна быть `verified = true`.
- Объекты ограничены компанией: `applications WHERE company_id = current_company`.

## Эндпоинты

### B2B: проверка ключа компании

`GET /b2b/ping`

```json
{ "ok": true, "company": { "id": "...", "name": "...", "verified": true, "limit": 100 } }
```

### B2B: заявки

`GET /b2b/applications?status=new|in_progress|completed|cancelled`
`POST /b2b/applications`

```json
{ "client_name": "...", "property_type": "...", "address": "...", "client_iin": "...", "area": 42 }
```

### B2B: отчёты

`GET /b2b/reports/{applicationId}/report`
`GET /b2b/reports/{applicationId}/pdf`

### B2B: вебхуки

`GET /b2b/webhooks`
`POST /b2b/webhooks`
`DELETE /b2b/webhooks`

```json
{ "url": "https://partner.example/hook", "events": ["application.created", "report.ready"] }
```

## План

| Метод | Путь | Описание |
|---|---|---|
| `GET` | `/b2b/appraisers` | Список оценщиков |
| `GET` | `/b2b/balance` | Лимиты/баланс интегратора |

## План (следующие эндпоинты, по мере спроса)

| Метод | Путь | Scope | Описание |
|---|---|---|---|
| POST | `/estimates` | `estimates:write` | Предварительная оценка по параметрам объекта (AI) |
| GET | `/appraisers` | `appraisers:read` | Список доступных оценщиков |
| POST | `/applications` | `applications:write` | Создание заявки от имени интегратора (B2B) |
| GET | `/applications/{id}` | `applications:read` | Статус и результат заявки |
| POST | `/applications/{id}/sign` | `applications:write` | Загрузка CMS-подписи оценщика |

## Ограничения и безопасность

- Никаких персональных данных (ФИО/ИИН третьих лиц) в публичных ответах без
  договорного основания — закон РК о персональных данных.
- Rate limiting добавляется, когда появятся платные/тяжёлые эндпоинты
  (Cloudflare Rate Limiting Rules).
- Ключи не должны попадать в клиентский JS-бандл: вызовы API v1 — только
  с серверов интеграторов.
