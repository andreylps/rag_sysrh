# Manual de Atualização de Dados - RAG SYS-RH

Este documento explica como atualizar os dados do sistema (Solicitações, RCMs, Custos e Manuais) para que sejam refletidos no Dashboard e na Base de Conhecimento.

## Estrutura de Pastas

Os dados devem ser colocados na pasta `data/` na raiz do projeto:

```
RAG_SYSRH/
├── data/
│   ├── solicitacoes.csv       # Dados exportados do Azure DevOps/Jira
│   ├── rcms_01.csv            # Metadados das RCMs
│   ├── casos_de_teste.csv     # (Opcional) Casos de teste
│   ├── faturamento/
│   │   └── custos.csv         # Tabela de custos unitários
│   ├── manuais/               # Documentos PDF/DOCX para a Base de Conhecimento
│   │   ├── manual_1.pdf
│   │   └── manual_2.docx
│   └── rcms/                  # Documentos DOCX das RCMs (nome deve ser o ID)
│       ├── 12345.docx
│       └── 67890.docx
```

## Passo a Passo para Atualização

### 1. Atualizar Arquivos CSV

Substitua os arquivos `.csv` na pasta `data/` com as versões mais recentes exportadas dos seus sistemas de origem. Mantenha os nomes dos arquivos ou ajuste o script de ingestão se necessário.

**Formatos Esperados:**

- **solicitacoes.csv**: Separador `;`, encoding `latin-1`. Colunas: `id`, `work_item_type`, `title`, `status`, `responsavel`, `tipo_solicitacao`, `effort`, etc.
- **custos.csv**: Separador `,`. Colunas: `tipo`, `valor`.

### 2. Adicionar Novos Manuais

Coloque novos arquivos PDF ou DOCX na pasta `data/manuais/`. Eles serão processados e indexados automaticamente.

### 3. Executar o Script de Ingestão

Para processar os novos dados e atualizar o banco de dados Neo4j, execute o seguinte comando no terminal (na raiz do projeto):

```bash
uv run run_ingestion.py
```

> **Atenção:** Por padrão, este script **LIMPA** o banco de dados antes de recarregar tudo. Isso garante que dados antigos ou deletados não permaneçam. Se desejar apenas adicionar dados sem apagar (modo incremental), edite o arquivo `run_ingestion.py` e altere `clear_db=True` para `clear_db=False` na última linha.

### 4. Verificar no Dashboard

Após a execução do script (que pode levar alguns minutos dependendo da quantidade de dados), recarregue a página do Dashboard. Os novos números e documentos já estarão disponíveis.

## Solução de Problemas

- **Erro de Encoding**: Se o script falhar ao ler um CSV, verifique se ele foi salvo como `UTF-8` ou `Latin-1` (ANSI). O padrão atual é `Latin-1` para compatibilidade com Excel em português.
- **Dados Zerados**: Verifique se os nomes das colunas nos CSVs correspondem exatamente ao esperado pelo script `src/rag_sysrh/data_ingestion.py`.
