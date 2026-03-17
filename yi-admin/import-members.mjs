#!/usr/bin/env node
/**
 * Member Import Script
 * Usage (from yi-admin folder):
 *   SUPABASE_URL=xxx SUPABASE_SERVICE_KEY=xxx node import-members.mjs ../members.csv
 *
 * Before running:
 *   1. Delete existing phone-based auth users from Supabase dashboard
 *   2. Run SQL: ALTER TYPE yi_vertical_enum ADD VALUE IF NOT EXISTS 'active_living';
 *   3. Run SQL: INSERT INTO public.verticals (slug, label) VALUES ('active_living', 'Active Living') ON CONFLICT (slug) DO NOTHING;
 *   4. Make sure organisation_emails table exists
 */

import { createClient } from '@supabase/supabase-js'
import { readFileSync } from 'fs'

const SUPABASE_URL = process.env.SUPABASE_URL
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY
const CSV_PATH = process.argv[2]

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('❌  Set SUPABASE_URL and SUPABASE_SERVICE_KEY env vars')
  process.exit(1)
}
if (!CSV_PATH) {
  console.error('Usage: node import-members.mjs <path-to-csv>')
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
})

// ── CSV parser (handles quoted fields with embedded newlines) ─────────────────
function parseCSV(text) {
  const rows = []
  let row = [], field = '', inQuotes = false
  text = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
  for (let i = 0; i <= text.length; i++) {
    const ch = text[i]
    if (inQuotes) {
      if (ch === '"' && text[i + 1] === '"') { field += '"'; i++ }
      else if (ch === '"') inQuotes = false
      else if (ch === undefined) { row.push(field); if (row.some(Boolean)) rows.push(row) }
      else field += ch
    } else {
      if (ch === '"') { inQuotes = true }
      else if (ch === ',') { row.push(field.trim()); field = '' }
      else if (ch === '\n' || ch === undefined) {
        row.push(field.trim())
        if (row.some(Boolean)) rows.push(row)
        row = []; field = ''
      } else field += ch
    }
  }
  return rows
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function toTitleCase(str) {
  if (!str || str === '-') return null
  return str.trim().replace(/\b\w+/g, w => {
    if (w.length <= 2 && w === w.toUpperCase() && /[A-Z]/.test(w)) return w
    return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()
  }) || null
}

function parseDate(str) {
  if (!str || str === '-') return null
  const m = str.trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/)
  if (m) return `${m[3]}-${m[1].padStart(2, '0')}-${m[2].padStart(2, '0')}`
  if (/^\d{4}-\d{2}-\d{2}$/.test(str.trim())) return str.trim()
  return null
}

function normalizePhone(str) {
  if (!str || str === '-') return null
  return str.replace(/^\+91\s*/, '').replace(/\s+/g, '').replace(/[^0-9]/g, '') || null
}

const VERTICAL_MAP = {
  'yuva': 'yuva', 'thalir': 'thalir', 'thailr': 'thalir',
  'rural_initiatives': 'rural_initiatives', 'rural initiatives': 'rural_initiatives',
  'masoom': 'masoom', 'road_safety': 'road_safety', 'road safety': 'road_safety',
  'health': 'health', 'accessibility': 'accessibility',
  'climate_change': 'climate_change', 'climate': 'climate_change',
  'entrepreneurship': 'entrepreneurship', 'innovation': 'innovation',
  'learning': 'learning', 'branding': 'branding',
  'membership': 'membership', 'sports': 'sports',
  'pr_advocacy': 'pr_advocacy', 'pr&advocacy': 'pr_advocacy',
  'active_living': 'active_living', 'active living': 'active_living',
  'none': 'none', '': 'none',
}

function normalizeVertical(str) {
  if (!str || str === '-') return 'none'
  const part = str.split(',')[0]          // handle "Yuva, Co-chair" merged fields
  const key = part.trim().toLowerCase()
  const mapped = VERTICAL_MAP[key]
  if (!mapped) console.warn(`    ⚠ Unknown vertical "${str.trim()}" → none`)
  return mapped ?? 'none'
}

const POSITION_MAP = {
  'chair': 'chair',
  'co-chair': 'co_chair', 'co_chair': 'co_chair', 'co chair': 'co_chair',
  'joint_chair': 'joint_chair', 'joint chair': 'joint_chair', 'joint-chair': 'joint_chair',
  'ec_member': 'ec_member', 'ec member': 'ec_member',
  'mentor': 'mentor', 'none': 'none', '': 'none',
}

function normalizePosition(str) {
  if (!str || str === '-') return 'none'
  const key = str.trim().toLowerCase()
  const mapped = POSITION_MAP[key]
  if (!mapped) console.warn(`    ⚠ Unknown position "${str.trim()}" → none`)
  return mapped ?? 'none'
}

