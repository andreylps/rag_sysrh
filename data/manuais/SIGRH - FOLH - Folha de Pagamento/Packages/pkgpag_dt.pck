CREATE OR REPLACE PACKAGE PKGPAG_DT IS

FUNCTION FVerificaPensaoValida(pCdVinculo IN INTEGER,
                                                            pNuSeqPensao IN INTEGER,
                                                            pCdpessoapensao IN INTEGER,
                                                            pDtInicioMes IN DATE)

RETURN BOOLEAN;

PROCEDURE PReprocessa13Salario(pCdVinculo        IN INTEGER,
                               pCdAgrupamento    IN INTEGER,
                               pCdFolhaPagamento IN INTEGER,
                               pCdFolha13Ant     IN INTEGER,
                               pCdFolha13        IN INTEGER);

PROCEDURE PProcessarCalculo13Salario(pCalculo                   IN PKGPAG_CAL.rCalculo,
                                     pDtCalculo                 IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                                     pFlDefinitivo              IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                                     pLog                       IN BOOLEAN,
                                     pTrace                     IN BOOLEAN,
                                     pCalculoRetorno            OUT PKGPAG_CAL.rCalculoRetorno);

PROCEDURE PProcessarCalculo13Salario (pCdJobId IN VARCHAR2, pCdCalculo  IN INTEGER);

END PKGPAG_DT;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_DT IS

TYPE rVinc IS RECORD
    (CdFolhaPagamento         INTEGER,
     CdOrgaoFolha             INTEGER,
     CdOrgao                  INTEGER,
     CdPessoa                 INTEGER,
     NuSeqMatricula           INTEGER,
     CdVinculo                INTEGER,
     CdRegimeTrabalho         INTEGER,
     CdRegimePrevidenciario   INTEGER,
     DtAdmissao               DATE,
     DtDesligamento           DATE,
     DtNascimento             DATE,
     FlSexo                   CHAR(1),
     FlContribIndiv           INTEGER,
     deOrdemExecucao          VARCHAR(5)     
     );

FUNCTION FDuploVinculoVigente(pCdPessoa    IN INTEGER,
                             pDtInicioMes IN DATE)
    RETURN INTEGER IS

    vcont INTEGER;

BEGIN
 
    SELECT COUNT(*)
      INTO vcont
      FROM ecadvinculo v
      inner join ecadhistorgao ho on v.cdorgao = ho.cdorgao and ho.dtfimvigencia is null
                              and ho.cdtipoorgao not in (1,5)
   WHERE CdPessoa = pCdPessoa AND
         (DtDesligamento IS NULL OR DtDesligamento >= pDtInicioMes);

    RETURN vcont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FVinculosVigentes(pCdPessoa in integer)
    RETURN INTEGER IS

    vCont INTEGER DEFAULT 0;

  BEGIN
 
     with fol AS
          (SELECT f.cdfolhapagamento
             FROM EPAGFOLHAPAGAMENTO F
            INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
               ON F.CDTIPOFOLHAPAGAMENTO = TF.CDTIPOFOLHAPAGAMENTO
            inner join ecadhistorgao ho on f.cdorgao = ho.cdorgao and ho.dtfimvigencia is null
                              and ho.cdtipoorgao not in (1,5)
            INNER JOIN EPAGTIPOFOLHA TP
               ON TP.CDTIPOFOLHA = TF.CDTIPOFOLHA
              AND TF.CDTIPOFOLHA IN
                  (PKGPAG_TIPO.CNTPFOLHANORMAL, pkgpag_tipo.cnTpFolhaResidente)
              AND F.CDTIPOCALCULO IN
                  (PKGPAG_TIPO.CNTPCALCULONORMAL, PKGPAG_TIPO.CNTPCALCULOSUPL, PKGPAG_TIPO.cnTpCalculoAnterior )
              AND F.NUANOMESREFERENCIA = to_number(TO_CHAR(pkgpag_var.vgFolha.dtcalculo, 'YYYYMM'))),
         rub as
           (SELECT r.cdrubricaagrupamento
             FROM VPAGRUBRICAAGRUPAMENTO R
            WHERE R.NURUBRICA IN (903)
              AND R.CDTIPORUBRICA = 9)
    select count(distinct v.cdvinculo)
      into vCont
      from epaghistoricorubricavinculo hv
      inner join fol fp on fp.cdfolhapagamento = hv.cdfolhapagamento
      inner join ECadVinculo V ON V.CdVinculo = hv.CdVinculo and v.cdregimeprevidenciario = 1
      inner join rub r on r.cdrubricaagrupamento = hv.cdrubricaagrupamento
      where V.CdPessoa = pCdPessoa
        and not exists (SELECT 1
                          FROM eTrbRecolhimentoAvulso T
                          WHERE T.CdPessoa = pCdPessoa
                            AND (T.CdVinculo IS NULL OR T.CdVinculo = v.CdVinculo)
                            AND T.FlAnulado = 'N'
                            AND T.CdObjetoRecolhimento = 1
                            AND (T.FlRecolhimentoTeto = 'S')
                            AND ((T.NuAnoInicio < pkgpag_var.vgFolha.NuAnoReferencia OR
                                 (T.NuAnoInicio = pkgpag_var.vgFolha.NuAnoReferencia AND
                                  T.NuMesInicio <= pkgpag_var.vgFolha.NuMesReferencia))
                            AND (T.NuAnoFim > pkgpag_var.vgFolha.NuAnoReferencia OR
                                 (T.NuAnoFim = pkgpag_var.vgFolha.NuAnoReferencia AND
                                  T.NuMesFim >= pkgpag_var.vgFolha.NuAnoReferencia) OR
                                  T.NuAnoFim IS NULL)));

    RETURN vCont;

  EXCEPTION

      WHEN OTHERS THEN

         RETURN 0;

  END;

  FUNCTION fDiferencaINSS13(pCdPessoa in integer)

    RETURN number IS

    vVlPagoDefinitiva number(13,2);

    vVlPagoDez        number(13,2);

    vCdRubrica        integer;

  begin
 
      vVlPagoDez := 0;

      vVlPagoDefinitiva := 0;

      vCdRubrica := pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,5,513);

     with vin as (select *
                    from ecadvinculo v
                   where v.cdpessoa = pCdPessoa
                     and v.flanulado = 'N'),
          fol as (select *
                    from epagfolhapagamento fp
                    inner join epagtipofolhapagamento tfp
                       on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
                      and tfp.cdtipofolha = pkgpag_tipo.cnTpFolha13
                    WHERE FP.NuAnoReferencia = pkgpag_var.vgfolha.NuAnoReferencia
                      and fp.numesreferencia = 11
                      and FP.FlCalculoDefinitivo =  PKGPAG_TIPO.cnS)

     SELECT nvl(SUM(rv.vlpagamento), 0)
       INTO vVlPagoDefinitiva
       FROM epaghistoricorubricavinculo rv
       INNER JOIN fol f on f.cdfolhapagamento = rv.cdfolhapagamento
       inner join vin v on v.cdvinculo = rv.cdvinculo
       WHERE rv.cdrubricaagrupamento = vCdRubrica;

     with vin as (select *
                    from ecadvinculo v
                   where v.cdpessoa = pCdPessoa
                     and v.flanulado = 'N'),
          fol as (select *
                    from epagfolhapagamento fp
                    inner join epagtipofolhapagamento tfp
                       on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
                      and tfp.cdtipofolha = pkgpag_tipo.cnTpFolha13
                      and fp.cdtipocalculo = 1
                    WHERE FP.NuAnoReferencia = pkgpag_var.vgfolha.NuAnoReferencia
                      and fp.numesreferencia = 12)

     SELECT nvl(SUM(rv.vlpagamento), 0)
       INTO vVlPagoDez
       FROM epaghistoricorubricavinculo rv
       INNER JOIN fol f on f.cdfolhapagamento = rv.cdfolhapagamento
       inner join vin v on v.cdvinculo = rv.cdvinculo
       WHERE rv.cdrubricaagrupamento = vCdRubrica;

     return vVlPagoDez - vVlPagoDefinitiva;

     exception
    when others then
     return 0;

  end;

  FUNCTION FTemFolha13Definitivo(pCdVinculo in integer)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
   WITH FOL AS
     (SELECT FP.CdFolhaPagamento
        FROM EPagFolhaPagamento FP
        inner join epagtipofolhapagamento tfp on fp.cdtipofolhapagamento=tfp.cdtipofolhapagamento
        where fp.numesreferencia <> pkgpag_var.vgfolha.numesreferencia
          and fp.nuanoreferencia = pkgpag_var.vgfolha.nuanoreferencia
          and fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoNormal
          and tfp.cdtipofolha = PKGPAG_TIPO.cnTpFolha13
          and fp.cdorgao = pkgpag_var.vgFolha.Cdorgao
          and fp.flcalculodefinitivo = 'S')
      SELECT 1
        INTO VCONT
        FROM EPAGHISTORICORUBRICAVINCULO HRV
        inner join fol f on f.cdfolhapagamento = hrv.cdfolhapagamento
        WHERE HRV.CDVINCULO = pCdVinculo
          AND ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

FUNCTION FTemPagamento(pCdFolhaPagamento IN INTEGER,
                      pCdTipoFolha in integer default null)

    RETURN BOOLEAN IS

    vCont INTEGER;

BEGIN
 

  case when pCdTipoFolha in (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13, pkgpag_tipo.cnTpFolhaAposentadoria13,
                           pkgpag_tipo.cnTpFolhaResidente13) then

    SELECT 1
      INTO VCONT
      FROM EPAGHISTORICORUBRICAVINCULO HRV
     WHERE HRV.CDVINCULO = PKGPAG_VAR.vgVinculo.CdVinculo
       AND HRV.CDFOLHAPAGAMENTO = PCDFOLHAPAGAMENTO
       AND ROWNUM < 2;

  else

    SELECT 1
      INTO VCONT
      FROM EPAGHISTORICORUBRICAVINCULO HRV
     WHERE HRV.CDVINCULO = PKGPAG_VAR.vgVinculo.CdVinculo
       AND HRV.CDFOLHAPAGAMENTO IN
           (SELECT DISTINCT FP2.CDFOLHAPAGAMENTO
              FROM EPAGFOLHAPAGAMENTO FP
             INNER JOIN EPAGFOLHAPAGAMENTO FP2
                ON FP.NUANOMESREFERENCIA = FP2.NUANOMESREFERENCIA
                AND FP.CDORGAO = FP2.CDORGAO
                AND FP.CDTIPOFOLHAPAGAMENTO = FP2.CDTIPOFOLHAPAGAMENTO
                AND FP.CDTIPOCALCULO = FP2.CDTIPOCALCULO
                AND FP2.FLCALCULODEFINITIVO = 'S'
             WHERE FP.CDFOLHAPAGAMENTO = PCDFOLHAPAGAMENTO)
       AND ROWNUM < 2;

  end case;

    RETURN TRUE;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

  FUNCTION FTemPagamentoOutroOrgao

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    IF FTemPagamento(PKGPAG_VAR.vgCdFolhaSuplementar) THEN

        SELECT 1
        INTO VCONT
        FROM EPAGHISTORICORUBRICAVINCULO HRV
        WHERE HRV.CDVINCULO = PKGPAG_VAR.vgVinculo.CdVinculo
        AND HRV.CDFOLHAPAGAMENTO IN
             (SELECT DISTINCT FP2.CDFOLHAPAGAMENTO
                FROM EPAGFOLHAPAGAMENTO FP
               INNER JOIN EPAGFOLHAPAGAMENTO FP2
                  ON FP.NUANOMESREFERENCIA = FP2.NUANOMESREFERENCIA
                  AND FP.CDTIPOFOLHAPAGAMENTO = FP2.CDTIPOFOLHAPAGAMENTO
               WHERE FP.CDFOLHAPAGAMENTO = PKGPAG_VAR.vgCdFolhaSuplementar
               AND   FP2.FLCALCULODEFINITIVO = 'S'
               AND   FP2.CDORGAO <> FP.CDORGAO
               AND   FP2.DTCALCULO > FP.DTCALCULO)
         AND ROWNUM < 2;

         RETURN TRUE;

    ELSE

         SELECT 1
         INTO VCONT
         FROM EPAGHISTORICORUBRICAVINCULO HRV
         WHERE HRV.CDVINCULO = PKGPAG_VAR.vgVinculo.CdVinculo
         AND HRV.CDFOLHAPAGAMENTO IN
             (SELECT DISTINCT FP2.CDFOLHAPAGAMENTO
                FROM EPAGFOLHAPAGAMENTO FP
               INNER JOIN EPAGFOLHAPAGAMENTO FP2
                  ON FP.NUANOMESREFERENCIA = FP2.NUANOMESREFERENCIA
                  AND FP.CDTIPOFOLHAPAGAMENTO = FP2.CDTIPOFOLHAPAGAMENTO
               WHERE FP.CDFOLHAPAGAMENTO = PKGPAG_VAR.vgCdFolhaNormal
               AND   FP2.FLCALCULODEFINITIVO = 'S'
               AND   FP2.CDORGAO <> FP.CDORGAO
               AND   FP2.DTCALCULO > FP.DTCALCULO)
          AND ROWNUM < 2;

          RETURN TRUE;

    END IF;



  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    WHEN OTHERS THEN

      RETURN FALSE;

  END;
--------------------------------------------------------------------------------
-- Função que verifica a existencia de decisão judicial de penhora ATIVA
--------------------------------------------------------------------------------
  FUNCTION FPossuiDecJudPenhora  (pcdvinculo       IN INTEGER,
                                  pnuanoreferencia IN INTEGER,
                                  pnumesreferencia IN INTEGER,
                                  vIncide13        OUT CHAR,
                                  vIncideAdiant13  OUT CHAR,
                                  pCdRubricaPenhora OUT INTEGER) RETURN BOOLEAN IS
                                  
  BEGIN
 
    SELECT epd.flincide13penhora, epd.flincideadianta13penhora, epd.cdrubricaagrupamento
      INTO vIncide13, vIncideAdiant13, pCdRubricaPenhora
      FROM epageventopagagrupdecisao epd
     WHERE EPD.CdVinculo = pCdVinculo
       AND ((EPD.NuAnoInicioDireito < pNuAnoReferencia OR
           (epd.nuanoiniciodireito = pnuanoreferencia AND
           EPD.NuMesInicioDireito <= pNuMesReferencia)) AND
           (epd.nuanofimdireito > pnuanoreferencia OR
           (epd.nuanofimdireito = pnuanoreferencia AND
           epd.numesfimdireito >= pnumesreferencia) OR
           EPD.NuAnoFimDireito IS NULL))
       AND EPD.FlAnulado = 'N'
       AND EPD.Intipovalor = 5 -- Penhora
       AND ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN
      
      vIncide13       := 'N';
      vIncideAdiant13 := 'N';

      RETURN FALSE;

  END;
-----------------------------------------------------------------------------------
-- Para folha de adiantamento de 13 do CIASC, desconta valor das pensoes
-- do valor do adiantamento 1-0024 1-0024
-----------------------------------------------------------------------------------

PROCEDURE PDescontaPensaoDoAdiantamento(pCdFolhaPagamento INTEGER) IS

       vVlPensao      NUMBER(13,2) := 0; -- VALOR DA PENSAO
       vVlPensaoTotal NUMBER(13,2) := 0; -- ACUMULADOR VALOR DAS PENSOES

BEGIN
 
  FOR vPensao IN (SELECT TPR.CdRubricaAgrupamento, SJ.NuSequencial
                    FROM ePenSentencaJudicial SJ
                   INNER JOIN EPenHistSentencaJudicial HSJ
                      ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
                   INNER JOIN Epentipopensaoalimenticia TPA
                      ON HSJ.CdTipoPensaoAlimenticia = TPA.CdTipoPensaoAlimenticia
                   INNER JOIN Epenhisttipopensao HTP
                      ON TPA.CdTipoPensaoAlimenticia = HTP.CdTipoPensaoAlimenticia
                   INNER JOIN EPenHistTipoPensaoRubrica TPR
                      ON TPR.CdHistTipoPensao = HTP.CdHistTipoPensao
                   INNER JOIN EPagHistRubricaAgrupamento HRA
                      ON TPR.CdRubricaAgrupamento = HRA.CdRubricaAgrupamento
                   WHERE SJ.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                        (((CASE
                             WHEN PKGPAG_VAR.vgFolha.CdTipoFolha = 3 THEN
                                HSJ.FlPagamento13
                             WHEN PKGPAG_VAR.vgFolha.CdTipoFolha = 5 THEN
                                HSJ.FlPagamentoAdiant13
                           END) = 'N' AND
                         HSJ.DtInicioVigencia <= PKGPAG_VAR.vgFolha.DtInicioMes AND
                         (HSJ.DtFimVigencia >= PKGPAG_VAR.vgFolha.DtFimMes OR HSJ.DtFimVigencia IS NULL) AND
                         ((HTP.NuAnoInicio < PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HTP.NuAnoInicio = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                          HTP.NuMesInicio <= PKGPAG_VAR.vgFolha.NuMesReferencia))
                         AND
                         (HTP.NuAnoFim > PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HTP.NuAnoFim = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                         HTP.NuMesFim >= PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                         HTP.NuAnoFim IS NULL)) AND
                         ((HRA.NuAnoInicioVigencia <PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HRA.NuAnoInicioVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                         HRA.NuMesInicioVigencia <= PKGPAG_VAR.vgFolha.NuMesReferencia))
                         AND
                         (HRA.NuAnoFimVigencia > PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HRA.NuAnoFimVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                         HRA.NuMesFimVigencia >= PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                         HRA.NuMesFimVigencia IS NULL))) OR
                        (HSJ.DtFimVigencia BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND
                                                    PKGPAG_VAR.vgFolha.DtFimMes AND
                         NOT EXISTS (SELECT 1 FROM EPenHistSentencaJudicial HSJ1
                                      WHERE HSJ.CdSentencaJudicial = HSJ1.CdSentencaJudicial AND
                                            (HSJ1.DtInicioVigencia > PKGPAG_VAR.vgFolha.DtFimMes OR
                                             HSJ1.DtFimVigencia IS NULL)))))
    LOOP

       BEGIN

           -- Busca o valor a pensao
           SELECT HRV.VLPAGAMENTO
             INTO vVlPensao
             FROM EPagHistoricoRubricaVinculo HRV
            WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                  HRV.CdFolhaPagamento = pCdFolhaPagamento AND
                  HRV.NuSufixoRubrica = vPensao.Nusequencial AND
                  HRV.Cdrubricaagrupamento = vPensao.CdRubricaAgrupamento;

       EXCEPTION

         WHEN NO_DATA_FOUND THEN

            vVlPensao := 0;

       END;

       -- Adiciona o valor da pensao ao totalizador
       vVlPensaoTotal := vVlPensaoTotal + vVlPensao;

    END LOOP;

    -- Aplica o percentual de adiantamento de 13 ao valor total de pensao
    vVlPensaoTotal := vVlPensaoTotal*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13DescPensao/100;

    -- Atualiza valor do adiantamento 1-0024 subtraindo o valor de adiantamento de pensao
    UPDATE EPagHistoricoRubricaVinculo HRV
       SET HRV.VlPagamento = HRV.VlPagamento - vVlPensaoTotal
     WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
           HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.Cdrubricaagrupamento = PKGPAG_VAR.vgCdRubAgrupAntecip13;  -- 1-0024

END;

------------------------------------------------------------------------------------------------
-- Verifica se pensao esta valida na vigencia
------------------------------------------------------------------------------------------------
 FUNCTION FVerificaPensaoValida(pCdVinculo IN INTEGER,
                                                            pNuSeqPensao IN INTEGER,
                                                            pCdpessoapensao IN INTEGER,
                                                            pDtInicioMes IN DATE)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vCont
      FROM ePenSentencaJudicial SJ
     INNER JOIN EPenHistSentencaJudicial HSJ
        ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
     WHERE SJ.CDVINCULO = pCdVinculo
       AND SJ.NUSEQUENCIAL = pNuSeqPensao
       AND SJ.CDPESSOAPENSAO = pCdpessoapensao
       AND HSJ.Flpagamento13 = 'S'
       AND HSJ.DtInicioVigencia <= pDtInicioMes
       AND (HSJ.DTFIMVIGENCIA >= pDtInicioMes OR  HSJ.DtFimVigencia IS NULL);

    RETURN TRUE;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

------------------------------------------------------------------------------------------------
-- Exclui as pensoes que nao permitem adiantamento de 13 salario ou que foram finalizadas ate
-- o ultimo dia do mes do processamento
------------------------------------------------------------------------------------------------
 FUNCTION FVerificaPensaoInvalida(pCdVinculo IN INTEGER,
                                  pNuSeqPensao IN INTEGER,
                                  pCdpessoapensao IN INTEGER,
                                  pDtFimMes IN DATE)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vCont
      FROM ePenSentencaJudicial SJ
     INNER JOIN EPenHistSentencaJudicial HSJ
        ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
     WHERE SJ.CDVINCULO = pCdVinculo
       AND SJ.NUSEQUENCIAL = pNuSeqPensao
       AND SJ.CDPESSOAPENSAO = pCdpessoapensao
       AND TO_CHAR(HSJ.DTFIMVIGENCIA,'YYYYMM') = TO_CHAR(pDtFimMes,'YYYYMM');

    IF vCont = 0
      THEN

       RETURN FALSE;

    ELSE
       --
       -- Verificar se nao tem nova vigencia
       --
       vCont := 0;
       BEGIN

           SELECT 1
             INTO vCont
             FROM ePenSentencaJudicial SJ
            INNER JOIN EPenHistSentencaJudicial HSJ
               ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
            WHERE SJ.CDVINCULO = pCdVinculo
              AND SJ.NUSEQUENCIAL = pNuSeqPensao
              AND SJ.CDPESSOAPENSAO = pCdpessoapensao
              AND HSJ.DTINICIOVIGENCIA > pDtFimMes
              AND ROWNUM < 2;

           IF vCont > 0
             THEN
               RETURN FALSE;

           ELSE
               RETURN TRUE;

           END IF;

           EXCEPTION

            WHEN NO_DATA_FOUND THEN

               RETURN TRUE;

            WHEN OTHERS THEN

               RETURN TRUE;

       END;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

  FUNCTION FPagaPensaoAlimento13(pCdVinculo          IN INTEGER,
                                 pCdSentencaJudicial IN INTEGER,
                                 pNuSeqPensao        IN INTEGER,
                                 pCdpessoapensao     IN INTEGER)

   RETURN BOOLEAN IS

    vCont NUMERIC := 0;

  BEGIN
 
    PKGPAG_VAR.bPossuiIprevCCO := FALSE;

    SELECT 1
      INTO vCont
      FROM ePenSentencaJudicial SJ
     INNER JOIN EPenHistSentencaJudicial HSJ
        ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
     WHERE SJ.CDVINCULO = PKGPAG_VAR.vgVinculo.CdVinculo
       AND SJ.CDSENTENCAJUDICIAL = pCdSentencaJudicial
       AND SJ.NUSEQUENCIAL = pNuSeqPensao
       AND SJ.CDPESSOAPENSAO = pCdpessoapensao
       AND (CASE
             WHEN PKGPAG_VAR.vgFolha.CdTipoFolha = 3 THEN
              HSJ.FlPagamento13
             WHEN PKGPAG_VAR.vgFolha.CdTipoFolha = 5 THEN
              HSJ.FlPagamentoAdiant13
           END) = 'S'
       AND ROWNUM < 2;

    IF vCont = 1 THEN

      RETURN TRUE;

    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END;

PROCEDURE PExcluiPensaoFimMes(pCdFolhaPagamento INTEGER) IS

vVlPensaoAdiant NUMBER (13,2);

BEGIN
 
  FOR vPensao IN (SELECT TPR.CdRubricaAgrupamento, SJ.NuSequencial, SJ.Cdpessoapensao, SJ.CdSentencaJudicial
                    FROM ePenSentencaJudicial SJ
                   INNER JOIN EPenHistSentencaJudicial HSJ
                      ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
                   INNER JOIN Epentipopensaoalimenticia TPA
                      ON HSJ.CdTipoPensaoAlimenticia = TPA.CdTipoPensaoAlimenticia
                   INNER JOIN Epenhisttipopensao HTP
                      ON TPA.CdTipoPensaoAlimenticia = HTP.CdTipoPensaoAlimenticia
                   INNER JOIN EPenHistTipoPensaoRubrica TPR
                      ON TPR.CdHistTipoPensao = HTP.CdHistTipoPensao
                   INNER JOIN EPagHistRubricaAgrupamento HRA
                      ON TPR.CdRubricaAgrupamento = HRA.CdRubricaAgrupamento
                   LEFT JOIN ECADPESSOA P
                      ON P.CdPessoa = SJ.CdPessoa
                   LEFT JOIN EPENPESSOAPENSAO PP
                      ON PP.CdPessoaPensao = SJ.CdPessoaPensao
                   WHERE SJ.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                        (((CASE
                             WHEN PKGPAG_VAR.vgFolha.CdTipoFolha = 3 THEN
                                HSJ.FlPagamento13
                             WHEN PKGPAG_VAR.vgFolha.CdTipoFolha = 5 THEN
                                HSJ.FlPagamentoAdiant13
                           END) = 'N' AND
                         HSJ.DtInicioVigencia <= PKGPAG_VAR.vgFolha.DtInicioMes AND
                         (HSJ.DtFimVigencia >= PKGPAG_VAR.vgFolha.DtFimMes OR HSJ.DtFimVigencia IS NULL) AND
                         ((HTP.NuAnoInicio < PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HTP.NuAnoInicio = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                          HTP.NuMesInicio <= PKGPAG_VAR.vgFolha.NuMesReferencia))
                         AND
                         (HTP.NuAnoFim > PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HTP.NuAnoFim = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                         HTP.NuMesFim >= PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                         HTP.NuAnoFim IS NULL)) AND
                         ((HRA.NuAnoInicioVigencia <PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HRA.NuAnoInicioVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                         HRA.NuMesInicioVigencia <= PKGPAG_VAR.vgFolha.NuMesReferencia))
                         AND
                         (HRA.NuAnoFimVigencia > PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                         (HRA.NuAnoFimVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                         HRA.NuMesFimVigencia >= PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                         HRA.NuMesFimVigencia IS NULL)))
                         OR
                        (HSJ.DtFimVigencia BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND
                                                    PKGPAG_VAR.vgFolha.DtFimMes AND
                         NOT EXISTS (SELECT 1

                                    FROM ePenSentencaJudicial SJ1
                                    INNER JOIN EPenHistSentencaJudicial HSJ1
                                      ON SJ1.CdSentencaJudicial = HSJ1.CdSentencaJudicial
                                    LEFT JOIN ECADPESSOA P1
                                      ON P1.CdPessoa = SJ1.CdPessoa
                                    LEFT JOIN EPENPESSOAPENSAO PP1
                                      ON PP1.CdPessoaPensao = SJ1.CdPessoaPensao

                                    WHERE (
                                         P1.NuCpf IN ( P.Nucpf, PP.NuCpf )
                                      ) AND
                                      (HSJ1.DtInicioVigencia > PKGPAG_VAR.vgFolha.DtFimMes OR
                                      HSJ1.DtFimVigencia IS NULL)))

                         ))
    LOOP

      --
      -- Solicitacao de Sustentacao #76781
      -- 10527/2017 - FOLHA - FOLHA DO ADIANTAMENTO DE 13º
      --

       IF NOT FVerificaPensaoInvalida(PKGPAG_VAR.vgVinculo.CdVinculo,
                                     vPensao.Nusequencial,
                                     vPensao.Cdpessoapensao,
                                     PKGPAG_VAR.vgFolha.dtFimMes) AND
                   FPagaPensaoAlimento13(PKGPAG_VAR.vgVinculo.CdVinculo,
                                     vPensao.CdSentencaJudicial,
                                     vPensao.Nusequencial,
                                     vPensao.Cdpessoapensao) THEN

        CONTINUE;
      END IF;

      IF pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento,
                                           PKGPAG_VAR.vgVinculo.CdVinculo,
                                           PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,4,1586),
                                           vPensao.Nusequencial) > 0
         then

          vVlPensaoAdiant :=  pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento,
                                           PKGPAG_VAR.vgVinculo.CdVinculo,
                                           PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,4,1586),
                                           vPensao.Nusequencial);

          UPDATE EPagHistoricoRubricaVinculo HRV
             set hrv.vlpagamento = vVlPensaoAdiant
           WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                 HRV.CdFolhaPagamento = pCdFolhaPagamento AND
                 HRV.NuSufixoRubrica = vPensao.Nusequencial AND
                HRV.Cdrubricaagrupamento = vPensao.CdRubricaAgrupamento;

      else

         DELETE
           FROM EPagHistoricoRubricaVinculo HRV
          WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                HRV.CdFolhaPagamento = pCdFolhaPagamento AND
                HRV.NuSufixoRubrica = vPensao.Nusequencial AND
                HRV.Cdrubricaagrupamento = vPensao.CdRubricaAgrupamento;

      end if;

      IF PKGPAG_VAR.vgFolha.CdAgrupamento = 134
        THEN

            DELETE
               FROM EPagHistoricoRubricaVinculo HRV
              WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                    HRV.CdFolhaPagamento = pCdFolhaPagamento AND
                    HRV.NuSufixoRubrica = vPensao.Nusequencial AND
                    HRV.Cdrubricaagrupamento IN (PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                              6,
                                                                              0586));

      END IF;

    END LOOP;

