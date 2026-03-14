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
import { upsertOfflineOffer } from '../_actions/offer-actions'

const OFFLINE_CATEGORIES = ['Restaurant', 'Hotel', 'Gym', 'Hospital', 'Spa', 'Retail', 'Cafe', 'Entertainment', 'Other']

interface OfflineOffer {
  id: string; business_name: string; logo_url?: string; category: string
  address?: string; map_url?: string; city?: string; phone?: string; offer_description: string
  discount_label?: string; how_to_avail?: string; expiry_date?: string
  banner_url?: string; is_active: boolean
}

interface Props { offer?: OfflineOffer }

export function OfflineOfferForm({ offer }: Props) {
  const router = useRouter()
  const supabase = createClient()
  const isEdit = !!offer

  const [loading, setLoading] = useState(false)
  const [businessName, setBusinessName] = useState(offer?.business_name || '')
  const [category, setCategory] = useState(offer?.category || 'Other')
  const [address, setAddress] = useState(offer?.address || '')
  const [mapUrl, setMapUrl] = useState(offer?.map_url || '')
  const [city, setCity] = useState(offer?.city || '')
  const [phone, setPhone] = useState(offer?.phone || '')
  const [offerDescription, setOfferDescription] = useState(offer?.offer_description || '')
  const [discountLabel, setDiscountLabel] = useState(offer?.discount_label || '')
  const [howToAvail, setHowToAvail] = useState(offer?.how_to_avail || '')
  const [expiryDate, setExpiryDate] = useState(offer?.expiry_date || '')
  const [isActive, setIsActive] = useState(offer?.is_active ?? true)
  const [logoFile, setLogoFile] = useState<File | null>(null)
  const [bannerFile, setBannerFile] = useState<File | null>(null)

  async function uploadFile(file: File) {
    const path = `${Date.now()}-${file.name}`
    const { error } = await supabase.storage.from('offer-images').upload(path, file, { upsert: true })
    if (error) throw error
    return supabase.storage.from('offer-images').getPublicUrl(path).data.publicUrl
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!businessName || !offerDescription) { toast.error('Business name and offer description are required'); return }
    setLoading(true)

    try {
      let logoUrl = offer?.logo_url || null
      let bannerUrl = offer?.banner_url || null

      if (logoFile) logoUrl = await uploadFile(logoFile)
      if (bannerFile) bannerUrl = await uploadFile(bannerFile)

      await upsertOfflineOffer({
        id: offer?.id,
        business_name: businessName,
        category,
        address: address || null,
        map_url: mapUrl || null,
        city: city || null,
        phone: phone || null,
        offer_description: offerDescription,
        discount_label: discountLabel || null,
        how_to_avail: howToAvail || null,
        expiry_date: expiryDate || null,
        logo_url: logoUrl,
        banner_url: bannerUrl,
        is_active: isActive,
      })

      toast.success(isEdit ? 'Offer updated' : 'Offer created')
      router.push('/privileges')
      router.refresh()
    } catch (err: any) {
      toast.error(err.message || 'Something went wrong')
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* ── Main ── */}
        <div className="lg:col-span-2 space-y-6">
          <Card className="border-border">
            <CardHeader className="pb-3"><CardTitle className="text-base">Business Info</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label>Business Name *</Label>
                  <Input value={businessName} onChange={e => setBusinessName(e.target.value)} placeholder="e.g. Barbeque Nation" required />
                </div>
                <div className="space-y-1.5">
                  <Label>Category</Label>
                  <Select value={category} onValueChange={setCategory}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {OFFLINE_CATEGORIES.map(c => <SelectItem key={c} value={c}>{c}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label>City</Label>
                  <Input value={city} onChange={e => setCity(e.target.value)} placeholder="e.g. Kanpur" />
                </div>
                <div className="space-y-1.5">
                  <Label>Phone</Label>
                  <Input value={phone} onChange={e => setPhone(e.target.value)} placeholder="+91 98765 43210" />
                </div>
              </div>
              <div className="space-y-1.5">
                <Label>Address</Label>
                <Textarea value={address} onChange={e => setAddress(e.target.value)} placeholder="Full address..." rows={2} />
              </div>
              <div className="space-y-1.5">
                <Label>Map Link</Label>
                <Input value={mapUrl} onChange={e => setMapUrl(e.target.value)} placeholder="https://maps.google.com/..." type="url" />
                <p className="text-xs text-muted-foreground">Paste a Google Maps or Apple Maps link for the Directions button in the app</p>
              </div>
            </CardContent>
          </Card>

          <Card className="border-border">
            <CardHeader className="pb-3"><CardTitle className="text-base">Offer Details</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-1.5">
                <Label>Offer Description *</Label>
                <Textarea value={offerDescription} onChange={e => setOfferDescription(e.target.value)} placeholder="e.g. 15% off on food bill for YI members" rows={3} required />
              </div>
              <div className="space-y-1.5">
                <Label>Discount Label</Label>
                <Input value={discountLabel} onChange={e => setDiscountLabel(e.target.value)} placeholder="e.g. 15% OFF" />
              </div>
              <div className="space-y-1.5">
                <Label>How to Avail</Label>
                <Textarea value={howToAvail} onChange={e => setHowToAvail(e.target.value)} placeholder="e.g. Show YI membership card at billing counter" rows={3} />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* ── Sidebar ── */}
        <div className="space-y-6">
          <Card className="border-border">
            <CardHeader className="pb-3"><CardTitle className="text-base">Publishing</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="active" className="cursor-pointer">Active</Label>
                <Switch id="active" checked={isActive} onCheckedChange={setIsActive} />
              </div>
              <div className="space-y-1.5">
                <Label>Expiry Date</Label>
                <Input type="date" value={expiryDate} onChange={e => setExpiryDate(e.target.value)} />
              </div>
            </CardContent>
          </Card>

          <Card className="border-border">
            <CardHeader className="pb-3"><CardTitle className="text-base">Logo</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              {offer?.logo_url && (
                <img src={offer.logo_url} className="h-16 rounded border border-border object-contain bg-white p-2 w-full" alt="Logo" />
              )}
              <Input type="file" accept="image/*" onChange={e => setLogoFile(e.target.files?.[0] || null)} />
            </CardContent>
          </Card>

          <Card className="border-border">
            <CardHeader className="pb-3"><CardTitle className="text-base">Banner Image</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              {offer?.banner_url && (
                <img src={offer.banner_url} className="h-24 rounded border border-border object-cover w-full" alt="Banner" />
              )}
              <Input type="file" accept="image/*" onChange={e => setBannerFile(e.target.files?.[0] || null)} />
            </CardContent>
          </Card>
        </div>
      </div>

      <div className="flex gap-3 pt-2">
        <Button type="submit" disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          {isEdit ? 'Save Changes' : 'Create Offer'}
        </Button>
        <Button type="button" variant="outline" onClick={() => router.back()}>Cancel</Button>
      </div>
    </form>
  )
}
