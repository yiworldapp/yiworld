import { createClient, createAdminClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { LinkButton } from '@/components/ui/link-button'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { FileText, ExternalLink } from 'lucide-react'
import { format } from 'date-fns'
import { MOUUploadDialog } from './_components/mou-upload-dialog'
import { DeleteMOUButton } from './_components/delete-mou-button'

const MOU_TAGS = ['all', 'institute', 'school', 'organisation'] as const

export default async function MOUPage({ searchParams }: { searchParams: Promise<{ tag?: string }> }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('mou')) redirect('/events')

  const { tag } = await searchParams
  const activeTag = tag && tag !== 'all' ? tag : null

  let query = supabase.from('mous').select('*').order('created_at', { ascending: false })
  if (activeTag) query = query.eq('tag', activeTag)

  const { data: mous } = await query

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">MOUs</h1>
          <p className="text-muted-foreground text-sm mt-1">Memorandum of Understanding</p>
        </div>
        <MOUUploadDialog />
      </div>

      {/* Tag filter chips */}
      <div className="flex items-center gap-2 flex-wrap">
        {MOU_TAGS.map(t => {
          const isActive = (t === 'all' && !activeTag) || t === activeTag
          return (
            <a
              key={t}
              href={t === 'all' ? '/mou' : `/mou?tag=${t}`}
              className={[
                'px-3 py-1.5 rounded-md border text-sm font-medium transition-colors capitalize',
                isActive
                  ? 'bg-foreground text-background border-foreground'
                  : 'border-border text-muted-foreground hover:text-foreground bg-transparent',
              ].join(' ')}
            >
              {t}
            </a>
          )
        })}
      </div>

      <div className="rounded-lg border border-border overflow-hidden">
        <Table>
          <TableHeader className="bg-muted/40">
            <TableRow className="hover:bg-transparent border-border">
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide">Name</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden md:table-cell">Description</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden sm:table-cell">Tag</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide hidden sm:table-cell">Uploaded</TableHead>
              <TableHead className="px-4 py-3 text-muted-foreground font-semibold text-xs uppercase tracking-wide text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {!mous?.length ? (
              <TableRow>
                <TableCell colSpan={5} className="py-16 text-center text-muted-foreground">
                  <FileText className="w-10 h-10 mx-auto mb-3 opacity-30" />
                  No MOUs found
                </TableCell>
              </TableRow>
            ) : mous.map((mou) => (
              <TableRow key={mou.id} className="border-border">
                <TableCell className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded bg-muted border border-border flex items-center justify-center shrink-0">
                      <FileText className="w-3.5 h-3.5 text-muted-foreground" />
                    </div>
                    <span className="font-medium text-foreground">{mou.title}</span>
                  </div>
                </TableCell>
                <TableCell className="px-4 py-3 text-muted-foreground hidden md:table-cell text-sm max-w-[240px]">
                  <p className="line-clamp-2">{mou.description || '—'}</p>
                </TableCell>
                <TableCell className="px-4 py-3 hidden sm:table-cell">
                  <Badge variant="secondary" className="capitalize text-xs">{mou.tag}</Badge>
                </TableCell>
                <TableCell className="px-4 py-3 text-muted-foreground hidden sm:table-cell text-sm">
                  {format(new Date(mou.created_at), 'd MMM yyyy')}
                </TableCell>
                <TableCell className="px-4 py-3 text-right">
                  <div className="flex items-center justify-end gap-1">
                    <LinkButton href={mou.pdf_url} variant="ghost" size="sm" className="h-8 w-8 p-0 text-muted-foreground hover:text-foreground" target="_blank" rel="noopener noreferrer">
                      <ExternalLink className="w-3.5 h-3.5" />
                    </LinkButton>
                    <DeleteMOUButton mouId={mou.id} mouTitle={mou.title} />
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  )
}