END;

FUNCTION fGeraPagamentoCtisp(pCdVinculo in integer,
                             pDtIni  in date,
                             pDtFim  in date) return boolean is

   vCont integer := 0;

begin
 
     SELECT sum(1)
       into vCont
       FROM epvdconvocacaoaposentado conv
         WHERE conv.cdvinculo = pCdVinculo
           AND conv.Dtinicioconvocacao between pDtIni and pDtFim
           AND conv.flgerarpagamento = 'S'
           AND conv.flanulado = 'N';

     if vCont > 0
       then
         vCont := 0;
         begin
            SELECT sum(1)
              into vCont
              FROM epvdconvocacaoaposentado conv
             WHERE conv.cdvinculo = pCdVinculo
               AND pkgpag_var.vgfolha.dtiniciomes
                   between conv.dtinicioconvocacao and conv.dtfimconvocacao
               AND conv.flgerarpagamento = 'N'
               AND conv.flanulado = 'N';

             if vCont > 0
               then
                return false;
             else
                return true;
             end if;

             exception
               when no_data_found
                 then
                   return true;
         end;
     else
        return false;

     end if;

     exception
       when no_data_found
         then
           return false;
       when others
         then
           return false;

end;

PROCEDURE PProcessaLancComplementar(pCdVinculo        IN INTEGER,
                                    pCdFolhaPagamento IN INTEGER) IS  -- 1 Proventos 2 Descontos

vCdExpressaoFormCalc INTEGER :=0;

BEGIN
 
  IF PKGPAG_VAR.vgLancComplementar.COUNT > 0 THEN

    IF pkgpag_var.vgFolha.CdAgrupamento in (4,5)
      THEN

       --
       -- Base de calculo flex 13
       --
       PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,931),
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,931),
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,935),
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,935),
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

    END IF;

    FOR i IN PKGPAG_VAR.vgLancComplementar.FIRST .. PKGPAG_VAR.vgLancComplementar.LAST
    LOOP

      PKGPAG_GERAL.PExcluiRubricaSufixo(pCdVinculo        => pCdVinculo,
                                         pCdFolhaPagamento => pCdFolhaPagamento,
                                         pCdRubrica        => PKGPAG_VAR.vgLancComplementar(i).CdRubricaAgrupamento,
                                         pNuSufixo         => PKGPAG_VAR.vgLancComplementar(i).NuSufixoRubrica,
                                         pFlExcluiAmbos    => 'S');

       -- Comentado em 03/07/2012 - Para o adiantamento de 13º
       IF PKGPAG_VAR.vgLancComplementar(i).CdTipoRubrica IN (1,2,3,4,10,12)/* AND PKGPAG_VAR.vgLancComplementar(i).VlLancamento > 0*/ THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdVinculo            => pCdVinculo,
                                               pCdFolhaPagamento     => pCdFolhaPagamento,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgLancComplementar(i).CdRubricaAgrupamento,
                                               pNuSufixoRubrica      => PKGPAG_VAR.vgLancComplementar(i).NuSufixoRubrica,
                                               pVlPagamento          => NVL(PKGPAG_VAR.vgLancComplementar(i).VlLancamento,0),
                                               pCdTipoOrigemRubrica  => 17);

      -- Comentado em 04/12/2012
      ELSE
         --
         -- Implementacao EPAGRI para executar formulas dos lancamentos complementares com indice informado
         --
         IF pkgpag_var.vgFolha.CdAgrupamento in (4,5)
            and PKGPAG_VAR.vgLancComplementar(i).VlIndice is not null

            THEN

               vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                    pCdRubricaAgrupamento     => PKGPAG_VAR.vgLancComplementar(i).CdRubricaAgrupamento,
                                    pCdRelacaoVinculo         => pkgpag_var.vgCEF(1).CdRelacaoVinculo);

               IF vCdExpressaoFormCalc > 0

                 THEN

                   PKGPAG_GERAL.PInsereLancamentoVinculo(pCdVinculo            => pCdVinculo,
                                                         pCdFolhaPagamento     => pCdFolhaPagamento,
                                                         pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                         pCdRubricaAgrupamento => PKGPAG_VAR.vgLancComplementar(i).CdRubricaAgrupamento,
                                                         pNuSufixoRubrica      => PKGPAG_VAR.vgLancComplementar(i).NuSufixoRubrica,
                                                         pVlPagamento          => 0,
                                                         pVlIndice             => PKGPAG_VAR.vgLancComplementar(i).VlIndice,
                                                         pCdTipoOrigemRubrica  => 17);

                   PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                    pCdVinculo       => pCdVinculo,
                                                    pCdRubrica       => PKGPAG_VAR.vgLancComplementar(i).CdRubricaAgrupamento,
                                                    pTpProcessamento => 1, -- Processa formula rubrica
                                                    pTpLocal         => 2);
              END IF;

            ELSE

               PKGPAG_GERAL.PInsereLancamentoVinculo(pCdVinculo            => pCdVinculo,
                                                     pCdFolhaPagamento     => pCdFolhaPagamento,
                                                     pCdExpressaoFormCalc  => NULL,
                                                     pCdRubricaAgrupamento => PKGPAG_VAR.vgLancComplementar(i).CdRubricaAgrupamento,
                                                     pNuSufixoRubrica      => PKGPAG_VAR.vgLancComplementar(i).NuSufixoRubrica,
                                                     pVlPagamento          => PKGPAG_VAR.vgLancComplementar(i).VlLancamento,
                                                     pCdTipoOrigemRubrica  => 17);

         END IF;

      END IF;

    END LOOP;

  END IF;

END;

PROCEDURE PInsereProventos(pCdVinculo      IN INTEGER,
                           pCdFolhaOrigem  IN INTEGER,
                           pCdFolhaDestino IN INTEGER) IS

  --vCont INTEGER;
  vNuDiasTrab INTEGER;
  vNuDiasMes  INTEGER;
  vdtCalculoNormal DATE;
  vdtCalculoNormalAnt DATE;

BEGIN
 
  INSERT
    INTO epagHistoricoRubricaVinculo HRV
        (cdhistoricorubricavinculo,
         cdfolhapagamento,
         cdrubricaagrupamento,
         cdvinculo,
         nusufixorubrica,
         cdlancamentofinanceiro,
         vlpagamento,
         qtparcelas,
         vlindicerubrica,
         dtultalteracao,
         cdvantagempecuniaria,
         cdrubricatotalizadoravantagem,
         nuordemcalculo,
         cdexpressaoformcalc,
         flvigenciapagamento,
         cdincorporacaoativo,
         vlminrecebincorp,
         flatualizacaoconstante,
         cdtiporubricaorigem,
         vlrubricanormal,
         vlrubricasupl,
         cdbaseconsignacao,
         vlpagamentotrunc,
         cdtipoorigemrubrica,
         deexpressao)
  SELECT spagHistoricoRubricaVinculo.NEXTVAL,
         pCdFolhaDestino,
         HRV.cdrubricaagrupamento,
         HRV.cdvinculo,
         HRV.nusufixorubrica,
         HRV.cdlancamentofinanceiro,
         HRV.vlpagamento,
         HRV.qtparcelas,
         HRV.vlindicerubrica,
         HRV.dtultalteracao,
         HRV.cdvantagempecuniaria,
         HRV.cdrubricatotalizadoravantagem,
         HRV.nuordemcalculo,
         HRV.cdexpressaoformcalc,
         HRV.flvigenciapagamento,
         HRV.cdincorporacaoativo,
         HRV.vlminrecebincorp,
         HRV.flatualizacaoconstante,
         HRV.cdtiporubricaorigem,
         HRV.vlrubricanormal,
         HRV.vlrubricasupl,
         HRV.cdbaseconsignacao,
         HRV.vlpagamentotrunc,
         HRV.cdtipoorigemrubrica,
         HRV.deexpressao
    FROM epagHistoricoRubricaVinculo HRV
   INNER JOIN EpagRubricaAgrupamento RA
      ON HRV.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
   INNER JOIN EPagRubrica R
      ON RA.CdRubrica = R.CdRubrica
   WHERE HRV.CdFolhaPagamento =  pCdFolhaOrigem AND
         HRV.CdVinculo = pCdVinculo AND
         (R.CdTipoRubrica IN (1,2,3,4,10,12) OR
         (R.CdTipoRubrica = 5 AND R.NuRubrica = 617 AND RA.Cdagrupamento = 1) OR
         (R.CdTipoRubrica = 5 AND RA.Cdagrupamento = 4) OR
     (R.CdTipoRubrica = 5 AND R.NuRubrica = 1623) OR
         (R.CdTipoRubrica = 6 AND R.NuRubrica = 983 AND RA.Cdagrupamento = 132) OR
         (R.CdTipoRubrica = 9 AND (RA.CdModalidadeRubrica <> 2 OR RA.CdModalidadeRubrica IS NULL))); -- RETROATIVO

     -- buca a data de calculo da folha origem
     SELECT pag.dtcalculo
       INTO vdtCalculoNormal
       FROM epagfolhapagamento pag
      WHERE pag.cdfolhapagamento = pCdFolhaOrigem;

     -- busca a data do calculo anterior a folha origem
     SELECT NVL(fp.dtcalculo+1, PKGPAG_VAR.vgFolha.DtInicioMes)
       INTO vdtCalculoNormalAnt
       FROM epagfolhapagamento fp
      INNER JOIN (SELECT nuanomesreferencia,
                         cdtipofolhapagamento,
                         cdorgao,
                         cdagrupamento
                    FROM epagfolhapagamento fpg
                   WHERE FPG.CDFOLHAPAGAMENTO IN
                         (SELECT DISTINCT FP2.CDFOLHAPAGAMENTO -- quando há movimentação no mês, busca a folha de outros órgãos
                            FROM EPAGFOLHAPAGAMENTO FP
                           INNER JOIN EPAGFOLHAPAGAMENTO FP2
                              ON FP.NUANOMESREFERENCIA =
                                 FP2.NUANOMESREFERENCIA
                             AND (fp.numesreferencia=12 or (fp.numesreferencia<> 12 AND FP2.FLCALCULODEFINITIVO = 'S'))
                           WHERE FP.CDFOLHAPAGAMENTO = PCDFOLHAORIGEM)) FX
         ON (FX.nuanomesreferencia - 1) = fp.nuanomesreferencia
        AND fx.cdtipofolhapagamento = fp.cdtipofolhapagamento
        AND fp.cdagrupamento = fx.cdagrupamento
        AND fp.flcalculodefinitivo = 'S'
        AND fp.cdtipocalculo = 1
        AND fp.cdorgao = fx.cdorgao
        AND rownum < 2;

   -- Tratar casos de admitidos no mes com direito ao 13 para integralizar o valor.
   -- 12617/2018 - Regra de calculo para o 13º Salario "desproporcionalizacao"
   IF ((PKGPAG_VAR.vgVinculo.DtAdmissao BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND  PKGPAG_VAR.vgFolha.DtFimMes ) OR
       (pkgpag_var.vgVinculo.Dtdesligamento BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND  PKGPAG_VAR.vgFolha.DtFimMes ))
     OR (PKGPAG_VAR.VMOTAFAST.INAFASTADO = 'P' AND PKGPAG_VAR.vMotAfast.InTipoAfastamento in ('D','T') 
            --se a folha de novembro normal foi calculada antes da inclusao do afastamento
            AND (TRUNC(PKGPAG_VAR.vMotAfast.dtInclusao) BETWEEN vdtCalculoNormalAnt AND vdtCalculoNormal)
            AND PKGPAG_VAR.vgFolha.CdAgrupamento NOT IN (2, 4, 5, 6, 136, 276))

      THEN

       IF PKGPAG_VAR.VMOTAFAST.INAFASTADO = 'P' AND 
          NOT pkgpag_var.vgVinculo.Dtdesligamento BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND  PKGPAG_VAR.vgFolha.DtFimMes THEN
          
         vNuDiasTrab := 30 - PKGPAG_GERAL.fdiasafasttempnaorem(pcdvinculo => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                       pdtiniciomes =>pkgpag_var.vgFolha.dtiniciomes,
                                                       pdtfimmes => pkgpag_var.vgfolha.dtfimmes,
                                                       pdtcalculo => pkgpag_var.vgfolha.dtcalculo,
                                                       pflApenasAfastNaoRem => 'S');
        ELSE

         IF PKGPAG_VAR.vgVinculo.DtAdmissao BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND  PKGPAG_VAR.vgFolha.DtFimMes then

            vNuDiasTrab := TO_CHAR(PKGPAG_VAR.vgFolha.DtFimMes,'DD') - TO_CHAR(PKGPAG_VAR.vgVinculo.DtAdmissao,'DD') + 1;

         elsif pkgpag_var.vgVinculo.Dtdesligamento BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND  PKGPAG_VAR.vgFolha.DtFimMes then

             vNuDiasTrab := TO_CHAR(PKGPAG_VAR.vgVinculo.Dtdesligamento,'DD') - TO_CHAR(PKGPAG_VAR.vgFolha.DtInicioMes,'DD') + 1;

         end if;

        END IF;

         vNuDiasMes  := TO_CHAR(PKGPAG_VAR.vgFolha.DtFimMes,'DD');

         IF vNuDiasTrab > 30 THEN
            vNuDiasTrab := 30;
         END IF;

         IF vNuDiasMes > 30 THEN
            vNuDiasMes := 30;
         END IF;

         if vNuDiasTrab > 0 then

             UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.VlPagamento =trunc(trunc((HRV.Vlpagamento / vNuDiasTrab),2) * vNuDiasMes ,2) --Desproporcionalizando a rubrica
             WHERE HRV.CdFolhaPagamento = pCdFolhaDestino
             AND   HRV.Cdvinculo = pCdVinculo;

         end if;

   END IF;

   BEGIN

     SELECT HRV.CdRubricaAgrupamento
       INTO PKGPAG_VAR.vgCdRubricaAbonoPerm
       FROM ePagHistoricoRubricaVinculo HRV
      INNER JOIN EpagRubricaAgrupamento RA
         ON HRV.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
      INNER JOIN EPagRubrica R
         ON RA.CdRubrica = R.CdRubrica
      WHERE HRV.CdFolhaPagamento = pCdFolhaDestino AND
            HRV.CdVinculo = pCdVinculo AND
            R.CdTipoRubrica = 1 AND R.NuRubrica = 914 AND
            ROWNUM < 2;

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       PKGPAG_VAR.vgCdRubricaAbonoPerm := 0;

   END;
END;

FUNCTION FValorIsentoTeto13Sal(pCdVinculo        IN INTEGER,
                                pCdFolhaPagamento IN INTEGER,
                                pNuAnoReferencia  IN INTEGER,
                                pNuMesReferencia  IN INTEGER)

    RETURN NUMBER IS

    vVlIsento NUMBER(15,4);
    vVlIsentoJud NUMBER(15,4);

BEGIN
 
    BEGIN

    SELECT SUM(PAG.VlPagamento)
        INTO vVlIsento
        FROM ePagHistoricoRubricaVinculo PAG
       INNER JOIN ePagRubricaAgrupamento RUB
          ON RUB.CdRubricaAgrupamento = PAG.CdRubricaAgrupamento
       INNER JOIN ePagRubrica R
          ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
      -------- descobre rubricas isentas do teto de 13 Sal
       INNER JOIN (SELECT TR.CdVinculo,
                          TR.CdRubricaAgrupamento
                   FROM ETrbIsencaoRubrica TR
                  INNER JOIN ETrbHistIsencaoRubrica HTR
                     ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                  INNER JOIN ETrbRubricaIsentaFormula RIF
                     ON RIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica AND
                        RIF.CdRubricaAgrupFormula IN
                          (PKGPAG_VAR.vgCdRubricaBaseTetoGov13,PKGPAG_VAR.vgCdRubricaBaseTetoGov)
                  WHERE TR.CdVinculo = pCdVinculo AND
                        TR.FlRubricaIsentaFormula = PKGPAG_TIPO.cnS AND
                        ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                        (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                        HTR.NuMesInicioVigencia <= pNuMesReferencia))
                        AND
                        (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                        (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                        HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                        HTR.NuMesFimVigencia IS NULL)) AND
                        ROWNUM < 2) TR
           ON TR.CdVinculo = PAG.CdVinculo AND
              TR.CdRubricaAgrupamento = PAG.CdRubricaAgrupamento
       -------- descobre rubricas que incidem na base do 13 salario
        INNER JOIN (SELECT RUBEX2.CdRubricaAgrupamento
                      FROM epagrubricaagrupamento RUBM2
                     INNER JOIN epagbasecalculo base2
                        ON base2.cdbasecalculo = rubm2.cdbasecalculo
                     INNER JOIN epagbasecalculoversao bv2
                        ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                     INNER JOIN ePagHistBaseCalculo hb2
                        ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                     INNER JOIN epagbasecalculobloco bl2
                        ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                     INNER JOIN epagbasecalculoblocoexpressao ex2
                        ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                     INNER JOIN Epagbasecalcblocoexprrubagrup RUBEX2
                        ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                      WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal) B
             ON B.CdRubricaAgrupamento = PAG.CdRubricaAgrupamento
          WHERE PAG.CdVinculo = pCdVinculo AND
                PAG.CdFolhaPagamento = pCdFolhaPagamento;

   EXCEPTION
     WHEN OTHERS THEN
       vVlIsento := 0;

   END;

   -- VERIFICAR SE TEM ISENCAO DA BASE DE CALCULO DO 13º REFERENTE AS RUBRICAS QUE COMPOE A BASE DA DECISAO JUDICIAL
   -- E PARA QUEM TEM A DECISAO JUDICIAL REF. A RUBRICA 01-1025.

   BEGIN

   SELECT SUM(PAG.VlPagamento)
        INTO vVlIsentoJud
        FROM ePagHistoricoRubricaVinculo PAG
       INNER JOIN ePagRubricaAgrupamento RUB
          ON RUB.CdRubricaAgrupamento = PAG.CdRubricaAgrupamento
       INNER JOIN ePagRubrica R
          ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
      -------- descobre rubricas isentas do teto de 13 Sal
       INNER JOIN (SELECT TR.CdVinculo,
                          TR.CdRubricaAgrupamento
                   FROM ETrbIsencaoRubrica TR
                  INNER JOIN ETrbHistIsencaoRubrica HTR
                     ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                  INNER JOIN ETrbRubricaIsentaFormula RIF
                     ON RIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica AND
                        RIF.CdRubricaAgrupFormula IN
                          (PKGPAG_VAR.vgCdRubricaBaseTetoGov13) --,PKGPAG_VAR.vgCdRubricaBaseTetoGov)
                  WHERE TR.CdVinculo = pCdVinculo AND
                        TR.FlRubricaIsentaFormula = PKGPAG_TIPO.cnS AND
                        ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                        (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                        HTR.NuMesInicioVigencia <= pNuMesReferencia))
                        AND
                        (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                        (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                        HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                        HTR.NuMesFimVigencia IS NULL))) TR
           ON TR.CdVinculo = PAG.CdVinculo AND
              TR.CdRubricaAgrupamento = PAG.CdRubricaAgrupamento
       -------- descobre rubricas que incidem na base do 13 salario
        INNER JOIN (SELECT RUBEX2.CdRubricaAgrupamento
                      FROM epagrubricaagrupamento RUBM2
                     INNER JOIN epagbasecalculo base2
                        ON base2.cdbasecalculo = rubm2.cdbasecalculo
                     INNER JOIN epagbasecalculoversao bv2
                        ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                     INNER JOIN ePagHistBaseCalculo hb2
                        ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                     INNER JOIN epagbasecalculobloco bl2
                        ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                     INNER JOIN epagbasecalculoblocoexpressao ex2
                        ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                     INNER JOIN Epagbasecalcblocoexprrubagrup RUBEX2
                        ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                      WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                        9, -- Base decisao judicial
                                                                        1110) AND
                      EXISTS (SELECT 1
                                      FROM EPagEventoPagAgrupDecisao EPD
                                     WHERE EPD.CdVinculo = pCdVinculo AND
                                        EPD.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                        1,
                                                                        1025) -- 38321 -- Rub Dec. Judicial 01-1025
                                       AND ((EPD.NuAnoInicioDireito < pNuAnoReferencia OR
                                           (EPD.NuAnoInicioDireito = pNuAnoReferencia AND
                                           EPD.NuMesInicioDireito <= pNuMesReferencia)) AND
                                           (EPD.NuAnoFimDireito > pNuAnoReferencia OR
                                           (EPD.NuAnoFimDireito = pNuAnoReferencia AND
                                           EPD.NuMesFimDireito >= pNuMesReferencia) OR
                                           EPD.NuAnoFimDireito IS NULL))
                                       AND EPD.FlAnulado = 'N'   )) B
             ON B.CdRubricaAgrupamento = PAG.CdRubricaAgrupamento
          WHERE PAG.CdVinculo = pCdVinculo AND
                PAG.CdFolhaPagamento = pCdFolhaPagamento;

  EXCEPTION
     WHEN OTHERS THEN
       vVlIsentoJud := 0;

  END;

     RETURN NVL(vVlIsento,0) + NVL(vVlIsentoJud,0);

 END;

PROCEDURE PGeraSalMaternidade13(pVinculo         IN PKGPAG_TIPO.rVinculo,
                                pFolha            IN PKGPAG_TIPO.rFolha) IS

  vCdRub01_1009        INTEGER;

  vCdRub05_1509        INTEGER;

  vCdExpressaoFormCalc INTEGER;

