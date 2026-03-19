'use client'

import { format } from 'date-fns'
import { useState, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { Trash2, Plus, Upload, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'

type OrgEmail = { id: string; email: string; created_at: string }

export function OrgEmailsClient({ initialEmails }: { initialEmails: OrgEmail[] }) {
  const router = useRouter()
  const [emails, setEmails] = useState<OrgEmail[]>(initialEmails)
  const [search, setSearch] = useState('')

  // Manual add
  const [addOpen, setAddOpen] = useState(false)
  const [newEmail, setNewEmail] = useState('')
  const [addLoading, setAddLoading] = useState(false)

  // CSV upload
  const [csvOpen, setCsvOpen] = useState(false)
  const [csvFile, setCsvFile] = useState<File | null>(null)
  const [csvPreview, setCsvPreview] = useState<string[]>([])
  const [csvLoading, setCsvLoading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Delete
  const [deletingId, setDeletingId] = useState<string | null>(null)

  const filtered = emails.filter(e =>
    e.email.toLowerCase().includes(search.toLowerCase())
  )

  // ── Manual Add ──────────────────────────────────────────────────────────
  async function handleAdd() {
    const email = newEmail.trim().toLowerCase()
    if (!email || !email.includes('@')) { toast.error('Enter a valid email'); return }
    setAddLoading(true)
    const res = await fetch('/api/organisation-emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ emails: [email] }),
    })
    if (!res.ok) { toast.error('Failed to add email'); setAddLoading(false); return }
    toast.success('Email added')
    setNewEmail('')
    setAddOpen(false)
    setAddLoading(false)
    router.refresh()
    // Optimistic update
    setEmails(prev => [{ id: Date.now().toString(), email, created_at: new Date().toISOString() }, ...prev])
  }

  // ── CSV Upload ──────────────────────────────────────────────────────────
  function handleCsvChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setCsvFile(file)
    const reader = new FileReader()
    reader.onload = (ev) => {
      const text = ev.target?.result as string
      const parsed = parseEmails(text)
      setCsvPreview(parsed)
    }
    reader.readAsText(file)
  }

  function parseEmails(text: string): string[] {
    return text
      .split(/[\n,\r]+/)
      .map(s => s.trim().toLowerCase().replace(/^["']|["']$/g, ''))
      .filter(s => s.includes('@') && s.includes('.'))
  }

  async function handleCsvUpload() {
    if (csvPreview.length === 0) { toast.error('No valid emails found in file'); return }
    setCsvLoading(true)
    const res = await fetch('/api/organisation-emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ emails: csvPreview }),
    })
    const json = await res.json()
    if (!res.ok) { toast.error(json.error || 'Upload failed'); setCsvLoading(false); return }
    toast.success(`${json.inserted} email(s) added`)
    setCsvFile(null)
    setCsvPreview([])
    setCsvOpen(false)
    setCsvLoading(false)
    if (fileInputRef.current) fileInputRef.current.value = ''
    router.refresh()
  }

  // ── Delete ──────────────────────────────────────────────────────────────
  async function handleDelete(id: string) {
    setDeletingId(id)
    const res = await fetch('/api/organisation-emails', {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id }),
    })
    if (!res.ok) { toast.error('Failed to delete'); setDeletingId(null); return }
    toast.success('Email removed')
    setEmails(prev => prev.filter(e => e.id !== id))
    setDeletingId(null)
  }

  return (
    <>
      {/* Toolbar */}
      <div className="flex items-center gap-3 flex-wrap">
        <Input
          placeholder="Search emails..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="max-w-xs"
        />
        <div className="ml-auto flex gap-2">
          <Button variant="outline" size="sm" onClick={() => setCsvOpen(true)}>
            <Upload className="w-4 h-4 mr-2" />
            Upload CSV
          </Button>
          <Button size="sm" onClick={() => setAddOpen(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Add Email
          </Button>
        </div>
      </div>

      {/* Count */}
      <p className="text-sm text-muted-foreground">
        {filtered.length} of {emails.length} email{emails.length !== 1 ? 's' : ''}
      </p>

      {/* Table */}
      <div className="border border-border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 border-b border-border">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-muted-foreground">Email</th>
              <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden sm:table-cell">Added</th>
              <th className="w-12 px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={3} className="px-4 py-8 text-center text-muted-foreground">
                  {emails.length === 0 ? 'No emails added yet.' : 'No emails match your search.'}
                </td>
              </tr>
            ) : (
              filtered.map(e => (
                <tr key={e.id} className="border-b border-border last:border-0 hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-mono text-xs">{e.email}</td>
                  <td className="px-4 py-3 text-muted-foreground hidden sm:table-cell">
                    {format(new Date(e.created_at), 'dd/MM/yyyy')}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => handleDelete(e.id)}
                      disabled={deletingId === e.id}
                      className="text-muted-foreground hover:text-red-500 transition-colors disabled:opacity-50"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Add Email Dialog */}
      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent className="bg-card border-border max-w-sm">
          <DialogHeader>
            <DialogTitle>Add Email</DialogTitle>
          </DialogHeader>
          <Input
            type="email"
            placeholder="member@example.com"
            value={newEmail}
            onChange={e => setNewEmail(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleAdd()}
            autoFocus
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => setAddOpen(false)}>Cancel</Button>
            <Button onClick={handleAdd} disabled={addLoading}>
              {addLoading ? 'Adding...' : 'Add'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* CSV Upload Dialog */}
      <Dialog open={csvOpen} onOpenChange={open => {
        if (!open) { setCsvFile(null); setCsvPreview([]); if (fileInputRef.current) fileInputRef.current.value = '' }
        setCsvOpen(open)
      }}>
        <DialogContent className="bg-card border-border max-w-md">
          <DialogHeader>
            <DialogTitle>Upload CSV</DialogTitle>
            <p className="text-sm text-muted-foreground">
              One email per row, or comma-separated. Header row is auto-detected and skipped.
            </p>
          </DialogHeader>

          <div
            className="border-2 border-dashed border-border rounded-lg p-6 text-center cursor-pointer hover:border-foreground/40 transition-colors"
            onClick={() => fileInputRef.current?.click()}
          >
            <Upload className="w-8 h-8 mx-auto mb-2 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">
              {csvFile ? csvFile.name : 'Click to select a CSV file'}
            </p>
            <input
              ref={fileInputRef}
              type="file"
              accept=".csv,text/csv,text/plain"
              className="hidden"
              onChange={handleCsvChange}
            />
          </div>

          {csvPreview.length > 0 && (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <p className="text-sm font-medium">{csvPreview.length} valid email(s) found</p>
                <button onClick={() => { setCsvFile(null); setCsvPreview([]); if (fileInputRef.current) fileInputRef.current.value = '' }}>
                  <X className="w-4 h-4 text-muted-foreground" />
                </button>
              </div>
              <div className="bg-muted rounded-md p-3 max-h-40 overflow-y-auto text-xs font-mono space-y-1">
                {csvPreview.slice(0, 50).map((e, i) => <div key={i}>{e}</div>)}
                {csvPreview.length > 50 && (
                  <div className="text-muted-foreground">...and {csvPreview.length - 50} more</div>
                )}
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="outline" onClick={() => setCsvOpen(false)}>Cancel</Button>
            <Button onClick={handleCsvUpload} disabled={csvLoading || csvPreview.length === 0}>
              {csvLoading ? 'Uploading...' : `Upload ${csvPreview.length > 0 ? csvPreview.length : ''} Email(s)`}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
