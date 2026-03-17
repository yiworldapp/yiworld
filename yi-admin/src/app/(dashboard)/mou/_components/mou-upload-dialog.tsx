'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { insertMOU } from '../actions'
import { uploadToStorage } from '../../upload-actions'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from '@/components/ui/dialog'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Plus, Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import { cn } from '@/lib/utils'

const MOU_TAGS = ['institute', 'school', 'organisation'] as const

export function MOUUploadDialog() {
  const router = useRouter()
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [tag, setTag] = useState<string>('organisation')
  const [file, setFile] = useState<File | null>(null)

  function reset() {
    setName('')
    setDescription('')
    setTag('organisation')
    setFile(null)
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!file) { toast.error('Please select a PDF file'); return }
    if (!name.trim()) { toast.error('Name is required'); return }
    setLoading(true)

    try {
      const fd = new FormData()
      fd.append('file', file)
      fd.append('bucket', 'mou-pdfs')
      fd.append('path', `mous/${Date.now()}-${file.name}`)
      const publicUrl = await uploadToStorage(fd)

      await insertMOU({
        title: name.trim(),
        description: description.trim() || null,
        tag,
        pdf_url: publicUrl,
      })

      toast.success('MOU added successfully')
      setOpen(false)
      reset()
      router.refresh()
    } catch (err: any) {
      toast.error(err.message || 'Upload failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { setOpen(v); if (!v) reset() }}>
      <DialogTrigger className={cn(buttonVariants({ variant: 'default' }))}>
        <Plus className="mr-2 h-4 w-4" /> Add MOU
      </DialogTrigger>
      <DialogContent className="bg-card border-border max-w-md">
        <DialogHeader>
          <DialogTitle>Add MOU</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <Label>Name *</Label>
            <Input
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="e.g. IIT Kanpur MOU"
              required
            />
          </div>
          <div className="space-y-1.5">
            <Label>Description</Label>
            <Textarea
              value={description}
              onChange={e => setDescription(e.target.value)}
              placeholder="Brief description of this MOU..."
              rows={3}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Tag *</Label>
            <Select value={tag} onValueChange={(v) => v && setTag(v)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {MOU_TAGS.map(t => (
                  <SelectItem key={t} value={t} className="capitalize">{t}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label>PDF Attachment *</Label>
            <Input
              type="file"
              accept="application/pdf"
              onChange={e => setFile(e.target.files?.[0] || null)}
              required
            />
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
            <Button type="submit" disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Upload
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