BEGIN
 
  IF pVinculo.CdRegimePrevidenciario = PKGPAG_TIPO.cnRegPrevGeral AND pVinculo.FlSexo = 'F' THEN

    vCdRub01_1009 := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                  1,
                                                  1009);

    vCdRub05_1509 := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                  5,
                                                  1509);

    IF vCdRub01_1009 > 0 THEN

      vCdExpressaoFormCalc :=

           PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                  pCdRubricaAgrupamento     => vCdRub01_1009,
                                                  pCdRelacaoVinculo         => 0);

      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => vCdRub01_1009,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pVinculo.CdVinculo,
                                         pCdRubrica       => vCdRub01_1009,
                                         pTpProcessamento => 1,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

    END IF;

    IF vCdRub05_1509 > 0 THEN

      vCdExpressaoFormCalc :=

           PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                  pCdRubricaAgrupamento     => vCdRub05_1509,
                                                  pCdRelacaoVinculo         => 0);

      IF vCdExpressaoFormCalc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => vCdRub05_1509,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_FB.PProcessaFormulasBases(pFolha            => pFolha,
                                         pCdVinculo       => pVinculo.CdVinculo,
                                         pCdRubrica       => vCdRub05_1509,
                                         pTpProcessamento => 1,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

    END IF;

  END IF;

END;

-----------------------------------------------------------------------------
-- Gera totalizadoras e a capa de lote de 13/Adiantamento
-----------------------------------------------------------------------------

PROCEDURE PGeraTotalizadoras(pCalculo               IN PKGPAG_CAL.rCalculo,
                             pCdVinculo             IN INTEGER,
                             pCdFolhaPagamento      IN INTEGER,
                             pVlPercentContribIndiv IN NUMBER DEFAULT NULL
                             ) IS

  vFolha               PKGPAG_TIPO.rFolha;

  vVlDevAntNaoEfetuada NUMBER(13,2);

  FUNCTION FPensoesDescontadas

    RETURN INTEGER IS

    vCont INTEGER;

  BEGIN
 
    vCont := 0;

    SELECT COUNT(*)
      INTO vCont
      FROM EPagHistoricoRubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.CdVinculo = pCdVinculo AND
           HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensao13;

    RETURN vCont;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;

  END;

BEGIN
 
  OPEN PKGPAG_VAR.cFolha(pCdFolhaPagamento);

  FETCH PKGPAG_VAR.cFolha INTO vFolha;

  CLOSE PKGPAG_VAR.cFolha;

  PKGPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => pCdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo);

  -----------------------------------------------------------------------------
  -- Insere Total de Proventos
  -----------------------------------------------------------------------------

  IF PKGPAG_VAR.vgVlTotalProventos > 0 THEN

    DELETE
      FROM EPagHistoricoRubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.CdVinculo = pCdVinculo AND
           HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTotPrv;

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotPrv,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => PKGPAG_VAR.vgVlTotalProventos,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);
  END IF;

  -----------------------------------------------------------------------------
  -- Insere Total de Descontos
  -----------------------------------------------------------------------------

  IF PKGPAG_VAR.vgVlTotalDescontos > 0 THEN

    DELETE
      FROM EPagHistoricoRubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.CdVinculo = pCdVinculo AND
           HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTotDsc;

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotDsc,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => PKGPAG_VAR.vgVlTotalDescontos,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);
  END IF;

  ------------------------------------------------------------------------------
  -- Verificacao de liquido negativo de pensao
  ------------------------------------------------------------------------------

  FOR vPagPensao IN (SELECT B.CdHistoricoRubricaVinculo,
                            A.VlPagamento,
                            B.vlPagamento - A.Vlpagamento AS VlAdiantNaoeEfetuado,
                            B.NuSufixoRubrica
                       FROM (SELECT HRV.CdHistoricoRubricaVinculo,
                                    HRV.CdRubricaAgrupamento,
                                    HRV.NuSufixoRubrica,
                                    HRV.VlPagamento
                               FROM EPagHistoricoRubricaVinculo hrv
                              WHERE CdFolhaPagamento = pcdFolhaPagamento AND
                                    CdVinculo = pCdVinculo AND
                                    CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensao13) A
                      INNER JOIN (SELECT HRV.Cdhistoricorubricavinculo,
                                         HRV.CdRubricaAgrupamento,
                                         HRV.NuSufixoRubrica,
                                         HRV.VlPagamento
                                    FROM EPagHistoricoRubricaVinculo hrv
                                   WHERE CdFolhaPagamento = pcdFolhaPagamento AND
                                         CdVinculo = pCdVinculo AND
                                         CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                4,
                                                                1586)) B
                        ON A.NuSufixoRubrica = B.NuSufixoRubrica
                     WHERE A.VlPagamento < B.VlPagamento)

   LOOP

     UPDATE EPagHistoricoRubricaVinculo
        SET vlPagamento = vPagPensao.VlPagamento
      WHERE CdHistoricoRubricaVinculo = vPagPensao.CdHistoricoRubricaVinculo;

     UPDATE EPagHistoricoRubricaVinculo
        SET vlPagamento = vlPagamento - vPagPensao.VlAdiantNaoeEfetuado
      WHERE CdFolhaPagamento = pCdFolhaPagamento AND
            CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTotPrv AND
            CdVinculo = pCdVinculo ;

     PKGPAG_VAR.vgVlTotalProventos := PKGPAG_VAR.vgVlTotalProventos - vPagPensao.VlAdiantNaoeEfetuado;

     PKGPAG_VAR.vgVlBaseTotalLiquida := PKGPAG_VAR.vgVlBaseTotalLiquida - vPagPensao.VlAdiantNaoeEfetuado;

     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                           pCdVinculo            => pCdVinculo,
                                           pCdExpressaoFormCalc  => NULL,
                                           pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDevAd13NaoEfet,
                                           pNuSufixoRubrica      => vPagPensao.NuSufixoRubrica,
                                           pVlPagamento          => vPagPensao.VlAdiantNaoeEfetuado,
                                           pVlIndice             => NULL,
                                           pCdTipoOrigemRubrica  => 1);

     PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                            pCalculo.CdHistoricoParamCalculo,
                            PKGPAG_VAR.vgVinculo.CdPessoa,
                            'Valor de desconto de adiantamento de pensão descontado parcialmente.',
                            PKGPAG_VAR.vgVinculo.CdVinculo,
                            2,
                            20);

   END LOOP;

  ------------------------------------------------------------------------------
  -- Insere Total Liquido
  ------------------------------------------------------------------------------

  DELETE
    FROM EPagHistoricoRubricaVinculo HRV
   WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
         HRV.CdVinculo = pCdVinculo AND
         HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTotLiq;

  IF PKGPAG_VAR.vgVlBaseTotalLiquida > 0.01 THEN

    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotLiq,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => PKGPAG_VAR.vgVlBaseTotalLiquida,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

  ELSIF vFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaAdiant13) THEN

    -- Exclui contracheque zerado, caso nao possua rubrica 5-471 (DEPOSITO JUDICIAL)
    IF NOT (PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                              pCdVinculo,
                                              PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                       5,
                                                                       471)) > 0) THEN

      DELETE
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo;

    END IF;

  -- Retirada do liquido negativo atraves de compensacao do valor da devolucao do adiantamento de 13o
  ELSIF vFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaResidente13, PKGPAG_TIPO.cnTpFolhaCTISP13)THEN

     IF PKGPAG_VAR.vgFolha.CdAgrupamento <> 2 AND
       PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                         pCdVinculo,
                                         PKGPAG_VAR.vgCdRubricaDevAnt13
                                         ) > 0 THEN

       PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => ABS(PKGPAG_VAR.vgVlBaseTotalLiquida),
                                             pVlIndice             => NULL,
                                             pCdTipoOrigemRubrica  => 1);

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - ABS(PKGPAG_VAR.vgVlBaseTotalLiquida)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaDevAnt13;

      vVlDevAntNaoEfetuada := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                                                pCdVinculo,
                                                                PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado);

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - nvl(vVlDevAntNaoEfetuada,0)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTotDsc;
      --
      -- Solicitacao de Sustentacao #74520
      -- Acertar total de descontos na capa do contracheque - rotina de folha
      --
      PKGPAG_VAR.vgVlTotalDescontos := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                                                          pCdVinculo,PKGPAG_VAR.vgCdRubricaBaseTotDsc);

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vgVinculo.CdPessoa,
                              'Valor de desconto de adiantamento descontado parcialmente.',
                              PKGPAG_VAR.vgVinculo.CdVinculo,
                              2,
                              17);

     -- Retirada do liquido negativo atraves de compensacao do valor de pensao quando existe apenas uma
     ELSIF PKGPAG_VAR.vgFolha.CdAgrupamento <> 2 AND FPensoesDescontadas = 1  THEN

       PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBasePensaoNaoDesc,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => ABS(PKGPAG_VAR.vgVlBaseTotalLiquida),
                                             pVlIndice             => NULL,
                                             pCdTipoOrigemRubrica  => 1);

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - ABS(PKGPAG_VAR.vgVlBaseTotalLiquida)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensao13;

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - ABS(PKGPAG_VAR.vgVlBaseTotalLiquida)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTotDsc;

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                               pCalculo.CdHistoricoParamCalculo,
                               PKGPAG_VAR.vgVinculo.CdPessoa,
                               'Valor de pensao de 13 salário não descontado.',
                               PKGPAG_VAR.vgVinculo.CdVinculo,
                               2,
                               18);

     ELSE

      IF ABS(PKGPAG_VAR.vgVlBaseTotalLiquida) > 0 THEN

        -------------------------------------------------------------------------------------------
        -- Geracao de liquido negativo
        -------------------------------------------------------------------------------------------
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pCdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgParamOrgao.CdRubricaProvento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => ABS(PKGPAG_VAR.vgVlBaseTotalLiquida),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

         UPDATE EPagHistoricoRubricaVinculo HRV
            SET HRV.VlPagamento =  HRV.VlPagamento - ABS(PKGPAG_VAR.vgVlBaseTotalLiquida)
          WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
                HRV.CdVinculo = pCdVinculo AND
                HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTotDsc;

         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 pCalculo.CdHistoricoParamCalculo,
                                 PKGPAG_VAR.vgVinculo.CdPessoa,
                                 'Geração de líquido negativo.',
                                 PKGPAG_VAR.vgVinculo.CdVinculo,
                                 2,
                                 6);

        END IF;

      END IF;

    else
      null;
    END IF;

   ----------------------------------------------------------------------------------
   -- Gera a capa de lote
   ----------------------------------------------------------------------------------

     PKGPAG_GERAL.PGeraCapaLote(pCdFolhaPagamento         => pCdFolhaPagamento,
                                pCdVinculo                => pCdVinculo,
                                pFlAtivo                  => pkgpag_geral.fflativo(PKGPAG_VAR.vgVinculo.CdVinculo, PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria),
                                pMotAfast                 => NULL,
                                pFlPagamentoBloqueado     => PKGPAG_VAR.vgVinculo.FlPagamentoBloqueado,
                                pVlPercentContribIndiv    => pVlPercentContribIndiv);
                                
     IF PKGPAG_VAR.vgVinculo.FlPagamentoBloqueado = 'S' THEN

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                pCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vgVinculo.CdPessoa,
                                'Servidor com pagamento de 13o salário bloqueado.',
                                PKGPAG_VAR.vgVinculo.CdVinculo,
                                2,
                                11);

     END IF;

END;

FUNCTION FPossuiDesbloqueioRemun (pCdVinculo            IN INTEGER,
                                  pCdRubricaAgrupamento IN INTEGER,
                                  pNuAnoReferencia      IN INTEGER,
                                  pNuMesReferencia      IN INTEGER)

  RETURN BOOLEAN IS

  vVlDeterminado NUMBER(13,2);

BEGIN
 
  SELECT EPD.VlDeterminado
    INTO vVlDeterminado
    FROM EPagEventoPagAgrupDecisao EPD
   WHERE EPD.CdVinculo = pCdVinculo AND
         EPD.CdRubricaAgrupamento = pCdRubricaAgrupamento AND
         ((EPD.NuAnoInicioDireito < pNuAnoReferencia OR
          (EPD.NuAnoInicioDireito = pNuAnoReferencia AND
           EPD.NuMesInicioDireito <= pNuMesReferencia))
           AND
          (EPD.NuAnoFimDireito > pNuAnoReferencia OR
          (EPD.NuAnoFimDireito = pNuAnoReferencia AND
           EPD.NuMesFimDireito >= pNuMesReferencia) OR
           EPD.NuAnoFimDireito IS NULL)) AND
           ROWNUM <2;

  RETURN TRUE;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

END;

FUNCTION fPercentualAts(pCdVinculo IN INTEGER,
                        pDtFim     IN DATE)

   RETURN NUMBER IS

BEGIN
 
  if pkgpag_var.vgFolha.CdOrgao = 443 then -- SIG-9095 DPE-SC - folha 13 salario - rubrica 09-0920 e 01-0016

     SELECT sum(PA.VlPercentualDireito)
       INTO pkgpag_var.vgpercentacumats(1)
       FROM EPagPeriodoAquistempServ PA
       INNER JOIN EBpcRegraTipoAdicionalTempServ RTS
          ON PA.CdRegraTipoAdicionalTempServ =
            RTS.CdRegraTipoAdicionalTempServ
       INNER JOIN EPAGHISTEVENTOPAGAGRUP EVH
          ON EVH.CDTIPOTEMPOSERVICO =  RTS.CDTIPOADICIONALTEMPSERV
       WHERE PA.CdVinculo = pCdVinculo
        AND PA.DtFimConquista <= pDtFim
        AND (PA.DtFimConquista >=  evh.DtInicioConquistaPerAquis AND
            (PA.DtFimConquista <=  evh.DtFimConquistaPerAquis OR
            evh.DtFimConquistaPerAquis IS NULL))
        AND RTS.CdTipoAdicionalTempServ =  evh.CdTipoTempoServico
        AND PA.CdSituacaoPerAquisitivo = 2
        AND PA.FlPago = PKGPAG_TIPO.cnS;

  else

      SELECT SUM(PA.VLPERCENTUALDIREITO)
        INTO pkgpag_var.vgpercentacumats(1)
        FROM EPagPeriodoAquistempServ PA
        INNER JOIN EBpcRegraTipoAdicionalTempServ RTS
                ON PA.CdRegraTipoAdicionalTempServ = RTS.CdRegraTipoAdicionalTempServ
        INNER JOIN EBPCTIPOADICIONALTEMPSERV ETS
           ON ETS.CDTIPOADICIONALTEMPSERV = RTS.CDTIPOADICIONALTEMPSERV
        INNER JOIN EPAGHISTEVENTOPAGAGRUP EVH
           ON EVH.CDTIPOTEMPOSERVICO =  RTS.CDTIPOADICIONALTEMPSERV
        WHERE PA.CdVinculo = pCdVinculo
          AND PA.DtFimConquista <= pDtFim
          AND (PA.DtFimConquista >= evh.DtInicioConquistaPerAquis AND
              (PA.DtFimConquista <= EVH.DtFimConquistaPerAquis OR
              EVH.DtFimConquistaPerAquis IS NULL))
          AND RTS.CdTipoAdicionalTempServ =  EVH.CdTipoTempoServico
          AND PA.CdSituacaoPerAquisitivo = 2
          AND PA.FlPago = PKGPAG_TIPO.cnS
          AND EVH.CDTIPOTEMPOSERVICO = 2
          AND ((EVH.NuAnoRefInicial < to_number(TO_CHAR(pDtFim,'yyyy'))
                OR (EVH.NuAnoRefInicial = to_number(TO_CHAR(pDtFim,'yyyy')) AND
                    EVH.NumesRefInicial <= to_number(TO_CHAR(pDtFim,'mm'))))
               AND (EVH.NuAnoRefFinal > to_number(TO_CHAR(pDtFim,'yyyy')) OR
                   (EVH.NuAnoRefFinal = to_number(TO_CHAR(pDtFim,'yyyy'))  AND
                    EVH.NuMesRefFinal >= to_number(TO_CHAR(pDtFim,'mm'))) OR
                    EVH.NuMesRefFinal IS NULL));

   end if;

   RETURN pkgpag_var.vgpercentacumats(1);

   EXCEPTION
     WHEN OTHERS
       THEN
         RETURN 0;

END;

FUNCTION FRetornaValorIsentoTeto(pCdVinculo IN INTEGER,
                                 pFolha     IN PKGPAG_TIPO.rFolha)

  RETURN NUMBER IS

  vVlIsencaoBloqueio NUMBER(13,2);

