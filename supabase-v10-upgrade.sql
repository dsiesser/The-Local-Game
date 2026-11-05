-- The Local Game v10: run AFTER v8 and v9 SQL scripts.
-- Presses become effective immediately in the existing game engine.
-- This upgrade creates an auditable, recipient-specific notification feed.
create table if not exists public.tlg_press_notifications (
 id uuid primary key default gen_random_uuid(),
 round_id uuid not null references public.tlg_rounds(id) on delete cascade,
 game_id uuid not null references public.tlg_games(id) on delete cascade,
 recipient_player_id uuid not null references public.tlg_players(id) on delete cascade,
 press_id text not null,
 message text not null,
 created_at timestamptz not null default now(),
 read_at timestamptz,
 unique(game_id,recipient_player_id,press_id)
);
create index if not exists tlg_press_notifications_recipient on public.tlg_press_notifications(recipient_player_id,created_at desc);
alter table public.tlg_press_notifications enable row level security;
drop policy if exists tlg_press_notification_read on public.tlg_press_notifications;
create policy tlg_press_notification_read on public.tlg_press_notifications for select to authenticated
 using (exists(select 1 from public.tlg_players p where p.id=recipient_player_id and p.user_id=auth.uid()));
drop policy if exists tlg_press_notification_mark_read on public.tlg_press_notifications;
-- Mark-read is handled through a restricted RPC; clients cannot edit notification contents.
create or replace function public.tlg_mark_press_notifications_read(r uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
 update public.tlg_press_notifications n set read_at=now()
 where n.round_id=r and n.read_at is null
 and exists(select 1 from public.tlg_players p where p.id=n.recipient_player_id and p.user_id=auth.uid());
end; $$;
revoke all on function public.tlg_mark_press_notifications_read(uuid) from public;
grant execute on function public.tlg_mark_press_notifications_read(uuid) to authenticated;
-- The trigger creates notifications only for new press IDs. Recipients are the opposing side.
create or replace function public.tlg_notify_new_presses() returns trigger
language plpgsql security definer set search_path='' as $$
declare press jsonb; initiator uuid; recipient uuid; actor_name text; start_hole int; press_key text;
begin
 if new.presses is not distinct from old.presses then return new; end if;
 select p.id,p.name into initiator,actor_name from public.tlg_players p
 where p.round_id=new.round_id and p.user_id=auth.uid() limit 1;
 -- Creator is the only user permitted to add presses under the v8 update policy.
 if initiator is null then return new; end if;
 for press in select value from jsonb_array_elements(new.presses) loop
   press_key:=press->>'id';
   if press_key is null or exists(select 1 from jsonb_array_elements(old.presses) op where op->>'id'=press_key) then continue; end if;
   start_hole:=coalesce(nullif(press->>'start','')::int,1);
   -- For 1v1: opponent. For 2v2: opposing side relative to initiating golfer.
   for recipient in
     select x from unnest(array[new.a,new.b,new.c,new.d]) x where x is not null
     and (case when new.kind='pigeon' then x<>initiator
       when initiator in (new.a,new.c) then x in (new.b,new.d)
       when initiator in (new.b,new.d) then x in (new.a,new.c)
       else false end)
   loop
     insert into public.tlg_press_notifications(round_id,game_id,recipient_player_id,press_id,message)
     values(new.round_id,new.id,recipient,press_key,actor_name||' pressed your '||
       (case when new.kind='pigeon' then 'Pigeon' else 'Team Nassau' end)||' match. Starts hole '||start_hole||'.')
     on conflict do nothing;
   end loop;
 end loop;
 return new;
end; $$;
drop trigger if exists tlg_new_press_notify on public.tlg_games;
create trigger tlg_new_press_notify after update of presses on public.tlg_games
 for each row execute function public.tlg_notify_new_presses();
-- Realtime publication for in-app alerts. Ignore duplicate-publication error.
do $$ begin
 alter publication supabase_realtime add table public.tlg_press_notifications;
exception when duplicate_object then null;
end $$;
