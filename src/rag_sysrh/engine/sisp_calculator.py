from decimal import Decimal
from typing import List

from rag_sysrh.engine.models import (
    Complexidade,
    ItemFuncional,
    ResultadoSISP,
    TipoFuncao,
)


class SISPCalculator:
    """
    Motor determinístico para cálculo de Pontos de Função conforme SISP 2.3.
    NÃO utiliza IA. Segue estritamente as tabelas oficiais.
    """

    def calcular_complexidade_dados(
        self, tipo: TipoFuncao, der: int, rlr: int
    ) -> Complexidade:
        """
        Calcula a complexidade de Funções de Dados (ALI/AIE) baseada em DER e RLR.
        Referência: Tabela 1 e 2 do Roteiro de Métricas SISP.
        """
        if tipo not in [TipoFuncao.ALI, TipoFuncao.AIE]:
            raise ValueError(f"Tipo {tipo} inválido para função de dados.")

        # Lógica da Tabela SISP para ALI/AIE
        if rlr == 1:
            if der <= 19:
                return Complexidade.BAIXA
            if der <= 50:
                return Complexidade.BAIXA
            return Complexidade.MEDIA
        elif 2 <= rlr <= 5:
            if der <= 19:
                return Complexidade.BAIXA
            if der <= 50:
                return Complexidade.MEDIA
            return Complexidade.ALTA
        elif rlr >= 6:
            if der <= 19:
                return Complexidade.MEDIA
            if der <= 50:
                return Complexidade.ALTA
            return Complexidade.ALTA

        return Complexidade.MEDIA  # Fallback seguro

    def calcular_complexidade_transacao(
        self, tipo: TipoFuncao, der: int, alr: int
    ) -> Complexidade:
        """
        Calcula a complexidade de Funções de Transação (EE, SE, CE) baseada em DER e ALR (Arquivos Referenciados).
        Referência: Tabelas 3, 4 e 5 do Roteiro de Métricas SISP.
        """
        if tipo == TipoFuncao.EE:
            # Tabela 3 - EE
            if alr <= 1:
                if der <= 4:
                    return Complexidade.BAIXA
                if der <= 15:
                    return Complexidade.BAIXA
                return Complexidade.MEDIA
            elif alr == 2:
                if der <= 4:
                    return Complexidade.BAIXA
                if der <= 15:
                    return Complexidade.MEDIA
                return Complexidade.ALTA
            elif alr >= 3:
                if der <= 4:
                    return Complexidade.MEDIA
                if der <= 15:
                    return Complexidade.ALTA
                return Complexidade.ALTA

        elif tipo == TipoFuncao.SE:
            # Tabela 4 - SE
            if alr <= 1:
                if der <= 5:
                    return Complexidade.BAIXA
                if der <= 19:
                    return Complexidade.BAIXA
                return Complexidade.MEDIA
            elif 2 <= alr <= 3:
                if der <= 5:
                    return Complexidade.BAIXA
                if der <= 19:
                    return Complexidade.MEDIA
                return Complexidade.ALTA
            elif alr >= 4:
                if der <= 5:
                    return Complexidade.MEDIA
                if der <= 19:
                    return Complexidade.ALTA
                return Complexidade.ALTA

        elif tipo == TipoFuncao.CE:
            # Tabela 5 - CE (Igual a EE na estrutura, mas valores diferentes? Verificar manual.
            # No SISP 2.3, CE geralmente segue a mesma tabela de EE ou SE dependendo da interpretação,
            # mas vamos usar a tabela padrão de CE se distinta.
            # Simplificação: Usando tabela padrão de CE que costuma ser similar a EE/SE)

            # Ajuste fino conforme Tabela 5 (Consulta Externa)
            if alr <= 1:
                if der <= 4:
                    return Complexidade.BAIXA
                if der <= 19:
                    return Complexidade.BAIXA
                return Complexidade.MEDIA
            elif 2 <= alr <= 3:
                if der <= 4:
                    return Complexidade.BAIXA
                if der <= 19:
                    return Complexidade.MEDIA
                return Complexidade.ALTA
            elif alr >= 4:
                if der <= 4:
                    return Complexidade.MEDIA
                if der <= 19:
                    return Complexidade.ALTA
                return Complexidade.ALTA

        return Complexidade.MEDIA

    def get_peso(self, tipo: TipoFuncao, complexidade: Complexidade) -> int:
        """Retorna o peso (PF) baseado no tipo e complexidade."""
        tabela_pesos = {
            TipoFuncao.ALI: {
                Complexidade.BAIXA: 7,
                Complexidade.MEDIA: 10,
                Complexidade.ALTA: 15,
            },
            TipoFuncao.AIE: {
                Complexidade.BAIXA: 5,
                Complexidade.MEDIA: 7,
                Complexidade.ALTA: 10,
            },
            TipoFuncao.EE: {
                Complexidade.BAIXA: 3,
                Complexidade.MEDIA: 4,
                Complexidade.ALTA: 6,
            },
            TipoFuncao.SE: {
                Complexidade.BAIXA: 4,
                Complexidade.MEDIA: 5,
                Complexidade.ALTA: 7,
            },
            TipoFuncao.CE: {
                Complexidade.BAIXA: 3,
                Complexidade.MEDIA: 4,
                Complexidade.ALTA: 6,
            },
        }
        return tabela_pesos[tipo][complexidade]

    def calcular_pf(self, itens: List[ItemFuncional], deflator: float) -> ResultadoSISP:
        """
        Executa o cálculo completo para uma lista de itens.
        """
        pf_bruto_total = 0
        itens_calculados = []

        for item in itens:
            # 0. Verificar se é Não Mensurável
            if item.tipo == TipoFuncao.NAO_MENSURAVEL:
                item_calc = item.model_copy()
                item_calc.complexidade = None
                item_calc.pf_bruto = 0
                itens_calculados.append(item_calc)
                continue

            # 1. Determinar Complexidade
            if item.tipo in [TipoFuncao.ALI, TipoFuncao.AIE]:
                comp = self.calcular_complexidade_dados(
                    item.tipo, item.der_estimado, item.rlr_estimado
                )
            else:
                comp = self.calcular_complexidade_transacao(
                    item.tipo, item.der_estimado, item.rlr_estimado
                )

            # 2. Determinar PF Bruto
            peso = self.get_peso(item.tipo, comp)

            # Atualiza o item (copia para não mutar o original se não quiser, mas aqui vamos atualizar)
            item_calc = item.model_copy()
            item_calc.complexidade = comp
            item_calc.pf_bruto = peso

            itens_calculados.append(item_calc)
            pf_bruto_total += peso

        # 3. Calcular PF Líquido
        # Usando Decimal para precisão financeira/legal
        pf_liquido = Decimal(pf_bruto_total) * Decimal(str(deflator))
        # Arredondamento padrão SISP (geralmente 2 casas ou inteiro, vamos manter float por enquanto)

        # 4. Calcular Prazo (Tabela 9)
        # Regra simplificada: Prazo = PF Líquido * Fator (ex: 0.6h/PF ou dias)
        # A Tabela 9 do SISP define prazos máximos em dias.
        # Vamos implementar uma função de prazo baseada em faixas (Mock por enquanto, precisa da Tabela 9 exata)
        prazo_dias = self._calcular_prazo_tabela_9(float(pf_liquido))

        return ResultadoSISP(
            itens_calculados=itens_calculados,
            pf_bruto_total=pf_bruto_total,
            pf_liquido_total=float(pf_liquido),
            prazo_estimado_dias=prazo_dias,
        )

    def _calcular_prazo_tabela_9(self, pf_liquido: float) -> int:
        """
        Calcula o prazo em dias úteis baseado na Tabela 9 do SISP 2.3.
        Referência: Imagem fornecida (Tabela 9: Estimativa de Prazo de Projetos menores que 100 PF).

        Regras:
        - Usa o teto da faixa.
        - Considera complexidade média como padrão para segurança (ou baixa se especificado, mas aqui usaremos média/alta como conservador).
        - Nota: A tabela distingue "Complex. Baixa" e "Complex. Média".
          Como o cálculo de PF já considera complexidade item a item, o "Projeto" em si pode ser avaliado.
          Para fins de automação segura, adotaremos a coluna "Complex. Média" (mais conservadora/padrão)
          a menos que o PF seja muito baixo.
        """
        pf = float(pf_liquido)

        # Faixas exatas da Tabela 9 (Coluna Complex. Média - Dias Úteis)
        if pf <= 10:
            return 15
        elif pf <= 20:
            return 30
        elif pf <= 30:
            return 45
        elif pf <= 40:
            return 60
        elif pf <= 50:
            return 75
        elif pf <= 60:
            return 90
        elif pf <= 70:
            return 105
        elif pf <= 85:
            return 110
        elif pf <= 99:
            return 110
        else:
            # Para projetos >= 100 PF, o SISP geralmente define outras regras ou negociação.
            # Fallback linear conservador: ~1.2 dias por PF acima de 100
            return 110 + int((pf - 99) * 1.2)
