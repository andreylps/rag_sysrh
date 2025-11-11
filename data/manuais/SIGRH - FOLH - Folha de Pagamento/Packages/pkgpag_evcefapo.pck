create or replace package PKGPAG_EVCEFAPO is

  /*

     Tratamento de Eventos da Folha de Pagamento

     Relacao de Vinculo Efetivo/Aposentadoria

  */

  PROCEDURE PInicializaVinculo;

  PROCEDURE PProcessaEventosCEF(pVinculo             IN PKGPAG_TIPO.rVinculo,
                                pFolha               IN PKGPAG_TIPO.rFolha,
                                pEvento              IN PKGPAG_TIPO.rEvento,
                                pRubrica             IN PKGPAG_TIPO.tRubrica,
                                pFormExpr            IN PKGPAG_TIPO.tFormulaCalculo,
                                pCEF                 IN PKGPAG_TIPO.tCEF,
                                pdtCalculo           IN DATE,
                                pCdEstruturaCarreira IN OUT INTEGER);

  PROCEDURE PProcessaEventosAPO(pVinculo   IN PKGPAG_TIPO.rVinculo,
                                pFolha     IN PKGPAG_TIPO.rFolha,
                                pEvento    IN PKGPAG_TIPO.rEvento,
                                pRubrica   IN PKGPAG_TIPO.tRubrica,
                                pAPO       IN PKGPAG_TIPO.tCEF,
                                pdtCalculo IN DATE);

  PROCEDURE PProcessaEventosAPOSemParid(pVinculo     IN PKGPAG_TIPO.rVinculo,
                                        pFolha       IN PKGPAG_TIPO.rFolha,
                                        pEvento      IN PKGPAG_TIPO.rEvento,
                                        pRubrica     IN PKGPAG_TIPO.tRubrica,
                                        pAPOSemParid IN PKGPAG_TIPO.tCEF);

  PROCEDURE PObterEnturmacao (pFolha    IN PKGPAG_TIPO.rFolha,
                              pCEF      IN PKGPAG_TIPO.rCEF);

end PKGPAG_EVCEFAPO;
/
create or replace package body PKGPAG_EVCEFAPO is

 vgPercentRegenciaClasse      NUMBER;
 vgPercentRegenciaClasseSub   NUMBER;
 vgAulaExcedente              NUMBER;
 vgGratifAtivEsp              NUMBER;
 vgDiasRegencia               NUMBER;
 vgHorasEnturmacao            NUMBER;
 vgArea                       NUMBER;
 vgDisciplina                 NUMBER;
 vgTemRegenciaUltDiaMes       BOOLEAN;
 vgDescFormula                VARCHAR2 (4000);
 vgVLFixoCEF                  NUMBER (13,2);
 vgNuDiasUteisAfa             NUMBER;

 CURSOR cHistJornada(pCdHistCargoEfetivo   IN INTEGER,
                     pCdApuracaoFrequencia IN INTEGER,
                     pDtInicialApuracao    IN DATE,
                     pDtFinalApuracao      IN DATE) IS
    SELECT CdHistJornadaTrabalho,
           CASE
             WHEN HJT.DtInicio <= pDtInicialApuracao THEN
               pDtInicialApuracao
             ELSE
               HJT.DtInicio
           END AS DtInicioApuracao,
           CASE
             WHEN HJT.DtFim >= pDtFinalApuracao OR
                  HJT.DtFim IS NULL THEN
             pDtFinalApuracao
           ELSE
             HJT.DtFim
           END AS DtFimApuracao,
           CASE WHEN HFJ.CdHomologFreqJornada IS NULL THEN
             PKGPAG_TIPO.cnN
           ELSE
             PKGPAG_TIPO.cnS
           END AS FlFreqJornadaHomologada
          FROM ECadHistJornadaTrabalho HJT
         INNER JOIN ECadLocalTrabalho LT
            ON HJT.CdLocalTrabalho = LT.CdLocalTrabalho
          LEFT JOIN EMovHomologFreqJornada HFJ
            ON HFJ.CdUnidadeOrganizacional = HFJ.CdUnidadeOrganizacional AND
               HFJ.CdApuracaoFrequencia = pCdApuracaoFrequencia
         WHERE LT.CdHistCargoEfetivo = pCdHistCargoEfetivo AND
               HJT.DtInicio <= pDtFinalApuracao AND
               (HJT.DtFim >= pDtInicialApuracao OR HJT.DtFim IS NULL) AND
               HJT.FlAnulado = PKGPAG_TIPO.cnN;

  CURSOR cHistEscala(pCdHistCargoEfetivo   IN INTEGER,
                     pCdApuracaoFrequencia IN INTEGER,
                     pDtInicialApuracao    IN DATE,
                     pDtFinalApuracao      IN DATE,
                     pCdTipoEscala         IN INTEGER DEFAULT NULL)  IS
    SELECT CdHistEscalaServico,
           CdUnidOrgEscala,
           CASE
             WHEN HES.DtInicial <= pDtInicialApuracao THEN
               pDtInicialApuracao
             ELSE
               HES.DtInicial
           END AS DtInicioApuracao,
           CASE
             WHEN HES.DtFinal >= pDtFinalApuracao OR
                  HES.DtFinal IS NULL THEN
               pDtFinalApuracao
           ELSE
             HES.DtFinal
           END AS DtFimApuracao,
           CASE WHEN HFE.CdHomologFreqEscala IS NULL THEN
             'N'
           ELSE
             'S'
           END AS FlFreqEscalaHomologada
          FROM EMovHistEscalaServico HES
         INNER JOIN ECadLocalTrabalho LT
            --9056
            --ON HES.CdLocalTrabalho = LT.CdLocalTrabalho
            ON HES.CdVinculo = LT.CdVinculo
         INNER JOIN EMovModeloEscalaServico MES
            ON HES.CdModeloEscalaServico = MES.CdModeloEscalaServico
         INNER JOIN EMOVORGAOESCALA oe
            ON oe.CdOrgao = PKGPAG_VAR.vgCdOrgaoVinculo
           AND oe.DTINICIOVIGENCIA <= pDtInicialApuracao
           AND (oe.DTFIMVIGENCIA >= pDtInicialApuracao OR oe.DTFIMVIGENCIA IS NULL)
          LEFT JOIN EMovEmpregoEscalaServico EES
            ON HES.CdEmpregoEscalaServico = EES.CdEmpregoEscalaServico
          LEFT JOIN EMovHomologFreqEscala HFE
            ON HFE.CdUnidadeOrganizacional = HES.CdUnidOrgEscala AND
               HFE.CdApuracaoFrequencia = pCdApuracaoFrequencia
         WHERE LT.CdHistCargoEfetivo = pCdHistCargoEfetivo AND
               HES.DtInicial <= pDtFinalApuracao AND
               (MES.CdTipoEscala = pCdTipoEscala OR pCdTipoEscala IS NULL) AND
               (HES.DtFinal >= pDtInicialApuracao OR HES.DtFinal IS NULL) AND
               (oe.FlAdicionalNoturno = 'S' OR EES.FlAdicionalNoturno = 'S') ;

/*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Inicializar variaveis globais deste pacote quando da mudanca de vinculo
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PInicializaVinculo IS

BEGIN

    vgPercentRegenciaClasse      := NULL;
  vgPercentRegenciaClasseSub   := NULL;
    vgAulaExcedente              := NULL;
    vgDiasRegencia               := NULL;
    vgGratifAtivEsp              := NULL;
    vgDescFormula                := NULL;
    vgTemRegenciaUltDiaMes       := FALSE;

END;

FUNCTION FTipoHoraAulaAtividade(pCdVinculo    IN INTEGER,
                                pDtInicioMes  IN DATE,
                                pDtFimMes     IN DATE)

 RETURN INTEGER IS

 vInTipoPagamento INTEGER;

BEGIN

  SELECT InTipoPagamento
    INTO vInTipoPagamento
    FROM ECadHistHoraAulaAtividade HA
   WHERE HA.CdVinculo = pCdVinculo AND
         HA.FlAnulado = PKGPAG_TIPO.cnN AND
         HA.DtInicio <= pDtFimMes AND
         (HA.DtFim >= pDtInicioMes OR HA.DtFim IS NULL) AND
          ROWNUM < 2;

  RETURN vInTipoPagamento;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN 0;

END;

FUNCTION FRetornUnidOrgApo(pCdVinculo    IN INTEGER,
                                                       pDtInicioMes  IN DATE,
                                                       pDtFimMes    IN DATE)

 RETURN INTEGER IS

 vcdunidadeorganizacionalAPO INTEGER;

BEGIN

  select con.cdunidadeorganizacional
    into vcdunidadeorganizacionalAPO
    from EPVDCONCESSAOAPOSENTADORIA con
   WHERE con.cdvinculo = pCdVinculo
   and con.flanulado = 'N'
     and con.dtinicioaposentadoria <= pDtFimMes
     and (con.dtfimaposentadoria >= pDtInicioMes OR
         con.dtfimaposentadoria IS NULL)
  and rownum < 2
   ORDER BY con.dtfimaposentadoria DESC;

  RETURN vcdunidadeorganizacionalAPO;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN null;

END;

FUNCTION FPercentualRegencia(pCdHistCargoEfetivo    IN INTEGER,
                             pDtInicioMes   IN DATE,
                             pDtFimMes      IN DATE)

   RETURN INTEGER IS

   vPercentual INTEGER :=0;

BEGIN

     SELECT CASE
            WHEN D.INMODALIDADE = 1 THEN
              25
            ELSE
              40
            END AS PercentRegencia
     INTO vPercentual
     FROM EcadEnturmacao E
     INNER JOIN Ecaddisciplinaareaensino DA
             ON DA.CdDisciplinaAreaEnsino = E.CdDisciplinaAreaEnsino
     INNER JOIN ECadDisciplina D
             ON D.CdDisciplina = DA.CdDisciplina
     INNER JOIN ECadAreaEnsino A
             ON A.CdAreaEnsino = DA.CdAreaEnsino
     INNER JOIN VCadUOUltimaVigencia UO
             ON UO.CdUnidadeOrganizacional = E.CdUnidadeOrganizacional
     INNER JOIN ecadhistcargoefetivo cef
             ON cef.cdhistcargoefetivo = E.Cdhistcargoefetivo
     WHERE e.CdHistCargoEfetivo = pCdHistCargoEfetivo
        AND E.FlEmExercicio = 'S' -- So paga Exercicio S
        AND e.Dtiniciovigencia <= pDtFimMes
        AND (e.DtFimvigencia >= pDtInicioMes OR e.DtFimvigencia IS NULL)
        AND e.FLANULADO = 'N'
        AND ( uo.CDORGAO <> 42 OR -- SED e outros
              ( uo.CDORGAO = 42 AND cef.cdregimetrabalho = 2 ) OR -- FCCE Estatutario
              ( uo.CDORGAO = 42 AND cef.cdregimetrabalho = 3 AND d.cddisciplinasirh IN (005, 2841, 2472, 1155, 2837, 2838, 2839, 2840) ) -- FCEE ACT
            )
      AND ROWNUM < 2;

      RETURN vPercentual;

    EXCEPTION

       WHEN NO_DATA_FOUND
         THEN

         RETURN 0;

       WHEN OTHERS
         THEN
           RETURN 0;

End;

FUNCTION FVerificaUnidOrgCEF(pCdHistCargoEfetivo    IN INTEGER,
                                                        pDtInicioMes   IN DATE,
                                                        pDtFimMes      IN DATE)

 RETURN CHAR IS

 flUnidOrgEscolaCEF CHAR(1);

BEGIN

  select tuo.flescola
    into flUnidOrgEscolaCEF
    from ecadhistcargoefetivo cef
   inner join ecadlocaltrabalho lt
      on cef.cdvinculo = lt.cdvinculo
   INNER JOIN ecadhistunidadeorganizacional huo
      ON lt.cdunidadeorganizacional = huo.cdunidadeorganizacional
   inner JOIN ecadtipounidorg tuo
      ON huo.cdtipounidorg = tuo.cdtipounidorg
   where cef.cdhistcargoefetivo = pCdHistCargoEfetivo
     and lt.flanulado = 'N'
     and lt.dtinicio <= pDtFimMes
     and (lt.dtfim >= pDtInicioMes OR lt.DtFim IS NULL)
     and rownum < 2
   ORDER BY lt.dtfim DESC;

  RETURN flUnidOrgEscolaCEF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN null;

END;

FUNCTION FPossuiIndiceUnidEscolar( pCEF          IN PKGPAG_TIPO.rCEF DEFAULT NULL,
                                   pAPO                      IN PKGPAG_TIPO.rCEF DEFAULT NULL,
                                   pCCO                     IN PKGPAG_TIPO.rCCO DEFAULT NULL,
                                   pDtCalculo              IN DATE,
                                   pDtInicioMes           IN DATE,
                                   pDtFimMes             IN DATE)

  RETURN BOOLEAN IS

  vlIndiceUnidEscolar CHAR;
  vCdUniOrgAposentado INTEGER;

BEGIN

-- Se for comissionado, retorna falso
IF pCCO.CdHistCargoCom IS NOT NULL THEN
    RETURN FALSE;

ELSIF pAPO.CdHistRelVinc IS NOT NULL THEN

     vCdUniOrgAposentado := FRetornUnidOrgApo(pAPO.CdVinculo,
                                                                                  pDtInicioMes,
                                                                                  pDtFimMes);

      --Utiliza o codigo da unidade organizacional cadastrada na tabela EPVDCONCESSAOAPOSENTADORIA
     IF vCdUniOrgAposentado IS NOT NULL
       THEN

          SELECT tuo.flescola
            INTO vlIndiceUnidEscolar
            FROM ecadlocaltrabalho lt
           INNER JOIN ecadhistunidadeorganizacional huo
              ON lt.cdunidadeorganizacional = huo.cdunidadeorganizacional
            LEFT JOIN ecadtipounidorg tuo
              ON huo.cdtipounidorg = tuo.cdtipounidorg
           WHERE lt.cdunidadeorganizacional = vCdUniOrgAposentado
             AND lt.cdvinculo = pAPO.CdVinculo
             AND ROWNUM < 2
          ORDER BY lt.dtfim DESC;

    ELSE --Caso nao haja UO cadastrada na tabela EPVDCONCESSAOAPOSENTADORIA

   SELECT tuo.flescola
     INTO vlIndiceUnidEscolar
     FROM ecadlocaltrabalho lt
    INNER JOIN ecadhistunidadeorganizacional huo
       ON lt.cdunidadeorganizacional = huo.cdunidadeorganizacional
     LEFT JOIN ecadtipounidorg tuo
       ON huo.cdtipounidorg = tuo.cdtipounidorg
    WHERE lt.cdvinculo = pCEF.CdVinculo
      AND lt.flanulado = 'N'
      and lt.dtinicio <= pDtFimMes
      and (lt.dtfim >= pDtInicioMes OR lt.DtFim IS NULL)
      and ROWNUM < 2
    ORDER BY lt.dtfim DESC;

     END IF;

ELSIF pCEF.CdHistRelVinc IS NOT NULL THEN

  --  Verifica dentro do mes se o CDHISTCARGOEFETIVO  teve algum dia de local de trabalho
  -- em unidade organizacional do tipo ESCOLA.
  vlIndiceUnidEscolar := FVerificaUnidOrgCEF(pCEF.CdHistCargoEfetivo,
                                                                            pDtInicioMes,
                                                                            pDtFimMes);
  IF vlIndiceUnidEscolar is not null
   AND vlIndiceUnidEscolar = 'S' THEN
        RETURN TRUE;

  ELSE

   SELECT flescola
     INTO vlIndiceUnidEscolar
     FROM (SELECT tuo.flescola
             FROM ecadlocaltrabalho lt
            INNER JOIN ecadhistunidadeorganizacional huo
               ON lt.cdunidadeorganizacional = huo.cdunidadeorganizacional
             LEFT JOIN ecadtipounidorg tuo
               ON huo.cdtipounidorg = tuo.cdtipounidorg
            WHERE lt.cdvinculo = pCEF.CdVinculo
              AND lt.flanulado = 'N'
              and lt.dtinicio <= pDtFimMes
              and (lt.dtfim >= pDtInicioMes OR lt.DtFim IS NULL)
            ORDER BY lt.dtfim DESC)
    WHERE ROWNUM = 1;

  END IF;

ELSE
  NULL;
END IF;

     IF vlIndiceUnidEscolar = 'S' THEN
        RETURN TRUE;
     ELSE
          RETURN FALSE;
     END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

END;

FUNCTION FAplicarAbrangenciaParcialCCO(pCdTipoAtipratFaz      IN INTEGER,
                                                                           pFolha     IN PKGPAG_TIPO.rFolha )

  RETURN BOOLEAN IS

   vAplicaAbrangenciaParcialCCO CHAR;

BEGIN

    SELECT  HAF.flaplicaabrangenciaparcialcco
          INTO vAplicaAbrangenciaParcialCCO
        FROM  EPagGratAtivFazendaria AF
       INNER JOIN EpagHistGratAtivFazendaria HAF
             ON AF.CdGratAtivFazendaria = HAF.CdGratAtivFazendaria
       INNER JOIN vcadorgaoultimavigencia o
             ON o.cdagrupamento = af.cdagrupamento
     WHERE o.cdOrgao IN(41, 42) AND
                    AF.CdTipoGratAtivFazendaria = pCdTipoAtipratFaz AND
                    ((HAF.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                    (HAF.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                    HAF.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                    AND
                    (HAF.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                    (HAF.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                    HAF.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                    HAF.NuMesFimVigencia IS NULL));

     IF vAplicaAbrangenciaParcialCCO = 'S' THEN
        RETURN TRUE;
     ELSE
          RETURN FALSE;
     END IF;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

END;

PROCEDURE PMediaCHOHoraAtiv(pInTipoHoraAulaAtiv IN INTEGER,
                            pCdVinculo          IN INTEGER,
                            pDtInicioMes        IN DATE,
                            pDtFimMes           IN DATE,
                            pDtFimRelacao       IN DATE) IS

  vQtHoras     INTEGER := 0;

  vNuDiasTotal INTEGER := 0;

  FUNCTION FRetornaHora(pQtHoras  IN INTEGER)

    RETURN INTEGER IS

  BEGIN

    IF pInTipoHoraAulaAtiv = 2 THEN

      CASE

        WHEN pQtHoras BETWEEN 1 AND 7 THEN

          RETURN 10;

        WHEN pQtHoras BETWEEN 8 AND 12 THEN

          RETURN 20;

        WHEN pQtHoras BETWEEN 13 AND 17 THEN

          RETURN 30;

        WHEN pQtHoras >= 18 THEN

          RETURN 40;

       ELSE

         RETURN 0;

       END CASE;

    ELSE

      RETURN pQtHoras;

    END IF;

  END;

BEGIN

  FOR vRec IN ( SELECT CASE
                       WHEN HA.DtInicio < pDtInicioMes THEN
                         pDtInicioMes
                       ELSE
                         HA.DtInicio
                       END DtInicio,
                       CASE
                         WHEN pDtFimRelacao < pDtFimMes THEN
                           pDtFimRelacao
                         WHEN HA.DtFim > pDtFimMes OR HA.DtFim IS NULL THEN
                           pDtFimMes
                       ELSE
                         HA.DtFim
                      END DtFim,
                      HA.QtHorasMensal
                 FROM ECadHistHoraAulaAtividade HA
                WHERE HA.CdVinculo = pCdVinculo AND
                      HA.InTipoPagamento = pInTipoHoraAulaAtiv AND
                      HA.FlAnulado = PKGPAG_TIPO.cnN AND
                      HA.DtInicio <= pDtFimMes AND
                      (HA.DtFim >= pDtInicioMes OR HA.DtFim IS NULL)
                ORDER BY HA.DtInicio)
  LOOP

    vNuDiasTotal := vNuDiasTotal + (vRec.DtFim - vRec.DtInicio + 1);

    IF vNuDiasTotal > 30 THEN

      vNuDiasTotal := 30;

    END IF;

    vQtHoras := vQtHoras + FRetornaHora(PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal))*LEAST(vRec.DtFim - vRec.DtInicio + 1,30);

  END LOOP;

  PKGPAG_VAR.vgMediaCHOHoraAtividade := vQtHoras/vNuDiasTotal;

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

/*-----------------------------------------------------------------------------------------
-- Procedure: pProcessaRemuneracaoFixaCEF
--  Objetivo: Gera a remuneracao fixa para cargos efetivos
--
/*-----------------------------------------------------------------------------------------*/
PROCEDURE P001RemuneracaoFixaCEF(pFolha     IN PKGPAG_TIPO.rFolha,
                                 pCEF       IN PKGPAG_TIPO.rCEF,
                                 pRubrica   IN PKGPAG_TIPO.rRubrica,
                                 pDtCalculo IN DATE) IS

 CURSOR cHNR(pCdHistRelVinc INTEGER,
             pDtInicioMes   DATE,
             pDtFimMes      DATE) IS
    SELECT HNR.NuNivelPagamento,
           HNR.NuReferenciaPagamento,
           CASE
             WHEN HNR.DtInicio < pDtInicioMes THEN
               pDtInicioMes
           ELSE
             HNR.DtInicio
           END AS DtInicio,
           CASE
             WHEN HNR.DtFim > pDtFimMes OR
                  HNR.DtFim IS NULL OR
                  pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao  THEN
               pDtFimMes
            ELSE
              HNR.DtFim
          END AS DtFim,
          EC.CDESTRUTURACARREIRA,
          EC.CDESTRUTURACARREIRACARREIRA,
          CEF.CDORGAOEXERCICIO
     FROM ECadHistNivelRefCEF HNR
     INNER JOIN ECADHISTCARGOEFETIVO CEF ON HNR.CDHISTCARGOEFETIVO = CEF.CDHISTCARGOEFETIVO
     INNER JOIN ECADESTRUTURACARREIRA EC ON EC.CDESTRUTURACARREIRA = CEF.CDESTRUTURACARREIRA
    WHERE HNR.CdHistCargoEfetivo = pCdHistRelVinc AND
          HNR.FlAnulado = PKGPAG_TIPO.cnN AND
          (
             (HNR.DtInicio <= pdtFimMes) AND
             (HNR.DtFim >= pdtInicioMes OR
                (
                    -- SE HOUVER 2 PERIODOS ABERTOS OU FOR FOLHA DE INSTIRUIDOR, BUSCA APENAS 0 ULTIMO PERIODO
                     HNR.dtInicio = (SELECT MAX(HNR2.dtInicio)
                                       FROM   ECadHistNivelRefCEF HNR2
                                       WHERE HNR2.CdHistCargoEfetivo = HNR.CdHistCargoEfetivo AND
                                             HNR2.FlAnulado = PKGPAG_TIPO.cnN AND
                                             (HNR2.DtFim IS NULL OR pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao))
                )
             )
          )
    ORDER BY HNR.DtInicio;

   TYPE tHP                IS TABLE OF cHNR%ROWTYPE INDEX BY PLS_INTEGER;

   vHP                     tHP;
   vProporcional           PKGPAG_TIPO.rValorPagamento;
   vProporcionalAcum       PKGPAG_TIPO.rValorPagamento;
   vCEF                    PKGPAG_TIPO.rCEF;
   bMesInteiro             BOOLEAN := FALSE;
   bPossuiNivelReferencia  BOOLEAN := FALSE;
   j                       INTEGER := 0;
   vVlIndiceAnt            INTEGER := 0;
   vVlIndice               INTEGER := 0;
   vInTipoHoraAulaAtiv     INTEGER;
   vCdEstruturaCarreiraOrigem INTEGER;

   vDiasIntegral           INTEGER;
   vDiasAux                INTEGER;
   vDiaIntegralIni         DATE;
   vvldecisaoJud           NUMBER;
   vcdvalorrefDecJud       INTEGER;
   vdtiniciodireitoDecJud  DATE;
   vDtInclusaoDecJud       DATE;
   --vDiaIntegralFim         DATE;
   --vNuDiasUteis            INTEGER;
   --vVlBonus                PKGPAG_TIPO.rValorPagamento;
   --vNuNivel                varchar2(2);
   --vNuReferencia           varchar2(1);
   --vNuDiasUteisTrab        INTEGER;

