import Foundation

/// An active City capital improvement project.
///
/// `progress` and `contractor` are optional because most cities do not publish
/// them; the UI hides those rows rather than showing an invented number.
nonisolated struct CapitalProject: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let phase: String
    var progress: Double?
    let manager: String
    var contractor: String?
    let schedule: String
    let scope: String
    /// Published City page for this project, when one exists.
    var infoURL: String?
    /// The City's own project number, e.g. "2026-101".
    var projectNumber: String?
}

/// A processed traffic count record.
nonisolated struct TrafficCount: Identifiable, Hashable, Sendable {
    let id: String
    let location: String
    let averageDailyTraffic: Int
    let month: String
    let isLatest: Bool
}
