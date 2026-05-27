-- BTFlow - Ontologia Canonica MVP / Arvore 01
-- Execute somente apos as migracoes base e de persistencia.
-- Escopo: Contexto -> Decisao -> Resultado -> Execucao, Cartao de Foco e aprendizagem.
-- Nao cria biblioteca de exercicios e nao altera scouts/avaliacoes existentes.

create extension if not exists "pgcrypto";

-- Catalogos canonicos. Sao dados de referencia, sem informacao sensivel.
create table if not exists public.pedagogy_trees (
  key text primary key,
  name text not null,
  version text not null,
  description text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.pedagogy_contexts (
  key text primary key,
  label text not null,
  rank int not null,
  description text not null
);

create table if not exists public.pedagogy_decisions (
  key text primary key,
  label text not null,
  description text not null
);

create table if not exists public.pedagogy_execution_dimensions (
  key text primary key,
  label text not null,
  description text not null
);

create table if not exists public.pedagogy_tree_rules (
  id uuid primary key default gen_random_uuid(),
  tree_key text not null references public.pedagogy_trees(key) on delete cascade,
  context_key text not null references public.pedagogy_contexts(key),
  decision_key text not null references public.pedagogy_decisions(key),
  ideal_decision_key text not null references public.pedagogy_decisions(key),
  coherent boolean not null,
  feedback text not null,
  focus_title text not null,
  observe_text text not null,
  dynamic_text text not null,
  question_text text,
  progression_text text,
  unique (tree_key, context_key, decision_key)
);

-- Registro observavel: guarda a leitura feita em quadra, nao a aula inteira.
create table if not exists public.pedagogy_observations (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid references public.students(id) on delete set null,
  class_id uuid references public.classes(id) on delete set null,
  session_id uuid references public.class_sessions(id) on delete set null,
  scout_match_id uuid references public.scout_matches(id) on delete set null,
  tree_key text not null references public.pedagogy_trees(key),
  context_key text not null references public.pedagogy_contexts(key),
  decision_key text not null references public.pedagogy_decisions(key),
  result_key text check (result_key in ('success','error')),
  execution_dimension_key text references public.pedagogy_execution_dimensions(key),
  execution_error boolean,
  coherent boolean not null,
  learning_stage text check (learning_stage in ('aquisicao','estabilizacao','transferencia','pressao')),
  diagnostic_text text,
  trigger_text text,
  adjustment_text text,
  source text not null default 'focus_card'
    check (source in ('focus_card','scout','manual')),
  notes text,
  created_at timestamptz not null default now()
);

-- Snapshot do cartao: preserva exatamente o que foi exibido ao professor.
create table if not exists public.focus_cards (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  observation_id uuid references public.pedagogy_observations(id) on delete set null,
  student_id uuid references public.students(id) on delete set null,
  class_id uuid references public.classes(id) on delete set null,
  session_id uuid references public.class_sessions(id) on delete set null,
  tree_key text not null references public.pedagogy_trees(key),
  focus_title text not null,
  attention_text text not null,
  dynamic_text text not null,
  learning_stage text check (learning_stage in ('aquisicao','estabilizacao','transferencia','pressao')),
  trigger_text text,
  adjustment_text text,
  status text not null default 'active'
    check (status in ('active','applied','archived')),
  viewed_at timestamptz,
  created_at timestamptz not null default now()
);

-- O estagio pode pertencer a um aluno OU a uma turma em cada arvore.
create table if not exists public.learning_states (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  tree_key text not null references public.pedagogy_trees(key),
  student_id uuid references public.students(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  stage text not null
    check (stage in ('aquisicao','estabilizacao','transferencia','pressao')),
  evidence_source text not null default 'teacher'
    check (evidence_source in ('teacher','scout','focus_card')),
  notes text,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check (num_nonnulls(student_id, class_id) = 1)
);

-- Atualiza projetos onde a primeira versao da ontologia ja foi executada.
alter table public.pedagogy_observations
  add column if not exists result_key text check (result_key in ('success','error'));
alter table public.pedagogy_observations
  add column if not exists learning_stage text check (learning_stage in ('aquisicao','estabilizacao','transferencia','pressao'));
alter table public.pedagogy_observations
  add column if not exists diagnostic_text text;
alter table public.pedagogy_observations
  add column if not exists trigger_text text;
alter table public.pedagogy_observations
  add column if not exists adjustment_text text;

alter table public.focus_cards
  add column if not exists learning_stage text check (learning_stage in ('aquisicao','estabilizacao','transferencia','pressao'));
alter table public.focus_cards
  add column if not exists trigger_text text;
alter table public.focus_cards
  add column if not exists adjustment_text text;

create unique index if not exists ux_learning_state_student_tree
  on public.learning_states (teacher_id, student_id, tree_key)
  where student_id is not null;
create unique index if not exists ux_learning_state_class_tree
  on public.learning_states (teacher_id, class_id, tree_key)
  where class_id is not null;
create index if not exists idx_pedagogy_observations_teacher_created
  on public.pedagogy_observations (teacher_id, created_at desc);
create index if not exists idx_focus_cards_teacher_created
  on public.focus_cards (teacher_id, created_at desc);

insert into public.pedagogy_trees (key, name, version, description)
values (
  'construction_finalization',
  'Construcao vs Finalizacao',
  '2.0.0',
  'Leitura rapida de contexto, decisao e resultado para priorizar leitura antes da execucao e orientar progressao pedagogica.'
)
on conflict (key) do update set
  name = excluded.name,
  version = excluded.version,
  description = excluded.description,
  active = true;

insert into public.pedagogy_contexts (key, label, rank, description) values
  ('disadvantage', 'Desvantagem', 1, 'A dupla precisa ganhar tempo e recuperar organizacao.'),
  ('neutral', 'Neutro', 2, 'O ponto exige construcao antes da aceleracao.'),
  ('advantage', 'Vantagem', 3, 'Existe permissao contextual para pressionar ou finalizar.')
on conflict (key) do update set label=excluded.label, rank=excluded.rank, description=excluded.description;

insert into public.pedagogy_decisions (key, label, description) values
  ('recover', 'Recuperou', 'Ganhar tempo e reorganizar posicao.'),
  ('construct', 'Construiu', 'Criar vantagem sem finalizar cedo demais.'),
  ('finish', 'Finalizou', 'Pressionar ou encerrar em contexto favoravel.')
on conflict (key) do update set label=excluded.label, description=excluded.description;

insert into public.pedagogy_execution_dimensions (key, label, description) values
  ('technique', 'Tecnica', 'Mecanica geral da execucao.'),
  ('timing', 'Timing', 'Momento de contato e tempo da acao.'),
  ('base', 'Base', 'Apoio, deslocamento e sustentacao corporal.'),
  ('contact', 'Contato', 'Ponto de contato e estabilidade da face.'),
  ('direction', 'Direcao', 'Alvo ou direcao selecionada.'),
  ('balance', 'Equilibrio', 'Controle corporal antes e apos a acao.')
on conflict (key) do update set label=excluded.label, description=excluded.description;

insert into public.pedagogy_tree_rules
  (tree_key, context_key, decision_key, ideal_decision_key, coherent, feedback, focus_title, observe_text, dynamic_text, question_text, progression_text)
values
  ('construction_finalization','disadvantage','recover','recover',true,
   'Boa leitura. Primeiro reorganizar, depois voltar a construir.',
   'Recuperar para voltar a construir.',
   'Observe se recupera base e cobertura antes de arriscar.',
   'Bola profunda inicial; bonus ao recuperar o centro antes do rali livre.',
   'Apos recuperar, qual bola liberou a construcao?',
   'Aumentar velocidade da segunda bola.'),
  ('construction_finalization','disadvantage','construct','recover',false,
   'Tentou construir ainda em pressao. Primeiro precisa recuperar tempo e posicao.',
   'Recuperar antes de construir.',
   'Observe se tenta direcionar a bola ainda desequilibrado.',
   'Iniciar em pressao; so liberar construcao apos lob ou gancho com recuperacao.',
   'Voce ja havia recuperado o ponto?',
   'Variar a bola de recuperacao.'),
  ('construction_finalization','disadvantage','finish','recover',false,
   'Esta acelerando sem vantagem. O problema nao e o golpe, e a leitura da situacao.',
   'Recuperar antes de acelerar.',
   'Observe se tenta definir ainda recuado ou desequilibrado.',
   'Em desvantagem, bonus por ganhar tempo e reorganizar.',
   'Essa bola pedia ataque ou sobrevivencia?',
   'Liberar pressao somente apos recuperar a zona neutra.'),
  ('construction_finalization','neutral','recover','construct',false,
   'Excesso de seguranca no neutro. Havia espaco para construir vantagem.',
   'Assumir a construcao.',
   'Observe se devolve margem sem tentar criar desconforto.',
   'Rali neutro; bonus ao direcionar bola que abra espaco antes do ataque.',
   'Qual opcao criava vantagem sem arriscar demais?',
   'Diminuir o alvo de construcao.'),
  ('construction_finalization','neutral','construct','construct',true,
   'Boa decisao. Manteve o ponto vivo e preparou a proxima bola.',
   'Construir a bola de ataque.',
   'Observe se cria vantagem sem antecipar a finalizacao.',
   'Ponto bonus quando constroi antes de acelerar.',
   'Qual sinal mostrou que o ponto ficou ofensivo?',
   'Depois da construcao, liberar uma bola vulneravel.'),
  ('construction_finalization','neutral','finish','construct',false,
   'Finalizacao precoce. O aluno tentou ganhar o ponto antes de construir vantagem.',
   'Construir antes de acelerar.',
   'Observe se tenta winner em bola ainda neutra.',
   'Rali iniciado neutro; finalizacao so pontua depois de uma acao de construcao.',
   'O que faltou criar antes de acelerar?',
   'Variar altura da bola neutra.'),
  ('construction_finalization','advantage','recover','finish',false,
   'Excesso de seguranca. O aluno evitou assumir a vantagem.',
   'Reconhecer e assumir a vantagem.',
   'Observe se recua quando a bola permite pressao.',
   'Bola vulneravel; bonus por pressionar com equilibrio e recompor.',
   'Qual sinal liberava a pressao?',
   'Reduzir o tempo disponivel na bola ofensiva.'),
  ('construction_finalization','advantage','construct','finish',false,
   'Tinha chance de pressionar, mas manteve o ponto neutro.',
   'Converter vantagem em pressao.',
   'Observe se prolonga a construcao mesmo com bola favoravel.',
   'Bola verde controlada; bonus ao pressionar sem perder base.',
   'A construcao ainda era necessaria?',
   'Alternar bola para pressao e bola para controle.'),
  ('construction_finalization','advantage','finish','finish',true,
   'Boa decisao. O aluno reconheceu a chance de pressionar.',
   'Finalizar com equilibrio.',
   'Observe se acelera apenas na bola vulneravel e cobre a resposta.',
   'Bola em vantagem; bonus por finalizar e recompor posicao.',
   'O que tornou esta bola finalizavel?',
   'Variar direcao da bola favoravel.')
on conflict (tree_key, context_key, decision_key) do update set
  ideal_decision_key=excluded.ideal_decision_key,
  coherent=excluded.coherent,
  feedback=excluded.feedback,
  focus_title=excluded.focus_title,
  observe_text=excluded.observe_text,
  dynamic_text=excluded.dynamic_text,
  question_text=excluded.question_text,
  progression_text=excluded.progression_text;

alter table public.pedagogy_trees enable row level security;
alter table public.pedagogy_contexts enable row level security;
alter table public.pedagogy_decisions enable row level security;
alter table public.pedagogy_execution_dimensions enable row level security;
alter table public.pedagogy_tree_rules enable row level security;
alter table public.pedagogy_observations enable row level security;
alter table public.focus_cards enable row level security;
alter table public.learning_states enable row level security;

drop policy if exists "pedagogy_trees_read" on public.pedagogy_trees;
create policy "pedagogy_trees_read" on public.pedagogy_trees for select using (true);
drop policy if exists "pedagogy_contexts_read" on public.pedagogy_contexts;
create policy "pedagogy_contexts_read" on public.pedagogy_contexts for select using (true);
drop policy if exists "pedagogy_decisions_read" on public.pedagogy_decisions;
create policy "pedagogy_decisions_read" on public.pedagogy_decisions for select using (true);
drop policy if exists "pedagogy_execution_dimensions_read" on public.pedagogy_execution_dimensions;
create policy "pedagogy_execution_dimensions_read" on public.pedagogy_execution_dimensions for select using (true);
drop policy if exists "pedagogy_tree_rules_read" on public.pedagogy_tree_rules;
create policy "pedagogy_tree_rules_read" on public.pedagogy_tree_rules for select using (true);

drop policy if exists "pedagogy_observations_teacher" on public.pedagogy_observations;
create policy "pedagogy_observations_teacher" on public.pedagogy_observations for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
drop policy if exists "focus_cards_teacher" on public.focus_cards;
create policy "focus_cards_teacher" on public.focus_cards for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
drop policy if exists "learning_states_teacher" on public.learning_states;
create policy "learning_states_teacher" on public.learning_states for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
