# The Local Game v17 — Handicap and match strokes

## Changes
- Leaderboard golfer names display calculated course/playing handicap in parentheses, including plus handicaps.
- Pigeon match cards show the higher-handicap golfer, relative stroke count, and stroke-index holes.
- Nassau match cards show only the higher-handicap golfer on the higher-total-handicap team, using the existing `canyonHandicaps` scoring calculation.
- When strokes exceed 18, each hole is shown once and the additional stroke count is indicated with ×2 or more.
- Missing handicap index shows a pending indicator rather than inventing a number.
- Updates recalculate from round and roster state; no new database columns are needed.

## Deployment
1. Extract the ZIP.
2. Upload/replace the application files in GitHub repository.
3. Commit, wait for Netlify automatic deployment, then reload the app.
4. No new Supabase SQL is needed for these display changes.

## Important
The current engine calculates Course Handicap using Handicap Index, slope, rating, and par. This version displays that calculated number; it does not apply a separate handicap allowance. If you need a different Playing Handicap allowance, that requires an additional scoring-rule change.

The existing Supabase RLS policy issue is independent of this UI update. Verify match creation works with your database policy before testing new match cards.
