Current Focus: Fixed broken layouts, clipped views, 403 group auth errors, and bottom tab bar centering.
Completed:
- Tab Bar: Centered floating `+` button by adding missing 4th tab (`sacredRites` "Ritos") and disabled top border hit testing.
- Groups Fallback: Handled unauthenticated/offline PostgREST calls with graceful fallback to `LocalCommunityGroupsService`.
- Today Dashboard: Wrapped view in `ScrollView`, eliminated dead whitespace, and wired "Ver regra ->" to `.ruleOfLife` sheet.
- Meu Caminho Heatmap: Inverted matrix to row-major for 1:1 day label alignment and removed duplicate settings header gear icon.
- Modals & Viewports: Added `ScrollView` to `NewCheckInModalView`, `HolyMassGuideModalView`, `ConfessionPreparationModalView`, `NightlyExamenModalView`, `SpiritualDiaryModalView`, `CreateGroupFormTabView`, and `JoinGroupByCodeTabView`.
- Timer & Completion: Wired `onCompletePractice` callback on timer/rosary completion; paused timer on mode switch; fixed decade meditation card.
- Design System: Replaced hardcoded fonts and colors across views with `MassMatesFont` and `MassMatesPalette` tokens.
- Rebuilt workspace with Tuist and passed 100% of unit tests (99 tests in 26 suites) with zero warnings under Swift 6 strict concurrency.
Next Step: Perform visual verification on iOS Simulator and review live network integration.
Blockers/Quirks:
- Operator secrets and provider configuration pending for AdMob, APNs, and Auth SMTP in Supabase dashboard.
