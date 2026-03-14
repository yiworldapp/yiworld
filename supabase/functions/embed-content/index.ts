import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

async function generateEmbedding(text: string, openaiKey: string): Promise<number[]> {
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${openaiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'text-embedding-3-small', input: text }),
  })
  const data = await response.json()
  return data.data[0].embedding
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { type, record } = await req.json()
    const openaiKey = Deno.env.get('OPENAI_API_KEY')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    let content = ''
    let sourceType = type
    let sourceId = record.id

    switch (type) {
      case 'event':
        content = `Event: ${record.title}. ${record.description || ''}.
          Location: ${record.is_remote ? 'Online' : record.location_name || 'TBD'}.
          Date: ${new Date(record.starts_at).toLocaleDateString()}.`
        break
      case 'partner':
        content = `Partner: ${record.name}. Category: ${record.category || 'General'}. ${record.description || ''}.
          Website: ${record.website_url || 'N/A'}.`
        break
      case 'offer':
        content = `Offer: ${record.title}. Type: ${record.offer_type}. Value: ${record.discount_value || 'N/A'}.
          Coupon: ${record.coupon_code || 'None'}. ${record.description || ''}.
          How to claim: ${record.how_to_claim || 'N/A'}.`
        break
      case 'profile':
        if (!record.onboarding_done) break
        content = `Member: ${record.name}. Role: ${record.yi_role || 'Member'}.
          Vertical: ${record.vertical || 'General'}. Type: ${record.member_type}.
          Bio: ${record.bio || 'N/A'}.`
        break
      case 'mou':
        content = `MOU with ${record.partner_name || 'Partner'}. Title: ${record.title}. ${record.description || ''}.
          Signed: ${record.signed_date || 'N/A'}.`
        break
    }

    if (!content.trim()) {
      return new Response(JSON.stringify({ success: true, skipped: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const embedding = await generateEmbedding(content, openaiKey)

    // Upsert embedding
    await supabase.from('chat_embeddings').upsert({
      source_type: sourceType,
      source_id: sourceId,
      content,
      embedding,
      metadata: { record_type: type },
    }, { onConflict: 'source_type,source_id' })

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Embed error:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
