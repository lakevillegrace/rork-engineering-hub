import SwiftUI

/// The Engineering Hub home: six category tiles, pinned shortcuts, and search
/// across every resource in the app.
struct HubView: View {
    @Environment(HubStore.self) private var store
    @Environment(LiveOpsService.self) private var live
    @Environment(LocationProvider.self) private var location
    @State private var query: String = ""
    @State private var isShowingSettings = false

    /// The municipality the crew is physically standing in, from bundled county
    /// boundary geometry.
    private var standingIn: MunicipalBoundary? {
        guard let here = location.currentPoint else { return nil }
        return BoundaryStore.shared.boundary(containing: here)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var searchResults: [ResourceLink] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return store.currentLinks.filter { link in
            link.title.localizedStandardContains(trimmed)
                || (link.detail?.localizedStandardContains(trimmed) ?? false)
                || store.categoryTitle(for: link).localizedStandardContains(trimmed)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    browseContent
                } else {
                    resultsContent
                }
            }
        }
        .background(Theme.canvas)
        .scrollDismissesKeyboard(.immediately)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search resources")
        .navigationTitle(store.selectedCity?.displayName ?? "Dakota County")
        .navigationBarTitleDisplayMode(.inline)
        .civicNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .task {
            if live.items.isEmpty {
                await live.refresh(city: store.selectedCity, sources: store.allSources)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Engineering Hub")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("A central starting point for Engineering workflows, applications, tracking, procedures and reference materials.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Label("Internal use — city staff only", systemImage: "lock.shield.fill")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 14)
        .padding(.bottom, 26)
        .background(Theme.navy)
    }

    private var browseContent: some View {
        VStack(spacing: 20) {
            briefingCard

            if let standingIn, standingIn.cityID != store.selectedCityID {
                outsideCityCallout(standingIn)
            }

            if !store.pinnedLinks.isEmpty {
                pinnedSection
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.categories) { category in
                    CategoryCard(category: category)
                }
            }

            tipCallout
        }
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 18)
        .padding(.bottom, 28)
    }

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PINNED")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(0.6)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Array(store.pinnedLinks.enumerated()), id: \.element.id) { index, link in
                    ResourceRow(link: link, showsCategory: true)
                    if index < store.pinnedLinks.count - 1 {
                        Divider().padding(.leading, 55)
                    }
                }
            }
            .civicCard()
        }
    }

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if searchResults.isEmpty {
                ContentUnavailableView.search(text: query)
                    .padding(.top, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, link in
                        ResourceRow(link: link, showsCategory: true)
                        if index < searchResults.count - 1 {
                            Divider().padding(.leading, 55)
                        }
                    }
                }
                .civicCard()
            }
        }
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 18)
        .padding(.bottom, 28)
    }

    /// Snapshot of what's happening in the field right now, plus open permits.
    private var briefingCard: some View {
        NavigationLink(value: HubRoute.liveConditions) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Today", systemImage: "dot.radiowaves.left.and.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if live.state == .loading {
                        ProgressView().controlSize(.mini)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkSecondary.opacity(0.7))
                    }
                }

                HStack(spacing: 0) {
                    briefingMetric(
                        value: nearbyCount(.closure),
                        label: "Closures",
                        tone: nearbyCount(.closure) > 0 ? Theme.amber : Theme.steel
                    )
                    Divider().frame(height: 34)
                    briefingMetric(value: nearbyCount(.project), label: "Projects", tone: Theme.steel)
                    Divider().frame(height: 34)
                    briefingMetric(value: openPermitCount, label: "Open permits", tone: Theme.steel)
                }

                Text(briefingFootnote)
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .civicCard()
        }
        .buttonStyle(.plain)
    }

    private func briefingMetric(value: Int, label: String, tone: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(tone)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// Counts work inside the selected city's actual limits, falling back to a
    /// radius only when a feature has no geometry to place.
    private func nearbyCount(_ category: LiveCategory) -> Int {
        guard let city = store.selectedCity else {
            return live.items(in: category).count
        }
        return live.items(in: category).filter { item in
            if item.hasJurisdiction { return item.isInside(cityID: city.id) }
            return (item.distanceInMiles(from: city.center) ?? .greatestFiniteMagnitude) <= 8
        }.count
    }

    /// Field crews cross municipal lines constantly; say so plainly rather than
    /// letting them read the wrong city's numbers.
    private func outsideCityCallout(_ boundary: MunicipalBoundary) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(Theme.amber)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("You're in \(boundary.displayName)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("The hub is showing \(store.selectedCity?.displayName ?? "another city") content.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .civicCard()
        .accessibilityElement(children: .combine)
    }

    private var openPermitCount: Int {
        PermitInbox.allCases.reduce(0) { $0 + store.openCount(in: $1) }
    }

    private var briefingFootnote: String {
        if let lastUpdated = live.lastUpdated {
            let prefix = live.isFromCache ? "Saved copy" : "Live from Dakota County GIS"
            let scope = store.selectedCity.map { "Within \($0.displayName) limits" } ?? "Countywide"
            return "\(scope) · \(prefix) · \(lastUpdated.formatted(.relative(presentation: .named)))"
        }
        return "Tap to load live county road data"
    }

    private var tipCallout: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Theme.amber)
                .accessibilityHidden(true)
            Text("**Tip:** Always check the tracking spreadsheet first to confirm current statuses.")
                .font(.footnote)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .civicCard()
    }
}
