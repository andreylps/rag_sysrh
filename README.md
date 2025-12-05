# Assistente de Conhecimento RAG-SYSRH

Este projeto implementa um assistente de IA multifuncional para o sistema SYSRH, combinando um **agente de consulta conversacional** e um **workflow de análise automatizada**. Construído com o padrão RAG (_Retrieval-Augmented Generation_) e orquestrado com LangGraph, o sistema oferece suporte inteligente para analistas e gestores.

## ✨ Funcionalidades Principais

- **Ingestão de Dados Seletiva**: Processa e estrutura dados de arquivos `.csv`, `.docx` e `.xlsx`. Permite a ingestão granular de dados (`manuais`, `solicitações`, etc.) para otimizar custos e tempo.
- **Grafo de Conhecimento**: Modela os dados em um grafo Neo4j, conectando Solicitações, Clientes, Manuais e RCMs para permitir consultas complexas.
<<<<<<< HEAD
- **Interface Web Interativa**: Uma aplicação Streamlit (`app.py`) que serve como ponto de entrada unificado para todas as funcionalidades.
- **Agente de Consulta Conversacional**:
  - **Arquitetura de Múltiplos Agentes**: Utiliza um agente orquestrador que delega tarefas a especialistas (Factual, Semântico, Web) para responder a perguntas complexas.
  - **Memória Conversacional**: Mantém o contexto do diálogo, permitindo responder a perguntas de acompanhamento.
  - **Tratamento de Ambiguidade**: Pede esclarecimentos ao usuário quando uma pergunta é vaga.
- **Workflow de Análise Automatizada (`LangGraph`)**:
  - **Classificação Inteligente**: Classifica novas solicitações por tipo, complexidade e cliente.
  - **Busca por Similaridade no Histórico**: Utiliza busca vetorial para encontrar não apenas manuais, mas também **chamados passados** com problemas similares.
  - **Pré-Análise e Sugestão de Solução**: Diagnostica o problema e sugere uma solução técnica com base no histórico de chamados.
  - **Estimativa de Esforço e Prazo**: Calcula o esforço em Pontos de Função (PF) ou Horas e projeta uma data de entrega.
  - **Geração de Relatório**: Consolida toda a análise em um relatório Markdown.
=======
- **Busca Semântica (Vetorial)**: Utiliza embeddings de texto da OpenAI para encontrar informações relevantes em documentos longos, mesmo que a pergunta não use as mesmas palavras-chave.
- **Busca Factual (Cypher)**: Gera consultas Cypher dinamicamente para responder a perguntas específicas sobre dados estruturados (IDs, status, contagens, etc.).
- **Agente Inteligente com Múltiplas Ferramentas**: O agente decide autonomamente qual ferramenta (semântica ou factual) é a mais adequada para responder à pergunta do usuário.
- **Memória Conversacional**: Mantém o contexto do diálogo, permitindo responder a perguntas de acompanhamento de forma natural.
- **Monitoramento de Saúde (Novo)**: Endpoint `/api/v1/system/health` e widget no Painel Maestro para monitoramento de uso de disco e status da infraestrutura.
>>>>>>> b55c263f4c6229631e8d58bea7ffd1b4e1a45bae

## 🏗️ Arquitetura do Projeto

O projeto é dividido em dois componentes principais: o pipeline de ingestão de dados e o agente conversacional interativo.

### 1. Pipeline de Ingestão de Dados (`src/rag_sysrh/data_ingestion.py`)

Este script é responsável por construir e manter o grafo de conhecimento no Neo4j. O processo (ETL) consiste em:

1. **Extração**: Lê dados brutos de `solicitacoes.csv`, documentos de RCMs e Manuais.
2. **Transformação**:
   - Limpa e padroniza os dados tabulares, incluindo a correção de codificação de caracteres.
   - Converte o conteúdo dos arquivos `.docx` para o formato **Markdown**.
   - Divide os textos longos em pedaços menores e coesos (_semantic chunking_).
   - Gera **embeddings vetoriais** para cada chunk de documento e para a descrição de cada solicitação, usando o modelo `text-embedding-ada-002` da OpenAI.
   - Lida com limites de API através de truncamento de texto e processamento em lotes.
