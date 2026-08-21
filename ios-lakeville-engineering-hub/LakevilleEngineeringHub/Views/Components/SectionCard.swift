import SwiftUI

/// A titled white card containing resource rows, matching the grouped-list
/// language used across every hub page.
struct SectionCard: View {
    let section: ResourceSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(0.6)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(section.links.enumerated()), id: \.element.id) { index, link in
                    ResourceRow(link: link)
                    if index < section.links.count - 1 {
                        Divider().padding(.leading, 55)
                    }
                }
            }
            .civicCard()

            if let footnote = section.footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
