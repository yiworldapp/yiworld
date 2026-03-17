import type { CSSProperties } from 'react'

// Hex colors mirror the color_hex column in public.verticals
const COLORS: Record<string, string> = {
  accessibility:     '#8b5cf6',
  active_living:     '#f97316',
  branding:          '#a855f7',
  climate_change:    '#10b981',
  entrepreneurship:  '#f59e0b',
  health:            '#06b6d4',
  innovation:        '#3b82f6',
  learning:          '#ec4899',
  masoom:            '#f97316',
  membership:        '#8B5CF6',
  pr_advocacy:       '#D946EF',
  road_safety:       '#ef4444',
  rural_initiatives: '#84cc16',
  sports:            '#0EA5E9',
  thalir:            '#22c55e',
  yuva:              '#16a34a',
}

const FALLBACK = '#6b7280'

export function verticalBadgeStyle(slug: string | null | undefined): CSSProperties {
  const hex = (slug && COLORS[slug]) ? COLORS[slug] : FALLBACK
  return {
    color: hex,
    borderColor: `${hex}50`,
    backgroundColor: `${hex}18`,
  }
}

export function verticalLabel(slug: string | null | undefined): string {
  if (!slug || slug === 'none') return ''
  return slug.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}
