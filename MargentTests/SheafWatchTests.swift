import XCTest
@testable import Margent

@MainActor
final class SheafWatchTests: XCTestCase {
    func test_writeSlip_emptyPopulatedInvalid() async throws {
        let watch = SheafWatch.previewPopulated()
        let before = try XCTUnwrap(watch.volume(id: SheafSeed.clayHoursID))
        XCTAssertTrue(before.acceptsSlips)
        XCTAssertEqual(before.sheaf.slips.count, 2)

        await watch.writeSlip(volumeID: SheafSeed.clayHoursID, body: "   ", page: 80)
        XCTAssertEqual(watch.fault, SheafWatch.copy(.emptySlip))
        XCTAssertEqual(watch.volume(id: SheafSeed.clayHoursID)?.sheaf.slips.count, 2)

        watch.clearFault()
        await watch.writeSlip(volumeID: SheafSeed.clayHoursID, body: "A new margin line.", page: 0)
        XCTAssertEqual(watch.fault, SheafWatch.copy(.pageOutOfRange))

        watch.clearFault()
        await watch.writeSlip(volumeID: SheafSeed.clayHoursID, body: "A new margin line.", page: 80)
        XCTAssertNil(watch.fault)
        let after = try XCTUnwrap(watch.volume(id: SheafSeed.clayHoursID))
        XCTAssertEqual(after.sheaf.slips.count, 3)
        XCTAssertEqual(after.pinnedPage, 80)
        XCTAssertEqual(after.progressFraction, 80.0 / 248.0, accuracy: 1e-12)
        XCTAssertEqual(after.sheaf.slips.last?.body, "A new margin line.")
        XCTAssertFalse(after.sheaf.slips.last?.reread ?? true)
    }

    func test_markGone_hollowsAndRefusesWrite() async throws {
        let watch = SheafWatch.previewPopulated()
        XCTAssertTrue(try XCTUnwrap(watch.volume(id: SheafSeed.clayHoursID)).acceptsSlips)
        await watch.markGone(SheafSeed.clayHoursID)
        XCTAssertNil(watch.fault)
        let gone = try XCTUnwrap(watch.volume(id: SheafSeed.clayHoursID))
        XCTAssertTrue(gone.isHollow)
        XCTAssertFalse(gone.acceptsSlips)
        XCTAssertEqual(gone.progressFraction, 72.0 / 248.0, accuracy: 1e-12)
        XCTAssertEqual(watch.florilegium.goneSheafCount, 2)

        await watch.writeSlip(volumeID: SheafSeed.clayHoursID, body: "Should not land.", page: 73)
        XCTAssertEqual(watch.fault, SheafWatch.copy(.sheafFrozen))
        XCTAssertEqual(watch.volume(id: SheafSeed.clayHoursID)?.sheaf.slips.count, 2)
    }

