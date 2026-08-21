import SwiftUI

/// Shared navigation stack: every tab resolves the same set of hub routes.
struct HubNavigationStack<Root: View>: View {
    @ViewBuilder var root: () -> Root

    @Environment(HubStore.self) private var store

    var body: some View {
        NavigationStack {
            root()
                .navigationDestination(for: HubRoute.self) { route in
                    destination(for: route)
                        .toolbar(.hidden, for: .tabBar)
                }
                .navigationDestination(for: LiveItem.self) { item in
                    LiveItemDetailView(item: item)
                        .toolbar(.hidden, for: .tabBar)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: HubRoute) -> some View {
        switch route {
        case let .category(id):
            CategoryDestinationView(categoryID: id)
        case .permitTracking:
            PermitTrackingView()
        case .trafficCounts:
            TrafficResourcesView()
        case .liveConditions:
            LiveOpsView()
        case .updates:
            UpdatesView()
        case let .project(id):
            if let project = store.project(id: id) {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView("Project unavailable", systemImage: "hammer")
            }
        }
    }
}
