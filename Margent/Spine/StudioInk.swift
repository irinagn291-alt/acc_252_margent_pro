import SwiftUI

/// Role: Spine. Warm terracotta studio tokens. Hex lives only here and in the catalog; SF Pro via `.system`.
enum StudioInk {
    static let face = "SF Pro"

    enum Hex {
        static let background = "#F5F7F9"
        static let surface = "#FEFEFE"
        static let ink = "#1B2637"
        static let accent = "#2265C3"
        static let muted = "#647081"
    }

    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("accent")
        static let muted = Color("muted")
    }

    /// Six SF Pro steps. Display stays at title (≤ 34pt). Spine titles are headline; slip body is body; page pins are caption.
    enum Step: CaseIterable {
        case display
        case headline
        case body
        case figure
        case caption
        case footnote

        var font: Font {
            switch self {
            case .display:
                .system(.title).weight(.semibold)
            case .headline:
                .system(.headline)
            case .body:
                .system(.body)
            case .figure:
                .system(.title3).weight(.semibold).monospacedDigit()
            case .caption:
                .system(.caption)
            case .footnote:
                .system(.footnote)
            }
        }
    }

    static let space: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 16
    static let chipRadius: CGFloat = 10

    static func space(_ units: Int) -> CGFloat {
        space * CGFloat(units)
    }

    static func page(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func fraction(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}
