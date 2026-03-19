import { format } from 'date-fns'
import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { LinkButton } from '@/components/ui/link-button'
import { Badge } from '@/components/ui/badge'
import { Plus, Globe, MapPin, Wifi, Store } from 'lucide-react'
import { DeleteOfferButton } from './_components/delete-offer-button'

export default async function PrivilegesPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('privileges')) redirect('/events')

  const [{ data: onlineOffers }, { data: offlineOffers }] = await Promise.all([
    supabase.from('online_offers').select('*').order('created_at', { ascending: false }),
    supabase.from('offline_offers').select('*').order('created_at', { ascending: false }),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Privileges</h1>
        <p className="text-muted-foreground text-sm mt-1">Exclusive offers for YI members</p>
      </div>

      <Tabs defaultValue="online">
        <div className="flex items-center justify-between gap-4">
          <TabsList className="bg-transparent border-0 p-0 gap-2 h-auto">
            <TabsTrigger
              value="online"
              className="px-3 py-1.5 rounded-md border text-sm font-medium transition-colors gap-1.5 h-auto
                data-[state=active]:bg-foreground data-[state=active]:text-background data-[state=active]:border-foreground
                data-[state=inactive]:border-border data-[state=inactive]:text-muted-foreground data-[state=inactive]:hover:text-foreground data-[state=inactive]:bg-transparent"
            >
              <Wifi className="w-3.5 h-3.5" /> Online ({onlineOffers?.length || 0})
            </TabsTrigger>
            <TabsTrigger
              value="offline"
              className="px-3 py-1.5 rounded-md border text-sm font-medium transition-colors gap-1.5 h-auto
                data-[state=active]:bg-foreground data-[state=active]:text-background data-[state=active]:border-foreground
                data-[state=inactive]:border-border data-[state=inactive]:text-muted-foreground data-[state=inactive]:hover:text-foreground data-[state=inactive]:bg-transparent"
            >
              <Store className="w-3.5 h-3.5" /> Offline ({offlineOffers?.length || 0})
            </TabsTrigger>
          </TabsList>
          <div className="flex gap-2">
            <LinkButton href="/privileges/online/new" size="sm">
              <Plus className="mr-1.5 h-3.5 w-3.5" /> Add Online Offer
            </LinkButton>
            <LinkButton href="/privileges/offline/new" size="sm" variant="outline">
              <Plus className="mr-1.5 h-3.5 w-3.5" /> Add Offline Offer
            </LinkButton>
          </div>
        </div>

        {/* Online Offers */}
        <TabsContent value="online" className="mt-6 space-y-4">
          <div className="rounded-lg border border-border overflow-hidden">
            <Table>
              <TableHeader className="bg-muted/40">
                <TableRow className="hover:bg-transparent border-border">
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Brand</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden md:table-cell">Category</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Discount</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Coupon</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden md:table-cell">Expires</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Status</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {!onlineOffers?.length ? (
                  <TableRow>
                    <TableCell colSpan={7} className="py-16 text-center text-muted-foreground">
                      <Globe className="w-10 h-10 mx-auto mb-3 opacity-30" />
                      No online offers yet
                    </TableCell>
                  </TableRow>
                ) : onlineOffers.map((offer) => (
                  <TableRow key={offer.id} className="border-border">
                    <TableCell className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        {offer.logo_url ? (
                          <img src={offer.logo_url} alt={offer.brand_name} className="w-8 h-8 rounded object-contain bg-white p-1 border border-border shrink-0" />
                        ) : (
                          <div className="w-8 h-8 rounded bg-primary/10 border border-primary/20 flex items-center justify-center shrink-0 text-primary font-bold text-xs">
                            {offer.brand_name[0]}
                          </div>
                        )}
                        <div>
                          <p className="font-medium text-foreground">{offer.brand_name}</p>
                          <p className="text-xs text-muted-foreground line-clamp-1 max-w-[160px]">{offer.title}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="px-4 py-3 text-muted-foreground hidden md:table-cell text-sm">{offer.category}</TableCell>
                    <TableCell className="px-4 py-3 hidden lg:table-cell text-sm">
                      {offer.discount_label
                        ? <span className="text-primary font-semibold">{offer.discount_label}</span>
                        : <span className="text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell className="px-4 py-3 hidden lg:table-cell">
                      {offer.coupon_code
                        ? <code className="text-xs bg-muted px-2 py-0.5 rounded font-mono border border-border">{offer.coupon_code}</code>
                        : <span className="text-muted-foreground text-sm">—</span>}
                    </TableCell>
                    <TableCell className="px-4 py-3 text-muted-foreground hidden md:table-cell text-sm">
                      {offer.expiry_date ? format(new Date(offer.expiry_date), 'dd/MM/yyyy') : '—'}
                    </TableCell>
                    <TableCell className="px-4 py-3">
                      <Badge variant={offer.is_active ? 'default' : 'secondary'} className="text-xs font-medium">
                        {offer.is_active ? 'Active' : 'Inactive'}
                      </Badge>
                    </TableCell>
                    <TableCell className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <LinkButton href={`/privileges/online/${offer.id}/edit`} variant="ghost" size="sm" className="h-8 w-8 p-0 text-muted-foreground hover:text-foreground">
                          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
                        </LinkButton>
                        <DeleteOfferButton id={offer.id} name={offer.brand_name} table="online_offers" />
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </TabsContent>

        {/* Offline Offers */}
        <TabsContent value="offline" className="mt-6 space-y-4">
          <div className="rounded-lg border border-border overflow-hidden">
            <Table>
              <TableHeader className="bg-muted/40">
                <TableRow className="hover:bg-transparent border-border">
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Business</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden md:table-cell">Category</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">City</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden lg:table-cell">Discount</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden md:table-cell">Expires</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Status</TableHead>
                  <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {!offlineOffers?.length ? (
                  <TableRow>
                    <TableCell colSpan={7} className="py-16 text-center text-muted-foreground">
                      <MapPin className="w-10 h-10 mx-auto mb-3 opacity-30" />
                      No offline offers yet
                    </TableCell>
                  </TableRow>
                ) : offlineOffers.map((offer) => (
                  <TableRow key={offer.id} className="border-border">
                    <TableCell className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        {offer.logo_url ? (
                          <img src={offer.logo_url} alt={offer.business_name} className="w-8 h-8 rounded object-contain bg-white p-1 border border-border shrink-0" />
                        ) : (
                          <div className="w-8 h-8 rounded bg-orange-500/10 border border-orange-200 flex items-center justify-center shrink-0 text-orange-600 font-bold text-xs">
                            {offer.business_name[0]}
                          </div>
                        )}
                        <div>
                          <p className="font-medium text-foreground">{offer.business_name}</p>
                          <p className="text-xs text-muted-foreground line-clamp-1 max-w-[160px]">{offer.offer_description}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="px-4 py-3 text-muted-foreground hidden md:table-cell text-sm">{offer.category}</TableCell>
                    <TableCell className="px-4 py-3 text-muted-foreground hidden lg:table-cell text-sm">
                      <div className="flex items-center gap-1.5">
                        <MapPin className="w-3 h-3 shrink-0" />
                        {offer.city || '—'}
                      </div>
                    </TableCell>
                    <TableCell className="px-4 py-3 hidden lg:table-cell text-sm">
                      {offer.discount_label
                        ? <span className="text-orange-600 font-semibold">{offer.discount_label}</span>
                        : <span className="text-muted-foreground">—</span>}
                    </TableCell>
                    <TableCell className="px-4 py-3 text-muted-foreground hidden md:table-cell text-sm">
                      {offer.expiry_date ? format(new Date(offer.expiry_date), 'dd/MM/yyyy') : '—'}
                    </TableCell>
                    <TableCell className="px-4 py-3">
                      <Badge variant={offer.is_active ? 'default' : 'secondary'} className="text-xs font-medium">
                        {offer.is_active ? 'Active' : 'Inactive'}
                      </Badge>
                    </TableCell>
                    <TableCell className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <LinkButton href={`/privileges/offline/${offer.id}/edit`} variant="ghost" size="sm" className="h-8 w-8 p-0 text-muted-foreground hover:text-foreground">
                          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
                        </LinkButton>
                        <DeleteOfferButton id={offer.id} name={offer.business_name} table="offline_offers" />
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
