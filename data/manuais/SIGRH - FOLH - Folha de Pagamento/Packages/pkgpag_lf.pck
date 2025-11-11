CREATE OR REPLACE PACKAGE PKGPAG_LF IS

  -- Tabela utilizada no desconto da antecipação salarial
  tabAntecipSal PKGPAG_TIPO.tLancFinanceiro;
    
 -- Tipo utilizado na rotina PPagamentoDecisaoJudicial

  CURSOR cPagDecisaoJudicial(pCdVinculo IN INTEGER,
                             pNuAnoReferencia IN INTEGER,
                             pNuMesReferencia IN INTEGER) IS
     SELECT EPD.CdVinculo,
            EPD.CdRubricaAgrupamento,
            EPD.VlDeterminado,
            EPD.VlIndice,
            EPD.DtInicioDireito,
            EPD.CdValorGeralCefAgrup,
            EPD.NuNivel,
            EPD.NuReferencia,
            EPD.CdValorReferencia,
            EPD.QtValorReferencia,
            NVL(EPD.NuPercentual,100)/100 AS NuPercentual,
            EPD.NuSufixoRubrica,
            EPD.FlUtilizaFormulaExistente,
             -- 21461/2024 - Tiago Von (Inclusão dos novos campos)
            EPD.Vlmontantepenhora,
            EPD.Vlmensalpenhora,
            EPD.Vlindicepenhora,
            EPD.Nuparcelaspenhora,
            EPD.Flincide13penhora,
            EPD.Flincideadianta13penhora
    FROM EPagEventoPagAgrupDecisao EPD
   INNER JOIN EpagRubricaAgrupamento RA
      ON RA.CdRubricaAgrupamento = EPD.CdRubricaAgrupamento
   INNER JOIN EPagRubrica R
      ON R.CdRubrica = RA.CdRubrica
   WHERE EPD.CdVinculo = pCdVinculo AND
         EPD.FlAnulado = PKGPAG_TIPO.cnN AND
         EPD.InTipoValor <> 4 AND
         R.CdTipoRubrica <> PKGPAG_TIPO.cnTpRubTotalizadora AND
         ((EPD.NuAnoInicioDireito < pNuAnoReferencia OR
          (EPD.NuAnoInicioDireito = pNuAnoReferencia AND
           EPD.NuMesInicioDireito <= pNuMesReferencia))
           AND
          (EPD.NuAnoFimDireito > pNuAnoReferencia OR
          (EPD.NuAnoFimDireito = pNuAnoReferencia AND
           EPD.NuMesFimDireito >= pNuMesReferencia) OR
           EPD.NuAnoFimDireito IS NULL));

/*---------------------------------------------------------------------------------*/
-- Procedimento : FValorDecisaoJudicial
--     Objetivo : Retorna o valor calculado a partir das informacoes presentes na
--                decisao judicial
/*----------------------------------------------------------------------------------*/

FUNCTION FValorDecisaoJudicial(pFolha              IN PKGPAG_TIPO.rFolha,
                               pPagDecisaoJudicial IN cPagDecisaoJudicial%ROWTYPE)
  RETURN NUMBER;

/*---------------------------------------------------------------------------------*/
-- Procedimento : PLancamentosFinanceiros
--     Objetivo : Gerar os pagamentos de lancamentos financeiros de acordo com as
--               regras estabelecidas pela parametrizacao da rubrica
/*----------------------------------------------------------------------------------*/

PROCEDURE PLancamentosFinanceiros(pFolha            IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo        IN INTEGER,
                                  pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                                  pDtCalculo        IN DATE,
                                  pLstRubTrib       IN PKGPAG_TIPO.tLista,
                                  pFlTributacao     IN CHAR,
                                  pQtdeNaoLancados OUT INTEGER);

/*---------------------------------------------------------------------------------*/
-- Procedimento : PPagamentoDecisaoJudicial
--     Objetivo : Gerar os pagamentos de decisoes judiciais
--
/*----------------------------------------------------------------------------------*/

  PROCEDURE PPagamentoDecisaoJudicial(pFolha      IN PKGPAG_TIPO.rFolha,
                                      pCdVinculo  IN INTEGER);

/*---------------------------------------------------------------------------------*/
-- Procedimento : PAtualizaHistoricoLancamento
--     Objetivo :
--
/*----------------------------------------------------------------------------------*/

  PROCEDURE PAtualizaHistoricoLancamento(pFolha     IN PKGPAG_TIPO.rFolha,
                                         pCdVinculo IN INTEGER);

/*---------------------------------------------------------------------------------*/
-- Procedimento : PAtualizaHistoricoLancamento
--     Objetivo : Efetuar o somatorio das rubricas do Tipo = 3 e gerar a rubrica
--                07-9999
/*----------------------------------------------------------------------------------*/

 PROCEDURE PGeraDescontoLancTesouro(pFolha     IN PKGPAG_TIPO.rFolha,
                                    pCdVinculo IN INTEGER);

/*---------------------------------------------------------------------------------*/
-- Procedimento : PGeracaoLancamentoValor
--     Objetivo : Gerar registros de pagamentos de lancamentos financeiros e
--                decisoes judiciais com valor informado
/*----------------------------------------------------------------------------------*/

PROCEDURE PGeracaoLancamentoValor(pFolha                   IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo               IN INTEGER,
                                  pCdRubricaAgrupamento    IN INTEGER,
                                  pNuSufixoRubrica         IN INTEGER,
                                  pNuParcelasProc          IN INTEGER  DEFAULT NULL,
                                  pInPossuiValorInformado  IN CHAR     DEFAULT '1',
                                  pVlLancamento            IN NUMBER,
                                  pVlIndice                IN INTEGER,
                                  pCdLancamentoFinanceiro  IN INTEGER  DEFAULT NULL,
                                  pCdTipoOrigemRubrica     IN INTEGER  DEFAULT 1,
                                  pVlIntegralIPREV         IN NUMBER   DEFAULT NULL,
                                  pDeProcessoRetroativo    IN VARCHAR2 DEFAULT NULL,
                                  pVlRestituir             IN NUMBER   DEFAULT NULL,
                                  pVlReal                  IN NUMBER   DEFAULT NULL,
                                  pCdProcessoPagRetroativo IN INTEGER DEFAULT NULL,
                                  pFlValorProporcional     IN CHAR DEFAULT NULL,
                                  pDtInicioDireito         IN DATE DEFAULT pkgpag_var.vgFolha.DtInicioMes,
                                  pDtFimDireito            IN DATE DEFAULT pkgpag_var.vgFolha.DtFimMes,
                                  pFlProcessoRestErario    IN CHAR DEFAULT 'N');


 PROCEDURE PRegistarPagamentoParcela(pCdLancamentoFinanceiro  IN INTEGER,
                                     pNuAnoReferencia         IN INTEGER,
                                     pNuMesReferencia         IN INTEGER,
                                     pNuParcela               IN INTEGER,
                                     pValorParcela            IN NUMBER,
                                     pDataUltimaAlteracao     IN TIMESTAMP DEFAULT SYSTIMESTAMP);


 PROCEDURE PExcluirPagamentoParcela(pCdLancamentoFinanceiro  IN INTEGER,
                                    pNuAnoReferencia         IN INTEGER,
                                    pNuMesReferencia         IN INTEGER);

 FUNCTION FPossuiLancamentoFinanceiro(pCdRubricaAgrupamento IN INTEGER) RETURN BOOLEAN;

 PROCEDURE PRegistraPgtPenhora(pFolha      IN PKGPAG_TIPO.rFolha,
                               pCdVinculo  IN INTEGER);

 /* Processa os lançamentos financeiros de descontos de antecipação salarial */                              
 PROCEDURE PDescontoAntecipSal(pFolha     IN   PKGPAG_TIPO.rFolha,
                               pCdVinculo IN INTEGER);                               


END PKGPAG_LF;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_LF IS

  pTotalNuDiasVinculo INTEGER := 0;


 /*---------------------------------------------------------------------------------*/
--      Cursor que seleciona os lancamentos financeiros com valor definido e cujo
--      numero de parcelas pagas e inferior ao numero de parcelas definida no
--      lancamento
 /*---------------------------------------------------------------------------------*/

   CURSOR cLancParcela(pCdVinculo   IN INTEGER,
                       pDtInicioMes IN DATE,
                       pDtFimMes    IN DATE) IS
      select 1 as CdTipoLancamento -- Parcelado
           , CdRubricaAgrupamento
           , CdLancamentoFinanceiro
           , NuSufixoRubrica
           , VlLancamentoFinanceiro
           , NuParcelas
           , FlPagaAfastDefinitivo
           , case when DtInicio > pDtInicioMes then
               DtInicio
             else
               pDtInicioMes
             end DtInicio
           , case when (DtFim > pDtFimMes or DtFim is null) then
               pDtFimMes
             else
               DtFim
             end DtFim
           , FlValorProporcional
           , VlIndice
           , NuParcelasProc
           , CdProcessoRestituicaoErario
           , CdProcessoPagRetroativo
           , NuFormulaEspecifica
           , FlPropDemitidoNoMes
           , CdTipoFolhaPagamento
           , VlIntegralIPREV
           , FlPagaAfastTempSemRemun
           , DtInclusao
        from (select LF.CdRubricaAgrupamento
                   , LF.CdLancamentoFinanceiro
                   , LF.NuSufixoRubrica
                   , LF.VlLancamentoFinanceiro
                   , LF.NuParcelas
                   , LF.FlPagaAfastDefinitivo
                   , LF.DtInicioDireito as DtInicio
                   , LF.DtFimDireito as DtFim
                   , LF.FlValorProporcional
                   , LF.VlIndice
                   , LF.FlPropDemitidoNoMes
                   , LF.FlPagaAfastTempSemRemun
                   , (select count(*)
                        from EPagPagamentoLancamento PL
                       where PL.CdLancamentoFinanceiro = LF.CdLancamentoFinanceiro
                         and (PL.NuAnoReferencia < PKGPAG_VAR.vgFolha.NuAnoReferencia or
                             (PL.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia and
                             PL.NuMesReferencia < PKGPAG_VAR.vgFolha.NuMesReferencia))) as NuParcelasProc
                   , CdProcessoRestituicaoErario
                   , CdProcessoPagRetroativo
                   , LF.NuFormulaEspecifica
                   , LF.CdTipoFolhaPagamento
                   , LF.VlIntegralIPREV
                   , LF.DtInclusao
                from EPagLancamentoFinanceiro LF
               where LF.CdVinculo = pCdVinculo
                 and PKGPAG_VAR.vgFolha.cdorgao not in (20, 66, 64, 69, 263, 80) --#79353 órgãos que foram desativados e continuam pagando LF na folha dos instituidores
                 and LF.FlAnulado = PKGPAG_TIPO.cnN
                 and LF.InPeriodicidade = PKGPAG_TIPO.cnQ
                 and (LF.NuParcelas is not null)
                 and LF.VlLancamentoFinanceiro >= 0
                 and LF.DtInicioDireito < (pDtFimMes + 1)
                 and (LF.DtFimDireito >= pDtInicioMes or LF.DtFimDireito is null)
                 and PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento not in (1525, 1526, 1505)

                 AND (
                       ( PKGPAG_VAR.vgFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                         NVL(LF.CdTipoFolhaPagamento,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento) AND
                         NVL(LF.CdTipoCalculo,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoCalculo) AND
                         NVL(LF.NuSequencialFolha,0) IN (0, PKGPAG_VAR.vgFolha.NuSequencialFolha)
                        )
                      OR
                        (PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                         LF.CdTipoFolhaPagamento          = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                         LF.CdTipoCalculo                 = PKGPAG_VAR.vgFolha.CdTipoCalculo AND
                         LF.NuSequencialFolha             = PKGPAG_VAR.vgFolha.NuSequencialFolha
                        )
                     )
                 and (lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                                   from vpagrubricaagrupamento ra
                                                  where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                                    and ra.flsuspensa = PKGPAG_TIPO.cnN) or
                      -- SIG-5412 Nao esta gerando rubrica 02-0722 na PM
                      -- Se retroativo, verificar tambem a vigencia da rubrica no inicio do processo
                      lf.cdrubricaagrupamento in (select ret.cdrubricaagrupamento
                                                    from eretprocessorestituicoesdevida ret
                                                   inner join eretprocessopagretroativo proc
                                                           on proc.cdprocessopagretroativo = ret.cdprocessopagretroativo
                                                   inner join epaghistrubricaagrupamento rub
                                                           on rub.cdrubricaagrupamento = ret.cdrubricaagrupamento
                                                           and proc.nuanoiniciorestituicao * 100 + proc.numesiniciorestituicao
                                                       between rub.nuanoiniciovigencia * 100 + rub.numesiniciovigencia and
                                                               rub.nuanofimvigencia * 100 + rub.numesfimvigencia))
             )

          WHERE NuParcelas > NuParcelasProc;

 /*---------------------------------------------------------------------------------*/
 -- Cursor que seleciona os lancamentos financeiros com valor informado e vigentes
 -- no periodo de processamento da folha com valor de lancamento financeiro
 /*---------------------------------------------------------------------------------*/

  CURSOR cLancPeriodo(pCdVinculo           IN INTEGER,
                      pDtInicioMes         IN DATE,
                      pDtFimMes            IN DATE) IS
      select 2 as CdTipoLancamento --Lancamento por periodo com valor informado
           , LF.CdRubricaAgrupamento
           , LF.CdLancamentoFinanceiro
           , LF.NuSufixoRubrica
           , LF.VlLancamentoFinanceiro
           , LF.NuParcelas
           , LF.FlPagaAfastDefinitivo
           , case when LF.DtInicioDireito > pDtInicioMes then
               LF.DtInicioDireito
             else
               pDtInicioMes
             end DtInicio
           , case when (LF.DtFimDireito > pDtFimMes or LF.DtFimDireito is null) then
               pDtFimMes
             else
               LF.DtFimDireito
             end DtFim
           , LF.FlValorProporcional
           , LF.VlIndice
           , 0 as NuParcelasProc
           , LF.CdProcessoRestituicaoErario
           , LF.CdProcessoPagRetroativo
           , LF.NuFormulaEspecifica
           , LF.FlPropDemitidoNoMes
           , LF.CdTipoFolhaPagamento
           , LF.VlIntegralIPREV
           , LF.FlPagaAfastTempSemRemun
           , LF.DtInclusao
        from EPagLancamentoFinanceiro LF
       inner join EPagRubricaAgrupamento RA on LF.CdRubricaAgrupamento = RA.cdRubricaAgrupamento
       inner join EPagRubrica R on RA.CdRubrica = R.CdRubrica
       where LF.CdVinculo = pCdVinculo
         and PKGPAG_VAR.vgFolha.cdorgao not in (20, 66, 64, 69, 263, 80) --#79353 órgãos que foram desativados e continuam pagando LF na folha dos instituidores
         and LF.FlAnulado = PKGPAG_TIPO.cnN
         and (LF.InPeriodicidade = PKGPAG_TIPO.cnP or (LF.InPeriodicidade = PKGPAG_TIPO.cnQ and LF.NuParcelas is null))
         and LF.VlLancamentoFinanceiro >= 0
         and LF.DtInicioDireito <= pDtFimMes
         and (LF.DtFimDireito >= pDtInicioMes or LF.DtFimDireito is null)
         and LF.CdProcessoRestituicaoErario is null
         and ((LF.CdProcessoPagRetroativo is null and LF.FlAcertoAuto13Sal = 'N') or
             (LF.CdProcessoPagRetroativo is not null and LF.FlObservaLimRetroativoErario = PKGPAG_TIPO.cnN))
         and not (R.CdTipoRubrica in (10, 12) and LF.FlFolhaSuplementar = 'S')
         and not (R.CdTipoRubrica in (1, 2) and R.NuRubrica in (53, 95))

         and (PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento not in (1525, 1526, 1505) OR
         (PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento in (1525, 1526, 1505) AND
         RA.Cdrubricaagrupamento in
         (select cdrubricaagrupamento from epagtipofolharubrica where cdhisttipofolhapagamento in
         (select cdhisttipofolhapagamento from epaghisttipofolhapagamento where cdtipofolhapagamento=PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento
         and to_char(pDtInicioMes,'yyyymm') between nuanoiniciovigencia||lpad(numesiniciovigencia,2,0)
         and nvl(nuanofimvigencia,to_char(pDtInicioMes,'yyyy'))||lpad(nvl(numesfimvigencia,to_char(pDtInicioMes,'mm')),2,0)))))

         AND (
               (PKGPAG_VAR.vgFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                NVL(LF.CdTipoFolhaPagamento,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento) AND
                NVL(LF.CdTipoCalculo,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoCalculo) AND
                NVL(LF.NuSequencialFolha,0) IN (0, PKGPAG_VAR.vgFolha.NuSequencialFolha)
               )
             OR
               (PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                LF.CdTipoFolhaPagamento          = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                LF.CdTipoCalculo                 = PKGPAG_VAR.vgFolha.CdTipoCalculo AND
                LF.NuSequencialFolha             = PKGPAG_VAR.vgFolha.NuSequencialFolha
               )
             )
           and  exists (select cdrubricaagrupamento,ra.nuanoiniciovigencia,lpad(ra.numesiniciovigencia,2,0)
                      from  EPAGHISTRUBRICAAGRUPAMENTO ra
                      where to_char(pDtInicioMes,'yyyymm')  between ra.nuanoiniciovigencia||lpad(ra.numesiniciovigencia,2,0)
                      and nvl(ra.nuanofimvigencia,to_char(pDtInicioMes,'yyyy'))||lpad(nvl(ra.numesfimvigencia,to_char(pDtInicioMes,'mm')),2,0)
                      and ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                      and ra.flsuspensa = 'N');

  /*---------------------------------------------------------------------------------*/
  -- Cursor que seleciona os lancamentos financeiros sem valor definido e cujo
  --   numero de parcelas pagas e inferior ao numero de parcelas definida no
  --   lancamento
 /*---------------------------------------------------------------------------------*/

  CURSOR cLancParcelaFC(pCdVinculo   IN INTEGER,
                        pDtInicioMes IN DATE,
                        pDtFimMes    IN DATE) IS
      select 1 as CdTipoLancamento -- Parcelado
           , CdRubricaAgrupamento
           , CdLancamentoFinanceiro
           , NuSufixoRubrica
           , VlLancamentoFinanceiro
           , NuParcelas
           , FlPagaAfastDefinitivo
           , case when DtInicio > pDtInicioMes then
               DtInicio
             else
               pDtInicioMes
             end DtInicio
           , case when (DtFim > pDtFimMes or DtFim is null) then
               pDtFimMes
             else
               DtFim
             end DtFim
           , FlValorProporcional
           , VlIndice
           , NuParcelasProc
           , CdProcessoRestituicaoErario
           , CdProcessoPagRetroativo
           , NuFormulaEspecifica
           , FlPropDemitidoNoMes
           , CdTipoFolhaPagamento
           , VlIntegralIPREV
           , FlPagaAfastTempSemRemun
           , DtInclusao
        from (select LF.CdRubricaAgrupamento
                   , LF.CdLancamentoFinanceiro
                   , LF.NuSufixoRubrica
                   , LF.VlLancamentoFinanceiro
                   , LF.NuParcelas
                   , LF.FlPagaAfastDefinitivo
                   , LF.DtInicioDireito as DtInicio
                   , LF.DtFimDireito as DtFim
                   , LF.FlValorProporcional
                   , LF.VlIndice
                   , LF.FlPropDemitidoNoMes
                   , LF.FlPagaAfastTempSemRemun
                   , (select count(*)
                        from EPagPagamentoLancamento PL
                       where PL.CdLancamentoFinanceiro = LF.CdLancamentoFinanceiro
                         and (PL.NuAnoReferencia < PKGPAG_VAR.vgFolha.NuAnoReferencia or
                             (PL.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia and
                             PL.NuMesReferencia < PKGPAG_VAR.vgFolha.NuMesReferencia))) as NuParcelasProc
                   , LF.CdProcessoRestituicaoErario
                   , LF.CdProcessoPagRetroativo
                   , LF.NuFormulaEspecifica
                   , LF.CdTipoFolhaPagamento
                   , LF.VlIntegralIPREV
                   , LF.DtInclusao
                from EPagLancamentoFinanceiro LF
               where LF.CdVinculo = pCdVinculo
                 and LF.FlAnulado = PKGPAG_TIPO.cnN
                 and LF.InPeriodicidade = PKGPAG_TIPO.cnQ
                 and LF.NuParcelas is not null
                 and NVL(LF.VlLancamentoFinanceiro, 0) = 0
                 and LF.DtInicioDireito < (pDtFimMes + 1)
                 and (LF.DtFimDireito >= pDtInicioMes or LF.DtFimDireito is null)
                 AND (
                       (PKGPAG_VAR.vgFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                        NVL(LF.CdTipoFolhaPagamento,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento) AND
                        NVL(LF.CdTipoCalculo,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoCalculo) AND
                        NVL(LF.NuSequencialFolha,0) IN (0, PKGPAG_VAR.vgFolha.NuSequencialFolha)
                       )
                     OR
                       (PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                        LF.CdTipoFolhaPagamento          = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                        LF.CdTipoCalculo                 = PKGPAG_VAR.vgFolha.CdTipoCalculo AND
                        LF.NuSequencialFolha             = PKGPAG_VAR.vgFolha.NuSequencialFolha
                       )
                     )
                 and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                                   from vpagrubricaagrupamento ra
                                                  where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                                    and ra.flsuspensa = PKGPAG_TIPO.cnN)
              )
       WHERE (NuParcelas > NuParcelasProc);

 /*---------------------------------------------------------------------------------*/
 -- Cursor que seleciona os lancamentos financeiros sem valor informado e vigentes
 --  no periodo de processamento da folha com valor de lancamento financeiro
 /*---------------------------------------------------------------------------------*/

   CURSOR cLancPeriodoFC(pCdVinculo   IN INTEGER,
                         pDtInicioMes IN DATE,
                         pDtFimMes    IN DATE) IS
      select 2 as CdTipoLancamento
           , LF.CdRubricaAgrupamento
           , LF.CdLancamentoFinanceiro
           , LF.NuSufixoRubrica
           , LF.VlLancamentoFinanceiro
           , LF.NuParcelas
           , LF.FlPagaAfastDefinitivo
           , case when LF.DtInicioDireito > pDtInicioMes then
               LF.DtInicioDireito
             else
               pDtInicioMes
             end DtInicio
           , case when (LF.DtFimDireito > pDtFimMes or LF.DtFimDireito is null) then
               pDtFimMes
             else
               LF.DtFimDireito
             end DtFim
           , LF.FlValorProporcional
           , LF.VlIndice
           , 0 as NuParcelasProc
           , LF.CdProcessoRestituicaoErario
           , LF.CdProcessoPagRetroativo
           , LF.NuFormulaEspecifica
           , LF.FlPropDemitidoNoMes
           , LF.CdTipoFolhaPagamento
           , LF.VlIntegralIPREV
           , LF.FlPagaAfastTempSemRemun
           , LF.DtInclusao
        from EPagLancamentoFinanceiro LF
       inner join EPagRubricaAgrupamento RA on LF.CdRubricaAgrupamento = RA.cdRubricaAgrupamento
       inner join EPagRubrica R on RA.CdRubrica = R.CdRubrica
       where LF.CdVinculo = pCdVinculo
         and LF.FlAnulado = PKGPAG_TIPO.cnN
         and (LF.InPeriodicidade = PKGPAG_TIPO.cnP or (LF.InPeriodicidade = PKGPAG_TIPO.cnQ and LF.NuParcelas is null))
         and LF.VlLancamentoFinanceiro is null
         and LF.DtInicioDireito <= pDtFimMes
         and (LF.DtFimDireito >= pDtInicioMes or LF.DtFimDireito is null)
         and LF.CdProcessoRestituicaoErario is null
         and ((LF.CdProcessoPagRetroativo is null and LF.FlAcertoAuto13Sal = 'N') or
             (LF.CdProcessoPagRetroativo is not null and LF.FlObservaLimRetroativoErario = PKGPAG_TIPO.cnN))
         and not (R.CdTipoRubrica in (10, 12) and LF.FlFolhaSuplementar = 'S')
         and not (R.CdTipoRubrica in (1, 2) and R.NuRubrica in (53, 95))
         AND (
               (PKGPAG_VAR.vgFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                NVL(LF.CdTipoFolhaPagamento,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento) AND
                NVL(LF.CdTipoCalculo,0) IN (0, PKGPAG_VAR.vgFolha.CdTipoCalculo) AND
                NVL(LF.NuSequencialFolha,0) IN (0, PKGPAG_VAR.vgFolha.NuSequencialFolha)
               )
             OR
               (PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                LF.CdTipoFolhaPagamento          = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                LF.CdTipoCalculo                 = PKGPAG_VAR.vgFolha.CdTipoCalculo AND
                LF.NuSequencialFolha             = PKGPAG_VAR.vgFolha.NuSequencialFolha
               )
             )
          and  exists (select cdrubricaagrupamento
                      from  EPAGHISTRUBRICAAGRUPAMENTO ra
                      where to_char(pDtInicioMes,'yyyymm') between ra.nuanoiniciovigencia||lpad(ra.numesiniciovigencia,2,0)
                      and nvl(ra.nuanofimvigencia,to_char(pDtInicioMes,'yyyy'))||lpad(nvl(ra.numesfimvigencia,to_char(pDtInicioMes,'mm')),2,0)
                      and ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                      and ra.flsuspensa = PKGPAG_TIPO.cnN);

 /*---------------------------------------------------------------------------------*/
 -- Cursor que seleciona o valor da gratificacao da atividade fazendaria
 -- no periodo de processamento da folha
 /*---------------------------------------------------------------------------------*/

   CURSOR cVlGratFazendaria (vCdrubricaagrupamento IN INTEGER,
                                                     vNuReferencia IN NUMBER,
                                                     vNuNivel IN CHAR,
                                                     vCdGrupoOcupacional IN INTEGER,
                                                     vCdCargoComissionado IN INTEGER,
                                                     vNuMesReferencia IN NUMBER,
                                                     vNuAnoReferencia IN NUMBER) IS

     SELECT NuValor,
                     VlIndice
          FROM (SELECT  NuValor,
                                         VlIndice
                        FROM (SELECT VV.NuValor,
                                                      HAF.VlIndice,
                                                      CASE
                                                        WHEN VV.DeNivel =  vNuReferencia AND
                                                             VV.DeCodigo =  vNuNivel THEN
                                                          1
                                                        WHEN VV.CdGrupoOcupacional =  vCdGrupoOcupacional AND
                                                             VV.CdCargoComissionado =  vCdCargoComissionado THEN
                                                          2
                                                        WHEN VV.CdGrupoOcupacional =  vCdGrupoOcupacional AND
                                                             VV.CdCargoComissionado IS NULL THEN
                                                          3
                                                      END AS NIVEL
                                         FROM epaghisteventopagagrup hea
                                        INNER JOIN epageventopagagrup ea
                                              ON ea.cdeventopagagrup = hea.cdeventopagagrup
                                        INNER JOIN epagtipogratativfazendaria tgra
                                              ON tgra.cdtipogratativfazendaria = hea.cdtipogratativfazendaria
                                        INNER JOIN epaggratativfazendaria gf
                                              ON gf.cdtipogratativfazendaria = tgra.cdtipogratativfazendaria
                                        INNER JOIN epaghistgratativfazendaria haf
                                              ON haf.cdgratativfazendaria = gf.cdgratativfazendaria
                                        INNER JOIN EPagHistGratAtivfazendvalvenc VV
                                              ON HAF.CdHistAtivFazendaria = VV.CdHistAtivFazendaria
                                      WHERE ea.cdrubricaagrupamento = vCdrubricaagrupamento
                                            AND (VV.CdCargoComissionado = vCdCargoComissionado
                                                     OR (VV.CdGrupoOcupacional = vCdGrupoOcupacional AND VV.CdCargoComissionado IS NULL)
                                                     OR (VV.DeNivel = vNuReferencia AND VV.DeCodigo = vNuNivel))
                                            AND ((HAF.NuAnoInicioVigencia < vNuAnoReferencia OR (HAF.NuAnoInicioVigencia = vNuAnoReferencia
                                                    AND HAF.NuMesInicioVigencia <= vNuMesReferencia))
                                                    AND (HAF.NuAnoFimVigencia > vNuAnoReferencia OR (HAF.NuAnoFimVigencia = vNuAnoReferencia
                                                    AND HAF.NuMesFimVigencia >= vNuMesReferencia) OR HAF.NuMesFimVigencia IS NULL))
                                                 ) ORDER BY NIVEL)
                                             WHERE ROWNUM = 1;

