import XCTest
@testable import Margent

final class SheafStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "mgt.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar = utc
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesGoneSheafAndReread() async throws {
        let origin = Date(timeIntervalSince1970: 1_746_000_000)
        let store = makeStore(now: { origin })
        _ = try await store.setDown(title: "Clay Hours", totalPages: 80)
        let afterSet = await store.florilegium()
        let volumeID = try XCTUnwrap(afterSet.volumes.first?.id)
        _ = try await store.writeSlip(volumeID: volumeID, body: "Pinned at the playhead.", page: 16)
        let written = await store.florilegium()
        let slipID = try XCTUnwrap(written.volumes.first?.sheaf.slips.first?.id)
        _ = try await store.markReread(
            volumeID: volumeID,
            slipID: slipID,
            reread: true
        )
        _ = try await store.markGone(volumeID)
        _ = try await store.setOnboardingComplete(true)
        try await store.flush()

        let relaunched = makeStore(now: { origin })
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertTrue(loaded.florilegium.onboardingComplete)
        XCTAssertEqual(loaded.florilegium.volumes.count, 1)
        let volume = try XCTUnwrap(loaded.florilegium.volumes.first)
        XCTAssertTrue(volume.isHollow)
        XCTAssertEqual(volume.pinnedPage, 16)
        XCTAssertEqual(volume.progressFraction, 16.0 / 80.0, accuracy: 1e-12)
        XCTAssertEqual(volume.sheaf.slips.count, 1)
        XCTAssertEqual(volume.sheaf.slips.first?.body, "Pinned at the playhead.")
        XCTAssertEqual(volume.sheaf.slips.first?.reread, true)
        XCTAssertEqual(volume.sheaf.slips.first?.writtenOn, DayStamp.yyyyMMdd(from: origin, calendar: calendar))
        XCTAssertEqual(loaded.florilegium.goneSheafCount, 1)
        XCTAssertEqual(loaded.florilegium.rereadSlipCount, 1)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = try await store.setDown(title: "Clay Hours", totalPages: 40)
        if let good = defaults.data(forKey: SheafKey.snapshot) {
            defaults.set(good, forKey: SheafKey.backup)
        }
        let file = directory.appendingPathComponent("florilegium.json")
        let backup = directory.appendingPathComponent("florilegium.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: SheafKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.florilegium.volumes.first?.title, "Clay Hours")
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: SheafKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("florilegium.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.florilegium.volumes.isEmpty)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let document = SheafCodec.committed(from: SheafSeed.florilegium())
        let data = try SheafCodec.encode(document)
        let decoded = try SheafCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.volumes.count, 4)
        let gone = try XCTUnwrap(decoded.volumes.first { $0.id == SheafSeed.returnedLightID })
        XCTAssertEqual(gone.stance, "gone")
        XCTAssertEqual(gone.page, 196)

        let mapped = try SheafCodec.florilegium(from: decoded)
        XCTAssertTrue(try XCTUnwrap(mapped.volume(id: SheafSeed.returnedLightID)).isHollow)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try SheafCodec.decode(future)) { error in
            XCTAssertEqual(error as? SheafCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try SheafCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? SheafCodec.Failure, .corrupt)
        }

        var bad = document
        bad.volumes[0].stance = "lent"
        XCTAssertThrowsError(try SheafCodec.florilegium(from: bad)) { error in
            XCTAssertEqual(error as? SheafCodec.Failure, .unknownStance)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        _ = try await store.setDown(title: "Clay Hours", totalPages: 12)
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.florilegium.volumes.isEmpty)
        XCTAssertFalse(loaded.florilegium.onboardingComplete)
        XCTAssertNil(defaults.data(forKey: SheafKey.snapshot))
        XCTAssertNil(defaults.data(forKey: SheafKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_playheadDebounceFlushPersists() async throws {
        let store = makeStore()
        _ = try await store.setDown(title: "Clay Hours", totalPages: 90)
        let afterSet = await store.florilegium()
        let volumeID = try XCTUnwrap(afterSet.volumes.first?.id)
        _ = try await store.advancePlayhead(volumeID: volumeID, page: 33)
        try await store.flush()

        let loaded = await makeStore().load()
        let page = try XCTUnwrap(loaded.florilegium.volumes.first)
        XCTAssertEqual(page.pinnedPage, 33)
        XCTAssertEqual(page.progressFraction, 33.0 / 90.0, accuracy: 1e-12)
    }

    func test_storeRefusesWriteOnGone() async throws {
        let store = makeStore()
        _ = try await store.setDown(title: "Returned Light", totalPages: 20)
        let afterSet = await store.florilegium()
        let volumeID = try XCTUnwrap(afterSet.volumes.first?.id)
        _ = try await store.markGone(volumeID)
        do {
            _ = try await store.writeSlip(volumeID: volumeID, body: "No.", page: 2)
            XCTFail("expected sheafFrozen")
        } catch {
            XCTAssertEqual(error as? VolumeFault, .sheafFrozen)
        }
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnce() async throws {
        let store = makeStore()
        let first = try await store.seedDemoIfNeeded()
        let second = try await store.seedDemoIfNeeded()
        XCTAssertNil(second)
        XCTAssertEqual(first?.volumes.count, 4)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.writeSlipEnabled, true)
        XCTAssertEqual(first?.goneSheafCount, 1)
        XCTAssertTrue(defaults.bool(forKey: SheafKey.demo))
        XCTAssertNotNil(defaults.data(forKey: SheafKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("florilegium.json").path))
    }
    #endif

    private func makeStore(now: @escaping @Sendable () -> Date = { Date() }) -> SheafStore {
        SheafStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0,
            calendar: calendar,
            now: now
        )
    }
}
