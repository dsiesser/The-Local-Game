# The Local Game v19 — account migration (staged, NOT live)
This branch begins the move to permanent golfer accounts. v18.2 stays operational until migration, login, commissioner assignment, and historical round access are tested together.

## Decisions
- Every golfer registers; unique username and password; verified private email for recovery.
- Supabase Auth stores password hashes and recovery email. Never store passwords in public tables.
- `tlg_profiles` stores stable golfer identity and optional manually verified GHIN data.
- `tlg_round_memberships` ties accounts to rounds; `tlg_players.profile_id` links existing scoring records without replacing their IDs.
- Account welcome screen will list active/closed memberships; any account can create a round as commissioner.
- Existing anonymous round participants are NOT auto-claimed by matching names.
- Guest name-selection must be retired only after account-based join is fully tested.

## Authentication engineering requirement
Supabase password sign-in accepts email or phone, **not a username**. A username-only sign-in needs a secure server-side username-to-email resolver with rate limiting and no email disclosure. Do not expose a username/email lookup RPC to clients or put the service-role key in the PWA. The registration form can collect username, email and password with email verification; the final username sign-in flow must be implemented and tested before switching off v18.2.

## Deployment checklist
1. Back up production and test SQL on a development branch/project.
2. Apply `supabase/migrations/20261112_v19_accounts_foundation.sql` after review.
3. Implement and test registration, email verification, recovery, secure username sign-in, and session restoration.
4. Implement commissioner profile search/invite and account-based round membership.
5. Test closed-round read-only access, prior scoring, commissioner game creation and RLS.
6. Only then merge and deploy to production.

No SQL in this PR should be run automatically on production.
