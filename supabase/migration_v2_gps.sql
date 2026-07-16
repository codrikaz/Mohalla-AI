-- =============================================
--  MOHALLA — Migration v1 → v2 (GPS-based)
--  Supabase SQL Editor mein POORA paste karo
--  ek baar mein RUN karo
-- =============================================


-- =============================================
-- STEP 1: PEHLE PURANI RLS POLICIES hato
-- (ye policies primary_colony_id use karti thi
--  isliye pehle inhe hatana zaroori hai)
-- =============================================

DROP POLICY IF EXISTS "posts_colony_read"       ON public.posts;
DROP POLICY IF EXISTS "alerts_colony_read"       ON public.alerts;
DROP POLICY IF EXISTS "replies_read_colony"      ON public.replies;
DROP POLICY IF EXISTS "lost_found_colony_read"   ON public.lost_found;


-- =============================================
-- STEP 2: USERS TABLE fix karo
-- =============================================

ALTER TABLE public.users DROP COLUMN IF EXISTS primary_colony_id;
ALTER TABLE public.users DROP COLUMN IF EXISTS secondary_colony_id;
ALTER TABLE public.users DROP COLUMN IF EXISTS is_kisan;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS country_flag text;


-- =============================================
-- STEP 3: POSTS TABLE fix karo
-- =============================================

ALTER TABLE public.posts ALTER COLUMN colony_id DROP NOT NULL;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS area_name  text;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS city_name  text;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS state_name text;


-- =============================================
-- STEP 4: ALERTS TABLE fix karo
-- =============================================

ALTER TABLE public.alerts ALTER COLUMN colony_id DROP NOT NULL;


-- =============================================
-- STEP 5: LOST & FOUND TABLE fix karo
-- =============================================

ALTER TABLE public.lost_found DROP COLUMN IF EXISTS colony_id;
ALTER TABLE public.lost_found ADD COLUMN IF NOT EXISTS location_lat double precision;
ALTER TABLE public.lost_found ADD COLUMN IF NOT EXISTS location_lng double precision;
ALTER TABLE public.lost_found ADD COLUMN IF NOT EXISTS area_name  text;
ALTER TABLE public.lost_found ADD COLUMN IF NOT EXISTS city_name  text;


-- =============================================
-- STEP 6: NAYI RLS POLICIES banao
-- =============================================

CREATE POLICY "posts_read_auth" ON public.posts
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "alerts_read_auth" ON public.alerts
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "replies_read_auth" ON public.replies
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "lost_found_read_auth" ON public.lost_found
  FOR SELECT USING (auth.uid() IS NOT NULL);


-- =============================================
-- DONE!
-- users ✅  posts ✅  votes ✅
-- replies ✅  alerts ✅
-- lost_found ✅  subscriptions ✅
-- =============================================
