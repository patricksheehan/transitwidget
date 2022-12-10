import CoreData
import SwiftUI
import WidgetKit

struct NearbyStationView: View {
    @EnvironmentObject var fetcher: TransitDataFetcher
    
    var body: some View {
        VStack {
            Text(fetcher.stationSnapshot.stationName)
            for routeSnapshot in fetcher.stationSnapshot.routeSnapshots {
                HStack {
                    Text(routeSnapshot.routeName)
                    Text(routeSnapshot.departureMinutes)
                }
            }
        }
        .padding()
        .task {
            try? await fetcher.fetchData()
        }
    }
}
