import SwiftUI

/// Role: Spine. Tab identity. Shelf, Quotes, and Dashboard stay tabs; Settings is never a fourth tab.
enum SpineTab: Hashable {
    case shelf
    case quotes
    case dashboard
}

enum SpineCover: Identifiable, Equatable {
    case settings
    case setDown
    case margin(UUID)
    case hollow(UUID)

    var id: String {
        switch self {
        case .settings:
            "settings"
        case .setDown:
            "setDown"
        case .margin(let id):
            "margin-\(id.uuidString)"
        case .hollow(let id):
            "hollow-\(id.uuidString)"
        }
    }
}

/// Role: Spine. ReviewScreen today|log|goals maps onto Shelf, Quotes, and the Settings sheet.
enum SpineLaunch {
    static func apply(_ pane: ReviewPane, tab: inout SpineTab, cover: inout SpineCover?) {
        switch pane {
        case .today:
            tab = .shelf
            cover = nil
        case .log:
            tab = .quotes
            cover = nil
        case .goals:
            tab = .dashboard
            cover = .settings
        }
    }

    static func peekChrome(
        handlesLaunch: Bool,
        onboardingComplete: Bool,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> (tab: SpineTab, cover: SpineCover?) {
        guard handlesLaunch, onboardingComplete, let pane = ReviewLaunch.peek(arguments: arguments) else {
            return (.shelf, nil)
        }
        var tab = SpineTab.shelf
        var cover: SpineCover?
        apply(pane, tab: &tab, cover: &cover)
        return (tab, cover)
    }
}

/// Role: Spine. Spine-tab chrome. The dock sits on the home indicator. Drill is shelf → volume → margin. Settings arrives as a sheet.
struct SpineChrome: View {
    @ObservedObject var watch: SheafWatch
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab: SpineTab
    @State private var cover: SpineCover?
    @State private var dayStamp = Calendar.current.startOfDay(for: Date())
    @State private var showSuccess = false
    @State private var successTask: Task<Void, Never>?
    @State private var reviewPane: ReviewPane?

    init(watch: SheafWatch, handlesLaunch: Bool = true) {
        self.watch = watch
        self.handlesLaunch = handlesLaunch
        let start = SpineLaunch.peekChrome(
            handlesLaunch: handlesLaunch,
            onboardingComplete: watch.onboardingComplete
        )
        _tab = State(initialValue: start.tab)
        _cover = State(initialValue: start.cover)
    }

    init() {
        self.init(watch: .previewPopulated(), handlesLaunch: false)
    }

