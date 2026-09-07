import SwiftUI

/// Role: Hollow. Settings sheet. Contact URL pins with re-run and reset; spines scroll above. ReviewScreen goals.
struct SettingsPane: View {
    @ObservedObject var watch: SheafWatch
    var onClose: () -> Void
    var onRerun: () -> Void
    var onOpen: (Volume) -> Void
    var onSetDown: () -> Void
    @State private var confirmReset = false

    init(
        watch: SheafWatch,
        onClose: @escaping () -> Void = {},
        onRerun: @escaping () -> Void = {},
        onOpen: @escaping (Volume) -> Void = { _ in },
        onSetDown: @escaping () -> Void = {}
    ) {
        self.watch = watch
        self.onClose = onClose
        self.onRerun = onRerun
        self.onOpen = onOpen
        self.onSetDown = onSetDown
    }

    init() {
        self.init(watch: .previewPopulated())
    }

    private var slipCount: Int {
        watch.florilegium.volumes.reduce(0) { $0 + $1.sheaf.slips.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            StudioSheetBar(title: "Settings", onClose: onClose)
            if watch.warning == .startedEmpty, watch.florilegium.volumes.isEmpty {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "Settings were lost",
                    line: "The sheaf started empty. You can still contact us or set the shelf down again.",
                    actionTitle: "Retry"
                ) {
                    Task { await watch.retry() }
                }
            } else if let fault = watch.fault, watch.warning == .startedEmpty {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "Could not load settings.",
                    line: fault,
                    actionTitle: "Retry"
                ) {
                    Task { await watch.retry() }
                }
            } else {
                populated
            }
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(StudioInk.Palette.background.ignoresSafeArea())
        .confirmationDialog(
            "Erase every book and slip on this device?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await watch.resetAll() }
            }
            Button("Keep my sheaf", role: .cancel) {}
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            if let fault = watch.fault, watch.warning != .startedEmpty {
                StudioBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: StudioInk.space(2)) {
                    settingsCard
                    shelfBlock
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(1)) {
            contactCard
            StudioCapsule(title: "Re-run onboarding", enabled: !watch.isBusy, action: onRerun)
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .studio(.headline)
                    .foregroundStyle(StudioInk.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: StudioInk.tap)
                    .background(StudioInk.Palette.surface, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(StudioPressStyle())
            .accessibilityLabel("Reset all data")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsCard: some View {
        HStack(alignment: .top, spacing: StudioInk.space(2)) {
            Image("mgt_ControlFace")
                .resizable()
                .scaledToFit()
                .frame(width: StudioInk.space(8), height: StudioInk.space(8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                Text("This device")
                    .studio(.headline)
                Text("Books, slips, and reread verdicts stay on this iPhone or iPad. There is no store login.")
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

    private var shelfBlock: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            Text("On this shelf")
                .studio(.headline)
            VStack(spacing: StudioInk.space(2)) {
                HStack(spacing: StudioInk.space(2)) {
                    figure(
                        value: StudioFace.count(watch.florilegium.heldCount),
                        title: watch.florilegium.heldCount == 1 ? "Held spine" : "Held spines"
                    )
                    figure(
                        value: StudioFace.count(watch.florilegium.goneSheafCount),
                        title: watch.florilegium.goneSheafCount == 1 ? "Gone sheaf" : "Gone sheaves"
                    )
                }
                HStack(spacing: StudioInk.space(2)) {
                    figure(
                        value: StudioFace.count(slipCount),
                        title: slipCount == 1 ? "Slip" : "Slips"
                    )
                    figure(
                        value: StudioFace.count(watch.florilegium.rereadSlipCount),
                        title: watch.florilegium.rereadSlipCount == 1 ? "Reread slip" : "Reread slips"
                    )
                }
            }
            .padding(StudioInk.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .studioCard()
            if watch.florilegium.volumes.isEmpty {
                emptyShelf
            } else {
                ForEach(watch.florilegium.volumes) { volume in
                    volumeRow(volume)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyShelf: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            Text("No books on this shelf yet")
                .studio(.headline)
            Text("Set down a book to keep a sheaf of slips on this device.")
                .studio(.body)
                .foregroundStyle(StudioInk.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            StudioCapsule(title: "Set down a book", action: onSetDown)
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioCard()
    }

    private func volumeRow(_ volume: Volume) -> some View {
        Button {
            onOpen(volume)
        } label: {
            HStack(spacing: StudioInk.space(2)) {
                VStack(alignment: .leading, spacing: StudioInk.space(1)) {
                    Text(volume.title)
                        .studio(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(volumeLine(volume))
                        .studio(.caption)
                        .foregroundStyle(StudioInk.Palette.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(StudioFace.count(volume.sheaf.slips.count))
                    .studio(.figure)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(StudioInk.Step.caption.font)
                    .foregroundStyle(StudioInk.Palette.muted)
                    .accessibilityHidden(true)
            }
            .padding(StudioInk.space(2))
            .frame(maxWidth: .infinity, minHeight: StudioInk.tap, alignment: .leading)
            .studioCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel(volumeAccess(volume))
        .accessibilityHint(volume.acceptsSlips ? "Opens the margin to write a slip." : "Opens the hollow spine to reread.")
    }

    private func volumeLine(_ volume: Volume) -> String {
        let page = StudioInk.page(volume.pinnedPage)
        let slips = StudioFace.count(volume.sheaf.slips.count)
        if volume.isHollow {
            return "Gone · sheaf kept at p. \(page) · \(slips) slips"
        }
        return "Held at p. \(page) · \(slips) slips"
    }

    private func volumeAccess(_ volume: Volume) -> String {
        if volume.isHollow {
            return "\(volume.title), gone, \(StudioFace.count(volume.sheaf.slips.count)) slips"
        }
        return "\(volume.title), held, page \(StudioInk.page(volume.pinnedPage))"
    }

    private func figure(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: StudioInk.space(1)) {
            Text(value)
                .studio(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .studio(.caption)
                .foregroundStyle(StudioInk.Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: StudioInk.tap, alignment: .leading)
    }

    private var contactCard: some View {
        Link(destination: ContactHop.contactURL) {
            HStack(alignment: .center, spacing: StudioInk.space(2)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Contact Margent")
                        .studio(.headline)
                        .foregroundStyle(StudioInk.Palette.accent)
                    Text(ContactHop.contactURL.absoluteString)
                        .studio(.body)
                        .foregroundStyle(StudioInk.Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right")
                    .font(StudioInk.Step.caption.font)
                    .foregroundStyle(StudioInk.Palette.accent)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, StudioInk.space(2))
            .padding(.vertical, StudioInk.space(1))
            .frame(maxWidth: .infinity, minHeight: StudioInk.tap, alignment: .leading)
            .studioCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel("Contact Margent")
        .accessibilityHint(ContactHop.contactURL.absoluteString)
    }
}

#Preview {
    SettingsPane()
}
