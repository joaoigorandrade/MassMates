# iOS Engineering Rules (SOLID, Swift 6, Token-Efficient)

## 1. Agent Output & Token Efficiency
- Output ONLY complete, working code or targeted diffs using `// MARK: -` context anchors.
- NO conversational filler ("Here is how this works..."), NO placeholder comments (`// TODO: implement`).
- Write zero comments unless explaining non-obvious algorithmic or concurrency edge cases.
- Do not rewrite unchanged functions when editing existing files.

## 2. Modern Stack, Required Packages & Banned Legacy APIs (Zero Hallucination)
- **Language:** Swift 6.2+ with Strict Concurrency enabled.
- **Required First-Party Packages (MANDATORY):**
  - **Navigation (`https://github.com/joaoigorandrade/NavigationPackage`, module `Navigation`):**
    - ALL app navigation, routing, tab coordination, modal presentation, and deep linking MUST use `Navigation` (`Routable`, `ModalRoute`, `TabRoute`, `URLRoutable`, `Navigator<Route>`, `NavigationStackWrapper`, `NavigationTabView`, `TabBarCoordinator`, `@OptionalNavigator`).
    - BANNED: Raw `NavigationStack`, manual `NavigationPath`, manual `.navigationDestination(for:)`, `NavigationView`, `NavigationLink(destination:)`, or raw `.sheet` / `.fullScreenCover` outside `Navigator`.
  - **Networking (`https://github.com/joaoigorandrade/NetworkingPackage`, modules `Networking` & `NetworkingTestSupport`):**
    - ALL HTTP/API communication and SSE streams MUST use `Networking` (`NetworkClient`, `URLSessionNetworkClient`, `APIRequest`, `HTTPRequest`, `HTTPRequestData`, `HTTPInterceptor`, `NetworkError`, `SSEEventStream`) and `NetworkingTestSupport` (`MockURLSession`) in unit tests.
    - BANNED: Direct `URLSession.shared` calls, raw `URLRequest` construction outside `Networking` abstractions, or third-party HTTP libraries (e.g., Alamofire).
- **State Management:** Use `@Observable` macro (`Observation` framework). Use `@State` for view ownership, `@Bindable` for bindings, and `@Environment` for view-tree injection.
  - BANNED: `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `Combine` (EXCEPT when interfacing directly with `Navigation.Navigator`, which conforms to `ObservableObject`, or bridging legacy C/Obj-C APIs).
- **Concurrency:** Use structured concurrency (`async/await`, `.task {}`, `TaskGroup`, `actor`).
  - BANNED: `DispatchQueue`, `OperationQueue`, completion handlers, `Task.detached` (unless justified), `@unchecked Sendable`.
- **Testing:** Use `Swift Testing` framework (`import Testing`, `@Test`, `#expect`, `#require`).
  - BANNED: `XCTest` for unit tests (use `XCUITest` only for UI automation).
- **Formatting & Styling:** Use `.foregroundStyle()`, `.clipShape(.rect(cornerRadius:))`, `SFSymbols`.
  - BANNED: `.foregroundColor()`, `.cornerRadius()`, `AnyView` (use `@ViewBuilder` or `Group` instead—`AnyView` breaks SwiftUI diffing).

## 3. SOLID Architecture Guidelines
- **Single Responsibility (SRP):**
  - Files MUST NOT exceed 180 lines. Functions MUST NOT exceed 30 lines.
  - Views are strictly declarative (layout + user intent forwarding). Zero business logic, networking, or formatting in `View.body`.
  - Extract complex subviews into private computed properties or dedicated small `View` structs.
- **Open/Closed (OCP):**
  - Prefer composition (`ViewModifier`, `extension`, generic protocol constraints) over inheritance.
  - BANNED: `BaseViewModel` or inheritance hierarchies for Views/ViewModels.
- **Liskov Substitution & Interface Segregation (LSP / ISP):**
  - Define granular, role-specific protocols (1–3 methods max, e.g., `ProfileReading`, `ProfileUpdating`) rather than monolithic repositories.
