import Foundation
import os
import CoreLocation

public enum LLL {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? ""
    private static let logger = Logger(subsystem: subsystem, category: "LLL")
    
    public static func log(_ message: @autoclosure () -> String) {
        let str = message()
        logger.log("\(str)")
    }
    
    public static func logf(_ message: @autoclosure () -> String) {
        
        let str = message()
        
        guard let url = URL(string: "https://www.qfqu.com/logf/log/test/LLL/0") else {
            fatalError("Invalid URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonString = "\"\(str)\""
        request.httpBody = jsonString.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
            }
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
        }
        task.resume()
    }
    
    public static func network(request: URLRequest, taskid: Int = 0) {
        let message = { () -> String in
            let urlAsString = request.url?.absoluteString ?? ""
            let urlComponents = URLComponents(string: urlAsString)
            let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
            let path = "\(urlComponents?.path ?? "")"
            let query = "\(urlComponents?.query ?? "")"
            let host = "\(urlComponents?.host ?? "")"
            
            var output = "[REQ:\(abs(taskid) % 100000)] "
            output += """
           \(method) \(path)?\(query) HTTP/1.1 \n
           HOST: \(host)\n
           """
            for (key, value) in request.allHTTPHeaderFields ?? [:] {
                output += "\(key): \(value) \n"
            }
            if let body = request.httpBody {
                output += "\n \(String(data: body, encoding: .utf8) ?? "")"
            }
            
            output += "\n - - - - - - - - - -  END - - - - - - - - - - \n"
            return output
        }()
        
        logger.log("\(message)")
    }
    
    public static func network(response: URLResponse?, data: Data?, error: Error?, taskid: Int = 0) {
        let message = { () -> String in
            let urlString = response?.url?.absoluteString
            let components = NSURLComponents(string: urlString ?? "")
            let path = "\(components?.path ?? "")"
            let query = "\(components?.query ?? "")"
            var output = "[RES:\(abs(taskid) % 100000)] "
    //        if let urlString = urlString {
    //            output += "\(urlString)"
    //            output += "\n\n"
    //        }
            if let response = response as? HTTPURLResponse {
                output += "HTTP \(response.statusCode) \(path)?\(query)\n"
            }
            if let host = components?.host {
                output += "Host: \(host)\n"
            }
            if let response = response as? HTTPURLResponse {
                for (key, value) in response.allHeaderFields {
                    output += "\(key): \(value)\n"
                }
            }
            if let body = data {
                output += "\n\(String(data: body, encoding: .utf8) ?? "")\n"
            }
            if let error {
                output += "\nError: \(error.localizedDescription)\n"
            }
            output += "\n - - - - - - - - - -  END - - - - - - - - - - \n"
            return output
        }()
        
        logger.log("\(message)")
    }
    
    public static func uploadGpx(_ locations: [CLLocation]) async throws -> String {
        
        let wpts = locations.map {
            Waypoint(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                name: nil,
                time: $0.timestamp,
                desc: "{\"speedAccuracy\": \($0.speedAccuracy)}",
                ele: $0.altitude,
                hdop: $0.horizontalAccuracy,
                vdop: $0.verticalAccuracy,
                speed: $0.speed
            )
        }
        
        do {
            let res = try await GpxUploader.shared.uploadGpx(wpts: wpts, location: .localhost)
            logger.log("[GpxUploader] Success, downloadUrl: \(res.downloadUrl)")
            return res.downloadUrl
        } catch {
            logger.log("[GpxUploader] Fail: \(error)")
            throw error
        }
    }
    
    public static func loadTestGpx(gpxUrlString: String) async throws -> [CLLocation] {
        guard let url = URL(string: gpxUrlString) else {
            return []
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let points = GPXParser().parse(data: data)
            logger.log("[GPXParser] Success, count: \(points.count)")
            return points.map { CLLocation($0) }
        } catch {
            logger.log("[GPXParser] Fail: \(error)")
            throw error
        }
    }
    
    public static func loadTestGpx(url: URL) throws -> [CLLocation] {
        let data = try Data(contentsOf: url)
        let points = GPXParser().parse(data: data)
        return points.map { CLLocation($0) }
    }
}
