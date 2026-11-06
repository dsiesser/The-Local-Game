# The Local Game v11

Features: automatic refresh of matches every 5 seconds while app is visible (with existing Supabase Realtime subscription), immediate-active Pigeon/Nassau matches, commissioner/creator match removal, collapsible leaderboard, player scorecard and skin details, Gross/Net E formatting, Profit / Loss for completed game units, Nassau tab.

## Deployment
Replace app files in GitHub with this folder. Netlify will rebuild. No new SQL migration is required for UI features.

## Important database configuration
The authenticated role needs DELETE privileges and an RLS DELETE policy on tlg_games allowing match creator or round commissioner to delete. The existing database may not provide that policy. Do NOT disable RLS. If Remove returns permission denied, inspect your policies and apply a narrowly scoped DELETE policy.

The application polls every five seconds as a fallback because the Supabase realtime publication might not include tlg_games. For true instant notifications enable tlg_games in Database > Publications > supabase_realtime (and ensure SELECT RLS allows participants to see matches).

Profit/Loss currently sums completed game-unit results for Pigeon and Nassau; unfinished matches show provisional $0. Skins are counts, not dollar settlements.

Note: If a v9/v10 SQL function forces status pending or restricts deletion, that function/policy must be updated separately.
