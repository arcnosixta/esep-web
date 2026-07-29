-- ============================================
-- ESEP — Полная починка auth/RLS (v3)
-- Запусти ВЕСЬ скрипт в Supabase SQL Editor
-- ============================================

-- ============================================
-- ШАГ 1: ДОБАВЬ НЕДОСТАЮЩИЕ КОЛОНКИ
-- ============================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS iin TEXT NOT NULL DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- ============================================
-- ШАГ 2: ВЫКЛЮЧИ RLS НА ВСЕХ ТАБЛИЦАХ
-- ============================================

ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE properties DISABLE ROW LEVEL SECURITY;
ALTER TABLE documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE applications DISABLE ROW LEVEL SECURITY;
ALTER TABLE appraisals DISABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations DISABLE ROW LEVEL SECURITY;

-- ============================================
-- ШАГ 3: УДАЛИ ВСЕ СТАРЫЕ ПОЛИТИКИ
-- ============================================

-- profiles
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
  DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
  DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
  DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
  DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
  DROP POLICY IF EXISTS "Admins can delete all profiles" ON profiles;
  DROP POLICY IF EXISTS "Appraisers can view client profiles" ON profiles;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- properties
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own properties" ON properties;
  DROP POLICY IF EXISTS "Users can insert own properties" ON properties;
  DROP POLICY IF EXISTS "Users can update own properties" ON properties;
  DROP POLICY IF EXISTS "Users can delete own properties" ON properties;
  DROP POLICY IF EXISTS "Admins can view all properties" ON properties;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- documents
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own documents" ON documents;
  DROP POLICY IF EXISTS "Users can insert own documents" ON documents;
  DROP POLICY IF EXISTS "Users can delete own documents" ON documents;
  DROP POLICY IF EXISTS "Admins can view all documents" ON documents;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- applications
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own applications" ON applications;
  DROP POLICY IF EXISTS "Users can insert own applications" ON applications;
  DROP POLICY IF EXISTS "Appraisers can view assigned applications" ON applications;
  DROP POLICY IF EXISTS "Appraisers can update assigned applications" ON applications;
  DROP POLICY IF EXISTS "Admins can view all applications" ON applications;
  DROP POLICY IF EXISTS "Admins can update all applications" ON applications;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- appraisals
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own appraisals" ON appraisals;
  DROP POLICY IF EXISTS "Appraisers can view assigned appraisals" ON appraisals;
  DROP POLICY IF EXISTS "Appraisers can insert appraisals" ON appraisals;
  DROP POLICY IF EXISTS "Admins can view all appraisals" ON appraisals;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- activity_logs
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own logs" ON activity_logs;
  DROP POLICY IF EXISTS "Admins can view all logs" ON activity_logs;
  DROP POLICY IF EXISTS "Authenticated users can insert logs" ON activity_logs;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ai_conversations
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own conversations" ON ai_conversations;
  DROP POLICY IF EXISTS "Users can insert own conversations" ON ai_conversations;
  DROP POLICY IF EXISTS "Users can update own conversations" ON ai_conversations;
  DROP POLICY IF EXISTS "Users can delete own conversations" ON ai_conversations;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ============================================
