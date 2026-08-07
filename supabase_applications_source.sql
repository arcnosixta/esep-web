-- ============================================================
-- ESEP: пометка источника заявки (прошла ли ИИ-анализ)
-- Выполнить в Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- Заявки, созданные после ИИ-анализа, помечаются source='ai'.
-- Обычные (ручные/тестовые) заявки остаются 'manual'.
-- Страница «Заявки» и очередь оценщика показывают только source='ai'.
ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'manual';

-- Существующие заявки остаются manual — они НЕ прошли ИИ-анализ
-- и больше не будут видны в списке заявок.

-- Индекс для быстрой фильтрации
CREATE INDEX IF NOT EXISTS idx_applications_source
  ON applications(source);
