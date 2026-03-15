function Skeleton({ className }: { className?: string }) {
  return <div className={`bg-muted animate-pulse rounded ${className ?? ''}`} />
}

function CardSkeleton({ rows = 3 }: { rows?: number }) {
  return (
    <div className="rounded-lg border bg-card">
      <div className="px-4 pt-4 pb-2">
        <Skeleton className="h-3 w-24" />
      </div>
      <div className="px-4 pb-4 space-y-3">
        {Array.from({ length: rows }).map((_, i) => (
          <div key={i} className="flex justify-between items-center py-2 border-b border-border/50 last:border-0">
            <Skeleton className="h-4 w-24" />
            <Skeleton className="h-4 w-32" />
          </div>
        ))}
      </div>
    </div>
  )
}

export default function MemberDetailLoading() {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Skeleton className="h-8 w-8 rounded-md" />
        <div className="flex-1 space-y-1.5">
          <Skeleton className="h-7 w-48" />
          <Skeleton className="h-4 w-36" />
        </div>
        <Skeleton className="h-8 w-16 rounded-md" />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="space-y-4 lg:col-span-1">
          <div className="rounded-lg border bg-card">
            <div className="pt-6 flex flex-col items-center gap-4 pb-6 px-4">
              <Skeleton className="h-24 w-24 rounded-full" />
              <div className="space-y-2 w-full flex flex-col items-center">
                <Skeleton className="h-5 w-36" />
                <Skeleton className="h-4 w-28" />
              </div>
              <div className="flex gap-2">
                <Skeleton className="h-5 w-16 rounded-full" />
                <Skeleton className="h-5 w-20 rounded-full" />
              </div>
            </div>
          </div>
          <CardSkeleton rows={4} />
        </div>
        <div className="lg:col-span-2 space-y-4">
          <CardSkeleton rows={4} />
          <CardSkeleton rows={5} />
          <CardSkeleton rows={4} />
          <CardSkeleton rows={3} />
        </div>
      </div>
    </div>
  )
}
