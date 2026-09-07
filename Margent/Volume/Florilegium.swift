import Foundation

/// Role: Volume. The in-memory source of truth: a shelf of volumes, each with one sheaf.
struct Florilegium: Equatable, Sendable {
    var volumes: [Volume]
    var onboardingComplete: Bool

    static let empty = Florilegium(volumes: [], onboardingComplete: false)

    var spines: [Spine] {
        volumes.map(Spine.init)
    }

    var goneSheafCount: Int {
        volumes.reduce(0) { $0 + ($1.isHollow ? 1 : 0) }
    }

    var rereadSlipCount: Int {
        volumes.reduce(0) { $0 + $1.sheaf.rereadCount }
    }

    var heldCount: Int {
        volumes.reduce(0) { $0 + ($1.acceptsSlips ? 1 : 0) }
    }

    /// Home primary verb is enabled when at least one volume still accepts a slip.
    var writeSlipEnabled: Bool {
        heldCount > 0
    }

    func settingDown(title: String, totalPages: Int, id: UUID = UUID()) throws -> Florilegium {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw VolumeFault.emptyTitle }
        try Volume.requirePage(1, totalPages: totalPages)
        let volume = Volume(
            id: id,
            title: name,
            totalPages: totalPages,
            sheaf: .empty,
            stance: .held(currentPage: 1)
        )
        var next = self
        next.volumes.append(volume)
        return next
    }

    func writingSlip(
        volumeID: UUID,
        body: String,
        page: Int,
        now: Date,
        calendar: Calendar,
        slipID: UUID = UUID()
    ) throws -> Florilegium {
        try mutatingVolume(id: volumeID) { volume in
            try volume.writingSlip(body: body, page: page, now: now, calendar: calendar, id: slipID)
        }
    }

    func advancingPlayhead(volumeID: UUID, page: Int) throws -> Florilegium {
        try mutatingVolume(id: volumeID) { volume in
            try volume.advancingPlayhead(to: page)
        }
    }

    func markGone(_ volumeID: UUID) throws -> Florilegium {
        try mutatingVolume(id: volumeID) { volume in
            try volume.markingGone()
        }
    }

    func markingReread(volumeID: UUID, slipID: UUID, reread: Bool) throws -> Florilegium {
        try mutatingVolume(id: volumeID) { volume in
            try volume.markingReread(slipID: slipID, reread: reread)
        }
    }

    func volume(id: UUID) -> Volume? {
        volumes.first(where: { $0.id == id })
    }

    func pinsMatching(_ query: String) -> [SlipPin] {
        volumes.flatMap { volume in
            volume.sheaf.matching(query).map { slip in
                SlipPin(
                    volumeID: volume.id,
                    volumeTitle: volume.title,
                    volumeIsHollow: volume.isHollow,
                    slip: slip
                )
            }
        }
    }

    private func mutatingVolume(id: UUID, _ transform: (Volume) throws -> Volume) throws -> Florilegium {
        guard let index = volumes.firstIndex(where: { $0.id == id }) else {
            throw VolumeFault.unknownVolume
        }
        var next = self
        next.volumes[index] = try transform(volumes[index])
        return next
    }
}
