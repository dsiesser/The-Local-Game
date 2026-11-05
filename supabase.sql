-- PROTOTYPE ONLY: Public read/write access for possession-of-link testing.
-- Do NOT use for sensitive data, paid contests, or production until RLS is replaced
-- with authenticated membership, commissioner roles, score audit logs, and RPC writes.
create table if not exists public.rounds (
 id uuid primary key,
 data jsonb not null,
 updated_at timestamptz not null default now()
);
alter table public.rounds enable row level security;
create policy "prototype public read" on public.rounds for select to anon using (true);
create policy "prototype public insert" on public.rounds for insert to anon with check (true);
create policy "prototype public update" on public.rounds for update to anon using (true) with check (true);
alter publication supabase_realtime add table public.rounds;