-- ШАГ 4: ВОССТАНОВИ FK НА auth.users
-- ============================================

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_user_id_fkey;
ALTER TABLE profiles ADD CONSTRAINT profiles_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE properties DROP CONSTRAINT IF EXISTS properties_user_id_fkey;
ALTER TABLE properties ADD CONSTRAINT properties_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_user_id_fkey;
ALTER TABLE documents ADD CONSTRAINT documents_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE applications DROP CONSTRAINT IF EXISTS applications_user_id_fkey;
ALTER TABLE applications ADD CONSTRAINT applications_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE applications DROP CONSTRAINT IF EXISTS applications_appraiser_id_fkey;
ALTER TABLE applications ADD CONSTRAINT applications_appraiser_id_fkey
  FOREIGN KEY (appraiser_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE activity_logs DROP CONSTRAINT IF EXISTS activity_logs_user_id_fkey;
ALTER TABLE activity_logs ADD CONSTRAINT activity_logs_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE ai_conversations DROP CONSTRAINT IF EXISTS ai_conversations_user_id_fkey;
ALTER TABLE ai_conversations ADD CONSTRAINT ai_conversations_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- ============================================
-- ШАГ 5: СОЗДАЙ ПРОФИЛИ ДЛЯ ТЕХ У КОГО ИХ НЕТ
-- ============================================

INSERT INTO profiles (user_id, full_name, email, phone)
SELECT
  au.id,
  COALESCE(au.raw_user_meta_data->>'full_name', ''),
  COALESCE(au.email, ''),
  COALESCE(au.phone, '')
FROM auth.users au
LEFT JOIN profiles p ON p.user_id = au.id
WHERE p.id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- ============================================
-- ШАГ 6: ТРИГГЕРЫ
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, email, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.phone, '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON profiles;
CREATE TRIGGER trigger_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_applications_updated_at ON applications;
CREATE TRIGGER trigger_applications_updated_at
  BEFORE UPDATE ON applications FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trigger_ai_conversations_updated_at ON ai_conversations;
CREATE TRIGGER trigger_ai_conversations_updated_at
  BEFORE UPDATE ON ai_conversations FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- ШАГ 7: SECURITY DEFINER ФУНКЦИИ
-- RLS выключен — рекурсии НЕ БУДЕТ
-- ============================================

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

-- ============================================
-- ШАГ 8: ВКЛЮЧИ RLS И СОЗДАЙ НОВЫЕ ПОЛИТИКИ
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE TO authenticated USING (public.is_admin());

CREATE POLICY "Admins can delete all profiles" ON profiles
  FOR DELETE TO authenticated USING (public.is_admin());

CREATE POLICY "Appraisers can view client profiles" ON profiles
  FOR SELECT TO authenticated USING (public.is_appraiser());

-- PROPERTIES
CREATE POLICY "Users can view own properties" ON properties
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own properties" ON properties
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own properties" ON properties
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own properties" ON properties
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Admins can view all properties" ON properties
  FOR SELECT TO authenticated USING (public.is_admin());

-- DOCUMENTS
CREATE POLICY "Users can view own documents" ON documents
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own documents" ON documents
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own documents" ON documents
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Admins can view all documents" ON documents
  FOR SELECT TO authenticated USING (public.is_admin());

-- APPLICATIONS
CREATE POLICY "Users can view own applications" ON applications
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own applications" ON applications
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Appraisers can view assigned applications" ON applications
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = appraiser_id);

CREATE POLICY "Appraisers can update assigned applications" ON applications
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = appraiser_id);

CREATE POLICY "Admins can view all applications" ON applications
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "Admins can update all applications" ON applications
  FOR UPDATE TO authenticated USING (public.is_admin());

-- APPRAISALS
CREATE POLICY "Users can view own appraisals" ON appraisals
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM applications
      WHERE applications.id = appraisals.application_id
        AND applications.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Appraisers can view assigned appraisals" ON appraisals
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM applications
      WHERE applications.id = appraisals.application_id
        AND applications.appraiser_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Appraisers can insert appraisals" ON appraisals
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM applications
      WHERE applications.id = appraisals.application_id
        AND applications.appraiser_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Admins can view all appraisals" ON appraisals
  FOR SELECT TO authenticated USING (public.is_admin());

-- ACTIVITY_LOGS
CREATE POLICY "Users can view own logs" ON activity_logs
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Admins can view all logs" ON activity_logs
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "Authenticated users can insert logs" ON activity_logs
  FOR INSERT TO authenticated WITH CHECK (true);

-- AI_CONVERSATIONS
CREATE POLICY "Users can view own conversations" ON ai_conversations
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert own conversations" ON ai_conversations
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own conversations" ON ai_conversations
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own conversations" ON ai_conversations
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- ШАГ 9: НАЗНАЧЬ ADMIN РОЛЬ
-- ============================================

UPDATE profiles
SET role = 'admin'
WHERE user_id = (
  SELECT id FROM auth.users WHERE email = 'arcnosixta@gmail.com'
);

-- Проверь:
SELECT au.email, p.role, p.full_name
FROM profiles p
JOIN auth.users au ON au.id = p.user_id;

-- ============================================
-- ШАГ 10: STORAGE POLICIES
-- ============================================

DROP POLICY IF EXISTS "Users can upload to own folder" ON storage.objects;
CREATE POLICY "Users can upload to own folder" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'user-docs'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

DROP POLICY IF EXISTS "Users can view own files" ON storage.objects;
CREATE POLICY "Users can view own files" ON storage.objects
  FOR SELECT TO authenticated USING (
    bucket_id = 'user-docs'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
CREATE POLICY "Users can delete own files" ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'user-docs'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );
