# The Local Game v19 — invitation-first access (staged, NOT live)

## Product decision (revised November 12)
Regular golfers **must not** register, create passwords, or log in to join a game. Commissioner creates the round, adds players, and shares a private invite. Players open their invite directly, and a durable, device-bound player session allows return to a welcome screen listing their active and past events. Commissioners may use a separate authenticated account for administrative privileges.

## Player experience
1. Commissioner creates round, chooses existing golfer or adds a new golfer to a permanent golfer directory.
2. Each player gets a private, high-entropy invite token (not a public name-picker). Token is exchanged server-side for a scoped player session; do not expose service role credentials.
3. Welcome screen: active/upcoming games, closed/past games, enter game, and optional join by invite.
4. Return on same device without password using a securely stored, revocable session. New device or lost session requires commissioner to resend invite. Never use name-only lookup as authentication.
5. Commissioner can attach a known golfer to multiple rounds. Past events persist by permanent golfer identity, with immutable scoring history.
6. Closed games are read-only for players. Scorekeepers only edit permitted groups; commissioner permissions remain separate.

## Security and migration
- Existing v18.2 remains live until tested. Do not change existing auth/RLS functions or scores during foundation stage.
- Never link historical player records solely by name. Commissioner must confirm identity before attaching historical events.
- Do not place reusable invitation secrets in query strings after redemption; remove from URL and avoid leaking via analytics/referrers.
- Store only hashes of invite/session secrets on the server; expire and rotate invites, support revocation.
- Rate-limit redemption and avoid exposing other players' private profile details.
- Existing anonymous Supabase sessions are not themselves proof of a golfer's identity.
- Backup production before any migration; verify RLS, commissioner and player flows and cross-round history on a test environment.

## Staged implementation
1. Add permanent golfer directory and round-to-golfer links (additive migration).
2. Implement secure invite issuing/redemption and player session restore on a test environment.
3. Implement welcome dashboard, commissioner roster search, past/closed round views.
4. Test multi-device, invite resend, revoke, existing v18.2 scores and commissioner controls.
5. Merge and deploy only after complete end-to-end verification.

The SQL migration in this branch is a **proposal**, not yet applied to production.

## Implementation progress
- [x] Branch-only My Games dashboard UI using `tlg_my_events_v19`.
- [x] Session-scoped query for existing linked player sessions and commissioner rounds.
- [x] Closed-round score entry disabled in UI (server-side enforcement still required).
- [ ] Apply and test dashboard query on a test Supabase project.
- [ ] Secure individual invite generation and redemption; current v18 name selection remains as fallback.
- [ ] Cross-device permanent golfer identity and verified past-round association.
- [ ] Server-side closed-round write protection.
- [ ] Full end-to-end build, test and production rollout.

**Do not merge yet:** Frontend now depends on `tlg_my_events_v19` RPC, which is not installed in production. No production deployment or database change has been made.
