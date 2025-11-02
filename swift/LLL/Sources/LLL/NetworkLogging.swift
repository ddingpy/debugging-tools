import Foundation

actor IndexStore {
    static let shared = IndexStore()
    
    private var lastIndex = 0
    
    private init() { }
    
    func getNextIndex() -> Int {
        lastIndex += 1
        return lastIndex
    }
}

extension DateFormatter {
    static let iso8601WithMilliseconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension URLSession {
    
    public func dataLLL(for req: URLRequest) async throws -> (Data, URLResponse) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let datetimestring = DateFormatter.iso8601WithMilliseconds.string(from: Date(timeIntervalSinceReferenceDate: startTime))
        
        let index = await IndexStore.shared.getNextIndex()
        
        var log = getString(request: req, index: index)
        log += "\n - - - - - - - - - -  END REQUEST (\(datetimestring)) - - - - - - - - - - \n"
        
        do {
            let (data, res) = try await self.data(for: req)
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log += getString(error: nil, response: res, data: data)
            log += "\n - - - - - - - - - -  END RESPONSE (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
            
            LLL.log(log)
            return (data, res)
        } catch {
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log += getString(error: error, response: nil, elapsedTime: elapsedTime)
            log += "\n - - - - - - - - - -  END ERROR (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
            LLL.log(log)
            throw error
        }
    }
    
    private func getString(request: URLRequest, index: Int) -> String {
        let message = { () -> String in
            let urlAsString = request.url?.absoluteString ?? ""
            let urlComponents = URLComponents(string: urlAsString)
            let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
            let path = "\(urlComponents?.path ?? "")"
            let host = "\(urlComponents?.host ?? "")"
            
            var output = "\(index) \(method) \(urlAsString)\n"
            
            output += """
HOST: \(host)
PATH: \(path)

"""
            if let query = urlComponents?.query {
                output += "QUERY: \(query)\n"
            }
            
            output += "\n"
            
            for (key, value) in request.allHTTPHeaderFields ?? [:] {
                output += "\(key): \(value) \n"
            }
            if let body = request.httpBody {
                output += "\n \(String(data: body, encoding: .utf8) ?? "")"
            }
            return output
        }()
        
        return message
    }
    
    private func getString(error: Error?, response: URLResponse?, data: Data? = nil, elapsedTime: TimeInterval? = nil) -> String {
        let message = { () -> String in
            var output = ""
            
            if let elapsedTime = elapsedTime {
                output += "ELAPSED TIME: \(String(format: "%.3f", elapsedTime))s\n"
            }
            
            if let response = response as? HTTPURLResponse {
                output += "HTTP \(response.statusCode)\n"
            }
            if let response = response as? HTTPURLResponse {
                for (key, value) in response.allHeaderFields {
                    output += "\(key): \(value)\n"
                }
            }
            if let body = data {
                output += String(data: body, encoding: .utf8) ?? ""
                
            }
            if let error {
                output += error.localizedDescription
            }
            return output
        }()
        
        return message
    }
}
