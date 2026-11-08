# BongoFoodie agent rules (read before every task)
1. Read DESIGN.md first. Use only tokens from mobile/lib/core/theme. No hardcoded
   colors, spacing, radii, shadows or durations.
2. Do exactly what the task says. No unrelated refactors, renames or new packages.
3. Before editing, state the root cause or plan in 5 lines. For bugs, show evidence
   (render tree dump, logs, screenshot), not guesses.
4. Never change business logic, Supabase schema, route paths or provider public APIs
   unless the task explicitly says so.
5. Check pubspec.yaml for exact versions (Flutter, Riverpod, go_router,
   supabase_flutter) and use APIs that exist in those versions. Never invent packages or
   APIs. If unsure, read the package source or docs.
6. No emojis in UI strings or code comments.
7. Every async UI needs loading (skeleton), empty, and error-with-retry states.
8. Tap targets >= 48dp. Text contrast >= 4.5:1. Must survive textScaleFactor 1.3.
   Test at 360x640 and 430x932.
9. Definition of done: dart format, flutter analyze (0 issues), flutter test, run the app
   (emulator or flutter web), check the affected screens, and list what was verified and
   what could NOT be verified. Never claim "verified" for something you did not run.
10. If something is ambiguous, choose the simplest option consistent with DESIGN.md,
    state the assumption, and continue. Ask only if truly blocked.

Any file you touch must have its remaining hardcoded spacing/radii migrated to AppSpace/AppRadius.
