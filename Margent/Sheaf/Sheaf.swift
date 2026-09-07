import Foundation

/// Role: Sheaf. Fold over Slip values: reduce by append on write, never by star rating.
struct Sheaf: Equatable, Sendable {
    var slips: [Slip]

    static let empty = Sheaf(slips: [])

    var rereadCount: Int {
        slips.reduce(0) { $0 + ($1.reread ? 1 : 0) }
    }

    func appending(_ slip: Slip) -> Sheaf {
        var next = self
        next.slips.append(slip)
        return next
    }

    func markingReread(id: UUID, reread: Bool) throws -> Sheaf {
        guard let index = slips.firstIndex(where: { $0.id == id }) else {
            throw VolumeFault.unknownSlip
        }
        var next = self
        next.slips[index].reread = reread
        return next
    }

    func matching(_ query: String) -> [Slip] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty {
            return slips
        }
        return slips.filter { $0.body.localizedCaseInsensitiveContains(needle) }
    }
}
