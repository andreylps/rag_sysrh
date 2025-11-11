CREATE OR REPLACE PACKAGE PKGPAG_POS IS

 PROCEDURE PAtualizaEventoVinculo(pFolha                IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo            IN INTEGER,
                                  pCdTipoEvento         IN INTEGER,
                                  pCdChave              IN INTEGER DEFAULT NULL,
                                  pCdRubrica            IN INTEGER DEFAULT NULL,
                                  pVlIndice             IN INTEGER DEFAULT NULL,
                                  pNuMes               IN INTEGER DEFAULT NULL,
                                  pNuAno                IN INTEGER DEFAULT NULL);

 PROCEDURE PSaldoDevolucao13(pCdVinculo  IN INTEGER,
                             pFolha      IN PKGPAG_TIPO.rFolha);

 PROCEDURE PSaldoDevolucao13Ctisp(pCdVinculo  IN INTEGER,
                                  pFolha      IN PKGPAG_TIPO.rFolha);

 PROCEDURE PAjustarSaldoDevedor13(pCdVinculo           IN INTEGER,
                                  pFolha               IN PKGPAG_TIPO.rFolha);

 FUNCTION FPossuiProventos(pFolha           IN PKGPAG_TIPO.rFolha,
                           pCdVinculo       IN INTEGER)
   RETURN BOOLEAN;

 PROCEDURE PRescisaoMesAnterior(pFolha     IN PKGPAG_TIPO.rFolha,
                                pVinculo   IN PKGPAG_TIPO.rVinculo,
                                pDtCalculo IN DATE);

 PROCEDURE PDescontoValeTransporte(pCdVinculo              IN INTEGER,
                                   pFolha                  IN PKGPAG_TIPO.rFolha,
                                   pCdRubricaAgrupamento   IN INTEGER,
                                   pFlCalculoDefinitivo    IN CHAR,
                                   pDtCalculo              IN DATE);

 PROCEDURE PDescontoTetoGovernador(pCdVinculo            IN INTEGER,
                                   pFolha                IN PKGPAG_TIPO.rFolha,
                                   pCdRubricaAgrupamento IN INTEGER);

PROCEDURE PDescontoTetoGovernador13(pCdVinculo             IN INTEGER,
                                     pFolha                 IN PKGPAG_TIPO.rFolha,
                                     pCdRubricaAgrupamento  IN INTEGER);

procedure pDescontoPlanoSaude (pCdVinculo in integer);


PROCEDURE PDescontoPlanoSaudeTitular(pCdVinculo                IN INTEGER,
                                      pFolha                    IN PKGPAG_TIPO.rFolha,
                                      pRubrica                  IN PKGPAG_TIPO.rRubrica);

 PROCEDURE PDescontoPlanoSaudeAgreg(pCdVinculo IN INTEGER,
                                    pFolha     IN PKGPAG_TIPO.rFolha,
                                    pRubrica   IN PKGPAG_TIPO.rRubrica);

 PROCEDURE PDescontoCoParticipacao(pCdVinculo           IN INTEGER,
                                   pFolha               IN PKGPAG_TIPO.rFolha,
                                   pRubrica             IN PKGPAG_TIPO.rRubrica,
                                   pEvento              IN PKGPAG_TIPO.rEvento,
                                   pFlCalculoDefinitivo IN CHAR);

 PROCEDURE PLiqNegativo(pCdVinculo IN INTEGER,
                       pFolha      IN PKGPAG_TIPO.rFolha);

 PROCEDURE PDescontoLiqNegativo(pCdVinculo IN INTEGER,
                                pFolha     IN PKGPAG_TIPO.rFolha);

 PROCEDURE PUmTercoFerias(pCdVinculo  IN INTEGER,
                          pFolha      IN PKGPAG_TIPO.rFolha,
                          pRubrica    IN PKGPAG_TIPO.rRubrica,
                          pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo);

 PROCEDURE PDiferencaUmTercoFerias(pCdVinculo  IN INTEGER,
                                   pFolha      IN PKGPAG_TIPO.rFolha,
                                   pRubrica    IN PKGPAG_TIPO.rRubrica,
                                   pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo);

 PROCEDURE PDevolucaoUmTercoFerias(pCdVinculo  IN INTEGER,
                                   pFolha      IN PKGPAG_TIPO.rFolha,
                                   pRubrica    IN PKGPAG_TIPO.rRubrica,
                                   pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo);

 PROCEDURE PDevolucao13SalPensao(pFolha        IN PKGPAG_TIPO.rFolha,
                                 pCdVinculo    IN INTEGER,
                                 pRubrica      IN PKGPAG_TIPO.rRubrica);

 PROCEDURE PAbonoPecuniario(pCdVinculo  IN INTEGER,
                            pFolha      IN PKGPAG_TIPO.rFolha,
                            pRubrica    IN PKGPAG_TIPO.rRubrica,
                            pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo);

 PROCEDURE PAdiantamentoSalarioFerias(pCdVinculo  IN INTEGER,
                                      pFolha      IN PKGPAG_TIPO.rFolha,
                                      pRubrica    IN PKGPAG_TIPO.rRubrica,
                                      pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo);

 PROCEDURE PBaseGratProd(pFolha              IN PKGPAG_TIPO.rFolha,
                         pCdVinculo          IN INTEGER,
                         pRubrica            IN PKGPAG_TIPO.rRubrica,
                         pCEF                IN PKGPAG_TIPO.tCEF,
                         pCCO                IN PKGPAG_TIPO.tCCO,
                         pCCOSubst           IN PKGPAG_TIPO.tCCO,
                         pAPO                IN PKGPAG_TIPO.tCEF,
                         pCdTipoAtipratFaz   IN INTEGER);

 PROCEDURE PBloqueioRemunApo(pAPO        IN PKGPAG_TIPO.tCEF,
                             pFolha      IN PKGPAG_TIPO.rFolha,
                             pCdRubrica  IN INTEGER);

 PROCEDURE PContribuicaoSindical(pFolha                IN PKGPAG_TIPO.rFolha,
                                 pCdVinculo            IN INTEGER,
                                 pRubrica              IN PKGPAG_TIPO.rRubrica,
                                 pFormExpr             IN PKGPAG_TIPO.tFormulaCalculo,
                                 pCEF                  IN PKGPAG_TIPO.tCEF,
                                 pCCO                  IN PKGPAG_TIPO.tCCO,
                                 pCCOSubst             IN PKGPAG_TIPO.tCCO,
                                 pFUC                  IN PKGPAG_TIPO.tFUC,
                                 pBOL                  IN PKGPAG_TIPO.tBOL,
                                 pAPO                  IN PKGPAG_TIPO.tCEF);

 PROCEDURE PDescontoEventual(pFolha                IN PKGPAG_TIPO.rFolha,
                             pCdVinculo            IN INTEGER,
                             pRubrica              IN PKGPAG_TIPO.rRubrica,
                             pFormExpr             IN PKGPAG_TIPO.tFormulaCalculo,
                             pCEF                  IN PKGPAG_TIPO.tCEF,
                             pCCO                  IN PKGPAG_TIPO.tCCO,
                             pCCOSubst             IN PKGPAG_TIPO.tCCO,
                             pFUC                  IN PKGPAG_TIPO.tFUC,
                             pBOL                  IN PKGPAG_TIPO.tBOL,
                             pAPO                  IN PKGPAG_TIPO.tCEF);

PROCEDURE P069RescisaoFeriasACT(pFolha          IN PKGPAG_TIPO.rFolha,
                                pEvento         IN PKGPAG_TIPO.rEvento,
                                pTemDifMes      IN BOOLEAN,
                pRubrica        IN PKGPAG_TIPO.rRubrica);

PROCEDURE P069RescisaoFeriasCTISP(pFolha          IN PKGPAG_TIPO.rFolha,
                                  pEvento         IN PKGPAG_TIPO.rEvento,
                                  pTemDifMes      IN BOOLEAN,
                                  pRubrica        IN PKGPAG_TIPO.rRubrica);

PROCEDURE P073074FeriasIndenizadas(pCdRubricaAgrupamento IN INTEGER);

PROCEDURE P010392FeriasIndenizadasACTSJC(pCdRubricaAgrupamento IN INTEGER, pCdFolhaAnterior in integer default null);

PROCEDURE P011156FeriasIndenizadasVinc(pCdRubricaAgrupamento IN INTEGER);

FUNCTION RetornaValorRefBloqRemun (pCdVinculo     IN INTEGER,
                                   pCdAgrupamento IN INTEGER,
                                   pCdFolhaPagto  IN INTEGER,
                                   pNuAno         IN INTEGER,
                                   pNuMes         IN INTEGER )
    RETURN NUMBER;

PROCEDURE PBATIMENTOINSTPENSAO(pNuAnoMes  IN INTEGER);

END PKGPAG_POS;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_POS IS

 -- Inicio Globais de Ferias

 VERSAO_FERIAS CHAR(1) := 'N';

 gFerCdVinculo           INTEGER;
 gFerMesCalcAntFerias    INTEGER;
 gFerAnoCalcAntFerias    INTEGER;
 gFerAnoMesCalcAntFolha  INTEGER;
 gFerMinDiasEstorno      INTEGER;
 gVlRub1156              NUMBER(13,2);

 CURSOR cPagFerias (pCdVinculo      IN INTEGER,
                    pNuAnoPag       IN INTEGER,
                    pNuMesPag       IN INTEGER,
                    pNuAnoMesFerias IN INTEGER) IS

   SELECT PA.CdPeriodoAquisitivoFerias,
          NVL(FFP.NuDiasReceber,0) + NVL(FFP.NuDiasDevolvidos,0) as NuDias,
          FFU.Flanulado,
          PA.DtInicio,
          DECODE ( TO_CHAR (FFU.DtInicial,'YYYYMM'), TO_CHAR(pNuAnoMesFerias),'S','N' ) AS FlPermiteDiferenca,
          FFP.NuAnoMesDevolucao,
          LEAD (PA.CdPeriodoAquisitivoFerias,1,0) OVER (ORDER BY PA.CdPeriodoAquisitivoFerias) as ProxPerAquisitivoFerias,
          ffu.DtInicial as DtInicioFerias

    FROM EMovPeriodoAquisitivoFerias PA
   INNER JOIN EMovFeriasFruicaoUsufruto FFU
      ON FFU.CdPeriodoAquisitivoFerias = PA.CdPeriodoAquisitivoFerias
   INNER JOIN EMovFeriasFruicaoPagamento FFP
      ON FFP.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto

   WHERE PA.CdVinculo = pCdVinculo AND
         FFP.NuAnoReferencia = pNuAnoPag AND
         FFP.NuMesReferencia = pNuMesPag AND
         FFU.InSituacao IN ( -- GOZADOS
                             1, -- Programado
                             2, -- Reprogramado
                             3, -- Programado retroativamente
                            11, -- Alterado
                            -- SUSPENSOS/INTERROMPIDOS, por causa dos recalculos
                             4, -- Suspenso sem estorno dos beneficios
                             5, -- Suspenso com estorno dos beneficios
                             6, -- Suspenso motivo de movimentacao
                             7, -- Interrompido definitivamente
                             8  -- Interrompido temporariamente
                             -- 12 - Suspenso Nao Pago nao entra
                            ) AND
         FFP.NuDiasReceber >= 0 AND

         FFP.FlPagamentoIndenizado = PKGPAG_TIPO.cnN AND
         FFP.FlAnulado = PKGPAG_TIPO.cnN
 ORDER BY PA.CdPeriodoAquisitivoFerias, PA.Dtinicio,FFU.NuDias;

 CURSOR cPagFeriasDev (pCdVinculo     IN INTEGER,
                       pNuAnoMesDev   IN INTEGER,
                       pNuAnoLim      IN INTEGER,
                       pNuMesLim      IN INTEGER ) IS

   SELECT PA.CdPeriodoAquisitivoFerias,
          1 as NuDias, -- Para devolucao so importa a existencia do registro, nao o numero de dias
          FFP.NUANOREFERENCIA,
          FFP.Numesreferencia,
          FFU.Dtinicial,
          LEAD (PA.CdPeriodoAquisitivoFerias,1,0) OVER (ORDER BY PA.CdPeriodoAquisitivoFerias) as ProxPerAquisitivoFerias
    FROM EMovPeriodoAquisitivoFerias PA
   INNER JOIN EMovFeriasFruicaoUsufruto FFU
      ON FFU.CdPeriodoAquisitivoFerias = PA.CdPeriodoAquisitivoFerias
   INNER JOIN EMovFeriasFruicaoPagamento FFP
      ON FFP.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto

   WHERE PA.CdVinculo = pCdVinculo AND
         FFP.NuAnoMesDevolucao = pNuAnoMesDev AND
         ( FFP.NuAnoReferencia > pNuAnoLim OR
           (FFP.NuAnoReferencia = pNuAnoLim AND FFP.NuMesReferencia >= pNuMesLim ) ) AND
         FFP.NuDiasReceber >= 0 AND
         FFP.FlPagamentoIndenizado = PKGPAG_TIPO.cnN
 ORDER BY PA.CdPeriodoAquisitivoFerias, PA.Dtinicio;

 -- Fim Globais de Ferias

 PROCEDURE PAtualizaEventoVinculo(pFolha                IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo            IN INTEGER,
                                  pCdTipoEvento         IN INTEGER,
                                  pCdChave              IN INTEGER DEFAULT NULL,
                                  pCdRubrica            IN INTEGER DEFAULT NULL,
                                  pVlIndice             IN INTEGER DEFAULT NULL,
                                  pNuMes               IN INTEGER DEFAULT NULL,
                                  pNuAno                IN INTEGER DEFAULT NULL)
IS

  vRub                  INTEGER;

  vCdRubricaAgrupamento INTEGER;

  vvlEvento             NUMBER(13,2);

  vVlIndice             NUMBER(15,4);

  vCountEventoVinculoMes INTEGER := 0;

  PROCEDURE pInsereRegistro IS

  BEGIN

    IF vvlEvento > 0 OR vvlIndice > 0 THEN

    -- Verifica se registro ja foi inserido

    INSERT INTO EPagEventoVinculo
      (CdEventoVinculo,
       CdVinculo,
       CdTipoEventoVinculo,
       NuAnoMesReferencia,
       VlEvento,
       VlIndice,
       CdRubricaAgrupamento,
       NuCpfCadastrador,
       NuCpfUltimaAlteracao,
       DtInclusao,
       DtUltAlteracao,
       CdChave)
    VALUES
      (SPagEventoVinculo.nextval,
       pCdVinculo,
       pCdTipoEvento,
       (case when pNuAno < pFolha.NuAnoReferencia then pNuAno else
        pFolha.NuAnoReferencia end * 100 + case when
        pNuMes <> pFolha.NuMesReferencia then pNuMes else
        pFolha.NuMesReferencia end),
       vVlEvento,
       vVlIndice,
       vCdRubricaAgrupamento,
       '00000000000',
       NULL,
       SYSDATE,
       SYSTIMESTAMP,
       pCdChave);

    END IF;

  END;

BEGIN

  vvlEvento             := 0;

  vvlIndice             := 0;

  vCdRubricaAgrupamento := NULL;

  IF pCdChave is not null
    THEN
       DELETE
         FROM EPagEventoVinculo EV
        WHERE EV.CdVinculo = pCdVinculo
          AND EV.NuAnoMesReferencia = (pFolha.NuAnoReferencia*100 + pFolha.NuMesReferencia)
          AND EV.CdTipoEventoVinculo = pCdTipoEvento
          AND EV.Cdchave = pCdChave
          AND EV.Cdrubricaagrupamento = pCdRubrica;

    ELSE

       DELETE
         FROM EPagEventoVinculo EV
        WHERE EV.CdVinculo = pCdVinculo
          AND EV.NuAnoMesReferencia = (pFolha.NuAnoReferencia*100 + pFolha.NuMesReferencia)
          AND EV.CdTipoEventoVinculo = pCdTipoEvento;

  END IF;

  CASE pCdTipoEvento

    WHEN 1 THEN

      IF PKGPAG_VAR.vgListaContribSind.FIRST IS NOT NULL THEN

        vRub := PKGPAG_VAR.vgListaContribSind.FIRST;

        IF PKGPAG_VAR.vgListaContribSind.EXISTS(vRub) THEN

          WHILE vRub <= PKGPAG_VAR.vgListaContribSind.LAST
          LOOP

            vCdRubricaAgrupamento := vRub;

            vvlEvento             := PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                       pCdVinculo,
                                                                       vRub);

            IF vvlEvento > 0 THEN

              pInsereRegistro;

              vRub:= PKGPAG_VAR.vgListaContribSind.LAST + 1;

            END IF;

            vRub := PKGPAG_VAR.vgListaContribSind.NEXT(vRub);

          END LOOP;

        END IF;

      END IF;

    WHEN 2 THEN

      -- Se codigo da rubrica igual a zero, entao retorna
      IF NVL(PKGPAG_VAR.vgCdRubricaHoraPlantao,0) = 0 THEN
        RETURN;
      END IF;

        vCdRubricaAgrupamento := PKGPAG_VAR.vgCdRubricaHoraPlantao;

        IF pkgpag_var.vgNuIndiceHoraPlantao > 0 THEN
          vVlIndice := pkgpag_var.vgNuIndiceHoraPlantao;
        ELSE
          vVlIndice := PKGPAG_GERAL.FRetornaIndiceRubrica(pFolha.CdFolhaPagamento,
                                                          pCdVinculo,
                                                          PKGPAG_VAR.vgCdRubricaHoraPlantao,
                                                          0,
                                                          TRUE);
        END IF;

      -- Se valor do indice igual a zero, entao retorna
      IF NVL(vVlIndice,0) = 0 THEN
          RETURN;
      END IF;

      -- Verifica se ja salvou indice no mes
      vCountEventoVinculoMes := 0;

      select count(*)
      into vCountEventoVinculoMes
      from EPagEventoVinculo ev
      where ev.cdvinculo = pCdVinculo
      and   ev.cdtipoeventovinculo = pCdTipoEvento
      and   ev.nuanomesreferencia =
             (case when pNuAno < pFolha.NuAnoReferencia then pNuAno else
              pFolha.NuAnoReferencia end * 100 + case when
              pNuMes <> pFolha.NuMesReferencia then pNuMes else
              pFolha.NuMesReferencia end)
      and ev.cdrubricaagrupamento = vCdRubricaAgrupamento
      and ev.cdchave = pCdChave;

      -- Se ja salvou o indice no mes, entao retorna
      IF NVL(vCountEventoVinculoMes,0) > 0 THEN
          RETURN;
      END IF;

      -- Insere registro
      pInsereRegistro;

    WHEN 3 THEN

      IF (pCdRubrica is not null AND NVL(pVlIndice,0) > 0)

         THEN
           vCdRubricaAgrupamento := pCdRubrica;

           vVlIndice := pVlIndice;

           pInsereRegistro;

      END IF;

     WHEN 4 THEN

            vCdRubricaAgrupamento := pCdRubrica;

            vVlIndice := PKGPAG_GERAL.FRetornaIndiceRubrica(pFolha.CdFolhaPagamento,
                                                        pCdVinculo,
                                                        pCdRubrica,
                                                        0,
                                                        TRUE);

            vvlEvento             := PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                       pCdVinculo,
                                                                       pCdRubrica);

            IF vvlEvento > 0 THEN

             vvlEvento:= vvlEvento / vVlIndice * pVlIndice;
             vVlIndice :=      pVlIndice;

              pInsereRegistro;

            END IF;

            --vRub := PKGPAG_VAR.vgListaContribSind.NEXT(vRub);

  END CASE;

EXCEPTION

  WHEN OTHERS THEN

     PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                             PKGPAG_VAR.vCdHistParamCalc,
                             PKGPAG_VAR.vCdPessoa,
                             'Erro ao atualizar eventos Indice Hora Plantão/Contribuição Sindical.',
                             PKGPAG_VAR.vgCdVinculo);

END;

FUNCTION FRetornaValorExpressao(pCdFolhaPagamento IN INTEGER,
                                pCdVinculo        IN INTEGER,
                                pCdRubricaAgrupamento IN INTEGER)
RETURN NUMBER IS

  vVlCalculado NUMBER(13,2) := 0;

BEGIN

 SELECT
    SUM(trunc(pkgmath.fcalcular(hr.deexpressao),2))
   INTO vVlCalculado
   from epaghistoricorubricarelvinc hr
   where hr.cdrubricaagrupamento = pCdRubricaAgrupamento
     and hr.cdvinculo = pCdVinculo
     and hr.cdfolhapagamento = pCdFolhaPagamento
     and hr.deexpressao is not null;

    RETURN vVlCalculado;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

     RETURN 0;

  WHEN OTHERS THEN

     RETURN 0;

END;

FUNCTION FCarreiraPermitidasRubrica(pCdVinculo IN INTEGER,
                                    pDtInicio  IN DATE,
                                    pDtFim     IN DATE,
                                    pRubrica   IN PKGPAG_TIPO.rRubrica)
  RETURN BOOLEAN IS

  vcdestrutura                 INTEGER := 0;
  vcdestruturacarreira         INTEGER;
  vcdestruturacarreiracarreira INTEGER;
  vAnoMesDesligamento          INTEGER;
BEGIN

  IF pkgpag_var.vgcef.count > 0 THEN

    FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

      -- Algumas carreiras impedem a geracao da rubrica
      IF prubrica.ingerarubricacarreira = '1' THEN

        vcdestrutura := pkgpag_geral.fexistecarreira(PKGPAG_VAR.vgCEF(i)
                                                     .cdestruturacarreira);

        WHILE vcdestrutura IS NOT NULL LOOP

          IF prubrica.lscarreira.exists(vcdestrutura) THEN

            RETURN FALSE;
          END IF;

          -- Retorna a carreira pai
          vcdestrutura := pkgpag_geral.fproxcarreira(vcdestrutura);

        END LOOP;

        -- Algumas carreiras exigem a geracao da rubrica
      ELSIF prubrica.ingerarubricacarreira = '2' THEN

        vcdestrutura := pkgpag_geral.fexistecarreira(PKGPAG_VAR.vgCEF(1)
                                                     .cdestruturacarreira);

        WHILE vcdestrutura IS NOT NULL LOOP

          IF prubrica.lscarreira.exists(vcdestrutura) THEN

            RETURN TRUE;

          END IF;

          --Retorna a carreira pai
          vcdestrutura := pkgpag_geral.fproxcarreira(vcdestrutura);

        END LOOP;

        RETURN FALSE;

      else
        null;
      END IF;

      RETURN TRUE;

    END LOOP;

  ELSIF PKGPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
        PKGPAG_VAR.vgVinculo.DtDesligamento <= pkgpag_var.vgFolha.dtfimMes THEN

    vAnoMesDesligamento := (EXTRACT(year FROM PKGPAG_VAR.vgVinculo.DtDesligamento) * 100) + EXTRACT(month FROM PKGPAG_VAR.vgVinculo.DtDesligamento);

    select cfm.cdestruturacarreira, ec.cdestruturacarreiracarreira
      into vcdestruturacarreira, vcdestruturacarreiracarreira
      from ecadconsfuncmensal cfm
     inner join ecadestruturacarreira ec
        on cfm.cdestruturacarreira = ec.cdestruturacarreira
     where cfm.cdvinculo = pCdVinculo
       and cfm.nuanomes = vAnoMesDesligamento;

    -- Algumas carreiras impedem a geração da rubrica
    IF prubrica.InGeraRubricaCarreira = 1 AND
       (prubrica.lscarreira.exists(vcdestruturacarreira) OR
       prubrica.lscarreira.exists(vcdestruturacarreiracarreira)) THEN

      RETURN FALSE;

    END IF;

    -- Algumas carreiras permitem a geração da rubrica
    IF prubrica.InGeraRubricaCarreira = 2 AND
       NOT (prubrica.lscarreira.exists(vcdestruturacarreira) OR
        prubrica.lscarreira.exists(vcdestruturacarreiracarreira)) THEN

      RETURN FALSE;

    END IF;

    RETURN TRUE;

  END IF;

  RETURN FALSE;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN TRUE;

  WHEN OTHERS THEN

    RETURN TRUE;

END;

FUNCTION FPossuiProventos(pFolha             IN PKGPAG_TIPO.rFolha,
                          pCdVinculo       IN INTEGER)
RETURN BOOLEAN IS

  vPossuiProventos  INTEGER;

BEGIN

  SELECT 1
    INTO vPossuiProventos
    FROM EPagHistoricoRubricaRelVinc HRV
   INNER JOIN EPagRubricaAgrupamento RA
      ON HRV.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
   INNER JOIN EPagRubrica R
      ON R.CdRubrica = RA.CdRubrica
   WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
         HRV.CdVinculo = pCdVinculo AND
         R.CdTipoRubrica IN (1,2,4,10,12) AND
         HRV.VlProporcional > 0 AND
         ROWNUM < 2;

  RETURN TRUE;

EXCEPTION

  WHEN NO_DATA_FOUND THEN
    --
    -- Solicitacao de Sustentacao #69570
    -- 8681/2016 - FOLHA MATRICULA 0394121-3-02 ORGAO 902
    --
    BEGIN
    SELECT 1
      INTO vPossuiProventos
      FROM EPagHistoricoRubricaVinculo HRV
      INNER JOIN EPagRubricaAgrupamento RA
              ON HRV.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
      INNER JOIN EPagRubrica R
              ON R.CdRubrica = RA.CdRubrica
      WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
        AND HRV.CdVinculo = pCdVinculo
        AND R.CdTipoRubrica IN (1,2,4,10,12)
        AND HRV.VLPAGAMENTO > 0
        AND ROWNUM < 2;

     RETURN TRUE;

    EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    END;

END;

--
-- Funcao que verifica se ACT teve prorrogacao de contrato.
--
FUNCTION FProrrogacao(pCdHistCargoEfetivo IN INTEGER)
RETURN BOOLEAN IS

  vCont INTEGER;

BEGIN

  SELECT 1
    INTO vCont
    FROM ECadHistActProrrogacao HRP
   WHERE HRP.Cdhistcargoefetivo = pCdHistCargoEfetivo
     AND HRP.FLANULADO = 'N'
     AND ROWNUM < 2;

  RETURN TRUE;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

END;

------------------------------------------------------------------------
--
------------------------------------------------------------------------

FUNCTION FPagaContribuicaoSindical(pCdVinculo       IN INTEGER,
                                   pNuAnoReferencia IN INTEGER,
                                   pDtInicioMes     IN DATE,
                                   pDdtFimMes       IN DATE,
                                   pRubrica         IN PKGPAG_TIPO.rRubrica )

  RETURN BOOLEAN IS

   vCont INTEGER;

   vCdVinculo       INTEGER;
   --vNuAnoReferencia INTEGER;
   vdtInicioMes     DATE;
   vdtFimMes       DATE;

BEGIN

  vCont := 0;

  vCdVinculo := pCdVinculo;
  --vNuAnoReferencia := pNuAnoReferencia;
  vdtInicioMes := pDtInicioMes;
  vdtFimMes := pDdtFimMes;

  SELECT 1
    INTO vCont
    FROM EPagEventoVinculo EV
   WHERE EV.CdVinculo = pCdVinculo AND
         EV.CdTipoEventoVinculo = 1 AND
         EV.NuAnoMesReferencia BETWEEN (pNuAnoReferencia*100 + 01) AND (pNuAnoReferencia*100 + 12) AND
         ROWNUM < 2;

   RETURN FALSE;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    BEGIN

      SELECT 1
        INTO vCont
        FROM EPagIsencaoContribSindical IC
       WHERE IC.CdVinculo = pCdVinculo AND
             IC.NuAnoReferencia = pNuAnoReferencia AND
             IC.FlAnulado = PKGPAG_TIPO.cnN AND
             ROWNUM < 2;

      RETURN FALSE;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        BEGIN

           SELECT 1
            INTO vCont
            FROM EAfaAfastamentoVinculo AV
            INNER JOIN EAfaHistMotivoAfastTemp HMAT
              ON Av.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
            INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario, MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                         FROM EAfaHistMotivoAfastTemp HMATV
                        WHERE HMATV.dtInicioVigencia <= vdtFimMes
                       GROUP BY HMATV.CdMotivoAfastTemporario) MV
              ON HMAT.CdMotivoAfastTemporario = MV.CdMotivoAfastTemporario AND
                 HMAT.DtInicioVigencia = MV.DtInicioVigencia
            WHERE AV.CdVinculo = vCdVinculo AND
                 AV.FlAnulado = PKGPAG_TIPO.cnN AND
                 ( (AV.DtInicio <= vdtFimMes AND (AV.DtFim >= vdtInicioMes OR AV.DtFim IS NULL) )
                 ) AND
                 (
                     (pRubrica.InGeraRubricaAfastTemp = '1' AND
                       AV.CdMotivoAfastTemporario IN
                         (SELECT CdMotivoAfastTemporario
                            FROM EPagRubAgrupMotAfastTempImp AI
                           WHERE AI.CdMotivoAfastTemporario = AV.CdMotivoAfastTemporario AND
                                 AI.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica AND
                                 NOT EXISTS (SELECT 1
                                               FROM EPagRubAgrpMotAfTempImpVinc VI
                                              WHERE AI.Cdhistrubricaagrupamento = VI.Cdhistrubricaagrupamento AND
                                                    AI.CdMotivoAfastTemporario =  VI.CdMotivoAfastTemporario AND
                                                    VI.CdVinculo = vCdVinculo)))
                    OR (pRubrica.InGeraRubricaAfastTemp = '2' AND
                        ( (AV.CdMotivoAfastTemporario NOT IN
                          (SELECT CdMotivoAfastTemporario
                             FROM EPagRubAgrupMotAfastTempImp AI
                            WHERE AV.CdMotivoAfastTemporario = AI.CdMotivoAfastTemporario AND
                                  AI.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica AND
                                  NOT EXISTS (SELECT 1
                                               FROM EPagRubAgrpMotAfTempImpVinc VI
                                              WHERE AI.Cdhistrubricaagrupamento = VI.Cdhistrubricaagrupamento AND
                                                    AI.CdMotivoAfastTemporario =  VI.CdMotivoAfastTemporario AND
                                                    VI.CdVinculo = vCdVinculo)))
                           OR (SELECT COUNT(*)
                              FROM EPagRubAgrupMotAfastTempImp AI
                             WHERE AI.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica) = 0 ))
                 ) AND
                 ROWNUM < 2 ;

           RETURN FALSE;

        EXCEPTION

           WHEN NO_DATA_FOUND THEN

                RETURN TRUE;

        END;

     END;
END;

 FUNCTION fPossuiSitPrevVigenteMesAnt(pcdvinculo     IN INTEGER,
                                      pDtDeligamento IN DATE DEFAULT NULL)
   RETURN BOOLEAN IS
   vsitprev integer;

 BEGIN
   IF pDtDeligamento IS NOT NULL THEN
     SELECT cdsituacaoprevidenciaria
       INTO vsitprev
       FROM (SELECT hspv.cdsituacaoprevidenciaria
               FROM ecadhistsitprevvinculo hspv
              WHERE HSPV.CdVinculo = pcdvinculo
                AND HSPV.DTFIM <= pDtDeligamento
              ORDER BY hspv.dtinicio DESC)
      WHERE ROWNUM < 2;
   END IF;

   IF vsitprev <> 1 THEN
     -- ATIVO
     RETURN FALSE;
   ELSE
     RETURN TRUE;
   END IF;

 EXCEPTION

   WHEN no_data_found THEN
     RETURN FALSE;

   WHEN OTHERS THEN
     RETURN FALSE;

 END;

 FUNCTION falteroucargoefetivo(pcdvinculo IN INTEGER) RETURN BOOLEAN IS

   vcont             INTEGER;
   vcdfolhanormalant INTEGER;
   vnuanomesant      CHAR(6) := to_char(pkgpag_var.vgfolha.dtcalculoant,
                                        'yyyymm');

 BEGIN

   vcont             := 0;
   vcdfolhanormalant := 0;
   FOR vin IN (SELECT cef.*
                 FROM ecadhistcargoefetivo cef
                WHERE cef.cdvinculo = pcdvinculo
                  AND cef.flanulado = 'N'
                  AND ((trunc(cef.dtinicio) <=
                      trunc(pkgpag_var.vgfolha.dtcalculoant) AND
                      trunc(cef.dtfim) <
                      trunc(pkgpag_var.vgfolha.dtiniciomes)) OR
                      (trunc(cef.dtinicio) <
                      trunc(pkgpag_var.vgfolha.dtiniciomes) AND
                      trunc(cef.dtinclusao) >
                      trunc(pkgpag_var.vgfolha.dtcalculoant)))
                  AND cef.cdhistcargoefetivo <> pkgpag_var.vgcef(1)
                     .cdhistrelvinc
                ORDER BY cef.dtinicio)

    LOOP

     vcont := vcont + 1;

     IF vin.cdorgaoexercicio <> pkgpag_var.vgfolha.cdorgao THEN

       BEGIN

         SELECT f.cdfolhapagamento
           INTO vcdfolhanormalant
           FROM epagfolhapagamento f
          INNER JOIN epagtipofolhapagamento tf
             ON f.cdtipofolhapagamento = tf.cdtipofolhapagamento
          INNER JOIN epagtipofolha tp
             ON tp.cdtipofolha = tf.cdtipofolha
            AND tf.cdtipofolha = pkgpag_tipo.cntpfolhanormal
            AND f.cdtipocalculo = pkgpag_tipo.cntpcalculonormal
            AND f.nuanomesreferencia = vnuanomesant
            AND f.cdorgao = vin.cdorgaoexercicio;

       EXCEPTION
         WHEN no_data_found THEN
           vcdfolhanormalant := 0;

         WHEN OTHERS THEN
           vcdfolhanormalant := 0;

       END;

     END IF;

   END LOOP;

   CASE
     WHEN vcont = 0 THEN
       RETURN FALSE;
     WHEN vcont > 0 THEN
       RETURN TRUE;
   END CASE;

 EXCEPTION
   WHEN no_data_found THEN
     RETURN FALSE;

   WHEN OTHERS THEN
     RETURN FALSE;
 END;

FUNCTION fPossuiAfastDefinitivoAnulado(pcdvinculo IN INTEGER) RETURN BOOLEAN IS

  -- SIG-2938
  -- 14303/2019 Sistema nao esta estornando ferias indenizadas
  vCont integer;

