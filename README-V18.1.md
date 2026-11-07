# The Local Game v18.1

## Install
1. Back up Supabase and keep the previous working Netlify deploy available for rollback.
2. Run `supabase-v18-1-upgrade.sql` in Supabase SQL Editor. It changes only the default for newly created rounds. Existing rounds retain their selection.
3. Upload the contents of this folder to the repository root in GitHub, replacing existing application files. Netlify builds automatically.
4. Test in a NEW round: choose no foursome game, then Beast Ball; enter four scores and verify relative-to-par results. Test incomplete-hole provisional skins and My Round.

## Changes
- Commissioner-only format selection: none, 2 net best balls, 1 gross + 1 net, Beast Ball.
- Beast Ball: best net score, plus bonuses for other players' net scores below par.
- Foursome leaderboard is visible only when a format is enabled.
- Skins are provisional from first entered score; no carryovers. They can change until all scores are entered.
- My Round top row: Gross, Net, Total Active Games. Bottom row: Skins G/N/KP, Profit/Loss.

## Notes
- The v18.1 SQL assumes the v18 `team_stroke_format` column exists.
- No live Supabase test has been performed.
- KP payout remains outside Profit/Loss, as in v18.
- Scores for foursome competitions are calculated for fully entered team holes only.
- Existing rounds with `two-net` retain that setting unless commissioner changes it.
