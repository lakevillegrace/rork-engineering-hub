import SwiftUI

/// Bulk-assigns real destinations to hub rows from a pasted list.
///
/// Department link lists usually live in a SharePoint page that only staff can
/// open. Rather than making the app open SharePoint, staff paste the underlying
/// destinations here once and every row points straight at the real site or PDF.
struct BulkLinkImportSheet: View {
    @Environment(HubStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var pasted: String = ""
    @State private var didApply = false
    @State private var appliedCount = 0

    /// One parsed line, resolved against the rows this city actually has.
    private struct ParsedEntry: Identifiable {
        let id = UUID()
        let label: String
        let url: String
        let match: ResourceLink?
    }

    private var entries: [ParsedEntry] {
        pasted
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let raw = String(line).trimmingCharacters(in: .whitespaces)
                guard !raw.isEmpty else { return nil }
                guard let (label, url) = BulkLinkImportSheet.split(raw) else { return nil }
                return ParsedEntry(label: label, url: url, match: bestMatch(for: label))
            }
    }

    private var matched: [ParsedEntry] { entries.filter { $0.match != nil } }
    private var unmatched: [ParsedEntry] { entries.filter { $0.match == nil } }

    /// Splits "Title | URL", "Title - URL", "Title<tab>URL" or a bare URL.
    private static func split(_ line: String) -> (String, String)? {
        for separator in ["|", "\t", " — ", " – ", " - "] {
            guard let range = line.range(of: separator) else { continue }
            let label = line[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            let url = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if !label.isEmpty, !url.isEmpty { return (label, url) }
        }
        // A bare URL still counts; it just can't be matched by name.
        if line.lowercased().hasPrefix("http") { return (line, line) }
        return nil
    }

    /// Loose title match so "ROW OneStop" finds the "ROW OneStop" row even with
    /// different punctuation or casing.
    private func bestMatch(for label: String) -> ResourceLink? {
        let needle = BulkLinkImportSheet.normalize(label)
        guard !needle.isEmpty else { return nil }
        let links = store.currentLinks

        if let exact = links.first(where: { BulkLinkImportSheet.normalize($0.title) == needle }) {
            return exact
        }
        return links.first { link in
            let title = BulkLinkImportSheet.normalize(link.title)
            return title.contains(needle) || needle.contains(title)
        }
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $pasted)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 170)
                        .overlay(alignment: .topLeading) {
                            if pasted.isEmpty {
                                Text("ROW OneStop | https://example.gov/onestop\nAs-Built Plans | https://example.gov/asbuilts.pdf")
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(Theme.inkSecondary.opacity(0.6))
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text("Paste links")
                } footer: {
                    Text("One per line, as `Name | URL`. Names are matched to the rows already in the hub, so the row opens the real destination instead of a SharePoint page.")
                }

                if !matched.isEmpty {
                    Section("Will update \(matched.count)") {
                        ForEach(matched) { entry in
                            VStack(alignment: .leading, spacing: 3) {
                                Label(entry.match?.title ?? entry.label, systemImage: "checkmark.circle.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.ink)
                                Text(entry.url)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.inkSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }

                if !unmatched.isEmpty {
                    Section {
                        ForEach(unmatched) { entry in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.label)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text(entry.url)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.inkSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    } header: {
                        Text("No matching row (\(unmatched.count))")
                    } footer: {
                        Text("Rename these to match a row's title exactly, or set them on the row itself with Edit link.")
                    }
                }
            }
            .navigationTitle("Import Links")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { apply() }
                        .disabled(matched.isEmpty)
                }
            }
            .alert("Links updated", isPresented: $didApply) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(appliedCount) row\(appliedCount == 1 ? "" : "s") now open the destination you pasted.")
            }
        }
    }

    private func apply() {
        let toApply = matched
        for entry in toApply {
            guard let link = entry.match else { continue }
            store.setURL(entry.url, for: link)
        }
        appliedCount = toApply.count
        didApply = true
    }
}
