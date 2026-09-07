import XCTest
@testable import Margent

final class ReviewLaunchTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            ReviewLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = ReviewLaunch.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            ReviewLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinct() {
        XCTAssertEqual(ReviewPane.today.rawValue, "today")
        XCTAssertEqual(ReviewPane.log.rawValue, "log")
        XCTAssertEqual(ReviewPane.goals.rawValue, "goals")
        XCTAssertNotEqual(ReviewPane.today, ReviewPane.log)
        XCTAssertNotEqual(ReviewPane.log, ReviewPane.goals)
        XCTAssertNotEqual(ReviewPane.today, ReviewPane.goals)

        var consumed = false
        XCTAssertEqual(
            ReviewLaunch.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            ReviewLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            ReviewLaunch.consume(
                arguments: ["-ReviewScreen", "aura"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
        XCTAssertEqual(
            ReviewLaunch.peek(arguments: ["-ReviewScreen", "today"]),
            .today
        )
        XCTAssertNil(ReviewLaunch.peek(arguments: ["app"]))
    }

    func test_livePathReadsProcessInfoArguments() {
        var consumed = false
        _ = ReviewLaunch.consume(onboardingComplete: true, consumed: &consumed)
        XCTAssertTrue(consumed)
        XCTAssertFalse(ProcessInfo.processInfo.arguments.isEmpty)
    }
}
