'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import type { Offer, Partner } from '@/types/database.types'

interface OfferFormProps {
  offer?: Offer
  partners: Partner[]
}

export function OfferForm({ offer, partners }: OfferFormProps) {
  const router = useRouter()
  const supabase = createClient()
  const isEdit = !!offer

  const [loading, setLoading] = useState(false)
  const [partnerId, setPartnerId] = useState(offer?.partner_id || '')
  const [title, setTitle] = useState(offer?.title || '')
  const [description, setDescription] = useState(offer?.description || '')
  const [offerType, setOfferType] = useState(offer?.offer_type || 'discount')
  const [discountValue, setDiscountValue] = useState(offer?.discount_value || '')
  const [couponCode, setCouponCode] = useState(offer?.coupon_code || '')
  const [howToClaim, setHowToClaim] = useState(offer?.how_to_claim || '')
  const [terms, setTerms] = useState(offer?.terms || '')
  const [validFrom, setValidFrom] = useState(offer?.valid_from || '')
  const [validUntil, setValidUntil] = useState(offer?.valid_until || '')
  const [isActive, setIsActive] = useState(offer?.is_active ?? true)
  const [imageFile, setImageFile] = useState<File | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title || !partnerId) { toast.error('Partner and title are required'); return }
    setLoading(true)

    try {
      let imageUrl = offer?.image_url || null
      if (imageFile) {
        const path = `offer-images/${Date.now()}-${imageFile.name}`
        const { error: uploadError } = await supabase.storage.from('offer-images').upload(path, imageFile, { upsert: true })
        if (uploadError) throw uploadError
        imageUrl = supabase.storage.from('offer-images').getPublicUrl(path).data.publicUrl
      }

      const data = {
        partner_id: partnerId, title,
        description: description || null, offer_type: offerType as any,
        discount_value: discountValue || null, coupon_code: couponCode || null,
        image_url: imageUrl, how_to_claim: howToClaim || null,
        terms: terms || null, valid_from: validFrom || null,
        valid_until: validUntil || null, is_active: isActive,
      }

      if (isEdit) {
        const { error } = await supabase.from('offers').update(data).eq('id', offer!.id)
        if (error) throw error
      } else {
        const { error } = await supabase.from('offers').insert(data)
        if (error) throw error
      }

      toast.success(isEdit ? 'Offer updated!' : 'Offer created!')
      router.push('/privileges')
      router.refresh()
    } catch (err: any) {
      toast.error(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-xl">
      <Card className="border-border bg-card/80">
        <CardHeader><CardTitle className="text-base">Offer Details</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>Partner *</Label>
            <Select value={partnerId} onValueChange={(v) => setPartnerId(v ?? '')} required>
              <SelectTrigger className="bg-input"><SelectValue placeholder="Select partner..." /></SelectTrigger>
              <SelectContent className="bg-card border-border">
                {partners.map(p => <SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>Title *</Label>
            <Input value={title} onChange={e => setTitle(e.target.value)} required className="bg-input" placeholder="20% off on all services" />
          </div>
          <div className="space-y-2">
            <Label>Offer Type</Label>
            <Select value={offerType} onValueChange={(v) => setOfferType((v || 'discount') as 'discount' | 'freebie' | 'cashback' | 'exclusive')}>
              <SelectTrigger className="bg-input"><SelectValue /></SelectTrigger>
              <SelectContent className="bg-card border-border">
                <SelectItem value="discount">Discount</SelectItem>
                <SelectItem value="freebie">Freebie</SelectItem>
                <SelectItem value="cashback">Cashback</SelectItem>
                <SelectItem value="exclusive">Exclusive</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Discount Value</Label>
              <Input value={discountValue} onChange={e => setDiscountValue(e.target.value)} className="bg-input" placeholder="20%, ₹500, etc." />
            </div>
            <div className="space-y-2">
              <Label>Coupon Code</Label>
              <Input value={couponCode} onChange={e => setCouponCode(e.target.value)} className="bg-input font-mono" placeholder="YI2025" />
            </div>
          </div>
          <div className="space-y-2">
            <Label>Description</Label>
            <Textarea value={description} onChange={e => setDescription(e.target.value)} rows={3} className="bg-input resize-none" />
          </div>
          <div className="space-y-2">
            <Label>How to Claim</Label>
            <Textarea value={howToClaim} onChange={e => setHowToClaim(e.target.value)} rows={2} className="bg-input resize-none" placeholder="Show YI membership card at checkout..." />
          </div>
          <div className="space-y-2">
            <Label>Terms & Conditions</Label>
            <Textarea value={terms} onChange={e => setTerms(e.target.value)} rows={2} className="bg-input resize-none" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Valid From</Label>
              <Input type="date" value={validFrom} onChange={e => setValidFrom(e.target.value)} className="bg-input" />
            </div>
            <div className="space-y-2">
              <Label>Valid Until</Label>
              <Input type="date" value={validUntil} onChange={e => setValidUntil(e.target.value)} className="bg-input" />
            </div>
          </div>
          <div className="space-y-2">
            <Label>Offer Image</Label>
            {offer?.image_url && !imageFile && (
              <img src={offer.image_url} alt="Offer" className="w-full h-32 object-cover rounded-lg mb-2" />
            )}
            <Input type="file" accept="image/*" onChange={e => setImageFile(e.target.files?.[0] || null)} className="bg-input" />
          </div>
          <div className="flex items-center justify-between">
            <Label>Active</Label>
            <Switch checked={isActive} onCheckedChange={setIsActive} />
          </div>
        </CardContent>
      </Card>
      <div className="flex gap-3">
        <Button type="submit" className="bg-primary hover:bg-primary/90" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          {isEdit ? 'Save Changes' : 'Create Offer'}
        </Button>
        <Button type="button" variant="outline" onClick={() => router.back()} className="border-border">Cancel</Button>
      </div>
    </form>
  )
}
