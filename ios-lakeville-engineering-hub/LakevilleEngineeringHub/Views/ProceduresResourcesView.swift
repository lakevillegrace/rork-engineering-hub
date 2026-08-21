import SwiftUI

/// The More tab: procedures, SOPs, contacts and templates, plus entry points to
/// the categories that do not have their own tab.
struct ProceduresResourcesView: View {
    @Environment(HubStore.self) private var store

    private var otherSections: ResourceSection? {
        let extras = ["capital-projects", "development-review"].compactMap { store.category(id: $0) }
        guard !extras.isEmpty else { return nil }
        return ResourceSection(
            id: "more-sections",
            title: "More Sections",
            links: extras.map { category in
                ResourceLink(
                    id: "more-\(category.id)",
                    title: category.title,
                    systemImage: category.systemImage,
                    detail: category.summary,
                    action: .route(.category(category.id))
                )
            }
        )
    }

    var body: some View {
        Group {
            if let category = store.category(id: "procedures-resources") {
                CategoryPageView(category: category) {
                    VStack(spacing: 22) {
                        if let otherSections {
                            SectionCard(section: otherSections)
                        }
                        if let provenance = store.pack.provenance {
                            provenanceCard(provenance)
                        }
                    }
                }
            } else {
                ContentUnavailableView("Section unavailable", systemImage: "questionmark.folder")
            }
        }
    }

    /// Tells staff plainly where this city's content came from.
    private func provenanceCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: store.pack.isCurated ? "checkmark.seal.fill" : "info.circle.fill")
                .foregroundStyle(store.pack.isCurated ? Theme.steel : Theme.amber)
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .civicCard()
    }
}
