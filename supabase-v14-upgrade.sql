-- The Local Game v14: reliable match removal and dot entry permissions.
-- Apply in Supabase SQL Editor before deploying v14.
create or replace function public.tlg_remove_match_v14(match_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare m public.tlg_games%rowtype;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  select * into m from public.tlg_games where id=match_id;
  if not found then return false; end if;
  if m.created_by is distinct from auth.uid() and not public.tlg_is_commissioner(m.round_id) then
    raise exception 'Only the match creator or commissioner can remove this match';
  end if;
  delete from public.tlg_games where id=match_id;
  return found;
end $$;
revoke all on function public.tlg_remove_match_v14(uuid) from public;
grant execute on function public.tlg_remove_match_v14(uuid) to authenticated;
-- Allow any golfer involved in a Nassau match to record team dots.
-- Existing update guard prevents changes to protected match fields.
drop policy if exists tlg_game_dot_participant_v14 on public.tlg_games;
create policy tlg_game_dot_participant_v14 on public.tlg_games
for update to authenticated
using (kind='canyon' and dots_enabled and exists (
 select 1 from public.tlg_players p where p.round_id=tlg_games.round_id and p.user_id=auth.uid()
 and p.id in (tlg_games.a,tlg_games.b,tlg_games.c,tlg_games.d)))
with check (kind='canyon' and dots_enabled and exists (
 select 1 from public.tlg_players p where p.round_id=tlg_games.round_id and p.user_id=auth.uid()
 and p.id in (tlg_games.a,tlg_games.b,tlg_games.c,tlg_games.d)));
notify pgrst, 'reload schema';
