'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Select, SelectContent, SelectItem,
  SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { toast } from 'sonner'
import { DatePicker } from '@/components/ui/date-picker'
import type { Profile } from '@/types/database.types'

function FormSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <Card className="border-border">
      <CardHeader className="pb-2 pt-4 px-4">
        <CardTitle className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">{title}</CardTitle>
      </CardHeader>
      <CardContent className="px-4 pb-4 space-y-4">{children}</CardContent>
    </Card>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="space-y-1.5">
      <Label className="text-sm font-medium">{label}</Label>
      {children}
    </div>
  )
}

function Row({ children }: { children: React.ReactNode }) {
  return <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">{children}</div>
}

const VERTICALS = [
  { value: 'none', label: 'None' },
  { value: 'innovation', label: 'Innovation' },
  { value: 'climate_change', label: 'Climate Change' },
  { value: 'yuva', label: 'Yuva' },
  { value: 'thalir', label: 'Thalir' },
  { value: 'masoom', label: 'Masoom' },
  { value: 'branding', label: 'Branding' },
  { value: 'learning', label: 'Learning' },
  { value: 'road_safety', label: 'Road Safety' },
  { value: 'accessibility', label: 'Accessibility' },
  { value: 'health', label: 'Health' },
  { value: 'rural_initiatives', label: 'Rural Initiatives' },
  { value: 'entrepreneurship', label: 'Entrepreneurship' },
]

const POSITIONS = [
  { value: 'none', label: 'None' },
  { value: 'chair', label: 'Chair' },
  { value: 'co_chair', label: 'Co-Chair' },
  { value: 'joint_chair', label: 'Joint Chair' },
  { value: 'ec_member', label: 'EC Member' },
  { value: 'mentor', label: 'Mentor' },
]

const BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']

