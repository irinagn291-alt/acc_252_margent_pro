import Foundation
import SwiftUI
import UIKit

/// Role: Sheaf. The single observable fold every view talks to. Pattern-matches Held | Gone; views never touch UserDefaults.
@MainActor
final class SheafWatch: ObservableObject {
    @Published private(set) var florilegium: Florilegium
    @Published private(set) var warning: SheafWarning?
    @Published private(set) var fault: String?
    @Published private(set) var isHauling = false
    @Published private(set) var isBusy = false

    let store: any SheafStoring
    private let shouldLoad: Bool
    private var appeared = false
    private var reviewConsumed = false
    private var haulStarted: Date?
    private var spinnerTask: Task<Void, Never>?

    init(
        store: any SheafStoring,
        florilegium: Florilegium = .empty,
        warning: SheafWarning? = nil,
        fault: String? = nil,
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.florilegium = florilegium
        self.warning = warning
        self.fault = fault
        self.shouldLoad = shouldLoad
    }

    var onboardingComplete: Bool {
        florilegium.onboardingComplete
    }

    var spines: [Spine] {
        florilegium.spines
    }

    var writeSlipEnabled: Bool {
        florilegium.writeSlipEnabled
    }

    var firstHeld: Volume? {
        florilegium.volumes.first(where: \.acceptsSlips)
    }

    func volume(id: UUID) -> Volume? {
        florilegium.volume(id: id)
    }

    func appear() async {
        guard shouldLoad else { return }
        if appeared { return }
        appeared = true
        await haul()
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = Self.saveFailed
        }
    }

    func setDown(title: String, totalPages: Int) async {
        await run(haptic: true) {
            self.florilegium = try await self.store.setDown(title: title, totalPages: totalPages)
        }
    }

    func writeSlip(volumeID: UUID, body: String, page: Int) async {
        await run(haptic: true) {
            self.florilegium = try await self.store.writeSlip(
                volumeID: volumeID,
                body: body,
                page: page
            )
        }
    }

    func advancePlayhead(volumeID: UUID, page: Int) async {
        do {
            florilegium = try await store.advancePlayhead(volumeID: volumeID, page: page)
        } catch let volumeFault as VolumeFault {
            fault = Self.copy(volumeFault)
        } catch {
            fault = Self.saveFailed
        }
    }

    func markGone(_ volumeID: UUID) async {
        await run(haptic: true) {
            self.florilegium = try await self.store.markGone(volumeID)
        }
    }

    func markReread(volumeID: UUID, slipID: UUID, reread: Bool) async {
        await run(haptic: false) {
            self.florilegium = try await self.store.markReread(
                volumeID: volumeID,
                slipID: slipID,
                reread: reread
            )
        }
    }

    func finishOnboarding(skipped: Bool) async {
        _ = skipped
        await run(haptic: false) {
            self.florilegium = try await self.store.setOnboardingComplete(true)
        }
    }

    func reopenOnboarding() async {
        await run(haptic: false) {
            self.florilegium = try await self.store.setOnboardingComplete(false)
        }
    }

    func resetAll() async {
        await run(haptic: false) {
            try await self.store.resetAllData()
            self.florilegium = .empty
            self.warning = nil
        }
    }

    func consumeReview(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> ReviewPane? {
        ReviewLaunch.consume(
            arguments: arguments,
            onboardingComplete: onboardingComplete,
            consumed: &reviewConsumed
        )
    }

    func clearFault() {
        fault = nil
    }

    static func live() -> SheafWatch {
        let directory: URL
        if let support = try? SheafStore.applicationSupportDirectory() {
            directory = support
        } else {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Margent",
                isDirectory: true
            )
        }
        let store = SheafStore(directory: directory)
        #if targetEnvironment(simulator)
        return SheafWatch(
            store: store,
            florilegium: SheafSeed.florilegium(),
            shouldLoad: true
        )
        #else
        return SheafWatch(store: store)
        #endif
    }

    static func previewPopulated() -> SheafWatch {
        SheafWatch(
            store: HoldSheaf(florilegium: SheafSeed.florilegium()),
            florilegium: SheafSeed.florilegium(),
            shouldLoad: false
        )
    }

    static func previewEmpty() -> SheafWatch {
        let shelf = Florilegium(volumes: [], onboardingComplete: true)
        return SheafWatch(
            store: HoldSheaf(florilegium: shelf),
            florilegium: shelf,
            shouldLoad: false
        )
    }

    static func previewError() -> SheafWatch {
        let shelf = Florilegium(volumes: [], onboardingComplete: true)
        return SheafWatch(
            store: HoldSheaf(florilegium: shelf, warning: .startedEmpty),
            florilegium: shelf,
            warning: .startedEmpty,
            fault: "The sheaf could not be read. The shelf is empty.",
            shouldLoad: false
        )
    }

    private func haul() async {
        let started = Date()
        haulStarted = started
        spinnerTask?.cancel()
        spinnerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, !Task.isCancelled, self.haulStarted == started else { return }
            if self.florilegium.volumes.isEmpty {
                self.isHauling = true
            }
        }
        let loaded = await store.load()
        do {
            if let seeded = try await store.seedDemoIfNeeded() {
                florilegium = seeded
                warning = nil
                fault = nil
            } else {
                florilegium = loaded.florilegium
                warning = loaded.warning
                if warning == .startedEmpty {
                    fault = "The sheaf could not be read. The shelf is empty."
                } else if warning == .recoveredFromBackup {
                    fault = "Recovered the last good sheaf."
                }
            }
        } catch {
            florilegium = loaded.florilegium
            warning = loaded.warning
            fault = Self.saveFailed
        }
        spinnerTask?.cancel()
        spinnerTask = nil
        haulStarted = nil
        isHauling = false
    }

    private func run(haptic: Bool, _ work: @escaping () async throws -> Void) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            fault = nil
            try await work()
            if haptic {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch let volumeFault as VolumeFault {
            fault = Self.copy(volumeFault)
        } catch {
            fault = Self.saveFailed
        }
    }

    private static let saveFailed = "The sheaf could not be saved. Try again."

    static func copy(_ fault: VolumeFault) -> String {
        switch fault {
        case .emptyTitle:
            "Name the book before you set it down."
        case .emptySlip:
            "Write a line before pinning the slip."
        case .pageOutOfRange:
            "That page is not in this book."
        case .unknownVolume:
            "That book is not on the shelf."
        case .unknownSlip:
            "That slip is not in this sheaf."
        case .sheafFrozen:
            "This spine is hollow. The sheaf is frozen — you can reread, not add."
        case .alreadyGone:
            "This book is already gone."
        }
    }
}
