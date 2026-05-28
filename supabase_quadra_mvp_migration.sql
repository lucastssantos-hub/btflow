-- BeachFlow Sprint Quadra MVP
-- Matriz canonica operacional: professor registra fatos observaveis; motor infere comportamento.

create extension if not exists "pgcrypto";

-- Tabela solicitada pelo MVP. Em instalacoes antigas, scout_points ja existe;
-- por isso a migracao e aditiva e nao destrutiva.
alter table public.scout_points
  add column if not exists point_phase text,
  add column if not exists observed_action text,
  add column if not exists observed_result text,
  add column if not exists optional_context text,
  add column if not exists inferred_behavior text,
  add column if not exists confidence numeric(3,2);

create table if not exists public.canonical_problems (
  id uuid primary key default gen_random_uuid(),

  point_phase text not null,
  observed_action text not null,
  observed_result text not null,

  inferred_behavior text not null,

  pedagogical_goal text not null,
  initial_format text not null,
  observable_criteria text not null,

  regression text,
  progression text,

  bonus_rule text,
  dynamic_text text,
  teacher_focus text,
  decision_quality text not null default 'unknown'
    check (decision_quality in ('correct','incorrect','unknown')),

  created_at timestamptz default now(),
  unique (point_phase, observed_action, observed_result)
);

insert into public.canonical_problems
  (point_phase, observed_action, observed_result, inferred_behavior, pedagogical_goal, initial_format, observable_criteria, regression, progression, bonus_rule, dynamic_text, teacher_focus, decision_quality)
values
  ('development','smash','unforced_error','Conversao precipitada','Criar vantagem antes de acelerar.','Semiaberto','O aluno so acelera quando a bola deixa o adversario deslocado ou atrasado.','Modo fechado: bola alta controlada e alvo grande antes de liberar ponto.','Rally livre com smash permitido apenas apos deslocamento adversario.','+1 ponto apenas se a finalizacao vier depois de vantagem criada.','Rally livre com aceleracao permitida somente apos bola curta ou adversario deslocado.','Observar se a aceleracao nasce de oportunidade ou ansiedade.','incorrect'),
  ('rally_entry','return','ball_given','Falha na reorganizacao pos-devolucao','Devolver e recuperar base antes da terceira bola.','Fechado','Depois da devolucao, a dupla fecha o centro e recupera profundidade.','Devolucao profunda sem ponto; professor cobra recuperacao de base.','Devolucao + terceira bola viva com pontuacao.','+1 ponto se a devolucao entrar funda e a dupla recuperar posicao.','Devolucao obrigatoria seguida de cobertura do centro antes do rally livre.','Observar se a devolucao termina a acao ou organiza a proxima bola.','incorrect'),
  ('development','lob','continuity','Defesa sem transicao para controle','Ganhar tempo e transformar defesa em controle.','Semiaberto','Apos o lob, a dupla avanca ou reorganiza sem entregar a bola seguinte.','Lob profundo com recuperacao marcada por cones.','Lob + bola neutra + decisao livre.','+1 ponto quando o lob gera tempo e a dupla recupera centro.','Comecar em pressao; lob profundo so vale se houver recuperacao de base.','Observar se o lob so sobrevive ou se devolve controle ao ponto.','correct'),
  ('conversion','smash','continuity','Tentativa de definicao sem vantagem consolidada','Finalizar somente quando a vantagem estiver clara.','Aberto','A dupla reconhece bola verde antes de tentar definir.','Professor alterna bola verde e bola neutra; aluno precisa chamar a decisao antes de bater.','Ponto aberto com bonus apenas para finalizacao contextual.','+1 ponto se a dupla nomear a bola certa antes de finalizar.','Jogo condicionado: finalizacao antecipada nao recebe bonus.','Observar se o aluno define por leitura ou por habito.','incorrect'),
  ('development','acceleration','unforced_error','Aceleracao em desvantagem','Neutralizar antes de acelerar.','Fechado','Em bola baixa ou corrida lateral, o aluno escolhe margem antes de potencia.','Sequencia fixa: defesa com margem, recuperacao, bola de construcao.','Liberar aceleracao apenas na terceira bola da sequencia.','+1 ponto quando evita acelerar bola baixa ou desequilibrada.','Professor mistura bola baixa e bola vulneravel; aluno so acelera a vulneravel.','Observar se a aceleracao aparece com base ou em fuga.','incorrect'),
  ('development','short_ball','pressure_generated','Construcao curta eficiente','Usar a curta para tirar conforto antes de atacar.','Aberto','A curta desloca o adversario e a dupla ocupa o espaco seguinte.','Curta com alvo largo e recuperacao obrigatoria.','Curta + interceptacao ou pressao na bola seguinte.','+1 ponto se a curta gerar deslocamento antes da pressao.','Rally livre; bonus quando a curta cria a bola de ataque.','Observar se a curta e uma construcao ou uma bola entregue.','correct'),
  ('return','return','pressure_generated','Devolucao que quebra a terceira bola','Devolver com profundidade e preparar cobertura.','Aberto','A devolucao tira tempo e a dupla protege o centro.','Devolucao profunda sem pressa de atacar.','Devolucao profunda + terceira bola viva.','+1 ponto se a devolucao reduzir a qualidade da terceira bola.','Game iniciado pelo saque; bonus para devolucao profunda com cobertura.','Observar se a devolucao so entra ou se organiza a dupla.','correct'),
  ('serve','serve','pressure_generated','Saque preparando terceira bola','Servir para manipular a devolucao.','Semiaberto','O saque gera devolucao previsivel e a dupla prepara a terceira bola.','Saque com alvo grande e recuperacao obrigatoria.','Saque + terceira bola com ponto vivo.','+1 ponto se o saque preparar a terceira bola, nao apenas entrar.','Saque no alvo combinado e terceira bola jogada com intencao.','Observar se o saque cria contexto ou apenas inicia o ponto.','correct'),
  ('conversion','smash','point_won','Conversao bem reconhecida','Manter finalizacao com equilibrio e cobertura.','Aberto','Depois de definir, a dupla ainda cobre possivel resposta.','Bola verde controlada com alvo amplo.','Ponto aberto com placar e consequencia.','+1 ponto se a finalizacao vier com recuperacao de cobertura.','Jogo livre; bonus quando a bola verde e convertida sem perder organizacao.','Observar se a finalizacao fecha o ponto sem desorganizar a dupla.','correct'),
  ('development','defense','ball_given','Perda de iniciativa apos defesa','Defender com profundidade para voltar ao ponto.','Fechado','A defesa passa a rede com margem e compra tempo para recuperar.','Defesa alta profunda com recuperacao marcada.','Defesa + bola neutra + rally livre.','+1 ponto se a defesa gerar tempo real de recuperacao.','Comecar pressionado; ponto so abre depois da defesa profunda.','Observar se a defesa entrega o ponto ou reorganiza a dupla.','incorrect')
