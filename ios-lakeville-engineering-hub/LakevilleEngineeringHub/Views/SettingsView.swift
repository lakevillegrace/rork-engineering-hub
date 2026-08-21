import SwiftUI
import UniformTypeIdentifiers

/// Staff settings: which city the hub runs for, which GIS layers it polls, and
/// sharing the whole configuration with the rest of the department.
struct SettingsView: View {
    @Environment(HubStore.self) private var store
    @Environment(LiveOpsService.self) private var live
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var isChangingCity = false
    @State private var isAddingSource = false
    @State private var isImporting = false
    @State private var isPastingLinks = false
    @State private var exportURL: URL?
    @State private var alert: SettingsAlert?

    private struct SettingsAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private var city: City? { store.selectedCity }

    var body: some View {
        NavigationStack {
            Form {
                citySection
                sharingSection
                sourcesSection
                maintenanceSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $isChangingCity) {
                CityPickerView(isChangingCity: true)
            }
            .sheet(isPresented: $isAddingSource) {
                LiveSourceEditorSheet()
            }
            .sheet(isPresented: $isPastingLinks) {
                BulkLinkImportSheet()
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert(item: $alert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Sections

    private var citySection: some View {
        Section {
            Button {
                isChangingCity = true
            } label: {
                LabeledContent {
                    Text(city?.displayName ?? "Not set")
                        .foregroundStyle(Theme.inkSecondary)
                } label: {
                    Label("Municipality", systemImage: "building.columns")
                }
            }
            .tint(Theme.ink)

            if let website = city?.website, let url = URL(string: website) {
                Button {
                    openURL(url)
                } label: {
                    Label("Open city website", systemImage: "safari")
                }
            }
        } header: {
            Text("Your City")
        } footer: {
            Text("Live conditions, county contacts and distance filters follow this choice.")
        }
    }

    private var sharingSection: some View {
        Section {
            Button {
                prepareExport()
            } label: {
                Label("Export configuration", systemImage: "square.and.arrow.up")
            }
            .disabled(store.configuredLinkCount == 0 && store.customSources.isEmpty)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share \(exportURL.lastPathComponent)", systemImage: "paperplane.fill")
                }
            }

            Button {
                isImporting = true
            } label: {
                Label("Import configuration", systemImage: "square.and.arrow.down")
            }

            Button {
                isPastingLinks = true
            } label: {
                Label("Paste a list of links", systemImage: "list.clipboard")
            }
        } header: {
            Text("Share Setup With Your Team")
        } footer: {
            Text("Exports every saved link, pinned shortcut and custom GIS layer as a JSON file — \(store.configuredLinkCount) link\(store.configuredLinkCount == 1 ? "" : "s") saved. Send it to a colleague and they can import it instead of entering addresses by hand. Use Paste a list of links to set many rows at once from a department link list.")
        }
    }

    private var sourcesSection: some View {
        Section {
            ForEach(store.allSources) { source in
                sourceRow(source)
            }

            Button {
                isAddingSource = true
            } label: {
                Label("Add a GIS layer", systemImage: "plus.circle")
            }
        } header: {
            Text("Live Data Sources")
        } footer: {
            Text("Built-in layers come from Dakota County's public GIS and work for every city in the county. Add your own city's ArcGIS layer to show local closures and trail work.")
        }
    }

    private func sourceRow(_ source: LiveSource) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(
                get: { store.isSourceEnabled(source) },
                set: { store.setSource(source, enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.title)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                    Text(source.isBuiltIn ? "Dakota County · \(source.category.title)" : "Custom · \(source.category.title)")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .tint(Theme.navy)
        }
        .swipeActions(edge: .trailing) {
            if !source.isBuiltIn {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    store.removeCustomSource(id: source.id)
                }
            }
        }
    }

    private var maintenanceSection: some View {
        Section {
            Button {
                Task { await live.refresh(city: city, sources: store.allSources) }
            } label: {
                Label("Refresh live data now", systemImage: "arrow.clockwise")
            }

            Button(role: .destructive) {
                store.clearAllLinks()
                alert = SettingsAlert(
                    title: "Links cleared",
                    message: "All saved resource addresses were removed. Content and permits were not affected."
                )
            } label: {
                Label("Clear all saved links", systemImage: "trash")
            }
            .disabled(store.configuredLinkCount == 0)
        } header: {
            Text("Maintenance")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Saved links", value: "\(store.configuredLinkCount)")
            LabeledContent("Pinned shortcuts", value: "\(store.pinnedLinkIDs.count)")
            LabeledContent("Tracked submittals", value: "\(store.permits.count)")
            if let lastUpdated = live.lastUpdated {
                LabeledContent("Live data", value: lastUpdated.formatted(date: .abbreviated, time: .shortened))
            }
        } header: {
            Text("This Device")
        } footer: {
            Text("Internal tool for municipal staff. Data is stored on this device only — nothing is sent to a server. Live conditions come from public Dakota County GIS services and are advisory; always confirm field conditions before acting.")
        }
    }

    // MARK: - Import / export

    private func prepareExport() {
        let configuration = store.exportConfiguration()
        do {
            let data = try configuration.encoded()
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(configuration.suggestedFileName)
            try data.write(to: url, options: .atomic)
            exportURL = url
        } catch {
            alert = SettingsAlert(
                title: "Export failed",
                message: "Couldn't create the configuration file. Please try again."
            )
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

            do {
                let data = try Data(contentsOf: url)
                let configuration = try HubConfiguration.decoded(from: data)
                guard configuration.formatVersion <= HubConfiguration.currentFormatVersion else {
                    throw ConfigurationImportError.unsupportedVersion(configuration.formatVersion)
                }
                let summary = store.importConfiguration(configuration, replaceExisting: false)
                alert = SettingsAlert(title: "Configuration imported", message: summary.message)
            } catch let error as ConfigurationImportError {
                alert = SettingsAlert(title: "Import failed", message: error.localizedDescription)
            } catch {
                alert = SettingsAlert(
                    title: "Import failed",
                    message: ConfigurationImportError.unreadable.localizedDescription
                )
            }
        case .failure:
            alert = SettingsAlert(title: "Import cancelled", message: "No file was imported.")
        }
    }
}

/// Lets staff point the hub at any public ArcGIS layer from their own city.
private struct LiveSourceEditorSheet: View {
    @Environment(HubStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var layerURL: String = ""
    @State private var category: LiveCategory = .closure
    @State private var titleField: String = ""
    @State private var subtitleField: String = ""
    @State private var whereClause: String = "1=1"

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !titleField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && URL(string: layerURL.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
            && layerURL.lowercased().contains("http")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Lakeville Trail Closures)", text: $title)
                    Picker("Shows as", selection: $category) {
                        ForEach(LiveCategory.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }
                } header: {
                    Text("Layer")
                }

                Section {
                    TextField("https://…/FeatureServer/0", text: $layerURL, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lineLimit(2...4)
                        .font(.callout.monospaced())
                } header: {
                    Text("ArcGIS layer address")
                } footer: {
                    Text("Paste the full layer endpoint, ending in a layer number.")
                }

                Section {
                    TextField("Title field (e.g. STREET)", text: $titleField)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Subtitle field (optional)", text: $subtitleField)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Filter (optional)", text: $whereClause)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.callout.monospaced())
                } header: {
                    Text("Field mapping")
                } footer: {
                    Text("Field names are case-sensitive and come from the layer's own attribute table.")
                }
            }
            .navigationTitle("Add GIS Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let trimmedSubtitle = subtitleField.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWhere = whereClause.trimmingCharacters(in: .whitespacesAndNewlines)

        let source = LiveSource(
            id: "custom-\(UUID().uuidString.prefix(8))",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            layerURL: layerURL.trimmingCharacters(in: .whitespacesAndNewlines),
            whereClause: trimmedWhere.isEmpty ? "1=1" : trimmedWhere,
            titleField: titleField.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitleField: trimmedSubtitle.isEmpty ? nil : trimmedSubtitle,
            isBuiltIn: false
        )
        store.addCustomSource(source)
        dismiss()
    }
}
