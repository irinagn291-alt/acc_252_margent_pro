import SwiftUI

/// Role: Spine. Hero drawing on Shelf only. Held fills with progressFraction; Gone cuts a hollow window.
struct ClaySpineShape: Shape {
    var hollow: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: StudioInk.chipRadius, height: StudioInk.chipRadius),
            style: .continuous
        )
        if hollow {
            let window = CGRect(
                x: rect.minX + rect.width * 0.22,
                y: rect.minY + rect.height * 0.30,
                width: rect.width * 0.56,
                height: rect.height * 0.34
            )
            path.addRoundedRect(
                in: window,
                cornerSize: CGSize(width: StudioInk.chipRadius, height: StudioInk.chipRadius),
                style: .continuous
            )
        }
        return path
    }
}

struct ShelfLedge: Shape {
    func path(in rect: CGRect) -> Path {
        Path(
            roundedRect: rect,
            cornerRadius: StudioInk.chipRadius,
            style: .continuous
        )
    }
}

/// Role: Spine. One clay post on the home shelf. Gouache face plus progress; colour is never the only Held/Gone signal.
struct ClaySpinePost: View {
    var spine: Spine
    var emphasized: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: StudioInk.space(1)) {
                GeometryReader { geo in
                    let height = geo.size.height
                    ZStack(alignment: .bottom) {
                        Image(spine.isHollow ? "mgt_HollowSpine" : "mgt_HeldSpine")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: height)
                            .clipped()
                            .accessibilityHidden(true)
                        if spine.isHollow {
                            ClaySpineShape(hollow: true)
                                .stroke(StudioInk.Palette.ink.opacity(0.45), lineWidth: 1.5)
                                .frame(height: min(height * 0.5, StudioInk.space(12)))
                                .padding(.horizontal, StudioInk.space(1))
                                .padding(.bottom, StudioInk.space(1))
                        } else {
                            ClaySpineShape(hollow: false)
                                .fill(StudioInk.Palette.accent)
                                .frame(
                                    width: max(StudioInk.space(1), geo.size.width * CGFloat(spine.progressFraction)),
                                    height: StudioInk.space(1)
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, StudioInk.space(1))
                                .padding(.bottom, StudioInk.space(1))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(spine.title)
                    .studio(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(caption)
                    .studio(.caption)
                    .foregroundStyle(StudioInk.Palette.muted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, StudioInk.space(1))
            .padding(.top, StudioInk.space(1))
            .padding(.bottom, StudioInk.space(1))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .background(
                emphasized ? StudioInk.Palette.accent.opacity(0.12) : StudioInk.Palette.surface.opacity(0.88),
                in: RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous)
                    .stroke(
                        emphasized ? StudioInk.Palette.accent : StudioInk.Palette.ink.opacity(0.12),
                        lineWidth: emphasized ? 2 : 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous))
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel(label)
        .accessibilityHint(spine.acceptsSlips ? "Opens the margin to write a slip." : "Opens the hollow spine to reread.")
        .accessibilityAddTraits(emphasized ? [.isSelected, .isButton] : .isButton)
    }

    private var caption: String {
        if spine.isHollow {
            return "Gone · sheaf kept"
        }
        return "p. \(StudioInk.page(spine.pinnedPage)) · \(StudioInk.fraction(spine.progressFraction))"
    }

    private var label: String {
        if spine.isHollow {
            return "\(spine.title), gone, sheaf kept"
        }
        return "\(spine.title), held, page \(StudioInk.page(spine.pinnedPage)) of \(StudioInk.page(spine.totalPages))"
    }
}
