'use client'

import Link from 'next/link'
import { cn } from '@/lib/utils'
import { buttonVariants } from '@/components/ui/button'
import type { VariantProps } from 'class-variance-authority'

interface LinkButtonProps extends VariantProps<typeof buttonVariants> {
  href: string
  className?: string
  children: React.ReactNode
  target?: string
  rel?: string
}

export function LinkButton({ href, variant, size, className, children, target, rel }: LinkButtonProps) {
  if (href.startsWith('http') || target) {
    return (
      <a href={href} target={target} rel={rel} className={cn(buttonVariants({ variant, size }), className)}>
        {children}
      </a>
    )
  }
  return (
    <Link href={href} prefetch={true} className={cn(buttonVariants({ variant, size }), className)}>
      {children}
    </Link>
  )
}