BEGIN
 
  SELECT SUM(VlPagamento)
         INTO vVlIsencaoBloqueio
         FROM ( SELECT HRV.VlPagamento
                  FROM EPagHistoricoRubricaVinculo HRV
                 INNER JOIN ETrbIsencaoRubrica TR
                    ON TR.CdVinculo = HRV.CdVinculo AND
                       TR.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
                 INNER JOIN ETrbHistIsencaoRubrica HTR
                    ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                 INNER JOIN ETrbRubricaIsentaFormula RI
                    ON HTR.CdHistIsencaoRubrica = RI.CdHistIsencaoRubrica
                 INNER JOIN EPagRubricaAgrupamento RA
                    ON RA.CdRubricaAgrupamento = RI.CdRubricaAgrupFormula
                 INNER JOIN EPagRubrica R
                    ON R.CdRubrica = RA.CdRubrica
                 WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                       HRV.CdVinculo = pCdVinculo AND
                       R.CdTipoRubrica = 9 AND R.NuRubrica = 983 AND
                       TR.FlRubricaIsentaFormula = PKGPAG_TIPO.cnS AND
                       ((HTR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                       (HTR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                       HTR.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                       AND
                       (HTR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                       (HTR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                       HTR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                       HTR.NuMesFimVigencia IS NULL)) AND
                       RI.CdRubricaAgrupFormula IN
                       (SELECT RUBEX2.CdRubricaAgrupamento
                          FROM EPagRubricaAgrupamento RUBM2
                         INNER JOIN EPagBaseCalculo base2
                            ON base2.CdBaseCalculo = rubm2.CdBaseCalculo
                         INNER JOIN EPagBaseCalculoVersao bv2
                            ON bv2.CdBaseCalculo = base2.CdBaseCalculo AND bv2.NuVersao = 1
                         INNER JOIN EPagHistBaseCalculo hb2
                            ON hb2.CdVersaoBaseCalculo = bv2.CdVersaoBaseCalculo and hb2.NuAnoFimVigencia IS NULL
                         INNER JOIN EPagBaseCalculoBloco bl2
                            ON bl2.CdHistBaseCalculo = hb2.CdHistBaseCalculo
                         INNER JOIN EPagBaseCalculoBlocoExpressao ex2
                            ON ex2.CdBaseCalculoBloco = bl2.CdBaseCalculoBloco
                         INNER JOIN EPagBaseCalcBlocoExprRubAgrup RUBEX2
                            ON RUBEX2.CdBaseCalculoBlocoExpressao = ex2.CdBaseCalculoBlocoExpressao
                          WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal));

      RETURN NVL(vVlIsencaoBloqueio,0);

  EXCEPTION

    WHEN OTHERS THEN

       RETURN 0;

END ;

PROCEDURE PInsereLancErario(pCdVinculo            IN INTEGER,
                             pCdRubricaAgrupamento IN INTEGER,
                             pVlPagamento          IN NUMBER,
                             pDtInicioMes          IN DATE) IS

BEGIN
 
      INSERT
        INTO EPagLancamentoFinanceiro
            (CdLancamentoFinanceiro,
             CdVinculo,
             NuSufixoRubrica,
             DtInicioDireito,
             DtFimDireito,
             FlValorProporcional,
             NuParcelas,
             FlPagaAfastDefinitivo,
             NuCpfCadastrador,
             DtInclusao,
             DtUltalteracao,
             VlIndice,
             VlLancamentofinanceiro,
             FlAnulado,
             CdRubricaAgrupamento,
             InPeriodicidade,
             FlAcertoAuto13Sal,
             FlObservaLimretroativoErario)
      VALUES (SPagLancamentoFinanceiro.NextVal,
              pCdVinculo,
              1,
              pDtInicioMes,
              NULL,
              'N',
              NULL,
              'N',
              '00000000000',
              sysdate,
              systimestamp,
              NULL,
              pVlPagamento,
              'N',
              pCdRubricaAgrupamento,
              'Q',
              'S',
              'S');

END;

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

PROCEDURE PGeraProventos(pCdVinculo        IN INTEGER,
                         pCdFolha13        IN INTEGER, -- 13o ou Adiantamento
                         pCdFolhaNormal    IN INTEGER,
                         pCdFolhaRecalculo IN INTEGER,
                         pDtInicioMes      IN DATE,
                         pDtFimMes         IN DATE ) IS

  vDtInicioMes    DATE;

  vNuMes          INTEGER;

  vNuAno          INTEGER;

  vCdFolha        INTEGER;

 vcdFolhaRecalculo       INTEGER;
  -------------------------------------------------------
  --
  -------------------------------------------------------


BEGIN
 
  vDtInicioMes   := pDtInicioMes;

  vNuMes         := TO_CHAR(vDtInicioMes,'MM');

  vNuAno         := TO_CHAR(vDtInicioMes,'YYYY');

  IF FTemPagamento(PKGPAG_VAR.vgCdFolhaSuplementar) THEN

    BEGIN
     
     SELECT DISTINCT FP.CDFOLHAVINCSUPL
       INTO VCDFOLHARECALCULO
       FROM EPAGHISTORICORUBRICAVINCULO HRV
      INNER JOIN EPAGFOLHAPAGAMENTO FP
         ON FP.CDFOLHAVINCSUPL = HRV.CDFOLHAPAGAMENTO
        AND FP.NUANOREFERENCIA = VNUANO
        AND FP.NUMESREFERENCIA = VNUMES
        AND HRV.CDVINCULO = PCDVINCULO
        AND FP.FLCALCULODEFINITIVO = 'S'
      WHERE ROWNUM < 2;
      
    EXCEPTION
            
      WHEN NO_DATA_FOUND THEN
        
        VCDFOLHARECALCULO := 0 ;
        
    END;
        
    IF NVL(vcdFolhaRecalculo, 0) = 0
      THEN
        vcdFolhaRecalculo := pcdFolhaRecalculo;
    END IF;

    PInsereProventos(pCdVinculo,
                     vcdFolhaRecalculo,
                     pCdFolha13);

    PKGPAG_VAR.vgCdFolhaReplicada13 := vcdFolhaRecalculo;

  ELSIF FTemPagamento(pCdFolhaNormal, pkgpag_var.vgFolha.CdTipoFolha) THEN

    PInsereProventos(pCdVinculo,
                     pCdFolhaNormal,
                     pCdFolha13);

    PKGPAG_VAR.vgCdFolhaReplicada13 := pCdFolhaNormal;

  ELSE

    vNuMes       := vNuMes - 1;

    WHILE vNuMes >= 1
    LOOP

      BEGIN

        SELECT FP.CdFolhaPagamento
          INTO vCdFolha
          FROM EPagHistoricoRubricaVinculo HRV
         INNER JOIN EPagFolhaPagamento FP
            ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
         INNER JOIN EPagTipoFolhaPagamento TFP
            ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
         WHERE HRV.CdVinculo = pCdVinculo AND
               FP.NuAnoReferencia = vNuAno AND
               FP.NuMesReferencia = vNuMes AND
               TFP.CdTipoFolha = case when pkgpag_var.vgFolha.CdTipoFolha in (pkgpag_tipo.cnTpFolhaCtisp13, pkgpag_tipo.cnTpFolhaAdiant13Ctisp)
                                      then pkgpag_tipo.cnTpFolhaCtisp
                                      when pkgpag_var.vgFolha.CdTipoFolha in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13)
                                      then pkgpag_tipo.cnTpFolhaOutras
                   else PKGPAG_TIPO.cnTpFolhaNormal
                 end AND
               FP.CdTipoCalculo = PKGPAG_TIPO.cn1 AND
               FP.FlCalculoDefinitivo = 'S' AND
               ROWNUM < 2;

        PInsereProventos(pCdVinculo,
                         vCdFolha,
                         pCdFolha13);

        PKGPAG_VAR.vgCdFolhaReplicada13 := vCdFolha;

        EXIT;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          vNuMes := vNuMes - 1;

      END;

    END LOOP;

  END IF;
  --
  -- Armazenar parametros da folha replicada para utilizacao em formulas de media
  -- para rubricas que devem ser recalculadas para o decimo terceiro.
  -- Ex: Media de horas extras.
  --

  pkgpag_param.PArmazenaInfoFolhaAuxiliar(PKGPAG_VAR.vgCdFolhaReplicada13);

END;

PROCEDURE PReprocessa13Salario(pCdVinculo        IN INTEGER,
                               pCdAgrupamento    IN INTEGER,
                               pCdFolhaPagamento IN INTEGER,
                               pCdFolha13Ant     IN INTEGER,
                               pCdFolha13        IN INTEGER) IS

  vVlDevAnt13NaoEfetuado    NUMBER(13,2);

  vCdRubDevAnt13NaoEfetuado INTEGER;

  vVlAnt13SemFolhaAnt       NUMBER(13,2);

  vCdRubDevAntecip13        INTEGER;

  vCdRubDifAntecip13        INTEGER;

  vCdFolha13Ant             INTEGER;

  vCdRubricaIRRF13          INTEGER;

  vgCdRubricaAbonoPerm13    integer;

  vVlBase983                NUMBER(13,2) := 0;

  vVlInss13Total            number(13,2);

  bPossuiDuploVinculo       boolean := false;

  CURSOR cSuplementar (pCdFolhaPagamento     INTEGER,
                       pCdFolhaOrigem        INTEGER,
                       pCdFolhaVincSupl      INTEGER,
                       pCdVinculo            INTEGER,
                       pCdRubricaAgrupamento INTEGER,
                       pCdRubricaAbonoPerm13 integer default null,
                       pCdRubricaIRRF13      INTEGER DEFAULT NULL) IS
     SELECT *
       FROM
     (SELECT pCdFolhaPagamento AS CdFolhaPagamento,
             RA.CdRubricaagrupamento,
             RA.CdAgrupamento,
             S.CdVinculo,
             CASE WHEN RS.CdTipoRubricaGerada <> 9 THEN
               ABS(vlPagamentoSupl - vlPagamentoOrigem)
             ELSE
               GREATEST(vlPagamentoSupl - vlPagamentoOrigem,0)
             END AS VlPagamento,
             S.NuSufixoRubrica,
             S.vlPagamentoOrigem,
             S.vlPagamentoSupl,
             RS.CdTipoRubricaOrigem,
             RS.CdTipoRubricaGerada as CdTipoRubrica,
             RA.FlGeraSuplementar,
             RA.FlTributacao,
             R.NuRubrica,
             S.CdRubricaAgrupamento AS CdRubricaAgrupOrigem
        FROM (SELECT R.CdTipoRubrica,
                     R.NuRubrica,
                     H1.Cdvinculo,
                     RA.CdAgrupamento,
                     H1.CdRubricaAgrupamento,
                     H1.VlPagamentoOrigem,
                     H2.VlPagamentoSupl,
                     H1.NuSufixoRubrica,
                     CASE
                       WHEN vlPagamentoOrigem > vlPagamentoSupl THEN
                         PKGPAG_TIPO.cnS
                       ELSE
                         PKGPAG_TIPO.cnN
                     END FlValorOrigemMaior
                FROM (SELECT H1.CdVinculo,
                             H1.CdRubricaAgrupamento,
                             H1.NuSufixoRubrica,
                             SUM(H1.VlPagamento) AS vlPagamentoOrigem
                        FROM  EPagHistoricoRubricaVinculo H1
                       WHERE H1.CdFolhapagamento = pCdFolhaOrigem AND
                             H1.CdVinculo = pCdVinculo
                       GROUP BY H1.CdVinculo,
                                H1.CdRubricaAgrupamento,
                                H1.NuSufixoRubrica) H1
               INNER JOIN (SELECT H2.CdVinculo,
                                  H2.CdRubricaAgrupamento,
                                  H2.NuSufixoRubrica,
                                  SUM(H2.VlPagamento) AS vlPagamentoSupl
                             FROM EPagHistoricoRubricaVinculo H2
                            WHERE H2.CdFolhapagamento = pCdFolhaVincSupl AND
                                  H2.CdVinculo = pCdVinculo
                            GROUP BY H2.CdVinculo,
                                     H2.CdRubricaAgrupamento,
                                     H2.NuSufixoRubrica) H2
                  ON H1.CdVinculo = H2.CdVinculo AND
                     H1.CdRubricaAgrupamento = H2.CdRubricaAgrupamento AND
                     H1.NuSufixoRubrica = H2.NuSufixoRubrica
               INNER JOIN EPagRubricaAgrupamento RA
                  ON H1.CdRubricaAgrupamento = RA.CdRubricaAgrupamento AND
                     H2.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
               INNER JOIN EPagrubrica R
                  ON RA.CdRubrica = R.CdRubrica
               WHERE RA.FlCompoe13 = PKGPAG_TIPO.cnS AND -- hj
                     (R.CdTipoRubrica IN (1,5) OR
                     (R.CdTipoRubrica = 9 AND RA.CdModalidadeRubrica IN (12,13,15,32,47)))

            UNION ALL

            SELECT R.CdTipoRubrica,
                   R.NuRubrica,
                   H1.Cdvinculo,
                   RA.CdAgrupamento,
                   H1.Cdrubricaagrupamento,
                   SUM(H1.VlPagamento),
                   0,
                   H1.NuSufixoRubrica,
                   PKGPAG_TIPO.cnS AS FlValorOrigemMaior
             FROM EpaghistoricoRubricaVinculo H1
            INNER JOIN EpagRubricaAgrupamento RA
               ON H1.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
            INNER JOIN EPagRubrica R
               ON RA.CdRubrica = R.CdRubrica
            WHERE H1.CdFolhapagamento = pCdFolhaOrigem AND
                  (H1.CdVinculo = pCdVinculo) AND
                   NOT EXISTS (SELECT 1
                                 FROM EpaghistoricoRubricaVinculo H2
                                WHERE H1.Cdrubricaagrupamento = H2.Cdrubricaagrupamento AND
                                      H1.NuSufixoRubrica = H2.NuSufixoRubrica AND
                                      H1.CdVinculo = H2.CdVinculo AND
                                      H2.CdFolhaPagamento = pCdFolhaVincSupl AND
                                      (H2.CdVinculo = pCdVinculo)) AND
                   RA.FlCompoe13 = PKGPAG_TIPO.cnS AND -- hj
                   (R.CdTipoRubrica IN (1,5) OR
                   (R.CdTipoRubrica = 9 AND RA.CdModalidadeRubrica IN (12,13,15,32,47)))
              GROUP BY R.CdTipoRubrica,
                       R.NuRubrica,
                       H1.Cdvinculo,
                       RA.CdAgrupamento,
                       H1.CdRubricaAgrupamento,
                       0,
                       H1.NuSufixoRubrica,
                       PKGPAG_TIPO.cnS
            UNION ALL

            SELECT R.CdTipoRubrica,
                   R.NuRubrica,
                   H1.CdVinculo,
                   RA.CdAgrupamento,
                   H1.CdRubricaAgrupamento,
                   0,
                   SUM(H1.VlPagamento),
                   H1.NuSufixoRubrica,
                   PKGPAG_TIPO.cnN AS FlValorOrigemMaior
             FROM EpaghistoricoRubricaVinculo H1
            INNER JOIN EpagRubricaAgrupamento RA
               ON H1.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
            INNER JOIN EPagRubrica R
               ON RA.Cdrubrica = R.Cdrubrica
             WHERE H1.CdFolhapagamento = pCdFolhaVincSupl AND
                  (H1.CdVinculo = pCdVinculo) AND
              NOT EXISTS (SELECT 1
                            FROM EpagHistoricoRubricaVinculo H2
                           WHERE H1.CdRubricaAgrupamento = H2.CdRubricaAgrupamento AND
                                 H1.NuSufixoRubrica = H2.NuSufixoRubrica AND
                                 H1.CdVinculo = H2.CdVinculo AND
                                 H2.CdFolhaPagamento = pCdFolhaOrigem AND
                                 (H2.CdVinculo = pCdVinculo)) AND
                    RA.FlCompoe13 = PKGPAG_TIPO.cnS AND -- hj
                    (R.CdTipoRubrica IN (1,5) OR
                    (R.CdTipoRubrica = 9 AND RA.CdModalidadeRubrica IN (12,13,15,32,47)))
           GROUP BY R.CdTipoRubrica,
                    R.NuRubrica,
                    H1.CdVinculo,
                    RA.CdAgrupamento,
                    H1.CdRubricaAgrupamento,
                    0,
                    H1.NuSufixoRubrica,
                    PKGPAG_TIPO.cnN) S
     INNER JOIN EPagRubricaSuplementar RS
       ON S.CdTipoRubrica = RS.CdTipoRubricaOrigem
     INNER JOIN EPagRubrica R
       ON R.CdTipoRubrica = RS.CdTipoRubricaGerada
     INNER JOIN EPagRubricaAgrupamento RA
       ON R.CdRubrica = RA.CdRubrica
     WHERE S.NuRubrica = R.NuRubrica AND
           S.FlValorOrigemMaior = RS.FlValorOrigemMaior AND
           S.CdAgrupamento = RA.CdAgrupamento)
   WHERE VlPagamento <> 0 AND (pCdRubricaAgrupamento IS NULL OR CdRubricaAgrupOrigem in (pCdRubricaAgrupamento, pCdRubricaAbonoPerm13, pCdRubricaIRRF13));

  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------

  FUNCTION FPossuiDiferenca(pCdFolhaPagamento     IN INTEGER,
                            pCdFolha13Ant         IN INTEGER,
                            pCdFolha13            IN INTEGER,
                            pCdVinculo            IN INTEGER,
                            pCdRubricaAgrupamento IN INTEGER,
                            pCdRubricaAbonoPerm13 in integer default null,
                            pCdRubricaIRRF13      IN INTEGER DEFAULT NULL)
    RETURN BOOLEAN IS

    bPossuiDiferenca BOOLEAN;

  BEGIN
 
    bPossuiDiferenca := FALSE;

    FOR rSuplementar IN cSuplementar(pCdFolhaPagamento,
                                     pCdFolha13Ant,
                                     pCdFolha13,
                                     pCdVinculo,
                                     pCdRubricaAgrupamento,
                                     pCdRubricaAbonoPerm13,
                                     pCdRubricaIRRF13)
    LOOP

      bPossuiDiferenca := TRUE;

    END LOOP;

    RETURN bPossuiDiferenca;

  END;

  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------

  FUNCTION FPossuiPagamento(pCdVinculo        IN INTEGER,
                            pCdFolhaPagamento IN INTEGER)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vCont
      FROM Epaghistoricorubricavinculo CV
     WHERE CV.CdVinculo = pCdVinculo AND
           CV.CdFolhaPagamento = pCdFolhaPagamento AND
           ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

  END;

BEGIN
 
    PKGPAG_VAR.vgFaseCalculo := PKGPAG_TIPO.cnFaseCalculoIntegral;

    ----------------------------------------------------------------
    -- Caso possua pagamentos na folha de 13 atual
    ----------------------------------------------------------------

    IF FPossuiPagamento(pCdVinculo,
                        pCdFolha13) THEN

      ----------------------------------------------------------------------------
      -- Caso possua pagamentos na folha de 13 anterior no orgao de processamento
      ----------------------------------------------------------------------------

      IF FPossuiPagamento(pCdVinculo,
                          pCdFolha13Ant) THEN

          vCdFolha13Ant := pCdFolha13Ant;

      ----------------------------------------------------------------------------
      -- Senao busca alguma folha de 13 salario no mes anterior em qualquer orgao
      ----------------------------------------------------------------------------
      ELSE

        BEGIN

          SELECT FP.CdFolhaPagamento
            INTO vCdFolha13Ant
            FROM EPagHistoricoRubricaVinculo HRV
           INNER JOIN EPagFolhaPagamento FP
              ON FP.cdFolhaPagamento = HRV.cdFolhaPagamento
           INNER JOIN (SELECT FPA.NuAnoReferencia,
                              FPA.NuMesReferencia,
                              FPA.CdTipoFolhaPagamento,
                              FPA.CdTipoCalculo
                         FROM EPagFolhaPagamento FPA
                        WHERE FPA.CdFolhaPagamento = pCdFolha13Ant) FPA
              ON FP.NuAnoReferencia = FPA.NuAnoReferencia AND
                 FP.NuMesReferencia = FPA.NuMesReferencia AND
                 FP.CdTipoFolhaPagamento = FPA.CdTipoFolhaPagamento AND
                 FP.CdTipoCalculo = FPA.CdTipoCalculo
           WHERE HRV.CdVinculo = pCdVinculo AND
                 FP.FlCalculoDefinitivo = 'S' AND
                 ROWNUM < 2;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            vCdFolha13Ant := 0;

        END;

      END IF;
      --
      -- Busca valor da Base 09-0983 usada como limite de 10% para as rubricas 08-0023 e 08-0024
      --
      BEGIN

      SELECT HRV.VLPAGAMENTO
        INTO vVlBase983
        FROM Epaghistoricorubricavinculo HRV
       WHERE HRV.Cdfolhapagamento = pCdFolhaPagamento
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

      bPossuiDuploVinculo := false;

      vVlInss13Total := 0;

      if FDuploVinculoVigente(pCdPessoa => pkgpag_var.vgvinculo.cdpessoa,
                              pDtInicioMes => pkgpag_var.vgFolha.DtInicioMes) > 1 or
            FVinculosVigentes(pkgpag_var.vgvinculo.cdpessoa) > 1
            and pkgpag_var.vgFolha.NuMesReferencia = 12 then

            vVlInss13Total := fDiferencaINSS13(pkgpag_var.vgvinculo.cdpessoa);

            bPossuiDuploVinculo := true;

      end if;
      ----------------------------------------------------------------
      -- Se existir diferenca na rubrica de 13 salario (01-0023)
      ----------------------------------------------------------------


      vgCdRubricaAbonoPerm13 := pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,1,1914);

      IF pkgpag_var.vgFolha.CdAgrupamento=134 THEN
         vCdRubricaIRRF13 := pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,5,546);
      END IF;

      IF FPossuiDiferenca(pCdFolhaPagamento,
                          vCdFolha13Ant,
                          pCdFolha13,
                          pCdVinculo,
                          PKGPAG_VAR.vgCdRubAgrup13,
                          vgCdRubricaAbonoPerm13,
                          vCdRubricaIRRF13) THEN

        ----------------------------------------------------------------------------
        -- Processa diferencas entre a folha de 13 do mes anterior e folha 13 atual
        ----------------------------------------------------------------------------

        FOR rSuplementar IN cSuplementar(pCdFolhaPagamento,
                                         vCdFolha13Ant,
                                         pCdFolha13,
                                         pCdVinculo,
                                         NULL)
        LOOP

          if rSuplementar.Nurubrica = 513 and vVlInss13Total < 0 then

               rSuplementar.Vlpagamento := 0;

          end if;

          IF (rSuplementar.FlTributacao = 'S') AND rSuplementar.CdTipoRubrica = 6 THEN

            rSuplementar.CdRubricaAgrupamento:= PKGPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,
                                                                             5,

                                                                   rSuplementar.NuRubrica);



          END IF;

          IF PKGPAG_GERAL.FGeraRubrica(rSuplementar.CdRubricaAgrupamento) THEN

            --IF NOT (rSuplementar.CdTipoRubrica = 4 AND rSuplementar.NuRubrica IN (/*546,*/ 513, 586))   THEN
            IF (rSuplementar.CdTipoRubrica IN (4) AND rSuplementar.NuRubrica IN (944))   THEN
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
                     VlRubricaNormal,
                     VlRubricaSupl,
                     CdTipoRubricaOrigem,
                     CdTipoOrigemRubrica)
              VALUES
                    (Spaghistoricorubricavinculo.NEXTVAL,
                     pCdFolhaPagamento,
                     rSuplementar.CdRubricaAgrupamento,
                     pCdVinculo,
                     rSuplementar.NuSufixoRubrica,
                     NULL,
                     CASE
                       WHEN rSuplementar.CdTipoRubrica = 8 and rSuplementar.NuRubrica = 23
                            and rSuplementar.VlPagamento > (vVlBase983 * 0.10)
                         THEN
                           (vVlBase983 * 0.10)
                         ELSE
                           rSuplementar.vlPagamento
                     END ,
                     1,
                     CASE
                       WHEN rSuplementar.CdTipoRubrica = 8 and rSuplementar.NuRubrica = 23
                         THEN
                           10
                         ELSE
                           0
                     END,
                     systimestamp,
                     rSuplementar.vlPagamentoOrigem,
                     rSuplementar.vlPagamentoSupl,
                     rSuplementar.CdTipoRubricaOrigem,
                     16);

                -- Inserir SALDO do desconto parcial da rubrica 08-0023 na rubrica 09-9023

                IF rSuplementar.Cdtiporubrica = 8 and rSuplementar.Nurubrica = 23
                   AND rSuplementar.Vlpagamento > (vVlBase983 * 0.10)
                  THEN
                    PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pCdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBase080023DescParcial,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => rSuplementar.vlPagamento - vVlBase983 * 0.10,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

                END IF;

            END IF;

          END IF;

          PKGPAG_VAR.bReprocessou13Sal := TRUE;

        END LOOP;

      END IF;

      --------------------------------------------------------------------------------
      -- Gera a rubrica 08-0024 com o mesmo valor  da rubrica 9-9524 gerada na folha
      -- de 13 do mes anterior
      -- (Devolucao de antecipacao de 13 nao efetuada)
      --------------------------------------------------------------------------------

      IF PKGPAG_VAR.vgFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolhaCtisp13,
                                         pkgpag_tipo.cnTpFolhaAdiant13Ctisp,
                                         pkgpag_tipo.cnTpFolhaCtisp) THEN

        vCdRubDevAnt13NaoEfetuado := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento,
                                                                  8,
                                                                  324);

      ELSE

        vCdRubDevAnt13NaoEfetuado := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento,
                                                                  8,
                                                                  24);

     END IF;

     IF PKGPAG_GERAL.FGeraRubrica(vCdRubDevAnt13NaoEfetuado) THEN

        vVlDevAnt13NaoEfetuado:= PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pCdFolha13Ant,
                                                                   pCdVinculo        => pCdVinculo,
                                                                   pCdRubrica        => PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado);

        IF vVlDevAnt13NaoEfetuado > 0.1 THEN

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
                  vlRubricaNormal,
                  vlRubricaSupl,
                  CdTipoRubricaOrigem,
                  CdTipoOrigemRubrica)
           VALUES
                 (Spaghistoricorubricavinculo.NEXTVAL,
                  pCdFolhaPagamento,
                  vCdRubDevAnt13NaoEfetuado,
                  pCdVinculo,
                  1,
                  NULL,
                  CASE WHEN vVlDevAnt13NaoEfetuado > (vVlBase983 * 0.10)
                       THEN (vVlBase983 * 0.10)
                       ELSE vVlDevAnt13NaoEfetuado
                  END,
                  -- Aplicar teto de 10%
                  -- Antes gerava o valor
                  -- vVlDevAnt13NaoEfetuado,
                  1,
                  0,
                  systimestamp,
                  0,
                  0,
                  1,
                  16);

            -- Inserir o saldo na base do desconto parcial (09-9024)

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => PCdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBase080024DescParcial,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => (vVlDevAnt13NaoEfetuado -
                                                                         CASE WHEN (vVlBase983 * 0.10) < vVlDevAnt13NaoEfetuado
                                                                              THEN (vVlBase983 * 0.10)
                                                                              ELSE vVlDevAnt13NaoEfetuado
                                                                         END ),
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);

         END IF;

       END IF;

       ------------------------------------------------------------

      --------------------------------------------------------------------------------
      -- Gera a rubrica 06-0534 se nao houve folha de 13o. no mes anterior
      -- vVlAnt13SemFolhaAnt       NUMBER(13,2);
      -- vCdRubDevAnt13    INTEGER;
      -- vCdRubDifAnt13    INTEGER;
      --------------------------------------------------------------------------------

      -- Se nao houve folha pagamento na folha de 13 anterior...
      IF vCdFolha13Ant = 0 THEN

         -- Rubrica de devolucao de 13o.
         vCdRubDevAntecip13 := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento,
                                                        5,
                                                        524);

         -- Rubrica de diferenca de devolucao de 13o.
         vCdRubDifAntecip13 := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento,
                                                        6,
                                                        524);

          IF PKGPAG_GERAL.FGeraRubrica(vCdRubDifAntecip13) THEN

             /* Tenta encontrar valor da antecipacao na folha de 13 anterior (novembro) */
              vVlAnt13SemFolhaAnt := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pCdFolha13Ant,
                                                                       pCdVinculo        => pCdVinculo,
                                                                       pCdRubrica        => vCdRubDevAntecip13);
              /* Se nao encontrou o valor... */
              IF vVlAnt13SemFolhaAnt = 0 THEN

                    /*  Tenta encontrar valor na folha de 13 atual (dezembro) */
                    vVlAnt13SemFolhaAnt := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pCdFolha13,
                                                                               pCdVinculo        => pCdVinculo,
                                                                               pCdRubrica        => vCdRubDevAntecip13);

                    -- Se encontrou valor na folha atual de 13o., insere valor na rubrica de diferenca de antecipacao de 13o.
                    IF vVlAnt13SemFolhaAnt > 0 THEN

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
                              vlRubricaNormal,
                              vlRubricaSupl,
                              CdTipoRubricaOrigem,
                              CdTipoOrigemRubrica)
                       VALUES
                             (Spaghistoricorubricavinculo.NEXTVAL,
                              pCdFolhaPagamento,
                              vCdRubDifAntecip13,
                              pCdVinculo,
                              1,
                              NULL,
                              vVlAnt13SemFolhaAnt,
                              1,
                              0,
                              systimestamp,
                              0,
                              0,
                              1,
                              16);

                     END IF;

               END IF;

           END IF;

       END IF;
       ------------------------------------------------------------

       -- Reprocessar bases de FGTS 13 e INSS 13

    END IF;

