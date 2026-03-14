export default function AdminUsersLoading() {
  return (
    <div className="space-y-6">
      <div className="h-8 w-32 bg-muted animate-pulse rounded-md" />
      <div className="rounded-lg border bg-card divide-y">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="flex items-center gap-4 px-4 py-3.5">
            <div className="h-9 w-9 bg-muted animate-pulse rounded-full shrink-0" />
            <div className="flex-1 space-y-1.5">
              <div className="h-4 w-40 bg-muted animate-pulse rounded" />
              <div className="h-3 w-28 bg-muted animate-pulse rounded" />
            </div>
            <div className="h-5 w-20 bg-muted animate-pulse rounded-full" />
            <div className="h-5 w-16 bg-muted animate-pulse rounded-full" />
            <div className="h-8 w-8 bg-muted animate-pulse rounded" />
          </div>
        ))}
      </div>
    </div>
  )
}
