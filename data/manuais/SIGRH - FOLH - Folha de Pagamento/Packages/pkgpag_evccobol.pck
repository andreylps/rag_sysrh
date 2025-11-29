create or replace package PKGPAG_EVCCOBOL is

/*

   Tratamento de Eventos da Folha de Pagamento

   Relacao de Vinculo Comissionado/Bolsista

*/

PROCEDURE PProcessaEventosCCO (pVinculo             IN PKGPAG_TIPO.rVinculo,
                               pFolha               IN PKGPAG_TIPO.rFolha,
                               pEvento              IN PKGPAG_TIPO.rEvento,
                               pRubrica             IN PKGPAG_TIPO.tRubrica,
                               pFormExpr            IN PKGPAG_TIPO.tFormulaCalculo,
                               pParamPag            IN EPagAgrupamentoParametro%ROWTYPE,
                               pCCO                 IN PKGPAG_TIPO.tCCO,
                               pdtCalculo           IN DATE,
                               pCdEstruturaCarreira IN INTEGER);

PROCEDURE PProcessaEventosCCOSubst (pVinculo            IN PKGPAG_TIPO.rVinculo,
                                    pFolha              IN PKGPAG_TIPO.rFolha,
                                    pEvento             IN PKGPAG_TIPO.rEvento,
                                    pRubrica            IN PKGPAG_TIPO.tRubrica,
                                    pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                                    pParamPag           IN EPagAgrupamentoParametro%ROWTYPE,
                                    pCCOSubst           IN PKGPAG_TIPO.tCCO,
                                    pdtCalculo          IN DATE);

PROCEDURE PProcessaEventosBOL (pVinculo            IN PKGPAG_TIPO.rVinculo,
                               pFolha              IN PKGPAG_TIPO.rFolha,
                               pEvento             IN PKGPAG_TIPO.rEvento,
                               pRubrica            IN PKGPAG_TIPO.tRubrica,
                               pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                               pBOL                IN PKGPAG_TIPO.tBOL,
                               pdtCalculo          IN DATE) ;

FUNCTION FObterValorTotalProporcional(pCdvinculo            IN INTEGER,
                                      pCdfolhapagamento     IN INTEGER,
                                      pCdrubricaagrupamento IN INTEGER,
                                      pCdhistcargocom       IN INTEGER,
                                      pDtinicio             IN DATE,
                                      pDtfim                IN DATE) RETURN NUMBER;

end PKGPAG_EVCCOBOL;
/
create or replace package body PKGPAG_EVCCOBOL is

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

------------------------------------------------------------------------------------
-- Antecao -> eventos 15, 17 e 23 estao sendo calculados dentro da rotina do efetivo
-- PKGPAG_CEFAPO.P015a017e023RemunHoraExtra
------------------------------------------------------------------------------------

/*----------------------------------------------------------------------------------------------*/
-- Procedure: P015a017RemuneracaoHoraExtra
--
--  Objetivo: Gerar rubrica de horas extras normais, horas extras especiais para cargos
--            comissionado
--            levando em consideracao as jornadas e escalas de servico
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P015a017e023RemunHoraExtra(pFolha                 IN PKGPAG_TIPO.rFolha,
                                     pRubrica               IN PKGPAG_TIPO.rRubrica,
                                     pCCO                   IN PKGPAG_TIPO.rCCO,
                                     pFormExpr              IN PKGPAG_TIPO.tFormulaCalculo,
                                     pCdTipoRegistroJornada IN INTEGER DEFAULT 0,
                                     pCdTipoRegistroEscala  IN INTEGER DEFAULT 0,
                                     pCdTpEscSobreAviso     IN INTEGER DEFAULT 0)
IS

    vHorasJornada        INTEGER DEFAULT 0;

    vHorasEscala         INTEGER DEFAULT 0;

    vMinutosTotal        INTEGER DEFAULT 0;

    vHorasTotal          INTEGER DEFAULT 0;

    vCdExpressaoFormCalc INTEGER;

  FUNCTION FPossuiBancoDeHoras

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN

    SELECT COUNT(*)
      INTO vCont
      FROM EPagBHApurado BH
     WHERE BH.CdHistCargoCom = pCCO.CdHistCargoCom AND
           BH.NuAnoReferencia = pFolha.NuAnoReferencia AND
           BH.NuMesReferencia = pFolha.NuMesReferencia;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  END;

  /*------------------------------------------------------*/
  FUNCTION FRetornaHorasJornada
  /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras   NUMBER(4);

      vMinutos NUMBER(8);

  BEGIN

    IF pCdTipoRegistroJornada > 0 THEN

      SELECT SUM(SUBSTR(LPAD(TRIM(FJ.QtHoras),4,'0'),1,2)),
             SUM(SUBSTR(LPAD(TRIM(FJ.QtHoras),4,'0'),3,2))
            INTO vHoras,
                 vMinutos
            FROM EMovFrequenciaJornada FJ
           INNER JOIN ECadHistJornadaTrabalho HJT
              ON FJ.CdHistJornadaTrabalho = HJT.CdHistJornadaTrabalho
           INNER JOIN ECadLocalTrabalho LT
              ON HJT.CdLocalTrabalho = LT.CdLocalTrabalho
           WHERE LT.CdHistCargoCom = pCCO.CdHistCargoCom AND
                 LT.FlAnulado = PKGPAG_TIPO.cnN AND
                 FJ.CdTipoRegistroJornada = pCdTipoRegistroJornada AND
                 FJ.DtFrequencia
                   BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                           PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao;

        IF vMinutos > 59 THEN

          vHoras := vHoras + TRUNC(vMinutos/60);

          vMinutos := MOD(vMinutos,60);

        END IF;

        RETURN LPAD(NVL(vHoras,0),LENGTH(vHoras),'0') || LPAD(NVL(vMinutos,0),2,'0');

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

     WHEN NO_DATA_FOUND THEN

       RETURN 0;

   END;

  /*------------------------------------------------------*/
  FUNCTION FRetornaHorasEscala
  /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras   NUMBER(4);

      vMinutos NUMBER(8);

  BEGIN

    SELECT SUM(SUBSTR(LPAD(TRIM(FE.QtHoras),4,'0'),1,2)),
           SUM(SUBSTR(LPAD(TRIM(FE.QtHoras),4,'0'),3,2))
          INTO vHoras,
               vMinutos
          FROM EMovFrequenciaEscala FE
         INNER JOIN EMovHistEscalaServico HES
            ON FE.CdHistEscalaServico = HES.CdHistEscalaServico
         INNER JOIN ECadLocalTrabalho LT
            --9056
            --ON HES.CdLocalTrabalho = LT.CdLocalTrabalho
            ON HES.CdVinculo = LT.CdVinculo
         INNER JOIN EmovModeloEscalaServico MES
            ON HES.CdModeloEscalaServico = MES.CdModeloEscalaServico
         INNER JOIN EMOVORGAOESCALA oe
            ON oe.CdOrgao = PKGPAG_VAR.vgCdOrgaoVinculo
           AND oe.DTINICIOVIGENCIA <= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao
           AND (oe.DTFIMVIGENCIA >= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao OR oe.DTFIMVIGENCIA IS NULL)
          LEFT JOIN EMovEmpregoEscalaServico EES
            ON HES.CdEmpregoEscalaServico = EES.CdEmpregoEscalaServico
         WHERE LT.CdHistCargoCom = pCCO.CdHistCargoCom AND
               LT.FlAnulado = PKGPAG_TIPO.cnN AND
               FE.CdTipoRegistroEscala IN (pCdTipoRegistroEscala, pCdTpEscSobreAviso) AND
               (EES.FlPagtoServicoExtra = PKGPAG_TIPO.cnS OR oe.FlPagaExtra = PKGPAG_TIPO.cnS) AND
               FE.DtFrequencia
                 BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                         PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao;

      IF vMinutos > 59 THEN

        vHoras := vHoras + TRUNC(vMinutos/60);

        vMinutos := MOD(vMinutos,60);

      END IF;

      RETURN LPAD(NVL(vHoras,0),2,'0') || LPAD(NVL(vMinutos,0),2,'0');

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       RETURN 0;

   END;

   /*------------------------------------------------------*/
   FUNCTION FRetornaHorasJornadaHomolog
   /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras   NUMBER(4);

      vMinutos NUMBER(8);

   BEGIN

      IF pCdTipoRegistroJornada > 0 THEN

         SELECT SUM(SUBSTR(LPAD(TRIM(FJ.QtHoras),4,'0'),1,2)),
                SUM(SUBSTR(LPAD(TRIM(FJ.QtHoras),4,'0'),3,2))
           INTO vHoras,
                vMinutos
           FROM EMovFrequenciaJornada FJ
          INNER JOIN ECadHistJornadaTrabalho HJT
             ON FJ.CdHistJornadaTrabalho = HJT.CdHistJornadaTrabalho
          INNER JOIN ECadLocalTrabalho LT
             ON HJT.CdLocalTrabalho = LT.CdLocalTrabalho
          INNER JOIN EMovHomologFreqJornada HFJ
             ON HFJ.CdUnidadeOrganizacional = LT.CdUnidadeOrganizacional
          WHERE LT.CdHistCargoCom = pCCO.CdHistCargoCom AND
                HFJ.DtHomologacao = FJ.DtFrequencia AND
                HFJ.CdApuracaoFrequencia = PKGPAG_VAR.vgApuracaoFrequencia.CdApuracaoFrequencia AND
                FJ.CdTipoRegistroJornada = pCdTipoRegistroJornada AND
                LT.FlAnulado = PKGPAG_TIPO.cnN AND
                FJ.DtFrequencia
                  BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                          PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao;

         IF vMinutos > 59 THEN

           vHoras := vHoras + TRUNC(vMinutos/60);

           vMinutos := MOD(vMinutos,60);

         END IF;

        RETURN LPAD(NVL(vHoras,0),2,'0') || LPAD(NVL(vMinutos,0),2,'0');

      ELSE

        RETURN 0;

      END IF;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN 0;

    END;

   /*------------------------------------------------------*/
   FUNCTION FRetornaHorasEscalaHomolog
   /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras   NUMBER(4);

      vMinutos NUMBER(8);

   BEGIN

       SELECT SUM(SUBSTR(LPAD(TRIM(FE.QtHoras),4,'0'),1,2)),
              SUM(SUBSTR(LPAD(TRIM(FE.QtHoras),4,'0'),3,2))
         INTO vHoras,
              vMinutos
         FROM EMovFrequenciaEscala FE
        INNER JOIN EMovHistEscalaServico HES
           ON FE.CdHistEscalaServico = HES.CdHistEscalaServico
        INNER JOIN ECadLocalTrabalho LT
            --9056
            --ON HES.CdLocalTrabalho = LT.CdLocalTrabalho
            ON HES.CdVinculo = LT.CdVinculo
        INNER JOIN EMovHomologFreqEscala HFE
           ON HFE.CdUnidadeOrganizacional = LT.CdUnidadeOrganizacional
        INNER JOIN EMovModeloEscalaServico MES
           ON HES.CdModeloEscalaServico = MES.CdModeloEscalaServico
        INNER JOIN EMOVORGAOESCALA oe
           ON oe.CdOrgao = PKGPAG_VAR.vgCdOrgaoVinculo
          AND oe.DTINICIOVIGENCIA <= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao
          AND (oe.DTFIMVIGENCIA >= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao OR oe.DTFIMVIGENCIA IS NULL)

         LEFT JOIN EMovEmpregoEscalaServico EES
           ON EES.CdEmpregoEscalaServico = HES.CdEmpregoEscalaServico
        WHERE LT.CdHistCargoCom = pCCO.CdHistCargoCom AND
              HFE.DtHomologacao = FE.DtFrequencia AND
              HFE.CdApuracaoFrequencia = PKGPAG_VAR.vgApuracaoFrequencia.CdApuracaoFrequencia AND
             (EES.FlPagtoServicoExtra = PKGPAG_TIPO.cnS OR oe.FlPagaExtra = PKGPAG_TIPO.cnS) AND
              LT.FlAnulado = PKGPAG_TIPO.cnN AND
              FE.CdTipoRegistroEscala IN (pCdTipoRegistroEscala, pCdTpEscSobreAviso) AND
              FE.DtFrequencia
                BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                        PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao;

       IF vMinutos > 59 THEN

         vHoras := vHoras + TRUNC(vMinutos/60);

         vMinutos := MOD(vMinutos,60);

       END IF;

      RETURN LPAD(NVL(vHoras,0),2,'0') || LPAD(NVL(vMinutos,0),2,'0');

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN 0;

    END;

   /*------------------------------------------------------*/
    FUNCTION FRetornaHorasSobreAviso
   /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras   NUMBER(4) DEFAULT 0;

      vMinutos NUMBER(8) DEFAULT 0;

    BEGIN

       SELECT SUM(FE.DtFimReal - FE.DtInicioReal)*1440
         INTO vMinutos
         FROM EMovFrequenciaRealEscala FE
        INNER JOIN EMovHistEscalaServico HES
           ON FE.CdHistEscalaServico = HES.CdHistEscalaServico
        INNER JOIN ECadLocalTrabalho LT
            --9056
            --ON HES.CdLocalTrabalho = LT.CdLocalTrabalho
            ON HES.CdVinculo = LT.CdVinculo
        INNER JOIN EMovModeloEscalaServico MES
           ON HES.CdModeloEscalaServico = MES.CdModeloEscalaServico
        INNER JOIN EMOVORGAOESCALA oe
           ON oe.CdOrgao = PKGPAG_VAR.vgCdOrgaoVinculo
          AND oe.DTINICIOVIGENCIA <= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao
          AND (oe.DTFIMVIGENCIA >= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao OR oe.DTFIMVIGENCIA IS NULL)

         LEFT JOIN EMovEmpregoEscalaServico EES
           ON HES.CdEmpregoEscalaServico = EES.CdEmpregoEscalaServico
        WHERE LT.CdHistCargoCom = pCCO.CdHistCargoCom AND
              LT.FlAnulado = PKGPAG_TIPO.cnN AND
              FE.FlSobreAviso = PKGPAG_TIPO.cnS AND
              (EES.FlPagtoServicoExtra = PKGPAG_TIPO.cnS OR oe.FlPagaExtra = PKGPAG_TIPO.cnS) AND
              FE.DtFrequencia
              BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                      PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao;

      IF vMinutos > 59 THEN

        vHoras := vHoras + TRUNC(vMinutos/60);

        vMinutos := MOD(vMinutos,60);

      END IF;

      RETURN LPAD(NVL(vHoras,0),2,'0') || LPAD(NVL(vMinutos,0),2,'0');

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       RETURN 0;

   END;

   /*------------------------------------------------------*/
   FUNCTION FRetornaHorasSobreAvisoHom
   /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras   NUMBER(4) DEFAULT 0;

      vMinutos NUMBER(8) DEFAULT 0;

   BEGIN

      SELECT SUM(FE.DtFimReal - FE.DtInicioReal)*1440
        INTO vMinutos
        FROM EMovFrequenciaRealEscala FE
       INNER JOIN EMovHistEscalaServico HES
          ON FE.CdHistEscalaServico = HES.CdHistEscalaServico
       INNER JOIN ECadLocalTrabalho LT
            --9056
            --ON HES.CdLocalTrabalho = LT.CdLocalTrabalho
            ON HES.CdVinculo = LT.CdVinculo
       INNER JOIN EMovHomologFreqEscala HFE
          ON HFE.CdUnidadeOrganizacional = LT.CdUnidadeOrganizacional
       INNER JOIN EMovModeloEscalaServico MES
          ON HES.CdModeloEscalaServico = MES.CdModeloEscalaServico
       INNER JOIN EMOVORGAOESCALA oe
          ON oe.CdOrgao = PKGPAG_VAR.vgCdOrgaoVinculo
         AND oe.DTINICIOVIGENCIA <= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao
         AND (oe.DTFIMVIGENCIA >= PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao OR oe.DTFIMVIGENCIA IS NULL)

        LEFT JOIN EMovEmpregoEscalaServico EES
          ON EES.CdEmpregoEscalaServico = HES.CdEmpregoEscalaServico
       WHERE LT.CdHistCargoCom = pCCO.CdHistCargoCom AND
             HFE.DtHomologacao = FE.DtFrequencia AND
             HFE.CdApuracaoFrequencia = PKGPAG_VAR.vgApuracaoFrequencia.CdApuracaoFrequencia AND
            (EES.FlPagtoServicoExtra = PKGPAG_TIPO.cnS OR oe.FlPagaExtra = PKGPAG_TIPO.cnS) AND
             LT.FlAnulado = PKGPAG_TIPO.cnN AND
             FE.FlSobreAviso = PKGPAG_TIPO.cnS AND
             FE.DtFrequencia BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                                     PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao;

        IF vMinutos > 59 THEN

          vHoras :=  TRUNC(vMinutos/60);

          vMinutos := MOD(vMinutos,60);

       END IF;

       RETURN LPAD(NVL(vHoras,0),2,'0') || LPAD(NVL(vMinutos,0),2,'0');

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

