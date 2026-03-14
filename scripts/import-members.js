/**
 * import-members.js
 *
 * Reads members.csv, for each member:
 *  1. Creates a Supabase auth user (phone-based)
 *  2. Downloads profile photo from deftform → uploads to avatars bucket
 *  3. Inserts a fully-populated profiles row (onboarding_done = true)
 *
 * Run:
 *   cd scripts
 *   node import-members.js
 */

const { createClient } = require('@supabase/supabase-js');
const fs   = require('fs');
const path = require('path');
const https = require('https');
const http  = require('http');

// ── Config ────────────────────────────────────────────────────────────────────
const SUPABASE_URL      = 'https://wluqvfoenfyawnmynpuw.supabase.co';
const SERVICE_ROLE_KEY  = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndsdXF2Zm9lbmZ5YXdubXlucHV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzMwNDQ0MCwiZXhwIjoyMDg4ODgwNDQwfQ.lI_85XteMos-ox5GrFv0t_HaZV2wMltM_KMtEviz3Rc';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Normalise phone to E.164: "+91 73793 57888" → "+917379357888" */
function normalisePhone(raw) {
  if (!raw || raw.trim() === '-') return null;
  return raw.replace(/\s+/g, '');
}

/** Extract first URL from deftform picture field */
function extractPhotoUrl(raw) {
  if (!raw || raw.trim() === '-') return null;
  // Format: "filename.jpg: https://..."  (may have multiple separated by ", ")
  const match = raw.match(/https?:\/\/[^\s,]+/);
  return match ? match[0] : null;
}

/** Map CSV vertical text → yi_vertical_enum */
function mapVertical(raw) {
  if (!raw) return 'none';
  const v = raw.trim().toLowerCase();
  const map = {
    'innovation': 'innovation',
    'climate': 'climate_change',
    'climate change': 'climate_change',
    'yuva': 'yuva',
    'thalir': 'thalir',
    'thailr': 'thalir',
    'masoom': 'masoom',
    'branding': 'branding',
    'learning': 'learning',
    'road safety': 'road_safety',
    'accessibility': 'accessibility',
    'health': 'health',
    'active living': 'health',
    'rural initiatives': 'rural_initiatives',
    'entrepreneurship': 'entrepreneurship',
  };
  return map[v] || 'none';
}

/** Map CSV position text → yi_position_enum */
function mapPosition(raw) {
  if (!raw) return 'none';
  const v = raw.trim().toLowerCase();
  if (v.includes('co-chair') || v.includes('co chair')) return 'co_chair';
  if (v.includes('joint chair') || v.includes('joint-chair')) return 'joint_chair';
  if (v.includes('ec member') || v.includes('ec-member')) return 'ec_member';
  if (v.includes('mentor')) return 'mentor';
  if (v.includes('chair')) return 'chair';
  return 'none';
}

/** Map CSV member type → member_type_enum */
function mapMemberType(isEcRaw) {
  const v = (isEcRaw || '').trim().toLowerCase();
  if (v === 'yess' || v === 'yes') return 'committee';
  return 'member';
}

/** Parse MM/DD/YYYY or similar → "YYYY-MM-DD" or null */
function parseDate(raw) {
  if (!raw || raw.trim() === '-') return null;
  const parts = raw.trim().split('/');
  if (parts.length === 3) {
    const [m, d, y] = parts;
    return `${y.padStart(4,'0')}-${m.padStart(2,'0')}-${d.padStart(2,'0')}`;
  }
  return null;
}

/** Clean "N/A", "-", blank → null */
function clean(val) {
  if (!val) return null;
  const v = val.trim();
  if (v === '' || v === '-' || v.toLowerCase() === 'n/a' || v.toLowerCase() === 'na') return null;
  return v;
}

/** Split comma-separated tags into array, max 4, clean nulls */
function parseTags(raw) {
  if (!raw || raw.trim() === '-') return [];
  return raw.split(/[,!]+/).map(t => t.trim()).filter(t => t && t !== '-').slice(0, 4);
}

/** Download a URL into a Buffer */
function downloadBuffer(url) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    lib.get(url, (res) => {
      if (res.statusCode !== 200) {
        res.resume();
        return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
      }
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    }).on('error', reject);
  });
}

