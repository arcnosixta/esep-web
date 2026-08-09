-- ESEP: фундамент для юр.лиц и B2B-сделок (2026-08-09)
-- 1) profiles: тип клиента (физлицо/юрлицо), наименование организации, БИН
-- 2) applications: дублируем тип клиента для истории сделки
-- 3) api_keys: ключи для будущего публичного API (v1) — храним ТОЛЬКО хэш

-- ---------- 1. Профили: юрлица ----------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS client_type TEXT NOT NULL DEFAULT 'person',
  ADD COLUMN IF NOT EXISTS org_name TEXT,
  ADD COLUMN IF NOT EXISTS bin TEXT;

COMMENT ON COLUMN profiles.client_type IS 'person (ИИН) | org (БИН + org_name)';
COMMENT ON COLUMN profiles.bin IS 'БИН юрлица (12 цифр)';

-- ---------- 2. Заявки: тип клиента на момент сделки ----------
ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS client_type TEXT NOT NULL DEFAULT 'person',
  ADD COLUMN IF NOT EXISTS org_name TEXT,
  ADD COLUMN IF NOT EXISTS bin TEXT;

COMMENT ON COLUMN applications.client_type IS 'Снимок типа клиента на момент заявки (B2B-сделки)';

-- ---------- 3. API-ключи (публичное API v1) ----------
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  key_hash TEXT NOT NULL UNIQUE,          -- SHA-256 хэш ключа; сам ключ не храним
  key_prefix TEXT NOT NULL,               -- первые 8 символов для идентификации в UI
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  scopes TEXT[] NOT NULL DEFAULT '{}',    -- например {'estimates:read','appraisers:read'}
  last_used_at TIMESTAMPTZ,
  revoked BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS: ключами управляет владелец
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS api_keys_owner_select ON api_keys;
CREATE POLICY api_keys_owner_select ON api_keys
  FOR SELECT USING (owner_id = auth.uid());

DROP POLICY IF EXISTS api_keys_owner_insert ON api_keys;
CREATE POLICY api_keys_owner_insert ON api_keys
  FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS api_keys_owner_update ON api_keys;
CREATE POLICY api_keys_owner_update ON api_keys
  FOR UPDATE USING (owner_id = auth.uid());

-- ---------- 4. Полезные индексы ----------
CREATE INDEX IF NOT EXISTS idx_profiles_bin ON profiles (bin) WHERE bin IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_applications_client_type ON applications (client_type);
