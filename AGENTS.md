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
