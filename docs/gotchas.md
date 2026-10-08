# Gotchas

Known traps and surprising behaviors when building UI with DesignKit.

- **DesignKit package** — traps specific to shipping SwiftUI from a Swift package shared by
  several apps (collected while porting Tenra's components).
- **SwiftUI Layout / Code Hygiene** — Tenra's `docs/gotchas.md` (Tenra `74a12c5`), UI-relevant
  sections only. Examples name Tenra screens; the rules are general.

## DesignKit package

- **Memberwise inits are `internal`.** A `public struct` ported from an app keeps compiling
  inside the package, but consumers get "initializer is inaccessible". Every public view needs
  an explicit `public init(...)`, and `body` must be `public var body`. The Gallery is the
  cheapest check: it is a separate module, so a missing `public` fails its build.
- **Protocol requirements in public types must be public** — `var id` (Identifiable),
  `func body(content:)` (ViewModifier), `func body(content:phase:)` (Transition), `==`, `hash(into:)`.
- **Default arguments of public functions may only reference public declarations.** A default
  of `Self.privateConstant` fails to compile; inline the literal or make the constant public.
- **`public` inside a `public extension` is redundant** and warns on every build. Members
  inherit the extension's access; write `public extension View { func x() }`. An extension that
  declares a protocol conformance cannot carry an access modifier at all.
- **Build with Xcode 26 and 27.** Consumers' CI (Dalada) runs Xcode 26 (iOS 26 SDK); Tenra builds
  with Xcode 27. An iOS 27 SDK API behind `#available(iOS 27, *)` still fails to *compile* on
  Xcode 26 — wrap it in `#if compiler(>=6.4)` as well (see `AmbientMotionGate`,
  `swipeActionsContainerIfAvailable`). CI builds on the runner's latest stable Xcode (26.x as
  of October 2026); the `Package on Xcode 27` job adds an Xcode 27 build once the runner image
  has it, and only warns until then.
- **Language mode is per package.** DesignKit compiles in Swift 5 mode even inside Dalada's
  Swift 6 build, and without Tenra's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Code that
  relied on implicit MainActor isolation in Tenra is nonisolated here. Tokens are `nonisolated`
  so nonisolated app code can read them.
- **No app services.** Networking, FX, logos, persistence and settings come through host hooks
  (`DesignKitLogoLoader`, `DesignKitCurrencyConverter`, `DesignKitTheme`). A component that needs
  something else gets a closure/parameter or a new hook — never an app type.
- **Strings resolve in the host app's bundle.** `String(localized: "key")` inside the package
  looks up the *main* bundle, i.e. the app's tables. List new keys in
  [localization-keys.md](localization-keys.md).
- **Package resources use `Bundle.module`** (the Inter fonts in `DesignTokens/Resources`).
  `Bundle.main` from package code is the app's bundle.
- **Gallery project is generated.** `Gallery/Gallery.xcodeproj` comes from `Gallery/project.yml`
  (xcodegen). A new Gallery source file needs `xcodegen generate`; CI regenerates the project
  before building.

## SwiftUI Layout

