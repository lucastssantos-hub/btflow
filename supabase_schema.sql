-- BeachFlow Supabase schema
-- Base para transformar o protótipo estático em app real com Auth + Postgres + RLS.

create extension if not exists "pgcrypto";

do $$ begin create type public.skill_level as enum ('iniciante','intermediario','avancado'); exception when duplicate_object then null; end $$;
do $$ begin create type public.payment_status as enum ('pendente','pago','atrasado'); exception when duplicate_object then null; end $$;
do $$ begin create type public.evaluator_type as enum ('teacher','student_blind'); exception when duplicate_object then null; end $$;
do $$ begin create type public.app_role as enum ('professor','aluno'); exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  level public.skill_level not null default 'iniciante',
  user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  level public.skill_level not null default 'iniciante',
  weekday int not null check (weekday between 0 and 6),
  start_time time not null,
  capacity int not null default 4 check (capacity > 0),
  focus_fundamental text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.class_enrollments (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (class_id, student_id)
);

create table if not exists public.class_sessions (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  session_date date not null,
  start_time time not null,
  focus_fundamental text,
  notes text,
  ai_drill_json jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (class_id, session_date)
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.class_sessions(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  present boolean not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (session_id, student_id)
);

create table if not exists public.class_confirmations (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references public.class_sessions(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  token text not null default encode(gen_random_bytes(16), 'hex'),
  status text not null default 'pending' check (status in ('pending','confirmed','declined')),
  sent_at timestamptz,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  unique (session_id, student_id),
  unique (token)
);

create table if not exists public.makeup_credits (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  source_class_id uuid references public.classes(id) on delete set null,
  source_session_id uuid references public.class_sessions(id) on delete set null,
  status text not null default 'open' check (status in ('open','invited','used','expired')),
  created_at timestamptz not null default now(),
  used_at timestamptz
);

create table if not exists public.evaluations (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  evaluator public.evaluator_type not null,
  fundamental text not null,
  score numeric(3,1) not null check (score >= 0 and score <= 10),
  created_at timestamptz not null default now()
);

create table if not exists public.scout_matches (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  format text not null default 'best3',
  mode text not null default 'live',
  team_a uuid[] not null,
  team_b uuid[] not null,
  games_a int not null default 0,
  games_b int not null default 0,
  points_a int not null default 0,
  points_b int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scout_points (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  match_id uuid not null references public.scout_matches(id) on delete cascade,
  server_id uuid not null references public.students(id) on delete cascade,
  finisher_id uuid not null references public.students(id) on delete cascade,
  outcome text not null,
  shot text not null default 'Decisão',
  zone text not null default 'Fundo',
  winner_team text not null check (winner_team in ('a','b')),
  score_label text,
  created_at timestamptz not null default now()
);

create table if not exists public.scout_events (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  class_id uuid references public.classes(id) on delete set null,
  match_id uuid references public.scout_matches(id) on delete set null,
  fundamental text not null,
  kind text not null check (kind in ('winner','error','decision','position')),
  score numeric(3,1) not null check (score >= 0 and score <= 10),
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  amount numeric(10,2) not null check (amount >= 0),
  due_date date not null,
  paid_at timestamptz,
  status public.payment_status not null default 'pendente',
  pix_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ops_feed (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('info','warning','waitlist','weather')),
  text text not null,
  resolved boolean not null default false,
  class_id uuid references public.classes(id) on delete set null,
  student_id uuid references public.students(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_drills (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  fundamental text not null,
  level text not null,
  prompt_hash text not null,
  payload_json jsonb not null,
  knowledge_version text,
  created_at timestamptz not null default now(),
  used_at timestamptz
);

create table if not exists public.ai_training_knowledge (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid references auth.users(id) on delete set null,
  class_id uuid references public.classes(id) on delete set null,
  fundamental text,
  level text,
  original_markdown text,
  edited_markdown text not null,
  lesson_summary text,
  approved boolean not null default true,
  created_at timestamptz not null default now()
);

create or replace function public.update_updated_at_column()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'name', split_part(new.email,'@',1)), new.raw_user_meta_data->>'avatar_url')
  on conflict (id) do nothing;
  insert into public.user_roles (user_id, role) values (new.id, 'professor')
  on conflict (user_id, role) do nothing;
  return new;
end;
$$;

create or replace function public.get_class_confirmation(p_token text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'token', cc.token,
    'status', cc.status,
    'student_name', s.name,
    'class_name', c.name,
    'session_date', cs.session_date,
    'start_time', to_char(cs.start_time, 'HH24:MI')
  )
  from public.class_confirmations cc
  join public.students s on s.id = cc.student_id
  join public.classes c on c.id = cc.class_id
  join public.class_sessions cs on cs.id = cc.session_id
  where cc.token = p_token
  limit 1;
$$;

create or replace function public.respond_class_confirmation(p_token text, p_status text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v public.class_confirmations%rowtype;
  v_class public.classes%rowtype;
  v_student public.students%rowtype;
begin
  if p_status not in ('confirmed', 'declined') then
    raise exception 'Status inválido';
  end if;

  select * into v
  from public.class_confirmations
  where token = p_token
  limit 1;

  if not found then
    raise exception 'Confirmação não encontrada';
  end if;

  update public.class_confirmations
  set status = p_status,
      responded_at = now()
  where id = v.id;

  insert into public.attendance (session_id, student_id, present)
  values (v.session_id, v.student_id, p_status = 'confirmed')
  on conflict (session_id, student_id)
  do update set present = excluded.present, updated_at = now();

  select * into v_class from public.classes where id = v.class_id;
  select * into v_student from public.students where id = v.student_id;

  if p_status = 'declined' then
    insert into public.makeup_credits (teacher_id, student_id, source_class_id, source_session_id, status)
    select v.teacher_id, v.student_id, v.class_id, v.session_id, 'open'
    where not exists (
      select 1
      from public.makeup_credits
      where student_id = v.student_id
        and source_session_id = v.session_id
    );

    insert into public.ops_feed (teacher_id, kind, text, resolved, class_id, student_id)
    values (
      v.teacher_id,
      'waitlist',
      coalesce(v_student.name, 'Aluno') || ' declinou a aula ' || to_char(v_class.start_time, 'HH24:MI') || '. Chamar alunos com reposição pendente.',
      false,
      v.class_id,
      v.student_id
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'status', p_status,
    'message', case
      when p_status = 'confirmed' then 'Presença confirmada e check-in registrado.'
      else 'Aula declinada. O professor foi avisado e a vaga foi liberada para reposição.'
    end
  );
end;
$$;

create or replace function public.ensure_class_confirmation(
  p_session_id uuid,
  p_class_id uuid,
  p_student_id uuid,
  p_teacher_id uuid
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
begin
  insert into public.class_confirmations (teacher_id, session_id, class_id, student_id, sent_at)
  values (p_teacher_id, p_session_id, p_class_id, p_student_id, now())
  on conflict (session_id, student_id)
  do update set sent_at = now();

  select token into v_token
  from public.class_confirmations
  where session_id = p_session_id and student_id = p_student_id;

  return v_token;
end;
$$;

grant execute on function public.get_class_confirmation(text) to anon, authenticated;
grant execute on function public.respond_class_confirmation(text, text) to anon, authenticated;
grant execute on function public.ensure_class_confirmation(uuid, uuid, uuid, uuid) to anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

do $$ declare t text; begin
  foreach t in array array['profiles','user_roles','students','classes','class_enrollments','class_sessions','attendance','class_confirmations','makeup_credits','evaluations','scout_matches','scout_points','scout_events','payments','ops_feed','ai_drills','ai_training_knowledge']
  loop execute format('alter table public.%I enable row level security', t); end loop;
end $$;

drop policy if exists "profiles_self" on public.profiles;
create policy "profiles_self" on public.profiles for all using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "roles_self" on public.user_roles;
create policy "roles_self" on public.user_roles for select using (user_id = auth.uid());

drop policy if exists "students_teacher" on public.students;
create policy "students_teacher" on public.students for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "students_self_read" on public.students;
create policy "students_self_read" on public.students for select using (user_id = auth.uid());

drop policy if exists "classes_teacher" on public.classes;
create policy "classes_teacher" on public.classes for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "enroll_teacher" on public.class_enrollments;
create policy "enroll_teacher" on public.class_enrollments for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "sessions_teacher" on public.class_sessions;
create policy "sessions_teacher" on public.class_sessions for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "eval_teacher" on public.evaluations;
create policy "eval_teacher" on public.evaluations for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "makeups_teacher" on public.makeup_credits;
create policy "makeups_teacher" on public.makeup_credits for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "confirmations_teacher" on public.class_confirmations;
create policy "confirmations_teacher" on public.class_confirmations for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

-- Permite que o aluno (anon) leia e responda a confirmação pelo token, sem precisar de login
drop policy if exists "confirmations_anon_by_token" on public.class_confirmations;
create policy "confirmations_anon_by_token" on public.class_confirmations
  for select using (true);

drop policy if exists "confirmations_anon_update" on public.class_confirmations;
create policy "confirmations_anon_update" on public.class_confirmations
  for update using (true) with check (true);

drop policy if exists "scout_matches_teacher" on public.scout_matches;
create policy "scout_matches_teacher" on public.scout_matches for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "scout_points_teacher" on public.scout_points;
create policy "scout_points_teacher" on public.scout_points for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "scout_events_teacher" on public.scout_events;
create policy "scout_events_teacher" on public.scout_events for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "payments_teacher" on public.payments;
create policy "payments_teacher" on public.payments for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "ops_teacher" on public.ops_feed;
create policy "ops_teacher" on public.ops_feed for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "ai_drills_teacher" on public.ai_drills;
create policy "ai_drills_teacher" on public.ai_drills for all using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists "ai_training_knowledge_read_approved" on public.ai_training_knowledge;
create policy "ai_training_knowledge_read_approved" on public.ai_training_knowledge for select using (approved = true);

drop policy if exists "ai_training_knowledge_insert_own" on public.ai_training_knowledge;
create policy "ai_training_knowledge_insert_own" on public.ai_training_knowledge for insert with check (teacher_id = auth.uid());
