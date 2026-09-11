-- Phase 2: PostGIS & Geospatial Support
-- Created: 2026-09-11
-- Enables PostGIS for radius/distance search on property_requests.

-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- ============================================
-- GEOGRAPHY COLUMN
-- ============================================

ALTER TABLE public.property_requests
  ADD COLUMN IF NOT EXISTS location geography(Point, 4326);

-- Backfill from existing latitude/longitude
UPDATE public.property_requests
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND location IS NULL;

-- ============================================
-- INDEX
-- ============================================

CREATE INDEX IF NOT EXISTS idx_property_requests_location
  ON public.property_requests
  USING GIST (location);

-- ============================================
-- TRIGGER: keep location in sync with lat/lng
-- ============================================

CREATE OR REPLACE FUNCTION public.sync_property_request_location()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location := ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude), 4326
    )::geography;
  ELSE
    NEW.location := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_property_request_location_sync
  ON public.property_requests;

CREATE TRIGGER on_property_request_location_sync
  BEFORE INSERT OR UPDATE OF latitude, longitude
  ON public.property_requests
  FOR EACH ROW EXECUTE FUNCTION public.sync_property_request_location();

-- ============================================
-- FUNCTION: nearby_requests_postgis
-- Radius search using PostGIS ST_DWithin (meters).
-- ============================================

CREATE OR REPLACE FUNCTION public.nearby_requests_postgis(
  p_lat DECIMAL,
  p_lng DECIMAL,
  p_radius_m INT
)
RETURNS TABLE (
  request_id UUID,
  request_buyer_id UUID,
  request_category TEXT,
  request_title TEXT,
  request_city TEXT,
  request_min_price DECIMAL,
  request_max_price DECIMAL,
  request_bedrooms INT,
  request_bathrooms INT,
  request_status TEXT,
  distance_m INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pr.id,
    pr.buyer_id,
    pr.category,
    pr.title,
    pr.city,
    pr.min_price,
    pr.max_price,
    pr.bedrooms,
    pr.bathrooms,
    pr.status,
    ST_Distance(
      pr.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    )::INT AS distance_m
  FROM public.property_requests pr
  WHERE pr.status = 'active'
    AND pr.location IS NOT NULL
    AND ST_DWithin(
      pr.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    )
  ORDER BY distance_m ASC;
END;
$$ LANGUAGE plpgsql STABLE;
