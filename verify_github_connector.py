import json
import logging
import os

from rag_sysrh.connectors import GitHubMockConnector

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def verify_github_connector():
    """
    Verifica a funcionalidade do GitHubMockConnector.
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DO CONECTOR GITHUB ---")

    try:
        # 1. Instanciar o conector
        mock_file = "data/external_system/test_github_mock.json"
        connector = GitHubMockConnector(mock_file_path=mock_file)

        # 2. Dados de teste (simulando uma RCM)
        rcm_data = {
            "titulo_rcm": "Implementar Dark Mode",
            "descricao_tecnica_detalhada": "Adicionar suporte a tema escuro usando CSS variables.",
            "objetivo_negocio": "Melhorar a experiência do usuário em ambientes com pouca luz.",
            "estimativa_pontos_funcao": 5,
            "prazo_dias_uteis": 3,
            "criterios_de_aceite": [
                "Botão de toggle no header",
                "Persistência da preferência",
            ],
        }

        # 3. Criar Issue
        issue_url = connector.create_issue(rcm_data)
        logging.info(f"Issue criada: {issue_url}")

        # 4. Verificar se o arquivo foi criado e contém os dados
        if os.path.exists(mock_file):
            with open(mock_file, "r", encoding="utf-8") as f:
                issues = json.load(f)

            last_issue = issues[-1]
            if last_issue["title"] == "[RCM] Implementar Dark Mode":
                logging.info(
                    "✅ PASSOU: Issue encontrada no arquivo mock com título correto."
                )
            else:
                logging.error(
                    f"❌ FALHOU: Título da issue incorreto. Encontrado: {last_issue['title']}"
                )

            if "Dark Mode" in last_issue["body"]:
                logging.info("✅ PASSOU: Corpo da issue contém a descrição.")
            else:
                logging.error("❌ FALHOU: Corpo da issue não contém a descrição.")

        else:
            logging.error("❌ FALHOU: Arquivo mock não foi criado.")

        # Limpeza
        if os.path.exists(mock_file):
            os.remove(mock_file)
            logging.info("Arquivo de teste removido.")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_github_connector()
