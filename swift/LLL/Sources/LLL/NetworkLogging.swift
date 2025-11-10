import Foundation

extension DateFormatter {
    static let iso8601WithMilliseconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension String {
    
    init(request: URLRequest, index: Int) {
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
        
        self = message
    }
    
    init(error: Error?, response: URLResponse?, data: Data? = nil, elapsedTime: TimeInterval? = nil) {
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
        
        self = message
    }
}

extension URLSession {
    
    public func dataLLL(
        for req: URLRequest
    ) async throws -> (Data, URLResponse) {
        
        var log = String(request: req, index: LockedAccumulator.shared.next())
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let datetimestring = DateFormatter.iso8601WithMilliseconds.string(from: Date(timeIntervalSinceReferenceDate: startTime))
        
        log += "\n - - - - - - - - - -  END REQUEST (\(datetimestring)) - - - - - - - - - - \n"
        
        do {
            let (data, res) = try await self.data(for: req)
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log += String(error: nil, response: res, data: data)
            log += "\n - - - - - - - - - -  END RESPONSE (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
            
            LLL.log(log)
            return (data, res)
        } catch {
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log += String(error: error, response: nil, elapsedTime: elapsedTime)
            log += "\n - - - - - - - - - -  END ERROR (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
            LLL.log(log)
            throw error
        }
    }
    
    public func dataTaskLLL(
        with url: URL
    ) -> URLSessionDataTask {
        return self.dataTaskLLL(
            with: URLRequest(url: url),
            completionHandler: { _, _, _ in }
        )
    }
    
    public func dataTaskLLL(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
        
        var log = String(request: request, index: LockedAccumulator.shared.next())
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let datetimestring = DateFormatter.iso8601WithMilliseconds.string(from: Date(timeIntervalSinceReferenceDate: startTime))
        
        log += "\n - - - - - - - - - -  END REQUEST (\(datetimestring)) - - - - - - - - - - \n"
        
        return self.dataTask(
            with: request,
            completionHandler: { [weak self, log] (data: Data?, response: URLResponse?, error: (any Error)?) in
                
                guard let wself = self else {
                    return
                }
                
                var finalLog = log
                
                let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                
                if let response {
                    let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                    finalLog += String(error: nil, response: response, data: data)
                    finalLog += "\n - - - - - - - - - -  END RESPONSE (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
                }
                
                if let error {
                    finalLog += String(error: error, response: nil, elapsedTime: elapsedTime)
                    finalLog += "\n - - - - - - - - - -  END ERROR (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
                }
                LLL.log(finalLog)
                
                completionHandler(data, response, error)
            })
    }
    
}

extension LLL {
    public static func network(request: URLRequest, response: URLResponse?, data: Data?, error: Error?) {
        
        var log = String(request: request, index: LockedAccumulator.shared.next())
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let datetimestring = DateFormatter.iso8601WithMilliseconds.string(from: Date(timeIntervalSinceReferenceDate: startTime))
        
        log += "\n - - - - - - - - - -  END REQUEST (\(datetimestring)) - - - - - - - - - - \n"
        
        
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        
        if let response {
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            log += String(error: nil, response: response, data: data)
            log += "\n - - - - - - - - - -  END RESPONSE (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
        }
        
        if let error {
            log += String(error: error, response: nil, elapsedTime: elapsedTime)
            log += "\n - - - - - - - - - -  END ERROR (\(String(format: "%.3f", elapsedTime))s) - - - - - - - - - - \n"
        }
        LLL.network.log("\(log)")
    }
}