- **Dependency Inversion (DIP):**
  - ViewModels and Services depend on abstractions (`NetworkClient`, granular protocols, or Sendable Closure Structs) injected via `init`.
  - BANNED: Accessing singletons (`APIClient.shared`, `SupabaseClient.shared`, `URLSession.shared`) directly inside ViewModels or Views. Always inject a default value in `init(service: ServiceProtocol = DefaultService())`.

## 4. Swift 6 Concurrency & Safety Rules
- Annotate all `@Observable` ViewModels and UI-coordinating classes with `@MainActor`.
- Domain models, DTOs, and Errors MUST be immutable `struct` or `enum` conforming to `Sendable` and `Equatable`.
- Never fire raw `Task {}` inside `onAppear`—always use the `.task {}` view modifier for automatic lifecycle cancellation.
- Error Handling: Use typed throws or `do/catch` managing an explicit view state enum (`idle`, `loading`, `loaded(T)`, `error(AppError)`).
- BANNED: Force unwrapping (`!`), force casting (`as!`), and silent `try?` on critical domain operations.

## 5. Reading Pattern & Code Structure
- **Early Returns:** Always use `guard let` / `guard` for preconditions. Maximum indentation depth is 2 levels (no pyramid of doom).
- **Vertical Slicing:** Organize code by feature (`Features/<FeatureName>/View`, `ViewModel`, `Models`) rather than global horizontal folders.
- **Deterministic File Ordering:** Every View and ViewModel must follow this exact `// MARK: -` sequence:
  1. `// MARK: - Dependencies & State`
  2. `// MARK: - Init`
  3. `// MARK: - Body / Public API`
  4. `// MARK: - Subviews / Private Helpers`

## 6. Tuist, Makefile & Token-Efficient Build Protocol (Zero-Error, Zero-Log-Bloat)
- **Single Source of Truth:** `Project.swift`, `Tuist.swift`, and `Makefile` own project configuration and build execution.
  - BANNED: Manually editing `.xcodeproj/project.pbxproj` or `.xcworkspace`, or running raw `xcodebuild` without `-quiet`.
- **When to Generate vs Build (MANDATORY `make` targets):**
  - **After creating, deleting, renaming, or moving any `.swift` file/resource, or editing `Project.swift`:**
    Run `make rebuild` (runs `tuist generate --no-open` + quiet `xcodebuild build`) or `make generate`.
  - **After editing existing, already-indexed `.swift` files only:**
    Run `make build` (skips `tuist generate` for fast incremental compilation with `-quiet`).
  - **To compile unit tests (`MassMatesTests`):**
    Run `make test-build`.
  - **To execute unit tests (Swift Testing on auto-detected Simulator):**
    Run `make test`.

## 7. Persistent Memory Protocol (Zero-Bloat)
Do NOT bloat this file with project history or task plans. Use progressive disclosure via `docs/memory/`:
- **Before starting non-trivial work:** Run `cat docs/memory/STATE.md` and `grep -i "<keyword>" docs/memory/DECISIONS.md` to check active context and past architectural choices.
- **When making an architectural choice or hitting a framework bug:** Append a 1-line entry to `docs/memory/DECISIONS.md` using format: `[YYYY-MM-DD] [Topic]: Decision -> Reason (Why alternatives failed)`.
- **Before ending a session or running `/compact`:** Overwrite `docs/memory/STATE.md` (max 30 lines) with:
  1. `Current Focus:` (1 sentence)
  2. `Completed:` (bulleted file/feature list)
  3. `Next Step:` (exact next action + file path)
  4. `Blockers/Quirks:` (unresolved issues)
- **Exploration Rule:** If you need to inspect >4 files to understand a flow, spawn a subagent to explore and return a <150-word summary to preserve main context tokens.

