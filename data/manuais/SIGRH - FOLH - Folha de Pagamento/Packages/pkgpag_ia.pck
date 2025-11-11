CREATE OR REPLACE PACKAGE PKGPAG_IA IS

/*---------------------------------------------------------------------------------------------*/
--  Procedimento : PProcessaIncorporacaoAtivo
--      Objetivo : Processar as incorporacoes de ativo nas relacoes de vinculo
--
--   Regras implementadas baseadas na forma de recebimento:
--
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PProcessaIncorporacaoAtivo(pFolha      IN PKGPAG_TIPO.rFolha,
                                     pCdVinculo  IN INTEGER,
                                     pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo,
                                     pDtCalculo  IN DATE);

PROCEDURE PAtualizaValorIncorporacao(pCdVinculo              IN INTEGER,
                                     pNuAno                  IN INTEGER,
                                     pNuMes                  IN INTEGER,
                                     pCdIncorporacaoAtivo    IN INTEGER,
                                     pFlAtualizacaoConstante IN CHAR,
                                     pFlVigenciaPagamento    IN CHAR,
                                     pVlMinIncorporacao      IN NUMBER,
                                     pVlFormula              IN NUMBER);

END PKGPAG_IA;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_IA IS

/*
 TYPE rValor IS RECORD
    (vlIntegral  NUMBER(13,2),
     vlIndice    NUMBER(13,4));*/

/*---------------------------------------------------------------------------------------------*/
--   Procedimento : PValorCEF
--       Objetivo : Gera os registros de pagamento das incorporacoes de ativo para a relacao de
--                  vinculo de cargo efetivo
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PIncorporacaoCEF(pFolha                   IN PKGPAG_TIPO.rFolha,
                           pCdVinculo               IN INTEGER,
                           pFormExpr                IN PKGPAG_TIPO.tFormulaCalculo,
                           pRubrica                 IN PKGPAG_TIPO.rRubrica,
                           pCdIncorporacao          IN EbpcIncorporacaoAtivo.CdIncorporacaoAtivo%TYPE,
                           pVlMinimoRecebimento     IN EbpcIncorporacaoAtivo.VlMinimoRecebimento%TYPE,
                           pFlAtualizacaoConstante  IN EbpcIncorporacaoAtivo.FlAtualizacaoConstante%TYPE,
                           pFlVigenciaPagamento     IN EbpcIncorporacaoAtivo.FlVigenciaPagamento%TYPE,
                           pVlIncorporacao          IN EbpcIncorporacaoAtivo.VlFixo%TYPE,
                           pVlPercProp              IN EbpcIncorporacaoAtivo.VlPercProporcionalidade%TYPE,
                           pCdBaseIncorporacaoAtivo IN EbpcIncorporacaoAtivo.CdBaseIncorporacaoAtivo%TYPE,
                           pNuSufixo                IN EbpcIncorporacaoAtivo.NuSufixo%TYPE,
                           pDtCalculo               IN DATE) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

    FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdOrgaoExercicio         => PKGPAG_VAR.vgCEF(i).CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => PKGPAG_VAR.vgCEF(i).CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => PKGPAG_VAR.vgCEF(i).CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => PKGPAG_VAR.vgCEF(i).CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => PKGPAG_VAR.vgCEF(i).CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgCEF(i).CdSituacaoPrevidenciaria,
                                   pCdEstruturaCarreira      => PKGPAG_VAR.vgCEF(i).CdEstruturaCarreira,
                                   pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional,
                                   pFlTipoProvimento         => PKGPAG_VAR.vgCEF(i).FlEfetivacao
                                  ) THEN

         IF pVlIncorporacao IS NOT NULL AND pCdBaseIncorporacaoAtivo = 6 THEN

           vProporcional :=

              PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                     pRubrica           => pRubrica ,
                                                     pValorIntegral     => pVlIncorporacao,
                                                     pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                     pCEF               => PKGPAG_VAR.vgCEF(i),
                                                     pDtCalculo         => pDtCalculo);

          vCdExpressaoFormCalc := null;

          -- EPAGRI usar formula de calculo para valor fixo.

          IF pFolha.CdAgrupamento = 5

            THEN
              vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                          pFormExpr                 => pFormExpr,
                          pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                          pCdRelacaoVinculo         => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                          pCdEstruturaCarreira      => PKGPAG_VAR.vgCEF(i).CdEstruturaCarreira,
                          pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional);

             IF vCdExpressaoFormCalc > 0 THEN

                PKGPAG_GERAL.PInsereLancamentoRelacao(
                           pCdFolhaPagamento       => pFolha.CdFolhaPagamento ,
                           pCdVinculo              => pCdVinculo,
                           pCdRelacaoVinculo       => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                           pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(i).CdHistCargoEfetivo,
                           pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                           pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                           pVlIntegral             => NULL,
                           pVlProporcional         => NULL,
                           pNuSufixoRubrica        => pNuSufixo,
                           pNuParcelas             => NULL,
                           pVlIndice               => pVlPercProp,
                           pCdIncorporacaoAtivo    => pCdIncorporacao,
                           pVlMinRecebIncorp       => pVlMinimoRecebimento,
                           pFlAtualizacaoConstante => pFlAtualizacaoConstante,
                           pFlVigenciaPagamento    => pFlVigenciaPagamento,
                           pCdTipoOrigemRubrica    => 4,
                           pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                           pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim);

             END IF;

            ELSE

             PKGPAG_GERAL.PInsereLancamentoRelacao(
                           pCdFolhaPagamento     => pFolha.CdFolhaPagamento ,
                           pCdVinculo            => pCdVinculo,
                           pCdRelacaoVinculo     => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                           pCdHistRelacaoVinculo => PKGPAG_VAR.vgCEF(i).CdHistCargoEfetivo,
                           pCdExpressaoFormCalc  => NULL,
                           pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                           pVlIntegral           => vProporcional.vlIntegral, --pVlIncorporacao,
                           pVlProporcional       => vProporcional.vlProporcional,
                           pVlReal               => vProporcional.vlReal,
                           pNuSufixoRubrica      => pNuSufixo,
                           pNuParcelas           => NULL,
                           pVlIndice             => vProporcional.vlIndice,
                           pCdTipoOrigemRubrica  => 4,
                           pDtInicio             => PKGPAG_VAR.vgCEF(i).DtInicio,
                           pDtFim                => PKGPAG_VAR.vgCEF(i).DtFim);

           END IF;

         ELSIF pVlPercProp IS NOT NULL THEN

           vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                          pFormExpr                 => pFormExpr,
                          pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                          pCdRelacaoVinculo         => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                          pCdEstruturaCarreira      => PKGPAG_VAR.vgCEF(i).CdEstruturaCarreira,
                          pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional);

          IF vCdExpressaoFormCalc > 0 THEN

             PKGPAG_GERAL.PInsereLancamentoRelacao(
                           pCdFolhaPagamento       => pFolha.CdFolhaPagamento ,
                           pCdVinculo              => pCdVinculo,
                           pCdRelacaoVinculo       => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                           pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(i).CdHistCargoEfetivo,
                           pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                           pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                           pVlIntegral             => NULL,
                           pVlProporcional         => NULL,
                           pNuSufixoRubrica        => pNuSufixo,
                           pNuParcelas             => NULL,
                           pVlIndice               => pVlPercProp,
                           pCdIncorporacaoAtivo    => pCdIncorporacao,
                           pVlMinRecebIncorp       => pVlMinimoRecebimento,
                           pFlAtualizacaoConstante => pFlAtualizacaoConstante,
                           pFlVigenciaPagamento    => pFlVigenciaPagamento,
                           pCdTipoOrigemRubrica    => 4,
                           pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                           pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim);

           END IF;

         else
           null;
         END IF;

       END IF;

    END LOOP;

  END IF;

