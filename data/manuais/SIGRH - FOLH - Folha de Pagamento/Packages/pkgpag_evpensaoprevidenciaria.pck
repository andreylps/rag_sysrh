create or replace package pkgpag_evpensaoprevidenciaria is

  -- Author  : RVFURTADO
  -- Created : 05/07/2017 18:03:19
  -- Purpose :

  /*

     Tratamento de Eventos da Folha de Pagamento

     Relacao de Vinculo Pensao Previdenciaria

  */

  PROCEDURE PProcessaEventosPensaoPrev(pVinculo      IN PKGPAG_TIPO.rVinculo,
                                pFolha               IN PKGPAG_TIPO.rFolha,
                                pEvento              IN PKGPAG_TIPO.rEvento,
                                pRubrica             IN PKGPAG_TIPO.tRubrica,
                                pFormExpr            IN PKGPAG_TIPO.tFormulaCalculo,
                                pPensaoPrev          IN PKGPAG_TIPO.tPensaoPrev,
                                pdtCalculo           IN DATE);

end pkgpag_evpensaoprevidenciaria;
/
create or replace package body pkgpag_evpensaoprevidenciaria is

PROCEDURE P104RemuneracaoFixaPensaoPrev(pFolha      IN PKGPAG_TIPO.rFolha,
                                        pPensaoPrev IN PKGPAG_TIPO.rPensaoPrev,
                                        pRubrica    IN PKGPAG_TIPO.rRubrica,
                                        pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

   vCdExpressaoFormCalc   INTEGER;

BEGIN

   -- Se nao gera rubrica, retorna
   IF NOT PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN
     RETURN;
   END IF;

   -- Verifica abrangencia da pensao
   IF NOT pkgpag_pensaoprevidenciaria.fVerificaAbrangenciaPensaoPrev(pCdVinculoPensionista => pPensaoPrev.CdVinculo,
                                                                 pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                                 pDataReferencia => pFolha.DtCalculo) THEN
     RETURN;
   END IF;

   -- Verifica abrangencia da rubrica
   /*IF NOT PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                      pRubrica                  => pRubrica,
                                      pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                                      pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                      pCdNaturezaVinculo        => pPensaoPrev.CdNaturezaVinculo,
                                      pCdUnidadeOrganizacional  => pPensaoPrev.CdUnidadeOrganizacional
    )  THEN
      RETURN;
    END IF;*/

     -- 1) Busca a formula associada

     vCdExpressaoFormCalc :=

         PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                pFormExpr                 => pFormExpr,
                                pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                pCdRelacaoVinculo         => pPensaoPrev.CdRelacaoVinculo,
                               -- pCdEstruturaCarreira      => pPensaoPrev.CdEstruturaCarreira,
                                pCdUnidadeOrganizacional  => pPensaoPrev.CdUnidadeOrganizacional);

     IF vCdExpressaoFormCalc > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoRelacao (
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => pPensaoPrev.CdVinculo,
                              pCdRelacaoVinculo     => pPensaoPrev.CdRelacaoVinculo,
                              pCdHistRelacaoVinculo => pPensaoPrev.CdHistPensaoPrevidenciaria,
                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => NULL,
                              pVlProporcional       => NULL,
                              pNuSufixoRubrica      => 1,
                              pNuParcelas           => 1,
                              pVlIndice             => NULL,
                              pCdTipoOrigemRubrica  => 7,
                              pDtInicio             => pPensaoPrev.DtInicio,
                              pDtFim                => pPensaoPrev.DtFim,
                              pVlIndiceReal         => NULL,
                              pCdTipoIndice         => null
                              );

     END IF;

END;

