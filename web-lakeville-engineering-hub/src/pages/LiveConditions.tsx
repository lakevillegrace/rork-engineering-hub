import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import {
  CircleAlert,
  ExternalLink,
  Layers,
  RefreshCw,
  Search,
  SlidersHorizontal,
  X,
} from "lucide-react";

import { ConditionsMap } from "@/components/ConditionsMap";
import { PageHeader } from "@/components/PageHeader";
import { StatusChip } from "@/components/StatusChip";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Switch } from "@/components/ui/switch";
import { LIVE_CATEGORY_SINGULAR, type LiveCategory } from "@/data/live-sources";
import { formatMiles } from "@/lib/geo";
import { useHubStore } from "@/lib/hub-store";
import {
  distanceFrom,
  hasJurisdiction,
  isInside,
  matchesQuery,
  type LiveItem,
} from "@/lib/live-ops";
import { useLiveFeed } from "@/lib/queries";
import { cn } from "@/lib/utils";

type ScopeFilter = "city" | "county";
const CATEGORY_FILTERS: (LiveCategory | "all")[] = ["all", "closure", "project", "trail"];

function toneFor(item: LiveItem): "danger" | "amber" | "steel" {
  if (item.category === "closure") return "danger";
  if (item.category === "trail") return "steel";
  return "amber";
}

