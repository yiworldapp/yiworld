-- ============================================================
-- Young Indians (YI) - Supabase Schema
-- Run this in Supabase SQL Editor (top to bottom)
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================
-- ENUMS
-- ============================================================
CREATE TYPE member_type_enum AS ENUM ('member', 'committee', 'super_admin');

CREATE TYPE yi_vertical_enum AS ENUM (
  'yuva', 'thalir', 'rural_initiatives', 'masoom', 'road_safety',
  'health', 'accessibility', 'climate_change', 'entrepreneurship',
  'innovation', 'learning', 'branding', 'none'
);

CREATE TYPE yi_position_enum AS ENUM (
  'chair', 'co_chair', 'joint_chair', 'ec_member', 'mentor', 'none'
);

CREATE TYPE rsvp_status_enum AS ENUM ('going', 'not_going', 'maybe');
CREATE TYPE offer_type_enum  AS ENUM ('discount', 'freebie', 'cashback', 'exclusive');

-- ============================================================
-- HELPER TRIGGERS
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

-- ============================================================
-- TABLE: profiles
-- ============================================================
CREATE TABLE public.profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Auth
  phone               TEXT UNIQUE NOT NULL,
  phone_country_code  TEXT NOT NULL DEFAULT '+91',

  -- Identity
  first_name          TEXT NOT NULL DEFAULT '',
  last_name           TEXT NOT NULL DEFAULT '',
  primary_email       TEXT,
  secondary_email     TEXT,
  secondary_phone     TEXT,
  dob                 DATE,
  headshot_url        TEXT,

  -- Location
  address_line1       TEXT,
  address_line2       TEXT,
  country             TEXT,
  state               TEXT,
  city                TEXT,

  -- Professional
  company_name        TEXT,   -- NULL means "N/A"
  job_title           TEXT,
  industry            TEXT,   -- NULL means "N/A"
  business_bio        TEXT,
  business_website    TEXT,

  -- YI Membership
  yi_vertical         yi_vertical_enum NOT NULL DEFAULT 'none',
  yi_position         yi_position_enum NOT NULL DEFAULT 'none',
  yi_member_since     INT,              -- joining year e.g. 2023
  member_type         member_type_enum NOT NULL DEFAULT 'member',
  approved            BOOLEAN NOT NULL DEFAULT FALSE,

  -- Social Media
  linkedin_url        TEXT,
  instagram_url       TEXT,
  twitter_url         TEXT,
  facebook_url        TEXT,

  -- Personal
  personal_bio        TEXT,
  relationship_status TEXT,             -- 'married' | 'single'
  spouse_name         TEXT,             -- only set when relationship_status = 'married'
  is_spouse_yi_member BOOLEAN,          -- only set when relationship_status = 'married'
  anniversary_date    DATE,             -- only set when relationship_status = 'married'
  blood_group         TEXT,             -- A+, A-, B+, B-, AB+, AB-, O+, O-

  -- Tags (arrays of up to 3 each)
  business_tags       TEXT[] NOT NULL DEFAULT '{}',
  hobby_tags          TEXT[] NOT NULL DEFAULT '{}',

  -- Meta
  onboarding_done     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone)
  VALUES (NEW.id, COALESCE(NEW.phone, NEW.email, ''))
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-sync member_type based on yi_vertical
-- none → member (auto-approved), any other → committee (needs approval)
CREATE OR REPLACE FUNCTION public.sync_member_type()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.yi_vertical = 'none' THEN
    NEW.member_type := 'member';
    NEW.approved := TRUE;
  ELSIF NEW.yi_vertical IS NOT NULL AND OLD.yi_vertical IS DISTINCT FROM NEW.yi_vertical THEN
    -- Only reset to committee+unapproved if vertical changed (not if admin manually set super_admin)
    IF OLD.member_type != 'super_admin' THEN
      NEW.member_type := 'committee';
      NEW.approved := FALSE;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_member_type_trigger
  BEFORE INSERT OR UPDATE OF yi_vertical ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.sync_member_type();