/*--------------------------------------------------------------------------------*/
--    Funcao  : FRetornaIndiceLancamento
--   Objetivo : Retorna o valor do indice para inclusao no registro de pagamento.
--              Regra: Quando o lancamento e por periodo, verifica-se se o valor a
--                     ser pago deve ser proporcional aos dias em que a relacao
--                     permaneceu durante o mes.
--
--       pLancamento.CdTipoLancamento : 1) Parcelado
--                                      2) Por Periodo
/*--------------------------------------------------------------------------------*/
FUNCTION FRetornaIndiceLancamento(pLancamento      IN cLancParcela%ROWTYPE,
                                  pDtInicioMes     IN DATE,
                                  pDtFimMes        IN DATE,
                                  pDtInicioRelacao IN DATE,
                                  pDtFimRelacao    IN DATE)
  RETURN NUMBER IS

  vNuDias    INTEGER;
  vNuDiasMes INTEGER;
  vVlIndice  NUMBER;

  vDtInicio  DATE;
  vDtFim     DATE;

BEGIN

  vvlIndice := pLancamento.VlIndice;

  vNuDiasMes :=  PKGPAG_GERAL.FRetornaDiasDoMes(pDtFimMes,
                                                PKGPAG_VAR.vgRubrica(pLancamento.CdRubricaAgrupamento).FlPropMesComercial);

  -- Somente proporcionaliza se nao tem parcelas

  IF pLancamento.CdTipoLancamento = 2 AND NVL(pLancamento.VlIndice,0) > 0
    AND (pLancamento.FlPropDemitidoNoMes ='S' OR pLancamento.FlValorProporcional ='S'
        /*OR (pkgpag_var.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre )*/) THEN

    IF pLancamento.FlPropDemitidoNoMes ='S' /*or
       pkgpag_var.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre*/

     THEN

      vDtInicio := GREATEST (pLancamento.DtInicio, pDtInicioRelacao);
      vDtFim    := LEAST    (pLancamento.DtFim,    pDtFimRelacao);

    ELSIF pLancamento.FlValorProporcional ='S' THEN

      vDtInicio := pLancamento.DtInicio;
      vDtFim    := pLancamento.DtFim;

    else
      null;
    END IF;

    -- Aplica proporcao

    IF vDtFim < vDtInicio THEN

       vNuDias := 0;

    ELSE

       IF vDtFim = pDtFimMes AND
          to_number(TO_CHAR(vDtFim,'MM')) = 2 AND
          PKGPAG_VAR.vgRubrica(pLancamento.CdRubricaAgrupamento).FlPropMesComercial = 'S' THEN

          IF TO_CHAR(pDtFimMes,'DD') = '28' THEN

             vNuDias   := (vDtFim - vDtInicio + 3);

          ELSE

             vNuDias   := (vDtFim - vDtInicio + 2);

          END IF;

       ELSE

         IF vDtFim < pDtInicioRelacao OR vDtInicio > pDtFimRelacao THEN

           vNuDias := 0;

         ELSE

           vNuDias   := LEAST((vDtFim - vDtInicio + 1), vNuDiasMes);

         END IF;

       END IF;

    END IF;

    vvlIndice := (pLancamento.VlIndice*vNuDias)/vNuDiasMes;

 END IF;

 RETURN vvlIndice ;

END;

/*--------------------------------------------------------------------------------------*/
--      Funcao: PVerificaNivelRefDecJud
--      Objetivo: Verificar na decisao judicial por Tabela Geral de Valores,
--                se nivel/ref foi informado (opcao Nivel/Referencia Informado) ou
--                se utilizara nivel/ref do servidor (opcao Nivel/Referencia do Servidor).
--                Se nivel/ref do servidor, busca valores no vetor de APO,
--                ou no vetor de CEF, nesta ordem, atualizando os valores na variavel
--                de entrada e saida:
--                - pPagDecisaoJudicial.NuNivel
--                - pPagDecisaoJudicial.NuReferencia
/*--------------------------------------------------------------------------------------*/
PROCEDURE PVerificaNivelRefDecJud( pPagDecisaoJudicial IN OUT cPagDecisaoJudicial%ROWTYPE ) IS

BEGIN

  -- Se decisao tem valor em nivel/ref, retorna sem atualizar valores
  IF pPagDecisaoJudicial.NuNivel IS NOT NULL AND pPagDecisaoJudicial.NuReferencia IS NOT NULL THEN
     RETURN;
  END IF;

  -- Verifica nivel/referencia da APO
  IF PKGPAG_VAR.vgAPO.COUNT > 0 THEN
    FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
    LOOP

       -- Se encontrou, atualiza valores do primeiro APO e retorna
       pPagDecisaoJudicial.NuNivel := PKGPAG_VAR.vgAPO(i).NuNivelPagamento;
       pPagDecisaoJudicial.NuReferencia := PKGPAG_VAR.vgAPO(i).NuReferenciaPagamento;

      RETURN;

    END LOOP;
  END IF;

  -- Verifica nivel/referencia do CEF
  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN
    FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
    LOOP

        -- Se encontrou, atualiza valores do primeiro CEF e retorna
       pPagDecisaoJudicial.NuNivel := PKGPAG_VAR.vgCEF(i).NuNivelPagamento;
       pPagDecisaoJudicial.NuReferencia := PKGPAG_VAR.vgCEF(i).NuReferenciaPagamento;

       RETURN;

    END LOOP;
  END IF;

END;

---------------------------------------------------------------------------
--
---------------------------------------------------------------------------
FUNCTION FValidaPagamentoRetroativo(pCdProcessoPagRetroativo IN INTEGER,
                                    pcdlancamentofinanceiro  IN INTEGER)

 RETURN BOOLEAN IS

  vCdVinculo              INTEGER;
  vCdSituacaoProcesso     INTEGER;
  vNuAnoInicioRestituicao INTEGER;
  vNuMesInicioRestituicao INTEGER;
  vNuAnoFinalRestituicao  INTEGER;
  vNuMesFinalRestituicao  INTEGER;
  vDtAtivacaoProcesso     DATE;
  vDtFimDireito           DATE;
  vDtCalculoReferencia    DATE;

BEGIN

  SELECT NVL(rt.cdsituacaoprocesso, 0),
         rt.NuAnoInicioRestituicao,
         rt.numesiniciorestituicao,
         rt.DtAtivacaoProcesso,
         rt.cdvinculo,
         rt.numesfinalrestituicao,
         rt.nuanofinalrestituicao
    INTO vCdSituacaoProcesso,
         vNuAnoInicioRestituicao,
         vNuMesInicioRestituicao,
         vDtAtivacaoProcesso,
         vCdVinculo,
         vNuMesFinalRestituicao,
         vNuAnoFinalRestituicao
    FROM eretprocessopagretroativo rt
   WHERE rt.cdprocessopagretroativo = pCdProcessoPagRetroativo;

  SELECT lf.dtfimdireito
    INTO vDtFimDireito
    FROM epaglancamentofinanceiro lf
   WHERE lf.CdLancamentoFinanceiro = pCdLancamentoFinanceiro;

  vDtCalculoReferencia   := PKGPAG_VAR.vgFolha.dtCalculo;

  IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes THEN
    select fpg.dtcalculo
    into vDtCalculoReferencia
    from
    epagfolhapagamento fpg
    inner join epagtipofolhapagamento tfp on fpg.cdtipofolhapagamento=tfp.cdtipofolhapagamento
    where
    fpg.cdorgao=PKGPAG_VAR.vgFolha.cdOrgao
    and fpg.nuanoreferencia=PKGPAG_VAR.vgFolha.NuAnoReferencia
    and fpg.numesreferencia=PKGPAG_VAR.vgFolha.NuMesReferencia
    and tfp.cdtipofolha=1
    and fpg.cdtipocalculo=1;

    IF (vCdSituacaoProcesso = 6 /*suspenso*/) or
       (vDtFimDireito is not null and vDtFimDireito < vDtCalculoReferencia) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
  END IF;

  -- se o processo retroativo for anterior ao calculo da folha, verifica se há parcelas
  -- não processadas. Havalia se o processo deve ser finalizado ou não.
  -- Caso o processo não tenha lançamentos financeiros vigentes, não permite o processamento da parcela
  IF ((vNuAnoInicioRestituicao = pkgpag_var.vgFolha.NuAnoReferencia and
     vNuMesInicioRestituicao < pkgpag_var.vgFolha.NuMesReferencia) or
     (vNuAnoInicioRestituicao < pkgpag_var.vgFolha.NuAnoReferencia)) and
     vDtAtivacaoProcesso < pkgpag_var.vgFolha.DtInicioMes then

    PKGPAG_RT.pajustaparcelanaocomputadaRET(pCdProcessoPagRetroativo,
                                            pCdLancamentoFinanceiro,
                                            vCdVinculo);

    FOR DADOS IN (select nuanomesfim
                    from (select count(lf.cdlancamentofinanceiro) numero,
                                 to_char(max(lf.dtfimdireito), 'YYYYMM') nuanomesfim
                            from ERetProcessoPagRetroativo ret
                           inner join epaglancamentofinanceiro lf
                              on ret.cdprocessopagretroativo =
                                 lf.cdprocessopagretroativo
                           where ret.cdprocessopagretroativo =
                                 pCdProcessoPagRetroativo
                             and (lf.dtfimdireito is not null and
                                 lf.dtfimdireito >
                                 PKGPAG_VAR.vgFolha.dtInicioMes)) x
                   where numero > 0) LOOP

      --caso não haja lançamento financeiros ativos/vigentes, finaliza o processo
      UPDATE ERetProcessoPagRetroativo RT
         SET RT.CdSituacaoProcesso  = 2,
             RT.NuAnoMesFinalizacao = dados.nuanomesfim
       WHERE RT.cdprocessopagretroativo = pCdProcessoPagRetroativo;

       RETURN FALSE;
    END LOOP;

  END IF;

  IF vDtFimDireito IS NOT NULL AND
     vDtFimDireito < vDtCalculoReferencia THEN
    -- LF FINALIZADO
    RETURN FALSE;
  END IF;

  -- Nao paga retroativos SUSPENSOS
  IF vCdSituacaoProcesso = 6 THEN
    -- SUSPENSO
    RETURN FALSE;
  END IF;

  IF vCdSituacaoProcesso = 3 THEN
    -- FINALIZADO

    IF vDtAtivacaoProcesso BETWEEN PKGPAG_VAR.vgFolha.dtInicioMes AND PKGPAG_VAR.vgFolha.dtFimMes
       AND ((vNuMesFinalRestituicao <= PKGPAG_VAR.vgFolha.nuMesReferencia
            AND vNuAnoFinalRestituicao = PKGPAG_VAR.vgFolha.NuAnoReferencia)
             OR (vNuMesFinalRestituicao > PKGPAG_VAR.vgFolha.nuMesReferencia
            AND vNuAnoFinalRestituicao < PKGPAG_VAR.vgFolha.NuAnoReferencia)) THEN
      -- CASO O PROCESSO TENHA SIDO FINALIZADO ANTES DA DATA DE ATIVAÇÃO
      UPDATE eretprocessopagretroativo rt
       SET rt.cdsituacaoprocesso = 2 --ATIVO
     WHERE rt.cdprocessopagretroativo = pCdProcessoPagRetroativo;

    ELSE

      RETURN FALSE;
    END IF;
  END IF;

  RETURN TRUE;

EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;

END;

---------------------------------------------------------------------------
--
---------------------------------------------------------------------------
FUNCTION FGeraLancamento (pRubrica                 IN PKGPAG_TIPO.rRubrica,
                          pCdProcessoPagRetroativo IN INTEGER,
                          pCdLancamentoFinanceiro  IN INTEGER,
                          pDtCalculo               IN DATE)

  RETURN BOOLEAN IS

BEGIN

  IF pCdProcessoPagRetroativo IS NOT NULL THEN

   IF pRubrica.CdAgrupamento != PKGPAG_VAR.vgFolha.CdAgrupamento THEN
     PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                             PKGPAG_VAR.vCdHistParamCalc,
                             PKGPAG_VAR.vCdPessoa,
                             'Tentativa de processamento de rubrica de outro agrupamento.'||
                             ' Rubrica: '||lpad(nvl(pRubrica.CdTipoRubrica,0),2,'0')||'-'||lpad(nvl(pRubrica.NuRubrica,0),4,'0')||
                             ', CdRubricaAgrupamento: '||pRubrica.cdRubricaAgrupamento||'. '||SQLERRM,
                             PKGPAG_VAR.vgCdVinculo);
     RETURN FALSE;
   END IF;

   IF NOT FValidaPagamentoRetroativo(pCdProcessoPagRetroativo, pCdLancamentoFinanceiro) THEN
     RETURN FALSE;
   END IF;

   IF PKGPAG_RT.vgDecJudRetro.EXISTS(pCdProcessoPagRetroativo) THEN

     IF PKGPAG_RT.vgDecJudRetro(pCdProcessoPagRetroativo).FlIsentaIprev = 'S' THEN

       IF (NVL(PKGPAG_RT.vgDecJudRetro(pCdProcessoPagRetroativo).DtConcessaoIsencao,
               PKGPAG_RT.vgDecJudRetro(pCdProcessoPagRetroativo).DtInclusao) <= pDtCalculo) THEN

         IF pRubrica.CdRubricaAgrupamento IN (PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundFinanc,
                                      PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundPrev,
                                      PKGPAG_RT.vCdRubrAgpDifAbonoPerm) THEN

           RETURN FALSE;

         END IF;

       END IF;

     END IF;

   END IF;

   IF PKGPAG_VAR.vgFolha.CdTipoFolha != pkgpag_tipo.cnTpFolhaCtisp 
      AND pRubrica.nuRubrica = 2323 THEN
      RETURN FALSE;
   END IF;

 END IF;

 RETURN TRUE;

END;

FUNCTION FValorDecisaoJudicial(pFolha              IN PKGPAG_TIPO.rFolha,
                               pPagDecisaoJudicial IN cPagDecisaoJudicial%ROWTYPE)

  RETURN NUMBER IS

  vPagDecisaoJudicial cPagDecisaoJudicial%ROWTYPE;

  vNuDias             INTEGER;

  vNuDiasMes          INTEGER;

BEGIN

  vPagDecisaoJudicial := pPagDecisaoJudicial;

  -- Deciscao Judicial por Tabela Geral de Valores de Agrupamento
  IF vPagDecisaoJudicial.CdValorGeralCEFAgrup IS NOT NULL THEN

    -- verifica se foram informados os valores de nivel/ref em vPagDecisaoJudicial,
    -- atualizando se necessario com valores de nivel/ref da APO ou CEF, nesta ordem
    PVerificaNivelRefDecJud(vPagDecisaoJudicial);

    vPagDecisaoJudicial.VlDeterminado := NVL(vPagDecisaoJudicial.NuPercentual,100)*

          PKGPAG_GERAL.FRetonaValorFixoTab(pNuVersaoTab           => pFolha.NuVersaoTabValorReferencia,
                                           pNuAnoReferencia       => pFolha.NuAnoReferencia,
                                           pNuMesReferencia       => pFolha.NuMesReferencia,
                                           pCdValorGeralCEFAgrup  => vPagDecisaoJudicial.CdValorGeralCefAgrup,
                                           pNuNivelPagamento      => vPagDecisaoJudicial.NuNivel,
                                           pNuReferenciaPagamento => vPagDecisaoJudicial.NuReferencia);

  -- Decisao Judicial por Referencia de valor
  ELSIF vPagDecisaoJudicial.CdValorReferencia IS NOT NULL AND
        vPagDecisaoJudicial.QtValorReferencia IS NOT NULL THEN

    IF PKGPAG_VAR.vgValorReferencia.EXISTS(vPagDecisaoJudicial.CdValorReferencia) THEN

      vPagDecisaoJudicial.VlDeterminado := NVL(vPagDecisaoJudicial.NuPercentual,100)*

        PKGPAG_VAR.vgValorReferencia(vPagDecisaoJudicial.CdValorReferencia).VlReferencia*vPagDecisaoJudicial.QtValorReferencia;

    END IF;

  else
    null;
  END IF;

  IF vPagDecisaoJudicial.VlDeterminado IS NOT NULL THEN

    IF (((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
        (PKGPAG_VAR.vgVinculo.DtAdmissao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)OR
        (vPagDecisaoJudicial.DtInicioDireito BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)) AND
        PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).CdTipoRubrica = 1) THEN

       IF (PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

        vNuDias:= PKGPAG_VAR.vgVinculo.DtDesligamento - pFolha.DtInicioMes + 1;

       ELSIF (PKGPAG_VAR.vgVinculo.DtAdmissao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

         vNuDias:= pFolha.DtFimMes - PKGPAG_VAR.vgVinculo.DtAdmissao + 1;

       ELSIF vPagDecisaoJudicial.DtInicioDireito BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes THEN

         vNuDias:= pFolha.DtFimMes - vPagDecisaoJudicial.DtInicioDireito + 1;

       ELSE

         vNuDias:= pFolha.DtFimMes - pFolha.DtInicioMes + 1;

       END IF;

       vNuDiasMes :=  PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes,
                                                     PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).FlPropMesComercial);

       IF vNuDias > vNuDiasMes OR
         (vNuDias < vNuDiasMes and vNuDias = to_number(TO_CHAR(pFolha.DtFimMes, 'DD'))
                               and to_number(TO_CHAR(pFolha.DtFimMes, 'MM')) = 2) -- TRATAR FEVEREIRO
         THEN

         vNuDias := vNuDiasMes;

       END IF;

       vPagDecisaoJudicial.VlDeterminado := (vPagDecisaoJudicial.VlDeterminado/vNuDiasMes)*vNuDias;

     END IF;

   END IF;

  -- 21461/2024 - Tiago Von - INICIO
  IF vPagDecisaoJudicial.vlmontantepenhora IS NOT NULL THEN
    
     IF vPagDecisaoJudicial.vlmensalpenhora IS NOT NULL THEN
        vPagDecisaoJudicial.VlDeterminado := vPagDecisaoJudicial.vlmensalpenhora;
        
     ELSIF vPagDecisaoJudicial.Vlindicepenhora IS NOT NULL THEN
        vPagDecisaoJudicial.VlDeterminado := NULL;
        
     ELSIF vPagDecisaoJudicial.nuparcelaspenhora IS NOT NULL THEN
        vPagDecisaoJudicial.VlDeterminado := vPagDecisaoJudicial.vlmontantepenhora / vPagDecisaoJudicial.nuparcelaspenhora;
        
     END IF;
  ELSE 
      
     IF vPagDecisaoJudicial.vlmensalpenhora IS NOT NULL THEN
        vPagDecisaoJudicial.VlDeterminado := vPagDecisaoJudicial.vlmensalpenhora;
     
     ELSIF vPagDecisaoJudicial.Vlindicepenhora IS NOT NULL THEN
         vPagDecisaoJudicial.VlDeterminado := (vPagDecisaoJudicial.vlmensalpenhora * vPagDecisaoJudicial.Vlindicepenhora) /100;   
     END IF;
           
  END IF;
  -- 21461/2024 - Tiago Von - FIM

   RETURN vPagDecisaoJudicial.VlDeterminado;

