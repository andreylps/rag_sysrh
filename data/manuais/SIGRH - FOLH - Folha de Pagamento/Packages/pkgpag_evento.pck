CREATE OR REPLACE PACKAGE PKGPAG_EVENTO IS

  PROCEDURE PProcessaEventos(pVinculo            PKGPAG_TIPO.rVinculo,
                            pCdPessoa           IN INTEGER,
                            pFolha              IN PKGPAG_TIPO.rFolha,
                            pEvento             IN PKGPAG_TIPO.tEvento,
                            pRubrica            IN PKGPAG_TIPO.tRubrica,
                            pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                            pParamPag           IN EPagAgrupamentoParametro%ROWTYPE,
                            pCEF                IN PKGPAG_TIPO.tCEF,
                            pCCO                IN PKGPAG_TIPO.tCCO,
                            pCCOSubst           IN PKGPAG_TIPO.tCCO,
                            pFUC                IN PKGPAG_TIPO.tFUC,
                            pFUCSubst           IN PKGPAG_TIPO.tFUC,
                            pAPO                IN PKGPAG_TIPO.tCEF,
                            pAPOSemParid        IN PKGPAG_TIPO.tCEF,
                            pBOL                IN PKGPAG_TIPO.tBOL,
                            pPensaoNaoPrev      IN PKGPAG_TIPO.tPensaoNaoPrev,
                            pPensaoPrev         IN PKGPAG_TIPO.tPensaoPrev,
                            pdtCalculo          IN DATE,
                            pFlCalcDefinitivo   IN CHAR DEFAULT PKGPAG_TIPO.cnN,
                            pFlPagaAdiantamento IN CHAR DEFAULT PKGPAG_TIPO.cnN);

  PROCEDURE PGeraRegistroPagamento(pTipoRegistro        IN INTEGER,
                                   pFolha               IN PKGPAG_TIPO.rFolha,
                                   pCdVinculo           IN INTEGER,
                                   pRubrica             IN PKGPAG_TIPO.rRubrica,
                                   pFormExpr            IN PKGPAG_TIPO.tFormulaCalculo,
                                   pFlPrincipal         IN CHAR DEFAULT PKGPAG_TIPO.cnS,
                                   pCEF                 IN PKGPAG_TIPO.tCEF,
                                   pCCO                 IN PKGPAG_TIPO.tCCO,
                                   pCCOSubst            IN PKGPAG_TIPO.tCCO,
                                   pFUC                 IN PKGPAG_TIPO.tFUC,
                                   pBOL                 IN PKGPAG_TIPO.tBOL,
                                   pAPO                 IN PKGPAG_TIPO.tCEF,
                                   pVlIndice            IN NUMBER,
                                   pValorIntegral       IN NUMBER DEFAULT NULL,
                                   pDtCalculo           IN DATE,
                                   pCdTipoOrigemRubrica IN INTEGER DEFAULT 1,
                                   pNuFormulaEspecifica IN INTEGER DEFAULT NULL,
                                   pDtDesligamento      IN DATE DEFAULT NULL,
                                   pNuSufixo            IN INTEGER DEFAULT 1,
                                   pFlApenasNoVinculo   IN CHAR DEFAULT 'N');

FUNCTION FAceitaEvento ( pRegEvento IN PKGPAG_TIPO.rEvento) RETURN BOOLEAN;

END PKGPAG_EVENTO;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_EVENTO IS

FUNCTION FAceitaEvento ( pRegEvento IN PKGPAG_TIPO.rEvento)  RETURN BOOLEAN IS

BEGIN

    IF (PKGPAG_GERAL.FGeraRubrica(pRegEvento.CdRubricaAgrupamento) AND NOT
        PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pRegEvento.CdRubricaAgrupamento,
                                                                                                             pNuSufixoRubrica      => 1)) OR
       (pRegEvento.CdTipoEventoPagamento IN
       (1, 31, /*32,42,43,*/ 44, 45, 47, 48, 49, 50, 55)) THEN

      RETURN TRUE;

    ELSIF (PKGPAG_GERAL.FGeraRubrica(pRegEvento.CdRubricaAgrupamento) AND NOT  --sig 7062 folha óbito iprev
           PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pRegEvento.CdRubricaAgrupamento,
                                                                                                                pNuSufixoRubrica      => 1)) OR
          (pRegEvento.CdTipoEventoPagamento IN
          (1, 31, /*32,42,43,*/ 44, 45, 47, 48, 49, 50, 52, 55)) AND
          pRegEvento.cdagrupamento = 132 THEN
      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

END;

PROCEDURE PGeraRegistroPagamento(pTipoRegistro        IN INTEGER,
                                 pFolha               IN PKGPAG_TIPO.rFolha,
                                 pCdVinculo           IN INTEGER,
                                 pRubrica             IN PKGPAG_TIPO.rRubrica,
                                 pFormExpr            IN PKGPAG_TIPO.tFormulaCalculo,
                                 pFlPrincipal         IN CHAR DEFAULT PKGPAG_TIPO.cnS,
                                 pCEF                 IN PKGPAG_TIPO.tCEF,
                                 pCCO                 IN PKGPAG_TIPO.tCCO,
                                 pCCOSubst            IN PKGPAG_TIPO.tCCO,
                                 pFUC                 IN PKGPAG_TIPO.tFUC,
                                 pBOL                 IN PKGPAG_TIPO.tBOL,
                                 pAPO                 IN PKGPAG_TIPO.tCEF,
                                 pVlIndice            IN NUMBER,
                                 pValorIntegral       IN NUMBER DEFAULT NULL,
                                 pDtCalculo           IN DATE,
                                 pCdTipoOrigemRubrica IN INTEGER DEFAULT 1,
                                 pNuFormulaEspecifica IN INTEGER DEFAULT NULL,
                                 pDtDesligamento      IN DATE DEFAULT NULL,
                                 pNuSufixo            IN INTEGER DEFAULT 1,
                                 pFlApenasNoVinculo   IN CHAR DEFAULT 'N') IS

 vCdExpressaoFormCalc INTEGER;

 vValorProp           PKGPAG_TIPO.rValorPagamento;

 vCdCargoComissionado INTEGER;

 vCdGrupoOcupacional  INTEGER;

 vFlPrincipal         CHAR;