END;

  PROCEDURE PCopiaContraCheques(pCdFolhaOrigem  IN INTEGER,
                                pCdFolhaDestino IN INTEGER,
                                pCdVinculo      IN INTEGER) IS
  BEGIN
 
    INSERT INTO EPagHistoricoRubricaVinculo
      (cdhistoricorubricavinculo,
       cdfolhapagamento,
       cdrubricaagrupamento,
       cdvinculo,
       nusufixorubrica,
       cdlancamentofinanceiro,
       vlpagamento,
       qtparcelas,
       vlindicerubrica,
       dtultalteracao,
       cdvantagempecuniaria,
       cdrubricatotalizadoravantagem,
       nuordemcalculo,
       cdexpressaoformcalc,
       flvigenciapagamento,
       cdincorporacaoativo,
       vlminrecebincorp,
       flatualizacaoconstante,
       cdtiporubricaorigem,
       vlrubricanormal,
       vlrubricasupl,
       cdbaseconsignacao,
       vlpagamentotrunc,
       cdtipoorigemrubrica,
       deexpressao,
       dtdesligamento,
       vlpagamentooriginal,
       deprocessoretroativo,
       vlmontanteretroativo,
       vlindicenmrra)
      SELECT SPagHistoricoRubricaVinculo.NextVal,
             pCdFolhaDestino,
             cdrubricaagrupamento,
             cdvinculo,
             nusufixorubrica,
             cdlancamentofinanceiro,
             vlpagamento,
             qtparcelas,
             vlindicerubrica,
             dtultalteracao,
             cdvantagempecuniaria,
             cdrubricatotalizadoravantagem,
             nuordemcalculo,
             cdexpressaoformcalc,
             flvigenciapagamento,
             cdincorporacaoativo,
             vlminrecebincorp,
             flatualizacaoconstante,
             cdtiporubricaorigem,
             vlrubricanormal,
             vlrubricasupl,
             cdbaseconsignacao,
             vlpagamentotrunc,
             cdtipoorigemrubrica,
             deexpressao,
             dtdesligamento,
             vlpagamentooriginal,
             deprocessoretroativo,
             vlmontanteretroativo,
             vlindicenmrra
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE CdFolhaPagamento = pCdFolhaOrigem
         AND CdVinculo = pCdVinculo;

    INSERT INTO EPagCapaHistRubricaVinculo
      (cdfolhapagamento,
       cdvinculo,
       vlproventos,
       vldescontos,
       cdmotivoafasttemporario,
       cdmotivoafastdefinitivo,
       insistemaorigem,
       flativo,
       flpagamentobloqueado,
       flrecadastrado,
       cdcreditobancario,
       cdrelacaotrabalho,
       cdregimetrabalho,
       nucho,
       cdgrupoocupacional,
       cdlocalidade,
       cdvalorgeralcefagrup,
       cdcargocomissionado,
       nunivelcef,
       nureferenciacef,
       nureferenciacco,
       nunivelcco,
       cdestruturacarreira,
       cdgrauescolaridade,
       cdnaturezavinculo,
       cdsituacaoprevidenciaria,
       nuchorelacao,
       cdunidadeorganizacional,
       cdagenciacredito,
       Nucontacredito,
       Nudvcontacredito,
       Cdagenciareceb,
       Nucontareceb,
       Fltipocontacredito,
       Nuagencia,
       Nudvagencia,
       Nubanco,
       cdCentroCusto,
       inAposentadoriaEspecial)
      SELECT pCdFolhaDestino,
             cdvinculo,
             vlproventos,
             vldescontos,
             cdmotivoafasttemporario,
             cdmotivoafastdefinitivo,
             insistemaorigem,
             flativo,
             flpagamentobloqueado,
             flrecadastrado,
             cdcreditobancario,
             cdrelacaotrabalho,
             cdregimetrabalho,
             nucho,
             cdgrupoocupacional,
             cdlocalidade,
             cdvalorgeralcefagrup,
             cdcargocomissionado,
             nunivelcef,
             nureferenciacef,
             nureferenciacco,
             nunivelcco,
             cdestruturacarreira,
             cdgrauescolaridade,
             cdnaturezavinculo,
             cdsituacaoprevidenciaria,
             nuchorelacao,
             cdunidadeorganizacional,
             PKGPAG_VAR.vgCdAgenciaCredito,
             PKGPAG_VAR.vgNuContaCredito,
             PKGPAG_VAR.vgNuDvContaCredito,
             PKGPAG_VAR.vgCdAgenciaReceb,
             PKGPAG_VAR.vgNuContaReceb,
             PKGPAG_VAR.vgFlTipoContaCredito,
             PKGPAG_VAR.vgNuAgencia,
             PKGPAG_VAR.vgNuDvAgencia,
             PKGPAG_VAR.vgNuBanco,
             hrv.cdcentrocusto,
             hrv.inaposentadoriaespecial
        FROM EPagCapaHistRubricaVinculo HRV
       WHERE CdFolhaPagamento = pCdFolhaOrigem
         AND CdVinculo = pCdVinculo;

  END;

  PROCEDURE PProcessaFolhaSuplementar(pFolhaSuplementar    IN PKGPAG_TIPO.rFolha,
                                      pCdFolhaOrigem       IN integer,
                                      pCdFolhaRecalculo    IN integer,
                                      pCdVinculo           IN INTEGER,
                                      pFlCalculoDefinitivo IN CHAR,
                                      pVlDiferencaValor    IN NUMBER DEFAULT 0,
                                      pCdFolhaPagou        IN INTEGER DEFAULT 0) IS

    vTemRecalc BOOLEAN;

    vPossuiOutraSuplMes boolean;

    vValorRecebido number(13,2);

    vCdProcessoRestituicaoErario integer;

    vNuParcela integer;

    vCdFolha13OrigOutroOrgao INTEGER;

    CURSOR cSuplVinculo(pCdFolhaOrigem   INTEGER,
                        pCdFolhaVincSupl INTEGER,
                        pCdVinculo       INTEGER) IS
      SELECT RA.CdRubricaAgrupamento,
             RA.CdAgrupamento,
             S.CdVinculo,
             CASE
               WHEN S.CdTipoRubrica <> PKGPAG_TIPO.cnTpRubTotalizadora THEN
                ABS(vlPagamentoSupl - vlPagamentoOrigem)
               ELSE
                (vlPagamentoSupl - vlPagamentoOrigem)
             END AS VlPagamento,
             CASE
               WHEN RS.CdTipoRubricaOrigem = 2 THEN
                2
               ELSE
                S.NuSufixoRubrica
             END AS NuSufixoRubrica,
             S.VlPagamentoOrigem,
             S.VlPagamentoSupl,
             RS.CdTipoRubricaOrigem,
             RS.CdTipoRubricaGerada as CdTipoRubrica,
             RA.FlConsignacao,
             RA.FlGeraSuplementar,
             RA.FlTributacao,
             R.NuRubrica,
             CASE
               WHEN RA.FlConsignacao = 'S' THEN
                CASE
                  WHEN NVL(vlPagamentoOrigem, 0) = 0 THEN
                   'S'
                  ELSE
                   'N'
                END
             END AS FlOrigemZerada,
             S.CdBaseConsignacao,
             S.CdLancamentoFinanceiro,
             S.CdTipoOrigemRubrica,
             s.deprocessoretroativo,
             s.vlindicerubrica,
             s.vlindicenmrra,
             s.cdprocessopagretroativo,
             s.vlmontanteretroativo,
             s.cdprocessorestituicaoerario,
             ra.flpensaoalimenticia,
             s.cdhistsentencajudicial
        FROM (SELECT R.CdTipoRubrica,
                     R.NuRubrica,
                     H1.CdVinculo,
                     RA.CdAgrupamento,
                     H1.CdRubricaAgrupamento,
                     H1.VlPagamentoOrigem,
                     H2.VlPagamentoSupl,
                     H1.NuSufixoRubrica,
                     H1.CdBaseConsignacao,
                     CASE
                       WHEN vlPagamentoOrigem > vlPagamentoSupl THEN
                        PKGPAG_TIPO.cnS
                       ELSE
                        PKGPAG_TIPO.cnN
                     END FlValorOrigemMaior,
                     H1.CdLancamentoFinanceiro,
                     H1.Cdtipoorigemrubrica,
                     h1.deprocessoretroativo,
                     h1.vlindicerubrica,
                     h1.vlindicenmrra,
                     h1.cdprocessopagretroativo,
                     h1.vlmontanteretroativo,
                     h1.cdprocessorestituicaoerario,
                     h1.cdhistsentencajudicial
                FROM (SELECT H1.CdVinculo,
                             H1.CdRubricaAgrupamento,
                             H1.NuSufixoRubrica,
                             H1.CdBaseConsignacao,
                             H1.CdLancamentoFinanceiro,
                             SUM(H1.VlPagamento) AS vlPagamentoOrigem,
                             H1.CdTipoOrigemRubrica,
                             h1.deprocessoretroativo,
                             SUM(h1.vlindicerubrica) AS vlindicerubrica,
                             h1.vlindicenmrra,
                             h1.cdprocessopagretroativo,
                             h1.vlmontanteretroativo,
                             h1.cdprocessorestituicaoerario,
                             h1.cdhistsentencajudicial
                        FROM EpagHistoricoRubricaVinculo H1
                       WHERE H1.CdFolhapagamento = pCdFolhaOrigem
                         AND H1.CdVinculo = pCdVinculo
                       GROUP BY H1.CdVinculo,
                                H1.CdRubricaAgrupamento,
                                H1.NuSufixoRubrica,
                                H1.CdBaseConsignacao,
                                H1.CdLancamentoFinanceiro,
                                H1.Cdtipoorigemrubrica,
                                h1.deprocessoretroativo,
                                h1.vlindicenmrra,
                                h1.cdprocessopagretroativo,
                                h1.vlmontanteretroativo,
                                h1.cdprocessorestituicaoerario,
                                h1.cdhistsentencajudicial) H1
               INNER JOIN (SELECT H2.CdVinculo,
                                 H2.CdRubricaAgrupamento,
                                 H2.NuSufixoRubrica,
                                 H2.CdBaseConsignacao,
                                 H2.CdLancamentoFinanceiro,
                                 SUM(H2.VlPagamento) AS vlPagamentoSupl,
                                 H2.Cdtipoorigemrubrica,
                                 h2.deprocessoretroativo,
                                 SUM(h2.vlindicerubrica) AS vlindicerubrica,
                                 h2.vlindicenmrra,
                                 h2.cdprocessopagretroativo,
                                 h2.vlmontanteretroativo,
                                 h2.cdprocessorestituicaoerario,
                                 h2.cdhistsentencajudicial
                            FROM EPagHistoricoRubricaVinculo H2
                           WHERE H2.CdFolhapagamento = pCdFolhaVincSupl
                             AND H2.CdVinculo = pCdVinculo
                           GROUP BY H2.CdVinculo,
                                    H2.CdRubricaAgrupamento,
                                    H2.NuSufixoRubrica,
                                    H2.CdBaseConsignacao,
                                    H2.CdLancamentoFinanceiro,
                                    H2.Cdtipoorigemrubrica,
                                    h2.deprocessoretroativo,
                                    h2.vlindicenmrra,
                                    h2.cdprocessopagretroativo,
                                    h2.vlmontanteretroativo,
                                    h2.cdprocessorestituicaoerario,
                                    h2.cdhistsentencajudicial) H2
                  ON H1.CdVinculo = H2.CdVinculo
                 AND H1.CdRubricaAgrupamento = H2.CdRubricaAgrupamento
                 AND H1.NuSufixoRubrica = H2.NuSufixoRubrica
               INNER JOIN EPagRubricaAgrupamento RA
                  ON H1.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
                 AND H2.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
               INNER JOIN EPagrubrica R
                  ON RA.CdRubrica = R.CdRubrica
               WHERE ABS(vlPagamentoOrigem - vlPagamentoSupl) > NVL(pVlDiferencaValor, 0)
                 AND
                     RA.FlConsignacao = PKGPAG_TIPO.cnN
                 AND (R.CdTipoRubrica IN
                     (1, /*2,*/ 3, 4, 5, 6, 7,8, 9, 10, 11, 12, 13) or (r.nurubrica=23 and r.cdtiporubrica=2))

              UNION ALL

              SELECT R.CdTipoRubrica,
                     R.NuRubrica,
                     H1.CdVinculo,
                     RA.CdAgrupamento,
                     H1.CdRubricaAgrupamento,
                     SUM(H1.VlPagamento),
                     0,
                     H1.NuSufixoRubrica,
                     H1.CdBaseConsignacao,
                     PKGPAG_TIPO.cnS AS FlValorOrigemMaior,
                     H1.CdLancamentoFinanceiro,
                     H1.Cdtipoorigemrubrica,
                     h1.deprocessoretroativo,
                     h1.vlindicerubrica,
                     h1.vlindicenmrra,
                     h1.cdprocessopagretroativo,
                     h1.vlmontanteretroativo,
                     h1.cdprocessorestituicaoerario,
                     h1.cdhistsentencajudicial
                FROM EPagHistoricoRubricaVinculo H1
               INNER JOIN EPagRubricaAgrupamento RA
                  ON H1.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
               INNER JOIN EPagRubrica R
                  ON RA.CdRubrica = R.CdRubrica
               WHERE H1.CdFolhapagamento = pCdFolhaOrigem
                 AND (H1.CdVinculo = pCdVinculo)
                 AND  RA.FlConsignacao = PKGPAG_TIPO.cnN
                 AND R.CdTipoRubrica IN
                     (1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
             AND NOT EXISTS
               (SELECT 1
                        FROM EPagHistoricoRubricaVinculo H2
                       WHERE H1.CdRubricaAgrupamento =
                             H2.CdRubricaAgrupamento
                         AND H1.NuSufixoRubrica = H2.NuSufixoRubrica
                         AND H1.CdVinculo = H2.CdVinculo
                         AND H2.CdFolhaPagamento = pCdFolhaVincSupl
                         AND (H2.CdVinculo = pCdVinculo))
               GROUP BY R.CdTipoRubrica,
                        R.NuRubrica,
                        H1.CdVinculo,
                        RA.CdAgrupamento,
                        H1.CdRubricaAgrupamento,
                        0,
                        H1.NuSufixoRubrica,
                        H1.CdBaseConsignacao,
                        PKGPAG_TIPO.cnS,
                        H1.CdLancamentoFinanceiro,
                        H1.Cdtipoorigemrubrica,
                        h1.deprocessoretroativo,
                        h1.vlindicerubrica,
                        h1.vlindicenmrra,
                        h1.cdprocessopagretroativo,
                        h1.vlmontanteretroativo,
                        h1.cdprocessorestituicaoerario,
                        h1.cdhistsentencajudicial
              HAVING SUM(H1.VlPagamento) <> NVL(pVlDiferencaValor, 0)

              UNION ALL

              SELECT R.CdTipoRubrica,
                     R.NuRubrica,
                     H1.CdVinculo,
                     RA.CdAgrupamento,
                     H1.CdRubricaAgrupamento,
                     0,
                     SUM(H1.VlPagamento),
                     H1.NuSufixoRubrica,
                     H1.CdBaseConsignacao,
                     PKGPAG_TIPO.cnN AS FlValorOrigemMaior,
                     H1.CdLancamentoFinanceiro,
                     H1.Cdtipoorigemrubrica,
                     h1.deprocessoretroativo,
                     h1.vlindicerubrica,
                     h1.vlindicenmrra,
                     h1.cdprocessopagretroativo,
                     h1.vlmontanteretroativo,
                     h1.cdprocessorestituicaoerario,
                     h1.cdhistsentencajudicial
                FROM EPagHistoricoRubricaVinculo H1
               INNER JOIN EPagRubricaAgrupamento RA
                  ON H1.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
               INNER JOIN EPagRubrica R
                  ON RA.CdRubrica = R.CdRubrica
               WHERE H1.CdFolhapagamento = pCdFolhaVincSupl
                 AND (H1.CdVinculo = pCdVinculo)
                 AND NOT EXISTS
               (SELECT 1
                        FROM EPagHistoricoRubricaVinculo H2
                       WHERE H1.CdRubricaAgrupamento =
                             H2.CdRubricaAgrupamento
                         AND H1.NuSufixoRubrica = H2.NuSufixoRubrica
                         AND H1.CdVinculo = H2.CdVinculo
                         AND H2.CdFolhaPagamento = pCdFolhaOrigem
                         AND (H2.CdVinculo = pCdVinculo))
                 AND
                     RA.FlConsignacao = PKGPAG_TIPO.cnN
                 AND R.CdTipoRubrica IN
                     (1,3,4,5,6,7,8,9,10,11,12,13)
               GROUP BY R.CdTipoRubrica,
                        R.NuRubrica,
                        H1.CdVinculo,
                        RA.CdAgrupamento,
                        H1.CdRubricaAgrupamento,
                        0,
                        H1.NuSufixoRubrica,
                        H1.CdBaseConsignacao,
                        PKGPAG_TIPO.cnN,
                        H1.CdLancamentoFinanceiro,
                        H1.Cdtipoorigemrubrica,
                        h1.deprocessoretroativo,
                        h1.vlindicerubrica,
                        h1.vlindicenmrra,
                        h1.cdprocessopagretroativo,
                        h1.vlmontanteretroativo,
                        h1.cdprocessorestituicaoerario,
                        h1.cdhistsentencajudicial
              HAVING SUM(H1.VlPagamento) <> NVL(pVlDiferencaValor, 0))  S
       INNER JOIN EPagRubricaSuplementar RS
          ON S.CdTipoRubrica = RS.CdTipoRubricaOrigem
       INNER JOIN EPagRubrica R
          ON R.CdTipoRubrica = RS.CdTipoRubricaGerada
       INNER JOIN EPagRubricaAgrupamento RA
          ON R.CdRubrica = RA.CdRubrica
       WHERE S.NuRubrica = R.NuRubrica
         AND S.FlValorOrigemMaior = RS.FlValorOrigemMaior
         AND S.CdAgrupamento = RA.CdAgrupamento
         --and s.cdtiporubrica <> 9
       --  and s.vlpagamentosupl <> 0
         and s.vlpagamentoorigem <> s.vlpagamentosupl;

    subtype rSuplVinculo IS cSuplVinculo%rowtype;

    type tSuplVinculo IS TABLE OF rSuplVinculo;

    rSuplementar rSuplVinculo;

    vTabSuplVinculo tSuplVinculo;

    TYPE tDtCalculo IS TABLE OF DATE INDEX BY PLS_INTEGER;

    vTabDtCalculo tDtCalculo;

    vNuSufixoDifMes INTEGER;

    FUNCTION FPossuiPagamento(pCdFolhaPagamento IN INTEGER,
                              pCdVinculo        IN INTEGER) RETURN BOOLEAN IS

      vCont INTEGER;

    BEGIN
 
      SELECT 1
        INTO vCont
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND ROWNUM < 2;

      RETURN TRUE;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN FALSE;

    END;

    FUNCTION FRestituicaoErario(pCdLancamentoFinanceiro in integer) RETURN integer IS

      vCont INTEGER;

    BEGIN
 
      begin
      -- Identifica se ja existe parcela na suplementar e exclui
      select max(pg.cdpagamentolancamento)
        into vCont
        from epagpagamentolancamento pg
       where pg.cdlancamentofinanceiro = pCdLancamentoFinanceiro
         and pg.nuanoreferencia = pkgpag_var.vgFolha.NuAnoReferencia
         and pg.numesreferencia = pkgpag_var.vgFolha.NuMesReferencia
         group by cdlancamentofinanceiro
         having count(cdlancamentofinanceiro) > 1;

      if vCont > 0 then
         begin

         delete epagpagamentolancamento pg
          where pg.cdpagamentolancamento = vCont;

         exception
           when others
             then null;
         end;

      end if;

      exception
        when no_data_found
          then vCont := 0;
        when others
          then vCont := 0;

      end;

      vCont := 0;

      SELECT lf.cdprocessorestituicaoerario
        INTO vCont
        FROM EPagLancamentoFinanceiro LF
       WHERE lf.cdlancamentofinanceiro = pCdLancamentoFinanceiro
         and lf.cdprocessorestituicaoerario is not null;

      RETURN vCont;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN 0;

      when others then

        return 0;

    END;

    FUNCTION FPossuiPagOutraSuplMes(pCdVinculo IN INTEGER) RETURN BOOLEAN IS

      vCont INTEGER;

    BEGIN
 
      with fol as (select cdfolhapagamento
                     from epagfolhapagamento pf
                    where pf.nuanoreferencia = pkgpag_var.vgFolha.NuAnoReferencia
                      and pf.numesreferencia = pkgpag_var.vgFolha.NuMesReferencia
                      and pf.flcalculodefinitivo = 'S'
                      and pf.cdorgao = pkgpag_var.vgFolha.CdOrgao
                      and pf.cdtipocalculo = pkgpag_tipo.cnTpCalculoSupl
                      and pf.cdfolhapagamento <> pkgpag_var.vgFolha.CdFolhaPagamento)
      SELECT 1
        INTO vCont
        FROM epagcapahistrubricavinculo capa
       inner join fol f on f.cdfolhapagamento = capa.cdfolhapagamento
       WHERE capa.CdVinculo = pCdVinculo
         AND ROWNUM < 2;

      RETURN TRUE;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN FALSE;

    END;

    FUNCTION FPossuiPagRubOutraSuplMes(rSuplementar IN cSuplVinculo%rowtype) RETURN NUMBER IS

      vSoma number(13,2);

    BEGIN
 
      with fol as (select cdfolhapagamento
                     from epagfolhapagamento pf
                    where pf.nuanoreferencia = pkgpag_var.vgFolha.NuAnoReferencia
                      and pf.numesreferencia = pkgpag_var.vgFolha.NuMesReferencia
                      and pf.flcalculodefinitivo = 'S'
                      and pf.cdorgao = pkgpag_var.vgFolha.CdOrgao
                      and pf.cdtipocalculo = pkgpag_tipo.cnTpCalculoSupl
                      and pf.cdfolhapagamento <> pkgpag_var.vgFolha.CdFolhaPagamento)

      SELECT sum(vlpagamento)
        INTO vSoma
        FROM epaghistoricorubricavinculo hv
       inner join fol f on f.cdfolhapagamento = hv.cdfolhapagamento
       WHERE hv.CdVinculo = rSuplementar.Cdvinculo
         and hv.cdrubricaagrupamento = rSuplementar.Cdrubricaagrupamento
         and hv.nusufixorubrica = rSuplementar.Nusufixorubrica;

      RETURN vSoma;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN 0;

    END;

    FUNCTION FRetornaSufixo(pCdVinculo            IN INTEGER,
                            pCdFolhaPagamento     IN INTEGER,
                            pCdRubricaAgrupamento IN INTEGER,
                            pNuSufixoRubrica      IN INTEGER)

     RETURN INTEGER IS

      vCont INTEGER;

    BEGIN
 
      SELECT 1
        INTO vCont
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento
         AND HRV.NuSufixoRubrica = pNuSufixoRubrica
         AND ROWNUM < 2;

      RETURN pNuSufixoRubrica + 1;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN pNuSufixoRubrica;

    END;

    PROCEDURE PCarregaTabDtCalculo IS

    BEGIN
 
      vTabDtCalculo.DELETE;

      FOR rec IN (SELECT NuMesReferencia, DtCalculo
                    FROM EPagfolhaPagamento
                   WHERE cdtipofolhapagamento =
                         PKGPAG_VAR.vgFolhaRecalculo.CdTipoFolhaPagamento
                     AND cdtipocalculo = PKGPAG_TIPO.cnTpCalculoNormal
                     AND cdorgao = PKGPAG_VAR.vgFolhaRecalculo.CdOrgao
                     AND NuAnoReferencia =
                         PKGPAG_VAR.vgFolhaRecalculo.NuAnoReferencia) LOOP

        vTabDtCalculo(rec.NuMesReferencia) := rec.DtCalculo;

      END LOOP;

    END;

    FUNCTION FMesPagamento(pCdOrgao   IN INTEGER,
                           pCdVinculo IN INTEGER,
                           pDtCalculo IN DATE,
                           pDtIniMes  IN DATE,
                           pDtFimMes  IN DATE)

     RETURN INTEGER IS

      vMesPagAux INTEGER;

      vMenorDataInclusao DATE;

    BEGIN
 
      vMenorDataInclusao := NULL;

      FOR iRelVinc IN PKGPAG_VAR.vgRelVinc.FIRST .. PKGPAG_VAR.vgRelVinc.LAST LOOP

        IF PKGPAG_VAR.vgRelVinc(iRelVinc)
         .DtInclusao > (pDtCalculo + 1 - 1 / 86400) THEN

          IF vMenorDataInclusao IS NULL OR
             vMenorDataInclusao > PKGPAG_VAR.vgRelVinc(iRelVinc).DtInclusao THEN

            vMenorDataInclusao := PKGPAG_VAR.vgRelVinc(iRelVinc).DtInclusao;

          END IF;

        END IF;

      END LOOP;

      IF vMenorDataInclusao IS NULL THEN

        RETURN 99;

      END IF;

      vMesPagAux := vTabDtCalculo.LAST;

      WHILE vMesPagAux IS NOT NULL LOOP

        IF vTabDtCalculo(vMesPagAux) < vMenorDataInclusao THEN
          EXIT;
        END IF;

        vMesPagAux := vTabDtCalculo.PRIOR(vMesPagAux);

      END LOOP;

      IF vMesPagAux IS NULL THEN

        vMesPagAux := 98;

      ELSE

        vMesPagAux := vMesPagAux + 1;

      END IF;

      RETURN vMesPagAux;

    END;

    FUNCTION fTemFolha13NovOutroOrgao(pCdOrgao   IN INTEGER,
                                      pCdVinculo IN INTEGER)
      RETURN INTEGER IS

      vCdFolhaPagamento INTEGER;

    BEGIN
 
        SELECT capa.cdfolhapagamento
          INTO vCdFolhaPagamento
          FROM epagcapahistrubricavinculo capa
          INNER JOIN epagfolhapagamento fp
                ON fp.cdfolhapagamento = capa.cdfolhapagamento
          INNER JOIN epagtipofolhapagamento tfp
                ON tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
         WHERE capa.cdvinculo = pCdVinculo
           AND fp.cdorgao <> pCdOrgao
           AND tfp.cdtipofolha = pkgpag_tipo.cnTpFolha13
           AND fp.cdtipocalculo = 1
           AND fp.flcalculodefinitivo = pkgpag_tipo.cnS
           AND fp.nuanoreferencia = pkgpag_var.vgfolha.NuAnoReferencia
           AND fp.numesreferencia = pkgpag_var.vgfolha.NuMesReferencia - 1
           AND rownum < 2;
        EXCEPTION
          WHEN no_data_found THEN
            RETURN NULL;
          WHEN OTHERS THEN
            RETURN NULL;

      RETURN vCdFolhaPagamento;

    END;

  BEGIN
 
    PKGPAG_RT.PExcluiHistoricoRetroSupl(pCdVinculo => pCdVinculo,
                                        pFolha     => pFolhaSuplementar);

    IF PKGPAG_VAR.vgFolhaRecalculo.CdTipoCalculo =
       PKGPAG_TIPO.cnTpCalculoRecalcCompl THEN

      PCopiaContraCheques(pCdFolhaOrigem  => PKGPAG_VAR.vgFolhaRecalculo.CdFolhaPagamento,
                          pCdFolhaDestino => pFolhaSuplementar.CdFolhaPagamento,
                          pCdVinculo      => pCdVinculo);

      IF pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

        PKGPAG_RT.PAtualizaParcelaRetroativo(pFolha     => pFolhaSuplementar,
                                             pCdVinculo => pCdVinculo);

      END IF;

      -- Fim do Tipo de Calculo Recalculo Complementar

      RETURN;
    END IF;

    -- Demais tipos de Calculo

    /*-------------------------------------------------------------------------------------*/
    -- Verifica se na folha de recalculo indica se a folha deve ser gerada apenas
    --  para servidores com  registro no lancamento financeiro complementar para a folha
    /*-------------------------------------------------------------------------------------*/

    vTemRecalc := FALSE;

    vPossuiOutraSuplMes := false;

    IF FPossuiPagamento(pCdFolhaPagamento => pCdFolhaRecalculo,
                        pCdVinculo        => pCdVinculo) THEN

      vTemRecalc := TRUE;
      /* SIG-10902-INICIO servidores que tiveram folha 13o. salário novembro em outro órgão, precisa buscar folha origem neste órgão */
      vCdFolha13OrigOutroOrgao := fTemFolha13NovOutroOrgao(pFolhaSuplementar.CdOrgao,
                                                           pCdVinculo);

      /* SIG-10902-FIM*/
      -- Carrega vetor com rubricas suplementares
      OPEN cSuplVinculo(pCdFolhaOrigem   => CASE
                                              WHEN vCdFolha13OrigOutroOrgao IS NOT NULL THEN
                                                vCdFolha13OrigOutroOrgao
                                              WHEN pCdFolhaPagou <> 0 THEN
                                               pCdFolhaPagou
                                              ELSE
                                               pCdFolhaOrigem
                                            END,
                        pCdFolhaVincSupl => pCdFolhaRecalculo,
                        pCdVinculo       => pCdVinculo);
      FETCH cSuplVinculo BULK COLLECT
        INTO vTabSuplVinculo;

      CLOSE cSuplVinculo;

      -- exclui folha de recalculo caso seja a mesma da suplementar

      IF pCdFolhaRecalculo =
         pFolhaSuplementar.CdFolhaPagamento AND
         pFolhaSuplementar.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes THEN

        -- Excluir Folha sem excluir Capa

        DELETE FROM Epaghistoricorubricarelvinc HRV
         WHERE HRV.CdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo;
        DELETE FROM EpaghistoricorubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo;

        -- Inicializa tabela de Datas de Calculo

        PCarregaTabDtCalculo;

        vNuSufixoDifMes := FMesPagamento(pCdOrgao   => pFolhaSuplementar.CdOrgao,
                                         pCdVinculo => pCdvinculo,
                                         pDtCalculo => pFolhaSuplementar.DtCalculo, -- Data da normal
                                         pDtIniMes  => pFolhaSuplementar.DtInicioMes,
                                         pDtFimMes  => pFolhaSuplementar.DtFimMes);
      END IF;

      -- Percorre rubricas suplementares

      IF vTabSuplVinculo.COUNT > 0 THEN

        vPossuiOutraSuplMes := FPossuiPagOutraSuplMes(pCdVinculo);

        FOR r IN vTabSuplVinculo.FIRST .. vTabSuplVinculo.LAST

         LOOP

          rSuplementar := vTabSuplVinculo(r);

          IF pFolhaSuplementar.CdTipoCalculo =
             PKGPAG_TIPO.cnTpCalculoDifMes THEN

            -- Sufixo da Rubrica sera mes de pagamento da diferenca
            rSuplementar.NuSufixoRubrica := vNuSufixoDifMes;

          END IF;

          -- FOI OMITIDO ISTO VISTO QUE O SELECT ANTERIOR Ja NaO CONSIDERA MAIS CONSIGNAcaO
          IF ( rSuplementar.FlGeraSuplementar = 'S') THEN

            IF (rSuplementar.FlTributacao = 'S') AND
               rSuplementar.CdTipoRubrica = 6 THEN

              rSuplementar.CdRubricaAgrupamento := PKGPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,
                                                                                5,
                                                                                rSuplementar.NuRubrica);

            END IF;

            IF (rSuplementar.FlPensaoAlimenticia = 'S' OR
                rSuplementar.CdTipoRubricaOrigem = 9) AND
                  rSuplementar.VlPagamentoOrigem >
                  rSuplementar.VlPagamentoSupl THEN

              NULL;

            ELSE

              --------------------------------------------------------------------------------------
              -- Caso a rubrica gerada seja de ferias do tipo 2 e a origem seja do tipo 1,
              -- a rubrica gerada e transformada para o tipo 1
              -- 14/04/2011
              --------------------------------------------------------------------------------------

              IF rSuplementar.CdTipoRubricaOrigem = 1 AND
                 rSuplementar.CdTipoRubrica = 2 AND
                 rSuplementar.NuRubrica = 56 THEN

                rSuplementar.CdRubricaAgrupamento := PKGPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,
                                                                                  1,
                                                                                  rSuplementar.NuRubrica);

              -- Solicitacao de Sustentacao #79626
              -- 12077/2018 - FOLHA - - RUBRICA 06-0953 NA FOLHA SUPLEMENTAR

              ELSIF rSuplementar.CdTipoRubricaOrigem = 5 AND
                    rSuplementar.CdTipoRubrica = 6 AND
                    rSuplementar.NuRubrica in (837,953) THEN

                rSuplementar.CdRubricaAgrupamento := PKGPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,
                                                                                  5,
                                                                                  rSuplementar.NuRubrica);

              else
                null;
              END IF;

              --
              -- Solicitacao de Sustentacao #76335
              -- 10000/2017 - Desconto de rubrica 06-0915 em folha suplementar
              -- 10437/2017 - FOLHA - - CALCULO DO IPREV (FF 662/15) VALORES RETROATIVO
              --
              IF rSuplementar.NuRubrica in (915,1328)
                AND rSuplementar.CdTipoRubrica = 6
                AND rSuplementar.CdTipoOrigemRubrica = 12
                THEN

                  rSuplementar.CdRubricaAgrupamento :=
                  PKGPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,5,rSuplementar.NuRubrica);

              END IF;

              vValorRecebido := 0;

              if vPossuiOutraSuplMes and
                 vTabSuplVinculo(r).CdTipoRubrica <> 9 then

                 vValorRecebido:= FPossuiPagRubOutraSuplMes (rSuplementar);

                 rSuplementar.Vlpagamento := rSuplementar.Vlpagamento - nvl(vValorRecebido,0);

              end if;

              IF rSuplementar.VlPagamento > 0 THEN

                INSERT INTO EPagHistoricoRubricaVinculo
                  (CdHistoricoRubricaVinculo,
                   CdFolhaPagamento,
                   CdRubricaAgrupamento,
                   CdVinculo,
                   NuSufixoRubrica,
                   CdLancamentoFinanceiro,
                   VlPagamento,
                   QtParcelas,
                   DtUltAlteracao,
                   vlRubricaNormal,
                   vlRubricaSupl,
                   CdTipoRubricaOrigem,
                   CdBaseConsignacao,
                   deprocessoretroativo,
                   vlindicerubrica,
                   vlindicenmrra,
                   cdprocessopagretroativo,
                   vlmontanteretroativo,
                   cdhistsentencajudicial)
                VALUES
                  (SPagHistoricoRubricaVinculo.NEXTVAL,
                   pFolhaSuplementar.CdFolhaPagamento,
                   rSuplementar.CdRubricaAgrupamento,
                   rSuplementar.CdVinculo,
                   rSuplementar.NuSufixoRubrica,
                   rSuplementar.CdLancamentoFinanceiro,
                   rSuplementar.vlPagamento,
                   1,
                   systimestamp,
                   rSuplementar.vlPagamentoOrigem,
                   rSuplementar.vlPagamentoSupl,
                   rSuplementar.CdTipoRubricaOrigem,
                   rSuplementar.CdBaseConsignacao,
                   rSuplementar.deprocessoretroativo,
                   rSuplementar.vlindicerubrica,
                   rSuplementar.vlindicenmrra,
                   rSuplementar.cdprocessopagretroativo,
                   rSuplementar.vlmontanteretroativo,
                   rsuplementar.cdhistsentencajudicial);

              END IF;

            END IF;

            if rSuplementar.Cdlancamentofinanceiro is not null and
               pkgpag_var.vgFolha.FlCalculoDefinitivo = 'S'

               then

                  vCdProcessoRestituicaoErario := FRestituicaoErario(rSuplementar.Cdlancamentofinanceiro);

                  if nvl(vCdProcessoRestituicaoErario,0) > 0 then
                     begin
                     select nvl(max(pag.nuparcela),0)
                       into vNuParcela
                      from epagpagamentolancamento pag
                     where pag.cdlancamentofinanceiro = rSuplementar.cdlancamentofinanceiro;
                      exception
                       when no_data_found then
                         vNuParcela := 0;
                       when others then
                         vNuParcela :=0;
                     end;

                     BEGIN

                      PKGPAG_LF.PRegistarPagamentoParcela(
                         pCdLancamentoFinanceiro => rSuplementar.CdLancamentoFinanceiro,
                                pNuAnoReferencia => pkgpag_var.vgFolha.NuAnoReferencia,
                                pNuMesreferencia => pkgpag_var.vgFolha.NuMesReferencia,
                                      pNuParcela => vNuParcela + 1,
                                   pValorParcela => rSuplementar.Vlpagamento);

                     EXCEPTION

                        WHEN OTHERS THEN

                          PKGPAG_GERAL.pInsereLog(
                              PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Erro ao gerar parcela de erário: Código do lançamento: ' || rSuplementar.CdLancamentoFinanceiro,
                              PKGPAG_VAR.vgCdVinculo);

                     END;

                  end if;

            end if;


          END IF;

        END LOOP;

      END IF;

    END IF;

    -- Caso possua pagamentos na folha de recalculo ou lancamento complementar
    -- 1) Finaliza parcelas do retroativo (folha definitiva)
    -- 2) Se possui lancamento complementar, reprocessa bases
    -- 3) Se nao possui lancamento complementar, se tipo de calculo e "Suplementar" e
    --    e total de proventos e menor que total de descontos, exclui registros

    IF vTemRecalc
     THEN

      /*PKGPAG_RT.PAtualizaParcelaRetroativo(pFolha     => pFolhaSuplementar,
                                           pCdVinculo => pCdVinculo);*/

      PKGPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => pFolhaSuplementar.CdFolhaPagamento,
                                          pCdVinculo        => pCdVinculo);

      -- Regera as totalizadoras

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento IN
             (PKGPAG_VAR.vgCdRubricaBaseTotPrv,
              PKGPAG_VAR.vgCdRubricaBaseTotDsc,
              PKGPAG_VAR.vgCdRubricaBaseTotLiq);

      IF PKGPAG_VAR.vgVlTotalProventos >= PKGPAG_VAR.vgVlTotalDescontos THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolhaSuplementar.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotPrv,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => NVL(PKGPAG_VAR.vgVlTotalProventos,
                                                                           0),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolhaSuplementar.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotDsc,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => NVL(PKGPAG_VAR.vgVlTotalDescontos,
                                                                           0),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolhaSuplementar.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotLiq,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => PKGPAG_VAR.vgVlBaseTotalLiquida,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        PKGPAG_GERAL.PExcluiValoresZerados(pCdVinculo        => pCdVinculo,
                                           pCdFolhaPagamento => pFolhaSuplementar.CdFolhaPagamento);

        -------------------------------------------------------------------
        -- Gera a capa de lote da Suplementar a partir da capa do recalculo
        -------------------------------------------------------------------

        IF pFolhaSuplementar.CdFolhaPagamento = pCdFolhaRecalculo THEN

          UPDATE EPagCapaHistRubricaVinculo CL
             SET vlProventos = NVL(PKGPAG_VAR.vgVlTotalProventos, 0),
                 vlDescontos = NVL(PKGPAG_VAR.vgVlTotalDescontos, 0)
           WHERE CL.cdVinculo = pCdVinculo
             AND CL.cdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento;

        ELSE

          DELETE FROM EPagCapaHistRubricaVinculo CL
           WHERE CL.cdVinculo = pCdVinculo
             AND CL.cdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento;

          INSERT INTO EPagCapaHistRubricaVinculo
                 (cdfolhapagamento,
                  cdvinculo,
                  vlproventos,
                  vldescontos,
                  cdmotivoafasttemporario,
                  cdmotivoafastdefinitivo,
                  insistemaorigem,
                  flativo,
                  flpagamentobloqueado,
                  flrecadastrado,
                  cdcreditobancario,
                  cdrelacaotrabalho,
                  cdregimetrabalho,
                  nucho,
                  cdgrupoocupacional,
                  cdlocalidade,
                  cdvalorgeralcefagrup,
                  cdcargocomissionado,
                  nunivelcef,
                  nureferenciacef,
                  nureferenciacco,
                  nunivelcco,
                  cdestruturacarreira,
                  cdgrauescolaridade,
                  cdnaturezavinculo,
                  cdsituacaoprevidenciaria,
                  nuchorelacao,
                  cdunidadeorganizacional,
                  cdagenciacredito,
                  Nucontacredito,
                  Nudvcontacredito,
                  Cdagenciareceb,
                  Nucontareceb,
                  Fltipocontacredito,
                  Nuagencia,
                  Nudvagencia,
                  Nubanco,
                  cdCentroCusto,
                  inAposentadoriaEspecial)
            SELECT pFolhaSuplementar.CdFolhaPagamento,
                   CdVinculo,
                   NVL(PKGPAG_VAR.vgVlTotalProventos, 0),
                   NVL(PKGPAG_VAR.vgVlTotalDescontos, 0),
                   CdMotivoAfastTemporario,
                   CdMotivoAfastDefinitivo,
                   InSistemaOrigem,
                   FlAtivo,
                   FlPagamentoBloqueado,
                   FlRecadastrado,
                   CdCreditobancario,
                   CdRelacaotrabalho,
                   CdRegimetrabalho,
                   NuCho,
                   CdGrupoocupacional,
                   CdLocalidade,
                   CdValorgeralCEFAgrup,
                   CdCargoComissionado,
                   NuNivelCEF,
                   NuReferenciaCEF,
                   NuReferenciaCCO,
                   NuNivelCCO,
                   CdEstruturaCarreira,
                   CdGrauEscolaridade,
                   CdNaturezaVinculo,
                   CdSituacaoPrevidenciaria,
                   NuChorelacao,
                   CdUnidadeOrganizacional,
                   PKGPAG_VAR.vgCdAgenciaCredito,
                   PKGPAG_VAR.vgNuContaCredito,
                   PKGPAG_VAR.vgNuDvContaCredito,
                   PKGPAG_VAR.vgCdAgenciaReceb,
                   PKGPAG_VAR.vgNuContaReceb,
                   PKGPAG_VAR.vgFlTipoContaCredito,
                   PKGPAG_VAR.vgNuAgencia,
                   PKGPAG_VAR.vgNuDvAgencia,
                   PKGPAG_VAR.vgNuBanco,
                   cp1.cdcentrocusto,
                   cp1.inaposentadoriaespecial
              FROM EPagCapaHistRubricaVinculo CP1
             WHERE CP1.CdFolhaPagamento = pCdFolhaRecalculo
               AND CP1.CdVinculo = pCdVinculo;

        END IF;

      ELSE

        -- Incluir rubrica 01-???? - AJUSTE SALDO DEVEDOR PARAMETRO DO AGRUPAMENTO  = abs (PKGPAG_VAR.vgVlTotalProventos - PKGPAG_VAR.vgVlTotalDescontos)
        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => pkgpag_var.vgParamPagamento.CdRubAgrupAjusteSaldoDevedor,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => abs (PKGPAG_VAR.vgVlTotalProventos - PKGPAG_VAR.vgVlTotalDescontos),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        -- Incluir rubrica 09-???? - 09-xxxx AJUSTE SALDO DEVEDOR FOLHA 13 = abs (PKGPAG_VAR.vgVlTotalProventos - PKGPAG_VAR.vgVlTotalDescontos)
        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => pkgpag_var.vgParamPagamento.CdRubAgrupAjusteSaldoDevedor13,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => abs (PKGPAG_VAR.vgVlTotalProventos - PKGPAG_VAR.vgVlTotalDescontos),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);


        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vgVinculo.CdPessoa,
                                 'Geração de líquido negativo.',
                                 PKGPAG_VAR.vgVinculo.CdVinculo,
                                 2,6);

      END IF;

      --END IF;

    ELSE

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Erro ao processar suplementar: ' || SQLERRM,
                              PKGPAG_VAR.vgCdVinculo);

  END;



