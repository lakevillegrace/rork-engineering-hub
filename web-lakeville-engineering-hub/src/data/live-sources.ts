import type { City } from "@/data/cities";

export type LiveCategory = "closure" | "project" | "trail" | "other";

export const LIVE_CATEGORY_TITLE: Record<LiveCategory, string> = {
  closure: "Closures",
  project: "Projects",
  trail: "Trails",
  other: "Other",
};

export const LIVE_CATEGORY_SINGULAR: Record<LiveCategory, string> = {
  closure: "Road closure",
  project: "Construction project",
  trail: "Trail closure",
  other: "Advisory",
};

/** A configurable ArcGIS layer the hub polls for live field conditions. */
export interface LiveSource {
  id: string;
  title: string;
  category: LiveCategory;
  layerURL: string;
  whereClause: string;
  titleField: string;
  subtitleField?: string;
  detailField?: string;
  impactField?: string;
  startField?: string;
  finishField?: string;
  ownerField?: string;
  urlField?: string;
  updatedField?: string;
  /** Field holding the municipality name, enabling server-side city filters. */
  cityField?: string;
  /**
   * When set, records sharing the same title and this field's value collapse
   * into one row. County centreline layers split a single street into dozens of
   * address-range records, which otherwise read as duplicates.
   */
  groupField?: string;
  /** Clips the query to Dakota County's extent, for statewide layers. */
  countyExtentOnly?: boolean;
  isBuiltIn?: boolean;
  isEnabled: boolean;
}

/** Fields requested from the service, or `*` when the mapping is sparse. */
export function outFieldsFor(source: LiveSource): string {
  const fields = [
    source.titleField,
    source.subtitleField,
    source.detailField,
    source.impactField,
    source.startField,
    source.finishField,
    source.ownerField,
    source.urlField,
    source.updatedField,
    source.cityField,
    source.groupField,
  ].filter((field): field is string => Boolean(field && field.length > 0));

  if (fields.length === 0) return "*";
  return [...new Set(fields)].sort().join(",");
}

/** Escapes a municipality name for an ArcGIS SQL `where` clause. */
export function whereClauseFor(source: LiveSource, city: City | null): string {
  if (!source.cityField || !city) return source.whereClause;
  const escaped = city.gisName.replace(/'/g, "''").toUpperCase();
  const cityPredicate = `UPPER(${source.cityField})='${escaped}'`;
  if (!source.whereClause || source.whereClause === "1=1") return cityPredicate;
  return `(${source.whereClause}) AND ${cityPredicate}`;
}

/**
 * Countywide layers published by Dakota County and MnDOT. These are public,
 * read-only endpoints that serve every city in the county.
 */
export const BUILT_IN_SOURCES: LiveSource[] = [
  {
    id: "dakota-transportation-projects",
    title: "Dakota County Construction Projects",
    category: "project",
    layerURL:
      "https://gis2.co.dakota.mn.us/arcgis/rest/services/AGOL/DC_OL_TRANS_TransportationProjects_PUBLIC/MapServer/0",
    whereClause: "CURRENT_='Yes'",
    titleField: "ROADNAME",
    subtitleField: "LOCATIONDESCRIPTION",
    detailField: "PROJECTWORK",
    impactField: "CONST_IMPACT",
    startField: "CONST_START",
    finishField: "CONST_FINISH",
    ownerField: "CONST_ENGINEER",
    urlField: "CONST_URL",
    updatedField: "UPDATEDATE",
    isBuiltIn: true,
    isEnabled: true,
  },
  {
    id: "dakota-mill-overlay",
    title: "Dakota County Mill & Overlay",
    category: "project",
    // The layer carries the whole street centreline network; only records with
    // a program year are actually in the paving program.
    layerURL:
      "https://gis2.co.dakota.mn.us/arcgis/rest/services/AGOL/DC_OL_TRANS_MillAndOverlayProject_PUBLIC/FeatureServer/0",
    whereClause: "ProgramYear IS NOT NULL",
    titleField: "STREET_NAM",
    subtitleField: "ProgramYear",
    detailField: "Strategy",
    ownerField: "RoadNo",
    cityField: "CITY_L",
    groupField: "ProgramYear",
    isBuiltIn: true,
    isEnabled: true,
  },
  {
    id: "mndot-511-events",
    title: "MnDOT 511 Traveler Information",
    category: "project",
    layerURL:
      "https://services.arcgis.com/8lRhdTsQyJpO52F1/arcgis/rest/services/CARS511_MN_Events_View/FeatureServer/0",
    whereClause: "1=1",
    titleField: "headline",
    subtitleField: "Route",
    detailField: "Restrict_",
    impactField: "phrase",
    urlField: "linktxt",
    countyExtentOnly: true,
    isBuiltIn: true,
    isEnabled: true,
  },
];
