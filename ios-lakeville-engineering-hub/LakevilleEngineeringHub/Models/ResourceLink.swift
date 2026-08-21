import Foundation

/// What happens when a resource row is tapped.
nonisolated enum ResourceAction: Hashable, Sendable {
    /// Opens a web resource. The URL is configured by staff inside the app.
    case web(defaultURL: String?)
    case phone(String)
    case email(String)
    case route(HubRoute)
}

/// A single tappable row inside a hub section.
nonisolated struct ResourceLink: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let systemImage: String
    var detail: String?
    var action: ResourceAction

    init(
        id: String,
        title: String,
        systemImage: String,
        detail: String? = nil,
        action: ResourceAction = .web(defaultURL: nil)
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.detail = detail
        self.action = action
    }
}

/// A titled group of resource rows.
nonisolated struct ResourceSection: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    var footnote: String?
    let links: [ResourceLink]

    init(id: String, title: String, footnote: String? = nil, links: [ResourceLink]) {
        self.id = id
        self.title = title
        self.footnote = footnote
        self.links = links
    }
}
