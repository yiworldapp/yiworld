/**
 * fix-member-columns.js
 *
 * Fixes column mismatch from original CSV import using pattern-based extraction:
 *  - Social URLs → domain-name regex (linkedin.com, instagram.com, etc.)
 *  - Blood group  → blood-type regex (/^[ABO][+-]$|^AB[+-]$/)
 *  - Yi vertical  → scans each field for known vertical names
 *  - Yi position  → scans for known position names
 *  - Member type  → scans for "Yess"/"Yes"
 *  - Personal bio → extracted via blood-group anchor
 *
 * Run (dry-run):  node fix-member-columns.js
 * Apply for real: node fix-member-columns.js --apply
 */

const { createClient } = require('@supabase/supabase-js');
const fs   = require('fs');
const path = require('path');

const SUPABASE_URL     = 'https://wluqvfoenfyawnmynpuw.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndsdXF2Zm9lbmZ5YXdubXlucHV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzMwNDQ0MCwiZXhwIjoyMDg4ODgwNDQwfQ.lI_85XteMos-ox5GrFv0t_HaZV2wMltM_KMtEviz3Rc';

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const APPLY = process.argv.includes('--apply');

// ── Helpers ────────────────────────────────────────────────────────────────────

function normalisePhone(raw) {
  if (!raw || raw.trim() === '-') return null;
  return raw.replace(/\s+/g, '');
}

function mapVertical(raw) {
  if (!raw) return 'none';
  const v = raw.trim().toLowerCase();
  const m = {
    'innovation': 'innovation', 'climate': 'climate_change',
    'climate change': 'climate_change', 'yuva': 'yuva',
    'thalir': 'thalir', 'thailr': 'thalir', 'masoom': 'masoom',
    'branding': 'branding', 'learning': 'learning',
    'road safety': 'road_safety', 'accessibility': 'accessibility',
    'health': 'health', 'active living': 'health',
    'rural initiatives': 'rural_initiatives', 'entrepreneurship': 'entrepreneurship',
  };
  return m[v] || 'none';
}

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

function clean(val) {
  if (!val) return null;
  const v = String(val).trim();
  if (!v || v === '-' || v.toLowerCase() === 'n/a' || v.toLowerCase() === 'na') return null;
  return v;
}

function parseTags(raw) {
  if (!raw || raw.trim() === '-') return [];
  return raw.split(/[,!]+/).map(t => t.trim()).filter(t => t && t.toLowerCase() !== '-' && t.toLowerCase() !== 'n/a').slice(0, 5);
}

// ── CSV row tokeniser ─────────────────────────────────────────────────────────
function parseCsvRow(line) {
  const fields = [];
  let field = '';
  let inQ = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQ && line[i + 1] === '"') { field += '"'; i++; }
      else inQ = !inQ;
    } else if (ch === ',' && !inQ) {
      fields.push(field.trim()); field = '';
    } else {
      field += ch;
    }
  }
  fields.push(field.trim());
  return fields;
}

// ── Pattern-based field extractor ─────────────────────────────────────────────
const BLOOD_RE = /^(A[+-]|B[+-]|AB[+-]|O[+-])$/i;

// Extract URL matching a domain. `which` = 'first' | 'last' (default 'last').
function extractUrl(line, domain, which = 'last') {
  const re = new RegExp(`https?://[^\\s,"]*${domain}[^\\s,"]*`, 'gi');
  const matches = [...line.matchAll(re)].map(m => m[0]);
  if (!matches.length) return null;
  return which === 'first' ? matches[0] : matches[matches.length - 1];
}

function extractRowData(line, vals) {
  // -- Phone: position 5 (always before any problematic columns)
  const phone = normalisePhone(vals[5]);

  // -- Social URLs via domain regex on raw line
  const linkedin_url  = extractUrl(line, 'linkedin\\.com');
  const instagram_url = extractUrl(line, 'instagram\\.com');
  const facebook_url  = extractUrl(line, 'facebook\\.com');
  const twitter_url   = extractUrl(line, '(?:x\\.com|twitter\\.com)');

  // -- Blood group: scan all fields for blood type
  let blood_group = null;
  for (const f of vals) {
    if (BLOOD_RE.test(f.trim())) { blood_group = f.trim().toUpperCase(); break; }
  }

  // -- Yi vertical, position, member_type: scan all fields for known values
  let yi_vertical = 'none', yi_position = 'none', member_type = 'member';
  for (const f of vals) {
    const lower = f.trim().toLowerCase();
    if (mapVertical(lower) !== 'none')     yi_vertical  = mapVertical(lower);
    if (mapPosition(lower) !== 'none')     yi_position  = mapPosition(lower);
    // "Yess" (double-s) is the distinctive EC field answer; "yes" also appears
    // in the "Is spouse Yi member?" column so we must NOT use it for member_type.
    if (lower === 'yess') member_type = 'committee';
  }

  // -- Personal bio: find blood_group in vals array, then work left to find
  //    the 4 social URL slots (even if they're "-"), then take everything
  //    between those URL slots and blood_group as bio+hobbies.
  let personal_bio = null;
  let bloodIdx = vals.findIndex(f => BLOOD_RE.test(f.trim()));
  if (bloodIdx >= 5) {
    // Walk left from bloodIdx skipping the 4 social URL positions.
    // Social URL slots are each 1 field (they don't contain commas), so we
    // skip 4 positions back from bloodIdx: twitter, facebook, instagram, linkedin.
    // Then between linkedin (bloodIdx - 4) and bloodIdx there's bio + hobbies.
    // But first we need to verify the 4 fields look like URL-or-dash:
    const urlOrDash = (s) => !s || s.trim() === '-' || /^https?:\/\//i.test(s.trim());
    // Find the rightmost group of 4 consecutive url-or-dash fields left of bloodIdx
    let twitterIdx = -1;
    for (let i = bloodIdx - 1; i >= Math.max(0, bloodIdx - 12); i--) {
      // Check if [i-3, i-2, i-1, i] are all url-or-dash (or at least 3 of 4)
      const groupIdx = [i-3, i-2, i-1, i];
      const group    = groupIdx.map(j => vals[j]);
      const urlCount = group.filter(v => urlOrDash(v)).length;
      if (urlCount >= 3) {
        // twitterIdx = rightmost URL position within the group (not necessarily i)
        for (let j = groupIdx.length - 1; j >= 0; j--) {
          if (urlOrDash(vals[groupIdx[j]])) {
            twitterIdx = groupIdx[j];
            break;
          }
        }
        break;
      }
    }

    if (twitterIdx >= 0) {
      // Bio and hobbies are between twitterIdx + 1 and bloodIdx - 1
      const bioAndHobbies = vals.slice(twitterIdx + 1, bloodIdx).join(' ');
      personal_bio = clean(bioAndHobbies) || null;
    } else {
      // Fallback: everything 5..8 fields left of bloodIdx
      const slice = vals.slice(Math.max(0, bloodIdx - 8), bloodIdx - 3);
      personal_bio = clean(slice.join(' ')) || null;
    }
  }

  return {
    phone,
    yi_vertical,
    yi_position,
    member_type,
    linkedin_url:  clean(linkedin_url),
    instagram_url: clean(instagram_url),
    facebook_url:  clean(facebook_url),
    twitter_url:   clean(twitter_url),
    personal_bio,
    blood_group:   clean(blood_group),
    hobby_tags:    [],  // can't reliably separate from bio; cleared for now
  };
}

