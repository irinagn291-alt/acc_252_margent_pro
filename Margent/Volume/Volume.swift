import Foundation

/// Role: Volume. Closed algebraic fold Held | Gone. A third role is a defect.
/// Held carries a live currentPage and an open Sheaf. Gone freezes the page and the quote-store.
struct Volume: Equatable, Sendable, Identifiable {
    enum Stance: Equatable, Sendable {
        case held(currentPage: Int)
        case gone(frozenPage: Int)
    }

    var id: UUID
    var title: String
    var totalPages: Int
    var sheaf: Sheaf
    var stance: Stance

    init(id: UUID = UUID(), title: String, totalPages: Int, sheaf: Sheaf, stance: Stance) {
        self.id = id
        self.title = title
        self.totalPages = totalPages
        self.sheaf = sheaf
        self.stance = stance
    }

    var pinnedPage: Int {
        switch stance {
        case .held(let currentPage):
            return currentPage
        case .gone(let frozenPage):
            return frozenPage
        }
    }

    /// progressFraction equals currentPage / totalPages while Held and the stored freeze while Gone.
    var progressFraction: Double {
        guard totalPages > 0 else { return 0 }
        let raw = Double(pinnedPage) / Double(totalPages)
        if raw < 0 { return 0 }
        if raw > 1 { return 1 }
        return raw
    }

    var isHollow: Bool {
        switch stance {
        case .held:
            return false
        case .gone:
            return true
        }
    }

    var acceptsSlips: Bool {
        switch stance {
        case .held:
            return true
        case .gone:
            return false
        }
    }

    func writingSlip(
        body: String,
        page: Int,
        now: Date,
        calendar: Calendar,
        id: UUID = UUID()
    ) throws -> Volume {
        switch stance {
        case .gone:
            throw VolumeFault.sheafFrozen
        case .held:
            break
        }
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw VolumeFault.emptySlip }
        try Self.requirePage(page, totalPages: totalPages)
        let slip = Slip(
            id: id,
            body: text,
            page: page,
            reread: false,
            writtenOn: DayStamp.yyyyMMdd(from: now, calendar: calendar)
        )
        var next = self
        next.sheaf = sheaf.appending(slip)
        next.stance = .held(currentPage: page)
        return next
    }

    func advancingPlayhead(to page: Int) throws -> Volume {
        switch stance {
        case .gone:
            throw VolumeFault.sheafFrozen
        case .held:
            try Self.requirePage(page, totalPages: totalPages)
            var next = self
            next.stance = .held(currentPage: page)
            return next
        }
    }

    func markingGone() throws -> Volume {
        switch stance {
        case .gone:
            throw VolumeFault.alreadyGone
        case .held(let currentPage):
            var next = self
            next.stance = .gone(frozenPage: currentPage)
            return next
        }
    }

    func markingReread(slipID: UUID, reread: Bool) throws -> Volume {
        var next = self
        next.sheaf = try sheaf.markingReread(id: slipID, reread: reread)
        return next
    }

    static func requirePage(_ page: Int, totalPages: Int) throws {
        guard totalPages >= 1, page >= 1, page <= totalPages else {
            throw VolumeFault.pageOutOfRange
        }
    }
}
