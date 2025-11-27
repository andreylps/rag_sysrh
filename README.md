# NOESYS.AI - Plataforma de Governança e Engenharia de Software Assistida por IA

**NOESYS.AI** é uma plataforma integrada que orquestra agentes de Inteligência Artificial para automatizar, governar e auditar o ciclo de vida de desenvolvimento de software (SDLC). Ela combina práticas de **Scrum**, **Engenharia de Requisitos** e **QA** em um fluxo contínuo e transparente.

![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow)
![Stack](https://img.shields.io/badge/Stack-FastAPI_React_LangChain-blue)

---

## 🚀 Visão Geral

O sistema atua como uma "Fábrica de Software Autônoma", onde agentes especializados colaboram com humanos para entregar software de alta qualidade.

### Principais Módulos

1.  **Central de Solicitações (`/governance`):** Interface para usuários registrarem demandas.
2.  **Validation Workbench (`/validacao`):** Ambiente para Analistas validarem diagnósticos e RCMs gerados por IA.
3.  **Portal do Cliente (`/cliente/aprovacao`):** Interface simplificada para aprovação de escopo e orçamento.
4.  **Sala Scrum (`/scrum-room`):** Painel do Scrum Master com Burndown Real, Kanban e Relatórios de Sprint.
5.  **Sala de Qualidade (`/qa-room`):** Painel do Auditor QA com Calendário de Auditorias e Relatórios PDCA.
6.  **Technical Workbench (`/technical-review`):** Ambiente para revisão de código e homologação final.

---

## 🏗️ Arquitetura

O projeto segue uma arquitetura de microsserviços modulares:

- **Backend:** FastAPI (Python) para orquestração, APIs e Agentes.
- **Frontend:** React + Vite + TailwindCSS para interfaces de usuário.
- **Agentes:**
  - `AnalistaWorkflow`: Diagnóstico e Engenharia de Requisitos (SISP).
  - `ScrumMasterService`: Planejamento, Monitoramento de Risco e Fechamento de Sprint.
  - `AuditService`: Auditoria Contínua e Geração de Relatórios PDCA.
  - `LibrarianAgent`: Gestão da Base de Conhecimento.
- **Dados:** GitHub Issues (Estado), JSON (Histórico/Snapshots), SQLite (Auxiliar).

---

## 🛠️ Instalação e Execução

### Pré-requisitos

- Python 3.10+
- Node.js 18+
- Conta no GitHub (para integração de Issues)

### 1. Backend (API)

```bash
# Clone o repositório
git clone https://github.com/andreylps/rag_sysrh.git
cd rag_sysrh

# Crie um ambiente virtual
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# ou
.venv\Scripts\activate  # Windows

# Instale as dependências
pip install -r requirements.txt

# Configure as variáveis de ambiente (.env)
cp .env.example .env
# Edite .env com suas chaves (OPENAI_API_KEY, GITHUB_TOKEN, etc.)

# Execute a API
uv run run_api.py
```

A API estará disponível em `http://localhost:8080`.

### 2. Frontend (Interface)

```bash
cd frontend

# Instale as dependências
npm install

# Execute o servidor de desenvolvimento
npm run dev
```

O Frontend estará disponível em `http://localhost:5173`.

---

## 🔄 Fluxo Operacional

1.  **Solicitação:** Usuário abre um pedido.
2.  **Análise (IA):** Agente Analista gera RCM e estimativa.
3.  **Validação:** Analista Humano valida o RCM.
4.  **Aprovação:** Cliente aprova o orçamento.
5.  **Planejamento (IA):** Agente Scrum Master aloca na Sprint (`sprint:atual`).
6.  **Execução:** Desenvolvedores codificam.
7.  **Monitoramento (IA):** Scrum Master monitora riscos diariamente.
8.  **Qualidade (IA):** Agente QA audita e gera relatórios PDCA.
9.  **Entrega:** Usuário homologa e Sprint é fechada.

---

## 📂 Estrutura do Projeto

```
rag_sysrh/
├── src/
│   ├── agents/          # Lógica dos Agentes (Analista, Librarian)
│   ├── api/             # Endpoints FastAPI
│   ├── services/        # Serviços Core (Scrum, Audit, GitHub)
│   ├── schemas/         # Modelos Pydantic
│   └── rag_sysrh/       # Workflows legados
├── frontend/
│   ├── src/
│   │   ├── pages/       # Telas (Salas de Controle, Workbenches)
│   │   ├── components/  # Componentes Reutilizáveis
│   │   └── ...
├── data/                # Persistência (Snapshots, Relatórios)
├── docs/                # Documentação do Sistema
└── ...
```

---

## 📄 Licença

Este projeto é proprietário e confidencial.
Copyright © 2025 NOESYS.AI.
