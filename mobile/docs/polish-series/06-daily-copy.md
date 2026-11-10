# Polish 6/15 — daily food stories and quiz copy

## Scope and evidence

Home previously rendered `list.first` (and silently substituted the first demo
story for an empty live result). Quiz selection used `DateTime.now().day % count`,
resetting the sequence at each month boundary. Bundled English copy asserted a
precise street-food origin, world production ranking and flagship-kitchen facts
without evidence. Quiz headings, explanations and copy-code feedback were English
regardless of the selected language.

## Implementation

- Five bundled food stories and three quiz questions now have EN/SW copy in
  `DailyCopy`. Removed unsupported rankings, origin claims, universal recipe rules,
  specific rice provenance and kitchen/AI promotional assertions. Copy describes
  common ingredients and preparations, allowing for recipe variation.
- SW questions/options/explanations preserve question IDs, option order and the
  correct answer index. Locale changes do not reroll a question or answer.
- Full calendar-day rotation uses Dar es Salaam UTC+3 (no daylight saving), sorted
  stable IDs, and a fixed 2024 epoch. Same content set + day produces the same
  selection independent of backend row ordering, restart or device timezone.
  Content additions/removals may change the day's selection; this is not a stored
  server assignment. Duplicate IDs are not a supported catalog contract.
- Mounted Home refreshes at Dar midnight and on app resume; its timer and lifecycle
  observer are disposed. An already-open quiz keeps its question until closed,
  avoiding answer changes mid-task. Next opening selects the current day.
- Only exact bundled discovery ID/title/description matches receive bundled SW
  copy. Live/staff-edited text is not replaced merely because an ID collides.
  Live single-language rows stay in their authored language: no fabricated
  translation, database columns or migrations were introduced.
- Successful empty discovery responses show an honest EN/SW empty message, not
  demo content. Failure shows existing localized error/Retry; skeleton preserved.
- Quiz sheet scrolls at large text/small viewports; heading wraps. Trivia action
  has a 48dp minimum. Existing motion, tokens and routes retained.
- Quiz copy no longer says a correct answer has guaranteed an unlocked discount.
  Correct and incorrect answers both explain the food fact. Existing code-copy
  action remains with a conditions notice. This is NOT a redemption security fix.

## Boundaries and next prompt

Prompt 7 must reconcile server eligibility/attempt dates, ownership, daily limits,
concurrency, practice replay and demo rewards. Existing repository attempt tracking
still uses device-local date and best-effort persistence; this prompt changes
editorial selection, not server authority. Legacy persisted discoveries are treated
as authored content, not silently migrated to new seed wording. No native speaker
or external culinary expert has signed off the wording; it is editorially reviewed
in source, with further human language review welcome.

## Validation

Unit coverage: Dar midnight, year/month/leap-day transitions, reorder/restart/locale
stability, empty/single-item selection, translation identities/answer indices and
staff-ID collision preservation. Widget coverage: 360×640 and 430×932, EN/SW,
light/dark, text scale 1.3, reduced motion, visible story and scrollable quiz opening.
Existing Home, emoji, image and skeleton tests remain in the suite.

Local WASM Dart formatting, theme/spinner/emoji guards and diff check run. Local
Flutter SDK unavailable: no local analyzer/tests/app launch or physical-device,
screen-reader or live Supabase QA. CI results recorded in PR17 after validation.