END;

/*---------------------------------------------------------------------------------------------*/
--   Procedimento : PValorAPO
--       Objetivo : Gera os registros de pagamento das vantagens pecuniarias para a relacao de
--                  vinculo de aposentado com paridade
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PIncorporacaoAPO(pFolha                   IN PKGPAG_TIPO.rFolha,
                           pCdVinculo               IN INTEGER,
                           pFormExpr                IN PKGPAG_TIPO.tFormulaCalculo,
                           pRubrica                 IN PKGPAG_TIPO.rRubrica,
                           pCdIncorporacao          IN EbpcIncorporacaoAtivo.CdIncorporacaoAtivo%TYPE,
                           pVlMinimoRecebimento     IN EbpcIncorporacaoAtivo.VlMinimoRecebimento%TYPE,
                           pFlAtualizacaoConstante  IN EbpcIncorporacaoAtivo.FlAtualizacaoConstante%TYPE,
                           pFlVigenciaPagamento     IN EbpcIncorporacaoAtivo.FlVigenciaPagamento%TYPE,
                           pVlIncorporacao          IN EbpcIncorporacaoAtivo.VlFixo%TYPE,
                           pVlPercProp              IN EbpcIncorporacaoAtivo.VlPercProporcionalidade%TYPE,
                           pNuSufixo                IN EbpcIncorporacaoAtivo.NuSufixo%TYPE,
                           pCdBaseIncorporacaoAtivo IN EbpcIncorporacaoAtivo.CdBaseIncorporacaoAtivo%TYPE,
                           pDtCalculo               IN DATE) IS

  vProporcional            PKGPAG_TIPO.rValorPagamento;

  vCdExpressaoFormCalc     INTEGER;