BEGIN

  vHorasJornada := 0;

  vHorasEscala  := 0;

  vHorasTotal   := 0;

  -- Se a homologacao de frequencia nao e obrigatoria
  IF PKGPAG_VAR.vgApuracaoFrequencia.FlHomologaJornada = PKGPAG_TIPO.cnN THEN

    vHorasJornada := FRetornaHorasJornada;

  ELSE

    vHorasJornada := FRetornaHorasJornadaHomolog;

  END IF;

  IF PKGPAG_VAR.vgApuracaoFrequencia.FlHomologaEscala = PKGPAG_TIPO.cnN THEN

    vHorasEscala := FRetornaHorasEscala;

    IF pCdTpEscSobreAviso = 7 THEN

      vHorasEscala := vHorasEscala + FRetornaHorasSobreAviso;

    END IF;

  ELSE

    vHorasEscala := FRetornaHorasEscalaHomolog;

    IF pCdTpEscSobreAviso = 7 THEN

      vHorasEscala := vHorasEscala + FRetornaHorasSobreAvisoHom;

    END IF;

  END IF;

  vMinutosTotal := SUBSTR(LPAD(vHorasJornada,10,'0'),LENGTH(LPAD(vHorasJornada,10,'0'))-1,2) +
                   SUBSTR(LPAD(vHorasEscala,10,'0'),LENGTH(LPAD(vHorasEscala,10,'0'))-1,2);

  PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Remun Hora Extra', 'Horas min total: ' || vMinutosTotal);

  IF vMinutosTotal > 59 THEN

    vHorasTotal   := TRUNC(vMinutosTotal/60);

    vMinutosTotal := MOD(vMinutosTotal,60);

  END IF;

  PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Remun Hora Extra', 'Horas jornada : ' ||  SUBSTR(LPAD(vHorasJornada,10,'0'),1,LENGTH(LPAD(vHorasJornada,10,'0'))-2));
  PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Remun Hora Extra', 'Horas escala : ' || SUBSTR(LPAD(vHorasEscala,10,'0'),1,LENGTH(LPAD(vHorasEscala,10,'0'))-2));

  vHorasTotal := (vHorasTotal + SUBSTR(LPAD(vHorasJornada,10,'0'),1,LENGTH(LPAD(vHorasJornada,10,'0'))-2) +
                                SUBSTR(LPAD(vHorasEscala,10,'0'),1,LENGTH(LPAD(vHorasEscala,10,'0'))-2))*100;

  IF (vHorasTotal + vMinutosTotal)  > 0 THEN

    IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                     pRubrica                  => pRubrica,
                                     pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                     pCdOrgaoExercicio         => pCCO.CdOrgaoExercicio,
                                     pCdNaturezaVinculo        => pCCO.CdNaturezaVinculo,
                                     pCdRelacaoTrabalho        => pCCO.CdRelacaoTrabalho,
                                     pCdRegimeTrabalho         => pCCO.CdRegimeTrabalho,
                                     pCdRegimePrevidenciario   => pCCO.CdRegimePrevidenciario,
                                     pCdSituacaoPrevidenciaria => pCCO.CdSituacaoPrevidenciaria,
                                     pCdUnidadeOrganizacional  => pCCO.CdUnidadeOrganizacional,
                                     pCdMotivoMovimentacao     => pCCO.CdMotivoMovimentacao,
                                     pCdInstitutoMovimentacao  => pCCO.CdInstitutoMovimentacao) THEN

       -- 1) Busca a formula associada

       vCdExpressaoFormCalc :=

            PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                 pFormExpr                 => pFormExpr,
                                 pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                 pCdRelacaoVinculo         => 2,
                                 pCdUnidadeOrganizacional  => pCCO.CdUnidadeOrganizacional);

      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoRelacao(
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => pCCO.CdVinculo,
                              pCdRelacaoVinculo     => 2,
                              pCdHistRelacaoVinculo => pCCO.CdHistCargoCom,
                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => NULL,
                              pVlProporcional       => NULL,
                              pNuSufixoRubrica      => 1,
                              pNuParcelas           => 1,
                              pVlIndice             => (vHorasTotal + vMinutosTotal),
                              pCdTipoOrigemRubrica  => 7,
                              pDtInicio             => pCCO.DtInicio,
                              pDtFim                => pCCO.DtFim);

      END IF;

    END IF;

  END IF;

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

/*-----------------------------------------------------------------------------------------/
--     Procedure : P004RemuneracaoFixaCCO
--      Objetivo : Gerar a remuneracao fixa para a relacao de vinculo de cargo comissionado
--
--         Nota :
/*-----------------------------------------------------------------------------------------*/

