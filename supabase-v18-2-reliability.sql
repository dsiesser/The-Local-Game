-- The Local Game v18.2. Run ONCE in Supabase SQL Editor as project owner.
-- Does not delete or alter existing rounds, players, scores, or match results.
BEGIN;
-- Private session table remains inaccessible directly to clients.
REVOKE ALL ON TABLE public.tlg_player_sessions FROM anon, authenticated;

-- RLS policies must not read the private session table directly as the client role.
-- SECURITY DEFINER evaluates the membership check under the function owner.
CREATE OR REPLACE FUNCTION public.tlg_can_create_match_v182(
  r uuid, creator uuid, pa uuid, pb uuid, pc uuid, pd uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT auth.uid() IS NOT NULL
    AND creator = auth.uid()
    AND public.tlg_is_member(r)
    AND (
      public.tlg_is_commissioner(r)
      OR EXISTS (
        SELECT 1 FROM public.tlg_players p
        WHERE p.round_id = r
          AND p.id IN (pa,pb,pc,pd)
          AND (
            p.user_id = auth.uid()
            OR EXISTS (
              SELECT 1 FROM public.tlg_player_sessions s
              WHERE s.round_id = r AND s.player_id = p.id AND s.user_id = auth.uid()
            )
          )
      )
    );
$$;
REVOKE ALL ON FUNCTION public.tlg_can_create_match_v182(uuid,uuid,uuid,uuid,uuid,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tlg_can_create_match_v182(uuid,uuid,uuid,uuid,uuid,uuid) TO authenticated;

DROP POLICY IF EXISTS tlg_game_add ON public.tlg_games;
CREATE POLICY tlg_game_add ON public.tlg_games FOR INSERT TO authenticated
WITH CHECK (public.tlg_can_create_match_v182(round_id,created_by,a,b,c,d));

-- v18's roster lookup referred to a column not present in some deployments.
-- Preserve the existing function signature to avoid breaking dependent objects.
CREATE OR REPLACE FUNCTION public.tlg_invite_roster_v18(code text)
RETURNS TABLE(round_id uuid,round_name text,player_id uuid,player_name text,commissioner_name text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT r.id,r.name,p.id,p.name,
   COALESCE((SELECT c.name FROM public.tlg_players c
     WHERE c.round_id=r.id AND c.user_id=r.commissioner_id ORDER BY c.id LIMIT 1),'Commissioner')::text
 FROM public.tlg_rounds r JOIN public.tlg_players p ON p.round_id=r.id
 WHERE r.join_code=upper(trim(code)) AND r.status='open' AND auth.uid() IS NOT NULL
 ORDER BY p.name;
$$;
REVOKE ALL ON FUNCTION public.tlg_invite_roster_v18(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tlg_invite_roster_v18(text) TO authenticated;
COMMIT;
NOTIFY pgrst, 'reload schema';