PROCEDURE P052Decimo13FimPensao (pFolha      IN PKGPAG_TIPO.rFolha,
                                 pPensaoPrev IN PKGPAG_TIPO.rPensaoPrev,
                                 pRubrica    IN PKGPAG_TIPO.rRubrica,
                                 pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

   vCdExpressaoFormCalc   INTEGER;

BEGIN

   -- Se nao gera rubrica, retorna
   IF NOT PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN
     RETURN;
   END IF;

   -- 1) Busca a formula associada

     vCdExpressaoFormCalc :=

         PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                pFormExpr                 => pFormExpr,
                                pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                pCdRelacaoVinculo         => pPensaoPrev.CdRelacaoVinculo,
                               -- pCdEstruturaCarreira      => pPensaoPrev.CdEstruturaCarreira,
                                pCdUnidadeOrganizacional  => pPensaoPrev.CdUnidadeOrganizacional);

     IF vCdExpressaoFormCalc > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoRelacao (
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => pPensaoPrev.CdVinculo,
                              pCdRelacaoVinculo     => pPensaoPrev.CdRelacaoVinculo,
                              pCdHistRelacaoVinculo => pPensaoPrev.CdHistPensaoPrevidenciaria,
                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => NULL,
                              pVlProporcional       => NULL,
                              pNuSufixoRubrica      => 1,
                              pNuParcelas           => 1,
                              pVlIndice             => NULL,
                              pCdTipoOrigemRubrica  => 7,
                              pDtInicio             => pPensaoPrev.DtInicio,
                              pDtFim                => pPensaoPrev.DtFim,
                              pVlIndiceReal         => NULL,
                              pCdTipoIndice         => null
                              );

     END IF;

END;

PROCEDURE PProcessaEventosPensaoPrev (
                               pVinculo              IN PKGPAG_TIPO.rVinculo,
                               pFolha                IN PKGPAG_TIPO.rFolha,
                               pEvento               IN PKGPAG_TIPO.rEvento,
                               pRubrica              IN PKGPAG_TIPO.tRubrica,
                               pFormExpr             IN PKGPAG_TIPO.tFormulaCalculo,
                               pPensaoPrev           IN PKGPAG_TIPO.tPensaoPrev,
                               pdtCalculo            IN DATE) IS

  bEventoGerado         BOOLEAN;

BEGIN

  FOR j IN pPensaoPrev.FIRST .. pPensaoPrev.LAST
  LOOP

    bEventoGerado := FALSE;

    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

    --
    -- Pagamento de REMUNERACAO FIXA DE PENSAO PREVIDENCIARIA
    --

    CASE

      WHEN pEvento.CdTipoEventoPagamento in (52,47) AND
           ((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND
             pFolha.DtFimMes)
             OR (PKGPAG_VAR.vMotAfast.InTipoAfastamento = 'D' AND
                 PKGPAG_VAR.vMotAfast.DtInclusao > pkgpag_var.vgFolha.DtCalculoAnt AND
                 to_char(PKGPAG_VAR.vMotAfast.DtInicio,'mmyyyy') =
                 to_char(pkgpag_var.vgFolha.DtCalculoAnt,'mmyyyy'))) THEN

          bEventoGerado := TRUE;

          P052Decimo13FimPensao(pFolha => pFolha,
                                pRubrica     => pRubrica(pEvento.CdRubricaAgrupamento),
                                pPensaoPrev  => pPensaoPrev(j),
                                pFormExpr    => pFormExpr);

      WHEN pEvento.CdTipoEventoPagamento = 104 THEN


          if pFolha.CdOrgao = 33 and
       pkgpag_var.vgVinculo.bPossuiObito then
             return;
          end if;

          bEventoGerado := TRUE;

          P104RemuneracaoFixaPensaoPrev(pFolha => pFolha,
                             pRubrica     => pRubrica(pEvento.CdRubricaAgrupamento),
                             pPensaoPrev  => pPensaoPrev(j),
                             pFormExpr    => pFormExpr);

      -- Senao
      ELSE

        NULL;

    END CASE;

    IF bEventoGerado THEN

      PKGPAG_GERAL.PLogTrace ('EVPENSAOPREV - Evento Gerado ' || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - PENSAOPREV ' || j, PKGPAG_VAR.vgTmInicio);

    ELSE

      PKGPAG_GERAL.PLogTrace ('EVPENSAOPREV - Evento Não Gerado '  || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - PENSAOPREV ' || j, PKGPAG_VAR.vgTmInicio);

    END IF;

  END LOOP;

END;

end pkgpag_evpensaoprevidenciaria;
/
