-- Realtor's saved property inventory, so they can pick from a list
-- instead of retyping the same property into every offer.
CREATE TABLE public.realtor_properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  realtor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  address TEXT NOT NULL,
  price DECIMAL(15, 2),
  currency TEXT DEFAULT 'IQD',
  lease_type TEXT CHECK (lease_type IN ('rent', 'sale')),
  area_sqft INT,
  bedrooms INT,
  bathrooms INT,
  furnished BOOLEAN,
  photo_urls TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_realtor_properties_realtor_id ON public.realtor_properties(realtor_id);

ALTER TABLE public.realtor_properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "realtor_properties_select_own" ON public.realtor_properties
  FOR SELECT USING (current_user_id() = realtor_id);

CREATE POLICY "realtor_properties_insert_own" ON public.realtor_properties
  FOR INSERT WITH CHECK (current_user_id() = realtor_id);

CREATE POLICY "realtor_properties_update_own" ON public.realtor_properties
  FOR UPDATE USING (current_user_id() = realtor_id) WITH CHECK (current_user_id() = realtor_id);

CREATE POLICY "realtor_properties_delete_own" ON public.realtor_properties
  FOR DELETE USING (current_user_id() = realtor_id);

CREATE POLICY "realtor_properties_admin_all" ON public.realtor_properties
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE TRIGGER update_realtor_properties_updated_at
  BEFORE UPDATE ON public.realtor_properties
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
