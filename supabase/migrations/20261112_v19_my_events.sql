-- v19 dashboard query: reads only rounds belonging to the current Supabase session.
-- Compatible with existing anonymous v18.2 sessions; no password required.
create or replace function public.tlg_my_events_v19()
returns table(round_id uuid,round_name text,course text,status text,player_name text,role text,created_at timestamptz)
language sql stable security definer set search_path = ''
as $$
 select r.id,r.name,r.course,r.status,p.name,'player'::text,r.created_at
 from public.tlg_player_sessions s
 join public.tlg_players p on p.id=s.player_id and p.round_id=s.round_id
 join public.tlg_rounds r on r.id=s.round_id
 where s.user_id=(select auth.uid()) and (select auth.uid()) is not null
 union
 select r.id,r.name,r.course,r.status,'Commissioner'::text,'commissioner'::text,r.created_at
 from public.tlg_rounds r
 where r.commissioner_id=(select auth.uid()) and (select auth.uid()) is not null
 order by created_at desc
$$;
revoke all on function public.tlg_my_events_v19() from public,anon;
grant execute on function public.tlg_my_events_v19() to authenticated;
