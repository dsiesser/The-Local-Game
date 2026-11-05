# The Local Game v9 — invite-and-join beta

## What changed
- Anyone can start a new round and become that round's commissioner.
- No email OTP, SMTP, or Google login. Uses **Supabase anonymous authentication** (a private user session per browser/device).
- Commissioner rosters names and handicap indexes; players join with a link/code, claim a roster name or add themselves, and enter their own index or select **Not sure**.
- New unrostered players start in Group 6; commissioner should move them to their actual group before scoring.
- Commissioner can edit indexes and groups. Client recomputes net scores, skins, and match results from live updated player rows. Gross scores are retained.
- Copy/share invitation, SMS link, email link, and QR code in Setup. QR uses a third-party image service; it receives the invitation URL.

## Install — important order
1. **Back up your Supabase project** before running database changes.
2. If `supabase-v8.sql` has **never** been run, run that file in Supabase SQL Editor first. If already installed, do not rerun unnecessarily.
3. Run `supabase-v9-upgrade.sql` in SQL Editor.
4. Supabase Dashboard → Authentication → Sign In / Providers → **Anonymous Sign-Ins** → Enable. This is not the same as making your database tables publicly writable.
5. Upload/commit the ZIP's **individual app files** to your GitHub repository, overwriting v8 files. Netlify redeploys automatically. Keep `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
6. Test with two browsers/devices: commissioner creates a game and rosters a golfer; second device opens invitation, claims the name, enters index; commissioner changes the index and both screens refresh via Realtime.

## Security and beta limitations
- **Anyone with the invitation code can claim an unclaimed name or add themselves.** No proof of identity. Treat this as a casual-game beta, not an authenticated money settlement system.
- Anonymous sessions are device/browser specific; clearing site data or switching devices can lose commissioner or golfer access. No account recovery yet.
- The commissioner cannot edit a claimed golfer's name with the current v8 editor; index and group remain editable.
- For score permission, the server enforces group membership; a commissioner can score any group. Group 6 is a temporary holding group for self-added players; do not place real groups in Group 6 until assigned.
- **Unknown index is stored as NULL**, not zero. Current v8 scoring engine uses a temporary zero solely to keep gross UI rendering; **net figures for players with unknown indexes are provisional and must not be used for payouts**. Enter all missing indexes before finalizing.
- Rounds already closed cannot be edited without reopening.
- QR uses `api.qrserver.com` to generate the image; it sees the private invitation URL. Replace with locally generated QR if you require no third-party disclosure.
- This build is an updated **beta**, not an audited production wagering platform. No server-side payout finalization or identity recovery.
