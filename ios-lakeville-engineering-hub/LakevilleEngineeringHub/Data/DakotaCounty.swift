import Foundation

/// The municipalities of Dakota County, Minnesota.
///
/// `gisName` matches the values Dakota County GIS publishes in its `CITY_L`
/// fields, which is what makes per-city filtering of countywide layers work.
nonisolated enum DakotaCounty {
    static let countyName = "Dakota County"
    static let countyPhone = "651-437-3191"
    static let permitOfficePhone = "952-891-7115"
    static let gopherStateOneCall = "811"

    static let cities: [City] = [
        City(id: "lakeville", name: "Lakeville", kind: .city, gisName: "LAKEVILLE",
             center: GeoPoint(latitude: 44.6497, longitude: -93.2427),
             website: "https://www.lakevillemn.gov", engineeringPath: "/158/Engineering",
             hasCuratedContent: true),
        City(id: "apple-valley", name: "Apple Valley", kind: .city, gisName: "APPLE VALLEY",
             center: GeoPoint(latitude: 44.7319, longitude: -93.2177),
             website: "https://www.applevalleymn.gov", engineeringPath: "/1071/Engineering",
             hasCuratedContent: true),
        City(id: "burnsville", name: "Burnsville", kind: .city, gisName: "BURNSVILLE",
             center: GeoPoint(latitude: 44.7678, longitude: -93.2777),
             website: "https://www.burnsvillemn.gov", engineeringPath: nil),
        City(id: "coates", name: "Coates", kind: .city, gisName: "COATES",
             center: GeoPoint(latitude: 44.7169, longitude: -93.0338),
             website: nil, engineeringPath: nil),
        City(id: "eagan", name: "Eagan", kind: .city, gisName: "EAGAN",
             center: GeoPoint(latitude: 44.8041, longitude: -93.1668),
             website: "https://www.cityofeagan.com", engineeringPath: nil),
        City(id: "farmington", name: "Farmington", kind: .city, gisName: "FARMINGTON",
             center: GeoPoint(latitude: 44.6400, longitude: -93.1436),
             website: "https://www.farmingtonmn.gov", engineeringPath: nil),
        City(id: "hampton", name: "Hampton", kind: .city, gisName: "HAMPTON",
             center: GeoPoint(latitude: 44.6069, longitude: -93.0022),
             website: nil, engineeringPath: nil),
        City(id: "hastings", name: "Hastings", kind: .city, gisName: "HASTINGS",
             center: GeoPoint(latitude: 44.7433, longitude: -92.8524),
             website: "https://www.hastingsmn.gov", engineeringPath: nil),
        City(id: "inver-grove-heights", name: "Inver Grove Heights", kind: .city, gisName: "INVER GROVE HEIGHTS",
             center: GeoPoint(latitude: 44.8480, longitude: -93.0427),
             website: "https://www.invergroveheights.org", engineeringPath: nil),
        City(id: "lilydale", name: "Lilydale", kind: .city, gisName: "LILYDALE",
             center: GeoPoint(latitude: 44.9147, longitude: -93.1130),
             website: nil, engineeringPath: nil),
        City(id: "mendota", name: "Mendota", kind: .city, gisName: "MENDOTA",
             center: GeoPoint(latitude: 44.8875, longitude: -93.1636),
             website: "https://www.cityofmendota.org", engineeringPath: nil),
        City(id: "mendota-heights", name: "Mendota Heights", kind: .city, gisName: "MENDOTA HEIGHTS",
             center: GeoPoint(latitude: 44.8835, longitude: -93.1382),
             website: "https://www.mendotaheightsmn.gov", engineeringPath: nil),
        City(id: "miesville", name: "Miesville", kind: .city, gisName: "MIESVILLE",
             center: GeoPoint(latitude: 44.6008, longitude: -92.8180),
             website: nil, engineeringPath: nil),
        City(id: "new-trier", name: "New Trier", kind: .city, gisName: "NEW TRIER",
             center: GeoPoint(latitude: 44.6155, longitude: -92.9319),
             website: nil, engineeringPath: nil),
        City(id: "northfield", name: "Northfield", kind: .city, gisName: "NORTHFIELD",
             center: GeoPoint(latitude: 44.4583, longitude: -93.1616),
             website: "https://www.northfieldmn.gov", engineeringPath: nil),
        City(id: "randolph", name: "Randolph", kind: .city, gisName: "RANDOLPH",
             center: GeoPoint(latitude: 44.5261, longitude: -93.0208),
             website: "https://www.cityofrandolphmn.com", engineeringPath: nil),
        City(id: "rosemount", name: "Rosemount", kind: .city, gisName: "ROSEMOUNT",
             center: GeoPoint(latitude: 44.7394, longitude: -93.1258),
             website: "https://www.rosemountmn.gov", engineeringPath: nil),
        City(id: "south-st-paul", name: "South St. Paul", kind: .city, gisName: "SOUTH ST PAUL",
             center: GeoPoint(latitude: 44.8928, longitude: -93.0349),
             website: "https://www.southstpaul.org", engineeringPath: nil),
        City(id: "sunfish-lake", name: "Sunfish Lake", kind: .city, gisName: "SUNFISH LAKE",
             center: GeoPoint(latitude: 44.8672, longitude: -93.0913),
             website: "https://www.sunfishlake.org", engineeringPath: nil),
        City(id: "vermillion", name: "Vermillion", kind: .city, gisName: "VERMILLION",
             center: GeoPoint(latitude: 44.6725, longitude: -92.9666),
             website: nil, engineeringPath: nil),
        City(id: "west-st-paul", name: "West St. Paul", kind: .city, gisName: "WEST ST PAUL",
             center: GeoPoint(latitude: 44.9163, longitude: -93.1013),
             website: "https://www.wspmn.gov", engineeringPath: nil),
    ]

    static let townships: [City] = [
        City(id: "castle-rock-twp", name: "Castle Rock", kind: .township, gisName: "CASTLE ROCK TWP",
             center: GeoPoint(latitude: 44.5636, longitude: -93.1489), website: nil, engineeringPath: nil),
        City(id: "douglas-twp", name: "Douglas", kind: .township, gisName: "DOUGLAS TWP",
             center: GeoPoint(latitude: 44.5825, longitude: -92.8969), website: nil, engineeringPath: nil),
        City(id: "empire-twp", name: "Empire", kind: .township, gisName: "EMPIRE TWP",
             center: GeoPoint(latitude: 44.6608, longitude: -93.0783), website: nil, engineeringPath: nil),
        City(id: "eureka-twp", name: "Eureka", kind: .township, gisName: "EUREKA TWP",
             center: GeoPoint(latitude: 44.5892, longitude: -93.2836), website: nil, engineeringPath: nil),
        City(id: "greenvale-twp", name: "Greenvale", kind: .township, gisName: "GREENVALE TWP",
             center: GeoPoint(latitude: 44.5011, longitude: -93.2861), website: nil, engineeringPath: nil),
        City(id: "hampton-twp", name: "Hampton", kind: .township, gisName: "HAMPTON TWP",
             center: GeoPoint(latitude: 44.6031, longitude: -92.9500), website: nil, engineeringPath: nil),
        City(id: "marshan-twp", name: "Marshan", kind: .township, gisName: "MARSHAN TWP",
             center: GeoPoint(latitude: 44.6786, longitude: -92.8944), website: nil, engineeringPath: nil),
        City(id: "nininger-twp", name: "Nininger", kind: .township, gisName: "NININGER TWP",
             center: GeoPoint(latitude: 44.7622, longitude: -92.9089), website: nil, engineeringPath: nil),
        City(id: "randolph-twp", name: "Randolph", kind: .township, gisName: "RANDOLPH TWP",
             center: GeoPoint(latitude: 44.5222, longitude: -93.0189), website: nil, engineeringPath: nil),
        City(id: "ravenna-twp", name: "Ravenna", kind: .township, gisName: "RAVENNA TWP",
             center: GeoPoint(latitude: 44.7175, longitude: -92.8103), website: nil, engineeringPath: nil),
        City(id: "sciota-twp", name: "Sciota", kind: .township, gisName: "SCIOTA TWP",
             center: GeoPoint(latitude: 44.5178, longitude: -93.0300), website: nil, engineeringPath: nil),
        City(id: "vermillion-twp", name: "Vermillion", kind: .township, gisName: "VERMILLION TWP",
             center: GeoPoint(latitude: 44.6644, longitude: -92.9331), website: nil, engineeringPath: nil),
        City(id: "waterford-twp", name: "Waterford", kind: .township, gisName: "WATERFORD TWP",
             center: GeoPoint(latitude: 44.4906, longitude: -93.2072), website: nil, engineeringPath: nil),
    ]

    static let all: [City] = cities + townships

    static let defaultCityID = "lakeville"

    static func city(id: String?) -> City? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}
