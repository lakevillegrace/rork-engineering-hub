import type { GeoBounds, GeoPoint } from "@/lib/geo";

export type JSONScalar = string | number | boolean | null;

export interface ArcGISGeometry {
  x?: number;
  y?: number;
  paths?: number[][][];
  rings?: number[][][];
}

export interface ArcGISFeature {
  attributes: Record<string, JSONScalar>;
  geometry?: ArcGISGeometry;
}

interface ArcGISQueryResponse {
  features?: ArcGISFeature[];
  error?: { code: number; message: string };
}

export class ArcGISError extends Error {}

/** A display string for an attribute, or null when absent or blank. */
export function fieldText(
  feature: ArcGISFeature,
  field: string | undefined | null,
): string | null {
  if (!field) return null;
  const value = feature.attributes[field];
  if (value === null || value === undefined) return null;
  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed.length === 0 ? null : trimmed;
  }
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if (typeof value === "number") {
    return Number.isInteger(value) ? String(value) : value.toFixed(2);
  }
  return null;
}

/** Esri encodes dates as epoch milliseconds. */
export function fieldDate(
  feature: ArcGISFeature,
  field: string | undefined | null,
): Date | null {
  if (!field) return null;
  const value = feature.attributes[field];
  if (typeof value !== "number" || value <= 0) return null;
  return new Date(value);
}

/** Flattens an Esri geometry into an ordered list of coordinates. */
export function coordinatesFrom(geometry: ArcGISGeometry | undefined): GeoPoint[] {
  if (!geometry) return [];
  if (typeof geometry.x === "number" && typeof geometry.y === "number") {
    return [{ latitude: geometry.y, longitude: geometry.x }];
  }
  const shape = geometry.paths ?? geometry.rings;
  const first = shape?.[0];
  if (!first) return [];
  return first
    .filter((pair) => pair.length >= 2)
    .map((pair) => ({ latitude: pair[1], longitude: pair[0] }));
}

export interface QueryOptions {
  layerURL: string;
  whereClause?: string;
  outFields?: string;
  returnGeometry?: boolean;
  resultRecordCount?: number;
  /** Clips the query server-side, for statewide layers such as MnDOT 511. */
  envelope?: GeoBounds | null;
  signal?: AbortSignal;
}

/**
 * Minimal read-only client for public ArcGIS REST feature/map service layers.
 *
 * Dakota County GIS and MnDOT's 511 service both send permissive CORS headers,
 * so these queries run straight from the browser with no proxy in between.
 */
export async function queryFeatures({
  layerURL,
  whereClause = "1=1",
  outFields = "*",
  returnGeometry = true,
  resultRecordCount = 250,
  envelope = null,
  signal,
}: QueryOptions): Promise<ArcGISFeature[]> {
  const base = layerURL.trim().replace(/\/+$/, "");
  const params = new URLSearchParams({
    where: whereClause,
    outFields,
    returnGeometry: returnGeometry ? "true" : "false",
    outSR: "4326",
    geometryPrecision: "5",
    resultRecordCount: String(resultRecordCount),
    f: "json",
  });

  if (envelope) {
    params.set(
      "geometry",
      [
        envelope.minLongitude,
        envelope.minLatitude,
        envelope.maxLongitude,
        envelope.maxLatitude,
      ].join(","),
    );
    params.set("geometryType", "esriGeometryEnvelope");
    params.set("inSR", "4326");
    params.set("spatialRel", "esriSpatialRelIntersects");
  }

  const response = await fetch(`${base}/query?${params.toString()}`, { signal });
  if (!response.ok) {
    throw new ArcGISError(`The GIS server returned an error (HTTP ${response.status}).`);
  }

  const decoded = (await response.json()) as ArcGISQueryResponse;
  if (decoded.error) throw new ArcGISError(decoded.error.message);
  return decoded.features ?? [];
}