PROCEDURE  P004RemuneracaoFixaCCO(pFolha           IN PKGPAG_TIPO.rFolha,
                                  pCCO             IN PKGPAG_TIPO.rCCO,
                                  pCalculaSUbst    IN CHAR DEFAULT 'N',
                                  pEvento          IN PKGPAG_TIPO.rEvento,
                                  pRubrica         IN PKGPAG_TIPO.rRubrica,
                                  pParamPagamento  IN Epagagrupamentoparametro%ROWTYPE,
                                  pDtCalculo       IN DATE,
                                  pFormExpr        IN PKGPAG_TIPO.tFormulaCalculo) IS

  vRemun                  PKGPAG_TIPO.rValorPagamento;
  vvlIntegral             NUMBER(13,2);
  vvlIntegralOR           NUMBER(13,2);
  vRubrica                PKGPAG_TIPO.rRubrica;
  vRubPercent             PKGPAG_TIPO.rRubPercent;
  vVlDiferenca            NUMBER(13,2);
  vCdAgrupamento          INTEGER:= 0;
  vCdExpressaoFormCalc    integer;
  vCdRubricaAlternativa   integer;
  vBOOLPropRub            BOOLEAN;

BEGIN
  

   vRubrica := pRubrica;
   vBOOLPropRub := TRUE;
   
   -- Se opcao de remuneracao nao e:
   -- 4) PELA REMUNERACAO ORIGEM
   -- 5) COMO MILITAR NA ORIGEM
   -- 7) EXCLUSIVAMENTE PELO CARGO EFETIVO

   IF ( pCCO.CdOpcaoRemuneracao NOT IN (4,7) OR
        (
          pCCO.CdOpcaoRemuneracao = 5 AND
          pFolha.CdAgrupamento = 134 -- Agrupamento Militar
        )
      ) THEN

      IF pCCO.CdOpcaoRemuneracao = 5 AND
         pFolha.CdAgrupamento = 134 THEN
         
        --Busca o agrupamento do orgao exercicio do CCO
        SELECT o.cdagrupamento
          INTO vCdAgrupamento
          FROM ecadorgao o
         WHERE o.cdorgao = pCCO.CdOrgaoExercicio;

      ELSE
        
         vCdAgrupamento := pFolha.CdAgrupamento;
         
      END IF;

     /* Busca o valor o valor na tabela de valores de CCO */
     vvlIntegral := PKGPAG_GERAL.FRetornaValorFixoCCO(pCCO.NuNivel,
                                                      pCCO.NuReferencia,
                                                      pCCO.CdRelacaoTrabalho,
                                                      vCdAgrupamento,
                                                      pFolha.CdOrgao,
                                                      pFolha.NuVersaoTabCCO,
                                                      pFolha.NuAnoReferencia,
                                                      pFolha.NuMesReferencia);


  -- SIG-7044 SUBSTITUICAO DE CARGO COMISSIONADO
  -- Trocar variavel para dados da rubrica alternativa para opcao de remuneracao com percentual
     IF pFolha.CdAgrupamento = 133 AND
        vRubrica.NuRubrica = 5 AND
        pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,1,16) = pEvento.CdRubAgrupAlternativa1 AND
        pCCO.CdOpcaoRemuneracao = 2 THEN

        vRubrica := pkgpag_var.vgRubrica(pEvento.CdRubAgrupAlternativa1);

     END IF;

     IF vvlIntegral IS NOT NULL THEN

       PKGPAG_VAR.vCdRelacaoTrabalhoCCO  := pCCO.CdRelacaoTrabalho;
       PKGPAG_VAR.vCdOpcaoRemuneracaoCCO := pCCO.CdOpcaoRemuneracao;

       /* Se a relacao de trabalho for de FTG ou Comissionado e a opcao de
          remuneracao e pela maior remuneracao, deve-se encontrar o maior
          valor entre as duas relacoes */
       IF pCCO.CdRelacaoTrabalho IN (6,9) AND pCCO.CdOpcaoRemuneracao = 1 THEN

         vvlIntegralOR := PKGPAG_GERAL.FRetornaValorFixoCCO(pCCO.NuReferencia,
                                                            pCCO.NuNivel,
                                                            CASE pCCO.CdRelacaoTrabalho
                                                              WHEN 6 THEN 
                                                                9
                                                              ELSE 
                                                                6
                                                            END,
                                                            pFolha.CdAgrupamento,
                                                            pFolha.CdOrgao,
                                                            pFolha.Nuversaotabfuc,
                                                            pFolha.NuAnoReferencia,
                                                            pFolha.NuMesReferencia);

         vvlIntegral := GREATEST(vvlIntegral, NVL(vvlIntegralOR,0));

      END IF;

      IF (pRubrica.FlPropAfaCCOSubst = 'S' AND prubrica.FlPagaSubstituicao = 'S') OR
         prubrica.FlPropMesComercial = 'S' AND 
         prubrica.FlPropAfaComissionado = 'S' THEN

         IF pcco.FlTipoProvimento <> 'S' THEN
           
            vRemun := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                             pRubrica       => vRubrica,
                                                             pCCO           => pCCO,
                                                             pValorIntegral => vvlIntegral,
                                                             pDtCalculo     => pDtCalculo);
         ELSE
              
            vRemun := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                             pRubrica       => vRubrica,
                                                             pCCOSubst      => pCCO,
                                                             pValorIntegral => vvlIntegral,
                                                             pDtCalculo     => pDtCalculo);
         END IF;
         
         vBOOLPropRub := FALSE;

      ELSE
         
          vRemun.vlProporcional := vvlIntegral;
          vRemun.vlIntegral := vvlIntegral;
          vRemun.vlReal := vvlIntegral;
          
      END IF;

      vCdRubricaAlternativa := pRubrica.CdRubricaAgrupamento;

      if pCCO.CdRelacaoTrabalho = 12 and pCCO.CdOpcaoRemuneracao = 2 then

          begin
             select pcc.cdrubricaagrupamento,
                    pcc.vlpercentual
               into vCdRubricaAlternativa,
                    vRubPercent.VlPercentual
               from epagagrupparamcargocom pcc
              where pcc.cdcargocomissionado = pCCO.CdCargoComissionado
                and pcc.cdagrupamentoparametro = pParamPagamento.Cdagrupamentoparametro;

          exception
             when others then

                vCdRubricaAlternativa := pRubrica.CdRubricaAgrupamento;

          end;

       end if;

       /* Se o tipo de relacao de trabalho e de CCO (comissionado ou agente politico)
         e opcao de remuneracao e opcao pelo cargo efetivo com percentual sobre o comissionado */

      IF pCCO.CdRelacaoTrabalho IN (4,6,13) AND
         (
            pCCO.CdOpcaoRemuneracao = 2
            OR
            (pCCO.CdOpcaoRemuneracao = 5 AND
              pFolha.CdAgrupamento = 134) -- Agrupamento Militar            
         ) THEN

        vvlIntegral := vRemun.vlProporcional;

        -- Verifica parametrizacao do agrupamento com relacao as carreiras para saber
        -- se deve ser aplicado um percentual especifico da carreira do CEF


        IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

          vRubPercent := FRetornaPercentualCCO(pCCO.CdCargoComissionado);

          IF vRubPercent.VlPercentual IS NOT NULL THEN

            vRemun.vlProporcional := PKGPAG_VAR.vgValorFixoCEF.VlFixo*vRubPercent.VlPercentual/100;

              vRemun := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                               pRubrica           => vRubrica,
                                                               pCCO               => pCCO,
                                                               pValorIntegral     => vRemun.vlProporcional,
                                                               pDtCalculo         => pDtCalculo);

          END IF;

        END IF;

        -- Caso nao encontre percentual parametrizado para a carreira do CEF,
        IF vRubPercent.VlPercentual IS NULL THEN

          IF FPossuiIncorporacao(pCCO.CdVinculo,
                                 pFolha.NuAnoReferencia,
                                 pFolha.NuMesReferencia,
                                 pParamPagamento.CdAgrupamentoParametro) THEN

             vRemun.vlProporcional := vvlIntegral*pParamPagamento.VlPagoCCOPossuiTpIncorp/100;
             vRemun.vlReal := vRemun.vlReal*pParamPagamento.VlPagoCCOPossuiTpIncorp/100;

          ELSE

             vRemun.vlProporcional := vvlIntegral*pParamPagamento.VlPagoCCONaoPossuiTpIncorp/100;
             vRemun.vlReal := vRemun.vlReal*pParamPagamento.VlPagoCCONaoPossuiTpIncorp/100;

          END IF;


          vRemun.vlIntegral := vRemun.vlProporcional;

        END IF;

        IF vRemun.VlProporcional > 0 THEN

          IF vRubPercent.CdRubricaAgrupamento IS NOT NULL THEN

            vRubrica.CdRubricaAgrupamento := vRubPercent.CdRubricaAgrupamento;

          ELSE

            vRubrica.CdRubricaAgrupamento := pEvento.CdRubAgrupAlternativa1;



          END IF;

          vRemun.vlProporcional := TRUNC(vRemun.vlProporcional,2);

          vRemun.vlReal         := TRUNC(vRemun.vlReal,2);

          vRemun.vlIntegral     := TRUNC(vRemun.vlIntegral,2);

          if not (PKGPAG_VAR.vgVlPercentReducao <> 0 and
            pRubrica.FlPercentReducaoAfastRemun = PKGPAG_TIPO.cnS) then

              vVlDiferenca := PKGPAG_GERAL.FArredondaVerifica(pVlTotal     => vRemun.vlReal,
                                                              pVlParcela   => vRemun.vlProporcional,
                                                              pVlVinculado => vRemun.vlIntegral,
                                                              pQtDias      => vRemun.vlIndice);



              vRemun.vlProporcional := vRemun.vlProporcional + vVlDiferenca;

              IF vVlDiferenca <> 0 AND PKGPAG_GERAL.FArredondaVinculado THEN

                 vRemun.vlIntegral := vRemun.vlIntegral + vVlDiferenca;

              END IF;

          end if;

          IF vBOOLPropRub AND pRubrica.FlPropServRelVinc = 'S' AND
             (pkgpag_var.vgNuDiasCCO > 0 or pkgpag_var.vgNuDiasSubst > 0) AND
             (pCCO.DtFim - pCCO.DtInicio + 1) < 30 AND vRubPercent.VlPercentual IS NULL THEN

             vRemun := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                              pRubrica       => vRubrica,
                                                              pCCO           => pCCO,
                                                              pValorIntegral => vRemun.vlProporcional,
                                                              pDtCalculo     => pDtCalculo);

          END IF;

          PKGPAG_GERAL.PAtualizaHistCCO(pFolha,
                                        vRubrica,
                                        pCCO,
                                        vRemun.vlIntegral,
                                        vRemun.vlProporcional,
                                        vRemun.vlReal,
                                        vRemun.vlIndice);

        END IF;

      ELSIF pCCO.CdRelacaoTrabalho = 12 AND pCCO.CdOpcaoRemuneracao = 2 AND vCdRubricaAlternativa <> pRubrica.CdRubricaAgrupamento THEN
       --
          --  SIG-2237  SEA - 14004/2019 - FG com pagamento em percentual

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => pFormExpr,
                                                                         pCdRubricaAgrupamento     => vCdRubricaAlternativa,
                                                                         pCdRelacaoVinculo         => 2,
                                                                         pCdUnidadeOrganizacional  => pCCO.CdUnidadeOrganizacional);

          delete epaghistoricorubricavinculo hrv
           where hrv.cdvinculo = pCCO.CdVinculo
             and hrv.cdrubricaagrupamento = pEvento.CdRubricaAgrupamento
             and hrv.cdfolhapagamento = pFolha.CdFolhaPagamento;

          delete epaghistoricorubricarelvinc hr
           where hr.cdvinculo = pCCO.CdVinculo
             and hr.cdrubricaagrupamento = pEvento.CdRubricaAgrupamento
             and hr.cdfolhapagamento = pFolha.CdFolhaPagamento;

          IF vCdExpressaoFormCalc > 0 THEN

             PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                   pCdVinculo            => pCCO.CdVinculo,
                                                   pCdRelacaoVinculo     => 2,
                                                   pCdHistRelacaoVinculo => pCCO.CdHistCargoCom,
                                                   pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                   pCdRubricaAgrupamento => vCdRubricaAlternativa,
                                                   pVlIntegral           => NULL,
                                                   pVlProporcional       => NULL,
                                                   pNuSufixoRubrica      => 1,
                                                   pNuParcelas           => 1,
                                                   pCdTipoOrigemRubrica  => 7,
                                                   pDtInicio             => pCCO.DtInicio,
                                                   pDtFim                => pCCO.DtFim,
                                                   pVlIndiceReal         => vRubPercent.VlPercentual,
                                                   pvlindice             => vRubPercent.VlPercentual);
           END IF;

      ELSE

        IF pCCO.FlPagaSubsidio = PKGPAG_TIPO.cnS AND pEvento.CdRubAgrupAlternativa2 IS NOT NULL THEN

            vRubrica.CdRubricaAgrupamento := pEvento.CdRubAgrupAlternativa2;

        END IF;

        IF (pCCO.CdOpcaoRemuneracao = 3 AND pFolha.CdAgrupamento = 176) AND /* opcao de remuneracao pelo CCO para DPE*/              
            vBOOLPropRub AND
            pRubrica.FlPropMesComercial = 'S' AND
            pRubrica.FlPropServRelVinc = 'S' AND 
            pkgpag_var.vgNuDiasCCO > 0 AND
           (pCCO.DtFim - pCCO.DtInicio + 1) < 30 AND 
            vRubPercent.VlPercentual IS NULL THEN

            vRemun := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha          => pFolha,
                                                             pRubrica        => vRubrica,
                                                             pCCO            => pCCO,
                                                             pValorIntegral  => vRemun.vlProporcional,
                                                             pDtCalculo      => pDtCalculo);-- Agrupamento DPE

        END IF;

        vRemun.vlProporcional := TRUNC(vRemun.vlProporcional,2);

        vRemun.vlReal         := TRUNC(vRemun.vlReal,2);

        vRemun.vlIntegral     := TRUNC(vRemun.vlIntegral,2);

        if not (PKGPAG_VAR.vgVlPercentReducao <> 0 and pRubrica.FlPercentReducaoAfastRemun = PKGPAG_TIPO.cnS) then

            vVlDiferenca := PKGPAG_GERAL.FArredondaVerifica(pVlTotal     => vRemun.vlReal,
                                                            pVlParcela   => vRemun.vlProporcional,
                                                            pVlVinculado => vRemun.vlIntegral,
                                                            pQtDias      => vRemun.vlIndice);

            vRemun.vlProporcional := vRemun.vlProporcional + vVlDiferenca;

            IF vVlDiferenca <> 0 AND PKGPAG_GERAL.FArredondaVinculado THEN

               vRemun.vlIntegral := vRemun.vlIntegral + vVlDiferenca;

            END IF;

        end if;

        PKGPAG_GERAL.PAtualizaHistCCO(pFolha,
                                      vRubrica,
                                      pCCO,
                                      vRemun.vlIntegral,
                                      vRemun.vlProporcional,
                                      vRemun.vlReal,
                                      vRemun.vlIndice);
      END IF;

    END IF;

  END IF;

