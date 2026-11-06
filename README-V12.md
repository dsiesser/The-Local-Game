# The Local Game v12

## Install
1. Back up Supabase. Run `supabase-v12-upgrade.sql` in Supabase SQL Editor.
2. Upload app files to GitHub and wait for Netlify to deploy.
3. While signed in as commissioner, open Setup and click **Generate / Rotate Recovery Key**. Store the Round ID and private key securely. This is distinct from the public invite code.
4. Test Nassau with dots enabled, per-unit wager and per-dot wager. Enter team dots by hole in the match card.

## Important
Closing the app should preserve Supabase's anonymous session, but explicitly signing out, clearing browser data or changing devices creates a new anonymous identity. Recovery transfers commissioner access; it does not restore the previous anonymous identity or automatically reclaim its player roster entry. Generate the recovery key **before** losing access. If commissioner access was already lost and no recovery key exists, a trusted database administrator must manually restore access after independently verifying ownership.

The SQL does not disable RLS. Verify that existing `tlg_games` update policies and triggers permit editing `hole_dots` by the creator. The UI exposes dots to the creator or commissioner, but your existing RLS may need an additional commissioner update policy. No production Supabase integration test was performed.
