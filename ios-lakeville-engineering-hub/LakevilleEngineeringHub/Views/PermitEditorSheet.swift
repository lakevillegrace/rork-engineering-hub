import SwiftUI

/// Adds or edits a tracked permit / survey submittal.
struct PermitEditorSheet: View {
    let permit: PermitRecord?

    @Environment(HubStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var number: String = ""
    @State private var applicant: String = ""
    @State private var inbox: PermitInbox = .row
    @State private var status: PermitStatus = .underReview
    @State private var receivedDate: Date = Date()
    @State private var note: String = ""

    private var isValid: Bool {
        !number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Submittal") {
                    TextField("Permit number", text: $number)
                        .autocorrectionDisabled()
                    TextField("Applicant", text: $applicant)
                    Picker("Inbox", selection: $inbox) {
                        ForEach(PermitInbox.allCases) { box in
                            Text(box.longLabel).tag(box)
                        }
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(PermitStatus.allCases) { value in
                            Text(value.rawValue).tag(value)
                        }
                    }
                    DatePicker("Received", selection: $receivedDate, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let permit {
                    Section {
                        Button("Delete submittal", role: .destructive) {
                            store.deletePermits(ids: [permit.id])
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(permit == nil ? "Add Submittal" : "Edit Submittal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let permit else { return }
        number = permit.number
        applicant = permit.applicant
        inbox = permit.inbox
        status = PermitStatus(rawValue: permit.status) ?? .underReview
        receivedDate = permit.receivedDate
        note = permit.note
    }

    private func save() {
        let record = PermitRecord(
            id: permit?.id ?? UUID(),
            number: number.trimmingCharacters(in: .whitespacesAndNewlines),
            applicant: applicant.trimmingCharacters(in: .whitespacesAndNewlines),
            inbox: inbox,
            status: status.rawValue,
            receivedDate: receivedDate,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if permit == nil {
            store.addPermit(record)
        } else {
            store.updatePermit(record)
        }
        dismiss()
    }
}
