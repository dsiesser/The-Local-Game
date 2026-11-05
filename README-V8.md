# The Local Game v8 — multiplayer beta

This is a **new authenticated data model**, not an in-place migration of v7 rounds. Your v7 round JSON is not imported. Back up your existing data before switching. This release implements the first working multiplayer beta, not a fully audited wagering or competition platform.

## Install

1. In your existing Supabase project, open **SQL Editor**, paste and run `supabase-v8.sql`. **Do not run the old `supabase.sql`**, which granted anonymous read/write access. If v7's legacy table exists, the new script removes its anonymous policies.
2. In Supabase **Authentication → Providers → Email**, enable email authentication and OTP. In **Authentication → Email Templates**, ensure the email template includes the one-time code (`{{ .Token }}`), rather than only a magic link. Configure production SMTP for dependable delivery and set your Netlify site URL in Supabase Auth URL Configuration.
3. In Netlify, keep `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` set to your project's values. Never put a Supabase service-role key in the app or Netlify VITE variables.
4. Replace your GitHub project with the ZIP's root files (do not upload the ZIP itself). Make sure there is only one `main.jsx`, at repository root. Commit; Netlify should deploy automatically.
5. Sign in with email code, create a round, add golfer names and groups under Setup, then share **Copy link**. Invited golfers verify email and claim their name from the roster.

## Permissions

- **Commissioner:** creates round; adds golfers and edits handicaps, groups and round settings; can score all groups.
- **Player:** can view all round scores, score only their own group, create Pigeon and Canyon Nassau invitations, and see personal games on the leaderboard.
- **Pigeon opponent:** accepts or declines invitation. Games stay pending until accepted.
- **Canyon invitation:** the current beta uses a *single participant's* acceptance to activate a proposed Canyon match. For real-stakes use, implement all-four-player approval before activating; do not assume consent from all players.
- **Game creator:** may add presses to their active game. The server prevents changing game participants and stakes after creation.

## Important limitations

- The live updates use Supabase Realtime Postgres Changes. Enable Realtime for the new tables if needed; the SQL script adds them to the publication. The refresh icon also manually reloads.
- Players must choose their own unclaimed roster name. This is an invite-code possession workflow, not verified name-to-email identity matching; a person with the code could claim another unclaimed golfer slot. For higher-stakes games, send targeted email invitations bound to email addresses.
- The Pigeon/Canyon matching engine and gross/net skins come from v7. Press creation is limited to the match creator. No payment processing, financial settlement authorization, score dispute flow, or anti-cheat audit dashboard is included.
- New rounds use the sample 18-hole par/stroke index until scorecard editing/course selection is implemented in this v8 UI. The course name, rating, and slope can be adjusted by the commissioner. Verify scorecard data before play.
- This package was syntax-parsed with TypeScript JSX and `engine.js` checked with Node. The full Vite production build was **not verified** because npm package installation was unavailable in the environment. Check Netlify's build logs.