BEGIN

  vCdCargoComissionado := NULL;

  vCdGrupoOcupacional  := NULL;

  IF pFlApenasNoVinculo = 'N' THEN

    IF pCEF.COUNT > 0 THEN

      FOR i IN pCEF.FIRST .. pCEF.LAST
      LOOP

        IF (pFlPrincipal = PKGPAG_TIPO.cnN) OR
           (pFlPrincipal = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgRelVincPrincipal.Tipo = 1 AND
            pCEF(i).CdHistRelVinc = PKGPAG_VAR.vgRelVincPrincipal.CdHist) THEN

          IF pCCO.COUNT > 0 THEN

            vCdCargoComissionado := pCCO(1).CdCargoComissionado;

            vCdGrupoOcupacional := pCCO(1).CdGrupoOcupacional;

          END IF;

          IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica( pRubrica                  => pRubrica,
                                                     pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                     pCdOrgaoExercicio         => pCEF(i).CdOrgaoExercicio,
                                                     pCdNaturezaVinculo        => pCEF(i).CdNaturezaVinculo,
                                                     pCdRelacaoTrabalho        => pCEF(i).CdRelacaoTrabalho,
                                                     pCdRegimeTrabalho         => pCEF(i).CdRegimeTrabalho,
                                                     pCdRegimePrevidenciario   => pCEF(i).CdRegimePrevidenciario,
                                                     pCdSituacaoPrevidenciaria => pCEF(i).CdSituacaoPrevidenciaria,
                                                     pCdUnidadeOrganizacional  => pCEF(i).CdUnidadeOrganizacional,
                                                     pCdEstruturaCarreira      => pCEF(i).CdEstruturaCarreira,
                                                     pCdCargoComissionado      => vCdCargoComissionado,
                                                     pCdGrupoOcupacional       => vCdGrupoOcupacional,
                                                     pFlTipoProvimento         => pCEF(i).FlEfetivacao,
                                                     pCdMotivoMovimentacao     => pCEF(i).CdMotivoMovimentacao,
                                                     pCdInstitutoMovimentacao  => pCEF(i).CdInstitutoMovimentacao,
                                                     pCdTipoRelacaoVinculo     => 1
                                                     ) THEN

             CASE pTipoRegistro

               WHEN 1 THEN -- Valor

                 vValorProp := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                      pRubrica           => pRubrica,
                                                                      pValorIntegral     => pValorIntegral,
                                                                      pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                      pCEF               => pCEF(i),
                                                                      pDtCalculo         => PKGPAG_VAR.vDtCalculo);

                 PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                       pCdVinculo               => pCdVinculo,
                                                       pCdRelacaoVinculo        => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                       pCdHistRelacaoVinculo    => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                       pCdExpressaoFormCalc     => NULL,
                                                       pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                       pVlIntegral              => vValorProp.vlIntegral,
                                                       pVlProporcional          => vValorProp.vlProporcional,
                                                       pVlReal                  => vValorProp.vlReal,
                                                       pNuSufixoRubrica         => pNuSufixo,
                                                       pNuParcelas              => 1,
                                                       pVlIndice                => vValorProp.vlIndice,
                                                       pCdTipoOrigemRubrica     => pCdTipoOrigemRubrica);

               WHEN 2 THEN -- Formula de calculo

                 vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                                 pFormExpr                 => pFormExpr,
                                                 pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                 pCdRelacaoVinculo         => pCEF(i).CdRelacaoVinculo,
                                                 pCdEstruturaCarreira      => pCEF(i).CdEstruturaCarreira,
                                                 pCdUnidadeOrganizacional  => pCEF(i).CdUnidadeOrganizacional,
                                                 pNuFormulaEspecifica      => pNuFormulaEspecifica);

                 IF vCdExpressaoFormCalc > 0 THEN

                   PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                         pCdVinculo               => pCdVinculo,
                                                         pCdRelacaoVinculo        => pCEF(i).CdRelacaoVinculo,
                                                         pCdHistRelacaoVinculo    => pCEF(i).CdHistRelVinc,
                                                         pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                         pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                         pVlIntegral              => NULL,
                                                         pVlProporcional          => NULL,
                                                         pNuSufixoRubrica         => pNuSufixo,
                                                         pNuParcelas              => 0,
                                                         pVlIndice                => pVlIndice,
                                                         pDtInicioRelacao         => pCEF(i).DtInicioRelacao,
                                                         pDtDesligamento          => pCEF(i).DtFimRelacao,
                                                         pCdUnidadeOrganizacional => pCEF(i).CdUnidadeOrganizacional,
                                                         pCdTipoOrigemRubrica     => pCdTipoOrigemRubrica,
                                                         pDtInicio                => pCEF(i).DtInicio,
                                                         pDtFim                   => pCEF(i).DtFim);

                   --
                   -- Cidasc Adiantamento 13º ferias gerar CEF
                   --
                   IF  pkgpag_geral.fretornacodigorubrica(pcdagrupamento => pFolha.CdAgrupamento,
                       pcdtipoeventopagamento => 51) = pRubrica.CdRubricaAgrupamento
                       and pFolha.CdAgrupamento = 4
                       and pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaFerias)
                     THEN

                       RETURN;

                   END IF;

                 END IF;

             END CASE;

           END IF;

         END IF;

       END LOOP;

    END IF;

    IF pCCO.COUNT > 0 THEN

       FOR i IN pCCO.FIRST .. pCCO.LAST
       LOOP

         -- 7593/2015 - FOLHA - AUXILIO ALIMENTACAO JUDICIAL 01-0153 IPREV
         -- Gerar os dias da primeira relacao de comissionado
         -- Quando alterou de cargo comissionado
         vFlPrincipal := pFlPrincipal;

         IF pRubrica.NuRubrica = 153 and pFolha.CdAgrupamento = 1 and pCCO.Count > 1 and
            pCCO(i).CdHistCargoCom <> PKGPAG_VAR.vgRelVincPrincipal.CdHist and
            pCCO(i).DtFim < pFolha.DtFimMes

           THEN
             vFlPrincipal := 'N';
         END IF;

         IF(vFlPrincipal = PKGPAG_TIPO.cnN) OR
           (vFlPrincipal = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgRelVincPrincipal.Tipo = 2 AND
            pCCO(i).CdHistCargoCom = PKGPAG_VAR.vgRelVincPrincipal.CdHist) THEN

           IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                      pRubrica                  => pRubrica,
                                      pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                      pCdOrgaoExercicio         => pCCO(i).CdOrgaoExercicio,
                                      pCdNaturezaVinculo        => pCCO(i).CdNaturezaVinculo,
                                      pCdRelacaoTrabalho        => pCCO(i).CdRelacaoTrabalho,
                                      pCdRegimeTrabalho         => pCCO(i).CdRegimeTrabalho,
                                      pCdRegimePrevidenciario   => pCCO(i).CdRegimePrevidenciario,
                                      pCdSituacaoPrevidenciaria => pCCO(i).CdSituacaoPrevidenciaria,
                                      pCdCargoComissionado      => pCCO(i).CdCargoComissionado,
                                      pCdGrupoOcupacional       => pCCO(i).CdGrupoOcupacional,
                                      pCdUnidadeOrganizacional  => pCCO(i).CdUnidadeOrganizacional,
                                      pCdOpcaoRemuneracao       => pCCO(i).CdOpcaoRemuneracao,
                                      pCdEstruturaCarreira      => PKGPAG_VAR.vgCdEstruturaCarreira,
                                      pFlTipoProvimento         => pCCO(i).FlTipoProvimento,
                                      pCdTipoRelacaoVinculo     => 2
                                      ) THEN

             CASE pTipoRegistro

               WHEN 1 THEN -- Valor

                  vValorProp :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                        pRubrica       => pRubrica,
                                                                        pCCO           => pCCO(i),
                                                                        pValorIntegral => pValorIntegral,
                                                                        pDtCalculo     => PKGPAG_VAR.vDtCalculo);

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento         => pFolha.CdFolhaPagamento,
                                                        pCdVinculo                => pCdVinculo,
                                                        pCdRelacaoVinculo         => 2,
                                                        pCdHistRelacaoVinculo     => pCCO(i).CdHistCargoCom,
                                                        pCdExpressaoFormCalc      => NULL,
                                                        pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                        pVlIntegral               => vValorProp.vlProporcional,
                                                        pVlProporcional           => vValorProp.vlProporcional,
                                                        pVlReal                   => vValorProp.vlReal,
                                                        pNuSufixoRubrica          => pNuSufixo,
                                                        pNuParcelas               => 1,
                                                        pVlIndice                 => vValorProp.vlIndice,
                                                        pCdTipoOrigemRubrica      => pCdTipoOrigemRubrica,
                                                        pDtInicio                 => pCCO(i).DtInicio,
                                                        pDtFim                    => pCCO(i).DtFim);

                 WHEN 2 THEN -- Formula de calculo

                  vCdExpressaoFormCalc :=

                     PKGPAG_GERAL.FIdentificaFormulaCalculo( pFormExpr                 => pFormExpr,
                                                             pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                             pCdRelacaoVinculo         => 2,
                                                             pCdCargoComissionado      => pCCO(i).CdCargoComissionado,
                                                             pCdUnidadeOrganizacional  => pCCO(i).CdUnidadeOrganizacional,
                                                             pNuFormulaEspecifica      => pNuFormulaEspecifica);

                  IF vCdExpressaoFormCalc > 0 THEN

                    PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                          pCdVinculo               => pCdVinculo,
                                                          pCdRelacaoVinculo        => 2,
                                                          pCdHistRelacaoVinculo    => pCCO(i).CdHistCargoCom,
                                                          pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                          pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                          pVlIntegral              => NULL,
                                                          pVlProporcional          => NULL,
                                                          pNuSufixoRubrica         => pNuSufixo,
                                                          pNuParcelas              => 0,
                                                          pVlIndice                => pVlIndice,
                                                          pDtInicioRelacao         => pCCO(i).DtInicioRelacao,
                                                          pDtDesligamento          => pCCO(i).DtFimRelacao,
                                                          pCdUnidadeOrganizacional => pCCO(i).CdUnidadeOrganizacional,
                                                          pCdTipoOrigemRubrica     => pCdTipoOrigemRubrica,
                                                          pDtInicio                 => pCCO(i).DtInicio,
                                                          pDtFim                    => pCCO(i).DtFim);

                 END IF;

               END CASE;

         END IF;

       END IF;

     END LOOP;

    END IF;

    IF pCCOSubst.COUNT > 0 THEN

       FOR i IN pCCOSubst.FIRST .. pCCOSubst.LAST
       LOOP

         IF(pFlPrincipal = PKGPAG_TIPO.cnN) OR
           (pFlPrincipal = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgRelVincPrincipal.Tipo = 2 AND
            pCCOSubst(i).CdHistCargoCom = PKGPAG_VAR.vgRelVincPrincipal.CdHist) THEN

           IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                      pRubrica                  => pRubrica,
                                      pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                      pCdOrgaoExercicio         => pCCOSubst(i).CdOrgaoExercicio,
                                      pCdNaturezaVinculo        => pCCOSubst(i).CdNaturezaVinculo,
                                      pCdRelacaoTrabalho        => pCCOSubst(i).CdRelacaoTrabalho,
                                      pCdRegimeTrabalho         => pCCOSubst(i).CdRegimeTrabalho,
                                      pCdRegimePrevidenciario   => pCCOSubst(i).CdRegimePrevidenciario,
                                      pCdSituacaoPrevidenciaria => pCCOSubst(i).CdSituacaoPrevidenciaria,
                                      pCdCargoComissionado      => pCCOSubst(i).CdCargoComissionado,
                                      pCdGrupoOcupacional       => pCCOSubst(i).CdGrupoOcupacional,
                                      pCdUnidadeOrganizacional  => pCCOSubst(i).CdUnidadeOrganizacional,
                                      pCdOpcaoRemuneracao       => pCCOSubst(i).CdOpcaoRemuneracao,
                                      pCdEstruturaCarreira      => PKGPAG_VAR.vgCdEstruturaCarreira,
                                      pFlTipoProvimento         => pCCOSubst(i).FlTipoProvimento,
                                      pCdTipoRelacaoVinculo     => 2
                                      ) THEN

             CASE pTipoRegistro

               WHEN 1 THEN -- Valor

                  vValorProp :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                        pRubrica       => pRubrica,
                                                                        pCCO           => pCCOSubst(i),
                                                                        pValorIntegral => pValorIntegral,
                                                                        pDtCalculo     => PKGPAG_VAR.vDtCalculo);

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento         => pFolha.CdFolhaPagamento,
                                                        pCdVinculo                => pCdVinculo,
                                                        pCdRelacaoVinculo         => 2,
                                                        pCdHistRelacaoVinculo     => pCCOSubst(i).CdHistCargoCom,
                                                        pCdExpressaoFormCalc      => NULL,
                                                        pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                        pVlIntegral               => vValorProp.vlProporcional,
                                                        pVlProporcional           => vValorProp.vlProporcional,
                                                        pVlReal                   => vValorProp.vlReal,
                                                        pNuSufixoRubrica          => pNuSufixo,
                                                        pNuParcelas               => 1,
                                                        pVlIndice                 => vValorProp.vlIndice,
                                                        pCdTipoOrigemRubrica      => pCdTipoOrigemRubrica,
                                                        pDtInicio                 => pCCOSubst(i).DtInicio,
                                                        pDtFim                    => pCCOSubst(i).DtFim);

                 WHEN 2 THEN -- Formula de calculo

                  vCdExpressaoFormCalc :=

                     PKGPAG_GERAL.FIdentificaFormulaCalculo( pFormExpr                 => pFormExpr,
                                                             pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                             pCdRelacaoVinculo         => 2,
                                                             pCdCargoComissionado      => pCCOSubst(i).CdCargoComissionado,
                                                             pCdUnidadeOrganizacional  => pCCOSubst(i).CdUnidadeOrganizacional,
                                                             pNuFormulaEspecifica      => pNuFormulaEspecifica);

                  IF vCdExpressaoFormCalc > 0 THEN

                    PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                          pCdVinculo               => pCdVinculo,
                                                          pCdRelacaoVinculo        => 2,
                                                          pCdHistRelacaoVinculo    => pCCOSubst(i).CdHistCargoCom,
                                                          pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                          pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                          pVlIntegral              => NULL,
                                                          pVlProporcional          => NULL,
                                                          pNuSufixoRubrica         => pNuSufixo,
                                                          pNuParcelas              => 0,
                                                          pVlIndice                => pVlIndice,
                                                          pDtInicioRelacao         => pCCOSubst(i).DtInicioRelacao,
                                                          pDtDesligamento          => pCCOSubst(i).DtFimRelacao,
                                                          pCdUnidadeOrganizacional => pCCOSubst(i).CdUnidadeOrganizacional,
                                                          pCdTipoOrigemRubrica     => pCdTipoOrigemRubrica,
                                                          pDtInicio                 => pCCOSubst(i).DtInicio,
                                                          pDtFim                    => pCCOSubst(i).DtFim);

                 END IF;

               END CASE;

         END IF;

       END IF;

     END LOOP;

    END IF;

    IF pFUC.COUNT > 0 THEN

      FOR i IN pFUC.FIRST .. pFUC.LAST
      LOOP

        IF (pFlPrincipal = PKGPAG_TIPO.cnN) THEN

          IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica( pRubrica             => pRubrica,
                                                     pCdOrgao             => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                     pCdOrgaoExercicio    => pFUC(i).CdOrgaoExercicio,
                                                     pCdFuncaoChefia      => pFUC(i).CdFuncaoChefia,
                                                     pCdEstruturaCarreira => PKGPAG_VAR.vgCdEstruturaCarreira,
                                                     pCdUnidadeOrganizacional  => pFUC(i).CdUnidadeOrganizacional,
                                                     pFlTipoProvimento    => pFUC(i).FlEfetivacao) THEN

            CASE pTipoRegistro

               WHEN 1 THEN -- Valor

                  vValorProp :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                        pRubrica       => pRubrica,
                                                                        pFUC           => pFUC(i),
                                                                        pValorIntegral => pValorIntegral,
                                                                        pDtCalculo     => PKGPAG_VAR.vDtCalculo);

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                        pCdVinculo              => pCdVinculo,
                                                        pCdRelacaoVinculo       => 3,
                                                        pCdHistRelacaoVinculo   => pFUC(i).CdHistFuncaoChefia,
                                                        pCdExpressaoFormCalc    => NULL,
                                                        pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                        pVlIntegral             => vValorProp.vlIntegral,
                                                        pVlProporcional         => vValorProp.vlProporcional,
                                                        pVlReal                 => vValorProp.vlReal,
                                                        pNuSufixoRubrica        => pNuSufixo,
                                                        pNuParcelas             => 1,
                                                        pVlIndice               => vValorProp.vlIndice,
                                                        pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                        pDtInicio               => pFUC(i).DtInicio,
                                                        pDtFim                  => pFUC(i).DtFim);

                 WHEN 2 THEN -- Formula de calculo

                   vCdExpressaoFormCalc :=

                       PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                              pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                              pCdRelacaoVinculo         => 3,
                                                              pNuFormulaEspecifica      => pNuFormulaEspecifica/*,
                                                              pCdUnidadeOrganizacional  => pFUC(i).CdUnidadeOrganizacional*/);

                   IF vCdExpressaoFormCalc > 0 THEN

                     PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                           pCdVinculo               => pCdVinculo,
                                                           pCdRelacaoVinculo        => 3, -- Funcao de chefia
                                                           pCdHistRelacaoVinculo    => pFUC(i).CdHistFuncaoChefia,
                                                           pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                           pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                           pVlIntegral              => NULL,
                                                           pVlProporcional          => NULL,
                                                           pNuSufixoRubrica         => pNuSufixo,
                                                           pNuParcelas              => 0,
                                                           pVlIndice                => pVlIndice,
                                                           pDtInicioRelacao         => pFUC(i).DtInicioRelacao,
                                                           pDtDesligamento          => pFUC(i).DtFimRelacao,
                                                           pCdUnidadeOrganizacional => pFUC(i).CdUnidadeOrganizacional,
                                                           pCdTipoOrigemRubrica     => pCdTipoOrigemRubrica,
                                                           pDtInicio               => pFUC(i).DtInicio,
                                                           pDtFim                  => pFUC(i).DtFim);

                   END IF;

                END CASE;

           END IF;

         END IF;

       END LOOP;

    END IF;

    IF pBOL.COUNT > 0 THEN

       FOR i IN pBOL.FIRST .. pBOL.LAST
       LOOP

         IF (pFlPrincipal = PKGPAG_TIPO.cnN) OR
            (pFlPrincipal = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgRelVincPrincipal.Tipo = 5 AND
            pBOL(i).CdHistEstagio = PKGPAG_VAR.vgRelVincPrincipal.CdHist)  THEN

          IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                       pRubrica                  => pRubrica,
                                       pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                       pCdOrgaoExercicio         => pBOL(i).CdOrgaoExercicio,
                                       pCdNaturezaVinculo        => pBOL(i).CdNaturezaVinculo,
                                       pCdRelacaoTrabalho        => pBOL(i).CdRelacaoTrabalho,
                                       pCdRegimeTrabalho         => pBOL(i).CdRegimeTrabalho,
                                       pCdRegimePrevidenciario   => pBOL(i).CdRegimePrevidenciario,
                                       pCdSituacaoPrevidenciaria => pBOL(i).CdSituacaoPrevidenciaria,
                                       pCdPrograma               => pBOL(i).CdPrograma
                                       ) THEN

             vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                      pFormExpr                 => pFormExpr,
                                      pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                      pCdRelacaoVinculo         => 5,
                                      pNuFormulaEspecifica      => pNuFormulaEspecifica);

             IF vCdExpressaoFormCalc > 0 THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(
                                        pCdFolhaPagamento         => pFolha.CdFolhaPagamento,
                                        pCdVinculo                => pCdVinculo,
                                        pCdRelacaoVinculo         => 5,
                                        pCdHistRelacaoVinculo     => pBOL(i).CdHistEstagio,
                                        pCdExpressaoFormCalc      => vCdExpressaoFormCalc,
                                        pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                        pVlIntegral               => NULL,
                                        pVlProporcional           => NULL,
                                        pNuSufixoRubrica          => pNuSufixo,
                                        pNuParcelas               => 0,
                                        pVlIndice                 => pVlIndice,
                                        pDtInicioRelacao          => pBOL(i).DtInicioRelacao,
                                        pDtDesligamento           => pBOL(i).DtFimRelacao,
                                        pCdUnidadeOrganizacional  => pBOL(i).CdUnidadeOrganizacional,
                                        pCdTipoOrigemRubrica      => pCdTipoOrigemRubrica,
                                        pDtInicio                 => pBOL(i).DtInicio,
                                        pDtFim                    => pBOL(i).DtFim);

              END IF;

           END IF;

         END IF;

       END LOOP;

    END IF;

    IF pAPO.COUNT > 0 THEN

        FOR i IN pAPO.FIRST .. pAPO.LAST
        LOOP

          IF (pFlPrincipal = PKGPAG_TIPO.cnN) OR
             (pFlPrincipal = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgRelVincPrincipal.Tipo = 4 AND
              pAPO(i).CdHistRelVinc = PKGPAG_VAR.vgRelVincPrincipal.CdHist)  THEN

            IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                      pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                      pCdOrgaoExercicio         => pAPO(i).CdOrgaoExercicio,
                                                      pCdSituacaoPrevidenciaria => pAPO(i).CdSituacaoPrevidenciaria,
                                                      pCdEstruturaCarreira      => pAPO(i).CdEstruturaCarreira,
                                                      pFlAPOOrigemCCO           => pAPO(i).FlOrigemCCO,
                                                      pCdTipoRelacaoVinculo     => 4) THEN

              CASE pTipoRegistro

                WHEN 1 THEN

                  vValorProp :=

                    PKGPAG_GERAL.FCalculaProporcionalidade(pFolha          => pFolha,
                                                           pAPO            => pAPO(i),
                                                           pRubrica        => pRubrica,
                                                           pValorIntegral  => pValorIntegral);

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                        pCdVinculo              => pCdVinculo,
                                                        pCdRelacaoVinculo       => 4,
                                                        pCdHistRelacaoVinculo   => pAPO(i).CdHistRelVinc,
                                                        pCdExpressaoFormCalc    => NULL,
                                                        pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                        pVlIntegral             => vValorProp.vlIntegral,
                                                        pVlProporcional         => vValorProp.vlProporcional,
                                                        pVlReal                 => vValorProp.vlReal,
                                                        pNuSufixoRubrica        => pNuSufixo,
                                                        pNuParcelas             => 1,
                                                        pVlIndice               => vValorProp.vlIndice,
                                                        pCdTipoOrigemRubrica    => pCdTipoOrigemRubrica,
                                                        pDtInicio               => pAPO(i).DtInicio,
                                                        pDtFim                  => pAPO(i).DtFim);

                WHEN 2 THEN

                  vCdExpressaoFormCalc :=

                    PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                           pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                           pCdRelacaoVinculo         => pAPO(i).CdRelacaoVinculo,
                                                           pNuFormulaEspecifica      => pNuFormulaEspecifica);

                  IF vCdExpressaoFormCalc > 0 THEN

                    PKGPAG_GERAL.PInsereLancamentoRelacao(
                                       pCdFolhaPagamento         => pFolha.CdFolhaPagamento,
                                       pCdVinculo                => pCdVinculo,
                                       pCdRelacaoVinculo         => 4,
                                       pCdHistRelacaoVinculo     => pAPO(i).CdHistRelVinc,
                                       pCdExpressaoFormCalc      => vCdExpressaoFormCalc,
                                       pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                       pVlIntegral               => NULL,
                                       pVlProporcional           => NULL,
                                       pNuSufixoRubrica          => pNuSufixo,
                                       pNuParcelas               => 0,
                                       pVlIndice                 => pVlIndice,
                                       pDtInicioRelacao          => pAPO(i).DtInicioRelacao,
                                       pDtDesligamento           => pAPO(i).DtFimRelacao,
                                       pCdUnidadeOrganizacional  => pAPO(i).CdUnidadeOrganizacional,
                                       pCdTipoOrigemRubrica      => pCdTipoOrigemRubrica,
                                       pDtInicio                 => pAPO(i).DtInicio,
                                       pDtFim                    => pAPO(i).DtFim);

                  END IF;

                END CASE;

            END IF;

          END IF;

        END LOOP;

    END IF;

    IF pDtDesligamento < pFolha.DtInicioMes THEN

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) THEN

          vCdExpressaoFormCalc :=

                      PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                             pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                             pCdRelacaoVinculo         => 0);
          IF vCdExpressaoFormCalc > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pCdVinculo,
                                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => case when pkgpag_var.vgrubrica(pRubrica.CdRubricaAgrupamento).nurubrica = 1115
                                                                                then pVlIndice else NULL end,
                                                  pCdTipoOrigemRubrica  => 1);

          END IF;

        END IF;

      END IF;

    ELSE

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) THEN

       vCdExpressaoFormCalc :=

                  PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                         pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                         pCdRelacaoVinculo         => 0);

       IF vCdExpressaoFormCalc > 0 THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                               pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
       END IF;

      END IF;

    END IF;

 END;

