'use server'

import { createAdminClient } from '@/lib/supabase/server'

export async function insertMOU(data: {
  title: string
  description: string | null
  tag: string
  pdf_url: string
}) {
  const supabase = await createAdminClient()
  const { error } = await supabase.from('mous').insert(data)
  if (error) throw new Error(error.message)
}

export async function deleteMOU(mouId: string) {
  const supabase = await createAdminClient()
  const { error } = await supabase.from('mous').delete().eq('id', mouId)
  if (error) throw new Error(error.message)
}
