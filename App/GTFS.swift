// Written in collaboration with chatGPT! But sort of barely...

import Foundation
import SwiftCSV

protocol GTFSObject {
    static var fileName: String { get }
    init(csvRow: [String: String])
}

struct Stop {
    let stopID: String
    let stopName: String
    let stopLat: Double
    let stopLon: Double
    var distanceMiles: Double?
}

extension Stop: GTFSObject {
    static let fileName = "stops.txt"
    
    init(csvRow: [String: String]) {
        self.stopID = csvRow["stop_id"]!
        self.stopName = csvRow["stop_name"]!
        self.stopLat = Double(csvRow["stop_lat"]!)!
        self.stopLon = Double(csvRow["stop_lon"]!)!
        self.parentStation = csvRow["parent_station"]!
        self.distanceMiles = nil
    }
}

struct Trip: GTFSObject {
    static let fileName = "trips.txt"
    
    let routeID: String
    let serviceID: String?
    let tripID: String
    
    init(csvRow: [String: String]) {
        tripID = csvRow["trip_id"]!
        routeID = csvRow["route_id"]!
        serviceID = csvRow["service_id"]
    }
}

struct Route: GTFSObject {
    static let fileName = "routes.txt"
    
    let routeID: String
    let routeLongName: String
        
    init(csvRow: [String: String]) {
      routeID = csvRow["route_id"]!
      routeLongName = csvRow["route_long_name"]!
    }
}


class GTFS {
    let routes: [Route]
    let stops: [Stop]
    let trips: [Trip]
    
    init(gtfsFolderUrl: URL) {
        func structFromUrl<GTFSType>(gtfsFolderUrl: URL, type: GTFSType.Type) -> [GTFSType] where GTFSType : GTFSObject{
            var returnList: [GTFSType] = []
            let rows = try! NamedCSV(url: gtfsFolderUrl.appendingPathComponent(type.fileName), delimiter: CSVDelimiter.comma, loadColumns: false).rows
            for row in rows {
                returnList.append(type.init(csvRow: row))
            }
            return returnList
        }
        self.stops = structFromUrl(gtfsFolderUrl: gtfsFolderUrl, type: Stop.self)
        self.trips = structFromUrl(gtfsFolderUrl: gtfsFolderUrl, type: Trip.self)
        self.routes = structFromUrl(gtfsFolderUrl: gtfsFolderUrl, type: Route.self)
    }
}