PROCEDURE PInicializaVariaveis (pRegVinc   IN rVinc,
                                pDtCalculo IN DATE) IS

BEGIN
 
  -- Constantes

  PKGPAG_VAR.vgPercDecJudMargem                 := 100;

  PKGPAG_VAR.bReprocessou13Sal                  := FALSE;

  PKGPAG_VAR.vgCdRubricaAbonoPerm               := 0;

  PKGPAG_VAR.vgQtFaltas                         := 0;

  PKGPAG_VAR.vgVinculo.CdVinculo                := pRegVinc.CdVinculo;

  PKGPAG_VAR.vgVinculo.CdPessoa                 := pRegVinc.CdPessoa;

  PKGPAG_VAR.vgVinculo.DtAdmissao               := pRegVinc.DtAdmissao;

  PKGPAG_VAR.vgVinculo.DtNascimento             := pRegVinc.DtNascimento;

  PKGPAG_VAR.vgVinculo.DtDesligamento           := pRegVinc.DtDesligamento;

  PKGPAG_VAR.vgVinculo.CdRegimeTrabalho         := pRegVinc.CdRegimeTrabalho;

  PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario   := pRegVinc.CdRegimePrevidenciario;

  PKGPAG_VAR.vgVinculo.FlSexo                   := pRegVinc.FlSexo;

  PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria := PKGPAG_GERAL.FSituacaoPrevVigente(pCdVinculo   => pRegVinc.CdVinculo,
                                                                                     pDtInicioMes => PKGPAG_VAR.vgFolha.DtInicioMes,
                                                                                     pDtFimMes    => PKGPAG_VAR.vgFolha.DtFimMes);

  PKGPAG_VAR.vgVinculo.CdFolhaPagamentoNormal := 0;


  PKGPAG_VAR.vpagasitdisposicao := '';

END;

PROCEDURE PProcessarVinculo13Salario (pCalculo                 IN PKGPAG_CAL.rCalculo,
                                      pRegVinc                 IN rVinc,
                                      pDtCalculo               IN DATE,
                                      pTributacao   IN OUT NOCOPY PKGPAG_TRIBUTACAO.rTributacao  
                                      ) IS

  vCdExpressaoFormCalc        INTEGER;

  vVinc                       rVinc;

  vVlTeto                     NUMBER(13,2);

  vVlIndice                   INTEGER;

  --vCdHistTipoPensaoRubrica    INTEGER;

  vDtInicioDireito            DATE;

  vDtInclusao                 DATE;

  vVlIsencaoBloqueio          NUMBER(13,2);

  vVlIsentoTeto13             NUMBER(13,2);

  vVlBase13                   NUMBER(13,2);

  --vCdRubricaCTISP13           INTEGER;

  vCdRubricaDevAdiant13CTISP  INTEGER;

  vVlAdiantamentoPago         NUMBER(13,2);

  vCdRubrica0968              INTEGER := 0;

  vVlRubrica090932            NUMBER(13,2) := 0;

  bGerouCtisp13               boolean := false;

  vIndiceCtisp13              integer;

  vVlRubrica09_0380           NUMBER(13,2) := 0;

  vVlRubrica09_1380           NUMBER(13,2) := 0;

  VExpressao                  VARCHAR2(2000);

  VexpressaoResultado         NUMBER(17,2) := 0;

  vVlAnoMesFolha              INTEGER;

  vlRubBase13Sal            NUMBER(13,2) := 0;

  vCdTipoFolha integer;

  vFlIncide13 CHAR(1);       -- 21461/2024 - Tiago Von
  vFlIncideAdiant13 CHAR(1); -- 21461/2024 - Tiago Von
  vCdRubricaPenhora INTEGER; -- 21461/2024 - Tiago Von


  FUNCTION FPossuiCTISPVigente RETURN INTEGER IS

  vNuMesesTrab integer;
  vDtInicio date;
  --vDtFim    date;
  --vCdFolha  integer;
  --vSoma     number(13,2);

  BEGIN
 
    IF pkgpag_var.bGeraPagamentoCTISP then

    vDtInicio := '01/01/' || pkgpag_var.vgFolha.NuAnoReferencia;
    --vDtFim    := '30/11/' || pkgpag_var.vgFolha.NuAnoReferencia;
    vNuMesesTrab := 0;

    IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

      FOR i IN PKGPAG_VAR.vgCEF.FIRST  .. PKGPAG_VAR.vgCEF.LAST
      LOOP

        IF PKGPAG_VAR.vgCEF(i).CdRelacaoTrabalho = PKGPAG_TIPO.cnRelCTISP THEN

          IF PKGPAG_VAR.vgCEF(i).DtFimRelacao > PKGPAG_VAR.vgFolha.DtInicioMes OR
             PKGPAG_VAR.vgCEF(i).DtFimRelacao IS NULL AND
             fGeraPagamentoCtisp(pkgpag_var.vgApo(1).CdVinculo,
                                 PKGPAG_VAR.vgCEF(i).DtInicioRelacao,
                                 nvl(PKGPAG_VAR.vgCEF(i).DtFimRelacao,PKGPAG_VAR.vgFolha.DtFimMes))
              THEN

             vNuMesesTrab := vNuMesesTrab + pkgpag_fb.fmneuqtmesestrabano(pfolha => pkgpag_var.vgFolha,
                                                                          pcdvinculo => PKGPAG_VAR.vgCEF(i).CdVinculo,
                                                                          pdtiniciorelacao => greatest(PKGPAG_VAR.vgVinculo.DtAdmissao,vDtInicio),
                                                                          pdtfimrelacao => PKGPAG_VAR.vgCEF(i).DtFimRelacao,
                                                                          pdtcalculo => pkgpag_var.vgFolha.DtCalculo);
            RETURN vNuMesesTrab;

          END IF;

        END IF;

      END LOOP;
     end if;

    else

      return 0;

    END IF;

    RETURN 0;

  END;

  --
  -- Para folha 13 verificar se teve CTISP vigente no ano
  --
  FUNCTION FPossuiCTISPVigenteAno (pCdVinculo IN INTEGER, pVlIndice IN INTEGER) RETURN BOOLEAN IS

  vNuMesesTrab integer;
  vDtInicio date;
  vDtFim    date;
  --vCdFolha  integer;
  vSoma     number(13,2);

  BEGIN
 
     vDtInicio := '01/01/' || pkgpag_var.vgFolha.NuAnoReferencia;
     vDtFim    := '30/11/' || pkgpag_var.vgFolha.NuAnoReferencia;
     vNuMesesTrab := 0;

     for ctisp in (select cef.dtinicio, cef.dtfim
                     from ecadhistcargoefetivo cef
                    where cef.cdvinculo = pCdVinculo
                      and to_char(cef.dtfim,'yyyy') = to_char(pkgpag_var.vgFolha.NuAnoReferencia)
                      and to_char(cef.dtfim,'mm') < '12'
                      and cef.flanulado = 'N'
                    order by cef.dtinicio)
     loop

       if fGeraPagamentoCtisp(pkgpag_var.vgAPO(1).CdVinculo, ctisp.DtInicio, ctisp.DtFim)
         then

         vNuMesesTrab := vNuMesesTrab + pkgpag_fb.fmneuqtmesestrabano(pfolha => pkgpag_var.vgFolha,
                                                                    pcdvinculo => pCdVinculo,
                                                                    pdtiniciorelacao => greatest(vDtInicio, ctisp.Dtinicio),
                                                                    pdtfimrelacao => ctisp.Dtfim,
                                                                    pdtcalculo => pkgpag_var.vgFolha.DtCalculo);

         vDtFim := ctisp.dtfim;

       end if;

     end loop;

     if vNuMesesTrab > 0
         then

           begin
             with fol as (select f.cdfolhapagamento
                            from epagfolhapagamento f
                            inner join epagtipofolhapagamento t on t.cdtipofolhapagamento = f.cdtipofolhapagamento
                                                               and t.cdtipofolha = pkgpag_tipo.cnTpFolhaNormal
                           where f.cdorgao = pkgpag_var.vgFolha.cdorgao
                             and f.flcalculodefinitivo = 'S'
                             and f.cdtipocalculo = 1
                             and f.nuanomesreferencia = to_number(to_char(vdtfim,'yyyymm')))
             select hv.vlreal
               into vSoma
               from epaghistoricorubricarelvinc hv
               inner join fol f on f.cdfolhapagamento = hv.cdfolhapagamento
               where hv.cdvinculo = pCdVinculo
                 and hv.cdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,229)
                 and rownum < 2;

             if nvl(vSoma,0) > 0
               then

                 PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                       pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                       pCdExpressaoFormCalc  => NULL,
                                                       pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubAgrup13CTISP,
                                                       pNuSufixoRubrica      => case when pVlIndice = 0 then 1 else 2 end,
                                                       pVlPagamento          => (vSoma / 12 * vNuMesesTrab),
                                                       pVlIndice             => vNuMesesTrab,
                                                       pCdTipoOrigemRubrica  => 1,
                                                       pDeexpressao          => vSoma || ' / (12 * ' || vNuMesesTrab || ')');

             end if;

           end;

           RETURN TRUE;

       else
          return false;
       end if;

    exception
      when no_data_found
        then
          return false;

      when others
        then
          return false;
  END;

  FUNCTION fpossuidisposicao(pcdvinculo IN INTEGER,
                             pdtinicio  IN DATE,
                             pDtFim     IN DATE)
  RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vcont
      FROM emovdisposicaoservidor hce
   WHERE HCE.CdVinculo = pCdVinculo AND
         (HCE.DTDISPOSICAO <= pDtFim AND
        (HCE.Dtfimdisposicao >= pDtInicio OR HCE.Dtfimdisposicao IS NULL)) AND
         HCE.FlAnulado = PKGPAG_TIPO.cnN AND
         ROWNUM < 2;

    IF vcont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION fpaganodestino(pcdvinculo IN INTEGER)

     RETURN BOOLEAN IS

      vflpagamento CHAR(1);

  BEGIN
 
      SELECT flpagamento
        INTO vflpagamento
        FROM emovservidorrecebido sr
     WHERE SR.CdVinculo = pCdVinculo AND
           SR.DtApresentacao <= PKGPAG_VAR.vgFolha.DtFimMes  AND
           (SR.DtFimDisposicao >= PKGPAG_VAR.vgFolha.DtInicioMes OR SR.DtFimDisposicao IS NULL);

      IF vflpagamento = 'O' THEN

        RETURN FALSE;

      ELSE

        RETURN TRUE;

      END IF;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN TRUE;

  END;
  --
  -- Verificar se esta a disposicao e recebe na origem
  --
  FUNCTION fpaganaorigem(pcdvinculo IN INTEGER)

     RETURN BOOLEAN IS

      vflpagamento CHAR(1);

  BEGIN
 
      select 'S'
        INTO vflpagamento
        from ecadhistcargoefetivo cef
       where cef.cdvinculo = pCdVinculo
         and cef.cdrelacaotrabalho = pkgpag_tipo.cnRelTrabDisposicao
         and CEF.Cdorgaoexercicio = pkgpag_var.vgfolha.cdorgao
         AND CEF.Dtinicio <= PKGPAG_VAR.vgFolha.DtFimMes
         AND (CEF.Dtfim >= PKGPAG_VAR.vgFolha.DtInicioMes OR CEF.Dtfim IS NULL)
         and exists (select 1 from ecadhistcargoefetivo cef1
                        inner join emovmovimentacao mov1 on mov1.cdhistcargoefetivo = cef1.cdhistcargoefetivo
                             where CEF1.CdVinculo = pCdVinculo
                               AND MOV1.Dtmovimentacao <= PKGPAG_VAR.vgFolha.DtFimMes
                               AND (Mov1.Dtfimmovimentacao >= PKGPAG_VAR.vgFolha.DtInicioMes
                                    OR Mov1.Dtfimmovimentacao IS NULL)
                               AND MOV1.Flpagamentoorigem = pkgpag_tipo.cnS
                               AND CEF1.Dtinicio <= PKGPAG_VAR.vgFolha.DtFimMes
                               AND MOV1.Cdorgaodestino = CEF1.Cdorgaoexercicio
                               AND (CEF1.Dtfim >= PKGPAG_VAR.vgFolha.DtInicioMes OR CEF1.Dtfim IS NULL))
          and rownum < 2;

      IF vflpagamento = 'S' THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN FALSE;

  END;