BEGIN

   select 1
     into vCont
     from eafaafastamentovinculo vv
    where vv.cdvinculo = pcdvinculo
      and flanulado = 'S'
      and vv.fltipoafastamento = 'D'
      and vv.dtanulado > trunc(pkgpag_var.vgfolha.dtcalculoant)
      and vv.dtanulado <= trunc(pkgpag_var.vgFolha.dtfimmes)
      and nvl(pkgpag_var.vmotafast.intipoafastamento,'') <> 'D'
      and rownum < 2;

   if vCont = 1
     then
      return true;

   else
      return false;
   end if;

 EXCEPTION
   WHEN no_data_found THEN
     RETURN FALSE;

   WHEN OTHERS THEN
     RETURN FALSE;

 end;

 FUNCTION fAlterouCargoCom(pcdvinculo IN INTEGER) RETURN BOOLEAN IS

   vcont             INTEGER;
   vcdfolhanormalant INTEGER;
   vnuanomesant      CHAR(6) := to_char(pkgpag_var.vgfolha.dtcalculoant,
                                        'yyyymm');

 BEGIN

   vcont             := 0;
   vcdfolhanormalant := 0;

   FOR vin IN (SELECT cco.cdorgaoexercicio
                       FROM ecadhistcargocom cco
                      WHERE cco.cdvinculo = pcdvinculo
                          AND cco.flanulado = 'N'
                          AND ((trunc(cco.dtinicio) <= trunc(pkgpag_var.vgfolha.dtiniciomes) AND
                             trunc(cco.dtfim) BETWEEN trunc(pkgpag_var.vgfolha.dtcalculoant+1) AND
                             trunc(pkgpag_var.vgfolha.dtfimmes))
                            OR (trunc(cco.dtinicio) < trunc(pkgpag_var.vgfolha.dtiniciomes) AND
                             trunc(cco.dtinclusao) > trunc(pkgpag_var.vgfolha.dtcalculoant)))
                      ORDER BY cco.dtinicio) LOOP

     vcont := vcont + 1;

     IF vin.cdorgaoexercicio <> pkgpag_var.vgfolha.cdorgao THEN

       BEGIN

         SELECT f.cdfolhapagamento
           INTO vcdfolhanormalant
           FROM epagfolhapagamento f
          INNER JOIN epagtipofolhapagamento tf
             ON f.cdtipofolhapagamento = tf.cdtipofolhapagamento
          INNER JOIN epagtipofolha tp
             ON tp.cdtipofolha = tf.cdtipofolha
            AND tf.cdtipofolha = pkgpag_tipo.cntpfolhanormal
            AND f.cdtipocalculo = pkgpag_tipo.cntpcalculonormal
            AND f.nuanomesreferencia = vnuanomesant
            AND f.cdorgao = vin.cdorgaoexercicio;

       gVlRub1156 := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => vcdfolhanormalant,pcdvinculo => pcdvinculo, pcdrubrica => 58037);

       EXCEPTION
         WHEN no_data_found THEN
           vcdfolhanormalant := 0;

         WHEN OTHERS THEN
           vcdfolhanormalant := 0;

       END;

     END IF;

   END LOOP;

   CASE
     WHEN vcont = 0 THEN
       RETURN FALSE;
     WHEN vcont > 0 THEN
       RETURN TRUE;
   END CASE;

 EXCEPTION
   WHEN no_data_found THEN
     RETURN FALSE;

   WHEN OTHERS THEN
     RETURN FALSE;
 END;

 PROCEDURE PRescisaoMesAnterior(pFolha     IN PKGPAG_TIPO.rFolha,
                                pVinculo   IN PKGPAG_TIPO.rVinculo,
                                pDtCalculo IN DATE) IS

    vCdRubrica51023 INTEGER;
    vVlRecebido number(13,2);
    vVlNaoDescontado number(13,2);

 BEGIN

   IF (pVinculo.DtDesligamento < pFolha.DtInicioMes) AND
      (trunc(PKGPAG_VAR.vMotAfast.DtInclusao) BETWEEN (PKGPAG_VAR.vDtCalculoAnt + 1) AND (pDtCalculo)) AND
      -- Solicitacao de Sustentacao #80264
      -- 12550/2018 - NAO ESTA DESCONTANDO O ADIANTAMENTO 13 NA EXONERACAO
      -- Incluida validacao da data de inclusao
      (trunc(PKGPAG_VAR.vMotAfast.DtInicio) >= trunc(PKGPAG_VAR.vDtCalculoAnt,'mm') OR
       (trunc(PKGPAG_VAR.vMotAfast.DtInclusao) >= trunc(PKGPAG_VAR.vDtCalculoAnt,'mm')) ) AND
      NOT PKGPAG_VAR.bPossuiObito  THEN

     vCdRubrica51023 := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                     pCdTipoRubrica => 5,
                                                     pNuRubrica     => 1023);

     IF PKGPAG_GERAL.FVinculoComProventos(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                          pCdVinculo            => pVinculo.CdVinculo) THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  =>
                                                 PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                                                        pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                        pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaDevAnt13,
                                                                        pCdRelacaoVinculo     => 0),
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaDevAnt13,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_FB.PProcessaFormulasBases(pFolha,
                                         pVinculo.CdVinculo,
                                         PKGPAG_VAR.vgCdRubricaDevAnt13,
                                         1,
                                         2);

       PKGPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo => pVinculo.CdVinculo);

       -- Se nao tem saldo para desconto inclui valor na rubrica 09-9924
       if PKGPAG_VAR.vgVlTotalProventos < PKGPAG_VAR.vgVlTotalDescontos and
          PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                            pVinculo.CdVinculo,
                                            PKGPAG_VAR.vgCdRubricaDevAnt13) > 0 then
                                            
          vVlRecebido := PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                            pVinculo.CdVinculo,
                                            PKGPAG_VAR.vgCdRubricaDevAnt13);                                  

         
         if vVlRecebido > PKGPAG_VAR.vgVlTotalProventos then
           
           vVlNaoDescontado := vVlRecebido - PKGPAG_VAR.vgVlTotalProventos;
           
           vVlRecebido := PKGPAG_VAR.vgVlTotalProventos;
          
           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pVinculo.CdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado,
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vVlNaoDescontado,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 1);

        
        end if;
        
        update epaghistoricorubricavinculo v
           set v.vlpagamento = vVlRecebido
         where v.cdvinculo = pVinculo.CdVinculo
           and v.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
           and v.cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaDevAnt13;

      end if;


       IF vCdRubrica51023 > 0 THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pVinculo.CdVinculo,
                                               pCdExpressaoFormCalc  =>
                                                PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                                                       pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                       pCdRubricaAgrupamento => vCdRubrica51023,
                                                                       pCdRelacaoVinculo     => 0),
                                             pCdRubricaAgrupamento => vCdRubrica51023,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => 0,
                                             pVlIndice             => NULL,
                                             pCdTipoOrigemRubrica  => 1);

         PKGPAG_FB.PProcessaFormulasBases(pFolha,
                                          pVinculo.CdVinculo,
                                          vCdRubrica51023,
                                          1,
                                          2);

      END IF;

    END IF;

  END IF;

END;

PROCEDURE PDescontoValeTransporte(pCdVinculo            IN INTEGER,
                                  pFolha                IN PKGPAG_TIPO.rFolha,
                                  pCdRubricaAgrupamento IN INTEGER,
                                  pFlCalculoDefinitivo  IN CHAR,
                                  pDtCalculo            IN DATE)

  IS

  vvlTotalVale              NUMBER(13,2);
  vvlDesconto               NUMBER(13,2);
  vvlMaxDesconto            NUMBER(13,2);
  vvlBaseDesconto           NUMBER(13,2);
  vQtValesConcedidos        INTEGER;
  vQtValesNaoConcedidos     INTEGER;
  vCdHistoricoFinanceiro    INTEGER;
  vCdHistoricoProcessamento INTEGER;
  vNuAnoFolha               INTEGER;
  vNuMesFolha               INTEGER;
  vCdExpressaoFormCalc      integer;
  vNuDiasDesconto           integer;
  vrubrica                  pkgpag_tipo.rrubrica;

BEGIN

  IF PKGPAG_VAR.vgIndicadorValeTransp.FlPecunia = PKGPAG_TIPO.cnN AND
     PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria NOT IN (2,3) and not
     (pFolha.CdAgrupamento = 176 and to_char(pFolha.DtInicioMes,'YYYYMM') > '202403')   THEN

    -- Calcula a base associada a rubrica de desconto de vale transporte

   PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                         pCdVinculo            => pCdVinculo,
                                         pCdExpressaoFormCalc  => NULL,
                                         pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseVP,
                                         pNuSufixoRubrica      => 1,
                                         pVlPagamento          => 0,
                                         pVlIndice             => NULL,
                                         pCdTipoOrigemRubrica  => 1);

    PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => PKGPAG_VAR.vgCdRubBaseVP,
                                     pTpProcessamento => 2,
                                     pTpLocal         => 2);

    BEGIN

      SELECT HPV.CdHistoricoProcessamento,
             HF.CdHistoricoFinanceiro,
             HF.VlTotalValesConcedidos,
             HF.QtValesConcedidos,
             HF.QtValesNaoConcedidos,
             HPV.NuAnoFolha,
             HPV.NuMesFolha
        INTO vCdHistoricoProcessamento,
             vCdHistoricoFinanceiro,
             vvlTotalVale,
             vQtValesConcedidos,
             vQtValesNaoConcedidos,
             vNuAnoFolha,
             vNuMesFolha
        FROM EVtrHistoricoFinanceiro HF
       INNER JOIN EVtrHistoricoProcessamento HPV
         ON HF.CdHistoricoProcessamento = HPV.CdHistoricoProcessamento
        WHERE HF.CdVinculo = pCdVinculo
          AND HPV.NuAnoCompetencia = pFolha.NuAnoReferencia
          AND HPV.NuMesCompetencia = pFolha.NuMesReferencia
          AND HPV.DtEfetivacao IS NOT NULL;

      BEGIN

       SELECT HRV.VlPagamento,
              HRV.VlPagamento*0.06
         INTO vvlBaseDesconto,
              vvlMaxDesconto
         FROM EPagHistoricoRubricaVinculo HRV
        WHERE HRV.CdVinculo = pCdVinculo AND
              HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
              HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseVP;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          RAISE PKGPAG_VAR.eSemBaseValeTransp;

      END;

      IF vvlTotalVale > vvlMaxDesconto THEN

        vvlDesconto := vvlMaxDesconto;

      ELSE

        vvlDesconto := vvlTotalVale;

         -- Caso o orgao indique que deve cancelar a concessao

        IF pFlCalculoDefinitivo = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgIndicadorValeTransp.FlConcessao = PKGPAG_TIPO.cnS THEN

          -- Caso nao tenha havido abatimento de vale tansporte (quantidade integral)

          IF NVL(vQtValesNaoConcedidos,0) = 0 THEN

           -- Cancela vale transporte

            UPDATE EVtrPedidoValeTransporte VT
               SET VT.DtCancelamento = pDtCalculo,
                   VT.CdTipoCancelamento = 2,
                   VT.FlCancelado = 'S',
                   VT.DtUltAlteracao = systimestamp
             WHERE VT.CdVinculo = pCdVinculo AND
                   VT.DtCancelamento IS NULL;

          END IF;

        END IF;

       END IF;

      UPDATE EvtrHistoricoFinanceiro HF
         SET HF.VlBaseCalculo = vvlBaseDesconto,
             HF.VlADescontar = vvlDesconto,
             HF.FlTipoDesconto = PKGPAG_TIPO.cnS
       WHERE HF.CdHistoricoFinanceiro = vCdHistoricoFinanceiro;

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => vvlDesconto,
                                            pVlIndice             => 6,
                                            pCdTipoOrigemRubrica  => 13);

    IF PKGPAG_VAR.vCdHistParamCalc <> 0 AND
       (vNuAnoFolha IS NULL OR vNuAnoFolha <> pFolha.NuAnoReferencia OR
        vNuMesFolha IS NULL OR vNuMesFolha <> pFolha.NuMesReferencia ) THEN

      UPDATE EVtrHistoricoProcessamento HP
         SET HP.NuAnoFolha = pFolha.NuAnoReferencia,
             HP.NuMesFolha = pFolha.NuMesReferencia
       WHERE HP.CdHistoricoProcessamento = vCdHistoricoProcessamento;

    END IF;

    --

    EXCEPTION

      WHEN PKGPAG_VAR.eSemBaseValeTransp THEN

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vCdHistParamCalc,
                                PKGPAG_VAR.vCdPessoa,
                                'Não foi encontrada a rubrica referente à base do Vale Transporte. Desconto não calculado.',
                                PKGPAG_VAR.vgCdVinculo);

      WHEN TOO_MANY_ROWS THEN

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  PKGPAG_VAR.vCdHistParamCalc,
                                  PKGPAG_VAR.vCdPessoa,
                                  'Encontrada duplicidade de dados de processamento do Vale Transporte.',
                                  PKGPAG_VAR.vgCdVinculo);

      WHEN NO_DATA_FOUND THEN

         NULL;
    END;

  ELSIF pFolha.CdAgrupamento = 176  THEN

   -- Calcula a base associada a rubrica de desconto de vale transporte

   vrubrica :=  pkgpag_var.vgRubrica(PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                  pCdTipoRubrica => 8,
                                                                  pNuRubrica     => 1000));

   vNuDiasDesconto:= pkgpag_fb.fmneqtdiasremimpedsuteisret(pfolha,pcdvinculo,
                                        vRubrica,
                                        pkgpag_var.vgvinculo.dtdesligamento,
                                        pFolha.dtcalculo);

   if PKGPAG_VAR.vgIndiceFaltasMesAnterior > 0 then

      vNuDiasDesconto := nvl(vNuDiasDesconto,0) + PKGPAG_VAR.vgIndiceFaltasMesAnterior;

   end if;

   vvlDesconto := PKGPAG_PARAM.FValorReferencia('VTR');

   PKGPAG_GERAL.PInsereLancamentoVinculo (pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => null,
                                          pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                  pCdTipoRubrica => 8,
                                                                  pNuRubrica     => 1000),
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => vNuDiasDesconto * vvlDesconto,
                                          pVlIndice             => vNuDiasDesconto,
                                          pCdTipoOrigemRubrica  => 1);

    PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => pCdRubricaAgrupamento,
                                     pTpProcessamento => 1,
                                     pTpLocal         => 2);

    update epaghistoricorubricavinculo hv
       set hv.cdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                  pCdTipoRubrica => 8,
                                                                  pNuRubrica     => 1000)
     where hv.cdvinculo = pCdVinculo
       and hv.cdfolhapagamento = pFolha.CdFolhaPagamento
       and hv.cdrubricaagrupamento = pCdRubricaAgrupamento;

  END IF;

END;

PROCEDURE PDescontoTetoGovernador(pCdVinculo             IN INTEGER,
                                  pFolha                 IN PKGPAG_TIPO.rFolha,
                                  pCdRubricaAgrupamento  IN INTEGER) IS

  vCdExpressaoFormCalc   INTEGER;

  vCdEstruturaCarreira   INTEGER DEFAULT NULL;

  vVlRubDescTetoGov      NUMBER(13,2);

  vCdFolhaRetro          INTEGER;

  vVlBaseTeto            NUMBER(13,2);

  vVlReferencia          NUMBER(13,2);

  vNuAnoRefRetro         INTEGER;

  vNuMesRefRetro         INTEGER;

  vVlBloqueio            NUMBER(13,2);

  vVlDepositoJud         INTEGER;

  vCdValRefDepJud        INTEGER;

  vVlPago                NUMBER(13,2);

  vNuMesesRetro          INTEGER;

  vDtInclusao            DATE;

  vDtInicioDireito       DATE;

  vVlDescTetoGovMesesAnt NUMBER(13,2);

  vNuAnoMesInicio        INTEGER;

  vNuAnoMesFim           INTEGER;

  FUNCTION FDeveSomarRubrica(pCdRubricaAgrupamento IN INTEGER,
                             pCdAgrupamento        IN INTEGER,
                             pNuAnoReferencia      IN INTEGER,
                             pNuMesReferencia      IN INTEGER)

    RETURN BOOLEAN IS

    vCont              INTEGER;

    vNuRubrica         INTEGER;

    vCdRubricaAgrupTp1 INTEGER;

  BEGIN

    SELECT nuRubrica
      INTO vNuRubrica
      FROM ePagRubrica R
     WHERE R.CdRubrica = (SELECT cdRubrica
                            FROM epagRubricaAgrupamento
                           WHERE cdRubricaAgrupamento = pCdRubricaAgrupamento);

    SELECT CdRubricaAgrupamento
      INTO vCdRubricaAgrupTp1
      FROM epagRubricaAgrupamento RA
     WHERE RA.CdAgrupamento = pcdAgrupamento AND
           RA.cdRubrica = (SELECT cdRubrica
                             FROM epagRubrica WHERE CdTipoRubrica = 1 AND nuRubrica = vNuRubrica);

     SELECT COUNT(*)
       INTO vCont
       FROM EPagRubricaAgrupamento RA
      INNER JOIN ePagBaseCalculo BC ON RA.CdBaseCalculo = BC.CdBaseCalculo
      INNER JOIN EpagBaseCalculoVersao BCV ON BC.CdBaseCalculo = BCV.CdBaseCalculo
      INNER JOIN EPagHistBaseCalculo HBC ON HBC.CdVersaoBaseCalculo = BCV.CdVersaoBaseCalculo
      INNER JOIN EPagBaseCalculoBloco BCB ON HBC.CdHistBaseCalculo = BCB.Cdhistbasecalculo
      INNER JOIN Epagbasecalculoblocoexpressao BCE ON BCB.CdBaseCalculoBloco = BCE.CdBaseCalculoBloco
      INNER JOIN Epagbasecalcblocoexprrubagrup BCRA ON BCE.CdBaseCalculoBlocoExpressao = BCRA.CdBaseCalculoBlocoExpressao
      WHERE RA.CdModalidadeRubrica = 27 -- olha o hard code ai gente!
            AND RA.CdAgrupamento = pCdAgrupamento
            AND BCV.NuVersao = 1
            AND BCRA.CdRubricaAgrupamento = vCdRubricaAgrupTp1
            AND (HBC.NuAnoInicioVigencia < pNuAnoReferencia OR
                (HBC.NuAnoInicioVigencia = pNuAnoReferencia AND
                 HBC.NuMesInicioVigencia <= pNuMesReferencia))
            AND (HBC.NuAnoFimVigencia > pNuAnoReferencia OR
                (HBC.NuAnoFimVigencia = pNuAnoReferencia AND
                HBC.NuMesFimVigencia >= pNuMesReferencia) OR
                HBC.NuAnoFimVigencia IS NULL);

     IF nvl(vCont,0) > 0 THEN

       RETURN TRUE;

     ELSE

       RETURN FALSE;

     END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN TRUE;

  END;

BEGIN

  vVlBloqueio := 0;

  -- Processa o bloqueio de remuneracao de retroativos
  -- Processo cancelado a partir de Julho/2010 em decorrencia de implementacao
  -- do processo de retroativos na aplicacao

  IF PKGPAG_VAR.bProcessaBloqueio  AND
     (pFolha.NuAnoReferencia < 2010 OR (pFolha.NuAnoReferencia = 2010 AND pFolha.NuMesReferencia < 7)) THEN

    -- Para cada mes
    FOR vRetro IN (SELECT RD.CdRubricaAgrupamento,
                          RD.NuMesCompetencia,
                          SUM(NVL(RD.VlRestituirComIncidencia,0) + NVL(RD.Vlrestituirsemincidencia,0)) VlRestituicao
                     FROM ERetprocessoRestituicoesDevida RD
                    INNER JOIN ERetProcessoPagRetroativo RT
                       ON RD.CdProcessoPagRetroativo = RT.CdProcessoPagRetroativo
                    INNER JOIN EPagRubricaAgrupamento RA
                       ON RD.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
                    INNER JOIN EPagRubrica R
                       ON R.CdRubrica = RA.CdRubrica
                    WHERE RT.CdVinculo = pCdVinculo AND
                          R.CdTipoRubrica = 2 AND
                          RD.NuAnoCompetencia = pFolha.NuAnoReferencia AND
                          RT.FlAnulado = 'N'
                    GROUP BY RD.CdRubricaAgrupamento,
                             RD.NuMesCompetencia
                   HAVING SUM(NVL(RD.VlRestituirComIncidencia,0) + NVL(RD.Vlrestituirsemincidencia,0)) > 0)
    LOOP

      BEGIN

        --- Busca o valor da base
        SELECT HRV.CdFolhaPagamento,
               HRV.VlPagamento,
               FP.NuAnoReferencia,
               FP.NuMesReferencia
          INTO vCdFolhaRetro,
               vVlBaseTeto,
               vNuAnoRefRetro,
               vNuMesRefRetro
          FROM EPagFolhaPagamento FP
         INNER JOIN EPagHistoricoRubricaVinculo HRV
            ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
         INNER JOIN EPagTipoFolhaPagamento TFP
            ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
         WHERE HRV.CdVinculo = pCdVinculo AND
               FP.CdOrgao = pFolha.CdOrgao AND
               FP.NuMesReferencia  = vRetro.NuMesCompetencia AND
               FP.NuAnoReferencia  = pFolha.NuAnoReferencia AND
               FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
               TFP.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
               HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTetoGov;

        vVlReferencia := RetornaValorRefBloqRemun(pCdVinculo,
                                                  pFolha.CdAgrupamento,
                                                  vCdFolhaRetro,
                                                  vNuAnoRefRetro,
                                                  vNuMesRefRetro);

        IF FDeveSomarRubrica(vRetro.CdRubricaAgrupamento,
                             pFolha.CdAgrupamento,
                             vNuAnoRefRetro,
                             vNuMesRefRetro) THEN

          IF (vVlBaseTeto + vVlBloqueio) >= vVlReferencia THEN

            vVlBloqueio := vVlBloqueio + vRetro.VlRestituicao;

          ELSE

            vVlBloqueio := vVlBloqueio + ((vRetro.VlRestituicao + vVlBaseTeto) - vVlReferencia);

          END IF;

        END IF;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          NULL;

      END;

    END LOOP;

    IF vVlBloqueio > 0 THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBloqRetroativo,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => vVlBloqueio,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRet,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => vVlBloqueio,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

    END IF;

  END IF;

  -- Se o vinculo possuir cargo efetivo, busca formula por Carreira

  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

    vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

  ELSIF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

    vCdEstruturaCarreira := PKGPAG_VAR.vgAPO(1).CdEstruturaCarreira;

  else
    null;
  END IF;

  vCdExpressaoFormCalc :=

       PKGPAG_GERAL.FIdentificaFormulaCalculo(
                    pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                    pCdRubricaAgrupamento     => pCdRubricaAgrupamento,
                    pCdRelacaoVinculo         => 0,
                    pCdEstruturaCarreira      => vCdEstruturaCarreira);

  IF vCdExpressaoFormCalc > 0 THEN

   -- Geracao do 5983 - Valor do bloqueio

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                          pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => 0,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

    PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => pCdRubricaAgrupamento,
                                     pTpProcessamento => 1,
                                     pTpLocal         => 2); /*Vinculo*/

    -----------------------------------------------------------------------------
    -- Recupera valor do bloqueio
    -----------------------------------------------------------------------------

     vVlRubDescTetoGov := PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                            pCdVinculo,
                                                            pCdRubricaAgrupamento);

     IF vVlRubDescTetoGov > 0 THEN

       -------------------------------------------------------------------------
       -- Se a rubrica do deposito judicial esta lancada em Decisao Judicial
       -------------------------------------------------------------------------
       IF PKGPAG_GERAL.FPossuiDecisaoJudicial(pCdVinculo,
                                              pFolha.NuAnoReferencia,
                                              pFolha.NuMesReferencia,
                                              PKGPAG_VAR.vgCdRubDepositoJud,
                                              vVlDepositoJud,
                                              vCdValRefDepJud,
                                              vDtInicioDireito,
                                              vDtInclusao) THEN

         IF NVL(vVlDepositoJud,0) = 0 AND vCdValRefDepJud IS NULL THEN

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDepositoJud ,
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vVlRubDescTetoGov,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 1);

         ELSIF NVL(vVlDepositoJud,0) > 0 AND vCdValRefDepJud IS NULL THEN

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDepositoJud ,
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vVlDepositoJud,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 1);

         ELSIF NVL(vVlDepositoJud,0) = 0 AND vCdValRefDepJud IS NOT NULL THEN

           vVlPago := PKGPAG_VAR.vgValorReferencia(vCdValRefDepJud).VlReferencia -
                      PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                       pCdVinculo        => pCdVinculo,
                                                       pCdRubrica        => PKGPAG_VAR.vgCdRubricaTetoGov);

           IF vVlPago > 0 THEN

             IF vVlPago > vVlRubDescTetoGov THEN

               vVlPago :=  vVlRubDescTetoGov;

             END IF;

             PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                                   pCdVinculo            => pCdVinculo,
                                                   pCdExpressaoFormCalc  => NULL,
                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDepositoJud ,
                                                   pNuSufixoRubrica      => 1,
                                                   pVlPagamento          => vVlPago,
                                                   pVlIndice             => NULL,
                                                   pCdTipoOrigemRubrica  => 1);

           END IF;

         else
           null;
         END IF;

         ------------------------------------------------------------------
         -- Deposito em juizo retroativo
         ------------------------------------------------------------------

        IF TRUNC(vDtInclusao) BETWEEN (PKGPAG_VAR.vDtCalculoAnt + 1) AND  PKGPAG_VAR.vDtCalculo THEN

           IF vDtInicioDireito < pFolha.DtInicioMes THEN

             vNuMesesRetro := MONTHS_BETWEEN(TRUNC(pFolha.dtInicioMes,'MM'), trunc(vDtInicioDireito,'MM'));

             IF NVL(vVlDepositoJud,0) = 0 AND vCdValRefDepJud IS NULL THEN

               -- Acumular o valor do vVlRubDescTetoGov nos meses anteriores em VLDESCTETOGOVMESESANT

               vNuAnoMesInicio := to_number(TO_CHAR(vDtInicioDireito, 'YYYYMM'));

               IF pFolha.NuMesReferencia = 1 THEN

                 vNuAnoMesFim := to_number((TO_CHAR(pFolha.NuAnoReferencia,'YYYY') - 1) || '12');
               ELSE

                 vNuAnoMesFim := to_number(LPAD(pFolha.NuAnoReferencia,4,'0') || LPAD((pFolha.NuMesReferencia -1),2,'0'));

               END IF;

               SELECT SUM(vlPagamento)
                 INTO vVlDescTetoGovMesesAnt
                 FROM EPagHistoricoRubricaVinculo HRV
                INNER JOIN EPagFolhaPagamento FP
                   ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
                INNER JOIN EPagTipoFolhaPagamento TFP
                   ON FP.CdTipoFolhaPagamento =  TFP.CdTipoFolhaPagamento
                WHERE HRV.CdVinculo = pCdVinculo AND
                      HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento AND
                      FP.CdOrgao = pFolha.CdOrgao AND
                      TFP.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
                      FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                      to_number(LPAD(FP.NuAnoReferencia,4,'0') || LPAD(FP.NuMesReferencia,2,'0'))
                      BETWEEN vNuAnoMesInicio AND vNuAnoMesFim;

                IF NVL(vVlDescTetoGovMesesAnt,0) > 0 THEN

                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento      => pFolha.CdFolhaPagamento,
                                                        pCdVinculo             => pCdVinculo,
                                                        pCdExpressaoFormCalc   => NULL,
                                                        pCdRubricaAgrupamento  => PKGPAG_VAR.vgCdRubDepositoJud ,
                                                        pNuSufixoRubrica       => 9,
                                                        pVlPagamento           => vVlDescTetoGovMesesAnt,
                                                        pVlIndice              => NULL,
                                                        pCdTipoOrigemRubrica   => 1);
                END IF;

              ELSIF NVL(vVlDepositoJud,0) > 0 AND vCdValRefDepJud IS NULL THEN

                     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                           pCdVinculo            => pCdVinculo,
                                                           pCdExpressaoFormCalc  => NULL,
                                                           pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDepositoJud ,
                                                           pNuSufixoRubrica      =>  9,
                                                           pVlPagamento          => vVlDepositoJud * vNuMesesRetro,
                                                           pVlIndice             => NULL,
                                                           pCdTipoOrigemRubrica  => 1);

              ELSIF NVL(vVlDepositoJud,0) = 0 AND vCdValRefDepJud IS NOT NULL THEN

                  IF vVlPago > 0 THEN

                     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                                           pCdVinculo            => pCdVinculo,
                                                           pCdExpressaoFormCalc  => NULL,
                                                           pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDepositoJud ,
                                                           pNuSufixoRubrica      => 9,
                                                           pVlPagamento          => vVlPago * vNuMesesRetro,
                                                           pVlIndice             => NULL,
                                                           pCdTipoOrigemRubrica  => 1);

                  END IF;

              else
                null;
              END IF;

           END IF;

         END IF;

       END IF;

    END IF;

  END IF;

END;

PROCEDURE PDescontoTetoGovernador13(pCdVinculo             IN INTEGER,
                                     pFolha                 IN PKGPAG_TIPO.rFolha,
                                     pCdRubricaAgrupamento  IN INTEGER) IS

  vCdExpressaoFormCalc INTEGER;

  vCdEstruturaCarreira INTEGER DEFAULT NULL;

  vVlRubDescTetoGov    NUMBER(13,2);

BEGIN

  -- Se o vinculo possuir cargo efetivo, busca formula por Carreira

  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

    vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

  ELSIF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

    vCdEstruturaCarreira := PKGPAG_VAR.vgAPO(1).CdEstruturaCarreira;

  else
    null;
  END IF;

  vCdExpressaoFormCalc :=

       PKGPAG_GERAL.FIdentificaFormulaCalculo(
                    pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                    pCdRubricaAgrupamento     => pCdRubricaAgrupamento,
                    pCdRelacaoVinculo         => 0,
                    pCdEstruturaCarreira      => vCdEstruturaCarreira);

  IF vCdExpressaoFormCalc > 0 THEN

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                          pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => 0,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

    PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => pCdRubricaAgrupamento,
                                     pTpProcessamento => 1,
                                     pTpLocal         => 2); /*Vinculo*/

    -----------------------------------------------------------------------------
    -- Geracao de rubrica associada a modalidade  "Teto do Governador"
    -----------------------------------------------------------------------------

     vVlRubDescTetoGov := PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                            pCdVinculo,
                                                            pCdRubricaAgrupamento);

     IF vVlRubDescTetoGov > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaTetoGov,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => RetornaValorRefBloqRemun(pCdVinculo,
                                                                                               pFolha.CdAgrupamento,
                                                                                               pFolha.CdFolhaPagamento,
                                                                                               pFolha.NuAnoReferencia,
                                                                                               pFolha.NuMesReferencia),
                                             pVlIndice             => NULL,
                                             pCdTipoOrigemRubrica  => 1);

    END IF;

  END IF;

END;

PROCEDURE PDescontoPlanoSaudeTitular(pCdVinculo                IN INTEGER,
                                     pFolha                    IN PKGPAG_TIPO.rFolha,
                                     pRubrica                  IN PKGPAG_TIPO.rRubrica) IS

  vRegistro            ESauImpSistemaExterno%ROWTYPE;

  vCdExpressaoFormCalc INTEGER;

  vNuAno               INTEGER;

  vNuMes               INTEGER;

  vNuIndice              INTEGER;

  vVlScSaudeDecJudicial NUMBER(13,2) :=0;

  vVlBasePlanoSaude     NUMBER(13,2) :=0;

BEGIN

  IF (NVL(PKGPAG_VAR.vgVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax)
       BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
     (PKGPAG_VAR.vgVinculo.DtAdmissao
       BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

    vNuIndice :=  NVL(PKGPAG_VAR.vgVinculo.DtDesligamento, pFolha.DtFimMes)
                  - GREATEST(PKGPAG_VAR.vgVinculo.DtAdmissao,pFolha.DtInicioMes);

    IF vNuIndice > 30 THEN

      vNuIndice := 30;

    END IF;

  ELSE

      vNuIndice := 30;

  END IF;

  IF pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast) AND
     FPossuiProventos(pFolha     => pFolha,
                      pCdVinculo => pCdVinculo) THEN

    BEGIN

      IF PKGPAG_VAR.bTemPlanoSaudeSaudeNoMes THEN

          vNuAno := pFolha.NuAnoReferencia;

          vNuMes := pFolha.NuMesReferencia;

        ELSE

          IF pFolha.NuMesReferencia = 1 THEN

            vNuMes := 12;

            vNuAno := pFolha.NuAnoReferencia - 1;

          ELSE

            vNuMes := pFolha.NuMesReferencia - 1;

            vNuAno := pFolha.NuAnoReferencia;

          END IF;

      END IF;

      BEGIN

      SELECT SE.*
        INTO vRegistro
        FROM ESauImpSistemaExterno SE
       INNER JOIN ECadOrgao O
         ON O.CdOrgao = SE.CdOrgao AND
            O.CdAgrupamento = pFolha.CdAgrupamento
       WHERE SE.CdVinculo = pCdVinculo AND
             SE.NuAnoCompetencia = vNuAno AND
             SE.NuMesCompetencia = vNuMes;

      EXCEPTION
        WHEN OTHERS THEN
          NULL;

      END;

       -- RUBRIDA 05-0167 SCSAUDE DEC JUD

       vVlBasePlanoSaude :=  PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                                               pCdVinculo         => pCdVinculo,
                                                               pCdRubrica         => PKGPAG_VAR.vgCdRubricaBasePlanoSaude);

       vVlScSaudeDecJudicial :=  least(nvl(vRegistro.Vldecisaojudicial,0),(vVlBasePlanoSaude * 0.2)) ;

        if nvl(vVlScSaudeDecJudicial,0) > 0
          then

            PKGPAG_LF.PGeracaoLancamentoValor(pFolha                  => pFolha,
                                    pCdVinculo              => pCdVinculo,
                                    pCdRubricaAgrupamento   => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                                            pCdTipoRubrica => 5,
                                                                                            pNuRubrica     => 167),
                                    pNuSufixoRubrica        => 1,
                                    pNuParcelasProc         => NULL,
                                    pInPossuiValorInformado => 0,
                                    pVlLancamento           => vVlScSaudeDecJudicial,
                                    pVlIndice               => NULL,
                                    pCdTipoOrigemRubrica    => 3,
                                    pVlReal                 => vVlScSaudeDecJudicial);

           PKGPAG_LF.PGeracaoLancamentoValor(pFolha            => pFolha,
                                    pCdVinculo              => pCdVinculo,
                                    pCdRubricaAgrupamento   => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                                            pCdTipoRubrica => 5,
                                                                                            pNuRubrica     => 167),
                                    pNuSufixoRubrica        => 1,
                                    pNuParcelasProc         => NULL,
                                    pInPossuiValorInformado => 1,
                                    pVlLancamento           => vVlScSaudeDecJudicial,
                                    pVlIndice               => NULL,
                                    pCdTipoOrigemRubrica    => 3,
                                    pVlReal                 => vVlScSaudeDecJudicial);

        end if;

       IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) AND
          vRegistro.FlTitularAtivo = PKGPAG_TIPO.cnS THEN

         vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                                        pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                                                        pCdRelacaoVinculo         => 0);

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                               pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => vNuIndice,
                                               pCdTipoOrigemRubrica  => 9);

         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => pRubrica.CdRubricaAgrupamento,
                                          pTpProcessamento => 1,
                                          pTpLocal         => 2); /*Vinculo*/

      END IF;

      IF NVL(vRegistro.VlRestituicaoTitular,0) > 0 THEN

        IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 4, pRubrica.NuRubrica)) THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                      4,
                                                                                                      pRubrica.NuRubrica),
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => vRegistro.VlRestituicaoTitular,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 9);
        END IF;

      END IF;

      IF NVL(vRegistro.VlDiferencaTitular,0) > 0 AND
        (PKGPAG_VAR.vgVinculo.DtDesligamento >= pFolha.DtInicioMes OR PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL) THEN

        IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 6, pRubrica.NuRubrica)) THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                     6,
                                                                                                     pRubrica.NuRubrica),
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => vRegistro.VlDiferencaTitular,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 9);
        END IF;

      END IF;

      -- Gera registros de rubricas totalizadoras de modalidades 41 e 42

      IF NVL(PKGPAG_VAR.vgCdRubBaseSCSAUDEOutros,0) > 0
        AND PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                           pCdVinculo        => pCdVinculo,
                                           pCdRubrica        => PKGPAG_VAR.vgCdRubricaBasePlanoSaude) > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseSCSAUDEOutros,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 9);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => PKGPAG_VAR.vgCdRubBaseSCSAUDEOutros,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDeducaoSCSAUDEOutros,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 9);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => PKGPAG_VAR.vgCdRubDeducaoSCSAUDEOutros,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        -- Caso nao encontre registro na tabela ESauImpSistemaExterno
        -- exclui a rubrica da base do PATRONAL SC-SAUDE

        PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                    pCdVinculo        => pCdVinculo,
                                    pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                      9,
                                                                                      1018),
                                    pFlExcluiAmbos    => 'S');

      WHEN TOO_MANY_ROWS THEN

       PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Foi encontrado mais de um registro de desconto de titular do plano de saúde.',
                               PKGPAG_VAR.vgCdVinculo);

    END;

  END IF;

END;

PROCEDURE PVlPlanoSaudeAgregOutrosVinc(pCdVinculo IN INTEGER,
                                       pFolha     IN PKGPAG_TIPO.rFolha,
                                       pVlBaseOutrosVinculos OUT NUMBER,
                                       pVlContribuicaoOutrosVinculos OUT NUMBER) IS

   vNuAno INTEGER;
   vNuMes INTEGER;

   vCdTipoRubrica pls_integer;
   vNuRubrica pls_integer;

