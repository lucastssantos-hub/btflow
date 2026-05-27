(function (root) {
  "use strict";

  const learningStages = [
    { key: "aquisicao", label: "Aquisição" },
    { key: "estabilizacao", label: "Estabilização" },
    { key: "transferencia", label: "Transferência" },
    { key: "pressao", label: "Pressão" }
  ];

  const executionDimensions = [
    { key: "timing", label: "Timing" },
    { key: "base", label: "Base" },
    { key: "contact", label: "Contato" },
    { key: "direction", label: "Direção" },
    { key: "balance", label: "Equilíbrio" }
  ];

  const tree = {
    key: "construction_finalization",
    id: "tree_01",
    title: "Construção vs Finalização",
    version: "2.0.0",
    contexts: [
      ["disadvantage", "Desvantagem"],
      ["neutral", "Neutro"],
      ["advantage", "Vantagem"]
    ],
    decisions: [
      ["recover", "Recuperou"],
      ["construct", "Construiu"],
      ["finish", "Finalizou"]
    ],
    outcomes: [
      ["success", "Funcionou"],
      ["error", "Erro"]
    ],
    ideal: { disadvantage: "recover", neutral: "construct", advantage: "finish" },
    cases: {
      "disadvantage:recover": {
        ok: true,
        feedback: "Boa leitura. Primeiro reorganizar, depois voltar a construir.",
        focus: "Recuperar para voltar a construir.",
        observe: "Se recupera base e cobertura antes de arriscar.",
        dynamic: "Bola profunda inicial; bônus ao recuperar o centro antes do rali livre.",
        question: "Após recuperar, qual bola liberou a construção?",
        progression: "Aumentar velocidade da segunda bola."
      },
      "disadvantage:construct": {
        ok: false,
        feedback: "Tentou construir ainda em pressão. Primeiro precisa recuperar tempo e posição.",
        focus: "Recuperar antes de construir.",
        observe: "Se tenta direcionar a bola ainda desequilibrado.",
        dynamic: "Iniciar em pressão; só liberar construção após lob ou gancho com recuperação.",
        question: "Você já havia recuperado o ponto?",
        progression: "Variar a bola de recuperação."
      },
      "disadvantage:finish": {
        ok: false,
        feedback: "Está acelerando sem vantagem. O problema não é o golpe - é a leitura da situação.",
        focus: "Recuperar antes de acelerar.",
        observe: "Se tenta definir ainda recuado ou desequilibrado.",
        dynamic: "Em desvantagem, ponto bônus por ganhar tempo e reorganizar.",
        question: "Essa bola pedia ataque ou sobrevivência?",
        progression: "Liberar pressão somente após recuperar a zona neutra."
      },
      "neutral:recover": {
        ok: false,
        feedback: "Excesso de segurança no neutro. Havia espaço para construir vantagem.",
        focus: "Assumir a construção.",
        observe: "Se devolve margem sem tentar criar desconforto.",
        dynamic: "Rali neutro; bônus ao direcionar uma bola que abra espaço antes do ataque.",
        question: "Qual opção criava vantagem sem arriscar demais?",
        progression: "Diminuir o alvo de construção."
      },
      "neutral:construct": {
        ok: true,
        feedback: "Boa decisão. Manteve o ponto vivo e preparou a próxima bola.",
        focus: "Construir a bola de ataque.",
        observe: "Se cria vantagem sem antecipar a finalização.",
        dynamic: "Ponto bônus quando constrói antes de acelerar.",
        question: "Qual sinal mostrou que o ponto ficou ofensivo?",
        progression: "Depois da construção, liberar uma bola vulnerável."
      },
      "neutral:finish": {
        ok: false,
        feedback: "Finalização precoce. O aluno tentou ganhar o ponto antes de construir vantagem.",
        focus: "Construir antes de acelerar.",
        observe: "Se tenta winner em bola ainda neutra.",
        dynamic: "Finalização só pontua depois de uma ação de construção.",
        question: "O que faltou criar antes de acelerar?",
        progression: "Variar altura da bola neutra."
      },
      "advantage:recover": {
        ok: false,
        feedback: "Excesso de segurança. O aluno evitou assumir a vantagem.",
        focus: "Reconhecer e assumir a vantagem.",
        observe: "Se recua ou neutraliza quando a bola permite pressão.",
        dynamic: "Bola vulnerável; bônus por pressionar com equilíbrio e recuperar cobertura.",
        question: "Qual sinal liberava a pressão?",
        progression: "Reduzir o tempo disponível na bola ofensiva."
      },
      "advantage:construct": {
        ok: false,
        feedback: "Tinha chance de pressionar, mas manteve o ponto neutro.",
        focus: "Converter vantagem em pressão.",
        observe: "Se prolonga a construção mesmo com bola favorável.",
        dynamic: "Bola verde controlada; bônus ao pressionar sem perder base.",
        question: "A construção ainda era necessária?",
        progression: "Alternar bola para pressão e bola para controle."
      },
      "advantage:finish": {
        ok: true,
        feedback: "Boa decisão. O aluno reconheceu a chance de pressionar.",
        focus: "Finalizar com equilíbrio.",
        observe: "Se acelera apenas na bola vulnerável e cobre a resposta.",
        dynamic: "Bola em vantagem; bônus por finalizar e recompor posição.",
        question: "O que tornou esta bola finalizável?",
        progression: "Variar direção da bola favorável."
      }
    }
  };

  function countMatching(history, predicate) {
    return (history || []).filter(predicate).length;
  }

  function stageFor(rule, outcome, history, context, decision) {
    const repeatedReadingErrors = countMatching(history, function (item) {
      return item.context === context && item.decision === decision && item.ok === false;
    });
    const repeatedCorrectSuccess = countMatching(history, function (item) {
      return item.context === context && item.decision === decision &&
        item.ok === true && item.outcome === "success";
    });
    if (!rule.ok) {
      return {
        key: "aquisicao",
        label: "Aquisição",
        trigger: repeatedReadingErrors >= 2
          ? "Leitura incoerente recorrente. Regressão sugerida."
          : "Primeiro ajustar a leitura da situação.",
        adjustment: repeatedReadingErrors >= 2
          ? "Regredir para exercício fechado com contexto fixo."
          : "Repetir a situação com regra simples."
      };
    }
    if (outcome === "error") {
      return {
        key: "estabilizacao",
        label: "Estabilização",
        trigger: "Decisão correta, resultado com erro.",
        adjustment: "Manter a decisão e estabilizar a execução."
      };
    }
    if (outcome === "success" && repeatedCorrectSuccess >= 2) {
      return {
        key: "pressao",
        label: "Pressão",
        trigger: "Decisão correta repetida com resultado positivo.",
        adjustment: "Validar sob placar e pressão de tempo."
      };
    }
    return {
      key: "transferencia",
      label: "Transferência",
      trigger: "Decisão coerente aplicada com resultado positivo.",
      adjustment: "Levar a escolha para jogo condicionado."
    };
  }

  function evaluate(input) {
    const data = input || {};
    const rule = tree.cases[data.context + ":" + data.decision];
    if (!rule) return null;
    const outcome = data.outcome || "";
    const dimension = executionDimensions.find(function (item) {
      return item.key === data.executionIssue;
    });
    const stage = outcome ? stageFor(rule, outcome, data.history, data.context, data.decision) : null;
    const technicalError = rule.ok && outcome === "error";
    return Object.assign({}, rule, {
      treeId: tree.key,
      treeTitle: tree.title,
      context: data.context,
      decision: data.decision,
      outcome: outcome,
      idealDecision: tree.ideal[data.context],
      stage: stage,
      needsExecutionCheck: technicalError,
      executionLabel: dimension ? dimension.label : "",
      diagnostic: technicalError
        ? "A decisão foi correta. Agora o foco é execução."
        : rule.feedback,
      executionFeedback: technicalError && dimension
        ? "Foco de execução: " + dimension.label + "."
        : ""
    });
  }

  root.BEACHFLOW_PEDAGOGY_ONTOLOGY = {
    learningStages: learningStages,
    executionDimensions: executionDimensions,
    trees: { construction_finalization: tree },
    evaluate: evaluate
  };
})(typeof window !== "undefined" ? window : globalThis);
