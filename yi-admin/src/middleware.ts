import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  const isAuthPage = request.nextUrl.pathname.startsWith('/login')
  const isDashboard = request.nextUrl.pathname.startsWith('/') && !isAuthPage

  if (!user && isDashboard && request.nextUrl.pathname !== '/login') {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (user && isAuthPage) {
    return NextResponse.redirect(new URL('/events', request.url))
  }

  if (user && isDashboard) {
    // Single query — fetch role + permissions together (was two queries before)
    const { data: adminUser } = await supabase
      .from('admin_users')
      .select('role, permissions')
      .eq('id', user.id)
      .single()

    if (!adminUser) {
      await supabase.auth.signOut()
      return NextResponse.redirect(new URL('/login?error=unauthorized', request.url))
    }

    if (adminUser.role === 'committee') {
      const perms: string[] = adminUser.permissions || []
      const routePermMap: Record<string, string> = {
        '/members': 'members',
        '/mou': 'mou',
        '/privileges': 'privileges',
        '/admin-users': 'admin-users',
        '/organisation-emails': 'organisation-emails',
      }
      for (const [route, perm] of Object.entries(routePermMap)) {
        if (request.nextUrl.pathname.startsWith(route) && !perms.includes(perm)) {
          return NextResponse.redirect(new URL('/events', request.url))
        }
      }
    }
  }

  return supabaseResponse
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
}
