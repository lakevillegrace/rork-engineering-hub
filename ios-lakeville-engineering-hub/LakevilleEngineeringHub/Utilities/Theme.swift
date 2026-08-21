import SwiftUI

/// Civic visual system for the Lakeville Engineering Hub.
enum Theme {
    static let canvas = Color(red: 0.969, green: 0.976, blue: 0.984)
    static let surface = Color.white
    static let navy = Color(red: 0.122, green: 0.306, blue: 0.475)
    static let navyDeep = Color(red: 0.078, green: 0.227, blue: 0.361)
    static let steel = Color(red: 0.290, green: 0.565, blue: 0.769)
    static let amber = Color(red: 0.910, green: 0.639, blue: 0.239)
    static let ink = Color(red: 0.102, green: 0.141, blue: 0.188)
    static let inkSecondary = Color(red: 0.365, green: 0.412, blue: 0.463)
    static let hairline = Color(red: 0.886, green: 0.910, blue: 0.933)

    static let cardRadius: CGFloat = 14
    static let pageMargin: CGFloat = 16
}

extension View {
    /// Applies the shared navy navigation bar treatment used on every hub page.
    func civicNavigationBar() -> some View {
        toolbarBackground(Theme.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    /// White grouped card container used for every link section.
    func civicCard() -> some View {
        background(Theme.surface)
            .clipShape(.rect(cornerRadius: Theme.cardRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
