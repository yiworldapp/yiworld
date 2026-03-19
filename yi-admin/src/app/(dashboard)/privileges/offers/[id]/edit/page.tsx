import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import { OfferForm } from '../../_components/offer-form'

export default async function EditOfferPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('privileges')) redirect('/events')

  const [{ data: offer }, { data: partners }] = await Promise.all([
    adminClient.from('offers').select('*').eq('id', id).single(),
    adminClient.from('partners').select('*').eq('is_active', true).order('name'),
  ])
  if (!offer) notFound()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Edit Offer</h1>
        <p className="text-muted-foreground text-sm mt-1">{offer.title}</p>
      </div>
      <OfferForm offer={offer} partners={partners || []} />
    </div>
  )
}
