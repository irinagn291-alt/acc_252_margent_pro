# Margent

Write a slip at the page you are reading.

Margent is a commonplace book for readers who lose marginalia in highlights they never reopen. Home is a shelf of clay spines. Open a held book, pin a line to the page you are on, and keep going. Mark a returned, sold, given, or lost book gone — the spine hollows, the sheaf freezes, and the slips stay searchable on this device. There is no account, no store catalog, and no Game tab.

## Architecture

Volume ADT fold. A `Volume` is Held or Gone — a third role does not compile. Held carries a live `currentPage` and an open `Sheaf`. Gone stores a frozen page, freezes that volume's quote-store, and asks the `Spine` to render hollow. The sheaf is a fold over `Slip` values: reduce by append on write, never by star rating. One quote-store per volume. UI sends `writeSlip` and `markGone` to a single observable `SheafWatch` that pattern-matches the role and refuses new slips on Gone. `progressFraction` is `currentPage / totalPages` while Held and the stored freeze while Gone. Reread is a boolean verdict on a slip.

This pattern fits the product: the home verb is write-the-slip on a fused page-and-text sheet, not star-a-book. A tab plus a list of quotes would be a clone.

Persistence is one Codable florilegium in UserDefaults (`mgt.sheaf.v1`) plus an atomic Application Support file. Views never touch UserDefaults.

## Mark-gone sheaf

This is why a reader would pick Margent. A volume starts Held. Writing a slip pins `currentPage` and stores the text in that book's quote-store. Marking the volume gone — returned, sold, given, or lost — hollows the spine on the shelf and freezes the sheaf. You still open a hollow spine to reread; you do not add slips there. Reread is a yes or no, not a star. Dashboard counts gone sheaves and reread slips.

The hollow spine is visible on home, not buried in Settings. The freeze is persisted. Unit tests cover write, refuse-on-Gone, and the Held | Gone fold.

## Design

Warm terracotta studio. Palette lives in `Assets.xcassets` and is reached only through `StudioInk.Palette`: background `#F5F7F9`, surface `#FEFEFE`, ink `#1B2637`, accent `#2265C3`, muted `#647081`. Type is SF Pro via `Font.system` in a six-step Dynamic Type scale (`StudioInk.Step`). Display never jumps above 34 pt. Spacing unit 8 pt. Card radius 16 pt. Chip radius 10 pt. Elevation is one soft drop shadow. Primary controls are full-width filled capsules.

Navigation is spine-tab chrome: Shelf, Quotes, and Dashboard as tabs. A spine opens a fused margin sheet that writes the slip and pins `currentPage` in one commit. Settings arrives as a sheet.

## Art

Style: gouache illustration.

Base prompt reused for every asset:

```
Opaque gouache illustration, loaded brush, matte pigment sitting on paper tooth, still-life studio of clay book spines and paper slips, soft daylight, quiet studio table, no neon, no glassmorphism, no photoreal stock, no 3D chrome, no readable lettering.
```

| Image set | Prompt |
| --- | --- |
| `mgt_AppIcon` | A single clay book spine with a paper slip tucked into the margin, opaque gouache, subject filling the canvas edge to edge, no text, no rounded-corner plate, no transparency. |
| `mgt_Splash` | A quiet vertical still life of a clay-spine shelf receding into a studio, gouache, uncluttered centre band for a wordmark, no text in the paint. |
| `mgt_Onboarding1` | A person setting a clay-spine book onto an empty shelf, gouache still life, isolated subject, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_Onboarding2` | A hand writing a paper slip against a fused margin sheet at the open page, gouache, mid-gesture, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_Onboarding3` | A hollow clay spine on the shelf beside a tied sheaf of paper slips that remain, gouache, no text. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_EmptyHome` | An empty clay bookshelf with no spines, waiting, gouache cutout, isolated subject, no plate. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_EmptyList` | An empty sheaf string with no slips, gouache cutout, isolated subject, no plate. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_CardBackdrop` | Opaque gouache illustration, loaded brush, matte pigment sitting on paper tooth, still-life studio of clay book spines and paper slips, soft daylight, quiet studio table, no neon, no glassmorphism, no photoreal stock, no 3D chrome, no readable lettering., an abstract backdrop suitable for sitting behind a card |
| `mgt_ControlFace` | A paper slip and page playhead as one physical control, gouache cutout, isolated, no plate. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_TwistHero` | A hollow clay spine with a frozen sheaf of slips beside it, gouache cutout, isolated subject, no plate. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_SuccessMark` | A paper slip settled into a margin, gouache cutout, isolated, no plate. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_HeaderDecor` | Opaque gouache illustration, loaded brush, matte pigment sitting on paper tooth, still-life studio of clay book spines and paper slips, soft daylight, quiet studio table, no neon, no glassmorphism, no photoreal stock, no 3D chrome, no readable lettering., a wide decorative band or ornament. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_HeldSpine` | A solid clay book spine standing on a shelf, gouache cutout, isolated, no plate. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |
| `mgt_HollowSpine` | A hollow clay spine, empty window through the body, gouache cutout, isolated, no plate. HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. |

Assets are generated by the factory `assets.generate` step. This tree ships empty imagesets named as above.

## How this is not a repeat

First `book_quotes` in the ledger. Home is a shelf of clay spines that drills to a fused margin, not a genre-island board, not an ISBN crate, and not a daily quote card. The verb is write-the-slip. Gone is a Held-to-Gone fold that hollows the spine and freezes the sheaf so quotes outlive the book. Verdict is reread or not. No food, slots, barcode, or Game tab.

## Build

```bash
cd Margent
xcodegen generate
xcodebuild -scheme Margent -destination 'generic/platform=iOS Simulator' build-for-testing
xcodebuild -scheme Margent -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.margent.sheaf`. Contact: https://margent-sheaf.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `mgt.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
