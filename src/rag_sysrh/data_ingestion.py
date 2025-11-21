import logging
import os
from pathlib import Path

import ftfy  # type: ignore
import pandas as pd  # type: ignore
from dotenv import load_dotenv  # pyright: ignore[reportMissingImports]
from langchain_community.document_loaders import (  # pyright: ignore[reportMissingImports]
    Docx2txtLoader,
    PyPDFLoader,
    UnstructuredExcelLoader,
)
from langchain_community.graphs import (  # type: ignore
    Neo4jGraph,  # pyright: ignore[reportMissingImports]
)
from langchain_openai import OpenAIEmbeddings  # type: ignore
from langchain_text_splitters import RecursiveCharacterTextSplitter  # type: ignore

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
        rcm_data_path: str,
        single_manual_path: str | None = None,
    ) -> None:
        """
        Inicializa o processo de ingestão de dados.

        Args:
            data_directory (str): O caminho para o diretório que contém os arquivos de dados.
            structured_data_path (str): O caminho para o arquivo CSV com dados estruturados.
            rcm_data_path (str): O caminho para o arquivo CSV com metadados de RCMs.
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
        self.rcm_data_path = rcm_data_path
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
            # Percorre recursivamente todos os subdiretórios
            for root, _, files in os.walk(data_dir_abs_path):
                for filename in files:
                    files_to_process.append(os.path.join(root, filename))

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
            Path(__file__).resolve().parent.parent.parent
            / "data"
            / "faturamento"
            / "custos.csv"
        )
        if not cost_data_path.exists():
            logging.warning(  # noqa: LOG015
                "Arquivo de dados de custo não encontrado em %s. Pulando esta etapa.",
                cost_data_path,
            )
            return

        logging.info("Ingerindo dados de custo de %s...", cost_data_path)  # noqa: LOG015

        try:
            df = pd.read_csv(cost_data_path, sep=",", encoding="latin-1")
            records = df.to_dict("records")

            ingest_query = """
            UNWIND $records AS record
            MERGE (c:Custo {tipo: record.tipo})
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

    def _load_and_ingest_rcm_data(self) -> None:
        """Carrega metadados de RCMs, seus documentos .docx e cria nós e relacionamentos."""  # noqa: E501
        rcm_data_abs_path = (
            Path(__file__).resolve().parent.parent.parent / self.rcm_data_path
        )
        if not rcm_data_abs_path.exists():
            logging.warning(  # noqa: LOG015
                "Arquivo de metadados de RCM não encontrado em %s. Pulando esta etapa.",
                rcm_data_abs_path,
            )
            return

        logging.info("Ingerindo dados de RCMs de %s...", rcm_data_abs_path)  # noqa: LOG015
        try:
            df = pd.read_csv(rcm_data_abs_path, sep=";", encoding="latin-1", skiprows=1)
            # Renomeia as colunas para um formato limpo e previsível
            # Renomeia as colunas para um formato limpo e previsível
            df.columns = [
                "rcm_id_raw",
                "work_item_type",  # Usado para extrair o cliente
                "title",  # Contém o ID da RCM e a descrição
                "status",
                "responsavel",
                "tipo_solicitacao",
                "iteration_path",
                "description",
                "created_date",
                "effort",  # Mapeado para pontos_funcao ou horas_reais
                "data_prevista_entrega",
                "data_conclusao_real",
            ]
            # Usa a coluna 'rcm_id_raw' (que é o ID original do item de trabalho) como o identificador principal.
            # Isso é mais robusto do que extrair do título.
            df["rcm_id"] = df["rcm_id_raw"].astype(str)

            # Remove linhas onde o rcm_id não foi encontrado para evitar erros de NaN
            df = df.dropna(subset=["rcm_id"])

            # Garante que as colunas numéricas tenham um valor padrão (0) se estiverem vazias
            df["effort"] = pd.to_numeric(df["effort"], errors="coerce").fillna(0.0)
            # Cria a coluna 'horas_reais' a partir de 'effort' e garante que seja numérica
            df["horas_reais"] = pd.to_numeric(df["effort"], errors="coerce").fillna(0)

            rcm_records = df.to_dict("records")

            # 1. Ingestão em LOTE dos nós RCM (CORRIGIDO)
            ingest_rcm_query = """
            UNWIND $records AS record
            MERGE (rcm:RCM {id: record.rcm_id})
            SET rcm += {
                status: record.status,
                horas_reais: toFloat(record.horas_reais),
                pontos_funcao: toFloat(record.effort), 
                data_prevista_entrega: record.data_prevista_entrega,
                data_conclusao_real: record.data_conclusao_real,
                titulo: record.title,
                tipo_solicitacao: record.tipo_solicitacao,
                rcm_id_raw: record.rcm_id_raw
            }
            """
            self.graph.query(ingest_rcm_query, params={"records": rcm_records})

            # 2. Criação em LOTE dos relacionamentos com Solicitações (CORRIGIDO)
            link_rcm_solicitacao_query = """
            UNWIND $records AS record
            MATCH (rcm:RCM {id: record.rcm_id})
            MATCH (s:Solicitacao) WHERE record.rcm_id_raw CONTAINS s.title
            MERGE (rcm)-[:ORIGINADO_DE]->(s)
            """
            self.graph.query(
                link_rcm_solicitacao_query, params={"records": rcm_records}
            )

            # 3. Processamento dos documentos .docx associados (continua em loop, pois é I/O de arquivo)
            for record in rcm_records:
                rcm_id = record.get(
                    "rcm_id_raw"
                )  # Usar o ID original para nome do arquivo
                if not rcm_id:
                    continue
                rcm_doc_path = (
                    Path(__file__).resolve().parent.parent.parent
                    / "data"
                    / "rcms"
                    / f"{rcm_id}.docx"
                )
                if rcm_doc_path.exists():
                    logging.info("Processando documento associado: %s", rcm_doc_path)
                    loader = Docx2txtLoader(str(rcm_doc_path))
                    documents = loader.load()

                    text_splitter = RecursiveCharacterTextSplitter(
                        chunk_size=1500, chunk_overlap=200
                    )
                    chunks = text_splitter.split_documents(documents)

                    for chunk in chunks:
                        self.graph.query(
                            """
                            MATCH (rcm:RCM {id: $rcm_node_id})
                            CREATE (c:Chunk {texto: $texto})
                            MERGE (c)-[:PARTE_DE]->(rcm)
                            """,
                            params={
                                "rcm_node_id": record.get("rcm_id"),
                                "texto": chunk.page_content,
                            },
                        )
            logging.info("Ingestão de dados de RCMs concluída.")  # noqa: LOG015
        except Exception as e:
            logging.exception("Falha ao ingerir dados de RCMs: %s", e)  # noqa: LOG015, TRY401
            raise

    def _load_and_ingest_test_cases(self) -> None:
        """Carrega casos de teste de um CSV e cria nós e relacionamentos."""
        test_cases_path = (
            Path(__file__).resolve().parent.parent.parent
            / "data"
            / "casos_de_teste.csv"
        )
        if not test_cases_path.exists():
            logging.warning(  # noqa: LOG015
                "Arquivo de casos de teste não encontrado em %s. Pulando esta etapa.",
                test_cases_path,
            )
            return

        logging.info("Ingerindo casos de teste de %s...", test_cases_path)  # noqa: LOG015

        try:
            df = pd.read_csv(test_cases_path, sep=";", encoding="latin-1")
            # Usa os nomes de coluna do arquivo CSV
            df.columns = [
                "rcm_id",
                "caso_teste_id",
                "descricao_teste",
                "status_teste",
                "data_execucao",
                "responsavel_teste",
                "versao_software",
            ]
            df = df.dropna(subset=["rcm_id", "caso_teste_id", "status_teste"])
            records = df.to_dict("records")

            ingest_query = """
            UNWIND $records AS record
            MERGE (rcm:RCM {id: record.rcm_id})
            ON CREATE SET rcm.titulo = 'RCM criada a partir de caso de teste: ' + record.rcm_id
            CREATE (ct:CasoDeTeste {
                id: record.caso_teste_id,
                descricao: record.descricao_teste,
                status: record.status_teste,
                dataExecucao: record.data_execucao,
                responsavel: record.responsavel_teste,
                versaoSoftware: record.versao_software
            })
            MERGE (rcm)-[:TEM_TESTE]->(ct)
            """
            self.graph.query(ingest_query, params={"records": records})
            logging.info("Ingestão de casos de teste concluída.")  # noqa: LOG015
        except Exception as e:
            logging.exception("Falha ao ingerir casos de teste: %s", e)  # noqa: LOG015, TRY401

    def run_ingestion(self, clear_db: bool = True) -> None:
        """
        Executa o pipeline completo de ingestão de dados.

        Args:
            clear_db (bool): Se True, apaga todos os dados do banco antes de ingerir.
                             Se False, apenas adiciona/atualiza (MERGE).
        """
        if clear_db:
            logging.info("Limpando banco de dados Neo4j existente...")  # noqa: LOG015
            self.graph.query("MATCH (n) DETACH DELETE n")
        else:
            logging.info("Modo incremental: Mantendo dados existentes no Neo4j.")

        # Fase 1: Ingestão de dados estruturados (Solicitações, Clientes, etc.)
        self._load_and_ingest_structured_data()

        # Fase 2: Ingestão de dados de custo
        self._load_and_ingest_cost_data()

        # Fase 3: Ingestão de RCMs e seus documentos associados
        self._load_and_ingest_rcm_data()

        # Fase 3.5: Ingestão de Casos de Teste associados às RCMs
        self._load_and_ingest_test_cases()

        # Fase 4: Ingestão de documentos não estruturados (Manuais)
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
        rcm_data_path="data/rcms_01.csv",
        single_manual_path="data/manuais/SIGRH - PSE - Processo Seletivo/UCS0325 - Manter Edital.docx",  # noqa: E501
    )
    ingestion_pipeline.run_ingestion()
