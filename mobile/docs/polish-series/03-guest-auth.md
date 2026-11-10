# Polish 3/15 — guest browsing and auth forms

## Changes

- Onboarding Continue as guest completes onboarding and opens Home without calling
  signInDemo or writing a local demo identity. Sign-in/signup also expose guest
  continuation. These actions never clear the cart or sign out an existing user.
- Shared bilingual form keeps sign-in/signup wrappers and existing route paths.
  Editorial ember brand header, themed canvas, token geometry, scrollable layout,
  autofill/keyboard actions and accessible password visibility controls.
- Signup validates name, TZ mobile phone, email and minimum six-character password.
  Sign-in only requires a nonempty password (not a new signup policy). These are
  format checks, not proof of ownership; Supabase remains authoritative.
- Waiting/submitting and reset states disable repeat requests without spinners.
  Errors provide bilingual retry guidance, without displaying raw server details.
- Missing live credentials are explicitly demo/local. Demo role previews are
  secondary and hidden when live credentials are configured. Repository rejects
  showcase login in an initialized live app; live session restoration will not
  fall back to a stored demo profile.
- Live signup with a user but no session raises a typed confirmation-required
  result. Controller stays signed out; form explains email verification and guest
  continuation. Offline signup is explicitly a local demo customer profile.
- Removed email-allowlist role elevation from offline signup/live role fallback.
  Live role comes from profile data, falling back to customer. This is NOT a
  substitute for RLS/authorization of every privileged backend operation.

## Tests and preserved behavior

`auth_guest_test.dart` covers three guest entry points, null identity, no demo
login, onboarding preference and cart preservation; EN/SW sign-in/signup at
360x640 and 430x932 with text scale 1.3 and light/dark; invalid input; typed
confirmation-required handling; offline signup cannot assign admin by email.
Existing system-overlay and onboarding tests remain in place.

No packages, schema changes, payment or checkout behavior changed. The pending
validated customer checkout work belongs to Prompt 11; guest browsing does not
prove guest orders are ready for live operation. No live staff authorization,
OAuth redirect, recovery-link completion or deployed RLS claims are made here.

## Validation limitations

Formatter is dart_style via WASM because local Flutter/Dart SDK is absent.
Local spinner/theme/emoji guards and diff checks are run; remote analyzer/tests/
APK/web outcomes are reported in the PR. Native branding checks remain in CI.
No emulator/web app launch, physical keyboard/autofill/screen-reader review,
real Supabase confirmation mail, password recovery mail, OAuth callback or real
signout/account-switch network test was performed in this sandbox.
