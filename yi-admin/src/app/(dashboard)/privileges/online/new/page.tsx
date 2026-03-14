import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { OnlineOfferForm } from '../../_components/online-offer-form'

export default async function NewOnlineOfferPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('privileges')) redirect('/events')

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">New Online Offer</h1>
        <p className="text-muted-foreground text-sm mt-1">Add a new online offer for YI members</p>
      </div>
      <OnlineOfferForm />
    </div>
  )
}