EXCEPTION

   WHEN OTHERS THEN

     RETURN NULL;

END;

FUNCTION FPagaCCORegraInerente(pFolha              IN PKGPAG_TIPO.rFolha,
                               pPagDecisaoJudicial IN cPagDecisaoJudicial%ROWTYPE)

  RETURN BOOLEAN IS
  vAplicaCCORegraInerente CHAR(1);

BEGIN

    SELECT dj.Flpagaccoregrainerente
      INTO vAplicaCCORegraInerente
      FROM epageventopagagrupdecisao dj
     WHERE dj.cdvinculo = pPagDecisaoJudicial.Cdvinculo
       AND   dj.cdrubricaagrupamento = pPagDecisaoJudicial.Cdrubricaagrupamento
       AND   DJ.FLANULADO = 'N'
       AND ((dj.nuanoiniciodireito < pFolha.NuAnoReferencia OR
              (dj.nuanoiniciodireito = pFolha.NuAnoReferencia AND
              dj.numesiniciodireito <= pFolha.NuMesReferencia))
       AND
              (dj.nuanofimdireito > pFolha.NuAnoReferencia OR
              dj.nuanofimdireito = pFolha.NuAnoReferencia AND
              dj.numesfimdireito >= pFolha.NuMesReferencia) OR
              dj.numesfimdireito IS NULL)
       AND ROWNUM < 2;

    IF vAplicaCCORegraInerente = 'S'
      THEN
        RETURN TRUE;
    ELSE
          RETURN FALSE;
    END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

  WHEN OTHERS THEN

    RETURN FALSE;

END;

/*--------------------------------------------------------------------------------*/
-- Procedure :  PFormulaCEF
--  Objetivo : Encontrar a formula de calculo e inserir registro de pagamento
--             pertinente a relacao de vinculo (CEF de titular remunerado -regra-,
--             subsituindo ou respondendo) obedecendo a abrangencia da rubrica para
--             lancamentos financeiros, decisoes judiciais e eventos.

--       pTpRegistro - 1) Lancamento Financeiro
--                     2) Decisao judicial
--                     3) Enventos
/*--------------------------------------------------------------------------------*/

PROCEDURE PFormulaVinc(pCdTipoReg        IN INTEGER,
                       pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                       pCdFolhaPagamento IN INTEGER,
                       pCdOrgao          IN INTEGER,
                       pCdVinculo        IN INTEGER,
                       pDtInicioMes      IN DATE,
                       pDtFimMes         IN DATE,
                       pRubrica          IN PKGPAG_TIPO.rRubrica,
                       pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                       pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE DEFAULT NULL) IS

  vCdExpressaoFormCalc INTEGER;

  --vCdCargoComissionado INTEGER;

  --vCdGrupoOcupacional  INTEGER;

BEGIN

   -- 1) Busca a formula associada
  vCdExpressaoFormCalc :=

     PKGPAG_GERAL.FIdentificaFormulaCalculo(
                  pFormExpr                 => pFormExpr,
                  pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                  pCdRelacaoVinculo         => 0,
                  pNuFormulaEspecifica      => pLancamento.NuFormulaEspecifica);

  IF vCdExpressaoFormCalc > 0 THEN

    CASE pCdTipoReg

      WHEN 1 THEN -- Lancamento Financeiro

        IF pLancamento.FlPagaAfastDefinitivo = 'S' THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pCdFolhaPagamento,
                                                pCdVinculo              => pCdVinculo,
                                                pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                pCdRubricaAgrupamento   => pLancamento.CdRubricaAgrupamento,
                                                pVlPagamento            => 0,
                                                pNuSufixoRubrica        => pLancamento.NuSufixoRubrica,
                                                pNuParcelas             => pLancamento.NuParcelasProc + 1,
                                                pVlIndice               => pLancamento.VlIndice,
                                                pCdLancamentoFinanceiro => pLancamento.CdLancamentoFinanceiro,
                                                pCdTipoOrigemRubrica    => CASE
                                                                           WHEN pLancamento.CdProcessoPagRetroativo IS NULL THEN
                                                                             2
                                                                           ELSE
                                                                             12
                                                                           END);

        END IF;

     -- Hoje nao gera decisao Judicial para desligados
      -- 21461/2024 - Tiago Von
      WHEN 2 THEN -- Decisao judicial

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pCdFolhaPagamento,
                                               pCdVinculo              => pCdVinculo,
                                               pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                               pCdRubricaAgrupamento   => pLancDetJud.CdRubricaAgrupamento,
                                               pVlPagamento            => 0,
                                               pNuSufixoRubrica        => pLancDetJud.NuSufixoRubrica,
                                                 pVlIndice               => nvl(pLancDetJud.VlIndice,pLancDetJud.Vlindicepenhora), -- 21461/2024 - Tiago Von
                                                 pCdTipoOrigemRubrica    => 3);
    ELSE

      NULL;

    END CASE;

  END IF;

END;

/*--------------------------------------------------------------------------------*/
-- Procedure :  PFormulaCEF
--  Objetivo : Encontrar a formula de calculo e inserir registro de pagamento
--             pertinente a relacao de vinculo (CEF de titular remunerado -regra-,
--             subsituindo ou respondendo) obedecendo a abrangencia da rubrica para
--             lancamentos financeiros, decisoes judiciais e eventos.

--       pTpRegistro - 1) Lancamento Financeiro
--                     2) Decisao judicial
--                     3) Enventos
/*--------------------------------------------------------------------------------*/

PROCEDURE PFormulaCEF(pCdTipoReg        IN INTEGER,
                      pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                      pCdFolhaPagamento IN INTEGER,
                      pCdOrgao          IN INTEGER,
                      pCdVinculo        IN INTEGER,
                      pDtInicioMes      IN DATE,
                      pDtFimMes         IN DATE,
                      pRubrica          IN PKGPAG_TIPO.rRubrica,
                      pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                      pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE DEFAULT NULL,
                      pApenasRVPrinc    IN CHAR DEFAULT 'N') IS

  vCdExpressaoFormCalc INTEGER;

  vCdCargoComissionado INTEGER;

  vCdGrupoOcupacional  INTEGER;

BEGIN

   FOR vCEF IN PKGPAG_VAR.cRelCEF(pCdVinculo,
                                  PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento,
                                  pDtInicioMes,
                                  pDtFimMes)
    LOOP

      vCdCargoComissionado := NULL;

      vCdGrupoOcupacional  := NULL;

      IF PKGPAG_VAR.vgCCO.COUNT > 0 THEN

        vCdCargoComissionado := PKGPAG_VAR.vgCCO(1).CdCargoComissionado;

        vCdGrupoOcupacional := PKGPAG_VAR.vgCCO(1).CdGrupoOcupacional;

      END IF;

      IF (pApenasRVPrinc = 'N') OR
         (pApenasRVPrinc = 'S' AND
         (PKGPAG_VAR.vgRelVincPrincipal.CdHist = vCEF.CdHistCargoEfetivo)) THEN

        IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                     pRubrica                  => pRubrica,
                                     pCdOrgao                  => pCdOrgao,
                                     pCdOrgaoExercicio         => vCEF.CdOrgaoExercicio,
                                     pCdNaturezaVinculo        => vCEF.CdNaturezaVinculo,
                                     pCdRelacaoTrabalho        => vCEF.CdRelacaoTrabalho,
                                     pCdRegimeTrabalho         => vCEF.CdRegimeTrabalho,
                                     pCdRegimePrevidenciario   => vCEF.CdRegimePrevidenciario,
                                     pCdSituacaoPrevidenciaria => vCEF.CdSituacaoPrevidenciaria,
                                     pCdUnidadeOrganizacional  => vCEF.CdUnidadeOrganizacional,
                                     pCdEstruturaCarreira      => vCEF.CdEstruturaCarreira,
                                     pFlTipoProvimento         => vCEF.FlEfetivacao,
                                     pCdCargoComissionado      => vCdCargoComissionado,
                                     pCdGrupoOcupacional       => vCdGrupoOcupacional
                                    ) THEN

           -- 1) Busca a formula associada
          vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                          pFormExpr                 => pFormExpr,
                          pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                          pCdRelacaoVinculo         => 1,
                          pCdEstruturaCarreira      => vCEF.CdEstruturaCarreira,
                          pCdUnidadeOrganizacional  => vCEF.CdUnidadeOrganizacional,
                          pNuFormulaEspecifica      => pLancamento.NuFormulaEspecifica);

          IF vCdExpressaoFormCalc > 0 THEN

              CASE pCdTipoReg

                WHEN 1 THEN -- Lancamento Financeiro

                  pTotalNuDiasVinculo := pTotalNuDiasVinculo + vCEF.DtFim - vCEF.DtInicio + 1;

                  -- POG para evitar de proporcionalizar o 31
                  IF pTotalNuDiasVinculo > 30 AND TO_CHAR(vCEF.DtFim, 'DD') = '31'
                     AND vCEF.DtInicio > pkgpag_var.vgFolha.dtInicioMes THEN

                    pkgpag_var.vgNuIndiceHoraPlantao := FRetornaIndiceLancamento(pLancamento,
                                                                                pDtInicioMes,
                                                                                pDtFimMes,
                                                                                vCEF.DtInicio,
                                                                                vCEF.DtFim-1);

                  ELSIF pkgpag_var.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre
                    AND (pRubrica.NuRubrica IN (33, 69, 108, 220) AND pRubrica.CdTipoRubrica = 1)
                    THEN
                    --Não deve proporcionalizar hora plantão para folha funebre
                     pkgpag_var.vgNuIndiceHoraPlantao := FRetornaIndiceLancamento(pLancamento,
                                                                                pDtInicioMes,
                                                                                pDtFimMes,
                                                                                pDtInicioMes,
                                                                                pDtFimMes);
                  ELSE
                    pkgpag_var.vgNuIndiceHoraPlantao := FRetornaIndiceLancamento(pLancamento,
                                                                                pDtInicioMes,
                                                                                pDtFimMes,
                                                                                vCEF.DtInicio,
                                                                                vCEF.DtFim);

                  END IF;

                 IF pLancamento.cdRubricaAgrupamento = 58861
                   THEN
                   pkgpag_var.vgIndiceRub010431 := NVL(pLancamento.vlIndice, pkgpag_var.vgNuIndiceHoraPlantao);

                 END IF;

                 PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pCdFolhaPagamento,
                                                        pCdVinculo              => pCdVinculo,
                                                        pCdRelacaoVinculo       => 1,
                                                        pCdHistRelacaoVinculo   => vCEF.CdHistCargoEfetivo,
                                                        pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento   => pLancamento.CdRubricaAgrupamento,
                                                        pVlIntegral             => NULL,
                                                        pVlProporcional         => NULL,
                                                        pNuSufixoRubrica        => pLancamento.NuSufixoRubrica,
                                                        pNuParcelas             => pLancamento.NuParcelasProc + 1,
                                                        pVlIndice               => pkgpag_var.vgNuIndiceHoraPlantao,
                                                        pCdLancamentoFinanceiro => pLancamento.CdLancamentoFinanceiro,
                                                        pDtInicioRelacao        => vCEF.DtInicioRelacao,
                                                        pDtDesligamento         => vCEF.DtFimRelacao,
                                                        pCdTipoOrigemRubrica    => CASE
                                                                                   WHEN pLancamento.CdProcessoPagRetroativo IS NULL THEN
                                                                                     2
                                                                                   ELSE
                                                                                     12
                                                                                   END,
                                                        pDtInicio                => vCEF.DtInicio,
                                                        pDtFim                   => vCEF.DtFim);

                WHEN 2 THEN -- Decisao judicial

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pCdFolhaPagamento,
                                                        pCdVinculo              => pCdVinculo,
                                                        pCdRelacaoVinculo       => 1,
                                                        pCdHistRelacaoVinculo   => vCEF.CdHistCargoEfetivo,
                                                        pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento   => pLancDetJud.CdRubricaAgrupamento,
                                                        pVlIntegral             => NULL,
                                                        pVlProporcional         => NULL,
                                                        pNuSufixoRubrica        => pLancDetJud.NuSufixoRubrica,
                                                        pNuParcelas             => nvl(pLancDetJud.nuparcelaspenhora,0) + 1, -- 21461/2024 - Tiago Von, --1,
                                                        pVlIndice               => CASE WHEN pLancDetJud.VlIndice IS NULL THEN pLancDetJud.Vlindicepenhora ELSE pLancDetJud.VlIndice END, -- 21461/2024 - Tiago Von -- pLancDetJud.VlIndice,
                                                        pDtInicioRelacao        => vCEF.DtInicioRelacao,
                                                        pDtDesligamento         => vCEF.DtFimRelacao,
                                                        pCdTipoOrigemRubrica    => 3,
                                                        pDtInicio               => vCEF.DtInicio,
                                                        pDtFim                  => vCEF.DtFim);

              END CASE;

          END IF;

        END IF;

     END IF;

   END LOOP;

END;

/*--------------------------------------------------------------------------------*/
-- Procedure :  PFormulaCCO
--  Objetivo : Encontrar a formula de calculo e inserir registro de pagamento
--             pertinente a relacao de vinculo (CCO) obedecendo a
--             abrangencia da rubrica para lanc. financeiros ou decisoes judiciais.

--       pTpRegistro - 1) Lancamento Financeiro
--                     2) Decisao judicial
--                     3) Enventos
/*--------------------------------------------------------------------------------*/
PROCEDURE PFormulaCCO(pCdTipoReg        IN INTEGER,
                      pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                      pCdFolhaPagamento IN INTEGER,
                      pCdOrgao          IN INTEGER,
                      pCdVinculo        IN INTEGER,
                      pDtInicioMes      IN DATE,
                      pDtFimMes         IN DATE,
                      pRubrica          IN PKGPAG_TIPO.rRubrica,
                      pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                      pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE  DEFAULT NULL,
                      pApenasRVPrinc    IN CHAR DEFAULT 'N') IS

  vCdExpressaoFormCalc INTEGER;

BEGIN

  FOR vCCO IN PKGPAG_VAR.cRelCCO(pCdVinculo,
                                 pDtInicioMes,
                                 pDtFimMes,
                                 PKGPAG_VAR.vDtCalculo)

  LOOP

   IF (pApenasRVPrinc = 'N') OR
      (pApenasRVPrinc = 'S' AND
      (PKGPAG_VAR.vgRelVincPrincipal.CdHist = vCCO.CdHistCargoCom)) THEN

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => pCdOrgao,
                                   pCdOrgaoExercicio         => vCCO.CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => vCCO.CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => vCCO.CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => vCCO.CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => vCCO.CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => vCCO.CdSituacaoPrevidenciaria,
                                   pCdCargoComissionado      => vCCO.CdCargoComissionado,
                                   pCdGrupoOcupacional       => vCCO.CdGrupoOcupacional,
                                   pCdOpcaoRemuneracao       => vCCO.CdOpcaoRemuneracao,
                                   pCdUnidadeOrganizacional  => vCCO.CdUnidadeOrganizacional,
                                   pFlTipoProvimento         => vCCO.FlTipoProvimento,
                                   pCdEstruturaCarreira      => PKGPAG_VAR.vgCdEstruturaCarreira
                                   ) THEN

        vCdExpressaoFormCalc :=

          PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                  pFormExpr                 => pFormExpr,
                                  pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                  pCdRelacaoVinculo         => vCCO.CdTipoRelacao,
                                  pCdCargoComissionado      => vCCO.CdCargoComissionado,
                                  pCdUnidadeOrganizacional  => vCCO.CdUnidadeOrganizacional,
                                  pNuFormulaEspecifica      => pLancamento.NuFormulaEspecifica);

        IF vCdExpressaoFormCalc > 0 THEN

          CASE pCdTipoReg

              WHEN 1 THEN -- Lancamento Financeiro

                pkgpag_var.vgNuIndiceHoraPlantao :=  FRetornaIndiceLancamento(pLancamento,
                                                                                             pDtInicioMes,
                                                                                             pDtFimMes,
                                                                                             vCCO.DtInicio,
                                                                                             vCCO.DtFim);

                PKGPAG_GERAL.PInsereLancamentoRelacao(
                                         pCdFolhaPagamento       => pCdFolhaPagamento,
                                         pCdVinculo              => pCdVinculo,
                                         pCdRelacaoVinculo       => vCCO.CdTipoRelacao,
                                         pCdHistRelacaoVinculo   => vCCO.CdHistCargoCom,
                                         pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                         pCdRubricaAgrupamento   => pLancamento.CdRubricaAgrupamento,
                                         pVlIntegral             => NULL,
                                         pVlProporcional         => NULL,
                                         pNuSufixoRubrica        => pLancamento.NuSufixoRubrica,
                                         pNuParcelas             => pLancamento.NuParcelasProc + 1,
                                         pVlIndice               => pkgpag_var.vgNuIndiceHoraPlantao,
                                         pCdLancamentoFinanceiro => pLancamento.CdLancamentoFinanceiro,
                                         pDtInicioRelacao        => vCCO.DtInicioRelacao,
                                         pDtDesligamento         => vCCO.DtFimRelacao,
                                         pCdTipoOrigemRubrica    => CASE
                                                                     WHEN pLancamento.CdProcessoPagRetroativo IS NULL THEN
                                                                       2
                                                                     ELSE
                                                                       12
                                                                     END,
                                         pDtInicio               => vCCO.DtInicio,
                                         pDtFim                  => vCCO.DtFim);

              WHEN 2 THEN -- Decisao judicial

                PKGPAG_GERAL.PInsereLancamentoRelacao(
                                         pCdFolhaPagamento       => pCdFolhaPagamento,
                                         pCdVinculo              => pCdVinculo,
                                         pCdRelacaoVinculo       => vCCO.CdTipoRelacao,
                                         pCdHistRelacaoVinculo   => vCCO.CdHistCargoCom,
                                         pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                         pCdRubricaAgrupamento   => pLancDetJud.CdRubricaAgrupamento,
                                         pVlIntegral             => NULL,
                                         pVlProporcional         => NULL,
                                         pNuSufixoRubrica        => pLancDetJud.NuSufixoRubrica,
                                         pNuParcelas             => nvl(pLancDetJud.nuparcelaspenhora,0) + 1, -- 21461/2024 - Tiago Von --0,
                                         pVlIndice               => CASE WHEN pLancDetJud.VlIndice IS NULL THEN pLancDetJud.Vlindicepenhora ELSE pLancDetJud.VlIndice END, -- 21461/2024 - Tiago Von, --
                                         pDtInicioRelacao        => vCCO.DtInicioRelacao,
                                         pDtDesligamento         => vCCO.DtFimRelacao,
                                         pCdTipoOrigemRubrica    => 3,
                                         pDtInicio               => vCCO.DtInicio,
                                         pDtFim                  => vCCO.DtFim);

            END CASE;

        END IF;

     END IF;

   END IF;

 END LOOP;

END;

/*--------------------------------------------------------------------------------*/
-- Procedure :  PFormulaFUC
--  Objetivo : Encontrar a formula de calculo e inserir registro de pagamento
--             pertinente a relacao de vinculo (Funcao de chefia) obedecendo a
--             abrangencia da rubrica para lanc. financeiros ou decisoes judiciais.

--       pTpRegistro - 1) Lancamento Financeiro
--                     2) Decisao judicial
/*--------------------------------------------------------------------------------*/
PROCEDURE PFormulaFUC(pCdTipoReg        IN INTEGER,
                      pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                      pCdFolhaPagamento IN INTEGER,
                      pCdOrgao          IN INTEGER,
                      pCdVinculo        IN INTEGER,
                      pDtInicioMes      IN DATE,
                      pDtFimMes         IN DATE,
                      pRubrica          IN PKGPAG_TIPO.rRubrica,
                      pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                      pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE  DEFAULT NULL) IS

 vCdExpressaoFormCalc INTEGER;

