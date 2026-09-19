-- Mirrors the existing expire_old_offers() pattern (also called
-- opportunistically — this project has no pg_cron scheduler). Marks
-- any active request older than 30 days as inactive, so realtors stop
-- seeing stale requests. The buyer can reactivate their own request
-- at any time from dashboard.html (already allowed by the existing
-- property_requests_update_own RLS policy).
CREATE OR REPLACE FUNCTION public.auto_expire_old_requests()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  rows_affected INT;
BEGIN
  UPDATE public.property_requests
  SET status = 'inactive'
  WHERE status = 'active'
    AND created_at < NOW() - INTERVAL '30 days';

  GET DIAGNOSTICS rows_affected = ROW_COUNT;
  RETURN rows_affected;
END;
$function$;
