import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import { cityByID, cityDisplayName, DEFAULT_CITY_ID, type City } from "@/data/cities";
import {
  ALL_LINKS,
  categoryTitleForLink,
  seedPermits,
  type PermitInbox,
  type PermitRecord,
  type PermitStatus,
  type ResourceLink,
  OPEN_PERMIT_STATUSES,
} from "@/data/hub-content";
import { BUILT_IN_SOURCES, type LiveSource } from "@/data/live-sources";

const STORAGE_KEYS = {
  city: "hub.selectedCity",
  urls: "hub.resourceURLs",
  pinned: "hub.pinnedLinks",
  checklists: "hub.checklistProgress",
  permits: "hub.permits",
  sources: "hub.customSources",
  disabled: "hub.disabledSources",
} as const;

function readStored<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;
  try {
    const raw = window.localStorage.getItem(key);
    if (raw === null) return fallback;
    return JSON.parse(raw) as T;
  } catch (error) {
    console.error(`Couldn't read ${key} from local storage.`, error);
    return fallback;
  }
}

function writeStored<T>(key: string, value: T): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch (error) {
    console.error(`Couldn't save ${key} to local storage.`, error);
  }
}

/** Adds an https scheme when staff paste a bare host. */
export function normalizeURL(raw: string): string {
  const lower = raw.toLowerCase();
  if (lower.startsWith("http://") || lower.startsWith("https://")) return raw;
  return `https://${raw}`;
}

// MARK: - Shareable configuration

export interface ConfiguredLink {
  id: string;
  title: string;
  category: string;
  url: string;
}

/**
 * A shareable snapshot of everything a staff member has configured.
 *
 * The shape matches the iOS app's export byte for byte, so a file made on a
 * phone imports here and vice versa.
 */
export interface HubConfiguration {
  formatVersion: number;
  exportedAt: string;
  cityID?: string;
  cityName?: string;
  links: ConfiguredLink[];
  pinnedLinkIDs: string[];
  customSources: LiveSource[];
}

export interface ImportSummary {
  linksAdded: number;
  linksUpdated: number;
  pinsAdded: number;
  sourcesAdded: number;
}

export function importSummaryMessage(summary: ImportSummary): string {
  const parts: string[] = [];
  if (summary.linksAdded > 0) {
    parts.push(`${summary.linksAdded} link${summary.linksAdded === 1 ? "" : "s"} added`);
  }
  if (summary.linksUpdated > 0) parts.push(`${summary.linksUpdated} updated`);
  if (summary.pinsAdded > 0) parts.push(`${summary.pinsAdded} pinned`);
  if (summary.sourcesAdded > 0) {
    parts.push(`${summary.sourcesAdded} data source${summary.sourcesAdded === 1 ? "" : "s"}`);
  }
  if (parts.length === 0) return "Everything in that file was already set up.";
  return `${parts.join(", ")}.`;
}

interface HubStoreValue {
  city: City | null;
  cityName: string;
  setCityID: (id: string) => void;

  resourceURLs: Record<string, string>;
  urlFor: (link: ResourceLink) => string | null;
  hasURL: (link: ResourceLink) => boolean;
  setURL: (raw: string, link: ResourceLink) => void;
  configuredLinkCount: number;

  pinnedLinkIDs: string[];
  pinnedLinks: ResourceLink[];
  isPinned: (link: ResourceLink) => boolean;
  togglePin: (link: ResourceLink) => void;

  isStepComplete: (checklistID: string, step: string) => boolean;
  toggleStep: (checklistID: string, step: string) => void;
  resetChecklist: (checklistID: string) => void;
  completedCount: (checklistID: string) => number;

  permits: PermitRecord[];
  permitsIn: (inbox: PermitInbox | null) => PermitRecord[];
  openCount: (inbox: PermitInbox) => number;
  addPermit: (permit: Omit<PermitRecord, "id">) => void;
  updatePermit: (permit: PermitRecord) => void;
  deletePermit: (id: string) => void;

  allSources: LiveSource[];
  enabledSources: LiveSource[];
  customSources: LiveSource[];
  isSourceEnabled: (source: LiveSource) => boolean;
  setSourceEnabled: (source: LiveSource, enabled: boolean) => void;
  addCustomSource: (source: LiveSource) => void;
  removeCustomSource: (id: string) => void;

  exportConfiguration: () => HubConfiguration;
  importConfiguration: (config: HubConfiguration) => ImportSummary;
  resetEverything: () => void;
}

const HubStoreContext = createContext<HubStoreValue | null>(null);

