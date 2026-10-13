-- 慢慢来 v2：在 Supabase SQL Editor 运行。所有业务表均按 auth.uid() 隔离。
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null default '慢慢', focus text, challenge_start_date date not null default current_date,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.app_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb, revision bigint not null default 0,
  updated_at timestamptz not null default now()
);
create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, starts_on date not null, ends_on date not null, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.annual_goals (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, category text not null, target_value numeric not null, current_value numeric not null default 0, unit text not null,
  starts_on date, ends_on date, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.monthly_plans (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  month_number smallint not null check(month_number between 1 and 12), title text not null, description text, review text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,month_number)
);
create table if not exists public.weekly_challenges (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  week_number smallint not null check(week_number between 1 and 52), title text not null, completed_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,week_number)
);
create table if not exists public.daily_tasks (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  position smallint not null check(position between 0 and 4), title text not null, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,position)
);
create table if not exists public.daily_checkins (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  checkin_date date not null, task_position smallint not null check(task_position between 0 and 4), completed boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,checkin_date,task_position)
);
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check(kind in ('income','necessary','nonessential','saving_in','saving_out')), amount numeric(12,2) not null check(amount>0),
  category text not null, occurred_on date not null, note text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.savings_entries (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  transaction_id uuid unique references public.transactions(id) on delete cascade, amount numeric(12,2) not null, occurred_on date not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.wishlists (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  name text not null, price numeric(12,2) not null default 0, reason text, is_essential boolean not null default false,
  calm_until timestamptz not null, decision text not null default 'waiting' check(decision in ('waiting','abandoned','purchased')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  name text not null, category text not null, quantity numeric not null default 1, purchased_on date, status text not null default 'stock', replenish boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.declutter_records (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  name text not null, category text not null, image_url text, original_price numeric(12,2), method text not null, recovered_amount numeric(12,2) not null default 0,
  handled_on date not null, status text not null default 'done', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.learning_sessions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  minutes integer not null check(minutes>0), topic text, occurred_on date not null, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, cost integer not null check(cost>0), active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.point_events (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  event_key text not null, event_type text not null, points integer not null, reference_id text,
  created_at timestamptz not null default now(), unique(user_id,event_key)
);
create table if not exists public.reward_redemptions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  reward_id uuid references public.rewards(id) on delete set null, title text not null, cost integer not null check(cost>0), redeemed_at timestamptz not null default now()
);
create table if not exists public.weekly_reviews (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null, nonessential_spend numeric(12,2) not null default 0, saved_amount numeric(12,2) not null default 0,
  happy_things text, biggest_difficulty text, next_focus text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,week_start)
);
create table if not exists public.monthly_reviews (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  month_start date not null, saved_amount numeric(12,2) not null default 0, declutter_count integer not null default 0, learning_minutes integer not null default 0,
  exercise_count integer not null default 0, summary text, next_goal text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,month_start)
);
create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade, currency text not null default 'CNY', calm_hours integer not null default 72,
  nonessential_rule text, privacy_mode boolean not null default true, settings jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_user_date on public.transactions(user_id,occurred_on desc);
create index if not exists idx_checkins_user_date on public.daily_checkins(user_id,checkin_date desc);
create index if not exists idx_wishlists_user_calm on public.wishlists(user_id,calm_until);
create index if not exists idx_declutter_user_date on public.declutter_records(user_id,handled_on desc);

do $$ declare t text; begin
  foreach t in array array['profiles','app_snapshots','challenges','annual_goals','monthly_plans','weekly_challenges','daily_tasks','daily_checkins','transactions','savings_entries','wishlists','inventory_items','declutter_records','learning_sessions','rewards','point_events','reward_redemptions','weekly_reviews','monthly_reviews','user_settings'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('drop policy if exists "owner_all" on public.%I',t);
    execute format('create policy "owner_all" on public.%I for all using (auth.uid() = user_id) with check (auth.uid() = user_id)',t);
  end loop;
end $$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(user_id,nickname) values(new.id,coalesce(new.raw_user_meta_data->>'nickname','慢慢')) on conflict do nothing; return new; end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

