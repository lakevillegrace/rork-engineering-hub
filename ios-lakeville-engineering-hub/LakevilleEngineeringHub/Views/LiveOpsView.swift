import MapKit
import SwiftUI
import UIKit

/// Live field conditions for the selected city, pulled from public Dakota
/// County GIS services and any city layers staff have added.
struct LiveOpsView: View {
    @Environment(HubStore.self) private var store
    @Environment(LiveOpsService.self) private var live
    @Environment(LocationProvider.self) private var location
    @Environment(\.openURL) private var openURL

    @State private var filter: LiveCategory?
    @State private var query: String = ""
    @State private var scope: LiveScope = .nearCity
    @State private var showsBoundaries = true

    private let boundaries = BoundaryStore.shared

    private enum LiveScope: String, CaseIterable, Identifiable {
        case nearMe
        case nearCity
        case county

        var id: String { rawValue }
        var label: String {
            switch self {
            case .nearMe: "Near Me"
            case .nearCity: "My City"
            case .county: "Countywide"
            }
        }
    }

    /// Radius used to decide whether a countywide feature is "near" the city.
    private let nearbyRadiusMiles: Double = 8
    /// Tighter radius for the field-crew "Near Me" scope.
    private let aroundMeRadiusMiles: Double = 5

    private var city: City? { store.selectedCity }

    /// Mapped limits of the selected municipality.
    private var cityBoundary: MunicipalBoundary? {
        boundaries.boundary(cityID: store.selectedCityID)
    }

    /// The municipality the crew is physically inside right now.
    private var standingIn: MunicipalBoundary? {
        guard let here = location.currentPoint else { return nil }
        return boundaries.boundary(containing: here)
    }

    /// The point distances are measured from: the crew's GPS fix when we have
    /// one, otherwise the centre of the selected municipality.
    private var referencePoint: GeoPoint? {
        location.currentPoint ?? city?.center
    }

    private var scopedItems: [LiveItem] {
        switch scope {
        case .nearMe:
            guard let here = location.currentPoint else { return [] }
            return live.items
                .filter { ($0.distanceInMiles(from: here) ?? .greatestFiniteMagnitude) <= aroundMeRadiusMiles }
                .sorted { lhs, rhs in
                    (lhs.distanceInMiles(from: here) ?? .greatestFiniteMagnitude)
                        < (rhs.distanceInMiles(from: here) ?? .greatestFiniteMagnitude)
                }
        case .nearCity:
            guard let city else { return live.items }
            // Prefer the city's real limits; fall back to a radius only for
            // features the county published without usable geometry.
            return live.items.filter { item in
                if item.hasJurisdiction { return item.isInside(cityID: city.id) }
                guard let distance = item.distanceInMiles(from: city.center) else { return false }
                return distance <= nearbyRadiusMiles
            }
        case .county:
            return live.items
        }
    }

    private var visibleItems: [LiveItem] {
        var result = scopedItems
        if let filter {
            result = result.filter { $0.category == filter }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter { $0.matches(trimmed) }
        }
        return result
    }

