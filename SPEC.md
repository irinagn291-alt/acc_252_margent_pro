# Margent — Build Specification

> Portfolio app 66, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Write a slip at the page you are reading.

| Field | Value |
| --- | --- |
| Product name | Margent |
| Bundle identifier | `com.margent.sheaf` |
| Domain | https://margent-sheaf.pro |
| Contact URL | https://margent-sheaf.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `mgt_` |
| User-Agent | `Margent/1.0 (iOS; +https://margent-sheaf.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Margent -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A reader writes a slip at the current page of a held book.

### 2.1 User flow

1. Tap the empty shelf and set down a book with its page count
2. Open the spine and write a slip on the fused margin sheet at the current page
3. Advance the page playhead and write more slips on that volume
4. Open Quotes to search your own words and mark a slip reread
5. Mark a returned or finished book gone so the spine hollows and the sheaf stays

### 2.2 Essential behaviour

- Shelf of clay spines; drill shelf to book to margin
- One quote-store per volume
- Fused margin sheet writes slip text and currentPage together
- progressFraction equals currentPage divided by totalPages while Held and freezes on Gone
- Verdict is reread or not, no stars
- Gone hollows the spine and freezes the sheaf; slips stay searchable locally
- No store login, no catalog, no ISBN crate

---

## 3. Uniqueness assignment for Margent

| Axis | Assigned value |
| --- | --- |
| Architecture | **Volume ADT fold (Held | Gone); the sheaf is a fold over Slips; Gone hollows the Spine and freezes the store** |
| UI approach | **SwiftUI pure · take bookquotes** |
| Naming convention | **Commonplace / florilegium lexicon** |
| File organization | **By volume role (Volume, Slip, Spine, Sheaf, Hollow)** |
| Dependency strategy | **None** |
| Design direction | **Warm terracotta studio** |
| Typography | **SF Pro** |
| Navigation pattern | **Spine-tab chrome (Shelf, Quotes and Dashboard remain tabs; a spine opens a fused margin sheet that writes the slip and pins currentPage in one commit; Settings arrives as a sheet)** |
| AI art style | **Gouache illustration** |
| Functional twist | **Mark-gone sheaf (Held accepts slips; Gone hollows the spine and freezes the sheaf; reread is a verdict)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — book_quotes

**Core** — A reader writes a slip at the current page of a held book.

**Audience** — Readers who lose marginalia in highlights they never reopen.

**User flow**

1. Tap the empty shelf and set down a book with its page count
2. Open the spine and write a slip on the fused margin sheet at the current page
3. Advance the page playhead and write more slips on that volume
4. Open Quotes to search your own words and mark a slip reread
5. Mark a returned or finished book gone so the spine hollows and the sheaf stays

**Essential features**

- Shelf of clay spines; drill shelf to book to margin
- One quote-store per volume
- Fused margin sheet writes slip text and currentPage together
- progressFraction equals currentPage divided by totalPages while Held and freezes on Gone
- Verdict is reread or not, no stars
- Gone hollows the spine and freezes the sheaf; slips stay searchable locally
- No store login, no catalog, no ISBN crate

**Twist** — Mark-gone sheaf. A volume starts Held. Writing a slip pins it at currentPage and stores it in that book's quote-store. Marking the volume gone — returned, sold, given, or lost — hollows the spine on the shelf and freezes the sheaf. You still open a hollow spine to reread; you do not add slips there. Reread is a yes or no verdict on a slip, not a star. progressFraction is currentPage divided by totalPages while Held, and freezes on Gone. Home verb: write-the-slip, not star-a-book. Dashboard counts gone sheaves and reread slips.

**Why this is not a repeat** — First book_quotes in the ledger. Home is a shelf of spines that drills to a margin, not a genre-island board, not an ISBN crate, not a cyanotype expedition map, not Pugillar's two-hand seam, and not a daily quote card. The verb is write-the-slip on a fused page-and-text sheet; Gone is a Held-to-Gone fold that hollows the spine and freezes the sheaf so quotes outlive the book. Verdict is reread or not. Unique axes architecture, naming, organization, navigation, and twist are newly coined. design Soft card daylight, art Soft 3D clay icons, and screens Tab bar with fused assign take still-free catalog slots. ui reuses SwiftUI pure · take bookquotes. Non-unique axes follow the graph seed: None, SF Pro, UserDefaults+Codable, AVCaptureMetadataOutput, cgi search pl, YYYYMMDD. No food, slots, or barcode. repeats is empty because no unique axis collides.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Shelf of spines. Drill shelf → book → margin.
- Invariant: One quote-store per book. Verdict is reread / not — no stars. progressFraction = currentPage/totalPages.
- Never: Not a store catalog crate.

### 3.1 Architecture contract

Volume is a closed algebraic fold Held | Gone; a third role is a defect. Held carries a live currentPage and an open Sheaf. Gone stores a frozen currentPage, freezes that volume's quote-store, and asks the Spine to render hollow. The Sheaf is a fold over Slip values: reduce by append on write, never by star rating. One quote-store per Volume; UI sends writeSlip and markGone to a single observable store that pattern-matches the role and refuses new slips on Gone. progressFraction equals currentPage divided by totalPages while Held and the stored freeze while Gone; reread is a boolean verdict on a Slip.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

100% SwiftUI. No UIViewRepresentable, no WKWebView, no camera preview. Each of Shelf, Quotes, and Dashboard is a full-bleed paging panel inside TabView; fused margin assign and Settings are .sheet. Draw spine fill, hollow, and progressFraction with Shape and Path, never a star control. The ui axis restates SwiftUI pure under take-token bookquotes: new types and a spine-shelf composition; do not copy the holder app's file tree, type names, or layout.

### 3.3 Naming contract

Convention: Commonplace / florilegium lexicon.

Examples to follow: `Florilegium`, `Sheaf`, `Slip`, `markGone(_:)`

### 3.4 Dependency contract

None. Zero SPM packages; project.yml has no packages: key. No URLSession catalog client and no Open Food Facts. Own-slip lookup is in-process over the sheaf. AVFoundation is not linked; the product does not capture.

### 3.5 Navigation contract

Spine-tab chrome: TabView with three tabs Shelf, Quotes, and Dashboard. Tapping a spine on Shelf presents a fused margin sheet that writes slip text and pins currentPage in one commit. Settings arrives as a sheet from the toolbar, not a fourth tab. Drill is shelf to volume to margin. No ISBN crate and no genre-island board.

### 3.6 Screen composition contract

Paging panels with sheet assign. Physical screens: Shelf, Quotes, Dashboard, Settings. Shelf is the home paging panel of clay spines that drills to a volume; ReviewScreen today. Quotes is the florilegium of your own slips with local filter and reread verdict; ReviewScreen log. Dashboard counts gone sheaves and reread slips. Settings is a sheet with the contact URL; ReviewScreen goals. The fused margin assign is a sheet over Shelf (slip text plus currentPage in one commit), not a tab. Empty Shelf is a full-page empty state with generated art, one headline, one line, and one full-width CTA. No Today, Scan, Search, or Goals screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By volume role (Volume, Slip, Spine, Sheaf, Hollow)**

```
Margent/
  Volume/ Slip/ Spine/ Sheaf/ Hollow/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Shelf
