import {
  boundaryContaining,
  jurisdictionIDsTouchedBy,
  COUNTY_EXTENT,
} from "@/lib/boundaries";
import {
  coordinatesFrom,
  fieldDate,
  fieldText,
  queryFeatures,
  type ArcGISFeature,
} from "@/lib/arcgis";
import type { City } from "@/data/cities";
import {
  outFieldsFor,
  whereClauseFor,
  type LiveCategory,
  type LiveSource,
} from "@/data/live-sources";
import { nearestDistanceInMiles, type GeoPoint } from "@/lib/geo";

/** A normalized live condition pulled from a GIS layer, ready for display. */
export interface LiveItem {
  id: string;
  title: string;
  subtitle?: string;
  detail?: string;
  impact?: string;
  schedule?: string;
  owner?: string;
  link?: string;
  category: LiveCategory;
  sourceTitle: string;
  sourceID: string;
  updatedAt?: string;
  /** Every mapped run of this work. Separate runs are never joined. */
  segments: GeoPoint[][];
  /** How many source records were folded into this row. */
  segmentCount: number;
  /** Municipality resolved from county boundary geometry, not a source field. */
  jurisdiction?: string;
  jurisdictionID?: string;
  /** Every municipality the work touches — border roads belong to both. */
  jurisdictionIDs: string[];
}

export interface LiveSourceFailure {
  id: string;
  title: string;
  message: string;
}

export interface LiveFeedResult {
  items: LiveItem[];
  failures: LiveSourceFailure[];
  fetchedAt: string;
}

/** Every mapped coordinate, used for jurisdiction and distance maths. */
export function allPoints(item: LiveItem): GeoPoint[] {
  return item.segments.flat();
}

/**
 * Midpoint of the longest run, so the pin lands on the main body of work
 * rather than on a stray stub.
 */
export function anchorOf(item: LiveItem): GeoPoint | null {
  let longest: GeoPoint[] = [];
  for (const segment of item.segments) {
    if (segment.length > longest.length) longest = segment;
  }
  if (longest.length === 0) return null;
  return longest[Math.floor(longest.length / 2)];
}

export function isInside(item: LiveItem, cityID: string): boolean {
  if (item.jurisdictionIDs.length > 0) return item.jurisdictionIDs.includes(cityID);
  return item.jurisdictionID === cityID;
}

export function hasJurisdiction(item: LiveItem): boolean {
  return Boolean(item.jurisdictionID) || item.jurisdictionIDs.length > 0;
}

/** True when the impact text indicates the road is fully shut. */
export function isFullClosure(item: LiveItem): boolean {
  const impact = item.impact?.toLowerCase();
  if (!impact) return false;
  return impact.includes("closed") || impact.includes("closure");
}

export function distanceFrom(item: LiveItem, center: GeoPoint): number | null {
  return nearestDistanceInMiles(allPoints(item), center);
}

export function matchesQuery(item: LiveItem, query: string): boolean {
  const needle = query.trim().toLowerCase();
  if (needle.length === 0) return true;
  return [
    item.title,
    item.subtitle,
    item.detail,
    item.impact,
    item.owner,
    item.sourceTitle,
    item.jurisdiction,
  ].some((field) => field?.toLowerCase().includes(needle));
}

