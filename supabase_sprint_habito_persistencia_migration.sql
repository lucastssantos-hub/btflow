-- BTFlow - Sprint de Habito e Persistencia
-- Execute uma vez no SQL Editor do Supabase.
-- Escopo: autoavaliacao entre dispositivos e eventos minimos de uso.

create extension if not exists "pgcrypto";

create table if not exists public.self_assess_tokens (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  token text not null unique,
  used_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (teacher_id, student_id)
);

-- Atualiza instalações que já tinham a tabela criada em uma versão anterior.
alter table public.self_assess_tokens
  add column if not exists used_at timestamptz;

alter table public.self_assess_tokens
  add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_self_assess_tokens_token
  on public.self_assess_tokens (token);

-- Versões anteriores não tinham a unicidade necessária ao ON CONFLICT da RPC.
-- Se houver mais de um token para o mesmo aluno, preserva o registro mais recente.
delete from public.self_assess_tokens older
using public.self_assess_tokens newer
where older.teacher_id = newer.teacher_id
  and older.student_id = newer.student_id
  and (
    older.created_at < newer.created_at
    or (older.created_at = newer.created_at and older.id < newer.id)
  );

create unique index if not exists uq_self_assess_tokens_teacher_student
  on public.self_assess_tokens (teacher_id, student_id);

alter table public.self_assess_tokens enable row level security;

drop policy if exists "self_assess_tokens_teacher" on public.self_assess_tokens;
create policy "self_assess_tokens_teacher" on public.self_assess_tokens for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

-- Pode existir uma versao anterior dessas RPCs com outro tipo de retorno.
-- Remover apenas a funcao permite recria-la sem apagar tokens ou avaliacoes.
drop function if exists public.register_self_assess_token(uuid, text, uuid);
drop function if exists public.save_self_assessment(text, jsonb);

create or replace function public.register_self_assess_token(
  p_student_id uuid,
  p_token text,
  p_teacher_id uuid
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_teacher_id then
    raise exception 'Apenas o professor autenticado pode enviar autoavaliacao';
  end if;

  if not exists (
    select 1 from public.students
    where id = p_student_id and teacher_id = p_teacher_id
  ) then
    raise exception 'Aluno nao pertence ao professor';
  end if;

  insert into public.self_assess_tokens (teacher_id, student_id, token, used_at, updated_at)
  values (p_teacher_id, p_student_id, p_token, null, now())
  on conflict (teacher_id, student_id)
  do update set token = excluded.token, used_at = null, updated_at = now();

  return true;
end;
$$;

create or replace function public.save_self_assessment(
  p_token text,
  p_scores jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token public.self_assess_tokens%rowtype;
  v_item record;
begin
  select * into v_token
  from public.self_assess_tokens
  where token = p_token
  for update;

  if not found then
    raise exception 'Link de autoavaliacao invalido';
  end if;

  if v_token.used_at is not null then
    raise exception 'Esta autoavaliacao ja foi enviada';
  end if;

  for v_item in select key, value from jsonb_each_text(p_scores)
  loop
    if (v_item.value)::numeric < 0 or (v_item.value)::numeric > 10 then
      raise exception 'Nota invalida';
    end if;
    insert into public.evaluations (teacher_id, student_id, evaluator, fundamental, score)
    values (v_token.teacher_id, v_token.student_id, 'student_blind', v_item.key, (v_item.value)::numeric);
  end loop;

  update public.self_assess_tokens
  set used_at = now(), updated_at = now()
  where id = v_token.id;

  return jsonb_build_object('ok', true, 'student_id', v_token.student_id);
end;
$$;

revoke execute on function public.register_self_assess_token(uuid, text, uuid) from public;
revoke execute on function public.register_self_assess_token(uuid, text, uuid) from anon;
grant execute on function public.register_self_assess_token(uuid, text, uuid) to authenticated;

revoke execute on function public.save_self_assessment(text, jsonb) from public;
grant execute on function public.save_self_assessment(text, jsonb) to anon, authenticated;

create table if not exists public.usage_events (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  event_name text not null,
  session_key text,
  properties jsonb not null default '{}'::jsonb,
  duration_ms integer,
  touch_count integer,
  created_at timestamptz not null default now()
);

create index if not exists idx_usage_events_teacher_created
  on public.usage_events (teacher_id, created_at desc);
create index if not exists idx_usage_events_name_created
  on public.usage_events (event_name, created_at desc);

alter table public.usage_events enable row level security;

drop policy if exists "usage_events_teacher" on public.usage_events;
create policy "usage_events_teacher" on public.usage_events for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

-- Consulta util para a reuniao de validacao:
-- select event_name, count(*) as total,
--        round(avg(duration_ms)) as tempo_medio_ms,
--        round(avg(touch_count), 1) as toques_medios
-- from public.usage_events
-- group by event_name order by total desc;
