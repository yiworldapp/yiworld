export default function PrivilegesLoading() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="h-8 w-28 bg-muted animate-pulse rounded-md" />
        <div className="h-9 w-32 bg-muted animate-pulse rounded-md" />
      </div>
      <div className="flex gap-2">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-9 w-24 bg-muted animate-pulse rounded-md" />
        ))}
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="rounded-lg border bg-card p-4 space-y-3">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 bg-muted animate-pulse rounded-full" />
              <div className="flex-1 space-y-1.5">
                <div className="h-4 w-32 bg-muted animate-pulse rounded" />
                <div className="h-3 w-20 bg-muted animate-pulse rounded" />
              </div>
            </div>
            <div className="h-3 w-full bg-muted animate-pulse rounded" />
            <div className="h-3 w-3/4 bg-muted animate-pulse rounded" />
          </div>
        ))}
      </div>
    </div>
  )
}
