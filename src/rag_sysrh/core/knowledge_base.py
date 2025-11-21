# src/rag_sysrh/core/knowledge_base.py

"""
FONTE ÚNICA DA VERDADE ORGANIZACIONAL DO SYSRH.

Este arquivo contém as definições estáticas fundamentais sobre a estrutura
organizacional, responsabilidades dos times, regras de exceção críticas e
o fluxo de processo padrão.

IMPORTANTE: Todos os agentes do sistema (Analista, Gerente, Auditor, etc.)
DEVEM importar e utilizar as funções deste arquivo para compor seu
System Prompt, garantindo que compartilhem o mesmo contexto do negócio.
"""

from typing import Dict, List

# --- 1. DEFINIÇÃO DOS TIMES E RESPONSABILIDADES ---
RESPONSABILIDADES_TIMES: Dict[str, Dict[str, str]] = {
    "FUNC": {
        "nome_completo": "Funcional e Cadastro",
        "descricao": "Responsável pelo 'núcleo' dos dados do colaborador. Cuida de admissões, demissões, alterações contratuais, dados pessoais, estrutura de cargos e salários, e movimentações na carreira/organograma. Geralmente trata demandas evolutivas de negócio.",
    },
    "FOLHA": {
        "nome_completo": "Processamento de Folha de Pagamento",
        "descricao": "Responsável pelo motor de cálculo. Processa a folha mensal, férias, 13º salário, rescisões, e calcula os encargos e impostos (IRRF, FGTS) baseados nas regras vigentes. É o time que 'roda' a folha.",
    },
    "PAGTO": {
        "nome_completo": "Financeiro e Pagamentos",
        "descricao": "Responsável pela etapa final financeira. Gera os arquivos de remessa bancária (CNAB), controla o pagamento líquido aos colaboradores, gerencia empréstimos consignados e a interface com bancos.",
    },
    "PREV": {
        "nome_completo": "Previdenciário",
        "descricao": "Especializado em regras de previdência (RPPS/RGPS). Cuida de aposentadorias, pensões, averbação de tempo de serviço, fundos previdenciários e regras de transição de inatividade.",
    },
    "SERV": {
        "nome_completo": "Serviços e Benefícios",
        "descricao": "Gerencia os benefícios não-salariais e rotinas de controle de jornada. Inclui planos de saúde, vale transporte/alimentação, e a gestão de ponto/frequência (batidas, atestados, abonos).",
    },
    "INFOB": {
        "nome_completo": "Informações Gerenciais e Acessórias",
        "descricao": "Focado na saída de dados e conformidade legal. Gera relatórios gerenciais, obrigações acessórias (eSocial, DIRF, RAIS) e indicadores de BI. Cuida da extração e apresentação da informação.",
    },
    "SUST": {
        "nome_completo": "Sustentação e Manutenção",
        "descricao": "Responsável por manter o sistema operando (Business As Usual). Trata solicitações do tipo 'Corretiva' (bugs/erros em produção), 'Correção de Dados' (scripts via banco) e 'Garantia' (problemas em entregas recentes).",
    },
}

# --- 2. REGRAS DE EXCEÇÃO CRÍTICAS DE NEGÓCIO ---
# Estas regras sobrepõem as definições padrão dos times e fluxos.
REGRAS_EXCECAO_CRITICAS: List[str] = [
    "⚠️ EXCEÇÃO CLIENTE ALESC: Para o cliente 'ALESC' exclusivamente, solicitações classificadas como 'Corretivas' (bugs) NÃO devem ser tratadas como sustentação padrão. Elas se enquadram no fluxo de 'Evolução' e devem ser direcionadas aos times funcionais (FUNC, FOLHA, etc.) para análise de requisitos e orçamento, e não ao time SUST."
]

# --- 3. ESTÁGIOS PADRÃO DO PROCESSO DE ATENDIMENTO ---
ESTAGIOS_PROCESSO: Dict[str, str] = {
    "1_ANALISE": "Triagem inicial, entendimento do problema, refinamento de requisitos e, se for evolutiva, estimativa de esforço (orçamento).",
    "2_DESENVOLVIMENTO": "Codificação da solução, criação de scripts ou configuração do sistema pelo time responsável.",
    "3_TESTES_INTERNOS": "Validação técnica e funcional realizada pelo time de QA (Qualidade) ou peer review.",
    "4_HOMOLOGACAO": "Validação final realizada pelo cliente (UAT - User Acceptance Testing) em ambiente controlado.",
    "5_PRODUCAO": "Implantação da solução no ambiente vivo e monitoramento inicial pós-go-live.",
}

# --- FUNÇÕES HELPER PARA INJEÇÃO DE PROMPT ---


def get_contexto_organizacional_completo() -> str:
    """
    Gera uma string única e formatada contendo TODO o conhecimento organizacional
    (Regras Críticas + Times + Estágios do Processo).
    Esta é a função principal a ser chamada na inicialização de qualquer agente.
    """
    contexto = "============================================\n"
    contexto += "CONTEXTO ORGANIZACIONAL SYSRH (FONTE ÚNICA)\n"
    contexto += "============================================\n\n"

    # 1. Regras de Exceção (Prioridade Máxima)
    contexto += "### ⚠️ REGRAS DE NEGÓCIO CRÍTICAS E EXCEÇÕES ###\n"
    contexto += "ATENÇÃO: As regras abaixo têm precedência absoluta sobre as definições padrão.\n"
    for regra in REGRAS_EXCECAO_CRITICAS:
        contexto += f"- {regra}\n"

    # 2. Estrutura de Times
    contexto += "\n### ESTRUTURA E RESPONSABILIDADES DOS TIMES ###\n"
    contexto += (
        "Utilize para identificar a especialidade e responsabilidade de cada área.\n\n"
    )
    for sigla, dados in RESPONSABILIDADES_TIMES.items():
        contexto += (
            f"- **Time {sigla} ({dados['nome_completo']}):** {dados['descricao']}\n"
        )

    # 3. Estágios do Processo
    contexto += "\n### ESTÁGIOS PADRÃO DO PROCESSO DE ATENDIMENTO ###\n"
    contexto += "O fluxo de vida padrão de uma solicitação no sistema.\n\n"
    for estagio, descricao in ESTAGIOS_PROCESSO.items():
        nome_limpo = estagio.split("_", 1)[1]  # Remove o número prefixo para leitura
        contexto += f"- **{nome_limpo}**: {descricao}\n"

    contexto += "\n============================================\n"
    contexto += "FIM DO CONTEXTO ORGANIZACIONAL\n"
    contexto += "============================================\n"

    return contexto
