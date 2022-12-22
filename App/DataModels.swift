import CoreLocation
import SwiftCSV
import SQLite3
import SQLite
import Foundation

struct StopArrivals {
    let stopName: String
    var routes: [RouteArrivals]
}

struct RouteArrivals: Identifiable {
    let id = UUID()
    let routeName: String
    var arrivalMinutes: [Int]
}

let GTFS_DB_URL = Bundle.main.path(forResource: "gtfs", ofType: "db")!

class TransitDataFetcher: ObservableObject {
    @Published var departuresMinutes: [String: [Int]] = ["Sample Route": [1, 3, 15]]
    @Published var closestStop: Stop = Stop(stopID: "1", stopName: "Sample Stop", platformIDs: ["blah"], distanceMiles: 1.2)
    
    let gtfsrtUrlString = "https://google.com"
    
    var gtfsDb: OpaquePointer?
    
    enum FetchError: Error {
        case badRequest
        case badJSON
    }
    
    func fetchData() async
    throws  {
        guard let url = URL(string: gtfsrtUrlString) else { return }
        
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FetchError.badRequest }
        
        Task { @MainActor in
            // Get the scheduled trips for the closest stop.
            let now = Date()
            let gtfsDb = try Connection(GTFS_DB_URL, readonly: true)
            let userLocation = CLLocation(latitude: 37.768840, longitude: -122.433270)
            closestStop = getClosestStopSQL(lat: userLocation.coordinate.latitude, lon: userLocation.coordinate.longitude, db: gtfsDb)!
            let activeServiceIDs = getActiveServices(date: now, db: gtfsDb)
            var departures = getScheduledDepartures(stop: closestStop, serviceIDs: activeServiceIDs, date: now, db: gtfsDb)
            let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)
            updateDepartures(stop: closestStop, feedMessage: feedMessage, departures: departures)
            print("hola")
        }
    }
}


func getNoonMinusTwelveHours(date: Date) -> Date {
    let calendar = Calendar.current
    let timeZone = calendar.timeZone
    let localDate = calendar.date(from: calendar.dateComponents(in: timeZone, from: date))!
    let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: localDate)!
    let noonMinus12Hours = calendar.date(byAdding: .hour, value: -12, to: noon)!
    return noonMinus12Hours
}


func dateToGTFSTimestamp(date: Date) -> Int {
    // GTFS timestamps are calculated relative to "noon minus twelve hours" on the service date.
    let noonMinus12Hours = getNoonMinusTwelveHours(date: date)
    let interval = date.timeIntervalSince(noonMinus12Hours)
    return Int(interval)
}


func gtfsTimestampToDate(serviceDate: Date, gtfsTimestamp: Int) -> Date {
    // Given a service date and a GTFS timestamp calcualtes the real timestamp.
    let calendar = Calendar.current
    let noonMinus12Hours = getNoonMinusTwelveHours(date: serviceDate)
    let timestamp = calendar.date(byAdding: .second, value: gtfsTimestamp, to: noonMinus12Hours)!
    
    return timestamp
}


func getScheduledDepartures(stop: Stop, serviceIDs: [String], date: Date, db: Connection) -> [String: [Date]] {
    var tripDepartures: [String: [Date]] = [:]
    do {
        // Get the current timestamp relative to the service day.
        let currentGTFSTimestamp = dateToGTFSTimestamp(date: date)
        
        let serviceIDsBindString = serviceIDs.map{_ in "?"}.joined(separator: ",")
        
        assert(stop.platformIDs.count == 1, "Expecting only one platform per stop")
        
        
        let stop_times = Table("stop_times")
        let trips = Table("trips")
        let tripID = Expression<String>("trip_id")
        let departureTimestamp = Expression<Int>("departure_timestamp")
        let stopID = Expression<String>("stop_id")
        let serviceID = Expression<String>("service_id")
        let query = stop_times.select(stop_times[tripID], departureTimestamp)
            .join(trips, on: stop_times[tripID] == trips[tripID])
            .where(
                stopID == stop.platformIDs[0] &&
                serviceIDs.contains(serviceID) &&
                departureTimestamp >= currentGTFSTimestamp
            )
        
        for row in try db.prepare(query) {
            let tripID = row[tripID]
            let departueGTFSTimestamp = row[departureTimestamp]
            let departueDate = gtfsTimestampToDate(serviceDate: date, gtfsTimestamp: departueGTFSTimestamp)

            if tripDepartures[tripID] != nil {
                tripDepartures[tripID]!.append(departueDate)
            } else {
                tripDepartures[tripID] = [departueDate]
            }
        }
    } catch {
        print("Unable to fetch scheduled departures")
    }
    
    return tripDepartures
}


