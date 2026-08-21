import { Link } from "react-router-dom";
import {
  ArrowUpRight,
  Building2,
  CircleAlert,
  Clock,
  Pin,
  RadioTower,
  RefreshCw,
  Table2,
} from "lucide-react";

import { PageHeader } from "@/components/PageHeader";
import { ResourceIcon } from "@/components/ResourceIcon";
import { ResourceRow } from "@/components/ResourceRow";
import { StatusChip } from "@/components/StatusChip";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { HUB_CATEGORIES, PERMIT_INBOXES, PERMIT_INBOX_TITLE } from "@/data/hub-content";
import { useHubStore } from "@/lib/hub-store";
import { distanceFrom, isInside, type LiveItem } from "@/lib/live-ops";
import { formatMiles } from "@/lib/geo";
import { useLiveFeed, useUpdates } from "@/lib/queries";
import { cn } from "@/lib/utils";

function StatCard({
  label,
  value,
  hint,
  tone,
  to,
  isLoading,
}: {
  label: string;
  value: number | string;
  hint: string;
  tone: "danger" | "amber" | "navy" | "steel";
  to: string;
  isLoading: boolean;
}) {
  const accents: Record<typeof tone, string> = {
    danger: "text-destructive",
    amber: "text-[#8A5A0B]",
    navy: "text-navy",
    steel: "text-[#28618C]",
  };

  return (
    <Link
      to={to}
      className="civic-card group flex flex-col gap-1 p-4 transition-shadow hover:shadow-[0_2px_4px_rgba(16,32,48,0.06),0_16px_28px_-20px_rgba(16,32,48,0.5)]"
    >
      <span className="flex items-center justify-between text-[11px] font-semibold uppercase tracking-wider text-ink-secondary">
        {label}
        <ArrowUpRight className="h-3.5 w-3.5 opacity-0 transition-opacity group-hover:opacity-100" />
      </span>
      {isLoading ? (
        <Skeleton className="mt-1 h-8 w-12" />
      ) : (
        <span className={cn("tabular text-3xl font-semibold", accents[tone])}>{value}</span>
      )}
      <span className="text-xs text-ink-secondary">{hint}</span>
    </Link>
  );
}

function LiveRowCompact({ item, cityCenter }: { item: LiveItem; cityCenter: { latitude: number; longitude: number } | null }) {
  const miles = cityCenter ? distanceFrom(item, cityCenter) : null;
  return (
    <Link
      to={`/live?item=${encodeURIComponent(item.id)}`}
      className="flex items-start gap-3 rounded-lg px-2.5 py-2 transition-colors hover:bg-secondary/70"
    >
      <span
        className={cn(
          "mt-1.5 h-2 w-2 shrink-0 rounded-full",
          item.category === "closure" ? "bg-destructive" : "bg-amber",
        )}
      />
      <span className="min-w-0 flex-1">
        <span className="block truncate text-sm font-medium text-ink">{item.title}</span>
        <span className="mt-0.5 block truncate text-xs text-ink-secondary">
          {[item.impact ?? item.subtitle, item.jurisdiction].filter(Boolean).join(" · ")}
        </span>
      </span>
      {miles !== null ? (
        <span className="tabular shrink-0 text-xs text-ink-secondary">{formatMiles(miles)}</span>
      ) : null}
    </Link>
  );
}

