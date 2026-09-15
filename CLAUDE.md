# Dabberli (دبّرلي) - Reverse Real Estate Platform

## Project Overview

**Dabberli** is an innovative **reverse real estate platform** that flips the traditional property listing model. Instead of realtors/owners posting properties for buyers to browse, buyers and renters post their property requirements and verified realtors/owners pitch matching offers directly to them.

### Platform Categories
- **Residential**: Apartments, houses, villas, and other residential properties
- **Commercial**: Office spaces, retail shops, warehouses, and commercial buildings
- **Land**: Plots and land for development or investment

### Key Differentiators
- **Buyer-centric**: Users define their exact criteria and receive curated offers
- **Verification**: Realtors and owners undergo verification to ensure legitimacy
- **Efficiency**: Direct matching reduces time spent browsing irrelevant listings
- **Transparency**: Strict role-based access controls and audit trails

---

## Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
  - Cross-platform mobile (iOS/Android) and web support
  - Strong type safety and performance
  - Rich widget ecosystem for complex UIs

### Backend & Database
- **Backend-as-a-Service**: Supabase (PostgreSQL-based)
- **Database**: PostgreSQL with Row-Level Security (RLS)
- **Real-time Features**: Supabase Realtime for live notifications
- **Authentication**: Supabase Auth (email/OAuth)
- **File Storage**: Supabase Storage for property photos, documents

### Rationale for Supabase + PostgreSQL + RLS
- **Rapid Development**: Zero backend code for common operations
- **Security**: PostgreSQL RLS enforces data access rules at the database layer, preventing data leaks
- **Scalability**: PostgreSQL handles complex queries; Supabase provides managed infrastructure
- **Cost-Effective**: Pay-as-you-go pricing; no expensive backend server maintenance
- **Type Safety**: Auto-generated TypeScript/Dart types from PostgreSQL schema

---

## Architecture Overview

### High-Level Data Flow
```
Flutter App (Mobile/Web)
    ↓
Supabase Client SDK
    ↓
Supabase Auth & APIs
    ↓
PostgreSQL Database (with RLS policies)
    ↓
Real-time subscriptions → Flutter app updates
```

### Core User Roles
1. **Buyer**: Posts property requests, reviews offers, communicates with realtors
2. **Realtor**: Verified professional, creates offers for buyer requests
3. **Admin**: Manages user verification, disputes, platform settings

### System Layers
- **Presentation Layer**: Flutter UI widgets for each role and feature
- **Data Layer**: Supabase client for API calls and real-time subscriptions
- **Authentication Layer**: Supabase Auth with custom JWT claims for roles
- **Database Layer**: PostgreSQL tables with RLS policies enforcing access control

---

## Database Schema (Phase 1)

### 1. Users Table (`public.users`)
Stores user profiles with role-based differentiation.

```sql
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
```

**Purpose**: Central user repository; `role` determines access permissions.

### 2. Realtors Table (`public.realtors`)
Additional profile data for realtor-specific attributes.

```sql
CREATE TABLE public.realtors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  license_number TEXT NOT NULL UNIQUE,
  license_expiry DATE NOT NULL,
  specializations TEXT[] DEFAULT '{}', -- e.g., ['residential', 'commercial']
  average_rating DECIMAL(3, 2) DEFAULT 0.0,
  total_offers INT DEFAULT 0,
  verified_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_realtors_user_id ON public.realtors(user_id);
CREATE INDEX idx_realtors_verified_at ON public.realtors(verified_at);
```

**Purpose**: Realtor-specific metadata; enables realtor verification workflow.

### 3. Property Requests Table (`public.property_requests`)
Buyer-posted property criteria across residential, commercial, and land categories.

```sql
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
  preferred_contact TEXT[] DEFAULT '{}', -- e.g., ['call', 'whatsapp', 'email']
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP
);

CREATE INDEX idx_property_requests_buyer_id ON public.property_requests(buyer_id);
CREATE INDEX idx_property_requests_category ON public.property_requests(category);
CREATE INDEX idx_property_requests_city ON public.property_requests(city);
CREATE INDEX idx_property_requests_status ON public.property_requests(status);
CREATE INDEX idx_property_requests_location ON public.property_requests USING GIST (
  ll_to_earth(latitude, longitude)
);
```

**Purpose**: Central table for all property criteria posted by buyers; supports filtering by category, location, budget, and amenities.

**Additional columns (added September 2026, `supabase/migrations/20260911000004`–`20260911000008`):**

