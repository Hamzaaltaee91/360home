-- This is an Iraq-focused platform (Arabic UI, Iraqi governorates, د.ع
-- shown everywhere), but property_requests/realtor_offers.currency
-- defaulted to 'AED' — no form on the site ever lets a user pick a
-- currency, so every row silently inherited the wrong default unless
-- something explicitly set 'IQD'. realtor_properties already defaults
-- to 'IQD' correctly; bringing these two in line. Existing rows are
-- left untouched (changing their stated currency after the fact would
-- misrepresent the actual price, not fix it).
ALTER TABLE public.property_requests ALTER COLUMN currency SET DEFAULT 'IQD';
ALTER TABLE public.realtor_offers ALTER COLUMN currency SET DEFAULT 'IQD';
