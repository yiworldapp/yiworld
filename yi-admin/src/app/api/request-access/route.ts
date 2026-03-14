import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'

export async function POST(req: NextRequest) {
  const { id, email, name } = await req.json()
  if (!id || !email) return NextResponse.json({ error: 'Missing fields' }, { status: 400 })

  const supabase = await createAdminClient()

  const { error } = await supabase.from('admin_users').insert({
    id,
    email,
    name: name || email.split('@')[0],
    role: 'committee',
    status: 'pending',
    permissions: [],
  })

  if (error && error.code !== '23505') { // ignore duplicate
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ ok: true })
}
