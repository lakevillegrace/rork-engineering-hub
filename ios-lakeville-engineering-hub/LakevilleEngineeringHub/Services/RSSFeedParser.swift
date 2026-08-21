import Foundation

/// One entry lifted from an RSS channel.
nonisolated struct RSSEntry: Sendable {
    var title: String = ""
    var link: String = ""
    var summary: String = ""
    var published: Date?
    var guid: String = ""
}

/// Minimal RSS 2.0 reader.
///
/// City sites in Dakota County run on CivicPlus, which publishes plain RSS with
/// no JSON alternative, so the app parses the XML directly.
nonisolated final class RSSFeedParser: NSObject, XMLParserDelegate {
    private var entries: [RSSEntry] = []
    private var current: RSSEntry?
    private var buffer = ""
    private var isInsideItem = false

    func parse(_ data: Data) -> [RSSEntry] {
        entries = []
        current = nil
        buffer = ""
        isInsideItem = false

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.parse()
        return entries
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        if elementName == "item" || elementName == "entry" {
            isInsideItem = true
            current = RSSEntry()
        }
        buffer = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        buffer += String(data: CDATABlock, encoding: .utf8) ?? ""
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        defer { buffer = "" }
        guard isInsideItem else { return }

        let value = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "item", "entry":
            if let current, !current.title.isEmpty {
                entries.append(current)
            }
            self.current = nil
            isInsideItem = false
        case "title":
            current?.title = value.strippingHTML
        case "link":
            if !value.isEmpty { current?.link = value }
        case "description", "summary":
            current?.summary = value.strippingHTML
        case "pubDate", "published", "updated":
            current?.published = RSSFeedParser.date(from: value)
        case "guid", "id":
            current?.guid = value
        default:
            break
        }
    }

    /// CivicPlus emits RFC 822 dates, sometimes without seconds.
    private static let formats = [
        "EEE, dd MMM yyyy HH:mm:ss Z",
        "EEE, dd MMM yyyy HH:mm Z",
        "EEE, dd MMM yyyy HH:mm:ss zzz",
        "yyyy-MM-dd'T'HH:mm:ssZ",
    ]

    private static func date(from value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}

extension String {
    /// Removes markup and decodes the handful of entities city feeds emit, so
    /// summaries read as plain text.
    var strippingHTML: String {
        var output = replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )
        let entities = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
            "&#39;": "'", "&apos;": "'", "&nbsp;": " ", "&rsquo;": "\u{2019}",
            "&ldquo;": "\u{201C}", "&rdquo;": "\u{201D}", "&ndash;": "\u{2013}",
            "&mdash;": "\u{2014}",
        ]
        for (entity, replacement) in entities {
            output = output.replacingOccurrences(of: entity, with: replacement)
        }
        output = output.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
