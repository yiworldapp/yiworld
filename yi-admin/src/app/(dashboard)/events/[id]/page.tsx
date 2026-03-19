import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import { LinkButton } from '@/components/ui/link-button'
import { Badge } from '@/components/ui/badge'
import { format } from 'date-fns'
import { Calendar, Clock, MapPin, Users, Globe, Pencil, ArrowLeft } from 'lucide-react'
import { verticalBadgeStyle } from '@/lib/vertical-colors'

export default async function ViewEventPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: event } = await supabase
    .from('events')
    .select('*, verticals(label, slug), event_rsvps(count), event_gallery(*), event_organizers(profile_id, profiles(first_name, last_name, headshot_url))')
    .eq('id', id)
    .single()

  if (!event) notFound()

  const vertical = event.verticals as any
  const rsvpCount = (event.event_rsvps as any)?.[0]?.count || 0
  const gallery = (event.event_gallery as any[]) || []
  const organizers = (event.event_organizers as any[]) || []

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <LinkButton href="/events" variant="ghost" size="sm" className="h-8 w-8 p-0 text-muted-foreground">
            <ArrowLeft className="w-4 h-4" />
          </LinkButton>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">{event.title}</h1>
            <div className="flex items-center gap-2 mt-1">
              <Badge variant={event.is_published ? 'default' : 'secondary'} className="text-xs">
                {event.is_published ? 'Live' : 'Draft'}
              </Badge>
              {vertical && (
                <Badge variant="outline" className="text-xs" style={verticalBadgeStyle(vertical.slug)}>
                  {vertical.label}
                </Badge>
              )}
            </div>
          </div>
        </div>
        <LinkButton href={`/events/${id}/edit`} size="sm" className="bg-foreground text-background hover:bg-foreground/90 shrink-0">
          <Pencil className="mr-1.5 h-3.5 w-3.5" /> Edit Event
        </LinkButton>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* LEFT — Main */}
        <div className="lg:col-span-2 space-y-6">

          {/* Cover */}
          {event.cover_image_url && (
            <div className="rounded-xl overflow-hidden border border-border">
              <img src={event.cover_image_url} alt={event.title} className="w-full h-64 object-cover" />
            </div>
          )}

          {/* Description */}
          {event.description && (
            <div className="rounded-xl border border-border p-5">
              <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">About</h2>
              <p className="text-sm text-foreground leading-relaxed whitespace-pre-wrap">{event.description}</p>
            </div>
          )}

          {/* Gallery */}
          {gallery.length > 0 && (
            <div className="rounded-xl border border-border p-5">
              <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">Gallery</h2>
              <div className="grid grid-cols-3 gap-2">
                {gallery.map((item: any) => (
                  <div key={item.id} className="aspect-square rounded-lg overflow-hidden bg-muted">
                    {item.media_type === 'video' ? (
                      <video src={item.media_url} className="w-full h-full object-cover" muted playsInline preload="metadata" />
                    ) : (
                      <img src={item.media_url} alt="" className="w-full h-full object-cover" />
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Organizers */}
          {organizers.length > 0 && (
            <div className="rounded-xl border border-border p-5">
              <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">Organizers</h2>
              <div className="flex flex-wrap gap-3">
                {organizers.map((o: any) => {
                  const p = o.profiles
                  const name = [p?.first_name, p?.last_name].filter(Boolean).join(' ') || 'Member'
                  const initials = [p?.first_name?.[0], p?.last_name?.[0]].filter(Boolean).join('').toUpperCase() || '?'
                  return (
                    <div key={o.profile_id} className="flex items-center gap-2 bg-muted rounded-lg px-3 py-2">
                      {p?.headshot_url ? (
                        <img src={p.headshot_url} alt={name} className="w-7 h-7 rounded-full object-cover" />
                      ) : (
                        <div className="w-7 h-7 rounded-full bg-foreground/10 flex items-center justify-center text-xs font-bold">{initials}</div>
                      )}
                      <span className="text-sm font-medium">{name}</span>
                    </div>
                  )
                })}
              </div>
            </div>
          )}
        </div>

        {/* RIGHT — Details sidebar */}
        <div className="space-y-4">

          {/* Date & Time */}
          <div className="rounded-xl border border-border p-5 space-y-3">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Date & Time</h2>
            <div className="flex items-start gap-3">
              <Calendar className="w-4 h-4 text-muted-foreground mt-0.5 shrink-0" />
              <div>
                <p className="text-sm font-medium">{format(new Date(event.starts_at), 'EEEE, dd/MM/yyyy')}</p>
                <p className="text-xs text-muted-foreground">{format(new Date(event.starts_at), 'h:mm a')}
                  {event.ends_at && ` — ${format(new Date(event.ends_at), 'h:mm a')}`}
                </p>
              </div>
            </div>
            {event.ends_at && new Date(event.ends_at).toDateString() !== new Date(event.starts_at).toDateString() && (
              <div className="flex items-start gap-3">
                <Clock className="w-4 h-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-xs text-muted-foreground">Ends</p>
                  <p className="text-sm font-medium">{format(new Date(event.ends_at), 'EEEE, dd/MM/yyyy')}</p>
                </div>
              </div>
            )}
          </div>

          {/* Location */}
          <div className="rounded-xl border border-border p-5 space-y-3">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Location</h2>
            {event.is_remote ? (
              <div className="flex items-start gap-3">
                <Globe className="w-4 h-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">Remote Event</p>
                  {event.location_url && (
                    <a href={event.location_url} target="_blank" rel="noopener noreferrer" className="text-xs text-primary hover:underline">
                      Join Link
                    </a>
                  )}
                </div>
              </div>
            ) : (
              <div className="flex items-start gap-3">
                <MapPin className="w-4 h-4 text-muted-foreground mt-0.5 shrink-0" />
                <div>
                  <p className="text-sm font-medium">{event.location_name || '—'}</p>
                  {event.location_url && (
                    <a href={event.location_url} target="_blank" rel="noopener noreferrer" className="text-xs text-primary hover:underline">
                      View on Maps
                    </a>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Stats */}
          <div className="rounded-xl border border-border p-5 space-y-3">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Attendance</h2>
            <div className="flex items-center gap-3">
              <Users className="w-4 h-4 text-muted-foreground shrink-0" />
              <div>
                <p className="text-sm font-medium">{rsvpCount} attending</p>
                {event.max_attendees && (
                  <p className="text-xs text-muted-foreground">of {event.max_attendees} max</p>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
