create or replace package PKGPAG_EVVINC is

  /*

     Tratamento de Eventos da Folha de Pagamento

     Todas as Relacoes de Vinculo

  */
  Procedure P085DevolucaoRemAtivEspecial (pFolha    IN PKGPAG_TIPO.rFolha,
                                          pRubrica  IN PKGPAG_TIPO.rRubrica,
                                          pCEF      IN PKGPAG_TIPO.tCEF,
                                          pCdVinculo IN INTEGER,
                                          pEventoGerado OUT BOOLEAN);

  PROCEDURE PProcessaEventosVinc(pVinculo            IN PKGPAG_TIPO.rVinculo,
                                 pCdPessoa           IN INTEGER,
                                 pFolha              IN PKGPAG_TIPO.rFolha,
                                 pEvento             IN PKGPAG_TIPO.rEvento,
                                 pRubrica            IN PKGPAG_TIPO.tRubrica,
                                 pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                                 pCEF                IN PKGPAG_TIPO.tCEF,
                                 pCCO                IN PKGPAG_TIPO.tCCO,
                                 pCCOSubst           IN PKGPAG_TIPO.tCCO,
                                 pFUC                IN PKGPAG_TIPO.tFUC,
                                 pAPO                IN PKGPAG_TIPO.tCEF,
                                 pBOL                IN PKGPAG_TIPO.tBOL,
                                 pFlPagaAdiantamento IN CHAR DEFAULT PKGPAG_TIPO.cnN,
                                 -- pVlPercentualTotal  IN OUT NUMBER,
                                 pIndiceEvento IN INTEGER);

  FUNCTION FServidorDesligadoMesFolha(pDataDesligamento DATE,
                                      pDataInicioMesFolha DATE,
                                      pDataFimMesFolha DATE) RETURN BOOLEAN;

  FUNCTION FDevolverAdnt13oServDesligado(pDataDesligamento DATE,
                                         pDataInicioMesFolha DATE,
                                         pDataFimMesFolha DATE,
                                         pDataInclusaoMotivoAfast DATE,
                                         pDataCalculoFolhaAnterior DATE,
                                         pDataCalculoFolhaAtual DATE) RETURN BOOLEAN;

  FUNCTION FPagarRescisao13oServDesligado(pDataDesligamento DATE,
                                          pDataInicioMesFolha DATE,
                                          pDataFimMesFolha DATE,
                                          pDataInclusaoMotivoAfast DATE,
                                          pDataCalculoFolhaAnterior DATE,
                                          pDataCalculoFolhaAtual DATE) RETURN BOOLEAN;