    var body: some View {
        Group {
            if handlesLaunch && !watch.onboardingComplete {
                OnboardingPane { skipped in
                    Task { await watch.finishOnboarding(skipped: skipped) }
                }
            } else {
                chrome
            }
        }
        .background(StudioInk.Palette.background.ignoresSafeArea())
        .preferredColorScheme(.light)
        .task {
            guard handlesLaunch else { return }
            await watch.appear()
            captureReview()
            await Task.yield()
            applyStoredReview()
        }
        .onChange(of: watch.onboardingComplete) { _, complete in
            if complete { captureReview() }
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .active {
                dayStamp = Calendar.current.startOfDay(for: Date())
            }
            if phase == .inactive || phase == .background {
                Task { await watch.flush() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            dayStamp = Calendar.current.startOfDay(for: Date())
        }
        .onDisappear { successTask?.cancel() }
        .sheet(item: $cover) { item in
            NavigationStack {
                sheet(for: item)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .presentationDetents([.large])
            .presentationCornerRadius(StudioInk.cardRadius)
            .presentationDragIndicator(.visible)
            .presentationBackground(StudioInk.Palette.background)
        }
    }

    private var chrome: some View {
        VStack(spacing: 0) {
            ZStack {
                tabPage(.shelf, title: "Shelf", addsBook: true) {
                    ShelfPane(
                        watch: watch,
                        onOpen: open(_:),
                        onSetDown: { cover = .setDown }
                    )
                }
                tabPage(.quotes, title: "Quotes", addsBook: false) {
                    QuotesPane(
                        watch: watch,
                        onOpen: open(_:),
                        onSetDown: { cover = .setDown }
                    )
                }
                tabPage(.dashboard, title: "Dashboard", addsBook: false) {
                    DashboardPane(
                        watch: watch,
                        onOpen: open(_:),
                        onSetDown: { cover = .setDown }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            SpineDock(tab: $tab)
        }
        .background(StudioInk.Palette.background.ignoresSafeArea())
        .tint(StudioInk.Palette.accent)
        .id(dayStamp)
        .overlay {
            if showSuccess {
                Image("mgt_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StudioInk.space(10), height: StudioInk.space(10))
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .linear(duration: 0.2) : StudioFace.motion, value: showSuccess)
        .onAppear { applyStoredReview() }
    }

    private func tabPage<Content: View>(
        _ item: SpineTab,
        title: String,
        addsBook: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { chromeToolbar(addsBook: addsBook) }
        }
        .opacity(tab == item ? 1 : 0)
        .allowsHitTesting(tab == item)
        .accessibilityHidden(tab != item)
    }

    @ToolbarContentBuilder
    private func chromeToolbar(addsBook: Bool) -> some ToolbarContent {
        if addsBook {
            ToolbarItem(placement: .topBarLeading) {
                StudioIconButton(systemName: "plus", label: "Set down a book") {
                    cover = .setDown
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            StudioIconButton(systemName: "gearshape", label: "Settings") {
                cover = .settings
            }
        }
    }

    @ViewBuilder
    private func sheet(for item: SpineCover) -> some View {
        switch item {
        case .settings:
            SettingsPane(
                watch: watch,
                onClose: { cover = nil },
                onRerun: {
                    cover = nil
                    Task { await watch.reopenOnboarding() }
                },
                onOpen: open(_:),
                onSetDown: { cover = .setDown }
            )
        case .setDown:
            SetDownSheet(watch: watch, onClose: { cover = nil })
        case .margin(let id):
            MarginSheet(
                watch: watch,
                volumeID: id,
                onClose: { cover = nil },
                onWrote: { flashSuccess() },
                onMarkGone: { cover = .hollow(id) }
            )
        case .hollow(let id):
            HollowPane(watch: watch, volumeID: id, onClose: { cover = nil })
        }
    }

    private func open(_ volume: Volume) {
        if volume.isHollow {
            cover = .hollow(volume.id)
        } else {
            cover = .margin(volume.id)
        }
    }

    private func captureReview() {
        if reviewPane == nil {
            reviewPane = watch.consumeReview()
        }
        applyStoredReview()
    }

    private func applyStoredReview() {
        guard let pane = reviewPane else { return }
        SpineLaunch.apply(pane, tab: &tab, cover: &cover)
    }

    private func flashSuccess() {
        successTask?.cancel()
        successTask = Task {
            showSuccess = true
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            showSuccess = false
        }
    }
}

/// Role: Spine. Grounded tab dock. Surface fill extends through the home-indicator band.
private struct SpineDock: View {
    @Binding var tab: SpineTab

    var body: some View {
        HStack(spacing: StudioInk.space(1)) {
            dockItem(.shelf, title: "Shelf", symbol: "books.vertical")
            dockItem(.quotes, title: "Quotes", symbol: "text.quote")
            dockItem(.dashboard, title: "Dashboard", symbol: "chart.bar")
        }
        .padding(.horizontal, StudioInk.space(1))
        .padding(.top, StudioInk.space(1))
        .frame(maxWidth: .infinity)
        .background {
            StudioInk.Palette.surface
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(StudioInk.Palette.ink.opacity(0.12))
                .frame(height: 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shelf tabs")
    }

    private func dockItem(_ item: SpineTab, title: String, symbol: String) -> some View {
        let selected = tab == item
        return Button {
            tab = item
        } label: {
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(StudioInk.Step.body.font)
                    .symbolVariant(selected ? .fill : .none)
                Text(title)
                    .font(StudioInk.Step.caption.font)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? StudioInk.Palette.accent : StudioInk.Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: StudioInk.tap)
            .padding(.vertical, StudioInk.space(1))
            .background(
                selected ? StudioInk.Palette.accent.opacity(0.14) : Color.clear,
                in: RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
