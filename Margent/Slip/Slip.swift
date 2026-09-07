import Foundation

/// Role: Slip. One margin note pinned to a page. Verdict is reread or not — never a star.
struct Slip: Equatable, Sendable, Identifiable {
    var id: UUID
    var body: String
    var page: Int
    var reread: Bool
    var writtenOn: Int

    init(
        id: UUID = UUID(),
        body: String,
        page: Int,
        reread: Bool = false,
        writtenOn: Int
    ) {
        self.id = id
        self.body = body
        self.page = page
        self.reread = reread
        self.writtenOn = writtenOn
    }
}

/// Role: Slip. In-process florilegium hit. Own-slip lookup never leaves the sheaf.
struct SlipPin: Equatable, Sendable, Identifiable {
    var volumeID: UUID
    var volumeTitle: String
    var volumeIsHollow: Bool
    var slip: Slip

    var id: UUID { slip.id }
}
