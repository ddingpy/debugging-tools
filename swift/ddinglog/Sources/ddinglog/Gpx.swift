import Foundation
import CoreLocation

enum GpxUploadLocation {
    
    case localhost
    
    var uriString: String {
        switch self {
        case .localhost:
            return "http://localhost:3206/gpx"
        }
    }
}

struct Waypoint {
    
    public let latitude: Double
    public let longitude: Double
    public let name: String?
    public let time: Date
    public let desc: String?
    public let ele: Double?   // elevation
    public let hdop: Double?  // horizontalAccuracy
    public let vdop: Double?  // verticalAccuracy
    public let speed: Double?
    
    public init (
        latitude: Double,
        longitude: Double,
        name: String?,
        time: Date,
        desc: String?,
        ele: Double?,
        hdop: Double?,
        vdop: Double?,
        speed: Double?
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.time = time
        self.desc = desc
        self.ele = ele
        self.hdop = hdop
        self.vdop = vdop
        self.speed = speed
    }
}

extension CLLocation {
    convenience init(_ wpt: Waypoint) {
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: wpt.latitude, longitude: wpt.longitude),
            altitude: wpt.ele ?? -1,
            horizontalAccuracy: wpt.hdop ?? -1,
            verticalAccuracy: wpt.vdop ?? -1,
            course: -1,
            courseAccuracy: -1,
            speed: wpt.speed ?? -1,
            speedAccuracy: -1,
            timestamp: wpt.time
        )
    }
}

struct UploadGpxResponse: Codable {
    let downloadUrl: String
}

final class GpxUploader: Sendable {
    
    static let shared = GpxUploader()
    
    private init() {}
    
    func uploadGpx(wpts: [Waypoint], location: GpxUploadLocation) async throws -> UploadGpxResponse {
                
        guard let url = URL(string: location.uriString) else {
            throw NSError(domain: "url error", code: 0)
        }

        let xml = GpxXmlMaker(wpts: wpts).xml
        
        // Create the boundary string for multipart form-data
        let boundary = UUID().uuidString

        // Function to create multipart form-data body
        func createBody() -> Data {
            
            var body = Data()
            
            let mimeType = "text/plain" // Set the appropriate MIME type
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"sample.gpx\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            if let fileData = xml.data(using: .utf8) {
                body.append(fileData)
            }
            body.append("\r\n".data(using: .utf8)!)
            
            // End the multipart form-data body
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            return body
        }

        // Create the URLRequest and configure it for a POST request with the appropriate headers
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Create the request body
        let body = createBody()

        // Set the body of the request
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("response: \(response)")
        
        if let dataString = String(data: data, encoding: .utf8) {
            print("dataString: \(dataString)")
        }
            
        let uploadRes = try JSONDecoder().decode(UploadGpxResponse.self, from: data)
        return uploadRes
    }
    
}

struct GpxXmlMaker {
    private var wpts: [Waypoint]
    
    private let createdTime = Date()
    
    init(wpts: [Waypoint]) {
        self.wpts = wpts
    }
    
    func count() -> Int {
        wpts.count
    }
    
    var xml: String {
        var ret = """
<?xml version="1.0" encoding="UTF-8"?>
<gpx>

"""
        wpts.forEach { wpt in
            
            let formatter = ISO8601DateFormatter()
            let timeStr = formatter.string(from: wpt.time)
            
            ret += "    <wpt lat=\"\(wpt.latitude)\" lon=\"\(wpt.longitude)\">\n"
            ret += "        <time>\(timeStr)</time>\n"
            if let name = wpt.name {
                ret += "        <name>\(name)</name>\n"
            }
            if let desc = wpt.desc {
                ret += "        <desc>\(desc)</desc>\n"
            }
            if let ele = wpt.ele {
                ret += "        <ele>\(ele)</ele>\n"
            }
            if let hdop = wpt.hdop {
                ret += "        <hdop>\(hdop)</hdop>\n"
            }
            if let vdop = wpt.vdop {
                ret += "        <vdop>\(vdop)</vdop>\n"
            }
            if let speed = wpt.speed {
                ret += "        <speed>\(speed)</speed>\n"
            }
            ret += "    </wpt>\n"
        }
        ret += "</gpx>\n"
        return ret
    }
}

