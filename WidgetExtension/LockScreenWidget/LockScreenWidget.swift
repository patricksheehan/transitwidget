import SwiftUI
import WidgetKit
import UIKit

struct TransitStatusProvider: TimelineProvider {
    typealias Entry = TransitStatusEntry
    
    var hasFetchedTransitStatus: Bool
    var nearestStationFromServer: String
    var routeTimeMapFromServer: [(String, [Int])]
    
    func placeholder(in context: Context) -> TransitStatusEntry {
        let date = Date()
        let entry: TransitStatusEntry

        if context.isPreview && !hasFetchedTransitStatus {
            entry = TransitStatusEntry(date: date, nearestStation: "16th St. Mission", routeTimeMap: [("Richmond", [1, 22, 45])])
        } else {
            entry = TransitStatusEntry(date: date, nearestStation: nearestStationFromServer, routeTimeMap: routeTimeMapFromServer)
        }
        return entry
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TransitStatusEntry>) -> Void){
        // Create a timeline entry for "now."
        let date = Date()
        let entry = TransitStatusEntry(
            date: date,
            nearestStation: nearestStationFromServer,
            routeTimeMap: routeTimeMapFromServer
        )

        // Create a date that's 15 minutes in the future.
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!

        // Create the timeline with the entry and a reload policy with the date
        // for the next update.
        let timeline = Timeline(
            entries:[entry],
            policy: .after(nextUpdateDate)
        )

        // Call the completion to pass the timeline to WidgetKit.
        completion(timeline)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let date = Date()
        let entry: TransitStatusEntry
        
        if context.isPreview && !hasFetchedTransitStatus {
            entry = TransitStatusEntry(date: date, nearestStation: "16th St. Mission", routeTimeMap: [("Richmond", [1, 22, 45])])
        } else {
            entry = TransitStatusEntry(date: date, nearestStation: nearestStationFromServer, routeTimeMap: routeTimeMapFromServer)
        }
        completion(entry)
    }
}
    
struct TransitStatusEntry: TimelineEntry {
    let date: Date
    let nearestStation: String
    let routeTimeMap: [(String, [Int])]
}

private struct TransitWidgetEntryView: View {
    var entry: TransitStatusProvider.Entry

    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        VStack {
            Text(entry.nearestStation)
        }
    }
}


struct WidgetPreview: PreviewProvider {
    static var previews: some View {
        TransitWidgetEntryView(entry: TransitStatusEntry(date: Date(), nearestStation: "16th St. Mission", routeTimeMap: [("Richmond", [1, 22, 45])]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}


@main
struct TransitWidget: Widget {
    private let kind: String = WidgetKind.lockScreen

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TransitStatusProvider(hasFetchedTransitStatus: true, nearestStationFromServer: "16th", routeTimeMapFromServer: [("Rich", [1, 2])])) { entry in
            TransitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lock Screen Widget")
        .description("A Widget that can be displayed on both the lock screen and the home screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall])
    }
}
