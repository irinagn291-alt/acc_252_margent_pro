import SwiftUI

/// Role: Slip. Florilegium of your own slips. Local filter and reread verdict. ReviewScreen log.
struct QuotesPane: View {
    @ObservedObject var watch: SheafWatch
    var onOpen: (Volume) -> Void
    var onSetDown: () -> Void
    @State private var query = ""
    @FocusState private var searchFocused: Bool

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

    private var pins: [SlipPin] {
        watch.florilegium.pinsMatching(query)
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
                    headline: "Quotes could not be read.",
                    line: watch.fault ?? "The sheaf started empty.",
                    actionTitle: "Retry"
                ) {
                    Task { await watch.retry() }
                }
            } else if pins.isEmpty && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "No slips yet",
                    line: "Open a spine and write a line at the page you are on. Search finds only your words.",
                    actionTitle: watch.writeSlipEnabled ? "Write a slip" : "Set down a book"
                ) {
                    if let held = watch.firstHeld {
                        onOpen(held)
                    } else {
                        onSetDown()
                    }
                }
            } else {
                populated
            }
        }
        .background(StudioInk.Palette.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.immediately)
    }

    private var populated: some View {
        VStack(spacing: StudioInk.space(2)) {
            Text("Your slips, searchable. Reread is a yes or no.")
                .studio(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, StudioInk.space(2))
                .padding(.top, StudioInk.space(1))
            TextField("Search your slips", text: $query)
                .studio(.body)
                .padding(.horizontal, StudioInk.space(2))
                .frame(minHeight: StudioInk.tap)
                .background(StudioInk.Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous)
                        .stroke(StudioInk.Palette.muted.opacity(0.25), lineWidth: 1)
                }
                .focused($searchFocused)
                .submitLabel(.search)
                .padding(.horizontal, StudioInk.space(2))
                .padding(.top, StudioInk.space(1))
            if let fault = watch.fault, watch.warning != .startedEmpty {
                StudioBanner(text: fault) {
                    Task { await watch.retry() }
                }
                .padding(.horizontal, StudioInk.space(2))
            }
            if pins.isEmpty {
                StudioVacancy(
                    image: "mgt_EmptyList",
                    headline: "No slips match that line",
                    line: "Clear the search to see every slip in the sheaf.",
                    actionTitle: "Clear search"
                ) {
                    query = ""
                    searchFocused = false
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: StudioInk.space(2)) {
                        ForEach(pins) { pin in
                            pinCard(pin)
                        }
                    }
                    .padding(.horizontal, StudioInk.space(2))
                    .padding(.bottom, StudioInk.space(2))
                }
                .contentMargins(.bottom, StudioInk.space(2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { searchFocused = false }
            }
        }
    }

    private func pinCard(_ pin: SlipPin) -> some View {
        VStack(alignment: .leading, spacing: StudioInk.space(1)) {
            Button {
                if let volume = watch.volume(id: pin.volumeID) {
                    onOpen(volume)
                }
            } label: {
                VStack(alignment: .leading, spacing: StudioInk.space(1)) {
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
                    Text(pin.slip.body)
                        .studio(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text(StudioFace.dayLine(pin.slip.writtenOn))
                            .studio(.caption)
                            .foregroundStyle(StudioInk.Palette.muted)
                        if pin.volumeIsHollow {
                            Text("Gone")
                                .studio(.caption)
                                .foregroundStyle(StudioInk.Palette.muted)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(StudioPressStyle())
            .accessibilityLabel("\(pin.volumeTitle), page \(StudioInk.page(pin.slip.page))")
            StudioChip(
                title: pin.slip.reread ? "Reread" : "Not yet",
                lit: pin.slip.reread
            ) {
                Task {
                    await watch.markReread(
                        volumeID: pin.volumeID,
                        slipID: pin.slip.id,
                        reread: !pin.slip.reread
                    )
                }
            }
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioCard()
    }
}

#Preview {
    QuotesPane()
}
