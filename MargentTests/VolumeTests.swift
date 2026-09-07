import XCTest
@testable import Margent

final class VolumeTests: XCTestCase {
    private var calendar: Calendar!
    private let now = Date(timeIntervalSince1970: 1_746_000_000)

    override func setUp() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    func test_familyInvariant_oneSheafPerVolume_rereadNotStars_progressFraction() throws {
        var shelf = Florilegium.empty
        shelf = try shelf.settingDown(title: "Clay Hours", totalPages: 200, id: SheafSeed.clayHoursID)
        shelf = try shelf.settingDown(title: "Sheaf of Rivers", totalPages: 100, id: SheafSeed.riverSheafID)
        shelf = try shelf.writingSlip(
            volumeID: SheafSeed.clayHoursID,
            body: "Keep the sheaf, not the loaned copy.",
            page: 40,
            now: now,
            calendar: calendar,
            slipID: SheafSeed.clayFirstSlipID
        )

        let clay = try XCTUnwrap(shelf.volume(id: SheafSeed.clayHoursID))
        let river = try XCTUnwrap(shelf.volume(id: SheafSeed.riverSheafID))
        XCTAssertEqual(clay.sheaf.slips.count, 1)
        XCTAssertTrue(river.sheaf.slips.isEmpty)
        XCTAssertEqual(clay.sheaf.slips.first?.id, SheafSeed.clayFirstSlipID)
        XCTAssertEqual(river.sheaf.slips.map(\.id), [])

        XCTAssertEqual(clay.progressFraction, 40.0 / 200.0, accuracy: 1e-12)
        XCTAssertEqual(clay.pinnedPage, 40)

        let slip = try XCTUnwrap(clay.sheaf.slips.first)
        XCTAssertFalse(slip.reread)
        let labels = Mirror(reflecting: slip).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.localizedCaseInsensitiveContains("star") })
        XCTAssertFalse(labels.contains { $0.localizedCaseInsensitiveContains("rating") })
        XCTAssertTrue(labels.contains("reread"))

        shelf = try shelf.markingReread(
            volumeID: SheafSeed.clayHoursID,
            slipID: SheafSeed.clayFirstSlipID,
            reread: true
        )
        XCTAssertEqual(shelf.rereadSlipCount, 1)
        XCTAssertEqual(try XCTUnwrap(shelf.volume(id: SheafSeed.clayHoursID)).sheaf.slips.first?.reread, true)
    }

    func test_writeSlip_emptyPopulatedInvalid() throws {
        var shelf = try Florilegium.empty.settingDown(title: "Clay Hours", totalPages: 80, id: SheafSeed.clayHoursID)

        do {
            _ = try shelf.writingSlip(
                volumeID: SheafSeed.clayHoursID,
                body: "   ",
                page: 3,
                now: now,
                calendar: calendar
            )
            XCTFail("expected emptySlip")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .emptySlip)
        }

        do {
            _ = try shelf.writingSlip(
                volumeID: SheafSeed.clayHoursID,
                body: "A line",
                page: 0,
                now: now,
                calendar: calendar
            )
            XCTFail("expected pageOutOfRange")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .pageOutOfRange)
        }

        do {
            _ = try shelf.writingSlip(
                volumeID: SheafSeed.clayHoursID,
                body: "A line",
                page: 81,
                now: now,
                calendar: calendar
            )
            XCTFail("expected pageOutOfRange")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .pageOutOfRange)
        }

        do {
            _ = try Florilegium.empty.settingDown(title: "  ", totalPages: 10)
            XCTFail("expected emptyTitle")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .emptyTitle)
        }

        shelf = try shelf.writingSlip(
            volumeID: SheafSeed.clayHoursID,
            body: "  First margin note.  ",
            page: 12,
            now: now,
            calendar: calendar,
            slipID: SheafSeed.clayFirstSlipID
        )
        let volume = try XCTUnwrap(shelf.volume(id: SheafSeed.clayHoursID))
        XCTAssertEqual(volume.sheaf.slips.count, 1)
        XCTAssertEqual(volume.sheaf.slips.first?.body, "First margin note.")
        XCTAssertEqual(volume.pinnedPage, 12)
        XCTAssertEqual(volume.progressFraction, 12.0 / 80.0, accuracy: 1e-12)
        XCTAssertTrue(shelf.writeSlipEnabled)
        XCTAssertEqual(DayStamp.yyyyMMdd(from: now, calendar: calendar), 20250430)
    }

    func test_markGone_hollowsSpineAndFreezesSheaf() throws {
        var shelf = try Florilegium.empty.settingDown(
            title: "Returned Light",
            totalPages: 50,
            id: SheafSeed.returnedLightID
        )
        shelf = try shelf.writingSlip(
            volumeID: SheafSeed.returnedLightID,
            body: "Keep this line after the book goes back.",
            page: 20,
            now: now,
            calendar: calendar,
            slipID: SheafSeed.returnedFirstSlipID
        )
        let before = try XCTUnwrap(shelf.volume(id: SheafSeed.returnedLightID)).progressFraction
        XCTAssertEqual(before, 20.0 / 50.0, accuracy: 1e-12)
        XCTAssertFalse(try XCTUnwrap(shelf.spines.first).isHollow)

        shelf = try shelf.markGone(SheafSeed.returnedLightID)
        let gone = try XCTUnwrap(shelf.volume(id: SheafSeed.returnedLightID))
        XCTAssertTrue(gone.isHollow)
        XCTAssertFalse(gone.acceptsSlips)
        XCTAssertEqual(gone.progressFraction, before, accuracy: 1e-12)
        XCTAssertEqual(gone.sheaf.slips.count, 1)
        XCTAssertEqual(shelf.goneSheafCount, 1)
        XCTAssertFalse(shelf.writeSlipEnabled)

        let hollow = try XCTUnwrap(Hollow(gone))
        XCTAssertEqual(hollow.frozenPage, 20)
        XCTAssertEqual(hollow.frozenProgress, before, accuracy: 1e-12)
        XCTAssertTrue(try XCTUnwrap(shelf.spines.first).isHollow)

        do {
            _ = try shelf.writingSlip(
                volumeID: SheafSeed.returnedLightID,
                body: "Should not land.",
                page: 21,
                now: now,
                calendar: calendar
            )
            XCTFail("expected sheafFrozen")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .sheafFrozen)
        }

        do {
            _ = try shelf.advancingPlayhead(volumeID: SheafSeed.returnedLightID, page: 21)
            XCTFail("expected sheafFrozen")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .sheafFrozen)
        }

        shelf = try shelf.markingReread(
            volumeID: SheafSeed.returnedLightID,
            slipID: SheafSeed.returnedFirstSlipID,
            reread: true
        )
        XCTAssertEqual(shelf.rereadSlipCount, 1)
        XCTAssertEqual(try XCTUnwrap(shelf.volume(id: SheafSeed.returnedLightID)).sheaf.slips.count, 1)
        XCTAssertEqual(try XCTUnwrap(shelf.volume(id: SheafSeed.returnedLightID)).progressFraction, before, accuracy: 1e-12)
    }

    func test_architecture_heldGoneFoldAndSheafAppend() throws {
        var volume = Volume(
            id: SheafSeed.clayHoursID,
            title: "Clay Hours",
            totalPages: 10,
            sheaf: .empty,
            stance: .held(currentPage: 1)
        )
        volume = try volume.writingSlip(body: "One", page: 2, now: now, calendar: calendar)
        volume = try volume.writingSlip(body: "Two", page: 3, now: now, calendar: calendar)
        XCTAssertEqual(volume.sheaf.slips.map(\.body), ["One", "Two"])
        XCTAssertEqual(foldProgress(volume.stance, totalPages: 10), 0.3, accuracy: 1e-12)

        volume = try volume.markingGone()
        XCTAssertEqual(foldProgress(volume.stance, totalPages: 10), 0.3, accuracy: 1e-12)
        switch volume.stance {
        case .held:
            XCTFail("Gone must not remain Held")
        case .gone(let frozenPage):
            XCTAssertEqual(frozenPage, 3)
        }

        do {
            _ = try volume.markingGone()
            XCTFail("expected alreadyGone")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .alreadyGone)
        }

        let pins = Florilegium(volumes: [volume], onboardingComplete: true).pinsMatching("two")
        XCTAssertEqual(pins.count, 1)
        XCTAssertTrue(pins.first?.volumeIsHollow ?? false)
    }

    func test_seed_primaryVerbEnabledAndTwistVisible() throws {
        let seed = SheafSeed.florilegium()
        XCTAssertTrue(seed.onboardingComplete)
        XCTAssertTrue(seed.writeSlipEnabled)
        XCTAssertEqual(seed.volumes.count, 4)
        XCTAssertEqual(seed.goneSheafCount, 1)
        XCTAssertGreaterThanOrEqual(seed.volumes.reduce(0) { $0 + $1.sheaf.slips.count }, 7)
        XCTAssertEqual(seed.rereadSlipCount, 3)
        XCTAssertTrue(try XCTUnwrap(seed.volume(id: SheafSeed.returnedLightID)).isHollow)
        XCTAssertTrue(try XCTUnwrap(seed.volume(id: SheafSeed.clayHoursID)).acceptsSlips)
    }

    /// Exhaustive fold used by the architecture test. A third stance would not compile.
    private func foldProgress(_ stance: Volume.Stance, totalPages: Int) -> Double {
        switch stance {
        case .held(let currentPage):
            return Double(currentPage) / Double(totalPages)
        case .gone(let frozenPage):
            return Double(frozenPage) / Double(totalPages)
        }
    }
}
