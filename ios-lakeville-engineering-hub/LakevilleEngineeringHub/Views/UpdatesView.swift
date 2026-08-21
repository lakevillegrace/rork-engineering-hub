import SwiftUI

/// One dated stream of City, Dakota County and MnDOT notices.
struct UpdatesView: View {
    @Environment(HubStore.self) private var store
    @Environment(LiveOpsService.self) private var live
    @Environment(UpdatesService.self) private var updates
    @Environment(\.openURL) private var openURL

    @State private var agency: UpdateAgency?
    @State private var query: String = ""

    private var visibleItems: [UpdateItem] {
        var result = updates.items
        if let agency {
            result = result.filter { $0.agency == agency }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter { $0.matches(trimmed) }
        }
        return result
    }

    private func count(_ agency: UpdateAgency) -> Int {
        updates.items(from: agency).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: 18) {
                    agencyFilter

                    if updates.isLoading, updates.items.isEmpty {
                        loadingCard
                    } else if visibleItems.isEmpty {
                        emptyState
                    } else {
                        list
                    }

                    if !updates.failedFeeds.isEmpty { failureCard }
                    sourcesNote
                }
                .padding(.horizontal, Theme.pageMargin)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.canvas)
        .scrollDismissesKeyboard(.immediately)
        .refreshable { await reload() }
        .searchable(text: $query, prompt: "Search updates")
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.inline)
        .civicNavigationBar()
        .task {
            if updates.items.isEmpty || updates.isFromCache { await reload() }
        }
        .onChange(of: store.selectedCityID) { _, _ in
            Task { await reload() }
        }
    }

    private func reload() async {
        await updates.refresh(city: store.selectedCity, liveItems: live.items)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Agency Updates")
                .font(.title2.bold())
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                if updates.isLoading {
                    ProgressView().controlSize(.mini).tint(.white)
                    Text("Checking feeds…")
                } else if let lastUpdated = updates.lastUpdated {
                    Image(systemName: updates.isFromCache ? "wifi.slash" : "checkmark.circle.fill")
                        .font(.caption2)
                    Text(updates.isFromCache
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

    private var agencyFilter: some View {
        HStack(spacing: 8) {
            filterChip(title: "All", count: updates.items.count, isActive: agency == nil) {
                agency = nil
            }
            ForEach(UpdateAgency.allCases) { value in
                filterChip(
                    title: value.shortLabel,
                    count: count(value),
                    isActive: agency == value
                ) {
                    agency = (agency == value) ? nil : value
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: agency)
    }

    private func filterChip(
        title: String,
        count: Int,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(isActive ? .white : Theme.navy)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(isActive ? .white.opacity(0.9) : Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isActive ? Theme.navy : Theme.surface)
            .clipShape(.rect(cornerRadius: 11))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) \(title) updates")
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                Button {
                    if let link = item.link, let url = URL(string: link) { openURL(url) }
                } label: {
                    UpdateRow(item: item)
                }
                .buttonStyle(.plain)
                .disabled(item.link == nil)

                if index < visibleItems.count - 1 {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .civicCard()
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Checking agency feeds…")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .civicCard()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(Theme.steel)
            Text(UpdateFeed.feeds(for: store.selectedCityID).isEmpty
                 ? "No city feed configured"
                 : "No updates match")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(UpdateFeed.feeds(for: store.selectedCityID).isEmpty
                 ? "\(store.selectedCity?.displayName ?? "This city") doesn't publish a public news feed. County and MnDOT notices still appear here."
                 : "Try a different filter or pull down to refresh.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .civicCard()
    }

    private var failureCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.amber)
                .accessibilityHidden(true)
            Text("Couldn't reach: \(updates.failedFeeds.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .civicCard()
    }

    private var sourcesNote: some View {
        Text("City notices come from the City's public news and alert feeds. County items are Dakota County projects revised in the last 90 days. MnDOT items are live 511 events inside Dakota County.")
            .font(.caption2)
            .foregroundStyle(Theme.inkSecondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

private struct UpdateRow: View {
    let item: UpdateItem

    private var tone: Color {
        switch item.agency {
        case .city: Theme.navy
        case .county: Theme.steel
        case .state: Theme.amber
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.agency.systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tone)
                .frame(width: 24)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let summary = item.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 6) {
                    StatusChip(text: item.agency.shortLabel, tone: item.agency == .state ? .amber : .steel)
                    if let published = item.published {
                        Text(published.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 4)

            if item.link != nil {
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary.opacity(0.7))
                    .padding(.top, 3)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
