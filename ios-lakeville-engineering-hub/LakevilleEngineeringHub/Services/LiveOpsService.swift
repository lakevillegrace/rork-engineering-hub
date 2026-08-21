import Foundation
import Observation
import OSLog

nonisolated private let logger = Logger(subsystem: "app.rork.engineeringhub", category: "LiveOps")

/// Loading state for the live conditions feed.
nonisolated enum LiveLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}

/// A source that failed during the last refresh, surfaced so staff know which
/// layer is unreachable rather than silently seeing fewer results.
nonisolated struct LiveSourceFailure: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let message: String
}

/// Fetches live field conditions from configured ArcGIS layers, normalizes
/// them into `LiveItem`s, and caches the last good result for offline use.
@Observable
final class LiveOpsService {
    private(set) var items: [LiveItem] = []
    private(set) var state: LiveLoadState = .idle
    private(set) var lastUpdated: Date?
    private(set) var failures: [LiveSourceFailure] = []
    private(set) var isFromCache = false

    private let client = ArcGISClient()
    private let cacheURL: URL?

    init() {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        cacheURL = directory?.appendingPathComponent("live-conditions.json")
        loadCache()
    }

    var closures: [LiveItem] { items.filter { $0.category == .closure } }
    var projects: [LiveItem] { items.filter { $0.category == .project } }
    var trails: [LiveItem] { items.filter { $0.category == .trail } }

    func items(in category: LiveCategory) -> [LiveItem] {
        items.filter { $0.category == category }
    }

    /// Refreshes every enabled source for the selected city.
    func refresh(city: City?, sources: [LiveSource]) async {
        let enabled = sources.filter(\.isEnabled)
        guard !enabled.isEmpty else {
            items = []
            state = .loaded
            failures = []
            return
        }

        state = .loading

        var collected: [LiveItem] = []
        var problems: [LiveSourceFailure] = []

        await withTaskGroup(of: (LiveSource, Result<[LiveItem], Error>).self) { group in
            for source in enabled {
                group.addTask { [client] in
                    do {
                        let features = try await client.queryFeatures(
                            layerURL: source.layerURL,
                            whereClause: source.whereClause(forCity: city),
                            outFields: source.outFields,
                            resultRecordCount: source.groupField == nil ? 250 : 1000,
                            envelope: source.limitsToCounty ? BoundaryStore.shared.countyExtent : nil
                        )
                        return (source, .success(LiveOpsService.makeItems(from: features, source: source)))
                    } catch {
                        return (source, .failure(error))
                    }
                }
            }

            for await (source, result) in group {
                switch result {
                case let .success(mapped):
                    collected.append(contentsOf: mapped)
                case let .failure(error):
                    logger.error("Source \(source.id, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                    problems.append(
                        LiveSourceFailure(
                            id: source.id,
                            title: source.title,
                            message: error.localizedDescription
                        )
                    )
                }
            }
        }

        failures = problems

        if collected.isEmpty, !problems.isEmpty {
            // Keep whatever we already had rather than blanking the screen.
            state = .failed(problems.first?.message ?? "Couldn't reach the GIS services.")
            return
        }

        items = LiveOpsService.sorted(LiveOpsService.deduplicated(collected), near: city)
        lastUpdated = Date()
        isFromCache = false
        state = .loaded
        saveCache()
    }

    // MARK: - Mapping

    /// Turns raw features into display rows, folding a source's segmented
    /// records into one row per real project when the source declares a
    /// grouping field.
    private static func makeItems(from features: [ArcGISFeature], source: LiveSource) -> [LiveItem] {
        guard let groupField = source.groupField, !groupField.isEmpty else {
            return features.enumerated().compactMap { index, feature in
                makeItem(from: feature, source: source, index: index)
            }
        }

        var order: [String] = []
        var buckets: [String: [ArcGISFeature]] = [:]
        for feature in features {
            guard let title = feature.text(source.titleField) else { continue }
            let key = "\(title)|\(feature.text(groupField) ?? "")"
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(feature)
        }

        return order.enumerated().compactMap { index, key in
            guard let bucket = buckets[key], let first = bucket.first else { return nil }
            guard var item = makeItem(from: first, source: source, index: index) else { return nil }
            guard bucket.count > 1 else { return item }

            let runs = bucket.map { coordinates(from: $0.geometry) }.filter { !$0.isEmpty }
            item.segments = runs
            item.segmentCount = bucket.count
            item.path = runs.max(by: { $0.count < $1.count }) ?? item.path

            // Re-resolve jurisdiction across the whole corridor, not just the
            // first record's short stretch.
            let touched = BoundaryStore.shared.jurisdictionIDs(touchedBy: runs.flatMap { $0 })
            item.jurisdictionIDs = touched
            if let anchor = item.anchor,
               let boundary = BoundaryStore.shared.boundary(containing: anchor) {
                item.jurisdiction = boundary.displayName
                item.jurisdictionID = boundary.cityID
            }
            return item
        }
    }

