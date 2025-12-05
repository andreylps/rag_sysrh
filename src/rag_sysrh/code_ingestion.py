import ast
import logging
import os
from pathlib import Path

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph
from langchain_openai import OpenAIEmbeddings

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

load_dotenv()


class CodeIngestion:
    """
    Responsável por analisar o código fonte (Python) e ingerir sua estrutura (Arquivos, Classes, Funções)
    no Neo4j para permitir análises de impacto e correlação com documentação.
    """

    def __init__(self, root_dir: str):
        self.root_dir = Path(root_dir).resolve()
        self.embeddings = OpenAIEmbeddings()

        try:
            url = os.getenv("NEO4J_URI")
            username = os.getenv("NEO4J_USERNAME")
            password = os.getenv("NEO4J_PASSWORD")

            if not all([url, username, password]):
                raise ValueError("Credenciais do Neo4j não encontradas no .env")

            self.graph = Neo4jGraph(url=url, username=username, password=password)
            logger.info("Conexão com Neo4j estabelecida para CodeIngestion.")
        except Exception as e:
            logger.error(f"Falha ao conectar ao Neo4j: {e}")
            raise

    def parse_file(self, file_path: Path) -> dict:
        """
        Analisa um arquivo Python usando AST e extrai classes, funções e docstrings.
        """
        try:
            with open(file_path, encoding="utf-8") as f:
                source = f.read()

            tree = ast.parse(source)

            classes = []
            functions = []

            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    classes.append(
                        {
                            "name": node.name,
                            "docstring": ast.get_docstring(node) or "",
                            "lineno": node.lineno,
                        }
                    )
                elif isinstance(node, ast.FunctionDef):
                    # Ignora métodos dentro de classes por enquanto (serão capturados se fizermos walk recursivo ou check de parent)
                    # Para simplificar, pegamos todas as funções/métodos
                    functions.append(
                        {
                            "name": node.name,
                            "docstring": ast.get_docstring(node) or "",
                            "lineno": node.lineno,
                            "args": [arg.arg for arg in node.args.args],
                        }
                    )

            return {
                "rel_path": str(file_path.relative_to(self.root_dir)),
                "classes": classes,
                "functions": functions,
                "source": source,
            }
        except Exception as e:
            logger.warning(f"Erro ao analisar arquivo {file_path}: {e}")
            return {}

    def ingest_file(self, file_data: dict):
        """
        Cria nós no Neo4j para o arquivo e seus componentes.
        """
        if not file_data:
            return

        rel_path = file_data["rel_path"]
        logger.info(f"Ingerindo estrutura do arquivo: {rel_path}")

        # 1. Cria nó do Arquivo
        query_file = """
        MERGE (f:File {path: $path})
        SET f.name = $name
        """
        self.graph.query(
            query_file, params={"path": rel_path, "name": os.path.basename(rel_path)}
        )

        # 2. Ingestão de Classes
        for cls in file_data["classes"]:
            query_cls = """
            MATCH (f:File {path: $path})
            MERGE (c:Class {name: $cls_name, file_path: $path})
            SET c.docstring = $docstring, c.lineno = $lineno
            MERGE (f)-[:DEFINES_CLASS]->(c)
            """
            self.graph.query(
                query_cls,
                params={
                    "path": rel_path,
                    "cls_name": cls["name"],
                    "docstring": cls["docstring"],
                    "lineno": cls["lineno"],
                },
            )

            # Gera embedding para a classe (Docstring + Nome)
            text_to_embed = f"Class: {cls['name']}\nDocstring: {cls['docstring']}"
            embedding = self.embeddings.embed_query(text_to_embed)

            self.graph.query(
                """
                MATCH (c:Class {name: $cls_name, file_path: $path})
                CALL db.create.setNodeVectorProperty(c, "embedding", $embedding)
            """,
                params={
                    "cls_name": cls["name"],
                    "path": rel_path,
                    "embedding": embedding,
                },
            )

        # 3. Ingestão de Funções
        for func in file_data["functions"]:
            query_func = """
            MATCH (f:File {path: $path})
            MERGE (fn:Function {name: $func_name, file_path: $path})
            SET fn.docstring = $docstring, fn.lineno = $lineno, fn.args = $args
            MERGE (f)-[:DEFINES_FUNCTION]->(fn)
            """
            self.graph.query(
                query_func,
                params={
                    "path": rel_path,
                    "func_name": func["name"],
                    "docstring": func["docstring"],
                    "lineno": func["lineno"],
                    "args": func["args"],
                },
            )

            # Gera embedding para a função
            text_to_embed = f"Function: {func['name']}\nArgs: {func['args']}\nDocstring: {func['docstring']}"
            embedding = self.embeddings.embed_query(text_to_embed)

            self.graph.query(
                """
                MATCH (fn:Function {name: $func_name, file_path: $path})
                CALL db.create.setNodeVectorProperty(fn, "embedding", $embedding)
            """,
                params={
                    "func_name": func["name"],
                    "path": rel_path,
                    "embedding": embedding,
                },
            )

    def run_ingestion(self):
        """
        Percorre o diretório e processa todos os arquivos Python.
        """
        # Cria índices vetoriais se não existirem
        self.graph.query("""
            CREATE VECTOR INDEX `code_class_index` IF NOT EXISTS
            FOR (c:Class) ON (c.embedding)
            OPTIONS { indexConfig: {
                `vector.dimensions`: 1536,
                `vector.similarity_function`: 'cosine'
            }}
        """)
        self.graph.query("""
            CREATE VECTOR INDEX `code_function_index` IF NOT EXISTS
            FOR (f:Function) ON (f.embedding)
            OPTIONS { indexConfig: {
                `vector.dimensions`: 1536,
                `vector.similarity_function`: 'cosine'
            }}
        """)

        for root, _, files in os.walk(self.root_dir):
            for file in files:
                if file.endswith(".py"):
                    full_path = Path(root) / file

                    # Ignora pastas virtuais ou de cache
                    if any(
                        part.startswith(".") or part == "__pycache__" or part == "venv"
                        for part in full_path.parts
                    ):
                        continue

                    file_data = self.parse_file(full_path)
                    self.ingest_file(file_data)


if __name__ == "__main__":
    # Exemplo de uso
    project_root = os.path.join(
        os.path.dirname(__file__), "..", "..", ".."
    )  # Ajuste conforme a localização do script
    ingestor = CodeIngestion(project_root)
    ingestor.run_ingestion()
