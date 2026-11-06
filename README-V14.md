# The Local Game v14 — Match removal and team dots

1. Supabase > SQL Editor > New query: run `supabase-v14-upgrade.sql`.
2. Upload the application files to GitHub (keep existing Netlify environment variables). Commit.
3. Wait for Netlify deployment and refresh the app.
4. Test removing a Pigeon/Nassau match; it should disappear for all players.
5. Create a Nassau with Enable team dots checked. Open **Score** and move between holes: each hole displays dot inputs labeled with both teams’ players’ **first names**.

Note: dot entries save when leaving the input. The SQL grants match participants permission to update dots. The SQL has not been run on your production database.
