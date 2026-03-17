'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { upsertEvent, replaceOrganizers, insertGalleryItem, deleteGalleryItem } from '../actions'
import { uploadToStorage } from '../../upload-actions'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger } from '@/components/ui/select'
import { toast } from 'sonner'
import { Loader2, X, MapPin } from 'lucide-react'
import { DateTimePicker } from '@/components/ui/date-time-picker'
import type { Event, VerticalRecord, Profile } from '@/types/database.types'

interface EventFormProps {
  event?: Event & { event_gallery?: any[]; event_organizers?: any[] }
  verticals: VerticalRecord[]
  committeeMembers: Profile[]
}

function parseDatetime(iso: string) {
  if (!iso) return { date: '', time: '' }
  const d = new Date(iso)
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const date = `${year}-${month}-${day}`
  const time = d.toTimeString().slice(0, 5)
  return { date, time }
}

function combineDatetime(date: string, time: string): string | null {
  if (!date) return null
  return new Date(`${date}T${time || '00:00'}:00`).toISOString()
}

export function EventForm({ event, verticals, committeeMembers }: EventFormProps) {
  const router = useRouter()
  const isEdit = !!event

  const [loading, setLoading] = useState(false)
  const [title, setTitle] = useState(event?.title || '')
  const [description, setDescription] = useState(event?.description || '')
  const [verticalId, setVerticalId] = useState(event?.vertical_id || '')
  const [locationName, setLocationName] = useState(event?.location_name || '')
  const [locationUrl, setLocationUrl] = useState(event?.location_url || '')
  const [isRemote, setIsRemote] = useState(event?.is_remote || false)

  const startParsed = parseDatetime(event?.starts_at || '')
  const endParsed = parseDatetime(event?.ends_at || '')
  const [startDate, setStartDate] = useState(startParsed.date)
  const [startTime, setStartTime] = useState(startParsed.time || '09:00')
  const [endDate, setEndDate] = useState(endParsed.date)
  const [endTime, setEndTime] = useState(endParsed.time || '18:00')

  const [isPublished, setIsPublished] = useState(event?.is_published || false)
  const [maxAttendees, setMaxAttendees] = useState(event?.max_attendees?.toString() || '')
  const [selectedOrganizers, setSelectedOrganizers] = useState<string[]>(
    event?.event_organizers?.map((o: any) => o.profile_id) || []
  )
  const [galleryFiles, setGalleryFiles] = useState<File[]>([])
  const [existingGallery, setExistingGallery] = useState<any[]>(event?.event_gallery || [])
  const [coverFile, setCoverFile] = useState<File | null>(null)

  useEffect(() => {
    if (verticalId && !isEdit) {
      const vertical = verticals.find(v => v.id === verticalId)
      if (vertical) {
        const committeeForVertical = committeeMembers
          .filter(m => m.yi_vertical === vertical.slug)
          .slice(0, 4)
          .map(m => m.id)
        setSelectedOrganizers(committeeForVertical)
      }
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [verticalId])

  async function uploadFile(file: File, bucket: string, path: string): Promise<string> {
    const fd = new FormData()
    fd.append('file', file)
    fd.append('bucket', bucket)
    fd.append('path', path)
    return uploadToStorage(fd)
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title || !startDate) {
      toast.error('Title and start date are required')
      return
    }
    setLoading(true)

    try {
      let coverImageUrl = event?.cover_image_url || null
      if (coverFile) {
        coverImageUrl = await uploadFile(coverFile, 'event-media', `covers/${Date.now()}-${coverFile.name}`)
      }

      const eventData = {
        title, description, vertical_id: verticalId || null,
        location_name: locationName || null,
        location_url: locationUrl || null,
        is_remote: isRemote,
        starts_at: combineDatetime(startDate, startTime)!,
        ends_at: endDate ? combineDatetime(endDate, endTime) : null,
        is_published: isPublished,
        max_attendees: maxAttendees ? parseInt(maxAttendees) : null,
        cover_image_url: coverImageUrl,
      }

      const { id: eventId } = await upsertEvent(eventData, isEdit ? event!.id : undefined)

      await replaceOrganizers(eventId, selectedOrganizers)

      if (galleryFiles.length > 0) {
        for (let i = 0; i < galleryFiles.length; i++) {
          const file = galleryFiles[i]
          const mediaUrl = await uploadFile(file, 'event-media', `gallery/${eventId}/${Date.now()}-${file.name}`)
          const isVideo = file.type.startsWith('video/')
          await insertGalleryItem(eventId, mediaUrl, isVideo ? 'video' : 'image', existingGallery.length + i)
        }
      }

      toast.success(isEdit ? 'Event updated!' : 'Event created!')
      router.push('/events')
    } catch (err: any) {
      toast.error(err.message || 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  async function removeGalleryItem(galleryId: string) {
    await deleteGalleryItem(galleryId)
    setExistingGallery(prev => prev.filter(g => g.id !== galleryId))
    toast.success('Removed')
  }

  function toggleOrganizer(profileId: string) {
    setSelectedOrganizers(prev =>
      prev.includes(profileId) ? prev.filter(id => id !== profileId) : [...prev, profileId]
    )
  }

  const selectedVerticalLabel = verticals.find(v => v.id === verticalId)?.label

  return (
    <form onSubmit={handleSubmit}>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* LEFT — Main content (2/3 width) */}
        <div className="lg:col-span-2 space-y-6">

          {/* Event Details */}
          <Card className="border-border">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-semibold">Event Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-5">
              <div className="space-y-1.5">
                <Label className="text-sm font-medium">Event Name <span className="text-destructive">*</span></Label>
                <Input
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                  placeholder="Annual Health Summit 2025"
                  required
                  className="h-10"
                />
              </div>

              <div className="space-y-1.5">
                <Label className="text-sm font-medium">Description</Label>
                <Textarea
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  placeholder="Describe the event..."
                  rows={5}
                  className="resize-none"
                />
              </div>

              {/* Dates — 2 col */}
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <Label className="text-sm font-medium">
                    Start Date & Time <span className="text-destructive">*</span>
                  </Label>
                  <DateTimePicker
                    date={startDate}
                    time={startTime}
                    onDateChange={setStartDate}
                    onTimeChange={setStartTime}
                    placeholder="Pick start date"
                    required
                  />
                </div>
                <div className="space-y-1.5">
                  <Label className="text-sm font-medium">End Date & Time</Label>
                  <DateTimePicker
                    date={endDate}
                    time={endTime}
                    onDateChange={setEndDate}
                    onTimeChange={setEndTime}
                    placeholder="Pick end date"
                    minDate={startDate}
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Location */}
          <Card className="border-border">
            <CardHeader className="pb-4">
              <div className="flex items-center justify-between">
                <CardTitle className="text-base font-semibold flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-muted-foreground" /> Location
                </CardTitle>
                <div className="flex items-center gap-2">
                  <Label htmlFor="is-remote" className="text-sm text-muted-foreground cursor-pointer">Remote Event</Label>
                  <Switch id="is-remote" checked={isRemote} onCheckedChange={setIsRemote} />
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {isRemote ? (
                <div className="space-y-1.5">
                  <Label className="text-sm font-medium">Meeting Link</Label>
                  <Input value={locationUrl} onChange={e => setLocationUrl(e.target.value)} placeholder="https://zoom.us/j/..." className="h-10" />
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <Label className="text-sm font-medium">Venue Name / Address</Label>
                    <Input value={locationName} onChange={e => setLocationName(e.target.value)} placeholder="Hotel Grand, Mumbai" className="h-10" />
                  </div>
                  <div className="space-y-1.5">
                    <Label className="text-sm font-medium">Google Maps Link</Label>
                    <Input value={locationUrl} onChange={e => setLocationUrl(e.target.value)} placeholder="https://maps.google.com/..." className="h-10" />
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Photo Gallery */}
          <Card className="border-border">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-semibold">Photo Gallery</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {(existingGallery.length > 0 || galleryFiles.length > 0) && (
                <div className="grid grid-cols-4 gap-2">
                  {existingGallery.map(item => (
                    <div key={item.id} className="relative rounded-lg overflow-hidden aspect-square bg-muted">
                      {item.media_type === 'video' ? (
                        <video src={item.media_url} className="w-full h-full object-cover" muted playsInline preload="metadata" />
                      ) : (
                        <img src={item.media_url} alt="" className="w-full h-full object-cover" />
                      )}
                      <button
                        type="button"
                        onClick={() => removeGalleryItem(item.id)}
                        className="absolute top-1 right-1 w-5 h-5 bg-destructive rounded-full flex items-center justify-center"
                      >
                        <X className="w-3 h-3 text-white" />
                      </button>
                    </div>
                  ))}
                  {galleryFiles.map((file, i) => {
                    const url = URL.createObjectURL(file)
                    const isVideo = file.type.startsWith('video/')
                    return (
                      <div key={`new-${i}`} className="relative rounded-lg overflow-hidden aspect-square bg-muted">
                        {isVideo ? (
                          <video src={url} className="w-full h-full object-cover" muted playsInline preload="metadata" />
                        ) : (
                          <img src={url} alt="" className="w-full h-full object-cover" />
                        )}
                        <button
                          type="button"
                          onClick={() => setGalleryFiles(prev => prev.filter((_, idx) => idx !== i))}
                          className="absolute top-1 right-1 w-5 h-5 bg-destructive rounded-full flex items-center justify-center"
                        >
                          <X className="w-3 h-3 text-white" />
                        </button>
                      </div>
                    )
                  })}
                </div>
              )}
              {(() => {
                const slotsUsed = existingGallery.length + galleryFiles.length
                const slotsLeft = 10 - slotsUsed
                return slotsLeft > 0 ? (
                  <div className="space-y-1.5">
                    <Label className="text-sm font-medium">Add Photos / Videos</Label>
                    <Input
                      type="file"
                      accept="image/*,video/*"
                      multiple
                      onChange={e => {
                        const newFiles = Array.from(e.target.files || [])
                        setGalleryFiles(prev => {
                          const combined = [...prev, ...newFiles]
                          return combined.slice(0, 10 - existingGallery.length)
                        })
                        e.target.value = ''
                      }}
                      className="h-10 cursor-pointer"
                    />
                    <p className="text-xs text-muted-foreground">{slotsLeft} of 10 slots remaining</p>
                  </div>
                ) : (
                  <p className="text-xs text-muted-foreground">Gallery full (10/10). Remove items to add more.</p>
                )
              })()}
            </CardContent>
          </Card>

          {/* Organizers */}
          {committeeMembers.length > 0 && (
            <Card className="border-border">
              <CardHeader className="pb-4">
                <CardTitle className="text-base font-semibold">Organizers</CardTitle>
                <p className="text-xs text-muted-foreground mt-1">Select committee members organizing this event (3–4 recommended).</p>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-2">
                  {committeeMembers.map(member => {
                    const fullName = [member.first_name, member.last_name].filter(Boolean).join(' ') || 'Member'
                    const initials = [member.first_name?.[0], member.last_name?.[0]].filter(Boolean).join('').toUpperCase() || '?'
                    const isSelected = selectedOrganizers.includes(member.id)
                    return (
                      <button
                        key={member.id}
                        type="button"
                        onClick={() => toggleOrganizer(member.id)}
                        className={`flex items-center gap-2.5 p-2.5 rounded-lg border text-sm text-left transition-all
                          ${isSelected
                            ? 'border-foreground/60 bg-foreground/5 ring-1 ring-foreground/20'
                            : 'border-border hover:border-border/80 hover:bg-muted/50'
                          }`}
                      >
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0
                          ${isSelected ? 'bg-foreground text-background' : 'bg-muted text-muted-foreground'}`}>
                          {initials}
                        </div>
                        <div className="overflow-hidden min-w-0">
                          <p className="truncate font-medium text-xs leading-tight">{fullName}</p>
                          <p className="truncate text-xs text-muted-foreground capitalize mt-0.5">
                            {member.yi_vertical?.replace(/_/g, ' ') || 'General'}
                          </p>
                        </div>
                      </button>
                    )
                  })}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        {/* RIGHT — Sidebar (1/3 width) */}
        <div className="space-y-6">

          {/* Vertical & Capacity */}
          <Card className="border-border">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-semibold">Organisation</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-1.5">
                <Label className="text-sm font-medium">Vertical</Label>
                <Select value={verticalId} onValueChange={(v) => setVerticalId(v ?? '')}>
                  <SelectTrigger className="h-10 w-full">
                    <span className={!selectedVerticalLabel ? 'text-muted-foreground' : ''}>
                      {selectedVerticalLabel ?? 'Select vertical...'}
                    </span>
                  </SelectTrigger>
                  <SelectContent>
                    {verticals.map(v => (
                      <SelectItem key={v.id} value={v.id}>{v.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label className="text-sm font-medium">Max Attendees</Label>
                <Input
                  type="number"
                  value={maxAttendees}
                  onChange={e => setMaxAttendees(e.target.value)}
                  placeholder="Unlimited"
                  className="h-10"
                  min={1}
                />
              </div>
            </CardContent>
          </Card>

          {/* Cover Image */}
          <Card className="border-border">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-semibold">Cover Image</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {event?.cover_image_url && !coverFile && (
                <img src={event.cover_image_url} alt="Cover" className="w-full h-36 object-cover rounded-lg border border-border" />
              )}
              {coverFile && (
                <img src={URL.createObjectURL(coverFile)} alt="Preview" className="w-full h-36 object-cover rounded-lg border border-border" />
              )}
              <Input
                type="file"
                accept="image/*"
                onChange={e => setCoverFile(e.target.files?.[0] || null)}
                className="h-10 cursor-pointer"
              />
            </CardContent>
          </Card>

          {/* Publish — last */}
          <Card className="border-border">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-semibold">Publishing</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-sm">Publish Event</p>
                  <p className="text-xs text-muted-foreground mt-0.5">Visible to all members in app</p>
                </div>
                <Switch checked={isPublished} onCheckedChange={setIsPublished} />
              </div>
              <div className="pt-2 space-y-3">
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  {isEdit ? 'Save Changes' : 'Create Event'}
                </Button>
                <Button type="button" variant="outline" className="w-full" onClick={() => router.back()}>
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </form>
  )
}
