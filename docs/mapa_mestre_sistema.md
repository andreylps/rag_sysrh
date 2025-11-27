# Mapa Mestre do Sistema (RAG_SYSRH)

Este documento descreve a arquitetura de alto nível, os componentes principais e suas interações no ecossistema NOESYS.AI.

## 🏗️ Arquitetura Geral

O sistema segue uma arquitetura baseada em **Microserviços Modulares** orquestrados por uma API FastAPI, com um Frontend React e Agentes Autônomos operando em background.

### 1. Camada de Interface (Frontend)

- **Tecnologia:** React + Vite + TailwindCSS
- **Principais Módulos:**
  - **Central de Solicitações (`/governance`):** Entrada de demandas.
  - **Validation Workbench (`/validacao`):** Interface para Analistas validarem RCMs.
  - **Client Portal (`/cliente/aprovacao`):** Interface simplificada para aprovação de orçamento/escopo.
  - **Technical Workbench (`/technical-review`):** Revisão de código e Homologação.
  - **Sala Scrum (`/scrum-room`):** Dashboard do Scrum Master (Burndown, Kanban, Relatórios).
  - **Sala de Qualidade (`/qa-room`):** Dashboard do Auditor QA (Calendário, Relatórios PDCA).
  - **Biblioteca (`/documentation`):** Visualização hierárquica de documentos.

### 2. Camada de Orquestração (Backend API)

- **Tecnologia:** FastAPI (Python)
- **Responsabilidade:** Roteamento, Autenticação (Simples), Gestão de Estado, Integração com Banco de Dados.
- **Endpoints Principais:**
  - `/api/v1/scrum/*`: Gestão de Sprints e Relatórios.
  - `/api/v1/audit/*`: Gestão de Auditorias e PDCA.
  - `/api/v1/documentation/*`: Gestão de Arquivos e Pastas.
  - `/api/v1/github/*`: Integração com GitHub Issues.

### 3. Camada de Agentes (Inteligência)

- **AnalistaWorkflow:**
  - _Função:_ Diagnóstico, Classificação, Estimativa (SISP) e Geração de RCM.
  - _Gatilho:_ Nova Issue ou Rejeição de RCM.
- **ScrumMasterService (Agente):**
  - _Função:_ Planejamento de Sprint, Monitoramento de Risco (SLA), Fechamento de Ciclo, Snapshot Diário.
  - _Gatilho:_ Agendado (Scheduler) ou Eventos de Issue.
- **AuditService (QA Auditor):**
  - _Função:_ Auditoria Autônoma (SISP, Código, Docs), Geração de Relatórios PDCA (PDF).
  - _Gatilho:_ Agendado (Scheduler) ou Eventos de Deploy.
- **LibrarianAgent:**
  - _Função:_ Indexação e Organização da Base de Conhecimento.
- **KnowledgeFeedbackService:**
  - _Função:_ Extração de lições aprendidas de PDFs e retroalimentação do sistema (Neo4j).

### 4. Camada de Dados & Persistência

- **GitHub Issues:** Fonte da verdade para estado das tarefas (Labels como banco de dados).
- **Sistema de Arquivos (`data/`):**
  - `sprint_history_{id}.json`: Snapshots diários das sprints.
  - `audit_reports/`: Relatórios PDCA em PDF.
  - `knowledge_base/`: Documentos indexados.
- **Neo4j (Opcional/Futuro):** Grafo de conhecimento para RAG avançado.
- **SQLite:** Tabelas auxiliares (se necessário).

## 🔄 Fluxo de Dados Principal

1.  **Entrada:** Usuário cria solicitação -> GitHub Issue.
2.  **Processamento:** `AnalistaWorkflow` lê Issue -> Gera RCM -> Atualiza Issue.
3.  **Validação:** Humano valida RCM (Frontend) -> Atualiza Issue.
4.  **Planejamento:** `ScrumMasterService` pega Issues aprovadas -> Monta Sprint -> Aplica Labels.
5.  **Execução:** Devs trabalham -> `ScrumMasterService` monitora riscos.
6.  **Qualidade:** `AuditService` verifica conformidade -> Gera PDCA.
7.  **Fechamento:** `ScrumMasterService` fecha Sprint -> Gera Relatório Final.

## 🧩 Mapa de Dependências

- **Frontend** depende de **FastAPI**.
- **FastAPI** depende de **GitHub API** e **OpenAI/LLM**.
- **Agentes** compartilham **`src/services/github_service.py`** e **`src/config/slas.py`**.
