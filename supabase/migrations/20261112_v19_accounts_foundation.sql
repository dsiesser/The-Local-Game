-- v19 foundation: additive only. Does not change existing v18.2 login.
create table if not exists public.tlg_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  display_name text not null,
  ghin_number text,
  handicap_index numeric(4,1),
  handicap_source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tlg_profiles_username_format check (username ~ '^[a-z][a-z0-9_]{2,23}$'),
  constraint tlg_profiles_handicap_range check (handicap_index is null or handicap_index between -10 and 54)
);
create unique index if not exists tlg_profiles_username_unique on public.tlg_profiles(lower(username));
alter table public.tlg_profiles enable row level security;
revoke all on public.tlg_profiles from anon;
grant select,insert,update on public.tlg_profiles to authenticated;
drop policy if exists tlg_profile_read_self on public.tlg_profiles;
create policy tlg_profile_read_self on public.tlg_profiles for select to authenticated using (id = (select auth.uid()));
drop policy if exists tlg_profile_insert_self on public.tlg_profiles;
create policy tlg_profile_insert_self on public.tlg_profiles for insert to authenticated with check (id = (select auth.uid()));
drop policy if exists tlg_profile_update_self on public.tlg_profiles;
create policy tlg_profile_update_self on public.tlg_profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
-- Preserve existing round player IDs and scores. Link only verified account owners.
alter table public.tlg_players add column if not exists profile_id uuid references public.tlg_profiles(id);
create index if not exists tlg_players_profile_id_idx on public.tlg_players(profile_id);
-- Commissioner and participant account links are kept separately from legacy anonymous sessions.
create table if not exists public.tlg_round_memberships (
  round_id uuid not null references public.tlg_rounds(id) on delete cascade,
  profile_id uuid not null references public.tlg_profiles(id) on delete cascade,
  role text not null default 'player' check (role in ('player','commissioner')),
  created_at timestamptz not null default now(),
  primary key(round_id,profile_id)
);
alter table public.tlg_round_memberships enable row level security;
revoke all on public.tlg_round_memberships from anon;
grant select on public.tlg_round_memberships to authenticated;
drop policy if exists tlg_membership_read_self on public.tlg_round_memberships;
create policy tlg_membership_read_self on public.tlg_round_memberships for select to authenticated using (profile_id = (select auth.uid()));
-- Never automatically merge historical players by name.
comment on column public.tlg_players.profile_id is 'Only set after verified identity claim or authenticated commissioner assignment; never infer from name alone.';
