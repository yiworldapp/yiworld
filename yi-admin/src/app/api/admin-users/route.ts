import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient, createClient } from '@/lib/supabase/server'

async function requireSuperAdmin() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null
  const { data } = await supabase.from('admin_users').select('role').eq('id', user.id).single()
  if (data?.role !== 'super_admin') return null
  return user
}

// PATCH — approve or update permissions
export async function PATCH(req: NextRequest) {
  const caller = await requireSuperAdmin()
  if (!caller) return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })

  const { id, role, status, permissions } = await req.json()
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 })

  const validRoles = ['super_admin', 'committee']
  if (role !== undefined && !validRoles.includes(role)) {
    return NextResponse.json({ error: 'Invalid role' }, { status: 400 })
  }

  const validStatuses = ['pending', 'active']
  if (status !== undefined && !validStatuses.includes(status)) {
    return NextResponse.json({ error: 'Invalid status' }, { status: 400 })
  }

  const validPermissions = ['events', 'members', 'mou', 'privileges', 'admin-users', 'organisation-emails']
  if (permissions !== undefined) {
    if (!Array.isArray(permissions) || !permissions.every((p: unknown) => validPermissions.includes(p as string))) {
      return NextResponse.json({ error: 'Invalid permissions' }, { status: 400 })
    }
  }

  const supabase = await createAdminClient()
  const updates: Record<string, unknown> = {}
  if (role !== undefined) updates.role = role
  if (status !== undefined) updates.status = status
  if (permissions !== undefined) updates.permissions = permissions

  const { error } = await supabase.from('admin_users').update(updates).eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}

// DELETE — remove admin user
export async function DELETE(req: NextRequest) {
  const caller = await requireSuperAdmin()
  if (!caller) return NextResponse.json({ error: 'Unauthorized' }, { status: 403 })

  const { id } = await req.json()
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 })
  if (id === caller.id) return NextResponse.json({ error: 'Cannot delete yourself' }, { status: 400 })

  const supabase = await createAdminClient()
  const { error } = await supabase.auth.admin.deleteUser(id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ ok: true })
}
