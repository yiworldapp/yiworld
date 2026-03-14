'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button, buttonVariants } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { cn } from '@/lib/utils'
import { deleteOffer } from '../_actions/offer-actions'

interface Props { id: string; name: string; table: 'online_offers' | 'offline_offers' }

export function DeleteOfferButton({ id, name, table }: Props) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleDelete() {
    setLoading(true)
    try {
      await deleteOffer(id, table)
      toast.success('Offer deleted')
      setOpen(false)
      router.refresh()
    } catch {
      toast.error('Failed to delete')
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger className={cn(buttonVariants({ variant: 'ghost', size: 'sm' }), 'h-7 text-xs px-2 text-muted-foreground hover:text-destructive hover:bg-destructive/10')}>
        <Trash2 className="w-3 h-3 mr-1" /> Delete
      </DialogTrigger>
      <DialogContent className="bg-card border-border">
        <DialogHeader>
          <DialogTitle>Delete Offer</DialogTitle>
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