BEGIN

   -- Se nao gera rubrica, retorna
   IF NOT PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN
     --
     -- Verifica se tem LF para carregar o valor informado
     --
     IF pkgpag_geral.fpossuilancfinanceiro(pkgpag_var.vgVinculo.CdVinculo,
                                           pFolha,
                                           pRubrica.CdRubricaAgrupamento)
       THEN

        j := 0;

     END IF;
     RETURN;
   END IF;

   IF pkgpag_geral.fpossuidecisaojudicial(pkgpag_var.vgVinculo.cdvinculo,
                                          pFolha.nuanoreferencia,
                                          pFolha.numesreferencia,
                                          pRubrica.CdRubricaAgrupamento,
                                          vvldecisaoJud,
                                          vcdvalorrefDecJud,
                                          vdtiniciodireitoDecJud,
                                          vDtInclusaoDecJud) THEN

     RETURN;
   END IF;

   vProporcionalAcum.vlIntegral     := 0;

   vProporcionalAcum.vlProporcional := 0;

   vProporcionalAcum.vlReal         := 0;

   vProporcionalAcum.vlIndice       := 0;

   PKGPAG_VAR.bVinculoComCEF        := TRUE;

   vCEF                             := pCEF;

   PKGPAG_VAR.vgFixoCEF             := PKGPAG_TIPO.tFixoCEF ();

   FOR vRec IN cHNR(vCEF.CdHistRelVinc,
                    pFolha.DtInicioMes,
                    pFolha.DtFimMes)
   LOOP

     bPossuiNivelReferencia  := TRUE;

     j:= j + 1;

     vHP(j) := vRec;

     vVlIndice := vVlIndice + (vHP(j).DtFim - vHP(j).DtInicio + 1);

     IF vvlIndice > 30 AND vvlIndiceAnt > 0 THEN

       vHP(j).DtFim := vRec.DtFim - 1;

     END IF;

     vvlIndiceAnt := vvlIndice;

   END LOOP;

   IF bPossuiNivelReferencia THEN

     vDiasIntegral := 30;

     FOR i IN vHP.FIRST .. vHP.LAST
     LOOP

       /*Atualiza as datas de inicio e fim da progressao na variavel vCEF para
         utilizacao no calculo da proporcionalidade da carga horaria       */

      IF NOT bMesInteiro THEN

      -- Verificacao para evitar de pagar a maior quando existem duas vigencias
      -- abertas por problema de migracao de dados

        IF (vHP(i).DtInicio = pFolha.dtInicioMes AND
            vHP(i).DtFim = pFolha.dtFimMes) THEN

          bMesInteiro := TRUE;

        END IF;

        vCEF.DtInicio := vHP(i).DtInicio;

        ----------------------------------------------------------------------
        -- Mega-pog
        -- Se a variavel bSemIntersticio = TRUE (setada quando o vinculo possui
        -- duas relacoes de cargo efetivo dentro do mes sem intervalo)
        -- e a data fim do historico = 31 assume-se a data fim como = 30
        ----------------------------------------------------------------------
        IF PKGPAG_VAR.bSemIntersticio AND TO_CHAR(vHP(i).DtFim,'DD') = 31 THEN

          vCEF.DtFim    := vHP(i).DtFim - 1;

        ELSE

          vCEF.DtFim    := vHP(i).DtFim;

          IF PKGPAG_VAR.vgAPO.Count > 0
            THEN

            IF PKGPAG_Var.vgApo(1).DtInicio = vCEF.DtFim
             THEN
               vCEF.DtFim := PKGPAG_Var.vgApo(1).DtInicio - 1;

            --
            -- Solicitacao de Sustentacao #77383
            -- SEA - FOLHA - 10727/2017 - pagamento de 31 dias da rubrica 01-0001
            --
            ELSIF PKGPAG_Var.vgApo(1).DtFim = vCEF.DtInicio -1
              AND pkgpag_var.vgapo(1).DtInicio = pFolha.DtInicioMes
              AND vcef.DtFim = pFolha.DtFimMes
              AND to_char(vCef.DtFim,'dd') = 31

              THEN

               vCef.DtFim :=  vCef.DtFim - 1;

            ELSE

              vCEF.DtFim  := vHP(i).DtFim;

            END IF;
          END IF;

        END IF;
        ----------------------------------------------------------------------

        ----------------------------------------------------------------------
        -- Mega-pog II
        -- Se for agrupamento Defensoria Publica verificar se teve movimentacao
        -- do cargo efetivo na carreira no periodo, ja que para este orgao a progressao
        -- altera a carreira e o cargo e nestes casos o calculo so faz para a ultima e nao encontra
        -- o valor do cargo efetivo na tabela. Implementar posteriormente melhoria
        -- Incluido orgao 17 para o agrupamento 1 para tratar os casos de promocao a partir do
        -- dia 05/01/2015, ja que nao existe historico de cargo efetivo
        ----------------------------------------------------------------------

        IF (PKGPAG_VAR.vgFolha.CdAgrupamento IN (176, 1)) --OR
           -- (PKGPAG_VAR.vgFolha.CdAgrupamento = 1 AND vHP(i).cdOrgaoExercicio <> pFOlha.CdOrgao ))-- and PKGPAG_VAR.vgFolha.CdOrgao = 17))

          THEN

            vCdEstruturaCarreiraOrigem := vHP(i).CdEstruturaCarreira;

            BEGIN
            SELECT EMC.CDESTRUTURACARREIRAORIGEM
              INTO vCdEstruturaCarreiraOrigem
              FROM EMOVMOVCARGOEFETIVO EMC
             INNER JOIN EMOVMOVCARGOEFETIVOVINC EMV
                ON EMV.CDMOVCARGOEFETIVO = EMC.CDMOVCARGOEFETIVO
               AND EMV.CDVINCULO = vCef.CdVinculo
               AND EMC.FLANULADO = 'N'
               AND EMC.DTMOVIMENTACAO >  vHP(i).DtFim
               AND EMC.DTMOVIMENTACAO <= pFolha.DtFimMes;

            EXCEPTION

            WHEN OTHERS
              THEN
                vCdEstruturaCarreiraOrigem := vHP(i).CdEstruturaCarreira;

            END;

            PKGPAG_VAR.vgValorFixoCEF :=

            PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                           pFolha.CdOrgao,
                                           pFolha.NuVersaoTabcef,
                                           pFolha.NuAnoReferencia,
                                           pFolha.NuMesReferencia,
                                           vCdEstruturaCarreiraOrigem,
                                           vHP(i).CdEstruturaCarreiraCarreira,
                                           vHP(i).NuNivelPagamento,
                                           vHP(i).NuReferenciaPagamento);
        ELSE

            PKGPAG_VAR.vgValorFixoCEF :=

            PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                         pFolha.CdOrgao,
                                         pFolha.NuVersaoTabcef,
                                         pFolha.NuAnoReferencia,
                                         pFolha.NuMesReferencia,
                                         vCef.CdEstruturaCarreira, --vHP(i).CdEstruturaCarreira,
                                         vCef.CdEstruturaCarreiraCarreira, --vHP(i).CdEstruturaCarreiraCarreira,
                                         vHP(i).NuNivelPagamento,
                                         vHP(i).NuReferenciaPagamento);

        END IF;

        -- Alimenta vetor de Valor Fixo de CEF por periodo

        PKGPAG_VAR.vgFixoCEF.EXTEND;

        PKGPAG_VAR.vgFixoCEF (PKGPAG_VAR.vgFixoCEF.LAST).DtInicio := vHP(i).DtInicio;
        PKGPAG_VAR.vgFixoCEF (PKGPAG_VAR.vgFixoCEF.LAST).DtFim    := vCEF.DtFim;
        PKGPAG_VAR.vgFixoCEF (PKGPAG_VAR.vgFixoCEF.LAST).VlFixo   := PKGPAG_VAR.vgValorFixoCEF;

        IF vHp(i).DtFim < pFolha.DtFimMes
          AND PKGPAG_VAR.vgValorFixoCEFAnt.VlIntegral IS NULL
          THEN

           PKGPAG_VAR.vgDtInicioCefAnt := vHP(i).DtInicio;
           PKGPAG_VAR.vgDtFimCefAnt := vHP(I).DtFim;
           PKGPAG_VAR.vgValorFixoCEFAnt.VlIntegral := pkgpag_var.vgValorFixoCEF.VlFixo;
           PKGPAG_VAR.vgValorFixoCEFAnt.VlIndice := vHP(i).DtFim - vHP(i).DtInicio + 1;

        END IF;
        ---------------------------------------------------------------------------
        -- Alteracao para atender UDESC
        ---------------------------------------------------------------------------

        IF PKGPAG_VAR.bPossuiEventoHoraAulaAtiv THEN

         -----------------------------------------------------------------------------
         -- Caso o orgao possua evento de hora aula/atividade, verifica se o servidor
         -- possui registros de hora aula/atividade vigentes
         -----------------------------------------------------------------------------

         vInTipoHoraAulaAtiv := FTipoHoraAulaAtividade(vCEF.CdVinculo,
                                                       pFolha.DtInicioMes,
                                                       pFolha.DtFimMes);

         -------------------------------------------------------------------
         -- Caso possua, ira realizar o pagamento via eventos 65 e 66
         -------------------------------------------------------------------

         IF vInTipoHoraAulaAtiv IN (1,2) THEN

          --------------------------------------------------------------------
          -- Se o servidor possuir hora atividade ou hora aula, ira alimentar a variavel
          -- PKGPAG_VAR.vgMediaCHOHoraAtiv
          --------------------------------------------------------------------

          --IF vInTipoHoraAulaAtiv = 2 THEN

            PMediaCHOHoraAtiv(pInTipoHoraAulaAtiv => vInTipoHoraAulaAtiv,
                              pCdVinculo          => vCEF.CdVinculo,
                              pDtInicioMes        => pFolha.DtInicioMes,
                              pDtFimMes           => pFolha.DtFimMes,
                              pDtFimRelacao       => vCEF.DtFim);

          --END IF;

          RETURN;

        END IF;

      ELSIF PKGPAG_VAR.vPagaSitDisposicao = 'PAG-DISP-ONUS-ORIGEM' THEN

       RETURN;

      else
        null;
      END IF;

      IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

          IF PKGPAG_VAR.vgValorFixoCEF.vlFixo IS NOT NULL THEN

            -- Pagamento integral de salario para
            -- disposicao finalizada ou iniciada no mes.
            -- Integralizar somente para quem tem um cargo efetivo
            IF PKGPAG_GERAL.FDisposicaoParcialNoMes(vCEF, pFolha) and
          pkgpag_var.vgCef.Count = 1 THEN

              IF  PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria = vCEF.NuCargaHoraria OR
                  pRubrica.CdRubProporcionalidadeCHO = 1 THEN

                 vProporcional.VlIntegral     := PKGPAG_VAR.vgValorFixoCEF.vlFixo;

              ELSE

                 vProporcional.VlIntegral     := PKGPAG_VAR.vgValorFixoCEF.vlFixo /
                                                 PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria *
                                                 vCEF.NuCargaHoraria;

              END IF;

              vProporcional.VlProporcional := vProporcional.VlIntegral;

              vProporcional.VlReal         := vProporcional.VlIntegral;

              vProporcional.VlIndice       := 30;

            ELSE

              vProporcional :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                       pRubrica           => pRubrica ,
                                                                       pValorIntegral     => PKGPAG_VAR.vgValorFixoCEF.VlFixo,
                                                                       pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                       pCEF               => vCEF,
                                                                       pDtCalculo         => pDtCalculo,
                                                                       pEventoCEF         => PKGPAG_TIPO.cnS);

            END IF;

            vProporcionalAcum.vlIndice       := vProporcionalAcum.vlIndice + vProporcional.vlIndice;

            vProporcionalAcum.vlIntegral     := vProporcionalAcum.vlIntegral + vProporcional.vlIntegral;

            vProporcionalAcum.vlProporcional := vProporcionalAcum.vlProporcional + vProporcional.vlProporcional;

        END IF;

      END IF;

      -- Calcular valor integral proporcionalizado

     IF vDiasIntegral = 30 THEN -- Primeira Vez
        -- Para demitidos no mes forcar a data inicio primeiro dia do mes e nao do inicio da relacao.
        -- caso tenha iniciado depois do inicio do mes e demitido no mes para calcular as verbas rescisorias
        -- corretamente
        IF vCef.DtInicio > pFolha.DtInicioMes and vCef.DtFim <= pFolha.DtFimMes
          THEN
             vDiaIntegralIni:= pFolha.DtInicioMes;
          ELSE
            vDiaIntegralIni := vCEF.DtInicio; -- Salario sera calculado como iniciado no dia 01, mesmo que comecado depois
        END IF;

      END IF;

      IF i = vHP.LAST THEN -- ULtima ocorrencia de data, calcula ate o fim do mes

        vDiasAux := PKGPAG_GERAL.FRetornaIndice (pFlPropMesComercial => 'S',
                                                 pDtInicioMes        => pFolha.DtInicioMes,
                                                 pDtFimMes           => pFolha.DtFimMes,
                                                 pDtInicio           => vDiaIntegralIni,
                                                 pDtFim              => pFolha.DtFimMes );

      ELSE

        vDiasAux := PKGPAG_GERAL.FRetornaIndice (pFlPropMesComercial => 'S',
                                                 pDtInicioMes        => pFolha.DtInicioMes,
                                                 pDtFimMes           => pFolha.DtFimMes,
                                                 pDtInicio           => vDiaIntegralIni,
                                                 pDtFim              => vCEF.DtFim );
      END IF;

      IF vDiasAux > vDiasIntegral THEN
         vDiasAux := vDiasIntegral;
      END IF;

      vDiasIntegral := vDiasIntegral - vDiasAux;

      vProporcionalAcum.vlReal         := vProporcionalAcum.vlReal + (vDiasAux / 30 ) * vProporcional.vlReal;

      vDiaIntegralIni := vCEF.DtFim + 1; -- Indica o proximo dia do proximo periodo

     END IF;

    END LOOP;

  ELSE

     PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vCdHistParamCalc,
                                PKGPAG_VAR.vCdPessoa,
                                'Histórico de Nível/Referencia do cargo efetivo não está definido.',
                                PKGPAG_VAR.vgCdVinculo);

  END IF;

  IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

    IF PKGPAG_VAR.vgVlPercentReducao > 0 THEN
      -- Se usar reducao, verificar pois parece que a rotina de proporcionalidade ja faz este passo

      vProporcionalAcum.vlIntegral     :=

        vProporcionalAcum.vlIntegral*(100-PKGPAG_VAR.vgVlPercentReducao)/100;

      vProporcionalAcum.vlProporcional :=

        vProporcionalAcum.vlProporcional*(100-PKGPAG_VAR.vgVlPercentReducao)/100;

      vProporcionalAcum.vlReal :=

        vProporcionalAcum.vlReal*(100-PKGPAG_VAR.vgVlPercentReducao)/100;

    END IF;

    -- vProporcional.vlReal contem ultimo salario do mes

    PKGPAG_GERAL.PAtualizaHistCEF(pFolha,
                                  pRubrica,
                                  vCEF,
                                  vProporcionalAcum.vlIntegral,
                                  vProporcionalAcum.vlProporcional,
                                  vProporcionalAcum.vlReal,
                                  vProporcionalAcum.vlIndice);
  END IF;

END;
/*--------- FABIO - REAJUSTE PROPORCIONAL UDESC ----------------------------------*/
PROCEDURE P001RemuneracaoFixaCEFUDESC(pFolha     IN PKGPAG_TIPO.rFolha,
                                 pCEF       IN PKGPAG_TIPO.rCEF,
                                 pRubrica   IN PKGPAG_TIPO.rRubrica,
                                 pDtCalculo IN DATE) IS

 CURSOR cHNR(pCdHistRelVinc INTEGER,
             pDtInicioMes   DATE,
             pDtFimMes      DATE) IS
    SELECT HNR.NuNivelPagamento,
           HNR.NuReferenciaPagamento,
           CASE
             WHEN HNR.DtInicio < pDtInicioMes THEN
               pDtInicioMes
           ELSE
             HNR.DtInicio
           END AS DtInicio,
           CASE
             WHEN HNR.DtFim > pDtFimMes OR HNR.DtFim IS NULL THEN
               pDtFimMes
            ELSE
              HNR.DtFim
          END AS DtFim,
          EC.CDESTRUTURACARREIRA,
          EC.CDESTRUTURACARREIRACARREIRA
     FROM ECadHistNivelRefCEF HNR
     INNER JOIN ECADHISTCARGOEFETIVO CEF ON HNR.CDHISTCARGOEFETIVO = CEF.CDHISTCARGOEFETIVO
     INNER JOIN ECADESTRUTURACARREIRA EC ON EC.CDESTRUTURACARREIRA = CEF.CDESTRUTURACARREIRA
    WHERE HNR.CdHistCargoEfetivo = pCdHistRelVinc AND
          HNR.FlAnulado = PKGPAG_TIPO.cnN AND
          (
             (HNR.DtInicio <= pdtFimMes) AND
             (HNR.DtFim >= pdtInicioMes OR
                (
                     HNR.dtFim IS NULL -- SE HOUVER 2 PERIODOS ABERTOS, BUSCA APENAS 0 ULTIMO PERIODO
                     AND HNR.dtInicio = (SELECT MAX(HNR2.dtInicio)
                                         FROM   ECadHistNivelRefCEF HNR2
                                         WHERE HNR2.CdHistCargoEfetivo = pCdHistRelVinc AND
                                               HNR2.FlAnulado = PKGPAG_TIPO.cnN AND
                                               HNR2.DtFim IS NULL )
                )
             )
          )
    ORDER BY HNR.DtInicio;

   TYPE tHP                IS TABLE OF cHNR%ROWTYPE INDEX BY PLS_INTEGER;

   vHP                     tHP;
   vProporcional           PKGPAG_TIPO.rValorPagamento;
   vProporcionalAcum       PKGPAG_TIPO.rValorPagamento;
   vCEF                    PKGPAG_TIPO.rCEF;
   bMesInteiro             BOOLEAN := FALSE;
   bPossuiNivelReferencia  BOOLEAN := FALSE;
   j                       INTEGER := 0;
   vVlIndiceAnt            INTEGER := 0;
   vVlIndice               INTEGER := 0;
   vInTipoHoraAulaAtiv     INTEGER;
   vCdEstruturaCarreiraOrigem INTEGER;
  /*FABIO */
  vindex    integer;

BEGIN

   vProporcionalAcum.vlIntegral     := 0;

   vProporcionalAcum.vlProporcional := 0;

   vProporcionalAcum.vlIndice       := 0;

   PKGPAG_VAR.bVinculoComCEF        := TRUE;

   vCEF                             := pCEF;

  /*FABIO*/

   PKGPAG_VAR.vgFixoCEF             := PKGPAG_TIPO.tFixoCEF ();

   FOR vRec IN cHNR(vCEF.CdHistRelVinc,
                    pFolha.DtInicioMes,
                    pFolha.DtFimMes)
   LOOP

     bPossuiNivelReferencia  := TRUE;

     j:= j + 1;

     vVlIndice := vVlIndice + (vRec.DtFim -vRec.DtInicio + 1);

     vHP(j) := vRec;

     IF vvlIndice > 30 AND vvlIndiceAnt > 0 THEN

       vHP(j).DtFim := vRec.DtFim - 1;

     END IF;

     vvlIndiceAnt := vvlIndice;

   END LOOP;

   IF bPossuiNivelReferencia THEN

     FOR i IN vHP.FIRST .. vHP.LAST
     LOOP
/* FABIO */
FOR vindex in 1 .. 2
  LOOP

       /*Atualiza as datas de inicio e fim da progressao na variavel vCEF para
         utilizacao no calculo da proporcionalidade da carga horaria       */

      IF NOT bMesInteiro THEN

      -- Verificacao para evitar de pagar a maior quando existem duas vigencias
      -- abertas por problema de migracao de dados

        IF (vHP(i).DtInicio = pFolha.dtInicioMes AND
            vHP(i).DtFim = pFolha.dtFimMes) THEN

          bMesInteiro := TRUE;

        END IF;

        vCEF.DtInicio := vHP(i).DtInicio;

        ----------------------------------------------------------------------
        -- Mega-pog
        -- Se a variavel bSemIntersticio = TRUE (setada quando o vinculo possui
        -- duas relacoes de cargo efetivo dentro do mes sem intervalo)
        -- e a data fim do historico = 31 assume-se a data fim como = 30
        ----------------------------------------------------------------------
        IF PKGPAG_VAR.bSemIntersticio AND TO_CHAR(vHP(i).DtFim,'DD') = 31 THEN

          vCEF.DtFim    := vHP(i).DtFim - 1;

        ELSE

          vCEF.DtFim    := vHP(i).DtFim;

        END IF;
        ----------------------------------------------------------------------

/*FABIO*/

IF vindex = 1 THEN
 IF vCEF.DtFim > to_date('06/04/2014', 'DD/MM/YYYY') AND -- nao altera data fim para CEF finalizado ate dia 06
   vCEF.DtInicio < to_date('07/04/2014', 'DD/MM/YYYY') THEN  -- nao altera data fim para CEF iniciado depois do dia 06
  vCEF.DtFim := to_date('06/04/2014', 'DD/MM/YYYY'); -- calcula primeiros 6 dias do mes
 END IF;
ELSE
 IF vCEF.DtInicio < to_date('07/04/2014', 'DD/MM/YYYY') THEN -- nao altera data inicio para CEF iniciado apos dia 06
    vCEF.DtInicio := to_date('07/04/2014', 'DD/MM/YYYY');  -- calcula demais 24 dias do mes
 END IF;
END IF;

        ----------------------------------------------------------------------
        -- Mega-pog II
        -- Se for agrupamento Defensoria Publica verificar se teve movimentacao
        -- do cargo efetivo na carreira no periodo, ja que para este orgao a progressao
        -- altera a carreira e o cargo e nestes casos o calculo so faz para a ultima e nao encontra
        -- o valor do cargo efetivo na tabela. Implementar posteriormente melhoria
        ----------------------------------------------------------------------

        IF PKGPAG_VAR.vgFolha.CdAgrupamento = 176

          THEN

            vCdEstruturaCarreiraOrigem := vHP(i).CdEstruturaCarreira;

            BEGIN
            SELECT EMC.CDESTRUTURACARREIRAORIGEM
              INTO vCdEstruturaCarreiraOrigem
              FROM EMOVMOVCARGOEFETIVO EMC
             INNER JOIN EMOVMOVCARGOEFETIVOVINC EMV
                ON EMV.CDMOVCARGOEFETIVO = EMC.CDMOVCARGOEFETIVO
               AND EMV.CDVINCULO = vCef.CdVinculo
               AND EMC.FLANULADO = 'N'
               AND EMC.DTMOVIMENTACAO >  vHP(i).DtFim
               AND EMC.DTMOVIMENTACAO <= pFolha.DtFimMes;

            EXCEPTION

            WHEN OTHERS
              THEN
                vCdEstruturaCarreiraOrigem := vHP(i).CdEstruturaCarreira;

            END;

            PKGPAG_VAR.vgValorFixoCEF :=

            PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                           pFolha.CdOrgao,
                                           pFolha.NuVersaoTabcef,
                                           pFolha.NuAnoReferencia,
                                           pFolha.NuMesReferencia,
                                           vCdEstruturaCarreiraOrigem,
                                           vHP(i).CdEstruturaCarreiraCarreira,
                                           vHP(i).NuNivelPagamento,
                                           vHP(i).NuReferenciaPagamento);
        ELSE
            /* FABIO */ -- para calcular primeiros 6 dias
      IF vindex = 1 THEN
        PKGPAG_VAR.vgValorFixoCEF :=

        PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                        pFolha.CdOrgao,
                        pFolha.NuVersaoTabcef,
                        pFolha.NuAnoReferencia,
                        pFolha.NuMesReferencia - 1, /*FABIO*/ -- para pegar tabela salarial anterior
                        vHP(i).CdEstruturaCarreira,
                        vHP(i).CdEstruturaCarreiraCarreira,
                        vHP(i).NuNivelPagamento,
                        vHP(i).NuReferenciaPagamento);

         vgVLFixoCEF := PKGPAG_VAR.vgValorFixoCEF.VlFixo;

       ELSE /* FABIO */ -- para calcular demais 24 dias
       PKGPAG_VAR.vgValorFixoCEF :=

        PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                        pFolha.CdOrgao,
                        pFolha.NuVersaoTabcef,
                        pFolha.NuAnoReferencia,
                        pFolha.NuMesReferencia, /*FABIO*/ -- para pegar tabela salarial atual
                        vHP(i).CdEstruturaCarreira,
                        vHP(i).CdEstruturaCarreiraCarreira,
                        vHP(i).NuNivelPagamento,
                        vHP(i).NuReferenciaPagamento);
      END IF;

        END IF;

        -- Alimenta vetor de Valor Fixo de CEF por periodo

        PKGPAG_VAR.vgFixoCEF.EXTEND;

        PKGPAG_VAR.vgFixoCEF (PKGPAG_VAR.vgFixoCEF.LAST).DtInicio := vHP(i).DtInicio;
        PKGPAG_VAR.vgFixoCEF (PKGPAG_VAR.vgFixoCEF.LAST).DtFim    := vCEF.DtFim;
        PKGPAG_VAR.vgFixoCEF (PKGPAG_VAR.vgFixoCEF.LAST).VlFixo   := PKGPAG_VAR.vgValorFixoCEF;

        ---------------------------------------------------------------------------
        -- Alteracao para atender UDESC
        ---------------------------------------------------------------------------

        IF PKGPAG_VAR.bPossuiEventoHoraAulaAtiv THEN

      PKGPAG_VAR.vgValorFixoCEF :=

        PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                        pFolha.CdOrgao,
                        pFolha.NuVersaoTabcef,
                        pFolha.NuAnoReferencia,
                        pFolha.NuMesReferencia, /*FABIO*/ -- para pegar tabela salarial atual
                        vHP(i).CdEstruturaCarreira,
                        vHP(i).CdEstruturaCarreiraCarreira,
                        vHP(i).NuNivelPagamento,
                        vHP(i).NuReferenciaPagamento);
         -----------------------------------------------------------------------------
         -- Caso o orgao possua evento de hora aula/atividade, verifica se o servidor
         -- possui registros de hora aula/atividade vigentes
         -----------------------------------------------------------------------------

         vInTipoHoraAulaAtiv := FTipoHoraAulaAtividade(vCEF.CdVinculo,
                                                       pFolha.DtInicioMes,
                                                       pFolha.DtFimMes);

         -------------------------------------------------------------------
         -- Caso possua, ira realizar o pagamento via eventos 65 e 66
         -------------------------------------------------------------------

         IF vInTipoHoraAulaAtiv IN (1,2) THEN

          --------------------------------------------------------------------
          -- Se o servidor possuir hora atividade ou hora aula, ira alimentar a variavel
          -- PKGPAG_VAR.vgMediaCHOHoraAtiv
          --------------------------------------------------------------------

          --IF vInTipoHoraAulaAtiv = 2 THEN

            PMediaCHOHoraAtiv(pInTipoHoraAulaAtiv => vInTipoHoraAulaAtiv,
                              pCdVinculo          => vCEF.CdVinculo,
                              pDtInicioMes        => pFolha.DtInicioMes,
                              pDtFimMes           => pFolha.DtFimMes,
                              pDtFimRelacao       => vCEF.DtFim);

          --END IF;

          RETURN;

        END IF;

      ELSIF PKGPAG_VAR.vPagaSitDisposicao = 'PAG-DISP-ONUS-ORIGEM' THEN

       RETURN;

      else
        null;
      END IF;

        IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

          IF PKGPAG_VAR.vgValorFixoCEF.vlFixo IS NOT NULL THEN

            IF vCEF.CdRelacaoTrabalho <> 10 THEN

              /* FABIO - REAJUSTE PROPORCIONAL DUAS TABELAS SALARIAIS UDESC */
       IF PKGPAG_VAR.bPossuiEventoHoraAulaAtiv AND
          vIndex = 1 THEN

        vProporcional :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                       pRubrica           => pRubrica ,
                                                                       pValorIntegral     => vgVLFixoCEF,
                                                                       pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                       pCEF               => vCEF,
                                                                       pDtCalculo         => pDtCalculo,
                                                                       pEventoCEF         => PKGPAG_TIPO.cnS);

              ELSE
                vProporcional :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                       pRubrica           => pRubrica ,
                                                                       pValorIntegral     => PKGPAG_VAR.vgValorFixoCEF.VlFixo,
                                                                       pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                       pCEF               => vCEF,
                                                                       pDtCalculo         => pDtCalculo,
                                                                       pEventoCEF         => PKGPAG_TIPO.cnS);
              END IF;
            -- Alteracao posterior a folha de Junho, para pagamento integral de salario para
            -- disposicao finalizada ou iniciada no mes.

            ELSIF vCEF.CdRelacaoTrabalho = 10 AND
                   (PKGPAG_VAR.vgVinculo.DtDesligamento > pFolha.DtFimMes OR PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL) AND
                   ((vCEF.DtInicioRelacao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
                   (vCEF.DtFimRelacao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)) THEN

              IF  PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria = vCEF.NuCargaHoraria OR
                  pRubrica.CdRubProporcionalidadeCHO = 1 THEN

                 vProporcional.VlIntegral     := PKGPAG_VAR.vgValorFixoCEF.vlFixo;

              ELSE

                 vProporcional.VlIntegral     := PKGPAG_VAR.vgValorFixoCEF.vlFixo /
                                                 PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria *
                                                 vCEF.NuCargaHoraria;

              END IF;

              vProporcional.VlProporcional := vProporcional.VlIntegral;

              vProporcional.VlReal         := vProporcional.VlIntegral;

              vProporcional.VlIndice       := 30;

            ELSE

              vProporcional :=  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                       pRubrica           => pRubrica ,
                                                                       pValorIntegral     => PKGPAG_VAR.vgValorFixoCEF.VlFixo,
                                                                       pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                       pCEF               => vCEF,                                                                       pDtCalculo         => pDtCalculo,
                                                                       pEventoCEF         => PKGPAG_TIPO.cnS);

            END IF;

            vProporcionalAcum.vlIndice       := vProporcionalAcum.vlIndice + vProporcional.vlIndice;

            vProporcionalAcum.vlIntegral     := vProporcionalAcum.vlIntegral + vProporcional.vlIntegral;

            vProporcionalAcum.vlProporcional := vProporcionalAcum.vlProporcional + vProporcional.vlProporcional;

        END IF;

       END IF;

     END IF;

   bMesInteiro := FALSE;

END LOOP;
    END LOOP;

  ELSE

     PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vCdHistParamCalc,
                                PKGPAG_VAR.vCdPessoa,
                                'Histórico de Nível/Referencia do cargo efetivo não está definido.',
                                PKGPAG_VAR.vgCdVinculo);

  END IF;

  IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

    IF PKGPAG_VAR.vgVlPercentReducao > 0 THEN

      vProporcionalAcum.vlIntegral     :=

        vProporcionalAcum.vlIntegral*(100-PKGPAG_VAR.vgVlPercentReducao)/100;

      vProporcionalAcum.vlProporcional :=

        vProporcionalAcum.vlProporcional*(100-PKGPAG_VAR.vgVlPercentReducao)/100;

    END IF;

    PKGPAG_GERAL.PAtualizaHistCEF(pFolha,
                                  pRubrica,
                                  vCEF,
                                  vProporcionalAcum.vlIntegral,
                                  vProporcionalAcum.vlProporcional,
                                  vProporcional.vlReal,
                                  vProporcionalAcum.vlIndice);
  END IF;

END;

/*-----------------------------------------------------------------------------------------/
--     Procedure : p001RemuneracaoAPOParid
--      Objetivo : Gerar a remuneracao fixa para a relacao de vinculo de aposentado
--                 com paridade.
--
/*-----------------------------------------------------------------------------------------*/

PROCEDURE P001RemuneracaoAPOParid(pFolha              IN PKGPAG_TIPO.rFolha,
                                  pAPO                IN PKGPAG_TIPO.rCEF,
                                  pRubrica            IN PKGPAG_TIPO.rRubrica) IS

  vValorIndice       NUMBER(13,2);
  vValorIntegral     NUMBER(13,2);
  vProporcional      PKGPAG_TIPO.rValorPagamento;
   vvldecisaoJud           NUMBER;
   vcdvalorrefDecJud       INTEGER;
   vdtiniciodireitoDecJud  DATE;
   vDtInclusaoDecJud       DATE;

