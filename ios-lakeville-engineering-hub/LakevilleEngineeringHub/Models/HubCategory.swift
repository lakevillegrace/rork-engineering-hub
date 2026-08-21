import Foundation

/// One of the six top-level Engineering Hub categories.
nonisolated struct HubCategory: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String
    let headerSummary: String
    let systemImage: String
    let sections: [ResourceSection]
}
