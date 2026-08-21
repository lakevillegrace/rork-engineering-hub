import Foundation
import Observation
import OSLog

nonisolated private let logger = Logger(subsystem: "app.rork.engineeringhub", category: "Updates")

/// Gathers agency notices from public feeds and from the live GIS data already
/// on hand, so staff get one dated list instead of checking three websites.
@Observable
final class UpdatesService {
    private(set) var items: [UpdateItem] = []
    private(set) var isLoading = false
    private(set) var lastUpdated: Date?
    private(set) var isFromCache = false
    private(set) var failedFeeds: [String] = []

    private let cacheURL: URL?
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)

        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        cacheURL = directory?.appendingPathComponent("agency-updates.json")
        loadCache()
    }

    func items(from agency: UpdateAgency) -> [UpdateItem] {
        items.filter { $0.agency == agency }
    }

    /// Refreshes city feeds and folds in agency notices derived from live data.
    ///
    /// - Parameter liveItems: the current GIS feed, used to surface MnDOT 511
    ///   events and recently revised county projects without a second download.
    func refresh(city: City?, liveItems: [LiveItem]) async {
        isLoading = true
        defer { isLoading = false }

        let feeds = UpdateFeed.feeds(for: city?.id)
        var collected: [UpdateItem] = []
        var problems: [String] = []

        await withTaskGroup(of: (UpdateFeed, [UpdateItem]?).self) { group in
            for feed in feeds {
                group.addTask { [session] in
                    guard let url = URL(string: feed.url) else { return (feed, nil) }
                    do {
                        let (data, response) = try await session.data(from: url)
                        if let http = response as? HTTPURLResponse,
                           !(200..<300).contains(http.statusCode) {
                            return (feed, nil)
                        }
                        let entries = RSSFeedParser().parse(data)
                        return (feed, UpdatesService.map(entries, feed: feed))
                    } catch {
                        logger.error("Feed \(feed.id, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                        return (feed, nil)
                    }
                }
            }

            for await (feed, mapped) in group {
                if let mapped {
                    collected.append(contentsOf: mapped)
                } else {
                    problems.append(feed.title)
                }
            }
        }

        collected.append(contentsOf: UpdatesService.stateUpdates(from: liveItems))
        collected.append(contentsOf: UpdatesService.countyUpdates(from: liveItems))

        failedFeeds = problems

        // A total failure keeps the cached list on screen rather than blanking it.
        guard !collected.isEmpty else { return }

        items = UpdatesService.deduplicated(collected)
            .sorted { ($0.published ?? .distantPast) > ($1.published ?? .distantPast) }
        lastUpdated = Date()
        isFromCache = false
        saveCache()
    }

    // MARK: - Mapping

    private static func map(_ entries: [RSSEntry], feed: UpdateFeed) -> [UpdateItem] {
        entries.map { entry in
            UpdateItem(
                id: "\(feed.id)-\(entry.guid.isEmpty ? entry.link + entry.title : entry.guid)",
                title: entry.title,
                summary: entry.summary.isEmpty ? nil : entry.summary,
                link: entry.link.isEmpty ? nil : entry.link,
                published: entry.published,
                agency: feed.agency,
                sourceTitle: feed.title
            )
        }
    }

    /// MnDOT 511 events already fetched for the map, presented as state notices.
    private static func stateUpdates(from liveItems: [LiveItem]) -> [UpdateItem] {
        liveItems
            .filter { $0.sourceTitle.localizedStandardContains("511") }
            .map { item in
                UpdateItem(
                    id: "mndot-\(item.id)",
                    title: item.title,
                    summary: [item.impact, item.detail, item.jurisdiction]
                        .compactMap { $0 }
                        .joined(separator: " · "),
                    link: item.link,
                    published: item.updatedAt,
                    agency: .state,
                    sourceTitle: "MnDOT 511",
                    isFieldImpact: true
                )
            }
    }

    /// County projects the county itself revised recently.
    private static func countyUpdates(from liveItems: [LiveItem]) -> [UpdateItem] {
        let cutoff = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        return liveItems
            .filter { $0.sourceTitle.localizedStandardContains("Dakota County") }
            .filter { ($0.updatedAt ?? .distantPast) >= cutoff }
            .map { item in
                UpdateItem(
                    id: "county-\(item.id)",
                    title: item.title,
                    summary: [item.subtitle, item.detail, item.schedule]
                        .compactMap { $0 }
                        .joined(separator: " · "),
                    link: item.link,
                    published: item.updatedAt,
                    agency: .county,
                    sourceTitle: item.sourceTitle,
                    isFieldImpact: true
                )
            }
    }

    private static func deduplicated(_ items: [UpdateItem]) -> [UpdateItem] {
        var seen: Set<String> = []
        return items.filter { seen.insert("\($0.agency.rawValue)|\($0.title.lowercased())").inserted }
    }

    // MARK: - Cache

    nonisolated private struct CachePayload: Codable, Sendable {
        let items: [UpdateItem]
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
