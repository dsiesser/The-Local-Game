# The Local Game v18.2 — Reliability Fix

## Installation (in this order)
1. Back up the Supabase database. Keep the previous Netlify deployment for rollback.
2. In **Supabase → SQL Editor**, run ONLY `supabase-v18-2-reliability.sql` for this upgrade. Do not rerun all old migration files. The script preserves all existing rounds, scores and players.
3. Unzip this package and upload the application files to the root of the GitHub repository, replacing existing versions. Commit and wait for Netlify's automatic deploy.
4. On a new device/browser, test: commissioner creates round; commissioner adds roster; player joins by code and name; player creates Pigeon; commissioner creates Nassau; player returns Home and joins another round; player revisits a prior round. Test on both phone and desktop.

## Fixes
- Match insert authorization is evaluated through a `SECURITY DEFINER` function instead of a client-executed RLS policy querying the private `tlg_player_sessions` table. The private table remains inaccessible directly to clients.
- Roster lookup no longer assumes `tlg_players.created_at` exists.
- App home no longer automatically opens the last visited round; explicit invitation URLs still work.
- Home shows recent-round shortcuts on this device, with a clear-shortcuts option. These are local shortcuts, NOT permanent player accounts.
- Home / Start another game clears the previous round's state and local last-round pointer.

## Important limitations
- **No live Supabase integration test was possible.** SQL must be executed in your project before match creation is expected to work.
- Returning guests still use anonymous Supabase authentication. If a device's guest session is lost, join the round again using the code and roster name, or recover commissioner access using the existing PIN. A recent-round shortcut does not grant permission.
- This version does not yet implement permanent accounts, historical cross-device identity, or multi-round tournaments; those are planned for v19.
- The roster-code method lets anyone with the code select a roster name. Do not treat it as verified identity for financial settlements.
- If a new error occurs, capture the exact error and the action that caused it before running further SQL.
