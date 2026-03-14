'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { ChevronRight } from 'lucide-react'

const routeLabels: Record<string, string> = {
  events: 'Events',
  members: 'Members',
  mou: 'MOUs',
  privileges: 'Privileges',
  partners: 'Partners',
  offers: 'Offers',
  online: 'Online',
  offline: 'Offline',
  new: 'New',
  edit: 'Edit',
}

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function Breadcrumbs() {
  const pathname = usePathname()
  // Filter out UUID segments — they add no readable value
  const allSegments = pathname.split('/').filter(Boolean)
  const segments = allSegments.filter(s => !uuidPattern.test(s))

  // Build hrefs by mapping back to full path positions
  const segmentHrefs = segments.map((seg) => {
    const idx = allSegments.indexOf(seg)
    return '/' + allSegments.slice(0, idx + 1).join('/')
  })

  return (
    <nav className="flex items-center gap-1 text-sm text-muted-foreground">
      {segments.map((segment, i) => {
        const href = segmentHrefs[i]
        const isLast = i === segments.length - 1
        const label = routeLabels[segment] || segment

        return (
          <span key={href} className="flex items-center gap-1">
            {i > 0 && <ChevronRight className="w-3.5 h-3.5" />}
            {isLast ? (
              <span className="text-foreground font-medium capitalize">{label}</span>
            ) : (
              <Link href={href} className="hover:text-foreground transition-colors capitalize">
                {label}
              </Link>
            )}
          </span>
        )
      })}
    </nav>
  )
}
