-- The Local Game v11: allow round commissioner or match creator to remove duplicate games.
-- Does not disable RLS or expose games to non-members.
grant select, insert, update, delete on public.tlg_games to authenticated;
drop policy if exists tlg_game_remove on public.tlg_games;
create policy tlg_game_remove on public.tlg_games
for delete to authenticated
using (
  public.tlg_is_commissioner(round_id)
  or (created_by = (select auth.uid()) and public.tlg_is_member(round_id))
);
-- Existing v8 setup normally adds tlg_games to supabase_realtime.
-- Safe to run repeatedly if the publication exists.
do $$ begin
 if exists (select 1 from pg_publication where pubname='supabase_realtime')
 and not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tlg_games') then
  alter publication supabase_realtime add table public.tlg_games;
 end if;
end $$;
