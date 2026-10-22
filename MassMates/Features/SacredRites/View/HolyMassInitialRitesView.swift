import SwiftUI

struct HolyMassInitialRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            initialGreetingSection
            hairlineDivider
            penitentialActSection
            hairlineDivider
            collectPrayerSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var initialGreetingSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            rubricText("O SACERDOTE SAÚDA O POVO")
            dialogueRow(speaker: "S.", text: "O Senhor esteja convosco.", isAssembly: false)
            dialogueRow(speaker: "T.", text: "Ele está no meio de nós.", isAssembly: true)
        }
    }

    private var penitentialActSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            rubricText("ATO PENITENCIAL")
            Text("Irmãos, reconheçamos os nossos pecados...")
                .font(MassMatesFont.callout)
                .italic()
                .foregroundStyle(MassMatesPalette.textSecondary)
            kyrieDialogues
        }
    }

    private var kyrieDialogues: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            dialogueRow(speaker: "S.", text: "Senhor, tende piedade de nós.", isAssembly: false)
            dialogueRow(speaker: "T.", text: "Senhor, tende piedade de nós.", isAssembly: true)
            dialogueRow(speaker: "S.", text: "Cristo, tende piedade de nós.", isAssembly: false)
            dialogueRow(speaker: "T.", text: "Cristo, tende piedade de nós.", isAssembly: true)
            dialogueRow(speaker: "S.", text: "Senhor, tende piedade de nós.", isAssembly: false)
            dialogueRow(speaker: "T.", text: "Senhor, tende piedade de nós.", isAssembly: true)
        }
    }

    private var collectPrayerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            rubricText("ORAÇÃO DA COLETA")
            Text("«Ó Deus, cuja providência jamais falha, concedei-nos tudo o que for de proveito para a nossa salvação.»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(3)
            dialogueRow(speaker: "T.", text: "Amém.", isAssembly: true)
        }
    }

    private func dialogueRow(speaker: String, text: String, isAssembly: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MassMatesSpacing.xs) {
            Text(speaker)
                .font(MassMatesFont.scripture)
                .fontWeight(.bold)
                .foregroundStyle(isAssembly ? theme.tint : MassMatesPalette.textSecondary)
                .frame(width: 22, alignment: .leading)
            Text(text)
                .font(MassMatesFont.scripture)
                .fontWeight(isAssembly ? .semibold : .regular)
                .foregroundStyle(MassMatesPalette.textPrimary)
        }
    }

    private func rubricText(_ text: String) -> some View {
        Text(text)
            .font(MassMatesFont.caption)
            .fontWeight(.semibold)
            .tracking(0.8)
            .foregroundStyle(MassMatesPalette.danger)
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
            .padding(.vertical, MassMatesSpacing.xxs)
    }
}

#Preview("Holy Mass Initial Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassInitialRitesView()
    }
}