export function HubStoreProvider({ children }: { children: ReactNode }) {
  const [selectedCityID, setSelectedCityID] = useState<string>(() =>
    readStored<string>(STORAGE_KEYS.city, DEFAULT_CITY_ID),
  );
  const [resourceURLs, setResourceURLs] = useState<Record<string, string>>(() =>
    readStored<Record<string, string>>(STORAGE_KEYS.urls, {}),
  );
  const [pinnedLinkIDs, setPinnedLinkIDs] = useState<string[]>(() =>
    readStored<string[]>(STORAGE_KEYS.pinned, []),
  );
  const [checklistProgress, setChecklistProgress] = useState<Record<string, string[]>>(() =>
    readStored<Record<string, string[]>>(STORAGE_KEYS.checklists, {}),
  );
  const [permits, setPermits] = useState<PermitRecord[]>(() =>
    readStored<PermitRecord[]>(STORAGE_KEYS.permits, seedPermits()),
  );
  const [customSources, setCustomSources] = useState<LiveSource[]>(() =>
    readStored<LiveSource[]>(STORAGE_KEYS.sources, []),
  );
  const [disabledSourceIDs, setDisabledSourceIDs] = useState<string[]>(() =>
    readStored<string[]>(STORAGE_KEYS.disabled, []),
  );

  useEffect(() => writeStored(STORAGE_KEYS.city, selectedCityID), [selectedCityID]);
  useEffect(() => writeStored(STORAGE_KEYS.urls, resourceURLs), [resourceURLs]);
  useEffect(() => writeStored(STORAGE_KEYS.pinned, pinnedLinkIDs), [pinnedLinkIDs]);
  useEffect(() => writeStored(STORAGE_KEYS.checklists, checklistProgress), [checklistProgress]);
  useEffect(() => writeStored(STORAGE_KEYS.permits, permits), [permits]);
  useEffect(() => writeStored(STORAGE_KEYS.sources, customSources), [customSources]);
  useEffect(() => writeStored(STORAGE_KEYS.disabled, disabledSourceIDs), [disabledSourceIDs]);

  const city = useMemo(() => cityByID(selectedCityID), [selectedCityID]);

  const urlFor = useCallback(
    (link: ResourceLink): string | null => {
      const stored = resourceURLs[link.id];
      if (stored && stored.length > 0) return stored;
      if (link.action.kind === "web" && link.action.value) return link.action.value;
      return null;
    },
    [resourceURLs],
  );

  const setURL = useCallback((raw: string, link: ResourceLink) => {
    const trimmed = raw.trim();
    setResourceURLs((current) => {
      const next = { ...current };
      if (trimmed.length === 0) {
        delete next[link.id];
      } else {
        next[link.id] = normalizeURL(trimmed);
      }
      return next;
    });
  }, []);

  const togglePin = useCallback((link: ResourceLink) => {
    setPinnedLinkIDs((current) =>
      current.includes(link.id)
        ? current.filter((id) => id !== link.id)
        : [...current, link.id],
    );
  }, []);

  const toggleStep = useCallback((checklistID: string, step: string) => {
    setChecklistProgress((current) => {
      const steps = current[checklistID] ?? [];
      const next = steps.includes(step)
        ? steps.filter((entry) => entry !== step)
        : [...steps, step];
      return { ...current, [checklistID]: next };
    });
  }, []);

  const allSources = useMemo<LiveSource[]>(
    () =>
      [...BUILT_IN_SOURCES, ...customSources].map((source) => ({
        ...source,
        isEnabled: !disabledSourceIDs.includes(source.id),
      })),
    [customSources, disabledSourceIDs],
  );

  const enabledSources = useMemo(
    () => allSources.filter((source) => source.isEnabled),
    [allSources],
  );

  const setSourceEnabled = useCallback((source: LiveSource, enabled: boolean) => {
    setDisabledSourceIDs((current) =>
      enabled ? current.filter((id) => id !== source.id) : [...new Set([...current, source.id])],
    );
  }, []);

  const exportConfiguration = useCallback((): HubConfiguration => {
    const links: ConfiguredLink[] = Object.entries(resourceURLs).map(([id, url]) => ({
      id,
      title: ALL_LINKS.find((link) => link.id === id)?.title ?? id,
      category: categoryTitleForLink(id),
      url,
    }));

    return {
      formatVersion: 1,
      exportedAt: new Date().toISOString(),
      cityID: city?.id,
      cityName: city ? cityDisplayName(city) : undefined,
      links,
      pinnedLinkIDs,
      customSources,
    };
  }, [city, customSources, pinnedLinkIDs, resourceURLs]);

  const importConfiguration = useCallback(
    (config: HubConfiguration): ImportSummary => {
      let linksAdded = 0;
      let linksUpdated = 0;

      setResourceURLs((current) => {
        const next = { ...current };
        for (const link of config.links ?? []) {
          if (!link.id || !link.url) continue;
          if (next[link.id] === undefined) {
            linksAdded += 1;
          } else if (next[link.id] !== link.url) {
            linksUpdated += 1;
          }
          next[link.id] = link.url;
        }
        return next;
      });

      let pinsAdded = 0;
      setPinnedLinkIDs((current) => {
        const next = [...current];
        for (const id of config.pinnedLinkIDs ?? []) {
          if (!next.includes(id)) {
            next.push(id);
            pinsAdded += 1;
          }
        }
        return next;
      });

      let sourcesAdded = 0;
      setCustomSources((current) => {
        const next = [...current];
        const builtInIDs = new Set(BUILT_IN_SOURCES.map((source) => source.id));
        for (const source of config.customSources ?? []) {
          if (builtInIDs.has(source.id)) continue;
          if (next.some((existing) => existing.id === source.id)) continue;
          next.push({ ...source, isBuiltIn: false, isEnabled: true });
          sourcesAdded += 1;
        }
        return next;
      });

      return { linksAdded, linksUpdated, pinsAdded, sourcesAdded };
    },
    [],
  );

  const value = useMemo<HubStoreValue>(
    () => ({
      city,
      cityName: cityDisplayName(city),
      setCityID: setSelectedCityID,

      resourceURLs,
      urlFor,
      hasURL: (link) => urlFor(link) !== null,
      setURL,
      configuredLinkCount: Object.keys(resourceURLs).length,

      pinnedLinkIDs,
      pinnedLinks: pinnedLinkIDs
        .map((id) => ALL_LINKS.find((link) => link.id === id))
        .filter((link): link is ResourceLink => link !== undefined),
      isPinned: (link) => pinnedLinkIDs.includes(link.id),
      togglePin,

      isStepComplete: (checklistID, step) =>
        (checklistProgress[checklistID] ?? []).includes(step),
      toggleStep,
      resetChecklist: (checklistID) =>
        setChecklistProgress((current) => ({ ...current, [checklistID]: [] })),
      completedCount: (checklistID) => (checklistProgress[checklistID] ?? []).length,

      permits,
      permitsIn: (inbox) =>
        [...permits]
          .filter((permit) => (inbox ? permit.inbox === inbox : true))
          .sort((a, b) => Date.parse(b.receivedDate) - Date.parse(a.receivedDate)),
      openCount: (inbox) =>
        permits.filter(
          (permit) =>
            permit.inbox === inbox &&
            OPEN_PERMIT_STATUSES.includes(permit.status as PermitStatus),
        ).length,
      addPermit: (permit) =>
        setPermits((current) => [
          { ...permit, id: `permit-${Date.now()}-${current.length}` },
          ...current,
        ]),
      updatePermit: (permit) =>
        setPermits((current) =>
          current.map((entry) => (entry.id === permit.id ? permit : entry)),
        ),
      deletePermit: (id) => setPermits((current) => current.filter((entry) => entry.id !== id)),

      allSources,
      enabledSources,
      customSources,
      isSourceEnabled: (source) => !disabledSourceIDs.includes(source.id),
      setSourceEnabled,
      addCustomSource: (source) =>
        setCustomSources((current) => [...current, { ...source, isBuiltIn: false }]),
      removeCustomSource: (id) =>
        setCustomSources((current) => current.filter((source) => source.id !== id)),

      exportConfiguration,
      importConfiguration,
      resetEverything: () => {
        setResourceURLs({});
        setPinnedLinkIDs([]);
        setChecklistProgress({});
        setPermits(seedPermits());
        setCustomSources([]);
        setDisabledSourceIDs([]);
      },
    }),
    [
      allSources,
      checklistProgress,
      city,
      customSources,
      disabledSourceIDs,
      enabledSources,
      exportConfiguration,
      importConfiguration,
      permits,
      pinnedLinkIDs,
      resourceURLs,
      setSourceEnabled,
      setURL,
      toggleStep,
      togglePin,
      urlFor,
    ],
  );

  return <HubStoreContext.Provider value={value}>{children}</HubStoreContext.Provider>;
}

export function useHubStore(): HubStoreValue {
  const context = useContext(HubStoreContext);
  if (context === null) {
    throw new Error("useHubStore must be used inside a HubStoreProvider.");
  }
  return context;
}