BEGIN

   FOR vFUC IN PKGPAG_VAR.cRelFUC(pCdVinculo,
                                  pDtInicioMes,
                                  pDtFimMes)

   LOOP

     IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                  pRubrica                 => pRubrica,
                                  pCdOrgao                 => pCdOrgao,
                                  pCdOrgaoExercicio        => vFUC.CdOrgaoExercicio,
                                  pCdFuncaoChefia          => vFUC.CdFuncaoChefia,
                                  pCdUnidadeOrganizacional => vFUC.CdUnidadeOrganizacional,
                                  pFlTipoProvimento        => vFUC.FlEfetivacao) THEN

       vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                pFormExpr                 => pFormExpr,
                                pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                pCdRelacaoVinculo         => vFUC.CdTipoRelacao,
                                pCdUnidadeOrganizacional  => vFUC.CdUnidadeOrganizacional,
                                pNuFormulaEspecifica      => pLancamento.NuFormulaEspecifica);

       IF vCdExpressaoFormCalc > 0 THEN

         CASE pCdTipoReg

            WHEN 1 THEN -- Lancamento Financeiro

            -- Para o calculo de hora-extra a porporcionalização é feita no final da fb.
            IF prubrica.nurubrica=75 AND PKGPAG_VAR.vgFolha.CdAgrupamento = 5
              THEN

                 pkgpag_var.vgNuIndiceHoraPlantao :=  FRetornaIndiceLancamento(pLancamento,
                                                                                           pDtInicioMes,
                                                                                           pDtFimMes,
                                                                                           pDtInicioMes,
                                                                                           pDtFimMes);
              ELSE
                pkgpag_var.vgNuIndiceHoraPlantao :=  FRetornaIndiceLancamento(pLancamento,
                                                                                             pDtInicioMes,
                                                                                             pDtFimMes,
                                                                                             vFUC.DtInicio,
                                                                                             vFUC.DtFim);
              END IF;

              PKGPAG_GERAL.PInsereLancamentoRelacao(
                                       pCdFolhaPagamento       => pCdFolhaPagamento,
                                       pCdVinculo              => pCdVinculo,
                                       pCdRelacaoVinculo       => vFUC.CdTipoRelacao,
                                       pCdHistRelacaoVinculo   => vFUC.CdHistFuncaoChefia,
                                       pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                       pCdRubricaAgrupamento   => pLancamento.CdRubricaAgrupamento,
                                       pVlIntegral             => NULL,
                                       pVlProporcional         => NULL,
                                       pNuSufixoRubrica        => pLancamento.NuSufixoRubrica,
                                       pNuParcelas             => pLancamento.NuParcelasProc + 1,
                                       pVlIndice               => pkgpag_var.vgNuIndiceHoraPlantao,
                                       pCdLancamentoFinanceiro => pLancamento.CdLancamentoFinanceiro,
                                       pDtInicioRelacao        => vFUC.DtInicioRelacao,
                                       pDtDesligamento         => vFUC.DtFimRelacao,
                                       pCdTipoOrigemRubrica    => CASE
                                                                   WHEN pLancamento.CdProcessoPagRetroativo IS NULL THEN
                                                                     2
                                                                   ELSE
                                                                     12
                                                                   END,
                                       pDtInicio               => vFUC.DtInicio,
                                       pDtFim                  => vFUC.DtFim);

            WHEN 2 THEN -- Decisao judicial

              PKGPAG_GERAL.PInsereLancamentoRelacao(
                                       pCdFolhaPagamento       => pCdFolhaPagamento,
                                       pCdVinculo              => pCdVinculo,
                                       pCdRelacaoVinculo       => vFUC.CdTipoRelacao,
                                       pCdHistRelacaoVinculo   => vFUC.CdHistFuncaoChefia,
                                       pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                       pCdRubricaAgrupamento   => pLancDetJud.CdRubricaAgrupamento,
                                       pVlIntegral             => NULL,
                                       pVlProporcional         => NULL,
                                       pNuSufixoRubrica        => pLancDetJud.NuSufixoRubrica,
                                       pNuParcelas             => nvl(pLancDetJud.nuparcelaspenhora,0) + 1, -- 21461/2024 - Tiago Von --0,
                                       pVlIndice               => CASE WHEN pLancDetJud.VlIndice IS NULL THEN pLancDetJud.Vlindicepenhora ELSE pLancDetJud.VlIndice END, -- 21461/2024 - Tiago Von --pLancDetJud.VlIndice,
                                       pDtInicioRelacao        => vFUC.DtInicioRelacao,
                                       pDtDesligamento         => vFUC.DtFimRelacao,
                                       pCdTipoOrigemRubrica    => 3,
                                       pDtInicio               => vFUC.DtInicio,
                                       pDtFim                  => vFUC.DtFim);

          END CASE;

      END IF;

    END IF;

  END LOOP;

END;

/*--------------------------------------------------------------------------------*/
-- Procedure :  PFormulaBOL
--  Objetivo : Encontrar a formula de calculo pertinente a relacao de vinculo
--             (Bolsista) obedecendo a abrangencia da rubrica
--
/*--------------------------------------------------------------------------------*/
PROCEDURE PFormulaBOL(pCdTipoReg        IN INTEGER,
                      pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                      pCdFolhaPagamento IN INTEGER,
                      pCdOrgao          IN INTEGER,
                      pCdVinculo        IN INTEGER,
                      pDtInicioMes      IN DATE,
                      pDtFimMes         IN DATE,
                      pRubrica          IN PKGPAG_TIPO.rRubrica,
                      pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                      pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE  DEFAULT NULL,
                      pApenasRVPrinc    IN CHAR DEFAULT 'N') IS

  vCdExpressaoFormCalc INTEGER;

BEGIN

  FOR vBOL IN PKGPAG_VAR.cRelBOL(pCdVinculo,
                                 pDtInicioMes,
                                 pDtFimMes)
  LOOP

   IF (pApenasRVPrinc = 'N') OR
      (pApenasRVPrinc = 'S' AND
      (PKGPAG_VAR.vgRelVincPrincipal.CdHist = vBOL.Cdhistestagio)) THEN

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => pCdOrgao,
                                   pCdOrgaoExercicio         => vBOL.CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => vBOL.CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => vBOL.CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => vBOL.CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => vBOL.CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => vBOL.CdSituacaoPrevidenciaria
                                   ) THEN

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                  pFormExpr                 => pFormExpr,
                                  pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                  pCdRelacaoVinculo         => vBOL.CdTipoRelacao,
                                  pCdUnidadeOrganizacional  => vBOL.CdUnidadeOrganizacional,
                                  pNuFormulaEspecifica      => pLancamento.NuFormulaEspecifica);

         IF vCdExpressaoFormCalc > 0 THEN

           CASE pCdTipoReg

             WHEN 1 THEN -- Lancamento Financeiro

               pkgpag_var.vgNuIndiceHoraPlantao := FRetornaIndiceLancamento(pLancamento,
                                                                                           pDtInicioMes,
                                                                                           pDtFimMes,
                                                                                           vBOL.DtInicio,
                                                                                           vBOL.DtDesligamento);

               PKGPAG_GERAL.PInsereLancamentoRelacao(
                                       pCdFolhaPagamento       => pCdFolhaPagamento,
                                       pCdVinculo              => pCdVinculo,
                                       pCdRelacaoVinculo       => vBOL.CdTipoRelacao,
                                       pCdHistRelacaoVinculo   => vBOL.CdHistEstagio,
                                       pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                       pCdRubricaAgrupamento   => pLancamento.CdRubricaAgrupamento,
                                       pVlIntegral             => NULL,
                                       pVlProporcional         => NULL,
                                       pNuSufixoRubrica        => pLancamento.NuSufixoRubrica,
                                       pNuParcelas             => pLancamento.NuParcelasProc + 1,
                                       pVlIndice               => pkgpag_var.vgNuIndiceHoraPlantao,
                                       pCdLancamentoFinanceiro => pLancamento.CdLancamentoFinanceiro,
                                       pDtInicioRelacao        => vBOL.DtInicio,
                                       pDtDesligamento         => vBOL.DtDesligamento,
                                       pCdTipoOrigemRubrica    => CASE
                                                                   WHEN pLancamento.CdProcessoPagRetroativo IS NULL THEN
                                                                     2
                                                                   ELSE
                                                                     12
                                                                   END);

             WHEN 2 THEN -- Decisao judicial

               PKGPAG_GERAL.PInsereLancamentoRelacao(
                                        pCdFolhaPagamento       => pCdFolhaPagamento,
                                        pCdVinculo              => pCdVinculo,
                                        pCdRelacaoVinculo       => vBOL.CdTipoRelacao,
                                        pCdHistRelacaoVinculo   => vBOL.CdHistEstagio,
                                        pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                        pCdRubricaAgrupamento   => pLancDetJud.CdRubricaAgrupamento,
                                        pVlIntegral             => NULL,
                                        pVlProporcional         => NULL,
                                        pNuSufixoRubrica        => pLancDetJud.NuSufixoRubrica,
                                        pNuParcelas             => nvl(pLancDetJud.nuparcelaspenhora,0) + 1, -- 21461/2024 - Tiago Von --0,
                                        pVlIndice               => CASE WHEN pLancDetJud.VlIndice IS NULL THEN pLancDetJud.Vlindicepenhora ELSE pLancDetJud.VlIndice END, -- 21461/2024 - Tiago Von, --pLancDetJud.VlIndice,
                                        pDtInicioRelacao        => vBOL.DtInicio,
                                        pDtDesligamento         => vBOL.DtDesligamento,
                                        pCdTipoOrigemRubrica    => 3);

           END CASE;

         END IF;

      END IF;

   END IF;

 END LOOP;

END;

/*--------------------------------------------------------------------------------*/
-- Procedure :  pFormulaOutras
--  Objetivo : Encontrar a formula de calculo pertinente a relacao de vinculo
--             (Aposentado, Pensao previdenciaria, pensao nao previdenciaria,
--             auxilio reclusao, ex-parlamentar) obedecendo a abrangencia da rubrica
--
/*--------------------------------------------------------------------------------*/
PROCEDURE PFormulaOutras(pCdTipoReg        IN INTEGER,
                         pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                         pCdFolhaPagamento IN INTEGER,
                         pCdOrgao          IN INTEGER,
                         pCdVinculo        IN INTEGER,
                         pDtInicioMes      IN DATE,
                         pDtFimMes         IN DATE,
                         pRubrica          IN PKGPAG_TIPO.rRubrica,
                         pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                         pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE  DEFAULT NULL,
                         pApenasRVPrinc    IN CHAR DEFAULT 'N') IS

  vCdExpressaoFormCalc    INTEGER;

  vCdRelApoAnt            integer;

  FUNCTION FRetornaEstruturaCarreira(pCdTipoRelacao IN INTEGER,
                                     pCdHistRelVinc IN INTEGER)
    RETURN INTEGER IS

  BEGIN

    IF pCdTipoRelacao = 4 THEN

      IF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

        FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
        LOOP

           IF pCdHistRelVinc = PKGPAG_VAR.vgAPO(i).CdHistRelVinc THEN

             RETURN PKGPAG_VAR.vgAPO(i).CdEstruturaCarreira;

           END IF;

        END LOOP;

      END IF;

    END IF;

    RETURN 0;

  END;

BEGIN

  FOR vRelOutras IN PKGPAG_VAR.cRelOutras(pCdVinculo,
                                          pCdOrgao,
                                          pDtInicioMes,
                                          pDtFimMes)
  LOOP

    /*--------------------------------------------------------------------------------------
    -- Se a rubrica indicar que deve ser gerada para todas as relacoes de vinculo, ao se
    -- tratar de aposentado, so gera se o inicio da aposentadoria for inferior ao inicio do
    -- mes de processamento
    ---------------------------------------------------------------------------------------*/

    IF (pApenasRVPrinc = 'N'
       /* A linha baixo foi comentada porque tinha um servidor se aposentando no mes com um lancamento de pos-graduacao (1-131)
       -- em financeiro que estava gerando apenas para a relacao de vinculo de efetivo e nao estava gerando para
       -- a relacao de vinculo de aposentado e ainda por cima estava proporcionalizando pelos dias que ficou no efetivo.
       -- Como aqui e um lancamento sem valor - pr formula - quem diz se deve proporcionalizar ou nao e o parametro da rubrica
       -- e de fato toda rubrica em financeiro sem valor deve ser lancadas em todas as relacoes e deixar que a abrangencia
       -- da rubrica tmebem se responsabilizada se deve ou nao ser pago ... Feito na folha de Fev/2011 */

       /* AND NOT (vRelOutras.CdTipoRelacao = 4 AND (vRelOutras.DtInicioRelacao BETWEEN pDtInicioMes AND pDtFimMes))*/
       ) OR
       (pApenasRVPrinc = 'S' AND
       (PKGPAG_VAR.vgRelVincPrincipal.CdHist = vRelOutras.CdHistRelVinc)) THEN

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica     => pRubrica,
                                   pCdOrgao                  => pCdOrgao,
                                   pCdOrgaoExercicio         => vRelOutras.CdOrgaoExercicio,
                                   pCdSituacaoPrevidenciaria => vRelOutras.CdSituacaoPrevidenciaria,
                                   pFlAPOOrigemCCO           => vRelOutras.FlOrigemCCO) OR
         --
         -- SIG-469 Chamado 12967 Rubrica 01-0249 nao gerando
         --
         pCdTipoReg = 2 then -- Decisao judicial

         if pCdTipoReg = 2 and
            pRubrica.NuRubrica = 914 and
            pRubrica.CdTipoRubrica = 1 and
            pkgpag_var.vgFolha.CdAgrupamento = 1 and not
            PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica     => pRubrica,
                                                   pCdOrgao     => pCdOrgao,
                                                   pCdOrgaoExercicio => vRelOutras.CdOrgaoExercicio,
                                                   pCdSituacaoPrevidenciaria => vRelOutras.CdSituacaoPrevidenciaria) then

            continue;

         end if;

         vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                  pFormExpr                 => pFormExpr,
                                  pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                  pCdRelacaoVinculo         => vRelOutras.CdTipoRelacao,
                                  pNuFormulaEspecifica      => pLancamento.NuFormulaEspecifica,
                                  pCdEstruturaCarreira      => FRetornaEstruturaCarreira(vRelOutras.CdTipoRelacao,
                                                                                         vRelOutras.CdHistRelVinc));

         if pkgpag_var.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao then
            -- Folha instituidores salvar LF na relacao nova se  foi retificado
             begin

             vCdRelApoAnt := vRelOutras.CdHistRelVinc;

              select retif.cdconcessaoaposentadoria
                into vRelOutras.CdHistRelVinc
                from epvdconcessaoaposentadoria retif
               where retif.cdconcessaoaposentadoriaretif = vRelOutras.CdHistRelVinc;

             exception
               when no_data_found then
                 vRelOutras.CdHistRelVinc := vCdRelApoAnt;
               when others then
                 vRelOutras.CdHistRelVinc := vCdRelApoAnt;
             end;

         end if;

         IF vCdExpressaoFormCalc > 0 THEN

           CASE pCdTipoReg

             WHEN 1 THEN -- Lancamento Financeiro

               pkgpag_var.vgNuIndiceHoraPlantao := FRetornaIndiceLancamento(pLancamento,
                                                                            pDtInicioMes,
                                                                            pDtFimMes,
                                                                            vRelOutras.DtInicio,
                                                                            vRelOutras.DtFim);

               pTotalNuDiasVinculo := pTotalNuDiasVinculo + vRelOutras.DtFim - vRelOutras.DtInicio + 1;

               -- ||POG|| para evitar considerar o 31 dia quando uma rubrica e paga para mais de uma relacoes.
               IF pTotalNuDiasVinculo > 30 AND TO_CHAR(vRelOutras.DtFim, 'DD') = '31' THEN

                 pkgpag_var.vgNuIndiceHoraPlantao := FRetornaIndiceLancamento(pLancamento,
                                                                              pDtInicioMes,
                                                                              pDtFimMes,
                                                                              vRelOutras.DtInicio,
                                                                              vRelOutras.DtFim-1);
               END IF;

               PKGPAG_GERAL.PInsereLancamentoRelacao(
                                        pCdFolhaPagamento       => pCdFolhaPagamento,
                                        pCdVinculo              => pCdVinculo,
                                        pCdRelacaoVinculo       => vRelOutras.CdTipoRelacao,
                                        pCdHistRelacaoVinculo   => vRelOutras.CdHistRelVinc,
                                        pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                        pCdRubricaAgrupamento   => pLancamento.CdRubricaAgrupamento,
                                        pVlIntegral             => NULL,
                                        pVlProporcional         => NULL,
                                        pNuSufixoRubrica        => pLancamento.NuSufixoRubrica,
                                        pNuParcelas             => pLancamento.NuParcelasProc + 1,
                                        pVlIndice               => pkgpag_var.vgNuIndiceHoraPlantao,
                                        pCdLancamentoFinanceiro => pLancamento.CdLancamentoFinanceiro,
                                        pDtInicioRelacao        => vRelOutras.DtInicioRelacao,
                                        pDtDesligamento         => vRelOutras.DtFimRelacao,
                                        pCdTipoOrigemRubrica    => CASE
                                                                     WHEN pLancamento.CdProcessoPagRetroativo IS NULL THEN
                                                                       2
                                                                   ELSE
                                                                     12
                                                                   END,
                                       pDtInicio                => vRelOutras.DtInicio,
                                       pDtFim                   => vRelOutras.DtFim);

             WHEN 2 THEN -- Decisao judicial

               PKGPAG_GERAL.PInsereLancamentoRelacao(
                                        pCdFolhaPagamento       => pCdFolhaPagamento,
                                        pCdVinculo              => pCdVinculo,
                                        pCdRelacaoVinculo       => vRelOutras.CdTipoRelacao,
                                        pCdHistRelacaoVinculo   => vRelOutras.CdHistRelVinc,
                                        pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                        pCdRubricaAgrupamento   => pLancDetJud.CdRubricaAgrupamento,
                                        pVlIntegral             => NULL,
                                        pVlProporcional         => NULL,
                                        pNuSufixoRubrica        => pLancDetJud.NuSufixoRubrica,
                                        pNuParcelas             => nvl(pLancDetJud.nuparcelaspenhora,0) + 1, -- 21461/2024 - Tiago Von, -- 0,
                                        pVlIndice               => CASE WHEN pLancDetJud.VlIndice IS NULL THEN pLancDetJud.Vlindicepenhora ELSE pLancDetJud.VlIndice END, -- 21461/2024 - Tiago Von -- pLancDetJud.VlIndice,
                                        pDtInicioRelacao        => vRelOutras.DtInicioRelacao,
                                        pDtDesligamento         => vRelOutras.DtFimRelacao,
                                        pCdTipoOrigemRubrica    => 3,
                                        pDtInicio               => vRelOutras.DtInicio,
                                        pDtFim                  => vRelOutras.DtFim);

           END CASE;

          END IF;

        END IF;

    END IF;

  END LOOP;

END;

/*------------------------------------------------------------------------*/
--  Procedure: PFormulaPropRelVinc
--   Objetivo: Atender regra de parametrizacao da rubrica para lancamentos
--             financeiros, decisoes judiciais e eventos baseados em formula
--             de calculo.
--             "Gerar para todas as relacoes de vinculo"

/*------------------------------------------------------------------------*/
PROCEDURE  PFormulaPropRelVinc(pCdTipoReg        IN INTEGER,
                               pCdVinculo        IN INTEGER,
                               pDtInicioMes      IN DATE,
                               pDtFimMes         IN DATE,
                               pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                               pCdFolhaPagamento IN INTEGER,
                               pCdOrgao          IN INTEGER,
                               pRubrica          IN PKGPAG_TIPO.rRubrica,
                               pLancamento       IN cLancParcela%ROWTYPE,
                               pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE) IS

BEGIN

    PFormulaCEF(pCdTipoReg        => pCdTipoReg,
                pFormExpr         => pFormExpr,
                pCdFolhaPagamento => pCdFolhaPagamento,
                pCdOrgao          => pCdOrgao,
                pCdVinculo        => pCdVinculo,
                pDtInicioMes      => pDtInicioMes,
                pDtFimMes         => pDtFimMes,
                pRubrica          => pRubrica,
                pLancamento       => pLancamento,
                pLancDetJud       => pLancDetJud);

    PFormulaCCO(pCdTipoReg        => pCdTipoReg,
                pFormExpr         => pFormExpr,
                pCdFolhaPagamento => pCdFolhaPagamento,
                pCdOrgao          => pCdOrgao,
                pCdVinculo        => pCdVinculo,
                pDtInicioMes      => pDtInicioMes,
                pDtFimMes         => pDtFimMes,
                pRubrica          => pRubrica,
                pLancamento       => pLancamento,
                pLancDetJud       => pLancDetJud);

    PFormulaFUC(pCdTipoReg        => pCdTipoReg,
                pFormExpr         => pFormExpr,
                pCdFolhaPagamento => pCdFolhaPagamento,
                pCdOrgao          => pCdOrgao,
                pCdVinculo        => pCdVinculo,
                pDtInicioMes      => pDtInicioMes,
                pDtFimMes         => pDtFimMes,
                pRubrica          => pRubrica,
                pLancamento       => pLancamento,
                pLancDetJud       => pLancDetJud);

    PFormulaBOL(pCdTipoReg        => pCdTipoReg,
                pFormExpr         => pFormExpr,
                pCdFolhaPagamento => pCdFolhaPagamento,
                pCdOrgao          => pCdOrgao,
                pCdVinculo        => pCdVinculo,
                pDtInicioMes      => pDtInicioMes,
                pDtFimMes         => pDtFimMes,
                pRubrica          => pRubrica,
                pLancamento       => pLancamento,
                pLancDetJud       => pLancDetJud);

    PFormulaOutras(pCdTipoReg        => pCdTipoReg,
                   pFormExpr         => pFormExpr,
                   pCdFolhaPagamento => pCdFolhaPagamento,
                   pCdOrgao          => pCdOrgao,
                   pCdVinculo        => pCdVinculo,
                   pDtInicioMes      => pDtInicioMes,
                   pDtFimMes         => pDtFimMes,
                   pRubrica          => pRubrica,
                   pLancamento       => pLancamento,
                   pLancDetJud       => pLancDetJud);

END;

/*---------------------------------------------------------------------------------*/
-- Procedimento : PGeracaoLancamentoFormula
--     Objetivo : Gerar registros de pagamentos de lancamentos financeiros e
--                decisoes judiciais com formula de calculo

--       pTpRegistro - 1) Lancamento Financeiro
--                     2) Decisao judicial
/*----------------------------------------------------------------------------------*/
PROCEDURE PGeracaoLancamentoFormula(pFolha            IN PKGPAG_TIPO.rFolha,
                                    pCdVinculo        IN INTEGER,
                                    pRubrica          IN PKGPAG_TIPO.rRubrica,
                                    pTipoRegistro     IN INTEGER,
                                    pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                                    pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE DEFAULT NULL) IS
