-- Run AFTER supabase-v8.sql. No SMTP required. Enable Anonymous Sign-Ins in Supabase Auth settings.
-- This script preserves v8 rounds and scores.
alter table public.tlg_players alter column hi drop not null;
alter table public.tlg_players alter column hi drop default;
alter table public.tlg_players add column if not exists index_status text not null default 'commissioner' check(index_status in ('needed','player','commissioner'));
update public.tlg_players set index_status='needed' where hi is null;
-- Round creators and joined golfers are authenticated anonymous Supabase users.
-- A secret join code authorizes a roster claim or addition. New additions default to group 6,
-- to prevent scoring another group's players before the commissioner assigns them.
create or replace function public.tlg_join_round_v9(code text, golfer uuid default null, new_name text default null, reported_hi numeric default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid; existing uuid;
begin
 if auth.uid() is null then raise exception 'A device session is required'; end if;
 select id into rid from public.tlg_rounds where join_code=upper(trim(code)) and status='open';
 if rid is null then raise exception 'Invalid or closed invitation'; end if;
 select id into existing from public.tlg_players where round_id=rid and user_id=auth.uid();
 if existing is not null then return rid; end if;
 if reported_hi is not null and (reported_hi < -10 or reported_hi > 99.9) then raise exception 'Invalid Handicap Index'; end if;
 if golfer is not null then
   update public.tlg_players set user_id=auth.uid(), hi=reported_hi,
     index_status=case when reported_hi is null then 'needed' else 'player' end

   where id=golfer and round_id=rid and user_id is null;
   if not found then raise exception 'Name already claimed. Ask the commissioner for help'; end if;
 else
   if length(trim(coalesce(new_name,''))) < 3 or length(trim(new_name))>120 then raise exception 'Enter your first and last name'; end if;
   if (select count(*) from public.tlg_players where round_id=rid)>=24 then raise exception 'Round is full (24 golfers)'; end if;
   insert into public.tlg_players(round_id,name,hi,group_number,user_id,index_status)
   values(rid,trim(new_name),reported_hi,6,auth.uid(),case when reported_hi is null then 'needed' else 'player' end);
 end if;
 return rid;
end; $$;
revoke all on function public.tlg_join_round_v9(text,uuid,text,numeric) from public;
grant execute on function public.tlg_join_round_v9(text,uuid,text,numeric) to authenticated;
-- No player email addresses are collected or stored in the invite workflow.
-- Keep commissioner editing via existing RLS. Client recalculates derived standings from current scores and indexes.

-- Newly created commissioners also start with an unknown handicap until they set it.
create or replace function public.tlg_create_round(round_name text, course_name text, tee_name text, course_slope numeric, course_rating numeric, course_par integer, hole_data jsonb, commissioner_name text)
returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid;
begin
 if auth.uid() is null then raise exception 'Device session required'; end if;
 insert into public.tlg_rounds(name,course,tee,slope,rating,par,holes,commissioner_id)
 values(round_name,course_name,tee_name,course_slope,course_rating,course_par,hole_data,auth.uid()) returning id into rid;
 insert into public.tlg_players(round_id,name,hi,group_number,user_id,index_status) values(rid,commissioner_name,null,1,auth.uid(),'needed');
 return rid;
end; $$;
