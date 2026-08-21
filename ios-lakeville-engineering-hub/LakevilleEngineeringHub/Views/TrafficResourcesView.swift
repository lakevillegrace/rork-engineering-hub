import Charts
import SwiftUI

/// Traffic Resources page: local count data where the city has it, plus mapping,
/// equipment and crash-review resources.
struct TrafficResourcesView: View {
    @Environment(HubStore.self) private var store

    var body: some View {
        Group {
            if let category = store.category(id: "traffic-resources") {
                CategoryPageView(category: category) {
                    if store.trafficCounts.isEmpty {
                        noLocalCountsCard
                    } else {
                        countProgramCard
                    }
                }
            } else {
                ContentUnavailableView("Section unavailable", systemImage: "questionmark.folder")
            }
        }
    }

    /// Shown for cities that don't ship local count data, rather than inventing numbers.
    private var noLocalCountsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No local count data loaded", systemImage: "chart.bar.xaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Dakota County publishes annual average daily traffic for county roads — the link below opens the public service. Attach your city's own count records to any row to keep them here.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .civicCard()
    }

    private var countProgramCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Traffic Count Program")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("Internal count applications, 2026–2029")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }

            Chart(store.trafficCounts) { count in
                BarMark(
                    x: .value("Month", count.month),
                    y: .value("Average daily traffic", count.averageDailyTraffic)
                )
                .foregroundStyle(count.isLatest ? Theme.amber : Theme.navy)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel {
                        if let number = value.as(Int.self) {
                            Text(number / 1_000, format: .number)
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.caption2)
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
            }
            .frame(height: 140)
            .accessibilityLabel("Recent traffic counts by month, in thousands of vehicles per day")

            Text("Thousands of vehicles per day (ADT)")
                .font(.caption2)
                .foregroundStyle(Theme.inkSecondary)

            Divider()

            VStack(spacing: 10) {
                ForEach(store.trafficCounts.suffix(3).reversed()) { count in
                    HStack {
                        Text(count.location)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(count.averageDailyTraffic, format: .number) ADT")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.navy)
                        Text(count.month)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.inkSecondary)
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .civicCard()
    }
}
