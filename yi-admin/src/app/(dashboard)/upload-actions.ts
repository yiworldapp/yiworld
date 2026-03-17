'use server'

import { createAdminClient } from '@/lib/supabase/server'

/**
 * Upload a file to Supabase Storage using the service role key (bypasses storage RLS).
 * Accepts FormData so it can receive File objects from client components.
 */
export async function uploadToStorage(formData: FormData): Promise<string> {
  const file = formData.get('file') as File
  const bucket = formData.get('bucket') as string
  const path = formData.get('path') as string

  if (!file || !bucket || !path) throw new Error('Missing file, bucket, or path')

  const supabase = await createAdminClient()
  const arrayBuffer = await file.arrayBuffer()
  const buffer = Buffer.from(arrayBuffer)

  const { error } = await supabase.storage.from(bucket).upload(path, buffer, {
    contentType: file.type || 'application/octet-stream',
    upsert: true,
  })
  if (error) throw new Error(error.message)

  const { data: { publicUrl } } = supabase.storage.from(bucket).getPublicUrl(path)
  return publicUrl
}
