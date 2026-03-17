'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { upsertPartner } from '../../actions'
import { uploadToStorage } from '../../../upload-actions'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import type { Partner } from '@/types/database.types'

export function PartnerForm({ partner }: { partner?: Partner }) {
  const router = useRouter()
  const isEdit = !!partner

  const [loading, setLoading] = useState(false)
  const [name, setName] = useState(partner?.name || '')
  const [description, setDescription] = useState(partner?.description || '')
  const [category, setCategory] = useState(partner?.category || '')
  const [websiteUrl, setWebsiteUrl] = useState(partner?.website_url || '')
  const [isActive, setIsActive] = useState(partner?.is_active ?? true)
  const [logoFile, setLogoFile] = useState<File | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!name) { toast.error('Name is required'); return }
    setLoading(true)

    try {
      let logoUrl = partner?.logo_url || null
      if (logoFile) {
        const fd = new FormData()
        fd.append('file', logoFile)
        fd.append('bucket', 'partner-logos')
        fd.append('path', `partner-logos/${Date.now()}-${logoFile.name}`)
        logoUrl = await uploadToStorage(fd)
      }

      const data = {
        name, description: description || null,
        category: category || null, website_url: websiteUrl || null,
        logo_url: logoUrl, is_active: isActive,
      }

      await upsertPartner(data, isEdit ? partner!.id : undefined)

      toast.success(isEdit ? 'Partner updated!' : 'Partner added!')
      router.push('/privileges')
    } catch (err: any) {
      toast.error(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-xl">
      <Card className="border-border bg-card/80">
        <CardHeader><CardTitle className="text-base">Partner Details</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>Name *</Label>
            <Input value={name} onChange={e => setName(e.target.value)} required className="bg-input" placeholder="Acme Corp" />
          </div>
          <div className="space-y-2">
            <Label>Category</Label>
            <Input value={category} onChange={e => setCategory(e.target.value)} className="bg-input" placeholder="Healthcare, Travel, F&B..." />
          </div>
          <div className="space-y-2">
            <Label>Description</Label>
            <Textarea value={description} onChange={e => setDescription(e.target.value)} rows={3} className="bg-input resize-none" />
          </div>
          <div className="space-y-2">
            <Label>Website URL</Label>
            <Input value={websiteUrl} onChange={e => setWebsiteUrl(e.target.value)} className="bg-input" placeholder="https://..." />
          </div>
          <div className="space-y-2">
            <Label>Logo</Label>
            {partner?.logo_url && !logoFile && (
              <img src={partner.logo_url} alt="Logo" className="w-16 h-16 rounded-lg object-contain bg-white p-1 mb-2" />
            )}
            <Input type="file" accept="image/*" onChange={e => setLogoFile(e.target.files?.[0] || null)} className="bg-input" />
          </div>
          <div className="flex items-center justify-between">
            <Label htmlFor="active">Active</Label>
            <Switch id="active" checked={isActive} onCheckedChange={setIsActive} />
          </div>
        </CardContent>
      </Card>
      <div className="flex gap-3">
        <Button type="submit" className="bg-primary hover:bg-primary/90" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          {isEdit ? 'Save Changes' : 'Add Partner'}
        </Button>
        <Button type="button" variant="outline" onClick={() => router.back()} className="border-border">Cancel</Button>
      </div>
    </form>
  )
}
