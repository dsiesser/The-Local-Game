# The Local Game v18 — On-course update

## Installation (IMPORTANT)
1. **Back up** your Supabase database or at least the `tlg_rounds`, `tlg_players`, `tlg_scores`, and `tlg_games` tables. Keep the existing v17 ZIP available for rollback.
2. In Supabase **SQL Editor**, run `supabase-v18-upgrade.sql` **once**. Confirm success before deploying the new app. Do not rerun older migration scripts.
3. Upload all application files from this folder to the root of the GitHub repository (not the folder itself). Commit changes. Netlify should automatically redeploy.
4. Verify that Netlify still has `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` set.
5. On iPhone, close/reopen the PWA or refresh the browser. If old assets persist, clear the website cache.
6. Test with a NEW game first, then confirm an existing round still opens and scores remain intact.

## Features
- Game code + select any name on roster; no handicap entry or new profile. Works on first and subsequent visits. Commissioner name displayed at bottom of sign-in. The commissioner manages the roster.
- 4-person stroke play per four-golfer group: 2 net best balls, or 1 gross + 1 net by **different** golfers. Scores shown relative to 2× hole par. Commissioner selects the shared format.
- Pigeon matches use low-handicap-relative strokes. +2 vs 10 becomes 0 vs 12.
- Nassau dot totals shown on match cards.
- Gross and net skins do not carry over. Skins listed hole by hole.
- Commissioner can assign an independent KP skin on par-3 holes. KP count appears in My Round.
- Presses require a player on the losing side of the selected original bet or press, and must be at least two points down with an eligible remaining hole. Server checks both Pigeon and Nassau.

## Important limitations / security
- Anyone with the round code can select **any** golfer on that roster. This is deliberate per requirements; sharing the code shares the ability to enter that group's scores. It is **not identity verification**. Keep commissioner PIN separate.
- Existing per-round user identities are preserved. New session-to-player mapping allows returning players to reselect the same name without overwriting their old profile.
- KP is counted as a separate skin, but **KP cash value / skins cash payouts are not configured** in the current app. The Profit/Loss figure still reflects match and dot wagers, not skins or KP cash. Settle skin stakes before adding payouts.
- Team stroke-play is computed from each existing group of exactly four golfers, not separately created teams.
- The package passed static JSX parsing but **not** an npm production build or live Supabase integration test (npm dependencies unavailable offline). Deploy to a staging site if possible.
- SQL migration has not been executed against your actual database. Back up first and report any error before proceeding.