    func test_familyInvariant_oneSheafPerVolume_rereadNotStars() async throws {
        let watch = SheafWatch.previewPopulated()
        let clay = try XCTUnwrap(watch.volume(id: SheafSeed.clayHoursID))
        let river = try XCTUnwrap(watch.volume(id: SheafSeed.riverSheafID))
        XCTAssertTrue(Set(clay.sheaf.slips.map(\.id)).isDisjoint(with: Set(river.sheaf.slips.map(\.id))))
        XCTAssertEqual(clay.progressFraction, 72.0 / 248.0, accuracy: 1e-12)
        let labels = Mirror(reflecting: try XCTUnwrap(clay.sheaf.slips.first)).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.localizedCaseInsensitiveContains("star") })
        XCTAssertTrue(labels.contains("reread"))
        XCTAssertTrue(watch.writeSlipEnabled)
        XCTAssertEqual(watch.spines.first(where: { $0.id == SheafSeed.returnedLightID })?.isHollow, true)
        XCTAssertEqual(watch.spines.first(where: { $0.id == SheafSeed.clayHoursID })?.pinnedPage, 72)
        XCTAssertEqual(watch.spines.first(where: { $0.id == SheafSeed.clayHoursID })?.totalPages, 248)
    }

    func test_consumeReview_onceAfterOnboarding() {
        let blocked = SheafWatch(
            store: HoldSheaf(florilegium: .empty),
            florilegium: .empty,
            shouldLoad: false
        )
        XCTAssertFalse(blocked.onboardingComplete)
        XCTAssertNil(
            blocked.consumeReview(arguments: ["-ReviewScreen", "log"])
        )

        let watch = SheafWatch.previewPopulated()
        XCTAssertEqual(
            watch.consumeReview(arguments: ["-ReviewScreen", "log"]),
            .log
        )
        XCTAssertNil(
            watch.consumeReview(arguments: ["-ReviewScreen", "goals"])
        )
    }

    func test_spineLaunch_threeKeysAreDifferentScreens() {
        var tab = SpineTab.shelf
        var cover: SpineCover? = .settings
        SpineLaunch.apply(.today, tab: &tab, cover: &cover)
        XCTAssertEqual(tab, .shelf)
        XCTAssertNil(cover)

        SpineLaunch.apply(.log, tab: &tab, cover: &cover)
        XCTAssertEqual(tab, .quotes)
        XCTAssertNil(cover)

        SpineLaunch.apply(.goals, tab: &tab, cover: &cover)
        XCTAssertEqual(tab, .dashboard)
        XCTAssertEqual(cover, .settings)
        XCTAssertNotEqual(SpineTab.shelf, SpineTab.quotes)
        XCTAssertNotEqual(SpineTab.quotes, SpineTab.dashboard)
        XCTAssertNotEqual(SpineCover.settings.id, SpineCover.setDown.id)
        XCTAssertNotEqual(ReviewPane.today, ReviewPane.log)
        XCTAssertNotEqual(ReviewPane.log, ReviewPane.goals)

        let today = SpineLaunch.peekChrome(
            handlesLaunch: true,
            onboardingComplete: true,
            arguments: ["-ReviewScreen", "today"]
        )
        XCTAssertEqual(today.tab, .shelf)
        XCTAssertNil(today.cover)

        let log = SpineLaunch.peekChrome(
            handlesLaunch: true,
            onboardingComplete: true,
            arguments: ["-ReviewScreen", "log"]
        )
        XCTAssertEqual(log.tab, .quotes)

        let blocked = SpineLaunch.peekChrome(
            handlesLaunch: true,
            onboardingComplete: false,
            arguments: ["-ReviewScreen", "log"]
        )
        XCTAssertEqual(blocked.tab, .shelf)
        XCTAssertNil(blocked.cover)
    }

    func test_setDownAndReset() async throws {
        let watch = SheafWatch.previewEmpty()
        await watch.setDown(title: "  ", totalPages: 12)
        XCTAssertEqual(watch.fault, SheafWatch.copy(.emptyTitle))
        XCTAssertTrue(watch.florilegium.volumes.isEmpty)

        watch.clearFault()
        await watch.setDown(title: "Clay Hours", totalPages: 40)
        XCTAssertNil(watch.fault)
        XCTAssertEqual(watch.florilegium.volumes.count, 1)
        XCTAssertEqual(watch.florilegium.volumes.first?.title, "Clay Hours")
        XCTAssertTrue(watch.writeSlipEnabled)

        await watch.resetAll()
        XCTAssertTrue(watch.florilegium.volumes.isEmpty)
        XCTAssertFalse(watch.onboardingComplete)
    }

    func test_presentationTypesExist() {
        XCTAssertEqual(String(describing: SheafWatch.self), "SheafWatch")
        XCTAssertEqual(String(describing: SpineChrome.self), "SpineChrome")
        XCTAssertEqual(String(describing: ShelfPane.self), "ShelfPane")
        XCTAssertEqual(String(describing: QuotesPane.self), "QuotesPane")
        XCTAssertEqual(String(describing: DashboardPane.self), "DashboardPane")
        XCTAssertEqual(String(describing: SettingsPane.self), "SettingsPane")
        XCTAssertEqual(String(describing: HollowPane.self), "HollowPane")
        XCTAssertEqual(String(describing: MarginSheet.self), "MarginSheet")
        XCTAssertEqual(String(describing: OnboardingPane.self), "OnboardingPane")
        XCTAssertEqual(String(describing: SetDownSheet.self), "SetDownSheet")
        XCTAssertEqual(String(describing: ClaySpineShape.self), "ClaySpineShape")
    }
}
