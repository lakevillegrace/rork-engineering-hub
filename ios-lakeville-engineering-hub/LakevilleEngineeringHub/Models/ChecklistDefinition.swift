import Foundation

/// A staff checklist that can be worked through inside the app.
nonisolated struct ChecklistDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let steps: [String]
}

/// Maps resource rows to the checklists they open.
nonisolated enum ChecklistCatalog {
    static let rowPermit = ChecklistDefinition(
        id: "row-checklist",
        title: "ROW Checklist",
        subtitle: "Confirm moratorium restrictions and applicable fees prior to approval.",
        steps: HubContent.rowChecklistSteps
    )

    static let asBuilt = ChecklistDefinition(
        id: "survey-asbuilt-checklist",
        title: "As-Built Survey Checklist",
        subtitle: "Review steps for RowM as-built submittals.",
        steps: HubContent.asBuiltChecklistSteps
    )

    static let certificateOfSurvey = ChecklistDefinition(
        id: "survey-cos-checklist",
        title: "Certificate of Survey Checklist",
        subtitle: "Review steps for ENG Survey building permit certificates.",
        steps: HubContent.certificateChecklistSteps
    )

    static let preliminaryPlat = ChecklistDefinition(
        id: "dev-plat-checklist",
        title: "Preliminary Plat Checklist",
        subtitle: "Engineering review items for preliminary plat submittals.",
        steps: [
            "Confirm right-of-way widths and easements",
            "Review street and intersection geometrics",
            "Check sanitary, water and storm layouts",
            "Verify stormwater management and ponding",
            "Confirm trail and sidewalk connections",
            "Compile comments using the review template",
        ]
    )

    static let all: [ChecklistDefinition] = [rowPermit, asBuilt, certificateOfSurvey, preliminaryPlat]

    static func definition(forLinkID id: String) -> ChecklistDefinition? {
        all.first { $0.id == id }
    }
}
