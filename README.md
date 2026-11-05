# The Local Game — v1.0 prototype

Mobile-first React PWA for 2–8 golfers. Features manual Handicap Index, WHS Course Handicap calculation, per-hole gross/net scoring, net stroke leaderboard, Stableford, net skins with carryovers, two-player Nassau, course/hole setup, commissioner controls, and optional Supabase live round synchronization.

## Local test
1. Install Node.js 20+.
2. Run `npm install` then `npm run dev`.
3. Open the printed local URL. Without Supabase credentials, the app runs in local demo mode and saves to browser localStorage.

## Supabase setup
1. Create a Supabase project.
2. In SQL Editor, run `supabase.sql` (read the prototype security warning first).
3. In Project Settings → API, copy the project URL and **publishable/anon key** (never the service-role/secret key).
4. Copy `.env.example` to `.env.local` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
5. Restart `npm run dev`. Click **Share round** to create the shared round and copy its link. Invitees can use the player link to enter scores. Changes synchronize via Supabase Realtime.

## Netlify + GitHub
1. Create a GitHub repository and upload the project files (not `node_modules`, `.env.local`, or `dist`).
2. In Netlify, import the GitHub repository. Build command: `npm run build`; publish directory: `dist`.
3. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in Netlify project environment variables, then redeploy.
4. Open the Netlify URL on a phone and choose Add to Home Screen.

## Scoring rules / limitations
- Course Handicap = round(Handicap Index × Slope / 113 + Course Rating − Par). The same tees and rating are applied to all players in this prototype.
- Handicap strokes allocated using full Course Handicap and stroke index; no separate Playing Handicap allowances or relative match-play handicap adjustments yet.
- Net Stableford: max(0, 2 + hole par − net strokes).
- Net skins: only completed holes with scores from every golfer settle; ties carry forward. Outstanding carryovers are displayed.
- Nassau: two-player net match play, front/back/overall, **without automatic presses**. Nassau requires two players.
- Live leaderboard is updated when scores change; players can have different holes completed, so comparisons are provisional.
- Course data is illustrative. Enter official rating, slope, par and hole stroke indexes before competitive play.
- GHIN indexes are entered manually; no GHIN API integration or verification.
- Offline demo persists locally. Shared rounds require internet; there is no offline conflict-resolution queue.
- Prototype database permissions are deliberately permissive for testing; anyone who knows or guesses a round UUID can modify its scores, and a client could alter commissioner data. Add authentication, membership-based RLS, server-side validation, and audit history before public release.
- `admin` query parameter is a convenience UI control, not secure authorization.