END;

/*----------------------------------------------------------------------------------------------*/
-- Procedure: P005GratificacaoProd
--
--  Objetivo:
--  Beneficio Pecuniario
--
/*---------------------------------------------------------------------------------------------*/

FUNCTION FPossuiIndiceUnidEscolar(pCdVinculo IN INTEGER,
                                                     pCdOrgao IN INTEGER,
                                                     pDtCalculo IN DATE,
                                                     pDtInicioMes IN DATE)

  RETURN BOOLEAN IS

  vlIndiceUnidEscolar CHAR;

BEGIN

      SELECT flescola
            INTO vlIndiceUnidEscolar
          FROM (
                     SELECT tuo.flescola FROM ecadlocaltrabalho lt
                        INNER JOIN ecadhistunidadeorganizacional huo
                              ON lt.cdunidadeorganizacional = huo.cdunidadeorganizacional
                        LEFT JOIN ecadtipounidorg tuo
                              ON huo.cdtipounidorg = tuo.cdtipounidorg
                      WHERE lt.cdvinculo = pCdVinculo
                            AND huo.cdorgao = pCdOrgao
                      ORDER BY tuo.flescola, lt.dtinicio DESC)
       WHERE ROWNUM = 1;

     IF vlIndiceUnidEscolar = 'S' THEN
        RETURN TRUE;
     ELSE
          RETURN FALSE;
     END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

END;

FUNCTION FAplicarAbrangenciaParcialCCO(pFolha               IN PKGPAG_TIPO.rFolha,
                                       pcdrubricaagrupamento IN INTEGER)

  RETURN BOOLEAN IS

   vAplicaAbrangenciaParcialCCO CHAR(1);

