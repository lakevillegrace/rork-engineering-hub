import { useMemo, useState } from "react";
import { CircleAlert, ExternalLink, RefreshCw, Search } from "lucide-react";

import { PageHeader } from "@/components/PageHeader";
import { StatusChip } from "@/components/StatusChip";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { useHubStore } from "@/lib/hub-store";
import { useUpdates } from "@/lib/queries";
import { AGENCY_LABEL, matchesUpdateQuery, type UpdateAgency } from "@/lib/updates";
import { cn } from "@/lib/utils";

const FILTERS: (UpdateAgency | "all")[] = ["all", "city", "county", "state"];

function relativeDate(iso: string | undefined): string {
  if (!iso) return "Undated";
  const timestamp = Date.parse(iso);
  if (Number.isNaN(timestamp)) return "Undated";

  const days = Math.floor((Date.now() - timestamp) / 86_400_000);
  if (days <= 0) return "Today";
  if (days === 1) return "Yesterday";
  if (days < 7) return `${days} days ago`;
  return new Date(timestamp).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export default function Updates() {
  const { cityName } = useHubStore();
  const { data, isLoading, isFetching, refetch } = useUpdates();
  const [agency, setAgency] = useState<UpdateAgency | "all">("all");
  const [query, setQuery] = useState("");

  const items = useMemo(() => data?.items ?? [], [data]);

  const filtered = useMemo(
    () =>
      items.filter(
        (item) => (agency === "all" || item.agency === agency) && matchesUpdateQuery(item, query),
      ),
    [items, agency, query],
  );

  const counts = useMemo(
    () => ({
      all: items.length,
      city: items.filter((item) => item.agency === "city").length,
      county: items.filter((item) => item.agency === "county").length,
      state: items.filter((item) => item.agency === "state").length,
    }),
    [items],
  );

  return (
    <>
      <PageHeader
        eyebrow="One dated list"
        title="Agency Updates"
        summary={`${cityName} news and alerts, county project revisions and MnDOT 511 events — every item links back to the agency that published it.`}
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

      <div className="mx-auto max-w-4xl space-y-4 px-5 py-6 sm:px-8">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className="relative flex-1">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-secondary" />
            <Input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search notices…"
              className="bg-card pl-9"
            />
          </div>
          <div className="flex flex-wrap gap-1.5">
            {FILTERS.map((option) => (
              <button
                key={option}
                type="button"
                onClick={() => setAgency(option)}
                className={cn(
                  "rounded-full border px-3 py-1.5 text-xs font-semibold transition-colors",
                  agency === option
                    ? "border-navy bg-navy text-white"
                    : "border-border bg-card text-ink-secondary hover:border-navy/40",
                )}
              >
                {option === "all" ? "All" : AGENCY_LABEL[option]}
                <span className="tabular ml-1.5 opacity-70">{counts[option]}</span>
              </button>
            ))}
          </div>
        </div>

        {data?.failedFeeds.length ? (
          <div className="flex items-start gap-2 rounded-lg border border-amber/40 bg-amber/10 px-4 py-3">
            <CircleAlert className="mt-0.5 h-4 w-4 shrink-0 text-[#8A5A0B]" />
            <p className="text-xs text-ink-secondary">
              Couldn't reach {data.failedFeeds.join(", ")}. Everything else is current.
            </p>
          </div>
        ) : null}

        {isLoading ? (
          <div className="space-y-3">
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-24 w-full" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="civic-card px-6 py-16 text-center">
            <p className="text-sm font-medium text-ink">No notices to show</p>
            <p className="mt-1 text-xs text-ink-secondary">
              Nothing matched those filters. Agency feeds refresh every few minutes.
            </p>
          </div>
        ) : (
          <ol className="space-y-2.5">
            {filtered.map((item) => {
              const content = (
                <>
                  <div className="flex flex-wrap items-center gap-2">
                    <StatusChip
                      label={AGENCY_LABEL[item.agency]}
                      tone={
                        item.agency === "state" ? "steel" : item.agency === "county" ? "navy" : "neutral"
                      }
                    />
                    {item.isFieldImpact ? <StatusChip label="Field impact" tone="amber" /> : null}
                    <span className="tabular text-[11px] text-ink-secondary">
                      {relativeDate(item.published)}
                    </span>
                    <span className="text-[11px] text-ink-secondary">· {item.sourceTitle}</span>
                  </div>
                  <p className="mt-1.5 text-sm font-semibold leading-snug text-ink">{item.title}</p>
                  {item.summary ? (
                    <p className="mt-1 line-clamp-3 text-xs leading-relaxed text-ink-secondary">
                      {item.summary}
                    </p>
                  ) : null}
                </>
              );

              return (
                <li
                  key={item.id}
                  className={cn("civic-card p-4", item.isFieldImpact && "rule-amber")}
                >
                  {item.link ? (
                    <a
                      href={item.link}
                      target="_blank"
                      rel="noreferrer noopener"
                      className="group block"
                    >
                      {content}
                      <span className="mt-2 inline-flex items-center gap-1 text-xs font-medium text-navy group-hover:underline">
                        Open on {item.sourceTitle}
                        <ExternalLink className="h-3 w-3" />
                      </span>
                    </a>
                  ) : (
                    content
                  )}
                </li>
              );
            })}
          </ol>
        )}

        <p className="pb-4 text-center text-[11px] leading-relaxed text-ink-secondary">
          Sources: Lakeville News Flash, Alert Center and Meetings (city RSS), Dakota County
          project revisions from the county's own GIS, and MnDOT 511 traveler events. Nothing on
          this page is written by the app.
        </p>
      </div>
    </>
  );
}
