'use client'

import Link from 'next/link'
import Image from 'next/image'
import { usePathname, useRouter } from 'next/navigation'
import { Calendar, Users, FileText, Gem, LogOut, ShieldCheck } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import type { AdminUser } from '@/types/database.types'
import { cn } from '@/lib/utils'

const navItems = [
  { key: 'events',       href: '/events',       label: 'Events',       icon: Calendar    },
  { key: 'members',      href: '/members',      label: 'Members',      icon: Users       },
  { key: 'admin-users',  href: '/admin-users',  label: 'Admin Users',  icon: ShieldCheck },
  { key: 'mou',          href: '/mou',          label: 'MOUs',         icon: FileText    },
  { key: 'privileges',   href: '/privileges',   label: 'Privileges',   icon: Gem         },
]

export function AppSidebar({ profile }: { profile: AdminUser }) {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()

  const visibleItems = profile.role === 'super_admin'
    ? navItems
    : navItems.filter(item => (profile.permissions || []).includes(item.key))

  async function handleSignOut() {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <aside className="flex flex-col w-56 shrink-0 border-r border-border bg-background h-full">
      {/* Header — Logo */}
      <div className="border-b border-border px-5 h-14 flex items-center">
        <Link href="/events" className="flex items-center gap-3">
          <Image src="/yi_logo.png" alt="Young Indians" width={32} height={32} className="rounded-sm object-contain" />
          <div>
            <p className="text-sm font-bold text-foreground leading-tight">Young Indians</p>
            <p className="text-xs text-muted-foreground">Admin Panel</p>
          </div>
        </Link>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        <p className="px-2 text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">Navigation</p>
        {visibleItems.map(item => {
          const Icon = item.icon
          const isActive = pathname.startsWith(item.href)
          return (
            <Link
              key={item.href}
              href={item.href}
              prefetch={true}
              className={cn(
                'flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-foreground text-background'
                  : 'text-muted-foreground hover:bg-muted hover:text-foreground'
              )}
            >
              <Icon className="w-4 h-4 shrink-0" />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>

      {/* Footer — User + Logout */}
      <div className="border-t border-border px-3 py-4 space-y-1">
        <div className="flex items-center gap-3 px-3 py-2">
          <div className="w-8 h-8 rounded-full bg-muted border border-border flex items-center justify-center shrink-0">
            <span className="text-xs font-bold text-foreground">
              {profile.name?.charAt(0)?.toUpperCase() || 'A'}
            </span>
          </div>
          <div className="overflow-hidden flex-1 min-w-0">
            <p className="text-xs font-semibold text-foreground truncate">{profile.name || 'Admin'}</p>
            <p className="text-xs text-muted-foreground truncate capitalize">
              {profile.role.replace('_', ' ')}
            </p>
          </div>
        </div>
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-medium text-muted-foreground hover:bg-red-50 hover:text-red-600 transition-colors w-full"
        >
          <LogOut className="w-4 h-4 shrink-0" />
          <span>Logout</span>
        </button>
      </div>
    </aside>
  )
}
