import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { getAdminProfile } from '@/lib/auth'
import { createAdminClient } from '@/lib/supabase/server'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Card, CardContent } from '@/components/ui/card'
import { MemberActions } from './_components/member-actions'
import { LinkButton } from '@/components/ui/link-button'
import { format } from 'date-fns'
import { Users, Eye } from 'lucide-react'
import { verticalBadgeStyle, verticalLabel } from '@/lib/vertical-colors'

export default async function MembersPage({
  searchParams,
}: {
  searchParams: Promise<{ type?: string; vertical?: string; search?: string }>
}) {
  const adminUser = await getAdminProfile() // cached — free
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('members')) redirect('/events')

  const params = await searchParams

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Members</h1>
      </div>

      {/* Filters render instantly */}
      <div className="flex flex-wrap gap-2">
        <FilterChip href="/members" label="All" active={!params.type} />
        <FilterChip href="/members?type=member" label="Members" active={params.type === 'member'} />
        <FilterChip href="/members?type=committee" label="Committee" active={params.type === 'committee'} />
      </div>

      <Suspense fallback={<MembersTableSkeleton />}>
        <MembersTable params={params} />
      </Suspense>
    </div>
  )
}

async function MembersTable({ params }: { params: { type?: string; vertical?: string; search?: string } }) {
  const adminClient = await createAdminClient()
  let query = adminClient.from('profiles').select('*').order('created_at', { ascending: false })

  if (params.type) query = query.eq('member_type', params.type)
  if (params.vertical) query = query.eq('yi_vertical', params.vertical)
  if (params.search) {
    query = query.or(`first_name.ilike.%${params.search}%,last_name.ilike.%${params.search}%`)
  }

  const { data: members } = await query
  const allMembers = members || []

  if (allMembers.length === 0) {
    return (
      <Card className="border-dashed border-border">
        <CardContent className="flex flex-col items-center justify-center py-16">
          <Users className="w-12 h-12 text-muted-foreground/40 mb-4" />
          <p className="text-muted-foreground">No members found</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <>
      <p className="text-muted-foreground text-sm -mt-4">{allMembers.length} total members</p>
      <div className="rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/40">
            <tr>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Member</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden md:table-cell">Type</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Vertical</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Joined</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden sm:table-cell">Status</th>
              <th className="text-right py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Actions</th>
            </tr>
          </thead>
          <tbody>
            {allMembers.map((member) => {
              const fullName = [member.first_name, member.last_name].filter(Boolean).join(' ') || 'Unnamed'
              const initials = [member.first_name?.[0], member.last_name?.[0]].filter(Boolean).join('').toUpperCase() || '?'
              return (
                <tr key={member.id} className="border-b border-border last:border-b-0 hover:bg-muted/30 transition-colors">
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-3">
                      <Avatar className="h-9 w-9 border border-border shrink-0">
                        <AvatarImage src={member.headshot_url || ''} />
                        <AvatarFallback className="bg-muted text-foreground text-xs font-bold">
                          {initials}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium text-foreground">{fullName}</p>
                        <p className="text-xs text-muted-foreground">{member.phone || member.email || '—'}</p>
                      </div>
                    </div>
                  </td>
                  <td className="py-3 px-4 hidden md:table-cell">
                    <Badge variant="outline" className="text-xs capitalize border-border">
                      {member.member_type.replace('_', ' ')}
                    </Badge>
                  </td>
                  <td className="py-3 px-4 hidden lg:table-cell">
                    {member.yi_vertical && member.yi_vertical !== 'none' ? (
                      <Badge variant="outline" className="text-xs" style={verticalBadgeStyle(member.yi_vertical)}>
                        {verticalLabel(member.yi_vertical)}
                      </Badge>
                    ) : (
                      <span className="text-muted-foreground text-xs">—</span>
                    )}
                  </td>
                  <td className="py-3 px-4 hidden lg:table-cell text-muted-foreground text-sm">
                    {format(new Date(member.created_at), 'd MMM yyyy')}
                  </td>
                  <td className="py-3 px-4 hidden sm:table-cell">
                    <Badge variant="outline" className="text-xs font-medium text-green-600 border-green-200 bg-green-50">
                      Active
                    </Badge>
                  </td>
                  <td className="py-3 px-4 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <LinkButton href={`/members/${member.id}`} variant="ghost" size="sm" className="h-8 w-8 p-0 text-muted-foreground hover:text-foreground">
                        <Eye className="w-3.5 h-3.5" />
                      </LinkButton>
                      <MemberActions member={member} />
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </>
  )
}

function MembersTableSkeleton() {
  return (
    <div className="rounded-lg border border-border overflow-hidden animate-pulse">
      <div className="bg-muted/40 border-b border-border h-10" />
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 px-4 py-3 border-b border-border last:border-b-0">
          <div className="h-9 w-9 bg-muted rounded-full shrink-0" />
          <div className="flex-1 space-y-1.5">
            <div className="h-4 w-36 bg-muted rounded" />
            <div className="h-3 w-24 bg-muted rounded" />
          </div>
          <div className="h-5 w-16 bg-muted rounded-full hidden md:block" />
          <div className="h-4 w-20 bg-muted rounded hidden lg:block" />
        </div>
      ))}
    </div>
  )
}

function FilterChip({ href, label, active, accent }: { href: string; label: string; active: boolean; accent?: string }) {
  const activeClass = accent === 'orange'
    ? 'bg-orange-50 text-orange-600 border-orange-200'
    : 'bg-foreground text-background border-foreground'

  return (
    <a
      href={href}
      className={`px-3 py-1.5 rounded-md border text-sm font-medium transition-colors
        ${active ? activeClass : 'border-border text-muted-foreground hover:text-foreground hover:border-foreground/40'}`}
    >
      {label}
    </a>
  )
}
