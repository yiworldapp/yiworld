export default function NewEventLoading() {
  return (
    <div className="space-y-6">
      <div>
        <div className="h-8 w-36 bg-muted animate-pulse rounded-md" />
        <div className="h-4 w-52 bg-muted animate-pulse rounded mt-1.5" />
      </div>
      <div className="rounded-lg border bg-card p-6 space-y-5">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="space-y-1.5">
            <div className="h-4 w-24 bg-muted animate-pulse rounded" />
            <div className="h-10 w-full bg-muted animate-pulse rounded-md" />
          </div>
        ))}
        <div className="flex justify-end gap-2 pt-2">
          <div className="h-9 w-20 bg-muted animate-pulse rounded-md" />
          <div className="h-9 w-28 bg-muted animate-pulse rounded-md" />
        </div>
      </div>
    </div>
  )
}