FUNCTION FRetornaPercentualCCO(pCdCargoComissionado IN INTEGER)

  RETURN PKGPAG_TIPO.rRubPercent IS

  vRubPercent PKGPAG_TIPO.rRubPercent;

BEGIN

  IF PKGPAG_VAR.vgParamCCO.EXISTS(pCdCargoComissionado) THEN

    vRubPercent.CdRubricaAgrupamento := PKGPAG_VAR.vgParamCCO(pCdCargoComissionado).CdRubricaAgrupamento;

    vRubPercent.VlPercentual := PKGPAG_VAR.vgParamCCO(pCdCargoComissionado).VlPercentual;

    RETURN vRubPercent;

  END IF;

  RETURN NULL;

EXCEPTION

  WHEN OTHERS THEN

    RETURN NULL;

END;

FUNCTION FPossuiAbrangenciaCarreira(pCdEvento            IN INTEGER,
                                    pInAcaoCarreira      IN INTEGER,
                                    pCdEstruturaCarreira IN INTEGER)
  RETURN BOOLEAN IS

BEGIN

   CASE pInAcaoCarreira

     WHEN 3 THEN -- Todas sao permitidas

       RETURN TRUE;

     WHEN 1 THEN -- Impedidas

       IF PKGPAG_VAR.vgEventoCarreira(pCdEvento).Carreira.EXISTS(pCdEstruturaCarreira) THEN

         RETURN FALSE;

       ELSE

         RETURN TRUE;

       END IF;

     WHEN 2 THEN -- Permitidas

       IF PKGPAG_VAR.vgEventoCarreira(pCdEvento).Carreira.EXISTS(pCdEstruturaCarreira) THEN

         RETURN TRUE;

       ELSE

         RETURN FALSE;

       END IF;

     ELSE

       RETURN TRUE;

   END CASE;

