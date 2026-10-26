Current Focus: Eliminated all banned navigation APIs across the app and overhauled Onboarding into discrete Navigator screens.
Completed:
- Onboarding: Removed transition navigation; created `OnboardingRoute` and dedicated screens (`OnboardingSlidesScreenView`, `OnboardingAuthScreenView`, `OnboardingProfileScreenView`, `OnboardingRuleScreenView`, `OnboardingConsentScreenView`, `OnboardingCustomizeRuleSheetView`, `OnboardingAdPreferencesSheetView`) using `NavigationStackWrapper(navigator:)`.
- Groups: Replaced raw `.sheet` and raw `NavigationStack` in `GroupFeedPostMediaView` with full-screen lightbox overlay.
- PrayerTimer: Replaced raw `.sheet` in `PrayerTimerModalView` with in-view bottom drawer overlay.
- MyPath: Replaced raw `.sheet` in `SpiritualDiaryModalView` with interactive in-view overlays; removed spurious `navigator.pop()` from subviews.
- RouteHosts: Added proper `navigator.dismiss()` coordination in `AuthenticationCallbackRouteHostView` and `AppRouteHosts+MyPath`; replaced `@unchecked Sendable` on `HostBox<T>`.
- Verification: Clean compilation with zero warnings, 100% of unit tests passing via `make test`.
Next Step: Verify on simulator or device.
Blockers/Quirks:
- Operator secrets pending in Supabase dashboard for production AdMob SSV and APNs.
