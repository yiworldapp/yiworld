import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import { EventForm } from '../../_components/event-form'
import { LinkButton } from '@/components/ui/link-button'
import { Eye } from 'lucide-react'

export default async function EditEventPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const [{ data: event }, { data: verticals }, { data: committee }] = await Promise.all([
    supabase.from('events')
      .select('*, event_gallery(*), event_organizers(*)')
      .eq('id', id)
      .single(),
    supabase.from('verticals').select('*').order('label'),
    supabase.from('profiles').select('id, first_name, last_name, yi_vertical, member_type, headshot_url')
      .in('member_type', ['committee', 'super_admin'])
      .order('first_name'),
  ])

  if (!event) notFound()

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Edit Event</h1>
          <p className="text-muted-foreground text-sm mt-1">{event.title}</p>
        </div>
        <LinkButton href={`/events/${id}`} variant="outline" size="sm" className="shrink-0">
          <Eye className="mr-1.5 h-3.5 w-3.5" /> View Event
        </LinkButton>
      </div>
      <EventForm
        event={event as any}
        verticals={verticals || []}
        committeeMembers={committee || []}
        userId={user.id}
      />
    </div>
  )
}
