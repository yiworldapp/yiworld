import { createClient, createAdminClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { OnlineOfferForm } from '../../../_components/online-offer-form'

export default async function EditOnlineOfferPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('privileges')) redirect('/events')

  const { data: offer } = await adminClient.from('online_offers').select('*').eq('id', id).single()
  if (!offer) notFound()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Edit Online Offer</h1>
        <p className="text-muted-foreground text-sm mt-1">{offer.brand_name}</p>
      </div>
      <OnlineOfferForm offer={offer} />
    </div>
  )
}