END;

/*-----------------------------------------------------------------------------------------/*
--    Funcao: FPossuiIncorporacao
--
--  Objetivo: Verificar a exisitencia de incorporacao de ativo vigente para o vinculo
--            (...)
--
/*-----------------------------------------------------------------------------------------*/

FUNCTION FPossuiIncorporacao(pCdVinculo              IN INTEGER,
                             pNuAnoReferencia        IN INTEGER,
                             pNuMesReferencia        IN INTEGER,
                             pCdAgrupamentoParametro IN INTEGER)
  RETURN BOOLEAN IS

  vCont INTEGER;

BEGIN

  SELECT COUNT(*)
    INTO vCont
    FROM EBpcIncorporacaoAtivo IA
   WHERE IA.CdVinculo = pCdVinculo AND
         ((IA.NuAnoInicio < pNuAnoReferencia OR
          (IA.NuAnoInicio = pNuAnoReferencia AND
           IA.NuMesInicio <= pNuMesReferencia))
          AND
          (IA.NuAnoFim > pNuAnoReferencia OR
          (IA.NuAnoFim = pNuAnoReferencia AND
           IA.NuMesFim >= pNuMesReferencia) OR
           IA.NuAnoFim IS NULL)) AND
           EXISTS (SELECT 1
                     FROM EPagAgrupParamTpIncorp TI
                    WHERE TI.CdTipoIncorporacaoAtivo = IA.CdTipoIncorporacaoAtivo AND
                          TI.CdAgrupamentoParametro = pCdAgrupamentoParametro);

  IF vCont > 0 then

    RETURN TRUE;

  ELSE

    RETURN FALSE;

  END IF;