BEGIN

  CASE

    WHEN PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes OR                         -- 21461/2024 - Tiago Von
         pFolha.CdTipoFolha in (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaAdiant13) THEN -- 21461/2024 - Tiago Von

      PFormulaVinc(pCdTipoReg        => pTipoRegistro,
                   pFormExpr         => PKGPAG_VAR.vgFormExpr,
                   pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                   pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                   pCdVinculo        => pCdVinculo,
                   pDtInicioMes      => pFolha.DtInicioMes,
                   pDtFimMes         => pFolha.DtFimMes,
                   pRubrica          => pRubrica,
                   pLancamento       => pLancamento,
                   pLancDetJud       => pLancDetJud);

    WHEN pRubrica.InLancPropRelVinc = 1 THEN -- Gerar para a relacao de vinculo principal

      CASE PKGPAG_VAR.vgRelVincPrincipal.Tipo

         WHEN 1 THEN

           PFormulaCEF(pCdTipoReg        => pTipoRegistro,
                       pFormExpr         => PKGPAG_VAR.vgFormExpr,
                       pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                       pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                       pCdVinculo        => pCdVinculo,
                       pDtInicioMes      => pFolha.DtInicioMes,
                       pDtFimMes         => pFolha.DtFimMes,
                       pRubrica          => pRubrica,
                       pLancamento       => pLancamento,
                       pLancDetJud       => pLancDetJud,
                       pApenasRVPrinc    => 'S');

         WHEN 2 THEN

           PFormulaCCO(pCdTipoReg        => pTipoRegistro,
                       pFormExpr         => PKGPAG_VAR.vgFormExpr,
                       pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                       pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                       pCdVinculo        => pCdVinculo,
                       pDtInicioMes      => pFolha.DtInicioMes,
                       pDtFimMes         => pFolha.DtFimMes,
                       pRubrica          => pRubrica,
                       pLancamento       => pLancamento,
                       pLancDetJud       => pLancDetJud,
                       pApenasRVPrinc    => 'S');

        WHEN 5 THEN

           PFormulaBOL(pCdTipoReg        => pTipoRegistro,
                       pFormExpr         => PKGPAG_VAR.vgFormExpr,
                       pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                       pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                       pCdVinculo        => pCdVinculo,
                       pDtInicioMes      => pFolha.DtInicioMes,
                       pDtFimMes         => pFolha.DtFimMes,
                       pRubrica          => pRubrica,
                       pLancamento       => pLancamento,
                       pLancDetJud       => pLancDetJud,
                       pApenasRVPrinc    => 'S');

        ELSE

           PFormulaOutras(pCdTipoReg        => pTipoRegistro,
                          pFormExpr         => PKGPAG_VAR.vgFormExpr,
                          pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                          pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                          pCdVinculo        => pCdVinculo,
                          pDtInicioMes      => pFolha.DtInicioMes,
                          pDtFimMes         => pFolha.DtFimMes,
                          pRubrica          => pRubrica,
                          pLancamento       => pLancamento,
                          pLancDetJud       => pLancDetJud,
                          pApenasRVPrinc    => 'S');

      END CASE;

    WHEN pRubrica.InLancPropRelVinc = 2 THEN -- Gerar para todas as relacoes de vinculo

      PFormulaPropRelVinc(pCdTipoReg        => pTipoRegistro,
                          pFormExpr         => PKGPAG_VAR.vgFormExpr,
                          pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                          pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                          pCdVinculo        => pCdVinculo,
                          pDtInicioMes      => pFolha.DtInicioMes,
                          pDtFimMes         => pFolha.DtFimMes,
                          pRubrica          => pRubrica,
                          pLancamento       => pLancamento,
                          pLancDetJud       => pLancDetJud);

    WHEN  pRubrica.InLancPropRelVinc = 3 THEN -- Gerar para a relacao de vinculo de comissionado

      PFormulaCCO(pCdTipoReg        => pTipoRegistro,
                  pFormExpr         => PKGPAG_VAR.vgFormExpr,
                  pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                  pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                  pCdVinculo        => pCdVinculo,
                  pDtInicioMes      => pFolha.DtInicioMes,
                  pDtFimMes         => pFolha.DtFimMes,
                  pRubrica          => pRubrica,
                  pLancamento       => pLancamento,
                  pLancDetJud       => pLancDetJud);

    WHEN  pRubrica.InLancPropRelVinc = 4 THEN -- Gerar para a relacao de vinculo de fucao de chefia

      PFormulaFUC(pCdTipoReg        => pTipoRegistro,
                  pFormExpr         => PKGPAG_VAR.vgFormExpr,
                  pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                  pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                  pCdVinculo        => pCdVinculo,
                  pDtInicioMes      => pFolha.DtInicioMes,
                  pDtFimMes         => pFolha.DtFimMes,
                  pRubrica          => pRubrica,
                  pLancamento       => pLancamento,
                  pLancDetJud       => pLancDetJud);

    WHEN  pRubrica.InLancPropRelVinc = 5 THEN -- Gerar para a relacao de vinculo de aposentado

      PFormulaOutras(pCdTipoReg        => pTipoRegistro,
                     pFormExpr         => PKGPAG_VAR.vgFormExpr,
                     pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                     pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                     pCdVinculo        => pCdVinculo,
                     pDtInicioMes      => pFolha.DtInicioMes,
                     pDtFimMes         => pFolha.DtFimMes,
                     pRubrica          => pRubrica,
                     pLancamento       => pLancamento,
                     pLancDetJud       => pLancDetJud);
    ELSE
      NULL;

  END CASE;

END;

FUNCTION FGeraLancMesAposentadoria (pCdvinculo               IN INTEGER,
                                    pVlLancamento            IN NUMBER,
                                    pVlReal                  IN NUMBER,
                                    pCdRubricaAgrupamento    IN INTEGER,
                                    pNuSufixoRubrica         IN INTEGER,
                                    pNuParcelasProc          IN INTEGER,
                                    pVlIndice                IN INTEGER,
                                    pCdLancamentoFinanceiro  IN INTEGER,
                                    pCdTipoOrigemRubrica     IN INTEGER,
                                    pCdProcessoPagRetroativo IN INTEGER,
                                    pDtCalculo               IN DATE)

  RETURN BOOLEAN IS
  pVlCefProporcional NUMBER;
  pVlApoProporcional   NUMBER;
  pnudiasmes           INTEGER:=30;
  vVlIndiceCEF            INTEGER;
  vVlIndiceAPO            INTEGER;

BEGIN

  IF (PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 1 AND
      PKGPAG_VAR.vgApo.count > 0 AND
      PKGPAG_VAR.vgApo(1).DtInicioRelacao > PKGPAG_VAR.vgFolha.dtInicioMes AND
      PKGPAG_VAR.vgApo(1).DtInicioRelacao < PKGPAG_VAR.vgFolha.dtFimMes AND
      NVL(pVlLancamento,0) > 0) THEN

      vVlIndiceCEF := PKGPAG_VAR.vgApo(1).DtInicioRelacao - PKGPAG_VAR.vgFolha.dtInicioMes;
      vVlIndiceAPO := 30 - vVlIndiceCEF;

      -- Valor referente ao efetivo
      pVlCefProporcional:= trunc(pVlLancamento*vVlIndiceCEF/pNuDiasMes, 2);

      PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo              => pCdVinculo,
                                             pCdRelacaoVinculo       => 1, --Efetivo
                                             pCdHistRelacaoVinculo   => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                             pCdExpressaoFormCalc    => NULL,
                                             pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                             pVlIntegral             => pVlCefProporcional,
                                             pVlProporcional         => pVlCefProporcional,
                                             pVlReal                 => pVlReal,
                                             pNuSufixoRubrica        => pNuSufixoRubrica,
                                             pNuParcelas             => pNuParcelasProc + 1,
                                             pVlIndice               => pVlIndice,
                                             pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                             pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                             pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

      -- Valor referente a aposentadoria
      pVlApoProporcional:= pVlLancamento - pVlCefProporcional;

      PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                               pCdVinculo              => pCdVinculo,
                                               pCdRelacaoVinculo       => 4, --Aposentadoria
                                               pCdHistRelacaoVinculo   => PKGPAG_VAR.vgAPO(1).CdHistRelVinc,
                                               pCdExpressaoFormCalc    => NULL,
                                               pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                               pVlIntegral             => pVlApoProporcional,
                                               pVlProporcional         => pVlApoProporcional,
                                               pVlReal                 => pVlReal,
                                               pNuSufixoRubrica        => pNuSufixoRubrica,
                                               pNuParcelas             => pNuParcelasProc + 1,
                                               pVlIndice               => pVlIndice,
                                               pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                               pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                               pDtInicio               => PKGPAG_VAR.vgAPO(1).DtInicio,
                                               pDtFim                  => PKGPAG_VAR.vgAPO(1).DtFim,
                                               pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);
      RETURN TRUE;
 ELSE
      RETURN FALSE;
 END IF;

END;

/*---------------------------------------------------------------------------------*/
-- Procedimento : PGeracaoLancamentoValor
--     Objetivo : Gerar registros de pagamentos de lancamentos financeiros e
--                decisoes judiciais com valor informado
/*----------------------------------------------------------------------------------*/
PROCEDURE PGeracaoLancamentoValor(pFolha                   IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo               IN INTEGER,
                                  pCdRubricaAgrupamento    IN INTEGER,
                                  pNuSufixoRubrica         IN INTEGER,
                                  pNuParcelasProc          IN INTEGER  DEFAULT NULL,
                                  pInPossuiValorInformado  IN CHAR     DEFAULT '1',
                                  pVlLancamento            IN NUMBER,
                                  pVlIndice                IN INTEGER,
                                  pCdLancamentoFinanceiro  IN INTEGER  DEFAULT NULL,
                                  pCdTipoOrigemRubrica     IN INTEGER  DEFAULT 1,
                                  pVlIntegralIPREV         IN NUMBER   DEFAULT NULL,
                                  pDeProcessoRetroativo    IN VARCHAR2 DEFAULT NULL,
                                  pVlRestituir             IN NUMBER   DEFAULT NULL,
                                  pVlReal                  IN NUMBER   DEFAULT NULL,
                                  pCdProcessoPagRetroativo IN INTEGER DEFAULT NULL,
                                  pFlValorProporcional     IN CHAR DEFAULT NULL,
                                  pDtInicioDireito         IN DATE DEFAULT pkgpag_var.vgFolha.DtInicioMes,
                                  pDtFimDireito            IN DATE DEFAULT pkgpag_var.vgFolha.DtFimMes,
                                  pFlProcessoRestErario    IN CHAR DEFAULT 'N') IS

  vProporcional  PKGPAG_TIPO.rValorPagamento;

BEGIN

   IF pFlProcessoRestErario = 'N'
      and FGeraLancMesAposentadoria(pCdvinculo,
                                pVlLancamento,
                                pVlReal,
                                pCdRubricaAgrupamento,
                                pNuSufixoRubrica,
                                pNuParcelasProc,
                                pVlIndice,
                                pCdLancamentoFinanceiro,
                                pCdTipoOrigemRubrica,
                                pCdProcessoPagRetroativo,
                                PKGPAG_VAR.vgFolha.dtCalculo) THEN
     RETURN;
   END IF;

   CASE pInPossuiValorInformado

     WHEN '0' THEN -- Gera lancamento no vinculo

       PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                             pCdVinculo              => pCdVinculo,
                                             pCdExpressaoFormCalc    => NULL,
                                             pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                             pNuSufixoRubrica        => pNuSufixoRubrica,
                                             pVlPagamento            => pVlLancamento,
                                             pNuParcelas             => pNuParcelasProc + 1,
                                             pVlIndice               => pVlIndice,
                                             pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                             pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                             pDeProcessoRetroativo   => pDeProcessoRetroativo,
                                             pVlRestituir            => pVlRestituir,
                                             pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

     WHEN '1' THEN -- Gerar para a relacao de vinculo principal

     /*
        --Caso nao seja aposentado sem paridade ou caso seja um aposentado com aposendadoria sem paridade
        --com data de inicio no ano/mes do processamento, gera o lancamento

       IF (PKGPAG_VAR.vgAPOSemParidade.COUNT = 0) THEN*/

       -- Pasep - melhorar - Nao paga para CCO com opcao de remuneracao na Origem ou Militar Na Origem

         PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                               pCdVinculo              => pCdVinculo,
                                               pCdRelacaoVinculo       => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                               pCdHistRelacaoVinculo   => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                               pCdExpressaoFormCalc    => NULL,
                                               pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                               pVlIntegral             => CASE
                                                                            WHEN PKGPAG_VAR.vgRelVincPrincipal.Tipo = 1 AND
                                                                                 pVlIntegralIPREV  >= 0 THEN
                                                                              NVL(pVlIntegralIPREV, 0)
                                                                          ELSE
                                                                            pVlLancamento
                                                                          END,
                                               pVlProporcional         => pVlLancamento,
                                               pVlReal                 => pVlReal,
                                               pNuSufixoRubrica        => pNuSufixoRubrica,
                                               pNuParcelas             => pNuParcelasProc + 1,
                                               pVlIndice               => pVlIndice,
                                               pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                               pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                               pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

             -- Lanca na relacao de VINCULO DE EFETIVO O VALOR INTEGRAL INCIDENTE PARA O IPREV QUANDO A RELACAO DE
             -- VINCULO PRINCIPAL FOR O COMISSIONADO POR O ESTAR EXERCENDO

          IF PKGPAG_VAR.vgRelVincPrincipal.Tipo = 2 AND PKGPAG_VAR.vgCEF.COUNT > 0 AND NVL(pVlIntegralIPREV, 0) > 0 THEN

             PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                   pCdVinculo              => pCdVinculo,
                                                   pCdRelacaoVinculo       => 1, --- CEF
                                                   pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(1).CdHistCargoEfetivo, --- CEF
                                                   pCdExpressaoFormCalc    => NULL,
                                                   pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                                   pVlIntegral             => NVL(pVlIntegralIPREV, 0),
                                                   pVlProporcional         => 0,
                                                   pNuSufixoRubrica        => pNuSufixoRubrica,
                                                   pNuParcelas             => pNuParcelasProc + 1,
                                                   pVlIndice               => pVlIndice,
                                                   pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                                   pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                   pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

         END IF;
      -- END IF;

     WHEN '2' THEN -- Gerar para a relacao de vinculo de comissionado como nomeado/designado

       IF PKGPAG_VAR.vgCCO.COUNT > 0 THEN

         FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST
         LOOP

           PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                 pCdVinculo              => pCdVinculo,
                                                 pCdRelacaoVinculo       => 2,
                                                 pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCCO(i).CdHistCargoCom,
                                                 pCdExpressaoFormCalc    => NULL,
                                                 pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                                 pVlIntegral             => pVlLancamento,
                                                 pVlProporcional         => pVlLancamento,
                                                 pVlReal                 => pVlReal,
                                                 pNuSufixoRubrica        => pNuSufixoRubrica,
                                                 pNuParcelas             => pNuParcelasProc + 1,
                                                 pVlIndice               => pVlIndice,
                                                 pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                                 pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                 pDtInicio               => PKGPAG_VAR.vgCCO(i).DtInicio,
                                                 pDtFim                  => PKGPAG_VAR.vgCCO(i).DtFim,
                                                 pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

          EXIT; -- Gerar apenas para uma relacao

        END LOOP;

       ELSIF pCdRubricaAgrupamento IN (7927, 7928)   THEN -- POG: Somente para rubrica 01-0538 e 01-0539 da agpe,
                                                -- deve verificar tambem substituicao

             IF PKGPAG_VAR.vgCCOSubst.COUNT > 0 THEN

               FOR i IN PKGPAG_VAR.vgCCOSubst.FIRST .. PKGPAG_VAR.vgCCOSubst.LAST
               LOOP

                 PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                       pCdVinculo              => pCdVinculo,
                                                       pCdRelacaoVinculo       => 2,
                                                       pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCCOSubst(i).CdHistCargoCom,
                                                       pCdExpressaoFormCalc    => NULL,
                                                       pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                                       pVlIntegral             => pVlLancamento,
                                                       pVlProporcional         => pVlLancamento,
                                                       pVlReal                 => pVlReal,
                                                       pNuSufixoRubrica        => pNuSufixoRubrica,
                                                       pNuParcelas             => pNuParcelasProc + 1,
                                                       pVlIndice               => pVlIndice,
                                                       pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                                       pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                       pDtInicio               => PKGPAG_VAR.vgCCOSubst(i).DtInicio,
                                                       pDtFim                  => PKGPAG_VAR.vgCCOSubst(i).DtFim,
                                                       pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);
              END LOOP;

            END IF;

       else
         null;
       END IF;

    WHEN '3' THEN -- Gerar para a relacao de vinculo de substituicao de comissionado

       IF PKGPAG_VAR.vgCCOSubst.COUNT > 0 THEN

         FOR i IN PKGPAG_VAR.vgCCOSubst.FIRST .. PKGPAG_VAR.vgCCOSubst.LAST
         LOOP

           PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                 pCdVinculo              => pCdVinculo,
                                                 pCdRelacaoVinculo       => 2,
                                                 pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCCOSubst(i).CdHistCargoCom,
                                                 pCdExpressaoFormCalc    => NULL,
                                                 pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                                 pVlIntegral             => pVlLancamento,
                                                 pVlProporcional         => pVlLancamento,
                                                 pVlReal                 => pVlReal,
                                                 pNuSufixoRubrica        => pNuSufixoRubrica,
                                                 pNuParcelas             => pNuParcelasProc + 1,
                                                 pVlIndice               => pVlIndice,
                                                 pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                                 pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                 pDtInicio               => PKGPAG_VAR.vgCCOSubst(i).DtInicio,
                                                 pDtFim                  => PKGPAG_VAR.vgCCOSubst(i).DtFim,
                                                 pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);
        END LOOP;

      END IF;

    WHEN '4' THEN --  Gerar para a relacao de vinculo de funcao de chefia como titular.

       IF PKGPAG_VAR.vgFUC.COUNT > 0 THEN

         FOR i IN PKGPAG_VAR.vgFUC.FIRST .. PKGPAG_VAR.vgFUC.LAST
         LOOP

           PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                 pCdVinculo              => pCdVinculo,
                                                 pCdRelacaoVinculo       => 3,
                                                 pCdHistRelacaoVinculo   => PKGPAG_VAR.vgFUC(i).CdHistFuncaoChefia,
                                                 pCdExpressaoFormCalc    => NULL,
                                                 pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                                 pVlIntegral             => pVlLancamento,
                                                 pVlProporcional         => pVlLancamento,
                                                 pVlReal                 => pVlReal,
                                                 pNuSufixoRubrica        => pNuSufixoRubrica,
                                                 pNuParcelas             => pNuParcelasProc + 1,
                                                 pVlIndice               => pVlIndice,
                                                 pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                                 pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                 pDtInicio               => PKGPAG_VAR.vgFUC(i).DtInicio,
                                                 pDtFim                  => PKGPAG_VAR.vgFUC(i).DtFim,
                                                 pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

        END LOOP;

      END IF;

   WHEN '5' THEN --  Gerar para a relacao de vinculo de substituicao de funcao de chefia.

       IF PKGPAG_VAR.vgFUCSubst.COUNT > 0 THEN

         FOR i IN PKGPAG_VAR.vgFUCSubst.FIRST .. PKGPAG_VAR.vgFUCSubst.LAST
         LOOP

           PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                 pCdVinculo              => pCdVinculo,
                                                 pCdRelacaoVinculo       => 3,
                                                 pCdHistRelacaoVinculo   => PKGPAG_VAR.vgFUCSubst(i).CdHistFuncaoChefia,
                                                 pCdExpressaoFormCalc    => NULL,
                                                 pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                                 pVlIntegral             => pVlLancamento,
                                                 pVlProporcional         => pVlLancamento,
                                                 pVlReal                 => pVlReal,
                                                 pNuSufixoRubrica        => pNuSufixoRubrica,
                                                 pNuParcelas             => pNuParcelasProc + 1,
                                                 pVlIndice               => pVlIndice,
                                                 pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                                 pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                 pDtInicio               => PKGPAG_VAR.vgFUCSubst(i).DtInicio,
                                                 pDtFim                  => PKGPAG_VAR.vgFUCSubst(i).DtFim,
                                                 pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

        END LOOP;

      END IF;

   WHEN '6' THEN -- Gerar para a relacao de vinculo de aposentadoria
                 -- ira gerar apenas para aquela com maior data fim

     IF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

       FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.FIRST
       LOOP

         PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                               pCdVinculo              => pCdVinculo,
                                               pCdRelacaoVinculo       => 4,
                                               pCdHistRelacaoVinculo   => PKGPAG_VAR.vgAPO(i).CdHistRelVinc,
                                               pCdExpressaoFormCalc    => NULL,
                                               pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                               pVlIntegral             => pVlLancamento,
                                               pVlProporcional         => pVlLancamento,
                                               pVlReal                 => pVlReal,
                                               pNuSufixoRubrica        => pNuSufixoRubrica,
                                               pNuParcelas             => pNuParcelasProc + 1,
                                               pVlIndice               => pVlIndice,
                                               pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                               pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                               pDtInicio               => PKGPAG_VAR.vgAPO(i).DtInicio,
                                               pDtFim                  => PKGPAG_VAR.vgAPO(i).DtFim,
                                               pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

       END LOOP;

      END IF;

     WHEN 7 THEN --  Gerar para a relacao de vinculo de cargo efetivo/aposentadoria

      IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

        FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
        LOOP

          IF pFlValorProporcional = 'N'
             and pDtInicioDireito = pFolha.DtInicioMes
             and pDtFimDireito = pFolha.DtFimMes then
             vProporcional.vlIntegral     := pVlLancamento;
             vProporcional.VlReal         := pVlLancamento;
             vProporcional.vlProporcional := pVlLancamento;
          else
             vProporcional :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                       pRubrica           => PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento),
                                                                      pValorIntegral     => pVlLancamento,
                                                                      pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                      pCEF               => PKGPAG_VAR.vgCEF(i),
                                                                      pDtCalculo         => PKGPAG_VAR.vDtCalculo,
                                                                      pEventoCEF         => 'N');
          end if;

          PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                pCdVinculo              => pCdVinculo,
                                                pCdRelacaoVinculo       => 1,
                                                pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                pCdExpressaoFormCalc    => NULL,
                                                pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                                pVlIntegral             => vProporcional.vlIntegral,
                                                pVlProporcional         => vProporcional.vlProporcional,
                                                pVlReal                 => pVlReal,
                                                pNuSufixoRubrica        => pNuSufixoRubrica,
                                                pNuParcelas             => pNuParcelasProc + 1,
                                                pVlIndice               => pVlIndice,
                                                pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                                pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                                                pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim,
                                                pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

        END LOOP;

     END IF;

     IF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

       FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
       LOOP

         vProporcional :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                  pRubrica           => PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento),
                                                                  pValorIntegral     => pVlLancamento,
                                                                  pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                  pAPO               => PKGPAG_VAR.vgAPO(i),
                                                                  pDtCalculo         => PKGPAG_VAR.vDtCalculo);

         PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                               pCdVinculo              => pCdVinculo,
                                               pCdRelacaoVinculo       => 4,
                                               pCdHistRelacaoVinculo   => PKGPAG_VAR.vgAPO(i).CdHistRelVinc,
                                               pCdExpressaoFormCalc    => NULL,
                                               pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                               pVlIntegral             => vProporcional.vlIntegral,
                                               pVlProporcional         => vProporcional.vlProporcional,
                                               pVlReal                 => pVlReal,
                                               pNuSufixoRubrica        => pNuSufixoRubrica,
                                               pNuParcelas             => pNuParcelasProc + 1,
                                               pVlIndice               => pVlIndice,
                                               pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                               pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                               pDtInicio               => PKGPAG_VAR.vgAPO(i).DtInicio,
                                               pDtFim                  => PKGPAG_VAR.vgAPO(i).DtFim,
                                               pCdProcessoPagRetroativo=> pCdProcessoPagRetroativo);

       END LOOP;

     END IF;

     --
     -- Pensao nao previdenciaria, tratar uma excecao para a rubrica 09-0363
     --
     IF PKGPAG_VAR.vgPensaoNaoPrev.COUNT > 0 AND pCdRubricaAgrupamento = 46022 --and pCdVinculo IN (171413, 651330)

       THEN

       FOR i IN PKGPAG_VAR.vgPensaoNaoPrev.FIRST .. PKGPAG_VAR.vgPensaoNaoPrev.LAST
       LOOP

         /*vProporcional :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                  pRubrica           => PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento),
                                                                  pValorIntegral     => pVlLancamento,
                                                                  pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                  pPNP               => PKGPAG_VAR.vgPensaoNaoPrev(i),
                                                                  pDtCalculo         => PKGPAG_VAR.vDtCalculo);      */

         PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                               pCdVinculo              => pCdVinculo,
                                               pCdRelacaoVinculo       => 7,
                                               pCdHistRelacaoVinculo   => PKGPAG_VAR.vgPensaoNaoPrev(i).CdHistPensaoNaoPrev,
                                               pCdExpressaoFormCalc    => NULL,
                                               pCdRubricaAgrupamento   => pCdRubricaAgrupamento,
                                               pVlIntegral             => pVlLancamento,--vProporcional.vlIntegral,
                                               pVlProporcional         => pVlLancamento, --vProporcional.vlProporcional,
                                               pVlReal                 => pVlLancamento,--pVlReal,
                                               pNuSufixoRubrica        => pNuSufixoRubrica,
                                               pNuParcelas             => pNuParcelasProc + 1,
                                               pVlIndice               => pVlIndice,
                                               pCdLancamentoFinanceiro => pCdLancamentoFinanceiro,
                                               pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                               pDtInicio               => PKGPAG_VAR.vgPensaoNaoPrev(i).DtInicio,
                                               pDtFim                  => PKGPAG_VAR.vgPensaoNaoPrev(i).DtFim);

       END LOOP;

     END IF;

  END CASE;