func getActiveServices(date: Date, db: Connection) -> [String] {
    var serviceIDs: [String] = []
    
    do {
        // Parse the day of the week as a lowercase name (e.g. "monday").
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: date).lowercased()
        
        // Parse the date as an integer in YYYYMMDD format
        formatter.dateFormat = "yyyyMMdd"
        let dateInteger = Int(formatter.string(from: date))!
        
        let query = "SELECT service_id FROM calendar WHERE \(weekday) = 1 AND start_date <= \(dateInteger) AND end_date >= \(dateInteger)"
        for row in try db.prepare(query) {
            serviceIDs.append(row[0] as! String)
        }
    } catch {
        print("Unable to fetch active Services")
    }
    
    return serviceIDs
}


func getClosestStopSQL(lat: Double, lon: Double, db: Connection) -> Stop? {
    // Set up the SQLite statement we'll need
    var query = "SELECT stop_id, stop_lat, stop_lon, stop_name, ((\(lat) - stop_lat) * (\(lat) - stop_lat)) + ((\(lon) - stop_lon) * (\(lon) - stop_lon)) AS distance FROM stops WHERE location_type = 1 ORDER BY distance ASC LIMIT 1"
    do {
        var platformIDs: [String] = []
        let row = try db.prepare(query).next()!
        let id = row[0] as! String
        let distanceMiles = row[4]! as! Double * 0.000621371
        for platformRow in try db.prepare("SELECT stop_id FROM stops WHERE parent_station = \"\(id)\" AND location_type = 0") {
            platformIDs.append(platformRow[0] as! String)
        }
        return Stop(stopID: id, stopName: row[3] as! String, platformIDs: platformIDs, distanceMiles: distanceMiles)
    } catch {
        print("Issue fetching closest stop")
    }
    
    return nil
}


func updateDepartures(stop: Stop, feedMessage: TransitRealtime_FeedMessage, departures: [String: [Date]] ) {
    // Create an empty array to store the routes and arrival times
    var routeArrivalsDict: [String: [Int]] = [String: [Int]]()
    
    // Iterate over the entities in the feed message
    for entity in feedMessage.entity {
        // Check if the entity is a trip update
        if entity.hasTripUpdate {
            let tripUpdate = entity.tripUpdate
            
            // Get the route ID from the trip update
            let routeName = tripIDToRouteName(tripID: tripUpdate.trip.tripID, trips: trips, routes: routes)
            
            if routeName == nil {
                continue
            }
            
            // Iterate over the stop times in the trip update
            for stopTimeUpdate in tripUpdate.stopTimeUpdate {
                // Check if the stop ID matches the one we're looking for
                if stopTimeUpdate.stopID == stop.stopID {
                    print("Found stop match")
                    // Get the arrival time from the stop time update
                    let arrivalTime = stopTimeUpdate.arrival.time
                    
                    // Calculate the number of minutes until the arrival time
                    let arrivalMinutes = Int((Int64(Date().timeIntervalSince1970) - arrivalTime) / 60)
                    
                    // Add the arrival time to the RouteArrivals object
                    if routeArrivalsDict[routeName!] != nil {
                        routeArrivalsDict[routeName!]?.append(arrivalMinutes)
                    } else {
                        routeArrivalsDict[routeName!] = [arrivalMinutes]
                    }
                }
            }
        }
    }
    
    // Return the array of routes and arrival times
    return routeArrivalsDict
}


func tripIDToRouteName(tripID: String, trips: [Trip], routes: [Route]) -> String? {
    var routeID: String? = nil
    var routeName: String? = nil
    
    for trip in trips {
        if trip.tripID == tripID {
            routeID = trip.routeID
            break
        }
    }
    
    for route in routes {
        if route.routeID == routeID {
            routeName = route.routeLongName
            break
        }
    }
    
    return routeName
}



