# Assistente de Conhecimento RAG-SYSRH

Este projeto implementa um assistente de IA conversacional avançado, construído com o padrão RAG (_Retrieval-Augmented Generation_), para responder a perguntas sobre a base de conhecimento do sistema SYSRH. O agente é capaz de realizar buscas factuais e semânticas em um grafo de conhecimento populado a partir de diversas fontes de dados.

## ✨ Funcionalidades Principais

- **Ingestão de Dados Multi-fonte**: Processa e estrutura dados de arquivos `.csv`, `.docx` e `.xlsx`.
- **Grafo de Conhecimento**: Modela os dados em um grafo Neo4j, conectando Solicitações, Clientes, Manuais e RCMs para permitir consultas complexas.
- **Busca Semântica (Vetorial)**: Utiliza embeddings de texto da OpenAI para encontrar informações relevantes em documentos longos, mesmo que a pergunta não use as mesmas palavras-chave.
- **Busca Factual (Cypher)**: Gera consultas Cypher dinamicamente para responder a perguntas específicas sobre dados estruturados (IDs, status, contagens, etc.).
- **Agente Inteligente com Múltiplas Ferramentas**: O agente decide autonomamente qual ferramenta (semântica ou factual) é a mais adequada para responder à pergunta do usuário.
- **Memória Conversacional**: Mantém o contexto do diálogo, permitindo responder a perguntas de acompanhamento de forma natural.

## 🏗️ Arquitetura do Projeto

O projeto é dividido em dois componentes principais: o pipeline de ingestão de dados e o agente conversacional interativo.

### 1. Pipeline de Ingestão de Dados (`src/rag_sysrh/data_ingestion.py`)

Este script é responsável por construir e manter o grafo de conhecimento no Neo4j. O processo (ETL) consiste em:

1. **Extração**: Lê dados brutos de `solicitacoes.csv`, documentos de RCMs e Manuais.
2. **Transformação**:
   - Limpa e padroniza os dados tabulares.
   - Converte o conteúdo dos arquivos `.doc` para o formato **Markdown**, preservando a estrutura de títulos e listas.
   - Divide os textos longos em pedaços menores e coesos (_semantic chunking_).
   - Gera **embeddings vetoriais** para cada chunk de texto usando o modelo `text-embedding-ada-002` da OpenAI.
3. **Carregamento**:
   - Popula o banco de dados Neo4j com nós (`Solicitacao`, `Cliente`, `Manual`, `RCM`, `Chunk`).
   - Cria os relacionamentos entre os nós (`ASSOCIADA_A`, `ORIGINADO_DE`, `PARTE_DE`).
   - Armazena os embeddings gerados diretamente nos nós `:Chunk`.
   - Cria um **índice de vetor** no Neo4j para otimizar as buscas semânticas.

### 2. Agente Conversacional (`src/rag_sysrh/main.py` e `agent_executor.py`)

Este é o ponto de entrada para interagir com o assistente.

- **`main.py`**: Orquestra a criação do agente e suas ferramentas.
  - **Ferramenta Semântica**: Utiliza `Neo4jVector` para fazer buscas de similaridade no índice de vetores. Ideal para perguntas abertas como "Como funciona o processo de férias?".
  - **Ferramenta Factual**: Utiliza uma cadeia customizada que, através de _prompt engineering_ detalhado, guia um LLM para gerar consultas Cypher precisas. Ideal para perguntas específicas como "Liste as 3 últimas solicitações do cliente ALESC".
- **`agent_executor.py`**: Constrói o agente ReAct, que recebe as ferramentas e uma **memória conversacional** (`ConversationBufferMemory`), permitindo que ele mantenha o contexto entre as perguntas.

## 🛠️ Tecnologias Utilizadas

- **Linguagem**: Python 3.11+
- **Orquestração de IA**: LangChain
- **Modelos de Linguagem (LLM)**: OpenAI GPT-4
- **Embeddings**: OpenAI `text-embedding-ada-002`
- **Banco de Dados**: Neo4j (Graph Database + Vector Search)
- **Manipulação de Dados**: Pandas
- **Leitura de Documentos**: `python-docx`
- **Gerenciamento de Ambiente**: `uv`
- **Variáveis de Ambiente**: `python-dotenv`

## 🚀 Como Executar

### Pré-requisitos

1. **Python** instalado.
2. **`uv`** instalado (`pip install uv`).
3. Uma instância do **Neo4j** ativa e acessível.
4. Uma chave de API da **OpenAI**.

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
