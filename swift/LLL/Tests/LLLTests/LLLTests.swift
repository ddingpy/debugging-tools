import Testing
import Foundation
@testable import LLL

@Suite("LLL Tests")
struct LLLTests {

    @Test("Test for test")
    func testExample() throws {
        #expect(true)
    }
}

// Custom error type for testing
enum TestError: Error {
    case invalidURL
    case networkError
}
