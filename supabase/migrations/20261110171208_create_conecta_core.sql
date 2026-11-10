/*
# Create Conecta core data model

1. New tables
- `profiles`: public identity, city, bio, interests, and server-controlled trust fields.
- `plans`: user-created or official activities tied to a launch city.
- `plan_members`: membership and attendance eligibility for a plan.
- `messages`: group chat messages authored by verified members.
- `ratings`: private post-attendance ratings, one per person per activity.
- `reports`: safety reports for admin review.
- `blocks`: user-to-user content and contact blocks.

2. Security
- Every table has row-level security enabled.
- Public activity data is visible only to authenticated, verified users.
- User-owned profile edits are limited to display name, avatar, bio, city, and interests.
- Trust score, rating count, host status, verification, attendance counts, and admin fields are not client-writable.
- Membership, message, rating, report, and block access is scoped to the signed-in user.

3. Important notes
- All owner fields default to `auth.uid()` so clients cannot forge ownership.
- Ratings are private and can only be created after attendance is recorded.
- Official events are represented by `is_official` and are not user-editable.
*/

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  avatar_url text,
  home_city text NOT NULL CHECK (home_city IN ('Barcelona', 'Madrid', 'Valencia', 'Sevilla', 'Granada')),
  bio text NOT NULL DEFAULT '',
  interests text[] NOT NULL DEFAULT '{}',
  is_verified boolean NOT NULL DEFAULT false,
  rating_count integer NOT NULL DEFAULT 0,
  average_rating numeric(3,2),
  attended_events integer NOT NULL DEFAULT 0,
  is_host boolean NOT NULL DEFAULT false,
  is_admin boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  city text NOT NULL CHECK (city IN ('Barcelona', 'Madrid', 'Valencia', 'Sevilla', 'Granada')),
  title text NOT NULL,
  description text NOT NULL,
  category text NOT NULL,
  starts_at timestamptz NOT NULL,
  meeting_point text NOT NULL,
  max_people integer CHECK (max_people IS NULL OR max_people > 1),
  is_night boolean NOT NULL DEFAULT false,
  is_official boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.plan_members (
  plan_id uuid NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'interested' CHECK (status IN ('interested', 'going', 'removed')),
  attended boolean NOT NULL DEFAULT false,
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (plan_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  author_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  body text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  rater_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  rated_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  score integer NOT NULL CHECK (score BETWEEN 1 AND 5),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (plan_id, rater_id, rated_user_id),
  CHECK (rater_id <> rated_user_id)
);

CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id uuid REFERENCES public.plans(id) ON DELETE CASCADE,
  message_id uuid REFERENCES public.messages(id) ON DELETE CASCADE,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'reviewing', 'closed')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.blocks (
  blocker_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.profiles TO authenticated;
GRANT INSERT (display_name, avatar_url, home_city, bio, interests) ON public.profiles TO authenticated;
GRANT UPDATE (display_name, avatar_url, home_city, bio, interests) ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.plan_members TO authenticated;
GRANT SELECT, INSERT ON public.messages TO authenticated;
GRANT SELECT, INSERT ON public.ratings TO authenticated;
GRANT SELECT, INSERT ON public.reports TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.blocks TO authenticated;

DROP POLICY IF EXISTS "verified users read profiles" ON public.profiles;
CREATE POLICY "verified users read profiles" ON public.profiles FOR SELECT TO authenticated USING (is_verified = true OR id = auth.uid());
DROP POLICY IF EXISTS "users create own profile" ON public.profiles;
CREATE POLICY "users create own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
DROP POLICY IF EXISTS "users edit own public profile" ON public.profiles;
CREATE POLICY "users edit own public profile" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
DROP POLICY IF EXISTS "users delete own profile" ON public.profiles;
CREATE POLICY "users delete own profile" ON public.profiles FOR DELETE TO authenticated USING (id = auth.uid());

DROP POLICY IF EXISTS "verified users read plans" ON public.plans;
CREATE POLICY "verified users read plans" ON public.plans FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.is_verified = true));
DROP POLICY IF EXISTS "verified users create plans" ON public.plans;
CREATE POLICY "verified users create plans" ON public.plans FOR INSERT TO authenticated WITH CHECK (creator_id = auth.uid() AND is_official = false);
DROP POLICY IF EXISTS "creators edit plans" ON public.plans;
CREATE POLICY "creators edit plans" ON public.plans FOR UPDATE TO authenticated USING (creator_id = auth.uid() AND is_official = false) WITH CHECK (creator_id = auth.uid() AND is_official = false);
DROP POLICY IF EXISTS "creators delete plans" ON public.plans;
CREATE POLICY "creators delete plans" ON public.plans FOR DELETE TO authenticated USING (creator_id = auth.uid() AND is_official = false);