BEGIN

   IF PKGPAG_VAR.bTemPlanoSaudeSaudeNoMes THEN

      vNuAno := pFolha.NuAnoReferencia;

      vNuMes := pFolha.NuMesReferencia;

    ELSE

      IF pFolha.NuMesReferencia = 1 THEN

        vNuMes := 12;

        vNuAno := pFolha.NuAnoReferencia - 1;

      ELSE

        vNuMes := pFolha.NuMesReferencia - 1;

        vNuAno := pFolha.NuAnoReferencia;

      END IF;

    END IF;

   -- 09-0937-01 BASE DE CONTRIBUICAO SCSAUDE
   vCdTipoRubrica := 9;
   vNuRubrica := 937;
   /***** ATENÇÃO *****

     O plano de execucao dessa query foi fixado no oracle.
     Qualquer minima alteracao nela vai afetar a performance do calculo.
     Se for necessario mexer nela, falar comigo depois. Tiago

   ****** ATENÇÃO ********************************************************/
   select NVL(sum(hrv.vlpagamento), 0)
     into pVlBaseOutrosVinculos
     from epagfolhapagamento fp
    inner join epaghistoricorubricavinculo hrv on hrv.cdfolhapagamento = fp.cdfolhapagamento
    inner join epagrubricaagrupamento ra on ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
    inner join epagrubrica r on r.cdrubrica = ra.cdrubrica
    where fp.nuanoreferencia = pFolha.NuAnoReferencia
      and fp.numesreferencia = pFolha.NuMesReferencia
      and fp.cdtipocalculo = pFolha.CdTipoCalculo
      and hrv.cdvinculo in (select v2.cdvinculo
                              from ecadvinculo v
                             inner join ecadpessoa p on p.cdpessoa = v.cdpessoa
                             inner join ecadvinculo v2 on v2.cdpessoa = p.cdpessoa
                             inner join ESauImpSistemaExterno s on s.cdvinculo = v2.cdvinculo
                                                               and s.nuanocompetencia = vNuAno
                                                               and s.numescompetencia = vNuMes
                                                               and s.fltitularativo = 'S'
                             where v.cdvinculo = pCdVinculo
                               and v2.cdvinculo <> pCdVinculo)
      and r.cdtiporubrica = vCdTipoRubrica
      and r.nurubrica = vNuRubrica;

   -- 05-0839-01 SCSAUDE-AGREGADOS
   vCdTipoRubrica := 5;
   vNuRubrica := 839;
   /***** ATENÇÃO *****

     O plano de execucao dessa query foi fixado no oracle.
     Qualquer minima alteracao nela vai afetar a performance do calculo.
     Se for necessario mexer nela, falar comigo depois. Tiago

   ****** ATENÇÃO ********************************************************/
   select NVL(sum(hrv.vlpagamento), 0)
     into pVlContribuicaoOutrosVinculos
     from epagfolhapagamento fp
    inner join epaghistoricorubricavinculo hrv on hrv.cdfolhapagamento = fp.cdfolhapagamento
    inner join epagrubricaagrupamento ra on ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
    inner join epagrubrica r on r.cdrubrica = ra.cdrubrica
    where fp.nuanoreferencia = pFolha.NuAnoReferencia
      and fp.numesreferencia = pFolha.NuMesReferencia
      and fp.cdtipocalculo = pFolha.CdTipoCalculo
      and hrv.cdvinculo in (select v2.cdvinculo
                              from ecadvinculo v
                             inner join ecadpessoa p on p.cdpessoa = v.cdpessoa
                             inner join ecadvinculo v2 on v2.cdpessoa = p.cdpessoa
                             inner join ESauImpSistemaExterno s on s.cdvinculo = v2.cdvinculo
                                                               and s.nuanocompetencia = vNuAno
                                                               and s.numescompetencia = vNuMes
                                                               and s.fltitularativo = 'S'
                             where v.cdvinculo = pCdVinculo
                               and v2.cdvinculo <> pCdVinculo)
      and r.cdtiporubrica = vCdTipoRubrica
      and r.nurubrica = vNuRubrica;

EXCEPTION
  WHEN OTHERS THEN
    pVlBaseOutrosVinculos := 0;
    pVlContribuicaoOutrosVinculos := 0;

END;

procedure pDescontoPlanoSaude (pCdVinculo in integer) is


  vVlRubrica number(13,2);

  vVlCalculadoRubrica pkgpag_tipo.rValorPagamento;

begin

  IF PKGPAG_VAR.bPossuiAct AND PKGPAG_VAR.vgFolha.CdAgrupamento = 1 THEN
    RETURN;
  END IF;

  IF PKGPAG_VAR.vgCdRubricaBasePlanoSaude > 0 THEN

     PKGPAG_FB.PAtualizaBaseCalculo(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdVinculo        => pCdVinculo,
                                    pCdRubrica        => PKGPAG_VAR.vgCdRubricaBasePlanoSaude);
  END IF;

  -------------------------------------------------------------------------------
  -- Desconto de plano de saude de titular
  -------------------------------------------------------------------------------

  IF PKGPAG_VAR.vgCdRubDescPlanSauTit IS NOT NULL THEN

    PKGPAG_POS.PDescontoPlanoSaudeTitular(pCdVinculo => pCdVinculo,
                                          pFolha     => PKGPAG_VAR.vgFolha,
                                          pRubrica   => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubDescPlanSauTit));

    PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,pCdVinculo);

    if (PKGPAG_VAR.vgVlTotalProventos < PKGPAG_VAR.vgVlTotalDescontos)
      and  PKGPAG_VAR.vgFolha.cdOrgao <> 33 then

       vVlRubrica := 0;

       vVlRubrica := PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                       pCdVinculo,
                                                       PKGPAG_VAR.vgCdRubDescPlanSauTit) -
                                                       (PKGPAG_VAR.vgVlTotalDescontos - PKGPAG_VAR.vgVlTotalProventos);

       vVlCalculadoRubrica.vlIntegral := vVlRubrica;

       pkgpag_cal.pAtualizaValorRubrica(pCdVinculo,  PKGPAG_VAR.vgFolha.CdFolhaPagamento, PKGPAG_VAR.vgCdRubDescPlanSauTit, vVlCalculadoRubrica);


       PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,pCdVinculo);

    end if;

  END IF;

  ---------------------------------------------------------------------------------
  -- Patronal de SC saude
  ---------------------------------------------------------------------------------

  IF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                       pCdVinculo        => pCdVinculo,
                                       pCdRubrica        => PKGPAG_VAR.vgCdRubricaBasePSPatronal) = 0 THEN

    IF NVL(PKGPAG_VAR.vgCdRubricaBasePSPatronal, 0) > 0 THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBasePSPatronal,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

    END IF;

  END IF;

  IF NVL(PKGPAG_VAR.vgCdRubricaBasePSPatronal, 0) > 0 THEN

    PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => PKGPAG_VAR.vgCdRubricaBasePSPatronal,
                                     pTpProcessamento => 2, -- Processa base de calculo
                                     pTpLocal         => 2); -- no vinculo
  END IF;

  --------------------------------------------------------------------------------
  -- Desconto de plano de saude de agregados
  --------------------------------------------------------------------------------

  IF (PKGPAG_VAR.vgCdRubDescPlanSauAgr IS NOT NULL and
     PKGPAG_VAR.vgVlTotalProventos > PKGPAG_VAR.vgVlTotalDescontos)

    THEN

    PKGPAG_POS.PDescontoPlanoSaudeAgreg(pCdVinculo => pCdVinculo,
                                        pFolha     => PKGPAG_VAR.vgFolha,
                                        pRubrica   => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubDescPlanSauAgr));

    PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,pCdVinculo);

    if PKGPAG_VAR.vgVlTotalProventos < PKGPAG_VAR.vgVlTotalDescontos then

       vVlRubrica := 0;

       vVlRubrica := PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                       pCdVinculo,
                                                       PKGPAG_VAR.vgCdRubDescPlanSauAgr) -
                                                       (PKGPAG_VAR.vgVlTotalDescontos - PKGPAG_VAR.vgVlTotalProventos);

       vVlCalculadoRubrica.vlIntegral := vVlRubrica;

       pkgpag_cal.pAtualizaValorRubrica(pCdVinculo,  PKGPAG_VAR.vgFolha.CdFolhaPagamento, PKGPAG_VAR.vgCdRubDescPlanSauAgr, vVlCalculadoRubrica);

       PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,pCdVinculo);

    end if;

  END IF;

  --------------------------------------------------------------------------------
  -- Desconto de co-participacao
  --------------------------------------------------------------------------------

  IF (PKGPAG_VAR.vgCdEventoDescCoPart IS NOT NULL and
     PKGPAG_VAR.vgVlTotalProventos > PKGPAG_VAR.vgVlTotalDescontos)
     OR PKGPAG_VAR.vgFolha.cdorgao = 33 THEN

     IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
        PKGPAG_VAR.vgFolha.FlCalculoDefinitivo = 'S' THEN
        pkgpag_cal.PZerarValorPgtoCopPlanoSaude(pCdVinculo => pCdVinculo,
                                                pNuAnoreferencia => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                pNuMesReferencia => PKGPAG_VAR.vgFolha.NuMesReferencia);
     END IF;

    PKGPAG_POS.PDescontoCoParticipacao(pCdVinculo           => pCdVinculo,
                                       pFolha               => PKGPAG_VAR.vgFolha,
                                       pRubrica             => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoDescCoPart)
                                                                                    .CdRubricaAgrupamento),
                                       pEvento              => PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoDescCoPart),
                                       pFlCalculoDefinitivo => pkgpag_var.vgFolha.FlCalculoDefinitivo);

     PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,pCdVinculo);

    if PKGPAG_VAR.vgVlTotalProventos < PKGPAG_VAR.vgVlTotalDescontos then

       vVlRubrica := 0;

       vVlRubrica := PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                       pCdVinculo,
                                                       PKGPAG_VAR.vgCdEventoDescCoPart) -
                                                       (PKGPAG_VAR.vgVlTotalDescontos - PKGPAG_VAR.vgVlTotalProventos);

       vVlCalculadoRubrica.vlIntegral := vVlRubrica;

       pkgpag_cal.pAtualizaValorRubrica(pCdVinculo,  PKGPAG_VAR.vgFolha.CdFolhaPagamento, PKGPAG_VAR.vgCdEventoDescCoPart, vVlCalculadoRubrica);

       PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,pCdVinculo);

    end if;

  end if;

end;

PROCEDURE PDescontoPlanoSaudeAgreg(pCdVinculo IN INTEGER,
                                   pFolha     IN PKGPAG_TIPO.rFolha,
                                   pRubrica   IN PKGPAG_TIPO.rRubrica) IS

  vRegistro            ESauImpSistemaExterno%ROWTYPE;

  vvlContribuicao                   NUMBER(13,2) := 0;

  vvlBaseOutrosVinculos             NUMBER(13,2) := 0;

  vvlContribuicaoOutrosVinculos     NUMBER(13,2) := 0;

  vvlContribuicaoAjustado           NUMBER(13,2) := 0;

  vNuMes               INTEGER;

  vNuAno               INTEGER;

BEGIN

  IF pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast) AND
     PKGPAG_VAR.vgValorBasePlanoSaude > 0  THEN

    BEGIN

      PVlPlanoSaudeAgregOutrosVinc(pCdVinculo => pCdVinculo,
                                   pFolha => pFolha,
                                   pVlBaseOutrosVinculos => vVlBaseOutrosVinculos,
                                   pVlContribuicaoOutrosVinculos => vVlContribuicaoOutrosVinculos);

      IF PKGPAG_VAR.bTemPlanoSaudeSaudeNoMes THEN

        vNuAno := pFolha.NuAnoReferencia;

        vNuMes := pFolha.NuMesReferencia;

      ELSE

        IF pFolha.NuMesReferencia = 1 THEN

          vNuMes := 12;

          vNuAno := pFolha.NuAnoReferencia - 1;

        ELSE

          vNuMes := pFolha.NuMesReferencia - 1;

          vNuAno := pFolha.NuAnoReferencia;

        END IF;

      END IF;

      SELECT *
        INTO vRegistro
        FROM ESauImpSistemaExterno SE
       WHERE SE.CdVinculo = pCdVinculo AND
             SE.NuAnoCompetencia = vNuAno AND
             SE.NuMesCompetencia = vNuMes;

       IF PKGPAG_VAR.vgContribPlanoSaudeAgregado.COUNT > 0
         THEN

         -- Verificar valor sem considerar outros vínculos

         FOR iCon IN PKGPAG_VAR.vgContribPlanoSaudeAgregado.FIRST .. PKGPAG_VAR.vgContribPlanoSaudeAgregado.LAST
         LOOP

           IF PKGPAG_VAR.vgValorBasePlanoSaude BETWEEN
              PKGPAG_VAR.vgContribPlanoSaudeAgregado (iCon).VlMinimo AND
              PKGPAG_VAR.vgContribPlanoSaudeAgregado (iCon).VlMaximo

              THEN

                vvlContribuicao := PKGPAG_VAR.vgContribPlanoSaudeAgregado(iCon).VlAgregado*
                                   (NVL(vRegistro.QtAgregadoCompAnterior,0) +
                                    NVL(vRegistro.QtAgregadoInserido,0) -
                                    NVL(vRegistro.QtAgregadoExcluido,0));

                EXIT;

           END IF;

         END LOOP;

         -- Verificar valor somando bases de outros vínculos

         FOR iCon IN PKGPAG_VAR.vgContribPlanoSaudeAgregado.FIRST .. PKGPAG_VAR.vgContribPlanoSaudeAgregado.LAST
         LOOP

           IF PKGPAG_VAR.vgValorBasePlanoSaude + vVlBaseOutrosVinculos BETWEEN
              PKGPAG_VAR.vgContribPlanoSaudeAgregado (iCon).VlMinimo AND
              PKGPAG_VAR.vgContribPlanoSaudeAgregado (iCon).VlMaximo

              THEN

                vvlContribuicaoAjustado :=  greatest(0,PKGPAG_VAR.vgContribPlanoSaudeAgregado(iCon).VlAgregado*
                                            (NVL(vRegistro.QtAgregadoCompAnterior,0) +
                                             NVL(vRegistro.QtAgregadoInserido,0) -
                                             NVL(vRegistro.QtAgregadoExcluido,0)) -
                                             NVL(vvlContribuicaoOutrosVinculos,0));

                EXIT;

           END IF;

         END LOOP;

       ELSE

          PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  PKGPAG_VAR.vCdHistParamCalc,
                                  PKGPAG_VAR.vCdPessoa,
                                  'Não foram encontradas faixas de valores plano de saúde para ano/mês de referencia.',
                                  PKGPAG_VAR.vgCdVinculo);

       END IF;




       -- Limita o valor ajustado ao valor que deveria ser descontado do vinculo que está sendo calculado
       vvlContribuicao := least(vvlContribuicao,vvlContribuicaoAjustado);

       IF NVL(vvlContribuicao,0) > 0 AND PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento)  THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => vvlContribuicao,
                                               pVlIndice             => (NVL(vRegistro.QtAgregadoCompAnterior,0) +
                                                                         NVL(vRegistro.QtAgregadoInserido,0) -
                                                                         NVL(vRegistro.QtAgregadoExcluido,0)),
                                               pCdTipoOrigemRubrica  => 9);

      END IF;

      IF NVL(vRegistro.VlRestituicaoAgregado,0) > 0 THEN

        IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 4, pRubrica.NuRubrica)) THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento   => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                         4,
                                                                                         pRubrica.NuRubrica),
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => vRegistro.VlRestituicaoAgregado,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 9);
        END IF;

      END IF;

       IF NVL(vRegistro.VlDiferencaAgregado,0) > 0 THEN

        IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 6, pRubrica.NuRubrica)) THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                         6,
                                                                                         pRubrica.NuRubrica),
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => vRegistro.VlDiferencaAgregado,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 9);

        END IF;

      END IF;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        NULL;

      WHEN TOO_MANY_ROWS THEN

       PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Foi encontrado mais de um registro de desconto de agregados do plano de saúde.',
                               PKGPAG_VAR.vgCdVinculo);

    END;

  END IF;

END;

PROCEDURE PDescontoCoParticipacao(pCdVinculo           IN INTEGER,
                                  pFolha               IN PKGPAG_TIPO.rFolha,
                                  pRubrica             IN PKGPAG_TIPO.rRubrica,
                                  pEvento              IN PKGPAG_TIPO.rEvento,
                                  pFlCalculoDefinitivo IN CHAR) IS

  vRegistro                   ESauImpSistemaExterno%ROWTYPE;
  vvlCoParticipacaoUnimed    NUMBER(13,2) := 0;
  vvlCoParticipacaoGP        NUMBER(13,2) := 0;
  vvlCoParticipacaoUniSanta  NUMBER(13,2) := 0;
  vvlCoParticIPESC           NUMBER(13,2) := 0;
  vvlDescontoCoPartLimite    NUMBER(13,2) := 0;
  vvlCoParticipacaoJudicial  NUMBER(13,2) := 0;
  --vvlDevolCoParticipacaoJudicial  NUMBER(13,2) := 0;
  --vvlSaldoCoParticipacaoJudicial  NUMBER(13,2) := 0;
  vRubrica                   PKGPAG_TIPO.rRubrica;
  vvlPagoCoParticIPESC NUMBER(13,2) := 0;
  vvlPagoCoParticipacaoGP NUMBER(13,2) := 0;
  vvlPagoCoParticipacaoUniSanta NUMBER(13,2) := 0;
  vvlPagoCoParticipacaoJudicial NUMBER(13,2) := 0;
  vvlPagoCoParticipacaoUnimed NUMBER(13,2) := 0;
  --vPagDecisaoJudicial PKGPAG_LF.cPagDecisaoJudicial%ROWTYPE;

BEGIN

  IF pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast ) AND
     FPossuiProventos(pFolha     => pFolha,
                      pCdVinculo => pCdVinculo)  THEN


    /*--------------------------------------------------------------------------------*/
    /* Recalcula a base associada ao desconto de co-participacao
    /*--------------------------------------------------------------------------------*/

     delete EPAGHISTORICORUBRICAVINCULO HV
      where HV.CDRUBRICAAGRUPAMENTO = PKGPAG_VAR.vgCdRubricaBaseCoParticip
        and HV.CDVINCULO = pCdVinculo
        and HV.Cdfolhapagamento = pFolha.CdFolhaPagamento;

     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                           pCdVinculo            => pCdVinculo,
                                           pCdExpressaoFormCalc  => null,
                                           pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseCoParticip,
                                           pNuSufixoRubrica      => 1,
                                           pVlPagamento          => 0,
                                           pVlIndice             => NULL,
                                           pCdTipoOrigemRubrica  => 1);

     PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                      pCdVinculo       => pCdVinculo,
                                      pCdRubrica       => PKGPAG_VAR.vgCdRubricaBaseCoParticip,
                                      pTpProcessamento => 2,
                                      pTpLocal         => 2);

    /*--------------------------------------------------------------------------------*/
    -- Seleciona o valor da base de contribuicao de co-participacao
    /*--------------------------------------------------------------------------------*/

    PKGPAG_VAR.vgValorBaseCoPart :=

             PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                               pCdVinculo         => pCdVinculo,
                                               pCdRubrica         => PKGPAG_VAR.vgCdRubricaBaseCoParticip);



    BEGIN


      BEGIN

      SELECT SE.*
        INTO vRegistro
        FROM ESauImpSistemaExterno SE
       INNER JOIN ECadOrgao O
         ON O.CdOrgao = SE.CdOrgao AND
            O.CdAgrupamento = pFolha.CdAgrupamento
       WHERE SE.CdVinculo = pCdVinculo AND
             SE.NuAnoCompetencia = pFolha.NuAnoReferencia AND
             SE.NuMesCompetencia = pFolha.NuMesReferencia;

      EXCEPTION
        WHEN OTHERS THEN
          NULL;

      END;

      IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

       -- Se possui co-partipacao da Gestao Propria ira descontar a rubrica alternativa 3 (05-0953)

       -- Caso reprocesse a folha defitiniva, atualiza os valores do contador.
       -- SIG-3176: A def foi calculada, zeraram os valores mas o registro de pagamento, no plano de saúde, permaneceu.
       vvlPagoCoParticipacaoGP := NVL(vRegistro.Vlpagocoparticip_Gp,0);
       vvlPagoCoParticipacaoUniSanta := NVL(vRegistro.Vlpagounisanta,0);
       vvlPagoCoParticIPESC := NVL(vRegistro.Vlpagocopipesctratsaude,0);
       vvlPagoCoParticipacaoJudicial := NVL(vRegistro.Vlpagocoparticipjudicial,0);
       vvlPagoCoParticipacaoUnimed := NVL(vRegistro.Vlpagocoparticip,0);

       IF NVL(vRegistro.VlSaldoCoParticip_GP,0) + NVL(vRegistro.VlDespesaCoParticip_GP,0) > 0 THEN

         vvlCoParticipacaoGP   := NVL(vRegistro.VlSaldoCoParticip_GP,0) +
                                  NVL(vRegistro.VlDespesaCoParticip_GP,0);

       END IF;

       -- Se possui co-partipacao da UNIMED ira descontar a rubrica do evento (05-0838)

       IF NVL(vRegistro.VlSaldoCoParticipAnterior,0) + NVL(vRegistro.VlDespesaCoParticip,0) > 0 THEN

         vvlCoParticipacaoUnimed   := NVL(vRegistro.VlSaldoCoParticipAnterior,0) +
                                      NVL(vRegistro.VlDespesaCoParticip,0);

       END IF;

       -- Se possui saldo do UniSanta ira descontar a rubrica alternativa 1 (05-0815)

       IF NVL(vRegistro.VlSaldoUniSantaAnterior,0) > 0 THEN

         vvlCoParticipacaoUniSanta   := NVL(vRegistro.VlSaldoUniSantaAnterior,0);

       END IF;

       --- Aplica o limitador para a Gestao Propria, UNIMED e UNISANTA

       vvlDescontoCoPartLimite := PKGPAG_VAR.vgValorBaseCoPart*0.2 ;

       IF vvlCoParticipacaoGP > vvlDescontoCoPartLimite THEN

          vvlCoParticipacaoGP := vvlDescontoCoPartLimite;

       END IF;

       vvlDescontoCoPartLimite := vvlDescontoCoPartLimite - vvlCoParticipacaoGP ;

       IF vvlCoParticipacaoUnimed > vvlDescontoCoPartLimite THEN

          vvlCoParticipacaoUnimed := vvlDescontoCoPartLimite;

       END IF;

       vvlDescontoCoPartLimite := vvlDescontoCoPartLimite - vvlCoParticipacaoUnimed ;

       IF vvlCoParticipacaoUniSanta > vvlDescontoCoPartLimite THEN

          vvlCoParticipacaoUniSanta := vvlDescontoCoPartLimite;

       END IF;

       -- Se possui saldo do IPREV ira descontar a rubrica alternativa 2 (05-0531)

       vvlCoParticIPESC    := NVL(vRegistro.VlCopIPESCTratSaude,0);

       IF vvlCoParticIPESC  > 0 THEN

         IF vvlCoParticIPESC > PKGPAG_VAR.vgValorBaseCoPart*0.1 THEN

          vvlCoParticIPESC := PKGPAG_VAR.vgValorBaseCoPart*0.1;

         END IF;

       END IF;

       -- Gestao Propria

       IF vvlCoParticipacaoGP > 0 AND NVL(pEvento.CdRubAgrupAlternativa3, 0) > 0 AND
          PKGPAG_GERAL.FGeraRubrica(pEvento.CdRubAgrupAlternativa3) THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa3,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => vvlCoParticipacaoGP,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 9);

        ELSIF  vvlCoParticipacaoGP > 0 AND NVL(pEvento.CdRubAgrupAlternativa3, 0) > 0 THEN

          vvlCoParticipacaoGP :=  PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                                                    pCdVinculo         => pCdVinculo,
                                                                    pCdRubrica         => pEvento.CdRubAgrupAlternativa3);
        else
          null;
        END IF;

        -- RUBRICA 05-0127 DESC SC JUD


        IF nvl(vRegistro.Vlsaldocoparticipjudicial,0) + NVL(vRegistro.vlcoparticipjudicial,0) > 0  THEN

           -- LIMITA VALOR A 20% DO VALOR BASE DE COPARTICIPAÇÃO

           vvlCoParticipacaoJudicial := nvl(vRegistro.Vlsaldocoparticipjudicial,0) + NVL(vRegistro.vlcoparticipjudicial,0);

           vvlCoParticipacaoJudicial := LEAST(vvlcoparticipacaojudicial,((PKGPAG_VAR.vgValorBaseCoPart * 0.2) - vvlCoParticipacaoGP));

           if vvlCoParticipacaoJudicial > 0 then

               PKGPAG_LF.PGeracaoLancamentoValor(pFolha            => pFolha,
                                        pCdVinculo              => pCdVinculo,
                                        pCdRubricaAgrupamento   => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                                                pCdTipoRubrica => 5,
                                                                                                pNuRubrica     => 127),
                                        pNuSufixoRubrica        => 1,
                                        pNuParcelasProc         => NULL,
                                        pInPossuiValorInformado => 1,
                                        pVlLancamento           => vvlCoParticipacaoJudicial,
                                        pVlIndice               => NULL,
                                        pCdTipoOrigemRubrica    => 3,
                                        pVlReal                 => vvlCoParticipacaoJudicial);


             PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                                                       pCdTipoRubrica => 5,
                                                                                                       pNuRubrica     => 127),
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vvlCoParticipacaoJudicial,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 3);
          end if;

        END IF;

        -- RUBRICA 04-0127 DEV COPARTICIPA DESC JUD

        IF NVL(vRegistro.vldevdecisaojudicial,0) > 0  THEN

           -- LIMITA VALOR A 20% DO VALOR BASE DE COPARTICIPAÇÃO

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento =>pFolha.CdAgrupamento,
                                                                                                       pCdTipoRubrica => 4,
                                                                                                       pNuRubrica     => 127),
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vRegistro.vldevdecisaojudicial,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 9);

          --end if;

        END IF;

        -- Unimed

        IF vvlCoParticipacaoUnimed > 0 AND NVL(pRubrica.CdRubricaAgrupamento, 0) > 0 AND
          PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => vvlCoParticipacaoUnimed,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 9);

        ELSIF  vvlCoParticipacaoUnimed > 0 AND NVL(pRubrica.CdRubricaAgrupamento, 0) > 0 THEN

          vvlCoParticipacaoUnimed :=  PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                                                        pCdVinculo         => pCdVinculo,
                                                                        pCdRubrica         => pRubrica.CdRubricaAgrupamento);

        END IF;

        -- UniSanta

        IF vvlCoParticipacaoUniSanta > 0 AND NVL(pEvento.CdRubAgrupAlternativa1, 0) > 0 AND
           PKGPAG_GERAL.FGeraRubrica(pEvento.CdRubAgrupAlternativa1) THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa1,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => vvlCoParticipacaoUniSanta,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 9);

        ELSIF  vvlCoParticipacaoUniSanta > 0 AND NVL(pEvento.CdRubAgrupAlternativa1, 0) > 0 THEN

          vvlCoParticipacaoUniSanta :=  PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                                                          pCdVinculo         => pCdVinculo,
                                                                          pCdRubrica         => pEvento.CdRubAgrupAlternativa1);

        END IF;

        IF vvlCoParticIPESC > 0 AND NVL(pEvento.CdRubAgrupAlternativa2, 0) > 0 AND
           PKGPAG_GERAL.FGeraRubrica(pEvento.CdRubAgrupAlternativa2) THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa2,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => vvlCoParticIPESC,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 9);

        ELSIF  vvlCoParticIPESC > 0 AND NVL(pEvento.CdRubAgrupAlternativa2, 0) > 0 THEN

          vvlCoParticIPESC :=  PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                                                 pCdVinculo         => pCdVinculo,
                                                                 pCdRubrica         => pEvento.CdRubAgrupAlternativa2);
        END IF;

    IF pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND pFlCalculoDefinitivo = 'S' AND
          ((vvlPagoCoParticipacaoUnimed > 0 OR
            vvlPagoCoParticIPESC > 0 OR
            vvlPagoCoParticipacaoGP > 0 OR
            vvlPagoCoParticipacaoUniSanta > 0 OR
            vvlPagoCoParticipacaoJudicial > 0)
            OR
           (vvlCoParticipacaoUnimed > 0 OR
            vvlCoParticIPESC > 0 OR
            vvlCoParticipacaoUniSanta > 0 OR
            vvlCoParticipacaoGP > 0 OR
            vvlCoParticipacaoJudicial > 0)) THEN

           vvlCoParticipacaoGP :=  PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                                                    pCdVinculo         => pCdVinculo,
                                                                    pCdRubrica         => pEvento.CdRubAgrupAlternativa3);

          -- SIG-3176: regitra a parcela paga
          --Saúde Servidor/Pano de Saúde/ Mante dados do plano de saúde para a folha de pagamento
          UPDATE ESauImpSistemaExterno SE
             SET SE.VlPagoCoParticip        = vvlCoParticipacaoUnimed,
                 SE.VlPagoUniSanta          = vvlCoParticipacaoUniSanta,
                 SE.VlPagoCopIPESCTratSaude = vvlCoParticIPESC,
                 SE.VlPagoCoParticip_GP     = vvlCoParticipacaoGP,
                 se.vlpagocoparticipjudicial = vvlCoParticipacaoJudicial
           WHERE SE.CdVinculo = pCdVinculo AND
                 SE.NuAnoCompetencia = pFolha.NuAnoReferencia AND
                 SE.NuMesCompetencia = pFolha.NuMesReferencia;

        END IF;
        END IF;
     ---------------------------------------------------------------------------------------------------
     -- Unimed
     ---------------------------------------------------------------------------------------------------

     IF NVL(vRegistro.VlRestituicaoCoParticip,0) > 0 THEN

       IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 4, pRubrica.NuRubrica)) THEN

         IF PKGPAG_VAR.vPagaSitDisposicao NOT IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' ) THEN

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento   => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                          4,
                                                                                           pRubrica.NuRubrica),
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => vRegistro.VlRestituicaoCoParticip,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 9);

         END IF;

       END IF;

     END IF;

     IF NVL(vRegistro.VlDiferencaCoParticip,0) > 0 THEN

       IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 6, pRubrica.NuRubrica)) THEN

         IF PKGPAG_VAR.vPagaSitDisposicao NOT IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' ) THEN

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                          6,
                                                                                          pRubrica.NuRubrica),
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vRegistro.VlDiferencaCoParticip,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 9);
         END IF;

       END IF;

      END IF;

       --------------------------------------------------------------------------------------------------------
       -- Gestao Propria
       --------------------------------------------------------------------------------------------------------

       IF NVL(vRegistro.VlRestituicaoCoParticip_GP,0) > 0 AND pEvento.CdRubAgrupAlternativa3 > 0 THEN

         vRubrica := PKGPAG_VAR.vgRubrica(pEvento.CdRubAgrupAlternativa3);

         IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 4, vRubrica.NuRubrica)) THEN

           IF PKGPAG_VAR.vPagaSitDisposicao NOT IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' ) THEN

             PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                   pCdVinculo            => pCdVinculo,
                                                   pCdExpressaoFormCalc  => NULL,
                                                   pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                            4,
                                                                                             vRubrica.NuRubrica),
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => vRegistro.VlRestituicaoCoParticip_GP,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 9);

           END IF;

         END IF;

      END IF;

     IF NVL(vRegistro.VlDiferencaCoParticip_GP,0) > 0  AND pEvento.CdRubAgrupAlternativa3 > 0 THEN

       vRubrica := PKGPAG_VAR.vgRubrica(pEvento.CdRubAgrupAlternativa3);

       IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 6, vRubrica.NuRubrica)) THEN

         IF PKGPAG_VAR.vPagaSitDisposicao NOT IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' ) THEN

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                          6,
                                                                                          vRubrica.NuRubrica),
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vRegistro.VlDiferencaCoParticip_GP,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 9);
         END IF;

       END IF;

     END IF;

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       NULL;

     WHEN TOO_MANY_ROWS THEN

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vCdHistParamCalc,
                                PKGPAG_VAR.vCdPessoa,
                                'Foi encontrado mais de um registro de desconto de co-participação.',
                                PKGPAG_VAR.vgCdVinculo);

    END;

  END IF;

END;

PROCEDURE PLiqNegativo(pCdVinculo IN INTEGER,
                       pFolha     IN PKGPAG_TIPO.rFolha) IS

  vVlRubricaFalta       NUMBER(13,2);

  vVlTotDescFalta       NUMBER(13,2):= 0;

  vvlPensaoUnica        NUMBER(13,2);

  vvlNaoDescontado      NUMBER (13,2);

  vCdRubricaPensaoUnica INTEGER;

  vNuSeqPensaoUnica     INTEGER;

  --vCont                 INTEGER;

  vVlRubricaFaltaMesAtual  NUMBER(13,2);

  vVlRubricaDevolFaltaMesAnt  NUMBER(13,2);

  vValorRubrica050513 number(13,2);

  vValorErarioDevido number(13,2);

  PROCEDURE PValorPensaoUnica (pCdHistSentencaJudicial in integer) IS

  BEGIN

    vvlPensaoUnica        := 0;

    vCdRubricaPensaoUnica := NULL;

    vNuSeqPensaoUnica     := NULL;

    BEGIN

       SELECT HRV.vlPagamento,
              HRV.Cdrubricaagrupamento,
              HRV.Nusufixorubrica
        INTO vvlPensaoUnica,
             vCdRubricaPensaoUnica,
             vNuSeqPensaoUnica
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdTipoOrigemRubrica = 8
         and hrv.cdhistsentencajudicial = pCdHistSentencaJudicial;

    EXCEPTION

      WHEN OTHERS THEN

      NULL;

   END;

  END;

