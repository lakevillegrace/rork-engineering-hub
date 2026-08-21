import Foundation

/// A rectangular envelope used to reject point-in-polygon tests cheaply.
nonisolated struct GeoBounds: Hashable, Sendable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    func contains(_ point: GeoPoint) -> Bool {
        point.latitude >= minLatitude && point.latitude <= maxLatitude
            && point.longitude >= minLongitude && point.longitude <= maxLongitude
    }

    static func around(_ rings: [[GeoPoint]]) -> GeoBounds {
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude

        for ring in rings {
            for point in ring {
                minLat = min(minLat, point.latitude)
                maxLat = max(maxLat, point.latitude)
                minLon = min(minLon, point.longitude)
                maxLon = max(maxLon, point.longitude)
            }
        }

        return GeoBounds(
            minLatitude: minLat,
            maxLatitude: maxLat,
            minLongitude: minLon,
            maxLongitude: maxLon
        )
    }
}

/// The mapped limits of one Dakota County municipality.
///
/// Geometry comes from the county's published Municipal Boundaries layer and is
/// bundled with the app so the map still draws jurisdiction lines with no signal.
nonisolated struct MunicipalBoundary: Identifiable, Hashable, Sendable {
    /// Uppercase name exactly as the county publishes it, e.g. `LAKEVILLE`.
    let gisName: String
    /// Matching `City.id` when this boundary is one of the county's own
    /// municipalities; nil for neighbours that only clip into Dakota County.
    let cityID: String?
    let displayName: String
    /// One or more closed rings. Detached parcels and holes are separate rings.
    let rings: [[GeoPoint]]
    let bounds: GeoBounds

    var id: String { gisName }

    /// Even-odd point-in-polygon test across every ring, so interior holes and
    /// detached parcels both resolve correctly.
    func contains(_ point: GeoPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        var isInside = false
        for ring in rings where MunicipalBoundary.ringContains(ring, point) {
            isInside.toggle()
        }
        return isInside
    }

    /// Standard ray-casting crossing count for a single closed ring.
    private static func ringContains(_ ring: [GeoPoint], _ point: GeoPoint) -> Bool {
        guard ring.count > 2 else { return false }
        var isInside = false
        var j = ring.count - 1

        for i in 0..<ring.count {
            let a = ring[i]
            let b = ring[j]
            let straddles = (a.latitude > point.latitude) != (b.latitude > point.latitude)
            if straddles {
                let span = b.latitude - a.latitude
                if span != 0 {
                    let crossing = (b.longitude - a.longitude) * (point.latitude - a.latitude) / span + a.longitude
                    if point.longitude < crossing { isInside.toggle() }
                }
            }
            j = i
        }

        return isInside
    }
}
