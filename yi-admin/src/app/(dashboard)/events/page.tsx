import { Suspense } from 'react'
import { getUser, getAdminProfile } from '@/lib/auth'
import { createAdminClient } from '@/lib/supabase/server'
import { Badge } from '@/components/ui/badge'
import { LinkButton } from '@/components/ui/link-button'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Plus, Calendar, Users, Eye } from 'lucide-react'
import { format } from 'date-fns'
import { DeleteEventButton } from './_components/delete-event-button'
import { verticalBadgeStyle } from '@/lib/vertical-colors'

export default async function EventsPage() {
  const user = await getUser()           // cached — free if layout already called it
  const adminUser = await getAdminProfile() // cached — free

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Events</h1>
        <LinkButton href="/events/new" className="bg-primary hover:bg-primary/90">
          <Plus className="mr-2 h-4 w-4" />
          New Event
        </LinkButton>
      </div>

      <Suspense fallback={<EventsTableSkeleton />}>
        <EventsTable
          userId={user!.id}
          isCommittee={adminUser?.role === 'committee'}
        />
      </Suspense>
    </div>
  )
}

async function EventsTable({ userId, isCommittee }: { userId: string; isCommittee: boolean }) {
  const adminClient = await createAdminClient()
  let query = adminClient
    .from('events')
    .select(`*, verticals(label, color_hex, slug), event_rsvps(count)`)
    .order('starts_at', { ascending: false })

  if (isCommittee) query = query.eq('created_by', userId)

  const { data: events } = await query

  return (
    <>
      <p className="text-muted-foreground text-sm -mt-4">{events?.length || 0} total events</p>
      <div className="rounded-lg border border-border overflow-hidden">
        <Table>
          <TableHeader className="bg-muted/40">
            <TableRow className="hover:bg-transparent border-border">
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Title</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Date</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden xl:table-cell">Vertical</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Attending</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden sm:table-cell">Status</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {!events?.length ? (
              <TableRow>
                <TableCell colSpan={6} className="py-16 text-center text-muted-foreground">
                  <Calendar className="w-10 h-10 mx-auto mb-3 opacity-30" />
                  No events yet
                </TableCell>
              </TableRow>
            ) : events.map((event) => {
              const vertical = event.verticals as any
              const rsvpCount = (event.event_rsvps as any)?.[0]?.count || 0
              return (
                <TableRow key={event.id} className="border-border">
                  <TableCell className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      {event.cover_image_url ? (
                        <img src={event.cover_image_url} alt={event.title} className="w-8 h-8 rounded object-cover shrink-0 border border-border" />
                      ) : (
                        <div className="w-8 h-8 rounded bg-primary/10 border border-primary/20 flex items-center justify-center shrink-0">
                          <Calendar className="w-3.5 h-3.5 text-primary" />
                        </div>
                      )}
                      <span className="font-medium text-foreground">{event.title}</span>
                    </div>
                  </TableCell>
                  <TableCell className="px-4 py-3 text-muted-foreground hidden lg:table-cell text-sm whitespace-nowrap">
                    {format(new Date(event.starts_at), 'd MMM yyyy · h:mm a')}
                  </TableCell>
                  <TableCell className="px-4 py-3 hidden xl:table-cell">
                    {vertical ? (
                      <Badge variant="outline" className="text-xs font-medium" style={verticalBadgeStyle(vertical.slug)}>
                        {vertical.label}
                      </Badge>
                    ) : <span className="text-muted-foreground text-sm">—</span>}
                  </TableCell>
                  <TableCell className="px-4 py-3 text-muted-foreground hidden lg:table-cell text-sm">
                    <div className="flex items-center gap-1.5">
                      <Users className="w-3 h-3" />
                      {rsvpCount}
                    </div>
                  </TableCell>
                  <TableCell className="px-4 py-3 hidden sm:table-cell">
                    <Badge variant={event.is_published ? 'default' : 'secondary'} className="text-xs font-medium">
                      {event.is_published ? 'Live' : 'Draft'}
                    </Badge>
                  </TableCell>
                  <TableCell className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <LinkButton href={`/events/${event.id}`} variant="ghost" size="sm" className="h-8 w-8 p-0 text-muted-foreground hover:text-foreground">
                        <Eye className="w-3.5 h-3.5" />
                      </LinkButton>
                      <LinkButton href={`/events/${event.id}/edit`} variant="ghost" size="sm" className="h-8 w-8 p-0 text-muted-foreground hover:text-foreground">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
                      </LinkButton>
                      <DeleteEventButton eventId={event.id} eventTitle={event.title} />
                    </div>
                  </TableCell>
                </TableRow>
              )
            })}
          </TableBody>
        </Table>
      </div>
    </>
  )
}

function EventsTableSkeleton() {
  return (
    <div className="rounded-lg border border-border overflow-hidden animate-pulse">
      <div className="bg-muted/40 border-b border-border h-10" />
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 px-4 py-3 border-b border-border last:border-b-0">
          <div className="w-8 h-8 bg-muted rounded shrink-0" />
          <div className="flex-1 h-4 bg-muted rounded w-48" />
          <div className="h-4 bg-muted rounded w-32 hidden lg:block" />
          <div className="h-5 bg-muted rounded w-16 hidden sm:block ml-auto" />
        </div>
      ))}
    </div>
  )
}