BEGIN

    SELECT flaplicaabrangenciaparcialcco
    INTO vAplicaAbrangenciaParcialCCO
   FROM(SELECT  HAF.flaplicaabrangenciaparcialcco
  FROM epaghisteventopagagrup hea
  INNER JOIN epageventopagagrup ea
   ON ea.cdeventopagagrup = hea.cdeventopagagrup
  INNER JOIN epagtipogratativfazendaria tgra
   ON tgra.cdtipogratativfazendaria = hea.cdtipogratativfazendaria
  INNER JOIN epaggratativfazendaria gf
   ON gf.cdtipogratativfazendaria = tgra.cdtipogratativfazendaria
       INNER JOIN EpagHistGratAtivFazendaria HAF
   ON HAF.cdgratativfazendaria = gf.cdgratativfazendaria
  WHERE ea.cdrubricaagrupamento = pcdrubricaagrupamento
   AND ((HAF.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
              (HAF.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
              HAF.NuMesInicioVigencia <= pFolha.NuMesReferencia))
     AND
              (HAF.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
              (HAF.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
              HAF.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
              HAF.NuMesFimVigencia IS NULL))
ORDER BY HAF.Nuanoiniciovigencia DESC, HAF.Numesiniciovigencia DESC)
WHERE ROWNUM = 1;

     IF vAplicaAbrangenciaParcialCCO = 'S' THEN
        RETURN TRUE;
     ELSE
          RETURN FALSE;
     END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

END;

FUNCTION FPossuiGratProdutCEF(pCdVinculo INTEGER,
                              pCdRubrica INTEGER,
                              pCdFolhaPagamento INTEGER)
  RETURN BOOLEAN IS

    vVlGratifProdutividCEF NUMBER(13,2);

BEGIN

 SELECT rv.vlintegral
              INTO vVlGratifProdutividCEF
              FROM EPagHistoricoRubricaRelVinc rv
  WHERE rv.cdvinculo = pCdVinculo
    AND rv.cdrubricaagrupamento = pCdRubrica -- 45911 - 01-0576
    AND rv.cdfolhapagamento = pCdFolhaPagamento
    AND rv.cdhistcargoefetivo is not null;

  IF vVlGratifProdutividCEF > 0 THEN
        RETURN TRUE;
   ELSE
        RETURN FALSE;

  END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN
    RETURN FALSE;

END;

PROCEDURE P005GratificacaoProd(pFolha               IN PKGPAG_TIPO.rFolha,
                               pRubrica             IN PKGPAG_TIPO.rRubrica,
                               pCdTipoAtipratFaz    IN INTEGER,
                               pCEF                 IN PKGPAG_TIPO.rCEF DEFAULT NULL,
                               pAPO                 IN PKGPAG_TIPO.rCEF DEFAULT NULL,
                               pCCO                 IN PKGPAG_TIPO.rCCO DEFAULT NULL,
                               pCCOSubst          IN PKGPAG_TIPO.rCCO DEFAULT NULL,
                               pCdEstruturaCarreira IN INTEGER          DEFAULT NULL,
                               pDtCalculo           IN DATE) IS

  vValorFixo                         PKGPAG_TIPO.rValorFixo;
  vProporcional                   PKGPAG_TIPO.rValorPagamento;
  vNuValorCCOSubst                    NUMBER(13,2);
  vValorIntegral                    NUMBER(13,2);
  vVlIndiceunidescolar         NUMBER(7,4) DEFAULT NULL;
  vNuValorCCO                           NUMBER(13,2):= 0;
  vVlIndiceCCO                           NUMBER(7,4) DEFAULT NULL;
  bPermiteGratProdCCOSubst BOOLEAN;
  bPermiteGratProdCCO BOOLEAN DEFAULT FALSE;
  bPossuiCargoEfetivo BOOLEAN;
  bAplicarAbrangenciaParcialCCO BOOLEAN;
  bPossuiGratProdutividadeCEF BOOLEAN;

  FUNCTION FRetornaValorFixoGrat(pCdVinculo             IN INTEGER,
                                 pCdEstruturaCarreira   IN INTEGER,
                                 pNuNivelPagamento      IN VARCHAR2,
                                 pNuReferenciaPagamento IN VARCHAR2,
                                 pCdTipoAtipratFaz     IN INTEGER)

    RETURN PKGPAG_TIPO.rValorFixo IS

    vCdValorGeralCEFAGrup        INTEGER;
    vCdHistValorGeralCEFAGrup    INTEGER;
    vCdRubricaAgrupamento        INTEGER;
    vVlFixoCEF                   NUMBER(13,2);
    vCdValorGeralCEFAgrupLimite  INTEGER;
    vFlAplicaPercentSobreRubrica CHAR(1);
    vVlRubricaAgrupamento        NUMBER(13,2); -- Valor da rubrica
    vVlFixoCEFLimite             NUMBER(13,2);

  BEGIN

    SELECT CdValorGeralCEFAGrup,
           VlIndice,
           CdRubricaAgrupamento,
           VlFixoCEF,
           Vlindiceunidescolar,
           CdValorGeralCEFAgrupLimite,
           FlAplicaPercentSobreRubrica
      INTO vCdValorGeralCEFAGrup,
           vVlIndiceCCO,
           vCdRubricaAgrupamento,
           vVlFixoCEF,
           vVlIndiceunidescolar,
           vCdValorGeralCEFAgrupLimite,
           vFlAplicaPercentSobreRubrica
      FROM ( SELECT VS.CdValorGeralCEFAGrup,
                    HAF.VlIndice,
                    HAF.CdRubricaAgrupamento,
                    HAF.VlFixoCEF,
                    HAF.Vlindiceunidescolar,
                    NVL(VS.CdValorGeralCEFAgrupLimite,HAF.CdValorGeralCEFAgrupLimite) AS CdValorGeralCEFAgrupLimite,
                    HAF.FlAplicaPercentSobreRubrica,
                    Nivel
               FROM EPagGratAtivFazendaria AF
              INNER JOIN EpagHistGratAtivFazendaria HAF
                 ON AF.CdGratAtivFazendaria = HAF.CdGratAtivFazendaria
              INNER JOIN Epaghistgratativfazendvalsal VS
                 ON HAF.CdHistAtivFazendaria = VS.CdHistAtivFazendaria
              INNER JOIN (SELECT CdEstruturaCarreira,
                                 LEVEL AS Nivel
                            FROM ECadEstruturaCarreira C
                         CONNECT BY PRIOR C.CdEstruturaCarreiraPai = C.CdEstruturaCarreira
                           START WITH C.CdEstruturaCarreira = pCdEstruturaCarreira) ES
                 ON ES.CdEstruturaCarreira = VS.CdEstruturaCarreira OR
                    VS.CdEstruturaCarreira IS NULL
              WHERE AF.CdAgrupamento = pFolha.CdAgrupamento AND
                    AF.CdTipoGratAtivFazendaria = pCdTipoAtipratFaz AND
                    ((HAF.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                    (HAF.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                    HAF.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                    AND
                    (HAF.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                    (HAF.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                    HAF.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                    HAF.NuMesFimVigencia IS NULL))
              ORDER BY Nivel)
      WHERE ROWNUM = 1;

       -- Caso a rubrica esteja lancada em financeiro
       IF PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubricaAgrupamento) AND vFlAplicaPercentSobreRubrica = PKGPAG_TIPO.cnN THEN

         vValorFixo.VlFixo := NVL(vVlFixoCEF,0);

         vValorFixo.NuCargaHoraria := PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria;

         vValorFixo.vlFixo := vValorFixo.vlFixo*vVlIndiceCCO/100;

         RETURN  vValorFixo;

       ELSE

         vVlRubricaAgrupamento := 0;

         IF PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubricaAgrupamento) AND vFlAplicaPercentSobreRubrica = PKGPAG_TIPO.cnS  THEN

           BEGIN

             select LF.VlLancamentoFinanceiro
               into vVlRubricaAgrupamento
               from Epaglancamentofinanceiro LF
              where LF.CdVinculo = pCdVinculo
                and LF.CdRubricaAgrupamento = vCdRubricaAgrupamento
                and LF.DtInicioDireito <= pFolha.DtFimMes
                and (LF.DtFimDireito >= pFolha.DtInicioMes or LF.DtFimDireito is null)
                and LF.VlLancamentoFinanceiro is not null
                and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                                  from vpagrubricaagrupamento ra
                                                 where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                                   and ra.flsuspensa = PKGPAG_TIPO.cnN)
                and ROWNUM < 2;

           EXCEPTION

             WHEN NO_DATA_FOUND THEN

               vVlRubricaAgrupamento := 0;

           END;

         END IF;

         vCdHistValorGeralCEFAGrup := PKGPAG_GERAL.FTabelaValorGeral(vCdValorGeralCEFAGrup,
                                                                     pFolha.NuVersaoTabCEF,
                                                                     pFolha.NuAnoReferencia,
                                                                     pFolha.NuMesReferencia);

         SELECT pCdEstruturaCarreira,
                V.nuNivel,
                V.nuReferencia,
                (V.vlFixo + vVlRubricaAgrupamento)*vVlIndiceCCO/100,
                PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                V.DtUltAlteracao,
                0
           INTO vValorFixo
           FROM EPagValorEspecCEFAgrup V
          WHERE V.CdHistValorGeralCEFAgrup = vCdHistValorGeralCEFAGrup AND
                V.NuNivel = pNuNivelPagamento AND
                V.NuReferencia = pNuReferenciaPagamento;

         -- Caso a tabela limitadora seja informada

         IF vCdValorGeralCEFAgrupLimite IS NOT NULL THEN   -- LIMITE ESPECIFICO/GERAL

            -- Busca a tabela geral limitadora

            vCdHistValorGeralCEFAGrup := PKGPAG_GERAL.FTabelaValorGeral(vCdValorGeralCEFAgrupLimite,
                                                                        pFolha.NuVersaoTabCEF,
                                                                        pFolha.NuAnoReferencia,
                                                                        pFolha.NuMesReferencia);
            BEGIN

              SELECT V.vlFixo
                INTO vVlFixoCEFLimite
                FROM EPagValorEspecCEFAgrup V
               WHERE V.CdHistValorGeralCEFAgrup = vCdHistValorGeralCEFAGrup AND
                     V.NuNivel = pNuNivelPagamento AND
                     V.NuReferencia = pNuReferenciaPagamento;

              IF NVL(vVlFixoCEFLimite, 0) > 0 AND vVlFixoCEFLimite < vValorFixo.VlFixo THEN

                vValorFixo.vlFixo := vVlFixoCEFLimite;

              END IF ;

           EXCEPTION

             WHEN NO_DATA_FOUND THEN

               RETURN vValorFixo;

           END;

         END IF;

         RETURN vValorFixo;

       END IF;

     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         vValorFixo.VlFixo := NULL;

         RETURN vValorFixo;

    END;

BEGIN

  IF pCEF.CdHistRelVinc IS NOT NULL THEN

  IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                 pRubrica                  => pRubrica,
                                 pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                 pCdOrgaoExercicio         => pCEF.CdOrgaoExercicio,
                                 pCdNaturezaVinculo        => pCEF.CdNaturezaVinculo,
                                 pCdRelacaoTrabalho        => pCEF.CdRelacaoTrabalho,
                                 pCdRegimeTrabalho         => pCEF.CdRegimeTrabalho,
                                 pCdRegimePrevidenciario   => pCEF.CdRegimePrevidenciario,
                                 pCdSituacaoPrevidenciaria => pCEF.CdSituacaoPrevidenciaria,
                                 pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional,
                                 pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                 pFlTipoProvimento         => pCEF.FlEfetivacao,
                                 pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                 pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao,
                                 pFlExercicioOrigem        => pCEF.FlExercicioOrigem) THEN

       vValorFixo :=  FRetornaValorFixoGrat(pCEF.CdVinculo,
                                            pCEF.CdEstruturaCarreira,
                                            pCEF.NuNivelPagamento,
                                            pCEF.NuReferenciaPagamento,
                                            pCdTipoAtipratFaz);

      IF (vValorFixo.vlFixo IS NOT NULL) THEN

         vValorIntegral := vValorFixo.vlFixo;

         vProporcional :=

           PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                  pRubrica           => pRubrica ,
                                                  pValorIntegral     => vValorIntegral,
                                                  pNuCHO             => vValorFixo.NuCargaHoraria,
                                                  pCEF               => pCEF,
                                                  pDtCalculo         => pDtCalculo);

         PKGPAG_GERAL.PAtualizaHistCEF(pFolha               => pFolha,
                                       pRubrica             => pRubrica,
                                       pCEF                 => pCEF,
                                       pValorIntegral       => vProporcional.vlIntegral,
                                       pValorProporcional   => vProporcional.vlProporcional,
                                       pValorReal           => vProporcional.vlReal,
                                       pValorIndice         => CASE vProporcional.vlProporcional
                                                                 WHEN 0 THEN 0
                                                               ELSE vVlIndiceCCO
                                                               END,
                                       pCdTipoOrigemRubrica => 7);

      END IF;

    END IF;

  ELSIF pAPO.CdHistRelVinc IS NOT NULL THEN

    IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                 pRubrica                  => pRubrica,
                                 pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                 pCdOrgaoExercicio         => pAPO.CdOrgaoExercicio,
                                 pCdSituacaoPrevidenciaria => pAPO.CdSituacaoPrevidenciaria,
                                 pCdEstruturaCarreira      => pAPO.CdEstruturaCarreira,
                                 pFlAPOOrigemCCO           => pAPO.FlOrigemCCO) THEN

       vValorFixo :=  FRetornaValorFixoGrat(pAPO.CdVinculo,
                                            pAPO.CdEstruturaCarreira,
                                            pAPO.NuNivelPagamento,
                                            pAPO.NuReferenciaPagamento,
                                            pCdTipoAtipratFaz);

       IF vValorFixo.vlFixo IS NOT NULL THEN

         vValorIntegral := vValorFixo.vlFixo;

         vProporcional :=

           PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                  pAPO               => pAPO,
                                                  pRubrica           => pRubrica,
                                                  pValorIntegral     => vValorIntegral);

         PKGPAG_GERAL.PAtualizaHistAPO(pFolha             => pFolha,
                                       pRubrica           => pRubrica,
                                       pAPO               => pAPO,
                                       pValorIntegral     => vProporcional.vlIntegral,
                                       pValorProporcional => vProporcional.vlProporcional,
                                       pValorReal         => vProporcional.vlReal,
                                       pValorIndice       => CASE vProporcional.vlProporcional
                                                               WHEN 0 THEN 0
                                                             ELSE vVlIndiceCCO
                                                             END,
                                       pCdTipoOrigemRubrica => 7);

     END IF;

   END IF;

  ELSIF pCCO.CdHistCargoCom IS NOT NULL THEN

      -- Inicia a vari?vel permitindo a gera??o da gratifica??o de produtividade
      bPermiteGratProdCCO := TRUE;

      -- Caso a produtividade n?o tenha sido gerada no cargo efetivo, a mesma somente dever? ser gerada no cargo comissionado
      -- se o ?rg?o de exerc?cio do pr?prio cargo em comiss?o der direito ? rubrica, conforme parametriza??o abaixo, n?o havendo neste caso,
      -- necessidade de se verificar se lotado e/ou em exerc?cio, pois o comissionado sempre est? em ambas as situa??es.
      IF PKGPAG_VAR.vgCEF.count > 0 -- Possui cargo efetivo
          AND FAplicarAbrangenciaParcialCCO(pFolha => pFolha,
                                       pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento) = TRUE
          AND  FPossuiGratProdutCEF( PKGPAG_VAR.vgCEF(1).CdVinculo,
                                    pRubrica.CdRubricaAgrupamento,
                                    pFolha.CdFolhaPagamento) = FALSE
          AND NOT prubrica.lsorgao.exists(pCCO.cdorgaoexercicio) THEN

            bPermiteGratProdCCO := FALSE;

     END IF;

     IF bPermiteGratProdCCO = TRUE THEN

       IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => CASE PKGPAG_VAR.bTemEfetivoAnyOrgao
                                                                  WHEN FALSE THEN
                                                                    pCCO.CdOrgaoExercicio
                                                                ELSE
                                                                  PKGPAG_VAR.vgCdOrgaoVinculo
                                                                END,
                                   pCdOrgaoExercicio         => pCCO.CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => pCCO.CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => pCCO.CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => pCCO.CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => pCCO.CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => pCCO.CdSituacaoPrevidenciaria,
                                   pCdCargoComissionado      => pCCO.CdCargoComissionado,
                                   pCdGrupoOcupacional       => pCCO.CdGrupoOcupacional,
                                   pCdUnidadeOrganizacional  => pCCO.CdUnidadeOrganizacional,
                                   pCdEstruturaCarreira      => pCdEstruturaCarreira,
                                   pCdOpcaoRemuneracao       => pCCO.CdOpcaoRemuneracao,
                                   pFlTipoProvimento         => pCCO.FlTipoProvimento)
                                  THEN

         BEGIN
         -- As nomenclaturas dos campos DeNivel e DeCodigo da tabela de valores com
         -- os campos NuNivel e NuReferencia so geram confusao e dificuldade de entendimento.
         -- A epoca que foi solicitada a alteracao dos nomes para manter um padrao, porem foi negado,
         -- com a desculpa de que muita coisa ja estava implementada.

         SELECT NuValor,
                         VlIndice,
                         Vlindiceunidescolar
               INTO vNuValorCCO,
                         vVlIndiceCCO,
                         vVlIndiceunidescolar
             FROM (SELECT NuValor,
                          VlIndice,
                          Vlindiceunidescolar
                     FROM (SELECT VV.NuValor,
                                  HAF.VlIndice,
                                  HAF.Vlindiceunidescolar,
                                  CASE
                                    WHEN VV.DeNivel = pCCO.NuReferencia AND
                                         VV.DeCodigo = pCCO.NuNivel THEN
                                      1
                                    WHEN VV.CdGrupoOcupacional = pCCO.CdGrupoOcupacional AND
                                         VV.CdCargoComissionado = pCCO.CdCargoComissionado THEN
                                      2
                                    WHEN VV.CdGrupoOcupacional = pCCO.CdGrupoOcupacional AND
                                         VV.CdCargoComissionado IS NULL THEN
                                      3
                                  END AS NIVEL
                             FROM EpagGratAtivFazendaria AF
                            INNER JOIN EpagHistGratAtivFazendaria HAF
                               ON AF.CdGratAtivFazendaria = HAF.CdGratAtivFazendaria
                            INNER JOIN EPagHistGratAtivfazendvalvenc VV
                               ON HAF.CdHistAtivFazendaria = VV.CdHistAtivFazendaria
                            WHERE AF.CdAgrupamento = pFolha.CdAgrupamento AND
                                  AF.CdTipoGratAtivFazendaria = pCdTipoAtipratFaz AND
                                  (VV.CdCargoComissionado = pCCO.CdCargoComissionado OR
                                   (VV.CdGrupoOcupacional = pCCO.CdGrupoOcupacional AND
                                    VV.CdCargoComissionado IS NULL) OR
                                  (VV.DeNivel = pCCO.NuReferencia AND VV.DeCodigo = pCCO.NuNivel)) AND
                                  ((HAF.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                                  (HAF.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                                  HAF.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                                  AND
                                  (HAF.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                                  (HAF.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                                  HAF.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                                  HAF.NuMesFimVigencia IS NULL))
                               ) ORDER BY NIVEL)
                            WHERE ROWNUM < 2;
             EXCEPTION

                        WHEN NO_DATA_FOUND THEN

                          vNuValorCCO := NULL;

              END;

              IF vNuValorCCO IS NOT NULL THEN

              vValorIntegral := vNuValorCCO*vVlIndiceCCO/100;

              IF pRubrica.FlPropAfaCCOSubst = 'S'
                THEN
                vProporcional :=
                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pCCO               => pCCO,
                                                         pValorIntegral     => vValorIntegral,
                                                         pDtCalculo         => pDtCalculo);
              ELSE
                vProporcional.vlProporcional := vValorIntegral;
                vProporcional.vlIntegral := vValorIntegral;
                vProporcional.vlReal := vValorIntegral;
              END IF;

               --se houver uma subst no mês inteiro, não paga pelo cco.
              IF (pRubrica.nurubrica = 319 AND
                  (pkgpag_var.vgCCOSubst.count > 0 AND pkgpag_var.vgnudiassubst < 30))
                OR pRubrica.nurubrica <> 319
                OR pkgpag_var.vgCCOSubst.count = 0
                THEN

                PKGPAG_GERAL.PAtualizaHistCCO(pFolha             => pFolha,
                                              pRubrica           => pRubrica,
                                              pCCO               => pCCO,
                                              pValorIntegral     => vProporcional.vlIntegral,
                                              pValorProporcional => vProporcional.vlProporcional,
                                              pValorReal         => vProporcional.vlReal,
                                              pValorIndice       => CASE vValorIntegral
                                                                            WHEN 0 THEN 0
                                                                          ELSE vVlIndiceCCO
                                                                          END,
                                              pCdExpressaoFormula  => NULL,
                                              pCdTipoOrigemRubrica => 7);
           END IF;

         END IF;

       END IF;

  ELSE
      bPermiteGratProdCCO := FALSE;

  END IF;

  ELSIF pCCOSubst.CdHistCargoCom IS NOT NULL THEN

      -- Inicia a vari?vel permitindo a gera??o da gratifica??o de produtividade
      bPermiteGratProdCCOSubst := TRUE;

      bPossuiCargoEfetivo := PKGPAG_VAR.vgCEF.count > 0;
      bAplicarAbrangenciaParcialCCO := FAplicarAbrangenciaParcialCCO(pFolha => pFolha,
                                                                     pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento);

      bPossuiGratProdutividadeCEF := FALSE;

      IF (PKGPAG_VAR.vgCEF.COUNT > 0) THEN
        bPossuiGratProdutividadeCEF := FPossuiGratProdutCEF( PKGPAG_VAR.vgCEF(1).CdVinculo,
                                       pRubrica.CdRubricaAgrupamento,
                                       pFolha.CdFolhaPagamento);
      END IF;

      -- Caso a produtividade n?o tenha sido gerada no cargo efetivo, a mesma somente dever? ser gerada no cargo comissionado
      -- se o ?rg?o de exerc?cio do pr?prio cargo em comiss?o der direito ? rubrica, conforme parametriza??o abaixo, n?o havendo neste caso,
      -- necessidade de se verificar se lotado e/ou em exerc?cio, pois o comissionado sempre est? em ambas as situa??es.
      IF bPossuiCargoEfetivo AND
         bAplicarAbrangenciaParcialCCO AND
         NOT bPossuiGratProdutividadeCEF AND
         NOT prubrica.lsorgao.exists(pCCOSubst.cdorgaoexercicio) THEN
            bPermiteGratProdCCOSubst := FALSE;

     END IF;

  IF bPermiteGratProdCCOSubst = TRUE THEN

       IF (pkgpag_var.vgCCO.count > 0 AND  bPermiteGratProdCCO = TRUE)
         OR PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => CASE PKGPAG_VAR.bTemEfetivoAnyOrgao
                                                                  WHEN FALSE THEN
                                                                    pCCOSubst.CdOrgaoExercicio
                                                                ELSE
                                                                  PKGPAG_VAR.vgCdOrgaoVinculo
                                                                END,
                                   pCdOrgaoExercicio         => pCCOSubst.CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => pCCOSubst.CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => pCCOSubst.CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => pCCOSubst.CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => pCCOSubst.CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => pCCOSubst.CdSituacaoPrevidenciaria,
                                   pCdCargoComissionado      => pCCOSubst.CdCargoComissionado,
                                   pCdGrupoOcupacional       => pCCOSubst.CdGrupoOcupacional,
                                   pCdUnidadeOrganizacional  => pCCOSubst.CdUnidadeOrganizacional,
                                   pCdEstruturaCarreira      => pCdEstruturaCarreira,
                                   pCdOpcaoRemuneracao       => pCCOSubst.CdOpcaoRemuneracao,
                                   pFlTipoProvimento         => pCCOSubst.FlTipoProvimento)
                                  THEN

         BEGIN
         -- As nomenclaturas dos campos DeNivel e DeCodigo da tabela de valores com
         -- os campos NuNivel e NuReferencia so geram confusao e dificuldade de entendimento.
         -- A epoca que foi solicitada a alteracao dos nomes para manter um padrao, porem foi negado,
         -- com a desculpa de que muita coisa ja estava implementada.

         SELECT NuValor,
                         VlIndice,
                         Vlindiceunidescolar
               INTO vNuValorCCOSubst,
                         vVlIndiceCCO,
                         vVlIndiceunidescolar
             FROM (SELECT NuValor,
                          VlIndice,
                          Vlindiceunidescolar
                     FROM (SELECT VV.NuValor,
                                  HAF.VlIndice,
                                  HAF.Vlindiceunidescolar,
                                  CASE
                                    WHEN VV.DeNivel = pCCOSubst.NuReferencia AND
                                         VV.DeCodigo = pCCOSubst.NuNivel THEN
                                      1
                                    WHEN VV.CdGrupoOcupacional = pCCOSubst.CdGrupoOcupacional AND
                                         VV.CdCargoComissionado = pCCOSubst.CdCargoComissionado THEN
                                      2
                                    WHEN VV.CdGrupoOcupacional = pCCOSubst.CdGrupoOcupacional AND
                                         VV.CdCargoComissionado IS NULL THEN
                                      3
                                  END AS NIVEL
                             FROM EpagGratAtivFazendaria AF
                            INNER JOIN EpagHistGratAtivFazendaria HAF
                               ON AF.CdGratAtivFazendaria = HAF.CdGratAtivFazendaria
                            INNER JOIN EPagHistGratAtivfazendvalvenc VV
                               ON HAF.CdHistAtivFazendaria = VV.CdHistAtivFazendaria
                            WHERE AF.CdAgrupamento = pFolha.CdAgrupamento AND
                                  AF.CdTipoGratAtivFazendaria = pCdTipoAtipratFaz AND
                                  (VV.CdCargoComissionado = pCCOSubst.CdCargoComissionado OR
                                   (VV.CdGrupoOcupacional = pCCOSubst.CdGrupoOcupacional AND
                                    VV.CdCargoComissionado IS NULL) OR
                                  (VV.DeNivel = pCCOSubst.NuReferencia AND VV.DeCodigo = pCCOSubst.NuNivel)) AND
                                  ((HAF.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                                  (HAF.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                                  HAF.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                                  AND
                                  (HAF.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                                  (HAF.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                                  HAF.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                                  HAF.NuMesFimVigencia IS NULL))
                               ) ORDER BY NIVEL)
                            WHERE ROWNUM < 2;


                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                  vNuValorCCOSubst := NULL;

              END;

              IF vNuValorCCOSubst IS NOT NULL THEN

              vValorIntegral := vNuValorCCOSubst*vVlIndiceCCO/100;

              IF pRubrica.FlPropAfaCCOSubst = 'S'
                THEN
                vProporcional :=
                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pCCO               => pCCOSubst,
                                                         pValorIntegral     => vValorIntegral,
                                                         pDtCalculo         => pDtCalculo);
              ELSE
                vProporcional.vlProporcional := vValorIntegral;
                vProporcional.vlIntegral := vValorIntegral;
                vProporcional.vlReal := vValorIntegral;
              END IF;

              PKGPAG_GERAL.PAtualizaHistCCO(pFolha             => pFolha,
                                            pRubrica           => pRubrica,
                                            pCCO               => pCCOSubst,
                                            pValorIntegral     => vProporcional.VlProporcional,
                                            pValorProporcional => vProporcional.VlProporcional,
                                            pValorReal         => vProporcional.VlReal,
                                            pValorIndice       => CASE vProporcional.VlProporcional
                                                                    WHEN 0 THEN 0
                                                                  ELSE vVlIndiceCCO
                                                                  END,
                                            pCdExpressaoFormula  => NULL,
                                            pCdTipoOrigemRubrica => 7);
         END IF;

       END IF;

  END IF;

ELSE
  NULL;

END IF;

EXCEPTION

  WHEN OTHERS THEN

    vVlIndiceCCO := 0;

END;

/*-----------------------------------------------------------------------------------------/
--     Procedure : P012SubstituicaoCCO
--      Objetivo : Gerar a remuneracao fixa para a relacao de vinculo de cargo comissionado
--                 de substituicao
--
--         Nota :
/*-----------------------------------------------------------------------------------------*/

PROCEDURE P012SubstituicaoCCO(pFolha          IN PKGPAG_TIPO.rFolha,
                              pCCO            IN PKGPAG_TIPO.rCCO,
                              pCalculaSubst CHAR DEFAULT 'N',
                              pEvento         IN PKGPAG_TIPO.rEvento,
                              pRubrica        IN PKGPAG_TIPO.rRubrica,
                              pFormExpr       IN PKGPAG_TIPO.tFormulaCalculo,
                              pParamPagamento IN Epagagrupamentoparametro%ROWTYPE,
                              pDtCalculo      IN DATE) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;
  vvlIntegral          NUMBER(13,2);
  --vValorFixo         PKGPAG_TIPO.rValorPagamento;
  vRubrica             PKGPAG_TIPO.rRubrica;
  vCdExpressaoFormCalc INTEGER DEFAULT NULL;
  vVlProporcionalRubAlternativa  NUMBER := 0;

BEGIN

  IF pCCO.CdOpcaoRemuneracao= 2
    --PELO CARGO EFETIVO COM PERCENTUAL SOBRE O COMISSIONADO
    THEN

    /* Busca o valor o valor na tabela de valores de CCO */
    vvlIntegral := PKGPAG_GERAL.FRetornaValorFixoCCO(pCCO.NuNivel,
                                          pCCO.NuReferencia,
                                          pCCO.CdRelacaoTrabalho,
                                          pFolha.CdAgrupamento,
                                          pFolha.CdOrgao,
                                          pFolha.NuVersaoTabCCO,
                                          pFolha.NuAnoReferencia,
                                          pFolha.NuMesReferencia);

    IF vvlIntegral IS NOT NULL THEN

      PKGPAG_VAR.vCdRelacaoTrabalhoCCO    := pCCO.CdRelacaoTrabalho;

      PKGPAG_VAR.vCdOpcaoRemuneracaoCCO   := pCCO.CdOpcaoRemuneracao;

      IF pCalculaSubst = 'N'
        THEN
      vProporcional :=
           PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                  pRubrica           => pRubrica,
                                                  pCCO               => pCCO,
                                                  pValorIntegral     => vvlIntegral,
                                                  pDtCalculo         => pDtCalculo);
        ELSE
          vProporcional :=
           PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                  pRubrica           => pRubrica,
                                                  pCCOSubst               => pCCO,
                                                  pValorIntegral     => vvlIntegral,
                                                  pDtCalculo         => pDtCalculo);
         END IF;
      /*-----------------------------------------------------------------------------------------*/
      -- Se o tipo de relacao de trabalho e de CCO (comissionado ou agente politico
      --    e opcao de remuneracao e opcao pelo cargo efetivo com percentual sobre o comissionado
      /*-----------------------------------------------------------------------------------------*/

      -- vvlIntegral := vProporcional.vlProporcional;

      IF FPossuiIncorporacao(pCCO.CdVinculo,
                             pFolha.NuAnoReferencia,
                             pFolha.NuMesReferencia,
                             pParamPagamento.CdAgrupamentoParametro) THEN

        vProporcional.vlProporcional := vProporcional.vlIntegral*pParamPagamento.VlPagoCCOPossuiTpIncorp/100;

      ELSE

        vProporcional.vlProporcional := vProporcional.vlIntegral*pParamPagamento.VlPagoCCONaoPossuiTpIncorp/100;

      END IF;

      vVlProporcionalRubAlternativa := pkgpag_evccobol.FObterValorTotalProporcional(pCdVinculo => pCCO.CdVinculo,
                                                                                    pCdFolhapagamento => pFolha.CdFolhaPagamento,
                                                                                    pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa1,
                                                                                    pCdhistcargocom => pCCO.CdHistCargoCom,
                                                                                    pDtinicio => pCCO.DtInicioRelacao,
                                                                                    pDtfim => pCCO.DtFimRelacao);

     IF (vProporcional.VlProporcional > 0) AND (vVlProporcionalRubAlternativa=0) THEN

        vRubrica := pkgpag_var.vgRubrica(pEvento.CdRubAgrupAlternativa1);

        PKGPAG_GERAL.PAtualizaHistCCO(pFolha,
                                      vRubrica,
                                      pCCO,
                                      vProporcional.vlIntegral,
                                      vProporcional.vlProporcional,
                                      vProporcional.vlReal,
                                      vProporcional.vlIndice,
                                      NULL);

      END IF;

    END IF;

  ELSE

    vCdExpressaoFormCalc :=

       PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr  => pFormExpr,
                                 pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                 pCdRelacaoVinculo       => 2, -- Cargo Comissionado
                                 pCdCargoComissionado    => pCCO.CdCargoComissionado,
                                 pCdUnidadeOrganizacional=> pCCO.CdUnidadeOrganizacional);

    PKGPAG_GERAL.PAtualizaHistCCO(pFolha,
                                  pRubrica,
                                  pCCO,
                                  NULL,
                                  NULL,
                                  NULL,
                                  0,
                                  vCdExpressaoFormCalc);

  END IF;

END;

/*-----------------------------------------------------------------------------------------/
--     Procedure : P028RemuneracaoFixaBOL
--      Objetivo : Gerar a remuneracao para a relacao de vinculo de bolsista
--
/*-----------------------------------------------------------------------------------------*/

PROCEDURE P028RemuneracaoFixaBOL(pFolha              IN PKGPAG_TIPO.rFolha,
                                 pBOL                IN PKGPAG_TIPO.rBOL,
                                 pRubrica            IN PKGPAG_TIPO.rRubrica,
                                 pDtCalculo          IN DATE) IS

  --vNuDiasMes    INTEGER;
  vProporcional PKGPAG_TIPO.rValorPagamento;

BEGIN

  vProporcional:=

    PKGPAG_GERAL.FCalculaProporcionalidade(pFolha     => pFolha,
                                           pRubrica   => pRubrica,
                                           pBOL       => pBOL,
                                           pDtCalculo => pDtCalculo);

 IF vProporcional.vlProporcional IS NULL THEN

   PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                           PKGPAG_VAR.vCdHistParamCalc,
                           PKGPAG_VAR.vCdPessoa,
                            'Não foi encontrado o valor de remuneração do bolsista. ' ||
                            'Rubrica ' || LPAD(pRubrica.CdTipoRubrica,'0',2) || '-' || LPAD(pRubrica.NuRubrica,'0',4) || ' não foi calculada.' ,
                           PKGPAG_VAR.vgCdVinculo);

  ELSE
    IF (vProporcional.vlIntegral IS NULL) THEN
      vProporcional.vlIntegral := vProporcional.vlReal;
    END IF;

    PKGPAG_GERAL.PAtualizaHistBOL(pFolha,
                                  pRubrica,
                                  pBOL,
                                  vProporcional.vlIntegral,
                                  vProporcional.vlProporcional,
                                  vProporcional.vlReal,
                                  vProporcional.vlIndice);
  END IF;

