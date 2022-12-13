// Written in collaboration with chatGPT!
// Lots of non-Dry code here, can deal with it later.

import Foundation
import SwiftCSV

let delimiter = "\",\""

struct Stop {
    let stop_id: String
    let stop_code: String
    let stop_name: String
    let stop_desc: String
    let stop_lat: Double
    let stop_lon: Double
    let zone_id: String
    let plc_url: String
    let location_type: Int
    let parent_station: String
}

extension Stop: Codable {
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(Stop.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

struct Trip {
    let route_id: String
    let service_id: String
    let trip_id: String
    let trip_headsign: String
    let direction_id: String
    let block_id: String
    let shape_id: String
    let trip_load_information: String
    let wheelchair_accessible: String
    let bikes_allowed: String
}

extension Trip: Codable {
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(Trip.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

struct Route {
    let route_id: String
    let route_short_name: String
    let route_long_name: String
    let route_desc: String
    let route_type: Int
    let route_url: String
    let route_color: String
    let route_text_color: String
}

extension Route: Codable {
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(Route.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}
