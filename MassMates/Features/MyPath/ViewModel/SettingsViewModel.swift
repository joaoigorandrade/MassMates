import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Dependencies & State
    private let settingsService: any SettingsAndRemindersManaging
    private let milestonesService: any ProfileMilestonesManaging
    private let notificationService: any LiturgicalNotificationScheduling
    private let biometricService: any DiaryBiometricLocking
    private let onOpenDiaryBackupCallback: @MainActor () -> Void

    private(set) var reminders: [LiturgicalReminderItem] = []
    private(set) var selectedLanguage: AppLanguage
    private(set) var selectedThemeMode: AppThemeMode = .system
    private(set) var isPersonalizedAdConsentEnabled: Bool
    private(set) var isBiometricLockEnabled: Bool
    private(set) var activeAppIcon: SaintAppIconOption
    private(set) var unlockedSaintIcons: Set<SaintAppIconOption>
    private(set) var accountDeletionState: AccountDeletionState = .idle
    private(set) var statusBannerMessage: String?

    // MARK: - Init
    init(
        settingsService: any SettingsAndRemindersManaging = LocalMyPathService(),
        milestonesService: (any ProfileMilestonesManaging)? = nil,
        notificationService: any LiturgicalNotificationScheduling = LocalLiturgicalNotificationService(),
        biometricService: any DiaryBiometricLocking = DefaultSpiritualDiarySecurityService(),
        onOpenDiaryBackup: @escaping @MainActor () -> Void = {}
    ) {
        let resolvedMilestones = milestonesService
            ?? (settingsService as? LocalMyPathService)
            ?? LocalMyPathService()
        self.settingsService = settingsService
        self.milestonesService = resolvedMilestones
        self.notificationService = notificationService
        self.biometricService = biometricService
        self.onOpenDiaryBackupCallback = onOpenDiaryBackup
        self.reminders = settingsService.reminders()
        self.selectedLanguage = settingsService.selectedLanguage()
        self.isPersonalizedAdConsentEnabled = settingsService.isPersonalizedAdConsentEnabled()
        self.isBiometricLockEnabled = biometricService.isBiometricLockEnabled
        let summary = resolvedMilestones.milestonesSummary()
        self.activeAppIcon = summary.activeAppIcon
        self.unlockedSaintIcons = summary.unlockedSaintIcons
    }

    // MARK: - Body / Public API
    func toggleReminder(_ id: String) {
        reminders = settingsService.toggleReminder(id)
        if let toggled = reminders.first(where: { $0.id == id }) {
            Task {
                await notificationService.syncReminderSchedule(toggled)
            }
        }
    }

    func updateReminderTime(_ id: String, timeLabel: String) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        let current = reminders[index]
        reminders[index] = LiturgicalReminderItem(
            id: current.id,
            kind: current.kind,
            title: current.title,
            subtitle: current.subtitle,
            timeLabel: timeLabel,
            isEnabled: current.isEnabled
        )
    }

    func selectLanguage(_ language: AppLanguage) {
        settingsService.setLanguage(language)
        selectedLanguage = settingsService.selectedLanguage()
        statusBannerMessage = "Idioma atualizado para \(language.displayName)."
    }

    func selectThemeMode(_ mode: AppThemeMode) {
        selectedThemeMode = mode
        statusBannerMessage = "Tema atualizado para \(mode.displayName)."
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

    func toggleBiometricLock(_ enabled: Bool) {
        biometricService.setBiometricLockEnabled(enabled)
        isBiometricLockEnabled = biometricService.isBiometricLockEnabled
        statusBannerMessage = enabled ? "Bloqueio biométrico ativado." : "Bloqueio biométrico desativado."
    }

    func requestDiaryBackupExport() {
        onOpenDiaryBackupCallback()
        statusBannerMessage = "Abra o Diário Espiritual para exportar seu arquivo criptografado."
    }

    func signOut() {
        statusBannerMessage = "Sessão encerrada com sucesso."
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
