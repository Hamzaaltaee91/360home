-- Backing store for the shared Edge Function rate limiter
-- (supabase/functions/_shared/rate_limit.ts).
--
-- Written by hand (not by the autonomous pilot): this is infrastructure
-- for the Edge Functions layer, which the pilot never touches per
-- CONVENTIONS.md §5. Every read/write to this table happens through an
-- Edge Function's service-role client, which bypasses RLS entirely — RLS
-- is enabled anyway with no policies, so a client that somehow obtained
-- only the anon/authenticated role could never read or write it directly.

CREATE TABLE public.rate_limit_hits (
  id BIGSERIAL PRIMARY KEY,
  function_name TEXT NOT NULL,
  identifier TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rate_limit_hits_lookup
  ON public.rate_limit_hits(function_name, identifier, created_at);

-- Old hits are useless once their window has passed; keep the table small.
CREATE INDEX idx_rate_limit_hits_created_at ON public.rate_limit_hits(created_at);

ALTER TABLE public.rate_limit_hits ENABLE ROW LEVEL SECURITY;
-- No policies: only the service-role client (used exclusively by Edge
-- Functions) can read or write this table.