BEGIN

   vVinc := pRegVinc;

   PInicializaVariaveis(pRegVinc   => vVinc,
                        pDtCalculo => pdtCalculo);

   IF FTemPagamentoOutroOrgao THEN

      GOTO LBL_CONTINUE;

   END IF;

   PKGPAG_GERAL.PArmazenaRelacoesVinculo(pCdVinculo => PKGPAG_VAR.vgVinculo.CdVinculo);

   PKGPAG_TRIBUTACAO.PInicializarVinculo(pTributacao => pTributacao);

   --
   -- FOLHA - 8812/2016 - FOLHA DE ADIANTAMENTO DE 13º
   -- Solicitacao de Sustentacao #70279
   -- Calcular somente para os que nao tem data de desligamento em Junho e Julho no adiantamento
   --
   IF (PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaCtisp13)
     AND TRUNC(NVL(vVinc.DtDesligamento,PKGPAG_TIPO.cnDtMax), 'YEAR') < TRUNC(PKGPAG_VAR.vgFolha.DtInicioMes, 'YEAR'))
     OR (PKGPAG_VAR.vgFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaCtisp13
         AND NVL(vVinc.DtDesligamento,PKGPAG_TIPO.cnDtMax) <=
          (CASE WHEN PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFunebre13 or
                     (PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 and
                      PKGPAG_VAR.vgFolha.NuMesReferencia = 12 and
                      PKGPAG_VAR.vgFolha.FlCalculoDefinitivo = 'N')
                THEN (PKGPAG_VAR.vgFolha.DtInicioMes - 1)
                WHEN PKGPAG_VAR.vgFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaAdiant13
                THEN PKGPAG_VAR.vgFolha.DtFimMes
                ELSE last_day(PKGPAG_VAR.vgFolha.DtFimMes +1)
           END))
      OR ( (pkgpag_var.vgFolha.CdAgrupamento in (1, 134) and
          pkgpag_var.vgFolha.NuMesReferencia  in (11, 12) and
          PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 and
          to_char(vVinc.DtDesligamento,'YYYYMM') = pkgpag_var.vgFolha.nuanoreferencia||'12'))  THEN

      GOTO LBL_CONTINUE;

   END IF;

   -- Calcular

   PKGPAG_GERAL.PTrataBloqueioCredito;
   --
   -- Solicitacao de Sustentacao #73204
   -- 9492/2016 - CHAMADO - - INCLUSAO NA BASE DO IPREV 13º DO TOTALIZADOR 09-0967
   --

   pkgpag_var.vgpercentacumats(1) := fPercentualAts(PKGPAG_VAR.vgVinculo.CdVinculo,PKGPAG_VAR.vgFolha.DtFimMes);

   IF pkgpag_geral.fpossuilancfinanceiro(PKGPAG_VAR.vgVinculo.CdVinculo,
                                         PKGPAG_VAR.vgFolha,
                                         PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,967))

     THEN

       vCdRubrica0968 := PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,968);

   END IF;
   -----------------------------------------------------------------------------------
   -- Para SCParcerias, CIASC, SANTUR e CIDASC
   -- foi solicitado que a relacao trabalho Diretor/Presidente
   -- nao deve aparecer na folha de 13°
   -- SANTUR solicitou para que tambem nao gere 13º para a relacao de trabalho conselheiro. Solicitacao #78142
   -----------------------------------------------------------------------------------

   IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento IN (13, 15)
     AND PKGPAG_VAR.vgFolha.CdAgrupamento in (2,6,136,4) THEN
     GOTO LBL_CONTINUE;
   END IF;

  -- Nao calcula decimo terceiro para quem esta com afastamento sem remuneracao e afastado o mes inteiro
   PKGPAG_VAR.vMotAfast := PKGPAG_CAL.FAfastSemRemun(PKGPAG_VAR.vgVinculo.CdVinculo,
                                                 PKGPAG_VAR.vgFolha.DtInicioMes,
                                                 PKGPAG_VAR.vgFolha.DtFimMes,
                                                 PKGPAG_VAR.vDtCalculo);

   -- Excluir CIASC/EPAGRI processa para todos afastados menos demitidos.
   IF ((PKGPAG_VAR.vMotAfast.InAfastado = PKGPAG_TIPO.cnAfastadoMesTodo AND PKGPAG_VAR.vgFolha.CdAgrupamento NOT IN (2,4,5,133, 276) AND
        PKGPAG_VAR.vgFolha.NuMesReferencia <> 12 ) OR
       (PKGPAG_VAR.vMotAfast.InTipoAfastamento = 'D' AND PKGPAG_VAR.vgFolha.CdAgrupamento = 2) )
      and not FTemFolha13Definitivo(PKGPAG_VAR.vgVinculo.CdVinculo)
      THEN
       GOTO LBL_CONTINUE;

   END IF;

   -----------------------------------------------------------------------------------
   -- Para a pensao nao previdenciaria verifica se possui direito a pagamento de
   -- adiantamento de 13 ou 13 salario
   -----------------------------------------------------------------------------------

   IF PKGPAG_VAR.vgPensaoNaoPrev.COUNT > 0 THEN

     FOR i IN PKGPAG_VAR.vgPensaoNaoPrev.FIRST .. PKGPAG_VAR.vgPensaoNaoPrev.LAST
     LOOP

       IF (PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaAdiant13 AND
           PKGPAG_VAR.vgPensaoNaoPrev(i).FlAdianta13 = 'N') OR
          (PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 AND
           PKGPAG_VAR.vgPensaoNaoPrev(i).FlPaga13 = 'N') THEN

         GOTO LBL_CONTINUE;

       END IF;

     END LOOP;

   END IF;

   -----------------------------------------------------------------------------------
   -- Se e folha de adiantamento, verifica se ja recebeu pagamento de adiantamento
   -- e o agrupamento nao permite
   -----------------------------------------------------------------------------------

   vVlAdiantamentoPago := 0;

   IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaAdiant13 AND
      PKGPAG_VAR.vgParamPagamento.FlRecebeAdiantamentos13 = 'N' THEN

     BEGIN

       SELECT SUM(vlPagamento)
         INTO vVlAdiantamentoPago
         FROM ePagHistoricoRubricaVinculo HRV
        INNER JOIN EPagFolhaPagamento FP
           ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
        INNER JOIN EPagTipoFolhaPagamento TFP
           ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento
        WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
              FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl) AND
              FP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
              FP.NuMesReferencia BETWEEN 1 AND 12 AND
              FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
              HRV.CdRubricaAgrupamento IN (SELECT CdRubricaAgrupamento
                                             FROM EPagRubricaAgrupamento RA
                                            INNER JOIN EPagRubrica R
                                               ON RA.CdRubrica = R.CdRubrica
                                            WHERE R.CdTipoRubrica IN (1,2,3) AND
                                                  R.NuRubrica = 24 AND
                                                  RA.CdAgrupamento = PKGPAG_VAR.vgFolha.CdAgrupamento);

       IF vVlAdiantamentoPago > 0 THEN

         GOTO LBL_CONTINUE;

       END IF;

     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         NULL;

     END;

   END IF;

   PKGPAG_GERAL.PSetaDadosBancarios(pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                    pNuAnoReferencia  => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                    pNuMesReferencia  => PKGPAG_VAR.vgFolha.NuMesReferencia,
                                    pDtCalculo        => pDtCalculo);

   PKGPAG_VAR.vgLancComplementar := PKGPAG_GERAL.FRubricasLancComplementar(pCdVinculo => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                                           pFolha     => PKGPAG_VAR.vgFolha);

   PKGPAG_TRIBUTACAO.PSetaRubricasIsentas(pFolha     => PKGPAG_VAR.vgFolha,
                                          pCdVinculo => vVinc.CdVinculo);

   vVlIndice := 0;


   PKGPAG_GERAL.PLogProcIni('040300','Carregar Folha Vinculo');

   PKGPAG_GERAL.PCarregarFolhaVinculo (pCdCalculo       => pCalculo.cdCalculo, 
                                       pCdPessoa        => pRegVinc.CdPessoa,
                                       pFlIniciarPessoa => 1);

   PKGPAG_GERAL.PLogProcFim('040300');

   ---------------------------------------------------------------------------------------------
   -- Realiza a copia dos proventos da folha normal ou de recalculo
   ---------------------------------------------------------------------------------------------

   if pkgpag_var.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl then


       BEGIN
      -- Folha 13 do Mes da Suplementar como Recalculo
      SELECT fp.cdfolhavincsupl, tfp.cdtipofolha
        INTO PKGPAG_VAR.vgCdFolhaRecalculo, vCdTipoFolha
        FROM EPagFolhaPagamento FP
        inner join epagtipofolhapagamento tfp on fp.cdtipofolhapagamento=tfp.cdtipofolhapagamento
        where fp.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento;

      -- Folha 13 do Mes Anterior como Folha Normal para a Suplementar
      SELECT FP.CdFolhaPagamento
        INTO PKGPAG_VAR.vgCdFolhaNormal
        FROM EPagFolhaPagamento FP
        inner join epagtipofolhapagamento tfp on fp.cdtipofolhapagamento=tfp.cdtipofolhapagamento
        where fp.numesreferencia = pkgpag_var.vgfolha.numesreferencia-- - 1
          and fp.nuanoreferencia = pkgpag_var.vgfolha.nuanoreferencia
          and fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoNormal
          and tfp.cdtipofolha = vCdTipoFolha
          and fp.cdorgao = pkgpag_var.vgFolha.Cdorgao
          and fp.flcalculodefinitivo = 'S';

     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         return;

       when others then
          return;

      END;

       PProcessaFolhaSuplementar(pkgpag_var.vgFolha,
                                 PKGPAG_VAR.vgCdFolhaNormal,
                                 PKGPAG_VAR.vgCdFolhaRecalculo,
                                 PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pkgpag_var.vgFolha.FlCalculoDefinitivo,
                                 0, 0);

   else

       PGeraProventos(PKGPAG_VAR.vgVinculo.CdVinculo,
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                      PKGPAG_VAR.vgCdFolhaNormal,
                      PKGPAG_VAR.vgCdFolhaRecalculo,
                      PKGPAG_VAR.vgFolha.DtInicioMes,
                      PKGPAG_VAR.vgFolha.DtFimMes);

       ---------------------------------------------------------------------------------------------
       -- Recupera valores da rubrica extra-teto (01-0280) e demais rubricas com isencao de
       -- bloqueio de remuneracao que incidem para a base do 13 salario
       ---------------------------------------------------------------------------------------------

       vVlIsencaoBloqueio := FRetornaValorIsentoTeto(pcdVinculo => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                     pFolha     => PKGPAG_VAR.vgFolha);

       ---------------------------------------------------------------------------------------------
       -- Recupera a formula associada ao 01-0023, regera a base do 13 e executa a formula
       ---------------------------------------------------------------------------------------------

       vCdExpressaoFormCalc :=

          PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                 pCdRubricaAgrupamento     => PKGPAG_VAR.vgCdRubAgrup13,
                                                 pCdRelacaoVinculo         => 0);

       IF vCdExpressaoFormCalc > 0 THEN
         
        IF PKGPAG_VAR.vgFolha.CdTipoFolha NOT IN (PKGPAG_TIPO.cnTpFolhaCtisp13, pkgpag_tipo.cnTpFolhaAdiant13Ctisp) THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubAgrup13,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

          ---------------------------------------------------------------------------------------
          -- Caso a base de 13 salario nao exista (mes em orgao nao implantado), gera a rubrica
          ---------------------------------------------------------------------------------------
          IF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                               pCdRubrica            => PKGPAG_VAR.vgCdRubBase13Sal) = 0 THEN

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBase13Sal,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

                                                  END IF;
          PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                           pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                           pCdRubrica       => PKGPAG_VAR.vgCdRubBase13Sal,
                                           pTpProcessamento => 2,
                                           pTpLocal         => 2); /*Vinculo*/

          vlRubBase13Sal := NVL(PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                               pCdRubrica            => PKGPAG_VAR.vgCdRubBase13Sal), 0);

          PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                           pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                           pCdRubrica       => PKGPAG_VAR.vgCdRubAgrup13,
                                           pTpProcessamento => 1,
                                           pTpLocal         => 2); /*Vinculo*/
                                        

          ------------------------------------------------------------------------------------
          -- Caso o evento de 13º do CTISP esteja parametrizado no agrupamento ira calcula-lo
          ------------------------------------------------------------------------------------

          

          ELSIF PKGPAG_VAR.vgCdRubAgrup13CTISP > 0  THEN
            
            bGerouCtisp13 := false;

             vIndiceCtisp13 := FPossuiCTISPVigente;

             IF nvl(vIndiceCtisp13,0) > 0 THEN

               vCdExpressaoFormCalc :=

                  PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                         pCdRubricaAgrupamento     => PKGPAG_VAR.vgCdRubAgrup13CTISP,
                                                         pCdRelacaoVinculo         => 0);

               IF vCdExpressaoFormCalc > 0 THEN

                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                        pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                        pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubAgrup13CTISP,
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => 0,
                                                        pVlIndice             => NULL,
                                                        pCdTipoOrigemRubrica  => 1);

                  PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                   pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                   pCdRubrica       => PKGPAG_VAR.vgCdRubAgrup13CTISP,
                                                   pTpProcessamento => 1,
                                                   pTpLocal         => 2); /*Vinculo*/

                  UPDATE EPagHistoricoRubricaVinculo HRV
                     SET HRV.VlIndiceRubrica = vIndiceCtisp13
                   WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                         HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                         HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13CTISP;

               END IF;

               bGerouCtisp13 := true;

            END IF;

            IF FPossuiCTISPVigenteAno (PKGPAG_VAR.vgVinculo.CdVinculo, nvl(vIndiceCtisp13,0)) THEN

              bGerouCtisp13 := true;

            END IF;

          END IF;

          ------------------------------------------------------------------------------------
          -- Recupera o codigo da rubrica de 13 associada a Devolucao de adiantamento CTISPs
          -- ou DIRETOR/PRESIDENTE (SC-Parcerias)
          ------------------------------------------------------------------------------------

          vCdRubricaDevAdiant13CTISP := null;
          if pkgpag_var.vgcef.count > 0 and PKGPAG_VAR.vgFolha.CdTipoFolha in (pkgpag_tipo.cnTpFolhaAdiant13Ctisp) then
            -- ignorar os vinculos que tem relacao CTISP com data fim da relacao posterior ao ano/mes referencia da folha que está sendo calculada
            for i in pkgpag_var.vgcef.first .. pkgpag_var.vgcef.last
            loop
              if pkgpag_var.vgCEF(i).cdrelacaotrabalho = pkgpag_tipo.cnRelCTISP
                 and (pkgpag_var.vgCEF(i).dtfimrelacao is null
                   or to_number(to_char(pkgpag_var.vgCEF(i).dtfimrelacao, 'YYYYMM')) > PKGPAG_VAR.vgFolha.nuanoreferencia * 100 + PKGPAG_VAR.vgFolha.numesreferencia)
              then
                vCdRubricaDevAdiant13CTISP := 0;
                exit;
              end if;
            end loop;
          end if;

          if vCdRubricaDevAdiant13CTISP is null then
            vCdRubricaDevAdiant13CTISP := PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 5, 1324);
          end if;

          if vCdRubricaDevAdiant13CTISP > 0 and pkgpag_var.vgFolha.CdAgrupamento = 134 and not bGerouCtisp13 then
              vCdRubricaDevAdiant13CTISP := 0;
          end if;

          ---------------------------------------------------------------------------------------------
          -- Busca o valor do Bloqueio de Remuneracao - Teto
          -- Caso possua alguma decisao judicial para a rubrica do Teto do Governador
          -- busca o valor do teto/codigo do valor de referencia na sentenca do contrario seleciona da
          -- tabela de valor de referencia
          ---------------------------------------------------------------------------------------------

          PKGPAG_VAR.vgVlRefTetoDecJud := NULL;

          PKGPAG_VAR.vgCdValRefTetoDecJud := NULL;

          IF PKGPAG_GERAL.FPossuiDecisaoJudicial(pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                 pNuAnoReferencia => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                 pNuMesReferencia => PKGPAG_VAR.vgFolha.NuMesReferencia,
                                                 pCdRubrica       => PKGPAG_VAR.vgCdRubricaTetoGov,
                                                 pVlDecisaoJud    => PKGPAG_VAR.vgVlRefTetoDecJud,
                                                 pCdValorRef      => PKGPAG_VAR.vgCdValRefTetoDecJud,
                                                 pDtInicioDireito => vDtInicioDireito,
                                                 pDtInclusao      => vDtInclusao) THEN

             PKGPAG_VAR.vgVlRefTetoDecJud := PKGPAG_VAR.vgVlRefTetoDecJud;

          END IF;

          ---------------------------------------------------------------------------------------------
          -- Recupera a formula associada ao 05-0524 -- Devolucao de adiantamento de 13º
          ---------------------------------------------------------------------------------------------

          vCdExpressaoFormCalc :=

              PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                     pCdRubricaAgrupamento     => PKGPAG_VAR.vgCdRubricaDevAnt13,
                                                     pCdRelacaoVinculo         => 0);

          IF vCdExpressaoFormCalc > 0 THEN

             PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento  => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                   pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                   pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaDevAnt13,
                                                   pNuSufixoRubrica      => 1,
                                                   pVlPagamento          => 0,
                                                   pVlIndice             => NULL,
                                                   pCdTipoOrigemRubrica  => 1);

             PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                              pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                              pCdRubrica       => PKGPAG_VAR.vgCdRubricaDevAnt13,
                                              pTpProcessamento => 1,
                                              pTpLocal         => 2); /*Vinculo*/



          END IF;

          IF vCdExpressaoFormCalc > 0 AND PKGPAG_VAR.vgFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaFunebre13 THEN

            PKGPAG_POS.PDevolucao13SalPensao(pFolha      => PKGPAG_VAR.vgFolha,
                                              pCdVinculo  => PKGPAG_VAR.vgVinculo.CdVinculo,
                                              pRubrica    => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao));

          END IF;

           --------------------------------------------------------------------------------------
           -- Busca a quantidade de meses trabalhados no ano e atualiza o indice
           --------------------------------------------------------------------------------------

          IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT AND
             PKGPAG_VAR.vgFolha.CdOrgao <> 43 THEN

            vVlIndice :=
              PKGPAG_FB.FMneuQtMesesTrabAno (pFolha           => PKGPAG_VAR.vgFolha,
                                             pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                             pDtInicioRelacao => PKGPAG_VAR.vgRelVincPrincipal.DtInicioRelacao,
                                             pDtFimRelacao    => PKGPAG_VAR.vgVinculo.DtDesligamento,
                                             pDtCalculo       => pDtCalculo);

          ELSE

            vVlIndice :=
              PKGPAG_FB.FMneuQtMesesTrabAno (pFolha           => PKGPAG_VAR.vgFolha,
                                             pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                             pDtInicioRelacao => PKGPAG_VAR.vgVinculo.DtAdmissao,
                                             pDtFimRelacao    => PKGPAG_VAR.vgVinculo.DtDesligamento,
                                             pDtCalculo       => pDtCalculo);

          END IF;

          IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelCTISP AND
             PKGPAG_VAR.vgFolha.CdOrgao = 443 THEN

             --ALTERA INDICE DA RUB 01-0323 TB.
             UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.VlIndiceRubrica = vVlIndice
           WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                 HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                 HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13CTISP;

          END IF;

          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.VlIndiceRubrica = vVlIndice
           WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                 HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                 HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13;

          -------------------------------------------------------------------------------------------------------
          --- VERIFICA ANTES DA DELECAO DAS RUBRICAS QUE NAO SAO DE 13 SALARIO, QUAIS DELAS (MONTANTE DO VALOR)
          --- INCIDEM PARA O PROPRIO 13 SALARIO E POSSUEM DECISAO JUDICIAL QUE AS RETIRAM DA BASE DO TETO
          --- ESPECIFICO DO 13 SALARIO.
          -------------------------------------------------------------------------------------------------------

          vVlIsentoTeto13 := FValorIsentoTeto13Sal(pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                   pCdFolhaPagamento => PKGPAG_VAR.vgCdFolhaNormal,
                                                   pNuAnoReferencia  => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                   pNuMesReferencia  => PKGPAG_VAR.vgFolha.NuMesReferencia);

          -----------------------------------------------------------------------------------------------
          -- Exclui rubricas que nao compoe o 13 salario
          -----------------------------------------------------------------------------------------------

          IF vCdRubrica0968 > 0 THEN

               UPDATE EPagHistoricoRubricaVinculo HRV
                  SET HRV.CDRUBRICAAGRUPAMENTO = vCdRubrica0968
                WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                  AND HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(
                                                 PKGPAG_VAR.vgFolha.CdAgrupamento,9,967);

          END IF;

          IF pkgpag_var.bPossuiIprevCCO THEN

             vVlRubrica090932 := NVL(PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => vVinc.CdFolhaPagamento,
                                                                       pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                                       pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(
                                                                                            PKGPAG_VAR.vgFolha.CdAgrupamento,9,932)), 0);

             IF vVlRubrica090932 = 0 THEN

                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,932),
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 10);

                PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                 pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                 pCdRubrica       => PKGPAG_VAR.vgCdRubVlFGTS13,
                                                 pTpProcessamento => 2,
                                                 pTpLocal         => 2);

                vVlRubrica090932 := NVL(PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => vVinc.CdFolhaPagamento,
                                                                       pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                                       pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(
                                                                                            PKGPAG_VAR.vgFolha.CdAgrupamento,9,932)), 0);

             END IF;

          END IF;

          vVlAnoMesFolha := pkgpag_var.vgFolha.NuAnoReferencia*100 + pkgpag_var.vgFolha.NuMesReferencia;
          
              -- 21461/2024 - Tiago Von
          IF FPossuiDecJudPenhora (pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                    pNuAnoReferencia  => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                    pNuMesReferencia  => PKGPAG_VAR.vgFolha.NuMesReferencia,
                                    vIncide13         => vFlIncide13,
                                    vIncideAdiant13   => vFlIncideAdiant13,
                                    pCdRubricaPenhora => vCdRubricaPenhora) THEN

              IF vFlIncide13 = 'S' OR vFlIncideAdiant13 = 'S' THEN
                                            
                 PKGPAG_LF.PPagamentoDecisaoJudicial(PKGPAG_VAR.vgFolha,
                                                     PKGPAG_VAR.vgVinculo.CdVinculo);
                                                             
                 PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                                  PKGPAG_VAR.vgVinculo.CdVinculo,
                                                  vCdRubricaPenhora,
                                                  pTpProcessamento => 1,
                                                  pTpLocal         => 2);
                                                                                                                  
                 PKGPAG_LF.PRegistraPgtPenhora(PKGPAG_VAR.vgFolha,
                                               PKGPAG_VAR.vgVinculo.CdVinculo);                                              
              END IF;   
                                 
           END IF;     

          DELETE
            FROM EPagHistoricoRubricaVinculo HRV
           WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                 HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                 HRV.CdRubricaAgrupamento
                   NOT IN (PKGPAG_VAR.vgCdRubAgrup13,
                           PKGPAG_VAR.vgCdRubricaDevAnt13,
                           PKGPAG_VAR.vgCdRubAgrup13CTISP,
                           vCdRubricaDevAdiant13CTISP,
                           PKGPAG_VAR.vgCdRubBase13Sal,
                           PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                        4,
                                                        1586), -- PENS ALM AD13 -- Falta parametrizar
                           PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                        5,
                                                        586),
                           PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, -- 21461/2024 - Tiago Von
                                                        5,
                                                        893),  
                           PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 
                                                        5,
                                                        883),                                                                                     
                            PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                            5,
                            617),
                            vCdRubrica0968,
                            PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                            5,
                            1623));


          if pkgpag_var.vgFolha.DtInicioMes > to_date(31102023) then

          begin
            select hrv.deexpressao, hrv.vlpagamento
              into vexpressao, vvlbase13
              from EPagHistoricoRubricaVinculo HRV
             WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                   HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                   HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal;

          exception
            when others
              then
                vExpressao := null;

          end;

          end if;

          -----------------------------------------------------------------------------------------------
          -- Processa os lancamentos complementares
          -----------------------------------------------------------------------------------------------

          PProcessaLancComplementar(pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                    pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento);

          -----------------------------------------------------------------------------------------------
          -- Caso o vinculo nao possua proventos exclui a 05-0617
          -----------------------------------------------------------------------------------------------
          IF NVL(PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => vVinc.CdFolhaPagamento,
                                                         pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                         pCdRubrica        => PKGPAG_VAR.vgCdRubAgrup13), 0) <= 0 AND
             NVL(PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => vVinc.CdFolhaPagamento,
                                                         pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                         pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                                                                      5,
                                                                                                                                                      617)), 0) > 0
                                                                                                                                                                          THEN
                DELETE
                FROM EPagHistoricoRubricaVinculo HRV
               WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                     HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                     HRV.CdRubricaAgrupamento
                           IN (PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                5,
                                617));

          END IF;

          -----------------------------------------------------------------------------------------------
          -- Gera totalizadoras e processa formulas de calculo
          -----------------------------------------------------------------------------------------------

          IF PKGPAG_GERAL.FGeraRubricasTotalizadoras(pFolha     => PKGPAG_VAR.vgFolha,
                                                     pCdVinculo => PKGPAG_VAR.vgVinculo.CdVinculo)
             OR PKGPAG_VAR.vgFolha.CdTipoFolha in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13) THEN

             PKGPAG_FB.PProcessaFormulasBases(pFolha          => PKGPAG_VAR.vgFolha,
                                              pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                              pCdRubrica       => PKGPAG_VAR.vgCdRubBaseFGTS13,
                                              pTpProcessamento => 2,
                                              pTpLocal         => 2); /*Vinculo*/

             PKGPAG_FB.PProcessaFormulasBasesTotal(pFolha           => PKGPAG_VAR.vgFolha,
                                                   pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                   pTpProcessamento => 2,
                                                   pTpLocal         => 2); /*Vinculo*/

             -- Utiliza o redutor apenas para recalcular a base do IPREV 13. Após isso, ele deve ser deletado
             DELETE FROM EPagHistoricoRubricaVinculo HRV
                   WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                         HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                         HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                 5,
                                                                                 1623);                                              
             if pkgpag_var.vgFolha.DtInicioMes > to_date(31102023) then
             UPDATE EPagHistoricoRubricaVinculo HRV
                  SET hrv.deexpressao = vexpressao,
                      hrv.vlpagamento = NVL(vVlBase13,0)
                WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                  AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal;
             end if;

             IF vVlIsentoTeto13 > 0 THEN

               UPDATE EPagHistoricoRubricaVinculo HRV
                  SET HRV.VlPagamento = HRV.VlPagamento - vVlIsentoTeto13
                WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                      HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                      HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseTetoGov13;

             END IF;

             IF vVlRubrica090932 > 0 THEN

               PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                     pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                     pCdExpressaoFormCalc  => NULL,
                                                     pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,932),
                                                     pNuSufixoRubrica      => 1,
                                                     pVlPagamento          => vVlRubrica090932,
                                                     pVlIndice             => NULL,
                                                     pCdTipoOrigemRubrica  => 10);

             END IF;

             DELETE
               FROM EPagHistoricoRubricaVinculo HRV
              WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
                    HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                    HRV.VlPagamento = 0 AND
                    HRV.CdRubricaAgrupamento IN (SELECT CdRubricaAgrupamento
                                                   FROM epagRubricaAgrupamento RA
                                                  INNER JOIN EPagRubrica R
                                                     ON RA.CdRubrica = R.CdRubrica
                                                  WHERE R.CdTipoRubrica = 9);

             IF NOT FPossuiDesbloqueioRemun(PKGPAG_VAR.vgVinculo.CdVinculo,
                                            PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                         5,
                                                                         983),
                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                            PKGPAG_VAR.vgFolha.NuMesReferencia) THEN

               PKGPAG_VAR.vgCdRubDescTetoGovernador13 := PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                      5,
                                                                                      984);

               IF NOT PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDescTetoGovernador13,
                                                           pNuSufixoRubrica      => 1) THEN

                 PKGPAG_POS.PDescontoTetoGovernador13(pFolha                => PKGPAG_VAR.vgFolha,
                                                      pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                      pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDescTetoGovernador13);

               ELSE

                 PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                       pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                       pCdExpressaoFormCalc  => NULL,
                                                       pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaTetoGov,
                                                       pNuSufixoRubrica      => 1,
                                                       pVlPagamento          => PKGPAG_POS.RetornaValorRefBloqRemun(
                                                                                                         PKGPAG_VAR.vgVinculo.CdVinculo,
                                                                                                         PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                         PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                                         PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                                                         PKGPAG_VAR.vgFolha.NuMesReferencia),
                                                       pVlIndice             => NULL,
                                                       pCdTipoOrigemRubrica  => 1);

               END IF;

             END IF;

             IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 THEN

                -----------------------------------------------------------------------------------------
                -- Geracao do salario maternidade de 13 salario (apenas para Regime Previdenciario = GERAL (1)
                -----------------------------------------------------------------------------------------

                PGeraSalMaternidade13(pVinculo          => PKGPAG_VAR.vgVinculo,
                                      pFolha            => PKGPAG_VAR.vgFolha);

             END IF;

             if pkgpag_GERAL.FRetornaRegimeProprioPrev(PKGPAG_VAR.vgVinculo.CdVinculo) not in (1,3,4) then

                 delete epaghistoricorubricavinculo hv
                     where hv.cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                       and hv.cdfolhapagamento = pkgpag_var.vgFolha.CdFolhaPagamento
                       and hv.cdrubricaagrupamento in (pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,963),
                                                       pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,9908),
                                                       pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,1925));

             end if;

            if not (PKGPAG_GERAL.fpossuilancfinanceiro(PKGPAG_VAR.vgVinculo.CdVinculo,PKGPAG_VAR.vgFolha,
                                               pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1925)) or
                     PKGPAG_GERAL.fpossuilancfinanceiro(PKGPAG_VAR.vgVinculo.CdVinculo,PKGPAG_VAR.vgFolha,
                                               pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1926)) or
                      PKGPAG_GERAL.fpossuilancfinanceiro(PKGPAG_VAR.vgVinculo.CdVinculo,PKGPAG_VAR.vgFolha,
                                               pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1927)) or
                      PKGPAG_GERAL.fpossuilancfinanceiro(PKGPAG_VAR.vgVinculo.CdVinculo,PKGPAG_VAR.vgFolha,
                                               pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1928))) then

                delete epaghistoricorubricavinculo hv
                     where hv.cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                       and hv.cdfolhapagamento = pkgpag_var.vgFolha.CdFolhaPagamento
                       and hv.cdrubricaagrupamento = pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,9908);

             end if;

             PKGPAG_TRIBUTACAO.PProcessaTributacaoEPensao(pTributacao      => pTributacao,
                                                          pCdPessoa        => PKGPAG_VAR.vgVinculo.CdPessoa,
                                                          pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo);

             --
             -- Solicitacao de Sustentacao #73306
             -- 9532/2016 - CHAMADO - - TOTALIZADOR 09-1005 NO 1506
             --
             IF pkgpag_var.vgfolha.cdorgao = 34 AND pkgpag_var.vgVinculo.CdRegimePrevidenciario <> 1 THEN

                 DELETE
                   FROM EPagHistoricoRubricaVinculo HRV
                  WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                    AND HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                    AND HRV.CdRubricaAgrupamento =  pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,1005);
                    

             END IF;

             IF vCdRubrica0968 > 0 THEN

               DELETE
                 FROM EPagHistoricoRubricaVinculo HRV
                WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                  AND HRV.CdRubricaAgrupamento =  vCdRubrica0968;

              END IF;

          END IF;



       END IF;

        ------------------------------------------------------------------------
        -- Realiza a copia dos dados gerados na folha de antecipacao de 13 para
        -- a folha de 13 salario e demais processamentos
        ------------------------------------------------------------------------

       IF (PKGPAG_VAR.vgFolha.CdTipoFolha in (PKGPAG_TIPO.cnTpFolhaAdiant13,pkgpag_tipo.cnTpFolhaAdiant13Ctisp) AND PKGPAG_VAR.vgCdFolha13 > 0) THEN

          IF PKGPAG_VAR.vgCdFolha13 > 0 THEN
            
              DELETE
                FROM epagHistoricoRubricaVinculo HRV
               WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                     HRV.CdFolhaPagamento = PKGPAG_VAR.vgCdFolha13;

              INSERT
                INTO ePagHistoricoRubricaVinculo
                     (cdhistoricorubricavinculo,
                      cdfolhapagamento,
                      cdrubricaagrupamento,
                      cdvinculo,
                      nusufixorubrica,
                      cdlancamentofinanceiro,
                      vlpagamento,
                      qtparcelas,
                      vlindicerubrica,
                      dtultalteracao,
                      cdvantagempecuniaria,
                      cdrubricatotalizadoravantagem,
                      nuordemcalculo,
                      cdexpressaoformcalc,
                      flvigenciapagamento,
                      cdincorporacaoativo,
                      vlminrecebincorp,
                      flatualizacaoconstante,
                      cdtiporubricaorigem,
                      vlrubricanormal,
                      vlrubricasupl,
                      cdbaseconsignacao,
                      vlpagamentotrunc,
                      cdtipoorigemrubrica,
                      deexpressao)
               SELECT spagHistoricoRubricaVinculo.NEXTVAL,
                      PKGPAG_VAR.vgCdFolha13 ,
                      HRV.cdrubricaagrupamento,
                      HRV.cdvinculo,
                      HRV.nusufixorubrica,
                      HRV.cdlancamentofinanceiro,
                      HRV.vlpagamento,
                      HRV.qtparcelas,
                      HRV.vlindicerubrica,
                      HRV.dtultalteracao,
                      HRV.cdvantagempecuniaria,
                      HRV.cdrubricatotalizadoravantagem,
                      HRV.nuordemcalculo,
                      HRV.cdexpressaoformcalc,
                      HRV.flvigenciapagamento,
                      HRV.cdincorporacaoativo,
                      HRV.vlminrecebincorp,
                      HRV.flatualizacaoconstante,
                      HRV.cdtiporubricaorigem,
                      HRV.vlrubricanormal,
                      HRV.vlrubricasupl,
                      HRV.cdbaseconsignacao,
                      HRV.vlpagamentotrunc,
                      HRV.cdtipoorigemrubrica,
                      HRV.deexpressao
                 FROM ePagHistoricoRubricaVinculo HRV
                WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                      HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                      HRV.VlPagamento > 0;

              PGeraTotalizadoras(pCalculo          => pCalculo,
                                 pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                 pCdFolhaPagamento => PKGPAG_VAR.vgCdFolha13);

           end if;

           IF PKGPAG_VAR.vgVlTotalProventos*0.85 <= PKGPAG_VAR.vgVlTotalDescontos AND
             (PKGPAG_VAR.vgVlTotalProventos > 0 OR PKGPAG_VAR.vgVlTotalDescontos > 0) THEN

              PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                      pCalculo.CdHistoricoParamCalculo,
                                      PKGPAG_VAR.vgVinculo.CdPessoa,
                                      'O valor dos descontos ultrapassam 85% dos proventos.'||
                                      ' Proventos: ' || FFormataNumero(PKGPAG_VAR.vgVlTotalProventos,2,1) || ' - ' ||
                                      ' Descontos: ' || FFormataNumero(PKGPAG_VAR.vgVlTotalDescontos,2,1),
                                      PKGPAG_VAR.vgVinculo.CdVinculo,
                                      2,
                                      10);

              DELETE
                FROM epagHistoricoRubricaVinculo HRV
               WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                     HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento;

          ELSE

            ------------------------------------------------------------------------------------------------
            -- Verifica o valor do teto
            ------------------------------------------------------------------------------------------------

            vVlTeto := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => vVinc.CdFolhaPagamento,
                                                         pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                         pCdRubrica        => PKGPAG_VAR.vgCdRubricaTetoGov);

            --------------------------------------------------------------------------------
            -- Para o SC-Parcerias, o codigo 01-0023 se desdobra em 01-0024 ou 01-0324
            --------------------------------------------------------------------------------

            IF PKGPAG_VAR.vgFolha.CdAgrupamento = 136  THEN

              IF vVlTeto > 0 THEN

               UPDATE epagHistoricoRubricaVinculo HRV
                  SET HRV.CdRubricaAgrupamento =
                          CASE
                            WHEN PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 13 AND PKGPAG_VAR.vgCdRubAgrupAntecip13Alt > 0 THEN
                              PKGPAG_VAR.vgCdRubAgrupAntecip13Alt
                          ELSE
                            PKGPAG_VAR.vgCdRubAgrupAntecip13
                          END,
                      HRV.VlPagamento = (vVlTeto + vVlIsencaoBloqueio)*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13/100
                WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                      HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                      HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13;

              ELSE

                UPDATE epagHistoricoRubricaVinculo HRV
                   SET HRV.CdRubricaAgrupamento =
                          CASE
                              WHEN PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 13 AND PKGPAG_VAR.vgCdRubAgrupAntecip13Alt > 0 THEN
                                PKGPAG_VAR.vgCdRubAgrupAntecip13Alt
                            ELSE
                              PKGPAG_VAR.vgCdRubAgrupAntecip13 -- 1024
                            END,
                       HRV.VlPagamento = HRV.VlPagamento*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13/100
                 WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                       HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                       HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13 ; -- 1023

              END IF;

            ELSE

              --------------------------------------------------------------------------------
              -- Para os demais agrupamentos, baseia-se nos codigos dos eventos 67 e 68
              --------------------------------------------------------------------------------

              -- SIG-6595: DPE - folha Adiantamento 13 salario - Pagar somente o valor do lancamento complementar
              if pkgpag_Var.vgFolha.CdOrgao = 443 and PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubAgrupAntecip13,
                                                                                           pNuSufixoRubrica      => 1) then
               delete epagHistoricoRubricaVinculo HRV
                      WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                            HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                            HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13;

             end if;

              IF vVlTeto > 0 THEN

                  IF PKGPAG_VAR.vgVlTotalProventos*0.85 < vVlTeto
                    AND PKGPAG_VAR.vgFolha.cdorgao = 27
                    AND PKGPAG_TIPO.cnTpFolhaAdiant13 = 5
                    AND PKGPAG_VAR.vgFolha.cdtipocalculo = 1
                    AND vVlAnoMesFolha >= 202211 THEN

                     select 'select '||rtrim(deexpressao) ||' from dual'
                     into VExpressao
                     from epagHistoricoRubricaVinculo HRV
                     WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                             HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                             HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13;

                     execute immediate VExpressao
                     into VexpressaoResultado;

                      UPDATE epagHistoricoRubricaVinculo HRV
                         SET HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrupAntecip13, -- 1-0024
                             HRV.VlPagamento = (VexpressaoResultado+ vVlIsencaoBloqueio)*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13/100
                       WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                             HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                             HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13; -- 1-0023

                     ELSE

                UPDATE epagHistoricoRubricaVinculo HRV
                   SET HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrupAntecip13, -- 1-0024
                       HRV.VlPagamento = (vVlTeto + vVlIsencaoBloqueio)*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13/100
                 WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                       HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                       HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13; -- 1-0023
                      END IF;

              ELSE

                UPDATE epagHistoricoRubricaVinculo HRV
                   SET HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrupAntecip13, -- 1-0024
                       HRV.VlPagamento = HRV.VlPagamento*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13/100
                 WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                       HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                       HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13; -- 1-0023

              END IF;

              UPDATE epagHistoricoRubricaVinculo HRV
                 SET HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrupAntecip13CTISP, -- 1-324
                     HRV.VlPagamento = HRV.VlPagamento*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13/100
               WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                     HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                     HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13CTISP; -- 1-0323

            END IF;

            -- Para folha de adiantamento de 13 do CIASC, desconta valor das pensoes da 1-0024
            IF PKGPAG_VAR.vgFolha.CdAgrupamento = 2 THEN

               PDescontaPensaoDoAdiantamento(pCdFolhaPagamento => vVinc.CdFolhaPagamento);

            END IF;

            -- Exclui pensoes
            PExcluiPensaoFimMes(pCdFolhaPagamento => vVinc.CdFolhaPagamento);

            UPDATE epagHistoricoRubricaVinculo HRV
               SET  HRV.VlPagamento = HRV.VlPagamento*PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13DescPensao/100,
                    HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao,
                    HRV.VlIndiceRubrica = PKGPAG_VAR.vgParamPagamento.VlPercentAdiant13DescPensao
             WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                   HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                   HRV.CdRubricaAgrupamento IN (SELECT RA.CdRubricaAgrupamento
                                                  FROM EPagRubricaAgrupamento RA
                                                 WHERE RA.FlPensaoAlimenticia = 'S');

            DELETE
              FROM epagHistoricoRubricaVinculo HRV
             WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                   HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                   HRV.CdRubricaAgrupamento NOT IN
                     (SELECT RA.CdRubricaAgrupamento
                        FROM EPagRubricaAgrupamento RA
                       INNER JOIN EPagRubrica R
                          ON R.CdRubrica = RA.CdRubrica
                       WHERE RA.FlPensaoAlimenticia = 'S' OR
                             RA.Fl13SalPensao = 'S' OR
                             RA.FlAdiant13Pensao = 'S' OR
                             R.CdTipoRubrica = 1 OR
                             (R.CdTipoRubrica = 5 AND R.NuRubrica IN (524,883,893)))
               AND HRV.CdTipoOrigemRubrica <> 17;

            -----------------------------------------------------------------------
            -- Verifica se existe pensoes vigentes e caso a sentenca nao possua
            -- a rubrica associada ao adiantamento de 13 da pensao, ela e incluida
            -----------------------------------------------------------------------

            /*PKGPAG_TRIBUTACAO.PAssociaRubricaPensao(pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                    pFolha            => PKGPAG_VAR.vgFolha,
                                                    pFlAdiant13Pensao => 'S',
                                                    pFlPensao13       => 'N');
    */
             -- PARA CIASC, NAO GERA PAGAMENTO DE PENSAO NO ADIANTAMENTO DE 13
            IF PKGPAG_VAR.vgFolha.CdAgrupamento = 2 AND
               PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaAdiant13  THEN

                DELETE
                FROM EPagHistoricoRubricaVinculo HRV
                WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                      HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                      HRV.Cdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                5,
                                                                                1586);
            END IF;

            -----------------------------------------------------------------------
            -- Gera as bases de 13 FGTS e Valor FGTS  13
            -----------------------------------------------------------------------

            IF PKGPAG_VAR.vgVinculo.CdRegimeTrabalho = PKGPAG_TIPO.cnRegTrabCLT AND
               PKGPAG_VAR.vgDtOpcaoFGTS IS NOT NULL THEN

              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseFGTS13,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 10);

              PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                               pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                               pCdRubrica       => PKGPAG_VAR.vgCdRubBaseFGTS13,
                                               pTpProcessamento => 2,
                                               pTpLocal         => 2); /*Vinculo*/

              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubVlFGTS13,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 10);

              PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                               pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                               pCdRubrica       => PKGPAG_VAR.vgCdRubVlFGTS13,
                                               pTpProcessamento => 2,
                                               pTpLocal         => 2); /*Vinculo*/

            END IF;

          END IF;

          -- Gera total de proventos/descontos e capa de lote

          PGeraTotalizadoras(pCalculo               => pCalculo,
                             pCdVinculo             => PKGPAG_VAR.vgVinculo.CdVinculo,
                             pCdFolhaPagamento      => vVinc.CdFolhaPagamento,
                             pVlPercentContribIndiv => pTributacao.inss.VlALiquotaContribIndiv);


       ELSE

          ----------------------------------------------------------------------------
          -- Para o SC-Parcerias
          -----------------------------------------------------------------------------

          IF PKGPAG_VAR.vgFolha.CdAgrupamento = 136 THEN

            IF PKGPAG_VAR.vgCdRubAgrup13Alt IS NOT NULL THEN

                 UPDATE ePagHistoricoRubricaVinculo HRV
                       SET HRV.CdRubricaAgrupamento =
                           CASE
                             WHEN PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 13 THEN
                               PKGPAG_VAR.vgCdRubAgrup13Alt
                           ELSE
                              PKGPAG_VAR.vgCdRubAgrup13
                           END
                     WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo AND
                           HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                           HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubAgrup13;

            END IF;

          END IF;

          PExcluiPensaoFimMes(pCdFolhaPagamento => vVinc.CdFolhaPagamento);

          PGeraTotalizadoras(pCalculo               => pCalculo,
                             pCdVinculo             => PKGPAG_VAR.vgVinculo.CdVinculo,
                             pCdFolhaPagamento      => vVinc.CdFolhaPagamento,
                             pVlPercentContribIndiv => pTributacao.inss.VlALiquotaContribIndiv);

          PKGPAG_GERAL.PExcluiValoresZerados(pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
                                             pCdFolhaPagamento => vVinc.CdFolhaPagamento);

          IF PKGPAG_VAR.vgVlTotalProventos = 0 AND PKGPAG_VAR.vgVlTotalDescontos = 0 THEN

            DELETE
              FROM EpagHistoricoRubricaVinculo HRV
             WHERE HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                   HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo;

            DELETE
              FROM Epagcapahistrubricavinculo HRV
             WHERE HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
                   HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo;

          END IF;

       END IF;

       vVlRubrica09_0380 := pkgpag_geral.fretornavalorrubrica(vVinc.CdFolhaPagamento,
                                                PKGPAG_VAR.vgVinculo.CdVinculo,
                                                PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 9, 380));

       vVlRubrica09_1380 := pkgpag_geral.fretornavalorrubrica(vVinc.CdFolhaPagamento,
                                                PKGPAG_VAR.vgVinculo.CdVinculo,
                                                PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 9, 1380));

       IF pkgpag_var.vgFolha.CdOrgao in (25, 27)
         AND (vVlRubrica09_0380 > 0)
         AND (vVlRubrica09_1380 = 0)
         AND (PKGPAG_VAR.vgCEF.COUNT > 0)
         AND (PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho <> 18 /*Jovem Aperendiz*/)
         THEN
           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                 pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 9,1380),
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => 0,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 10);

          PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                           pCdVinculo       => PKGPAG_VAR.vgVinculo.CdVinculo,
                                           pCdRubrica       => PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 9,1380),
                                           pTpProcessamento => 2,
                                           pTpLocal         => 2);
       END IF;

   END IF;

  << LBL_CONTINUE>> NULL;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de execucao da folha Mensal Normal (nao de 13o Salario)
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PProcessarCalculo13Salario(pCalculo                   IN PKGPAG_CAL.rCalculo,
                                     pDtCalculo                 IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                                     pFlDefinitivo              IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                                     pLog                       IN BOOLEAN,
                                     pTrace                     IN BOOLEAN,
                                     pCalculoRetorno           OUT PKGPAG_CAL.rCalculoRetorno) IS

   vCdFolhaPagamentoAnt   INTEGER;
   vCdOrgaoAnt            INTEGER;
   vCdPessoaAnt           INTEGER;
   vTributacao            PKGPAG_TRIBUTACAO.rTributacao;

   vContador              INTEGER;
   vContadorGeral         INTEGER;

   vNuVinculosVigentes    INTEGER DEFAULT 0;

   vTmIni                 INTEGER;
   vTmTot                 INTEGER;

   CURSOR cVinc IS
            SELECT CdFolhaPagamento,
                   MAX(CdOrgaoExercicio) as CdOrgaoFolha,
                   max(CdOrgaoVinculo) as CdOrgao,
                   MAX(CdPessoa) as CdPessoa,
                   MAX(NuSeqMatricula) as NuSeqMatricula,
                   CdVinculo,
                   max(CdRegimeTrabalho) as CdRegimeTrabalho,
                   max(CdRegimePrevidenciario) as CdRegimePrevidenciario,
                   max(DtAdmissao) as DtAdmissao,
                   max(DtDesligamento) as DtDesligamento,
                   max(DtNascimento) as DtNascimento,
                   max(FlSexo) as FlSexo,
                   max(FlContribIndiv) as FlContribIndiv,
                   max(deOrdemExecucao) as DeOrdemExecucao 
             FROM ECalVincFolha
            WHERE CdCalculo = pCalculo.CdCalculo
              and flCalcular = 1 -- cnFlCalcSim

            group by cdfolhapagamento,
                     CdVinculo
            ORDER BY DeOrdemExecucao,
                     cdfolhapagamento,
                     CdOrgaoFolha,
                     Cdpessoa,
                     FlContribIndiv DESC,
                     Nuseqmatricula;
