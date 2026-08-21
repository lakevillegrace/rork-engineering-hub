import CoreLocation
import Foundation

/// The kind of live field condition an item represents.
nonisolated enum LiveCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case closure
    case project
    case trail
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .closure: "Closures"
        case .project: "Projects"
        case .trail: "Trails"
        case .other: "Other"
        }
    }

    var singular: String {
        switch self {
        case .closure: "Road closure"
        case .project: "Construction project"
        case .trail: "Trail closure"
        case .other: "Advisory"
        }
    }

    var systemImage: String {
        switch self {
        case .closure: "exclamationmark.triangle.fill"
        case .project: "cone.fill"
        case .trail: "figure.walk"
        case .other: "info.circle.fill"
        }
    }
}

nonisolated struct GeoPoint: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// A normalized live condition pulled from a GIS layer, ready for display.
nonisolated struct LiveItem: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    var subtitle: String?
    var detail: String?
    var impact: String?
    var schedule: String?
    var owner: String?
    var link: String?
    var category: LiveCategory
    var sourceTitle: String
    var updatedAt: Date?
    var path: [GeoPoint]
    /// Every mapped run of this work. County layers publish long corridors as
    /// dozens of short address-range records; grouping them keeps one project as
    /// one row while still drawing each run in its own place.
    var segments: [[GeoPoint]]?
    /// How many source records were folded into this row.
    var segmentCount: Int = 1
    /// Municipality the work sits inside, resolved from county boundary geometry
    /// rather than any field the source layer publishes.
    var jurisdiction: String?
    /// `City.id` of the containing municipality, used for exact in-city filters.
    var jurisdictionID: String?
    /// Every municipality the work touches. Segments on a shared border belong
    /// to both cities, so both must see them.
    var jurisdictionIDs: [String]?

    /// True when this work falls inside the given municipality's limits.
    func isInside(cityID: String) -> Bool {
        if let jurisdictionIDs, !jurisdictionIDs.isEmpty {
            return jurisdictionIDs.contains(cityID)
        }
        return jurisdictionID == cityID
    }

    /// True when we were able to place this work in any municipality at all.
    var hasJurisdiction: Bool {
        jurisdictionID != nil || !(jurisdictionIDs ?? []).isEmpty
    }

    /// Runs to draw on a map. Separate runs are never joined into one line.
    var displaySegments: [[GeoPoint]] {
        if let segments, !segments.isEmpty { return segments }
        return path.isEmpty ? [] : [path]
    }

    /// Every mapped coordinate, used for jurisdiction and distance maths.
    var allPoints: [GeoPoint] {
        displaySegments.flatMap { $0 }
    }

    /// Midpoint of the longest run, so the pin lands on the main body of work
    /// rather than on a stray stub.
    var anchor: GeoPoint? {
        guard let longest = displaySegments.max(by: { $0.count < $1.count }), !longest.isEmpty else {
            return nil
        }
        return longest[longest.count / 2]
    }

    /// Label for corridors assembled from several source records.
    var segmentSummary: String? {
        segmentCount > 1 ? "\(segmentCount) segments" : nil
    }

    /// True when the impact text indicates the road is fully shut.
    var isFullClosure: Bool {
        guard let impact = impact?.lowercased() else { return false }
        return impact.contains("closed") || impact.contains("closure")
    }

    func matches(_ query: String) -> Bool {
        let fields = [title, subtitle, detail, impact, owner, sourceTitle, jurisdiction]
        return fields.contains { $0?.localizedStandardContains(query) == true }
    }

    /// Distance in miles to the nearest mapped point of this work.
    ///
    /// Measuring to the closest point rather than the midpoint matters on long
    /// corridors: a crew parked at one end of a four-mile mill and overlay
    /// should read "0.1 mi", not "2 mi".
    func distanceInMiles(from center: GeoPoint) -> Double? {
        let points = allPoints
        guard !points.isEmpty else { return nil }
        let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)
        // Sample long geometries so this stays cheap inside list filters.
        let step = max(1, points.count / 24)
        var nearest = Double.greatestFiniteMagnitude
        for index in stride(from: 0, to: points.count, by: step) {
            let point = points[index]
            let candidate = CLLocation(latitude: point.latitude, longitude: point.longitude)
            nearest = min(nearest, candidate.distance(from: origin))
        }
        return nearest == .greatestFiniteMagnitude ? nil : nearest / 1609.344
    }
}
