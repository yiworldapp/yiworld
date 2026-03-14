'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'

import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { MoreHorizontal, Settings, Trash2, CheckCircle } from 'lucide-react'
import { toast } from 'sonner'
import { ApproveDialog } from './approve-dialog'
import { ManageAccessDialog } from './manage-access-dialog'
import type { AdminUser } from '@/types/database.types'

export function AdminUserActions({ admin, currentUserId }: { admin: AdminUser; currentUserId: string }) {
  const router = useRouter()
  const [approveOpen, setApproveOpen] = useState(false)
  const [manageOpen, setManageOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const isSelf = admin.id === currentUserId

  if (isSelf) return null

  async function handleDelete() {
    setLoading(true)
    const res = await fetch('/api/admin-users', {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: admin.id }),
    })
    if (!res.ok) { toast.error('Failed to delete'); setLoading(false); return }
    toast.success('Admin user removed')
    setDeleteOpen(false)
    router.refresh()
    setLoading(false)
  }

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger className="inline-flex items-center justify-center h-8 w-8 rounded-md text-muted-foreground hover:bg-muted hover:text-foreground transition-colors">
          <MoreHorizontal className="w-4 h-4" />
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="bg-card border-border w-44">
          {admin.status === 'pending' && (
            <DropdownMenuItem onClick={() => setApproveOpen(true)}>
              <CheckCircle className="mr-2 h-4 w-4 text-green-600" />
              Approve
            </DropdownMenuItem>
          )}
          {admin.status === 'active' && admin.role === 'committee' && (
            <DropdownMenuItem onClick={() => setManageOpen(true)}>
              <Settings className="mr-2 h-4 w-4" />
              Manage Access
            </DropdownMenuItem>
          )}
          <DropdownMenuItem
            onClick={() => setDeleteOpen(true)}
            className="text-destructive focus:text-destructive focus:bg-destructive/10"
          >
            <Trash2 className="mr-2 h-4 w-4" />
            Remove
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      <ApproveDialog admin={admin} open={approveOpen} onClose={() => setApproveOpen(false)} />
      <ManageAccessDialog admin={admin} open={manageOpen} onClose={() => setManageOpen(false)} />

      <Dialog open={deleteOpen} onOpenChange={setDeleteOpen}>
        <DialogContent className="bg-card border-border">
          <DialogHeader>
            <DialogTitle>Remove Admin User</DialogTitle>
            <DialogDescription>
              Remove <strong>{admin.name || admin.email}</strong> from dashboard access? This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteOpen(false)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete} disabled={loading}>
              {loading ? 'Removing...' : 'Remove'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