BEGIN

  IF PKGPAG_VAR.vgParamOrgao.FlGeraLiquidoNegativo = PKGPAG_TIPO.cnS AND
     PKGPAG_VAR.vgParamOrgao.CdRubricaDesconto IS NOT NULL AND
     PKGPAG_VAR.vgParamOrgao.CdRubricaProvento IS NOT NULL
     THEN

    IF PKGPAG_VAR.vgVlBaseTotalLiquida < 0 THEN

     -- SIG-7029 SIGRH - [Chamado 16410/2021] - LIQUIDO NEGATIVO GERADO PELA FUNCIONALIDADE DE ERARIO
     if PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                          pCdVinculo,
                                          pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,5,513)) > 0 then

       vValorRubrica050513 := PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                 pCdVinculo,
                                                                 pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,5,513));

       vValorErarioDevido := vValorRubrica050513;

       for cc in (SELECT rv.* FROM epaghistoricorubricavinculo RV
                        inner join epaglancamentofinanceiro lf on lf.cdlancamentofinanceiro = rv.cdlancamentofinanceiro
                   where RV.cdvinculo = pCdVinculo
                     and rv.cdfolhapagamento = pFolha.CdFolhaPagamento
                     and lf.cdprocessorestituicaoerario is not null
                     order by rv.vlpagamento desc)

       loop

          begin

          if vValorRubrica050513 > 0 then

            case when cc.vlpagamento >= vValorRubrica050513 then

               update epaghistoricorubricavinculo rv
                  set rv.vlpagamento = rv.vlpagamento - vValorRubrica050513
                where rv.cdhistoricorubricavinculo = cc.cdhistoricorubricavinculo;


              update epaghistoricorubricarelvinc rvv
                  set rvv.vlreal = rvv.vlreal - vValorRubrica050513,
                      rvv.vlintegral = rvv.vlintegral - vValorRubrica050513,
                      rvv.vlproporcional = rvv.vlproporcional - vValorRubrica050513
                where rvv.cdfolhapagamento = cc.cdfolhapagamento
                  and rvv.cdvinculo = cc.cdvinculo
                  and rvv.cdrubricaagrupamento = cc.cdrubricaagrupamento;

              vValorRubrica050513 := 0;

            else

               vValorRubrica050513 := vValorRubrica050513 - cc.vlpagamento;

               update epaghistoricorubricavinculo rv
                  set rv.vlpagamento = 0
                where rv.cdhistoricorubricavinculo = cc.cdhistoricorubricavinculo;

            end case;

          end if;

          exception
            when others then
              null;

          end;

       end loop;

       vValorErarioDevido := vValorErarioDevido - vValorRubrica050513;

       begin

       update epaghistoricorubricavinculo rv
          set rv.vlpagamento = rv.vlpagamento - vValorErarioDevido
        where rv.cdvinculo = pCdVinculo
          and rv.cdfolhapagamento = pFolha.CdFolhaPagamento
          and rv.cdrubricaagrupamento = pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,1001);

       update epaghistoricorubricavinculo rv
          set rv.vlpagamento = rv.vlpagamento - vValorErarioDevido
        where rv.cdvinculo = pCdVinculo
          and rv.cdfolhapagamento = pFolha.CdFolhaPagamento
          and rv.cdrubricaagrupamento = pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,9001);

       exception
         when others then
           null;

       end;

       pkgpag_geral.patualizatotalizadoras (pFolha.CdFolhaPagamento ,pCdVinculo);

     end if;

      -- Verifica se o valor das faltas e superior ao valor liquido,

      vVlRubricaFalta :=

        PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                          pCdVinculo,
                                          PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,25));

      -- Verifica se o valor das faltas e superior ao valor liquido, MES ATUAL

      vVlRubricaFaltaMesAtual :=

        PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                          pCdVinculo,
                                          PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,82));

      -- 08-0519-01 DEVOL.PROV. DEV.FALTAS MES ANTERIOR
      vVlRubricaDevolFaltaMesAnt := PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                      pCdVinculo,
                                                                      pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,519));

      -- Varre pensoes para identificar

      if pkgpag_var.bPossuiPensao then


          for pen in (select hrv.cdhistsentencajudicial
                        from EPagHistoricoRubricaVinculo HRV
                        inner join epenhistsentencajudicial pp on pp.cdhistsentencajudicial = hrv.cdhistsentencajudicial
                        where HRV.CdVinculo = pCdVinculo
                          and hRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                          and HRV.CdTipoOrigemRubrica = 8
                          order by pp.dtiniciovigencia desc)
            loop

              vvlPensaoUnica := 0;

              PValorPensaoUnica(pen.cdhistsentencajudicial);

              --solicitacao #76809: Para a CIDASC o liq. negativo nao abate da pensao alimenticia
              IF vVlPensaoUnica > 0 AND PKGPAG_VAR.vgVlBaseTotalLiquida < 0 AND pfolha.CdAgrupamento <> 4 THEN

                PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_VAR.vgVlTotalDescontos - vVlPensaoUnica ;

                IF vVlPensaoUnica >= ABS(PKGPAG_VAR.vgVlBaseTotalLiquida) THEN
                   vVlPensaoUnica := vVlPensaoUnica - ABS(PKGPAG_VAR.vgVlBaseTotalLiquida);
                   vvlNaoDescontado := ABS(PKGPAG_VAR.vgVlBaseTotalLiquida);
                   PKGPAG_VAR.vgVlBaseTotalLiquida := 0;
                ELSE
                   vvlNaoDescontado := vVlPensaoUnica;
                   PKGPAG_VAR.vgVlBaseTotalLiquida := PKGPAG_VAR.vgVlBaseTotalLiquida + vVlPensaoUnica;
                   vVlPensaoUnica := 0;
                END IF;

                PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_VAR.vgVlTotalDescontos + vVlPensaoUnica ;

                UPDATE EPagHistoricoRubricaVinculo HRV
                   SET VlPagamento = vVlPensaoUnica
                 WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                       HRV.CdVinculo = pCdVinculo AND
                       HRV.CdRubricaAgrupamento = vCdRubricaPensaoUnica AND
                       HRV.Nusufixorubrica = vNuSeqPensaoUnica;

                 PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pCdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBasePensaoNaoDesc,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => vvlNaoDescontado,
                                                      pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 1);

                 PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                         pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                         pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                         pDeLog                   => 'Montante de pensão alimentícia não descontada.',
                                         pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                         pCdTipoOcorrencia        => 2, -- Ocorrencia
                                         pCdMotivoOcorrencia      => 16);

              END IF;
         end loop;
      end if;

      -- SIG-1949 desconto totalizadora de faltas 09-5519 - chamado 13862
      -- Tratamento desconto de faltas
      if PKGPAG_VAR.vgVlBaseTotalLiquida < 0
        -- Quando estiver parametrizada a rubrica de proventos para compensação: 01-0299
        -- (conta corrente), não limita o desconto de faltas.
        AND pkgpag_var.vgrubrica(PKGPAG_VAR.vgParamOrgao.CdRubricaProvento).nurubrica <> 299
        AND (vVlRubricaDevolFaltaMesAnt > 0 or vVlRubricaFalta > 0 or vVlRubricaFaltaMesAtual > 0) then

        -- Considera o tot proventos e descontos obrigatórios (tipo INSS/IPREV..)
        vVlTotDescFalta := PKGPAG_VAR.vgVlBaseTotalLiquida + vVlRubricaDevolFaltaMesAnt + vVlRubricaFalta + vVlRubricaFaltaMesAtual;

        vvlNaoDescontado := 0; --vVlRubricaDevolFaltaMesAnt;

        pkgpag_geral.patualizatotalizadoras (pFolha.CdFolhaPagamento ,pCdVinculo);

         -- 05-0519-01 FALTAS MES ANTERIOR
         if vVlRubricaFalta > 0 then

            case
              when pkgpag_var.vgVlTotalProventos = 0 then

                 vvlNaoDescontado := vvlNaoDescontado + vVlRubricaFalta;

                 vVlRubricaFalta := 0;

              when vVlRubricaFalta >= vVlTotDescFalta then

                 vvlNaoDescontado := vVlNaoDescontado + vVlRubricaFalta - vVlTotDescFalta;

                 vVlRubricaFalta := vVlTotDescFalta;

                 pkgpag_var.vgVlTotalProventos := 0;

                 -- vVlRubricaFalta := vVlRubricaFalta - vVlRubricaDevolFaltaMesAnt;
              else

                 vVlTotDescFalta := vVlTotDescFalta - vVlRubricaFalta;

            end case;

            UPDATE EPagHistoricoRubricaVinculo HRV
               SET VlPagamento = case when vVlRubricaFalta > 0 then vVlRubricaFalta else 0 end
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                   HRV.CdVinculo = pCdVinculo AND
                   HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,25);

            UPDATE EPagHistoricoRubricaRelVinc HR
               set hr.vlintegral = case when vVlRubricaFalta > 0 then vVlRubricaFalta else 0 end,
                   hr.vlreal = case when vVlRubricaFalta > 0 then vVlRubricaFalta else 0 end,
                   hr.vlproporcional = case when vVlRubricaFalta > 0 then vVlRubricaFalta else 0 end
             WHERE HR.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                   HR.CdVinculo = pCdVinculo AND
                   HR.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,25);

         end if;

         -- Faltas Mes Atual
         if vVlRubricaFaltaMesAtual > 0 then

            case
              when pkgpag_var.vgVlTotalProventos = 0 then

                 vvlNaoDescontado := vVlNaoDescontado + vVlRubricaFaltaMesAtual;

                 vVlRubricaFaltaMesAtual := 0;

              when vVlRubricaFaltaMesAtual >= vVlTotDescFalta then

                 vvlNaoDescontado := vVlNaoDescontado + vVlRubricaFaltaMesAtual - vVlTotDescFalta;

                 vVlRubricaFaltaMesAtual := vVlTotDescFalta;

                 vVlTotDescFalta := 0;

              else

                 vVlTotDescFalta := vVlTotDescFalta - vVlRubricaFaltaMesAtual;

            end case;

            UPDATE EPagHistoricoRubricaVinculo HRV
               SET VlPagamento = vVlRubricaFaltaMesAtual
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                   HRV.CdVinculo = pCdVinculo AND
                   HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,82);

            UPDATE EPagHistoricoRubricaRelVinc HR
               set hr.vlintegral = vVlRubricaFaltaMesAtual,
                   hr.vlreal = vVlRubricaFaltaMesAtual,
                   hr.vlproporcional = vVlRubricaFaltaMesAtual
             WHERE HR.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                   HR.CdVinculo = pCdVinculo AND
                   HR.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,82);

         end if;

         --pkgpag_geral.patualizatotalizadoras (pFolha.CdFolhaPagamento ,pCdVinculo);
         -- Saldo Mes Anterior
         if vVlRubricaDevolFaltaMesAnt > 0
              then

            case
              when pkgpag_var.vgVlTotalProventos = 0 then

                 vvlNaoDescontado := vVlRubricaDevolFaltaMesAnt;

                 vVlRubricaDevolFaltaMesAnt := 0;

              when vVlRubricaDevolFaltaMesAnt >= vVlTotDescFalta then

                 vvlNaoDescontado := vVlRubricaDevolFaltaMesAnt - vVlTotDescFalta;

                 vVlRubricaDevolFaltaMesAnt := vVlTotDescFalta;

                 pkgpag_var.vgVlTotalProventos := 0;

              else

                 vVlTotDescFalta := vVlTotDescFalta - vVlRubricaDevolFaltaMesAnt;

            end case;

            UPDATE EPagHistoricoRubricaVinculo HRV
               SET VlPagamento = vVlRubricaDevolFaltaMesAnt
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                   HRV.CdVinculo = pCdVinculo AND
                   HRV.CdRubricaAgrupamento = pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,519);

            UPDATE EPagHistoricoRubricaRelVinc HR
               set hr.vlintegral = vVlRubricaDevolFaltaMesAnt,
                   hr.vlreal = vVlRubricaDevolFaltaMesAnt,
                   hr.vlproporcional = vVlRubricaDevolFaltaMesAnt
             WHERE HR.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                   HR.CdVinculo = pCdVinculo AND
                   HR.CdRubricaAgrupamento = pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,519);


         end if;

         pkgpag_geral.patualizatotalizadoras (pFolha.CdFolhaPagamento ,pCdVinculo);

         if pkgpag_var.vgVlBaseTotalLiquida < 0 and
            abs(pkgpag_var.vgVlBaseTotalLiquida) <> vvlNaoDescontado
           then

           if vVlRubricaFaltaMesAtual > 0 then

              if vVlRubricaFaltaMesAtual >= abs(pkgpag_var.vgVlBaseTotalLiquida) then

                 vVlRubricaFaltaMesAtual := vVlRubricaFaltaMesAtual - abs(pkgpag_var.vgVlBaseTotalLiquida);

                 vvlNaoDescontado := abs(pkgpag_var.vgVlBaseTotalLiquida);

                 pkgpag_var.vgVlBaseTotalLiquida := 0;

              else

                 pkgpag_var.vgVlBaseTotalLiquida := abs(pkgpag_var.vgVlBaseTotalLiquida) - vVlRubricaFaltaMesAtual;

                 vvlNaoDescontado := vVlRubricaFaltaMesAtual;

                 vVlRubricaFaltaMesAtual := 0;

              end if;

              UPDATE EPagHistoricoRubricaVinculo HRV
                 SET VlPagamento = vVlRubricaFaltaMesAtual
               WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                     HRV.CdVinculo = pCdVinculo AND
                     HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,82);

              UPDATE EPagHistoricoRubricaRelVinc HR
                 set hr.vlintegral = vVlRubricaFaltaMesAtual,
                     hr.vlreal = vVlRubricaFaltaMesAtual,
                     hr.vlproporcional = vVlRubricaFaltaMesAtual
               WHERE HR.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                     HR.CdVinculo = pCdVinculo AND
                     HR.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,82);

               vvlNaoDescontado := vvlNaoDescontado + abs(pkgpag_var.vgVlBaseTotalLiquida);

           end if;

           if vVlRubricaFalta > 0 and pkgpag_var.vgVlBaseTotalLiquida < 0 then

              if vVlRubricaFalta >= abs(pkgpag_var.vgVlBaseTotalLiquida) then

                 vVlRubricaFalta := vVlRubricaFalta - abs(pkgpag_var.vgVlBaseTotalLiquida);

                 vvlNaoDescontado := abs(pkgpag_var.vgVlBaseTotalLiquida);

                 pkgpag_var.vgVlBaseTotalLiquida := 0;

              else

                 pkgpag_var.vgVlBaseTotalLiquida := abs(pkgpag_var.vgVlBaseTotalLiquida) - vVlRubricaFalta;

                 vvlNaoDescontado := vVlRubricaFalta;

                 vVlRubricaFalta := 0;

              end if;

              UPDATE EPagHistoricoRubricaVinculo HRV
                 SET VlPagamento = vVlRubricaFalta
               WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                     HRV.CdVinculo = pCdVinculo AND
                     HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,25);

              UPDATE EPagHistoricoRubricaRelVinc HR
                 set hr.vlintegral = vVlRubricaFalta,
                     hr.vlreal = vVlRubricaFalta,
                     hr.vlproporcional = vVlRubricaFalta
               WHERE HR.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                     HR.CdVinculo = pCdVinculo AND
                     HR.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaCodigoRubrica(pFolha.CdAgrupamento,25);

               vvlNaoDescontado := vvlNaoDescontado + abs(pkgpag_var.vgVlBaseTotalLiquida);

           end if;

        end if;

         if vvlNaoDescontado > 0 then

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pCdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseFaltaRetroNaoDesc,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => vvlNaoDescontado,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

            PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                    pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                    pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                    pDeLog                   => 'Montante de faltas retroativas n?o descontado.',
                                    pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                    pCdTipoOcorrencia        => 2, -- Ocorrencia
                                    pCdMotivoOcorrencia      => 15);

         end if;

          pkgpag_geral.patualizatotalizadoras (pFolha.CdFolhaPagamento ,pCdVinculo);

      END IF;

      IF PKGPAG_VAR.vgVlBaseTotalLiquida >= 0 THEN

         NULL;

      ELSIF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                              pCdVinculo           => pCdVinculo,
                                              pCdRubrica           => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                   8,
                                                                                                   23),
                                              pCdTipoOrigemRubrica => 16) >= ABS(PKGPAG_VAR.vgVlBaseTotalLiquida) THEN /* 13S */

        FOR vRec IN ( SELECT ROWID AS RID, VlPagamento
                        FROM EPagHistoricoRubricaVinculo HRV
                       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                             HRV.CdVinculo = pCdVinculo AND
                             HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                     8,
                                                                                     23) AND
                             HRV.NuSufixoRubrica = 1 AND
                             HRV.CdTipoOrigemRubrica = 16 AND
                             ROWNUM < 2)
        LOOP

          PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_VAR.vgVlTotalDescontos - vRec.VlPagamento ;

          vRec.VlPagamento := vRec.VlPagamento - ABS(PKGPAG_VAR.vgVlBaseTotalLiquida);

          PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_VAR.vgVlTotalDescontos + vRec.VlPagamento ;

          UPDATE EPagHistoricoRubricaVinculo
             SET VlPagamento = vRec.VlPagamento
            WHERE ROWID = vRec.RID;

        END LOOP;

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBase080023DescParcial,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => ABS(PKGPAG_VAR.vgVlBaseTotalLiquida),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

         PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                 pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                 pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                 pDeLog                   => 'Devolução de 08-0023 descontada parcialmente.',
                                 pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pCdTipoOcorrencia        => 2, -- Ocorrencia
                                 pCdMotivoOcorrencia      => 21);

       ELSIF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                               pCdVinculo           => pCdVinculo,
                                               pCdRubrica           => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                            8,
                                                                            24),
                                               pCdTipoOrigemRubrica => 16) >= ABS(PKGPAG_VAR.vgVlBaseTotalLiquida) THEN /* 13S */

         FOR vRec IN ( SELECT ROWID AS RID, VlPagamento
                         FROM EPagHistoricoRubricaVinculo HRV
                        WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                              HRV.CdVinculo = pCdVinculo AND
                              HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                      8,
                                                                                      24) AND
                              HRV.NuSufixoRubrica = 1 AND
                              HRV.CdTipoOrigemRubrica = 16 AND
                              ROWNUM < 2)
         LOOP

           PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_VAR.vgVlTotalDescontos - vRec.VlPagamento ;

           vRec.VlPagamento := vRec.VlPagamento - ABS(PKGPAG_VAR.vgVlBaseTotalLiquida);

           PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_VAR.vgVlTotalDescontos + vRec.VlPagamento ;

           UPDATE EPagHistoricoRubricaVinculo
             SET VlPagamento = vRec.VlPagamento
             WHERE ROWID = vRec.RID;

         END LOOP;

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBase080024DescParcial,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => ABS(PKGPAG_VAR.vgVlBaseTotalLiquida),
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);

         PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                 pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                 pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                 pDeLog                   => 'Rubrica 08-0024 descontada parcialmente.',
                                 pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pCdTipoOcorrencia        => 2, -- Ocorrencia
                                 pCdMotivoOcorrencia      => 22);
      ELSE

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgParamOrgao.CdRubricaProvento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => ABS(PKGPAG_VAR.vgVlBaseTotalLiquida),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                pDeLog                   => 'Geração de líquido negativo.',
                                pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                pCdTipoOcorrencia        => 2, -- Ocorrencia
                                pCdMotivoOcorrencia      => 6);

        PKGPAG_VAR.vgVlTotalProventos := PKGPAG_VAR.vgVlTotalProventos + ABS(PKGPAG_VAR.vgVlBaseTotalLiquida);

      END IF;

      PKGPAG_VAR.vgVlBaseTotalLiquida := 0;

    END IF;

  END IF;

END;

PROCEDURE PDescontoLiqNegativo(pCdVinculo IN INTEGER,
                               pFolha     IN PKGPAG_TIPO.rFolha) IS

  vNuAnoFolha  INTEGER;

  vNuMesFolha  INTEGER;

BEGIN

  PKGPAG_VAR.vgValorDescLiqNegativo := 0;

  IF pFolha.NuMesReferencia = 1 THEN

    vNuAnoFolha := pFolha.NuAnoReferencia - 1;

    vNuMesFolha := 12;

  ELSE

    vNuAnoFolha := pFolha.NuAnoReferencia;

    vNuMesFolha := pFolha.NuMesReferencia - 1;

  END IF;

  IF PKGPAG_VAR.vgParamOrgao.FlGeraLiquidoNegativo = PKGPAG_TIPO.cnS AND
     PKGPAG_VAR.vgParamOrgao.CdRubricaDesconto IS NOT NULL AND
     PKGPAG_VAR.vgParamOrgao.CdRubricaProvento IS NOT NULL THEN

    SELECT NVL(SUM(VlPagamento),0)
      INTO PKGPAG_VAR.vgValorDescLiqNegativo
      FROM ePagHistoricoRubricaVinculo HRV
     INNER JOIN EPagFolhaPagamento FP
        ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
     WHERE HRV.CdVinculo = pCdVinculo AND
           HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamOrgao.CdRubricaProvento AND
           FP.NuAnoReferencia = vNuAnoFolha AND
           FP.Numesreferencia = vNuMesFolha AND
           FP.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento AND
           FP.CdTipoCalculo IN (1,5) AND
           FP.FlCalculoDefinitivo =PKGPAG_TIPO.cnS;

     IF PKGPAG_VAR.vgValorDescLiqNegativo > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => PKGPAG_VAR.vgParamOrgao.CdRubricaDesconto,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => PKGPAG_VAR.vgValorDescLiqNegativo,
                                             pVlIndice             => NULL);

      PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_VAR.vgVlTotalDescontos + PKGPAG_VAR.vgValorDescLiqNegativo;

      PKGPAG_VAR.vgVlBaseTotalLiquida :=  PKGPAG_VAR.vgVlBaseTotalLiquida - PKGPAG_VAR.vgValorDescLiqNegativo;

     END IF;

   END IF;

END;

/* Gera as Rubricas identificadas de ferias */
PROCEDURE PAdicionaProcessaRubFerias (pCdVinculo            IN INTEGER,
                                      pFolha                IN PKGPAG_TIPO.rFolha,
                                      pCdRubricaAgrupamento IN INTEGER,
                                      pDias                 IN INTEGER) IS

  vCdEstruturaCarreira INTEGER;

  vCdExpressaoFormCalc INTEGER;

  vValorRubrica NUMBER(13,2);

  vVlPagamentoSupl NUMBER(13,2);

  vCdHistoricoRubricaVinculo NUMBER(38) := 0;

BEGIN

  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

    vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

  END IF;

  vCdExpressaoFormCalc :=

       PKGPAG_GERAL.FIdentificaFormulaCalculo (
                    pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                    pCdRubricaAgrupamento     => pCdRubricaAgrupamento,
                    pCdRelacaoVinculo         => 0,
                    pCdEstruturaCarreira      => vCdEstruturaCarreira);

  IF vCdExpressaoFormCalc > 0 THEN

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                          pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => 0,
                                          pVlIndice             => pDias,
                                          pCdTipoOrigemRubrica  => 7);

    PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => pCdRubricaAgrupamento,
                                     pTpProcessamento => 1,
                                     pTpLocal         => 2); /*Vinculo*/

     vValorRubrica := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                              pcdvinculo => pCdVinculo,
                                                              pcdrubrica => pCdRubricaAgrupamento,
                                                              pnusufixo  => 1,
                                                              pcdtipoorigemrubrica => 7);

     IF NVL(vValorRubrica,0) > 0
       THEN
         PKGPAG_GERAL.pinserelancamentorelacao(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                    pcdvinculo => pCdVinculo,
                                                                    pCdRelacaoVinculo     => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                                    pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                                    pcdexpressaoformcalc => vCdExpressaoFormCalc,
                                                                    pcdrubricaagrupamento => pCdRubricaAgrupamento,
                                                                    pvlintegral => vValorRubrica,
                                                                    pvlproporcional => vValorRubrica,
                                                                    pnusufixorubrica => 1,
                                                                    pvlreal => vValorRubrica);

         -- SIG-1988 13883/2019 Julho NAO considerando férias na suplementar
         begin

         select hv.cdhistoricorubricavinculo
           into vCdHistoricoRubricaVinculo
           from EPAGHISTORICORUBRICAVINCULO HV
          where HV.CDRUBRICAAGRUPAMENTO = pCdRubricaAgrupamento
            and HV.CDVINCULO = pCdVinculo
            and HV.Cdfolhapagamento = pFolha.CdFolhaPagamento
            and HV.Nusufixorubrica = 1
            and HV.Cdtipoorigemrubrica = 7;

         if nvl(vCdHistoricoRubricaVinculo,0) <> 0 then

            update epagHistoricoRubricaVinculo hv
               set hv.vlpagamento = vValorRubrica,
                   hv.deexpressao = hv.deexpressao || ' - ' || vVlPagamentoSupl
             where hv.cdhistoricorubricavinculo = vCdHistoricoRubricaVinculo;

         end if;

         exception

            when no_data_found then

              pkgpag_geral.pinserelancamentovinculo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                            pcdvinculo => pCdVinculo,
                                                  pcdexpressaoformcalc => vCdExpressaoFormCalc,
                                                 pcdrubricaagrupamento => pCdRubricaAgrupamento,
                                                      pnusufixorubrica => 1,
                                                          pvlpagamento => vValorRubrica,
                                                  pcdtipoorigemrubrica => 7);

            when others then

               pkgpag_geral.pinserelancamentovinculo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                            pcdvinculo => pCdVinculo,
                                                  pcdexpressaoformcalc => vCdExpressaoFormCalc,
                                                 pcdrubricaagrupamento => pCdRubricaAgrupamento,
                                                      pnusufixorubrica => 1,
                                                          pvlpagamento => vValorRubrica,
                                                  pcdtipoorigemrubrica => 7);

         end;



     ELSE

       DELETE EPAGHISTORICORUBRICAVINCULO HV
        WHERE HV.CDRUBRICAAGRUPAMENTO = pCdRubricaAgrupamento
          AND HV.CDVINCULO = pCdVinculo
          AND HV.Cdfolhapagamento = pFolha.CdFolhaPagamento
          AND HV.Nusufixorubrica = 1
          AND HV.Cdtipoorigemrubrica = 7;

     END IF;

  END IF;

END;

PROCEDURE PCarregaGlobaisRubFerias (pCdVinculo  IN INTEGER,
                                    pFolha      IN PKGPAG_TIPO.rFolha,
                                    pRubrica    IN PKGPAG_TIPO.rRubrica) IS

   vNuMesCalcAntFolha     INTEGER;
   vNuAnoCalcAntFolha     INTEGER;

BEGIN

   IF pCdVinculo = gFerCdVinculo THEN -- Mesmo vinculo, globais ja carregadas
      RETURN;
   END IF;

   gFerCdVinculo := pCdVinculo;

   -- Buscando folha anterior do tipo em calculo

   IF pFolha.NuMesReferencia = 1 THEN

      vNuMesCalcAntFolha := 12;

      vNuAnoCalcAntFolha := pFolha.NuAnoReferencia - 1;

  ELSE

      vNuMesCalcAntFolha := pFolha.NuMesReferencia - 1;

      vNuAnoCalcAntFolha := pFolha.NuAnoReferencia;

  END IF;

  gFerAnoMesCalcAntFolha := 100 * vNuAnoCalcAntFolha + vNuMesCalcAntFolha;

   -- Buscando referencia do calculo anterior de ferias

  IF PKGPAG_VAR.vgOrgaoFeriasParam.InPagBeneficioFerias = 1 THEN

      gFerMesCalcAntFerias := pFolha.NuMesReferencia;

      gFerAnoCalcAntFerias := pFolha.NuAnoReferencia;

  ELSE

      gFerMesCalcAntFerias := vNuMesCalcAntFolha;

      gFerAnoCalcAntFerias := vNuAnoCalcAntFolha;

  END IF;

  -- Verifica o numero minimo de dias para retorno

  BEGIN

     SELECT ORT.NUMINDIASESTORNO
       INTO gFerMinDiasEstorno
       FROM Emovorgaoreltrabalhoferias ORT
      WHERE ORT.Cdorgao = PKGPAG_VAR.vgCdOrgaoVinculo
        AND ORT.CDRELACAOTRABALHO = PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento
        AND ORT.DTFIMVIGENCIA IS NULL;

     EXCEPTION

        WHEN NO_DATA_FOUND THEN

           gFerMinDiasEstorno := 10;
  END;

/*

select DECODE (InPagBeneficioFerias,1,'F','N') as FolhaFerias
  from EMovOrgaoFerias
where CdOrgao = 3
  and DtFimVigencia IS NULL

     IF PKGPAG_VAR.vgOrgaoFeriasParam.InPagBeneficioFerias = 1 THEN

       PKGPAG_VAR.vgCdFolhaFerias := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                         pCdFolha       => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                         pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                         pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaFerias);

     ELSE

       PKGPAG_VAR.vgCdFolhaFerias := FRetornaFolhaPagamento(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,

  */

END;

PROCEDURE PGerarRubFerias (pCdVinculo             IN INTEGER,
                           pFolha                 IN PKGPAG_TIPO.rFolha,
                           pCdRubricaAgrupamento  IN INTEGER,
                           pNuMesPag              IN INTEGER,
                           pNuAnoPag              IN INTEGER,
                           pFormExpr              IN PKGPAG_TIPO.tFormulaCalculo,
                           pFlDifFerias           IN BOOLEAN) IS

  vQtdeDias     INTEGER;
  bPossuiCTISP  BOOLEAN := FALSE;

BEGIN

/* EMovFeriasFruicaoPagamento.InSituacao:

     -- GOZADOS
        1, -- Programado
        2, -- Reprogramado
        3, -- Programado retroativamente
       11, -- Alterado

     -- SUSPENSOS/INTERROMPIDOS, por causa dos recalculos
        4, -- Suspenso sem estorno dos beneficios
        5, -- Suspenso com estorno dos beneficios
        6, -- Suspenso motivo de movimentacao
        7, -- Interrompido definitivamente
        8, -- Interrompido temporariamente
       12, -- Suspenso

     -- Situacoes antigas nao mais tratadas
        9, -- Averbado em dobro
       10, -- Indenizado
*/

-- verifica se e ctisp --
  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

    FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
    LOOP

      IF PKGPAG_VAR.vgCEF(i).CdRelacaoTrabalho = PKGPAG_TIPO.cnRelCTISP THEN

        bPossuiCTISP := TRUE;

      END IF;

    END LOOP;

  END IF;

  IF NOT PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 1 AND  -- nao e ativo
   NOT bPossuiCTISP THEN    -- nao e ctisp

     RETURN;

  END IF;

  -- Calcular

  vQtdeDias                  := 0;

  FOR rec IN  cPagFerias (pCdVinculo      => pCdVinculo,
                          pNuAnoPag       => pNuAnoPag,
                          pNuMesPag       => pNuMesPag,
                          pNuAnoMesFerias => pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia ) LOOP

    if bPossuiCTISP and rec.dtinicioferias > pkgpag_var.vgVinculo.DtDesligamento
       then
         continue;
    end if;

    IF pFlDifFerias THEN

       IF rec.FlPermiteDiferenca = 'S' AND -- Permite porque as ferias foram adiantadas e sao iguais ao mes de pagamento
          (rec.NuAnoMesDevolucao IS NULL OR rec.NuAnoMesDevolucao > pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia) THEN

          -- Devolucao sera em meses futuros, entao pagar a diferenca

          IF rec.NuDias > vQtdeDias THEN

             vQtdeDias := rec.NuDias;

          END IF;

       END IF;

    ELSE

       IF rec.NuDias > vQtdeDias THEN

          vQtdeDias := rec.NuDias;

       END IF;

    END IF;

    IF rec.CdPeriodoAquisitivoFerias <> rec.ProxPerAquisitivoFerias THEN

      IF vQtdeDias > 0 THEN

         PAdicionaProcessaRubFerias (pCdVinculo            => pCdVinculo,
                                     pFolha                => pFolha,
                                     pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                     pDias                 => vQtdeDias);

         -- Sistema so trabalha com um periodo aquisitivo, portanto, sair

         RETURN;

      END IF;

      vQtdeDias := 0;

    END IF;

  END LOOP;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;

END;

PROCEDURE PUmTercoFeriasNov(pCdVinculo  IN INTEGER,
                         pFolha      IN PKGPAG_TIPO.rFolha,
                         pRubrica    IN PKGPAG_TIPO.rRubrica,
                         pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

BEGIN

   PGerarRubFerias (pCdVinculo             => pCdVinculo,
                    pFolha                 => pFolha,
                    pCdRubricaAgrupamento  => pRubrica.CdRubricaAgrupamento, -- Gera pagto 1/3 ferias
                    pNuMesPag              => pFolha.NuMesReferencia,
                    pNuAnoPag              => pFolha.NuAnoReferencia,
                    pFormExpr              => pFormExpr,
                    pFlDifFerias           => false);

END;

PROCEDURE PDiferencaUmTercoFeriasNov(pCdVinculo  IN INTEGER,
                                  pFolha      IN PKGPAG_TIPO.rFolha,
                                  pRubrica    IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

BEGIN

   IF PKGPAG_VAR.vPagaSitDisposicao IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' ) THEN

      RETURN;

   END IF;

   PCarregaGlobaisRubFerias (pCdVinculo  => pCdVinculo,
                             pFolha      => pFolha,
                             pRubrica    => pRubrica);

   PGerarRubFerias (pCdVinculo             => pCdVinculo,
                    pFolha                 => pFolha,
                    pCdRubricaAgrupamento  => pRubrica.CdRubricaAgrupamento, -- Gera diferenca pagto 1/3 ferias
                    pNuMesPag              => gFerMesCalcAntFerias,
                    pNuAnoPag              => gFerAnoCalcAntFerias,
                    pFormExpr              => pFormExpr,
                    pFlDifFerias           => TRUE);

END;

PROCEDURE PDevolucaoUmTercoFeriasNov(pCdVinculo  IN INTEGER,
                                  pFolha      IN PKGPAG_TIPO.rFolha,
                                  pRubrica    IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

  vQtdeDias                   INTEGER;

  --vInSituacao                 INTEGER;

  --vFlFruicaoAnulada           CHAR(1);

  --vInSitFeriasVigente         INTEGER;

  --vDtFimAfastamentoVinculo    DATE;

  vNuAnoLimite                INTEGER;

  vNuMesLimite                INTEGER;

  vComUsufrutoNoMesAPagar     BOOLEAN;

  cLimitePrazoMesesDev        INTEGER := 4; -- Limite maximo de aceitacao de devolucao - 4 meses

  vGerarDiferenca             INTEGER;

 FUNCTION FAfastadoPorGravidez (pCdVinculo        IN INTEGER,
                                pDtInicioUsufruto IN DATE) RETURN BOOLEAN IS

     vCdAfastamentoGravidez      INTEGER;

 BEGIN

     SELECT 1
       INTO vCdAfastamentoGravidez
       FROM EAfaAfastamentoVinculo AV1
       INNER JOIN EAfaAfastamentoVinculo AV2
          ON AV2.CdVinculo = AV1.CdVinculo
         AND AV2.DtInicio  = AV1.DtFim + 1
       INNER JOIN EAfaHistMotivoAfastTemp HMAT
          ON AV2.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
       WHERE AV1.CdVinculo = pCdVinculo
         AND AV1.FlAnulado = PKGPAG_TIPO.cnN
         AND AV2.FlAnulado = PKGPAG_TIPO.cnN
         AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
         AND HMAT.FlGravidez = PKGPAG_TIPO.cnS
         AND  AV1.DtInicio = pDtInicioUsufruto
         AND ROWNUM < 2;

      RETURN TRUE;

  EXCEPTION
       WHEN NO_DATA_FOUND THEN

         RETURN FALSE;

  END;

 PROCEDURE PBuscaValorDevolucao (pIndice             OUT NUMBER,
                                 pValor              OUT NUMBER,
                                 pIndiceTrib         OUT NUMBER,
                                 pValorTrib          OUT NUMBER,
                                 pAnoRef              IN INTEGER,
                                 pMesRef              IN INTEGER
) IS

    vNuAnoPagamentoDifFerias    INTEGER;      -- Ano de pagamento da dif de ferias

    vNuMesPagamentoDifFerias    INTEGER;      -- Mes de pagamento da dif de ferias

    vVlPagamentoDifFerias       NUMBER(13,2); -- Valor de pagamento de dif de ferias

    vVlPagamentoFerias          NUMBER(13,2);

    vCdFolhaDifFerias           INTEGER;

    vCdFolhaFeriasAnt           INTEGER;

  BEGIN

     -- Consulta valor de pagamento de ferias

     vVlPagamentoFerias  := 0;
     pIndice             := 0;
     vCdFolhaFeriasAnt   := 0;

     BEGIN

       SELECT HRV.VlPagamento,
              HRV.VlIndiceRubrica,
              FP.CdFolhaPagamento
         INTO vVlPagamentoFerias,
              pIndice,
              vCdFolhaFeriasAnt
         FROM EPagHistoricoRubricaVinculo HRV
        INNER JOIN EPagFolhaPagamento FP
           ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
        WHERE HRV.CdVinculo = pCdVinculo AND
              HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubUmTercoFerias AND
              FP.NuAnoReferencia = pAnoRef AND
              FP.NuMesReferencia = pMesRef AND
              FP.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento AND
              FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
              FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS;

     EXCEPTION
       WHEN OTHERS THEN
           NULL;

     END;

     -- Pagamento de dif de ferias e realizado no mes seguinte ao pag. de ferias

     IF pMesRef <> 12 THEN
       vNuMesPagamentoDifFerias := pMesRef + 1;
       vNuAnoPagamentoDifFerias := pAnoRef;
     ELSE
       vNuMesPagamentoDifFerias := 1;
       vNuAnoPagamentoDifFerias := pAnoRef + 1;
     END IF;

     -- Consulta valor de pagamento de dif de ferias

     vVlPagamentoDifFerias := 0;
     vCdFolhaDifFerias     := 0;

     BEGIN

       SELECT HRV.VlPagamento,
              FP.CdFolhaPagamento
         INTO vVlPagamentoDifFerias,
              vCdFolhaDifFerias
         FROM EPagHistoricoRubricaVinculo HRV
        INNER JOIN EPagFolhaPagamento FP
           ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
        WHERE HRV.CdVinculo = pCdVinculo AND
              HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pFolha.CdAgrupamento,
                                                                      pCdTipoRubrica => 1,
                                                                      pNuRubrica     => 156)    AND
              FP.NuAnoReferencia = vNuAnoPagamentoDifFerias AND
              FP.NuMesReferencia = vNuMesPagamentoDifFerias AND
              FP.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento AND
              FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
              FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
        AND ROWNUM < 2;

     EXCEPTION

       WHEN OTHERS THEN
           NULL;

     END;

     -- Retorna Valores da Devolucao

     pValor              := vVlPagamentoFerias + vVlPagamentoDifFerias;

     -- Busca Tributacao

     pValorTrib   := 0;
     pIndiceTrib  := 0;

     BEGIN

       SELECT NVL(SUM(vlPagamento),0),
              NVL(SUM(vlIndiceRubrica),0)
         INTO pValorTrib,
              pIndiceTrib
         FROM EPagHistoricoRubricaVinculo HRV
        WHERE HRV.CdFolhaPagamento in ( vCdFolhaFeriasAnt, vCdFolhaDifFerias) AND
              HRV.CdVinculo = pCdVinculo AND
              HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias;

      EXCEPTION

       WHEN OTHERS THEN
           NULL;

      END;

  END;

 PROCEDURE PCriarDevolucao (pAnoReferencia IN INTEGER,
                            pMesReferencia IN INTEGER) IS

  vVlIndice                   NUMBER(7,4);

  vVlPagamento                NUMBER(13,2);

  vVlIndiceTrib               NUMBER(7,4);

  vVlPagTrib                  NUMBER(13,2);

 BEGIN

   -- Busca Valor da Devolucao

   PBuscaValorDevolucao (pIndice      => vvlIndice,
                         pValor       => vVlPagamento,
                         pIndiceTrib  => vVlIndiceTrib,
                         pValorTrib   => vVlPagTrib,
                         pAnoRef      => pAnoReferencia,
                         pMesRef      => pMesReferencia);

   -- Caso nao exista novo registro de ferias vigente no mes/ano de processamento ira devolver as ferias

   IF vVlPagamento > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => vvlPagamento,
                                             pVlIndice             => vvlIndice,
                                             pCdTipoOrigemRubrica  => 7);

/* nao mais
       IF vCdFeriasFruicaoPagamento > 0 THEN

         UPDATE EMovFeriasFruicaoPagamento FP
            SET FP.NuDiasDevolvidos = FP.NuDiasReceber,
                FP.NuDiasReceber = 0
          WHERE FP.CdFeriasFruicaoPagamento = vCdFeriasFruicaoPagamento;
       END IF;
*/

       IF vVlPagTrib > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pCdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pFolha.CdAgrupamento,
                                                                                                        pCdTipoRubrica => 4,
                                                                                                        pNuRubrica     => 544),
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => vVlPagTrib,
                                                  pVlIndice             => vvlIndiceTrib,
                                                  pCdTipoOrigemRubrica  => 10);
        END IF;

   END IF;

 END;

 FUNCTION FComUsufrutoNoMesAPagar (pCdPeriodoAquisitivoFerias IN INTEGER DEFAULT NULL,
                                   pCdVinculo                 IN INTEGER DEFAULT NULL) RETURN BOOLEAN IS

    vAux INTEGER;
 BEGIN

    IF pCdVinculo IS NOT NULL THEN

      SELECT 1
        INTO vAux
        FROM EMovPeriodoAquisitivoFerias PA
       INNER JOIN EMovFeriasFruicaoUsufruto FFU
          ON PA.CdPeriodoAquisitivoFerias = FFU.CdPeriodoAquisitivoFerias
       INNER JOIN EMovFeriasFruicaoPagamento FFP
          ON FFP.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto
       WHERE PA.CdVinculo = pCdVinculo AND
             FFU.DtInicial BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes AND
             FFU.FlAnulado ='N' AND FFU.InSituacao IN (1,2,3,11) AND
             FFP.FlPagamentoIndenizado = PKGPAG_TIPO.cnN AND
             ROWNUM < 2;

    ELSE

      SELECT 1
        INTO vAux
        FROM EMovPeriodoAquisitivoFerias PA
       INNER JOIN EMovFeriasFruicaoUsufruto FFU
          ON PA.CdPeriodoAquisitivoFerias = FFU.CdPeriodoAquisitivoFerias
       INNER JOIN EMovFeriasFruicaoPagamento FFP
          ON FFP.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto
       WHERE PA.CdPeriodoAquisitivoFerias = pCdPeriodoAquisitivoFerias AND
             FFU.DtInicial BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes AND
             FFU.FlAnulado ='N' AND FFU.InSituacao IN (1,2,3,11) AND
             FFP.FlPagamentoIndenizado = PKGPAG_TIPO.cnN AND
             ROWNUM < 2;

     END IF;

     RETURN TRUE;

 EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

 END;

