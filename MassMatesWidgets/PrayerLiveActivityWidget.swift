import ActivityKit
import SwiftUI
import WidgetKit

struct PrayerLiveActivityWidget: Widget {
    // MARK: - Dependencies & State
    // MARK: - Init
    // MARK: - Body / Public API
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerLiveActivityAttributes.self) { context in
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.title, systemImage: "circle.grid.cross.fill")
                        .font(.caption2).fontWeight(.semibold)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatSeconds(context.state.remainingSeconds))
                        .font(.system(.body, design: .monospaced)).fontWeight(.bold)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.currentBeadLabel).font(.caption).foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "circle.grid.cross.fill").foregroundStyle(.purple)
            } compactTrailing: {
                Text(formatSeconds(context.state.remainingSeconds)).font(.caption2).monospacedDigit()
            } minimal: {
                Image(systemName: "circle.grid.cross.fill")
            }
        }
    }

    // MARK: - Subviews / Private Helpers
    private func lockScreenBanner(context: ActivityViewContext<PrayerLiveActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.grid.cross.fill")
                .font(.title2).foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.title).font(.headline)
                Text(context.state.currentBeadLabel).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatSeconds(context.state.remainingSeconds))
                .font(.system(.title3, design: .monospaced)).fontWeight(.bold)
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
