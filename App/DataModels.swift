import Foundation

struct RouteSnapshot {
    let routeName: String
    let departureMinutes: [Int]
}

struct StationSnapshot {
    let stationName: String
    let routeSnapshots: [RouteSnapshot]
}

var sampleStationSnapshot = StationSnapshot(
    stationName: "16th St. Mission",
    routeSnapshots: [
        RouteSnapshot(routeName: "Richmond", departureMinutes: [1, 15, 35]),
        RouteSnapshot(routeName: "SFO", departureMinutes: [2, 4, 24])
    ]
)

