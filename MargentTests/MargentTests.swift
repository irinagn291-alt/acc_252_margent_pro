import XCTest
@testable import Margent

final class MargentTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: MargentApp.self), "MargentApp")
    }

    func test_keysAndContact() {
        XCTAssertEqual(SheafKey.snapshot, "mgt.sheaf.v1")
        XCTAssertEqual(SheafKey.demo, "mgt.demo.v1")
        XCTAssertEqual(ContactHop.userAgent, "Margent/1.0 (iOS; +https://margent-sheaf.pro)")
        XCTAssertEqual(ContactHop.contactURL.absoluteString, "https://margent-sheaf.pro/contact-us")
        XCTAssertEqual(StudioInk.face, "SF Pro")
        XCTAssertEqual(StudioInk.Hex.background, "#F5F7F9")
        XCTAssertEqual(StudioInk.Hex.surface, "#FEFEFE")
        XCTAssertEqual(StudioInk.Hex.ink, "#1B2637")
        XCTAssertEqual(StudioInk.Hex.accent, "#2265C3")
        XCTAssertEqual(StudioInk.Hex.muted, "#647081")
        XCTAssertEqual(StudioInk.Step.allCases.count, 6)
    }
}
