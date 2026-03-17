import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient, createClient } from '@/lib/supabase/server'

async function requireAccess() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null
  const { data } = await supabase
    .from('admin_users')
    .select('role, permissions')
    .eq('id', user.id)
    .single()
  if (!data) return null
  const hasAccess =
    data.role === 'super_admin' ||
    (data.permissions || []).includes('organisation-emails')
  return hasAccess ? user : null
}

// POST — add one or many emails
export async function POST(req: NextRequest) {
  const caller = await requireAccess()
  if (!caller) return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })

  const { emails } = await req.json()
  if (!Array.isArray(emails) || emails.length === 0) {
    return NextResponse.json({ error: 'emails array required' }, { status: 400 })
  }

  const rows = emails
    .map((e: string) => e.trim().toLowerCase())
    .filter(e => e.includes('@'))
    .map(email => ({ email }))

  if (rows.length === 0) {
    return NextResponse.json({ error: 'No valid emails provided' }, { status: 400 })
  }

  const supabase = await createAdminClient()
  const { data, error } = await supabase
    .from('organisation_emails')
    .upsert(rows, { onConflict: 'email', ignoreDuplicates: true })
    .select()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ inserted: data?.length ?? 0 })
}

// DELETE — remove by id
export async function DELETE(req: NextRequest) {
  const caller = await requireAccess()
  if (!caller) return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })

  const { id } = await req.json()
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 })

  const supabase = await createAdminClient()
  const { error } = await supabase.from('organisation_emails').delete().eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}