BEGIN

  -- pAPO.CdRelacaoTrabalho : Relacao de trabalho do cargo efetivo
  -- que deu origem a aposentadoria


   IF pkgpag_geral.fpossuidecisaojudicial(pkgpag_var.vgVinculo.cdvinculo,
                                          pFolha.nuanoreferencia,
                                          pFolha.numesreferencia,
                                          pRubrica.CdRubricaAgrupamento,
                                          vvldecisaoJud,
                                          vcdvalorrefDecJud,
                                          vdtiniciodireitoDecJud,
                                          vDtInclusaoDecJud) THEN

     RETURN;
   END IF;

  IF pAPO.CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao THEN

    PKGPAG_VAR.vgValorFixoCEF :=

      PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                       pFolha.CdOrgao,
                                       pFolha.NuVersaoTabcef,
                                       pFolha.NuAnoReferencia,
                                       pFolha.NuMesReferencia,
                                       pAPO.CdEstruturaCarreira,
                                       pAPO.CdEstruturaCarreiraCarreira,
                                       pAPO.NuNivelPagamento,
                                       pAPO.NuReferenciaPagamento);

     IF PKGPAG_GERAL.FGeraRubrica(pRubrica.CdRubricaAgrupamento) THEN

      IF PKGPAG_VAR.vgValorFixoCEF.vlFixo IS NOT NULL THEN

          vValorIntegral := PKGPAG_VAR.vgValorFixoCEF.vlFixo;

          vProporcional :=

            PKGPAG_GERAL.FCalculaProporcionalidade(pFolha          => pFolha,
                                                   pAPO            => pAPO,
                                                   pRubrica        => pRubrica,
                                                   pValorIntegral  => vValorIntegral);

          vValorIndice :=  CASE NVL(pAPO.VlPercentPropAPO,0)
                             WHEN 0 THEN
                               100
                             ELSE
                               pAPO.VlPercentPropAPO
                             END;

          -- Alterar indice das outras relacoes porque o indice padrao da rubrica 01-0263 eh dias
          -- quando setado para 100 nao somar
          if vValorIndice = 100 and pApo.DtInicio > pFolha.DtInicioMes then

             begin

             update epaghistoricorubricarelvinc vv
              set vv.vlindicerubrica = 0
              where vv.cdvinculo = pkgpag_var.vgVinculo.cdvinculo
                and vv.cdfolhapagamento = pFolha.CdFolhaPagamento
                and vv.cdrelacaovinculo <> pApo.CdRelacaoVinculo
                and vv.cdrubricaagrupamento = pRubrica.CdRubricaAgrupamento;

             exception
               when others then
                 null;
             end;

          end if;

          PKGPAG_GERAL.PAtualizaHistAPO(pFolha             => pFolha,
                                        pRubrica           => pRubrica,
                                        pAPO               => pAPO,
                                        pValorIntegral     => vProporcional.vlIntegral,
                                        pValorProporcional => vProporcional.vlProporcional,
                                        pValorReal         => vProporcional.vlReal,
                                        pValorIndice       => vValorIndice,
                                        pCdTipoIndice      => 2); -- Percentual

      ELSE

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                PKGPAG_VAR.vCdHistParamCalc,
                                PKGPAG_VAR.vCdPessoa,
                                'APO - Remuneracao fixa - Não foi encontrado valor fixo.',
                                PKGPAG_VAR.vgCdVinculo);

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

PROCEDURE P005GratificacaoProd(pFolha               IN PKGPAG_TIPO.rFolha,
                               pRubrica             IN PKGPAG_TIPO.rRubrica,
                               pCdTipoAtipratFaz    IN INTEGER,
                               pCEF                 IN PKGPAG_TIPO.rCEF DEFAULT NULL,
                               pAPO                 IN PKGPAG_TIPO.rCEF DEFAULT NULL,
                               pCCO                 IN PKGPAG_TIPO.rCCO DEFAULT NULL,
                               pCdEstruturaCarreira IN INTEGER          DEFAULT NULL,
                               pDtCalculo           IN DATE) IS

  vVlIndice                          NUMBER(7,4) DEFAULT NULL;
  vValorFixo                         PKGPAG_TIPO.rValorFixo;
  vProporcional                      PKGPAG_TIPO.rValorPagamento;
  vNuValor                           NUMBER(13,2);
  vValorIntegral                     NUMBER(13,2);
  vVlindiceunidescolar  NUMBER(7,4) DEFAULT NULL;
  vvldecisaoJud           NUMBER;
  vcdvalorrefDecJud       INTEGER;
  vdtiniciodireitoDecJud  DATE;
  vDtInclusaoDecJud       DATE;

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
           Vlindiceunidescolar,
           CdRubricaAgrupamento,
           VlFixoCEF,
           CdValorGeralCEFAgrupLimite,
           FlAplicaPercentSobreRubrica
      INTO vCdValorGeralCEFAGrup,
           vVlIndice,
           vVlindiceunidescolar,
           vCdRubricaAgrupamento,
           vVlFixoCEF,
           vCdValorGeralCEFAgrupLimite,
           vFlAplicaPercentSobreRubrica
      FROM ( SELECT VS.CdValorGeralCEFAGrup,
                    HAF.VlIndice,
                    HAF.Vlindiceunidescolar,
                    HAF.CdRubricaAgrupamento,
                    HAF.VlFixoCEF,
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

      -- O valor do indice diferenciado (vlindiceunidescolar)deve ser aplicado para as gratificacoes de produtividade
      -- quando este estiver definido e quando a unidade do local de trabalho da relacao de vinculo principal for uma unidade escolar.
      -- Nao estando definido, deve ser utilizado o valor do indice ja existente (vlindice).

      -- O calculo observa a lotacao de contratual (de origem).
       IF PKGPAG_VAR.vgCdOrgaoVinculo = 41  --apenas para educacao: chamado #64958
          AND FPossuiIndiceUnidEscolar (pCEF,
                                                                pAPO,
                                                                pCCO,
                                                                pfolha.DtCalculo,
                                                                pfolha.DtInicioMes,
                                                                pfolha.DtFimMes) = TRUE

           AND  NVL(vVlindiceunidescolar,0) != 0
       THEN
            vVlIndice := vVlindiceunidescolar;

       END IF;

       -- Caso a rubrica esteja lancada em financeiro
       IF PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubricaAgrupamento) AND vFlAplicaPercentSobreRubrica = PKGPAG_TIPO.cnN THEN

         vValorFixo.VlFixo := NVL(vVlFixoCEF,0);

         vValorFixo.NuCargaHoraria := PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria;

         vValorFixo.vlFixo := vValorFixo.vlFixo*vVlIndice/100;

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
                (V.vlFixo + vVlRubricaAgrupamento)*vVlIndice/100,
                PKGPAG_VAR.vgCarreira(pCdEstruturaCarreira).NuCargaHoraria,--PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
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

  IF pkgpag_geral.fpossuidecisaojudicial(pkgpag_var.vgVinculo.cdvinculo,
                                         pFolha.nuanoreferencia,
                                         pFolha.numesreferencia,
                                         pRubrica.CdRubricaAgrupamento,
                                         vvldecisaoJud,
                                         vcdvalorrefDecJud,
                                         vdtiniciodireitoDecJud,
                                         vDtInclusaoDecJud) THEN

      RETURN;
  END IF;

  IF pCEF.CdHistRelVinc IS NOT NULL AND
     PKGPAG_VAR.vPagaSitDisposicao <> 'PAG-DISP-ONUS-ORIGEM'
     --AND
     --pCEF.CdVinculo not in (221383)
     THEN

    IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                 pRubrica                  => pRubrica,
                                 pCdOrgao                  => CASE
                                                                WHEN pCEF.CdRelacaoTrabalho = 5 THEN
                                                                  pCEF.CdOrgaoExercicio
                                                                ELSE
                                                                  PKGPAG_VAR.vgCdOrgaoVinculo
                                                              END,
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
                                                               ELSE vVlIndice
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
                                                             ELSE vVlIndice
                                                             END,
                                       pCdTipoOrigemRubrica => 7);

     END IF;

   END IF;

  ELSIF pCCO.CdHistCargoCom IS NOT NULL THEN

    IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                 pRubrica                  => pRubrica,
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
                                 pCdEstruturaCarreira      => pCdEstruturaCarreira,
                                 pCdOpcaoRemuneracao       => pCCO.CdOpcaoRemuneracao,
                                 pFlTipoProvimento         => pCCO.FlTipoProvimento)
              -- Caso a Flag flAplicaAbrangenciaParcialCCO permita tambem ira gera a rubrica - SED e FCEE
             OR FAplicarAbrangenciaParcialCCO(pCdTipoAtipratFaz,
                                                                          pFolha) = TRUE THEN

        BEGIN

       -- As nomenclaturas dos campos DeNivel e DeCodigo da tabela de valores com
       -- os campos NuNivel e NuReferencia so geram confusao e dificuldade de entendimento.
       -- A epoca que foi solicitada a alteracao dos nomes para manter um padrao, porem foi negado,
       -- com a desculpa de que muita coisa ja estava implementada.

           SELECT NuValor,
                  VlIndice,
                  Vlindiceunidescolar
             INTO vNuValor,
                  vVlIndice,
                  vVlindiceunidescolar
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

            vNuValor := NULL;

        END;

          -- O calculo observa a lotacao de contratual (de origem).
           IF PKGPAG_VAR.vgCdOrgaoVinculo IN (41, 42)  --apenas para educa??o  e FCEE
              AND FPossuiIndiceUnidEscolar (pCEF,
                                                                    pAPO,
                                                                    pCCO,
                                                                    pfolha.DtCalculo,
                                                                    pfolha.DtInicioMes,
                                                                    pfolha.DtFimMes) = TRUE

               AND  NVL(vVlIndiceunidescolar,0) != 0
           THEN
                vVlIndice := vVlIndiceunidescolar;

           END IF;

        IF vNuValor IS NOT NULL THEN

            vValorIntegral := vNuValor*vVlIndice/100;

            vProporcional :=

              PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                     pRubrica           => pRubrica,
                                                     pCCO               => pCCO,
                                                     pValorIntegral     => vValorIntegral,
                                                     pDtCalculo         => pDtCalculo);

            PKGPAG_GERAL.PAtualizaHistCCO(pFolha               => pFolha,
                                          pRubrica             => pRubrica,
                                          pCCO                 => pCCO,
                                          pValorIntegral       => vProporcional.vlProporcional,
                                          pValorProporcional   => vProporcional.vlProporcional,
                                          pValorReal           => vProporcional.VlReal,
                                          pValorIndice         => CASE vProporcional.vlProporcional
                                                                  WHEN 0 THEN 0
                                                                ELSE vVlIndice
                                                                END,
                                          pCdExpressaoFormula  => NULL,
                                          pCdTipoOrigemRubrica => 7);

       END IF;

     END IF;

  else
    null;
  END IF;

EXCEPTION

  WHEN OTHERS THEN

    vVlIndice := 0;

END;

/*----------------------------------------------------------------------------------------------*/
-- Procedure: P007HorasSobreAviso
--
--  Objetivo: Gerar rubrica de adicional noturno para cargos efetivos levando em
--            consideracao as jornadas e escalas de servico
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P007HorasSobreAviso(pFolha    IN PKGPAG_TIPO.rFolha,
                              pRubrica  IN PKGPAG_TIPO.rRubrica,
                              pCEF      IN PKGPAG_TIPO.rCEF,
                              pFormExpr IN PKGPAG_TIPO.tFormulaCalculo) IS

   --vHorasJornada          INTEGER DEFAULT 0;

   vHorasEscala           INTEGER DEFAULT 0;

   vMinutosTotal          INTEGER DEFAULT 0;

   vHorasTotal            INTEGER DEFAULT 0;

   vCdExpressaoFormCalc   INTEGER;

   vCdExpansaoEscalaAtual INTEGER;

   FUNCTION FRetornaHorasEscala(/*pCdHistEscalaServico IN INTEGER,*/
                                pCdExpansaoEscala    IN INTEGER)

     RETURN INTEGER IS

     vMinutos INTEGER DEFAULT 0;

   BEGIN

      SELECT SUM( DtFim - DtInicio)*1440
        INTO vMinutos
        FROM EMovExpansaoEscalaTMP FE
       WHERE FE.CdExpansaoEscalaAtual = pCdExpansaoEscala AND
             DtInicio  BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                               PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao;

     RETURN NVL(vMinutos,0);

   END;

BEGIN

  FOR vHistEscala IN cHistEscala(pCEF.CdHistCargoEfetivo,
                                 PKGPAG_VAR.vgApuracaoFrequencia.CdApuracaoFrequencia,
                                 PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao,
                                 PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao,
                                 4)
    LOOP

      PKGMOV.PExpandeEscala(pCdOrgao => pkgpag_var.vgFolha.CdOrgao,
                            pCdHistEscalaServico  => vHistEscala.CdHistEscalaServico,
                            pDtInicio             => vHistEscala.DtInicioApuracao,
                            pdtFim                => (vHistEscala.DtFimApuracao + 1),
                            pFlEliminaAfastamento => PKGPAG_TIPO.cnN,
                            pCdExpansaoEscalaAtual => vCdExpansaoEscalaAtual);

      IF PKGPAG_VAR.vgApuracaoFrequencia.FlHomologaEscala = PKGPAG_TIPO.cnN THEN

        vHorasEscala := vHorasEscala + FRetornaHorasEscala(/*vHistEscala.CdHistEscalaServico,*/
                                                           vCdExpansaoEscalaAtual);

      ELSE

        IF vHistEscala.FlFreqEscalaHomologada = PKGPAG_TIPO.cnS THEN

          vHorasEscala := vHorasEscala + FRetornaHorasEscala(/*vHistEscala.CdHistEscalaServico,*/
                                                             vCdExpansaoEscalaAtual);

        END IF;

      END IF;

      vMinutosTotal := vMinutosTotal + vHorasEscala;

    END LOOP;

    IF vMinutosTotal > 59 THEN

      vHorasTotal := TRUNC(vMinutosTotal/60);

      vMinutosTotal := MOD(vMinutosTotal,60);

    END IF;

    vHorasTotal := vHorasTotal*100;

    IF (vHorasTotal + vMinutosTotal)  > 0 THEN

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

        IF vCdExpressaoFormCalc > 0 THEN

          PKGPAG_GERAL.PInsereLancamentoRelacao(
                                 pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                 pCdVinculo            => pCEF.CdVinculo,
                                 pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                 pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                 pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                 pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                 pVlIntegral           => NULL,
                                 pVlProporcional       => NULL,
                                 pNuSufixoRubrica      => 1,
                                 pNuParcelas           => 1,
                                 pVlIndice             => (vHorasTotal + vMinutosTotal),
                                 pCdTipoOrigemRubrica  => 7,
                                 pDtInicio             => pCEF.DtInicio,
                                 pDtFim                => pCEF.DtFim);

        END IF;

      END IF;

    END IF;

END;

/*----------------------------------------------------------------------------------------------*/
-- Procedure: P008AdicionalNoturno
--
--  Objetivo: Gerar rubrica de adicional noturno para cargos efetivos levando em
--            consideracao as jornadas e escalas de servico
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P008AdicionalNoturno(pFolha    IN PKGPAG_TIPO.rFolha,
                               pRubrica  IN PKGPAG_TIPO.rRubrica,
                               pCEF      IN PKGPAG_TIPO.rCEF,
                               pFormExpr IN PKGPAG_TIPO.tFormulaCalculo)
IS

    vHorasJornada          INTEGER DEFAULT 0;

    vHorasEscala           INTEGER DEFAULT 0;

    vMinutosTotal          INTEGER DEFAULT 0;

    vHorasTotal            INTEGER DEFAULT 0;

    vCdExpressaoFormCalc   INTEGER;

    --vCdExpansaoEscalaAtual INTEGER;

  FUNCTION FPossuiBancoDeHoras

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN

   SELECT COUNT(*)
     INTO vCont
     FROM EPagBHApurado BH
    WHERE BH.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
          BH.NuAnoReferencia = pFolha.NuAnoReferencia AND
          BH.NuMesReferencia = pFolha.NuMesReferencia;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  END;

  /*------------------------------------------------------*/
  FUNCTION FRetornaHorasJornada(pCdHistJornadaTrabalho IN INTEGER)
  /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras      NUMBER(4);

      vMinutos    NUMBER(2);

      vSomaMinutos NUMBER;

  BEGIN

    SELECT SUM((DtFimReal - DtInicioReal))*1440
      INTO vSomaMinutos
      FROM
     (SELECT CASE
             WHEN TO_CHAR(DtFimReal,'HH24MI') BETWEEN '0000' AND '0500' THEN
               DtFimReal
             WHEN TO_CHAR(DtFimReal,'HH24MI') = '2359' THEN
               DtFimReal + 1/1440
             WHEN TO_CHAR(DtFimReal,'HH24MI') BETWEEN '2200' AND '2359' THEN
               DtFimReal
             WHEN TO_CHAR(DtFimReal,'HH24MI') > '0500' AND
                  TO_CHAR(DtInicioReal,'HH24MI') BETWEEN '0000' AND '0500' THEN
               TO_DATE(TO_CHAR(DtFimReal,'DD/MM/YYYY') || '0500','DD/MM/YYYY HH24MI')
             END DtFimReal,
             CASE
             WHEN TO_CHAR(DtInicioReal,'HH24MI') BETWEEN '0000' AND '0500' THEN
               DtInicioReal
             WHEN TO_CHAR(DtInicioReal,'HH24MI') BETWEEN '2200' AND '2359' THEN
               DtInicioReal
             WHEN (TO_CHAR(DtFimReal,'HH24MI') BETWEEN '2200' AND '2359')  AND
                 TO_CHAR(DtInicioReal,'HH24MI') < '2200' THEN
              TO_DATE(TO_CHAR(DtInicioReal,'DD/MM/YYYY') || '2200','DD/MM/YYYY HH24MI')
             END DtInicioReal
        FROM (SELECT DtInicioReal AS DtFrequencia,
                     DtFimReal,
                     CASE
                       WHEN TRUNC(FJ.DtFimReal) - TRUNC(FJ.DtInicioReal) = 1 THEN
                                TRUNC(FJ.DtFimReal)
                            ELSE
                              DtInicioReal
                            END AS DtInicioReal
                       FROM EMovFrequenciaRealJornada FJ
                      WHERE (FJ.DtFrequencia
                                BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                                        PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao) AND
                             FJ.CdHistJornadaTrabalho = pCdHistJornadaTrabalho AND
                             FJ.FlAnulado = PKGPAG_TIPO.cnN
                     UNION
                     SELECT DtFimReal,
                            CASE
                              WHEN TRUNC(FJ.DtFimReal) - TRUNC(FJ.DtInicioReal) = 1 THEN
                                TRUNC(FJ.DtFimReal) - 1/1440
                              ELSE
                                FJ.DtFimReal
                            END AS DtFimReal,
                            DtInicioReal
                       FROM EMovFrequenciaRealJornada FJ
                      WHERE (FJ.DtFrequencia
                                BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                                        PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao) AND
                             FJ.CdHistJornadaTrabalho = pCdHistJornadaTrabalho AND
                             FJ.FlAnulado = PKGPAG_TIPO.cnN))
             WHERE DtFimReal IS NOT NULL AND DtInicioReal IS NOT NULL;

      vHoras   := TRUNC(vSomaMinutos/60);

      vMinutos := MOD(vSomaMinutos,60);

      RETURN LPAD(NVL(vHoras,0),2,'0') || LPAD(NVL(vMinutos,0),2,'0');

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       RETURN 0;

   END;

  /*------------------------------------------------------*/
  FUNCTION FRetornaHorasEscala(pCdHistEscalaServico IN INTEGER,
                               pCdExpansaoEscala    IN INTEGER)
  /*------------------------------------------------------*/
    RETURN INTEGER IS

      vHoras       NUMBER(4);

      vMinutos     NUMBER(2);

      vSomaMinutos NUMBER;

  BEGIN

    SELECT SUM(MINUTOS)*1440
      INTO vSomaMinutos
      FROM
     (SELECT DtFrequencia,
            SUM(DtFimEscala - DtInicioEscala) MINUTOS
        FROM (SELECT DtFrequencia,
                     CASE
                       WHEN TO_CHAR(DtFimReal,'HH24MI') BETWEEN '0000' AND '0500' THEN
                         DtFimReal
                       WHEN DtfimReal BETWEEN to_char(dtFimReal || '2200') AND trunc(dtFimReal + 1) THEN
                         DtFimReal
                       WHEN TO_CHAR(DtFimReal,'HH24MI') > '0500' AND
                            TO_CHAR(DtInicioReal,'HH24MI') BETWEEN '0000' AND '0500' THEN
                         TO_DATE(TO_CHAR(DtFimReal,'DD/MM/YYYY') || '0500','DD/MM/YYYY HH24MI')
                       END DtFimEscala,
                       CASE
                       WHEN TO_CHAR(DtInicioReal,'HH24MI') BETWEEN '0000' AND '0500' THEN
                         DtInicioReal
                       WHEN DtInicioReal BETWEEN to_date(to_char(DtInicioReal,'DD/MM/YYYY') || '2200','DD/MM/YYYY HH24MI')  AND trunc(DtInicioReal + 1) THEN
                         DtInicioReal
                       WHEN DtFimReal BETWEEN to_date(to_char(DtFimReal,'DD/MM/YYYY') || '2200','DD/MM/YYYY HH24MI') AND trunc(DtFimReal + 1) AND
                            TO_CHAR(DtInicioReal,'HH24MI') < '2200' THEN
                         TO_DATE(TO_CHAR(DtInicioReal,'DD/MM/YYYY') || '2200','DD/MM/YYYY HH24MI')
                     END DtInicioEscala
                FROM (SELECT DtFrequencia,
                             DtFimReal,
                             CASE
                               WHEN TRUNC(FE.DtFimReal) - TRUNC(FE.DtInicioReal) = 1 THEN
                                 TRUNC(FE.DtFimReal)
                             ELSE
                               DtInicioReal
                             END AS DtInicioReal
                        FROM EMovFrequenciaRealEscala FE
                       WHERE (FE.DtFrequencia
                                  BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                                          PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao) AND
                              FE.CdHistEscalaServico = pCdHistEscalaServico  AND
                             FE.FlAnulado = PKGPAG_TIPO.cnN
                      UNION
                      SELECT DtFrequencia,
                             CASE
                               WHEN TRUNC(FE.DtFimReal) - TRUNC(FE.DtInicioReal) = 1 THEN
                                 TRUNC(FE.DtFimReal)
                               ELSE
                                 FE.DtFimReal
                             END AS DtFimReal,
                             DtInicioReal
                       FROM EMovFrequenciaRealEscala FE
                      WHERE (FE.DtFrequencia
                               BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                                        PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao) AND
                             FE.CdHistEscalaServico = pCdHistEscalaServico AND
                             FE.FlAnulado = PKGPAG_TIPO.cnN))
     WHERE DtFimEscala IS NOT NULL AND DtInicioEscala IS NOT NULL
     GROUP BY DtFrequencia

  UNION

    SELECT  DtInicio,
            MINUTOS
      FROM (SELECT DtInicio,
                  SUM( DtFimEscala - DtInicioEscala) MINUTOS
              FROM (SELECT TRUNC(FE.DtInicio) DtInicio,
                      CASE
                      WHEN TO_CHAR(FE.Dtfim,'HH24MI') BETWEEN '0000' AND '0500' THEN
                        FE.DtFim
                      WHEN FE.Dtfim BETWEEN to_date(to_char(FE.DtFim,'DD/MM/YYYY') ||' 2200','DD/MM/YYYY HH24MI') AND trunc(FE.DtFim + 1) THEN
                        FE.DtFim
                      WHEN TO_CHAR(FE.Dtfim,'HH24MI') > '0500' AND
                           TO_CHAR(FE.DtInicio,'HH24MI') BETWEEN '0000' AND '0500' THEN
                        TO_DATE(TO_CHAR(FE.DtFim,'DD/MM/YYYY') || '0500','DD/MM/YYYY HH24MI')
                      ELSE
                         FE.DtFim
                     END DtFimEscala,
                     CASE
                     WHEN TO_CHAR(FE.DtInicio,'HH24MI') BETWEEN '0000' AND '0500' THEN
                       FE.DtInicio
                     WHEN FE.DtInicio BETWEEN to_date(to_char(FE.DtInicio,'DD/MM/YYYY') ||' 2200','DD/MM/YYYY HH24MI') AND trunc(FE.DtInicio + 1)THEN
                       FE.DtInicio
                     WHEN FE.DtFim BETWEEN to_date(to_char(FE.DtInicio,'DD/MM/YYYY') ||' 2200','DD/MM/YYYY HH24MI') AND trunc(FE.DtInicio + 1) AND
                         TO_CHAR(FE.DtInicio,'HH24MI') < '2200' THEN
                      TO_DATE(TO_CHAR(FE.DtInicio,'DD/MM/YYYY') || '2200','DD/MM/YYYY HH24MI')
                     ELSE
                      FE.DtInicio
                     END DtInicioEscala
                    FROM EMovExpansaoEscalaTMP FE
                   WHERE FE.CdExpansaoEscalaAtual = pCdExpansaoEscala) EX
               WHERE DtFimEscala IS NOT NULL AND DtInicioEscala IS NOT NULL
      GROUP BY DtInicio)
     WHERE (DtInicio  BETWEEN PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao AND
                              PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao) AND
           NOT EXISTS (SELECT 1
                         FROM EMovFrequenciaRealEscala FE
                        WHERE FE.DtFrequencia = DtInicio AND
                              FE.CdHistEscalaServico = pCdHistEscalaServico));

     vHoras   := TRUNC(vSomaMinutos/60);

     vMinutos := MOD(vSomaMinutos,60);

     RETURN LPAD(NVL(vHoras,0),2,'0') || LPAD(NVL(vMinutos,0),2,'0');

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       RETURN 0;

   END;

BEGIN

  /*IF FPossuiBancoDeHoras THEN

  ELSE*/

    -- Se a homologacao de frequencia nao e obrigatoria

    FOR vHistJornada IN cHistJornada(pCEF.CdHistCargoEfetivo,
                                     PKGPAG_VAR.vgApuracaoFrequencia.CdApuracaoFrequencia,
                                     PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao,
                                     PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao)
    LOOP

      IF PKGPAG_VAR.vgApuracaoFrequencia.FlHomologaJornada = PKGPAG_TIPO.cnN THEN

        vHorasJornada := FRetornaHorasJornada(vHistJornada.CdHistJornadaTrabalho);

      ELSE

        IF vHistJornada.FlFreqJornadaHomologada = PKGPAG_TIPO.cnS THEN

         vHorasJornada := FRetornaHorasJornada(vHistJornada.CdHistJornadaTrabalho);

        END IF;

      END IF;

    END LOOP;

    /*
    COMENTADO POIS VALOR DA ESCALA E INCLUIDA NO FINANCEIRO PELA FUNCIONALIDADE ESPECIFICA
    FOR vHistEscala IN cHistEscala(pCEF.CdHistCargoEfetivo,
                                   PKGPAG_VAR.vgApuracaoFrequencia.CdApuracaoFrequencia,
                                   PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao,
                                   PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao)
    LOOP

      PKGMOV.PExpandeEscala(pCdHistEscalaServico  => vHistEscala.CdHistEscalaServico,
                            pDtInicio             => vHistEscala.DtInicioApuracao,
                            pdtFim                => (vHistEscala.DtFimApuracao + 1),
                            pFlEliminaAfastamento => PKGPAG_TIPO.cnN,
                            pCdExpansaoEscalaAtual => vCdExpansaoEscalaAtual);

      IF PKGPAG_VAR.vgApuracaoFrequencia.FlHomologaEscala = PKGPAG_TIPO.cnN THEN

        vHorasEscala := vHorasEscala + FRetornaHorasEscala(vHistEscala.CdHistEscalaServico,
                                                           vCdExpansaoEscalaAtual);

      ELSE

        IF vHistEscala.FlFreqEscalaHomologada = PKGPAG_TIPO.cnS THEN

          vHorasEscala := vHorasEscala + FRetornaHorasEscala(vHistEscala.CdHistEscalaServico,
                                                             vCdExpansaoEscalaAtual);

        END IF;

      END IF;

    END LOOP;
    */

    vMinutosTotal := SUBSTR(LPAD(vHorasJornada,4,'0'),3,2) + SUBSTR(LPAD(vHorasEscala, 4,'0'),3,2);

    IF vMinutosTotal > 59 THEN

      vHorasTotal := TRUNC(vMinutosTotal/60);

      vMinutosTotal := MOD(vMinutosTotal,60);

    END IF;

    vHorasTotal := (vHorasTotal + SUBSTR(LPAD(vHorasJornada,4,'0'),1,2) + SUBSTR(LPAD(vHorasEscala,4,'0'),1,2))*100;

    IF (vHorasTotal + vMinutosTotal)  > 0 THEN

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

        IF vCdExpressaoFormCalc > 0 THEN

          PKGPAG_GERAL.PInsereLancamentoRelacao(
                                 pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                 pCdVinculo            => pCEF.CdVinculo,
                                 pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                 pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                 pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                 pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                 pVlIntegral           => NULL,
                                 pVlProporcional       => NULL,
                                 pNuSufixoRubrica      => 1,
                                 pNuParcelas           => 1,
                                 pVlIndice             => (vHorasTotal + vMinutosTotal),
                                 pCdTipoOrigemRubrica  => 7,
                                 pDtInicio             => pCEF.DtInicio,
                                 pDtFim                => pCEF.DtFim);

        END IF;

      END IF;

    END IF;

    /*ELSE

    END IF;

  END IF;*/