EXCEPTION

  WHEN OTHERS THEN

    RETURN FALSE;

END;

PROCEDURE PProcessaEventos(pVinculo            IN PKGPAG_TIPO.rVinculo,
                           pCdPessoa           IN INTEGER,
                           pFolha              IN PKGPAG_TIPO.rFolha,
                           pEvento             IN PKGPAG_TIPO.tEvento,
                           pRubrica            IN PKGPAG_TIPO.tRubrica,
                           pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                           pParamPag           IN EPagAgrupamentoParametro%ROWTYPE,
                           pCEF                IN PKGPAG_TIPO.tCEF,
                           pCCO                IN PKGPAG_TIPO.tCCO,
                           pCCOSubst           IN PKGPAG_TIPO.tCCO,
                           pFUC                IN PKGPAG_TIPO.tFUC,
                           pFUCSubst           IN PKGPAG_TIPO.tFUC,
                           pAPO                IN PKGPAG_TIPO.tCEF,
                           pAPOSemParid        IN PKGPAG_TIPO.tCEF,
                           pBOL                IN PKGPAG_TIPO.tBOL,
                           pPensaoNaoPrev      IN PKGPAG_TIPO.tPensaoNaoPrev,
                           pPensaoPrev         IN PKGPAG_TIPO.tPensaoPrev,
                           pdtCalculo          IN DATE,
                           pFlCalcDefinitivo   IN CHAR DEFAULT PKGPAG_TIPO.cnN,
                           pFlPagaAdiantamento IN CHAR DEFAULT PKGPAG_TIPO.cnN) IS