function fixEncoding(str) {
  if (!str || str === '-') return null
  return str
    .replace(/â\x80\x99|â€™/g, "'").replace(/â/g, "'")
    .replace(/â\x80\x9c|â€œ/g, '"').replace(/â\x80\x9d|â€/g, '"')
    .replace(/â¦/g, '...').replace(/â¢/g, '•').replace(/ð/g, '')
    .trim() || null
}

function parseTags(str) {
  if (!str || str === '-') return []
  return str.split(/[|,]/).map(t => t.trim()).filter(Boolean).slice(0, 4)
}

function normalizeRelationship(str) {
  if (!str) return null
  const s = str.toLowerCase()
  if (s.includes('married')) return 'married'
  if (s.includes('single')) return 'single'
  return null
}

async function downloadAndUpload(url, userId) {
  if (!url || url === '-') return null
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(20000) })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const buffer = Buffer.from(await res.arrayBuffer())
    const ext = url.split('?')[0].split('.').pop()?.toLowerCase()
    const isPng = ext === 'png'
    const path = `${userId}/avatar.${isPng ? 'png' : 'jpg'}`
    const { error } = await supabase.storage.from('avatars').upload(path, buffer, {
      contentType: isPng ? 'image/png' : 'image/jpeg',
      upsert: true,
    })
    if (error) throw error
    return supabase.storage.from('avatars').getPublicUrl(path).data.publicUrl
  } catch (e) {
    console.warn(`    ⚠ Headshot failed: ${e.message}`)
    return null
  }
}

// ── Survey header → field name mapping ───────────────────────────────────────
// Maps the deftform survey column names to the internal field names used below.
const HEADER_MAP = {
  'Profile Picture':                                         'headshot_url',
  'Your First Name (the one your friends shout)':           'first_name',
  'Middle + Last Name':                                     'last_name',
  'Primary Email':                                          'email',
  'Secondary Email (your "that" email)':                    'secondary_email',
  'Your Always-On (WhatsApp) Phone Number':                 'phone',
  'Emergency \u00e2Try This One\u00e2 Number (Secondary Phone)': 'secondary_phone',
  'The Day You Entered the World':                          'dob',
  'Where Should We Find You? (Line 1)':                     'address_line1',
  'Apartment / Landmark / Secret Hideout (Line 2)':        'address_line2',
  'Your City':                                              'city',
  'State':                                                  'state',
  'Country':                                                'country',
  'Yi Kanpur joining year':                                 'yi_member_since',
  'Business Name':                                          'company_name',
  'Business Website':                                       'business_website',
  'What Hat Do You Wear in your business?':                 'job_title',
  'Your Industry':                                          'industry',
  'Business Bio':                                           'business_bio',
  '3\u00e24 Keywords That Describe Your Work':             'business_tags',
  'Are you Part of the Core Crew (EC)?':                   '_ec_flag',
  'Which Yi Vertical you belong to?':                      'yi_vertical',
  'What is your role/position in your vertical?':          'yi_position',
  'LinkedIn Profile Link':                                  'linkedin_url',
  'Instagram Profile Link (full)':                         'instagram_url',
  'Facebook Profile Link':                                  'facebook_url',
  'X (Twitter) Profile Link':                              'twitter_url',
  'Who Are You Beyond Work?':                              'personal_bio',
  'What Do You Do For Fun?':                               'hobby_tags',
  'Blood Group':                                           'blood_group',
  'Relationship Status':                                   'relationship_status',
  'Is spouse Yi member?':                                  'is_spouse_yi_member',
  'Spouse Name':                                           'spouse_name',
  'Anniversary Date':                                      'anniversary_date',
}

// Extract URL from deftform "filename: https://..." headshot format
function extractHeadshotUrl(str) {
  if (!str || str === '-') return null
  const m = str.match(/https?:\/\/\S+/)
  return m ? m[0] : null
}

// ── Main ──────────────────────────────────────────────────────────────────────
const csv = readFileSync(CSV_PATH, 'utf8')
const rows = parseCSV(csv)
const rawHeaders = rows[0]
// Remap headers: use HEADER_MAP if available, else keep as-is
const headers = rawHeaders.map(h => HEADER_MAP[h] ?? h)
const dataRows = rows.slice(1).filter(r => r.length > 1)

console.log(`\n📋 ${dataRows.length} members to import\n${'─'.repeat(60)}`)

let success = 0, failed = 0

