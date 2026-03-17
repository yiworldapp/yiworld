import { redirect } from 'next/navigation'
import { createAdminClient, createClient } from '@/lib/supabase/server'
import { OrgEmailsClient } from './_components/org-emails-client'

export default async function OrganisationEmailsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: adminUser } = await supabase
    .from('admin_users')
    .select('role, permissions')
    .eq('id', user.id)
    .single()

  const hasAccess =
    adminUser?.role === 'super_admin' ||
    (adminUser?.permissions || []).includes('organisation-emails')

  if (!hasAccess) redirect('/events')

  const adminClient = await createAdminClient()
  const { data: emails } = await adminClient
    .from('organisation_emails')
    .select('id, email, created_at')
    .order('created_at', { ascending: false })

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Organisation Emails</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Only emails in this list can log in to the YI app.
        </p>
      </div>
      <OrgEmailsClient initialEmails={emails ?? []} />
    </div>
  )
}
