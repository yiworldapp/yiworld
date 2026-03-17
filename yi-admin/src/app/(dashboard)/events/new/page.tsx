import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { EventForm } from '../_components/event-form'

export default async function NewEventPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')
  // user.id intentionally not passed to form — admin users are not in profiles table

  const admin = await createAdminClient()
  const [{ data: verticals }, { data: committee }] = await Promise.all([
    admin.from('verticals').select('*').order('label'),
    admin.from('profiles').select('id, first_name, last_name, yi_vertical, member_type, headshot_url')
      .in('member_type', ['committee', 'super_admin'])
      .order('first_name'),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Create Event</h1>
        <p className="text-muted-foreground text-sm mt-1">Add a new event for members</p>
      </div>
      <EventForm
        verticals={verticals || []}
        committeeMembers={(committee as any) || []}
      />
    </div>
  )
}
