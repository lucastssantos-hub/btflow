(function(root){
  "use strict";

  const norm = value => String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();

  const FUNDAMENTAL_ALIASES = {
    saque: ["saque", "servico"],
    devolucao: ["devolucao", "return", "recepcao"],
    tapa: ["tapa", "acelerada curta", "espetada"],
    bandeja: ["bandeja"],
    smash: ["smash"],
    forehand: ["forehand", "forehand de fundo", "four"],
    backhand: ["backhand", "backhand de fundo"],
    lob: ["lob", "contra-lob", "contralob"],
    gancho: ["gancho"],
    curta: ["curta", "bola curta"],
    consistencia: ["consistencia", "neutra"],
    posicionamento: ["posicionamento", "cobertura", "movimentacao"],
    decisao: ["decisao", "risco", "gestao de risco"]
  };

  const FUNDAMENTAL_LABEL = {
    saque: "Saque",
    devolucao: "Devolução",
    tapa: "Tapa",
    bandeja: "Bandeja",
    smash: "Smash",
    forehand: "Forehand",
    backhand: "Backhand",
    lob: "Lob",
    gancho: "Gancho",
    curta: "Curta",
    consistencia: "Consistência",
    posicionamento: "Posicionamento",
    decisao: "Decisão"
  };

  const RULES = {
    saque: {
      cause: "O saque aparece como início pouco organizado da cadeia do ponto.",
      microFocus: "Sacar e preparar.",
      microRule: "Sacou, fechou a próxima bola.",
      positive: "Você já usa o saque como ponto de partida do jogo.",
      limiter: "O saque ainda não está ajudando a preparar a terceira bola.",
      next: "Na próxima aula, o foco será sacar com intenção e recuperar a base para a próxima ação.",
      drill: "Saque no alvo + primeira bola controlada. O ponto só libera depois da recuperação da dupla."
    },
    devolucao: {
      cause: "A entrada no ponto está quebrando antes da dupla conseguir se organizar.",
      microFocus: "Devolver e recuperar.",
      microRule: "Devolveu, fechou o centro.",
      positive: "Você consegue identificar que a devolução influencia o ponto inteiro.",
      limiter: "A devolução ainda entrega tempo ou espaço para a terceira bola adversária.",
      next: "Na próxima aula, o foco será devolver com margem e recuperar posição antes da bola seguinte.",
      drill: "Devolução profunda + recuperação de base. Bônus apenas se a dupla neutralizar a terceira bola."
    },
    tapa: {
      cause: "A aceleração curta está aparecendo antes da bola estar realmente vulnerável.",
      microFocus: "Acelerar só com vantagem.",
      microRule: "Tapa só no forehand alto.",
      positive: "Você procura tirar tempo quando enxerga oportunidade.",
      limiter: "O tapa ainda aparece em contexto arriscado ou sem recuperação depois da ação.",
      next: "Na próxima aula, o foco será reconhecer a bola certa para acelerar sem transformar tudo em definição.",
      drill: "Bola média-alta no forehand para tapa; backhand usa ventaglio/anômala ou controle. Bola baixa deve ser neutralizada."
    },
    bandeja: {
      cause: "A continuidade ofensiva precisa ser mais estável antes da tentativa de definição.",
      microFocus: "Manter vantagem.",
      microRule: "Bandeja não é smash.",
      positive: "Você busca manter a dupla viva em posição ofensiva.",
      limiter: "A bandeja ainda perde profundidade ou vira aceleração sem necessidade.",
      next: "Na próxima aula, o foco será sustentar vantagem com margem e organização.",
      drill: "Bandeja profunda com alvo grande. O ponto libera quando a dupla mantém ferradura ofensiva."
    },
    smash: {
      cause: "A finalização está sendo buscada sem vantagem totalmente consolidada.",
      microFocus: "Finalizar na bola certa.",
      microRule: "Winner cedo perde bônus.",
      positive: "Você reconhece oportunidades de definição.",
      limiter: "O smash ainda aparece cedo demais ou sem base equilibrada.",
      next: "Na próxima aula, o foco será criar vantagem antes de finalizar.",
      drill: "Rally com bola alta variável. Smash só vale depois de deslocar o adversário ou receber bola alta confortável."
    },
    forehand: {
      cause: "O forehand está sendo exigido sem preparação corporal suficiente.",
      microFocus: "Base antes da bola.",
      microRule: "Sem base, sem acelerar.",
      positive: "Você usa o forehand para participar bastante do ponto.",
      limiter: "O forehand perde qualidade quando chega atrasado ou sem transferência de peso.",
      next: "Na próxima aula, o foco será ajustar base, contato e recuperação antes de aumentar velocidade.",
      drill: "Forehand com deslocamento curto, alvo profundo e recuperação obrigatória após cada bola."
    },
    backhand: {
      cause: "O lado não dominante está pedindo mais sustentação e escolha simples.",
      microFocus: "Sustentar o backhand.",
      microRule: "Backhand constrói, não força.",
      positive: "Você consegue manter o ponto vivo pelo lado do backhand.",
      limiter: "O backhand ainda perde margem quando tenta resolver o ponto cedo.",
      next: "Na próxima aula, o foco será usar o backhand para construir ou neutralizar.",
      drill: "Backhand cruzado com margem. Quando vier bola acelerável, usar ventaglio/anômala, não tapa de backhand."
    },
    lob: {
      cause: "A bola alta precisa virar recuperação real, não apenas sobrevivência.",
      microFocus: "Ganhar tempo de verdade.",
      microRule: "Lob curto não recupera.",
      positive: "Você usa o lob como recurso para sair da pressão.",
      limiter: "O lob ainda não compra tempo suficiente para reorganizar a dupla.",
      next: "Na próxima aula, o foco será profundidade do lob e reposicionamento logo depois.",
      drill: "Lob profundo saindo da pressão + retorno para base. O ponto libera apenas após a dupla recuperar espaço."
    },
    gancho: {
      cause: "A recuperação em desequilíbrio precisa manter margem e reorganizar a dupla.",
      microFocus: "Gancho para reorganizar.",
      microRule: "Gancho não define.",
      positive: "Você encontra soluções quando a bola sai do eixo ideal.",
      limiter: "O gancho ainda vira improviso quando falta margem ou recuperação depois do golpe.",
      next: "Na próxima aula, o foco será usar o gancho para ganhar tempo e voltar ao ponto.",
      drill: "Gancho de cobertura após lob profundo. Depois do gancho, dupla precisa fechar centro antes da próxima bola."
    },
    curta: {
      cause: "A variação curta precisa ter intenção e cobertura, não ser fuga do rali.",
      microFocus: "Curta com intenção.",
      microRule: "Curta sem cobertura entrega.",
      positive: "Você tenta variar o ponto e mudar o ritmo.",
      limiter: "A curta ainda aparece sem preparação ou sem cobertura do parceiro.",
      next: "Na próxima aula, o foco será usar a curta para desorganizar, não para escapar.",
      drill: "Curta com alvo e cobertura. Ponto bônus somente se a dupla fechar o espaço depois da curta."
    },
    consistencia: {
      cause: "O volume de bola ainda quebra antes de gerar uma situação favorável.",
      microFocus: "Sustentar mais uma bola.",
      microRule: "Erro cedo perde bônus.",
      positive: "Você consegue entrar em ralis e reconhecer quando precisa manter o ponto vivo.",
      limiter: "A consistência ainda cai quando o ponto pede paciência e profundidade.",
      next: "Na próxima aula, o foco será jogar com margem até criar a bola certa.",
      drill: "Rali profundo com alvo grande. Bônus por sequência de três bolas com recuperação."
    },
    posicionamento: {
      cause: "A leitura coletiva está chegando tarde: a bola até volta, mas a dupla perde espaço.",
      microFocus: "Fechar espaço primeiro.",
      microRule: "Bateu, recuperou.",
      positive: "Você já percebe que posição muda a qualidade da próxima bola.",
      limiter: "A recuperação e a cobertura ainda chegam depois da necessidade do ponto.",
      next: "Na próxima aula, o foco será jogar e recuperar como dupla.",
      drill: "Rali com chamada de cobertura. Cada ação só conta se a dupla fechar centro depois."
    },
    decisao: {
      cause: "A escolha da resposta está quebrando antes da técnica explicar o erro.",
      microFocus: "Escolher antes de bater.",
      microRule: "Bola ruim pede margem.",
      positive: "Você tenta assumir responsabilidade nas bolas importantes.",
      limiter: "A decisão ainda acelera quando o ponto pedia ganhar tempo ou construir.",
      next: "Na próxima aula, o foco será reconhecer a função da bola antes da execução.",
      drill: "Jogo condicionado: desvantagem recupera, neutro constrói, vantagem pressiona."
    }
  };

  function keyForFundamental(value){
    const n = norm(value);
    return Object.keys(FUNDAMENTAL_ALIASES).find(key =>
      FUNDAMENTAL_ALIASES[key].some(alias => n.includes(norm(alias)))
    ) || "";
  }

  function scoreValue(map, key){
    if(!map) return 0;
    const aliases = FUNDAMENTAL_ALIASES[key] || [];
    const direct = FUNDAMENTAL_LABEL[key];
    const candidates = [direct, ...aliases];
    for(const name of candidates){
      const found = Object.keys(map).find(k => norm(k) === norm(name));
      if(found && Number(map[found]) > 0) return Number(map[found]);
    }
    return 0;
  }

  function addCandidate(candidates, key, weight, reason, source){
    if(!key || !RULES[key] || !Number.isFinite(weight) || weight <= 0) return;
    const item = candidates[key] || {key, weight:0, reasons:[], sources:new Set()};
    item.weight += weight;
    if(reason) item.reasons.push(reason);
    if(source) item.sources.add(source);
    candidates[key] = item;
  }

  function scoutKey(event){
    const issue = norm(event.tactical_issue || event.inferred_behavior || "");
    const text = norm([
      event.fundamental,
      event.shot,
      event.technique,
      event.observed_action,
      event.outcome,
      event.kind,
      event.inferred_intention,
      event.note
    ].filter(Boolean).join(" "));

    if(issue.includes("fora de contexto") || issue.includes("precipitada") || issue.includes("sem contexto") || issue.includes("risco")) return "decisao";
    if(issue.includes("reorganizacao") || issue.includes("cobertura") || issue.includes("posicion")) return "posicionamento";
    if(issue.includes("defesa sem saida")) return "lob";
    return keyForFundamental(text);
  }

  function scoutKindWeight(event){
    const k = norm(event.kind || event.outcome || event.observed_result || "");
    if(k.includes("error") || k.includes("erro")) return 1.6;
    if(k.includes("decision") || k.includes("decis")) return 1.4;
    if(k.includes("position") || k.includes("posic")) return 1.25;
    if(k.includes("ball_given") || k.includes("entreg")) return 1.3;
    return 0.65;
  }

  function evaluateStudent(input = {}){
    const teacherScores = input.teacherScores || {};
    const selfScores = input.selfScores || {};
    const events = Array.isArray(input.scoutEvents) ? input.scoutEvents : [];
    const candidates = {};

    Object.keys(RULES).forEach(key => {
      const t = scoreValue(teacherScores, key);
      if(t > 0 && t < 6.5){
        addCandidate(candidates, key, (6.5 - t) * 2.4, `Avaliação do professor indica ${FUNDAMENTAL_LABEL[key]} em ${t.toFixed(1)}/10.`, "professor");
      }

      const s = scoreValue(selfScores, key);
      if(s > 0 && s < 6.5){
        addCandidate(candidates, key, (6.5 - s) * 1.1, `Autoavaliação aponta baixa confiança em ${FUNDAMENTAL_LABEL[key]} (${s.toFixed(1)}/10).`, "auto");
      }
    });

    events.forEach(event => {
      const key = scoutKey(event);
      if(!key) return;
      const weight = scoutKindWeight(event);
      const issue = event.tactical_issue || event.inferred_behavior || event.fundamental || event.shot || event.technique || "ação observada no Scout";
      addCandidate(candidates, key, weight, `Scout registrou ${issue}.`, "scout");
    });

    const devolucaoScore = Math.max(scoreValue(teacherScores, "devolucao"), scoreValue(selfScores, "devolucao"));
    const forehandEvents = events.filter(event => scoutKey(event) === "forehand").length;
    if(forehandEvents >= 2 && devolucaoScore > 0 && devolucaoScore < 6){
      addCandidate(candidates, "devolucao", 1.8, "Erros de forehand podem estar nascendo de uma entrada ruim no ponto.", "causal");
    }

    const defesaEvents = events.filter(event => ["lob","gancho"].includes(scoutKey(event))).length;
    const posScore = Math.max(scoreValue(teacherScores, "posicionamento"), scoreValue(selfScores, "posicionamento"));
    if(defesaEvents >= 2 && posScore > 0 && posScore < 6.5){
      addCandidate(candidates, "posicionamento", 1.6, "A defesa aparece ligada à recuperação de espaço da dupla.", "causal");
    }

    const ranked = Object.values(candidates).sort((a,b) => b.weight - a.weight);
    if(!ranked.length) return null;

    const top = ranked[0];
    const rule = RULES[top.key];
    const sourceCount = top.sources.size;
    const confidence = sourceCount >= 3 ? "alta" : sourceCount >= 2 ? "média" : "baixa";
    const sourceLabel = Array.from(top.sources).join(" + ");

    return {
      key: top.key,
      label: FUNDAMENTAL_LABEL[top.key],
      probableCause: rule.cause,
      microFocus: rule.microFocus,
      microRule: rule.microRule,
      studentPositive: rule.positive,
      studentLimiter: rule.limiter,
      studentNextFocus: rule.next,
      drill: rule.drill,
      confidence,
      sourceLabel,
      evidence: top.reasons.slice(0, 4),
      alternatives: ranked.slice(1, 4).map(item => ({
        key: item.key,
        label: FUNDAMENTAL_LABEL[item.key],
        weight: Number(item.weight.toFixed(2))
      }))
    };
  }

  root.BEACHFLOW_CAUSE_ENGINE = {
    evaluateStudent,
    keyForFundamental,
    rules: RULES
  };
})(typeof window !== "undefined" ? window : globalThis);
