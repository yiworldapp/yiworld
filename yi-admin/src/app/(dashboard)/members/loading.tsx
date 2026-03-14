export default function MembersLoading() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="h-8 w-28 bg-muted animate-pulse rounded-md" />
      </div>
      <div className="rounded-lg border bg-card">
        <div className="p-4 border-b flex items-center gap-3">
          <div className="h-9 flex-1 bg-muted animate-pulse rounded-md" />
          <div className="h-9 w-24 bg-muted animate-pulse rounded-md" />
        </div>
        <div className="divide-y">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="flex items-center gap-4 px-4 py-3">
              <div className="h-9 w-9 bg-muted animate-pulse rounded-full shrink-0" />
              <div className="flex-1 space-y-1.5">
                <div className="h-4 w-36 bg-muted animate-pulse rounded" />
                <div className="h-3 w-24 bg-muted animate-pulse rounded" />
              </div>
              <div className="h-5 w-16 bg-muted animate-pulse rounded-full" />
              <div className="h-4 w-20 bg-muted animate-pulse rounded" />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