3. **Carregamento**:
   - Popula o banco de dados Neo4j com nós (`Solicitacao`, `Cliente`, `Manual`, `RCM`, `Chunk`, `GuiaMetrica`).
   - Cria os relacionamentos entre os nós (`ASSOCIADA_A`, `ORIGINADO_DE`, `PARTE_DE`).
   - Armazena os embeddings gerados diretamente nos nós `:Chunk` e `:Solicitacao`.
   - Cria múltiplos **índices de vetor** no Neo4j para otimizar as buscas semânticas em diferentes tipos de conteúdo.

### 2. Aplicação Interativa (`src/rag_sysrh/app.py` e `analista_workflow.py`)

Este é o coração do sistema, onde a lógica de IA é executada.

- **`app.py`**: A interface de usuário construída com **Streamlit**. Ela permite ao usuário escolher entre o modo de "Consulta Conversacional" e o de "Análise de Solicitação".
- **`analista_workflow.py`**: Contém toda a lógica de IA:
  - A configuração do **agente conversacional** e suas ferramentas (Semântica, Factual, Web).
  - A definição do **workflow de análise** usando `LangGraph`, com todos os seus nós (Classificador, RAG, Analista, Sumarizador).
- **`agent_executor.py`**: Constrói o agente ReAct com memória conversacional, que é utilizado pelo modo de consulta.

## 🛠️ Tecnologias Utilizadas

- **Linguagem**: Python 3.11+
- **Orquestração de IA**: LangChain
- **Modelos de Linguagem (LLM)**: OpenAI GPT-4
- **Embeddings**: OpenAI `text-embedding-ada-002`
- **Busca Web**: Tavily Search API
- **Banco de Dados**: Neo4j (Graph Database + Vector Search)
- **Manipulação de Dados**: Pandas
- **Leitura de Documentos**: `python-docx`
- **Interface Web**: Streamlit
- **Gerenciamento de Ambiente**: `uv`
- **Variáveis de Ambiente**: `python-dotenv`

## 🚀 Como Executar

### Pré - requisitos

1. **Python** instalado.
2. **`uv`** instalado (`pip install uv`).
3. Uma instância do **Neo4j** ativa e acessível.
4. Chaves de API para **OpenAI** e **Tavily**.

### 1. Configuração do Ambiente

Clone o repositório e instale as dependências:

```bash
# Crie o ambiente virtual
uv venv

# Ative o ambiente virtual
# No Windows (PowerShell)
.venv\Scripts\Activate.ps1
# No Linux/macOS
source .venv/bin/activate

# Instale as dependências
uv pip install -r requirements.txt
```

### 2. Configuração das Variáveis de Ambiente

Renomeie o arquivo `.env.example` para `.env` e preencha com suas credenciais:

```env
NEO4J_URI="bolt://localhost:7687"
NEO4J_USER="neo4j"
NEO4J_PASSWORD="your_neo4j_password"
OPENAI_API_KEY="sk-..."
TAVILY_API_KEY="tvly-..."
```

### 3. Ingestão de Dados

Execute o script de ingestão, especificando o que deseja processar com o argumento `--target`.

```bash
# Para ingerir apenas os manuais (rápido e econômico)
python src/rag_sysrh/data_ingestion.py --target manuais

# Para ingerir apenas as solicitações (pode consumir mais tokens)
python src/rag_sysrh/data_ingestion.py --target solicitacoes

# Para ingerir tudo
python src/rag_sysrh/data_ingestion.py --target all
```

### 4. Executando a Aplicação

Inicie a interface web com o Streamlit:

```bash
streamlit run src/rag_sysrh/app.py
```

A aplicação será aberta no seu navegador, pronta para uso.

```

```
