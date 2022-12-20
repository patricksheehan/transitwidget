import SwiftUI

@main
struct TransitWidget: App {
    @StateObject private var fetcher = TransitDataFetcher()
    
    var body: some Scene {
        return WindowGroup {
            NearbyStationView()
                .environmentObject(fetcher)
        }
    }
}
