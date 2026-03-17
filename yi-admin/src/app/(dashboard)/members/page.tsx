import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
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
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()

  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('members')) redirect('/events')

  const params = await searchParams
  let query = supabase.from('profiles').select('*').order('created_at', { ascending: false })

  if (params.type) query = query.eq('member_type', params.type)
  if (params.vertical) query = query.eq('yi_vertical', params.vertical)
  if (params.search) {
    query = query.or(`first_name.ilike.%${params.search}%,last_name.ilike.%${params.search}%`)
  }

  const { data: members } = await query

  const allMembers = members || []

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Members</h1>
          <p className="text-muted-foreground text-sm mt-1">{allMembers.length} total members</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2">
        <FilterChip href="/members" label="All" active={!params.type} />
        <FilterChip href="/members?type=member" label="Members" active={params.type === 'member'} />
        <FilterChip href="/members?type=committee" label="Committee" active={params.type === 'committee'} />
      </div>

      {allMembers.length === 0 ? (
        <Card className="border-dashed border-border">
          <CardContent className="flex flex-col items-center justify-center py-16">
            <Users className="w-12 h-12 text-muted-foreground/40 mb-4" />
            <p className="text-muted-foreground">No members found</p>
          </CardContent>
        </Card>
      ) : (
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
                      {format(new Date(member.created_at), 'MMM d, yyyy')}
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
      )}
    </div>
  )
}

function FilterChip({
  href, label, active, accent
}: { href: string; label: string; active: boolean; accent?: string }) {
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