- **`containerRelativeFrame` wrong container**: Plain `HStack`/`VStack` are NOT qualifying containers — use `GeometryReader` for proportional sizing inside non-lazy containers.
- **`layoutPriority` is not proportional**: Higher priority takes all remaining space first — it's not a ratio.
- **`Task.yield()` for focus timing**: Replace `Task.sleep(nanoseconds:)` focus hacks with `await Task.yield()` inside `.task {}`.
- **Missing struct `}` after Button wrap**: Wrapping a view's body in `Button { }` can absorb the struct's closing brace — verify brace balance.
- **`.task` vs `.onAppear { Task {} }`**: `.task` is automatically cancelled on view removal; unstructured `Task {}` in `.onAppear` is unowned and can fire after dismissal.
- **`Text("localization.key")` renders the raw key**: Always use `Text(String(localized: "some.key"))` for guaranteed localized output.
- **`Task.sleep(nanoseconds:)` → Duration API**: Use `try? await Task.sleep(for: .milliseconds(150))` instead.
- **ForEach identity — never use `UUID()`**: `UUID()` generates a new id every render → spurious animations, sheet dismiss/reopen. Use stable identifiers: name-based id, `"\(name)_\(type.rawValue)"` fallback.
- **Prefer `.searchable(text:placement:.navigationBarDrawer(.always))` over custom TextField**: gives native Cancel for keyboard dismiss + scope/tokens support. Custom search bars in nav stacks typically need manual `@FocusState` + keyboard toolbar that `.searchable` handles for free.
- **Extra toolbar items in `EditSheetContainer`**: container uses `.cancellationAction` (xmark) + `.confirmationAction` (Save). Child views nest `.toolbar { ToolbarItem(placement: .primaryAction) { ... } }` inside the content closure — iOS auto-places `.primaryAction` items LEFT of `.confirmationAction`. Do NOT use `.topBarTrailing` / `.navigationBarTrailing` — they land on the wrong side of Save.
- **Layers under a `.glassEffect` blend with the layers under them.** Since 3.0.0
  `cardStyle()` draws its glass behind the content, so cards are safe; this still applies to
  `.glassEffect` put on a view's content directly. Before 3.0.0, inside `cardStyle()` shapes
  drawn over each other did not simply cover: the glass
  darkens each layer into what is under it in light mode and lightens it in dark. A marker over
  an arc looked translucent, an arc looked darker over its own glow; even two plain overlapping
  circles change colour (measured on snapshots, 2.9.0). `.compositingGroup()` changes nothing.
  `.drawingGroup()` makes the drawing one layer and gives back its exact colours (`HeroHalfGauge`
  does it); pad it for a glow or shadow that reaches outside the frame, and keep platform views
  (`ProgressView`, text fields) out of it: they draw as an error placeholder. Glass behind the
  content (`.background { Color.clear.glassEffect(…) }`) also gives the exact colours.
- **`.contentReveal(isReady:)` only hides via opacity** — it does NOT skip body evaluation, layout, or render. For genuinely deferred rendering of heavy sections (glass cards, PackedCircleIcons, large grids), gate them behind an `if` condition instead.
- **iOS 26 TabView lazy-renders non-active tab content** — verified: `AnalyticsTab.body` and `SettingsTab.body` don't fire on launch when `.home` is selected. Don't worry about non-active tab init being on the launch critical path.
- **`.frame(height:)` doesn't resize a segmented `Picker`** — `Picker(.segmented)` has fixed intrinsic height. Use `.controlSize(.large)` (~36pt) or `.controlSize(.extraLarge)` (~44pt) to match adjacent button heights.
- **`.localizedCapitalized` capitalizes EVERY word** — wrong for date-range strings like `"3 янв – 9 янв"` → `"3 Янв – 9 Янв"`. For first-char-only capitalization: `first.uppercased() + dropFirst()`.
- **Liquid Glass merged button group**: `GlassEffectContainer(spacing: AppSpacing.sm) { HStack(spacing: 0) { Button { … }.buttonStyle(.glass).buttonBorderShape(.circle) } }`. `HStack(spacing: 0)` is intentional — adjacent glass shapes blend into a continuous merged look. For separated round glass buttons use HStack with non-zero spacing.
- **Animated `AngularGradient` border — rotate the gradient, NOT the shape**: Using `.stroke(AngularGradient(...)).rotationEffect(.degrees(t))` tilts the entire stroked rectangle in space (you see a diagonal beam floating around the card). Correct: keep the shape fixed and pass the rotation into the gradient itself via `AngularGradient(gradient:center:angle: .degrees(t))`. The bright spot then travels along the perimeter as time advances. See `BorderBeamModifier`.
- **iOS 26 `Menu` must NOT wrap a whole `UniversalRow`** — `Menu { … } label: { UniversalRow(…) }` collapses *sibling rows in the same `FormSection`* during the menu-open transition (no warning, no crash). Keep `Menu` inside the trailing slot only; see `MenuPickerRow.swift` for the canonical layout.
- **iOS 26 `.glassEffect(...)` is the morph-source for `Picker(.menu)` / `Menu`** — any card that wraps an interactive picker (`Picker(.menu)`, `MenuPickerRow`, etc.) cannot use `cardStyle()` (Liquid Glass). iOS treats the glass-rect as the menu's source view; in a single-row section the glass-rect ≈ row and the entire row visually collapses into the popover at tap. Use `formCardStyle()` (Material on every iOS) instead. The split is canonical in `AppModifiers.swift`: `cardStyle` = display cards, `formCardStyle` = interactive form containers.
- **iOS 26 native `Menu` — accepted limitations.** These are Apple bugs we accept; do NOT try to work around with UIKit bridges (`UITapGestureRecognizer`), `simultaneousGesture`, `onChange`, popovers, or extra modifiers — all were tried in a multi-iteration debugging session and rejected as kostyly. Document state of `MenuPickerRow` on iOS 26.0–26.2:
  1. **Keyboard does NOT dismiss on Menu tap.** `Menu` uses UIControl-level event handling that absorbs touches *before* SwiftUI's gesture chain resolves, so `.simultaneousGesture(TapGesture())` never fires. `DatePicker` gets dismissal for free via sheet presentation; `Menu` does not. Users have to dismiss the keyboard themselves before tapping a picker.
  2. **Open-morph clips mixed-width options.** SwiftUI `Button`s inside `Menu` are converted to `UIMenuItem` at the UIKit layer; SwiftUI `.frame(minWidth:)` modifiers are ignored. Apple's canonical workaround — `Picker` inside `Menu` — gives uniform `UIMenuItem` rendering but the visible morph animation still clips on iOS 26 today.
  3. **`.menuIndicator(.visible)` is ignored when the `Menu` label is a custom `View`** (only works with plain `Text` label). Bake the chevron into the label `HStack` manually with `Image(systemName: "chevron.up.chevron.down")`.
