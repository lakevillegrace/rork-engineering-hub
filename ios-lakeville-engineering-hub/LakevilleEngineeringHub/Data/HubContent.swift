import Foundation

/// Static content model for the Engineering Hub: the six categories, their
/// sections, and seed data for tracking screens. Web links start unconfigured
/// so staff can attach the real SharePoint URLs from inside the app.
nonisolated enum HubContent {
    static let dakotaCountyPhone = "9528917115"
    static let dakotaCountyContactEmail = "rosalee.mccready@co.dakota.mn.us"

    static let categories: [HubCategory] = [
        rowPermitting,
        surveyReview,
        trafficResources,
        capitalProjects,
        developmentReview,
        proceduresResources,
    ]

    static func category(id: String) -> HubCategory? {
        categories.first { $0.id == id }
    }

    // MARK: - ROW & Utility Permitting

    static let rowPermitting = HubCategory(
        id: "row-permitting",
        title: "ROW & Utility Permitting",
        summary: "Permit tracking, utility coordination, fiber construction, restoration and closeout.",
        headerSummary: "Utility and ROW permit review and coordination: permits, fiber construction, restoration and closeout.",
        systemImage: "doc.text.magnifyingglass",
        sections: [
            ResourceSection(
                id: "row-tracking",
                title: "Permit Tracking",
                footnote: "Always check tracking first to confirm current status before responding.",
                links: [
                    ResourceLink(
                        id: "row-tracking-all",
                        title: "Permit Tracking (ALL Inboxes)",
                        systemImage: "tablecells",
                        detail: "ROW · RowM · ENG Survey",
                        action: .route(.permitTracking)
                    ),
                    ResourceLink(id: "row-applications", title: "ROW Permit Applications", systemImage: "tray.full"),
                    ResourceLink(id: "row-fiber-inquiry", title: "ROW/Fiber Inquiry Management", systemImage: "point.3.connected.trianglepath.dotted"),
                    ResourceLink(id: "row-moratorium", title: "Moratorium Notes & Admin Updates", systemImage: "exclamationmark.triangle"),
                ]
            ),
            ResourceSection(
                id: "row-quick-links",
                title: "Quick Links",
                links: [
                    ResourceLink(id: "row-onestop-permits", title: "ROW — One Stop Roadway Permits", systemImage: "link"),
                    ResourceLink(id: "row-onestop-shop", title: "OneStop Roadway Shop", systemImage: "building.columns"),
                    ResourceLink(id: "row-gis", title: "GIS Lakeville ROW Permits", systemImage: "map"),
                    ResourceLink(id: "row-gsoc", title: "FIND One Call Concepts Ticket List", systemImage: "list.bullet.rectangle"),
                    ResourceLink(id: "row-contacts", title: "ROW & General Contacts", systemImage: "person.2"),
                    ResourceLink(
                        id: "row-dakota-phone",
                        title: "Dakota County Permit Office",
                        systemImage: "phone",
                        detail: "(952) 891-7115 — direct applicants here",
                        action: .phone(dakotaCountyPhone)
                    ),
                    ResourceLink(
                        id: "row-dakota-email",
                        title: "Rosalee McCready (Dakota County)",
                        systemImage: "envelope",
                        detail: "Internal staff contact",
                        action: .email(dakotaCountyContactEmail)
                    ),
                ]
            ),
            ResourceSection(
                id: "row-templates",
                title: "Examples & Templates",
                links: [
                    ResourceLink(
                        id: "row-checklist",
                        title: "ROW Checklist",
                        systemImage: "checklist",
                        detail: "Review steps before approval"
                    ),
                    ResourceLink(id: "row-install-example", title: "Installation Plan Example", systemImage: "doc.richtext"),
                    ResourceLink(id: "row-traffic-example", title: "Traffic Control Plan Example", systemImage: "cone"),
                    ResourceLink(id: "row-notice-template", title: "ROW Permit Notice Template", systemImage: "doc.on.doc"),
                    ResourceLink(id: "row-fee-permits", title: "2026 Fee Schedule (Permits)", systemImage: "dollarsign.circle"),
                    ResourceLink(id: "row-fee-full", title: "2026 Fee Schedule (Full)", systemImage: "dollarsign.circle"),
                ]
            ),
        ]
    )

    // MARK: - Survey Review

    static let surveyReview = HubCategory(
        id: "survey-review",
        title: "Survey Review",
        summary: "As-built surveys, building permit certificates, checklists and examples.",
        headerSummary: "As-built surveys, building permit certificates, checklists and examples.",
        systemImage: "camera.metering.matrix",
        sections: [
            ResourceSection(
                id: "survey-inboxes",
                title: "Inboxes",
                links: [
                    ResourceLink(id: "survey-rowm", title: "RowM — As-Built Surveys", systemImage: "map"),
                    ResourceLink(id: "survey-eng", title: "ENG Survey — Building Permit Certificates", systemImage: "doc.text.magnifyingglass"),
                    ResourceLink(
                        id: "survey-tracking",
                        title: "Permit Tracking (ALL Inboxes)",
                        systemImage: "tablecells",
                        action: .route(.permitTracking)
                    ),
                ]
            ),
            ResourceSection(
                id: "survey-quick-links",
                title: "Quick Links",
                links: [
                    ResourceLink(id: "survey-asbuilt-checklist", title: "As-Built Survey Checklist", systemImage: "checklist"),
                    ResourceLink(id: "survey-cos-checklist", title: "Certificate of Survey Checklist", systemImage: "checklist"),
                    ResourceLink(id: "survey-county-contacts", title: "Dakota County Surveyor Contacts", systemImage: "person.2"),
                    ResourceLink(id: "survey-gis", title: "GIS Survey Reference Map", systemImage: "map"),
                ]
            ),
            ResourceSection(
                id: "survey-templates",
                title: "Examples & Templates",
                links: [
                    ResourceLink(id: "survey-asbuilt-example", title: "Approved As-Built Example", systemImage: "doc.richtext"),
                    ResourceLink(id: "survey-cos-example", title: "Certificate of Survey Example", systemImage: "doc.richtext"),
                    ResourceLink(id: "survey-comment-template", title: "Review Comment Notice Template", systemImage: "doc.on.doc"),
                    ResourceLink(id: "survey-submittal", title: "Survey Submittal Requirements", systemImage: "list.clipboard"),
                ]
            ),
        ]
    )

    // MARK: - Traffic Resources

    static let trafficResources = HubCategory(
        id: "traffic-resources",
        title: "Traffic Resources",
        summary: "Traffic counts, mapping, equipment, data processing and crash-review resources.",
        headerSummary: "Traffic counts, mapping, equipment, data processing and crash-review resources.",
        systemImage: "car.2",
        sections: [
            ResourceSection(
                id: "traffic-mapping",
                title: "Mapping & Data",
                links: [
                    ResourceLink(
                        id: "traffic-count-apps",
                        title: "Internal Traffic Count Applications",
                        systemImage: "chart.bar.doc.horizontal",
                        detail: "2026–2029 program"
                    ),
                    ResourceLink(id: "traffic-count-map", title: "Traffic Count Map (GIS)", systemImage: "map"),
                    ResourceLink(id: "traffic-crash-data", title: "Crash Review Data", systemImage: "exclamationmark.triangle"),
                    ResourceLink(id: "traffic-processing-sop", title: "Data Processing SOP", systemImage: "gearshape.2"),
                ]
            ),
            ResourceSection(
                id: "traffic-equipment",
                title: "Equipment & Contacts",
                links: [
                    ResourceLink(id: "traffic-equipment-checkout", title: "Count Equipment Checkout", systemImage: "shippingbox"),
                    ResourceLink(id: "traffic-scheduler", title: "Metro Count Scheduler", systemImage: "calendar"),
                    ResourceLink(id: "traffic-staff", title: "Traffic Staff Contacts", systemImage: "person.2"),
                ]
            ),
        ]
    )

    // MARK: - Capital Projects

    static let capitalProjects = HubCategory(
        id: "capital-projects",
        title: "Capital Projects",
        summary: "Quick access to active City project information and coordination resources.",
        headerSummary: "Quick access to active City project information and coordination resources.",
        systemImage: "hammer",
        sections: [
            ResourceSection(
                id: "cip-resources",
                title: "Project Resources",
                links: [
                    ResourceLink(id: "cip-map", title: "CIP Project Map (GIS)", systemImage: "map"),
                    ResourceLink(id: "cip-notices", title: "Construction Notices & Updates", systemImage: "bell"),
                    ResourceLink(id: "cip-detours", title: "Detour & Traffic Impacts", systemImage: "car"),
                    ResourceLink(id: "cip-contacts", title: "Project Contact List", systemImage: "person.2"),
                ]
            ),
            ResourceSection(
                id: "cip-coordination",
                title: "Coordination",
                links: [
                    ResourceLink(id: "cip-utility-meetings", title: "Utility Coordination Meetings", systemImage: "calendar"),
                    ResourceLink(id: "cip-inspections", title: "Inspection Schedules", systemImage: "checkmark.seal"),
                    ResourceLink(id: "cip-directory", title: "Consultant & Contractor Directory", systemImage: "building.2"),
                ]
            ),
        ]
    )

    // MARK: - Development Review

    static let developmentReview = HubCategory(
        id: "development-review",
        title: "Development Review",
        summary: "Plat, site plan and development engineering review resources.",
        headerSummary: "Plat, site plan and development engineering review resources.",
        systemImage: "building.2",
        sections: [
            ResourceSection(
                id: "dev-review-types",
                title: "Review Types",
                links: [
                    ResourceLink(id: "dev-plat", title: "Plat Review", systemImage: "map"),
                    ResourceLink(id: "dev-site-plan", title: "Site Plan Review", systemImage: "square.grid.3x3.square"),
                    ResourceLink(id: "dev-engineering", title: "Development Engineering Review", systemImage: "camera.metering.matrix"),
                ]
            ),
            ResourceSection(
                id: "dev-applications",
                title: "Applications & Tracking",
                links: [
                    ResourceLink(id: "dev-tracking", title: "Development Review Tracking", systemImage: "list.clipboard"),
                    ResourceLink(id: "dev-forms", title: "Application Forms & Fees", systemImage: "doc.badge.clock"),
                    ResourceLink(id: "dev-preapp", title: "Pre-Application Meetings", systemImage: "person.3"),
                    ResourceLink(id: "dev-deadlines", title: "Comment Deadline Calendar", systemImage: "calendar"),
                ]
            ),
            ResourceSection(
                id: "dev-standards",
                title: "Standards & Templates",
                links: [
                    ResourceLink(id: "dev-standards-manual", title: "Design Standards Manual", systemImage: "book"),
                    ResourceLink(id: "dev-comment-template", title: "Review Comment Template", systemImage: "doc.on.doc"),
                    ResourceLink(id: "dev-plat-checklist", title: "Preliminary Plat Checklist", systemImage: "checklist"),
                    ResourceLink(id: "dev-swppp", title: "Stormwater Requirements (SWPPP)", systemImage: "cloud.rain"),
                ]
            ),
        ]
    )

    // MARK: - Procedures & Resources

    static let proceduresResources = HubCategory(
        id: "procedures-resources",
        title: "Procedures & Resources",
        summary: "Engineering procedures, SOPs, contacts, templates and staff references.",
        headerSummary: "Engineering procedures, SOPs, contacts, templates and staff references.",
        systemImage: "folder.badge.gearshape",
        sections: [
            ResourceSection(
                id: "proc-sops",
                title: "Procedures & SOPs",
                links: [
                    ResourceLink(id: "proc-sop-library", title: "Engineering SOP Library", systemImage: "book"),
                    ResourceLink(id: "proc-permit-review", title: "Permit Review Procedure", systemImage: "checklist"),
                    ResourceLink(id: "proc-records", title: "Records Retention & Filing", systemImage: "archivebox"),
                    ResourceLink(id: "proc-safety", title: "Safety & Field Procedures", systemImage: "shield.lefthalf.filled"),
                ]
            ),
            ResourceSection(
                id: "proc-contacts",
                title: "Contacts",
                links: [
                    ResourceLink(id: "proc-staff-directory", title: "Engineering Staff Directory", systemImage: "person.crop.circle"),
                    ResourceLink(
                        id: "proc-dakota-phone",
                        title: "Dakota County Permit Office",
                        systemImage: "phone",
                        detail: "(952) 891-7115",
                        action: .phone(dakotaCountyPhone)
                    ),
                    ResourceLink(id: "proc-utility-contacts", title: "Utility & Fiber Contacts", systemImage: "person.crop.circle"),
                    ResourceLink(id: "proc-gsoc", title: "GSOC / One Call Concepts", systemImage: "phone.badge.waveform"),
                ]
            ),
            ResourceSection(
                id: "proc-templates",
                title: "Templates & References",
                links: [
                    ResourceLink(id: "proc-notice-templates", title: "Notice & Letter Templates", systemImage: "doc.text"),
                    ResourceLink(id: "proc-fees", title: "Fee Schedules (2026)", systemImage: "dollarsign.circle"),
                    ResourceLink(id: "proc-gis", title: "GIS Maps & Layers", systemImage: "map"),
                    ResourceLink(id: "proc-handbook", title: "Employee Handbook References", systemImage: "book.closed"),
                ]
            ),
        ]
    )

    // MARK: - Checklists

    static let rowChecklistSteps: [String] = [
        "Verify moratorium restrictions",
        "Confirm applicable 2026 fees",
        "Review installation plan",
        "Review traffic control plan",
        "Notify fiber contacts",
        "Issue approval notice from template",
    ]

    static let asBuiltChecklistSteps: [String] = [
        "Confirm submittal is a signed as-built",
        "Check elevations against approved grading plan",
        "Verify utility service locations",
        "Note erosion control status",
        "Log result in tracking spreadsheet",
    ]

    static let certificateChecklistSteps: [String] = [
        "Confirm building permit number matches",
        "Verify setbacks and lot lines",
        "Check drainage & utility easements",
        "Confirm proposed elevations",
        "Return comments using notice template",
    ]

    // MARK: - Seed tracking data

    static func seedPermits(referenceDate: Date = Date()) -> [PermitRecord] {
        let calendar = Calendar.current
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: referenceDate) ?? referenceDate
        }
        return [
            PermitRecord(number: "ROW-2026-0141", applicant: "Xcel Energy", inbox: .row, status: PermitStatus.awaitingRestoration.rawValue, receivedDate: daysAgo(6), note: "Restoration due before winter moratorium."),
            PermitRecord(number: "ROW-2026-0139", applicant: "Frontier Fiber", inbox: .row, status: PermitStatus.underReview.rawValue, receivedDate: daysAgo(8), note: "Traffic control plan needs revision."),
            PermitRecord(number: "ROW-2026-0136", applicant: "Dakota Electric", inbox: .row, status: PermitStatus.approved.rawValue, receivedDate: daysAgo(14)),
            PermitRecord(number: "AB-2026-0087", applicant: "Keavy & Klein Surveying", inbox: .rowM, status: PermitStatus.approved.rawValue, receivedDate: daysAgo(2)),
            PermitRecord(number: "AB-2026-0086", applicant: "Sathre-Bergquist", inbox: .rowM, status: PermitStatus.underReview.rawValue, receivedDate: daysAgo(3)),
            PermitRecord(number: "CS-2026-0032", applicant: "Lennar Homes", inbox: .engSurvey, status: PermitStatus.pendingPickup.rawValue, receivedDate: daysAgo(1)),
            PermitRecord(number: "CS-2026-0031", applicant: "M/I Homes", inbox: .engSurvey, status: PermitStatus.awaitingApplicant.rawValue, receivedDate: daysAgo(5)),
        ]
    }

    static let projects: [CapitalProject] = [
        CapitalProject(
            id: "185th-street",
            name: "185th St Reconstruction — Phase 2",
            phase: "Construction",
            progress: 0.45,
            manager: "City Engineering",
            contractor: "Northwest Asphalt",
            schedule: "May 2026 – Oct 2026",
            scope: "Full-depth reconstruction, storm sewer replacement, trail and signal improvements between Kenwood Trail and Ipava Ave."
        ),
        CapitalProject(
            id: "kenwood-trail",
            name: "Kenwood Trail Improvements",
            phase: "Design",
            progress: 0.20,
            manager: "City Engineering",
            contractor: "Consultant design underway",
            schedule: "Design 2026 · Construction 2027",
            scope: "Pedestrian crossing upgrades, trail widening and drainage improvements along Kenwood Trail."
        ),
        CapitalProject(
            id: "mill-overlay-2026",
            name: "2026 Mill & Overlay Program",
            phase: "Construction",
            progress: 0.60,
            manager: "City Engineering",
            contractor: "Bituminous Roadways",
            schedule: "Jun 2026 – Sep 2026",
            scope: "Annual pavement management program: milling, paving, casting adjustments and striping across selected neighborhoods."
        ),
        CapitalProject(
            id: "holyoke-water-main",
            name: "Holyoke Ave Water Main",
            phase: "Utility Coordination",
            progress: 0.15,
            manager: "City Engineering / Utilities",
            contractor: "TBD — bidding fall 2026",
            schedule: "Coordination 2026 · Construction 2027",
            scope: "Water main replacement with private utility relocation coordination through the downtown corridor."
        ),
    ]

    static let trafficCounts: [TrafficCount] = [
        TrafficCount(id: "tc-1", location: "210th St W", averageDailyTraffic: 8_600, month: "Apr", isLatest: false),
        TrafficCount(id: "tc-2", location: "Dodd Blvd", averageDailyTraffic: 15_200, month: "May", isLatest: false),
        TrafficCount(id: "tc-3", location: "233rd St W", averageDailyTraffic: 12_400, month: "Jun", isLatest: false),
        TrafficCount(id: "tc-4", location: "Kenwood Trl", averageDailyTraffic: 18_900, month: "Jul", isLatest: false),
        TrafficCount(id: "tc-5", location: "Keats Ave", averageDailyTraffic: 4_100, month: "Aug", isLatest: true),
    ]
}
