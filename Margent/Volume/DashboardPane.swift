import SwiftUI

/// Role: Volume. Counts gone sheaves and reread slips. ReviewScreen stays on Settings for goals; this is the Dashboard tab.
struct DashboardPane: View {
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

    private var goneVolumes: [Volume] {
        watch.florilegium.volumes.filter(\.isHollow)
    }

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(StudioInk.Palette.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.warning == .startedEmpty {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "Dashboard could not be read.",
                    line: watch.fault ?? "The sheaf started empty.",
                    actionTitle: "Retry"
                ) {
                    Task { await watch.retry() }
                }
            } else if watch.florilegium.volumes.isEmpty {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "No sheaves yet",
                    line: "Counts of gone sheaves and reread slips appear after you set down a book and write.",
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
        ScrollView {
            VStack(alignment: .leading, spacing: StudioInk.space(2)) {
                Text("Gone sheaves stay. Reread is a verdict.")
                    .studio(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                if let fault = watch.fault, watch.warning != .startedEmpty {
                    StudioBanner(text: fault) {
                        Task { await watch.retry() }
                    }
                }
                hero
                twistSurface
                recentSlips
                if goneVolumes.isEmpty {
                    Text("No hollow spines yet. Mark a finished book gone to freeze its sheaf.")
                        .studio(.body)
                        .foregroundStyle(StudioInk.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Hollow spines")
                        .studio(.headline)
                    ForEach(goneVolumes) { volume in
                        Button {
                            onOpen(volume)
                        } label: {
                            HStack(spacing: StudioInk.space(2)) {
                                VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                                    Text(volume.title)
                                        .studio(.headline)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text("Frozen at p. \(StudioInk.page(volume.pinnedPage)) · \(StudioInk.fraction(volume.progressFraction))")
                                        .studio(.caption)
                                        .foregroundStyle(StudioInk.Palette.muted)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text(StudioFace.count(volume.sheaf.slips.count))
                                    .studio(.figure)
                                    .lineLimit(1)
                            }
                            .padding(StudioInk.space(2))
                            .frame(maxWidth: .infinity, minHeight: StudioInk.tap, alignment: .leading)
                            .studioCard()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(StudioPressStyle())
                        .accessibilityLabel("\(volume.title), gone, \(StudioFace.count(volume.sheaf.slips.count)) slips")
                    }
                }
            }
            .padding(StudioInk.space(2))
        }
        .contentMargins(.bottom, StudioInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("mgt_CardBackdrop")
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .accessibilityHidden(true)
            HStack(alignment: .top, spacing: StudioInk.space(2)) {
                figure(
                    value: StudioFace.count(watch.florilegium.goneSheafCount),
                    title: watch.florilegium.goneSheafCount == 1 ? "Gone sheaf" : "Gone sheaves"
                )
                figure(
                    value: StudioFace.count(watch.florilegium.rereadSlipCount),
                    title: watch.florilegium.rereadSlipCount == 1 ? "Reread slip" : "Reread slips"
                )
            }
            .padding(StudioInk.space(2))
        }
        .frame(maxWidth: .infinity, minHeight: StudioInk.space(16))
        .background(StudioInk.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: StudioInk.cardRadius, style: .continuous))
        .studioLift()
    }

    private var twistSurface: some View {
        Group {
            if let gone = goneVolumes.first {
                Button {
                    onOpen(gone)
                } label: {
                    twistBody
                        .contentShape(Rectangle())
                }
                .buttonStyle(StudioPressStyle())
                .accessibilityLabel("Open a hollow spine to reread")
            } else {
                twistBody
            }
        }
    }

    private var twistBody: some View {
        HStack(alignment: .top, spacing: StudioInk.space(2)) {
            Image("mgt_TwistHero")
                .resizable()
                .scaledToFit()
                .frame(width: StudioInk.space(8), height: StudioInk.space(8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                Text("Mark gone, keep the sheaf")
                    .studio(.headline)
                Text("A hollow spine still opens. You reread; you do not add slips. Progress stays frozen at the last page.")
                    .studio(.body)
                    .foregroundStyle(StudioInk.Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioCard()
    }

    private var recentSlips: some View {
        let pins = Array(watch.florilegium.pinsMatching("").prefix(3))
        return Group {
            if !pins.isEmpty {
                Text("Latest slips")
                    .studio(.headline)
                ForEach(pins) { pin in
                    Button {
                        if let volume = watch.volume(id: pin.volumeID) {
                            onOpen(volume)
                        }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: StudioInk.space(1)) {
                            Text(pin.volumeTitle)
                                .studio(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: StudioInk.space(1))
                            Text("p. \(StudioInk.page(pin.slip.page))")
                                .studio(.caption)
                                .foregroundStyle(StudioInk.Palette.muted)
                                .lineLimit(1)
                        }
                        .padding(StudioInk.space(2))
                        .frame(maxWidth: .infinity, minHeight: StudioInk.tap, alignment: .leading)
                        .studioCard()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StudioPressStyle())
                    .accessibilityLabel("\(pin.volumeTitle), page \(StudioInk.page(pin.slip.page))")
                }
            }
        }
    }

    private func figure(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: StudioInk.space(1)) {
            Text(value)
                .studio(.display)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .studio(.caption)
                .foregroundStyle(StudioInk.Palette.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DashboardPane()
}
