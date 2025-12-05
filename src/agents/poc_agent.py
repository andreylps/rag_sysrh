import json
import os

from openai import OpenAI

from src.schemas.poc import POCRequestDTO


class POCAgent:
    def __init__(self):
        self.client = None
        self.system_prompt = """
        Você é um Arquiteto de Soluções Sênior e Especialista em Vendas Técnicas da noesys.ai.
        Seu objetivo é analisar a necessidade de um cliente e gerar uma proposta técnica de Prova de Conceito (POC) estruturada.
        
        A stack padrão da noesys.ai é:
        - Backend: Python (FastAPI)
        - Frontend: React (Vite + Tailwind)
        - Banco de Dados: Neo4j (Graph DB) + PostgreSQL (se necessário)
        - IA: OpenAI GPT-4o, LangChain, Agentes Autônomos.
        
        Gere uma resposta estritamente em formato JSON com a seguinte estrutura:
        {
            "titulo": "Título da POC",
            "resumo_executivo": "Resumo do problema e da solução proposta (1 parágrafo)",
            "escopo_tecnico": [
                "Lista de entregáveis técnicos",
                "Ex: API de ingestão de dados",
                "Ex: Dashboard de visualização"
            ],
            "arquitetura_sugerida": "Descrição da arquitetura (ex: Microserviços, Monolito Modular, Agentes)",
            "cronograma_estimado": "Estimativa de tempo em semanas (ex: 2 semanas)",
            "kpis_sucesso": ["KPI 1", "KPI 2"]
        }
        
        Seja persuasivo, técnico mas acessível, e foque em valor de negócio.
        """

    def generate_poc_proposal_content(self, data: POCRequestDTO) -> dict:
        user_prompt = f"""
        Gere uma proposta de POC para o seguinte cenário:
        
        Contexto/Problema: {data.problema_contexto}
        Objetivo Principal: {data.objetivo_principal}
        Funcionalidades Desejadas: {data.funcionalidades_desejadas}
        KPIs de Sucesso: {data.kpis_sucesso}
        Restrições/Prazo: {data.prazo_restricoes or "Não especificado"}
        """

        try:
            if not self.client:
                self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                response_format={"type": "json_object"},
                temperature=0.7,
            )

            content = response.choices[0].message.content
            return json.loads(content)
        except Exception as e:
            print(f"Erro ao gerar proposta de POC: {e}")
            # Fallback em caso de erro
            return {
                "titulo": "Erro na Geração",
                "resumo_executivo": "Não foi possível gerar a proposta automaticamente.",
                "escopo_tecnico": [],
                "arquitetura_sugerida": "N/A",
                "cronograma_estimado": "N/A",
                "kpis_sucesso": [],
            }