/** Guess mime type from URL */
function mimeFromUrl(url) {
  const ext = url.split('?')[0].split('.').pop().toLowerCase();
  const map = { jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', gif: 'image/gif', webp: 'image/webp' };
  return map[ext] || 'image/jpeg';
}

// ── Simple CSV parser (handles quoted fields with embedded commas/newlines) ──
function parseCSV(text) {
  const rows = [];
  let cur = '';
  let inQuote = false;
  const lines = [];
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '"') {
      if (inQuote && text[i+1] === '"') { cur += '"'; i++; }
      else inQuote = !inQuote;
    } else if (ch === '\n' && !inQuote) {
      lines.push(cur); cur = '';
    } else {
      cur += ch;
    }
  }
  if (cur) lines.push(cur);

  const parseRow = (line) => {
    const fields = [];
    let field = '';
    let inQ = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (inQ && line[i+1] === '"') { field += '"'; i++; }
        else inQ = !inQ;
      } else if (ch === ',' && !inQ) {
        fields.push(field); field = '';
      } else {
        field += ch;
      }
    }
    fields.push(field);
    return fields;
  };

  const headers = parseRow(lines[0]);
  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    const vals = parseRow(lines[i]);
    const obj = {};
    headers.forEach((h, idx) => { obj[h.trim()] = (vals[idx] || '').trim(); });
    rows.push(obj);
  }
  return rows;
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const csvPath = path.join(__dirname, 'members.csv');
  const csvText = fs.readFileSync(csvPath, 'utf8');
  const rows = parseCSV(csvText);
  console.log(`Found ${rows.length} members\n`);

  for (const row of rows) {
    const firstName = clean(row['Your First Name (the one your friends shout)']) || '';
    const lastName  = clean(row['Middle + Last Name']) || '';
    const phone     = normalisePhone(row['Your Always-On (WhatsApp) Phone Number']);

    if (!phone) {
      console.warn(`⚠️  Skipping ${firstName} ${lastName} — no phone`);
      continue;
    }

    console.log(`\n── Processing: ${firstName} ${lastName} (${phone})`);

    // 1. Create auth user
    let userId;
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      phone: phone,
      phone_confirm: true,   // mark phone as verified so OTP works immediately
      user_metadata: { first_name: firstName, last_name: lastName },
    });

    if (authError) {
      if (authError.message?.includes('already been registered') || authError.code === 'phone_exists') {
        // Fetch existing user
        const { data: list } = await supabase.auth.admin.listUsers({ perPage: 1000 });
        const existing = list?.users?.find(u => u.phone === phone);
        if (existing) {
          userId = existing.id;
          console.log(`   ↩  Auth user already exists: ${userId}`);
        } else {
          console.error(`   ✗  Could not create or find user for ${phone}`);
          continue;
        }
      } else {
        console.error(`   ✗  Auth error: ${authError.message}`);
        continue;
      }
    } else {
      userId = authData.user.id;
      console.log(`   ✓  Auth user created: ${userId}`);
    }

    // 2. Download & upload profile photo
    let headshotUrl = null;
    const photoUrl = extractPhotoUrl(row['Profile Picture']);
    if (photoUrl) {
      try {
        console.log(`   ↓  Downloading photo...`);
        const buf  = await downloadBuffer(photoUrl);
        const ext  = photoUrl.split('?')[0].split('.').pop().toLowerCase() || 'jpg';
        const mime = mimeFromUrl(photoUrl);
        const storagePath = `${userId}/avatar.${ext}`;

        const { error: uploadError } = await supabase.storage
          .from('avatars')
          .upload(storagePath, buf, { contentType: mime, upsert: true });

        if (uploadError) {
          console.warn(`   ⚠️  Upload failed: ${uploadError.message}`);
        } else {
          const { data: urlData } = supabase.storage.from('avatars').getPublicUrl(storagePath);
          headshotUrl = urlData.publicUrl;
          console.log(`   ✓  Photo uploaded`);
        }
      } catch (e) {
        console.warn(`   ⚠️  Photo download failed: ${e.message}`);
      }
    }

    // 3. Build profile row
    const isMarried = (row['Relationship Status'] || '').toLowerCase().includes('married');
    const profile = {
      id:                 userId,
      phone:              phone,
      phone_country_code: '+91',
      first_name:         firstName,
      last_name:          lastName,
      primary_email:      clean(row['Primary Email']),
      secondary_email:    clean(row['Secondary Email (your "that" email)']),
      secondary_phone:    normalisePhone(row['Emergency âTry This Oneâ Number (Secondary Phone)']),
      dob:                parseDate(row['The Day You Entered the World']),
      headshot_url:       headshotUrl,
      address_line1:      clean(row['Where Should We Find You? (Line 1)']),
      address_line2:      clean(row['Apartment / Landmark / Secret Hideout (Line 2)']),
      city:               clean(row['Your City']),
      state:              clean(row['State']),
      country:            'India',
      company_name:       clean(row['Business Name']),
      job_title:          clean(row['What Hat Do You Wear in your business?']),
      industry:           clean(row['Your Industry']),
      business_bio:       clean(row['Business Bio']),
      business_website:   clean(row['Business Website']),
      business_tags:      parseTags(row['3â4 Keywords That Describe Your Work']),
      yi_vertical:        mapVertical(row['Which Yi Vertical you belong to?']),
      yi_position:        mapPosition(row['What is your role/position in your vertical?']),
      yi_member_since:    parseInt(row['Yi Kanpur joining year']) || null,
      member_type:        mapMemberType(row['Are you Part of the Core Crew (EC?)']),
      approved:           true,
      linkedin_url:       clean(row['LinkedIn Profile Link']),
      instagram_url:      clean(row['Instagram Profile Link (full)']),
      facebook_url:       clean(row['Facebook Profile Link']),
      twitter_url:        clean(row['X (Twitter) Profile Link']),
      personal_bio:       clean(row['Who Are You Beyond Work?']),
      blood_group:        clean(row['Blood Group']),
      relationship_status: isMarried ? 'married' : 'single',
      spouse_name:        isMarried ? clean(row['Spouse Name']) : null,
      is_spouse_yi_member: isMarried
        ? (row['Is spouse Yi member?'] || '').toLowerCase().startsWith('yes')
        : null,
      anniversary_date:   isMarried ? parseDate(row['Anniversary Date']) : null,
      hobby_tags:         parseTags(row['What Do You Do For Fun?']),
      onboarding_done:    true,
    };

    // 4. Upsert profile
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert(profile, { onConflict: 'id' });

    if (profileError) {
      console.error(`   ✗  Profile upsert failed: ${profileError.message}`);
    } else {
      console.log(`   ✓  Profile saved`);
    }
  }

  console.log('\n\nDone!');
}

main().catch(console.error);
