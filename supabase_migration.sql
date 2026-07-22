-- ============================================
-- ESEP — Supabase Database Schema (полный, безопасный)
-- ============================================
-- Можно запускать сколько угодно раз — не будет ошибок
-- ============================================

-- 1. Профили пользователей
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  full_name TEXT NOT NULL DEFAULT '',
  iin TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('client', 'appraiser', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Имущество пользователей
CREATE TABLE IF NOT EXISTS properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('apartment', 'house', 'land', 'commercial')),
  address TEXT NOT NULL DEFAULT '',
  area NUMERIC NOT NULL DEFAULT 0,
  rooms INTEGER,
  floor INTEGER,
  total_floors INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Документы на объекты
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  file_url TEXT NOT NULL DEFAULT '',
  file_type TEXT NOT NULL DEFAULT 'pdf',
  file_size NUMERIC,
  content_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE documents ADD COLUMN IF NOT EXISTS content_text TEXT;

-- 4. Заявки на оценку
CREATE TABLE IF NOT EXISTS applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'completed', 'rejected', 'paid')),
  appraiser_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  estimated_price NUMERIC,
  final_price NUMERIC,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Отчёты об оценке
CREATE TABLE IF NOT EXISTS appraisals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES applications(id) ON DELETE CASCADE UNIQUE NOT NULL,
  estimated_price NUMERIC NOT NULL DEFAULT 0,
  report_url TEXT,
  report_pdf_url TEXT,
  signed_at TIMESTAMPTZ,
  signature_data TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Рыночные данные (аналоги)
CREATE TABLE IF NOT EXISTS market_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  address TEXT NOT NULL,
  type TEXT NOT NULL,
  area NUMERIC NOT NULL,
  price NUMERIC NOT NULL,
  price_per_m2 NUMERIC NOT NULL,
  rooms INTEGER,
  floor INTEGER,
  source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('krisha', 'krn', 'manual')),
  parsed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- ИНДЕКСЫ
-- ============================================

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_properties_user_id ON properties(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_property_id ON documents(property_id);
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON applications(user_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_appraiser_id ON applications(appraiser_id);
CREATE INDEX IF NOT EXISTS idx_appraisals_application_id ON appraisals(application_id);
CREATE INDEX IF NOT EXISTS idx_market_data_type ON market_data(type);
CREATE INDEX IF NOT EXISTS idx_market_data_source ON market_data(source);

-- ============================================
-- ROW LEVEL SECURITY (RLS) — таблицы
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_data ENABLE ROW LEVEL SECURITY;

-- profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

-- properties
DROP POLICY IF EXISTS "Users can view own properties" ON properties;
CREATE POLICY "Users can view own properties" ON properties FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own properties" ON properties;
CREATE POLICY "Users can insert own properties" ON properties FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own properties" ON properties;
CREATE POLICY "Users can update own properties" ON properties FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = user_id) WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own properties" ON properties;
CREATE POLICY "Users can delete own properties" ON properties FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- documents
DROP POLICY IF EXISTS "Users can view own documents" ON documents;
CREATE POLICY "Users can view own documents" ON documents FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own documents" ON documents;
CREATE POLICY "Users can insert own documents" ON documents FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own documents" ON documents;
CREATE POLICY "Users can delete own documents" ON documents FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

-- applications
DROP POLICY IF EXISTS "Users can view own applications" ON applications;
CREATE POLICY "Users can view own applications" ON applications FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Appraisers can view assigned applications" ON applications;
CREATE POLICY "Appraisers can view assigned applications" ON applications FOR SELECT TO authenticated USING ((SELECT auth.uid()) = appraiser_id);

DROP POLICY IF EXISTS "Users can insert own applications" ON applications;
CREATE POLICY "Users can insert own applications" ON applications FOR INSERT TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Appraisers can update assigned applications" ON applications;
CREATE POLICY "Appraisers can update assigned applications" ON applications FOR UPDATE TO authenticated USING ((SELECT auth.uid()) = appraiser_id);

-- appraisals
DROP POLICY IF EXISTS "Users can view own appraisals" ON appraisals;
CREATE POLICY "Users can view own appraisals" ON appraisals FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM applications WHERE applications.id = appraisals.application_id AND applications.user_id = (SELECT auth.uid())));

DROP POLICY IF EXISTS "Appraisers can view assigned appraisals" ON appraisals;
CREATE POLICY "Appraisers can view assigned appraisals" ON appraisals FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM applications WHERE applications.id = appraisals.application_id AND applications.appraiser_id = (SELECT auth.uid())));

DROP POLICY IF EXISTS "Appraisers can insert appraisals" ON appraisals;
CREATE POLICY "Appraisers can insert appraisals" ON appraisals FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM applications WHERE applications.id = appraisals.application_id AND applications.appraiser_id = (SELECT auth.uid())));

-- market_data
DROP POLICY IF EXISTS "Anyone can view market data" ON market_data;
CREATE POLICY "Anyone can view market data" ON market_data FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Authenticated users can view market data" ON market_data;
CREATE POLICY "Authenticated users can view market data" ON market_data FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert market data" ON market_data;
CREATE POLICY "Authenticated users can insert market data" ON market_data FOR INSERT TO authenticated WITH CHECK (true);

-- ============================================
-- ROW LEVEL SECURITY — Supabase Storage
-- ============================================

DROP POLICY IF EXISTS "Users can upload to own folder" ON storage.objects;
CREATE POLICY "Users can upload to own folder" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user-docs' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

DROP POLICY IF EXISTS "Users can view own files" ON storage.objects;
CREATE POLICY "Users can view own files" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'user-docs' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
CREATE POLICY "Users can delete own files" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'user-docs' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

-- ============================================
-- TRIGGERS
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON profiles;
CREATE TRIGGER trigger_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trigger_applications_updated_at ON applications;
CREATE TRIGGER trigger_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION update_updated_at();

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
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
