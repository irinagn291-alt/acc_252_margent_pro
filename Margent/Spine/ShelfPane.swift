import SwiftUI

/// Role: Spine. Home mechanic. A shelf of clay spines; drill shelf → book → margin. ReviewScreen today.
struct ShelfPane: View {
    @ObservedObject var watch: SheafWatch
    var onOpen: (Volume) -> Void
    var onSetDown: () -> Void

    init(
        watch: SheafWatch,
        onOpen: @escaping (Volume) -> Void = { _ in },
        onSetDown: @escaping () -> Void = {}
    ) {
        self.watch = watch
        self.onOpen = onOpen
        self.onSetDown = onSetDown
    }

    init() {
        self.init(watch: .previewPopulated())
    }

    private var held: Volume? {
        watch.firstHeld
    }

    var body: some View {
        Group {
            if watch.isHauling && watch.spines.isEmpty {
                ProgressView()
                    .tint(StudioInk.Palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.warning == .startedEmpty, watch.spines.isEmpty {
                StudioVacancy(
                    image: "mgt_EmptyHome",
                    headline: "The shelf is empty",
                    line: "Set down your first book — and leave a thought in the margins.",
                    actionTitle: "Retry"
                ) {
                    Task { await watch.retry() }
                }
            } else if watch.spines.isEmpty {
                StudioVacancy(
                    image: "mgt_EmptyHome",
                    headline: "The shelf is empty",
                    line: "Set down your first book — and leave a thought in the margins.",
                    actionTitle: "Set down a book",
                    action: onSetDown
                )
            } else {
                populated
            }
        }
        .background(StudioInk.Palette.background.ignoresSafeArea())
    }

    private var populated: some View {
        VStack(spacing: StudioInk.space(2)) {
            header
            if let fault = watch.fault, watch.warning != .startedEmpty {
                StudioBanner(text: fault) {
                    Task { await watch.retry() }
                }
                .padding(.horizontal, StudioInk.space(2))
            }
            shelfBoard
            if let held {
                writeBench(held)
            }
            StudioCapsule(
                title: watch.writeSlipEnabled ? "Write a slip" : "Set down a book",
                enabled: !watch.isBusy
            ) {
                if let held {
                    onOpen(held)
                } else {
                    onSetDown()
                }
            }
            .padding(.horizontal, StudioInk.space(2))
            goneStrip
        }
        .padding(.bottom, StudioInk.space(2))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(1)) {
            Text("Write a slip at this page")
                .studio(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(jobLine)
                .studio(.body)
                .foregroundStyle(StudioInk.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, StudioInk.space(2))
        .padding(.top, StudioInk.space(1))
    }

    private var jobLine: String {
        if let held {
            return "Tap Write a slip to pin a line to page \(StudioInk.page(held.pinnedPage)) in \(held.title)."
        }
        return "These spines are hollow. Open one to reread, or set down a book you still hold."
    }

    private var goneLine: String {
        let goneCount = watch.florilegium.goneSheafCount
        let rereadCount = watch.florilegium.rereadSlipCount
        let goneWord = goneCount == 1 ? "gone sheaf" : "gone sheaves"
        let rereadWord = rereadCount == 1 ? "reread slip" : "reread slips"
        return "\(StudioFace.count(goneCount)) \(goneWord) · \(StudioFace.count(rereadCount)) \(rereadWord)"
    }

    private var shelfBoard: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image("mgt_CardBackdrop")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.55)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .accessibilityHidden(true)
                VStack(spacing: 0) {
                    Image("mgt_HeaderDecor")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: min(StudioInk.space(10), geo.size.height * 0.2))
                        .clipped()
                        .accessibilityHidden(true)
                        .padding(.top, StudioInk.space(1))
                    HStack(alignment: .bottom, spacing: StudioInk.space(1)) {
                        ForEach(watch.spines) { spine in
                            ClaySpinePost(
                                spine: spine,
                                emphasized: spine.id == held?.id
                            ) {
                                if let volume = watch.volume(id: spine.id) {
                                    onOpen(volume)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, StudioInk.space(2))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ShelfLedge()
                        .fill(StudioInk.Palette.ink.opacity(0.18))
                        .frame(height: StudioInk.space(2))
                        .padding(.horizontal, StudioInk.space(2))
                        .padding(.bottom, StudioInk.space(2))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(StudioInk.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: StudioInk.cardRadius, style: .continuous))
            .studioLift()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, StudioInk.space(2))
    }

    private func writeBench(_ volume: Volume) -> some View {
        Button {
            onOpen(volume)
        } label: {
            HStack(alignment: .center, spacing: StudioInk.space(2)) {
                Image("mgt_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StudioInk.space(7), height: StudioInk.space(7))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                    Text(volume.title)
                        .studio(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Page \(StudioInk.page(volume.pinnedPage)) of \(StudioInk.page(volume.totalPages)) · \(StudioInk.fraction(volume.progressFraction))")
                        .studio(.body)
                        .foregroundStyle(StudioInk.Palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let slip = volume.sheaf.slips.last {
                        Text(slip.body)
                            .studio(.caption)
                            .foregroundStyle(StudioInk.Palette.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(StudioInk.Step.body.font)
                    .foregroundStyle(StudioInk.Palette.ink)
                    .frame(minWidth: StudioInk.tap / 2, minHeight: StudioInk.tap)
                    .accessibilityHidden(true)
            }
            .padding(StudioInk.space(2))
            .frame(maxWidth: .infinity, minHeight: StudioInk.tap, alignment: .leading)
            .studioCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .padding(.horizontal, StudioInk.space(2))
        .accessibilityLabel("Write a slip in \(volume.title), page \(StudioInk.page(volume.pinnedPage))")
        .accessibilityHint("Opens the fused margin sheet.")
    }

    private var goneStrip: some View {
        let gone = watch.florilegium.volumes.first(where: \.isHollow)
        return Group {
            if let gone {
                Button {
                    onOpen(gone)
                } label: {
                    HStack(alignment: .center, spacing: StudioInk.space(2)) {
                        Image("mgt_HollowSpine")
                            .resizable()
                            .scaledToFit()
                            .frame(width: StudioInk.space(6), height: StudioInk.space(6))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                            Text("\(gone.title) is gone. The sheaf stayed.")
                                .studio(.headline)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Text(goneLine)
                                .studio(.caption)
                                .foregroundStyle(StudioInk.Palette.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(StudioInk.Step.body.font)
                            .foregroundStyle(StudioInk.Palette.ink)
                            .frame(minWidth: StudioInk.tap / 2, minHeight: StudioInk.tap)
                            .accessibilityHidden(true)
                    }
                    .padding(StudioInk.space(2))
                    .frame(maxWidth: .infinity, minHeight: StudioInk.tap, alignment: .leading)
                    .studioCard()
                    .contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
                .padding(.horizontal, StudioInk.space(2))
                .accessibilityLabel("\(gone.title), gone, sheaf kept")
                .accessibilityHint("Opens the hollow spine to reread.")
            }
        }
    }
}

#Preview("Populated") {
    ShelfPane()
}

#Preview("Empty") {
    ShelfPane(watch: .previewEmpty())
}