END;

PROCEDURE PGeracaoLancamentoNaoFormula(pFolha            IN PKGPAG_TIPO.rFolha,
                                       pCdVinculo        IN INTEGER,
                                       pRubrica          IN PKGPAG_TIPO.rRubrica,
                                       pTipoRegistro     IN INTEGER,
                                       pLancamento       IN cLancParcela%ROWTYPE DEFAULT NULL,
                                       pLancDetJud       IN cPagDecisaoJudicial%ROWTYPE DEFAULT NULL) IS

  vvlLancamento        NUMBER(13,2);
  vNuDias              INTEGER;
  vNuDiasMes           INTEGER;
  vNuDiasAfastMes      INTEGER;
  vDtInicio            DATE;
  vDtFim               DATE;
  vInPossuiValorInformado INTEGER:= 1;

  /*--------------------------------------------------------------------------------*/
  --  Funcao que verifica se o vinculo esteve afastado no mes pelo menos um dia                                                          */
  /*--------------------------------------------------------------------------------*/
   FUNCTION FDiasAfastadoSemRemuneracao(pCdVinculo   IN INTEGER,
                                        pdtInicioMes IN DATE,
                                        pdtFimMes    IN DATE,
                                        pdtCalculo   IN DATE)  RETURN INTEGER IS

     vNuDiasAfast INTEGER;

     vDtFimMes    DATE;

   BEGIN

     IF TO_CHAR(pDtFimMes,'DD') = '31' THEN

        vDtFimMes := pDtFimMes -1;

     ELSE

        vDtFimMes := pDtFimMes;

     END IF;

     SELECT nvl(SUM(DiaAfastado),0) AS NuDiaAfast
       INTO vNuDiasAfast
       FROM ( SELECT CdVinculo, dtDia AS DtDiaAfastado, 1 AS DiaAfastado
                FROM (SELECT pdtInicioMes + (LEVEL - 1) AS dtdia
                        FROM dual
                     CONNECT BY pdtInicioMes + (LEVEL - 1)
                     BETWEEN pdtInicioMes AND vDtFimMes) D
                INNER JOIN (SELECT
                             cdVinculo,
                             CASE
                              WHEN AV.dtInicio < pdtInicioMes THEN
                                pdtInicioMes
                              ELSE
                                AV.Dtinicio
                              END AS dtInicio,
                             CASE
                              WHEN (AV.dtFim > vdtFimMes OR AV.DtFim IS NULL) THEN
                                vdtFimMes
                              ELSE
                               AV.dtFim
                             END AS dtFim
                            FROM EAfaAfastamentoVinculo AV
                           INNER JOIN EAfaMotivoAfastTemporario MAT
                              ON AV.CdMotivoAfastTemporario = MAT.CdMotivoAfastTemporario
                           INNER JOIN EAfaHistMotivoAfastTemp HMAT
                              ON MAT.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
                           WHERE AV.CdVinculo = pCdVinculo
                             AND HMAT.FlRemunerado = PKGPAG_TIPO.cnN
                             AND  AV.DtInicio <= pdtFimMes
                             AND (AV.DtFim >= pdtInicioMes OR AV.DtFim IS NULL)
                             AND  HMAT.DtInicioVigencia <= pdtCalculo
                             AND (HMAT.DtFimVigencia >= pdtCalculo OR HMAT.DtFimVigencia IS NULL)
                             AND  HMAT.FlAnulado = PKGPAG_TIPO.cnN AND AV.FlAnulado = PKGPAG_TIPO.cnN) B
                  ON (B.DtInicio <= D.DtDia) AND (B.DtFim >= D.DtDia)) A;

        IF vNuDiasAfast > 30 OR
           (TO_CHAR(pDtFimMes,'DD') = '28' AND vNuDiasAfast = 28) OR
           (TO_CHAR(pDtFimMes,'DD') = '29' AND vNuDiasAfast = 29)THEN

          RETURN 30;

        ELSE

          RETURN vNuDiasAfast;

        END IF;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

           RETURN 0;

   END;

BEGIN

   --------------------------------------------------------------------------------
   -- Implementacao para atender o CIASC
   --------------------------------------------------------------------------------

   IF PKGPAG_VAR.vgRubrica(pLancamento.CdRubricaAgrupamento).CdTipoRubrica = 3 THEN

     PKGPAG_VAR.bPossuiLancTesouraria := TRUE;

   END IF;
   -- Colocada excecao para esta rubrica antes de implementar as demais
   -- pelo curto tempo de rodar a folha definitiva.
   IF pLancamento.CdRubricaAgrupamento = 10393
     THEN
      vNuDiasAfastMes := FDiasAfastadoSemRemuneracao(pCdVinculo,
                                                  pFolha.DtInicioMes,
                                                  pFolha.DtFimMes,
                                                  pFolha.DtCalculo);
   END IF;
   -- Solicitacao de Sustentacao #77689
   -- 10849/2017 - AUXILIO- FUNERAL NAO ESTA PROPORCIONALIZANDO A RUBRICA 01-0171
   vDtInicio := pLancamento.DtInicio;
   vDtFim := pLancamento.DtFim;

   IF pkgpag_var.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre
     THEN
       SELECT LF.Dtiniciodireito, LF.Dtfimdireito
         INTO vDtInicio, vDtFim
         FROM EPAGLANCAMENTOFINANCEIRO LF
        WHERE LF.Cdlancamentofinanceiro = pLancamento.CdLancamentoFinanceiro;

   END IF;

   IF pkgpag_var.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre
      AND NOT (vDtInicio = pFolha.DtInicioMes AND
               vDtFim IS NOT NULL AND vDtFim = pFolha.DtFimMes)
     THEN

     vNuDiasMes :=  PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes,
                                                   pRubrica.FlPropMesComercial);

     vNuDias := pkgpag_var.vgVinculo.DtDesligamento - pFolha.DtInicioMes + 1 ;

     IF vNuDias > vNuDiasMes THEN

       vNuDias := vNuDiasMes;

     END IF;

     vvlLancamento := (pLancamento.VlLancamentoFinanceiro/vNuDiasMes)*vNuDias;

   ELSIF (pLancamento.CdTipoLancamento = 2 AND pLancamento.FlValorProporcional = 'S')
      OR
      (
        (
          (PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)
          OR
          (vNuDiasAfastMes > 0 AND pLancamento.CdRubricaAgrupamento = 10393)
         )
         AND
         PKGPAG_VAR.vgRubrica(pLancamento.CdRubricaAgrupamento).CdTipoRubrica = 1
         AND
         pLancamento.FlPropDemitidoNoMes = 'S'
      ) THEN

     IF (PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

       vNuDias:= PKGPAG_VAR.vgVinculo.DtDesligamento - pLancamento.DtInicio + 1;

     ELSE

       vNuDias:= pLancamento.DtFim - pLancamento.DtInicio + 1;

     END IF;

     IF to_number(TO_CHAR(pFolha.DtFimMes,'MM')) = 2 AND
        TRUNC(pFolha.DtFimMes) = NVL(TRUNC(pLancamento.DtFim), TRUNC(pFolha.DtFimMes)) THEN

       vNuDias := vNuDias + ( 30 - to_number(TO_CHAR(pFolha.DtFimMes,'DD')) );

     END IF;

     vNuDiasMes :=  PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes,
                                                   pRubrica.FlPropMesComercial);

     IF vNuDiasAfastMes > 0
         THEN
           vNuDias := vNuDiasMes - vNuDiasAfastMes;

     END IF;

     IF vNuDias > vNuDiasMes THEN

       vNuDias := vNuDiasMes;

     END IF;

     vvlLancamento := (pLancamento.VlLancamentoFinanceiro/vNuDiasMes)*vNuDias;

   ELSE

      if pLancamento.cdrubricaagrupamento in (48294, 48343) then
        /* -- cdRubricaAgrupamento ----------------
           CIASC
           48294 - 09-0912
           48343 - 09-0950
        -----------------------------------------*/
        vvlLancamento := pLancamento.vlindice / 100;
      else
        vvlLancamento := pLancamento.VlLancamentoFinanceiro;
      end if;

   END IF;

   IF ((PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
       PKGPAG_VAR.vgVinculo.DtDesligamento >= pFolha.DtInicioMes) OR
       PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes AND
       pLancamento.FlPagaAfastDefinitivo = 'S' AND vvlLancamento > 0)
       THEN

       vInPossuiValorInformado := CASE
                                    WHEN (PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
                                          PKGPAG_VAR.vgVinculo.DtDesligamento >= pFolha.DtInicioMes) THEN
                                      NVL(pRubrica.InPossuiValorInformado, 0)
                                    -- OBRIGA PDVI CIDASC SER LANCADO
                                    -- NA EPAGHISTORICORUBRICARELVINC, PARA GERACAO DE BASE 09-0992
                                    WHEN pRubrica.CdRubricaAgrupamento IN ( 48849, 48843, 48021) THEN
                                      '1'
                                  ELSE
                                    '0'
                                  END;

       IF pLancamento.CdProcessoPagRetroativo IS NOT NULL
         AND PKGPAG_VAR.vgCCO.COUNT = 0
         AND NVL(pRubrica.InPossuiValorInformado, 0) = 2 --CCO
         THEN

         --No caso dos lancamentos financeiros relativos aos processos retroativos,
         --quando a rubrica é devida de um CCO e o servidor nao possui CCO ativa, verifica se no ano/mes do retroativo o
         --servidor possuia a relacao CCO ativa. Se pussuir, insere a rubrica na relacao do vinculo
         BEGIN
           SELECT 0 --relacao do vinculo
             INTO vInPossuiValorInformado
             FROM ERetProcessoPagRetroativo r
            INNER JOIN ecadhistcargocom cco
               ON to_char(cco.dtinicio, 'YYYYMM') <=
                  (r.nuanofinalrestituicao * 100 + r.numesfinalrestituicao)
              AND to_char(cco.dtfim, 'YYYYMM') >=
                  (r.nuanoiniciorestituicao * 100 + r.numesiniciorestituicao)
            WHERE r.cdprocessopagretroativo = pLancamento.CdProcessoPagRetroativo
              AND cco.cdvinculo = pCdVinculo;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             NULL;
         END;

       END IF;

       PGeracaoLancamentoValor(pFolha                  => pFolha,
                               pCdVinculo              => pCdVinculo,
                               pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                               pNuSufixoRubrica        => pLancamento.NuSufixoRubrica,
                               pNuParcelasProc         => pLancamento.NuParcelasProc,
                               pInPossuiValorInformado => vInPossuiValorInformado,
                               pVlLancamento           => vvlLancamento,
                               pVlIndice               => CASE WHEN pkgpag_var.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre
                                                               THEN vNuDias
                                                               ELSE pLancamento.VlIndice
                                                           END,
                               pCdLancamentoFinanceiro => pLancamento.CdLancamentoFinanceiro,
                               pCdTipoOrigemRubrica    => CASE
                                                             WHEN pLancamento.CdProcessoPagRetroativo IS NULL THEN
                                                               2
                                                             ELSE
                                                               12
                                                             END,
                               pVlIntegralIPREV         =>  pLancamento.VlIntegralIPREV,
                               pVlReal                  => pLancamento.VlLancamentoFinanceiro,
                               pCdProcessoPagRetroativo => pLancamento.CdProcessoPagRetroativo,
                               pFlValorProporcional     => pLancamento.FlValorProporcional,
                               pDtInicioDireito         => pLancamento.DtInicio,
                               pDtFimDireito            => pLancamento.DtFim);

       IF NVL(pLancamento.VlIntegralIPREV,0) > 0 THEN

         PKGPAG_VAR.vgVlIntegralIPREV := pLancamento.VlIntegralIPREV;

       END IF;

   END IF;

END;

PROCEDURE PRegistraPagamentoValorParcial(pCdLancamentoFinanceiro IN INTEGER,
                                         pNuAnoReferencia        IN INTEGER,
                                         pNuMesReferencia        IN INTEGER,                                         
                                         pValorParcela           IN NUMBER,
                                         pValorTotalLanc         IN NUMBER,
                                         pValorTotalPago         IN NUMBER,
                                         pNuParcela              IN INTEGER) IS
   
BEGIN
  
   
  
  -- Registra o pagamento 
  INSERT INTO EPagPagamentoLancamento
    (CdPagamentoLancamento,
     CdLancamentoFinanceiro,
     NuAnoReferencia,
     NuMesReferencia,
     NuParcela,
     VlParcela,
     DtUltAlteracao)
  VALUES
    (sPagPagamentoLancamento.Nextval,
     pCdLancamentoFinanceiro,
     pNuAnoReferencia,
     pNuMesReferencia,
     pNuParcela,
     pValorParcela,
     SYSDATE);

  -- Se o total já registrado é igual ao total do lançamento, encerra o lançamento  
  IF (pValorTotalPago + pValorParcela) = pValorTotalLanc AND PKGPAG_VAR.vgFolha.flCalculoDefinitivo = 'S' THEN
    
    UPDATE EPagLancamentoFinanceiro LF
       SET LF.DtFimDireito = PKGPAG_VAR.vgFolha.dtFimMes
     WHERE LF.CdLancamentoFinanceiro = pCdLancamentoFinanceiro;

  END IF;

END;
      
 /*---------------------------------------------------------------------------------*/
 -- Procedimento : PDescontoAntecipSal
 --     Objetivo : Gerar os pagamentos de lancamentos financeiros de descontos oriundos 
 --                de antecipações salariais
 /*----------------------------------------------------------------------------------*/

 PROCEDURE PDescontoAntecipSal(pFolha     IN   PKGPAG_TIPO.rFolha,
                               pCdVinculo IN INTEGER) IS
            
   vVlDesc            NUMBER(11,2);
   vNuParcelaAnterior INTEGER;  
   vVlTotalPago       NUMBER(13,2);             
                       
 BEGIN
   
   IF pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal THEN
    
    IF tabAntecipSal.COUNT > 0 THEN
        
      FOR i IN tabAntecipSal.FIRST .. tabAntecipSal.LAST LOOP
     
        SELECT NVL(SUM(PL.vlParcela),0),
               COUNT(PL.nuParcela)   
          INTO vVlTotalPago,
               vNuParcelaAnterior
          FROM EPagPagamentoLancamento PL       
         WHERE PL.CdLancamentoFinanceiro = tabAntecipSal(i).CdLancamentoFinanceiro;
              
        IF PKGPAG_VAR.vgVlBaseTotalLiquida - (tabAntecipSal(i).VlLancamentoFinanceiro - vVlTotalPago) < 0 THEN
          
          vVlDesc := PKGPAG_VAR.vgVlBaseTotalLiquida;
          
        ELSE
          
          vVlDesc := tabAntecipSal(i).VlLancamentoFinanceiro - vVlTotalPago;
          
        END IF;
        
        IF vVlDesc > 0 THEN
          
          PRegistraPagamentoValorParcial(pCdLancamentoFinanceiro => tabAntecipSal(i).CdLancamentoFinanceiro,
                                         pNuAnoReferencia        => pFolha.NuAnoReferencia,
                                         pNuMesReferencia        => pFolha.NuMesReferencia,
                                         pValorParcela           => vVlDesc,
                                         pValorTotalLanc         => tabAntecipSal(i).VlLancamentoFinanceiro,
                                         pValorTotalPago         => vVlTotalPago,
                                         pNuParcela              => vNuParcelaAnterior + 1);
                                         
          PGeracaoLancamentoValor(pFolha                  => pFolha,
                                  pCdVinculo              => pCdVinculo,
                                  pCdRubricaAgrupamento   => tabAntecipSal(i).CdRubricaAgrupamento,
                                  pNuSufixoRubrica        => tabAntecipSal(i).NuSufixoRubrica,
                                  pNuParcelasProc         => vNuParcelaAnterior,
                                  pInPossuiValorInformado => 0,
                                  pVlLancamento           => vVlDesc,
                                  pVlIndice               => NULL,
                                  pCdLancamentoFinanceiro => tabAntecipSal(i).CdLancamentoFinanceiro,
                                  pCdTipoOrigemRubrica    => 2,
                                  pDtInicioDireito        => tabAntecipSal(i).DtInicio,
                                  pDtFimDireito           => tabAntecipSal(i).DtFim);
        END IF;                          

      END LOOP;
        
    END IF;
        
   END IF;
 
 END;

PROCEDURE PPagamentoDecisaoJudicial(pFolha      IN PKGPAG_TIPO.rFolha,
                                    pCdVinculo  IN INTEGER) IS

   vVlReal NUMBER;
   vVlDecisaoJudicialCCO NUMBER;
   vPossuiValorInformado INTEGER; -- 21461/2024 - Tiago Von
   
   /*21461/2024 - Tiago Von - Funcao criada para buscar o numero de parcelas pagas, e preparar o pag da proxima parcela*/
   FUNCTION FRetornaNuParcPenhoraPagas (pFolha      IN PKGPAG_TIPO.rFolha,
                                        pCdVcinculo INTEGER) RETURN INTEGER IS
     vNuParcelasPagas INTEGER := 0;
     
     BEGIN
           BEGIN
             
            SELECT   nvl(max(ADP.NUPARCELAPAGA),0)
            INTO     vNuParcelasPagas 
            FROM     EPAGEVENTOPAGAGRUPDECPARCELAS ADP
                     INNER JOIN ECADMES M ON ADP.NUMESREFERENCIA = M.CDMES
                     INNER JOIN EPAGEVENTOPAGAGRUPDECISAO epd ON epd.cdeventopagagrupdecisao = adp.cdeventopagagrupdecisao AND 
                                                                 epd.intipovalor = 5 -- penhora
            WHERE    epd.cdvinculo = pCdVcinculo;
            
           EXCEPTION 
              WHEN no_data_found THEN
                   vNuParcelasPagas:= 0;
           END;
           
           /*IF vNuAnoRefParcela = pFolha.NuAnoReferencia AND vNuMesRefPArcela = pFolha.NuMesReferencia THEN
              vNuParcelasPagas:= 0;
           END IF;*/
           
           RETURN vNuParcelasPagas;
     END;   

