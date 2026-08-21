import boundaryData from "@/data/dakota-municipal-boundaries.json";
import { DAKOTA_MUNICIPALITIES } from "@/data/cities";
import {
  boundsAround,
  ringsContain,
  type GeoBounds,
  type GeoPoint,
} from "@/lib/geo";

/** The mapped limits of one Dakota County municipality. */
export interface MunicipalBoundary {
  /** Uppercase name exactly as the county publishes it, e.g. `LAKEVILLE`. */
  gisName: string;
  /** Matching city id when the boundary is one of our selectable cities. */
  cityID: string | null;
  displayName: string;
  rings: GeoPoint[][];
  bounds: GeoBounds;
}

/**
 * Wire format of the bundled boundary file. Rings are written as flat
 * `[lon, lat, lon, lat, …]` runs to keep the resource small (29 KB for all 35
 * municipalities), matching the file the iOS app ships.
 */
interface RawBoundaryFile {
  source: string;
  notice: string;
  retrieved: string;
  boundaries: { name: string; rings: number[][] }[];
}

const raw = boundaryData as RawBoundaryFile;

/** Expands one flat `[lon, lat, …]` run into coordinates. */
function expandRing(flat: number[]): GeoPoint[] {
  if (flat.length < 6) return [];
  const points: GeoPoint[] = [];
  for (let index = 0; index < flat.length - 1; index += 2) {
    points.push({ latitude: flat[index + 1], longitude: flat[index] });
  }
  return points;
}

/**
 * County GIS names townships with a "TWP" suffix that our city list omits, so
 * match both spellings before giving up.
 */
function cityFor(gisName: string): { id: string; displayName: string } | null {
  const direct = DAKOTA_MUNICIPALITIES.find((city) => city.gisName === gisName);
  if (direct) return { id: direct.id, displayName: direct.displayName };

  const withoutSuffix = gisName.replace(/\s+TWP$/, "");
  const township = DAKOTA_MUNICIPALITIES.find(
    (city) => city.gisName === withoutSuffix || city.gisName === `${withoutSuffix} TWP`,
  );
  return township ? { id: township.id, displayName: township.displayName } : null;
}

function titleCase(value: string): string {
  return value
    .toLowerCase()
    .split(" ")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

export const MUNICIPAL_BOUNDARIES: MunicipalBoundary[] = raw.boundaries
  .map((entry) => {
    const rings = entry.rings.map(expandRing).filter((ring) => ring.length > 0);
    const match = cityFor(entry.name);
    return {
      gisName: entry.name,
      cityID: match?.id ?? null,
      displayName: match?.displayName ?? titleCase(entry.name),
      rings,
      bounds: boundsAround(rings),
    };
  })
  .filter((boundary) => boundary.rings.length > 0);

export const BOUNDARY_SOURCE_NOTE = raw.notice;
export const BOUNDARY_RETRIEVED = raw.retrieved;

export function boundaryForCity(cityID: string | null | undefined): MunicipalBoundary | null {
  if (!cityID) return null;
  return MUNICIPAL_BOUNDARIES.find((boundary) => boundary.cityID === cityID) ?? null;
}

/** The municipality a coordinate falls inside, if any. */
export function boundaryContaining(point: GeoPoint): MunicipalBoundary | null {
  return (
    MUNICIPAL_BOUNDARIES.find((boundary) =>
      ringsContain(boundary.rings, boundary.bounds, point),
    ) ?? null
  );
}

/**
 * Every municipality a run of geometry passes through.
 *
 * Sampling a handful of points along the path (rather than only the midpoint)
 * is what makes a road on a shared border show up in both cities' lists.
 */
export function jurisdictionIDsTouchedBy(points: GeoPoint[]): string[] {
  if (points.length === 0) return [];
  const step = Math.max(1, Math.floor(points.length / 12));
  const found = new Set<string>();

  for (let index = 0; index < points.length; index += step) {
    const boundary = boundaryContaining(points[index]);
    if (boundary?.cityID) found.add(boundary.cityID);
  }

  // Always test the final vertex so short spurs at the end aren't missed.
  const last = boundaryContaining(points[points.length - 1]);
  if (last?.cityID) found.add(last.cityID);

  return [...found];
}

/** Envelope of the whole county, padded slightly, for server-side clipping. */
export const COUNTY_EXTENT: GeoBounds = (() => {
  const envelope = boundsAround(MUNICIPAL_BOUNDARIES.flatMap((boundary) => boundary.rings));
  const pad = 0.02;
  return {
    minLatitude: envelope.minLatitude - pad,
    maxLatitude: envelope.maxLatitude + pad,
    minLongitude: envelope.minLongitude - pad,
    maxLongitude: envelope.maxLongitude + pad,
  };
})();
