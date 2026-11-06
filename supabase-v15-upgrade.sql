-- Safe compatibility migration for The Local Game v15
ALTER TABLE public.tlg_games ADD COLUMN IF NOT EXISTS sweep boolean NOT NULL DEFAULT false;
NOTIFY pgrst, 'reload schema';
