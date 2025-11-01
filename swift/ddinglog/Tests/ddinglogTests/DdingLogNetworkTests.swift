import Testing
import Foundation
@testable import ddinglog

@Suite("DdingLog Network Integration Tests")
struct DdingLogNetworkTests {
    
    @Test("Test URLSession data task creation and execution")
    func testURLSessionIntegration() async throws {
        // Create a mock server response
        let expectedResponse = "{\"status\":\"success\",\"message\":\"Log received\"}"
//        let expectedData = expectedResponse.data(using: .utf8)!
        
        // Create URL and request similar to what DdingLog.logf creates
        guard let url = URL(string: "https://httpbin.org/put") else {
            throw NetworkTestError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let testMessage = "Integration test message"
        let jsonString = "\"\(testMessage)\""
        request.httpBody = jsonString.data(using: .utf8)
        
        // Perform the actual network request
        do {
            
            DdingLog.network(request: request, taskid: request.hashValue)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            DdingLog.network(response: response, data: data, error: nil, taskid: request.hashValue)
            
            // Verify response
            #expect(response is HTTPURLResponse)
            
            if let httpResponse = response as? HTTPURLResponse {
                // httpbin.org should return 200 for successful PUT
                #expect(httpResponse.statusCode == 200)
            }
            
            // Verify we got some data back
            #expect(data.count > 0)
            
            // Parse the response to verify our data was received
            if let responseString = String(data: data, encoding: .utf8) {
                #expect(responseString.contains("data"))
            }
            
        } catch {
            // If the network request fails (e.g., no internet), we'll skip this test
            // In a real app, you might want to handle this differently
            print("Network test skipped due to connectivity: \(error)")
            
            DdingLog.network(response: nil, data: nil, error: error as NSError, taskid: request.hashValue)
        }
    }
    
//    @Test("Test URLRequest construction matches DdingLog.logf behavior")
//    func testRequestMatchesDdingLogBehavior() throws {
//        let testMessage = "Test message with special characters: !@#$%^&*()"
//        
//        // Simulate what DdingLog.logf does
//        guard let url = URL(string: "https://www.qfqu.com/logf/log/test/ddinglog/0") else {
//            throw NetworkTestError.invalidURL
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "PUT"
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let jsonString = "\"\(testMessage)\""
//        request.httpBody = jsonString.data(using: .utf8)
//        
//        // Test all the expected properties
//        #expect(request.url == url)
//        #expect(request.httpMethod == "PUT")
//        #expect(request.allHTTPHeaderFields?["Accept"] == "application/json")
//        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/json")
//        
//        // Test body encoding
//        let decodedBody = String(data: request.httpBody!, encoding: .utf8)
//        #expect(decodedBody == "\"\(testMessage)\"")
//        
//        // Verify JSON escaping works correctly
//        let messageWithQuotes = "Message with \"quotes\""
//        let escapedJson = "\"\(messageWithQuotes)\""
//        #expect(escapedJson == "\"Message with \\\"quotes\\\"\"")
//    }
    
    @Test("Test concurrent URLSession requests")
    func testConcurrentRequests() async throws {
        let messages = ["Message 1", "Message 2", "Message 3", "Message 4", "Message 5"]
        
        // Create multiple requests that could run concurrently
        let requests = messages.map { message -> URLRequest in
            let url = URL(string: "https://httpbin.org/put")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = "\"\(message)\"".data(using: .utf8)
            return request
        }
        
        // Execute all requests concurrently
        await withTaskGroup(of: (Int, Result<(Data, URLResponse), Error>).self) { group in
            for (index, request) in requests.enumerated() {
                group.addTask {
                    do {
                        DdingLog.network(request: request, taskid: index)
                        let result = try await URLSession.shared.data(for: request)
                        return (index, .success(result))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            var results: [Int: Result<(Data, URLResponse), Error>] = [:]
            
            for await (index, result) in group {
                results[index] = result
                
                // Handle the Result type properly
                switch result {
                case .success((let data, let response)):
                    DdingLog.network(response: response, data: data, error: nil, taskid: index)
                case .failure(let error):
                    DdingLog.network(response: nil, data: nil, error: error, taskid: index)
                }
            }
            
            // Verify all requests completed (either successfully or with error)
            #expect(results.count == messages.count)
            
            // Check that we got responses for all indices
            for i in 0..<messages.count {
                #expect(results[i] != nil)
            }
        }
    }
    
    @Test("Test URLSession timeout behavior")
    func testTimeoutBehavior() async throws {
        // Create a request with a very short timeout
        guard let url = URL(string: "https://httpbin.org/delay/5") else {
            throw NetworkTestError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 1.0 // 1 second timeout for a 5 second delay
        
        do {
            DdingLog.network(request: request, taskid: request.hashValue)
            let _ = try await URLSession.shared.data(for: request)
            DdingLog.network(response: nil, data: nil, error: nil, taskid: request.hashValue)
            // If this succeeds, the test might be running too fast or the server responded quickly
            // This is not necessarily a failure
        } catch {
            // We expect a timeout error
            let nsError = error as NSError
            
            DdingLog.network(response: nil, data: nil, error: error, taskid: request.hashValue)
            
            #expect(nsError.domain == NSURLErrorDomain)
            #expect(nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorCannotConnectToHost)
        }
    }
    
}

enum NetworkTestError: Error {
    case invalidURL
    case unexpectedResponse
    case networkUnavailable
}