// ── CSV multi-line splitter ───────────────────────────────────────────────────
function splitCsvLines(text) {
  const rawLines = [];
  let cur = '';
  let inQ = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '"') {
      if (inQ && text[i + 1] === '"') { cur += '"'; i++; }
      else inQ = !inQ;
    } else if (ch === '\n' && !inQ) {
      rawLines.push(cur); cur = '';
    } else {
      cur += ch;
    }
  }
  if (cur) rawLines.push(cur);
  return rawLines;
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const csvText = fs.readFileSync(path.join(__dirname, 'members.csv'), 'utf8');
  const rawLines = splitCsvLines(csvText);

  const rows = [];
  for (let i = 1; i < rawLines.length; i++) {
    if (!rawLines[i].trim()) continue;
    const vals = parseCsvRow(rawLines[i]);
    rows.push(extractRowData(rawLines[i], vals));
  }

  console.log(`Parsed ${rows.length} members\n`);
  console.log(APPLY ? '🚀 APPLY MODE — writing to DB\n' : '🔍 DRY-RUN — pass --apply to write\n');

  let fixed = 0, skipped = 0, errors = 0;

  for (const data of rows) {
    if (!data.phone) { skipped++; continue; }

    const { data: profiles, error: lookupErr } = await supabase
      .from('profiles')
      .select('id')
      .eq('phone', data.phone)
      .limit(1);

    if (lookupErr || !profiles?.length) {
      console.warn(`⚠️  ${data.phone} — not found in DB`);
      skipped++; continue;
    }

    const profileId = profiles[0].id;

    const updates = {
      yi_vertical:   data.yi_vertical,
      yi_position:   data.yi_position,
      member_type:   data.member_type,
      linkedin_url:  data.linkedin_url,
      instagram_url: data.instagram_url,
      facebook_url:  data.facebook_url,
      twitter_url:   data.twitter_url,
      personal_bio:  data.personal_bio,
      blood_group:   data.blood_group,
      hobby_tags:    data.hobby_tags,
    };

    const matchLine = rawLines.find(l => l.includes(data.phone.replace('+91', '').replace(/\s/g, '')));
    const name = `${matchLine ? parseCsvRow(matchLine)[1] : '?'} [${data.phone}]`;
    console.log(`\n── ${name}`);
    console.log(`   member_type  : ${updates.member_type}`);
    console.log(`   yi_vertical  : ${updates.yi_vertical}`);
    console.log(`   yi_position  : ${updates.yi_position}`);
    console.log(`   linkedin_url : ${updates.linkedin_url ?? 'null'}`);
    console.log(`   instagram_url: ${updates.instagram_url ?? 'null'}`);
    console.log(`   facebook_url : ${updates.facebook_url ?? 'null'}`);
    console.log(`   twitter_url  : ${updates.twitter_url ?? 'null'}`);
    console.log(`   personal_bio : ${(updates.personal_bio ?? '').slice(0, 70)}`);
    console.log(`   blood_group  : ${updates.blood_group ?? 'null'}`);

    if (APPLY) {
      const { error: updateErr } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', profileId);

      if (updateErr) {
        console.error(`   ✗  ${updateErr.message}`);
        errors++;
      } else {
        console.log(`   ✓  Updated`);
        fixed++;
      }
    } else {
      fixed++;
    }
  }

  console.log(`\n${'─'.repeat(50)}`);
  console.log(`${APPLY ? 'Fixed' : 'Would fix'}: ${fixed}  |  Skipped: ${skipped}  |  Errors: ${errors}`);
  if (!APPLY) console.log('\nRun with --apply to write changes.');
}

main().catch(console.error);
