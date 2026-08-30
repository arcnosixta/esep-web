-- ESEP: фикс infinite recursion в RLS для profiles
-- Причина: политика админа на profiles сама query'ит profiles → петля.
-- Решение: проверка через SECURITY DEFINER функцию.

-- 1. Убираем рекурсивные политики на profiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can delete all profiles" ON profiles;

-- 2. Вспомогательная функция без RLS-петли
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE user_id = auth.uid()
      AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Повторно создаём админские политики на profiles через функцию
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete all profiles" ON profiles
  FOR DELETE TO authenticated USING (public.is_admin());
