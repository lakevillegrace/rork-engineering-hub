import Foundation
import Observation

/// Persisted staff-configurable state: SharePoint URLs attached to resource
/// rows, pinned rows, checklist progress and locally tracked permits.
@Observable
final class HubStore {
    private enum Key {
        static let urls = "hub.resourceURLs"
        static let pinned = "hub.pinnedLinkIDs"
        static let checklists = "hub.checklistProgress"
        static let permits = "hub.permits"
        static let seeded = "hub.didSeedPermits"
        static let cityID = "hub.selectedCityID"
        static let customSources = "hub.customSources"
        static let disabledSources = "hub.disabledSourceIDs"
    }

    private let defaults: UserDefaults

    private(set) var resourceURLs: [String: String]
    private(set) var pinnedLinkIDs: [String]
    private(set) var checklistProgress: [String: [String]]
    private(set) var permits: [PermitRecord]
    private(set) var customSources: [LiveSource]
    private(set) var disabledSourceIDs: [String]

    /// The municipality the hub is configured for. `nil` until staff choose one
    /// on first launch.
    var selectedCityID: String? {
        didSet {
            guard selectedCityID != oldValue else { return }
            defaults.set(selectedCityID, forKey: Key.cityID)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        resourceURLs = HubStore.decode([String: String].self, from: defaults.data(forKey: Key.urls)) ?? [:]
        pinnedLinkIDs = HubStore.decode([String].self, from: defaults.data(forKey: Key.pinned)) ?? []
        checklistProgress = HubStore.decode([String: [String]].self, from: defaults.data(forKey: Key.checklists)) ?? [:]
        customSources = HubStore.decode([LiveSource].self, from: defaults.data(forKey: Key.customSources)) ?? []
        disabledSourceIDs = HubStore.decode([String].self, from: defaults.data(forKey: Key.disabledSources)) ?? []
        selectedCityID = defaults.string(forKey: Key.cityID)

        let storedPermits = HubStore.decode([PermitRecord].self, from: defaults.data(forKey: Key.permits))
        if let storedPermits, defaults.bool(forKey: Key.seeded) {
            permits = storedPermits
        } else {
            permits = HubContent.seedPermits()
            defaults.set(true, forKey: Key.seeded)
            persistPermits()
        }
    }

    // MARK: - Resource URLs

    /// Returns the staff-configured URL for a resource row, if one exists.
    func url(for link: ResourceLink) -> URL? {
        if let stored = resourceURLs[link.id], let url = URL(string: stored) {
            return url
        }
        if case let .web(defaultURL) = link.action, let defaultURL, let url = URL(string: defaultURL) {
            return url
        }
        return nil
    }

    func urlString(for link: ResourceLink) -> String {
        resourceURLs[link.id] ?? ""
    }

    func hasURL(for link: ResourceLink) -> Bool {
        url(for: link) != nil
    }

    /// Saves a link target. An empty or invalid string clears it.
    func setURL(_ raw: String, for link: ResourceLink) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            resourceURLs.removeValue(forKey: link.id)
        } else {
            resourceURLs[link.id] = HubStore.normalized(trimmed)
        }
        persist(resourceURLs, key: Key.urls)
    }

    /// Adds an https scheme when staff paste a bare host.
    static func normalized(_ raw: String) -> String {
        if raw.lowercased().hasPrefix("http://") || raw.lowercased().hasPrefix("https://") {
            return raw
        }
        return "https://" + raw
    }

    // MARK: - Pinned rows

    func isPinned(_ link: ResourceLink) -> Bool {
        pinnedLinkIDs.contains(link.id)
    }

    func togglePin(_ link: ResourceLink) {
        if let index = pinnedLinkIDs.firstIndex(of: link.id) {
            pinnedLinkIDs.remove(at: index)
        } else {
            pinnedLinkIDs.append(link.id)
        }
        persist(pinnedLinkIDs, key: Key.pinned)
    }

    var pinnedLinks: [ResourceLink] {
        pinnedLinkIDs.compactMap { id in
            currentLinks.first { $0.id == id } ?? CityContent.allLinks.first { $0.id == id }
        }
    }

    // MARK: - Checklists

    func isStepComplete(checklist: String, step: String) -> Bool {
        checklistProgress[checklist]?.contains(step) ?? false
    }

    func toggleStep(checklist: String, step: String) {
        var steps = checklistProgress[checklist] ?? []
        if let index = steps.firstIndex(of: step) {
            steps.remove(at: index)
        } else {
            steps.append(step)
        }
        checklistProgress[checklist] = steps
        persist(checklistProgress, key: Key.checklists)
    }

    func resetChecklist(_ checklist: String) {
        checklistProgress[checklist] = []
        persist(checklistProgress, key: Key.checklists)
    }

    func completedCount(checklist: String) -> Int {
        checklistProgress[checklist]?.count ?? 0
    }

    // MARK: - Permits

    func permits(in inbox: PermitInbox?) -> [PermitRecord] {
        let filtered = inbox.map { box in permits.filter { $0.inbox == box } } ?? permits
        return filtered.sorted { $0.receivedDate > $1.receivedDate }
    }

    func openCount(in inbox: PermitInbox) -> Int {
        permits.filter { $0.inbox == inbox && PermitStatus(rawValue: $0.status)?.isOpen != false }.count
    }

    func addPermit(_ permit: PermitRecord) {
        permits.append(permit)
        persistPermits()
    }

    func updatePermit(_ permit: PermitRecord) {
        guard let index = permits.firstIndex(where: { $0.id == permit.id }) else { return }
        permits[index] = permit
        persistPermits()
    }

    func deletePermits(ids: Set<UUID>) {
        permits.removeAll { ids.contains($0.id) }
        persistPermits()
    }

    // MARK: - City

    var selectedCity: City? {
        DakotaCounty.city(id: selectedCityID)
    }

    var hasSelectedCity: Bool { selectedCity != nil }

    // MARK: - City content

    /// Content resolved for the selected municipality.
    var pack: ContentPack { CityContent.pack(for: selectedCity) }

    var categories: [HubCategory] { pack.categories }

    var projects: [CapitalProject] { pack.projects }

    var trafficCounts: [TrafficCount] { pack.trafficCounts }

    func category(id: String) -> HubCategory? {
        categories.first { $0.id == id }
    }

    func project(id: String) -> CapitalProject? {
        projects.first { $0.id == id }
    }

    /// Every resource row available for the current city.
    var currentLinks: [ResourceLink] {
        categories.flatMap { $0.sections.flatMap(\.links) }
    }

    /// The category a row belongs to within the current city's content.
    func categoryTitle(for link: ResourceLink) -> String {
        categories.first { category in
            category.sections.contains { $0.links.contains { $0.id == link.id } }
        }?.title ?? CityContent.categoryTitle(for: link)
    }

    // MARK: - Live data sources

    /// Built-in county layers plus any layers staff added, with enablement applied.
    var allSources: [LiveSource] {
        (LiveSource.builtIns + customSources).map { source in
            var copy = source
            copy.isEnabled = !disabledSourceIDs.contains(source.id)
            return copy
        }
    }

    func isSourceEnabled(_ source: LiveSource) -> Bool {
        !disabledSourceIDs.contains(source.id)
    }

    func setSource(_ source: LiveSource, enabled: Bool) {
        if enabled {
            disabledSourceIDs.removeAll { $0 == source.id }
        } else if !disabledSourceIDs.contains(source.id) {
            disabledSourceIDs.append(source.id)
        }
        persist(disabledSourceIDs, key: Key.disabledSources)
    }

    func addCustomSource(_ source: LiveSource) {
        if let index = customSources.firstIndex(where: { $0.id == source.id }) {
            customSources[index] = source
        } else {
            customSources.append(source)
        }
        persist(customSources, key: Key.customSources)
    }

    func removeCustomSource(id: String) {
        customSources.removeAll { $0.id == id }
        persist(customSources, key: Key.customSources)
    }

    // MARK: - Configuration sharing

    var configuredLinkCount: Int { resourceURLs.count }

    /// Builds an exportable snapshot of every staff-entered setting.
    func exportConfiguration() -> HubConfiguration {
        let links: [ConfiguredLink] = resourceURLs
            .map { id, url in
                let link = CityContent.allLinks.first { $0.id == id }
                return ConfiguredLink(
                    id: id,
                    title: link?.title ?? id,
                    category: link.map { CityContent.categoryTitle(for: $0) } ?? "Other",
                    url: url
                )
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

        return HubConfiguration(
            exportedAt: Date(),
            cityID: selectedCityID,
            cityName: selectedCity?.displayName,
            links: links,
            pinnedLinkIDs: pinnedLinkIDs,
            customSources: customSources
        )
    }

    /// Merges an imported configuration into local settings. Existing addresses
    /// are overwritten only when the incoming one differs.
    @discardableResult
    func importConfiguration(_ configuration: HubConfiguration, replaceExisting: Bool) -> ConfigurationImportSummary {
        if replaceExisting {
            resourceURLs.removeAll()
        }

        var added = 0
        var updated = 0
        for link in configuration.links {
            let trimmed = link.url.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let normalized = HubStore.normalized(trimmed)
            guard URL(string: normalized) != nil else { continue }

            if let existing = resourceURLs[link.id] {
                if existing != normalized {
                    resourceURLs[link.id] = normalized
                    updated += 1
                }
            } else {
                resourceURLs[link.id] = normalized
                added += 1
            }
        }
        persist(resourceURLs, key: Key.urls)

        var pinsAdded = 0
        for id in configuration.pinnedLinkIDs where !pinnedLinkIDs.contains(id) {
            pinnedLinkIDs.append(id)
            pinsAdded += 1
        }
        persist(pinnedLinkIDs, key: Key.pinned)

        var sourcesAdded = 0
        for source in configuration.customSources where !customSources.contains(where: { $0.id == source.id }) {
            customSources.append(source)
            sourcesAdded += 1
        }
        persist(customSources, key: Key.customSources)

        return ConfigurationImportSummary(
            linksAdded: added,
            linksUpdated: updated,
            pinsAdded: pinsAdded,
            sourcesAdded: sourcesAdded
        )
    }

    /// Clears every saved resource address, leaving content and permits intact.
    func clearAllLinks() {
        resourceURLs.removeAll()
        persist(resourceURLs, key: Key.urls)
    }

    // MARK: - Persistence helpers

    private func persistPermits() {
        persist(permits, key: Key.permits)
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

extension HubContent {
    /// Every resource row in the app, used for search and pinned lookups.
    static let allLinks: [ResourceLink] = categories.flatMap { category in
        category.sections.flatMap(\.links)
    }

    /// The category a resource row belongs to.
    static func categoryTitle(for link: ResourceLink) -> String {
        categories.first { category in
            category.sections.contains { $0.links.contains(link) }
        }?.title ?? ""
    }
}
