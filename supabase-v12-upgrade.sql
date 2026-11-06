-- The Local Game v12: team dots and secure commissioner recovery.
-- Run after v11. Recovery secrets are stored only as hashes in a separate, RLS-protected table.
alter table public.tlg_games add column if not exists dots_enabled boolean not null default false;
alter table public.tlg_games add column if not exists dot_unit numeric not null default 0 check(dot_unit>=0);
alter table public.tlg_games add column if not exists hole_dots jsonb not null default '{}'::jsonb;
create table if not exists public.tlg_commissioner_recovery (
 round_id uuid primary key references public.tlg_rounds(id) on delete cascade,
 secret_hash text not null,
 created_at timestamptz not null default now()
);
alter table public.tlg_commissioner_recovery enable row level security;
revoke all on public.tlg_commissioner_recovery from public, anon, authenticated;
create or replace function public.tlg_issue_commissioner_recovery(r uuid)
returns text language plpgsql security definer set search_path='' as $$
declare raw text;
begin
 if auth.uid() is null or not exists(select 1 from public.tlg_rounds where id=r and commissioner_id=auth.uid()) then raise exception 'Commissioner access required'; end if;
 raw:=encode(gen_random_bytes(24),'hex');
 insert into public.tlg_commissioner_recovery(round_id,secret_hash,created_at)
 values(r,public.crypt(raw,public.gen_salt('bf',12)),now())
 on conflict(round_id) do update set secret_hash=excluded.secret_hash,created_at=now();
 return raw;
end $$;
create or replace function public.tlg_recover_commissioner(r text,secret text)
returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid; existing uuid;
begin
 if auth.uid() is null then raise exception 'Guest session required'; end if;
 begin rid:=r::uuid; exception when invalid_text_representation then raise exception 'Invalid round ID'; end;
 if length(secret)<40 then raise exception 'Invalid recovery key'; end if;
 if not exists(select 1 from public.tlg_commissioner_recovery x where x.round_id=rid and x.secret_hash=public.crypt(secret,x.secret_hash)) then raise exception 'Recovery key incorrect'; end if;
 -- A new anonymous identity may already belong to a golfer in this round; commissioner rights transfer without changing scores.
 update public.tlg_rounds set commissioner_id=auth.uid() where id=rid;
 return rid;
end $$;
revoke all on function public.tlg_issue_commissioner_recovery(uuid) from public,anon;
revoke all on function public.tlg_recover_commissioner(text,text) from public,anon;
grant execute on function public.tlg_issue_commissioner_recovery(uuid),public.tlg_recover_commissioner(text,text) to authenticated;
-- Commissioners can edit dots in any game; creators can edit their own games.
-- Existing update policy and validation triggers remain active.

-- Permit commissioner to update matches, including dot scores.
drop policy if exists tlg_game_commissioner_edit on public.tlg_games;
create policy tlg_game_commissioner_edit on public.tlg_games
for update to authenticated
using (public.tlg_is_commissioner(round_id))
with check (public.tlg_is_commissioner(round_id));