BEGIN
 
  PKGPAG_VAR.vgFaseCalculo := PKGPAG_TIPO.cnFaseCalculoIntegral;

  PKGPAG_VAR.vgCalculo := pCalculo;

  PKGPAG_VAR.vCdPessoa := NULL;

  PKGPAG_GERAL.PLogProcIni ('00','Calculo total');

  -- seta Timer de inicio do calculo da folha ( diferenca de valores / 100 = segundos de duracao)

  vTmIni := DBMS_UTILITY.get_time;

  -- Inicializa dados Ant

  vCdFolhaPagamentoAnt := 0;
  vCdOrgaoAnt          := 0;
  vCdPessoaAnt         := 0;

  vContadorGeral       := 0;

  pCalculoRetorno.CdMensagem      := 0;

  PKGPAG_VAR.vCdHistParamCalc         := pCalculo.CdHistoricoParamCalculo;
  PKGPAG_VAR.bTrace                   := pTrace;
  PKGPAG_VAR.bLog                     := pLog;

  FOR rVinc IN cVinc

  LOOP

    PKGPAG_GERAL.PLogProcIni ('01','Avalia Quebra de Folha');

    -- Testa quebra de orgao. Apos finalizar um orgao, realiza as atualizacoes necessarias

    IF rVinc.CdFolhaPagamento <> vCdFolhaPagamentoAnt
       OR rVinc.CdOrgaoFolha <> vCdOrgaoAnt THEN

      PKGPAG_GERAL.PLogProcIni ('0101','Houve Quebra de Folha');

      -- Processar dados do orgao anterior

      IF vCdOrgaoAnt <> 0 THEN
        PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pQtPessoasCalculadas => vContador);
      END IF;

      if pCalculo.FlGeral <> 'I' THEN -- nao pode comitar na individual, da erro na transacao
        COMMIT;
      END IF;

      vContador            := 0;

      -- Inicializar novo orgao

      -------------------------------------------------------------------------------------------
      -- Caso esteja iniciando o processamento de um orgao, atualiza o status do registro de
      -- parametros do orgao para "Em Andamento".
      -------------------------------------------------------------------------------------------

      IF PKGPAG_TAR.FInterromperProcessamento(pCalculo) THEN

        PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pInStatus => 3 );

        RAISE PKGPAG_VAR.eInterrupCalc;

      END IF;

      PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => rVinc.CdOrgaoFolha, pInStatus => 1);

      PKGPAG_GERAL.PLogProcIni ('010101','Armazena Info Proc');

      PKGPAG_PARAM.PArmazenaInfoProc(rVinc.CdFolhaPagamento,pDtCalculo);

      PKGPAG_GERAL.PLogProcFim ('010101');

      if rVinc.cdfolhapagamento != vCdFolhaPagamentoAnt then
         PKGPAG_GERAL.PLogProcIni('010102','Ins parc faltantes RET/ERA');
         pkgpag_cal.PInsPagamentoLancFaltantes(rVinc.Cdvinculo, pCalculo, pFlDefinitivo);--, pDtInicioMes);
         PKGPAG_GERAL.PLogProcFim('010102');
      end if;

      PKGPAG_GERAL.PLogProcIni ('010103','Inicializacao da Tributacao');
      
      PKGPAG_TRIBUTACAO.PInicializarControle (pTributacao => vTributacao,
                                              pFolha      => PKGPAG_VAR.vgFolha);

      PKGPAG_GERAL.PLogProcFim ('010103');
 
      vCdFolhaPagamentoAnt := rVinc.CdFolhaPagamento;
      vCdOrgaoAnt          := rVinc.CdOrgaoFolha;
      vCdPessoaAnt         := 0; -- Forca quebra de pessoa

      PKGPAG_GERAL.PLogProcFim ('0101');
      
    END IF;

    PKGPAG_GERAL.PLogProc ('01','04','Calculo Pessoas');

    -- Testa se Atualiza estatisticas

    vTmTot := DBMS_UTILITY.get_time - vTmIni;
    if vTmTot >= 3000 THEN -- 30 segundos ou 3000 ms

       ------------------------------------------------------------------------------------------------
       -- Atualiza a quantidade de pessoas calculadas do registro de parametros (no orgao e no geral)
       ------------------------------------------------------------------------------------------------

       PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao =>  rVinc.CdOrgaoFolha, pQtPessoasCalculadas => vContador);
       vContador := 0;

       vTmIni := DBMS_UTILITY.get_time;
    END IF;

     -- Testa se quebrou pessoa do vinculo

    IF vCdPessoaAnt <> rVinc.CdPessoa THEN
      vContador      := vContador + 1;
      vContadorGeral := vContadorGeral + 1;

      -- Verifica o numero de vinculos vigentes para saber se
      -- deve efetuar commit (para evitar problemas de calculo do IRRF)

      PKGPAG_GERAL.PLogProcIni ('0401','Quebrou Pessoa');
      
      PKGPAG_GERAL.PLogProcIni ('040101','Ver Vigentes');

      vNuVinculosVigentes := PKGPAG_GERAL.FVinculosVigentes(rVinc.CdPessoa,
                                                            trunc(pDtCalculo, 'MM'));

      PKGPAG_GERAL.PLogProcFim ('040101');

      IF (MOD(vContadorGeral,100) = 0 OR vNuVinculosVigentes > 1) AND pCalculo.FlGeral <> 'I' THEN

        COMMIT;

        IF PKGPAG_TAR.FInterromperProcessamento(pCalculo) THEN

          PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pInStatus => 3 );

          RAISE PKGPAG_VAR.eInterrupCalc;

        END IF;

      END IF;

      vCdPessoaAnt   := rVinc.CdPessoa;

      -- Apagar calculos anteriores da pessoa

      IF pCalculo.FlGeral in ('I','N') THEN

        PKGPAG_GERAL.PLogProcIni ('040102','Excluir Pag Pessoa');

        PKGPAG_GERAL.PExcluirPagPessoa(rVinc.CdFolhaPagamento,
                                       rVinc.CdPessoa);

        PKGPAG_GERAL.PLogProcFim ('040102');

      END IF;
   
      PKGPAG_GERAL.PLogProcFim ('0401');

    END IF;

    PKGPAG_GERAL.PLogProcIni ('0403','Processar Vinculo');
    
    BEGIN

       PProcessarVinculo13Salario (pCalculo                => pCalculo,
                                   pRegVinc                => rVinc,
                                   pDtCalculo              => pDtCalculo,
                                   pTributacao             => vTributacao);

       -- Tratamento de Exceptions que devem continuar o processamento
       EXCEPTION

         WHEN OTHERS THEN

           pCalculoRetorno.CdMensagem := 1;

           pCalculoRetorno.DeParametros :=  '';

           PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                   pCalculo.CdHistoricoParamCalculo,
                                   rVinc.CdPessoa,
                                   '** Alerta: PProcessarCalculo13Salario: ' || SQLERRM,
                                   rVinc.CdVinculo);
           -- RAISE; -- Faz com que o erro suba para procedimento chamador e interrompe processamento

    END;
    
    PKGPAG_GERAL.PLogProcFim ('0403');

    PKGPAG_GERAL.PLogProcFim ('04');
    
  END LOOP;

  -- Processa quebras

  IF vCdOrgaoAnt <> 0 THEN

     PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pQtPessoasCalculadas => vContador);
     vContador            := 0;

  END IF;

  IF pCalculo.FlGeral <> 'I' THEN
     COMMIT;
  END IF;

  PKGPAG_GERAL.PLogProcFim ('00');
  
---------------------------------------------------------------------------------------------
-- Erro fatal : interrompe a execucao
---------------------------------------------------------------------------------------------

EXCEPTION

  WHEN PKGPAG_VAR.eRubTetoInexistente THEN

    pCalculoRetorno.CdMensagem := 2561;

    pCalculoRetorno.DeParametros :=  '';

  WHEN PKGPAG_VAR.eFolhaEmExecucao THEN

    pCalculoRetorno.CdMensagem := 2649;

    pCalculoRetorno.DeParametros :=  '';

  WHEN PKGPAG_VAR.eDependenciaFormula THEN

   IF pCalculo.CdHistoricoParamCalculo = 0 THEN

     pCalculoRetorno.CdMensagem := 2164;

     pCalculoRetorno.DeParametros :=  '';

   ELSE

     RAISE PKGPAG_VAR.eDependenciaFormula;

   END IF;

  WHEN PKGPAG_VAR.eChaveDuplicada THEN

    IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2164;

      pCalculoRetorno.DeParametros :=  '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Chave duplicada ao executar folha suplementar.',
                              PKGPAG_VAR.vgCdVinculo);

    ELSE

     RAISE PKGPAG_VAR.eChaveDuplicada;

    END IF;

  WHEN PKGPAG_VAR.eSemBaseIRRF THEN

  --  IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2430;

      pCalculoRetorno.DeParametros :=  '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Não foi encontrada a rubrica referente à base do IRRF. Folha não calculada.',
                              PKGPAG_VAR.vgCdVinculo);

  --  ELSE

  --    RAISE PKGPAG_VAR.eSemBaseIRRF;

  --  END IF;

  WHEN PKGPAG_VAR.eSemBaseIRRFFerias THEN

  --  IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2431;

      pCalculoRetorno.DeParametros :=  '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Não foi encontrada a rubrica referente à base do IRRF de férias. Folha não calculada.',
                              PKGPAG_VAR.vgCdVinculo);

   --  ELSE

       RAISE PKGPAG_VAR.eSemBaseIRRFFerias;

   --  END IF;

  WHEN PKGPAG_VAR.eSemBaseIRRF13 THEN

  -- IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2432;

      pCalculoRetorno.DeParametros :=  '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Não foi encontrada a rubrica referente à base do IRRF de 13º. Folha não calculada.',
                              PKGPAG_VAR.vgCdVinculo);

   -- ELSE

   --   RAISE PKGPAG_VAR.eSemBaseIRRF13;

   -- END IF;

  WHEN PKGPAG_VAR.eNaoRodaFolhaNormal THEN

    IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2471;

      pCalculoRetorno.DeParametros :=  '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Não é permitido executar folha normal/calculo normal temporariamente.',
                              PKGPAG_VAR.vgCdVinculo);

    END IF;

  WHEN OTHERS THEN

    pCalculoRetorno.CdMensagem := 1;

    pCalculoRetorno.DeParametros :=  '';

    PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                            pCalculo.CdHistoricoParamCalculo,
                            PKGPAG_VAR.vCdPessoa,
                            SQLERRM,
                            PKGPAG_VAR.vgCdVinculo);

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de execucao da folha Mensal Normal via JOB
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PProcessarCalculo13Salario (pCdJobId IN VARCHAR2, pCdCalculo  IN INTEGER) IS

   vCalculo                   PKGPAG_CAL.rCalculo;
   vDtCalculo                 EPagHistoricoParamCalculo.DtCalculo%TYPE;
   vCdTipoCalculo             EPagHistoricoParamCalculo.CdTipoCalculo%TYPE;
   vFlDefinitivo              EPagHistoricoParamCalculo.FlDefinitivo%TYPE;
   vLog                       CHAR(1);
   vTrace                     CHAR(1);
   vLogb                      BOOLEAN;
   vTraceb                    BOOLEAN;
   vCalculoRetorno            PKGPAG_CAL.rCalculoRetorno;

BEGIN

  SELECT
      CdCalculo,
      CdCalculoPai,
      CdTarefa,
      CdHistoricoParamCalculo,
      FlGeral,
      InTipoExecucao,
      DtCalculo,
      CdTipoCalculo,
      FlDefinitivo,
      FlLog,
      FlTrace
   into
       vCalculo.CdCalculo,
       vCalculo.CdCalculoPai,
       vCalculo.CdTarefa,
       vCalculo.CdHistoricoParamCalculo,
       vCalculo.FlGeral,
       vCalculo.InTipoExecucao,
       vDtCalculo,
       vCdTipoCalculo,
       vFlDefinitivo,
       vLog,
       vTrace
   from ECalCalculo where cdCalculo = pCdCalculo;

   vLogb   := FALSE;
   vTraceb := FALSE;
   if vLog = 'S' then
      vLogb := true;
   end if;

   if vTrace = 'S' then
      vTraceb := true;
   end if;

   BEGIN

     PProcessarCalculo13Salario (vCalculo,
                                 vDtCalculo,
                                 vFlDefinitivo,
                                 vLogb,
                                 vTraceb,
                                 vCalculoRetorno);

   EXCEPTION

      WHEN OTHERS THEN

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                vCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vCdPessoa,
                                '** Erro (PProcessar13Salario-Paralelo): ' || SQLERRM,
                                PKGPAG_VAR.vgCdVinculo);

   END;

   PKGPAG_TAR.PFinalizarJob (pCdJobId,vCalculoRetorno.DeParametros);

 END;

END PKGPAG_DT;
/
