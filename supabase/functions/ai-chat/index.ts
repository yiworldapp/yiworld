import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ── YI Organisational Knowledge (static) ────────────────────────────────────
const YI_KNOWLEDGE = `
ABOUT YOUNG INDIANS (YI):
Young Indians (YI) is the youth wing of the Confederation of Indian Industry (CII), India's premier industry body. YI brings together young business leaders, entrepreneurs, and professionals between the ages of 25 and 45 to collaborate, network, and contribute to nation-building.

YI KANPUR CHAPTER:
The Young Indians Kanpur Chapter is one of the active YI chapters in Uttar Pradesh. Members come from diverse industries including manufacturing, retail, healthcare, education, and technology. The chapter organises regular events, knowledge sessions, networking meets, and social impact initiatives.

MEMBERSHIP:
- Open to individuals aged 25–45 years
- Members are typically entrepreneurs, business owners, professionals, or young executives
- Membership is renewed annually
- Benefits include: access to chapter events, national YI events, privileges & discounts from partner brands, and a strong professional network
- To join: reach out to the chapter leadership or apply through the CII/YI portal

YI VERTICALS / INITIATIVES:
YI runs several national verticals that chapters participate in:
- YI-YUVA: Youth empowerment and education initiative
- YI-WISE: Women in Social Endeavour — empowering women entrepreneurs and leaders
- YI-HEAL: Health and wellness initiative
- YI-SUSTAIN: Sustainability and environment initiative
- YI-LEAD: Leadership development programs

CHAPTER ACTIVITIES:
- Monthly chapter meetings
- Annual flagship events (varies by chapter)
- Business networking sessions
- Social impact projects
- National YI conclaves and summits
- Sports and wellness activities for members

APP FEATURES (what this app does):
- Events: View upcoming and past chapter events
- Members: Browse and connect with fellow YI members
- Birthdays: See member birthdays this month
- Privileges: Exclusive discounts and offers from partner brands (online & offline)
- Chat: Ask the YI Assistant anything
`

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { messages } = await req.json()
    if (!messages?.length) {
      return new Response(JSON.stringify({ error: 'No messages provided' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const openaiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiKey) {
      return new Response(JSON.stringify({ reply: 'AI service is not configured. Please contact the administrator.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const userMessages = messages.filter((m: any) => m.role === 'user')
    const lastUserMessage = (userMessages[userMessages.length - 1]?.content || '').toLowerCase()

    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const now = new Date()
    const currentMonth = now.getMonth() + 1

    // Intent detection
    const wantsBirthdays = /birthday|bday|born|cake/i.test(lastUserMessage)
    const wantsMembers   = /member|who is|who are|people|team|committee|position|vertical|chapter|leader|chair/i.test(lastUserMessage)
    const wantsEvents    = /event|meetup|meet|schedule|upcoming|when|past event|previous/i.test(lastUserMessage)
    const wantsOffers    = /offer|discount|deal|privilege|coupon|benefit|cashback|freebie|online offer|offline offer|in.?store/i.test(lastUserMessage)
    const wantsPartners  = /partner|mou|collaboration|tie.?up|sponsor/i.test(lastUserMessage)

    // ── Parallel DB fetches ───────────────────────────────────────────────────
    const fetchList: Promise<any>[] = [
      // 0: upcoming events
      serviceClient.from('events')
        .select('id, title, starts_at, ends_at, location_name, is_remote, description, is_published')
        .eq('is_published', true)
        .gte('starts_at', now.toISOString())
        .order('starts_at')
        .limit(10),

      // 1: member count
      serviceClient.from('profiles')
        .select('*', { count: 'exact', head: true })
        .eq('onboarding_done', true),

      // 2: verticals
      serviceClient.from('verticals')
        .select('slug, label, description'),

      // 3: active partners
      serviceClient.from('partners')
        .select('name, description, category, website_url')
        .eq('is_active', true)
        .limit(30),

      // 4: online offers
      serviceClient.from('online_offers')
        .select('id, brand_name, title, discount_label, coupon_code, how_to_claim, expiry_date, website_url, category, logo_url, banner_url')
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(30),

      // 5: offline offers
      serviceClient.from('offline_offers')
        .select('id, business_name, offer_description, discount_label, how_to_avail, address, city, phone, expiry_date, category, logo_url, banner_url, map_url')
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(30),

      // 6: MOUs
      serviceClient.from('mous')
        .select('title, description, partner_name, signed_date, expiry_date')
        .order('signed_date', { ascending: false })
        .limit(20),

      // 7: past events (last 5)
      serviceClient.from('events')
        .select('title, starts_at, location_name, is_remote, description')
        .eq('is_published', true)
        .lt('starts_at', now.toISOString())
        .order('starts_at', { ascending: false })
        .limit(5),
    ]

    // 8: members (when relevant)
    const needsMembers = wantsMembers || (!wantsBirthdays && !wantsEvents && !wantsOffers && !wantsPartners)
    if (needsMembers) {
      fetchList.push(
        serviceClient.from('profiles')
          .select('id, first_name, last_name, primary_email, phone, dob, blood_group, job_title, company_name, industry, personal_bio, business_bio, yi_vertical, yi_position, yi_member_since, member_type, city, state, business_tags, hobby_tags, spouse_name')
          .eq('onboarding_done', true)
          .order('first_name')
          .limit(100)
      )
    }

    // 9: birthdays this month
    if (wantsBirthdays) {
      fetchList.push(
        serviceClient.rpc('get_birthdays_by_month', { target_month: currentMonth })
      )
    }

    const results = await Promise.all(fetchList)

    const upcomingEvents  = results[0].data ?? []
    const memberCount     = results[1].count ?? 0
    const verticals       = results[2].data ?? []
    const partners        = results[3].data ?? []
    const onlineOffers    = results[4].data ?? []
    const offlineOffers   = results[5].data ?? []
    const mous            = results[6].data ?? []
    const pastEvents      = results[7].data ?? []

    const membersIdx  = 8
    const members     = needsMembers ? (results[membersIdx]?.data ?? []) : []
    const bdayIdx     = needsMembers ? 9 : 8
    const birthdays   = wantsBirthdays ? (results[bdayIdx]?.data ?? []) : []

    // ── Build context ─────────────────────────────────────────────────────────
    const contextParts: string[] = [
      `Young Indians (YI) Kanpur Chapter — Active members: ${memberCount}`,
    ]

    // Verticals from DB (override static if available)
    if (verticals.length > 0) {
      const vList = verticals
        .filter((v: any) => v.slug !== 'none')
        .map((v: any) => `- ${v.label}${v.description ? ': ' + v.description : ''}`)
        .join('\n')
      contextParts.push(`Chapter Verticals:\n${vList}`)
    }

    // Upcoming events
    if (upcomingEvents.length > 0) {
      contextParts.push(`Upcoming Events:\n${upcomingEvents.map((e: any) =>
        `- "${e.title}" on ${new Date(e.starts_at).toLocaleDateString('en-IN')} (${e.is_remote ? 'Online' : e.location_name ?? 'Venue TBD'})${e.description ? ': ' + e.description.slice(0, 150) : ''}`
      ).join('\n')}`)
    } else {
      contextParts.push('No upcoming events scheduled currently.')
    }

    // Past events
    if (pastEvents.length > 0) {
      contextParts.push(`Recent Past Events:\n${pastEvents.map((e: any) =>
        `- "${e.title}" on ${new Date(e.starts_at).toLocaleDateString('en-IN')} (${e.is_remote ? 'Online' : e.location_name ?? ''})`
      ).join('\n')}`)
    }

    // Members
    if (members.length > 0) {
      const memberList = members.map((m: any) => {
        const name     = [m.first_name, m.last_name].filter(Boolean).join(' ')
        const role     = [m.job_title, m.company_name].filter(Boolean).join(' @ ')
        const yi       = [
          m.yi_position !== 'none' ? m.yi_position : null,
          m.yi_vertical !== 'none' ? m.yi_vertical : null,
        ].filter(Boolean).join(', ')
        const type     = m.member_type !== 'member' ? ` [${m.member_type}]` : ''
        const location = [m.city, m.state].filter(Boolean).join(', ')
        const contact  = [
          m.primary_email ? `Email: ${m.primary_email}` : '',
          m.phone ? `Phone: ${m.phone}` : '',
        ].filter(Boolean).join(', ')
        const extras   = [
          m.dob ? `DOB: ${new Date(m.dob).toLocaleDateString('en-IN')}` : '',
          m.blood_group ? `Blood: ${m.blood_group}` : '',
          m.spouse_name ? `Spouse: ${m.spouse_name}` : '',
          location,
          contact,
          m.business_tags?.length ? `Business: ${m.business_tags.join(', ')}` : '',
          m.hobby_tags?.length ? `Hobbies: ${m.hobby_tags.join(', ')}` : '',
        ].filter(Boolean).join(' | ')
        return `- ${name}${role ? ` (${role})` : ''}${yi ? ` [YI: ${yi}]` : ''}${type}${extras ? `\n  ${extras}` : ''}`
      }).join('\n')
      contextParts.push(`Members (${members.length}):\n${memberList}`)
    }

    // Birthdays
    if (birthdays.length > 0) {
      const bdayList = birthdays.map((b: any) => {
        const name      = b.full_name || [b.first_name, b.last_name].filter(Boolean).join(' ')
        const daysUntil = b.days_until
        const when      = daysUntil === 0 ? 'TODAY' : daysUntil === 1 ? 'tomorrow' : daysUntil > 0 ? `in ${daysUntil} days` : `${Math.abs(daysUntil)} days ago`
        return `- ${name}: birthday ${when} (turning ${b.age_turning})`
      }).join('\n')
      contextParts.push(`Birthdays this month (${now.toLocaleString('en-IN', { month: 'long' })}):\n${bdayList}`)
    }

    // Partners
    if (partners.length > 0) {
      const pList = partners.map((p: any) =>
        `- ${p.name}${p.category ? ` [${p.category}]` : ''}${p.description ? ': ' + p.description.slice(0, 100) : ''}`
      ).join('\n')
      contextParts.push(`Partners & Collaborators:\n${pList}`)
    }

    // Online offers
    if (onlineOffers.length > 0) {
      const oList = onlineOffers.map((o: any) => {
        const code     = o.coupon_code ? ` | Coupon: ${o.coupon_code}` : ''
        const expiry   = o.expiry_date ? ` | Expires: ${o.expiry_date}` : ''
        const claim    = o.how_to_claim ? ` | How to claim: ${o.how_to_claim.slice(0, 100)}` : ''
        return `- [Online] ${o.brand_name}${o.category ? ` (${o.category})` : ''}: ${o.title}${o.discount_label ? ' — ' + o.discount_label : ''}${code}${expiry}${claim}`
      }).join('\n')
      contextParts.push(`Online Member Offers:\n${oList}`)
    } else {
      contextParts.push('Online Member Offers: None currently active.')
    }

    // Offline offers
    if (offlineOffers.length > 0) {
      const oList = offlineOffers.map((o: any) => {
        const loc    = [o.city].filter(Boolean).join(', ')
        const expiry = o.expiry_date ? ` | Expires: ${o.expiry_date}` : ''
        const avail  = o.how_to_avail ? ` | How to avail: ${o.how_to_avail.slice(0, 100)}` : ''
        return `- [In-Store] ${o.business_name}${o.category ? ` (${o.category})` : ''}${loc ? ` — ${loc}` : ''}: ${o.offer_description}${o.discount_label ? ' — ' + o.discount_label : ''}${expiry}${avail}`
      }).join('\n')
      contextParts.push(`In-Store Member Offers:\n${oList}`)
    } else {
      contextParts.push('In-Store Member Offers: None currently active.')
    }

    // MOUs
    if (mous.length > 0) {
      const mouList = mous.map((m: any) =>
        `- ${m.title}${m.partner_name ? ` with ${m.partner_name}` : ''}${m.signed_date ? ` (signed ${new Date(m.signed_date).toLocaleDateString('en-IN')})` : ''}${m.description ? ': ' + m.description.slice(0, 100) : ''}`
      ).join('\n')
      contextParts.push(`MOUs / Agreements:\n${mouList}`)
    }

    // RAG semantic search
    try {
      const embedResponse = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: 'text-embedding-3-small', input: lastUserMessage }),
      })
      const embedData = await embedResponse.json()
      if (embedData?.data?.[0]?.embedding) {
        const { data: chunks } = await serviceClient.rpc('match_embeddings', {
          query_embedding: embedData.data[0].embedding,
          match_threshold: 0.7,
          match_count: 3,
        })
        if (chunks?.length) {
          contextParts.push(`Additional Context:\n${chunks.map((c: any) => c.content).join('\n')}`)
        }
      }
    } catch (_) { /* skip RAG if unavailable */ }

    // ── System prompt ─────────────────────────────────────────────────────────
    const systemPrompt = `You are the YI Assistant — a friendly AI helper for the Young Indians (YI) Kanpur Chapter app.

CRITICAL FORMATTING RULES (strictly follow these):
- NEVER use markdown. No **bold**, no *italic*, no ### headers, no --- dividers.
- Use plain text only. Use emojis to create visual structure.
- Keep responses SHORT and scannable. Max 5-6 lines for most answers.
- For lists: use emoji bullets like 📅 or → not dashes or numbers.
- Separate sections with a blank line, not headers.
- Be conversational, warm, and direct — like a helpful colleague.

ANSWERING RULES:
1. Use LIVE DATA below for specific facts (events, members, offers, birthdays).
2. Use ORGANISATION KNOWLEDGE for general YI questions.
3. Members: name, company/role, YI position — keep it to 2-3 lines per person.
4. Birthdays: use "today!", "tomorrow", "in 3 days" — add a birthday emoji 🎂.
5. Events: date + venue on one line, then 1 short line of description max.
6. Offers: Online (show coupon code prominently) vs In-Store (show how to avail).
7. If you don't have specific info, say so in one line, then show the options block.
8. NEVER invent, guess, or fabricate offers, events, members, or any data. If LIVE DATA shows no offers, say "No active offers right now" — do not make any up.

FORMAT FOR EVENTS (use only real data from LIVE DATA):
📅 [Event Title]
[Date] · [Venue]
[One line description]

FORMAT FOR OFFERS (use only real data from LIVE DATA):
🟢 [Brand Name] (Online)
[Discount] — Code: [Code if available]
Visit: [website]

🟠 [Business Name] (In-Store)
[Discount] — [How to avail]

FORMAT FOR MEMBERS (use only real data from LIVE DATA):
👤 [Full Name]
[Job Title] @ [Company] | [YI Vertical]
📞 [Phone]

WHEN YOU DON'T HAVE THE ANSWER:
Say it in one friendly line, then add:

Here's what I can help you with:
📅 Upcoming Events
👥 Member Directory
🎁 Privileges & Offers
🎂 Birthdays This Month
🤝 Partners & MOUs

ORGANISATION KNOWLEDGE:
${YI_KNOWLEDGE}

LIVE DATA:
${contextParts.join('\n\n')}`

    const chatResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          ...messages.slice(-10),
        ],
        max_tokens: 900,
        temperature: 0.35,
      }),
    })

    const chatData = await chatResponse.json()

    if (!chatResponse.ok) {
      const errMsg = chatData?.error?.message ?? 'OpenAI request failed'
      return new Response(JSON.stringify({ reply: `AI error: ${errMsg}` }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const reply = chatData.choices?.[0]?.message?.content || 'Sorry, I could not generate a response.'

    // ── Build deep-link actions ───────────────────────────────────────────────
    const actions: any[] = []

    if (wantsEvents && upcomingEvents.length > 0) {
      upcomingEvents.slice(0, 4).forEach((e: any) => {
        actions.push({ label: e.title, type: 'event', id: e.id })
      })
    }

    if (wantsOffers) {
      onlineOffers.slice(0, 3).forEach((o: any) => {
        actions.push({ label: o.brand_name, type: 'online_offer', id: o.id, data: o })
      })
      offlineOffers.slice(0, 3).forEach((o: any) => {
        actions.push({ label: o.business_name, type: 'offline_offer', id: o.id, data: o })
      })
    }

    if (wantsMembers && members.length > 0) {
      // Prefer name-matched members (for queries like "who is John"), else show first 5 fetched
      const nameMatched = members.filter((m: any) => {
        const first = (m.first_name || '').toLowerCase()
        const last  = (m.last_name  || '').toLowerCase()
        return first.length > 2 && (lastUserMessage.includes(first) || lastUserMessage.includes(last))
      })
      const chipsSource = nameMatched.length > 0 ? nameMatched.slice(0, 5) : members.slice(0, 5)
      chipsSource.forEach((m: any) => {
        actions.push({ label: `${m.first_name} ${m.last_name}`, type: 'member', id: m.id })
      })
    }

    return new Response(JSON.stringify({ reply, actions }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err) {
    console.error('AI Chat error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error', detail: String(err) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
