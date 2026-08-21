import { useEffect, useMemo } from "react";
import {
  CircleMarker,
  MapContainer,
  Polygon,
  Polyline,
  TileLayer,
  useMap,
} from "react-leaflet";
import type { LatLngBoundsExpression, LatLngExpression } from "leaflet";
import "leaflet/dist/leaflet.css";

import { MUNICIPAL_BOUNDARIES, boundaryForCity } from "@/lib/boundaries";
import { anchorOf, isFullClosure, type LiveItem } from "@/lib/live-ops";
import type { GeoPoint } from "@/lib/geo";

const NAVY = "#1F4E79";
const STEEL = "#4A90C4";
const AMBER = "#E8A33D";
const DANGER = "#B3261E";

function toLatLng(point: GeoPoint): LatLngExpression {
  return [point.latitude, point.longitude];
}

function colorFor(item: LiveItem): string {
  if (item.category === "closure" || isFullClosure(item)) return DANGER;
  if (item.category === "trail") return STEEL;
  return AMBER;
}

/** Keeps the viewport on the selected work without fighting the user's pan. */
function ViewportController({
  focus,
  fallbackBounds,
}: {
  focus: LiveItem | null;
  fallbackBounds: LatLngBoundsExpression;
}) {
  const map = useMap();

  useEffect(() => {
    if (!focus) {
      map.fitBounds(fallbackBounds, { padding: [24, 24] });
      return;
    }
    const points = focus.segments.flat();
    if (points.length === 0) return;
    if (points.length === 1) {
      map.setView(toLatLng(points[0]), 15, { animate: true });
      return;
    }
    const latitudes = points.map((point) => point.latitude);
    const longitudes = points.map((point) => point.longitude);
    map.fitBounds(
      [
        [Math.min(...latitudes), Math.min(...longitudes)],
        [Math.max(...latitudes), Math.max(...longitudes)],
      ],
      { padding: [48, 48], maxZoom: 15, animate: true },
    );
  }, [focus, fallbackBounds, map]);

  return null;
}

export function ConditionsMap({
  items,
  selectedID,
  onSelect,
  cityID,
  showBoundaries = true,
  className,
}: {
  items: LiveItem[];
  selectedID?: string | null;
  onSelect?: (item: LiveItem) => void;
  cityID: string | null;
  showBoundaries?: boolean;
  className?: string;
}) {
  const homeBoundary = useMemo(() => boundaryForCity(cityID), [cityID]);

  const fallbackBounds = useMemo<LatLngBoundsExpression>(() => {
    const target = homeBoundary ?? MUNICIPAL_BOUNDARIES[0];
    return [
      [target.bounds.minLatitude, target.bounds.minLongitude],
      [target.bounds.maxLatitude, target.bounds.maxLongitude],
    ];
  }, [homeBoundary]);

  const focus = useMemo(
    () => items.find((item) => item.id === selectedID) ?? null,
    [items, selectedID],
  );

  return (
    <MapContainer
      bounds={fallbackBounds}
      scrollWheelZoom
      className={className}
      preferCanvas
    >
      <TileLayer
        url="https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>'
        maxZoom={19}
      />

      {showBoundaries
        ? MUNICIPAL_BOUNDARIES.map((boundary) => {
            const isHome = boundary.cityID === cityID;
            return (
              <Polygon
                key={boundary.gisName}
                positions={boundary.rings.map((ring) => ring.map(toLatLng))}
                pathOptions={{
                  color: isHome ? NAVY : "#8FA3B5",
                  weight: isHome ? 2.5 : 1,
                  opacity: isHome ? 0.9 : 0.5,
                  fillColor: NAVY,
                  fillOpacity: isHome ? 0.07 : 0.02,
                }}
                interactive={false}
              />
            );
          })
        : null}

      {items.map((item) => {
        const isSelected = item.id === selectedID;
        const color = colorFor(item);
        return item.segments.map((segment, index) => {
          if (segment.length === 1) {
            return (
              <CircleMarker
                key={`${item.id}-point-${index}`}
                center={toLatLng(segment[0])}
                radius={isSelected ? 9 : 6}
                pathOptions={{
                  color: "#ffffff",
                  weight: 2,
                  fillColor: color,
                  fillOpacity: 1,
                }}
                eventHandlers={{ click: () => onSelect?.(item) }}
              />
            );
          }
          return (
            <Polyline
              key={`${item.id}-run-${index}`}
              positions={segment.map(toLatLng)}
              pathOptions={{
                color,
                weight: isSelected ? 7 : 4,
                opacity: isSelected ? 1 : 0.75,
                lineCap: "round",
              }}
              eventHandlers={{ click: () => onSelect?.(item) }}
            />
          );
        });
      })}

      {focus
        ? (() => {
            const anchor = anchorOf(focus);
            if (!anchor) return null;
            return (
              <CircleMarker
                center={toLatLng(anchor)}
                radius={11}
                pathOptions={{
                  color: "#ffffff",
                  weight: 3,
                  fillColor: colorFor(focus),
                  fillOpacity: 1,
                }}
                interactive={false}
              />
            );
          })()
        : null}

      <ViewportController focus={focus} fallbackBounds={fallbackBounds} />
    </MapContainer>
  );
}