- **iOS 26: a *visible* nav bar always paints a scroll-edge plate over scrolling content.** `.toolbarBackground(.hidden, for: .navigationBar)` does NOT remove it; `.scrollEdgeEffectStyle` only restyles it (`.automatic`/`.soft`/`.hard` — no "off", and `.soft` adds a *more* visible veil); `.searchable` in the nav bar forces the bar opaque, overriding `.hidden`. The plate is invisible over a neutral page (≈ page color) but visible over a colored/glow background. To get a truly transparent bar over color: hide the nav bar (`.toolbar(.hidden, for: .navigationBar)`, render chrome yourself — see welcome onboarding step) OR wrap content in an extra outer `ScrollView` (nesting absorbs the edge effect — see OnboardingCurrencyStep).
- **`.searchable` drawer vs interactive bars below the nav bar (iOS 26/27 hit-testing).** Three stacked findings from HistoryView's filter carousel, all reproduced by `TenraUITests/HistoryFilterUITests` (run them ON DEVICE — every variant passed on 26.2/26.5 Simulators while failing on an iOS 27 device): (1) iOS 26, default collapsible placement: the drawer's reveal gesture rubber-bands and CLAIMS taps over a `.safeAreaInset(.top)` bar while collapsed — chips dead unless scrolled to top. `placement: .navigationBarDrawer(displayMode: .always)` fixes the taps but forces an opaque bar plate and an always-visible field (rejected cosmetically, like `.searchToolbarBehavior(.minimize)` before it — merges input + dismiss into one bubble); on iOS 27 the default drawer additionally never reveals on scroll at all, `.minimize` stopped dismissing after type+erase, and ANY nav-bar `.searchable` forces an opaque scroll-edge plate behind the whole top block (no API removes it). FINAL RESOLUTION (spec 2026-08-26-history-bottom-navigation): History has NOTHING interactive at the top — filters + system search live in the system BOTTOM toolbar (`ToolbarItemGroup(.bottomBar)` + `ToolbarSpacer(.flexible, placement: .bottomBar)` + `DefaultToolbarItem(kind: .search, placement: .bottomBar)` + `.searchable`, tab bar hidden per-destination). Bottom-bar search facts (device-verified): WITHOUT `.searchToolbarBehavior(.minimize)` it renders as a compact inline `SearchField`; WITH `.minimize` (History's choice) it is a prominent loupe-icon Button labeled `Search` that expands into the system SearchField. `.controlSize(.large)` on the content view scales the bottom-bar capsules up to main-tab-bar height. The expanded search's dismiss control is a Button labeled `close` (lowercase), and collapsing keeps a search element in the hierarchy (assert close/keyboard nonexistence, not field nonexistence). Custom search UI is BANNED (user rule). (2) iOS 27, even with `.always`: content in the safe-area-inset band still loses every tap (scrolls deliver, taps don't) — the bar must be a plain VStack sibling ABOVE the list, not a `.safeAreaInset`. (3) iOS 27, even as a VStack sibling: when the bar's own horizontal `ScrollView` is the TOPMOST content view, its frame extends up under the nav bar + drawer and the bar claims every touch in the carousel's whole strip. A small non-scroll view must abut the safe-area edge first — HistoryView's `Color.clear.frame(height: AppSpacing.xs)` spacer is LOAD-BEARING, not cosmetic.
- **Large view body → `unable to type-check this expression in reasonable time`.** Adding one modifier to a long chain (e.g. HistoryView's `Group{}.safeAreaInset.searchable.onChange×8.sheet×3`) trips the compiler budget. Fix: split `body` into `private var` computed sub-views — each type-checks independently, opaque `some View` refs are cheap. Pure compiler issue, not perf.
- **iOS 26 `.searchToolbarBehavior(.minimize)` polish bugs (accepted).** When search expands from the toolbar button, the field + Cancel render in one merged glass capsule (no API to split) and the button↔field collapse is janky. System-rendered, not app-fixable from code; may settle in later betas. Mature alternative is the always-visible drawer (`displayMode: .always`).
- **Conditional `.scrollTransition` / `.matchedTransitionSource` / `.glassEffectID` must use a `ViewModifier` — not `if/else`.** Branching with `if/else { content }` inside `ForEach` splits view identity between the two branches and breaks geometry-tracked transitions when the condition flips (matched-geometry morphs vanish, scrollTransition phases reset). Wrap the modifier in a `ViewModifier` that returns the modified view in one branch and bare `content` in the other. Precedent: `CarouselScrollTransition` in `AccountsCarousel.swift` *(Tenra)*.
- **Generic `View` types can't have `static let` stored properties** — `private static let fooAnimation = …` inside `InsightDetailView<…>` / `GroupedTransactionList<…>` fails with `static stored properties not supported in generic types`. Use a computed `private var foo: Animation { … }`. Related: a reduce-motion token typed `Animation?` (returns `nil`) works with `.animation(_:value:)` but NOT `withAnimation(_)` (needs a concrete `Animation`) — env-gate those sites with `.linear(duration: 0)` instead.
- **Staggered entrance animation** — stagger a multi-element reveal with per-view `.animation(anim.delay(index·step), value: trigger)` + one `@State` flip. NOT a loop mutating a shared `@State [T]` array (delays coalesce into one commit → all animate together) and NOT `DispatchQueue.asyncAfter` timers (re-entrancy/lifecycle risk). Fail-safe to visible (`!animatesOnAppear || reduceMotion`) so offscreen/headless renders aren't blank. Precedent: [`OrbChart.swift`](../Sources/DesignComponents/Charts/OrbChart.swift).
- **`glassEffect(.clear)` swallows low-alpha fills** — a muted track/base element (e.g. `textSecondary.opacity(0.15)` gray) under `glassBar()` renders as fully transparent. Apply Liquid Glass only to solid-filled marks; keep muted tracks glass-free. Bug precedent: HeroMilestoneGauge base row (2026-07).
- **Entrance animations during `.navigationTransition(.zoom)` push make content jump at transition end** — `onAppear`-driven springs/materialize running mid-transition glitch when the zoom settles. Delay entrances past the push (~0.45s); see `entranceDelay` in the Hero* chart components.
- **`DisclosureGroup` clips its content — never put `cardStyle()` cards inside it.** The clip is how it animates the reveal, and on iOS 26 `cardStyle()` is `.glassEffect`, whose glow/shadow renders *outside* the shape bounds — so expanded cards come out with their shadows sliced along the container edge. Use a header `Button` + `if` inside a `VStack` instead (plain opacity transition, no clip), and keep `screenPadding()` on each card rather than on the section container. Precedent: `closedLoansSection` in `LoansListView.swift` *(Tenra)*.
- **A `scrollPosition(id:)` write before the scroll view is measured is DROPPED, but still mutates your `@State`** — after which the state equals the target, every later write is a no-op, and the carousel is permanently desynced from the selection (visible bug: card A centered, card B selected). `onAppear` is *before* measurement, so this hits any carousel whose selection arrives asynchronously (e.g. `TransactionAddModal.task` resolving the suggested account). Fix: own the first alignment in `.onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.width }` — wait for a non-zero container width, then one `DispatchQueue.main.async` tick for the cards to size against it — and gate all other sync paths behind a `hasAlignedInitialScroll` flag so they can't corrupt the state first. Also re-read the selection *inside* the deferred block; capturing it before the hop yields a stale value. Precedent: `AccountSelectorView.swift` *(Tenra)*.

## Code Hygiene

- **Dead code deletion — orphaned call sites**: When deleting a class, grep all `.swift` sources for the class name AND all method names it implemented.
- **`Group {}` in `@ViewBuilder` computed var is unnecessary** — add `@ViewBuilder` and remove `Group`.
- **Don't flag `#Preview` block inconsistencies as production drifts in audits** — distinguish preview-only from production usage when grep'ing.