-- ============================================================
-- TABLE: verticals (reference table for display labels/colors)
-- ============================================================
CREATE TABLE public.verticals (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug        yi_vertical_enum UNIQUE NOT NULL,
  label       TEXT NOT NULL,
  description TEXT,
  color_hex   TEXT,
  icon_url    TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.verticals (slug, label, description, color_hex) VALUES
  ('yuva',              'YUVA',                   'Youth leadership initiatives',          '#16a34a'),
  ('thalir',            'THALIR',                 'Green & sustainability initiatives',    '#22c55e'),
  ('rural_initiatives', 'Rural Initiatives',      'Rural development programs',            '#84cc16'),
  ('masoom',            'MASOOM',                 'Child welfare and education',           '#f97316'),
  ('road_safety',       'Road Safety',            'Road safety awareness campaigns',       '#ef4444'),
  ('health',            'Health',                 'Health & wellness programs',            '#06b6d4'),
  ('accessibility',     'Accessibility',          'Inclusive accessibility initiatives',   '#8b5cf6'),
  ('climate_change',    'Climate Change',         'Environmental sustainability',          '#10b981'),
  ('entrepreneurship',  'Entrepreneurship',       'Startup & entrepreneurship support',    '#f59e0b'),
  ('innovation',        'Innovation',             'Technology & innovation',               '#3b82f6'),
  ('learning',          'Learning',               'Education & skill development',         '#ec4899'),
  ('branding',          'Branding',               'YI branding & communications',          '#a855f7'),
  ('none',              'General Member',         'General YI member',                     '#6b7280');

-- ============================================================
-- TABLE: committees
-- ============================================================
CREATE TABLE public.committees (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  vertical_id UUID REFERENCES public.verticals(id),
  position    TEXT,
  joined_at   DATE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(profile_id)
);

-- ============================================================
-- TABLE: events
-- ============================================================
CREATE TABLE public.events (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title            TEXT NOT NULL,
  description      TEXT,
  vertical_id      UUID REFERENCES public.verticals(id),
  location_name    TEXT,
  location_lat     DOUBLE PRECISION,
  location_lng     DOUBLE PRECISION,
  location_url     TEXT,
  is_remote        BOOLEAN NOT NULL DEFAULT FALSE,
  starts_at        TIMESTAMPTZ NOT NULL,
  ends_at          TIMESTAMPTZ,
  cover_image_url  TEXT,
  is_published     BOOLEAN NOT NULL DEFAULT FALSE,
  max_attendees    INT,
  created_by       UUID REFERENCES public.profiles(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Event gallery (up to 10 items per event)
CREATE TABLE public.event_gallery (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  media_url   TEXT NOT NULL,
  media_type  TEXT NOT NULL DEFAULT 'image',  -- 'image' | 'video'
  caption     TEXT,
  sort_order  INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Event organizers (M:N - auto-populated from committee vertical)
CREATE TABLE public.event_organizers (
  event_id    UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  profile_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role        TEXT DEFAULT 'Organizer',
  PRIMARY KEY (event_id, profile_id)
);

-- ============================================================
-- TABLE: event_rsvps
-- ============================================================
CREATE TABLE public.event_rsvps (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id    UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  profile_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status      rsvp_status_enum NOT NULL DEFAULT 'going',
  rsvped_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(event_id, profile_id)
);

-- ============================================================
-- TABLE: mous
-- ============================================================
CREATE TABLE public.mous (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         TEXT NOT NULL,
  description   TEXT,
  pdf_url       TEXT NOT NULL,
  partner_name  TEXT,
  signed_date   DATE,
  expiry_date   DATE,
  created_by    UUID REFERENCES public.profiles(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER mous_updated_at
  BEFORE UPDATE ON public.mous
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- TABLE: partners
-- ============================================================
CREATE TABLE public.partners (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name         TEXT NOT NULL,
  description  TEXT,
  logo_url     TEXT,
  website_url  TEXT,
  category     TEXT,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER partners_updated_at
  BEFORE UPDATE ON public.partners
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- TABLE: offers
-- ============================================================
CREATE TABLE public.offers (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  partner_id      UUID NOT NULL REFERENCES public.partners(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  offer_type      offer_type_enum NOT NULL DEFAULT 'discount',
  discount_value  TEXT,
  coupon_code     TEXT,
  image_url       TEXT,
  how_to_claim    TEXT,
  terms           TEXT,
  valid_from      DATE,
  valid_until     DATE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER offers_updated_at
  BEFORE UPDATE ON public.offers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- TABLE: chat_embeddings (for YI AI Chat RAG)
-- ============================================================
CREATE TABLE public.chat_embeddings (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_type  TEXT NOT NULL,
  source_id    UUID NOT NULL,
  content      TEXT NOT NULL,
  embedding    vector(1536),
  metadata     JSONB,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(source_type, source_id)
);

CREATE INDEX ON public.chat_embeddings USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- ============================================================
-- VIEWS
-- ============================================================
CREATE VIEW public.events_with_stats AS
SELECT
  e.*,
  v.label     AS vertical_label,
  v.color_hex AS vertical_color,
  COUNT(r.id) FILTER (WHERE r.status = 'going') AS rsvp_count
FROM public.events e
LEFT JOIN public.verticals v ON v.id = e.vertical_id
LEFT JOIN public.event_rsvps r ON r.event_id = e.id
GROUP BY e.id, v.label, v.color_hex;

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Birthday lookup by month
CREATE OR REPLACE FUNCTION public.get_birthdays_by_month(target_month INT)
RETURNS TABLE (
  id           UUID,
  first_name   TEXT,
  last_name    TEXT,
  full_name    TEXT,
  headshot_url TEXT,
  dob          DATE,
  job_title    TEXT,
  company_name TEXT,
  age_turning  INT,
  days_until   INT
) LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    p.id,
    p.first_name,
    p.last_name,
    TRIM(p.first_name || ' ' || p.last_name) AS full_name,
    p.headshot_url,
    p.dob,
    p.job_title,
    p.company_name,
    DATE_PART('year', CURRENT_DATE)::INT - DATE_PART('year', p.dob)::INT AS age_turning,
    (MAKE_DATE(
      DATE_PART('year', CURRENT_DATE)::INT,
      DATE_PART('month', p.dob)::INT,
      DATE_PART('day', p.dob)::INT
    ) - CURRENT_DATE)::INT AS days_until
  FROM public.profiles p
  WHERE
    p.dob IS NOT NULL
    AND DATE_PART('month', p.dob) = target_month
    AND p.onboarding_done = TRUE
  ORDER BY DATE_PART('day', p.dob);
$$;

-- Vector similarity search for AI chat
CREATE OR REPLACE FUNCTION public.match_embeddings(
  query_embedding  vector(1536),
  match_threshold  FLOAT DEFAULT 0.75,
  match_count      INT   DEFAULT 5
)
RETURNS TABLE (
  id           UUID,
  source_type  TEXT,
  source_id    UUID,
  content      TEXT,
  similarity   FLOAT
) LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    id, source_type, source_id, content,
    1 - (embedding <=> query_embedding) AS similarity
  FROM public.chat_embeddings
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;

-- ============================================================
-- ROLE HELPER FUNCTIONS
-- ============================================================
CREATE OR REPLACE FUNCTION public.current_member_type()
RETURNS member_type_enum LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT member_type FROM public.profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.is_committee_or_above()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT current_member_type() IN ('super_admin', 'committee')
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verticals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.committees       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_gallery    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_organizers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_rsvps      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mous             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_embeddings  ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY "profiles_read_all"
  ON public.profiles FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_admin_all"
  ON public.profiles FOR ALL TO authenticated
  USING (current_member_type() = 'super_admin');

-- VERTICALS (public read)
CREATE POLICY "verticals_read"
  ON public.verticals FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "verticals_write_admin"
  ON public.verticals FOR ALL TO authenticated
  USING (current_member_type() = 'super_admin');

-- COMMITTEES
CREATE POLICY "committees_read"
  ON public.committees FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "committees_write_admin"
  ON public.committees FOR ALL TO authenticated
  USING (current_member_type() = 'super_admin');

-- EVENTS
CREATE POLICY "events_read"
  ON public.events FOR SELECT TO authenticated
  USING (is_published = TRUE OR is_committee_or_above());

CREATE POLICY "events_insert_committee"
  ON public.events FOR INSERT TO authenticated
  WITH CHECK (is_committee_or_above());

CREATE POLICY "events_update"
  ON public.events FOR UPDATE TO authenticated
  USING (
    current_member_type() = 'super_admin'
    OR (current_member_type() = 'committee' AND created_by = auth.uid())
  );

CREATE POLICY "events_delete_admin"
  ON public.events FOR DELETE TO authenticated
  USING (
    current_member_type() = 'super_admin'
    OR (current_member_type() = 'committee' AND created_by = auth.uid())
  );

-- EVENT GALLERY
CREATE POLICY "gallery_read"
  ON public.event_gallery FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "gallery_write_committee"
  ON public.event_gallery FOR ALL TO authenticated
  USING (is_committee_or_above());

-- EVENT ORGANIZERS
CREATE POLICY "organizers_read"
  ON public.event_organizers FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "organizers_write_committee"
  ON public.event_organizers FOR ALL TO authenticated
  USING (is_committee_or_above());

-- RSVPS
CREATE POLICY "rsvps_read"
  ON public.event_rsvps FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "rsvps_insert_own"
  ON public.event_rsvps FOR INSERT TO authenticated
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "rsvps_update_own"
  ON public.event_rsvps FOR UPDATE TO authenticated
  USING (profile_id = auth.uid());

CREATE POLICY "rsvps_delete_own"
  ON public.event_rsvps FOR DELETE TO authenticated
  USING (profile_id = auth.uid());

-- MOUS
CREATE POLICY "mous_read"
  ON public.mous FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "mous_write_admin"
  ON public.mous FOR ALL TO authenticated
  USING (current_member_type() = 'super_admin')
  WITH CHECK (current_member_type() = 'super_admin');

-- PARTNERS
CREATE POLICY "partners_read"
  ON public.partners FOR SELECT TO authenticated
  USING (is_active = TRUE OR current_member_type() = 'super_admin');

CREATE POLICY "partners_write_admin"
  ON public.partners FOR ALL TO authenticated
  USING (current_member_type() = 'super_admin');

-- OFFERS
CREATE POLICY "offers_read"
  ON public.offers FOR SELECT TO authenticated
  USING (is_active = TRUE OR current_member_type() = 'super_admin');

CREATE POLICY "offers_write_admin"
  ON public.offers FOR ALL TO authenticated
  USING (current_member_type() = 'super_admin');

-- CHAT EMBEDDINGS (service role only for writes)
CREATE POLICY "embeddings_read_authenticated"
  ON public.chat_embeddings FOR SELECT TO authenticated USING (TRUE);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_profiles_member_type   ON public.profiles(member_type);
CREATE INDEX idx_profiles_yi_vertical   ON public.profiles(yi_vertical);
CREATE INDEX idx_profiles_approved      ON public.profiles(approved);
CREATE INDEX idx_profiles_name_trgm     ON public.profiles USING gin(
  (first_name || ' ' || last_name) gin_trgm_ops
);
CREATE INDEX idx_profiles_dob_month     ON public.profiles(EXTRACT(MONTH FROM dob));

CREATE INDEX idx_events_starts_at       ON public.events(starts_at DESC);
CREATE INDEX idx_events_vertical        ON public.events(vertical_id);
CREATE INDEX idx_events_published       ON public.events(is_published) WHERE is_published = TRUE;

CREATE INDEX idx_rsvps_event_id         ON public.event_rsvps(event_id);
CREATE INDEX idx_rsvps_profile_id       ON public.event_rsvps(profile_id);

CREATE INDEX idx_gallery_event_id       ON public.event_gallery(event_id, sort_order);
CREATE INDEX idx_offers_partner_id      ON public.offers(partner_id);
CREATE INDEX idx_offers_active          ON public.offers(is_active) WHERE is_active = TRUE;

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
-- Run these in Supabase Dashboard > Storage or via API:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('event-media', 'event-media', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('mou-pdfs', 'mou-pdfs', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('partner-logos', 'partner-logos', true);
