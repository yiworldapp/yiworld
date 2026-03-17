'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { deletePrivilege } from '../actions'
import { Button, buttonVariants } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { cn } from '@/lib/utils'

interface Props { id: string; name: string; type: 'partner' | 'offer' }

export function DeletePrivilegeButton({ id, name, type }: Props) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleDelete() {
    setLoading(true)
    try {
      await deletePrivilege(id, type)
      toast.success(`${type === 'partner' ? 'Partner' : 'Offer'} deleted`)
      setOpen(false)
      router.refresh()
    } catch {
      toast.error('Failed to delete')
    }
    setLoading(false)
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger className={cn(buttonVariants({ variant: 'ghost', size: 'sm' }), 'h-7 text-xs px-2 text-muted-foreground hover:text-destructive hover:bg-destructive/10')}>
        <Trash2 className="w-3 h-3 mr-1" /> Delete
      </DialogTrigger>
      <DialogContent className="bg-card border-border">
        <DialogHeader>
          <DialogTitle>Delete {type === 'partner' ? 'Partner' : 'Offer'}</DialogTitle>
          <DialogDescription>Delete &ldquo;{name}&rdquo;? This cannot be undone.</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="destructive" onClick={handleDelete} disabled={loading}>Delete</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
