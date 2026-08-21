import SwiftUI

/// Permit tracking across all three Engineering inboxes, with per-inbox counts
/// and an editable list of tracked submittals.
struct PermitTrackingView: View {
    @Environment(HubStore.self) private var store
    @State private var selectedInbox: PermitInbox?
    @State private var isAddingPermit = false
    @State private var editingPermit: PermitRecord?

    private var trackingLink: ResourceLink {
        ResourceLink(id: "row-tracking-spreadsheet", title: "Tracking Spreadsheet", systemImage: "tablecells")
    }

    private var visiblePermits: [PermitRecord] {
        store.permits(in: selectedInbox)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Inbox", selection: $selectedInbox) {
                    Text("All").tag(PermitInbox?.none)
                    ForEach(PermitInbox.allCases) { inbox in
                        Text(inbox.shortLabel).tag(PermitInbox?.some(inbox))
                    }
                }
                .pickerStyle(.segmented)

                summaryRow

                if visiblePermits.isEmpty {
                    ContentUnavailableView(
                        "Nothing tracked yet",
                        systemImage: "tray",
                        description: Text("Add a permit or survey submittal to keep an eye on it.")
                    )
                    .padding(.top, 30)
                } else {
                    permitList
                }
            }
            .padding(.horizontal, Theme.pageMargin)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.canvas)
        .navigationTitle("Permit Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .civicNavigationBar()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") { isAddingPermit = true }
            }
        }
        .safeAreaInset(edge: .bottom) {
            spreadsheetButton
        }
        .sheet(isPresented: $isAddingPermit) {
            PermitEditorSheet(permit: nil)
        }
        .sheet(item: $editingPermit) { permit in
            PermitEditorSheet(permit: permit)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            ForEach(PermitInbox.allCases) { inbox in
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: inbox.systemImage)
                        .font(.footnote)
                        .foregroundStyle(Theme.steel)
                    Text("\(store.openCount(in: inbox))")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Theme.navy)
                        .contentTransition(.numericText())
                    Text(inbox.longLabel)
                        .font(.caption2)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .civicCard()
            }
        }
    }

    private var permitList: some View {
        VStack(spacing: 0) {
            ForEach(Array(visiblePermits.enumerated()), id: \.element.id) { index, permit in
                Button {
                    editingPermit = permit
                } label: {
                    PermitRow(permit: permit)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Edit", systemImage: "pencil") { editingPermit = permit }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        store.deletePermits(ids: [permit.id])
                    }
                }

                if index < visiblePermits.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .civicCard()
    }

    private var spreadsheetButton: some View {
        ResourceLinkButton(link: trackingLink, title: "Open Tracking Spreadsheet")
            .padding(.horizontal, Theme.pageMargin)
            .padding(.vertical, 12)
            .background(.bar)
    }
}

private struct PermitRow: View {
    let permit: PermitRecord

    private var tone: StatusChip.Tone {
        switch PermitStatus(rawValue: permit.status) {
        case .approved, .closed: .positive
        case .awaitingRestoration, .awaitingApplicant: .amber
        default: .steel
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(permit.number)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                StatusChip(text: permit.status, tone: tone)
            }

            HStack(spacing: 6) {
                Text(permit.applicant)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                Text(permit.receivedDate, format: .dateTime.month(.abbreviated).day())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkSecondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                Text(permit.inbox.shortLabel)
                    .font(.caption)
                    .foregroundStyle(Theme.steel)
            }

            if !permit.note.isEmpty {
                Text(permit.note)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// A prominent button that opens a configurable resource, prompting for the
/// address the first time it is used.
struct ResourceLinkButton: View {
    let link: ResourceLink
    let title: String

    @Environment(HubStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var isEditingLink = false

    var body: some View {
        Button {
            if let url = store.url(for: link) {
                openURL(url)
            } else {
                isEditingLink = true
            }
        } label: {
            Label(store.hasURL(for: link) ? title : "Add \(title.lowercased()) link",
                  systemImage: store.hasURL(for: link) ? "arrow.up.right.square" : "link.badge.plus")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.navy, in: .rect(cornerRadius: 12))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isEditingLink) { LinkEditorSheet(link: link) }
    }
}
