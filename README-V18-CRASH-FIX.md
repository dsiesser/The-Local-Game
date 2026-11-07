# The Local Game v18 — Startup Crash Fix

Fixes `ReferenceError: toggleCard is not defined`, which caused a white screen immediately after the app loaded. The missing collapsible leaderboard helper is now defined inside `App` and uses the existing `expanded` state and `toggleSection` callback.

## Deploy
1. Extract this ZIP.
2. Upload the application files to the root of your existing GitHub repository, replacing matching files (especially `main.jsx`). Do not upload the containing folder as an extra directory.
3. Commit changes. Netlify will build and publish automatically.
4. On the published site, refresh (Ctrl+Shift+R on desktop). Verify the leaderboard opens and My Round / My Games / All Golfers / Skins expand and collapse.

## Supabase
No SQL change is needed for this specific JavaScript crash. Your prior v18 migration and press notification repair should remain in place.

## Scope
This is a focused startup-crash repair. It does not claim that all v18 game rules have been tested end to end against your live database.