    private func count(_ category: LiveCategory) -> Int {
        scopedItems.filter { $0.category == category }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: 20) {
                    scopePicker

                    if scope == .nearMe, !location.access.isAuthorized {
                        locationPermissionCard
                    } else if live.state == .loading, live.items.isEmpty {
                        loadingCard
                    } else {
                        if let standingIn, standingIn.cityID != store.selectedCityID {
                            jurisdictionBanner(standingIn)
                        }
                        summaryRow
                        if !visibleItems.isEmpty { mapCard }
                        itemsSection
                    }

                    if !live.failures.isEmpty { failureCard }
                }
                .padding(.horizontal, Theme.pageMargin)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.canvas)
        .scrollDismissesKeyboard(.immediately)
        .refreshable { await reload() }
        .searchable(text: $query, prompt: "Search closures and projects")
        .navigationTitle("Live Conditions")
        .navigationBarTitleDisplayMode(.inline)
        .civicNavigationBar()
        .task {
            location.start()
            if live.items.isEmpty || live.isFromCache { await reload() }
        }
        .onChange(of: scope) { _, newValue in
            if newValue == .nearMe { location.start() }
        }
        .onChange(of: store.selectedCityID) { _, _ in
            Task { await reload() }
        }
    }

    private func reload() async {
        await live.refresh(city: city, sources: store.allSources)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(city?.displayName ?? "Dakota County")
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                if live.state == .loading {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                    Text("Updating…")
                } else if let lastUpdated = live.lastUpdated {
                    Image(systemName: live.isFromCache ? "wifi.slash" : "checkmark.circle.fill")
                        .font(.caption2)
                    Text(live.isFromCache
                         ? "Saved copy · \(lastUpdated.formatted(.relative(presentation: .named)))"
                         : "Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                } else {
                    Text("Pull down to load")
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .background(Theme.navy)
    }

    private var scopePicker: some View {
        Picker("Scope", selection: $scope) {
            ForEach(LiveScope.allCases) { value in
                Text(value.label).tag(value)
            }
        }
        .pickerStyle(.segmented)
    }

    /// Shown when the crew picks "Near Me" before granting location access.
    private var locationPermissionCard: some View {
        VStack(spacing: 12) {
            Image(systemName: location.access == .denied ? "location.slash" : "location.circle")
                .font(.system(size: 34))
                .foregroundStyle(Theme.steel)

            Text(location.access == .denied ? "Location is turned off" : "Show work near you")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Text(location.access == .denied
                 ? "Enable location for this app in Settings to see closures within 5 miles of where you're standing."
                 : "Allow location and the hub will list every closure and work zone within 5 miles of you, nearest first.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if location.access == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.subheadline.weight(.semibold))
            } else {
                Button("Allow location") { location.start() }
                    .font(.subheadline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .civicCard()
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading county GIS data…")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .civicCard()
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            ForEach([LiveCategory.closure, .project, .trail], id: \.self) { category in
                Button {
                    filter = (filter == category) ? nil : category
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: category.systemImage)
                            .font(.footnote)
                            .foregroundStyle(category == .closure ? Theme.amber : Theme.steel)
                        Text("\(count(category))")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(Theme.navy)
                            .contentTransition(.numericText())
                        Text(category.title)
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(.rect(cornerRadius: Theme.cardRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .strokeBorder(filter == category ? Theme.navy : Color.clear, lineWidth: 2)
                    }
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(count(category)) \(category.title)")
                .accessibilityHint(filter == category ? "Showing only these. Tap to show all." : "Tap to filter")
            }
        }
        .animation(.snappy(duration: 0.2), value: filter)
    }

    /// Tells a crew standing outside the selected city which limits they're in.
    private func jurisdictionBanner(_ boundary: MunicipalBoundary) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(Theme.amber)
                .accessibilityHidden(true)
            Text("You're standing in **\(boundary.displayName)**")
                .font(.footnote)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
            if let cityID = boundary.cityID, DakotaCounty.city(id: cityID) != nil {
                Button("Switch") { store.selectedCityID = cityID }
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .civicCard()
    }

    private var mapCard: some View {
        Map(initialPosition: .region(region)) {
            if showsBoundaries {
                ForEach(boundaries.boundaries) { boundary in
                    let isSelected = boundary.cityID == store.selectedCityID
                    ForEach(Array(boundary.rings.enumerated()), id: \.offset) { _, ring in
                        MapPolygon(coordinates: ring.map(\.coordinate))
                            .foregroundStyle(isSelected ? Theme.navy.opacity(0.07) : Color.clear)
                            .stroke(
                                isSelected ? Theme.navy.opacity(0.85) : Theme.inkSecondary.opacity(0.35),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    }
                }
            }
            ForEach(visibleItems) { item in
                ForEach(Array(item.displaySegments.enumerated()), id: \.offset) { _, run in
                    if run.count > 1 {
                        MapPolyline(coordinates: run.map(\.coordinate))
                            .stroke(
                                item.category == .closure ? Theme.amber : Theme.steel,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                    }
                }
                if let anchor = item.anchor {
                    Marker(item.title, systemImage: item.category.systemImage, coordinate: anchor.coordinate)
                        .tint(item.category == .closure ? Theme.amber : Theme.navy)
                }
            }
            if location.access.isAuthorized {
                UserAnnotation()
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .frame(height: 260)
        .clipShape(.rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .overlay(alignment: .topLeading) { boundaryToggle }
        .accessibilityLabel("Map of \(visibleItems.count) live conditions")
    }

    /// Municipal lines can crowd a countywide view, so let staff drop them.
    private var boundaryToggle: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { showsBoundaries.toggle() }
        } label: {
            Label(
                showsBoundaries ? "Boundaries on" : "Boundaries off",
                systemImage: showsBoundaries ? "map.fill" : "map"
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(showsBoundaries ? Theme.navy : Theme.inkSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: .capsule)
        }
        .buttonStyle(.plain)
        .padding(10)
        .accessibilityLabel(showsBoundaries ? "Hide city boundaries" : "Show city boundaries")
    }

    private var region: MKCoordinateRegion {
        let fallback = CLLocationCoordinate2D(latitude: 44.67, longitude: -93.05)
        let center: CLLocationCoordinate2D = switch scope {
        case .nearMe: location.currentPoint?.coordinate ?? city?.center.coordinate ?? fallback
        case .nearCity, .county: city?.center.coordinate ?? fallback
        }
        let span: Double = switch scope {
        case .nearMe: 0.10
        case .nearCity: 0.16
        case .county: 0.55
        }
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    @ViewBuilder
    private var itemsSection: some View {
        if visibleItems.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text((filter?.title ?? "All conditions").uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .tracking(0.6)
                    Spacer()
                    if filter != nil {
                        Button("Show all") { filter = nil }
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                        NavigationLink(value: item) {
                            LiveItemRow(
                                item: item,
                                reference: referencePoint,
                                isFromDevice: location.currentPoint != nil,
                                showsJurisdiction: scope != .nearCity
                            )
                        }
                        .buttonStyle(.plain)

                        if index < visibleItems.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .civicCard()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 34))
                .foregroundStyle(Theme.steel)
            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(scope == .county
                 ? "Pull down to check for updates."
                 : "Switch to Countywide to see the rest of Dakota County.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .civicCard()
    }

    private var emptyTitle: String {
        switch scope {
        case .nearMe: "Nothing active within 5 miles of you"
        case .nearCity: "Nothing active near \(city?.name ?? "your city")"
        case .county: "Nothing active countywide"
        }
    }

    private var failureCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Some sources didn't load", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)

            ForEach(live.failures) { failure in
                VStack(alignment: .leading, spacing: 2) {
                    Text(failure.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.ink)
                    Text(failure.message)
                        .font(.caption2)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            Text("If you're on the City VPN, GIS servers may be restricted. Try again on a normal connection.")
                .font(.caption2)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .civicCard()
    }
}

private struct LiveItemRow: View {
    let item: LiveItem
    let reference: GeoPoint?
    let isFromDevice: Bool
    let showsJurisdiction: Bool

    private var distanceText: String? {
        guard let reference, let miles = item.distanceInMiles(from: reference) else { return nil }
        if miles < 0.1 { return isFromDevice ? "at your location" : "here" }
        let value = miles.formatted(.number.precision(.fractionLength(1)))
        return isFromDevice ? "\(value) mi away" : "\(value) mi"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.category.systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(item.category == .closure ? Theme.amber : Theme.steel)
                .frame(width: 22)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    if let impact = item.impact {
                        StatusChip(text: impact, tone: item.isFullClosure ? .amber : .steel)
                    }
                    if let segmentSummary = item.segmentSummary {
                        Text(segmentSummary)
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    if showsJurisdiction, let jurisdiction = item.jurisdiction {
                        Label(jurisdiction, systemImage: "building.2")
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    if let distanceText {
                        Label(distanceText, systemImage: isFromDevice ? "location.fill" : "mappin")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Theme.inkSecondary)
                            .labelStyle(.titleAndIcon)
                    }
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.7))
                .padding(.top, 3)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
