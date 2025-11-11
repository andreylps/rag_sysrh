import argparse
import logging
import os
import re
from pathlib import Path
from typing import LiteralString

import pandas as pd
from docx import Document
from docx.document import Document as DocumentObject
from dotenv import load_dotenv
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from neo4j import GraphDatabase
from tqdm import tqdm


class DataIngestor:
    """
    Classe para conectar ao Neo4j e ingerir dados de diversas fontes.
    """

    def __init__(self, uri, user, password) -> None:  # noqa: ANN001
        # Inicializa a conexão com o banco de dados
        self.driver = GraphDatabase.driver(uri, auth=(user, password))
        logging.info("Conexão com o Neo4j estabelecida.")  # noqa: LOG015
        # Configura o text splitter para quebrar os documentos em chunks
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1500,  # Tamanho máximo de cada chunk
            chunk_overlap=200,  # Sobreposição para manter o contexto entre chunks
            separators=[
                "\n\n",
                "#",  # Adicionado para respeitar cabeçalhos Markdown
                "##",  # Adicionado para respeitar cabeçalhos Markdown
                "\n",
                " ",
                "",
            ],  # Prioriza quebras em parágrafos Markdown
        )
        # Inicializa o modelo de embeddings da OpenAI
        self.embedding_model = OpenAIEmbeddings(
            model="text-embedding-ada-002", timeout=60.0
        )

    def close(self) -> None:
        # Fecha a conexão com o banco de dados
        self.driver.close()
        logging.info("Conexão com o Neo4j fechada.")  # noqa: LOG015

    def setup_constraints(self) -> None:
        """
        Cria constraints (regras de unicidade) no banco para garantir
        que não haja nós duplicados. É uma boa prática e otimiza as buscas.
        """
        queries: list[LiteralString] = [
            "CREATE CONSTRAINT IF NOT EXISTS FOR (c:Cliente) REQUIRE c.nome IS UNIQUE",
            "CREATE CONSTRAINT IF NOT EXISTS FOR (s:Solicitacao) REQUIRE s.id IS UNIQUE",  # noqa: E501
            "CREATE CONSTRAINT IF NOT EXISTS FOR (r:RCM) REQUIRE r.id IS UNIQUE",
            "CREATE CONSTRAINT IF NOT EXISTS FOR (m:Manual) REQUIRE m.nome IS UNIQUE",
            "CREATE CONSTRAINT IF NOT EXISTS FOR (c:Chunk) REQUIRE c.id IS UNIQUE",
        ]
        with self.driver.session() as session:
            for query in queries:
                session.run(query)
            # Cria o índice de vetor para os chunks
            session.run(
                """CREATE VECTOR INDEX `manual-chunks` IF NOT EXISTS FOR (c:Chunk) ON (c.embedding)
                   OPTIONS { indexConfig: { `vector.dimensions`: 1536, `vector.similarity_function`: 'cosine' } }
                """  # noqa: E501
            )
        logging.info("Constraints de unicidade garantidas no Neo4j.")  # noqa: LOG015

    def doc_to_markdown(self, doc: DocumentObject) -> str:
        """
        Converte um objeto Document do python-docx para uma string Markdown.
        Identifica títulos e listas com base nos estilos do Word.
        """
        markdown_lines = []
        for para in doc.paragraphs:
            text = para.text.strip()
            if not text:
                continue

            # Adiciona uma verificação para evitar erro se o estilo ou seu nome não existirem.  # noqa: E501
            # Se para.style for None, style_name será uma string vazia.
            style_name = ""
            if para.style:
                style_name = (para.style.name or "").lower()

            if style_name.startswith(("heading 1", "título 1")):
                markdown_lines.append(f"# {text}")
            elif style_name.startswith(("heading 2", "título 2")):
                markdown_lines.append(f"## {text}")
            elif style_name.startswith(("heading 3", "título 3")):
                markdown_lines.append(f"### {text}")
            elif "list paragraph" in style_name or "item de lista" in style_name:
                # Simplificação: trata todos os itens de lista como listas com marcadores.
                # O nível de recuo (list level) pode ser usado para listas aninhadas.
                markdown_lines.append(f"* {text}")
            else:
                markdown_lines.append(text)

        return "\n\n".join(markdown_lines)

    def ingest_solicitacoes(self, df):
        """
        Recebe um DataFrame de solicitações e cria os nós (Cliente) e (Solicitacao)
        e o relacionamento entre eles.
        """
        logging.info("Iniciando ingestão de %s solicitações.", len(df))

        # Usamos uma transação para garantir a integridade dos dados
        with self.driver.session() as session:
            # A query usa MERGE para evitar duplicatas e criar nós/relacionamentos
            # UNWIND transforma a lista de solicitações em linhas para processamento em lote  # noqa: E501
            query_solicitacao = """
            UNWIND $solicitacoes as row
            MERGE (s:Solicitacao {id: row.solicitacao_id})
                ON CREATE SET
                    s.tipo = row.solicitacao_tipo,
                    s.Title = row.Title,
                    s.descricao = row.solicitacao_descricao,
                    s.data_abertura = date(row.solicitacao_data),
                    s.status = 'Aberta'
            """
            query_relacionamento = """
            UNWIND $solicitacoes as row
            MATCH (s:Solicitacao {id: row.solicitacao_id})
            MERGE (c:Cliente {nome: row.cliente_nome})
            MERGE (s)-[:ASSOCIADA_A {comment: "Indica a qual cliente uma solicitação pertence"}]->(c)
            """
            # Convertendo o DataFrame para uma lista de dicionários
            solicitacoes_list = df.to_dict("records")

            # Executa a query em lotes para melhor performance
            # tqdm adiciona uma barra de progresso
            for i in tqdm(
                range(0, len(solicitacoes_list), 1000), desc="Ingerindo Solicitações"
            ):
                batch = solicitacoes_list[i : i + 1000]
                session.run(query_solicitacao, solicitacoes=batch)

                # Cria relacionamentos apenas para as linhas que têm cliente_nome
                batch_com_cliente = [row for row in batch if row.get("cliente_nome")]
                if batch_com_cliente:
                    session.run(query_relacionamento, solicitacoes=batch_com_cliente)

        logging.info("Ingestão de solicitações concluída com sucesso!")

    def ingest_rcms(self, rcm_folder_path: Path, df_solicitacoes: pd.DataFrame) -> None:
        """
        Lê arquivos .doc de uma pasta, cria nós (RCM) e os conecta
        às Solicitações existentes, usando o número do processo no título como chave.
        """
        logging.info("Iniciando ingestão de RCMs da pasta '%s'...", rcm_folder_path)
        rcm_files = list(rcm_folder_path.glob("*.doc*"))

        if not rcm_files:
            logging.info("Nenhum arquivo RCM (.doc, .docx) encontrado.")
            return

        # Garante que a coluna 'Title' exista para a busca
        if "Title" not in df_solicitacoes.columns:
            logging.warning(
                "A coluna 'Title' não foi encontrada no CSV de solicitações. Pulando ingestão de RCMs."
            )
            return

        # Abre a sessão uma vez para reutilizar em todos os arquivos
        with self.driver.session() as session:
            for file_path in tqdm(rcm_files, desc="Ingerindo RCMs"):
                # Extrai o número do processo do nome do arquivo. Ex: "...-3225-2025.doc" -> "3225/2025"
                match = re.search(r"(\d+-\d+)", file_path.name)
                if not match:
                    logging.warning(
                        "Não foi possível extrair o número do processo de '%s'. Pulando arquivo.",
                        file_path.name,
                    )
                    continue

                processo_num = match.group(1).replace("-", "/")

                # Procura no DataFrame pela solicitação que contém esse número de processo no título
                solicitacao_row = df_solicitacoes[
                    df_solicitacoes["Title"].str.startswith(processo_num, na=False)
                ]

                if solicitacao_row.empty:
                    logging.warning(
                        "Nenhuma solicitação encontrada para o processo '%s' do arquivo '%s'. Pulando arquivo.",
                        processo_num,
                        file_path.name,
                    )
                    continue

                solicitacao_id = float(solicitacao_row.iloc[0]["solicitacao_id"])
                rcm_id = int(processo_num.split("/")[0])  # Usa o '3225' como ID do RCM
                try:
                    # Lê o conteúdo do arquivo .doc
                    doc = Document(str(file_path))
                    markdown_text = self.doc_to_markdown(doc)

                    # 1. Cria o nó RCM principal e o conecta à Solicitação
                    query_rcm = """
                    MATCH (s:Solicitacao {id: $solicitacao_id})
                    MERGE (r:RCM {id: $rcm_id})
                        ON CREATE SET
                            r.nome = $rcm_nome
                    MERGE (r)-[:ORIGINADO_DE {comment: "Indica que uma RCM foi criada a partir de uma solicitação"}]->(s)
                    """
                    session.run(
                        query_rcm,
                        solicitacao_id=solicitacao_id,
                        rcm_id=rcm_id,
                        rcm_nome=file_path.name,
                    )

                    # 2. Quebra o texto em chunks
                    chunks = self.text_splitter.split_text(markdown_text)

                    # 3. Para cada chunk, gera embedding, cria o nó e a relação
                    for i, chunk_text in enumerate(chunks):
                        embedding = self.embedding_model.embed_query(chunk_text)
                        chunk_id = f"{file_path.name}-{i}"
                        query_chunk = """
                        MATCH (r:RCM {id: $rcm_id})
                        MERGE (c:Chunk {id: $chunk_id})
                        ON CREATE SET
                            c.texto = $texto,
                            c.embedding = $embedding
                        MERGE (c)-[:PARTE_DE]->(r)
                        """
                        session.run(
                            query_chunk,
                            rcm_id=rcm_id,
                            chunk_id=chunk_id,
                            texto=chunk_text,
                            embedding=embedding,
                        )

                except Exception as e:
                    logging.exception(
                        "Erro ao processar o arquivo RCM '%s': %s. Pulando.",
                        file_path.name,
                        e,
                    )

        logging.info("Ingestão de RCMs concluída com sucesso!")

    def ingest_calculos(self, calculo_folder_path: Path) -> None:
        """
        Lê arquivos .xlsx de uma pasta, extrai o valor do esforço e
        adiciona como uma propriedade ao nó (RCM) correspondente.
        """
        logging.info(
            "Iniciando ingestão de Memórias de Cálculo da pasta '%s'...",
            calculo_folder_path,
        )
        calculo_files = list(calculo_folder_path.glob("*.xls*"))

        if not calculo_files:
            logging.info("Nenhum arquivo de cálculo (.xls, .xlsx) encontrado.")
            return

        # Abre a sessão uma vez para reutilizar em todos os arquivos
        with self.driver.session() as session:
            for file_path in tqdm(calculo_files, desc="Ingerindo Cálculos"):
                # Extrai o número do processo do nome do arquivo. Ex: "...-3225-2025.xlsx" -> 3225
                match = re.search(r"(\d+)", file_path.name)
                if not match:
                    logging.warning(
                        "Não foi possível extrair o ID do RCM de '%s'. Pulando arquivo.",
                        file_path.name,
                    )
                    continue

                rcm_id = int(match.group(1))

                # Lê a planilha e extrai o valor de uma célula específica.
                # --- ATENÇÃO: Ajuste a célula (ex: 'F11') para a sua planilha ---
                try:
                    # Lê a planilha 'Contagem' e extrai o valor da célula F21
                    df_calculo = pd.read_excel(
                        file_path, sheet_name="Contagem", header=None
                    )
                    # O .iloc[20, 5] corresponde à célula F21 (linha 21, coluna F)
                    esforco_horas = df_calculo.iloc[20, 5]
                except Exception as e:
                    logging.exception(
                        "Erro ao ler o arquivo '%s': %s. Pulando.", file_path.name, e
                    )
                    continue

                # Query para encontrar o RCM e adicionar a propriedade de esforço
                query = """
            MATCH (r:RCM {id: $rcm_id})
            SET r.esforco_horas = $esforco
            """
                session.run(query, rcm_id=rcm_id, esforco=esforco_horas)

        logging.info("Ingestão de Memórias de Cálculo concluída com sucesso!")

    def ingest_manuais(self, manuais_folder_path: Path) -> None:
        """
        Lê arquivos de manuais (.docx), cria nós (Manual) e os armazena no grafo.
        """
        logging.info(
            "Iniciando ingestão de Manuais da pasta '%s'...", manuais_folder_path
        )
        # Usamos rglob para buscar arquivos recursivamente em subdiretórios
        manual_files = list(manuais_folder_path.rglob("*.doc*"))

        if not manual_files:
            logging.info("Nenhum arquivo de manual (.doc, .docx) encontrado.")
            return

        with self.driver.session() as session:
            for file_path in tqdm(manual_files, desc="Ingerindo Manuais"):
                try:
                    doc = Document(str(file_path))
                    markdown_text = self.doc_to_markdown(doc)

                    # Extrai o código UCS do nome do arquivo, ex: "UCS0083"
                    match = re.search(r"(UCS\d+)", file_path.name, re.IGNORECASE)
                    ucs_code = match.group(1).upper() if match else None

                    # 1. Cria ou atualiza o nó Manual principal (sem o texto completo)
                    query = """
                    MERGE (m:Manual {nome: $manual_nome})
                    ON CREATE SET
                        m.codigo_ucs = $ucs_code
                    """
                    session.run(query, manual_nome=file_path.name, ucs_code=ucs_code)

                    # 2. Quebra o texto em chunks
                    chunks = self.text_splitter.split_text(markdown_text)

                    # 3. Para cada chunk, gera o embedding, cria um nó :Chunk e o conecta ao Manual
                    for i, chunk_text in enumerate(chunks):
                        # Gera o embedding para o chunk
                        embedding = self.embedding_model.embed_query(chunk_text)
                        chunk_id = (
                            f"{file_path.name}-{i}"  # Cria um ID único para o chunk
                        )
                        query_chunk = """
                        MATCH (m:Manual {nome: $manual_nome})
                        MERGE (c:Chunk {id: $chunk_id})
                        ON CREATE SET 
                            c.texto = $texto,
                            c.embedding = $embedding
                        MERGE (c)-[:PARTE_DE]->(m)
                        """
                        session.run(
                            query_chunk,
                            manual_nome=file_path.name,
                            chunk_id=chunk_id,
                            texto=chunk_text,  # Salva o texto original do chunk
                            embedding=embedding,  # Salva o vetor de embedding
                        )

                except Exception as e:
                    logging.exception(
                        "Erro ao ler o arquivo de manual '%s': %s. Pulando.",
                        file_path.name,
                        e,
                    )
        logging.info("Ingestão de Manuais concluída com sucesso!")


