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
import { upsertOnlineOffer } from '../_actions/offer-actions'

const ONLINE_CATEGORIES = ['Fashion', 'Food & Beverage', 'Travel', 'Health & Wellness', 'Tech', 'Education', 'Entertainment', 'Finance', 'Other']

interface OnlineOffer {
  id: string; brand_name: string; logo_url?: string; category: string; website_url?: string
  title: string; discount_label?: string; coupon_code?: string; about_offer?: string
  how_to_claim?: string; terms_and_conditions?: string; expiry_date?: string
  banner_url?: string; is_active: boolean
}

interface Props { offer?: OnlineOffer }

export function OnlineOfferForm({ offer }: Props) {
  const router = useRouter()
  const supabase = createClient()
  const isEdit = !!offer

  const [loading, setLoading] = useState(false)
  const [brandName, setBrandName] = useState(offer?.brand_name || '')
  const [category, setCategory] = useState(offer?.category || 'Other')
  const [websiteUrl, setWebsiteUrl] = useState(offer?.website_url || '')
  const [title, setTitle] = useState(offer?.title || '')
  const [discountLabel, setDiscountLabel] = useState(offer?.discount_label || '')
  const [couponCode, setCouponCode] = useState(offer?.coupon_code || '')
  const [aboutOffer, setAboutOffer] = useState(offer?.about_offer || '')
  const [howToClaim, setHowToClaim] = useState(offer?.how_to_claim || '')
  const [termsAndConditions, setTermsAndConditions] = useState(offer?.terms_and_conditions || '')
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
    if (!brandName || !title) { toast.error('Brand name and title are required'); return }
    setLoading(true)

    try {
      let logoUrl = offer?.logo_url || null
      let bannerUrl = offer?.banner_url || null
      if (logoFile) logoUrl = await uploadFile(logoFile)
      if (bannerFile) bannerUrl = await uploadFile(bannerFile)

      await upsertOnlineOffer({
        id: offer?.id, brand_name: brandName, category,
        website_url: websiteUrl || null, title,
        discount_label: discountLabel || null, coupon_code: couponCode || null,
        about_offer: aboutOffer || null, how_to_claim: howToClaim || null,
        terms_and_conditions: termsAndConditions || null, expiry_date: expiryDate || null,
        logo_url: logoUrl, banner_url: bannerUrl, is_active: isActive,
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
            <CardHeader className="pb-3"><CardTitle className="text-base">Brand Info</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label>Brand Name *</Label>
                  <Input value={brandName} onChange={e => setBrandName(e.target.value)} placeholder="e.g. Myntra" required />
                </div>
                <div className="space-y-1.5">
                  <Label>Category</Label>
                  <Select value={category} onValueChange={(v) => v && setCategory(v)}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent>
                      {ONLINE_CATEGORIES.map(c => <SelectItem key={c} value={c}>{c}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="space-y-1.5">
                <Label>Website URL</Label>
                <Input value={websiteUrl} onChange={e => setWebsiteUrl(e.target.value)} placeholder="https://..." type="url" />
              </div>
            </CardContent>
          </Card>

          <Card className="border-border">
            <CardHeader className="pb-3"><CardTitle className="text-base">Offer Details</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-1.5">
                <Label>Offer Title *</Label>
                <Input value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g. 20% off on all orders" required />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label>Discount Label</Label>
                  <Input value={discountLabel} onChange={e => setDiscountLabel(e.target.value)} placeholder="e.g. 20% OFF" />
                </div>
                <div className="space-y-1.5">
                  <Label>Coupon Code</Label>
                  <Input value={couponCode} onChange={e => setCouponCode(e.target.value)} placeholder="e.g. YI20" className="font-mono" />
                </div>
              </div>
              <div className="space-y-1.5">
                <Label>About this Offer</Label>
                <Textarea value={aboutOffer} onChange={e => setAboutOffer(e.target.value)} placeholder="Describe what the offer includes..." rows={3} />
              </div>
              <div className="space-y-1.5">
                <Label>How to Claim</Label>
                <Textarea value={howToClaim} onChange={e => setHowToClaim(e.target.value)} placeholder="Step-by-step instructions..." rows={3} />
              </div>
              <div className="space-y-1.5">
                <Label>Terms &amp; Conditions</Label>
                <Textarea value={termsAndConditions} onChange={e => setTermsAndConditions(e.target.value)} placeholder="e.g. Valid for YI members only." rows={3} />
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
