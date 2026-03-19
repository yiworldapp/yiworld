import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { OfferForm } from '../_components/offer-form'

export default async function NewOfferPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('privileges')) redirect('/events')

  const { data: partners } = await adminClient.from('partners').select('*').eq('is_active', true).order('name')

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Create Offer</h1>
        <p className="text-muted-foreground text-sm mt-1">Add a new offer or coupon for members</p>
      </div>
      <OfferForm partners={partners || []} />
    </div>
  )
}