def install_missing_libraries():
    # Função para instalar bibliotecas que podem estar faltando
    pass


def main() -> None:
    """
    Função principal para orquestrar o processo de ingestão de dados.
    """
    # Carrega as variáveis de ambiente do arquivo .env
    load_dotenv()

    # --- Configuração dos Argumentos da Linha de Comando ---
    project_root = Path(__file__).resolve().parent.parent.parent
    default_data_path = project_root / "data"

    parser = argparse.ArgumentParser(
        description="Script para ingerir dados de solicitações, RCMs e cálculos para o Neo4j."
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=default_data_path / "solicitacoes.csv",
        help="Caminho para o arquivo CSV de solicitações.",
    )
    parser.add_argument(
        "--rcms",
        type=Path,
        default=default_data_path / "rcms",
        help="Caminho para a pasta contendo os arquivos RCM (.doc, .docx).",
    )
    parser.add_argument(
        "--calculos",
        type=Path,
        default=default_data_path / "calculos",
        help="Caminho para a pasta contendo as planilhas de cálculo (.xls, .xlsx).",
    )
    parser.add_argument(
        "--manuais",
        type=Path,
        default=default_data_path / "manuais",
        help="Caminho para a pasta contendo os arquivos de manuais (.doc, .docx).",
    )
    args = parser.parse_args()

    # Configura o logging para exibir mensagens de nível INFO e acima
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # --- Mapeamento das colunas do seu CSV para os nomes que o script espera ---
    colunas_mapeadas = {
        "Title": "Title",  # Mantém a coluna Title para a busca
        "ID": "solicitacao_id",
        "Work Item Type": "cliente_nome",  # Usando 'Work Item Type' como nome do cliente
        "TipoSolicitacao": "solicitacao_tipo",
        "Description": "solicitacao_descricao",
        "Created Date": "solicitacao_data",  # Formato esperado: 'YYYY-MM-DD' ou 'DD/MM/YYYY HH:MM'
    }

    # Carrega as credenciais do ambiente
    NEO4J_URI = os.getenv("NEO4J_URI")
    NEO4J_USER = os.getenv("NEO4J_USER")
    NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD")

    # --- Ingestão de Solicitações (CSV) ---
    if args.csv.exists():
        df_solicitacoes = pd.read_csv(args.csv, sep=";", skiprows=1, encoding="latin-1")
        df_solicitacoes = df_solicitacoes.rename(columns=colunas_mapeadas)

        # --- NOVA ETAPA DE LIMPEZA ---
        # Remove o prefixo "SOLICITACAO " do nome do cliente para normalizar o dado.
        # Ex: "SOLICITACAO ALESC" -> "ALESC"
        if "cliente_nome" in df_solicitacoes.columns:
            df_solicitacoes["cliente_nome"] = (
                df_solicitacoes["cliente_nome"]
                .str.replace(r"SOLICITACAO\s*", "", case=False, regex=True)
                .str.strip()
            )

        # Garante que o ID da solicitação não é nulo
        df_solicitacoes.dropna(subset=["solicitacao_id"], inplace=True)
        df_solicitacoes["solicitacao_id"] = df_solicitacoes["solicitacao_id"].astype(
            float
        )
        df_solicitacoes["solicitacao_data"] = pd.to_datetime(
            df_solicitacoes["solicitacao_data"], dayfirst=True, errors="coerce"
        ).dt.strftime("%Y-%m-%d")
    else:
        df_solicitacoes = pd.DataFrame()
        logging.warning(
            "Arquivo '%s' não encontrado. Pulando ingestão de solicitações.", args.csv
        )

    # --- Inicia o processo de ingestão ---
    ingestor = DataIngestor(NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD)
    ingestor.setup_constraints()

    if not df_solicitacoes.empty:
        ingestor.ingest_solicitacoes(df_solicitacoes.copy())

    ingestor.ingest_rcms(
        rcm_folder_path=args.rcms, df_solicitacoes=df_solicitacoes.copy()
    )

    ingestor.ingest_calculos(calculo_folder_path=args.calculos)

    ingestor.ingest_manuais(manuais_folder_path=args.manuais)

    ingestor.close()


if __name__ == "__main__":
    main()
