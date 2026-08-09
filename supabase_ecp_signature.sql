-- ESEP: реальная ЭЦП-подпись отчётов (CMS через NCALayer)
-- Добавляет колонки для данных подписанта в таблицу applications.

ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS signer_name TEXT,
  ADD COLUMN IF NOT EXISTS signer_iin TEXT,
  ADD COLUMN IF NOT EXISTS signature_path TEXT;

-- Индекс для быстрого поиска подписанных заявок
CREATE INDEX IF NOT EXISTS idx_applications_signed_at
  ON applications (signed_at)
  WHERE signed_at IS NOT NULL;
