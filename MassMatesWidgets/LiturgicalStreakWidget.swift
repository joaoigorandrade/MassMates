import SwiftUI
import WidgetKit

struct LiturgicalStreakEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let seasonName: String
    let seasonHex: String
    let saintOfTheDay: String
}

struct LiturgicalStreakProvider: TimelineProvider {
    // MARK: - Dependencies & State
    // MARK: - Init
    // MARK: - Body / Public API
    func placeholder(in context: Context) -> LiturgicalStreakEntry {
        LiturgicalStreakEntry(date: Date(), streakDays: 14, seasonName: "Tempo Comum", seasonHex: "#3F7D58", saintOfTheDay: "Sta. Teresinha")
    }

    func getSnapshot(in context: Context, completion: @escaping (LiturgicalStreakEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiturgicalStreakEntry>) -> Void) {
        let entry = placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    // MARK: - Subviews / Private Helpers
}

struct LiturgicalStreakWidgetView: View {
    let entry: LiturgicalStreakEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(Color(hex: entry.seasonHex)).frame(width: 8, height: 8)
                Text(entry.seasonName.uppercased()).font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "flame.fill").foregroundStyle(.orange)
            }
            Text("\(entry.streakDays) dias").font(.system(size: 24, weight: .bold, design: .rounded))
            Text("Fidelidade em oração").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(entry.saintOfTheDay).font(.caption2).italic().lineLimit(1).foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }
}

struct LiturgicalStreakWidget: Widget {
    let kind: String = "LiturgicalStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiturgicalStreakProvider()) { entry in
            LiturgicalStreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Chama da Fidelidade")
        .description("Acompanhe seus dias fiéis em oração e a liturgia de hoje.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

private extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