END;

/*-----------------------------------------------------------------------------------------
-- Procedure: P013RemuneracaoSubstCEF
--  Objetivo: Gera a remuneracao de substituicao para cargos efetivos
--
/*-----------------------------------------------------------------------------------------*/

PROCEDURE P013RemuneracaoSubstCEF(pFolha     IN PKGPAG_TIPO.rFolha,
                                  pEvento    IN PKGPAG_TIPO.rEvento,
                                  pCEF       IN PKGPAG_TIPO.rCEF,
                                  pDtCalculo IN DATE) IS

  tRotData       PKGAFA.tabRotData;

  ind            PLS_INTEGER;

  vValorFixo PKGPAG_TIPO.rValorFixo;

  --C_RESP_NAO_PERMITE        INTEGER := 1;
  --C_RESP_SEM_ADIC           INTEGER := 2;
  C_RESP_DIF_ADIC           INTEGER := 3;
  C_RESP_PERC_ADIC_APOS1    INTEGER := 4;
  C_RESP_PERC_ADIC_APOS2    INTEGER := 5;

  C_RUBR_UNID_DIF           CHAR(1) := 'A';
  C_RUBR_UNID_PER           CHAR(1) := 'B';
  C_RUBR_CARG_DIF           CHAR(1) := 'C';

  CURSOR cCEFSubst(pCdVinculo       IN INTEGER,
                   pCdHistCEFOrigem IN INTEGER,
                   pdtInicioMes     IN DATE,
                   pdtFimMes        IN DATE,
                   pDtCalculo       IN DATE) IS
    SELECT CE.CdTipoRecebimento,
           CE.CdHistCargoEfetivo,
           CE.CdEstruturaCarreira,
           EC.CdEstruturaCarreiraCarreira,
           greatest (CE.DtInicio,pDtInicioMes) as DtInicio,
           least (nvl(CE.DtFim,pDtFimMes),pDtFimMes) as DtFim,
           CE.NuNivelPagamento,
           CE.NuReferenciaPagamento,
           LT.CdUnidadeOrganizacional,
           0.0 as VlRemuneracaoMensal
     FROM eCadHistCargoEfetivo CE
    INNER JOIN ECadEstruturaCarreira EC
       ON CE.CdEstruturaCarreira = EC.CdEstruturaCarreira
    INNER JOIN (SELECT LT.CdHistCargoEfetivo,
                       MAX(DtInicio) AS DtInicio
                 FROM eCadLocalTrabalho LT
                WHERE LT.CdVinculo = pCdVinculo AND
                      LT.FlDefinitiva = PKGPAG_TIPO.cnS AND
                      LT.FlAnulado = PKGPAG_TIPO.cnN AND
                      LT.DtInicio <= pdtFimMes AND
                      LT.CdHistCargoEfetivo IS NOT NULL
                GROUP BY LT.CdHistCargoEfetivo) LT1
       ON LT1.CdHistCargoEfetivo = CE.CdHistCargoEfetivo
    INNER JOIN ECadLocalTrabalho LT
       ON  LT.CdHistCargoEfetivo = LT1.CdHistCargoEfetivo AND
           LT.DtInicio = LT1.DtInicio AND
           (LT.DtFim >= pdtInicioMes
           OR LT.DtFim IS NULL) AND
           LT.FlDefinitiva = PKGPAG_TIPO.cnS
    WHERE (CE.CdVinculo = pCdVinculo ) AND
          ((CE.DtInicio <= pdtFimMes) AND
          (CE.dtFim >=  pdtInicioMes
          OR CE.dtFim IS NULL)) AND
          CE.FlEfetivacao = PKGPAG_TIPO.cnR AND
          CE.FlAnulado = PKGPAG_TIPO.cnN AND
          CE.CdHistCEFOrigem = pCdHistCEFOrigem AND
          CE.FlRespCumulativa = PKGPAG_TIPO.cnS AND
          CE.CdTipoRecebimento in (2,3); -- Receber por UO ou Cargo

   type TAB_CEFSubst IS TABLE OF cCEFSubst%ROWTYPE;

   tCEFSubst TAB_CEFSubst;

   type REC_Valores IS RECORD (
       QtDias        INTEGER,
       FlForma       CHAR(1), --  C_RUBR_UNID_DIF ,C_RUBR_UNID_PER,C_RUBR_CARG_DIF
       VlFixo        NUMBER,
       VlRef         NUMBER);

   type TAB_Valores is TABLE OF REC_Valores;

   tValoresResp  TAB_Valores;

   -----------
   -- Busca o Maior Valor do "Respondendo" do intervalo iniciado em pData
   -----------

   FUNCTION FBuscaMaiorRemuneracao (pCdTipoRecebimento IN INTEGER,
                                    pData              IN DATE,
                                    pQtdeOcor          IN INTEGER) RETURN NUMBER IS

      vQtRestante        INTEGER;

      vlMaiorRemuneracao NUMBER;

   BEGIN

     vlMaiorRemuneracao := 0;

     vQtRestante := pQtdeOcor;

     FOR ind in tCEFSubst.FIRST..tCEFSubst.LAST LOOP

        IF tCEFSubst (ind).CdTipoRecebimento = pCdTipoRecebimento AND
           pData between tCEFSubst (ind).DtInicio
                     and tCEFSubst (ind).DtFim then

           -- Processa, do tipo de recebimento e no intervalo

           IF vlMaiorRemuneracao < NVL (tCEFSubst (ind).VlRemuneracaoMensal,0) THEN

              vlMaiorRemuneracao := NVL (tCEFSubst (ind).VlRemuneracaoMensal,0);

           END IF;

           vQtRestante := vQtRestante - 1;

           IF vQtRestante <= 0 THEN

              EXIT;

           END IF;

        END IF;

     END LOOP;

     RETURN vlMaiorRemuneracao;

   END;

   -----------
   -- Carga de "Respondendo por" e calculo dos intervalos
   -----------

   PROCEDURE PCargaDados IS

      vTipoResponderUO     INTEGER;
      vTipoResponderCargo  INTEGER;

   BEGIN

       -- Calculando a remuneracao do "Responder por Efetivo" e os intervalos de data de Receber

       PKGAFA.PRotDataInicializar (pFolha.DtInicioMes,pFolha.DtFimMes);

       FOR ind in tCEFSubst.FIRST..tCEFSubst.LAST LOOP

          vValorFixo :=
              PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                               pFolha.CdOrgao,
                                               pFolha.NuVersaoTabcef,
                                               pFolha.NuAnoReferencia,
                                               pFolha.NuMesReferencia,
                                               tCEFSubst (ind).CdEstruturaCarreira,
                                               tCEFSubst (ind).CdEstruturaCarreiraCarreira,
                                               tCEFSubst (ind).NuNivelPagamento,
                                               tCEFSubst (ind).NuReferenciaPagamento);

          tCEFSubst (ind).VlRemuneracaoMensal := vValorFixo.VlFixo;

          IF tCEFSubst(ind).Cdtiporecebimento = 2 THEN -- Receber por UO

             PKGAFA.PRotDataInserirData (tCEFSubst(ind).DtInicio,
                                         tCEFSubst(ind).dtFim,
                                         pNuSoma2 => 1 ); -- NuSoma2 = qtde de ocorr de tCEFSubst do intervalo

          ELSIF tCEFSubst(ind).Cdtiporecebimento = 3 THEN -- Receber por Cargo Efetivo
             PKGAFA.PRotDataInserirData (tCEFSubst(ind).DtInicio,
                                         tCEFSubst(ind).dtFim,
                                         pNuSoma3 => 1 ); -- NuSoma3 = qtde de ocorr de tCEFSubst do intervalo

          else
            null;
          END IF;

       END LOOP;

       -- Buscando o Tipo de Responder do Cargo Original

       vTipoResponderUO    := null;
       vTipoResponderCargo := null;

       BEGIN

          select CdTipoFormaResponderUO, CdTipoFormaResponderCargo
             into vTipoResponderUO, vTipoResponderCargo
          FROM (  select CdTipoFormaResponderUO, CdTipoFormaResponderCargo,
                         ROW_NUMBER() OVER ( ORDER BY DtInicioVigencia DESC) as ordem
                    from ECadOrgaoCarreiraCargoEfetivo
                   where cdEstruturaCarreira = pCEF.cdEstruturaCarreira
                     and cdOrgao = pFolha.CdOrgao
                    and DtInicioVigencia <= pFolha.DtFimMes
                    and (DtFimVigencia IS NULL or DtFimVigencia >= pFolha.DtInicioMes)
               ) WHERE ordem = 1;

       EXCEPTION
           WHEN NO_DATA_FOUND THEN
              NULL;
       END;

       -- Adiciona aos intervalos o valor do FIXO do CEF Origem

       FOR ind in PKGPAG_VAR.vgFixoCEF.FIRST .. PKGPAG_VAR.vgFixoCEF.LAST LOOP

         PKGAFA.PRotDataInserirData (PKGPAG_VAR.vgFixoCEF (ind).DtInicio,
                                     PKGPAG_VAR.vgFixoCEF (ind).DtFim,
                                     pFlTem1  => PKGPAG_VAR.vgFixoCEF (ind).vlFixo.vlFixo,  -- FlTem1  = Valor do Fixo (usa "Tem" para setar apenas uma vez e nao "Somar")
                                     pFlTem2  => vTipoResponderUO,
                                     pFlTem3  => vTipoResponderCargo);
       END LOOP;

       -- calcula Intervalos

       PKGAFA.PRotDataCalcular (tRotData);

   END;

   -----------
   -- Percorre os valores da tabela e apura o valor da rubrica
   -----------

   FUNCTION FApuraValor (pValores IN TAB_VALORES, pForma IN CHAR )RETURN NUMBER IS

      vVlRubrica    NUMBER;
      cPERC_SUBCEF  INTEGER := 15; -- 15% de Remuneracao de Substituicao de Cargo Efetivo
      vIndice       NUMBER;
      v_LimitaMes   INTEGER;
      v_Dias        INTEGER;
      v_Tam_Mes     INTEGER;
   BEGIN

     vVlRubrica := 0;

     v_Tam_Mes  := 30;

     IF pValores.FIRST IS NULL THEN -- Nao tem valores a apurar
        NULL;

     ELSE -- Tem valores

       v_LimitaMes := 0;

       FOR reg IN pValores.FIRST .. pValores.LAST LOOP

          IF pValores(reg).FlForma = pForma THEN
              v_LimitaMes := v_LimitaMes + pValores (reg).QtDias;

              v_dias := pValores (reg).QtDias;
              if v_LimitaMes > v_Tam_Mes THEN -- Limitar a 30 dias

                 v_dias := v_dias - (v_LimitaMes - v_Tam_Mes);

                 V_LimitaMes := v_Tam_Mes;

              END IF;

              IF v_dias > 0 THEN

                 vIndice :=v_dias / v_Tam_Mes;

                 IF pValores (reg).FlForma IN (C_RUBR_UNID_DIF,C_RUBR_CARG_DIF) THEN -- Diferenca
                    IF pValores (reg).VlRef > pValores (reg).VlFixo THEN
                        vVlRubrica := vVlRubrica
                                    + vIndice * (pValores (reg).VlRef - pValores (reg).VlFixo);
                    END IF;
                 ELSE -- Percentual = C_RUBR_UNID_PER
                    vVlRubrica := vVlRubrica
                                + vIndice * (cPERC_SUBCEF * pValores (reg).VlRef / 100);
                 END IF;

               END IF;
           END IF;

       END LOOP;

     END IF;

     RETURN vVlRubrica;

   END;

   -----------
   -- Percorre os intervalos para o tipo de recebimento indicado

   -- Usar o valor do cargo "Respondendo" . Sempre considerar a subst. "Respondendo" de maior valor e cumulativa
   -- Proporcionalizar todos os valores por dia

   -- pFlTem1  => Valor do Fixo do CEF para o intervalo
   -- pFlTem2  => Tipo de Responder por UO
   -- pFlTem3  => Tipo de Responder por Cargo
   -- pNuSoma2 => qtde de ocorr de tCEFSubst do intervalo que esta respondendo por UO (cdTipoRecebimento=2)
   -- pNuSoma3  => Valor do Fixo do CEF para o intervalo que esta respondendo por Cargo (cdTipoRecebimento=3)
   -----------

   PROCEDURE PPercorreIntervalos IS

      qtOcorRespUO      number;
      qtOcorRespCargo   number;
      vlFixoCEF         number;
      vlFixoRespondendo number;
      vFlTipoRespUO     integer;
      vFlTipoRespCargo  integer;
      vFlForma          VARCHAR2(10);

   BEGIN

     -- Percorrer os intervalos e calcular valores conforme dias e maior valor

     tValoresResp := TAB_Valores();

     FOR reg IN tRotData.FIRST .. tRotData.LAST LOOP

       -- Obtem valores do intervalo

       qtOcorRespUO      := tRotData (reg).NuSoma2;
       qtOcorRespCargo   := tRotData (reg).NuSoma3;
       vlFixoCEF         := tRotData (reg).FlTem1;
       vFlTipoRespUO     := tRotData (reg).FlTem2;
       vFlTipoRespCargo  := tRotData (reg).FlTem3;

       /* ------------------------------------
          Respondendo pela UO

          -- Para cargo PROMOTOR DE JUSTICA SUBSTITUTO, paga a diferenca do vencimento para o valor titular como gratificacao

          -- Para cargo PROMOTOR DE ENTRANCA ESPECIAL DA CAPITAL, paga 15% do valor titular como gratificacao (somente apos a segunda subst, concomitante)

          -- Para demais cargos, paga 15% do valor titular como gratificacao

          ------------------------------------ */

       IF vFlTipoRespUO IS NOT NULL AND qtOcorRespUO > 0 THEN -- Teve "Responder pela UO" por no intervalo

          vlFixoRespondendo := FBuscaMaiorRemuneracao (pCdTipoRecebimento => 2,
                                                       pData              => tRotData (reg).DtIni,
                                                       pQtdeOcor          => qtOcorRespUO);

          vFlForma := NULL;

         -- PROMOTOR DE JUSTICA SUBSTITUTO, paga a diferenca do vencimento para o valor titular como gratificacao

          IF vFlTipoRespUO = C_RESP_DIF_ADIC THEN

             vFlForma := C_RUBR_UNID_DIF; -- Diferenca

          -- PROMOTOR DE ENTRANCA ESPECIAL DA CAPITAL, paga 15% do valor titular como gratificacao (somente apos a segunda subst, concomitante)

          ELSIF vFlTipoRespUO = C_RESP_PERC_ADIC_APOS2 THEN

             IF qtOcorRespUO >= 2 THEN
                vFlForma :=  C_RUBR_UNID_PER; -- Percentual
             END IF;

          -- Para demais cargos, paga 15% do valor titular como gratificacao

          ELSIF vFlTipoRespUO = C_RESP_PERC_ADIC_APOS1 THEN

             vFlForma := C_RUBR_UNID_PER; -- Percentual

          else
            null;
          END IF;

          -- Verifica se deve armazenar valor na tabela

          if vFlForma IS NOT NULL THEN

            if tValoresResp.LAST IS NULL or
                        (  tValoresResp (tValoresResp.LAST).FlForma <> vFlForma
                        or tValoresResp (tValoresResp.LAST).VlRef   <> vlFixoRespondendo
                        or tValoresResp (tValoresResp.LAST).VlFixo  <> vlFixoCEF) THEN
               tValoresResp.EXTEND;
               tValoresResp (tValoresResp.LAST).QtDias  := 0;
               tValoresResp (tValoresResp.LAST).FlForma := vFlForma;
               tValoresResp (tValoresResp.LAST).VlRef   := vlFixoRespondendo;
               tValoresResp (tValoresResp.LAST).VlFixo  := vlFixoCEF;
            END IF;

            tValoresResp (tValoresResp.LAST).QtDias := tValoresResp (tValoresResp.LAST).QtDias
                                                     + tRotData (reg).DtFim - tRotData (reg).DtIni + 1;

          END IF;

       END IF;

       /* ------------------------------------
          Respondendo pelo Cargo

          -- Paga a diferenca do vencimento para o valor do cargo ao qual esta respondendo como gratificacao

          ------------------------------------ */
       IF vFlTipoRespCargo = C_RESP_DIF_ADIC AND qtOcorRespCargo > 0 THEN -- Teve "Responder pelo Cargo" por no intervalo

          vlFixoRespondendo := FBuscaMaiorRemuneracao (pCdTipoRecebimento => 3,
                                                       pData              => tRotData (reg).DtIni,
                                                       pQtdeOcor          => qtOcorRespCargo);

          vFlForma := C_RUBR_CARG_DIF; -- Diferenca

          if tValoresResp.LAST IS NULL or
                      (  tValoresResp (tValoresResp.LAST).FlForma <> vFlForma
                      or tValoresResp (tValoresResp.LAST).VlRef   <> vlFixoRespondendo
                      or tValoresResp (tValoresResp.LAST).VlFixo  <> vlFixoCEF) THEN
             tValoresResp.EXTEND;
             tValoresResp (tValoresResp.LAST).QtDias  := 0;
             tValoresResp (tValoresResp.LAST).FlForma := vFlForma;
             tValoresResp (tValoresResp.LAST).VlRef   := vlFixoRespondendo;
             tValoresResp (tValoresResp.LAST).VlFixo  := vlFixoCEF;
          END IF;

          tValoresResp (tValoresResp.LAST).QtDias := tValoresResp (tValoresResp.LAST).QtDias
                                                   + tRotData (reg).DtFim - tRotData (reg).DtIni + 1;

       END IF;

     END LOOP;

   END;

   PROCEDURE PInsereLancamentoSubstCEF (pFolha                IN PKGPAG_TIPO.rFolha,
                                        pCEF                  IN PKGPAG_TIPO.rCEF,
                                        pCdRubricaAgrupamento IN INTEGER,
                                        pForma                IN CHAR) IS
    vVlRubrica        NUMBER;

   BEGIN

      vVlRubrica := FApuraValor (tValoresResp,pForma);

      IF vVlRubrica > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoRelacao(
                               pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                               pCdVinculo            => pCEF.CdVinculo,
                               pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                               pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                               pCdExpressaoFormCalc  => NULL,
                               pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                               pVlIntegral           => vVlRubrica,
                               pVlProporcional       => vVlRubrica,
                               pNuSufixoRubrica      => 1,
                               pNuParcelas           => 1,
                               pVlIndice             => NULL,
                               pCdTipoOrigemRubrica  => 7,
                               pDtInicio             => pCEF.DtInicio,
                               pDtFim                => pCEF.DtFim);
     END IF;
   END;

BEGIN

   -- Carregar "Responder por Efetivo" de Cumulativas

   OPEN cCEFSubst (pCdVinculo       => pCEF.CdVinculo,
                   pCdHistCEFOrigem => pCEF.CdHistCargoEfetivo,
                   pdtInicioMes     => pFolha.DtInicioMes,
                   pdtFimMes        => pFolha.DtFimMes,
                   pDtCalculo       => pDtCalculo);

   FETCH cCEFSubst BULK COLLECT INTO tCEFSubst;

   CLOSE cCEFSubst;

   IF tCEFSubst.FIRST IS NOT NULL THEN

      PCargaDados;

      PPercorreIntervalos;

      PInsereLancamentoSubstCEF (pFolha                => pFolha,
                                 pCEF                  => pCEF,
                                 pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa2,
                                 pForma                => C_RUBR_CARG_DIF);

      PInsereLancamentoSubstCEF (pFolha                => pFolha,
                                 pCEF                  => pCEF,
                                 pCdRubricaAgrupamento => pEvento.CdRubricaAgrupamento,
                                 pForma                => C_RUBR_UNID_PER);

      PInsereLancamentoSubstCEF (pFolha                => pFolha,
                                 pCEF                  => pCEF,
                                 pCdRubricaAgrupamento => pEvento.CdRubAgrupAlternativa3,
                                 pForma     => C_RUBR_UNID_DIF);

   END IF;

END;

/*----------------------------------------------------------------------------------------------*/
-- Procedure: P015a017RemuneracaoHoraExtra
--
--  Objetivo: Gerar rubrica de horas extras normais, horas extras especiais para cargos
--            efetivos e funcoes de chefia
--            levando em consideracao as jornadas e escalas de servico
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P015a017e023RemunHoraExtra(pFolha                 IN PKGPAG_TIPO.rFolha,
                                     pRubrica               IN PKGPAG_TIPO.rRubrica,
                                     pCEF                   IN PKGPAG_TIPO.rCEF,
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
     WHERE BH.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
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
           WHERE --LT.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
                 LT.CdVinculo = pCEF.CdVinculo AND
                 LT.CdHistCargoEfetivo IS NOT NULL AND
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
         WHERE LT.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
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
          WHERE --LT.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
                LT.CdVinculo = pCEF.CdVinculo AND
                LT.CdHistCargoEfetivo IS NOT NULL AND
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
        WHERE LT.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
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
        WHERE LT.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
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
       WHERE LT.CdHistCargoEfetivo = pCEF.CdHistRelVinc AND
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

  PKGPAG_GERAL.PLogTrace ('EVCEFAPO - Remun Hora Extra', 'Horas min total: ' || vMinutosTotal);

  IF vMinutosTotal > 59 THEN

    vHorasTotal   := TRUNC(vMinutosTotal/60);

    vMinutosTotal := MOD(vMinutosTotal,60);

  END IF;

  vHorasTotal := (vHorasTotal + SUBSTR(LPAD(vHorasJornada,10,'0'),1,LENGTH(LPAD(vHorasJornada,10,'0'))-2) +
                                SUBSTR(LPAD(vHorasEscala,10,'0'),1,LENGTH(LPAD(vHorasEscala,10,'0'))-2))*100;

  IF (vHorasTotal + vMinutosTotal)  > 0 THEN

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
                                     pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                     pFlTipoProvimento         => pCEF.FlEfetivacao,
                                     pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                     pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao) THEN

       -- 1) Busca a formula associada

       vCdExpressaoFormCalc :=

            PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                 pFormExpr                 => pFormExpr,
                                 pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                 pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                 pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                 pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoRelacao(
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => pCEF.CdVinculo,
                              pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                              pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => NULL,
                              pVlProporcional       => NULL,
                              pNuSufixoRubrica      => 1,
                              pNuParcelas           => 1,
                              pVlIndice             => (vHorasTotal + vMinutosTotal),
                              pCdTipoOrigemRubrica  => 7,
                              pDtInicio             => pCEF.DtInicio,
                              pDtFim                => pCEF.DtFim);

        IF PKGPAG_VAR.vgFUC.COUNT > 0 THEN

          FOR j IN PKGPAG_VAR.vgFUC.FIRST .. PKGPAG_VAR.vgFUC.LAST
          LOOP

            PKGPAG_GERAL.PInsereLancamentoRelacao(
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => PKGPAG_VAR.vgFUC(j).CdVinculo,
                              pCdRelacaoVinculo     => 3,
                              pCdHistRelacaoVinculo => PKGPAG_VAR.vgFUC(j).CdHistFuncaoChefia,
                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => NULL,
                              pVlProporcional       => NULL,
                              pNuSufixoRubrica      => 1,
                              pNuParcelas           => 1,
                              pVlIndice             =>(vHorasTotal + vMinutosTotal),
                              pCdTipoOrigemRubrica  => 7,
                              pDtInicio             => PKGPAG_VAR.vgFUC(j).DtInicio,
                              pDtFim                => PKGPAG_VAR.vgFUC(j).DtFim);

          END LOOP;

        END IF;

        IF PKGPAG_VAR.vgCCO.COUNT > 0 THEN

          FOR j IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST
          LOOP

            PKGPAG_GERAL.PInsereLancamentoRelacao(
                              pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                              pCdVinculo            => PKGPAG_VAR.vgCCO(j).CdVinculo,
                              pCdRelacaoVinculo     => 2,
                              pCdHistRelacaoVinculo => PKGPAG_VAR.vgCCO(j).CdHistCargoCom,
                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                              pVlIntegral           => NULL,
                              pVlProporcional       => NULL,
                              pNuSufixoRubrica      => 1,
                              pNuParcelas           => 1,
                              pVlIndice             =>(vHorasTotal + vMinutosTotal),
                              pCdTipoOrigemRubrica  => 7,
                              pDtInicio             => PKGPAG_VAR.vgCCO(j).DtInicio,
                              pDtFim                => PKGPAG_VAR.vgCCO(j).DtFim);

          END LOOP;

        END IF;

      END IF;

    END IF;

  END IF;

END;

/*-----------------------------------------------------------------------------------------/
--     Procedure : P022RemuneracaoAPOSemParid
--      Objetivo : Gerar a remuneracao para a relacao de vinculo de aposentado
--                 sem paridade.
--
/*-----------------------------------------------------------------------------------------*/

PROCEDURE P022RemuneracaoAPOSemParid(pFolha              IN PKGPAG_TIPO.rFolha,
                                     pRubrica            IN PKGPAG_TIPO.rRubrica,
                                     pApoSemParid        IN PKGPAG_TIPO.rCEF) IS

  CURSOR cValorApoSemParid IS
    SELECT DtIniciovalidade,
           VlFinalAposentadoria
      FROM (SELECT VASP.DtIniciovalidade,
                   VASP.VlFinalAposentadoria
              FROM EPagValorApoSemParidade VASP
             WHERE VASP.CdVinculo = pApoSemParid.CdVinculo AND
                   VASP.DtInicioValidade <= pFolha.DtFimMes
             ORDER BY VASP.DtInicioValidade DESC)
      WHERE ROWNUM < 2;

  vNuDiasMes        INTEGER; -- Numero de dias do mes
  vNuDias           INTEGER; -- Numero de dias da relacao
  vVlIntegral       NUMBER(13,2) := 0;
  vVlProporcional   NUMBER(13,2) := 0;
  vVlReal           NUMBER(13,2) := 0;
  vVlIndice         NUMBER(9,4)  := 0;

BEGIN

  vNuDiasMes := PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes,
                                               pRubrica.FlPropMesComercial);

  FOR vValorSemParid IN cValorApoSemParid
  LOOP

    vNuDias := PKGPAG_GERAL.FRetornaIndice(pRubrica.FlPropMesComercial,
                                           pFolha.DtInicioMes,
                                           pFolha.DtFimMes,
                                           pApoSemParid.DtInicio,
                                           pApoSemParid.DtFim);

    vVlIntegral := vVlIntegral + (vValorSemParid.VlFinalAposentadoria*(vNuDias/vNuDiasMes));

    vVlReal     := vValorSemParid.VlFinalAposentadoria;

    vVlIndice   := pApoSemParid.VlPercentPropAPO*(vNuDias/vNuDiasMes);

  END LOOP;

  IF vVlIntegral > 0 THEN

    vVlProporcional := vVlIntegral/**(pApoSemParid.VlPercentPropAPO/100)*/;

    PKGPAG_GERAL.PAtualizaHistAPO(pFolha,
                                  pRubrica,
                                  pApoSemParid,
                                  vVlIntegral,
                                  vVlProporcional,
                                  vVlReal,
                                  vVlIndice);

  END IF;

END;

