import CoreLocation
import SwiftCSV
import SQLite3
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

let GTFS_DB_URL = Bundle.main.url(forResource: "gtfs", withExtension: ".db")

class TransitDataFetcher: ObservableObject {
    @Published var stopArrivals: [String: [Int]] = ["Sample Route": [1, 3, 15]]
    @Published var closestStop: Stop = Stop(stopID: "1", stopName: "Sample Stop", stopLat: 20.0, stopLon: 20.0, distanceMiles: 1.2)
    
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
            sqlite3_open(GTFS_DB_URL!.path, &gtfsDb)
            let userLocation = CLLocation(latitude: 37.768840, longitude: -122.433270)
            closestStop = getClosestStopSQL(lat: userLocation.coordinate.latitude, lon: userLocation.coordinate.longitude, db: gtfsDb!)!
            let activeServiceIDs = getActiveServices(date: now, db: gtfsDb!)
            let trips = getScheduledDepartures(stop: closestStop, serviceIDs: activeServiceIDs, date: now, db: gtfsDb!)
            
//            let feedMessage = try TransitRealtime_FeedMessage(serializedData: data)
//            stopArrivals = getRtArrivals(stop: closestStop, feedMessage: feedMessage, db: gtfsDb!)
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


func getScheduledDepartures(stop: Stop, serviceIDs: [String], date: Date, db: OpaquePointer) -> [String: [Date]] {
    var tripDepartures: [String: [Date]] = [:]
    
    // Get the current timestamp relative to the service day.
    let currentGTFSTimestamp = dateToGTFSTimestamp(date: date)
    
    let serviceIDsBindString = serviceIDs.map{_ in "?"}.joined(separator: ",")
    
    let query = """
        SELECT st.trip_id, st.departure_timestamp
        FROM stop_times AS st
        INNER JOIN trips AS t ON st.trip_id = t.trip_id
        WHERE st.stop_id = ? AND t.service_id IN (\(serviceIDsBindString)) AND st.departure_timestamp > ?
        """
    var statement: OpaquePointer?
    sqlite3_prepare_v2(db, query, -1, &statement, nil)
    sqlite3_bind_text(statement, 1, stop.stopID, -1, nil)
    for i in 0...serviceIDs.count - 1 {
        sqlite3_bind_text(statement, Int32(i + 1), serviceIDs[i], -1, nil)
    }
    sqlite3_bind_int(statement, Int32(1 + serviceIDs.count), Int32(currentGTFSTimestamp))
    
    
    while sqlite3_step(statement) == SQLITE_ROW {
        let tripID = String(cString: sqlite3_column_text(statement, 0))
        let departueGTFSTimestamp = Int(sqlite3_column_int(statement, 1))
        let departueDate = gtfsTimestampToDate(serviceDate: date, gtfsTimestamp: departueGTFSTimestamp)

        if tripDepartures[tripID] != nil {
            tripDepartures[tripID]!.append(departueDate)
        } else {
            tripDepartures[tripID] = [departueDate]
        }
    }
    
    return tripDepartures
}


func getActiveServices(date: Date, db: OpaquePointer) -> [String] {
    var serviceIDs: [String] = []
    
    // Parse the day of the week as a lowercase name (e.g. "monday").
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "EEEE"
    let weekday = formatter.string(from: date).lowercased()
    
    // Parse the date as an integer in YYYYMMDD format
    formatter.dateFormat = "yyyyMMdd"
    let dateInteger = Int(formatter.string(from: date))!
    
    let query = "SELECT service_id FROM calendar WHERE \(weekday) = 1 AND start_date <= \(dateInteger) AND end_date >= \(dateInteger)"
    var statement: OpaquePointer?
    sqlite3_prepare_v2(db, query, -1, &statement, nil)
    
    while sqlite3_step(statement) == SQLITE_ROW {
        let serviceID = String(cString: sqlite3_column_text(statement, 0))
        serviceIDs.append(serviceID)
    }
    
    return serviceIDs
}


func getClosestStopSQL(lat: Double, lon: Double, db: OpaquePointer) -> Stop? {
  // Set up the SQLite statement we'll need
  let query = "SELECT stop_id, stop_lat, stop_lon, stop_name, ((\(lat) - stop_lat) * (\(lat) - stop_lat)) + ((\(lon) - stop_lon) * (\(lon) - stop_lon)) AS distance FROM stops WHERE parent_station IS NULL ORDER BY distance ASC LIMIT 1"
  var statement: OpaquePointer?
  sqlite3_prepare_v2(db, query, -1, &statement, nil)

  // Bind the parameters and execute the statement
  sqlite3_bind_double(statement, 1, lat)
  sqlite3_bind_double(statement, 2, lon)
  if sqlite3_step(statement) == SQLITE_ROW {
    // Extract the values from the result row
    let id = String(cString: sqlite3_column_text(statement, 0))
    let lat = sqlite3_column_double(statement, 1)
    let lon = sqlite3_column_double(statement, 2)
    let name = String(cString: sqlite3_column_text(statement, 3))
    let distance = sqlite3_column_double(statement, 4)

    // Return the closest stop as a Stop struct
    let distanceMiles = distance * 0.000621371  // convert meters to miles
    return Stop(stopID: id, stopName: name, stopLat: Double(lat), stopLon: Double(lon), distanceMiles: Double(distanceMiles))
  }

  return nil
}


func getRoutesWithArrivalTimes(stop: Stop, feedMessage: TransitRealtime_FeedMessage, trips: [Trip], routes: [Route]) -> [String: [Int]] {
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



