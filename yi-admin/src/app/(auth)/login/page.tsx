'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { toast } from 'sonner'
import { Loader2, Shield } from 'lucide-react'

export default function LoginPage() {
  const router = useRouter()
  const supabase = createClient()
  const [mode, setMode] = useState<'login' | 'signup'>('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) { setError(error.message); setLoading(false); return }

    if (data.user) {
      const { data: adminUser } = await supabase
        .from('admin_users')
        .select('role, status')
        .eq('id', data.user.id)
        .single()

      if (!adminUser) {
        await supabase.auth.signOut()
        setError('Access denied. This dashboard is for admins and committee members only.')
        setLoading(false)
        return
      }

      if (adminUser.status !== 'active') {
        await supabase.auth.signOut()
        setError('Your account is pending approval. Please wait for a super admin to approve your access.')
        setLoading(false)
        return
      }

      toast.success('Welcome back!')
      router.push('/events')
      router.refresh()
    }
  }

  async function handleSignup(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    const { data, error } = await supabase.auth.signUp({ email, password })
    if (error) { setError(error.message); setLoading(false); return }

    if (data.user) {
      await fetch('/api/request-access', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: data.user.id, email, name: email.split('@')[0] }),
      })
      toast.success('Account created! A super admin will review and approve your access.')
      setMode('login')
      setPassword('')
    }
    setLoading(false)
  }

  const isLogin = mode === 'login'

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-primary/10 via-background to-background" />

      <Card className="relative w-full max-w-md border-border/60 bg-card/80 backdrop-blur-sm shadow-2xl">
        <CardHeader className="text-center space-y-4 pb-6">
          <div className="mx-auto w-16 h-16 rounded-2xl bg-primary/10 border border-primary/30 flex items-center justify-center">
            <Shield className="w-8 h-8 text-primary" />
          </div>
          <div>
            <CardTitle className="text-2xl font-bold tracking-tight">YI Admin</CardTitle>
            <CardDescription className="text-muted-foreground mt-1">
              {isLogin ? 'Young Indians Dashboard' : 'Create your dashboard account'}
            </CardDescription>
          </div>
        </CardHeader>

        <CardContent>
          <form onSubmit={isLogin ? handleLogin : handleSignup} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" placeholder="you@youngindians.com"
                value={email} onChange={e => setEmail(e.target.value)} required
                className="bg-input border-border" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" placeholder="••••••••"
                value={password} onChange={e => setPassword(e.target.value)}
                required minLength={6} className="bg-input border-border" />
            </div>

            {!isLogin && (
              <p className="text-xs text-muted-foreground bg-muted/50 rounded-lg px-3 py-2">
                After signup, a super admin must approve your account before you can access the dashboard.
              </p>
            )}

            {error && (
              <div className="rounded-lg bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
                {error}
              </div>
            )}

            <Button type="submit" className="w-full bg-primary font-semibold" disabled={loading}>
              {loading
                ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" />{isLogin ? 'Signing in...' : 'Creating account...'}</>
                : isLogin ? 'Sign In' : 'Create Account'
              }
            </Button>
          </form>

          <div className="mt-4 text-center text-sm text-muted-foreground">
            {isLogin ? (
              <>Don&apos;t have an account?{' '}
                <button onClick={() => { setMode('signup'); setError('') }}
                  className="text-primary hover:underline font-medium">Sign up</button>
              </>
            ) : (
              <>Already have an account?{' '}
                <button onClick={() => { setMode('login'); setError('') }}
                  className="text-primary hover:underline font-medium">Sign in</button>
              </>
            )}
          </div>

          <div className="mt-4 flex items-center gap-2 text-xs text-muted-foreground">
            <div className="flex-1 h-px bg-border" />
            <span>Admin & Committee Access Only</span>
            <div className="flex-1 h-px bg-border" />
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