END;

PROCEDURE P032DescontoACM(pCdVinculo IN INTEGER,
                          pFolha     IN PKGPAG_TIPO.rFolha,
                          pRubrica   IN PKGPAG_TIPO.rRubrica,
                          pFormExpr  IN PKGPAG_TIPO.tFormulaCalculo) IS

  vCdExpressaoFormCalc INTEGER;

BEGIN

 FOR vBOL IN PKGPAG_VAR.cRelBOL(pCdVinculo,
                                pFolha.DtInicioMes,
                                pFolha.DtFimMes)
 LOOP

   IF (PKGPAG_VAR.vgRelVincPrincipal.CdHist = vBOL.CdHistEstagio) THEN

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
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
                                  pCdUnidadeOrganizacional  => vBOL.CdUnidadeOrganizacional);

         IF vCdExpressaoFormCalc > 0 THEN

           PKGPAG_GERAL.PInsereLancamentoRelacao(
                                    pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                    pCdVinculo              => pCdVinculo,
                                    pCdRelacaoVinculo       => vBOL.CdTipoRelacao,
                                    pCdHistRelacaoVinculo   => vBOL.CdHistEstagio,
                                    pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                    pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                    pVlIntegral             => NULL,
                                    pVlProporcional         => NULL,
                                    pNuSufixoRubrica        => 1,
                                    pNuParcelas             => 0,
                                    pVlIndice               => NULL,
                                    pDtDesligamento         => vBOL.DtDesligamento,
                                    pCdUnidadeOrganizacional=> vBOL.CdUnidadeOrganizacional,
                                    pCdTipoOrigemRubrica    => 1);

          END IF;

       END IF;

     END IF;

   END LOOP;

