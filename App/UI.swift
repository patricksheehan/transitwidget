import CoreData
import SwiftUI
import WidgetKit

struct NearbyStationView: View, Sendable {
    @EnvironmentObject var fetcher: TransitDataFetcher
    
    var body: some View {
        Text(fetcher.closestStop.stopName).font(Font.title)
        Text("(" + String(round(fetcher.closestStop.distanceMiles ?? 0.0)) + " miles)").font(Font.caption)
        List {
            ForEach(fetcher.departuresMinutes.keys.sorted(), id: \.self) {
                routeName in
                HStack{
                    Text(routeName + ":").font(Font.headline)
                    Text(fetcher.departuresMinutes[routeName]!.map{String($0)}.joined(separator: ", "))
                }
            }
        }
        .padding()
        .task {
            try? await fetcher.fetchData()
        }
        .refreshable {
            try? await fetcher.fetchData()
        }
        Text("Last updated: " + (fetcher.lastUpdated ?? "")).font(Font.footnote)
    }
}
