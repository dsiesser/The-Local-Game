# The Local Game v13 — Commissioner Login

## Install
1. Back up Supabase. Run `supabase-v13-upgrade.sql` in Supabase SQL Editor after v12.
2. Upload application files to GitHub (contents of this folder, not the enclosing folder). Commit and wait for Netlify.
3. Create a NEW round: enter first and last name plus a 4-digit commissioner PIN.
4. On a second phone or after losing your session, tap Commissioner Login and enter last name and PIN.

## Important limitations
- **Existing rounds** do not have a PIN automatically. Continue using their original recovery key. Create a new round to use PIN login.
- If multiple rounds share the same surname and PIN, login opens the most recently created matching round. Use distinct PINs for different rounds.
- Login transfers commissioner access to the current anonymous session. The previous device will no longer be commissioner.
- Four-digit PINs are low security. This version includes database-backed failure counting and a 30-minute lockout after five failed attempts per surname, but is intended for casual rounds, not high-stakes financial administration. Shared surnames can trigger lockouts for each other.
- Never share the commissioner PIN with golfers. Anonymous sign-ins must remain enabled.
- The SQL depends on the `public.tlg_create_round` function and `public.crypt` / `public.gen_salt` already present in your v12 environment.