| Column | Type | Constraint | Purpose |
|---|---|---|---|
| `purpose` | TEXT | `NOT NULL CHECK (purpose IN ('rent', 'buy'))` | Distinguishes rental requests from purchase requests. |
| `governorate` | TEXT | `CHECK` against the 18 Iraq governorate slugs (e.g. `baghdad`, `basra`, `nineveh`) | English-slug governorate, separate from the free-text legacy `city` column. |
| `area` | TEXT | nullable | Selected sub-area within the governorate, or free text when the user picks "أخرى" (other); separate from the legacy `area_name` column. |
| `property_subtype` | TEXT | `CHECK (category <> 'residential' OR property_subtype IN ('apartment', 'house', 'villa', 'duplex'))` | Residential-only subtype; unconstrained (and typically null) for non-residential categories. |
| `rental_period` | TEXT | `CHECK (rental_period IN ('daily', 'weekly', 'monthly', 'yearly'))`, nullable | Rental cadence; only meaningful when `purpose = 'rent'` — null for `buy` requests. |

### 4. Realtor Offers Table (`public.realtor_offers`)
Realtors submit offers matching buyer requests.

```sql
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
  photo_urls TEXT[] DEFAULT '{}', -- Array of Supabase Storage URLs
  document_urls TEXT[] DEFAULT '{}', -- Deeds, certificates, etc.
  
  -- Status & engagement
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  buyer_response TEXT, -- 'interested', 'not_interested', NULL (pending)
  message_to_buyer TEXT,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '30 days'
);

CREATE INDEX idx_realtor_offers_realtor_id ON public.realtor_offers(realtor_id);
CREATE INDEX idx_realtor_offers_request_id ON public.realtor_offers(request_id);
CREATE INDEX idx_realtor_offers_status ON public.realtor_offers(status);
CREATE INDEX idx_realtor_offers_buyer_response ON public.realtor_offers(buyer_response);
```

**Purpose**: Realtors pitch property offers; buyers review and respond with interest/rejection.

### 5. Offer Interactions Table (`public.offer_interactions`)
Tracks communication and interest history between buyers and realtors.

```sql
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
```

**Purpose**: Audit trail for interactions; enables analytics and follow-up features.

### 6. Verifications Table (`public.verifications`)
Tracks realtor/user verification documents and status.

```sql
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
```

**Purpose**: Manages verification workflows for realtor credibility.

---

## Authentication & Authorization Strategy

### User Authentication (Phase 1)
- **Supabase Auth** handles email/password and social login (Google, Apple)
- Email verification required for account activation
- Custom JWT claims include `user_id` and `role`

### Row-Level Security (RLS) Policies

#### Users Table RLS
```sql
-- Users can only view their own profile
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = auth_id);

-- Users can only update their own profile
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = auth_id);

-- Public can view minimal realtor profiles (for offer context)
CREATE POLICY "users_select_realtor_public" ON public.users
  FOR SELECT USING (role = 'realtor' AND is_verified = true);
```

#### Property Requests RLS
```sql
-- Buyers can only view their own requests
CREATE POLICY "property_requests_select_own" ON public.property_requests
  FOR SELECT USING (auth.uid() = buyer_id);

-- Buyers can only insert their own requests
CREATE POLICY "property_requests_insert_own" ON public.property_requests
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- Buyers can only update their own requests
CREATE POLICY "property_requests_update_own" ON public.property_requests
  FOR UPDATE USING (auth.uid() = buyer_id);

-- Realtors can view active requests to create offers
CREATE POLICY "property_requests_select_active_for_realtor" ON public.property_requests
  FOR SELECT USING (
    status = 'active' AND 
    EXISTS (SELECT 1 FROM public.realtors WHERE user_id = auth.uid())
  );
```

#### Realtor Offers RLS
```sql
-- Realtors can only create/view their own offers
CREATE POLICY "realtor_offers_select_own" ON public.realtor_offers
  FOR SELECT USING (auth.uid() = realtor_id);

CREATE POLICY "realtor_offers_insert_own" ON public.realtor_offers
  FOR INSERT WITH CHECK (auth.uid() = realtor_id);

-- Buyers can view offers on their own requests
CREATE POLICY "realtor_offers_select_for_buyer" ON public.realtor_offers
  FOR SELECT USING (
    auth.uid() = (
      SELECT buyer_id FROM public.property_requests WHERE id = request_id
    )
  );

-- Buyers can update offer response (accept/reject)
CREATE POLICY "realtor_offers_update_buyer_response" ON public.realtor_offers
  FOR UPDATE USING (
    auth.uid() = (
      SELECT buyer_id FROM public.property_requests WHERE id = request_id
    )
  )
  WITH CHECK (
    auth.uid() = (
      SELECT buyer_id FROM public.property_requests WHERE id = request_id
    )
  );
```