BEGIN

  IF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

    FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdOrgaoExercicio         => PKGPAG_VAR.vgAPO(i).CdOrgaoExercicio,
                                   pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgAPO(i).CdSituacaoPrevidenciaria,
                                   pCdEstruturaCarreira      => PKGPAG_VAR.vgAPO(i).CdEstruturaCarreira,
                                   pFlAPOOrigemCCO           => PKGPAG_VAR.vgAPO(i).FlOrigemCCO) THEN

        IF pVlIncorporacao IS NOT NULL AND pCdBaseIncorporacaoAtivo = 6 THEN

          vProporcional.vlIntegral := pVlIncorporacao;

          vProporcional.vlProporcional := pVlIncorporacao;

          IF pCdBaseIncorporacaoAtivo <> 7 THEN

            IF PKGPAG_VAR.vgAPO(i).CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao THEN

              vProporcional :=

                PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                       pRubrica           => pRubrica ,
                                                       pAPO               => PKGPAG_VAR.vgAPO(i),
                                                       pValorIntegral     => pVlIncorporacao);

           END IF;

            PKGPAG_GERAL.PInsereLancamentoRelacao(
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => pCdVinculo,
                              pCdRelacaoVinculo     => PKGPAG_VAR.vgAPO(i).CdRelacaoVinculo,
                              pCdHistRelacaoVinculo => PKGPAG_VAR.vgAPO(i).CdHistRelVinc,
                              pCdExpressaoFormCalc  => NULL,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => vProporcional.vlIntegral,--vIntegral.vlIntegral,
                              pVlProporcional       => vProporcional.vlProporcional,
                              pVlReal               => vProporcional.vlReal,
                              pNuSufixoRubrica      => pNuSufixo,
                              pNuParcelas           => NULL,
                              pVlIndice             => vProporcional.vlIndice,
                              pCdTipoOrigemRubrica  => 4,
                              pDtInicio             => PKGPAG_VAR.vgAPO(i).DtInicio,
                              pDtFim                => PKGPAG_VAR.vgAPO(i).DtFim);

          END IF;

        ELSIF pVlPercProp IS NOT NULL THEN

            vCdExpressaoFormCalc :=

                PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                 pFormExpr                 => pFormExpr,
                                 pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                 pCdRelacaoVinculo         => 4);

            IF vCdExpressaoFormCalc > 0 THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(
                             pCdFolhaPagamento       => pFolha.CdFolhaPagamento ,
                             pCdVinculo              => pCdVinculo,
                             pCdRelacaoVinculo       => 4,
                             pCdHistRelacaoVinculo   => PKGPAG_VAR.vgAPO(i).CdHistRelVinc,
                             pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                             pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                             pVlIntegral             => NULL,
                             pVlProporcional         => NULL,
                             pNuSufixoRubrica        => pNuSufixo,
                             pNuParcelas             => NULL,
                             pVlIndice               => pVlPercProp,
                             pCdIncorporacaoAtivo    => pCdIncorporacao,
                             pVlMinRecebIncorp       => pVlMinimoRecebimento,
                             pFlAtualizacaoConstante => pFlAtualizacaoConstante,
                             pFlVigenciaPagamento    => pFlVigenciaPagamento,
                             pCdTipoOrigemRubrica    => 4,
                             pDtInicio               => PKGPAG_VAR.vgAPO(i).DtInicio,
                             pDtFim                  => PKGPAG_VAR.vgAPO(i).DtFim);

            END IF;

          else
            null;
          END IF;

      END IF;

    END LOOP;

  END IF;

END;

/*---------------------------------------------------------------------------------------------*/
--   Procedimento : PValorFUC
--       Objetivo : Gera os registros de pagamento das vantagens pecuniarias para a relacao de
--                  vinculo de aposentado com paridade
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PIncorporacaoFUC(pFolha                   IN PKGPAG_TIPO.rFolha,
                           pCdVinculo               IN INTEGER,
                           pFormExpr                IN PKGPAG_TIPO.tFormulaCalculo,
                           pRubrica                 IN PKGPAG_TIPO.rRubrica,
                           pCdIncorporacao          IN EbpcIncorporacaoAtivo.CdIncorporacaoAtivo%TYPE,
                           pVlMinimoRecebimento     IN EbpcIncorporacaoAtivo.VlMinimoRecebimento%TYPE,
                           pFlAtualizacaoConstante  IN EbpcIncorporacaoAtivo.FlAtualizacaoConstante%TYPE,
                           pFlVigenciaPagamento     IN EbpcIncorporacaoAtivo.FlVigenciaPagamento%TYPE,
                           pVlIncorporacao          IN EbpcIncorporacaoAtivo.VlFixo%TYPE,
                           pVlPercProp              IN EbpcIncorporacaoAtivo.VlPercProporcionalidade%TYPE,
                           pCdBaseIncorporacaoAtivo IN EbpcIncorporacaoAtivo.CdBaseIncorporacaoAtivo%TYPE,
                           pNuSufixo                IN EbpcIncorporacaoAtivo.NuSufixo%TYPE,
                           pDtCalculo               IN DATE) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF PKGPAG_VAR.vgFUC.COUNT > 0 THEN

    FOR i IN PKGPAG_VAR.vgFUC.FIRST .. PKGPAG_VAR.vgFUC.LAST
    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                  pRubrica          => pRubrica,
                                  pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                                  pCdOrgaoExercicio => PKGPAG_VAR.vgFUC(i).CdOrgaoExercicio,
                                  pCdFuncaoChefia   => PKGPAG_VAR.vgFUC(i).CdFuncaoChefia,
                                  pFlTipoProvimento => PKGPAG_VAR.vgFUC(i).FlEfetivacao) THEN

        IF pVlIncorporacao IS NOT NULL AND pCdBaseIncorporacaoAtivo = 6 THEN

          vProporcional :=

              PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                     pRubrica           => pRubrica ,
                                                     pFUC               => PKGPAG_VAR.vgFUC(i),
                                                     pValorIntegral     => pVlIncorporacao);

          PKGPAG_GERAL.PInsereLancamentoRelacao(
                          pCdFolhaPagamento     => pFolha.CdFolhaPagamento ,
                          pCdVinculo            => pCdVinculo,
                          pCdRelacaoVinculo     => 3,
                          pCdHistRelacaoVinculo => PKGPAG_VAR.vgFUC(i).CdHistFuncaoChefia,
                          pCdExpressaoFormCalc  => NULL,
                          pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                          pVlIntegral           => vProporcional.vlIntegral, --pVlIntegral           => pVlIncorporacao,
                          pVlProporcional       => vProporcional.vlProporcional,
                          pVlReal               => vProporcional.vlReal,
                          pNuSufixoRubrica      => pNuSufixo,
                          pNuParcelas           => NULL,
                          pVlIndice             => vProporcional.vlIndice,
                          pCdTipoOrigemRubrica  => 4,
                          pDtInicio             => PKGPAG_VAR.vgFUC(i).DtInicio,
                          pDtFim                => PKGPAG_VAR.vgFUC(i).DtFim);

        ELSIF pVlPercProp IS NOT NULL THEN

           vCdExpressaoFormCalc :=

              PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                pFormExpr                 => pFormExpr,
                                pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                pCdRelacaoVinculo         => 3);

          IF vCdExpressaoFormCalc > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoRelacao(
                           pCdFolhaPagamento       => pFolha.CdFolhaPagamento ,
                           pCdVinculo              => pCdVinculo,
                           pCdRelacaoVinculo       => 3,
                           pCdHistRelacaoVinculo   => PKGPAG_VAR.vgFUC(i).CdHistFuncaoChefia,
                           pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                           pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                           pVlIntegral             => NULL,
                           pVlProporcional         => NULL,
                           pNuSufixoRubrica        => pNuSufixo,
                           pNuParcelas             => NULL,
                           pVlIndice               => pVlPercProp,
                           pCdIncorporacaoAtivo    => pCdIncorporacao,
                           pVlMinRecebIncorp       => pVlMinimoRecebimento,
                           pFlAtualizacaoConstante => pFlAtualizacaoConstante,
                           pFlVigenciaPagamento    => pFlVigenciaPagamento,
                           pCdTipoOrigemRubrica    => 4,
                           pDtInicio             => PKGPAG_VAR.vgFUC(i).DtInicio,
                           pDtFim                => PKGPAG_VAR.vgFUC(i).DtFim);

          END IF;

        else
          null;
        END IF;

      END IF;

    END LOOP;

  END IF;

