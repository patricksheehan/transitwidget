import CoreData
import SwiftUI
import WidgetKit

struct NearbyStationView: View, Sendable {
    @EnvironmentObject var fetcher: TransitDataFetcher
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(fetcher.closestStop.stopName).font(Font.title)
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
    }
}
