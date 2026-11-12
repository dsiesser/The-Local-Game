-- v19 invitation-first foundation (NOT YET APPLIED).
-- Existing v18.2 player IDs and scores remain unchanged.
create table if not exists public.tlg_golfers (
 id uuid primary key default gen_random_uuid(),
 display_name text not null,
 ghin_number text,
 handicap_index numeric(4,1),
 created_at timestamptz not null default now(),
 constraint tlg_golfers_hi_range check (handicap_index is null or handicap_index between -10 and 54)
);
alter table public.tlg_golfers enable row level security;
revoke all on public.tlg_golfers from anon, authenticated;
-- Access to directory will be via commissioner-verified server endpoints with explicit authorization.
alter table public.tlg_players add column if not exists golfer_id uuid references public.tlg_golfers(id);
create index if not exists tlg_players_golfer_id_idx on public.tlg_players(golfer_id);
-- No name-based auto-merge. Existing records are not modified.
create table if not exists public.tlg_player_invites (
 id uuid primary key default gen_random_uuid(),
 golfer_id uuid not null references public.tlg_golfers(id),
 round_id uuid not null references public.tlg_rounds(id),
 token_hash text not null unique,
 expires_at timestamptz not null,
 redeemed_at timestamptz,
 revoked_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.tlg_player_invites enable row level security;
revoke all on public.tlg_player_invites from anon, authenticated;
-- Secure token issue/redeem and persistent player-session backend must be implemented
-- before this schema is deployed. Never expose token hashes via Data API.
