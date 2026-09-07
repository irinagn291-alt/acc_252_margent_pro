import SwiftUI

/// Role: Slip. Fused margin assign. Slip text and currentPage commit together. Held only.
struct MarginSheet: View {
    @ObservedObject var watch: SheafWatch
    var volumeID: UUID
    var onClose: () -> Void
    var onWrote: () -> Void
    var onMarkGone: () -> Void

    @State private var pageValue: Double
    @State private var bodyText: String = ""
    @State private var confirmClose = false
    @FocusState private var writing: Bool

    init(
        watch: SheafWatch,
        volumeID: UUID,
        onClose: @escaping () -> Void = {},
        onWrote: @escaping () -> Void = {},
        onMarkGone: @escaping () -> Void = {}
    ) {
        self.watch = watch
        self.volumeID = volumeID
        self.onClose = onClose
        self.onWrote = onWrote
        self.onMarkGone = onMarkGone
        let page = watch.volume(id: volumeID)?.pinnedPage ?? 1
        _pageValue = State(initialValue: Double(page))
    }

    init() {
        self.init(watch: .previewPopulated(), volumeID: SheafSeed.clayHoursID)
    }

    private var volume: Volume? {
        watch.volume(id: volumeID)
    }

    private var page: Int {
        Int(pageValue.rounded())
    }

    private var canWrite: Bool {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let volume, volume.acceptsSlips else { return false }
        return !trimmed.isEmpty && page >= 1 && page <= volume.totalPages && !watch.isBusy
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            StudioSheetBar(title: volume?.title ?? "Margin", onClose: attemptClose)
            if let volume {
                if volume.isHollow {
                    Text(SheafWatch.copy(.sheafFrozen))
                        .studio(.body)
                        .foregroundStyle(StudioInk.Palette.muted)
                    StudioCapsule(title: "Open the hollow spine") {
                        onMarkGone()
                    }
                } else {
                    held(volume)
                }
            } else {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "That spine is gone from the shelf.",
                    line: "The book is no longer here.",
                    actionTitle: "Close",
                    action: onClose
                )
            }
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(StudioInk.Palette.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.immediately)
        .onChange(of: pageValue) { _, _ in
            Task { await watch.advancePlayhead(volumeID: volumeID, page: page) }
        }
        .confirmationDialog(
            "Leave this slip unwritten?",
            isPresented: $confirmClose,
            titleVisibility: .visible
        ) {
            Button("Discard the line", role: .destructive, action: onClose)
            Button("Keep writing", role: .cancel) {}
        }
        .interactiveDismissDisabled(!bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func held(_ volume: Volume) -> some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            playhead(volume)
            if let fault = watch.fault {
                Text(fault)
                    .studio(.caption)
                    .foregroundStyle(StudioInk.Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $bodyText)
                    .studio(.body)
                    .focused($writing)
                    .scrollContentBackground(.hidden)
                    .padding(StudioInk.space(1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(StudioInk.Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: StudioInk.cardRadius, style: .continuous))
                    .studioLift()
                if bodyText.isEmpty {
                    Text("Write the slip at this page")
                        .studio(.body)
                        .foregroundStyle(StudioInk.Palette.muted)
                        .padding(.horizontal, StudioInk.space(2))
                        .padding(.vertical, StudioInk.space(2))
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: StudioInk.space(2)) {
                Image("mgt_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StudioInk.space(6), height: StudioInk.space(6))
                    .accessibilityHidden(true)
                StudioCapsule(title: "Pin this slip", enabled: canWrite) {
                    writing = false
                    Task {
                        await watch.writeSlip(volumeID: volumeID, body: bodyText, page: page)
                        if watch.fault == nil {
                            onWrote()
                            onClose()
                        }
                    }
                }
            }
            Button(action: onMarkGone) {
                Text("Mark this book gone")
                    .studio(.body)
                    .foregroundStyle(StudioInk.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: StudioInk.tap)
                    .background(StudioInk.Palette.surface, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(StudioPressStyle())
            .accessibilityLabel("Mark this book gone")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { writing = false }
            }
        }
    }

    private func playhead(_ volume: Volume) -> some View {
        VStack(alignment: .leading, spacing: StudioInk.space(1)) {
            HStack {
                Text("Page \(StudioInk.page(page)) of \(StudioInk.page(volume.totalPages))")
                    .studio(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: StudioInk.space(1))
                Text(StudioInk.fraction(volume.progressFraction))
                    .studio(.figure)
                    .lineLimit(1)
            }
            Slider(
                value: $pageValue,
                in: 1 ... Double(max(volume.totalPages, 1)),
                step: 1
            )
            .tint(StudioInk.Palette.accent)
            .frame(minHeight: StudioInk.tap)
            .accessibilityLabel("Current page")
            .accessibilityValue(StudioInk.page(page))
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioCard()
    }

    private func attemptClose() {
        if bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onClose()
        } else {
            confirmClose = true
        }
    }
}

#Preview {
    MarginSheet()
}