for (const cols of dataRows) {
  const row = Object.fromEntries(headers.map((h, i) => [h, cols[i] ?? '']))

  const email = row.email?.trim().toLowerCase()
  if (!email) { console.warn('⏭  Skipping row — no email'); continue }

  const firstName = toTitleCase(row.first_name) ?? ''
  const lastName  = toTitleCase(row.last_name)  ?? ''
  const phone     = normalizePhone(row.phone)

  console.log(`\n→ ${firstName} ${lastName} <${email}>`)

  // 1. Create auth user (or find existing if already created)
  let userId
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    phone: phone ? `+91${phone}` : undefined,
    email_confirm: true,
    user_metadata: { first_name: firstName, last_name: lastName },
  })

  if (authError) {
    if (authError.message.includes('already') || authError.status === 422) {
      // User already exists — find by email
      const { data: { users } } = await supabase.auth.admin.listUsers({ perPage: 1000 })
      const existing = users?.find(u => u.email === email)
      if (!existing) {
        console.error(`  ✗ Auth: ${authError.message} (and could not find existing)`)
        failed++
        continue
      }
      userId = existing.id
      console.log(`  ↺ Auth user already exists (${userId})`)
    } else {
      console.error(`  ✗ Auth: ${authError.message}`)
      failed++
      continue
    }
  } else {
    userId = authData.user.id
    console.log(`  ✓ Auth user created (${userId})`)
  }

  // 2. Upload headshot
  const headshotUrl = await downloadAndUpload(extractHeadshotUrl(row.headshot_url), userId)
  console.log(headshotUrl ? `  ✓ Headshot uploaded` : `  - No headshot`)

  // 3. Derive vertical / position / member_type
  const vertical   = normalizeVertical(row.yi_vertical)
  const position   = normalizePosition(row.yi_position)
  const memberType = (vertical !== 'none' && position !== 'none') ? 'committee' : 'member'

  // 4. Build and insert profile
  const relStatus = normalizeRelationship(row.relationship_status)
  const isMarried = relStatus === 'married'

  const profile = {
    id: userId,
    first_name:   firstName,
    last_name:    lastName,
    primary_email: email,
    secondary_email: row.secondary_email?.trim() || null,
    phone: phone || null,
    phone_country_code: '+91',
    secondary_phone: normalizePhone(row.secondary_phone) || null,
    secondary_phone_country_code: '+91',
    dob: parseDate(row.dob),
    headshot_url: headshotUrl,
    address_line1: row.address_line1?.trim() || null,
    address_line2: row.address_line2?.trim() || null,
    city:    row.city?.trim() || null,
    state:   row.state?.trim() || null,
    country: row.country?.replace(/\s*\(.*?\)/, '').trim() || 'India',
    company_name:    row.company_name?.trim() || null,
    job_title:       row.job_title?.trim() || null,
    industry:        row.industry?.trim() || null,
    industry_other:  row.industry?.trim() === 'Other' ? (row.industry_other?.trim() || null) : null,
    business_bio:    fixEncoding(row.business_bio),
    business_website: row.business_website?.trim().replace(/^HTTPS:\/\//i, 'https://') || null,
    yi_vertical:   vertical,
    yi_position:   position,
    yi_member_since: parseInt(row.yi_member_since) || null,
    linkedin_url:  row.linkedin_url?.trim() || null,
    instagram_url: row.instagram_url?.trim() || null,
    twitter_url:   row.twitter_url?.trim() || null,
    facebook_url:  row.facebook_url?.trim() || null,
    personal_bio:  fixEncoding(row.personal_bio),
    relationship_status: relStatus,
    spouse_name:         isMarried ? (toTitleCase(row.spouse_name) || null) : null,
    is_spouse_yi_member: isMarried ? row.is_spouse_yi_member?.trim().toLowerCase() === 'yes' : null,
    anniversary_date:    isMarried ? parseDate(row.anniversary_date) : null,
    blood_group:   row.blood_group?.trim() || null,
    business_tags: parseTags(row.business_tags),
    hobby_tags:    parseTags(row.hobby_tags),
    member_type:   memberType,
    onboarding_done: true,
    is_test_user:    false,
  }

  const { error: profileError } = await supabase
    .from('profiles')
    .upsert(profile, { onConflict: 'id' })

  if (profileError) {
    console.error(`  ✗ Profile: ${profileError.message}`)
    failed++
    continue
  }

  // Set approved=true via direct update (bypasses schema cache issue)
  await supabase.from('profiles').update({ approved: true }).eq('id', userId)

  console.log(`  ✓ Profile saved  [${memberType} · ${vertical}]`)

  // 5. Add to organisation_emails whitelist
  const { error: orgError } = await supabase
    .from('organisation_emails')
    .upsert({ email }, { onConflict: 'email', ignoreDuplicates: true })
  if (orgError) console.warn(`  ⚠ Org email: ${orgError.message}`)
  else console.log(`  ✓ Added to organisation_emails`)

  success++
}

console.log(`\n${'─'.repeat(60)}`)
console.log(`✅  Done: ${success} imported, ${failed} failed`)
