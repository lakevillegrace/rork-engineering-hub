import Foundation

/// Which agency issued an update. Staff care about the difference: a MnDOT
/// closure and a City council notice are read very differently.
nonisolated enum UpdateAgency: String, CaseIterable, Identifiable, Codable, Sendable {
    case city
    case county
    case state

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .city: "City"
        case .county: "County"
        case .state: "MnDOT"
        }
    }

    var systemImage: String {
        switch self {
        case .city: "building.columns.fill"
        case .county: "map.fill"
        case .state: "road.lanes"
        }
    }
}

/// A dated notice pulled from an agency feed.
nonisolated struct UpdateItem: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    var summary: String?
    var link: String?
    var published: Date?
    var agency: UpdateAgency
    var sourceTitle: String
    /// True for items that describe active field impact rather than general news.
    var isFieldImpact: Bool = false

    func matches(_ query: String) -> Bool {
        [title, summary, sourceTitle].contains { $0?.localizedStandardContains(query) == true }
    }
}

/// A public feed the hub polls for agency updates.
nonisolated struct UpdateFeed: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let url: String
    let agency: UpdateAgency

    /// Verified public feeds, keyed by the city they belong to.
    ///
    /// Only feeds confirmed to return real items are listed; a city with no
    /// published feed shows nothing rather than a broken source.
    static func feeds(for cityID: String?) -> [UpdateFeed] {
        switch cityID {
        case "lakeville":
            [
                UpdateFeed(
                    id: "lakeville-news",
                    title: "Lakeville News Flash",
                    url: "https://www.lakevillemn.gov/RSSFeed.aspx?ModID=1&CID=All-0",
                    agency: .city
                ),
                UpdateFeed(
                    id: "lakeville-alerts",
                    title: "Lakeville Alert Center",
                    url: "https://www.lakevillemn.gov/RSSFeed.aspx?ModID=76&CID=All-0",
                    agency: .city
                ),
                UpdateFeed(
                    id: "lakeville-calendar",
                    title: "Lakeville Meetings & Calendar",
                    url: "https://www.lakevillemn.gov/RSSFeed.aspx?ModID=58&CID=All-0",
                    agency: .city
                ),
            ]
        default:
            []
        }
    }
}
