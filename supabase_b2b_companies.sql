-- ============================================================
-- ESEP: B2B-компании, верификация, API-ключи, webhooks
-- ============================================================

-- ---------- 1. Компании ----------
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  bin TEXT NOT NULL UNIQUE,
  contact_name TEXT NOT NULL DEFAULT '',
  contact_email TEXT NOT NULL DEFAULT '',
  contact_phone TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending_verification' CHECK (status IN ('pending_verification', 'verified', 'rejected', 'suspended')),
  documents JSONB NOT NULL DEFAULT '[]'::jsonb,
  notes TEXT,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_companies_bin ON companies (bin);
CREATE INDEX IF NOT EXISTS idx_companies_status ON companies (status);

-- ---------- 2. Участники компаний ----------
CREATE TABLE IF NOT EXISTS company_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_company_members_company ON company_members (company_id);
CREATE INDEX IF NOT EXISTS idx_company_members_user ON company_members (user_id);

-- ---------- 3. Запросы API-ключей ----------
CREATE TABLE IF NOT EXISTS api_key_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_api_key_requests_company ON api_key_requests (company_id);
CREATE INDEX IF NOT EXISTS idx_api_key_requests_status ON api_key_requests (status);

-- ---------- 4. Webhooks компаний ----------
CREATE TABLE IF NOT EXISTS webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE NOT NULL,
  url TEXT NOT NULL,
  events TEXT[] NOT NULL DEFAULT '{}',
  secret TEXT NOT NULL DEFAULT '',
  enabled BOOLEAN NOT NULL DEFAULT true,
  last_status TEXT,
  last_triggered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_webhooks_company ON webhooks (company_id);

-- ---------- 5. Расширение api_keys ----------
ALTER TABLE api_keys
  ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS company_scope TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS environment TEXT NOT NULL DEFAULT 'live',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'revoked')),
  ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_api_keys_company ON api_keys (company_id);

-- ---------- 6. Обновление company_id у существующих ключей ----------
UPDATE api_keys
SET company_id = COALESCE(
  (SELECT id FROM companies WHERE companies.owner_id = api_keys.owner_id LIMIT 1),
  company_id
)
WHERE company_id IS NULL;

-- ---------- 7. RLS ----------
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_key_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage companies" ON companies;
CREATE POLICY "Admins can manage companies" ON companies
  FOR ALL TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.user_id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Company owners can view own company" ON companies;
CREATE POLICY "Company owners can view own company" ON companies
  FOR SELECT TO authenticated USING (
    id IN (
      SELECT company_id FROM company_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Company owners can update own company" ON companies;
CREATE POLICY "Company owners can update own company" ON companies
  FOR UPDATE TO authenticated USING (
    id IN (
      SELECT company_id FROM company_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Members can view company_members" ON company_members;
CREATE POLICY "Members can view company_members" ON company_members
  FOR SELECT TO authenticated USING (
    company_id IN (
      SELECT company_id FROM company_members WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Company admins can manage members" ON company_members;
CREATE POLICY "Company admins can manage members" ON company_members
  FOR ALL TO authenticated USING (
    company_id IN (
      SELECT company_id FROM company_members WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

DROP POLICY IF EXISTS "Users can view own key requests" ON api_key_requests;
CREATE POLICY "Users can view own key requests" ON api_key_requests
  FOR SELECT TO authenticated USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE profiles.user_id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Users can create key requests" ON api_key_requests;
CREATE POLICY "Users can create key requests" ON api_key_requests
  FOR INSERT TO authenticated WITH CHECK (
    user_id = auth.uid() AND
    company_id IN (SELECT company_id FROM company_members WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "Admins can update key requests" ON api_key_requests;
CREATE POLICY "Admins can update key requests" ON api_key_requests
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.user_id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Company can manage own webhooks" ON webhooks;
CREATE POLICY "Company can manage own webhooks" ON webhooks
  FOR ALL TO authenticated USING (
    company_id IN (
      SELECT company_id FROM company_members WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- ---------- 8. Триггеры ----------
DROP TRIGGER IF EXISTS trigger_companies_updated_at ON companies;
CREATE TRIGGER trigger_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trigger_webhooks_updated_at ON webhooks;
CREATE TRIGGER trigger_webhooks_updated_at BEFORE UPDATE ON webhooks FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------- 9. Аудиторский след ----------
INSERT INTO activity_logs (user_id, action, details)
SELECT NULL, 'migration',
  '{"message": "B2B companies/requests/webhooks + api_keys company support", "source": "supabase_b2b_companies.sql"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM activity_logs
  WHERE action = 'migration'
    AND details->>'message' LIKE '%B2B companies/requests/webhooks%'
);
