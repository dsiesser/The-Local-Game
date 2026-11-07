-- The Local Game v18.1: new rounds default to no foursome game.
-- Existing rounds retain their existing selection.
ALTER TABLE public.tlg_rounds ALTER COLUMN team_stroke_format SET DEFAULT 'none';
NOTIFY pgrst, 'reload schema';
