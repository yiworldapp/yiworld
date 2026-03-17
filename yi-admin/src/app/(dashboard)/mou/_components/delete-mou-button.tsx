'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { deleteMOU } from '../actions'
import { Button, buttonVariants } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { cn } from '@/lib/utils'

export function DeleteMOUButton({ mouId, mouTitle }: { mouId: string; mouTitle: string }) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleDelete() {
    setLoading(true)
    try {
      await deleteMOU(mouId)
      toast.success('MOU deleted')
      setOpen(false)
      router.refresh()
    } catch {
      toast.error('Failed to delete')
    }
    setLoading(false)
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger className={cn(buttonVariants({ variant: 'ghost', size: 'sm' }), 'h-8 text-muted-foreground hover:text-destructive hover:bg-destructive/10')}>
        <Trash2 className="w-3.5 h-3.5" />
      </DialogTrigger>
      <DialogContent className="bg-card border-border">
        <DialogHeader>
          <DialogTitle>Delete MOU</DialogTitle>
          <DialogDescription>Delete &ldquo;{mouTitle}&rdquo;? This cannot be undone.</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="destructive" onClick={handleDelete} disabled={loading}>Delete</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