    /// Drops records that describe the same work in the same place. Some layers
    /// publish one row per status style, which would otherwise double-count.
    private static func deduplicated(_ items: [LiveItem]) -> [LiveItem] {
        var seen: Set<String> = []
        return items.filter { item in
            let anchor = item.anchor
            let latitude = anchor.map { String(format: "%.4f", $0.latitude) } ?? "-"
            let longitude = anchor.map { String(format: "%.4f", $0.longitude) } ?? "-"
            let key = [
                item.title.lowercased(),
                item.subtitle?.lowercased() ?? "",
                item.impact?.lowercased() ?? "",
                latitude,
                longitude,
            ].joined(separator: "|")
            return seen.insert(key).inserted
        }
    }

    private static func makeItem(from feature: ArcGISFeature, source: LiveSource, index: Int) -> LiveItem? {
        guard let title = feature.text(source.titleField) else { return nil }

        let impact = feature.text(source.impactField)
        let start = feature.text(source.startField)
        let finish = feature.text(source.finishField)

        let schedule: String? = switch (start, finish) {
        case let (start?, finish?): "\(start) – \(finish)"
        case let (start?, nil): "Starts \(start)"
        case let (nil, finish?): "Through \(finish)"
        default: nil
        }

        let path = coordinates(from: feature.geometry)
        let anchor = path.isEmpty ? nil : path[path.count / 2]
        let boundary = anchor.flatMap { BoundaryStore.shared.boundary(containing: $0) }
        let touched = BoundaryStore.shared.jurisdictionIDs(touchedBy: path)

        return LiveItem(
            id: "\(source.id)-\(index)-\(title.hashValue)",
            title: title,
            subtitle: feature.text(source.subtitleField)?.capitalizedIfShouting,
            detail: feature.text(source.detailField),
            impact: impact,
            schedule: schedule,
            owner: feature.text(source.ownerField),
            link: feature.text(source.urlField),
            category: resolvedCategory(source: source, impact: impact),
            sourceTitle: source.title,
            updatedAt: feature.date(source.updatedField),
            path: path,
            jurisdiction: boundary?.displayName,
            jurisdictionID: boundary?.cityID,
            jurisdictionIDs: touched
        )
    }

    /// A project whose impact says the road is closed is really a closure.
    private static func resolvedCategory(source: LiveSource, impact: String?) -> LiveCategory {
        guard source.category == .project, let impact = impact?.lowercased() else {
            return source.category
        }
        let isClosed = impact.contains("closed") || impact.contains("closure") || impact.contains("detour")
        return isClosed ? .closure : .project
    }

    private static func coordinates(from geometry: ArcGISGeometry?) -> [GeoPoint] {
        guard let geometry else { return [] }
        if let x = geometry.x, let y = geometry.y {
            return [GeoPoint(latitude: y, longitude: x)]
        }
        let shape = geometry.paths ?? geometry.rings
        guard let first = shape?.first else { return [] }
        return first.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return GeoPoint(latitude: pair[1], longitude: pair[0])
        }
    }

    /// Closures first, then nearest to the selected city.
    private static func sorted(_ items: [LiveItem], near city: City?) -> [LiveItem] {
        items.sorted { lhs, rhs in
            if lhs.category != rhs.category {
                return categoryRank(lhs.category) < categoryRank(rhs.category)
            }
            guard let center = city?.center else { return lhs.title < rhs.title }
            let left = lhs.distanceInMiles(from: center) ?? .greatestFiniteMagnitude
            let right = rhs.distanceInMiles(from: center) ?? .greatestFiniteMagnitude
            if left == right { return lhs.title < rhs.title }
            return left < right
        }
    }

    private static func categoryRank(_ category: LiveCategory) -> Int {
        switch category {
        case .closure: 0
        case .trail: 1
        case .project: 2
        case .other: 3
        }
    }

    // MARK: - Cache

    nonisolated private struct CachePayload: Codable, Sendable {
        let items: [LiveItem]
        let savedAt: Date
    }

    private func loadCache() {
        guard let cacheURL, let data = try? Data(contentsOf: cacheURL) else { return }
        guard let payload = try? JSONDecoder().decode(CachePayload.self, from: data) else { return }
        items = payload.items
        lastUpdated = payload.savedAt
        isFromCache = true
    }

    private func saveCache() {
        guard let cacheURL, let lastUpdated else { return }
        let payload = CachePayload(items: items, savedAt: lastUpdated)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}

private extension String {
    /// County GIS stores city names in caps; soften them for display.
    var capitalizedIfShouting: String {
        let letters = filter(\.isLetter)
        guard !letters.isEmpty, letters.allSatisfy(\.isUppercase) else { return self }
        return capitalized
    }
}
