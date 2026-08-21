//
//  ContentView.swift
//  LakevilleEngineeringHub
//

import SwiftUI

/// Root shell. Staff pick their municipality once, then land in the tabbed hub.
struct ContentView: View {
    @State private var store = HubStore()
    @State private var live = LiveOpsService()
    @State private var location = LocationProvider()
    @State private var updates = UpdatesService()

    var body: some View {
        Group {
            if store.hasSelectedCity {
                MainTabView()
            } else {
                CityPickerView()
            }
        }
        .environment(store)
        .environment(live)
        .environment(location)
        .environment(updates)
        .tint(Theme.navy)
        .preferredColorScheme(.light)
        .animation(.snappy(duration: 0.25), value: store.hasSelectedCity)
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Hub", systemImage: "house.fill") {
                HubNavigationStack { HubView() }
            }

            Tab("Live", systemImage: "dot.radiowaves.left.and.right") {
                HubNavigationStack { LiveOpsView() }
            }

            Tab("Updates", systemImage: "bell.badge.fill") {
                HubNavigationStack { UpdatesView() }
            }

            Tab("ROW & Utility", systemImage: "shield.lefthalf.filled") {
                HubNavigationStack { CategoryDestinationView(categoryID: "row-permitting") }
            }

            Tab("More", systemImage: "ellipsis") {
                HubNavigationStack { ProceduresResourcesView() }
            }
        }
    }
}

#Preview {
    ContentView()
}
