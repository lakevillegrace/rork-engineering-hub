import SwiftUI

/// A single tappable resource row: opens a saved link, dials a contact,
/// pushes an in-app destination, or opens a checklist.
struct ResourceRow: View {
    let link: ResourceLink
    var showsCategory: Bool = false

    @Environment(HubStore.self) private var store
    @Environment(\.openURL) private var openURL

    @State private var isEditingLink = false
    @State private var activeChecklist: ChecklistDefinition?

    private var checklist: ChecklistDefinition? {
        ChecklistCatalog.definition(forLinkID: link.id)
    }

    var body: some View {
        Group {
            if case let .route(route) = link.action {
                NavigationLink(value: route) { rowContent }
                    .buttonStyle(.plain)
            } else {
                Button(action: activate) { rowContent }
                    .buttonStyle(.plain)
            }
        }
        .contextMenu { contextMenuItems }
        .sheet(isPresented: $isEditingLink) { LinkEditorSheet(link: link) }
        .sheet(item: $activeChecklist) { ChecklistSheet(definition: $0) }
    }

    private var rowContent: some View {
        HStack(spacing: 13) {
            Image(systemName: link.systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.navy)
                .frame(width: 26, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(subtitleColor)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: 8)

            if store.isPinned(link) {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.amber)
                    .accessibilityHidden(true)
            }

            Image(systemName: trailingSymbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint(accessibilityHint)
    }

    private var subtitle: String? {
        if showsCategory {
            return HubContent.categoryTitle(for: link)
        }
        if let detail = link.detail {
            return detail
        }
        if case .web = link.action, !store.hasURL(for: link) {
            return "No link yet — tap to add"
        }
        return nil
    }

    private var subtitleColor: Color {
        if case .web = link.action, link.detail == nil, !showsCategory, !store.hasURL(for: link) {
            return Theme.steel
        }
        return Theme.inkSecondary
    }

    private var trailingSymbol: String {
        switch link.action {
        case .phone: "phone.fill"
        case .email: "envelope.fill"
        case .route: "chevron.right"
        case .web: checklist != nil ? "chevron.right" : (store.hasURL(for: link) ? "arrow.up.right.square" : "plus.circle")
        }
    }

    private var accessibilityHint: String {
        switch link.action {
        case .phone:
            return "Calls this number"
        case .email:
            return "Starts an email"
        case .route:
            return "Opens in the app"
        case .web:
            if checklist != nil { return "Opens the checklist" }
            return store.hasURL(for: link) ? "Opens the saved link" : "Adds a link address"
        }
    }

    private func activate() {
        switch link.action {
        case let .phone(number):
            if let url = URL(string: "tel://\(number)") { openURL(url) }
        case let .email(address):
            if let url = URL(string: "mailto:\(address)") { openURL(url) }
        case .route:
            break
        case .web:
            if let checklist, !store.hasURL(for: link) {
                activeChecklist = checklist
            } else if let url = store.url(for: link) {
                openURL(url)
            } else {
                isEditingLink = true
            }
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if let checklist {
            Button("Open checklist", systemImage: "checklist") { activeChecklist = checklist }
        }
        if case .web = link.action {
            Button(store.hasURL(for: link) ? "Edit link" : "Add link", systemImage: "link") {
                isEditingLink = true
            }
            if let url = store.url(for: link) {
                Button("Copy address", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = url.absoluteString
                }
            }
        }
        Button(store.isPinned(link) ? "Unpin from Hub" : "Pin to Hub", systemImage: store.isPinned(link) ? "pin.slash" : "pin") {
            store.togglePin(link)
        }
    }
}
