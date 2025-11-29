# src/services/neo4j_service.py

import logging
import os
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from neo4j import AsyncGraphDatabase

# Importa o DTO de validação para usar na função save_validated_demand_data
from src.schemas.validation import ValidatedDataDTO

load_dotenv()

logger = logging.getLogger(__name__)

# Configurações do Neo4j a partir das variáveis de ambiente
URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
USER = os.getenv("NEO4J_USER", "neo4j")
PASSWORD = os.getenv("NEO4J_PASSWORD", "password")
DATABASE = os.getenv("NEO4J_DATABASE", "neo4j")

_driver: Optional[AsyncGraphDatabase.driver] = None


async def _get_driver():
    """Retorna o driver assíncrono do Neo4j, inicializando-o se necessário."""
    global _driver
    if _driver is None:
        try:
            _driver = AsyncGraphDatabase.driver(URI, auth=(USER, PASSWORD))
            await _driver.verify_connectivity()
            logger.info("Conexão com Neo4j estabelecida com sucesso.")
        except Exception as e:
            logger.error(f"Falha ao conectar ao Neo4j em {URI}: {e}")
            _driver = None  # Reseta o driver se a conexão falhar
            raise
    return _driver


async def close_neo4j_driver():
    """Fecha o driver do Neo4j se estiver aberto."""
    global _driver
    if _driver:
        logger.info("Fechando conexão com Neo4j.")
        await _driver.close()
        _driver = None


async def _run_query(
    query_string: str, parameters: Optional[Dict[str, Any]] = None
) -> List[Dict[str, Any]]:
    """
    Executa uma query Cypher no Neo4j de forma assíncrona.
    Retorna uma lista de dicionários com os resultados.
    """
    driver = await _get_driver()

    async with driver.session(database=DATABASE) as session:
        try:
            result = await session.run(query_string, parameters)
            records = await result.data()
            return records
        except Exception as e:
            logger.error(
                f"Erro ao executar query Neo4j: {query_string} com parâmetros {parameters}. Erro: {e}"
            )
            raise  # Re-lança a exceção para ser tratada em um nível superior


async def save_validated_demand_data(
    issue_number: int,
    issue_title: str,
    issue_body: str,
    issue_html_url: str,
    validated_data: ValidatedDataDTO,
) -> None:
    """
    Salva ou atualiza os dados validados de uma Demanda no Neo4j.
    Cria a Demanda se não existir, ou atualiza suas propriedades.
    """
    logger.info(f"Persistindo dados validados da Demanda #{issue_number} no Neo4j...")

    query = """
    MERGE (d:Demanda {github_issue_id: $issue_number})
    ON CREATE SET
        d.title = $issue_title,
        d.description = $issue_body,
        d.html_url = $issue_html_url,
        d.created_at = datetime(),
        d.status = 'Validada'
    ON MATCH SET
        d.title = $issue_title,
        d.description = $issue_body,
        d.html_url = $issue_html_url,
        d.updated_at = datetime(),
        d.status = 'Validada'
    SET
        d.tipo = $tipo_solicitacao,
        d.prioridade = $prioridade,
        d.esforco_estimado = $esforco_estimado,
        d.comentarios_validacao = $comentarios_validacao
    RETURN d
    """
    parameters = {
        "issue_number": issue_number,
        "issue_title": issue_title,
        "issue_body": issue_body,
        "issue_html_url": issue_html_url,
        "tipo_solicitacao": validated_data.tipo_solicitacao,
        "prioridade": validated_data.prioridade,
        "esforco_estimado": validated_data.esforco_estimado,
        "comentarios_validacao": validated_data.comentarios_validacao,
    }

    try:
        await _run_query(query, parameters)
        logger.info(
            f"Dados da Demanda #{issue_number} persistidos no Neo4j com sucesso."
        )

        # --- Conectar RCMs (Se existirem) ---
        if validated_data.rcms_relacionadas:
            rcm_connect_query = """
            MATCH (d:Demanda {github_issue_id: $issue_number})
            UNWIND $rcm_codes AS rcm_code
            MERGE (r:RCM {code: rcm_code})
            MERGE (d)-[:RELACIONADA_A]->(r)
            """
            rcm_connect_params = {
                "issue_number": issue_number,
                "rcm_codes": validated_data.rcms_relacionadas,
            }
            await _run_query(rcm_connect_query, rcm_connect_params)
            logger.info(
                f"Demanda #{issue_number} relacionada a RCMs: {validated_data.rcms_relacionadas}"
            )

    except Exception as e:
        logger.error(
            f"Erro ao salvar dados da Demanda #{issue_number} no Neo4j: {e}",
            exc_info=True,
        )
        raise  # Propaga o erro


# TODO: Adicione outras funções de serviço Neo4j aqui conforme necessário no futuro.
# Ex: get_related_rcms_for_demand, get_demand_graph, etc.
