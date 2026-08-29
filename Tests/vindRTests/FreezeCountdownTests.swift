import XCTest
@testable import vindR

@MainActor
final class FreezeCountdownTests: XCTestCase {
    func testFreezeDeadlineTracksTheActualScheduledFreeze() throws {
        let tab = BrowserTab()
        let scheduledAt = Date()

        tab.scheduleFreeze(after: 60)

        let deadline = try XCTUnwrap(tab.freezeDeadline)
        XCTAssertGreaterThanOrEqual(deadline.timeIntervalSince(scheduledAt), 59)
        XCTAssertLessThanOrEqual(deadline.timeIntervalSince(scheduledAt), 61)

        tab.cancelFreeze()
        XCTAssertNil(tab.freezeDeadline)
    }
}
