# Fluxo Operacional da Fábrica de Software (RAG_SYSRH)

Este documento detalha o fluxo operacional completo da fábrica de software, integrando os novos agentes autônomos de Governança (Scrum Master) e Qualidade (QA Auditor).

## 🔄 Visão Geral do Fluxo

O fluxo segue um modelo cíclico e governado: **Solicitação -> Análise -> Planejamento (Scrum) -> Execução & Monitoramento -> Qualidade (QA) -> Entrega & Fechamento**.

---

## 📝 Passo a Passo Operacional

### Fase 1: Solicitação e Análise (AnalistaWorkflow)

**Responsável:** Usuário + Agente Analista

1.  **Entrada:** Usuário abre solicitação na **Central de Solicitações**.
2.  **Diagnóstico:** O **Agente Analista** classifica a demanda, consulta a base de conhecimento e gera um **RCM (Relatório de Controle de Mudança)** com estimativa de Pontos de Função (SISP).
3.  **Status:** `aguardando-validacao-rcm`.

### Fase 2: Validação e Aprovação (Humano)

**Responsável:** Analista de Requisitos + Cliente

1.  **Validação Técnica:** Analista revisa o RCM no **Validation Workbench**.
    - _Aprovar:_ Segue para o cliente.
    - _Rejeitar:_ Volta para o Agente Analista refazer.
2.  **Aprovação Comercial:** Cliente aprova escopo/custo no **Portal do Cliente**.
    - _Aprovado:_ Issue recebe label `pronto-para-dev`.

### Fase 3: Planejamento da Sprint (Scrum Master Agent) - **NOVO**

**Responsável:** Agente Scrum Master (Automático)

1.  **Planejamento (SM.1):** A cada início de ciclo (quinzenal), o Agente Scrum Master varre o backlog (`pronto-para-dev`).
2.  **Seleção:** Prioriza itens por SLA e Criticidade até preencher a capacidade do time.
3.  **Ação:** Aplica a label `sprint:atual` nos itens selecionados.
4.  **Artefato:** Cria o plano da sprint no sistema.

### Fase 4: Execução e Monitoramento (Scrum Master Agent) - **NOVO**

**Responsável:** Desenvolvedores + Agente Scrum Master

1.  **Execução:** Desenvolvedores trabalham nas issues da `sprint:atual`.
2.  **Monitoramento Diário (SM.2):** O Agente Scrum Master roda diariamente (09:00 e hora em hora para críticos).
    - Verifica SLAs prestes a estourar.
    - Identifica bloqueios (`status:blocked`).
    - Emite alertas na **Sala Scrum**.
3.  **Snapshot Diário (SM.5):** Às 20:00, o agente salva o "estado do dia" para alimentar o **Gráfico de Burndown Real**.

### Fase 5: Controle de Qualidade Autônomo (QA Auditor) - **NOVO**

**Responsável:** Agente QA Auditor

1.  **Auditoria Contínua:** O Agente QA roda em background verificando conformidade.
    - _SISP:_ Verifica se a contagem de PF está correta.
    - _Docs:_ Verifica se o Manual Operacional foi gerado.
2.  **Relatórios PDCA:** Gera relatórios de auditoria em PDF e os disponibiliza na **Sala de Qualidade**.
3.  **Feedback Loop:** Extrai lições aprendidas dos relatórios e retroalimenta a Base de Conhecimento.

### Fase 6: Homologação e Fechamento (Scrum Master Agent)

**Responsável:** Usuário + Agente Scrum Master

1.  **Homologação:** Usuário valida a entrega no **Technical Workbench** (`status:homologado`).
2.  **Fechamento de Sprint (SM.4):** Ao final do ciclo:
    - O Agente Scrum Master calcula métricas finais (Velocity, Lead Time).
    - Gera o **Relatório de Fechamento de Sprint**.
    - Remove itens não entregues da sprint (`spilled issues`).
    - Arquiva o relatório para consulta na **Sala Scrum**.

---

## 📊 Painéis de Controle (Dashboards)

- **Sala Scrum (`/scrum-room`):** Para o Time Técnico. Burndown, Kanban, Métricas de Sprint.
- **Sala de Qualidade (`/qa-room`):** Para Auditores. Calendário de Auditorias, Relatórios PDCA.
- **Central de Solicitações:** Para Usuários Finais. Status das demandas.
