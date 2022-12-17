// Written in collaboration with chatGPT! But sort of barely...

import Foundation

struct Stop {
    let stopID: String
    let stopName: String
    let stopLat: Double
    let stopLon: Double
    var distanceMiles: Double?
}

struct Trip {
    let routeID: String
    let serviceID: String?
    let tripID: String
}

struct Route {
    let routeID: String
    let routeLongName: String
}
