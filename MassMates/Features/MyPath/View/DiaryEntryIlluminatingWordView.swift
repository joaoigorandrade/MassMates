import SwiftUI

struct DiaryEntryIlluminatingWordView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @State private var isFullPericopeExpanded = false

    // MARK: - Init
    init() {}

    // MARK: - Body / Public API
    var body: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
            scriptureCard
            if isFullPericopeExpanded {
                fullPericopeBox
            }
            devotionalPhotoCard
        }
    }

    // MARK: - Subviews / Private Helpers
    private var scriptureCard: some View {
        MassMatesCard {
            HStack(spacing: MassMatesSpacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.tint)
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: MassMatesSpacing.sm) {
                    HStack {
                        Label("PALAVRA ILUMINADORA", systemImage: "book.closed")
                            .font(MassMatesFont.caption)
                            .foregroundStyle(theme.tint)
                            .tracking(0.5)
                        Spacer()
                        Button { isFullPericopeExpanded.toggle() } label: {
                            Label("Ver perícope integral", systemImage: "arrow.right")
                                .font(MassMatesFont.caption)
                                .foregroundStyle(MassMatesPalette.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("«Todo aquele que me reconhecer diante dos homens, também o Filho do Homem o reconhecerá diante dos anjos de Deus; mas quem me renegar diante dos homens será renegado diante dos anjos de Deus.»")
                        .font(MassMatesFont.scriptureEmphasis)
                        .foregroundStyle(MassMatesPalette.textPrimary)
                    HStack {
                        Text("São Lucas 12, 8-9").font(MassMatesFont.caption).foregroundStyle(MassMatesPalette.textSecondary)
                        Spacer()
                        Label("Ouvir Evangelho", systemImage: "play.circle").font(MassMatesFont.caption).foregroundStyle(theme.tint)
                    }
                }
            }
        }
    }

    private var fullPericopeBox: some View {
        Text("Evangelho Integral (Lc 12, 8-12): «Naquele tempo, disse Jesus aos seus discípulos: \"Todo aquele que me reconhecer diante dos homens, o Filho do Homem também o reconhecerá diante dos anjos de Deus... porque o Espírito Santo vos ensinará naquela mesma hora o que deveis falar.\"»")
            .font(MassMatesFont.customScripture(size: 16))
            .foregroundStyle(MassMatesPalette.textSecondary)
            .padding(MassMatesSpacing.md)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
    }

    private var devotionalPhotoCard: some View {
        Label("Lugar do recolhimento • Canto de oração matutino", systemImage: "camera.fill")
            .font(MassMatesFont.caption)
            .foregroundStyle(MassMatesPalette.textPrimary)
            .padding(MassMatesSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MassMatesPalette.surfaceMuted)
            .clipShape(.rect(cornerRadius: MassMatesRadius.card))
            .overlay(RoundedRectangle(cornerRadius: MassMatesRadius.card).stroke(MassMatesPalette.line, lineWidth: 1))
    }
}

#Preview("Diary Illuminating Word — 5 Seasons (Light / Dark / AX3)") {
    LiturgicalSeasonPreviewMatrix { _ in
        DiaryEntryIlluminatingWordView()
            .padding()
    }
}
