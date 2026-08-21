/** A WGS84 coordinate. Mirrors the iOS app's `GeoPoint`. */
export interface GeoPoint {
  latitude: number;
  longitude: number;
}

/** A rectangular envelope used to reject point-in-polygon tests cheaply. */
export interface GeoBounds {
  minLatitude: number;
  maxLatitude: number;
  minLongitude: number;
  maxLongitude: number;
}

export function boundsContain(bounds: GeoBounds, point: GeoPoint): boolean {
  return (
    point.latitude >= bounds.minLatitude &&
    point.latitude <= bounds.maxLatitude &&
    point.longitude >= bounds.minLongitude &&
    point.longitude <= bounds.maxLongitude
  );
}

export function boundsAround(rings: GeoPoint[][]): GeoBounds {
  let minLatitude = Number.POSITIVE_INFINITY;
  let maxLatitude = Number.NEGATIVE_INFINITY;
  let minLongitude = Number.POSITIVE_INFINITY;
  let maxLongitude = Number.NEGATIVE_INFINITY;

  for (const ring of rings) {
    for (const point of ring) {
      minLatitude = Math.min(minLatitude, point.latitude);
      maxLatitude = Math.max(maxLatitude, point.latitude);
      minLongitude = Math.min(minLongitude, point.longitude);
      maxLongitude = Math.max(maxLongitude, point.longitude);
    }
  }

  return { minLatitude, maxLatitude, minLongitude, maxLongitude };
}

/** Standard ray-casting crossing count for a single closed ring. */
function ringContains(ring: GeoPoint[], point: GeoPoint): boolean {
  if (ring.length <= 2) return false;
  let isInside = false;
  let j = ring.length - 1;

  for (let i = 0; i < ring.length; i += 1) {
    const a = ring[i];
    const b = ring[j];
    const straddles = a.latitude > point.latitude !== b.latitude > point.latitude;
    if (straddles) {
      const span = b.latitude - a.latitude;
      if (span !== 0) {
        const crossing =
          ((b.longitude - a.longitude) * (point.latitude - a.latitude)) / span + a.longitude;
        if (point.longitude < crossing) isInside = !isInside;
      }
    }
    j = i;
  }

  return isInside;
}

/**
 * Even-odd point-in-polygon across every ring, so interior holes and detached
 * parcels both resolve correctly.
 */
export function ringsContain(rings: GeoPoint[][], bounds: GeoBounds, point: GeoPoint): boolean {
  if (!boundsContain(bounds, point)) return false;
  let isInside = false;
  for (const ring of rings) {
    if (ringContains(ring, point)) isInside = !isInside;
  }
  return isInside;
}

const EARTH_RADIUS_METERS = 6_371_000;
const METERS_PER_MILE = 1609.344;

/** Great-circle distance in meters. */
export function distanceInMeters(a: GeoPoint, b: GeoPoint): number {
  const toRadians = Math.PI / 180;
  const dLat = (b.latitude - a.latitude) * toRadians;
  const dLon = (b.longitude - a.longitude) * toRadians;
  const lat1 = a.latitude * toRadians;
  const lat2 = b.latitude * toRadians;

  const h =
    Math.sin(dLat / 2) ** 2 + Math.sin(dLon / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2);
  return 2 * EARTH_RADIUS_METERS * Math.asin(Math.min(1, Math.sqrt(h)));
}

/**
 * Distance in miles to the nearest of a set of points.
 *
 * Measuring to the closest point rather than the midpoint matters on long
 * corridors: a crew parked at one end of a four-mile mill and overlay should
 * read "0.1 mi", not "2 mi". Long geometries are sampled so this stays cheap
 * inside list filters.
 */
export function nearestDistanceInMiles(points: GeoPoint[], origin: GeoPoint): number | null {
  if (points.length === 0) return null;
  const step = Math.max(1, Math.floor(points.length / 24));
  let nearest = Number.POSITIVE_INFINITY;
  for (let index = 0; index < points.length; index += step) {
    nearest = Math.min(nearest, distanceInMeters(points[index], origin));
  }
  return Number.isFinite(nearest) ? nearest / METERS_PER_MILE : null;
}

export function formatMiles(miles: number): string {
  if (miles < 0.1) return "on site";
  if (miles < 10) return `${miles.toFixed(1)} mi`;
  return `${Math.round(miles)} mi`;
}