#### Offer Interactions RLS
```sql
-- Only involved parties (buyer/realtor) can view interactions
CREATE POLICY "offer_interactions_select_involved" ON public.offer_interactions
  FOR SELECT USING (
    auth.uid() = buyer_id OR auth.uid() = realtor_id
  );

-- System automatically inserts interactions
CREATE POLICY "offer_interactions_insert" ON public.offer_interactions
  FOR INSERT WITH CHECK (true);
```

### Authorization Model
- **Buyer**: Can create property requests, view offers, respond to offers
- **Realtor**: Can view active property requests, create offers, view buyer responses
- **Admin**: Manages verifications, resolves disputes, system settings (not Phase 1)

---

## Coding Standards

### Git Workflow
- **Branch naming**: Feature branches follow `feature/` prefix for features, `fix/` for bugs, `docs/` for documentation
- **Commit messages**: Clear, descriptive, present tense (e.g., "Add property request schema")
- **Pull requests**: Require code review; reference related issues

### Dart/Flutter
- **Format**: Use `dart format` (automatic formatting)
- **Linting**: Enable all linter rules via `analysis_options.yaml`
- **Null Safety**: Strict null safety enabled; use non-nullable by default
- **Naming Conventions**:
  - Classes: `PascalCase`
  - Functions/variables: `camelCase`
  - Constants: `CONSTANT_CASE`
  - Private members: `_privateVariable`
- **Comments**: Minimal comments; code should be self-documenting. Use comments only for "why", not "what"
- **Testing**: Write unit tests for business logic; widget tests for UI components

### SQL/PostgreSQL
- **Table naming**: `snake_case`, plural (e.g., `property_requests`)
- **Column naming**: `snake_case`, descriptive (e.g., `offered_price`, not `price`)
- **Constraints**: Always include NOT NULL, UNIQUE, FOREIGN KEY constraints
- **Indexes**: Create indexes on frequently queried columns (foreign keys, status, dates)
- **Comments**: Document complex triggers, functions, and business rules
- **Migrations**: Use SQL migration files; version incrementally

### TypeScript/JavaScript (if backend needed later)
- **Format**: Use Prettier for formatting
- **Linting**: ESLint with recommended rules
- **Naming**: Same as Dart conventions
- **Type Safety**: Strict TypeScript; avoid `any` type

### Documentation
- **README.md**: Setup, running, deployment instructions
- **CLAUDE.md**: Architecture, phasing, standards (this file)
- **Code comments**: Explain non-obvious logic and business decisions
- **API docs**: Document Supabase schema and RLS policies in CLAUDE.md

---

## Phased Implementation Plan

### Phase 1: Database Schema & Authentication ✓ CURRENT
**Objective**: Establish secure data foundation with verified roles and RLS policies.

#### Deliverables
1. **Database Migration Files** (`supabase/migrations/`)
   - `001_initial_schema.sql` - Create all Phase 1 tables
   - `002_rls_policies.sql` - Implement RLS policies
   - `003_indexes.sql` - Create performance indexes

2. **Supabase Configuration**
   - Enable Row-Level Security on all tables
   - Configure auth.users JWT claims for role
   - Setup Storage buckets for property photos/documents

3. **Documentation**
   - Schema diagram (ERD)
   - RLS policy matrix (who can access what)
   - Authentication flow diagram

#### Key Decisions
- ✅ PostgreSQL for relational data + RLS enforcement
- ✅ Separate `users` and `realtors` tables (realtor = enhanced user profile)
- ✅ Property requests support multiple categories with flexible schemas
- ✅ Offers expire after 30 days; buyers can view offers in real-time

#### Timeline: 1-2 weeks
- Setup Supabase project and PostgreSQL database
- Create migration files and test locally
- Deploy to development environment
- Verify RLS policies block unauthorized access

---

### Phase 2: Backend Services & API Layer
**Objective**: Implement business logic for verification, notifications, and complex queries.

#### Planned Services
- **Realtor Verification Service**: Admin approval workflow for license validation
- **Offer Matching Engine**: Recommend matching property requests to realtors
- **Notification Service**: Real-time alerts for new offers, messages, requests
- **Search & Filtering Service**: Geospatial queries, budget filters, category sorting
- **Analytics Service**: Track user engagement, offer response rates

