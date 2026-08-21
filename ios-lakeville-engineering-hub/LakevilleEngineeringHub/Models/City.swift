import Foundation

nonisolated enum MunicipalityKind: String, Codable, Sendable {
    case city
    case township

    var label: String {
        switch self {
        case .city: "City"
        case .township: "Township"
        }
    }
}

/// A Dakota County municipality staff can run the hub for.
nonisolated struct City: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let kind: MunicipalityKind
    /// Value used by county GIS layers in their `CITY_L` / `CITY_R` fields.
    let gisName: String
    let center: GeoPoint
    var website: String?
    var engineeringPath: String?
    /// True when the hub ships curated Engineering content for this city.
    var hasCuratedContent: Bool = false

    var displayName: String {
        kind == .township ? "\(name) Township" : name
    }

    var engineeringURL: String? {
        guard let website else { return nil }
        guard let engineeringPath else { return website }
        return website + engineeringPath
    }
}
