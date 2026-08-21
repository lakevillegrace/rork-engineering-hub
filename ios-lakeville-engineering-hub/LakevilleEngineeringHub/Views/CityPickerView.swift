import SwiftUI

/// First-launch municipality picker. Everything in the hub — live GIS filters,
/// contacts and resources — keys off this choice.
struct CityPickerView: View {
    @Environment(HubStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// When presented from Settings the view dismisses instead of unlocking the app.
    var isChangingCity: Bool = false

    @State private var query: String = ""

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func filtered(_ list: [City]) -> [City] {
        guard !trimmedQuery.isEmpty else { return list }
        return list.filter { $0.name.localizedStandardContains(trimmedQuery) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !isChangingCity {
                        banner
                    }

                    VStack(spacing: 22) {
                        cityGroup(title: "Cities", cities: filtered(DakotaCounty.cities))
                        cityGroup(title: "Townships", cities: filtered(DakotaCounty.townships))

                        if filtered(DakotaCounty.all).isEmpty {
                            ContentUnavailableView.search(text: query)
                                .padding(.top, 30)
                        }
                    }
                    .padding(.horizontal, Theme.pageMargin)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Theme.canvas)
            .scrollDismissesKeyboard(.immediately)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find your city")
            .navigationTitle(isChangingCity ? "Change City" : "Dakota County")
            .navigationBarTitleDisplayMode(.inline)
            .civicNavigationBar()
            .toolbar {
                if isChangingCity {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Engineering Hub")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Choose the municipality you work for. The hub filters county road data, projects and contacts to your city.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Label("Internal use — city staff only", systemImage: "lock.shield.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.amber)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 14)
        .padding(.bottom, 24)
        .background(Theme.navy)
    }

    @ViewBuilder
    private func cityGroup(title: String, cities: [City]) -> some View {
        if !cities.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .tracking(0.6)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                        Button {
                            select(city)
                        } label: {
                            CityRow(city: city, isSelected: store.selectedCityID == city.id)
                        }
                        .buttonStyle(.plain)

                        if index < cities.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .civicCard()
            }
        }
    }

    private func select(_ city: City) {
        store.selectedCityID = city.id
        if isChangingCity { dismiss() }
    }
}

private struct CityRow: View {
    let city: City
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(city.displayName)
                    .font(.body)
                    .foregroundStyle(Theme.ink)

                if city.hasCuratedContent {
                    Text("Full Engineering content")
                        .font(.caption)
                        .foregroundStyle(Theme.steel)
                } else if city.website == nil {
                    Text("Add city website in Settings")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            Spacer(minLength: 8)

            if city.hasCuratedContent {
                StatusChip(text: "Configured", tone: .positive)
            }

            Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                .font(isSelected ? .body : .caption.weight(.semibold))
                .foregroundStyle(isSelected ? Theme.navy : Theme.inkSecondary.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