END;

/*---------------------------------------------------------------------------------------------*/
--   Procedimento : PValorCCO
--       Objetivo : Gera os registros de pagamento das vantagens pecuniarias para a relacao de
--                  vinculo de cargo comissionado
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PIncorporacaoCCO(pFolha                   IN PKGPAG_TIPO.rFolha,
                           pCdVinculo               IN INTEGER,
                           pFormExpr                IN PKGPAG_TIPO.tFormulaCalculo,
                           pRubrica                 IN PKGPAG_TIPO.rRubrica,
                           pCdIncorporacao          IN EbpcIncorporacaoAtivo.CdIncorporacaoAtivo%TYPE,
                           pVlMinimoRecebimento     IN EbpcIncorporacaoAtivo.VlMinimoRecebimento%TYPE,
                           pFlAtualizacaoConstante  IN EbpcIncorporacaoAtivo.FlAtualizacaoConstante%TYPE,
                           pFlVigenciaPagamento     IN EbpcIncorporacaoAtivo.FlVigenciaPagamento%TYPE,
                           pVlIncorporacao          IN EbpcIncorporacaoAtivo.VlFixo%TYPE,
                           pVlPercProp              IN EbpcIncorporacaoAtivo.VlPercProporcionalidade%TYPE,
                           pCdBaseIncorporacaoAtivo IN EbpcIncorporacaoAtivo.Cdbaseincorporacaoativo%TYPE,
                           pNuSufixo                IN EbpcIncorporacaoAtivo.NuSufixo%TYPE,
                           pDtCalculo               IN DATE) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF PKGPAG_VAR.vgCCO.COUNT > 0 THEN

    FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST

    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdOrgaoExercicio         => PKGPAG_VAR.vgCCO(i).CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => PKGPAG_VAR.vgCCO(i).CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => PKGPAG_VAR.vgCCO(i).CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => PKGPAG_VAR.vgCCO(i).CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => PKGPAG_VAR.vgCCO(i).CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgCCO(i).CdSituacaoPrevidenciaria,
                                   pCdCargoComissionado      => PKGPAG_VAR.vgCCO(i).CdCargoComissionado,
                                   pCdGrupoOcupacional       => PKGPAG_VAR.vgCCO(i).CdGrupoOcupacional,
                                   pCdOpcaoRemuneracao       => PKGPAG_VAR.vgCCO(i).CdOpcaoRemuneracao,
                                   pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCCO(i).CdUnidadeOrganizacional,
                                   pFlTipoProvimento         => PKGPAG_VAR.vgCCO(i).FlTipoProvimento
                                   ) THEN

        IF pVlIncorporacao IS NOT NULL AND pCdBaseIncorporacaoAtivo = 6 THEN

          vProporcional :=

              PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                     pRubrica           => pRubrica,
                                                     pCCO               => PKGPAG_VAR.vgCCO(i),
                                                     pValorIntegral     => pVlIncorporacao,
                                                     pDtCalculo         => pDtCalculo);

          PKGPAG_GERAL.PInsereLancamentoRelacao(
                           pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                           pCdVinculo            => pCdVinculo,
                           pCdRelacaoVinculo     => 2,
                           pCdHistRelacaoVinculo => PKGPAG_VAR.vgCCO(i).CdHistCargoCom,
                           pCdExpressaoFormCalc  => NULL,
                           pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                           pVlIntegral           => vProporcional.VlIntegral, --pVlIncorporacao,
                           pVlProporcional       => vProporcional.vlProporcional,
                           pVlReal               => vProporcional.vlReal,
                           pNuSufixoRubrica      => pNuSufixo,
                           pNuParcelas           => NULL,
                           pVlIndice             => vProporcional.vlIndice,
                           pCdTipoOrigemRubrica  => 4,
                           pDtInicio             => PKGPAG_VAR.vgCCO(i).DtInicio,
                           pDtFim                => PKGPAG_VAR.vgCCO(i).DtFim);

        ELSIF pVlPercProp IS NOT NULL THEN

          vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                          pFormExpr                 => pFormExpr,
                          pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                          pCdRelacaoVinculo         => 2,
                          pCdCargoComissionado      => PKGPAG_VAR.vgCCO(i).CdCargoComissionado,
                          pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCCO(i).CdUnidadeOrganizacional);

          IF vCdExpressaoFormCalc > 0 THEN

            IF PKGPAG_VAR.vgCCO(i).CdOpcaoRemuneracao = 3 AND
               pCdBaseIncorporacaoAtivo = 7 AND
               PKGPAG_VAR.vgCEF.Count > 0 THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(
                             pCdFolhaPagamento       => pFolha.CdFolhaPagamento ,
                             pCdVinculo              => pCdVinculo,
                             pCdRelacaoVinculo       => 1,
                             pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(1).CdHistCargoEfetivo,
                             pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                             pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                             pVlIntegral             => NULL,
                             pVlProporcional         => NULL,
                             pNuSufixoRubrica        => pNuSufixo,
                             pNuParcelas             => NULL,
                             pVlIndice               => pVlPercProp,
                             pCdIncorporacaoAtivo    => pCdIncorporacao,
                             pVlMinRecebIncorp       => pVlMinimoRecebimento,
                             pFlAtualizacaoConstante => pFlAtualizacaoConstante,
                             pFlVigenciaPagamento    => pFlVigenciaPagamento,
                             pCdTipoOrigemRubrica    => 4,
                             pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                             pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim);

             END IF;

             PKGPAG_GERAL.PInsereLancamentoRelacao(
                              pCdFolhaPagamento       => pFolha.CdFolhaPagamento ,
                              pCdVinculo              => pCdVinculo,
                              pCdRelacaoVinculo       => 2,
                              pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCCO(i).CdHistCargoCom,
                              pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                              pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral             => NULL,
                              pVlProporcional         => NULL,
                              pNuSufixoRubrica        => pNuSufixo,
                              pNuParcelas             => NULL,
                              pVlIndice               => pVlPercProp,
                              pCdIncorporacaoAtivo    => pCdIncorporacao,
                              pVlMinRecebIncorp       => pVlMinimoRecebimento,
                              pFlAtualizacaoConstante => pFlAtualizacaoConstante,
                              pFlVigenciaPagamento    => pFlVigenciaPagamento,
                              pCdTipoOrigemRubrica    => 4,
                              pDtInicio               => PKGPAG_VAR.vgCCO(i).DtInicio,
                              pDtFim                  => PKGPAG_VAR.vgCCO(i).DtFim);

          END IF;

        else
          null;
        END IF;

     END IF;

   END LOOP;

 END IF;