END;

PROCEDURE PProcessaEventosCCO (pVinculo             IN PKGPAG_TIPO.rVinculo,
                               pFolha               IN PKGPAG_TIPO.rFolha,
                               pEvento              IN PKGPAG_TIPO.rEvento,
                               pRubrica             IN PKGPAG_TIPO.tRubrica,
                               pFormExpr            IN PKGPAG_TIPO.tFormulaCalculo,
                               pParamPag            IN EPagAgrupamentoParametro%ROWTYPE,
                               pCCO                 IN PKGPAG_TIPO.tCCO,
                               pdtCalculo           IN DATE,
                               pCdEstruturaCarreira IN INTEGER) IS

  bEventoGerado         BOOLEAN;

BEGIN

  PKGPAG_GERAL.PArredondaInicializa;

  FOR j IN pCCO.FIRST .. pCCO.LAST
  LOOP

    bEventoGerado := FALSE;
    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;


      -- 004 - Remuneracao fixa de cargo comissionado
   CASE
      WHEN pEvento.CdTipoEventoPagamento = 4 THEN

          IF pEvento.CdRelacaoTrabalho =  pCCO(j).CdRelacaoTrabalho THEN

            bEventoGerado := TRUE;

            P004RemuneracaoFixaCCO(pFolha,
                                   pCCO(j),
                                   'N',
                                   pEvento,
                                   pRubrica(pEvento.CdRubricaAgrupamento),
                                   pParamPag,
                                   pDtCalculo,
                                   pFormExpr);

         END IF;

      -- 005 - Pagamento de gratificacao por referencia salarial

      WHEN pEvento.CdTipoEventoPagamento = 5 THEN

          bEventoGerado := TRUE;

          P005GratificacaoProd(pFolha              => pFolha,
                               pRubrica            => pRubrica(pEvento.CdRubricaAgrupamento),
                               pCdTipoAtipratFaz   => pEvento.CdTipoGratAtivFazendaria,
                               pCCO                => pCCO(j),
                               pCdEstruturaCarreira=> pCdEstruturaCarreira,
                               pDtCalculo          => pDtCalculo);

       -- 015 - Pagamento de indenizacao de estimulo operacional

      WHEN pEvento.CdTipoEventoPagamento = 15 THEN

        bEventoGerado := TRUE;

        P015a017e023RemunHoraExtra(pFolha                 => pFolha,
                                   pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                   pCCO                   => pCCO(j),
                                   pFormExpr              => pFormExpr,
                                   pCdTipoRegistroJornada => 4,
                                   pCdTipoRegistroEscala  => 3,
                                   pCdTpEscSobreAviso     => 7);

        -- Hora extra normal
      -- 017 - Pagamento de horas extras normais

      WHEN pEvento.CdTipoEventoPagamento = 17 THEN

        bEventoGerado := TRUE;

        P015a017e023RemunHoraExtra(pFolha                 => pFolha,
                                   pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                   pCCO                   => pCCO(j),
                                   pFormExpr              => pFormExpr,
                                   pCdTipoRegistroJornada => 5,
                                   pCdTipoRegistroEscala  => 4);

      -- Hora extra especial
      -- 023 - Pagamento de horas extras especiais

      WHEN pEvento.CdTipoEventoPagamento = 23 THEN

        bEventoGerado := TRUE;

        P015a017e023RemunHoraExtra(pFolha                 => pFolha,
                                   pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                   pCCO                   => pCCO(j),
                                   pFormExpr              => pFormExpr,
                                   pCdTipoRegistroJornada => 6,
                                   pCdTipoRegistroEscala  => 5);

        WHEN pEvento.CdTipoEventoPagamento = 92 THEN

        bEventoGerado := TRUE;

        PKGPAG_VAR.vgCdRubFeriasIndenizadasVinc := pEvento.CdRubricaAgrupamento;

        ELSE

          NULL;

    END CASE;

    IF bEventoGerado THEN

      PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Evento Gerado ' || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - CCO ' || j, PKGPAG_VAR.vgTmInicio);

    ELSE

      PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Evento Não Gerado '  || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - CCO ' || j, PKGPAG_VAR.vgTmInicio);

    END IF;

  END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

    PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'EVCCOBOL - Erro ao processar Evento (' || pEvento.CdTipoEventoPagamento || ') - ' || pEvento.DeEvento ,
                              PKGPAG_VAR.vgCdVinculo);

