-- The Local Game v8: NEW installation. Run in Supabase SQL Editor.
-- Do not run legacy supabase.sql: it grants public anonymous write access.
create extension if not exists pgcrypto;
create table if not exists public.tlg_rounds (
 id uuid primary key default gen_random_uuid(), name text not null default 'Golf round', course text not null default 'Custom', tee text not null default 'White', slope numeric not null default 113, rating numeric not null default 72, par integer not null default 72,
 holes jsonb not null, commissioner_id uuid not null references auth.users(id), join_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,8)), status text not null default 'open' check(status in ('open','closed')), created_at timestamptz not null default now());
create table if not exists public.tlg_players (
 id uuid primary key default gen_random_uuid(), round_id uuid not null references public.tlg_rounds(id) on delete cascade,
 name text not null, hi numeric not null default 18 check(hi between -10 and 99.9), group_number integer not null default 1 check(group_number between 1 and 6), user_id uuid references auth.users(id), unique(round_id,user_id));
create unique index if not exists tlg_claimed_user_round on public.tlg_players(round_id,user_id) where user_id is not null;
create table if not exists public.tlg_scores (
 round_id uuid not null references public.tlg_rounds(id) on delete cascade,
 player_id uuid not null references public.tlg_players(id) on delete cascade,
 hole integer not null check(hole between 1 and 18), strokes integer not null check(strokes between 1 and 30), edited_by uuid not null references auth.users(id), updated_at timestamptz not null default now(), primary key(player_id,hole));
create table if not exists public.tlg_games (
 id uuid primary key default gen_random_uuid(), round_id uuid not null references public.tlg_rounds(id) on delete cascade,
 kind text not null check(kind in ('pigeon','canyon')), created_by uuid not null references auth.users(id),
 a uuid not null references public.tlg_players(id), b uuid not null references public.tlg_players(id),
 c uuid references public.tlg_players(id), d uuid references public.tlg_players(id),
 unit numeric not null default 5 check(unit>=0), sweep boolean not null default false,
 status text not null default 'pending' check(status in ('pending','active','declined')),
 presses jsonb not null default '[]'::jsonb, created_at timestamptz not null default now(), check(a<>b));
create index if not exists tlg_players_round_idx on public.tlg_players(round_id);
create index if not exists tlg_scores_round_idx on public.tlg_scores(round_id);
create index if not exists tlg_games_round_idx on public.tlg_games(round_id);
create or replace function public.tlg_is_member(r uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.tlg_players p where p.round_id=r and p.user_id=(select auth.uid()))
 or exists(select 1 from public.tlg_rounds x where x.id=r and x.commissioner_id=(select auth.uid())); $$;
