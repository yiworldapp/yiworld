import { createClient, createAdminClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { LinkButton } from '@/components/ui/link-button'
import { ArrowLeft, Mail, Phone, MapPin, Briefcase, Building2, Globe, Linkedin, Instagram, Twitter, Facebook, Heart, Tag, Users } from 'lucide-react'
import { format } from 'date-fns'

function InfoRow({ label, value }: { label: string; value?: string | null }) {
  if (!value) return null
  return (
    <div className="flex justify-between items-start gap-4 py-2 border-b border-border/50 last:border-0">
      <span className="text-sm text-muted-foreground shrink-0">{label}</span>
      <span className="text-sm text-foreground text-right">{value}</span>
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <Card className="border-border">
      <CardHeader className="pb-2 pt-4 px-4">
        <CardTitle className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">{title}</CardTitle>
      </CardHeader>
      <CardContent className="px-4 pb-4">{children}</CardContent>
    </Card>
  )
}

export default async function ViewMemberPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const adminClient = await createAdminClient()
  const { data: adminUser } = await adminClient.from('admin_users').select('role, permissions').eq('id', user!.id).single()
  if (adminUser?.role !== 'super_admin' && !adminUser?.permissions?.includes('members')) redirect('/events')

  const { data: member } = await supabase.from('profiles').select('*').eq('id', id).single()
  if (!member) notFound()

  const fullName = [member.first_name, member.last_name].filter(Boolean).join(' ') || 'Unnamed'
  const initials = [member.first_name?.[0], member.last_name?.[0]].filter(Boolean).join('').toUpperCase() || '?'

  const verticalColors: Record<string, string> = {
    health: 'text-green-600 border-green-200 bg-green-50',
    climate: 'text-orange-600 border-orange-200 bg-orange-50',
    other: 'text-yellow-600 border-yellow-200 bg-yellow-50',
  }

  const hasYiInfo = member.yi_vertical && member.yi_vertical !== 'none'
  const hasSocial = member.linkedin_url || member.instagram_url || member.twitter_url || member.facebook_url
  const hasProfessional = member.job_title || member.company_name || member.industry || member.business_bio || member.business_website
  const hasPersonal = member.dob || member.blood_group || member.relationship_status || member.city || member.country
  const hasContact = member.phone || member.primary_email || member.secondary_email || member.secondary_phone

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <LinkButton href="/members" variant="ghost" size="sm" className="h-8 w-8 p-0">
          <ArrowLeft className="w-4 h-4" />
        </LinkButton>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">{fullName}</h1>
          <p className="text-muted-foreground text-sm mt-0.5">
            {member.member_type.replace('_', ' ')} · Joined {format(new Date(member.created_at), 'MMM d, yyyy')}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* ── Left column — sticky identity card ── */}
        <div className="space-y-4 lg:col-span-1 lg:sticky lg:top-6 lg:self-start">
          <Card className="border-border">
            <CardContent className="pt-6 flex flex-col items-center text-center gap-4 pb-6">
              <Avatar className="h-24 w-24 border-2 border-border">
                <AvatarImage src={member.headshot_url || ''} />
                <AvatarFallback className="bg-muted text-foreground text-2xl font-bold">{initials}</AvatarFallback>
              </Avatar>
              <div>
                <h2 className="text-lg font-semibold">{fullName}</h2>
                {member.job_title && <p className="text-sm text-muted-foreground">{member.job_title}</p>}
                {member.company_name && <p className="text-sm text-muted-foreground">{member.company_name}</p>}
              </div>
              <div className="flex flex-wrap gap-2 justify-center">
                <Badge variant="outline" className="capitalize border-border text-xs">
                  {member.member_type.replace('_', ' ')}
                </Badge>
                {hasYiInfo && (
                  <Badge variant="outline" className={`text-xs ${verticalColors[member.yi_vertical!] || verticalColors.other}`}>
                    {member.yi_vertical}
                  </Badge>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Social links */}
          {hasSocial && (
            <Section title="Social">
              <div className="space-y-2">
                {member.linkedin_url && (
                  <a href={member.linkedin_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:text-foreground text-muted-foreground transition-colors">
                    <Linkedin className="w-4 h-4 shrink-0" /> LinkedIn
                  </a>
                )}
                {member.instagram_url && (
                  <a href={member.instagram_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:text-foreground text-muted-foreground transition-colors">
                    <Instagram className="w-4 h-4 shrink-0" /> Instagram
                  </a>
                )}
                {member.twitter_url && (
                  <a href={member.twitter_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:text-foreground text-muted-foreground transition-colors">
                    <Twitter className="w-4 h-4 shrink-0" /> Twitter / X
                  </a>
                )}
                {member.facebook_url && (
                  <a href={member.facebook_url} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-sm hover:text-foreground text-muted-foreground transition-colors">
                    <Facebook className="w-4 h-4 shrink-0" /> Facebook
                  </a>
                )}
              </div>
            </Section>
          )}
        </div>

        {/* ── Right column — details ── */}
        <div className="lg:col-span-2 space-y-4">
          {/* Contact */}
          {hasContact && (
            <Section title="Contact">
              <InfoRow label="Phone" value={member.phone} />
              <InfoRow label="Secondary Phone" value={member.secondary_phone} />
              <InfoRow label="Primary Email" value={member.primary_email || member.email} />
              <InfoRow label="Secondary Email" value={member.secondary_email} />
            </Section>
          )}

          {/* Personal */}
          {hasPersonal && (
            <Section title="Personal">
              <InfoRow label="Date of Birth" value={member.dob ? format(new Date(member.dob), 'MMM d, yyyy') : null} />
              <InfoRow label="Blood Group" value={member.blood_group} />
              <InfoRow label="Location" value={[member.city, member.state, member.country].filter(Boolean).join(', ')} />
              <InfoRow label="Relationship" value={member.relationship_status} />
              <InfoRow label="Spouse" value={member.spouse_name} />
              {member.is_spouse_yi_member != null && (
                <InfoRow label="Spouse is YI Member" value={member.is_spouse_yi_member ? 'Yes' : 'No'} />
              )}
              <InfoRow label="Anniversary" value={member.anniversary_date ? format(new Date(member.anniversary_date), 'MMM d, yyyy') : null} />
              {member.personal_bio && (
                <div className="pt-2">
                  <p className="text-xs text-muted-foreground mb-1">Personal Bio</p>
                  <p className="text-sm text-foreground leading-relaxed">{member.personal_bio}</p>
                </div>
              )}
            </Section>
          )}

          {/* Professional */}
          {hasProfessional && (
            <Section title="Professional">
              <InfoRow label="Job Title" value={member.job_title} />
              <InfoRow label="Company" value={member.company_name} />
              <InfoRow label="Industry" value={member.industry} />
              <InfoRow label="Website" value={member.business_website} />
              {member.business_bio && (
                <div className="pt-2">
                  <p className="text-xs text-muted-foreground mb-1">Business Bio</p>
                  <p className="text-sm text-foreground leading-relaxed">{member.business_bio}</p>
                </div>
              )}
              {member.business_tags && member.business_tags.length > 0 && (
                <div className="pt-2">
                  <p className="text-xs text-muted-foreground mb-2">Business Tags</p>
                  <div className="flex flex-wrap gap-1.5">
                    {member.business_tags.map((t) => (
                      <Badge key={t} variant="outline" className="text-xs border-border">{t}</Badge>
                    ))}
                  </div>
                </div>
              )}
              {member.hobby_tags && member.hobby_tags.length > 0 && (
                <div className="pt-2">
                  <p className="text-xs text-muted-foreground mb-2">Hobbies</p>
                  <div className="flex flex-wrap gap-1.5">
                    {member.hobby_tags.map((t) => (
                      <Badge key={t} variant="outline" className="text-xs border-border">{t}</Badge>
                    ))}
                  </div>
                </div>
              )}
            </Section>
          )}

          {/* YI Info */}
          <Section title="Young Indians">
            <InfoRow label="Vertical" value={hasYiInfo ? member.yi_vertical : null} />
            <InfoRow label="Position" value={member.yi_position && member.yi_position !== 'none' ? member.yi_position : null} />
            <InfoRow label="Member Since" value={member.yi_member_since ? String(member.yi_member_since) : null} />
            <InfoRow label="Status" value="Active" />
          </Section>

          {/* Account */}
          <Section title="Account">
            <InfoRow label="Member ID" value={member.id} />
            <InfoRow label="Joined" value={format(new Date(member.created_at), 'MMM d, yyyy')} />
            <InfoRow label="Onboarding" value={member.onboarding_done ? 'Complete' : 'Incomplete'} />
          </Section>
        </div>
      </div>
    </div>
  )
}
