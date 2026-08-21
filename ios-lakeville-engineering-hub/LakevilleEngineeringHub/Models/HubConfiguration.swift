import Foundation
import UniformTypeIdentifiers

/// One saved resource address, exported in a human-readable shape so a
/// colleague can review the file before importing it.
nonisolated struct ConfiguredLink: Codable, Hashable, Sendable {
    let id: String
    let title: String
    let category: String
    let url: String
}

/// A shareable snapshot of everything a staff member has configured: resource
/// addresses, pinned shortcuts and any custom GIS layers they added.
///
/// Exported as JSON so one person can set the hub up once and hand it to the
/// rest of the department.
nonisolated struct HubConfiguration: Codable, Hashable, Sendable {
    static let currentFormatVersion = 1

    var formatVersion: Int = HubConfiguration.currentFormatVersion
    var exportedAt: Date
    var cityID: String?
    var cityName: String?
    var links: [ConfiguredLink]
    var pinnedLinkIDs: [String]
    var customSources: [LiveSource]

    var linkCount: Int { links.count }

    /// Pretty-printed JSON with ISO-8601 dates, suitable for email or Teams.
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static func decoded(from data: Data) throws -> HubConfiguration {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(HubConfiguration.self, from: data)
    }

    /// A stable, descriptive filename for the export.
    var suggestedFileName: String {
        let slug = (cityName ?? "dakota-county")
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let stamp = exportedAt.formatted(.iso8601.year().month().day())
        return "\(slug)-engineering-hub-\(stamp).json"
    }
}

nonisolated enum ConfigurationImportError: LocalizedError, Sendable {
    case unreadable
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unreadable:
            "That file isn't a valid Engineering Hub configuration."
        case let .unsupportedVersion(version):
            "This file was made by a newer version of the app (format \(version))."
        }
    }
}

/// Result of merging an imported configuration, used for the confirmation
/// message.
nonisolated struct ConfigurationImportSummary: Sendable {
    let linksAdded: Int
    let linksUpdated: Int
    let pinsAdded: Int
    let sourcesAdded: Int

    var isEmpty: Bool {
        linksAdded == 0 && linksUpdated == 0 && pinsAdded == 0 && sourcesAdded == 0
    }

    var message: String {
        guard !isEmpty else { return "Everything in that file was already set up." }
        var parts: [String] = []
        if linksAdded > 0 { parts.append("\(linksAdded) link\(linksAdded == 1 ? "" : "s") added") }
        if linksUpdated > 0 { parts.append("\(linksUpdated) updated") }
        if pinsAdded > 0 { parts.append("\(pinsAdded) pinned") }
        if sourcesAdded > 0 { parts.append("\(sourcesAdded) data source\(sourcesAdded == 1 ? "" : "s")") }
        return parts.joined(separator: ", ") + "."
    }
}
