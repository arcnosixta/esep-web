-- ============================================
-- ESEP — Пофиксить RLS для оценщика
-- Запусти в Supabase SQL Editor
-- ============================================

-- Удали старые политики
DO $$ BEGIN
  DROP POLICY IF EXISTS "Appraisers can view assigned applications" ON applications;
  DROP POLICY IF EXISTS "Appraisers can update assigned applications" ON applications;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Оценщик видит: а) свои назначенные б) доступные (new + appraiser_id IS NULL)
CREATE POLICY "Appraisers can view assigned applications" ON applications
  FOR SELECT TO authenticated USING (
    public.is_appraiser() AND (
      (SELECT auth.uid()) = appraiser_id
      OR (status = 'new' AND appraiser_id IS NULL)
    )
  );

-- Оценщик может: а) обновить свою назначенную б) назначить себе доступную
CREATE POLICY "Appraisers can update assigned applications" ON applications
  FOR UPDATE TO authenticated USING (
    public.is_appraiser() AND (
      (SELECT auth.uid()) = appraiser_id
      OR (status = 'new' AND appraiser_id IS NULL)
    )
  );
