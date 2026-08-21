import SwiftUI

/// A single capital project: phase, progress, schedule and key contacts.
struct ProjectDetailView: View {
    let project: CapitalProject

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: 22) {
                    if project.progress != nil {
                        progressCard
                    } else {
                        scopeCard
                    }
                    detailsCard
                    if let link = project.infoURL, let url = URL(string: link) {
                        projectPageButton(url)
                    }
                }
                .padding(.horizontal, Theme.pageMargin)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.canvas)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .civicNavigationBar()
        .toolbar(.hidden, for: .tabBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(project.name)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                StatusChip(text: project.phase, tone: .amber)
                if let number = project.projectNumber {
                    Text(number)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            Text(project.schedule)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 18)
        .padding(.bottom, 24)
        .background(Theme.navy)
    }

    /// Used when the City doesn't publish a percent-complete figure.
    private var scopeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scope")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(project.scope)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .civicCard()
    }

    private func projectPageButton(_ url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Label("Open City project page", systemImage: "arrow.up.right.square")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.navy, in: .rect(cornerRadius: 12))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progress")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(project.progress ?? 0, format: .percent.precision(.fractionLength(0)))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.navy)
            }

            ProgressView(value: project.progress ?? 0)
                .tint(Theme.steel)

            Text(project.scope)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .civicCard()
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(label: "Phase", value: project.phase)
            Divider().padding(.leading, 16)
            detailRow(label: "Schedule", value: project.schedule)
            Divider().padding(.leading, 16)
            detailRow(label: "Project manager", value: project.manager)
            if let contractor = project.contractor {
                Divider().padding(.leading, 16)
                detailRow(label: "Contractor", value: contractor)
            }
            if let number = project.projectNumber {
                Divider().padding(.leading, 16)
                detailRow(label: "Project number", value: number)
            }
        }
        .civicCard()
    }

    private func detailRow(label: String, value: String) -> some View {
        LabeledContent {
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        } label: {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
