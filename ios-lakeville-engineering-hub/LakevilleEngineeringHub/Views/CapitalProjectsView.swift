import SwiftUI

/// Capital Projects page: the selected city's active projects with status, plus
/// project and coordination resources.
struct CapitalProjectsView: View {
    @Environment(HubStore.self) private var store

    var body: some View {
        Group {
            if let category = store.category(id: "capital-projects") {
                CategoryPageView(category: category) {
                    if !store.projects.isEmpty {
                        activeProjectsSection
                    }
                }
            } else {
                ContentUnavailableView("Section unavailable", systemImage: "questionmark.folder")
            }
        }
    }

    private var activeProjectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACTIVE PROJECTS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(0.6)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(store.projects.enumerated()), id: \.element.id) { index, project in
                    NavigationLink(value: HubRoute.project(project.id)) {
                        ProjectRow(project: project)
                    }
                    .buttonStyle(.plain)

                    if index < store.projects.count - 1 {
                        Divider().padding(.leading, 55)
                    }
                }
            }
            .civicCard()
        }
    }
}

private struct ProjectRow: View {
    let project: CapitalProject

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.navy)
                .frame(width: 26)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)

                if let number = project.projectNumber {
                    Text(number)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            Spacer(minLength: 8)

            StatusChip(text: project.phase, tone: project.phase == "Construction" ? .amber : .steel)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