BEGIN

  IF PKGPAG_VAR.vPagaSitDisposicao IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' )
     OR ( NOT FPossuiProventos(pFolha     => pFolha,
                               pCdVinculo => pCdVinculo) ) THEN

     RETURN;

  END IF;

  PCarregaGlobaisRubFerias (pCdVinculo  => pCdVinculo,
                            pFolha      => pFolha,
                            pRubrica    => pRubrica);

  -- Limite maximo de aceitacao de devolucao - 4 meses

  IF pFolha.NuMesReferencia > cLimitePrazoMesesDev THEN
     vNuAnoLimite :=  pFolha.NuAnoReferencia;
     vNuMesLimite :=  pFolha.NuMesReferencia - cLimitePrazoMesesDev;
  ELSE
     vNuAnoLimite := pFolha.NuAnoReferencia - 1;
     vNuMesLimite := 12 + pFolha.NuMesReferencia - cLimitePrazoMesesDev;
  END IF;

  -- Calcular

  vQtdeDias                  := 0;
  vGerarDiferenca            := -1; -- gerar se nao tiver registro no loop

  FOR rec IN cPagFeriasDev (pCdVinculo    => pCdVinculo,
                            pNuAnoMesDev  => pFolha.NuAnoReferencia * 100 +  pFolha.NuMesReferencia,
                            pNuAnoLim     => vNuAnoLimite,
                            pNuMesLim     => vNuMesLimite ) LOOP

    IF rec.NuDias > vQtdeDias THEN

       vQtdeDias := rec.NuDias;

    END IF;

    IF rec.CdPeriodoAquisitivoFerias <> rec.ProxPerAquisitivoFerias THEN

      -- Verifica se vai pagar este mes ferias deste mes, entao nao devolver o outro usufruto que era desejado

      vComUsufrutoNoMesAPagar := FComUsufrutoNoMesAPagar (pCdPeriodoAquisitivoFerias => rec.CdPeriodoAquisitivoFerias);

      vGerarDiferenca          := 0; -- tem registros no loop. So gerar se dentro do loop desejar

      IF vQtdeDias > 0 AND PKGPAG_VAR.vgOrgaoFeriasParam.InPagBeneficioFerias = 2 THEN

          -- possibilidade de estorno de beneficios

          -- Nao permitir  que seja feita a devolucao do 1/3 de ferias quando houver
          -- uma interrupcao de fruicao devido a um afastamento relacionado a gestacao

          IF NOT ( --vComUsufrutoNoMesAPagar OR
                   FAfastadoPorGravidez (pCdVinculo        => pCdVinculo,
                                         pDtInicioUsufruto => rec.DtInicial ) ) THEN

             IF PKGPAG_VAR.vgCdRubDevUmTercoFerias IS NOT NULL THEN
                pCriarDevolucao (pAnoReferencia => rec.NuAnoReferencia,
                                 pMesReferencia => rec.NuMesReferencia);

                -- Sistema so trabalha com um periodo aquisitivo, portanto, sair

                EXIT;

             END IF;

          END IF;

      ELSIF vComUsufrutoNoMesAPagar THEN

          -- Verifica se possui dias a receber de ferias no mes anterior

          vGerarDiferenca := 1;

          EXIT;

      else
        null;
      END IF;

      vQtdeDias := 0;

    END IF;

  END LOOP;

  IF vGerarDiferenca < 0 THEN -- Checar se tem dias a receber

     vComUsufrutoNoMesAPagar := FComUsufrutoNoMesAPagar (pCdVinculo => pCdVinculo);

     IF vComUsufrutoNoMesAPagar THEN

        vGerarDiferenca := 1;

     END IF;

  END IF;

  IF vGerarDiferenca = 1 THEN

    PGerarRubFerias (pCdVinculo             => pCdVinculo,
                     pFolha                 => pFolha,
                     pCdRubricaAgrupamento  => pRubrica.CdRubricaAgrupamento, -- devolucao de pagto 1/3 ferias
                     pNuMesPag              => gFerMesCalcAntFerias,
                     pNuAnoPag              => gFerAnoCalcAntFerias,
                     pFormExpr              => pFormExpr,
                     pFlDifFerias           => FALSE);

  END IF;

END;

PROCEDURE PUmTercoFeriasAnt(pCdVinculo  IN INTEGER,
                         pFolha      IN PKGPAG_TIPO.rFolha,
                         pRubrica    IN PKGPAG_TIPO.rRubrica,
                         pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

  vNuDiasReceber       INTEGER;

  vCdEstruturaCarreira INTEGER;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 1 THEN

    SELECT SUM(FFP.NuDiasReceber)
      INTO vNuDiasReceber
      FROM EMovPeriodoAquisitivoFerias PA
     INNER JOIN EMovFeriasFruicaoPagamento FFP
        ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
     INNER JOIN EMovFeriasFruicaoUsufruto FFU
        ON FFU.CdFeriasProgramacaoUsufruto = FFP.CdFeriasProgramacaoUsufruto
     WHERE PA.CdVinculo = pCdVinculo AND
           FFP.NuAnoReferencia = pFolha.NuAnoReferencia AND
           FFP.NuMesReferencia = pFolha.NuMesReferencia AND
           FFU.InSituacao NOT IN (4,12) AND
           FFP.FlPagamentoIndenizado = PKGPAG_TIPO.cnN AND
           FFP.FlAnulado = PKGPAG_TIPO.cnN;

    IF NVL(vNuDiasReceber,0) > 0 THEN

      IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

        vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

      END IF;

      vCdExpressaoFormCalc :=

           PKGPAG_GERAL.FIdentificaFormulaCalculo(
                        pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                        pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                        pCdRelacaoVinculo         => 0,
                        pCdEstruturaCarreira      => vCdEstruturaCarreira);

      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => vNuDiasReceber,
                                              pCdTipoOrigemRubrica  => 7);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => pRubrica.CdRubricaAgrupamento,
                                         pTpProcessamento => 1,
                                         pTpLocal         => 2); -- Vinculo

      END IF;

    END IF;

  END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;

END;

PROCEDURE PDiferencaUmTercoFeriasAnt(pCdVinculo  IN INTEGER,
                                  pFolha      IN PKGPAG_TIPO.rFolha,
                                  pRubrica    IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

  vNuDiasReceber       INTEGER;

  vNuMesReferencia     INTEGER;

  vNuAnoReferencia     INTEGER;

  vCdEstruturaCarreira INTEGER;

  vCdExpressaoFormCalc INTEGER;

  vInSituacao          INTEGER;

BEGIN

  IF PKGPAG_VAR.vPagaSitDisposicao NOT IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' ) THEN

    IF pFolha.CdAgrupamento <> 2 THEN

      IF pFolha.NuMesReferencia = 1 THEN

        vNuMesReferencia := 12;

        vNuAnoReferencia := pFolha.NuAnoReferencia - 1;

      ELSE

        vNuMesReferencia := pFolha.NuMesReferencia - 1;

        vNuAnoReferencia := pFolha.NuAnoReferencia;

      END IF;

    ELSE

      vNuMesReferencia := pFolha.NuMesReferencia;

      vNuAnoReferencia := pFolha.NuAnoReferencia;

    END IF;

    -- Verifica se possui dias a receber de ferias

    SELECT SUM(FFP.NuDiasReceber)
      INTO vNuDiasReceber
      FROM EMovPeriodoAquisitivoFerias PA
     INNER JOIN Emovferiasfruicaopagamento FFP
        ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
     INNER JOIN Emovferiasfruicaousufruto FFU
        ON FFU.CdPeriodoAquisitivoFerias = PA.CdPeriodoAquisitivoFerias AND
           FFP.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto
     WHERE PA.CdVinculo = pCdVinculo AND
           FFP.NuAnoReferencia = vNuAnoReferencia AND
           FFP.NuMesReferencia = vNuMesReferencia AND
           FFP.FlPagamentoIndenizado = PKGPAG_TIPO.cnN;

    -- Verifica a situacao do usufruto das ferias,
    -- e caso nao exista, o vInSituacao recebe null

    BEGIN

      SELECT InSituacao
        INTO vInSituacao
        FROM EMovperiodoaquisitivoferias PA
       INNER JOIN EMovFeriasFruicaoUsufruto FFU
          ON PA.CdPeriodoAquisitivoFerias = FFU.CdPeriodoAquisitivoFerias
        WHERE PA.CdVinculo = pCdVinculo AND
             FFU.DtInicial BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes AND
             FFU.FlAnulado = 'N' AND FFU.InSituacao NOT IN (2,3,4,5,12) AND
             ROWNUM < 2;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        vInSituacao := NULL;

    END;

    IF vNuDiasReceber > 0 AND vInSituacao NOT IN (2,3,4,5,12) THEN

      IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

        vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

      END IF;

      vCdExpressaoFormCalc :=

           PKGPAG_GERAL.FIdentificaFormulaCalculo(
                        pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                        pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                        pCdRelacaoVinculo         => 0,
                        pCdEstruturaCarreira      => vCdEstruturaCarreira);

      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => vNuDiasReceber,
                                              pCdTipoOrigemRubrica  => 7);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => pRubrica.CdRubricaAgrupamento,
                                         pTpProcessamento => 1,
                                         pTpLocal         => 2); -- Vinculo

      END IF;

    END IF;

  END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;

END;

PROCEDURE PDevolucaoUmTercoFeriasAnt(pCdVinculo  IN INTEGER,
                                  pFolha      IN PKGPAG_TIPO.rFolha,
                                  pRubrica    IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

  vNuDiasReceber              INTEGER;

  vNuMesReferencia            INTEGER;

  vNuAnoReferencia            INTEGER;

  --vNuAnoPagamento             INTEGER;

  --vNuMesPagamento             INTEGER;

  vVlPagamento                NUMBER(13,2);

  vInSituacao                 INTEGER;

  vVlIndice                   NUMBER(7,4);

  vCdFolhaAnterior            INTEGER;

  vFlFruicaoAnulada           CHAR(1);

  vInSitFeriasVigente         INTEGER;

  vCdEstruturaCarreira        INTEGER;

  vCdExpressaoFormCalc        INTEGER;

  vCdFeriasFruicaoPagamento   INTEGER;

  vDtFimAfastamentoVinculo    DATE;

  vCdAfastamentoGravidez      INTEGER;

  vCdFolhaDifFerias           INTEGER;      -- CD Folha de pagamento da dif de ferias

  vNuAnoPagamentoDifFerias    INTEGER;      -- Ano de pagamento da dif de ferias

  vNuMesPagamentoDifFerias    INTEGER;      -- Mes de pagamento da dif de ferias

  vVlPagamentoDifFerias       NUMBER(13,2); -- Valor de pagamento de dif de ferias

  vNuMinDiasEstorno           INTEGER :=0;  -- Numero minimo de dias no orgao para devolucao de um terco

BEGIN

  IF PKGPAG_VAR.vPagaSitDisposicao NOT IN ('PAG-DEST-CALCULO-ORIGEM','PAG-ORIGEM-CALCULO-DEST' ) AND
     FPossuiProventos(pFolha     => pFolha,
                      pCdVinculo => pCdVinculo) THEN

    IF pFolha.NuMesReferencia = 1 THEN

      vNuMesReferencia := 12;

      vNuAnoReferencia := pFolha.NuAnoReferencia - 1;

    ELSE

      vNuMesReferencia := pFolha.NuMesReferencia - 1;

      vNuAnoReferencia := pFolha.NuAnoReferencia;

    END IF;

    --------------------------------------------------------------------
    -- Verifica a situacao do usufruto das ferias e caso nao exista, o vInSituacao recebe null
    --------------------------------------------------------------------
    BEGIN

       SELECT ORT.NUMINDIASESTORNO
         INTO vNuMinDiasEstorno
         FROM Emovorgaoreltrabalhoferias ORT
        WHERE ORT.Cdorgao = PKGPAG_VAR.vgCdOrgaoVinculo
          AND ORT.CDRELACAOTRABALHO = PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento
          AND ORT.DTFIMVIGENCIA IS NULL;

       EXCEPTION

          WHEN NO_DATA_FOUND THEN

             vNuMinDiasEstorno := 10;
    END;

    BEGIN

      SELECT InSituacao,
             FlAnulado,
             NuAnoReferencia,
             NuMesReferencia,
             CdFeriasFruicaoPagamento,
             DtFimAfastamentoVinculo
        INTO vInSituacao,
             vFlFruicaoAnulada,
             vNuAnoReferencia,
             vNuMesReferencia,
             vCdFeriasFruicaoPagamento,
             vDtFimAfastamentoVinculo
        FROM
      (

      -- Verifica se as ferias usufruidas foram suspensas
      SELECT FFU.InSituacao,
              FFU.FlAnulado,
              vNuAnoReferencia AS NuAnoReferencia,
              vNuMesReferencia AS NuMesReferencia,
              NULL AS CdFeriasFruicaoPagamento,
              NULL AS DtFimAfastamentoVinculo
        FROM EMovPeriodoAquisitivoFerias PA
       INNER JOIN EMovFeriasFruicaoUsufruto FFU
          ON PA.CdPeriodoAquisitivoFerias = FFU.CdPeriodoAquisitivoFerias
        WHERE PA.CdVinculo = pCdVinculo AND
              FFU.DtInicial BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes AND
              FFU.InSituacao IN (5,12) AND
              FFU.FlAnulado = PKGPAG_TIPO.cnN

       UNION ALL

       -- Verifica anulacao do usufruto de ferias dentro do exercicio
       SELECT FFU.InSituacao,
              FFU.FlAnulado,
              FP.NuAnoReferencia,
              FP.NuMesReferencia,
              NULL AS CdFeriasFruicaoPagamento,
              NULL AS DtFimAfastamentoVinculo
        FROM EMovPeriodoAquisitivoFerias PA
       INNER JOIN EMovFeriasFruicaoUsufruto FFU
          ON PA.CdPeriodoAquisitivoFerias = FFU.CdPeriodoAquisitivoFerias
       INNER JOIN EMovFeriasFruicaoPagamento FP
          ON FP.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto
       WHERE PA.CdVinculo = pCdVinculo AND
              FFU.FlAnulado = PKGPAG_TIPO.cnS AND
              FFU.DtAnulado BETWEEN TRUNC(pFolha.DtCalculoAnt+1) AND TRUNC(pFolha.DtCalculo)

       UNION ALL
        -- Solicitacao 38477
        -- Na interrupcao de ferias fazer o estorno da gratificacao de ferias quando a quantidade de dias
        -- usufruidos for inferior a 10.
        SELECT InSituacao,
               FlAnulado,
               NuAnoReferencia,
               NuMesReferencia,
               CdFeriasFruicaoPagamento,
               DtFimAfastamentoVinculo
          FROM (SELECT FFU.InSituacao,
                       FFU.FlAnulado,
                       FP.NuAnoReferencia,
                       FP.NuMesReferencia,
                       FP.CdFeriasFruicaoPagamento,
                       FFU.NUDIAS NuDiasUsufruidos,
                       -- SUM(CASE
                       --      WHEN (AV.FlAnulado = 'N') OR (FI.Dtinicio = FFU.Dtinicial) THEN
                       --         FI.DtFinal-FI.DtInicio + 1
                       --    ELSE
                       --      0
                       --    END) NuDiasInterrompidos,
                       AV.DtFim AS DtFimAfastamentoVinculo
                  FROM EMovPeriodoAquisitivoFerias PA
                 INNER JOIN EMovFeriasFruicaoUsufruto FFU
                    ON PA.CdPeriodoAquisitivoFerias = FFU.CdPeriodoAquisitivoFerias
                 INNER JOIN EMovFeriasFruicaoPagamento FP
                    ON FP.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto
                 INNER JOIN EMovFeriasFruicaoInterrupcao FI
                    ON FI.CdFeriasProgramacaoUsufruto = FFU.CdFeriasProgramacaoUsufruto
                 INNER JOIN EAfaAfastamentoVinculo AV
                    ON AV.CdVinculo = PA.CdVinculo AND
                       FFU.DtInicial BETWEEN AV.DtInicio AND AV.DtFim
                 INNER JOIN EAfaHistMotivoAfastTemp HMAT
                    ON AV.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
                 WHERE PA.CdVinculo = pCdVinculo AND
                       FI.DtInclusao BETWEEN PKGPAG_VAR.vDtCalculoAnt+1 AND PKGPAG_VAR.vDtCalculo AND
                       ((HMAT.DtInicioVigencia <= PKGPAG_VAR.vDtCalculo AND PKGPAG_VAR.vDtCalculo <= HMAT.DtFimVigencia)
                         OR HMAT.DtFimVigencia IS NULL)
                        AND
                       ((FFU.InSituacao IN (7, 8) -- AND  FP.NuDiasReceber > 0
                       )) AND
                       HMAT.FlGravidez = PKGPAG_TIPO.cnN AND
                       AV.FlAnulado = PKGPAG_TIPO.cnN AND
                       FP.FlPagamentoIndenizado = PKGPAG_TIPO.cnN
                 GROUP BY FFU.InSituacao,
                          FFU.FlAnulado,
                          FP.NuAnoReferencia,
                          FP.NuMesReferencia,
                          FP.CdFeriasFruicaoPagamento,
                          AV.DtFim,
                          FFU.NuDias )
        WHERE NuDiasUsufruidos < vNuMinDiasEstorno -- Parametro que determina a quantidade de dias para estorno.

               )
       WHERE ROWNUM < 2;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        vInSituacao := NULL;

        vFlFruicaoAnulada := NULL;

    END;

    --- Verifica se as ferias usufruidas neste mes NAO foram anuladas ou suspensas,ou seja,
    --  de fato gozadas

    BEGIN

      SELECT FFU.InSituacao
        INTO vInSitFeriasVigente
        FROM EMovPeriodoAquisitivoFerias PA
       INNER JOIN EMovFeriasFruicaoUsufruto FFU
          ON PA.CdPeriodoAquisitivoFerias = FFU.CdPeriodoAquisitivoFerias
       WHERE PA.CdVinculo = pCdVinculo AND
             FFU.DtInicial BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes AND
             FFU.FlAnulado ='N' AND FFU.InSituacao IN (1,2,3,11) AND
             ROWNUM < 2;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        vInSitFeriasVigente := NULL;

    END;

    BEGIN

     -- Caso a situacao da fruicao esteja suspensa ou anulada com possibilidade de estorno de beneficios

       IF (vInSituacao IN (5,12,7,8) OR vFlFruicaoAnulada = 'S') AND PKGPAG_VAR.vgOrgaoFeriasParam.InPagBeneficioFerias = 2 THEN

         -- Consulta valor de pagamento de ferias

         BEGIN

           SELECT HRV.VlPagamento,
                  HRV.VlIndiceRubrica,
                  FP.CdFolhaPagamento
             INTO vvlPagamento,
                  vvlIndice,
                  vCdFolhaAnterior
             FROM EPagHistoricoRubricaVinculo HRV
            INNER JOIN EPagFolhaPagamento FP
               ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
            WHERE HRV.CdVinculo = pCdVinculo AND
                  HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubUmTercoFerias AND
                  FP.NuAnoReferencia = vNuAnoReferencia AND
                  FP.NuMesReferencia = vNuMesReferencia AND
                  FP.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento AND
                  FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                  FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS;

         EXCEPTION

           WHEN NO_DATA_FOUND THEN

             vVlPagamento := 0;

         END;

         -- Consulta valor de pagamento de dif de ferias

         BEGIN

           -- Pagamento de dif de ferias e realizado no mes seguinte ao pag. de ferias
           IF vNuMesReferencia <> 12 THEN
             vNuMesPagamentoDifFerias := vNuMesReferencia + 1;
             vNuAnoPagamentoDifFerias := vNuAnoReferencia;
           ELSE
             vNuMesPagamentoDifFerias := 1;
             vNuAnoPagamentoDifFerias := vNuAnoReferencia + 1;
           END IF;

           SELECT HRV.VlPagamento,
                  FP.CdFolhaPagamento
             INTO vVlPagamentoDifFerias,
                  vCdFolhaDifFerias
             FROM EPagHistoricoRubricaVinculo HRV
            INNER JOIN EPagFolhaPagamento FP
               ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
            WHERE HRV.CdVinculo = pCdVinculo AND
                  HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pFolha.CdAgrupamento,
                                                                          pCdTipoRubrica => 1,
                                                                          pNuRubrica     => 156)    AND
                  FP.NuAnoReferencia = vNuAnoPagamentoDifFerias AND
                  FP.NuMesReferencia = vNuMesPagamentoDifFerias AND
                  FP.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento AND
                  FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                  FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
            AND ROWNUM < 2;

         EXCEPTION

           WHEN NO_DATA_FOUND THEN

             vVlPagamentoDifFerias := 0;
             vCdFolhaDifFerias     := 0;

         END;

         -- Valor devolucao: valor pagamento de ferias + valor pagamento dif ferias

         vVlPagamento := vVlPagamento + vVlPagamentoDifFerias;

         -- Nao permitir  que seja feita a devolucao do 1/3 de ferias quando houver
         -- uma interrupcao de fruicao devido a um afastamento relacionado a gestacao

         BEGIN

            SELECT AV.CdAfastamento
            INTO   vCdAfastamentoGravidez
            FROM   EAfaAfastamentoVinculo AV
            INNER  JOIN EAfaHistMotivoAfastTemp HMAT
                ON AV.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
            WHERE   AV.CdVinculo = pCdVinculo
            AND     AV.FlAnulado = PKGPAG_TIPO.cnN
            AND     HMAT.FlAnulado = PKGPAG_TIPO.cnN
            AND     HMAT.FlGravidez = PKGPAG_TIPO.cnS
            AND     AV.DtInicio = to_date(vDtFimAfastamentoVinculo) + 1;

         EXCEPTION

           WHEN NO_DATA_FOUND THEN

             vCdAfastamentoGravidez := NULL;

         END;

         -- Caso nao exista novo registro de ferias vigente no mes/ano de processamento ira devolver as ferias

         IF vInSitFeriasVigente IS NULL AND vCdAfastamentoGravidez IS NULL AND vVlPagamento > 0 THEN

           IF PKGPAG_VAR.vgCdRubDevUmTercoFerias IS NOT NULL THEN

             PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                   pCdVinculo            => pCdVinculo,
                                                   pCdExpressaoFormCalc  => NULL,
                                                   pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                   pNuSufixoRubrica      => 1,
                                                   pVlPagamento          => vvlPagamento,
                                                   pVlIndice             => vvlIndice,
                                                   pCdTipoOrigemRubrica  => 7);

             IF vCdFeriasFruicaoPagamento > 0 THEN

               UPDATE EMovFeriasFruicaoPagamento FP
                  SET FP.NuDiasDevolvidos = FP.NuDiasReceber,
                      FP.NuDiasReceber = 0
                WHERE FP.CdFeriasFruicaoPagamento = vCdFeriasFruicaoPagamento;

             END IF;

             BEGIN

               SELECT SUM(vlPagamento),
                      SUM(vlIndiceRubrica)
                 INTO vVlPagamento,
                      vVlIndice
                 FROM EPagHistoricoRubricaVinculo HRV
                WHERE HRV.CdFolhaPagamento in ( vCdFolhaAnterior, vCdFolhaDifFerias) AND
                      HRV.CdVinculo = pCdVinculo AND
                      HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias;

        IF NVL(vVlPagamento,0) > 0 THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                            pCdVinculo            => pCdVinculo,
                            pCdExpressaoFormCalc  => NULL,
                            pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pFolha.CdAgrupamento,
                                                       pCdTipoRubrica => 4,
                                                       pNuRubrica     => 544),
                            pNuSufixoRubrica      => 1,
                            pVlPagamento          => vVlPagamento,
                            pVlIndice             => vvlIndice,
                            pCdTipoOrigemRubrica  => 10);
        END IF;
              END;

            END IF;

          END IF;

       -- Se houve ferias gozadas este mes sem ter sido anulada ou suspensa -- ROGERIO

       ELSIF vInSitFeriasVigente IS NOT NULL THEN

          -- Verifica se possui dias a receber de ferias no mes anterior

          SELECT SUM(FFP.NuDiasReceber)
            INTO vNuDiasReceber
            FROM EMovPeriodoAquisitivoFerias PA
           INNER JOIN EMovFeriasFruicaoPagamento FFP
              ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
           WHERE PA.CdVinculo = pCdVinculo AND
                 FFP.NuAnoReferencia = vNuAnoReferencia AND
                 FFP.NuMesReferencia = vNuMesReferencia;

          IF vNuDiasReceber > 0 THEN

            IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

               vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

            END IF;

            vCdExpressaoFormCalc :=

                 PKGPAG_GERAL.FIdentificaFormulaCalculo(
                              pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                              pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                              pCdRelacaoVinculo         => 0,
                              pCdEstruturaCarreira      => vCdEstruturaCarreira);

            IF vCdExpressaoFormCalc > 0 THEN

              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                    pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => vNuDiasReceber,
                                                    pCdTipoOrigemRubrica  => 7);

              PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                               pCdVinculo       => pCdVinculo,
                                               pCdRubrica       => pRubrica.CdRubricaAgrupamento,
                                               pTpProcessamento => 1,
                                               pTpLocal         => 2); -- Vinculo

           END IF;

        END IF;

      else
        null;
      END IF;

    EXCEPTION

      WHEN NO_DATA_FOUND  THEN

        NULL;

    END;

   END IF;

END;

PROCEDURE PUmTercoFerias(pCdVinculo  IN INTEGER,
                         pFolha      IN PKGPAG_TIPO.rFolha,
                         pRubrica    IN PKGPAG_TIPO.rRubrica,
                         pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS
BEGIN

   --SIG-6660
   --Se houver lançamento financeiro, não calcula a rubrica. Mantem o valor cadastrado.
   IF NOT (pkgpag_geral.fpossuilancfinanceiro(pcdvinculo => pCdVinculo,
                                         pfolha => pFolha,
                                         pcdrubrica => pRubrica.CdRubricaAgrupamento)
      AND PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo => pCdVinculo,
                                        pcdrubrica => pRubrica.CdRubricaAgrupamento) > 0)
     THEN

     IF VERSAO_FERIAS = 'N' THEN

        PUmTercoFeriasNov (pCdVinculo  => pCdVinculo,
                           pFolha      => pFolha,
                           pRubrica    => pRubrica,
                           pFormExpr   => pFormExpr);

     ELSE

        PUmTercoFeriasAnt (pCdVinculo  => pCdVinculo,
                           pFolha      => pFolha,
                           pRubrica    => pRubrica,
                           pFormExpr   => pFormExpr);

     END IF;
  END IF;

END;