create or replace function public.tlg_is_commissioner(r uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.tlg_rounds x where x.id=r and x.commissioner_id=(select auth.uid())); $$;
revoke all on function public.tlg_is_member(uuid), public.tlg_is_commissioner(uuid) from public;
grant execute on function public.tlg_is_member(uuid), public.tlg_is_commissioner(uuid) to authenticated;
-- Join by secret invitation code. Claim an unclaimed roster slot exactly once.
create or replace function public.tlg_join_round(code text, golfer uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 select id into rid from public.tlg_rounds where join_code=upper(trim(code)) and status='open';
 if rid is null then raise exception 'Invalid or closed invitation'; end if;
 if exists(select 1 from public.tlg_players where round_id=rid and user_id=auth.uid()) then return rid; end if;
 update public.tlg_players set user_id=auth.uid() where id=golfer and round_id=rid and user_id is null;
 if not found then raise exception 'Golfer already claimed or not found'; end if;
 return rid;
end; $$;
revoke all on function public.tlg_join_round(text,uuid) from public;
grant execute on function public.tlg_join_round(text,uuid) to authenticated;
-- Read unclaimed roster names only when a valid code is supplied (no public round enumeration).
create or replace function public.tlg_invite_roster(code text)
returns table(round_id uuid,round_name text,player_id uuid,player_name text) language sql stable security definer set search_path='' as $$
 select r.id,r.name,p.id,p.name from public.tlg_rounds r join public.tlg_players p on p.round_id=r.id
 where r.join_code=upper(trim(code)) and r.status='open' and p.user_id is null and auth.uid() is not null order by p.name; $$;
revoke all on function public.tlg_invite_roster(text) from public;
grant execute on function public.tlg_invite_roster(text) to authenticated;
-- Commissioner creates a round and first linked golfer in one transaction.
create or replace function public.tlg_create_round(round_name text, course_name text, tee_name text, course_slope numeric, course_rating numeric, course_par integer, hole_data jsonb, commissioner_name text)
returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 insert into public.tlg_rounds(name,course,tee,slope,rating,par,holes,commissioner_id)
 values(round_name,course_name,tee_name,course_slope,course_rating,course_par,hole_data,auth.uid()) returning id into rid;
 insert into public.tlg_players(round_id,name,hi,group_number,user_id) values(rid,commissioner_name,18,1,auth.uid());
 return rid;
end; $$;
revoke all on function public.tlg_create_round(text,text,text,numeric,numeric,integer,jsonb,text) from public;
grant execute on function public.tlg_create_round(text,text,text,numeric,numeric,integer,jsonb,text) to authenticated;
-- A secure score write checks the actual target player's group on the server.
create or replace function public.tlg_set_score(r uuid,p uuid,h integer,s integer)
returns void language plpgsql security definer set search_path='' as $$
declare allowed boolean;
begin
 select (public.tlg_is_commissioner(r) or exists(
  select 1 from public.tlg_players actor join public.tlg_players target on actor.round_id=target.round_id
  where actor.round_id=r and actor.user_id=auth.uid() and target.id=p and actor.group_number=target.group_number))
  and exists(select 1 from public.tlg_rounds where id=r and status='open') into allowed;
 if not coalesce(allowed,false) then raise exception 'Not permitted to score this group'; end if;
 if not exists(select 1 from public.tlg_players where id=p and round_id=r) then raise exception 'Invalid golfer'; end if;
 if h not between 1 and 18 then raise exception 'Invalid hole'; end if;
 if s is null then delete from public.tlg_scores where round_id=r and player_id=p and hole=h;
 elsif s between 1 and 30 then
  insert into public.tlg_scores(round_id,player_id,hole,strokes,edited_by) values(r,p,h,s,auth.uid())
  on conflict(player_id,hole) do update set strokes=excluded.strokes,edited_by=excluded.edited_by,updated_at=now();
 else raise exception 'Invalid score'; end if;
end; $$;
revoke all on function public.tlg_set_score(uuid,uuid,integer,integer) from public;
grant execute on function public.tlg_set_score(uuid,uuid,integer,integer) to authenticated;
-- Server-side invitation acceptance: only the intended golfer may accept.
create or replace function public.tlg_respond_game(game_id uuid,decision text)
returns void language plpgsql security definer set search_path='' as $$
declare g public.tlg_games%rowtype; me uuid;
begin
 select * into g from public.tlg_games where id=game_id;
 if not found or g.status<>'pending' then raise exception 'Invitation unavailable'; end if;
 select id into me from public.tlg_players where round_id=g.round_id and user_id=auth.uid();
 if me is null or me not in (g.a,g.b,g.c,g.d) or g.created_by=auth.uid() then raise exception 'Not an invited player'; end if;
 if decision not in ('active','declined') then raise exception 'Invalid response'; end if;
 update public.tlg_games set status=decision where id=game_id;
end; $$;
revoke all on function public.tlg_respond_game(uuid,text) from public;
grant execute on function public.tlg_respond_game(uuid,text) to authenticated;
-- All records private to members; setup only commissioner, score writes only via RPC.
alter table public.tlg_rounds enable row level security;
alter table public.tlg_players enable row level security;
alter table public.tlg_scores enable row level security;
alter table public.tlg_games enable row level security;
create policy tlg_round_read on public.tlg_rounds for select to authenticated using(public.tlg_is_member(id));
create policy tlg_round_edit on public.tlg_rounds for update to authenticated using(public.tlg_is_commissioner(id)) with check(public.tlg_is_commissioner(id));
create policy tlg_player_read on public.tlg_players for select to authenticated using(public.tlg_is_member(round_id));
create policy tlg_player_add on public.tlg_players for insert to authenticated with check(public.tlg_is_commissioner(round_id) and user_id is null);
create policy tlg_player_edit on public.tlg_players for update to authenticated using(public.tlg_is_commissioner(round_id)) with check(public.tlg_is_commissioner(round_id));
create policy tlg_player_delete on public.tlg_players for delete to authenticated using(public.tlg_is_commissioner(round_id) and user_id is null);
create policy tlg_score_read on public.tlg_scores for select to authenticated using(public.tlg_is_member(round_id));
create policy tlg_game_read on public.tlg_games for select to authenticated using(public.tlg_is_member(round_id));
create policy tlg_game_add on public.tlg_games for insert to authenticated with check(public.tlg_is_member(round_id) and created_by=auth.uid() and exists(select 1 from public.tlg_players p where p.round_id=round_id and p.user_id=auth.uid() and p.id in (a,b,c,d)));
-- Game edits are restricted to creator, but status changes go through responder RPC.
create policy tlg_game_edit on public.tlg_games for update to authenticated using(public.tlg_is_member(round_id) and created_by=auth.uid()) with check(public.tlg_is_member(round_id) and created_by=auth.uid());
-- Prevent creator changing match participants, stakes or status after creation via direct UPDATE.
create or replace function public.tlg_guard_game_update() returns trigger language plpgsql as $$ begin
 if (new.round_id,new.kind,new.created_by,new.a,new.b,new.c,new.d,new.unit,new.sweep,new.status) is distinct from
    (old.round_id,old.kind,old.created_by,old.a,old.b,old.c,old.d,old.unit,old.sweep,old.status) then
  if current_setting('tlg.game_response',true) is distinct from 'yes' then raise exception 'Game terms are immutable'; end if;
 end if;
 return new;
end $$;
drop trigger if exists tlg_game_guard on public.tlg_games;
create trigger tlg_game_guard before update on public.tlg_games for each row execute function public.tlg_guard_game_update();
-- responder RPC is SECURITY DEFINER but must mark authorized status change for trigger.
create or replace function public.tlg_respond_game(game_id uuid,decision text)
returns void language plpgsql security definer set search_path='' as $$
declare g public.tlg_games%rowtype; me uuid;
begin
 select * into g from public.tlg_games where id=game_id;
 if not found or g.status<>'pending' then raise exception 'Invitation unavailable'; end if;
 select id into me from public.tlg_players where round_id=g.round_id and user_id=auth.uid();
 if me is null or me not in (g.a,g.b,g.c,g.d) or g.created_by=auth.uid() then raise exception 'Not an invited player'; end if;
 if decision not in ('active','declined') then raise exception 'Invalid response'; end if;
 perform set_config('tlg.game_response','yes',true);
 update public.tlg_games set status=decision where id=game_id;
end; $$;
-- Realtime broadcasts; membership-protected reads remain enforced by RLS.
do $$ begin
 alter publication supabase_realtime add table public.tlg_rounds;
 alter publication supabase_realtime add table public.tlg_players;
 alter publication supabase_realtime add table public.tlg_scores;
 alter publication supabase_realtime add table public.tlg_games;
exception when duplicate_object then null; end $$;
-- Ensure all participants in a game belong to the same round, and Canyon games have four unique golfers.
create or replace function public.tlg_validate_game() returns trigger language plpgsql set search_path='' as $$
declare n integer; required_n integer;
begin
 required_n:=case when new.kind='pigeon' then 2 else 4 end;
 if new.kind='canyon' and (new.c is null or new.d is null) then raise exception 'Canyon requires four players'; end if;
 if new.kind='canyon' and (new.a=new.c or new.a=new.d or new.b=new.c or new.b=new.d or new.c=new.d) then raise exception 'Players must be unique'; end if;
 if new.kind='pigeon' and (new.c is not null or new.d is not null) then raise exception 'Pigeon has two players'; end if;
 select count(*) into n from public.tlg_players where round_id=new.round_id and id in (new.a,new.b,new.c,new.d);
 if n<>required_n then raise exception 'All participants must belong to this round'; end if;
 return new;
end $$;
drop trigger if exists tlg_game_validate on public.tlg_games;
create trigger tlg_game_validate before insert or update on public.tlg_games for each row execute function public.tlg_validate_game();
-- The old v1-v7 public rounds table may remain if upgrading. Remove its anonymous policies.
do $$ begin
 if to_regclass('public.rounds') is not null then
  execute 'drop policy if exists "prototype public read" on public.rounds';
  execute 'drop policy if exists "prototype public insert" on public.rounds';
  execute 'drop policy if exists "prototype public update" on public.rounds';
 end if;
end $$;
