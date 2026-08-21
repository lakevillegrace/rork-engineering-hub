import SwiftUI

/// Shared anatomy for every category page: navy header, optional bespoke
/// content, then grouped resource sections.
struct CategoryPageView<TopContent: View>: View {
    let category: HubCategory
    @ViewBuilder var topContent: () -> TopContent

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PageHeader(
                    title: category.title,
                    summary: category.headerSummary,
                    systemImage: category.systemImage
                )

                VStack(spacing: 22) {
                    topContent()

                    ForEach(category.sections) { section in
                        SectionCard(section: section)
                    }
                }
                .padding(.horizontal, Theme.pageMargin)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.canvas)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .civicNavigationBar()
    }
}

extension CategoryPageView where TopContent == EmptyView {
    init(category: HubCategory) {
        self.init(category: category, topContent: { EmptyView() })
    }
}

/// Routes a category id to its page, using the bespoke page where one exists.
/// Categories resolve against the selected city's content pack.
struct CategoryDestinationView: View {
    let categoryID: String

    @Environment(HubStore.self) private var store

    var body: some View {
        switch categoryID {
        case "traffic-resources":
            TrafficResourcesView()
        case "capital-projects":
            CapitalProjectsView()
        case "procedures-resources":
            ProceduresResourcesView()
        default:
            if let category = store.category(id: categoryID) {
                CategoryPageView(category: category)
            } else {
                ContentUnavailableView("Section unavailable", systemImage: "questionmark.folder")
            }
        }
    }
}
