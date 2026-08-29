import XCTest
@testable import vindR

@MainActor
final class StartPageTests: XCTestCase {
    func testValidStartPageIsTrimmedAndPreserved() {
        XCTAssertEqual(
            BrowserModel.usableStartPage("  https://example.com/start  \n"),
            "https://example.com/start"
        )
    }

    func testMissingOrInvalidStartPageUsesHardFallback() {
        XCTAssertEqual(BrowserModel.usableStartPage(""), BrowserModel.fallbackStartPage)
        XCTAssertEqual(BrowserModel.usableStartPage("not a url"), BrowserModel.fallbackStartPage)
        XCTAssertEqual(BrowserModel.usableStartPage("file:///tmp/start.html"), BrowserModel.fallbackStartPage)
    }
}
