import SwiftUI

/// Role: Spine. Shared studio chrome. Radii and lift live here; hex never leaves StudioInk.
enum StudioFace {
    static let motion: Animation = .easeInOut(duration: 0.28)

    static func count(_ value: Int) -> String {
        StudioInk.page(value)
    }

    static func dayLine(_ stamp: Int, calendar: Calendar = .current) -> String {
        var parts = DateComponents()
        parts.year = stamp / 10_000
        parts.month = (stamp / 100) % 100
        parts.day = stamp % 100
        guard let date = calendar.date(from: parts) else { return "—" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: calendar.startOfDay(for: date))
    }
}

extension View {
    func studio(_ step: StudioInk.Step) -> some View {
        font(step.font)
            .foregroundStyle(StudioInk.Palette.ink)
            .dynamicTypeSize(step == .display ? DynamicTypeSize.xSmall ... DynamicTypeSize.xxxLarge : DynamicTypeSize.xSmall ... DynamicTypeSize.accessibility5)
    }

    func studioLift() -> some View {
        shadow(color: StudioInk.Palette.ink.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    func studioCard() -> some View {
        background(StudioInk.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: StudioInk.cardRadius, style: .continuous))
            .studioLift()
    }
}

/// Role: Spine. Pressed scale for every control. Disabled is a different fill, not only inert.
struct StudioPressStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        StudioPressBody(configuration: configuration, enabled: enabled)
    }
}

private struct StudioPressBody: View {
    var configuration: ButtonStyleConfiguration
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : StudioFace.motion, value: configuration.isPressed)
            .saturation(enabled ? 1 : 0.6)
    }
}

/// Role: Spine. Primary verb. Full-width filled Capsule.
struct StudioCapsule: View {
    var title: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .studio(.headline)
                .foregroundStyle(enabled ? StudioInk.Palette.surface : StudioInk.Palette.muted)
                .frame(maxWidth: .infinity, minHeight: StudioInk.tap)
                .padding(.horizontal, StudioInk.space(2))
                .background(
                    (enabled ? StudioInk.Palette.accent : StudioInk.Palette.muted.opacity(0.28)),
                    in: Capsule()
                )
                .contentShape(Capsule())
        }
        .buttonStyle(StudioPressStyle(enabled: enabled))
        .disabled(!enabled)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

/// Role: Spine. Full-page empty or error. CTA sits at the bottom, full width.
struct StudioVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: StudioInk.space(2)) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: StudioInk.space(30))
                .overlay {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .accessibilityHidden(true)
                }
            Text(headline)
                .studio(.display)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .studio(.body)
                .foregroundStyle(StudioInk.Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            StudioCapsule(title: actionTitle, action: action)
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StudioInk.Palette.background)
    }
}

/// Role: Spine. Recoverable warning or fault with retry.
struct StudioBanner: View {
    var text: String
    var retryTitle: String = "Retry"
    var retry: () -> Void

    var body: some View {
        HStack(spacing: StudioInk.space(1)) {
            Text(text)
                .studio(.caption)
                .foregroundStyle(StudioInk.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: StudioInk.space(1))
            Button(action: retry) {
                Text(retryTitle)
                    .studio(.caption)
                    .foregroundStyle(StudioInk.Palette.accent)
                    .frame(minWidth: StudioInk.tap, minHeight: StudioInk.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StudioPressStyle())
            .accessibilityLabel(retryTitle)
        }
        .padding(.horizontal, StudioInk.space(2))
        .padding(.vertical, StudioInk.space(1))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioInk.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous))
    }
}

/// Role: Spine. Verdict chip. Reread or not — never a star.
struct StudioChip: View {
    var title: String
    var lit: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .studio(.caption)
                .foregroundStyle(lit ? StudioInk.Palette.surface : StudioInk.Palette.ink)
                .lineLimit(1)
                .padding(.horizontal, StudioInk.space(2))
                .frame(minHeight: StudioInk.tap)
                .background(
                    RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous)
                        .fill(lit ? StudioInk.Palette.accent : StudioInk.Palette.surface)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous)
                        .stroke(StudioInk.Palette.muted.opacity(0.35), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous))
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel(title)
    }
}

struct StudioIconButton: View {
    var systemName: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(StudioInk.Step.body.font)
                .foregroundStyle(StudioInk.Palette.ink)
                .frame(minWidth: StudioInk.tap, minHeight: StudioInk.tap)
                .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel(label)
    }
}

struct StudioSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: StudioInk.space(1)) {
            Text(title)
                .studio(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: StudioInk.space(1))
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(StudioInk.Step.body.font)
                    .foregroundStyle(StudioInk.Palette.ink)
                    .frame(minWidth: StudioInk.tap, minHeight: StudioInk.tap)
                    .background(StudioInk.Palette.surface, in: Circle())
                    .contentShape(Rectangle())
            }
            .buttonStyle(StudioPressStyle())
            .accessibilityLabel("Close")
        }
    }
}