BEGIN

  -- NAO PAGA DECISAO JUDICIAL EM FOLHA DE RECALCULO COMPLEMENTAR
  IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalcCompl THEN
     RETURN;
  END IF;

  FOR vPagDecisaoJudicial IN cPagDecisaoJudicial(pCdVinculo,
                                                 pFolha.NuAnoReferencia,
                                                 pFolha.NuMesReferencia)
  LOOP

    IF pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaAdiant13 AND  vPagDecisaoJudicial.Flincideadianta13penhora = 'N' THEN
      CONTINUE;
    ELSIF pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 AND  vPagDecisaoJudicial.Flincide13penhora = 'N' THEN
      CONTINUE;
    END IF;
    
    -- O DESCONTO DE COPARTICIPACAO JUDICIAL É REALIZADO NA PKGPAG_POS.PDescontoCoParticipacao
    IF PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).NuRubrica = 127 and
       PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).CdTipoRubrica = 5  THEN
        CONTINUE;
    END IF;

    vVlReal := NULL;
    vVlDecisaoJudicialCCO := NULL;

    -- Solicitacao de Sustentacao #79792
    -- 12163/2018 - RUBRICA 01-0572 NAO GERAR NOS AFASTAMENTOS
    if PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).NuRubrica = 572 and
       PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).CdTipoRubrica = 1 and
       pFolha.CdAgrupamento = 1 and
       pkgpag_var.vgcef.count > 0


       then

         if not pkgpag_geral.fpossuiabrangenciarubrica (pRubrica                  => pkgpag_var.vgRubrica(vPagDecisaoJudicial.Cdrubricaagrupamento),
                                                        pcdorgao                  => pFolha.CdOrgao,
                                                        pcdorgaoexercicio         => pkgpag_var.vgcef(1).CdOrgaoExercicio,
                                                        pCdNaturezaVinculo        => pkgpag_var.vgcef(1).CdNaturezaVinculo,
                                                        pCdRelacaoTrabalho        => pkgpag_var.vgcef(1).CdRelacaoTrabalho,
                                                        pCdRegimeTrabalho         => pkgpag_var.vgcef(1).CdRegimeTrabalho,
                                                        pCdRegimePrevidenciario   => pkgpag_var.vgcef(1).CdRegimePrevidenciario,
                                                        pCdSituacaoPrevidenciaria => pkgpag_var.vgcef(1).CdSituacaoPrevidenciaria,
                                                        pCdUnidadeOrganizacional  => pkgpag_var.vgcef(1).CdUnidadeOrganizacional,
                                                        pCdEstruturaCarreira      => pkgpag_var.vgcef(1).CdEstruturaCarreira,
                                                        pFlTipoProvimento         => pkgpag_var.vgcef(1).FlEfetivacao)  then

            return;

         end if;

    end if;


    -- SIG-9193 - RUBRICA 01-1467 NAO GERAR NOS AFASTAMENTOS
    -- Pagamento em decis?o judicial n?o gerando na folha de pagamento Folha normal
   if PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).NuRubrica = 1467 and
       PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).CdTipoRubrica = 1 and
       pFolha.CdAgrupamento = 1 and
       pkgpag_var.vgcef.count > 0 and
       pfolha.CdTipoFolha in (1, 22) and
       pkgpag_var.vgcef(1).CdSituacaoPrevidenciaria = 13 then --decisao judicial

         if not pkgpag_geral.fpossuiabrangenciarubrica (pRubrica                  => pkgpag_var.vgRubrica(vPagDecisaoJudicial.Cdrubricaagrupamento),
                                                        pcdorgao                  => pFolha.CdOrgao,
                                                        pcdorgaoexercicio         => pkgpag_var.vgcef(1).CdOrgaoExercicio,
                                                        pCdNaturezaVinculo        => pkgpag_var.vgcef(1).CdNaturezaVinculo,
                                                        pCdRelacaoTrabalho        => pkgpag_var.vgcef(1).CdRelacaoTrabalho,
                                                        pCdRegimeTrabalho         => pkgpag_var.vgcef(1).CdRegimeTrabalho,
                                                        pCdRegimePrevidenciario   => pkgpag_var.vgcef(1).CdRegimePrevidenciario,
                                                        pCdSituacaoPrevidenciaria => pkgpag_var.vgcef(1).CdSituacaoPrevidenciaria,
                                                        pCdUnidadeOrganizacional  => pkgpag_var.vgcef(1).CdUnidadeOrganizacional,
                                                        pCdEstruturaCarreira      => pkgpag_var.vgcef(1).CdEstruturaCarreira,
                                                        pFlTipoProvimento         => pkgpag_var.vgcef(1).FlEfetivacao)  then

            return;

         end if;

    end if;

    IF PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).CdTipoRubrica = 9 THEN

      -- Caso a rubrica seja de margem consignavel bruta
      -- armazena o valor do indice para ser utilizado no mneumonico QtPercDecJudMargem

      IF PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).CdModalidadeRubrica = 10 THEN

        PKGPAG_VAR.vgPercDecJudMargem := NVL(vPagDecisaoJudicial.VlIndice,100);

      END IF;

    ELSIF PKGPAG_GERAL.FRubricaPermitida(pFolha.FlPagaTodasRubricas, pFolha.CdTipoFolha, vPagDecisaoJudicial.CdRubricaAgrupamento) AND
          vPagDecisaoJudicial.FlUtilizaFormulaExistente  = 'N' THEN

       vVlReal := vPagDecisaoJudicial.VlDeterminado;

       vPagDecisaoJudicial.VlDeterminado := FValorDecisaoJudicial(pFolha              => pFolha,
                                                                  pPagDecisaoJudicial => vPagDecisaoJudicial);

       /* 21461/2024 - Tiago Von - Altera o valor do campo nuparcelaspenhora em tempo de execução para gerar a parcela com o numero correto,
                                   uma vez que, só existe um campo, e ele indica APENAS a qtd de parcela total da Dec. Jud.*/
       vPagDecisaoJudicial.Nuparcelaspenhora := FRetornaNuParcPenhoraPagas(pFolha      => pFolha, 
                                                                           pCdVcinculo => vPagDecisaoJudicial.Cdvinculo);                                                                   

       -- Implantacao SED.
       -- Caso selecionado o flag SIGRH.EPAGEVENTOPAGAGRUPDECISAO.FlPagaCCORegraInerente
       -- o pagamento da relacao de vinculo do comissionado tera direito ao mesmo valor determinado pela gratificacao de produtividade da rubrica.
       IF PKGPAG_VAR.vgCCO.COUNT > 0  AND
           FPagaCCORegraInerente(pFolha              => pFolha,
                                pPagDecisaoJudicial  => vPagDecisaoJudicial)
         THEN

         FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST
         LOOP

          -- pesquisa o valor da gratificacao de produtividade da rubrica
          FOR vVlGratFazendaria IN cVlGratFazendaria(vCdrubricaagrupamento => vPagDecisaoJudicial.Cdrubricaagrupamento,
                                                     vNuReferencia => PKGPAG_VAR.vgCCO(i).NuReferencia,
                                                     vNuNivel => PKGPAG_VAR.vgCCO(i).NuNivel,
                                                     vCdGrupoOcupacional => PKGPAG_VAR.vgCCO(i).CdGrupoOcupacional,
                                                     vCdCargoComissionado => PKGPAG_VAR.vgCCO(i).CdCargoComissionado,
                                                     vNuMesReferencia => pFolha.NuMesReferencia,
                                                     vNuAnoReferencia => pFolha.NuAnoReferencia)
          LOOP

          -- Calcula o valor da decisao judicial e insere
          vVlDecisaoJudicialCCO := vVlGratFazendaria.Nuvalor * NVL(vVlGratFazendaria.Vlindice,0) / 100;

          IF vVlDecisaoJudicialCCO IS NOT NULL THEN
               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => 2, --CCO
                                                     pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCCO(i).CdHistCargoCom,
                                                     pCdExpressaoFormCalc    => NULL,
                                                     pCdRubricaAgrupamento   => vPagDecisaoJudicial.CdRubricaAgrupamento,
                                                     pVlIntegral             => vVlDecisaoJudicialCCO,
                                                     pVlProporcional         => vVlDecisaoJudicialCCO,
                                                     pVlReal                 => vVlDecisaoJudicialCCO,
                                                     pNuSufixoRubrica        =>  vPagDecisaoJudicial.NuSufixoRubrica,
                                                     pNuParcelas             => 1,
                                                     pVlIndice               => NVL(vVlGratFazendaria.Vlindice,0),
                                                     pCdLancamentoFinanceiro => NULL,
                                                     pCdTipoOrigemRubrica    => 3,
                                                     pDtInicio               => PKGPAG_VAR.vgCCO(i).DtInicio,
                                                     pDtFim                  => PKGPAG_VAR.vgCCO(i).DtFim,
                                                     pCdProcessoPagRetroativo=> NULL);

            END IF;

          EXIT; -- Gerar apenas para uma relac?o

          END LOOP;

        END LOOP;

         -- Para relacao CEF, insere valor zero na rubrica e considera o valor da decisao judicial para calculo IPREV
         IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

             PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                   pCdVinculo              => pCdVinculo,
                                                   pCdRelacaoVinculo       => 1, --- CEF
                                                   pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(1).CdHistCargoEfetivo, --- CEF
                                                   pCdExpressaoFormCalc    => NULL,
                                                   pCdRubricaAgrupamento   => vPagDecisaoJudicial.Cdrubricaagrupamento,
                                                   pVlIntegral             => NVL(vPagDecisaoJudicial.VlDeterminado, 0),
                                                   pVlProporcional         => 0,
                                                   pVlReal                 => NVL(vPagDecisaoJudicial.VlDeterminado, 0),
                                                   pNuSufixoRubrica        => vPagDecisaoJudicial.NuSufixoRubrica,
                                                   pNuParcelas             =>  1,
                                                   pVlIndice               => NVL(vPagDecisaoJudicial.VlIndice, 0),
                                                   pCdLancamentoFinanceiro => NULL,
                                                   pCdTipoOrigemRubrica    => 3,
                                                   pCdProcessoPagRetroativo=> NULL);

         END IF;

       -- Regra geral
       ELSIF vPagDecisaoJudicial.VlDeterminado IS NOT NULL THEN

        -- 21461/2024 - Tiago Von
        IF pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaAdiant13) THEN
           vPossuiValorInformado := 0;
           vPagDecisaoJudicial.VlDeterminado := vPagDecisaoJudicial.VlDeterminado/2;
        ELSE
           vPossuiValorInformado := PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento).InPossuiValorInformado;
        END IF;
         
        PGeracaoLancamentoValor(pFolha                  => pFolha,
                                pCdVinculo              => pCdVinculo,
                                pCdRubricaAgrupamento   => vPagDecisaoJudicial.CdRubricaAgrupamento,
                                pNuSufixoRubrica        => vPagDecisaoJudicial.NuSufixoRubrica,
                                pNuParcelasProc         => CASE WHEN vPagDecisaoJudicial.Nuparcelaspenhora IS NOT NULL THEN vPagDecisaoJudicial.Nuparcelaspenhora ELSE NULL END, -- 21461/2024 - Tiago Von -- NULL,
                                pInPossuiValorInformado => vPossuiValorInformado, -- 21461/2024 - Tiago Von
                                pVlLancamento           => vPagDecisaoJudicial.VlDeterminado,
                                pVlIndice               => vPagDecisaoJudicial.VlIndice,
                                pCdTipoOrigemRubrica    => 3,
                                pVlReal                 => vVlReal);

       ELSE

           PGeracaoLancamentoFormula(pFolha               => pFolha,
                                     pCdVinculo           => pCdVinculo,
                                     pRubrica             => PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento),
                                     pTipoRegistro        => 2,
                                     pLancamento          => NULL,
                                     pLancDetJud          => vPagDecisaoJudicial);

      END IF;

     ELSIF PKGPAG_GERAL.FRubricaPermitida(pFolha.FlPagaTodasRubricas, pFolha.CdTipoFolha, vPagDecisaoJudicial.CdRubricaAgrupamento) AND
           vPagDecisaoJudicial.FlUtilizaFormulaExistente  = 'S' THEN

       PGeracaoLancamentoFormula(pFolha               => pFolha,
                                 pCdVinculo           => pCdVinculo,
                                 pRubrica             => PKGPAG_VAR.vgRubrica(vPagDecisaoJudicial.CdRubricaAgrupamento),
                                 pTipoRegistro        => 2,
                                 pLancamento          => NULL,
                                 pLancDetJud          => vPagDecisaoJudicial);

    else
      null;
    END IF;

  END LOOP;

END;

PROCEDURE PExcluiHistoricoLancamento(pFolha     IN PKGPAG_TIPO.rFolha,
                                     pCdVinculo IN INTEGER) IS

vCont INTEGER;

BEGIN

   DELETE
     FROM EpagPagamentoLancamento PL
    WHERE PL.NuAnoReferencia = pFolha.NuAnoReferencia AND
          PL.NuMesReferencia = pFolha.NuMesReferencia AND
          PL.CdLancamentoFinanceiro IN
          (SELECT LF.CdLancamentoFinanceiro
             FROM EPagLancamentoFinanceiro LF
            INNER JOIN EPagRubricaAgrupamento RA
              ON RA.Cdrubricaagrupamento = LF.Cdrubricaagrupamento             
            WHERE LF.CdVinculo = pCdVinculo AND
                  ((LF.InPeriodicidade = PKGPAG_TIPO.cnQ AND
                  LF.FlObservaLimRetroativoErario = PKGPAG_TIPO.cnN) OR
                  (LF.DtInicioDireito = pFolha.DtInicioMes AND
                   LF.FlAcertoAuto13Sal = PKGPAG_TIPO.cnS) OR
                  (LF.InPeriodicidade = PKGPAG_TIPO.cnP AND
                   RA.FlRubAntecipSal = 'S'))
           --AUDITORIA: nao excluir parcela de meses que ja foram empenhados
           AND NOT EXISTS
              (SELECT 1
                 FROM epagcapahistrubricavinculo capa
                INNER JOIN epaghistoricorubricavinculo rv
                   ON rv.cdvinculo = capa.cdvinculo
                  AND rv.cdfolhapagamento = capa.cdfolhapagamento
                INNER JOIN epagfolhapagamento fp
                   ON rv.cdfolhapagamento = fp.cdfolhapagamento
                WHERE rv.cdvinculo = pCdVinculo
                  AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS
                  AND fp.flfolhafechada = PKGPAG_TIPO.cnS
                  AND fp.nuanoreferencia = pFolha.nuanoreferencia
                  AND fp.numesreferencia = pFolha.numesreferencia
                  AND rv.cdlancamentofinanceiro = LF.cdlancamentofinanceiro));

   UPDATE EPagLancamentoFinanceiro LF
      SET LF.DtFimDireito = NULL,
          LF.DtUltAlteracao = systimestamp
     WHERE LF.CdVinculo = pCdVinculo AND
           LF.InPeriodicidade = PKGPAG_TIPO.cnQ AND
           LF.DtFimDireito = pFolha.DtFimMes AND
           LF.FlObservaLimRetroativoErario = PKGPAG_TIPO.cnN AND
           LF.CdLancamentoFinanceiro IN
            (select cdlancamentofinanceiro
               from (select fin.cdprocessopagretroativo CdProcessoPagRetroativo,
                            fin.vllancamentofinanceiro VlRestituir, --Valor restituir
                            sum(pag.vlparcela) vlPago,
                            fin.cdlancamentofinanceiro cdlancamentofinanceiro,
                            hrv.cdrubricaagrupamento
                       from epaghistoricorubricavinculo hrv -- CONTRA-CHEQUE
                      inner join epagfolhapagamento fp
                         on fp.cdfolhapagamento = hrv.cdfolhapagamento
                        and fp.flfolhafechada = 'N'
                      inner join epaglancamentofinanceiro fin
                         on hrv.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro
                       left join epagpagamentolancamento pag
                         on pag.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro
                      where hrv.cdvinculo = pCdVinculo
                        and (hrv.cdlancamentofinanceiro is not null and
                            hrv.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro)
                      group by fin.cdprocessopagretroativo,
                               fin.vllancamentofinanceiro,
                               hrv.cdrubricaagrupamento,
                               fin.cdlancamentofinanceiro) A
              where a.vlrestituir > a.vlpago);

   IF pFolha.NuMesReferencia = 12 THEN

      BEGIN

        vCont :=0;

        SELECT 1
          INTO vCont
          FROM EPagLancamentoFinanceiro LF
         WHERE LF.CdVinculo = pCdVinculo
           AND LF.DtInicioDireito = pFolha.DtInicioMes
           AND LF.FlAcertoAuto13Sal = PKGPAG_TIPO.cnS
           AND ROWNUM < 2;

        IF SQL%ROWCOUNT > 0
          THEN

           DELETE
             FROM EPagLancamentoFinanceiro LF
            WHERE LF.CdVinculo = pCdVinculo
              AND LF.DtInicioDireito = pFolha.DtInicioMes
              AND LF.FlAcertoAuto13Sal = PKGPAG_TIPO.cnS;
        END IF;

        EXCEPTION
          WHEN NO_DATA_FOUND
            THEN
              vCont := 0;

      END;

   END IF;

END;

PROCEDURE PGeraDescontoLancTesouro(pFolha     IN PKGPAG_TIPO.rFolha,
                                   pCdVinculo IN INTEGER) IS

  vVlPagamento          NUMBER(13,2);

  vCdRubricaAgrupamento INTEGER;

BEGIN

  SELECT SUM(VlPagamento)
    INTO vVlPagamento
    FROM EPagHistoricoRubricaVinculo HRV
   INNER JOIN EPagRubricaAgrupamento RA
      ON RA.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
   INNER JOIN EPagRubrica R
      ON R.CdRubrica = RA.CdRubrica
   WHERE HRV.CdVinculo = pCdVinculo AND
         HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
         R.CdTipoRubrica = 3;

  IF vVlPagamento > 0 THEN

    vCdRubricaAgrupamento := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                          7,
                                                          9999);
    IF vCdRubricaAgrupamento > 0 THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                            pCdVinculo              => pCdVinculo,
                                            pCdExpressaoFormCalc    => NULL,
                                            pCdRubricaAgrupamento   => vCdRubricaAgrupamento,
                                            pNuSufixoRubrica        => 1,
                                            pVlPagamento            => vVlPagamento,
                                            pNuParcelas             => NULL,
                                            pVlIndice               => NULL,
                                            pCdTipoOrigemRubrica    => 1);

    END IF;

  END IF;

END;

/*---------------------------------------------------------------------------------*/
-- Procedimento : PAtualizaHistoricoLancamento
--     Objetivo :
--
/*----------------------------------------------------------------------------------*/

  PROCEDURE PAtualizaHistoricoLancamento(pFolha     IN PKGPAG_TIPO.rFolha,
                                         pCdVinculo IN INTEGER) IS
    vnuParcela INTEGER := 0;
  BEGIN

    FOR vPagLanc IN (SELECT sPagPagamentoLancamento.Nextval,
                            HRV.CdLancamentoFinanceiro,
                            pFolha.NuAnoReferencia          NuAnoReferencia,
                            pFolha.NuMesReferencia          NuMesReferencia,
                            HRV.QtParcelas,
                            LF.NuParcelas,
                            HRV.VlPagamento,
                            systimestamp
                       FROM EPagHistoricoRubricaVinculo HRV
                      INNER JOIN EPagLancamentoFinanceiro LF
                         ON HRV.CdLancamentoFinanceiro =
                            LF.CdLancamentoFinanceiro
                      WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                        AND HRV.CdVinculo = pCdVinculo
                        AND LF.InPeriodicidade = PKGPAG_TIPO.cnQ)
    --(LF.NuParcelas IS NOT NULL OR LF.NuParcelas > 0) AND
    --LF.FlObservaLimRetroativoErario = PKGPAG_TIPO.cnN)
     LOOP

      BEGIN
        PExcluirPagamentoParcela(pCdLancamentoFinanceiro => vPagLanc.CdLancamentoFinanceiro,
                                 pNuAnoReferencia        => pFolha.NuAnoReferencia,
                                 pNuMesreferencia        => pFolha.NuMesReferencia);

        SELECT COUNT(nuparcela)
          INTO vnuParcela
          FROM epagpagamentolancamento pp
         WHERE pp.cdlancamentofinanceiro = vPagLanc.CdLancamentoFinanceiro
           AND (pp.nuanoreferencia < vPagLanc.nuanoreferencia or
               (pp.nuanoreferencia = vPagLanc.nuanoreferencia and
               pp.numesreferencia <= vPagLanc.numesreferencia));

        vnuParcela := NVL(vnuParcela,0) +1;

        PRegistarPagamentoParcela(pCdLancamentoFinanceiro => vPagLanc.CdLancamentoFinanceiro,
                                  pNuAnoReferencia        => pFolha.NuAnoReferencia,
                                  pNuMesreferencia        => pFolha.NuMesReferencia,
                                  pNuParcela              => vnuParcela,
                                  pValorParcela           => vPagLanc.VlPagamento,
                                  pDataUltimaAlteracao    => SYSTIMESTAMP);

        IF NVL(vPagLanc.NuParcelas, 0) > 0 AND
           vnuParcela >= vPagLanc.NuParcelas THEN

          UPDATE EPagLancamentoFinanceiro LF
             SET LF.DtFimDireito = pFolha.DtFimMes
           WHERE LF.CdLancamentoFinanceiro = vPagLanc.CdLancamentoFinanceiro;

        END IF;

      EXCEPTION

        WHEN OTHERS THEN

          PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  PKGPAG_VAR.vCdHistParamCalc,
                                  PKGPAG_VAR.vCdPessoa,
                                  'Erro inserir pagamento de parcela de lançamento financeiro: ' ||
                                  vPagLanc.VlPagamento,
                                  PKGPAG_VAR.vgCdVinculo);

      END;

    END LOOP;

  END;

/*---------------------------------------------------------------------------------*/
-- Procedimento : PLancamentosFinanceiros
--     Objetivo : Gerar os pagamentos de lancamentos financeiros de acordo com as
--               regras estabelecidas pela parametrizacao da rubrica
/*----------------------------------------------------------------------------------*/

