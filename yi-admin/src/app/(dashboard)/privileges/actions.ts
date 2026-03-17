'use server'

import { createAdminClient } from '@/lib/supabase/server'

export async function upsertPartner(
  data: Record<string, unknown>,
  partnerId?: string
) {
  const supabase = await createAdminClient()
  if (partnerId) {
    const { error } = await supabase.from('partners').update(data).eq('id', partnerId)
    if (error) throw new Error(error.message)
  } else {
    const { error } = await supabase.from('partners').insert(data)
    if (error) throw new Error(error.message)
  }
}

export async function upsertOffer(
  data: Record<string, unknown>,
  offerId?: string
) {
  const supabase = await createAdminClient()
  if (offerId) {
    const { error } = await supabase.from('offers').update(data).eq('id', offerId)
    if (error) throw new Error(error.message)
  } else {
    const { error } = await supabase.from('offers').insert(data)
    if (error) throw new Error(error.message)
  }
}

export async function deletePrivilege(id: string, type: 'partner' | 'offer') {
  const supabase = await createAdminClient()
  const table = type === 'partner' ? 'partners' : 'offers'
  const { error } = await supabase.from(table).delete().eq('id', id)
  if (error) throw new Error(error.message)
}
