import Foundation

/// Role: Spine. ReviewScreen today|log|goals. Read once, only after onboarding.
enum ReviewPane: String, Equatable, Sendable {
    case today
    case log
    case goals
}

/// Role: Spine. Reads ProcessInfo.processInfo.arguments once. If onboarding is still showing, the hook never fires.
enum ReviewLaunch {
    static func peek(arguments: [String] = ProcessInfo.processInfo.arguments) -> ReviewPane? {
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return ReviewPane(rawValue: arguments[next])
    }

    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> ReviewPane? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        return peek(arguments: arguments)
    }
}