PROCEDURE PLancamentosFinanceiros(pFolha            IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo        IN INTEGER,
                                  pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                                  pDtCalculo        IN DATE,
                                  pLstRubTrib       IN PKGPAG_TIPO.tLista,
                                  pFlTributacao     IN CHAR,
                                  pQtdeNaoLancados OUT INTEGER) IS

   vTabLancamento      PKGPAG_TIPO.tLancFinanceiro;

   FUNCTION FObterLimiteMaxDiasAfastMes(pDtCalculo IN DATE) RETURN INTEGER IS
     vQtdDiasMes INTEGER;
     vMaxDiasAfastMes INTEGER;
   BEGIN
     vQtdDiasMes := last_day(pDtCalculo) - trunc((pDtCalculo),'month') + 1;
     IF vQtdDiasMes = 31 THEN
       vMaxDiasAfastMes := 31;
     ELSE
       vMaxDiasAfastMes := 30;
     END IF;
     RETURN vMaxDiasAfastMes;
   END;

  /*--------------------------------------------------------------------------------*/
  --  Funcao que verifica se o vinculo esteve afastado no mes pelo menos um dia                                                          */
  /*--------------------------------------------------------------------------------*/
   FUNCTION FAfastadoPorAcidente RETURN BOOLEAN IS

   vCont INTEGER;

   BEGIN

      SELECT COUNT(*)
        INTO vCont
        FROM Eafaafastamentovinculo AV
       INNER JOIN Eafamotivoafasttemporario MAT
          ON AV.Cdmotivoafasttemporario = MAT.Cdmotivoafasttemporario
       INNER JOIN Eafahistmotivoafasttemp HMAT
          ON MAT.Cdmotivoafasttemporario = HMAT.Cdmotivoafasttemporario
       WHERE AV.cdVinculo = pcdVinculo AND
             HMAT.FlAcidenteTrabalho = PKGPAG_TIPO.cnS AND
             AV.DtInicio <= pFolha.DtFimMes AND
            (AV.DtFim >= pFolha.DtInicioMes OR AV.DtFim IS NULL) AND
             HMAT.Dtiniciovigencia <= pdtCalculo AND
            (HMAT.Dtfimvigencia >= pdtCalculo OR HMAT.Dtfimvigencia IS NULL);

      IF vCont > 0 THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

   EXCEPTION

     WHEN OTHERS THEN

       RETURN  FALSE;

   END;

  /*--------------------------------------------------------------------------------*/
   -- Procedure: PProcessaLancamento
   --            Processa os lancamentos financeiros para os quais deve ser
   --            aplicado formula de calculo.

   /*--------------------------------------------------------------------------------*/

   PROCEDURE PProcessaLancamento (pLancamento IN cLancParcela%ROWTYPE,
                                  pTpCalculo  IN CHAR) IS

     bPagaLancFinanceiro  BOOLEAN;
     vTpCalculo CHAR(1);

     vRubrica             PKGPAG_TIPO.rRubrica;

   BEGIN

     bPagaLancFinanceiro := TRUE;

     vRubrica := PKGPAG_VAR.vgRubrica(pLancamento.CdRubricaAgrupamento);

     /* Verifica se a rubrica esta bloqueada para lancamentos financeiros
        Apenas as rubricas do tipo 1 e 5 sao bloqueadas                   */

    /* IF NOT (vRubrica.FlBloqLancFinanc = 'S' AND
             vRubrica.CdTipoRubrica IN (1,5)) THEN*/

      /* Verifica se a rubrica e permitida apenas para servidores que
         estejam ou estiveram afastados no mes por afastamento caracterizado
         como acidente de trabalho */

      IF vRubrica.FlPermiteAfastAcidente = 'S' THEN

        IF NOT FAfastadoPorAcidente THEN

          bPagaLancFinanceiro := FALSE;

        END IF;

      END IF;

      IF bPagaLancFinanceiro THEN

        if pLancamento.cdrubricaagrupamento in (48294, 48343) then
          /* -- cdRubricaAgrupamento ----------------
             CIASC
             48294 - 09-0912
             48343 - 09-0950
          -----------------------------------------*/
          vTpCalculo := 'V';
        else
          vTpCalculo := pTpCalculo;
        end if;

        IF vTpCalculo = 'F' THEN
          PGeracaoLancamentoFormula(pFolha,
                                    pCdVinculo,
                                    vRubrica,
                                    1,
                                    pLancamento,
                                    NULL);
        ELSE
          PGeracaoLancamentoNaoFormula(pFolha,
                                       pCdVinculo,
                                       vRubrica,
                                       1,
                                       pLancamento,
                                       NULL);
        END IF;
      END IF;

     --END IF;

   EXCEPTION

     WHEN NO_DATA_FOUND THEN -- Nao processa rubricas de outro agrupamento

       NULL;

   END;

  PROCEDURE PTratarLancamentos (pTabLancamento IN PKGPAG_TIPO.tLancFinanceiro,
                                pTpCalculo     IN CHAR) IS

      vLancamento      cLancParcela%ROWTYPE;
      vMaxDiasAfastMes INTEGER;
      vRubrica         PKGPAG_TIPO.rRubrica;
      vNuInd           INTEGER;    
      vFlAntecipSal    CHAR(1);   

   BEGIN

      IF pTabLancamento.FIRST IS NULL THEN
         RETURN;
      END IF;

      vNuInd := 0;

      FOR l IN pTabLancamento.FIRST .. pTabLancamento.LAST LOOP

        vLancamento := pTabLancamento (l);
 
        vRubrica := PKGPAG_GERAL.FObterInfoRubrica(vLancamento.CdRubricaAgrupamento);

        BEGIN
          
          vFlAntecipSal := PKGPAG_VAR.vgRubrica(vLancamento.CdRubricaAgrupamento).flRubAntecipSal;
          
        EXCEPTION
          
          WHEN NO_DATA_FOUND THEN
            
            vFlAntecipSal := 'N'; -- Não estourar erro em rubrica inexistente
            
        END;
        
        IF vFlAntecipSal = 'S' THEN
          
          vNuInd := vNuInd + 1;
          
          tabAntecipSal(vNuInd) := vLancamento;
          
        ELSE  
       
           IF pFlTributacao = 'S' THEN -- Somente Rubricas de Tributacao
            
              IF NOT pLstRubTrib.EXISTS (vLancamento.CdRubricaAgrupamento) THEN

                 pQtdeNaoLancados := pQtdeNaoLancados + 1;
                 
                 CONTINUE;
              END IF;

           ELSIF pFlTributacao = 'N' THEN    

              IF pLstRubTrib.EXISTS (vLancamento.CdRubricaAgrupamento) THEN
                 
                 pQtdeNaoLancados := pQtdeNaoLancados + 1;
                  
                 CONTINUE;
              END IF;
           
           END IF;
                  
           vRubrica := PKGPAG_GERAL.FObterInfoRubrica(vLancamento.CdRubricaAgrupamento);
           vMaxDiasAfastMes:= FObterLimiteMaxDiasAfastMes(pDtCalculo);

           --
           -- Atribuir a variavel o codigo das rubricas lancadas em financeiro
           -- e que devem ser salvos na tabela EPAGEVENTOVINCULO
           -- Rubricas que a condicao de pagamento da vantagem e um funcao da media
           --

           IF PKGPAG_VAR.vgListaOutraRubCondPag.EXISTS(vLancamento.CdRubricaAgrupamento)
             THEN

              PKGPAG_VAR.vgCdRubricaHoraPlantao := vLancamento.CdRubricaAgrupamento;

           ELSE

              PKGPAG_VAR.vgCdRubricaHoraPlantao := 0;

           END IF;

           -- #73492 9578/2016 - FOLHA - BLOQUEIO DA RUBRICA 01-0332
           -- esse bloqueio era pra ter sido temporario... bloco comentado pelo chamado SIG-2965 14319/2019
           /*BEGIN
           IF pFolha.CdOrgao IN (41, 42) AND vLancamento.CdRubricaAgrupamento IN (37561)
               AND pFolha.NuMesReferencia = 12 AND pFolha.CdTipoFolhaPagamento = 2  AND  pFolha.CdTipoCalculo = 1
               /*AND pFolha.FlCalculoDefinitivo = 'S' *THEN
               CONTINUE;
           END IF;
           EXCEPTION
             WHEN OTHERS THEN
               NULL;
           END;*/

           IF FGeraLancamento(pRubrica                 => vRubrica,
                              pCdProcessoPagRetroativo => vLancamento.CdProcessoPagRetroativo,
                              pCdLancamentoFinanceiro  => vLancamento.CdLancamentoFinanceiro,
                              pDtCalculo               => pDtCalculo) THEN

             IF NOT (pFolha.FlIgnoraInclusaoFutura = 'S' AND vLancamento.DtInclusao >= (pDtCalculo+1)) THEN

               --PARAMETRO:

               IF pFolha.CdAgrupamento IN (1, 7, 133, 134, 176) AND
                  pFolha.CdTipoFolha NOT IN(PKGPAG_TIPO.cnTpFolhaInstPensao)  AND
                 -- Os valores informados devem ser pagos para servidores
                 -- afastados temporariamente sem remuneracao
                  ((PKGPAG_VAR.vgAfastTempNaoRemun.count > 0 AND
                   PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual >= vMaxDiasAfastMes AND
                   vLancamento.FlPagaAfastTempSemRemun = PKGPAG_TIPO.cnN) OR
                 -- Os valores informados ou calculados devem ser pagos
                 -- mesmo apos afastamento definitivo nao remunerado
                  (PKGPAG_VAR.vgAfastDefinitivo.count > 0 AND
                   PKGPAG_VAR.vgNuDiasAfastDefinitivo >= vMaxDiasAfastMes AND
                   vLancamento.FLPAGAAFASTDEFINITIVO = PKGPAG_TIPO.cnN))THEN

                 -- se nao estiver preenchido, nao gera a rubrica.
                 CONTINUE;

               ELSIF (PKGPAG_VAR.vMotAfast.InPagaLancamento = PKGPAG_TIPO.cnN OR
                   vLancamento.FlPagaAfastTempSemRemun = PKGPAG_TIPO.cnS) THEN
                 -- Caso seja uma rubrica do tipo 2 e o lancamento seja relativo a retroativos,
                 -- altera o valor da variavel global vgProcessaBloqueio

                 IF vLancamento.CdProcessoPagRetroativo IS NOT NULL AND
                    vRubrica.CdTipoRubrica = 2 THEN

                  PKGPAG_VAR.bProcessaBloqueio := TRUE;

                 END IF;

                 IF PKGPAG_GERAL.FRubricaPermitida(pFolha.FlPagaTodasRubricas, pFolha.CdTipoFolha, vLancamento.CdRubricaAgrupamento) THEN

                   -- Se nao tem o tipo de folha de pagamento definido ou se o tipo e igual ao da folha que esta sendo calculada

                   IF vLancamento.CdTipoFolhaPagamento IS NULL OR vLancamento.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento THEN

                     PProcessaLancamento(vLancamento, pTpCalculo);

                     PKGPAG_VAR.vgLancFinanceiro(vLancamento.CdLancamentoFinanceiro) := vLancamento;

                     IF PKGPAG_VAR.vgCdRubricaHoraPlantao > 0 AND pFolha.flCalculoDefinitivo = 'S' THEN
                       -- Salva os valores de hora plantao pagos na tabela epageventovinculo
                       -- para o calculo da media hora plantao
                       PKGPAG_POS.PAtualizaEventoVinculo(pCdVinculo    => pCdVinculo,
                                               pFolha        => pFolha,
                                               pCdTipoEvento => 2,
                                               pCdChave => vLancamento.CdLancamentoFinanceiro  ); -- indice para media hora plantao
                     END IF;
                   END IF;

                 END IF;

               else
                 null;
               END IF;

             END IF;

           END IF;
        
        END IF;

      END LOOP;

   END;

BEGIN
  
  pQtdeNaoLancados := 0;
   
  IF pFlTributacao = 'N' THEN
  
     IF (pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaNormal,
                                PKGPAG_TIPO.cnTpFolhaBolsista,
                                PKGPAG_TIPO.cnTpFolhaResidente,
                                PKGPAG_TIPO.cnTpFolhaPesquisador,
                                PKGPAG_TIPO.cnTpFolhaConvenio,
                                PKGPAG_TIPO.cnTpFolhaFunebre,
                                PKGPAG_TIPO.cnTpFolhaServAfast,
                                PKGPAG_TIPO.cnTpFolhaInstPensao,
                                PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                                pkgpag_tipo.cnTpFolhaRescisaoPesquisador,
                                PKGPAG_TIPO.cnTpFolhaOutras,
                                PKGPAG_TIPO.cnTpFolhaBEP) AND
        pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal) THEN

       PExcluiHistoricoLancamento(pFolha,
                                  pCdVinculo);

     END IF;

     /* POG:
       Quando fazemos uma importação na linha que deveria ir índice e valor igual a zero, está indo como nulo.
       Dessa forma, a base de cálculo nao calcula e nenhum lançamento aparece nos contracheques.
       Rubrica 09-0992 Patronal Associação, exemplo de matrs. 1572-5; 481-2; 40457-8.
     */
     IF pFolha.CdAgrupamento = 4 THEN

        UPDATE epaglancamentofinanceiro LF
        SET   LF.VLLANCAMENTOFINANCEIRO = 0
        WHERE LF.cdvinculo = pCdVinculo
        AND   LF.CDRUBRICAAGRUPAMENTO = 49205
        AND   LF.VLLANCAMENTOFINANCEIRO IS NULL;

     END IF;

  END IF;
  --

  OPEN cLancParcela(pCdVinculo,
                    pFolha.DtInicioMes,
                    pFolha.DtFimMes);

  FETCH cLancParcela BULK COLLECT INTO vTabLancamento;

  CLOSE cLancParcela;

  PTratarLancamentos ( pTabLancamento => vTabLancamento, pTpCalculo => 'V');

  --

  OPEN cLancPeriodo(pCdVinculo,
                    pFolha.DtInicioMes,
                    pFolha.DtFimMes);

  FETCH cLancPeriodo BULK COLLECT INTO vTabLancamento;

  CLOSE cLancPeriodo;

  PTratarLancamentos ( pTabLancamento => vTabLancamento, pTpCalculo => 'V');
  --
  OPEN cLancParcelaFC(pCdVinculo,
                      pFolha.DtInicioMes,
                      pFolha.DtFimMes);

  FETCH cLancParcelaFC BULK COLLECT INTO vTabLancamento;

  CLOSE cLancParcelaFC;

  PTratarLancamentos ( pTabLancamento => vTabLancamento, pTpCalculo => 'F');

  --

  OPEN cLancPeriodoFC(pCdVinculo,
                      pFolha.DtInicioMes,
                      pFolha.DtFimMes);

  FETCH cLancPeriodoFC BULK COLLECT INTO vTabLancamento;

  CLOSE cLancPeriodoFC;
  
  PTratarLancamentos ( pTabLancamento => vTabLancamento, pTpCalculo => 'F');

END;

PROCEDURE PRegistarPagamentoParcela(pCdLancamentoFinanceiro IN INTEGER,
                                    pNuAnoReferencia        IN INTEGER,
                                    pNuMesReferencia        IN INTEGER,
                                    pNuParcela              IN INTEGER,
                                    pValorParcela           IN NUMBER,
                                    pDataUltimaAlteracao    IN TIMESTAMP DEFAULT SYSTIMESTAMP) IS
BEGIN

  INSERT INTO EPagPagamentoLancamento
    (CdPagamentoLancamento,
     CdLancamentoFinanceiro,
     NuAnoReferencia,
     NuMesReferencia,
     NuParcela,
     VlParcela,
     DtUltAlteracao)
  VALUES
    (sPagPagamentoLancamento.Nextval,
     pCdLancamentoFinanceiro,
     pNuAnoReferencia,
     pNuMesReferencia,
     pNuParcela,
     pValorParcela,
     pDataUltimaAlteracao);

  -- EM CASO DE AJUSTE DE PARCELAS, CASO O NUMERO DE PARCELA COMPUTADAS SEJA
  -- IGUAL AO NUMERO DE PARCELAS DEFINIDAS, ENCERRA O LF
  IF PKGPAG_VAR.vgFolha.NuAnoReferencia > pNuAnoReferencia OR
     (PKGPAG_VAR.vgFolha.NuAnoReferencia = pNuAnoReferencia AND
     PKGPAG_VAR.vgFolha.NuMesReferencia > pNuMesReferencia) THEN

    FOR vPagLanc IN (SELECT HRV.QtParcelas,
                            LF.NuParcelas,
                            LAST_DAY(fp.dtcalculo) dtfimMes
                       FROM EPagHistoricoRubricaVinculo HRV
                      INNER JOIN EPagLancamentoFinanceiro LF
                         ON HRV.CdLancamentoFinanceiro =
                            LF.CdLancamentoFinanceiro
                      INNER JOIN epagFolhaPagamento fp
                         ON fp.cdfolhapagamento = HRV.cdfolhapagamento
                        AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS
                      WHERE fp.nuanoreferencia = pNuAnoReferencia
                        AND fp.numesreferencia = pNuMesReferencia
                        AND LF.CdLancamentoFinanceiro =
                            pCdLancamentoFinanceiro
                        AND (LF.NuParcelas IS NOT NULL OR LF.NuParcelas > 0)
                        AND LF.FlObservaLimRetroativoErario =
                            PKGPAG_TIPO.cnN) LOOP

        IF NVL(vPagLanc.QtParcelas,0) >= NVL(vPagLanc.NuParcelas,0) THEN

          UPDATE EPagLancamentoFinanceiro LF
             SET LF.DtFimDireito = vPagLanc.dtfimMes
           WHERE LF.CdLancamentoFinanceiro =
                 pCdLancamentoFinanceiro;

        END IF;
      END LOOP;

     END IF;

    END;

PROCEDURE PExcluirPagamentoParcela(pCdLancamentoFinanceiro  IN INTEGER,
                                   pNuAnoReferencia         IN INTEGER,
                                   pNuMesReferencia         IN INTEGER) IS
BEGIN

  DELETE FROM EPAGPAGAMENTOLANCAMENTO
   WHERE CDLANCAMENTOFINANCEIRO = pCdLancamentoFinanceiro
     AND NUANOREFERENCIA = pNuAnoReferencia
     AND NUMESREFERENCIA = pNuMesReferencia
        --AUDITORIA: nao excluir parcela de meses que ja foram empenhados
     AND CdLancamentoFinanceiro IN
         (SELECT LF.CdLancamentoFinanceiro
            FROM EPagLancamentoFinanceiro LF
           WHERE LF.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
             AND NOT EXISTS
           (SELECT 1
                    FROM epaghistoricorubricavinculo rv
                   INNER JOIN epagfolhapagamento fp
                      ON rv.cdfolhapagamento = fp.cdfolhapagamento
                   WHERE rv.cdvinculo = lf.CdVinculo
                     AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS
                     AND fp.flfolhafechada = PKGPAG_TIPO.cnS
                     AND fp.nuanoreferencia = pnuanoreferencia
                     AND fp.numesreferencia = pnumesreferencia
                     AND rv.cdlancamentofinanceiro = LF.cdlancamentofinanceiro));

END;

FUNCTION FPossuiLancamentoFinanceiro(pCdRubricaAgrupamento IN INTEGER) RETURN BOOLEAN IS
BEGIN
  RETURN PKGPAG_VAR.vListaRubricas.EXISTS(pCdRubricaAgrupamento);
END;

-- 21461/2024 - Tiago Von
procedure PRegistraPgtPenhora(pFolha      IN PKGPAG_TIPO.rFolha,
                              pCdVinculo  IN INTEGER) IS
     
vNuParcelasPagas INTEGER := 0;
vMesRef          INTEGER;

CURSOR penhoras IS 
       select 
               pgd.cdeventopagagrupdecisao,
               phr.qtparcelas AS NuParcelaMes,
               phr.vlPagamento AS ValorPagoMes,
               pgd.vlmontantepenhora as TotalPenhora,
               pgd.nuparcelaspenhora as TotalParcelasPenhora,
               phr.cdrubricaagrupamento as cdrubricaagrupamento,
               phr.nusufixorubrica AS nusufixorubrica,
               case WHEN pgd.nuanofimdireito IS NULL THEN 'A' ELSE 'I' END StatusPenhora,
               (SELECT SUM(pcl.vlpago)
                FROM   ePagEventoPagaGrupDecParcelas pcl
                WHERE  pcl.cdeventopagagrupdecisao = pgd.cdeventopagagrupdecisao
                AND    pcl.numesreferencia < vMesRef) ValorTotalPago
          from ePagHistoricoRubricaVinculo phr
               inner join ePagEventoPagaGrupDecisao pgd
                  on pgd.cdrubricaagrupamento = phr.cdrubricaagrupamento
                 AND pgd.nusufixorubrica = phr.nusufixorubrica
                 and pgd.cdvinculo = phr.cdvinculo
         where phr.cdvinculo = pCdVinculo
           and phr.cdfolhapagamento = pFolha.CdFolhaPagamento
           AND pgd.flanulado = 'N'
           and pgd.intipovalor = 5 --Rubrica definida como Penhora.
           AND ((pgd.NuAnoInicioDireito < pFolha.NuAnoReferencia OR
                 (pgd.NuAnoInicioDireito = pFolha.NuAnoReferencia AND
                 pgd.NuMesInicioDireito <= pFolha.NuMesReferencia)) AND
                 (pgd.NuAnoFimDireito > pFolha.NuAnoReferencia OR
                 (pgd.NuAnoFimDireito = pFolha.NuAnoReferencia AND
                 pgd.NuMesFimDireito >= pFolha.NuMesReferencia) OR
                 pgd.NuAnoFimDireito IS NULL));

                                          
BEGIN

     IF pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaAdiant13) THEN
        vMesRef := 13;
     ELSE
        vMesRef := pFolha.numesreferencia;
     END IF;                  
     
     FOR pen IN penhoras LOOP
       
         IF pen.StatusPenhora = 'A' THEN

             delete from ePagEventoPagaGrupDecParcelas pc
                   where pc.cdeventopagagrupdecisao = pen.Cdeventopagagrupdecisao
                     and pc.nuanoreferencia = pFolha.nuanoreferencia
                     and pc.numesreferencia = vMesRef;
             --RETURNING pc.vlpagamento INTO vNuParcela; 
             
             SELECT nvl(max(p.nuparcelapaga),0)
             INTO   vNuParcelasPagas
             FROM   ePagEventoPagaGrupDecParcelas p
             where  p.cdeventopagagrupdecisao = pen.Cdeventopagagrupdecisao;
                   
             IF vNuParcelasPagas = 0 THEN
                vNuParcelasPagas := 1;
             ELSE 
                vNuParcelasPagas := vNuParcelasPagas + 1;
             END IF;
                  
             IF pen.ValorPagoMes > pen.TotalPenhora THEN
                       
                pen.ValorPagoMes := pen.TotalPenhora;
                          
             END IF;
                       
             IF pen.ValorPagoMes + pen.ValorTotalPago > pen.TotalPenhora AND vNuParcelasPagas > 1 THEN
                            
                pen.ValorPagoMes := pen.TotalPenhora - pen.ValorTotalPago;
                       
             END if;
                       
             IF pen.ValorPagoMes > 0  THEN
               -- Ajusta valor da parcela caso o valor calculado seja superior ao do montante
               UPDATE epaghistoricorubricavinculo fol
               SET    fol.vlpagamento          = pen.ValorPagoMes,
                      fol.qtparcelas           = vNuParcelasPagas
               WHERE  fol.cdfolhapagamento     = pFolha.CdFolhaPagamento
               AND    fol.cdvinculo            = pCdVinculo
               AND    fol.cdrubricaagrupamento = pen.cdrubricaagrupamento
               AND    fol.nusufixorubrica      = pen.nusufixorubrica;
             END IF;

             IF pFolha.FlCalculoDefinitivo = 'S' AND
                ((pen.ValorPagoMes > 0 and pen.ValorPagoMes <= pen.TotalPenhora) or 
                 (vNuParcelasPagas > 0 and vNuParcelasPagas <= nvl(pen.TotalParcelasPenhora,0))) then

               insert into ePagEventoPagaGrupDecParcelas
                           (cdeventopagagrupdecparcelas ,
                            cdeventopagagrupdecisao,
                            nuanoreferencia,
                            numesreferencia,
                            nuparcelapaga,
                            vlpago,
                            dtultalteracao) values
                           (Spageventopagagrupdecparcelas.Nextval,
                            pen.Cdeventopagagrupdecisao,
                            pFolha.nuanoreferencia,
                            vMesRef,
                            vNuParcelasPagas, --vNuParcelaMes,
                            pen.ValorPagoMes,
                            systimestamp);
             END IF;
             
         END IF;

         IF pFolha.FlCalculoDefinitivo = 'S' AND nvl(pen.ValorTotalPago,0) + pen.ValorPagoMes >= pen.TotalPenhora THEN
                 
            update ePagEventoPagaGrupDecisao
            set    numesfimdireito = pFolha.numesreferencia,
                   nuanofimdireito = pFolha.nuanoreferencia,
                   dtultalteracao = systimestamp
            where  cdeventopagagrupdecisao = pen.Cdeventopagagrupdecisao;           
                 
         END IF;       
         
     END LOOP;         
END;    

END PKGPAG_LF;
/