PROCEDURE PDiferencaUmTercoFerias(pCdVinculo  IN INTEGER,
                                  pFolha      IN PKGPAG_TIPO.rFolha,
                                  pRubrica    IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS
BEGIN

   IF VERSAO_FERIAS = 'N' THEN

      PDiferencaUmTercoFeriasNov (pCdVinculo  => pCdVinculo,
                                  pFolha      => pFolha,
                                  pRubrica    => pRubrica,
                                  pFormExpr   => pFormExpr);

   ELSE

      PDiferencaUmTercoFeriasAnt (pCdVinculo  => pCdVinculo,
                                  pFolha      => pFolha,
                                  pRubrica    => pRubrica,
                                  pFormExpr   => pFormExpr);

   END IF;

END;

PROCEDURE PDevolucaoUmTercoFerias(pCdVinculo  IN INTEGER,
                                  pFolha      IN PKGPAG_TIPO.rFolha,
                                  pRubrica    IN PKGPAG_TIPO.rRubrica,
                                  pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS
BEGIN

   IF VERSAO_FERIAS = 'N' THEN

      PDevolucaoUmTercoFeriasNov (pCdVinculo  => pCdVinculo,
                                  pFolha      => pFolha,
                                  pRubrica    => pRubrica,
                                  pFormExpr   => pFormExpr);

   ELSE

      PDevolucaoUmTercoFeriasAnt (pCdVinculo  => pCdVinculo,
                                  pFolha      => pFolha,
                                  pRubrica    => pRubrica,
                                  pFormExpr   => pFormExpr);

   END IF;

END;

PROCEDURE PAjustarSaldoDevedor13(pCdVinculo           IN INTEGER,
                                 pFolha               IN PKGPAG_TIPO.rFolha) IS
  vVlRubBaseTetoGov    NUMBER (13,2);
  vVlLimite            NUMBER (13,2);
  vVlSaldoDevedor      NUMBER (13,2);
  vVlSaldoDescontado   NUMBER (13,2);
  vVlSaldoPendente     NUMBER (13,2);
  vCdsFolhasReferencia sys.odcinumberlist;

  FUNCTION FObterValorLimite(pVlRubBaseTetoGov     IN NUMBER,
                             pVlTotalDescErarioMes IN NUMBER) RETURN NUMBER IS
    vVlLimite NUMBER (13,2);
  BEGIN

    vVlLimite := pVlRubBaseTetoGov * 0.10;

    IF NVL(pVlTotalDescErarioMes,0) > 0
      AND NVL(pVlTotalDescErarioMes,0) >= vVlLimite THEN
        vVlLimite := 0;

    ELSIF  NVL(pVlTotalDescErarioMes,0) > 0 THEN
      vVlLimite := vVlLimite - pVlTotalDescErarioMes;

    ELSE
      NULL;

    END IF;

    RETURN vVlLimite;
  END;

  FUNCTION FObterValorRubrica(pCdsFolhasPagamento   IN sys.odcinumberlist,
                              pCdVinculo            IN INTEGER,
                              pCdRubricaAgrupamento IN INTEGER) RETURN NUMBER IS

    vVlRubrica NUMBER(13, 2);
  BEGIN

    SELECT sum(vlpagamento)
      INTO vVlRubrica
      FROM epaghistoricorubricavinculo hrv
     WHERE HRV.CdFolhaPagamento IN (SELECT column_value FROM TABLE(pCdsFolhasPagamento))
       AND HRV.CdVinculo = pCdVinculo
       AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento
     GROUP BY HRV.CDRUBRICAAGRUPAMENTO;

    RETURN vVlRubrica;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FObterFolhasDefMesAnterior(pFolha IN PKGPAG_TIPO.rFolha) RETURN sys.odcinumberlist IS
    vCdsFolhas sys.odcinumberlist := sys.odcinumberlist();
    vNuAnoReferencia INTEGER;
    vNuMesReferencia INTEGER;
  BEGIN

    vNuAnoReferencia := pFolha.NuAnoReferencia;
    vNuMesReferencia := pFolha.NuMesReferencia;
    IF (vNuMesReferencia = 1) THEN
      vNuMesReferencia := 12;
      vNuAnoReferencia := vNuAnoReferencia - 1;
    ELSE
      vNuMesReferencia := vNuMesReferencia - 1;
    END IF;

    SELECT CDFOLHAPAGAMENTO
      BULK COLLECT
      INTO vCdsFolhas
      FROM EPAGFOLHAPAGAMENTO
     WHERE NUANOREFERENCIA = vNuAnoReferencia
       AND NUMESREFERENCIA = vNuMesReferencia
       AND FLCALCULODEFINITIVO = 'S';

    RETURN vCdsFolhas;
  END;

BEGIN

  vCdsFolhasReferencia:= FObterFolhasDefMesAnterior(pFolha => pFolha);

  vVlSaldoDevedor := FObterValorRubrica(pCdsFolhasPagamento => vCdsFolhasReferencia,
                                        pCdVinculo => pCdVinculo,
                                        pCdRubricaAgrupamento => pkgpag_var.vgParamPagamento.CdRubAgrupAjusteSaldoDevedor13);

  IF vVlSaldoDevedor > 0 THEN
    vVlRubBaseTetoGov:= PKGPAG_GERAL.fretornavalorrubrica(pcdvinculo => pCdVinculo,
                                                          pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                          pcdrubrica => PKGPAG_VAR.vgCdRubricaBaseTetoGov);

    vVlLimite := FObterValorLimite(pVlRubBaseTetoGov => vVlRubBaseTetoGov,
                                   pVlTotalDescErarioMes => PKGPAG_VAR.vgVlTotalDescErarioMes);


    vVlSaldoDescontado := vVlSaldoDevedor;
    vVlSaldoPendente   := 0;
    IF vVlSaldoDevedor > vVlLimite THEN
      vVlSaldoDescontado := vVlLimite;
      vVlSaldoPendente   := vVlSaldoDevedor - vVlSaldoDescontado;
    END IF;

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => pkgpag_var.vgParamPagamento.CDRUBAGRUPDEVAJUSTESALDODEV13,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => vVlSaldoDescontado,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

    IF vVlSaldoPendente > 0 THEN
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pkgpag_var.vgParamPagamento.CDRUBAGRUPAJUSTESALDODEVEDOR13,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => vVlSaldoPendente,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);
    END IF;

  END IF;

END;

--
-- Implementacao: Estudar alteracao posterior para que o calculo do 13º inclui processo de restituicao
-- Nº da solicitacao: 8002/2016
-- Assunto: FOLHA - FOLHA DE JANEIRO 2016 DESCONTO 08-0023 E 08-0024
-- NA FOLHA DE DEZEMBRO/2015, ALGUNS SERVIDORES FICARAM COM SALDO DE 13º PARA DEVOLVER AO ESTADO.
-- ESTE VALOR FICOU EM UMA TOTALIZADORA: 09-9023 E 09-9024, E DEVERIA SER DESCONTADO NAS FOLHAS
-- SEGUINTES AUTOMATICAMENTE, OBEDECENDO A BASE DE 10% DA REMUNERACAO (BASE DO ERARIO)
-- ATE QUE ZERE O SALDO.
--

PROCEDURE PSaldoDevolucao13(pCdVinculo  IN INTEGER,
                            pFolha      IN PKGPAG_TIPO.rFolha) IS

vVlBase983    NUMBER (13,2);
vVlSaldo      NUMBER (13,2);
vVlSaldo9023  NUMBER(13,2);
--vVlSaldo9524  NUMBER(13,2) :=0;
vVlLimite     NUMBER (13,2);
vCdRub        INTEGER;
vCdFolha13    integer;
vCdRubrica9524 integer;
vVlBaseProventos NUMBER(13,2);
--vCdRubDevAnt13NaoEfetuado INTEGER;
--vVlDevAnt13NaoEfetuado NUMBER(13,2) :=0;


-- Verificar se tem folha de 13 definitiva no mes anterior
Function fFolha13MesAnt (pCdFolhaNormalAnt IN INTEGER)
  return integer is

  vCdFolha13Ant integer;

  begin

    with fol as (select f.cdorgao, f.nuanomesreferencia
                   from epagfolhapagamento f
                  where f.cdfolhapagamento = pCdFolhaNormalAnt)
    select ff.cdFolhaPagamento
      into vCdFolha13Ant
      from Epagfolhapagamento ff
      INNER JOIN epagtipofolhapagamento tfp
          ON ff.cdtipofolhapagamento = tfp.cdtipofolhapagamento
     inner join fol f on f.cdorgao = ff.cdorgao
                     and f.nuanomesreferencia = ff.nuanomesreferencia
     where ff.flcalculodefinitivo = 'S'
       and tfp.cdtipofolha = pkgpag_tipo.cnTpFolha13;

    return vCdFolha13Ant;

    exception
      when no_data_found
        then return 0;
      when others
        then return 0;

end;

Function fRetornaCdRubrica (pNuRubrica IN INTEGER,
                            pCdTipoRubrica IN INTEGER)
  return integer is

  vCdRubrica INTEGER;

begin

  SELECT ER.Cdrubricaagrupamento
    INTO vCdRubrica
    FROM EpagRubricaAgrupamento ER
    INNER JOIN EPagRubrica EP ON ER.Cdrubrica = Ep.Cdrubrica
    WHERE EP.NURUBRICA = pNuRubrica
      AND EP.CDTIPORUBRICA = pCdTipoRubrica
      AND ER.Cdagrupamento = PKGPAG_VAR.vgFolha.CdAgrupamento;

  Return vCdRubrica;

  Exception
   When Others
     THEN

       Return 0;

 End;

BEGIN

   BEGIN

      SELECT HRV.VLPAGAMENTO
        INTO vVlBase983
        FROM Epaghistoricorubricavinculo HRV
       WHERE HRV.Cdfolhapagamento = pFolha.CdFolhaPagamento
         AND HRV.CDVINCULO = pCdVinculo
         AND HRV.Cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseTetoGov;

      EXCEPTION
        WHEN NO_DATA_FOUND
          THEN
            vVlBase983 := 0;

        WHEN OTHERS
          THEN
            vVlBase983 := 0;

      END;

      vVlLimite := vVlBase983 * 0.10;

   IF NVL(PKGPAG_VAR.vgVlTotalDescErarioMes,0) > 0
      AND NVL(PKGPAG_VAR.vgVlTotalDescErarioMes,0) >= vVlLimite
      THEN

        vVlLimite := 0;

   ELSIF  NVL(PKGPAG_VAR.vgVlTotalDescErarioMes,0) > 0
      THEN
       vVlLimite := vVlLimite - PKGPAG_VAR.vgVlTotalDescErarioMes;

   else
     null;
   END IF;

   IF PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                        pCdVinculo => pCdVinculo,
                                        pcdrubrica => PKGPAG_VAR.vgCdRubBase080023DescParcial) > 0

      THEN

      vVlSaldo9023 := PKGPAG_GERAL.fretornavalorrubrica(pCdFolhapagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                                        pCdVinculo => pCdVinculo,
                                                        pCdRubrica => PKGPAG_VAR.vgCdRubBase080023DescParcial);

         vVlSaldo := vVlSaldo9023;

      IF vVlSaldo > vVlLimite
        THEN

            vVlSaldo := vVlLimite;

      END IF;

      -- Inserir SALDO do desconto parcial da rubrica 08-0023 na rubrica 09-9023

      IF vVlSaldo9023 > vVlLimite
          THEN
           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                                 pCdVinculo            => pCdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBase080023DescParcial,
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => (vVlSaldo9023 - vVlLimite),
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 1);

           vVlLimite := 0;

       ELSE

           vVlLimite := vVlLimite - vVlSaldo9023;

       END IF;

   --
   -- Solicitacao de Sustentacao #73486
   -- 9573/2016 - FOLHA AJUSTES DE 13
   --
   ELSIF FRetornaValorExpressao(pFolha.CdFolhaPagamento, pCdVinculo,
                                pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,1,1023)) < 0

      THEN

         vVlSaldo := FRetornaValorExpressao(pFolha.CdFolhaPagamento, pCdVinculo,
                                               pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,1,1023)) * -1;

         if vVlSaldo > pkgpag_var.vgVlTotalProventos
           THEN
             vVlSaldo := pkgpag_var.vgVlTotalProventos;

         end if;

   else
     null;
   END IF;

   vCdRub := fRetornaCdRubrica(23,8);

   IF vVlSaldo > 0 and not pkgpag_geral.fpossuilancfinanceiro(pcdvinculo => pCdVinculo,pfolha => pFolha,pcdrubrica => vCdRub)
     THEN

      vCdRub := fRetornaCdRubrica(23,8);

      INSERT
        INTO EPagHistoricoRubricaVinculo
            (CdHistoricoRubricaVinculo,
             CdFolhaPagamento,
             CdRubricaAgrupamento,
             CdVinculo,
             NuSufixoRubrica,
             CdLancamentoFinanceiro,
             VlPagamento,
             QtParcelas,
             VlIndiceRubrica,
             DtUltAlteracao,
             CdTipoOrigemRubrica)
      VALUES
            (Spaghistoricorubricavinculo.NEXTVAL,
             pFolha.CdFolhaPagamento,
             vCdRub,
             pCdVinculo,
             1,
             NULL,
             vVlSaldo,
             1,
             0,
             systimestamp,
             16);

     END IF;

   vCdFolha13 := fFolha13MesAnt(pFolha.CdFolhaPagamentoNormalAnt);

   vCdRubrica9524 := fRetornaCdRubrica(9524,9);

   vCdRub := fRetornaCdRubrica(24,8);

   -- Caso ja exista valor na rubrica 08-0024 nao gera
   -- # 78545
   IF PKGPAG_GERAL.FGeraRubrica(vCdRub) then

     if (PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                            pCdVinculo        => pCdVinculo,
                                                            pCdRubrica        => vCdRub) = 0

          AND PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo => pCdVinculo,
                                        pcdrubrica => PKGPAG_VAR.vgCdRubBase080024DescParcial) = 0
         AND
         (PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                        pCdVinculo => pCdVinculo,
                                        pcdrubrica => PKGPAG_VAR.vgCdRubBase080024DescParcial) > 0
         OR

          PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => vCdFolha13,
                                            pCdVinculo => pCdVinculo,
                                            pcdrubrica => vCdRubrica9524) > 0))



      THEN

      vVlSaldo := PKGPAG_GERAL.fretornavalorrubrica(pCdFolhapagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                                    pCdVinculo => pCdVinculo,
                                                    pCdRubrica => PKGPAG_VAR.vgCdRubBase080024DescParcial);

      vVlSaldo := vVlSaldo +
                  PKGPAG_GERAL.fretornavalorrubrica(pCdFolhapagamento => vCdFolha13,
                                                    pCdVinculo => pCdVinculo,
                                                    pCdRubrica => vCdRubrica9524);

      INSERT
        INTO EPagHistoricoRubricaVinculo
            (CdHistoricoRubricaVinculo,
             CdFolhaPagamento,
             CdRubricaAgrupamento,
             CdVinculo,
             NuSufixoRubrica,
             CdLancamentoFinanceiro,
             VlPagamento,
             QtParcelas,
             VlIndiceRubrica,
             DtUltAlteracao,
             CdTipoOrigemRubrica)
      VALUES
            (Spaghistoricorubricavinculo.NEXTVAL,
             pFolha.CdFolhaPagamento,
             vCdRub,
             pCdVinculo,
             1,
             NULL,
             CASE
               WHEN vVlSaldo > vVlLimite
                 AND (PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
                      PKGPAG_VAR.vgVinculo.DtDesligamento NOT BETWEEN
                      PKGPAG_VAR.vgFolha.DtInicioMes AND PKGPAG_VAR.vgFolha.DtFimMes)
                 THEN
                   vVlLimite
                 ELSE
                   vVlSaldo
             END ,
             1,
             0,
             systimestamp,
             16);

         IF  PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN
             PKGPAG_VAR.vgFolha.DtInicioMes AND PKGPAG_VAR.vgFolha.DtFimMes
           THEN
             vVlSaldo := 0;
         END IF;

         -- Inserir SALDO do desconto parcial da rubrica 08-0024 na rubrica 09-9524

         IF vVlSaldo > vVlLimite
            THEN
             PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                                   pCdVinculo            => pCdVinculo,
                                                   pCdExpressaoFormCalc  => NULL,
                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBase080024DescParcial,
                                                   pNuSufixoRubrica      => 1,
                                                   pVlPagamento          => (vVlSaldo - vVlLimite),
                                                   pVlIndice             => NULL,
                                                   pCdTipoOrigemRubrica  => 1);

          END IF;

       end if;
       --
       -- SIG-5516
       -- rubrica 09-9524-01 - Devolucao de Adiant de 13 Sal.
       --
       if nvl(vVlSaldo,0) = 0 and
          PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamentoNormalAnt,
                                                   pCdVinculo => pCdVinculo,
                                                   pcdrubrica => vCdRubrica9524) > 0 and
          PKGPAG_VAR.vgVinculo.DtDesligamento < PKGPAG_VAR.vgFolha.DtInicioMes and
          pFolha.CdAgrupamento = 1 then

          vVlSaldo :=
           pKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamentoNormalAnt,
                                                    pCdVinculo => pCdVinculo,
                                                    pcdrubrica => vCdRubrica9524);

          BEGIN

            SELECT hrv.vlpagamento
              INTO vVlBaseProventos
              FROM Epaghistoricorubricavinculo HRV
             WHERE HRV.Cdfolhapagamento = pFolha.CdFolhaPagamento
               AND HRV.CDVINCULO = pCdVinculo
               AND HRV.Cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseTotPrv;

            EXCEPTION
              WHEN NO_DATA_FOUND
                THEN
                  vVlBaseProventos := 0;

              WHEN OTHERS
                THEN
                  vVlBaseProventos := 0;

          END;
          -- SOMENTE DESCONTAR A 05-0524 SE HOUVER PAGAMENTO DE PROVENTOS PARA O SERVIDOR
          IF NVL(vVlBaseProventos,0) > 0 AND vVlSaldo > NVL(vVlBaseProventos,0) THEN
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                                     pCdVinculo            => pCdVinculo,
                                                     pCdExpressaoFormCalc  => NULL,
                                                     pCdRubricaAgrupamento => fRetornaCdRubrica(524,5),
                                                     pNuSufixoRubrica      => 1,
                                                     pVlPagamento          => vVlSaldo,
                                                     pVlIndice             => NULL,
                                                     pCdTipoOrigemRubrica  => 1);
           END IF;
        end if;

   END IF;

END;

PROCEDURE PSaldoDevolucao13Ctisp(pCdVinculo  IN INTEGER,
                                 pFolha      IN PKGPAG_TIPO.rFolha) IS

  vVlRubDevAnt13NaoEfetuado  NUMBER(13,2) := 0;

BEGIN

  -- TODO: Limite

   BEGIN

      -- BUSCA DEVOLUCAO DE ADIAN 13 SALARIO CTISP NAO EFETUADA 09-9324
      with
      folhaNormalAnt as (
          select f.cdorgao, f.nuanomesreferencia
          from epagfolhapagamento f
          where f.cdfolhapagamento =  pFolha.CdFolhaPagamentoNormalAnt),

      folha13Ctisp as (
          select ff.cdFolhaPagamento
          from Epagfolhapagamento ff
          inner join epagtipofolhapagamento tfp
              on ff.cdtipofolhapagamento = tfp.cdtipofolhapagamento
          inner join folhaNormalAnt f
              on f.cdorgao = ff.cdorgao
              and f.nuanomesreferencia = ff.nuanomesreferencia
          where ff.flcalculodefinitivo = 'S'
          and tfp.cdtipofolha = 20) -- pkgpag_tipo.cnTpFolha13

      select hrv.vlpagamento
      into vVlRubDevAnt13NaoEfetuado
      from epaghistoricorubricavinculo hrv
      inner join folha13Ctisp on folha13Ctisp.cdFolhaPagamento = hrv.cdfolhapagamento
      where hrv.cdvinculo = pCdVinculo
      and   hrv.cdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,9,9324);

      IF vVlRubDevAnt13NaoEfetuado > 0 THEN

          INSERT
            INTO EPagHistoricoRubricaVinculo
                (CdHistoricoRubricaVinculo,
                 CdFolhaPagamento,
                 CdRubricaAgrupamento,
                 CdVinculo,
                 NuSufixoRubrica,
                 CdLancamentoFinanceiro,
                 VlPagamento,
                 QtParcelas,
                 VlIndiceRubrica,
                 DtUltAlteracao,
                 CdTipoOrigemRubrica)
          VALUES
                (Spaghistoricorubricavinculo.NEXTVAL,
                 pFolha.CdFolhaPagamento,
                 PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,8,324),
                 pCdVinculo,
                 1,
                 NULL,
                 vVlRubDevAnt13NaoEfetuado,
                 1,
                 0,
                 systimestamp,
                 16);

      END IF;

   EXCEPTION
     WHEN OTHERS THEN
       RETURN;
   END;


END;

PROCEDURE PDevolucao13SalPensaoA(pFolha        IN PKGPAG_TIPO.rFolha,
                                pCdVinculo    IN INTEGER,
                                pRubrica      IN PKGPAG_TIPO.rRubrica) IS

  vVlAdiant13SalPen             NUMBER(13,2);

  vCdRubDevDescAdiant13Pensao   INTEGER;

  vNuSequencial                 INTEGER;

BEGIN

  vNuSequencial := 0;

  IF (((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
     (PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes)) AND
     NOT PKGPAG_VAR.bPossuiObito) OR
     pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13,PKGPAG_TIPO.cnTpFolhaCtisp13)  THEN

    vCdRubDevDescAdiant13Pensao := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                4,
                                                                PKGPAG_VAR.vgRubrica(pRubrica.CdRubricaAgrupamento).NuRubrica);

    IF pRubrica.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao THEN

         FOR vSentenca IN (
                     WITH TabDes AS (
                         SELECT
                           SJ.NuSequencial,
                          HSJ.Dtiniciovigencia,
                          HSJ.Dtfimvigencia,
                          case
                             WHEN (HSJ.DtFimVigencia >= pFolha.DtFimMes OR HSJ.DtFimVigencia IS NULL)  THEN
                              SJ.NuSequencial
                             ELSE
                              0
                          end as NuSequencialVigente,

                          HSJ.RowId as rid
                            FROM ePenSentencaJudicial SJ
                           INNER JOIN EPenHistSentencaJudicial HSJ
                                   ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
                                WHERE SJ.CdVinculo = pCdVinculo
                          AND ( HSJ.Dtiniciovigencia <= pFolha.DtInicioMes AND (   HSJ.Dtfimvigencia >= trunc(pFolha.DtInicioMes,'YYYY') -- Primeiro dia do ano
                                                                                OR HSJ.Dtfimvigencia IS NULL) )
                      )
                          SELECT ext.NuSequencial,
                                 MAX (CASE
                                    WHEN NuSequencialVigente <> 0 THEN
                                        NuSequencialVigente
                                    ELSE (
                                             SELECT max(NuSequencialVigente)
                                             FROM TabDes
                                              CONNECT BY PRIOR DtFimVigencia + 1  = DtInicioVigencia

                                              START with rid  = ext.rid
                                          )
                                       END) as NuSequencialAplicar
                             FROM TabDes ext
                             group by  ext.NuSequencial
                           ORDER BY 2 -- Tem que ordenar para apagar a hrv somente na quebra
       )

        LOOP

         BEGIN

          SELECT SUM(HRV.VlPagamento)
            INTO vVlAdiant13SalPen
            FROM EPagHistoricoRubricaVinculo HRV
           INNER JOIN EPagFolhaPagamento F
              ON F.CdFolhaPagamento = HRV.CdFolhaPagamento AND
                 F.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND F.NuAnoReferencia = pFolha.NuAnoReferencia
           WHERE HRV.CdVinculo = pCdVinculo AND
                 HRV.CdRubricaAgrupamento = pRubrica.CdRubricaAgrupamento AND
                 HRV.NuSufixoRubrica = vSentenca.NuSequencial;

          IF vNuSequencial <> vSentenca.NuSequencialAplicar THEN -- Diferente da ultima excluida, excluir                   INTEGER;

             vNuSequencial := vSentenca.NuSequencialAplicar;

              DELETE
                FROM EPagHistoricoRubricaVinculo HRV
               WHERE HRV.CdVinculo = pCdVinculo AND
                     HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                     HRV.CdRubricaAgrupamento = vCdRubDevDescAdiant13Pensao AND
                     HRV.NuSufixoRubrica = vNuSequencial;

          END IF;

          IF NVL(vVlAdiant13SalPen,0) > 0 THEN

            IF vSentenca.NuSequencialAplicar = 0 THEN -- Pensao Encerrada sem sucessora para abater adiantamento

                PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                        PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo,
                                        PKGPAG_VAR.vgVinculo.CdPessoa,
                                        'Dev. de Adiantamento de Pensão não lançado sufixo '
                                            || vSentenca.NuSequencial ,
                                        PKGPAG_VAR.vgVinculo.CdVinculo,
                                        2,
                                        19);

            ELSIF NOT PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => vCdRubDevDescAdiant13Pensao,
                                                           pNuSufixoRubrica      => vSentenca.NuSequencialAplicar) THEN

              -- OBs: Adotado como verdade que caso uma pensao tenha sucessora e teve valor adiantado, nao existira adiantamento
              -- para a pensao que a sucedeu. Caso isto aconteca, este procedimento sera chamado mais de uma vez, gerando talvez
              -- duas rubricas de mesmo codigo e sufixo e valores diferentes.

              IF vSentenca.NuSequencial <> vSentenca.NuSequencialAplicar THEN -- Lancamento da sucedida na sucessora

                PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                        PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo,
                                        PKGPAG_VAR.vgVinculo.CdPessoa,
                                        'Dev. de Adiantamento de Pensão lançada na sentença judicial sucessora, de sufixo '
                                            || vSentenca.NuSequencial || ' para ' || vSentenca.NuSequencialAplicar,
                                        PKGPAG_VAR.vgVinculo.CdVinculo,
                                        2,
                                        19);

              END IF;

              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento =>vCdRubDevDescAdiant13Pensao,
                                                    pNuSufixoRubrica      => vSentenca.NuSequencialAplicar,
                                                    pVlPagamento          => vVlAdiant13SalPen,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 8);

            else
              null;
            END IF;
          END IF;

         EXCEPTION

           WHEN OTHERS THEN

             NULL;

         END;

       END LOOP;
    END IF;

  END IF;

END;

PROCEDURE PDevolucao13SalPensao(pFolha        IN PKGPAG_TIPO.rFolha,
                                pCdVinculo    IN INTEGER,
                                pRubrica      IN PKGPAG_TIPO.rRubrica) IS

  vVlAdiant13SalPen             NUMBER(13,2);

  vCdRubDevDescAdiant13Pensao   INTEGER;

  vCdRubDevDescAdiant13PensaoDeb   INTEGER;

  --vNuSequencial                 INTEGER;

BEGIN

  --vNuSequencial := 0;

  IF (((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
     (PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes)) AND
     NOT PKGPAG_VAR.bPossuiObito) OR
     pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13,PKGPAG_TIPO.cnTpFolhaCtisp13) THEN

    vCdRubDevDescAdiant13Pensao := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                4,
                                                                PKGPAG_VAR.vgRubrica(pRubrica.CdRubricaAgrupamento).NuRubrica);

    vCdRubDevDescAdiant13PensaoDeb := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                5,
                                                                586);

    IF pRubrica.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao THEN

         FOR vSentenca IN (
                     -- SELECIONA PENSOES
                     WITH TabDes AS (
                         SELECT
                           SJ.NuSequencial,
                          HSJ.Dtiniciovigencia,
                          HSJ.Dtfimvigencia,
                          MAX(
                                case
                                   WHEN (HSJ.DtFimVigencia > pFolha.DtFimMes OR HSJ.DtFimVigencia IS NULL)  THEN
                                    SJ.NuSequencial
                                   ELSE
                                    0
                                end

                          ) OVER (PARTITION BY SJ.NuSequencial) as NuSequencialVigente,
                          DECODE (DtInicioVigencia, MIN (DtInicioVigencia) OVER (PARTITION BY SJ.NuSequencial) ,1,0 ) as PrimVig,
                          CASE
                             WHEN SJ.CdPessoa IS NOT NULL THEN
                              P.NUCPF
                             ELSE
                              PP.NuCpf
                          END AS NumCpfRepresentante,
                          HSJ.RowId as rid,
                          SJ.Cdpessoapensao
                            FROM ePenSentencaJudicial SJ
                           INNER JOIN EPenHistSentencaJudicial HSJ
                                   ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
                            LEFT JOIN ECADPESSOA P
                              ON P.CdPessoa = SJ.CdPessoa
                            LEFT JOIN EPENPESSOAPENSAO PP
                              ON PP.CdPessoaPensao = SJ.CdPessoaPensao
                          WHERE SJ.CdVinculo = pCdVinculo
                               AND HSJ.FLPAGAMENTO13 = 'S'
                               AND (HSJ.Dtiniciovigencia <= pFolha.DtInicioMes AND -- Permite o desconto em pensao valida no ano
                                        (HSJ.Dtfimvigencia >= to_date(to_char('01/01/' || pFolha.NuAnoReferencia), 'DD/MM/YYYY') OR HSJ.Dtfimvigencia IS NULL))
                      )

                           SELECT ext.NumCpfRepresentante,
                                 ext.NuSequencial,
                                 -- SE PENSAO NAO ESTA MAIS VIGENTE ( NuSequencialVigente = 0)
                                 -- DESCOBRE SE HA OUTRA VIGENTE COM MESMO CPF PARA APLICAR DESCONTO
                                 CASE
                                   WHEN  ext.NuSequencialVigente = 0 THEN
                                      MAX(ext.NuSequencialVigente) OVER (PARTITION BY ext.NumCpfRepresentante)
                                   ELSE
                                     ext.NuSequencialVigente
                                 END as NuSequencialAplicar,
                                 ext.cdPessoaPensao
                             FROM TabDes ext
                             group by  ext.NumCpfRepresentante , ext.NuSequencial , ext.NuSequencialVigente, ext.cdPessoaPensao
                           ORDER BY 3
       )

        LOOP

         BEGIN

          -- SELECIONA VALOR DO ADIANTAMENTO DE 13 DA PENSAO PARA O SEQUENCIAL
          SELECT SUM(HRV.VlPagamento)
            INTO vVlAdiant13SalPen
            FROM EPagHistoricoRubricaVinculo HRV
           INNER JOIN EPagFolhaPagamento F
              ON F.CdFolhaPagamento = HRV.CdFolhaPagamento
             AND F.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
             AND F.NuAnoReferencia = pFolha.NuAnoReferencia
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdRubricaAgrupamento IN
                 (pRubrica.CdRubricaAgrupamento,
                  (SELECT VAG.cdrubricaagrupamento -- retorna o valor do tipo rubrica 06
                     FROM VPAGRUBRICAAGRUPAMENTO VAG
                    WHERE VAG.cdagrupamento = PKGPAG_VAR.vgFolha.CdAgrupamento
                      AND VAG.cdtiporubrica = 6
                      AND VAG.nurubrica =
                          (SELECT VA.nurubrica
                             FROM VPAGRUBRICAAGRUPAMENTO VA
                            WHERE VA.CDRUBRICAAGRUPAMENTO =
                                  pRubrica.CdRubricaAgrupamento)))
             AND HRV.NuSufixoRubrica = vSentenca.NuSequencial;

          -- SE HOUVE VALOR DE ADIANTAMENTO PARA O SEQUENCIAL, ENT?O DEVOLVE
          IF NVL(vVlAdiant13SalPen,0) > 0 THEN

            -- SE NuSequencialAplicar = 0 ENTAO PENSAO ESTA ENCERRADA SEM SUCESSORA NO MESMO CPF
            IF vSentenca.NuSequencialAplicar = 0 THEN -- Pensao Encerrada sem sucessora para abater adiantamento

                PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                        PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo,
                                        PKGPAG_VAR.vgVinculo.CdPessoa,
                                        'Dev. de Adiantamento de Pensão não lançado sufixo '
                                            || vSentenca.NuSequencial ,
                                        PKGPAG_VAR.vgVinculo.CdVinculo,
                                        2,
                                        19);

                -- Gera CREDITO E DEBITO, para efeito de tributacao

                -- CREDITO
                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento =>vCdRubDevDescAdiant13Pensao,
                                                    pNuSufixoRubrica      => vSentenca.NuSequencial,
                                                    pVlPagamento          => vVlAdiant13SalPen,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 8);

                  -- Caso a pensao esteja valida nao gera o debito
                  IF PKGPAG_DT.FVerificaPensaoValida(PKGPAG_VAR.vgVinculo.CdVinculo,
                                                        vSentenca.NuSequencial,
                                                        vSentenca.Cdpessoapensao,
                                                        PKGPAG_VAR.vgFolha.dtFimMes) THEN

                    CONTINUE;
                  END IF;

                -- DEBITO
                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento =>vCdRubDevDescAdiant13PensaoDeb,
                                                    pNuSufixoRubrica      => vSentenca.NuSequencial,
                                                    pVlPagamento          => vVlAdiant13SalPen,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 8);

            ELSIF NOT PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => vCdRubDevDescAdiant13Pensao,
                                                           pNuSufixoRubrica      => vSentenca.NuSequencialAplicar) THEN

              -- SE DEVE DEVOLVER EM OUTRO SEQUENCIAL, REGISTRA EM LOG
              IF vSentenca.NuSequencial <> vSentenca.NuSequencialAplicar THEN -- Lancamento da sucedida na sucessora

                PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                        PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo,
                                        PKGPAG_VAR.vgVinculo.CdPessoa,
                                        'Dev. de Adiantamento de Pensão lançada na sentença judicial sucessora, de sufixo '
                                            || vSentenca.NuSequencial || ' para ' || vSentenca.NuSequencialAplicar,
                                        PKGPAG_VAR.vgVinculo.CdVinculo,
                                        2,
                                        19);

              END IF;

              -- GERA CREDITO DA DEVOLUCAO, NO SEQUENCIAL A APLICAR
              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento =>vCdRubDevDescAdiant13Pensao,
                                                    pNuSufixoRubrica      => vSentenca.NuSequencialAplicar,
                                                    pVlPagamento          => vVlAdiant13SalPen,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 8);

            else
              null;
            END IF;
          END IF;

         EXCEPTION

           WHEN OTHERS THEN

             NULL;

         END;

       END LOOP;
    END IF;

  END IF;

END;

PROCEDURE PAbonoPecuniario(pCdVinculo  IN INTEGER,
                           pFolha      IN PKGPAG_TIPO.rFolha,
                           pRubrica    IN PKGPAG_TIPO.rRubrica,
                           pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

  vNuDiasReceber       INTEGER;

  vCdEstruturaCarreira INTEGER;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

    SELECT SUM(FFP.NuDiasReceber)
      INTO vNuDiasReceber
      FROM EMovPeriodoAquisitivoFerias PA
     INNER JOIN EmovFeriasFruicaoPagamento FFP
        ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
     INNER JOIN EmovFeriasFruicaoUsufruto FFU
        ON FFU.CdFeriasProgramacaoUsufruto = FFP.CdFeriasProgramacaoUsufruto
     WHERE PA.CdVinculo = pCdVinculo AND
           FFP.NuAnoReferencia = pFolha.NuAnoReferencia AND
           FFP.NuMesReferencia = pFolha.NuMesReferencia AND
           FFP.FlAbono = PKGPAG_TIPO.cnS AND
           FFP.FlAnulado = PKGPAG_TIPO.cnN AND
           FFU.InSituacao NOT IN (2,3,4,5,12);

    IF vNuDiasReceber > 0 THEN

      IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

        vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

      END IF;

      vCdExpressaoFormCalc :=

           PKGPAG_GERAL.FIdentificaFormulaCalculo(
                        pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                        pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                        pCdRelacaoVinculo         => 0,
                        pCdEstruturaCarreira      => vCdEstruturaCarreira);

      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => vNuDiasReceber,
                                              pCdTipoOrigemRubrica  => 7);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => pRubrica.CdRubricaAgrupamento,
                                         pTpProcessamento => 1,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

    END IF;

  END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;

END;

PROCEDURE PAdiantamentoSalarioFerias(pCdVinculo  IN INTEGER,
                                     pFolha      IN PKGPAG_TIPO.rFolha,
                                     pRubrica    IN PKGPAG_TIPO.rRubrica,
                                     pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo) IS

  vNuDiasReceber       INTEGER;

  vCdEstruturaCarreira INTEGER;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  SELECT SUM(FFP.NuDiasReceber)
    INTO vNuDiasReceber
    FROM EMovPeriodoAquisitivoFerias PA
   INNER JOIN EmovFeriasFruicaoPagamento FFP
      ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
   WHERE PA.CdVinculo = pCdVinculo AND
         FFP.NuAnoReferencia = pFolha.NuAnoReferencia AND
         FFP.NuMesReferencia = pFolha.NuMesReferencia AND
         FFP.FlAdiantamentoFerias = PKGPAG_TIPO.cnS AND
         FFP.FlAnulado = PKGPAG_TIPO.cnN;

  IF vNuDiasReceber > 0 THEN

    IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

      vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;

    END IF;

    vCdExpressaoFormCalc :=

         PKGPAG_GERAL.FIdentificaFormulaCalculo(
                      pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                      pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                      pCdRelacaoVinculo         => 0,
                      pCdEstruturaCarreira      => vCdEstruturaCarreira);

    IF vCdExpressaoFormCalc > 0 THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                            pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => vNuDiasReceber,
                                            pCdTipoOrigemRubrica  => 7);

      PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => pRubrica.CdRubricaAgrupamento,
                                       pTpProcessamento => 1,
                                       pTpLocal         => 2); /*Vinculo*/

    END IF;

  END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    NULL;

END;

PROCEDURE PBaseGratProd (pFolha              IN PKGPAG_TIPO.rFolha,
                         pCdVinculo          IN INTEGER,
                         pRubrica            IN PKGPAG_TIPO.rRubrica,
                         pCEF                IN PKGPAG_TIPO.tCEF,
                         pCCO                IN PKGPAG_TIPO.tCCO,
                         pCCOSubst           IN PKGPAG_TIPO.tCCO,
                         pAPO                IN PKGPAG_TIPO.tCEF,
                         pCdTipoAtipratFaz   IN INTEGER) IS

  vCdEstruturaCarreira INTEGER;

  vVlFixo              NUMBER(13,2);

  FUNCTION FRetornaValorFixoGratCEF(pCdEstruturaCarreira   IN INTEGER,
                                    pNuNivelPagamento      IN VARCHAR2,
                                    pNuReferenciaPagamento IN VARCHAR2,
                                    pCdTipoAtipratFaz     IN INTEGER)

    RETURN NUMBER IS

    vCdValorGeralCEFAGrup     INTEGER;
    vCdHistValorGeralCEFAGrup INTEGER;
    vCdRubricaAgrupamento     INTEGER;
    vVlFixoCEF                NUMBER(13,2);
    vVlIndice                 NUMBER(7,4) DEFAULT NULL;

  BEGIN

    SELECT CdValorGeralCEFAGrup,
           VlIndice,
           CdRubricaAgrupamento,
           VlFixoCEF
      INTO vCdValorGeralCEFAGrup,
           vVlIndice,
           vCdRubricaAgrupamento,
           vVlFixoCEF
      FROM ( SELECT VS.CdValorGeralCEFAGrup,
                    HAF.VlIndice,
                    HAF.CdRubricaAgrupamento,
                    HAF.VlFixoCEF,
                    Nivel
               FROM EPagGratAtivFazendaria AF
              INNER JOIN EpagHistGratAtivFazendaria HAF
                 ON AF.CdGratAtivFazendaria = HAF.CdGratAtivFazendaria
              INNER JOIN Epaghistgratativfazendvalsal VS
                 ON HAF.CdHistAtivFazendaria = VS.CdHistAtivFazendaria
              INNER JOIN (SELECT CdEstruturaCarreira,
                                 LEVEL AS Nivel
                            FROM EcadEstruturaCarreira C
                         CONNECT BY PRIOR C.CdEstruturaCarreiraPai = C.CdEstruturaCarreira
                           START WITH C.CdEstruturaCarreira = pCdEstruturaCarreira) ES
                 ON ES.CdEstruturaCarreira = VS.CdEstruturaCarreira OR
                    VS.CdEstruturaCarreira IS NULL
              WHERE AF.Cdagrupamento = pFolha.CdAgrupamento AND
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

       IF PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubricaAgrupamento) THEN

         vVlFixoCEF  := NVL(vVlFixoCEF,0)*vVlIndice/100;

       ELSE

         vCdHistValorGeralCEFAGrup :=

           PKGPAG_GERAL.FTabelaValorGeral(vCdValorGeralCEFAGrup,
                                          pFolha.NuVersaoTabCEF,
                                          pFolha.NuAnoReferencia,
                                          pFolha.NuMesReferencia);

         SELECT V.vlFixo
           INTO vVlFixoCEF
           FROM EPagValorEspecCEFAgrup V
          WHERE V.CdHistValorGeralCEFAgrup = vCdHistValorGeralCEFAGrup AND
                V.NuNivel = pNuNivelPagamento AND
                V.NuReferencia = pNuReferenciaPagamento;

       END IF;

         RETURN  vVlFixoCEF*vVlIndice/100;

     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         RETURN 0;

    END;

  FUNCTION FRetornaValorFixoGratCCO (pCCO IN PKGPAG_TIPO.rCCO)

   RETURN NUMBER IS

   vNuValor   NUMBER(13,2);
   vVlIndice  NUMBER(7,4) DEFAULT NULL;

  BEGIN

    SELECT NuValor,
           VlIndice
      INTO vNuValor,
           vVlIndice
      FROM (SELECT NuValor,
                   VlIndice
      FROM (SELECT VV.NuValor,
                HAF.VlIndice,
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

        IF vNuValor IS NOT NULL THEN

            vNuValor := vNuValor*vVlIndice/100;

        END IF;

        RETURN vNuValor;

 EXCEPTION

   WHEN NO_DATA_FOUND THEN

     --vNuValor := NULL;

     RETURN vNuValor;

 END;

BEGIN

  vCdEstruturaCarreira := NULL;

  IF pCCO.COUNT > 0 THEN

    FOR j IN pCCO.FIRST .. pCCO.LAST
    LOOP

       IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                 pRubrica                  => pRubrica,
                                 pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                 pCdOrgaoExercicio         => pCCO(j).CdOrgaoExercicio,
                                 pCdNaturezaVinculo        => pCCO(j).CdNaturezaVinculo,
                                 pCdRelacaoTrabalho        => pCCO(j).CdRelacaoTrabalho,
                                 pCdRegimeTrabalho         => pCCO(j).CdRegimeTrabalho,
                                 pCdRegimePrevidenciario   => pCCO(j).CdRegimePrevidenciario,
                                 pCdSituacaoPrevidenciaria => pCCO(j).CdSituacaoPrevidenciaria,
                                 pCdCargoComissionado      => pCCO(j).CdCargoComissionado,
                                 pCdGrupoOcupacional       => pCCO(j).CdGrupoOcupacional,
                                 pCdUnidadeOrganizacional  => pCCO(j).CdUnidadeOrganizacional,
                                 pCdEstruturaCarreira      => vCdEstruturaCarreira,
                                 pCdOpcaoRemuneracao       => pCCO(j).CdOpcaoRemuneracao,
                                 pFlTipoProvimento         => pCCO(j).FlTipoProvimento,
                                 pFlAplicaTodosOrgaos      => 'S') THEN

       vVlFixo := FRetornaValorFixoGratCCO(pCCO(j));

      END IF;

    END LOOP;

  ELSIF pCCOSubst.COUNT > 0 THEN

    FOR j IN pCCOSubst.FIRST .. pCCOSubst.LAST
    LOOP

      vVlFixo := FRetornaValorFixoGratCCO(pCCOSubst(j));

    END LOOP;

  ELSIF pCEF.COUNT > 0 THEN

    FOR j IN pCEF.FIRST .. pCEF.LAST
    LOOP

      vCdEstruturaCarreira := pCEF(j).CdEstruturaCarreira;

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                 pRubrica                  => pRubrica,
                                 pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                 pCdOrgaoExercicio         => pCEF(j).CdOrgaoExercicio,
                                 pCdNaturezaVinculo        => pCEF(j).CdNaturezaVinculo,
                                 pCdRelacaoTrabalho        => pCEF(j).CdRelacaoTrabalho,
                                 pCdRegimeTrabalho         => pCEF(j).CdRegimeTrabalho,
                                 pCdRegimePrevidenciario   => pCEF(j).CdRegimePrevidenciario,
                                 pCdSituacaoPrevidenciaria => pCEF(j).CdSituacaoPrevidenciaria,
                                 pCdUnidadeOrganizacional  => pCEF(j).CdUnidadeOrganizacional,
                                 pCdEstruturaCarreira      => pCEF(j).CdEstruturaCarreira,
                                 pFlTipoProvimento         => pCEF(j).FlEfetivacao,
                                 pFlAplicaTodosOrgaos      => 'S',
                                 pCdMotivoMovimentacao     => pCEF(j).CdMotivoMovimentacao,
                                 pCdInstitutoMovimentacao  => pCEF(j).CdInstitutoMovimentacao) THEN

         vVlFixo :=  FRetornaValorFixoGratCEF(pCEF(j).CdEstruturaCarreira,
                                              pCEF(j).NuNivelPagamento,
                                              pCEF(j).NuReferenciaPagamento,
                                              pCdTipoAtipratFaz);

     END IF;

    END LOOP;

 ELSIF pAPO.COUNT > 0 THEN

   FOR j IN pAPO.FIRST .. pAPO.LAST
   LOOP

     IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                 pRubrica                  => pRubrica,
                                 pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                 pCdOrgaoExercicio         => pAPO(j).CdOrgaoExercicio,
                                 pCdSituacaoPrevidenciaria => pAPO(j).CdSituacaoPrevidenciaria,
                                 pCdEstruturaCarreira      => pAPO(j).CdEstruturaCarreira,
                                 pFlAPOOrigemCCO           => pAPO(j).FlOrigemCCO,
                                 pFlAplicaTodosOrgaos      => 'S') THEN

       vVlFixo :=  FRetornaValorFixoGratCEF(pAPO(j).CdEstruturaCarreira,
                                            pAPO(j).NuNivelPagamento,
                                            pAPO(j).NuReferenciaPagamento,
                                            pCdTipoAtipratFaz);

     END IF;

    END LOOP;

  else
    null;
  END IF;

  IF NVL(vVlFixo,0) > 0 THEN

    PKGPAG_VAR.vgVlBase1467 := vVlFixo;

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseRateio,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => vVlFixo,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

  END IF;