## 8. Visual Identity & Design System (`docs/plan/visual.md`)
All UI work MUST strictly implement the tokens and specifications in `docs/plan/visual.md` (`Core/DesignSystem`):
- **Principles:** Quiet first (whitespace over dividers/boxes); serif (`New York`) for sacred text/Scripture and sans (`SF Pro`) for UI controls (`SF Pro Rounded` for numerals); liturgical color is a subtle accent tint, never a full-screen background; soft/warm encouragement for streaks (never red/guilt on missed days); ads use the quiet card system and are clearly labeled `"Patrocinado"`.
- **Color Tokens (`Core/DesignSystem`):**
  - **BANNED:** Hard-coding hex values or raw colors in views.
  - **Neutrals (Light / Dark):** `bg` (`#FAF8F5` / `#121110`), `surface` (`#FFFFFF` / `#1B1A18`), `surfaceMuted` (`#F2EFEA` / `#242220`), `line` (`#E7E3DC` / `#33302C`), `textPrimary` (`#1C1B19` / `#F3F0EA`), `textSecondary` (`#6B665E` / `#A9A39A`), `textTertiary` (`#9A948A` / `#7A746B`).
  - **Liturgical Tints (`green`, `purple`, `white` [muted gold], `red`, `rose`):** Each provides `tint`, `tintSoft` (10–14% wash), and `onTint` (`#FFFFFF` light / `#121110` dark). Used ONLY on Today header accent, streak ring, primary button, selected tab icon, progress bars, and small highlights. Always pair color with season name label. Animate season transitions over 400 ms (respecting Reduce Motion).
  - **Functional:** `success` (`#3F7D58` / `#7CC096`), `warning` (`#B7791F` / `#E3B25A`), `danger` (`#B3382E` / `#E5857D` — destructive actions only), `sponsored` (`#6B665E` / `#A9A39A`).
- **Typography & Layout:**
  - **Type Scale:** `display` (New York 34/40 Semibold), `title` (SF Pro 24/30 Semibold), `headline` (SF Pro 17/22 Semibold), `body` (SF Pro 17/24 Regular), `scripture` (New York 19/30 Regular, max measure ≈ 60 chars, never truncated/justified), `scriptureEmphasis` (New York Italic 19/30), `callout` (SF Pro 15/20), `caption` (SF Pro 12/16 Medium), `numeral` (SF Pro Rounded 28/32 Medium). Support Dynamic Type up to AX5.
  - **Spacing & Shape:** 4 pt grid (`4, 8, 12, 16, 24, 32, 48`); screen margins `20` pt (`24` pt and max width `560` pt on iPad for reading/timer); radius: cards `16`, buttons `14`, chips `999`, sheets `24`, proof photos `12`; prefer 1 pt `line` borders over shadows (shadows only on floating `+` button and toasts in light mode); min row height `56` pt, min tap target `44×44` pt.
  - **Sacred Screens (Scripture & Prayer Timer):** Zero ads, banners, or tinted washes.
- **Mandatory Design System Agent Rules:**
  1. Never hard-code hex values in views; use tokens from `Core/DesignSystem`.
  2. Every season color pair MUST have a unit test verifying contrast (≥ 4.5:1 for text, ≥ 3:1 for icons/non-text) against `bg`, `surface`, and `onTint`.
  3. Every UI component MUST include a `#Preview` showing all five liturgical seasons in light, dark, and AX3 Dynamic Type.
  4. Ad views MUST be built strictly from design-system components; never style them ad hoc or place them adjacent to Confession entries.
  5. If a screen requires a token not in `docs/plan/visual.md`, add it to `docs/plan/visual.md` first before using it in code.

## 9. Git & Continuous Delivery Protocol
- **Pre-Commit Verification (MANDATORY):** Never commit broken or untested code. Before staging or committing, verify that both the app and unit tests pass via `make build` (or `make rebuild`) and `make test`.
- **Auto-Commit & Push to `main`:** Once a feature, fix, or task is finished and all tests pass:
  1. Stage all relevant changes (`git add`).
  2. Commit with a concise Conventional Commits message (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
  3. Push directly to `origin main` (`git push origin main`).
- **Clean Working Tree:** Do not leave completed work uncommitted or unpushed at the end of a task. Never commit secrets, temporary scratch files, or build artifacts.
