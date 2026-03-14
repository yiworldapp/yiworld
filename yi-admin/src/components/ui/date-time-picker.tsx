'use client'

import * as React from 'react'
import { format, parse, isValid } from 'date-fns'
import { CalendarIcon, Clock } from 'lucide-react'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Calendar } from '@/components/ui/calendar'
import { cn } from '@/lib/utils'

interface DateTimePickerProps {
  date: string
  time: string
  onDateChange: (date: string) => void
  onTimeChange: (time: string) => void
  placeholder?: string
  required?: boolean
  minDate?: string
}

const HOURS   = Array.from({ length: 12 }, (_, i) => String(i + 1).padStart(2, '0'))
const MINUTES = Array.from({ length: 60 }, (_, i) => String(i).padStart(2, '0'))
const PERIODS = ['AM', 'PM']

const ITEM_H = 36   // px per row
const VISIBLE = 5   // rows shown

// ── Drum-roll column ──────────────────────────────────────────────
function TimeColumn({
  items,
  value,
  onChange,
}: {
  items: string[]
  value: string
  onChange: (v: string) => void
}) {
  const ref = React.useRef<HTMLDivElement>(null)
  const scrollTimer = React.useRef<ReturnType<typeof setTimeout> | null>(null)

  // Scroll to selected item whenever value changes externally
  React.useEffect(() => {
    const idx = items.indexOf(value)
    if (ref.current && idx >= 0) {
      ref.current.scrollTop = idx * ITEM_H
    }
  }, [value, items])

  function handleScroll() {
    if (!ref.current) return
    if (scrollTimer.current) clearTimeout(scrollTimer.current)
    scrollTimer.current = setTimeout(() => {
      if (!ref.current) return
      const idx = Math.round(ref.current.scrollTop / ITEM_H)
      const clamped = Math.max(0, Math.min(items.length - 1, idx))
      // Snap scroll position
      ref.current.scrollTop = clamped * ITEM_H
      if (items[clamped] !== value) onChange(items[clamped])
    }, 80)
  }

  function handleClick(item: string) {
    const idx = items.indexOf(item)
    if (ref.current) ref.current.scrollTo({ top: idx * ITEM_H, behavior: 'smooth' })
    onChange(item)
  }

  const pad = (VISIBLE - 1) * ITEM_H // bottom padding only so last item can scroll to top

  return (
    <div className="relative flex flex-col items-center" style={{ width: 52 }}>
      {/* Selection highlight band — pinned to top */}
      <div
        className="pointer-events-none absolute left-0 right-0 rounded-md bg-foreground z-10"
        style={{ top: 0, height: ITEM_H }}
      />
      {/* Scroll container */}
      <div
        ref={ref}
        onScroll={handleScroll}
        className="overflow-y-scroll relative z-20"
        style={{
          height: VISIBLE * ITEM_H,
          scrollbarWidth: 'none',
          WebkitOverflowScrolling: 'touch',
        }}
      >
        <style>{`.no-scrollbar::-webkit-scrollbar{display:none}`}</style>
        {items.map((item) => {
          const isSelected = item === value
          return (
            <div
              key={item}
              onClick={() => handleClick(item)}
              className={cn(
                'flex items-center justify-center cursor-pointer select-none text-sm font-medium transition-colors',
                isSelected ? 'text-background' : 'text-foreground/40 hover:text-foreground/70'
              )}
              style={{ height: ITEM_H }}
            >
              {item}
            </div>
          )
        })}
        {/* Bottom padding so last item can reach top */}
        <div style={{ height: pad }} />
      </div>
    </div>
  )
}

// ── Helpers ───────────────────────────────────────────────────────
function to12h(time: string) {
  if (!time) return { h12: '09', minute: '00', period: 'AM' as 'AM' | 'PM' }
  const [hStr, mStr] = time.split(':')
  const h24 = parseInt(hStr || '9')
  const period: 'AM' | 'PM' = h24 >= 12 ? 'PM' : 'AM'
  const h12 = h24 === 0 ? '12' : h24 > 12 ? String(h24 - 12).padStart(2, '0') : String(h24).padStart(2, '0')
  const minute = String(parseInt(mStr || '0')).padStart(2, '0')
  return { h12, minute, period }
}

