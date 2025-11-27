# Guia de Validação Operacional - RAG_SYSRH

**Versão:** 1.0
**Data:** 26/11/2025
**Status:** Fase 6.7.1 (Pronto para Validação Humana)

---

## 1. Visão Geral do Fluxo (SDLC Híbrido)

Este guia orienta a validação manual de ponta a ponta do sistema RAG_SYSRH, cobrindo o ciclo de vida de desenvolvimento de software (SDLC) híbrido, que combina automação por agentes de IA com governança humana.

**Fluxo Macro:**

1.  **Triagem (Governança):** Entrada da demanda via Portal -> Classificação e Roteamento pela IA.
2.  **Análise (Humano + IA):** Analista valida a demanda -> Agente gera RCM (Requisitos) -> Cliente aprova.
3.  **Desenvolvimento (Agente Dev):** Agente implementa código e gera documentação.
4.  **Qualidade (Agente QA):** Validação automática de código e documentação (ISO/SISP).
5.  **Deploy:** Liberação para produção se aprovado.

---

## 2. Estrutura de Testes

Cada seção abaixo descreve um cenário de teste, as ações a serem realizadas e o critério de sucesso esperado.

---

## Seção 1: Validação de Entrada e Classificação (Governança & IA)

**Objetivo:** Verificar se o portal de entrada captura corretamente as demandas e se a IA realiza a triagem inicial com precisão.

### Cenário 1.1: Criar Nova Solicitação

**Ação:**

1.  Acesse a página inicial (`/`) ou `/governance`.
2.  Preencha o formulário:
    - **Título:** "Erro no cálculo do 13º salário para pensionistas"
    - **Tipo:** Selecione "Corretiva" (ou "Correção de Dados").
    - **Prioridade:** "Alta".
    - **Descrição:** "O sistema está calculando o valor base errado para pensionistas do grupo X."
3.  Clique em "Enviar Solicitação".

**Critério de Avaliação (Sucesso):**

- [ ] O sistema exibe mensagem de sucesso com o número da Issue (ex: #45).
- [ ] Ao clicar no link da Issue no GitHub:
  - [ ] A Issue foi criada no repositório correto.
  - [ ] **Roteamento:** A label de time (ex: `time:folha` ou similar) foi aplicada corretamente pela IA baseada no contexto.
  - [ ] **Status:** A label `status:nova` (ou equivalente inicial) está presente.

---

## Seção 2: Validação da Qualidade (QA e Documentação)

**Objetivo:** Testar a "Trava de Qualidade" (Quality Gate) que impede que documentação ou código fora dos padrões ISO/SISP avancem.

### Cenário 2.1: Teste de Sucesso (Caminho Feliz)

**Ação:**

1.  Utilize uma issue existente (tipo Evolutiva) que esteja pronta para desenvolvimento.
2.  Simule (ou aguarde) a execução do **Agente Desenvolvedor**.
3.  O Agente deve gerar um Manual Operacional completo e correto.

**Critério de Avaliação (Sucesso):**

- [ ] O Agente QA valida o manual e retorna "Aprovado".
- [ ] A Issue no GitHub recebe um comentário de "Documentação Aprovada".
- [ ] A label da issue muda para `status:pronto-para-deploy` (ou fecha a issue, dependendo da configuração final).

### Cenário 2.2: Teste de Bloqueio Crítico (Violação de Segurança)

**Ação:**

1.  Crie uma issue solicitando uma funcionalidade que force uma má prática (ex: "Adicionar senha de banco hardcoded no script de conexão").
2.  Observe a reação do Agente QA ao analisar o código ou documentação gerada.

**Critério de Avaliação (Sucesso):**

- [ ] **Bloqueio:** A issue **NÃO** é fechada.
- [ ] **Feedback:** Um comentário detalhado é postado na issue com o cabeçalho `❌ FALHA NA AUDITORIA DE QUALIDADE`.
- [ ] **Detalhes:** O comentário cita a violação (ex: ISO 27001 - Credenciais expostas).
- [ ] **Dashboard:** No painel `/qa-room`, um novo alerta de "Violação de Segurança" deve aparecer.
- [ ] **Rework:** A label `status:aguardando-correcao-doc` (ou similar) é aplicada.

---

## Seção 3: Validação de Artefatos e Rastreabilidade

**Objetivo:** Garantir que os documentos gerados (RCM, Memória de Cálculo) sejam acessíveis, legíveis e tecnicamente corretos.

### Cenário 3.1: Revisão Técnica e Artefatos

**Ação:**

1.  Acesse o **Workbench Técnico** (`/technical-review`).
2.  Selecione uma issue em revisão.
3.  Clique em "Revisar Código" (se disponível) ou verifique os links de artefatos na issue do GitHub.
4.  Baixe o **RCM (DOCX)** e a **Memória de Cálculo (XLSX)** gerados.

**Critério de Avaliação (Sucesso):**

- [ ] **Download:** Os arquivos baixam corretamente.
- [ ] **Conteúdo RCM:** O DOCX abre e contém as seções esperadas (Objetivo, Solução Técnica, Impacto).
- [ ] **Conteúdo XLSX:** A planilha abre e contém os cálculos de Ponto de Função (SISP) preenchidos.
- [ ] **Diff:** Se houver visualizador de código, a navegação entre arquivos é fluida e a sintaxe (Python/SQL) está destacada corretamente.

---

## Seção 4: Validação de Visibilidade Operacional

**Objetivo:** Verificar se os Dashboards refletem a realidade do sistema em tempo real.

### Cenário 4.1: Dashboard de BI

**Ação:**

1.  Acesse `/dashboard`.
2.  Verifique os KPIs principais (OEE, Faturamento, etc.).

**Critério de Avaliação (Sucesso):**

- [ ] Os gráficos renderizam sem erros.
- [ ] Os valores parecem consistentes com os dados simulados (não estão zerados ou "NaN", a menos que seja o estado inicial esperado).

### Cenário 4.2: Sala de Controle de Qualidade (QCC)

**Ação:**

1.  Acesse `/qa-room`.
2.  Verifique as abas "Dashboard", "Calendário" e "PDCA".

**Critério de Avaliação (Sucesso):**

- [ ] **Métricas:** O gráfico de "Distribuição de Falhas" aparece (mesmo que seja "Sem Falhas").
- [ ] **Calendário:** As datas de auditoria são futuras (dinâmicas) e fazem sentido (ex: próxima sexta-feira).
- [ ] **PDCA:** Os relatórios simulados de melhoria contínua estão listados.

---

## 3. Formulário de Feedback do Operador

Utilize este espaço para registrar observações durante a validação.

| ID Teste          | Status (OK/Falha) | Observações / Bugs Encontrados |
| :---------------- | :---------------- | :----------------------------- |
| 1.1 (Entrada)     |                   |                                |
| 2.1 (QA Sucesso)  |                   |                                |
| 2.2 (QA Bloqueio) |                   |                                |
| 3.1 (Artefatos)   |                   |                                |
| 4.1 (BI)          |                   |                                |
| 4.2 (QCC)         |                   |                                |

**Conclusão Geral:**
( ) Sistema Aprovado para Piloto
( ) Sistema Requer Correções Críticas
