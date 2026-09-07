import SwiftUI

/// Role: Hollow. Twist screen. Confirm mark-gone, then reread a frozen sheaf. Surface on Shelf is the hollow spine.
struct HollowPane: View {
    @ObservedObject var watch: SheafWatch
    var volumeID: UUID
    var onClose: () -> Void

    init(
        watch: SheafWatch,
        volumeID: UUID,
        onClose: @escaping () -> Void = {}
    ) {
        self.watch = watch
        self.volumeID = volumeID
        self.onClose = onClose
    }

    init() {
        self.init(watch: .previewPopulated(), volumeID: SheafSeed.returnedLightID)
    }

    private var volume: Volume? {
        watch.volume(id: volumeID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            StudioSheetBar(title: volume?.title ?? "Hollow spine", onClose: onClose)
            if let volume {
                if volume.isHollow {
                    frozen(volume)
                } else {
                    confirm(volume)
                }
            } else {
                StudioVacancy(
                    image: "mgt_TwistHero",
                    headline: "That spine is not on the shelf.",
                    line: "It may have been reset.",
                    actionTitle: "Close",
                    action: onClose
                )
            }
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(StudioInk.Palette.background.ignoresSafeArea())
    }

    private func confirm(_ volume: Volume) -> some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: StudioInk.space(28))
                .overlay {
                    Image("mgt_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .accessibilityHidden(true)
                }
            Text("The book can leave. The slips stay.")
                .studio(.display)
                .fixedSize(horizontal: false, vertical: true)
            Text("Mark this volume gone if you returned it, sold it, gave it, or lost it. The spine hollows on the shelf. The sheaf freezes at page \(StudioInk.page(volume.pinnedPage)). You can still open it to reread. You cannot add slips.")
                .studio(.body)
                .foregroundStyle(StudioInk.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            if let fault = watch.fault {
                Text(fault)
                    .studio(.caption)
                    .foregroundStyle(StudioInk.Palette.muted)
            }
            Spacer(minLength: 0)
            StudioCapsule(title: "Mark this book gone", enabled: !watch.isBusy) {
                Task { await watch.markGone(volumeID) }
            }
        }
    }

    private func frozen(_ volume: Volume) -> some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            if let fault = watch.fault {
                StudioBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
            HStack(alignment: .top, spacing: StudioInk.space(2)) {
                Image("mgt_HollowSpine")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StudioInk.space(8), height: StudioInk.space(8))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                    Text("Sheaf frozen")
                        .studio(.headline)
                    Text("Page \(StudioInk.page(volume.pinnedPage)) of \(StudioInk.page(volume.totalPages)) · \(StudioInk.fraction(volume.progressFraction))")
                        .studio(.caption)
                        .foregroundStyle(StudioInk.Palette.muted)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(StudioInk.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .studioCard()
            if volume.sheaf.slips.isEmpty {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "No slips in this sheaf",
                    line: "The spine is hollow. There is nothing left to reread here.",
                    actionTitle: "Close",
                    action: onClose
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: StudioInk.space(2)) {
                        ForEach(volume.sheaf.slips) { slip in
                            VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                                HStack {
                                    Text("p. \(StudioInk.page(slip.page))")
                                        .studio(.caption)
                                        .foregroundStyle(StudioInk.Palette.muted)
                                    Spacer(minLength: StudioInk.space(1))
                                    Text(StudioFace.dayLine(slip.writtenOn))
                                        .studio(.caption)
                                        .foregroundStyle(StudioInk.Palette.muted)
                                        .lineLimit(1)
                                }
                                Text(slip.body)
                                    .studio(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                StudioChip(
                                    title: slip.reread ? "Reread" : "Not yet",
                                    lit: slip.reread
                                ) {
                                    Task {
                                        await watch.markReread(
                                            volumeID: volume.id,
                                            slipID: slip.id,
                                            reread: !slip.reread
                                        )
                                    }
                                }
                            }
                            .padding(StudioInk.space(2))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .studioCard()
                        }
                    }
                }
                .contentMargins(.bottom, StudioInk.space(2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    HollowPane()
}
