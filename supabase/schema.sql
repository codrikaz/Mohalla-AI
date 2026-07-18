-- =============================================
--  MOHALLA — Complete Supabase Schema (GPS-based, v2)
--  No colonies needed — pure GPS radius feed
--  Supabase SQL Editor mein paste karke run karo
-- =============================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";


-- =============================================
-- 1. USERS
-- =============================================
create table if not exists public.users (
  id               uuid primary key references auth.users(id) on delete cascade,
  phone_hash       text not null,
  anonymous_name   text,
  is_rwa_verified  boolean not null default false,
  display_name     text,        -- real naam (country feed mein dikhega)
  country_code     text,        -- ISO 3166-1 e.g. "IN", "US"
  country_name     text,        -- e.g. "India", "United States"
  country_flag     text,        -- e.g. "🇮🇳"
  fcm_token        text,
  created_at       timestamptz not null default now()
);

alter table public.users enable row level security;
create policy "users_read_own" on public.users
  for select using (auth.uid() = id);
create policy "users_insert_own" on public.users
  for insert with check (auth.uid() = id);
create policy "users_update_own" on public.users
  for update using (auth.uid() = id);


-- =============================================
-- 2. POSTS
-- =============================================
create table if not exists public.posts (
  id                  uuid primary key default uuid_generate_v4(),
  colony_id           uuid,              -- nullable — GPS ke baad zaroorat nahi
  user_id             uuid not null references public.users(id) on delete cascade,
  category            text not null check (category in ('safety', 'info', 'issue', 'krishi')),
  text                text not null check (char_length(text) <= 500),
  image_url           text,
  audio_url           text,
  agree_count         integer not null default 0,
  disagree_count      integer not null default 0,
  is_pinned           boolean not null default false,
  is_country_feed     boolean not null default false,
  poster_display_name text,              -- real naam (sirf country feed posts mein)
  country             text,              -- ISO country code e.g. "IN"
  location_lat        double precision,  -- GPS latitude
  location_lng        double precision,  -- GPS longitude
  area_name           text,              -- e.g. "Civil Lines"
  city_name           text,              -- e.g. "Rampur"
  state_name          text,              -- e.g. "Uttar Pradesh"
  created_at          timestamptz not null default now()
);

alter table public.posts enable row level security;

-- Any authenticated user can read all posts (GPS filtering app-side hoti hai)
create policy "posts_read_auth" on public.posts
  for select using (auth.uid() is not null);

create policy "posts_auth_insert" on public.posts
  for insert with check (auth.uid() = user_id);

create policy "posts_delete_own" on public.posts
  for delete using (auth.uid() = user_id);

-- Realtime enable
alter publication supabase_realtime add table public.posts;