END;

/*----------------------------------------------------------------------------------------------/
-- Procedure: PContribuicaoSindical
--
--  Objetivo:
--
--
/*----------------------------------------------------------------------------------------------*/

PROCEDURE PContribuicaoSindical(pFolha                IN PKGPAG_TIPO.rFolha,
                                pCdVinculo            IN INTEGER,
                                pRubrica              IN PKGPAG_TIPO.rRubrica,
                                pFormExpr             IN PKGPAG_TIPO.tFormulaCalculo,
                                pCEF                  IN PKGPAG_TIPO.tCEF,
                                pCCO                  IN PKGPAG_TIPO.tCCO,
                                pCCOSubst             IN PKGPAG_TIPO.tCCO,
                                pFUC                  IN PKGPAG_TIPO.tFUC,
                                pBOL                  IN PKGPAG_TIPO.tBOL,
                                pAPO                  IN PKGPAG_TIPO.tCEF) IS

BEGIN

   DELETE
     FROM EPagEventoVinculo EV
    WHERE EV.CdVinculo = pCdVinculo AND
          EV.CdTipoEventoVinculo = 1 AND
          EV.NuAnoMesReferencia = (pFolha.NuAnoReferencia*100+ pFolha.NuMesReferencia);

   IF FPagaContribuicaoSindical(pCdVinculo,
                                pFolha.NuAnoReferencia,
                                pFolha.DtInicioMes,
                                pFolha.DtFimMes,
                                pRubrica) THEN

     PKGPAG_VAR.vgListaContribSind(pRubrica.CdRubricaAgrupamento) := pRubrica.CdRubricaAgrupamento;

     PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro      => 2,
                                          pFolha             => pFolha,
                                          pCdVinculo         => pCdVinculo,
                                          pRubrica           => pRubrica,
                                          pFormExpr          => pFormExpr,
                                          pFlPrincipal       => PKGPAG_TIPO.cnN,
                                          pCEF               => pCEF,
                                          pCCO               => pCCO,
                                          pCCOSubst          => pCCOSubst,
                                          pFUC               => pFUC,
                                          pBOL               => pBOL,
                                          pAPO               => pAPO,
                                          pVlIndice          => NULL,
                                          pDtCalculo         => PKGPAG_VAR.vDtCalculo,
                                          pFlApenasNoVinculo => 'N');

  END IF;

END;

/*----------------------------------------------------------------------------------------------/
-- Procedure: PDescontoEventual
--
--  Objetivo:
--
--
/*----------------------------------------------------------------------------------------------*/

PROCEDURE PDescontoEventual(pFolha                IN PKGPAG_TIPO.rFolha,
                            pCdVinculo            IN INTEGER,
                            pRubrica              IN PKGPAG_TIPO.rRubrica,
                            pFormExpr             IN PKGPAG_TIPO.tFormulaCalculo,
                            pCEF                  IN PKGPAG_TIPO.tCEF,
                            pCCO                  IN PKGPAG_TIPO.tCCO,
                            pCCOSubst             IN PKGPAG_TIPO.tCCO,
                            pFUC                  IN PKGPAG_TIPO.tFUC,
                            pBOL                  IN PKGPAG_TIPO.tBOL,
                            pAPO                  IN PKGPAG_TIPO.tCEF) IS

BEGIN

   PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro      => 2,
                                        pFolha             => pFolha,
                                        pCdVinculo         => pCdVinculo,
                                        pRubrica           => pRubrica,
                                        pFormExpr          => pFormExpr,
                                        pFlPrincipal       => PKGPAG_TIPO.cnN,
                                        pCEF               => pCEF,
                                        pCCO               => pCCO,
                                        pCCOSubst          => pCCOSubst,
                                        pFUC               => pFUC,
                                        pBOL               => pBOL,
                                        pAPO               => pAPO,
                                        pVlIndice          => NULL,
                                        pDtCalculo         => PKGPAG_VAR.vDtCalculo,
                                        pFlApenasNoVinculo => 'N');

END;

-------------------------------------------------------------------------------------------
-- Rescisao de Ferias ACT
-- Este evento podera gerar duas Rubricas :
-- Indenizacao de Ferias do 1º ano de contrato (01-0331)
-- Indenizacao de Ferias do ano corrente       (01-0332)
--------------------------------------------------------------------------------------------

PROCEDURE P069RescisaoFeriasACT(pFolha          IN PKGPAG_TIPO.rFolha,
                                pEvento         IN PKGPAG_TIPO.rEvento,
                                pTemDifMes      IN BOOLEAN,
                pRubrica        IN PKGPAG_TIPO.rRubrica) IS

  vCdExpressaoFormCalc INTEGER;
  vVlPagamento PKGPAG_TIPO.rValorPagamento;
  vVlPagamentoSupl PKGPAG_TIPO.rValorPagamento;
  vCdHistCargoEfetivo INTEGER;
  vVlPagamentoFolhaAnterior number(13,2);

  /* Encontra Cdhistcargoefetivo */
  FUNCTION RetornaCdHistCargoEfetivo
    RETURN INTEGER IS

  BEGIN

    RETURN PKGPAG_VAR.vgRelVincPrincipal.CdHist;

  END;

  FUNCTION RetornaDataInicio(pCdVinculo       IN INTEGER,
                             pDtInicioRelacao IN DATE)
    RETURN DATE IS

    vDtInicioRelacao DATE;

  BEGIN

    vDtInicioRelacao := pDtInicioRelacao;

    FOR vRec IN (SELECT DtInicio, DtFim
                   FROM ECadHistCargoEfetivo CEF
                  WHERE CEF.CdVinculo = pCdVinculo AND
                        CEF.DtInicio < pDtInicioRelacao AND
                        CEF.Flanulado = 'N'
                 ORDER BY 1 DESC)
    LOOP

      IF vRec.DtFim + 1 = vDtInicioRelacao THEN

        vDtInicioRelacao := vRec.DtInicio;

      ELSE

        RETURN vDtInicioRelacao;

      END IF;

    END LOOP;

    RETURN vDtInicioRelacao;

  END;

  FUNCTION VerificaPagamentoFerias(pCdVinculo INTEGER, nuAno INTEGER)
  RETURN BOOLEAN IS

  nuDias INTEGER;
  cdFeriasFruicaoPagamento INTEGER;

  BEGIN

SELECT nvl(SUM(x.nuDias), 0)
/* x.cdferiasfruicaopagamento,
x.dtinicio,
x.dtfim*/
  INTO nuDias
  FROM (SELECT FFU.NUDIAS                   AS nuDias,
               FFP.CDFERIASFRUICAOPAGAMENTO AS cdFeriasFruicaoPagamento
          FROM EMovFeriasFruicaoPagamento FFP
         INNER JOIN emovferiasfruicaousufruto ffu
            ON FFP.CdFeriasProgramacaoUsufruto =
               FFU.CdFeriasProgramacaoUsufruto
         INNER JOIN EMovPeriodoAquisitivoFerias eff
            ON eff.cdperiodoaquisitivoferias = ffu.cdperiodoaquisitivoferias
         WHERE eff.cdvinculo = pCdVinculo
           AND FFP.NuDiasReceber >= 0
--         AND FFP.FlPagamentoIndenizado = 'N'
           AND ffp.nuanoreferencia = nuAno
           AND FFP.NuDiasReceber >= 0
           AND ffp.nudiasreceber > 0) x
 GROUP BY x.cdFeriasFruicaoPagamento; -- x.dtinicio, x.dtfim;

    IF nuDias > 0 THEN
      RETURN TRUE;

      ELSE
        RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

BEGIN

  -- Busca a menor data de inicio da relacao caso nao haja intersticio
  vCdHistCargoEfetivo := RetornaCdHistCargoEfetivo();
  -- Se possui prorrogacao de contrato busca a data inicial da relacao
  IF (FProrrogacao(vCdHistCargoEfetivo)) THEN
    -- Busca a menor data de inicio da relac?o caso n?o haja intersticio
     PKGPAG_VAR.vgRelVincPrincipal.DtInicioRelacao := RetornaDataInicio(PKGPAG_VAR.vgVinculo.CdVinculo
                                                          , PKGPAG_VAR.vgRelVincPrincipal.DtInicioRelacao);
  END IF;

  -- #73492 9578/2016 - FOLHA - BLOQUEIO DA RUBRICA 01-0332
/*  IF pFolha.CdOrgao IN (41, 42) AND pRubrica.CdRubricaAgrupamento IN (\*37555, 37561,*\ 31377)
     AND pFolha.NuMesReferencia = 12 AND pFolha.CdTipoFolhaPagamento = 2
     AND pFolha.CdTipoCalculo = 1 --AND pFolha.FlCalculoDefinitivo = 'S'
  THEN
    RETURN;
  END IF;*/

  IF (PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT OR pFolha.CdOrgao = 443)
     AND ((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)
        OR (PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes)
       AND (TRUNC(PKGPAG_VAR.vMotAfast.DtInclusao) BETWEEN PKGPAG_VAR.vDtCalculoAnt + 1 AND PKGPAG_VAR.vDtCalculo
         OR pTemDifMes))
  THEN

    IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                              pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                              pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                                              pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria)
        AND FCarreiraPermitidasRubrica(pCdVinculo => PKGPAG_VAR.vgVinculo.cdvinculo,
                                        pDtInicio => pFolha.DtInicioMes,
                                           pDtFim => pFolha.DtFimMes,
                                         pRubrica => PKGPAG_VAR.vgRubrica(pEvento.CdRubricaAgrupamento))
       AND NOT VerificaPagamentoFerias(PKGPAG_VAR.vgVinculo.CdVinculo,  --01-0331: Verifica se houve pagamento de ferias no ano corrente.
                                               pFolha.NuAnoReferencia) --01-0331: Se nao houver, permite o pagamento.
       AND NOT PKGPAG_VAR.vListaRubricas.EXISTS(pRubrica.CdRubricaAgrupamento) -- Rubrica nao possui lancamento financeiro
       AND NOT PKGPAG_VAR.vgRubrica(pRubrica.CdRubricaAgrupamento).FlSuspensa = PKGPAG_TIPO.cnS -- Rubrica nao esta suspensa
    THEN

      -- Indenizacao de Ferias do 1º ano de contrato (01-0331)
      -- Ano DtAdmissao  <> Ano DtDesligamento and Mes DtAdmissao NOT IN (1,12)
      IF TO_CHAR(PKGPAG_VAR.vgRelVincPrincipal.DtInicioRelacao, 'YYYY') <> TO_CHAR(PKGPAG_VAR.vgVinculo.DtDesligamento, 'YYYY')
         AND to_number(TO_CHAR(PKGPAG_VAR.vgRelVincPrincipal.DtInicioRelacao, 'MM')) <> 1
         -- Para DEFENSORIA utilizar somente a rubrica 01-0332
         AND pFolha.CdOrgao <> 443
      THEN

        vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr => PKGPAG_VAR.vgFormExpr
                                      , pCdRubricaAgrupamento     => pEvento.CdRubricaAgrupamento
                                      , pCdRelacaoVinculo         => 0);

        IF vCdExpressaoFormCalc > 0 THEN

          /* Se possui relacao de vinculo, calcula baseado na relacao de vinculo */
          IF vCdHistCargoEfetivo IS NOT NULL  THEN

            /* Prepara calculo da rubrica na relacao de vinculo, para poder trazer valor real */
            PKGPAG_GERAL.PInsereLancamentoRelacao(
                          pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                          pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                          pCdRelacaoVinculo     => 1,
                          pCdHistRelacaoVinculo => vCdHistCargoEfetivo,
                          pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                          pCdRubricaAgrupamento => pEvento.CdRubricaAgrupamento,
                          pVlIntegral           => NULL,
                          pVlProporcional       => NULL,
                          pNuSufixoRubrica      => 1,
                          pNuParcelas           => 1,
                          pVlIndice             => NULL,
                          pCdTipoOrigemRubrica  => 1);

            /* Processa valores na relacao de vinculo */
            PKGPAG_FB.PProcessaFormulasBases(pFolha, PKGPAG_VAR.vgVinculo.CdVinculo
                                           , pEvento.CdRubricaAgrupamento, 1, 1);

            IF PKGPAG_VAR.vgVinculo.DtDesligamento > pFolha.DtCalculoAnt THEN
              /* Busca valores calculados do vinculo em folha suplementar */
              vVlPagamentoSupl.vlReal := PKGPAG_GERAL.fretornasomavalorrubricasupl(pFolha.CdFolhaPagamentoNormalAnt
                                                   , PKGPAG_VAR.vgVinculo.cdvinculo
                                                   , PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento
                                                   , 2, pRubrica.NuRubrica));
              IF vVlPagamentoSupl.VlReal > 0 THEN
                --Se houve pagamento em folha suplementar, retorna.
                RETURN;
              END IF;
            END IF;

            /* Busca valores calculados na relacao de vinculo */
            vVlPagamento := PKGPAG_GERAL.FRetornaValorRubricaRV(pFolha.CdFolhaPagamento, PKGPAG_VAR.vgVinculo.CdVinculo
                                   , pEvento.CdRubricaAgrupamento, 1);


            IF vVlPagamento.VlReal > 0 THEN
              /* Insere valor Real no vinculo */
              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                                 pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pCdExpressaoFormCalc  => NULL,
                                 pCdRubricaAgrupamento => pEvento.CdRubricaAgrupamento,
                                 pNuSufixoRubrica      => 1,
                                 pVlPagamento          => NVL(vVlPagamento.vlReal,0),
                                 pVlIndice             => vVlPagamento.vlIndice,
                                 pCdTipoOrigemRubrica  => 1);
            ELSE /* Caso nao calcule nada na relacao, calcula no vinculo */
              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                 pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                 pCdRubricaAgrupamento => pEvento.CdRubricaAgrupamento,
                                 pNuSufixoRubrica      => 1,
                                 pVlPagamento          => 0,
                                 pVlIndice             => NULL,
                                 pCdTipoOrigemRubrica  => 1);
              PKGPAG_FB.PProcessaFormulasBases(pFolha, PKGPAG_VAR.vgVinculo.CdVinculo, pEvento.CdRubricaAgrupamento, 1, 2);
            END IF;
          END IF;
        END IF;
      END IF;  -- abrangencia
    END IF;

    -- Indenizacao de Ferias do ano corrente (01-0332)
     IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica => PKGPAG_VAR.vgRubrica(pEvento.CdRubAgrupAlternativa1),
                      pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                      pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                      pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria)
       AND FCarreiraPermitidasRubrica(pCdVinculo => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                  pDtInicio=> pFolha.DtInicioMes,
                                                  pDtFim => pFolha.DtFimMes,
                                                  pRubrica => PKGPAG_VAR.vgRubrica(pEvento.CdRubAgrupAlternativa1))
       AND NOT PKGPAG_VAR.vListaRubricas.EXISTS(pEvento.CdRubAgrupAlternativa1) -- Rubrica nao possui lancamento financeiro
       AND NOT PKGPAG_VAR.vgRubrica(pEvento.CdRubAgrupAlternativa1).FlSuspensa = PKGPAG_TIPO.cnS -- Rubrica nao esta suspensa
       AND NVL(PKGPAG_GERAL.fretornasomavalorrubricasupl(pFolha.CdFolhaPagamentoNormalAnt -- nao paga se tiver 02-0332 em normal/suplementar - Solic: 10002/2017
                                                       , PKGPAG_VAR.vgVinculo.cdvinculo
                                                       , PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 2, 332)), 0) <= 0
    THEN

      vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr => PKGPAG_VAR.vgFormExpr,
                                     pCdRubricaAgrupamento     => pEvento.CdRubAgrupAlternativa1,
                                     pCdRelacaoVinculo         => 0);

      IF vCdExpressaoFormCalc > 0 THEN
        PKGPAG_VAR.vgCdRubCalculada := pEvento.CdRubAgrupAlternativa1;

        /* Se possui relacao de vinculo, calcula baseado na relacao de vinculo */
        IF vCdHistCargoEfetivo IS NOT NULL THEN

          /* Prepara calculo da rubrica na relacao de vinculo, para poder trazer valor real */
          PKGPAG_GERAL.PInsereLancamentoRelacao(
                       pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                       pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                       pCdRelacaoVinculo     => 1,
                       pCdHistRelacaoVinculo => vCdHistCargoEfetivo,
                       pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                       pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa1,
                       pVlIntegral           => NULL,
                       pVlProporcional       => NULL,
                       pNuSufixoRubrica      => 1,
                       pNuParcelas           => 1,
                       pVlIndice             => NULL,
                       pCdTipoOrigemRubrica  => 1);

          /* Processa valores na relacao de vinculo */
          PKGPAG_FB.PProcessaFormulasBases(pFolha, PKGPAG_VAR.vgVinculo.CdVinculo, pEvento.CdRubAgrupAlternativa1, 1, 1);

          /* Busca valores calculados na relacao de vinculo */
          vVlPagamento := PKGPAG_GERAL.FRetornaValorRubricaRV(pFolha.CdFolhaPagamento, PKGPAG_VAR.vgVinculo.CdVinculo
                               , pEvento.CdRubAgrupAlternativa1, 1);

          /* Busca valores pagos na folha anterior para nao pagar em duplicidade
             SIG-9832 01-0332 duplicada em folhas sequenciais  */

          vVlPagamentoFolhaAnterior := 0;

          vVlPagamentoFolhaAnterior := nvl(pkgpag_geral.fretornavalorrubrica(pFolha.CdFolhaPagamentoNormalAnt,
                                           PKGPAG_VAR.vgVinculo.CdVinculo,pEvento.CdRubAgrupAlternativa1),0);

          if vVlPagamentoFolhaAnterior > 0 and
             vVlPagamentoFolhaAnterior >= vVlPagamento.VlReal then

             return;

          end if;

          vVlPagamento.VlReal := vVlPagamento.VlReal - nvl(vVlPagamentoFolhaAnterior,0);

          IF vVlPagamento.VlReal > 0 THEN
            /* Insere valor Real no vinculo */
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pFolha.CdFolhaPagamento,
                               pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                               pCdExpressaoFormCalc  => NULL,
                               pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa1,
                               pNuSufixoRubrica      => 1,
                               pVlPagamento          => NVL(vVlPagamento.vlReal,0),
                               pVlIndice             => vVlPagamento.vlIndice,
                               pCdTipoOrigemRubrica  => 1);
          ELSE /* Se nao possui relacao de vinculo, calcula diretamente sobre o vinculo */
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                               pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                               pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                               pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa1,
                               pNuSufixoRubrica      => 1,
                               pVlPagamento          => 0,
                               pVlIndice             => NULL,
                               pCdTipoOrigemRubrica  => 1);
            PKGPAG_FB.PProcessaFormulasBases(pFolha, PKGPAG_VAR.vgVinculo.CdVinculo, pEvento.CdRubAgrupAlternativa1, 1, 2);
          END IF;
        END IF;
        PKGPAG_VAR.vgCdRubCalculada := null;
      END IF;
    END IF;
  END IF;
END;

-------------------------------------------------------------------------------------------
-- Rescisao de Ferias CTISP Agrupamento Militar
-- Este evento podera gerar duas Rubricas :
-- Indenizacao de Ferias do 1º ano de contrato (01-0316)
-- Indenizacao de Ferias previstas             (01-0317)
-- Rubricas incluidas no pacote PKGPAG_EVVINC. Indice referente aos meses trabalhados no periodo
-- de ferias apurado
--------------------------------------------------------------------------------------------

PROCEDURE P069RescisaoFeriasCTISP(pFolha          IN PKGPAG_TIPO.rFolha,
                                  pEvento         IN PKGPAG_TIPO.rEvento,
                                  pTemDifMes      IN BOOLEAN,
                                  pRubrica        IN PKGPAG_TIPO.rRubrica) IS

BEGIN

      -- Indenizacao de Ferias nao pagas rescisao (01-0316)

     IF NOT PKGPAG_VAR.vListaRubricas.EXISTS(pRubrica.CdRubricaAgrupamento) -- Possui Lancamento Financeiro
        AND NOT PKGPAG_VAR.vgRubrica(pRubrica.CdRubricaAgrupamento).FlSuspensa = PKGPAG_TIPO.cnS
        AND pkgpag_var.vgNuDiasFeriasNaoPagas > 0

        THEN

               PKGPAG_FB.PProcessaFormulasBases(pFolha, PKGPAG_VAR.vgVinculo.CdVinculo, pEvento.CdRubricaAgrupamento, 1, 1);

     END IF;

    -- Indenizacao de Ferias previstas (01-0317)

    IF NOT PKGPAG_VAR.vListaRubricas.EXISTS(pEvento.CdRubAgrupAlternativa1)
      AND NOT PKGPAG_VAR.vgRubrica(pEvento.CdRubAgrupAlternativa1).FlSuspensa = PKGPAG_TIPO.cnS
      AND pkgpag_var.vgNuDiasFeriasPrevistos > 0

      THEN   -- Rubrica nao esta suspensa

         PKGPAG_FB.PProcessaFormulasBases(pFolha, PKGPAG_VAR.vgVinculo.CdVinculo, pEvento.CdRubAgrupAlternativa1, 1, 1);

      END IF;

      PKGPAG_VAR.vgCdRubCalculada := null;

END;

---------------------------------------------------------------------------
-- Processa os eventos de ferias indenizadas e 1/3 de ferias indenizadas
---------------------------------------------------------------------------

PROCEDURE P073074FeriasIndenizadas(pCdRubricaAgrupamento IN INTEGER) IS

  vCont                INTEGER;

  vCdExpressaoFormCalc INTEGER;

  vVlFolhaAnt          number(13,2);

  vCdFolhaNormalAnt    integer;

  vVlFeriasIndenizadas number(13,2) :=0;

BEGIN

  IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento),
                                            pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                            pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                                            pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) THEN

    SELECT COUNT(*)
      INTO vCont
      FROM EMovPeriodoAquisitivoFerias PA
     INNER JOIN EMovFeriasFruicaoPagamento FFP
        ON PA.CdPeriodoAquisitivoFerias = FFP.CdPeriodoAquisitivoFerias
     INNER JOIN EMovFeriasFruicaoUsufruto FFU
        ON FFU.CdFeriasProgramacaoUsufruto = FFP.CdFeriasProgramacaoUsufruto
     WHERE PA.CdVinculo = PKGPAG_VAR.vgCdVinculo AND
           FFP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
           FFP.NuMesReferencia = PKGPAG_VAR.vgFolha.NuMesReferencia AND
           FFP.FlPagamentoIndenizado = PKGPAG_TIPO.cnS AND
           FFP.FlAnulado = PKGPAG_TIPO.cnN;

    IF vCont > 0 THEN

      vCdExpressaoFormCalc :=

              PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                     pCdRubricaAgrupamento     => pCdRubricaAgrupamento,
                                                     pCdRelacaoVinculo         => 0);
      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => PKGPAG_VAR.vgCdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                         PKGPAG_VAR.vgCdVinculo,
                                         pCdRubricaAgrupamento,
                                         1,
                                         2);

        vVlFeriasIndenizadas := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamentoNormal,
                                                                         pcdvinculo => PKGPAG_VAR.vgCdVinculo,
                                                                         pcdrubrica => pCdRubricaAgrupamento);

      END IF;

    END IF;

  END IF;

  -- Devolucao de ferias indenizadas indevidas para servidores que receberam mas tem um novo vinculo apos o calculo anterior
  if  pkgpag_var.vgcef.count > 0 and fAlterouCargoEfetivo(PKGPAG_VAR.vgCdVinculo) and vVlFeriasIndenizadas = 0
     then

     vVlFolhaAnt := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => case when nvl(vCdFolhaNormalAnt,0) = 0
                                                                                then pkgpag_var.vgFolha.CdFolhaPagamentoNormalAnt
                                                                                else vCdFolhaNormalAnt end,
                                                             pcdvinculo => PKGPAG_VAR.vgCdVinculo,
                                                             pcdrubrica => pCdRubricaAgrupamento);

     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => PKGPAG_VAR.vgCdVinculo,
                                              pCdExpressaoFormCalc  => null,
                                              pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,
                                                                       pkgpag_var.vgRubrica(pCdRubricaAgrupamento).NuRubrica),
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => vVlFolhaAnt,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

  end if;

END;


PROCEDURE p011156feriasindenizadasvinc(pcdrubricaagrupamento IN INTEGER) IS

  vnumeses                INTEGER;
  vcdexpressaoformcalc    INTEGER := 0;
  vvlcalculado            pkgpag_tipo.rvalorpagamento;
  vdeexpressao            CHAR(200) := 0;
  vnusufixorubrica        INTEGER := 0;
  vnudiasusufruto         INTEGER := 0;
  vnudiasferiasparcial    INTEGER := 0;
  vvlrecebidomesant       NUMBER(13, 2);
  vnudiascomestorno       INTEGER := 0;
  vtemestornobeneficio    BOOLEAN := FALSE;
  vvlrecebidoferiasmesant NUMBER(13, 2);
  vdtDesligamento         DATE;
  
