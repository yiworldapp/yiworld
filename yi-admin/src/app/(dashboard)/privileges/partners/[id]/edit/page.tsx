import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import { PartnerForm } from '../../_components/partner-form'

export default async function EditPartnerPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('privileges')) redirect('/events')

  const { data: partner } = await adminClient.from('partners').select('*').eq('id', id).single()
  if (!partner) notFound()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Edit Partner</h1>
        <p className="text-muted-foreground text-sm mt-1">{partner.name}</p>
      </div>
      <PartnerForm partner={partner} />
    </div>
  )
}
