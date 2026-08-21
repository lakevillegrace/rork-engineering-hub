import Foundation

/// Type-safe destinations pushed onto a hub navigation stack.
nonisolated enum HubRoute: Hashable, Sendable {
    case category(String)
    case permitTracking
    case project(String)
    case trafficCounts
    case liveConditions
    case updates
}
