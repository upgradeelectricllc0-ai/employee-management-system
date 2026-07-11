import { NextResponse, type NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

const PUBLIC_ROUTES = ['/', '/login', '/setup', '/forgot-password', '/reset-password']
const ADMIN_PREFIX = '/admin'
const EMPLOYEE_PREFIX = '/employee'

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const { supabaseResponse, user } = await updateSession(request)

  // Allow public routes
  if (PUBLIC_ROUTES.some((route) => pathname === route || pathname.startsWith(`${route}/`))) {
    // Redirect authenticated users away from login/setup
    if (user && (pathname === '/login' || pathname === '/')) {
      const profile = await getProfile(request, user.id)
      const redirectPath = profile?.role === 'admin' ? '/admin/dashboard' : '/employee/dashboard'
      return NextResponse.redirect(new URL(redirectPath, request.url))
    }
    return supabaseResponse
  }

  // Unauthenticated — redirect to login
  if (!user) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Role-based route protection
  if (pathname.startsWith(ADMIN_PREFIX) || pathname.startsWith(EMPLOYEE_PREFIX)) {
    const profile = await getProfile(request, user.id)
    if (!profile) return NextResponse.redirect(new URL('/login', request.url))

    if (pathname.startsWith(ADMIN_PREFIX) && profile.role !== 'admin') {
      return NextResponse.redirect(new URL('/employee/dashboard', request.url))
    }
    if (pathname.startsWith(EMPLOYEE_PREFIX) && profile.role !== 'employee') {
      return NextResponse.redirect(new URL('/admin/dashboard', request.url))
    }
  }

  return supabaseResponse
}

async function getProfile(request: NextRequest, userId: string) {
  const { createServerClient } = await import('@supabase/ssr')
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: () => {},
      },
    }
  )
  const { data } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', userId)
    .single()
  return data
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
}