PROCEDURE P065066HoraAulaAtividade (pFolha                IN PKGPAG_TIPO.rFolha,
                                    pCEF                  IN PKGPAG_TIPO.rCEF,
                                    pRubrica              IN PKGPAG_TIPO.rRubrica,
                                    pInTipoPagamento      IN INTEGER) IS

  vVlPagamento           NUMBER(13,2) DEFAULT 0;
  vVlReal                NUMBER(13,2) DEFAULT 0; -- Incluido valor real em 31/07 Solicitac?o Rescis?o UDESC
  vVlIntegral             NUMBER(13,2) DEFAULT 0;
  vNuDiasTratados               pkgpag_tipo.rData;
  vNuDiasMov                    pkgpag_tipo.rData;
  vNuDias                INTEGER      DEFAULT 0;
  --vNuNivelPagamento      VARCHAR2(3);
  --vNuReferenciaPagamento VARCHAR2(3);
  vNuCHO                 NUMBER(7,4);
  vProporcional          PKGPAG_TIPO.rValorPagamento;
  vValorFixo             pkgpag_tipo.rValorFixo;
  vValorSoma             NUMBER(13,2) :=0;
  vNuDiasMovSoma         INTEGER := 0;
  vNuDiasTratadosSoma    INTEGER := 0;
BEGIN

  -- Define a carga horaria de acordo com o tipo de Hora: Aula ou Atividade

  IF pInTipoPagamento = 1 THEN

    vNuCHO := NVL(PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria, pCEF.NuCargaHoraria);

  ELSE

    vNuCHO := 20;

  END IF;

  ----------------------------------------------------------------
  -- Caso encontre o valor definido para a carreira do servidor
  ----------------------------------------------------------------

  IF PKGPAG_VAR.vgValorFixoCEF.VlFixo IS NOT NULL AND
     vNuCHO > 0 THEN

    FOR vRec IN ( SELECT CASE
                           WHEN HA.DtInicio < pFolha.DtInicioMes THEN
                             pFolha.DtInicioMes
                           ELSE
                             HA.DtInicio
                           END DtInicio,
                           CASE
                             WHEN HA.DtFim < pCef.DtFim THEN
                               HA.DtFim
                             WHEN pCEF.DtFim < pFolha.DtFimMes THEN
                               pCEF.DtFim
                             WHEN HA.DtFim > pFolha.DtFimMes OR HA.DtFim IS NULL THEN
                               pFolha.DtFimMes
                           ELSE
                             HA.DtFim
                          END DtFim,
                          HA.QtHorasMensal
                     FROM ECadHistHoraAulaAtividade HA
                    WHERE HA.CdVinculo = pCEF.CdVinculo AND
                          HA.InTipoPagamento = pInTipoPagamento AND
                          HA.FlAnulado = PKGPAG_TIPO.cnN AND
                          HA.DtInicio <= pFolha.DtFimMes AND
                          (HA.DtFim >= pFolha.DtInicioMes OR HA.DtFim IS NULL)
                    ORDER BY HA.DtInicio)
    LOOP

        -- Caso haja uma data de desligamento, considerar a data fim do ultimo periodo trabalhado
        -- como a data final do mes, limitando/arredondando aos 30 dias.
        --  #71671: Caso o parametro da rubrica nao permita porporcionalizacao, aplica esta regra.
        IF pRubrica.FlPropMesComercial = 'N' AND PKGPAG_VAR.vgVinculo.DtDesligamento > pFolha.DtInicioMes
            AND PKGPAG_VAR.vgVinculo.DtDesligamento <= pFolha.DtFimMes
            AND vRec.dtFim = PKGPAG_VAR.vgVinculo.DtDesligamento THEN

              vNuDiasTratados :=  pkgpag_geral.fTratarDatas(pfolha.DtInicioMes,
                                                            pfolha.DtFimMes,
                                                            vRec.dtInicio,
                                                            pFolha.DtFimMes,
                                                            vNuDiasTratadosSoma);
          ELSE

            vNuDiasTratados := pkgpag_geral.fTratarDatas(pfolha.DtInicioMes,
                                                         pfolha.DtFimMes,
                                                         vRec.dtInicio,
                                                         vRec.dtFim,
                                                         vNuDiasTratadosSoma);
        END IF;

        vNuDias :=  vNuDiasTratados.vNuDiasMes; -- vRec.DtFim - vRec.DtInicio + 1;

        vProporcional.vlIndice := vNuDiasTratados.vNuDiasTrabalhados;

         -- Atualiza o indice
         IF pkgpag_var.vgNuDiasTrabalhados != vNuDiasTratados.vNuDiasTrabalhados AND
            vNuDiasTratados.vNuDiasMes != LEAST(pkgpag_var.vgNuDiasTrabalhados,30)
           THEN
             vProporcional.vlIndice := LEAST(pkgpag_var.vgNuDiasTrabalhados, 30);
         END IF;

       --
       --  Solicitacao de Sustentacao #69806
       -- FOLHA - MATRICULA 929630-1-01 ORGAO 3802
       -- Considerar alteracao de nivel referencia e valores da tabela salarial
       --
       -- INICIA A VARIAVEL
       vValorSoma := 0;

       FOR mov IN (SELECT  ENC.NuNivelPagamento,
                                               ENC.NuReferenciaPagamento,
                                               CASE
                                                 WHEN ENC.DtInicio < vRec.dtInicio /*pFolha.DtInicioMes*/ THEN
                                                  vRec.dtInicio --pFolha.DtInicioMes
                                                 ELSE
                                                  ENC.DtInicio
                                               END AS DtInicio,
                                               CASE
                                                 WHEN ENC.DtFim > vRec.dtFIM /*pFolha.DtFimMes*/ OR ENC.DtFim IS NULL THEN
                                                  vRec.dtFIM --pFolha.DtFimMes
                                                 ELSE
                                                  ENC.DtFim
                                               END AS DtFim,
                                               EC.CDESTRUTURACARREIRA,
                                               EC.CDESTRUTURACARREIRACARREIRA
                                          FROM ECADHISTNIVELREFCEF ENC
                                         INNER JOIN ECADHISTCARGOEFETIVO CEF
                                            ON ENC.CDHISTCARGOEFETIVO = CEF.CDHISTCARGOEFETIVO
                                         INNER JOIN ECADESTRUTURACARREIRA EC
                                            ON EC.CDESTRUTURACARREIRA = CEF.CDESTRUTURACARREIRA
                                         WHERE ENC.CdHistCargoEfetivo = pCEF.CdHistCargoEfetivo
                                           AND ENC.FlAnulado = PKGPAG_TIPO.cnN
                                           AND ENC.DtInicio <= vRec.dtFIM --pFolha.DtFimMes
                                           AND (ENC.DtFim >= vRec.dtInicio/*pFolha.DtInicioMes*/ OR ENC.dtFim IS NULL) -- SE HOUVER 2 PERIODOS ABERTOS, BUSCA APENAS 0 ULTIMO PERIODO
                                         ORDER BY ENC.DTINICIO)

       LOOP

            vValorFixo := PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                                           pFolha.CdOrgao,
                                                           pFolha.NuVersaoTabcef,
                                                           pFolha.NuAnoReferencia,
                                                           pFolha.NuMesReferencia,
                                                           mov.CdEstruturaCarreira,
                                                           mov.CdEstruturaCarreiraCarreira,
                                                           MOV.NUNIVELPAGAMENTO,
                                                           MOV.Nureferenciapagamento);

            -- Caso haja uma data de desligamento, considerar a data fim do ultimo periodo trabalhado
            -- como a data final do mes, limitando/arredondando aos 30 dias.
            IF PKGPAG_VAR.vgVinculo.DtDesligamento > pFolha.DtInicioMes
              AND PKGPAG_VAR.vgVinculo.DtDesligamento <= pFolha.DtFimMes
              AND mov.dtfim = PKGPAG_VAR.vgVinculo.DtDesligamento THEN

                vNuDiasMov :=  pkgpag_geral.fTratarDatas(pfolha.DtInicioMes,
                                                         pfolha.DtFimMes,
                                                         mov.dtInicio,
                                                         pFolha.DtFimMes,
                                                         vNuDiasMovSoma);
                                          --LEAST(pFolha.DtFimMes - mov.dtinicio + 1, 30);
            ELSE
                --
                -- 9977/2017 - FOLHA - MATRICULA 314253-1-03 UDESC
                --
                vNuDiasMov :=  pkgpag_geral.fTratarDatas(pfolha.DtInicioMes,
                                                         pfolha.DtFimMes,
                                                         mov.dtInicio,
                                                         mov.dtfim,
                                                         vNuDiasMovSoma);
            END IF;

            -- Se o servidor estiver afastado o mes todo, nao gera a rubrica.
            IF NVL(pkgpag_var.vgNuDiasAfastSemRemun, 0) >= vNuDiasMov.vNuDiasMes THEN
              vNuDiasMov.vNuDiasTrabalhados := 0;
            END IF;

          vValorSoma := vValorSoma + (vValorFixo.VlFixo /vNuDiasMov.vNuDiasMes * LEAST(vProporcional.vlIndice,vNuDiasMov.vNuDiasTrabalhados));

       END LOOP;

      vVlReal := PKGPAG_VAR.vgValorFixoCEF.VlFixo*(PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO);
      --
      -- 9977/2017 - FOLHA - MATRICULA 314253-1-03 UDESC
      --
      vVlPagamento := vVlPagamento + vValorSoma *
          (PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO);
          --*
          --(vNuDiasTratados.vNuDiasTrabalhados/vNuDiasTratados.vNuDiasMes);
         --PKGPAG_VAR.vgValorFixoCEF.VlFixo*(PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO)*(vNuDias/30);

      vVlIntegral := vVlIntegral + vValorSoma *
          (PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO);
          --*
          --(vNuDiasTratados.vNuDiasTrabalhados/vNuDiasTratados.vNuDiasMes);
         --PKGPAG_VAR.vgValorFixoCEF.VlFixo*(PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO)*(vNuDias/30);

    END LOOP;

    IF vVlPagamento > 0 THEN

      PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCEF.CdVinculo,
                                            pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                            pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                            pVlIntegral           => vVlIntegral,
                                            pVlProporcional       => vVlPagamento,
                                            pVlReal               => vVlReal,
                                            pNuSufixoRubrica      => 1,
                                            pNuParcelas           => 1,
                                            pVlIndice             => vProporcional.vlIndice,
                                            pCdTipoOrigemRubrica  => 7,
                                            pDtInicio             => pCEF.DtInicio,
                                            pDtFim                => pCEF.DtFim);

    END IF;

  END IF;

END;

PROCEDURE P065066HoraAulaAtividadeUDESC (pFolha                IN PKGPAG_TIPO.rFolha,
                                    pCEF                  IN PKGPAG_TIPO.rCEF,
                                    pRubrica              IN PKGPAG_TIPO.rRubrica,
                                    pInTipoPagamento      IN INTEGER) IS

  vVlPagamento           NUMBER(13,2) DEFAULT 0;
  vVlReal                NUMBER(13,2) DEFAULT 0; -- Incluido valor real em 31/07 Solicitacao Rescisao UDESC
  vNuDias                INTEGER      DEFAULT 0;
  vNuDiasTotal           INTEGER      DEFAULT 0;
  --vNuNivelPagamento      VARCHAR2(3);
  --vNuReferenciaPagamento VARCHAR2(3);
  vNuCHO                 NUMBER(7,4);
  vProporcional          PKGPAG_TIPO.rValorPagamento;

BEGIN

  -- Define a carga horaria de acordo com o tipo de Hora: Aula ou Atividade

  IF pInTipoPagamento = 1 THEN

    vNuCHO := NVL(PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria, pCEF.NuCargaHoraria);

  ELSE

    vNuCHO := 20;

  END IF;

  ----------------------------------------------------------------
  -- Caso encontre o valor definido para a carreira do servidor
  ----------------------------------------------------------------

  IF PKGPAG_VAR.vgValorFixoCEF.VlFixo IS NOT NULL  AND
     vNuCHO > 0 THEN

    FOR vRec IN ( SELECT CASE
                           WHEN HA.DtInicio < pFolha.DtInicioMes THEN
                             pFolha.DtInicioMes
                           ELSE
                             HA.DtInicio
                           END DtInicio,
                           CASE
                             WHEN pCEF.DtFim < pFolha.DtFimMes THEN
                               pCEF.DtFim
                             WHEN HA.DtFim > pFolha.DtFimMes OR HA.DtFim IS NULL THEN
                               pFolha.DtFimMes
                           ELSE
                             HA.DtFim
                          END DtFim,
                          HA.QtHorasMensal
                     FROM ECadHistHoraAulaAtividade HA
                    WHERE HA.CdVinculo = pCEF.CdVinculo AND
                          HA.InTipoPagamento = pInTipoPagamento AND
                          HA.FlAnulado = PKGPAG_TIPO.cnN AND
                          HA.DtInicio <= pFolha.DtFimMes AND
                          (HA.DtFim >= pFolha.DtInicioMes OR HA.DtFim IS NULL)
                    ORDER BY HA.DtInicio)
    LOOP
     FOR vIndex in 1 .. 2
     LOOP

      IF vIndex = 1 THEN
        vProporcional :=
      PKGPAG_GERAL.FCalculaProporcionalidade(pFolha => pFolha,
                          pRubrica           => pRubrica ,
                          pValorIntegral     => vgVLFixoCEF, -- valor remun. tabela anterior
                          pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                          pCEF               => pCEF,
                          pDtCalculo         => pFolha.DtCalculo,
                          pEventoCEF         => PKGPAG_TIPO.cnS);
      ELSE
       vProporcional :=
      PKGPAG_GERAL.FCalculaProporcionalidade(pFolha => pFolha,
                          pRubrica           => pRubrica ,
                          pValorIntegral     => PKGPAG_VAR.vgValorFixoCEF.VlFixo,
                          pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                          pCEF               => pCEF,
                          pDtCalculo         => pFolha.DtCalculo,
                          pEventoCEF         => PKGPAG_TIPO.cnS);
          END IF;

      vNuDias := LEAST(vRec.DtFim - vRec.DtInicio + 1, vProporcional.vlIndice);
      vNuDiasTotal := vNuDiasTotal + vNuDias;

      IF vNuDiasTotal > 30 THEN

       vNuDias      := vNuDias - 1;

       vNuDiasTotal := 30;

      ELSIF pFolha.NuMesReferencia = 2 AND vNuDiasTotal = 28 OR
         pFolha.NuMesReferencia = 2 AND vNuDiasTotal = 29 THEN

       vNuDias := 30;

       vNuDiasTotal := 30;

      ELSIF pFolha.NuMesReferencia = 2 AND vRec.DtInicio > pFolha.DtInicioMes

        THEN
           IF to_char(pFolha.DtFimMes,'DD') = 29
             THEN
               vNuDias := LEAST(vNuDias + 1,30);
           ELSE
       vNuDias := LEAST(vNuDias + 2,30);
           END IF;
      else
        null;
      END IF;

      IF vIndex = 1 THEN
        vVlPagamento := vVlPagamento +

        vgVLFixoCEF*(PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO)*(6/30); -- Posteriormente, alterar o valor 6 para parametro

      ELSE
       vVlPagamento := vVlPagamento +

        PKGPAG_VAR.vgValorFixoCEF.VlFixo*(PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO)*(24/30);-- Posteriormente, alterar o valor 24 para parametro

      END IF;

      -- Incluido para calculo rescisao UDESC
        vVlReal := vVlReal +

            PKGPAG_VAR.vgValorFixoCEF.VlFixo*(PKGUTIL.FHoraMinutoParaDecimal(vRec.QtHorasMensal)/vNuCHO);

       END LOOP; /* vIndex */
    END LOOP;

    IF vVlPagamento > 0 THEN

      PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCEF.CdVinculo,
                                            pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                            pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                            pVlIntegral           => vVlPagamento,
                                            pVlProporcional       => vVlPagamento,
                                            pVlReal               => vVlReal,
                                            pNuSufixoRubrica      => 1,
                                            pNuParcelas           => 1,
                                            pVlIndice             => vNuDiasTotal,
                                            pCdTipoOrigemRubrica  => 7,
                                            pDtInicio             => pCEF.DtInicio,
                                            pDtFim                => pCEF.DtFim);

    END IF;

  END IF;

END;

PROCEDURE P070DiferencaAposentadoria(pFolha    IN PKGPAG_TIPO.rFolha,
                                     pAPO      IN PKGPAG_TIPO.rCEF,
                                     pRubrica  IN PKGPAG_TIPO.rRubrica,
                                     pFormExpr IN PKGPAG_TIPO.tFormulaCalculo) IS

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                            pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                            pCdOrgaoExercicio         => pAPO.CdOrgaoExercicio,
                                            pCdSituacaoPrevidenciaria => pAPO.CdSituacaoPrevidenciaria,
                                            pCdUnidadeOrganizacional  => pAPO.CdUnidadeOrganizacional,
                                            pCdEstruturaCarreira      => pAPO.CdEstruturaCarreira,
                                            pFlAPOOrigemCCO           => pAPO.FlOrigemCCO,
                                            pCdTipoRelacaoVinculo     => 4) THEN

    vCdExpressaoFormCalc :=

               PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                      pFormExpr                 => pFormExpr,
                                      pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                      pCdRelacaoVinculo         => 4,
                                      pCdEstruturaCarreira      => pAPO.CdEstruturaCarreira,
                                      pCdUnidadeOrganizacional  => pAPO.CdUnidadeOrganizacional);

     IF vCdExpressaoFormCalc > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pAPO.CdVinculo,
                                             pCdRelacaoVinculo     => 4,
                                             pCdHistRelacaoVinculo => pAPO.CdHistRelVinc,
                                             pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                             pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                             pVlIntegral           => NULL,
                                             pVlProporcional       => NULL,
                                             pNuSufixoRubrica      => 1,
                                             pNuParcelas           => 1,
                                             pVlIndice             => NULL,
                                             pCdTipoOrigemRubrica  => 1);

    END IF;

      END IF;

END;


PROCEDURE P090AfastServicoMilitar    (pFolha    IN PKGPAG_TIPO.rFolha,
                                      pCef      IN PKGPAG_TIPO.rCEF,
                                      pRubrica  IN PKGPAG_TIPO.rRubrica,
                                      pFormExpr IN PKGPAG_TIPO.tFormulaCalculo,
                                      pNuDias   IN integer) IS

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                      pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                      pCdOrgaoExercicio         => pCEF.CdOrgaoExercicio,
                                      pCdNaturezaVinculo        => pCEF.CdNaturezaVinculo,
                                      pCdRelacaoTrabalho        => pCEF.CdRelacaoTrabalho,
                                      pCdRegimeTrabalho         => pCEF.CdRegimeTrabalho,
                                      pCdRegimePrevidenciario   => pCEF.CdRegimePrevidenciario,
                                      pCdSituacaoPrevidenciaria => pCEF.CdSituacaoPrevidenciaria,
                                      pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional,
                                      pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

    vCdExpressaoFormCalc :=

               PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                      pFormExpr                 => pFormExpr,
                                      pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                      pCdRelacaoVinculo         => 1,
                                      pCdEstruturaCarreira      => pCef.CdEstruturaCarreira,
                                      pCdUnidadeOrganizacional  => pCef.CdUnidadeOrganizacional);

     IF vCdExpressaoFormCalc > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pCef.CdVinculo,
                                             pCdRelacaoVinculo     => 1,
                                             pCdHistRelacaoVinculo => pCef.CdHistRelVinc,
                                             pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                             pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                             pVlIntegral           => NULL,
                                             pVlProporcional       => NULL,
                                             pNuSufixoRubrica      => 1,
                                             pNuParcelas           => 1,
                                             pVlIndice             => pNuDias,
                                             pCdTipoOrigemRubrica  => 1);

    END IF;

      END IF;

END;

--
-- Versao para a SED, com regras simplificadas.
--
--

PROCEDURE PObterEnturmacaoSED (pFolha    IN PKGPAG_TIPO.rFolha,
                               pCEF      IN PKGPAG_TIPO.rCEF,
                               pRubrica  IN PKGPAG_TIPO.rRubrica) IS

   vDia                      INTEGER;
   vDiaFinal                 INTEGER;
   vDiaInicial               INTEGER;
   vDiaAfastIni              INTEGER;
   vDiaAfastFim              INTEGER;
   vDiasAfast                INTEGER;

   vTIDEnturmacao            PKGTID.tTID;
   vTIDIntervalos            PKGTID.tTID;
   vTIDIntervalosSemRemun    PKGTID.tTID;
   vTIDAfastRegra            PKGTID.tTID;
   vTIDAfastAtivEsp          PKGTID.tTID;
   vTIDAfastAulaExced        PKGTID.tTID;
   vTIDAfastSemRemun         PKGTID.tTID;

   vValores                  PKGTID.tValor;

   vCargaHoraria             INTEGER;
   vHorasEnturmacao          INTEGER;
   vAfastRegra               INTEGER;
   vAfastAtivEsp             INTEGER;
   vAfastSemRemun            INTEGER;
   vAfastAulaExced           INTEGER;

   --vResultPercentRot         INTEGER;
   vResultExcedenteRot       INTEGER;

   vResultPercentInterv      NUMBER;
   vQtdeInterv               INTEGER;
   vResultExcedenteInterv    INTEGER;
   vTotalAulasComExcInterv   INTEGER;
   vTotalAulasSemExcInterv   INTEGER;
   vInd                      INTEGER;
   vVal                      INTEGER;

   vCdRubrica01_1252         INTEGER;

   type tRecEnturmacao IS RECORD (
       DataIni              DATE,
       DataFim              DATE,
       CdDisciplina         INTEGER,
       CdArea               INTEGER,
       FlTemTurnoInterMat   INTEGER,
       CdLotacao            INTEGER,
       TotalAulas           INTEGER,
       PercentRegencia      INTEGER,
       FlAulaExcedente      CHAR);

   TYPE tTabEnturmacao      IS TABLE OF tRecEnturmacao;

   vTabEnturmacao      tTabEnturmacao;

   PROCEDURE PGratEnturmacao (PCdOrgao               IN INTEGER,
                              PDisciplina            IN INTEGER,
                              PArea                  IN INTEGER,
                              PCHO                   IN INTEGER,
                              PFlTemTurnoInterMat    IN INTEGER,
                              PCdLotacao             IN INTEGER,
                              PFlAfastado            IN INTEGER,
                              PRegimeTrabalho        IN INTEGER,
                              PCdEstruturaCarreira   IN INTEGER,
                              PResultPercent        OUT INTEGER,
                              PResultExcedente      OUT INTEGER) IS

   BEGIN

      PResultPercent :=0;
      PResultExcedente :=0;

      SELECT CASE WHEN ED.INMODALIDADE = 1
                  THEN 25
                  ELSE 40 END
        INTO PResultPercent
        FROM ECADDISCIPLINA ED
       WHERE ED.CDDISCIPLINASIRH = pDisciplina;

      IF pResultPercent = 0
        THEN
          RETURN;
      ELSIF PResultPercent = 25
         THEN
           PResultExcedente := 1;
      else
        null;
      END IF;

      EXCEPTION
        WHEN OTHERS
          THEN
            RETURN;

   END;

   FUNCTION FAulaExcedente (PTotalAula  IN INTEGER,
                            PCHO        IN INTEGER) RETURN NUMBER IS

      vTotalAula     INTEGER;

   BEGIN

      IF PCHO IS NULL THEN

         vTotalAula := 0;

      ELSE

         vTotalAula := LEAST (PTotalAula,PCHO);

         vTotalAula := vTotalAula - 0.80 * PCHO;

      END IF;

      RETURN vTotalAula;

   END;