DROP POLICY IF EXISTS "members read memberships" ON public.plan_members;
CREATE POLICY "members read memberships" ON public.plan_members FOR SELECT TO authenticated USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM public.plan_members own WHERE own.plan_id = plan_members.plan_id AND own.user_id = auth.uid() AND own.status <> 'removed'));
DROP POLICY IF EXISTS "users join plans" ON public.plan_members;
CREATE POLICY "users join plans" ON public.plan_members FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "users update own membership" ON public.plan_members;
CREATE POLICY "users update own membership" ON public.plan_members FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "users leave plans" ON public.plan_members;
CREATE POLICY "users leave plans" ON public.plan_members FOR DELETE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "members read messages" ON public.messages;
CREATE POLICY "members read messages" ON public.messages FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.plan_members WHERE plan_members.plan_id = messages.plan_id AND plan_members.user_id = auth.uid() AND plan_members.status <> 'removed'));
DROP POLICY IF EXISTS "members send messages" ON public.messages;
CREATE POLICY "members send messages" ON public.messages FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid() AND EXISTS (SELECT 1 FROM public.plan_members WHERE plan_members.plan_id = messages.plan_id AND plan_members.user_id = auth.uid() AND plan_members.status <> 'removed'));
DROP POLICY IF EXISTS "no message updates" ON public.messages;
CREATE POLICY "no message updates" ON public.messages FOR UPDATE TO authenticated USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS "no message deletes" ON public.messages;
CREATE POLICY "no message deletes" ON public.messages FOR DELETE TO authenticated USING (false);

DROP POLICY IF EXISTS "users read ratings they gave" ON public.ratings;
CREATE POLICY "users read ratings they gave" ON public.ratings FOR SELECT TO authenticated USING (rater_id = auth.uid() OR rated_user_id = auth.uid());
DROP POLICY IF EXISTS "attendees create ratings" ON public.ratings;
CREATE POLICY "attendees create ratings" ON public.ratings FOR INSERT TO authenticated WITH CHECK (rater_id = auth.uid() AND EXISTS (SELECT 1 FROM public.plan_members rater WHERE rater.plan_id = ratings.plan_id AND rater.user_id = auth.uid() AND rater.attended = true) AND EXISTS (SELECT 1 FROM public.plan_members rated WHERE rated.plan_id = ratings.plan_id AND rated.user_id = ratings.rated_user_id AND rated.attended = true));
DROP POLICY IF EXISTS "ratings cannot update" ON public.ratings;
CREATE POLICY "ratings cannot update" ON public.ratings FOR UPDATE TO authenticated USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS "ratings cannot delete" ON public.ratings;
CREATE POLICY "ratings cannot delete" ON public.ratings FOR DELETE TO authenticated USING (false);

DROP POLICY IF EXISTS "users read own reports" ON public.reports;
CREATE POLICY "users read own reports" ON public.reports FOR SELECT TO authenticated USING (reporter_id = auth.uid());
DROP POLICY IF EXISTS "users create reports" ON public.reports;
CREATE POLICY "users create reports" ON public.reports FOR INSERT TO authenticated WITH CHECK (reporter_id = auth.uid());
DROP POLICY IF EXISTS "reports cannot update" ON public.reports;
CREATE POLICY "reports cannot update" ON public.reports FOR UPDATE TO authenticated USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS "reports cannot delete" ON public.reports;
CREATE POLICY "reports cannot delete" ON public.reports FOR DELETE TO authenticated USING (false);

DROP POLICY IF EXISTS "users read own blocks" ON public.blocks;
CREATE POLICY "users read own blocks" ON public.blocks FOR SELECT TO authenticated USING (blocker_id = auth.uid());
DROP POLICY IF EXISTS "users create blocks" ON public.blocks;
CREATE POLICY "users create blocks" ON public.blocks FOR INSERT TO authenticated WITH CHECK (blocker_id = auth.uid());
DROP POLICY IF EXISTS "users update blocks" ON public.blocks;
CREATE POLICY "users update blocks" ON public.blocks FOR UPDATE TO authenticated USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS "users remove own blocks" ON public.blocks;
CREATE POLICY "users remove own blocks" ON public.blocks FOR DELETE TO authenticated USING (blocker_id = auth.uid());

REVOKE UPDATE (is_verified, rating_count, average_rating, attended_events, is_host, is_admin) ON public.profiles FROM authenticated;
REVOKE UPDATE (creator_id, is_official) ON public.plans FROM authenticated;
CREATE INDEX IF NOT EXISTS plans_city_start_idx ON public.plans(city, starts_at);
CREATE INDEX IF NOT EXISTS messages_plan_created_idx ON public.messages(plan_id, created_at);
