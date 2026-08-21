import Foundation

/// A configurable ArcGIS layer the app polls for live field conditions.
///
/// Built-in sources cover countywide data that works for every Dakota County
/// city. Staff can add their own city layers without an app update.
nonisolated struct LiveSource: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var title: String
    var category: LiveCategory
    var layerURL: String
    var whereClause: String
    var titleField: String
    var subtitleField: String?
    var detailField: String?
    var impactField: String?
    var startField: String?
    var finishField: String?
    var ownerField: String?
    var urlField: String?
    var updatedField: String?
    /// Field holding the municipality name, enabling server-side city filters.
    var cityField: String?
    /// When set, records sharing the same title and this field's value collapse
    /// into one row. County centreline layers split a single street into dozens
    /// of address-range records, which otherwise read as duplicates.
    var groupField: String?
    /// Clips the query to Dakota County's extent, for statewide layers such as
    /// MnDOT 511.
    var countyExtentOnly: Bool?
    var isBuiltIn: Bool = false
    var isEnabled: Bool = true

    var limitsToCounty: Bool { countyExtentOnly == true }

    /// Fields requested from the service, or `*` when the mapping is sparse.
    var outFields: String {
        let fields = [
            titleField, subtitleField, detailField, impactField, startField,
            finishField, ownerField, urlField, updatedField, cityField, groupField,
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return fields.isEmpty ? "*" : Set(fields).sorted().joined(separator: ",")
    }

    /// Escapes a municipality name for an ArcGIS SQL `where` clause.
    func whereClause(forCity city: City?) -> String {
        guard let cityField, !cityField.isEmpty, let city else { return whereClause }
        let escaped = city.gisName.replacingOccurrences(of: "'", with: "''")
        let cityPredicate = "UPPER(\(cityField))='\(escaped.uppercased())'"
        guard whereClause != "1=1", !whereClause.isEmpty else { return cityPredicate }
        return "(\(whereClause)) AND \(cityPredicate)"
    }
}

extension LiveSource {
    /// Countywide layers published by Dakota County. These are public,
    /// read-only endpoints that serve every city in the county.
    static let builtIns: [LiveSource] = [
        LiveSource(
            id: "dakota-transportation-projects",
            title: "Dakota County Construction Projects",
            category: .project,
            layerURL: "https://gis2.co.dakota.mn.us/arcgis/rest/services/AGOL/DC_OL_TRANS_TransportationProjects_PUBLIC/MapServer/0",
            whereClause: "CURRENT_='Yes'",
            titleField: "ROADNAME",
            subtitleField: "LOCATIONDESCRIPTION",
            detailField: "PROJECTWORK",
            impactField: "CONST_IMPACT",
            startField: "CONST_START",
            finishField: "CONST_FINISH",
            ownerField: "CONST_ENGINEER",
            urlField: "CONST_URL",
            updatedField: "UPDATEDATE",
            cityField: nil,
            isBuiltIn: true
        ),
        LiveSource(
            id: "dakota-mill-overlay",
            title: "Dakota County Mill & Overlay",
            category: .project,
            // The layer carries the whole street centreline network; only
            // records with a program year are actually in the paving program.
            layerURL: "https://gis2.co.dakota.mn.us/arcgis/rest/services/AGOL/DC_OL_TRANS_MillAndOverlayProject_PUBLIC/FeatureServer/0",
            whereClause: "ProgramYear IS NOT NULL",
            titleField: "STREET_NAM",
            subtitleField: "ProgramYear",
            detailField: "Strategy",
            impactField: nil,
            startField: nil,
            finishField: nil,
            ownerField: "RoadNo",
            urlField: nil,
            updatedField: nil,
            cityField: "CITY_L",
            groupField: "ProgramYear",
            isBuiltIn: true
        ),
        LiveSource(
            id: "mndot-511-events",
            title: "MnDOT 511 Traveler Information",
            category: .project,
            layerURL: "https://services.arcgis.com/8lRhdTsQyJpO52F1/arcgis/rest/services/CARS511_MN_Events_View/FeatureServer/0",
            whereClause: "1=1",
            titleField: "headline",
            subtitleField: "Route",
            detailField: "Restrict_",
            impactField: "phrase",
            startField: nil,
            finishField: nil,
            ownerField: nil,
            urlField: "linktxt",
            updatedField: nil,
            cityField: nil,
            groupField: nil,
            countyExtentOnly: true,
            isBuiltIn: true
        ),
    ]
}
