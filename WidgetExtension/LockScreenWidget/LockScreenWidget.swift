import SwiftUI
import WidgetKit
import UIKit

@main
struct TransitWidget: Widget {
    private let kind: String = WidgetKind.lockScreen

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lock Screen Widget")
        .description("A Widget that can be displayed on both the lock screen and the home screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall])
    }
}

struct TransitStatusProvider: TimelineProvider {
    var hasFetchedTransitStatus: Bool
    var nearestStationFromServer: String
    var routeTimeMapFromServer: [(String, [Int])]

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let date = Date()
        let entry: TransitStatusEntry

        if context.isPreview && !hasFetchedTransitStatus {
            entry = TransitStatusEntry(date: date, neartestStation: "16th St. Mission", routeTimeMap: [("Richmond", [1, 22, 45])])
        } else {
            entry = TransitStatusEntry(date: date, nearestStation: nearestStationFromServer, routeTimeMap: routeTimeMapFromServer)
        }
        completion(entry)
}
    
private struct TransitStatusEntry: TimelineEntry {
    let date: Date
    let nearestStation: String
    let routeTimeMap: [(String, [Int])]
}

private struct LockScreenWidgetEntryView: View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        VStack {
            Text("Percent: \(entry.percent)")
                .font(.headline)
            Capsule()
                .foregroundStyle(.secondary)
                .frame(maxWidth: 100)
                .opacity(0.5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .foregroundStyle(.primary)
                        .frame(maxWidth: CGFloat(entry.percent))
                }
        }
    }
}


struct WidgetPreview: PreviewProvider {
    static var previews: some View {
        LockScreenWidgetEntryView(entry: SimpleEntry(date: Date(), percent: 50))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
