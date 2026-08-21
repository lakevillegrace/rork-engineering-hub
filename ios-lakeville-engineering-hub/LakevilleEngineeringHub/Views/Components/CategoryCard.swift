import SwiftUI

/// One of the six category tiles on the Hub home grid.
struct CategoryCard: View {
    let category: HubCategory

    var body: some View {
        NavigationLink(value: HubRoute.category(category.id)) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Theme.navy)
                    .frame(height: 34, alignment: .bottom)
                    .accessibilityHidden(true)

                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(category.summary)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.steel)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .civicCard()
        }
        .buttonStyle(CategoryCardButtonStyle())
        .accessibilityLabel("\(category.title). \(category.summary)")
    }
}

/// Subtle press feedback for the home grid tiles.
private struct CategoryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
