export type MemberType = 'member' | 'committee' | 'super_admin'
export type AdminRole = 'super_admin' | 'committee'
export type AdminStatus = 'pending' | 'active'

export interface AdminUser {
  id: string
  name: string
  email: string
  role: AdminRole
  status: AdminStatus
  permissions: string[]
  created_at: string
}
export type Vertical = 'health' | 'climate' | 'other'
export type RsvpStatus = 'going' | 'not_going' | 'maybe'
export type OfferType = 'discount' | 'freebie' | 'cashback' | 'exclusive'

export interface Profile {
  id: string
  // Contact
  phone: string | null
  phone_country_code: string | null
  secondary_phone: string | null
  secondary_phone_country_code: string | null
  email: string | null
  primary_email: string | null
  secondary_email: string | null
  // Personal
  first_name: string | null
  last_name: string | null
  headshot_url: string | null
  dob: string | null
  country: string | null
  state: string | null
  city: string | null
  blood_group: string | null
  relationship_status: string | null
  spouse_name: string | null
  is_spouse_yi_member: boolean | null
  anniversary_date: string | null
  personal_bio: string | null
  // Professional
  job_title: string | null
  company_name: string | null
  industry: string | null
  business_bio: string | null
  business_website: string | null
  business_tags: string[] | null
  hobby_tags: string[] | null
  // Social
  linkedin_url: string | null
  instagram_url: string | null
  twitter_url: string | null
  facebook_url: string | null
  // YI
  member_type: MemberType
  yi_vertical: string | null
  yi_position: string | null
  yi_member_since: number | null
  // Legacy
  bio: string | null
  onboarding_done: boolean
  created_at: string
  updated_at: string
}

export interface VerticalRecord {
  id: string
  slug: Vertical
  label: string
  description: string | null
  color_hex: string | null
  icon_url: string | null
  created_at: string
}

export interface Event {
  id: string
  title: string
  description: string | null
  vertical_id: string | null
  location_name: string | null
  location_lat: number | null
  location_lng: number | null
  location_url: string | null
  is_remote: boolean
  starts_at: string
  ends_at: string | null
  cover_image_url: string | null
  is_published: boolean
  max_attendees: number | null
  created_by: string | null
  created_at: string
  updated_at: string
  // joined
  vertical_label?: string
  vertical_color?: string
  rsvp_count?: number
}

export interface EventGallery {
  id: string
  event_id: string
  media_url: string
  media_type: 'image' | 'video'
  caption: string | null
  sort_order: number
  created_at: string
}

export interface EventOrganizer {
  event_id: string
  profile_id: string
  role: string
  // joined
  profile?: Profile
}

export interface EventRsvp {
  id: string
  event_id: string
  profile_id: string
  status: RsvpStatus
  rsvped_at: string
  profile?: Profile
}

export interface Mou {
  id: string
  title: string
  description: string | null
  tag: 'institute' | 'school' | 'organisation'
  pdf_url: string
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface Partner {
  id: string
  name: string
  description: string | null
  logo_url: string | null
  website_url: string | null
  category: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Offer {
  id: string
  partner_id: string
  title: string
  description: string | null
  offer_type: OfferType
  discount_value: string | null
  coupon_code: string | null
  image_url: string | null
  how_to_claim: string | null
  terms: string | null
  valid_from: string | null
  valid_until: string | null
  is_active: boolean
  created_at: string
  updated_at: string
  // joined
  partner?: Partner
}
