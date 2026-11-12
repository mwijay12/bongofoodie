# Supabase: switch to the new project (do these once)

The old project `ovdozsryglkljcugdnkz` was **paused**, which is why the app
showed "offline" and quietly fell back to showcase data. The new project is:

```
https://ywmjjdfomjeadcghlpjt.supabase.co
```

Everything that can be done from this side is done. The four steps below need
**your** credentials, so they are yours to run once.

---

## 1. GitHub repository secrets (required)

Flutter CI now **fails** if these are missing, instead of shipping an APK that
silently runs in showcase mode.

Go to **Settings → Secrets and variables → Actions → New repository secret**:

| Name | Value |
|---|---|
| `SUPABASE_URL` | `https://ywmjjdfomjeadcghlpjt.supabase.co` |
| `SUPABASE_ANON_KEY` | the project's publishable key (`sb_publishable_...`) from **Project Settings → API** |
| `SUPABASE_ACCESS_TOKEN` | the `sbp_...` token you created |
| `SUPABASE_PROJECT_REF` | `ywmjjdfomjeadcghlpjt` |
| `SUPABASE_DB_PASSWORD` | the database password of the new project |

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are what the app is compiled with.
The other three are only used by the one-off schema setup.

These are secrets on purpose: this repository is **public**, so a token
committed to a branch would be readable by anyone.

---

## 2. Create the database tables (required)

A brand-new Supabase project has an empty database. Without this step the app
connects, gets an error, and still looks "broken".

1. On GitHub go to **Actions → Supabase database setup → Run workflow**
2. Type `APPLY` in the confirm field and run it.

That pushes `supabase/schema.sql` (68 idempotent statements: profiles, menu,
orders, promotions, RLS policies, storage buckets and the `ping_keepalive`
function) through the Supabase Management API.

If you prefer the dashboard, paste `supabase/schema.sql` into the SQL Editor
and run it. It is safe to run more than once.

---

## 3. Keep-alive (required, then automatic)

**Actions → Supabase Keep-Alive Heartbeat** now runs **every 12 hours**
(05:00 and 17:00 UTC). Each run:

- fails loudly if the secrets above are missing, and
- after pinging, verifies `auth/v1/health` and a real `menu` read return 200.

Supabase pauses free projects after ~7 days of inactivity. Two runs a day gives
~14 chances before that window closes, and the post-ping check catches a paused
project the same day instead of a week later.

Trigger it once manually after step 2 to confirm it is green.

The Vercel cron (`/api/keepalive`, daily at 06:00 UTC) is a second, independent
heartbeat. Its environment variables were updated to the new project.

---

## 4. Nothing to change in the app

No credentials are hardcoded any more. `flutter-ci.yml` reads
`SUPABASE_URL` / `SUPABASE_ANON_KEY` from secrets for both the APK and the
Flutter web build.

---

## What to expect in the app

The connection banner now tells the truth:

| Situation | What the app shows |
|---|---|
| Secrets missing at build time | CI fails — no APK is produced |
| No credentials compiled in | "Showcase mode" — explains live data needs config |
| Credentials present, client failed to start | "Server unavailable" + the real error + Try again |
| Live client, read fell back to cache | "Showing saved data" / "Saved data is out of date" |

Previously every one of these collapsed into "check your connection", which is
why a paused project looked like a network problem.