function ItemCard({
  item,
  isSelected,
  distance,
  onSelect,
}: {
  item: LiveItem;
  isSelected: boolean;
  distance: number | null;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      className={cn(
        "w-full border-l-2 px-4 py-3 text-left transition-colors",
        isSelected
          ? "border-l-navy bg-navy/[0.045]"
          : "border-l-transparent hover:bg-secondary/60",
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-1.5">
            <StatusChip label={LIVE_CATEGORY_SINGULAR[item.category]} tone={toneFor(item)} />
            {item.segmentCount > 1 ? (
              <StatusChip label={`${item.segmentCount} segments`} tone="neutral" />
            ) : null}
          </div>
          <p className="mt-1.5 truncate text-sm font-semibold text-ink">{item.title}</p>
          {item.subtitle ? (
            <p className="mt-0.5 line-clamp-2 text-xs text-ink-secondary">{item.subtitle}</p>
          ) : null}
          <div className="mt-1.5 flex flex-wrap items-center gap-x-2 gap-y-1 text-[11px] text-ink-secondary">
            {item.jurisdiction ? <span>{item.jurisdiction}</span> : null}
            {item.schedule ? <span>· {item.schedule}</span> : null}
          </div>
        </div>
        {distance !== null ? (
          <span className="tabular shrink-0 text-xs font-medium text-ink-secondary">
            {formatMiles(distance)}
          </span>
        ) : null}
      </div>
    </button>
  );
}

function DetailPanel({ item, onClose }: { item: LiveItem; onClose: () => void }) {
  return (
    <div className="civic-card absolute bottom-4 left-4 right-4 z-[1000] max-h-[52%] overflow-y-auto p-4 sm:max-w-md">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-1.5">
            <StatusChip label={LIVE_CATEGORY_SINGULAR[item.category]} tone={toneFor(item)} />
            {item.segmentCount > 1 ? (
              <StatusChip label={`Mapped as ${item.segmentCount} segments`} tone="neutral" />
            ) : null}
          </div>
          <h3 className="mt-2 text-base font-semibold text-ink">{item.title}</h3>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="rounded-md p-1 text-ink-secondary hover:bg-secondary"
          aria-label="Close details"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      <dl className="mt-3 space-y-2 text-sm">
        {[
          ["Location", item.subtitle],
          ["Work", item.detail],
          ["Impact", item.impact],
          ["Schedule", item.schedule],
          ["Contact", item.owner],
          ["Jurisdiction", item.jurisdiction],
          ["Source", item.sourceTitle],
        ]
          .filter(([, value]) => Boolean(value))
          .map(([label, value]) => (
            <div key={label} className="flex gap-3">
              <dt className="w-24 shrink-0 text-xs font-medium uppercase tracking-wide text-ink-secondary">
                {label}
              </dt>
              <dd className="min-w-0 flex-1 text-ink">{value}</dd>
            </div>
          ))}
      </dl>

      {item.link ? (
        <a
          href={item.link}
          target="_blank"
          rel="noreferrer noopener"
          className="mt-3 inline-flex items-center gap-1.5 text-sm font-medium text-navy hover:underline"
        >
          Open source page
          <ExternalLink className="h-3.5 w-3.5" />
        </a>
      ) : null}
    </div>
  );
}

export default function LiveConditions() {
  const { city, cityName } = useHubStore();
  const { data, isLoading, isFetching, isError, error, refetch } = useLiveFeed();
  const [searchParams, setSearchParams] = useSearchParams();

  const [scope, setScope] = useState<ScopeFilter>("city");
  const [category, setCategory] = useState<LiveCategory | "all">(
    (searchParams.get("category") as LiveCategory | null) ?? "all",
  );
  const [query, setQuery] = useState("");
  const [showBoundaries, setShowBoundaries] = useState(true);
  const [selectedID, setSelectedID] = useState<string | null>(searchParams.get("item"));

  // Deep links from the dashboard arrive as ?item= / ?category=.
  useEffect(() => {
    const item = searchParams.get("item");
    if (item) setSelectedID(item);
  }, [searchParams]);

  const items = useMemo(() => data?.items ?? [], [data]);

  const filtered = useMemo(() => {
    return items.filter((item) => {
      if (category !== "all" && item.category !== category) return false;
      if (!matchesQuery(item, query)) return false;
      if (scope === "city" && city) {
        // Items with no mapped geometry can't be placed, so they stay visible
        // rather than disappearing from the city view entirely.
        if (hasJurisdiction(item)) return isInside(item, city.id);
        return true;
      }
      return true;
    });
  }, [items, category, query, scope, city]);

  const selected = useMemo(
    () => filtered.find((item) => item.id === selectedID) ?? null,
    [filtered, selectedID],
  );

  const counts = useMemo(() => {
    const scoped = items.filter((item) =>
      scope === "city" && city ? (hasJurisdiction(item) ? isInside(item, city.id) : true) : true,
    );
    return {
      all: scoped.length,
      closure: scoped.filter((item) => item.category === "closure").length,
      project: scoped.filter((item) => item.category === "project").length,
      trail: scoped.filter((item) => item.category === "trail").length,
    };
  }, [items, scope, city]);

  function selectItem(item: LiveItem) {
    setSelectedID(item.id);
    const next = new URLSearchParams(searchParams);
    next.set("item", item.id);
    setSearchParams(next, { replace: true });
  }

  return (
    <div className="flex h-full flex-col">
      <PageHeader
        eyebrow="Field conditions"
        title="Live Conditions"
        summary="Dakota County construction and paving programs plus MnDOT 511 events, placed against municipal boundaries."
        actions={
          <Button
            variant="secondary"
            size="sm"
            onClick={() => void refetch()}
            disabled={isFetching}
            className="bg-white/10 text-white hover:bg-white/20"
          >
            <RefreshCw className={cn("mr-2 h-3.5 w-3.5", isFetching && "animate-spin")} />
            Refresh
          </Button>
        }
      />

      <div className="flex flex-1 flex-col overflow-hidden lg:flex-row">
        {/* List */}
        <div className="flex w-full shrink-0 flex-col border-b border-border bg-card lg:w-[420px] lg:border-b-0 lg:border-r">
          <div className="space-y-3 border-b border-border p-4">
            <div className="relative">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-secondary" />
              <Input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search streets, impacts, contacts…"
                className="pl-9"
              />
            </div>

            <div className="flex items-center gap-1 rounded-lg bg-secondary p-1">
              {(["city", "county"] as ScopeFilter[]).map((option) => (
                <button
                  key={option}
                  type="button"
                  onClick={() => setScope(option)}
                  className={cn(
                    "flex-1 rounded-md px-3 py-1.5 text-xs font-semibold transition-colors",
                    scope === option
                      ? "bg-card text-navy shadow-sm"
                      : "text-ink-secondary hover:text-ink",
                  )}
                >
                  {option === "city" ? cityName : "Whole county"}
                </button>
              ))}
            </div>

            <div className="flex flex-wrap gap-1.5">
              {CATEGORY_FILTERS.map((option) => (
                <button
                  key={option}
                  type="button"
                  onClick={() => setCategory(option)}
                  className={cn(
                    "rounded-full border px-2.5 py-1 text-[11px] font-semibold transition-colors",
                    category === option
                      ? "border-navy bg-navy text-white"
                      : "border-border bg-card text-ink-secondary hover:border-navy/40",
                  )}
                >
                  {option === "all" ? "All" : LIVE_CATEGORY_SINGULAR[option].split(" ")[0]}
                  <span className="tabular ml-1.5 opacity-70">{counts[option]}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="flex-1 divide-y divide-border overflow-y-auto">
            {isLoading ? (
              <div className="space-y-3 p-4">
                <Skeleton className="h-20 w-full" />
                <Skeleton className="h-20 w-full" />
                <Skeleton className="h-20 w-full" />
              </div>
            ) : isError ? (
              <div className="flex flex-col items-center gap-2 px-6 py-12 text-center">
                <CircleAlert className="h-6 w-6 text-destructive" />
                <p className="text-sm font-medium text-ink">Couldn't reach the GIS services</p>
                <p className="text-xs text-ink-secondary">{error?.message}</p>
                <Button size="sm" variant="outline" onClick={() => void refetch()}>
                  Try again
                </Button>
              </div>
            ) : filtered.length === 0 ? (
              <p className="px-6 py-12 text-center text-sm text-ink-secondary">
                Nothing matches those filters.
              </p>
            ) : (
              filtered.map((item) => (
                <ItemCard
                  key={item.id}
                  item={item}
                  isSelected={item.id === selectedID}
                  distance={city ? distanceFrom(item, city.center) : null}
                  onSelect={() => selectItem(item)}
                />
              ))
            )}
          </div>

          {data?.failures.length ? (
            <div className="flex items-start gap-2 border-t border-border bg-destructive/5 px-4 py-2.5">
              <CircleAlert className="mt-0.5 h-3.5 w-3.5 shrink-0 text-destructive" />
              <p className="text-[11px] text-ink-secondary">
                {data.failures.map((failure) => failure.title).join(", ")} didn't respond.
              </p>
            </div>
          ) : null}
        </div>

        {/* Map */}
        <div className="relative min-h-[420px] flex-1">
          <ConditionsMap
            items={filtered}
            selectedID={selectedID}
            onSelect={selectItem}
            cityID={city?.id ?? null}
            showBoundaries={showBoundaries}
            className="h-full w-full"
          />

          <div className="civic-card absolute right-4 top-4 z-[1000] flex items-center gap-2.5 px-3 py-2">
            <Layers className="h-4 w-4 text-navy" />
            <span className="text-xs font-medium text-ink">Boundaries</span>
            <Switch checked={showBoundaries} onCheckedChange={setShowBoundaries} />
          </div>

          <div className="civic-card absolute left-4 top-4 z-[1000] flex items-center gap-2 px-3 py-2">
            <SlidersHorizontal className="h-3.5 w-3.5 text-ink-secondary" />
            <span className="tabular text-xs text-ink-secondary">
              {filtered.length} shown
            </span>
          </div>

          {selected ? (
            <DetailPanel item={selected} onClose={() => setSelectedID(null)} />
          ) : null}
        </div>
      </div>
    </div>
  );
}
