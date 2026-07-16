-- Mohalla AI Build Week migration
-- Run once in Supabase SQL Editor before deploying ai-post-assistant.

create table if not exists public.ai_daily_usage (
  user_id uuid not null references public.users(id) on delete cascade,
  request_date date not null default (timezone('utc', now()))::date,
  request_count integer not null default 0 check (request_count between 0 and 3),
  updated_at timestamptz not null default now(),
  primary key (user_id, request_date)
);

create table if not exists public.ai_post_generations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  input_hash text not null,
  target_language text not null,
  result jsonb not null,
  created_at timestamptz not null default now(),
  unique (user_id, input_hash, target_language)
);

alter table public.ai_daily_usage enable row level security;
alter table public.ai_post_generations enable row level security;

drop policy if exists "ai_usage_read_own" on public.ai_daily_usage;
create policy "ai_usage_read_own" on public.ai_daily_usage
  for select using (auth.uid() = user_id);

drop policy if exists "ai_generations_read_own" on public.ai_post_generations;
create policy "ai_generations_read_own" on public.ai_post_generations
  for select using (auth.uid() = user_id);

create or replace function public.claim_ai_post_request()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_count integer;
begin
  if current_user_id is null then
    raise exception 'authentication_required';
  end if;

  insert into public.ai_daily_usage (user_id, request_date, request_count)
  values (current_user_id, (timezone('utc', now()))::date, 1)
  on conflict (user_id, request_date) do update
    set request_count = public.ai_daily_usage.request_count + 1,
        updated_at = now()
    where public.ai_daily_usage.request_count < 3
  returning request_count into new_count;

  if new_count is null then
    raise exception 'daily_limit_reached';
  end if;

  return 3 - new_count;
end;
$$;

create or replace function public.release_ai_post_request()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication_required';
  end if;

  update public.ai_daily_usage
  set request_count = greatest(0, request_count - 1),
      updated_at = now()
  where user_id = auth.uid()
    and request_date = (timezone('utc', now()))::date;
end;
$$;

revoke all on function public.claim_ai_post_request() from public;
revoke all on function public.release_ai_post_request() from public;
grant execute on function public.claim_ai_post_request() to authenticated;
grant execute on function public.release_ai_post_request() to authenticated;

-- Replace the old increment-only RPC. Counts are now recalculated from the
-- caller's real vote, so directly calling the RPC cannot inflate a post.
create or replace function public.increment_vote(
  p_post_id uuid,
  p_vote_type text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or p_vote_type not in ('agree', 'disagree') then
    raise exception 'invalid_vote';
  end if;

  if not exists (
    select 1 from public.votes
    where post_id = p_post_id
      and user_id = auth.uid()
      and type = p_vote_type
  ) then
    raise exception 'vote_not_found';
  end if;

  update public.posts
  set agree_count = (
        select count(*) from public.votes
        where post_id = p_post_id and type = 'agree'
      ),
      disagree_count = (
        select count(*) from public.votes
        where post_id = p_post_id and type = 'disagree'
      )
  where id = p_post_id;
end;
$$;

revoke all on function public.increment_vote(uuid, text) from public;
grant execute on function public.increment_vote(uuid, text) to authenticated;

-- Authenticated users may upload only into their own post-images folder.
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do update set public = true;

drop policy if exists "post_images_insert_own" on storage.objects;
create policy "post_images_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'post-images'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "post_images_delete_own" on storage.objects;
create policy "post_images_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'post-images'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