END;

PROCEDURE PIncorporacaoPNP(pFolha                   IN PKGPAG_TIPO.rFolha,
                           pCdVinculo               IN INTEGER,
                           pFormExpr                IN PKGPAG_TIPO.tFormulaCalculo,
                           pRubrica                 IN PKGPAG_TIPO.rRubrica,
                           pCdIncorporacao          IN EbpcIncorporacaoAtivo.CdIncorporacaoAtivo%TYPE,
                           pVlMinimoRecebimento     IN EbpcIncorporacaoAtivo.VlMinimoRecebimento%TYPE,
                           pFlAtualizacaoConstante  IN EbpcIncorporacaoAtivo.FlAtualizacaoConstante%TYPE,
                           pFlVigenciaPagamento     IN EbpcIncorporacaoAtivo.FlVigenciaPagamento%TYPE,
                           pVlIncorporacao          IN EbpcIncorporacaoAtivo.VlFixo%TYPE,
                           pVlPercProp              IN EbpcIncorporacaoAtivo.VlPercProporcionalidade%TYPE,
                           pNuSufixo                IN EbpcIncorporacaoAtivo.NuSufixo%TYPE,
                           pCdBaseIncorporacaoAtivo IN EbpcIncorporacaoAtivo.CdBaseIncorporacaoAtivo%TYPE,
                           pDtCalculo               IN DATE) IS

  vProporcional            PKGPAG_TIPO.rValorPagamento;

  vCdExpressaoFormCalc     INTEGER;

