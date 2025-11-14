import Foundation

extension LLL {
    
    public static func debug(
        request: URLRequest,
        response: URLResponse?,
        data: Data?,
        error: Error?,
        startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    ) {
        let log = network(request: request, response: response, data: data, error: error, startTime: startTime)
        LLL.debug("\(log)")
    }
    
    public static func info(
        request: URLRequest,
        response: URLResponse?,
        data: Data?,
        error: Error?,
        startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    ) {
        let log = network(request: request, response: response, data: data, error: error, startTime: startTime)
        LLL.info("\(log)")
    }
    
    static func network(
        request: URLRequest,
        response: URLResponse?,
        data: Data?,
        error: Error?,
        startTime: CFAbsoluteTime
    ) -> String {
        
        var log = String(request: request, index: LockedAccumulator.shared.next())
        
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
        
        return log
    }
}

#if DEBUG
extension URLSession {
    
    public func dataLLL(
        for req: URLRequest
    ) async throws -> (Data, URLResponse) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let (data, res) = try await self.data(for: req)
            
            let log = LLL.network(request: req, response: res, data: data, error: nil, startTime: startTime)
            LLL.debug(log)
            
            return (data, res)
        } catch {
            let log = LLL.network(request: req, response: nil, data: nil, error: error, startTime: startTime)
            LLL.debug(log)
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
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        return self.dataTask(
            with: request,
            completionHandler: { (data: Data?, response: URLResponse?, error: (any Error)?) in
                
                let log = LLL.network(request: request, response: response, data: data, error: error, startTime: startTime)
                LLL.debug(log)
                
                completionHandler(data, response, error)
            })
    }
}
#endif

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
