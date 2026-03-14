-- ============================================================
-- Young Indians (YI) - Seed Data for Testing
-- Run in Supabase SQL Editor AFTER schema.sql
-- Test password for all accounts: YItest@2024
-- ============================================================

-- ============================================================
-- STEP 1: AUTH USERS
-- Dashboard users (email login) + Mobile users (phone OTP)
-- ============================================================

INSERT INTO auth.users (
  id, instance_id, aud, role,
  email, phone,
  encrypted_password,
  email_confirmed_at, phone_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token
) VALUES

-- ── Dashboard users (email login) ──────────────────────────
(
  'a0000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'superadmin@youngindians.com', NULL,
  crypt('YItest@2024', gen_salt('bf')),
  NOW(), NULL,
  '{"provider":"email","providers":["email"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'a0000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'health.committee@youngindians.com', NULL,
  crypt('YItest@2024', gen_salt('bf')),
  NOW(), NULL,
  '{"provider":"email","providers":["email"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'a0000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  'startup.committee@youngindians.com', NULL,
  crypt('YItest@2024', gen_salt('bf')),
  NOW(), NULL,
  '{"provider":"email","providers":["email"]}', '{}',
  NOW(), NOW(), '', ''
),

-- ── Mobile app users (phone OTP) ───────────────────────────
(
  'b0000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543201',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543202',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543203',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543204',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000005',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543205',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000006',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543206',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000007',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543207',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000008',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543208',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000009',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543209',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000010',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543210',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000011',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543211',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
),
(
  'b0000000-0000-0000-0000-000000000012',
  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
  NULL, '+919876543212',
  crypt('YItest@2024', gen_salt('bf')),
  NULL, NOW(),
  '{"provider":"phone","providers":["phone"]}', '{}',
  NOW(), NOW(), '', ''
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 2: UPDATE PROFILES
-- Trigger already created rows — now fill in all details
-- ============================================================

-- ── Super Admin ─────────────────────────────────────────────
UPDATE public.profiles SET
  first_name       = 'Arjun',
  last_name        = 'Mehta',
  primary_email    = 'superadmin@youngindians.com',
  dob              = '1985-06-15',
  yi_vertical      = 'none',  -- trigger sets member/approved
  yi_position      = 'none',
  company_name     = 'Young Indians',
  job_title        = 'National Coordinator',
  industry         = 'Non-Profit',
  city             = 'Mumbai',
  state            = 'Maharashtra',
  country          = 'India',
  blood_group      = 'O+',
  business_tags    = ARRAY['Leadership', 'Strategy', 'Growth'],
  hobby_tags       = ARRAY['Cricket', 'Reading'],
  onboarding_done  = TRUE
WHERE id = 'a0000000-0000-0000-0000-000000000001';

-- Now promote to super_admin (doesn't touch yi_vertical so trigger won't fire)
UPDATE public.profiles SET
  member_type = 'super_admin',
  approved    = TRUE
WHERE id = 'a0000000-0000-0000-0000-000000000001';

-- ── Health Committee (dashboard) ────────────────────────────
UPDATE public.profiles SET
  first_name       = 'Priya',
  last_name        = 'Sharma',
  primary_email    = 'health.committee@youngindians.com',
  dob              = '1992-03-22',
  yi_vertical      = 'health',   -- trigger sets committee, unapproved
  yi_position      = 'chair',
  company_name     = 'Apollo Hospitals',
  job_title        = 'Senior Consultant',
  industry         = 'Healthcare',
  city             = 'Chennai',
  state            = 'Tamil Nadu',
  country          = 'India',
  blood_group      = 'A+',
  business_tags    = ARRAY['Healthcare', 'Wellness', 'Public Health'],
  hobby_tags       = ARRAY['Yoga', 'Cooking'],
  onboarding_done  = TRUE
WHERE id = 'a0000000-0000-0000-0000-000000000002';

UPDATE public.profiles SET approved = TRUE
WHERE id = 'a0000000-0000-0000-0000-000000000002';

-- ── Entrepreneurship Committee (dashboard) ──────────────────
UPDATE public.profiles SET
  first_name       = 'Rahul',
  last_name        = 'Verma',
  primary_email    = 'startup.committee@youngindians.com',
  dob              = '1990-11-08',
  yi_vertical      = 'entrepreneurship',
  yi_position      = 'co_chair',
  company_name     = 'StartupHub India',
  job_title        = 'Founder & CEO',
  industry         = 'Technology',
  city             = 'Bengaluru',
  state            = 'Karnataka',
  country          = 'India',
  blood_group      = 'B+',
  business_tags    = ARRAY['Startups', 'Tech', 'Funding'],
  hobby_tags       = ARRAY['Hiking', 'Chess'],
  onboarding_done  = TRUE
WHERE id = 'a0000000-0000-0000-0000-000000000003';

UPDATE public.profiles SET approved = TRUE
WHERE id = 'a0000000-0000-0000-0000-000000000003';

-- ── Mobile App Members ──────────────────────────────────────
UPDATE public.profiles SET
  first_name = 'Aisha', last_name = 'Khan',
  primary_email = 'aisha.khan@example.com',
  dob = '1995-07-14', yi_vertical = 'health', yi_position = 'ec_member',
  company_name = 'Max Healthcare', job_title = 'Physiotherapist', industry = 'Healthcare',
  city = 'Delhi', state = 'Delhi', country = 'India', blood_group = 'AB+',
  business_tags = ARRAY['Rehabilitation', 'Wellness'],
  hobby_tags = ARRAY['Dance', 'Travel'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000001';
UPDATE public.profiles SET approved = TRUE WHERE id = 'b0000000-0000-0000-0000-000000000001';

UPDATE public.profiles SET
  first_name = 'Vikram', last_name = 'Nair',
  primary_email = 'vikram.nair@example.com',
  dob = '1988-01-30', yi_vertical = 'entrepreneurship', yi_position = 'mentor',
  company_name = 'Nair Ventures', job_title = 'Angel Investor', industry = 'Finance',
  city = 'Kochi', state = 'Kerala', country = 'India', blood_group = 'O-',
  business_tags = ARRAY['Investment', 'Mentorship', 'Finance'],
  hobby_tags = ARRAY['Golf', 'Photography'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000002';
UPDATE public.profiles SET approved = TRUE WHERE id = 'b0000000-0000-0000-0000-000000000002';

UPDATE public.profiles SET
  first_name = 'Sneha', last_name = 'Patel',
  primary_email = 'sneha.patel@example.com',
  dob = '1997-04-05', yi_vertical = 'climate_change', yi_position = 'joint_chair',
  company_name = 'GreenEarth NGO', job_title = 'Program Manager', industry = 'NGO',
  city = 'Ahmedabad', state = 'Gujarat', country = 'India', blood_group = 'A-',
  business_tags = ARRAY['Sustainability', 'Environment', 'Policy'],
  hobby_tags = ARRAY['Gardening', 'Cycling'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000003';
UPDATE public.profiles SET approved = TRUE WHERE id = 'b0000000-0000-0000-0000-000000000003';

UPDATE public.profiles SET
  first_name = 'Rohan', last_name = 'Singh',
  primary_email = 'rohan.singh@example.com',
  dob = '1993-09-18', yi_vertical = 'yuva', yi_position = 'chair',
  company_name = 'Singh & Associates', job_title = 'Advocate', industry = 'Legal',
  city = 'Chandigarh', state = 'Punjab', country = 'India', blood_group = 'B-',
  business_tags = ARRAY['Law', 'Youth Rights', 'Policy'],
  hobby_tags = ARRAY['Football', 'Music'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000004';
UPDATE public.profiles SET approved = TRUE WHERE id = 'b0000000-0000-0000-0000-000000000004';

UPDATE public.profiles SET
  first_name = 'Meera', last_name = 'Iyer',
  primary_email = 'meera.iyer@example.com',
  dob = '1991-12-25', yi_vertical = 'learning', yi_position = 'co_chair',
  company_name = 'EduTech Solutions', job_title = 'EdTech Entrepreneur', industry = 'Education',
  city = 'Hyderabad', state = 'Telangana', country = 'India', blood_group = 'O+',
  business_tags = ARRAY['Education', 'Technology', 'Innovation'],
  hobby_tags = ARRAY['Reading', 'Painting'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000005';
UPDATE public.profiles SET approved = TRUE WHERE id = 'b0000000-0000-0000-0000-000000000005';

UPDATE public.profiles SET
  first_name = 'Karan', last_name = 'Malhotra',
  primary_email = 'karan.malhotra@example.com',
  dob = '1996-08-11', yi_vertical = 'innovation', yi_position = 'ec_member',
  company_name = 'TechVenture Labs', job_title = 'Product Manager', industry = 'Technology',
  city = 'Pune', state = 'Maharashtra', country = 'India', blood_group = 'AB-',
  business_tags = ARRAY['Product', 'AI/ML', 'Startups'],
  hobby_tags = ARRAY['Gaming', 'Trekking'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000006';
UPDATE public.profiles SET approved = TRUE WHERE id = 'b0000000-0000-0000-0000-000000000006';

UPDATE public.profiles SET
  first_name = 'Divya', last_name = 'Reddy',
  primary_email = 'divya.reddy@example.com',
  dob = '1994-02-14', yi_vertical = 'masoom', yi_position = 'mentor',
  company_name = 'CRY India', job_title = 'Child Rights Advocate', industry = 'NGO',
  city = 'Hyderabad', state = 'Telangana', country = 'India', blood_group = 'A+',
  business_tags = ARRAY['Child Welfare', 'Education', 'Rights'],
  hobby_tags = ARRAY['Art', 'Volunteering'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000007';
UPDATE public.profiles SET approved = TRUE WHERE id = 'b0000000-0000-0000-0000-000000000007';

-- Regular members (yi_vertical = none → trigger sets member + approved)
UPDATE public.profiles SET
  first_name = 'Amit', last_name = 'Joshi',
  primary_email = 'amit.joshi@example.com',
  dob = '1990-05-20', yi_vertical = 'none',
  company_name = 'Joshi Textiles', job_title = 'Business Owner', industry = 'Textile',
  city = 'Surat', state = 'Gujarat', country = 'India', blood_group = 'B+',
  business_tags = ARRAY['Textile', 'Export'],
  hobby_tags = ARRAY['Swimming', 'Cooking'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000008';

UPDATE public.profiles SET
  first_name = 'Pooja', last_name = 'Chauhan',
  primary_email = 'pooja.chauhan@example.com',
  dob = '1998-10-03', yi_vertical = 'none',
  company_name = 'Chauhan Real Estate', job_title = 'Property Consultant', industry = 'Real Estate',
  city = 'Jaipur', state = 'Rajasthan', country = 'India', blood_group = 'O+',
  business_tags = ARRAY['Real Estate', 'Investment'],
  hobby_tags = ARRAY['Dancing', 'Photography'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000009';

UPDATE public.profiles SET
  first_name = 'Nikhil', last_name = 'Desai',
  primary_email = 'nikhil.desai@example.com',
  dob = '1987-07-07', yi_vertical = 'none',
  company_name = 'Desai Pharma', job_title = 'MD & Director', industry = 'Pharmaceutical',
  city = 'Mumbai', state = 'Maharashtra', country = 'India', blood_group = 'A-',
  business_tags = ARRAY['Pharma', 'Healthcare', 'R&D'],
  hobby_tags = ARRAY['Tennis', 'Travel'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000010';

UPDATE public.profiles SET
  first_name = 'Ananya', last_name = 'Bose',
  primary_email = 'ananya.bose@example.com',
  dob = '1999-01-21', yi_vertical = 'none',
  company_name = NULL, job_title = 'CA Student', industry = 'Finance',
  city = 'Kolkata', state = 'West Bengal', country = 'India', blood_group = 'B+',
  business_tags = ARRAY['Finance', 'Accounting'],
  hobby_tags = ARRAY['Singing', 'Badminton'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000011';

UPDATE public.profiles SET
  first_name = 'Siddharth', last_name = 'Gupta',
  primary_email = 'sid.gupta@example.com',
  dob = '1993-03-15', yi_vertical = 'none',
  company_name = 'Gupta Logistics', job_title = 'Operations Head', industry = 'Logistics',
  city = 'Nagpur', state = 'Maharashtra', country = 'India', blood_group = 'O-',
  business_tags = ARRAY['Logistics', 'Supply Chain'],
  hobby_tags = ARRAY['Cycling', 'Chess'],
  onboarding_done = TRUE
WHERE id = 'b0000000-0000-0000-0000-000000000012';

-- ============================================================
-- STEP 3: EVENTS
-- ============================================================

INSERT INTO public.events (id, title, description, vertical_id, location_name, location_url,
  is_remote, starts_at, ends_at, is_published, max_attendees, created_by) VALUES

-- Upcoming event (Health)
(
  'c0000000-0000-0000-0000-000000000001',
  'YI Health Summit 2026',
  'Join us for the annual Young Indians Health Summit bringing together healthcare professionals, entrepreneurs, and change-makers. This year''s theme: "Preventive Healthcare for a Healthier Bharat". Featuring panel discussions, hands-on workshops, and networking sessions with leading healthcare experts.',
  (SELECT id FROM public.verticals WHERE slug = 'health'),
  'Taj Coromandel, Chennai',
  'https://maps.google.com/?q=Taj+Coromandel+Chennai',
  FALSE,
  NOW() + INTERVAL '15 days',
  NOW() + INTERVAL '15 days' + INTERVAL '8 hours',
  TRUE,
  200,
  'a0000000-0000-0000-0000-000000000001'
),

-- Remote event (Entrepreneurship) — coming soon
(
  'c0000000-0000-0000-0000-000000000002',
  'Startup Pitch Night — YI Entrepreneurship Vertical',
  'Got a startup idea? Pitch it to a panel of seasoned investors and YI mentors. Open to all YI members with a business concept at any stage — idea, MVP, or growth. Top 3 pitches win mentorship sessions with top angel investors.',
  (SELECT id FROM public.verticals WHERE slug = 'entrepreneurship'),
  NULL,
  'https://zoom.us/j/912345678',
  TRUE,
  NOW() + INTERVAL '5 days',
  NOW() + INTERVAL '5 days' + INTERVAL '3 hours',
  TRUE,
  100,
  'a0000000-0000-0000-0000-000000000003'
),

-- Past event (YUVA Leadership)
(
  'c0000000-0000-0000-0000-000000000003',
  'YUVA Leadership Camp 2025',
  'A 2-day residential camp for young leaders aged 18–35. Activities included team challenges, leadership workshops, a guided trek, and a campfire session with YI chapter leaders from across India.',
  (SELECT id FROM public.verticals WHERE slug = 'yuva'),
  'Coorg Mountain Retreat, Karnataka',
  'https://maps.google.com/?q=Coorg+Karnataka',
  FALSE,
  NOW() - INTERVAL '30 days',
  NOW() - INTERVAL '28 days',
  TRUE,
  60,
  'a0000000-0000-0000-0000-000000000001'
),

-- Climate event (upcoming)
(
  'c0000000-0000-0000-0000-000000000004',
  'Green Hackathon: Climate Action 2026',
  'A 48-hour hackathon challenging teams to build innovative solutions for climate change. Participants will work on real problems provided by partner NGOs. Winners get seed funding, mentorship, and a chance to present at the YI National Conference.',
  (SELECT id FROM public.verticals WHERE slug = 'climate_change'),
  'IIT Bombay, Mumbai',
  'https://maps.google.com/?q=IIT+Bombay+Mumbai',
  FALSE,
  NOW() + INTERVAL '45 days',
  NOW() + INTERVAL '47 days',
  TRUE,
  150,
  'a0000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 4: EVENT ORGANIZERS
-- ============================================================

INSERT INTO public.event_organizers (event_id, profile_id, role) VALUES
-- Health Summit organizers
('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Chair'),
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'Co-Organizer'),
-- Startup Pitch Night organizers
('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'Host'),
('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'Co-Host'),
-- YUVA Camp organizers
('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000004', 'Camp Lead'),
-- Climate Hackathon organizers
('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000003', 'Chair'),
('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000006', 'Tech Lead')
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 5: EVENT RSVPs
-- ============================================================

INSERT INTO public.event_rsvps (event_id, profile_id, status) VALUES
-- Health Summit RSVPs
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'going'),
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'going'),
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000005', 'maybe'),
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000008', 'going'),
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000009', 'going'),
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000010', 'not_going'),
-- Startup Pitch RSVPs
('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'going'),
('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000006', 'going'),
('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000011', 'maybe'),
('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000012', 'going'),
-- YUVA Camp RSVPs (past event)
('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000004', 'going'),
('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000008', 'going'),
('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000009', 'going'),
('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000010', 'going'),
('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000011', 'not_going'),
-- Climate Hackathon RSVPs
('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000003', 'going'),
('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000006', 'going'),
('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000007', 'going'),
('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000012', 'maybe')
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 6: PARTNERS
-- ============================================================

INSERT INTO public.partners (id, name, description, website_url, category, is_active) VALUES
(
  'd0000000-0000-0000-0000-000000000001',
  'Apollo Hospitals',
  'India''s leading healthcare provider, offering exclusive health packages and free screenings for all YI members.',
  'https://apollohospitals.com',
  'Healthcare',
  TRUE
),
(
  'd0000000-0000-0000-0000-000000000002',
  'HDFC Bank',
  'YI''s banking partner providing zero-fee current accounts, priority banking, and special loan rates for member businesses.',
  'https://hdfcbank.com',
  'Banking & Finance',
  TRUE
),
(
  'd0000000-0000-0000-0000-000000000003',
  'Coursera for Business',
  'Leading online learning platform offering YI members access to 10,000+ courses from top universities worldwide.',
  'https://coursera.org',
  'Education',
  TRUE
),
(
  'd0000000-0000-0000-0000-000000000004',
  'MakeMyTrip',
  'India''s top travel platform with exclusive member discounts on flights, hotels, and holiday packages.',
  'https://makemytrip.com',
  'Travel',
  TRUE
),
(
  'd0000000-0000-0000-0000-000000000005',
  'WeWork India',
  'Premium coworking spaces across India with exclusive monthly membership rates for YI members.',
  'https://wework.com/in',
  'Coworking',
  TRUE
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 7: OFFERS
-- ============================================================

INSERT INTO public.offers (
  partner_id, title, description, offer_type, discount_value,
  coupon_code, how_to_claim, terms, valid_from, valid_until, is_active
) VALUES

-- Apollo Hospitals offers
(
  'd0000000-0000-0000-0000-000000000001',
  'Free Annual Health Check-up',
  'Comprehensive annual health check-up package worth ₹5,000 — completely free for YI members. Includes 40+ blood tests, ECG, X-Ray, and doctor consultation.',
  'freebie',
  '₹5,000 value',
  'YIHEALTH2026',
  'Show your YI membership card at Apollo reception and quote code YIHEALTH2026. Book via the YI app or call 1860-500-1066.',
  'Valid at all Apollo Hospitals across India. One check-up per member per year. Advance booking required.',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '1 year',
  TRUE
),
(
  'd0000000-0000-0000-0000-000000000001',
  '25% Off All OPD Consultations',
  'Get 25% off on all outpatient department consultations at any Apollo Hospital for yourself and immediate family members.',
  'discount',
  '25%',
  'YIAPOLLO25',
  'Book appointment via Apollo app, select "YI Member Discount", and enter code at checkout.',
  'Valid for member + spouse + children only. Not valid on super-speciality consultations.',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '1 year',
  TRUE
),

-- HDFC Bank offers
(
  'd0000000-0000-0000-0000-000000000002',
  'Zero-Balance Business Current Account',
  'Open an HDFC Business Current Account with zero minimum balance requirement, free NEFT/RTGS, and a dedicated relationship manager.',
  'exclusive',
  NULL,
  NULL,
  'Visit your nearest HDFC branch with your YI membership certificate and ID proof. Mention "YI Partnership" to the branch manager.',
  'Offer for new account openings only. Subject to KYC and standard HDFC eligibility criteria.',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '6 months',
  TRUE
),
(
  'd0000000-0000-0000-0000-000000000002',
  '1% Lower Interest Rate on Business Loans',
  'YI members get business loans at 1% below the standard rate. Applicable on loans from ₹10L to ₹5Cr.',
  'discount',
  '1% p.a. off',
  'YILOAN2026',
  'Apply online at hdfc.com/business-loan and enter promo code, or walk into any branch with your YI ID.',
  'Subject to credit appraisal and HDFC''s standard lending norms. Valid for business loans only.',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '1 year',
  TRUE
),

-- Coursera offers
(
  'd0000000-0000-0000-0000-000000000003',
  '50% Off Coursera Plus Annual Plan',
  'Get unlimited access to 10,000+ courses, Specializations, and Professional Certificates at 50% off the annual plan price.',
  'discount',
  '50%',
  'YILEARN50',
  'Go to coursera.org/yi-members and register with your primary YI email. Apply code YILEARN50 at checkout.',
  'Offer valid for new Coursera Plus subscribers only. 12-month plan required. Auto-renews at standard rate.',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '3 months',
  TRUE
),

-- MakeMyTrip offers
(
  'd0000000-0000-0000-0000-000000000004',
  '15% Off Hotels — Up to ₹3,000 Off',
  'Book any hotel through MakeMyTrip and get 15% off, capped at ₹3,000 per booking. Valid on 5,000+ properties across India.',
  'discount',
  '15% (up to ₹3,000)',
  'YIMMT2026',
  'Book on makemytrip.com or app. Enter code YIMMT2026 in the "Apply Coupon" field before payment.',
  'Valid on bookings of 2+ nights. Not combinable with other offers. Minimum booking ₹5,000.',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '1 year',
  TRUE
),

-- WeWork offers
(
  'd0000000-0000-0000-0000-000000000005',
  '20% Off All WeWork Memberships',
  'Hot desks, dedicated desks, or private offices — YI members get 20% off all WeWork India membership plans.',
  'discount',
  '20%',
  'YIWEWORK',
  'Email partnerships@wework.co.in with your YI membership proof, or scan the QR at any WeWork reception and quote code YIWEWORK.',
  'Valid at all WeWork India locations. Subject to availability. 3-month minimum commitment.',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '1 year',
  TRUE
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 8: MOUs
-- ============================================================

INSERT INTO public.mous (id, title, description, pdf_url, partner_name, signed_date, expiry_date, created_by) VALUES
(
  'e0000000-0000-0000-0000-000000000001',
  'MOU with Apollo Hospitals — Member Healthcare Program',
  'Formal agreement for the Apollo-YI Healthcare Partnership covering free annual check-ups, OPD discounts, and joint health awareness campaigns.',
  'https://example.com/mou/apollo-yi-2024.pdf',
  'Apollo Hospitals',
  '2024-01-15',
  '2026-01-14',
  'a0000000-0000-0000-0000-000000000001'
),
(
  'e0000000-0000-0000-0000-000000000002',
  'MOU with HDFC Bank — YI Business Banking Initiative',
  'Partnership agreement covering banking benefits for YI member businesses, including preferential lending rates and zero-balance accounts.',
  'https://example.com/mou/hdfc-yi-2024.pdf',
  'HDFC Bank',
  '2024-03-20',
  '2026-03-19',
  'a0000000-0000-0000-0000-000000000001'
),
(
  'e0000000-0000-0000-0000-000000000003',
  'MOU with Coursera — YI Learning Partnership',
  'Agreement to provide subsidised access to Coursera''s learning platform for all YI members as part of the Learning Vertical''s upskilling initiative.',
  'https://example.com/mou/coursera-yi-2025.pdf',
  'Coursera Inc.',
  '2025-06-01',
  '2027-05-31',
  'a0000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- DONE ✓
-- ============================================================
-- Test accounts:
--
-- DASHBOARD (admin.youngindians.com):
--   superadmin@youngindians.com   / YItest@2024  → super_admin
--   health.committee@youngindians.com / YItest@2024  → committee (Health)
--   startup.committee@youngindians.com / YItest@2024 → committee (Entrepreneurship)
--
-- MOBILE APP (OTP login):
--   +919876543201 → Aisha Khan (Health committee member)
--   +919876543202 → Vikram Nair (Entrepreneurship committee member)
--   +919876543203 → Sneha Patel (Climate Change committee member)
--   +919876543204 → Rohan Singh (YUVA committee member)
--   +919876543205 → Meera Iyer (Learning committee member)
--   +919876543206 → Karan Malhotra (Innovation committee member)
--   +919876543207 → Divya Reddy (Masoom committee member)
--   +919876543208 → Amit Joshi (regular member)
--   +919876543209 → Pooja Chauhan (regular member)
--   +919876543210 → Nikhil Desai (regular member)
--   +919876543211 → Ananya Bose (regular member)
--   +919876543212 → Siddharth Gupta (regular member)
--
-- NOTE: For OTP login in dev, use Supabase test phone numbers:
--   Go to Supabase Dashboard → Auth → Phone → Test Numbers
--   Add +919876543201 with OTP 123456 (repeat for others or use one test number)
-- ============================================================