-- =============================================
-- 3. VOTES
-- =============================================
create table if not exists public.votes (
  id         uuid primary key default uuid_generate_v4(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  type       text not null check (type in ('agree', 'disagree')),
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

alter table public.votes enable row level security;
create policy "votes_insert_auth" on public.votes
  for insert with check (auth.uid() = user_id);
create policy "votes_read_own" on public.votes
  for select using (auth.uid() = user_id);


-- =============================================
-- 4. REPLIES
-- =============================================
create table if not exists public.replies (
  id         uuid primary key default uuid_generate_v4(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  text       text not null check (char_length(text) <= 300),
  audio_url  text,
  created_at timestamptz not null default now()
);

alter table public.replies enable row level security;
create policy "replies_read_auth" on public.replies
  for select using (auth.uid() is not null);
create policy "replies_insert_auth" on public.replies
  for insert with check (auth.uid() = user_id);


-- =============================================
-- 5. ALERTS
-- =============================================
create table if not exists public.alerts (
  id         uuid primary key default uuid_generate_v4(),
  colony_id  uuid,              -- nullable — GPS ke baad zaroorat nahi
  sent_by    uuid not null references public.users(id) on delete cascade,
  type       text not null,
  message    text not null,
  created_at timestamptz not null default now()
);

alter table public.alerts enable row level security;
create policy "alerts_read_auth" on public.alerts
  for select using (auth.uid() is not null);
create policy "alerts_insert_auth" on public.alerts
  for insert with check (auth.uid() = sent_by);

-- Realtime enable
alter publication supabase_realtime add table public.alerts;


-- =============================================
-- 6. LOST & FOUND
-- =============================================
create table if not exists public.lost_found (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.users(id) on delete cascade,
  type        text not null check (type in ('lost', 'found')),
  title       text not null,
  description text,
  image_url   text,
  location_lat  double precision,
  location_lng  double precision,
  area_name     text,
  city_name     text,
  is_resolved   boolean not null default false,
  created_at    timestamptz not null default now()
);

alter table public.lost_found enable row level security;
create policy "lost_found_read_auth" on public.lost_found
  for select using (auth.uid() is not null);
create policy "lost_found_insert_auth" on public.lost_found
  for insert with check (auth.uid() = user_id);
create policy "lost_found_update_own" on public.lost_found
  for update using (auth.uid() = user_id);


-- =============================================
-- 7. SUBSCRIPTIONS
-- =============================================
create table if not exists public.subscriptions (
  id           uuid primary key default uuid_generate_v4(),
  plan         text not null check (plan in ('rwa', 'panchayat', 'premium')),
  razorpay_id  text,
  start_date   date not null default current_date,
  end_date     date,
  amount       integer not null,
  created_at   timestamptz not null default now()
);

alter table public.subscriptions enable row level security;
create policy "subscriptions_service_role" on public.subscriptions
  using (false);  -- sirf backend/admin access kare


-- =============================================
-- RPC: Vote count increment (race condition safe)
-- =============================================
create or replace function public.increment_vote(
  p_post_id   uuid,
  p_vote_type text
)
returns void
language plpgsql
security definer
as $$
begin
  if p_vote_type = 'agree' then
    update public.posts set agree_count = agree_count + 1 where id = p_post_id;
  elsif p_vote_type = 'disagree' then
    update public.posts set disagree_count = disagree_count + 1 where id = p_post_id;
  end if;
end;
$$;

-- Add/remove/switch one authenticated user's vote atomically.
create or replace function public.toggle_vote(
  p_post_id uuid,
  p_vote_type text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_previous_type text;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_vote_type not in ('agree', 'disagree') then
    raise exception 'Invalid vote type';
  end if;

  select type into v_previous_type
    from public.votes
   where post_id = p_post_id and user_id = v_user_id;

  if v_previous_type is null then
    insert into public.votes (post_id, user_id, type)
    values (p_post_id, v_user_id, p_vote_type);
    update public.posts
       set agree_count = agree_count + case when p_vote_type = 'agree' then 1 else 0 end,
           disagree_count = disagree_count + case when p_vote_type = 'disagree' then 1 else 0 end
     where id = p_post_id;
    return p_vote_type;
  elsif v_previous_type = p_vote_type then
    delete from public.votes
     where post_id = p_post_id and user_id = v_user_id;
    update public.posts
       set agree_count = greatest(agree_count - case when p_vote_type = 'agree' then 1 else 0 end, 0),
           disagree_count = greatest(disagree_count - case when p_vote_type = 'disagree' then 1 else 0 end, 0)
     where id = p_post_id;
    return null;
  end if;

  update public.votes set type = p_vote_type
   where post_id = p_post_id and user_id = v_user_id;
  update public.posts
     set agree_count = greatest(agree_count - case when v_previous_type = 'agree' then 1 else 0 end + case when p_vote_type = 'agree' then 1 else 0 end, 0),
         disagree_count = greatest(disagree_count - case when v_previous_type = 'disagree' then 1 else 0 end + case when p_vote_type = 'disagree' then 1 else 0 end, 0)
   where id = p_post_id;
  return p_vote_type;
end;
$$;

revoke all on function public.toggle_vote(uuid, text) from public;
revoke all on function public.toggle_vote(uuid, text) from anon;
grant execute on function public.toggle_vote(uuid, text) to authenticated;
