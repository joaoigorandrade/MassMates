Current Focus: Fixed collapsed Daily Gospel modal sheet and verified full scripture text rendering.
Completed:
- NavigationPackage: Made `SelfSizingSheetModifier` opt-in via `.selfSizingSheet` and restored unconstrained standard `.sheet` presentation.
- DailyGospelModalView: Added `.frame(maxWidth: .infinity, maxHeight: .infinity)` to `pagedReadingView` and `readingTabView`.
- AppRouteHosts: Configured `.presentationDetents([.large])` and `.presentationDragIndicator(.visible)` for `DailyGospelRouteHostView`.
- MassMatesTests: Added unit test verifying `AppRoute.dailyGospel` presentation style.
- Verification: Clean compilation with zero warnings, all 83 NavigationPackage tests and 80+ MassMates tests passing.
Next Step: Run on simulator or device to visually verify the Gospel reading sheet presentation.
Blockers/Quirks:
- Operator secrets pending in Supabase dashboard for production AdMob SSV and APNs.