vCdEstruturaCarreira    INTEGER;

BEGIN

  vCdEstruturaCarreira := NULL;

  --vValrPercentualTotal := 0;

  -- Inicializa variaveis do Vinculo. Pode ser feita para demais pacotes

  PKGPAG_EVCEFAPO.PInicializaVinculo;

  --

  PKGPAG_VAR.vgCdRubDifUmTercoFerias := NULL;

  PKGPAG_VAR.vgCdRubDevUmTercoFerias := NULL;

  IF pEvento.COUNT > 0 THEN

    FOR i IN pEvento.FIRST .. pEvento.LAST
    LOOP

      IF PKGPAG_EVENTO.FAceitaEvento (pEvento(i)) THEN

        PKGPAG_EVVINC.PProcessaEventosVinc (pVinculo            => pVinculo,
                                            pCdPessoa           => pCdPessoa,
                                            pFolha              => pFolha,
                                            pEvento             => pEvento(i),
                                            pRubrica            => pRubrica,
                                            pFormExpr           => pFormExpr,
                                            pCEF                => pCEF ,
                                            pCCO                => pCCO,
                                            pCCOSubst           => pCCOSubst,
                                            pFUC                => pFUC,
                                            pAPO                => pAPO,
                                            pBOL                => pBOL,
                                            pFlPagaAdiantamento => pFlPagaAdiantamento,
                                            pIndiceEvento       => i);

        IF pCEF.COUNT > 0 THEN

          -- Obtem o vCdEstruturaCarreira
          PKGPAG_EVCEFAPO.PProcessaEventosCEF (pVinculo             => pVinculo,
                                               pFolha               => pFolha,
                                               pEvento              => pEvento(i),
                                               pRubrica             => pRubrica,
                                               pFormExpr            => pFormExpr,
                                               pCEF                 => pCEF,
                                               pDtCalculo           => pDtCalculo,
                                               pCdEstruturaCarreira => vCdEstruturaCarreira);
           END IF;

           IF pCCO.COUNT > 0 THEN

             PKGPAG_EVCCOBOL.PProcessaEventosCCO (pVinculo             => pVinculo,
                                                  pFolha               => pFolha,
                                                  pEvento              => pEvento(i) ,
                                                  pRubrica             => pRubrica,
                                                  pFormExpr            => pFormExpr,
                                                  pParamPag            => pParamPag,
                                                  pCCO                 => pCCO,
                                                  pdtCalculo           => pDtCalculo,
                                                  pCdEstruturaCarreira => vCdEstruturaCarreira);

           END IF;

           IF pCCOSubst.COUNT > 0 THEN

             PKGPAG_EVCCOBOL.PProcessaEventosCCOSubst (pVinculo   => pVinculo,
                                                       pFolha     => pFolha,
                                                       pEvento    => pEvento(i),
                                                       pRubrica   => pRubrica,
                                                       pFormExpr  => pFormExpr,
                                                       pParamPag  => pParamPag,
                                                       pCCOSubst  => pCCOSubst,
                                                       pdtCalculo => pDtCalculo);

           END IF;

           IF pFUC.COUNT > 0 THEN

             PKGPAG_EVFUCPNP.PProcessaEventosFUC (pVinculo   => pVinculo,
                                                  pFolha     => pFolha,
                                                  pEvento    => pEvento(i),
                                                  pRubrica   => pRubrica,
                                                  pFormExpr  => pFormExpr,
                                                  pFUC       => pFUC,
                                                  pdtCalculo => pDtCalculo);

           END IF;

           IF pFUCSubst.COUNT > 0 THEN

             PKGPAG_EVFUCPNP.PProcessaEventosFUCSubst (pVinculo  => pVinculo,
                                                       pFolha    => pFolha,
                                                       pEvento   => pEvento(i),
                                                       pRubrica  => pRubrica,
                                                       pFormExpr => pFormExpr,
                                                       pFUCSubst => pFUCSubst );

           END IF;

           IF pPensaoNaoPrev.COUNT > 0 THEN

             PKGPAG_EVFUCPNP.PProcessaEventosPNP (pVinculo       => pVinculo,
                                                  pFolha         => pFolha,
                                                  pEvento        => pEvento(i),
                                                  pRubrica       => pRubrica,
                                                  pPensaoNaoPrev => pPensaoNaoPrev,
                                                  pdtCalculo     => pDtCalculo);
           END IF;

           IF pPensaoPrev.COUNT > 0 THEN

             PKGPAG_EVPENSAOPREVIDENCIARIA.PProcessaEventosPensaoPrev(
                                                  pVinculo       => pVinculo,
                                                  pFolha         => pFolha,
                                                  pEvento        => pEvento(i),
                                                  pRubrica       => pRubrica,
                                                  pFormExpr      => pFormExpr,
                                                  pPensaoPrev    => pPensaoPrev,
                                                  pdtCalculo     => pDtCalculo);
           END IF;

           IF pAPO.COUNT > 0 THEN

             PKGPAG_EVCEFAPO.PProcessaEventosAPO (pVinculo   => pVinculo,
                                                  pFolha     => pFolha,
                                                  pEvento    => pEvento(i),
                                                  pRubrica   => pRubrica,
                                                  pAPO       => pAPO,
                                                  pdtCalculo => pDtCalculo);

           END IF;

           IF pAPOSemParid.COUNT > 0 THEN

             PKGPAG_EVCEFAPO.PProcessaEventosAPOSemParid (pVinculo     => pVinculo,
                                                          pFolha       => pFolha,
                                                          pEvento      => pEvento(i),
                                                          pRubrica     => pRubrica,
                                                          pAPOSemParid => pAPOSemParid);
           END IF;

           IF pBOL.COUNT > 0 THEN

             PKGPAG_EVCCOBOL.PProcessaEventosBOL (pVinculo   => pVinculo,
                                                  pFolha     => pFolha,
                                                  pEvento    => pEvento(i),
                                                  pRubrica   => pRubrica,
                                                  pFormExpr  => pFormExpr,
                                                  pBOL       => pBol,
                                                  pdtCalculo => pDtCalculo);

           END IF;

        END IF;

     END LOOP;

   END IF;

END;

END PKGPAG_EVENTO;
/
