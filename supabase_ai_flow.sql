-- ============================================================
-- ESEP: полный ИИ-поток (оценка → оплата → заявка → оценщик → ЭЦП)
-- Выполнить в Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- 1. Ссылка на объявление-аналог (доказательство для отчёта)
ALTER TABLE market_data
  ADD COLUMN IF NOT EXISTS source_url TEXT;

-- 2. ЭЦП-подпись оценщика (заглушка для теста, потом NCALayer)
ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS signed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS signed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS signature TEXT;

-- 3. Оценка из ИИ-анализа сохраняется в заявке при создании
--    (estimated_price уже есть в схеме — проверка на всякий случай)
ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS estimated_price NUMERIC;
