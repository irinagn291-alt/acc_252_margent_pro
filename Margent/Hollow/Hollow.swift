import Foundation

/// Role: Hollow. Gone freeze: frozen page and frozen progress. The Spine renders hollow from this.
struct Hollow: Equatable, Sendable {
    var frozenPage: Int
    var frozenProgress: Double

    init(frozenPage: Int, frozenProgress: Double) {
        self.frozenPage = frozenPage
        self.frozenProgress = frozenProgress
    }

    init?(_ volume: Volume) {
        switch volume.stance {
        case .held:
            return nil
        case .gone(let frozenPage):
            self.frozenPage = frozenPage
            self.frozenProgress = volume.progressFraction
        }
    }
}
