import Foundation

/// Curated content for the City of Apple Valley.
///
/// Every web address below was verified against applevalleymn.gov before being
/// added. Phone numbers and the Public Works address come from the City's
/// Engineering and project pages. Staff can still override any row with an
/// internal SharePoint address from inside the app.
nonisolated enum AppleValleyContent {
    private static let site = "https://www.applevalleymn.gov"

    /// Engineering front desk, published on the City's project notices.
    static let engineeringPhone = "9529532425"
    /// Public Works main line, published on the Engineering page.
    static let publicWorksPhone = "9529532500"
    static let publicWorksEmail = "pubworks@applevalleymn.gov"
    static let publicWorksAddress = "7100 147th Street W, Apple Valley"

    static let pack = ContentPack(
        cityID: "apple-valley",
        categories: [
            rowPermitting,
            surveyReview,
            trafficResources,
            capitalProjects,
            developmentReview,
            proceduresResources,
        ],
        projects: projects,
        trafficCounts: [],
        provenance: "Links verified against applevalleymn.gov. Apple Valley's own GIS server requires a token, so live road data comes from Dakota County.",
        isCurated: true
    )

    // MARK: - ROW & Utility Permitting

    static let rowPermitting = HubCategory(
        id: "row-permitting",
        title: "ROW & Utility Permitting",
        summary: "Right-of-way work, permits, technical specifications and utility coordination.",
        headerSummary: "Right-of-way work, permits, technical specifications and utility coordination for Apple Valley.",
        systemImage: "doc.text.magnifyingglass",
        sections: [
            ResourceSection(
                id: "av-row-tracking",
                title: "Permit Tracking",
                footnote: "Tracking is stored on this device. Attach your internal spreadsheet to any row below.",
                links: [
                    ResourceLink(
                        id: "av-row-tracking-all",
                        title: "Permit Tracking (ALL Inboxes)",
                        systemImage: "tablecells",
                        detail: "ROW · RowM · ENG Survey",
                        action: .route(.permitTracking)
                    ),
                    ResourceLink(
                        id: "av-row-current-work",
                        title: "Current Right-of-Way Work",
                        systemImage: "cone",
                        detail: "City page listing active ROW permits",
                        action: .web(defaultURL: "\(site)/1215/Current-Right-of-Way-Work")
                    ),
                    ResourceLink(id: "av-row-inquiries", title: "ROW / Fiber Inquiry Log", systemImage: "point.3.connected.trianglepath.dotted"),
                    ResourceLink(id: "av-row-moratorium", title: "Moratorium Notes & Restrictions", systemImage: "exclamationmark.triangle"),
                ]
            ),
            ResourceSection(
                id: "av-row-permits",
                title: "Permits & Applications",
                links: [
                    ResourceLink(
                        id: "av-licenses-permits",
                        title: "Licenses and Permits",
                        systemImage: "tray.full",
                        action: .web(defaultURL: "\(site)/1017/Licenses-and-Permits")
                    ),
                    ResourceLink(
                        id: "av-permits-regulations",
                        title: "Permits & Regulations",
                        systemImage: "list.bullet.rectangle",
                        action: .web(defaultURL: "\(site)/1149/Permits-Regulations")
                    ),
                    ResourceLink(
                        id: "av-nrmp",
                        title: "Natural Resources Management Permit (NRMP)",
                        systemImage: "leaf",
                        detail: "Required for land-disturbing work",
                        action: .web(defaultURL: "\(site)/229/Natural-Resources-Management-Permit-NRMP")
                    ),
                    ResourceLink(
                        id: "av-tech-specs",
                        title: "2026 Technical Specifications",
                        systemImage: "book",
                        detail: "City construction standards",
                        action: .web(defaultURL: "\(site)/1016/2026-Technical-Specifications")
                    ),
                ]
            ),
            contactsSection(id: "av-row-contacts"),
        ]
    )

    // MARK: - Survey Review

    static let surveyReview = HubCategory(
        id: "survey-review",
        title: "Survey Review",
        summary: "As-built surveys, building permit certificates, mapping and checklists.",
        headerSummary: "As-built surveys, building permit certificates, mapping and checklists.",
        systemImage: "camera.metering.matrix",
        sections: [
            ResourceSection(
                id: "av-survey-queue",
                title: "Review Queue",
                links: [
                    ResourceLink(
                        id: "av-survey-tracking",
                        title: "Permit Tracking (ALL Inboxes)",
                        systemImage: "tablecells",
                        action: .route(.permitTracking)
                    ),
                    ResourceLink(
                        id: "av-building-inspections",
                        title: "Building Inspections",
                        systemImage: "hammer",
                        detail: "Permit and inspection information",
                        action: .web(defaultURL: "\(site)/1070/Building-Inspections")
                    ),
                    ResourceLink(id: "av-survey-asbuilt-inbox", title: "As-Built Survey Submittals", systemImage: "map"),
                    ResourceLink(id: "av-survey-cos-inbox", title: "Certificate of Survey Submittals", systemImage: "doc.text.magnifyingglass"),
                ]
            ),
            ResourceSection(
                id: "av-survey-mapping",
                title: "Mapping",
                links: [
                    ResourceLink(
                        id: "av-city-maps",
                        title: "City Maps",
                        systemImage: "map",
                        action: .web(defaultURL: "\(site)/192/City-Maps")
                    ),
                    ResourceLink(
                        id: "av-development-map-survey",
                        title: "Development Map",
                        systemImage: "square.grid.3x3.square",
                        detail: "Active development sites",
                        action: .web(defaultURL: "\(site)/1136/Development-Map")
                    ),
                ]
            ),
            ResourceSection(
                id: "av-survey-checklists",
                title: "Checklists & Templates",
                links: [
                    ResourceLink(id: "av-asbuilt-checklist", title: "As-Built Survey Checklist", systemImage: "checklist"),
                    ResourceLink(id: "av-cos-checklist", title: "Certificate of Survey Checklist", systemImage: "checklist"),
                    ResourceLink(id: "av-survey-comment-template", title: "Review Comment Notice Template", systemImage: "doc.on.doc"),
                ]
            ),
        ]
    )

    // MARK: - Traffic Resources

    static let trafficResources = HubCategory(
        id: "traffic-resources",
        title: "Traffic Resources",
        summary: "Traffic safety, signs and signals, street maintenance and count data.",
        headerSummary: "Traffic safety, signs and signals, street maintenance and count data.",
        systemImage: "car.2",
        sections: [
            ResourceSection(
                id: "av-traffic-city",
                title: "City Traffic",
                links: [
                    ResourceLink(
                        id: "av-traffic-safety",
                        title: "Traffic Safety",
                        systemImage: "exclamationmark.triangle",
                        action: .web(defaultURL: "\(site)/306/Traffic-Safety")
                    ),
                    ResourceLink(
                        id: "av-traffic-signs",
                        title: "Street Signs, Traffic Signs & Signals",
                        systemImage: "signpost.right",
                        action: .web(defaultURL: "\(site)/305/Street-Signs-Traffic-Signs-Traffic-Signa")
                    ),
                    ResourceLink(
                        id: "av-streetlights",
                        title: "Streetlights",
                        systemImage: "lightbulb",
                        action: .web(defaultURL: "\(site)/304/Streetlights")
                    ),
                    ResourceLink(
                        id: "av-street-maintenance",
                        title: "Street Maintenance & Potholes",
                        systemImage: "wrench.and.screwdriver",
                        action: .web(defaultURL: "\(site)/303/Street-Maintenance-Potholes")
                    ),
                ]
            ),
            ResourceSection(
                id: "av-traffic-data",
                title: "Count & Planning Data",
                links: [
                    ResourceLink(
                        id: "av-county-aadt",
                        title: "Dakota County Traffic Counts (AADT)",
                        systemImage: "chart.bar.doc.horizontal",
                        detail: "Public county GIS service",
                        action: .web(defaultURL: "https://gis2.co.dakota.mn.us/arcgis/rest/services/AGOL/DC_OL_TRANSTRAFFIC_AADTCounts/MapServer")
                    ),
                    ResourceLink(
                        id: "av-bike-ped-plan",
                        title: "Bicycle and Pedestrian Plan",
                        systemImage: "figure.walk",
                        action: .web(defaultURL: "\(site)/1039/Bicycle-and-Pedestrian-Plan")
                    ),
                    ResourceLink(id: "av-traffic-counts-internal", title: "Internal Count Records", systemImage: "tablecells"),
                    ResourceLink(id: "av-crash-data", title: "Crash Review Data", systemImage: "car.side.rear.and.collision.and.car.side.front"),
                ]
            ),
        ]
    )

    // MARK: - Capital Projects

    static let capitalProjects = HubCategory(
        id: "capital-projects",
        title: "Capital Projects",
        summary: "Apple Valley's construction program, park projects and live road work.",
        headerSummary: "Apple Valley's construction program, park projects and live road work.",
        systemImage: "hammer",
        sections: [
            ResourceSection(
                id: "av-cip-live",
                title: "Live Data",
                footnote: "Pulled automatically from Dakota County GIS — no login required.",
                links: [
                    ResourceLink(
                        id: "av-live-conditions",
                        title: "Live Conditions",
                        systemImage: "dot.radiowaves.left.and.right",
                        detail: "Closures and work zones near Apple Valley",
                        action: .route(.liveConditions)
                    ),
                ]
            ),
            ResourceSection(
                id: "av-cip-program",
                title: "Construction Program",
                links: [
                    ResourceLink(
                        id: "av-cip-2026",
                        title: "2026 Construction Projects",
                        systemImage: "calendar",
                        action: .web(defaultURL: "\(site)/1193/2026-Construction-Projects")
                    ),
                    ResourceLink(
                        id: "av-cip-2027",
                        title: "2027 Construction Projects",
                        systemImage: "calendar",
                        action: .web(defaultURL: "\(site)/1285/2027-Construction-Projects")
                    ),
                    ResourceLink(
                        id: "av-cip-improvements",
                        title: "City Improvement Projects",
                        systemImage: "list.clipboard",
                        action: .web(defaultURL: "\(site)/1096/City-Improvement-Projects")
                    ),
                    ResourceLink(
                        id: "av-park-projects",
                        title: "Park Projects",
                        systemImage: "tree",
                        action: .web(defaultURL: "\(site)/1188/Park-Projects")
                    ),
                ]
            ),
            ResourceSection(
                id: "av-cip-coordination",
                title: "Coordination",
                links: [
                    ResourceLink(id: "av-cip-utility-meetings", title: "Utility Coordination Meetings", systemImage: "calendar.badge.clock"),
                    ResourceLink(id: "av-cip-inspections", title: "Inspection Schedules", systemImage: "checkmark.seal"),
                    ResourceLink(id: "av-cip-directory", title: "Consultant & Contractor Directory", systemImage: "building.2"),
                ]
            ),
        ]
    )

    // MARK: - Development Review

    static let developmentReview = HubCategory(
        id: "development-review",
        title: "Development Review",
        summary: "Development mapping, planning deadlines, stormwater and comprehensive planning.",
        headerSummary: "Development mapping, planning deadlines, stormwater and comprehensive planning.",
        systemImage: "building.2",
        sections: [
            ResourceSection(
                id: "av-dev-active",
                title: "Active Development",
                links: [
                    ResourceLink(
                        id: "av-development-map",
                        title: "Development Map",
                        systemImage: "square.grid.3x3.square",
                        detail: "Where things are being built",
                        action: .web(defaultURL: "\(site)/1136/Development-Map")
                    ),
                    ResourceLink(
                        id: "av-planning-calendar",
                        title: "Planning Commission Calendar & Deadlines",
                        systemImage: "calendar",
                        detail: "Submittal deadlines",
                        action: .web(defaultURL: "\(site)/1242/Planning-Commission-Calendar-and-Submitt")
                    ),
                    ResourceLink(id: "av-dev-tracking", title: "Development Review Tracking", systemImage: "list.clipboard"),
                    ResourceLink(id: "av-dev-preapp", title: "Pre-Application Meetings", systemImage: "person.3"),
                ]
            ),
            ResourceSection(
                id: "av-dev-standards",
                title: "Standards & Environmental",
                links: [
                    ResourceLink(
                        id: "av-dev-tech-specs",
                        title: "2026 Technical Specifications",
                        systemImage: "book",
                        action: .web(defaultURL: "\(site)/1016/2026-Technical-Specifications")
                    ),
                    ResourceLink(
                        id: "av-swppp",
                        title: "Stormwater Pollution Prevention Plan Program",
                        systemImage: "cloud.rain",
                        action: .web(defaultURL: "\(site)/372/Stormwater-Pollution-Prevention-Plan-Pro")
                    ),
                    ResourceLink(
                        id: "av-water-resources",
                        title: "Water Resources",
                        systemImage: "drop",
                        action: .web(defaultURL: "\(site)/231/Water-Resources")
                    ),
                    ResourceLink(
                        id: "av-nrm-plans",
                        title: "Natural Resources Management Plans",
                        systemImage: "leaf",
                        action: .web(defaultURL: "\(site)/1244/Natural-Resources-Management-Plans")
                    ),
                    ResourceLink(
                        id: "av-comp-plan",
                        title: "2050 Comprehensive Plan Update",
                        systemImage: "doc.text",
                        action: .web(defaultURL: "\(site)/1259/2050-Comprehensive-Plan-Update")
                    ),
                ]
            ),
        ]
    )

    // MARK: - Procedures & Resources

    static let proceduresResources = HubCategory(
        id: "procedures-resources",
        title: "Procedures & Resources",
        summary: "Engineering and Public Works references, utility systems and contacts.",
        headerSummary: "Engineering and Public Works references, utility systems and contacts.",
        systemImage: "folder.badge.gearshape",
        sections: [
            ResourceSection(
                id: "av-proc-departments",
                title: "Engineering & Public Works",
                links: [
                    ResourceLink(
                        id: "av-engineering",
                        title: "Engineering",
                        systemImage: "compass.drawing",
                        detail: "A division of Public Works",
                        action: .web(defaultURL: "\(site)/1071/Engineering")
                    ),
                    ResourceLink(
                        id: "av-streets",
                        title: "Streets",
                        systemImage: "road.lanes",
                        action: .web(defaultURL: "\(site)/293/Streets")
                    ),
                    ResourceLink(
                        id: "av-water-sewer",
                        title: "Water & Sewer",
                        systemImage: "drop.circle",
                        action: .web(defaultURL: "\(site)/294/Water-Sewer")
                    ),
                ]
            ),
            ResourceSection(
                id: "av-proc-systems",
                title: "Utility Systems",
                links: [
                    ResourceLink(
                        id: "av-drinking-water",
                        title: "Drinking Water System",
                        systemImage: "drop.fill",
                        action: .web(defaultURL: "\(site)/307/Drinking-Water-System")
                    ),
                    ResourceLink(
                        id: "av-sanitary-sewer",
                        title: "Sanitary Sewer System",
                        systemImage: "arrow.down.circle",
                        action: .web(defaultURL: "\(site)/308/Sanitary-Sewer-System")
                    ),
                    ResourceLink(
                        id: "av-storm-drainage",
                        title: "Storm Drainage System",
                        systemImage: "cloud.heavyrain",
                        action: .web(defaultURL: "\(site)/309/Storm-Drainage-System")
                    ),
                    ResourceLink(
                        id: "av-stormwater-ponds",
                        title: "Stormwater Ponds",
                        systemImage: "water.waves",
                        action: .web(defaultURL: "\(site)/378/Stormwater-Ponds")
                    ),
                    ResourceLink(
                        id: "av-lakes-ponds",
                        title: "Lakes, Ponds & Surface Water",
                        systemImage: "water.waves.and.arrow.trianglehead.up",
                        action: .web(defaultURL: "\(site)/371/Lakes-Ponds-Surface-Water-Mgmt")
                    ),
                ]
            ),
            ResourceSection(
                id: "av-proc-internal",
                title: "Internal Procedures",
                links: [
                    ResourceLink(id: "av-sop-library", title: "Engineering SOP Library", systemImage: "book.closed"),
                    ResourceLink(id: "av-permit-review-sop", title: "Permit Review Procedure", systemImage: "checklist"),
                    ResourceLink(id: "av-safety", title: "Safety & Field Procedures", systemImage: "shield.lefthalf.filled"),
                    ResourceLink(id: "av-records", title: "Records Retention & Filing", systemImage: "archivebox"),
                ]
            ),
            contactsSection(id: "av-proc-contacts"),
        ]
    )

    // MARK: - Contacts

    private static func contactsSection(id: String) -> ResourceSection {
        ResourceSection(
            id: id,
            title: "Contacts",
            footnote: publicWorksAddress,
            links: [
                ResourceLink(
                    id: "\(id)-engineering-phone",
                    title: "Apple Valley Engineering",
                    systemImage: "phone",
                    detail: "(952) 953-2425",
                    action: .phone(engineeringPhone)
                ),
                ResourceLink(
                    id: "\(id)-public-works-phone",
                    title: "Apple Valley Public Works",
                    systemImage: "phone",
                    detail: "(952) 953-2500",
                    action: .phone(publicWorksPhone)
                ),
                ResourceLink(
                    id: "\(id)-public-works-email",
                    title: "Public Works (email)",
                    systemImage: "envelope",
                    detail: publicWorksEmail,
                    action: .email(publicWorksEmail)
                ),
                ResourceLink(
                    id: "\(id)-county-permit",
                    title: "Dakota County Permit Office",
                    systemImage: "phone",
                    detail: "(952) 891-7115",
                    action: .phone("9528917115")
                ),
                ResourceLink(
                    id: "\(id)-gopher",
                    title: "Gopher State One Call",
                    systemImage: "phone.badge.waveform",
                    detail: "811 before you dig",
                    action: .phone("811")
                ),
            ]
        )
    }

    // MARK: - Projects

    /// Real Apple Valley capital projects, each linked to its published City page.
    /// Percent-complete is intentionally omitted — the City does not publish it.
    static let projects: [CapitalProject] = [
        CapitalProject(
            id: "av-2026-101",
            name: "2026 Street & Utility Improvements",
            phase: "2026 Program",
            manager: "Apple Valley Engineering",
            schedule: "2026 construction season",
            scope: "Street and utility improvements. Scope, maps and resident notices are published on the City project page.",
            infoURL: "https://www.applevalleymn.gov/1206/2026-Street-Utility-Improvements-2026-10",
            projectNumber: "2026-101"
        ),
        CapitalProject(
            id: "av-2026-105",
            name: "2026 Street Improvements",
            phase: "2026 Program",
            manager: "Apple Valley Engineering",
            schedule: "2026 construction season",
            scope: "Street improvements. Contact Engineering at (952) 953-2425 for current status.",
            infoURL: "https://www.applevalleymn.gov/1219/2026-Street-Improvements-2026-105",
            projectNumber: "2026-105"
        ),
        CapitalProject(
            id: "av-2026-109",
            name: "Central Village Street Improvements — Phase 2",
            phase: "Construction",
            manager: "Apple Valley Engineering",
            schedule: "Work hours Mon–Fri 7am–7pm, Sat 8am–5pm",
            scope: "Includes a 153rd Street closure with a resident access map. Schedules are subject to change due to weather and other conditions.",
            infoURL: "https://www.applevalleymn.gov/1202/Central-Village-Street-Improvements-Phas",
            projectNumber: "2026-109"
        ),
        CapitalProject(
            id: "av-2026-107",
            name: "Apple Valley Additions Stormwater Feasibility Study",
            phase: "Feasibility",
            manager: "Apple Valley Engineering",
            schedule: "Study phase",
            scope: "Stormwater feasibility study. A copy of the feasibility report is available upon request from the City.",
            infoURL: "https://www.applevalleymn.gov/1194/Apple-Valley-Additions-Stormwater-Feasib",
            projectNumber: "2026-107"
        ),
        CapitalProject(
            id: "av-2026-152",
            name: "2026–2027 CIPP Sanitary Sewer Improvements",
            phase: "2026 Program",
            manager: "Apple Valley Engineering",
            schedule: "Bid on a 2-year timeline",
            scope: "Cured-in-place pipe sanitary sewer lining. Bid across two years for better unit pricing and scheduling flexibility.",
            infoURL: "https://www.applevalleymn.gov/1284/2026-2027-CIPP-Sanitary-Sewer-Improvemen",
            projectNumber: "2026-152"
        ),
        CapitalProject(
            id: "av-2025-106",
            name: "Sanitary Sewer (CIPP) Improvements",
            phase: "2025 Program",
            manager: "Apple Valley Engineering",
            schedule: "2025 program",
            scope: "Cured-in-place pipe sanitary sewer rehabilitation.",
            infoURL: "https://www.applevalleymn.gov/1212/Sanitary-Sewer-CIPP-Improvements-2025-10",
            projectNumber: "2025-106"
        ),
        CapitalProject(
            id: "av-2027-104",
            name: "145th Street (Hayes to Pennock) Improvements",
            phase: "2027 Program",
            manager: "Apple Valley Engineering",
            schedule: "Planned for 2027",
            scope: "Street improvements on 145th Street between Hayes Road and Pennock Avenue.",
            infoURL: "https://www.applevalleymn.gov/1286/145th-Street-Hayes-to-Pennock-Improvemen",
            projectNumber: "2027-104"
        ),
    ]
}