END;

PROCEDURE PProcessaEventosCCOSubst (pVinculo            IN PKGPAG_TIPO.rVinculo,
                                    pFolha              IN PKGPAG_TIPO.rFolha,
                                    pEvento             IN PKGPAG_TIPO.rEvento,
                                    pRubrica            IN PKGPAG_TIPO.tRubrica,
                                    pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                                    pParamPag           IN EPagAgrupamentoParametro%ROWTYPE,
                                    pCCOSubst           IN PKGPAG_TIPO.tCCO,
                                    pdtCalculo          IN DATE) IS

  bEventoGerado         BOOLEAN;

  vRubPercentCCO PKGPAG_TIPO.rRubPercent;

BEGIN

  IF PKGPAG_VAR.vPagaSitDisposicao = 'PAG-ORIGEM-CALCULO-DEST' THEN

    NULL;

  ELSE

    FOR j IN pCCOSubst.FIRST .. pCCOSubst.LAST
    LOOP

       bEventoGerado := FALSE;
       PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

      CASE

       --
       -- 004 - Remuneracao fixa de cargo comissionado
       -- Incluido para substitutos. Nao estava gerando rubrica 01-0279 para substitutos PGE
       --
        WHEN pEvento.CdTipoEventoPagamento = 4 THEN

          IF pEvento.CdRelacaoTrabalho =  pCCOSubst(j).CdRelacaoTrabalho THEN

            vRubPercentCCO := FRetornaPercentualCCO(pCCOSubst(j).CdCargoComissionado);

            -- Verifica se possui percentual CCO para a rubrica 01-0279
            --IF vRubPercentCCO.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 1, 279)  THEN

                bEventoGerado := TRUE;

                P004RemuneracaoFixaCCO(pFolha,
                                       pCCOSubst(j),
                                       'S',
                                       pEvento,
                                       pRubrica(pEvento.CdRubricaAgrupamento),
                                       pParamPag,
                                       pDtCalculo,
                                       pFormExpr);

            --END IF;

          END IF;

        -- 005 - Pagamento de gratificacao por referencia salarial

        WHEN pEvento.CdTipoEventoPagamento = 5 THEN

            bEventoGerado := TRUE;

            P005GratificacaoProd(pFolha              => pFolha,
                                 pRubrica            => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pCdTipoAtipratFaz   => pEvento.CdTipoGratAtivFazendaria,
                                 pCCOSubst                => pCCOSubst(j),
                                 pDtCalculo          => pDtCalculo);


        -- 012 - Remuneracao de substituicao de cargo comissionado
        WHEN pEvento.CdTipoEventoPagamento = 12 THEN

          IF pEvento.CdRelacaoTrabalho =  pCCOSubst(j).CdRelacaoTrabalho THEN

            bEventoGerado := TRUE;

            P012SubstituicaoCCO (pFolha,
                                 pCCOSubst(j),
                                 'S',
                                 pEvento,
                                 pRubrica(pEvento.CdRubricaAgrupamento),
                                 pFormExpr,
                                 pParamPag,
                                 pDtCalculo);
          END IF;

        ELSE

          NULL;

      END CASE;

      IF bEventoGerado THEN

        PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Evento Gerado ' || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - CCOSubst ' || j, PKGPAG_VAR.vgTmInicio);

      ELSE

        PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Evento Não Gerado '  || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - CCOSubst ' || j, PKGPAG_VAR.vgTmInicio);

      END IF;

    END LOOP;

  END IF;

  EXCEPTION

    WHEN OTHERS THEN

    PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'EVCCOBOL - Erro ao processar Evento (' || pEvento.CdTipoEventoPagamento || ') - ' || pEvento.DeEvento ,
                              PKGPAG_VAR.vgCdVinculo);

END;

PROCEDURE PProcessaEventosBOL (pVinculo            IN PKGPAG_TIPO.rVinculo,
                               pFolha              IN PKGPAG_TIPO.rFolha,
                               pEvento             IN PKGPAG_TIPO.rEvento,
                               pRubrica            IN PKGPAG_TIPO.tRubrica,
                               pFormExpr           IN PKGPAG_TIPO.tFormulaCalculo,
                               pBOL                IN PKGPAG_TIPO.tBOL,
                               pdtCalculo          IN DATE) IS

  bEventoGerado         BOOLEAN;

BEGIN

  FOR j IN pBOL.FIRST .. pBOL.LAST
  LOOP

    bEventoGerado := FALSE;
    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

    CASE

      -- 028 - Remuneracao fixa de bolsista

      WHEN pEvento.CdTipoEventoPagamento = 28 THEN

        IF pBOL(j).CdRelacaoTrabalho = pEvento.CdRelacaoTrabalho THEN

          bEventoGerado := TRUE;

          P028RemuneracaoFixaBOL (pFolha,
                                  pBOL(j),
                                  pRubrica(pEvento.CdRubricaAgrupamento),
                                  pDtCalculo);

        END IF;

      -- 032 - Desconto de Associacao Catarinense de Medicina- Bolsista

      WHEN pEvento.CdTipoEventoPagamento = 32 THEN

        bEventoGerado := TRUE;

        P032DescontoACM (pVinculo.CdVinculo,
                         pFolha,
                         pRubrica(pEvento.CdRubricaAgrupamento),
                         pFormExpr);

      ELSE
        NULL;
    END CASE;

    IF bEventoGerado THEN

      PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Evento Gerado ' || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - BOL ' || j, PKGPAG_VAR.vgTmInicio);

    ELSE

      PKGPAG_GERAL.PLogTrace ('EVVCOBOL - Evento Não Gerado '  || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - BOL ' || j, PKGPAG_VAR.vgTmInicio);

    END IF;

  END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

    PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'EVCCOBOL - Erro ao processar Evento (' || pEvento.CdTipoEventoPagamento || ') - ' || pEvento.DeEvento ,
                              PKGPAG_VAR.vgCdVinculo);

END;

FUNCTION FObterValorTotalProporcional(pCdvinculo            IN INTEGER,
                                      pCdfolhapagamento     IN INTEGER,
                                      pCdrubricaagrupamento IN INTEGER,
                                      pCdhistcargocom       IN INTEGER,
                                      pDtinicio             IN DATE,
                                      pDtfim                IN DATE) RETURN NUMBER IS
  vValorTotal number;
BEGIN

  select sum(hrv.vlproporcional)
    into vValorTotal
    from epaghistoricorubricarelvinc hrv
   inner join ecadhistcargocom hcco
      on hrv.cdhistcargocom = hcco.cdhistcargocom
   where hrv.cdfolhapagamento = pCdfolhapagamento
     and hrv.cdvinculo = pCdvinculo
     and hrv.cdrubricaagrupamento = pCdrubricaagrupamento
     and hcco.cdhistcargocom = pCdhistcargocom
     and hcco.dtinicio = pDtinicio
     and hcco.dtfim = pDtfim;

  RETURN vValorTotal;
END;


END PKGPAG_EVCCOBOL;
/
