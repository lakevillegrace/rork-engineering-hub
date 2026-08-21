import Foundation

/// A loosely typed JSON scalar, used for ArcGIS attribute bags whose value
/// types vary per layer.
nonisolated enum JSONScalar: Decodable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }

    /// A display string, or nil when the value is absent or blank.
    var text: String? {
        switch self {
        case let .string(value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case let .number(value):
            return value == value.rounded()
                ? String(Int(value))
                : String(format: "%.2f", value)
        case let .bool(value):
            return value ? "Yes" : "No"
        case .null:
            return nil
        }
    }

    var number: Double? {
        switch self {
        case let .number(value): value
        case let .string(value): Double(value)
        default: nil
        }
    }

    /// Esri encodes dates as epoch milliseconds.
    var esriDate: Date? {
        guard let number, number > 0 else { return nil }
        return Date(timeIntervalSince1970: number / 1000)
    }
}

nonisolated struct ArcGISGeometry: Decodable, Hashable, Sendable {
    let x: Double?
    let y: Double?
    let paths: [[[Double]]]?
    let rings: [[[Double]]]?
}

nonisolated struct ArcGISFeature: Decodable, Sendable {
    let attributes: [String: JSONScalar]
    let geometry: ArcGISGeometry?

    func text(_ field: String?) -> String? {
        guard let field, !field.isEmpty else { return nil }
        return attributes[field]?.text
    }

    func date(_ field: String?) -> Date? {
        guard let field, !field.isEmpty else { return nil }
        return attributes[field]?.esriDate
    }
}

nonisolated struct ArcGISServiceError: Decodable, Sendable {
    let code: Int
    let message: String
}

nonisolated private struct ArcGISQueryResponse: Decodable, Sendable {
    let features: [ArcGISFeature]?
    let error: ArcGISServiceError?
}

nonisolated enum ArcGISError: LocalizedError, Sendable {
    case invalidURL
    case service(String)
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "That layer address isn't a valid URL."
        case let .service(message):
            message
        case let .badResponse(code):
            "The GIS server returned an error (HTTP \(code))."
        }
    }
}

/// Minimal read-only client for public ArcGIS REST feature/map service layers.
///
/// Every Dakota County city publishes its data through Esri services, so a
/// generic query client lets staff point the app at any layer they have.
nonisolated struct ArcGISClient: Sendable {
    private let session: URLSession

    init(timeout: TimeInterval = 20) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
    }

    /// Runs a `query` against an ArcGIS layer endpoint and returns raw features.
    func queryFeatures(
        layerURL: String,
        whereClause: String = "1=1",
        outFields: String = "*",
        returnGeometry: Bool = true,
        resultRecordCount: Int = 250,
        envelope: GeoBounds? = nil
    ) async throws -> [ArcGISFeature] {
        let base = layerURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(string: base + "/query") else {
            throw ArcGISError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "where", value: whereClause),
            URLQueryItem(name: "outFields", value: outFields),
            URLQueryItem(name: "returnGeometry", value: returnGeometry ? "true" : "false"),
            URLQueryItem(name: "outSR", value: "4326"),
            URLQueryItem(name: "geometryPrecision", value: "5"),
            URLQueryItem(name: "resultRecordCount", value: String(resultRecordCount)),
            URLQueryItem(name: "f", value: "json"),
        ]

        // Statewide layers are clipped server-side so we never pull the whole
        // state down to show one county.
        if let envelope {
            let box = "\(envelope.minLongitude),\(envelope.minLatitude),\(envelope.maxLongitude),\(envelope.maxLatitude)"
            components.queryItems?.append(contentsOf: [
                URLQueryItem(name: "geometry", value: box),
                URLQueryItem(name: "geometryType", value: "esriGeometryEnvelope"),
                URLQueryItem(name: "inSR", value: "4326"),
                URLQueryItem(name: "spatialRel", value: "esriSpatialRelIntersects"),
            ])
        }

        guard let url = components.url else { throw ArcGISError.invalidURL }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ArcGISError.badResponse(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(ArcGISQueryResponse.self, from: data)
        if let error = decoded.error {
            throw ArcGISError.service(error.message)
        }
        return decoded.features ?? []
    }
}
