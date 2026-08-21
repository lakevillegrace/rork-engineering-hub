import Foundation

/// The three shared Engineering inboxes permits are tracked in.
nonisolated enum PermitInbox: String, CaseIterable, Codable, Identifiable, Sendable {
    case row = "ROW"
    case rowM = "RowM"
    case engSurvey = "ENG Survey"

    nonisolated var id: String { rawValue }

    var shortLabel: String { rawValue }

    var longLabel: String {
        switch self {
        case .row: "ROW Permits"
        case .rowM: "As-Built Surveys"
        case .engSurvey: "Certificate of Surveys"
        }
    }

    var systemImage: String {
        switch self {
        case .row: "doc.badge.gearshape"
        case .rowM: "map"
        case .engSurvey: "doc.text.magnifyingglass"
        }
    }
}

/// A tracked permit or survey submittal.
nonisolated struct PermitRecord: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var number: String
    var applicant: String
    var inbox: PermitInbox
    var status: String
    var receivedDate: Date
    var note: String

    init(
        id: UUID = UUID(),
        number: String,
        applicant: String,
        inbox: PermitInbox,
        status: String,
        receivedDate: Date,
        note: String = ""
    ) {
        self.id = id
        self.number = number
        self.applicant = applicant
        self.inbox = inbox
        self.status = status
        self.receivedDate = receivedDate
        self.note = note
    }
}

/// Workflow states a tracked submittal can be in.
nonisolated enum PermitStatus: String, CaseIterable, Identifiable, Sendable {
    case underReview = "Under Review"
    case awaitingRestoration = "Awaiting Restoration"
    case awaitingApplicant = "Awaiting Applicant"
    case approved = "Approved"
    case pendingPickup = "Pending Pickup"
    case closed = "Closed"

    nonisolated var id: String { rawValue }

    /// Statuses that still need staff action.
    var isOpen: Bool {
        switch self {
        case .approved, .closed: false
        default: true
        }
    }
}