export default function Dashboard() {
  const { city, cityName, pinnedLinks, openCount } = useHubStore();
  const live = useLiveFeed();
  const updates = useUpdates();

  const items = live.data?.items ?? [];
  const inCity = city ? items.filter((item) => isInside(item, city.id)) : items;
  const closures = inCity.filter((item) => item.category === "closure");
  const projects = inCity.filter((item) => item.category === "project");
  const openPermits = PERMIT_INBOXES.reduce((total, inbox) => total + openCount(inbox), 0);
  const recentUpdates = (updates.data?.items ?? []).slice(0, 5);

  return (
    <>
      <PageHeader
        eyebrow={`${cityName} · Engineering`}
        title="Engineering Hub"
        summary="Permit resources, live road conditions and agency notices in one place."
        actions={
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              void live.refetch();
              void updates.refetch();
            }}
            disabled={live.isFetching}
            className="bg-white/10 text-white hover:bg-white/20"
          >
            <RefreshCw className={cn("mr-2 h-3.5 w-3.5", live.isFetching && "animate-spin")} />
            Refresh
          </Button>
        }
      />

      <div className="mx-auto max-w-6xl space-y-6 px-5 py-6 sm:px-8">
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <StatCard
            label="Closures"
            value={closures.length}
            hint={`In ${cityName}`}
            tone="danger"
            to="/live?category=closure"
            isLoading={live.isLoading}
          />
          <StatCard
            label="Projects"
            value={projects.length}
            hint="Active in city limits"
            tone="amber"
            to="/live?category=project"
            isLoading={live.isLoading}
          />
          <StatCard
            label="Open permits"
            value={openPermits}
            hint="Across all three inboxes"
            tone="navy"
            to="/permits"
            isLoading={false}
          />
          <StatCard
            label="Updates"
            value={updates.data?.items.length ?? 0}
            hint="City, county and MnDOT"
            tone="steel"
            to="/updates"
            isLoading={updates.isLoading}
          />
        </div>

        <div className="grid gap-6 lg:grid-cols-[1.15fr_1fr]">
          <section className="civic-card overflow-hidden">
            <header className="flex items-center justify-between border-b border-border px-4 py-3">
              <div className="flex items-center gap-2">
                <span className="relative flex h-2 w-2">
                  <span className="live-dot absolute inline-flex h-2 w-2 rounded-full" />
                  <span className="relative inline-flex h-2 w-2 rounded-full bg-amber" />
                </span>
                <h2 className="text-sm font-semibold text-ink">Live in {cityName}</h2>
              </div>
              <Link to="/live" className="text-xs font-medium text-navy hover:underline">
                Open map
              </Link>
            </header>
            <div className="p-2">
              {live.isLoading ? (
                <div className="space-y-2 p-2">
                  <Skeleton className="h-10 w-full" />
                  <Skeleton className="h-10 w-full" />
                  <Skeleton className="h-10 w-full" />
                </div>
              ) : inCity.length === 0 ? (
                <p className="px-3 py-8 text-center text-sm text-ink-secondary">
                  {live.isError
                    ? "Couldn't reach the GIS services."
                    : `Nothing currently mapped inside ${cityName}.`}
                </p>
              ) : (
                inCity
                  .slice(0, 6)
                  .map((item) => (
                    <LiveRowCompact key={item.id} item={item} cityCenter={city?.center ?? null} />
                  ))
              )}
            </div>
          </section>

          <section className="civic-card overflow-hidden">
            <header className="flex items-center justify-between border-b border-border px-4 py-3">
              <div className="flex items-center gap-2">
                <Building2 className="h-4 w-4 text-navy" />
                <h2 className="text-sm font-semibold text-ink">Latest notices</h2>
              </div>
              <Link to="/updates" className="text-xs font-medium text-navy hover:underline">
                See all
              </Link>
            </header>
            <div className="divide-y divide-border">
              {updates.isLoading ? (
                <div className="space-y-2 p-4">
                  <Skeleton className="h-10 w-full" />
                  <Skeleton className="h-10 w-full" />
                </div>
              ) : recentUpdates.length === 0 ? (
                <p className="px-4 py-8 text-center text-sm text-ink-secondary">
                  No notices published yet.
                </p>
              ) : (
                recentUpdates.map((update) => (
                  <a
                    key={update.id}
                    href={update.link ?? "#"}
                    target="_blank"
                    rel="noreferrer noopener"
                    className="block px-4 py-3 transition-colors hover:bg-secondary/60"
                  >
                    <div className="flex items-center gap-2">
                      <StatusChip
                        label={update.agency === "state" ? "MnDOT" : update.agency === "county" ? "County" : "City"}
                        tone={update.agency === "state" ? "steel" : update.agency === "county" ? "navy" : "neutral"}
                      />
                      {update.published ? (
                        <span className="tabular text-[11px] text-ink-secondary">
                          {new Date(update.published).toLocaleDateString(undefined, {
                            month: "short",
                            day: "numeric",
                          })}
                        </span>
                      ) : null}
                    </div>
                    <p className="mt-1 line-clamp-2 text-sm font-medium text-ink">{update.title}</p>
                  </a>
                ))
              )}
            </div>
          </section>
        </div>

        {pinnedLinks.length > 0 ? (
          <section className="civic-card overflow-hidden">
            <header className="flex items-center gap-2 border-b border-border px-4 py-3">
              <Pin className="h-4 w-4 text-navy" />
              <h2 className="text-sm font-semibold text-ink">Pinned</h2>
            </header>
            <div className="grid gap-0.5 p-2 sm:grid-cols-2">
              {pinnedLinks.map((link) => (
                <ResourceRow key={link.id} link={link} />
              ))}
            </div>
          </section>
        ) : null}

        <section>
          <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-ink-secondary">
            Resource areas
          </h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {HUB_CATEGORIES.map((category) => (
              <Link
                key={category.id}
                to={`/category/${category.id}`}
                className="civic-card group flex gap-3 p-4 transition-shadow hover:shadow-[0_2px_4px_rgba(16,32,48,0.06),0_16px_28px_-20px_rgba(16,32,48,0.5)]"
              >
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-navy/8 text-navy">
                  <ResourceIcon name={category.icon} className="h-5 w-5" />
                </span>
                <span className="min-w-0">
                  <span className="block text-sm font-semibold text-ink">{category.title}</span>
                  <span className="mt-1 block text-xs leading-relaxed text-ink-secondary">
                    {category.summary}
                  </span>
                </span>
              </Link>
            ))}
          </div>
        </section>

        <section className="civic-card overflow-hidden">
          <header className="flex items-center justify-between border-b border-border px-4 py-3">
            <div className="flex items-center gap-2">
              <Table2 className="h-4 w-4 text-navy" />
              <h2 className="text-sm font-semibold text-ink">Permit inboxes</h2>
            </div>
            <Link to="/permits" className="text-xs font-medium text-navy hover:underline">
              Open tracking
            </Link>
          </header>
          <div className="grid divide-y divide-border sm:grid-cols-3 sm:divide-x sm:divide-y-0">
            {PERMIT_INBOXES.map((inbox) => (
              <div key={inbox} className="px-4 py-3">
                <p className="text-xs font-medium text-ink-secondary">{PERMIT_INBOX_TITLE[inbox]}</p>
                <p className="tabular mt-1 text-2xl font-semibold text-navy">{openCount(inbox)}</p>
                <p className="text-[11px] text-ink-secondary">open items</p>
              </div>
            ))}
          </div>
        </section>

        {live.data?.failures.length ? (
          <div className="flex items-start gap-2 rounded-lg border border-destructive/25 bg-destructive/5 px-4 py-3">
            <CircleAlert className="mt-0.5 h-4 w-4 shrink-0 text-destructive" />
            <div className="text-xs text-ink">
              <p className="font-semibold text-destructive">Some layers didn't respond</p>
              <p className="mt-0.5 text-ink-secondary">
                {live.data.failures.map((failure) => failure.title).join(", ")} — showing
                everything else.
              </p>
            </div>
          </div>
        ) : null}

        {live.data?.fetchedAt ? (
          <p className="flex items-center justify-center gap-1.5 pb-2 text-[11px] text-ink-secondary">
            <Clock className="h-3 w-3" />
            Live data checked {new Date(live.data.fetchedAt).toLocaleTimeString()}
            <RadioTower className="ml-1 h-3 w-3" />
            Dakota County GIS · MnDOT 511
          </p>
        ) : null}
      </div>
    </>
  );
}
