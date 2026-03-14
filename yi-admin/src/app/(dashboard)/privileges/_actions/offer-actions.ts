'use server'

import { createAdminClient, createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function upsertOnlineOffer(formData: {
  id?: string
  brand_name: string
  category: string
  website_url: string | null
  title: string
  discount_label: string | null
  coupon_code: string | null
  about_offer: string | null
  how_to_claim: string | null
  terms_and_conditions: string | null
  expiry_date: string | null
  logo_url: string | null
  banner_url: string | null
  is_active: boolean
}) {
  const authClient = await createClient()
  const { data: { user } } = await authClient.auth.getUser()
  if (!user) throw new Error('Unauthorized')
  const { data: adminUser } = await authClient.from('admin_users').select('role, permissions').eq('id', user.id).single()
  if (!adminUser) throw new Error('Unauthorized')
  if (adminUser.role !== 'super_admin' && !adminUser.permissions?.includes('privileges')) throw new Error('Unauthorized')

  const supabase = await createAdminClient()
  const { id, ...payload } = formData

  if (id) {
    const { error } = await supabase.from('online_offers').update(payload).eq('id', id)
    if (error) throw new Error(error.message)
  } else {
    const { error } = await supabase.from('online_offers').insert(payload)
    if (error) throw new Error(error.message)
  }

  revalidatePath('/privileges')
}

export async function upsertOfflineOffer(formData: {
  id?: string
  business_name: string
  category: string
  city: string | null
  phone: string | null
  address: string | null
  map_url: string | null
  offer_description: string
  discount_label: string | null
  how_to_avail: string | null
  expiry_date: string | null
  logo_url: string | null
  banner_url: string | null
  is_active: boolean
}) {
  const authClient = await createClient()
  const { data: { user } } = await authClient.auth.getUser()
  if (!user) throw new Error('Unauthorized')
  const { data: adminUser } = await authClient.from('admin_users').select('role, permissions').eq('id', user.id).single()
  if (!adminUser) throw new Error('Unauthorized')
  if (adminUser.role !== 'super_admin' && !adminUser.permissions?.includes('privileges')) throw new Error('Unauthorized')

  const supabase = await createAdminClient()
  const { id, ...payload } = formData

  if (id) {
    const { error } = await supabase.from('offline_offers').update(payload).eq('id', id)
    if (error) throw new Error(error.message)
  } else {
    const { error } = await supabase.from('offline_offers').insert(payload)
    if (error) throw new Error(error.message)
  }

  revalidatePath('/privileges')
}

export async function deleteOffer(id: string, table: 'online_offers' | 'offline_offers') {
  const authClient = await createClient()
  const { data: { user } } = await authClient.auth.getUser()
  if (!user) throw new Error('Unauthorized')
  const { data: adminUser } = await authClient.from('admin_users').select('role, permissions').eq('id', user.id).single()
  if (!adminUser) throw new Error('Unauthorized')
  if (adminUser.role !== 'super_admin' && !adminUser.permissions?.includes('privileges')) throw new Error('Unauthorized')

  const supabase = await createAdminClient()
  const { error } = await supabase.from(table).delete().eq('id', id)
  if (error) throw new Error(error.message)
  revalidatePath('/privileges')
}
