import SwiftUI

/// Small capsule used for permit and project statuses.
struct StatusChip: View {
    let text: String
    var tone: Tone = .steel

    enum Tone {
        case steel
        case amber
        case positive
        case neutral

        var background: Color {
            switch self {
            case .steel: Theme.steel.opacity(0.16)
            case .amber: Theme.amber.opacity(0.22)
            case .positive: Color(red: 0.851, green: 0.925, blue: 0.878)
            case .neutral: Theme.hairline
            }
        }

        var foreground: Color {
            switch self {
            case .steel: Theme.navy
            case .amber: Color(red: 0.549, green: 0.353, blue: 0.055)
            case .positive: Color(red: 0.106, green: 0.369, blue: 0.216)
            case .neutral: Theme.inkSecondary
            }
        }
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tone.background, in: .capsule)
            .lineLimit(1)
    }
}
