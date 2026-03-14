-- ============================================================
-- YI Kanpur – Cumulative Migrations
-- Safe to run on an existing DB (all use IF NOT EXISTS / DO guards)
-- Run top-to-bottom in Supabase SQL Editor
-- ============================================================


-- ============================================================
-- MIGRATION 1: profiles – relationship & spouse fields
-- ============================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS relationship_status TEXT,          -- 'married' | 'single'
  ADD COLUMN IF NOT EXISTS spouse_name         TEXT,          -- only when married
  ADD COLUMN IF NOT EXISTS is_spouse_yi_member BOOLEAN,       -- only when married
  ADD COLUMN IF NOT EXISTS anniversary_date    DATE;          -- only when married


-- ============================================================
-- MIGRATION 2: profiles – yi_member_since  DATE → INT (year)
-- Only runs if the column is still of type DATE
-- ============================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'profiles'
      AND column_name  = 'yi_member_since'
      AND data_type    = 'date'
  ) THEN
    ALTER TABLE public.profiles
      ALTER COLUMN yi_member_since TYPE INT
      USING DATE_PART('year', yi_member_since)::INT;
  END IF;
END
$$;


-- ============================================================
-- MIGRATION 3: offers – online vs offline offer support
-- ============================================================
ALTER TABLE public.offers
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS address   TEXT;


-- ============================================================
-- MIGRATION 5: profiles – secondary phone country code
-- ============================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS secondary_phone_country_code TEXT;


-- ============================================================
-- MIGRATION 4: get_birthdays_by_month – include job_title & company_name
-- (DROP + recreate because Postgres can't change return type of existing function)
-- ============================================================
DROP FUNCTION IF EXISTS public.get_birthdays_by_month(INT);

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