BEGIN

   vCdRubrica01_1252 := pkgpag_geral.fretornarubrica(pCdAgrupamento => pFolha.CdAgrupamento,
                                                     pcdtiporubrica => 1,
                                                     pNuRubrica => 1252);

   IF vgPercentRegenciaClasse IS NOT NULL THEN

      -- Dados ja foram carregados para este vinculo, sair e processar o evento

      RETURN;

   END IF;

   -- Reset de valores das globais

   vgPercentRegenciaClasse   := 0;
   vgPercentRegenciaClasseSub   := 0;
   vgAulaExcedente           := 0;
   vgDiasRegencia            := 0;
   vgGratifAtivEsp           := 0;
   vgDescFormula             := '';
   vgTemRegenciaUltDiaMes    := FALSE;

   -- Buscar enturmacoes

   vTabEnturmacao := tTabEnturmacao();

   FOR REC IN ( SELECT
                    CdHistCargoEfetivo,
                    GREATEST (E.DtInicioVigencia,pFolha.DtInicioMes) as DataIni,
                    LEAST (NVL(E.DtFimVigencia,pFolha.DtFimMes),pFolha.DtFimMes) as DataFim,
                    UO.CDLOTACAOSIRH as CdLotacao,
                    CDDisciplinaSIRH as CdDisciplina,
                    CdAreaEnsinoSIRH as CdArea,
                    NVL(QTHORAAULAMAT,0)
                     + NVL(E.QTHORAAULAVESP,0)
                     + NVL(E.QTHORAAULANOT,0)
                     + NVL(E.QTHORAAULAINTERMAT,0)
                     + NVL(E.QTHORAAULAINTERVESP,0)
                     + NVL(E.QTHORAAULAINTEGRAL,0)
                      AS TotalAulas,
                    DECODE (QTHORAAULAINTERMAT,NULL,0,0,0,1) AS FlTemTurnoInterMat,
                    CASE WHEN D.INMODALIDADE = 1 THEN 25 ELSE 40 END AS PercentRegencia

                FROM EcadEnturmacao E

                INNER JOIN Ecaddisciplinaareaensino DA
                   ON DA.CdDisciplinaAreaEnsino = E.CdDisciplinaAreaEnsino

                INNER JOIN ECadDisciplina D
                   ON D.CdDisciplina = DA.CdDisciplina

                INNER JOIN ECadAreaEnsino A
                  ON A.CdAreaEnsino = DA.CdAreaEnsino

                INNER JOIN VCadUOUltimaVigencia UO
                  ON UO.CdUnidadeOrganizacional = E.CdUnidadeOrganizacional

                WHERE e.CdHistCargoEfetivo = pCEF.CdHistCargoEfetivo
                  AND E.FlEmExercicio = 'S' -- So paga Exercicio S
                  AND e.Dtiniciovigencia <= pFolha.dtFimMes
                  AND (e.DtFimvigencia >= pFolha.dtInicioMes OR e.DtFimvigencia IS NULL)
                  AND e.FLANULADO = 'N') LOOP

      -- Alimentar vetores

      vTabEnturmacao.EXTEND;
      vInd := vTabEnturmacao.LAST;
      vTabEnturmacao(vInd).DataIni            := REC.DataIni;
      vTabEnturmacao(vInd).DataFim            := REC.DataFim;
      vTabEnturmacao(vInd).CdDisciplina       := REC.CdDisciplina;
      vTabEnturmacao(vInd).CdArea             := REC.CdArea;
      vTabEnturmacao(vInd).FlTemTurnoInterMat := REC.FlTemTurnoInterMat;
      vTabEnturmacao(vInd).CdLotacao          := REC.CdLotacao;
      vTabEnturmacao(vInd).DataIni            := REC.DataIni;
      vTabEnturmacao(vInd).TotalAulas         := REC.TotalAulas;
      vTabEnturmacao(vInd).PercentRegencia    := REC.PercentRegencia;
      vTabEnturmacao(vInd).FlAulaExcedente    := CASE WHEN REC.PercentRegencia = 25 THEN 'S' ELSE 'N' END;
      vgArea := REC.CDAREA ;
      vgDisciplina := REC.CDDISCIPLINA;
      vgHorasEnturmacao := REC.TOTALAULAS;

      PKGTID.PInserir ( PTID     => vTIDEnturmacao,
                        PDataIni => REC.DataIni,
                        PDataFim => REC.DataFim,
                        PValor   => vInd);

   END LOOP;

   IF vTabEnturmacao.COUNT = 0 THEN
      RETURN;
   END IF;

   -- Buscar Afastamentos da Regra

   PKGTID.PInserir ( PTID     => vTIDAfastRegra,
                     PDataIni => pFolha.DtInicioMes,
                     PDataFim => pFolha.DtFimMes,
                     PValor   => 0);

   FOR afa IN (SELECT
                  GREATEST (A.DtInicio,pFolha.DtInicioMes) as DataIni,
                  LEAST (NVL(A.DtFim,pFolha.DtFimMes),pFolha.DtFimMes) as DataFim

              FROM EAFAAfastamentoVinculo A

              WHERE A.CdVinculo = pCEF.CdVinculo
                AND A.DtInicio <= pFolha.dtInicioMes
                AND (A.DtFim >= pFolha.dtFimMes OR A.DtFim IS NULL)
                AND A.FLANULADO = 'N'
                AND A.Cdmotivoafasttemporario IN (
                   1394,-- LICENCA ESPECIAL PARA ATENDER EXCEPCIONAL
                   1401,1455 -- LICENCA ESPECIAL PARA ATENDER MENOR ADOTADO
                   )
              ) LOOP

      PKGTID.PInserir ( PTID     => vTIDAfastRegra,
                        PDataIni => afa.DataIni,
                        PDataFim => afa.DataFim,
                        PValor   => 1);

   END LOOP;

   -- Buscar Afastamentos da Atividade Especial

   PKGTID.PInserir ( PTID     => vTIDAfastAtivEsp,
                     PDataIni => pFolha.DtInicioMes,
                     PDataFim => pFolha.DtFimMes,
                     PValor   => 0);

   FOR AFA IN (SELECT GREATEST (A.DTINICIO,PFOLHA.DTINICIOMES) AS DATAINI,
                         LEAST (NVL(A.DTFIM,PFOLHA.DTFIMMES),PFOLHA.DTFIMMES) AS DATAFIM
                    FROM EAFAAFASTAMENTOVINCULO A
                    INNER JOIN EPAGHISTRUBRICAAGRUPAMENTO HRA
                            ON HRA.CDRUBRICAAGRUPAMENTO = 10273 AND -- RUBRICA 01-0253-01 - GR DES ATIV ESPECIAL
                             ((HRA.NUANOINICIOVIGENCIA < pFolha.NuAnoReferencia OR
                              (HRA.NUANOINICIOVIGENCIA = pFolha.NuAnoReferencia AND
                               HRA.NUMESINICIOVIGENCIA <= pFolha.NuMesReferencia)) AND
                             (HRA.NUANOFIMVIGENCIA > pFolha.NuAnoReferencia OR
                             (HRA.NUANOFIMVIGENCIA = pFolha.NuAnoReferencia AND
                              HRA.NUMESFIMVIGENCIA >= pFolha.NuMesReferencia) OR
                              HRA.NUANOFIMVIGENCIA IS NULL))
                   INNER JOIN EPAGRUBAGRUPMOTAFASTTEMPIMP IMP
                           ON IMP.CDHISTRUBRICAAGRUPAMENTO = HRA.CDHISTRUBRICAAGRUPAMENTO
                    WHERE A.CDVINCULO = PCEF.CDVINCULO
                      AND A.DTINICIO <= PFOLHA.DTFIMMES
                      AND (A.DTFIM >= PFOLHA.DTINICIOMES  OR A.DTFIM IS NULL)
                      AND A.FLANULADO = 'N'
                      AND A.CDMOTIVOAFASTTEMPORARIO =  IMP.CDMOTIVOAFASTTEMPORARIO)

      LOOP

      PKGTID.PInserir ( PTID     => vTIDAfastAtivEsp,
                        PDataIni => afa.DataIni,
                        PDataFim => afa.DataFim,
                        PValor   => 1);

   END LOOP;

   -- Buscar Afastamentos Aulas Excedentes

   PKGTID.PInserir ( PTID     => vTIDAfastAulaExced,
                     PDataIni => pFolha.DtInicioMes,
                     PDataFim => pFolha.DtFimMes,
                     PValor   => 0);

   FOR AFA IN (SELECT GREATEST (A.DTINICIO,PFOLHA.DTINICIOMES) AS DATAINI,
                         LEAST (NVL(A.DTFIM,PFOLHA.DTFIMMES),PFOLHA.DTFIMMES) AS DATAFIM
                    FROM EAFAAFASTAMENTOVINCULO A
                    INNER JOIN EPAGHISTRUBRICAAGRUPAMENTO HRA
                            ON HRA.CDRUBRICAAGRUPAMENTO = 49664 AND -- RUBRICA 01-1252
                             ((HRA.NUANOINICIOVIGENCIA < pFolha.NuAnoReferencia OR
                              (HRA.NUANOINICIOVIGENCIA = pFolha.NuAnoReferencia AND
                               HRA.NUMESINICIOVIGENCIA <= pFolha.NuMesReferencia)) AND
                             (HRA.NUANOFIMVIGENCIA > pFolha.NuAnoReferencia OR
                             (HRA.NUANOFIMVIGENCIA = pFolha.NuAnoReferencia AND
                              HRA.NUMESFIMVIGENCIA >= pFolha.NuMesReferencia) OR
                              HRA.NUANOFIMVIGENCIA IS NULL))
                   INNER JOIN EPAGRUBAGRUPMOTAFASTTEMPIMP IMP
                           ON IMP.CDHISTRUBRICAAGRUPAMENTO = HRA.CDHISTRUBRICAAGRUPAMENTO
                    WHERE A.CDVINCULO = PCEF.CDVINCULO
                      AND A.DTINICIO <= PFOLHA.DTFIMMES
                      AND (A.DTFIM >= PFOLHA.DTINICIOMES  OR A.DTFIM IS NULL)
                      AND A.FLANULADO = 'N'
                      AND A.CDMOTIVOAFASTTEMPORARIO =  IMP.CDMOTIVOAFASTTEMPORARIO)

      LOOP

      PKGTID.PInserir ( PTID     => vTIDAfastAulaExced,
                        PDataIni => afa.DataIni,
                        PDataFim => afa.DataFim,
                        PValor   => 1);

   END LOOP;
   -- Buscar Afastamentos Sem Remuneracao

   vgNuDiasUteisAfa := 0;

   FOR afaSemRemun IN (SELECT
                GREATEST (A.DtInicio,pFolha.DtInicioMes) as DataIni,
                LEAST (NVL(A.DtFim,pFolha.DtFimMes),pFolha.DtFimMes) as DataFim

            FROM EAFAAfastamentoVinculo A

            WHERE A.CdVinculo = pCEF.CdVinculo
              AND A.DtInicio <= pFolha.dtFimMes
              AND (A.DtFim >= pFolha.dtInicioMes  OR A.DtFim IS NULL)
              AND A.FLANULADO = 'N'
              AND A.Cdmotivoafasttemporario in (1873, -- AUXILIO-DOENCA RGPS - SUPERIOR A 15 DIAS
                                                4628,1455) -- AUXILIO-DOENCA RGPS - SUPERIOR A 30 DIAS
            ) LOOP

      PKGTID.PInserir ( PTID     => vTIDAfastSemRemun,
                        PDataIni => afaSemRemun.DataIni,
                        PDataFim => afaSemRemun.DataFim,
                        PValor   => 1);

      vgNuDiasUteisAfa := vgNuDiasUteisAfa + PKGMOV.FQtDiaUtil(pCdAgrupamento  => pFolha.CdAgrupamento,
                                                               pCdOrgao        => pFolha.CdOrgao,
                                                               pCdUnidadeOrganizacional => pCef.CdUnidadeOrganizacional,
                                                               pDtInicio       => afaSemRemun.DataIni,
                                                               pDtFim          => afaSemRemun.DataFim,
                                                               pFlCalculoGeral => pkgpag_var.vgCalculo.flgeral);

      vDiaInicial := to_char( afaSemRemun.DataIni,'YYYYMMDD');

   END LOOP;

   -- Buscar intervalos de Carga Horaria e Enturmacao

   vTIDIntervalos := PKGTID.FIntervalos (PTID1 => vTIDEnturmacao, PTID2 => PCEF.TIDNuCargaHoraria);

   -- e Tambem de Afastamento das Regras

   vTIDIntervalos := PKGTID.FIntervalos (PTID1 => vTIDIntervalos, PTID2 => vTIDAfastRegra);

   -- e Tambem de Afastamento da Atividade Especial

   vTIDIntervalos := PKGTID.FIntervalos (PTID1 => vTIDIntervalos, PTID2 => vTIDAfastAtivEsp);

   -- e Tambem de Afastamento sem Remuneracao

   vTIDIntervalosSemRemun := PKGTID.FIntervalos (PTID1 => vTIDIntervalosSemRemun, PTID2 => vTIDAfastSemRemun);

   -- Percorrer intervalos distintos

   vDia := vTIDIntervalos.intervalos.FIRST;

   WHILE vDia IS NOT NULL LOOP

      vDiaFinal :=  TO_CHAR(vTIDIntervalos.intervalos(vDia).DtFim,'YYYYMMDD');

      vCargaHoraria := PKGTID.FConsultar (PTID => PCEF.TIDNuCargaHoraria,
                                          PData => vTIDIntervalos.intervalos (vDia).DtIni );

      vAfastRegra   := PKGTID.FConsultar (PTID => vTIDAfastRegra,
                                          PData => vTIDIntervalos.intervalos (vDia).DtIni );

      vAfastAtivEsp := PKGTID.FConsultar (PTID => vTIDAfastAtivEsp,
                                          PData => vTIDIntervalos.intervalos (vDia).DtIni );

      vAfastAulaExced := PKGTID.FConsultar (PTID => vTIDAfastAulaExced,
                                          PData => vTIDIntervalos.intervalos (vDia).DtIni );

      vValores      := PKGTID.FConsultarValores (PTID => vTIDEnturmacao, PData => vTIDIntervalos.intervalos (vDia).DtIni );

      -- Se tem afastamento sem remuneracao desconsidera periodo
      vAfastSemRemun := PKGTID.FConsultar (PTID => vTIDAfastSemRemun,
                                           PData => vTIDIntervalos.intervalos (vDia).DtIni );

      IF vValores IS NOT NULL

        THEN
      --IF vValores IS NOT NULL THEN -- Verifica se tem enturmacao (quando inicia no meio do mes nao tem no primeiro intervalo, por exemplo

        vVal := vValores.FIRST;

        -- Dentro do mesmo intervalo, mais de uma Enturmacao
        -- Verificar valores pois pode ter mais de uma enturmacao

        vResultPercentInterv    := 0;
        vResultExcedenteInterv  := 0;
        vTotalAulasComExcInterv := 0;
        vTotalAulasSemExcInterv := 0;
        vQtdeInterv             := 0;

        vgDescFormula := vgDescFormula
                      || 'D' || LPAD (TO_CHAR ( vTIDIntervalos.intervalos (vDia).DtIni,'DD'),2,'0')
                      || '-' || LPAD (TO_CHAR ( vTIDIntervalos.intervalos (vDia).DtFim,'DD'),2,'0')
                      || '[';

        vHorasEnturmacao := 0;

        WHILE vVal IS NOT NULL LOOP

          vInd := vValores (vVal);

          vQtdeInterv := vQtdeInterv + 1;

          vHorasEnturmacao := vHorasEnturmacao + vTabEnturmacao(vInd).TotalAulas;

          vgDescFormula := vgDescFormula
                        || 'A' || vTabEnturmacao(vInd).CdArea
                        || ' D' || vTabEnturmacao(vInd).CdDisciplina
                        || '='  || REPLACE (TO_CHAR (vTabEnturmacao(vInd).PercentRegencia),'.',',') || '%'
                        || ' '  || REPLACE (vTabEnturmacao(vInd).TotalAulas,'.',',') || 'H'
                        || ' E' || vResultExcedenteRot;
          -- Obtem maior percentual quando mais de uma Enturmacao

          IF vTabEnturmacao(vInd).PercentRegencia IS NOT NULL THEN
            vResultPercentInterv := vResultPercentInterv + vTabEnturmacao(vInd).PercentRegencia;
          END IF;

          -- Soma horas excedentes quando mais de uma Enturmacao

          IF vTabEnturmacao(vInd).FlAulaExcedente = 'S'
             AND vAfastAulaExced = 0  THEN

             vTotalAulasComExcInterv := vTotalAulasComExcInterv + vTabEnturmacao(vInd).TotalAulas;

          ELSE

             vTotalAulasSemExcInterv := vTotalAulasSemExcInterv + vTabEnturmacao(vInd).TotalAulas;

          END IF;

          vVal := vValores.NEXT (vVal);

          IF vVal IS NOT NULL THEN
            vgDescFormula := vgDescFormula || ';';
          END IF;

        END LOOP;
        --
        -- SOMENTE PAGAR REGENCIA DE CLASSE (01-0142) PARA OS SERVIDORES QUE TIVEREM NO MINIMO
        -- A QUANTIDADE DE AULAS POR CARGA HORARIA CONFORME ABAIXO:
        -- 40 >= 32; 30 >= 24; 20 >= 16; 10 >= 8
        -- Chamado 7305/2015
        --
        IF vHorasEnturmacao < (vCargaHoraria * 0.8)
         THEN
            vResultPercentInterv := 0;
        END IF;

        IF vResultPercentInterv > 0 THEN -- Calcula a Media
           vResultPercentInterv := vResultPercentInterv / vQtdeInterv;
        END IF;

        -- Checa horas excedentes da enturmacao para quem tem regencia 25%

        IF vTabEnturmacao(vInd).FlAulaExcedente = 'S'
          THEN
            vResultExcedenteInterv := FAulaExcedente (PTotalAula  => vTotalAulasComExcInterv,
                                                      PCHO        => vCargaHoraria - vTotalAulasSemExcInterv );
        END IF;

        IF NVL(vResultExcedenteInterv,0) <= 0
          THEN -- Se negativo, nao cumpriu carga horaria da enturmacao
             vResultExcedenteInterv := 0;
        END IF;

        -- Soma intervalos ao total

        if vDiaInicial is not null and vDiaInicial between vDia and vDiaFinal -- NVL(vgNuDiasUteisAfa,0) > 0 --tSemRemun is not null -- Descontar dias de afastamento sem remuneracao.
            then
               case
                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtIni >= vTIDIntervalos.intervalos(vDia).DtIni
                   then
                     vDiaAfastIni := to_char(vTIDAfastSemRemun.intervalos(vDiaInicial).DtIni,'YYYYMMDD');

                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtIni < vTIDIntervalos.intervalos(vDia).DtIni
                    then
                      vDiaAfastIni := to_char(vTIDIntervalos.intervalos(vDia).DtIni,'YYYYMMDD');
               end case;

               case
                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtFim > vTIDIntervalos.intervalos(vDia).DtFim
                   then
                     vDiaAfastFim := to_char(vTIDIntervalos.intervalos(vDia).DtFim,'YYYYMMDD');

                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtFim <= vTIDIntervalos.intervalos(vDia).DtFim
                    then
                      vDiaAfastFim := to_char(vTIDAfastSemRemun.intervalos(vDiaInicial).DtFim,'YYYYMMDD');
               end case;

               vDiasAfast := vDiaAfastFim - vDiaAfastIni + 1;

               vgPercentRegenciaClasse   := vgPercentRegenciaClasse
                   + vResultPercentInterv   * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1 - vDiasAfast);

               vgAulaExcedente           := vgAulaExcedente
                   + vResultExcedenteInterv * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1 - vDiasAfast);

               vgDiasRegencia            := vgDiasRegencia
                   + (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1 - vDiasAfast);

           else

              vgPercentRegenciaClasse   := vgPercentRegenciaClasse
                   + vResultPercentInterv   * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

              vgAulaExcedente           := vgAulaExcedente
                   + vResultExcedenteInterv * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

              vgDiasRegencia            := vgDiasRegencia
                   + (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

          end if;

          IF pFolha.DtFimMes BETWEEN vTIDIntervalos.intervalos (vDia).DtIni AND vTIDIntervalos.intervalos (vDia).DtFim THEN

             vgTemRegenciaUltDiaMes := TRUE;

             -- Tratar mes com menos de 30 dias
             IF TO_CHAR(pFolha.DtFimMes,'DD') < 30
               THEN
                 vgPercentRegenciaClasse := vgPercentRegenciaClasse +
                                            vResultPercentInterv * (30 - TO_CHAR(pFolha.DtFimMes,'DD'));

                 vgAulaExcedente := vgAulaExcedente +
                                    vResultExcedenteInterv * (30 - TO_CHAR(pFolha.DtFimMes,'DD'));

                 IF pRubrica.CdRubricaAgrupamento NOT IN (vCdRubrica01_1252) THEN
                   vgDiasRegencia := vgDiasRegencia + (30 - TO_CHAR(pFolha.DtFimMes,'DD'));
                 END IF;

             -- Para os afastados com mes de 31 dias ajustar os dias da regencia
             -- Favelao
             ELSIF TO_CHAR(pFolha.DtFimMes,'DD') = 31
               AND vDiasAfast > 0
               AND SUBSTR(vDiaAfastFim,7,2) < 31
                THEN
                  vgPercentRegenciaClasse := vgPercentRegenciaClasse +
                                            (vResultPercentInterv * -1);

                  vgAulaExcedente := vgAulaExcedente +
                                    (vResultExcedenteInterv * (-1));

                  vgDiasRegencia := (vgDiasRegencia -1);

             else
               null;
             END IF;

          END IF;

          IF vAfastAtivEsp = 0 THEN -- Nao esta afastado, recebe gratificacao especial

             vgGratifAtivEsp           := vgGratifAtivEsp
                   + vResultExcedenteInterv * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

          END IF;

      END IF;

      vgDescFormula := vgDescFormula || '] ';

      vDia := vTIDIntervalos.intervalos.NEXT (vDia);

   END LOOP;

   ---------------------------------------------------

   IF vgDiasRegencia > 0 THEN

     vgPercentRegenciaClasse := vgPercentRegenciaClasse / vgDiasRegencia;
     vgAulaExcedente         := vgAulaExcedente         / vgDiasRegencia;
     vgGratifAtivEsp         := vgGratifAtivEsp         / vgDiasRegencia;

   END IF;

END;

/*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Obter informacoes sobre Regencia de Classe, aulas excedentes e gratif. des. ativ. especial
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PObterEnturmacao (pFolha    IN PKGPAG_TIPO.rFolha,
                            pCEF      IN PKGPAG_TIPO.rCEF) IS

   vDia                      INTEGER;
   vDiaFinal                 INTEGER;
   vDiaInicial               INTEGER;
   vDiaAfastIni              INTEGER;
   vDiaAfastFim              INTEGER;
   vDiasAfast                INTEGER;

   vTIDEnturmacao            PKGTID.tTID;
   vTIDIntervalos            PKGTID.tTID;
   vTIDIntervalosSemRemun    PKGTID.tTID;
   vTIDAfastRegra            PKGTID.tTID;
   vTIDAfastAtivEsp          PKGTID.tTID;
   vTIDAfastSemRemun         PKGTID.tTID;

   vValores                  PKGTID.tValor;

   vCargaHoraria             INTEGER;
   vAfastRegra               INTEGER;
   vAfastAtivEsp             INTEGER;
   vAfastSemRemun            INTEGER;

   vResultPercentRot         INTEGER;
   vResultExcedenteRot       INTEGER;

   vResultPercentInterv      NUMBER;
   vQtdeInterv               INTEGER;
   vResultExcedenteInterv    INTEGER;
   vTotalAulasComExcInterv   INTEGER;
   vTotalAulasSemExcInterv   INTEGER;
   vInd                      INTEGER;
   vVal                      INTEGER;

   type tRecEnturmacao IS RECORD (
       DataIni              DATE,
       DataFim              DATE,
       CdDisciplina         INTEGER,
       CdArea               INTEGER,
       FlTemTurnoInterMat   INTEGER,
       CdLotacao            INTEGER,
       TotalAulas           INTEGER);

   TYPE tTabEnturmacao      IS TABLE OF tRecEnturmacao;

   vTabEnturmacao      tTabEnturmacao;

   PROCEDURE PGratEnturmacao (PCdOrgao               IN INTEGER,
                              PDisciplina            IN INTEGER,
                              PArea                  IN INTEGER,
                              PCHO                   IN INTEGER,
                              PFlTemTurnoInterMat    IN INTEGER,
                              PCdLotacao             IN INTEGER,
                              PFlAfastado            IN INTEGER,
                              PRegimeTrabalho        IN INTEGER,
                              PCdEstruturaCarreira   IN INTEGER,
                              PResultPercent        OUT INTEGER,
                              PResultExcedente      OUT INTEGER) IS

      C_NAO_PAGA    CONSTANT INTEGER := 0;
      C_VALOR_MENOR CONSTANT INTEGER := 25;
      C_VALOR_MAIOR CONSTANT INTEGER := 40;

      C_CARGO_464  CONSTANT INTEGER := 67795;
      C_CARGO_465   CONSTANT INTEGER := 67792;

      C_CARGO_701_1 CONSTANT INTEGER := 59757;
      C_CARGO_701_2 CONSTANT INTEGER := 59785;
      C_CARGO_701_3 CONSTANT INTEGER := 59816;
      C_CARGO_701_4 CONSTANT INTEGER := 59838;
      C_CARGO_701_5 CONSTANT INTEGER := 59880;
      C_CARGO_701_6 CONSTANT INTEGER := 60001;
      C_CARGO_701_7 CONSTANT INTEGER := 67788;
      C_CARGO_701_8 CONSTANT INTEGER := 68000;
      C_CARGO_701_9 CONSTANT INTEGER := 69178;

   BEGIN  -- NOVO ALTERADO PARA TRATAR EXCECOES DA SED

      --pResultExcedente := 0;
      --PResultPercent   := C_NAO_PAGA;
      pResultExcedente := 1;
      PResultPercent   := C_VALOR_MENOR;

      IF pDisciplina in (0211,0214,0265,0941,1001,2841,1155,1302,1344,2473) AND pArea IN (1,2,3,6)
         OR (pDisciplina IN (0265,0371,1810,1811,1812,1884,1885,3356) and pArea = 5)
         OR (pDisciplina = 2142 and pArea = 2)
         OR (pDisciplina IN (1125,1701) )
         OR (pDisciplina IN (3496,3497) and pArea = 3 and PCHO = 40 and PFlTemTurnoInterMat = 1)
         OR (pDisciplina IN (2907,3449) and pArea = 6) THEN

         PResultPercent   := C_VALOR_MAIOR;
         pResultExcedente := 0;

      ELSIF pDisciplina = 1835 and pArea = 5 THEN

         PResultPercent   := C_VALOR_MENOR;
         pResultExcedente := 1;

      ELSIF pDisciplina = 1881 THEN

         IF pArea = 1 AND PCHO IN (10,30) THEN

             PResultPercent   := C_VALOR_MENOR;
             pResultExcedente := 1;

         ELSIF pArea = 6 AND PCHO IN (10,30) THEN

             PResultPercent   := C_VALOR_MENOR;
             pResultExcedente := 0;

         ELSIF pArea IN (1,6) AND PCHO IN (20,40) THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

         ELSE

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

         END IF;

      ELSIF pArea IN (1,4) AND PCdLotacao = 740000000190 AND PFlAfastado = 1 THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF (pDisciplina IN (3507,3508) and pArea = 6) THEN

             PResultPercent   := C_VALOR_MENOR;
             PResultExcedente := 0;

      ELSIF pArea IN (2,3) AND PCdLotacao = 740000000190 AND PFlAfastado = 1 THEN

             PResultPercent   := C_VALOR_MENOR;
             pResultExcedente := 1;

      ELSIF pArea = 7 THEN

             PResultPercent   := C_VALOR_MENOR;
             PResultExcedente := 0;

      ELSIF (pDisciplina IN (1133,1134,1135,1129,1130) and pArea = 6)
         OR (pDisciplina = 1130 and pArea = 3)
         OR (pDisciplina IN (1136,1137) and pArea = 2)  THEN

             PResultPercent   := C_NAO_PAGA;

      ELSIF pDisciplina IN (1110,1111,1112,1113,1114,1115,1116,1117,1118,1119,1157,
                            1190,1191,1148,1252,1279,1722,1723,1725,1726,1727,1753,1754,1731,1732,
                            1735,1736,1738,1739,1742,1743,1744,1745,1747,1748,1752,1792,1793,1794,
                            1799,1801,2196) THEN

             PResultPercent   := C_NAO_PAGA;

      ELSIF pDisciplina IN (1155,2837,2838,2839,2840,2841)
         OR (pDisciplina = 1124 and pArea = 6) THEN

             PResultPercent   := C_VALOR_MENOR;
             PResultExcedente := 0;

      ELSIF pDisciplina = 1123 and PCHO IN (10,30) THEN

             PResultPercent   := C_VALOR_MENOR;
             PResultExcedente := 0;

      ELSIF pDisciplina = 1123 and PCHO IN (20,40) THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF PArea = 6 AND pCdLotacao IN (758007002580,758007002660,758007002740,763007004010,
                                         777007002150,752007000880,752007000960,764007004280,767007005090,
                                         776001405700,759007003040,758007002580,758007002660,
                                         758007002740,801001397260,802001405620,763007004010,777007002150,
                                         755007001850,770001408480,765001396450,762001397180,779007030520,
                                         769007030600,751007000700,752001396530,752007000880,752007000960,
                                         764007004280,767007005090,803001404810) THEN

             PResultPercent   := C_VALOR_MENOR;
             PResultExcedente := 0;

      ELSIF PArea = 6 AND pCdLotacao IN (752007000881,764007004282) THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF PRegimeTrabalho = 1 AND PCdLotacao IN (751007000700,755007001850,75900700303040,
                                                   764007004281,779007030520,769007030600,764007013940) THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF PDisciplina = 0001 and PArea = 1 AND PRegimeTrabalho = 2 and pCdEstruturaCarreira = C_CARGO_465 THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF PDisciplina IN (3331,3311) and PArea = 1
        AND pCdEstruturaCarreira IN (C_CARGO_701_1,C_CARGO_701_2,C_CARGO_701_3,C_CARGO_701_4,
                                     C_CARGO_701_5,C_CARGO_701_6,C_CARGO_701_7,C_CARGO_701_8,
                                     C_CARGO_701_9,C_CARGO_464,C_CARGO_465) THEN

             PResultPercent   := C_VALOR_MENOR;
             PResultExcedente := 0;

      ELSIF PDisciplina = 1198 AND PArea = 5 AND PCdOrgao = 42 THEN  -- FCEE

             PResultPercent   := C_VALOR_MENOR;
             pResultExcedente := 1;

      ELSIF PDisciplina = 0001 and PArea = 6 THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF PArea in (1,4,5) AND PDisciplina NOT IN (0307,0319,0628) THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF (pDisciplina = 1334 and pArea = 6)
         OR (pDisciplina IN (1344,1886,2148) and pArea in (2,3) )
         OR (PDisciplina IN (1886,2148) and pArea = 6) THEN

             PResultPercent   := C_VALOR_MAIOR;
             pResultExcedente := 0;

      ELSIF pDisciplina IN (0307,0319,0628,1198,2204) THEN

             PResultPercent   := C_VALOR_MENOR;

             -- Incluindo tentando corrigir.
             pResultExcedente := 1;

      ELSIF PArea IN (2,3,6) AND PDisciplina <> 0001 THEN

             PResultPercent   := C_VALOR_MENOR;

             IF PDisciplina IN (1121,1122) AND Parea IN (2,3) AND PCdLotacao NOT IN (779007043420,807007011900,809007032810,806007008430,
                                                                                     808007043180,805007043000,811007008000,810007043500) THEN

                 pResultExcedente := 1;

             END IF;

      else
        null;
      END IF;

   END;

   FUNCTION FAulaExcedente (PTotalAula  IN INTEGER,
                            PCHO        IN INTEGER) RETURN NUMBER IS

      vTotalAula     INTEGER;

   BEGIN

      IF PCHO IS NULL THEN

         vTotalAula := 0;

      ELSE

         -- Verificar a quantidade de horas excedentes a serem pagas

         vTotalAula := LEAST (PTotalAula,PCHO);

         vTotalAula := vTotalAula - 0.80 * PCHO;
     /* -- Retorna negativo para indicar que a carga horaria da enturmacao nao foi cumprida
         IF vTotalAula < 0 THEN
            vTotalAula := 0;
         END IF;
     */
      END IF;

      RETURN vTotalAula;

   END;

BEGIN

   IF vgPercentRegenciaClasse IS NOT NULL THEN

      -- Dados ja foram carregados para este vinculo, sair e processar o evento

      RETURN;

   END IF;

   -- Reset de valores das globais

   vgPercentRegenciaClasse   := 0;
   vgPercentRegenciaClasseSub   := 0;
   vgAulaExcedente           := 0;
   vgDiasRegencia            := 0;
   vgGratifAtivEsp           := 0;
   vgDescFormula             := '';
   vgTemRegenciaUltDiaMes    := FALSE;

   -- Buscar enturmacoes

   vTabEnturmacao := tTabEnturmacao();

   FOR REC IN ( SELECT
                    CdHistCargoEfetivo,
                    GREATEST (E.DtInicioVigencia,pFolha.DtInicioMes) as DataIni,
                    LEAST (NVL(E.DtFimVigencia,pFolha.DtFimMes),pFolha.DtFimMes) as DataFim,
                    UO.CDLOTACAOSIRH as CdLotacao,
                    CDDisciplinaSIRH as CdDisciplina,
                    CdAreaEnsinoSIRH as CdArea,
                    NVL(QTHORAAULAMAT,0)
                     + NVL(QTHORAAULAVESP,0)
                     + NVL(QTHORAAULANOT,0)
                     + NVL(QTHORAAULAINTERMAT,0)
                     + NVL(QTHORAAULAINTERVESP,0)
                      AS TotalAulas,
                    DECODE (QTHORAAULAINTERMAT,NULL,0,0,0,1) AS FlTemTurnoInterMat

                FROM EcadEnturmacao E

                INNER JOIN Ecaddisciplinaareaensino DA
                   ON DA.CdDisciplinaAreaEnsino = E.CdDisciplinaAreaEnsino

                INNER JOIN ECadDisciplina D
                   ON D.CdDisciplina = DA.CdDisciplina

                INNER JOIN ECadAreaEnsino A
                  ON A.CdAreaEnsino = DA.CdAreaEnsino

                INNER JOIN VCadUOUltimaVigencia UO
                  ON UO.CdUnidadeOrganizacional = E.CdUnidadeOrganizacional

                WHERE e.CdHistCargoEfetivo = pCEF.CdHistCargoEfetivo
                  AND E.FlEmExercicio = 'S' -- So paga Exercicio S
                  AND e.Dtiniciovigencia <= pFolha.dtFimMes
                  AND (e.DtFimvigencia >= pFolha.dtInicioMes OR e.DtFimvigencia IS NULL)
                  AND e.FLANULADO = 'N') LOOP

      -- Alimentar vetores

      vTabEnturmacao.EXTEND;
      vInd := vTabEnturmacao.LAST;
      vTabEnturmacao(vInd).DataIni            := REC.DataIni;
      vTabEnturmacao(vInd).DataFim            := REC.DataFim;
      vTabEnturmacao(vInd).CdDisciplina       := REC.CdDisciplina;
      vTabEnturmacao(vInd).CdArea             := REC.CdArea;
      vTabEnturmacao(vInd).FlTemTurnoInterMat := REC.FlTemTurnoInterMat;
      vTabEnturmacao(vInd).CdLotacao          := REC.CdLotacao;
      vTabEnturmacao(vInd).DataIni            := REC.DataIni;
      vTabEnturmacao(vInd).TotalAulas         := REC.TotalAulas;
      vgArea := REC.CDAREA ;
      vgDisciplina := REC.CDDISCIPLINA;
      vgHorasEnturmacao := REC.TOTALAULAS;

      PKGTID.PInserir ( PTID     => vTIDEnturmacao,
                        PDataIni => REC.DataIni,
                        PDataFim => REC.DataFim,
                        PValor   => vInd);

   END LOOP;

   IF vTabEnturmacao.COUNT = 0 THEN
      RETURN;
   END IF;

   -- Buscar Afastamentos da Regra

   PKGTID.PInserir ( PTID     => vTIDAfastRegra,
                     PDataIni => pFolha.DtInicioMes,
                     PDataFim => pFolha.DtFimMes,
                     PValor   => 0);

   FOR afa IN (SELECT
                  GREATEST (A.DtInicio,pFolha.DtInicioMes) as DataIni,
                  LEAST (NVL(A.DtFim,pFolha.DtFimMes),pFolha.DtFimMes) as DataFim

              FROM EAFAAfastamentoVinculo A

              WHERE A.CdVinculo = pCEF.CdVinculo
                AND A.DtInicio <= pFolha.dtInicioMes
                AND (A.DtFim >= pFolha.dtFimMes OR A.DtFim IS NULL)
                AND A.FLANULADO = 'N'
                AND A.Cdmotivoafasttemporario IN (
                   1394,-- LICENCA ESPECIAL PARA ATENDER EXCEPCIONAL
                   1401,1455 -- LICENCA ESPECIAL PARA ATENDER MENOR ADOTADO
                   )
              ) LOOP

      PKGTID.PInserir ( PTID     => vTIDAfastRegra,
                        PDataIni => afa.DataIni,
                        PDataFim => afa.DataFim,
                        PValor   => 1);

   END LOOP;

   -- Buscar Afastamentos da Atividade Especial

   PKGTID.PInserir ( PTID     => vTIDAfastAtivEsp,
                     PDataIni => pFolha.DtInicioMes,
                     PDataFim => pFolha.DtFimMes,
                     PValor   => 0);

   /*FOR afa IN (SELECT
                GREATEST (A.DtInicio,pFolha.DtInicioMes) as DataIni,
                LEAST (NVL(A.DtFim,pFolha.DtFimMes),pFolha.DtFimMes) as DataFim

            FROM EAFAAfastamentoVinculo A

            WHERE A.CdVinculo = pCEF.CdVinculo
              AND A.DtInicio <= pFolha.dtFimMes
              AND (A.DtFim >= pFolha.dtInicioMes  OR A.DtFim IS NULL)
              AND A.FLANULADO = 'N'
              AND A.Cdmotivoafasttemporario IN (
                  1268,-- DESINCOMPATIBILIZACAO - LICENCA  PARA  CONCORRER A CARGO ELETIVO
                  1307,-- GOZO - LICENCA PREMIO
                  1338,-- LICENCA PARA SERVICO MILITAR OBRIGATORIO - COM REMUNERACAO
                  1422,-- LICENCA PARA REPOUSO A GESTANTE - CONCESSAO ANTES DO NASCIMENTO
                  1470,-- LUTO
                  1478,-- NUPCIAS
                  1867,-- AGUARDANDO PROCESSO DE APOSENTADORIA
                  1869,-- LICENCA DECORRENTE DE ACIDENTE EM SERVICO
                  1872,-- AUXILIO-DOENCA RGPS - ATE 15 DIAS
                  1875,-- LICENCA PARA TRATAMENTO DE SAUDE
                  1888,-- LICENCA TRATAMENTO PESSOA DA FAMILIA
                  2489,-- LICENCA PATERNIDADE
                  2490,-- LICENCA PATERNIDADE - GUARDA EXCLUSIVA
                  2647,-- CONSIDERADO DEFINITIVAMENTE INVALIDO
                  2648,-- LICENCA PARA REPOUSO A GESTANTE - CONCESSAO APOS NASCIMENTO
                  3567,-- CURSO DE POS GRADUACAO INTEGRAL - UDESC
                  3627,-- SALARIO MATERNIDADE - CONCESSAO ANTES DO NASCIMENTO / RGPS 60 DIAS
                  3647,-- SALARIO MATERNIDADE - CONCESSAO APOS O NASCIMENTO / RGPS 60 DIAS
                  3887,-- AFASTAMENTO DO PAIS PARA FREQUENTAR CURSO/EVENTO - COM ONUS LIMITADO
                  3888,-- AFASTAMENTO DO PAIS PARA FREQUENTAR CURSO/EVENTO - COM ONUS PARA O ESTADO
                  4627 -- AUXILIO-DOENCA RGPS - ATE 30 DIAS
                 )
            ) LOOP     */

   FOR AFA IN (SELECT GREATEST (A.DTINICIO,PFOLHA.DTINICIOMES) AS DATAINI,
                         LEAST (NVL(A.DTFIM,PFOLHA.DTFIMMES),PFOLHA.DTFIMMES) AS DATAFIM
                    FROM EAFAAFASTAMENTOVINCULO A
                    INNER JOIN EPAGHISTRUBRICAAGRUPAMENTO HRA
                            ON HRA.CDRUBRICAAGRUPAMENTO = 10273 AND -- RUBRICA 01-0253-01 - GR DES ATIV ESPECIAL
                             ((HRA.NUANOINICIOVIGENCIA < pFolha.NuAnoReferencia OR
                              (HRA.NUANOINICIOVIGENCIA = pFolha.NuAnoReferencia AND
                               HRA.NUMESINICIOVIGENCIA <= pFolha.NuMesReferencia)) AND
                             (HRA.NUANOFIMVIGENCIA > pFolha.NuAnoReferencia OR
                             (HRA.NUANOFIMVIGENCIA = pFolha.NuAnoReferencia AND
                              HRA.NUMESFIMVIGENCIA >= pFolha.NuMesReferencia) OR
                              HRA.NUANOFIMVIGENCIA IS NULL))
                   INNER JOIN EPAGRUBAGRUPMOTAFASTTEMPIMP IMP
                           ON IMP.CDHISTRUBRICAAGRUPAMENTO = HRA.CDHISTRUBRICAAGRUPAMENTO
                    WHERE A.CDVINCULO = PCEF.CDVINCULO
                      AND A.DTINICIO <= PFOLHA.DTFIMMES
                      AND (A.DTFIM >= PFOLHA.DTINICIOMES  OR A.DTFIM IS NULL)
                      AND A.FLANULADO = 'N'
                      AND A.CDMOTIVOAFASTTEMPORARIO =  IMP.CDMOTIVOAFASTTEMPORARIO)

      LOOP

      PKGTID.PInserir ( PTID     => vTIDAfastAtivEsp,
                        PDataIni => afa.DataIni,
                        PDataFim => afa.DataFim,
                        PValor   => 1);

   END LOOP;

  -- Buscar Afastamentos Sem Remuneracao

 /*  PKGTID.PInserir ( PTID     => vTIDAfastSemRemun,
                     PDataIni => pFolha.DtInicioMes,
                     PDataFim => pFolha.DtFimMes,
                     PValor   => 0);
   */

   vgNuDiasUteisAfa := 0;

   FOR afaSemRemun IN (SELECT
                GREATEST (A.DtInicio,pFolha.DtInicioMes) as DataIni,
                LEAST (NVL(A.DtFim,pFolha.DtFimMes),pFolha.DtFimMes) as DataFim

            FROM EAFAAfastamentoVinculo A

            WHERE A.CdVinculo = pCEF.CdVinculo
              AND A.DtInicio <= pFolha.dtFimMes
              AND (A.DtFim >= pFolha.dtInicioMes  OR A.DtFim IS NULL)
              AND A.FLANULADO = 'N'
              AND A.Cdmotivoafasttemporario in (1873, -- AUXILIO-DOENCA RGPS - SUPERIOR A 15 DIAS
                                                4628,1455) -- AUXILIO-DOENCA RGPS - SUPERIOR A 30 DIAS
            ) LOOP

      PKGTID.PInserir ( PTID     => vTIDAfastSemRemun,
                        PDataIni => afaSemRemun.DataIni,
                        PDataFim => afaSemRemun.DataFim,
                        PValor   => 1);

      vgNuDiasUteisAfa := vgNuDiasUteisAfa + PKGMOV.FQtDiaUtil(pCdAgrupamento  => pFolha.CdAgrupamento,
                                                               pCdOrgao        => pFolha.CdOrgao,
                                                               pCdUnidadeOrganizacional => pCef.CdUnidadeOrganizacional,
                                                               pDtInicio       => afaSemRemun.DataIni,
                                                               pDtFim          => afaSemRemun.DataFim,
                                                               pFlCalculoGeral => pkgpag_var.vgCalculo.flgeral);

      vDiaInicial := to_char( afaSemRemun.DataIni,'YYYYMMDD');

   END LOOP;

   -- Buscar intervalos de Carga Horaria e Enturmacao

   vTIDIntervalos := PKGTID.FIntervalos (PTID1 => vTIDEnturmacao, PTID2 => PCEF.TIDNuCargaHoraria);

   -- e Tambem de Afastamento das Regras

   vTIDIntervalos := PKGTID.FIntervalos (PTID1 => vTIDIntervalos, PTID2 => vTIDAfastRegra);

   -- e Tambem de Afastamento da Atividade Especial

   vTIDIntervalos := PKGTID.FIntervalos (PTID1 => vTIDIntervalos, PTID2 => vTIDAfastAtivEsp);

  -- e Tambem de Afastamento sem Remuneracao

   vTIDIntervalosSemRemun := PKGTID.FIntervalos (PTID1 => vTIDIntervalosSemRemun, PTID2 => vTIDAfastSemRemun);

   -- Percorrer intervalos distintos

   vDia := vTIDIntervalos.intervalos.FIRST;

   WHILE vDia IS NOT NULL LOOP

      vDiaFinal :=  TO_CHAR(vTIDIntervalos.intervalos(vDia).DtFim,'YYYYMMDD');

      vCargaHoraria := PKGTID.FConsultar (PTID => PCEF.TIDNuCargaHoraria,
                                          PData => vTIDIntervalos.intervalos (vDia).DtIni );

      vAfastRegra   := PKGTID.FConsultar (PTID => vTIDAfastRegra,
                                          PData => vTIDIntervalos.intervalos (vDia).DtIni );

      vAfastAtivEsp := PKGTID.FConsultar (PTID => vTIDAfastAtivEsp,
                                          PData => vTIDIntervalos.intervalos (vDia).DtIni );

      vValores      := PKGTID.FConsultarValores (PTID => vTIDEnturmacao, PData => vTIDIntervalos.intervalos (vDia).DtIni );

      -- Se tem afastamento sem remuneracao desconsidera periodo
      vAfastSemRemun := PKGTID.FConsultar (PTID => vTIDAfastSemRemun,
                                           PData => vTIDIntervalos.intervalos (vDia).DtIni );

      IF vValores IS NOT NULL

        THEN
      --IF vValores IS NOT NULL THEN -- Verifica se tem enturmacao (quando inicia no meio do mes nao tem no primeiro intervalo, por exemplo

        vVal := vValores.FIRST;

        -- Dentro do mesmo intervalo, mais de uma Enturmacao
        -- Verificar valores pois pode ter mais de uma enturmacao

        vResultPercentInterv    := 0;
        vResultExcedenteInterv  := 0;
        vTotalAulasComExcInterv := 0;
        vTotalAulasSemExcInterv := 0;
        vQtdeInterv             := 0;

        vgDescFormula := vgDescFormula
                      || 'D' || LPAD (TO_CHAR ( vTIDIntervalos.intervalos (vDia).DtIni,'DD'),2,'0')
                      || '-' || LPAD (TO_CHAR ( vTIDIntervalos.intervalos (vDia).DtFim,'DD'),2,'0')
                      || '[';

        WHILE vVal IS NOT NULL LOOP

          vInd := vValores (vVal);

          vQtdeInterv := vQtdeInterv + 1;

          PGratEnturmacao (PCdOrgao               => PKGPAG_VAR.vgFolha.CdOrgao,
                           PDisciplina            => vTabEnturmacao(vInd).CdDisciplina,
                           PArea                  => vTabEnturmacao(vInd).CdArea,
                           PCHO                   => vCargaHoraria,
                           PFlTemTurnoInterMat    => vTabEnturmacao(vInd).FlTemTurnoInterMat,
                           PCdLotacao             => vTabEnturmacao(vInd).CdLotacao,
                           PFlAfastado            => vAfastRegra,
                           PRegimeTrabalho        => PKGPAG_VAR.vgVinculo.CdRegimeTrabalho,
                           PCdEstruturaCarreira   => PCEF.CdEstruturaCarreira,
                           PResultPercent         => vResultPercentRot,
                           PResultExcedente       => vResultExcedenteRot);

          vgDescFormula := vgDescFormula
                        || 'A' || vTabEnturmacao(vInd).CdArea
                        || ' D' || vTabEnturmacao(vInd).CdDisciplina
                        || '='  || REPLACE (TO_CHAR (vResultPercentRot),'.',',') || '%'
                        || ' '  || REPLACE (vTabEnturmacao(vInd).TotalAulas,'.',',') || 'H'
                        || ' E' || vResultExcedenteRot;
          -- Obtem maior percentual quando mais de uma Enturmacao

          IF vResultPercentRot IS NOT NULL THEN
            vResultPercentInterv := vResultPercentInterv + vResultPercentRot;
          END IF;

          -- Soma horas excedentes quando mais de uma Enturmacao

          IF vResultExcedenteRot = 1 THEN

             vTotalAulasComExcInterv := vTotalAulasComExcInterv + vTabEnturmacao(vInd).TotalAulas;

          ELSE

             vTotalAulasSemExcInterv := vTotalAulasSemExcInterv + vTabEnturmacao(vInd).TotalAulas;

          END IF;

          vVal := vValores.NEXT (vVal);

          IF vVal IS NOT NULL THEN
            vgDescFormula := vgDescFormula || ';';
          END IF;

        END LOOP;

        IF vResultPercentInterv > 0 THEN -- Calcula a Media
           vResultPercentInterv := vResultPercentInterv / vQtdeInterv;
        END IF;

        -- Checa horas excedentes da enturmacao

        vResultExcedenteInterv := FAulaExcedente (PTotalAula  => vTotalAulasComExcInterv,
                                                  PCHO        => vCargaHoraria - vTotalAulasSemExcInterv );

        IF vResultExcedenteInterv >= 0 THEN -- Se negativo, nao cumpriu carga horaria da enturmacao

          IF vTotalAulasComExcInterv = 0 THEN
             vResultExcedenteInterv := 0;
          END IF;

          -- Soma intervalos ao total

          if vDiaInicial is not null and vDiaInicial between vDia and vDiaFinal -- NVL(vgNuDiasUteisAfa,0) > 0 --tSemRemun is not null -- Descontar dias de afastamento sem remuneracao.
            then
               case
                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtIni >= vTIDIntervalos.intervalos(vDia).DtIni
                   then
                     vDiaAfastIni := to_char(vTIDAfastSemRemun.intervalos(vDiaInicial).DtIni,'YYYYMMDD');

                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtIni < vTIDIntervalos.intervalos(vDia).DtIni
                    then
                      vDiaAfastIni := to_char(vTIDIntervalos.intervalos(vDia).DtIni,'YYYYMMDD');
               end case;

               case
                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtFim > vTIDIntervalos.intervalos(vDia).DtFim
                   then
                     vDiaAfastFim := to_char(vTIDIntervalos.intervalos(vDia).DtFim,'YYYYMMDD');

                 when vTIDAfastSemRemun.intervalos(vDiaInicial).DtFim <= vTIDIntervalos.intervalos(vDia).DtFim
                    then
                      vDiaAfastFim := to_char(vTIDAfastSemRemun.intervalos(vDiaInicial).DtFim,'YYYYMMDD');
               end case;

               vDiasAfast := vDiaAfastFim - vDiaAfastIni + 1;

               vgPercentRegenciaClasse   := vgPercentRegenciaClasse
                   + vResultPercentInterv   * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1 - vDiasAfast);

               vgAulaExcedente           := vgAulaExcedente
                   + vResultExcedenteInterv * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1 - vDiasAfast);

               vgDiasRegencia            := vgDiasRegencia
                   + (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1 - vDiasAfast);

           else

              vgPercentRegenciaClasse   := vgPercentRegenciaClasse
                   + vResultPercentInterv   * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

              vgAulaExcedente           := vgAulaExcedente
                   + vResultExcedenteInterv * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

              vgDiasRegencia            := vgDiasRegencia
                   + (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

          end if;

          IF pFolha.DtFimMes BETWEEN vTIDIntervalos.intervalos (vDia).DtIni AND vTIDIntervalos.intervalos (vDia).DtFim THEN

             vgTemRegenciaUltDiaMes := TRUE;

             -- Tratar mes com menos de 30 dias
             IF TO_CHAR(pFolha.DtFimMes,'DD') < 30
               THEN
                 vgPercentRegenciaClasse := vgPercentRegenciaClasse +
                                            vResultPercentInterv * (30 - TO_CHAR(pFolha.DtFimMes,'DD'));

                 vgAulaExcedente := vgAulaExcedente +
                                    vResultExcedenteInterv * (30 - TO_CHAR(pFolha.DtFimMes,'DD'));

                 vgDiasRegencia := vgDiasRegencia + (30 - TO_CHAR(pFolha.DtFimMes,'DD'));

             -- Para os afastados com mes de 31 dias ajustar os dias da regencia
             -- Favelao
             ELSIF TO_CHAR(pFolha.DtFimMes,'DD') = 31
               AND vDiasAfast > 0
               AND SUBSTR(vDiaAfastFim,7,2) < 31
                THEN
                  vgPercentRegenciaClasse := vgPercentRegenciaClasse +
                                            (vResultPercentInterv * -1);

                  vgAulaExcedente := vgAulaExcedente +
                                    (vResultExcedenteInterv * (-1));

                  vgDiasRegencia := (vgDiasRegencia -1);

             else
               null;
             END IF;

          END IF;

          IF vAfastAtivEsp = 0 THEN -- Nao esta afastado, recebe gratificacao especial

             vgGratifAtivEsp           := vgGratifAtivEsp
                   + vResultExcedenteInterv * (vTIDIntervalos.intervalos (vDia).DtFim - vTIDIntervalos.intervalos (vDia).DtIni  + 1);

          END IF;

        END IF;

      END IF;

      vgDescFormula := vgDescFormula || '] ';

      vDia := vTIDIntervalos.intervalos.NEXT (vDia);

   END LOOP;
   -----------------------------------------------
   -- Comentado abaixo tratado anteriormente.
   --
  /*vDia := null;

  vDia := vTIDIntervalosSemRemun.intervalos.FIRST;

   WHILE vDia IS NOT NULL LOOP

   vAfastSemRemun := PKGTID.FConsultar (PTID => vTIDAfastSemRemun,
                     PData => vTIDIntervalosSemRemun.intervalos (vDia).DtIni );

   vgPercentRegenciaClasseSub   := vgPercentRegenciaClasseSub + (vTIDIntervalosSemRemun.intervalos (vDia).DtFim - vTIDIntervalosSemRemun.intervalos (vDia).DtIni + 1);

   vDia := vTIDIntervalosSemRemun.intervalos.NEXT (vDia);

   END LOOP;

  vgPercentRegenciaClasseSub := 1 - (vgPercentRegenciaClasseSub / 30); -- proporcionalizar dias afastados sem remun

  vgPercentRegenciaClasse := vgPercentRegenciaClasse * vgPercentRegenciaClasseSub;*/

   ---------------------------------------------------

   IF vgDiasRegencia > 0 THEN

     vgPercentRegenciaClasse := vgPercentRegenciaClasse / vgDiasRegencia;
     vgAulaExcedente         := vgAulaExcedente         / vgDiasRegencia;
     vgGratifAtivEsp         := vgGratifAtivEsp         / vgDiasRegencia;

   END IF;

END;

/*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Obter informacoes sobre Regencia de Classe, aulas excedentes e gratif. des. ativ. especial
--
/*---------------------------------------------------------------------------------------------*/

FUNCTION FProporcaoDiasRegencia (pNuAnoReferencia IN INTEGER,
                                 pNuMesReferencia IN INTEGER,
                                 pDtFimMes        IN DATE,
                                 pDiasRegencia    IN INTEGER) RETURN NUMBER IS

   vNuDiasMes   INTEGER;

   vProporcao   NUMBER;

BEGIN

   vNuDiasMes := PKGPAG_GERAL.FRetornaDiasDoMes (pDtFimMes           => pDtFimMes,
                                                 pFlPropMesComercial => 'N');

   IF pDiasRegencia = vNuDiasMes THEN

      vProporcao := 1;

   ELSE

       vProporcao := ( vgDiasRegencia ) / 30;

   END IF;

   RETURN vProporcao;

END;

/*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Gerar rubrica de Regencia de Classe, de acordo com enturmacoes
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P075RegenciaDeClasse (pFolha    IN PKGPAG_TIPO.rFolha,
                                pRubrica  IN PKGPAG_TIPO.rRubrica,
                                pCEF      IN PKGPAG_TIPO.rCEF,
                                pFormExpr IN PKGPAG_TIPO.tFormulaCalculo) IS

   vCdExpressaoFormCalc   INTEGER;

   vPercentual            NUMBER;

BEGIN

    IF pFolha.CdOrgao = 41 -- IMPLANTACAO EDUCACAO
      THEN
       PObterEnturmacaoSED (pFolha => pFolha,
                            pCEF   => pCEF,
                            pRubrica => pRubrica);
    ELSE
       PObterEnturmacao (pFolha => pFolha,
                         pCEF   => pCEF);
    END IF;
    IF vgPercentRegenciaClasse > 0 THEN

      -- Proporcionalizar o percentual pelos dias com regencia

      vPercentual := vgPercentRegenciaClasse * FProporcaoDiasRegencia (pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                                       pNuMesReferencia => pFolha.NuMesReferencia,
                                                                       pDtFimMes        => pFolha.DtFimMes,
                                                                       pDiasRegencia    => vgDiasRegencia);

      vPercentual := TRUNC(vPercentual,2);

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

         IF vCdExpressaoFormCalc > 0 THEN

           PKGPAG_GERAL.PInsereLancamentoRelacao (
                                  pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                  pCdVinculo            => pCEF.CdVinculo,
                                  pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                  pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                  pVlIntegral           => NULL,
                                  pVlProporcional       => NULL,
                                  pNuSufixoRubrica      => CASE When PKGPAG_GERAL.vgFlPossuiFinRegencia = TRUE
                                                                THEN PKGPAG_GERAL.vgNuSufixoRegencia ELSE 1 END,
                                  pNuParcelas           => 1,
                                  pVlIndice             => vPercentual,
                                  pCdTipoOrigemRubrica  => 7,
                                  pDtInicio             => pCEF.DtInicio,
                                  pDtFim                => pCEF.DtFim,
                                  pDescritivo           => SUBSTR(vgDescFormula,1,200),
                                  pVlIndiceReal         => vgPercentRegenciaClasse,
                                  pCdTipoIndice         => null
                                  );

         END IF;

      END IF;

    END IF;

END;

--
-- Pagamento de abono de aniversario de admissao
--
PROCEDURE P088AbonoAdmissao (pFolha    IN PKGPAG_TIPO.rFolha,
                             pRubrica  IN PKGPAG_TIPO.rRubrica,
                             pCEF      IN PKGPAG_TIPO.rCEF,
                             pFormExpr IN PKGPAG_TIPO.tFormulaCalculo) IS

   vCdExpressaoFormCalc   INTEGER;

BEGIN

    --
    -- Identificar quem teve aniversario de admissao no mes do calculo anterior
    --
    IF pCef.DtInicioVinculo < pFolha.DtInicioMes AND
       to_char(pCef.DtInicioVinculo,'YYYY') < to_char(pFolha.DtInicioMes,'YYYY') AND
       to_char(pCef.DtInicioVinculo,'MM') = to_char(pFolha.DtCalculoAnt,'MM') AND
       MONTHS_BETWEEN(pFolha.DtInicioMes,pCef.DtInicioVinculo) >= 12

      THEN

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

         IF vCdExpressaoFormCalc > 0 THEN

           PKGPAG_GERAL.PInsereLancamentoRelacao (
                                  pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                  pCdVinculo            => pCEF.CdVinculo,
                                  pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                  pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                  pVlIntegral           => NULL,
                                  pVlProporcional       => NULL,
                                  pNuSufixoRubrica      => 1,
                                  pNuParcelas           => 1,
                                  pVlIndice             => 25,
                                  pCdTipoOrigemRubrica  => 7,
                                  pDtInicio             => pCEF.DtInicio,
                                  pDtFim                => pCEF.DtFim,
                                  pVlIndiceReal         => 25
                                  /*,
                                  pCdTipoIndice         => null   */
                                  );

         END IF;

      END IF;

    END IF;