#### Deliverables
- Supabase Edge Functions for server-side logic
- Trigger-based automatic interaction logging
- Real-time subscriptions configuration

#### Timeline: 2-3 weeks (dependent on Phase 1 completion)

---

### Phase 3: Flutter Mobile/Web App
**Objective**: Build user interfaces for buyers, realtors, and admins.

#### Screens (Buyer App)
1. **Authentication**: Signup, login, email verification
2. **Home**: Active requests, offer summaries, notifications
3. **Create Request**: Multi-step form for property criteria
4. **Browse Offers**: List/map view of incoming offers, filters
5. **Offer Details**: Full property info, realtor profile, communication
6. **Profile**: User preferences, saved requests, interaction history

#### Screens (Realtor App)
1. **Authentication**: Signup, license verification, login
2. **Dashboard**: Active offers, response rates, earnings
3. **Browse Requests**: Filter by category/location, search
4. **Create Offer**: Submit property details + photos for matching request
5. **Offer Management**: Track status, buyer interactions, follow-ups
6. **Profile**: License info, ratings, specializations

#### Deliverables
- Flutter app with navigation structure
- Supabase client integration (auth, real-time subscriptions)
- Responsive UI for mobile and web
- Photo upload with Supabase Storage

#### Timeline: 3-4 weeks (after Phase 2)

---

### Phase 4: Admin Panel & Verification Workflows
**Objective**: Empower admins to moderate platform, approve realtors, resolve disputes.

#### Features
- Admin dashboard for user management
- Verification document review interface
- Dispute resolution tools
- Platform analytics and reports
- Settings management (categories, currencies, etc.)

#### Timeline: 2-3 weeks (parallel with Phase 3)

---

### Phase 5: Advanced Features & Polish
**Objective**: Enhance user experience with ratings, messaging, and analytics.

#### Features
- Realtor ratings and reviews
- In-app messaging/chat between buyers and realtors
- Saved favorites and request templates
- Analytics dashboards for buyers and realtors
- Performance optimization and caching

#### Timeline: 2-3 weeks (dependent on Phase 4)

---

## Development Environment Setup (Phase 1)

### Prerequisites
- Flutter SDK (latest stable)
- PostgreSQL 14+
- Supabase CLI
- Git

### Local Development
```bash
# Clone the repository
git clone <repo_url>
cd dabberli

# Initialize Supabase locally
supabase init
supabase start

# Run migrations
supabase migration up

# Run tests
supabase test

# View database in local dashboard
supabase studio
```

### Deployment
- Development: Supabase free tier (or dedicated project)
- Production: Supabase Pro tier with backups and SLA
- Flutter app: Build via CI/CD (GitHub Actions) → App Store / Play Store

---

## Success Metrics & Milestones

### Phase 1 Success Criteria
- ✅ All tables created and RLS policies active
- ✅ Supabase project accessible with secure auth
- ✅ Manual testing confirms RLS blocks unauthorized access
- ✅ Documentation complete and reviewed

### Overall Platform KPIs (Future)
- User acquisition: 1000+ buyers, 100+ verified realtors by end of Year 1
- Offer-to-match ratio: 80%+ of offers accepted/followed up by buyers
- Realtor verification turnaround: <24 hours
- Platform uptime: 99.9%
- Data security: Zero breach incidents

---

## Security & Compliance

### Data Protection (Phase 1)
- ✅ Row-Level Security enforces data isolation at database layer
- ✅ All sensitive data (phone, address) visible only to involved parties
- ✅ Email uniqueness prevents account duplication
- ✅ Auth tokens rotate on logout

### Planned Security Features (Future Phases)
- Realtor license verification via government database
- Two-factor authentication (2FA) for realtors
- Document encryption for stored sensitive files
- Audit logs for all admin actions
- GDPR compliance (data export, deletion)
- Fraud detection for suspicious offers

---

## Next Steps

### Immediate Actions (Awaiting Approval)
1. ✅ Review and approve this CLAUDE.md
2. ⏳ Create Supabase project (free tier or dedicated)
3. ⏳ Write Phase 1 database migration files
4. ⏳ Test RLS policies in local development
5. ⏳ Document schema diagram and deployment steps

### Questions for Review
- Realtor verification workflow: Email + document upload, or API integration with government databases?
- Realtor ratings: 5-star scale or more detailed feedback?
- Pricing model for Phase 2: Commission per successful match, or subscription tier?

---

**Author**: Claude Haiku 4.5  
**Last Updated**: 2026-09-08  
**Status**: Draft (Awaiting Approval)

