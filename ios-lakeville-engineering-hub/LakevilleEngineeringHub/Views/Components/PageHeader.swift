import SwiftUI

/// Navy context band that opens every category page.
struct PageHeader: View {
    let title: String
    let summary: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.pageMargin)
        .padding(.top, 18)
        .padding(.bottom, 24)
        .background(Theme.navy)
    }
}

#Preview {
    PageHeader(
        title: "ROW & Utility Permitting",
        summary: "Utility and ROW permit review and coordination.",
        systemImage: "doc.text.magnifyingglass"
    )
}
