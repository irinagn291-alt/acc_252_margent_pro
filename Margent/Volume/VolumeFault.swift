import Foundation

/// Role: Volume. Typed faults for the Held | Gone fold. Views map these; they never parse strings.
enum VolumeFault: Error, Equatable, Sendable {
    case emptyTitle
    case emptySlip
    case pageOutOfRange
    case unknownVolume
    case unknownSlip
    case sheafFrozen
    case alreadyGone
}
