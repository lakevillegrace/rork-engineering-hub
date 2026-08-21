import Foundation
import OSLog

nonisolated private let logger = Logger(subsystem: "app.rork.engineeringhub", category: "Boundaries")

/// Wire format of the bundled boundary file, written as flat coordinate pairs to
/// keep the resource small.
nonisolated private struct BoundaryFile: Decodable, Sendable {
    struct Entry: Decodable, Sendable {
        let name: String
        /// `[lon, lat, lon, lat, …]` per ring.
        let rings: [[Double]]
    }

    let source: String
    let notice: String
    let retrieved: String
    let boundaries: [Entry]
}

/// Loads the county's municipal boundaries once and answers jurisdiction
/// questions: which limits to draw, and which city a point falls inside.
///
/// The data ships in the app bundle, so boundaries and the "what jurisdiction am
/// I standing in" check both work with no connection.
nonisolated final class BoundaryStore: Sendable {
    static let shared = BoundaryStore()

    let boundaries: [MunicipalBoundary]
    let attribution: String

    private init() {
        guard
            let url = Bundle.main.url(forResource: "DakotaMunicipalBoundaries", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(BoundaryFile.self, from: data)
        else {
            logger.error("Municipal boundary resource missing or unreadable")
            boundaries = []
            attribution = ""
            return
        }

        boundaries = file.boundaries.compactMap { entry in
            let rings: [[GeoPoint]] = entry.rings.compactMap { flat in
                guard flat.count >= 6 else { return nil }
                return stride(from: 0, to: flat.count - 1, by: 2).map { index in
                    GeoPoint(latitude: flat[index + 1], longitude: flat[index])
                }
            }
            guard !rings.isEmpty else { return nil }

            let match = BoundaryStore.city(forGISName: entry.name)
            return MunicipalBoundary(
                gisName: entry.name,
                cityID: match?.id,
                displayName: match?.displayName ?? entry.name.capitalized,
                rings: rings,
                bounds: GeoBounds.around(rings)
            )
        }

        attribution = file.notice
    }

    /// Boundaries carry the county's own spelling; a couple differ from the
    /// municipality list, so match on the shared prefix as a fallback.
    private static func city(forGISName name: String) -> City? {
        let upper = name.uppercased()
        if let exact = DakotaCounty.all.first(where: { $0.gisName.uppercased() == upper }) {
            return exact
        }
        // The county writes some townships without the "TWP" suffix.
        return DakotaCounty.townships.first { township in
            township.gisName.uppercased().replacingOccurrences(of: " TWP", with: "") == upper
        }
    }

    func boundary(cityID: String?) -> MunicipalBoundary? {
        guard let cityID else { return nil }
        return boundaries.first { $0.cityID == cityID }
    }

    /// The municipality a coordinate falls inside, if any.
    func boundary(containing point: GeoPoint) -> MunicipalBoundary? {
        boundaries.first { $0.contains(point) }
    }

    /// Display name of the jurisdiction a coordinate sits in.
    func jurisdictionName(for point: GeoPoint) -> String? {
        boundary(containing: point)?.displayName
    }

    /// Envelope covering every mapped municipality, used to clip statewide
    /// layers such as MnDOT 511 down to Dakota County.
    var countyExtent: GeoBounds? {
        guard !boundaries.isEmpty else { return nil }
        let all = boundaries.map(\.bounds)
        let pad = 0.02
        return GeoBounds(
            minLatitude: (all.map(\.minLatitude).min() ?? 0) - pad,
            maxLatitude: (all.map(\.maxLatitude).max() ?? 0) + pad,
            minLongitude: (all.map(\.minLongitude).min() ?? 0) - pad,
            maxLongitude: (all.map(\.maxLongitude).max() ?? 0) + pad
        )
    }

    /// Every municipality a line of work passes through.
    ///
    /// County roads frequently run along a shared city line, so testing a single
    /// anchor point would hand border work to just one neighbour. Sampling the
    /// whole path keeps it visible to every city that owns a side of the street.
    func jurisdictionIDs(touchedBy path: [GeoPoint]) -> [String] {
        guard !path.isEmpty else { return [] }

        let sampleLimit = 12
        let step = max(1, path.count / sampleLimit)
        var samples = stride(from: 0, to: path.count, by: step).map { path[$0] }
        if let last = path.last, samples.last != last {
            samples.append(last)
        }

        var found: [String] = []
        for sample in samples {
            guard let cityID = boundary(containing: sample)?.cityID else { continue }
            if !found.contains(cityID) { found.append(cityID) }
        }
        return found
    }
}
