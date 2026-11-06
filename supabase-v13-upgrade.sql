-- The Local Game v13: last name + 4-digit commissioner PIN.
-- Run AFTER v12. This adds a separate login path; older recovery functions remain intact.
-- pgcrypto is already required by the v12 upgrade.
create table if not exists public.tlg_commissioner_pins_v13 (
 round_id uuid primary key references public.tlg_rounds(id) on delete cascade,
 last_name text not null,
 pin_hash text not null,
 created_at timestamptz not null default now()
);
create index if not exists tlg_commissioner_pins_last_idx on public.tlg_commissioner_pins_v13(last_name);
alter table public.tlg_commissioner_pins_v13 enable row level security;
revoke all on public.tlg_commissioner_pins_v13 from public, anon, authenticated;
create table if not exists public.tlg_commissioner_attempts_v13 (
 last_name text primary key,
 failures integer not null default 0,
 blocked_until timestamptz,
 updated_at timestamptz not null default now()
);
alter table public.tlg_commissioner_attempts_v13 enable row level security;
revoke all on public.tlg_commissioner_attempts_v13 from public, anon, authenticated;

create or replace function public.tlg_create_round_v13(
 round_name text, course_name text, tee_name text, course_slope numeric,
 course_rating numeric, course_par integer, hole_data jsonb,
 commissioner_name text, pin text
) returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid; surname text;
begin
 if auth.uid() is null then raise exception 'Guest session required'; end if;
 if pin !~ '^[0-9]{4}$' then raise exception 'PIN must be exactly four digits'; end if;
 surname:=lower(btrim(regexp_replace(btrim(commissioner_name), '^.*[[:space:]]', '')));
 if surname='' or btrim(commissioner_name)=surname then raise exception 'First and last name required'; end if;
 -- Reuse the established v9 round-creation routine to retain existing setup logic.
 rid:=public.tlg_create_round(round_name,course_name,tee_name,course_slope,course_rating,course_par,hole_data,commissioner_name);
 insert into public.tlg_commissioner_pins_v13(round_id,last_name,pin_hash)
 values(rid,surname,public.crypt(pin,public.gen_salt('bf',12)));
 return rid;
end $$;

create or replace function public.tlg_commissioner_login_v13(last_name text,pin text)
returns uuid language plpgsql security definer set search_path='' as $$
declare surname text; attempts record; rid uuid;
begin
 if auth.uid() is null then raise exception 'Guest session required'; end if;
 surname:=lower(btrim(last_name));
 if surname='' or pin !~ '^[0-9]{4}$' then raise exception 'Invalid login'; end if;
 -- Serialize attempts by surname to prevent simultaneous guessing.
 perform pg_advisory_xact_lock(hashtext('tlg-login:'||surname));
 insert into public.tlg_commissioner_attempts_v13(last_name) values(surname) on conflict do nothing;
 select * into attempts from public.tlg_commissioner_attempts_v13 where tlg_commissioner_attempts_v13.last_name=surname for update;
 if attempts.blocked_until is not null and attempts.blocked_until>now() then raise exception 'Too many attempts. Try again later'; end if;
 select p.round_id into rid from public.tlg_commissioner_pins_v13 p
 where p.last_name=surname and p.pin_hash=public.crypt(pin,p.pin_hash)
 order by p.created_at desc limit 1;
 if rid is null then
   update public.tlg_commissioner_attempts_v13
   set failures=case when updated_at<now()-interval '30 minutes' then 1 else failures+1 end,
       blocked_until=case when (case when updated_at<now()-interval '30 minutes' then 1 else failures+1 end)>=5 then now()+interval '30 minutes' else null end,
       updated_at=now() where tlg_commissioner_attempts_v13.last_name=surname;
   -- Return a generic failure without rolling back the attempt counter.
   return null;
 end if;
 update public.tlg_commissioner_attempts_v13 set failures=0,blocked_until=null,updated_at=now() where tlg_commissioner_attempts_v13.last_name=surname;
 update public.tlg_rounds set commissioner_id=auth.uid() where id=rid;
 return rid;
end $$;
revoke all on function public.tlg_create_round_v13(text,text,text,numeric,numeric,integer,jsonb,text,text) from public,anon;
revoke all on function public.tlg_commissioner_login_v13(text,text) from public,anon;
grant execute on function public.tlg_create_round_v13(text,text,text,numeric,numeric,integer,jsonb,text,text) to authenticated;
grant execute on function public.tlg_commissioner_login_v13(text,text) to authenticated;
