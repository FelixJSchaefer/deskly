import XCTest
@testable import Deskly

final class DesklyTests: XCTestCase {
    func testStandardPlanMatchesWorkday() {
        let plan = WorkPhase.standardPlan
        XCTAssertEqual(plan.count, 16)
        XCTAssertEqual(plan.reduce(0) { $0 + $1.minutes }, 510)
        XCTAssertEqual(plan.first?.name, "Sitzen · Bürostuhl")
        XCTAssertEqual(plan.last?.name, "Stehen")
    }

    @MainActor
    func testCardWidthHasMinimumAndGrowsWithDuration() {
        let model = DesklyViewModel()
        let short = WorkPhase(minutes: 1, kind: .movement)
        let long = WorkPhase(minutes: 60, kind: .officeChair)
        XCTAssertEqual(model.cardWidth(for: short), 124)
        XCTAssertGreaterThan(model.cardWidth(for: long), model.cardWidth(for: short))
    }
}
