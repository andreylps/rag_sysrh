import logging
import os
from pathlib import Path

import ftfy
import pandas as pd
from dotenv import load_dotenv
from langchain_community.document_loaders import (
    Docx2txtLoader,
    PyPDFLoader,
    UnstructuredExcelLoader,
)
from langchain_community.graphs import Neo4jGraph
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class DataIngestion:
    """
    Classe responsável por carregar documentos, processá-los e ingeri-los
    em um banco de dados Neo4j, criando nós e um índice vetorial.
    """

    def __init__(
        self,
        data_directory: str,
        structured_data_path: str,
        single_manual_path: str | None = None,
    ) -> None:
        """
        Inicializa o processo de ingestão de dados.

        Args:
            data_directory (str): O caminho para o diretório que contém os arquivos de dados.
            structured_data_path (str): O caminho para o arquivo CSV com dados estruturados.
            single_manual_path (str | None): O caminho para um único arquivo de manual a ser processado.
        """  # noqa: E501
        # Garante que o .env seja carregado a partir da raiz do projeto
        project_root = Path(__file__).resolve().parent.parent.parent
        dotenv_path = project_root / ".env"
        load_dotenv(dotenv_path=dotenv_path)

        if not os.path.exists(data_directory):  # noqa: PTH110
            msg = f"O diretório de dados especificado não foi encontrado: {data_directory}"  # noqa: E501
            raise FileNotFoundError(msg)

        self.data_directory = data_directory
        self.structured_data_path = structured_data_path
        self.single_manual_path = single_manual_path
        self.embeddings = OpenAIEmbeddings()

        try:
            uri = os.getenv("NEO4J_URI")
            username = os.getenv("NEO4J_USERNAME")
            password = os.getenv("NEO4J_PASSWORD")
            if not all([uri, username, password]):
                msg = "As variáveis de ambiente do Neo4j não foram definidas."
                raise ValueError(  # noqa: TRY301
                    msg
                )
            self.graph = Neo4jGraph(url=uri, username=username, password=password)
            logging.info("Conexão com o Neo4j estabelecida com sucesso.")  # noqa: LOG015
        except ValueError as ve:
            logging.exception(f"Erro de configuração do Neo4j: {ve}")  # noqa: G004, LOG015, TRY401
            raise
        except Exception as e:
            logging.exception(f"Falha ao conectar com o Neo4j: {e}")  # noqa: G004, LOG015, TRY401
            raise

    def _load_documents(self) -> list:
        """Carrega documentos de diferentes formatos (PDF, DOCX, XLSX, CSV)."""
        documents = []

        files_to_process = []
        if self.single_manual_path:
            # Constrói o caminho absoluto para o manual a partir da raiz do projeto
            manual_abs_path = (
                Path(__file__).resolve().parent.parent.parent / self.single_manual_path
            )
            if manual_abs_path.exists():
                files_to_process.append(str(manual_abs_path))
            else:
                logging.error(  # noqa: LOG015
                    "Arquivo de manual especificado não encontrado: %s",
                    manual_abs_path,  # Loga o caminho absoluto para facilitar a depuração  # noqa: E501
                )
        else:
            data_dir_abs_path = (
                Path(__file__).resolve().parent.parent.parent / self.data_directory
            )
            for filename in os.listdir(data_dir_abs_path):  # noqa: PTH208
                files_to_process.append(os.path.join(data_dir_abs_path, filename))  # noqa: PERF401, PTH118

        for filepath in files_to_process:
            filename = os.path.basename(filepath)  # noqa: PTH119
            try:
                if filename.endswith(".pdf"):
                    loader = PyPDFLoader(filepath)
                    documents.extend(loader.load())
                elif filename.endswith(".docx"):
                    loader = Docx2txtLoader(filepath)
                    documents.extend(loader.load())
                elif filename.endswith(".xlsx"):
                    loader = UnstructuredExcelLoader(filepath, mode="elements")
                    documents.extend(loader.load())
            except Exception as e:
                logging.exception(f"Erro ao carregar o arquivo {filename}: {e}")  # noqa: G004, LOG015, TRY401

        return documents

    def _load_and_ingest_cost_data(self) -> None:
        """Carrega dados de custo de um CSV e cria nós :Custo."""
        cost_data_path = (
            Path(__file__).resolve().parent.parent.parent / "data" / "custos.csv"
        )
        if not cost_data_path.exists():
            logging.warning(  # noqa: LOG015
                "Arquivo de dados de custo não encontrado em %s. Pulando esta etapa.",
                cost_data_path,
            )
            return

        logging.info("Ingerindo dados de custo de %s...", cost_data_path)  # noqa: LOG015

        try:
            df = pd.read_csv(cost_data_path, sep=";", encoding="latin-1")
            records = df.to_dict("records")

            ingest_query = """
            UNWIND $records AS record
            MERGE (c:Custo {tipo: record.tipo_custo, chave: record.chave})
            ON CREATE SET c.valor = toFloat(record.valor)
            ON MATCH SET c.valor = toFloat(record.valor)
            """
            self.graph.query(ingest_query, params={"records": records})
            logging.info("Ingestão de dados de custo concluída.")  # noqa: LOG015
        except Exception as e:
            logging.exception("Falha ao ingerir dados de custo: %s", e)  # noqa: LOG015, TRY401
            raise

    def _load_and_ingest_structured_data(self) -> None:
        """Carrega dados estruturados de um CSV e cria nós e relacionamentos."""
        structured_data_abs_path = (
            Path(__file__).resolve().parent.parent.parent / self.structured_data_path
        )
        if not structured_data_abs_path.exists():
            logging.warning(  # noqa: LOG015
                "Arquivo de dados estruturados não encontrado em %s. Pulando esta etapa.",  # noqa: E501
                structured_data_abs_path,
            )
            return

        logging.info("Ingerindo dados estruturados de %s...", structured_data_abs_path)  # noqa: LOG015

        try:
            # Carrega os dados com pandas, especificando o separador e o encoding
            df = pd.read_csv(
                structured_data_abs_path,
                sep=";",
                skiprows=1,  # Ignora a primeira linha do arquivo
                encoding="latin-1",
                on_bad_lines="skip",
            )
            # Renomeia colunas para facilitar o acesso, removendo espaços e caracteres especiais  # noqa: E501
            df.columns = [
                "id",
                "work_item_type",
                "title",
                "status",
                "responsavel",
                "tipo_solicitacao",
                "iteration_path",
                "description",  # Mapeia diretamente a coluna correta
                "created_date",
                "effort",
            ]
            df["cliente"] = df["work_item_type"].str.replace("SOLICITACAO ", "")

            # Limpa caracteres corrompidos em ambas as colunas
            df["title"] = df["title"].apply(
                lambda x: ftfy.fix_text(str(x)) if pd.notna(x) else x
            )
            df["description"] = df["description"].apply(
                lambda x: ftfy.fix_text(str(x)) if pd.notna(x) else x
            )

            # 1. Preserva a descrição original (já limpa) em uma nova coluna 'texto_completo'  # noqa: E501
            df["texto_completo"] = df["description"]
            # 2. Sobrescreve a coluna 'description' do DataFrame com o título (já limpo)
            df["description"] = df["title"]

            df["texto_completo"] = df["texto_completo"].apply(
                lambda x: ftfy.fix_text(str(x)) if pd.notna(x) else x
            )

            # Remove linhas onde o 'id' da solicitação é nulo para evitar erros no MERGE
            df = df.dropna(subset=["id", "responsavel"])

            # Converte o dataframe para uma lista de dicionários
            records = df.to_dict("records")

            # Define a query para ingestão em lote
            ingest_query = """
            UNWIND $records AS record
            // Cria ou atualiza a Solicitação
            MERGE (s:Solicitacao {id: toFloat(record.id)}) // Usa o ID para encontrar o nó
            // Define ou atualiza as propriedades, garantindo o nome correto 'description'
            SET s.title = record.title, s.status = record.status, s.description = record.description, s.texto_completo = record.texto_completo, s.tipo_solicitacao = record.tipo_solicitacao, s.effort = toFloat(record.effort)
            // Cria ou atualiza o Cliente
            MERGE (c:Cliente {nome: record.cliente})
            // Cria ou atualiza o Responsável
            MERGE (r:Responsavel {nome: record.responsavel})
            // Cria relacionamentos
            MERGE (s)-[:ASSOCIADA_A]->(c)
            MERGE (s)-[:ATRIBUIDA_A]->(r)
            """  # noqa: E501
            # Executa a query com os dados em lote
            self.graph.query(ingest_query, params={"records": records})
            logging.info("Ingestão de dados estruturados concluída.")  # noqa: LOG015
        except Exception as e:
            logging.exception("Falha ao ingerir dados estruturados: %s", e)  # noqa: LOG015, TRY401
            raise

    def run_ingestion(self) -> None:
        """
        Executa o pipeline completo de ingestão de dados.
        """
        logging.info("Limpando banco de dados Neo4j existente...")  # noqa: LOG015
        self.graph.query("MATCH (n) DETACH DELETE n")

        # 1. Ingestão de dados estruturados (Solicitações, Clientes, etc.)
        self._load_and_ingest_structured_data()

        # 2. Ingestão de dados de custo
        self._load_and_ingest_cost_data()

        # 2. Ingestão de documentos não estruturados (Manuais)
        logging.info("Iniciando o carregamento dos documentos não estruturados...")  # noqa: LOG015

        documents = self._load_documents()

        logging.info(f"{len(documents)} documentos carregados.")  # noqa: G004, LOG015

        logging.info("Dividindo os documentos em trechos (chunks)...")  # noqa: LOG015
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000, chunk_overlap=200
        )
        chunks = text_splitter.split_documents(documents)
        logging.info(f"Documentos divididos em {len(chunks)} trechos.")  # noqa: G004, LOG015

        logging.info("Ingerindo chunks no Neo4j...")  # noqa: LOG015
        for chunk in chunks:
            # Extrai metadados e texto do chunk
            source_doc = chunk.metadata.get("source", "desconhecido").split(os.sep)[-1]  # noqa: PTH206
            page = chunk.metadata.get("page", 0)

            # Cria nós :Manual e :Chunk e o relacionamento entre eles
            self.graph.query(
                """
                MERGE (m:Manual {nome: $source_doc})
                CREATE (c:Chunk {texto: $texto, pagina: $page})
                MERGE (c)-[:PARTE_DE]->(m)
                """,
                params={
                    "source_doc": source_doc,
                    "texto": chunk.page_content,
                    "page": page,
                },
            )

        logging.info("Criação de nós e relacionamentos concluída.")  # noqa: LOG015

        logging.info("Criando índice vetorial no Neo4j...")  # noqa: LOG015
        self.graph.query("""
            CREATE VECTOR INDEX `manual-chunks` IF NOT EXISTS
            FOR (c:Chunk) ON (c.embedding)
            OPTIONS { indexConfig: {
                `vector.dimensions`: 1536,
                `vector.similarity_function`: 'cosine'
            }}
        """)

        logging.info("Calculando e adicionando embeddings aos nós...")  # noqa: LOG015
        self.graph.query(
            """
            MATCH (chunk:Chunk) WHERE chunk.embedding IS NULL
            WITH chunk, genai.vector.encode(
              chunk.texto,
              "OpenAI",
              {token: $openAiApiKey}
            ) AS vector
            CALL db.create.setNodeVectorProperty(chunk, "embedding", vector)
            """,
            params={"openAiApiKey": os.getenv("OPENAI_API_KEY")},
        )

        logging.info("Ingestão de dados no Neo4j concluída com sucesso!")  # noqa: LOG015


if __name__ == "__main__":
    # Exemplo de uso:
    # Crie uma pasta 'data' na raiz do projeto e coloque seus PDFs lá.
    # Adicione também um arquivo 'solicitacoes.csv' com os dados estruturados.
    # Certifique-se de que as variáveis de ambiente (NEO4J_*, OPENAI_API_KEY) estão no .env  # noqa: E501
    # Para ingerir apenas um manual, passe o caminho para ele.
    # Ex: single_manual_path="data/manual_especifico.pdf"
    ingestion_pipeline = DataIngestion(
        data_directory="data",
        structured_data_path="data/solicitacoes.csv",
        single_manual_path="data/manuais/SIGRH - PSE - Processo Seletivo/UCS0325 - Manter Edital.docx",  # noqa: E501
    )
    ingestion_pipeline.run_ingestion()
