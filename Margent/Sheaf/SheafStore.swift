import Foundation

/// Role: Sheaf. The only persistence seam. Views observe the florilegium; they never touch UserDefaults or files.
protocol SheafStoring: Sendable {
    func load() async -> (florilegium: Florilegium, warning: SheafWarning?)
    func florilegium() async -> Florilegium
    func setDown(title: String, totalPages: Int) async throws -> Florilegium
    func writeSlip(volumeID: UUID, body: String, page: Int) async throws -> Florilegium
    func advancePlayhead(volumeID: UUID, page: Int) async throws -> Florilegium
    func markGone(_ volumeID: UUID) async throws -> Florilegium
    func markReread(volumeID: UUID, slipID: UUID, reread: Bool) async throws -> Florilegium
    func setOnboardingComplete(_ flag: Bool) async throws -> Florilegium
    func note(_ florilegium: Florilegium) async
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded() async throws -> Florilegium?
}

/// Role: Sheaf. Memory is the source of truth. UserDefaults mgt.sheaf.v1 plus an Application Support file are projections.
actor SheafStore: SheafStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    private var latest: Florilegium = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: SheafWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
        self.calendar = calendar
        self.now = now
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Margent", isDirectory: true)
    }

    func load() async -> (florilegium: Florilegium, warning: SheafWarning?) {
        warning = nil
        latest = .empty
        dirty = false
        let defaults = preferenceDefaults()
        if let data = defaults.data(forKey: SheafKey.snapshot), let loaded = decode(data) {
            latest = loaded
            return (latest, nil)
        }
        if let loaded = decodeFile(fileURL) {
            latest = loaded
            return (latest, nil)
        }
        if let data = defaults.data(forKey: SheafKey.backup), let loaded = decode(data) {
            latest = loaded
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let loaded = decodeFile(backupURL) {
            latest = loaded
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: SheafKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func florilegium() async -> Florilegium {
        latest
    }

    func setDown(title: String, totalPages: Int) async throws -> Florilegium {
        latest = try latest.settingDown(title: title, totalPages: totalPages)
        try persistCommitted()
        return latest
    }

    func writeSlip(volumeID: UUID, body: String, page: Int) async throws -> Florilegium {
        latest = try latest.writingSlip(
            volumeID: volumeID,
            body: body,
            page: page,
            now: now(),
            calendar: calendar
        )
        try persistCommitted()
        return latest
    }

    func advancePlayhead(volumeID: UUID, page: Int) async throws -> Florilegium {
        latest = try latest.advancingPlayhead(volumeID: volumeID, page: page)
        dirty = true
        scheduleFlush()
        return latest
    }

    func markGone(_ volumeID: UUID) async throws -> Florilegium {
        latest = try latest.markGone(volumeID)
        try persistCommitted()
        return latest
    }

    func markReread(volumeID: UUID, slipID: UUID, reread: Bool) async throws -> Florilegium {
        latest = try latest.markingReread(volumeID: volumeID, slipID: slipID, reread: reread)
        try persistCommitted()
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async throws -> Florilegium {
        latest.onboardingComplete = flag
        try persistCommitted()
        return latest
    }

    func note(_ florilegium: Florilegium) async {
        latest = florilegium
        dirty = true
        scheduleFlush()
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistCommitted()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: SheafKey.snapshot)
        defaults.removeObject(forKey: SheafKey.backup)
        defaults.synchronize()
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        prepareDirectory()
    }

    func seedDemoIfNeeded() async throws -> Florilegium? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        let alreadySeeded = defaults.object(forKey: SheafKey.demo) != nil
        if alreadySeeded, !latest.volumes.isEmpty, latest.onboardingComplete {
            return nil
        }
        latest = SheafSeed.florilegium()
        try persistCommitted()
        defaults.set(true, forKey: SheafKey.demo)
        defaults.synchronize()
        return latest
        #else
        return nil
        #endif
    }

    private func persistCommitted() throws {
        let document = SheafCodec.committed(from: latest)
        let data = try SheafCodec.encode(document)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: SheafKey.snapshot) {
            defaults.set(previous, forKey: SheafKey.backup)
        }
        defaults.set(data, forKey: SheafKey.snapshot)
        defaults.synchronize()
        prepareDirectory()
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistCommitted()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> Florilegium? {
        guard let document = try? SheafCodec.decode(data) else { return nil }
        return try? SheafCodec.florilegium(from: document)
    }

    private func decodeFile(_ url: URL) -> Florilegium? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("florilegium.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("florilegium.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}

/// Role: Sheaf. In-memory hold for tests and later previews. Not a second document.
actor HoldSheaf: SheafStoring {
    private var latest: Florilegium
    private var warning: SheafWarning?
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        florilegium: Florilegium = .empty,
        warning: SheafWarning? = nil,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.latest = florilegium
        self.warning = warning
        self.calendar = calendar
        self.now = now
    }

    func load() async -> (florilegium: Florilegium, warning: SheafWarning?) {
        (latest, warning)
    }

    func florilegium() async -> Florilegium {
        latest
    }

    func setDown(title: String, totalPages: Int) async throws -> Florilegium {
        latest = try latest.settingDown(title: title, totalPages: totalPages)
        return latest
    }

    func writeSlip(volumeID: UUID, body: String, page: Int) async throws -> Florilegium {
        latest = try latest.writingSlip(
            volumeID: volumeID,
            body: body,
            page: page,
            now: now(),
            calendar: calendar
        )
        return latest
    }

    func advancePlayhead(volumeID: UUID, page: Int) async throws -> Florilegium {
        latest = try latest.advancingPlayhead(volumeID: volumeID, page: page)
        return latest
    }

    func markGone(_ volumeID: UUID) async throws -> Florilegium {
        latest = try latest.markGone(volumeID)
        return latest
    }

    func markReread(volumeID: UUID, slipID: UUID, reread: Bool) async throws -> Florilegium {
        latest = try latest.markingReread(volumeID: volumeID, slipID: slipID, reread: reread)
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async throws -> Florilegium {
        latest.onboardingComplete = flag
        return latest
    }

    func note(_ florilegium: Florilegium) async {
        latest = florilegium
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .empty
        warning = nil
    }

    func seedDemoIfNeeded() async throws -> Florilegium? {
        nil
    }
}
