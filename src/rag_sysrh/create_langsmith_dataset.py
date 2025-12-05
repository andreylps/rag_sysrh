from pathlib import Path

from dotenv import load_dotenv  # pyright: ignore[reportMissingImports]
from langsmith import Client  # pyright: ignore[reportMissingImports]


def create_evaluation_dataset():
    """
    Cria um dataset no LangSmith para avaliação contínua do AnalistaWorkflow.

    Este dataset contém pares de "input" (a solicitação do usuário) e
    "output" (os campos essenciais do relatório que esperamos como resultado).
    """
    # Garante que as variáveis de ambiente (LANGCHAIN_API_KEY) sejam carregadas
    project_root = Path(__file__).resolve().parent.parent.parent
    dotenv_path = project_root / ".env"
    load_dotenv(dotenv_path=dotenv_path)

    client = Client()

    dataset_name = "AnalistaWorkflow - Avaliação Qualidade v1"
    dataset_description = "Dataset para avaliar a qualidade das respostas do AnalistaWorkflow, focando em classificação, diagnóstico e geração de detalhes evolutivos."

    # --- Definição dos Exemplos de Teste ---
    # Cada item é um par de input/output esperado.
    # O 'output' não precisa ser o objeto completo, apenas os campos-chave que queremos validar.
    examples = [
        # Exemplo 1: Relato de Erro Simples
        {
            "inputs": {
                "solicitacao": "Ao tentar registrar uma proposta de consignação para o cliente UDESC, o sistema exibe o erro 'RN005 - Limite excedido'. O que devo fazer?"
            },
            "outputs": {
                "tipo_problema": "Erro",
                "complexidade": "Baixa",
                "solucao_sugerida": "Verificar o cadastro do cliente e orientar sobre a política de limite de crédito.",
                # Garante que a estrutura seja consistente com os outros exemplos
                "data_prevista_entrega": None,
                "estimativa_pontos_funcao": None,
                "prazo_dias_uteis": None,
            },
        },
        # Exemplo 2: Solicitação de Melhoria (Evolutivo)
        {
            "inputs": {
                "solicitacao": "Seria muito útil se pudéssemos exportar o relatório de comissões para o formato PDF, além do CSV atual. Isso facilitaria o compartilhamento com a diretoria."
            },
            "outputs": {
                "tipo_problema": "Melhoria",
                "tipo_solicitacao": "Evolutivo",
                "complexidade": "Média",
                # Aplainamos a estrutura para corresponder ao novo output da função target.
                "data_prevista_entrega": "Qualquer data válida",
                "estimativa_pontos_funcao": 0,
                "prazo_dias_uteis": 0,
            },
        },
        # Exemplo 3: Dúvida de Procedimento
        {
            "inputs": {
                "solicitacao": "Qual é o passo a passo para cadastrar um novo convênio no sistema? Não encontrei no manual."
            },
            "outputs": {
                "tipo_problema": "Dúvida",
                "tipo_solicitacao": "Transferencia de conhecimento",
                "complexidade": "Baixa",
                # Garante que a estrutura seja consistente com os outros exemplos
                "data_prevista_entrega": None,
                "estimativa_pontos_funcao": None,
                "prazo_dias_uteis": None,
            },
        },
    ]

    # Verifica se o dataset já existe
    if client.has_dataset(dataset_name=dataset_name):
        print(f"Dataset '{dataset_name}' já existe. Pulando a criação.")
    else:
        # Cria o dataset
        dataset = client.create_dataset(
            dataset_name=dataset_name, description=dataset_description
        )
        # Adiciona os exemplos ao dataset
        client.create_examples(
            inputs=[ex["inputs"] for ex in examples],
            outputs=[ex["outputs"] for ex in examples],
            dataset_id=dataset.id,
        )
        print(
            f"Dataset '{dataset_name}' criado com sucesso com {len(examples)} exemplos."
        )


if __name__ == "__main__":
    create_evaluation_dataset()
