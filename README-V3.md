# The Local Game v3 — installation and changes

## Installation (existing GitHub / Netlify)
This archive is **flat**, matching your repository: `main.jsx`, `engine.js`, `courses.js`, etc. all live at the repository root. Do not upload the ZIP itself; extract it and replace the matching files in GitHub. The simplest reliable way to replace existing files is GitHub Desktop: clone the repository, copy these files into its folder, commit, and push. Netlify will build automatically. No new environment variables or database schema changes are needed.

## Changes
- Combination tees for Indian Canyon, Qualchan, Downriver, and Esmeralda, with published course rating/slope and source links.
- Pigeon now supports any number of independent 1v1 matches, each with presses, unit values and sweep rules. Older single-match saved rounds are migrated in memory; new saves use `pigeonMatches`.
- Score is the home screen and displays quick live match summaries for all Pigeon matches and Canyon Game.
- Canyon team dots are optional in Setup. When enabled, the Score screen offers per-hole Team 1 and Team 2 dot entry, with running totals. Disabled dots contribute $0 to settlement.

## Caution on course ratings
City-published standard tee ratings and third-party combination tee ratings sometimes differ by revision year. Confirm the current rating, slope, tee gender, and par against the USGA National Course Rating Database or current official scorecard before a money game. This is a prototype: hole-by-hole stroke indexes are placeholders until course scorecards are entered.

## Testing
1. Create a round and select each of the four Spokane courses and a combination tee. Verify auto-populated rating/slope.
2. Open Pigeon, add two different matches, set stakes independently, enter scores, and check both match summaries on Score.
3. Enable Canyon Game and Enable team dots in Setup; select four distinct players, then enter per-hole dots in Score. Disable dots and verify they no longer count.
4. Check Netlify Deploy log for build status. Real-time cross-device updates require correctly configured Supabase and policies.
