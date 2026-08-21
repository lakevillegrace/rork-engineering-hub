import type { City } from "@/data/cities";
import { type LiveItem } from "@/lib/live-ops";

export type UpdateAgency = "city" | "county" | "state";

export const AGENCY_LABEL: Record<UpdateAgency, string> = {
  city: "City",
  county: "County",
  state: "MnDOT",
};

/** A dated notice pulled from an agency feed or from live GIS data. */
export interface UpdateItem {
  id: string;
  title: string;
  summary?: string;
  link?: string;
  published?: string;
  agency: UpdateAgency;
  sourceTitle: string;
  /** True for items describing active field impact rather than general news. */
  isFieldImpact: boolean;
}

export interface UpdateFeed {
  id: string;
  title: string;
  url: string;
  agency: UpdateAgency;
}

export interface UpdatesResult {
  items: UpdateItem[];
  failedFeeds: string[];
  fetchedAt: string;
}

/**
 * Verified public feeds, keyed by the city they belong to.
 *
 * Only feeds confirmed to return real items are listed; a city with no
 * published feed shows nothing rather than a broken source.
 */
export function feedsFor(cityID: string | null | undefined): UpdateFeed[] {
  if (cityID !== "lakeville") return [];
  return [
    {
      id: "lakeville-news",
      title: "Lakeville News Flash",
      url: "https://www.lakevillemn.gov/RSSFeed.aspx?ModID=1&CID=All-0",
      agency: "city",
    },
    {
      id: "lakeville-alerts",
      title: "Lakeville Alert Center",
      url: "https://www.lakevillemn.gov/RSSFeed.aspx?ModID=76&CID=All-0",
      agency: "city",
    },
    {
      id: "lakeville-calendar",
      title: "Lakeville Meetings & Calendar",
      url: "https://www.lakevillemn.gov/RSSFeed.aspx?ModID=58&CID=All-0",
      agency: "city",
    },
  ];
}

const FUNCTIONS_URL: string =
  import.meta.env.VITE_RORK_FUNCTIONS_URL ?? "https://engineering-hub-backend.rork.app";

/**
 * City RSS is served without CORS headers, so the browser cannot read it
 * directly. The project's Worker fetches the allow-listed feed and hands it
 * back with the headers a browser needs.
 */
function proxiedFeedURL(feedURL: string): string {
  return `${FUNCTIONS_URL}/feed?url=${encodeURIComponent(feedURL)}`;
}

function textOf(element: Element, tag: string): string {
  return element.getElementsByTagName(tag)[0]?.textContent?.trim() ?? "";
}

/** Strips markup and entity noise out of CivicPlus description blocks. */
function plainText(html: string): string {
  if (html.length === 0) return "";
  const parsed = new DOMParser().parseFromString(html, "text/html");
  return (parsed.body.textContent ?? "").replace(/\s+/g, " ").trim();
}

function parseFeed(xml: string, feed: UpdateFeed): UpdateItem[] {
  const document = new DOMParser().parseFromString(xml, "text/xml");
  if (document.getElementsByTagName("parsererror").length > 0) return [];

  const nodes = Array.from(document.getElementsByTagName("item"));
  return nodes.flatMap((node) => {
    const title = textOf(node, "title");
    if (title.length === 0) return [];

    const link = textOf(node, "link");
    const guid = textOf(node, "guid");
    const pubDate = textOf(node, "pubDate");
    const parsedDate = pubDate.length > 0 ? new Date(pubDate) : null;
    const summary = plainText(textOf(node, "description"));

    return [
      {
        id: `${feed.id}-${guid.length > 0 ? guid : link + title}`,
        title,
        summary: summary.length > 0 ? summary : undefined,
        link: link.length > 0 ? link : undefined,
        published:
          parsedDate && !Number.isNaN(parsedDate.getTime())
            ? parsedDate.toISOString()
            : undefined,
        agency: feed.agency,
        sourceTitle: feed.title,
        isFieldImpact: false,
      },
    ];
  });
}

/** MnDOT 511 events already fetched for the map, presented as state notices. */
function stateUpdates(liveItems: LiveItem[]): UpdateItem[] {
  return liveItems
    .filter((item) => item.sourceTitle.includes("511"))
    .map((item) => ({
      id: `mndot-${item.id}`,
      title: item.title,
      summary: [item.impact, item.detail, item.jurisdiction].filter(Boolean).join(" · "),
      link: item.link,
      published: item.updatedAt,
      agency: "state" as const,
      sourceTitle: "MnDOT 511",
      isFieldImpact: true,
    }));
}

/** County projects the county itself revised in the last 90 days. */
function countyUpdates(liveItems: LiveItem[]): UpdateItem[] {
  const cutoff = Date.now() - 90 * 24 * 60 * 60 * 1000;
  return liveItems
    .filter((item) => item.sourceTitle.includes("Dakota County"))
    .filter((item) => (item.updatedAt ? Date.parse(item.updatedAt) >= cutoff : false))
    .map((item) => ({
      id: `county-${item.id}`,
      title: item.title,
      summary: [item.subtitle, item.detail, item.schedule].filter(Boolean).join(" · "),
      link: item.link,
      published: item.updatedAt,
      agency: "county" as const,
      sourceTitle: item.sourceTitle,
      isFieldImpact: true,
    }));
}

function deduplicated(items: UpdateItem[]): UpdateItem[] {
  const seen = new Set<string>();
  return items.filter((item) => {
    const key = `${item.agency}|${item.title.toLowerCase()}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

export function matchesUpdateQuery(item: UpdateItem, query: string): boolean {
  const needle = query.trim().toLowerCase();
  if (needle.length === 0) return true;
  return [item.title, item.summary, item.sourceTitle].some((field) =>
    field?.toLowerCase().includes(needle),
  );
}

/**
 * Gathers agency notices from public feeds and from the live GIS data already
 * on hand, so staff get one dated list instead of checking three websites.
 */
export async function fetchUpdates(
  city: City | null,
  liveItems: LiveItem[],
  signal?: AbortSignal,
): Promise<UpdatesResult> {
  const feeds = feedsFor(city?.id);

  const settled = await Promise.all(
    feeds.map(async (feed) => {
      try {
        const response = await fetch(proxiedFeedURL(feed.url), { signal });
        if (!response.ok) return { feed, items: null };
        return { feed, items: parseFeed(await response.text(), feed) };
      } catch (error) {
        console.error(
          `Feed ${feed.id} failed:`,
          error instanceof Error ? error.message : error,
        );
        return { feed, items: null };
      }
    }),
  );

  const collected = [
    ...settled.flatMap((result) => result.items ?? []),
    ...stateUpdates(liveItems),
    ...countyUpdates(liveItems),
  ];

  return {
    items: deduplicated(collected).sort((left, right) => {
      const a = left.published ? Date.parse(left.published) : 0;
      const b = right.published ? Date.parse(right.published) : 0;
      return b - a;
    }),
    failedFeeds: settled
      .filter((result) => result.items === null)
      .map((result) => result.feed.title),
    fetchedAt: new Date().toISOString(),
  };
}