BEGIN

  IF PKGPAG_VAR.vgPensaoNaoPrev.COUNT > 0 THEN

    FOR i IN PKGPAG_VAR.vgPensaoNaoPrev.FIRST .. PKGPAG_VAR.vgPensaoNaoPrev.LAST
    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgPensaoNaoPrev(i).CdSituacaoPrevidenciaria) THEN

        IF pVlIncorporacao IS NOT NULL AND pCdBaseIncorporacaoAtivo = 6 THEN

          vProporcional.vlIntegral := pVlIncorporacao;

          vProporcional.vlProporcional := pVlIncorporacao;

          IF pCdBaseIncorporacaoAtivo <> 7 THEN

              vProporcional :=

                PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                       pRubrica           => pRubrica ,
                                                       pPNP               => PKGPAG_VAR.vgPensaoNaoPrev(i),
                                                       pValorIntegral     => pVlIncorporacao);

            PKGPAG_GERAL.PInsereLancamentoRelacao(
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => pCdVinculo,
                              pCdRelacaoVinculo     => 7,
                              pCdHistRelacaoVinculo => PKGPAG_VAR.vgPensaoNaoPrev(i).CdHistPensaoNaoPrev,
                              pCdExpressaoFormCalc  => NULL,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => vProporcional.vlIntegral,--vIntegral.vlIntegral,
                              pVlProporcional       => vProporcional.vlProporcional,
                              pVlReal               => vProporcional.vlReal,
                              pNuSufixoRubrica      => pNuSufixo,
                              pNuParcelas           => NULL,
                              pVlIndice             => vProporcional.vlIndice,
                              pCdTipoOrigemRubrica  => 4,
                              pDtInicio             => PKGPAG_VAR.vgAPO(i).DtInicio,
                              pDtFim                => PKGPAG_VAR.vgAPO(i).DtFim);

          END IF;

        ELSIF pVlPercProp IS NOT NULL THEN

            vCdExpressaoFormCalc :=

                PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                 pFormExpr                 => pFormExpr,
                                 pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                 pCdRelacaoVinculo         => 7);

            IF vCdExpressaoFormCalc > 0 THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(
                             pCdFolhaPagamento       => pFolha.CdFolhaPagamento ,
                             pCdVinculo              => pCdVinculo,
                             pCdRelacaoVinculo       => 7,
                             pCdHistRelacaoVinculo   => PKGPAG_VAR.vgPensaoNaoPrev(i).CdHistPensaoNaoPrev,
                             pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                             pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                             pVlIntegral             => NULL,
                             pVlProporcional         => NULL,
                             pNuSufixoRubrica        => pNuSufixo,
                             pNuParcelas             => 1,
                             pVlIndice               => pVlPercProp,
                             pCdIncorporacaoAtivo    => pCdIncorporacao,
                             pVlMinRecebIncorp       => pVlMinimoRecebimento,
                             pFlAtualizacaoConstante => pFlAtualizacaoConstante,
                             pFlVigenciaPagamento    => pFlVigenciaPagamento,
                             pCdTipoOrigemRubrica    => 4,
                             pDtInicio               => PKGPAG_VAR.vgPensaoNaoPrev(i).DtInicio,
                             pDtFim                  => PKGPAG_VAR.vgPensaoNaoPrev(i).DtFim);

            END IF;

          else
            null;
          END IF;

      END IF;

    END LOOP;

  END IF;

END;

PROCEDURE PAtualizaValorIncorporacao(pCdVinculo              IN INTEGER,
                                     pNuAno                  IN INTEGER,
                                     pNuMes                  IN INTEGER,
                                     pCdIncorporacaoAtivo    IN INTEGER,
                                     pFlAtualizacaoConstante IN CHAR,
                                     pFlVigenciaPagamento    IN CHAR,
                                     pVlMinIncorporacao      IN NUMBER,
                                     pVlFormula              IN NUMBER) IS

 --v_rows_processed INTEGER;

  PROCEDURE PExcluiVigencia IS

  BEGIN

    DELETE
      FROM EBpcIncorporacaoAtivo IA
     WHERE IA.CdVinculo = pCdVinculo AND
           IA.FlVigenciaPagamento = 'S' AND
           ((IA.NuMesInicio > pNuMes AND IA.NuAnoInicio = pNuAno) OR
             IA.NuAnoInicio > pNuAno);

    UPDATE EBpcIncorporacaoAtivo IA
       SET IA.Numesfim = NULL,
           IA.NuAnoFim = NULL
     WHERE CdIncorporacaoAtivo = pCdIncorporacaoAtivo;

  END;

