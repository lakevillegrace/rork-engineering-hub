import SwiftUI

/// A working checklist with progress that persists between sessions.
struct ChecklistSheet: View {
    let definition: ChecklistDefinition

    @Environment(HubStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var completed: Int {
        definition.steps.filter { store.isStepComplete(checklist: definition.id, step: $0) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(definition.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ProgressView(value: Double(completed), total: Double(definition.steps.count)) {
                            Text("\(completed) of \(definition.steps.count) complete")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.navy)
                        }
                        .tint(Theme.steel)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(definition.steps.enumerated()), id: \.element) { index, step in
                            ChecklistRow(
                                step: step,
                                isComplete: store.isStepComplete(checklist: definition.id, step: step)
                            ) {
                                withAnimation(.snappy(duration: 0.22)) {
                                    store.toggleStep(checklist: definition.id, step: step)
                                }
                            }
                            if index < definition.steps.count - 1 {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                    .civicCard()
                }
                .padding(Theme.pageMargin)
            }
            .background(Theme.canvas)
            .navigationTitle(definition.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { store.resetChecklist(definition.id) }
                        .disabled(completed == 0)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ChecklistRow: View {
    let step: String
    let isComplete: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isComplete ? Theme.steel : Theme.hairline)
                    .contentTransition(.symbolEffect(.replace))

                Text(step)
                    .font(.body)
                    .foregroundStyle(isComplete ? Theme.inkSecondary : Theme.ink)
                    .strikethrough(isComplete, color: Theme.inkSecondary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isComplete ? [.isButton, .isSelected] : .isButton)
    }
}
