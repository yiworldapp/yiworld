import { cache } from 'react'
import { createClient, createAdminClient } from './supabase/server'

// React cache deduplicates these calls within a single request.
// Layout and page both call these, but they only hit the DB once.

export const getUser = cache(async () => {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  return user
})

export const getAdminProfile = cache(async () => {
  const user = await getUser()
  if (!user) return null
  const adminClient = await createAdminClient()
  const { data } = await adminClient
    .from('admin_users')
    .select('id, name, email, role, status, permissions, created_at')
    .eq('id', user.id)
    .single()
  return data
})