BEGIN

  IF pFlAtualizacaoConstante = 'N' THEN

    pExcluiVigencia;

  ELSE

    IF pVlFormula > pVlMinIncorporacao THEN

      BEGIN

        UPDATE EBpcIncorporacaoAtivo IA
           SET IA.VlMinimoRecebimento = pVlFormula
         WHERE IA.CdVinculo = pCdVinculo AND
               ((IA.NuMesInicio > pNuMes AND IA.NuAnoInicio = pNuAno) OR
               IA.NuAnoInicio > pNuAno);

        IF SQL%ROWCOUNT = 0 THEN

           UPDATE EBpcIncorporacaoAtivo IA
              SET IA.Numesfim = pNuMes,
                  IA.NuAnoFim = pNuAno
            WHERE CdIncorporacaoAtivo = pCdIncorporacaoAtivo;

           BEGIN

           INSERT
             INTO EBpcIncorporacaoAtivo
                  (cdincorporacaoativo,
                   cdvinculo,
                   cdrubricaagrupamento,
                   nusufixo,
                   dtincorporacao,
                   cdvalorreferencia,
                   nuanoinicio,
                   numesinicio,
                   nuanofim,
                   numesfim,
                   dejustificativa,
                   cdsituacaoincorporacao,
                   cdtipoincorporacaoativo,
                   vlfixo,
                   vlpercproporcionalidade,
                   nunivelcef,
                   nureferenciacef,
                   cdvalorgeralcefagrup,
                   flutilizabaseniverefcef,
                   decodigocomissionado,
                   nunivelcomissionado,
                   flutilizatabpropria,
                   depadraofuc,
                   qtvalorreferencia,
                   vlminimorecebimento,
                   flatualizacaoconstante,
                   dedetalhamentoincorp,
                   nucpfcadastrador,
                   dtinclusao,
                   dtultalteracao,
                   flanulado,
                   dtanulado,
                   cddocumento,
                   cdtipopublicacao,
                   dtpublicacao,
                   nupublicacao,
                   nupaginicial,
                   cdmeiopublicacao,
                   deoutromeio,
                   cdhistreajincorpvalorfixo,
                   flvigenciapagamento,
                   cdBaseIncorporacaoAtivo
                   )
           SELECT SBpcIncorporacaoAtivo.Nextval,
                  cdvinculo,
                  cdrubricaagrupamento,
                  nusufixo,
                  dtincorporacao,
                  cdvalorreferencia,
                  DECODE(pNuMes,12,(pNuAno + 1),pNuAno),
                  DECODE(pNuMes,12,1, pNuMes + 1),
                  NULL,
                  NULL,
                  dejustificativa,
                  cdsituacaoincorporacao,
                  cdtipoincorporacaoativo,
                  vlfixo,
                  vlpercproporcionalidade,
                  nunivelcef,
                  nureferenciacef,
                  cdvalorgeralcefagrup,
                  flutilizabaseniverefcef,
                  decodigocomissionado,
                  nunivelcomissionado,
                  flutilizatabpropria,
                  depadraofuc,
                  qtvalorreferencia,
                  pVlFormula,
                  flatualizacaoconstante,
                  dedetalhamentoincorp,
                  nucpfcadastrador,
                  dtinclusao,
                  dtultalteracao,
                  flanulado,
                  dtanulado,
                  cddocumento,
                  cdtipopublicacao,
                  dtpublicacao,
                  nupublicacao,
                  nupaginicial,
                  cdmeiopublicacao,
                  deoutromeio,
                  cdhistreajincorpvalorfixo,
                  'S',
                  cdBaseIncorporacaoAtivo
             FROM EBpcIncorporacaoAtivo
            WHERE CdIncorporacaoAtivo = pCdIncorporacaoAtivo;

          EXCEPTION

            WHEN OTHERS THEN

               PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                                       PKGPAG_VAR.vCdHistParamCalc,
                                       PKGPAG_VAR.vCdPessoa,
                                       'Erro ao atualizar valores de incorporações: '|| SQLERRM,
                                       PKGPAG_VAR.vgCdVinculo);

          END;

        END IF;

       END;

    ELSE

       pExcluiVigencia;

    END IF;

  END IF;

EXCEPTION

  WHEN OTHERS THEN

      PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              SQLERRM,
                              PKGPAG_VAR.vgCdVinculo);

END;

/*---------------------------------------------------------------------------------------------*/
--  Procedimento : PProcessaIncorporacaoAtivo
--      Objetivo : Processar as incorporacoes de ativo nas relacoes de vinculo
--
--   Regras implementadas:
--     - VlFixo informado - Se o valor fixo estiver preenchido, gera registro de pagamento
--                          da incorporacao na relacao de vinculo principal
--     - VlPercProporcionalidade - Aplica nas relacoes de CEF, FUC, CCO, e APO caso existam
/*---------------------------------------------------------------------------------------------*/
PROCEDURE PProcessaIncorporacaoAtivo(pFolha      IN PKGPAG_TIPO.rFolha,
                                     pCdVinculo  IN INTEGER,
                                     pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo,
                                     pDtCalculo  IN DATE) IS