/** County GIS stores city names in caps; soften them for display. */
function softenShouting(value: string | null): string | undefined {
  if (!value) return undefined;
  const letters = value.replace(/[^a-zA-Z]/g, "");
  if (letters.length === 0 || letters !== letters.toUpperCase()) return value;
  return value
    .toLowerCase()
    .split(" ")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

/** A project whose impact says the road is closed is really a closure. */
function resolvedCategory(source: LiveSource, impact: string | null): LiveCategory {
  if (source.category !== "project" || !impact) return source.category;
  const lower = impact.toLowerCase();
  const isClosed =
    lower.includes("closed") || lower.includes("closure") || lower.includes("detour");
  return isClosed ? "closure" : "project";
}

function scheduleText(start: string | null, finish: string | null): string | undefined {
  if (start && finish) return `${start} – ${finish}`;
  if (start) return `Starts ${start}`;
  if (finish) return `Through ${finish}`;
  return undefined;
}

function makeItem(
  feature: ArcGISFeature,
  source: LiveSource,
  index: number,
): LiveItem | null {
  const title = fieldText(feature, source.titleField);
  if (!title) return null;

  const impact = fieldText(feature, source.impactField);
  const path = coordinatesFrom(feature.geometry);
  const anchor = path.length > 0 ? path[Math.floor(path.length / 2)] : null;
  const boundary = anchor ? boundaryContaining(anchor) : null;
  const updated = fieldDate(feature, source.updatedField);

  return {
    id: `${source.id}-${index}-${title}`,
    title,
    subtitle: softenShouting(fieldText(feature, source.subtitleField)),
    detail: fieldText(feature, source.detailField) ?? undefined,
    impact: impact ?? undefined,
    schedule: scheduleText(
      fieldText(feature, source.startField),
      fieldText(feature, source.finishField),
    ),
    owner: fieldText(feature, source.ownerField) ?? undefined,
    link: fieldText(feature, source.urlField) ?? undefined,
    category: resolvedCategory(source, impact),
    sourceTitle: source.title,
    sourceID: source.id,
    updatedAt: updated?.toISOString(),
    segments: path.length > 0 ? [path] : [],
    segmentCount: 1,
    jurisdiction: boundary?.displayName,
    jurisdictionID: boundary?.cityID ?? undefined,
    jurisdictionIDs: jurisdictionIDsTouchedBy(path),
  };
}

/**
 * Turns raw features into display rows, folding a source's segmented records
 * into one row per real project when the source declares a grouping field.
 *
 * Dakota County's mill & overlay layer publishes one record per address range,
 * so a single corridor arrives as dozens of rows that all share a street name
 * and program year.
 */
export function makeItems(features: ArcGISFeature[], source: LiveSource): LiveItem[] {
  if (!source.groupField) {
    return features
      .map((feature, index) => makeItem(feature, source, index))
      .filter((item): item is LiveItem => item !== null);
  }

  const order: string[] = [];
  const buckets = new Map<string, ArcGISFeature[]>();

  for (const feature of features) {
    const title = fieldText(feature, source.titleField);
    if (!title) continue;
    const key = `${title}|${fieldText(feature, source.groupField) ?? ""}`;
    if (!buckets.has(key)) {
      buckets.set(key, []);
      order.push(key);
    }
    buckets.get(key)?.push(feature);
  }

  return order
    .map((key, index) => {
      const bucket = buckets.get(key);
      if (!bucket || bucket.length === 0) return null;
      const item = makeItem(bucket[0], source, index);
      if (!item) return null;
      if (bucket.length === 1) return item;

      const runs = bucket
        .map((feature) => coordinatesFrom(feature.geometry))
        .filter((run) => run.length > 0);

      item.segments = runs;
      item.segmentCount = bucket.length;

      // Re-resolve jurisdiction across the whole corridor, not just the first
      // record's short stretch.
      item.jurisdictionIDs = jurisdictionIDsTouchedBy(runs.flat());
      const anchor = anchorOf(item);
      const boundary = anchor ? boundaryContaining(anchor) : null;
      item.jurisdiction = boundary?.displayName;
      item.jurisdictionID = boundary?.cityID ?? undefined;
      return item;
    })
    .filter((item): item is LiveItem => item !== null);
}

/**
 * Drops records that describe the same work in the same place. Some layers
 * publish one row per status style, which would otherwise double-count.
 */
export function deduplicated(items: LiveItem[]): LiveItem[] {
  const seen = new Set<string>();
  return items.filter((item) => {
    const anchor = anchorOf(item);
    const key = [
      item.title.toLowerCase(),
      item.subtitle?.toLowerCase() ?? "",
      item.impact?.toLowerCase() ?? "",
      anchor ? anchor.latitude.toFixed(4) : "-",
      anchor ? anchor.longitude.toFixed(4) : "-",
    ].join("|");
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

const CATEGORY_RANK: Record<LiveCategory, number> = {
  closure: 0,
  trail: 1,
  project: 2,
  other: 3,
};

/** Closures first, then nearest to the selected city. */
export function sortItems(items: LiveItem[], city: City | null): LiveItem[] {
  return [...items].sort((left, right) => {
    if (left.category !== right.category) {
      return CATEGORY_RANK[left.category] - CATEGORY_RANK[right.category];
    }
    if (!city) return left.title.localeCompare(right.title);
    const a = distanceFrom(left, city.center) ?? Number.POSITIVE_INFINITY;
    const b = distanceFrom(right, city.center) ?? Number.POSITIVE_INFINITY;
    if (a === b) return left.title.localeCompare(right.title);
    return a - b;
  });
}

/** Fetches every enabled source in parallel and normalizes the results. */
export async function fetchLiveFeed(
  city: City | null,
  sources: LiveSource[],
  signal?: AbortSignal,
): Promise<LiveFeedResult> {
  const enabled = sources.filter((source) => source.isEnabled);
  if (enabled.length === 0) {
    return { items: [], failures: [], fetchedAt: new Date().toISOString() };
  }

  const settled = await Promise.all(
    enabled.map(async (source) => {
      try {
        const features = await queryFeatures({
          layerURL: source.layerURL,
          whereClause: whereClauseFor(source, city),
          outFields: outFieldsFor(source),
          resultRecordCount: source.groupField ? 1000 : 250,
          envelope: source.countyExtentOnly ? COUNTY_EXTENT : null,
          signal,
        });
        return { source, items: makeItems(features, source), error: null as string | null };
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "Couldn't reach the GIS service.";
        console.error(`Live source ${source.id} failed:`, message);
        return { source, items: [] as LiveItem[], error: message };
      }
    }),
  );

  const collected = settled.flatMap((result) => result.items);
  const failures = settled
    .filter((result) => result.error !== null)
    .map((result) => ({
      id: result.source.id,
      title: result.source.title,
      message: result.error ?? "Unknown error",
    }));

  if (collected.length === 0 && failures.length > 0) {
    throw new Error(failures[0].message);
  }

  return {
    items: sortItems(deduplicated(collected), city),
    failures,
    fetchedAt: new Date().toISOString(),
  };
}
