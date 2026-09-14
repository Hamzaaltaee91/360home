-- Pin search_path on 15 pre-existing functions flagged by the Supabase
-- security advisor (function_search_path_mutable, WARN) after the
-- 2026-09-14 live deployment.
--
-- Written by hand (not by the autonomous pilot): touches function
-- definitions on prod DB, forbidden to the pilot per CONVENTIONS.md §5.
--
-- Same class of issue already fixed for write_audit_log in
-- 20260911000003_audit_logging.sql: a function with a mutable search_path
-- can be hijacked by a caller who creates same-named objects earlier in
-- their session search_path, redirecting unqualified references inside the
-- function body. ALTER FUNCTION ... SET search_path is used instead of
-- CREATE OR REPLACE so none of these function bodies need to be
-- reproduced from memory — only the search_path GUC is changed, the
-- compiled body is untouched.

alter function public.auto_expire_offers() set search_path = public, pg_temp;
alter function public.bulk_update_offer_responses(uuid, jsonb) set search_path = public, pg_temp;
alter function public.calculate_match_score(uuid, uuid) set search_path = public, pg_temp;
alter function public.check_realtor_verified() set search_path = public, pg_temp;
alter function public.get_buyer_offer_stats(uuid) set search_path = public, pg_temp;
alter function public.get_buyer_stats(uuid) set search_path = public, pg_temp;
alter function public.get_realtor_performance(uuid) set search_path = public, pg_temp;
alter function public.get_realtor_stats(uuid) set search_path = public, pg_temp;
alter function public.match_offers(uuid, text, integer) set search_path = public, pg_temp;
alter function public.nearby_requests_postgis(numeric, numeric, integer) set search_path = public, pg_temp;
alter function public.nearby_requests(numeric, numeric, integer) set search_path = public, pg_temp;
alter function public.search_requests(text, text, numeric, numeric, integer, integer, numeric, numeric, numeric, integer, integer) set search_path = public, pg_temp;
alter function public.sync_property_request_location() set search_path = public, pg_temp;
alter function public.update_realtor_stats() set search_path = public, pg_temp;
alter function public.update_updated_at_column() set search_path = public, pg_temp;