BEGIN

  vvlrecebidomesant := pkgpag_fb.fmnesomaoutrasfolhasmes(pcdvinculo            => pkgpag_var.vgvinculo.cdvinculo,
                                                           pcdrubricaagrupamento => pcdrubricaagrupamento,
                                                           pfolha                => pkgpag_var.vgfolha,
                                                           pflmesanterior        => 'S');

  IF (PKGPAG_VAR.vgAPO.COUNT > 0 OR PKGPAG_VAR.vgAPOSemParidade.COUNT > 0) AND 
      PKGPAG_VAR.vgCEF.COUNT > 0 THEN
     
     IF PKGPAG_VAR.vgCEF(PKGPAG_VAR.vgCEF.FIRST).DtFimRelacao BETWEEN (pkgpag_var.vgfolha.dtiniciomes - 1) AND pkgpag_var.vgfolha.dtfimmes THEN
    
       vdtDesligamento := PKGPAG_VAR.vgCEF(PKGPAG_VAR.vgCEF.FIRST).DtFimRelacao;
       
     END IF;
      
  END IF;
  
  IF vdtDesligamento IS NULL THEN
    
    vdtDesligamento := PKGPAG_VAR.vgvinculo.dtdesligamento;  
    
  END IF;
     
  IF (vdtDesligamento BETWEEN (pkgpag_var.vgfolha.dtiniciomes - 1) AND pkgpag_var.vgfolha.dtfimmes) OR
     (pkgpag_var.vmotafast.intipoafastamento = 'D' AND
     trunc(pkgpag_var.vmotafast.dtinclusao) >=
     trunc(pkgpag_var.vgfolha.dtcalculoant) AND
     (to_char(pkgpag_var.vgvinculo.dtdesligamento, 'yyyymm') =
     to_char(pkgpag_var.vgfolha.dtcalculoant, 'yyyymm') OR
     to_number(to_char(pkgpag_var.vgvinculo.dtdesligamento, 'yyyymm')) =
     to_number(to_char(pkgpag_var.vgfolha.dtcalculoant, 'yyyymm')) - 1))
     THEN

    IF pkgpag_var.vgfolha.cdtipofolha IN (pkgpag_tipo.cntpfolhanormal, pkgpag_tipo.cnTpFolhaConvenio) AND
       ((pkgpag_geral.fpossuiabrangenciarubrica(prubrica                  => pkgpag_var.vgrubrica(pcdrubricaagrupamento),
                                                pcdrelacaotrabalho        => pkgpag_var.vgrelvincprincipal.cdreltrabpagamento,
                                                pcdorgao                  => pkgpag_var.vgcdorgaovinculo,
                                                pcdorgaoexercicio         => pkgpag_var.vgcdorgaovinculo,
                                                pcdsituacaoprevidenciaria => pkgpag_var.vgvinculo.cdsituacaoprevidenciaria) AND
       fcarreirapermitidasrubrica(pcdvinculo => pkgpag_var.vgvinculo.cdvinculo,
                                    pdtinicio  => pkgpag_var.vgfolha.dtiniciomes,
                                    pdtfim     => pkgpag_var.vgfolha.dtfimmes,
                                    prubrica   => pkgpag_var.vgrubrica(pcdrubricaagrupamento))) OR
       nvl(vvlrecebidomesant, 0) > 0) THEN

      IF (pkgpag_var.vgvinculo.cdsituacaoPrevidenciaria = 12 AND --FALECIDO
       NOT fPossuiSitPrevVigenteMesAnt(pkgpag_var.vgvinculo.cdvinculo,
                                   pkgpag_var.vgvinculo.dtDesligamento))
        THEN
        RETURN;
      END IF;

      FOR fer IN (SELECT DISTINCT pf.cdsituacaoperiodoaqferias,
                                  pf.dtinicio,
                                  pf.dtfim,
                                  pf.cdperiodoaquisitivoferias,
                                  greatest(nvl(pf.nudiasferiasconcedido, 30),
                                           30) AS dias,
                                  SUM(ffu.nudias) nudiasusufruto,
                                  ffu.insituacao,
                                  ffu.dtinicial dtinicialusufruto,
                                  ffp.nuanoreferencia nuanoreferenciapag,
                                  lpad(ffp.numesreferencia, 2, 0) numesreferenciapag,
                                  ffp.nudiasdevolvidos
                    FROM emovperiodoaquisitivoferias pf
                    LEFT JOIN emovferiasfruicaousufruto ffu
                      ON ffu.cdperiodoaquisitivoferias = pf.cdperiodoaquisitivoferias
                     AND ffu.flanulado = 'N'
                     AND ffu.insituacao <> 12
                    LEFT JOIN emovferiasfruicaopagamento ffp
                      ON ffp.cdperiodoaquisitivoferias = pf.cdperiodoaquisitivoferias
                     AND ffp.flanulado = 'N'
                   WHERE pf.cdvinculo = pkgpag_var.vgcdvinculo
                     AND pf.dtinicio <= pkgpag_var.vgfolha.dtiniciomes -- períodos aquisitivos anteriores ao início da folha
                     AND pf.dtinicio >= pkgpag_var.vgvinculo.dtadmissao -- data de admissão
                     AND pf.cdsituacaoperiodoaqferias IN (1, 2)
     					   AND pf.dtinicio >= to_date('01/01/2018','dd/mm/yyyy') --22964/2025 - INDENIZACAO DE FERIAS INATIVO - Claudemir Gomes - 30/07/2025                     
                     AND NOT EXISTS
                   (SELECT 1
                            FROM emovferiasfruicaopagamento fpag
                           WHERE fpag.cdperiodoaquisitivoferias = pf.cdperiodoaquisitivoferias
                             AND fpag.flanulado = 'N')
                  --and PF.DtInicio >= add_months(PKGPAG_VAR.vgFolha.DtInicioMes,-30)
                   GROUP BY pf.cdsituacaoperiodoaqferias,
                            pf.dtinicio,
                            pf.dtfim,
                            pf.cdperiodoaquisitivoferias,
                            pf.nudiasferiasconcedido,
                            ffu.nudias,
                            ffu.insituacao,
                            ffu.dtinicial,
                            ffp.nuanoreferencia,
                            ffp.numesreferencia,
                            ffp.nudiasdevolvidos
                   ORDER BY pf.dtinicio DESC) -- Periodo previsto ou conquistado
      -- Com usufruto parcial ou programado
       LOOP

        vnusufixorubrica := vnusufixorubrica + 1;

        vnudiasusufruto := greatest(nvl(fer.nudiasusufruto, 0) -
                                    nvl(fer.nudiasdevolvidos, 0),
                                    0);

        IF fer.insituacao = 5 AND vnudiasusufruto < 0
        -- 5  Suspenso com estorno dos benefícios
         THEN
          vnudiascomestorno    := abs(vnudiasusufruto);
          vtemestornobeneficio := TRUE;
        ELSE
          vtemestornobeneficio := FALSE;
        END IF;

        IF nvl(vnudiasusufruto, 0) >= 30 THEN
          CONTINUE;
        END IF;

        -- SIG-10180 01-1156 pagando periodo previsto incompleto
        -- SIG-10200 pagamento proporcional de ferias
        vnumeses := least(nvl(pkgpag_fb.fmneuqtmesestrabano(pfolha            => pkgpag_var.vgfolha,
                                                            pcdvinculo        => pkgpag_var.vgcdvinculo,
                                                            pdtiniciorelacao  => fer.dtinicio,
                                                            pdtfimrelacao      => least(case 
                                                                                         when to_char(vdtDesligamento,'DD') < 15 and
                                                                                              to_char(vdtDesligamento,'YYYYMM') = to_char(pkgpag_var.vgfolha.dtiniciomes,'YYYYMM') then
                                                                                              -- Se nao completou 15 dias no mes no inicio ou no fim nao conta
                                                                                                   pkgpag_var.vgfolha.dtiniciomes - 1
                                                                                         else 
                                                                                           vdtDesligamento 
                                                                                         end,
                                                                                      fer.dtfim),
                                                            pdtcalculo        => least(pkgpag_var.vgfolha.dtcalculo,
                                                                                       fer.dtfim),
                                                            pflperiodoferias   => 'S',
                                                            pFlValidaAuxDoenca => 'S'), 0), 12);

        vnudiasferiasparcial := fer.dias * (vnumeses / 12);

        vcdexpressaoformcalc := pkgpag_geral.fidentificaformulacalculo(pkgpag_var.vgformexpr,
                                                                       pcdrubricaagrupamento,
                                                                       0);

        pkgpag_geral.pinserelancamentovinculo(pcdfolhapagamento     => pkgpag_var.vgfolha.cdfolhapagamento,
                                              pcdvinculo            => pkgpag_var.vgvinculo.cdvinculo,
                                              pcdexpressaoformcalc  => vcdexpressaoformcalc,
                                              pcdrubricaagrupamento => pcdrubricaagrupamento,
                                              pnusufixorubrica      => vnusufixorubrica,
                                              pvlpagamento          => 0,
                                              pvlindice             => vnumeses,
                                              pcdtipoorigemrubrica  => 1,
                                              pdeexpressao          => vdeexpressao);

        pkgpag_fb.pprocessaformulasbases(pfolha           => pkgpag_var.vgfolha,
                                         pcdvinculo       => pkgpag_var.vgvinculo.cdvinculo,
                                         pcdrubrica       => pcdrubricaagrupamento,
                                         ptpprocessamento => 1,
                                         ptplocal         => 2,
                                         pnusufixorubrica => vnusufixorubrica);

        IF vnudiasusufruto > 0 AND vnudiasusufruto < 30 THEN
          -- Proprocionaliza calculo e desconta 1/3
          vvlcalculado.vlproporcional := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgfolha.cdfolhapagamentonormalant,
                                                                           pcdvinculo        => pkgpag_var.vgvinculo.cdvinculo,
                                                                           pcdrubrica        => pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,
                                                                                                                             9,

                                                                                                                            1014));

         begin

          IF nvl(vvlrecebidomesant, 0) > 0 AND
             nvl(vnudiasusufruto, 0) <= vnudiasferiasparcial THEN

            vvlcalculado.vlproporcional := (((vvlcalculado.vlreal / 30) *
                                           (vnudiasferiasparcial -
                                           vnudiasusufruto)) +
                                           ((vvlcalculado.vlreal / 3) *
                                           (vnumeses / 12))) -
                                           vvlrecebidomesant;

            vdeexpressao := '((' || trunc(vvlcalculado.vlreal, 2) ||
                            ' /30) * (' || fer.dias || ' * ' || vnumeses ||
                            ' meses)/12 - ' || nvl(vnudiasusufruto, 0) ||
                            ' dias usufruídos) + (' ||
                            trunc(vvlcalculado.vlreal / 3, 2) || ' /30 * (' ||
                            fer.dias || ' * ' || vnumeses ||
                            ' meses)/12) - ' || nvl(vvlrecebidomesant, 0) ||
                            ' (valor recebido ref.: ' ||
                            lpad(fer.numesreferenciapag, 2, 0) || '/' ||
                            fer.nuanoreferenciapag || ')';

          ELSIF nvl(vnudiasusufruto, 0) <= vnudiasferiasparcial THEN

            vvlcalculado.vlproporcional := (((vvlcalculado.vlreal / 30) *
                                           (vnudiasferiasparcial -
                                           vnudiasusufruto)) +
                                           ((vvlcalculado.vlreal / 3) *
                                           (vnumeses / 12)));

            vdeexpressao := '((' || trunc(vvlcalculado.vlreal, 2) ||
                            ' /30) * (' || fer.dias || ' * ' || vnumeses ||
                            ' meses)/12 - ' || nvl(vnudiasusufruto, 0) ||
                            ' dias usufruídos) + (' ||
                            trunc(vvlcalculado.vlreal / 3, 2) || ' /30 * (' ||
                            fer.dias || ' * ' || vnumeses || ' meses)/12) ';
          ELSE

            vvlcalculado.vlproporcional := nvl((((vvlcalculado.vlreal / 30) *
                                           (vnudiasferiasparcial -
                                           vnudiasusufruto)) +
                                           ((vvlcalculado.vlreal / 3) *
                                           (vnumeses / 12))),0);

            vdeexpressao := '((' || trunc(vvlcalculado.vlreal, 2) ||
                            ' /30) * (' || fer.dias || ' * ' || vnumeses ||
                            ' meses)/12 - ' || nvl(vnudiasusufruto, 0) ||
                            ' dias usufruídos) + (' ||
                            trunc(vvlcalculado.vlreal / 3, 2) || ' /30 * (' ||
                            fer.dias || ' * ' || vnumeses || ' meses)/12) ';

            if nvl(vvlcalculado.vlproporcional,0) > 0 then

            -- caso o servidor usufruiu dias a mais do que teria direito, gera um desconto
            pkgpag_geral.pinserelancamentovinculo(pcdfolhapagamento     => pkgpag_var.vgfolha.cdfolhapagamento,
                                                  pcdvinculo            => pkgpag_var.vgvinculo.cdvinculo,
                                                  pcdexpressaoformcalc  => vdeexpressao,
                                                  pcdrubricaagrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,
                                                                                                        5,
                                                                                                        pkgpag_var.vgrubrica(pcdrubricaagrupamento)
                                                                                                        .nurubrica),
                                                  pnusufixorubrica      => 1,
                                                  pvlpagamento          => vvlcalculado.vlproporcional);

           end if;

          END IF;

          UPDATE epaghistoricorubricavinculo hv
             SET hv.vlpagamento = nvl(vvlcalculado.vlproporcional, 0),
                 hv.deexpressao = vdeexpressao
           WHERE hv.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
             AND hv.cdfolhapagamento = pkgpag_var.vgfolha.cdfolhapagamento
             AND hv.cdrubricaagrupamento = pcdrubricaagrupamento
             AND hv.nusufixorubrica = vnusufixorubrica;

          exception
            when others then
              null;

        end;

        END IF;

        -- SIG-1635: Inclusão de desconto para usufruto de férias suspenso com estorno dos benefícios.
        -- Caso o servidor tenha recebido férias no mês anterior a demissão, e tenha o usufruto suspenso com estorno dos benefícios
        IF vtemestornobeneficio AND vnudiascomestorno > 0 AND
           fer.dtinicialusufruto BETWEEN pkgpag_var.vgfolha.dtiniciomes AND
           pkgpag_var.vgfolha.dtfimmes THEN

          vvlrecebidoferiasmesant := pkgpag_fb.fmnesomaoutrasfolhasmes(pcdvinculo            => pkgpag_var.vgvinculo.cdvinculo,
                                                                       pcdrubricaagrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,
                                                                                                                             1,
                                                                                                                             56),
                                                                       pfolha                => pkgpag_var.vgfolha,
                                                                       pflmesanterior        => 'S');

          IF nvl(vvlrecebidoferiasmesant, 0) > 0 THEN

            pkgpag_geral.pinserelancamentovinculo(pcdfolhapagamento     => pkgpag_var.vgfolha.cdfolhapagamento,
                                                  pcdvinculo            => pkgpag_var.vgvinculo.cdvinculo,
                                                  pcdexpressaoformcalc  => NULL,
                                                  pcdrubricaagrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,
                                                                                                        5,
                                                                                                        56),
                                                  pnusufixorubrica      => 1,
                                                  pvlpagamento          => vvlrecebidoferiasmesant);

          END IF;

        END IF;

        IF nvl(vvlrecebidomesant, 0) > 0 THEN

          vvlcalculado.vlproporcional := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgfolha.cdfolhapagamento,
                                                                           pcdvinculo        => pkgpag_var.vgvinculo.cdvinculo,
                                                                           pcdrubrica        => pcdrubricaagrupamento,
                                                                           pnusufixo         => vnusufixorubrica);

          IF vvlrecebidomesant >= vvlcalculado.vlproporcional THEN

            vvlrecebidomesant           := vvlrecebidomesant -
                                           vvlcalculado.vlproporcional;
            vvlcalculado.vlproporcional := 0;

          ELSE

            vvlcalculado.vlproporcional := vvlcalculado.vlproporcional -
                                           vvlrecebidomesant;
            vvlrecebidomesant           := 0;

          END IF;

          IF vvlcalculado.vlproporcional > 0 THEN

            UPDATE epaghistoricorubricavinculo hv
               SET hv.vlpagamento = vvlcalculado.vlproporcional
             WHERE hv.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
               AND hv.cdfolhapagamento =
                   pkgpag_var.vgfolha.cdfolhapagamento
               AND hv.cdrubricaagrupamento = pcdrubricaagrupamento
               AND hv.nusufixorubrica = vnusufixorubrica;

          ELSE

            DELETE epaghistoricorubricavinculo hv
             WHERE hv.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
               AND hv.cdfolhapagamento =
                   pkgpag_var.vgfolha.cdfolhapagamento
               AND hv.cdrubricaagrupamento = pcdrubricaagrupamento
               AND hv.nusufixorubrica = vnusufixorubrica;

          END IF;

        END IF;

      END LOOP;
    END IF;

  ELSIF (nvl(vvlrecebidomesant, 0) > 0 AND
        falteroucargoefetivo(pkgpag_var.vgvinculo.cdvinculo) OR
        falteroucargocom(pkgpag_var.vgvinculo.cdvinculo) or
        fPossuiAfastDefinitivoAnulado(pkgpag_var.vgvinculo.cdvinculo))
        and not pkgpag_geral.fpossuilancfinanceiro(  pkgpag_var.vgvinculo.cdvinculo,pkgpag_var.vgFolha,
                                                    pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,8,
                                                                                 pkgpag_var.vgrubrica(pcdrubricaagrupamento).nurubrica)) THEN

    IF NVL(vvlrecebidomesant,0) = 0
      THEN
        vvlrecebidomesant := NVL(gVlRub1156,0);
    END IF;

    vvlrecebidoferiasmesant := 0;

    vvlrecebidoferiasmesant :=
     pkgpag_geral.fretornavalorrubrica(pkgpag_var.vgfolha.cdfolhapagamentonormalant,
                                       pkgpag_var.vgvinculo.cdvinculo,
                                       pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,8,
                                       pkgpag_var.vgrubrica(pcdrubricaagrupamento).nurubrica));

    -- Somente incluir se nao descontou a mesma rubrica 08 no mes anterior
    if nvl(vvlrecebidoferiasmesant,0) <> nvl(vvlrecebidomesant,0) then

    pkgpag_geral.pinserelancamentovinculo(pcdfolhapagamento     => pkgpag_var.vgfolha.cdfolhapagamento,
                                          pcdvinculo            => pkgpag_var.vgvinculo.cdvinculo,
                                          pcdexpressaoformcalc  => NULL,
                                          pcdrubricaagrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,
                                                                                                8,
                                                                                                pkgpag_var.vgrubrica(pcdrubricaagrupamento)
                                                                                                .nurubrica),
                                          pnusufixorubrica      => 1,
                                          pvlpagamento          => vvlrecebidomesant);

    end if;

  ELSE

    NULL;

  END IF;

END;

PROCEDURE P010392FeriasIndenizadasACTSJC(pCdRubricaAgrupamento IN INTEGER, pCdFolhaAnterior in integer default null) IS

  vCont                INTEGER;
  vNuMeses             INTEGER;
  vCdExpressaoFormCalc INTEGER;
  vVlPagamento PKGPAG_TIPO.rValorPagamento;
  --vValorCalculado      number(13,2);
  --vDeFormula           char(200);

BEGIN

  -- Rubrica específica de ACT
  IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT AND
    PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento),
                                            pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                            pCdOrgaoExercicio         => PKGPAG_VAR.vgCdOrgaoVinculo,
                                            pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria)
      AND FCarreiraPermitidasRubrica(pCdVinculo => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                  pDtInicio=>  PKGPAG_VAR.vgFolha.DtInicioMes,
                                                  pDtFim =>  PKGPAG_VAR.vgFolha.DtFimMes,
                                                  pRubrica => PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento))

                                                                                                                                    THEN

      FOR FER IN (SELECT pf.dtinicio, pf.dtfim
                    FROM emovperiodoaquisitivoferias pf
                   WHERE PF.CdVinculo = PKGPAG_VAR.vgCdVinculo
                     AND pf.DtInicio <= pkgpag_var.vgVinculo.DtDesligamento
                     AND PF.DtInicio >= pkgpag_var.vgRelVincPrincipal.DtInicioRelacao
                     AND NOT EXISTS
                   (SELECT 1
                            FROM emovferiasfruicaousufruto ffu
                           WHERE FFU.CdPeriodoAquisitivoFerias =
                                 PF.CdPeriodoAquisitivoFerias
                             AND FFU.FlAnulado = 'N'
                             AND FFU.DtInicial < pkgpag_var.vgFolha.DtFimMes))

       LOOP

        vNuMeses := NVL(pkgpag_fb.fmneuqtmesestrabano(pFolha           => pkgpag_var.vgFolha,
                                                      pCdVinculo       => PKGPAG_VAR.vgCdVinculo,
                                                      pdtiniciorelacao => FER.DtInicio,
                                                      pdtfimrelacao    => least(pkgpag_var.vgVinculo.DtDesligamento,FER.DtFim),
                                                      pdtcalculo       => pkgpag_var.vgFolha.DtCalculo,
                                                      pFlPeriodoFerias => 'S'),
                        0);

        IF vNuMeses > 0 THEN

          vCont := vCont + 1;

          vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(PKGPAG_VAR.vgFormExpr,
                                                                         pCdRubricaAgrupamento,
                                                                         0);

        IF vCdExpressaoFormCalc > 0 THEN

            /* Prepara calculo da rubrica na relacao de vinculo, para poder trazer valor real */
            PKGPAG_GERAL.PInsereLancamentoRelacao(
                          pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                          pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                          pCdRelacaoVinculo     => 1,
                          pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                          pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                          pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                          pVlIntegral           => NULL,
                          pVlProporcional       => NULL,
                          pNuSufixoRubrica      => 1,
                          pNuParcelas           => 1,
                          pVlIndice             => vNuMeses,
                          pCdTipoOrigemRubrica  => 1);

            /* Processa valores na relacao de vinculo */
            PKGPAG_FB.PProcessaFormulasBases(pkgpag_var.vgFolha,
                                             PKGPAG_VAR.vgVinculo.CdVinculo,
                                             pCdRubricaAgrupamento,
                                             1,
                                             1);

            /* Busca valores calculados na relacao de vinculo */
            vVlPagamento := PKGPAG_GERAL.FRetornaValorRubricaRV(pkgpag_var.vgFolha.CdFolhaPagamento,
                                                                PKGPAG_VAR.vgVinculo.CdVinculo,
                                                                pCdRubricaAgrupamento,
                                                                1);


            IF vVlPagamento.VlReal > 0 THEN
              /* Insere valor Real no vinculo */
              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pkgpag_var.vgFolha.CdFolhaPagamento,
                                 pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pCdExpressaoFormCalc  => NULL,
                                 pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                 pNuSufixoRubrica      => 1,
                                 pVlPagamento          => NVL(vVlPagamento.vlReal,0),
                                 pVlIndice             => vNuMeses,
                                 pCdTipoOrigemRubrica  => 1);

            ELSE /* Caso nao calcule nada na relacao, calcula no vinculo */
              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                 pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                 pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                 pNuSufixoRubrica      => 1,
                                 pVlPagamento          => 0,
                                 pVlIndice             => vNuMeses,
                                 pCdTipoOrigemRubrica  => 1);

              PKGPAG_FB.PProcessaFormulasBases(pkgpag_var.vgFolha,
                                               PKGPAG_VAR.vgVinculo.CdVinculo,
                                               pCdRubricaAgrupamento,
                                               1,
                                               2);

            END IF;

            if pkgmath.FCalcular(pkgpag_var.vgValorCalculoRubrica (pCdRubricaAgrupamento).DeFormulaExpressao) < 0

               then

               vVlPagamento.VlReal := pkgmath.FCalcular(pkgpag_var.vgValorCalculoRubrica (pCdRubricaAgrupamento).DeFormulaExpressao) * -1;

                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                      pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                      pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                      pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pkgpag_var.vgFolha.CdAgrupamento,
                                                                                                            pCdTipoRubrica => 5,
                                                                                                            pNuRubrica     => pkgpag_var.vgrubrica(pCdRubricaAgrupamento).NuRubrica),
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => vVlPagamento.VlReal ,
                                                      pVlIndice             => vNuMeses,
                                                      pCdTipoOrigemRubrica  => 1,
                                                      pDeExpressao => pkgpag_var.vgValorCalculoRubrica (pCdRubricaAgrupamento).DeFormulaExpressao  );

            end if;

        END IF;
        END IF;

      END LOOP;

  END IF;

  EXCEPTION

      WHEN OTHERS THEN

       NULL;

END;

--
-- Solicitacao de Sustentacao #78198
-- 11138/2017 - SIGRH - FOLHA DE INSTITUIDORES DE PENSAO
-- SIGRH - FOLHA DE INSTITUIDORES DE PENSAO
-- SEGUE EM ANEXO UM SCRIPT (BASTANTE SIMPLES) QUE TEM COMO OBJETIVO REALIZAR A COPIA DOS CONTRACHEQUES DE
-- INSTITUIDORES DE PENSAO PROVENIENTES DO SIRH EM FOLHAS DE INSTITUIDORES DO SIGRH, PARA AQUELES CASOS ONDE
-- O SIGRH AINDA NAO CONSEGUIU CALCULAR COM OS MESMOS VALORES DO SIRH. AS FOLHAS PROVENIENTES DO SIRH FORAM
-- DEFINIDAS COM O TIPO DE CALCULO SIMULACAO E SEQUENCIAL DE FOLHA IGUAL A 2.

-- NA TABELA SIGRH.EPAGMATRICULABATIMENTO ESTAO CONTIDOS OS VINCULOS DOS INSTITUIDORES QUE A ROTINA EM ANEXO
-- PRECISA REALIZAR A COPIA. NA MEDIDA QUE OS TRABALHOS DE BATIMENTO FOREM AVANCANDO, O ROGERIO FARA O TRABALHO
-- DE RETIRAR OS VINCULOS CUJOS CONTRACHEQUES NAO PRECISAM SER SUBSTITUIDOS PELA ROTINA.

-- A IDEIA E QUE SEJA CRIADA UMA PROCEDURE DENTRO DE ALGUM PACOTE DO CALCULO
-- (PKGPAG_TAR OU PKGPAG_PRE TALVEZ) COM O CODIGO ANEXO E QUE ESTA SEJA CHAMADA AO CONCLUIR O
-- PROCESSAMENTO DAS FOLHAS DE INSTITUIDORES DE PENSAO (APENAS PARA PROCESSAMENTO GERAL).
-- ESTA PROCEDURE TERIA COMO PARAMETRO O ANO/MES DE PROCESSAMENTO.
--

PROCEDURE PBATIMENTOINSTPENSAO(pNuAnoMes  IN INTEGER)
  IS

  VCDFOLHAORIGEM   INTEGER;
  VCDFOLHADESTINO  INTEGER;
  VCDORGAOFOLHA    INTEGER;

BEGIN

  FOR vRec IN (SELECT ARQ.CDVINCULO,
                      ARQ.CDAGRUPAMENTO,
                      ARQ.CDORGAOFOLHA,
                      V.NUMATRICULA,
                      V.NUDVMATRICULA,
                      V.NUSEQMATRICULA
                 FROM EPAGMATRICULABATIMENTO ARQ
                INNER JOIN ECADVINCULO V
                   ON V.CDVINCULO = ARQ.CDVINCULO)
  LOOP

     VCDFOLHAORIGEM  := 0;
     VCDFOLHADESTINO := 0;
     VCDORGAOFOLHA   := 0;

    ------ ENCONTRAR FOLHA ORIGEM
    BEGIN

    SELECT FP.CDFOLHAPAGAMENTO, FP.CDORGAO
      INTO VCDFOLHAORIGEM, VCDORGAOFOLHA
      FROM EPAGHISTORICORUBRICAVINCULO H
     INNER JOIN EPAGFOLHAPAGAMENTO FP
        ON H.CDFOLHAPAGAMENTO = FP.CDFOLHAPAGAMENTO
     INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
        ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
     WHERE FP.NUANOMESREFERENCIA = PNUANOMES
       AND TFP.CDAGRUPAMENTO = vrec.CDAGRUPAMENTO
       AND TFP.CDTIPOFOLHA = 6
       AND FP.CDTIPOCALCULO = 2 -- SIMULAÇÃO
       AND H.CDVINCULO = vrec.Cdvinculo
       AND ROWNUM < 2;

     EXCEPTION

       WHEN NO_DATA_FOUND THEN

          VCDFOLHAORIGEM := 0;
          VCDORGAOFOLHA  := 0;

     END;

     IF VCDFOLHAORIGEM = 0 THEN
         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo, --vCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vCdPessoa,
                                '** Erro ao copiar contracheque SIRH (PKGPAG_POS.PBATIMENTOINSTPENSAO.
                                    Não encontrada a folha origem: '||VCDFOLHADESTINO);
        CONTINUE;

     END IF;

     ------ DELETAR DESTINO
     FOR E1 IN
         (
          SELECT FP.CDFOLHAPAGAMENTO
            FROM EPAGHISTORICORUBRICAVINCULO H
           INNER JOIN SIGRH.EPAGFOLHAPAGAMENTO FP
              ON H.CDFOLHAPAGAMENTO = FP.CDFOLHAPAGAMENTO
           INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
              ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
           INNER JOIN VPAGRUBRICAAGRUPAMENTO RUB
              ON RUB.CDRUBRICAAGRUPAMENTO = H.CDRUBRICAAGRUPAMENTO
             AND RUB.CDTIPORUBRICA = 9
             AND RUB.NURUBRICA = 901
           WHERE FP.NUANOMESREFERENCIA = PNUANOMES
             AND TFP.CDTIPOFOLHA = 6
             AND TFP.CDAGRUPAMENTO = vrec.CDAGRUPAMENTO
             AND FP.CDTIPOCALCULO = PKGPAG_VAR.VGFOLHA.CDTIPOCALCULO
             AND H.CDVINCULO = VREC.CDVINCULO
             --AND FP.NUSEQUENCIALFOLHA = 1
         )
     LOOP

        DELETE FROM EPAGHISTORICORUBRICARELVINC
         WHERE CDVINCULO = vRec.CDVINCULO
           AND CDFOLHAPAGAMENTO = E1.CDFOLHAPAGAMENTO;

        DELETE FROM EPAGHISTORICORUBRICAVINCULO
         WHERE CDVINCULO = vRec.CDVINCULO
           AND CDFOLHAPAGAMENTO = E1.CDFOLHAPAGAMENTO;

     END LOOP;

     ------ ENCONTRAR FOLHA DESTINO
     FOR E2 IN
        (
        SELECT FP.CDFOLHAPAGAMENTO
          FROM EPAGFOLHAPAGAMENTO FP
         INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
            ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
         WHERE FP.NUANOMESREFERENCIA = PNUANOMES
           AND TFP.CDTIPOFOLHA = 6
           AND TFP.CDAGRUPAMENTO = vrec.CDAGRUPAMENTO
           AND FP.CDTIPOCALCULO = PKGPAG_VAR.VGFOLHA.CDTIPOCALCULO
           AND FP.cdOrgao = VCDORGAOFOLHA
           --AND FP.NUSEQUENCIALFOLHA = 1
                 )
      LOOP

          VCDFOLHADESTINO := NVL(E2.CDFOLHAPAGAMENTO, 0);

      END LOOP;

      IF VCDFOLHADESTINO = 0 THEN
         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo, --vCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vCdPessoa,
                                '** Erro ao copiar contracheque SIRH (PKGPAG_POS.PBATIMENTOINSTPENSAO).
                                    Não encontrada a folha destino: '||VCDFOLHADESTINO);

      END IF;

     IF vCDFOLHAORIGEM > 0 AND VCDFOLHADESTINO > 0 THEN

      INSERT INTO EPAGHISTORICORUBRICAVINCULO
       (CDHISTORICORUBRICAVINCULO,
        CDFOLHAPAGAMENTO,
        CDRUBRICAAGRUPAMENTO,
        CDVINCULO,
        NUSUFIXORUBRICA,
        CDLANCAMENTOFINANCEIRO,
        VLPAGAMENTO,
        QTPARCELAS,
        VLINDICERUBRICA,
        DTULTALTERACAO,
        CDVANTAGEMPECUNIARIA,
        CDRUBRICATOTALIZADORAVANTAGEM,
        NUORDEMCALCULO,
        CDEXPRESSAOFORMCALC,
        FLVIGENCIAPAGAMENTO,
        CDINCORPORACAOATIVO,
        VLMINRECEBINCORP,
        FLATUALIZACAOCONSTANTE,
        CDTIPORUBRICAORIGEM,
        VLRUBRICANORMAL,
        VLRUBRICASUPL,
        CDBASECONSIGNACAO,
        VLPAGAMENTOTRUNC,
        CDTIPOORIGEMRUBRICA,
        DEEXPRESSAO,
        DTDESLIGAMENTO,
        VLPAGAMENTOORIGINAL,
        DEPROCESSORETROATIVO,
        VLMONTANTERETROATIVO,
        VLINDICENMRRA,
        INCRITICA,
        DEINDICECONTRACHEQUE,
        CDTIPOINDICE,
        CDPROCESSOPAGRETROATIVO,
        CDHISTSENTENCAJUDICIAL,
        NUANOMESORIGEM,
        CDPROCESSORESTITUICAOERARIO
        )
        SELECT
          SPAGHISTORICORUBRICAVINCULO.NEXTVAL,
          VCDFOLHADESTINO,
          CDRUBRICAAGRUPAMENTO,
          CDVINCULO,
          NUSUFIXORUBRICA,
          CDLANCAMENTOFINANCEIRO,
          VLPAGAMENTO,
          QTPARCELAS,
          VLINDICERUBRICA,
          DTULTALTERACAO,
          CDVANTAGEMPECUNIARIA,
          CDRUBRICATOTALIZADORAVANTAGEM,
          NUORDEMCALCULO,
          CDEXPRESSAOFORMCALC,
          FLVIGENCIAPAGAMENTO,
          CDINCORPORACAOATIVO,
          VLMINRECEBINCORP,
          FLATUALIZACAOCONSTANTE,
          CDTIPORUBRICAORIGEM,
          VLRUBRICANORMAL,
          VLRUBRICASUPL,
          CDBASECONSIGNACAO,
          VLPAGAMENTOTRUNC,
          CDTIPOORIGEMRUBRICA,
          DEEXPRESSAO,
          DTDESLIGAMENTO,
          VLPAGAMENTOORIGINAL,
          DEPROCESSORETROATIVO,
          VLMONTANTERETROATIVO,
          VLINDICENMRRA,
          INCRITICA,
          DEINDICECONTRACHEQUE,
          CDTIPOINDICE,
          CDPROCESSOPAGRETROATIVO,
          CDHISTSENTENCAJUDICIAL,
          NUANOMESORIGEM,
          CDPROCESSORESTITUICAOERARIO
     FROM EPAGHISTORICORUBRICAVINCULO HRV
    WHERE HRV.CDFOLHAPAGAMENTO = VCDFOLHAORIGEM AND
          HRV.CDVINCULO = vREC.CdVinculo;

          /* PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo, --vCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vCdPessoa,      'Gravou o vinculo: '|| vrec.cdVinculo);*/
    ELSE

      NULL;

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo, --vCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              '** Erro ao copiar contracheque SIRH (PKGPAG_POS.PBATIMENTOINSTPENSAO).
                              Vinculo: ' || vrec.cdvinculo || '  sem folha de Simulação: '|| vrec.CdorgaoFolha ||
                              ' Folha ORIGEM : ' || vCdfolhaOrigem || '   Folha destino : '|| vcdFolhaDestino);

  END IF;

  END LOOP;

  EXCEPTION

      WHEN OTHERS THEN

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vgCalculo.CdHistoricoParamCalculo, --vCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vCdPessoa,
                                '** Erro ao copiar contracheque SIRH (PKGPAG_POS.PBATIMENTOINSTPENSAO)');

END;

--
-- BLOQUEIO DE REMUNERACAO NA APOSENTADORIA
--

PROCEDURE PBloqueioRemunApo(pAPO        IN PKGPAG_TIPO.tCEF,
                            pFolha      IN PKGPAG_TIPO.rFolha,
                            pCdRubrica  IN INTEGER) IS

vValorSalarioAnt PKGPAG_TIPO.rValorFixo;

vNuDiasProp INTEGER;

BEGIN

   FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST LOOP

      vNuDiasProp := (pApo(i).DtFim - pApo(i).DtInicio + 1);

      if vNuDiasProp > to_number(to_char(pFolha.DtFimMes,'DD'))
        then
          vNuDiasProp := to_number(to_char(pFolha.DtFimMes,'DD'));
      elsif to_number(to_char(pFolha.DtInicioMes,'MM')) = 2 and
            vNuDiasProp = to_number(to_char(pFolha.DtFimMes,'DD'))
        then
          vNuDiasProp := 30;
      else
        null;
      end if;

      vValorSalarioAnt :=

      PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                       pFolha.CdOrgao,
                                       pFolha.NuVersaoTabcef,
                                       pFolha.NuAnoReferencia,
                                       pFolha.NuMesReferencia,
                                       pAPO(i).CdEstruturaCarreiraCef,
                                       pAPO(i).CdEstruturaCarreiraCarreiraCef,
                                       pAPO(i).NuNivelPagamentoCef,
                                       pAPO(i).NuReferenciaPagamentoCef);

     IF PKGPAG_VAR.vgValorFixoCEF.vlFixo > vValorSalarioAnt.vlFixo

        THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo
                          (pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                           pCdVinculo            => pApo(i).CdVinculo,
                           pCdExpressaoFormCalc  => NULL,
                           pCdRubricaAgrupamento => pCdRubrica,
                           pNuSufixoRubrica      => 1,
                           pVlPagamento          => ((PKGPAG_VAR.vgValorFixoCEF.vlFixo - vValorSalarioAnt.vlFixo) / 30
                                                      * vNuDiasProp),
                           pVlIndice             => vNuDiasProp,
                           pCdTipoOrigemRubrica  => 2);

     END IF;

   END LOOP;

END;

/*-----------------------------------------------------------------------------------------------*/
-- Retorna o valor de referencia associado ao Bloqueio de Remuneracao - Teto
-- Caso exista alguma decisao judicial
/*-----------------------------------------------------------------------------------------------*/

  FUNCTION RetornaValorRefBloqRemun (pCdVinculo     IN INTEGER,
                                     pCdAgrupamento IN INTEGER,
                                     pCdFolhaPagto  IN INTEGER,
                                     pNuAno         IN INTEGER,
                                     pNuMes         IN INTEGER )
    RETURN NUMBER IS

    vCdHistValorReferencia INTEGER;

    vVlReferencia          NUMBER(13,2);

    vVlReferenciaCarreira  NUMBER(13,2);

    FUNCTION FValorReferenciaCarreira (pCdHistValorReferencia IN INTEGER,
                                       pCdEstruturaCarreira   IN INTEGER )

      RETURN NUMBER IS

      vCdEstrutura INTEGER;

      vVlReferencia NUMBER(13,2);

    BEGIN

      vCdEstrutura := PKGPAG_GERAL.FExisteCarreira (pCdEstruturaCarreira);

      WHILE vCdEstrutura IS NOT NULL LOOP

        BEGIN

          SELECT VRC.VlReferencia
            INTO vvlReferencia
            FROM EPagHistValorRefCarreira VRC
           WHERE VRC.CdHistValorReferencia = pCdHistValorReferencia AND
                 VRC.CdEstruturaCarreira = vCdEstrutura;

           RETURN vvlReferencia;

        EXCEPTION

          WHEN OTHERS THEN

            NULL;

        END;

        vCdEstrutura := PKGPAG_GERAL.FProxCarreira (vCdEstrutura);

      END LOOP;

      RETURN NULL;

    END;

    FUNCTION FEstruturaCarreiraMesAnt (pCdVinculo in integer)

      RETURN NUMBER IS

      vCdEstrutura INTEGER;

    BEGIN

      select cp.cdestruturacarreira
        into vCdEstrutura
        from epagcapahistrubricavinculo cp
       where cp.cdvinculo = pCdVinculo
         and cp.cdfolhapagamento = pkgpag_var.vgFolha.CdFolhaPagamentoNormalAnt;

      return vCdEstrutura;

     EXCEPTION

       WHEN OTHERS THEN

          NULL;

      RETURN NULL;

    END;

  BEGIN

     --- Busca o valor do Teto de Remuneracao - Teto

     -- Caso possua alguma decisao judicial para a rubrica do Teto do Governador
     -- busca o valor do teto na sentenca do contrario seleciona da tabela de valor de referencia

    vVlReferenciaCarreira := NULL;

    IF PKGPAG_VAR.vgVlRefTetoDecJud IS NOT NULL THEN

      RETURN PKGPAG_VAR.vgVlRefTetoDecJud;

    ELSIF PKGPAG_VAR.vgCdValRefTetoDecJud IS NOT NULL THEN

      RETURN PKGPAG_VAR.vgValorReferencia(PKGPAG_VAR.vgCdValRefTetoDecJud).VlReferencia;

    ELSE

       SELECT HVR.CdHistValorReferencia,
              HVR.VlReferencia
         INTO vCdHistValorReferencia,
              vVlReferencia
         FROM EPagValorReferencia VR
        INNER JOIN EPagValorReferenciaVersao VRV
           ON VR.CdValorReferencia = VRV.CdValorReferencia
        INNER JOIN EPagHistValorReferencia HVR
           ON VRV.CdValorReferenciaVersao = HVR.CdValorReferenciaVersao
        WHERE VR.CdAgrupamento = pCdAgrupamento AND
              VR.FlBloqueioRemuneracao = 'S' AND
              VRV.NuVersao = 1 AND
              (HVR.NuAnoInicioVigencia < pNuAno OR
              (HVR.NuAnoInicioVigencia = pNuAno AND
              HVR.NuMesInicioVigencia <= pNuMes)) AND
              (HVR.NuAnoFimVigencia > pNuAno OR
              (HVR.NuAnoFimVigencia = pNuAno AND
               HVR.NuMesFimVigencia >= pNuMes) OR
              HVR.NuAnoFimVigencia IS NULL);

    END IF;

    IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

      vVlReferenciaCarreira := FValorReferenciaCarreira
                               (pCdHistValorReferencia => vCdHistValorReferencia,
                                pCdEstruturaCarreira   => PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira );

    ELSIF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

      vVlReferenciaCarreira := FValorReferenciaCarreira
                               (pCdHistValorReferencia => vCdHistValorReferencia,
                                pCdEstruturaCarreira   => PKGPAG_VAR.vgAPO(1).CdEstruturaCarreira );

    elsif PKGPAG_VAR.vgCEF.COUNT = 0 and
          PKGPAG_VAR.vgAPO.COUNT = 0 and
          FEstruturaCarreiraMesAnt(pCdVinculo) > 0 then

          vVlReferenciaCarreira := FValorReferenciaCarreira
                                   (pCdHistValorReferencia => vCdHistValorReferencia,
                                    pCdEstruturaCarreira   => FEstruturaCarreiraMesAnt(pCdVinculo));

    else
      null;
    END IF;

    IF vVlReferenciaCarreira IS NOT NULL THEN

      RETURN vVlReferenciaCarreira;

    ELSE

      RETURN vVlReferencia;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

       RETURN 0;

  END;

END PKGPAG_POS;
/
