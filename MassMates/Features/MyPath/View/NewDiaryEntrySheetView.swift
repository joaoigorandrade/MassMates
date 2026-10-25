import Navigation
import SwiftUI

struct NewDiaryEntrySheetView: View {
    // MARK: - Dependencies & State
    @Environment(\.liturgicalTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @OptionalNavigator<AppRoute> private var navigator
    @State private var selectedPractice: SpiritualPractice = .mentalPrayer
    @State private var reflectionText: String = ""
    @State private var isSaving: Bool = false
    let onSave: (SpiritualPractice, String) async -> Void

    private let availablePractices: [SpiritualPractice] = [
        .mentalPrayer, .rosary, .dailyGospel, .confession, .adoration
    ]

    // MARK: - Init
    init(onSave: @escaping (SpiritualPractice, String) async -> Void) {
        self.onSave = onSave
    }

    // MARK: - Body / Public API
    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: MassMatesSpacing.md) {
                    practicePickerSection
                    editorSection
                    captionNotice
                }
                .padding(.horizontal, MassMatesLayout.screenMargin)
                .padding(.top, MassMatesSpacing.md)
                .padding(.bottom, MassMatesSpacing.xl)
            }
        }
        .background(MassMatesPalette.bg.ignoresSafeArea())
    }

    // MARK: - Subviews / Private Helpers
    private var topBar: some View {
        HStack {
            Button("Cancelar") { dismissModal() }
                .font(MassMatesFont.callout)
                .foregroundStyle(MassMatesPalette.textSecondary)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())

            Spacer()
            Text("Novo Registro")
                .font(MassMatesFont.headline)
                .foregroundStyle(MassMatesPalette.textPrimary)
            Spacer()

            Button("Salvar") { triggerSave() }
                .font(MassMatesFont.headline)
                .foregroundStyle(theme.tint)
                .disabled(trimmedText.isEmpty || isSaving)
                .frame(minHeight: MassMatesLayout.minTapTarget)
                .contentShape(Rectangle())
        }
        .padding(.horizontal, MassMatesLayout.screenMargin)
        .frame(minHeight: MassMatesLayout.minRowHeight)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MassMatesPalette.line).frame(height: 1)
        }
    }

    private var practicePickerSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("PRÁTICA SAGRADA")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MassMatesSpacing.xs) {
                    ForEach(availablePractices, id: \.self) { practice in
                        let isSelected = selectedPractice == practice
                        Button { selectedPractice = practice } label: {
                            Text(practice.title)
                                .font(MassMatesFont.callout)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .padding(.horizontal, MassMatesSpacing.sm)
                                .padding(.vertical, 8)
                                .background(isSelected ? theme.tint : MassMatesPalette.surfaceMuted)
                                .foregroundStyle(isSelected ? theme.onTint : MassMatesPalette.textPrimary)
                                .clipShape(.capsule)
                                .frame(minHeight: MassMatesLayout.minTapTarget)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: MassMatesSpacing.xs) {
            Text("REFLEXÃO E FRUTO DA ORAÇÃO")
                .font(MassMatesFont.caption)
                .foregroundStyle(MassMatesPalette.textSecondary)

            TextEditor(text: $reflectionText)
                .font(MassMatesFont.body)
                .padding(MassMatesSpacing.sm)
                .frame(minHeight: 180)
                .background(MassMatesPalette.surfaceMuted)
                .clipShape(.rect(cornerRadius: MassMatesRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: MassMatesRadius.card)
                        .stroke(MassMatesPalette.line, lineWidth: 1)
                )
        }
    }

    private var captionNotice: some View {
        HStack(spacing: MassMatesSpacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 13))
            Text("Registro estritamente local e protegido por criptografia.")
                .font(MassMatesFont.caption)
        }
        .foregroundStyle(MassMatesPalette.textTertiary)
        .padding(.top, MassMatesSpacing.xs)
    }

    private var trimmedText: String {
        reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func triggerSave() {
        guard !trimmedText.isEmpty else { return }
        isSaving = true
        Task {
            await onSave(selectedPractice, trimmedText)
            dismissModal()
        }
    }

    private func dismissModal() {
        if let navigator {
            navigator.dismiss()
        } else {
            dismiss()
        }
    }
}
