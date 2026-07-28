-- ONLY creates the missing activity_logs table
-- Does NOT change any foreign keys or existing tables

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
CREATE POLICY "Users can view own logs" ON activity_logs FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admins can view all logs" ON activity_logs;
CREATE POLICY "Admins can view all logs" ON activity_logs FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM profiles WHERE user_id = (SELECT auth.uid()) AND role = 'admin')
);

DROP POLICY IF EXISTS "Authenticated users can insert logs" ON activity_logs;
CREATE POLICY "Authenticated users can insert logs" ON activity_logs FOR INSERT TO authenticated WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);