BEGIN

  FOR vIncorp IN ( SELECT IA.cdvinculo, ia.cdrubricaagrupamento, ia.vlfixo, ia.cdbaseincorporacaoativo,
                          ia.CdIncorporacaoAtivo,
                          ia.VlMinimoRecebimento,
                          ia.FlAtualizacaoConstante,
                          ia.FlVigenciaPagamento,
                          ia.VlPercProporcionalidade,
                          ia.NuSufixo
                     FROM EBpcIncorporacaoAtivo IA
                    INNER JOIN EPagHistRubricaAgrupamento HRA
                       ON IA.CdRubricaAgrupamento = HRA.CdRubricaAgrupamento
                    WHERE IA.CdVinculo = pCdVinculo AND
                          IA.FlAnulado = PKGPAG_TIPO.cnN AND
                          ((IA.NuAnoInicio < pFolha.NuAnoReferencia OR
                          (IA.NuAnoInicio = pFolha.NuAnoReferencia AND
                           IA.NuMesInicio <= pFolha.NuMesReferencia))
                          AND
                          (IA.NuAnofim > pFolha.NuAnoReferencia OR
                          (IA.NuAnofim = pFolha.NuAnoReferencia AND
                           IA.NuMesfim >= pFolha.NuMesReferencia) OR
                           IA.NuAnofim IS NULL))
                          AND
                          ((HRA.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                          (HRA.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                          HRA.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                          AND
                          (HRA.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                          (HRA.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                          HRA.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                          HRA.NuMesFimVigencia IS NULL)))
  LOOP

    IF PKGPAG_GERAL.FGeraRubrica(vIncorp.CdRubricaAgrupamento) AND
       PKGPAG_GERAL.FRubricaPermitida(pFlPagaTodasRubricas  => pFolha.FlPagaTodasRubricas,
                                      pCdTipoFolha          => pFolha.CdTipoFolha,
                                      pCdRubricaAgrupamento => vIncorp.CdRubricaAgrupamento) THEN

      IF PKGPAG_VAR.vgRubrica.EXISTS(vIncorp.CdRubricaAgrupamento) THEN

        IF vIncorp.VlFixo IS NOT NULL AND vIncorp.CdBaseIncorporacaoAtivo = 6 AND
           NOT (PKGPAG_VAR.vgAPO.COUNT > 0 AND PKGPAG_VAR.vgCEF.COUNT > 0) THEN

          CASE PKGPAG_VAR.vgRelVincPrincipal.Tipo

            WHEN 1 THEN

              PIncorporacaoCEF(pFolha,
                               pCdVinculo,
                               pFormExpr,
                               PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                               vIncorp.CdIncorporacaoAtivo,
                               vIncorp.VlMinimoRecebimento,
                               vIncorp.FlAtualizacaoConstante,
                               vIncorp.FlVigenciaPagamento,
                               vIncorp.VlFixo,
                               vIncorp.VlPercProporcionalidade,
                               vIncorp.CdBaseIncorporacaoAtivo,
                               vIncorp.NuSufixo,
                               pDtCalculo);

            WHEN 2 THEN

              PIncorporacaoCCO(pFolha,
                               pCdVinculo,
                               pFormExpr,
                               PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                               vIncorp.CdIncorporacaoAtivo,
                               vIncorp.VlMinimoRecebimento,
                               vIncorp.FlAtualizacaoConstante,
                               vIncorp.FlVigenciaPagamento,
                               vIncorp.vlFixo,
                               vIncorp.VlPercProporcionalidade,
                               vIncorp.CdBaseIncorporacaoAtivo,
                               vIncorp.NuSufixo,
                               pDtCalculo);

            WHEN 3 THEN

              PIncorporacaoFUC(pFolha,
                               pCdVinculo,
                               pFormExpr,
                               PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                               vIncorp.CdIncorporacaoAtivo,
                               vIncorp.VlMinimoRecebimento,
                               vIncorp.FlAtualizacaoConstante,
                               vIncorp.FlVigenciaPagamento,
                               vIncorp.vlFixo,
                               vIncorp.VlPercProporcionalidade,
                               vIncorp.CdBaseIncorporacaoAtivo,
                               vIncorp.NuSufixo,
                               pDtCalculo);

            WHEN 4 THEN

              PIncorporacaoAPO(pFolha,
                               pCdVinculo,
                               pFormExpr,
                               PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                               vIncorp.CdIncorporacaoAtivo,
                               vIncorp.VlMinimoRecebimento,
                               vIncorp.FlAtualizacaoConstante,
                               vIncorp.FlVigenciaPagamento,
                               vIncorp.vlFixo,
                               vIncorp.VlPercProporcionalidade,
                               vIncorp.NuSufixo,
                               vIncorp.CdBaseIncorporacaoAtivo,
                               pDtCalculo);

            WHEN 7 THEN

              PIncorporacaoPNP(pFolha,
                               pCdVinculo,
                               pFormExpr,
                               PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                               vIncorp.CdIncorporacaoAtivo,
                               vIncorp.VlMinimoRecebimento,
                               vIncorp.FlAtualizacaoConstante,
                               vIncorp.FlVigenciaPagamento,
                               vIncorp.vlFixo,
                               vIncorp.VlPercProporcionalidade,
                               vIncorp.NuSufixo,
                               vIncorp.CdBaseIncorporacaoAtivo,
                               pDtCalculo);

            ELSE

              NULL;

          END CASE;

       ELSE

          PIncorporacaoCEF(pFolha,
                             pCdVinculo,
                             pFormExpr,
                             PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                             vIncorp.CdIncorporacaoAtivo,
                             vIncorp.VlMinimoRecebimento,
                             vIncorp.FlAtualizacaoConstante,
                             vIncorp.FlVigenciaPagamento,
                             vIncorp.VlFixo,
                             vIncorp.VlPercProporcionalidade,
                             vIncorp.CdBaseIncorporacaoAtivo,
                             vIncorp.NuSufixo,
                             pDtCalculo);

            PIncorporacaoAPO(pFolha,
                             pCdVinculo,
                             pFormExpr,
                             PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                             vIncorp.CdIncorporacaoAtivo,
                             vIncorp.VlMinimoRecebimento,
                             vIncorp.FlAtualizacaoConstante,
                             vIncorp.FlVigenciaPagamento,
                             vIncorp.vlFixo,
                             vIncorp.VlPercProporcionalidade,
                             vIncorp.NuSufixo,
                             vIncorp.CdBaseIncorporacaoAtivo,
                             pDtCalculo);

           PIncorporacaoPNP(pFolha,
                            pCdVinculo,
                            pFormExpr,
                            PKGPAG_VAR.vgRubrica(vIncorp.CdRubricaAgrupamento),
                            vIncorp.CdIncorporacaoAtivo,
                            vIncorp.VlMinimoRecebimento,
                            vIncorp.FlAtualizacaoConstante,
                            vIncorp.FlVigenciaPagamento,
                            vIncorp.vlFixo,
                            vIncorp.VlPercProporcionalidade,
                            vIncorp.NuSufixo,
                            vIncorp.CdBaseIncorporacaoAtivo,
                            pDtCalculo);

       END IF;

     END IF;

    END IF;

  END LOOP;

END;

END PKGPAG_IA;
/
