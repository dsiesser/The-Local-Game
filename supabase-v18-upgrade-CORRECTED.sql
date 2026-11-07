-- The Local Game v18: Run once in Supabase SQL Editor after v17 upgrades.
-- Roster-code access intentionally permits any code holder to act as any roster player.
-- Keep commissioner PIN private. Existing rounds, scores, and handicaps are preserved.
CREATE TABLE IF NOT EXISTS public.tlg_player_sessions (
 round_id uuid NOT NULL REFERENCES public.tlg_rounds(id) ON DELETE CASCADE,
 player_id uuid NOT NULL REFERENCES public.tlg_players(id) ON DELETE CASCADE,
 user_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY (round_id,user_id)
);
CREATE INDEX IF NOT EXISTS tlg_player_sessions_player ON public.tlg_player_sessions(player_id);
ALTER TABLE public.tlg_player_sessions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.tlg_player_sessions FROM anon,authenticated;

-- Show every roster name, including previously selected names, and the commissioner.
CREATE OR REPLACE FUNCTION public.tlg_invite_roster_v18(code text)
RETURNS TABLE(round_id uuid,round_name text,player_id uuid,player_name text,commissioner_name text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT r.id,r.name,p.id,p.name,
   COALESCE((SELECT c.name FROM public.tlg_players c WHERE c.round_id=r.id AND c.user_id=r.commissioner_id ORDER BY c.id LIMIT 1),'Commissioner')::text
 FROM public.tlg_rounds r JOIN public.tlg_players p ON p.round_id=r.id
 WHERE r.join_code=upper(trim(code)) AND r.status='open' AND auth.uid() IS NOT NULL
 ORDER BY p.name;
$$;
REVOKE ALL ON FUNCTION public.tlg_invite_roster_v18(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tlg_invite_roster_v18(text) TO authenticated;

-- Rejoining a name changes only the device-to-player association, not the roster or index.
CREATE OR REPLACE FUNCTION public.tlg_select_player_v18(code text,golfer uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE rid uuid;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sign in to a guest session first'; END IF;
 SELECT id INTO rid FROM public.tlg_rounds WHERE join_code=upper(trim(code)) AND status='open';
 IF rid IS NULL THEN RAISE EXCEPTION 'Invalid or closed game code'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tlg_players WHERE id=golfer AND round_id=rid) THEN
  RAISE EXCEPTION 'Choose a golfer from this game';
 END IF;
 INSERT INTO public.tlg_player_sessions(round_id,player_id,user_id)
 VALUES(rid,golfer,auth.uid())
 ON CONFLICT(round_id,user_id) DO UPDATE SET player_id=EXCLUDED.player_id;
 RETURN rid;
END;
$$;
REVOKE ALL ON FUNCTION public.tlg_select_player_v18(text,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tlg_select_player_v18(text,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.tlg_is_member(r uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.tlg_players p WHERE p.round_id=r AND p.user_id=auth.uid())
 OR EXISTS(SELECT 1 FROM public.tlg_rounds x WHERE x.id=r AND x.commissioner_id=auth.uid())
 OR EXISTS(SELECT 1 FROM public.tlg_player_sessions x WHERE x.round_id=r AND x.user_id=auth.uid());
$$;

CREATE OR REPLACE FUNCTION public.tlg_set_score(r uuid,p uuid,h integer,s integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE allowed boolean;
BEGIN
 SELECT (public.tlg_is_commissioner(r) OR EXISTS(
  SELECT 1 FROM public.tlg_players actor JOIN public.tlg_players target ON actor.round_id=target.round_id
  WHERE actor.round_id=r AND target.id=p AND actor.group_number=target.group_number
   AND (actor.user_id=auth.uid() OR EXISTS(
     SELECT 1 FROM public.tlg_player_sessions ps WHERE ps.round_id=r AND ps.player_id=actor.id AND ps.user_id=auth.uid()))))
 AND EXISTS(SELECT 1 FROM public.tlg_rounds WHERE id=r AND status='open') INTO allowed;
 IF NOT coalesce(allowed,false) THEN RAISE EXCEPTION 'Not permitted to score this group'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tlg_players WHERE id=p AND round_id=r) THEN RAISE EXCEPTION 'Invalid golfer'; END IF;
 IF h NOT BETWEEN 1 AND 18 THEN RAISE EXCEPTION 'Invalid hole'; END IF;
 IF s IS NULL THEN DELETE FROM public.tlg_scores WHERE round_id=r AND player_id=p AND hole=h;
 ELSIF s BETWEEN 1 AND 30 THEN
  INSERT INTO public.tlg_scores(round_id,player_id,hole,strokes,edited_by) VALUES(r,p,h,s,auth.uid())
  ON CONFLICT(player_id,hole) DO UPDATE SET strokes=EXCLUDED.strokes,edited_by=EXCLUDED.edited_by,updated_at=now();
 ELSE RAISE EXCEPTION 'Invalid score'; END IF;
END;
$$;

-- Allow roster-selected players to create matches they participate in; commissioners may create any.
DROP POLICY IF EXISTS tlg_game_add ON public.tlg_games;
CREATE POLICY tlg_game_add ON public.tlg_games FOR INSERT TO authenticated
WITH CHECK (
 public.tlg_is_member(round_id) AND created_by=auth.uid()
 AND (public.tlg_is_commissioner(round_id) OR EXISTS(
  SELECT 1 FROM public.tlg_players p WHERE p.round_id=tlg_games.round_id
  AND p.id IN(tlg_games.a,tlg_games.b,tlg_games.c,tlg_games.d)
  AND (p.user_id=auth.uid() OR EXISTS(
   SELECT 1 FROM public.tlg_player_sessions ps WHERE ps.round_id=tlg_games.round_id
   AND ps.player_id=p.id AND ps.user_id=auth.uid()))))
);

ALTER TABLE public.tlg_rounds ADD COLUMN IF NOT EXISTS kp_winners jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.tlg_rounds ADD COLUMN IF NOT EXISTS team_stroke_format text NOT NULL DEFAULT 'two-net';
NOTIFY pgrst,'reload schema';

-- Press requests: server verifies membership, which side is behind, and the
-- original/press interval. Only one request per source bet and start hole.
CREATE OR REPLACE FUNCTION public.tlg_add_press_v18(match_id uuid,source_id text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE g public.tlg_games%ROWTYPE; parent jsonb; begin_h integer; end_h integer;
 n integer; played integer:=0; diff integer:=0; side integer:=0; h jsonb;
 a_score integer; b_score integer; a_low integer; b_low integer;
 aid uuid; bid uuid; hc_a integer; hc_b integer; low_h integer; hc_c integer; hc_d integer; team_diff integer; team_high integer; recipient uuid; c_score integer; d_score integer; a_net integer; b_net integer; c_net integer; d_net integer;
 arr jsonb; new_press jsonb;
BEGIN
 SELECT * INTO g FROM public.tlg_games WHERE id=match_id AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Match unavailable'; END IF;
 IF source_id='front' THEN begin_h:=1;end_h:=9;
 ELSIF source_id='back' THEN begin_h:=10;end_h:=18;
 ELSIF source_id='overall' THEN begin_h:=1;end_h:=18;
 ELSE
  SELECT x INTO parent FROM jsonb_array_elements(g.presses) x WHERE x->>'id'=source_id LIMIT 1;
  IF parent IS NULL THEN RAISE EXCEPTION 'Unknown press'; END IF;
  begin_h:=(parent->>'start')::integer;end_h:=(parent->>'end')::integer;
 END IF;
 IF public.tlg_is_commissioner(g.round_id) THEN
  -- Commissioners who are not playing cannot initiate another team's press.
  NULL;
 END IF;
 SELECT CASE WHEN EXISTS(SELECT 1 FROM public.tlg_players p WHERE p.id IN(g.a,g.c) AND p.round_id=g.round_id
   AND (p.user_id=auth.uid() OR EXISTS(SELECT 1 FROM public.tlg_player_sessions ps WHERE ps.round_id=g.round_id AND ps.player_id=p.id AND ps.user_id=auth.uid()))) THEN 1
 WHEN EXISTS(SELECT 1 FROM public.tlg_players p WHERE p.id IN(g.b,g.d) AND p.round_id=g.round_id
   AND (p.user_id=auth.uid() OR EXISTS(SELECT 1 FROM public.tlg_player_sessions ps WHERE ps.round_id=g.round_id AND ps.player_id=p.id AND ps.user_id=auth.uid()))) THEN -1 ELSE 0 END INTO side;
 IF side=0 THEN RAISE EXCEPTION 'Only a golfer in the match may press'; END IF;
 SELECT r.holes INTO h FROM public.tlg_rounds r WHERE r.id=g.round_id AND r.status='open';
 IF h IS NULL THEN RAISE EXCEPTION 'Round closed'; END IF;
 SELECT ROUND(p.hi*r.slope/113+r.rating-r.par)::integer INTO hc_a FROM public.tlg_players p JOIN public.tlg_rounds r ON r.id=p.round_id WHERE p.id=g.a;
 SELECT ROUND(p.hi*r.slope/113+r.rating-r.par)::integer INTO hc_b FROM public.tlg_players p JOIN public.tlg_rounds r ON r.id=p.round_id WHERE p.id=g.b;
 IF hc_a IS NULL OR hc_b IS NULL THEN RAISE EXCEPTION 'Handicap missing'; END IF;
 IF g.kind='canyon' THEN
  SELECT ROUND(p.hi*r.slope/113+r.rating-r.par)::integer INTO hc_c FROM public.tlg_players p JOIN public.tlg_rounds r ON r.id=p.round_id WHERE p.id=g.c;
  SELECT ROUND(p.hi*r.slope/113+r.rating-r.par)::integer INTO hc_d FROM public.tlg_players p JOIN public.tlg_rounds r ON r.id=p.round_id WHERE p.id=g.d;
  IF hc_c IS NULL OR hc_d IS NULL THEN RAISE EXCEPTION 'Team handicap missing'; END IF;
  team_diff:=(hc_a+hc_c)-(hc_b+hc_d);
  recipient:=CASE WHEN team_diff>0 THEN CASE WHEN hc_a>=hc_c THEN g.a ELSE g.c END
                  WHEN team_diff<0 THEN CASE WHEN hc_b>=hc_d THEN g.b ELSE g.d END ELSE NULL END;
  hc_a:=CASE WHEN recipient=g.a THEN ABS(team_diff) ELSE 0 END;
  hc_b:=CASE WHEN recipient=g.b THEN ABS(team_diff) ELSE 0 END;
  hc_c:=CASE WHEN recipient=g.c THEN ABS(team_diff) ELSE 0 END;
  hc_d:=CASE WHEN recipient=g.d THEN ABS(team_diff) ELSE 0 END;
 ELSE
  low_h:=LEAST(hc_a,hc_b);hc_a:=hc_a-low_h;hc_b:=hc_b-low_h;
 END IF;
 FOR n IN begin_h..end_h LOOP
  SELECT strokes INTO a_score FROM public.tlg_scores WHERE round_id=g.round_id AND player_id=g.a AND hole=n;
  SELECT strokes INTO b_score FROM public.tlg_scores WHERE round_id=g.round_id AND player_id=g.b AND hole=n;
  IF a_score IS NULL OR b_score IS NULL THEN EXIT; END IF;
  IF g.kind='canyon' AND (NOT EXISTS(SELECT 1 FROM public.tlg_scores WHERE round_id=g.round_id AND player_id=g.c AND hole=n) OR NOT EXISTS(SELECT 1 FROM public.tlg_scores WHERE round_id=g.round_id AND player_id=g.d AND hole=n)) THEN EXIT; END IF;
  SELECT (x->>'stroke')::integer INTO a_low FROM jsonb_array_elements(h) x WHERE (x->>'number')::integer=n;
  a_score:=a_score-(hc_a/18)-CASE WHEN a_low<=hc_a%18 THEN 1 ELSE 0 END;
  b_score:=b_score-(hc_b/18)-CASE WHEN a_low<=hc_b%18 THEN 1 ELSE 0 END;
  IF g.kind='canyon' THEN
   SELECT strokes INTO c_score FROM public.tlg_scores WHERE round_id=g.round_id AND player_id=g.c AND hole=n;
   SELECT strokes INTO d_score FROM public.tlg_scores WHERE round_id=g.round_id AND player_id=g.d AND hole=n;
   IF c_score IS NULL OR d_score IS NULL THEN EXIT; END IF;
   c_net:=c_score-(hc_c/18)-CASE WHEN a_low<=hc_c%18 THEN 1 ELSE 0 END;
   d_net:=d_score-(hc_d/18)-CASE WHEN a_low<=hc_d%18 THEN 1 ELSE 0 END;
   diff:=diff+SIGN(LEAST(b_score,d_net)-LEAST(a_score,c_net))
             +SIGN(GREATEST(b_score,d_net)-GREATEST(a_score,c_net));
  ELSE diff:=diff+SIGN(b_score-a_score); END IF;
  played:=played+1;
 END LOOP;
 IF played=0 OR begin_h+played>end_h OR ABS(diff)<2 OR diff*side>=0 THEN
  RAISE EXCEPTION 'Only the losing player or team may press an eligible bet';
 END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(g.presses) x WHERE x->>'parent_id'=source_id AND (x->>'start')::integer=begin_h+played) THEN
  RAISE EXCEPTION 'This bet was already pressed on this hole';
 END IF;
 new_press:=jsonb_build_object('id',gen_random_uuid()::text,'parent_id',source_id,
  'parent',CASE WHEN source_id='front' THEN 'Front' WHEN source_id='back' THEN 'Back' WHEN source_id='overall' THEN 'Overall' ELSE coalesce(parent->>'name','Press') END,
  'start',begin_h+played,'end',end_h);
 UPDATE public.tlg_games SET presses=g.presses||jsonb_build_array(new_press) WHERE id=match_id;
END;
$$;
REVOKE ALL ON FUNCTION public.tlg_add_press_v18(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tlg_add_press_v18(uuid,text) TO authenticated;
