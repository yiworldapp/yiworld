import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { getUser, getAdminProfile } from '@/lib/auth'
import { createAdminClient } from '@/lib/supabase/server'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { ShieldCheck } from 'lucide-react'
import { format } from 'date-fns'
import { AdminUserActions } from './_components/admin-user-actions'

export default async function AdminUsersPage() {
  const adminUser = await getAdminProfile() // cached — free
  if (adminUser?.role !== 'super_admin') redirect('/events')

  const user = await getUser() // cached — free

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Admin Users</h1>
      </div>

      <Suspense fallback={<AdminUsersTableSkeleton />}>
        <AdminUsersTable currentUserId={user!.id} />
      </Suspense>
    </div>
  )
}

async function AdminUsersTable({ currentUserId }: { currentUserId: string }) {
  const adminClient = await createAdminClient()
  const { data: admins } = await adminClient
    .from('admin_users')
    .select('*')
    .order('status', { ascending: true })
    .order('created_at', { ascending: false })

  const allAdmins = admins || []
  const pendingCount = allAdmins.filter(a => a.status === 'pending').length

  if (allAdmins.length === 0) {
    return (
      <Card className="border-dashed border-border">
        <CardContent className="flex flex-col items-center justify-center py-16">
          <ShieldCheck className="w-12 h-12 text-muted-foreground/40 mb-4" />
          <p className="text-muted-foreground">No admin users found</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <>
      <p className="text-muted-foreground text-sm -mt-4">
        {allAdmins.length} dashboard users
        {pendingCount > 0 && (
          <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
            {pendingCount} pending
          </span>
        )}
      </p>
      <div className="rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/40">
            <tr>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide">User</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden sm:table-cell">Email</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Role</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden md:table-cell">Access</th>
              <th className="text-left py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Added</th>
              <th className="text-right py-3 px-4 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Actions</th>
            </tr>
          </thead>
          <tbody>
            {allAdmins.map((admin) => (
              <tr key={admin.id} className="border-b border-border last:border-b-0 hover:bg-muted/30 transition-colors">
                <td className="py-3 px-4">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-full bg-muted border border-border flex items-center justify-center shrink-0">
                      <span className="text-xs font-bold text-foreground">
                        {admin.name?.charAt(0)?.toUpperCase() || 'A'}
                      </span>
                    </div>
                    <div>
                      <p className="font-medium text-foreground">{admin.name || '—'}</p>
                      {admin.status === 'pending' && (
                        <span className="text-xs text-orange-600 font-medium">Pending approval</span>
                      )}
                    </div>
                  </div>
                </td>
                <td className="py-3 px-4 hidden sm:table-cell text-muted-foreground text-sm">
                  {admin.email}
                </td>
                <td className="py-3 px-4">
                  {admin.status === 'pending' ? (
                    <Badge variant="outline" className="text-xs text-orange-600 border-orange-200 bg-orange-50">
                      Pending
                    </Badge>
                  ) : (
                    <Badge
                      variant="outline"
                      className={`text-xs font-medium capitalize ${
                        admin.role === 'super_admin'
                          ? 'text-purple-600 border-purple-200 bg-purple-50'
                          : 'text-blue-600 border-blue-200 bg-blue-50'
                      }`}
                    >
                      {admin.role.replace('_', ' ')}
                    </Badge>
                  )}
                </td>
                <td className="py-3 px-4 hidden md:table-cell">
                  {admin.status === 'active' && admin.role === 'super_admin' ? (
                    <span className="text-xs text-muted-foreground">All pages</span>
                  ) : admin.status === 'active' && admin.permissions?.length > 0 ? (
                    <div className="flex flex-wrap gap-1">
                      {admin.permissions.map((p: string) => (
                        <span key={p} className="text-xs px-1.5 py-0.5 rounded bg-muted border border-border capitalize">
                          {p}
                        </span>
                      ))}
                    </div>
                  ) : (
                    <span className="text-xs text-muted-foreground">—</span>
                  )}
                </td>
                <td className="py-3 px-4 hidden lg:table-cell text-muted-foreground text-sm">
                  {format(new Date(admin.created_at), 'd MMM yyyy')}
                </td>
                <td className="py-3 px-4 text-right">
                  <AdminUserActions admin={admin} currentUserId={currentUserId} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}

function AdminUsersTableSkeleton() {
  return (
    <div className="rounded-lg border border-border overflow-hidden animate-pulse">
      <div className="bg-muted/40 border-b border-border h-10" />
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 px-4 py-3 border-b border-border last:border-b-0">
          <div className="w-9 h-9 bg-muted rounded-full shrink-0" />
          <div className="flex-1 h-4 bg-muted rounded w-32" />
          <div className="h-4 bg-muted rounded w-40 hidden sm:block" />
          <div className="h-5 bg-muted rounded-full w-16 ml-auto" />
        </div>
      ))}
    </div>
  )
}
