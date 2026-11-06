# The Local Game v15 — Profit/Loss and Sweep Bonus

## Changes
- Profit/Loss: negative amounts display red as `($5.00)`; positive amounts display green as `$5.00`; zero remains neutral.
- Pigeon and Nassau creation each offer an optional **Enable sweep bonus** checkbox.
- If the same side wins all three ORIGINAL bets (Front, Back, Overall), and all three are complete, the winner earns one additional unit at the match's existing unit value. Ties prevent the sweep; presses do not count toward sweep eligibility.
- Sweep bonus is included in My Round Profit/Loss and match payout calculations.

## Install
1. Back up your current GitHub repository or make a release/tag.
2. Verify Supabase `public.tlg_games` has a `sweep` boolean column (the existing v8 schema includes it). If missing, run `supabase-v15-upgrade.sql` in Supabase SQL Editor.
3. Upload the app files to your existing GitHub repository root, replacing matching files; commit.
4. Wait for Netlify automatic deployment and hard refresh the app.
5. Test both Pigeon and Nassau with sweep enabled and disabled; enter all 18 holes and check the resulting payout.

Note: No changes to completed match records; existing matches keep their saved `sweep` setting.
