-- ESEP: минимальный патч для avatar/cover и админского просмотра документов/заявок
-- Запускать в Supabase → SQL Editor

-- 1. Добавляем недостающие поля в profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS cover_url TEXT;

-- 2. Админ может видеть/изменять профили
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- 3. Админ может видеть все документы
DROP POLICY IF EXISTS "Admins can view all documents" ON documents;
CREATE POLICY "Admins can view all documents" ON documents
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );

-- 4. Админ может видеть все заявки
DROP POLICY IF EXISTS "Admins can view all applications" ON applications;
CREATE POLICY "Admins can view all applications" ON applications
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
  );
