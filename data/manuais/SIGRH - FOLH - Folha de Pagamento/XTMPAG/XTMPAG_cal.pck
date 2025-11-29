CREATE OR REPLACE PACKAGE XTMPAG_CAL IS

  /*-----------------------------------------------------------------------------------------/
      Constantes e Tipos
  /*-----------------------------------------------------------------------------------------*/

  TYPE rCalculo IS RECORD(
    CdCalculo               INTEGER,
    CdCalculoPai            INTEGER,
    CdTarefa                INTEGER,
    CdHistoricoParamCalculo INTEGER,
    FlGeral                 CHAR,
    InTipoExecucao          INTEGER);

  TYPE rCalculoRetorno IS RECORD(
    CdMensagem   INTEGER,
    DeParametros VARCHAR2(200));

  TYPE rVinc IS RECORD(
    CdFolhaPagamento         INTEGER,
    CdOrgaoFolha             INTEGER,
    CdOrgao                  INTEGER,
    CdPessoa                 INTEGER,
    NuSeqMatricula           INTEGER,
    CdVinculo                INTEGER,
    CdSituacaoPrevidenciaria NUMBER,
    CdRegimeTrabalho         INTEGER,
    CdRegimePrevidenciario   INTEGER,
    DtAdmissao               DATE,
    DtDesligamento           DATE,
    DtNascimento             DATE,
    DtInclusao               DATE,
    FlSexo                   CHAR(1),
    CdOpcaoAuxilioAli        INTEGER,
    FlPossuiObito            INTEGER,
    FlOutroVincCalculado     CHAR(1),
    FlOutroVincACalcular     CHAR(1));

  FUNCTION FAfastSemRemun(pCdVinculo IN INTEGER,
                          pDtInicio  IN DATE,
                          pDtFim     IN DATE,
                          pdtCalculo IN DATE) RETURN XTMPAG_TIPO.rMotAfast;

  FUNCTION FAfastamentoVinculo(pCdVinculo          IN INTEGER,
                               pDtInicio           IN DATE,
                               pDtFim              IN DATE,
                               pdtCalculo          IN DATE,
                               pTipoAfa            IN CHAR,
                               pCdHistCargoEfetivo IN INTEGER DEFAULT NULL,
                               pDtCalculoAnt       IN DATE DEFAULT NULL,
                               pAuxAlim            IN CHAR DEFAULT 'N') -- R-Temporario Remunerado | N-temporario nao remunerado | D-Definitivo | V-Relacao de vinculo
   RETURN XTMPAG_TIPO.tAfastamento;

   FUNCTION fpossuipagamentomediaferias(pcdvinculo       INTEGER,
                                        pdtiniciofruicao DATE,
                                        pcdorgao         INTEGER,
                                        pcdagrupamento   INTEGER)

  RETURN BOOLEAN;

  FUNCTION FTrataImpeditivas(pCdFolhaPagamento     IN INTEGER,
                             pCdVinculo            IN INTEGER,
                             pCdRubricaAgrupamento IN INTEGER,
                             pFlTotalizadora       IN CHAR)

  RETURN BOOLEAN;

  PROCEDURE PAnulaAfastTempNaoRemun(pCdVinculo IN INTEGER,
                                                            pDtCalculo IN DATE,
                                                            pcdAgrupamento IN INTEGER);


  PROCEDURE PProcessarCalculoNormal(pCalculo                 IN rCalculo,
                                    pDtCalculo               IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                                    pFlDefinitivo            IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                                    pFlPagaAdiantamento13sal IN EPagHistoricoParamCalculo.FlPagaAdiantamento13sal%TYPE,
                                    pVlDiferencaValor        IN EPagHistoricoParamcalculo.vlDiferencaValor%TYPE,
                                    pLog                     IN BOOLEAN,
                                    pTrace                   IN BOOLEAN,
                                    pCalculoRetorno          OUT rCalculoRetorno,
                                    pParalelo                in char default null);

PROCEDURE PProcessarCalculoDuploVinculo(pCalculo                   IN XTMPAG_CAL.rCalculo,
                                     pDtCalculo                 IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                                     pFlDefinitivo              IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                                     pLog                       IN BOOLEAN,
                                     pTrace                     IN BOOLEAN,
                                     pCalculoRetorno            OUT XTMPAG_CAL.rCalculoRetorno);

PROCEDURE PProcessarCalculoDuploVinculo (pCdJobId IN VARCHAR2, pCdCalculo  IN INTEGER);

 procedure pAtualizaValorRubrica (pCdVinculo in integer,
                                  pCdFolhaPagamento in integer,
                                  pCdRubricaAgrupamento in integer,
                                  pValorRubrica in XTMPAG_tipo.rValorPagamento,
                                  pCdRelacaoVinculo in integer default null,
                                  pCdOutraRubrica in integer default null,
                                  pDeFormula in char default null,
                                  pIncluiRelVinc in char default 'N');

  PROCEDURE PProcessaFolhaSuplementar(pFolhaSuplementar    IN XTMPAG_TIPO.rFolha,
                                      pFolhaOrigem         IN XTMPAG_TIPO.rFolha,
                                      pFolhaRecalculo      IN XTMPAG_TIPO.rFolha,
                                      pCdVinculo           IN INTEGER,
                                      pFlCalculoDefinitivo IN CHAR,
                                      pVlDiferencaValor    IN NUMBER DEFAULT 0,
                                      pCdFolhaPagou        IN INTEGER DEFAULT 0);

  FUNCTION FRetornaFolhaComPagamento(pCdVinculo            IN INTEGER,
                                     pNuAnoReferencia      IN INTEGER,
                                     pNuMesReferencia      IN INTEGER,
                                     pCdTipoFolhaPagamento IN INTEGER,
                                     pCdTipoCalculo        IN INTEGER,
                                     pCdFolhaOrigem        IN INTEGER)
    RETURN INTEGER;

  PROCEDURE PProcessarCalculoNormal(pCdJobId   IN VARCHAR2,
                                    pCdCalculo IN INTEGER);

  procedure PInsPagamentoLancFaltantes (pcdvinculo IN integer, pCalculo IN rCalculo, pFlDefinitivo IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE DEFAULT 'N');

  PROCEDURE PZerarValorPgtoCopPlanoSaude(pCdVinculo       IN INTEGER,
                                         pNuAnoReferencia IN INTEGER,
                                         pNuMesReferencia IN INTEGER);

  FUNCTION FObterUltimaDataCalculo(pDataReferencia      IN DATE,
                                   pCdOrgao             IN INTEGER,
                                   pCdTipoFolha         IN INTEGER,
                                   pCdTipoCalculo       IN INTEGER,
                                   pFlCalculoDefinitivo IN CHAR) RETURN DATE;

  PROCEDURE PExcluirRubricasCLT(pCdVinculo        IN INTEGER,
                                pCdFolhaPagamento IN INTEGER,
                                pCdAgrupamento    IN INTEGER);

  PROCEDURE PAjustarContrachequeCCO(pCdVinculo            IN INTEGER,
                                   pCdAgrupamento        IN INTEGER,
                                   pCdOrgao              IN INTEGER,
                                   pCdFolhaPagamento     IN INTEGER,
                                   pCdTipoFolhaPagamento IN INTEGER,
                                   pDataInicioMes        IN DATE,
                                   pDataFimMes           IN DATE,
                                   pDataCalculo          IN DATE);

END XTMPAG_CAL;
/
CREATE OR REPLACE PACKAGE BODY XTMPAG_CAL IS

  TYPE rTabFolhaPagamentoDifMes IS RECORD(
    CdFolhaDifMes INTEGER,
    DtCalculo     DATE);

  TYPE tTabFolhaPagamentoDifMes IS TABLE OF rTabFolhaPagamentoDifMes INDEX BY PLS_INTEGER;

  TYPE tFalta is VARRAY(12) of NUMBER;

  --vFalta tFalta;

  vgTabCdFolhaPagamentoDifMes tTabFolhaPagamentoDifMes;

  --vvlCalculado XTMPAG_tipo.rvalorpagamento;

  --vVlIndice NUMBER(10,4);

  vVlMargemErario NUMBER(13,2);

  --vvlCalculadoBaseErario XTMPAG_tipo.rvalorpagamento;

  vvlCalculadoRubrica XTMPAG_tipo.rvalorpagamento;

  vVlRubrica number(13,2);

  vDeFormula epagformulacalculo.deformulacalculo%type;

  vVlRubrica010201 number(13,2);

  vvgPercentATS XTMPAG_tipo.tPercentATS;
  --vHistRubRelVinc epaghistoricorubricarelvinc%rowtype;

  vCdFolha13Definitiva integer;

  FUNCTION FRetornaOpcaoRemuneracaoCCO(pCdHistCargoCom IN INTEGER,
                                       pDtInicioMes    IN DATE,
                                       pDtFimMes       IN DATE)

   RETURN INTEGER IS

    vCdOpcaoRemuneracao INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT NVL(CdOpcaoRemuneracao, 0)
      INTO vCdOpcaoRemuneracao
      FROM (SELECT HRC.CdOpcaoRemuneracao
              FROM ECadHistOpcaoRemuneracaoCCO HRC
             WHERE HRC.CdHistCargoCom = pCdHistCargoCom
               AND HRC.DtInicioVigencia <= pDtFimMes
               AND (HRC.DtFimVigencia >= pDtInicioMes OR
                   HRC.DtFimVigencia IS NULL)
             ORDER BY HRC.DtInicioVigencia DESC)
     WHERE ROWNUM < 2;

    RETURN vCdOpcaoRemuneracao;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN NULL;

  END;

Function fFolha13MesAnt (pCdFolhaNormalAnt IN INTEGER)
  return integer is

  vCdFolha13Ant integer;

  begin
    -- xtmpag_util.pGravaLogCallStack;

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
       and tfp.cdtipofolha = XTMPAG_tipo.cnTpFolha13;

    return vCdFolha13Ant;

    exception
      when no_data_found
        then return 0;
      when others
        then return 0;

end;

FUNCTION FPossuiFolhaDefAnterior(pCdVinculo IN INTEGER,
                           pDtInclusao  IN DATE) RETURN BOOLEAN IS

  vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

     -- OBS.: Voltei a query, porem o Victor aplicou um baseline pra melhoria de performance.
     -- A query estava muito pesada e melhorou bastante.
     -- Se for feita qualquer alteracao na query, é necessario informa-lo.
     select /*+ index (RV IDX1EPAGHISTORICORUBRICAVINCUL FP PKEPAGFOLHAPAGAMENTO) */
            count(fp.cdfolhapagamento)
      into vCont
      from epaghistoricorubricavinculo rv
     inner join epagfolhapagamento fp
        on rv.cdfolhapagamento = fp.cdfolhapagamento
       and fp.flcalculodefinitivo = 'S'
     where rv.cdvinculo = pCdVinculo
       and fp.dtcalculo < pDtInclusao
       and ((to_char(fp.dtcalculo,'YYYY') = XTMPAG_var.vgFolha.NuAnoReferencia and XTMPAG_var.vgFolha.NuMesReferencia > 1) or
           (XTMPAG_var.vgFolha.NuMesReferencia = 1 and fp.Nuanoreferencia = XTMPAG_var.vgFolha.NuAnoReferencia - 1 and
            fp.Numesreferencia = 12))
       and rownum <= 1;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

  END;

  FUNCTION FPossuiDisposicao(pCdVinculo IN INTEGER,
                             pDtInicio  IN DATE,
                             pDtFim     IN DATE) RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT 1
      INTO vCont
      FROM ECadHistCargoEfetivo HCE
     WHERE HCE.CdVinculo = pCdVinculo
       AND HCE.CdRelacaotrabalho = XTMPAG_TIPO.cnRelTrabDisposicao
       AND (HCE.DtInicio <= pDtFim AND
           (HCE.DtFim >= pDtInicio OR HCE.DtFim IS NULL))
       AND HCE.FlAnulado = XTMPAG_TIPO.cnN
       AND ROWNUM < 2;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

  END;

  FUNCTION FPossuiVinculoCCO(pCdVinculo IN INTEGER,
                             pCdOrgao   IN INTEGER,
                             pDtInicio  IN DATE,
                             pDtFim     IN DATE) RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT 1
      INTO vCont
      FROM ECadHistCargoCom HCC
     WHERE HCC.CdVinculo = pCdVinculo
       AND HCC.CdOrgaoExercicio = pCdOrgao
       AND HCC.CdCargoComRemuneracao IS NULL
       AND (HCC.DtInicio <= pDtFim AND
           (HCC.DtFim >= pDtInicio OR HCC.DtFim IS NULL))
       AND HCC.Flanulado = XTMPAG_TIPO.cnN
       AND ROWNUM < 2;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

  END;

  -- Verifica se possui comissionado em outro orgao e com provimento no destino e nao gera calculo no orgao de origem
  FUNCTION FPossuiVinculoCCOProvDestino(pCdVinculo IN INTEGER,
                                        pCdOrgao   IN INTEGER,
                                        pDtCalculo IN DATE,
                                        pDtFim     IN DATE) RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    -- Folhas Prodex e Honorarios GERA
    if XTMPAG_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766) then
       return false;
    end if;
    -- Ajuste emergencial data do calculo
    -- SIG-10093 Servidor SAP sem folha
    SELECT sum(1)
      INTO vCont
      FROM ECadHistCargoCom HCC
     WHERE HCC.CdVinculo = pCdVinculo
       AND HCC.CdOrgaoExercicio <> pCdOrgao
       AND HCC.CdCargoComRemuneracao IS NULL
       AND (HCC.DtInicio <= pDtCalculo AND
           (HCC.DtFim >= pDtCalculo OR HCC.DtFim IS NULL))
       AND HCC.Flanulado = XTMPAG_TIPO.cnN
       AND HCC.Fltipoprovimento in ('D','N')
       and not exists (select 1 from ecadhistcargoefetivo cef
                        where cef.cdvinculo = pCdVinculo
                          and cef.dtinicio > hcc.dtfim
                          and cef.dtinicio <= pDtFim
                          and cef.cdorgaoexercicio = pCdOrgao
                          and cef.flanulado = 'N');

    IF vCont > 0 THEN

       XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                               XTMPAG_VAR.vCdHistParamCalc,
                               XTMPAG_VAR.vCdPessoa,
                               'Comissionado em outro orgao, nao processa orgao origem! ' || pCdOrgao,
                               XTMPAG_VAR.vgCdVinculo);


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

  FUNCTION FPossuiDescAdiantamento13(pCdVinculo    IN INTEGER,
                             pcdrubricaagrupamento IN INTEGER,
                             pNuAno                IN INTEGER,
                             pNuMes                IN INTEGER) RETURN NUMBER IS

    vvlPagamento NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    select sum(hrv.vlpagamento)
      into vvlPagamento
      from epagfolhapagamento fp
     inner join ecadorgao o
        on o.cdorgao = fp.cdorgao
     inner join epagtipofolhapagamento tfp
        on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
     inner join epaghistoricorubricavinculo hrv
        on hrv.cdfolhapagamento = fp.cdfolhapagamento
     where fp.nuanoreferencia = pNuAno
       and fp.numesreferencia <> pNuMes
       and fp.flcalculodefinitivo = 'S'
       and hrv.cdvinculo = pCdVinculo
       and hrv.cdrubricaagrupamento = pcdrubricaagrupamento
       and fp.cdtipocalculo = 1;

    RETURN nvl(vvlPagamento,0);

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;

  END;

  FUNCTION FPesquisaBolsaNaoRemunerada(PCDVINCULO IN INTEGER,
                                       PDTCALCULO IN DATE,
                                       PDTINICIO  IN DATE) RETURN BOOLEAN IS

    vFlRemunerado CHAR;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

SELECT FLREMUNERADO
  INTO vFlRemunerado
  FROM (SELECT
      BOLAA3.FLREMUNERADO
  FROM ECADHISTESTAGIO CAD192
 INNER JOIN ECADVINCULO CADA39
    ON CADA39.CDVINCULO = CAD192.CDVINCULOESTAGIO
 INNER JOIN EBOLHISTPROGRAMA BOLAA3
    ON BOLAA3.CDPROGRAMA = CAD192.CDPROGRAMA
   AND BOLAA3.DTINICIOVIGENCIA =
       (SELECT MAX(A.DTINICIOVIGENCIA)
          FROM EBOLHISTPROGRAMA A
         WHERE A.CDPROGRAMA = BOLAA3.CDPROGRAMA)
  WHERE CADA39.CDVINCULO = PCDVINCULO
           AND CAD192.DTINICIO <= PDTCALCULO
           AND (CAD192.DTFIM IS NULL OR CAD192.DTFIM >= PDTINICIO
           AND ROWNUM < 2));

/*SELECT VLBOLSA, VLBOLSAPNE, FLOCUPAVAGAPNE
  INTO vValorBolsa, vValorBolsaPNE, vOcupaVagaPNE
  FROM (SELECT NVL(PNF.VLBOLSATRABALHO, NVL(BOLAA3.VLBOLSA, 0)) AS VLBOLSA,
               --NVL(BOLAA3.VLBOLSA, 0),
               NVL(PNF.VLBOLSATRABALHOPNE, NVL(BOLAA3.VLBOLSAPNE, 0)) AS VLBOLSAPNE,
               --NVL(BOLAA3.VLBOLSAPNE, 0),
               CAD192.FLOCUPAVAGAPNE
          FROM ECADHISTESTAGIO CAD192
         INNER JOIN ECADVINCULO CADA39
            ON CADA39.CDVINCULO = CAD192.CDVINCULOESTAGIO
         INNER JOIN EBOLHISTPROGRAMA BOLAA3
            ON BOLAA3.CDPROGRAMA = CAD192.CDPROGRAMA
           AND BOLAA3.DTINICIOVIGENCIA =
               (SELECT MAX(A.DTINICIOVIGENCIA)
                  FROM EBOLHISTPROGRAMA A
                 WHERE A.CDPROGRAMA = BOLAA3.CDPROGRAMA)

          LEFT JOIN EBOLPROGRAMANIVELFORMACAO PNF
            ON PNF.CDHISTPROGRAMA = BOLAA3.CDHISTPROGRAMA
          INNER JOIN ECADNIVELFORMGRAUESC NF
            ON PNF.CDNIVELFORMGRAUESC = NF.CDNIVELFORMGRAUESC
           AND NF.CDGRAUESCOLARIDADE = CAD192.CDGRAUESCOLARIDADE
           AND NF.CDNIVELFORMACAO = CAD192.CDNIVELFORMACAO

         WHERE CADA39.CDVINCULO = PCDVINCULO
           AND CAD192.DTINICIO <= PDTCALCULO
           AND (CAD192.DTFIM IS NULL OR CAD192.DTFIM >= PDTINICIO
           AND ROWNUM < 2));*/

    --IF (vOcupaVagaPNE = 'S' AND vValorBolsaPNE = 0) OR vValorBolsa = 0 THEN

    IF vFlRemunerado = 'N' THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;

  END;

  FUNCTION FRetornaFolhaComPagamento(pCdVinculo            IN INTEGER,
                                     pNuAnoReferencia      IN INTEGER,
                                     pNuMesReferencia      IN INTEGER,
                                     pCdTipoFolhaPagamento IN INTEGER,
                                     pCdTipoCalculo        IN INTEGER,
                                     pCdFolhaOrigem        IN INTEGER)
    RETURN INTEGER IS

    vCdFolhaPagamento INTEGER;

    vCdFolhaRecalculo INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF XTMPAG_VAR.bPossuiFolhaSuplDef THEN

      BEGIN

        SELECT CdFolhaPagamento
          INTO vCdFolhaPagamento
          FROM (SELECT HRV.CdFolhaPagamento
                  FROM EPagHistoricoRubricaVinculo HRV
                 INNER JOIN EPagFolhaPagamento FP
                    ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
                 WHERE FP.NuAnoReferencia = pNuAnoReferencia
                   AND FP.NuMesReferencia = pNuMesReferencia
                   AND FP.CdTipoFolhaPagamento = pCdTipoFolhaPagamento
                   AND FP.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoSupl
                   AND FP.FlCalculoDefinitivo = XTMPAG_TIPO.cnS
                   AND HRV.CdVinculo = pCdVinculo
                 ORDER BY FP.DtCalculo DESC)
         WHERE ROWNUM < 2;

        -- Busca o codigo do recalculo

        SELECT FP.CdFolhaVincSupl
          INTO vCdFolhaRecalculo
          FROM EPagFolhaPagamento FP
         WHERE FP.CdFolhaPagamento = vCdFolhaPagamento;

        RETURN vCdFolhaRecalculo;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          NULL;

      END;

    END IF;

    SELECT HRV.CdFolhaPagamento
      INTO vCdFolhaPagamento
      FROM EpagHistoricoRubricaVinculo HRV
     INNER JOIN EPagFolhaPagamento FP
        ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
     WHERE HRV.CdVinculo = pCdVinculo
       AND HRV.CdFolhaPagamento = pCdFolhaOrigem
       AND ROWNUM < 2;

    RETURN vCdFolhaPagamento;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      BEGIN

        SELECT HRV.CdFolhaPagamento
          INTO vCdFolhaPagamento
          FROM EpagHistoricoRubricaVinculo HRV
         INNER JOIN EPagFolhaPagamento FP
            ON FP.CdFolhaPagamento = HRV.CdFolhaPagamento
         WHERE FP.NuAnoReferencia = pNuAnoReferencia
           AND FP.NuMesReferencia = pNuMesReferencia
           AND FP.CdTipoFolhaPagamento = pCdTipoFolhaPagamento
           AND FP.CdTipoCalculo = pCdTipoCalculo
           AND FP.FlCalculoDefinitivo = 'S'
           AND HRV.CdVinculo = pCdVinculo
           AND ROWNUM < 2;

        RETURN vCdFolhaPagamento;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          RETURN pCdFolhaOrigem;

      END;

  END;

  /*-----------------------------------------------------------------
    Function: FAfastSemRemun

    Objetivo: Verificar se o vinculo possui um afastamento nao
              remunerado durante todo o mes da folha. Caso seja
              verdade, o vinculo nao sera calculado.

        Nota:

        - Retorna

           (0) Nao afastado
           (1) Afastamento temporario (e chave do motivo) o mes todo
           (2) Afastamento definitivo (e chave do motivo) o mes todo
           (3) Afastamento temporario parcial no mes

  /*----------------------------------------------------------------*/

  FUNCTION FAfastSemRemun(pCdVinculo IN INTEGER,
                          pDtInicio  IN DATE,
                          pDtFim     IN DATE,
                          pdtCalculo IN DATE) RETURN XTMPAG_TIPO.rMotAfast IS

    vMotivoAfastamento XTMPAG_TIPO.rMotAfast;

    vNuDiasAfast INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vMotivoAfastamento.InAfastado := XTMPAG_TIPO.cnAfastadoNao;

    vMotivoAfastamento.InTipoAfastamento := ' ';

    vMotivoAfastamento.InPagaLancamento := 'N';

    vMotivoAfastamento.CdChaveMotivo := NULL;

    vMotivoAfastamento.DtInclusao := NULL;

    vMotivoAfastamento.DtInicio := NULL;

    vMotivoAfastamento.FlAuxilioDoenca := NULL;

    vMotivoAfastamento.FlAcidenteTrabalho := NULL;

    vMotivoAfastamento.FlProcessaNaoPaga := NULL;

    IF XTMPAG_var.vgFolha.cdtipofolha = XTMPAG_tipo.cnTpFolhaInstPensao THEN
      RETURN vMotivoAfastamento;
    END IF;

    ---------------------------------------------------------------------------
    -- Alteracao: 07/06
    -- E verificado se o numero de dias afastados por motivo temporario
    -- e igual ao numero de dias do mes
    ---------------------------------------------------------------------------

    SELECT nvl(count(DISTINCT DtDiaAfastado), 0) AS NuDiaAfast
      INTO vNuDiasAfast
      FROM (SELECT CdVinculo, dtDia AS DtDiaAfastado, 1 AS DiaAfastado
              FROM (SELECT pdtInicio + (LEVEL - 1) AS dtdia
                      FROM dual
                    CONNECT BY pdtInicio + (LEVEL - 1) BETWEEN pdtInicio AND
                               pdtFim) D
             INNER JOIN (SELECT cdVinculo,
                               CASE
                                 WHEN AV.dtInicio < pdtInicio THEN
                                  pdtInicio
                                 ELSE
                                  AV.Dtinicio
                               END AS dtInicio,
                               CASE
                                 WHEN (AV.dtFim > pdtFim OR AV.DtFim IS NULL) THEN
                                  pdtFim
                                 ELSE
                                  AV.dtFim
                               END AS dtFim
                          FROM EAfaAfastamentoVinculo AV
                         INNER JOIN EAfaMotivoAfastTemporario MAT
                            ON AV.CdMotivoAfastTemporario =
                               MAT.CdMotivoAfastTemporario
                         INNER JOIN EAfaHistMotivoAfastTemp HMAT
                            ON MAT.CdMotivoAfastTemporario =
                               HMAT.CdMotivoAfastTemporario
                         WHERE AV.CdVinculo = pCdVinculo
                           AND HMAT.FlRemunerado = XTMPAG_TIPO.cnN
                           AND AV.DtInicio <= pdtFim
                           AND (AV.DtFim >= pdtInicio OR AV.DtFim IS NULL)
                           AND HMAT.DtInicioVigencia <= pdtCalculo
                           AND (HMAT.DtFimVigencia >= pdtCalculo OR
                               HMAT.DtFimVigencia IS NULL)
                           AND HMAT.FlAnulado = XTMPAG_TIPO.cnN
                           AND AV.FlAnulado = XTMPAG_TIPO.cnN) B
                ON (B.DtInicio <= D.DtDia)
               AND (B.DtFim >= D.DtDia)) A;

    --
    -- Caso o numero de dias afastados por motivo temporario
    -- seja igual ao numero de dias do mes.
    --
    -- 6660/2014 - FOLHA - PROBLEMAS FOLHA FCEE  em 05/12/2014
    -- Se o numero de dias afastados e igual a data de desligamento do vinculo
    --
    IF vNuDiasAfast = TO_CHAR(pdtFim, 'DD') OR
        (XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = XTMPAG_TIPO.cnRelACT AND
        TO_CHAR(XTMPAG_VAR.vgVinculo.DtDesligamento, 'DD') = vNuDiasAfast AND
        TO_CHAR(pDtFim, 'MMYYYY') =
        TO_CHAR(XTMPAG_VAR.vgVinculo.DtDesligamento, 'MMYYYY'))

     THEN

      vMotivoAfastamento.InAfastado := XTMPAG_TIPO.cnAfastadoMesTodo;

      SELECT 'T',
             MAT.CdMotivoAfastTemporario,
             AV.DtInclusao,
             HMAT.Flauxiliodoenca,
             HMAT.Flacidentetrabalho,
             HMAT.Flprocessanaopaga,
             AV.DtInicio
        INTO vMotivoAfastamento.InTipoAfastamento,
             vMotivoAfastamento.CdChaveMotivo,
             vMotivoAfastamento.DtInclusao,
             vMotivoAfastamento.FlAuxilioDoenca,
             vMotivoAfastamento.FlAcidenteTrabalho,
             vMotivoAfastamento.FlProcessaNaoPaga,
             vMotivoAfastamento.DtInicio
        FROM Eafaafastamentovinculo AV
       INNER JOIN Eafamotivoafasttemporario MAT
          ON AV.CdMotivoAfastTemporario = MAT.CdMotivoAfastTemporario
       INNER JOIN Eafahistmotivoafasttemp HMAT
          ON MAT.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
       WHERE AV.CdVinculo = pCdVinculo
         AND AV.FlAnulado = XTMPAG_TIPO.cnN
         AND HMAT.FlRemunerado = XTMPAG_TIPO.cnN
         AND AV.DtInicio <= pDtFim
         AND (AV.DtFim >= pDtInicio OR AV.DtFim IS NULL)
         AND HMAT.DtInicioVigencia <= pdtCalculo
         AND (HMAT.DtFimVigencia >= pdtCalculo OR
             HMAT.DtFimVigencia IS NULL)
         AND ROWNUM < 2;

      BEGIN

        SELECT 'S'
          INTO vMotivoAfastamento.InPagaLancamento
          FROM EPagLancamentoFinanceiro LF
         WHERE LF.CdVinculo = pCdVinculo
           AND LF.FlPagaAfastTempSemRemun = XTMPAG_TIPO.cnS
           AND LF.DtInicioDireito <= pDtFim
           AND (LF.DtFimDireito >= pDtInicio OR LF.Dtfimdireito IS NULL)
           and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                             from vpagrubricaagrupamento ra
                                            where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                              and ra.flsuspensa = XTMPAG_TIPO.cnN)
           AND ROWNUM < 2;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          NULL;

      END;

      RETURN vMotivoAfastamento;

    ELSE

      BEGIN

        SELECT 'D',
               MAD.CdMotivoAfastDefinitivo,
               AV.DtInclusao,
               AV.DtInicio
          INTO vMotivoAfastamento.InTipoAfastamento,
               vMotivoAfastamento.CdChaveMotivo,
               vMotivoAfastamento.DtInclusao,
               vMotivoAfastamento.DtInicio
          FROM EAfaAfastamentoVinculo AV
         INNER JOIN EAfaMotivoAfastDefinitivo MAD
            ON AV.CdMotivoAfastDefinitivo = MAD.CdMotivoAfastDefinitivo
         INNER JOIN EafahistmotivoafastDef HMAD
            ON MAD.CdMotivoAfastDefinitivo = HMAD.CdMotivoAfastDefinitivo
         WHERE AV.CdVinculo = pCdVinculo
           AND AV.FlAnulado = XTMPAG_TIPO.cnN
           AND HMAD.FlRemunerado = XTMPAG_TIPO.cnN
           AND AV.DtInicio <= pDtInicio
           AND (AV.DtFim >= pDtFim OR AV.DtFim IS NULL)
           AND HMAD.DtInicioVigencia <= pdtCalculo
           AND (HMAD.DtFimVigencia >= pdtCalculo OR
               HMAD.DtFimVigencia IS NULL)
           AND ROWNUM < 2;

        vMotivoAfastamento.InAfastado := XTMPAG_TIPO.cnAfastadoMesTodo;

        RETURN vMotivoAfastamento;

      EXCEPTION

      WHEN NO_DATA_FOUND THEN

          BEGIN
            -- Demitidos no mes
            SELECT 'D',
                   MAD.CdMotivoAfastDefinitivo,
                   AV.DtInclusao,
                   AV.Dtinicio
              INTO vMotivoAfastamento.InTipoAfastamento,
                   vMotivoAfastamento.CdChaveMotivo,
                   vMotivoAfastamento.DtInclusao,
                   vMotivoAfastamento.DtInicio
              FROM EAfaAfastamentoVinculo AV
              INNER JOIN EAfaMotivoAfastDefinitivo MAD
                 ON AV.CdMotivoAfastDefinitivo = MAD.CdMotivoAfastDefinitivo
              INNER JOIN EafahistmotivoafastDef HMAD
                 ON MAD.CdMotivoAfastDefinitivo = HMAD.CdMotivoAfastDefinitivo
              WHERE AV.CdVinculo = pCdVinculo
                AND AV.FlAnulado = XTMPAG_TIPO.cnN
                AND HMAD.FlRemunerado = XTMPAG_TIPO.cnN
                AND AV.DtInicio BETWEEN pDtInicio and pDtFim
                AND HMAD.DtInicioVigencia <= pdtCalculo
                AND (HMAD.DtFimVigencia >= pdtCalculo OR
                     HMAD.DtFimVigencia IS NULL)
                AND ROWNUM < 2;

           IF TO_CHAR(XTMPAG_VAR.vgVinculo.DtDesligamento, 'DD') = vNuDiasAfast
             AND TO_CHAR(pDtFim, 'MMYYYY') = TO_CHAR(XTMPAG_VAR.vgVinculo.DtDesligamento, 'MMYYYY')
            THEN

              BEGIN
                -- SIG-4755
                -- Servidor demitido no mês, com afastamento temporário não remunerado anterior
                SELECT XTMPAG_TIPO.cnAfastadoMesTodo
                  INTO vMotivoAfastamento.InAfastado
                  FROM EAfaAfastamentoVinculo AV
                  LEFT join Eafamotivoafasttemporario mat
                    on mat.cdmotivoafasttemporario = av.cdmotivoafasttemporario
                  LEFT join Eafahistmotivoafasttemp hmat
                    on hmat.cdmotivoafasttemporario = av.cdmotivoafasttemporario
                 WHERE AV.CdVinculo = pCdVinculo
                   AND AV.FlAnulado = XTMPAG_TIPO.cnN
                   AND (hmat.flremunerado = XTMPAG_TIPO.cnN)
                   AND AV.DtInicio < XTMPAG_var.vgFolha.dtInicioMes
                   AND (AV.Dtfim = vMotivoAfastamento.DtInicio OR AV.Dtfim = vMotivoAfastamento.DtInicio-1)
                   AND (HMAT.DtInicioVigencia <= XTMPAG_var.vgFolha.dtcalculoant)
                   AND (HMAT.DtFimVigencia >= XTMPAG_var.vgFolha.dtcalculoant OR
                       HMAT.DtFimVigencia IS NULL)
                   AND ROWNUM < 2;

                -- caso encontre um afastamento não remunerado com a data fim igual a data início do afastamento definitio,
                -- considera como afastado o mês todo
                -- vMotivoAfastamento.InAfastado := XTMPAG_TIPO.cnAfastadoMesTodo;

               EXCEPTION

                    WHEN NO_DATA_FOUND
                      THEN
                      vMotivoAfastamento.InAfastado := XTMPAG_TIPO.cnAfastadoParcial;

                    RETURN vMotivoAfastamento;
               END;

            ELSE
              vMotivoAfastamento.InAfastado := XTMPAG_TIPO.cnAfastadoParcial;
            END IF;

            RETURN vMotivoAfastamento;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

               BEGIN

                  SELECT 'T',
                         MAT.CdMotivoAfastTemporario,
                         AV.DtInclusao,
                         HMAT.Flauxiliodoenca,
                         HMAT.Flacidentetrabalho,
                         HMAT.Flprocessanaopaga
                    INTO vMotivoAfastamento.InTipoAfastamento,
                         vMotivoAfastamento.CdChaveMotivo,
                         vMotivoAfastamento.DtInclusao,
                         vMotivoAfastamento.FlAuxilioDoenca,
                         vMotivoAfastamento.FlAcidenteTrabalho,
                         vMotivoAfastamento.FlProcessaNaoPaga
                    FROM EAfaAfastamentoVinculo AV
                   INNER JOIN Eafamotivoafasttemporario MAT
                      ON AV.CdMotivoAfastTemporario = MAT.CdMotivoAfastTemporario
                   INNER JOIN Eafahistmotivoafasttemp HMAT
                      ON MAT.CdMotivoAfastTemporario =
                         HMAT.CdMotivoAfastTemporario
                   WHERE AV.CdVinculo = pCdVinculo
                     AND AV.FlAnulado = XTMPAG_TIPO.cnN
                     AND HMAT.FlRemunerado = XTMPAG_TIPO.cnN
                     AND AV.DtInicio <= pDtFim
                     AND (AV.DtFim >= pDtInicio OR AV.DtFim IS NULL)
                     AND HMAT.DtInicioVigencia <= pdtCalculo
                     AND (HMAT.DtFimVigencia >= pdtCalculo OR
                         HMAT.DtFimVigencia IS NULL)
                     AND ROWNUM < 2;

                  vMotivoAfastamento.InAfastado := XTMPAG_TIPO.cnAfastadoParcial;

                  RETURN vMotivoAfastamento;

                EXCEPTION

                  WHEN NO_DATA_FOUND THEN

                  RETURN vMotivoAfastamento;

              END;

          END;

      END;

    END IF;

    RETURN vMotivoAfastamento;

  END;

  procedure pAtualizaValorRubrica (pCdVinculo in integer,
                                   pCdFolhaPagamento in integer,
                                   pCdRubricaAgrupamento in integer,
                                   pValorRubrica in XTMPAG_tipo.rValorPagamento,
                                   pCdRelacaoVinculo in integer default null,
                                   pCdOutraRubrica in integer default null,
                                   pDeFormula in char default null,
                                   pIncluiRelVinc in char default 'N') is

  begin
    -- xtmpag_util.pGravaLogCallStack;

     case
        when pCdRelacaoVinculo is null and pCdOutraRubrica is null
          then

            update epaghistoricorubricavinculo hrv
               set hrv.vlpagamento = pValorRubrica.vlIntegral,
                   hrv.deexpressao = nvl(pDeFormula, hrv.deexpressao)
             where hrv.cdvinculo = pCdVinculo
               and hrv.cdfolhapagamento = pCdFolhaPagamento
               and hrv.cdrubricaagrupamento = pCdRubricaAgrupamento;

             if pIncluiRelVinc = 'S' then
                update epaghistoricorubricarelvinc hv
                   set hv.vlreal = pValorRubrica.vlIntegral,
                       hv.vlintegral = pValorRubrica.vlIntegral,
                       hv.vlproporcional =  pValorRubrica.vlIntegral,
                       hv.deexpressao = nvl(pDeFormula, hv.deexpressao)
                 where hv.cdvinculo = pCdVinculo
                   and hv.cdfolhapagamento = pCdFolhaPagamento
                   and hv.cdrubricaagrupamento = pCdRubricaAgrupamento;

             end if;

          else
             update epaghistoricorubricavinculo hrv
               set hrv.cdrubricaagrupamento = pCdOutraRubrica,
                   hrv.deexpressao = nvl(pDeFormula, hrv.deexpressao)
             where hrv.cdvinculo = pCdVinculo
               and hrv.cdfolhapagamento = pCdFolhaPagamento
               and hrv.cdrubricaagrupamento = pCdRubricaAgrupamento;

             if pIncluiRelVinc = 'S' then
                update epaghistoricorubricarelvinc hv
                   set hv.vlreal = pValorRubrica.vlIntegral,
                       hv.vlintegral = pValorRubrica.vlIntegral,
                       hv.vlproporcional =  pValorRubrica.vlIntegral,
                       hv.deexpressao = nvl(pDeFormula, hv.deexpressao)
                 where hv.cdvinculo = pCdVinculo
                   and hv.cdfolhapagamento = pCdFolhaPagamento
                   and hv.cdrubricaagrupamento = pCdOutraRubrica;

             end if;

      end case;

  end;

  FUNCTION FAfastamentoVinculo(pCdVinculo          IN INTEGER,
                               pDtInicio           IN DATE,
                               pDtFim              IN DATE,
                               pdtCalculo          IN DATE,
                               pTipoAfa            IN CHAR, -- R-Temporario Remunerado | N-temporario nao remunerado | D-Definitivo | V-Relacao de vinculo
                               pCdHistCargoEfetivo IN INTEGER DEFAULT NULL,
                               pDtCalculoAnt       IN DATE DEFAULT NULL,
                               pAuxAlim            IN CHAR DEFAULT 'N')
   RETURN XTMPAG_TIPO.tAfastamento IS

    tAfastVinc XTMPAG_TIPO.tAfastamento;

    i numeric := 0;
    j numeric := 0;

    PROCEDURE pIncluiAfast(pCdVinculo        IN INTEGER,
                           pCdMotivo         IN INTEGER,
                           pRemunerado       IN CHAR,
                           pTipo             IN CHAR,
                           pGravidez         IN CHAR,
                           pDtInicioAfa      IN DATE,
                           pDtFimAfa         IN DATE,
                           pDtInicioAfaNoMes IN DATE,
                           pDtFimAfaNoMes    IN DATE,
                           pDtInclusao       DATE,
                           pFlParteJornada    IN CHAR,
                           pVlPercentReducaoIRESA In NUMBER,
                           pIndice           IN NUMERIC,
                           pDtAnulado        IN DATE := NULL) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      tAfastVinc(pIndice).CdVinculo := pCdVinculo;

      tAfastVinc(pIndice).CdMotivoAfastamento := pCdMotivo;

      tAfastVinc(pIndice).FlGravidez := pGravidez;

      tAfastVinc(pIndice).DtInicioAfaNoMes := pDtInicioAfaNoMes;

      tAfastVinc(pIndice).DtFimAfaNoMes := pDtFimAfaNoMes;

      tAfastVinc(pIndice).DtFimAfa := pDtFimAfa;

      tAfastVinc(pIndice).DtInicioAfa := pDtInicioAfa;

      tAfastVinc(pIndice).DtInclusao := pDtInclusao;

      tAfastVinc(pIndice).NuDiasAfastMes := NVL((pDtFimAfaNoMes - pDtInicioAfaNoMes + 1),0);

      if to_char(pDtFimAfaNoMes,'DD') = 31 and tAfastVinc(pIndice).NuDiasAfastMes > 1 then
         tAfastVinc(pIndice).NuDiasAfastMes := tAfastVinc(pIndice).NuDiasAfastMes - 1;
      end if;

      if pDtFimAfaNoMes = pDtFim then
        tAfastVinc(pIndice).FlUltimoDiaMes := 'S';

        if pRemunerado = 'S' then
          XTMPAG_VAR.bPossuiAfastRemunUltDiaMes := true;
        else
          XTMPAG_VAR.bPossuiAfastNaoRemunUltDiaMes := true;
        end if;

      else
        tAfastVinc(pIndice).FlUltimoDiaMes := 'N';
      end if;

      if pDtInclusao > XTMPAG_var.vgfolha.DtCalculoAnt OR (pDtAnulado IS NOT NULL AND pDtAnulado > XTMPAG_var.vgfolha.DtCalculoAnt)
         and pDtInicioAfa < XTMPAG_var.vgfolha.DtInicioMes
       then
         tAfastVinc(pIndice).NuDiasAfastMesAnt := least(XTMPAG_var.vgfolha.DtInicioMes, NVL(pDtFimAfa,XTMPAG_var.vgfolha.DtInicioMes) ) - pDtInicioAfa;
      else
         tAfastVinc(pIndice).NuDiasAfastMesAnt := 0;
      end if;

      tAfastVinc(pIndice).DtAnulado := pDtAnulado;

      tAfastVinc(pIndice).FlParteJornada := pFlParteJornada;
      tAfastVinc(pIndice).VlPercentReducaoIRESA := pVlPercentReducaoIRESA;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    -- Afastamentos temporarios R - Remunerado, N - Nao Remunerado, L - Auxilio Alimentacao
    CASE
      WHEN pTipoAfa in ('R','N') THEN

        FOR f_afa in (SELECT CDVINCULO,
                             CDMOTIVO,
                             REMUNERADO,
                             'T' as TIPO,
                             'N' as Gravidez,
                             DtInicioAfa,
                             DtFimAfa,
                             DtFimAfaNoMes,
                             DtInicioAfaNoMes,
                             DtInclusao,
                             FlParteJornada,
                             VlPercentReducaoIRESA,
                             ROWNUM
                        FROM (SELECT AV.cdVinculo CdVinculo,
                                     AV.Cdmotivoafasttemporario CdMotivo,
                                     HMAT.Flremunerado as Remunerado,
                                     AV.DtInicio as DtInicioAfa,
                                     AV.DtFim as DtFimAfa,
                                     CASE
                                       WHEN AV.dtInicio < pDtInicio AND (Av.DtFim >= pDtInicio OR av.DtFim IS NULL)
                                          THEN pDtInicio
                                        WHEN Av.DtFim < pDtInicio
                                          THEN NULL
                                       ELSE
                                        AV.Dtinicio
                                     END AS DtInicioAfaNoMes,
                                     CASE
                                       WHEN (AV.dtFim > pDtFim OR
                                            AV.DtFim IS NULL) THEN
                                        pDtFim
                                       WHEN Av.DtFim < pDtInicio
                                          THEN NULL
                                       ELSE
                                        AV.dtFim
                                     END AS DtFimAfaNoMes,
                                     AV.DtInicio,
                                     AV.DtFim,
                                     AV.DtInclusao,
                                     HMAT.FlParteJornada,
                                     HMAT.VlPercentReducaoIRESA
                                FROM EAfaAfastamentoVinculo AV
                               INNER JOIN EAfaMotivoAfastTemporario MAT
                                  ON AV.CdMotivoAfastTemporario =
                                     MAT.CdMotivoAfastTemporario
                               INNER JOIN EAfaHistMotivoAfastTemp HMAT
                                  ON MAT.CdMotivoAfastTemporario =
                                     HMAT.CdMotivoAfastTemporario
                               WHERE AV.CdVinculo = pCdVinculo
                                  AND (AV.Dtinicio <= pDtFim AND
                                           ((AV.Dtfim >= pDtInicio OR AV.DtFim IS NULL) OR
                                            (trunc(AV.DtInclusao) BETWEEN (trunc(XTMPAG_VAR.vDtCalculoAnt) + 1) AND trunc(pDtCalculo))))
                                 AND HMAT.DtInicioVigencia <= pDtCalculo
                                 AND HMAT.FLREMUNERADO = CASE
                                       WHEN pTipoAfa = 'R' THEN
                                        XTMPAG_TIPO.cnS
                                       ELSE
                                        XTMPAG_TIPO.cnN
                                     END
                                 AND (HMAT.DtFimVigencia >= pDtCalculo OR
                                     HMAT.DtFimVigencia IS NULL)
                                 AND HMAT.FlAnulado = XTMPAG_TIPO.cnN
                                 AND AV.FlAnulado = XTMPAG_TIPO.cnN
                                 ) order by DtInicioAfa
                                ) LOOP

          i := i + 1;

          pIncluiAfast(f_Afa.CdVinculo,
                       f_Afa.CdMotivo,
                       f_Afa.REMUNERADO,
                       'T',
                       'N',
                       f_Afa.DtInicioAfa,
                       f_Afa.DtFimAfa,
                       f_Afa.DtInicioAfaNoMes,
                       f_Afa.DtFimAfaNoMes,
                       f_Afa.DtInclusao,
                       f_Afa.FlParteJornada,
                       f_Afa.VlPercentReducaoIRESA,
                       i);

         IF pAuxAlim = 'N' then

          IF pTipoAfa = 'R' then
            XTMPAG_VAR.vgNuDiasAfastRemun := NVL(XTMPAG_VAR.vgNuDiasAfastRemun,0) +
                                             f_Afa.DtFimAfaNoMes -
                                             f_Afa.DtInicioAfaNoMes + 1;

            IF f_Afa.DtInclusao >= XTMPAG_var.vgfolha.DtCalculoAnt +1
               AND f_Afa.DtInicioAfa < XTMPAG_var.vgFolha.DtInicioMes
               AND f_Afa.DtInicioAfa >= add_months(XTMPAG_var.vgFolha.DtInicioMes, -4)
               THEN

                 XTMPAG_var.vgNuDiasAfastRetroativo := nvl(XTMPAG_var.vgNuDiasAfastRetroativo,0) +
                                                     (case when NVL(f_Afa.DtFimAfa + 1, XTMPAG_var.vgfolha.DtInicioMes + 1) >
                                                                XTMPAG_var.vgfolha.DtInicioMes
                                                           then XTMPAG_var.vgfolha.DtInicioMes
                                                           else f_Afa.DtFimAfa + 1
                                                      end) - f_Afa.DtInicioAfa;
             END IF;

          else
            XTMPAG_VAR.vgNuDiasAfastSemRemun := NVL(XTMPAG_VAR.vgNuDiasAfastSemRemun,0) +
                                                f_Afa.DtFimAfaNoMes -
                                                f_Afa.DtInicioAfaNoMes + 1;

            if f_afa.DtInicioAfa <= pDtFim and nvl(f_afa.DtFimAfa, pDtInicio) >= pDtInicio then
              XTMPAG_VAR.vgNuDiasAfastSemRemunMesAtual := nvl(XTMPAG_VAR.vgNuDiasAfastSemRemunMesAtual,0) +
                                                          f_Afa.DtFimAfaNoMes -
                                                          f_Afa.DtInicioAfaNoMes + 1;
            end if;

             IF f_Afa.DtInclusao >= XTMPAG_var.vgfolha.DtCalculoAnt +1
               AND f_Afa.DtInicioAfa < XTMPAG_var.vgFolha.DtInicioMes
               AND f_Afa.DtInicioAfa >= add_months(XTMPAG_var.vgFolha.DtInicioMes, -4)
               THEN

                 XTMPAG_var.vgNuDiasAfastRetroativo := nvl(XTMPAG_var.vgNuDiasAfastRetroativo,0) +
                                                     (case when NVL(f_Afa.DtFimAfa + 1, XTMPAG_var.vgfolha.DtInicioMes + 1) >
                                                                XTMPAG_var.vgfolha.DtInicioMes
                                                           then XTMPAG_var.vgfolha.DtInicioMes
                                                           else f_Afa.DtFimAfa + 1
                                                      end) - f_Afa.DtInicioAfa;
                 --
                 -- Dias para auxílio alimentacao
                 --
                  IF XTMPAG_var.vgListaEventoAfast11.exists(f_afa.cdmotivo)
                    THEN
                      XTMPAG_var.vgNuDiasAfastAuxAlimRet := nvl(XTMPAG_var.vgNuDiasAfastAuxAlimRet,0) + 0;
                    ELSE
                      XTMPAG_var.vgNuDiasAfastAuxAlimRet := nvl(XTMPAG_var.vgNuDiasAfastAuxAlimRet,0) +
                                                     (case when NVL(f_Afa.DtFimAfa + 1, XTMPAG_var.vgfolha.DtInicioMes + 1) >
                                                                XTMPAG_var.vgfolha.DtInicioMes
                                                           then XTMPAG_var.vgfolha.DtInicioMes
                                                           else f_Afa.DtFimAfa + 1
                                                      end) - f_Afa.DtInicioAfa;

                  END IF;

             END IF;

          END IF;

          IF XTMPAG_var.vgListaEventoAfast11.exists(f_afa.cdmotivo)
            then
              j := j + 1;
              XTMPAG_var.vgAfastAuxAlimentacao(j) := tAfastVinc(i);
          end if;

        END IF;

        END LOOP;

      WHEN pTipoAfa = 'D' THEN
        FOR f_afa in (SELECT CDVINCULO,
                             CDMOTIVO,
                             REMUNERADO,
                             'T' as TIPO,
                             'N' as Gravidez,
                             DtInicioAfa,
                             DtFimAfa,
                             DtFimAfaNoMes,
                             DtInicioAfaNoMes,
                             DtInclusao,
                             'N' AS FlParteJornada,
                             0 AS VlPercentReducaoIRESA,
                             ROWNUM
                        FROM (SELECT AV.cdVinculo CdVinculo,
                                     AV.Cdmotivoafasttemporario CdMotivo,
                                     HMAD.Flremunerado as Remunerado,
                                     AV.DtInicio as DtInicioAfa,
                                     AV.DtFim as DtFimAfa,
                                     CASE
                                       WHEN AV.dtInicio < pDtInicio THEN
                                        pDtInicio
                                       ELSE
                                        AV.Dtinicio
                                     END AS DtInicioAfaNoMes,
                                     CASE
                                       WHEN (AV.dtFim > pDtFim OR
                                            AV.DtFim IS NULL) THEN
                                        pDtFim
                                       ELSE
                                        AV.dtFim
                                     END AS DtFimAfaNoMes,
                                     AV.DtInicio,
                                     AV.DtFim,
                                     AV.DtInclusao
                                FROM EAfaAfastamentoVinculo AV
                               INNER JOIN EAfaMotivoAfastDefinitivo MAD
                                  ON AV.CdMotivoAfastDefinitivo =
                                     MAD.CdMotivoAfastDefinitivo
                               INNER JOIN EafahistmotivoafastDef HMAD
                                  ON MAD.CdMotivoAfastDefinitivo =
                                     HMAD.CdMotivoAfastDefinitivo
                               WHERE AV.CdVinculo = pCdVinculo
                                 AND ((AV.Dtinicio <= pDtFim AND
                                      (AV.Dtfim >= pDtInicio OR AV.DtFim IS NULL))
                                      OR (trunc(AV.DtInclusao) BETWEEN (trunc(XTMPAG_VAR.vDtCalculoAnt) + 1) AND trunc(pDtCalculo)))
                                 AND HMAD.DtInicioVigencia <= pDtCalculo
                                 AND HMAD.FLREMUNERADO = XTMPAG_TIPO.cnN
                                 AND (HMAD.DtFimVigencia >= pDtCalculo OR
                                     HMAD.DtFimVigencia IS NULL)
                                 AND HMAD.FlAnulado = XTMPAG_TIPO.cnN
                                 AND AV.FlAnulado = XTMPAG_TIPO.cnN))

         LOOP

          i := i + 1;

          pIncluiAfast(f_Afa.CdVinculo,
                       f_Afa.CdMotivo,
                       'N',
                       'T',
                       'N',
                       f_Afa.DtInicioAfa,
                       f_Afa.DtFimAfa,
                       f_Afa.DtInicioAfaNoMes,
                       f_Afa.DtFimAfaNoMes,
                       f_Afa.DtInclusao,
                       f_Afa.FlParteJornada,
                       f_Afa.VlPercentReducaoIRESA,
                       i);

          XTMPAG_VAR.vgNuDiasAfastDefinitivo := nvl(XTMPAG_VAR.vgNuDiasAfastDefinitivo,0) +
                                                f_Afa.DtFimAfaNoMes -
                                                f_Afa.DtInicioAfaNoMes + 1;

        END LOOP;

      WHEN pTipoAfa = 'V' THEN
        FOR f_Afa in (SELECT pCdVinculo as CdVinculo,
                             1 as CdMotivo, -- Opcao Remureracao
                             'N' as Remunerado,
                             'T' as TIPO,
                             'N' as Gravidez,
                             DtInicioAfa,
                             DtFimAfa,
                             DtFimAfaNoMes,
                             DtInicioAfaNoMes,
                             DtInclusao,
                             'N' AS FlParteJornada,
                             0 AS VlPercentReducaoIRESA,
                             ROWNUM
                        FROM (SELECT CASE
                                       WHEN Av.DtInicio < pDtInicio THEN
                                        pDtInicio
                                       ELSE
                                        Av.DtInicio
                                     END AS DtInicioAfaNoMes,
                                     CASE
                                       WHEN Av.DtFim > pDtFim OR
                                            Av.DtFim IS NULL THEN
                                        pDtFim
                                       ELSE
                                        Av.DtFim
                                     END AS DtFimAFaNoMes,
                                     Av.DtInicio as DtInicioAfa,
                                     Av.DtFim as DtFimAfa,
                                     Av.DtInclusao
                                FROM Eafaafastamentorelvinc AV
                               WHERE AV.CdHistCargoEfetivo =
                                     pCdHistCargoEfetivo
                                 AND AV.CdHistCargoComGerador IS NOT NULL
                                 AND AV.Dtinicio <= pDtFim
                                 AND (AV.Dtfim >= pDtInicio OR
                                     AV.DtFim IS NULL)
                                 AND EXISTS
                               (SELECT 1
                                        FROM ECadHistCargoCom HCC
                                       INNER JOIN (SELECT H.CdHistCargoCom,
                                                         MAX(H.DtInicioVigencia) AS DtInicioVigencia
                                                    FROM ECadHistOpcaoRemuneracaoCCO H
                                                   WHERE H.DtInicioVigencia <=
                                                         pDtFim
                                                     AND (H.DtFimVigencia >=
                                                         pDtInicio OR
                                                         H.DtFimVigencia IS NULL)
                                                   GROUP BY H.CdHistCargoCom) HOR1
                                          ON HCC.CdHistCargoCom =
                                             HOR1.CdHistCargoCom
                                       INNER JOIN ECadHistOpcaoRemuneracaoCCO HOR
                                          ON HOR1.Cdhistcargocom =
                                             HOR.CdHistCargoCom
                                         AND HOR1.DtInicioVigencia =
                                             HOR.DtInicioVigencia
                                       WHERE HCC.CdHistCargoCom =
                                             AV.CdHistCargoComGerador
                                         AND NOT (XTMPAG_VAR.vgFolha.FlIgnoraInclusaoFutura = 'S' AND
                                              HCC.DtInclusao > pDtCalculo)
                                         AND HCC.CdCargoComRemuneracao IS NULL
                                            --AND ((HOR.CdOpcaoRemuneracao = 3 AND
                                            --      NOT (HCC.FlTipoProvimento IN (XTMPAG_TIPO.cnS) AND
                                            ---     pRubrica.FlPropAfaCCOSubst = XTMPAG_TIPO.cnN)) OR
                                            --    (pRubrica.FlPropAfaFgFtg = XTMPAG_TIPO.cnS AND
                                            ---    HOR.CdOpcaoRemuneracao = 6 ) OR
                                            --   (pEventoCEF = XTMPAG_TIPO.cnN AND HCC.CdOpcaoRemuneracao = 2 AND
                                            --   pRubrica.FlPropAfaComOpcPercCEF = 'S')))
                                         AND AV.FlAnulado = XTMPAG_TIPO.cnN)))

         LOOP

          i := i + 1;

          pIncluiAfast(f_Afa.CdVinculo,
                       f_Afa.CdMotivo,
                       'S',
                       'T',
                       'N',
                       f_Afa.DtInicioAfa,
                       f_Afa.DtFimAfa,
                       f_Afa.DtInicioAfaNoMes,
                       f_Afa.DtFimAfaNoMes,
                       f_Afa.DtInclusao,
                       f_Afa.FlParteJornada,
                       f_Afa.VlPercentReducaoIRESA,
                       i);

          XTMPAG_VAR.vgNuDiasAfastRelVinc := nvl(XTMPAG_VAR.vgNuDiasAfastRelVinc,0) +
                                             f_Afa.DtFimAfaNoMes -
                                             f_Afa.DtInicioAfaNoMes + 1;
        END LOOP;

      WHEN pTipoAfa = 'A' THEN
        -- Afastamento temporarios anulados
        FOR f_afa in (SELECT CDVINCULO,
                             CDMOTIVO,
                             REMUNERADO,
                             'T' as TIPO,
                             'N' as Gravidez,
                             DtInicioAfa,
                             DtFimAfa,
                             DtFimAfaNoMes,
                             DtInicioAfaNoMes,
                             DtInclusao,
                             Dtanulado,
                             FlParteJornada,
                             VlPercentReducaoIRESA,
                             ROWNUM
                        FROM (SELECT AV.cdVinculo CdVinculo,
                                     AV.Cdmotivoafasttemporario CdMotivo,
                                     HMAT.Flremunerado as Remunerado,
                                     AV.DtInicio as DtInicioAfa,
                                     AV.DtFim as DtFimAfa,
                                     CASE
                                       WHEN AV.dtInicio < pDtInicio THEN
                                        pDtInicio
                                       ELSE
                                        AV.Dtinicio
                                     END AS DtInicioAfaNoMes,
                                     CASE
                                       WHEN (AV.dtFim > pDtFim OR
                                            AV.DtFim IS NULL) THEN
                                        pDtFim
                                       ELSE
                                        AV.dtFim
                                     END AS DtFimAfaNoMes,
                                     AV.DtInicio,
                                     AV.DtFim,
                                     AV.Dtinclusao,
                                     AV.Dtanulado,
                                     HMAT.FlParteJornada,
                                     HMAT.VlPercentReducaoIRESA
                                FROM EAfaAfastamentoVinculo AV
                               INNER JOIN EAfaMotivoAfastTemporario MAT
                                  ON AV.CdMotivoAfastTemporario =
                                     MAT.CdMotivoAfastTemporario
                               INNER JOIN EAfaHistMotivoAfastTemp HMAT
                                  ON MAT.CdMotivoAfastTemporario =
                                     HMAT.CdMotivoAfastTemporario
                               WHERE AV.CdVinculo = pCdVinculo
                                 AND (AV.DtAnulado BETWEEN (XTMPAG_VAR.vDtCalculoAnt + 1) AND pDtCalculo)
                                 AND HMAT.DtInicioVigencia <= pDtCalculo
                                 AND HMAT.FLREMUNERADO = XTMPAG_TIPO.cnS
                                 AND (HMAT.DtFimVigencia >= pDtCalculo OR
                                     HMAT.DtFimVigencia IS NULL)
                                 AND HMAT.FlAnulado = XTMPAG_TIPO.cnN
                                 AND AV.FlAnulado = XTMPAG_TIPO.cnS) -- Anulados
                                ) LOOP

          i := i + 1;

          pIncluiAfast(f_Afa.CdVinculo,
                       f_Afa.CdMotivo,
                       f_Afa.REMUNERADO,
                       'T',
                       'N',
                       f_Afa.DtInicioAfa,
                       f_Afa.DtFimAfa,
                       f_Afa.DtInicioAfaNoMes,
                       f_Afa.DtFimAfaNoMes,
                       f_Afa.DtInclusao,
                       f_Afa.FlParteJornada,
                       f_Afa.VlPercentReducaoIRESA,
                       i,
                       f_Afa.Dtanulado);

        END LOOP;

    END CASE;

    RETURN tAfastVinc;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN tAfastVinc;

      RETURN tAfastVinc;

  END;

  FUNCTION FPossuiRescisao(pCdVinculo IN INTEGER)
    RETURN BOOLEAN IS

  vRescisao INTEGER := 0;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT COUNT(*)
    INTO vRescisao
    FROM epagrescisaocontrato re
    WHERE re.cdvinculo =  pCdVinculo
    AND to_char(re.dtrescisao, 'YYYYMM') = to_char(XTMPAG_var.vgFolha.dtcalculo, 'YYYYMM');

    IF vRescisao > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

  END;

  FUNCTION FPossuiFolhaRescisao(pCdVinculo IN INTEGER)
    RETURN BOOLEAN IS

  vFolha INTEGER := 0;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT COUNT(*)
      INTO vFolha
      FROM ecadvinculo v
     INNER JOIN epaghistoricorubricavinculo rv
        ON v.cdvinculo = rv.cdvinculo
     INNER JOIN epagfolhapagamento fp
        ON fp.cdfolhapagamento = rv.cdfolhapagamento
     INNER JOIN epagtipofolhapagamento tf
        ON tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
     WHERE v.cdvinculo = pCdVinculo
       AND fp.cdagrupamento = XTMPAG_var.vgFolha.cdagrupamento
       AND fp.cdtipocalculo = 1 -- calculo normal
       AND tf.cdtipofolha = 2 -- folha de rescisao
       AND fp.flcalculodefinitivo = 'S';

    IF vFolha > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

  END;

FUNCTION fpossuipagamentomediaferias(pcdvinculo       INTEGER,
                                     pdtiniciofruicao DATE,
                                     pcdorgao         INTEGER,
                                     pcdagrupamento   INTEGER)

 RETURN BOOLEAN IS

  vcdfolhapagamento INTEGER;

BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  WITH ferias AS
   (SELECT DISTINCT u.cdperiodoaquisitivoferias, v.cdvinculo
      FROM eafaafastamentovinculo v
     INNER JOIN emovferiasfruicaousufruto u
        ON u.cdferiasprogramacaousufruto = v.cdferiasprogramacaousufruto
     WHERE v.cdvinculo = pcdvinculo
       AND v.dtinicio >= pdtiniciofruicao)

  SELECT p.cdfolhapagamento
    INTO vcdfolhapagamento
    FROM emovferiasfruicaopagamento fu
   INNER JOIN ferias f
      ON fu.cdperiodoaquisitivoferias = f.cdperiodoaquisitivoferias
   INNER JOIN epagfolhapagamento p
      ON fu.nuanoreferencia = p.nuanoreferencia
     AND fu.numesreferencia = p.numesreferencia
   INNER JOIN epaghistoricorubricavinculo rv
      ON rv.cdfolhapagamento = p.cdfolhapagamento
     AND rv.cdvinculo = f.cdvinculo
   WHERE p.flcalculodefinitivo = 'S'
     AND p.cdorgao = pcdorgao
     AND rv.cdrubricaagrupamento =
         XTMPAG_geral.fretornarubrica(pcdagrupamento, 1, 201);

  IF NVL(vcdfolhapagamento, 0) > 0  THEN
     -- Permitir se for folha de recalculo do mes
     if XTMPAG_var.vgFolha.CdFolhaPagamentoNormal = vcdfolhapagamento and
        XTMPAG_var.vgFolha.CdTipoCalculo = XTMPAG_TIPO.cntpcalculorecalculomes then

        return false;

     else

        RETURN TRUE;

     end if;

  ELSE

    RETURN FALSE;

  END IF;

EXCEPTION

  WHEN no_data_found THEN
    RETURN FALSE;

END;
  FUNCTION FDadosServidorDesligado(pCdVinculo IN INTEGER) RETURN VARCHAR2 IS

  vDados VARCHAR2(90) := NULL;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT lpad(v.numatricula, 7, 0) || '-' || v.nudvmatricula || '-' || lpad(v.nuseqmatricula, 2, 0) || ' / ' || p.nmpessoa
      INTO vDados
      FROM ecadpessoa p
      INNER JOIN ecadvinculo v
      ON v.cdpessoa = p.cdpessoa
      WHERE v.cdvinculo = pCdVinculo;

    IF vDados IS NOT NULL THEN

      RETURN vDados;

    ELSE

      RETURN NULL;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN NULL;

  END;

  PROCEDURE PAnulaAfastTempNaoRemun ( pCdVinculo IN INTEGER,
                                      pDtCalculo IN DATE,
                                      pcdAgrupamento IN INTEGER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    insert into epaghistfolhaservafast (
           cdfolhapagamento
         , cdvinculo
         , cdafastamento
         , dtalteracao)
    select XTMPAG_var.vgFolha.cdFolhaPagamento
         , pCdVinculo
         , av.cdafastamento
         , XTMPAG_var.vgFolha.dtCalculo
      from eafaafastamentovinculo av
    /* inner join ecadhistcargoefetivo cef
     on cef.cdvinculo = av.cdvinculo
    and cef.cdrelacaotrabalho <> 10
    and cef.dtinicio <= XTMPAG_var.vgFolha.dtFimMes
    and (cef.dtfim >= XTMPAG_var.vgFolha.dtInicioMes or cef.dtfim is null)*/
    /* inner join ecadvinculo v
     on v.cdvinculo = cef.cdvinculo
    and V.CDVINCULO = pCdVinculo*/
     inner join eafamotivoafasttemporario ft on ft.cdmotivoafasttemporario = av.cdmotivoafasttemporario
                                            and ft.cdagrupamento = pcdAgrupamento
     inner join eafahistmotivoafasttemp ht on ht.cdmotivoafasttemporario = av.cdmotivoafasttemporario
                                          and ht.dtiniciovigencia < pDtCalculo
                                          and (ht.dtfimvigencia >= pDtCalculo or ht.dtfimvigencia is null)
     where av.cdvinculo = pCdVinculo
       and ht.flremunerado = 'N'
       and av.flanulado = 'N'
       and av.dtinicio < pDtCalculo
       and (av.dtfim >= trunc(pDtCalculo, 'MM') or av.dtfim is null);

    UPDATE eafaafastamentovinculo Afa
       SET Afa.Flanulado = XTMPAG_TIPO.cnS
     WHERE Afa.Cdafastamento in (select a.cdafastamento
                                   from epaghistfolhaservafast a
                                  where a.cdfolhapagamento = XTMPAG_var.vgFolha.cdFolhaPagamento
                                    and a.cdvinculo = pCdVinculo);
  END;

  --
  -- Verifica saldo de faltas nao descontadas mes anterior, base 09-5519 e inclui na rubrica 08-0519
  --
  procedure pFaltasNaoDescontadas (pCdVinculo IN INTEGER) is

     vVlPagamento number(13,2);

  begin
    -- xtmpag_util.pGravaLogCallStack;

          vVlPagamento := XTMPAG_geral.fretornavalorrubrica(XTMPAG_var.vgFolha.CdFolhaPagamentoNormalAnt,pcdvinculo,
                                                            XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,5519));

     if nvl(vVlPagamento,0) > 0
        then

          XTMPAG_geral.pinserelancamentorelacao(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                       pcdvinculo => pCdVinculo,
                                                pcdrelacaovinculo => XTMPAG_VAR.vgRelVincPrincipal.Tipo,
                                            pCdHistRelacaoVinculo => XTMPAG_VAR.vgRelVincPrincipal.CdHist,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,8,519),
                                                      pVlIntegral => vVlPagamento,
                                                  pVlProporcional => vVlPagamento,
                                            pNuSufixoRubrica      => 1);

          /*XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => null,
                                                pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,8,519),
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => vVlPagamento,
                                                pVlIndice             => null,
                                                pCdTipoOrigemRubrica  => 1);
                                                */
     else
        return;
     end if;

     exception
        when NO_DATA_FOUND
          THEN
            null;
        WHEN OTHERS
          THEN
            null;

  end;

  /*--------------------------------------------------------------------------------------/*
      Funcao: PConsolidaPagVinculo

   Objetivo: Insere/Atualiza registro com o valor integral associado as rubricas

        Nota: Caso o tipo de folha seja diferente de normal, deve ser verificado
              se a rubrica deve ser gerada.
  */ ---------------------------------------------------------------------------------------*/

  PROCEDURE PConsolidaPagVinculo(pCdFolhaPagamento IN INTEGER,
                                 pCdVinculo        IN INTEGER) IS

    PROCEDURE PInsereTodasRVs IS

      vCefCount       INTEGER := XTMPAG_VAR.vgCEF.COUNT;
      vApoCount       INTEGER := XTMPAG_VAR.vgAPO.COUNT;
      vCdRubAgrup1001 INTEGER := XTMPAG_VAR.vgCdRubAgrup1001;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      MERGE INTO EPagHistoricoRubricaVinculo D
      USING (SELECT RV.CdFolhaPagamento,
                    RV.CdVinculo,
                    RV.CdRubricaAgrupamento,
                    RV.NuSufixoRubrica,
                    RV.CdRubricaTotalizadoraVantagem,
                    RV.CdVantagemPecuniaria,
                    RV.CdIncorporacaoAtivo,
                    RV.VlMinRecebIncorp,
                    RV.FlVigenciaPagamento,
                    RV.FlAtualizacaoConstante,
                    RV.CdLancamentoFinanceiro,
                    RV.QtParcelas,
                    RV.CdTipoOrigemRubrica,
                    RV.DeIndiceContraCheque,
                    RV.CdProcessoPagRetroativo,
                    RV.CdHistSentencaJudicial,
                    RV.NuAnoMesOrigem,
                    RV.CdProcessoRestituicaoErario,
                    MAX(CASE
                        -- para rub 1001, se houver cef e apo no mesmo mes,
                        -- vale o indice da apo
                          WHEN vCefCount > 0 AND vApoCount > 0 AND
                               RV.CdRubricaAgrupamento = vCdRubAgrup1001 AND
                               RV.CdConcessaoAposentadoria IS NULL THEN
                           NULL
                          ELSE
                           RV.CdTipoIndice
                        END) CdTipoIndice,
                    SUM(RV.VlProporcional) AS vlPago,
                    SUM(DISTINCT(CASE
                                 -- para rub 1001, se houver cef e apo no mesmo mes, vale o indice da apo
                                   WHEN vCefCount > 0 AND vApoCount > 0 AND
                                        RV.CdRubricaAgrupamento = vCdRubAgrup1001 AND
                                        RV.Cdconcessaoaposentadoria is null THEN
                                    0
                                   WHEN RV.VlProporcional > 0 THEN
                                    RV.VlIndiceRubrica
                                   ELSE
                                    0
                                 END)) AS vlIndice,
                    CASE
                      WHEN RV.CdRubricaAgrupamento in (56601,56658,48193) THEN
                        RV.CDEXPRESSAOFORMCALC
                      ELSE
                        NULL
                      END AS CDEXPRESSAOFORMCALC
               FROM EPagHistoricoRubricaRelVinc RV
              WHERE RV.CdFolhaPagamento = pCdFolhaPagamento
                AND RV.CdVinculo = pCdVinculo
              GROUP BY RV.CdFolhaPagamento,
                       RV.CdVinculo,
                       RV.CdRubricaAgrupamento,
                       RV.NuSufixoRubrica,
                       RV.CdRubricaTotalizadoraVantagem,
                       RV.CdVantagemPecuniaria,
                       RV.CdIncorporacaoAtivo,
                       RV.VlMinRecebIncorp,
                       RV.FlVigenciaPagamento,
                       RV.FlAtualizacaoConstante,
                       RV.CdLancamentofinanceiro,
                       RV.QtParcelas,
                       RV.CdTipoOrigemRubrica,
                       RV.DeIndiceContraCheque,
                       RV.CdProcessoPagRetroativo,
                       RV.CdHistSentencaJudicial,
                       RV.NuAnoMesOrigem,
                       RV.CdProcessoRestituicaoErario,
                       RV.CDEXPRESSAOFORMCALC
             HAVING((SUM(RV.VlProporcional) > 0) OR (nvl(RV.VlMinRecebIncorp, 0) > 0))) S
      ON (D.CdFolhaPagamento = S.CdFolhaPagamento AND D.CdRubricaAgrupamento = S.CdRubricaAgrupamento AND D.CdVinculo = S.CdVinculo AND D.NuSufixoRubrica = S.NuSufixoRubrica)

      WHEN MATCHED THEN

        UPDATE
           SET D.VlPagamento                   = D.VlPagamento + S.VlPago,
               D.VlIndiceRubrica               = /*CASE
                                                                                                                 WHEN D.VlIndiceRubrica = S.VlIndice THEN
                                                                                                                   D.VlIndiceRubrica
                                                                                                                 ELSE*/ S.VlIndice /* END*/,
               D.CdRubricaTotalizadoraVantagem = S.CdRubricaTotalizadoraVantagem,
               D.CdVantagemPecuniaria          = S.CdVantagemPecuniaria,
               D.CdIncorporacaoAtivo           = S.CdIncorporacaoAtivo,
               D.VlMinRecebIncorp              = S.VlMinRecebIncorp,
               D.FlVigenciaPagamento           = S.FlVigenciaPagamento,
               D.FlAtualizacaoConstante        = S.FlAtualizacaoConstante,
               D.CdLancamentoFinanceiro        = S.CdLancamentoFinanceiro,
               D.CdTipoOrigemRubrica           = S.CdTipoOrigemRubrica,
               D.CdTipoIndice                  = S.CdTipoIndice,
               D.CdProcessoPagRetroativo       = S.CdProcessoPagRetroativo,
               D.CdHistSentencaJudicial        = S.CdHistSentencaJudicial,
               D.NuAnoMesOrigem                = S.NuAnoMesOrigem,
               D.CdProcessoRestituicaoErario   = S.CdProcessoRestituicaoErario,
               D.CDEXPRESSAOFORMCALC           = S.CDEXPRESSAOFORMCALC

      WHEN NOT MATCHED THEN

        INSERT
          (CdHistoricoRubricaVinculo,
           CdFolhaPagamento,
           CdRubricaAgrupamento,
           CdVinculo,
           NuSufixoRubrica,
           CdLancamentoFinanceiro,
           VlPagamento,
           QtParcelas,
           VlIndiceRubrica,
           CdRubricaTotalizadoraVantagem,
           CdVantagemPecuniaria,
           CdIncorporacaoAtivo,
           VlMinRecebIncorp,
           FlVigenciaPagamento,
           FlAtualizacaoConstante,
           CdTipoOrigemRubrica,
           DtUltAlteracao,
           CdTipoIndice,
           DeIndiceContraCheque,
           CdProcessoPagRetroativo,
           CdHistSentencaJudicial,
           NuAnoMesOrigem,
           CdProcessoRestituicaoErario,
           CDEXPRESSAOFORMCALC)
        VALUES
          (spaghistoricorubricavinculo.NEXTVAL,
           pCdFolhaPagamento,
           S.CdRubricaAgrupamento,
           S.CdVinculo,
           S.NuSufixoRubrica,
           S.CdLancamentoFinanceiro,
           S.vlPago,
           S.QtParcelas,
           S.vlIndice,
           S.CdRubricaTotalizadoraVantagem,
           S.CdVantagemPecuniaria,
           S.CdIncorporacaoAtivo,
           S.VlMinRecebIncorp,
           S.FlVigenciaPagamento,
           S.FlAtualizacaoConstante,
           S.CdTipoOrigemRubrica,
           systimestamp,
           S.CdTipoIndice,
           S.DeIndiceContraCheque,
           S.CdProcessoPagRetroativo,
           S.CdHistSentencaJudicial,
           S.NuAnoMesOrigem,
           S.CdProcessoRestituicaoErario,
           S.CDEXPRESSAOFORMCALC); --salva apenas para a rubrica 05-0260

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    /* PENDENCIA

    Verificar: quando o valor dos indices dos historicos para uma mesma
    rubrica sao diferentes, o valor indice nao deve ser gerado. */

    PInsereTodasRVs;

    IF XTMPAG_VAR.vgFolha.cdAgrupamento = 176 AND XTMPAG_VAR.vgCCO.COUNT > 1 THEN

      UPDATE EPAGHISTORICORUBRICAVINCULO RV
         SET RV.VLINDICERUBRICA = (SELECT SUM(RR.VLINDICERUBRICA)
                                    FROM EPAGHISTORICORUBRICARELVINC RR
                                   WHERE RR.CDVINCULO = RV.CDVINCULO
                                     AND RR.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
                                     AND RR.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO)
       WHERE RV.CDVINCULO = pCdVinculo
         AND RV.CDFOLHAPAGAMENTO = pCdFolhaPagamento
         AND RV.CDRUBRICAAGRUPAMENTO IN (select V.cdrubricaagrupamento
                                          from vpagrubrica v
                                         where v.nurubrica = 5
                                           and v.cdtiporubrica = 1
                                           and v.cdagrupamento = XTMPAG_VAR.vgFolha.cdAgrupamento);

      UPDATE EPAGHISTORICORUBRICAVINCULO RV
         SET RV.VLINDICERUBRICA = (SELECT SUM(RR.VLINDICERUBRICA)
                                    FROM EPAGHISTORICORUBRICARELVINC RR
                                   WHERE RR.CDVINCULO = RV.CDVINCULO
                                     AND RR.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
                                     AND RR.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO)
       WHERE RV.CDVINCULO = pCdVinculo
         AND RV.CDFOLHAPAGAMENTO = pCdFolhaPagamento
         AND RV.CDRUBRICAAGRUPAMENTO IN (select V.cdrubricaagrupamento
                                          from vpagrubrica v
                                         where v.nurubrica = 157
                                           and v.cdtiporubrica = 1
                                           and v.cdagrupamento = XTMPAG_VAR.vgFolha.cdAgrupamento);
    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              XTMPAG_VAR.vCdHistParamCalc,
                              XTMPAG_VAR.vCdPessoa,
                              'Erro ao jogar rubricas no historico de pagamento do vinculo: ' ||
                              SQLERRM,
                              XTMPAG_VAR.vgCdVinculo);
  END;

  /*-----------------------------------------------------------------------------------------
  --   Objetivo: Definir a ordem de execucao das formulas e bases de calculo
  -----------------------------------------------------------------------------------------*/
  PROCEDURE PDefinirOrdemFCalculo(pCalculo   IN rCalculo,
                                  pFolha     IN XTMPAG_TIPO.rFolha,
                                  pCdVinculo IN INTEGER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    -- Percorrer dependencias para assinalar ordem de execucao

    FOR rec IN (SELECT HRV.CdRubricaAgrupamento,
                       HRV.rowid as nuRowid,
                       RORD.NuOrdem
                  FROM EPagHistoricoRubricaRelVinc HRV,
                       ECalRubricaAgrupamentoOrdem RORD
                 WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                   AND HRV.CdVinculo = pCdVinculo
                   AND HRV.NuOrdemCalculo = 0
                   AND HRV.VlProporcional IS NULL
                   AND RORD.CdCalculoPai = pCalculo.CdCalculoPai
                   AND RORD.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
                   AND RORD.NUVERSAOBASECALC =
                       nvl(pFolha.NuVersaoBaseCalculo, XTMPAG_TIPO.cn1)
                   AND RORD.NUVERSAOFORMCALC =
                       nvl(pFolha.NuVersaoFormulaCalculo, XTMPAG_TIPO.cn1)) LOOP

      -- IF XTMPAG_VAR.vgRubrica (rec.CdRubricaAgrupamento).NuOrdemCalculo IS NOT NULL THEN

      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET nuOrdemCalculo = REC.NuOrdem
       WHERE rowid = rec.nuRowid;

    -- END IF;

    END LOOP;

    -- No Vinculo
 
    FOR rec IN (SELECT HRV.CdRubricaAgrupamento,
                       HRV.rowid as nuRowid,
                       RORD.NuOrdem
                  FROM EPagHistoricoRubricaVinculo HRV,
                       ECalRubricaAgrupamentoOrdem RORD
                 WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                   AND HRV.CdVinculo = pCdVinculo
                   AND HRV.NuOrdemCalculo = 0
                   AND RORD.CdCalculoPai = pCalculo.CdCalculoPai
                   AND RORD.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
                   AND RORD.NUVERSAOBASECALC =
                       nvl(pFolha.NuVersaoBaseCalculo, XTMPAG_TIPO.cn1)
                   AND RORD.NUVERSAOFORMCALC =
                       nvl(pFolha.NuVersaoFormulaCalculo, XTMPAG_TIPO.cn1)) LOOP
 
      -- IF XTMPAG_VAR.vgRubrica (rec.CdRubricaAgrupamento).NuOrdemCalculo IS NOT NULL THEN
 
      UPDATE EPagHistoricoRubricaVinculo HRV
         SET nuOrdemCalculo = REC.NuOrdem
       WHERE rowid = rec.nuRowid;
 
    -- END IF;
 
    END LOOP;

  END;

  PROCEDURE PDefinirOrdemFCalculoPassado(pFolha     IN XTMPAG_TIPO.rFolha,
                                         pCdVinculo IN INTEGER) IS

    TYPE rCaminhoRA IS RECORD(
      ChavePai INTEGER,
      nuRowid  ROWID,
      cdRAPai  INTEGER,
      cdRADep  INTEGER);

    TYPE rNoRA IS RECORD(
      chave   INTEGER,
      nuRowid rowid,
      cdRA    INTEGER,
      qtDep   INTEGER,
      nuOrdem INTEGER);

    TYPE tCaminhoRA is table of rCaminhoRA index by binary_integer;
    TYPE tNoRA is table of rNoRA index by binary_integer;

    n             INTEGER;
    vCaminhoRA    tCaminhoRA;
    vCaminhoRAAux tCaminhoRA;
    vNoRA         tNoRA;
    vMensagem     VARCHAR2(100);
    -------  Procedures Internas ---------

    /*-----------------------------------------------------------------------------------------
          Objetivo: Adicionar Rubrica Agrupamento a array para Ordenacao
    -----------------------------------------------------------------------------------------*/

    PROCEDURE PAdicionarRAOrdenacao(pNoRA         IN OUT tNoRA,
                                    pCaminhoRA    IN OUT tCaminhoRA,
                                    pCaminhoRAAux IN tCaminhoRA) IS

      vCaminhoCont INTEGER;
      vChavePai    INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF pCaminhoRAAux.COUNT > 0 THEN

        FOR i in pCaminhoRAAux.FIRST .. pCaminhoRAAux.LAST LOOP

          vChavePai := pCaminhoRAAux(i).ChavePai;

          IF NOT pNoRa.EXISTS(vChavePai) THEN
            pNoRa(vChavePai).NuRowid := pCaminhoRAAux(i).NuRowid;
            pNoRa(vChavePai).chave := vChavePai;
            pNoRa(vChavePai).cdRA := pCaminhoRAAux(i).CdRaPai;
            pNoRa(vChavePai).nuOrdem := 0;
            pNoRa(vChavePai).qtDep := 0;
          END IF;

          pNoRa(vChavePai).qtDep := pNoRa(vChavePai).qtDep + 1;

          vCaminhoCont := NVL(pCaminhoRA.LAST, 0) + 1;

          pCaminhoRA(vCaminhoCont).ChavePai := vChavePai;
          pCaminhoRA(vCaminhoCont).cdRaPai := pCaminhoRAAux(i).CdRaPai;
          pCaminhoRA(vCaminhoCont).cdRaDep := pCaminhoRAAux(i).CdRaDep;

        END LOOP;
      END IF;

    END;

    /*-----------------------------------------------------------------------------------------
          Objetivo: Ordenar Rubrica Agrupamento

          -- Chave   - cdHistoricoRubricaRelVinc
          -- cdRA    - cdRubricaAgrupamento
          -- nuRowid - rowId de ePagHistoricoRubricaRelVinc
    -----------------------------------------------------------------------------------------*/

    PROCEDURE POrdenarRAOrdenacao(pNoRA      IN OUT tNoRA,
                                  pCaminhoRA IN OUT tCaminhoRA,
                                  pMensagem  OUT VARCHAR2) IS

      bExisteDependencia BOOLEAN;
      bExiste            BOOLEAN;
      bRenumerou         BOOLEAN;
      vChaveDependencia  INTEGER;
      vOrdem             INTEGER;
      c                  INTEGER;
      n                  INTEGER;
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vOrdem := 1;

      bRenumerou         := TRUE;
      bExisteDependencia := TRUE;

      WHILE (bExisteDependencia AND bRenumerou) LOOP

        bRenumerou         := FALSE;
        bExisteDependencia := FALSE;

        -- Percorrer todos os caminhos com destino sem dependencias

        c := pCaminhoRA.FIRST;
        WHILE c IS NOT NULL LOOP

          bExiste := false;
          n       := pNoRA.FIRST;
          WHILE n IS NOT NULL LOOP

            IF pNoRA(n).cdRA = pCaminhoRA(c).cdRaDep THEN
              -- Encontrou dependente
              IF pNoRA(n).nuOrdem = 0 THEN
                -- ainda nao renumerado, contar como dependencia
                bExiste := TRUE;
                EXIT; -- so sai depois de percorrer tudo, pois pode ter mais de uma ocorrencia
              end if;
            END IF;

            n := pNoRA.NEXT(n); -- get subscript of next element
          END LOOP;

          IF NOT bExiste THEN
            -- Nao Encontrou o dependente, excluir caminho e subtrair dependencias do no pai
            pNoRa(pCaminhoRA(c).chavePai).qtDep := pNoRa(pCaminhoRA(c).chavePai)
                                                   .qtDep - 1;
            pCaminhoRA.DELETE(c);
          END IF;
          c := pCaminhoRA.NEXT(c);

        END LOOP;

        -- Indicar ordem dos nos sem dependentes

        vOrdem := vOrdem + 1;

        n := pNoRA.FIRST;
        WHILE n IS NOT NULL LOOP

          IF pNoRA(n).NuOrdem = 0 THEN
            -- Nao ordenado ainda

            IF pNoRA(n).qtDep = 0 THEN
              pNoRA(n).NuOrdem := vOrdem;
              bRenumerou := TRUE;
            ELSE
              vChaveDependencia  := pNoRA(n).cdRA;
              bExisteDependencia := TRUE;
            END IF;

          END IF;
          n := pNoRA.NEXT(n); -- get subscript of next element
        END LOOP;

      END LOOP;

      pMensagem := null;
      IF bExisteDependencia THEN
        -- Saiu deixando dependencias, formula circular

        pMensagem := 'Rubrica ';

        -- montar mensagem de erro
        bExiste := TRUE;

        WHILE bExiste LOOP
          /*
           pMensagem := pMensagem || ' => ' || vChaveDependencia  || ' ';
          */

          pMensagem := pMensagem || ' => ' ||
                       LPAD(XTMPAG_VAR.vgRubrica(vChaveDependencia)
                            .CdTipoRubrica,
                            2,
                            '0') || '-' || LPAD(XTMPAG_VAR.vgRubrica(vChaveDependencia)
                                                .NuRubrica,
                                                4,
                                                '0') || ' ';
          bExiste   := FALSE;
          c         := pCaminhoRA.FIRST;
          WHILE c IS NOT NULL LOOP

            IF pCaminhoRA(c).cdRaPai = vChaveDependencia THEN
              -- encontrou no inedito com dependencia
              vChaveDependencia := pCaminhoRA(c).cdRaDep;
              bExiste           := TRUE;
              pCaminhoRA.DELETE(c);
              EXIT;
            END IF;
            c := pCaminhoRA.NEXT(c);

          END LOOP;

        END LOOP;

      END IF;

    END;

    -------  Bloco Principal ---------

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    -- Registrar as rubricas sem dependencia

    UPDATE EPagHistoricoRubricaRelVinc HRV
       SET NuOrdemCalculo = 1
     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo
       AND HRV.NuOrdemCalculo = 0
       AND HRV.VlProporcional IS NOT NULL; -- tem valor

    -- Adicionar as dependencias a ordenar

    -- Verifica se a rubrica da relacao de vinculo possui alguma formula de calculo onde
    -- exista o mneumonico "RUB" com alguma outra rubrica da relacao de vinculo sem ordem
    -- de calculo (com dependencia)

    SELECT DISTINCT HRVO.Cdhistoricorubricarelvinc,
                    HRVO.rowid                     as nuRowId,
                    HRVO.CdRubricaAgrupamento      as CdRAPai,
                    HRVD.CdRubricaAgrupamento      as CdRADep
      BULK COLLECT
      INTO vCaminhoRAAux
      FROM EPagHistoricoRubricaRelVinc HRVO
     INNER JOIN EPagHistoricoRubricaRelVinc HRVD
        ON HRVO.CdFolhaPagamento = HRVD.CdFolhaPagamento
       AND HRVO.CdVinculo = HRVD.CdVinculo
       AND HRVO.NuOrdemCalculo = 0
       AND HRVO.VlProporcional IS NULL
     INNER JOIN EPagFormCalcBlocoExpRubAgrup FCBA
        ON FCBA.CdRubricaAgrupamento = HRVD.CdRubricaAgrupamento
     INNER JOIN EpagFormulaCalcBlocoExpressao FBE
        ON FCBA.CdFormulaCalcBlocoExpressao =
           FBE.CdFormulaCalcBlocoExpressao
     INNER JOIN EPagFormulaCalculoBloco FCB
        ON FCB.CdFormulaCalculoBloco = FBE.CdFormulaCalculoBloco
       AND FCB.CdExpressaoFormCalc = HRVO.CdExpressaoFormCalc
     WHERE HRVO.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRVO.CdVinculo = pCdVinculo
       AND HRVO.NuOrdemCalculo = 0
       AND HRVO.VlProporcional IS NULL;

    PAdicionarRAOrdenacao(vNoRa, vCaminhoRA, vCaminhoRAAux);

    -- Verifica se a rubrica do vinculo possui alguma formula de calculo onde
    -- exista o mneumonico "BAS" com alguma outra rubrica do vinculo sem ordem
    -- de calculo (com dependencia)

    SELECT DISTINCT HRVO.Cdhistoricorubricarelvinc,
                    HRVO.rowid                     as nuRowId,
                    HRVO.CdRubricaAgrupamento      as CdRAPai,
                    HRVD.CdRubricaAgrupamento      as CdRADep
      BULK COLLECT
      INTO vCaminhoRAAux
      FROM EPagHistoricoRubricaRelVinc HRVO
     INNER JOIN EPagHistoricoRubricaRelVinc HRVD
        ON HRVO.CdFolhaPagamento = HRVD.CdFolhaPagamento
       AND HRVO.CdVinculo = HRVD.CdVinculo
       AND HRVD.NuOrdemCalculo = 0
       AND HRVD.VlProporcional IS NULL
     INNER JOIN EPagFormulaCalculobloco FCB
        ON FCB.CdExpressaoFormCalc = HRVO.CdExpressaoFormCalc
     INNER JOIN EpagFormulaCalcBlocoExpressao FBE
        ON FBE.CdFormulaCalculoBloco = FCB.CdFormulaCalculoBloco
       AND FBE.CdBaseCalculo IS NOT NULL
    --    INNER JOIN ePagBaseCalculo BC
    --            ON FBE.CdBaseCalculo = BC.CdBaseCalculo
     INNER JOIN EpagBaseCalculoVersao BCV
        ON FBE.CdBaseCalculo = BCV.CdBaseCalculo --  ON BC.CdBaseCalculo = BCV.CdBaseCalculo
       AND BCV.NuVersao = pFolha.NuVersaoBaseCalculo
     INNER JOIN EPagHistBaseCalculo HBC
        ON HBC.CdVersaoBaseCalculo = BCV.CdVersaoBaseCalculo
     INNER JOIN EPagBaseCalculoBloco BCB
        ON HBC.CdHistBaseCalculo = BCB.Cdhistbasecalculo
       AND ((HBC.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
           (HBC.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
           HBC.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
           (HBC.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
           (HBC.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
           HBC.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
           HBC.NuAnoFimVigencia IS NULL))
     INNER JOIN Epagbasecalculoblocoexpressao BCE
        ON BCB.CdBaseCalculoBloco = BCE.CdBaseCalculoBloco
     INNER JOIN EPagBaseCalcBlocoExprRubAgrup BCRA
        ON BCE.CdBaseCalculoBlocoExpressao =
           BCRA.CdBaseCalculoBlocoExpressao
       AND BCRA.CdRubricaAgrupamento = HRVD.CdRubricaAgrupamento
     WHERE HRVO.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRVO.CdVinculo = pCdVinculo
       AND HRVO.NuOrdemCalculo = 0
       AND HRVO.VlProporcional IS NULL;

    PAdicionarRAOrdenacao(vNoRa, vCaminhoRA, vCaminhoRAAux);

    -- Verifica se na base de calculo da rubrica totalizadora da relacao de vinculo
    -- existe o mneumonico "RUB" com alguma rubrica da relacao de vinculo sem ordem
    -- de calculo (com dependencia)

    SELECT DISTINCT HRVO.Cdhistoricorubricarelvinc,
                    HRVO.rowid                     as nuRowId,
                    HRVO.CdRubricaAgrupamento      as CdRAPai,
                    HRVD.CdRubricaAgrupamento      as CdRADep
      BULK COLLECT
      INTO vCaminhoRAAux
      FROM EPagHistoricoRubricaRelVinc HRVO
     INNER JOIN EPagHistoricoRubricaRelVinc HRVD
        ON HRVO.CdFolhaPagamento = HRVD.CdFolhaPagamento
       AND HRVO.CdVinculo = HRVD.CdVinculo
       AND HRVD.NuOrdemCalculo = 0
       AND HRVD.VlProporcional IS NULL
     INNER JOIN EPagRubricaAgrupamento RA
        ON RA.CdRubricaagrupamento = HRVO.CdRubricaAgrupamento
     INNER JOIN EpagBaseCalculoVersao BCV
        ON RA.CdBaseCalculo = BCV.CdBaseCalculo
       AND BCV.NuVersao = pFolha.NuVersaoBaseCalculo
     INNER JOIN EPagHistBaseCalculo HBC
        ON HBC.CdVersaoBaseCalculo = BCV.CdVersaoBaseCalculo
       AND ((HBC.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
           (HBC.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
           HBC.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
           (HBC.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
           (HBC.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
           HBC.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
           HBC.NuAnoFimVigencia IS NULL))
     INNER JOIN EPagBaseCalculoBloco BCB
        ON HBC.CdHistBaseCalculo = BCB.Cdhistbasecalculo
     INNER JOIN EPagBaseCalculoBlocoExpressao BCE
        ON BCB.CdBaseCalculoBloco = BCE.CdBaseCalculoBloco
     INNER JOIN Epagbasecalcblocoexprrubagrup BCRA
        ON BCE.CdBaseCalculoBlocoExpressao =
           BCRA.CdBaseCalculoBlocoExpressao
       AND BCRA.CdRubricaAgrupamento = HRVD.CdRubricaAgrupamento
     WHERE HRVO.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRVO.CdVinculo = pCdVinculo
       AND HRVO.NuOrdemCalculo = 0
       AND HRVO.VlProporcional IS NULL;

    PAdicionarRAOrdenacao(vNoRa, vCaminhoRA, vCaminhoRAAux);

    -- Verifica se a rubrica da relacao de vinculo esta associada a uma rubrica totalizadora
    -- de uma vantagem pecuniaria sem ordem de calculo (com dependencia)

    SELECT DISTINCT HRVO.Cdhistoricorubricarelvinc,
                    HRVO.rowid                     as nuRowId,
                    HRVO.Cdrubricaagrupamento      as CdRAPai,
                    HRVD.CdRubricaAgrupamento      as CdRADep
      BULK COLLECT
      INTO vCaminhoRAAux
      FROM EPagHistoricoRubricaRelVinc HRVO
     INNER JOIN EPagHistoricoRubricaRelVinc HRVD
        ON HRVO.CdFolhaPagamento = HRVD.CdFolhaPagamento
       AND HRVO.CdVinculo = HRVD.CdVinculo
       AND HRVO.CdRubricaTotalizadoraVantagem = HRVD.Cdrubricaagrupamento
       AND HRVD.NuOrdemCalculo = 0
       AND HRVD.VlProporcional IS NULL
     WHERE HRVO.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRVO.CdVinculo = pCdVinculo
       AND HRVO.NuOrdemCalculo = 0
       AND HRVO.VlProporcional IS NULL;

    PAdicionarRAOrdenacao(vNoRa, vCaminhoRA, vCaminhoRAAux);

    -- Chamar Ordenacao

    POrdenarRAOrdenacao(vNoRa, vCaminhoRA, vMensagem);

    IF vMensagem IS NOT NULL THEN
      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              XTMPAG_VAR.vCdHistParamCalc,
                              XTMPAG_VAR.vCdPessoa,
                              'Processamento abortado. Encontrada dependencia mutua entre formulas/bases: ' ||
                              vMensagem,
                              XTMPAG_VAR.vgCdVinculo);

      IF XTMPAG_VAR.vCdHistParamCalc = 0 THEN

        RAISE XTMPAG_VAR.eDependenciaFormula;

      END IF;

    END IF;

    -- Percorrer dependencias para assinalar ordem de execucao

    n := vNoRA.FIRST;
    WHILE n IS NOT NULL LOOP

      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET nuOrdemCalculo = vNoRA(n).nuOrdem
       WHERE rowid = vNoRA(n).nuRowid;

      n := vNoRA.NEXT(n); -- get subscript of next element
    END LOOP;

  END;

  PROCEDURE PReprocessaFormulasBases(pFolha           IN XTMPAG_TIPO.rFolha,
                                     pCdVinculo       IN INTEGER,
                                     pTpProcessamento IN INTEGER DEFAULT 1) IS

  Vrubrica1480 integer;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

  Vrubrica1480 := XTMPAG_geral.fretornarubrica(1, 1, 1480);

    IF pTpProcessamento = 1 THEN

      -- Seta para NULL todos os valores de rubricas nas relacoes de vinculo com expressao associada

      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET HRV.VlIntegral     = NULL,
             HRV.VlProporcional = NULL,
             HRV.VlReal         = NULL
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdExpressaoFormCalc IS NOT NULL
         AND HRV.CDVINCULO != 404586
         AND HRV.Cdrubricaagrupamento != Vrubrica1480;

    END IF;

    -- Deletar o epgahistoricorubricavinculo

    DELETE FROM epagHistoricoRubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo;

    -- Seta para NULL os valores das rubricas totalizadoras
    -- Nr da solicitacao: 7423/2015, excecao para bases de calculo lancadas em financeiro.

    UPDATE EPagHistoricoRubricaRelVinc HRV
       SET HRV.VlIntegral     = NULL,
           HRV.VlProporcional = NULL,
           HRV.VlReal         = NULL
     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo
       AND HRV.Cdlancamentofinanceiro IS NULL
       AND EXISTS
     (SELECT CdRubricaAgrupamento
              FROM EPagRubricaAgrupamento RA
             INNER JOIN EPagRubrica R
                ON R.CdRubrica = RA.CdRubrica
             WHERE R.CdTipoRubrica = XTMPAG_TIPO.cnTpRubTotalizadora
               AND HRV.CdRubricaAgrupamento = RA.CdRubricaAgrupamento);

    XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pTpProcessamento => pTpProcessamento);

    PConsolidaPagVinculo(pFolha.CdFolhaPagamento, pCdVinculo);

    IF XTMPAG_VAR.vgVlBase1467 > 0 THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseRateio,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => XTMPAG_VAR.vgVlBase1467,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

    END IF;

  END;

  /*-----------------------------------------------------------------------

  /*-----------------------------------------------------------------------*/

  PROCEDURE PProcessaRubricaExcludente(pFolha     IN XTMPAG_TIPO.rFolha,
                                       pCdVinculo IN INTEGER) IS

    bPrimeiro BOOLEAN;

    vvlDiferenca NUMBER(13, 2);

    vvlMenorValor NUMBER(13, 2);

    bReprocessa BOOLEAN;

    FUNCTION FRetornaDiferencaRubrica(pCdRubricaAgrupExcl       IN INTEGER,
                                      pCdRubricaAgrupOutraRubEx IN INTEGER)

     RETURN NUMBER IS

      vVlRubExcludente NUMBER(13, 2);
      vVlOutraRub      NUMBER(13, 2);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      BEGIN

        SELECT HRV.VlPagamento
          INTO vVlRubExcludente
          FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdrubricaAgrupamento = pCdRubricaAgrupExcl;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          RETURN NULL;

      END;

      BEGIN

        SELECT HRV.VlPagamento
          INTO vVlOutraRub
          FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdrubricaAgrupamento = pCdRubricaAgrupOutraRubEx;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          RETURN NULL;

      END;

      RETURN ABS(vVlRubExcludente - vVlOutraRub);

    EXCEPTION

      WHEN OTHERS THEN

        RETURN NULL;

    END;

    FUNCTION FExisteRubricaPagDif(pCdRubricaAgrupamentoPagDif IN INTEGER)

     RETURN BOOLEAN IS

      vCont INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT COUNT(*)
        INTO vCont
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamentoPagDif;

      IF vCont > 0 THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN FALSE;

    END;

    FUNCTION FRetornaMenorValor(pCdRubricaAgrupExcl       IN INTEGER,
                                pCdRubricaAgrupOutraRubEx IN INTEGER)

     RETURN NUMBER IS

      vVlRubExcludente INTEGER;

      vVlOutraRub INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      BEGIN

        SELECT HRV.VlPagamento
          INTO vVlRubExcludente
          FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdrubricaAgrupamento = pCdRubricaAgrupExcl;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          RETURN NULL;

      END;

      BEGIN

        SELECT HRV.VlPagamento
          INTO vVlOutraRub
          FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupOutraRubEx;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          RETURN NULL;
      END;

      IF vVlRubExcludente > vVlOutraRub THEN

        RETURN vVlOutraRub;

      ELSE

        RETURN vVlRubExcludente;

      END IF;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

    bReprocessa := FALSE;

    IF XTMPAG_VAR.vgRubricaExcludente.COUNT > 0 THEN

      FOR i IN XTMPAG_VAR.vgRubricaExcludente.FIRST .. XTMPAG_VAR.vgRubricaExcludente.LAST LOOP

        IF XTMPAG_VAR.vgRubricaExcludente.EXISTS(i) THEN

          CASE XTMPAG_VAR.vgRubricaExcludente(i).InTipoRegraRubExcludente

            WHEN 1 THEN
              -- Paga a maior

              bPrimeiro := TRUE;

              FOR vRub IN (SELECT HRV.CdRubricaAgrupamento
                             FROM EPagHistoricoRubricaVinculo HRV
                            WHERE HRV.CdFolhaPagamento =
                                  pFolha.CdFolhaPagamento
                              AND HRV.CdVinculo = pCdVinculo
                              AND (HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgRubricaExcludente(i)
                                  .CdRubricaAgrupamentoExcludente OR
                                  HRV.CdRubricaAgrupamento IN
                                  (SELECT CdRubricaAgrupamento
                                      FROM EPagOutraRubricaExcludente ORE
                                     WHERE ORE.CdRubricaExcludente = XTMPAG_VAR.vgRubricaExcludente(i)
                                          .CdRubricaExcludente))
                            ORDER BY HRV.VlPagamento DESC) LOOP

                IF bPrimeiro THEN

                  bPrimeiro := FALSE;

                ELSE

                  DELETE FROM EPagHistoricoRubricaRelVinc HRV
                   WHERE HRV.CdRubricaAgrupamento =
                         vRub.CdRubricaAgrupamento
                     AND HRV.CdFolhaPagamento =
                         pFolha.CdFolhaPagamento
                     AND HRV.CdVinculo = pCdVinculo;

                  bReprocessa := TRUE;

                END IF;

              END LOOP;

            WHEN 2 THEN
              -- Paga diferenca entre ambas

              vvlDiferenca := FRetornaDiferencaRubrica(XTMPAG_VAR.vgRubricaExcludente(i)
                                                       .CdRubricaAgrupamentoExcludente,
                                                       XTMPAG_VAR.vgRubricaExcludente(i)
                                                       .CdRubricaAgrupamentoOutraRubEx);

              IF vvlDiferenca IS NOT NULL THEN

                CASE XTMPAG_VAR.vgRubricaExcludente(i).InRubricaPermanece

                  WHEN 1 THEN
                    -- Permanece a primeira rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlDiferenca
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoExcludente;

                    XTMPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                XTMPAG_VAR.vgRubricaExcludente(i)
                                                .CdRubricaAgrupamentoOutraRubEx);

                    bReprocessa := TRUE;

                  WHEN 2 THEN
                    -- Permanece a segunda rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlDiferenca
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoOutraRubEx;

                    XTMPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                XTMPAG_VAR.vgRubricaExcludente(i)
                                                .CdRubricaAgrupamentoExcludente);

                    bReprocessa := TRUE;

                  WHEN 3 THEN
                    -- A diferenca e paga numa terceira rubrica

                    IF NOT
                        FExisteRubricaPagDif(XTMPAG_VAR.vgRubricaExcludente(i)
                                             .CdRubricaAgrupamentoPagDif) THEN

                      DELETE FROM EPagHistoricoRubricaRelVinc HRV
                       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                         AND HRV.CdVinculo = pCdVinculo
                         AND HRV.CdRubricaAgrupamento IN
                             (XTMPAG_VAR.vgRubricaExcludente(i)
                              .CdRubricaAgrupamentoOutraRubEx,
                              XTMPAG_VAR.vgRubricaExcludente(i)
                              .CdRubricaAgrupamentoExcludente);

                      XTMPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                            pCdVinculo            => pCdVinculo,
                                                            pCdRelacaoVinculo     => XTMPAG_VAR.vgRelVincPrincipal.Tipo,
                                                            pCdHistRelacaoVinculo => XTMPAG_VAR.vgRelVincPrincipal.CdHist,
                                                            pCdExpressaoFormCalc  => NULL,
                                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgRubricaExcludente(i)
                                                                                     .CdRubricaAgrupamentoPagDif,
                                                            pVlIntegral           => vVlDiferenca,
                                                            pVlProporcional       => vVlDiferenca,
                                                            pNuSufixoRubrica      => 1);

                      bReprocessa := TRUE;

                    END IF;

                END CASE;

              END IF;

            WHEN 3 THEN
              -- Paga a menor

              vvlMenorValor := FRetornaMenorValor(XTMPAG_VAR.vgRubricaExcludente(i)
                                                  .CdRubricaAgrupamentoExcludente,
                                                  XTMPAG_VAR.vgRubricaExcludente(i)
                                                  .CdRubricaAgrupamentoOutraRubEx);

              IF vVlMenorValor IS NOT NULL THEN

                CASE XTMPAG_VAR.vgRubricaExcludente(i).InRubricaPermanece

                  WHEN 1 THEN
                    -- Permanece a primeira rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlMenorValor
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoExcludente;

                    XTMPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                XTMPAG_VAR.vgRubricaExcludente(i)
                                                .CdRubricaAgrupamentoOutraRubEx);

                  WHEN 2 THEN
                    -- Permanece a segunda rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlMenorValor
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoOutraRubEx;

                    XTMPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                XTMPAG_VAR.vgRubricaExcludente(i)
                                                .CdRubricaAgrupamentoExcludente);

                END CASE;

                bReprocessa := TRUE;

              END IF;

          END CASE;

        END IF;

        IF bReprocessa THEN

          PReprocessaFormulasBases(pFolha           => pFolha,
                                   pCdVinculo       => pCdVinculo,
                                   pTpProcessamento => 1);

        END IF;

      END LOOP;

    END IF;

    -- EXCLUI A BASE VALOR DA GRATIFICACAO DE PRODUTIVIDADE 09-9467 SE NÃO HOUVER PAGAMENTO DA PRODUTIVIDADE 01-0467
    IF XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                         pCdVinculo => XTMPAG_VAR.vgCdVinculo,
                                         pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,9467)) > 0
       THEN

       IF XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                            pCdVinculo => XTMPAG_VAR.vgCdVinculo,
                                            pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,467)) <= 0
          AND ((pFolha.NuAnoReferencia * 100) + pFolha.NuMesReferencia) >= 202101
         THEN

         DELETE epaghistoricorubricavinculo hv
          WHERE hv.cdvinculo = XTMPAG_var.vgcdvinculo
            AND hv.cdfolhapagamento =
                XTMPAG_var.vgfolha.cdfolhapagamento
            AND hv.cdrubricaagrupamento =
                XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,9467);

       END IF;

    END IF;

    XTMPAG_GERAL.PLogTrace('CAL - Rubrica Excludente',
                           null,
                           XTMPAG_VAR.vgTmInicio);

  END;

  FUNCTION FTrataImpeditivas(pCdFolhaPagamento     IN INTEGER,
                             pCdVinculo            IN INTEGER,
                             pCdRubricaAgrupamento IN INTEGER,
                             pFlTotalizadora       IN CHAR)

   RETURN BOOLEAN IS

    vRubrica XTMPAG_TIPO.rRubrica;

    FUNCTION FExisteImpedimento(pCdFolhaPagamento IN INTEGER,
                                pCdVinculo        IN INTEGER,
                                pRubrica          IN XTMPAG_TIPO.rRubrica)
      RETURN BOOLEAN IS

      vCont INTEGER;

      vCdHistRubrica INTEGER;

      vImpede BOOLEAN := FALSE;
      
      vCdFolhaAlternativa INTEGER;
      
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF XTMPAG_VAR.vgCdFolhaIndenizatoria > 0 THEN
        
        vCdFolhaAlternativa := XTMPAG_VAR.vgCdFolhaIndenizatoria;
        
      ELSE
        
        vCdFolhaAlternativa := pCdFolhaPagamento;
        
      END IF;
      
      IF pRubrica.InImpedimentoRubrica = '1' THEN

        /*Verifica se existem rubricas no conjunto de rubricas que
        impedem o recebimento desta .

        Se (vCont = 0) ent?o exclui o(s) pagamentos da rubrica            */

        SELECT COUNT(*)
          INTO vCont
          FROM EPagHistRubricaAgrupImpeditiva I
         WHERE I.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica
           AND NOT EXISTS
         (SELECT 1
                  FROM EPagHistoricoRubricaVinculo HRV
                 WHERE HRV.CdFolhaPagamento IN (pCdFolhaPagamento,vCdFolhaAlternativa)
                   AND HRV.CdVinculo = pCdVinculo
                   AND HRV.CdRubricaAgrupamento = I.CdRubricaAgrupamento
                   AND (HRV.VlPagamento > 0 OR
                       NVL(HRV.VlMinRecebIncorp, 0) > 0 OR
                       HRV.CdLancamentoFinanceiro IS NOT NULL));

        IF vCont = 0 THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      ELSIF pRubrica.InImpedimentoRubrica = '2' THEN

        /* Verifica se pelo menos uma rubrica no conjunto de rubricas que
        impedem o recebimento desta que n?o tenham sido pagas ao vinculo (vCont > 0)*/

        vCont := 0;

        BEGIN

          FOR f_impede in (SELECT HRV.CdRubricaAgrupamento
                             FROM EPagHistRubricaAgrupImpeditiva I
                            INNER JOIN EPagHistoricoRubricaVinculo HRV
                               ON HRV.CdRubricaAgrupamento =
                                  I.CdRubricaAgrupamento
                            WHERE I.CdHistRubricaAgrupamento =
                                  pRubrica.CdHistRubrica
                              AND HRV.CdFolhaPagamento IN (pCdFolhaPagamento,vCdFolhaAlternativa)
                              AND HRV.CdVinculo = pCdVinculo
                              AND (HRV.VlPagamento > 0 OR
                                  NVL(HRV.VlMinRecebIncorp, 0) > 0 OR
                                  HRV.CdLancamentoFinanceiro IS NOT NULL))

           LOOP

            vCdHistRubrica := XTMPAG_VAR.vgRubrica(f_impede.cdrubricaagrupamento)
                              .CdHistRubrica;

            vCont := 0;

            BEGIN

              SELECT HRV.CdRubricaAgrupamento
                INTO vCont
                FROM EPagHistRubricaAgrupImpeditiva I
               INNER JOIN EPagHistoricoRubricaVinculo HRV
                  ON HRV.CdRubricaAgrupamento = I.CdRubricaAgrupamento
                    -- Desconsiderar a propria rubrica
                 AND I.Cdrubricaagrupamento <>
                     pRubrica.CdRubricaAgrupamento
               WHERE I.CdHistRubricaAgrupamento = vCdHistRubrica
                 AND HRV.CdFolhaPagamento IN (pCdFolhaPagamento,vCdFolhaAlternativa)
                 AND HRV.CdVinculo = pCdVinculo
                 AND (HRV.VlPagamento > 0 OR
                     NVL(HRV.VlMinRecebIncorp, 0) > 0 OR
                     HRV.CdLancamentoFinanceiro IS NOT NULL)
                 AND ROWNUM < 2;

              -- A que impede tambem e impedida por outra, desconsiderar
              IF vCont = 0 then
                vImpede := TRUE;
                exit;
              END IF;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                vImpede := TRUE;

                exit;

            END;

          END LOOP;

          --Verificar se Rubrica Impeditiva e da Relacao de Vinculo Efetivo
          -- para uso posterior na exclus?o da rubrica
          IF vImpede = TRUE THEN

            BEGIN
              SELECT count(HRVINC.CDRELACAOVINCULO)
                INTO XTMPAG_VAR.vCdRelacaoRubImpeditiva
                FROM EPagHistRubricaAgrupImpeditiva IMP
               INNER JOIN EPagHistoricoRubricaRelVinc HRVINC
                  ON HRVINC.CdRubricaAgrupamento = IMP.CdRubricaAgrupamento
               WHERE IMP.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica
                 AND HRVINC.CdFolhaPagamento IN (pCdFolhaPagamento,vCdFolhaAlternativa)
                 AND HRVINC.CdVinculo = pCdVinculo
                 AND HRVINC.CDRELACAOVINCULO = 1  -- RELACAO DE EFETIVO
                 AND HRVINC.VLREAL > 0
                 AND HRVINC.VLINTEGRAL > 0.1; -- Existem LF com valor de 0,01 para desconsiderar

                 --servidores não efetivos do órgão, ou seja, que não recebem a rubrica em seu vínculo efetivo
                ---(recebem apenas por estarem em cargo comissionado no órgão) estarem contribuindo sobre o valor total da rubrica.

                /*IF pRubrica.CdRubricaAgrupamento =  XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,1,1468) AND
                    XTMPAG_VAR.bVinculoComCCO AND
                    XTMPAG_VAR.vgRelVincPrincipal.Tipo = 1 AND
                    XTMPAG_VAR.vgFolha.cdtipofolha = XTMPAG_TIPO.cnTpFolhaNormal AND
                    XTMPAG_var.vgValorCalculoRubrica(pRubrica.CdRubricaAgrupamento).vlcco = 0  AND
                    XTMPAG_var.vgValorCalculoRubrica(pRubrica.CdRubricaAgrupamento).vlcef = 0 and
                    XTMPAG_VAR.bVinculoComCEF and
                    XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                      pCdVinculo => XTMPAG_VAR.vgCdVinculo,
                                                      pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,1575)) = 0
                     THEN

                      XTMPAG_VAR.vCdRelacaoRubImpeditiva := 0;

             END IF;*/

            EXCEPTION

              WHEN NO_DATA_FOUND THEN
                XTMPAG_VAR.vCdRelacaoRubImpeditiva := 0;

            END;

            RETURN TRUE;
          ELSE

            RETURN FALSE;

          END IF;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            RETURN FALSE;

        END;

      ELSE

        RETURN FALSE;

      END IF;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vRubrica := XTMPAG_VAR.vgRubrica(pCdRubricaAgrupamento);

    IF (pFlTotalizadora = 'S' AND
       vRubrica.CdTipoRubrica = XTMPAG_TIPO.cnTpRubTotalizadora) OR
       (pFlTotalizadora = 'N' AND
       vRubrica.CdTipoRubrica <> XTMPAG_TIPO.cnTpRubTotalizadora) THEN

      IF vRubrica.lsRubImpeditiva.COUNT > 0 THEN

        IF FExisteImpedimento(pCdFolhaPagamento, pCdVinculo, vRubrica) THEN

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento,
                                      pCdVinculo,
                                      pCdRubricaAgrupamento,
                                      'S',
                                      vRubrica.FlPreservaValorIntegral);

          RETURN TRUE;

        END IF;

      END IF;

    END IF;

    RETURN FALSE;

  END;

  FUNCTION FTrataExigidas(pCdFolhaPagamento     IN INTEGER,
                          pCdVinculo            IN INTEGER,
                          pCdRubricaAgrupamento IN INTEGER,
                          pFlTotalizadora       IN CHAR)

   RETURN BOOLEAN IS

    vRubrica XTMPAG_TIPO.rRubrica;

    ------------------------------------------------------------------

    ------------------------------------------------------------------

    FUNCTION FCumpreExigencia(pCdFolhaPagamento IN INTEGER,
                              pCdVinculo        IN INTEGER,
                              pRubrica          IN XTMPAG_TIPO.rRubrica)
      RETURN BOOLEAN IS

      vCont INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF pRubrica.InRubricasExigidas = '1' THEN

        /*Verifica se existem rubricas no conjunto de rubricas que
        exigem o recebimento desta que nao tenham sido pagas ao vinculo.

        Se (vCont = 0) entao exclui o(s) pagamentos da rubrica            */

        SELECT COUNT(*)
          INTO vCont
          FROM EpagHistRubricaAgrupExigida E
         WHERE E.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica
           AND NOT EXISTS
         (SELECT 1
                  FROM EPagHistoricoRubricaVinculo HRV
                 WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
                   AND HRV.CdVinculo = pCdVinculo
                   AND HRV.CdRubricaAgrupamento = E.CdRubricaAgrupamento
                   AND (HRV.VlPagamento > 0 OR
                       NVL(HRV.VlMinRecebIncorp, 0) > 0 OR
                       HRV.CdLancamentoFinanceiro IS NOT NULL));

        IF vCont = 0 THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      ELSIF pRubrica.InRubricasExigidas = '2' THEN

        /*Verifica se pelo menos uma rubrica no conjunto de rubricas exigidas
        o recebimento desta que tenha sido pagas ao vinculo (vCont > 0)*/

        SELECT COUNT(*)
          INTO vCont
          FROM EPagHistRubricaAgrupExigida E
         WHERE E.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica
           AND EXISTS
         (SELECT 1
                  FROM EPagHistoricoRubricaVinculo HRV
                 WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
                   AND HRV.CdVinculo = pCdVinculo
                   AND HRV.CdRubricaAgrupamento = E.CdRubricaAgrupamento
                   AND (HRV.VlPagamento > 0 OR
                       NVL(HRV.VlMinRecebIncorp, 0) > 0 OR
                       HRV.CdLancamentoFinanceiro IS NOT NULL));

        IF vCont > 0 THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      ELSE

        RETURN TRUE;

      END IF;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vRubrica := XTMPAG_VAR.vgRubrica(pCdRubricaAgrupamento);

    IF (pFlTotalizadora = 'S' AND
       vRubrica.CdTipoRubrica = XTMPAG_TIPO.cnTpRubTotalizadora) OR
       (pFlTotalizadora = 'N' AND
       vRubrica.CdTipoRubrica <> XTMPAG_TIPO.cnTpRubTotalizadora) THEN

      IF vRubrica.lsRubExigida.COUNT > 0 THEN

        IF NOT FCumpreExigencia(pCdFolhaPagamento, pCdVinculo, vRubrica) THEN

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento,
                                      pCdVinculo,
                                      pCdRubricaAgrupamento,
                                      'S',
                                      vRubrica.FlPreservaValorIntegral);
          RETURN TRUE;

        END IF;

      END IF;

    END IF;

    RETURN FALSE;

    EXCEPTION
      WHEN OTHERS THEN
        RETURN FALSE;
  END;

  /*-----------------------------------------------------------------------
    Procedure PExpurgaRubricas

    Objetivo: Expurgar as rubricas de pagamento :

  /*-----------------------------------------------------------------------*/
  PROCEDURE PExpurgarRubricas(pFolha   IN XTMPAG_TIPO.rFolha,
                              pVinculo IN XTMPAG_TIPO.rVinculo) IS

    CURSOR cRubricaPaga IS

      SELECT CdRubricaAgrupamento
        FROM (SELECT HRV.CdRubricaAgrupamento,
                     MAX(HRV.NuOrdemCalculo) AS ORDEM
                FROM EPagHistoricoRubricaRelVinc HRV
               WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND HRV.CdVinculo = pVinculo.CdVinculo
                 AND ((HRV.VlProporcional > 0) OR
                     (NVL(HRV.VlMinRecebIncorp, 0) > 0))
                    -- Esta linha foi descomentada no dia 18/08/2011 para
                    -- nao aplicar a regra do expurga caso a rubrica tenha sido lancada em financeiro
                    -- Antes isto estava comentado e portanto expurgando sempre, porque dava problema no IPREV
                    -- Agora isto nao e problema porque ao lancar em financeiro pode-se informar o valor incidente para o IPREV
                 AND HRV.CdLancamentoFinanceiro IS NULL
               GROUP BY HRV.CdRubricaAgrupamento)
       ORDER BY ORDEM;

    CURSOR cPagVantagem IS

      SELECT HRV.CdRelacaoVinculo,
             HRV.CdHistoricoRubricaRelVinc,
             HRV.CdVantagemPecuniaria,
             HRV.CdRubricaTotalizadoraVantagem,
             0 AS VlTotalizadora
        FROM EPagHistoricoRubricaRelVinc HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pVinculo.CdVinculo
         AND HRV.CdRubricaTotalizadoraVantagem IS NOT NULL
         AND HRV.CdVantagemPecuniaria IS NOT NULL;

    TYPE rPagVantagem IS RECORD(
      CdRelacaoVinculo              INTEGER,
      CdHistoricoRubricaRelVinc     INTEGER,
      CdVantagemPecuniaria          INTEGER,
      CdRubricaTotalizadoraVantagem INTEGER,
      VlTotalizadora                NUMBER(13, 2));

    TYPE tPagVantagem IS TABLE OF rPagVantagem INDEX BY PLS_INTEGER;

    vPagVantagem tPagVantagem;

    bDeveExpurgar BOOLEAN DEFAULT TRUE;

    bDeveRecalcular BOOLEAN DEFAULT FALSE;

    bDeveRecVantagem BOOLEAN DEFAULT FALSE;

    bHouveExclusao BOOLEAN DEFAULT FALSE;

    i INTEGER;

    vVlBaseRecalc NUMBER(13, 2);

    vNuValorFixoVantagem NUMBER(13, 2);

    PROCEDURE PTratarExcecoesDeveRecalcular(pCdAgrupamento IN INTEGER,
                                            pCdRubricaAgrupamento IN INTEGER,
                                            pCdTipoFolha IN INTEGER) IS
      --01-0267-01 VP LEI COMP 83/93 FG
      vCdRubricaAgrupamento1_267 INTEGER;
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;
      vCdRubricaAgrupamento1_267 := XTMPAG_geral.fretornarubrica(pCdAgrupamento, 1, 267);
      IF pCdTipoFolha = XTMPAG_tipo.cnTpFolhaFunebre AND pCdRubricaAgrupamento = vCdRubricaAgrupamento1_267 THEN
       bDeveRecalcular := FALSE;
      END IF;
    END;

    FUNCTION FRetornaValorRubricaRV(pCdFolhaPagamento     IN INTEGER,
                                    pCdVinculo            IN INTEGER,
                                    pCdRubricaAgrupamento IN INTEGER,
                                    pCdRelacaoVinculo     IN INTEGER)
      RETURN NUMBER IS

      vVlRubrica NUMBER(13, 2);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT HRV.VlProporcional
        INTO vVlRubrica
        FROM EPagHistoricoRubricaRelVinc HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento
         AND HRV.CdRelacaoVinculo = pCdRelacaoVinculo
         AND ROWNUM < 2;

      RETURN vVlRubrica;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

    PROCEDURE PConsolida(pCdRubricaAgrupamento IN INTEGER) IS

      vRubrica XTMPAG_TIPO.rRubrica;

      vCdHistRelVinc INTEGER;

      vCdTipoOrigemRubrica INTEGER;

      vVlPagamento NUMBER(13, 2);

      vVlIndiceRubrica NUMBER(7, 4);

      vVlMinimoRecebimento NUMBER(13, 2);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vVlMinimoRecebimento := 0;

      vRubrica := XTMPAG_VAR.vgRubrica(pCdRubricaAgrupamento);

      IF vRubrica.FlConsolidaRubrica = 'S' THEN

        BEGIN

          SELECT SUM(HRV.vlPagamento),
                 SUM(HRV.VlIndiceRubrica),
                 MAX(HRV.Cdtipoorigemrubrica)
            INTO vVlPagamento, vVlIndiceRubrica, vCdTipoOrigemRubrica
            FROM EPagHistoricoRubricaVinculo HRV
           WHERE HRV.CdVinculo = pVinculo.CdVinculo
             AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento = vRubrica.CdRubricaAgrupamento
             AND HRV.CdLancamentoFinanceiro IS NULL;

          DELETE FROM EPagHistoricoRubricaVinculo HRV
           WHERE HRV.CdVinculo = pVinculo.CdVinculo
             AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento = vRubrica.CdRubricaAgrupamento
             AND HRV.CdLancamentoFinanceiro IS NULL;

          IF SQL%ROWCOUNT > 0 THEN

            IF vRubrica.FlIncorporacao = 'S' THEN

              SELECT MAX(IA.VlMinimoRecebimento)
                INTO vVlMinimoRecebimento
                FROM EBpcIncorporacaoAtivo IA
               WHERE IA.CdVinculo = pVinculo.CdVinculo
                 AND IA.CdRubricaAgrupamento =
                     vRubrica.CdRubricaAgrupamento
                 AND IA.FlAnulado = XTMPAG_TIPO.cnN
                 AND ((IA.NuAnoInicio < pFolha.NuAnoReferencia OR
                     (IA.NuAnoInicio = pFolha.NuAnoReferencia AND
                     IA.NuMesInicio <= pFolha.NuMesReferencia)) AND
                     (IA.NuAnofim > pFolha.NuAnoReferencia OR
                     (IA.NuAnofim = pFolha.NuAnoReferencia AND
                     IA.NuMesfim >= pFolha.NuMesReferencia) OR
                     IA.NuAnofim IS NULL));

              FOR vIncorp IN (SELECT HRV.CdIncorporacaoAtivo,
                                     HRV.FlAtualizacaoConstante,
                                     HRV.FlVigenciaPagamento
                                FROM EPagHistoricoRubricaVinculo HRV
                               WHERE HRV.CdFolhaPagamento =
                                     pFolha.CdFolhaPagamento
                                 AND HRV.CdVinculo = pVinculo.CdVinculo
                                 AND HRV.CdRubricaAgrupamento =
                                     vRubrica.CdRubricaAgrupamento
                                 AND HRV.FlAtualizacaoConstante =
                                     XTMPAG_TIPO.cnS) LOOP

                XTMPAG_IA.PAtualizaValorIncorporacao(pCdVinculo              => pVinculo.CdVinculo,
                                                     pNuAno                  => pFolha.NuAnoReferencia,
                                                     pNuMes                  => pFolha.NuMesReferencia,
                                                     pCdIncorporacaoAtivo    => vIncorp.CdIncorporacaoAtivo,
                                                     pFlAtualizacaoConstante => vIncorp.FlAtualizacaoConstante,
                                                     pFlVigenciaPagamento    => vIncorp.FlVigenciaPagamento,
                                                     pVlMinIncorporacao      => vVlMinimoRecebimento,
                                                     pVlFormula              => vVlPagamento);

              END LOOP;

            END IF;

            -- Caso NaO esteja desligamento no mes de processamento
            IF NOT (NVL(pVinculo.DtDesligamento, XTMPAG_TIPO.cnDtMax) BETWEEN
                pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

              -- Proporcionaliza a carga horaria caso seja CEF

              IF XTMPAG_VAR.vgCEF.COUNT > 0 THEN

                FOR i IN XTMPAG_VAR.vgCEF.FIRST .. XTMPAG_VAR.vgCEF.LAST LOOP

                  IF XTMPAG_VAR.vgCEF(i)
                   .NuCargaHoraria <>
                      XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

                    IF XTMPAG_VAR.vgCEF(i)
                     .NuCargaHoraria <
                        XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria /*AND
                                                                                                                             XTMPAG_VAR.vgRubrica(vRubrica.CdRubricaAgrupamento).FlCargaHorariaLimitada = 'N' - omitido em 10/04/2013 pelo Juan/Rogerio*/
                     THEN

                      vVlMinimoRecebimento := vVlMinimoRecebimento *
                                              (XTMPAG_VAR.vgCEF(i)
                                              .NuCargaHoraria /
                                               XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria);

                    ELSE

                      vVlMinimoRecebimento := vVlMinimoRecebimento;

                    END IF;

                  END IF;

                END LOOP;

                -- Proporcionaliza a carga horaria caso seja APO
              ELSIF XTMPAG_VAR.vgAPO.COUNT > 0 THEN

                FOR i IN XTMPAG_VAR.vgAPO.FIRST .. XTMPAG_VAR.vgAPO.LAST LOOP

                  IF XTMPAG_VAR.vgAPO(i)
                   .NuCargaHoraria <
                      XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento *
                                            (XTMPAG_VAR.vgAPO(i)
                                            .NuCargaHoraria /
                                             XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria);

                  END IF;

                  IF NVL(XTMPAG_VAR.vgAPO(i).VlPercentPropApo, 100) < 100 THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento *
                                            (XTMPAG_VAR.vgAPO(i)
                                            .VlPercentPropApo / 100);

                  END IF;

                END LOOP;

              else
                null;
              END IF;

              IF vVlPagamento < vVlMinimoRecebimento THEN

                vVlPagamento := vVlMinimoRecebimento;

              END IF;

            ELSE
              -- Caso possua desligamento no mes de processamento ira proporcionalizar o valor pago

              -- Proporcionaliza a carga horaria caso seja CEF

              IF XTMPAG_VAR.vgCEF.COUNT > 0 THEN

                FOR i IN XTMPAG_VAR.vgCEF.FIRST .. XTMPAG_VAR.vgCEF.LAST LOOP

                  IF XTMPAG_VAR.vgCEF(i)
                   .NuCargaHoraria <>
                      XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento /
                                            XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria * XTMPAG_VAR.vgCEF(i)
                                           .NuCargaHoraria;

                  END IF;

                END LOOP;

              ELSIF XTMPAG_VAR.vgAPO.COUNT > 0 THEN

                FOR i IN XTMPAG_VAR.vgAPO.FIRST .. XTMPAG_VAR.vgAPO.LAST LOOP

                  IF NVL(XTMPAG_VAR.vgAPO(i).VlPercentPropApo, 100) < 100 THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento *
                                            (XTMPAG_VAR.vgAPO(i)
                                            .VlPercentPropApo / 100);

                  END IF;

                END LOOP;

              else
                null;
              END IF;

              IF vVlPagamento < vVlMinimoRecebimento THEN

                vVlPagamento := vVlMinimoRecebimento *
                                (pVinculo.DtDesligamento -
                                pFolha.DtInicioMes + 1) / 30;

              END IF;

            END IF;
            --
            -- Alterado para passar o CdTipoOrigemRubrica da Origem, estava fixo 4 e deu problema
            -- na rubrica 01-0363 que estava marcado como consolidacao e e Vantagem Pecuniario TIPO 5
            --
            XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => vRubrica.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => vvlPagamento,
                                                  pVlIndice             => vvlIndiceRubrica,
                                                  pCdTipoOrigemRubrica  => vCdTipoOrigemRubrica); --4);

          END IF;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            NULL;

        END;

        FOR vPagRelVinc IN (SELECT HRV.CdRelacaoVinculo,
                                   HRV.CdHistCargoEfetivo,
                                   HRV.CdHistCargoCom,
                                   HRV.CdHistFuncaoChefia,
                                   HRV.CdConcessaoAposentadoria,
                                   HRV.CdHistEstagio,
                                   HRV.CdHistPensaoPrevidenciaria,
                                   HRV.CdHistPensaoNaoPrev,
                                   HRV.CdHistPensaoExParlamentar,
                                   HRV.CdHistAuxilioReclusao,
                                   HRV.CdTipoOrigemRubrica,
                                   HRV.DtInicio,
                                   HRV.DtFim,
                                   SUM(HRV.VlIntegral) OVER(PARTITION BY HRV.CdRelacaoVinculo) AS vlIntegral,
                                   SUM(HRV.VlProporcional) OVER(PARTITION BY HRV.CdRelacaoVinculo) AS vlProporcional,
                                   SUM(HRV.VlReal) OVER(PARTITION BY HRV.CdRelacaoVinculo) AS vlReal,
                                   SUM(HRV.VlIndiceRubrica) OVER(PARTITION BY HRV.CdRelacaoVinculo) AS vlIndice
                              FROM EPagHistoricoRubricaRelVinc HRV
                             WHERE HRV.CdVinculo = pVinculo.CdVinculo
                               AND HRV.CdFolhaPagamento =
                                   pFolha.CdFolhaPagamento
                               AND HRV.CdRubricaAgrupamento =
                                   vRubrica.CdRubricaAgrupamento
                               AND HRV.CdLancamentoFinanceiro IS NULL) LOOP

          vCdHistRelVinc := NULL;

          DELETE FROM EPagHistoricoRubricaRelVinc HRV
           WHERE HRV.CdVinculo = pVinculo.CdVinculo
             AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento = vRubrica.CdRubricaAgrupamento
             AND HRV.CdRelacaoVinculo = vPagRelVinc.CdRelacaoVinculo;

          CASE vPagRelVinc.CdRelacaoVinculo

            WHEN 1 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistCargoEfetivo;

            WHEN 2 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistCargoCom;

            WHEN 3 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistFuncaoChefia;

            WHEN 4 THEN

              vCdHistRelVinc := vPagRelVinc.CdConcessaoAposentadoria;

            WHEN 5 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistEstagio;

            WHEN 6 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistPensaoPrevidenciaria;

            WHEN 7 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistPensaoNaoPrev;

            WHEN 8 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistPensaoExParlamentar;

            WHEN 9 THEN

              vCdHistRelVinc := vPagRelVinc.CdHistAuxilioReclusao;

            ELSE

              vCdHistRelVinc := NULL;

          END CASE;

          IF vCdHistRelVinc IS NOT NULL THEN

            -- Caso NAO esta desligado no mes de processamento ira proporcionalizar o valor pago

            IF NOT (NVL(pVinculo.DtDesligamento, XTMPAG_TIPO.cnDtMax) BETWEEN
                pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

              IF vPagRelVinc.VlProporcional < NVL(vVlMinimoRecebimento, 0) THEN

                IF vPagRelVinc.CdRelacaoVinculo = 4 AND
                   vPagRelVinc.DtInicio > pFolha.DtInicioMes AND
                   vPagRelVinc.DtInicio <= pFolha.DtFimMes THEN

                  vVlPagamento := vVlMinimoRecebimento *
                                  (vPagRelVinc.DtFim - vPagRelVinc.DtInicio + 1) / 30;

                ELSIF vPagRelVinc.CdRelacaoVinculo = 1 AND
                      vPagRelVinc.DtFim >= pFolha.DtInicioMes AND
                      vPagRelVinc.DtFim < pFolha.DtFimMes THEN

                  vVlPagamento := vVlMinimoRecebimento *
                                  (vPagRelVinc.DtFim - vPagRelVinc.DtInicio + 1) / 30;

                ELSE

                  vVlPagamento := vVlMinimoRecebimento;

                END IF;

                bDeveRecalcular := TRUE;

              ELSE

                vVlPagamento := vPagRelVinc.VlProporcional;

              END IF;

            ELSE

              IF vPagRelVinc.VlProporcional < NVL(vVlMinimoRecebimento, 0) THEN

                vVlPagamento := vVlMinimoRecebimento *
                                (pVinculo.DtDesligamento -
                                pFolha.DtInicioMes + 1) / 30;

              END IF;

              bDeveRecalcular := TRUE;

            END IF;

            XTMPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pVinculo.CdVinculo,
                                                  pCdRelacaoVinculo     => vPagRelVinc.CdRelacaoVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdHistRelacaoVinculo => vCdHistRelVinc,
                                                  pCdRubricaAgrupamento => vRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral           => vVlPagamento, /*vPagRelVinc.VlIntegral,*/
                                                  pVlProporcional       => vVlPagamento,
                                                  pVlReal               => vVlPagamento,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlIndice             => vPagRelVinc.vlIndice,
                                                  pCdTipoOrigemRubrica  => vPagRelVinc.CdTipoOrigemRubrica,
                                                  pDtInicio             => vPagRelVinc.DtInicio,
                                                  pDtFim                => vPagRelVinc.DtFim);

          END IF;

        END LOOP;

      END IF;

    END;

    PROCEDURE PZeraValorCalculoRubrica(pCdRubricaAgrupamento IN INTEGER) IS
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

       XTMPAG_var.vgValorCalculoRubrica(pCdRubricaAgrupamento).VlCef := 0;
       XTMPAG_var.vgValorCalculoRubrica(pCdRubricaAgrupamento).VlFuc := 0;

       EXCEPTION
         WHEN OTHERS THEN
           NULL;

    END;

    PROCEDURE PResetaCalculoFlexCeresCIDASC IS
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;
      PZeraValorCalculoRubrica(48192); -- 05-0802
      PZeraValorCalculoRubrica(48193); -- 05-0803
    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    PResetaCalculoFlexCeresCIDASC;

    ------------------------------------------------------------------------------
    -- Exclui pagamentos das relacoes de vinculo com valor zerado
    -- excetuando-se aqueles que tem valor minimo de incorporacao ou
    -- sao incorporacoes com formula de calculo (caso da 01-0585) OU
    -- nao sao por formula de calculo nem lancamento financeiro
    ------------------------------------------------------------------------------

    DELETE FROM EPagHistoricoRubricaRelVinc HRV
     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HRV.CdVinculo = pVinculo.CdVinculo
       AND HRV.VlProporcional = 0
       AND HRV.VlIntegral = 0
       AND HRV.CdLancamentoFinanceiro IS NULL
       AND NVL(HRV.VlMinRecebIncorp, 0) = 0
       AND NOT (HRV.CdIncorporacaoAtivo IS NOT NULL AND
            HRV.CdExpressaoFormCalc IS NOT NULL)
       AND HRV.CdExpressaoFormCalc IS NULL;

    ------------------------------------------------------------------------------
    -- Armazena o valor da totalizadora associada a vantagens pecuniarias que
    -- serao verificadas no final do expurga para saber se a vantagem deve
    -- ser excluida (ABONO)
    ------------------------------------------------------------------------------

    i := 0;

    FOR vPag IN cPagVantagem LOOP

      IF XTMPAG_VAR.vgVantagem(vPag.CdVantagemPecuniaria)
       .CdFormaPagVantPecuniaria = 9 THEN

        i := i + 1;

        vPagVantagem(i) := vPag;

        vPagVantagem(i).VlTotalizadora := FRetornaValorRubricaRV(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                 pCdVinculo            => pVinculo.CdVinculo,
                                                                 pCdRubricaAgrupamento => vPagVantagem(i)
                                                                                          .CdRubricaTotalizadoraVantagem,
                                                                 pCdRelacaoVinculo     => vPagVantagem(i)
                                                                                          .CdRelacaoVinculo);

      END IF;

    END LOOP;

    ------------------------------------------------------------------------
    -- Inicio da rotina de consolidacao e expurga de rubricas
    ------------------------------------------------------------------------

    ----------------------------------------------------------------
    -- Exclui pagamentos do vinculo com valor zerado
    ----------------------------------------------------------------
    -- Foi colocada a validacao de somente deletar os registros
    -- se o vinculo nao estiver finalizado dentro do mes
    -- REVER A GERACAO DAS BASES DE IRRF e outras
    ----------------------------------------------------------------

    IF XTMPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
       XTMPAG_VAR.vgVinculo.DtDesligamento > pFolha.DtFimMes  THEN

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pVinculo.CdVinculo
         AND HRV.VlPagamento = 0
         AND NVL(HRV.VlMinRecebIncorp, 0) = 0
         AND hrv.cdrubricaagrupamento <> CASE
                                           WHEN (XTMPAG_var.vgFolha.numesreferencia >= 8 AND XTMPAG_var.vgFolha.nuanoreferencia = 2020) OR
                                                (XTMPAG_var.vgFolha.nuanoreferencia > 2020) THEN
                                                XTMPAG_VAR.vgCdRubricaBaseCsgLiq -- A 09-1007 - Margem consignavel liquida deve ser gravada no contracheque com valor zero
                                           ELSE
                                             0
                                          END;

    END IF;

    bDeveExpurgar := TRUE;

    bDeveRecalcular := FALSE;

    bDeveRecVantagem := FALSE;

    FOR vRec IN (SELECT RA.CdRubricaAgrupamento,
                        HRV.NuSufixoRubrica,
                        COUNT(*) AS NuRelacoes,
                        MAX(vlIntegral) maxValor
                   FROM EPagHistoricoRubricaRelVinc HRV
                  INNER JOIN EPagRubricaAgrupamento RA
                     ON RA.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
                  INNER JOIN EPagHistRubricaAgrupamento HRA
                     ON HRA.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
                  WHERE HRV.Cdvinculo = pVinculo.CdVinculo
                    AND HRV.Cdfolhapagamento = pFolha.CdFolhaPagamento
                    AND RA.CdAgrupamento = pFolha.CdAgrupamento
                    AND HRA.FlPagaMaiorRV = XTMPAG_TIPO.cnS
                    AND
                       -- Desconsiderar aposentadoria pois estava zerando os dias de efetivo
                       -- quando o valor da aposentadoria era maior e vice-versa
                        HRV.Cdrelacaovinculo <> 4
                    AND ((HRA.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                        (HRA.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                        HRA.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
                        (HRA.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                        (HRA.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                        HRA.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                        HRA.NuMesFimVigencia IS NULL))
                    AND HRV.VlIntegral > 0
                  GROUP BY RA.CdRubricaAgrupamento, HRV.Nusufixorubrica
                 HAVING COUNT(*) > 1) LOOP

      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET HRV.VlProporcional = 0, HRV.CdExpressaoFormCalc = NULL
       WHERE HRV.CdVinculo = pVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = vRec.CdRubricaAgrupamento
         AND HRV.NuSufixoRubrica = vRec.NuSufixoRubrica
         AND HRV.CdHistoricoRubricaRelVinc NOT IN
             (SELECT HRVX.CdHistoricoRubricaRelVinc
                FROM EPagHistoricoRubricaRelVinc HRVX
               WHERE HRVX.CdVinculo = pVinculo.CdVinculo
                 AND HRVX.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND HRVX.CdRubricaAgrupamento = vRec.CdRubricaAgrupamento
                 AND HRVX.NuSufixoRubrica = vRec.NuSufixoRubrica
                 AND HRVX.VlIntegral = vRec.maxValor
                 AND ROWNUM < 2);

      /*UPDATE EPagHistoricoRubricaRelVinc  HRV
         SET HRV.VlProporcional = 0,
             HRV.CdExpressaoFormCalc = NULL
      WHERE HRV.CdVinculo = pVinculo.CdVinculo AND
            HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
            HRV.CdRubricaAgrupamento = vRec.CdRubricaAgrupamento AND
            HRV.NuSufixoRubrica = vRec.NuSufixoRubrica AND
            HRV.VlIntegral <= vRec.maxValor AND
            ROWNUM < vRec.NuRelacoes;*/

      bDeveRecalcular := TRUE;

    END LOOP;

    -- Zera valores calculados previamente na 05-0802 e 05-0803 da CIDASC,
    -- Pois a base da    09-0930 sera recalculada.

    WHILE bDeveExpurgar LOOP

      bDeveExpurgar := FALSE;

      ----------------------------------
      -- Consolida rubricas
      ----------------------------------
      FOR vRubricaPaga IN cRubricaPaga LOOP

        PConsolida(vRubricaPaga.CdRubricaAgrupamento);

        PTratarExcecoesDeveRecalcular(pCdAgrupamento => pFolha.CdAgrupamento,
                                      pCdRubricaAgrupamento => vRubricaPaga.CdRubricaAgrupamento,
                                      pCdTipoFolha => pFolha.CdTipoFolha);

        IF bDeveRecalcular THEN

          PReprocessaFormulasBases(pFolha           => pFolha,
                                   pCdVinculo       => pVinculo.CdVinculo,
                                   pTpProcessamento => 1);

          bDeveRecalcular := FALSE;

          bDeveRecVantagem := TRUE;

        END IF;

      END LOOP;

      ----------------------------------
      -- Trata rubricas exigidas
      ----------------------------------

      bHouveExclusao := TRUE;

      WHILE bHouveExclusao LOOP

        bHouveExclusao := FALSE;

        FOR vRubricaPaga IN cRubricaPaga LOOP

          IF FTrataExigidas(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                            pCdVinculo            => pVinculo.CdVinculo,
                            pCdRubricaAgrupamento => vRubricaPaga.CdRubricaAgrupamento,
                            pFlTotalizadora       => 'N') THEN

            bDeveRecalcular := TRUE;

            bHouveExclusao := TRUE;

          END IF;

        END LOOP;

      END LOOP;

      IF bDeveRecalcular THEN

        PReprocessaFormulasBases(pFolha           => pFolha,
                                 pCdVinculo       => pVinculo.CdVinculo,
                                 pTpProcessamento => 1);

        bDeveRecalcular := FALSE;

        bDeveRecVantagem := TRUE;

        bDeveExpurgar := TRUE;

      END IF;

      ----------------------------------
      -- Trata rubricas impeditivas
      ----------------------------------

      bHouveExclusao := TRUE;

      WHILE bHouveExclusao LOOP

        bHouveExclusao := FALSE;

        FOR vRubricaPaga IN cRubricaPaga LOOP

          IF FTrataImpeditivas(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                               pCdVinculo            => pVinculo.CdVinculo,
                               pCdRubricaAgrupamento => vRubricaPaga.CdRubricaAgrupamento,
                               pFlTotalizadora       => 'N') THEN

              bDeveRecalcular := TRUE;

              bHouveExclusao := TRUE;

              ------------------------------------------------------------------------------
              -- Solicitacao de Sustentacao #73153
              -- Servidores  que possuem a rubrica 01-0274 com valor pago igual a zero
              -- e valor integral maior do que zero:
              -- Nestes casos, o valor integral deve ser tambem zerado
              ------------------------------------------------------------------------------
              if vRubricaPaga.CdRubricaAgrupamento = 24077 then
                  UPDATE EPagHistoricoRubricaRelVinc HRV
                     SET HRV.vlintegral = 0,
                         HRV.vlreal = 0
                   WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                     AND HRV.CdVinculo = pVinculo.CdVinculo
                     AND HRV.VlProporcional = 0
                     AND HRV.VlIntegral > 0
                     AND HRV.cdrubricaagrupamento = 24077;
              end if;

          END IF;

        END LOOP;

      END LOOP;

      IF bDeveRecalcular THEN

        PReprocessaFormulasBases(pFolha           => pFolha,
                                 pCdVinculo       => pVinculo.CdVinculo,
                                 pTpProcessamento => 1);

        bDeveRecalcular := FALSE;

        bDeveRecVantagem := TRUE;

        bDeveExpurgar := TRUE;

      END IF;

    END LOOP;

    --------------------------------------------------------------------------
    -- Inicio do reprocessamento de vantagens que usam rubricas totalizadoras
    -- (ABONO)
    --------------------------------------------------------------------------

    IF vPagVantagem.COUNT > 0 AND bDeveRecVantagem THEN

      FOR i in vPagVantagem.FIRST .. vPagVantagem.LAST LOOP

        vVlBaseRecalc := FRetornaValorRubricaRV(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pVinculo.CdVinculo,
                                                pCdRubricaAgrupamento => vPagVantagem(i)
                                                                         .CdRubricaTotalizadoraVantagem,
                                                pCdRelacaoVinculo     => vPagVantagem(i)
                                                                         .CdRelacaoVinculo);

        -- Se o valor anterior da base for menor que a base recalculada
        IF vPagVantagem(i).VlTotalizadora < vVlBaseRecalc THEN

          BEGIN

            SELECT NuValorFixoVantagem
              INTO vNuValorFixoVantagem
              FROM EBpcFaixaValorVPFormaPag FV
             WHERE FV.CdHistVantagemPecuniaria = XTMPAG_VAR.vgVantagem(vPagVantagem(i).CdVantagemPecuniaria)
                  .CdHistVantagemPecuniaria
               AND ((vVlBaseRecalc BETWEEN FV.NuValorBaseInicio AND
                   FV.NuValorBaseFim) OR
                   (vVlBaseRecalc >= FV.NuValorBaseInicio AND
                   FV.NuValorBaseFim IS NULL));

          EXCEPTION

            WHEN NO_DATA_FOUND THEN

              -- Exclui rubrica e reprocessa

              DELETE FROM EPagHistoricoRubricaRelVinc HRV
               WHERE HRV.CdHistoricoRubricaRelVinc = vPagVantagem(i)
                    .CdHistoricoRubricaRelVinc;

              PReprocessaFormulasBases(pFolha           => pFolha,
                                       pCdVinculo       => pVinculo.CdVinculo,
                                       pTpProcessamento => 1);

          END;

        END IF;

      END LOOP;

    END IF;
    -- rubrica 01-0274
  END;

  /*-----------------------------------------------------------------------
    Procedure PExpurgaRubricas

    Objetivo: Expurgar as rubricas de pagamento :

  /*-----------------------------------------------------------------------*/
  PROCEDURE PExpurgarTotalizadoras(pFolha   IN XTMPAG_TIPO.rFolha,
                                   pVinculo IN XTMPAG_TIPO.rVinculo) IS

    CURSOR cRubricaPaga IS

      SELECT DISTINCT HRV.CdRubricaAgrupamento
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pVinculo.CdVinculo;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    ----------------------------------
    -- Trata rubricas exigidas
    ----------------------------------

    FOR vRubricaPaga IN cRubricaPaga LOOP

      IF FTrataExigidas(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                        pCdVinculo            => pVinculo.CdVinculo,
                        pCdRubricaAgrupamento => vRubricaPaga.CdRubricaAgrupamento,
                        pFlTotalizadora       => 'S') THEN

        NULL;

      END IF;

    END LOOP;

  END;

  PROCEDURE PCopiaContraCheques(pCdFolhaOrigem  IN INTEGER,
                                pCdFolhaDestino IN INTEGER,
                                pCdVinculo      IN INTEGER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

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
             XTMPAG_VAR.vgCdAgenciaCredito,
             XTMPAG_VAR.vgNuContaCredito,
             XTMPAG_VAR.vgNuDvContaCredito,
             XTMPAG_VAR.vgCdAgenciaReceb,
             XTMPAG_VAR.vgNuContaReceb,
             XTMPAG_VAR.vgFlTipoContaCredito,
             XTMPAG_VAR.vgNuAgencia,
             XTMPAG_VAR.vgNuDvAgencia,
             XTMPAG_VAR.vgNuBanco,
             hrv.cdcentrocusto,
             hrv.inaposentadoriaespecial
        FROM EPagCapaHistRubricaVinculo HRV
       WHERE CdFolhaPagamento = pCdFolhaOrigem
         AND CdVinculo = pCdVinculo;

  END;

  /*-----------------------------------------------------------------------------------------/
       Procedure : PProcessaFolhaSuplementar
        Objetivo : Realizar o processamento de folha do tipo suplementar

            Nota : - e utilizada a tabela de apoio  EPAGRUBRICASUPLEMENTAR para a geracao
                     da folha suplementar.

  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessaFolhaSuplementar(pFolhaSuplementar    IN XTMPAG_TIPO.rFolha,
                                      pFolhaOrigem         IN XTMPAG_TIPO.rFolha,
                                      pFolhaRecalculo      IN XTMPAG_TIPO.rFolha,
                                      pCdVinculo           IN INTEGER,
                                      pFlCalculoDefinitivo IN CHAR,
                                      pVlDiferencaValor    IN NUMBER DEFAULT 0,
                                      pCdFolhaPagou        IN INTEGER DEFAULT 0) IS

    vTemRecalc BOOLEAN;

    vPossuiOutraSuplMes boolean;

    vValorRecebido number(13,2);

    vCdProcessoRestituicaoErario integer;

    vNuParcela integer;

    CURSOR cSuplVinculo(pCdFolhaOrigem   INTEGER,
                        pCdFolhaVincSupl INTEGER,
                        pCdVinculo       INTEGER) IS
      SELECT RA.CdRubricaAgrupamento,
             RA.CdAgrupamento,
             S.CdVinculo,
             CASE
               WHEN S.CdTipoRubrica <> XTMPAG_TIPO.cnTpRubTotalizadora THEN
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
                        XTMPAG_TIPO.cnS
                       ELSE
                        XTMPAG_TIPO.cnN
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
                                --h1.vlindicerubrica,
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
                                    --h2.vlindicerubrica,
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
                    --   RA.Fltributacao = XTMPAG_TIPO.cnN AND RA.Flconsignacao = XTMPAG_TIPO.cnN AND
                     RA.FlConsignacao = XTMPAG_TIPO.cnN
                 AND -- hj
                     (R.CdTipoRubrica IN
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
                     XTMPAG_TIPO.cnS AS FlValorOrigemMaior,
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
                 AND NOT EXISTS
               (SELECT 1
                        FROM EPagHistoricoRubricaVinculo H2
                       WHERE H1.CdRubricaAgrupamento =
                             H2.CdRubricaAgrupamento
                         AND H1.NuSufixoRubrica = H2.NuSufixoRubrica
                         AND H1.CdVinculo = H2.CdVinculo
                         AND H2.CdFolhaPagamento = pCdFolhaVincSupl
                         AND (H2.Cdvinculo = pCdVinculo))
                 AND
                    --  RA.Fltributacao = XTMPAG_TIPO.cnN AND RA.Flconsignacao = XTMPAG_TIPO.cnN*/ --
                     RA.FlConsignacao = XTMPAG_TIPO.cnN
                 AND R.CdTipoRubrica IN
                     (1, /*2,*/ 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
               GROUP BY R.CdTipoRubrica,
                        R.NuRubrica,
                        H1.CdVinculo,
                        RA.CdAgrupamento,
                        H1.CdRubricaAgrupamento,
                        0,
                        H1.NuSufixoRubrica,
                        H1.CdBaseConsignacao,
                        XTMPAG_TIPO.cnS,
                        H1.CdLancamentoFinanceiro,
                        H1.Cdtipoorigemrubrica,
                        h1.deprocessoretroativo,
                        h1.vlindicerubrica,
                        h1.vlindicenmrra,
                        h1.cdprocessopagretroativo,
                        h1.vlmontanteretroativo,
                        h1.cdprocessorestituicaoerario,
                        h1.cdhistsentencajudicial
              HAVING SUM(H1.VlPagamento) > NVL(pVlDiferencaValor, 0)

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
                     XTMPAG_TIPO.cnN AS FlValorOrigemMaior,
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
                    -- RA.Fltributacao = XTMPAG_TIPO.cnN  AND RA.Flconsignacao = XTMPAG_TIPO.cnN */ -- Anterior a 15/06
                     RA.FlConsignacao = XTMPAG_TIPO.cnN
                 AND -- Apos 16/06
                     R.CdTipoRubrica IN
                     (1,
                      CASE WHEN pFolhaRecalculo.FlIgnoraInclusaoFutura = 'S' THEN 0 ELSE 2 END,
                      3,
                      4,
                      5,
                      6,
                      7,
                      8,
                      9,
                      10,
                      11,
                      12,
                      13)
               GROUP BY R.CdTipoRubrica,
                        R.NuRubrica,
                        H1.CdVinculo,
                        RA.CdAgrupamento,
                        H1.CdRubricaAgrupamento,
                        0,
                        H1.NuSufixoRubrica,
                        H1.CdBaseConsignacao,
                        XTMPAG_TIPO.cnN,
                        H1.CdLancamentoFinanceiro,
                        H1.Cdtipoorigemrubrica,
                        h1.deprocessoretroativo,
                        h1.vlindicerubrica,
                        h1.vlindicenmrra,
                        h1.cdprocessopagretroativo,
                        h1.vlmontanteretroativo,
                        h1.cdprocessorestituicaoerario,
                        h1.cdhistsentencajudicial
              HAVING SUM(H1.VlPagamento) > NVL(pVlDiferencaValor, 0)) S
       INNER JOIN EPagRubricaSuplementar RS
          ON S.CdTipoRubrica = RS.CdTipoRubricaOrigem
       INNER JOIN EPagRubrica R
          ON R.CdTipoRubrica = RS.CdTipoRubricaGerada
       INNER JOIN EPagRubricaAgrupamento RA
          ON R.CdRubrica = RA.CdRubrica
       WHERE S.NuRubrica = R.NuRubrica
         AND S.FlValorOrigemMaior = RS.FlValorOrigemMaior
         AND S.CdAgrupamento = RA.CdAgrupamento;

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
      -- xtmpag_util.pGravaLogCallStack;

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
      -- xtmpag_util.pGravaLogCallStack;

      begin
      -- Identifica se ja existe parcela na suplementar e exclui
      select max(pg.cdpagamentolancamento)
        into vCont
        from epagpagamentolancamento pg
       where pg.cdlancamentofinanceiro = pCdLancamentoFinanceiro
         and pg.nuanoreferencia = XTMPAG_var.vgFolha.NuAnoReferencia
         and pg.numesreferencia = XTMPAG_var.vgFolha.NuMesReferencia
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
      -- xtmpag_util.pGravaLogCallStack;
      with fol as (select cdfolhapagamento
                     from epagfolhapagamento pf
                    where pf.nuanoreferencia = XTMPAG_var.vgFolha.NuAnoReferencia
                      and pf.numesreferencia = XTMPAG_var.vgFolha.NuMesReferencia
                      and pf.flcalculodefinitivo = 'S'
                      and pf.cdorgao = XTMPAG_var.vgFolha.CdOrgao
                      and pf.cdtipocalculo = XTMPAG_tipo.cnTpCalculoSupl
                      and pf.cdfolhapagamento <> XTMPAG_var.vgFolha.CdFolhaPagamento)
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
      -- xtmpag_util.pGravaLogCallStack;
      with fol as (select cdfolhapagamento
                     from epagfolhapagamento pf
                    where pf.nuanoreferencia = XTMPAG_var.vgFolha.NuAnoReferencia
                      and pf.numesreferencia = XTMPAG_var.vgFolha.NuMesReferencia
                      and pf.flcalculodefinitivo = 'S'
                      and pf.cdorgao = XTMPAG_var.vgFolha.CdOrgao
                      and pf.cdtipocalculo = XTMPAG_tipo.cnTpCalculoSupl
                      and pf.cdfolhapagamento <> XTMPAG_var.vgFolha.CdFolhaPagamento)

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
      -- xtmpag_util.pGravaLogCallStack;

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
      -- xtmpag_util.pGravaLogCallStack;

      vTabDtCalculo.DELETE;

      FOR rec IN (SELECT NuMesReferencia, DtCalculo
                    FROM EPagfolhaPagamento
                   WHERE cdtipofolhapagamento =
                         XTMPAG_VAR.vgFolhaRecalculo.CdTipoFolhaPagamento
                     AND cdtipocalculo = XTMPAG_TIPO.cnTpCalculoNormal
                     AND cdorgao = XTMPAG_VAR.vgFolhaRecalculo.CdOrgao
                     AND NuAnoReferencia =
                         XTMPAG_VAR.vgFolhaRecalculo.NuAnoReferencia) LOOP

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
      -- xtmpag_util.pGravaLogCallStack;

      vMenorDataInclusao := NULL;

      FOR iRelVinc IN XTMPAG_VAR.vgRelVinc.FIRST .. XTMPAG_VAR.vgRelVinc.LAST LOOP

        IF XTMPAG_VAR.vgRelVinc(iRelVinc)
         .DtInclusao > (pDtCalculo + 1 - 1 / 86400) THEN

          IF vMenorDataInclusao IS NULL OR
             vMenorDataInclusao > XTMPAG_VAR.vgRelVinc(iRelVinc).DtInclusao THEN

            vMenorDataInclusao := XTMPAG_VAR.vgRelVinc(iRelVinc).DtInclusao;

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

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_RT.PExcluiHistoricoRetroSupl(pCdVinculo => pCdVinculo,
                                        pFolha     => pFolhaSuplementar);

    IF XTMPAG_VAR.vgFolhaRecalculo.CdTipoCalculo =
       XTMPAG_TIPO.cnTpCalculoRecalcCompl THEN

      PCopiaContraCheques(pCdFolhaOrigem  => XTMPAG_VAR.vgFolhaRecalculo.CdFolhaPagamento,
                          pCdFolhaDestino => pFolhaSuplementar.CdFolhaPagamento,
                          pCdVinculo      => pCdVinculo);

      IF pFlCalculoDefinitivo = XTMPAG_TIPO.cnS THEN

        XTMPAG_RT.PAtualizaParcelaRetroativo(pFolha     => pFolhaSuplementar,
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

    IF FPossuiPagamento(pCdFolhaPagamento => pFolhaRecalculo.CdFolhaPagamento,
                        pCdVinculo        => pCdVinculo) THEN

      vTemRecalc := TRUE;

      -- Carrega vetor com rubricas suplementares
      OPEN cSuplVinculo(pCdFolhaOrigem   => CASE
                                              WHEN pCdFolhaPagou <> 0 THEN
                                               pCdFolhaPagou
                                              ELSE
                                               pFolhaOrigem.CdFolhaPagamento
                                            END,
                        pCdFolhaVincSupl => pFolhaRecalculo.CdFolhaPagamento,
                        pCdVinculo       => pCdVinculo);
      FETCH cSuplVinculo BULK COLLECT
        INTO vTabSuplVinculo;

      CLOSE cSuplVinculo;

      -- exclui folha de recalculo caso seja a mesma da suplementar

      IF pFolhaRecalculo.CdFolhaPagamento =
         pFolhaSuplementar.CdFolhaPagamento AND
         pFolhaSuplementar.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoDifMes THEN

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
                                         pDtCalculo => pFolhaOrigem.DtCalculo, -- Data da normal
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
             XTMPAG_TIPO.cnTpCalculoDifMes THEN

            -- Sufixo da Rubrica sera mes de pagamento da diferenca
            rSuplementar.NuSufixoRubrica := vNuSufixoDifMes;

          END IF;

          -- FOI OMITIDO ISTO VISTO QUE O SELECT ANTERIOR Ja NaO CONSIDERA MAIS CONSIGNAcaO
          IF ( rSuplementar.FlGeraSuplementar = 'S') THEN

            IF (rSuplementar.FlTributacao = 'S') AND
               rSuplementar.CdTipoRubrica = 6 THEN

              rSuplementar.CdRubricaAgrupamento := XTMPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,
                                                                                5,
                                                                                rSuplementar.NuRubrica);

            END IF;

            ----------------------------------------------------------------------------
            -- Nao gera suplementar para auxilio alimentacao
            -- Alterado em 12/08/13 Chamado 5090/2013 por solicitacao da SEA para que o
            -- programa permita gera o Auxilio em folha suplementar
            ----------------------------------------------------------------------------

            IF pFolhaRecalculo.FlIgnoraInclusaoFutura = 'S' AND
               rSuplementar.NuRubrica = 157 THEN

              NULL;

            ELSIF pFolhaRecalculo.FlIgnoraInclusaoFutura = 'S' AND
                  (rSuplementar.NuRubrica = 56 OR
                  rSuplementar.CdTipoRubricaOrigem NOT IN (1)) THEN

              NULL;

            ELSIF ((rSuplementar.CdTipoRubricaOrigem IN (5) AND
                  rSuplementar.NuRubrica IN (/*512,*/ 513, 516, 924, 925)) OR
                  (rSuplementar.CdTipoRubricaOrigem = 9)) AND
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

                rSuplementar.CdRubricaAgrupamento := XTMPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,
                                                                                  1,
                                                                                  rSuplementar.NuRubrica);

              -- Solicitacao de Sustentacao #79626
              -- 12077/2018 - FOLHA - - RUBRICA 06-0953 NA FOLHA SUPLEMENTAR

              ELSIF rSuplementar.CdTipoRubricaOrigem = 5 AND
                    rSuplementar.CdTipoRubrica = 6 AND
                    rSuplementar.NuRubrica in (837,953) THEN

                rSuplementar.CdRubricaAgrupamento := XTMPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,
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
                  XTMPAG_GERAL.FRetornaRubrica(rSuplementar.CdAgrupamento,5,rSuplementar.NuRubrica);

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
                   rSuplementar.cdhistsentencajudicial);

              END IF;

            END IF;

            if rSuplementar.Cdlancamentofinanceiro is not null and
               XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S'

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

                      XTMPAG_LF.PRegistarPagamentoParcela(
                         pCdLancamentoFinanceiro => rSuplementar.CdLancamentoFinanceiro,
                                pNuAnoReferencia => XTMPAG_var.vgFolha.NuAnoReferencia,
                                pNuMesreferencia => XTMPAG_var.vgFolha.NuMesReferencia,
                                      pNuParcela => vNuParcela + 1,
                                   pValorParcela => rSuplementar.Vlpagamento);

                     EXCEPTION

                        WHEN OTHERS THEN

                          XTMPAG_GERAL.pInsereLog(
                              XTMPAG_VAR.bLog,
                              XTMPAG_VAR.vCdHistParamCalc,
                              XTMPAG_VAR.vCdPessoa,
                              'Erro ao gerar parcela de erário: Código do lançamento: ' || rSuplementar.CdLancamentoFinanceiro,
                              XTMPAG_VAR.vgCdVinculo);

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

      /*XTMPAG_RT.PAtualizaParcelaRetroativo(pFolha     => pFolhaSuplementar,
                                           pCdVinculo => pCdVinculo);*/

      XTMPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => pFolhaSuplementar.CdFolhaPagamento,
                                          pCdVinculo        => pCdVinculo);

      -- Regera as totalizadoras

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento IN
             (XTMPAG_VAR.vgCdRubricaBaseTotPrv,
              XTMPAG_VAR.vgCdRubricaBaseTotDsc,
              XTMPAG_VAR.vgCdRubricaBaseTotLiq);

      IF XTMPAG_VAR.vgVlTotalProventos >= XTMPAG_VAR.vgVlTotalDescontos THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolhaSuplementar.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotPrv,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => NVL(XTMPAG_VAR.vgVlTotalProventos,
                                                                           0),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolhaSuplementar.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotDsc,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => NVL(XTMPAG_VAR.vgVlTotalDescontos,
                                                                           0),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolhaSuplementar.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotLiq,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => XTMPAG_VAR.vgVlBaseTotalLiquida,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_GERAL.PExcluiValoresZerados(pCdVinculo        => pCdVinculo,
                                           pCdFolhaPagamento => pFolhaSuplementar.CdFolhaPagamento);

        -------------------------------------------------------------------
        -- Gera a capa de lote da Suplementar a partir da capa do recalculo
        -------------------------------------------------------------------

        IF pFolhaSuplementar.CdFolhaPagamento =
           pFolhaRecalculo.CdFolhaPagamento THEN

          UPDATE EPagCapaHistRubricaVinculo CL
             SET vlProventos = NVL(XTMPAG_VAR.vgVlTotalProventos, 0),
                 vlDescontos = NVL(XTMPAG_VAR.vgVlTotalDescontos, 0)
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
                   NVL(XTMPAG_VAR.vgVlTotalProventos, 0),
                   NVL(XTMPAG_VAR.vgVlTotalDescontos, 0),
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
                   XTMPAG_VAR.vgCdAgenciaCredito,
                   XTMPAG_VAR.vgNuContaCredito,
                   XTMPAG_VAR.vgNuDvContaCredito,
                   XTMPAG_VAR.vgCdAgenciaReceb,
                   XTMPAG_VAR.vgNuContaReceb,
                   XTMPAG_VAR.vgFlTipoContaCredito,
                   XTMPAG_VAR.vgNuAgencia,
                   XTMPAG_VAR.vgNuDvAgencia,
                   XTMPAG_VAR.vgNuBanco,
                   cp1.cdcentrocusto,
                   cp1.inaposentadoriaespecial
              FROM EPagCapaHistRubricaVinculo CP1
             WHERE CP1.CdFolhaPagamento = pFolhaRecalculo.CdFolhaPagamento
               AND CP1.CdVinculo = pCdVinculo;

        END IF;

      ELSE

        DELETE FROM EPagCapaHistRubricaVinculo CL
         WHERE CL.cdVinculo = pCdVinculo
           AND CL.cdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento;

        DELETE FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo;

      END IF;

      --END IF;

    ELSE

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolhaSuplementar.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              XTMPAG_VAR.vCdHistParamCalc,
                              XTMPAG_VAR.vCdPessoa,
                              'Erro ao processar suplementar: ' || SQLERRM,
                              XTMPAG_VAR.vgCdVinculo);

  END;

  FUNCTION FLancamentoDifMes(pFolha            IN XTMPAG_TIPO.rFolha,
                             pTabCdFolhaDifMes IN tTabFolhaPagamentoDifMes,
                             prVinculo         IN XTMPAG_TIPO.rVinculo)
    RETURN BOOLEAN IS

    vTemDif          BOOLEAN;
    vTemDifFol       BOOLEAN;
    vVlIprevFF       NUMBER;
    vVlIprevFP       NUMBER;
    vBaseSufixo      INTEGER;
    vCdTipoOrigemRub INTEGER;
    vNuAnoMesOrigem  INTEGER;
    vCdRubAgr06_0328 INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vBaseSufixo      := 80;
    vCdTipoOrigemRub := 20;

    vTemDif := FALSE;

    vCdRubAgr06_0328 := XTMPAG_GERAL.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                     pcdtiporubrica => 6,
                                                     pNuRubrica => 328);

    FOR fol IN REVERSE 1 .. pFolha.NuMesReferencia - 1 LOOP

      IF NOT pTabCdFolhaDifMes.EXISTS(fol) THEN
        EXIT; -- So paga folhas continuas
      END IF;

      vTemDifFol := FALSE;

      vVlIprevFF := 0;
      vVlIprevFP := 0;

      vNuAnoMesOrigem := pFolha.NuAnoReferencia * 100 + fol;

      FOR rec IN (SELECT
                         CASE
                           WHEN CdTipoRubrica = 5 AND NuRubrica  = 328 THEN
                             vCdRubAgr06_0328
                           ELSE
                             H.CdRubricaAgrupamento
                           END as CdRubricaAgrupamento,
                         VlPagamento,
                         QtParcelas,
                         VlIndiceRubrica,
                         CASE
                           WHEN NuRubrica IN (924, 944) THEN
                            'FF'
                           WHEN NuRubrica IN (925, 945) THEN
                            'FP'
                           ELSE
                            NULL
                         END as TipoIprev
                    FROM Epaghistoricorubricavinculo H
                   INNER JOIN EPagRubricaAgrupamento RA
                      ON h.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
                   INNER JOIN EPagRubrica R
                      ON r.CdRubrica = RA.CdRubrica
                   WHERE CdFolhaPagamento = pTabCdFolhaDifMes(fol)
                        .CdFolhaDifMes
                     AND CdVinculo = prVinculo.CdVinculo
                     AND NuRubrica NOT IN (9000) -- Liquido Negativo
                     AND (CdTipoRubrica IN (2, 10, 12) OR
                         (CdTipoRubrica = 5 AND
                         NuRubrica IN (924, 925, 944, 945, 328)))
                     AND NuSufixoRubrica = pFolha.NuMesReferencia) LOOP

        vTemDifFol := TRUE;

        vTemDif := TRUE;

        IF rec.TipoIprev = 'FF' THEN

          vVlIprevFF := vVlIprevFF + rec.VlPagamento;

        ELSIF rec.TipoIprev = 'FP' THEN

          vVlIprevFP := vVlIprevFP + rec.VlPagamento;

        ELSE
          /*
                   -- Lancando no Vinculo
                   XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                         pCdVinculo              => pCdVinculo,
                                                         pCdExpressaoFormCalc    => NULL,
                                                         pCdRubricaAgrupamento   => rec.CdRubricaAgrupamento,
                                                         pNuSufixoRubrica        => vBaseSufixo + fol,  -- Indice contera vBaseSufixo mais o mes de referencia do retroativo
                                                         pVlPagamento            => rec.VlPagamento,
                                                         pNuParcelas             => rec.NuSufixoRubrica,
                                                         pVlIndice               => rec.VlIndiceRubrica,
                                                         pCdTipoOrigemRubrica    => vCdTipoOrigemRub,
                                                         pNuAnoMesOrigem         => vNuAnoMesOrigem);

          */

          -- Lancando na Relacao Principal

          XTMPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => prVinculo.CdVinculo,
                                                pCdRelacaoVinculo     => NVL(XTMPAG_VAR.vgRelVincPrincipal.Tipo,
                                                                             1),
                                                pCdHistRelacaoVinculo => XTMPAG_VAR.vgRelVincPrincipal.CdHist,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => rec.CdRubricaAgrupamento,
                                                pVlIntegral           => rec.VlPagamento,
                                                pVlProporcional       => rec.VlPagamento,
                                                pVlReal               => rec.VlPagamento,
                                                pNuSufixoRubrica      => vBaseSufixo + fol, -- Indice contera vBaseSufixo mais o mes de referencia do retroativo
                                                pNuParcelas           => rec.QtParcelas,
                                                pVlIndice             => rec.VlIndiceRubrica,
                                                pCdTipoOrigemRubrica  => vCdTipoOrigemRub,
                                                pNuAnoMesOrigem       => vNuAnoMesOrigem);

        END IF;

      END LOOP;

      IF vVlIprevFF > 0 THEN
        XTMPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => prVinculo.CdVinculo,
                                              pCdRelacaoVinculo     => NVL(XTMPAG_VAR.vgRelVincPrincipal.Tipo,
                                                                           1),
                                              pCdHistRelacaoVinculo => XTMPAG_VAR.vgRelVincPrincipal.CdHist,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                    05,
                                                                                                    0915),
                                              pVlIntegral           => vVlIprevFF,
                                              pVlProporcional       => vVlIprevFF,
                                              pVlReal               => vVlIprevFF,
                                              pNuSufixoRubrica      => vBaseSufixo + fol, -- Indice contera vBaseSufixo mais o mes de referencia do retroativo
                                              pCdTipoOrigemRubrica  => vCdTipoOrigemRub,
                                              pNuAnoMesOrigem       => vNuAnoMesOrigem);
      END IF;

      IF vVlIprevFP > 0 THEN
        XTMPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => prVinculo.CdVinculo,
                                              pCdRelacaoVinculo     => NVL(XTMPAG_VAR.vgRelVincPrincipal.Tipo,
                                                                           1),
                                              pCdHistRelacaoVinculo => XTMPAG_VAR.vgRelVincPrincipal.CdHist,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                    05,
                                                                                                    0926),
                                              pVlIntegral           => vVlIprevFP,
                                              pVlProporcional       => vVlIprevFP,
                                              pVlReal               => vVlIprevFP,
                                              pNuSufixoRubrica      => vBaseSufixo + fol, -- Indice contera vBaseSufixo mais o mes de referencia do retroativo
                                              pCdTipoOrigemRubrica  => vCdTipoOrigemRub,
                                              pNuAnoMesOrigem       => vNuAnoMesOrigem);
      END IF;
      --
      -- Se data de inclusao posterior a data de calculo anterior continua procurando folhas de diferencas
      --
      IF NOT vTemDifFol AND (XTMPAG_GERAL.fDtInclusaoCef(PRVINCULO.CdVinculo) IS NULL OR
                             XTMPAG_GERAL.fDtInclusaoCef(PRVINCULO.CdVinculo) <= pFolha.DtCalculoAnt)
         THEN
        EXIT;
      END IF;

    END LOOP;

    RETURN vTemDif;

  END;

  FUNCTION FOBtemFolhaDifMes(pFolha IN XTMPAG_TIPO.rFolha)
    RETURN tTabFolhaPagamentoDifMes IS

    vTabFolhaPagamentoDifMes tTabFolhaPagamentoDifMes;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    FOR rec IN (select Mes, fa.CdFolhaPAgamento, fn.DtCalculo
                  FROM (Select level as Mes
                          FROM DUAL
                        CONNECT BY LEVEL < pFolha.NuMesReferencia) TMes
                 INNER JOIN EPagFolhaPagamento fa
                    ON fa.CdOrgao = pFolha.CdOrgao
                   AND fa.NuAnoReferencia = pFolha.NuAnoReferencia
                   AND fa.NuMesReferencia = TMes.Mes
                   AND fa.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoDifMes
                   AND fa.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento
                 INNER JOIN EPagFolhaPagamento fn
                    ON fn.CdOrgao = pFolha.CdOrgao
                   AND fn.NuAnoReferencia = pFolha.NuAnoReferencia
                   AND fn.NuMesReferencia = TMes.Mes
                   AND fn.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoNormal
                   AND fn.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento
                   AND fn.FlCalculoDefinitivo = 'S') LOOP

      vTabFolhaPagamentoDifMes(rec.Mes).CdFolhaDifMes := rec.CdFolhaPagamento;
      vTabFolhaPagamentoDifMes(rec.Mes).DtCalculo := rec.DtCalculo;

    END LOOP;

    RETURN vTabFolhaPagamentoDifMes;

  END;

  PROCEDURE PInicializaVariaveis(pVinculo   IN XTMPAG_TIPO.rVinculo,
                                 pDtCalculo IN DATE) IS

    x INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    -- Constantes

    XTMPAG_VAR.vgValorBaseIRRF := 0;

    XTMPAG_VAR.vgVlTotalDescontos := 0;

    XTMPAG_VAR.vgVlTotalProventos := 0;

    XTMPAG_VAR.vgVlTotalDescontosFacult := 0;

    XTMPAG_VAR.vgVlBase1467 := 0;

    XTMPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;

    XTMPAG_var.vNuDiasAuxAlimNaoDesc := 0;

    XTMPAG_var.vDescAuxAlimNaoDesc := null;

    XTMPAG_VAR.vgVlIntegralIPREV := 0;

    XTMPAG_VAR.bPossuiDisposicao := FALSE;

    IF XTMPAG_VAR.vgPercentAcumATS.COUNT > 0 THEN

      x := XTMPAG_VAR.vgPercentAcumATS.FIRST;

      WHILE x IS NOT NULL LOOP

        XTMPAG_VAR.vgPercentAcumATS(x) := 0;

        x := XTMPAG_VAR.vgPercentAcumATS.NEXT(x);

      END LOOP;

    END IF;

    XTMPAG_VAR.vPagaSitDisposicao := 'NAO(EFETIVO/DISPOSICAO)';

    XTMPAG_VAR.bProcessaBloqueio := FALSE;

    XTMPAG_VAR.vgQtFaltas := 0;

    XTMPAG_VAR.vgRecolhimentoAvulso := NULL;

    XTMPAG_VAR.vgCdEstruturaCarreira := NULL;

    XTMPAG_VAR.bFlPossuiProventos := FALSE;

    XTMPAG_VAR.vgPercentPensaoNaoPrev := 0;

    XTMPAG_VAR.vgPercDecJudMargem := XTMPAG_CNS.FPercDecJudMargem(pVinculo.CdVinculo,
                                                                  XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                  XTMPAG_VAR.vgFolha.NuMesReferencia);

    XTMPAG_VAR.bReprocessou13Sal := FALSE;

    XTMPAG_VAR.bPossuiLancTesouraria := FALSE;

    XTMPAG_VAR.vgMediaCHOHoraAtividade := NULL;

    XTMPAG_VAR.vgCdRubricaHoraPlantao := 0;

    XTMPAG_VAR.vgNuIndiceHoraPlantao := 0;

    XTMPAG_VAR.bSemIntersticio := FALSE;

    XTMPAG_VAR.vPercentualTotalATS.DELETE;

    XTMPAG_VAR.vgListaRelTrab.DELETE;

    XTMPAG_VAR.vgListaContribSind.DELETE;

    ----------------------------------------------------------------------------------------
    -- Aplica reducao por afastamento remunerado -> Fazer leitura unica e armazenar na PRE
    ----------------------------------------------------------------------------------------

    XTMPAG_VAR.vgVlPercentReducao := XTMPAG_GERAL.FPercentReducaoSalario(pVinculo.CdVinculo,
                                                                         XTMPAG_VAR.vgFolha.DtInicioMes,
                                                                         XTMPAG_VAR.vgFolha.DtFimMes,
                                                                         pDtCalculo);

    ------------------------------------------------------------
    -- Incializa variaveis dos eventos que sao processados
    ------------------------------------------------------------

    XTMPAG_VAR.vgCdRubAbonoPecuniario := NULL;

    XTMPAG_VAR.vgCdRubAbono13Ferias := NULL;

    XTMPAG_VAR.vgCdRubAdiantSalFerias := NULL;

    XTMPAG_VAR.vgCdRubValeTransporte := NULL;

    XTMPAG_VAR.vgCdRubDevUmTercoFerias := NULL;

    XTMPAG_VAR.vgCdRubDifUmTercoFerias := NULL;

    XTMPAG_VAR.vgCdRubricaRecisao13 := 0;

    XTMPAG_VAR.vgCdRubricaRecisao13CTISP := 0;

    XTMPAG_VAR.vgCdRubricaRecisao13PENSAO := 0;

    -- TODO: Text="Excluir XTMPAG_VAR.bPossuiObito, XTMPAG_VAR.vCdPessoa, XTMPAG_VAR.vgCdOrgaoVinculo, XTMPAG_VAR.vgCdVinculo"
    XTMPAG_VAR.vgCdOrgaoVinculo := pVinculo.CdOrgao;

    XTMPAG_VAR.vCdPessoa := pVinculo.CdPessoa;

    XTMPAG_VAR.bPossuiObito := pVinculo.bPossuiObito;

    XTMPAG_VAR.vgCdVinculo := pVinculo.CdVinculo;

    XTMPAG_VAR.vgVlRefTetoDecJud := NULL;

    XTMPAG_VAR.vgCdValRefTetoDecJud := NULL;

    XTMPAG_VAR.vCdRelacaoTrabalhoCCO := NULL;

    XTMPAG_VAR.vCdOpcaoRemuneracaoCCO := NULL;

    XTMPAG_VAR.vgValorFixoCEF.vlFixo := NULL;

    XTMPAG_VAR.vgValorFixoCEF.NuCargaHoraria := 0;

    XTMPAG_VAR.bPossuiAfastNaoRemunUltDiaMes := FALSE;

    XTMPAG_VAR.bPossuiAfastRemunUltDiaMes := FALSE;

    XTMPAG_VAR.vgCdRubFeriasIndenizadas := NULL;

    XTMPAG_VAR.vgCdRubFeriasIndenUmTerco := NULL;

    XTMPAG_VAR.vgCdRubFeriasIndenizadasACTSJC := NULL;

    XTMPAG_VAR.vgCdRubFeriasIndenizadasVinc := NULL;

    XTMPAG_VAR.vgPercentATS :=  vvgPercentATS;

    XTMPAG_VAR.vgCdRubricaDevAnt13 := NULL;

    XTMPAG_VAR.vgCdRubUmTercoFerias := NULL;

    XTMPAG_VAR.vgCdRubDifAbonoPecuniario := NULL;

    XTMPAG_VAR.vgCdRubFeriasFGTS := NULL;

    XTMPAG_VAR.vgCdRubDescTetoGovernador := NULL;

    XTMPAG_VAR.vgCdRubDescTetoGovernador13 := NULL;

    XTMPAG_VAR.vgCdRubDescPlanSauAgr       := NULL;

    XTMPAG_VAR.vgCdEventoDescCoPart        := NULL;

    XTMPAG_VAR.vgCdRubDescPlanSauTit       := NULL;

    XTMPAG_var.vgCdRubDescCPSM             := NULL;

    XTMPAG_var.vgDtInicioConcessaoAbonoPerm := NULL;

  END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Processamento do Vinculo - Parte Erario
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarVincCalcErario(rVinculo             IN XTMPAG_TIPO.rVinculo,
                                     pFlCalculoDefinitivo IN CHAR) IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_GERAL.PLogProcIni('4-3-5.Atu Ret/Rep');

    IF XTMPAG_VAR.vgFolha.CdTipoFolha IN
       (XTMPAG_TIPO.cnTpFolhaNormal,
        XTMPAG_TIPO.cnTpFolhaBolsista,
        XTMPAG_TIPO.cnTpFolhaResidente,
        XTMPAG_TIPO.cnTpFolhaPesquisador,
        XTMPAG_TIPO.cnTpFolhaConvenio,
        XTMPAG_TIPO.cnTpFolhaServAfast,
        XTMPAG_TIPO.cnTpFolhaCtisp)
       OR XTMPAG_VAR.vgFolha.CdTipoFolhaPagamento = 765  -- FOLHA PDVI CIASC
       OR XTMPAG_VAR.vgFolha.CdTipoFolhaPagamento = 1285 -- FOLHA PDVI CIDASC
       OR XTMPAG_VAR.vgFolha.CdTipoFolhaPagamento = 1706 -- FOLHA PDVI EPAGRI

     THEN

      IF XTMPAG_VAR.vgFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoNormal THEN

        IF pFlCalculoDefinitivo = 'S' THEN

          XTMPAG_LF.PAtualizaHistoricoLancamento(XTMPAG_VAR.vgFolha,
                                                 rVinculo.CdVinculo);

          XTMPAG_POS.PAtualizaEventoVinculo(pCdVinculo    => rVinculo.CdVinculo,
                                            pFolha        => XTMPAG_VAR.vgFolha,
                                            pCdTipoEvento => 1); -- Contribuicao Sindical

--          XTMPAG_PC.PAtualizaSituacaoRetro(pCdVinculo => rVinculo.CdVinculo,
--                                           pFolha     => XTMPAG_VAR.vgFolha);

--          XTMPAG_PC.PAtualizaSituacaoCompensacao(pCdVinculo => rVinculo.CdVinculo,
--                                                 pFolha     => XTMPAG_VAR.vgFolha);

        END IF;

--        XTMPAG_PC.PAtualizaSituacaoErario(pCdVinculo => rVinculo.CdVinculo,
--                                          pFolha     => XTMPAG_VAR.vgFolha);

      ELSIF (XTMPAG_VAR.vgFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoSupl AND
            pFlCalculoDefinitivo = 'S') THEN


        XTMPAG_RT.PAtualizaParcelaRetroativo(pFolha     => XTMPAG_VAR.vgFolha,
                                             pCdVinculo => rVinculo.CdVinculo);

--        XTMPAG_PC.PAtualizaSituacaoRetro(pCdVinculo => rVinculo.CdVinculo,
--                                         pFolha     => XTMPAG_VAR.vgFolha);

--        XTMPAG_PC.PAtualizaSituacaoCompensacao(pCdVinculo => rVinculo.CdVinculo,
--                                               pFolha     => XTMPAG_VAR.vgFolha);

      else
        null;
      END IF;

    END IF;

    XTMPAG_GERAL.PLogProcFim('4-3-5.Atu Ret/Rep');

  END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Processamento do Vinculo - Parte Integral
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarVincCalcIntegral(pCalculo             IN rCalculo,
                                       rVinculo             IN OUT XTMPAG_TIPO.rVinculo,
                                       pDtCalculo           IN DATE,
                                       pFlCalculoDefinitivo IN CHAR,
                                       pFlPagaAdiantamento  IN CHAR) IS

    /*TYPE rRelVinc IS RECORD(
      CdRelacaoTrabalho       INTEGER,
      DtInicio                DATE,
      CdUnidadeOrganizacional INTEGER,
      NuCargaHoraria          NUMBER(7,4));
    vRelVinc rRelVinc;*/

    vSgOrgao VARCHAR2(20);
    bGerouTotalizadoras BOOLEAN;
    vvlBaseBaixa NUMBER(13, 2);
    vVlDesc050524 NUMBER(13,2);
    vVlNaoDesc050524 number(13,2);
    vVlDescReal050524 number(13,2);
    vVlDescFaltas number(13,2);
    vDtInicioDireito DATE;
    vDtInclusao DATE;
    vCdRetorno INTEGER DEFAULT 1;
    i INTEGER;
    vCdExpressaoFormula INTEGER;
    vTemDifMes BOOLEAN;
    vNuFaltas tFalta;
    vNuMEsFalta INTEGER;
    vAfast XTMPAG_TIPO.tAfastamento;
    vValorCalcRubrica XTMPAG_TIPO.tValorCalculoRubrica;
    --vFlAtivo CHAR :=  'S';
    vvlBaseIprev13SalResc XTMPAG_tipo.rvalorpagamento;
    Vvalor011207 number(17,2);
    VValor020023 number(17,2) :=187.20;
    Vvalor050246 number(17,2) := 51.48;
    Vcdvinculo   integer := 512666;
    vcdfolha     integer := 417241;

    PROCEDURE pDifVlPagamentoVincSemRemun(pCdVinculo        IN INTEGER,
                                       pCdFolhaPagamento IN INTEGER,
                                       pNuAnoReferencia  IN INTEGER,
                                       pNuMesReferencia  IN INTEGER,
                                       pCdTipoFolha      IN INTEGER,
                                       pCdTipoCalculo    IN INTEGER) IS
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      FOR vHistRub IN (SELECT HRV.Vlpagamento, HRV.Vlindicerubrica, FP.CdFolhaPagamento, HRV.Cdrubricaagrupamento
                         FROM EPagHistoricoRubricaVinculo HRV
                        INNER JOIN EPagFolhaPagamento FP
                           ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
                        INNER JOIN EPagTipoFolhaPagamento TFP
                           ON TFP.CdTipoFolhaPagamento =
                              FP.CdTipoFolhaPagamento
                         INNER JOIN vpagrubricaagrupamento R
                            ON R.cdrubricaagrupamento = HRV.Cdrubricaagrupamento
                           --AND R.CdTipoRubrica IN (1, 2, 4) -- Proventos
                        WHERE HRV.CdVinculo = pCdVinculo
                          AND FP.CdTipoCalculo = pCdTipoCalculo
                          AND FP.NuAnoReferencia = pNuAnoReferencia
                          AND FP.NuMesReferencia = pNuMesReferencia
                          AND FP.FlCalculoDefinitivo = XTMPAG_TIPO.cnS
                          AND FP.CdFolhaPagamento <> pCdFolhaPagamento) LOOP

           BEGIN

           FOR vRub IN (SELECT HRV.Vlpagamento, HRV.Vlindicerubrica, FP.CdFolhaPagamento
                         FROM EPagHistoricoRubricaVinculo HRV
                        INNER JOIN EPagFolhaPagamento FP
                           ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
                        INNER JOIN EPagTipoFolhaPagamento TFP
                           ON TFP.CdTipoFolhaPagamento =
                              FP.CdTipoFolhaPagamento
                         INNER JOIN vpagrubricaagrupamento R
                            ON R.cdrubricaagrupamento = HRV.Cdrubricaagrupamento
                           --AND R.CdTipoRubrica IN (1, 2, 4) -- Proventos
                        WHERE HRV.CdVinculo = pCdVinculo
                          AND HRV.Cdrubricaagrupamento = vHistRub.Cdrubricaagrupamento
                          AND FP.CdFolhaPagamento = pCdFolhaPagamento) LOOP

                          IF NVL(vRub.Vlpagamento,0) > NVL(vHistRub.Vlpagamento,0)
                            THEN

                            UPDATE EPagHistoricoRubricaVinculo rv
                                 SET rv.vlpagamento = vRub.Vlpagamento - vHistRub.Vlpagamento,
                                       rv.vlindicerubrica = vRub.Vlindicerubrica - vHistRub.Vlindicerubrica
                               WHERE rv.cdfolhapagamento = pCdFolhaPagamento
                                 AND rv.cdvinculo = PCdVinculo
                                 AND rv.cdrubricaagrupamento = vHistRub.Cdrubricaagrupamento;

                           UPDATE epaghistoricorubricarelvinc hh
                                 SET hh.vlintegral = vRub.Vlpagamento - vHistRub.Vlpagamento,
                                     hh.vlproporcional = vRub.Vlpagamento - vHistRub.Vlpagamento,
                                     hh.vlindicerubrica = vRub.Vlindicerubrica - vHistRub.Vlindicerubrica
                               WHERE hh.cdfolhapagamento = pCdFolhaPagamento
                                 AND hh.cdvinculo = pCdVinculo
                                 AND hh.cdrubricaagrupamento = vHistRub.Cdrubricaagrupamento;

                          END IF;

           END LOOP;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            NULL;

        END;

      END LOOP;

    END;

    PROCEDURE PTrataSufixosDuplicados(pCdVinculo        IN INTEGER,
                                      pCdFolhaPagamento IN INTEGER) IS

      vNuSufixoRubrica INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      -- Descobre rubricas com sufixo duplicado, somando o valor do que for de decisao judicial
      FOR rubSufixoDuplicado IN (

                                 SELECT hrv.CdRubricaAgrupamento,
                                         sum(case
                                               when hrv.cdtipoorigemrubrica = 3 then -- JUD
                                                hrv.vlpagamento
                                               else
                                                0
                                             end) as somaVlPagamentoDecJud,
                                         max(case
                                               when hrv.cdtipoorigemrubrica = 3 then -- JUD
                                                hrv.cdhistoricorubricavinculo
                                               else
                                                0
                                             end) as maxCdHistRubricaVinculoDecJud
                                   FROM ePagHistoricoRubricaVinculo hrv
                                  WHERE hrv.CdVinculo = pCdVinculo
                                    AND hrv.CdFolhaPagamento =
                                        pCdFolhaPagamento
                                  GROUP BY hrv.CdRubricaAgrupamento,
                                            hrv.NuSufixoRubrica
                                 HAVING COUNT(*) > 1)

       LOOP

        vNuSufixoRubrica := 0;

        -- Regera todos sufixos das rubricas duplicadas que nao forem de decisao judicial
        FOR regHistoricoRubricaVinculo IN (

                                           SELECT hrv.CdHistoricoRubricaVinculo,
                                                   hrv.cdtiporubricaorigem
                                             FROM ePagHistoricoRubricaVinculo hrv
                                            WHERE hrv.cdvinculo = pCdVinculo
                                              AND hrv.CdFolhaPagamento =
                                                  pCdFolhaPagamento
                                              AND hrv.CdRubricaAgrupamento =
                                                  rubSufixoDuplicado.CdRubricaAgrupamento
                                              AND hrv.cdtipoorigemrubrica <> 3 -- DIFERENTE DE JUD
                                            ORDER BY hrv.CdLancamentoFinanceiro

                                           )

         LOOP

          vNuSufixoRubrica := vNuSufixoRubrica + 1;

          -- RUBRICAS DUPLICADAS NaO ORIUNDAS DE DECISoES JUDICIAIS: ATUALIZA SUFIXO
          UPDATE ePagHistoricoRubricaVinculo hrv
             SET hrv.NuSufixoRubrica = vNuSufixoRubrica
           WHERE hrv.CdHistoricoRubricaVinculo =
                 regHistoricoRubricaVinculo.CdHistoricoRubricaVinculo;

        END LOOP;

        -- DECISoES JUDICIAIS: PAGAMENTO EM UMA uNICA RUBRICA, SOMANDO-SE OS VALORES
        IF rubSufixoDuplicado.maxCdHistRubricaVinculoDecJud > 0 THEN

          vNuSufixoRubrica := vNuSufixoRubrica + 1;

          -- ATUALIZA VALOR DA RUBRICA SUFIXO DE DECISaO JUDICIAL COM A SOMA
          UPDATE ePagHistoricoRubricaVinculo hrv
             SET hrv.NuSufixoRubrica = vNuSufixoRubrica,
                 hrv.vlpagamento     = rubSufixoDuplicado.somaVlPagamentoDecJud
           WHERE hrv.CdHistoricoRubricaVinculo =
                 rubSufixoDuplicado.maxCdHistRubricaVinculoDecJud;

          -- DELETA DEMAIS RUBRICAS DUPLICADAS DE DECISaO JUDICIAL
          DELETE FROM ePagHistoricoRubricaVinculo hrv
           WHERE hrv.cdvinculo = pCdVinculo
             AND hrv.CdFolhaPagamento = pCdFolhaPagamento
             AND hrv.CdRubricaAgrupamento =
                 rubSufixoDuplicado.CdRubricaAgrupamento
             AND hrv.cdtipoorigemrubrica = 3
             AND hrv.CdHistoricoRubricaVinculo <>
                 rubSufixoDuplicado.maxCdHistRubricaVinculoDecJud;

        END IF;

      END LOOP;

    END;

    FUNCTION FLocalTrabalhoVigente(pCdVinculo   IN INTEGER,
                                   pDtInicioMes IN DATE,
                                   pDtFimMes    IN DATE) RETURN BOOLEAN IS

      vCont INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT COUNT(*)
        INTO vCont
        FROM ECadLocalTrabalho LT
       WHERE LT.CdVinculo = pCdVinculo
         AND LT.DtInicio <= pDtFimMes
         AND (LT.DtFim >= pDtInicioMes OR LT.DtFim IS NULL);

      IF vCont > 0 THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    END;

    FUNCTION FVinculoComFolhaCalculada(pCdVinculo        IN INTEGER,
                                       pCdFolhaPagamento IN INTEGER,
                                       pNuAnoReferencia  IN INTEGER,
                                       pNuMesReferencia  IN INTEGER,
                                       pCdTipoFolha      IN INTEGER,
                                       pCdTipoCalculo    IN INTEGER)
      RETURN VARCHAR2 IS

      vSgOrgao VARCHAR2(20);

      vCont INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

       ---------------------------------------------------------------------------------
      --                                                           ~                   --
      --     xxx     xxxxxxx     xxxx      xx  x       xxxxx      xxx        xxxxx     --
      --    x   x      xxx      x         x x  x      xx         x   x      xx   xx    --
      --    xxxxxx      x       xxxx      x  x x      x          xxxxxx     x     x    --
      --    x   xx      x       x         x  x x      xx         x   xx     xx   xx    --
      --    x   xx      x       xxxxx     x   xx       xxxxx     x   xx      xxxxx     --
      --                                                 /                             --
      --                                                                               --
      --  A QUERY ABAIXO FOI AJUSTADA PELO VICTOR PARA TER MELHOR PERFORMANCE          --
      --     QUALQUER ALTERAÇÃO PRECISA SER PASSADA PRA ELE AJUSTAR NOVAMENTE          --
      FOR vHistRub IN (SELECT FP.CdOrgao, FP.CdFolhaPagamento                          --
                         FROM EPagHistoricoRubricaVinculo HRV                          --
                        INNER JOIN EPagFolhaPagamento FP                               --
                           ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento               --
                        INNER JOIN EPagTipoFolhaPagamento TFP                          --
                           ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento       --
                        WHERE HRV.CdVinculo = pCdVinculo                               --
                          AND TFP.CdTipoFolha = pCdTipoFolha                           --
                          AND FP.CdTipoCalculo = pCdTipoCalculo                        --
                          AND FP.NuAnoReferencia = pNuAnoReferencia                    --
                          AND FP.NuMesReferencia = pNuMesReferencia                    --
                          AND FP.FlCalculoDefinitivo = XTMPAG_TIPO.cnS                 --
                          AND FP.CdFolhaPagamento <> pCdFolhaPagamento) LOOP           --
      ----------------------------------------------------------------------------------
       --------------------------------------------------------------------------------

        BEGIN

          SELECT 1
            INTO vCont
            FROM EPagHistoricoRubricaVinculo HRV
           INNER JOIN EPagRubricaAgrupamento RA
              ON RA.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
           INNER JOIN EPagRubrica R
              ON R.CdRubrica = RA.CdRubrica
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = vHistRub.CdFolhaPagamento
             AND R.CdTipoRubrica IN (1, 2, 4, 10, 12)
             AND ROWNUM < 2;

          SELECT sgOrgao
            INTO vSgOrgao
            FROM ECadHistOrgao
           WHERE CdOrgao = vHistRub.CdOrgao
             AND ROWNUM = 1;

          RETURN vSgOrgao;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            NULL;

        END;

      END LOOP;

      RETURN NULL;

    END;

    FUNCTION FRelTrabPermitidoTpFolha RETURN BOOLEAN IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF rVinculo.DtDesligamento < XTMPAG_VAR.vgFolha.DtInicioMes THEN

        IF XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaBolsista THEN

          IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
             XTMPAG_TIPO.cnRelEstagiario THEN

            RETURN FALSE;

          END IF;

        ELSIF XTMPAG_VAR.vgFolha.CdTipoFolha =
              XTMPAG_TIPO.cnTpFolhaResidente THEN

          IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
             XTMPAG_TIPO.cnRelResidente THEN

            RETURN FALSE;

          END IF;

        ELSIF XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaPesquisador THEN

          IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
             XTMPAG_TIPO.cnRelPesquisador THEN

            RETURN FALSE;

          END IF;

        ELSE

          IF XTMPAG_VAR.vgFolha.CdTipoFolha <>
             XTMPAG_TIPO.cnTpFolhaRescisao AND
             XTMPAG_VAR.vgParamPagamento.FlPagaRecisaoFolhaEspec = 'S' THEN

            RETURN FALSE;

          END IF;

          IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento IN
             (XTMPAG_TIPO.cnRelEstagiario,
              XTMPAG_TIPO.cnRelResidente,
              XTMPAG_TIPO.cnRelPesquisador) THEN

            RETURN FALSE;

          END IF;

        END IF;

      ELSIF rVinculo.DtDesligamento >= XTMPAG_VAR.vgFolha.DtInicioMes THEN

        IF XTMPAG_VAR.vgFolha.CdTipoFolha NOT IN
           (XTMPAG_TIPO.cnTpFolhaBolsista,
            XTMPAG_TIPO.cnTpFolhaResidente,
            XTMPAG_TIPO.cnTpFolhaPesquisador,
            XTMPAG_TIPO.cnTpFolhaRescisaoEstagiario,
            XTMPAG_tipo.cnTpFolhaRescisaoPesquisador,
            XTMPAG_TIPO.cnTpFolhaConvenio) AND
           XTMPAG_VAR.vgBOL.COUNT > 0 THEN

          RETURN FALSE;

        ELSIF XTMPAG_VAR.vgFolha.CdTipoFolha IN
              (XTMPAG_TIPO.cnTpFolhaBolsista,
               XTMPAG_TIPO.cnTpFolhaResidente,
               XTMPAG_TIPO.cnTpFolhaPesquisador) AND
              (XTMPAG_VAR.vgCEF.COUNT > 0 OR XTMPAG_VAR.vgCCO.COUNT > 0 OR
              XTMPAG_VAR.vgAPO.COUNT > 0) THEN

          RETURN FALSE;

        ELSIF XTMPAG_VAR.vgFolha.CdTipoFolha <>
              XTMPAG_TIPO.cnTpFolhaRescisao AND XTMPAG_VAR.vgParamPagamento.FlPagaRecisaoFolhaEspec =
              XTMPAG_TIPO.cnS THEN

          RETURN FALSE;

        else
          null;
        END IF;

      ELSE

        IF rVinculo.DtDesligamento IS NULL AND
           XTMPAG_VAR.vgFolha.CdTipoFolha IN
           (XTMPAG_TIPO.cnTpFolhaRescisao) THEN

          RETURN FALSE;

        END IF;

      END IF;

      RETURN TRUE;

    END;

    ----------------------------------------------------------------------------------
    -- Atualiza o valor da base contribuicao do plano de saude ( Modalidade 21)
    -- abatendo as rubricas do tipo 8 que fazem parte da expressao do calculo da base
    -----------------------------------------------------------------------------------
    PROCEDURE PAtualizaBaseSCSaude (pCdVinculo INTEGER) IS
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;
      if nvl(XTMPAG_VAR.vgIndiceFaltasMesAnterior,0) < 30 then
         -- Solicitacao de Sustentacao  #79983
         -- 12316/2018 - FALTAS PRIORIDADE SOBRE DESC SC SAUDE
         -- Somente descontar plano de saude se o total de faltas do mes anterior nao estiver zerando o contra cheque.
         -- na rotina de liquido negativo eh feito um ajuste especifico nesta rubrica de faltas e o calculo
         -- acabava compensando as diferencas, ou seja, permitia o desconto do scsaude e depois ajustava a diferenca no
         -- desconto de faltas.

         -- Solicitacao de Sustentacao #80157
         -- 12458/2018 - FOLHA - - PROCESSAMENTO DA SCSAUDE
         -- Alterada ordem de calculo do SCSAUDE para apos a tributacao

         XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento, pCdVinculo);

         if XTMPAG_VAR.vgVlTotalProventos > XTMPAG_VAR.vgVlTotalDescontos
           or XTMPAG_VAR.vgFolha.cdorgao = 33 then

            XTMPAG_pos.pDescontoPlanoSaude(pCdVinculo);

        end if;

      end if;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack(rVinculo.CdVinculo);

--pInsereLogDebug('t', 1, rVinculo.CdVinculo, null, null, null, null, null, null, null, null, null, 0);

    XTMPAG_VAR.vgFaseCalculo := XTMPAG_TIPO.cnFaseCalculoIntegral;

    XTMPAG_VAR.bTemDireitoLancFin := TRUE;


     IF XTMPAG_VAR.vgFolha.cdtipofolha = XTMPAG_tipo.cnTpFolhaServAfast
        THEN

        PAnulaAfastTempNaoRemun(pCdVinculo => rVinculo.CdVinculo,
                                               pDtCalculo => XTMPAG_var.vgFolha.dtCalculo,
                                               pcdAgrupamento => XTMPAG_var.vgFolha.cdAgrupamento);

    END IF;

    IF XTMPAG_VAR.vgFolha.CdTipoCalculo =
       XTMPAG_TIPO.cnTpCalculoRecalculoMes AND
       XTMPAG_VAR.vgFolha.FlOrgaoImplantado = 'N' AND
       TRUNC(rVinculo.DtInclusao) > pDtCalculo THEN

      RETURN;

    END IF;

    ----------------------------------------------------------------
    -- Armazena vinculo para execucao de pos-calculo
    ----------------------------------------------------------------

    XTMPAG_VAR.vgVinculo := rVinculo;

    ----------------------------------------------------------------
    -- Armazena as relacoes vinculo vigentes
    -- Obs: Chama mesmo se o vinculo estiver desligado para inicializar
    --      variaveis
    ----------------------------------------------------------------

    XTMPAG_GERAL.PLogProcIni('4-3-1.Armz Rel Vinc');

    XTMPAG_GERAL.PArmazenaRelacoesVinculo(rVinculo.CdVinculo);

    -- SIG-5785
    -- Rubrica 10-0356 na folha normal - Folha CTISP DPESC

    if XTMPAG_var.bPossuiCtisp and
      XTMPAG_VAR.vgFolha.CdTipoFolha not IN
       (XTMPAG_tipo.cnTpFolhaCtisp, XTMPAG_tipo.cnTpFolhaCtisp13) and
      XTMPAG_VAR.vgFolha.CdAgrupamento = 176

       then

       return;

    end if;

    ----------------------------------------------------------------
    -- Verifica se a ultima relacao e compativel com o tipo de folha
    -- para desligados antes do inicio do mes de processamento
    ----------------------------------------------------------------
    IF NOT FRelTrabPermitidoTpFolha THEN

      GOTO FIM_LOOP;

    END IF;

    XTMPAG_GERAL.PLogProc('4-3-1.Armz Rel Vinc', '4-3-2.Bloco Intermed');

    -------------------------------------------------------------------------
    -- Tratamento do bloqueio de credito
    -------------------------------------------------------------------------

    XTMPAG_GERAL.PLogProcIni('4-3-2-1.Trata Bloqueio');

    XTMPAG_GERAL.PTrataBloqueioCredito;

    IF XTMPAG_VAR.vgVinculo.FlPagamentoBloqueado = 'A'
      AND XTMPAG_VAR.vgFolha.CdOrgao = 33
      THEN
        XTMPAG_VAR.vgVinculo.FlPagamentoBloqueado := 'S';
        GOTO FIM_LOOP;

    END IF;

    rVinculo.FlPagamentoBloqueado := XTMPAG_VAR.vgVinculo.FlPagamentoBloqueado;

    XTMPAG_GERAL.PLogProcFim('4-3-2-1.Trata Bloqueio');

    IF NVL(rVinculo.DtDesligamento, XTMPAG_TIPO.cnDtMax) >=
       XTMPAG_VAR.vgFolha.DtInicioMes AND
       rVinculo.CdSituacaoPrevidenciaria = 0 AND
       (XTMPAG_VAR.vgCEF.COUNT > 0 OR XTMPAG_VAR.vgCCO.COUNT > 0 OR
        XTMPAG_VAR.vgAPO.COUNT > 0 OR XTMPAG_VAR.vgBOL.COUNT > 0) THEN

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'O vinculo nao possui situacao previdenciaria vigente.',
                              XTMPAG_VAR.vgCdVinculo);

      GOTO FIM_LOOP;

    END IF;

    -----------------------------------------------------------
    -- Tratamento de folha de rescisão
    -----------------------------------------------------------

    IF XTMPAG_VAR.vgFolha.cdAgrupamento not in (1, 134, 176, 276) THEN

        XTMPAG_GERAL.PLogProcIni('4-3-2-2.Trata Rescisão');

        -- Não paga rescisão para quem não tem registro de rescisão
        IF  XTMPAG_VAR.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolhaRescisao, XTMPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                                               XTMPAG_tipo.cnTpFolhaRescisaoPesquisador) -- Folha de Rescisão
            AND NOT FPossuiRescisao(XTMPAG_VAR.vgCdVinculo) AND XTMPAG_var.vgFolha.CdTipoFolhaPagamento NOT IN (1706,1707,765,1285,1686) THEN


          XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  XTMPAG_VAR.vCdPessoa,
                                  'Vinculo NÃO possui RESCISÃO. Matrícula: ' || FDadosServidorDesligado(XTMPAG_VAR.vgCdVinculo),
                                  XTMPAG_VAR.vgCdVinculo,
                                  2);

          GOTO FIM_LOOP;

        END IF;

        -- Não paga rescisão para quem já tem folha de rescisão fechada
        /*IF XTMPAG_VAR.vgFolha.CdTipoFolha = 2 -- Folha de Rescisão
           AND FPossuiFolhaRescisao(XTMPAG_VAR.vgCdVinculo) THEN


          XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  XTMPAG_VAR.vCdPessoa,
                                  'Vinculo já possui FOLHA DE RESCISÃO fechada. Matrícula: ' || FDadosServidorDesligado(XTMPAG_VAR.vgCdVinculo),
                                  XTMPAG_VAR.vgCdVinculo,
                                  2);

          GOTO FIM_LOOP;

        END IF;*/

        -- Não paga rescisão em folha diferente de folha de rescisão
        IF XTMPAG_VAR.vgFolha.CdTipoFolha NOT IN (XTMPAG_TIPO.cnTpFolhaRescisao, XTMPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                                                  XTMPAG_tipo.cnTpFolhaRescisaoPesquisador,XTMPAG_TIPO.cnTpFolhaFunebre) -- Folha de Rescisão
           AND FPossuiRescisao(XTMPAG_VAR.vgCdVinculo) AND XTMPAG_var.vgFolha.CdTipoFolhaPagamento NOT IN (1706,1707,765,1285,1686)
           AND NVL(rVinculo.DtDesligamento, XTMPAG_TIPO.cnDtMax) >= XTMPAG_VAR.vgFolha.dtCalculoAnt THEN


          XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  XTMPAG_VAR.vCdPessoa,
                                  'Vinculo possui RESCISÃO. Matrícula: ' || FDadosServidorDesligado(XTMPAG_VAR.vgCdVinculo),
                                  XTMPAG_VAR.vgCdVinculo);

          GOTO FIM_LOOP;

        END IF;

        XTMPAG_GERAL.PLogProcFim('4-3-2-2.Trata Rescisão');

    END IF;
    -------------------------------------------------------------------------

    IF NOT XTMPAG_VAR.bCalculaVinculo THEN

      RETURN;

    END IF;

    -------------------------------------------------------------------------------------
    -- Seta Flags para saber se o vinculo possui rubricas isentas
    -- Obs: Variaveis Utilizadas na tributacao e na execucao de formulas
    -------------------------------------------------------------------------------------

    XTMPAG_GERAL.PLogProc('4-3-2.Bloco Intermed', '4-3-3.Set Trib');

    IF XTMPAG_var.vgFolha.cdtipofolha <> XTMPAG_TIPO.cnTpFolhaInstPensao
       THEN

        XTMPAG_TRIBUTACAO.PSetaRurbicasIsentas(pFolha     => XTMPAG_VAR.vgFolha,
                                               pCdVinculo => rVinculo.CdVinculo);

    END IF;
    ---------------------------------------------------------------------------------
    --  Em virtude do sistema legado, pode ocorrer de uma pessoa possuir
    --  dois vinculos vigentes no mesmo orgao, sendo um com relacao de bolsista.
    --  A condicao abaixo impede de calcular o vinculo caso a folha seja de bolsista
    --  e o vinculo nao possua relacao de bolsista no vinculo
    ---------------------------------------------------------------------------------

    IF (XTMPAG_VAR.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolhaResidente) AND
       XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
       XTMPAG_TIPO.cnRelResidente) OR
       (XTMPAG_VAR.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolhaBolsista) AND
       XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
       XTMPAG_TIPO.cnRelEstagiario) OR
       (XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaPesquisador AND XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
       XTMPAG_TIPO.cnRelPesquisador) THEN

      GOTO FIM_LOOP;

    END IF;

    XTMPAG_GERAL.PLogProc('4-3-3.Set Trib', '4-3-4.Rel Principal');

    IF (XTMPAG_VAR.vgRelVincPrincipal.CdHist IS NULL AND
       (rVinculo.DtDesligamento >= XTMPAG_VAR.vgFolha.DtInicioMes OR
       rVinculo.DtDesligamento IS NULL) AND
       (XTMPAG_VAR.vgCEF.COUNT > 0 OR XTMPAG_VAR.vgCCO.COUNT > 0 OR
       XTMPAG_VAR.vgAPO.COUNT > 0 OR XTMPAG_VAR.vgBOL.COUNT > 0)) THEN

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'O vinculo nao possui relacao de vinculo principal.',
                              XTMPAG_VAR.vgCdVinculo);

    ELSE

      ----------------------------------------------------------------------------
      -- Retorna 0 caso o servidor nao esteja afastado o mes inteiro
      -- Caso esteja afastado, gera a capa de lote com o motivo de afastamento
      ----------------------------------------------------------------------------

      XTMPAG_GERAL.PLogProcIni('4-3-4-1.Afast/Dec Jud');

      XTMPAG_VAR.vMotAfast := FAfastSemRemun(rVinculo.CdVinculo,
                                             XTMPAG_VAR.vgFolha.DtInicioMes,
                                             XTMPAG_VAR.vgFolha.DtFimMes,
                                             XTMPAG_VAR.vDtCalculo);

      -----------------------------------------------------------------------------
      -- Criar variaveis para os tipos de afastamento e periodos
      -----------------------------------------------------------------------------

        XTMPAG_VAR.vgNuDiasAfastRemun := 0;

        XTMPAG_VAR.vgAfastTempRemun := vAfast;

        XTMPAG_var.vgAfastAuxAlimentacao := vAfast;

        XTMPAG_VAR.vgAfastTempRemun := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                           XTMPAG_VAR.vgFolha.DtInicioMes,
                                                           XTMPAG_VAR.vgFolha.DtFimMes,
                                                           XTMPAG_VAR.vDtCalculo,
                                                           'R');

        XTMPAG_VAR.vgAfastAnulado := vAfast;

        XTMPAG_VAR.vgAfastAnulado := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                           XTMPAG_VAR.vgFolha.DtInicioMes,
                                                           XTMPAG_VAR.vgFolha.DtFimMes,
                                                           XTMPAG_VAR.vDtCalculo,
                                                           'A');   --Anulados

        XTMPAG_VAR.vgAfastTempRemunMesAnt := vAfast;

        XTMPAG_VAR.vgAfastTempRemunMesAnt := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                           ADD_MONTHS(XTMPAG_VAR.vgFolha.DtInicioMes, -1),
                                                           last_day(XTMPAG_VAR.vgFolha.DtCalculoAnt),
                                                           XTMPAG_VAR.vDtCalculo,
                                                           'R');

        XTMPAG_VAR.vgNuDiasAfastSemRemun := 0;

        XTMPAG_VAR.vgNuDiasAfastRetroativo := 0;

        XTMPAG_VAR.vgNuDiasAfastAuxAlimRet := 0;

        XTMPAG_VAR.vgNuDiasAfastSemRemunMesAtual := 0;

        XTMPAG_VAR.vgAfastTempNaoRemun := vAfast;

        XTMPAG_VAR.vgAfastTempNaoRemun := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                              XTMPAG_VAR.vgFolha.DtInicioMes,
                                                              XTMPAG_VAR.vgFolha.DtFimMes,
                                                              XTMPAG_VAR.vDtCalculo,
                                                              'N');

        XTMPAG_VAR.vgNuDiasAfastDefinitivo := 0;

        XTMPAG_VAR.vgAfastDefinitivo := vAfast;

        XTMPAG_VAR.vgAfastDefinitivo := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                            XTMPAG_VAR.vgFolha.DtInicioMes,
                                                            XTMPAG_VAR.vgFolha.DtFimMes,
                                                            XTMPAG_VAR.vDtCalculo,
                                                            'D');

      XTMPAG_VAR.vgNuDiasTrabalhados := 30 - NVL(XTMPAG_VAR.vgNuDiasAfastSemRemunMesAtual,0);

      XTMPAG_VAR.vgNuDiasAfastRelVinc := 0;

      XTMPAG_VAR.vgAfastRelVinc := vAfast;

      XTMPAG_VAR.vgAfastRelVinc := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                       XTMPAG_VAR.vgFolha.DtInicioMes,
                                                       XTMPAG_VAR.vgFolha.DtFimMes,
                                                       XTMPAG_VAR.vDtCalculo,
                                                       'V',
                                                       XTMPAG_VAR.vgRelVincPrincipal.CdHist);

      -- Caso o vínculo possua rescisão préviA a folha anterior
      IF XTMPAG_VAR.vgNuDiasAfastDefinitivo >= 30 AND
       rVinculo.DtDesligamento <= XTMPAG_VAR.vgFolha.dtCalcULOAnt AND
       XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal AND
       (XTMPAG_VAR.vgCEF.COUNT > 0 OR XTMPAG_VAR.vgCCO.COUNT > 0 OR
       XTMPAG_VAR.vgAPO.COUNT > 0 OR XTMPAG_VAR.vgBOL.COUNT > 0) THEN

         XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'O vinculo possui rescisão prévia ao calculo anterior.',
                              XTMPAG_VAR.vgCdVinculo);
         GOTO FIM_LOOP;

      END IF;
      ---------------------------------------------------------------------------------------------
      -- Busca o valor do Bloqueio de Remuneracao - Teto
      -- Caso possua alguma decisao judicial para a rubrica do Teto do Governador
      -- busca o valor do teto/codigo do valor de referencia na sentenca do contrario seleciona da
      -- tabela de valor de referencia
      ---------------------------------------------------------------------------------------------

      IF XTMPAG_GERAL.FPossuiDecisaoJudicial(pCdVinculo       => rVinculo.CdVinculo,
                                             pNuAnoReferencia => XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                             pNuMesReferencia => XTMPAG_VAR.vgFolha.NuMesReferencia,
                                             pCdRubrica       => XTMPAG_VAR.vgCdRubricaTetoGov,
                                             pVlDecisaoJud    => XTMPAG_VAR.vgVlRefTetoDecJud,
                                             pCdValorRef      => XTMPAG_VAR.vgCdValRefTetoDecJud,
                                             pDtInicioDireito => vDtInicioDireito,
                                             pDtInclusao      => vDtInclusao) THEN

        XTMPAG_VAR.vgVlRefTetoDecJud := XTMPAG_VAR.vgVlRefTetoDecJud;

      END IF;

      ---------------------------------------------------------------------------------------------
      -- Carrega as informacoes de decisoes judiciais que interferem em retroativos
      -- e nas tributacoes
      ---------------------------------------------------------------------------------------------

      XTMPAG_RT.vgDecJudRetro := XTMPAG_RT.FDecJudIsencaoTributacao(XTMPAG_VAR.vgFolha,
                                                                    rVinculo.CdVinculo);

      -----------------------------------------------------------------------
      -- Armazena os codigos das rubricas 06-0915; 06-0926; 02,10,12-914 para
      -- verificar na leitura dos retroativos se existe decisao judicial
      -- mandando isentar o IPREV, o que implica a nao geracao das mesmas
      -----------------------------------------------------------------------
      XTMPAG_RT.SetaRubDifDescIPREV(pCdAgrupamento => XTMPAG_VAR.vgFolha.CdAgrupamento);

      XTMPAG_GERAL.PLogProc('4-3-4-1.Afast/Dec Jud', '4-3-4-2.CapaLote');

      ----------------------------------------------------------------------------
      -- Gera a capa de lote, caso o vinculo esteja afastado o mes todo
      ----------------------------------------------------------------------------

      IF XTMPAG_VAR.vMotAfast.InAfastado = XTMPAG_TIPO.cnAfastadoMesTodo THEN

        XTMPAG_GERAL.PGeraCapaLote(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                   pCdVinculo            => rVinculo.CdVinculo,
                                   pFlAtivo              => XTMPAG_geral.fflativo(rvinculo.CdVinculo, rvinculo.CdSituacaoPrevidenciaria),
                                   pMotAfast             => XTMPAG_VAR.vMotAfast,
                                   pFlPagamentoBloqueado => rVinculo.FlPagamentoBloqueado);

      END IF;

      XTMPAG_GERAL.PLogProcFim('4-3-4-2.CapaLote');

      -------------------------------------------------------------------------------
      -- Caso esteja afastado sem remuneracao o mes todo e possua retroativo
      -- ou desligado antes do inicio do mes
      -------------------------------------------------------------------------------

      IF (XTMPAG_VAR.vMotAfast.InAfastado = XTMPAG_TIPO.cnAfastadoMesTodo AND
         XTMPAG_GERAL.FPossuiLancRetroativo(pCdVinculo => rVinculo.CdVinculo,
                                                             pFolha     => XTMPAG_VAR.vgFolha) AND
         rVinculo.CdSituacaoPrevidenciaria <> 2) OR
         (XTMPAG_VAR.vMotAfast.InAfastado IN
         (XTMPAG_TIPO.cnAfastadoNao, XTMPAG_TIPO.cnAfastadoParcial)) OR

         (rVinculo.DtDesligamento < XTMPAG_VAR.vgFolha.DtInicioMes) OR

        -- CIASC/CIDASC, PROCESSA PARA TODOS OS AFASTADOS
         (
           XTMPAG_VAR.vgCdRubAgrupDescDiasAfast > 0
           AND XTMPAG_VAR.vMotAfast.InTipoAfastamento <> 'D'
           AND (
             (XTMPAG_VAR.vgFolha.CdAgrupamento = 2 AND XTMPAG_VAR.vMotAfast.cdChaveMotivo <> 9267)
             OR (
               XTMPAG_VAR.vgFolha.CdAgrupamento = 4
               AND XTMPAG_VAR.vMotAfast.FlProcessaNaoPaga = 'S'
             )
           )
         )
         OR (
           XTMPAG_VAR.vMotAfast.InTipoAfastamento = 'D'
           AND (XTMPAG_VAR.vgFolha.cdtipofolha IN (2, 23) OR (XTMPAG_VAR.vgFolha.CdAgrupamento IN (1,7,276) AND XTMPAG_VAR.vgFolha.cdtipofolha = 1))
           AND (XTMPAG_VAR.vgVinculo.DtDesligamento BETWEEN XTMPAG_VAR.vgFolha.DtInicioMes AND XTMPAG_VAR.vgFolha.DtFimMes)
         )
         OR

        -- PROCESSA PARA oRGaOS QUE PAGAM AUXILIO DOENcA E MOTIVO AFASTAMENTO AUXILIO DOENcA. (ex: SANTUR, EPAGRI)
         (XTMPAG_VAR.vMotAfast.InTipoAfastamento <> 'D' AND
         (XTMPAG_VAR.vMotAfast.FlAuxilioDoenca = XTMPAG_TIPO.cnS OR
         XTMPAG_VAR.vMotAfast.FlAcidenteTrabalho = XTMPAG_TIPO.cnS) AND
         XTMPAG_VAR.vgParamOrgao.FlAuxilioDoenca = XTMPAG_TIPO.cnS) OR

         (XTMPAG_VAR.vMotAfast.InPagaLancamento = XTMPAG_TIPO.cnS) OR

         (XTMPAG_var.vgrelvincprincipal.cdreltrabpagamento = XTMPAG_tipo.cnrelact AND
          XTMPAG_VAR.vgVinculo.DtDesligamento BETWEEN
          XTMPAG_VAR.vgFolha.DtInicioMes AND XTMPAG_VAR.vgFolha.DtFimMes)

      THEN

        ------------------------------------------------------------------------------
        --  XTMPAG_VAR.vgCdRubAgrupDescDiasAfast > 0
        -- Indica que se o evento esta parametrizado, o servidor devera ser calculado
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        -- Armazena as rubricas que nao devem ser processadas pelos Eventos em
        -- decorrencia da existencia de lancamentos financeiros ou decisoes judiciais
        ------------------------------------------------------------------------------

        XTMPAG_VAR.vListaRubricas := XTMPAG_GERAL.FRubricasLancamento(pCdVinculo => rVinculo.CdVinculo,
                                                                      pFolha     => XTMPAG_VAR.vgFolha);

        XTMPAG_VAR.vgLancComplementar := XTMPAG_GERAL.FRubricasLancComplementar(pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                                                                pFolha     => XTMPAG_VAR.vgFolha);

        XTMPAG_GERAL.PLogProcIni('4-3-4-3.Per Aquis/Dados Banc');

        ------------------------------------------------------------------------------
        -- Conquista/Regera periodos aquisitivos de tempo de servico
        ------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal THEN

          BEGIN
NULL;
--            XTMPAG_PC.PGeraPerAquisTempServ(pVinculo         => rVinculo,
--                                            pCdOrgao         => XTMPAG_VAR.vgFolha.CdOrgao,
--                                            pDtInicioMes     => XTMPAG_VAR.vgFolha.DtInicioMes,
--                                            pDtFimMes        => XTMPAG_VAR.vgFolha.DtFimMes,
--                                            pTpOrigemChamada => 1,
--                                            pFlFazRollback   => 'S',
--                                            pCdRetorno       => vCdRetorno);

          EXCEPTION
            WHEN OTHERS THEN

              XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                      pCalculo.CdHistoricoParamCalculo,
                                      rVinculo.CdPessoa,
                                      '** Alerta: PProcessarCalculoNormal: Erro no Pacote PC chamada PGeraPerAquisTempServ: ' ||
                                      SQLERRM,
                                      rVinculo.CdVinculo);
              RAISE;

          END;

        END IF;

        ------------------------------------------------------------------------------
        -- Conquista periodos aquisitivos de ferias
        ------------------------------------------------------------------------------

        IF (XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal OR
            XTMPAG_VAR.VGFOLHA.CDTIPOFOLHA = XTMPAG_TIPO.CNTPFOLHACTISP OR
            XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaFerias)
            AND NVL(XTMPAG_VAR.vMotAfast.InTipoAfastamento,'') <> 'D'  THEN
NULL;
--            XTMPAG_PC.PGeraPerAquisFerias(pVinculo       => rVinculo,
--                                          pCdAgrupamento => XTMPAG_VAR.vgFolha.CdAgrupamento,
--                                          pCdOrgao       => XTMPAG_VAR.vgFolha.CdOrgao,
--                                          pDtInicioMes   => XTMPAG_VAR.vgFolha.DtInicioMes,
--                                          pDtFimMes      => XTMPAG_VAR.vgFolha.DtFimMes);


        END IF;

        ----------------------------------------------------------------------
        -- Verificacoes para bolsistas e residentes
        ----------------------------------------------------------------------

        --RETIRAR DO PROCESSAMENTO DE FOLHA AS FOLHAS DE PESQUISADORES NAO REMUNERADOS
        IF XTMPAG_VAR.vgFolha.CdAgrupamento = 1 AND
           XTMPAG_VAR.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolhaPesquisador,XTMPAG_TIPO.cnTpFolhaConvenio) AND
           FPesquisaBolsaNaoRemunerada(XTMPAG_VAR.vgCdVinculo,
                                       XTMPAG_VAR.vDtCalculo,
                                       XTMPAG_VAR.vgFolha.DtInicioMes) THEN

          GOTO FIM_LOOP;

        END IF;

        IF XTMPAG_VAR.vgFolha.CdTipoFolha IN
           (XTMPAG_TIPO.cnTpFolhaBolsista,
            XTMPAG_TIPO.cnTpFolhaResidente,
            XTMPAG_TIPO.cnTpFolhaPesquisador,
            XTMPAG_TIPO.cnTpFolhaConvenio,
            XTMPAG_TIPO.cnTpFolhaRescisaoEstagiario,
            XTMPAG_tipo.cnTpFolhaRescisaoPesquisador) AND
           XTMPAG_VAR.vgBOL.COUNT > 0 THEN

          IF XTMPAG_VAR.vFlPossuiContaBancoOficial = 'N' THEN

            XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                    pCalculo.CdHistoricoParamCalculo,
                                    XTMPAG_VAR.vCdPessoa,
                                    'O vinculo nao possui conta bancaria no banco oficial.',
                                    XTMPAG_VAR.vgCdVinculo,
                                    2,
                                    8);

          END IF;

          IF rVinculo.DtDesligamento >= XTMPAG_VAR.vgFolha.DtInicioMes AND
             NOT FLocalTrabalhoVigente(rVinculo.CdVinculo,
                                       XTMPAG_VAR.vgFolha.DtInicioMes,
                                       XTMPAG_VAR.vgFolha.DtFimMes) THEN

            XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                    pCalculo.CdHistoricoParamCalculo,
                                    XTMPAG_VAR.vCdPessoa,
                                    'O nao foram encontrados locais de trabalho ativos para este vinculo',
                                    XTMPAG_VAR.vgCdVinculo);

          END IF;

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-3.Per Aquis/Dados Banc',
                              '4-3-4-4.Faltas');

        XTMPAG_VAR.bVinculoComCEF := (XTMPAG_VAR.vgCEF.COUNT > 0);

        ------------------------------------------------------------------------------
        -- Calcula o numero de faltas com base no periodo de apuracao da frequencia
        ------------------------------------------------------------------------------

        PKGMOVFRE.PCalcularFaltas(pCdVinculo     => rVinculo.CdVinculo,
                                  pDtIniApuracao => CASE
                                                     XTMPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       NULL
                                                      ELSE
                                                       XTMPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao
                                                    END,

                                  pDtFimApuracao => CASE
                                                     XTMPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       NULL
                                                      ELSE
                                                       XTMPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao
                                                    END,
                                  pDtIniInclusao => CASE
                                                     XTMPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       XTMPAG_VAR.vDtCalculoAnt + 1
                                                      ELSE
                                                       NULL
                                                    END,
                                  pDtFimInclusao => CASE
                                                     XTMPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       XTMPAG_VAR.vDtCalculo
                                                      ELSE
                                                       NULL
                                                    END,
                                  pDtIniLimite   => CASE
                                                     XTMPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       ADD_MONTHS(XTMPAG_VAR.vgFolha.DtInicioMes,
                                                                  -1 *
                                                                  PKGMOVFRE.cn_Qt_Mes_Retro_Falta)
                                                      ELSE
                                                       NULL
                                                    END,

                                  pFlSomenteJornada    => 'S',
                                  pFlSomenteEnturmacao => 'S',
                                  pDtInicioMes => XTMPAG_VAR.vgFolha.DtInicioMes);


        XTMPAG_VAR.vgFaltas := PKGMOVFRE.FVetorFaltas;

        XTMPAG_VAR.vgIndiceFaltasMesAtual    := trunc(PKGMOVFRE.FIndiceFaltaMesAtual(pVetorFaltas => XTMPAG_VAR.vgFaltas),
                                                      2);
        XTMPAG_VAR.vgIndiceFaltasMesAnterior := trunc(PKGMOVFRE.FIndiceFaltaMesAnterior(pVetorFaltas => XTMPAG_VAR.vgFaltas),
                                                      2);

        XTMPAG_VAR.vgIndiceFaltasSomenteDiasUteis := trunc(PKGMOVFRE.FIndiceFaltaSomenteDiasUteis(pVetorFaltas => XTMPAG_VAR.vgFaltas),
                                                           2);

        XTMPAG_VAR.vgIndiceAbonoRetro := trunc(PKGMOVFRE.FIndiceAbonoRetro(pVetorFaltas => XTMPAG_VAR.vgFaltas),
                                               2);

        XTMPAG_VAR.vgIndiceAbonoRetroDiasUteis := trunc(PKGMOVFRE.FIndiceAbonoRetroDiasUteis(pVetorFaltas => XTMPAG_VAR.vgFaltas),
                                                        2);

        XTMPAG_GERAL.PLogProcFim('4-3-4-4.Faltas');

        XTMPAG_var.bGerouDescontoIRESA := FALSE;

        XTMPAG_var.vgVlDescontoIRESA := 0;

        XTMPAG_var.vgCdRubDescontoIRESA := NULL;

        IF XTMPAG_VAR.vgFolha.CdTipoCalculo <> XTMPAG_TIPO.cnTpCalculoRecalcCompl THEN

          XTMPAG_GERAL.PLogProcIni('4-3-4-5.Proc Eventos');

          ------------------------------------------------------------------------------
          -- Inicio da execucao dos eventos da folha
          ------------------------------------------------------------------------------
          ------------------------------------------------------------------------------
          -- SIG-1277
          -- CRIAR ROTINA AUTOMATICA PARA DESCONTO DE FALTAS RETRAOTIVAS NAO DESCONTADAS
          ------------------------------------------------------------------------------
          pFaltasNaoDescontadas(rVinculo.CdVinculo);

          XTMPAG_EVENTO.PProcessaEventos(rVinculo,
                                         rVinculo.CdPessoa,
                                         XTMPAG_VAR.vgFolha,
                                         XTMPAG_VAR.vgEvento,
                                         XTMPAG_VAR.vgRubrica,
                                         XTMPAG_VAR.vgFormExpr,
                                         XTMPAG_VAR.vgParamPagamento,
                                         XTMPAG_VAR.vgCEF,
                                         XTMPAG_VAR.vgCCO,
                                         XTMPAG_VAR.vgCCOSubst,
                                         XTMPAG_VAR.vgFUC,
                                         XTMPAG_VAR.vgFUCSubst,
                                         XTMPAG_VAR.vgAPO,
                                         XTMPAG_VAR.vgAPOSemParidade,
                                         XTMPAG_VAR.vgBOL,
                                         XTMPAG_VAR.vgPensaoNaoPrev,
                                         XTMPAG_VAR.vgPensaoPrev,
                                         XTMPAG_VAR.vdtCalculo,
                                         pFlCalculoDefinitivo,
                                         pFlPagaAdiantamento);

          ---------------------------------------------------------------------------------
          -- Verifica se o vinculo possui pagamentos em outra folha calculada em definitivo
          ---------------------------------------------------------------------------------

          XTMPAG_GERAL.PLogProc('4-3-4-5.Proc Eventos',
                                '4-3-4-6.Exc Eventos');

          XTMPAG_GERAL.PLogProcIni('4-3-4-6-1.FPossuiEventos');

          XTMPAG_VAR.bFlPossuiProventos := XTMPAG_POS.FPossuiProventos(pFolha     => XTMPAG_VAR.vgFolha,
                                                                       pCdVinculo => rVinculo.CdVinculo);

          XTMPAG_GERAL.PLogProcFim('4-3-4-6-1.FPossuiEventos');

          IF XTMPAG_VAR.bFlPossuiProventos THEN

            vSgOrgao := NULL;

            XTMPAG_GERAL.PLogProcIni('4-3-4-6-2.FVinculoComFolhaCalculada');

            vSgOrgao := FVinculoComFolhaCalculada(pCdVinculo        => rVinculo.CdVinculo,
                                                  pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pNuAnoReferencia  => XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                  pNuMesReferencia  => XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                  pCdTipoFolha      => XTMPAG_VAR.vgFolha.CdTipoFolha,
                                                  pCdTipoCalculo    => XTMPAG_VAR.vgFolha.CdTipoCalculo);

            -- Mantem pagamento nas condicoes abaixo
            if XTMPAG_var.bpossuidisposicao and
               XTMPAG_var.vpagasitdisposicao = 'PAG-ORIGEM-CALCULO-ORIGEM' then
               vSgOrgao := null;
            end if;

            IF vSgOrgao IS NOT NULL THEN

              XTMPAG_GERAL.PLogProcFim('4-3-4-6-2.FVinculoComFolhaCalculada');

              XTMPAG_GERAL.PLogProcIni('4-3-4-6-3.PExcluirPagVinc');

              XTMPAG_GERAL.PExcluirPagVinc(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                           rVinculo.CdVinculo);

              XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                      pCalculo.CdHistoricoParamCalculo,
                                      XTMPAG_VAR.vCdPessoa,
                                      'Vinculo possui pagamentos em folha da ' ||
                                      vSgOrgao,
                                      XTMPAG_VAR.vgCdVinculo,
                                      2,
                                      9);

              XTMPAG_GERAL.PLogProcFim('4-3-4-6-3.PExcluirPagVinc');

              GOTO FIM_LOOP;

            END IF;

          END IF;

          XTMPAG_GERAL.PLogProc('4-3-4-6.Exc Eventos',
                                '4-3-4-7.Produt/Vant Pec');

          -------------------------------------------------------------------------------------------------
          -- Processa base de Gratificacao de Produtividade 01-0467 para aplicacao de limite de valor
          -- no rateio
          -------------------------------------------------------------------------------------------------

          -- Parametrizar
          IF XTMPAG_VAR.vgFolha.CdAgrupamento = 1 THEN

            XTMPAG_POS.PBaseGratProd(pFolha            => XTMPAG_VAR.vgFolha,
                                     pCdVinculo        => rVinculo.CdVinculo,
                                     pRubrica          => XTMPAG_VAR.vgRubrica(10489),
                                     pCEF              => XTMPAG_VAR.vgCEF,
                                     pCCO              => XTMPAG_VAR.vgCCO,
                                     pCCOSubst         => XTMPAG_VAR.vgCCOSubst,
                                     pAPO              => XTMPAG_VAR.vgAPO,
                                     pCdTipoAtipratFaz => 22);

          END IF;

          ------------------------------------------------------------------------------
          -- Inicio de processamento das Vantagens Pecuniarias
          ------------------------------------------------------------------------------

          XTMPAG_VP.PProcessaVantagemPecuniaria(XTMPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo,
                                                XTMPAG_VAR.vgRubrica,
                                                XTMPAG_VAR.vgVantagem,
                                                XTMPAG_VAR.vgFormExpr,
                                                XTMPAG_VAR.vDtCalculo);

          ------------------------------------------------------------------------------
          -- Inicio de processamento das Incorporacoes
          ------------------------------------------------------------------------------
          -- Se afastado o mes todo sem remuneracao nao processar incorporacoes
          IF XTMPAG_VAR.vgFolha.CdAgrupamento = 1 THEN
            IF XTMPAG_VAR.vMotAfast.InAfastado <>
               XTMPAG_TIPO.cnAfastadoMesTodo THEN

              XTMPAG_IA.PProcessaIncorporacaoAtivo(XTMPAG_VAR.vgFolha,
                                                   rVinculo.CdVinculo,
                                                   XTMPAG_VAR.vgFormExpr,
                                                   XTMPAG_VAR.vDtCalculo);
            END IF;
          ELSE

            XTMPAG_IA.PProcessaIncorporacaoAtivo(XTMPAG_VAR.vgFolha,
                                                 rVinculo.CdVinculo,
                                                 XTMPAG_VAR.vgFormExpr,
                                                 XTMPAG_VAR.vDtCalculo);

          END IF;

          XTMPAG_GERAL.PLogProcFim('4-3-4-7.Produt/Vant Pec');

        END IF;

        XTMPAG_GERAL.PLogProcIni('4-3-4-7x.Dec Judicial');

        ----------------------------------------------------------------------------------
        -- Inicio do processamento dos lancamentos financeiros
        -- Obs: Se o pagamento e no destino e o orgao da folha que esta sendo calculada e
        --      igual ao do cargo efetivo, nao deve considerar os lancamentos financeiros
        -- Incluida a situacao 'NAO-DISPOSICAO' em 23/04/2013 para evitar que LF, RT
        ----------------------------------------------------------------------------------

        vTemDifMes := FALSE;

        IF XTMPAG_VAR.vPagaSitDisposicao NOT IN
           ('PAG-DEST-CALCULO-ORIGEM',
            'PAG-ORIGEM-CALCULO-DEST',
            'NAO-DISPOSICAO')
          OR (rVinculo.CdOrgao = 2
              and rVinculo.CdOrgao = XTMPAG_var.vgFolha.CdOrgao
              and XTMPAG_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766))
          THEN

          XTMPAG_LF.PLancamentosFinanceiros(XTMPAG_VAR.vgFolha,
                                            rVinculo.CdVinculo,
                                            XTMPAG_VAR.vgFolha.DtInicioMes,
                                            XTMPAG_VAR.vgFolha.DtFimMes,
                                            XTMPAG_VAR.vgFormExpr,
                                            pDtCalculo);

          ------------------------------------------------------------------------------
          -- Processa pagamento de Decisoes Judiciais
          ------------------------------------------------------------------------------
          if (not rVinculo.bPossuiObito AND
             (rVinculo.DtDesligamento IS NULL or
             rVinculo.DtDesligamento >= XTMPAG_VAR.vgFolha.DtInicioMes)) or
             (rVinculo.bPossuiObito and
             rVinculo.DtDesligamento >= XTMPAG_VAR.vgFolha.DtInicioMes) then

            XTMPAG_LF.PPagamentoDecisaoJudicial(XTMPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo);

          end if;
          ------------------------------------------------------------------------------
          -- Verifica se existe folha de Diferenca de Meses Anteriores para pagar nesta folha
          ------------------------------------------------------------------------------

          IF vgTabCdFolhaPagamentoDifMes.COUNT > 0
            AND NOT FPossuiFolhaDefAnterior(rVinculo.CdVinculo, rVinculo.DtInclusao) THEN

            vTemDifMes := FLancamentoDifMes(pFolha            => XTMPAG_VAR.vgFolha,
                                            pTabCdFolhaDifMes => vgTabCdFolhaPagamentoDifMes,
                                            prVinculo         => rVinculo);

          END IF;

        END IF;

        XTMPAG_GERAL.PLogProcFim('4-3-4-7x.Dec Judicial');

        ------------------------------------------------------------------------------
        -- Geracao das rubricas totalizadoras,
        -- Definicao da ordem de execucao das formulas e bases de calculo
        -- Processamento das formulas e bases de calculo
        ------------------------------------------------------------------------------

        bGerouTotalizadoras := XTMPAG_GERAL.FGeraRubricasTotalizadoras(XTMPAG_VAR.vgFolha,
                                                                       rVinculo.CdVinculo);

        IF bGerouTotalizadoras THEN

          XTMPAG_GERAL.PLogProcIni('4-3-4-8.Def Ordem Calc');

          -- Temporario ate retirar todas as dependencias de vigencias anteriores a 2012/07

          IF (XTMPAG_VAR.vgFolha.NuAnoReferencia <= 2011 OR
             (XTMPAG_VAR.vgFolha.NuAnoReferencia = 2012 AND
             XTMPAG_VAR.vgFolha.NuMesReferencia <= 6)) THEN

            PDefinirOrdemFCalculoPassado(XTMPAG_VAR.vgFolha,
                                         rVinculo.CdVinculo);

          ELSE

            PDefinirOrdemFCalculo(pCalculo,
                                  XTMPAG_VAR.vgFolha,
                                  rVinculo.CdVinculo);

          END IF;

          XTMPAG_GERAL.PLogProc('4-3-4-8.Def Ordem Calc',
                                '4-3-4-9.Proc Form Base');

          -- Primeiro processamento das Formulas e Bases

          XTMPAG_var.vgValorCalculoRubrica := vValorCalcRubrica;

          XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                           rVinculo.CdVinculo);

          --
          -- Salario família empresas
          --
          IF XTMPAG_VAR.vgFolha.cdorgao = 27

             THEN

             XTMPAG_FB.PProcessaFormulasBases(pFolha    => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 42948,
                                       pTpProcessamento => 1,
                                       pTpLocal         => 1);
          END IF;

          IF XTMPAG_VAR.vgFolha.cdorgao = 25 THEN

             XTMPAG_FB.PProcessaFormulasBases(pFolha    => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 47960,
                                       pTpProcessamento => 1,
                                       pTpLocal         => 1);
          END IF;


          IF NOT (XTMPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
                  XTMPAG_VAR.vgVinculo.DtDesligamento >=
                  XTMPAG_VAR.vgFolha.DtInicioMes) THEN

            IF XTMPAG_VAR.vgCdRubricaRecisao13 > 0 THEN

               XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo,
                                                XTMPAG_VAR.vgCdRubricaRecisao13,
                                                1,
                                                2);

               XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo,
                                                XTMPAG_VAR.vgCdRubBloqueioRescisao,
                                                1,
                                                2);
            END IF;

            IF XTMPAG_VAR.vgCdRubricaRecisao13CTISP > 0 THEN

              XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               XTMPAG_VAR.vgCdRubricaRecisao13CTISP,
                                               1,
                                               2);

              XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               XTMPAG_VAR.vgCdRubBloqueioRescisao,
                                               1,
                                               2);
            END IF;

            IF XTMPAG_VAR.vgCdRubricaRecisao13PENSAO > 0 THEN

              XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               XTMPAG_VAR.vgCdRubricaRecisao13PENSAO,
                                               1,
                                               2);

              XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               XTMPAG_VAR.vgCdRubBloqueioRescisao,
                                               1,
                                               2);
            END IF;
            XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                             rVinculo.CdVinculo,
                                             NULL,
                                             2,
                                             2);

          END IF;

          -- Não deve gerar 09-0916 - base de cálculo do IPREV quando for CPSM
          IF rVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevCPSM AND
            XTMPAG_fb.fmnepossuidecjudicial(rVinculo.CdVinculo,
                                             XTMPAG_geral.fretornarubrica(XTMPAG_var.vgfolha.CdAgrupamento,5,1934),
                                             XTMPAG_var.vgfolha.NuMesReferencia,
                                             XTMPAG_var.vgfolha.NuAnoReferencia) <> 1 THEN

            XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo        => rVinculo.CdVinculo,
                                              pCdRubrica        => nvl(XTMPAG_var.vgCdRubBaseIPESC,0),
                                              pnusufixo         => 1,
                                              pFlExcluiAmbos    => 'S');
          END IF;

          XTMPAG_FB.PProcessaFormulasBases(pFolha    => XTMPAG_VAR.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => 48384,
                                           pTpProcessamento => 1,
                                           pTpLocal         => 1);

          XTMPAG_GERAL.PLogProcFim('4-3-4-9.Proc Form Base');

        END IF;

        XTMPAG_GERAL.PLogProcIni('4-3-4-10.Consol Pag Vinc');

        ------------------------------------------------------------------------------
        -- Consolidacao dos pagamentos gerados nas relacoes de vinculo
        ------------------------------------------------------------------------------

        XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

        PConsolidaPagVinculo(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                             rVinculo.CdVinculo);


        XTMPAG_GERAL.PLogTrace('CAL - Consolida Pagamento',
                               NULL,
                               XTMPAG_VAR.vgTmInicio);

        XTMPAG_GERAL.PLogProc('4-3-4-10.Consol Pag Vinc',
                              '4-3-4-11.Expurga Rub');

        PAjustarContrachequeCCO(pCdVinculo            => rVinculo.CdVinculo,
                                pCdAgrupamento        => XTMPAG_var.vgfolha.cdagrupamento,
                                pCdOrgao              => XTMPAG_var.vgfolha.cdorgao,
                                pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                pCdTipoFolhaPagamento => XTMPAG_var.vgFolha.CdTipoFolhaPagamento,
                                pDataInicioMes        => XTMPAG_var.vgfolha.dtiniciomes,
                                pDataFimMes           => XTMPAG_var.vgfolha.dtfimmes,
                                pDataCalculo          => XTMPAG_var.vgfolha.dtcalculo);

        IF XTMPAG_VAR.vgFolha.cdAgrupamento=176
          AND XTMPAG_var.vgPercentATS.count > 0
          THEN

          FOR i IN XTMPAG_var.vgPercentATS.first .. XTMPAG_var.vgPercentATS.last
            LOOP
              --SIG-137 salva o valor inteiro do índice do triênio (não proporcionalizado)
              UPDATE epaghistoricorubricavinculo hrv
                   SET hrv.vlindicerubrica = XTMPAG_var.vgPercentATS(i).vlIndiceATS
                 WHERE hrv.cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                   AND hrv.cdvinculo = rVinculo.CdVinculo
                   AND hrv.cdrubricaagrupamento = XTMPAG_var.vgPercentATS(i).cdrubricaagrupamento
                   AND hrv.nusufixorubrica = i; --37891
          END LOOP;
        END IF;

        IF XTMPAG_VAR.vgCdRubricaRecisao13 > 0 THEN

           -- valor da 09-0920 lançado em financeiro se sobrepõe ao valor calculado
           if XTMPAG_geral.fpossuilancfinanceiro(rVinculo.CdVinculo,
                                          XTMPAG_VAR.vgFolha,
                                          XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,920)) then

                  begin

                      delete epaghistoricorubricavinculo hrv
                       where cdvinculo = rVinculo.CdVinculo
                         and cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                         and cdrubricaagrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,920)
                         and hrv.cdtipoorigemrubrica <> 2;

                      delete epaghistoricorubricarelvinc hrr
                       where cdvinculo = rVinculo.CdVinculo
                         and cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                         and cdrubricaagrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,920)
                         and hrr.cdtipoorigemrubrica <> 2;

                      vvlBaseIprev13SalResc.vlProporcional := XTMPAG_geral.fretornavalorrubrica(
                                                                           XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                           rVinculo.CdVinculo,
                                                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,920));

                      vvlBaseIprev13SalResc.vlIntegral := vvlBaseIprev13SalResc.vlProporcional;
                      vvlBaseIprev13SalResc.vlReal     := vvlBaseIprev13SalResc.vlProporcional;



                       exception
                         when others then
                           null;
                       end;

           else

               vvlBaseIprev13SalResc := XTMPAG_FB.FRetornaValorBaseCalculo(pfolha => XTMPAG_VAR.vgFolha,
                                            pcdvinculo => rVinculo.CdVinculo,
                                            pcdtipohistorico => 2,
                                            pcdrelacaovinculo => 0,
                                            pcdbasecalculo => XTMPAG_var.vgrubrica(XTMPAG_var.vgCdRubBaseIPESC13).cdbasecalculo,
                                            pcdchave => rVinculo.CdVinculo);
           end if;

           IF NVL(vvlBaseIprev13SalResc.vlProporcional,0) > 0 THEN

                UPDATE epaghistoricorubricarelvinc hh
                   SET hh.vlintegral = vvlBaseIprev13SalResc.vlIntegral,
                       hh.vlreal     = vvlBaseIprev13SalResc.vlReal,
                       hh.vlproporcional = vvlBaseIprev13SalResc.vlProporcional,
                       hh.vlindicerubrica = vvlBaseIprev13SalResc.vlIndice
                 WHERE hh.cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                   AND hh.cdvinculo = rVinculo.CdVinculo
                   AND hh.cdrubricaagrupamento = XTMPAG_var.vgCdRubBaseIPESC13;

                vvlBaseIprev13SalResc.vlIndice := NULL;

                BEGIN

                SELECT 1
                  INTO vvlBaseIprev13SalResc.vlIndice
                  FROM epaghistoricorubricavinculo hrv
                 WHERE hrv.cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                   AND hrv.cdvinculo = rVinculo.CdVinculo
                   AND hrv.cdrubricaagrupamento = XTMPAG_var.vgCdRubBaseIPESC13;

                 EXCEPTION
                   WHEN no_data_found
                     THEN
                       XTMPAG_geral.pinserelancamentovinculo (pcdfolhapagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                     pcdvinculo => rVinculo.CdVinculo,
                                                           pcdexpressaoformcalc => NULL,
                                                          pcdrubricaagrupamento => XTMPAG_var.vgCdRubBaseIPESC13,
                                                               pnusufixorubrica => 1,
                                                                   pvlpagamento => vvlBaseIprev13SalResc.vlProporcional);
                 END;

           END IF;
        END IF;
        ------------------------------------------------------------------------------
        -- Expurga rubricas conforme parametrizacao
        ------------------------------------------------------------------------------

        XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

        PExpurgarRubricas(XTMPAG_VAR.vgFolha, rVinculo);

        XTMPAG_GERAL.PLogTrace('CAL - Expurga Rubricas',
                               NULL,
                               XTMPAG_VAR.vgTmInicio);

        XTMPAG_GERAL.PLogProc('4-3-4-11.Expurga Rub',
                              '4-3-4-12.Proc Excludente');

        ------------------------------------------------------------------------------
        -- Rubricas Excludentes
        ------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
           XTMPAG_VAR.vgVinculo.DtDesligamento >=
           XTMPAG_VAR.vgFolha.DtInicioMes THEN

          PProcessaRubricaExcludente(XTMPAG_VAR.vgFolha,
                                     rVinculo.CdVinculo);

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-12.Proc Excludente',
                              '4-3-4-13.Proc Dec. Terc.');

        /*21461/2024 - Tiago Von - Rotina responsável por realizar o controle de saldo/parcelas das Dec. Judiciais de PENHORA*/
        XTMPAG_LF.PRegistraPgtPenhora(pFolha => XTMPAG_var.vgFolha,
                                      pCdVinculo => rVinculo.CdVinculo );  


        -------------------------------------------------------------------------------
        -- Caso a variavel seja maior do que zero, significa que houve uma
        -- folha de 13 calculada em definitivo no mes anterior
        -- Devera gerar as diferencas entre as folhas
        -------------------------------------------------------------------------------

    /*    IF (XTMPAG_VAR.vgCdFolha13Ant > 0 AND XTMPAG_VAR.vgCdFolha13 > 0)
          AND XTMPAG_var.vgFolha.CdTipoFolhaPagamento NOT IN (1505,1525,1526) -- Folhas PRODEX PGE NAO GERA
          AND XTMPAG_VAR.vgVinculo.DtDesligamento < XTMPAG_var.vgFolha.dtCalculo
          AND XTMPAG_VAR.vgVinculo.DtDesligamento >= XTMPAG_var.vgFolha.DtInicioMes
          THEN

          IF XTMPAG_GERAL.FGeraRubrica(XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                    2,
                                                                    23)) THEN

            XTMPAG_DT.PReprocessa13Salario(pCdVinculo        => rVinculo.CdVinculo,
                                           pCdAgrupamento    => XTMPAG_VAR.vgFolha.CdAgrupamento,
                                           pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                           pCdFolha13Ant     => XTMPAG_VAR.vgCdFolha13Ant,
                                           pCdFolha13        => XTMPAG_VAR.vgCdFolha13);

          END IF;

        END IF;*/

        ---------------------------------------------------------------------------------
        -- Solicitamos que valores menores que 1,00 sejam desprezados, para as rubricas
        -- indicadas
        ---------------------------------------------------------------------------------
        --
        -- Rubrica 10924 nao mais excluir.
        -- Solicitacao: 7946/2015] - FOLHA - NA DO 13 RSTITUICAO DE IRRF  #64364
        --
        DELETE FROM EpagHistoricoRubricaVinculo
         WHERE CdVinculo = rVinculo.CdVinculo
           AND CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
           AND CdRubricaAgrupamento in (23157, 38536, 10342) --, 10924)
           AND VlPagamento < 1;

        

        XTMPAG_GERAL.PLogProc('4-3-4-13.Proc Dec. Terc.',
                              '4-3-4-13.Proc Ferias');

        -------------------------------------------------------------------------------
        -- Insere e calcula a base de Ferias
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vPagaSitDisposicao NOT IN
           ('PAG-DEST-CALCULO-ORIGEM',
            'PAG-ORIGEM-CALCULO-DEST',
            'NAO-DISPOSICAO') THEN

          IF XTMPAG_VAR.vgCdRubricaBaseFerias > 0 THEN

            XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseFerias,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

            XTMPAG_FB.PProcessaFormulasBases(XTMPAG_VAR.vgFolha,
                                             rVinculo.CdVinculo,
                                             XTMPAG_VAR.vgCdRubricaBaseFerias,
                                             2,
                                             2);

          END IF;

        END IF;

        -------------------------------------------------------------------------------
        -- 1/3 de Ferias
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubUmTercoFerias IS NOT NULL
           AND NOT XTMPAG_LF.FPossuiLancamentoFinanceiro(XTMPAG_VAR.vgCdRubUmTercoFerias) THEN

          XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

          XTMPAG_POS.PUmTercoFerias(XTMPAG_VAR.vgCdVinculo,
                                    XTMPAG_VAR.vgFolha,
                                    XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubUmTercoFerias),
                                    XTMPAG_VAR.vgFormExpr);

          XTMPAG_GERAL.PLogTrace('CAL - 1/3 Ferias',
                                 null,
                                 XTMPAG_VAR.vgTmInicio);

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-13.Proc Ferias',
                              '4-3-4-14.Proc Abono');

        -------------------------------------------------------------------------------
        -- Rescisao de 1/3 de Ferias ACT
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdEventoRescisaoACT > 0
          AND XTMPAG_var.vgFolha.CdAgrupamento <> 134 AND
           (
             (
                XTMPAG_VAR.vgVinculo.DtDesligamento BETWEEN
                XTMPAG_VAR.vgFolha.DtInicioMes AND XTMPAG_VAR.vgFolha.DtFimMes
             )
             OR
             (
               XTMPAG_VAR.vgVinculo.DtDesligamento < XTMPAG_VAR.vgFolha.DtInicioMes AND
               TRUNC(XTMPAG_VAR.vMotAfast.DtInclusao) BETWEEN
               (XTMPAG_VAR.vDtCalculoAnt + 1) AND (pDtCalculo)
             )
             OR
             (XTMPAG_VAR.vMotAfast.InAfastado = XTMPAG_TIPO.cnAfastadoNao)

            ) THEN

          XTMPAG_POS.P069RescisaoFeriasACT(pFolha     => XTMPAG_VAR.vgFolha,
                                           pEvento    => XTMPAG_VAR.vgEvento(XTMPAG_VAR.vgCdEventoRescisaoACT),
                                           pTemDifMes => vTemDifMes,
                                           prubrica   => XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgEvento(XTMPAG_VAR.vgCdEventoRescisaoACT)
                                                                              .cdrubricaagrupamento));
        ELSIF XTMPAG_var.vgFolha.CdAgrupamento = 134
          AND (NVL(XTMPAG_var.vgNuDiasFeriasNaoPagas,0) + NVL(XTMPAG_var.vgNuDiasFeriasPrevistos,0)) > 0
          THEN

          XTMPAG_POS.P069RescisaoFeriasCTISP(pFolha     => XTMPAG_VAR.vgFolha,
                                             pEvento    => XTMPAG_VAR.vgEvento(XTMPAG_VAR.vgCdEventoRescisaoACT),
                                             pTemDifMes => vTemDifMes,
                                             prubrica   => XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgEvento(XTMPAG_VAR.vgCdEventoRescisaoACT).cdrubricaagrupamento));

        else
          null;
        END IF;

        -------------------------------------------------------------------------------
        -- Ferias indenizadas
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubFeriasIndenizadas IS NOT NULL THEN

          XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

          XTMPAG_POS.P073074FeriasIndenizadas(XTMPAG_VAR.vgCdRubFeriasIndenizadas);

          XTMPAG_GERAL.PLogTrace('CAL - Ferias indenizadas',
                                 null,
                                 XTMPAG_VAR.vgTmInicio);

        END IF;

        -------------------------------------------------------------------------------
        -- 1/3 de Ferias indenizadas
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubFeriasIndenUmTerco IS NOT NULL THEN

          XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

          XTMPAG_POS.P073074FeriasIndenizadas(XTMPAG_VAR.vgCdRubFeriasIndenUmTerco);

          XTMPAG_GERAL.PLogTrace('CAL - Ferias indenizadas',
                                 null,
                                 XTMPAG_VAR.vgTmInicio);

        END IF;

        -------------------------------------------------------------------------------
        -- Ferias indenizadas ACT SJC
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubFeriasIndenizadasACTSJC IS NOT NULL AND
           ((XTMPAG_VAR.vgVinculo.DtDesligamento BETWEEN
             XTMPAG_VAR.vgFolha.DtInicioMes AND XTMPAG_VAR.vgFolha.DtFimMes) or
             (XTMPAG_VAR.vMotAfast.InTipoAfastamento = 'D'
              and trunc(XTMPAG_VAR.vMotAfast.DtInclusao) > trunc(XTMPAG_var.vgFolha.DtCalculoAnt)
              and to_char(XTMPAG_VAR.vgVinculo.DtDesligamento,'yyyymm') = to_char(XTMPAG_var.vgFolha.DtCalculoAnt,'yyyymm')))

          THEN

          XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

          if XTMPAG_VAR.vMotAfast.InTipoAfastamento = 'D'
              and trunc(XTMPAG_VAR.vMotAfast.DtInclusao) > trunc(XTMPAG_var.vgFolha.DtCalculoAnt)
              and to_char(XTMPAG_VAR.vgVinculo.DtDesligamento,'yyyymm') = to_char(XTMPAG_var.vgFolha.DtCalculoAnt,'yyyymm') then

              XTMPAG_POS.P010392FeriasIndenizadasACTSJC(XTMPAG_VAR.vgCdRubFeriasIndenizadasACTSJC,XTMPAG_var.vgFolha.CdFolhaPagamentoNormalAnt);

          else

              XTMPAG_POS.P010392FeriasIndenizadasACTSJC(XTMPAG_VAR.vgCdRubFeriasIndenizadasACTSJC);

          end if;

          XTMPAG_GERAL.PLogTrace('CAL - Ferias indenizadas ACT SJC',
                                 null,
                                 XTMPAG_VAR.vgTmInicio);

        END IF;

        IF XTMPAG_VAR.vgCdRubFeriasIndenizadasVinc is not null
          THEN

               XTMPAG_pos.P011156FeriasIndenizadasVinc(XTMPAG_VAR.vgCdRubFeriasIndenizadasVinc);

         END IF;

        -------------------------------------------------------------------------------
        -- Abono pecuniario
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubAbonoPecuniario IS NOT NULL THEN

          XTMPAG_POS.PAbonoPecuniario(XTMPAG_VAR.vgCdVinculo,
                                      XTMPAG_VAR.vgFolha,
                                      XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubAbonoPecuniario),
                                      XTMPAG_VAR.vgFormExpr);

        END IF;

        -------------------------------------------------------------------------------
        -- Diferenca de Abono pecuniario
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubDifAbonoPecuniario IS NOT NULL THEN

          XTMPAG_POS.PAbonoPecuniario(XTMPAG_VAR.vgCdVinculo,
                                      XTMPAG_VAR.vgFolha,
                                      XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubDifAbonoPecuniario),
                                      XTMPAG_VAR.vgFormExpr);

        END IF;

        IF XTMPAG_VAR.vgCdRubAbono13Ferias IS NOT NULL THEN

          XTMPAG_POS.PAbonoPecuniario(XTMPAG_VAR.vgCdVinculo,
                                      XTMPAG_VAR.vgFolha,
                                      XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubAbono13Ferias),
                                      XTMPAG_VAR.vgFormExpr);

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-14.Proc Abono',
                              '4-3-4-15.Proc Adiant. Ferias');

        -------------------------------------------------------------------------------
        -- Adiantamento de salario/ferias
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubAdiantSalFerias IS NOT NULL THEN

          XTMPAG_POS.PAdiantamentoSalarioFerias(XTMPAG_VAR.vgCdVinculo,
                                                XTMPAG_VAR.vgFolha,
                                                XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubAdiantSalFerias),
                                                XTMPAG_VAR.vgFormExpr);

        END IF;

        -------------------------------------------------------------------------------
        -- Pagamento Media de Horas Extras Cidasc/ INMETRO 01-0201
        -------------------------------------------------------------------------------

        IF XTMPAG_var.vgFolha.CdAgrupamento in (4, 276) -- Cidasc e INMETRO
          AND XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                pCdVinculo => XTMPAG_VAR.vgCdVinculo,
                                                pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,201)) > 0

           THEN

           IF NOT fPossuiPagamentoMediaFerias(XTMPAG_VAR.vgCdVinculo,
                                                       XTMPAG_VAR.vgFolha.dtInicioMes,
                                                       XTMPAG_VAR.vgFolha.cdOrgao,
                                                       XTMPAG_VAR.vgFolha.CdAgrupamento)
             THEN

             vVlRubrica010201 := 0;

             vCdExpressaoFormula := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr => XTMPAG_VAR.vgFormExpr,
                                                                           pCdRubricaAgrupamento     => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,201),
                                                                           pCdRelacaoVinculo         => XTMPAG_var.vgCEF(1).CdRelacaoVinculo);

             UPDATE EPagHistoricoRubricaVinculo HRV
                   SET HRV.CdExpressaoFormCalc = vCdExpressaoFormula
                 WHERE HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                   AND HRV.CdVinculo = XTMPAG_VAR.vgCdVinculo
                   AND HRV.CdRubricaAgrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,201);

             XTMPAG_FB.PProcessaFormulasBases(pFolha     => XTMPAG_VAR.vgFolha,
                                              pCdVinculo => XTMPAG_VAR.vgCdVinculo,
                                              pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,201),
                                              ptplocal   => 2,
                                              pTpProcessamento => 1);

             vVlRubrica010201 := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                                          pCdVinculo => XTMPAG_VAR.vgCdVinculo,
                                                                          pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,201));

             BEGIN

               UPDATE epaghistoricorubricarelvinc hrvv
                  SET hrvv.vlintegral     = vvlrubrica010201,
                      hrvv.vlproporcional = vvlrubrica010201,
                      hrvv.vlreal         = vvlrubrica010201
                WHERE hrvv.cdfolhapagamento =
                      XTMPAG_var.vgfolha.cdfolhapagamento
                  AND hrvv.cdvinculo = XTMPAG_var.vgcdvinculo
                  AND hrvv.cdrubricaagrupamento =
                      XTMPAG_geral.fretornarubrica(XTMPAG_var.vgfolha.cdagrupamento,
                                                   1,
                                                   201)
                  AND hrvv.cdrelacaovinculo = XTMPAG_var.vgcef(1)
                     .cdrelacaovinculo;

               DELETE epaghistoricorubricarelvinc hrvv
                WHERE hrvv.cdfolhapagamento =
                      XTMPAG_var.vgfolha.cdfolhapagamento
                  AND hrvv.cdvinculo = XTMPAG_var.vgcdvinculo
                  AND hrvv.cdrubricaagrupamento =
                      XTMPAG_geral.fretornarubrica(XTMPAG_var.vgfolha.cdagrupamento,
                                                   1,
                                                   201)
                  AND hrvv.cdrelacaovinculo <> XTMPAG_var.vgcef(1)
                     .cdrelacaovinculo;

             EXCEPTION
               WHEN OTHERS THEN
                 NULL;
             END;

             END IF;
        END IF;
        -------------------------------------------------------------------------------
        -- Pagamento de diferenca de Ferias (1/3)
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubDifUmTercoFerias IS NOT NULL THEN

          XTMPAG_POS.PDiferencaUmTercoFerias(XTMPAG_VAR.vgCdVinculo,
                                             XTMPAG_VAR.vgFolha,
                                             XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubDifUmTercoFerias),
                                             XTMPAG_VAR.vgFormExpr);

          IF XTMPAG_var.vgFolha.CdAgrupamento = 4 THEN-- Cidasc

              BEGIN

              UPDATE epaghistoricorubricarelvinc hrv
                  SET vlproporcional  = NULL
                WHERE HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdVinculo       = XTMPAG_VAR.vgCdVinculo
                    AND HRV.CdRubricaAgrupamento IN (48135,61915,61895,61896);

              XTMPAG_FB.PProcessaFormulasBases(pFolha     => XTMPAG_VAR.vgFolha,
                                         pCdVinculo       => XTMPAG_VAR.vgCdVinculo,
                                         pCdRubrica       => 48135,
                                         ptplocal         => 1,
                                         pTpProcessamento => 1);

              UPDATE epaghistoricorubricavinculo hrv
                  SET vlpagamento = (select sum(vlreal)
                                      from epaghistoricorubricarelvinc hrv1
                                       WHERE HRV1.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                                         AND HRV1.CdVinculo       = XTMPAG_VAR.vgCdVinculo
                                         AND HRV1.CdRubricaAgrupamento = 48135)
                WHERE HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdVinculo       = XTMPAG_VAR.vgCdVinculo
                  AND HRV.CdRubricaAgrupamento = 48135;

                    
               XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                                pCdVinculo       => XTMPAG_VAR.vgCdVinculo,
                                                pCdRubrica       => 61915,
                                                ptplocal         => 2,
                                                pTpProcessamento => 2);    
                                                
               XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                                pCdVinculo       => XTMPAG_VAR.vgCdVinculo,
                                                pCdRubrica       => 61895,
                                                ptplocal         => 2,
                                                pTpProcessamento => 2);  

               XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                                pCdVinculo       => XTMPAG_VAR.vgCdVinculo,
                                                pCdRubrica       => 61896,
                                                ptplocal         => 2,
                                                pTpProcessamento => 2);                                                                                                  

              EXCEPTION
                WHEN OTHERS
                  THEN
                    NULL;

              END;

          END IF;

        END IF;

        -------------------------------------------------------------------------------
        -- Pagamento de devolucao de Ferias (1/3)
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubDevUmTercoFerias IS NOT NULL and
          (XTMPAG_VAR.vgVinculo.DtDesligamento is null or
           (trunc(XTMPAG_VAR.vgVinculo.DtDesligamento) > trunc(XTMPAG_var.vgFolha.DtCalculo)) or
           (XTMPAG_VAR.vgVinculo.DtDesligamento is not null and trunc(XTMPAG_geral.FObterDtInclusaoAfaDefinitivo(XTMPAG_VAR.vgVinculo.cdVinculo)) > trunc(XTMPAG_var.vgFolha.DtCalculoAnt))) THEN

          XTMPAG_POS.PDevolucaoUmTercoFerias(XTMPAG_VAR.vgCdVinculo,
                                             XTMPAG_VAR.vgFolha,
                                             XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubDevUmTercoFerias),
                                             XTMPAG_VAR.vgFormExpr);

        END IF;
        
        ---------------------------------------------------------------------------------
        -- Geracao da devolucao de antecipacao de 13 e 13 salario quando
        -- a recisao ocorre antes do mes de processamento
        ---------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubricaDevAnt13 > 0 THEN

          XTMPAG_POS.PRescisaoMesAnterior(pFolha     => XTMPAG_VAR.vgFolha,
                                          pVinculo   => rVinculo,
                                          pDtCalculo => XTMPAG_VAR.vDtCalculo);

        END IF;

        IF XTMPAG_var.vgAPO.Count > 0 AND
           XTMPAG_geral.fpossuilancfinanceiro (pcdvinculo => XTMPAG_VAR.vgCdVinculo,
                                                   pfolha => XTMPAG_VAR.vgFolha,
                                               pcdrubrica => XTMPAG_GERAL.fretornarubrica(pcdagrupamento => XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                          pcdtiporubrica => 5,
                                                                                              pNuRubrica => 9985))

          THEN

           XTMPAG_pos.PBloqueioRemunApo(XTMPAG_VAR.vgAPO,
                                        XTMPAG_VAR.vgFolha,
                                        XTMPAG_GERAL.fretornarubrica(pcdagrupamento => XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                          pcdtiporubrica => 5,
                                                                                              pNuRubrica => 9985));
        END IF;

        if XTMPAG_VAR.vgFolha.cdorgao in (25,27) and 
           XTMPAG_var.vgRelVincPrincipal.CdRelTrabPagamento not in (2,15,18) and
           XTMPAG_VAR.vgFolha.cdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal and
           not XTMPAG_geral.fpossuilancfinanceiro (pcdvinculo => rVinculo.CdVinculo,
                                                   pfolha => XTMPAG_VAR.vgFolha,
                                                   pcdrubrica => XTMPAG_GERAL.fretornarubrica(pcdagrupamento => XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                              pcdtiporubrica => 9,
                                                                                              pNuRubrica => 582)) THEN

             XTMPAG_alimentacao.pDescontoDiasAuxAlimEmpresas(pCdVinculo => rVinculo.CdVinculo);

        end if;

        IF rVinculo.CdRegimePrevidenciario IN
           (XTMPAG_TIPO.cnRegPrevGeral, XTMPAG_TIPO.cnRegPrevNaoPossui) THEN

          --------------------------------------------------------------------------------------
          -- A base de baixa de ferias e reprocessada apos o calculo das ferias e antes
          -- da exclusao das rubricas que nao compoe a folha de ferias para obter o valor
          --------------------------------------------------------------------------------------

          IF XTMPAG_VAR.vgCdRubBaseBaixa IS NOT NULL THEN

            XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                             pCdVinculo       => rVinculo.CdVinculo,
                                             pCdRubrica       => XTMPAG_VAR.vgCdRubBaseBaixa,
                                             pTpProcessamento => 2,
                                             pTpLocal         => 2);

            vvlBaseBaixa := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                              pCdVinculo        => rVinculo.CdVinculo,
                                                              pCdRubrica        => XTMPAG_VAR.vgCdRubBaseBaixa);

          END IF;

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-15.Proc Adiant. Ferias',
                              '4-3-4-16.Exc Rubrica e Processa');

        ----------------------------------------------------------------------------------------------------
        -- Exclui as rubricas geradas  pois estas foram geradas para poder calcular rubricas de ferias e 13o
        ----------------------------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgFolha.CdTipoFolha NOT IN
           (--XTMPAG_TIPO.cnTpFolhaNormal,
            XTMPAG_TIPO.cnTpFolhaBolsista,
            XTMPAG_TIPO.cnTpFolhaResidente,
            XTMPAG_TIPO.cnTpFolhaPesquisador,
            XTMPAG_TIPO.cnTpFolhaConvenio,
            XTMPAG_TIPO.cnTpFolhaOutras,
            --XTMPAG_TIPO.cnTpFolhaBEP,
            XTMPAG_TIPO.cnTpFolhaServAfast,
            XTMPAG_TIPO.cnTpFolhaFunebre,
            XTMPAG_TIPO.cnTpFolhaRescisaoEstagiario,
            XTMPAG_tipo.cnTpFolhaRescisaoPesquisador) THEN

          IF XTMPAG_VAR.vgFolha.FlPagaTodasRubricas = 'N' THEN

            XTMPAG_GERAL.PExcluiRubricas(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                         rVinculo.CdVinculo,
                                         XTMPAG_VAR.vgFolha.InPagamentoRubrica);
                                         
            IF XTMPAG_VAR.vgFolha.CdTipoFolha <> XTMPAG_TIPO.cnTpFolhaNormal THEN                              

              XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                               pCdVinculo       => rVinculo.CdVinculo,
                                               pTpProcessamento => 2,
                                               pTpLocal         => 2);
                                             
            END IF;                                 

            IF XTMPAG_VAR.vgCdRubBaseBaixa > 0 AND vvlBaseBaixa > 0 THEN

              UPDATE EPagHistoricoRubricaVinculo HRV
                 SET HRV.vlPagamento = vvlBaseBaixa
               WHERE HRV.CdVinculo = rVinculo.CdVinculo
                 AND HRV.CdFolhaPagamento =
                     XTMPAG_VAR.vgFolha.CdFolhaPagamento
                 AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseBaixa;

              ----------------------------------------------------------------------
              -- Recalcula a modalidade 56 - FGTS de Ferias
              ----------------------------------------------------------------------

              IF XTMPAG_VAR.vgCdRubFeriasFGTS > 0 THEN

                XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                                 pCdVinculo       => rVinculo.CdVinculo,
                                                 pCdRubrica       => XTMPAG_VAR.vgCdRubFeriasFGTS,
                                                 pTpProcessamento => 2,
                                                 pTpLocal         => 2);

              END IF;

            END IF;

          END IF;

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-16.Exc Rubrica e Processa',
                              '4-3-4-17.Teto Governador');

        -------------------------------------------------------------------------------
        -- Teto do governador
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubDescTetoGovernador IS NOT NULL THEN

          XTMPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo        => rVinculo.CdVinculo);

          IF XTMPAG_GERAL.FGeraRubrica(XTMPAG_VAR.vgCdRubDescTetoGovernador) THEN

            XTMPAG_POS.PDescontoTetoGovernador(pFolha                => XTMPAG_VAR.vgFolha,
                                               pCdVinculo            => rVinculo.CdVinculo,
                                               pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubDescTetoGovernador);
          END IF;

          IF XTMPAG_VAR.vgVlTotalProventos > 0 THEN

            XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaTetoGov,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => XTMPAG_POS.RetornaValorRefBloqRemun(rVinculo.CdVinculo,
                                                                                                               XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                               XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                                               XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                                                               XTMPAG_VAR.vgFolha.NuMesReferencia),
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

          END IF;

        END IF;
        --
        -- SIG-6578 GEREF - Base 13
        -- Reprocessar base 13 apos a inclusao da rubrica de abatimento do teto
        if XTMPAG_VAR.vgCdRubBase13Sal > 0 and
           XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                 rVinculo.CdVinculo,
                                             XTMPAG_VAR.vgCdRubricaTetoGov) > 0 then

               XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                                    pCdVinculo            => rVinculo.CdVinculo,
                                            pCdRubrica       => XTMPAG_VAR.vgCdRubBase13Sal,
                                            pTpProcessamento => 2,
                                            pTpLocal         => 2);

         END IF;
        -------------------------------------------------------------------------------
        -- Teto do governador - 13 Salario
        -------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubDescTetoGovernador13 IS NOT NULL AND
           NOT XTMPAG_VAR.bReprocessou13Sal THEN

          IF XTMPAG_GERAL.FGeraRubrica(XTMPAG_VAR.vgCdRubDescTetoGovernador13) THEN

            XTMPAG_POS.PDescontoTetoGovernador13(pFolha                => XTMPAG_VAR.vgFolha,
                                                 pCdVinculo            => rVinculo.CdVinculo,
                                                 pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubDescTetoGovernador13);
          END IF;

        END IF;

        ---------------------------------------------------------------------------
        -- Reprocessa a formula da Contribuicao Sindical para descontar o teto.
        ---------------------------------------------------------------------------

        IF XTMPAG_VAR.vgListaContribSind.COUNT > 0 THEN

          i := XTMPAG_VAR.vgListaContribSind.FIRST;

          WHILE i <= XTMPAG_VAR.vgListaContribSind.LAST LOOP

            IF XTMPAG_VAR.vgListaContribSind.EXISTS(i) THEN

              IF XTMPAG_GERAL.FRetornaValorRubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                   rVinculo.CdVinculo,
                                                   XTMPAG_VAR.vgListaContribSind(i)) > 0 THEN

                vCdExpressaoFormula := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                              pCdRubricaAgrupamento => i,
                                                                              pCdRelacaoVinculo     => 0);

                UPDATE EPagHistoricoRubricaVinculo HRV
                   SET HRV.CdExpressaoFormCalc = vCdExpressaoFormula
                 WHERE HRV.CdFolhaPagamento =
                       XTMPAG_VAR.vgFolha.CdFolhaPagamento
                   AND HRV.CdVinculo = rVinculo.CdVinculo
                   AND HRV.CdRubricaAgrupamento = i;

                XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                                 pCdVinculo       => rVinculo.CdVinculo,
                                                 pCdRubrica       => i,
                                                 pTpProcessamento => 1,
                                                 pTpLocal         => 2);

                i := XTMPAG_VAR.vgListaContribSind.LAST + 1;

              END IF;

            END IF;

            i := XTMPAG_VAR.vgListaContribSind.NEXT(i);

          END LOOP;

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-17.Teto Governador',
                              '4-3-4-18.Retroativo');

        IF XTMPAG_VAR.vPagaSitDisposicao NOT IN
           ('PAG-DEST-CALCULO-ORIGEM',
            'PAG-ORIGEM-CALCULO-DEST',
            'NAO-DISPOSICAO') THEN

          ------------------------------------------------------------------------------
          -- Processa retroativos - Exercicios findos
          ------------------------------------------------------------------------------

          XTMPAG_RT.PRetroativos(XTMPAG_VAR.vgFolha,
                                 rVinculo.CdVinculo,
                                 pFlCalculoDefinitivo);
          --
          -- Trecho comentado e implementado na XTMPAG_rt o recalculo das rubricas
          -- REPROCESSA A RUBRICA 05-0260
          --
         /* begin

          vHistRubRelVinc.Vlreal := null;

          select *
            into vHistRubRelVinc
             from epaghistoricorubricarelvinc hrv
           where hrv.cdrubricaagrupamento = 56601
             and hrv.cdfolhapagamento = XTMPAG_var.vgFolha.Cdfolhapagamento
             and hrv.cdvinculo = rVinculo.CdVinculo
             and rownum < 2;

          exception
            when no_data_found
              then
                vHistRubRelVinc.Vlreal := null;

             when others
               then
                vHistRubRelVinc.Vlreal := null;
          end;

          if vHistRubRelVinc.Vlreal is not null
             then

             begin
               select hv.vlpagamento
                 into vvlCalculadoRubrica.vlReal
                 from epaghistoricorubricavinculo hv
                where hv.cdrubricaagrupamento = 56601
                  and hv.cdfolhapagamento = XTMPAG_var.vgFolha.Cdfolhapagamento
                  and hv.cdvinculo = rVinculo.CdVinculo;

             exception
               when no_data_found then
                 XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => vHistRubRelVinc.CdFolhaPagamento,
                                                  pCdVinculo                 => vHistRubRelVinc.CdVinculo,
                                                  pCdExpressaoFormCalc       => vHistRubRelVinc.Cdexpressaoformcalc,
                                                  pCdRubricaAgrupamento      => vHistRubRelVinc.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica           => vHistRubRelVinc.NuSufixoRubrica,
                                                  pVlPagamento               => 0,
                                                  pVlIndice                  => vHistRubRelVinc.Vlindicerubrica,
                                                  pCdLancamentoFinanceiro    => null,
                                                  pCdTipoOrigemRubrica       => vHistRubRelVinc.Cdtipoorigemrubrica,
                                                  pCdTipoIndice              => vHistRubRelVinc.Cdtipoindice );
             end;

             XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                              pCdVinculo       => rVinculo.CdVinculo,
                                              pCdRubrica       => 56601,
                                              pTpProcessamento => 1, --formula de calculo
                                              pTpLocal         => 2);

          end if;

          --REPROCESSA A RUBRICA 05-0370
          begin

          vHistRubRelVinc.Vlreal := null;

          select *
            into vHistRubRelVinc
             from epaghistoricorubricarelvinc hrv
           where hrv.cdrubricaagrupamento = 56658
             and hrv.cdfolhapagamento = XTMPAG_var.vgFolha.Cdfolhapagamento
             and hrv.cdvinculo = rVinculo.CdVinculo
             and rownum < 2;

          exception
            when no_data_found
              then
                vHistRubRelVinc.Vlreal := null;

            when others
               then
                vHistRubRelVinc.Vlreal := null;

          end;

          if vHistRubRelVinc.Vlreal is not null
             then

             begin
               select hv.vlpagamento
                 into vvlCalculadoRubrica.vlReal
                 from epaghistoricorubricavinculo hv
                where hv.cdrubricaagrupamento = 56658
                  and hv.cdfolhapagamento = XTMPAG_var.vgFolha.Cdfolhapagamento
                  and hv.cdvinculo = rVinculo.CdVinculo;

             exception
               when no_data_found then
                 XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => vHistRubRelVinc.CdFolhaPagamento,
                                                  pCdVinculo                 => vHistRubRelVinc.CdVinculo,
                                                  pCdExpressaoFormCalc       => vHistRubRelVinc.Cdexpressaoformcalc,
                                                  pCdRubricaAgrupamento      => vHistRubRelVinc.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica           => vHistRubRelVinc.NuSufixoRubrica,
                                                  pVlPagamento               => 0,
                                                  pVlIndice                  => vHistRubRelVinc.Vlindicerubrica,
                                                  pCdLancamentoFinanceiro    => null,
                                                  pCdTipoOrigemRubrica       => vHistRubRelVinc.Cdtipoorigemrubrica,
                                                  pCdTipoIndice              => vHistRubRelVinc.Cdtipoindice );
             end;
          XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => 56658,
                                           pTpProcessamento => 1, --formula de calculo
                                           pTpLocal         => 2);

          end if;

          --REPROCESSA A RUBRICA 05-0405
          begin

          vHistRubRelVinc.Vlreal := null;

          select *
            into vHistRubRelVinc
             from epaghistoricorubricarelvinc hrv
           where hrv.cdrubricaagrupamento = 56818
             and hrv.cdfolhapagamento = XTMPAG_var.vgFolha.Cdfolhapagamento
             and hrv.cdvinculo = rVinculo.CdVinculo
             and rownum < 2;

          exception
            when no_data_found
              then
                vHistRubRelVinc.Vlreal := null;

            when others
               then
                vHistRubRelVinc.Vlreal := null;

          end;

          if vHistRubRelVinc.Vlreal is not null
             then

             begin
               select hv.vlpagamento
                 into vvlCalculadoRubrica.vlReal
                 from epaghistoricorubricavinculo hv
                where hv.cdrubricaagrupamento = 56818
                  and hv.cdfolhapagamento = XTMPAG_var.vgFolha.Cdfolhapagamento
                  and hv.cdvinculo = rVinculo.CdVinculo;

             exception
               when no_data_found then
                 XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => vHistRubRelVinc.CdFolhaPagamento,
                                                  pCdVinculo                 => vHistRubRelVinc.CdVinculo,
                                                  pCdExpressaoFormCalc       => vHistRubRelVinc.Cdexpressaoformcalc,
                                                  pCdRubricaAgrupamento      => vHistRubRelVinc.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica           => vHistRubRelVinc.NuSufixoRubrica,
                                                  pVlPagamento               => 0,
                                                  pVlIndice                  => vHistRubRelVinc.Vlindicerubrica,
                                                  pCdLancamentoFinanceiro    => null,
                                                  pCdTipoOrigemRubrica       => vHistRubRelVinc.Cdtipoorigemrubrica,
                                                  pCdTipoIndice              => vHistRubRelVinc.Cdtipoindice );
             end;
             XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                              pCdVinculo       => rVinculo.CdVinculo,
                                              pCdRubrica       => 56818,
                                              pTpProcessamento => 1, --formula de calculo
                                              pTpLocal         => 2);

          end if; */


          PAjustarContrachequeCCO(pCdVinculo            => rVinculo.CdVinculo,
                                  pCdAgrupamento        => XTMPAG_var.vgfolha.cdagrupamento,
                                  pCdOrgao              => XTMPAG_var.vgfolha.cdorgao,
                                  pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                  pCdTipoFolhaPagamento => XTMPAG_var.vgFolha.CdTipoFolhaPagamento,
                                  pDataInicioMes        => XTMPAG_var.vgfolha.dtiniciomes,
                                  pDataFimMes           => XTMPAG_var.vgfolha.dtfimmes,
                                  pDataCalculo          => XTMPAG_var.vgfolha.dtcalculo);

          ------------------------------------------------------------------------------
          -- Caso o vinculo possua
          ------------------------------------------------------------------------------

          IF (NOT bGerouTotalizadoras) AND
             rVinculo.DtDesligamento < XTMPAG_VAR.vgFolha.DtInicioMes THEN

            bGerouTotalizadoras := XTMPAG_GERAL.FGeraRubricasTotalizadoras(XTMPAG_VAR.vgFolha,
                                                                           rVinculo.CdVinculo);

          END IF;

          ------------------------------------------------------------------------------
          -- Restituicao ao erario
          ------------------------------------------------------------------------------

          IF XTMPAG_var.bGerouDescontoIRESA
            AND XTMPAG_var.vgCdRubDescontoIRESA IS NOT NULL
            AND XTMPAG_var.vgVlDescontoIRESA > 0
            AND XTMPAG_var.vgFolha.CdOrgao <> 443

             THEN

                XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaErario,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 11);

                XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                                 pCdVinculo       => rVinculo.CdVinculo,
                                                 pCdRubrica       => XTMPAG_VAR.vgCdRubricaErario,
                                                 pTpProcessamento => 2,
                                                 pTpLocal         => 2);

               vVlMargemErario := XTMPAG_re.FRetornaValorMargem(XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                                 XTMPAG_var.vgFolha.CdTipoFolha,
                                                                 rVinculo.CdVinculo,
                                                                 XTMPAG_VAR.vgCdRubricaErario,
                                                                 0,
                                                                 'S');

                IF XTMPAG_var.vgvldescontoiresa > vVlMargemErario
                   THEN

                     UPDATE EPagHistoricoRubricaVinculo HRV
                        SET VlPagamento = vVlMargemErario
                      WHERE HRV.CdVinculo = rVinculo.CdVinculo
                        AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                        AND HRV.CdRubricaAgrupamento = XTMPAG_var.vgCdRubDescontoIRESA;

                     UPDATE EPagHistoricoRubricaRelVinc HRR
                        SET HRR.Vlproporcional = vVlMargemErario,
                            hrr.vlintegral = vVlMargemErario
                      WHERE HRR.CdVinculo = rVinculo.CdVinculo
                        AND HRR.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                        AND HRR.CdRubricaAgrupamento = XTMPAG_var.vgCdRubDescontoIRESA;

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
                           CdBaseConsignacao)
                      VALUES
                          (SPagHistoricoRubricaVinculo.NEXTVAL,
                           XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                           XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,1573),
                           rVinculo.CdVinculo ,
                           1,
                           null,
                           XTMPAG_var.vgvldescontoiresa - vVlMargemErario,
                           1,
                           100,
                           systimestamp,
                           null,
                           null,
                           4,
                           null);

                END IF;

                DELETE ePagHistoricoRubricaVinculo HRV
                 WHERE HRV.CDRUBRICAAGRUPAMENTO = XTMPAG_VAR.vgCdRubricaErario
                   AND HRV.CdVinculo = rVinculo.CdVinculo
                   AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento;

          END IF;

           XTMPAG_RE.PRestituicaoErario(XTMPAG_VAR.vgFolha,
                                       rVinculo.CdVinculo,
                                       pFlCalculoDefinitivo,
                                       'S');

        END IF;

        XTMPAG_GERAL.PLogProc('4-3-4-18.Retroativo',
                              '4-3-4-19.Vale e Diversos');

        ------------------------------------------------------------------------------
        -- Desconto de vale transporte
        ------------------------------------------------------------------------------

        IF XTMPAG_VAR.vgCdRubValeTransporte IS NOT NULL OR
           ((XTMPAG_VAR.vgAfastTempRemunMesAnt.Count > 0 or
             XTMPAG_VAR.vgIndiceFaltasMesAnterior > 0) AND
            XTMPAG_VAR.vgFolha.CdAgrupamento = 176 AND
            XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaBolsista) THEN

          XTMPAG_POS.PDescontoValeTransporte(rVinculo.CdVinculo,
                                             XTMPAG_VAR.vgFolha,
                                             XTMPAG_VAR.vgCdRubValeTransporte,
                                             pFlCalculoDefinitivo,
                                             XTMPAG_VAR.vDtCalculo);

        END IF;

        -----------------------------------------------------------------------------------
        -- Atualiza o valor da base contribuicao do plano de saude ( Modalidade 21)
        -- abatendo as rubricas do tipo 8 que fazem parte da expressao do calculo da base
        -----------------------------------------------------------------------------------

        /*if nvl(XTMPAG_VAR.vgIndiceFaltasMesAnterior,0) < 30 then
           -- Solicitacao de Sustentacao  #79983
           -- 12316/2018 - FALTAS PRIORIDADE SOBRE DESC SC SAUDE
           -- Somente descontar plano de saude se o total de faltas do mes anterior nao estiver zerando o contra cheque.
           -- na rotina de liquido negativo eh feito um ajuste especifico nesta rubrica de faltas e o calculo
           -- acabava compensando as diferencas, ou seja, permitia o desconto do scsaude e depois ajustava a diferenca no
           -- desconto de faltas.

            IF XTMPAG_VAR.vgCdRubricaBasePlanoSaude > 0 THEN

              XTMPAG_FB.PAtualizaBaseCalculo(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo        => rVinculo.CdVinculo,
                                             pCdRubrica        => XTMPAG_VAR.vgCdRubricaBasePlanoSaude);
            END IF;

            -------------------------------------------------------------------------------
            -- Desconto de plano de saude de titular
            -------------------------------------------------------------------------------

            IF XTMPAG_VAR.vgCdRubDescPlanSauTit IS NOT NULL THEN

              XTMPAG_POS.PDescontoPlanoSaudeTitular(pCdVinculo => rVinculo.CdVinculo,
                                                    pFolha     => XTMPAG_VAR.vgFolha,
                                                    pRubrica   => XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubDescPlanSauTit));

              XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo);

              if XTMPAG_VAR.vgVlTotalProventos < XTMPAG_VAR.vgVlTotalDescontos then

                 vVlRubrica := 0;

                 vVlRubrica := XTMPAG_GERAL.FRetornaValorRubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                 rVinculo.CdVinculo,
                                                                 XTMPAG_VAR.vgCdRubDescPlanSauTit) -
                                                                 (XTMPAG_VAR.vgVlTotalDescontos - XTMPAG_VAR.vgVlTotalProventos);

                 vVlCalculadoRubrica.vlIntegral := vVlRubrica;

                 pAtualizaValorRubrica(rVinculo.CdVinculo,  XTMPAG_VAR.vgFolha.CdFolhaPagamento, XTMPAG_VAR.vgCdRubDescPlanSauTit, vVlCalculadoRubrica);

                 XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo);

              end if;

            END IF;

            ---------------------------------------------------------------------------------
            -- Patronal de SC saude
            ---------------------------------------------------------------------------------

            IF XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                 pCdVinculo        => rVinculo.CdVinculo,
                                                 pCdRubrica        => XTMPAG_VAR.vgCdRubricaBasePSPatronal) = 0 THEN

              IF NVL(XTMPAG_VAR.vgCdRubricaBasePSPatronal, 0) > 0 THEN

                XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                      pCdVinculo            => rVinculo.CdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBasePSPatronal,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => 0,
                                                      pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 1);

              END IF;

            END IF;

            IF NVL(XTMPAG_VAR.vgCdRubricaBasePSPatronal, 0) > 0 THEN

              XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                               pCdVinculo       => rVinculo.CdVinculo,
                                               pCdRubrica       => XTMPAG_VAR.vgCdRubricaBasePSPatronal,
                                               pTpProcessamento => 2, -- Processa base de calculo
                                               pTpLocal         => 2); -- no vinculo
            END IF;

            --------------------------------------------------------------------------------
            -- Desconto de plano de saude de agregados
            --------------------------------------------------------------------------------

            IF XTMPAG_VAR.vgCdRubDescPlanSauAgr IS NOT NULL and
               XTMPAG_VAR.vgVlTotalProventos > XTMPAG_VAR.vgVlTotalDescontos

              THEN

              XTMPAG_POS.PDescontoPlanoSaudeAgreg(pCdVinculo => rVinculo.CdVinculo,
                                                  pFolha     => XTMPAG_VAR.vgFolha,
                                                  pRubrica   => XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgCdRubDescPlanSauAgr));

            END IF;

            --------------------------------------------------------------------------------
            -- Desconto de co-participacao
            --------------------------------------------------------------------------------

            IF XTMPAG_VAR.vgCdEventoDescCoPart IS NOT NULL and
               XTMPAG_VAR.vgVlTotalProventos > XTMPAG_VAR.vgVlTotalDescontos THEN

              XTMPAG_POS.PDescontoCoParticipacao(pCdVinculo           => rVinculo.CdVinculo,
                                                 pFolha               => XTMPAG_VAR.vgFolha,
                                                 pRubrica             => XTMPAG_VAR.vgRubrica(XTMPAG_VAR.vgEvento(XTMPAG_VAR.vgCdEventoDescCoPart)
                                                                                              .CdRubricaAgrupamento),
                                                 pEvento              => XTMPAG_VAR.vgEvento(XTMPAG_VAR.vgCdEventoDescCoPart),
                                                 pFlCalculoDefinitivo => pFlCalculoDefinitivo);
            END IF;

        end if;*/

        XTMPAG_GERAL.PLogProcFim('4-3-4-19.Vale e Diversos');

      ELSE

        GOTO FIM_LOOP;

      END IF;

    END IF;

    XTMPAG_GERAL.PLogProcFim('4-3-4.Rel Principal');

    if  (XTMPAG_VAR.vgVinculo.DtDesligamento <= XTMPAG_VAR.vgFolha.DtFimMes) then
    -- A partir de Dezembro 2023 somente gerar rubricas de 13 na folha normal para casos de rescisao
    -- DESCONTO 08-0023 E 08-0024 para quem tem as bases 09-9024 e 09-9023 no mes anterior
    --
        IF rvinculo.DtAdmissao < XTMPAG_VAR.vgFolha.DtInicioMes
          AND (XTMPAG_VAR.vgCdRubBase080023DescParcial IS NOT NULL
               OR XTMPAG_VAR.vgCdRubBase080024DescParcial IS NOT NULL)
          AND XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal
          AND XTMPAG_VAR.vgFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoNormal
        THEN
            XTMPAG_pos.PSaldoDevolucao13(pCdVinculo => rVinculo.CdVinculo, pFolha => XTMPAG_VAR.vgFolha);
        END IF;

        IF rvinculo.DtAdmissao < XTMPAG_VAR.vgFolha.DtInicioMes
          AND XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaCtisp
          AND XTMPAG_VAR.vgFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoNormal
        THEN
            XTMPAG_pos.PSaldoDevolucao13Ctisp(pCdVinculo => rVinculo.CdVinculo, pFolha => XTMPAG_VAR.vgFolha);
        END IF;

    end if;

    if XTMPAG_var.vgFolha.CdTipoFolhaPagamento NOT IN (1505,1525,1526) then
        XTMPAG_POS.PAjustarSaldoDevedor13(pCdVinculo => rVinculo.CdVinculo,
                                             pFolha => XTMPAG_VAR.vgFolha);
    end if;


    -------------------------------------------------------------------
    -- Processa tributacoes e pensoes alimenticias
    --------------------------------------------------------------------------

    vvlBaseIprev13SalResc := XTMPAG_geral.fretornavaloroutrasrv(pcdfolhapagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                      pcdvinculo => rVinculo.CdVinculo,
                                      pcdrubricaagrupamento => XTMPAG_geral.fretornarubrica(pcdagrupamento => XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                 pcdtiporubrica => 1,
                                                                                 pNuRubrica => 1023));

    IF NVL(vvlBaseIprev13SalResc.vlProporcional,0) = 0 THEN
      vvlBaseIprev13SalResc.vlProporcional := XTMPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                 pcdvinculo => RVINCULO.CdVinculo,
                                                                 pcdrubrica => XTMPAG_geral.fretornarubrica(pcdagrupamento => XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                            pcdtiporubrica => 1,
                                                                                                            pNuRubrica => 1023));
    END IF;
    -- Solicitacao de Sustentacao #77583
    -- Para a Defensoria Publica, Caso haja a rubrica 01-1023, esta assume a base do BASE-IPESC-13 09-0920
    IF NVL(vvlBaseIprev13SalResc.vlProporcional,0) > 0
      AND XTMPAG_var.vgCdRubBaseIPESC13 > 0
      AND NOT XTMPAG_geral.fpossuilancfinanceiro(rVinculo.CdVinculo,
                                                  XTMPAG_VAR.vgFolha,
                                                  XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,920))  THEN

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => XTMPAG_var.vgCdRubBaseIPESC13,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

    END IF;

    PAtualizaBaseSCSaude(rVinculo.CdVinculo);

    -- Nao processa para folha PDVI CIASC
    IF XTMPAG_VAR.vgFolha.CdTipoFolhaPagamento <> 765

       THEN
      -- 765 = FOLHA PDVI

      IF XTMPAG_VAR.vgFolha.cdTipoFolha = XTMPAG_TIPO.cnTpFolhaServAfast
        THEN

        PDifVlPagamentoVincSemRemun(pCdVinculo        => rVinculo.CdVinculo,
                                                  pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pNuAnoReferencia  => XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                  pNuMesReferencia  => XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                  pCdTipoFolha      => XTMPAG_VAR.vgFolha.CdTipoFolha,
                                                  pCdTipoCalculo    => XTMPAG_VAR.vgFolha.CdTipoCalculo);

      END IF;

      if XTMPAG_VAR.vgFolha.cdorgao = 25 -- Reprocessar base

         THEN

          XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => 49218,
                                           pTpProcessamento => 2, -- Processa base de calculo  Patronal Ceres
                                           pTpLocal         => 2);

          if nvl(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                        rVinculo.CdVinculo,
                                                        XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803)),0) > 0 then

              XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                               pCdVinculo       => rVinculo.CdVinculo,
                                               pCdRubrica       => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803),
                                               pTpProcessamento => 1, -- Processa base de c?lculo
                                               pTpLocal         => 2);


              delete epaghistoricorubricarelvinc rvc
               where rvc.cdvinculo = rVinculo.CdVinculo
                 and rvc.cdfolhapagamento =  XTMPAG_VAR.vgFolha.CdFolhaPagamento
                 and rvc.cdhistcargoefetivo is null
                 and rvc.cdrubricaagrupamento =   XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803);

              update epaghistoricorubricarelvinc rvc
                 set rvc.vlintegral = XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                        rVinculo.CdVinculo,
                                                                        XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                     rvc.vlreal = XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                        rVinculo.CdVinculo,
                                                                        XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                     rvc.vlproporcional = XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                        rVinculo.CdVinculo,
                                                                        XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803))
               where rvc.cdvinculo = rVinculo.CdVinculo
                 and rvc.cdfolhapagamento =  XTMPAG_VAR.vgFolha.CdFolhaPagamento
                 and rvc.cdhistcargoefetivo is not null
                 and rvc.cdrubricaagrupamento =   XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803);


          end if;

      end if;

      IF XTMPAG_var.vgFolha.cdtipofolha <> XTMPAG_TIPO.cnTpFolhaInstPensao THEN            

          -- Quando não observa limite de erário, processa o erário antes da tributação apenas
          -- das rubricas que estão na base do IR, para evitar líquido negativo
          XTMPAG_RE.PRestituicaoErario(XTMPAG_VAR.vgFolha,
                                       rVinculo.CdVinculo,
                                       pFlCalculoDefinitivo,
                                       'N',
                                       'S');
                                       
          XTMPAG_GERAL.PLogProcIni('4-4.Tributacao');

          XTMPAG_GERAL.PLogProcIni('4-4-1.Processa Trib e Pensao');

          XTMPAG_TRIBUTACAO.PProcessaTributacaoEPensao(pFolha          => XTMPAG_VAR.vgFolha,
                                                       pCdPessoa       => rVinculo.CdPessoa,
                                                       pCdVinculo      => rVinculo.CdVinculo,
                                                       pParamPagamento => XTMPAG_VAR.vgParamPagamento,
                                                       pDtInicioMes    => XTMPAG_VAR.vgFolha.DtInicioMes,
                                                       pDtFimMes       => XTMPAG_VAR.vgFolha.DtFimMes,
                                                       pbPrima         => TRUE);


          IF XTMPAG_VAR.vgFolha.CdFolhaPagamento = vcdfolha and rVinculo.CdVinculo = Vcdvinculo then
            
              XTMPAG_geral.pinserelancamentovinculo (pcdfolhapagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                     pcdvinculo            => rVinculo.CdVinculo,
                                                     pcdexpressaoformcalc  => NULL,
                                                     pcdrubricaagrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,2,23),
                                                     pnusufixorubrica      => 1,
                                                     pvlpagamento          => VValor020023);

              XTMPAG_geral.pinserelancamentovinculo (pcdfolhapagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                     pcdvinculo            => rVinculo.CdVinculo,
                                                     pcdexpressaoformcalc  => NULL,
                                                     pcdrubricaagrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,546),
                                                     pnusufixorubrica      => 5,
                                                     pvlpagamento          => Vvalor050246,
                                                     pvlindice             => 27.5000);


          END IF;


          XTMPAG_GERAL.PLogProc('4-4-1.Processa Trib e Pensao',
                                '4-4-2.Processa Base Consig');
                                
          -- Processa os descontos de adiantamento salarial
          XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                              rVinculo.CdVinculo);
                                              
          XTMPAG_LF.PDescontoAntecipSal(pFolha     => XTMPAG_VAR.vgFolha,
                                        pCdVinculo => rVinculo.CdVinculo);                      
                                
          -- Processa os erários das rubricas que não estão na base de IR
          XTMPAG_RE.PRestituicaoErario(XTMPAG_VAR.vgFolha,
                                       rVinculo.CdVinculo,
                                       pFlCalculoDefinitivo,
                                       'N',
                                       'N');
          -- Verificar processos para finalizar ou nao


          PProcessarVincCalcErario(rVinculo             => rVinculo,
                                   pFlCalculoDefinitivo => pFlCalculoDefinitivo);


          --
          -- Solicitacao de Sustentacao #80019
          -- COHAB - INSS de ferias ficticio
          --
          if XTMPAG_var.vgFolha.CdOrgao = 7 then

            if XTMPAG_var.vgFolha.CdTipoFolha <> XTMPAG_TIPO.cnTpFolhaFerias and
               XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_VAR.vgCdFolhaFerias,
                                                 pcdvinculo => rVinculo.CdVinculo,
                                                 pcdrubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,216)) > 0 and
                                                 XTMPAG_var.vgfolha.cdtipofolhapagamento <> 1686 ----folhaPDVI SIG 11660

              then


                 XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                       pCdVinculo            => rVinculo.CdVinculo,
                                                       pCdExpressaoFormCalc  => NULL,
                                                       pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,4,216), --09-1008
                                                       pNuSufixoRubrica      => 1,
                                                       pVlPagamento          => XTMPAG_geral.fretornavalorrubrica(
                                                                                      pcdfolhapagamento => XTMPAG_VAR.vgCdFolhaFerias,
                                                                                      pcdvinculo => rVinculo.CdVinculo,
                                                                                      pcdrubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,216)),
                                                       pVlIndice             => NULL,
                                                       pCdTipoOrigemRubrica  => 1);


            end if;

          end if;

       elsif XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevCPSM then

          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => rVinculo.CdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseCPSM,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

          XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => XTMPAG_VAR.vgCdRubBaseCPSM,
                                           pTpProcessamento => 2,
                                           pTpLocal         => 2);

          if XTMPAG_geral.fretornavalorrubrica(
             XTMPAG_var.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo,
             XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,38)) > 0 then

             begin

             XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                              pCdVinculo       => rVinculo.CdVinculo,
                                              pCdRubrica       => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,38),
                                              pTpProcessamento => 1,
                                              pTpLocal         => 1);

             exception
               when others
                 then
                   null;

             end;

          end if;

       END IF;

    END IF;

   if XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevCPSM and
      XTMPAG_geral.fretornavalorrubrica(XTMPAG_var.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo,
                                        XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,38)) > 0
      then

         begin

         vVlRubrica := XTMPAG_fb.fCalculaFormula(pcdvinculo => rVinculo.CdVinculo,
                                                    pAnoMes => to_char(XTMPAG_var.vgFolha.DtInicioMes,'yyyymm'),
                                                    pcdrubricaagrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,38),
                                                    pDeFormula => vDeFormula, pFlCalculoDefinitivo => XTMPAG_var.vgFolha.FlCalculoDefinitivo );

          vvlCalculadoRubrica.vlIntegral := vVlRubrica;
          vvlCalculadoRubrica.vlProporcional := vVlRubrica;
          vvlCalculadoRubrica.vlReal := vVlRubrica;
          XTMPAG_cal.pAtualizaValorRubrica(pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,38),
                                    pValorRubrica => vvlCalculadoRubrica,
                                    pDeFormula => vDeFormula,
                                    pIncluiRelVinc => 'S');


             exception
               when others
                 then
                   null;

             end;

    end if;

    ---------------------------------------------------------------------------------
    -- Processa as consignacoes
    ---------------------------------------------------------------------------------

    IF (XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal OR
       XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaResidente OR
       XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaFunebre OR
       (XTMPAG_VAR.vgFolha.cdorgao = 25 AND XTMPAG_VAR.vgFolha.CdTipoFolha = 10) OR -- Folha PDI da CIDASC       
       (XTMPAG_VAR.vgFolha.cdorgao = 583 AND XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaRescisao) -- Folha de Rescisão da SC Porto
       ) AND
       XTMPAG_VAR.vgFolha.CdTipoCalculo NOT IN
       (XTMPAG_TIPO.cnTpCalculoSupl) THEN

      --
      -- Processar cartoes de credito primeiro
      -- 10107/2017 - FOLHA - EN: FWD: EN: INADIMPLENCIA CARTAO DE CREDITO - LIMITE EMPREST.
      --

      XTMPAG_var.vgValorAcumulado_CC := 0;

     IF XTMPAG_VAR.vgCdRubricaBaseCSG_CC IS NOT NULL
        THEN

         XTMPAG_CNS.PProcessaBaseConsig(pFolha               => XTMPAG_VAR.vgFolha,
                                         pCdVinculo           => rVinculo.CdVinculo,
                                         pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                         pDtCalculo           => pDtCalculo,
                                       pFlCartaoCredito     => 'S');
      END IF;

        XTMPAG_CNS.PProcessaBaseConsig(pFolha               => XTMPAG_VAR.vgFolha,
                                       pCdVinculo           => rVinculo.CdVinculo,
                                       pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                       pDtCalculo           => pDtCalculo,
                                       pFlCartaoCredito     => 'N');

    END IF;

    XTMPAG_GERAL.PLogProc('4-4-2.Processa Base Consig',
                          '4-4-3.Gera Desc Tesouro');

    ------------------------------------------------------------------------------------
    -- Caso haja indicativo de que houveram pagamentos via tesouraria (Tipo rubrica = 3)
    -- ira gerar a rubrica de desconto 7-9999
    ------------------------------------------------------------------------------------
    IF XTMPAG_VAR.bPossuiLancTesouraria THEN

      XTMPAG_LF.PGeraDescontoLancTesouro(pFolha     => XTMPAG_VAR.vgFolha,
                                         pCdVinculo => rVinculo.CdVinculo);

    END IF;

    XTMPAG_GERAL.PLogProc('4-4-3.Gera Desc Tesouro',
                          '4-4-5.Atualiz Totalizadoras');

    XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                        rVinculo.CdVinculo);

    XTMPAG_GERAL.PLogProc('4-4-5.Atualiz Totalizadoras',
                          '4-4-6.Ver Rescisao');

    ---------------------------------------------------------------------------------------------------------
    -- Caso o vinculo teve recisao
    ---------------------------------------------------------------------------------------------------------
    IF (XTMPAG_VAR.vgVinculo.DtDesligamento <= XTMPAG_VAR.vgFolha.DtFimMes) AND
       (XTMPAG_GERAL.FRetornaValorRubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                          rVinculo.CdVinculo,
                                          XTMPAG_VAR.vgCdRubricaDevAnt13) > 0)

      THEN

      vVlDescReal050524 := nvl(XTMPAG_GERAL.FRetornaValorRubrica(
                                 XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                 rVinculo.CdVinculo,
                                 XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,0524)),0);

      BEGIN
        -- Verifica se já houve desconto de ADIANT 13. SALARIO no ano
        select NVL(sum(h1.vlpagamento), 0)
          INTO vVlDesc050524
          FROM EPagHistoricoRubricaVinculo H1
         INNER JOIN EPagRubricaAgrupamento RA
            ON H1.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
         INNER JOIN EPagRubrica R
            ON RA.CdRubrica = R.CdRubrica
         inner join epagfolhapagamento fp
            on fp.cdfolhapagamento = h1.cdfolhapagamento
         inner join epagtipofolhapagamento tfp
            on fp.cdtipofolhapagamento=tfp.cdtipofolhapagamento
           and fp.nuanoreferencia = XTMPAG_VAR.vgFolha.NuAnoReferencia
           and (fp.numesreferencia < XTMPAG_VAR.vgFolha.NuMesReferencia OR (fp.numesreferencia = XTMPAG_VAR.vgFolha.NuMesReferencia AND tfp.cdtipofolha <> XTMPAG_VAR.vgFolha.cdtipofolha))
           and fp.flcalculodefinitivo = 'S'
           and H1.Cdrubricaagrupamento = XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,0524)
         WHERE H1.CdVinculo = rVinculo.CdVinculo;

      EXCEPTION
        WHEN OTHERS THEN vVlDesc050524 := 0;
      END;

      -- se houver desconto de adiantamento de 13., e a diferença do desconto real
      -- e o valor já descontado for igual a zero, não gera a rubrica
      IF vVlDescReal050524 - vVlDesc050524 = 0
        THEN

       DELETE EPagHistoricoRubricaVinculo HRV
        WHERE HRV.CdVinculo = rVinculo.CdVinculo AND
              HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento AND
              HRV.CdRubricaAgrupamento = XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                               5,
                                                                               0524);


        XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                        rVinculo.CdVinculo);

      ELSIF XTMPAG_VAR.vgVlTotalProventos < XTMPAG_VAR.vgVlTotalDescontos
        THEN

        vVlDescReal050524 := nvl(XTMPAG_GERAL.FRetornaValorRubrica(
                                 XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                 rVinculo.CdVinculo,
                                 XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,0524)),0);
                                 
        vVlDesc050524 := vVlDescReal050524 - (XTMPAG_VAR.vgVlTotalDescontos - XTMPAG_VAR.vgVlTotalProventos); 
        
        IF vVlDesc050524 < 0 THEN
          
          vVlDesc050524 := 0;
          
        END IF;
        
        vVlNaoDesc050524 := vVlDescReal050524 - vVlDesc050524;
       
        if vVlDesc050524 > XTMPAG_VAR.vgVlTotalProventos then
           
           vVlNaoDesc050524 := vVlNaoDesc050524 + (vVlDesc050524 - XTMPAG_VAR.vgVlTotalProventos);
          
           vVlDesc050524 := XTMPAG_VAR.vgVlTotalProventos;
           
        end if;

        -- Solicitacao de Sustentacao #71672: Rubrica 05-0524
        -- Nao gerar liquido negativo para ACT sem a presenca de remuneracao
        IF XTMPAG_VAR.vgFolha.CdOrgao = 41 AND --Orgao 2001
            XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = XTMPAG_TIPO.cnRelACT AND
            XTMPAG_VAR.vgVlTotalProventos = 0 THEN

              XTMPAG_VAR.vgVlTotalDescontos := 0;
        END IF;

        -- Nr da solicitacao: 6087/2014
        -- Correcao do calculo da rubrica 09-9524 e das rubricas 05-1023 e 05-0524.
        -- Alterado update abaixo para acertar os valores das rubricas
        --
        UPDATE EPagHistoricoRubricaVinculo HRV
          SET VlPagamento = vVlDesc050524
        WHERE HRV.CdVinculo = rVinculo.CdVinculo 
          AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento 
          AND HRV.CdRubricaAgrupamento = XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                               5,
                                                                               0524);
        

        XTMPAG_VAR.vgVlBaseTotDSC := XTMPAG_VAR.vgVlTotalDescontos;

        --
        -- Desconsiderar da Base dos Descontos o total de faltas
        --

        vVlDescFaltas := nvl(XTMPAG_GERAL.FRetornaValorRubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                             rVinculo.CdVinculo,
                                             XTMPAG_GERAL.FRetornaCodigoRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                25)),0);

        IF vVlDescFaltas > 0 AND
           XTMPAG_VAR.vgVlBaseTotalLiquida < 0 THEN

           XTMPAG_VAR.vgVlBaseTotDSC := XTMPAG_VAR.vgVlTotalDescontos - vVlDescFaltas;

        END IF;

        IF XTMPAG_GERAL.FRetornaValorRubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                             rVinculo.CdVinculo,
                                             XTMPAG_VAR.vgCdRubDevAnt13NaoEfetuado) > 0 THEN
               
          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.vlPagamento = HRV.vlPagamento + vVlNaoDesc050524
           WHERE HRV.cdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.cdVinculo = rVinculo.CdVinculo
             AND HRV.cdRubricaAgrupamento = XTMPAG_VAR.vgCdRubDevAnt13NaoEfetuado;  
                                       
        ELSE
          
          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => rVinculo.CdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubDevAnt13NaoEfetuado,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => vVlNaoDesc050524,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);
        END IF;
        --
        -- Acertar valores das rubricas para nao gerar liquido negativo
        --

        XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                            rVinculo.CdVinculo);

        /*IF XTMPAG_VAR.vgVlTotalProventos < XTMPAG_VAR.vgVlTotalDescontos

          THEN

         --  05-0524-01 ADIANT 13. SALARIO
         vVlDesc050524 := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo        => rVinculo.CdVinculo,
                                             pCdRubrica        => XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                               5,
                                                                                              0524));
         IF XTMPAG_VAR.vgVlTotalDescontos - vVlDesc050524 > XTMPAG_VAR.vgVlTotalProventos
           THEN
           --Base tem q considerar o valor já pago do adiantamento
           XTMPAG_VAR.vgVlBaseTotDSC := XTMPAG_VAR.vgVlTotalDescontos - vVlDesc050524;

         END IF;

         vVlDesc050524 := XTMPAG_VAR.vgVlTotalDescontos - XTMPAG_VAR.vgVlTotalProventos;

         UPDATE EPagHistoricoRubricaVinculo HRV
             SET VlPagamento = vlPagamento - vVlDesc050524 --(XTMPAG_VAR.vgVlBaseTotDSC -
                               --XTMPAG_VAR.vgVlTotalProventos)
           WHERE HRV.CdVinculo = rVinculo.CdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND (vlPagamento -
                 (XTMPAG_VAR.vgVlBaseTotDSC - XTMPAG_VAR.vgVlTotalProventos)) > 0
             AND HRV.CdRubricaAgrupamento in
                 (XTMPAG_VAR.vgCdRubricaDevAnt13,
                  XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                               5,
                                               0524));
        END IF;*/
        

      END IF;

       --se não houver valor de proventos não gera o desconto
       IF (nvl(XTMPAG_VAR.vgVlTotalDescontos,0) = nvl(vVlDesc050524,0)
             AND nvl(XTMPAG_VAR.vgVlTotalProventos,0) = 0)
             --ou se já houve o desc de adiantamento em folha anterior
             OR (FPossuiDescAdiantamento13(rVinculo.CdVinculo,
                                       XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                               5,
                                               0524),
                                       XTMPAG_VAR.vgFolha.nuAnoReferencia,
                                       XTMPAG_VAR.vgFolha.nuMesReferencia)) > 0 THEN

            UPDATE EPagHistoricoRubricaVinculo HRV
             SET VlPagamento = 0
           WHERE HRV.CdVinculo = rVinculo.CdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento in
                 (XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                               5,
                                               0524));

        END IF;

        XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                              rVinculo.CdVinculo);

    END IF;

    XTMPAG_GERAL.PLogProcFim('4-4-6.Ver Rescisao');

    XTMPAG_GERAL.PLogProc('4-4.Tributacao', '4-5.Liq Negativo');

    ------------------------------------------------------------------------------------
    -- Atualmente so executa o evento PDescontoLiqNegativo para o CIASC e SC Parcerias e SANTUR
    ------------------------------------------------------------------------------------

    IF XTMPAG_VAR.vgFolha.CdAgrupamento IN (2, 3, 5, 6, 136) AND
       XTMPAG_VAR.vgFolha.CdTipoCalculo <>
       XTMPAG_TIPO.cnTpCalculoRecalcCompl THEN

      XTMPAG_POS.PDescontoLiqNegativo(pFolha     => XTMPAG_VAR.vgFolha,
                                      pCdVinculo => rVinculo.CdVinculo);

    END IF;

    XTMPAG_POS.PLiqNegativo(pFolha     => XTMPAG_VAR.vgFolha,
                            pCdVinculo => rVinculo.CdVinculo);

    -----------------------------------------------------------------
    -- Gera rubricas totalizadoras de Total de Proventos e Descontos
    -----------------------------------------------------------------

    XTMPAG_GERAL.PLogProc('4-5.Liq Negativo', '4-6.Rub Tot');

    XTMPAG_GERAL.PAtualizaTotalizadoras(XTMPAG_VAR.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo);

    IF XTMPAG_VAR.vgVlTotalProventos <> 0 OR
       XTMPAG_VAR.vgVlTotalDescontos <> 0 THEN

      IF XTMPAG_VAR.vgCdRubricaBaseTotPrv > 0 THEN

        IF XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo        => rVinculo.CdVinculo,
                                             pCdRubrica        => XTMPAG_VAR.vgCdRubricaBaseTotPrv) = 0 THEN

          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => rVinculo.CdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotPrv,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => NVL(XTMPAG_VAR.vgVlTotalProventos,
                                                                             0),
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

        ELSE

          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.VlPagamento = NVL(XTMPAG_VAR.vgVlTotalProventos, 0)
           WHERE HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdVinculo = rVinculo.CdVinculo
             AND HRV.CdRubricaAgrupamento =
                 XTMPAG_VAR.vgCdRubricaBaseTotPrv;

        END IF;

      END IF;

      IF XTMPAG_VAR.vgCdRubricaBaseTotDsc > 0 THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => rVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotDsc,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => NVL(XTMPAG_VAR.vgVlTotalDescontos,
                                                                           0),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

      END IF;

      IF XTMPAG_VAR.vgCdRubricaBaseTotLiq > 0 THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => rVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotLiq,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => XTMPAG_VAR.vgVlBaseTotalLiquida,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

      END IF;

    END IF;

    XTMPAG_GERAL.PLogProc('4-6.Rub Tot', '4-7.Desc Facult');

    ---------------------------------------------------------------
    -- Gera rubrica totalizador de Total de descontos facultativos
    ---------------------------------------------------------------

    IF XTMPAG_VAR.vgCdRubBaseDescFacultativos > 0 THEN

      XTMPAG_VAR.vgVlTotalDescontosFacult := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                               pCdVinculo        => rVinculo.CdVinculo,
                                                                               pCdRubrica        => XTMPAG_VAR.vgCdRubricaCSGProc) +

                                             XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                               pCdVinculo        => rVinculo.CdVinculo,
                                                                               pCdRubrica        => XTMPAG_VAR.vgCdRubricaCSGNaoProc) +

                                              XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                pCdVinculo        => rVinculo.CdVinculo,
                                                                                pCdRubrica        => XTMPAG_VAR.vgCdRubricaCSGProcCC) ;

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => rVinculo.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDescFacultativos,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => NVL(XTMPAG_VAR.vgVlTotalDescontosFacult,
                                                                         0),
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);
    END IF;

    XTMPAG_GERAL.PLogProc('4-7.Desc Facult', '4-8.Rot Pos Calc');

    ------------------------------------------------------------------
    -- Regera a base do abono da SSP
    -- Motivo: A base e calculada em todas as relacoes, ao
    -- consolidar no vinculo ela pode subir "dobrada"
    ------------------------------------------------------------------

    IF XTMPAG_VAR.vgRubrica.EXISTS(XTMPAG_VAR.vgCdRubBaseAbonoSeguranca) THEN

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseAbonoSeguranca,
                                       pTpProcessamento => 2, -- Processa base de calculo
                                       pTpLocal         => 2); -- no vinculo

    END IF;

    -------------------------------------------------------------------
    -- Gera capa
    -------------------------------------------------------------------

    IF XTMPAG_VAR.vPagaSitDisposicao NOT IN
       ('PAG-DEST-CALCULO-ORIGEM',
        'PAG-ORIGEM-CALCULO-DEST',
        'NAO-DISPOSICAO') or
        -- SIG-5023 NAO gerou capa do contracheque
        XTMPAG_VAR.vgVlTotalProventos > 0 THEN

      XTMPAG_GERAL.PGeraCapaLote(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                 pCdVinculo            => rVinculo.CdVinculo,
                                 pFlAtivo              => XTMPAG_geral.fflativo(rvinculo.CdVinculo, rvinculo.CdSituacaoPrevidenciaria),
                                 pMotAfast             => XTMPAG_VAR.vMotAfast,
                                 pFlPagamentoBloqueado => rVinculo.FlPagamentoBloqueado);

    END IF;

    ----------------------------------------------------------------
    -- Executa rotina de pos calculo
    -- Nao deve conquistar PA de licenca premio com mais de 70 anos
    ----------------------------------------------------------------

    BEGIN

    IF XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal AND
       XTMPAG_VAR.vgFolha.CdTipoCalculo <> XTMPAG_TIPO.cnTpCalculoSupl THEN

      IF MONTHS_BETWEEN(XTMPAG_VAR.vgFolha.DtFimMes,
                        XTMPAG_VAR.vgVinculo.DtNascimento) <
         XTMPAG_TIPO.cnMesesIdade70 THEN
NULL;
--        XTMPAG_PC.PGeraPerAquisLicPre(pVinculo             => rVinculo,
--                                      pDtFimMes            => XTMPAG_VAR.vgFolha.DtFimMes,
--                                      pCdTipoLicencaPremio => 1); -- Licenca Premio

--        XTMPAG_PC.PGeraPerAquisLicPre(pVinculo             => rVinculo,
--                                      pDtFimMes            => XTMPAG_VAR.vgFolha.DtFimMes,
--                                      pCdTipoLicencaPremio => 2); -- Premio Assiduidade

      END IF;

    END IF;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;

    END;

    -- Valor Patronal INSS

    IF NVL(XTMPAG_VAR.vgCdRubBaseValorPatINSS, 0) > 0

     THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => rVinculo.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseValorPatINSS,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseValorPatINSS,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

    END IF;

    --
    -- Base Patronal IPREV FF
    -- Solicitacao de Sustentacao #68483
    -- 8505/2016 - FOLHA - - IDENTIFICACAO DA NAO GERACAO DO CODIGO 09-1017-PATRONAL DO IPREV FF
    --
    IF rVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevProprio
      AND rVinculo.CdSituacaoPrevidenciaria = XTMPAG_tipo.cnSitPrevAtivo
      AND NVL(XTMPAG_VAR.vgCdRubBaseIPREVFF,0) > 0
      AND NVL(XTMPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                        pcdvinculo => rVinculo.CdVinculo,
                                                        pcdrubrica => XTMPAG_VAR.vgCdRubBaseIPREVFF),0) = 0
     THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIPREVFF,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIPREVFF,
                                       pTpProcessamento => 2, -- Processa base de calculo
                                       pTpLocal         => 2); -- no vinculo

    END IF;
    --
    -- SIG-2236
    -- SEA - 14003/2019 - Patronal de IPREV para servidor INATIVO -- Nao deve gerar a patronal
    --
    IF rVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevProprio
      AND rVinculo.CdSituacaoPrevidenciaria IN (XTMPAG_tipo.cnSitPrevInstPensao, XTMPAG_tipo.cnSitPrevFalecido)
      AND NVL(XTMPAG_VAR.vgCdRubBaseIPREVFF,0) > 0
      AND NVL(XTMPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                        pcdvinculo => rVinculo.CdVinculo,
                                                        pcdrubrica => XTMPAG_VAR.vgCdRubBaseIPREVFF),0) > 0
     THEN

         delete epaghistoricorubricavinculo hrvc
           where hrvc.cdvinculo = rVinculo.CdVinculo
             and hrvc.cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             and hrvc.cdrubricaagrupamento = XTMPAG_VAR.vgCdRubBaseIPREVFF;

    END IF;


    IF XTMPAG_VAR.vgFolha.cdorgao = 25 -- Reprocessar base

     THEN

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 49218,
                                       pTpProcessamento => 2, -- Processa base de calculo  Patronal Ceres
                                       pTpLocal         => 2);

      if nvl(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803)),0) > 0 then

          XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803),
                                           pTpProcessamento => 1, -- Processa base de c?lculo
                                           pTpLocal         => 2);


          delete epaghistoricorubricarelvinc rvc
           where rvc.cdvinculo = rVinculo.CdVinculo
             and rvc.cdfolhapagamento =  XTMPAG_VAR.vgFolha.CdFolhaPagamento
             and rvc.cdhistcargoefetivo is null
             and rvc.cdrubricaagrupamento =   XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803);

          update epaghistoricorubricarelvinc rvc
             set rvc.vlintegral = XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    rVinculo.CdVinculo,
                                                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                 rvc.vlreal = XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    rVinculo.CdVinculo,
                                                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                 rvc.vlproporcional = XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    rVinculo.CdVinculo,
                                                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803))
           where rvc.cdvinculo = rVinculo.CdVinculo
             and rvc.cdfolhapagamento =  XTMPAG_VAR.vgFolha.CdFolhaPagamento
             and rvc.cdhistcargoefetivo is not null
             and rvc.cdrubricaagrupamento =   XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,803);


      end if;

      --
      -- Alterar codigos das rubricas de ferias para comissionados que optaram pelo recebimento: PELO CARGO COMISSIONADO ou PELO F.G. OU F.T.G
      --
      if XTMPAG_var.vgcco.count > 0
        then
        for i in XTMPAG_var.vgcco.first .. XTMPAG_var.vgcco.last
        loop

        if XTMPAG_var.vgFolha.CdTipoFolha = XTMPAG_tipo.cnTpFolhaFerias and
         --XTMPAG_var.vgcco.count > 0 and
         fretornaopcaoremuneracaocco(pcdhistcargocom => XTMPAG_var.vgcco(i).cdhistcargocom,
                                                               pdtiniciomes => XTMPAG_var.vgfolha.dtiniciomes,
                                                               pdtfimmes => XTMPAG_var.vgfolha.dtfimmes)  in (3,6)
         then

           if nvl(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,7)),0) > 0 then

             pAtualizaValorRubrica (pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,7),
                                    pValorRubrica => vvlCalculadoRubrica,
                                    pCdOutraRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,1207));


           end if;

           if nvl(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,56)),0) > 0 then

              pAtualizaValorRubrica (pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,56),
                                    pValorRubrica => vvlCalculadoRubrica,
                                    pCdOutraRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,1256));

           end if;

           if nvl(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,83)),0) > 0 then

              pAtualizaValorRubrica (pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,83),
                                    pValorRubrica => vvlCalculadoRubrica,
                                    pCdOutraRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,1283));

           end if;

      end if;

      if XTMPAG_var.vgFolha.CdTipoFolha =1 and
         XTMPAG_VAR.vgFolha.cdorgao = 25 and
         rVinculo.CdVinculo = 656528 and
         fretornaopcaoremuneracaocco(pcdhistcargocom => XTMPAG_var.vgcco(i).cdhistcargocom,
                                                               pdtiniciomes => XTMPAG_var.vgfolha.dtiniciomes,
                                                               pdtfimmes => XTMPAG_var.vgfolha.dtfimmes)  in (3,6)
         then

            SELECT  vlpagamento
            into  Vvalor011207
            FROM EPagHistoricoRubricaVinculo HRV
            WHERE CdFolhaPagamento in  (select cdfolhapagamento from epagfolhapagamento fpg
                                        inner join epagtipofolhapagamento tfp
                                        on fpg.cdtipofolhapagamento=tfp.cdtipofolhapagamento
                                        where fpg.cdorgao=XTMPAG_VAR.vgFolha.cdorgao
                                        and fpg.nuanoreferencia= XTMPAG_VAR.vgfolha.nuanoreferencia
                                        and fpg.numesreferencia= XTMPAG_VAR.vgfolha.numesreferencia
                                        and tfp.cdtipofolha=4
                                        and fpg.cdtipocalculo=1
                                        and fpg.flcalculodefinitivo='S')
            AND CdVinculo = rVinculo.CdVinculo
            and cdrubricaagrupamento =  XTMPAG_geral.fretornarubrica(4,1,1207);

                if Vvalor011207 > 0 then

                    XTMPAG_geral.PInsereLancamentoVinculo(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                         rVinculo.CdVinculo,
                                                         null,
                                                         XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,5,007),
                                                         5,
                                                         Vvalor011207);
               end if;

        end if;



      end loop;

     end if;
    end if;

    BEGIN

        IF XTMPAG_VAR.vgFolha.cdorgao = 25
        AND nvl(XTMPAG_var.vgValorCalculoRubrica(49205).VlLimiteInferior, 0) > 0
        AND XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento  => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    pcdvinculo           => rVinculo.CdVinculo,
                                                                    pcdrubrica           => 49205,
                                                                    pnusufixo            => 1) < nvl(XTMPAG_var.vgValorCalculoRubrica(49205).VlLimiteInferior, 0) THEN

        vvlCalculadoRubrica.vlIntegral := XTMPAG_var.vgValorCalculoRubrica(49205).VlLimiteInferior;

        pAtualizaValorRubrica (rVinculo.CdVinculo,
                               XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                               49205,
                               vvlCalculadoRubrica);

        END IF;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END ;                                                                   

    IF XTMPAG_VAR.vgFolha.cdorgao = 27 -- forcar o calculo das ferias

     THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => rVinculo.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => 44591, --09-1008
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 44591,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- BASE CASACARESC  09-0955
      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 44581,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- BASE SAUDE PATRONAL 09-0380
      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 45639,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- BASE BAIXA DE FERIAS INDENIZADAS 09-2007
      IF XTMPAG_GERAL.fRetornaValorRubrica(pcdfolhapagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pcdvinculo => rVinculo.CdVinculo,
                                                  pcdrubrica => XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,1,294)) > 0
       THEN

         XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => rVinculo.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => 47724,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);

         XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                          pCdVinculo       => rVinculo.CdVinculo,
                                          pCdRubrica       => 47724,
                                          pTpProcessamento => 2, -- Processa base de c?lculo
                                          pTpLocal         => 2);
      END IF;

    END IF;

    if XTMPAG_geral.fpossuilancfinanceiro(rVinculo.CdVinculo,
                                          XTMPAG_VAR.vgFolha,
                                          XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,8184))
      and nvl(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                rVinculo.CdVinculo,
                                                XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,8184)),0) > 0 then

      begin

      delete epaghistoricorubricavinculo hrv
       where cdvinculo = rVinculo.CdVinculo
         and cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
         and cdrubricaagrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,8184)
         and hrv.cdtipoorigemrubrica <> 2;

      delete epaghistoricorubricarelvinc hrr
       where cdvinculo = rVinculo.CdVinculo
         and cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
         and cdrubricaagrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,8184)
         and hrr.cdtipoorigemrubrica <> 2;

       exception
         when others then
           null;
       end;

    end if;
    --
    -- GERAR OCORRENCIA DE ERRO PARA LIQUIDO NEGATIVO DE PENSIONISTA -- Solicitacao de Sustentacao #64581
    --
    IF XTMPAG_var.bPossuiPensao
      THEN

         XTMPAG_GERAL.pValidaTotalPensao(pcdfolhapagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                pcdvinculo => rVinculo.CdVinculo);
    END IF;

    --
    -- Exclusao de rubricas de base de pensao com valor = 1
    --
    IF NVL(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                rVinculo.CdVinculo,
                                                XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,9053)),0) <= 1
       THEN

         DELETE FROM EpagHistoricoRubricaVinculo HRV
               WHERE HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
                AND  HRV.CdVinculo = rVinculo.CdVinculo
                AND  HRV.Cdrubricaagrupamento in (XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,9052),
                                                  XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,9,9053));

    END IF;

    XTMPAG_GERAL.PExcluiValoresZerados(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                       pCdVinculo        => rVinculo.CdVinculo);

    XTMPAG_GERAL.PLogProc('4-8.Rot Pos Calc', '4-9.Del Hist Rub');

    IF XTMPAG_VAR.vgVlTotalProventos = 0 AND
       XTMPAG_VAR.vgVlTotalDescontos = 0 THEN

      DELETE FROM EpagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
         AND HRV.CdVinculo = rVinculo.CdVinculo;

    ELSIF XTMPAG_VAR.vListaRubricas.EXISTS(8774) THEN

      IF XTMPAG_VAR.vgVlTotalProventos = XTMPAG_VAR.vListaRubricas(8774) THEN

        XTMPAG_GERAL.PExcluirPagVinc(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     rVinculo.CdVinculo);

      END IF;

    ELSIF XTMPAG_VAR.vgFolha.CdTipoCalculo <> XTMPAG_TIPO.cnTpCalculoSupl THEN

      PExpurgarTotalizadoras(pFolha   => XTMPAG_VAR.vgFolha,
                             pVinculo => rVinculo);

    else
      null;
    END IF;

    XTMPAG_GERAL.PLogProcFim('4-9.Del Hist Rub');

    ------------------------------------------------------------------------------
    -- Garante que rubricas nao terao sufixos duplicados no contracheque
    ------------------------------------------------------------------------------

    --XTMPAG_GERAL.PLogProcIni ('4-10.Trata Sufixo Duplicado');

    --PTrataSufixosDuplicados(pCdVinculo        => rVinculo.CdVinculo,
    --                        pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento);

    --XTMPAG_GERAL.PLogProcFim ('4-10.Trata Sufixo Duplicado');

    XTMPAG_GERAL.PLogProcIni('4-11.Pedido DGRH');

    --------------------------------------------------------------------------------------
    -- Caso a origem do calculo seja previa, 1 calculo ou 2 calculo
    -- realiza a copia dos contra-cheques da normal para a
    -- folha do tipo de calculo
    --------------------------------------------------------------------------------------

    IF XTMPAG_VAR.vgFolhaOrigem.CdTipoCalculo IN (7, 8, 9) THEN

      PCopiaContraCheques(pCdFolhaOrigem  => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                          pCdFolhaDestino => XTMPAG_VAR.vgFolhaOrigem.CdFolhaPagamento,
                          pCdVinculo      => rVinculo.CdVinculo);

    END IF;

    XTMPAG_GERAL.PLogProcFim('4-11.Pedido DGRH');

   IF pFlCalculoDefinitivo = 'S'

    THEN
    -- Conta os dias de falta que seao descontados
    -- e salva na variavel  vNuFaltas
   ------------------------------------------------------------------------------

   -- Inicializa a variavel
    vNuFaltas:= tFalta();
    vNuFaltas.Extend(12);

    if   XTMPAG_var.vgFaltas.count > 0
        and (XTMPAG_VAR.vgIndiceFaltasMesAnterior  > 0 or  XTMPAG_VAR.vgIndiceFaltasMesAtual > 0) then

          for i in XTMPAG_var.vgFaltas.first .. XTMPAG_var.vgFaltas.last
            loop

              if XTMPAG_var.vgFaltas(i).FlAbonado = 'N' then

              vNuMEsFalta := to_char( XTMPAG_var.vgFaltas(i).DtFrequencia,'mm');
               vNuFaltas(vnuMesFalta) :=  NVL(vNufaltas(vNumesFalta),0) +
                                        (XTMPAG_var.vgfaltas(i).numfracaofalta / XTMPAG_var.vgFaltas(i).denfracaofalta);
              --vNuFaltas(vnuMesFalta) :=  NVL(vNufaltas(vNumesFalta),0) + 1;

               end if;
           end loop;

           if XTMPAG_VAR.vgIndiceFaltasMesAtual > 0 -- Evento 82
             then
                XTMPAG_POS.PAtualizaEventoVinculo(pCdVinculo     => rVinculo.CdVinculo,
                                                                                  pFolha         => XTMPAG_VAR.vgFolha,
                                                                                  pCdTipoEvento  => 4,
                                                                                  pCdRubrica => XTMPAG_VAR.vgCdRubEvento82,
                                                                                  pVlIndice => XTMPAG_VAR.vgIndiceFaltasMesAtual ); --

           end if;

           if XTMPAG_VAR.vgIndiceFaltasMesAnterior > 0 -- Evento 81
             then

                 for i in 1 .. 12
                   loop

                      if vNuFaltas(i) is not null
                        then
                            XTMPAG_POS.PAtualizaEventoVinculo(pCdVinculo     => rVinculo.CdVinculo,
                                                                                  pFolha         => XTMPAG_VAR.vgFolha,
                                                                                              pCdTipoEvento  => 4,
                                                                                              pCdRubrica => XTMPAG_VAR.vgCdRubEvento81,
                                                                                              pVlIndice => vNuFaltas(i),
                                                                                              pNuMes => i,
                                                                                              pNuAno => case when i > XTMPAG_var.vgfolha.numesreferencia
                                                                                                                  then  XTMPAG_var.vgfolha.nuanoreferencia -1
                                                                                                                  else  XTMPAG_var.vgfolha.nuanoreferencia end) ;

                     end if;

                   end loop;

           end if;

      end if;

    END IF;

   -- pPossuiLancFinSemRegistro(XTMPAG_var.vgFolha, rVinculo.CdVinculo);

    IF XTMPAG_VAR.vgFolha.cdtipofolha in (XTMPAG_tipo.cnTpFolhaServAfast) THEN
      UPDATE eafaafastamentovinculo Afa
         SET Afa.Flanulado = XTMPAG_TIPO.cnN
       WHERE Afa.Cdafastamento in (select a.cdafastamento
                                     from epaghistfolhaservafast a
                                    where a.cdfolhapagamento = XTMPAG_var.vgFolha.cdFolhaPagamento
                                      and a.cdvinculo = rVinculo.CdVinculo);
      delete epaghistfolhaservafast a
       where a.cdfolhapagamento = XTMPAG_var.vgFolha.cdFolhaPagamento
         and a.cdvinculo = rVinculo.CdVinculo;
    END IF;

    -- Expugar contra-cheque "Outras Folhas" que não possuem valor - EXTRATOR
    IF XTMPAG_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766)
      AND XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S'
      THEN

      for dados in (select capa.cdfolhapagamento,
                           capa.cdvinculo
                      from epagcapahistrubricavinculo capa
                     Where capa.cdfolhapagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
                       and capa.cdvinculo = rVinculo.CdVinculo
                       and (capa.vlproventos = 0 and capa.vldescontos = 0)) loop

      delete epagcapahistrubricavinculo
       where cdvinculo = dados.cdvinculo
         and cdfolhapagamento = dados.cdfolhapagamento;

      delete epaghistoricorubricarelvinc
       where cdvinculo = dados.cdvinculo
         and cdfolhapagamento = dados.cdfolhapagamento;

      delete epaghistoricorubricavinculo
       where cdvinculo = dados.cdvinculo
         and cdfolhapagamento = dados.cdfolhapagamento;

      END LOOP;
    END IF;

    <<FIM_LOOP>>

    NULL;

--pInsereLogDebug('t', 2, rVinculo.CdVinculo, null, null, null, null, null, null, null, null, null, 0);
  END;


 PROCEDURE PGeraTotalizadoras(pCalculo          IN XTMPAG_CAL.rCalculo,
                             pCdVinculo        IN INTEGER,
                             pCdFolhaPagamento IN INTEGER) IS

  vFolha               XTMPAG_TIPO.rFolha;

  vVlDevAntNaoEfetuada NUMBER(13,2);

  FUNCTION FPensoesDescontadas

    RETURN INTEGER IS

    vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCont := 0;

    SELECT COUNT(*)
      INTO vCont
      FROM EPagHistoricoRubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.CdVinculo = pCdVinculo AND
           HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensao13;

    RETURN vCont;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;

  END;

BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  OPEN XTMPAG_VAR.cFolha(pCdFolhaPagamento);

  FETCH XTMPAG_VAR.cFolha INTO vFolha;

  CLOSE XTMPAG_VAR.cFolha;

  XTMPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => pCdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo);

  -----------------------------------------------------------------------------
  -- Insere Total de Proventos
  -----------------------------------------------------------------------------

  IF XTMPAG_VAR.vgVlTotalProventos > 0 THEN

    DELETE
      FROM EPagHistoricoRubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.CdVinculo = pCdVinculo AND
           HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaBaseTotPrv;

    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotPrv,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => XTMPAG_VAR.vgVlTotalProventos,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);
  END IF;

  -----------------------------------------------------------------------------
  -- Insere Total de Descontos
  -----------------------------------------------------------------------------

  IF XTMPAG_VAR.vgVlTotalDescontos > 0 THEN

    DELETE
      FROM EPagHistoricoRubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.CdVinculo = pCdVinculo AND
           HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaBaseTotDsc;

    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotDsc,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => XTMPAG_VAR.vgVlTotalDescontos,
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
                                    CdRubricaAgrupamento = XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensao13) A
                      INNER JOIN (SELECT HRV.Cdhistoricorubricavinculo,
                                         HRV.CdRubricaAgrupamento,
                                         HRV.NuSufixoRubrica,
                                         HRV.VlPagamento
                                    FROM EPagHistoricoRubricaVinculo hrv
                                   WHERE CdFolhaPagamento = pcdFolhaPagamento AND
                                         CdVinculo = pCdVinculo AND
                                         CdRubricaAgrupamento = XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
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
            CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaBaseTotPrv AND
            CdVinculo = pCdVinculo ;

     XTMPAG_VAR.vgVlTotalProventos := XTMPAG_VAR.vgVlTotalProventos - vPagPensao.VlAdiantNaoeEfetuado;

     XTMPAG_VAR.vgVlBaseTotalLiquida := XTMPAG_VAR.vgVlBaseTotalLiquida - vPagPensao.VlAdiantNaoeEfetuado;

     XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                           pCdVinculo            => pCdVinculo,
                                           pCdExpressaoFormCalc  => NULL,
                                           pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDevAd13NaoEfet,
                                           pNuSufixoRubrica      => vPagPensao.NuSufixoRubrica,
                                           pVlPagamento          => vPagPensao.VlAdiantNaoeEfetuado,
                                           pVlIndice             => NULL,
                                           pCdTipoOrigemRubrica  => 1);

     XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                            pCalculo.CdHistoricoParamCalculo,
                            XTMPAG_VAR.vgVinculo.CdPessoa,
                            'Valor de desconto de adiantamento de pensão descontado parcialmente.',
                            XTMPAG_VAR.vgVinculo.CdVinculo,
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
         HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaBaseTotLiq;

  IF XTMPAG_VAR.vgVlBaseTotalLiquida > 0.01 THEN

    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseTotLiq,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => XTMPAG_VAR.vgVlBaseTotalLiquida,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

  ELSIF vFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolhaAdiant13) THEN

    -- Exclui contracheque zerado, caso nao possua rubrica 5-471 (DEPOSITO JUDICIAL)
    IF NOT (XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                              pCdVinculo,
                                              XTMPAG_GERAL.FRetornaRubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                       5,
                                                                       471)) > 0) THEN

      DELETE
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo;

    END IF;

  -- Retirada do liquido negativo atraves de compensacao do valor da devolucao do adiantamento de 13o
  ELSIF vFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13, XTMPAG_TIPO.cnTpFolhaResidente13, XTMPAG_TIPO.cnTpFolhaCTISP13)THEN

     IF XTMPAG_VAR.vgFolha.CdAgrupamento <> 2 AND
       XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                         pCdVinculo,
                                         XTMPAG_VAR.vgCdRubricaDevAnt13
                                         ) > 0 THEN

       XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubDevAnt13NaoEfetuado,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => ABS(XTMPAG_VAR.vgVlBaseTotalLiquida),
                                             pVlIndice             => NULL,
                                             pCdTipoOrigemRubrica  => 1);

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - ABS(XTMPAG_VAR.vgVlBaseTotalLiquida)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaDevAnt13;

      vVlDevAntNaoEfetuada := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                                                pCdVinculo,
                                                                XTMPAG_VAR.vgCdRubDevAnt13NaoEfetuado);

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - nvl(vVlDevAntNaoEfetuada,0)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaBaseTotDsc;
      --
      -- Solicitacao de Sustentacao #74520
      -- Acertar total de descontos na capa do contracheque - rotina de folha
      --
      XTMPAG_VAR.vgVlTotalDescontos := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento,
                                                                          pCdVinculo,XTMPAG_VAR.vgCdRubricaBaseTotDsc);

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vgVinculo.CdPessoa,
                              'Valor de desconto de adiantamento descontado parcialmente.',
                              XTMPAG_VAR.vgVinculo.CdVinculo,
                              2,
                              17);

     -- Retirada do liquido negativo atraves de compensacao do valor de pensao quando existe apenas uma
     ELSIF XTMPAG_VAR.vgFolha.CdAgrupamento <> 2 AND FPensoesDescontadas = 1  THEN

       XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pCdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBasePensaoNaoDesc,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => ABS(XTMPAG_VAR.vgVlBaseTotalLiquida),
                                             pVlIndice             => NULL,
                                             pCdTipoOrigemRubrica  => 1);

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - ABS(XTMPAG_VAR.vgVlBaseTotalLiquida)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensao13;

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.VlPagamento =  HRV.VlPagamento - ABS(XTMPAG_VAR.vgVlBaseTotalLiquida)
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
             HRV.CdVinculo = pCdVinculo AND
             HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaBaseTotDsc;

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                               pCalculo.CdHistoricoParamCalculo,
                               XTMPAG_VAR.vgVinculo.CdPessoa,
                               'Valor de pensao de 13 salário não descontado.',
                               XTMPAG_VAR.vgVinculo.CdVinculo,
                               2,
                               18);

     ELSE

      IF ABS(XTMPAG_VAR.vgVlBaseTotalLiquida) > 0 THEN

        -------------------------------------------------------------------------------------------
        -- Geracao de liquido negativo
        -------------------------------------------------------------------------------------------
         XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => pCdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgParamOrgao.CdRubricaProvento,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => ABS(XTMPAG_VAR.vgVlBaseTotalLiquida),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

         UPDATE EPagHistoricoRubricaVinculo HRV
            SET HRV.VlPagamento =  HRV.VlPagamento - ABS(XTMPAG_VAR.vgVlBaseTotalLiquida)
          WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
                HRV.CdVinculo = pCdVinculo AND
                HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubricaBaseTotDsc;

         XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                 pCalculo.CdHistoricoParamCalculo,
                                 XTMPAG_VAR.vgVinculo.CdPessoa,
                                 'Geração de líquido negativo.',
                                 XTMPAG_VAR.vgVinculo.CdVinculo,
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

     XTMPAG_GERAL.PGeraCapaLote(pCdFolhaPagamento         => pCdFolhaPagamento,
                                pCdVinculo                => pCdVinculo,
                                pFlAtivo                  => XTMPAG_geral.fflativo(XTMPAG_VAR.vgVinculo.CdVinculo, XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria),
                                pMotAfast                 => NULL,
                                pFlPagamentoBloqueado     => XTMPAG_VAR.vgVinculo.FlPagamentoBloqueado);



END;

  PROCEDURE PInicializaVariaveis (pRegVinc   IN rVinc,
                                pDtCalculo IN DATE) IS

BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  -- Constantes

  XTMPAG_VAR.vgPercDecJudMargem                 := 100;

  XTMPAG_VAR.bReprocessou13Sal                  := FALSE;

  XTMPAG_VAR.vgCdRubricaAbonoPerm               := 0;

  XTMPAG_VAR.vgQtFaltas                         := 0;

  XTMPAG_VAR.vgVinculo.CdVinculo                := pRegVinc.CdVinculo;

  XTMPAG_VAR.vgVinculo.CdPessoa                 := pRegVinc.CdPessoa;

  XTMPAG_VAR.vgVinculo.DtAdmissao               := pRegVinc.DtAdmissao;

  XTMPAG_VAR.vgVinculo.DtNascimento             := pRegVinc.DtNascimento;

  XTMPAG_VAR.vgVinculo.DtDesligamento           := pRegVinc.DtDesligamento;

  XTMPAG_VAR.vgVinculo.CdRegimeTrabalho         := pRegVinc.CdRegimeTrabalho;

  XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario   := pRegVinc.CdRegimePrevidenciario;

  XTMPAG_VAR.vgVinculo.FlSexo                   := pRegVinc.FlSexo;

  XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria := XTMPAG_GERAL.FSituacaoPrevVigente(pCdVinculo   => pRegVinc.CdVinculo,
                                                                                     pDtInicioMes => XTMPAG_VAR.vgFolha.DtInicioMes,
                                                                                     pDtFimMes    => XTMPAG_VAR.vgFolha.DtFimMes);

  XTMPAG_VAR.vgVinculo.CdFolhaPagamentoNormal := 0;


  XTMPAG_VAR.vpagasitdisposicao := '';

END;

PROCEDURE PProcessarDuploVinculo (pCalculo                 IN XTMPAG_CAL.rCalculo,
                                      pRegVinc                 IN rVinc,
                                      pDtCalculo               IN DATE) IS

  vVinc                       rVinc;

  --vVlTeto                     NUMBER(13,2);

  vVlIndice                   INTEGER;

  vDtInicioDireito            DATE;

  vDtInclusao                 DATE;

  --vVlIsencaoBloqueio          NUMBER(13,2);

  --vCdRubricaDevAdiant13CTISP  INTEGER;

  vVlAdiantamentoPago         NUMBER(13,2);

  --vCdRubrica0968              INTEGER := 0;

  --vVlRubrica090932            NUMBER(13,2) := 0;

BEGIN
  -- xtmpag_util.pGravaLogCallStack;

   vVinc := pRegVinc;

   PInicializaVariaveis(pRegVinc   => vVinc,
                        pDtCalculo => pdtCalculo);

   -- Calcular

   XTMPAG_GERAL.PArmazenaRelacoesVinculo(pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo);
   XTMPAG_GERAL.PTrataBloqueioCredito;

   -- Nao calcula decimo terceiro para quem esta com afastamento sem remuneracao e afastado o mes inteiro
   XTMPAG_VAR.vMotAfast := XTMPAG_CAL.FAfastSemRemun(XTMPAG_VAR.vgVinculo.CdVinculo,
                                                 XTMPAG_VAR.vgFolha.DtInicioMes,
                                                 XTMPAG_VAR.vgFolha.DtFimMes,
                                                 XTMPAG_VAR.vDtCalculo);

   -----------------------------------------------------------------------------------
   -- Se e folha de adiantamento, verifica se ja recebeu pagamento de adiantamento
   -- e o agrupamento nao permite
   -----------------------------------------------------------------------------------

   vVlAdiantamentoPago := 0;


   XTMPAG_VAR.vgLancComplementar := XTMPAG_GERAL.FRubricasLancComplementar(pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                                                           pFolha     => XTMPAG_VAR.vgFolha);

   XTMPAG_TRIBUTACAO.PSetaRurbicasIsentas(pFolha     => XTMPAG_VAR.vgFolha,
                                          pCdVinculo => vVinc.CdVinculo);

   vVlIndice := 0;

   XTMPAG_VAR.vgVlRefTetoDecJud := NULL;

   XTMPAG_VAR.vgCdValRefTetoDecJud := NULL;

   IF XTMPAG_GERAL.FPossuiDecisaoJudicial(pCdVinculo       => XTMPAG_VAR.vgVinculo.CdVinculo,
                                          pNuAnoReferencia => XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                          pNuMesReferencia => XTMPAG_VAR.vgFolha.NuMesReferencia,
                                          pCdRubrica       => XTMPAG_VAR.vgCdRubricaTetoGov,
                                          pVlDecisaoJud    => XTMPAG_VAR.vgVlRefTetoDecJud,
                                          pCdValorRef      => XTMPAG_VAR.vgCdValRefTetoDecJud,
                                          pDtInicioDireito => vDtInicioDireito,
                                          pDtInclusao      => vDtInclusao) THEN

      XTMPAG_VAR.vgVlRefTetoDecJud := XTMPAG_VAR.vgVlRefTetoDecJud;

   END IF;

   -----------------------------------------------------------------------------------------------
   -- Gera totalizadoras e processa formulas de calculo
   -----------------------------------------------------------------------------------------------



      /*XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_VAR.vgCdRubBaseINSS13,
                                 pFlExcluiAmbos => 'S');*/

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_VAR.vgCdRubBaseINSS,
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_var.vgParamPagamento.cdrubagrupdescinss,
                                 pFlExcluiAmbos => 'S');

      /*XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_var.vgParamPagamento.cdrubagrupdescinsssobre13,
                                 pFlExcluiAmbos => 'S');*/

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_var.vgParamPagamento.cdrubagrupdescirrf,
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_var.vgParamPagamento.cdrubagrupdescirrfsobre13,
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_var.vgCdRubBaseIRRF,
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_var.vgCdRubBaseIRRF13,
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento =>  XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSSCLT,
                                      pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento =>  XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                      pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13PatINSS,
                                      pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento =>  XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubricaBaseINSSPat,
                                      pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento =>  XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                      pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_VAR.vgCdRubricaDescDepIRRF,
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_VAR.vgCdRubBaseIRRFOutros,
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_VAR.vgCdRubBaseIRRFFerias,
                                 pFlExcluiAmbos => 'S');

       XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica =>  XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,1021),
                                 pFlExcluiAmbos => 'S');

        XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica =>  XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,1005),
                                 pFlExcluiAmbos => 'S');

      XTMPAG_VAR.vgRecolhimentoAvulso := null;

      begin
         select v.cdregimetrabalho
           into XTMPAG_VAR.vgVinculo.CdRegimeTrabalho
           from ecadvinculo v
          where v.cdvinculo = XTMPAG_VAR.vgVinculo.CdVinculo;

         exception
           when others then
             XTMPAG_VAR.vgVinculo.CdRegimeTrabalho := 1;
      end;

      XTMPAG_VAR.vgDtOpcaoFGTS := XTMPAG_var.vgvinculo.dtadmissao;

      -- Excluir rubricas de pensao
      delete epaghistoricorubricavinculo hv
       where hv.cdhistsentencajudicial is not null
         and hv.cdvinculo = XTMPAG_VAR.vgVinculo.CdVinculo
         and hv.cdfolhapagamento = XTMPAG_VAR.vgFolha.CdFolhapagamento;

      XTMPAG_TRIBUTACAO.PProcessaTributacaoEPensao(pFolha           => XTMPAG_VAR.vgFolha,
                                                   pCdPessoa        => XTMPAG_VAR.vgVinculo.CdPessoa,
                                                   pCdVinculo       => XTMPAG_VAR.vgVinculo.CdVinculo,
                                                   pParamPagamento  => XTMPAG_VAR.vgParamPagamento,
                                                   pDtInicioMes     => XTMPAG_VAR.vgFolha.DtInicioMes,
                                                   pDtFimMes        => XTMPAG_VAR.vgFolha.DtFimMes,
                                                   pbPrima          => TRUE);

   PGeraTotalizadoras(pCalculo          => pCalculo,
                      pCdVinculo        => XTMPAG_VAR.vgVinculo.CdVinculo,
                      pCdFolhaPagamento => vVinc.CdFolhaPagamento);

   XTMPAG_GERAL.PExcluiValoresZerados(pCdVinculo        => XTMPAG_VAR.vgVinculo.CdVinculo,
                                      pCdFolhaPagamento => vVinc.CdFolhaPagamento);

   IF XTMPAG_VAR.vgVlTotalProventos = 0 AND XTMPAG_VAR.vgVlTotalDescontos = 0 THEN

      DELETE
        FROM EpagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
             HRV.CdVinculo = XTMPAG_VAR.vgVinculo.CdVinculo;

      DELETE
        FROM Epagcapahistrubricavinculo HRV
       WHERE HRV.CdFolhaPagamento = vVinc.CdFolhaPagamento AND
             HRV.CdVinculo = XTMPAG_VAR.vgVinculo.CdVinculo;

   END IF;

   update tmppagcalculocoletivo t
      set t.flcalculado = 'R',
          t.dtultalteracao = sysdate
    where t.cdvinculo = XTMPAG_VAR.vgVinculo.CdVinculo
      and t.cdfolhapagamento =  vVinc.CdFolhaPagamento
      and t.flcalculado = 'J';

  << LBL_CONTINUE>> NULL;

END;

PROCEDURE PProcessarCalculoDuploVinculo(pCalculo                   IN XTMPAG_CAL.rCalculo,
                                     pDtCalculo                 IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                                     pFlDefinitivo              IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                                     pLog                       IN BOOLEAN,
                                     pTrace                     IN BOOLEAN,
                                     pCalculoRetorno           OUT XTMPAG_CAL.rCalculoRetorno) IS

   vCdFolhaPagamentoAnt   INTEGER;
   vCdOrgaoAnt            INTEGER;
   vCdPessoaAnt           INTEGER;

   vContador              INTEGER;
   vContadorGeral         INTEGER;

   vNuVinculosVigentes    INTEGER DEFAULT 0;

   vTmIni                 INTEGER;
   vTmTot                 INTEGER;
   vValorInss          number(13,2);
   vValorInssAnt       number(13,2);

   CURSOR cVinc IS
             SELECT CdFolhaPagamento,
             CdOrgaoExercicio as CdOrgaoFolha,
             max(CdOrgaoVinculo) as CdOrgao,
             CdPessoa,
             NuSeqMatricula,
             CdVinculo,
             max(CdSituacaoPrevidenciaria) as CdSituacaoPrevidenciaria,
             max(CdRegimeTrabalho) as CdRegimeTrabalho,
             max(CdRegimePrevidenciario) as CdRegimePrevidenciario,
             max(DtAdmissao) as DtAdmissao,
             max(DtDesligamento) as DtDesligamento,
             max(DtNascimento) as DtNascimento,
             max(DtInclusao) as DtInclusao,
             max(FlSexo) as FlSexo,
             max(CdOpcaoAuxilioAli) as CdOpcaoAuxilioAli,
             max(FlObito) as FlPossuiObito,
             max(FlOutroVincCalculado) as FlOutroVincCalculado,
             max(FlOutroVincACalcular) as FlOutroVincACalcular
        FROM ECalVincFolha
       WHERE CdCalculo = pCalculo.CdCalculo
         and flCalcular = 1 -- cnFlCalcSim
       group by cdfolhapagamento,
                cdorgaoexercicio,
                cdpessoa,
                Nuseqmatricula,
                CdVinculo
       ORDER BY cdfolhapagamento,
                cdorgaoexercicio,
                cdpessoa,
                Nuseqmatricula,
                CdVinculo;


BEGIN
  -- xtmpag_util.pGravaLogCallStack;

--pInsereLogDebug('t', 9, pCalculo.CdCalculo);
--begin

  XTMPAG_VAR.vgFaseCalculo := XTMPAG_TIPO.cnFaseCalculoIntegral;

  XTMPAG_VAR.vgCalculo := pCalculo;

  XTMPAG_VAR.vCdPessoa := NULL;

  XTMPAG_GERAL.PLogProcIni ('0.Calculo total');

  vTmIni := DBMS_UTILITY.get_time;

  -- Inicializa dados Ant

  vCdFolhaPagamentoAnt := 0;
  vCdOrgaoAnt          := 0;
  vCdPessoaAnt         := 0;

  vContadorGeral       := 0;

  pCalculoRetorno.CdMensagem      := 0;



  XTMPAG_VAR.vCdHistParamCalc         := pCalculo.CdHistoricoParamCalculo;
  XTMPAG_VAR.bTrace                   := pTrace;
  XTMPAG_VAR.bLog                     := pLog;

  XTMPAG_var.bProcessandoDuploVinculo := true;

  FOR rVinc IN cVinc

  LOOP

    XTMPAG_GERAL.PLogProcIni ('1.Teste Quebra Folha');

    -- Testa quebra de orgao. Apos finalizar um orgao, realiza as atualizacoes necessarias

    IF rVinc.CdFolhaPagamento <> vCdFolhaPagamentoAnt
       OR rVinc.CdOrgaoFolha <> vCdOrgaoAnt THEN

      -- Processar dados do orgao anterior

      IF vCdOrgaoAnt <> 0 THEN
        XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pQtPessoasCalculadas => vContador);
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

      IF XTMPAG_TAR.FInterromperProcessamento(pCalculo) THEN

        XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pInStatus => 3 );

        RAISE XTMPAG_VAR.eInterrupCalc;

      END IF;

      XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => rVinc.CdOrgaoFolha, pInStatus => 1);

      XTMPAG_GERAL.PLogProcIni ('1-1.Armazena Info Proc');

      XTMPAG_PARAM.PArmazenaInfoProc(rVinc.CdFolhaPagamento,pDtCalculo);

      if XTMPAG_var.vgFolha.CdTipoFolha in (XTMPAG_TIPO.cnTpFolha13, XTMPAG_tipo.cnTpFolhaAdiant13,
                                            XTMPAG_tipo.cnTpFolhaResidente13)  then
         XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pQtPessoasCalculadas => vContador);
         vContador            := 0;
         return;
      end if;

      XTMPAG_GERAL.PLogProcFim ('1-1.Armazena Info Proc');

      if rVinc.cdfolhapagamento != vCdFolhaPagamentoAnt then
        XTMPAG_GERAL.PLogProcIni('1-3. Ins parc faltantes RET/ERA');
        XTMPAG_cal.PInsPagamentoLancFaltantes(rVinc.Cdvinculo, pCalculo, pFlDefinitivo);--, pDtInicioMes);
        XTMPAG_GERAL.PLogProcFim('1-3. Ins parc faltantes RET/ERA');
      end if;

      vCdFolhaPagamentoAnt := rVinc.CdFolhaPagamento;
      vCdOrgaoAnt          := rVinc.CdOrgaoFolha;
      vCdPessoaAnt         := 0; -- Forca quebra de pessoa

    END IF;

    XTMPAG_GERAL.PLogProc ('1.Teste Quebra Folha', '4.Calculo Pessoas');

    -- Testa se Atualiza estatisticas

    vTmTot := DBMS_UTILITY.get_time - vTmIni;
    if vTmTot >= 3000 THEN -- 30 segundos ou 3000 ms

       ------------------------------------------------------------------------------------------------
       -- Atualiza a quantidade de pessoas calculadas do registro de parametros (no orgao e no geral)
       ------------------------------------------------------------------------------------------------

       XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao =>  rVinc.CdOrgaoFolha, pQtPessoasCalculadas => vContador);
       vContador := 0;

       vTmIni := DBMS_UTILITY.get_time;
    END IF;

     -- Testa se quebrou pessoa do vinculo

    IF vCdPessoaAnt <> rVinc.CdPessoa THEN
      vContador      := vContador + 1;
      vContadorGeral := vContadorGeral + 1;

      -- Verifica o numero de vinculos vigentes para saber se
      -- deve efetuar commit (para evitar problemas de calculo do IRRF)

      XTMPAG_GERAL.PLogProcIni ('3.Ver Vigentes');

      vNuVinculosVigentes := XTMPAG_GERAL.FVinculosVigentes(vCdPessoaAnt,
                                                            trunc(pDtCalculo, 'MM'));

      XTMPAG_GERAL.PLogProcFim ('3.Ver Vigentes');

      IF (MOD(vContadorGeral,100) = 0 OR vNuVinculosVigentes > 1) AND pCalculo.FlGeral <> 'I' THEN

        COMMIT;

        IF XTMPAG_TAR.FInterromperProcessamento(pCalculo) THEN

          XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pInStatus => 3 );

          RAISE XTMPAG_VAR.eInterrupCalc;

        END IF;

      END IF;

      vCdPessoaAnt   := rVinc.CdPessoa;

     END IF;
        BEGIN

       vValorInssAnt := XTMPAG_geral.fretornavalorrubrica (
                                     pcdfolhapagamento => rvinc.cdfolhapagamento,
                                     pcdvinculo => rvinc.cdvinculo,
                                     pcdrubrica => XTMPAG_var.vgParamPagamento.CdRubAgrupDescInss);

       XTMPAG_var.bProcessandoDuploVinculo := true;

       PProcessarDuploVinculo (pCalculo                => pCalculo,
                                  pRegVinc                => rVinc,
                                  pDtCalculo              => pDtCalculo);

       XTMPAG_var.bProcessandoDuploVinculo := false;

       vValorInss := XTMPAG_geral.fretornavalorrubrica (
                                     pcdfolhapagamento => rvinc.cdfolhapagamento,
                                     pcdvinculo => rvinc.cdvinculo,
                                     pcdrubrica => XTMPAG_var.vgParamPagamento.CdRubAgrupDescInss);

       XTMPAG_geral.pinserelog(pinsere                  => TRUE,
                          pcdhistoricoparamcalculo => pcalculo.CdHistoricoParamCalculo,
                          pcdpessoa                => rvinc.cdpessoa,
                          pdelog                   =>
                           'Reprocessamento do INSS duplo vínculo. Valor Ant.: '
                            || vValorINSSAnt ||
                            ' - Valor Recalc.: ' || vValorINSS,
                          pcdvinculo               => rvinc.cdvinculo,
                          pcdtipoocorrencia        => 2, -- Ocorrencia
                          pcdmotivoocorrencia      => 25); -- Processamento duplo vinculo


      --atualiza o hr de calculo do calculo de duplo vinculo
      UPDATE epaghistoricorubricavinculo rv
      SET rv.dtultalteracao = systimestamp
      WHERE rv.cdvinculo = rvinc.cdvinculo
      AND rv.cdfolhapagamento = rvinc.cdfolhapagamento;

    -- Tratamento de Exceptions que devem continuar o processamento
    EXCEPTION

      WHEN OTHERS THEN

        pCalculoRetorno.CdMensagem := 1;

        pCalculoRetorno.DeParametros :=  '';

        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                pCalculo.CdHistoricoParamCalculo,
                                rVinc.CdPessoa,
                                '** Alerta: PProcessarCalculo13Salario: ' || SQLERRM,
                                rVinc.CdVinculo);
        -- RAISE; -- Faz com que o erro suba para procedimento chamador e interrompe processamento

    END;

    XTMPAG_GERAL.PLogProcFim ('4.Calculo Pessoas');

  END LOOP;

  XTMPAG_var.bProcessandoDuploVinculo := false;
  -- Processa quebras

  IF vCdOrgaoAnt <> 0 THEN

     XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoAnt, pQtPessoasCalculadas => vContador);
     vContador            := 0;

  END IF;

  IF pCalculo.FlGeral <> 'I' THEN
     COMMIT;
  END IF;

  XTMPAG_GERAL.PLogProcFim ('0.Calculo total');

/*exception
when others then
  pInsereLogDebug('t', 13, sqlerrm);
  null;
end; --*/

---------------------------------------------------------------------------------------------
-- Erro fatal : interrompe a execucao
---------------------------------------------------------------------------------------------

EXCEPTION

  WHEN XTMPAG_VAR.eRubTetoInexistente THEN

    pCalculoRetorno.CdMensagem := 2561;

    pCalculoRetorno.DeParametros :=  '';

  WHEN XTMPAG_VAR.eFolhaEmExecucao THEN

    pCalculoRetorno.CdMensagem := 2649;

    pCalculoRetorno.DeParametros :=  '';

  WHEN XTMPAG_VAR.eDependenciaFormula THEN

   IF pCalculo.CdHistoricoParamCalculo = 0 THEN

     pCalculoRetorno.CdMensagem := 2164;

     pCalculoRetorno.DeParametros :=  '';

   ELSE

     RAISE XTMPAG_VAR.eDependenciaFormula;

   END IF;

  WHEN XTMPAG_VAR.eChaveDuplicada THEN

    IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2164;

      pCalculoRetorno.DeParametros :=  '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Chave duplicada ao executar folha suplementar.',
                              XTMPAG_VAR.vgCdVinculo);

    ELSE

     RAISE XTMPAG_VAR.eChaveDuplicada;

    END IF;

  WHEN XTMPAG_VAR.eSemBaseIRRF THEN

  --  IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2430;

      pCalculoRetorno.DeParametros :=  '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Não foi encontrada a rubrica referente à base do IRRF. Folha não calculada.',
                              XTMPAG_VAR.vgCdVinculo);

  --  ELSE

  --    RAISE XTMPAG_VAR.eSemBaseIRRF;

  --  END IF;

  WHEN XTMPAG_VAR.eSemBaseIRRFFerias THEN

  --  IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2431;

      pCalculoRetorno.DeParametros :=  '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Não foi encontrada a rubrica referente à base do IRRF de férias. Folha não calculada.',
                              XTMPAG_VAR.vgCdVinculo);

   --  ELSE

       RAISE XTMPAG_VAR.eSemBaseIRRFFerias;

   --  END IF;

  WHEN XTMPAG_VAR.eSemBaseIRRF13 THEN

  -- IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2432;

      pCalculoRetorno.DeParametros :=  '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Não foi encontrada a rubrica referente à base do IRRF de 13º. Folha não calculada.',
                              XTMPAG_VAR.vgCdVinculo);

   -- ELSE

   --   RAISE XTMPAG_VAR.eSemBaseIRRF13;

   -- END IF;

  WHEN XTMPAG_VAR.eNaoRodaFolhaNormal THEN

    IF pCalculo.CdHistoricoParamCalculo = 0 THEN

      pCalculoRetorno.CdMensagem := 2471;

      pCalculoRetorno.DeParametros :=  '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Não é permitido executar folha normal/calculo normal temporariamente.',
                              XTMPAG_VAR.vgCdVinculo);

    END IF;

  WHEN OTHERS THEN

    pCalculoRetorno.CdMensagem := 1;

    pCalculoRetorno.DeParametros :=  '';

    XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                            pCalculo.CdHistoricoParamCalculo,
                            XTMPAG_VAR.vCdPessoa,
                            SQLERRM,
                            XTMPAG_VAR.vgCdVinculo);

END;

PROCEDURE PProcessarCalculoDuploVinculo (pCdJobId IN VARCHAR2, pCdCalculo  IN INTEGER) IS

   vCalculo                   XTMPAG_CAL.rCalculo;
   vDtCalculo                 EPagHistoricoParamCalculo.DtCalculo%TYPE;
   vCdTipoCalculo             EPagHistoricoParamCalculo.CdTipoCalculo%TYPE;
   vFlDefinitivo              EPagHistoricoParamCalculo.FlDefinitivo%TYPE;
   vLog                       CHAR(1);
   vTrace                     CHAR(1);
   vLogb                      BOOLEAN;
   vTraceb                    BOOLEAN;
   vCalculoRetorno            XTMPAG_CAL.rCalculoRetorno;

BEGIN
  -- xtmpag_util.pGravaLogCallStack;

--pInsereLogDebug('t', 9, pCdCalculo);

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

     XTMPAG_var.bProcessandoDuploVinculo := true;

     PProcessarCalculoDuploVinculo (vCalculo,
                                 vDtCalculo,
                                 vFlDefinitivo,
                                 vLogb,
                                 vTraceb,
                                 vCalculoRetorno);

    XTMPAG_var.bProcessandoDuploVinculo := false;

   EXCEPTION

      WHEN OTHERS THEN

        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                vCalculo.CdHistoricoParamCalculo,
                                XTMPAG_VAR.vCdPessoa,
                                '** Erro (PProcessar13Salario-Paralelo): ' || SQLERRM,
                                XTMPAG_VAR.vgCdVinculo);

   END;

   XTMPAG_TAR.PFinalizarJob (pCdJobId,vCalculoRetorno.DeParametros);

/*exception
when others then
  pInsereLogDebug('t', 10, sqlerrm);
  null; --*/
 END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Processamento do Vinculo - Parte Suplementar
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarVincCalcSupl(rVinculo             IN XTMPAG_TIPO.rVinculo,
                                   pVlDiferencaValor    IN NUMBER,
                                   pFlCalculoDefinitivo IN CHAR) IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_GERAL.PLogProcIni('4-3-1.Folha Sup');

    XTMPAG_VAR.vgFaseCalculo := XTMPAG_TIPO.cnFaseCalculoSuplementar;

    XTMPAG_VAR.vgVinculo := rVinculo;

    XTMPAG_VAR.vgFolhaOrigem := XTMPAG_VAR.vgFolhaOrigemAux;

    PProcessaFolhaSuplementar(XTMPAG_VAR.vgFolha,
                              XTMPAG_VAR.vgFolhaOrigem,
                              XTMPAG_VAR.vgFolhaRecalculo,
                              rVinculo.CdVinculo,
                              pFlCalculoDefinitivo,
                              pVlDiferencaValor,
                              rVinculo.CdFolhaPagamentoNormal);

    XTMPAG_GERAL.PLogProcFim('4-3-1.Folha Sup');

    PProcessarVincCalcErario(rVinculo             => rVinculo,
                             pFlCalculoDefinitivo => pFlCalculoDefinitivo);

  END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Chamado pelo Calculo Individual

                Procedure principal para execucao da folha de pagamento

          Nota: Sao selecionados os vinculos da pessoa para o orgao da folha passada
                como parametro, desde que este nao possua relacao de vinculo de CCO
                com orgao exercicio diferente do orgao da folha. Seleciona tambem, os
                vinculos que possuem uma relacao de vinculo de CCO com o mesmo orgao
                de processamento da folha.
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarVinculoNormal(pCalculo             IN rCalculo,
                                    pRegVinc             IN rVinc,
                                    pDtCalculo           IN DATE,
                                    pVlDiferencaValor    IN NUMBER,
                                    pFlCalculoDefinitivo IN CHAR,
                                    pFlPagaAdiantamento  IN CHAR) IS

    rVinculo XTMPAG_TIPO.rVinculo;

    ---- INICIO DO CaLCULO DA FOLHA APoS ARMAZRNAMENTO DE INFORMAcoES DO ViNCULO ----

  BEGIN
    XTMPAG_util.pAtivaLogCallStack;
    -- xtmpag_util.pGravaLogCallStack(pRegVinc.CdVinculo);
    XTMPAG_util.pAtivaLogHRV;

    -- Preenche formato antigo do registro do SQL

--pInsereLogDebug('t', 3, pCalculo.CdCalculo, pRegVinc.CdVinculo, null, null, null, null, null, null, null, null, 0);

    rVinculo.CdVinculo                := pRegVinc.CdVinculo;
    rVinculo.CdPessoa                 := pRegVinc.CdPessoa;
    rVinculo.NuSeqMatricula           := pRegVinc.NuSeqMatricula;
    rVinculo.CdOrgao                  := pRegVinc.CdOrgao;
    rVinculo.CdSituacaoPrevidenciaria := pRegVinc.CdSituacaoPrevidenciaria;
    rVinculo.CdRegimeTrabalho         := pRegVinc.CdRegimeTrabalho;
    rVinculo.CdRegimePrevidenciario   := pRegVinc.CdRegimePrevidenciario;
    rVinculo.DtAdmissao               := pRegVinc.DtAdmissao;
    IF XTMPAG_var.vgFolha.cdtipofolha <> XTMPAG_TIPO.cnTpFolhaInstPensao THEN
      rVinculo.DtDesligamento           := pRegVinc.DtDesligamento;
    END IF;
    rVinculo.DtNascimento             := pRegVinc.DtNascimento;
    rVinculo.DtInclusao               := pRegVinc.DtInclusao;
    rVinculo.FlSexo                   := pRegVinc.FlSexo;
    rVinculo.CdOpcaoAuxilioAli        := pRegVinc.CdOpcaoAuxilioAli;
    rVinculo.FlOutroVincCalculado     := pRegVinc.FlOutroVincCalculado;
    rVinculo.FlOutroVincACalcular     := pRegVinc.FlOutroVincACalcular;
    rVinculo.CdFolhaPagamentoNormal   := XTMPAG_GERAL.FCodigoFolhaNormalVinc(pCdVinculo => rVinculo.CdVinculo,
                                                                             pFolha     => XTMPAG_VAR.vgFolha);

    rVinculo.bPossuiObito := CASE
                               WHEN pRegVinc.FlPossuiObito = 1 AND
                                    XTMPAG_var.vgFolha.cdtipofolha <> XTMPAG_TIPO.cnTpFolhaInstPensao THEN
                                TRUE
                               ELSE
                                FALSE
                             END;

    rVinculo.FlPagamentoBloqueado := 'N';

    if rVinculo.CdOrgao = 2
        and rVinculo.CdOrgao <> XTMPAG_var.vgFolha.CdOrgao
        and XTMPAG_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766) then

         return;

    end if;

 /*  if rVinculo.CdPessoa = 61438
      and rVinculo.CdOrgao = 28  then
      return;
   end if;
    */

    PInicializaVariaveis(pVinculo => rVinculo, pDtCalculo => pdtCalculo);

    -------------------------------------------------------------
    -- Busca informacoes dos dados bancarios, opcao de FGTS
    -------------------------------------------------------------

    XTMPAG_GERAL.PSetaDadosBancarios(rVinculo.CdVinculo,
                                     XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                     XTMPAG_VAR.vgFolha.NuMesReferencia,
                                     pDtCalculo);

    XTMPAG_GERAL.PLogProcIni('4-2.Exc. Calc Ant');

    -- Caso Nao seja um calculo geral, exclui os registros de pagamento da folha

    IF pCalculo.FlGeral in ('I', 'N') THEN

      IF XTMPAG_VAR.vgFolhaOrigem.CdTipoCalculo IN (7, 8, 9) THEN

        XTMPAG_GERAL.PExcluirPagVinc(XTMPAG_VAR.vgFolhaOrigem.CdFolhaPagamento,
                                     rVinculo.CdVinculo);

      END IF;

      XTMPAG_GERAL.PExcluirPagVinc(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                   rVinculo.CdVinculo);

    END IF;

    XTMPAG_GERAL.PLogProc('4-2.Exc. Calc Ant', '4-3.Calculao');

    CASE

    /*----------------------------------------------------------------------------*/
    -- Fluxo para tipo de calculo NORMAL/RECALCULO/SIMULACAO/CALCULO RETROATIVO
    /*----------------------------------------------------------------------------*/

      WHEN XTMPAG_VAR.vgFolha.CdTipoCalculo IN
           (XTMPAG_TIPO.cnTpCalculoNormal,
            XTMPAG_TIPO.cnTpCalculoRecalculoMes,
            XTMPAG_TIPO.cnTpCalculoRecalcCompl,
            XTMPAG_TIPO.cnTpCalculoSimulacao)
      THEN

        PProcessarVincCalcIntegral(pCalculo             => pCalculo,
                                   rVinculo             => rVinculo,
                                   pDtCalculo           => pDtCalculo,
                                   pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                   pFlPagaAdiantamento  => pFlPagaAdiantamento);

    -----------------------------------------------------------------------------
    -- Fluxo para tipo de calculo SUPLEMENTAR
    -----------------------------------------------------------------------------

      WHEN XTMPAG_VAR.vgFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoSupl THEN

        PProcessarVincCalcSupl(rVinculo             => rVinculo,
                               pVlDiferencaValor    => pVlDiferencaValor,
                               pFlCalculoDefinitivo => pFlCalculoDefinitivo);

    -----------------------------------------------------------------------------
    -- Fluxo para tipo de calculo NORMAL e SUPLEMENTAR
    -----------------------------------------------------------------------------
     /*Gerar apenas para ACTs: foi utilizado o regime pois essa folha é aberta apenas para Educação*/
      WHEN XTMPAG_VAR.vgFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoDifMes AND 
           rVinculo.CdRegimePrevidenciario = XTMPAG_TIPO.cnRegPrevGeral THEN 

        PProcessarVincCalcIntegral(pCalculo             => pCalculo,
                                   rVinculo             => rVinculo,
                                   pDtCalculo           => pDtCalculo,
                                   pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                   pFlPagaAdiantamento  => pFlPagaAdiantamento);

        PProcessarVincCalcSupl(rVinculo             => rVinculo,
                               pVlDiferencaValor    => pVlDiferencaValor,
                               pFlCalculoDefinitivo => pFlCalculoDefinitivo);

    else
      null;
    END CASE;

    IF pRegVinc.CdRegimePrevidenciario <> XTMPAG_TIPO.cnRegPrevGeral THEN
      PExcluirRubricasCLT(pCdVinculo => rVinculo.Cdvinculo,
                          pCdFolhaPagamento => XTMPAG_VAR.vgFolha.Cdfolhapagamento,
                          pCdAgrupamento => XTMPAG_VAR.vgFolha.cdAgrupamento);
    END IF;

    XTMPAG_GERAL.PLogProcFim('4-3.Calculao');
--pInsereLogDebug('t', 4, pCalculo.CdCalculo, pRegVinc.CdVinculo, null, null, null, null, null, null, null, null, 0);

    XTMPAG_util.pDesativaLogHRV;
    XTMPAG_util.pDesativaLogCallStack;

  END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Procedure de execucao da folha Mensal Normal (nao de 13o Salario)
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarCalculoNormal(pCalculo                 IN rCalculo,
                                    pDtCalculo               IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                                    pFlDefinitivo            IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                                    pFlPagaAdiantamento13sal IN EPagHistoricoParamCalculo.FlPagaAdiantamento13sal%TYPE,
                                    pVlDiferencaValor        IN EPagHistoricoParamcalculo.vlDiferencaValor%TYPE,
                                    pLog                     IN BOOLEAN,
                                    pTrace                   IN BOOLEAN,
                                    pCalculoRetorno          OUT rCalculoRetorno,
                                    pParalelo                in char default null) IS

    vCdFolhaPagamentoAnt INTEGER;
    vCdOrgaoAnt          INTEGER;
    vCdPessoaAnt         INTEGER;

    vContador      INTEGER;
    vContadorGeral INTEGER;

    vNuVinculosVigentes INTEGER DEFAULT 0;

    vTmIni INTEGER;
    vTmTot INTEGER;

    CURSOR cVinc IS
      SELECT CdFolhaPagamento,
             CdOrgaoExercicio as CdOrgaoFolha,
             max(CdOrgaoVinculo) as CdOrgao,
             CdPessoa,
             NuSeqMatricula,
             CdVinculo,
             max(CdSituacaoPrevidenciaria) as CdSituacaoPrevidenciaria,
             max(CdRegimeTrabalho) as CdRegimeTrabalho,
             max(CdRegimePrevidenciario) as CdRegimePrevidenciario,
             max(DtAdmissao) as DtAdmissao,
             max(DtDesligamento) as DtDesligamento,
             max(DtNascimento) as DtNascimento,
             max(DtInclusao) as DtInclusao,
             max(FlSexo) as FlSexo,
             max(CdOpcaoAuxilioAli) as CdOpcaoAuxilioAli,
             max(FlObito) as FlPossuiObito,
             max(FlOutroVincCalculado) as FlOutroVincCalculado,
             max(FlOutroVincACalcular) as FlOutroVincACalcular
        FROM ECalVincFolha
       WHERE CdCalculo = pCalculo.CdCalculo
         and flCalcular = 1 -- cnFlCalcSim
       group by cdfolhapagamento,
                cdorgaoexercicio,
                cdpessoa,
                Nuseqmatricula,
                CdVinculo
       ORDER BY cdfolhapagamento,
                cdorgaoexercicio,
                cdpessoa,
                Nuseqmatricula,
                CdVinculo;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

--pInsereLogDebug('t', 5, pCalculo.CdCalculo);

--begin
    XTMPAG_VAR.vgCalculo := pCalculo;

    XTMPAG_VAR.vCdPessoa := NULL;

    XTMPAG_GERAL.PLogProcIni('0.Calculo total');

    -- seta Timer de inicio do calculo da folha ( diferenca de valores / 100 = segundos de duracao)

    vTmIni := DBMS_UTILITY.get_time;

    -- Inicializa dados Ant

    vCdFolhaPagamentoAnt := 0;
    vCdOrgaoAnt          := 0;
    vCdPessoaAnt         := 0;

    vContadorGeral := 0;

    /* insert into Epagrelatorio(Cdtpgeracao, deRel) values (2121, vsql);
    commit;*/

    pCalculoRetorno.CdMensagem := 0;

    XTMPAG_VAR.vCdHistParamCalc := pCalculo.CdHistoricoParamCalculo;
    XTMPAG_VAR.bTrace           := pTrace;
    XTMPAG_VAR.bLog             := pLog;

    FOR rVinc IN cVinc

     LOOP

      XTMPAG_GERAL.PLogProcIni('1.Teste Quebra Folha');

      -- Testa quebra de orgao. Apos finalizar um orgao, realiza as atualizacoes necessarias

      IF rVinc.CdFolhaPagamento <> vCdFolhaPagamentoAnt OR
         rVinc.CdOrgaoFolha <> vCdOrgaoAnt THEN

        XTMPAG_GERAL.PLogProcIni('1-1. Atualiza Parm Execucao');

        -- Processar dados do orgao anterior

        IF vCdOrgaoAnt <> 0 THEN
          XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo             => pCalculo,
                                                pCdOrgao             => vCdOrgaoAnt,
                                                pQtPessoasCalculadas => vContador);
        END IF;

        if pCalculo.FlGeral <> 'I' or pParalelo = 'S' THEN
          -- nao pode comitar na individual, da erro na transacao
          COMMIT;
        END IF;

        vContador := 0;

        -- Inicializar novo orgao

        -------------------------------------------------------------------------------------------
        -- Caso esteja iniciando o processamento de um orgao, atualiza o status do registro de
        -- parametros do orgao para "Em Andamento".
        -------------------------------------------------------------------------------------------

        IF XTMPAG_TAR.FInterromperProcessamento(pCalculo) THEN

          XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo  => pCalculo,
                                                pCdOrgao  => vCdOrgaoAnt,
                                                pInStatus => 3);

          RAISE XTMPAG_VAR.eInterrupCalc;

        END IF;

        XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo  => pCalculo,
                                              pCdOrgao  => rVinc.CdOrgaoFolha,
                                              pInStatus => 1);

        XTMPAG_GERAL.PLogProc('1-1. Atualiza Parm Execucao',
                              '1-2.Armazena Info Proc');

        XTMPAG_PARAM.PArmazenaInfoProc(rVinc.CdFolhaPagamento, pDtCalculo, rVinc.cdOrgao);

        vgTabCdFolhaPagamentoDifMes := FOBtemFolhaDifMes(pFolha => XTMPAG_VAR.vgFolha);

        XTMPAG_GERAL.PLogProcFim('1-2.Armazena Info Proc');

        if rVinc.cdfolhapagamento != vCdFolhaPagamentoAnt then
          XTMPAG_GERAL.PLogProcIni('1-3. Ins parc faltantes RET/ERA');
          PInsPagamentoLancFaltantes(rvinc.cdvinculo, pCalculo,  NVL(pFlDefinitivo, 'N'));--, pDtInicioMes);
          XTMPAG_GERAL.PLogProcFim('1-3. Ins parc faltantes RET/ERA');
        end if;

        vCdFolhaPagamentoAnt := rVinc.CdFolhaPagamento;
        vCdOrgaoAnt          := rVinc.CdOrgaoFolha;
        vCdPessoaAnt         := 0; -- Forca quebra de pessoa
      END IF;

      XTMPAG_GERAL.PLogProc('1.Teste Quebra Folha', '4.Calculo Pessoas');

      -- Testa se Atualiza estatisticas

      vTmTot := DBMS_UTILITY.get_time - vTmIni;
      if vTmTot >= 3000 THEN
        -- 30 segundos ou 3000 ms

        ------------------------------------------------------------------------------------------------
        -- Atualiza a quantidade de pessoas calculadas do registro de parametros (no orgao e no geral)
        ------------------------------------------------------------------------------------------------

        XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo             => pCalculo,
                                              pCdOrgao             => rVinc.CdOrgaoFolha,
                                              pQtPessoasCalculadas => vContador);
        vContador := 0;

        vTmIni := DBMS_UTILITY.get_time;
      END IF;

      -- Testa se quebrou pessoa do vinculo

      IF vCdPessoaAnt <> rVinc.CdPessoa THEN
        vContador      := vContador + 1;
        vContadorGeral := vContadorGeral + 1;

        -- Verifica o numero de vinculos vigentes para saber se
        -- deve efetuar commit (para evitar problemas de calculo do IRRF)

        XTMPAG_GERAL.PLogProcIni('4-1.Ver Vigentes');

        vNuVinculosVigentes := XTMPAG_GERAL.FVinculosVigentes(vCdPessoaAnt,
                                                              trunc(pDtCalculo,
                                                                    'MM'));

        XTMPAG_GERAL.PLogProcFim('4-1.Ver Vigentes');

        IF (MOD(vContadorGeral, 100) = 0 OR vNuVinculosVigentes > 1) AND
           pCalculo.FlGeral <> 'I' THEN

          COMMIT;

          IF XTMPAG_TAR.FInterromperProcessamento(pCalculo) THEN

            XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo  => pCalculo,
                                                  pCdOrgao  => vCdOrgaoAnt,
                                                  pInStatus => 3);

            RAISE XTMPAG_VAR.eInterrupCalc;

          END IF;

        END IF;

        vCdPessoaAnt := rVinc.CdPessoa;

      END IF;

      BEGIN

        PProcessarVinculoNormal(pCalculo             => pCalculo,
                                pRegVinc             => rVinc,
                                pDtCalculo           => pDtCalculo,
                                pVlDiferencaValor    => pVlDiferencaValor,
                                pFlCalculoDefinitivo => pFlDefinitivo,
                                pFlPagaAdiantamento  => pFlPagaAdiantamento13sal);

        -- Tratamento de Exceptions que devem continuar o processamento
      EXCEPTION

        WHEN XTMPAG_VAR.eNaoRodaFolhaNormal THEN

          RAISE XTMPAG_VAR.eNaoRodaFolhaNormal;

        WHEN XTMPAG_VAR.eRubTetoInexistente THEN

          RAISE XTMPAG_VAR.eRubTetoInexistente;

        WHEN XTMPAG_VAR.eFolhaEmExecucao THEN

          RAISE XTMPAG_VAR.eFolhaEmExecucao;

        WHEN XTMPAG_VAR.eDependenciaFormula THEN

          RAISE XTMPAG_VAR.eDependenciaFormula;

        WHEN XTMPAG_VAR.eChaveDuplicada THEN

          RAISE XTMPAG_VAR.eChaveDuplicada;

        WHEN XTMPAG_VAR.eSemBaseIRRF THEN

          RAISE XTMPAG_VAR.eSemBaseIRRF;

        WHEN XTMPAG_VAR.eSemBaseIRRFFerias THEN

          RAISE XTMPAG_VAR.eSemBaseIRRFFerias;

        WHEN XTMPAG_VAR.eSemBaseIRRF13 THEN

          RAISE XTMPAG_VAR.eSemBaseIRRF13;

        WHEN OTHERS THEN

          pCalculoRetorno.CdMensagem := 1;

          pCalculoRetorno.DeParametros := '';

          XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  rVinc.CdPessoa,
                                  '** Alerta: PProcessarCalculoNormal: ' ||
                                  SQLERRM,
                                  rVinc.CdVinculo);
          -- RAISE; -- Faz com que o erro suba para procedimento chamador e interrompe processamento

        IF XTMPAG_VAR.vgFolha.cdtipofolha in (XTMPAG_tipo.cnTpFolhaServAfast) THEN
          UPDATE eafaafastamentovinculo Afa
             SET Afa.Flanulado = XTMPAG_TIPO.cnN
           WHERE Afa.Cdafastamento in (select a.cdafastamento
                                         from epaghistfolhaservafast a
                                        where a.cdfolhapagamento = XTMPAG_var.vgFolha.cdFolhaPagamento
                                          and a.cdvinculo = rVinc.CdVinculo);
          delete epaghistfolhaservafast a
           where a.cdfolhapagamento = XTMPAG_var.vgFolha.cdFolhaPagamento
             and a.cdvinculo = rVinc.CdVinculo;
        END IF;

      END;


      XTMPAG_GERAL.PLogProcFim('4.Calculo Pessoas');

    END LOOP;

    -- Processa quebras

    IF vCdOrgaoAnt <> 0 THEN

      XTMPAG_TAR.PAtualizaParametroExecucao(pCalculo             => pCalculo,
                                            pCdOrgao             => vCdOrgaoAnt,
                                            pQtPessoasCalculadas => vContador);
      vContador := 0;

    END IF;

    XTMPAG_GERAL.PLogProcFim('0.Calculo total');

    IF pCalculo.FlGeral <> 'I' or pParalelo = 'S' THEN
      COMMIT;
    END IF;

/*exception
when others then
  pInsereLogDebug('t', 11, sqlerrm);
  null;
end; --*/

    ---------------------------------------------------------------------------------------------
    -- Erro fatal : interrompe a execucao
    ---------------------------------------------------------------------------------------------
--pInsereLogDebug('t', 6, pCalculo.CdCalculo);

  EXCEPTION

    WHEN XTMPAG_VAR.eNaoRodaFolhaNormal THEN

      pCalculoRetorno.CdMensagem := 2471;

      pCalculoRetorno.DeParametros := '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Nao e permitido executar folha normal/calculo normal para orgao nao implantado.',
                              XTMPAG_VAR.vgCdVinculo);

    WHEN XTMPAG_VAR.eRubTetoInexistente THEN

      pCalculoRetorno.CdMensagem := 2561;

      pCalculoRetorno.DeParametros := '';

    WHEN XTMPAG_VAR.eFolhaEmExecucao THEN

      pCalculoRetorno.CdMensagem := 2649;

      pCalculoRetorno.DeParametros := '';

    WHEN XTMPAG_VAR.eDependenciaFormula THEN

      pCalculoRetorno.CdMensagem := 2164;

      pCalculoRetorno.DeParametros := '';

    WHEN XTMPAG_VAR.eChaveDuplicada THEN

      pCalculoRetorno.CdMensagem := 2164;

      pCalculoRetorno.DeParametros := '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Chave duplicada ao executar folha suplementar.',
                              XTMPAG_VAR.vgCdVinculo);

    WHEN XTMPAG_VAR.eSemBaseIRRF THEN

      pCalculoRetorno.CdMensagem := 2430;

      pCalculoRetorno.DeParametros := '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Nao foi encontrada a rubrica referente a base do IRRF. Folha nao calculada.',
                              XTMPAG_VAR.vgCdVinculo);

    WHEN XTMPAG_VAR.eSemBaseIRRFFerias THEN

      pCalculoRetorno.CdMensagem := 2431;

      pCalculoRetorno.DeParametros := '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Nao foi encontrada a rubrica referente a base do IRRF de ferias. Folha nao calculada.',
                              XTMPAG_VAR.vgCdVinculo);

    WHEN XTMPAG_VAR.eSemBaseIRRF13 THEN

      pCalculoRetorno.CdMensagem := 2432;

      pCalculoRetorno.DeParametros := '';

      XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              XTMPAG_VAR.vCdPessoa,
                              'Nao foi encontrada a rubrica referente a base do IRRF de 13o. Folha nao calculada.',
                              XTMPAG_VAR.vgCdVinculo);

     WHEN OTHERS THEN

        IF XTMPAG_VAR.vgFolha.cdtipofolha in (XTMPAG_tipo.cnTpFolhaServAfast) THEN
          UPDATE eafaafastamentovinculo Afa
             SET Afa.Flanulado = XTMPAG_TIPO.cnN
           WHERE Afa.Cdafastamento in (select a.cdafastamento
                                         from epaghistfolhaservafast a
                                        where a.cdfolhapagamento = XTMPAG_var.vgFolha.cdFolhaPagamento
                                          and a.cdvinculo = XTMPAG_VAR.vgCdVinculo);
          delete epaghistfolhaservafast a
           where a.cdfolhapagamento = XTMPAG_var.vgFolha.cdFolhaPagamento
             and a.cdvinculo = XTMPAG_VAR.vgCdVinculo;
        END IF;

  END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Procedure de execucao da folha Mensal Normal via JOB
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarCalculoNormal(pCdJobId   IN VARCHAR2,
                                    pCdCalculo IN INTEGER) IS

    vCalculo                 rCalculo;
    vDtCalculo               EPagHistoricoParamCalculo.DtCalculo%TYPE;
    vCdTipoCalculo           EPagHistoricoParamCalculo.CdTipoCalculo%TYPE;
    vFlDefinitivo            EPagHistoricoParamCalculo.FlDefinitivo%TYPE;
    vFlPagaAdiantamento13sal EPagHistoricoParamCalculo.FlPagaAdiantamento13sal%TYPE;
    vVlDiferencaValor        EPagHistoricoParamcalculo.vlDiferencaValor%TYPE;
    vLog                     CHAR(1);
    vTrace                   CHAR(1);
    vLogb                    BOOLEAN;
    vTraceb                  BOOLEAN;
    vCalculoRetorno          rCalculoRetorno;

  BEGIN
    XTMPAG_util.pInicializaLogCallStack;
    -- xtmpag_util.pGravaLogCallStack;

--pInsereLogDebug('t', 7, pCdCalculo, pCdJobId);

    XTMPAG_GERAL.PIniciarLogProc;

    SELECT CdCalculo,
           CdCalculoPai,
           CdTarefa,
           CdHistoricoParamCalculo,
           FlGeral,
           InTipoExecucao,
           DtCalculo,
           CdTipoCalculo,
           FlDefinitivo,
           FlPagaAdiantamento13Sal,
           VlDiferencaValor,
           FlLog,
           FlTrace
      into vCalculo.CdCalculo,
           vCalculo.CdCalculoPai,
           vCalculo.CdTarefa,
           vCalculo.CdHistoricoParamCalculo,
           vCalculo.FlGeral,
           vCalculo.InTipoExecucao,
           vDtCalculo,
           vCdTipoCalculo,
           vFlDefinitivo,
           vFlPagaAdiantamento13sal,
           vVlDiferencaValor,
           vLog,
           vTrace
      from ECalCalculo
     where cdCalculo = pCdCalculo;

    vLogb   := FALSE;
    vTraceb := FALSE;
    if vLog = 'S' then
      vLogb := true;
    end if;

    if vTrace = 'S' then
      vTraceb := true;
    end if;

    BEGIN

      PProcessarCalculoNormal(vCalculo,
                              vDtCalculo,
                              vFlDefinitivo,
                              vFlPagaAdiantamento13sal,
                              vVlDiferencaValor,
                              vLogb,
                              vTraceb,
                              vCalculoRetorno);

    EXCEPTION

      WHEN OTHERS THEN

        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                vCalculo.CdHistoricoParamCalculo,
                                XTMPAG_VAR.vCdPessoa,
                                '** Erro (PProcessarCalculoNormal-Paralelo): ' ||
                                SQLERRM,
                                XTMPAG_VAR.vgCdVinculo);

    END;

    XTMPAG_TAR.PFinalizarJob(pCdJobId, vCalculoRetorno.DeParametros);

    XTMPAG_GERAL.PFinalizarLogProc(pCalculo => vCalculo);

--pInsereLogDebug('t', 8, pCdCalculo, pCdJobId);
  EXCEPTION

    WHEN OTHERS THEN
      --pInsereLogDebug('t', 12, sqlerrm);
      null; -- Erro nao conseguiu ser tratado
  END;

 PROCEDURE PINSPAGAMENTOLANCFALTANTES(PCDVINCULO    IN INTEGER,
                                      PCALCULO      IN RCALCULO,
                                      PFLDEFINITIVO IN EPAGHISTORICOPARAMCALCULO.FLDEFINITIVO%TYPE DEFAULT 'N') IS

   /*---------------------------------------
     procedure para inserção de pagamentos de lançamentos financeiros de meses anteriores
     para retroativo [RET (12)], erário [ERA (11)]
   ---------------------------------------*/

   VVLTOTAL         NUMBER;
   VDTFIMMESANT     DATE;
   VMSG             VARCHAR(1000);
   VPROCESSO        VARCHAR(30);
   VFOLHA           XTMPAG_TIPO.RFOLHA;
   VNUMESREFERENCIA CHAR(2);
   VNURUBRICA       VARCHAR2(7);
   VNUPARCELA       INTEGER;

 BEGIN
   -- xtmpag_util.pGravaLogCallStack;

   VDTFIMMESANT           := XTMPAG_VAR.VGFOLHA.DTINICIOMES - 1;
   VFOLHA.NUANOREFERENCIA := TO_NUMBER(TO_CHAR(VDTFIMMESANT, 'YYYY'));
   VFOLHA.NUMESREFERENCIA := TO_NUMBER(TO_CHAR(VDTFIMMESANT, 'MM'));
   VNUMESREFERENCIA       := LPAD(VFOLHA.NUMESREFERENCIA, 2, '0');

   FOR LANC IN (SELECT DISTINCT HRV.CDVINCULO,
                                HRV.VLPAGAMENTO,
                                HRV.CDTIPOORIGEMRUBRICA,
                                HRV.QTPARCELAS,
                                HRV.CDRUBRICAAGRUPAMENTO,
                                FP.NUANOREFERENCIA,
                                FP.NUMESREFERENCIA,
                                LF.CDLANCAMENTOFINANCEIRO,
                                LF.VLLANCAMENTOFINANCEIRO,
                                LF.CDPROCESSOPAGRETROATIVO,
                                LF.CDPROCESSORESTITUICAOERARIO,
                                LF.INPERIODICIDADE,
                                LF.NUPARCELAS,
                                LF.FLOBSERVALIMRETROATIVOERARIO,
                                V.CDPESSOA,
                                RT.CDSITUACAOPROCESSO
                  FROM EPAGHISTORICORUBRICAVINCULO HRV -- CONTRA-CHEQUE
                 INNER JOIN EPAGFOLHAPAGAMENTO FP
                    ON FP.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO

                 INNER JOIN EPAGLANCAMENTOFINANCEIRO LF
                    ON HRV.CDLANCAMENTOFINANCEIRO =
                       LF.CDLANCAMENTOFINANCEIRO
                   AND LF.NUPARCELAS > 0
                  LEFT JOIN ERETPROCESSOPAGRETROATIVO RT
                    ON RT.CDPROCESSOPAGRETROATIVO =
                       LF.CDPROCESSOPAGRETROATIVO
                 INNER JOIN ECADVINCULO V
                    ON V.CDVINCULO = HRV.CDVINCULO

                 WHERE HRV.CDVINCULO = PCDVINCULO
                   AND (HRV.CDLANCAMENTOFINANCEIRO IS NOT NULL AND
                       HRV.CDLANCAMENTOFINANCEIRO =
                       LF.CDLANCAMENTOFINANCEIRO)
                   AND LF.CDLANCAMENTOFINANCEIRO NOT IN
                       (SELECT PL.CDLANCAMENTOFINANCEIRO
                          FROM EPAGPAGAMENTOLANCAMENTO PL
                         WHERE PL.CDLANCAMENTOFINANCEIRO =
                               LF.CDLANCAMENTOFINANCEIRO
                           AND PL.NUANOREFERENCIA = FP.NUANOREFERENCIA
                           AND PL.NUMESREFERENCIA = FP.NUMESREFERENCIA)
                   AND FP.FLCALCULODEFINITIVO = 'S'
                   AND FP.NUANOREFERENCIA = VFOLHA.NUANOREFERENCIA
                   AND FP.NUMESREFERENCIA = VFOLHA.NUMESREFERENCIA
                   AND (LF.DTFIMDIREITO IS NULL OR
                       LF.DTFIMDIREITO >= VFOLHA.DTINICIOMES)) LOOP

     VMSG := '';

     IF PFLDEFINITIVO = 'S'
       THEN

     IF LANC.CDSITUACAOPROCESSO = 2 --PROCESSO ATIVO
        AND LANC.CDTIPOORIGEMRUBRICA IN (11, 12) THEN
       --11  erario
       --12  retroativo

       IF LANC.CDTIPOORIGEMRUBRICA = 11 THEN
         VPROCESSO := 'processo retroativo erario';
       ELSIF LANC.CDTIPOORIGEMRUBRICA = 12 THEN
         VPROCESSO := 'processo retroativo';
       END IF;

       IF LANC.CDLANCAMENTOFINANCEIRO IS NULL THEN
         VMSG := 'O lançamento financeiro registrado no contracheque nao existe ou foi excluído. Ref. ' ||
                 VPROCESSO;
       ELSE

         SELECT SUM(PL.VLPARCELA)
           INTO VVLTOTAL
           FROM EPAGPAGAMENTOLANCAMENTO PL
          WHERE PL.CDLANCAMENTOFINANCEIRO = LANC.CDLANCAMENTOFINANCEIRO;
         VVLTOTAL := NVL(VVLTOTAL, 0) + LANC.VLPAGAMENTO;

         IF VVLTOTAL > LANC.VLLANCAMENTOFINANCEIRO THEN
           VMSG := 'Ao tentar registrar parcela faltante de ' || VPROCESSO ||
                   ', verificou-se que o valor total passaria do original. Vl parcela ' ||
                   TO_CHAR(LANC.VLPAGAMENTO) || ' paga em ' ||
                   VNUMESREFERENCIA || '/' ||
                   TO_CHAR(VFOLHA.NUANOREFERENCIA);
         ELSIF VVLTOTAL <= LANC.VLLANCAMENTOFINANCEIRO THEN

       SELECT NVL(MAX(L.NUPARCELA), 0) + 1
       INTO VNUPARCELA
       FROM EPAGPAGAMENTOLANCAMENTO L
       WHERE L.CDLANCAMENTOFINANCEIRO = LANC.CDLANCAMENTOFINANCEIRO;

       XTMPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => LANC.CDLANCAMENTOFINANCEIRO,
                                           pNuAnoReferencia => LANC.NUANOREFERENCIA,
                                           pNuMesreferencia => LANC.NUMESREFERENCIA,
                                           pNuParcela => VNUPARCELA,
                                           pValorParcela => LANC.VLPAGAMENTO,
                                           pDataUltimaAlteracao => TRUNC(SYSDATE));

           VMSG := 'Parcela referente a ' || VPROCESSO || ', no valor de ' ||
                   TO_CHAR(LANC.VLPAGAMENTO) || ' e paga em ' ||
                   VNUMESREFERENCIA || '/' ||
                   TO_CHAR(VFOLHA.NUANOREFERENCIA) ||
                   ', estava faltando no lançamento financeiro, mas foi registrada agora';

           IF VVLTOTAL = LANC.VLLANCAMENTOFINANCEIRO THEN
             -- Altera tabela lançamento financeiro
             UPDATE EPAGLANCAMENTOFINANCEIRO LF
                SET LF.DTFIMDIREITO = VDTFIMMESANT
              WHERE LF.CDLANCAMENTOFINANCEIRO = LANC.CDLANCAMENTOFINANCEIRO
                AND NVL(LF.DTFIMDIREITO, TO_DATE('01/01/1900', 'DD/MM/YYYY')) < TO_DATE(TO_CHAR(VFOLHA.NUANOREFERENCIA) || VNUMESREFERENCIA || '01', 'YYYYMMDD');
             IF SQL%ROWCOUNT > 0 THEN
               VMSG := VMSG ||
                       '; O respectivo lançamento financeiro foi finalizado';
             END IF;
           END IF;

           -- Este bloco foi colocado originalmente na vacina, mas deu o problema relatado no chamado 125697/2018 e foi retirado
           --  Precisou-se de novo do bloco para corrigir o problema do chamado 12841/2018, mas agora só é feito para calculos definitivos
           -- Obs.: como o primeiro processamento definitivo sempre vai ser o geral, nao há preocupacao com os calculos definitivos individuais posteriores
           IF LANC.CDTIPOORIGEMRUBRICA = 12 THEN
             -- Finaliza processo retroativo
             -- XTMPAG_PC.PATUALIZASITUACAORETRO(LANC.CDVINCULO, VFOLHA);
             SELECT COUNT(*)
               INTO VVLTOTAL
               FROM ERETPROCESSOPAGRETROATIVO RET
              WHERE RET.CDPROCESSOPAGRETROATIVO =
                    LANC.CDPROCESSOPAGRETROATIVO
                AND RET.CDSITUACAOPROCESSO >= 3;
             IF VVLTOTAL > 0 THEN
               VMSG := VMSG || '; O respectivo ' || VPROCESSO ||
                       ' foi finalizado';
             END IF;
           ELSIF LANC.CDTIPOORIGEMRUBRICA = 11 THEN
             -- Finaliza processo restituicao erario
             -- XTMPAG_PC.PATUALIZASITUACAOERARIO(LANC.CDVINCULO, VFOLHA);
             SELECT COUNT(*)
               INTO VVLTOTAL
               FROM EREPPROCESSORESTITUICAOERARIO RET
              WHERE RET.CDPROCESSORESTITUICAOERARIO =
                    LANC.CDPROCESSORESTITUICAOERARIO
                AND RET.CDSITUACAOPROCESSO >= 3;
             IF VVLTOTAL > 0 THEN
               VMSG := VMSG || '; O respectivo ' || VPROCESSO ||
                       ' foi finalizado';
             END IF;
           END IF;

         END IF;
         VMSG := VMSG || '.';

         XTMPAG_GERAL.PINSERELOG(XTMPAG_VAR.BLOG,
                                 XTMPAG_VAR.VCDHISTPARAMCALC,
                                 LANC.CDPESSOA,
                                 VMSG,
                                 LANC.CDVINCULO,
                                 24); --Lançamento financeiro - parcela não computada

       END IF;

     ELSIF LANC.INPERIODICIDADE = XTMPAG_TIPO.CNQ AND
           (LANC.NUPARCELAS IS NOT NULL OR LANC.NUPARCELAS > 0) THEN

       SELECT R.NURUBRICAFMT
         INTO VNURUBRICA
         FROM VPAGRUBRICAAGRUPAMENTO R
        WHERE R.CDRUBRICAAGRUPAMENTO = LANC.CDRUBRICAAGRUPAMENTO;

       XTMPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => LANC.CDLANCAMENTOFINANCEIRO,
                                           pNuAnoReferencia => XTMPAG_VAR.VGFOLHA.NUANOREFERENCIA,
                                           pNuMesreferencia => XTMPAG_VAR.VGFOLHA.NUMESREFERENCIA,
                                           pNuParcela => LANC.QTPARCELAS,
                                           pValorParcela => LANC.VLPAGAMENTO,
                                           pDataUltimaAlteracao => SYSTIMESTAMP);

       VMSG := 'O respectivo lançamento financeiro foi registrado. Rubrica:' ||
               VNURUBRICA || ', parcela ' || LANC.QTPARCELAS ||
               ' - valor R$ ' || LANC.VLPAGAMENTO;

       XTMPAG_GERAL.PINSERELOG(PINSERE                  => XTMPAG_VAR.BLOG,
                               PCDHISTORICOPARAMCALCULO => XTMPAG_VAR.VCDHISTPARAMCALC,
                               PCDPESSOA                => LANC.CDPESSOA,
                               PDELOG                   => VMSG,
                               PCDVINCULO               => LANC.CDVINCULO,
                               PCDTIPOOCORRENCIA        => 2, -- Ocorrencia
                               PCDMOTIVOOCORRENCIA      => 24); --Lançamento financeiro - parcela não computada

     END IF;

     ELSE
        VMSG := 'O respectivo lançamento financeiro não foi computado. Rubrica:' ||
               VNURUBRICA || ', parcela ' || LANC.QTPARCELAS ||
               ' - valor R$ ' || LANC.VLPAGAMENTO;

        XTMPAG_GERAL.PINSERELOG(PINSERE                  => XTMPAG_VAR.BLOG,
                               PCDHISTORICOPARAMCALCULO => XTMPAG_VAR.VCDHISTPARAMCALC,
                               PCDPESSOA                => LANC.CDPESSOA,
                               PDELOG                   => VMSG,
                               PCDVINCULO               => LANC.CDVINCULO,
                               PCDTIPOOCORRENCIA        => 2, -- Ocorrencia
                               PCDMOTIVOOCORRENCIA      => 24); --Lançamento financeiro - parcela não computada
     END IF;

   END LOOP;

 EXCEPTION

   WHEN OTHERS THEN
     XTMPAG_GERAL.PINSERELOG(XTMPAG_VAR.BLOG,
                             NULL,
                             PCDVINCULO,
                             '** Erro (XTMPAG_cal.PINSPAGAMENTOLANCFALTANTES): ' ||
                             SQLERRM);

 END PINSPAGAMENTOLANCFALTANTES;

PROCEDURE PZerarValorPgtoCopPlanoSaude(pCdVinculo       IN INTEGER,
                                       pNuAnoReferencia IN INTEGER,
                                       pNuMesReferencia IN INTEGER) IS
BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  UPDATE ESauImpSistemaExterno
     SET vlpagocoparticip_gp = 0,
         vlpagounisanta = 0,
         vlpagocopipesctratsaude = 0,
         vlpagocoparticipjudicial = 0,
         vlpagocoparticip = 0
   WHERE cdvinculo = pCdVinculo
     AND nuanocompetencia = pNuAnoReferencia
     AND numescompetencia = pNuMesReferencia;
END;

FUNCTION FObterUltimaDataCalculo(pDataReferencia      IN DATE,
                                 pCdOrgao             IN INTEGER,
                                 pCdTipoFolha         IN INTEGER,
                                 pCdTipoCalculo       IN INTEGER,
                                 pFlCalculoDefinitivo IN CHAR) RETURN DATE IS
  vUltimaDataCalculo DATE;
BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  select max(fpg.dtcalculo)
  into vUltimaDataCalculo
  from
  epagfolhapagamento fpg
  inner join epagtipofolhapagamento tfp on fpg.cdtipofolhapagamento=tfp.cdtipofolhapagamento
  where
  fpg.cdorgao=pCdOrgao
  and tfp.cdtipofolha=pCdTipoFolha
  and fpg.cdtipocalculo=pCdTipoCalculo
  and fpg.flcalculodefinitivo=pFlCalculoDefinitivo
  and fpg.dtcalculo<pDataReferencia;

  RETURN vUltimaDataCalculo;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN TOO_MANY_ROWS THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
END;

PROCEDURE PExcluirRubricasCLT(pCdVinculo        IN INTEGER,
                              pCdFolhaPagamento IN INTEGER,
                              pCdAgrupamento    IN INTEGER) IS
BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  DELETE FROM epaghistoricorubricavinculo hrv
   WHERE hrv.cdfolhapagamento = pCdFolhaPagamento
     AND hrv.cdvinculo = pCdVinculo
     AND hrv.cdrubricaagrupamento IN
         (SELECT ragr.cdrubricaagrupamento
            FROM epagrubricaagrupamento ragr
           WHERE ragr.cdagrupamento = pCdAgrupamento
             AND ragr.cdrubrica IN
                 (SELECT rub.cdrubrica
                    FROM epagrubrica rub
                   WHERE rub.cdtiporubrica = 9
                     AND rub.nurubrica IN (903, 904, 906, 913)));
END;


 PROCEDURE PAjustarContrachequeCCO(pCdVinculo            IN INTEGER,
                                   pCdAgrupamento        IN INTEGER,
                                   pCdOrgao              IN INTEGER,
                                   pCdFolhaPagamento     IN INTEGER,
                                   pCdTipoFolhaPagamento IN INTEGER,
                                   pDataInicioMes        IN DATE,
                                   pDataFimMes           IN DATE,
                                   pDataCalculo          IN DATE) IS
 BEGIN
   -- xtmpag_util.pGravaLogCallStack;

   if FPossuiVinculoCCOProvDestino(pCdVinculo, pCdOrgao, pDataCalculo, pDataFimMes)
     and pCdAgrupamento <> 134 -- Excecao PM e Bombeiros
     and XTMPAG_var.vgFolha.CdTipoFolhaPagamento NOT IN (1505,1525,1526,1766) -- Folhas PRODEX excecao
     then

       if XTMPAG_var.vgfolha.cdorgao <> XTMPAG_GERAL.FObterOrgaoExercicioCCO(pcdvinculo => pCdVinculo,
                                                                             pdatareferencia => pDataCalculo) then
         XTMPAG_geral.pexcluirpagvinc (pCdFolhaPagamento, pCdVinculo);
       end if;

   end if;
 END;

END XTMPAG_CAL;
/
