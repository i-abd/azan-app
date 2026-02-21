import WidgetKit
import SwiftUI
import CoreLocation

// We'll use a standard struct for widget entries
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), nextPrayerName: "Asr", nextPrayerTime: "15:30")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), nextPrayerName: "Asr", nextPrayerTime: "15:30")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // In a real scenario with App Groups, we would read the cached coordinates from UserDefaults(suiteName:)
        // For this free sideloaded version without entitlements setup yet, we mock a timeline or load default
        // The user would need to open the app once a day/week to refresh coordinates if travelling.
        
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, nextPrayerName: "Prayer", nextPrayerTime: "--:--")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: String
}

struct AzanWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Next Prayer")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(entry.nextPrayerName)
                .font(.headline)
            
            Text(entry.nextPrayerTime)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
    }
}

@main
struct AzanWidget: Widget {
    let kind: String = "AzanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AzanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Prayer")
        .description("Shows the countdown to the next prayer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
