import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { AppSidebar } from '@/components/app-sidebar'
import { Breadcrumbs } from '@/components/breadcrumbs'
import { UserNav } from '@/components/user-nav'

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const { data: profile } = await supabase
    .from('admin_users')
    .select('id, name, email, role, status, permissions, created_at')
    .eq('id', user.id)
    .single()

  if (!profile || profile.status !== 'active') {
    await supabase.auth.signOut()
    redirect('/login?error=unauthorized')
  }

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      <AppSidebar profile={profile} />
      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        <header className="flex h-14 shrink-0 items-center gap-2 border-b border-border px-6 bg-background z-10">
          <Breadcrumbs />
          <div className="ml-auto">
            <UserNav profile={profile} />
          </div>
        </header>
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
