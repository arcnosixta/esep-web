-- ============================================================
-- ESEP — Защита от уязвимостей (RLS-ужесточение) — v1
-- Запусти ВЕСЬ скрипт в Supabase SQL Editor (идемпотентно).
--
-- Что закрывает:
--   1. ЭСКАЛАЦИЯ ПРИВИЛЕГИЙ: пользователь мог обновить СВОЙ профиль
--      и выдать себе роль 'admin'/'appraiser' или снять блокировку.
--      Теперь роль/is_blocked/user_id может менять только админ.
--   2. ЭЦП ОБЫЧНОМУ ПОЛЬЗОВАТЕЛЮ: клиент мог «подписать» свою заявку —
--      проставить signer_name/signer_iin/signature/signed_at, оставив
--      status='new' (WITH CHECK проходил). Теперь эти поля клиент
--      менять не может — только оценщик (или админ).
--   3. ОТЧЁТЫ (reports): владелец (клиент) мог сам пометить отчёт
--      status='paid'/'signed' — обход оплаты и подписи. Обновлять
--      отчёты теперь могут только оценщик и админ; клиент — читать.
--   4. ПЛАТЕЖИ: клиент мог создать платёж на ЧУЖУЮ заявку.
--   5. STORAGE 'reports': бакет был публичным — PDF с ФИО/ИИН/адресом
--      скачивался любым, у кого есть ссылка. Делаем приватным +
--      политики (клиент-владелец / оценщик / админ).
-- ============================================================

-- ============================================================
-- 0. SECURITY DEFINER функции (должны существовать всегда)
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_appraiser()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE user_id = auth.uid() AND role = 'appraiser'
  );
END;
$$;

-- ============================================================
-- 1. PROFILES — без самоназначения ролей и саморазблокировки
-- ============================================================

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    AND NEW.user_id = OLD.user_id
    AND NEW.role IS NOT DISTINCT FROM OLD.role
    AND NEW.is_blocked IS NOT DISTINCT FROM OLD.is_blocked
  );

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    AND COALESCE(role, 'client') = 'client'
  );

DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE TO authenticated USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================================
-- 2. APPLICATIONS — клиент не трогает поля подписи
-- ============================================================

-- Клиент: только перевод СВОЕЙ заявки new <-> pending_payment.
-- Поля подписи (signer_*, signature, signed_*) — только оценщик/админ.
DROP POLICY IF EXISTS "Users can mark own application pending payment" ON applications;
CREATE POLICY "Users can mark own application pending payment" ON applications
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    AND status IN ('new', 'pending_payment')
    AND NEW.signer_name IS NOT DISTINCT FROM OLD.signer_name
    AND NEW.signer_iin IS NOT DISTINCT FROM OLD.signer_iin
    AND NEW.signature IS NOT DISTINCT FROM OLD.signature
    AND NEW.signature_path IS NOT DISTINCT FROM OLD.signature_path
    AND NEW.signed_at IS NOT DISTINCT FROM OLD.signed_at
    AND NEW.signed_by IS NOT DISTINCT FROM OLD.signed_by
  );

-- Оценщик: свои/доступные заявки; статус — только рабочие
-- (не может сам пометить 'paid' — оплату подтверждает админ).
DROP POLICY IF EXISTS "Appraisers can update assigned applications" ON applications;
CREATE POLICY "Appraisers can update assigned applications" ON applications
  FOR UPDATE TO authenticated
  USING (
    public.is_appraiser() AND (
      (SELECT auth.uid()) = appraiser_id
      OR (status = 'new' AND appraiser_id IS NULL)
    )
  )
  WITH CHECK (
    public.is_appraiser() AND (
      (SELECT auth.uid()) = appraiser_id
      OR (status = 'new' AND appraiser_id IS NULL)
    )
    AND NEW.status IN ('new', 'in_progress', 'completed')
    AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id
  );

-- ============================================================
-- 3. REPORTS — клиент только читает, пишут оценщик/админ
-- ============================================================

DROP POLICY IF EXISTS reports_select_own ON public.reports;
CREATE POLICY reports_select_own ON public.reports
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.applications a
      WHERE a.id = application_id AND a.user_id = auth.uid()
    )
    OR public.is_appraiser()
    OR public.is_admin()
  );

DROP POLICY IF EXISTS reports_insert_own ON public.reports;
CREATE POLICY reports_insert_own ON public.reports
  FOR INSERT TO authenticated WITH CHECK (
    public.is_appraiser()
    OR public.is_admin()
    OR (
      auth.uid() = user_id
      AND EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id = application_id AND a.user_id = auth.uid()
      )
    )
  );

-- Обновлять отчёт может ТОЛЬКО оценщик/админ. Владелец-клиент не может
-- сам проставить status='paid'/'signed' (обход оплаты и ЭЦП).
DROP POLICY IF EXISTS reports_update_own ON public.reports;
CREATE POLICY reports_update_own ON public.reports
  FOR UPDATE TO authenticated USING (
    public.is_appraiser()
    OR public.is_admin()
  )
  WITH CHECK (
    public.is_appraiser()
    OR public.is_admin()
  );

-- ============================================================
-- 4. PAYMENTS — платёж только по СВОЕЙ заявке
-- ============================================================

DROP POLICY IF EXISTS "Users create own payments" ON payments;
CREATE POLICY "Users create own payments" ON payments FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR (
      (SELECT auth.uid()) = user_id
      AND EXISTS (
        SELECT 1 FROM applications a
        WHERE a.id = application_id AND a.user_id = (SELECT auth.uid())
      )
    )
  );

-- ============================================================
-- 5. STORAGE: бакет 'reports' — приватный
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('reports', 'reports', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Загрузка PDF: клиент-владелец заявки, оценщик, админ.
-- Путь: <application_id>/report_*.pdf (первая папка = id заявки).
DROP POLICY IF EXISTS "Reports upload" ON storage.objects;
CREATE POLICY "Reports upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'reports'
    AND (
      public.is_admin()
      OR public.is_appraiser()
      OR EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id::text = (storage.foldername(name))[1]
          AND a.user_id = (SELECT auth.uid())
      )
    )
  );

-- Чтение (нужно для createSignedUrl): владелец/оценщик/админ.
DROP POLICY IF EXISTS "Reports view" ON storage.objects;
CREATE POLICY "Reports view" ON storage.objects
  FOR SELECT TO authenticated USING (
    bucket_id = 'reports'
    AND (
      public.is_admin()
      OR public.is_appraiser()
      OR EXISTS (
        SELECT 1 FROM public.applications a
        WHERE a.id::text = (storage.foldername(name))[1]
          AND (
            a.user_id = (SELECT auth.uid())
            OR a.appraiser_id = (SELECT auth.uid())
          )
      )
    )
  );

-- ============================================================
-- Проверка (раскомментируй при желании):
-- SELECT au.email, p.role FROM profiles p
-- JOIN auth.users au ON au.id = p.user_id;
-- ============================================================
