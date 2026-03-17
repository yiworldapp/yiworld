import { createClient, createAdminClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { ArrowLeft } from 'lucide-react'
import { LinkButton } from '@/components/ui/link-button'
import { EditMemberForm } from './_components/edit-member-form'

export default async function EditMemberPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('members')) redirect('/events')

  const [{ data: member }, { data: verticals }] = await Promise.all([
    supabase.from('profiles').select('*').eq('id', id).single(),
    supabase.from('verticals').select('slug, label').order('label'),
  ])
  if (!member) notFound()

  const fullName = [member.first_name, member.last_name].filter(Boolean).join(' ') || 'Unnamed'

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <LinkButton href={`/members/${id}`} variant="ghost" size="sm" className="h-8 w-8 p-0">
          <ArrowLeft className="w-4 h-4" />
        </LinkButton>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Edit Member</h1>
          <p className="text-muted-foreground text-sm mt-0.5">{fullName}</p>
        </div>
      </div>

      <EditMemberForm member={member} verticals={verticals ?? []} />
    </div>
  )
}