end PKGPAG_EVVINC;
/
create or replace package body PKGPAG_EVVINC is

 vVlRub1023 number(13,2) :=0;
 vCdFolhaNormal integer;

  FUNCTION FServidorDesligadoMesFolha(pDataDesligamento DATE, pDataInicioMesFolha DATE, pDataFimMesFolha DATE)
    RETURN BOOLEAN IS
    desligado BOOLEAN := FALSE;
  BEGIN
    IF pDataDesligamento BETWEEN pDataInicioMesFolha AND pDataFimMesFolha THEN
      desligado := TRUE;
    END IF;
    RETURN desligado;
  END;

  -- Verificar parametro da relacao de vinculo quanto ao direito ao 13zimo
  FUNCTION FPaga13PensaoNaoPrev
    RETURN BOOLEAN IS
    paga BOOLEAN := FALSE;
  BEGIN

    if pkgpag_var.vgpensaonaoprev.count > 0 then

       FOR i IN pkgpag_var.vgpensaonaoprev.FIRST .. pkgpag_var.vgpensaonaoprev.LAST LOOP

          if (pkgpag_var.vgpensaonaoprev(i).flpaga13 = 'S' or
              pkgpag_var.vgpensaonaoprev(i).fladianta13 = 'S') then

              paga := TRUE;

          end if;

      END LOOP;

    end if;

    RETURN paga;

    exception
      when others then
        null;
  END;


  FUNCTION FDevolverAdnt13oServDesligado(pDataDesligamento DATE,
                                         pDataInicioMesFolha DATE,
                                         pDataFimMesFolha DATE,
                                         pDataInclusaoMotivoAfast DATE,
                                         pDataCalculoFolhaAnterior DATE,
                                         pDataCalculoFolhaAtual DATE)
  RETURN BOOLEAN IS
    devolver BOOLEAN := false;
  BEGIN
    IF (FServidorDesligadoMesFolha(pDataDesligamento, pDataInicioMesFolha, pDataFimMesFolha) OR
        ((pDataDesligamento < pDataInicioMesFolha) AND
        (TRUNC(pDataInclusaoMotivoAfast) BETWEEN (pDataCalculoFolhaAnterior + 1) AND pDataCalculoFolhaAtual))) THEN
       devolver := TRUE;
    END IF;
    RETURN devolver;
  END;

  FUNCTION FPagarRescisao13oServDesligado(pDataDesligamento DATE,
                                          pDataInicioMesFolha DATE,
                                          pDataFimMesFolha DATE,
                                          pDataInclusaoMotivoAfast DATE,
                                          pDataCalculoFolhaAnterior DATE,
                                          pDataCalculoFolhaAtual DATE)
  RETURN BOOLEAN IS
    pagar BOOLEAN := false;
  BEGIN
    IF (FServidorDesligadoMesFolha(pDataDesligamento, pDataInicioMesFolha, pDataFimMesFolha) OR
        ((pDataDesligamento < pDataInicioMesFolha) AND
        (TRUNC(pDataInclusaoMotivoAfast) BETWEEN (pDataCalculoFolhaAnterior + 1) AND pDataCalculoFolhaAtual))) THEN
       pagar := TRUE;
    END IF;
    RETURN pagar;
  END;


  FUNCTION fPossuiAuxCreche (pCdVinculo IN INTEGER)
     RETURN BOOLEAN IS

     vAuxilio INTEGER := 0;

  BEGIN

     SELECT 1
       INTO vAuxilio
       FROM EBPCAUXILIOCRECHE C
       WHERE C.CdVinculo = pCdVinculo
         AND DtInicioVigencia <= PKGPAG_VAR.vgFolha.dtFimMes
         AND (DtFimVigencia >= PKGPAG_VAR.vgFolha.dtInicioMes OR
              dtfimvigencia IS NULL)
         AND FlAnulado = 'N'
         AND ROWNUM < 2;

      IF vAuxilio = 1
        THEN
          RETURN TRUE;
      ELSE
          RETURN FALSE;
      END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND
          THEN
            RETURN FALSE;
        WHEN OTHERS
          THEN
            RETURN FALSE;

  END;

  FUNCTION fPossuiFeriasConqNaoPaga (pCdVinculo   IN INTEGER,
                                     pFolha       IN PKGPAG_TIPO.rFolha,
                                     pRubrica     IN PKGPAG_TIPO.rRubrica,
                                     pCdRubricaPrev IN INTEGER,
                                     pFormExpr    IN PKGPAG_TIPO.tFormulaCalculo)
    RETURN BOOLEAN IS

  vNuMeses INTEGER;
  vCdExpressaoFormCalc INTEGER;
  vCont    INTEGER := 0;

  BEGIN

       BEGIN
       FOR FER IN (SELECT pf.dtinicio, pf.dtfim
                     FROM emovperiodoaquisitivoferias pf
                    WHERE PF.CdVinculo = pCdVinculo
                      AND PF.CdSituacaoPeriodoAqFerias = 2 -- conquistado
                      AND PF.DtFim <= pkgpag_var.vgFolha.DtFimMes
                      AND PF.DtInicio > pkgpag_var.vgcef(1).DtInicioRelacao
                      AND NOT EXISTS (SELECT 1
                                        FROM emovferiasfruicaousufruto ffu
                                       WHERE FFU.CdPeriodoAquisitivoFerias = PF.CdPeriodoAquisitivoFerias
                                         AND FFU.FlAnulado = 'N'
                                         AND FFU.DtInicial < pkgpag_var.vgFolha.DtFimMes))

        LOOP

           vNuMeses := NVL (pkgpag_fb.fmneuqtmesestrabano (pFolha => pkgpag_var.vgFolha,
                                                           pCdVinculo => pCdVinculo,
                                                           pdtiniciorelacao => FER.DtInicio,
                                                           pdtfimrelacao => FER.DtFim,
                                                           pdtcalculo => pkgpag_var.vgFolha.DtCalculo,
                                                           pFlPeriodoFerias => 'S'),0);

           IF vNuMeses > 0
             THEN

               vCont := vCont + 1;

               vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr,
                                                                              pRubrica.CdRubricaAgrupamento,
                                                                              0);

               PKGPAG_GERAL.PInsereLancamentoRelacao(
                       pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                       pCdVinculo            => pCdVinculo,
                       pCdRelacaoVinculo     => 1,
                       pCdHistRelacaoVinculo => pkgpag_var.vgcef(1).CdHistCargoEfetivo,
                       pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                       pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                       pVlIntegral           => NULL,
                       pVlProporcional       => NULL,
                       pNuSufixoRubrica      => vCont,
                       pNuParcelas           => 1,
                       pVlIndice             => vNuMeses,
                       pCdTipoOrigemRubrica  => 1);

           END IF;

        END LOOP;

         EXCEPTION
          WHEN NO_DATA_FOUND
            THEN
              pkgpag_var.vgNuDiasFeriasNaoPagas := 0;

          WHEN OTHERS
            THEN
              pkgpag_var.vgNuDiasFeriasNaoPagas := 0;

       END;

       pkgpag_var.vgNuDiasFeriasNaoPagas := vCont;

       BEGIN

       vCont := 0;

       FOR PREV IN (SELECT pf.dtinicio, pf.dtfim
                      FROM emovperiodoaquisitivoferias pf
                     WHERE PF.CdVinculo = pCdVinculo
                       AND PF.CdSituacaoPeriodoAqFerias = 1 -- Previstos
                       AND PF.DtInicio < pkgpag_var.vgcef(1).DtFim)
       LOOP

           vCont := vCont + 1;

           vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr,
                                                                          pCdRubricaPrev,
                                                                          0);

           vNuMeses := NVL (pkgpag_fb.fmneuqtmesestrabano (pFolha => pkgpag_var.vgFolha,
                                                           pCdVinculo => pCdVinculo,
                                                           pdtiniciorelacao => PREV.DtInicio,
                                                           pdtfimrelacao => PREV.DtFim,
                                                           pdtcalculo => pkgpag_var.vgFolha.DtCalculo,
                                                           pFlPeriodoFerias => 'S'),0);

            PKGPAG_GERAL.PInsereLancamentoRelacao(
                       pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                       pCdVinculo            => pCdVinculo,
                       pCdRelacaoVinculo     => 1,
                       pCdHistRelacaoVinculo => pkgpag_var.vgcef(1).CdHistCargoEfetivo,
                       pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                       pCdRubricaAgrupamento => pCdRubricaPrev,
                       pVlIntegral           => NULL,
                       pVlProporcional       => NULL,
                       pNuSufixoRubrica      => vCont,
                       pNuParcelas           => 1,
                       pVlIndice             => vNuMeses,
                       pCdTipoOrigemRubrica  => 1);

           /*PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                 pCdRubricaAgrupamento => pCdRubricaPrev,
                                                 pNuSufixoRubrica      => vCont,
                                                 pVlPagamento          => 1,
                                                 pVlIndice             => vNuMeses,
                                                 pCdTipoOrigemRubrica  => 1);     */

       END LOOP;

       pkgpag_var.vgNuDiasFeriasPrevistos := vCont;

        EXCEPTION
          WHEN NO_DATA_FOUND
            THEN
              pkgpag_var.vgNuDiasFeriasPrevistos := 0;

          WHEN OTHERS
            THEN
              pkgpag_var.vgNuDiasFeriasPrevistos := 0;

        END;

        IF nvl(pkgpag_var.vgNuDiasFeriasNaoPagas,0) + nvl(pkgpag_var.vgNuDiasFeriasPrevistos,0) > 0
          THEN
           RETURN TRUE;
        ELSE
           RETURN FALSE;
        END IF;

  END;

  FUNCTION fPossuiFeriasAnuladasPagas (pCdVinculo   IN INTEGER)

    RETURN BOOLEAN IS

    vCont    INTEGER := 0;
    vNuAnoMes integer;

  BEGIN

       select p.nuanomesreferencia
         into vNuAnoMes
         from epagfolhapagamento p
        where p.cdfolhapagamento = pkgpag_var.vgFolha.CdFolhapagamento;

       vCont := 0;

       select count (*)
         into vCont
         from emovperiodoaquisitivoferias a
         inner join emovferiasfruicaousufruto u on u.cdperiodoaquisitivoferias = a.cdperiodoaquisitivoferias
         inner join emovferiasfruicaopagamento p on p.cdperiodoaquisitivoferias = a.cdperiodoaquisitivoferias
         where a.cdvinculo= pCdVinculo
           and u.flanulado = pkgpag_tipo.cnS
           and p.nuanomesdevolucao = vNuAnoMes ;

        IF nvl(vCont,0) > 0
          THEN
           RETURN TRUE;
        ELSE
           RETURN FALSE;
        END IF;

        EXCEPTION
          WHEN NO_DATA_FOUND
            THEN
              vCont := 0;
              return false;

          WHEN OTHERS
            THEN
              vCont := 0;
              return false;

  END;

  PROCEDURE P002DescontoFaltaParcial(pCdVinculo   IN INTEGER,
                                     pFolha       IN PKGPAG_TIPO.rFolha,
                                     pRubrica     IN PKGPAG_TIPO.rRubrica,
                                     pCdTipoFalta IN INTEGER,
                                     pFormExpr    IN PKGPAG_TIPO.tFormulaCalculo,
                                     pCEF         IN PKGPAG_TIPO.tCEF,
                                     pCCO         IN PKGPAG_TIPO.tCCO,
                                     pCCOSubst    IN PKGPAG_TIPO.tCCO,
                                     pFUC         IN PKGPAG_TIPO.tFUC,
                                     pBOL         IN PKGPAG_TIPO.tBOL,
                                     pAPO         IN PKGPAG_TIPO.tCEF) IS

    --cFalta TYPES.ref_cursor;

    vNuFalta INTEGER;

  BEGIN

    /*
    PKGMOV.PQtFalta (pCdVinculo    => pCdVinculo,
                     pDtInicio     => PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao,
                     pDtFim        => PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao,
                     pFlTipoFalta  => 'P',
                     pFlRegime     => 'J',
                     pFlTipoSaida  => 'R',
                     pCdTipoFalta  => pCdTipoFalta,
                     Resultado     => cFalta);

    FETCH cFalta INTO vNuFalta;

    CLOSE cFalta;
    */

    vNuFalta := PKGMOVFRE.FQtOcorFaltaParcial(pCdTipoFaltaParcial => pCdTipoFalta,
                                              pVetorFaltas        => PKGPAG_VAR.vgFaltas);

    IF vNuFalta > 0 THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- Formula de calculo
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => pCCO,
                                           pCCOSubst            => pCCOSubst,
                                           pFUC                 => pFUC,
                                           pBOL                 => pBOL,
                                           pAPO                 => pAPO,
                                           pVlIndice            => vNuFalta,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 7);

    END IF;

  END;

  PROCEDURE P006AdicionalTempoServico(pCdVinculo IN INTEGER,
                                      pFolha     IN PKGPAG_TIPO.rFolha,
                                      pEvento    IN PKGPAG_TIPO.rEvento,
                                      pRubrica   IN PKGPAG_TIPO.rRubrica,
                                      pCEF       IN PKGPAG_TIPO.tCEF,
                                      pCCO       IN PKGPAG_TIPO.tCCO,
                                      pCCOSubst  IN PKGPAG_TIPO.tCCO,
                                      pFUC       IN PKGPAG_TIPO.tFUC,
                                      pBOL       IN PKGPAG_TIPO.tBOL,
                                      pAPO       IN PKGPAG_TIPO.tCEF,
                                      pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo /*,
                                                                                                                pVlPercentualTotal IN OUT NUMBER*/) IS

    vVlPercentDireito NUMBER(7, 4);

    vNuCHOPago        NUMBER(7,4);

    vvlCHOaPagar      INTEGER;

    i INTEGER;

    PROCEDURE PObtemCHO IS

      vNuCHOPagoAux       NUMBER(7,4);

      vNuCHORelacaoAux    NUMBER(7,4);

      vNuCHOAux           NUMBER(7,4);

      vCdOrgaoExercicio   INTEGER;

    BEGIN

      vNuCHOPago := 0;

      vNuCHOPagoAux := 0;

      IF (PKGPAG_VAR.vgVinculo.FlOutroVincCalculado = 'S' OR
          PKGPAG_VAR.vgVinculo.FlOutroVincACalcular = 'S') THEN

        FOR vHistRub IN (SELECT V.CdVinculo,
                                FP.CdAgrupamento,
                                FP.CdOrgao,
                                FP.CdFolhaPagamento,
                                HRV.VlPagamento
                           FROM EPagHistoricoRubricaVinculo HRV
                          INNER JOIN ECadVinculo V
                             ON V.CdVinculo = HRV.CdVinculo
                          INNER JOIN EPagFolhaPagamento FP
                             ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
                          INNER JOIN EPagTipoFolhaPagamento TFP
                             ON TFP.CdTipoFolhaPagamento =
                                FP.CdTipoFolhaPagamento
                          INNER JOIN EPagRubricaAgrupamento RA
                             ON RA.CdRubricaAgrupamento =
                                HRV.CdRubricaAgrupamento
                          INNER JOIN EPagRubrica R
                             ON R.CdRubrica = RA.CdRubrica
                            AND R.CdTipoRubrica = pRubrica.CdTipoRubrica
                            AND R.NuRubrica = pRubrica.NuRubrica
                          WHERE V.CdPessoa = PKGPAG_VAR.vgVinculo.CdPessoa
                            AND V.CdVinculo <> pCdVinculo
                            AND (HRV.cdFolhaPagamento <> pFolha.CdFolhaPagamento OR
                                 (HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                                  V.NuSeqMatricula < PKGPAG_VAR.vgVinculo.NuSeqMatricula))
                            AND FP.NuAnoReferencia = pFolha.NuAnoReferencia
                            AND FP.NuMesReferencia = pFolha.NuMesReferencia
                            AND (
                                (FP.CdFolhaPagamento = pFolha.CdFolhaPagamento) OR
                                (FP.CdTipoCalculo =
                                PKGPAG_TIPO.cnTpCalculoNormal AND
                                FP.CdOrgao <> pFolha.CdOrgao AND
                                FP.FlCalculoDefinitivo =
                                DECODE(PKGPAG_GERAL.FVisaoCalculo(pFolha.CdTipoCalculo,
                                                                  pFolha.FlCalculoDefinitivo),
                                         'S',
                                         'S',
                                         FP.FlCalculoDefinitivo)) OR
                                (FP.CdTipoCalculo =
                                PKGPAG_TIPO.cnTpCalculoSupl AND
                                FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS))) LOOP

        -- Verifica se este vinculo possui um ACT

        BEGIN

          SELECT CdOrgaoExercicio
            INTO vCdOrgaoExercicio
            FROM ECADHistCargoEfetivo CEF
           WHERE CEF.CdVinculo = vHistRub.CdVinculo AND
                 CEF.CdRelacaoTrabalho = PKGPAG_TIPO.cnRelACT AND
                 CEF.DtInicio <= pFolha.DtFimMes AND
                 (CEF.DtFim >= pFolha.DtInicioMes OR CEF.DtFim IS NULL) AND
                 ROWNUM < 2;

             --Busca o valor da carga horaria nos contra-cheques do SIRH
             vNuCHOPagoAux := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => vHistRub.CdFolhaPagamento,
                                                                pCdVinculo        => vHistRub.CdVinculo,
                                                                pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(vHistRub.CdAgrupamento,
                                                                                      9,
                                                                                      257));

          -- Caso nao encontre, procura a capa de pagamento que e gerada pelo SIGRH

           IF vNuCHOPagoAux = 0 THEN

            vNuCHORelacaoAux := 0;

            vNuCHOAux := 0;

            BEGIN

              SELECT CH.NuCHORelacao, CH.NuCHO
                INTO vNuCHORelacaoAux, vNuCHOAux
                FROM EPagCapaHistrubricaVinculo CH
               WHERE CH.CdFolhaPagamento = vHistRub.CdFolhaPagamento
                 AND CH.Cdvinculo = vHistRub.CdVinculo;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                NULL;

            END;

            -- CHO completa

            IF vNuCHOAux <> 0 THEN

              IF vNuCHORelacaoAux >= vNuCHOAux THEN

                vNuCHOPagoAux := 40;

              ELSE

                vNuCHOPagoAux := vNuCHORelacaoAux;

              END IF;

            END IF;

          END IF;

          vNuCHOPago := vNuCHOPago + vNuCHOPagoAux;

          EXCEPTION

           WHEN NO_DATA_FOUND THEN

             NULL;

          END ;

        END LOOP;

      END IF;

    END;

    FUNCTION FRetornaPercentDireito

     RETURN NUMBER IS

      vVlPercentual NUMBER(7, 4);

      vVlPecentMaxAcum NUMBER(7, 4);

    BEGIN

      vVlPercentual := 0;

      IF PKGPAG_VAR.vgParamATSAcum.COUNT > 0 THEN

        /*Conta os periodos aquisitivos conquistados e sumariza os percentuais de direito */

        FOR vTS IN (SELECT PA.CdRegraTipoAdicionalTempServ,
                           PA.VlPercentualDireito,
                           PA.DtFimConquista
                      FROM EPagPeriodoAquistempServ PA
                     INNER JOIN EBpcRegraTipoAdicionalTempServ RTS
                        ON PA.CdRegraTipoAdicionalTempServ =
                           RTS.CdRegraTipoAdicionalTempServ
                     WHERE PA.CdVinculo = pCdVinculo
                       AND PA.DtFimConquista <= pFolha.DtFimMes
                       AND (PA.DtFimConquista >=
                           pEvento.DtInicioConquistaPerAquis AND
                           (PA.DtFimConquista <=
                           pEvento.DtFimConquistaPerAquis OR
                           pEvento.DtFimConquistaPerAquis IS NULL))
                       AND RTS.CdTipoAdicionalTempServ =
                           pEvento.CdTipoTempoServico
                       AND PA.CdSituacaoPerAquisitivo = 2
                       AND PA.FlPago = PKGPAG_TIPO.cnS) -- Conquistado
         LOOP

          -- Busca no parametro de acumulacao o percentual maximo permitido de
          -- acordo com a data da conquista

          i := PKGPAG_VAR.vgParamATSAcum.FIRST;

          WHILE i <= PKGPAG_VAR.vgParamATSAcum.LAST LOOP

            IF pEvento.CdTipoTempoServico = PKGPAG_VAR.vgParamATSAcum(i).CdTipoAdicionalTempServ AND
               vTS.DtFimConquista >= PKGPAG_VAR.vgParamATSAcum(i).DtConquista THEN

              vVlPecentMaxAcum := PKGPAG_VAR.vgParamATSAcum(i).VlPercentMaxAcum;

              EXIT;

            END IF;

            i := PKGPAG_VAR.vgParamATSAcum.NEXT(i);

          END LOOP;

          IF vTS.DtFimConquista BETWEEN pFolha.DtInicioMes AND
             pFolha.DtFimMes AND pFolha.CdAgrupamento <> 2 THEN

            vTS.VlPercentualDireito := (vTS.VlPercentualDireito /
                                       TO_CHAR(pFolha.DtFimMes, 'DD')) *
                                       (TO_CHAR(pFolha.DtFimMes, 'DD') -
                                       TO_CHAR(vTS.DtFimConquista, 'DD') + 1);

          END IF;

          IF (PKGPAG_VAR.vPercentualTotalATS(pEvento.CdTipoTempoServico) +
             VTS.VlPercentualDireito) <= NVL(vVlPecentMaxAcum, 999) THEN

            -- IF pEvento.CdTipoTempoServico <> 35 THEN

            PKGPAG_VAR.vPercentualTotalATS(pEvento.CdTipoTempoServico) := PKGPAG_VAR.vPercentualTotalATS(pEvento.CdTipoTempoServico) +
                                                                          VTS.VlPercentualDireito;

            --  END IF;

            vVlPercentual := vVlPercentual + VTS.VlPercentualDireito;

          END IF;

        END LOOP;

      END IF;

      RETURN vVlPercentual;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

  BEGIN

    vVlPercentDireito := FRetornaPercentDireito;

    IF vVlPercentDireito > 0 THEN

      -- SED: ACT
      IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT THEN

        PKGPAG_GERAL.PArmazenaCHO;

        PObtemCHO;

        -- Verifica se tem carga horaria maior que 40h
        IF pFolha.CdOrgao = 41 AND
            vNuCHOPago + pkgpag_var.vgRelVincPrincipal.nuCHORelacao > 40 THEN

             -- Limita a soma das cargas horarias dos vinculos de um servido em 40h para o calculo do trienio
            IF vNuCHOPago < 40 THEN
              vvlCHOaPagar := ABS(40 - vNuCHOPago);
        vVlPercentDireito := vVlPercentDireito*(vvlCHOaPagar/PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao);
            ELSE
              vvlCHOaPagar := 0;
     vVlPercentDireito := 0;
            END IF;

        ELSIF vnuCHOPago > 0 AND vnuCHOPago < 40 THEN

          vvlCHOaPagar := (40 - vnuCHOPago);

          IF vvlCHOaPagar < PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao THEN

            vVlPercentDireito := vVlPercentDireito*(vvlCHOaPagar/PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao);

          END IF;

        else
          null;
        END IF;

      END IF;

      PKGPAG_VAR.vgPercentAcumATS(pEvento.CdTipoTempoServico) := PKGPAG_VAR.vgPercentAcumATS(pEvento.CdTipoTempoServico) +
                                                                 vVlPercentDireito;

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2,
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => pCCO,
                                           pCCOSubst            => pCCOSubst,
                                           pFUC                 => pFUC,
                                           pBOL                 => pBOL,
                                           pAPO                 => pAPO,
                                           pVlIndice            => vVlPercentDireito,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 6);

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Erro ao processar Adicional de Tempo de Serviço.',
                              PKGPAG_VAR.vgCdVinculo);

  END;

 PROCEDURE P006AdicionalTempoServicoDPE(pCdVinculo IN INTEGER,
                                        pFolha     IN PKGPAG_TIPO.rFolha,
                                        pEvento    IN PKGPAG_TIPO.rEvento,
                                        pRubrica   IN PKGPAG_TIPO.rRubrica,
                                        pCEF       IN PKGPAG_TIPO.tCEF,
                                        pCCO       IN PKGPAG_TIPO.tCCO,
                                        pCCOSubst  IN PKGPAG_TIPO.tCCO,
                                        pFUC       IN PKGPAG_TIPO.tFUC,
                                        pBOL       IN PKGPAG_TIPO.tBOL,
                                        pAPO       IN PKGPAG_TIPO.tCEF,
                                        pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo) IS

   --vVlindiceATS     NUMBER(7, 4);
   vVlindiceATSAnt  NUMBER(7, 4);
   vVlindiceATSMes  NUMBER(7, 4);
   vVlPecentMaxAcum NUMBER(7, 4);
   vNuDiasATSAnt NUMBER(7,4);
   vNuDiasATSMes NUMBER(7,4);
   vDtfimconquista  DATE;

   i INTEGER;
   j INTEGER;

 BEGIN

   vVlindiceATSAnt := 0;
   vVlindiceATSMes := 0;
   vDtfimconquista := NULL;
   vNuDiasATSAnt := 0;
   vNuDiasATSMes := 0;

   j := 0;

   IF PKGPAG_VAR.vgParamATSAcum.COUNT > 0 THEN

     -- Busca no parametro de acumulacao o percentual maximo permitido de
     -- acordo com a data da conquista
     i := PKGPAG_VAR.vgParamATSAcum.FIRST;

     WHILE i <= PKGPAG_VAR.vgParamATSAcum.LAST LOOP

       vVlPecentMaxAcum := PKGPAG_VAR.vgParamATSAcum(i).VlPercentMaxAcum;
       i                := PKGPAG_VAR.vgParamATSAcum.NEXT(i);

     END LOOP;

     /*Conta os periodos aquisitivos conquistados  e sumariza os percentuais de direito */
     FOR vTS IN (SELECT PA.CdRegraTipoAdicionalTempServ,
                        PA.VlPercentualDireito,
                        PA.DtFimConquista
                   FROM EPagPeriodoAquistempServ PA
                  INNER JOIN EBpcRegraTipoAdicionalTempServ RTS
                     ON PA.CdRegraTipoAdicionalTempServ =
                        RTS.CdRegraTipoAdicionalTempServ
                  WHERE PA.CdVinculo = pCdVinculo
                    AND PA.DtFimConquista <= pFolha.DtFimMes
                    AND (PA.DtFimConquista >=
                        pEvento.DtInicioConquistaPerAquis AND
                        (PA.DtFimConquista <=
                        pEvento.DtFimConquistaPerAquis OR
                        pEvento.DtFimConquistaPerAquis IS NULL))
                    AND RTS.CdTipoAdicionalTempServ =
                        pEvento.CdTipoTempoServico
                    AND PA.CdSituacaoPerAquisitivo = 2
                    AND PA.FlPago = PKGPAG_TIPO.cnS
                  ORDER BY PA.Dtfimconquista)

      LOOP

       -- Busca no parametro de acumulacao o percentual maximo permitido de
       -- acordo com a data da conquista
       i := PKGPAG_VAR.vgParamATSAcum.FIRST;

       WHILE i <= PKGPAG_VAR.vgParamATSAcum.LAST LOOP

         IF pEvento.CdTipoTempoServico = PKGPAG_VAR.vgParamATSAcum(i)
           .CdTipoAdicionalTempServ AND
            vTS.DtFimConquista >= PKGPAG_VAR.vgParamATSAcum(i).DtConquista THEN

           vVlPecentMaxAcum := PKGPAG_VAR.vgParamATSAcum(i).VlPercentMaxAcum;

           EXIT;

         END IF;

         i := PKGPAG_VAR.vgParamATSAcum.NEXT(i);

       END LOOP;

       -- Soma os índices conquistados antes do mes da folha
       IF vTS.Dtfimconquista < pFOlha.DtInicioMes THEN

         vVlindiceATSAnt := vVlindiceATSAnt + vTS.Vlpercentualdireito;

       ELSIF vTS.Dtfimconquista BETWEEN trunc(pFOlha.DtInicioMes) AND trunc(pFolha.DtFimMes)
         THEN

         vVlindiceATSMes := vVlindiceATSAnt + vTS.Vlpercentualdireito + vVlindiceATSMes;
         vDtfimconquista := vTS.Dtfimconquista;

         vNuDiasATSMes := LEAST((TO_CHAR(pFolha.DtFimMes, 'DD')), 30) - LEAST((TO_CHAR(vDtFimConquista, 'DD')), 30) +1;
         vNuDiasATSAnt := 30 - vNuDiasATSMes;

        IF to_char(vDtfimconquista,'mm') = '02' then vNuDiasATSMes := 30; END IF;

       else
         null;
       END IF;

     END LOOP;


     IF vVlindiceATSAnt > 0 THEN

        j := j + 1;
       pkgpag_var.vgPercentATS(j).cdrubricaagrupamento := pRUbrica.CdRubricaAgrupamento;
       pkgpag_var.vgPercentATS(j).vlindiceATS := vVlindiceATSAnt;

       IF vDtfimconquista BETWEEN trunc(pFolha.DtInicioMes) AND trunc(pFolha.DtFimMes) THEN

         vVlindiceATSAnt := (vVlindiceATSAnt / 30) * vNuDiasATSAnt;

       END IF;

       PKGPAG_VAR.vgPercentAcumATS(pEvento.CdTipoTempoServico) := PKGPAG_VAR.vgPercentAcumATS(pEvento.CdTipoTempoServico) +
                                                                  vVlindiceATSAnt;

       PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2,
                                            pFolha               => pFolha,
                                            pCdVinculo           => pCdVinculo,
                                            pRubrica             => pRubrica,
                                            pFormExpr            => pFormExpr,
                                            pFlPrincipal         => PKGPAG_TIPO.cnN,
                                            pCEF                 => pCEF,
                                            pCCO                 => pCCO,
                                            pCCOSubst            => pCCOSubst,
                                            pFUC                 => pFUC,
                                            pBOL                 => pBOL,
                                            pAPO                 => pAPO,
                                            pVlIndice            => vVlindiceATSAnt,
                                            pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                            pNuSufixo            => j,
                                            pCdTipoOrigemRubrica => 6);

     END IF;

     IF vVlindiceATSMes > 0 THEN

        j := j + 1;
       pkgpag_var.vgPercentATS(j).cdrubricaagrupamento := pRUbrica.CdRubricaAgrupamento;
       pkgpag_var.vgPercentATS(j).vlIndiceATS := vVlindiceATSMes;

       IF vDtfimconquista BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes THEN

         vVlindiceATSMes := (vVlindiceATSMes / 30) * vNuDiasATSMes;

       END IF;

       PKGPAG_VAR.vgPercentAcumATS(pEvento.CdTipoTempoServico) := PKGPAG_VAR.vgPercentAcumATS(pEvento.CdTipoTempoServico) +
                                                                  vVlindiceATSMes;

       PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2,
                                            pFolha               => pFolha,
                                            pCdVinculo           => pCdVinculo,
                                            pRubrica             => pRubrica,
                                            pFormExpr            => pFormExpr,
                                            pFlPrincipal         => PKGPAG_TIPO.cnN,
                                            pCEF                 => pCEF,
                                            pCCO                 => pCCO,
                                            pCCOSubst            => pCCOSubst,
                                            pFUC                 => pFUC,
                                            pBOL                 => pBOL,
                                            pAPO                 => pAPO,
                                            pVlIndice            => vVlindiceATSMes,
                                            pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                            pNuSufixo            => j,
                                            pCdTipoOrigemRubrica => 6);

     END IF;
    -- END LOOP;

   END IF;

 EXCEPTION

   WHEN OTHERS THEN

     PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                             PKGPAG_VAR.vCdHistParamCalc,
                             PKGPAG_VAR.vCdPessoa,
                             'Erro ao processar Adicional de Tempo de Serviço.',
                             PKGPAG_VAR.vgCdVinculo);

 END;

  /*-----------------------------------------------------------------------------------------/
  --     Procedure : P024RemuneracaoRisco
  --      Objetivo : Gerar a remuneracao de insalubridade
  --
  --         Nota :
  /*-----------------------------------------------------------------------------------------*/
  PROCEDURE P024RemuneracaoRisco(pCdVinculo   IN INTEGER,
                                 pFolha       IN PKGPAG_TIPO.rFolha,
                                 pRubrica     IN PKGPAG_TIPO.rRubrica,
                                 pFormExpr    IN PKGPAG_TIPO.tFormulaCalculo,
                                 pCdTipoRisco IN INTEGER) IS

    vVlIndice NUMBER(7, 4);

    vNuDias INTEGER;

    vNuDiasMes INTEGER;

    vCdExpressaoFormCalc INTEGER;

    CURSOR cRelCEF(pCdVinculo   IN INTEGER,
                   pDtInicioMes IN DATE,
                   pDtFimMes    IN DATE) IS

      SELECT 1 AS CdTipoRelacao,
             CEF.CdHistCargoEfetivo,
             CEF.CdOrgaoExercicio,
             CEF.CdNaturezaVinculo,
             CEF.CdRelacaoTrabalho,
             CEF.CdRegimetrabalho,
             V.CdRegimePrevidenciario,
             HSP.CdSituacaoPrevidenciaria,
             CEF.CdEstruturaCarreira,
             EC.CdEstruturaCarreiraCarreira,
             CEF.FlEfetivacao,
             LT.CdUnidadeOrganizacional,
             RVA.CdUnidOrgAtividade,
             CASE
               WHEN LT.DtInicio <= pDtInicioMes THEN
                pDtInicioMes
               ELSE
                LT.DtInicio
             END DtInicio,
             CASE
               WHEN LT.DtFim >= pDtFimMes OR LT.DtFim IS NULL THEN
                pDtFimMes
               ELSE
                LT.DtFim
             END DtFim,
             CASE
               WHEN RVA.DtInicioValidade <= pDtInicioMes THEN
                pDtInicioMes
               ELSE
                RVA.DtInicioValidade
             END DtInicioAtividade,
             CASE
               WHEN RVA.DtFimValidade >= pDtFimMes OR
                    RVA.DtFimValidade IS NULL THEN
                pDtFimMes
               ELSE
                RVA.DtFimValidade
             END DtFimAtividade
        FROM ECadVinculo V
       INNER JOIN ECadHistCargoEfetivo CEF
          ON V.CdVinculo = CEF.CdVinculo
       INNER JOIN ECadHistSitPrevVinculo HSP
          ON CEF.CdVinculo = HSP.CdVinculo
         AND (CEF.DtInicio BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       INNER JOIN (SELECT LT.CdHistCargoEfetivo, MAX(DtInicio) AS DtInicio
                     FROM eCadLocalTrabalho LT
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                      AND LT.DtInicio <= pDtFimMes
                      AND LT.CdHistCargoEfetivo IS NOT NULL
                    GROUP BY LT.CdHistCargoEfetivo) LT1
          ON LT1.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo
       INNER JOIN ECadLocalTrabalho LT
          ON LT.CdHistCargoEfetivo = LT1.CdHistCargoEfetivo
         AND LT.DtInicio = LT1.DtInicio
         AND LT.flAnulado = PKGPAG_TIPO.cnN
       INNER JOIN ECadEstruturaCarreira EC
          ON CEF.CdEstruturaCarreira = EC.CdEstruturaCarreira
        LEFT JOIN (SELECT CdVinculo,
                          CdHistCargoEfetivo,
                          UOA.CdUnidOrgAtividade,
                          RVA.DtInicioValidade,
                          RVA.DtFimValidade
                     FROM ECadRelacaoVincAtividade RVA
                     LEFT JOIN ECadUnidOrgAtividade UOA
                       ON RVA.CdUnidadeorganizacional =
                          UOA.CdUnidadeorganizacional
                      AND RVA.CdAtividade = UOA.CdAtividade
                      AND RVA.CdVinculo = pCdVinculo
                      AND (RVA.DtInicioValidade <= pDtFimMes AND
                          RVA.DtFimValidade >= pDtInicioMes OR
                          RVA.DtFimValidade IS NULL)) RVA
          ON RVA.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo
       WHERE V.CdVinculo = pCdVinculo
         AND CEF.DtInicio <= pDtFimMes
         AND (CEF.DtFim >= pDtInicioMes OR CEF.DtFim IS NULL)
         AND CEF.FlAnulado = PKGPAG_TIPO.cnN
         AND pFolha.CdTipoFolha <> pkgpag_tipo.cnTpFolhaInstPensao

       UNION ALL

       SELECT 1 AS CdTipoRelacao,
             CEF.CdHistCargoEfetivo,
             CEF.CdOrgaoExercicio,
             CEF.CdNaturezaVinculo,
             CEF.CdRelacaoTrabalho,
             CEF.CdRegimetrabalho,
             V.CdRegimePrevidenciario,
             HSP.CdSituacaoPrevidenciaria,
             CEF.CdEstruturaCarreira,
             EC.CdEstruturaCarreiraCarreira,
             CEF.FlEfetivacao,
             LT.CdUnidadeOrganizacional,
             RVA.CdUnidOrgAtividade,
             CASE
               WHEN LT.DtInicio <= pDtInicioMes THEN
                pDtInicioMes
               ELSE
                LT.DtInicio
             END DtInicio,
             pDtFimMes AS DtFim,
             CASE
               WHEN RVA.DtInicioValidade <= pDtInicioMes THEN
                pDtInicioMes
               ELSE
                RVA.DtInicioValidade
             END DtInicioAtividade,
             CASE
               WHEN RVA.DtFimValidade >= pDtFimMes OR
                    RVA.DtFimValidade IS NULL THEN
                pDtFimMes
               ELSE
                RVA.DtFimValidade
             END DtFimAtividade
        FROM ECadVinculo V
       INNER JOIN ECadHistCargoEfetivo CEF
          ON V.CdVinculo = CEF.CdVinculo
       INNER JOIN ECadHistSitPrevVinculo HSP
          ON CEF.CdVinculo = HSP.CdVinculo
         AND (CEF.DtInicio BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       INNER JOIN (SELECT LT.CdHistCargoEfetivo, MAX(DtInicio) AS DtInicio
                     FROM eCadLocalTrabalho LT
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                      AND LT.DtInicio <= pDtFimMes
                      AND LT.CdHistCargoEfetivo IS NOT NULL
                    GROUP BY LT.CdHistCargoEfetivo) LT1
          ON LT1.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo
       INNER JOIN ECadLocalTrabalho LT
          ON LT.CdHistCargoEfetivo = LT1.CdHistCargoEfetivo
         AND LT.DtInicio = LT1.DtInicio
         AND LT.flAnulado = PKGPAG_TIPO.cnN
       INNER JOIN ECadEstruturaCarreira EC
          ON CEF.CdEstruturaCarreira = EC.CdEstruturaCarreira
        LEFT JOIN (SELECT CdVinculo,
                          CdHistCargoEfetivo,
                          UOA.CdUnidOrgAtividade,
                          RVA.DtInicioValidade,
                          RVA.DtFimValidade
                     FROM ECadRelacaoVincAtividade RVA
                     LEFT JOIN ECadUnidOrgAtividade UOA
                       ON RVA.CdUnidadeorganizacional =
                          UOA.CdUnidadeorganizacional
                      AND RVA.CdAtividade = UOA.CdAtividade
                      AND RVA.CdVinculo = pCdVinculo
                      AND (RVA.DtInicioValidade <= pDtFimMes AND
                          RVA.DtFimValidade >= pDtInicioMes OR
                          RVA.DtFimValidade IS NULL)) RVA
          ON RVA.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo
       INNER JOIN Eafaregistroobito o  on o.cdpessoa = v.cdpessoa
       WHERE V.CdVinculo = pCdVinculo
         AND CEF.DtInicio <= pDtFimMes
         AND CEF.DtFim = o.dtobito-1
         AND CEF.FlAnulado = PKGPAG_TIPO.cnN
         AND pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaInstPensao
         and o.flanulado = PKGPAG_TIPO.cnN;

    CURSOR cRelCCO(pCdVinculo   IN INTEGER,
                   pDtInicioMes IN DATE,
                   pDtFimMes    IN DATE) IS
      SELECT 2 AS CdTipoRelacao,
             CCO.CdHistCargoCom,
             CCO.CdOrgaoExercicio,
             CCO.CdCargoComissionado,
             C.CdGrupoOcupacional,
             CCO.CdNaturezaVinculo,
             CCO.CdRelacaoTrabalho,
             CCO.CdRegimetrabalho,
             CCO.CdRegimePrevidenciario,
             HSP.CdSituacaoPrevidenciaria,
             CCO.CdOpcaoRemuneracao,
             CCO.FlTipoProvimento,
             LT.CdUnidadeOrganizacional,
             CASE
               WHEN LT.DtInicio <= pDtInicioMes THEN
                pDtInicioMes
               ELSE
                LT.DtInicio
             END DtInicio,
             CASE
               WHEN LT.DtFim >= pDtFimMes OR LT.DtFim IS NULL THEN
                pDtFimMes
               ELSE
                LT.DtFim
             END DtFim
        FROM ECadHistCargoCom CCO
       INNER JOIN ECadHistSitPrevVinculo HSP
          ON CCO.CdVinculo = HSP.CdVinculo
         AND (CCO.DtInicio BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       INNER JOIN ECadCargoComissionado C
          ON CCO.CdCargoComissionado = C.CdCargoComissionado
       INNER JOIN (SELECT LT.CdHistCargoCom, MAX(dtInicio) AS DtInicio
                     FROM ecadLocalTrabalho LT
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                      AND LT.Cdhistcargocom IS NOT NULL
                      AND LT.DtInicio <= PKGPAG_VAR.vDtCalculo
                    GROUP BY LT.CdHistCargoCom) LT1
          ON LT1.CdHistCargoCom = CCO.CdHistCargoCom
       INNER JOIN Ecadlocaltrabalho LT
          ON LT.CdHistCargoCom = LT1.CdHistCargoCom
         AND LT.Dtinicio = LT1.DtInicio
       WHERE CCO.CdVinculo = pCdVinculo
         AND CCO.DtInicio <= pDtFimMes
         AND (CCO.DtFim >= pDtInicioMes OR CCO.DtFim IS NULL)
         AND CCO.Flanulado = PKGPAG_TIPO.cnN;

    CURSOR cRelFUC(pCdVinculo   IN INTEGER,
                   pDtInicioMes IN DATE,
                   pDtFimMes    IN DATE) IS
      SELECT 3 AS CdTipoRelacao,
             FUC.CdHistFuncaoChefia,
             FUC.CdOrgaoExercicio,
             FUC.CdFuncaoChefia,
             V.CdRegimePrevidenciario,
             LT.CdUnidadeOrganizacional,
             FUC.FlEfetivacao,
             CASE
               WHEN LT.DtInicio <= pDtInicioMes THEN
                pDtInicioMes
               ELSE
                LT.DtInicio
             END DtInicio,
             CASE
               WHEN LT.DtFim >= pDtFimMes OR LT.DtFim IS NULL THEN
                pDtFimMes
               ELSE
                LT.DtFim
             END DtFim
        FROM ECadHistFuncaoChefia FUC
       INNER JOIN (SELECT LT.CdHistFuncaoChefia, MAX(DtInicio) AS DtInicio
                     FROM eCadLocalTrabalho LT
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.CdHistFuncaoChefia IS NOT NULL
                      AND LT.DtInicio <= PKGPAG_VAR.vDtCalculo
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                    GROUP BY LT.CdHistFuncaoChefia) LT1
          ON LT1.CdHistFuncaoChefia = FUC.CdHistFuncaoChefia
       INNER JOIN ECadLocalTrabalho LT
          ON LT.CdHistFuncaoChefia = LT1.CdHistFuncaoChefia
         AND LT.DtInicio = LT1.DtInicio
       INNER JOIN ECadVinculo V
          ON V.CdVinculo = FUC.CdVinculo
       WHERE FUC.CdVinculo = pCdVinculo
         AND FUC.DtInicio <= pDtFimMes
         AND (FUC.InPagamento = 'D' OR FUC.InPagamento IS NULL)
         AND (FUC.DtFim >= pDtInicioMes OR FUC.DtFim IS NULL)
         AND FUC.Flanulado = PKGPAG_TIPO.cnN;

    CURSOR cRelAPO(pCdVinculo   IN INTEGER,
                   pDtInicioMes IN DATE,
                   pDtFimMes    IN DATE) IS
      SELECT 4 AS CdTipoRelacao,
             CA.CdVinculo,
             CA.CdConcessaoAposentadoria,
             CA.CdOrgaoExercicio,
             V.CdRegimePrevidenciario,
             V.CdSituacaoPrevidenciaria,
             V.CdRegimeTrabalho,
             0 AS CdEstruturaCarreira,
             0 AS CdEstruturaCarreiraCarreira,
             CA.CdUnidadeOrganizacional,
             CASE
               WHEN CA.DtInicioAposentadoria < pdtInicioMes THEN
                pdtInicioMes
               ELSE
                CA.DtInicioAposentadoria
             END AS DtInicio,
             CASE
               WHEN CA.DtFimAposentadoria IS NULL AND
                    CA.DtInicioAposentadoria BETWEEN pdtInicioMes AND
                    pdtFimMes THEN
                CASE
                  WHEN TO_CHAR(CA.DtInicioAposentadoria, 'MM') = 2 THEN
                   pdtFimMes
                  WHEN TO_CHAR(pdtFimMes, 'DD') > 30 THEN
                   pdtFimMes - 1
                  ELSE
                   pdtFimMes
                END
               WHEN CA.DtFimAposentadoria IS NULL OR
                    CA.DtFimAposentadoria > pdtFimMes THEN
                pdtFimMes
               ELSE
                CA.DtFimAposentadoria
             END AS DtFim,
             CA.VlPercentPropAPO,
             CA.FlOrigemCCO
        FROM EpvdConcessaoAposentadoria CA
       INNER JOIN ECadVinculo V
          ON CA.CdVinculo = V.CdVinculo
       INNER JOIN EPvdModeloAposentadoria MA
          ON CA.CdModeloAposentadoria = MA.CdModeloAposentadoria
       WHERE V.CdVinculo = pCdVinculo
         AND MA.FlParidade = PKGPAG_TIPO.cnS
         AND CA.FlAtiva = PKGPAG_TIPO.cnS
         AND ((CA.Dtinicioaposentadoria <= pdtFimMes) AND
             (CA.DtFimaposentadoria >= pdtInicioMes OR
             CA.DtFimaposentadoria IS NULL))
         AND pkgpag_var.vgFolha.CdTipoFolha != pkgpag_tipo.cnTpFolhaInstPensao

        UNION ALL

        SELECT 4 AS CdTipoRelacao,
             CA.CdVinculo,
             CA.CdConcessaoAposentadoria,
             CA.CdOrgaoExercicio,
             V.CdRegimePrevidenciario,
             V.CdSituacaoPrevidenciaria,
             V.CdRegimeTrabalho,
             0 AS CdEstruturaCarreira,
             0 AS CdEstruturaCarreiraCarreira,
             CA.CdUnidadeOrganizacional,
             CASE
               WHEN CA.DtInicioAposentadoria < pdtInicioMes THEN
                pdtInicioMes
               ELSE
                CA.DtInicioAposentadoria
             END AS DtInicio,
             pdtFimMes AS DtFim,
             CA.VlPercentPropAPO,
             CA.FlOrigemCCO
        FROM EpvdConcessaoAposentadoria CA
       INNER JOIN ECadVinculo V
          ON CA.CdVinculo = V.CdVinculo
       INNER JOIN EPvdModeloAposentadoria MA
          ON CA.CdModeloAposentadoria = MA.CdModeloAposentadoria
       INNER JOIN Eafaregistroobito o on o.cdpessoa = v.cdpessoa
       WHERE V.CdVinculo = pCdVinculo
         AND MA.FlParidade = PKGPAG_TIPO.cnS
         AND CA.FlAtiva = PKGPAG_TIPO.cnS
         AND CA.Dtinicioaposentadoria <= pdtFimMes
         AND CA.DtFimaposentadoria = o.dtobito-1
         and pkgpag_var.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaInstPensao
         and o.flanulado = PKGPAG_TIPO.cnN;

    CURSOR cLocRisco(pCdUnidadeOrganizacional IN INTEGER,
                     pCdTipoRisco             IN INTEGER) IS
      SELECT CdUnidadeOrganizacional, FlConsideraSubordinada, CdGrauRisco
        FROM (SELECT HLR.CdUnidadeOrganizacional,
                     HLR.FlConsideraSubordinada,
                     TR.CdGrauRisco
                FROM ESauHistLocalRisco HLR
               INNER JOIN esauhistlocalriscotiporisco TR
                  ON HLR.CdHistLocalRisco = TR.CdHistLocalRisco
               INNER JOIN (SELECT LEVEL AS Nivel, HUO.CdUnidadeOrganizacional
                            FROM ECadHistUnidadeOrganizacional HUO
                           START WITH HUO.CdUnidadeOrganizacional =
                                      pCdUnidadeOrganizacional
                          CONNECT BY PRIOR HUO.CdUOSupHierarq =
                                      HUO.CdUnidadeOrganizacional
                                 AND HUO.dtiniciovigencia <= pFolha.DtFimMes
                                 AND (HUO.dtfimvigencia >=
                                     pFolha.DtInicioMes OR
                                     HUO.dtfimvigencia IS NULL)) UO
                  ON HLR.CdUnidadeOrganizacional =
                     uo.CdUnidadeOrganizacional
               WHERE HLR.DtInicioVigencia <= pFolha.DtFimMes
                 AND (HLR.DtFimVigencia >= pFolha.DtInicioMes OR
                     HLR.dtFimVigencia IS NULL)
                 AND HLR.FlAnulado = PKGPAG_TIPO.cnN
                 AND TR.CdTipoRisco = pCdTipoRisco
               ORDER BY Nivel, HLR.DtInicioVigencia)
       WHERE ROWNUM = 1;

    CURSOR cAtivLocRisco(pCdUnidadeOrganizacional     IN INTEGER,
                         pCdUnidOrgAtividade          IN INTEGER,
                         pCdTipoRisco                 IN INTEGER,
                         pCdEstruturaCarreira         IN INTEGER,
                         pCdEstruturaCarreiraCarreira IN INTEGER,
                         pDtInicioAtividade           IN DATE,
                         pDtFimAtividade              IN DATE) IS

      SELECT cdunidadeorganizacional,
             flconsiderasubordinada,
             fltodaestruturacarreira,
             cdgraurisco
        FROM (SELECT ua.cdunidadeorganizacional,
                     har.flconsiderasubordinada,
                     har.fltodaestruturacarreira,
                     ar.cdgraurisco
                FROM ecadunidorgatividade ua
               INNER JOIN esauhistatividaderisco har
                  ON ua.cdunidorgatividade = har.cdunidorgatividade
               INNER JOIN esauhistativriscotiporisco ar
                  ON ar.cdhistatividaderisco = har.cdhistatividaderisco
               INNER JOIN (SELECT LEVEL AS nivel, huo.cdunidadeorganizacional
                            FROM ecadhistunidadeorganizacional huo
                           START WITH huo.cdunidadeorganizacional =
                                      pcdunidadeorganizacional
                          CONNECT BY PRIOR huo.cduosuphierarq =
                                      huo.cdunidadeorganizacional
                                 AND huo.dtiniciovigencia <= pfolha.dtfimmes
                                 AND (huo.dtfimvigencia >=
                                     pfolha.dtiniciomes OR
                                     huo.dtfimvigencia IS NULL)) uo
                  ON ua.cdunidadeorganizacional = uo.cdunidadeorganizacional
                LEFT JOIN esauhistativriscocarreira hac
                  ON har.cdhistatividaderisco = hac.cdhistatividaderisco
               WHERE har.dtiniciovalidade <= pfolha.dtfimmes
                 AND (har.dtfimvalidade >= pfolha.dtiniciomes OR
                     har.dtfimvalidade IS NULL)
                 AND har.flanulado = pkgpag_tipo.cnn
                 AND ar.cdtiporisco = pcdtiporisco
                 AND har.cdunidorgatividade = pcdunidorgatividade
                 AND (har.fltodaestruturacarreira = pkgpag_tipo.cns OR
                     (hac.cdestruturacarreira = pcdestruturacarreira OR
                     hac.cdestruturacarreira =
                     pcdestruturacarreiracarreira))
               ORDER BY nivel, har.dtiniciovalidade)
       WHERE rownum = 1;

    FUNCTION FEfetivoAfastado(pCdHistRelacao     IN INTEGER,
                              pCdRelacaoTrabalho IN INTEGER,
                              pDtCalculo         IN DATE) RETURN BOOLEAN IS

      bExiste INTEGER;

    BEGIN

      -- Nao verifica afastamento caso seja disposicao ou
      -- caso nao possua relacao de disposicao

      IF pCdRelacaoTrabalho = PKGPAG_TIPO.cnRelTrabDisposicao OR
         NOT PKGPAG_VAR.bPossuiDisposicao THEN

        RETURN FALSE;

      ELSE

        BEGIN

          -- Verifica afastamento na data do calculo
          SELECT 1
            INTO bExiste
            FROM EAfaAfastamentoRelVinc AR
           WHERE AR.CdHistCargoEfetivo = pCdHistRelacao
             AND AR.CdHistCargoEfetivoGerador IS NOT NULL
             AND AR.DtInicio <= pDtCalculo
             AND (AR.DtFim >= pDtCalculo OR AR.DtFim is NULL)
             AND ROWNUM < 2;

          RETURN TRUE;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            RETURN FALSE;

        END;

      END IF;

    END;

    FUNCTION FRetornaIndiceRisco(pCdOrgao                 IN INTEGER,
                                 pCdUnidadeOrganizacional IN INTEGER,
                                 pCdRegimePrevidenciario  IN INTEGER,
                                 pCdGrauRisco             IN INTEGER)
      RETURN NUMBER IS

      vVlPercentual NUMBER(7, 4);

    BEGIN

      SELECT vlpercentual
        INTO vvlpercentual
        FROM (SELECT vr.vlpercentual
                FROM esauorgaorisco o
               INNER JOIN esauorgaovalorregimerisco vr
                  ON o.cdorgaorisco = vr.cdorgaorisco
               WHERE ((o.cdorgao = pcdorgao AND
                     o.cdunidadeorganizacional IS NULL) OR
                     o.cdunidadeorganizacional = pcdunidadeorganizacional)
                 AND vr.cdtiporisco = pcdtiporisco
                 AND vr.intiporegime = pcdregimeprevidenciario
                 AND vr.cdgraurisco = pcdgraurisco
                 AND ((to_char(o.dtiniciovigencia, 'YYYY') <
                     to_char(pfolha.nuanoreferencia) OR
                     (to_char(o.dtiniciovigencia, 'YYYY') =
                     to_char(pfolha.nuanoreferencia) AND
                     to_char(o.dtiniciovigencia, 'MM') <=
                     to_char(pfolha.numesreferencia))) AND
                     (to_char(o.dtfimvigencia, 'YYYY') >
                     to_char(pfolha.nuanoreferencia) OR
                     (to_char(o.dtfimvigencia, 'YYYY') =
                     to_char(pfolha.nuanoreferencia) AND
                     to_char(o.dtfimvigencia, 'MM') >=
                     to_char(pfolha.numesreferencia)) OR
                     o.dtfimvigencia IS NULL))
               ORDER BY o.cdunidadeorganizacional, o.cdorgao)
       WHERE rownum < 2;

      RETURN vVlPercentual;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END FRetornaIndiceRisco;

    PROCEDURE PInsereRemuneracaoRiscoRV(pCdTipoRelacao               IN INTEGER,
                                        pCdHistRelVinc               IN INTEGER,
                                        pCdUnidadeOrganizacional     IN INTEGER,
                                        pCdRegimePrevidenciario      IN INTEGER,
                                        pDtInicio                    IN DATE,
                                        pDtFim                       IN DATE,
                                        pCdUnidOrgAtividade          IN INTEGER DEFAULT NULL,
                                        pDtInicioAtividade           IN DATE DEFAULT NULL,
                                        pDtFimAtividade              IN DATE DEFAULT NULL,
                                        pCdEstruturaCarreira         IN INTEGER DEFAULT NULL,
                                        pCdEstruturaCarreiraCarreira IN INTEGER DEFAULT NULL,
                                        pCdCargoComissionado         IN INTEGER DEFAULT NULL,
                                        pCdFuncaoChefia              IN INTEGER DEFAULT NULL) IS

      bAdicionouAtiv BOOLEAN DEFAULT FALSE;

    BEGIN

      IF pCdTipoRelacao = 1 AND pCdUnidOrgAtividade IS NOT NULL THEN

        FOR vLocRisco IN cAtivLocRisco(pCdUnidadeOrganizacional,
                                       pCdUnidOrgAtividade,
                                       pCdTipoRisco,
                                       pCdEstruturaCarreira,
                                       pCdEstruturaCarreiraCarreira,
                                       pDtInicioAtividade,
                                       pDtFimAtividade) LOOP

          IF ((vLocRisco.FlConsideraSubordinada = PKGPAG_TIPO.cnS) OR
             (vLocRisco.CdUnidadeOrganizacional = pCdUnidadeOrganizacional)) THEN

            vVlIndice := FRetornaIndiceRisco(pFolha.CdOrgao,
                                             pCdUnidadeOrganizacional,
                                             pCdRegimePrevidenciario,
                                             vLocRisco.CdGrauRisco);

            IF nvl(vVlIndice, 0) > 0 AND
               NOT (pDtFim BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

              IF (pDtFimAtividade - pDtInicioAtividade + 1 > vNuDiasMes) THEN

                vNuDias := vNuDiasMes;

              ELSE

                IF pDtFimAtividade = pFolha.DtFimMes AND
                   TO_CHAR(pFolha.DtFimMes, 'MM') = 2 THEN

                  IF TO_CHAR(pDtFimAtividade, 'DD') = 28 THEN

                    vNuDias := pDtFimAtividade - pDtInicioAtividade + 3;

                  ELSE

                    vNuDias := pDtFimAtividade - pDtInicioAtividade + 2;

                  END IF;

                ELSE

                  vNuDias := pDtFimAtividade - pDtInicioAtividade + 1;

                END IF;

              END IF;

              vvlIndice := (CASE
                             WHEN vNuDias > 30 THEN
                              30
                             ELSE
                              vNuDias
                           END / vNuDiasMes) * vVlIndice;

            END IF;

            vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                           pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                           pCdRelacaoVinculo        => pCdTipoRelacao,
                                                                           pCdEstruturaCarreira     => pCdEstruturaCarreira,
                                                                           pCdCargoComissionado     => pCdCargoComissionado,
                                                                           pCdFuncaoChefia          => pCdFuncaoChefia,
                                                                           pCdUnidadeOrganizacional => pCdUnidadeOrganizacional);

            IF vCdExpressaoFormCalc > 0 THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdRelacaoVinculo     => pCdTipoRelacao,
                                                    pCdHistRelacaoVinculo => pCdHistRelVinc,
                                                    pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                    pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral           => NULL,
                                                    pVlProporcional       => NULL,
                                                    pNuSufixoRubrica      => 1,
                                                    pNuParcelas           => 1,
                                                    pVlIndice             => vVlIndice,
                                                    pCdTipoOrigemRubrica  => 7);

              bAdicionouAtiv := TRUE;

            END IF;

          END IF;

        END LOOP;

      END IF;

      IF pCdTipoRelacao <> 1 OR bAdicionouAtiv = FALSE THEN

        FOR vLocRisco IN cLocRisco(pCdUnidadeOrganizacional, pCdTipoRisco) LOOP

          IF (vLocRisco.FlConsideraSubordinada = PKGPAG_TIPO.cnS) OR
             (vLocRisco.CdUnidadeOrganizacional = pCdUnidadeOrganizacional) THEN

            vVlIndice := FRetornaIndiceRisco(pFolha.CdOrgao,
                                             pCdUnidadeOrganizacional,
                                             pCdRegimePrevidenciario,
                                             vLocRisco.CdGrauRisco);

            --------------------------------------------------------------------------------------
            -- 12/07/2013 - Solicitacao 4916/2013
            --------------------------------------------------------------------------------------
            -- Caso se trate de um CCO &
            -- ja tenha havido inclusao de rubrica para um CEF &
            -- a rubrica em questao indique que deve pagar o mair valor entre as relacoes, o
            -- indice na relacao do CEF devera ser atualizado com o indice do CCO
            --------------------------------------------------------------------------------------

            IF pCdTipoRelacao = 2 AND pRubrica.FlPagaMaiorRV = 'S' THEN

              UPDATE EPagHistoricoRubricaRelVinc HRV
                 SET HRV.VlIndiceRubrica = vVlIndice
               WHERE HRV.CdVinculo = pCdVinculo
                 AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND HRV.CdRubricaAgrupamento =
                     pRubrica.CdRubricaAgrupamento
                 AND HRV.CdRelacaoVinculo = 1;

            END IF;

            -----------------------------------------------------------------------------
            --- Caso seja aposentado iniciando no mes, nao deve proporcionalizar o indice
            -----------------------------------------------------------------------------

            IF nvl(vVlIndice, 0) > 0 AND
               ((pCdTipoRelacao NOT IN (1, 4, 2)) OR
                (pCdTipoRelacao = 4 AND pDtInicio < pFolha.DtInicioMes) OR
                (pCdTipoRelacao = 1 AND
                NOT (pDtFim BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)) OR
                (pCdTipoRelacao = 2 AND pDtInicio < pFolha.DtInicioMes AND
                (pDtFim IS NULL OR pDtFim > pFolha.DtFimMes))) THEN

              IF (pDtFim - pDtInicio + 1) > vNuDiasMes THEN

                vNuDias := vNuDiasMes;

              ELSE

                IF pDtFimAtividade = pFolha.DtFimMes AND
                   TO_CHAR(pFolha.DtFimMes, 'MM') = 2 THEN

                  IF TO_CHAR(pdtFim, 'DD') = 28 THEN

                    vNuDias := pdtFim - pDtInicio + 3;

                  ELSE

                    vNuDias := pdtFim - pDtInicio + 2;

                  END IF;

                ELSE

                  vNuDias := pdtFim - pDtInicio + 1;

                END IF;

              END IF;

              vvlIndice := (CASE
                             WHEN vNuDias > 30 THEN
                              30
                             ELSE
                              vNuDias
                           END / vNuDiasMes) * vVlIndice;

            END IF;

            vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                           pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                           pCdRelacaoVinculo        => pCdTipoRelacao,
                                                                           pCdEstruturaCarreira     => pCdEstruturaCarreira,
                                                                           pCdCargoComissionado     => pCdCargoComissionado,
                                                                           pCdFuncaoChefia          => pCdFuncaoChefia,
                                                                           pCdUnidadeOrganizacional => pCdUnidadeOrganizacional);

            IF vCdExpressaoFormCalc > 0 THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdRelacaoVinculo     => pCdTipoRelacao,
                                                    pCdHistRelacaoVinculo => pCdHistRelVinc,
                                                    pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                    pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral           => NULL,
                                                    pVlProporcional       => NULL,
                                                    pNuSufixoRubrica      => 1,
                                                    pNuParcelas           => 0,
                                                    pVlIndice             => vVlIndice,
                                                    pCdTipoOrigemRubrica  => 7);
            END IF;

          END IF;

        END LOOP;

      END IF;

    END;

  BEGIN

    vNuDiasMes := PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.dtFimMes,
                                                 pRubrica.FlPropMesComercial);

    IF PKGPAG_VAR.vgRelVincPrincipal.CdHist IS NOT NULL THEN

      FOR vCEF IN cRelCEF(pCdVinculo, pFolha.DtInicioMes, pFolha.DtFimMes) LOOP

        IF NOT FEfetivoAfastado(vCEF.CdHistCargoEfetivo,
                                vCEF.CdRelacaoTrabalho,
                                pFolha.DtCalculo) THEN

          IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                    pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                    pCdOrgaoExercicio         => vCEF.CdOrgaoExercicio,
                                                    pCdNaturezaVinculo        => vCEF.CdNaturezaVinculo,
                                                    pCdRelacaoTrabalho        => vCEF.CdRelacaoTrabalho,
                                                    pCdRegimeTrabalho         => vCEF.CdRegimeTrabalho,
                                                    pCdRegimePrevidenciario   => vCEF.CdRegimePrevidenciario,
                                                    pCdSituacaoPrevidenciaria => vCEF.CdSituacaoPrevidenciaria,
                                                    pCdUnidadeOrganizacional  => vCEF.CdUnidadeOrganizacional,
                                                    pCdEstruturaCarreira      => vCEF.CdEstruturaCarreira,
                                                    pFlTipoProvimento         => vCEF.FlEfetivacao) THEN

            PInsereRemuneracaoRiscoRV(pCdTipoRelacao               => vCEF.CdTipoRelacao,
                                      pCdHistRelVinc               => vCEF.CdHistCargoEfetivo,
                                      pCdUnidadeOrganizacional     => vCEF.CdUnidadeOrganizacional,
                                      pCdRegimePrevidenciario      => vCEF.CdRegimePrevidenciario,
                                      pDtInicio                    => vCEF.DtInicio,
                                      pDtFim                       => vCEF.DtFim,
                                      pCdUnidOrgAtividade          => vCEF.CdUnidOrgAtividade,
                                      pDtInicioAtividade           => vCEF.DtInicioAtividade,
                                      pDtFimAtividade              => vCEF.DtFimAtividade,
                                      pCdEstruturaCarreira         => vCEF.CdEstruturaCarreira,
                                      pCdEstruturaCarreiraCarreira => vCEF.CdEstruturaCarreiraCarreira);

          END IF;

        END IF;

      END LOOP;

    END IF;

    FOR vCCO IN cRelCCO(pCdVinculo, pFolha.DtInicioMes, pFolha.DtFimMes) LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                pCdOrgaoExercicio         => vCCO.CdOrgaoExercicio,
                                                pCdNaturezaVinculo        => vCCO.CdNaturezaVinculo,
                                                pCdRelacaoTrabalho        => vCCO.CdRelacaoTrabalho,
                                                pCdRegimeTrabalho         => vCCO.CdRegimeTrabalho,
                                                pCdRegimePrevidenciario   => vCCO.CdRegimePrevidenciario,
                                                pCdSituacaoPrevidenciaria => vCCO.CdSituacaoPrevidenciaria,
                                                pCdCargoComissionado      => vCCO.CdCargoComissionado,
                                                pCdGrupoOcupacional       => vCCO.CdGrupoOcupacional,
                                                pCdUnidadeOrganizacional  => vCCO.CdUnidadeOrganizacional,
                                                pFlTipoProvimento         => vCCO.FlTipoProvimento,
                                                pCdOpcaoRemuneracao       => vCCO.CdOpcaoRemuneracao,
                                                pCdEstruturaCarreira      => PKGPAG_VAR.vgCdEstruturaCarreira) THEN

        PInsereRemuneracaoRiscoRV(pCdTipoRelacao           => vCCO.CdTipoRelacao,
                                  pCdHistRelVinc           => vCCO.CdHistCargoCom,
                                  pCdUnidadeOrganizacional => vCCO.CdUnidadeOrganizacional,
                                  pCdRegimePrevidenciario  => vCCO.CdRegimePrevidenciario,
                                  pDtInicio                => vCCO.DtInicio,
                                  pDtFim                   => vCCO.DtFim,
                                  pCdCargoComissionado     => vCCO.CdCargoComissionado);

      END IF;

    END LOOP;

    FOR vFUC IN cRelFUC(pCdVinculo, pFolha.DtInicioMes, pFolha.DtFimMes)

     LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica          => pRubrica,
                                                pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                pCdOrgaoExercicio => vFUC.CdOrgaoExercicio,
                                                pCdFuncaoChefia   => vFUC.CdFuncaoChefia,
                                                pFlTipoProvimento => vFUC.FlEfetivacao) THEN

        PInsereRemuneracaoRiscoRV(pCdTipoRelacao           => vFUC.CdTipoRelacao,
                                  pCdHistRelVinc           => vFUC.CdHistFuncaoChefia,
                                  pCdUnidadeOrganizacional => vFUC.CdUnidadeOrganizacional,
                                  pCdRegimePrevidenciario  => vFUC.CdRegimePrevidenciario,
                                  pDtInicio                => vFUC.DtInicio,
                                  pDtFim                   => vFUC.DtFim,
                                  pCdFuncaoChefia          => vFUC.CdFuncaoChefia);

      END IF;

    END LOOP;

    FOR vAPO IN cRelAPO(pCdVinculo, pFolha.DtInicioMes, pFolha.DtFimMes)

     LOOP

      -- Associa a carreira correta ao aposentado

      FOR i IN PKGPAG_VAR.vgAPO.FIRST.. PKGPAG_VAR.vgAPO.LAST LOOP

        IF vAPO.CdConcessaoAposentadoria = PKGPAG_VAR.vgAPO(i).CdHistRelVinc THEN

          vAPO.CdEstruturaCarreira := PKGPAG_VAR.vgAPO(i).CdEstruturaCarreira;

          vAPO.CdEstruturaCarreiraCarreira := PKGPAG_VAR.vgAPO(i).CdEstruturaCarreiraCarreira;

        END IF;

      END LOOP;

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                pCdOrgaoExercicio         => vAPO.CdOrgaoExercicio,
                                                pCdSituacaoPrevidenciaria => vAPO.CdSituacaoPrevidenciaria,
                                                pCdEstruturaCarreira      => vAPO.CdEstruturaCarreira,
                                                pFlAPOOrigemCCO           => vAPO.FlOrigemCCO) THEN
        --
        -- Incluida passagem de parametro CdEstruturaCarreira, nao estava usando formula especifica.
        -- chamado 7197-2015
        --
        PInsereRemuneracaoRiscoRV(vAPO.CdTipoRelacao,
                                  vAPO.CdConcessaoAposentadoria,
                                  vAPO.CdUnidadeOrganizacional,
                                  vAPO.CdRegimePrevidenciario,
                                  vAPO.DtInicio,
                                  vAPO.DtFim,
                                  NULL,
                                  NULL,
                                  NULL,
                                  vAPO.CdEstruturaCarreira,
                                  vAPO.CdEstruturaCarreiraCarreira);

      END IF;

    END LOOP;

  END;

 PROCEDURE P082DesctoFaltaIntMesAtual(pCdVinculo IN INTEGER,
                    pFolha     IN PKGPAG_TIPO.rFolha,
                    pRubrica   IN PKGPAG_TIPO.rRubrica,
                    pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                    pCEF       IN PKGPAG_TIPO.tCEF,
                    pCCO       IN PKGPAG_TIPO.tCCO,
                    pCCOSubst  IN PKGPAG_TIPO.tCCO,
                    pFUC       IN PKGPAG_TIPO.tFUC,
                    pBOL       IN PKGPAG_TIPO.tBOL,
                    pAPO       IN PKGPAG_TIPO.tCEF) IS

 BEGIN

    IF PKGPAG_VAR.vgIndiceFaltasMesAtual > 0 THEN

      PKGPAG_VAR.vgCdRubEvento82 := pRubrica.CdRubricaAgrupamento;

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- Formula de calculo
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => pCCO,
                                           pCCOSubst            => pCCOSubst,
                                           pFUC                 => pFUC,
                                           pBOL                 => pBOL,
                                           pAPO                 => pAPO,
                                           pVlIndice            => PKGPAG_VAR.vgIndiceFaltasMesAtual,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 7);

    END IF;

  END;

  PROCEDURE P081DesctoFaltaIntMesAnt(pCdVinculo IN INTEGER,
                   pFolha     IN PKGPAG_TIPO.rFolha,
                   pRubrica   IN PKGPAG_TIPO.rRubrica,
                   pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                   pCEF       IN PKGPAG_TIPO.tCEF,
                   pCCO       IN PKGPAG_TIPO.tCCO,
                   pCCOSubst  IN PKGPAG_TIPO.tCCO,
                   pFUC       IN PKGPAG_TIPO.tFUC,
                   pBOL       IN PKGPAG_TIPO.tBOL,
                   pAPO       IN PKGPAG_TIPO.tCEF) IS

    vIndiceFaltasMesAnterior number;
    vVlFalta NUMBER(13,2);
    --vNuFalta NUMBER(7,4);
    vNuMesFalta INTEGER;
    vNuFaltas pkgpag_tipo.tFalta;
    vNuAnoMesReferencia INTEGER;
    vNuAnoMesFalta pkgpag_tipo.tFalta;
    vDeFalta VARCHAR(200);
    vDeExpressao CHAR(200);
    vCdExpressaoFormCalc INTEGER;

  BEGIN

    IF PKGPAG_VAR.vgIndiceFaltasMesAnterior > 0 THEN

      -- Inicializa a variavel
      vNuFaltas := pkgpag_tipo.tFalta();
      vNuFaltas.Extend(12);
      vNuAnoMesFalta := pkgpag_tipo.tFalta();
      vNuAnoMesFalta.Extend(12);
      vNuAnoMesReferencia := pkgpag_var.vgFolha.NuAnoReferencia ||
                              lpad(pkgpag_var.vgFolha.NuMesReferencia,2,0);

      for i in pkgpag_var.vgFaltas.first .. pkgpag_var.vgFaltas.last loop

          if pkgpag_var.vgFaltas(i).FlAbonado = 'N'
            and to_char(pkgpag_var.vgFaltas(i).DtFrequencia,'yyyymm') < vNuAnoMesReferencia
                then

            vNuMesFalta := to_char(pkgpag_var.vgFaltas(i).DtFrequencia, 'mm');
            vNuFaltas(vnuMesFalta) := NVL(vNufaltas(vNumesFalta), 0) +
                                      (pkgpag_var.vgfaltas(i).numfracaofalta / pkgpag_var.vgFaltas(i)
                                       .denfracaofalta);
            vNuAnoMesFalta(vNuMesFalta) := to_char(pkgpag_var.vgFaltas(i).DtFrequencia, 'yyyymm');

            if vNuFaltas(vNuMesFalta) > 30
              then
                vNuFaltas(vNuMesFalta) := 30;
            end if;
          end if;

      end loop;

      PKGPAG_VAR.vgCdRubEvento81 := pRubrica.CdRubricaAgrupamento;

      vIndiceFaltasMesAnterior := PKGPAG_VAR.vgIndiceFaltasMesAnterior;
      --
      -- Desligado mes anterior. Gerar no vinculo e nao na relacao
      -- Solicitacao de Sustentacao #79936
      -- 12265/2018 - FOLHA - NAO GERA DESCONTO DE FALTAS MES ANTERIOR
      --
      if pkgpag_var.vgVinculo.DtDesligamento < pFolha.DtInicioMes
        then

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                                         pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                                         pCdRelacaoVinculo         => 1);

          pkgpag_geral.pinserelancamentovinculo(pFolha.CdFolhaPagamento,
                                                pcdvinculo,
                                                vcdexpressaoformcalc,
                                                PKGPAG_VAR.vgCdRubEvento81,
                                                1,
                                                0,
                                                PKGPAG_VAR.vgIndiceFaltasMesAnterior);

          pkgpag_fb.pprocessaformulasbases (pFolha, pcdvinculo,pRubrica.CdRubricaAgrupamento,1,2);

      else

          PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- Formula de calculo
                                               pFolha               => pFolha,
                                               pCdVinculo           => pCdVinculo,
                                               pRubrica             => pRubrica,
                                               pFormExpr            => pFormExpr,
                                               pFlPrincipal         => PKGPAG_TIPO.cnS,
                                               pCEF                 => pCEF,
                                               pCCO                 => pCCO,
                                               pCCOSubst            => pCCOSubst,
                                               pFUC                 => pFUC,
                                               pBOL                 => pBOL,
                                               pAPO                 => pAPO,
                                               pVlIndice            => vIndiceFaltasMesAnterior,
                                               pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                               pCdTipoOrigemRubrica => 7);

          vVlFalta := 0;

          vIndiceFaltasMesAnterior := 0;

          for i in vNuFaltas.first .. vNuFaltas.last loop

            if vNuFaltas(i) is not null then

               vVlFalta := vVlFalta +
                           pkgpag_fb.fCalculaFormula(pcdvinculo,vNuAnoMesFalta(i),pRubrica.CdRubricaAgrupamento,
                                                     vNuFaltas(i), vDeFalta);

               vDeExpressao := nvl(trim(vDeExpressao),'') || vNuAnoMesFalta(i) || ' -> ' || trim(vDeFalta) || ' = ' || trim(vVlFalta) || '; ';
               vIndiceFaltasMesAnterior := vIndiceFaltasMesAnterior + vNuFaltas(i);

            end if;

          end loop;

          PKGPAG_VAR.vgIndiceFaltasMesAnterior := vIndiceFaltasMesAnterior;

          UPDATE epaghistoricorubricarelvinc hrub
             SET hrub.vlindicerubrica     = vindicefaltasmesanterior,
                 hrub.cdexpressaoformcalc = NULL,
                 hrub.vlintegral          = vvlfalta,
                 hrub.vlreal              = vvlfalta,
                 hrub.vlproporcional      = vvlfalta,
                 hrub.deexpressao         = vdeexpressao
           WHERE hrub.cdvinculo = pcdvinculo
             AND hrub.cdrubricaagrupamento = prubrica.cdrubricaagrupamento
             AND hrub.cdfolhapagamento =
                 pkgpag_var.vgfolha.cdfolhapagamento;

        end if;

    end if;

  END;

  PROCEDURE P025DescontoFaltaIntegral(pCdVinculo IN INTEGER,
                                      pFolha     IN PKGPAG_TIPO.rFolha,
                                      pRubrica   IN PKGPAG_TIPO.rRubrica,
                                      pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                                      pCEF       IN PKGPAG_TIPO.tCEF,
                                      pCCO       IN PKGPAG_TIPO.tCCO,
                                      pCCOSubst  IN PKGPAG_TIPO.tCCO,
                                      pFUC       IN PKGPAG_TIPO.tFUC,
                                      pBOL       IN PKGPAG_TIPO.tBOL,
                                      pAPO       IN PKGPAG_TIPO.tCEF) IS

  BEGIN

    IF PKGPAG_VAR.vgIndiceFaltas > 0 THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- Formula de calculo
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => pCCO,
                                           pCCOSubst            => pCCOSubst,
                                           pFUC                 => pFUC,
                                           pBOL                 => pBOL,
                                           pAPO                 => pAPO,
                                           pVlIndice            => PKGPAG_VAR.vgIndiceFaltas,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 7);

    END IF;

  END;

  PROCEDURE PAdicionalPosGraduacao(pCdPessoa IN INTEGER,
                                   pFolha    IN PKGPAG_TIPO.rFolha,
                                   pRubrica  IN PKGPAG_TIPO.rRubrica,
                                   pFormExpr IN PKGPAG_TIPO.tFormulaCalculo,
                                   pRelVinc  IN PKGPAG_TIPO.rCEF DEFAULT NULL,
                                   pFUC      IN PKGPAG_TIPO.rFUC DEFAULT NULL,
                                   pCCO      IN PKGPAG_TIPO.rCCO DEFAULT NULL,
                                   bPagou    OUT BOOLEAN) IS

    -- Seleciona os cursos de pos graduacao finalizados
    CURSOR cCurriculo IS
      SELECT PC.CdNivelFormGrauEsc, PC.CdCurso, CA.CdCursoAgrupador
        FROM ecadPessoaCurriculo PC
       INNER JOIN EcadNivelFormGrauEsc NFGE
          ON PC.CdNivelFormGrauEsc = NFGE.CdNivelFormGrauEsc
       INNER JOIN ECadGrauEscolaridade GE
          ON NFGE.CdGrauEscolaridade = GE.CdGrauEscolaridade
        LEFT JOIN ECadCursoAgrupadorCurso CA
          ON PC.CdCurso = CA.CdCurso
       WHERE PC.CdPessoa = pCdPessoa
         AND PC.CdSituacaoCurso = 2
         AND GE.FlPosGraduacao = PKGPAG_TIPO.cnS;

    -- Seleciona os cursos de graduacao finalizados
    CURSOR cCursoGrad IS
      SELECT PC.CdNivelFormGrauEsc,
             PC.CdCurso,
             CA.CdCursoAgrupador,
             NFGE.FlRelGraduacao
        FROM ECadPessoaCurriculo PC
       INNER JOIN ECadNivelFormGrauEsc NFGE
          ON PC.CdNivelFormGrauEsc = NFGE.CdNivelFormGrauEsc
       INNER JOIN ECadGrauEscolaridade GE
          ON NFGE.CdGrauEscolaridade = GE.CdGrauEscolaridade
        LEFT JOIN ECadCursoAgrupadorCurso CA
          ON PC.CdCurso = CA.CdCurso
       WHERE PC.CdPessoa = pCdPessoa
         AND PC.CdSituacaoCurso = 2
         AND NFGE.FlRelGraduacao = PKGPAG_TIPO.cnS;

    -- Seleciona as regras de pos graduacao para cargos efetivos
    CURSOR cRegraPagAdic IS
      SELECT BR.CdAdicionalPosGrad,
             BR.CdEstruturaCarreira,
             BR.CdTipoItemCarreira,
             BR.CdCurso,
             BR.CdCursoAgrupador,
             BR.CdNivelFormGrauEsc,
             BR.FlTodosCEF
        FROM eBpcAdicionalPosGrad AP
       INNER JOIN eBpcRegraPagCEF BR
          ON AP.CdAdicionalPosGrad = BR.CdAdicionalPosGrad
       WHERE AP.CdAgrupamento = pFolha.CdAgrupamento
         AND ((AP.NuAnoInicio < pFolha.NuAnoReferencia OR
             (AP.NuAnoInicio = pFolha.NuAnoReferencia AND
             AP.NumesInicio <= pFolha.NuMesReferencia)) AND
             (AP.NuAnoFim > pFolha.NuAnoReferencia OR
             (AP.NuAnoFim = pFolha.NuAnoReferencia AND
             AP.NuMesFim >= pFolha.NuMesReferencia) OR
             AP.NuMesFim IS NULL));

    -- Seleciona as regras baseadas em curso de graduacao

    CURSOR cRegraPagAdicCurso IS
      SELECT BR.CdAdicionalPosGrad,
             BR.CdCurso,
             BR.CdCursoAgrupador,
             CASE
               WHEN C.CdNivelFormGrauEsc IS NULL THEN
                BR.CdNivelFormGrauEsc
               ELSE
                C.CdNivelFormGrauEsc
             END CdNivelFormGrauEsc,
             BR.CdCursoPosGraduacao
        FROM eBpcAdicionalPosGrad AP
       INNER JOIN EBpcRegraPagCursoGrad BR
          ON AP.CdAdicionalPosGrad = BR.CdAdicionalPosGrad
        LEFT JOIN Ecadcursonivelgrauesc C
          ON BR.CdCursoPosGraduacao = C.CdCurso
       WHERE AP.CdAgrupamento = pFolha.CdAgrupamento
         AND ((AP.NuAnoInicio < pFolha.NuAnoReferencia OR
             (AP.NuAnoInicio = pFolha.NuAnoReferencia AND
             AP.NumesInicio <= pFolha.NuMesReferencia)) AND
             (AP.NuAnoFim > pFolha.NuAnoReferencia OR
             (AP.NuAnoFim = pFolha.NuAnoReferencia AND
             AP.NuMesFim >= pFolha.NuMesReferencia) OR
             AP.NuMesFim IS NULL));

    CURSOR cRegraPercentual(pCdAdicionalPosGrad IN INTEGER) IS
      SELECT RP.CdNivelFormGrauEsc,
             RP.CdEstruturaCarreira,
             RP.VlPercentPagamento
        FROM EBpcRegraPagNivelFormGrauEsc RP
       WHERE RP.CdAdicionalPosGrad = pCdAdicionalPosGrad;

    TYPE tRegraPagAdic IS TABLE OF cRegraPagAdic%ROWTYPE INDEX BY PLS_INTEGER;

    TYPE tRegraPagAdicCurso IS TABLE OF cRegraPagAdicCurso%ROWTYPE INDEX BY PLS_INTEGER;

    vRegraAdic tRegraPagAdic;

    vRegraCandidata tRegraPagAdic;

    vRegraPagAdicCurso tRegraPagAdicCurso;

    vRegraCandAdicCur tRegraPagAdicCurso;

    vVlPercentual EBpcRegraPagNivelFormGrauEsc.Vlpercentpagamento%TYPE;

    bCandidato BOOLEAN;

    k INTEGER;

    vCdExpressaoFormCalc INTEGER;

    bEncontrouNFPosGrad BOOLEAN;

    bEncontrouCursoGrad BOOLEAN;

    bEncontrouPosGrad BOOLEAN;

    bEncontrouCursoAgrup BOOLEAN;

  BEGIN

    bPagou := FALSE;

    /* Armazena as regras para cargos efetivos */

    OPEN cRegraPagAdic;

    FETCH cRegraPagAdic BULK COLLECT
      INTO vRegraAdic;

    CLOSE cRegraPagAdic;

    /* Armazena as regras para cursos */

    OPEN cRegraPagAdicCurso;

    FETCH cRegraPagAdicCurso BULK COLLECT
      INTO vRegraPagAdicCurso;

    CLOSE cRegraPagAdicCurso;

    /*-------------------------------------------------------------------*/
    /* Implementacao de Regras de Pagamento atraves dos CEF e APO        */
    /*-------------------------------------------------------------------*/

    IF pRelVinc.CdVinculo IS NOT NULL AND vRegraAdic.COUNT > 0 THEN

      k := 0;

      /*Varre cada curriculo do CEF/APO e tenta encontrar as regras candidatas.
      Posteriormente busca o percentual de adicional de pos graduacao */

      FOR vCurriculo IN cCurriculo LOOP

        FOR j IN vRegraAdic.FIRST.. vRegraAdic.LAST LOOP

          bCandidato := TRUE;

          -- Se o curso esta preenchido na regra e o
          -- curso do curriculo for diferente, a regra nao e candidata

          IF vRegraAdic(j).CdCurso IS NOT NULL THEN

            IF vRegraAdic(j).CdCurso <> vCurriculo.CdCurso THEN

              bCandidato := FALSE;

            END IF;

          END IF;

          -- Se o Nivel de Formacao/Grau de escolaridade esta preenchido na regra
          -- e o Nivel de Formacao/Grau de escolaridade do curriculo for diferente,
          -- a regra nao e candidata

          IF vRegraAdic(j).CdNivelFormGrauEsc IS NOT NULL AND bCandidato THEN

            IF vRegraAdic(j).CdNivelFormGrauEsc <> vCurriculo.CdNivelFormGrauEsc THEN

              bCandidato := FALSE;

            END IF;

          END IF;

          -- Se o Curso Agrupador esta preenchido na regra
          -- e o Curso Agrupador do curriculo for diferente, a regra nao e candidata

          IF vRegraAdic(j).CdCursoAgrupador IS NOT NULL AND bCandidato THEN

            IF vRegraAdic(j).CdCursoAgrupador <> vCurriculo.CdCursoAgrupador THEN

              bCandidato := FALSE;

            END IF;

          END IF;

          IF vRegraAdic(j).FlTodosCEF = PKGPAG_TIPO.cnN AND bCandidato THEN

            IF vRegraAdic(j).CdEstruturaCarreira IS NOT NULL THEN

              IF PKGPAG_GERAL.FBuscaCarreira(pCdEstruturaCarreira     => pRelVinc.CdEstruturaCarreira,
                                             pCdEstruturaCarreiraProc => vRegraAdic(j).CdEstruturaCarreira) THEN

                bCandidato := TRUE;

              ELSE

                bCandidato := FALSE;

              END IF;

            END IF;

          END IF;

          IF bCandidato THEN

            k := k + 1;

            vRegraCandidata(k) := vRegraAdic(j);

          END IF;

        END LOOP;

      END LOOP;

      IF vRegraCandidata.COUNT > 0 THEN

        vVlPercentual := 0;

        FOR m IN vRegraCandidata.FIRST.. vRegraCandidata.LAST LOOP

          /*Varre a tabela de percentual para encontrar um percentual por carreira */
          FOR vRegraPercentual IN cRegraPercentual(vRegraCandidata(m).CdAdicionalPosGrad) LOOP

            IF vRegraCandidata(m).CdEstruturaCarreira = vRegraPercentual.CdEstruturaCarreira AND vRegraCandidata(m).CdNivelFormGrauEsc = vRegraPercentual.CdNivelFormGrauEsc THEN

              IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                vvlPercentual := vRegraPercentual.VlPercentPagamento;

              END IF;

            END IF;

          END LOOP;

        END LOOP;

        IF vvlPercentual = 0 THEN

          FOR m IN vRegraCandidata.FIRST.. vRegraCandidata.LAST LOOP

            /*Varre a tabela de percentual para encontrar um percentual geral */
            FOR vRegraPercentual IN cRegraPercentual(vRegraCandidata(m).CdAdicionalPosGrad) LOOP

              IF vRegraCandidata(m).CdNivelFormGrauEsc = vRegraPercentual.CdNivelFormGrauEsc AND
                  vRegraPercentual.CdEstruturaCarreira IS NULL THEN

                IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                  vvlPercentual := vRegraPercentual.VlPercentPagamento;

                END IF;

              END IF;

            END LOOP;

          END LOOP;

        END IF;

      END IF;

      IF vVlPercentual > 0 THEN

        IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                  pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                  pCdOrgaoExercicio         => pRelVinc.CdOrgaoExercicio,
                                                  pCdNaturezaVinculo        => pRelVinc.CdNaturezaVinculo,
                                                  pCdRelacaoTrabalho        => pRelVinc.CdRelacaoTrabalho,
                                                  pCdRegimeTrabalho         => pRelVinc.CdRegimeTrabalho,
                                                  pCdRegimePrevidenciario   => pRelVinc.CdRegimePrevidenciario,
                                                  pCdSituacaoPrevidenciaria => pRelVinc.CdSituacaoPrevidenciaria,
                                                  pCdUnidadeOrganizacional  => pRelVinc.CdUnidadeOrganizacional,
                                                  pCdEstruturaCarreira      => pRelVinc.CdEstruturaCarreira,
                                                  pFlAPOOrigemCCO           => pRelVinc.FlOrigemCCO,
                                                  pFlTipoProvimento         => pRelVinc.FlEfetivacao) THEN

          -- 1) Busca a formula associada

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                         pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                         pCdRelacaoVinculo        => pRelVinc.CdRelacaoVinculo,
                                                                         pCdEstruturaCarreira     => pRelVinc.CdEstruturaCarreira,
                                                                         pCdUnidadeOrganizacional => pRelVinc.CdUnidadeOrganizacional);

          IF vCdExpressaoFormCalc > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pRelVinc.CdVinculo,
                                                  pCdRelacaoVinculo        => pRelVinc.CdRelacaoVinculo,
                                                  pCdHistRelacaoVinculo    => pRelVinc.CdHistRelVinc,
                                                  pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                  pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral              => NULL,
                                                  pVlProporcional          => NULL,
                                                  pNuSufixoRubrica         => 1,
                                                  pNuParcelas              => 1,
                                                  pVlIndice                => vvlPercentual,
                                                  pDtInicioRelacao         => pRelVinc.DtInicioRelacao,
                                                  pDtDesligamento          => pRelVinc.DtFimRelacao,
                                                  pCdUnidadeOrganizacional => pRelVinc.CdUnidadeOrganizacional,
                                                  pCdTipoOrigemRubrica     => 7,
                                                  pdtInicio                => pRelVinc.DtInicio,
                                                  pdtFim                   => pRelVinc.DtFim);

            bPagou := TRUE;

          END IF;

        END IF;

      END IF;

    END IF;

    /*-------------------------------------------------------------------*/
    /* Regras de Pagamento Atraves dos Cursos de Graduacao               */
    /*-------------------------------------------------------------------*/

    -- Caso nao tenha pago pelas regras de CEF e CCO

    IF NOT bPagou AND vRegraPagAdicCurso.COUNT > 0 THEN

      bEncontrouCursoGrad := FALSE;

      bEncontrouNFPosGrad := FALSE;

      bEncontrouPosGrad := FALSE;

      bEncontrouCursoAgrup := FALSE;

      k := 0;

      FOR vCursoGrad IN cCursoGrad LOOP

        FOR j IN vRegraPagAdicCurso.FIRST.. vRegraPagAdicCurso.LAST LOOP

          -- Verifica se o curso de graduacao existe na lista de regras
          IF vCursoGrad.CdCurso IS NOT NULL THEN

            IF vRegraPagAdicCurso(j).CdCurso = vCursoGrad.CdCurso THEN

              bEncontrouCursoGrad := TRUE;

            END IF;

          END IF;

          -- Caso o nivel formacao/grau escolaridade da lista de regras
          -- esteja preenchido, verifica se existe o mesmo nivel/grau no
          -- curriculo

          IF vRegraPagAdicCurso(j).CdNivelFormGrauEsc IS NOT NULL AND bEncontrouCursoGrad THEN

            FOR vCurriculo IN cCurriculo LOOP

              IF vRegraPagAdicCurso(j).CdNivelFormGrauEsc = vCurriculo.CdNivelFormGrauEsc THEN

                bEncontrouNFPosGrad := TRUE;

              END IF;

            END LOOP;

          ELSE

            bEncontrouNFPosGrad := TRUE;

          END IF;

          IF vRegraPagAdicCurso(j).CdCursoPosGraduacao IS NOT NULL AND bEncontrouCursoGrad THEN

            FOR vCurriculo IN cCurriculo LOOP

              IF vRegraPagAdicCurso(j).CdCursoPosGraduacao = vCurriculo.CdCurso THEN

                bEncontrouPosGrad := TRUE;

              END IF;

            END LOOP;

          ELSE

            bEncontrouPosGrad := TRUE;

          END IF;

          IF vRegraPagAdicCurso(j).CdCursoAgrupador IS NOT NULL AND bEncontrouCursoGrad THEN

            FOR vCurriculo IN cCurriculo LOOP

              IF vRegraPagAdicCurso(j).CdCursoAgrupador = vCurriculo.CdCursoAgrupador THEN

                bEncontrouCursoAgrup := TRUE;

              END IF;

            END LOOP;

          ELSE

            bEncontrouCursoAgrup := TRUE;

          END IF;

          IF bEncontrouCursoAgrup AND bEncontrouCursoGrad AND
             bEncontrouNFPosGrad AND bEncontrouPosGrad THEN

            k := k + 1;

            vRegraCandAdicCur(k) := vRegraPagAdicCurso(j);

          END IF;

        END LOOP;

      END LOOP;

      IF vRegraCandAdicCur.COUNT > 0 THEN

        vVlPercentual := 0;

        FOR m IN vRegraCandAdicCur.FIRST.. vRegraCandAdicCur.LAST LOOP

          /*Varre a tabela de percentual para encontrar um percentual por carreira */
          FOR vRegraPercentual IN cRegraPercentual(vRegraCandAdicCur(m).CdAdicionalPosGrad) LOOP

            IF pRelVinc.CdVinculo IS NOT NULL THEN

              -- CEF ou APO

              IF pRelVinc.CdEstruturaCarreira =
                 vRegraPercentual.CdEstruturaCarreira AND vRegraCandAdicCur(m).CdNivelFormGrauEsc = vRegraPercentual.CdNivelFormGrauEsc THEN

                IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                  vvlPercentual := vRegraPercentual.VlPercentPagamento;

                END IF;

              END IF;

            ELSE

              -- FUC e CCO

              IF vRegraPercentual.CdEstruturaCarreira IS NULL AND
                 vRegraPercentual.CdNivelFormGrauEsc = vRegraCandAdicCur(m).CdNivelFormGrauEsc THEN

                IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                  vvlPercentual := vRegraPercentual.VlPercentPagamento;

                END IF;

              END IF;

            END IF;

          END LOOP;

        END LOOP;

        IF vvlPercentual = 0 THEN

          FOR m IN vRegraCandAdicCur.FIRST.. vRegraCandAdicCur.LAST LOOP

            /* Varre a tabela de percentual para encontrar um percentual geral  */
            FOR vRegraPercentual IN cRegraPercentual(vRegraCandAdicCur(m).CdAdicionalPosGrad) LOOP

              IF vRegraCandAdicCur(m).CdNivelFormGrauEsc = vRegraPercentual.CdNivelFormGrauEsc AND
                  vRegraPercentual.CdEstruturaCarreira IS NULL THEN

                IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                  vvlPercentual := vRegraPercentual.VlPercentPagamento;

                END IF;

              END IF;

            END LOOP;

          END LOOP;

        END IF;

      END IF;

      IF vVlPercentual > 0 THEN

        IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                  pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                  pCdOrgaoExercicio         => pRelVinc.CdOrgaoExercicio,
                                                  pCdNaturezaVinculo        => pRelVinc.CdNaturezaVinculo,
                                                  pCdRelacaoTrabalho        => pRelVinc.CdRelacaoTrabalho,
                                                  pCdRegimeTrabalho         => pRelVinc.CdRegimeTrabalho,
                                                  pCdRegimePrevidenciario   => pRelVinc.CdRegimePrevidenciario,
                                                  pCdSituacaoPrevidenciaria => pRelVinc.CdSituacaoPrevidenciaria,
                                                  pCdUnidadeOrganizacional  => pRelVinc.CdUnidadeOrganizacional,
                                                  pCdEstruturaCarreira      => pRelVinc.CdEstruturaCarreira,
                                                  pFlAPOOrigemCCO           => pRelVinc.FlOrigemCCO,
                                                  pFlTipoProvimento         => pRelVinc.FlEfetivacao) THEN

          -- 1) Busca a formula associada

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                         pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                         pCdRelacaoVinculo        => pRelVinc.CdRelacaoVinculo,
                                                                         pCdEstruturaCarreira     => pRelVinc.CdEstruturaCarreira,
                                                                         pCdUnidadeOrganizacional => pRelVinc.CdUnidadeOrganizacional);

          IF vCdExpressaoFormCalc > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pRelVinc.CdVinculo,
                                                  pCdRelacaoVinculo        => pRelVinc.CdRelacaoVinculo,
                                                  pCdHistRelacaoVinculo    => pRelVinc.CdHistRelVinc,
                                                  pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                  pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral              => NULL,
                                                  pVlProporcional          => NULL,
                                                  pNuSufixoRubrica         => 1,
                                                  pNuParcelas              => 1,
                                                  pVlIndice                => vvlPercentual,
                                                  pDtInicioRelacao         => pRelVinc.DtInicioRelacao,
                                                  pDtDesligamento          => pRelVinc.DtFimRelacao,
                                                  pCdUnidadeOrganizacional => pRelVinc.CdUnidadeOrganizacional,
                                                  pCdTipoOrigemRubrica     => 7,
                                                  pdtInicio                => pRelVinc.DtInicio,
                                                  pdtFim                   => pRelVinc.DtFim);

            bPagou := TRUE;

          END IF;

        END IF;

      END IF;

    END IF;

  END;

  /*------------------------------------------------------------------------*/
  /* Procedure: PAdicionalPosGradAtiv                                       */
  /* Implementa regras de adicional de pos graduacao atraves das atividades */
  /*------------------------------------------------------------------------*/
  PROCEDURE PAdicionalPosGradAtiv(pCdPessoa IN INTEGER,
                                  pFolha    IN PKGPAG_TIPO.rFolha,
                                  pRubrica  IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr IN PKGPAG_TIPO.tFormulaCalculo,
                                  pCEF      IN PKGPAG_TIPO.tCEF,
                                  pFUC      IN PKGPAG_TIPO.tFUC,
                                  pCCO      IN PKGPAG_TIPO.tCCO) IS

    CURSOR cCurriculo IS
      SELECT PC.CdNivelFormGrauEsc, PC.CdCurso, CA.CdCursoAgrupador
        FROM ecadPessoaCurriculo PC
       INNER JOIN EcadNivelFormGrauEsc NFGE
          ON PC.CdNivelFormGrauEsc = NFGE.CdNivelFormGrauEsc
       INNER JOIN ECadGrauEscolaridade GE
          ON NFGE.CdGrauEscolaridade = GE.CdGrauEscolaridade
        LEFT JOIN ECadCursoAgrupadorCurso CA
          ON PC.CdCurso = CA.CdCurso
       WHERE PC.CdPessoa = pCdPessoa
         AND PC.CdSituacaoCurso = 2
         AND GE.FlPosGraduacao = PKGPAG_TIPO.cnS;

    CURSOR cRegraPercentual(pCdAdicionalPosGrad IN INTEGER) IS
      SELECT RP.CdNivelFormGrauEsc,
             RP.CdEstruturaCarreira,
             RP.VlPercentPagamento
        FROM EBpcRegraPagNivelFormGrauEsc RP
       WHERE RP.CdAdicionalPosGrad = pCdAdicionalPosGrad;

    TYPE rAtiv IS RECORD(
      CdAdicionalPosGrad      INTEGER,
      CdUnidadeOrganizacional INTEGER,
      CdAtividade             INTEGER,
      CdCurso                 INTEGER,
      CdCursoAgrupador        INTEGER,
      CdNivelFormGrauEsc      INTEGER,
      DtInicio                DATE,
      DtFim                   DATE);

    cAtiv types.ref_cursor;

    vSQL VARCHAR2(4000);

    vWHERE VARCHAR2(1000);

    vSQLRelVinc VARCHAR2(400);

    vWHERERelVinc VARCHAR2(400);

    --vCdVinculo           VARCHAR2(10);

    vAtiv rAtiv;

    bCandidata BOOLEAN;

    vvlPercentual NUMBER(7, 4);

    vCdExpressaoFormCalc INTEGER;

    vNuDiasMes INTEGER;

  BEGIN

    vSQL := 'SELECT ' || 'AP.CdAdicionalPosGrad,' ||
            'A.CdUnidadeOrganizacional,' || 'B.CdAtividade, ' ||
            'B.CdCurso,' || 'B.CdCursoAgrupador,' ||
            'B.CdNivelFormGrauEsc,' || 'CASE ' ||
            '  WHEN LT.DtInicio <= TO_DATE(''' || pFolha.dtInicioMes ||
            ''')  THEN' || '    CASE ' || '      WHEN TO_DATE(''' ||
            pFolha.dtInicioMes || ''')  <= A.DtInicioVigencia THEN' ||
            '        A.DtInicioVigencia' || '    ELSE' ||
            '      TO_DATE(''' || pFolha.dtInicioMes || ''')' || '  END' ||
            '  WHEN LT.DtInicio >= TO_DATE(''' || pFolha.dtInicioMes ||
            ''') THEN ' || '    CASE ' ||
            '      WHEN LT.DtInicio <= A.DtInicioVigencia THEN' ||
            '         A.dtiniciovigencia' || '    ELSE' ||
            '      LT.DtInicio' || '  END ' || 'END AS DtInicio,' ||
            'CASE ' || '  WHEN (LT.DtFim >= TO_DATE(''' || pFolha.dtFimMes ||
            ''')  OR LT.dtFim IS NULL)THEN' || '    CASE ' ||
            '      WHEN TO_DATE(''' || pFolha.dtFimMes ||
            ''') <= A.dtFimVigencia OR A.DtFimVigencia IS NULL THEN' ||
            '        TO_DATE(''' || pFolha.dtFimMes || ''')' ||
            '      WHEN TO_DATE(''' || pFolha.dtFimMes ||
            ''') >= A.dtFimvigencia THEN' || '        A.dtFimvigencia ' ||
            '    END    ' || '  WHEN (LT.DtFim <= TO_DATE(''' ||
            pFolha.dtFimMes || ''')) THEN' || '    CASE ' ||
            '      WHEN LT.DtFim <= A.DtFimVigencia OR A.DtFimVigencia IS NULL THEN' ||
            '        LT.DtFim' ||
            '      WHEN LT.DtFim >= A.dtFimvigencia THEN' ||
            '        A.DtFimVigencia ' || '    END ' || 'END AS DtFim' ||
            '  FROM eBpcAdicionalPosGrad AP ' ||
            ' INNER JOIN EBpcRegraPagAtiv B ' ||
            '    ON AP.CdAdicionalPosGrad = B.CdAdicionalPosGrad ' ||
            ' INNER JOIN ECadUnidOrgAtividade A' ||
            '   ON B.CdAtividade = A.CdAtividade' ||
            ' INNER JOIN ECadRelacaoVincAtividade R' ||
            '   ON R.CdUnidOrgAtividade = A.CdUnidOrgAtividade';

    vWHERE := ' WHERE (LT.dtinicio <= ''' || pFolha.dtFimMes ||
              ''' AND (lt.dtFim >= ''' || pFolha.dtInicioMes ||
              ''' OR lt.dtFim IS NULL)) AND' ||
              '      (A.Dtiniciovigencia <= ''' || pFolha.dtFimMes ||
              ''' AND (a.dtfimvigencia >= ''' || pFolha.dtInicioMes ||
              ''' OR a.dtfimvigencia IS NULL)) AND ' ||
              '      A.CdUnidadeOrganizacional = LT.CdUnidadeOrganizacional AND' ||
              '      AP.CdAgrupamento = ' || pFolha.CdAgrupamento ||
              ' AND ' || '      ((AP.NuAnoInicio < ' ||
              pFolha.NuAnoReferencia || ' OR ' ||
              '      (AP.NuAnoInicio = ' || pFolha.NuAnoReferencia ||
              ' AND ' || '      AP.NumesInicio <= ' ||
              pFolha.NuMesReferencia || '))' || '      AND ' ||
              '      (AP.NuAnoFim > ' || pFolha.NuAnoReferencia || ' OR ' ||
              '      (AP.NuAnoFim = ' || pFolha.NuAnoReferencia || ' AND ' ||
              '      AP.NuMesFim >= ' || pFolha.NuMesReferencia || ') OR ' ||
              '      AP.NuMesFim IS NULL)) ';

    FOR vCurriculo IN cCurriculo LOOP

      IF pCEF.COUNT > 0 THEN

        FOR i IN pCEF.FIRST.. pCEF.LAST LOOP

          vSQLRelVinc := '  INNER JOIN eCadHistCargoEfetivo CEF' ||
                         '    ON R.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo' ||
                         ' INNER JOIN ECadLocalTrabalho LT' ||
                         '    ON CEF.CdHistCargoEfetivo = LT.CdHistCargoEfetivo';

          vWHERERelVinc := ' AND CEF.CdHistCargoEfetivo = ' || pCEF(i).CdHistCargoEfetivo;

          OPEN cAtiv FOR vSQL || vSQLRelVinc || vWHERE || vWHERERelVinc;
          LOOP

            FETCH cAtiv
              INTO vAtiv;

            EXIT WHEN cAtiv%NOTFOUND;

            bCandidata := TRUE;

            vvlPercentual := 0;

            IF vAtiv.CdCurso IS NOT NULL THEN

              IF vAtiv.CdCurso <> vCurriculo.CdCurso THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF vAtiv.CdCursoAgrupador IS NOT NULL THEN

              IF vAtiv.CdCursoAgrupador <> vCurriculo.CdCursoAgrupador THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF vAtiv.CdNivelFormGrauEsc IS NOT NULL THEN

              IF vAtiv.CdNivelFormGrauEsc <> vCurriculo.CdNivelFormGrauEsc THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF bCandidata THEN

              FOR vRegraPercentual IN cRegraPercentual(vAtiv.CdAdicionalPosGrad) LOOP

                IF vRegraPercentual.CdEstruturaCarreira IS NOT NULL THEN

                  IF pCEF(i).CdEstruturaCarreira =
                      vRegraPercentual.CdEstruturaCarreira AND
                      vAtiv.CdNivelFormGrauEsc =
                      vRegraPercentual.CdNivelFormGrauEsc THEN

                    IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                      vvlPercentual := vRegraPercentual.VlPercentPagamento;

                    END IF;

                  ELSIF pCEF(i).CdEstruturaCarreiraCarreira =
                         vRegraPercentual.CdEstruturaCarreira AND
                         vAtiv.CdNivelFormGrauEsc =
                         vRegraPercentual.CdNivelFormGrauEsc THEN

                    IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                      vvlPercentual := vRegraPercentual.VlPercentPagamento;

                    END IF;

                  else
                    null;
                  END IF;

                ELSE

                  IF vAtiv.CdNivelFormGrauEsc =
                     vRegraPercentual.CdNivelFormGrauEsc THEN

                    IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                      vvlPercentual := vRegraPercentual.VlPercentPagamento;

                    END IF;

                  END IF;

                END IF;

              END LOOP;

            END IF;

            IF vvlPercentual > 0 THEN

              IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                        pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                        pCdOrgaoExercicio         => pCEF(i).CdOrgaoExercicio,
                                                        pCdNaturezaVinculo        => pCEF(i).CdNaturezaVinculo,
                                                        pCdRelacaoTrabalho        => pCEF(i).CdRelacaoTrabalho,
                                                        pCdRegimeTrabalho         => pCEF(i).CdRegimeTrabalho,
                                                        pCdRegimePrevidenciario   => pCEF(i).CdRegimePrevidenciario,
                                                        pCdSituacaoPrevidenciaria => pCEF(i).CdSituacaoPrevidenciaria,
                                                        pCdUnidadeOrganizacional  => pCEF(i).CdUnidadeOrganizacional,
                                                        pCdEstruturaCarreira      => pCEF(i).CdEstruturaCarreira,
                                                        pFlAPOOrigemCCO           => pCEF(i).FlOrigemCCO,
                                                        pFlTipoProvimento         => pCEF(i).FlEfetivacao) THEN

                -- 1) Busca a formula associada

                vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                               pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                               pCdRelacaoVinculo        => pCEF(i).CdRelacaoVinculo,
                                                                               pCdEstruturaCarreira     => pCEF(i).CdEstruturaCarreira,
                                                                               pCdUnidadeOrganizacional => pCEF(i).CdUnidadeOrganizacional);

                IF vCdExpressaoFormCalc > 0 THEN

                  vNuDiasMes := PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes,
                                                               pRubrica.FlPropMesComercial);

                  -- Proporcionaliza o percentual pelo periodo que a atividade da relacao
                  -- perdurou no mes de processamento

                  vvlPercentual := vvlPercentual * ((CASE
                                     WHEN (vAtiv.DtFim - vAtiv.DtInicio + 1) > vNuDiasMes THEN
                                      30
                                     ELSE
                                      (vAtiv.DtFim - vAtiv.DtInicio + 1)
                                   END) / vNuDiasMes);

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                        pCdVinculo               => pCEF(i).CdVinculo,
                                                        pCdRelacaoVinculo        => pCEF(i).CdRelacaoVinculo,
                                                        pCdHistRelacaoVinculo    => pCEF(i).CdHistRelVinc,
                                                        pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                        pVlIntegral              => NULL,
                                                        pVlProporcional          => NULL,
                                                        pNuSufixoRubrica         => 1,
                                                        pNuParcelas              => 1,
                                                        pVlIndice                => vvlPercentual,
                                                        pDtInicioRelacao         => pCEF(i).DtInicioRelacao,
                                                        pDtDesligamento          => pCEF(i).DtFimRelacao,
                                                        pCdUnidadeOrganizacional => pCEF(i).CdUnidadeOrganizacional,
                                                        pCdTipoOrigemRubrica     => 7,
                                                        pdtInicio                => pCEF(i).DtInicio,
                                                        pdtFim                   => pCEF(i).DtFim);

                END IF;

              END IF;

            END IF;

          END LOOP;

        END LOOP;

      END IF;

      IF pCCO.COUNT > 0 THEN

        FOR i IN pCCO.FIRST.. pCCO.LAST LOOP

          vSQLRelVinc := ' INNER JOIN eCadHistCargoCom CCO' ||
                         '    ON R.CdHistCargoCom = CCO.CdHistCargoCom' ||
                         ' INNER JOIN ECadLocalTrabalho LT' ||
                         '    ON CCO.CdHistCargoCom = LT.CdHistCargoCom';

          vWHERERelVinc := ' AND CCO.CdHistCargoCom = ' || pCCO(i).CdHistCargoCom;

          OPEN cAtiv FOR vSQL || vSQLRelVinc || vWHERE || vWHERERelVinc;
          LOOP

            FETCH cAtiv
              INTO vAtiv;

            EXIT WHEN cAtiv%NOTFOUND;

            bCandidata := TRUE;

            vvlPercentual := 0;

            IF vAtiv.CdCurso IS NOT NULL THEN

              IF vAtiv.CdCurso <> vCurriculo.CdCurso THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF vAtiv.CdCursoAgrupador IS NOT NULL THEN

              IF vAtiv.CdCursoAgrupador <> vCurriculo.CdCursoAgrupador THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF vAtiv.CdNivelFormGrauEsc IS NOT NULL THEN

              IF vAtiv.CdNivelFormGrauEsc <> vCurriculo.CdNivelFormGrauEsc THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF bCandidata THEN

              FOR vRegraPercentual IN cRegraPercentual(vAtiv.CdAdicionalPosGrad) LOOP

                IF vRegraPercentual.CdEstruturaCarreira IS NULL AND
                   vRegraPercentual.CdNivelFormGrauEsc =
                   vAtiv.CdNivelFormGrauEsc THEN

                  IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                    vvlPercentual := vRegraPercentual.VlPercentPagamento;

                  END IF;

                END IF;

              END LOOP;

            END IF;

            IF vvlPercentual > 0 THEN

              IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
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
                                                        pFlTipoProvimento         => pCCO(i).FlTipoProvimento,
                                                        pCdOpcaoRemuneracao       => pCCO(i).CdOpcaoRemuneracao) THEN

                -- 1) Busca a formula associada

                vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                               pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                               pCdRelacaoVinculo        => 2,
                                                                               pCdUnidadeOrganizacional => pCCO(i).CdUnidadeOrganizacional);

                IF vCdExpressaoFormCalc > 0 THEN

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                        pCdVinculo               => pCCO(i).CdVinculo,
                                                        pCdRelacaoVinculo        => 2,
                                                        pCdHistRelacaoVinculo    => pCCO(i).CdHistCargoCom,
                                                        pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                        pVlIntegral              => NULL,
                                                        pVlProporcional          => NULL,
                                                        pNuSufixoRubrica         => 1,
                                                        pNuParcelas              => 1,
                                                        pVlIndice                => vvlPercentual,
                                                        pDtInicioRelacao         => pCCO(i).DtInicioRelacao,
                                                        pDtDesligamento          => pCCO(i).DtFimRelacao,
                                                        pCdUnidadeOrganizacional => pCCO(i).CdUnidadeOrganizacional,
                                                        pCdTipoOrigemRubrica     => 7,
                                                        pDtInicio                => pCCO(i).DtInicio,
                                                        pDtFim                   => pCCO(i).DtFim);

                END IF;

              END IF;

            END IF;

          END LOOP;

        END LOOP;

      END IF;

      IF pFUC.COUNT > 0 THEN

        FOR i IN pFUC.FIRST.. pFUC.LAST LOOP

          vSQLRelVinc := ' INNER JOIN eCadHistFuncaoChefia FUC' ||
                         '     ON R.CdHistFuncaoChefia = FUC.CdHistFuncaoChefia' ||
                         '  INNER JOIN ECadLocalTrabalho LT' ||
                         '     ON FUC.CdHistFuncaoChefia = LT.CdHistFuncaoChefia';

          vWHERERelVinc := ' AND FUC.CdHistFuncaoChefia = ' || pFUC(i).CdHistFuncaoChefia;

          OPEN cAtiv FOR vSQL || vSQLRelVinc || vWHERE || vWHERERelVinc;
          LOOP

            FETCH cAtiv
              INTO vAtiv;

            EXIT WHEN cAtiv%NOTFOUND;

            bCandidata := TRUE;

            vvlPercentual := 0;

            IF vAtiv.CdCurso IS NOT NULL THEN

              IF vAtiv.CdCurso <> vCurriculo.CdCurso THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF vAtiv.CdCursoAgrupador IS NOT NULL THEN

              IF vAtiv.CdCursoAgrupador <> vCurriculo.CdCursoAgrupador THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF vAtiv.CdNivelFormGrauEsc IS NOT NULL THEN

              IF vAtiv.CdNivelFormGrauEsc <> vCurriculo.CdNivelFormGrauEsc THEN

                bCandidata := FALSE;

              END IF;

            END IF;

            IF bCandidata THEN

              FOR vRegraPercentual IN cRegraPercentual(vAtiv.CdAdicionalPosGrad) LOOP

                IF vRegraPercentual.CdEstruturaCarreira IS NULL AND
                   vRegraPercentual.CdNivelFormGrauEsc =
                   vAtiv.CdNivelFormGrauEsc THEN

                  IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                    vvlPercentual := vRegraPercentual.VlPercentPagamento;

                  END IF;

                END IF;

              END LOOP;

            END IF;

            IF vvlPercentual > 0 THEN

              IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica          => pRubrica,
                                                        pCdOrgao          => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                        pCdOrgaoExercicio => pFUC(i).CdOrgaoExercicio,
                                                        pCdFuncaoChefia   => pFUC(i).CdFuncaoChefia,
                                                        pFlTipoProvimento => pFUC(i).FlEfetivacao) THEN

                -- 1) Busca a formula associada

                vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                               pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                               pCdRelacaoVinculo        => 3,
                                                                               pCdUnidadeOrganizacional => vAtiv.CdUnidadeOrganizacional);

                IF vCdExpressaoFormCalc > 0 THEN

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                        pCdVinculo               => pFUC(i).CdVinculo,
                                                        pCdRelacaoVinculo        => 3,
                                                        pCdHistRelacaoVinculo    => pFUC(i).CdHistFuncaoChefia,
                                                        pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                        pVlIntegral              => NULL,
                                                        pVlProporcional          => NULL,
                                                        pNuSufixoRubrica         => 1,
                                                        pNuParcelas              => 1,
                                                        pVlIndice                => vvlPercentual,
                                                        pDtInicioRelacao         => pFUC(i).DtInicioRelacao,
                                                        pDtDesligamento          => pFUC(i).DtFimRelacao,
                                                        pCdUnidadeOrganizacional => pFUC(i).CdUnidadeOrganizacional,
                                                        pCdTipoOrigemRubrica     => 7,
                                                        pDtInicio                => pFUC(i).DtInicio,
                                                        pDtFim                   => pFUC(i).DtFim);

                END IF;

              END IF;

            END IF;

          END LOOP;

        END LOOP;

      END IF;

    END LOOP;

  END;

  PROCEDURE P029AdicionalPosGradConc(pCdPessoa      IN INTEGER,
                                     pFolha         IN PKGPAG_TIPO.rFolha,
                                     pRubrica       IN PKGPAG_TIPO.rRubrica,
                                     pFormExpr      IN PKGPAG_TIPO.tFormulaCalculo,
                                     pCEF           IN PKGPAG_TIPO.tCEF,
                                     pAPO           IN PKGPAG_TIPO.tCEF,
                                     pFUC           IN PKGPAG_TIPO.tFUC,
                                     pCCO           IN PKGPAG_TIPO.tCCO,
                                     bPagou         OUT BOOLEAN,
                                     pGrauEscEvento IN INTEGER) IS

    CURSOR cConcAdicionalCEF IS
      SELECT DISTINCT CA.CdCurso,
                      CNF.CdNivelFormGrauEsc,
                      CASE
                        WHEN CA.Dtinicioconcessao <= pFolha.dtInicioMes THEN
                         CASE
                           WHEN RA.DtInicioValidade <= pFolha.dtInicioMes THEN
                            pFolha.dtInicioMes
                           ELSE
                            RA.DtInicioValidade
                         END
                        ELSE
                         CA.DtInicioConcessao
                      END AS DtInicio,
                      CASE
                        WHEN CA.DtFimConcessao >= pFolha.dtFimMes OR
                             CA.DtFimconcessao IS NULL THEN
                         CASE
                           WHEN RA.DtfimValidade >= pFolha.dtFimMes OR
                                RA.dtFimValidade IS NULL THEN
                            pFolha.dtFimMes
                           ELSE
                            RA.DtFimvalidade
                         END
                        ELSE
                         CA.DtFimConcessao
                      END AS DtFim,
                      CA.FlRQE,
                      PC.Dtinclusao
        FROM EbpcConcessaoAdicional CA
       INNER JOIN ECadPessoaCurriculo PC
          ON CA.CdCurso = PC.CdCurso
       INNER JOIN ECadCursoNivelGrauEsc CNF
          ON CNF.CdCurso = CA.CdCurso
       INNER JOIN EBpcConcessaoAdicionalativ CAA
          ON CA.CdConcessaoAdicional = CAA.cdconcessaoadicional
       INNER JOIN ECadRelacaoVincAtividade RA
          ON RA.CdVinculo = CA.cdVinculo
       INNER JOIN eCadHistCargoEfetivo CEF
          ON RA.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo
       INNER JOIN ECadLocalTrabalho LT
          ON CEF.CdHistCargoEfetivo = LT.CdHistCargoEfetivo
       WHERE CNF.CdNivelFormGrauEsc = PC.CdNivelFormGrauEsc
         AND CA.DtInicioConcessao <= pFolha.dtFimMes
         AND LT.CdUnidadeOrganizacional = RA.CdUnidadeOrganizacional
         AND (CA.DtFimConcessao >= pFolha.dtInicioMes OR
             CA.DtFimConcessao IS NULL)
         AND (LT.DtInicio <= pFolha.dtFimMes AND
             (LT.dtFim >= pFolha.dtInicioMes OR lt.dtFim IS NULL))
         AND (RA.DtInicioValidade <= pFolha.dtFimMes AND
             (RA.DtFimValidade >= pFolha.dtInicioMes OR
             RA.DtFimValidade IS NULL))
         AND PC.CdPessoa = pCdPessoa
         AND CA.FlAnulado = PKGPAG_TIPO.cnN
         AND PC.CdNivelFormGrauEsc = CA.CdNivelFormGrauEsc
       ORDER BY CNF.CdNivelFormGrauEsc DESC;

    CURSOR cConcAdicionalCCO IS
      SELECT DISTINCT CA.CdCurso,
                      CNF.CdNivelFormGrauEsc,
                      CASE
                        WHEN CA.Dtinicioconcessao <= pFolha.dtInicioMes THEN
                         CASE
                           WHEN RA.Dtiniciovalidade <= pFolha.dtInicioMes THEN
                            pFolha.dtInicioMes
                           ELSE
                            RA.DtInicioValidade
                         END
                        ELSE
                         CA.DtInicioConcessao
                      END AS DtInicio,
                      CASE
                        WHEN CA.DtFimconcessao >= pFolha.dtFimMes OR
                             CA.DtFimconcessao IS NULL THEN
                         CASE
                           WHEN RA.DtfimValidade >= pFolha.dtFimMes OR
                                RA.dtFimValidade IS NULL THEN
                            pFolha.dtFimMes
                           ELSE
                            RA.DtFimvalidade
                         END
                        ELSE
                         CA.DtFimConcessao
                      END AS DtFim,
                      CA.FlRQE,
                      PC.Dtinclusao
        FROM EBpcConcessaoAdicional CA
       INNER JOIN ECadPessoaCurriculo PC
          ON CA.CdCurso = PC.cdCurso
       INNER JOIN ECadCursoNivelGrauEsc CNF
          ON CNF.CdCurso = CA.CdCurso
       INNER JOIN EBpcConcessaoAdicionalativ CAA
          ON CA.CdConcessaoAdicional = CAA.cdconcessaoadicional
       INNER JOIN ECadRelacaoVincAtividade RA
          ON RA.CdVinculo = CA.cdVinculo
       INNER JOIN eCadHistCargoCom CCO
          ON RA.CdHistCargoCom = CCO.CdHistCargoCom
       INNER JOIN ECadLocalTrabalho LT
          ON CCO.CdHistCargoCom = LT.CdHistCargoCom
       WHERE CNF.CdNivelFormGrauEsc = PC.CdNivelFormGrauEsc
         AND CA.DtInicioConcessao <= pFolha.dtFimMes
         AND LT.CdUnidadeOrganizacional = RA.CdUnidadeOrganizacional
         AND (CA.DtFimConcessao >= pFolha.dtInicioMes OR
             CA.DtFimConcessao IS NULL)
         AND (LT.DtInicio <= pFolha.dtFimMes AND
             (lt.dtFim >= pFolha.dtInicioMes OR lt.dtFim IS NULL))
         AND (RA.DtInicioValidade <= pFolha.dtFimMes AND
             (RA.DtFimValidade >= pFolha.dtInicioMes OR
             RA.DtFimValidade IS NULL))
         AND PC.CdPessoa = pCdPessoa
         AND CA.FlAnulado = PKGPAG_TIPO.cnN
         AND PC.CdNivelFormGrauEsc = CA.CdNivelFormGrauEsc
       ORDER BY CNF.CdNivelFormGrauEsc DESC;

    CURSOR cConcAdicional IS
      SELECT CA.CdVinculo,
             CA.CdCurso,
             PC.CdNivelFormGrauEsc,
             CASE
               WHEN CA.DtInicioConcessao <= pFolha.dtInicioMes THEN
                pFolha.dtInicioMes
               ELSE
                CA.DtInicioConcessao
             END AS DtInicio,
             CASE
               WHEN CA.DtFimConcessao > pFolha.dtFimMes OR
                    CA.DtFimConcessao IS NULL THEN
                 pFolha.dtFimMes
               ELSE
                 CA.DtFimConcessao
             END AS DtFim,  
             CA.FlRQE,
             PC.Dtinclusao,
             G.InPriorizacaoFormacao,
             G.CdGrauEscolaridade
        FROM EBpcConcessaoAdicional CA
       INNER JOIN ECadPessoaCurriculo PC
          ON CA.CdCurso = PC.CdCurso
       INNER JOIN ECadVinculo V
          ON CA.CdVinculo = V.CdVinculo
       INNER JOIN ECadNivelFormGrauEsc NG
          ON NG.CdNivelFormGrauEsc = PC.CdNivelFormGrauEsc
       INNER JOIN ECadGrauEscolaridade G
          ON G.CdGrauEscolaridade = NG.CdGrauEscolaridade    
       WHERE CA.DtInicioConcessao <= pFolha.dtFimMes
         AND (CA.DtFimConcessao >= pFolha.DtInicioMes OR
             CA.DtFimConcessao IS NULL)
         AND PC.CdPessoa = pCdPessoa
         AND V.CdPessoa = pCdPessoa
         AND CA.FlAnulado = PKGPAG_TIPO.cnN
         AND V.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo
         AND PC.CdNivelFormGrauEsc = CA.CdNivelFormGrauEsc
       ORDER BY G.InPriorizacaoFormacao DESC,
                CASE
                   WHEN CA.DtInicioConcessao <= pFolha.dtInicioMes THEN
                    pFolha.dtInicioMes
                   ELSE
                    CA.DtInicioConcessao
                END DESC,
                PC.CdNivelFormGrauEsc DESC;

    CURSOR cRegraPercentual(pCdNivelFormGrauEsc INTEGER, pFlRQE CHAR) IS
      SELECT RP.CdNivelFormGrauEsc,
             RP.CdEstruturaCarreira,
             RP.CdTipoItemCarreira,
             RP.VlPercentPagamento
        FROM EbpcAdicionalPosGrad AP
       INNER JOIN EBpcRegraPagNivelFormGrauEsc RP
          ON AP.CdAdicionalPosGrad = RP.CdAdicionalPosGrad
       WHERE AP.CdAgrupamento = pFolha.CdAgrupamento
         AND RP.CdNivelFormGrauEsc = pCdNivelFormGrauEsc
         AND (RP.FlRQE = pFlRQE OR RP.FlRQE = PKGPAG_TIPO.cnN)
         AND ((AP.NuAnoInicio < pFolha.NuAnoReferencia OR
             (AP.NuAnoInicio = pFolha.NuAnoReferencia AND
             AP.NumesInicio <= pFolha.NuMesReferencia)) AND
             (AP.NuAnoFim > pFolha.NuAnoReferencia OR
             (AP.NuAnoFim = pFolha.NuAnoReferencia AND
             AP.NuMesFim >= pFolha.NuMesReferencia) OR
             AP.NuMesFim IS NULL));

    bAdicAtividade BOOLEAN;
    vNuSufixo INTEGER DEFAULT 0;
    bPagouCEF BOOLEAN;
    bPagouCCO BOOLEAN;
    vInPriorizacaoFormacao INTEGER;
    vQuebraVig CHAR;

    PROCEDURE PAdicionaCEF(pCEFInt             IN PKGPAG_TIPO.rCEF,
                           pCdNivelFormGrauEsc IN INTEGER,
                           pDtInicio           IN DATE,
                           pDtFim              IN DATE,
                           pNuSufixo           IN INTEGER,
                           pFlRQE              IN CHAR) IS

      vvlPercentual NUMBER(7, 4);

      vCdExpressaoFormCalc INTEGER;

      vNuDiasMes INTEGER;

      vNuDias INTEGER;

      vEstrutura PKGPAG_TIPO.tLista;

      i INTEGER;

    BEGIN

      vvlPercentual := 0;

      FOR vRec IN (SELECT C.CdEstruturaCarreira, IC.CdTipoItemCarreira
                     FROM ECadEstruturaCarreira C
                    INNER JOIN ECadItemCarreira IC
                       ON C.CdItemCarreira = IC.CdItemCarreira
                   CONNECT BY PRIOR
                               cdEstruturaCarreiraPai = cdEstruturaCarreira
                    START WITH cdEstruturaCarreira =
                               pCEFInt.CdEstruturaCarreira
                    ORDER BY LEVEL) LOOP

        vEstrutura(vRec.CdEstruturaCarreira) := vRec.CdTipoItemCarreira;

      END LOOP;

      FOR vRegraPercentual IN cRegraPercentual(pCdNivelFormGrauEsc, pFlRQE) LOOP

       -- IF NOT bPagouCEF THEN

          IF vRegraPercentual.CdEstruturaCarreira IS NOT NULL THEN

            i := vEstrutura.FIRST;

            WHILE i <= vEstrutura.LAST LOOP

              IF i = vRegraPercentual.CdEstruturaCarreira AND
                 vEstrutura(i) = vRegraPercentual.CdTipoItemCarreira AND
                 pCdNivelFormGrauEsc = vRegraPercentual.CdNivelFormGrauEsc THEN

                IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                  vvlPercentual := vRegraPercentual.VlPercentPagamento;

                END IF;

              END IF;

              i := vEstrutura.NEXT(i);

            END LOOP;

          ELSE

            IF pCdNivelFormGrauEsc = vRegraPercentual.CdNivelFormGrauEsc THEN

              IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

                vvlPercentual := vRegraPercentual.VlPercentPagamento;

              END IF;

            END IF;

          END IF;

       -- END IF;

      END LOOP;

      IF vvlPercentual > 0 THEN

        IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                  pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                  pCdOrgaoExercicio         => pCEFInt.CdOrgaoExercicio,
                                                  pCdNaturezaVinculo        => pCEFInt.CdNaturezaVinculo,
                                                  pCdRelacaoTrabalho        => pCEFInt.CdRelacaoTrabalho,
                                                  pCdRegimeTrabalho         => pCEFInt.CdRegimeTrabalho,
                                                  pCdRegimePrevidenciario   => pCEFInt.CdRegimePrevidenciario,
                                                  pCdSituacaoPrevidenciaria => pCEFInt.CdSituacaoPrevidenciaria,
                                                  pCdUnidadeOrganizacional  => pCEFInt.CdUnidadeOrganizacional,
                                                  pCdEstruturaCarreira      => pCEFInt.CdEstruturaCarreira,
                                                  pFlAPOOrigemCCO           => pCEFInt.FlOrigemCCO,
                                                  pFlTipoProvimento         => pCEFInt.FlEfetivacao,
                                                  pCdMotivoMovimentacao     => pCEFInt.CdMotivoMovimentacao,
                                                  pCdInstitutoMovimentacao  => pCEFInt.CdInstitutoMovimentacao) THEN

          -- 1) Busca a formula associada

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                         pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                         pCdRelacaoVinculo        => pCEFInt.CdRelacaoVinculo,
                                                                         pCdEstruturaCarreira     => pCEFInt.CdEstruturaCarreira,
                                                                         pCdUnidadeOrganizacional => pCEFInt.CdUnidadeOrganizacional);

          IF vCdExpressaoFormCalc > 0 THEN

            vNuDiasMes := PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes,
                                                         pRubrica.FlPropMesComercial);

            -- Proporcionaliza o percentual pelo periodo que a atividade da relacao
            -- perdurou no mes de processamento

            IF pDtFim = pFolha.DtFimMes AND
               TO_CHAR(pFolha.DtFimMes, 'MM') = 2 THEN

              IF TO_CHAR(pFolha.DtFimMes, 'DD') = 28 THEN

                vNuDias := pDtFim - pDtInicio + 1 + 3;

              ELSE

                vNuDias := pDtFim - pDtInicio + 2;

              END IF;

            ELSE

              vNuDias := pDtFim - pDtInicio + 1;

            END IF;

            IF vNuDias > vNuDiasMes THEN

              vNuDias := vNuDiasMes;

            END IF;

            IF ((vNuDias != pCEFInt.DtFim - pCEFInt.DtInicio +1) or
                (pCEFInt.DtFim - pCEFInt.DtInicio +1 < 30))

              THEN
                -- Se proporcionaliza o percentual nao proporcionaliza o calculo da rubrica
                vvlPercentual := vvlPercentual * (vNuDias / vNuDiasMes);
              END IF;

            PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pCEFInt.CdVinculo,
                                                  pCdRelacaoVinculo     => pCEFInt.CdRelacaoVinculo,
                                                  pCdHistRelacaoVinculo => pCEFInt.CdHistRelVinc,
                                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral           => NULL,
                                                  pVlProporcional       => NULL,
                                                  pNuSufixoRubrica      => pNuSufixo,
                                                  pNuParcelas           => 1,
                                                  pVlIndice             => vvlPercentual,
                                                  pCdTipoOrigemRubrica  => 7,
                                                  pDtInicio             => pCEFInt.DtInicio,
                                                  pDtFim                => pCEFInt.DtFim);

            bPagouCEF := TRUE;

          END IF;

        END IF;

      END IF;

    END;

    PROCEDURE PAdicionaCCO(pCCO                IN PKGPAG_TIPO.rCCO,
                           pCdNivelFormGrauEsc IN INTEGER,
                           pNuSufixo           IN INTEGER,
                           pFlRQE              IN CHAR DEFAULT 'N') IS

      vvlPercentual NUMBER(7, 4);

      vCdExpressaoFormCalc INTEGER;

    BEGIN

      vvlPercentual := 0;

      FOR vRegraPercentual IN cRegraPercentual(pCdNivelFormGrauEsc, pFlRQE) LOOP

        IF vRegraPercentual.CdEstruturaCarreira IS NULL THEN

          IF pCdNivelFormGrauEsc = vRegraPercentual.CdNivelFormGrauEsc THEN

            IF vvlPercentual < vRegraPercentual.VlPercentPagamento THEN

              vvlPercentual := vRegraPercentual.VlPercentPagamento;

            END IF;

          END IF;

        END IF;

      END LOOP;

      IF vvlPercentual > 0 THEN

        IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                  pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                  pCdOrgaoExercicio         => pCCO.CdOrgaoExercicio,
                                                  pCdNaturezaVinculo        => pCCO.CdNaturezaVinculo,
                                                  pCdRelacaoTrabalho        => pCCO.CdRelacaoTrabalho,
                                                  pCdRegimeTrabalho         => pCCO.CdRegimeTrabalho,
                                                  pCdRegimePrevidenciario   => pCCO.CdRegimePrevidenciario,
                                                  pCdSituacaoPrevidenciaria => pCCO.CdSituacaoPrevidenciaria,
                                                  pCdCargoComissionado      => pCCO.CdCargoComissionado,
                                                  pCdGrupoOcupacional       => pCCO.CdGrupoOcupacional,
                                                  pCdUnidadeOrganizacional  => pCCO.CdUnidadeOrganizacional,
                                                  pFlTipoProvimento         => pCCO.FlTipoProvimento,
                                                  pCdOpcaoRemuneracao       => pCCO.CdOpcaoRemuneracao) THEN

          -- 1) Busca a formula associada

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                => pFormExpr,
                                                                         pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                                         pCdRelacaoVinculo        => 2,
                                                                         pCdUnidadeOrganizacional => pCCO.CdUnidadeOrganizacional);

          IF vCdExpressaoFormCalc > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pCCO.CdVinculo,
                                                  pCdRelacaoVinculo        => 2,
                                                  pCdHistRelacaoVinculo    => pCCO.CdHistCargoCom,
                                                  pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                  pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral              => NULL,
                                                  pVlProporcional          => NULL,
                                                  pNuSufixoRubrica         => pNuSufixo,
                                                  pNuParcelas              => 1,
                                                  pVlIndice                => vvlPercentual,
                                                  pDtInicioRelacao         => pCCO.DtInicio,
                                                  pDtDesligamento          => pCCO.DtFimRelacao,
                                                  pCdUnidadeOrganizacional => pCCO.CdUnidadeOrganizacional,
                                                  pCdTipoOrigemRubrica     => 7,
                                                  pDtInicio                => pCCO.DtInicio,
                                                  pDtFim                   => pCCO.DtFim);

            bPagouCCO := TRUE;

          END IF;

        END IF;

      END IF;

    END;

  BEGIN

    bPagouCEF := FALSE;

    bPagouCCO := FALSE;

    IF pCEF.COUNT > 0 THEN

      FOR i IN pCEF.FIRST.. pCEF.LAST LOOP

        --Quando existe mais de um CEF para o mesmo vinculo
        IF i>=2 AND pCEF(i).DtFim + 1 <= pCEF(i-1).DtInicio
          THEN
             bPagouCEF := FALSE;
        END IF;

        bAdicAtividade := FALSE;

        FOR vConcAdicionalCEF IN cConcAdicionalCEF LOOP

          vNuSufixo := vNuSufixo + 1;

          PAdicionaCEF(pCEF(i),
                       vConcAdicionalCEF.CdNivelFormGrauEsc,
                       vConcAdicionalCEF.DtInicio,
                       vConcAdicionalCEF.DtFim,
                       vNuSufixo,
                       vConcAdicionalCEF.FlRQE);

        END LOOP;

        IF NOT bPagouCEF THEN

          vInPriorizacaoFormacao := 0;
          
          vQuebraVig := NULL;
          
          FOR vConcAdicional IN cConcAdicional LOOP

            IF (vInPriorizacaoFormacao = vConcAdicional.InPriorizacaoFormacao AND (vQuebraVig = 'S' AND vConcAdicional.DtFim < pFolha.dtFimMes))
               OR
               (vInPriorizacaoFormacao <> vConcAdicional.InPriorizacaoFormacao AND 
               ((vQuebraVig = 'S' AND vConcAdicional.DtFim < pFolha.dtFimMes) OR vQuebraVig IS NULL)) THEN
              
              IF vConcAdicional.CdGrauEscolaridade = pGrauEscEvento OR pGrauEscEvento IS NULL THEN
                 
                 vNuSufixo := vNuSufixo + 1;

                 PAdicionaCEF(pCEF(i),
                              vConcAdicional.CdNivelFormGrauEsc,
                              vConcAdicional.DtInicio,
                              vConcAdicional.DtFim,
                              vNuSufixo,
                              vConcAdicional.flRQE);
                              
              END IF;
                           
              vInPriorizacaoFormacao := vConcAdicional.InPriorizacaoFormacao;     
               
              IF vConcAdicional.DtInicio > pFolha.dtInicioMes THEN
                
                vQuebraVig := 'S';
                
              ELSE
                
                vQuebraVig := 'N';
                
              END IF;          

            END IF;
            
          END LOOP;

        END IF;

      END LOOP;

    END IF;

    vNuSufixo := 0;

    IF pCCO.COUNT > 0 THEN

      FOR i IN pCCO.FIRST.. pCCO.LAST LOOP

        bAdicAtividade := FALSE;

        FOR vConcAdicionalCCO IN cConcAdicionalCCO LOOP

          vNuSufixo := vNuSufixo + 1;

          PAdicionaCCO(pCCO(i),
                       vConcAdicionalCCO.CdNivelFormGrauEsc,
                       vNuSufixo,
                       vConcAdicionalCCO.FlRQE);

        END LOOP;

        IF NOT bPagouCCO THEN

          vInPriorizacaoFormacao := 0;
          
          vQuebraVig := NULL;
          
          FOR vConcAdicional IN cConcAdicional LOOP
            
            IF (vInPriorizacaoFormacao = vConcAdicional.InPriorizacaoFormacao AND (vQuebraVig = 'S' AND vConcAdicional.DtFim < pFolha.dtFimMes))
               OR
               (vInPriorizacaoFormacao <> vConcAdicional.InPriorizacaoFormacao AND 
               ((vQuebraVig = 'S' AND vConcAdicional.DtFim < pFolha.dtFimMes) OR vQuebraVig IS NULL)) THEN
              
              IF vConcAdicional.CdGrauEscolaridade = pGrauEscEvento OR pGrauEscEvento IS NULL THEN

                 vNuSufixo := vNuSufixo + 1;

                 PAdicionaCCO(pCCO(i),
                              vConcAdicional.CdNivelFormGrauEsc,
                              vNuSufixo,
                              vConcAdicional.FlRQE);
                           
              END IF;
                           
              vInPriorizacaoFormacao := vConcAdicional.InPriorizacaoFormacao;              
              

              IF vConcAdicional.DtInicio > pFolha.dtInicioMes THEN
                
                vQuebraVig := 'S';
                
              ELSE
                
                vQuebraVig := 'N';
                
              END IF;      
              
            END IF;
            
          END LOOP;

        END IF;

      END LOOP;

    END IF;

    IF pAPO.COUNT > 0 AND NOT bPagouCEF THEN

      bPagouCEF := FALSE;
      
      FOR i IN pAPO.FIRST.. pAPO.LAST LOOP
        
        vInPriorizacaoFormacao := 0;
      
        vQuebraVig := NULL;
        
        FOR vConcAdicional IN cConcAdicional LOOP

          IF (vInPriorizacaoFormacao = vConcAdicional.InPriorizacaoFormacao AND (vQuebraVig = 'S' AND vConcAdicional.DtFim < pFolha.dtFimMes))
               OR
               (vInPriorizacaoFormacao <> vConcAdicional.InPriorizacaoFormacao AND 
               ((vQuebraVig = 'S' AND vConcAdicional.DtFim < pFolha.dtFimMes) OR vQuebraVig IS NULL)) THEN
                
            IF vConcAdicional.CdGrauEscolaridade = pGrauEscEvento OR pGrauEscEvento IS NULL THEN  
            
               vNuSufixo := vNuSufixo + 1;

               PAdicionaCEF(pAPO(i),
                            vConcAdicional.CdNivelFormGrauEsc,
                            vConcAdicional.DtInicio,
                            vConcAdicional.DtFim,
                            vNuSufixo,
                            vConcAdicional.FlRQE);
                         
            END IF;  
                       
            vInPriorizacaoFormacao := vConcAdicional.InPriorizacaoFormacao;              

            IF vConcAdicional.DtInicio > pFolha.dtInicioMes THEN
                
              vQuebraVig := 'S';
                
            ELSE
                
              vQuebraVig := 'N';
                
            END IF;      
              
          END IF;              

        END LOOP;

      END LOOP;

    END IF;

    IF bPagouCEF OR bPagouCCO THEN

      bPagou := TRUE;

    END IF;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P033ValeTranspPecunia
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P033ValeTranspPecunia(pFolha     IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo IN INTEGER,
                                  pRubrica   IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                                  pCEF       IN PKGPAG_TIPO.tCEF,
                                  pCCO       IN PKGPAG_TIPO.tCCO,
                                  pCCOSubst  IN PKGPAG_TIPO.tCCO,
                                  pFUC       IN PKGPAG_TIPO.tFUC,
                                  pBOL       IN PKGPAG_TIPO.tBOL,
                                  pAPO       IN PKGPAG_TIPO.tCEF) IS

  BEGIN

    PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2,
                                         pFolha               => pFolha,
                                         pCdVinculo           => pCdVinculo,
                                         pRubrica             => pRubrica,
                                         pFormExpr            => pFormExpr,
                                         pFlPrincipal         => PKGPAG_TIPO.cnS,
                                         pCEF                 => pCEF,
                                         pCCO                 => pCCO,
                                         pCCOSubst            => pCCOSubst,
                                         pFUC                 => pFUC,
                                         pBOL                 => pBOL,
                                         pAPO                 => pAPO,
                                         pVlIndice            => 0,
                                         pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                         pCdTipoOrigemRubrica => 13);

  END;

   FUNCTION FPossuiRubFolhaSuplDefinitiva(pCdOrgao             IN INTEGER,
                                          pCdVinculo           IN INTEGER,
                                          pNuAnoMesReferencia  IN INTEGER,
                                          pCdRubricaAgrupaento IN INTEGER)
     RETURN BOOLEAN IS

     --vCdFolha      INTEGER;
     vValorRubrica INTEGER;

   BEGIN

     SELECT SUM(RUB.Vlpagamento)
       INTO vValorRubrica
       FROM EPagFolhaPagamento FP
      INNER JOIN epaghistoricorubricavinculo RUB
         ON RUB.Cdfolhapagamento = FP.Cdfolhapagamento
      WHERE FP.CdOrgao = pCdOrgao
        AND FP.NuAnoMesReferencia = pNuAnoMesReferencia
        AND
           -- FP.CdTipoFolhaPagamento = pCdTipoFolhaPagamento AND
            FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl
        AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
        AND RUB.Cdrubricaagrupamento = pCdRubricaAgrupaento
        AND RUB.Cdvinculo = pCdVinculo;

     IF vValorRubrica > 0 THEN
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

   FUNCTION FPossuiContraCheque(pCdVinculo        IN INTEGER,
                                pCdFolhaPagamento IN INTEGER)

     RETURN BOOLEAN IS

     vCont integer := 0;

   BEGIN

    select 1
      into vcont
      from epaghistoricorubricavinculo rub
     where rub.cdfolhapagamento = pCdFolhaPagamento
       and rub.Cdvinculo = pCdVinculo
       and rownum < 2;

    if vCont > 0 then
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
  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P034035SalMaternidade
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P034035SalMaternidade(pFolha     IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo IN INTEGER,
                                  pRubrica   IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                                  pCEF       IN PKGPAG_TIPO.tCEF,
                                  pCCO       IN PKGPAG_TIPO.tCCO,
                                  pCCOSubst  IN PKGPAG_TIPO.tCCO,
                                  pFUC       IN PKGPAG_TIPO.tFUC,
                                  pBOL       IN PKGPAG_TIPO.tBOL,
                                  pAPO       IN PKGPAG_TIPO.tCEF) IS

    vAfastGravidez PKGPAG_TIPO.rAfastGravidez;
    vVlBase NUMBER(13, 2);
    vRubrica PKGPAG_TIPO.rRubrica;
    vNuAnoMesInicio INTEGER;
    vNuAnoMesFim INTEGER;
    vBPossuiFolhaSuplDefinitiva BOOLEAN;
    vCdRubrica INTEGER;
    vFlPrincipal CHAR default 'N';

  BEGIN

    pkgpag_var.vgAfastGravidez := vAfastGravidez;

    vVlBase := 0;

    pkgpag_var.vgAfastGravidez := PKGPAG_GERAL.FDiasAfastGravidez(pCdVinculo,
                                                                  PKGPAG_VAR.vgFolha.DtInicioMes,
                                                                  PKGPAG_VAR.vgFolha.DtFimMes,
                                                                  PKGPAG_VAR.vDtCalculo,
                                                                  pRubrica);

    IF NVL(pkgpag_var.vgAfastGravidez.NuDias, 0) > 0 THEN

         PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro => 2,
                                              pFolha        => pFolha,
                                              pCdVinculo    => pCdVinculo,
                                              pRubrica      => pRubrica,
                                              pFormExpr     => pFormExpr,
                                              pFlPrincipal  => vFlPrincipal, --pkgpag_var.vgRelVincPrincipal.CdHistPKGPAG_TIPO.cnS,
                                              pCEF          => pCEF,
                                              pCCO          => pCCO,
                                              pCCOSubst     => pCCOSubst,
                                              pFUC          => pFUC,
                                              pBOL          => pBOL,
                                              pAPO          => pAPO,
                                              pVlIndice     => pkgpag_var.vgAfastGravidez.NuDias,
                                              pDtCalculo    => PKGPAG_VAR.vDtCalculo);

      ------------------------------------------------------------------------------
      --Verifica se houve pagamento da rubrica 02-0009 ou 6-509  em folha suplementar
      ------------------------------------------------------------------------------
      vCdRubrica := pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                 (CASE
                                   pRubrica.CdTipoRubrica
                                    WHEN 1 THEN
                                     2
                                    ELSE
                                     6
                                  END),
                                  pRubrica.NuRubrica);

     vBPossuiFolhaSuplDefinitiva := FPossuiRubFolhaSuplDefinitiva(pFolha.CdOrgao,
                                                          pCdVinculo,
                                                          to_char(add_months(pFolha.DtCalculo,-1) , 'yyyymm'),
                                                          vCdRubrica);

     ------------------------------------------------------------------------------
      --Verifica se houve pagamento da rubrica 01-0009 ou 5-0509  em folha anterior
      ------------------------------------------------------------------------------
     vCdRubrica := pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                  pRubrica.CdTipoRubrica,
                                  pRubrica.NuRubrica);

      IF pkgpag_var.vgAfastGravidez.DtInclusao BETWEEN (PKGPAG_VAR.vDtCalculoAnt + 1) AND
         PKGPAG_VAR.vDtCalculo AND
         pkgpag_var.vgAfastGravidez.DtInicio < pFolha.DtInicioMes AND
         vBPossuiFolhaSuplDefinitiva = FALSE THEN

      ------------------------------------------------------------------------------
      -- Determina se o afastamento e retroativo e deve pagar a rubrica 02 ou 06
      ------------------------------------------------------------------------------

        vNuAnoMesInicio := TO_CHAR(pkgpag_var.vgAfastGravidez.DtInicio, 'YYYYMM');
        vNuAnoMesFim := TO_CHAR(pFolha.DtInicioMes - 1, 'YYYYMM');

        /* ATENÇÃO: O DBA Victor fixou o plano de execução dessa query via baseline.
         * Qualquer alteração deve ser informada ao suporte oracle para que eles
         * acompanhem a execução e verifiquem se o novo plano está bom
         *****/
        -- Retorna o valor da base
        FOR vRec IN (SELECT TRUNC(TO_DATE(FP.NuAnoMesReferencia, 'YYYYMM')) DtInicioMes,
                            LAST_DAY(TRUNC(TO_DATE(FP.NuAnoMesReferencia,
                                                   'YYYYMM'))) DtFimMes,
                            VlPagamento
                       FROM EPagHistoricoRubricaVinculo HRV
                      INNER JOIN EPagFolhaPagamento FP
                         ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
                      INNER JOIN EPagTipoFolhaPagamento TFP
                         ON TFP.CdTipoFolhaPagamento =
                            FP.CdTipoFolhaPagamento
                      WHERE HRV.CdVinculo = pCdVinculo
                        AND HRV.CdRubricaAgrupamento =
                            PKGPAG_VAR.vgCdBaseSalMaternidade
                        AND TFP.CdTipoFolha = 1
                        AND FP.FlCalculoDefinitivo = 'S'
                        AND FP.NuAnoMesReferencia BETWEEN vNuAnoMesInicio AND vNuAnoMesFim
                        AND NOT EXISTS (
                               SELECT 1
                               FROM EPagHistoricoRubricaVinculo HRV2
                               INNER JOIN EPagFolhaPagamento FP2
                                   ON FP2.CdFolhaPagamento = HRV2.CdFolhaPagamento
                               WHERE HRV2.CdVinculo = pCdVinculo
                                  AND HRV2.CdRubricaAgrupamento =  vCdRubrica
                                  AND FP2.CdTipoFolhapagamento = FP.CdTipoFolhapagamento
                                  AND FP2.CdTipoCalculo = FP.CdTipoCalculo
                                  AND FP2.NuAnoMesReferencia = FP.NuAnoMesReferencia
                                  AND FP2.FlCalculoDefinitivo = 'S'
                            )
                        ) LOOP

          IF pkgpag_var.vgAfastGravidez.DtInicio BETWEEN vRec.DtInicioMes AND
             vRec.DtFimMes THEN

            vvlBase := vvlBase +
                       vRec.VlPagamento * (LEAST((vRec.DtFimMes - pkgpag_var.vgAfastGravidez.DtInicio + 1), 30) / 30);

          ELSE

            vVlBase := vVlBase + vRec.VlPagamento;

          END IF;

        END LOOP;

        IF vVlBase > 0 THEN

          vRubrica := PKGPAG_VAR.vgRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                        (CASE
                                                                         pRubrica.CdTipoRubrica
                                                                          WHEN 1 THEN
                                                                           2
                                                                          ELSE
                                                                           6
                                                                        END),
                                                                        pRubrica.NuRubrica));

          PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro  => 1,
                                               pFolha         => pFolha,
                                               pCdVinculo     => pCdVinculo,
                                               pRubrica       => vRubrica,
                                               pFormExpr      => pFormExpr,
                                               pFlPrincipal   => PKGPAG_TIPO.cnS,
                                               pCEF           => pCEF,
                                               pCCO           => pCCO,
                                               pCCOSubst      => pCCOSubst,
                                               pFUC           => pFUC,
                                               pBOL           => pBOL,
                                               pAPO           => pAPO,
                                               pVlIndice      => NULL,
                                               pDtCalculo     => PKGPAG_VAR.vDtCalculo,
                                               pValorIntegral => vVlBase);

        END IF;

      END IF;

    END IF;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P011DiasAfastNaoTrab
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P011036DiasAfastNaoTrab(pFolha      IN PKGPAG_TIPO.rFolha,
                                    pCdVinculo  IN INTEGER,
                                    pRubrica    IN PKGPAG_TIPO.rRubrica,
                                    pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo,
                                    pCEF        IN PKGPAG_TIPO.tCEF,
                                    pCCO        IN PKGPAG_TIPO.tCCO,
                                    pCCOSubst   IN PKGPAG_TIPO.tCCO,
                                    pFUC        IN PKGPAG_TIPO.tFUC,
                                    pBOL        IN PKGPAG_TIPO.tBOL,
                                    pAPO        IN PKGPAG_TIPO.tCEF,
                                    pFlAcidente IN CHAR DEFAULT 'N') IS

    vDiasAfastNaoTrab INTEGER;

  BEGIN

    vDiasAfastNaoTrab := PKGPAG_GERAL.FDiasAfastTempNaoRem(pCdVinculo,
                                                           PKGPAG_VAR.vgFolha.DtInicioMes,
                                                           PKGPAG_VAR.vgFolha.DtFimMes,
                                                           PKGPAG_VAR.vDtCalculo,
                                                           pFlAcidente);

    IF nvl(vDiasAfastNaoTrab, 0) > 0 THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro => 2,
                                           pFolha        => pFolha,
                                           pCdVinculo    => pCdVinculo,
                                           pRubrica      => pRubrica,
                                           pFormExpr     => pFormExpr,
                                           pFlPrincipal  => PKGPAG_TIPO.cnN,
                                           pCEF          => pCEF,
                                           pCCO          => pCCO,
                                           pCCOSubst     => pCCOSubst,
                                           pFUC          => pFUC,
                                           pBOL          => pBOL,
                                           pAPO          => pAPO,
                                           pVlIndice     => vDiasAfastNaoTrab,
                                           pDtCalculo    => PKGPAG_VAR.vDtCalculo);

    END IF;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P063MediaFerias
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P063MediaFerias(pFolha      IN PKGPAG_TIPO.rFolha,
                            pCdVinculo  IN INTEGER,
                            pRubrica    IN PKGPAG_TIPO.rRubrica,
                            pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo,
                            pCEF        IN PKGPAG_TIPO.tCEF,
                            pCCO        IN PKGPAG_TIPO.tCCO,
                            pCCOSubst   IN PKGPAG_TIPO.tCCO,
                            pFUC        IN PKGPAG_TIPO.tFUC,
                            pBOL        IN PKGPAG_TIPO.tBOL,
                            pAPO        IN PKGPAG_TIPO.tCEF,
                            pFlAcidente IN CHAR DEFAULT 'N') IS

    vCdPeriodoAquisitivoFerias INTEGER;

  BEGIN

  IF pFolha.cdAgrupamento = 276
    THEN

     SELECT PA.CdPeriodoAquisitivoFerias
      INTO vCdPeriodoAquisitivoFerias
      FROM EMovPeriodoAquisitivoFerias PA
     INNER JOIN EMovFeriasFruicaoUsufruto USU
        ON PA.CdPeriodoAquisitivoFerias = USU.CdPeriodoAquisitivoFerias
     INNER JOIN emovferiasfruicaopagamento ffp
        on ffp.cdperiodoaquisitivoferias = pa.cdperiodoaquisitivoferias
     WHERE PA.CdVinculo = pCdVinculo
       AND USU.FlAnulado = PKGPAG_TIPO.cnN
        AND ffp.nuanoreferencia = pFolha.NuAnoReferencia
        AND ffp.numesreferencia = pFolha.NuMesReferencia
       AND ROWNUM < 2;

  ELSE
    SELECT PA.CdPeriodoAquisitivoFerias
      INTO vCdPeriodoAquisitivoFerias
      FROM EMovPeriodoAquisitivoFerias PA
     INNER JOIN EMovFeriasFruicaoUsufruto USU
        ON PA.CdPeriodoAquisitivoFerias = USU.CdPeriodoAquisitivoFerias
     WHERE PA.CdVinculo = pCdVinculo
       AND USU.FlAnulado = PKGPAG_TIPO.cnN
       AND USU.DtInicial BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes
       AND ROWNUM < 2;

    END IF;

    IF NOT PKGPAG_GERAL.FPossuiInterrupcaoUsufruto(vCdPeriodoAquisitivoFerias,
                                                   pFolha.DtInicioMes,
                                                   pFolha.DtFimMes) THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro => 2,
                                           pFolha        => pFolha,
                                           pCdVinculo    => pCdVinculo,
                                           pRubrica      => pRubrica,
                                           pFormExpr     => pFormExpr,
                                           pFlPrincipal  => PKGPAG_TIPO.cnN,
                                           pCEF          => pCEF,
                                           pCCO          => pCCO,
                                           pCCOSubst     => pCCOSubst,
                                           pFUC          => pFUC,
                                           pBOL          => pBOL,
                                           pAPO          => pAPO,
                                           pVlIndice     => 100,
                                           pDtCalculo    => PKGPAG_VAR.vDtCalculo);
  END IF;

  EXCEPTION

    WHEN OTHERS THEN

      NULL;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P037038LicencaPremioPecAssid
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P037038LicencaPremioPecAssid(pFolha            IN PKGPAG_TIPO.rFolha,
                                         pCdVinculo        IN INTEGER,
                                         pRubrica          IN PKGPAG_TIPO.rRubrica,
                                         pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                                         pCdTipoEvento     IN INTEGER,
                                         pCEF              IN PKGPAG_TIPO.tCEF,
                                         pCCO              IN PKGPAG_TIPO.tCCO,
                                         pCCOSubst         IN PKGPAG_TIPO.tCCO,
                                         pFUC              IN PKGPAG_TIPO.tFUC,
                                         pBOL              IN PKGPAG_TIPO.tBOL,
                                         pAPO              IN PKGPAG_TIPO.tCEF,
                                         pFlCalcDefinitivo IN CHAR DEFAULT PKGPAG_TIPO.cnN) IS

    vQtDiasLicPre INTEGER;

    vCdTipoLicencaPremio INTEGER;

  BEGIN

    vCdTipoLicencaPremio := CASE pCdTipoEvento
                              WHEN 37 THEN
                               1
                              WHEN 38 THEN
                               2
                              ELSE
                               0
                            END;

    /* Atualiza os registros de indenizacao de licenca premio/ premio assiduidade*/

    UPDATE EAfaLicencaPremio LP
       SET LP.QtDiasPagos = NULL, LP.NuAnoPago = NULL, LP.NuMesPago = NULL
     WHERE LP.NuAnoPago = pFolha.NuAnoReferencia
       AND LP.NuMesPago = pFolha.NuMesReferencia
       AND LP.CdPeriodoAquisitivo IN
           (SELECT CdPeriodoAquisitivo
              FROM EafaPeriodoAquisitivoLP PA
             WHERE PA.CdVinculo = pCdVinculo
               AND PA.CdTipoLicencaPremio = vCdTipoLicencaPremio
               AND PA.CdSituacaoPerAquisitivo = 2);

    vQtDiasLicPre := PKGPAG_GERAL.FDiasLicPremio(pCdVinculo,
                                                 pFolha.NuAnoReferencia,
                                                 pFolha.NuMesReferencia,
                                                 vCdTipoLicencaPremio,
                                                 8);

    IF NVL(vQtDiasLicPre, 0) > 0 THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro => 2,
                                           pFolha        => pFolha,
                                           pCdVinculo    => pCdVinculo,
                                           pRubrica      => pRubrica,
                                           pFormExpr     => pFormExpr,
                                           pFlPrincipal  => PKGPAG_TIPO.cnN,
                                           pCEF          => pCEF,
                                           pCCO          => pCCO,
                                           pCCOSubst     => pCCOSubst,
                                           pFUC          => pFUC,
                                           pBOL          => pBOL,
                                           pAPO          => pAPO,
                                           pVlIndice     => vQtDiasLicPre,
                                           pDtCalculo    => PKGPAG_VAR.vDtCalculo);

      IF (pFolha.FlCalculoDefinitivo = PKGPAG_TIPO.cnS or pFlCalcDefinitivo = PKGPAG_TIPO.cnS)

        THEN

        UPDATE eafalicencapremio lp
           SET lp.qtdiaspagos = lp.qtdias,
               lp.nuanopago   = pfolha.nuanoreferencia,
               lp.numespago   = pfolha.numesreferencia
         WHERE ((lp.nuanopagamento < pfolha.nuanoreferencia) OR
               (lp.nuanopagamento = pfolha.nuanoreferencia AND
               lp.numespagamento <= pfolha.numesreferencia))
           AND nvl(lp.qtdiaspagos, 0) = 0
           AND lp.cdperiodoaquisitivo IN
               (SELECT cdperiodoaquisitivo
                  FROM eafaperiodoaquisitivolp pa
                 WHERE pa.cdvinculo = pcdvinculo
                   AND pa.cdtipolicencapremio = vcdtipolicencapremio
                   AND pa.cdsituacaoperaquisitivo = 2);
      END IF;

    END IF;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P039VantagemLei43
  --
  --  Objetivo: Gerar registro de pagamento para as relacoes de vinculo de um vinculo que possua
  --            cargo efetivo e registro vigente relativo a vantagem da Lei 43
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P039VantagemLei43(pFolha     IN PKGPAG_TIPO.rFolha,
                              pCdVinculo IN INTEGER,
                              pRubrica   IN PKGPAG_TIPO.rRubrica,
                              pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                              pCEF       IN PKGPAG_TIPO.tCEF,
                              pCCO       IN PKGPAG_TIPO.tCCO,
                              pCCOSubst  IN PKGPAG_TIPO.tCCO,
                              pFUC       IN PKGPAG_TIPO.tFUC,
                              pAPO       IN PKGPAG_TIPO.tCEF,
                              pBOL       IN PKGPAG_TIPO.tBOL) IS

    D1 NUMBER;
    P1 NUMBER;
    V4 NUMBER;
    V5 NUMBER;
    V6 NUMBER;

    FUNCTION FAplicaReajuste(pCdEstruturaCarreira IN INTEGER,
                             pDtFimMes            IN DATE,
                             pvlCalculado         IN NUMBER)

     RETURN NUMBER IS

      vvlReajustado NUMBER;

    BEGIN

      vVlReajustado := pVlCalculado;

      FOR vReajuste IN (SELECT TO_CHAR(dtReajuste, 'YYYYMM') nuAnoMes,
                               vlPercentReajuste,
                               Nivel
                          FROM (SELECT EC.CdEstruturaCarreira, LEVEL AS nivel
                                  FROM eCadEstruturaCarreira EC
                                 START WITH EC.CdEstruturaCarreira =
                                            pCdEstruturaCArreira
                                CONNECT BY PRIOR EC.CdEstruturaCarreiraPai =
                                            EC.CdEstruturaCarreira) E
                         INNER JOIN EpagReajGeralSalario RS
                            ON E.CdEstruturaCarreira =
                               RS.CdEstruturaCarreira
                         INNER JOIN (SELECT TO_CHAR(DtReajuste, 'YYYYMM') AS NuAnoMes,
                                           MIN(Nivel) AS NivelMin
                                      FROM (SELECT EC.CdEstruturaCarreira,
                                                   LEVEL AS Nivel
                                              FROM ECadEstruturaCarreira EC
                                             START WITH EC.CdEstruturaCarreira =
                                                        pCdEstruturaCarreira
                                            CONNECT BY PRIOR
                                                        EC.CdEstruturaCarreiraPai =
                                                        EC.CdEstruturaCarreira) E
                                     INNER JOIN EpagReajGeralSalario RS
                                        ON E.CdEstruturaCarreira =
                                           RS.CdEstruturaCarreira
                                     WHERE DtReajuste <= pdtFimMes
                                     GROUP BY TO_CHAR(DtReajuste, 'YYYYMM')) A
                            ON A.NuAnoMes = TO_CHAR(DtReajuste, 'YYYYMM')
                           AND A.NivelMin = E.Nivel
                         WHERE DtReajuste <= pdtFimMes) LOOP

        vVlReajustado := vVlReajustado +
                         (vVlReajustado * vReajuste.vlPercentReajuste) / 100;

      END LOOP;

      RETURN vVlReajustado;

    END;

  BEGIN

    IF pCEF.COUNT > 0 THEN

      FOR i IN pCEF.FIRST.. pCEF.LAST LOOP

        FOR vVantagem IN (SELECT VL.CdVinculo,
                                 NVL(VL.VlCCO1991, 0) VlCCO1991,
                                 NVL(VL.VlCEF1991, 0) VlCEF1991,
                                 NVL(VL.VLCEF1993, 0) VLCEF1993,
                                 NVL(VL.VLFUC1991, 0) VLFUC1991
                            FROM EbpcVantagemLei43 VL
                           WHERE VL.CdVinculo = pCdVinculo
                             AND VL.DtInicioVigencia <= pFolha.dtFimMes
                             AND (VL.DtFimVigencia >= pFolha.dtInicioMes OR
                                 VL.DtFimVigencia IS NULL)) LOOP

          D1 := ABS(vVantagem.VlCCO1991 - vVantagem.VlCEF1991);

          P1 := (D1 / vVantagem.VlCEF1991);

          V4 := vVantagem.VlCEF1993 * P1;

          V5 := FAplicaReajuste(pCEF(i).CdEstruturaCarreira,
                                pFolha.DtFimMes,
                                V4);

          V6 := (vVantagem.VLFUC1991 + vVantagem.VlCCO1991) * 0.6;

          PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 1,
                                               pFolha               => pFolha,
                                               pCdVinculo           => pCdVinculo,
                                               pRubrica             => pRubrica,
                                               pFormExpr            => pFormExpr,
                                               pFlPrincipal         => PKGPAG_TIPO.cnN,
                                               pCEF                 => pCEF,
                                               pCCO                 => pCCO,
                                               pCCOSubst            => pCCOSubst,
                                               pFUC                 => pFUC,
                                               pBOL                 => pBOL,
                                               pAPO                 => pAPO,
                                               pVlIndice            => NULL,
                                               pValorIntegral       => V6 + V5,
                                               pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                               pCdTipoOrigemRubrica => 6);

        END LOOP;

      END LOOP;

    END IF;

  END;

  PROCEDURE P052Rescisao13Salario(pFolha          IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo      IN INTEGER,
                                  pRubrica        IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr       IN PKGPAG_TIPO.tFormulaCalculo,
                                  pCEF            IN PKGPAG_TIPO.tCEF,
                                  pCCO            IN PKGPAG_TIPO.tCCO,
                                  pCCOSubst       IN PKGPAG_TIPO.tCCO,
                                  pFUC            IN PKGPAG_TIPO.tFUC,
                                  pBOL            IN PKGPAG_TIPO.tBOL,
                                  pAPO            IN PKGPAG_TIPO.tCEF,
                                  pDtDesligamento IN DATE DEFAULT NULL) IS

  vVlPagamentoSupl NUMBER(13,2);
  vCdExpressaoFormCalc INTEGER := 0;
  vPossuiLFRubBloqueioRescisao BOOLEAN := FALSE;

  BEGIN

    /* Busca valores calculados do vinculo em folha normal e suplementar */
    vVlPagamentoSupl := PKGPAG_GERAL.fretornasomavalorrubricasupl(pFolha.CdFolhaPagamentoNormalAnt,
                                                                                     PKGPAG_VAR.vgVinculo.cdvinculo,
                                                                                     PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                                             2,
                                                                                                                                             pRubrica.NuRubrica));
    
    
    IF (PKGPAG_VAR.vgVinculo.DtDesligamento > pFolha.DtCalculoAnt AND NVL(vVlPagamentoSupl,0) > 0) OR 
        fPossuiContraCheque(PKGPAG_VAR.vgVinculo.CdVinculo, PKGPAG_VAR.vgCdFolha13) THEN
      --Se houve pagamento em folha suplementar ou já pagou 13, retorna.
      RETURN;
    END IF;

    -- PENSAO NAO PREVIDENCIARIA
    IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 4
      AND prubrica.NuRubrica = 3323
      THEN

      vCdExpressaoFormCalc :=

                  PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                         pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                         pCdRelacaoVinculo         => 0);

      PKGPAG_GERAL.PInsereLancamentoRelacao(
                       pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                       pCdVinculo            => pCdVinculo,
                       pCdRelacaoVinculo     => 7,
                       pCdHistRelacaoVinculo =>PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                       pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                       pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                       pVlIntegral           => NULL,
                       pVlProporcional       => NULL,
                       pNuSufixoRubrica      => 1,
                       pNuParcelas           => 1,
                       pVlIndice             => NULL,
                       pCdTipoOrigemRubrica  => 1);

       pkgpag_geral.pinserelancamentovinculo (pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                              pCdVinculo        => pCdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0);

    ELSE

    PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro   => 2,
                                         pFolha          => pFolha,
                                         pCdVinculo      => pCdVinculo,
                                         pRubrica        => pRubrica,
                                         pFormExpr       => pFormExpr,
                                         pFlPrincipal    => PKGPAG_TIPO.cnN,
                                         pCEF            => pCEF,
                                         pCCO            => pCCO,
                                         pCCOSubst       => pCCOSubst,
                                         pFUC            => pFUC,
                                         pBOL            => pBOL,
                                         pAPO            => pAPO,
                                         pVlIndice       => NULL,
                                         pDtCalculo      => PKGPAG_VAR.vDtCalculo,
                                         pDtDesligamento => pDtDesligamento);
    END IF;

    PKGPAG_VAR.vgCdRubBloqueioRescisao := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                       5,
                                                                       1983);

    vPossuiLFRubBloqueioRescisao := PKGPAG_GERAL.fpossuilancfinanceiro(pcdvinculo => pCdVinculo,
                                                                       pfolha => pFolha,
                                                                       pcdrubrica => PKGPAG_VAR.vgCdRubBloqueioRescisao);

    IF PKGPAG_VAR.vgCdRubBloqueioRescisao > 0 AND NOT vPossuiLFRubBloqueioRescisao THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro   => 2,
                                           pFolha          => pFolha,
                                           pCdVinculo      => pCdVinculo,
                                           pRubrica        => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubBloqueioRescisao),
                                           pFormExpr       => pFormExpr,
                                           pFlPrincipal    => PKGPAG_TIPO.cnN,
                                           pCEF            => pCEF,
                                           pCCO            => pCCO,
                                           pCCOSubst       => pCCOSubst,
                                           pFUC            => pFUC,
                                           pBOL            => pBOL,
                                           pAPO            => pAPO,
                                           pVlIndice       => NULL,
                                           pDtCalculo      => PKGPAG_VAR.vDtCalculo,
                                           pDtDesligamento => pDtDesligamento);

    END IF;
  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P047Devolucao13Salario
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P047Devolucao13Salario(pFolha     IN PKGPAG_TIPO.rFolha,
                                   pCdVinculo IN INTEGER,
                                   pRubrica   IN PKGPAG_TIPO.rRubrica,
                                   pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                                   pCEF       IN PKGPAG_TIPO.tCEF,
                                   pCCO       IN PKGPAG_TIPO.tCCO,
                                   pCCOSubst  IN PKGPAG_TIPO.tCCO,
                                   pFUC       IN PKGPAG_TIPO.tFUC,
                                   pBOL       IN PKGPAG_TIPO.tBOL,
                                   pAPO       IN PKGPAG_TIPO.tCEF) IS

    vCdRubrica51023 INTEGER;

    vRubrica51023 PKGPAG_TIPO.rRubrica;

  BEGIN

    PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro   => 2,
                                         pFolha          => pFolha,
                                         pCdVinculo      => pCdVinculo,
                                         pRubrica        => pRubrica,
                                         pFormExpr       => pFormExpr,
                                         pFlPrincipal    => PKGPAG_TIPO.cnS,
                                         pCEF            => pCEF,
                                         pCCO            => pCCO,
                                         pCCOSubst       => pCCOSubst,
                                         pFUC            => pFUC,
                                         pBOL            => pBOL,
                                         pAPO            => pAPO,
                                         pVlIndice       => NULL,
                                         pDtCalculo      => PKGPAG_VAR.vDtCalculo,
                                         pDtDesligamento => PKGPAG_VAR.vgVinculo.DtDesligamento);

    vCdRubrica51023 := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pFolha.CdAgrupamento,
                                                    pCdTipoRubrica => 5,
                                                    pNuRubrica     => 1023);

    IF vCdRubrica51023 > 0 THEN

      vRubrica51023 := PKGPAG_VAR.vgRubrica(vCdRubrica51023);

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro   => 2,
                                           pFolha          => pFolha,
                                           pCdVinculo      => pCdVinculo,
                                           pRubrica        => vRubrica51023,
                                           pFormExpr       => pFormExpr,
                                           pFlPrincipal    => PKGPAG_TIPO.cnS,
                                           pCEF            => pCEF,
                                           pCCO            => pCCO,
                                           pCCOSubst       => pCCOSubst,
                                           pFUC            => pFUC,
                                           pBOL            => pBOL,
                                           pAPO            => pAPO,
                                           pVlIndice       => NULL,
                                           pDtCalculo      => PKGPAG_VAR.vDtCalculo,
                                           pDtDesligamento => PKGPAG_VAR.vgVinculo.DtDesligamento);

    END IF;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P051Antecipacao13Salario
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P051Antecipacao13Salario(pFolha              IN PKGPAG_TIPO.rFolha,
                                     pCdVinculo          IN INTEGER,
                                     pRubrica            IN PKGPAG_TIPO.rRubrica,
                                     pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                                     pCEF                IN PKGPAG_TIPO.tCEF,
                                     pCCO                IN PKGPAG_TIPO.tCCO,
                                     pCCOSubst           IN PKGPAG_TIPO.tCCO,
                                     pFUC                IN PKGPAG_TIPO.tFUC,
                                     pBOL                IN PKGPAG_TIPO.tBOL,
                                     pAPO                IN PKGPAG_TIPO.tCEF,
                                     pFlPagaAdiantamento IN CHAR DEFAULT PKGPAG_TIPO.cnN -- ,
                                     -- pNuMesPagamento     IN INTEGER DEFAULT NULL
                                     ) IS

    vCont         INTEGER;
    bPagaAdiant   BOOLEAN;
    bPossuiPensao BOOLEAN;

  BEGIN

    bPagaAdiant := FALSE;

    bPossuiPensao := FALSE;

    IF pFlPagaAdiantamento = PKGPAG_TIPO.cnS THEN

      bPagaAdiant := TRUE;

    END IF;

    IF NOT bPagaAdiant THEN

      BEGIN

        SELECT 1
          INTO vCont
          FROM EMovPeriodoAquisitivoFerias PA
         INNER JOIN EMovFeriasFruicaoPagamento FFP
            ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
         WHERE PA.CdVinculo = pCdVinculo
           AND FFP.NuAnoReferencia = pFolha.NuAnoReferencia
           AND FFP.NuMesReferencia = pFolha.NuMesReferencia
           AND FFP.FlAdiantamento13 = PKGPAG_TIPO.cnS
           AND FFP.Flanulado = PKGPAG_TIPO.cnN
           AND ROWNUM < 2;

        bPagaAdiant := TRUE;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          NULL;
      END;

    END IF;

    IF bPagaAdiant THEN

      -- Verifica se paga mais de um adiantamento de 13 no ano

      IF PKGPAG_VAR.vgParamOrgao.FlRecebeAdiantamentos13 = PKGPAG_TIPO.cnN THEN

        BEGIN

          SELECT 1
            INTO vCont
            FROM EPagHistoricoRubricaVinculo HRV
           INNER JOIN EPagFolhaPagamento FP
              ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
           WHERE HRV.CdFolhaPagamento = FP.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND FP.NuAnoReferencia = pFolha.NuANoReferencia
             AND FP.NuMesReferencia <> pFolha.NuMesReferencia
             AND HRV.CdRubricaAgrupamento = pRubrica.CdRubricaAgrupamento
             AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
             AND FP.CdTipoCalculo IN (1, 5)
             AND ROWNUM < 2;

          bPagaAdiant := FALSE;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            NULL;
        END;

      END IF;

    END IF;

    IF bPagaAdiant THEN

      -- Verifica se o vinculo possui pensoes no mes de processamento
      -- para imputar o valor correto de desconto

      BEGIN

        SELECT 1
          INTO vCont
          FROM ePenSentencaJudicial SJ
         INNER JOIN EPenHistSentencaJudicial HSJ
            ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
         WHERE SJ.CdVinculo = pCdVinculo
           AND HSJ.Dtiniciovigencia <= pFolha.DtInicioMes
           AND (HSJ.DtFimVigencia >= pFolha.DtFimMes OR
               HSJ.DtFimVigencia IS NULL)
           AND ROWNUM < 2;

        bPossuiPensao := TRUE;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          NULL;
      END;

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro => 2,
                                           pFolha        => pFolha,
                                           pCdVinculo    => pCdVinculo,
                                           pRubrica      => pRubrica,
                                           pFormExpr     => pFormExpr,
                                           pFlPrincipal  => PKGPAG_TIPO.cnN,
                                           pCEF          => pCEF,
                                           pCCO          => pCCO,
                                           pCCOSubst     => pCCOSubst,
                                           pFUC          => pFUC,
                                           pBOL          => pBOL,
                                           pAPO          => pAPO,
                                           pVlIndice     => CASE
                                                              WHEN NOT
                                                                    bPossuiPensao THEN
                                                               CASE
                                                                 WHEN PKGPAG_VAR.vgParamOrgao.VlPercentAdiant13 IS NOT NULL THEN
                                                                  PKGPAG_VAR.vgParamOrgao.VlPercentAdiant13
                                                                 WHEN PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13 IS NOT NULL THEN
                                                                  PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13
                                                               END
                                                              WHEN bPossuiPensao THEN
                                                               CASE
                                                                 WHEN PKGPAG_VAR.vgParamOrgao.VlPercentAdiant13DescPensao IS NOT NULL THEN
                                                                  PKGPAG_VAR.vgParamOrgao.VlPercentAdiant13DescPensao
                                                                 WHEN PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13DescPensao IS NOT NULL THEN
                                                                  PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13DescPensao
                                                               END
                                                            END,
                                           pDtCalculo    => PKGPAG_VAR.vDtCalculo);
    END IF;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P053RemuneracaoComissao
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

PROCEDURE P053RemuneracaoComissao(pFolha                  IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo              IN INTEGER,
                                  pRubrica                IN PKGPAG_TIPO.rRubrica,
                                  pCdTipoComConselhoGrupo IN INTEGER,
                                  pNuFormulaEspecifica    IN INTEGER,
                                  pFormExpr               IN PKGPAG_TIPO.tFormulaCalculo,
                                  pCEF                    IN PKGPAG_TIPO.tCEF,
                                  pCCO                    IN PKGPAG_TIPO.tCCO,
                                  pCCOSubst               IN PKGPAG_TIPO.tCCO,
                                  pFUC                    IN PKGPAG_TIPO.tFUC,
                                  pBOL                    IN PKGPAG_TIPO.tBOL,
                                  pAPO                    IN PKGPAG_TIPO.tCEF,
                                  pCdHistEventoPagAgrup   IN INTEGER) IS

  vNuSufixo            INTEGER;
  vvlIndice            NUMBER(7, 4);
  vvlIndiceAcum        NUMBER(7, 4);
  vNuFormulaEspecifica INTEGER;
  vNumComissoes        integer;

BEGIN

  vNuSufixo := 0;

  vvlIndice := 0;

  vvlIndiceAcum := 0;

  vNumComissoes := 0;

  FOR vMembro IN (SELECT (SELECT TMF.NUFORMULAESPECIFICA
                            FROM EPagTipoMembroCCGFormula TMF
                           WHERE TMF.CDHISTEVENTOPAGAGRUP =
                                 pCdHistEventoPagAgrup
                             AND TMF.CDTIPOMEMBROCCG = hc.Cdtipomembroccg) as NuFormulaEspecificaTipo,

                         CASE
                           WHEN HC.DtInicioVigencia < pFolha.DtInicioMes THEN
                            pFolha.DtInicioMes
                           ELSE
                            HC.DtInicioVigencia
                         END AS DtInicio,
                         CASE
                           WHEN (HC.DtFimVigencia > pFolha.DtFimMes OR
                                HC.DtFimVigencia IS NULL) THEN
                            pFolha.DtFimMes
                           ELSE
                            HC.DtFimVigencia
                         END AS DtFim,
                         HC.VlRecebimento,
                         C.DtInclusao,
                         ct.cdmodalidadecomissaoconselho as CdModalidade
                    FROM ECadMembroCCG C
                   INNER JOIN ECadComissaoConselhoGrupo CCO
                      ON C.CdComissaoConselhoGrupo = CCO.CdComissaoConselhoGrupo
                   INNER JOIN ECadHistMembroCCG hc
                      ON C.CdMembroCCG = HC.CdMembroCCG
                   inner join ecadtipocomissaoconselhogrupo ct on ct.cdtipocomconselhogrupo = cco.cdtipocomconselhogrupo
                   WHERE C.CdVinculo = pCdVinculo
                     AND HC.FlRemunerado = 'S'
                     AND CCO.CdTipoComConselhoGrupo = pCdTipoComConselhoGrupo
                     AND HC.DtInicioVigencia <= pFolha.dtFimMes
                     AND (HC.DtFimVigencia >= pFolha.dtInicioMes OR
                         hc.DtFimVigencia IS NULL)
                     AND HC.FlAnulado = 'N'
                   ORDER BY hc.CdHistMembroCCG                      
                     ) LOOP

    vNuSufixo := vNuSufixo + 1;

    IF NOT (pFolha.FlIgnoraInclusaoFutura = 'S' AND
        vMembro.DtInclusao > PKGPAG_VAR.vdtCalculo) THEN

      IF NOT (NVL(PKGPAG_VAR.vgVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax) BETWEEN
          pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

        vvlIndice := CASE
                       WHEN (vMembro.DtFim - vMembro.DtInicio + 1) > 30 THEN
                        30
                       WHEN to_number(TO_CHAR(vMembro.DtInicio, 'MM')) = 2 THEN
                        CASE
                          WHEN TO_CHAR(vMembro.DtFim, 'DD') = '28' THEN
                           (vMembro.DtFim - vMembro.DtInicio + 3)
                          WHEN TO_CHAR(vMembro.DtFim, 'DD') = '29' THEN
                           (vMembro.DtFim - vMembro.DtInicio + 2)
                          ELSE
                           (vMembro.DtFim - vMembro.DtInicio + 1)
                        END
                       ELSE
                        (vMembro.DtFim - vMembro.DtInicio + 1)
                     END / CASE
                       WHEN to_number(to_char(vMembro.DtFim, 'DD')) > 30 THEN
                        30
                       WHEN to_number(TO_CHAR(vMembro.DtInicio, 'MM')) = 2 THEN
                        30
                       ELSE
                        30 --to_char(pFolha.DtFimMes, 'DD')
                     END;

      ELSE

        vVlIndice := 1;

      END IF;

      vvlIndiceAcum := vvlIndiceAcum + vvlIndice;

      IF vNuSufixo > 1 AND vvlIndiceAcum > 1 THEN

        vvlIndice := vvlIndice - (vvlIndiceAcum - 1);

      END IF;

      IF vMembro.NuFormulaEspecificaTipo IS NULL THEN

        vNuFormulaEspecifica := pNuFormulaEspecifica;

      ELSE

        vNuFormulaEspecifica := vMembro.NuFormulaEspecificaTipo;

      END IF;

      PKGPAG_VAR.vDtInicioComissao := vMembro.DtInicio; -- Data inicial do exercicio da participacao em comissao

      PKGPAG_VAR.vgDtInicioComissao(vNuSufixo) := vMembro.DtInicio; -- Data inicial do exercicio da participacao em comissao

      PKGPAG_VAR.vDtFimComissao := vMembro.DtFim; -- Data final do exercicio da participacao em comissao

      PKGPAG_VAR.vgDtFimComissao(vNuSufixo) := vMembro.DtFim; -- Data final do exercicio da participacao em comissao

      -- Para comissoes diferentes da permanente sufixos diferentes
      if vNuSufixo = 1 then
         begin
           select count(c.cdmembroccg)
             into vNumComissoes
             FROM ECadMembroCCG C
                   INNER JOIN ECadComissaoConselhoGrupo CCO
                      ON C.CdComissaoConselhoGrupo = CCO.CdComissaoConselhoGrupo
                   INNER JOIN ECadHistMembroCCG hc
                      ON C.CdMembroCCG = HC.CdMembroCCG
                   WHERE C.CdVinculo = pCdVinculo
                     AND HC.FlRemunerado = 'S'
                     AND HC.DtInicioVigencia <= pFolha.dtFimMes
                     AND (HC.DtFimVigencia >= pFolha.dtInicioMes OR
                         hc.DtFimVigencia IS NULL)
                     AND HC.FlAnulado = 'N';
          exception
            when others
              then vNuSufixo := 1;
         end;

         if vNumComissoes > 1 then
            begin
              select count(*)
                into vNuSufixo
                from epaghistoricorubricarelvinc rv
               where rv.cdvinculo = pCdVinculo
                 and rv.cdfolhapagamento = pFolha.CdFolhaPagamento
                 and rv.cdrubricaagrupamento = pRubrica.CdRubricaAgrupamento;

             if vNuSufixo > 0 then
                vNuSufixo := vNuSufixo + 1;
             end if;

             exception
               when others
                 then vNuSufixo := 1;
             end;
         end if;


      end if;

      if vNuSufixo is null or vNuSufixo = 0 then
         vNuSufixo := 1;
      end if;

      IF pCEF.COUNT > 0 THEN

        FOR i IN pCEF.FIRST .. pCEF.LAST LOOP

          IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                    pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                    pCdOrgaoExercicio         => pCEF(i).CdOrgaoExercicio,
                                                    pCdNaturezaVinculo        => pCEF(i).CdNaturezaVinculo,
                                                    pCdRelacaoTrabalho        => pCEF(i).CdRelacaoTrabalho,
                                                    pCdRegimeTrabalho         => pCEF(i).CdRegimeTrabalho,
                                                    pCdRegimePrevidenciario   => pCEF(i).CdRegimePrevidenciario,
                                                    pCdSituacaoPrevidenciaria => pCEF(i).CdSituacaoPrevidenciaria,
                                                    pCdUnidadeOrganizacional  => pCEF(i).CdUnidadeOrganizacional,
                                                    pCdEstruturaCarreira      => pCEF(i).CdEstruturaCarreira,
                                                    pFlTipoProvimento         => pCEF(i).FlEfetivacao) THEN

            PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2,
                                                 pFolha               => pFolha,
                                                 pCdVinculo           => pCdVinculo,
                                                 pRubrica             => pRubrica,
                                                 pFormExpr            => pFormExpr,
                                                 pFlPrincipal         => PKGPAG_TIPO.cnS,
                                                 pCEF                 => pCEF,
                                                 pCCO                 => pCCO,
                                                 pCCOSubst            => pCCOSubst,
                                                 pFUC                 => pFUC,
                                                 pBOL                 => pBOL,
                                                 pAPO                 => pAPO,
                                                 pVlIndice            => vvlIndice *
                                                                         vMembro.VlRecebimento,
                                                 pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                                 pNuFormulaEspecifica => vNuFormulaEspecifica,
                                                 pDtDesligamento      => NULL,
                                                 pNuSufixo            => vNuSufixo);

            EXIT; -- Garante que ira gerar o registro de pagamento apenas uma vez para a comissao
          END IF;
        END LOOP;

      ELSE

        --Nenhuma funcao de chefia permite a geracao da rubrica
        --Todos os cargos em comissao permitem a geracao da rubrica
        IF pCCO.COUNT > 0 THEN

          FOR i IN pCCO.FIRST .. pCCO.LAST LOOP

            IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
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
                                                      pFlTipoProvimento         => pCCO(i).FlTipoProvimento,
                                                      pCdOpcaoRemuneracao       => pCCO(i).CdOpcaoRemuneracao) THEN

              PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2,
                                                   pFolha               => pFolha,
                                                   pCdVinculo           => pCdVinculo,
                                                   pRubrica             => pRubrica,
                                                   pFormExpr            => pFormExpr,
                                                   pFlPrincipal         => PKGPAG_TIPO.cnS,
                                                   pCEF                 => pCEF,
                                                   pCCO                 => pCCO,
                                                   pCCOSubst            => pCCOSubst,
                                                   pFUC                 => pFUC,
                                                   pBOL                 => pBOL,
                                                   pAPO                 => pAPO,
                                                   pVlIndice            => vvlIndice *
                                                                           vMembro.VlRecebimento,
                                                   pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                                   pNuFormulaEspecifica => vNuFormulaEspecifica,
                                                   pDtDesligamento      => NULL,
                                                   pNuSufixo            => vNuSufixo);

              EXIT; -- Garante que ira gerar o registro de pagamento apenas uma vez para a comissao
            END IF;
          END LOOP;
        END IF;

--Deve estar aposentado
--Permitido para aposentado originado de cargo em comissao
        IF pAPO.COUNT > 0 THEN

          FOR i IN pAPO.FIRST .. pAPO.LAST LOOP

          IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                            pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                            pCdOrgaoExercicio         => pAPO(i).CdOrgaoExercicio,
                                            pCdSituacaoPrevidenciaria => pAPO(i).CdSituacaoPrevidenciaria,
                                            pCdUnidadeOrganizacional  => pAPO(i).CdUnidadeOrganizacional,
                                            pCdEstruturaCarreira      => pAPO(i).CdEstruturaCarreira,
                                            pFlAPOOrigemCCO           => pAPO(i).FlOrigemCCO,
                                            pCdTipoRelacaoVinculo     => 4) THEN

              PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2,
                                                   pFolha               => pFolha,
                                                   pCdVinculo           => pCdVinculo,
                                                   pRubrica             => pRubrica,
                                                   pFormExpr            => pFormExpr,
                                                   pFlPrincipal         => PKGPAG_TIPO.cnN,
                                                   pCEF                 => pCEF,
                                                   pCCO                 => pCCO,
                                                   pCCOSubst            => pCCOSubst,
                                                   pFUC                 => pFUC,
                                                   pBOL                 => pBOL,
                                                   pAPO                 => pAPO,
                                                   pVlIndice            => vvlIndice *
                                                                           vMembro.VlRecebimento,
                                                   pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                                   pNuFormulaEspecifica => vNuFormulaEspecifica,
                                                   pDtDesligamento      => NULL,
                                                   pNuSufixo            => vNuSufixo);

              EXIT; -- Garante que ira gerar o registro de pagamento apenas uma vez para a comissao
            END IF;
          END LOOP;
        END IF;

      END IF;

    END IF;

  END LOOP;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;

  /*WHEN TOO_MANY_ROWS THEN

  PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                          PKGPAG_VAR.vCdHistParamCalc,
                          PKGPAG_VAR.vCdPessoa,
                            'Erro ao processar a remuneracao de Comissoes/Conselhos e Grupos.'||
                            ' A pessoa e membro remunerado em mais de uma comissao, conselho ou grupo.' ,
                          PKGPAG_VAR.vgCdVinculo);*/

  WHEN OTHERS THEN

      --DBMS_OUTPUT.put_line('Deu pau na comissão ' || SQLERRM);
      null;

END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P056Devolucao13SalPensao
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P056Devolucao13SalPensao(pFolha     IN PKGPAG_TIPO.rFolha,
                                     pCdVinculo IN INTEGER,
                                     pRubrica   IN PKGPAG_TIPO.rRubrica) IS

    vVlAdiant13SalPen    NUMBER(13, 2);
    vVlDesc13SalPen      NUMBER(13, 2);
    vCdRubricaDescSalPen INTEGER;

    FUNCTION FPossuiAdiant13Sal(pCdVinculo INTEGER,
                                pNuAnoReferencia INTEGER,
                                pNuMesReferencia INTEGER)
      RETURN BOOLEAN IS

      vVlAdiant13Sal       NUMBER(13, 2);

    BEGIN

      select capa.vlproventos
      into vVlAdiant13Sal
      from epagcapahistrubricavinculo capa
     inner join epagfolhapagamento fp
        on fp.cdfolhapagamento = capa.cdfolhapagamento
       and fp.flcalculodefinitivo = 'S'
     inner join epagtipofolhapagamento tf
        on tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
       and tf.cdtipofolha = 5
     where fp.nuanoreferencia = pNuAnoReferencia
       and fp.numesreferencia < pNuMesReferencia
       and capa.cdvinculo = pCdVinculo;

       IF vVlAdiant13Sal > 0
         THEN
           RETURN TRUE;
       ELSE
         RETURN FALSE;
       END IF;

    EXCEPTION
      WHEN OTHERS THEN
         RETURN FALSE;
    END;

  BEGIN

    IF /*(((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND
       pFolha.DtFimMes) OR
       (PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes)) AND
       NOT PKGPAG_VAR.bPossuiObito) OR
       (PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes
       AND pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal
       AND FPossuiAdiant13Sal(pCdVinculo, pFolha.NuAnoReferencia, pFolha.NuMesReferencia)) OR*/
       pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 OR
       (FPagarRescisao13oServDesligado(PKGPAG_VAR.vgVinculo.DtDesligamento, pFolha.DtInicioMes, pFolha.DtFimMes,PKGPAG_VAR.vMotAfast.DtInclusao, PKGPAG_VAR.vDtCalculoAnt, PKGPAG_VAR.vDtCalculo) 
        AND NOT PKGPAG_VAR.bPossuiObito)  THEN

      FOR vSentenca IN (SELECT SJ.CdSentencaJudicial, SJ.NuSequencial
                          FROM ePenSentencaJudicial SJ
                         INNER JOIN EPenHistSentencaJudicial HSJ
                            ON SJ.CdSentencaJudicial =
                               HSJ.CdSentencaJudicial
                         WHERE SJ.CdVinculo = pCdVinculo
                           AND HSJ.DtInicioVigencia <= pFolha.DtInicioMes
                           AND (HSJ.DtFimVigencia >= pFolha.DtFimMes OR
                               HSJ.DtFimVigencia IS NULL)
                         ORDER BY SJ.NuSequencial) LOOP

        BEGIN

          IF pRubrica.CdRubricaAgrupamento =
             PKGPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao THEN

             vCdRubricaDescSalPen :=
             PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,4,
                                          PKGPAG_VAR.vgRubrica(pRubrica.CdRubricaAgrupamento).NuRubrica);

            DELETE FROM EPagHistoricoRubricaVinculo HRV
             WHERE HRV.CdVinculo = pCdVinculo
               AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento =
                   PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                4,
                                                PKGPAG_VAR.vgRubrica(pRubrica.CdRubricaAgrupamento).NuRubrica)
               AND HRV.Nusufixorubrica = vSentenca.NuSequencial;

            begin

            vVlAdiant13SalPen := 0;

            SELECT SUM(HRV.VlPagamento)
              INTO vVlAdiant13SalPen
              FROM EPagHistoricoRubricaVinculo HRV
             INNER JOIN EPagFolhaPagamento F
                ON F.CdFolhaPagamento = HRV.CdFolhaPagamento
               AND F.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
               AND F.NuAnoReferencia = pFolha.NuAnoReferencia
             WHERE HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento = pRubrica.CdRubricaAgrupamento
               AND HRV.NuSufixoRubrica = vSentenca.NuSequencial;

             exception
               when no_data_found
                 then vVlAdiant13SalPen := 0;
               when others
                 then vVlAdiant13SalPen := 0;

             end;

             begin

             vVlDesc13SalPen := 0;

              SELECT SUM(HRV.VlPagamento)
                INTO vVlDesc13SalPen
                FROM EPagHistoricoRubricaVinculo HRV
               INNER JOIN EPagFolhaPagamento F
                  ON F.CdFolhaPagamento = HRV.CdFolhaPagamento
                 AND F.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
                 AND F.NuAnoReferencia = pFolha.NuAnoReferencia
               AND (pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes AND F.Numesreferencia <> pFolha.NuMesReferencia)
               WHERE HRV.CdVinculo = pCdVinculo
                 AND HRV.CdRubricaAgrupamento = vCdRubricaDescSalPen
                 AND HRV.NuSufixoRubrica = vSentenca.NuSequencial;

             exception
                when no_data_found
                 then vVlDesc13SalPen := 0;
               when others
                 then vVlDesc13SalPen := 0;

             end;

            IF NVL(vVlAdiant13SalPen, 0) - NVL(vVlDesc13SalPen, 0) > 0 THEN

              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                          4,
                                                                                                          PKGPAG_VAR.vgRubrica(pRubrica.CdRubricaAgrupamento).NuRubrica),
                                                    pNuSufixoRubrica      => vSentenca.NuSequencial,
                                                    pVlPagamento          => NVL(vVlAdiant13SalPen, 0) - NVL(vVlDesc13SalPen, 0),
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 8);

            END IF;

          END IF;

        EXCEPTION

          WHEN OTHERS THEN

            NULL;

        END;

      END LOOP;

    END IF;

  END;

  PROCEDURE P059DevolucaoAdiantFerias(pCdVinculo IN INTEGER,
                                      pFolha     IN PKGPAG_TIPO.rFolha,
                                      pRubrica   IN PKGPAG_TIPO.rRubrica) IS

    vVlAdiantFerias  NUMBER(13, 2);
    vCdRubricaAdiant INTEGER;

  BEGIN

    /*IF PKGPAG_POS.FPossuiProventos(pFolha     => pFolha,
    pCdVinculo => pCdVinculo) THEN  */

    vCdRubricaAdiant := PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,
                                                           58);
    SELECT VlPagamento
      INTO vVlAdiantFerias
      FROM EPagHistoricoRubricaVinculo HRV
     WHERE HRV.CdVinculo = pCdVinculo
       AND HRV.CdRubricaAgrupamento = vCdRubricaAdiant
       AND HRV.CdFolhaPagamento = PKGPAG_VAR.vgCdFolhaFerias;

    IF vVlAdiantFerias > 0 AND
       PKGPAG_VAR.vgRelVincPrincipal.CdHist IS NOT NULL THEN

      PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdRelacaoVinculo     => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                            pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                            pVlIntegral           => vVlAdiantFerias,
                                            pVlProporcional       => vVlAdiantFerias,
                                            pNuSufixoRubrica      => 1,
                                            pNuParcelas           => 1,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

    END IF;

    /*END IF;   */

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      NULL;

  END;

  /*----------------------------------------------------------------------------------------------/
  -- Procedure: P062AuxilioCreche
  --
  --  Objetivo:
  --
  --
  /*----------------------------------------------------------------------------------------------*/

  PROCEDURE P062AuxilioCreche(pFolha     IN PKGPAG_TIPO.rFolha,
                              pCdVinculo IN INTEGER,
                              pRubrica   IN PKGPAG_TIPO.rRubrica,
                              pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                              pCEF       IN PKGPAG_TIPO.tCEF,
                              pCCO       IN PKGPAG_TIPO.tCCO,
                              pCCOSubst  IN PKGPAG_TIPO.tCCO,
                              pFUC       IN PKGPAG_TIPO.tFUC,
                              pBOL       IN PKGPAG_TIPO.tBOL,
                              pAPO       IN PKGPAG_TIPO.tCEF,
                              pRubricaAlt IN PKGPAG_TIPO.rRubrica DEFAULT NULL) IS

    vVlAuxilioCreche NUMBER(13, 2);
    vVlBaseCalculo   NUMBER(13, 2);
    vNuSufixo        INTEGER;
    vQtReferencia    INTEGER;
    vVlReferencia    NUMBER(13, 2);

  BEGIN

    vVlAuxilioCreche := null;
    vNuSufixo        := 0;

    FOR rec IN (SELECT TRUNC(MONTHS_BETWEEN(PKGPAG_VAR.vgFolha.dtInicioMes,
                                            dtNascimento)) AS IdadeMeses,
                       VlAuxilioCreche
                  FROM EBPCAUXILIOCRECHE C, ECADDEPENDENTE D
                 WHERE CdVinculo = pCdVinculo
                   AND C.CdDependente = D.CdDependente
                   AND DtInicioVigencia <= PKGPAG_VAR.vgFolha.dtFimMes
                   AND (DtFimVigencia >= PKGPAG_VAR.vgFolha.dtInicioMes OR
                       dtfimvigencia IS NULL)
                   AND FlAnulado = 'N') LOOP

      IF NOT PKGPAG_VAR.vgAuxCreche.EXISTS(PKGPAG_VAR.vgFolha.cdOrgao) THEN
        -- Nao existe, pagar select por valor select nao nulo

        vVlAuxilioCreche := rec.vlAuxilioCreche;

        -- Verificar Pagamento, primeiramente idade
      ELSE

        IF rec.IdadeMeses <= PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).NuIdadeMaxDependente OR PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).NuIdadeMaxDependente IS NULL THEN
          -- Pagar

          IF rec.vlAuxilioCreche IS NOT NULL THEN
            -- Por Valor
            -- Pagar
            vVlAuxilioCreche := rec.vlAuxilioCreche;

            IF PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).CdValorRefLimite IS NOT NULL THEN

              vQtReferencia := PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).QtUnidValorRefLimite;

              vVlReferencia := PKGPAG_VAR.vgValorReferencia(PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).CdValorRefLimite).VlReferencia;

              vVlAuxilioCreche := LEAST(vVlAuxilioCreche,
                                        vVlReferencia *
                                        NVL(vQtReferencia, 1));

            END IF;

          ELSE
            -- Calcular a Base de Calculo

            vVlBaseCalculo := 150;

            IF PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa.FIRST IS NULL THEN
              -- Nao tem faixa, pagar pela propria base de calculo
              -- Pagar
              vVlAuxilioCreche := vVlBaseCalculo;
            ELSE
              -- Possui faixas, encontrar
              FOR faixa in PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa.FIRST.. PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa.LAST LOOP

                IF vVlBaseCalculo between PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa(faixa).vlInicialBaseCalculo and PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa(faixa).vlFinalBaseCalculo THEN

                  IF PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa(faixa).vlEspecifico IS NOT NULL THEN
                    -- Pagar pelo valor especifico
                    -- Pagar
                    vVlAuxilioCreche := PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa(faixa).vlEspecifico;

                  ELSE
                    -- Buscar valor de referencia e pagar

                    vVlAuxilioCreche := PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa(faixa).qtUnidValorReferencia * PKGPAG_VAR.vgValorReferencia(PKGPAG_VAR.vgAuxCreche(PKGPAG_VAR.vgFolha.cdOrgao).faixa(faixa).cdValorReferencia).VlReferencia;

                  END IF;

                  EXIT;

                END IF;

              END LOOP;

            END IF;

          END IF;

        END IF;

      END IF;

      IF vVlAuxilioCreche IS NOT NULL THEN

        vNuSufixo := vNuSufixo + 1;

        --
        -- Implantacao CIDASC. Utilizar rubrica alternativa 2 quando a idade em meses for maior
        -- que 71, ja que a partir desta idade a rubrica e tributada
        --

        PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 1,
                                             pFolha               => pFolha,
                                             pCdVinculo           => pCdVinculo,
                                             pRubrica             => CASE WHEN rec.idademeses < 72
                                                                          THEN pRubrica
                                                                          ELSE pRubricaAlt
                                                                     END,
                                             pFormExpr            => pFormExpr,
                                             pFlPrincipal         => PKGPAG_TIPO.cnS,
                                             pCEF                 => pCEF,
                                             pCCO                 => pCCO,
                                             pCCOSubst            => pCCOSubst,
                                             pFUC                 => pFUC,
                                             pBOL                 => pBOL,
                                             pAPO                 => pAPO,
                                             pVlIndice            => NULL,
                                             pNuSufixo            => vNuSufixo,
                                             pValorIntegral       => vVlAuxilioCreche,
                                             pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                             pCdTipoOrigemRubrica => 6);

      END IF;

    END LOOP;

  END;

FUNCTION FRetornaValorDescFalta(pNuAnoMesReferencia IN NUMBER,
                                pCdVinculo          IN INTEGER,
                                pCdRubrica          IN INTEGER)
  RETURN NUMBER IS

  vVlevento NUMBER(13,4);
  vVlindice NUMBER(13,4);

BEGIN

  SELECT vlevento, vlindice
    INTO vVlevento, vVlindice
    FROM (select ev.vlevento, ev.vlindice
            from EPagEventoVinculo ev
           where ev.cdvinculo = pCdVinculo
             and ev.cdrubricaagrupamento = pCdRubrica
             and ev.nuanomesreferencia = pNuAnoMesReferencia
             and ev.cdtipoeventovinculo = 4)
   WHERE ROWNUM < 2;

  RETURN vVlevento / vVlindice;

EXCEPTION

  WHEN OTHERS THEN

    RETURN 0;

END FRetornaValorDescFalta;

  PROCEDURE P071FaltaAbonada(pCdVinculo IN INTEGER,
                             pFolha     IN PKGPAG_TIPO.rFolha,
                             pRubrica   IN PKGPAG_TIPO.rRubrica,
                             pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                             pCEF       IN PKGPAG_TIPO.tCEF,
                             pCCO       IN PKGPAG_TIPO.tCCO,
                             pCCOSubst  IN PKGPAG_TIPO.tCCO,
                             pFUC       IN PKGPAG_TIPO.tFUC,
                             pBOL       IN PKGPAG_TIPO.tBOL,
                             pAPO       IN PKGPAG_TIPO.tCEF) IS

  vNuMesFalta INTEGER;
  vNuAnoMesFalta INTEGER;

  vNuFaltas pkgpag_tipo.tFalta;

  vVlFalta NUMBER(7,4);
  --vNuFalta NUMBER(7,4);

  BEGIN

    -- Inicializa a variavel
    vNuFaltas := pkgpag_tipo.tFalta();
    vNuFaltas.Extend(12);

    IF PKGPAG_VAR.vgIndiceAbonoRetro > 0 THEN

      for i in pkgpag_var.vgFaltas.first .. pkgpag_var.vgFaltas.last loop

        if pkgpag_var.vgFaltas(i).FlAbonado = 'S' then

          vNuMesFalta := to_char(pkgpag_var.vgFaltas(i).DtFrequencia, 'mm');
          vNuFaltas(vnuMesFalta) := NVL(vNufaltas(vNumesFalta), 0) +
                                    (pkgpag_var.vgfaltas(i).numfracaofalta / pkgpag_var.vgFaltas(i)
                                     .denfracaofalta);
        end if;

      end loop;

      for i in 1 .. 12 loop

        if vNuFaltas(i) is not null then

          if i > pFolha.NuMesReferencia then
            vNuAnoMesFalta := to_char(pFolha.NuAnoReferencia - 1 * 100 + i);
          else
            vNuAnoMesFalta := to_char(pFolha.NuAnoReferencia * 100 + i);
          end if;

          --Retorna o valor unitario descontado
          vVLFalta := FRetornaValorDescFalta(vNuAnoMesFalta,
                                             pCdVinculo,
                                             case
                                               when pFolha.NuMesReferencia - 1 = i or
                                                    (pFolha.NuMesReferencia =1 and i = 12) then
                                                PKGPAG_VAR.vgCdRubEvento82
                                               else
                                                PKGPAG_VAR.vgCdRubEvento81
                                             end);

          if vVlFalta > 0 then

                PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,       -- Valor
                                                       pCdVinculo               => pCdVinculo,
                                                       pCdRelacaoVinculo        => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                       pCdHistRelacaoVinculo    => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                       pCdExpressaoFormCalc     => NULL,
                                                       pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                       pVlIntegral              => vVlFalta * vNuFaltas(i), --Valor multiplicado do indice abonado
                                                       pVlProporcional          => vVlFalta * vNuFaltas(i),
                                                       pVlReal                  => vVlFalta * vNuFaltas(i),
                                                       pNuSufixoRubrica         => 1,
                                                       pNuParcelas              => 1,
                                                       pVlIndice                => vNuFaltas(i),
                                                       pCdTipoOrigemRubrica     => 7);

          else
      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- Formula de calculo
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => pCCO,
                                           pCCOSubst            => pCCOSubst,
                                           pFUC                 => pFUC,
                                           pBOL                 => pBOL,
                                           pAPO                 => pAPO,
                                                 pVlIndice            => vNuFaltas(i), -- PKGPAG_VAR.vgIndiceAbonoRetro,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 7);
          end if;
        end if;

      end loop;

    END IF;

  END;

  /*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Gerar rubrica de Suspensao revertida em Multa
--
/*---------------------------------------------------------------------------------------------*/

  PROCEDURE P080SuspensaoMulta (pFolha    IN PKGPAG_TIPO.rFolha,
                                pRubrica  IN PKGPAG_TIPO.rRubrica,
                                pCEF      IN PKGPAG_TIPO.tCEF,
                                pFormExpr IN PKGPAG_TIPO.tFormulaCalculo,
                                pCdVinculo IN INTEGER) IS

   vCdExpressaoFormCalc   INTEGER;
   vNudias                INTEGER := 0;
   --vCdChave               INTEGER := 0;
   vNuDiasAnt             INTEGER := 0;
   vNuDiasTotal           INTEGER := 0;
   vUltimaDataCalculo     DATE;

  BEGIN

   --
   -- Verificar as suspensoes no periodo
   --

   vUltimaDataCalculo := pkgpag_cal.FObterUltimaDataCalculo(pDataReferencia => pFolha.DtCalculo,
                                                            pCdOrgao => pFolha.CdOrgao,
                                                            pCdTipoFolha => 1,
                                                            pCdTipoCalculo => 1,
                                                            pFlCalculoDefinitivo => 'S');

   FOR F_SUSP IN (SELECT edp.Cdhistocorrenciadisciplinar, edp.cdvinculo, edp.dtinicioocorrencia, edp.dtfimocorrencia
                   FROM ERDIHISTOCORRENCIADISCIPLINAR EDP
                  WHERE EDP.CdVinculo = pCdVinculo
                    AND EDP.FLANULADO = PKGPAG_TIPO.cnN
                    AND ((EDP.DtInicioOcorrencia <= pFolha.DtFimMes
                    AND (EDP.DTFIMOCORRENCIA >= pFolha.DtInicioMes OR EDP.DTFIMOCORRENCIA IS NULL))
                     OR (EDP.Dtinclusao > vUltimaDataCalculo AND EDP.Dtinclusao < pFolha.DtInicioMes))
                    ORDER BY EDP.DTINICIOOCORRENCIA)

   LOOP

     BEGIN

     SELECT SUM(EPEV.VLINDICE)
       INTO vNuDiasAnt
       FROM EPAGEVENTOVINCULO EPEV
      WHERE EPEV.CDVINCULO = F_SUSP.CdVinculo
        AND EPEV.NuAnoMesReferencia < (pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia)
        AND EPEV.Cdtipoeventovinculo = 3
        AND EPEV.Cdrubricaagrupamento = pRubrica.CdRubricaAgrupamento
        AND EPEV.CdChave = F_SUSP.Cdhistocorrenciadisciplinar;

     EXCEPTION
       WHEN OTHERS
         THEN
            vNuDiasAnt:= 0;
     END;

     if f_susp.dtfimocorrencia > pFolha.DtFimMes
       then
         vNuDias := pFolha.DtFimMes - f_susp.dtinicioocorrencia + 1 - NVL(vNuDiasAnt,0);
       else
        vNuDias := f_susp.Dtfimocorrencia - f_susp.dtinicioocorrencia + 1 - NVL(vNuDiasAnt,0);
     end if;

     -- Limitar a 30 dias
     IF vNuDias > 30
       THEN
        vNuDias := 30;
     END IF;

     if (vNuDiasTotal + vNuDias) > 30
       then
         vNuDias := 30 - vNuDiasTotal;
     end if;

     if vNuDias = 0
       then
         RETURN;
     end if;
     vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => 1);
                                    --pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    --pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

   -- 1) Busca a formula associada
      IF vCdExpressaoFormCalc > 0 THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- Formula de calculo
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => PKGPAG_VAR.vgCCO,
                                           pCCOSubst            => PKGPAG_VAR.vgCCOSubst,
                                           pFUC                 => PKGPAG_VAR.vgFUC,
                                           pBOL                 => PKGPAG_VAR.vgBOL,
                                           pAPO                 => PKGPAG_VAR.vgAPO,
                                           pVlIndice            => vNuDias,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 21);

      --
      -- Incluir registro de desconto na tabela EPAGEVENTOVINCULO
      -- vCdChave = CDHISTOCORRENCIADISCIPLINAR
      --
      PKGPAG_POS.PAtualizaEventoVinculo(pFolha        => pFolha,
                                        pCdVinculo    => pCdVinculo,
                                        pCdTipoEvento => 3,
                                        pCdChave      => f_susp.cdhistocorrenciadisciplinar,
                                        pCdRubrica    => pRubrica.CdRubricaAgrupamento,
                                        pVlIndice     => vNuDias);

       vNuDiasTotal := vNuDiasTotal + vNuDias;

       if vNuDiasTotal = 30
         then
           return;
       end if;

      END IF;

    END LOOP;

  END;

  PROCEDURE P083AbonoFeriasRescisao (pFolha    IN PKGPAG_TIPO.rFolha,
                                     pRubrica  IN PKGPAG_TIPO.rRubrica,
                                     pCEF      IN PKGPAG_TIPO.tCEF,
                                     pFormExpr IN PKGPAG_TIPO.tFormulaCalculo,
                                     pCdVinculo IN INTEGER,
                                     pEventoGerado OUT BOOLEAN) IS

   vCdExpressaoFormCalc   INTEGER;
   vCont                  INTEGER := 0;
   --vCdChave               INTEGER := 0;
   --vNuDiasAnt             INTEGER := 0;
   --vNuDiasTotal           INTEGER := 0;

  BEGIN

       BEGIN

       pEventoGerado := FALSE;

       SELECT count(*)
         INTO vCont
         FROM EMovPeriodoAquisitivoFerias PA
         LEFT JOIN EMovFeriasFruicaoPagamento FFP
               ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
         WHERE PA.CdVinculo = pCdVinculo
           AND PA.CDSITUACAOPERIODOAQFERIAS = 2
           AND FFP.CDFERIASFRUICAOPAGAMENTO IS NULL;

        IF vCont = 0
          THEN
            RETURN;
        END IF;

        EXCEPTION
          WHEN NO_DATA_FOUND
            THEN
             RETURN;

          WHEN OTHERS
            THEN
              RETURN ;

        END;

     pEventoGerado := TRUE;
     vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => 1);
   -- 1) Busca a f?rmula associada
      IF vCdExpressaoFormCalc > 0 THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- F?rmula de c?lculo
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => PKGPAG_VAR.vgCCO,
                                           pCCOSubst            => PKGPAG_VAR.vgCCOSubst,
                                           pFUC                 => PKGPAG_VAR.vgFUC,
                                           pBOL                 => PKGPAG_VAR.vgBOL,
                                           pAPO                 => PKGPAG_VAR.vgAPO,
                                           pVlIndice            => CASE WHEN pFolha.CdAgrupamento = 5 THEN 25
                                                                        ELSE NULL END,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 23);

         pEventoGerado := TRUE;

      END IF;

  END;

  --
  -- 7526/2015 - FOLHA - IMPLEMENTACAO DE DESCONTO RETROATIVO AUTOMATICO
  -- SOLICITAMOS QUE SEJA IMPLEMENTADO NO CALCULO ROTINA PARA DESCONTO AUTOMATICO RETROATIVO,
  -- RUBRICA 08-0574, QUANDO DA INCLUSAO DE AFASTAMENTOS QUE CONSTAM NO PARAMETRO DA REFERIDA RUBRICA.
  --

   PROCEDURE P085DevolucaoRemAtivEspecial (pFolha    IN PKGPAG_TIPO.rFolha,
                                          pRubrica  IN PKGPAG_TIPO.rRubrica,
                                          pCEF      IN PKGPAG_TIPO.tCEF,
                                          pCdVinculo IN INTEGER,
                                          pEventoGerado OUT BOOLEAN) IS

   vValorPago            NUMBER(13,2);
   vVlIndicePago         INTEGER;
   vValorDevolvidoAnt    PKGPAG_TIPO.rValorPagamento;
   vValorDevolvidoAntDia NUMBER;
   vNuDiasAfastAnulado   NUMBER;
   vDtFimAfast           DATE;
   vDtIniAfast           DATE;
   vVlIndice             NUMBER :=0;
   vVlTotalIndPeriodo    INTEGER;
   vVlSaldoNaoDescontado NUMBER(13,2);
   vVlDescontado         pkgpag_tipo.rValorPagamento ;
   vNuDiasAjuste         INTEGER;
   vNuDiasAfastRemunMesAnt pls_integer;
   vVlrub20151               pkgpag_tipo.rValorPagamento;
   vValorTotal080151    number(13,2) :=0;
   vTotalIndice080151   integer :=0;
   vAnoMesAfastIni      number;
   vAnoMesAfastFim      number;
   vIndiceMes           integer;
   vDtFimControle       date;
   vDtInicioControle    date;

   FUNCTION fretornavalorrubrica(pcdfolhapagamento    IN INTEGER,
                                pcdvinculo           IN INTEGER,
                                pcdrubrica           IN INTEGER)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vvlrubrica pkgpag_tipo.rvalorpagamento;

   BEGIN

     SELECT hrv.vlpagamento, hrv.vlpagamento, hrv.vlindicerubrica
       INTO vvlrubrica.vlreal, vvlrubrica.vlintegral, vvlrubrica.vlindice
       FROM epaghistoricorubricavinculo hrv
      WHERE hrv.cdfolhapagamento = pcdfolhapagamento
        AND hrv.cdvinculo = pcdvinculo
        AND hrv.cdrubricaagrupamento = pcdrubrica
        AND rownum < 2;

      RETURN vvlrubrica;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN NULL;

    END;

    Function fRetornaValorDiaMes(pCdVinculo in integer,
                                 pNuAnoMes  in number,
                                 pCdRubrica in integer) return number is

      vValorDia number(13, 2);

    begin

      vValorDia := 0;

      with fol AS
       (SELECT folha.cdfolhapagamento
          FROM epagfolhapagamento folha
         INNER JOIN epagtipofolhapagamento tfp
            ON tfp.cdtipofolhapagamento = folha.cdtipofolhapagamento
         WHERE folha.flcalculodefinitivo = pkgpag_tipo.cns
           AND folha.cdtipocalculo = pkgpag_tipo.cntpcalculonormal
           AND tfp.cdtipofolha = pkgpag_tipo.cntpfolhanormal
           AND folha.cdorgao = pkgpag_var.vgfolha.cdorgao
           AND folha.nuanomesreferencia = pNuAnoMes)

      SELECT SUM(hv.vlreal) / case
               when pNuAnoMes = 202004 then
                16
               else
                30
             end
        INTO vValorDia
        FROM epaghistoricorubricarelvinc hv
       INNER JOIN fol ff
          ON ff.cdfolhapagamento = hv.cdfolhapagamento
         AND hv.cdrubricaagrupamento = pCdRubrica
       WHERE hv.cdvinculo = pcdvinculo;

      return vValorDia;

    exception
      when others then
        return 0;

    end;

  BEGIN

    if prubrica.NuRubrica = 151 and pFolha.CdAgrupamento in (1,176)
      then
        vVlDescontado :=  pkgpag_geral.fretornavaloroutrasrv(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                             pcdvinculo => pCdVinculo,
                                                             pcdrubricaagrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,151));
    else
       --
       -- Saldo da Rubrica 09-1573
       --
       vVlSaldoNaoDescontado := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                                                         pcdvinculo => pCdVinculo,
                                                                           pcdrubrica => pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,1573));
    end if;

    vNuDiasAfastAnulado := 0;
    --
    -- Contar total de dias afastados no periodo de 4 meses
    -- Comparar com valores recebidos e descontados
    -- Se for o caso gerar um saldo de desconto
    -- Incluidos apos o calculo definitivo e que sejam do periodo recebido
    --

    vDtIniAfast := pFolha.DtInicioMes - 1;

    if pFolha.CdAgrupamento <> 134
      then

      IF PKGPAG_VAR.vgAfastTempRemunMesAnt.Count > 0 then

         BEGIN

         vNuDiasAjuste := 0;
         vValorTotal080151 := 0;
         vTotalIndice080151 := 0;

         FOR i IN PKGPAG_VAR.vgAfastTempRemunMesAnt.FIRST .. PKGPAG_VAR.vgAfastTempRemunMesAnt.LAST
            LOOP

            --Verifica se existe afastamento impeditivo
            IF pRubrica.lsMotAfastTempImp.exists(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).CdMotivoAfastamento)
               AND trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa) < trunc(pFolha.DtInicioMes)
               AND trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInclusao) > trunc(pFolha.DtCalculoAnt)

              THEN
                 -- Solicitacao de Sustentacao #76715
                 -- 10496/2017 - FOLHA - DESCONTO DA RUBRICA 01-0573/01-0574

                 vDtIniAfast := trunc(least(vDtIniAfast, PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa));

                 vDtFimAfast := trunc(least(pFolha.DtInicioMes - 1,NVL(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa,pFolha.DtFimMes)));

                 IF To_char(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa,'yyyymm') =
                    to_char(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa,'yyyymm') AND
                    (vDtFimAfast - PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa + 1) > 30
                    THEN

                     vVlIndice := vVlIndice + 30;

                 ELSE
                    vVlIndice := vVlIndice + vDtFimAfast - PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa + 1;

                    if vDtFimAfast = pFolha.DtInicioMes - 1 and
                       to_char(pFolha.DtInicioMes - 1,'DD') < 30 and vNuDiasAjuste = 0
                      then
                         vNuDiasAjuste := (30 - to_char(pFolha.DtInicioMes - 1,'DD'));
                         vVlIndice := vVlIndice + vNuDiasAjuste;
                    elsif vDtFimAfast >= pFolha.DtInicioMes - 1
                      and to_char(pFolha.DtInicioMes - 1,'DD') > 30
                      then
                        -- desconto o 31 dia
                       vVlIndice := vVlIndice -1;
                    end if;

                 END IF;

                 if pRubrica.NuRubrica = 151 and
                    pRubrica.CdtipoRubrica = 8 and
                    pFolha.CdAgrupamento = 176 then


                    vAnoMesAfastIni := to_number(to_char(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa,'yyyymm'));
                    vAnoMesAfastFim := least(to_number(to_char(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa,'yyyymm')),
                    to_number(to_char(pFolha.DtInicioMes-1,'yyyymm'))) ;
                    vDtInicioControle := PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa;

                    while vAnoMesAfastIni <= vAnoMesAfastFim
                      loop

                        vDtFimControle := least(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa, last_day(vDtInicioControle));

                        if PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa > pFolha.DtInicioMes-1
                          and to_char(pFolha.DtInicioMes-1, 'dd') < 30
                         then
                           vNuDiasAfastAnulado := vNuDiasAfastAnulado + (30 - to_number(to_char(pFolha.DtInicioMes - 1,'DD')));

                        elsif PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa > pFolha.DtInicioMes-1
                           and to_char(pFolha.DtInicioMes-1, 'dd') > 30
                          then
                          vIndiceMes := vDtFimControle - vDtInicioControle;

                        else
                          vIndiceMes := vDtFimControle - vDtInicioControle + 1;
                       end if;

                        if vAnoMesAfastIni = '202004' then
                           vIndiceMes := 16;

                        end if;

                        vValorTotal080151 := vValorTotal080151 +
                                             (fRetornaValorDiaMes(pCdVinculo,
                                                                 to_number(to_char(vDtInicioControle,'yyyymm')),
                                                                 pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,1,151)) *
                                              vIndiceMes);

                        vTotalIndice080151 := vTotalIndice080151 + vIndiceMes;

                        vDtInicioControle := last_day(vDtInicioControle) +1;

                        vAnoMesAfastIni := to_number(to_char(vDtInicioControle,'yyyymm'));

                    end loop;

                 end if;

                 IF pRubrica.NuRubrica = 574 AND
                    PKGPAG_VAR.vgFolha.CdAgrupamento = 1 AND
                    PKGPAG_VAR.vgAfastTempRemunMesAnt(i).flpartejornada = 'S' AND
                    nvl(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).vlpercentreducaoiresa,0) > 0 THEN

                    vVlIndice := vVlIndice * (PKGPAG_VAR.vgAfastTempRemunMesAnt(i).vlpercentreducaoiresa/100);

                 END IF;

              END IF;

              if trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInclusao) < trunc(pFolha.DtInicioMes) and
                 pRubrica.CdRubricaAgrupamento in ( pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,8,151),
                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,151)) and
                 pFolha.CdAgrupamento = 176 and
                 PKGPAG_VAR.vgAfastTempRemunMesAnt(i).CdMotivoAfastamento IN (4024,3971) and
                 pkgpag_var.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal  and
                 pkgpag_var.vgFolha.cdorgao = 443
              then
                 vVlIndice  := 0;
              end if;

           END LOOP;

           vNuDiasAfastRemunMesAnt := vVlIndice;

          exception
            when no_data_found
              then
                if vVlSaldoNaoDescontado = 0
                  then
                   pEventoGerado := FALSE;
                   RETURN;
                end if;

            when others
               then
                 if vVlSaldoNaoDescontado = 0
                   then
                    pEventoGerado := FALSE;
                    RETURN;
                end if;

         END;

      IF vVlIndice > 0 or vVlSaldoNaoDescontado > 0 then


        BEGIN

          SELECT SUM(30)
            INTO vvltotalindperiodo
            FROM epagfolhapagamento folha
           INNER JOIN epagtipofolhapagamento tfp
              ON tfp.cdtipofolhapagamento = folha.cdtipofolhapagamento
           WHERE folha.flcalculodefinitivo = pkgpag_tipo.cns
             AND folha.cdtipocalculo = pkgpag_tipo.cntpcalculonormal
             AND tfp.cdtipofolha = pkgpag_tipo.cntpfolhanormal
             AND folha.cdorgao = pfolha.cdorgao
             AND folha.nuanomesreferencia BETWEEN
                 to_number(to_char(vdtiniafast, 'yyyymm')) AND
                 to_number(to_char((pfolha.dtiniciomes - 1), 'YYYYMM'));

          WITH fol AS
           (SELECT folha.cdfolhapagamento
              FROM epagfolhapagamento folha
             INNER JOIN epagtipofolhapagamento tfp
                ON tfp.cdtipofolhapagamento = folha.cdtipofolhapagamento
             WHERE folha.flcalculodefinitivo = pkgpag_tipo.cns
               AND folha.cdtipocalculo = pkgpag_tipo.cntpcalculonormal
               AND tfp.cdtipofolha = pkgpag_tipo.cntpfolhanormal
               AND folha.cdorgao = pfolha.cdorgao
               AND folha.nuanomesreferencia BETWEEN
                   to_number(to_char(vdtiniafast, 'yyyymm')) AND
                   to_number(to_char((pfolha.dtiniciomes - 1), 'YYYYMM'))),
          rub AS
           (SELECT v.cdrubricaagrupamento, v.cdtiporubrica
              FROM vpagrubricaagrupamento v
             WHERE v.nurubrica = prubrica.nurubrica
               AND v.cdtiporubrica IN (1, 8)
               AND v.cdagrupamento = pfolha.cdagrupamento)

          SELECT SUM(case when r.cdtiporubrica = 1 then hrv.vlpagamento else 0 end) AS CRED,
                 sum(case when r.cdtiporubrica = 1 then hrv.vlindicerubrica else 0 end)
            INTO vValorPago, vVlIndicePago
            FROM Epaghistoricorubricavinculo hrv
           INNER JOIN FOL FF on FF.CdFolhaPagamento = hrv.cdfolhapagamento
           INNER JOIN RUB R on R.CdRubricaAgrupamento = hrv.cdrubricaagrupamento
           WHERE HRV.CDVINCULO = pCdVinculo;

          EXCEPTION
            WHEN NO_DATA_FOUND
              THEN

                IF vVlSaldoNaoDescontado > 0
                  THEN

                   vValorPago := 0;
                   vVlIndicePago := 0;

                ELSE

                  RETURN;

                END IF;

            WHEN OTHERS
              THEN

                IF vVlSaldoNaoDescontado > 0
                  THEN

                   vValorPago := 0;
                   vVlIndicePago := 0;

                ELSE

                  RETURN;

                END IF;

        END;

        -- Descontar do total de afastamentos os dias ja devolvidos

        IF vVlIndice > vVlIndicePago
          THEN

             vVlIndice := vVlIndicePago;

        END IF;

        IF vVlIndice > 0
          THEN

            vValorDevolvidoAnt.vlIndice := vVlIndice;

            vValorDevolvidoAnt.vlProporcional := vValorPago / vVlIndicePago * vValorDevolvidoAnt.vlIndice;

        ELSIF vVlSaldoNaoDescontado = 0
          THEN

           RETURN;

        else
          null;
        END IF;

       end if;

     end if;

     IF vValorDevolvidoAnt.vlIndice > 0 OR vVlSaldoNaoDescontado > 0
       THEN

       pEventoGerado := TRUE;

       if pRubrica.NuRubrica = 151 and
          nvl(vVlDescontado.vlProporcional,0) <> nvl(vValorDevolvidoAnt.vlProporcional,0) and
          nvl(vVlDescontado.vlIndice,0) <> nvl(vValorDevolvidoAnt.vlIndice,0)
         then

          if pkgpag_geral.fpossuilancfinanceiro(pCdVinculo,
                                                 pFolha,
                                                 pkgpag_geral.fretornarubrica(176,8,151)) then
              return;

           end if;

           if pRubrica.CdtipoRubrica = 8 and
              pFolha.CdAgrupamento = 176 then

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                    pCdHistRelacaoVinculo    => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,151),
                                                    pVlIntegral              => vValorTotal080151,
                                                    pVlProporcional          => vValorTotal080151,
                                                    pVlReal                  => vValorTotal080151,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => 1,
                                                    pVlIndice                => vTotalIndice080151,
                                                    pcdtipoorigemrubrica     => 1,
                                                    pcdtipoindice            => 4);
           else

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pCdVinculo,
                                                  pCdRelacaoVinculo        => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                  pCdHistRelacaoVinculo    => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                  pCdExpressaoFormCalc     => NULL,
                                                  pCdRubricaAgrupamento    => pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,151),
                                                  pVlIntegral              => vValorDevolvidoAnt.vlProporcional,
                                                  pVlProporcional          => vValorDevolvidoAnt.vlProporcional,
                                                  pVlReal                  => vValorDevolvidoAnt.vlProporcional,
                                                  pNuSufixoRubrica         => 1,
                                                  pNuParcelas              => 1,
                                                  pVlIndice                => vValorDevolvidoAnt.vlIndice,
                                                  pcdtipoorigemrubrica     => 1,
                                                  pcdtipoindice            => 4);

           end if;

       else

           vValorDevolvidoAnt.vlProporcional :=  nvl(vValorDevolvidoAnt.vlProporcional,0) + vVlSaldoNaoDescontado;

           PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pCdVinculo,
                                                  pCdRelacaoVinculo        => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                  pCdHistRelacaoVinculo    => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                  pCdExpressaoFormCalc     => NULL,
                                                  pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral              => vValorDevolvidoAnt.vlProporcional,
                                                  pVlProporcional          => vValorDevolvidoAnt.vlProporcional,
                                                  pVlReal                  => vValorDevolvidoAnt.vlProporcional,
                                                  pNuSufixoRubrica         => 1,
                                                  pNuParcelas              => 1,
                                                  pVlIndice                => vValorDevolvidoAnt.vlIndice,
                                                  pcdtipoorigemrubrica     => 1,
                                                  pcdtipoindice            => 4);

           pkgpag_var.vgVlDescontoIRESA := vValorDevolvidoAnt.vlProporcional;

           pkgpag_var.bGerouDescontoIRESA := TRUE;

           pkgpag_var.vgCdRubDescontoIRESA := pRubrica.CdRubricaAgrupamento;

       end if;

     END IF;

     -- Solicitação de Sustentação #79236
     -- 11804/2018 - FOLHA - DESCONTO AUTOMATICO IRESA MILITARES 08-0573
     --
     -- SIG-2332 DPE - folha setembro /2019
     IF PKGPAG_VAR.vgAfastAnulado.COUNT > 0 THEN

         vNuDiasAfastAnulado := 0;
         vNuDiasAjuste := 0; -- Mês de fevereiro
         vValorDevolvidoAnt.vlIntegral := 0;
         vValorDevolvidoAnt.vlReal := 0;
         vValorDevolvidoAnt.vlProporcional := 0;
         vValorDevolvidoAnt.vlIndice := 0;
         vVlrub20151.vlProporcional := 0;
         vVlrub20151.vlIntegral := 0;
         vVlrub20151.vlIndice := 0;

         vValorDevolvidoAnt.vlreal :=  fRetornaValorDiaMes(pCdVinculo,
                                             to_number(to_char(pFolha.DtCalculoAnt,'yyyymm')),
                                             pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,1,151)) * 30;


         FOR j IN PKGPAG_VAR.vgAfastAnulado.FIRST .. PKGPAG_VAR.vgAfastAnulado.LAST
           LOOP

           IF PKGPAG_VAR.vgAfastAnulado(j).DtAnulado > pFolha.DtCalculoAnt AND
              PKGPAG_VAR.vgAfastAnulado(j).DtInclusao < pFolha.DtCalculoAnt AND
              trunc(PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa) < trunc(pFolha.DtInicioMes) AND
              trunc(PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa) >= trunc(add_months(pFolha.DtInicioMes,-4))

             THEN

                if j = 1 --caso haja mais de um afast anulado
                  or (trunc(PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa) <> trunc(PKGPAG_VAR.vgAfastAnulado(j-1).DtInicioAfa)
                  and (trunc(PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa) <> trunc(PKGPAG_VAR.vgAfastAnulado(j-1).DtFimAfa)
                       or trunc(PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa) <= pFolha.DtInicioMes - 1))
                  then

                  vNuDiasAfastAnulado := least(PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa, (pFolha.DtInicioMes - 1)) -
                                       PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa + 1;

                if PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa > pFolha.DtInicioMes - 1 and
                   to_number(to_char(pFolha.DtInicioMes - 1,'DD')) < 30 and vNuDiasAjuste = 0
                   then
                     vNuDiasAjuste := (30 - to_number(to_char(pFolha.DtInicioMes - 1,'DD')));
                     vNuDiasAfastAnulado := vNuDiasAfastAnulado + vNuDiasAjuste;

                elsif PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa > pFolha.DtInicioMes - 1 and
                   to_number(to_char(pFolha.DtInicioMes - 1,'DD')) > 30
                   then
                     vNuDiasAfastAnulado := vNuDiasAfastAnulado -1;
                end if;

                if vValorDevolvidoAnt.VlReal > 0 then
                   vValorDevolvidoAnt.vlProporcional := vValorDevolvidoAnt.vlProporcional + (vValorDevolvidoAnt.VlReal/30 * vNuDiasAfastAnulado);
                   vValorDevolvidoAnt.vlIndice := vValorDevolvidoAnt.vlIndice + vNuDiasAfastAnulado;
                end if;

             end if;

           END IF;

         END LOOP;

         IF vValorDevolvidoAnt.vlIndice > 0
            AND NOT  pkgpag_geral.fpossuilancfinanceiro(pCdVinculo,pfolha,pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,2,pRubrica.NuRubrica))
            THEN

              vVlrub20151 := PKGPAG_GERAL.fretornavalorrubricarv(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                                pCdVinculo        => pCdVinculo,
                                                                pCdRubricaAgrupamento        => pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,2,151),
                                                                pcdrelacaovinculo => 1);

              IF vVlrub20151.vlProporcional > 0
                THEN

                 UPDATE epaghistoricorubricarelvinc hr
                    SET hr.vlintegral     = vValorDevolvidoAnt.vlProporcional,
                        hr.vlreal         = vValorDevolvidoAnt.vlProporcional,
                        hr.vlproporcional = vValorDevolvidoAnt.vlProporcional,
                        hr.vlindicerubrica = vValorDevolvidoAnt.vlIndice
                  WHERE hr.cdfolhapagamento = pFolha.cdfolhapagamento
                    AND hr.cdvinculo = pcdvinculo
                    AND hr.cdrubricaagrupamento =PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                      2,
                                                                                      151);

                ELSE
                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdRelacaoVinculo     => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                    pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,2,pRubrica.NuRubrica),
                                                    pVlIntegral           => vValorDevolvidoAnt.vlProporcional,
                                                    pVlProporcional       => vValorDevolvidoAnt.vlProporcional,
                                                    pVlReal               => vValorDevolvidoAnt.vlProporcional,
                                                    pNuSufixoRubrica      => 1,
                                                    pNuParcelas           => 1,
                                                    pVlIndice             => vValorDevolvidoAnt.vlIndice,
                                                    pcdtipoorigemrubrica  => 1,
                                                    pcdtipoindice         => 4);
           END IF;
         END IF;

     END IF;

   else
     --
     -- Solicitação de Sustentação #79502 - 12015/2018 - DESFAZER O CHAMADAO 11804
     --
     BEGIN

     -- SIG-3346
     -- CHAMADO 14498/2020 - Folha - nao esta devolvendo IRESA automaticamente
     IF PKGPAG_VAR.vgAfastAnulado.COUNT > 0 and PKGPAG_VAR.vgAfastTempRemunMesAnt.Count = 0 THEN

         vNuDiasAfastAnulado := 0;
         vNuDiasAjuste := 0; -- Mês de fevereiro
         vValorDevolvidoAnt.vlIntegral := 0;
         vValorDevolvidoAnt.vlReal := 0;
         vValorDevolvidoAnt.vlProporcional := 0;
         vValorDevolvidoAnt.vlIndice := 0;
         vVlrub20151.vlProporcional := 0;
         vVlrub20151.vlIntegral := 0;
         vVlrub20151.vlIntegral := 0;
         vVlrub20151.vlIndice := 0;

         BEGIN

           WITH fol AS
            (SELECT folha.cdfolhapagamento
               FROM epagfolhapagamento folha
              WHERE folha.cdfolhapagamento =
                    pfolha.cdfolhapagamentonormalant),
           rub AS
            (SELECT v.cdrubricaagrupamento
               FROM vpagrubricaagrupamento v
              WHERE v.nurubrica = prubrica.nurubrica
                AND v.cdtiporubrica = 1
                AND v.cdagrupamento = pfolha.cdagrupamento)
           SELECT SUM(hv.vlreal)
             INTO vvalordevolvidoant.vlreal
             FROM epaghistoricorubricarelvinc hv
            INNER JOIN fol ff
               ON ff.cdfolhapagamento = hv.cdfolhapagamento
            INNER JOIN rub r
               ON r.cdrubricaagrupamento = hv.cdrubricaagrupamento
            WHERE hv.cdvinculo = pcdvinculo;

           EXCEPTION
             when no_data_found
                THEN
                  vValorDevolvidoAnt.VlReal := 0;

             WHEN OTHERS
                THEN
                  vValorDevolvidoAnt.VlReal := 0;

          end;

         begin

         FOR j IN PKGPAG_VAR.vgAfastAnulado.FIRST .. PKGPAG_VAR.vgAfastAnulado.LAST
           LOOP

           IF PKGPAG_VAR.vgAfastAnulado(j).DtAnulado > pFolha.DtCalculoAnt AND
              PKGPAG_VAR.vgAfastAnulado(j).DtInclusao < pFolha.DtCalculoAnt AND
              PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa <= pFolha.DtCalculoAnt  AND
              trunc(PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa) >=
              trunc(add_months(pFolha.DtInicioMes,-4))

             THEN

                vNuDiasAfastAnulado := least(PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa, (pFolha.DtInicioMes - 1)) -
                                       PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa + 1;

                if PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa > pFolha.DtInicioMes - 1 and
                   to_number(to_char(pFolha.DtInicioMes - 1,'DD')) < 30 and vNuDiasAjuste = 0
                   then
                     vNuDiasAjuste := (30 - to_number(to_char(pFolha.DtInicioMes - 1,'DD')));
                     vNuDiasAfastAnulado := vNuDiasAfastAnulado + vNuDiasAjuste;
                end if;

                if vValorDevolvidoAnt.VlReal > 0 then
                   vValorDevolvidoAnt.vlProporcional := vValorDevolvidoAnt.vlProporcional + ((vValorDevolvidoAnt.VlReal / 30) * vNuDiasAfastAnulado);
                   vValorDevolvidoAnt.vlIndice := vValorDevolvidoAnt.vlIndice + vNuDiasAfastAnulado;
                end if;

           END IF;

         END LOOP;

         IF vValorDevolvidoAnt.vlIndice > 0
            AND NOT  pkgpag_geral.fpossuilancfinanceiro(pCdVinculo,pfolha,pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,2,pRubrica.NuRubrica))
            THEN

              vVlrub20151 := PKGPAG_GERAL.fretornavalorrubricarv(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                                        pCdVinculo => pCdVinculo,
                                                             pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,2,pRubrica.NuRubrica),
                                                                 pcdrelacaovinculo => 1);

              IF vVlrub20151.vlProporcional > 0
                THEN

                 UPDATE epaghistoricorubricarelvinc hr
                    SET hr.vlintegral     = vValorDevolvidoAnt.vlProporcional,
                        hr.vlreal         = vValorDevolvidoAnt.vlProporcional,
                        hr.vlproporcional = vValorDevolvidoAnt.vlProporcional,
                        hr.vlindicerubrica = vValorDevolvidoAnt.vlIndice
                  WHERE hr.cdfolhapagamento = pFolha.cdfolhapagamento
                    AND hr.cdvinculo = pcdvinculo
                    AND hr.cdrubricaagrupamento =PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,2,pRubrica.NuRubrica);

                ELSE
                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pCdVinculo,
                                                        pCdRelacaoVinculo     => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                        pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,2,pRubrica.NuRubrica),
                                                        pVlIntegral           => vValorDevolvidoAnt.vlProporcional,
                                                        pVlProporcional       => vValorDevolvidoAnt.vlProporcional,
                                                        pVlReal               => vValorDevolvidoAnt.vlProporcional,
                                                        pNuSufixoRubrica      => 1,
                                                        pNuParcelas           => 1,
                                                        pVlIndice             => vValorDevolvidoAnt.vlIndice,
                                                        pcdtipoorigemrubrica  => 1,
                                                        pcdtipoindice         => 4);
             END IF;

         END IF;

         EXCEPTION
             when no_data_found
                THEN
                  vValorDevolvidoAnt.VlReal := 0;
                  vValorDevolvidoAnt.vlProporcional := 0;
                  vValorDevolvidoAnt.vlIntegral := 0;

             WHEN OTHERS
                THEN
                  vValorDevolvidoAnt.VlReal := 0;
                  vValorDevolvidoAnt.vlProporcional := 0;
                  vValorDevolvidoAnt.vlIntegral := 0;

          end;

     END IF;

     FOR i IN PKGPAG_VAR.vgAfastTempRemunMesAnt.FIRST .. PKGPAG_VAR.vgAfastTempRemunMesAnt.LAST
          LOOP

          --Verifica se existe afastamento impeditivo
          IF pRubrica.lsMotAfastTempImp.exists(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).CdMotivoAfastamento)
             AND trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa) < trunc(pFolha.DtInicioMes)
             AND trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInclusao) > trunc(pFolha.DtCalculoAnt)
             and trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa) >= trunc(add_months(pFolha.DtInicioMes,-4))

            THEN
               -- Solicitacao de Sustentacao #76715
               -- 10496/2017 - FOLHA - DESCONTO DA RUBRICA 01-0573/01-0574

               vDtIniAfast := trunc(least(vDtIniAfast, PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa));

               vDtFimAfast := trunc(least(pFolha.DtInicioMes - 1,nvl(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa, pFolha.DtFimMes)));

               IF To_char(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa,'yyyymm') =
                  to_char(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa,'yyyymm') AND
                  (vDtFimAfast - PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa + 1) > 30
                  THEN

                   vVlIndice := vVlIndice + 30;

               ELSE

                  vVlIndice := vVlIndice + vDtFimAfast - PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa + 1;

               END IF;
               --
               -- Anulados apos o calculo definitivo e incluidos antes do calculo
               --

               IF PKGPAG_VAR.vgAfastAnulado.COUNT > 0 THEN

                  vNuDiasAfastAnulado := 0;

                  FOR j IN PKGPAG_VAR.vgAfastAnulado.FIRST .. PKGPAG_VAR.vgAfastAnulado.LAST
                     LOOP

                    begin

                    if trunc(PKGPAG_VAR.vgAfastAnulado(j).DtAnulado) > trunc(pFolha.DtCalculoAnt) AND
                       trunc(PKGPAG_VAR.vgAfastAnulado(j).DtInclusao) < trunc(pFolha.DtCalculoAnt) AND
                       trunc(PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa) < trunc(pFolha.DtInicioMes) and
                       pRubrica.lsMotAfastTempImp.exists(PKGPAG_VAR.vgAfastAnulado(j).CdMotivoAfastamento) and
                      (PKGPAG_VAR.vgAfastAnulado(j).CdMotivoAfastamento = PKGPAG_VAR.vgAfastTempRemunMesAnt(i).CdMotivoAfastamento
                       OR (trunc(PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa) = trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa) AND
                           trunc(PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa) = trunc(PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfa)))
                      then

                          vNuDiasAfastAnulado := vNuDiasAfastAnulado +
                                                 least(pkgpag_var.vgFolha.DtInicioMes - 1, PKGPAG_VAR.vgAfastAnulado(j).DtFimAfa) -
                                                 PKGPAG_VAR.vgAfastAnulado(j).DtInicioAfa + 1;
                                                 --PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtFimAfaNoMes -
                                                 --PKGPAG_VAR.vgAfastTempRemunMesAnt(i).DtInicioAfa + 1;

                          vVlIndice := vVlIndice - vNuDiasAfastAnulado;
                    end if;

                     exception
                       when others
                         then
                           vVlIndice := vVlIndice;

                     end;
                   END LOOP;
                END IF;

            END IF;

        END LOOP;

        exception
          when no_data_found
            then
              if vVlSaldoNaoDescontado = 0
                then
                 pEventoGerado := FALSE;
                 RETURN;
              end if;

          when others
             then
               if vVlSaldoNaoDescontado = 0
                 then
                  pEventoGerado := FALSE;
                  RETURN;
              end if;

      END;

      IF vVlIndice <= 0 AND vVlSaldoNaoDescontado = 0
        THEN
          RETURN;
      END IF;

      BEGIN

        SELECT SUM(30)
          INTO vvltotalindperiodo
          FROM epagfolhapagamento folha
         INNER JOIN epagtipofolhapagamento tfp
            ON tfp.cdtipofolhapagamento = folha.cdtipofolhapagamento
         WHERE folha.flcalculodefinitivo = pkgpag_tipo.cns
           AND folha.cdtipocalculo = pkgpag_tipo.cntpcalculonormal
           AND tfp.cdtipofolha = pkgpag_tipo.cntpfolhanormal
           AND folha.cdorgao = pfolha.cdorgao
           AND folha.nuanomesreferencia BETWEEN
               to_number(to_char(vdtiniafast, 'yyyymm')) AND
               to_number(to_char((pfolha.dtiniciomes - 1), 'YYYYMM'));

        WITH fol AS
         (SELECT folha.cdfolhapagamento
            FROM epagfolhapagamento folha
           INNER JOIN epagtipofolhapagamento tfp
              ON tfp.cdtipofolhapagamento = folha.cdtipofolhapagamento
           WHERE folha.flcalculodefinitivo = pkgpag_tipo.cns
             AND folha.cdtipocalculo = pkgpag_tipo.cntpcalculonormal
             AND tfp.cdtipofolha = pkgpag_tipo.cntpfolhanormal
             AND folha.cdorgao = pfolha.cdorgao
             AND folha.nuanomesreferencia BETWEEN
                 to_number(to_char(vdtiniafast, 'yyyymm')) AND
                 to_number(to_char((pfolha.dtiniciomes - 1), 'YYYYMM'))),
        rub AS
         (SELECT v.cdrubricaagrupamento, v.cdtiporubrica
            FROM vpagrubricaagrupamento v
           WHERE v.nurubrica = prubrica.nurubrica
             AND v.cdtiporubrica IN (1, 8))

        SELECT sum(case when r.cdtiporubrica = 1 then hrv.vlpagamento else 0 end) AS CRED,
               --sum(case when r.cdtiporubrica = 8 then hrv.vlpagamento else 0 end) AS DEB,
               sum(case when r.cdtiporubrica = 1 then hrv.vlindicerubrica else 0 end)
               --sum(case when r.cdtiporubrica = 8 then hrv.vlindicerubrica else 0 end)
          INTO vValorPago/*, vValorDevolvido*/, vVlIndicePago/*, vVlIndiceDevolvido*/
          FROM Epaghistoricorubricavinculo hrv
         INNER JOIN FOL FF on FF.CdFolhaPagamento = hrv.cdfolhapagamento
         INNER JOIN RUB R on R.CdRubricaAgrupamento = hrv.cdrubricaagrupamento
         WHERE HRV.CDVINCULO = pCdVinculo;

        EXCEPTION
          WHEN NO_DATA_FOUND
            THEN

              IF vVlSaldoNaoDescontado > 0
                THEN

                 vValorPago := 0;
                 --vValorDevolvido := 0;
                 vVlIndicePago := 0;
                 --vVlIndiceDevolvido := 0;

              ELSE

                RETURN;

              END IF;

          WHEN OTHERS
            THEN

              IF vVlSaldoNaoDescontado > 0
                THEN

                 vValorPago := 0;
                 --vValorDevolvido := 0;
                 vVlIndicePago := 0;
                 --vVlIndiceDevolvido := 0;

              ELSE

                RETURN;

              END IF;

      END;
      -- Descontar do total de afastamentos os dias ja devolvidos

      IF vVlIndice > vVlIndicePago
        THEN

           vVlIndice := vVlIndicePago;

      END IF;

      IF vVlIndice > 0
        THEN

          vValorDevolvidoAnt.vlIndice := vVlIndice;

          vValorDevolvidoAnt.vlProporcional := vValorPago / vVlIndicePago * vValorDevolvidoAnt.vlIndice;

      ELSIF vVlSaldoNaoDescontado = 0
        THEN

         RETURN;

      else
        null;
      END IF;

      IF vValorDevolvidoAnt.vlIndice > 0 OR vVlSaldoNaoDescontado > 0
       THEN

       pEventoGerado := TRUE;

       vValorDevolvidoAnt.vlProporcional :=  nvl(vValorDevolvidoAnt.vlProporcional,0) + vVlSaldoNaoDescontado;

       PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                              pCdVinculo               => pCdVinculo,
                                              pCdRelacaoVinculo        => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                              pCdHistRelacaoVinculo    => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                              pCdExpressaoFormCalc     => NULL,
                                              pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                              pVlIntegral              => vValorDevolvidoAnt.vlProporcional,
                                              pVlProporcional          => vValorDevolvidoAnt.vlProporcional,
                                              pVlReal                  => vValorDevolvidoAnt.vlProporcional,
                                              pNuSufixoRubrica         => 1,
                                              pNuParcelas              => 1,
                                              pVlIndice                => vValorDevolvidoAnt.vlIndice,
                                              pcdtipoorigemrubrica     => 1,
                                              pcdtipoindice            => 4);

       pkgpag_var.vgVlDescontoIRESA := vValorDevolvidoAnt.vlProporcional;

       pkgpag_var.bGerouDescontoIRESA := TRUE;

       pkgpag_var.vgCdRubDescontoIRESA := pRubrica.CdRubricaAgrupamento;

      END IF;



   end if;

   EXCEPTION
      WHEN NO_DATA_FOUND
         THEN
           pEventoGerado := FALSE;

      WHEN OTHERS
         THEN
           pEventoGerado := FALSE;

  END;

  PROCEDURE P87MediaGratEspecSaude(
                    pCdVinculo IN INTEGER,
                    pFolha     IN PKGPAG_TIPO.rFolha,
                    pRubrica   IN PKGPAG_TIPO.rRubrica,
                    pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                    pCEF       IN PKGPAG_TIPO.tCEF,
                    pCCO       IN PKGPAG_TIPO.tCCO,
                    pCCOSubst  IN PKGPAG_TIPO.tCCO,
                    pFUC       IN PKGPAG_TIPO.tFUC,
                    pBOL       IN PKGPAG_TIPO.tBOL,
                    pAPO       IN PKGPAG_TIPO.tCEF

    ) IS

   vlIndice INTEGER :=0;
   vnuperiodo INTEGER := 0;

  BEGIN

          FOR i IN pRubrica.lsMotAfastTempEx.FIRST .. pRubrica.lsMotAfastTempEx.LAST
            LOOP

            CASE
                 WHEN pRubrica.lsMotAfastTempEx(i).CdPeriodoAfastamento = 1
                   THEN
                vnuperiodo := 0;

                 WHEN pRubrica.lsMotAfastTempEx(i).CdPeriodoAfastamento = 2
                   THEN
                vnuperiodo := 1;

              ELSE
                vnuperiodo := prubrica.lsmotafasttempex(i).nuperiodo;

            END CASE;

            vlIndice := vlIndice + PKGPAG_GERAL.fdiasafasttemp(pkgpag_var.vgvinculo.cdvinculo,
                                                  ADD_MONTHS(PKGPAG_VAR.vgFolha.DtInicioMes, - vNuPeriodo),
                                                  add_months(pkgpag_var.vgfolha.dtfimmes, -vnuperiodo),
                                                  pkgpag_var.vgfolha.dtcalculo,
                                                  pRubrica.lsMotAfastTempEx(i).cdmotivoafasttemporario);

          END LOOP;

          PKGPAG_EVENTO.PGeraRegistroPagamento(
                                 pTipoRegistro => 2,
                                 pFolha        => pFolha,
                                 pCdVinculo    => pCdVinculo,
                                 pRubrica      => pRubrica,
                                 pFormExpr     => pFormExpr,
                                 pCEF          => pCEF,
                                 pCCO          => pCCO,
                                 pCCOSubst     => pCCOSubst,
                                 pFUC          => pFUC,
                                 pBOL          => pBOL,
                                 pAPO          => pAPO,
                                 pVlIndice     => vlIndice,
                                 pDtDesligamento => pkgpag_var.vgVinculo.DtDesligamento,
                                 pDtCalculo    => PKGPAG_VAR.vDtCalculo );

  END;

  PROCEDURE P091Devolucao13SalarioCTISP(pFolha     IN PKGPAG_TIPO.rFolha,
                                        pCdVinculo IN INTEGER,
                                        pRubrica   IN PKGPAG_TIPO.rRubrica,
                                        pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo,
                                        pCEF       IN PKGPAG_TIPO.tCEF,
                                        pCCO       IN PKGPAG_TIPO.tCCO,
                                        pCCOSubst  IN PKGPAG_TIPO.tCCO,
                                        pFUC       IN PKGPAG_TIPO.tFUC,
                                        pBOL       IN PKGPAG_TIPO.tBOL,
                                        pAPO       IN PKGPAG_TIPO.tCEF) IS

  BEGIN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro   => 2,
                                           pFolha          => pFolha,
                                           pCdVinculo      => pCdVinculo,
                                           pRubrica        => pRubrica,
                                           pFormExpr       => pFormExpr,
                                           pFlPrincipal    => PKGPAG_TIPO.cnS,
                                           pCEF            => pCEF,
                                           pCCO            => pCCO,
                                           pCCOSubst       => pCCOSubst,
                                           pFUC            => pFUC,
                                           pBOL            => pBOL,
                                           pAPO            => pAPO,
                                           pVlIndice       => NULL,
                                           pDtCalculo      => PKGPAG_VAR.vDtCalculo,
                                           pDtDesligamento => PKGPAG_VAR.vgVinculo.DtDesligamento);

  END;

 PROCEDURE P124AbonoPermanencia (pFolha    IN PKGPAG_TIPO.rFolha,
                                     pRubrica  IN PKGPAG_TIPO.rRubrica,
                                     pCEF      IN PKGPAG_TIPO.tCEF,
                                     pFormExpr IN PKGPAG_TIPO.tFormulaCalculo,
                                     pCdVinculo IN INTEGER,
                                     pEventoGerado OUT BOOLEAN) IS

   vCdExpressaoFormCalc   INTEGER;
   vCont                  INTEGER := 0;
   --vCdChave               INTEGER := 0;
   --vNuDiasAnt             INTEGER := 0;
   --vNuDiasTotal           INTEGER := 0;

 BEGIN

       BEGIN

       pEventoGerado := FALSE;

       SELECT COUNT(ab.cdabonopermanencia),
              MIN(ab.dtconcessao)
         INTO vCont, pkgpag_var.vgDtInicioConcessaoAbonoPerm
         FROM epagabonopermanencia ab
         WHERE ab.cdvinculo = pCdVinculo
         AND ab.dtconcessao <= pfolha.DtFimMes
         AND (ab.dtfim >= pFolha.DtInicioMes OR ab.dtfim IS NULL)
         AND ab.flanulado = 'N';

        IF vCont = 0
          THEN
            RETURN;
        END IF;

        EXCEPTION
          WHEN NO_DATA_FOUND
            THEN
             RETURN;

          WHEN OTHERS
            THEN
              RETURN ;

        END;

     pEventoGerado := TRUE;
     vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => 1);
   -- 1) Busca a f?rmula associada
      IF vCdExpressaoFormCalc > 0 THEN

      PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 2, -- F?rmula de c?lculo
                                           pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pRubrica             => pRubrica,
                                           pFormExpr            => pFormExpr,
                                           pFlPrincipal         => PKGPAG_TIPO.cnN,
                                           pCEF                 => pCEF,
                                           pCCO                 => PKGPAG_VAR.vgCCO,
                                           pCCOSubst            => PKGPAG_VAR.vgCCOSubst,
                                           pFUC                 => PKGPAG_VAR.vgFUC,
                                           pBOL                 => PKGPAG_VAR.vgBOL,
                                           pAPO                 => PKGPAG_VAR.vgAPO,
                                           pVlIndice            => 14,
                                           pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                           pCdTipoOrigemRubrica => 6);

         pEventoGerado := TRUE;

      END IF;

  END;

  PROCEDURE P127IndenizacaoUniforme(pVinculo IN PKGPAG_TIPO.rVinculo,
                                    pFolha   IN PKGPAG_TIPO.rFolha,
                                    pRubrica IN PKGPAG_TIPO.rRubrica,
                                    pCEF     IN PKGPAG_TIPO.tCEF) IS
    
    FUNCTION FQtDiasAfastado(pDtInicio    IN DATE,
                             pDtFim       IN DATE,
                             pDtCalculo   IN DATE,
                             pCdVinculo   IN INTEGER) RETURN INTEGER IS
      
      vnudiasafast INTEGER;
      
    BEGIN
      
      SELECT nvl(SUM(diaafastado), 0) AS nudiaafast
        INTO vnudiasafast
        FROM (SELECT cdvinculo,
                     dtdia     AS dtdiaafastado,
                     1         AS diaafastado        
                FROM (SELECT pdtinicio + (LEVEL - 1) as dtdia                
                        FROM dual                
                      CONNECT BY pdtinicio + (LEVEL - 1) BETWEEN                          
                                 pdtinicio AND pdtfim) d        
               INNER JOIN (SELECT cdvinculo,                           
                                 CASE                           
                                   WHEN av.dtinicio < pdtinicio THEN                             
                                    pdtinicio                       
                                   ELSE                             
                                    av.dtinicio                           
                                 END AS dtinicio,                           
                                 CASE                           
                                   WHEN (av.dtfim > pdtfim OR                                  
                                        av.dtfim IS NULL) THEN                             
                                    pdtfim                        
                                   ELSE                             
                                    av.dtfim                           
                                 END AS dtfim                    
                            FROM eafaafastamentovinculo av                    
                           INNER JOIN eafamotivoafasttemporario mat                    
                              ON av.cdmotivoafasttemporario = mat.cdmotivoafasttemporario                    
                           INNER JOIN eafahistmotivoafasttemp hmat                    
                              ON mat.cdmotivoafasttemporario = hmat.cdmotivoafasttemporario                    
                           WHERE av.cdvinculo = pcdvinculo                          
                             -- AND hmat.flremunerado = pkgpag_tipo.cnn                         
                             AND av.dtinicio <= pdtfim                          
                             AND (av.dtfim >= pdtinicio OR av.dtfim IS NULL)                          
                             AND hmat.dtiniciovigencia <= pdtcalculo                          
                             AND (hmat.dtfimvigencia >= pdtcalculo or                           
                                 hmat.dtfimvigencia IS NULL)                          
                             AND hmat.flanulado = pkgpag_tipo.cnn                          
                             AND av.flanulado = pkgpag_tipo.cnn
                             AND hmat.flremuneracaointegral = 'S'
                             AND hmat.flferias = 'N') b        
                  ON (b.dtinicio <= d.dtdia)              
                 AND (b.dtfim >= d.dtdia)) a;
                 
      RETURN vnudiasafast;
      
    EXCEPTION
      
       WHEN OTHERS THEN
         
         RETURN 0;
         
    END;

    FUNCTION FLotacaoOrgao (pCdVinculo IN INTEGER)  RETURN INTEGER IS
      
      cdOrgaoLot INTEGER;
      
    BEGIN
      
          SELECT U.cdOrgao 
            INTO cdOrgaoLot
            FROM ECadLocalTrabalho l
           INNER JOIN ECadHistUnidadeOrganizacional U
              ON U.CdUnidadeOrganizacional = l.CdUnidadeOrganizacional
           WHERE l.cdvinculo = pCdVinculo
             AND l.dtInicio <= pfolha.dtFimMes
             AND (l.dtFim >= pfolha.dtInicioMes OR l.dtFim IS NULL)
             AND U.dtInicioVigencia <= pfolha.dtFimMes
             AND (U.dtFimVigencia >= pfolha.dtInicioMes OR U.dtFimVigencia IS NULL)
             AND L.CDHISTCARGOEFETIVO IS NOT NULL
             AND ROWNUM = 1;
    
        RETURN cdOrgaoLot;
        
    EXCEPTION
      
       WHEN OTHERS THEN
         
         RETURN 0;
         
    END;
    
  BEGIN
    
    -- Se for o mês do aniversário natalício e
    -- O vinculo estiver ativo a mais de 3 meses
    IF TO_CHAR(pVinculo.DtNascimento,'MM') = pFolha.NuMesReferencia AND
       MONTHS_BETWEEN(pFolha.DtCalculo,pVinculo.DtAdmissao) > 3 THEN

      -- Sem afastamento por mais de 6 meses  - 180 dias
      IF FQtDiasAfastado(to_date(to_char(pVinculo.DtNascimento,'DD') || 
                                 to_char(pVinculo.DtNascimento,'MM') || 
                                (pFolha.nuAnoReferencia - 1),'dd/mm/yyyy') + 1, 
                         to_date(to_char(pVinculo.DtNascimento,'DD') || 
                                 to_char(pVinculo.DtNascimento,'MM') || 
                                 pFolha.nuAnoReferencia,'dd/mm/yyyy'), 
                         pFolha.DtCalculo,
                         pVinculo.CdVinculo) < 180 THEN
                         
         IF pCEF.COUNT > 0 THEN

            FOR i IN pCEF.FIRST .. pCEF.LAST LOOP

               IF (pCEF(i).CdRelacaoTrabalho = PKGPAG_TIPO.cnRelCTISP AND FLotacaoOrgao(pVinculo.CdVinculo) IN (17,663)) OR
                   pCEF(i).CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelCTISP THEN
                   
                  IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                            pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                            pCdOrgaoExercicio         => pCEF(i).CdOrgaoExercicio,
                                                            pCdNaturezaVinculo        => pCEF(i).CdNaturezaVinculo,
                                                            pCdRelacaoTrabalho        => pCEF(i).CdRelacaoTrabalho,
                                                            pCdRegimeTrabalho         => pCEF(i).CdRegimeTrabalho,
                                                            pCdRegimePrevidenciario   => pCEF(i).CdRegimePrevidenciario,
                                                            pCdSituacaoPrevidenciaria => pCEF(i).CdSituacaoPrevidenciaria,
                                                            pCdUnidadeOrganizacional  => pCEF(i).CdUnidadeOrganizacional,
                                                            pCdEstruturaCarreira      => pCEF(i).CdEstruturaCarreira,
                                                            pFlAPOOrigemCCO           => pCEF(i).FlOrigemCCO,
                                                            pFlTipoProvimento         => pCEF(i).FlEfetivacao) THEN
                     IF PKGPAG_VAR.vgVlIndUniforme > 0 THEN
                       
                       PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                             pCdVinculo               => pVinculo.CdVinculo,
                                                             pCdRelacaoVinculo        => pCEF(i).CdRelacaoVinculo,
                                                             pCdHistRelacaoVinculo    => pCEF(i).CdHistRelVinc,
                                                             pCdExpressaoFormCalc     => NULL,
                                                             pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                             pVlIntegral              => PKGPAG_VAR.vgVlIndUniforme,
                                                             pVlProporcional          => PKGPAG_VAR.vgVlIndUniforme,
                                                             pVlReal                  => PKGPAG_VAR.vgVlIndUniforme,
                                                             pNuSufixoRubrica         => 1,
                                                             pNuParcelas              => 1,
                                                             pVlIndice                => NULL,
                                                             pcdtipoorigemrubrica     => 1);

                       EXIT;
                                                             
                     END IF; 
                     
                  END IF;                                                

               END IF;
               
            END LOOP;
            
         END IF;
         
      END IF;
       
    END IF;
    
  END;
  
  
  PROCEDURE PProcessaEventosVinc(pVinculo            IN PKGPAG_TIPO.rVinculo,
                                 pCdPessoa           IN INTEGER,
                                 pFolha              IN PKGPAG_TIPO.rFolha,
                                 pEvento             IN PKGPAG_TIPO.rEvento,
                                 pRubrica            IN PKGPAG_TIPO.tRubrica,
                                 pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                                 pCEF                IN PKGPAG_TIPO.tCEF,
                                 pCCO                IN PKGPAG_TIPO.tCCO,
                                 pCCOSubst           IN PKGPAG_TIPO.tCCO,
                                 pFUC                IN PKGPAG_TIPO.tFUC,
                                 pAPO                IN PKGPAG_TIPO.tCEF,
                                 pBOL                IN PKGPAG_TIPO.tBOL,
                                 pFlPagaAdiantamento IN CHAR DEFAULT PKGPAG_TIPO.cnN,
                                 --   pVlPercentualTotal  IN OUT NUMBER,
                                 pIndiceEvento IN INTEGER) IS

    bPagouAdicional BOOLEAN DEFAULT FALSE;

    bEventoGerado BOOLEAN;

    vCdExpressaoFormCalc INTEGER;

     vRubAgr01_0183  INTEGER;

  BEGIN

    bEventoGerado         := FALSE;
    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

    CASE

    -- 002 - Desconto de faltas parciais

      WHEN pEvento.CdTipoEventoPagamento = 2 THEN

        IF pEvento.CdTipoFalta IS NOT NULL THEN

          bEventoGerado := TRUE;

          P002DescontoFaltaParcial(pVinculo.CdVinculo,
                                   pFolha,
                                   pRubrica(pEvento.CdRubricaAgrupamento),
                                   pEvento.CdTipoFalta,
                                   pFormExpr,
                                   pCEF,
                                   pCCO,
                                   pCCOSubst,
                                   pFUC,
                                   pBOL,
                                   pAPO);

        END IF;

    -- 006 - Pagamento de adicional de tempo de servico

      WHEN pEvento.CdTipoEventoPagamento = 6 THEN

        bEventoGerado := TRUE;

        -----------------------------------------------------------------------------
        -- Inicializa os percentuais totais a acumular
        -----------------------------------------------------------------------------

        IF NOT
            PKGPAG_VAR.vPercentualTotalATS.EXISTS(pEvento.CdTipoTempoServico) THEN

          PKGPAG_VAR.vPercentualTotalATS(pEvento.CdTipoTempoServico) := 0;

        END IF;

        IF pFolha.CdAgrupamento = 176
          THEN

          P006AdicionalTempoServicoDPE(pCdVinculo => pVinculo.CdVinculo,
                                  pFolha     => pFolha,
                                  pEvento    => pEvento,
                                  pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                  pCEF       => pCEF,
                                  pCCO       => pCCO,
                                  pCCOSubst  => pCCOSubst,
                                  pFUC       => pFUC,
                                  pBOL       => pBOL,
                                  pAPO       => pAPO,
                                  pFormExpr  => pFormExpr);
        ELSE

          P006AdicionalTempoServico(pCdVinculo => pVinculo.CdVinculo,
                                  pFolha     => pFolha,
                                  pEvento    => pEvento,
                                  pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                  pCEF       => pCEF,
                                  pCCO       => pCCO,
                                  pCCOSubst  => pCCOSubst,
                                  pFUC       => pFUC,
                                  pBOL       => pBOL,
                                  pAPO       => pAPO,
                                  pFormExpr  => pFormExpr);
        END IF;
    -- 011 - Desconto de dias afastados
    -- 036 - Desconto de acidente de trabalho

      WHEN pEvento.CdTipoEventoPagamento IN (11, 36) THEN

        -- IF PKGPAG_VAR.vgParamPagamento.FlDescAfastSeparado = 'S' THEN

        bEventoGerado := TRUE;

        P011036DiasAfastNaoTrab(pFolha,
                                pVinculo.CdVinculo,
                                pRubrica(pEvento.CdRubricaAgrupamento),
                                pFormExpr,
                                pCEF,
                                pCCO,
                                pCCOSubst,
                                pFUC,
                                pBOL,
                                pAPO,
                                CASE pEvento.CdTipoEventoPagamento WHEN 11 THEN 'N' ELSE 'S' END);

    --   END IF;

    -- Pagamento em virtude de locais e atividades de risco
    -- 024 - Pagamento em virtude de locais e atividades de risco

      WHEN pEvento.CdTipoEventoPagamento = 24 THEN

        bEventoGerado := TRUE;

        P024RemuneracaoRisco(pVinculo.CdVinculo,
                             pFolha,
                             pRubrica(pEvento.CdRubricaAgrupamento),
                             pFormExpr,
                             pEvento.CdTipoRisco);

    -- 082 - Desconto de faltas integrais Mes Atual

      WHEN pEvento.CdTipoEventoPagamento = 82  THEN

        bEventoGerado := TRUE;

        P082DesctoFaltaIntMesAtual(pVinculo.CdVinculo,
                  pFolha,
                  pRubrica(pEvento.CdRubricaAgrupamento),
                  pFormExpr,
                  pCEF,
                  pCCO,
                  pCCOSubst,
                  pFUC,
                  pBOL,
                  pAPO);

    -- 081 - Desconto de faltas integrais Mes Anterior

      WHEN pEvento.CdTipoEventoPagamento = 81 THEN

        bEventoGerado := TRUE;

        P081DesctoFaltaIntMesAnt(pVinculo.CdVinculo,
                 pFolha,
                 pRubrica(pEvento.CdRubricaAgrupamento),
                 pFormExpr,
                 pCEF,
                 pCCO,
                 pCCOSubst,
                 pFUC,
                 pBOL,
                 pAPO);

    -- 025 - Desconto de faltas integrais

      WHEN pEvento.CdTipoEventoPagamento = 25 THEN

        bEventoGerado := TRUE;

    PKGPAG_VAR.vgIndiceFaltas := PKGPAG_VAR.vgIndiceFaltasMesAtual + PKGPAG_VAR.vgIndiceFaltasMesAnterior;

        P025DescontoFaltaIntegral(pVinculo.CdVinculo,
                                  pFolha,
                                  pRubrica(pEvento.CdRubricaAgrupamento),
                                  pFormExpr,
                                  pCEF,
                                  pCCO,
                                  pCCOSubst,
                                  pFUC,
                                  pBOL,
                                  pAPO);

    -- 029 - Pagamento de adicional de pos-graduacao

      WHEN pEvento.CdTipoEventoPagamento = 29 THEN

        -- Regras para concessao individual de adicional
        -- Para cada curso de pos-graduacao finalizado,
        -- processa nas 3 relacoes de vinculo

        bEventoGerado := TRUE;

        P029AdicionalPosGradConc(pCdPessoa      => pCdPessoa,
                                 pFolha         => pFolha,
                                 pRubrica       => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pFormExpr      => pFormExpr,
                                 pCEF           => pCEF,
                                 pAPO           => pAPO,
                                 pFUC           => pFUC,
                                 pCCO           => pCCO,
                                 bPagou         => bPagouAdicional,
                                 pGrauEscEvento => pEvento.CdGrauEscolaridade);

    -- 031 - Pagamento de 1/3 de ferias

      WHEN pEvento.CdTipoEventoPagamento = 31 AND
           pRubrica(pEvento.CdRubricaAgrupamento).FlSuspensa = 'N' AND
           (PFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias OR
           (pFolha.FlIncluiFerias = PKGPAG_TIPO.cnS AND
           pFolha.CdTipoFolha IN
           (PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaOutras, pkgpag_tipo.cnTpFolhaCtisp, PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaConvenio))) THEN

        PKGPAG_VAR.vgCdRubUmTercoFerias := pEvento.CdRubricaAgrupamento;

        IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

          IF PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho = PKGPAG_TIPO.cnRelCTISP THEN

            PKGPAG_VAR.vgCdRubUmTercoFerias := pEvento.CdRubAgrupAlternativa1;

          END IF;

        END IF;

    -- 033 - Pagamento de vale-transporte em pecunia

      WHEN pEvento.CdTipoEventoPagamento = 33 THEN

        bEventoGerado := TRUE;

        P033ValeTranspPecunia(pFolha,
                              pVinculo.CdVinculo,
                              pRubrica(pEvento.CdRubricaAgrupamento),
                              pFormExpr,
                              pCEF,
                              pCCO,
                              pCCOSubst,
                              pFUC,
                              pBOL,
                              pAPO);

    -- 034 - Pagamento de salario maternidade
    -- 035 - Desconto de salario maternidade

    -- Solicitacao Sustentacao #79726 - Nao gerar em folha de apuracao de diferencas
    -- 12122/2018 - FOLHA - - RUBRICAS DE SALARIO MATERNIDADE 02-0009 E 06-0509

      WHEN pEvento.CdTipoEventoPagamento IN (34, 35) AND pFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoDifMes then

        IF pVinculo.FlSexo = 'F' THEN

          bEventoGerado := TRUE;

          P034035SalMaternidade(pFolha,
                                pVinculo.CdVinculo,
                                pRubrica(pEvento.CdRubricaAgrupamento),
                                pFormExpr,
                                pCEF,
                                pCCO,
                                pCCOSubst,
                                pFUC,
                                pBOL,
                                pAPO);

        END IF;

    -- 037 - Pagamento da licenca premio em pecunia
    -- 038 - Pagamento de premio assiduidade em pecunia

      WHEN pEvento.CdTipoEventoPagamento IN (37, 38) THEN

        bEventoGerado := TRUE;

        P037038LicencaPremioPecAssid(pFolha,
                                     pVinculo.CdVinculo,
                                     pRubrica(pEvento.CdRubricaAgrupamento),
                                     pFormExpr,
                                     pEvento.CdTipoEventoPagamento,
                                     pCEF,
                                     pCCO,
                                     pCCOSubst,
                                     pFUC,
                                     pBOL,
                                     pAPO);

    -- 039 - Pagamento de vantagem da Lei 43

      WHEN pEvento.CdTipoEventoPagamento = 39 THEN

        bEventoGerado := TRUE;

        P039VantagemLei43(pFolha,
                          pVinculo.CdVinculo,
                          pRubrica(pEvento.CdRubricaAgrupamento),
                          pFormExpr,
                          pCEF,
                          pCCO,
                          pCCOSubst,
                          pFUC,
                          pAPO,
                          pBOL);

    -- 040 -  Pagamento de auxilio alimentacao por decisao judicial

      WHEN pEvento.CdTipoEventoPagamento = 40
        AND pFolha.CdTipoFolha not in (pkgpag_tipo.cnTpFolhaInstPensao, pkgpag_tipo.cnTpFolhaFunebre)

         THEN

         --
         -- Solicitacao de Sustentacao #75858
         -- FOLHA - 10297/2017 - PM-PARAMETRO PARA PAGTO DE CTISP
         --
         IF PKGPAG_VAR.bPossuiCtisp
          AND NOT pkgpag_var.bGeraPagamentoCTISP

          THEN

            bEventoGerado := FALSE;

         ELSE

          bEventoGerado := TRUE;

          pkgpag_alimentacao.P040AuxilioAliDecisaoJudicial(pCdVinculo => pVinculo.CdVinculo,
                                                           pFolha     => pFolha,
                                                           pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento));

         END IF;

    -- 041 - Pagamento de auxilio alimentacao

      WHEN pEvento.CdTipoEventoPagamento = 41
        AND pFolha.CdTipoFolha not in (pkgpag_tipo.cnTpFolhaInstPensao) THEN

        --
        -- Solicitacao de Sustentacao #75858
        -- FOLHA - 10297/2017 - PM-PARAMETRO PARA PAGTO DE CTISP
        --
        IF PKGPAG_VAR.bPossuiCtisp
          AND pkgpag_var.bGeraPagamentoCTISP = FALSE

          THEN

            bEventoGerado := FALSE;

        ELSE

          bEventoGerado := TRUE;

          -- Desmembramento do Auxilio Alimentacao para evitar concorrencia na manutencao desta rotina
          pkgpag_alimentacao.P041AuxilioAlimentacao(pCdVinculo => pVinculo.CdVinculo,
                                 pFolha     => pFolha,
                                 pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pCEF       => pCEF,
                                 pCCO       => pCCO,
                                 pCCOSubst  => pCCOSubst);

        END IF;

    -- 042 - Pagamento de diferenca de 1/3 de ferias
    -- 043 - Pagamento de devolucao de 1/3 de ferias

      WHEN pEvento.CdTipoEventoPagamento IN (42, 43)
           AND pRubrica(pEvento.CdRubricaAgrupamento).FlSuspensa = 'N'
           AND ((pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias OR
           (pFolha.FlIncluiFerias = PKGPAG_TIPO.cnS AND
           pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre,PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaCtisp,PKGPAG_TIPO.cnTpFolhaConvenio  ) )) OR
           (pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
           pFolha.CdAgrupamento in (2,3,4,5) /*CIASC, COHAB, CIDASC, EPAGRI*/
           )) THEN

        bEventoGerado := TRUE;

        CASE pEvento.CdTipoEventoPagamento

          WHEN 42 THEN

            PKGPAG_VAR.vgCdRubDifUmTercoFerias := pEvento.CdRubricaAgrupamento;

            -- Caso a relacao de trabalho seja CTISP

            IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

              IF PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho = PKGPAG_TIPO.cnRelCTISP THEN

                PKGPAG_VAR.vgCdRubDifUmTercoFerias := pEvento.CdRubAgrupAlternativa1;

              END IF;

            END IF;

          WHEN 43 THEN

            PKGPAG_VAR.vgCdRubDevUmTercoFerias := pEvento.CdRubricaAgrupamento;

            -- Caso a relacao de trabalho seja CTISP

            IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN
              -- (SIG-10024) Ausencia de devolucao de ferias - anulacao de usufruto - CTISP
              IF PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho = PKGPAG_TIPO.cnRelCTISP
                 and fPossuiFeriasAnuladasPagas(pVinculo.CdVinculo) THEN

                PKGPAG_VAR.vgCdRubDevUmTercoFerias := pEvento.CdRubAgrupAlternativa1;

              END IF;

            END IF;

        END CASE;

    -- 044 - Desconto de vale transporte

      WHEN pEvento.CdTipoEventoPagamento = 44 THEN

        bEventoGerado                    := TRUE;
        PKGPAG_VAR.vgCdRubValeTransporte := pEvento.CdRubricaAgrupamento;

    -- 045 - Desconto de limite maximo

      WHEN pEvento.CdTipoEventoPagamento = 45 THEN
        bEventoGerado                        := TRUE;
        PKGPAG_VAR.vgCdRubDescTetoGovernador := pEvento.CdRubricaAgrupamento;

      -- 047 - Devolucao de adiantamento de 13º salario
      -- 1506 ADMINISTRACAO DOS PENSIONISTAS DO ESTADO
      -- Desligados no mês
      WHEN pEvento.CdTipoEventoPagamento = 47 AND
           pFolha.CdOrgao = 34 AND --1506 ADMINISTRACAO DOS PENSIONISTAS DO ESTADO
           pFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaFunebre AND
           FDevolverAdnt13oServDesligado(PKGPAG_VAR.vgVinculo.DtDesligamento, pFolha.DtInicioMes, pFolha.DtFimMes,
           PKGPAG_VAR.vMotAfast.DtInclusao, PKGPAG_VAR.vDtCalculoAnt, PKGPAG_VAR.vDtCalculo) THEN

            vCdExpressaoFormCalc :=

                      PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                             pCdRubricaAgrupamento     => pEvento.CdRubricaAgrupamento,
                                                             pCdRelacaoVinculo         => 0);
            IF vCdExpressaoFormCalc > 0 THEN

             PKGPAG_GERAL.PInsereLancamentoRelacao(
                       pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                       pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                       pCdRelacaoVinculo     => 7,
                       pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                       pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                       pCdRubricaAgrupamento => pEvento.CdRubricaAgrupamento,
                       pVlIntegral           => NULL,
                       pVlProporcional       => NULL,
                       pNuSufixoRubrica      => 1,
                       pNuParcelas           => 1,
                       pVlIndice             => NULL,
                       pCdTipoOrigemRubrica  => 1);


            END IF;

         -- 047 - Devolucao de adiantamento de 13º salario
        WHEN pEvento.CdTipoEventoPagamento = 47 AND
             pFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaFunebre AND
             (pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaResidente13) OR
             FDevolverAdnt13oServDesligado(PKGPAG_VAR.vgVinculo.DtDesligamento, pFolha.DtInicioMes, pFolha.DtFimMes,
             PKGPAG_VAR.vMotAfast.DtInclusao, PKGPAG_VAR.vDtCalculoAnt, PKGPAG_VAR.vDtCalculo)) THEN

          -- Caso haja folha de decimo terceiro, nao realiza o desconto de ADIANT 13. SALARIO
         /* if (pFolha.NuMesReferencia = 12 AND PKGPAG_VAR.vgCdFolha13 > 0) and
            fPossuiContraCheque(PKGPAG_VAR.vgVinculo.CdVinculo, PKGPAG_VAR.vgCdFolha13) then
              return;
          end if;*/

        -- Caso seja devoluc?o de antecipac?o de um vinculo desligado calcula o evento posteriormente
        bEventoGerado := TRUE;
        PKGPAG_VAR.vgCdRubricaDevAnt13 := pEvento.CdRubricaAgrupamento;

        IF (PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes) THEN
           IF (PKGPAG_VAR.vgVinculo.bPossuiObito) THEN
              P047Devolucao13Salario(pFolha,
                                 pVinculo.CdVinculo,
                                 pRubrica(pEvento.CdRubricaAgrupamento),
                                 pFormExpr,
                                 pCEF,
                                 pCCO,
                                 pCCOSubst,
                                 pFUC,
                                 pBOL,
                                 pAPO);
           END IF;
        ELSE
          P047Devolucao13Salario(pFolha,
                                 pVinculo.CdVinculo,
                                 pRubrica(pEvento.CdRubricaAgrupamento),
                                 pFormExpr,
                                 pCEF,
                                 pCCO,
                                 pCCOSubst,
                                 pFUC,
                                 pBOL,
                                 pAPO);

       END IF;

    -- 048 - Desconto de contribuicao de plano de saude de titular

      WHEN pEvento.CdTipoEventoPagamento = 48 THEN

        bEventoGerado := TRUE;
        IF pVinculo.CdSituacaoPrevidenciaria <>
           PKGPAG_TIPO.cnSitPrevPensaoNaoPrev THEN

          PKGPAG_VAR.vgCdRubDescPlanSauTit := pEvento.CdRubricaAgrupamento;

        ELSE

          PKGPAG_VAR.vgCdRubDescPlanSauTit := pEvento.CdRubAgrupAlternativa1;

        END IF;

    -- 049 - Desconto de contribuicao de plano de saude de agregado

      WHEN pEvento.CdTipoEventoPagamento = 49 THEN
        bEventoGerado                    := TRUE;
        PKGPAG_VAR.vgCdRubDescPlanSauAgr := pEvento.CdRubricaAgrupamento;

    -- 050 - Desconto de co-participacao de plano de saude

      WHEN pEvento.CdTipoEventoPagamento = 50 THEN
        bEventoGerado                   := TRUE;
        PKGPAG_VAR.vgCdEventoDescCoPart := pIndiceEvento;

    -- 051 - Pagamento de antecipacao de 13º salario

      WHEN pEvento.CdTipoEventoPagamento = 51 AND
           (pFolha.CdTipoFolha IN
           (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaResidente13) OR
           (pFolha.FlIncluiAdiantamento13 = PKGPAG_TIPO.cnS AND
           pFolha.CdTipoFolha IN
           (PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaFerias, PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaConvenio))) THEN

        bEventoGerado := TRUE;

        P051Antecipacao13Salario(pFolha              => pFolha,
                                 pCdVinculo          => pVinculo.CdVinculo,
                                 pRubrica            => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pFormExpr           => pFormExpr,
                                 pCEF                => pCEF,
                                 pCCO                => pCCO,
                                 pCCOSubst           => pCCOSubst,
                                 pFUC                => pFUC,
                                 pBOL                => pBOL,
                                 pAPO                => pAPO,
                                 pFlPagaAdiantamento => pFlPagaAdiantamento);

    -- 052 - Pagamento de rescisao de 13º salario
      WHEN pEvento.CdTipoEventoPagamento = 52 AND
           pFolha.CdOrgao = 34 AND --1506 ADMINISTRACAO DOS PENSIONISTAS DO ESTADO
           pkgpag_var.vgRubrica(pEvento.CdRubricaAgrupamento).NuRubrica = 3323 AND
           FPaga13PensaoNaoPrev AND
           FPagarRescisao13oServDesligado(PKGPAG_VAR.vgVinculo.DtDesligamento, pFolha.DtInicioMes, pFolha.DtFimMes,
           PKGPAG_VAR.vMotAfast.DtInclusao, PKGPAG_VAR.vDtCalculoAnt, PKGPAG_VAR.vDtCalculo) THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubricaRecisao13PENSAO := pEvento.CdRubricaAgrupamento;

        P052Rescisao13Salario(pFolha,
                              pVinculo.CdVinculo,
                              pRubrica(pEvento.CdRubricaAgrupamento),
                              pFormExpr,
                              pCEF,
                              pCCO,
                              pCCOSubst,
                              pFUC,
                              pBOL,
                              pAPO,
                              PKGPAG_VAR.vgVinculo.DtDesligamento);

      -- SIGRH Service Desk
      -- SIG-101
      -- SEA - 12669/2018 Criar Evento para gerar o pagamento da rubrica de 13º  Sal CTISP Rescisao
      WHEN pEvento.CdTipoEventoPagamento = 52 and
           pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaCtisp and
           pkgpag_var.vgRubrica(pEvento.CdRubricaAgrupamento).NuRubrica = 2323 AND
           FPagarRescisao13oServDesligado(PKGPAG_VAR.vgVinculo.DtDesligamento, pFolha.DtInicioMes, pFolha.DtFimMes,
           PKGPAG_VAR.vMotAfast.DtInclusao, PKGPAG_VAR.vDtCalculoAnt, PKGPAG_VAR.vDtCalculo) THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubricaRecisao13CTISP := pEvento.CdRubricaAgrupamento;

        P052Rescisao13Salario(pFolha,
                              pVinculo.CdVinculo,
                              pRubrica(pEvento.CdRubricaAgrupamento),
                              pFormExpr,
                              pCEF,
                              pCCO,
                              pCCOSubst,
                              pFUC,
                              pBOL,
                              pAPO,
                              PKGPAG_VAR.vgVinculo.DtDesligamento);

      WHEN (pEvento.CdTipoEventoPagamento = 52 AND
           pkgpag_var.vgRubrica(pEvento.CdRubricaAgrupamento).NuRubrica = 1023 AND
           pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaServAfast,
                                  PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaConvenio) AND
           FPagarRescisao13oServDesligado(PKGPAG_VAR.vgVinculo.DtDesligamento, pFolha.DtInicioMes, pFolha.DtFimMes,
           PKGPAG_VAR.vMotAfast.DtInclusao, PKGPAG_VAR.vDtCalculoAnt, PKGPAG_VAR.vDtCalculo))
           THEN

           vVlRub1023 := 0;

        if pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaFunebre and
           PKGPAG_VAR.vMotAfast.DtInclusao > PKGPAG_VAR.vDtCalculoAnt then

           begin

             SELECT CdFolhaPagamento
               into vCdFolhaNormal
               FROM EPagFolhaPagamento FP
               inner join epagtipofolhapagamento tf on
                          tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
               inner join epagtipofolha tp on tp.cdtipofolha = tf.cdtipofolha
              WHERE FP.CdOrgao = PKGPAG_VAR.vgFolha.CdOrgao AND
                    FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                    tf.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
                    FP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                    FP.NuMesReferencia =PKGPAG_VAR.vgFolha.NuMesReferencia;

              exception
                when others then
                  vCdFolhaNormal :=0;

           end;

           vVlRub1023 := pkgpag_geral.fretornavalorrubrica(vCdFolhaNormal,
                                                           pVinculo.CdVinculo,
                                                           pEvento.CdRubricaAgrupamento);

           if vVlRub1023 > 0 then
             bEventoGerado := TRUE;
             PKGPAG_VAR.vgCdRubricaRecisao13 := pEvento.CdRubricaAgrupamento;

             P052Rescisao13Salario(pFolha,
                                pVinculo.CdVinculo,
                                pRubrica(pEvento.CdRubricaAgrupamento),
                                pFormExpr,
                                pCEF,
                                pCCO,
                                pCCOSubst,
                                pFUC,
                                pBOL,
                                pAPO,
                                PKGPAG_VAR.vgVinculo.DtDesligamento);
           end if;

        else
                    
          -- 24430/2025 - Tiago Von - INICIO
          IF PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes THEN
             
             vVlRub1023 := pkgpag_geral.fretornavalorrubrica(pFolha.CdFolhaPagamentoNormalAnt,
                                                             pVinculo.CdVinculo,
                                                             pEvento.CdRubricaAgrupamento);
           
          ELSE 

             vVlRub1023 := pkgpag_geral.fretornavalorrubrica(vCdFolhaNormal,
                                                             pVinculo.CdVinculo,
                                                             pEvento.CdRubricaAgrupamento);
                                                             
          END IF; 
         
          IF vVlRub1023 = 0 THEN
         
             -- 24430/2025 - Tiago Von - FIM
                        
             bEventoGerado := TRUE;
             PKGPAG_VAR.vgCdRubricaRecisao13 := pEvento.CdRubricaAgrupamento;

             P052Rescisao13Salario(pFolha,
                                   pVinculo.CdVinculo,
                                   pRubrica(pEvento.CdRubricaAgrupamento),
                                   pFormExpr,
                                   pCEF,
                                   pCCO,
                                   pCCOSubst,
                                   pFUC,
                                   pBOL,
                                   pAPO,
                                   PKGPAG_VAR.vgVinculo.DtDesligamento);
         
           END IF; -- 24430/2025 - Tiago Von 
         
        END IF; 

    -- 053 - Pagamento de comissoes

      WHEN pEvento.CdTipoEventoPagamento = 53 THEN

        bEventoGerado := TRUE;

        P053RemuneracaoComissao(pFolha,
                                pVinculo.CdVinculo,
                                pRubrica(pEvento.CdRubricaAgrupamento),
                                pEvento.CdTipoComConselhoGrupo,
                                pEvento.NuFormulaEspecifica,
                                pFormExpr,
                                pCEF,
                                pCCO,
                                pCCOSubst,
                                pFUC,
                                pBOL,
                                pAPO,
                                pEvento.CdHistEventoPagAgrup);

    -- 054 - Contribuicao Sindical

      WHEN pEvento.CdTipoEventoPagamento = 54 THEN

        bEventoGerado := TRUE;

        PKGPAG_POS.PContribuicaoSindical(pFolha     => pFolha,
                                         pCdVinculo => pVinculo.CdVinculo,
                                         pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                         pFormExpr  => pFormExpr,
                                         pCEF       => pCEF,
                                         pCCO       => pCCO,
                                         pCCOSubst  => pCCOSubst,
                                         pFUC       => pFUC,
                                         pBOL       => pBOL,
                                         pAPO       => pAPO);

    -- 055 - Desconto de limite maximo - 13º Salario

      WHEN pEvento.CdTipoEventoPagamento = 55 THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubDescTetoGovernador13 := pEvento.CdRubricaAgrupamento;

    -- 056 - Devolucao de adinatamento de13º salario de pensao

      WHEN pEvento.CdTipoEventoPagamento = 56 THEN

        bEventoGerado := TRUE;

        P056Devolucao13SalPensao(pFolha     => pFolha,
                                 pCdVinculo => pVinculo.CdVinculo,
                                 pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento));

    -- 057 - Pagamento de abono pecuniario de ferias

      WHEN pEvento.CdTipoEventoPagamento = 57 AND
           (PFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias OR
           (pFolha.FlIncluiFerias = PKGPAG_TIPO.cnS AND
           pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaConvenio) )) THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubAbonoPecuniario := pEvento.CdRubricaAgrupamento;

    -- 058 - Pagamento de adiantamento de salario em decorrencia de ferias

      WHEN pEvento.CdTipoEventoPagamento = 58 AND
           (PFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias OR
           (pFolha.FlIncluiFerias = PKGPAG_TIPO.cnS AND
           pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaConvenio ))) THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubAdiantSalFerias := pEvento.CdRubricaAgrupamento;

    -- 059 - Devolucao de adiantamento de salario em decorrencia de ferias

      WHEN pEvento.CdTipoEventoPagamento = 59 AND
           pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaConvenio ) THEN

        bEventoGerado := TRUE;

        P059DevolucaoAdiantFerias(pFolha     => pFolha,
                                  pCdVinculo => pVinculo.CdVinculo,
                                  pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento));

    -- 060 - Pagamento de 1/3 de abono pecuniario de ferias

      WHEN pEvento.CdTipoEventoPagamento = 60 AND
           (PFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias OR
           (pFolha.FlIncluiFerias = PKGPAG_TIPO.cnS AND
           pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaConvenio )  )) THEN
        bEventoGerado                   := TRUE;
        PKGPAG_VAR.vgCdRubAbono13Ferias := pEvento.CdRubricaAgrupamento;

    -- 062 - Auxilio Creche

      WHEN pEvento.CdTipoEventoPagamento = 62
       AND fPossuiAuxCreche(pVinculo.CdVinculo)

       THEN

        bEventoGerado := TRUE;

        P062AuxilioCreche(pFolha,
                          pVinculo.CdVinculo,
                          pRubrica(pEvento.CdRubricaAgrupamento),
                          pFormExpr,
                          pCEF,
                          pCCO,
                          pCCOSubst,
                          pFUC,
                          pBOL,
                          pAPO,
                          CASE WHEN pEvento.CdRubAgrupAlternativa2 IS NOT NULL
                               THEN pRubrica(pEvento.CdRubAgrupAlternativa2)
                               ELSE NULL END);

      WHEN pEvento.CdTipoEventoPagamento = 63 THEN

        bEventoGerado := TRUE;

        P063MediaFerias(pFolha,
                        pVinculo.CdVinculo,
                        pRubrica(pEvento.CdRubricaAgrupamento),
                        pFormExpr,
                        pCEF,
                        pCCO,
                        pCCOSubst,
                        pFUC,
                        pBOL,
                        pAPO);

    -- 064 - Pagamento diferenca de abono pecuniario de ferias

      WHEN pEvento.CdTipoEventoPagamento = 64 AND
           (pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre,PKGPAG_TIPO.cnTpFolhaServAfast, PKGPAG_TIPO.cnTpFolhaConvenio)) THEN

        bEventoGerado := TRUE;

        vRubAgr01_0183 := PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 1, 183);

          if (pEvento.CdRubricaAgrupamento = vRubAgr01_0183) then
              PKGPAG_VAR.vgCdRubDifAbonoPecuniario := vRubAgr01_0183;
          end if;

    -- 069 - Pagamento de Rescisao de Ferias para ACT/CTISP

      WHEN pEvento.CdTipoEventoPagamento = 69

       THEN

        IF pkgpag_var.vgFolha.CdAgrupamento = 134 or pkgpag_var.vgFolha.cdorgao = 14

          THEN

            IF (pkgpag_var.vgcef.count > 0 AND pkgpag_var.vgCef(1).CdRelacaoTrabalho = pkgpag_tipo.cnrelctisp
              or (pkgpag_var.vgCef(1).CdRelacaoTrabalho = pkgpag_tipo.cnRelACT AND pkgpag_var.vgFolha.cdorgao = 14))

              THEN
               --
               -- 9970/2017 - FOLHA - PAGAMENTO DE FERIAS PARA CTISP BASE MILITARES
               --
               pkgpag_var.vgNuDiasFeriasNaoPagas := 0;

               pkgpag_var.vgNuDiasFeriasPrevistos := 0;

               IF PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN
                  PKGPAG_VAR.vgFolha.DtInicioMes AND PKGPAG_VAR.vgFolha.DtFimMes
                  AND fPossuiFeriasConqNaoPaga(pVinculo.CdVinculo,
                                               pFolha,
                                               pRubrica(pEvento.CdRubricaAgrupamento),
                                               pEvento.CdRubAgrupAlternativa1,
                                               pFormExpr)
               THEN

                 bEventoGerado := TRUE;

                PKGPAG_VAR.vgCdEventoRescisaoACT := pIndiceEvento;

               END IF;

           END IF;

        ELSE

           bEventoGerado := TRUE;

           PKGPAG_VAR.vgCdEventoRescisaoACT := pIndiceEvento;

        END IF;

     -- 071 - Estorno de faltas

      WHEN pEvento.CdTipoEventoPagamento = 71 THEN

        bEventoGerado := TRUE;

           P071FaltaAbonada(pVinculo.CdVinculo,
                         pFolha,
                         pRubrica(pEvento.CdRubricaAgrupamento),
                         pFormExpr,
                         pCEF,
                         pCCO,
                         pCCOSubst,
                         pFUC,
                         pBOL,
                         pAPO);

    -- 072 - Descontos eventuais

      WHEN pEvento.CdTipoEventoPagamento = 72 THEN

        bEventoGerado := TRUE;

        PKGPAG_POS.PDescontoEventual(pFolha     => pFolha,
                                     pCdVinculo => pVinculo.CdVinculo,
                                     pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                     pFormExpr  => pFormExpr,
                                     pCEF       => pCEF,
                                     pCCO       => pCCO,
                                     pCCOSubst  => pCCOSubst,
                                     pFUC       => pFUC,
                                     pBOL       => pBOL,
                                     pAPO       => pAPO);

    -- 073 - Ferias indenizadas

      WHEN pEvento.CdTipoEventoPagamento = 73 THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubFeriasIndenizadas := pEvento.CdRubricaAgrupamento;

    -- 074 - Ferias indenizadas 1/3

      WHEN pEvento.CdTipoEventoPagamento = 74 THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubFeriasIndenUmTerco := pEvento.CdRubricaAgrupamento;

      -- 080 - Suspensao convertida em multa

      WHEN pEvento.CdTipoEventoPagamento = 80
       AND PKGPAG_GERAL.fPossuiPunicao(pVinculo.CdVinculo, pFolha) > 0

        THEN

        bEventoGerado := TRUE;

        P080SuspensaoMulta (pFolha => pFolha,
                            pRubrica => pRubrica(pEvento.CdRubricaAgrupamento),
                            pCEF => pCEF,
                            pFormExpr => pFormExpr,
                            pCdVinculo => pVinculo.CdVinculo);

      -- Abono Rescisao EPAGRI
      WHEN pEvento.CdTipoEventoPagamento = 83
       AND pVinculo.DtDesligamento between pFolha.DtInicioMes and pFolha.DtFimMes

        THEN

        P083AbonoFeriasRescisao (pFolha => pFolha,
                                 pRubrica => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pCEF => pCEF,
                                 pFormExpr => pFormExpr,
                                 pCdVinculo => pVinculo.CdVinculo,
                                 pEventoGerado => bEventoGerado);

      -- Devolucao automatica remuneracao atividade especial.
      WHEN pEvento.CdTipoEventoPagamento = 85
        THEN

         P085DevolucaoRemAtivEspecial (pFolha => pFolha,
                                       pRubrica => pRubrica(pEvento.CdRubricaAgrupamento),
                                       pCEF => pCEF,
                                       --pFormExpr => pFormExpr,
                                       pCdVinculo => pVinculo.CdVinculo,
                                       pEventoGerado => bEventoGerado);

      -----------------------------------------
       WHEN pEvento.CdTipoEventoPagamento = 87

        THEN

          P87MediaGratEspecSaude(pFolha        => pFolha,
                                 pCdVinculo    => pVinculo.CdVinculo,
                                 pRubrica      => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pFormExpr     => pFormExpr,
                                 pCEF          => pCEF,
                                 pCCO          => pCCO,
                                 pCCOSubst     => pCCOSubst,
                                 pFUC          => pFUC,
                                 pBOL          => pBOL,
                                 pAPO          => pAPO );

      -- PAGAMENTO DE FERIAS INDENIZADAS PARA ACT NA SJC
      WHEN pEvento.CdTipoEventoPagamento = 89 THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubFeriasIndenizadasACTSJC := pEvento.CdRubricaAgrupamento;

      -- 091 - Devolucao de adiantamento de 13º salario CTISP
      WHEN pEvento.CdTipoEventoPagamento = 91 AND
            (pFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolhaCtisp13,
                                   pkgpag_tipo.cnTpFolhaAdiant13Ctisp) or
             (pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaCtisp and
              (((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
                (PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes)) AND
                 NOT PKGPAG_VAR.bPossuiObito))) THEN

        -- Caso seja devoluc?o de antecipac?o de um vinculo desligado calcula o evento posteriormente
        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubricaDevAnt13 := pEvento.CdRubricaAgrupamento;

        P091Devolucao13SalarioCTISP(pFolha,
                                    pVinculo.CdVinculo,
                                    pRubrica(pEvento.CdRubricaAgrupamento),
                                    pFormExpr,
                                    pCEF,
                                    pCCO,
                                    pCCOSubst,
                                    pFUC,
                                    pBOL,
                                    pAPO);

      WHEN pEvento.CdTipoEventoPagamento = 92 THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubFeriasIndenizadasVinc := pEvento.CdRubricaAgrupamento;

      WHEN pEvento.CdTipoEventoPagamento = 124 THEN

        P124AbonoPermanencia (pFolha => pFolha,
                                 pRubrica => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pCEF => pCEF,
                                 pFormExpr => pFormExpr,
                                 pCdVinculo => pVinculo.CdVinculo,
                                 pEventoGerado => bEventoGerado);

     WHEN pEvento.CdTipoEventoPagamento = 127 THEN                                 
       
       P127IndenizacaoUniforme(pVinculo => pVinculo,
                               pFolha   => pFolha,
                               pRubrica => pRubrica(pEvento.CdRubricaAgrupamento),
                               pCEF     => pCEF);
       
    -----------------------------------------
    -- Fim Eventos


      ELSE

        NULL;

    END CASE;


    IF bEventoGerado THEN

      PKGPAG_GERAL.PLogTrace('EVVINC - Evento Gerado ' ||
                             pEvento.CdTipoEventoPagamento,
                             pEvento.DeEvento || ' - Vinc',
                             PKGPAG_VAR.vgTmInicio);

    ELSE

      PKGPAG_GERAL.PLogTrace('EVVINC - Evento Não Gerado ' ||
                             pEvento.CdTipoEventoPagamento,
                             pEvento.DeEvento || ' - Vinc',
                             PKGPAG_VAR.vgTmInicio);

    END IF;

    EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'EVVINC - Erro ao processar Evento (' || pEvento.CdTipoEventoPagamento || ') - ' || pEvento.DeEvento ,
                              PKGPAG_VAR.vgCdVinculo);
  END;

end PKGPAG_EVVINC;
/
