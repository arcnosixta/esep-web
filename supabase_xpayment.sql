-- ============================================================
-- ESEP: XPayment интеграция (ЗАГЛУШКА)
-- ============================================================
--
-- TODO: после подключения XPayment актуализировать схему
-- и добавить недостающие поля/индексы под их API.

CREATE TABLE IF NOT EXISTS xpayment_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES applications(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'paid', 'failed', 'cancelled')),
  provider_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_xpayment_application
  ON xpayment_sessions(application_id);
