import Testing
import Foundation
@testable import ddinglog

@Suite("DdingLog URLSession Tests")
struct DdingLogTests {

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
