-- ============================================================
-- ESEP: платёжный конвейер (Фаза Б)
-- Запустить в Supabase SQL Editor (один раз).
-- ============================================================

-- 1. Таблица платежей ----------------------------------------
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES applications(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  amount NUMERIC NOT NULL CHECK (amount > 0),
  method TEXT NOT NULL DEFAULT 'manual'
    CHECK (method IN ('kaspi', 'card', 'manual')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'paid', 'failed', 'cancelled')),
  provider TEXT NOT NULL DEFAULT 'manual'
    CHECK (provider IN ('manual', 'paybox', 'kaspi_api')),
  provider_tx_id TEXT,
  confirmed_at TIMESTAMPTZ,
  confirmed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_application ON payments(application_id);
CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

-- 2. Новый статус заявки: pending_payment ---------------------
ALTER TABLE applications DROP CONSTRAINT IF EXISTS applications_status_check;
ALTER TABLE applications ADD CONSTRAINT applications_status_check
  CHECK (status IN ('new', 'pending_payment', 'in_progress', 'completed', 'rejected', 'paid'));

-- 3. RLS: клиент видит/создаёт свои платежи, админ — все ------
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own payments" ON payments;
CREATE POLICY "Users view own payments" ON payments FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users create own payments" ON payments;
CREATE POLICY "Users create own payments" ON payments FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admins view all payments" ON payments;
CREATE POLICY "Admins view all payments" ON payments FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

DROP POLICY IF EXISTS "Admins update payments" ON payments;
CREATE POLICY "Admins update payments" ON payments FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- 3a. Клиент может перевести СВОЮ заявку в «ожидает оплаты» (и обратно в new),
--     но не может менять её на другие статусы.
DROP POLICY IF EXISTS "Users can mark own application pending payment" ON applications;
CREATE POLICY "Users can mark own application pending payment" ON applications FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id AND status IN ('new', 'pending_payment'));

-- 4. Аудиторский след: подтверждение оплаты менеджером --------
INSERT INTO activity_logs (user_id, action, details)
SELECT NULL, 'migration', 'payments table created + pending_payment status added'
WHERE NOT EXISTS (SELECT 1 FROM activity_logs WHERE action = 'migration' AND details LIKE '%payments table created%');
