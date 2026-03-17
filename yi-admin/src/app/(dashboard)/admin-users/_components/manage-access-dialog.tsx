'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'sonner'
import type { AdminUser } from '@/types/database.types'

const ALL_PAGES = [
  { key: 'events',      label: 'Events' },
  { key: 'members',     label: 'Members' },
  { key: 'mou',         label: 'MOUs' },
  { key: 'privileges',          label: 'Privileges' },
  { key: 'organisation-emails', label: 'Org Emails' },
]

export function ManageAccessDialog({ admin, open, onClose }: {
  admin: AdminUser
  open: boolean
  onClose: () => void
}) {
  const router = useRouter()
  const [permissions, setPermissions] = useState<string[]>(admin.permissions || [])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (open) setPermissions(admin.permissions || [])
  }, [open])

  function togglePerm(key: string) {
    setPermissions(prev =>
      prev.includes(key) ? prev.filter(p => p !== key) : [...prev, key]
    )
  }

  async function handleSave() {
    setLoading(true)
    const res = await fetch('/api/admin-users', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: admin.id, permissions }),
    })
    if (!res.ok) { toast.error('Failed to update'); setLoading(false); return }
    toast.success('Access updated')
    onClose()
    router.refresh()
    setLoading(false)
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="bg-card border-border max-w-sm">
        <DialogHeader>
          <DialogTitle>Manage Access</DialogTitle>
          <p className="text-sm text-muted-foreground">{admin.name || admin.email}</p>
        </DialogHeader>

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

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSave} disabled={loading}>
            {loading ? 'Saving...' : 'Save'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
