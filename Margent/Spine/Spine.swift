import Foundation

/// Role: Spine. Shelf projection of a Volume. Held fills; Gone hollows. Not a stored row.
struct Spine: Equatable, Sendable, Identifiable {
    var id: UUID
    var title: String
    var progressFraction: Double
    var pinnedPage: Int
    var totalPages: Int
    var isHollow: Bool
    var slipCount: Int
    var acceptsSlips: Bool

    init(_ volume: Volume) {
        id = volume.id
        title = volume.title
        progressFraction = volume.progressFraction
        pinnedPage = volume.pinnedPage
        totalPages = volume.totalPages
        isHollow = volume.isHollow
        slipCount = volume.sheaf.slips.count
        acceptsSlips = volume.acceptsSlips
    }
}
