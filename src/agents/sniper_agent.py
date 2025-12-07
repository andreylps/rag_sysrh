import json
import os
from typing import Any

from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

load_dotenv()


class SniperAgent:
    """
    Agente responsável por analisar o código fonte e identificar oportunidades de negócio
    baseadas em dívida técnica, segurança e modernização.
    """

    def __init__(self):
        self.llm = ChatOpenAI(
            model="gpt-4o", temperature=0.2, api_key=os.getenv("OPENAI_API_KEY")
        )

        self.system_prompt = """
        Você é um Arquiteto de Software Sênior e Consultor de Pré-Vendas especializado em modernização de sistemas legados.
        
        Sua missão é analisar trechos de código fonte, identificar problemas (dívida técnica, riscos de segurança, 
        gargalos de performance, padrões obsoletos) e transformá-los em OPORTUNIDADES DE NEGÓCIO.
        
        Para cada problema identificado, você deve gerar:
        1. Um título comercial atraente.
        2. Uma descrição técnica do problema.
        3. Um argumento comercial focado em ROI (Retorno sobre Investimento), redução de custos ou mitigação de riscos.
        4. Uma estimativa de esforço em Pontos de Função (PF) ou horas (apenas o número).
        5. A severidade do problema (Alta, Média, Baixa).
        
        Retorne APENAS um JSON válido com a seguinte estrutura (lista de objetos):
        Retorne APENAS um JSON válido com a seguinte estrutura (lista de objetos):
        [
            {{
                "titulo": "Refatoração de...",
                "descricao_tecnica": "O código utiliza...",
                "argumento_comercial": "A modernização deste módulo reduzirá...",
                "estimativa_pf": 10,
                "severidade": "Alta",
                "arquivo": "nome_do_arquivo.py"
            }}
        ]
        
        Se não encontrar oportunidades relevantes no trecho, retorne uma lista vazia [].
        """

    def _scan_directory(
        self, root_path: str, extensions: list[str] = [".py", ".js", ".jsx"]
    ) -> list[str]:
        """Lista arquivos relevantes para análise."""
        file_paths = []
        for root, _, files in os.walk(root_path):
            if "venv" in root or "__pycache__" in root or ".git" in root:
                continue
            for file in files:
                if any(file.endswith(ext) for ext in extensions):
                    file_paths.append(os.path.join(root, file))
        return file_paths

    def _read_file_content(self, file_path: str) -> str:
        """Lê o conteúdo de um arquivo."""
        try:
            with open(file_path, encoding="utf-8") as f:
                return f.read()
        except Exception as e:
            return f"Erro ao ler arquivo: {e!s}"

    async def scan_codebase(self, target_path: str = None) -> list[dict[str, Any]]:
        """
        Varre o código fonte alvo e gera oportunidades.

        Args:
            target_path: Caminho relativo ou absoluto para o diretório do projeto alvo.
        """
        if target_path is None:
            target_path = os.getenv(
                "RHGOV_PROJECT_ROOT", "D:/Projeto IA/PROJETOS/RH_GOV_SIMULADOR"
            )
        opportunities = []

        # Mapear arquivos (limitando a alguns chave para demonstração/performance)
        # Em produção, isso seria mais seletivo ou assíncrono em lotes
        print(f"DEBUG: Iniciando varredura em: {target_path}")
        all_files = self._scan_directory(target_path)
        print(f"DEBUG: Arquivos encontrados: {len(all_files)}")

        # Selecionar amostra de arquivos interessantes (Models e APIs costumam ter regras de negócio)
        target_files = [
            f for f in all_files if "models" in f or "api" in f or "endpoints" in f
        ]

        if not target_files:
            print(
                "DEBUG: Filtros principais não retornaram arquivos. Usando fallback para todos os arquivos encontrados."
            )
            target_files = all_files
        print(f"DEBUG: Arquivos alvo filtrados: {len(target_files)}")
        target_files = target_files[:5]  # Limite para não estourar tokens/tempo na POC

        for file_path in target_files:
            print(f"DEBUG: Analisando arquivo: {file_path}")
            content = self._read_file_content(file_path)
            if (
                not content or len(content) > 10000
            ):  # Pular arquivos muito grandes ou vazios
                print(f"DEBUG: Pulando arquivo {file_path} (vazio ou muito grande)")
                continue

            prompt = ChatPromptTemplate.from_messages(
                [
                    ("system", self.system_prompt),
                    (
                        "user",
                        "Analise o seguinte código do arquivo '{file_path}':\n\n```python\n{code_content}\n```",
                    ),
                ]
            )

            try:
                chain = prompt | self.llm
                response = await chain.ainvoke(
                    {"file_path": file_path, "code_content": content}
                )
                content_text = response.content.strip()
                print(f"DEBUG: Resposta LLM para {file_path}: {content_text[:100]}...")

                # Limpeza básica de markdown json se houver
                if content_text.startswith("```json"):
                    content_text = content_text.replace("```json", "").replace(
                        "```", ""
                    )

                file_opportunities = json.loads(content_text)
                print(
                    f"DEBUG: Oportunidades encontradas neste arquivo: {len(file_opportunities)}"
                )

                # Adicionar o nome do arquivo se a LLM não tiver colocado corretamente
                for opp in file_opportunities:
                    if "arquivo" not in opp:
                        opp["arquivo"] = os.path.basename(file_path)
                    opportunities.append(opp)

            except Exception as e:
                print(f"Erro ao analisar {file_path}: {e}")
                continue

        print(f"DEBUG: Total de oportunidades encontradas: {len(opportunities)}")
        return opportunities
