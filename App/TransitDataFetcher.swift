import SwiftUI

class TransitDataFetcher: ObservableObject {
    @Published var stationSnapshot = sampleStationSnapshot
    
    let urlString = "http://api.bart.gov/gtfsrt/tripupdate.aspx"
    
    enum FetchError: Error {
        case badRequest
    }

     func fetchData() async
     throws  {
        guard let url = URL(string: urlString) else { return }

        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw FetchError.badRequest }

        Task { @MainActor in
             stationSnapshot = sampleStationSnapshot
        }
    }
}
