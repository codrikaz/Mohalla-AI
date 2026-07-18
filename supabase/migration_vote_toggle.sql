-- Allow authenticated users to add, remove, or switch one vote per post.
-- Run this file once in the Supabase SQL Editor.

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

  select type
    into v_previous_type
    from public.votes
   where post_id = p_post_id
     and user_id = v_user_id;

  if v_previous_type is null then
    insert into public.votes (post_id, user_id, type)
    values (p_post_id, v_user_id, p_vote_type);

    update public.posts
       set agree_count = agree_count + case when p_vote_type = 'agree' then 1 else 0 end,
           disagree_count = disagree_count + case when p_vote_type = 'disagree' then 1 else 0 end
     where id = p_post_id;

    return p_vote_type;
  end if;

  if v_previous_type = p_vote_type then
    delete from public.votes
     where post_id = p_post_id
       and user_id = v_user_id;

    update public.posts
       set agree_count = greatest(
             agree_count - case when p_vote_type = 'agree' then 1 else 0 end,
             0
           ),
           disagree_count = greatest(
             disagree_count - case when p_vote_type = 'disagree' then 1 else 0 end,
             0
           )
     where id = p_post_id;

    return null;
  end if;

  update public.votes
     set type = p_vote_type
   where post_id = p_post_id
     and user_id = v_user_id;

  update public.posts
     set agree_count = greatest(
           agree_count
             - case when v_previous_type = 'agree' then 1 else 0 end
             + case when p_vote_type = 'agree' then 1 else 0 end,
           0
         ),
         disagree_count = greatest(
           disagree_count
             - case when v_previous_type = 'disagree' then 1 else 0 end
             + case when p_vote_type = 'disagree' then 1 else 0 end,
           0
         )
   where id = p_post_id;

  return p_vote_type;
end;
$$;

revoke all on function public.toggle_vote(uuid, text) from public;
revoke all on function public.toggle_vote(uuid, text) from anon;
grant execute on function public.toggle_vote(uuid, text) to authenticated;