END;

PROCEDURE P126DataAniversarioNatalicio (pFolha    IN PKGPAG_TIPO.rFolha,
                                        pRubrica  IN PKGPAG_TIPO.rRubrica,
                                        pCEF      IN PKGPAG_TIPO.rCEF,
                                        pFormExpr IN PKGPAG_TIPO.tFormulaCalculo) IS

   vCdExpressaoFormCalc   INTEGER;
   VlPaga Char(1) := 'S';
   Vinseriu integer;
   vpaga_regradtfim char(1);
   vpaga_reagranula char(1);
   vpaga_regra180 char(1);
   vpaga_regrapreso char(1);
   VNpaga_reagranula char(1);
   VNpaga_regra180 integer;
   Vpaga_menor90dias char(1);
   Voutroorgao integer;

BEGIN
    --
    -- Identificar quem teve aniversario  no mes do calculo.
    --
    IF pRubrica.CdRubricaAgrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,9207) and
       trunc(PKGPAG_VAR.vgVinculo.DtNascimento) < trunc(pFolha.DtInicioMes) AND
       trunc(to_char(PKGPAG_VAR.vgVinculo.DtNascimento,'YYYY')) < trunc(to_char(pFolha.DtInicioMes,'YYYY')) AND
       trunc(to_char(PKGPAG_VAR.vgVinculo.DtNascimento,'MM')) = trunc(to_char(pFolha.DtInicioMes,'MM')) AND
       (pkgpag_var.vgVinculo.dtdesligamento <= trunc(pFolha.DtInicioMes) 
         or pkgpag_var.vgVinculo.dtdesligamento is null
         or (pkgpag_var.vgVinculo.dtdesligamento >= trunc(pFolha.DtFimMes) and pfolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaCtisp))  and
       pfolha.CdOrgao = pkgpag_var.vgvinculo.cdorgao AND
       pcef.CdOrgaoExercicio = pkgpag_var.vgvinculo.cdorgao and
       PKGPAG_VAR.vgNuDiasAfastRelVinc < 30 and
       pCEF.CdUnidadeOrganizacional <> 379876 --(disposicao)
      THEN

    ---eafaafastamentovinculo
  begin
    SELECT 'N'
      into vpaga_regradtfim
      from Eafaafastamentovinculo p1
      inner join eafamotivoafasttemporario V on V.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
      inner join EAFAHISTMOTIVOAFASTTEMP x on x.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
      where  p1.flanulado = 'N'
       and p1.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
       and p1.dtfim is null
       and cdhistmotivoafasttemp <> 7707
       and rownum = 1;

     if vpaga_regradtfim > 0 then
        vpaga_regradtfim := 'N';
     else
        vpaga_regradtfim := 'S';
     end if;
     exception when others then
       vpaga_regradtfim := 'N';
     end;

