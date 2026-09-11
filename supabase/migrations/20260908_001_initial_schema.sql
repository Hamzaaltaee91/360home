-- Phase 1: Database Schema for Dabberli
-- Created: 2026-09-08

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "cube";
CREATE EXTENSION IF NOT EXISTS "earthdistance" CASCADE;

-- Users table
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('buyer', 'realtor', 'admin')),
  is_verified BOOLEAN DEFAULT false,
  profile_picture_url TEXT,
  bio TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_auth_id ON public.users(auth_id);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_email ON public.users(email);

-- Realtors table
CREATE TABLE public.realtors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  license_number TEXT NOT NULL UNIQUE,
  license_expiry DATE NOT NULL,
  specializations TEXT[] DEFAULT '{}',
  average_rating DECIMAL(3, 2) DEFAULT 0.0,
  total_offers INT DEFAULT 0,
  verified_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_realtors_user_id ON public.realtors(user_id);
CREATE INDEX idx_realtors_verified_at ON public.realtors(verified_at);
CREATE INDEX idx_realtors_license_number ON public.realtors(license_number);

-- Property requests table
CREATE TABLE public.property_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('residential', 'commercial', 'land')),
  title TEXT NOT NULL,
  description TEXT,

  -- Location
  city TEXT NOT NULL,
  area_name TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),

  -- Budget
  min_price DECIMAL(15, 2),
  max_price DECIMAL(15, 2),
  currency TEXT DEFAULT 'AED',

  -- Property-specific criteria
  min_area_sqft INT,
  max_area_sqft INT,
  bedrooms INT,
  bathrooms INT,
  furnished BOOLEAN,

  -- Meta
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'sold', 'rented')),
  is_urgent BOOLEAN DEFAULT false,
  preferred_contact TEXT[] DEFAULT '{}',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP
);

CREATE INDEX idx_property_requests_buyer_id ON public.property_requests(buyer_id);
CREATE INDEX idx_property_requests_category ON public.property_requests(category);
CREATE INDEX idx_property_requests_city ON public.property_requests(city);
CREATE INDEX idx_property_requests_status ON public.property_requests(status);
CREATE INDEX idx_property_requests_expires_at ON public.property_requests(expires_at);

-- Realtor offers table
CREATE TABLE public.realtor_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  realtor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  request_id UUID NOT NULL REFERENCES public.property_requests(id) ON DELETE CASCADE,

  -- Offer details
  property_title TEXT NOT NULL,
  property_description TEXT,
  property_address TEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),

  -- Price & terms
  offered_price DECIMAL(15, 2) NOT NULL,
  currency TEXT DEFAULT 'AED',
  lease_type TEXT CHECK (lease_type IN ('rent', 'sale')),
  lease_duration_months INT,

  -- Property specs
  area_sqft INT,
  bedrooms INT,
  bathrooms INT,
  furnished BOOLEAN,

  -- Documents & media
  photo_urls TEXT[] DEFAULT '{}',
  document_urls TEXT[] DEFAULT '{}',

  -- Status & engagement
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  buyer_response TEXT,
  message_to_buyer TEXT,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '30 days'
);

CREATE INDEX idx_realtor_offers_realtor_id ON public.realtor_offers(realtor_id);
CREATE INDEX idx_realtor_offers_request_id ON public.realtor_offers(request_id);
CREATE INDEX idx_realtor_offers_status ON public.realtor_offers(status);
CREATE INDEX idx_realtor_offers_buyer_response ON public.realtor_offers(buyer_response);
CREATE INDEX idx_realtor_offers_expires_at ON public.realtor_offers(expires_at);

-- Offer interactions table
CREATE TABLE public.offer_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id UUID NOT NULL REFERENCES public.realtor_offers(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  realtor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  interaction_type TEXT NOT NULL CHECK (interaction_type IN ('view', 'message', 'call_request', 'meeting_request')),
  message_content TEXT,

  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_offer_interactions_offer_id ON public.offer_interactions(offer_id);
CREATE INDEX idx_offer_interactions_buyer_id ON public.offer_interactions(buyer_id);
CREATE INDEX idx_offer_interactions_realtor_id ON public.offer_interactions(realtor_id);

-- Verifications table
CREATE TABLE public.verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  verification_type TEXT NOT NULL CHECK (verification_type IN ('realtor_license', 'identity', 'business_registration')),
  document_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  verified_by UUID REFERENCES public.users(id),

  created_at TIMESTAMP DEFAULT NOW(),
  reviewed_at TIMESTAMP
);

CREATE INDEX idx_verifications_user_id ON public.verifications(user_id);
CREATE INDEX idx_verifications_status ON public.verifications(status);
CREATE INDEX idx_verifications_verification_type ON public.verifications(verification_type);

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.realtors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.realtor_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offer_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifications ENABLE ROW LEVEL SECURITY;
