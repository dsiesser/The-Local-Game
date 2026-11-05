# The Local Game v4 — installation and changes

## Install
Extract this ZIP and replace the **files at the root** of your GitHub repository (do not upload the ZIP itself). Commit and push to `main`. Netlify will build automatically.

## Changes
- Course-specific men's par and stroke-index scorecards for Indian Canyon, Qualchan, Downriver and Esmeralda; edit individual holes in Setup. Selecting a course loads its scorecard. Verify against the current physical card; published third-party sources differ in places, especially women's pars and indexes.
- Setup is for real playing groups (two groups, max four players each). The *My scoring group* choice is stored on each device, so two foursomes can score the same round independently.
- Teams tab allows multiple independent Canyon 2v2 matches; Pigeon tab supports multiple 1v1 matches.
- Score is the home tab with live match summaries, gross score entry for your group only, per-hole Canyon dots directly underneath, and gross +/- to par.
- Gross skins replaces net stroke and net Stableford leaderboard options.
- Handicap Index supports plus players entered as negative numbers (-2.3 for a +2.3 index); negative Course Handicap adds strokes on applicable holes.
- Presses are separate zero-start matches from the next hole through the parent Nassau section end.
- Old v3 local round data is read and migrated in memory; v4 saves under `local-game-v4`.

## Important
Netlify production build **not verified** because npm registry access was unavailable in the development environment. `node --check` passed for the JavaScript engine and course scorecards. Test a round before using for wagers. Supabase `rounds` JSON data structure requires no new columns. Current shared links allow score edits without user authentication; commissioner controls are not secure for paid competitions.

## Source scorecards
- Indian Canyon: https://zommagolf.com/courses/wa/indian-canyon-golf-course
- Qualchan: https://18birdies.com/golf-courses/club/b0dba8c0-86ac-11e4-8c28-020000005b00/the-creek-at-qualchan
- Downriver: https://18birdies.com/golf-courses/club/b0dc6c10-86ac-11e4-8c28-020000005b00/downriver-golf-course
- Esmeralda: https://zommagolf.com/courses/wa/esmeralda-golf-course