## Claude Code reviewer role (added on top of existing docs above)

You are also the "thinking layer" above an autonomous pilot (auto_pilot.sh, tmux session "pilot").

### Pilot mechanics:
- Reads tasks from TODO.md (one line per task)
- 5 gates before any commit: static analysis (skipped), sanity_check.py, size limit (5 files/300 lines), security check (blocks RLS/roles/secrets), real CI wait
- Any gate failure = full rollback (git reset --hard)

### Your duties:
- Do not edit code directly unless the user explicitly asks
- Review aider.log and TODO.md when asked
- RLS/roles/secrets/migrations, live prod DB (updated 2026-09-15, user's explicit request — full delegation): you may write and apply these yourself — via a pilot task, or directly against the live Supabase project using the Supabase MCP tools — without stopping to ask first, PROVIDED you have personally verified the change: read the current live policy/function/schema (`pg_get_functiondef`, `pg_policies`, `information_schema.columns` — migration files can drift from what's actually deployed, confirmed this exact drift on 2026-09-15's get_matching_offers fix), cross-check for later migrations that may have already patched it, and confirm post-apply (re-read the policy/trigger, run `get_advisors`) that it took effect and introduced no new findings. Still stop and ask when: you can't verify current live state, the fix is ambiguous/has open design questions (note them instead of guessing), or it's something the platform itself blocks you from doing (e.g. editing auto_pilot.sh's own gates was refused by an "unsafe agent" classifier on 2026-09-15 — do not attempt to work around a platform-level refusal). Report what you did afterward (commit message + Telegram notify), same as any other applied fix — delegation removes the pre-approval stop, not the audit trail.

### When to notify via Telegram (~/pilot/scripts/notify.sh "message")
Send ONLY when: a gate blocked a task, a task fully completed/merged, pilot stuck/idle a while, you applied an RLS/roles/secrets/migrations change yourself, or CI failed after passing local gates.
Do NOT send for: routine progress, minor pilot activity, anything already visible in TODO.md.

### Key files:
- ~/pilot/README.md, ~/pilot/aider.log, TODO.md at repo root

### Raw task pre-formatting (raw_inbox → inbox.txt)

As part of each `/loop` check, also inspect `~/pilot/state/raw_inbox`. Telegram's `task:` command writes raw, unscoped requests there instead of straight into the queue. For each line found in it:

1. Read the repo to determine the single file the task should touch.
2. Rewrite the line as one single line, following the exact style already used in TODO.md: a task description ending with "Touch only <file> — nothing under lib/, no other file."
3. Append that formatted line to `~/pilot/state/inbox.txt` — this is what `auto_pilot.sh` reads and turns into a TODO.md entry.
4. Clear `raw_inbox` after processing that line.
5. Send a Telegram confirmation via `~/pilot/scripts/notify.sh` with the final formatted task text.
6. If a request is too vague to safely scope to one file, do not guess. Send a Telegram message via `~/pilot/scripts/notify.sh` asking for clarification instead, and leave it out of `inbox.txt`.

### Continuous live review during pilot runs

While `auto_pilot.sh` has an active task (not idle), watch `~/pilot/logs/pilot.log` live for: task start, `chore: mark task done`, `chore: block task`, gate-fail entries, and the CI conclusion line (`✓`/`X ... in Ns (ID ...)`).

After each task lands (gates passed, CI green), review the actual commit's diff (`git show <sha>`), not just the fact that its gates passed — the gates catch mechanical failures (size, sanity, security keywords), not semantic ones (wrong scope, wrong file touched, broken UX, hallucinated logic).

If a landed commit is wrong despite green gates/CI:
1. Pause the pilot via `touch ~/pilot/state/paused` — the same flag `telegram_bot.sh`'s `pause` command sets. Never `tmux kill-session` or any other hard stop.
2. Fix forward with a new commit (edit the file directly, or edit the relevant TODO.md line to redirect future attempts). Never `git reset --hard` or force-push to undo a landed commit — hard rollback is the pilot's own mechanism for gate failures, not something to invoke on a commit that already passed gates and CI.
3. Resume by removing the pause flag (`rm ~/pilot/state/paused`).
4. Send a Telegram summary of what was wrong, what was changed, and that the pilot has resumed.

RLS/roles/secrets/migrations fixes-forward are now in scope for you too (see "Your duties" above, updated 2026-09-15) — apply directly if you've verified it against live state, report afterward. Still pause and ask if you can't verify it or it's genuinely ambiguous.