export function EditMemberForm({ member }: { member: Profile }) {
  const router = useRouter()
  const [saving, setSaving] = useState(false)

  const [form, setForm] = useState({
    first_name: member.first_name ?? '',
    last_name: member.last_name ?? '',
    headshot_url: member.headshot_url ?? '',
    phone: member.phone ?? '',
    secondary_phone: member.secondary_phone ?? '',
    primary_email: member.primary_email ?? '',
    secondary_email: member.secondary_email ?? '',
    dob: member.dob ?? '',
    blood_group: member.blood_group ?? '',
    address_line1: member.address_line1 ?? '',
    address_line2: member.address_line2 ?? '',
    city: member.city ?? '',
    state: member.state ?? '',
    country: member.country ?? '',
    relationship_status: member.relationship_status ?? '',
    spouse_name: member.spouse_name ?? '',
    is_spouse_yi_member: member.is_spouse_yi_member == null ? '' : member.is_spouse_yi_member ? 'yes' : 'no',
    anniversary_date: member.anniversary_date ?? '',
    personal_bio: member.personal_bio ?? '',
    job_title: member.job_title ?? '',
    company_name: member.company_name ?? '',
    industry: member.industry ?? '',
    business_bio: member.business_bio ?? '',
    business_website: member.business_website ?? '',
    business_tags: (member.business_tags ?? []).join(', '),
    hobby_tags: (member.hobby_tags ?? []).join(', '),
    linkedin_url: member.linkedin_url ?? '',
    instagram_url: member.instagram_url ?? '',
    twitter_url: member.twitter_url ?? '',
    facebook_url: member.facebook_url ?? '',
    member_type: member.member_type ?? 'member',
    yi_vertical: member.yi_vertical ?? 'none',
    yi_position: member.yi_position ?? 'none',
    yi_member_since: member.yi_member_since ? String(member.yi_member_since) : '',
    is_test_user: member.is_test_user ?? false,
  })

  function set(key: keyof typeof form) {
    return (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      setForm(f => ({ ...f, [key]: e.target.value }))
  }

  function setSelect(key: keyof typeof form) {
    return (val: string | null) => setForm(f => ({ ...f, [key]: val ?? '' }))
  }

  async function handleSave() {
    setSaving(true)
    const parseTags = (s: string) =>
      s.split(',').map(t => t.trim()).filter(Boolean)

    const body = {
      id: member.id,
      first_name: form.first_name || null,
      last_name: form.last_name || null,
      headshot_url: form.headshot_url || null,
      phone: form.phone || null,
      secondary_phone: form.secondary_phone || null,
      primary_email: form.primary_email || null,
      secondary_email: form.secondary_email || null,
      dob: form.dob || null,
      blood_group: form.blood_group || null,
      address_line1: form.address_line1 || null,
      address_line2: form.address_line2 || null,
      city: form.city || null,
      state: form.state || null,
      country: form.country || null,
      relationship_status: form.relationship_status || null,
      spouse_name: form.spouse_name || null,
      is_spouse_yi_member: form.is_spouse_yi_member === 'yes' ? true : form.is_spouse_yi_member === 'no' ? false : null,
      anniversary_date: form.anniversary_date || null,
      personal_bio: form.personal_bio || null,
      job_title: form.job_title || null,
      company_name: form.company_name || null,
      industry: form.industry || null,
      business_bio: form.business_bio || null,
      business_website: form.business_website || null,
      business_tags: parseTags(form.business_tags),
      hobby_tags: parseTags(form.hobby_tags),
      linkedin_url: form.linkedin_url || null,
      instagram_url: form.instagram_url || null,
      twitter_url: form.twitter_url || null,
      facebook_url: form.facebook_url || null,
      member_type: form.member_type,
      yi_vertical: form.yi_vertical,
      yi_position: form.yi_position,
      yi_member_since: form.yi_member_since ? parseInt(form.yi_member_since) : null,
      is_test_user: form.is_test_user,
    }

    const res = await fetch('/api/members', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })

    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      toast.error(err.error ?? 'Failed to save changes')
      setSaving(false)
      return
    }

    toast.success('Member updated')
    router.push(`/members/${member.id}`)
    router.refresh()
  }

  return (
    <div className="space-y-4 max-w-3xl">
      {/* Identity */}
      <FormSection title="Identity">
        <Row>
          <Field label="First Name">
            <Input value={form.first_name} onChange={set('first_name')} placeholder="First name" />
          </Field>
          <Field label="Last Name">
            <Input value={form.last_name} onChange={set('last_name')} placeholder="Last name" />
          </Field>
        </Row>
        <Field label="Profile Photo URL">
          <Input value={form.headshot_url} onChange={set('headshot_url')} placeholder="https://..." />
        </Field>
      </FormSection>

      {/* Contact */}
      <FormSection title="Contact">
        <Row>
          <Field label="Phone">
            <Input value={form.phone} onChange={set('phone')} placeholder="+917379357888" />
          </Field>
          <Field label="Secondary Phone">
            <Input value={form.secondary_phone} onChange={set('secondary_phone')} placeholder="+91..." />
          </Field>
        </Row>
        <Row>
          <Field label="Primary Email">
            <Input type="email" value={form.primary_email} onChange={set('primary_email')} placeholder="email@example.com" />
          </Field>
          <Field label="Secondary Email">
            <Input type="email" value={form.secondary_email} onChange={set('secondary_email')} placeholder="email@example.com" />
          </Field>
        </Row>
      </FormSection>

      {/* Personal */}
      <FormSection title="Personal">
        <Row>
          <Field label="Date of Birth">
            <DatePicker date={form.dob} onDateChange={val => setForm(f => ({ ...f, dob: val }))} />
          </Field>
          <Field label="Blood Group">
            <Select value={form.blood_group} onValueChange={setSelect('blood_group')}>
              <SelectTrigger className="bg-background border-border">
                <SelectValue placeholder="Select" />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                <SelectItem value="">Not specified</SelectItem>
                {BLOOD_GROUPS.map(bg => (
                  <SelectItem key={bg} value={bg}>{bg}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
        </Row>
        <Field label="Address Line 1">
          <Input value={form.address_line1} onChange={set('address_line1')} placeholder="Street / Building" />
        </Field>
        <Field label="Address Line 2">
          <Input value={form.address_line2} onChange={set('address_line2')} placeholder="Apartment / Landmark" />
        </Field>
        <Row>
          <Field label="City">
            <Input value={form.city} onChange={set('city')} placeholder="City" />
          </Field>
          <Field label="State">
            <Input value={form.state} onChange={set('state')} placeholder="State" />
          </Field>
        </Row>
        <Field label="Country">
          <Input value={form.country} onChange={set('country')} placeholder="Country" />
        </Field>
        <Row>
          <Field label="Relationship Status">
            <Select value={form.relationship_status} onValueChange={setSelect('relationship_status')}>
              <SelectTrigger className="bg-background border-border">
                <SelectValue placeholder="Select" />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                <SelectItem value="">Not specified</SelectItem>
                <SelectItem value="single">Single</SelectItem>
                <SelectItem value="married">Married</SelectItem>
              </SelectContent>
            </Select>
          </Field>
          <Field label="Spouse Name">
            <Input value={form.spouse_name} onChange={set('spouse_name')} placeholder="Spouse name" />
          </Field>
        </Row>
        <Field label="Spouse is YI Member">
          <Select value={form.is_spouse_yi_member} onValueChange={setSelect('is_spouse_yi_member')}>
            <SelectTrigger className="bg-background border-border">
              <SelectValue placeholder="Select" />
            </SelectTrigger>
            <SelectContent className="bg-card border-border">
              <SelectItem value="">Not specified</SelectItem>
              <SelectItem value="yes">Yes</SelectItem>
              <SelectItem value="no">No</SelectItem>
            </SelectContent>
          </Select>
        </Field>
        <Field label="Anniversary Date">
          <DatePicker date={form.anniversary_date} onDateChange={val => setForm(f => ({ ...f, anniversary_date: val }))} />
        </Field>
        <Field label="Personal Bio">
          <Textarea value={form.personal_bio} onChange={set('personal_bio')} placeholder="About the person..." rows={3} />
        </Field>
      </FormSection>

      {/* Professional */}
      <FormSection title="Professional">
        <Row>
          <Field label="Job Title">
            <Input value={form.job_title} onChange={set('job_title')} placeholder="Job title" />
          </Field>
          <Field label="Company Name">
            <Input value={form.company_name} onChange={set('company_name')} placeholder="Company" />
          </Field>
        </Row>
        <Row>
          <Field label="Industry">
            <Input value={form.industry} onChange={set('industry')} placeholder="Industry" />
          </Field>
          <Field label="Business Website">
            <Input value={form.business_website} onChange={set('business_website')} placeholder="https://" />
          </Field>
        </Row>
        <Field label="Business Bio">
          <Textarea value={form.business_bio} onChange={set('business_bio')} placeholder="About the business..." rows={3} />
        </Field>
        <Field label="Business Tags (comma-separated)">
          <Input value={form.business_tags} onChange={set('business_tags')} placeholder="Design, Marketing, Retail" />
        </Field>
        <Field label="Hobby Tags (comma-separated)">
          <Input value={form.hobby_tags} onChange={set('hobby_tags')} placeholder="Cricket, Music, Travel" />
        </Field>
      </FormSection>

      {/* Social */}
      <FormSection title="Social Links">
        <Field label="LinkedIn URL">
          <Input value={form.linkedin_url} onChange={set('linkedin_url')} placeholder="https://linkedin.com/in/..." />
        </Field>
        <Field label="Instagram URL">
          <Input value={form.instagram_url} onChange={set('instagram_url')} placeholder="https://instagram.com/..." />
        </Field>
        <Field label="Twitter / X URL">
          <Input value={form.twitter_url} onChange={set('twitter_url')} placeholder="https://x.com/..." />
        </Field>
        <Field label="Facebook URL">
          <Input value={form.facebook_url} onChange={set('facebook_url')} placeholder="https://facebook.com/..." />
        </Field>
      </FormSection>

      {/* Young Indians */}
      <FormSection title="Young Indians">
        <Row>
          <Field label="Member Type">
            <Select value={form.member_type} onValueChange={setSelect('member_type')}>
              <SelectTrigger className="bg-background border-border">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                <SelectItem value="member">Member</SelectItem>
                <SelectItem value="committee">Committee</SelectItem>
                <SelectItem value="super_admin">Super Admin</SelectItem>
              </SelectContent>
            </Select>
          </Field>
          <Field label="Member Since (year)">
            <Input value={form.yi_member_since} onChange={set('yi_member_since')} placeholder="2022" type="number" />
          </Field>
        </Row>
        <Row>
          <Field label="Vertical">
            <Select value={form.yi_vertical} onValueChange={setSelect('yi_vertical')}>
              <SelectTrigger className="bg-background border-border">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                {VERTICALS.map(v => (
                  <SelectItem key={v.value} value={v.value}>{v.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <Field label="Position">
            <Select value={form.yi_position} onValueChange={setSelect('yi_position')}>
              <SelectTrigger className="bg-background border-border">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-card border-border">
                {POSITIONS.map(p => (
                  <SelectItem key={p.value} value={p.value}>{p.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
        </Row>
      </FormSection>

      {/* Test User */}
      <FormSection title="Testing">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium">Test User</p>
            <p className="text-xs text-muted-foreground">Hidden from the members list in the app</p>
          </div>
          <button
            type="button"
            onClick={() => setForm(f => ({ ...f, is_test_user: !f.is_test_user }))}
            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${form.is_test_user ? 'bg-green-500' : 'bg-muted'}`}
          >
            <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${form.is_test_user ? 'translate-x-6' : 'translate-x-1'}`} />
          </button>
        </div>
      </FormSection>

      {/* Actions */}
      <div className="flex items-center gap-3 pb-6">
        <Button onClick={handleSave} disabled={saving}>
          {saving ? 'Saving...' : 'Save Changes'}
        </Button>
        <Button variant="outline" onClick={() => router.back()} disabled={saving}>
          Cancel
        </Button>
      </div>
    </div>
  )
}
