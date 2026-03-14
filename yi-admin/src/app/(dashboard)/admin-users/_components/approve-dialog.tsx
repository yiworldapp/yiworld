'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'sonner'
import type { AdminUser } from '@/types/database.types'

const ALL_PAGES = [
  { key: 'events',      label: 'Events' },
  { key: 'members',     label: 'Members' },
  { key: 'mou',         label: 'MOUs' },
  { key: 'privileges',  label: 'Privileges' },
]

export function ApproveDialog({ admin, open, onClose }: {
  admin: AdminUser
  open: boolean
  onClose: () => void
}) {
  const router = useRouter()
  const [role, setRole] = useState<'committee' | 'super_admin'>('committee')
  const [permissions, setPermissions] = useState<string[]>(['events'])
  const [loading, setLoading] = useState(false)

  function togglePerm(key: string) {
    setPermissions(prev =>
      prev.includes(key) ? prev.filter(p => p !== key) : [...prev, key]
    )
  }

  async function handleApprove() {
    setLoading(true)
    const finalPerms = role === 'super_admin'
      ? ALL_PAGES.map(p => p.key).concat(['admin-users'])
      : permissions

    const res = await fetch('/api/admin-users', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: admin.id, role, status: 'active', permissions: finalPerms }),
    })
    if (!res.ok) { toast.error('Failed to approve'); setLoading(false); return }
    toast.success(`${admin.name || admin.email} approved`)
    onClose()
    router.refresh()
    setLoading(false)
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="bg-card border-border max-w-sm">
        <DialogHeader>
          <DialogTitle>Approve Access</DialogTitle>
          <p className="text-sm text-muted-foreground">{admin.email}</p>
        </DialogHeader>

        <div className="space-y-4">
          {/* Role */}
          <div>
            <p className="text-sm font-medium mb-2">Role</p>
            <div className="flex gap-3">
              {(['committee', 'super_admin'] as const).map(r => (
                <button
                  key={r}
                  onClick={() => setRole(r)}
                  className={`px-3 py-1.5 rounded-md border text-sm font-medium transition-colors capitalize ${
                    role === r
                      ? 'bg-foreground text-background border-foreground'
                      : 'border-border text-muted-foreground hover:text-foreground'
                  }`}
                >
                  {r.replace('_', ' ')}
                </button>
              ))}
            </div>
          </div>

          {/* Page access (only for committee) */}
          {role === 'committee' && (
            <div>
              <p className="text-sm font-medium mb-2">Page Access</p>
              <div className="space-y-2">
                {ALL_PAGES.map(page => (
                  <label key={page.key} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={permissions.includes(page.key)}
                      onChange={() => togglePerm(page.key)}
                      className="w-4 h-4 rounded border-border accent-foreground"
                    />
                    <span className="text-sm">{page.label}</span>
                  </label>
                ))}
              </div>
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleApprove} disabled={loading}>
            {loading ? 'Approving...' : 'Approve'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
