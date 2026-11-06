# The Local Game v16 — My Round and Commissioner Player Selection

## What changed
- Commissioner can select their own golfer in Setup → My player profile or directly in Leaderboard → My Round.
- Selection persists on that device for each round and works alongside commissioner privileges.
- My Round shows a helpful prompt instead of a blank panel when a commissioner has not selected a golfer.
- Gross, net, skins and Profit/Loss display using the selected golfer. No matches gives $0.00.
- Prior match creation, team dots and sweep bonus retained from v15.

## Install
1. Extract this ZIP.
2. Upload the application files (main.jsx, engine.js, courses.js, courseHoles.js, style.css, index.html, etc.) to the root of the existing GitHub repository, replacing same-named files. Do not upload the containing folder itself.
3. Commit and wait for Netlify to deploy.
4. On iPhone, close and reopen the app, refresh the page, and go to Setup → My player profile. Choose your name.
5. Open Leaderboard → My Round to verify scores and Profit/Loss.

No new SQL migration is required for this UI change. Existing Supabase policies must still allow commissioner access.

## Important
The selection is stored on the current device, not as a permanent cross-device player identity. On a new phone, choose your golfer once. It does not modify roster ownership or grant player login credentials.
