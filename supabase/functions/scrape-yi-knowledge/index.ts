import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-scrape-secret',
}

const PAGES = ['/', '/about-yi/', '/yi-initiatives/', '/membership/']
const BASE_URL = 'https://youngindians.net'

async function fetchPageText(url: string): Promise<string> {
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; YI-Bot/1.0)' },
      signal: AbortSignal.timeout(8000),
    })
    if (!res.ok) return ''
    const html = await res.text()
    // Remove scripts, styles, nav, footer, header tags entirely
    let text = html
      .replace(/<script[\s\S]*?<\/script>/gi, '')
      .replace(/<style[\s\S]*?<\/style>/gi, '')
      .replace(/<nav[\s\S]*?<\/nav>/gi, '')
      .replace(/<footer[\s\S]*?<\/footer>/gi, '')
      .replace(/<header[\s\S]*?<\/header>/gi, '')
      // Remove remaining HTML tags
      .replace(/<[^>]+>/g, ' ')
      // Decode common HTML entities
      .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
      .replace(/&nbsp;/g, ' ').replace(/&#39;/g, "'").replace(/&quot;/g, '"')
      // Collapse whitespace
      .replace(/[ \t]+/g, ' ')
      .replace(/\n\s*\n\s*\n+/g, '\n\n')
      .trim()
    return text.slice(0, 2000) // max 2000 chars per page
  } catch {
    return ''
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // ── Auth check ────────────────────────────────────────────────────────────
  const scrapeSecret = Deno.env.get('SCRAPE_SECRET')
  const requestSecret = req.headers.get('x-scrape-secret')
  const authHeader = req.headers.get('authorization') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  // Allow if:
  // 1. No SCRAPE_SECRET configured (easy first-run)
  // 2. x-scrape-secret header matches configured secret
  // 3. Request uses service role key as Bearer token
  const isAuthorised =
    !scrapeSecret ||
    (scrapeSecret && requestSecret === scrapeSecret) ||
    authHeader === `Bearer ${serviceRoleKey}`

  if (!isAuthorised) {
    return new Response(JSON.stringify({ error: 'Unauthorised' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    // ── Scrape pages ─────────────────────────────────────────────────────────
    const pageTexts = await Promise.all(
      PAGES.map((path) => fetchPageText(`${BASE_URL}${path}`))
    )

    const combined = pageTexts
      .filter((t) => t.length > 0)
      .join('\n\n---\n\n')

    // Trim to max ~6000 chars total
    const scrapedText = combined.slice(0, 6000)

    const scraped_at = new Date().toISOString()

    // ── Upsert into yi_knowledge ──────────────────────────────────────────────
    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      serviceRoleKey
    )

    const { error: upsertError } = await serviceClient
      .from('yi_knowledge')
      .upsert({ id: 'main', content: scrapedText, scraped_at })

    if (upsertError) {
      console.error('Upsert error:', upsertError)
      return new Response(
        JSON.stringify({ success: false, error: upsertError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ success: true, length: scrapedText.length, scraped_at }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error('Scraper error:', err)
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
