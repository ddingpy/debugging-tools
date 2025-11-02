import Foundation

extension URLSession {
    func dataLLL(for req: URLRequest) async throws -> (Data, URLResponse) {
        var log = getString(request: req)
        do {
            let (data, res) = try await self.data(for: req)
            log += getString(error: nil, response: res, data: data)
            LLL.log(log)
            return (data, res)
        } catch {
            log += getString(error: error, response: nil)
            LLL.log(log)
            throw error
        }
    }
    
    private func getString(request: URLRequest) -> String {
        let message = { () -> String in
            let urlAsString = request.url?.absoluteString ?? ""
            let urlComponents = URLComponents(string: urlAsString)
            let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
            let path = "\(urlComponents?.path ?? "")"
            let host = "\(urlComponents?.host ?? "")"
            
            var output = "\(method) \(urlAsString)\n"
            
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
            
            output += "\n - - - - - - - - - -  END REQUEST - - - - - - - - - - \n"
            return output
        }()
        
        return message
    }
    
    private func getString(error: Error?, response: URLResponse?, data: Data? = nil) -> String {
        let message = { () -> String in
            var output = ""
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
                output += "\n - - - - - - - - - -  END RESPONSE - - - - - - - - - - \n"
            }
            if let error {
                output += error.localizedDescription
                output += "\n - - - - - - - - - -  END ERROR - - - - - - - - - - \n"
            }
            return output
        }()
        
        return message
    }
}
