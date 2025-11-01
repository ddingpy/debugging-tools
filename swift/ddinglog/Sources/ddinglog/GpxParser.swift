import Foundation
import CoreLocation

// GPXParser class
final class GPXParser: NSObject, XMLParserDelegate {
    
    private var waypoints: [Waypoint] = []
    private var currentElement: String = ""
    private var currentLatitude: Double = 0.0
    private var currentLongitude: Double = 0.0
    private var currentName: String?
    private var currentTime: Date?
    private var currentDesc: String?
    private var currentEle: Double?
    private var currentHdop: Double?
    private var currentVdop: Double?
    private var currentSpeed: Double?
    
    private var isParsingWpt: Bool = false
    
    private let defaultDate = Date()
    
    func parse(data: Data) -> [Waypoint] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() {
            return waypoints
        } else {
            return []
        }
    }
    
    // XMLParserDelegate Methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "wpt" {
            if let latString = attributeDict["lat"], let lonString = attributeDict["lon"],
               let lat = Double(latString), let lon = Double(lonString) {
                currentLatitude = lat
                currentLongitude = lon
                isParsingWpt = true
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isParsingWpt else {
            return
        }
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        switch currentElement {
        case "name" where currentName == nil:
            currentName = value
        case "time" where currentTime == nil:
            let dateFormatter = ISO8601DateFormatter()
            currentTime = dateFormatter.date(from: value)
        case "desc" where currentDesc == nil:
            currentDesc = value
        case "ele" where currentEle == nil:
            currentEle = Double(value)
        case "hdop" where currentHdop == nil:
            currentHdop = Double(value)
        case "vdop" where currentVdop == nil:
            currentVdop = Double(value)
        case "speed" where currentSpeed == nil:
            currentSpeed = Double(value)
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
//        print("!! elementName: \(elementName), currentTime: \(currentTime), currentHdop: \(currentHdop)")
        
        if elementName == "wpt" {
            
            let waypoint = Waypoint(
                latitude: currentLatitude,
                longitude: currentLongitude,
                name: currentName,
                time: currentTime ?? defaultDate,
                desc: currentDesc,
                ele: currentEle,
                hdop: currentHdop,
                vdop: currentVdop,
                speed: currentSpeed
            )
            waypoints.append(waypoint)
            resetCurrentWaypointData()
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parse error: \(parseError.localizedDescription)")
    }
    
    private func resetCurrentWaypointData() {
        currentLatitude = 0.0
        currentLongitude = 0.0
        currentName = nil
        currentTime = nil
        currentDesc = nil
        currentEle = nil
        currentHdop = nil
        currentVdop = nil
        currentSpeed = nil
        isParsingWpt = false
    }
}
