import Foundation

/// Everything the hub knows about one municipality: its categories, its capital
/// projects and any local traffic-count data.
nonisolated struct ContentPack: Sendable {
    let cityID: String
    let categories: [HubCategory]
    var projects: [CapitalProject] = []
    var trafficCounts: [TrafficCount] = []
    /// Short, honest note about where this city's content comes from.
    var provenance: String?
    /// True when the pack was hand-built for this specific city.
    var isCurated: Bool = false
}

/// Resolves the right content pack for the municipality staff selected.
///
/// Lakeville and Apple Valley ship hand-verified content. Every other Dakota
/// County city and township falls back to a countywide pack so the app is
/// useful everywhere on day one.
nonisolated enum CityContent {
    static func pack(for city: City?) -> ContentPack {
        guard let city else { return generic(for: nil) }
        switch city.id {
        case "lakeville": return lakevillePack
        case "apple-valley": return AppleValleyContent.pack
        default: return generic(for: city)
        }
    }

    // MARK: - Lakeville

    static let lakevillePack = ContentPack(
        cityID: "lakeville",
        categories: HubContent.categories,
        projects: HubContent.projects,
        trafficCounts: HubContent.trafficCounts,
        provenance: "Built for Lakeville Engineering. Link targets are set by staff to your internal SharePoint locations.",
        isCurated: true
    )

    // MARK: - Countywide fallback

    /// A neutral pack for cities without curated content. Every link either
    /// points at a verified public page or is left blank for staff to fill in.
    static func generic(for city: City?) -> ContentPack {
        let cityName = city?.displayName ?? "Dakota County"
        let siteLink: [ResourceLink] = {
            guard let website = city?.website else { return [] }
            return [ResourceLink(
                id: "gen-city-website",
                title: "\(cityName) website",
                systemImage: "globe",
                detail: "Official city site",
                action: .web(defaultURL: website)
            )]
        }()

        return ContentPack(
            cityID: city?.id ?? "county",
            categories: [
                HubCategory(
                    id: "row-permitting",
                    title: "ROW & Utility Permitting",
                    summary: "Right-of-way and utility permit workflow for \(cityName).",
                    headerSummary: "Right-of-way and utility permit review. Attach your city's forms and tracking locations from any row.",
                    systemImage: "doc.text.magnifyingglass",
                    sections: [
                        ResourceSection(
                            id: "gen-row-tracking",
                            title: "Permit Tracking",
                            footnote: "Tracking is stored on this device until you attach your city's system.",
                            links: [
                                ResourceLink(
                                    id: "gen-row-tracking-all",
                                    title: "Permit Tracking (ALL Inboxes)",
                                    systemImage: "tablecells",
                                    action: .route(.permitTracking)
                                ),
                                ResourceLink(id: "gen-row-applications", title: "ROW Permit Applications", systemImage: "tray.full"),
                                ResourceLink(id: "gen-row-moratorium", title: "Moratorium & Restrictions", systemImage: "exclamationmark.triangle"),
                            ]
                        ),
                        countySection(id: "gen-row-county"),
                    ] + (siteLink.isEmpty ? [] : [ResourceSection(id: "gen-row-city", title: "City", links: siteLink)])
                ),
                HubCategory(
                    id: "survey-review",
                    title: "Survey Review",
                    summary: "As-built surveys, certificates of survey and review checklists.",
                    headerSummary: "As-built surveys, building permit certificates and review checklists.",
                    systemImage: "camera.metering.matrix",
                    sections: [
                        ResourceSection(
                            id: "gen-survey-inboxes",
                            title: "Review Queue",
                            links: [
                                ResourceLink(
                                    id: "gen-survey-tracking",
                                    title: "Permit Tracking (ALL Inboxes)",
                                    systemImage: "tablecells",
                                    action: .route(.permitTracking)
                                ),
                                ResourceLink(id: "gen-survey-asbuilt", title: "As-Built Survey Submittals", systemImage: "map"),
                                ResourceLink(id: "gen-survey-cos", title: "Certificate of Survey Submittals", systemImage: "doc.text.magnifyingglass"),
                            ]
                        ),
                        ResourceSection(
                            id: "gen-survey-checklists",
                            title: "Checklists",
                            links: [
                                ResourceLink(id: "gen-survey-asbuilt-checklist", title: "As-Built Survey Checklist", systemImage: "checklist"),
                                ResourceLink(id: "gen-survey-cos-checklist", title: "Certificate of Survey Checklist", systemImage: "checklist"),
                            ]
                        ),
                    ]
                ),
                HubCategory(
                    id: "traffic-resources",
                    title: "Traffic Resources",
                    summary: "Traffic counts, mapping and crash-review resources.",
                    headerSummary: "Traffic counts, mapping and crash-review resources.",
                    systemImage: "car.2",
                    sections: [
                        ResourceSection(
                            id: "gen-traffic-data",
                            title: "Mapping & Data",
                            links: [
                                countyAADTLink(id: "gen-traffic-county-aadt"),
                                ResourceLink(id: "gen-traffic-counts", title: "Local Traffic Count Records", systemImage: "chart.bar.doc.horizontal"),
                                ResourceLink(id: "gen-traffic-crash", title: "Crash Review Data", systemImage: "exclamationmark.triangle"),
                            ]
                        ),
                    ]
                ),
                HubCategory(
                    id: "capital-projects",
                    title: "Capital Projects",
                    summary: "Active construction, coordination and project information.",
                    headerSummary: "Active construction, coordination and project information.",
                    systemImage: "hammer",
                    sections: [
                        ResourceSection(
                            id: "gen-cip-live",
                            title: "Live Data",
                            footnote: "County road work near \(cityName) is pulled automatically.",
                            links: [
                                ResourceLink(
                                    id: "gen-cip-live-conditions",
                                    title: "Live Conditions",
                                    systemImage: "dot.radiowaves.left.and.right",
                                    detail: "Closures and work zones from county GIS",
                                    action: .route(.liveConditions)
                                ),
                            ]
                        ),
                        ResourceSection(
                            id: "gen-cip-resources",
                            title: "Project Resources",
                            links: [
                                ResourceLink(id: "gen-cip-notices", title: "Construction Notices & Updates", systemImage: "bell"),
                                ResourceLink(id: "gen-cip-contacts", title: "Project Contact List", systemImage: "person.2"),
                                ResourceLink(id: "gen-cip-directory", title: "Consultant & Contractor Directory", systemImage: "building.2"),
                            ]
                        ),
                    ]
                ),
                HubCategory(
                    id: "development-review",
                    title: "Development Review",
                    summary: "Plat, site plan and development engineering review.",
                    headerSummary: "Plat, site plan and development engineering review.",
                    systemImage: "building.2",
                    sections: [
                        ResourceSection(
                            id: "gen-dev-tracking",
                            title: "Applications & Tracking",
                            links: [
                                ResourceLink(id: "gen-dev-tracking-list", title: "Development Review Tracking", systemImage: "list.clipboard"),
                                ResourceLink(id: "gen-dev-forms", title: "Application Forms & Fees", systemImage: "doc.badge.clock"),
                                ResourceLink(id: "gen-dev-deadlines", title: "Submittal Deadline Calendar", systemImage: "calendar"),
                            ]
                        ),
                        ResourceSection(
                            id: "gen-dev-standards",
                            title: "Standards",
                            links: [
                                ResourceLink(id: "gen-dev-standards-manual", title: "Design Standards Manual", systemImage: "book"),
                                ResourceLink(id: "gen-dev-swppp", title: "Stormwater Requirements (SWPPP)", systemImage: "cloud.rain"),
                            ]
                        ),
                    ]
                ),
                HubCategory(
                    id: "procedures-resources",
                    title: "Procedures & Resources",
                    summary: "Procedures, contacts, templates and staff references.",
                    headerSummary: "Procedures, contacts, templates and staff references.",
                    systemImage: "folder.badge.gearshape",
                    sections: [
                        ResourceSection(
                            id: "gen-proc-sops",
                            title: "Procedures",
                            links: [
                                ResourceLink(id: "gen-proc-sop-library", title: "Engineering SOP Library", systemImage: "book"),
                                ResourceLink(id: "gen-proc-safety", title: "Safety & Field Procedures", systemImage: "shield.lefthalf.filled"),
                                ResourceLink(id: "gen-proc-records", title: "Records Retention & Filing", systemImage: "archivebox"),
                            ]
                        ),
                        countySection(id: "gen-proc-county"),
                    ] + (siteLink.isEmpty ? [] : [ResourceSection(id: "gen-proc-city", title: "City", links: siteLink)])
                ),
            ],
            provenance: city?.website == nil
                ? "Countywide template. No public website was verified for \(cityName) — attach your own addresses to any row."
                : "Countywide template plus \(cityName)'s public website. Attach your internal addresses to any row.",
            isCurated: false
        )
    }

    /// Shared, verified Dakota County contacts used by every non-curated pack.
    private static func countySection(id: String) -> ResourceSection {
        ResourceSection(
            id: id,
            title: "Dakota County",
            links: [
                ResourceLink(
                    id: "\(id)-permit-phone",
                    title: "Dakota County Permit Office",
                    systemImage: "phone",
                    detail: "(952) 891-7115",
                    action: .phone("9528917115")
                ),
                ResourceLink(
                    id: "\(id)-main-phone",
                    title: "Dakota County (main)",
                    systemImage: "phone",
                    detail: "(651) 437-3191",
                    action: .phone("6514373191")
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

    /// Dakota County's public annual-average-daily-traffic service.
    private static func countyAADTLink(id: String) -> ResourceLink {
        ResourceLink(
            id: id,
            title: "Dakota County Traffic Counts (AADT)",
            systemImage: "chart.bar.doc.horizontal",
            detail: "Public county GIS service",
            action: .web(defaultURL: "https://gis2.co.dakota.mn.us/arcgis/rest/services/AGOL/DC_OL_TRANSTRAFFIC_AADTCounts/MapServer")
        )
    }

    // MARK: - Cross-pack lookup

    /// Every link the app can produce, across all packs. Used so pinned rows and
    /// exported configurations keep readable titles no matter which city is active.
    static let allLinks: [ResourceLink] = {
        let packs = [lakevillePack, AppleValleyContent.pack, generic(for: nil)]
        var seen = Set<String>()
        var result: [ResourceLink] = []
        for pack in packs {
            for category in pack.categories {
                for section in category.sections {
                    for link in section.links where !seen.contains(link.id) {
                        seen.insert(link.id)
                        result.append(link)
                    }
                }
            }
        }
        return result
    }()

    /// The category title a link belongs to, searched across every pack.
    static func categoryTitle(for link: ResourceLink) -> String {
        let packs = [lakevillePack, AppleValleyContent.pack, generic(for: nil)]
        for pack in packs {
            if let match = pack.categories.first(where: { category in
                category.sections.contains { $0.links.contains { $0.id == link.id } }
            }) {
                return match.title
            }
        }
        return "Other"
    }
}
