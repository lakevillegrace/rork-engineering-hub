import type { GeoPoint } from "@/lib/geo";

export type MunicipalityKind = "city" | "township";

/** A Dakota County municipality the hub can run for. */
export interface City {
  id: string;
  name: string;
  kind: MunicipalityKind;
  /** Value used by county GIS layers in their `CITY_L` / `CITY_R` fields. */
  gisName: string;
  center: GeoPoint;
  website?: string;
  engineeringPath?: string;
  /** True when the hub ships curated Engineering content for this city. */
  hasCuratedContent?: boolean;
}

function point(latitude: number, longitude: number): GeoPoint {
  return { latitude, longitude };
}

export const DAKOTA_CITIES: City[] = [
  {
    id: "lakeville",
    name: "Lakeville",
    kind: "city",
    gisName: "LAKEVILLE",
    center: point(44.6497, -93.2427),
    website: "https://www.lakevillemn.gov",
    engineeringPath: "/158/Engineering",
    hasCuratedContent: true,
  },
  {
    id: "apple-valley",
    name: "Apple Valley",
    kind: "city",
    gisName: "APPLE VALLEY",
    center: point(44.7319, -93.2177),
    website: "https://www.applevalleymn.gov",
    engineeringPath: "/1071/Engineering",
    hasCuratedContent: true,
  },
  { id: "burnsville", name: "Burnsville", kind: "city", gisName: "BURNSVILLE", center: point(44.7678, -93.2777), website: "https://www.burnsvillemn.gov" },
  { id: "coates", name: "Coates", kind: "city", gisName: "COATES", center: point(44.7169, -93.0338) },
  { id: "eagan", name: "Eagan", kind: "city", gisName: "EAGAN", center: point(44.8041, -93.1668), website: "https://www.cityofeagan.com" },
  { id: "farmington", name: "Farmington", kind: "city", gisName: "FARMINGTON", center: point(44.64, -93.1436), website: "https://www.farmingtonmn.gov" },
  { id: "hampton", name: "Hampton", kind: "city", gisName: "HAMPTON", center: point(44.6069, -93.0022) },
  { id: "hastings", name: "Hastings", kind: "city", gisName: "HASTINGS", center: point(44.7433, -92.8524), website: "https://www.hastingsmn.gov" },
  { id: "inver-grove-heights", name: "Inver Grove Heights", kind: "city", gisName: "INVER GROVE HEIGHTS", center: point(44.848, -93.0427), website: "https://www.invergroveheights.org" },
  { id: "lilydale", name: "Lilydale", kind: "city", gisName: "LILYDALE", center: point(44.9147, -93.113) },
  { id: "mendota", name: "Mendota", kind: "city", gisName: "MENDOTA", center: point(44.8875, -93.1636), website: "https://www.cityofmendota.org" },
  { id: "mendota-heights", name: "Mendota Heights", kind: "city", gisName: "MENDOTA HEIGHTS", center: point(44.8835, -93.1382), website: "https://www.mendotaheightsmn.gov" },
  { id: "miesville", name: "Miesville", kind: "city", gisName: "MIESVILLE", center: point(44.6008, -92.818) },
  { id: "new-trier", name: "New Trier", kind: "city", gisName: "NEW TRIER", center: point(44.6155, -92.9319) },
  { id: "northfield", name: "Northfield", kind: "city", gisName: "NORTHFIELD", center: point(44.4583, -93.1616), website: "https://www.northfieldmn.gov" },
  { id: "randolph", name: "Randolph", kind: "city", gisName: "RANDOLPH", center: point(44.5261, -93.0208), website: "https://www.cityofrandolphmn.com" },
  { id: "rosemount", name: "Rosemount", kind: "city", gisName: "ROSEMOUNT", center: point(44.7394, -93.1258), website: "https://www.rosemountmn.gov" },
  { id: "south-st-paul", name: "South St. Paul", kind: "city", gisName: "SOUTH ST PAUL", center: point(44.8928, -93.0349), website: "https://www.southstpaul.org" },
  { id: "sunfish-lake", name: "Sunfish Lake", kind: "city", gisName: "SUNFISH LAKE", center: point(44.8672, -93.0913), website: "https://www.sunfishlake.org" },
  { id: "vermillion", name: "Vermillion", kind: "city", gisName: "VERMILLION", center: point(44.6725, -92.9666) },
  { id: "west-st-paul", name: "West St. Paul", kind: "city", gisName: "WEST ST PAUL", center: point(44.9163, -93.1013), website: "https://www.wspmn.gov" },
];

export const DAKOTA_TOWNSHIPS: City[] = [
  { id: "castle-rock-twp", name: "Castle Rock", kind: "township", gisName: "CASTLE ROCK TWP", center: point(44.5636, -93.1489) },
  { id: "douglas-twp", name: "Douglas", kind: "township", gisName: "DOUGLAS TWP", center: point(44.5825, -92.8969) },
  { id: "empire-twp", name: "Empire", kind: "township", gisName: "EMPIRE TWP", center: point(44.6608, -93.0783) },
  { id: "eureka-twp", name: "Eureka", kind: "township", gisName: "EUREKA TWP", center: point(44.5892, -93.2836) },
  { id: "greenvale-twp", name: "Greenvale", kind: "township", gisName: "GREENVALE TWP", center: point(44.5011, -93.2861) },
  { id: "hampton-twp", name: "Hampton", kind: "township", gisName: "HAMPTON TWP", center: point(44.6031, -92.95) },
  { id: "marshan-twp", name: "Marshan", kind: "township", gisName: "MARSHAN TWP", center: point(44.6786, -92.8944) },
  { id: "nininger-twp", name: "Nininger", kind: "township", gisName: "NININGER TWP", center: point(44.7622, -92.9089) },
  { id: "randolph-twp", name: "Randolph", kind: "township", gisName: "RANDOLPH TWP", center: point(44.5222, -93.0189) },
  { id: "ravenna-twp", name: "Ravenna", kind: "township", gisName: "RAVENNA TWP", center: point(44.7175, -92.8103) },
  { id: "sciota-twp", name: "Sciota", kind: "township", gisName: "SCIOTA TWP", center: point(44.5178, -93.03) },
  { id: "vermillion-twp", name: "Vermillion", kind: "township", gisName: "VERMILLION TWP", center: point(44.6644, -92.9331) },
  { id: "waterford-twp", name: "Waterford", kind: "township", gisName: "WATERFORD TWP", center: point(44.4906, -93.2072) },
];

export const DAKOTA_MUNICIPALITIES: (City & { displayName: string })[] = [
  ...DAKOTA_CITIES,
  ...DAKOTA_TOWNSHIPS,
].map((city) => ({
  ...city,
  displayName: city.kind === "township" ? `${city.name} Township` : city.name,
}));

export const DEFAULT_CITY_ID = "lakeville";

export const DAKOTA_COUNTY = {
  name: "Dakota County",
  phone: "651-437-3191",
  permitOfficePhone: "952-891-7115",
  gopherStateOneCall: "811",
} as const;

export function cityByID(id: string | null | undefined): City | null {
  if (!id) return null;
  return DAKOTA_MUNICIPALITIES.find((city) => city.id === id) ?? null;
}

export function cityDisplayName(city: City | null): string {
  if (!city) return "Not set";
  return city.kind === "township" ? `${city.name} Township` : city.name;
}

export function engineeringURL(city: City | null): string | null {
  if (!city?.website) return null;
  return city.engineeringPath ? city.website + city.engineeringPath : city.website;
}
