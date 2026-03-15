function Skeleton({ className }: { className?: string }) {
  return <div className={`bg-muted animate-pulse rounded ${className ?? ''}`} />
}

function SectionSkeleton({ fields = 2 }: { fields?: number }) {
  return (
    <div className="rounded-lg border bg-card">
      <div className="px-4 pt-4 pb-2">
        <Skeleton className="h-3 w-28" />
      </div>
      <div className="px-4 pb-4 space-y-4">
        {Array.from({ length: fields }).map((_, i) => (
          <div key={i} className="space-y-1.5">
            <Skeleton className="h-3.5 w-20" />
            <Skeleton className="h-8 w-full rounded-md" />
          </div>
        ))}
      </div>
    </div>
  )
}

export default function EditMemberLoading() {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Skeleton className="h-8 w-8 rounded-md" />
        <div className="space-y-1.5">
          <Skeleton className="h-7 w-36" />
          <Skeleton className="h-4 w-28" />
        </div>
      </div>
      <div className="space-y-4 w-full">
        <SectionSkeleton fields={3} />
        <SectionSkeleton fields={4} />
        <SectionSkeleton fields={6} />
        <SectionSkeleton fields={3} />
        <SectionSkeleton fields={4} />
        <SectionSkeleton fields={2} />
      </div>
    </div>
  )
}
