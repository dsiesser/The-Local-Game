# The Local Game v10 — Open Lobby, Join by Code, Press Alerts

## What changed
- Public home screen with **Start New Game** and **Join Game**; no sign-in gate.
- Players enter the commissioner's round code, select an unclaimed roster name (or add themselves), and enter an Index or choose Not sure.
- A guest Supabase Auth session is created only when a user creates, looks up, or joins a game. No SMTP or email verification.
- Presses are immediately effective; a notification bell shows received press events and unread counts. Supabase Realtime syncs the feed across connected devices.
- Existing v9 live handicap recalculation and group-scoped scoring are retained.

## Deployment
1. Back up your Supabase database.
2. Ensure `supabase-v8.sql` and `supabase-v9-upgrade.sql` have already run successfully.
3. Run **only** `supabase-v10-upgrade.sql` in Supabase SQL Editor. Do not paste `main.jsx` into SQL Editor.
4. Supabase Authentication → Providers → **Anonymous Sign-Ins: enabled**.
5. Replace your GitHub repository files with the contents of this folder (not the enclosing folder); commit. Netlify deploys automatically.
6. Keep existing `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` environment variables.
7. Test on a phone: open site (home should appear without login), tap Join Game, enter an existing code, choose name, confirm Index. In a second device create a Pigeon press and confirm the recipient sees a bell notification.

## Known limitations and safety
- This is an implementation build; production Netlify/Supabase integration has not been verified in your account.
- Guest identity is tied to a browser session. Clearing browser data or switching devices may lose commissioner/player access.
- A shared code allows claiming any unclaimed name; no verified identity. Treat links as private.
- Notifications are **in-app only** (no OS background push). Recipient must have the app open to receive realtime updates, or can open it later to view history.
- Existing game-creation invitation acceptance remains as in v9. Only presses are immediately active.
- If the app is opened with a `?round=...` URL on a new device, use the commissioner-issued `?code=...` invite instead.
