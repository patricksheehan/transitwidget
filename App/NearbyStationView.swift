import CoreData
import SwiftUI
import WidgetKit

struct NearbyStationView: View, Sendable {
    @EnvironmentObject var fetcher: TransitDataFetcher
    
    var body: some View {
        VStack {
            Text(fetcher.stationSnapshot.stationName)
            ForEach(fetcher.stationSnapshot.routeSnapshots) {
                routeSnapshot in
                HStack {
                    Text(routeSnapshot.routeName)
                    Text(routeSnapshot.departureMinutes.map{String($0)}.joined(separator: ","))
                }
            }
        }
        .padding()
        .task {
            try? await fetcher.fetchData()
        }
    }
}
