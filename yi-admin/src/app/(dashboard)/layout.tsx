import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { getUser, getAdminProfile } from '@/lib/auth'
import { AppSidebar } from '@/components/app-sidebar'
import { Breadcrumbs } from '@/components/breadcrumbs'
import { UserNav } from '@/components/user-nav'

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const user = await getUser()
  if (!user) redirect('/login')

  const profile = await getAdminProfile()
  if (!profile || profile.status !== 'active') {
    const supabase = await createClient()
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