on conflict (point_phase, observed_action, observed_result) do update set
  inferred_behavior=excluded.inferred_behavior,
  pedagogical_goal=excluded.pedagogical_goal,
  initial_format=excluded.initial_format,
  observable_criteria=excluded.observable_criteria,
  regression=excluded.regression,
  progression=excluded.progression,
  bonus_rule=excluded.bonus_rule,
  dynamic_text=excluded.dynamic_text,
  teacher_focus=excluded.teacher_focus,
  decision_quality=excluded.decision_quality;

-- Backfill dos scouts ja existentes.
-- Traduz registros antigos (technique/outcome/zone/intention) para a nova camada operacional.
update public.scout_points
set
  observed_action = coalesce(observed_action, case
    when coalesce(technique, shot, '') ilike '%saque%' then 'serve'
    when coalesce(technique, shot, '') ilike '%devolu%' then 'return'
    when coalesce(technique, shot, '') ilike '%lob%' then 'lob'
    when coalesce(technique, shot, '') ilike '%smash%' then 'smash'
    when coalesce(technique, shot, '') ilike '%gancho%' then 'hook'
    when coalesce(technique, shot, '') ilike '%voleio%' then 'volley'
    when coalesce(technique, shot, '') ilike '%curta%' then 'short_ball'
    when coalesce(technique, shot, '') ilike '%aceler%' then 'acceleration'
    when coalesce(technique, shot, '') ilike '%ventaglio%' then 'acceleration'
    when coalesce(technique, shot, '') ilike '%anôm%' then 'acceleration'
    when coalesce(technique, shot, '') ilike '%anom%' then 'acceleration'
    when coalesce(technique, shot, '') ilike '%tapa%' then 'acceleration'
    when coalesce(technique, shot, '') ilike '%defesa%' then 'defense'
    else 'defense'
  end),
  observed_result = coalesce(observed_result, case
    when coalesce(outcome, '') ilike '%winner%' then 'point_won'
    when coalesce(outcome, '') ilike '%ace%' then 'point_won'
    when coalesce(outcome, '') ilike '%forçou%' then 'pressure_generated'
    when coalesce(outcome, '') ilike '%forcou%' then 'pressure_generated'
    when coalesce(outcome, '') ilike '%erro%' then 'unforced_error'
    else 'continuity'
  end),
  optional_context = coalesce(optional_context, case
    when coalesce(zone, '') ilike '%vermelha%' then 'high_pressure'
    when coalesce(zone, '') ilike '%verde%' then 'short_ball'
    else null
  end),
  point_phase = coalesce(point_phase, case
    when coalesce(technique, shot, '') ilike '%saque%' then 'serve'
    when coalesce(technique, shot, '') ilike '%devolu%' then 'return'
    when coalesce(inferred_intention, '') ilike '%final%' then 'conversion'
    when coalesce(inferred_intention, '') ilike '%prepara%' then 'rally_entry'
    when coalesce(inferred_intention, '') ilike '%neut%' then 'rally_entry'
    else 'development'
  end),
  confidence = coalesce(confidence, 0.58)
where point_phase is null
   or observed_action is null
   or observed_result is null
   or confidence is null;

update public.scout_points sp
set inferred_behavior = coalesce(sp.inferred_behavior, cp.inferred_behavior)
from public.canonical_problems cp
where sp.point_phase = cp.point_phase
  and sp.observed_action = cp.observed_action
  and sp.observed_result = cp.observed_result
  and sp.inferred_behavior is null;

alter table public.canonical_problems enable row level security;

drop policy if exists "canonical_problems_read" on public.canonical_problems;
create policy "canonical_problems_read" on public.canonical_problems
  for select using (true);

create index if not exists idx_scout_points_operational
  on public.scout_points (point_phase, observed_action, observed_result);

create index if not exists idx_canonical_problems_lookup
  on public.canonical_problems (point_phase, observed_action, observed_result);
