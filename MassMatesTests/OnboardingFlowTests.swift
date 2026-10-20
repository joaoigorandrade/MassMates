import Foundation
import Testing
@testable import MassMates

@MainActor
struct OnboardingFlowTests {
    @Test("Onboarding provides 3 welcome slides and advances cleanly to auth sign-in")
    func welcomeSlidesAndStepProgression() {
        let service = LocalOnboardingService()
        let vm = OnboardingViewModel(readingService: service, completingService: service)

        #expect(vm.slides.count == 3)
        #expect(vm.currentStep == .welcomeSlides)
        #expect(vm.currentSlideIndex == 0)
        #expect(!vm.isOnFinalSlide)

        vm.advanceSlideOrProceedToAuth()
        #expect(vm.currentSlideIndex == 1)
        #expect(vm.currentStep == .welcomeSlides)

        vm.advanceSlideOrProceedToAuth()
        #expect(vm.currentSlideIndex == 2)
        #expect(vm.isOnFinalSlide)

        vm.advanceSlideOrProceedToAuth()
        #expect(vm.currentStep == .authSignIn)
    }

    @Test("One-tap auth sign-in supports Apple, Google, and Email and pre-populates name from email")
    func authSignInProviders() {
        let service = LocalOnboardingService()
        let vm = OnboardingViewModel(readingService: service, completingService: service)

        vm.emailDraft = "clara@paroquia.org"
        vm.signIn(with: .email)

        #expect(vm.authenticatedUserIdentifier == "mm-auth-clara@paroquia.org")
        #expect(vm.userName == "Clara")
        #expect(vm.currentStep == .profileAndRuleSetup)

        vm.signIn(with: .apple)
        #expect(vm.authenticatedUserIdentifier == "mm-auth-clara@paroquia.org")

        vm.emailDraft = ""
        vm.signIn(with: .google)
        #expect(vm.authenticatedUserIdentifier == "mm-auth-google")
    }

    @Test("Profile setup enforces authentication, non-empty name, and local-only diary warning acknowledgement")
    func profileValidationRules() {
        let service = LocalOnboardingService()
        let vm = OnboardingViewModel(
            readingService: service,
            completingService: service,
            initialStep: .profileAndRuleSetup
        )

        vm.proceedToPrivacyConsent()
        #expect(vm.errorMessage == OnboardingValidationError.authenticationRequired.userMessage)
        #expect(vm.currentStep == .profileAndRuleSetup)

        vm.signIn(with: .apple)
        vm.userName = "   "
        vm.proceedToPrivacyConsent()
        #expect(vm.errorMessage == OnboardingValidationError.emptyUserName.userMessage)

        vm.userName = "João Paulo"
        vm.acknowledgedLocalDiaryWarning = false
        vm.proceedToPrivacyConsent()
        #expect(vm.errorMessage == OnboardingValidationError.localDiaryWarningNotAcknowledged.userMessage)
        #expect(vm.currentStep == .profileAndRuleSetup)

        vm.acknowledgedLocalDiaryWarning = true
        vm.proceedToPrivacyConsent()
        #expect(vm.errorMessage == nil)
        #expect(vm.currentStep == .privacyAndAdConsent)
    }

    @Test("Deferring ad-consent until final step completes onboarding and syncs selected RuleOfLifePreset")
    func deferredAdConsentAndRuleOfLifeSync() throws {
        let ruleService = LocalRuleOfLifeService(initialPreset: .essentialDaily)
        let onboardingService = LocalOnboardingService(ruleOfLifeUpdating: ruleService)
        var finishedProfile: OnboardingProfileConfiguration?

        let vm = OnboardingViewModel(
            readingService: onboardingService,
            completingService: onboardingService,
            onOnboardingFinished: { profile in
                finishedProfile = profile
            }
        )

        vm.skipSlidesToAuth()
        #expect(vm.currentStep == .authSignIn)

        vm.signIn(with: .apple)
        vm.userName = "Helena"
        vm.parishOrCity = "Paróquia Santa Teresinha"
        vm.selectedPreset = .asceticLenten
        vm.acknowledgedLocalDiaryWarning = true

        vm.proceedToPrivacyConsent()
        #expect(vm.currentStep == .privacyAndAdConsent)
        #expect(!onboardingService.isOnboardingCompleted())

        let completed = try #require(
            vm.completeOnboardingWithConsent(allowPersonalizedAds: false)
        )
        #expect(onboardingService.isOnboardingCompleted())
        #expect(completed.userName == "Helena")
        #expect(completed.parishOrCity == "Paróquia Santa Teresinha")
        #expect(completed.selectedPreset == .asceticLenten)
        #expect(completed.acknowledgedLocalDiaryWarning)
        #expect(!completed.personalizedAdsConsented)
        #expect(finishedProfile == completed)
        #expect(ruleService.loadTodayProgress().selectedPreset == .asceticLenten)
    }
}