---2º ;regra
      begin
      SELECT count(*)
       into vNpaga_reagranula
       from Eafaafastamentovinculo p1
        inner join eafamotivoafasttemporario V on V.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
        inner join EAFAHISTMOTIVOAFASTTEMP x on x.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
      where  p1.flanulado = 'N'
         and p1.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
         and (p1.dtfim > pFolha.dtfimMes - 180 or p1.dtfim is null)
         and cdhistmotivoafasttemp = 7707
         and rownum = 1;

        if vNpaga_reagranula > 0 then
          Vpaga_reagranula := 'S';
        else
          Vpaga_reagranula := 'N';
          end if ;
         exception when others then
         vNpaga_reagranula := 'N';
     end;
  ----3º  Soma todos os afastamentos de um ano

         begin
         SELECT sum(p1.dtfim - p1.dtinicio)
         into VNpaga_regra180
          from Eafaafastamentovinculo p1
           inner join eafamotivoafasttemporario V on V.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
           inner join EAFAHISTMOTIVOAFASTTEMP x on x.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
          where  p1.flanulado = 'N'
          and p1.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
          and (p1.dtfim < pfolha.DtFimMes or p1.dtfim is null)
          and p1.dtfim is not null
          and p1.dtfim > pfolha.DtFimMes - 365
          and flpagaaniversario = 'N';

        if nvl(VNpaga_regra180,0) > 180 then
          vpaga_regra180 := 'N';
        end if;

         exception when others then
         vpaga_regra180 := 'S';
     end;
 ----4º regra
         begin
         SELECT 'S'
         into vpaga_regrapreso
          from Eafaafastamentovinculo p1
           inner join eafamotivoafasttemporario V on V.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
           inner join EAFAHISTMOTIVOAFASTTEMP x on x.CDMOTIVOAFASTTEMPORARIO = p1.CDMOTIVOAFASTTEMPORARIO
          where  p1.flanulado = 'N'
          and p1.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
          and p1.dtfim is not null
          and p1.dtfim < pfolha.DtFimMes
          and flpagaaniversario = 'N'
          and rownum = 1;

          if vpaga_regrapreso = 'S' then
            vpaga_regrapreso := 'N';
          else
            vpaga_regrapreso := 'S';
          end if;

          exception when others then
         vpaga_regrapreso := 'N';
     end;
 ---5º Regra, admissão < 90 dias

    begin

          select 'S'
          into Vpaga_menor90dias
          from ecadhistcargoefetivo where
          cdvinculo = pkgpag_var.vgvinculo.cdvinculo and
          (pFolha.dtfimMes - 90)  <= dtinicio  and
          flanulado <> 'S' and
          rownum = 1;

          if Vpaga_menor90dias = 'S' then
            Vpaga_menor90dias := 'N';
          else
            Vpaga_menor90dias := 'S';
          end if;

          exception when others then
         Vpaga_menor90dias := 'S';
     end;
----- ---6º nao paga quem esta fora dos militares

 begin

         select  count(*) ---efe.cdestruturacarreira,vin.cdvinculo,VIN.CDPESSOA,vin.cdorgao
         into Voutroorgao
         from ecadvinculo vin,
              ECadHistCargoEfetivo efe

         where vin.cdpessoa = pkgpag_var.vgvinculo.cdpessoa
          and efe.cdvinculo = vin.cdvinculo
          and vin.cdvinculo <> pkgpag_var.vgvinculo.cdvinculo
          and dtdesligamento is null
          and vin.cdorgao <> pfolha.cdorgao;


         if nvl(Voutroorgao,0) > 0 then
            Voutroorgao := 1;
          else
            Voutroorgao := 0;
          end if;

          exception when others then
         Voutroorgao := 0;
     end;

     if vpaga_regradtfim = 'S' or Vpaga_reagranula = 'S' or vpaga_regrapreso = 'S' then
        VlPaga := 'S';
     elsif vpaga_regra180 = 'N' or Vpaga_menor90dias = 'N' then
        VlPaga := 'N';
     elsif Voutroorgao = 1 then
       VlPaga := 'N';
     else
       null;
     end if;

     IF VlPaga = 'S'  THEN

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

         IF vCdExpressaoFormCalc > 0 THEN

           PKGPAG_GERAL.PInsereLancamentoRelacao (
                                  pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                  pCdVinculo            => pCEF.CdVinculo,
                                  pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                  pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                  pVlIntegral           => null,
                                  pVlProporcional       => null,
                                  pNuSufixoRubrica      => 1,
                                  pNuParcelas           => 1,
                                  pVlIndice             => null,
                                  pCdTipoOrigemRubrica  => 7,
                                  pDtInicio             => pCEF.DtInicio,
                                  pDtFim                => pCEF.DtFim,
                                  pVlIndiceReal         => null
                                  /*,
                                  pCdTipoIndice         => null   */
                                  );

         END IF;


      END IF;

     END IF;

    END IF;

END;

/*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Gerar rubrica de Regencia de Classe, de acordo com enturmacoes
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P076AulaExcedente (pFolha    IN PKGPAG_TIPO.rFolha,
                             pRubrica  IN PKGPAG_TIPO.rRubrica,
                             pCEF      IN PKGPAG_TIPO.rCEF,
                             pFormExpr IN PKGPAG_TIPO.tFormulaCalculo) IS

   vCdExpressaoFormCalc   INTEGER;

   vQtdeHoras             NUMBER;

BEGIN

    IF pFolha.CdOrgao = 41 -- IMPLANTACAO EDUCACAO
      THEN
       PObterEnturmacaoSED (pFolha => pFolha,
                            pCEF   => pCEF,
                            pRubrica => pRubrica);
    ELSE
       PObterEnturmacao (pFolha => pFolha,
                         pCEF   => pCEF);
    END IF;

    IF vgAulaExcedente > 0 THEN

      -- Proporcionalizar o percentual pelos dias com regencia

      vQtdeHoras := vgAulaExcedente * FProporcaoDiasRegencia (pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                              pNuMesReferencia => pFolha.NuMesReferencia,
                                                              pDtFimMes        => pFolha.DtFimMes,
                                                              pDiasRegencia    => vgDiasRegencia);
      vQtdeHoras := TRUNC(vQtdeHoras,4);

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

         IF vCdExpressaoFormCalc > 0 THEN

           PKGPAG_GERAL.PInsereLancamentoRelacao(
                                  pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                  pCdVinculo            => pCEF.CdVinculo,
                                  pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                  pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                  pVlIntegral           => NULL,
                                  pVlProporcional       => NULL,
                                  pNuSufixoRubrica      => 1,
                                  pNuParcelas           => 1,
                                  pVlIndice             => vQtdeHoras,
                                  pVlIndiceReal         => vgAulaExcedente,
                                  pCdTipoOrigemRubrica  => 7,
                                  pDtInicio             => pCEF.DtInicio,
                                  pDtFim                => pCEF.DtFim);

         END IF;

      END IF;

    END IF;

END;

/*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Gerar rubrica de Gratif. Des. Ativ. Especial
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P079GratifAtivEspecial (pFolha    IN PKGPAG_TIPO.rFolha,
                                  pRubrica  IN PKGPAG_TIPO.rRubrica,
                                  pCEF      IN PKGPAG_TIPO.rCEF,
                                  pFormExpr IN PKGPAG_TIPO.tFormulaCalculo) IS

   vCdExpressaoFormCalc   INTEGER;

   vQtdeHoras             NUMBER;

BEGIN

    IF pFolha.CdOrgao = 41 -- IMPLANTACAO EDUCACAO
      THEN
       PObterEnturmacaoSED (pFolha => pFolha,
                            pCEF   => pCEF,
                            pRubrica => pRubrica);
    ELSE
       PObterEnturmacao (pFolha => pFolha,
                         pCEF   => pCEF);
    END IF;

    IF vgGratifAtivEsp > 0 THEN

      -- Proporcionalizar o percentual pelos dias com regencia

      -- Alterado para calcular igual a aula excedente. Os afastamentos serao tratados na configuracao de rubrica 14/05/2014
     /* vQtdeHoras := \* vgGratifAtivEsp *\ vgAulaExcedente * FProporcaoDiasRegencia (pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                              pNuMesReferencia => pFolha.NuMesReferencia,
                                                              pDtFimMes        => pFolha.DtFimMes,
                                                              pDiasRegencia    => vgDiasRegencia);
                                                              */

      -- Chamado SEA 7376/2015 - Implantacao Educacao.
      vQtdeHoras :=  vgGratifAtivEsp * FProporcaoDiasRegencia (pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                               pNuMesReferencia => pFolha.NuMesReferencia,
                                                               pDtFimMes        => pFolha.DtFimMes,
                                                               pDiasRegencia    => vgDiasRegencia);

      vQtdeHoras := TRUNC(vQtdeHoras,4);

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

         IF vCdExpressaoFormCalc > 0 THEN

           PKGPAG_GERAL.PInsereLancamentoRelacao(
                                  pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                  pCdVinculo            => pCEF.CdVinculo,
                                  pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                  pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                  pVlIntegral           => NULL,
                                  pVlProporcional       => NULL,
                                  pNuSufixoRubrica      => 1,
                                  pNuParcelas           => 1,
                                  pVlIndice             => vQtdeHoras,
                                  pVlIndiceReal         => vgAulaExcedente,
                                  pCdTipoOrigemRubrica  => 7,
                                  pDtInicio             => pCEF.DtInicio,
                                  pDtFim                => pCEF.DtFim);

         END IF;

      END IF;

    END IF;

END;

/*----------------------------------------------------------------------------------------------*/
--
--  Objetivo: Gerar rubrica de Regencia de Classe, de acordo com enturmacoes
--
/*---------------------------------------------------------------------------------------------*/

PROCEDURE P086GratificacaoUnidocente (pFolha    IN PKGPAG_TIPO.rFolha,
                                      pRubrica  IN PKGPAG_TIPO.rRubrica,
                                      pCEF      IN PKGPAG_TIPO.rCEF,
                                      pFormExpr IN PKGPAG_TIPO.tFormulaCalculo,
                                      pPercentReg IN NUMBER) IS

   vCdExpressaoFormCalc   INTEGER;

   -- Percentual definido pela legislacao.

   vPercentual            NUMBER := 12;
   vPercentualProp        NUMBER;

BEGIN

    PObterEnturmacaoSED (pFolha => pFolha,
                         pCEF   => pCEF,
                         pRubrica => pRubrica);

    IF vgPercentRegenciaClasse > 0 THEN

     -- Proporcionalizar o percentual pelos dias com regencia

      vPercentual := vPercentual * vgPercentRegenciaClasse / pPercentReg;

      vPercentualProp := vPercentual * FProporcaoDiasRegencia (pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                                       pNuMesReferencia => pFolha.NuMesReferencia,
                                                                       pDtFimMes        => pFolha.DtFimMes,
                                                                       pDiasRegencia    => vgDiasRegencia);

      vPercentualProp := TRUNC(vPercentualProp,2);

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
                                      pFlAPOOrigemCCO           => pCEF.FlOrigemCCO,
                                      pFlTipoProvimento         => pCEF.FlEfetivacao,
                                      pCdMotivoMovimentacao     => pCEF.CdMotivoMovimentacao,
                                      pCdInstitutoMovimentacao  => pCEF.CdInstitutoMovimentacao ) THEN

         -- 1) Busca a formula associada

         vCdExpressaoFormCalc :=

             PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => pFormExpr,
                                    pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pCEF.CdRelacaoVinculo,
                                    pCdEstruturaCarreira      => pCEF.CdEstruturaCarreira,
                                    pCdUnidadeOrganizacional  => pCEF.CdUnidadeOrganizacional);

         IF vCdExpressaoFormCalc > 0 THEN

           PKGPAG_GERAL.PInsereLancamentoRelacao (
                                  pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                  pCdVinculo            => pCEF.CdVinculo,
                                  pCdRelacaoVinculo     => pCEF.CdRelacaoVinculo,
                                  pCdHistRelacaoVinculo => pCEF.CdHistRelVinc,
                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                  pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                  pVlIntegral           => NULL,
                                  pVlProporcional       => NULL,
                                  pNuSufixoRubrica      => CASE When PKGPAG_GERAL.vgFlPossuiFinRegencia = TRUE
                                                                THEN PKGPAG_GERAL.vgNuSufixoRegencia ELSE 1 END,
                                  pNuParcelas           => 1,
                                  pVlIndice             => vPercentualProp,
                                  pCdTipoOrigemRubrica  => 7,
                                  pDtInicio             => pCEF.DtInicio,
                                  pDtFim                => pCEF.DtFim,
                                  pDescritivo           => SUBSTR(vgDescFormula,1,200),
                                  pVlIndiceReal         => vPercentual,
                                  pCdTipoIndice         => null
                                  );

         END IF;

      END IF;

    END IF;

END;

PROCEDURE PProcessaEventosCEF (pVinculo              IN PKGPAG_TIPO.rVinculo,
                               pFolha                IN PKGPAG_TIPO.rFolha,
                               pEvento               IN PKGPAG_TIPO.rEvento,
                               pRubrica              IN PKGPAG_TIPO.tRubrica,
                               pFormExpr             IN PKGPAG_TIPO.tFormulaCalculo,
                               pCEF                  IN PKGPAG_TIPO.tCEF,
                               pdtCalculo            IN DATE,
                               pCdEstruturaCarreira IN OUT INTEGER) IS

  bEventoGerado         BOOLEAN;
  vPercentualRegencia   INTEGER;

BEGIN

  FOR j IN pCEF.FIRST .. pCEF.LAST
  LOOP

    bEventoGerado := FALSE;

    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

    CASE

      -- 001 - Remuneracao fixa de cargo efetivo / Aposentadoria sem paridade

      WHEN pEvento.CdTipoEventoPagamento = 1 THEN

        IF FPossuiAbrangenciaCarreira(pEvento.CdEventoPagAgrup,
                                      pEvento.InAcaoCarreira,
                                      pCEF(j).CdEstruturaCarreiraCarreira) THEN

          bEventoGerado := TRUE;

          P001RemuneracaoFixaCEF(pFolha,
                                 pCEF(j),
                                 pRubrica(pEvento.CdRubricaAgrupamento),
                                 pDtCalculo);

        END IF;

      -- 005 - Pagamento de gratificacao por referencia salarial

      WHEN pEvento.CdTipoEventoPagamento = 5 THEN

        pCdEstruturaCarreira := pCEF(j).CdEstruturaCarreira;

        bEventoGerado := TRUE;

        P005GratificacaoProd(pFolha             => pFolha,
                             pRubrica           => pRubrica(pEvento.CdRubricaAgrupamento),
                             pCdTipoAtipratFaz  => pEvento.CdTipoGratAtivFazendaria,
                             pCEF               => pCEF(j),
                             pDtCalculo         => pDtCalculo);

      -- 007 - Pagamento de horas de sobre aviso

      WHEN pEvento.CdTipoEventoPagamento = 7 THEN

        bEventoGerado := TRUE;

        P007HorasSobreAviso(pFolha     => pFolha,
                            pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                            pCEF       => pCEF(j),
                            pFormExpr  => pFormExpr);

      -- 008 - Pagamento de horas de adicional noturno

      WHEN pEvento.CdTipoEventoPagamento = 8 THEN

        bEventoGerado := TRUE;

        P008AdicionalNoturno(pFolha     => pFolha,
                             pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                             pCEF       => pCEF(j),
                             pFormExpr  => pFormExpr);

     -- 013 - Remuneracao de substituicao de cargo efetivo

      WHEN pEvento.CdTipoEventoPagamento = 13 THEN

        bEventoGerado := TRUE;

        P013RemuneracaoSubstCEF (pFolha                 => pFolha,
                                 pEvento                => pEvento,
                                 pCEF                   => pCEF(j),
                                 pDtCalculo             => pDtCalculo);

      -- 015 - Pagamento de indenizacao de estimulo operacional

      WHEN pEvento.CdTipoEventoPagamento = 15 THEN

        bEventoGerado := TRUE;

        P015a017e023RemunHoraExtra(pFolha                 => pFolha,
                                   pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                   pCEF                   => pCEF(j),
                                   pFormExpr              => pFormExpr,
                                   pCdTipoRegistroJornada => 4,
                                   pCdTipoRegistroEscala  => 3,
                                   pCdTpEscSobreAviso     => 7);

      -- 016 - Pagamento de horas plantao

      WHEN pEvento.CdTipoEventoPagamento = 16 THEN

        bEventoGerado := TRUE;

        P015a017e023RemunHoraExtra(pFolha                 => pFolha,
                                   pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                   pCEF                   => pCEF(j),
                                   pFormExpr              => pFormExpr,
                                   pCdTipoRegistroJornada => 0,
                                   pCdTipoRegistroEscala  => 6,
                                   pCdTpEscSobreAviso     => 7);

      -- Hora extra normal
      -- 017 - Pagamento de horas extras normais

      WHEN pEvento.CdTipoEventoPagamento = 17 THEN

        bEventoGerado := TRUE;

        P015a017e023RemunHoraExtra(pFolha                 => pFolha,
                                   pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                   pCEF                   => pCEF(j),
                                   pFormExpr              => pFormExpr,
                                   pCdTipoRegistroJornada => 5,
                                   pCdTipoRegistroEscala  => 4);

     -- Hora extra especial
     -- 023 - Pagamento de horas extras especiais

      WHEN pEvento.CdTipoEventoPagamento = 23 THEN

        bEventoGerado := TRUE;

        P015a017e023RemunHoraExtra(pFolha                 => pFolha,
                                   pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                   pCEF                   => pCEF(j),
                                   pFormExpr              => pFormExpr,
                                   pCdTipoRegistroJornada => 6,
                                   pCdTipoRegistroEscala  => 5);

      -- 065, 066

      WHEN pEvento.CdTipoEventoPagamento IN (65,66) THEN

        bEventoGerado := TRUE;

        P065066HoraAulaAtividade(pFolha                 => pFolha,
                                 pRubrica               => pRubrica(pEvento.CdRubricaAgrupamento),
                                 pCEF                   => pCEF(j),
                                 pInTipoPagamento       => CASE
                                                             WHEN pEvento.CdTipoEventoPagamento = 65 THEN
                                                               1
                                                           ELSE
                                                             2
                                                           END);

      -- 075 - Regencia de Classe

      WHEN pEvento.CdTipoEventoPagamento = 75 THEN

       bEventoGerado := TRUE;

        P075RegenciaDeClasse (pFolha     => pFolha,
                              pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                              pCEF       => pCEF(j),
                              pFormExpr  => pFormExpr);

      -- 076 - Aula Excedente

      WHEN pEvento.CdTipoEventoPagamento = 76 THEN

        bEventoGerado := TRUE;

        P076AulaExcedente (pFolha     => pFolha,
                           pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                           pCEF       => pCEF(j),
                           pFormExpr  => pFormExpr);

      -- 079 - Gratif. Des. Ativ. Especial

      WHEN pEvento.CdTipoEventoPagamento = 79 THEN

        bEventoGerado := TRUE;

        P079GratifAtivEspecial (pFolha     => pFolha,
                                pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                pCEF       => pCEF(j),
                                pFormExpr  => pFormExpr);

      WHEN pEvento.CdTipoEventoPagamento = 86

       THEN

         bEventoGerado := FALSE;

         vgPercentRegenciaClasse := NULL;

         vPercentualRegencia := fPercentualRegencia(pCef(j).CdHistCargoEfetivo,
                                pFolha.DtInicioMes,
                                pFolha.DtFimMes);

         IF (
                (pFolha.CdOrgao <> 42 AND vPercentualRegencia = 40 ) OR -- SED E OUTROS
                (pFolha.CdOrgao = 42  AND vPercentualRegencia > 0  )    -- FCEE
            )

         THEN

           bEventoGerado := TRUE;

           P086GratificacaoUnidocente (pFolha     => pFolha,
                                       pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                       pCEF       => pCEF(j),
                                       pFormExpr  => pFormExpr,
                                       pPercentReg => vPercentualRegencia);

         END IF;

      --
      -- Pagamento de abono de aniversario de admissao
      --
      WHEN pEvento.CdTipoEventoPagamento = 88 THEN

          bEventoGerado := TRUE;

          P088AbonoAdmissao (pFolha     => pFolha,
                             pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                             pCEF       => pCEF(j),
                             pFormExpr  => pFormExpr);


      --
      -- Afastamento servico militar
      --
      WHEN pEvento.CdTipoEventoPagamento = 90
    and pkgpag_var.vgNuDiasAfastSemRemunMesAtual > 0 then

        for i in pkgpag_var.vgAfastTempNaoRemun.first .. pkgpag_var.vgAfastTempNaoRemun.last
     loop
      if pkgpag_var.vgAfastTempNaoRemun(i).CdMotivoAfastamento = 1129
       then
        bEventoGerado := TRUE;

                P090AfastServicoMilitar (pFolha     => pFolha,
                                         pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                         pCEF       => pCEF(j),
                                         pFormExpr  => pFormExpr,
                                         pNuDias    => pkgpag_var.vgAfastTempNaoRemun(i).NuDiasAfastMes);

            end if;
        end loop;

       --
       -- Pagamento na data do aniversario natalicio
      ---
      WHEN pEvento.CdTipoEventoPagamento = 126 THEN

          bEventoGerado := TRUE;

          P126DataAniversarioNatalicio  (pFolha     => pFolha,
                                         pRubrica   => pRubrica(pEvento.CdRubricaAgrupamento),
                                         pCEF       => pCEF(j),
                                         pFormExpr  => pFormExpr);

      -- Senao
      ELSE

        NULL;

    END CASE;

    IF bEventoGerado THEN

      PKGPAG_GERAL.PLogTrace ('EVCEFAPO - Evento Gerado ' || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - CEF ' || j, PKGPAG_VAR.vgTmInicio);

    ELSE

      PKGPAG_GERAL.PLogTrace ('EVCEFAPO - Evento Não Gerado '  || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - CEF ' || j, PKGPAG_VAR.vgTmInicio);

    END IF;

  END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'EVCEFAPO - Erro ao processar Evento (' || pEvento.CdTipoEventoPagamento || ') - ' || pEvento.DeEvento ,
                              PKGPAG_VAR.vgCdVinculo);

END;

PROCEDURE PProcessaEventosAPO (pVinculo            IN PKGPAG_TIPO.rVinculo,
                               pFolha              IN PKGPAG_TIPO.rFolha,
                               pEvento             IN PKGPAG_TIPO.rEvento,
                               pRubrica            IN PKGPAG_TIPO.tRubrica,
                               pAPO                IN PKGPAG_TIPO.tCEF,
                               pdtCalculo          IN DATE) IS

  bEventoGerado         BOOLEAN;

BEGIN

  FOR j IN pAPO.FIRST .. pAPO.LAST
  LOOP

    bEventoGerado := FALSE;
    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

    CASE

     -- 001 - Remuneracao fixa de cargo efetivo / Aposentadoria com paridade

      WHEN pEvento.CdTipoEventoPagamento = 1 THEN

         IF FPossuiAbrangenciaCarreira(pEvento.CdEventoPagAgrup,
                                       pEvento.InAcaoCarreira,
                                       pAPO(j).CdEstruturaCarreiraCarreira) THEN

           bEventoGerado := TRUE;

           P001RemuneracaoAPOParid(pFolha,
                                   pAPO(j),
                                   pRubrica(pEvento.CdRubricaAgrupamento));

         END IF;

   -- 005 - Pagamento de gratificacao por referencia salarial

    WHEN pEvento.CdTipoEventoPagamento = 5 THEN

           bEventoGerado := TRUE;

           P005GratificacaoProd(pFolha             => pFolha,
                                pRubrica           => pRubrica(pEvento.CdRubricaAgrupamento),
                                pCdTipoAtipratFaz  => pEvento.CdTipoGratAtivFazendaria,
                                pAPO               => pAPO(j),
                                pDtCalculo         => pDtCalculo);

    -- 070 - Pagamento de diferenca de proventos de aposentado

    WHEN pEvento.CdTipoEventoPagamento = 70 THEN

          bEventoGerado := TRUE;

          P070DiferencaAposentadoria(pFolha    => pFolha,
                                     pAPO      => pAPO(j),
                                     pRubrica  => pRubrica(pEvento.CdRubricaAgrupamento),
                                     pFormExpr => PKGPAG_VAR.vgFormExpr);

    ELSE
      NULL;

    END CASE;

    IF bEventoGerado THEN

      PKGPAG_GERAL.PLogTrace ('EVCEFAPO - Evento Gerado ' || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - APO ' || j, PKGPAG_VAR.vgTmInicio);

    ELSE

      PKGPAG_GERAL.PLogTrace ('EVCEFAPO - Evento Não Gerado '  || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - APO ' || j, PKGPAG_VAR.vgTmInicio);

    END IF;

  END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

    PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                            PKGPAG_VAR.vCdHistParamCalc,
                            PKGPAG_VAR.vCdPessoa,
                           'EVCEFAPO - Erro ao processar Evento (' || pEvento.CdTipoEventoPagamento || ') - ' || pEvento.DeEvento ,
                            PKGPAG_VAR.vgCdVinculo);

END;

PROCEDURE PProcessaEventosAPOSemParid (pVinculo            IN PKGPAG_TIPO.rVinculo,
                                       pFolha              IN PKGPAG_TIPO.rFolha,
                                       pEvento             IN PKGPAG_TIPO.rEvento,
                                       pRubrica            IN PKGPAG_TIPO.tRubrica,
                                       pAPOSemParid        IN PKGPAG_TIPO.tCEF) IS

  bEventoGerado         BOOLEAN;

BEGIN

  FOR j IN pAPOSemParid.FIRST .. pAPOSemParid.LAST
  LOOP

    bEventoGerado := FALSE;
    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

    CASE

      -- 022 - Pagamento do provento de aposentadoria sem paridade

      WHEN pEvento.CdTipoEventoPagamento = 22 THEN

        bEventoGerado := TRUE;

        P022RemuneracaoAPOSemParid(pFolha,
                                   pRubrica(pEvento.CdRubricaAgrupamento),
                                   pAPOSemParid(j));
      ELSE
        NULL;

    END CASE;

    IF bEventoGerado THEN

      PKGPAG_GERAL.PLogTrace ('EVCEFAPO - Evento Gerado ' || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - APOSemParid ' || j, PKGPAG_VAR.vgTmInicio);

    ELSE

      PKGPAG_GERAL.PLogTrace ('EVCEFAPO - Evento Não Gerado '  || pEvento.CdTipoEventoPagamento, pEvento.DeEvento || ' - APOSemParid ' || j, PKGPAG_VAR.vgTmInicio);

    END IF;

  END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

    PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'EVCEFAPO - Erro ao processar Evento (' || pEvento.CdTipoEventoPagamento || ') - ' || pEvento.DeEvento ,
                              PKGPAG_VAR.vgCdVinculo);

END;

end PKGPAG_EVCEFAPO;
/
