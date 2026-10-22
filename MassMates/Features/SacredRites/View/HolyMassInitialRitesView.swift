import SwiftUI

struct HolyMassInitialRitesView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xl) {
            initialGreetingSection
            hairlineDivider
            penitentialActSection
            hairlineDivider
            gloriaSection
            hairlineDivider
            collectPrayerSection
        }
    }

    // MARK: - Subviews / Private Helpers
    private var initialGreetingSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Saudação Inicial", posture: .standing)
            ForEach(HolyMassRitesCatalog.initialGreetingTurns) { turn in
                dialogueTurnView(speaker: turn.speaker, text: turn.text, isAssembly: turn.isAssembly)
            }
        }
    }

    private var penitentialActSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
            sectionHeader(title: "Ato Penitencial", subtitle: "Confissão Comunitária")
            confiteorBlock
            ForEach(HolyMassRitesCatalog.kyrieTurns) { turn in
                dialogueTurnView(speaker: turn.speaker, text: turn.text, isAssembly: turn.isAssembly)
            }
        }
    }

    private var confiteorBlock: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text("TODOS")
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text("«Confesso a Deus todo-poderoso e a vós, irmãos e irmãs, que pequei muitas vezes por pensamentos e palavras, atos e omissões, por minha culpa, minha tão grande culpa...»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
        }
    }

    private var gloriaSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader(title: "Glória a Deus nas Alturas", subtitle: "Hino de Louvor")
            Text("«Glória a Deus nas alturas, e paz na terra aos homens por Ele amados. Senhor Deus, Rei dos céus, Deus Pai todo-poderoso: nós vos louvamos, nós vos bendizemos, nós vos adoramos, nós vos glorificamos, nós vos damos graças por vossa imensa glória...»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
        }
    }

    private var collectPrayerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            sectionHeader(title: "Oração da Coleta", subtitle: "Conclusão dos Ritos Iniciais")
            Text("«Ó Deus, cuja providência jamais falha em seus desígnios, afastai de nós todo mal e concedei-nos tudo o que for de proveito para a nossa salvação...»")
                .font(MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
            dialogueTurnView(speaker: "Assembleia", text: "Amém.", isAssembly: true)
        }
    }

    private func dialogueTurnView(speaker: String, text: String, isAssembly: Bool) -> some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xxs) {
            Text(speaker.replacingOccurrences(of: ":", with: "").uppercased())
                .font(MassMatesFont.caption)
                .tracking(0.5)
                .foregroundStyle(MassMatesPalette.textSecondary)
            Text(text)
                .font(isAssembly ? Font.system(size: 19, weight: .semibold, design: .serif) : MassMatesFont.scripture)
                .foregroundStyle(MassMatesPalette.textPrimary)
                .lineSpacing(6)
        }
    }

    private func sectionHeader(title: String, subtitle: String? = nil, posture: LiturgicalPosture? = nil) -> some View {
        HStack {
            Text(title)
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(MassMatesFont.caption)
                    .tracking(0.4)
                    .foregroundStyle(MassMatesPalette.textSecondary)
            }
            if let posture {
                Label(posture.rawValue, systemImage: posture.systemImage)
                    .font(MassMatesFont.caption)
                    .foregroundStyle(MassMatesPalette.textSecondary)
                    .padding(.horizontal, MassMatesSpacing.xs)
                    .padding(.vertical, 2)
                    .background(MassMatesPalette.surfaceMuted)
                    .clipShape(.rect(cornerRadius: MassMatesRadius.chip))
            }
        }
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(MassMatesPalette.line)
            .frame(height: 1)
            .padding(.vertical, MassMatesSpacing.xs)
    }
}

#Preview("Holy Mass Initial Rites — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        HolyMassInitialRitesView()
    }
}
