import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Dependencies & State
    private let settingsService: any SettingsAndRemindersManaging
    private let milestonesService: any ProfileMilestonesManaging
    private let onOpenDiaryBackupCallback: @MainActor () -> Void

    private(set) var reminders: [LiturgicalReminderItem] = []
    private(set) var selectedLanguage: AppLanguage
    private(set) var isPersonalizedAdConsentEnabled: Bool
    private(set) var activeAppIcon: SaintAppIconOption
    private(set) var unlockedSaintIcons: Set<SaintAppIconOption>
    private(set) var accountDeletionState: AccountDeletionState = .idle
    private(set) var statusBannerMessage: String?

    // MARK: - Init
    init(
        settingsService: any SettingsAndRemindersManaging = LocalMyPathService(),
        milestonesService: (any ProfileMilestonesManaging)? = nil,
        onOpenDiaryBackup: @escaping @MainActor () -> Void = {}
    ) {
        let resolvedMilestones = milestonesService
            ?? (settingsService as? LocalMyPathService)
            ?? LocalMyPathService()
        self.settingsService = settingsService
        self.milestonesService = resolvedMilestones
        self.onOpenDiaryBackupCallback = onOpenDiaryBackup
        self.reminders = settingsService.reminders()
        self.selectedLanguage = settingsService.selectedLanguage()
        self.isPersonalizedAdConsentEnabled = settingsService.isPersonalizedAdConsentEnabled()
        let summary = resolvedMilestones.milestonesSummary()
        self.activeAppIcon = summary.activeAppIcon
        self.unlockedSaintIcons = summary.unlockedSaintIcons
    }

    // MARK: - Body / Public API
    func toggleReminder(_ id: String) {
        reminders = settingsService.toggleReminder(id)
    }

    func selectLanguage(_ language: AppLanguage) {
        settingsService.setLanguage(language)
        selectedLanguage = settingsService.selectedLanguage()
        statusBannerMessage = "Idioma atualizado para \(language.displayName)."
    }

    func selectOrUnlockAppIcon(_ icon: SaintAppIconOption) {
        let summary = unlockedSaintIcons.contains(icon)
            ? milestonesService.selectAppIcon(icon)
            : milestonesService.unlockSaintAppIconViaRewardedVideo(icon)
        activeAppIcon = summary.activeAppIcon
        unlockedSaintIcons = summary.unlockedSaintIcons
        statusBannerMessage = "Ícone do aplicativo atualizado para \(icon.title)."
    }

    func togglePersonalizedAdConsent(_ enabled: Bool) {
        settingsService.setPersonalizedAdConsent(enabled)
        isPersonalizedAdConsentEnabled = settingsService.isPersonalizedAdConsentEnabled()
    }

    func requestDiaryBackupExport() {
        onOpenDiaryBackupCallback()
        statusBannerMessage = "Abra o Diário Espiritual para exportar seu arquivo criptografado."
    }

    func tapDeleteAccountStep() {
        switch accountDeletionState {
        case .idle:
            accountDeletionState = .awaitingSecondTapConfirmation
        case .awaitingSecondTapConfirmation:
            _ = settingsService.deleteAccountAndLocalData()
            accountDeletionState = .permanentlyDeleted
            statusBannerMessage = "Conta e dados locais apagados permanentemente deste dispositivo."
        case .permanentlyDeleted:
            break
        }
    }

    func cancelAccountDeletion() {
        guard accountDeletionState == .awaitingSecondTapConfirmation else { return }
        accountDeletionState = .idle
    }

    // MARK: - Subviews / Private Helpers
    var enabledRemindersCount: Int {
        reminders.filter(\.isEnabled).count
    }
}
