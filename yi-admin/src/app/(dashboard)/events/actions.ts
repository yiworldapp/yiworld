'use server'

import { createAdminClient } from '@/lib/supabase/server'

export async function upsertEvent(
  eventData: Record<string, unknown>,
  eventId?: string
): Promise<{ id: string }> {
  const supabase = await createAdminClient()

  if (eventId) {
    // Never overwrite created_by on edit
    const { created_by, ...updateData } = eventData
    const { error } = await supabase.from('events').update(updateData).eq('id', eventId)
    if (error) throw new Error(error.message)
    return { id: eventId }
  } else {
    const { data, error } = await supabase.from('events').insert(eventData).select('id').single()
    if (error) throw new Error(error.message)
    return { id: data.id }
  }
}

export async function replaceOrganizers(eventId: string, profileIds: string[]) {
  const supabase = await createAdminClient()
  await supabase.from('event_organizers').delete().eq('event_id', eventId)
  if (profileIds.length > 0) {
    const { error } = await supabase.from('event_organizers').insert(
      profileIds.map(pid => ({ event_id: eventId, profile_id: pid }))
    )
    if (error) throw new Error(error.message)
  }
}

export async function insertGalleryItem(
  eventId: string,
  mediaUrl: string,
  mediaType: 'image' | 'video',
  sortOrder: number
) {
  const supabase = await createAdminClient()
  const { error } = await supabase.from('event_gallery').insert({
    event_id: eventId,
    media_url: mediaUrl,
    media_type: mediaType,
    sort_order: sortOrder,
  })
  if (error) throw new Error(error.message)
}

export async function deleteGalleryItem(galleryId: string) {
  const supabase = await createAdminClient()
  const { error } = await supabase.from('event_gallery').delete().eq('id', galleryId)
  if (error) throw new Error(error.message)
}

export async function deleteEvent(eventId: string) {
  const supabase = await createAdminClient()
  const { error } = await supabase.from('events').delete().eq('id', eventId)
  if (error) throw new Error(error.message)
}
