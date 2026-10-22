import AppIntents
import SwiftUI
import WidgetKit

struct RuleOfLifeItemData: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String
    let isCompleted: Bool
}

struct RuleOfLifeEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int
    let items: [RuleOfLifeItemData]
}

struct RuleOfLifeProvider: TimelineProvider {
    // MARK: - Dependencies & State
    // MARK: - Init
    // MARK: - Body / Public API
    func placeholder(in context: Context) -> RuleOfLifeEntry {
        RuleOfLifeEntry(
            date: Date(),
            completedCount: 2,
            totalCount: 3,
            items: [
                RuleOfLifeItemData(id: "1", title: "Santo Terço", systemImage: "circle.grid.cross", isCompleted: true),
                RuleOfLifeItemData(id: "2", title: "Evangelho do Dia", systemImage: "book.closed", isCompleted: true),
                RuleOfLifeItemData(id: "3", title: "Oração Mental", systemImage: "sun.horizon.fill", isCompleted: false)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RuleOfLifeEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RuleOfLifeEntry>) -> Void) {
        let entry = placeholder(in: context)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
    // MARK: - Subviews / Private Helpers
}

struct RuleOfLifeWidgetView: View {
    let entry: RuleOfLifeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("REGRA DE VIDA").font(.caption2).fontWeight(.bold).foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.completedCount)/\(entry.totalCount)").font(.caption).fontWeight(.semibold)
            }
            ForEach(entry.items) { item in
                HStack(spacing: 6) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                    Text(item.title).font(.caption).lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
    }
}

struct RuleOfLifeWidget: Widget {
    let kind: String = "RuleOfLifeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RuleOfLifeProvider()) { entry in
            RuleOfLifeWidgetView(entry: entry)
        }
        .configurationDisplayName("Regra de Vida")
        .description("Acompanhe suas orações do dia direto na tela de início.")
        .supportedFamilies([.systemMedium, .systemSmall])
    }
}
