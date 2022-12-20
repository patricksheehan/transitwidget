import CoreData
import SwiftUI
import WidgetKit

struct NearbyStationView: View, Sendable {
    @EnvironmentObject var fetcher: TransitDataFetcher
    
    var body: some View {
        VStack {
            Text(fetcher.closestStop.stopName)
            ForEach(fetcher.stopArrivals.keys.sorted(), id: \.self) {
                routeName in
                HStack {
                    Text(routeName)
                    Text(fetcher.stopArrivals[routeName]!.map{String($0)}.joined(separator: ","))
                }
            }
        }
        .padding()
        .task {
           try? await fetcher.fetchData()
        }
    }
}
