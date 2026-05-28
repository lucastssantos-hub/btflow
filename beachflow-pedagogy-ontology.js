(function (root) {
  "use strict";

  const phases = [
    ["serve", "Saque"],
    ["return", "Devolucao"],
    ["rally_entry", "Entrada no Rally"],
    ["development", "Desenvolvimento"],
    ["conversion", "Conversao"]
  ];

  const actions = [
    ["serve", "Saque"],
    ["lob", "Lob"],
    ["smash", "Smash"],
    ["hook", "Gancho"],
    ["volley", "Voleio"],
    ["short_ball", "Bola curta"],
    ["acceleration", "Aceleracao"],
    ["defense", "Defesa"],
    ["counter_lob", "Contra-lob"],
    ["return", "Devolucao"]
  ];

  const results = [
    ["point_won", "Ponto ganho"],
    ["continuity", "Continuidade"],
    ["forced_error", "Erro forcado"],
    ["unforced_error", "Erro nao forcado"],
    ["ball_given", "Bola entregue"],
    ["pressure_generated", "Pressao gerada"]
  ];

  const optionalContexts = [
    ["low_ball", "Bola baixa"],
    ["no_displacement", "Sem deslocamento"],
    ["after_lob", "Apos lob"],
    ["lateral_run", "Corrida lateral"],
    ["high_pressure", "Pressao alta"],
    ["balanced_opponent", "Adversario equilibrado"],
    ["short_ball", "Bola curta"]
  ];

  const executionDimensions = [
    { key: "timing", label: "Timing" },
    { key: "base", label: "Base" },
    { key: "contact", label: "Contato" },
    { key: "direction", label: "Direcao" },
    { key: "balance", label: "Equilibrio" }
  ];

  const canonicalProblems = [
    {
      phase: "development",
      observed_action: "smash",
      observed_result: "unforced_error",
      inferred_behavior: "Conversao precipitada",
      pedagogical_goal: "Criar vantagem antes de acelerar.",
      initial_format: "Semiaberto",
      observable_criteria: "O aluno so acelera quando a bola deixa o adversario deslocado ou atrasado.",
      regression: "Modo fechado: bola alta controlada e alvo grande antes de liberar ponto.",
      progression: "Rally livre com smash permitido apenas apos deslocamento adversario.",
      bonus_rule: "+1 ponto apenas se a finalizacao vier depois de vantagem criada.",
      dynamic: "Rally livre com aceleracao permitida somente apos bola curta ou adversario deslocado.",
      teacher_focus: "Observar se a aceleracao nasce de oportunidade ou ansiedade.",
      decision_quality: "incorrect"
    },
    {
      phase: "rally_entry",
      observed_action: "return",
      observed_result: "ball_given",
      inferred_behavior: "Falha na reorganizacao pos-devolucao",
      pedagogical_goal: "Devolver e recuperar base antes da terceira bola.",
      initial_format: "Fechado",
      observable_criteria: "Depois da devolucao, a dupla fecha o centro e recupera profundidade.",
      regression: "Devolucao profunda sem ponto; professor cobra recuperacao de base.",
      progression: "Devolucao + terceira bola viva com pontuacao.",
      bonus_rule: "+1 ponto se a devolucao entrar funda e a dupla recuperar posicao.",
      dynamic: "Devolucao obrigatoria seguida de cobertura do centro antes do rally livre.",
      teacher_focus: "Observar se a devolucao termina a acao ou organiza a proxima bola.",
      decision_quality: "incorrect"
    },
    {
      phase: "development",
      observed_action: "lob",
      observed_result: "continuity",
      inferred_behavior: "Defesa sem transicao para controle",
      pedagogical_goal: "Ganhar tempo e transformar defesa em controle.",
      initial_format: "Semiaberto",
      observable_criteria: "Apos o lob, a dupla avanca ou reorganiza sem entregar a bola seguinte.",
      regression: "Lob profundo com recuperacao marcada por cones.",
      progression: "Lob + bola neutra + decisao livre.",
      bonus_rule: "+1 ponto quando o lob gera tempo e a dupla recupera centro.",
      dynamic: "Comecar em pressao; lob profundo so vale se houver recuperacao de base.",
      teacher_focus: "Observar se o lob so sobrevive ou se devolve controle ao ponto.",
      decision_quality: "correct"
    },
    {
      phase: "conversion",
      observed_action: "smash",
      observed_result: "continuity",
      inferred_behavior: "Tentativa de definicao sem vantagem consolidada",
      pedagogical_goal: "Finalizar somente quando a vantagem estiver clara.",
      initial_format: "Aberto",
      observable_criteria: "A dupla reconhece bola verde antes de tentar definir.",
      regression: "Professor alterna bola verde e bola neutra; aluno precisa chamar a decisao antes de bater.",
      progression: "Ponto aberto com bonus apenas para finalizacao contextual.",
      bonus_rule: "+1 ponto se a dupla nomear a bola certa antes de finalizar.",
      dynamic: "Jogo condicionado: finalizacao antecipada nao recebe bonus.",
      teacher_focus: "Observar se o aluno define por leitura ou por habito.",
      decision_quality: "incorrect"
    },
    {
      phase: "development",
      observed_action: "acceleration",
      observed_result: "unforced_error",
      inferred_behavior: "Aceleracao em desvantagem",
      pedagogical_goal: "Neutralizar antes de acelerar.",
      initial_format: "Fechado",
      observable_criteria: "Em bola baixa ou corrida lateral, o aluno escolhe margem antes de potencia.",
      regression: "Sequencia fixa: defesa com margem, recuperacao, bola de construcao.",
      progression: "Liberar aceleracao apenas na terceira bola da sequencia.",
      bonus_rule: "+1 ponto quando evita acelerar bola baixa ou desequilibrada.",
      dynamic: "Professor mistura bola baixa e bola vulneravel; aluno so acelera a vulneravel.",
      teacher_focus: "Observar se a aceleracao aparece com base ou em fuga.",
      decision_quality: "incorrect"
    },
    {
      phase: "development",
      observed_action: "short_ball",
      observed_result: "pressure_generated",
      inferred_behavior: "Construcao curta eficiente",
      pedagogical_goal: "Usar a curta para tirar conforto antes de atacar.",
      initial_format: "Aberto",
      observable_criteria: "A curta desloca o adversario e a dupla ocupa o espaco seguinte.",
      regression: "Curta com alvo largo e recuperacao obrigatoria.",
      progression: "Curta + interceptacao ou pressao na bola seguinte.",
      bonus_rule: "+1 ponto se a curta gerar deslocamento antes da pressao.",
      dynamic: "Rally livre; bonus quando a curta cria a bola de ataque.",
      teacher_focus: "Observar se a curta e uma construcao ou uma bola entregue.",
      decision_quality: "correct"
    },
    {
      phase: "return",
      observed_action: "return",
      observed_result: "pressure_generated",
      inferred_behavior: "Devolucao que quebra a terceira bola",
      pedagogical_goal: "Devolver com profundidade e preparar cobertura.",
      initial_format: "Aberto",
      observable_criteria: "A devolucao tira tempo e a dupla protege o centro.",
      regression: "Devolucao profunda sem pressa de atacar.",
      progression: "Devolucao profunda + terceira bola viva.",
      bonus_rule: "+1 ponto se a devolucao reduzir a qualidade da terceira bola.",
      dynamic: "Game iniciado pelo saque; bonus para devolucao profunda com cobertura.",
      teacher_focus: "Observar se a devolucao so entra ou se organiza a dupla.",
      decision_quality: "correct"
    },
    {
      phase: "serve",
      observed_action: "serve",
      observed_result: "pressure_generated",
      inferred_behavior: "Saque preparando terceira bola",
      pedagogical_goal: "Servir para manipular a devolucao.",
      initial_format: "Semiaberto",
      observable_criteria: "O saque gera devolucao previsivel e a dupla prepara a terceira bola.",
      regression: "Saque com alvo grande e recuperacao obrigatoria.",
      progression: "Saque + terceira bola com ponto vivo.",
      bonus_rule: "+1 ponto se o saque preparar a terceira bola, nao apenas entrar.",
      dynamic: "Saque no alvo combinado e terceira bola jogada com intencao.",
      teacher_focus: "Observar se o saque cria contexto ou apenas inicia o ponto.",
      decision_quality: "correct"
    },
    {
      phase: "conversion",
      observed_action: "smash",
      observed_result: "point_won",
      inferred_behavior: "Conversao bem reconhecida",
      pedagogical_goal: "Manter finalizacao com equilibrio e cobertura.",
      initial_format: "Aberto",
      observable_criteria: "Depois de definir, a dupla ainda cobre possivel resposta.",
      regression: "Bola verde controlada com alvo amplo.",
      progression: "Ponto aberto com placar e consequencia.",
      bonus_rule: "+1 ponto se a finalizacao vier com recuperacao de cobertura.",
      dynamic: "Jogo livre; bonus quando a bola verde e convertida sem perder organizacao.",
      teacher_focus: "Observar se a finalizacao fecha o ponto sem desorganizar a dupla.",
      decision_quality: "correct"
    },
    {
      phase: "development",
      observed_action: "defense",
      observed_result: "ball_given",
      inferred_behavior: "Perda de iniciativa apos defesa",
      pedagogical_goal: "Defender com profundidade para voltar ao ponto.",
      initial_format: "Fechado",
      observable_criteria: "A defesa passa a rede com margem e compra tempo para recuperar.",
      regression: "Defesa alta profunda com recuperacao marcada.",
      progression: "Defesa + bola neutra + rally livre.",
      bonus_rule: "+1 ponto se a defesa gerar tempo real de recuperacao.",
      dynamic: "Comecar pressionado; ponto so abre depois da defesa profunda.",
      teacher_focus: "Observar se a defesa entrega o ponto ou reorganiza a dupla.",
      decision_quality: "incorrect"
    }
  ];

  function findExact(input) {
    return canonicalProblems.find(function (row) {
      return row.phase === input.phase &&
        row.observed_action === input.action &&
        row.observed_result === input.result;
    });
  }

  function findFallback(input) {
    return canonicalProblems.find(function (row) {
      return row.phase === input.phase &&
        row.observed_action === input.action;
    }) || canonicalProblems.find(function (row) {
      return row.observed_action === input.action &&
        row.observed_result === input.result;
    }) || canonicalProblems[0];
  }

  function confidenceFor(exact, input, history) {
    const samePattern = (history || []).filter(function (item) {
      return item.phase === input.phase &&
        item.action === input.action &&
        item.result === input.result;
    }).length;
    return Math.min(0.95, (exact ? 0.74 : 0.56) + Math.min(0.18, samePattern * 0.04));
  }

  function evaluateExpress(input) {
    const data = input || {};
    if (!data.phase || !data.action || !data.result) return null;
    const exact = findExact(data);
    const row = exact || findFallback(data);
    const correctDecision = row.decision_quality === "correct";
    const executionOnly = correctDecision && data.result === "unforced_error";
    return Object.assign({}, row, {
      exact_match: Boolean(exact),
      point_phase: data.phase,
      observed_action: data.action,
      observed_result: data.result,
      optional_context: data.context || "",
      confidence: confidenceFor(Boolean(exact), data, data.history),
      correctDecision: correctDecision,
      needsExecutionCheck: executionOnly,
      objective: row.pedagogical_goal,
      bonusRule: row.bonus_rule,
      dynamic: row.dynamic,
      teacherFocus: executionOnly
        ? "Boa leitura primeiro. Depois observar a execucao tecnica que quebrou a acao."
        : row.teacher_focus,
      studentPositive: correctDecision
        ? "Voce reconheceu bem a situacao em alguns momentos."
        : "Voce compete e tenta resolver o ponto.",
      studentLimiter: correctDecision
        ? "O limite principal agora esta na execucao da escolha."
        : row.pedagogical_goal,
      studentNextFocus: row.observable_criteria
    });
  }

  function studentFeedback(result) {
    if (!result) return "";
    return [
      "O que faz bem: " + result.studentPositive,
      "Principal limitador: " + result.studentLimiter,
      "Foco da proxima aula: " + result.studentNextFocus
    ].join("\n\n");
  }

  root.BEACHFLOW_PEDAGOGY_ONTOLOGY = {
    phases: phases,
    actions: actions,
    results: results,
    optionalContexts: optionalContexts,
    canonicalProblems: canonicalProblems,
    executionDimensions: executionDimensions,
    evaluateExpress: evaluateExpress,
    studentFeedback: studentFeedback
  };
})(typeof window !== "undefined" ? window : globalThis);
