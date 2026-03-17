import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient, createClient } from '@/lib/supabase/server'

async function requireAdminUser() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null
  const { data } = await supabase.from('admin_users').select('role').eq('id', user.id).single()
  if (!data) return null
  return user
}

export async function PATCH(req: NextRequest) {
  const caller = await requireAdminUser()
  if (!caller) return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })

  const { id, ...updates } = await req.json()
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 })

  const supabase = await createAdminClient()

  // Keep auth.users in sync for fields that are used for login
  const authUpdates: Record<string, unknown> = {}
  if (updates.phone) { authUpdates.phone = updates.phone; authUpdates.phone_confirm = true }
  if (updates.primary_email) { authUpdates.email = updates.primary_email; authUpdates.email_confirm = true }
  if (Object.keys(authUpdates).length > 0) {
    const { error: authErr } = await supabase.auth.admin.updateUserById(id, authUpdates)
    if (authErr) return NextResponse.json({ error: `Auth update failed: ${authErr.message}` }, { status: 500 })
  }

  const { error } = await supabase.from('profiles').update(updates).eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}

export async function DELETE(req: NextRequest) {
  const caller = await requireAdminUser()
  if (!caller) return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })

  const { id } = await req.json()
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 })

  const supabase = await createAdminClient()
  const { error } = await supabase.auth.admin.deleteUser(id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}
