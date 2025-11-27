# Fluxo Operacional da Fábrica de Software (RAG_SYSRH)

Este documento detalha o fluxo operacional atual da fábrica de software, desde a solicitação inicial até a entrega do código e documentação. Ele identifica os agentes de IA envolvidos, os pontos de intervenção humana e os gatilhos de automação.

## 🔄 Visão Geral do Fluxo

O fluxo segue um modelo linear de **Solicitação -> Análise -> Validação -> Aprovação -> Desenvolvimento -> Entrega**.

1.  **Solicitação & Análise**: O usuário abre um pedido; o **Agente Analista** diagnostica e cria um RCM (Relatório de Controle de Mudança).
2.  **Validação (Analista)**: Um humano (Analista) revisa e valida o RCM.
3.  **Aprovação (Cliente)**: O cliente aprova o orçamento/escopo.
4.  **Fábrica (Dev)**: O **Agente Desenvolvedor** implementa o código, gera documentação e valida a qualidade.

---

## 📝 Passo a Passo Operacional

### Fase 1: Solicitação e Análise Automática

**Responsável:** Usuário (Solicitante) + Agente Analista (`AnalistaWorkflow`)

1.  **Ação no Portal:**
    - O usuário acessa o menu **"Chat Corporativo"** (`/chat`) ou **"Governança & IA"** (`/governance`).
    - Registra a solicitação descrevendo o problema ou necessidade.
2.  **Processamento (IA):** O sistema cria uma Issue no GitHub e aciona o `AnalistaWorkflow` em background.
    - O Agente classifica a demanda.
    - Consulta a Base de Conhecimento (Histórico, Manuais, Métricas SISP).
    - Gera um **Diagnóstico Técnico** e, se for Evolutiva, um **Rascunho de RCM** com estimativa de Pontos de Função e Prazo.
3.  **Saída:** A Issue no GitHub é atualizada com o diagnóstico e recebe a label `status:aguardando-validacao-rcm`.

### Fase 2: Validação do RCM (Intervenção Humana - Analista)

**Responsável:** Analista de Requisitos (Humano)

1.  **Acesso ao Portal:**
    - O Analista acessa o menu **"Validação (Analista)"** na barra lateral.
    - Rota: `/validacao` (Backlog de Validação).
2.  **Ação:**
    - Seleciona uma tarefa pendente na lista.
    - É redirecionado para o **Validation Workbench** (`/validacao/:issue_number`).
    - Revisa o Rascunho de RCM gerado pela IA no painel central.
3.  **Decisão:**
    - **Aprovar:** Clica no botão **"APROVA E IMPLANTAR"** na interface. O sistema gera o documento final (DOCX), anexa à Issue e muda o status para `status:aceite-homologacao`.
    - **Rejeitar/Ajustar:** Pode editar o texto diretamente no editor ou solicitar nova análise.
    - **Atualizar:** Botão "Atualizar" disponível para recarregar os dados da issue.

### Fase 3: Aprovação do Cliente (Intervenção Humana - Cliente)

**Responsável:** Cliente / Product Owner (Humano)

1.  **Acesso:**
    - O Cliente recebe um link direto por e-mail/notificação ou acessa a área pública de aprovação.
    - Rota: `/cliente/aprovacao/:issue_number` (Interface Simplificada de Aprovação).
2.  **Ação no Portal:**
    - Visualiza o **RCM Final** (PDF/DOCX) e o resumo de custos (Pontos de Função) e prazos.
3.  **Decisão:**
    - **Aprovar:** Clica no botão **"Aprovar Orçamento e Escopo"**.
      - _Efeito:_ O sistema registra a aprovação e muda a label da Issue para `status:pronto-para-dev`.
    - **Rejeitar:** Clica em **"Rejeitar"** e insere o motivo.
      - _Efeito:_ Devolve para o Analista (`status:aguardando-validacao-rcm`).

### Fase 4: Fábrica de Desenvolvimento (Automação Completa)

**Responsável:** Agente Desenvolvedor (`dev_agent`) + Agente de Documentação + Agente de Qualidade

1.  **Gatilho:** O Webhook detecta a label `status:pronto-para-dev` na Issue.
2.  **Orquestração:** O sistema dispara o `run_dev_agent`.
3.  **Execução (Agente Dev):**
    - Lê a Issue e o RCM aprovado.
    - Planeja a implementação.
    - Escreve/Modifica o código no projeto.
4.  **Documentação (Agente Doc):**
    - Após o código, o sistema aciona a geração/atualização do **Manual Operacional**.
5.  **Controle de Qualidade (Agente QA):**
    - O Agente de Qualidade audita o Manual Operacional gerado.
    - **Se Aprovado:** Issue movida para `status:aguardando-review-tecnico`. Comentário de sucesso postado.
    - **Se Reprovado:** Issue movida para `status:aguardando-correcao-doc`. Deploy bloqueado.

### Fase 5: Revisão Técnica e Homologação (Technical Workbench)

**Responsável:** Tech Lead / Usuário Homologador

1.  **Revisão Técnica:**

    - O Tech Lead acessa o **Technical Workbench** (`/technical-workbench`).
    - Na aba **"Revisões Pendentes"**, visualiza as demandas aguardando review.
    - Botão **"Atualizar"** disponível para recarregar a lista.
    - **Ação:** Clica em **"Aprovar e Implantar"**.
      - _Efeito:_ A issue é movida para `status:aceite-homologacao` (mas permanece aberta).

2.  **Homologação (Aceite do Usuário):**
    - Na aba **"Histórico de Revisões"** do Technical Workbench.
    - Uma nova coluna **"Homologação"** exibe um botão **"OK" (Laranja)** para issues em `status:aceite-homologacao`.
    - **Ação:** O usuário valida a entrega e clica em **"OK"**.
      - _Efeito:_ A issue recebe a label `status:homologado`, é fechada automaticamente, e o botão se torna um **Check Verde**.

---

## ⚠️ Pontos de Atenção e Gaps Identificados

### 1. Ausência do `agent_scrum`

O fluxo atual **NÃO possui um agente dedicado chamado `agent_scrum`**.

- **Como funciona hoje:** A transição de "Aprovado pelo Cliente" para "Desenvolvimento" é direta via Webhook -> `dev_agent`. O `dev_agent` faz seu próprio planejamento técnico ("Chain of Thought"), mas não há uma etapa formal de "Sprint Planning" ou quebra de tarefas em sub-issues gerenciada por um Scrum Master virtual.
- **Onde ele entraria:** Idealmente, entre a **Fase 3** e a **Fase 4**. O `agent_scrum` poderia pegar a Issue aprovada, quebrar em tarefas menores (sub-tasks), atribuir a diferentes agentes (se houvesse mais de um dev) e gerenciar o backlog da sprint.

### 2. Validação Técnica do Código

Atualmente, o fluxo move para `status:aguardando-review-tecnico` após o desenvolvimento. Esta etapa é um ponto de parada para um **Humano (Tech Lead)** revisar o código (PR Review) antes do merge final/deploy.

### 3. Intervenção Humana Obrigatória

O fluxo foi desenhado para **não ser 100% autônomo** nas decisões críticas (Orçamento, Escopo e Homologação Final). As fases 2, 3 e 5 exigem clique humano explícito para garantir governança.
