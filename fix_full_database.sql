-- ============================================
-- ESEP — Database Repair Script
-- Run this ENTIRE script in Supabase SQL Editor
-- It restores broken FKs and adds missing objects
-- ============================================

-- ============================================
-- 1. RESTORE ORIGINAL FOREIGN KEYS
-- The previous script changed FKs to reference
-- profiles(user_id) which broke auth.
-- We restore them to reference auth.users(id).
-- ============================================

-- Restore documents.user_id FK
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_user_id_fkey;
ALTER TABLE documents ADD CONSTRAINT documents_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Restore applications.user_id FK
ALTER TABLE applications DROP CONSTRAINT IF EXISTS applications_user_id_fkey;
ALTER TABLE applications ADD CONSTRAINT applications_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Restore applications.appraiser_id FK
ALTER TABLE applications DROP CONSTRAINT IF EXISTS applications_appraiser_id_fkey;
ALTER TABLE applications ADD CONSTRAINT applications_appraiser_id_fkey
  FOREIGN KEY (appraiser_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- ============================================
-- 2. CREATE MISSING TABLES
-- ============================================

-- activity_logs (was never created)
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own logs" ON activity_logs;
CREATE POLICY "Users can view own logs" ON activity_logs
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admins can view all logs" ON activity_logs;
CREATE POLICY "Admins can view all logs" ON activity_logs
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

DROP POLICY IF EXISTS "Authenticated users can insert logs" ON activity_logs;
CREATE POLICY "Authenticated users can insert logs" ON activity_logs
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);

-- ============================================
-- 3. ADD MISSING ADMIN RLS POLICIES
-- ============================================

-- properties: admin can view all
DROP POLICY IF EXISTS "Admins can view all properties" ON properties;
CREATE POLICY "Admins can view all properties" ON properties
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- documents: admin can view all
DROP POLICY IF EXISTS "Admins can view all documents" ON documents;
CREATE POLICY "Admins can view all documents" ON documents
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- ============================================
-- 4. CREATE PROFILES FOR EXISTING USERS
-- Users who registered but profile trigger didn't fire
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
-- 5. ENSURE ALL RLS POLICIES EXIST
-- ============================================

-- profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- properties
DROP POLICY IF EXISTS "Users can view own properties" ON properties;
CREATE POLICY "Users can view own properties" ON properties
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own properties" ON properties;
CREATE POLICY "Users can insert own properties" ON properties
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own properties" ON properties;
CREATE POLICY "Users can update own properties" ON properties
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own properties" ON properties;
CREATE POLICY "Users can delete own properties" ON properties
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- documents
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
CREATE POLICY "Users can view own documents" ON documents
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own documents" ON documents;
CREATE POLICY "Users can insert own documents" ON documents
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own documents" ON documents;
CREATE POLICY "Users can delete own documents" ON documents
  FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- applications
DROP POLICY IF EXISTS "Users can view own applications" ON applications;
CREATE POLICY "Users can view own applications" ON applications
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Appraisers can view assigned applications" ON applications;
CREATE POLICY "Appraisers can view assigned applications" ON applications
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = appraiser_id);

DROP POLICY IF EXISTS "Users can insert own applications" ON applications;
CREATE POLICY "Users can insert own applications" ON applications
  FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Appraisers can update assigned applications" ON applications;
CREATE POLICY "Appraisers can update assigned applications" ON applications
  FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = appraiser_id);

DROP POLICY IF EXISTS "Admins can view all applications" ON applications;
CREATE POLICY "Admins can view all applications" ON applications
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

DROP POLICY IF EXISTS "Admins can update all applications" ON applications;
CREATE POLICY "Admins can update all applications" ON applications
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- appraisals
DROP POLICY IF EXISTS "Users can view own appraisals" ON appraisals;
CREATE POLICY "Users can view own appraisals" ON appraisals
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM applications WHERE applications.id = appraisals.application_id AND applications.user_id = (SELECT auth.uid()))
  );

DROP POLICY IF EXISTS "Appraisers can view assigned appraisals" ON appraisals;
CREATE POLICY "Appraisers can view assigned appraisals" ON appraisals
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM applications WHERE applications.id = appraisals.application_id AND applications.appraiser_id = (SELECT auth.uid()))
  );

DROP POLICY IF EXISTS "Appraisers can insert appraisals" ON appraisals;
CREATE POLICY "Appraisers can insert appraisals" ON appraisals
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM applications WHERE applications.id = appraisals.application_id AND applications.appraiser_id = (SELECT auth.uid()))
  );

DROP POLICY IF EXISTS "Admins can view all appraisals" ON appraisals;
CREATE POLICY "Admins can view all appraisals" ON appraisals
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- ============================================
-- 6. ENSURE TRIGGERS EXIST
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON profiles;
CREATE TRIGGER trigger_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trigger_applications_updated_at ON applications;
CREATE TRIGGER trigger_applications_updated_at
  BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