A first-class screen for **Shelf**. Must render empty, populated and error states.

### 5.3 Quotes
A first-class screen for **Quotes**. Must render empty, populated and error states.

### 5.4 Dashboard
A first-class screen for **Dashboard**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Book** — named per this app's convention.
- **Quote** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Warm terracotta studio**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F5F7F9` | Screen background |
| `surface` | `#FEFEFE` | Cards, rows, sheets |
| `ink` | `#1B2637` | Primary text and icons |
| `accent` | `#2265C3` | Primary action, key figure, progress fill |
| `muted` | `#647081` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via .system throughout. Weights carry hierarchy; display never jumps above 34pt. Page numbers, totals, and dashboard counts go through NumberFormatter. Spine titles use .headline; slip body uses .body; muted page pins use .caption.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **16pt** for cards, sheets and primary surfaces; **10pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **shadow** — a single soft drop-shadow token, reused everywhere a surface sits above another.

Primary control: **filled capsule** — the primary CTA is a full-width filled `Capsule`, never a bare text link or a plain `.plain` button.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI pure · take bookquotes**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI pure · take bookquotes** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable root of volumes, sheaves, slips, and verdicts, JSON-encoded in UserDefaults under a single versioned key. Debounced saves during typing; flush when scenePhase becomes inactive or background. Day stamps are Int in YYYYMMDD form. Simulator demo seed behind mgt.demo.v1 runs once and marks onboarding complete; never seed on a device. resetAllData() lives in Settings. Views never touch UserDefaults.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Margent/1.0 (iOS; +https://margent-sheaf.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.books`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.books
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Mark-gone sheaf (Held accepts slips; Gone hollows the spine and freezes the sheaf; reread is a verdict)

A volume starts Held. Writing a slip pins currentPage and stores the text in that volume's quote-store. Marking the volume gone — returned, sold, given, or lost — hollows the spine on the shelf and freezes the sheaf; slips stay searchable locally. A hollow spine still opens for reread; it does not accept new slips. Reread is a yes or no verdict, not a star; the home verb is write-the-slip, and Dashboard counts gone sheaves and reread slips.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Gouache illustration**


Base prompt, reused and extended for every asset:

```
Opaque gouache illustration, loaded brush, matte pigment sitting on paper tooth, still-life studio of clay book spines and paper slips, soft daylight, quiet studio table, no neon, no glassmorphism, no photoreal stock, no 3D chrome, no readable lettering.
```

All 14 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `mgt_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `mgt_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `mgt_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `mgt_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `mgt_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `mgt_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `mgt_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `mgt_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `mgt_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `mgt_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `mgt_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Mark-gone sheaf (Held accepts slips; Gone hollows the spine and freezes the sheaf; reread is a verdict)' feature screen. |
| 11 | `mgt_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `mgt_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |
| 13 | `mgt_HeldSpine` | 1024x1024 | **required cutout** | A solid clay book spine standing on a shelf, gouache cutout, isolated, no plate. |
| 14 | `mgt_HollowSpine` | 1024x1024 | **required cutout** | A hollow clay book spine, empty window through the body, gouache cutout, isolated, no plate. |

### Prompt per asset

**`mgt_AppIcon`** — 1024x1024

```
A single clay book spine with a paper slip tucked into the margin, opaque gouache, subject filling the canvas edge to edge, no text, no rounded-corner plate, no transparency.
```

**`mgt_Splash`** — 1290x2796

```
A quiet vertical still life of a clay-spine shelf receding into a studio, gouache, uncluttered centre band for a wordmark, no text in the paint.
```

**`mgt_Onboarding1`** — 1024x1536

```
A person setting a clay-spine book onto an empty shelf, gouache still life, isolated subject, no text.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_Onboarding2`** — 1024x1536

```
A hand writing a paper slip against a fused margin sheet at the open page, gouache, mid-gesture, no text.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_Onboarding3`** — 1024x1536

```
A hollow clay spine on the shelf beside a tied sheaf of paper slips that remain, gouache, no text.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_EmptyHome`** — 1024x1024

```
An empty clay bookshelf with no spines, waiting, gouache cutout, isolated subject, no plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_EmptyList`** — 1024x1024

```
An empty sheaf string with no slips, gouache cutout, isolated subject, no plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_CardBackdrop`** — 1200x800

```
Opaque gouache illustration, loaded brush, matte pigment sitting on paper tooth, still-life studio of clay book spines and paper slips, soft daylight, quiet studio table, no neon, no glassmorphism, no photoreal stock, no 3D chrome, no readable lettering., an abstract backdrop suitable for sitting behind a card
```

**`mgt_ControlFace`** — 512x512

```
A paper slip and page playhead as one physical control, gouache cutout, isolated, no plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_TwistHero`** — 1024x1024

```
A hollow clay spine with a frozen sheaf of slips beside it, gouache cutout, isolated subject, no plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_SuccessMark`** — 512x512

```
A paper slip settled into a margin, gouache cutout, isolated, no plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_HeaderDecor`** — 1200x600

```
Opaque gouache illustration, loaded brush, matte pigment sitting on paper tooth, still-life studio of clay book spines and paper slips, soft daylight, quiet studio table, no neon, no glassmorphism, no photoreal stock, no 3D chrome, no readable lettering., a wide decorative band or ornament

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_HeldSpine`** — 1024x1024

```
A solid clay book spine standing on a shelf, gouache cutout, isolated, no plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```

**`mgt_HollowSpine`** — 1024x1024

```
A hollow clay book spine, empty window through the body, gouache cutout, isolated, no plate.

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated subject, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`mgt.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `MargentTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Margent -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Volume ADT fold (Held | Gone); the sheaf is a fold over Slips; Gone hollows the Spine and freezes the store** with no leakage across layers.
- [ ] UI approach matches **SwiftUI pure · take bookquotes**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Spine-tab chrome (Shelf, Quotes and Dashboard remain tabs; a spine opens a fused margin sheet that writes the slip and pins currentPage in one commit; Settings arrives as a sheet)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Margent
xcodegen generate
xcodebuild -scheme Margent -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Margent -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
