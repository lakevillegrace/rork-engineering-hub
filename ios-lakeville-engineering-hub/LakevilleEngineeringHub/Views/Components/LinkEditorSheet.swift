import SwiftUI

/// Lets staff attach the real SharePoint / web address to a resource row.
struct LinkEditorSheet: View {
    let link: ResourceLink

    @Environment(HubStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var address: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://lakevilleminnesota.sharepoint.com/…", text: $address, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .lineLimit(1...4)
                } header: {
                    Text("Link address")
                } footer: {
                    Text("Paste the SharePoint page, document or list address for “\(link.title)”. It is saved on this device only.")
                }

                if store.hasURL(for: link) {
                    Section {
                        Button("Remove link", role: .destructive) {
                            store.setURL("", for: link)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(link.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setURL(address, for: link)
                        dismiss()
                    }
                    .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { address = store.urlString(for: link) }
    }
}
