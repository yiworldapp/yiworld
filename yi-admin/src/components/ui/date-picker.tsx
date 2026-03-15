'use client'

import * as React from 'react'
import { format, parse, isValid } from 'date-fns'
import { CalendarIcon } from 'lucide-react'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Calendar } from '@/components/ui/calendar'
import { cn } from '@/lib/utils'

interface DatePickerProps {
  date: string // YYYY-MM-DD
  onDateChange: (date: string) => void
  placeholder?: string
}

export function DatePicker({ date, onDateChange, placeholder = 'Pick a date' }: DatePickerProps) {
  const [open, setOpen] = React.useState(false)

  const parsed = date ? parse(date, 'yyyy-MM-dd', new Date()) : null
  const displayDate = parsed && isValid(parsed) ? format(parsed, 'dd MMM yyyy') : null

  function handleSelect(day: Date | undefined) {
    if (day) {
      onDateChange(format(day, 'yyyy-MM-dd'))
      setOpen(false)
    }
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        className={cn(
          'flex w-full items-center gap-2 rounded-lg border border-input bg-transparent px-2.5 h-8 text-sm text-left font-normal transition-colors cursor-pointer outline-none',
          'hover:bg-accent focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50',
          !displayDate && 'text-muted-foreground'
        )}
      >
        <CalendarIcon className="h-4 w-4 shrink-0 text-muted-foreground" />
        {displayDate ?? placeholder}
      </PopoverTrigger>
      <PopoverContent className="w-auto p-0" align="start">
        <Calendar
          mode="single"
          selected={parsed && isValid(parsed) ? parsed : undefined}
          onSelect={handleSelect}
          initialFocus
        />
      </PopoverContent>
    </Popover>
  )
}