function to24h(h12: string, minute: string, period: string) {
  let h = parseInt(h12)
  if (period === 'AM') { if (h === 12) h = 0 }
  else { if (h !== 12) h += 12 }
  return `${String(h).padStart(2, '0')}:${minute}`
}

function formatDisplay(time: string) {
  const { h12, minute, period } = to12h(time)
  return `${h12}:${minute} ${period}`
}

// ── Main component ────────────────────────────────────────────────
export function DateTimePicker({
  date,
  time,
  onDateChange,
  onTimeChange,
  placeholder = 'Pick a date',
  required,
  minDate,
}: DateTimePickerProps) {
  const [dateOpen, setDateOpen] = React.useState(false)
  const [timeOpen, setTimeOpen] = React.useState(false)

  const selected = date ? parse(date, 'yyyy-MM-dd', new Date()) : undefined
  const validSelected = selected && isValid(selected) ? selected : undefined

  const { h12, minute, period } = to12h(time || '09:00')

  return (
    <div className="flex gap-2">
      {/* ── Date ── */}
      <Popover open={dateOpen} onOpenChange={setDateOpen}>
        <PopoverTrigger
          className={cn(
            'flex flex-1 items-center gap-2 rounded-md border border-input bg-background px-3 h-10 text-sm text-left font-normal transition-colors cursor-pointer',
            'hover:border-foreground/40 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
            !validSelected && 'text-muted-foreground'
          )}
        >
          <CalendarIcon className="h-4 w-4 shrink-0 opacity-50" />
          <span className="truncate">
            {validSelected ? format(validSelected, 'MMM d, yyyy') : placeholder}
          </span>
        </PopoverTrigger>
        <PopoverContent className="w-auto p-0" align="start">
          <Calendar
            mode="single"
            selected={validSelected}
            onSelect={(day) => { if (day) { onDateChange(format(day, 'yyyy-MM-dd')); setDateOpen(false) } }}
            disabled={minDate ? { before: parse(minDate, 'yyyy-MM-dd', new Date()) } : undefined}
            initialFocus
          />
        </PopoverContent>
      </Popover>

      {/* ── Time ── */}
      <Popover open={timeOpen} onOpenChange={setTimeOpen}>
        <PopoverTrigger
          className={cn(
            'flex w-[130px] items-center gap-2 rounded-md border border-input bg-background px-3 h-10 text-sm text-left font-normal transition-colors cursor-pointer',
            'hover:border-foreground/40 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
          )}
        >
          <Clock className="h-4 w-4 shrink-0 opacity-50" />
          <span>{formatDisplay(time || '09:00')}</span>
        </PopoverTrigger>
        <PopoverContent className="w-auto p-3" align="start">
          <div className="flex gap-1 items-start">
            <TimeColumn
              items={HOURS}
              value={h12}
              onChange={(v) => onTimeChange(to24h(v, minute, period))}
            />
            {/* Colon — centered at the top row height */}
            <div className="flex items-center justify-center shrink-0" style={{ height: ITEM_H, width: 12 }}>
              <span className="text-muted-foreground font-bold text-base leading-none">:</span>
            </div>
            <TimeColumn
              items={MINUTES}
              value={minute}
              onChange={(v) => onTimeChange(to24h(h12, v, period))}
            />
            {/* AM/PM — static toggle, no scroll */}
            <div className="flex flex-col gap-1 ml-1" style={{ paddingTop: 0 }}>
              {(['AM', 'PM'] as const).map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => onTimeChange(to24h(h12, minute, p))}
                  className={cn(
                    'rounded-md px-3 text-sm font-medium transition-colors',
                    period === p
                      ? 'bg-foreground text-background'
                      : 'text-foreground/40 hover:text-foreground/70'
                  )}
                  style={{ height: ITEM_H }}
                >
                  {p}
                </button>
              ))}
            </div>
          </div>
        </PopoverContent>
      </Popover>
    </div>
  )
}
