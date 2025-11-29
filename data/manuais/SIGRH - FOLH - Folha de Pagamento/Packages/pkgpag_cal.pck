CREATE OR REPLACE PACKAGE PKGPAG_CAL IS

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
    FlOutroVincACalcular     CHAR(1),
    FlContribIndiv           INTEGER,
    deOrdemExecucao          VARCHAR(5) 
    )      
    ;

  FUNCTION FAfastSemRemun(pCdVinculo IN INTEGER,
                          pDtInicio  IN DATE,
                          pDtFim     IN DATE,
                          pdtCalculo IN DATE) RETURN PKGPAG_TIPO.rMotAfast;

  FUNCTION FAfastamentoVinculo(pCdVinculo          IN INTEGER,
                               pDtInicio           IN DATE,
                               pDtFim              IN DATE,
                               pdtCalculo          IN DATE,
                               pTipoAfa            IN CHAR,
                               pCdHistCargoEfetivo IN INTEGER DEFAULT NULL,
                               pDtCalculoAnt       IN DATE DEFAULT NULL,
                               pAuxAlim            IN CHAR DEFAULT 'N') -- R-Temporario Remunerado | N-temporario nao remunerado | D-Definitivo | V-Relacao de vinculo
   RETURN PKGPAG_TIPO.tAfastamento;

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

 procedure pAtualizaValorRubrica (pCdVinculo in integer,
                                  pCdFolhaPagamento in integer,
                                  pCdRubricaAgrupamento in integer,
                                  pValorRubrica in pkgpag_tipo.rValorPagamento,
                                  pCdRelacaoVinculo in integer default null,
                                  pCdOutraRubrica in integer default null,
                                  pDeFormula in char default null,
                                  pIncluiRelVinc in char default 'N');

  PROCEDURE PProcessaFolhaSuplementar(pFolhaSuplementar    IN PKGPAG_TIPO.rFolha,
                                      pFolhaOrigem         IN PKGPAG_TIPO.rFolha,
                                      pFolhaRecalculo      IN PKGPAG_TIPO.rFolha,
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

END PKGPAG_CAL;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_CAL IS

  TYPE rTabFolhaPagamentoDifMes IS RECORD(
    CdFolhaDifMes INTEGER,
    DtCalculo     DATE);

  TYPE tTabFolhaPagamentoDifMes IS TABLE OF rTabFolhaPagamentoDifMes INDEX BY PLS_INTEGER;

  TYPE tFalta is VARRAY(12) of NUMBER;

  --vFalta tFalta;

  vgTabCdFolhaPagamentoDifMes tTabFolhaPagamentoDifMes;

  --vvlCalculado pkgpag_tipo.rvalorpagamento;

  --vVlIndice NUMBER(10,4);

  vVlMargemErario NUMBER(13,2);

  --vvlCalculadoBaseErario pkgpag_tipo.rvalorpagamento;

  vvlCalculadoRubrica pkgpag_tipo.rvalorpagamento;

  vVlRubrica number(13,2);

  vDeFormula epagformulacalculo.deformulacalculo%type;

  vVlRubrica010201 number(13,2);

  vvgPercentATS pkgpag_tipo.tPercentATS;
  --vHistRubRelVinc epaghistoricorubricarelvinc%rowtype;

  vCdFolha13Definitiva integer;


PROCEDURE PDebug (pMsg IN VARCHAR2) IS
   vvalor   varchar2(32000);
BEGIN

    select chr(10) || LISTAGG (max(deexpressao) || ': ' || MAX(nurubricafmt || ' - ' || descricao) || ' => ' || max(vlpagamento) || ' qtde = ' || count (*),CHR(10)) WITHIN GROUP (ORDER BY MAX(nurubricafmt))
      into vValor
      from vpagcc
     where cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
       and cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
       and nurubricafmt in ('05-0512','09-0903','09-1666')
     group by cdrubricaagrupamento;

/*
   select chr(10) || LISTAGG ('(' || MAX(nuOrdemCalculo) || ') ' || MAX(nurubricafmt || ' -' || derubricaagrupamento) || ' => ' || max(vlpagamento) || ' qtde = ' || count (*),CHR(10)) WITHIN GROUP (ORDER BY MAX(nurubricafmt))
      into vValor
          from epaghistoricorubricavinculo hrv
    inner join vpagrubricaagrupamento ra
       on ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
    where hrv.cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
      and hrv.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento

      and nuOrdemCalculo > (select NVL(MAX(nuOrdemCalculo),0)
                       from epaghistoricorubricavinculo hrvi
                      where hrvi.cdvinculo = hrv.cdvinculo 
                        and hrvi.cdfolhapagamento = hrv.cdfolhapagamento
                        and hrvi.cdrubricaagrupamento = 8018)

  group by nurubricafmt;  
*/
        
   DBMS_OUTPUT.PUT_LINE ('CAL: ' || pMsg || VVALOR);  
END;
  
  FUNCTION FRetornaOpcaoRemuneracaoCCO(pCdHistCargoCom IN INTEGER,
                                       pDtInicioMes    IN DATE,
                                       pDtFimMes       IN DATE)

   RETURN INTEGER IS

    vCdOpcaoRemuneracao INTEGER;

  BEGIN
 
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

FUNCTION FPossuiFolhaDefAnterior(pCdVinculo IN INTEGER,
                           pDtInclusao  IN DATE) RETURN BOOLEAN IS

  vCont INTEGER;

  BEGIN
 
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
       and ((to_char(fp.dtcalculo,'YYYY') = pkgpag_var.vgFolha.NuAnoReferencia and pkgpag_var.vgFolha.NuMesReferencia > 1) or
           (pkgpag_var.vgFolha.NuMesReferencia = 1 and fp.Nuanoreferencia = pkgpag_var.vgFolha.NuAnoReferencia - 1 and
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
 
    SELECT 1
      INTO vCont
      FROM ECadHistCargoEfetivo HCE
     WHERE HCE.CdVinculo = pCdVinculo
       AND HCE.CdRelacaotrabalho = PKGPAG_TIPO.cnRelTrabDisposicao
       AND (HCE.DtInicio <= pDtFim AND
           (HCE.DtFim >= pDtInicio OR HCE.DtFim IS NULL))
       AND HCE.FlAnulado = PKGPAG_TIPO.cnN
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
 
    SELECT 1
      INTO vCont
      FROM ECadHistCargoCom HCC
     WHERE HCC.CdVinculo = pCdVinculo
       AND HCC.CdOrgaoExercicio = pCdOrgao
       AND HCC.CdCargoComRemuneracao IS NULL
       AND (HCC.DtInicio <= pDtFim AND
           (HCC.DtFim >= pDtInicio OR HCC.DtFim IS NULL))
       AND HCC.Flanulado = PKGPAG_TIPO.cnN
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
 
    -- Folhas Prodex e Honorarios GERA
    if pkgpag_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766) then
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
       AND HCC.Flanulado = PKGPAG_TIPO.cnN
       AND HCC.Fltipoprovimento in ('D','N')
       and not exists (select 1 from ecadhistcargoefetivo cef
                        where cef.cdvinculo = pCdVinculo
                          and cef.dtinicio > hcc.dtfim
                          and cef.dtinicio <= pDtFim
                          and cef.cdorgaoexercicio = pCdOrgao
                          and cef.flanulado = 'N');

    IF vCont > 0 THEN

       PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Comissionado em outro orgao, nao processa orgao origem! ' || pCdOrgao,
                               pKGPAG_VAR.vgCdVinculo);


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
 
    IF PKGPAG_VAR.bPossuiFolhaSuplDef THEN

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
                   AND FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl
                   AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
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
                          pdtCalculo IN DATE) RETURN PKGPAG_TIPO.rMotAfast IS

    vMotivoAfastamento PKGPAG_TIPO.rMotAfast;

    vNuDiasAfast INTEGER;

  BEGIN
 
    vMotivoAfastamento.InAfastado := PKGPAG_TIPO.cnAfastadoNao;

    vMotivoAfastamento.InTipoAfastamento := ' ';

    vMotivoAfastamento.InPagaLancamento := 'N';

    vMotivoAfastamento.CdChaveMotivo := NULL;

    vMotivoAfastamento.DtInclusao := NULL;

    vMotivoAfastamento.DtInicio := NULL;

    vMotivoAfastamento.FlAuxilioDoenca := NULL;

    vMotivoAfastamento.FlAcidenteTrabalho := NULL;

    vMotivoAfastamento.FlProcessaNaoPaga := NULL;

    IF pkgpag_var.vgFolha.cdtipofolha = pkgpag_tipo.cnTpFolhaInstPensao THEN
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
                           AND HMAT.FlRemunerado = PKGPAG_TIPO.cnN
                           AND AV.DtInicio <= pdtFim
                           AND (AV.DtFim >= pdtInicio OR AV.DtFim IS NULL)
                           AND HMAT.DtInicioVigencia <= pdtCalculo
                           AND (HMAT.DtFimVigencia >= pdtCalculo OR
                               HMAT.DtFimVigencia IS NULL)
                           AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
                           AND AV.FlAnulado = PKGPAG_TIPO.cnN) B
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
        (PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT AND
        TO_CHAR(PKGPAG_VAR.vgVinculo.DtDesligamento, 'DD') = vNuDiasAfast AND
        TO_CHAR(pDtFim, 'MMYYYY') =
        TO_CHAR(PKGPAG_VAR.vgVinculo.DtDesligamento, 'MMYYYY'))

     THEN

      vMotivoAfastamento.InAfastado := PKGPAG_TIPO.cnAfastadoMesTodo;

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
         AND AV.FlAnulado = PKGPAG_TIPO.cnN
         AND HMAT.FlRemunerado = PKGPAG_TIPO.cnN
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
           AND LF.FlPagaAfastTempSemRemun = PKGPAG_TIPO.cnS
           AND LF.DtInicioDireito <= pDtFim
           AND (LF.DtFimDireito >= pDtInicio OR LF.Dtfimdireito IS NULL)
           and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                             from vpagrubricaagrupamento ra
                                            where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                              and ra.flsuspensa = PKGPAG_TIPO.cnN)
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
           AND AV.FlAnulado = PKGPAG_TIPO.cnN
           AND HMAD.FlRemunerado = PKGPAG_TIPO.cnN
           AND AV.DtInicio <= pDtInicio
           AND (AV.DtFim >= pDtFim OR AV.DtFim IS NULL)
           AND HMAD.DtInicioVigencia <= pdtCalculo
           AND (HMAD.DtFimVigencia >= pdtCalculo OR
               HMAD.DtFimVigencia IS NULL)
           AND ROWNUM < 2;

        vMotivoAfastamento.InAfastado := PKGPAG_TIPO.cnAfastadoMesTodo;

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
                AND AV.FlAnulado = PKGPAG_TIPO.cnN
                AND HMAD.FlRemunerado = PKGPAG_TIPO.cnN
                AND AV.DtInicio BETWEEN pDtInicio and pDtFim
                AND HMAD.DtInicioVigencia <= pdtCalculo
                AND (HMAD.DtFimVigencia >= pdtCalculo OR
                     HMAD.DtFimVigencia IS NULL)
                AND ROWNUM < 2;

           IF TO_CHAR(PKGPAG_VAR.vgVinculo.DtDesligamento, 'DD') = vNuDiasAfast
             AND TO_CHAR(pDtFim, 'MMYYYY') = TO_CHAR(PKGPAG_VAR.vgVinculo.DtDesligamento, 'MMYYYY')
            THEN

              BEGIN
                -- SIG-4755
                -- Servidor demitido no mês, com afastamento temporário não remunerado anterior
                SELECT PKGPAG_TIPO.cnAfastadoMesTodo
                  INTO vMotivoAfastamento.InAfastado
                  FROM EAfaAfastamentoVinculo AV
                  LEFT join Eafamotivoafasttemporario mat
                    on mat.cdmotivoafasttemporario = av.cdmotivoafasttemporario
                  LEFT join Eafahistmotivoafasttemp hmat
                    on hmat.cdmotivoafasttemporario = av.cdmotivoafasttemporario
                 WHERE AV.CdVinculo = pCdVinculo
                   AND AV.FlAnulado = PKGPAG_TIPO.cnN
                   AND (hmat.flremunerado = PKGPAG_TIPO.cnN)
                   AND AV.DtInicio < pkgpag_var.vgFolha.dtInicioMes
                   AND (AV.Dtfim = vMotivoAfastamento.DtInicio OR AV.Dtfim = vMotivoAfastamento.DtInicio-1)
                   AND (HMAT.DtInicioVigencia <= pkgpag_var.vgFolha.dtcalculoant)
                   AND (HMAT.DtFimVigencia >= pkgpag_var.vgFolha.dtcalculoant OR
                       HMAT.DtFimVigencia IS NULL)
                   AND ROWNUM < 2;

                -- caso encontre um afastamento não remunerado com a data fim igual a data início do afastamento definitio,
                -- considera como afastado o mês todo
                -- vMotivoAfastamento.InAfastado := PKGPAG_TIPO.cnAfastadoMesTodo;

               EXCEPTION

                    WHEN NO_DATA_FOUND
                      THEN
                      vMotivoAfastamento.InAfastado := PKGPAG_TIPO.cnAfastadoParcial;

                    RETURN vMotivoAfastamento;
               END;

            ELSE
              vMotivoAfastamento.InAfastado := PKGPAG_TIPO.cnAfastadoParcial;
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
                     AND AV.FlAnulado = PKGPAG_TIPO.cnN
                     AND HMAT.FlRemunerado = PKGPAG_TIPO.cnN
                     AND AV.DtInicio <= pDtFim
                     AND (AV.DtFim >= pDtInicio OR AV.DtFim IS NULL)
                     AND HMAT.DtInicioVigencia <= pdtCalculo
                     AND (HMAT.DtFimVigencia >= pdtCalculo OR
                         HMAT.DtFimVigencia IS NULL)
                     AND ROWNUM < 2;

                  vMotivoAfastamento.InAfastado := PKGPAG_TIPO.cnAfastadoParcial;

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
                                   pValorRubrica in pkgpag_tipo.rValorPagamento,
                                   pCdRelacaoVinculo in integer default null,
                                   pCdOutraRubrica in integer default null,
                                   pDeFormula in char default null,
                                   pIncluiRelVinc in char default 'N') is

  begin
 
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
   RETURN PKGPAG_TIPO.tAfastamento IS

    tAfastVinc PKGPAG_TIPO.tAfastamento;

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
          PKGPAG_VAR.bPossuiAfastRemunUltDiaMes := true;
        else
          PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes := true;
        end if;

      else
        tAfastVinc(pIndice).FlUltimoDiaMes := 'N';
      end if;

      if pDtInclusao > pkgpag_var.vgfolha.DtCalculoAnt OR (pDtAnulado IS NOT NULL AND pDtAnulado > pkgpag_var.vgfolha.DtCalculoAnt)
         and pDtInicioAfa < pkgpag_var.vgfolha.DtInicioMes
       then
         tAfastVinc(pIndice).NuDiasAfastMesAnt := least(pkgpag_var.vgfolha.DtInicioMes, NVL(pDtFimAfa,pkgpag_var.vgfolha.DtInicioMes) ) - pDtInicioAfa;
      else
         tAfastVinc(pIndice).NuDiasAfastMesAnt := 0;
      end if;

      tAfastVinc(pIndice).DtAnulado := pDtAnulado;

      tAfastVinc(pIndice).FlParteJornada := pFlParteJornada;
      tAfastVinc(pIndice).VlPercentReducaoIRESA := pVlPercentReducaoIRESA;

    END;

  BEGIN
 
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
                                            (trunc(AV.DtInclusao) BETWEEN (trunc(PKGPAG_VAR.vDtCalculoAnt) + 1) AND trunc(pDtCalculo))))
                                 AND HMAT.DtInicioVigencia <= pDtCalculo
                                 AND HMAT.FLREMUNERADO = CASE
                                       WHEN pTipoAfa = 'R' THEN
                                        PKGPAG_TIPO.cnS
                                       ELSE
                                        PKGPAG_TIPO.cnN
                                     END
                                 AND (HMAT.DtFimVigencia >= pDtCalculo OR
                                     HMAT.DtFimVigencia IS NULL)
                                 AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
                                 AND AV.FlAnulado = PKGPAG_TIPO.cnN
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
            PKGPAG_VAR.vgNuDiasAfastRemun := NVL(PKGPAG_VAR.vgNuDiasAfastRemun,0) +
                                             f_Afa.DtFimAfaNoMes -
                                             f_Afa.DtInicioAfaNoMes + 1;

            IF f_Afa.DtInclusao >= pkgpag_var.vgfolha.DtCalculoAnt +1
               AND f_Afa.DtInicioAfa < pkgpag_var.vgFolha.DtInicioMes
               AND f_Afa.DtInicioAfa >= add_months(pkgpag_var.vgFolha.DtInicioMes, -4)
               THEN

                 pkgpag_var.vgNuDiasAfastRetroativo := nvl(pkgpag_var.vgNuDiasAfastRetroativo,0) +
                                                     (case when NVL(f_Afa.DtFimAfa + 1, pkgpag_var.vgfolha.DtInicioMes + 1) >
                                                                pkgpag_var.vgfolha.DtInicioMes
                                                           then pkgpag_var.vgfolha.DtInicioMes
                                                           else f_Afa.DtFimAfa + 1
                                                      end) - f_Afa.DtInicioAfa;
             END IF;

          else
            PKGPAG_VAR.vgNuDiasAfastSemRemun := NVL(PKGPAG_VAR.vgNuDiasAfastSemRemun,0) +
                                                f_Afa.DtFimAfaNoMes -
                                                f_Afa.DtInicioAfaNoMes + 1;

            if f_afa.DtInicioAfa <= pDtFim and nvl(f_afa.DtFimAfa, pDtInicio) >= pDtInicio then
              PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual := nvl(PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual,0) +
                                                          f_Afa.DtFimAfaNoMes -
                                                          f_Afa.DtInicioAfaNoMes + 1;
            end if;

             IF f_Afa.DtInclusao >= pkgpag_var.vgfolha.DtCalculoAnt +1
               AND f_Afa.DtInicioAfa < pkgpag_var.vgFolha.DtInicioMes
               AND f_Afa.DtInicioAfa >= add_months(pkgpag_var.vgFolha.DtInicioMes, -4)
               THEN

                 pkgpag_var.vgNuDiasAfastRetroativo := nvl(pkgpag_var.vgNuDiasAfastRetroativo,0) +
                                                     (case when NVL(f_Afa.DtFimAfa + 1, pkgpag_var.vgfolha.DtInicioMes + 1) >
                                                                pkgpag_var.vgfolha.DtInicioMes
                                                           then pkgpag_var.vgfolha.DtInicioMes
                                                           else f_Afa.DtFimAfa + 1
                                                      end) - f_Afa.DtInicioAfa;
                 --
                 -- Dias para auxílio alimentacao
                 --
                  IF pkgpag_var.vgListaEventoAfast11.exists(f_afa.cdmotivo)
                    THEN
                      pkgpag_var.vgNuDiasAfastAuxAlimRet := nvl(pkgpag_var.vgNuDiasAfastAuxAlimRet,0) + 0;
                    ELSE
                      pkgpag_var.vgNuDiasAfastAuxAlimRet := nvl(pkgpag_var.vgNuDiasAfastAuxAlimRet,0) +
                                                     (case when NVL(f_Afa.DtFimAfa + 1, pkgpag_var.vgfolha.DtInicioMes + 1) >
                                                                pkgpag_var.vgfolha.DtInicioMes
                                                           then pkgpag_var.vgfolha.DtInicioMes
                                                           else f_Afa.DtFimAfa + 1
                                                      end) - f_Afa.DtInicioAfa;

                  END IF;

             END IF;

          END IF;

          IF pkgpag_var.vgListaEventoAfast11.exists(f_afa.cdmotivo)
            then
              j := j + 1;
              pkgpag_var.vgAfastAuxAlimentacao(j) := tAfastVinc(i);
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
                                      OR (trunc(AV.DtInclusao) BETWEEN (trunc(PKGPAG_VAR.vDtCalculoAnt) + 1) AND trunc(pDtCalculo)))
                                 AND HMAD.DtInicioVigencia <= pDtCalculo
                                 AND HMAD.FLREMUNERADO = PKGPAG_TIPO.cnN
                                 AND (HMAD.DtFimVigencia >= pDtCalculo OR
                                     HMAD.DtFimVigencia IS NULL)
                                 AND HMAD.FlAnulado = PKGPAG_TIPO.cnN
                                 AND AV.FlAnulado = PKGPAG_TIPO.cnN))

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

          PKGPAG_VAR.vgNuDiasAfastDefinitivo := nvl(PKGPAG_VAR.vgNuDiasAfastDefinitivo,0) +
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
                                         AND NOT (PKGPAG_VAR.vgFolha.FlIgnoraInclusaoFutura = 'S' AND
                                              HCC.DtInclusao > pDtCalculo)
                                         AND HCC.CdCargoComRemuneracao IS NULL
                                            --AND ((HOR.CdOpcaoRemuneracao = 3 AND
                                            --      NOT (HCC.FlTipoProvimento IN (PKGPAG_TIPO.cnS) AND
                                            ---     pRubrica.FlPropAfaCCOSubst = PKGPAG_TIPO.cnN)) OR
                                            --    (pRubrica.FlPropAfaFgFtg = PKGPAG_TIPO.cnS AND
                                            ---    HOR.CdOpcaoRemuneracao = 6 ) OR
                                            --   (pEventoCEF = PKGPAG_TIPO.cnN AND HCC.CdOpcaoRemuneracao = 2 AND
                                            --   pRubrica.FlPropAfaComOpcPercCEF = 'S')))
                                         AND AV.FlAnulado = PKGPAG_TIPO.cnN)))

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

          PKGPAG_VAR.vgNuDiasAfastRelVinc := nvl(PKGPAG_VAR.vgNuDiasAfastRelVinc,0) +
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
                                 AND (AV.DtAnulado BETWEEN (PKGPAG_VAR.vDtCalculoAnt + 1) AND pDtCalculo)
                                 AND HMAT.DtInicioVigencia <= pDtCalculo
                                 AND HMAT.FLREMUNERADO = PKGPAG_TIPO.cnS
                                 AND (HMAT.DtFimVigencia >= pDtCalculo OR
                                     HMAT.DtFimVigencia IS NULL)
                                 AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
                                 AND AV.FlAnulado = PKGPAG_TIPO.cnS) -- Anulados
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
 
    SELECT COUNT(*)
    INTO vRescisao
    FROM epagrescisaocontrato re
    WHERE re.cdvinculo =  pCdVinculo
    AND to_char(re.dtrescisao, 'YYYYMM') = to_char(pkgpag_var.vgFolha.dtcalculo, 'YYYYMM');

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
       AND fp.cdagrupamento = pkgpag_var.vgFolha.cdagrupamento
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
         pkgpag_geral.fretornarubrica(pcdagrupamento, 1, 201);

  IF NVL(vcdfolhapagamento, 0) > 0  THEN
     -- Permitir se for folha de recalculo do mes
     if pkgpag_var.vgFolha.CdFolhaPagamentoNormal = vcdfolhapagamento and
        pkgpag_var.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cntpcalculorecalculomes then

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
 
    insert into epaghistfolhaservafast (
           cdfolhapagamento
         , cdvinculo
         , cdafastamento
         , dtalteracao)
    select pkgpag_var.vgFolha.cdFolhaPagamento
         , pCdVinculo
         , av.cdafastamento
         , pkgpag_var.vgFolha.dtCalculo
      from eafaafastamentovinculo av
    /* inner join ecadhistcargoefetivo cef
     on cef.cdvinculo = av.cdvinculo
    and cef.cdrelacaotrabalho <> 10
    and cef.dtinicio <= pkgpag_var.vgFolha.dtFimMes
    and (cef.dtfim >= pkgpag_var.vgFolha.dtInicioMes or cef.dtfim is null)*/
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
       SET Afa.Flanulado = PKGPAG_TIPO.cnS
     WHERE Afa.Cdafastamento in (select a.cdafastamento
                                   from epaghistfolhaservafast a
                                  where a.cdfolhapagamento = pkgpag_var.vgFolha.cdFolhaPagamento
                                    and a.cdvinculo = pCdVinculo);
  END;

  --
  -- Verifica saldo de faltas nao descontadas mes anterior, base 09-5519 e inclui na rubrica 08-0519
  --
  procedure pFaltasNaoDescontadas (pCdVinculo IN INTEGER) is

     vVlPagamento number(13,2);

  begin
 
          vVlPagamento := pkgpag_geral.fretornavalorrubrica(pkgpag_var.vgFolha.CdFolhaPagamentoNormalAnt,pcdvinculo,
                                                            pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,5519));

     if nvl(vVlPagamento,0) > 0
        then

          pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                       pcdvinculo => pCdVinculo,
                                                pcdrelacaovinculo => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                            pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,519),
                                                      pVlIntegral => vVlPagamento,
                                                  pVlProporcional => vVlPagamento,
                                            pNuSufixoRubrica      => 1);

          /*PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => null,
                                                pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,8,519),
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

      vCefCount       INTEGER := PKGPAG_VAR.vgCEF.COUNT;
      vApoCount       INTEGER := PKGPAG_VAR.vgAPO.COUNT;
      vCdRubAgrup1001 INTEGER := PKGPAG_VAR.vgCdRubAgrup1001;

    BEGIN
 
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
 
    /* PENDENCIA

    Verificar: quando o valor dos indices dos historicos para uma mesma
    rubrica sao diferentes, o valor indice nao deve ser gerado. */

    PInsereTodasRVs;

    IF PKGPAG_VAR.vgFolha.cdAgrupamento = 176 AND PKGPAG_VAR.vgCCO.COUNT > 1 THEN

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
                                           and v.cdagrupamento = PKGPAG_VAR.vgFolha.cdAgrupamento);

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
                                           and v.cdagrupamento = PKGPAG_VAR.vgFolha.cdAgrupamento);
    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Erro ao jogar rubricas no historico de pagamento do vinculo: ' ||
                              SQLERRM,
                              PKGPAG_VAR.vgCdVinculo);
  END;

  /*-----------------------------------------------------------------------------------------
  --   Objetivo: Definir a ordem de execucao das formulas e bases de calculo
  -----------------------------------------------------------------------------------------*/
  PROCEDURE PDefinirOrdemFCalculo(pCalculo   IN rCalculo,
                                  pFolha     IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo IN INTEGER) IS
  BEGIN
 
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
                       nvl(pFolha.NuVersaoBaseCalculo, PKGPAG_TIPO.cn1)
                   AND RORD.NUVERSAOFORMCALC =
                       nvl(pFolha.NuVersaoFormulaCalculo, PKGPAG_TIPO.cn1)) LOOP

      -- IF PKGPAG_VAR.vgRubrica (rec.CdRubricaAgrupamento).NuOrdemCalculo IS NOT NULL THEN

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
                       nvl(pFolha.NuVersaoBaseCalculo, PKGPAG_TIPO.cn1)
                   AND RORD.NUVERSAOFORMCALC =
                       nvl(pFolha.NuVersaoFormulaCalculo, PKGPAG_TIPO.cn1)) LOOP

      -- IF PKGPAG_VAR.vgRubrica (rec.CdRubricaAgrupamento).NuOrdemCalculo IS NOT NULL THEN

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET nuOrdemCalculo = REC.NuOrdem
       WHERE rowid = rec.nuRowid;

    -- END IF;

    END LOOP;    

  END;

  PROCEDURE PDefinirOrdemFCalculoPassado(pFolha     IN PKGPAG_TIPO.rFolha,
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
                       LPAD(PKGPAG_VAR.vgRubrica(vChaveDependencia)
                            .CdTipoRubrica,
                            2,
                            '0') || '-' || LPAD(PKGPAG_VAR.vgRubrica(vChaveDependencia)
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
      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Processamento abortado. Encontrada dependencia mutua entre formulas/bases: ' ||
                              vMensagem,
                              PKGPAG_VAR.vgCdVinculo);

      IF PKGPAG_VAR.vCdHistParamCalc = 0 THEN

        RAISE PKGPAG_VAR.eDependenciaFormula;

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

  PROCEDURE PReprocessaFormulasBases(pFolha           IN PKGPAG_TIPO.rFolha,
                                     pCdVinculo       IN INTEGER,
                                     pTpProcessamento IN INTEGER DEFAULT 1) IS

  Vrubrica1480 integer;

  BEGIN
 
  Vrubrica1480 := pkgpag_geral.fretornarubrica(1, 1, 1480);

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
             WHERE R.CdTipoRubrica = PKGPAG_TIPO.cnTpRubTotalizadora
               AND HRV.CdRubricaAgrupamento = RA.CdRubricaAgrupamento);

    PKGPAG_FB.PProcessaFormulasBasesTotal (pFolha           => pFolha,
                                           pCdVinculo       => pCdVinculo,
                                           pTpProcessamento => pTpProcessamento);


    PConsolidaPagVinculo(pFolha.CdFolhaPagamento, pCdVinculo);

    IF PKGPAG_VAR.vgVlBase1467 > 0 THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseRateio,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => PKGPAG_VAR.vgVlBase1467,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

    END IF;

  END;

  /*-----------------------------------------------------------------------

  /*-----------------------------------------------------------------------*/

  PROCEDURE PProcessaRubricaExcludente(pFolha     IN PKGPAG_TIPO.rFolha,
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
 
    PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

    bReprocessa := FALSE;

    IF PKGPAG_VAR.vgRubricaExcludente.COUNT > 0 THEN

      FOR i IN PKGPAG_VAR.vgRubricaExcludente.FIRST .. PKGPAG_VAR.vgRubricaExcludente.LAST LOOP

        IF PKGPAG_VAR.vgRubricaExcludente.EXISTS(i) THEN

          CASE PKGPAG_VAR.vgRubricaExcludente(i).InTipoRegraRubExcludente

            WHEN 1 THEN
              -- Paga a maior

              bPrimeiro := TRUE;

              FOR vRub IN (SELECT HRV.CdRubricaAgrupamento
                             FROM EPagHistoricoRubricaVinculo HRV
                            WHERE HRV.CdFolhaPagamento =
                                  pFolha.CdFolhaPagamento
                              AND HRV.CdVinculo = pCdVinculo
                              AND (HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgRubricaExcludente(i)
                                  .CdRubricaAgrupamentoExcludente OR
                                  HRV.CdRubricaAgrupamento IN
                                  (SELECT CdRubricaAgrupamento
                                      FROM EPagOutraRubricaExcludente ORE
                                     WHERE ORE.CdRubricaExcludente = PKGPAG_VAR.vgRubricaExcludente(i)
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

              vvlDiferenca := FRetornaDiferencaRubrica(PKGPAG_VAR.vgRubricaExcludente(i)
                                                       .CdRubricaAgrupamentoExcludente,
                                                       PKGPAG_VAR.vgRubricaExcludente(i)
                                                       .CdRubricaAgrupamentoOutraRubEx);

              IF vvlDiferenca IS NOT NULL THEN

                CASE PKGPAG_VAR.vgRubricaExcludente(i).InRubricaPermanece

                  WHEN 1 THEN
                    -- Permanece a primeira rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlDiferenca
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoExcludente;

                    PKGPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                PKGPAG_VAR.vgRubricaExcludente(i)
                                                .CdRubricaAgrupamentoOutraRubEx);

                    bReprocessa := TRUE;

                  WHEN 2 THEN
                    -- Permanece a segunda rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlDiferenca
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoOutraRubEx;

                    PKGPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                PKGPAG_VAR.vgRubricaExcludente(i)
                                                .CdRubricaAgrupamentoExcludente);

                    bReprocessa := TRUE;

                  WHEN 3 THEN
                    -- A diferenca e paga numa terceira rubrica

                    IF NOT
                        FExisteRubricaPagDif(PKGPAG_VAR.vgRubricaExcludente(i)
                                             .CdRubricaAgrupamentoPagDif) THEN

                      DELETE FROM EPagHistoricoRubricaRelVinc HRV
                       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                         AND HRV.CdVinculo = pCdVinculo
                         AND HRV.CdRubricaAgrupamento IN
                             (PKGPAG_VAR.vgRubricaExcludente(i)
                              .CdRubricaAgrupamentoOutraRubEx,
                              PKGPAG_VAR.vgRubricaExcludente(i)
                              .CdRubricaAgrupamentoExcludente);

                      PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                            pCdVinculo            => pCdVinculo,
                                                            pCdRelacaoVinculo     => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                            pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                            pCdExpressaoFormCalc  => NULL,
                                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgRubricaExcludente(i)
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

              vvlMenorValor := FRetornaMenorValor(PKGPAG_VAR.vgRubricaExcludente(i)
                                                  .CdRubricaAgrupamentoExcludente,
                                                  PKGPAG_VAR.vgRubricaExcludente(i)
                                                  .CdRubricaAgrupamentoOutraRubEx);

              IF vVlMenorValor IS NOT NULL THEN

                CASE PKGPAG_VAR.vgRubricaExcludente(i).InRubricaPermanece

                  WHEN 1 THEN
                    -- Permanece a primeira rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlMenorValor
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoExcludente;

                    PKGPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                PKGPAG_VAR.vgRubricaExcludente(i)
                                                .CdRubricaAgrupamentoOutraRubEx);

                  WHEN 2 THEN
                    -- Permanece a segunda rubrica

                    UPDATE EPagHistoricoRubricaRelVinc HRV
                       SET HRV.Vlproporcional = vvlMenorValor
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgRubricaExcludente(i)
                          .CdRubricaAgrupamentoOutraRubEx;

                    PKGPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                                pCdVinculo,
                                                PKGPAG_VAR.vgRubricaExcludente(i)
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
    IF pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                         pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                         pCdRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,9467)) > 0
       THEN

       IF pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                            pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                            pCdRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,467)) <= 0
          AND ((pFolha.NuAnoReferencia * 100) + pFolha.NuMesReferencia) >= 202101
         THEN

         DELETE epaghistoricorubricavinculo hv
          WHERE hv.cdvinculo = pkgpag_var.vgcdvinculo
            AND hv.cdfolhapagamento =
                pkgpag_var.vgfolha.cdfolhapagamento
            AND hv.cdrubricaagrupamento =
                pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,9467);

       END IF;

    END IF;

    PKGPAG_GERAL.PLogTrace('CAL - Rubrica Excludente',
                           null,
                           PKGPAG_VAR.vgTmInicio);

  END;

  FUNCTION FTrataImpeditivas(pCdFolhaPagamento     IN INTEGER,
                             pCdVinculo            IN INTEGER,
                             pCdRubricaAgrupamento IN INTEGER,
                             pFlTotalizadora       IN CHAR)

   RETURN BOOLEAN IS

    vRubrica PKGPAG_TIPO.rRubrica;

    FUNCTION FExisteImpedimento(pCdFolhaPagamento IN INTEGER,
                                pCdVinculo        IN INTEGER,
                                pRubrica          IN PKGPAG_TIPO.rRubrica)
      RETURN BOOLEAN IS

      vCont INTEGER;

      vCdHistRubrica INTEGER;

      vImpede BOOLEAN := FALSE;

      vCdFolhaAlternativa INTEGER;
            
    BEGIN

      IF PKGPAG_VAR.vgCdFolhaIndenizatoria > 0 THEN
        
        vCdFolhaAlternativa := PKGPAG_VAR.vgCdFolhaIndenizatoria;
        
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

            vCdHistRubrica := PKGPAG_VAR.vgRubrica(f_impede.cdrubricaagrupamento)
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
                INTO PKGPAG_VAR.vCdRelacaoRubImpeditiva
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

                /*IF pRubrica.CdRubricaAgrupamento =  pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,1,1468) AND
                    PKGPAG_VAR.bVinculoComCCO AND
                    PKGPAG_VAR.vgRelVincPrincipal.Tipo = 1 AND
                    PKGPAG_VAR.vgFolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaNormal AND
                    pkgpag_var.vgValorCalculoRubrica(pRubrica.CdRubricaAgrupamento).vlcco = 0  AND
                    pkgpag_var.vgValorCalculoRubrica(pRubrica.CdRubricaAgrupamento).vlcef = 0 and
                    PKGPAG_VAR.bVinculoComCEF and
                    pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                      pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                                      pCdRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,1575)) = 0
                     THEN

                      PKGPAG_VAR.vCdRelacaoRubImpeditiva := 0;

             END IF;*/

            EXCEPTION

              WHEN NO_DATA_FOUND THEN
                PKGPAG_VAR.vCdRelacaoRubImpeditiva := 0;

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
 
    vRubrica := PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento);

    IF (pFlTotalizadora = 'S' AND
       vRubrica.CdTipoRubrica = PKGPAG_TIPO.cnTpRubTotalizadora) OR
       (pFlTotalizadora = 'N' AND
       vRubrica.CdTipoRubrica <> PKGPAG_TIPO.cnTpRubTotalizadora) THEN

      IF vRubrica.lsRubImpeditiva.COUNT > 0 THEN

        IF FExisteImpedimento(pCdFolhaPagamento, pCdVinculo, vRubrica) THEN

          PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento,
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

    vRubrica PKGPAG_TIPO.rRubrica;

    ------------------------------------------------------------------

    ------------------------------------------------------------------

    FUNCTION FCumpreExigencia(pCdFolhaPagamento IN INTEGER,
                              pCdVinculo        IN INTEGER,
                              pRubrica          IN PKGPAG_TIPO.rRubrica)
      RETURN BOOLEAN IS

      vCont INTEGER;

    BEGIN
 
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
 
    vRubrica := PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento);

    IF (pFlTotalizadora = 'S' AND
       vRubrica.CdTipoRubrica = PKGPAG_TIPO.cnTpRubTotalizadora) OR
       (pFlTotalizadora = 'N' AND
       vRubrica.CdTipoRubrica <> PKGPAG_TIPO.cnTpRubTotalizadora) THEN

      IF vRubrica.lsRubExigida.COUNT > 0 THEN

        IF NOT FCumpreExigencia(pCdFolhaPagamento, pCdVinculo, vRubrica) THEN

          PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento,
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
  PROCEDURE PExpurgarRubricas(pFolha   IN PKGPAG_TIPO.rFolha,
                              pVinculo IN PKGPAG_TIPO.rVinculo) IS

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
       vCdRubricaAgrupamento1_267 := pkgpag_geral.fretornarubrica(pCdAgrupamento, 1, 267);
      IF pCdTipoFolha = pkgpag_tipo.cnTpFolhaFunebre AND pCdRubricaAgrupamento = vCdRubricaAgrupamento1_267 THEN
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

      vRubrica PKGPAG_TIPO.rRubrica;

      vCdHistRelVinc INTEGER;

      vCdTipoOrigemRubrica INTEGER;

      vVlPagamento NUMBER(13, 2);

      vVlIndiceRubrica NUMBER(7, 4);

      vVlMinimoRecebimento NUMBER(13, 2);

    BEGIN
 
      vVlMinimoRecebimento := 0;

      vRubrica := PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento);

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
                 AND IA.FlAnulado = PKGPAG_TIPO.cnN
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
                                     PKGPAG_TIPO.cnS) LOOP

                PKGPAG_IA.PAtualizaValorIncorporacao(pCdVinculo              => pVinculo.CdVinculo,
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
            IF NOT (NVL(pVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax) BETWEEN
                pFolha.DtInicioMes AND pFolha.DtFimMes) THEN

              -- Proporcionaliza a carga horaria caso seja CEF

              IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

                FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

                  IF PKGPAG_VAR.vgCEF(i)
                   .NuCargaHoraria <>
                      PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

                    IF PKGPAG_VAR.vgCEF(i)
                     .NuCargaHoraria <
                        PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria /*AND
                                                                                                                             PKGPAG_VAR.vgRubrica(vRubrica.CdRubricaAgrupamento).FlCargaHorariaLimitada = 'N' - omitido em 10/04/2013 pelo Juan/Rogerio*/
                     THEN

                      vVlMinimoRecebimento := vVlMinimoRecebimento *
                                              (PKGPAG_VAR.vgCEF(i)
                                              .NuCargaHoraria /
                                               PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria);

                    ELSE

                      vVlMinimoRecebimento := vVlMinimoRecebimento;

                    END IF;

                  END IF;

                END LOOP;

                -- Proporcionaliza a carga horaria caso seja APO
              ELSIF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

                FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST LOOP

                  IF PKGPAG_VAR.vgAPO(i)
                   .NuCargaHoraria <
                      PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento *
                                            (PKGPAG_VAR.vgAPO(i)
                                            .NuCargaHoraria /
                                             PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria);

                  END IF;

                  IF NVL(PKGPAG_VAR.vgAPO(i).VlPercentPropApo, 100) < 100 THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento *
                                            (PKGPAG_VAR.vgAPO(i)
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

              IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

                FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

                  IF PKGPAG_VAR.vgCEF(i)
                   .NuCargaHoraria <>
                      PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento /
                                            PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria * PKGPAG_VAR.vgCEF(i)
                                           .NuCargaHoraria;

                  END IF;

                END LOOP;

              ELSIF PKGPAG_VAR.vgAPO.COUNT > 0 THEN

                FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST LOOP

                  IF NVL(PKGPAG_VAR.vgAPO(i).VlPercentPropApo, 100) < 100 THEN

                    vVlMinimoRecebimento := vVlMinimoRecebimento *
                                            (PKGPAG_VAR.vgAPO(i)
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
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
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

            IF NOT (NVL(pVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax) BETWEEN
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

            PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
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
 
       pkgpag_var.vgValorCalculoRubrica(pCdRubricaAgrupamento).VlCef := 0;
       pkgpag_var.vgValorCalculoRubrica(pCdRubricaAgrupamento).VlFuc := 0;

       EXCEPTION
         WHEN OTHERS THEN
           NULL;

    END;

    PROCEDURE PResetaCalculoFlexCeresCIDASC IS
    BEGIN
       PZeraValorCalculoRubrica(48192); -- 05-0802
      PZeraValorCalculoRubrica(48193); -- 05-0803
    END;

  BEGIN
 
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

      IF PKGPAG_VAR.vgVantagem(vPag.CdVantagemPecuniaria)
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

    IF PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
       PKGPAG_VAR.vgVinculo.DtDesligamento > pFolha.DtFimMes  THEN

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pVinculo.CdVinculo
         AND HRV.VlPagamento = 0
         AND NVL(HRV.VlMinRecebIncorp, 0) = 0
         AND hrv.cdrubricaagrupamento <> CASE
                                           WHEN (pkgpag_var.vgFolha.numesreferencia >= 8 AND pkgpag_var.vgFolha.nuanoreferencia = 2020) OR
                                                (pkgpag_var.vgFolha.nuanoreferencia > 2020) THEN
                                                PKGPAG_VAR.vgCdRubricaBaseCsgLiq -- A 09-1007 - Margem consignavel liquida deve ser gravada no contracheque com valor zero
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
                    AND HRA.FlPagaMaiorRV = PKGPAG_TIPO.cnS
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
             WHERE FV.CdHistVantagemPecuniaria = PKGPAG_VAR.vgVantagem(vPagVantagem(i).CdVantagemPecuniaria)
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
  PROCEDURE PExpurgarTotalizadoras(pFolha   IN PKGPAG_TIPO.rFolha,
                                   pVinculo IN PKGPAG_TIPO.rVinculo) IS

    CURSOR cRubricaPaga IS

      SELECT DISTINCT HRV.CdRubricaAgrupamento
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pVinculo.CdVinculo;

  BEGIN
 
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
       inAposentadoriaEspecial,
       cdorgaoexterno,
       cdorgaointerno,
       cdorgaoorigempensionista,
       flbloqueioenviado,
       nuordemcalculo,
       vlpercentcontribindiv   
       )
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
             hrv.inaposentadoriaespecial,
             cdorgaoexterno,
             cdorgaointerno,
             cdorgaoorigempensionista,
             flbloqueioenviado,
             nuordemcalculo,
             vlpercentcontribindiv 
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

  PROCEDURE PProcessaFolhaSuplementar(pFolhaSuplementar    IN PKGPAG_TIPO.rFolha,
                                      pFolhaOrigem         IN PKGPAG_TIPO.rFolha,
                                      pFolhaRecalculo      IN PKGPAG_TIPO.rFolha,
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
                    --   RA.Fltributacao = PKGPAG_TIPO.cnN AND RA.Flconsignacao = PKGPAG_TIPO.cnN AND
                     RA.FlConsignacao = PKGPAG_TIPO.cnN
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
                    --  RA.Fltributacao = PKGPAG_TIPO.cnN AND RA.Flconsignacao = PKGPAG_TIPO.cnN*/ --
                     RA.FlConsignacao = PKGPAG_TIPO.cnN
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
                    -- RA.Fltributacao = PKGPAG_TIPO.cnN  AND RA.Flconsignacao = PKGPAG_TIPO.cnN */ -- Anterior a 15/06
                     RA.FlConsignacao = PKGPAG_TIPO.cnN
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
                   rSuplementar.cdhistsentencajudicial);

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

        IF pFolhaSuplementar.CdFolhaPagamento = pFolhaRecalculo.CdFolhaPagamento THEN

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

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Erro ao processar suplementar: ' || SQLERRM,
                              PKGPAG_VAR.vgCdVinculo);

  END;

  FUNCTION FLancamentoDifMes(pFolha            IN PKGPAG_TIPO.rFolha,
                             pTabCdFolhaDifMes IN tTabFolhaPagamentoDifMes,
                             prVinculo         IN PKGPAG_TIPO.rVinculo)
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
 
    vBaseSufixo      := 80;
    vCdTipoOrigemRub := 20;

    vTemDif := FALSE;

    vCdRubAgr06_0328 := PKGPAG_GERAL.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
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
                   PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
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

          PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => prVinculo.CdVinculo,
                                                pCdRelacaoVinculo     => NVL(PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                                             1),
                                                pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
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
        PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => prVinculo.CdVinculo,
                                              pCdRelacaoVinculo     => NVL(PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                                           1),
                                              pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
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
        PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => prVinculo.CdVinculo,
                                              pCdRelacaoVinculo     => NVL(PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                                           1),
                                              pCdHistRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
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
      IF NOT vTemDifFol AND (PKGPAG_GERAL.fDtInclusaoCef(PRVINCULO.CdVinculo) IS NULL OR
                             PKGPAG_GERAL.fDtInclusaoCef(PRVINCULO.CdVinculo) <= pFolha.DtCalculoAnt)
         THEN
        EXIT;
      END IF;

    END LOOP;

    RETURN vTemDif;

  END;

  FUNCTION FOBtemFolhaDifMes(pFolha IN PKGPAG_TIPO.rFolha)
    RETURN tTabFolhaPagamentoDifMes IS

    vTabFolhaPagamentoDifMes tTabFolhaPagamentoDifMes;

  BEGIN
 
    FOR rec IN (select Mes, fa.CdFolhaPAgamento, fn.DtCalculo
                  FROM (Select level as Mes
                          FROM DUAL
                        CONNECT BY LEVEL < pFolha.NuMesReferencia) TMes
                 INNER JOIN EPagFolhaPagamento fa
                    ON fa.CdOrgao = pFolha.CdOrgao
                   AND fa.NuAnoReferencia = pFolha.NuAnoReferencia
                   AND fa.NuMesReferencia = TMes.Mes
                   AND fa.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes
                   AND fa.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento
                 INNER JOIN EPagFolhaPagamento fn
                    ON fn.CdOrgao = pFolha.CdOrgao
                   AND fn.NuAnoReferencia = pFolha.NuAnoReferencia
                   AND fn.NuMesReferencia = TMes.Mes
                   AND fn.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal
                   AND fn.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento
                   AND fn.FlCalculoDefinitivo = 'S') LOOP

      vTabFolhaPagamentoDifMes(rec.Mes).CdFolhaDifMes := rec.CdFolhaPagamento;
      vTabFolhaPagamentoDifMes(rec.Mes).DtCalculo := rec.DtCalculo;

    END LOOP;

    RETURN vTabFolhaPagamentoDifMes;

  END;

  PROCEDURE PInicializaVariaveis(pVinculo   IN PKGPAG_TIPO.rVinculo,
                                 pDtCalculo IN DATE) IS

    x INTEGER;

  BEGIN
 
    -- Constantes

    PKGPAG_VAR.vgVlTotalDescontos := 0;

    PKGPAG_VAR.vgVlTotalProventos := 0;

    PKGPAG_VAR.vgVlTotalDescontosFacult := 0;

    PKGPAG_VAR.vgVlBase1467 := 0;

    PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;

    pkgpag_var.vNuDiasAuxAlimNaoDesc := 0;

    pkgpag_var.vDescAuxAlimNaoDesc := null;

    PKGPAG_VAR.vgVlIntegralIPREV := 0;

    PKGPAG_VAR.bPossuiDisposicao := FALSE;

    IF PKGPAG_VAR.vgPercentAcumATS.COUNT > 0 THEN

      x := PKGPAG_VAR.vgPercentAcumATS.FIRST;

      WHILE x IS NOT NULL LOOP

        PKGPAG_VAR.vgPercentAcumATS(x) := 0;

        x := PKGPAG_VAR.vgPercentAcumATS.NEXT(x);

      END LOOP;

    END IF;

    PKGPAG_VAR.vPagaSitDisposicao := 'NAO(EFETIVO/DISPOSICAO)';

    PKGPAG_VAR.bProcessaBloqueio := FALSE;

    PKGPAG_VAR.vgQtFaltas := 0;

    PKGPAG_VAR.vgCdEstruturaCarreira := NULL;

    PKGPAG_VAR.bFlPossuiProventos := FALSE;

    PKGPAG_VAR.vgPercentPensaoNaoPrev := 0;

    PKGPAG_VAR.vgPercDecJudMargem := PKGPAG_CNS.FPercDecJudMargem(pVinculo.CdVinculo,
                                                                  PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                  PKGPAG_VAR.vgFolha.NuMesReferencia);

    PKGPAG_VAR.bReprocessou13Sal := FALSE;

    PKGPAG_VAR.bPossuiLancTesouraria := FALSE;

    PKGPAG_VAR.vgMediaCHOHoraAtividade := NULL;

    PKGPAG_VAR.vgCdRubricaHoraPlantao := 0;

    PKGPAG_VAR.vgNuIndiceHoraPlantao := 0;

    PKGPAG_VAR.bSemIntersticio := FALSE;

    PKGPAG_VAR.vPercentualTotalATS.DELETE;

    PKGPAG_VAR.vgListaRelTrab.DELETE;

    PKGPAG_VAR.vgListaContribSind.DELETE;

    ----------------------------------------------------------------------------------------
    -- Aplica reducao por afastamento remunerado -> Fazer leitura unica e armazenar na PRE
    ----------------------------------------------------------------------------------------

    PKGPAG_VAR.vgVlPercentReducao := PKGPAG_GERAL.FPercentReducaoSalario(pVinculo.CdVinculo,
                                                                         PKGPAG_VAR.vgFolha.DtInicioMes,
                                                                         PKGPAG_VAR.vgFolha.DtFimMes,
                                                                         pDtCalculo);

    ------------------------------------------------------------
    -- Incializa variaveis dos eventos que sao processados
    ------------------------------------------------------------

    PKGPAG_VAR.vgCdRubAbonoPecuniario := NULL;

    PKGPAG_VAR.vgCdRubAbono13Ferias := NULL;

    PKGPAG_VAR.vgCdRubAdiantSalFerias := NULL;

    PKGPAG_VAR.vgCdRubValeTransporte := NULL;

    PKGPAG_VAR.vgCdRubDevUmTercoFerias := NULL;

    PKGPAG_VAR.vgCdRubDifUmTercoFerias := NULL;

    PKGPAG_VAR.vgCdRubricaRecisao13 := 0;

    PKGPAG_VAR.vgCdRubricaRecisao13CTISP := 0;

    PKGPAG_VAR.vgCdRubricaRecisao13PENSAO := 0;

    -- TODO: Text="Excluir PKGPAG_VAR.bPossuiObito, PKGPAG_VAR.vCdPessoa, PKGPAG_VAR.vgCdOrgaoVinculo, PKGPAG_VAR.vgCdVinculo"
    PKGPAG_VAR.vgCdOrgaoVinculo := pVinculo.CdOrgao;

    PKGPAG_VAR.vCdPessoa := pVinculo.CdPessoa;

    PKGPAG_VAR.bPossuiObito := pVinculo.bPossuiObito;

    PKGPAG_VAR.vgCdVinculo := pVinculo.CdVinculo;

    PKGPAG_VAR.vgVlRefTetoDecJud := NULL;

    PKGPAG_VAR.vgCdValRefTetoDecJud := NULL;

    PKGPAG_VAR.vCdRelacaoTrabalhoCCO := NULL;

    PKGPAG_VAR.vCdOpcaoRemuneracaoCCO := NULL;

    PKGPAG_VAR.vgValorFixoCEF.vlFixo := NULL;

    PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria := 0;

    PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes := FALSE;

    PKGPAG_VAR.bPossuiAfastRemunUltDiaMes := FALSE;

    PKGPAG_VAR.vgCdRubFeriasIndenizadas := NULL;

    PKGPAG_VAR.vgCdRubFeriasIndenUmTerco := NULL;

    PKGPAG_VAR.vgCdRubFeriasIndenizadasACTSJC := NULL;

    PKGPAG_VAR.vgCdRubFeriasIndenizadasVinc := NULL;

    PKGPAG_VAR.vgPercentATS :=  vvgPercentATS;

    PKGPAG_VAR.vgCdRubricaDevAnt13 := NULL;

    PKGPAG_VAR.vgCdRubUmTercoFerias := NULL;

    PKGPAG_VAR.vgCdRubDifAbonoPecuniario := NULL;

    PKGPAG_VAR.vgCdRubFeriasFGTS := NULL;

    PKGPAG_VAR.vgCdRubDescTetoGovernador := NULL;

    PKGPAG_VAR.vgCdRubDescTetoGovernador13 := NULL;

    PKGPAG_VAR.vgCdRubDescPlanSauAgr       := NULL;

    PKGPAG_VAR.vgCdEventoDescCoPart        := NULL;

    PKGPAG_VAR.vgCdRubDescPlanSauTit       := NULL;

    pkgpag_var.vgCdRubDescCPSM             := NULL;

    pkgpag_var.vgDtInicioConcessaoAbonoPerm := NULL;

  END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Processamento do Vinculo - Parte Erario
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarVincCalcErario(rVinculo             IN PKGPAG_TIPO.rVinculo,
                                     pFlCalculoDefinitivo IN CHAR) IS

  BEGIN
 
    PKGPAG_GERAL.PLogProcIni('CAL040305','Atu Ret/Rep');

    IF PKGPAG_VAR.vgFolha.CdTipoFolha IN
       (PKGPAG_TIPO.cnTpFolhaNormal,
        PKGPAG_TIPO.cnTpFolhaBolsista,
        PKGPAG_TIPO.cnTpFolhaResidente,
        PKGPAG_TIPO.cnTpFolhaPesquisador,
        PKGPAG_TIPO.cnTpFolhaConvenio,
        PKGPAG_TIPO.cnTpFolhaServAfast,
        PKGPAG_TIPO.cnTpFolhaCtisp)
       OR PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento = 765  -- FOLHA PDVI CIASC
       OR PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento = 1285 -- FOLHA PDVI CIDASC
       OR PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento = 1706 -- FOLHA PDVI EPAGRI

     THEN

      IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal THEN

        IF pFlCalculoDefinitivo = 'S' THEN

          PKGPAG_LF.PAtualizaHistoricoLancamento(PKGPAG_VAR.vgFolha,
                                                 rVinculo.CdVinculo);

          PKGPAG_POS.PAtualizaEventoVinculo(pCdVinculo    => rVinculo.CdVinculo,
                                            pFolha        => PKGPAG_VAR.vgFolha,
                                            pCdTipoEvento => 1); -- Contribuicao Sindical

          PKGPAG_PC.PAtualizaSituacaoRetro(pCdVinculo => rVinculo.CdVinculo,
                                           pFolha     => PKGPAG_VAR.vgFolha);

          PKGPAG_PC.PAtualizaSituacaoCompensacao(pCdVinculo => rVinculo.CdVinculo,
                                                 pFolha     => PKGPAG_VAR.vgFolha);

        END IF;

        PKGPAG_PC.PAtualizaSituacaoErario(pCdVinculo => rVinculo.CdVinculo,
                                          pFolha     => PKGPAG_VAR.vgFolha);

      ELSIF (PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl AND
            pFlCalculoDefinitivo = 'S') THEN


        PKGPAG_RT.PAtualizaParcelaRetroativo(pFolha     => PKGPAG_VAR.vgFolha,
                                             pCdVinculo => rVinculo.CdVinculo);

        PKGPAG_PC.PAtualizaSituacaoRetro(pCdVinculo => rVinculo.CdVinculo,
                                         pFolha     => PKGPAG_VAR.vgFolha);

        PKGPAG_PC.PAtualizaSituacaoCompensacao(pCdVinculo => rVinculo.CdVinculo,
                                               pFolha     => PKGPAG_VAR.vgFolha);

      else
        null;
      END IF;

    END IF;

    PKGPAG_GERAL.PLogProcFim('CAL040305');

  END;

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Processamento do Vinculo - Parte Integral
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarVincCalcIntegral(pCalculo             IN rCalculo,
                                       rVinculo             IN OUT PKGPAG_TIPO.rVinculo,
                                       pDtCalculo           IN DATE,
                                       pFlCalculoDefinitivo IN CHAR,
                                       pFlPagaAdiantamento  IN CHAR,
                                       pTributacao      IN OUT NOCOPY PKGPAG_TRIBUTACAO.rTributacao) IS

    /*TYPE rRelVinc IS RECORD(
      CdRelacaoTrabalho       INTEGER,
      DtInicio                DATE,
      CdUnidadeOrganizacional INTEGER,
      NuCargaHoraria          NUMBER(7,4));
    vRelVinc rRelVinc;*/

vmsg varchar2(1000);

    vQtdeNaoLancados          INTEGER;
    vSgOrgao                  VARCHAR2(20);
    bGerouTotalizadoras       BOOLEAN;
    vvlBaseBaixa              NUMBER(13, 2);
    vVlDesc050524             NUMBER(13,2);
    vVlNaoDesc050524          number(13,2);
    vVlDescReal050524         number(13,2);
    vVlDescFaltas             number(13,2);
    vDtInicioDireito          DATE;
    vDtInclusao               DATE;
    vCdRetorno                INTEGER DEFAULT 1;
    i                         INTEGER;
    vCdExpressaoFormula       INTEGER;
    vTemDifMes                BOOLEAN;
    vNuFaltas                 tFalta;
    vNuMEsFalta               INTEGER;
    vAfast                    PKGPAG_TIPO.tAfastamento;
    vValorCalcRubrica         PKGPAG_TIPO.tValorCalculoRubrica;
    vvlBaseIprev13SalResc     pkgpag_tipo.rvalorpagamento;

    PROCEDURE pDifVlPagamentoVincSemRemun(pCdVinculo        IN INTEGER,
                                       pCdFolhaPagamento IN INTEGER,
                                       pNuAnoReferencia  IN INTEGER,
                                       pNuMesReferencia  IN INTEGER,
                                       pCdTipoFolha      IN INTEGER,
                                       pCdTipoCalculo    IN INTEGER) IS
    BEGIN
 
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
                          AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
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
                          AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS                 --
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
 
      IF rVinculo.DtDesligamento < PKGPAG_VAR.vgFolha.DtInicioMes THEN

        IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaBolsista THEN

          IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> PKGPAG_TIPO.cnRelEstagiario THEN

            RETURN FALSE;

          END IF;

        ELSIF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaResidente THEN

          IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> PKGPAG_TIPO.cnRelResidente THEN

            RETURN FALSE;

          END IF;

        ELSIF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaPesquisador THEN

          IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> PKGPAG_TIPO.cnRelPesquisador THEN

            RETURN FALSE;

          END IF;

        ELSE

          IF PKGPAG_VAR.vgFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaRescisao AND
             PKGPAG_VAR.vgParamPagamento.FlPagaRecisaoFolhaEspec = 'S' THEN

            RETURN FALSE;

          END IF;

          IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento IN
             (PKGPAG_TIPO.cnRelEstagiario,
              PKGPAG_TIPO.cnRelResidente,
              PKGPAG_TIPO.cnRelPesquisador) THEN

            RETURN FALSE;

          END IF;

        END IF;

      ELSIF rVinculo.DtDesligamento >= PKGPAG_VAR.vgFolha.DtInicioMes THEN

        IF PKGPAG_VAR.vgFolha.CdTipoFolha NOT IN
           (PKGPAG_TIPO.cnTpFolhaBolsista,
            PKGPAG_TIPO.cnTpFolhaResidente,
            PKGPAG_TIPO.cnTpFolhaPesquisador,
            PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
            pkgpag_tipo.cnTpFolhaRescisaoPesquisador,
            PKGPAG_TIPO.cnTpFolhaConvenio) AND
           PKGPAG_VAR.vgBOL.COUNT > 0 THEN

          RETURN FALSE;

        ELSIF PKGPAG_VAR.vgFolha.CdTipoFolha IN
              (PKGPAG_TIPO.cnTpFolhaBolsista,
               PKGPAG_TIPO.cnTpFolhaResidente,
               PKGPAG_TIPO.cnTpFolhaPesquisador) AND
              (PKGPAG_VAR.vgCEF.COUNT > 0 OR PKGPAG_VAR.vgCCO.COUNT > 0 OR
              PKGPAG_VAR.vgAPO.COUNT > 0) THEN

          RETURN FALSE;

        ELSIF PKGPAG_VAR.vgFolha.CdTipoFolha <>
              PKGPAG_TIPO.cnTpFolhaRescisao AND PKGPAG_VAR.vgParamPagamento.FlPagaRecisaoFolhaEspec =
              PKGPAG_TIPO.cnS THEN

          RETURN FALSE;

        else
          null;
        END IF;

      ELSE

        IF rVinculo.DtDesligamento IS NULL AND
           PKGPAG_VAR.vgFolha.CdTipoFolha IN
           (PKGPAG_TIPO.cnTpFolhaRescisao) THEN

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
       if nvl(PKGPAG_VAR.vgIndiceFaltasMesAnterior,0) < 30 then
         -- Solicitacao de Sustentacao  #79983
         -- 12316/2018 - FALTAS PRIORIDADE SOBRE DESC SC SAUDE
         -- Somente descontar plano de saude se o total de faltas do mes anterior nao estiver zerando o contra cheque.
         -- na rotina de liquido negativo eh feito um ajuste especifico nesta rubrica de faltas e o calculo
         -- acabava compensando as diferencas, ou seja, permitia o desconto do scsaude e depois ajustava a diferenca no
         -- desconto de faltas.

         -- Solicitacao de Sustentacao #80157
         -- 12458/2018 - FOLHA - - PROCESSAMENTO DA SCSAUDE
         -- Alterada ordem de calculo do SCSAUDE para apos a tributacao

         PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento, pCdVinculo);

         if PKGPAG_VAR.vgVlTotalProventos > PKGPAG_VAR.vgVlTotalDescontos
           or PKGPAG_VAR.vgFolha.cdorgao = 33 then

            pkgpag_pos.pDescontoPlanoSaude(pCdVinculo);

        end if;

      end if;

    END;

  BEGIN

    PKGPAG_VAR.vgFaseCalculo := PKGPAG_TIPO.cnFaseCalculoIntegral;

    PKGPAG_VAR.bTemDireitoLancFin := TRUE;

    IF PKGPAG_VAR.vgFolha.cdtipofolha = pkgpag_tipo.cnTpFolhaServAfast THEN

        PAnulaAfastTempNaoRemun(pCdVinculo => rVinculo.CdVinculo,
                                               pDtCalculo => pkgpag_var.vgFolha.dtCalculo,
                                               pcdAgrupamento => pkgpag_var.vgFolha.cdAgrupamento);

    END IF;

    IF PKGPAG_VAR.vgFolha.CdTipoCalculo =
       PKGPAG_TIPO.cnTpCalculoRecalculoMes AND
       PKGPAG_VAR.vgFolha.FlOrgaoImplantado = 'N' AND
       TRUNC(rVinculo.DtInclusao) > pDtCalculo THEN

      RETURN;

    END IF;

    ----------------------------------------------------------------
    -- Armazena vinculo para execucao de pos-calculo
    ----------------------------------------------------------------

    PKGPAG_VAR.vgVinculo := rVinculo;

    ----------------------------------------------------------------
    -- Armazena as relacoes vinculo vigentes
    -- Obs: Chama mesmo se o vinculo estiver desligado para inicializar
    --      variaveis
    ----------------------------------------------------------------

    PKGPAG_GERAL.PLogProcIni('CAL040302','Armz Rel Vinc');

    PKGPAG_GERAL.PArmazenaRelacoesVinculo(rVinculo.CdVinculo);

    -- Inicializar Tributacao
    
    PKGPAG_TRIBUTACAO.PInicializarVinculo (pTributacao => pTributacao);   

    -- SIG-5785
    -- Rubrica 10-0356 na folha normal - Folha CTISP DPESC

    if pkgpag_var.bPossuiCtisp and
      PKGPAG_VAR.vgFolha.CdTipoFolha not IN
       (pkgpag_tipo.cnTpFolhaCtisp, pkgpag_tipo.cnTpFolhaCtisp13) and
      PKGPAG_VAR.vgFolha.CdAgrupamento = 176

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

    PKGPAG_GERAL.PLogProc('CAL040302','CAL040303','Bloco Intermed');

    -------------------------------------------------------------------------
    -- Tratamento do bloqueio de credito
    -------------------------------------------------------------------------

    PKGPAG_GERAL.PLogProcIni('CAL04030301','Trata Bloqueio');

    PKGPAG_GERAL.PTrataBloqueioCredito;

    IF PKGPAG_VAR.vgVinculo.FlPagamentoBloqueado = 'A'
      AND PKGPAG_VAR.vgFolha.CdOrgao = 33
      THEN
        PKGPAG_VAR.vgVinculo.FlPagamentoBloqueado := 'S';
        GOTO FIM_LOOP;

    END IF;

    rVinculo.FlPagamentoBloqueado := PKGPAG_VAR.vgVinculo.FlPagamentoBloqueado;

    PKGPAG_GERAL.PLogProcFim('CAL04030301');

    IF NVL(rVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax) >=
       PKGPAG_VAR.vgFolha.DtInicioMes AND
       rVinculo.CdSituacaoPrevidenciaria = 0 AND
       (PKGPAG_VAR.vgCEF.COUNT > 0 OR PKGPAG_VAR.vgCCO.COUNT > 0 OR
        PKGPAG_VAR.vgAPO.COUNT > 0 OR PKGPAG_VAR.vgBOL.COUNT > 0) THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'O vinculo nao possui situacao previdenciaria vigente.',
                              PKGPAG_VAR.vgCdVinculo);

      GOTO FIM_LOOP;

    END IF;

    -----------------------------------------------------------
    -- Tratamento de folha de rescisão
    -----------------------------------------------------------

    IF PKGPAG_VAR.vgFolha.cdAgrupamento not in (1, 134, 176, 276) THEN

        PKGPAG_GERAL.PLogProcIni('CAL04030302','Trata Rescisão');

        -- Não paga rescisão para quem não tem registro de rescisão
        IF  PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaRescisao, PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                                               pkgpag_tipo.cnTpFolhaRescisaoPesquisador) -- Folha de Rescisão
            AND NOT FPossuiRescisao(PKGPAG_VAR.vgCdVinculo) AND pkgpag_var.vgFolha.CdTipoFolhaPagamento NOT IN (1706,1707,765,1285,1686) THEN


          PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  PKGPAG_VAR.vCdPessoa,
                                  'Vinculo NÃO possui RESCISÃO. Matrícula: ' || FDadosServidorDesligado(PKGPAG_VAR.vgCdVinculo),
                                  PKGPAG_VAR.vgCdVinculo,
                                  2);

          GOTO FIM_LOOP;

        END IF;

        -- Não paga rescisão para quem já tem folha de rescisão fechada
        /*IF PKGPAG_VAR.vgFolha.CdTipoFolha = 2 -- Folha de Rescisão
           AND FPossuiFolhaRescisao(PKGPAG_VAR.vgCdVinculo) THEN


          PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  PKGPAG_VAR.vCdPessoa,
                                  'Vinculo já possui FOLHA DE RESCISÃO fechada. Matrícula: ' || FDadosServidorDesligado(PKGPAG_VAR.vgCdVinculo),
                                  PKGPAG_VAR.vgCdVinculo,
                                  2);

          GOTO FIM_LOOP;

        END IF;*/

        -- Não paga rescisão em folha diferente de folha de rescisão
        IF PKGPAG_VAR.vgFolha.CdTipoFolha NOT IN (PKGPAG_TIPO.cnTpFolhaRescisao, PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                                                  pkgpag_tipo.cnTpFolhaRescisaoPesquisador,PKGPAG_TIPO.cnTpFolhaFunebre) -- Folha de Rescisão
           AND FPossuiRescisao(PKGPAG_VAR.vgCdVinculo) AND pkgpag_var.vgFolha.CdTipoFolhaPagamento NOT IN (1706,1707,765,1285,1686)
           AND NVL(rVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax) >= PKGPAG_VAR.vgFolha.dtCalculoAnt THEN


          PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  PKGPAG_VAR.vCdPessoa,
                                  'Vinculo possui RESCISÃO. Matrícula: ' || FDadosServidorDesligado(PKGPAG_VAR.vgCdVinculo),
                                  PKGPAG_VAR.vgCdVinculo);

          GOTO FIM_LOOP;

        END IF;

        PKGPAG_GERAL.PLogProcFim('CAL04030302');

    END IF;
    -------------------------------------------------------------------------

    IF NOT PKGPAG_VAR.bCalculaVinculo THEN

      RETURN;

    END IF;

    -------------------------------------------------------------------------------------
    -- Seta Flags para saber se o vinculo possui rubricas isentas
    -- Obs: Variaveis Utilizadas na tributacao e na execucao de formulas
    -------------------------------------------------------------------------------------

    PKGPAG_GERAL.PLogProc('CAL040303','CAL040304', 'Set Trib');

    IF pkgpag_var.vgFolha.cdtipofolha <> PKGPAG_TIPO.cnTpFolhaInstPensao
       THEN

        PKGPAG_TRIBUTACAO.PSetaRubricasIsentas(pFolha     => PKGPAG_VAR.vgFolha,
                                               pCdVinculo => rVinculo.CdVinculo);

    END IF;
    ---------------------------------------------------------------------------------
    --  Em virtude do sistema legado, pode ocorrer de uma pessoa possuir
    --  dois vinculos vigentes no mesmo orgao, sendo um com relacao de bolsista.
    --  A condicao abaixo impede de calcular o vinculo caso a folha seja de bolsista
    --  e o vinculo nao possua relacao de bolsista no vinculo
    ---------------------------------------------------------------------------------

    IF (PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaResidente) AND
       PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
       PKGPAG_TIPO.cnRelResidente) OR
       (PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaBolsista) AND
       PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
       PKGPAG_TIPO.cnRelEstagiario) OR
       (PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaPesquisador) 
        AND PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> PKGPAG_TIPO.cnRelPesquisador) THEN

      GOTO FIM_LOOP;

    END IF;

    PKGPAG_GERAL.PLogProc('CAL040304','CAL040305','Rel Principal');

    IF (PKGPAG_VAR.vgRelVincPrincipal.CdHist IS NULL AND
       (rVinculo.DtDesligamento >= PKGPAG_VAR.vgFolha.DtInicioMes OR
       rVinculo.DtDesligamento IS NULL) AND
       (PKGPAG_VAR.vgCEF.COUNT > 0 OR PKGPAG_VAR.vgCCO.COUNT > 0 OR
       PKGPAG_VAR.vgAPO.COUNT > 0 OR PKGPAG_VAR.vgBOL.COUNT > 0)) THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'O vinculo nao possui relacao de vinculo principal.',
                              PKGPAG_VAR.vgCdVinculo);

    ELSE

      ----------------------------------------------------------------------------
      -- Retorna 0 caso o servidor nao esteja afastado o mes inteiro
      -- Caso esteja afastado, gera a capa de lote com o motivo de afastamento
      ----------------------------------------------------------------------------

      PKGPAG_GERAL.PLogProcIni('CAL04030501','Afast/Dec Jud');

      PKGPAG_VAR.vMotAfast := FAfastSemRemun(rVinculo.CdVinculo,
                                             PKGPAG_VAR.vgFolha.DtInicioMes,
                                             PKGPAG_VAR.vgFolha.DtFimMes,
                                             PKGPAG_VAR.vDtCalculo);

      -----------------------------------------------------------------------------
      -- Criar variaveis para os tipos de afastamento e periodos
      -----------------------------------------------------------------------------

        PKGPAG_VAR.vgNuDiasAfastRemun := 0;

        PKGPAG_VAR.vgAfastTempRemun := vAfast;

        pkgpag_var.vgAfastAuxAlimentacao := vAfast;

        PKGPAG_VAR.vgAfastTempRemun := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                           PKGPAG_VAR.vgFolha.DtInicioMes,
                                                           PKGPAG_VAR.vgFolha.DtFimMes,
                                                           PKGPAG_VAR.vDtCalculo,
                                                           'R');

        PKGPAG_VAR.vgAfastAnulado := vAfast;

        PKGPAG_VAR.vgAfastAnulado := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                           PKGPAG_VAR.vgFolha.DtInicioMes,
                                                           PKGPAG_VAR.vgFolha.DtFimMes,
                                                           PKGPAG_VAR.vDtCalculo,
                                                           'A');   --Anulados

        PKGPAG_VAR.vgAfastTempRemunMesAnt := vAfast;

        PKGPAG_VAR.vgAfastTempRemunMesAnt := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                           ADD_MONTHS(PKGPAG_VAR.vgFolha.DtInicioMes, -1),
                                                           last_day(PKGPAG_VAR.vgFolha.DtCalculoAnt),
                                                           PKGPAG_VAR.vDtCalculo,
                                                           'R');

        PKGPAG_VAR.vgNuDiasAfastSemRemun := 0;

        PKGPAG_VAR.vgNuDiasAfastRetroativo := 0;

        PKGPAG_VAR.vgNuDiasAfastAuxAlimRet := 0;

        PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual := 0;

        PKGPAG_VAR.vgAfastTempNaoRemun := vAfast;

        PKGPAG_VAR.vgAfastTempNaoRemun := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                              PKGPAG_VAR.vgFolha.DtInicioMes,
                                                              PKGPAG_VAR.vgFolha.DtFimMes,
                                                              PKGPAG_VAR.vDtCalculo,
                                                              'N');

        PKGPAG_VAR.vgNuDiasAfastDefinitivo := 0;

        PKGPAG_VAR.vgAfastDefinitivo := vAfast;

        PKGPAG_VAR.vgAfastDefinitivo := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                            PKGPAG_VAR.vgFolha.DtInicioMes,
                                                            PKGPAG_VAR.vgFolha.DtFimMes,
                                                            PKGPAG_VAR.vDtCalculo,
                                                            'D');

      PKGPAG_VAR.vgNuDiasTrabalhados := 30 - NVL(PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual,0);

      PKGPAG_VAR.vgNuDiasAfastRelVinc := 0;

      PKGPAG_VAR.vgAfastRelVinc := vAfast;

      PKGPAG_VAR.vgAfastRelVinc := FAfastamentoVinculo(rVinculo.CdVinculo,
                                                       PKGPAG_VAR.vgFolha.DtInicioMes,
                                                       PKGPAG_VAR.vgFolha.DtFimMes,
                                                       PKGPAG_VAR.vDtCalculo,
                                                       'V',
                                                       PKGPAG_VAR.vgRelVincPrincipal.CdHist);

      -- Caso o vínculo possua rescisão préviA a folha anterior
      IF PKGPAG_VAR.vgNuDiasAfastDefinitivo >= 30 AND
       rVinculo.DtDesligamento <= PKGPAG_VAR.vgFolha.dtCalcULOAnt AND
       PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
       (PKGPAG_VAR.vgCEF.COUNT > 0 OR PKGPAG_VAR.vgCCO.COUNT > 0 OR
       PKGPAG_VAR.vgAPO.COUNT > 0 OR PKGPAG_VAR.vgBOL.COUNT > 0) THEN

         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'O vinculo possui rescisão prévia ao calculo anterior.',
                              PKGPAG_VAR.vgCdVinculo);
         GOTO FIM_LOOP;

      END IF;
      ---------------------------------------------------------------------------------------------
      -- Busca o valor do Bloqueio de Remuneracao - Teto
      -- Caso possua alguma decisao judicial para a rubrica do Teto do Governador
      -- busca o valor do teto/codigo do valor de referencia na sentenca do contrario seleciona da
      -- tabela de valor de referencia
      ---------------------------------------------------------------------------------------------

      IF PKGPAG_GERAL.FPossuiDecisaoJudicial(pCdVinculo       => rVinculo.CdVinculo,
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
      -- Carrega as informacoes de decisoes judiciais que interferem em retroativos
      -- e nas tributacoes
      ---------------------------------------------------------------------------------------------

      PKGPAG_RT.vgDecJudRetro := PKGPAG_RT.FDecJudIsencaoTributacao(PKGPAG_VAR.vgFolha,
                                                                    rVinculo.CdVinculo);

      -----------------------------------------------------------------------
      -- Armazena os codigos das rubricas 06-0915; 06-0926; 02,10,12-914 para
      -- verificar na leitura dos retroativos se existe decisao judicial
      -- mandando isentar o IPREV, o que implica a nao geracao das mesmas
      -----------------------------------------------------------------------
      PKGPAG_RT.SetaRubDifDescIPREV(pCdAgrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento);

      PKGPAG_GERAL.PLogProc('CAL04030501','CAL04030502','CapaLote');

      ----------------------------------------------------------------------------
      -- Gera a capa de lote, caso o vinculo esteja afastado o mes todo
      ----------------------------------------------------------------------------

      IF PKGPAG_VAR.vMotAfast.InAfastado = PKGPAG_TIPO.cnAfastadoMesTodo THEN

        PKGPAG_GERAL.PGeraCapaLote(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                   pCdVinculo            => rVinculo.CdVinculo,
                                   pFlAtivo              => pkgpag_geral.fflativo(rvinculo.CdVinculo, rvinculo.CdSituacaoPrevidenciaria),
                                   pMotAfast             => PKGPAG_VAR.vMotAfast,
                                   pFlPagamentoBloqueado => rVinculo.FlPagamentoBloqueado);

      END IF;

      PKGPAG_GERAL.PLogProcFim('CAL04030502');

      -------------------------------------------------------------------------------
      -- Caso esteja afastado sem remuneracao o mes todo e possua retroativo
      -- ou desligado antes do inicio do mes
      -------------------------------------------------------------------------------

      IF (PKGPAG_VAR.vMotAfast.InAfastado = PKGPAG_TIPO.cnAfastadoMesTodo AND
         PKGPAG_GERAL.FPossuiLancRetroativo(pCdVinculo => rVinculo.CdVinculo,
                                                             pFolha     => PKGPAG_VAR.vgFolha) AND
         rVinculo.CdSituacaoPrevidenciaria <> 2) OR
         (PKGPAG_VAR.vMotAfast.InAfastado IN
         (PKGPAG_TIPO.cnAfastadoNao, PKGPAG_TIPO.cnAfastadoParcial)) OR

         (rVinculo.DtDesligamento < PKGPAG_VAR.vgFolha.DtInicioMes) OR

        -- CIASC/CIDASC, PROCESSA PARA TODOS OS AFASTADOS
         (
           PKGPAG_VAR.vgCdRubAgrupDescDiasAfast > 0
           AND PKGPAG_VAR.vMotAfast.InTipoAfastamento <> 'D'
           AND (
             (PKGPAG_VAR.vgFolha.CdAgrupamento = 2 AND PKGPAG_VAR.vMotAfast.cdChaveMotivo <> 9267)
             OR (
               PKGPAG_VAR.vgFolha.CdAgrupamento = 4
               AND PKGPAG_VAR.vMotAfast.FlProcessaNaoPaga = 'S'
             )
           )
         )
         OR (
           PKGPAG_VAR.vMotAfast.InTipoAfastamento = 'D'
           AND (PKGPAG_VAR.vgFolha.cdtipofolha IN (2, 23) OR (PKGPAG_VAR.vgFolha.CdAgrupamento IN (1,7,276) AND PKGPAG_VAR.vgFolha.cdtipofolha = 1))
           AND (PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND PKGPAG_VAR.vgFolha.DtFimMes)
         )
         OR

        -- PROCESSA PARA oRGaOS QUE PAGAM AUXILIO DOENcA E MOTIVO AFASTAMENTO AUXILIO DOENcA. (ex: SANTUR, EPAGRI)
         (PKGPAG_VAR.vMotAfast.InTipoAfastamento <> 'D' AND
         (PKGPAG_VAR.vMotAfast.FlAuxilioDoenca = PKGPAG_TIPO.cnS OR
         PKGPAG_VAR.vMotAfast.FlAcidenteTrabalho = PKGPAG_TIPO.cnS) AND
         PKGPAG_VAR.vgParamOrgao.FlAuxilioDoenca = PKGPAG_TIPO.cnS) OR

         (PKGPAG_VAR.vMotAfast.InPagaLancamento = PKGPAG_TIPO.cnS) OR

         (pkgpag_var.vgrelvincprincipal.cdreltrabpagamento = pkgpag_tipo.cnrelact AND
          PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN
          PKGPAG_VAR.vgFolha.DtInicioMes AND PKGPAG_VAR.vgFolha.DtFimMes)

      THEN

        ------------------------------------------------------------------------------
        --  PKGPAG_VAR.vgCdRubAgrupDescDiasAfast > 0
        -- Indica que se o evento esta parametrizado, o servidor devera ser calculado
        ------------------------------------------------------------------------------

        ------------------------------------------------------------------------------
        -- Armazena as rubricas que nao devem ser processadas pelos Eventos em
        -- decorrencia da existencia de lancamentos financeiros ou decisoes judiciais
        ------------------------------------------------------------------------------

        PKGPAG_VAR.vListaRubricas := PKGPAG_GERAL.FRubricasLancamento(pCdVinculo => rVinculo.CdVinculo,
                                                                      pFolha     => PKGPAG_VAR.vgFolha);

        PKGPAG_VAR.vgLancComplementar := PKGPAG_GERAL.FRubricasLancComplementar(pCdVinculo => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                                                pFolha     => PKGPAG_VAR.vgFolha);

        PKGPAG_GERAL.PLogProcIni('CAL04030503','Per Aquis/Dados Banc');

        ------------------------------------------------------------------------------
        -- Conquista/Regera periodos aquisitivos de tempo de servico
        ------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal THEN

          BEGIN

            PKGPAG_PC.PGeraPerAquisTempServ(pVinculo         => rVinculo,
                                            pCdOrgao         => PKGPAG_VAR.vgFolha.CdOrgao,
                                            pDtInicioMes     => PKGPAG_VAR.vgFolha.DtInicioMes,
                                            pDtFimMes        => PKGPAG_VAR.vgFolha.DtFimMes,
                                            pTpOrigemChamada => 1,
                                            pFlFazRollback   => 'S',
                                            pCdRetorno       => vCdRetorno);

          EXCEPTION
            WHEN OTHERS THEN

              PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
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

        IF (PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal OR
            PKGPAG_VAR.VGFOLHA.CDTIPOFOLHA = PKGPAG_TIPO.CNTPFOLHACTISP OR
            PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias)
            AND NVL(PKGPAG_VAR.vMotAfast.InTipoAfastamento,'') <> 'D'  THEN

            PKGPAG_PC.PGeraPerAquisFerias(pVinculo       => rVinculo,
                                          pCdAgrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                          pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                          pDtInicioMes   => PKGPAG_VAR.vgFolha.DtInicioMes,
                                          pDtFimMes      => PKGPAG_VAR.vgFolha.DtFimMes);


        END IF;

        ----------------------------------------------------------------------
        -- Verificacoes para bolsistas e residentes
        ----------------------------------------------------------------------

        --RETIRAR DO PROCESSAMENTO DE FOLHA AS FOLHAS DE PESQUISADORES NAO REMUNERADOS
        IF PKGPAG_VAR.vgFolha.CdAgrupamento = 1 AND
           PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaPesquisador,PKGPAG_TIPO.cnTpFolhaConvenio) AND
           FPesquisaBolsaNaoRemunerada(PKGPAG_VAR.vgCdVinculo,
                                       PKGPAG_VAR.vDtCalculo,
                                       PKGPAG_VAR.vgFolha.DtInicioMes) THEN

          GOTO FIM_LOOP;

        END IF;

        IF PKGPAG_VAR.vgFolha.CdTipoFolha IN
           (PKGPAG_TIPO.cnTpFolhaBolsista,
            PKGPAG_TIPO.cnTpFolhaResidente,
            PKGPAG_TIPO.cnTpFolhaPesquisador,
            PKGPAG_TIPO.cnTpFolhaConvenio,
            PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
            pkgpag_tipo.cnTpFolhaRescisaoPesquisador) AND
           PKGPAG_VAR.vgBOL.COUNT > 0 THEN

          IF PKGPAG_VAR.vFlPossuiContaBancoOficial = 'N' THEN

            PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                    pCalculo.CdHistoricoParamCalculo,
                                    PKGPAG_VAR.vCdPessoa,
                                    'O vinculo nao possui conta bancaria no banco oficial.',
                                    PKGPAG_VAR.vgCdVinculo,
                                    2,
                                    8);

          END IF;

          IF rVinculo.DtDesligamento >= PKGPAG_VAR.vgFolha.DtInicioMes AND
             NOT FLocalTrabalhoVigente(rVinculo.CdVinculo,
                                       PKGPAG_VAR.vgFolha.DtInicioMes,
                                       PKGPAG_VAR.vgFolha.DtFimMes) THEN

            PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                    pCalculo.CdHistoricoParamCalculo,
                                    PKGPAG_VAR.vCdPessoa,
                                    'O nao foram encontrados locais de trabalho ativos para este vinculo',
                                    PKGPAG_VAR.vgCdVinculo);

          END IF;

        END IF;

        PKGPAG_GERAL.PLogProc('CAL04030503','CAL04030504','Faltas');

        PKGPAG_VAR.bVinculoComCEF := (PKGPAG_VAR.vgCEF.COUNT > 0);

        ------------------------------------------------------------------------------
        -- Calcula o numero de faltas com base no periodo de apuracao da frequencia
        ------------------------------------------------------------------------------

        PKGMOVFRE.PCalcularFaltas(pCdVinculo     => rVinculo.CdVinculo,
                                  pDtIniApuracao => CASE
                                                     PKGPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       NULL
                                                      ELSE
                                                       PKGPAG_VAR.vgApuracaoFrequencia.DtInicialApuracao
                                                    END,

                                  pDtFimApuracao => CASE
                                                     PKGPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       NULL
                                                      ELSE
                                                       PKGPAG_VAR.vgApuracaoFrequencia.DtFinalApuracao
                                                    END,
                                  pDtIniInclusao => CASE
                                                     PKGPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       PKGPAG_VAR.vDtCalculoAnt + 1
                                                      ELSE
                                                       NULL
                                                    END,
                                  pDtFimInclusao => CASE
                                                     PKGPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       PKGPAG_VAR.vDtCalculo
                                                      ELSE
                                                       NULL
                                                    END,
                                  pDtIniLimite   => CASE
                                                     PKGPAG_VAR.vgOrgaoFrequenciaParam.CdTipoPagamentoFrequencia
                                                      WHEN 4 THEN
                                                       ADD_MONTHS(PKGPAG_VAR.vgFolha.DtInicioMes,
                                                                  -1 *
                                                                  PKGMOVFRE.cn_Qt_Mes_Retro_Falta)
                                                      ELSE
                                                       NULL
                                                    END,

                                  pFlSomenteJornada    => 'S',
                                  pFlSomenteEnturmacao => 'S',
                                  pDtInicioMes         => PKGPAG_VAR.vgFolha.DtInicioMes
                                  );

        PKGPAG_VAR.vgFaltas := PKGMOVFRE.FVetorFaltas;

        PKGPAG_VAR.vgIndiceFaltasMesAtual    := trunc(PKGMOVFRE.FIndiceFaltaMesAtual(pVetorFaltas => PKGPAG_VAR.vgFaltas),
                                                      2);
        PKGPAG_VAR.vgIndiceFaltasMesAnterior := trunc(PKGMOVFRE.FIndiceFaltaMesAnterior(pVetorFaltas => PKGPAG_VAR.vgFaltas),
                                                      2);

        PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis := trunc(PKGMOVFRE.FIndiceFaltaSomenteDiasUteis(pVetorFaltas => PKGPAG_VAR.vgFaltas),
                                                           2);

        PKGPAG_VAR.vgIndiceAbonoRetro := trunc(PKGMOVFRE.FIndiceAbonoRetro(pVetorFaltas => PKGPAG_VAR.vgFaltas),
                                               2);

        PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis := trunc(PKGMOVFRE.FIndiceAbonoRetroDiasUteis(pVetorFaltas => PKGPAG_VAR.vgFaltas),
                                                        2);
/*
   pDebug ('vgIndiceFaltasMesAtual:' ||     PKGPAG_VAR.vgIndiceFaltasMesAtual);
   pDebug ('vgIndiceFaltasMesAnterior:' ||      PKGPAG_VAR.vgIndiceFaltasMesAnterior);
   pDebug ('vgIndiceFaltasSomenteDiasUteis:' ||      PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis);
   pDebug ('vgIndiceAbonoRetro:' ||      PKGPAG_VAR.vgIndiceAbonoRetro);
   pDebug ('vgIndiceAbonoRetroDiasUteis:' ||      PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis);
*/
        PKGPAG_GERAL.PLogProcFim('CAL04030504');

        pkgpag_var.bGerouDescontoIRESA := FALSE;

        pkgpag_var.vgVlDescontoIRESA := 0;

        pkgpag_var.vgCdRubDescontoIRESA := NULL;

        IF PKGPAG_VAR.vgFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoRecalcCompl THEN

          PKGPAG_GERAL.PLogProcIni('CAL04030505','Proc Eventos');

          ------------------------------------------------------------------------------
          -- Inicio da execucao dos eventos da folha
          ------------------------------------------------------------------------------
          ------------------------------------------------------------------------------
          -- SIG-1277
          -- CRIAR ROTINA AUTOMATICA PARA DESCONTO DE FALTAS RETRAOTIVAS NAO DESCONTADAS
          ------------------------------------------------------------------------------
          pFaltasNaoDescontadas(rVinculo.CdVinculo);

          PKGPAG_EVENTO.PProcessaEventos(rVinculo,
                                         rVinculo.CdPessoa,
                                         PKGPAG_VAR.vgFolha,
                                         PKGPAG_VAR.vgEvento,
                                         PKGPAG_VAR.vgRubrica,
                                         PKGPAG_VAR.vgFormExpr,
                                         PKGPAG_VAR.vgParamPagamento,
                                         PKGPAG_VAR.vgCEF,
                                         PKGPAG_VAR.vgCCO,
                                         PKGPAG_VAR.vgCCOSubst,
                                         PKGPAG_VAR.vgFUC,
                                         PKGPAG_VAR.vgFUCSubst,
                                         PKGPAG_VAR.vgAPO,
                                         PKGPAG_VAR.vgAPOSemParidade,
                                         PKGPAG_VAR.vgBOL,
                                         PKGPAG_VAR.vgPensaoNaoPrev,
                                         PKGPAG_VAR.vgPensaoPrev,
                                         PKGPAG_VAR.vdtCalculo,
                                         pFlCalculoDefinitivo,
                                         pFlPagaAdiantamento);

          ---------------------------------------------------------------------------------
          -- Verifica se o vinculo possui pagamentos em outra folha calculada em definitivo
          ---------------------------------------------------------------------------------

          PKGPAG_GERAL.PLogProc('CAL04030505','CAL04030506','Exc Eventos');

          PKGPAG_GERAL.PLogProcIni('CAL0403050601','FPossuiEventos');

          PKGPAG_VAR.bFlPossuiProventos := PKGPAG_POS.FPossuiProventos(pFolha     => PKGPAG_VAR.vgFolha,
                                                                       pCdVinculo => rVinculo.CdVinculo);

          PKGPAG_GERAL.PLogProcFim('CAL0403050601');

          IF PKGPAG_VAR.bFlPossuiProventos THEN

            vSgOrgao := NULL;

            PKGPAG_GERAL.PLogProcIni('CAL0403050602','FVinculoComFolhaCalculada');

            vSgOrgao := FVinculoComFolhaCalculada(pCdVinculo        => rVinculo.CdVinculo,
                                                  pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pNuAnoReferencia  => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                  pNuMesReferencia  => PKGPAG_VAR.vgFolha.NuMesReferencia,
                                                  pCdTipoFolha      => PKGPAG_VAR.vgFolha.CdTipoFolha,
                                                  pCdTipoCalculo    => PKGPAG_VAR.vgFolha.CdTipoCalculo);

            -- Mantem pagamento nas condicoes abaixo
            if pkgpag_var.bpossuidisposicao and
               pkgpag_var.vpagasitdisposicao = 'PAG-ORIGEM-CALCULO-ORIGEM' then
               vSgOrgao := null;
            end if;

            IF vSgOrgao IS NOT NULL THEN

              
              PKGPAG_GERAL.PLogProcIni('CAL040305060201','PExcluirPagVinc');

              PKGPAG_GERAL.PExcluirPagVinc(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                           rVinculo.CdVinculo);

              PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                      pCalculo.CdHistoricoParamCalculo,
                                      PKGPAG_VAR.vCdPessoa,
                                      'Vinculo possui pagamentos em folha da ' ||
                                      vSgOrgao,
                                      PKGPAG_VAR.vgCdVinculo,
                                      2,
                                      9);

              PKGPAG_GERAL.PLogProcFim('CAL040305060201');

              GOTO FIM_LOOP;

            END IF;

            PKGPAG_GERAL.PLogProcFim('CAL0403050602');
              
          END IF;

          PKGPAG_GERAL.PLogProc('CAL04030506','CAL04030507','Produt/Vant Pec');

          -------------------------------------------------------------------------------------------------
          -- Processa base de Gratificacao de Produtividade 01-0467 para aplicacao de limite de valor
          -- no rateio
          -------------------------------------------------------------------------------------------------

          -- Parametrizar
          IF PKGPAG_VAR.vgFolha.CdAgrupamento = 1 THEN

            PKGPAG_POS.PBaseGratProd(pFolha            => PKGPAG_VAR.vgFolha,
                                     pCdVinculo        => rVinculo.CdVinculo,
                                     pRubrica          => PKGPAG_VAR.vgRubrica(10489),
                                     pCEF              => PKGPAG_VAR.vgCEF,
                                     pCCO              => PKGPAG_VAR.vgCCO,
                                     pCCOSubst         => PKGPAG_VAR.vgCCOSubst,
                                     pAPO              => PKGPAG_VAR.vgAPO,
                                     pCdTipoAtipratFaz => 22);

          END IF;

          ------------------------------------------------------------------------------
          -- Inicio de processamento das Vantagens Pecuniarias
          ------------------------------------------------------------------------------

          PKGPAG_VP.PProcessaVantagemPecuniaria(PKGPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo,
                                                PKGPAG_VAR.vgRubrica,
                                                PKGPAG_VAR.vgVantagem,
                                                PKGPAG_VAR.vgFormExpr,
                                                PKGPAG_VAR.vDtCalculo);

          ------------------------------------------------------------------------------
          -- Inicio de processamento das Incorporacoes
          ------------------------------------------------------------------------------
          -- Se afastado o mes todo sem remuneracao nao processar incorporacoes
          IF PKGPAG_VAR.vgFolha.CdAgrupamento = 1 THEN
            IF PKGPAG_VAR.vMotAfast.InAfastado <>
               PKGPAG_TIPO.cnAfastadoMesTodo THEN

              PKGPAG_IA.PProcessaIncorporacaoAtivo(PKGPAG_VAR.vgFolha,
                                                   rVinculo.CdVinculo,
                                                   PKGPAG_VAR.vgFormExpr,
                                                   PKGPAG_VAR.vDtCalculo);
            END IF;
          ELSE

            PKGPAG_IA.PProcessaIncorporacaoAtivo(PKGPAG_VAR.vgFolha,
                                                 rVinculo.CdVinculo,
                                                 PKGPAG_VAR.vgFormExpr,
                                                 PKGPAG_VAR.vDtCalculo);

          END IF;

          PKGPAG_GERAL.PLogProcFim('CAL04030507');

        END IF;

        PKGPAG_GERAL.PLogProcIni('CAL04030508', 'Dec Judicial');

        ----------------------------------------------------------------------------------
        -- Inicio do processamento dos lancamentos financeiros
        -- Obs: Se o pagamento e no destino e o orgao da folha que esta sendo calculada e
        --      igual ao do cargo efetivo, nao deve considerar os lancamentos financeiros
        -- Incluida a situacao 'NAO-DISPOSICAO' em 23/04/2013 para evitar que LF, RT
        ----------------------------------------------------------------------------------

        vTemDifMes := FALSE;

        vQtdeNaoLancados := 0;

        IF PKGPAG_VAR.vPagaSitDisposicao NOT IN
           ('PAG-DEST-CALCULO-ORIGEM',
            'PAG-ORIGEM-CALCULO-DEST',
            'NAO-DISPOSICAO')
          OR (rVinculo.CdOrgao = 2
              and rVinculo.CdOrgao = pkgpag_var.vgFolha.CdOrgao
              and pkgpag_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766))
          THEN

          PKGPAG_LF.PLancamentosFinanceiros(pFolha           => PKGPAG_VAR.vgFolha,
                                            pCdVinculo       => rVinculo.CdVinculo,
                                            pFormExpr        => PKGPAG_VAR.vgFormExpr,
                                            pDtCalculo       => pDtCalculo,
                                            pLstRubTrib      => pTributacao.lstRubTrib,
                                            pFlTributacao    => 'T',
                                            pQtdeNaoLancados => vQtdeNaoLancados
                                            );

          ------------------------------------------------------------------------------
          -- Processa pagamento de Decisoes Judiciais
          ------------------------------------------------------------------------------
          if (not rVinculo.bPossuiObito AND
             (rVinculo.DtDesligamento IS NULL or
             rVinculo.DtDesligamento >= PKGPAG_VAR.vgFolha.DtInicioMes)) or
             (rVinculo.bPossuiObito and
             rVinculo.DtDesligamento >= PKGPAG_VAR.vgFolha.DtInicioMes) then

            PKGPAG_LF.PPagamentoDecisaoJudicial(PKGPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo);

          end if;
          ------------------------------------------------------------------------------
          -- Verifica se existe folha de Diferenca de Meses Anteriores para pagar nesta folha
          ------------------------------------------------------------------------------

          IF vgTabCdFolhaPagamentoDifMes.COUNT > 0
            AND NOT FPossuiFolhaDefAnterior(rVinculo.CdVinculo, rVinculo.DtInclusao) THEN

            vTemDifMes := FLancamentoDifMes(pFolha            => PKGPAG_VAR.vgFolha,
                                            pTabCdFolhaDifMes => vgTabCdFolhaPagamentoDifMes,
                                            prVinculo         => rVinculo);

          END IF;

        END IF;

        PKGPAG_GERAL.PLogProcFim('CAL04030508');

        ------------------------------------------------------------------------------
        -- Geracao das rubricas totalizadoras,
        -- Definicao da ordem de execucao das formulas e bases de calculo
        -- Processamento das formulas e bases de calculo
        ------------------------------------------------------------------------------

        bGerouTotalizadoras := PKGPAG_GERAL.FGeraRubricasTotalizadoras(PKGPAG_VAR.vgFolha,
                                                                       rVinculo.CdVinculo);
        IF bGerouTotalizadoras THEN

          PKGPAG_GERAL.PLogProcIni('CAL04030509','Def Ordem Calc');

          -- Temporario ate retirar todas as dependencias de vigencias anteriores a 2012/07

          IF (PKGPAG_VAR.vgFolha.NuAnoReferencia <= 2011 OR
             (PKGPAG_VAR.vgFolha.NuAnoReferencia = 2012 AND
             PKGPAG_VAR.vgFolha.NuMesReferencia <= 6)) THEN

            PDefinirOrdemFCalculoPassado(PKGPAG_VAR.vgFolha,
                                         rVinculo.CdVinculo);

          ELSE

            PDefinirOrdemFCalculo(pCalculo,
                                  PKGPAG_VAR.vgFolha,
                                  rVinculo.CdVinculo);

          END IF;

          PKGPAG_GERAL.PLogProc('CAL04030509','CAL04030510','Proc Form Base');

          -- Primeiro processamento das Formulas e Bases

          pkgpag_var.vgValorCalculoRubrica := vValorCalcRubrica;


          PKGPAG_FB.PProcessaFormulasBasesTotal (PKGPAG_VAR.vgFolha,
                                                 rVinculo.CdVinculo);

          --
          -- Salario família empresas
          --
          IF PKGPAG_VAR.vgFolha.cdorgao = 27

             THEN

             PKGPAG_FB.PProcessaFormulasBases(pFolha    => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 42948,
                                       pTpProcessamento => 1,
                                       pTpLocal         => 1);
          END IF;

          IF PKGPAG_VAR.vgFolha.cdorgao = 25 THEN

             PKGPAG_FB.PProcessaFormulasBases(pFolha    => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 47960,
                                       pTpProcessamento => 1,
                                       pTpLocal         => 1);
          END IF;

          IF NOT (PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
                  PKGPAG_VAR.vgVinculo.DtDesligamento >=
                  PKGPAG_VAR.vgFolha.DtInicioMes) THEN

            IF PKGPAG_VAR.vgCdRubricaRecisao13 > 0 THEN

               PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo,
                                                PKGPAG_VAR.vgCdRubricaRecisao13,
                                                1,
                                                2);

               PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                                rVinculo.CdVinculo,
                                                PKGPAG_VAR.vgCdRubBloqueioRescisao,
                                                1,
                                                2);
            END IF;

            IF PKGPAG_VAR.vgCdRubricaRecisao13CTISP > 0 THEN

              PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               PKGPAG_VAR.vgCdRubricaRecisao13CTISP,
                                               1,
                                               2);

              PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               PKGPAG_VAR.vgCdRubBloqueioRescisao,
                                               1,
                                               2);
            END IF;

            IF PKGPAG_VAR.vgCdRubricaRecisao13PENSAO > 0 THEN

              PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               PKGPAG_VAR.vgCdRubricaRecisao13PENSAO,
                                               1,
                                               2);

              PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                               rVinculo.CdVinculo,
                                               PKGPAG_VAR.vgCdRubBloqueioRescisao,
                                               1,
                                               2);
            END IF;
                    
            PKGPAG_FB.PProcessaFormulasBasesTotal(PKGPAG_VAR.vgFolha,
                                                  rVinculo.CdVinculo,
                                                  2,
                                                  2);
     
          END IF;

          -- Não deve gerar 09-0916 - base de cálculo do IPREV quando for CPSM
          IF rVinculo.CdRegimePrevidenciario = pkgpag_tipo.cnRegPrevCPSM AND
            pkgpag_fb.fmnepossuidecjudicial(rVinculo.CdVinculo,
                                             pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.CdAgrupamento,5,1934),
                                             pkgpag_var.vgfolha.NuMesReferencia,
                                             pkgpag_var.vgfolha.NuAnoReferencia) <> 1 THEN

            PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo        => rVinculo.CdVinculo,
                                              pCdRubrica        => nvl(pkgpag_var.vgCdRubBaseIPESC,0),
                                              pnusufixo         => 1,
                                              pFlExcluiAmbos    => 'S');
          END IF;

          PKGPAG_FB.PProcessaFormulasBases(pFolha    => PKGPAG_VAR.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => 48384,
                                           pTpProcessamento => 1,
                                           pTpLocal         => 1);

          PKGPAG_GERAL.PLogProcFim('CAL04030510');

        END IF;

        PKGPAG_GERAL.PLogProcIni('CAL04030511','Consol Pag Vinc');

        ------------------------------------------------------------------------------
        -- Consolidacao dos pagamentos gerados nas relacoes de vinculo
        ------------------------------------------------------------------------------

        PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

        PConsolidaPagVinculo(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                             rVinculo.CdVinculo);


        PKGPAG_GERAL.PLogTrace('CAL - Consolida Pagamento',
                               NULL,
                               PKGPAG_VAR.vgTmInicio);

        PKGPAG_GERAL.PLogProc('CAL04030511','CAL04030512','Expurga Rub');

        PAjustarContrachequeCCO(pCdVinculo            => rVinculo.CdVinculo,
                                pCdAgrupamento        => pkgpag_var.vgfolha.cdagrupamento,
                                pCdOrgao              => pkgpag_var.vgfolha.cdorgao,
                                pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                pCdTipoFolhaPagamento => pkgpag_var.vgFolha.CdTipoFolhaPagamento,
                                pDataInicioMes        => pkgpag_var.vgfolha.dtiniciomes,
                                pDataFimMes           => pkgpag_var.vgfolha.dtfimmes,
                                pDataCalculo          => pkgpag_var.vgfolha.dtcalculo);

        IF PKGPAG_VAR.vgFolha.cdAgrupamento=176
          AND pkgpag_var.vgPercentATS.count > 0
          THEN

          FOR i IN pkgpag_var.vgPercentATS.first .. pkgpag_var.vgPercentATS.last
            LOOP
              --SIG-137 salva o valor inteiro do índice do triênio (não proporcionalizado)
              UPDATE epaghistoricorubricavinculo hrv
                   SET hrv.vlindicerubrica = pkgpag_var.vgPercentATS(i).vlIndiceATS
                 WHERE hrv.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                   AND hrv.cdvinculo = rVinculo.CdVinculo
                   AND hrv.cdrubricaagrupamento = pkgpag_var.vgPercentATS(i).cdrubricaagrupamento
                   AND hrv.nusufixorubrica = i; --37891
          END LOOP;
        END IF;

        IF PKGPAG_VAR.vgCdRubricaRecisao13 > 0 THEN

           -- valor da 09-0920 lançado em financeiro se sobrepõe ao valor calculado
           if pkgpag_geral.fpossuilancfinanceiro(rVinculo.CdVinculo,
                                          PKGPAG_VAR.vgFolha,
                                          pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,920)) then

                  begin

                      delete epaghistoricorubricavinculo hrv
                       where cdvinculo = rVinculo.CdVinculo
                         and cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                         and cdrubricaagrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,920)
                         and hrv.cdtipoorigemrubrica <> 2;

                      delete epaghistoricorubricarelvinc hrr
                       where cdvinculo = rVinculo.CdVinculo
                         and cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                         and cdrubricaagrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,920)
                         and hrr.cdtipoorigemrubrica <> 2;

                      vvlBaseIprev13SalResc.vlProporcional := pkgpag_geral.fretornavalorrubrica(
                                                                           PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                           rVinculo.CdVinculo,
                                                                           pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,920));

                      vvlBaseIprev13SalResc.vlIntegral := vvlBaseIprev13SalResc.vlProporcional;
                      vvlBaseIprev13SalResc.vlReal     := vvlBaseIprev13SalResc.vlProporcional;



                       exception
                         when others then
                           null;
                       end;

           else

               vvlBaseIprev13SalResc := PKGPAG_FB.FRetornaValorBaseCalculo(pfolha => PKGPAG_VAR.vgFolha,
                                            pcdvinculo => rVinculo.CdVinculo,
                                            pcdtipohistorico => 2,
                                            pcdrelacaovinculo => 0,
                                            pcdbasecalculo => pkgpag_var.vgrubrica(pkgpag_var.vgCdRubBaseIPESC13).cdbasecalculo,
                                            pcdchave => rVinculo.CdVinculo);
           end if;

           IF NVL(vvlBaseIprev13SalResc.vlProporcional,0) > 0 THEN

                UPDATE epaghistoricorubricarelvinc hh
                   SET hh.vlintegral = vvlBaseIprev13SalResc.vlIntegral,
                       hh.vlreal     = vvlBaseIprev13SalResc.vlReal,
                       hh.vlproporcional = vvlBaseIprev13SalResc.vlProporcional,
                       hh.vlindicerubrica = vvlBaseIprev13SalResc.vlIndice
                 WHERE hh.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                   AND hh.cdvinculo = rVinculo.CdVinculo
                   AND hh.cdrubricaagrupamento = pkgpag_var.vgCdRubBaseIPESC13;

                vvlBaseIprev13SalResc.vlIndice := NULL;

                BEGIN

                SELECT 1
                  INTO vvlBaseIprev13SalResc.vlIndice
                  FROM epaghistoricorubricavinculo hrv
                 WHERE hrv.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                   AND hrv.cdvinculo = rVinculo.CdVinculo
                   AND hrv.cdrubricaagrupamento = pkgpag_var.vgCdRubBaseIPESC13;

                 EXCEPTION
                   WHEN no_data_found
                     THEN
                       pkgpag_geral.pinserelancamentovinculo (pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                     pcdvinculo => rVinculo.CdVinculo,
                                                           pcdexpressaoformcalc => NULL,
                                                          pcdrubricaagrupamento => pkgpag_var.vgCdRubBaseIPESC13,
                                                               pnusufixorubrica => 1,
                                                                   pvlpagamento => vvlBaseIprev13SalResc.vlProporcional);
                 END;

           END IF;
        END IF;
        ------------------------------------------------------------------------------
        -- Expurga rubricas conforme parametrizacao
        ------------------------------------------------------------------------------

        PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

        PExpurgarRubricas(PKGPAG_VAR.vgFolha, rVinculo);

        PKGPAG_GERAL.PLogTrace('CAL - Expurga Rubricas',
                               NULL,
                               PKGPAG_VAR.vgTmInicio);

        PKGPAG_GERAL.PLogProc('CAL04030512','CAL04030513','Proc Excludente');

        ------------------------------------------------------------------------------
        -- Rubricas Excludentes
        ------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgVinculo.DtDesligamento IS NULL OR
           PKGPAG_VAR.vgVinculo.DtDesligamento >=
           PKGPAG_VAR.vgFolha.DtInicioMes THEN

          PProcessaRubricaExcludente(PKGPAG_VAR.vgFolha,
                                     rVinculo.CdVinculo);

        END IF;

        PKGPAG_GERAL.PLogProc('CAL04030513','CAL04030514','Proc Dec. Terc.');

        /*21461/2024 - Tiago Von - Rotina responsável por realizar o controle de saldo/parcelas das Dec. Judiciais de PENHORA*/
        PKGPAG_LF.PRegistraPgtPenhora(pFolha => pkgpag_var.vgFolha,
                                      pCdVinculo => rVinculo.CdVinculo );  


        -------------------------------------------------------------------------------
        -- Caso a variavel seja maior do que zero, significa que houve uma
        -- folha de 13 calculada em definitivo no mes anterior
        -- Devera gerar as diferencas entre as folhas
        -------------------------------------------------------------------------------

    /*    IF (PKGPAG_VAR.vgCdFolha13Ant > 0 AND PKGPAG_VAR.vgCdFolha13 > 0)
          AND pkgpag_var.vgFolha.CdTipoFolhaPagamento NOT IN (1505,1525,1526) -- Folhas PRODEX PGE NAO GERA
          AND PKGPAG_VAR.vgVinculo.DtDesligamento < pkgpag_var.vgFolha.dtCalculo
          AND PKGPAG_VAR.vgVinculo.DtDesligamento >= pkgpag_var.vgFolha.DtInicioMes
          THEN

          IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                    2,
                                                                    23)) THEN

            PKGPAG_DT.PReprocessa13Salario(pCdVinculo        => rVinculo.CdVinculo,
                                           pCdAgrupamento    => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                           pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                           pCdFolha13Ant     => PKGPAG_VAR.vgCdFolha13Ant,
                                           pCdFolha13        => PKGPAG_VAR.vgCdFolha13);

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
           AND CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
           AND CdRubricaAgrupamento in (23157, 38536, 10342) --, 10924)
           AND VlPagamento < 1;

        PKGPAG_GERAL.PLogProc('CAL04030514','CAL04030515','Proc Ferias');

        -------------------------------------------------------------------------------
        -- Insere e calcula a base de Ferias
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vPagaSitDisposicao NOT IN
           ('PAG-DEST-CALCULO-ORIGEM',
            'PAG-ORIGEM-CALCULO-DEST',
            'NAO-DISPOSICAO') THEN

          IF PKGPAG_VAR.vgCdRubricaBaseFerias > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseFerias,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

            PKGPAG_FB.PProcessaFormulasBases(PKGPAG_VAR.vgFolha,
                                             rVinculo.CdVinculo,
                                             PKGPAG_VAR.vgCdRubricaBaseFerias,
                                             2,
                                             2);

          END IF;

        END IF;

        -------------------------------------------------------------------------------
        -- 1/3 de Ferias
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubUmTercoFerias IS NOT NULL
           AND NOT PKGPAG_LF.FPossuiLancamentoFinanceiro(PKGPAG_VAR.vgCdRubUmTercoFerias) THEN

          PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

          PKGPAG_POS.PUmTercoFerias(PKGPAG_VAR.vgCdVinculo,
                                    PKGPAG_VAR.vgFolha,
                                    PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubUmTercoFerias),
                                    PKGPAG_VAR.vgFormExpr);

          PKGPAG_GERAL.PLogTrace('CAL - 1/3 Ferias',
                                 null,
                                 PKGPAG_VAR.vgTmInicio);

        END IF;

        PKGPAG_GERAL.PLogProc('CAL04030515','CAL04030516','Proc Abono');

        -------------------------------------------------------------------------------
        -- Rescisao de 1/3 de Ferias ACT
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdEventoRescisaoACT > 0
          AND pkgpag_var.vgFolha.CdAgrupamento <> 134 AND
           (
             (
                PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN
                PKGPAG_VAR.vgFolha.DtInicioMes AND PKGPAG_VAR.vgFolha.DtFimMes
             )
             OR
             (
               PKGPAG_VAR.vgVinculo.DtDesligamento < PKGPAG_VAR.vgFolha.DtInicioMes AND
               TRUNC(PKGPAG_VAR.vMotAfast.DtInclusao) BETWEEN
               (PKGPAG_VAR.vDtCalculoAnt + 1) AND (pDtCalculo)
             )
             OR
             (PKGPAG_VAR.vMotAfast.InAfastado = PKGPAG_TIPO.cnAfastadoNao)

            ) THEN

          PKGPAG_POS.P069RescisaoFeriasACT(pFolha     => PKGPAG_VAR.vgFolha,
                                           pEvento    => PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoRescisaoACT),
                                           pTemDifMes => vTemDifMes,
                                           prubrica   => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoRescisaoACT)
                                                                              .cdrubricaagrupamento));
        ELSIF pkgpag_var.vgFolha.CdAgrupamento = 134
          AND (NVL(pkgpag_var.vgNuDiasFeriasNaoPagas,0) + NVL(pkgpag_var.vgNuDiasFeriasPrevistos,0)) > 0
          THEN

          PKGPAG_POS.P069RescisaoFeriasCTISP(pFolha     => PKGPAG_VAR.vgFolha,
                                             pEvento    => PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoRescisaoACT),
                                             pTemDifMes => vTemDifMes,
                                             prubrica   => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoRescisaoACT).cdrubricaagrupamento));

        else
          null;
        END IF;

        -------------------------------------------------------------------------------
        -- Ferias indenizadas
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubFeriasIndenizadas IS NOT NULL THEN

          PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

          PKGPAG_POS.P073074FeriasIndenizadas(PKGPAG_VAR.vgCdRubFeriasIndenizadas);

          PKGPAG_GERAL.PLogTrace('CAL - Ferias indenizadas',
                                 null,
                                 PKGPAG_VAR.vgTmInicio);

        END IF;

        -------------------------------------------------------------------------------
        -- 1/3 de Ferias indenizadas
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubFeriasIndenUmTerco IS NOT NULL THEN

          PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

          PKGPAG_POS.P073074FeriasIndenizadas(PKGPAG_VAR.vgCdRubFeriasIndenUmTerco);

          PKGPAG_GERAL.PLogTrace('CAL - Ferias indenizadas',
                                 null,
                                 PKGPAG_VAR.vgTmInicio);

        END IF;

        -------------------------------------------------------------------------------
        -- Ferias indenizadas ACT SJC
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubFeriasIndenizadasACTSJC IS NOT NULL AND
           ((PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN
             PKGPAG_VAR.vgFolha.DtInicioMes AND PKGPAG_VAR.vgFolha.DtFimMes) or
             (PKGPAG_VAR.vMotAfast.InTipoAfastamento = 'D'
              and trunc(PKGPAG_VAR.vMotAfast.DtInclusao) > trunc(pkgpag_var.vgFolha.DtCalculoAnt)
              and to_char(PKGPAG_VAR.vgVinculo.DtDesligamento,'yyyymm') = to_char(pkgpag_var.vgFolha.DtCalculoAnt,'yyyymm')))

          THEN

          PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

          if PKGPAG_VAR.vMotAfast.InTipoAfastamento = 'D'
              and trunc(PKGPAG_VAR.vMotAfast.DtInclusao) > trunc(pkgpag_var.vgFolha.DtCalculoAnt)
              and to_char(PKGPAG_VAR.vgVinculo.DtDesligamento,'yyyymm') = to_char(pkgpag_var.vgFolha.DtCalculoAnt,'yyyymm') then

              PKGPAG_POS.P010392FeriasIndenizadasACTSJC(PKGPAG_VAR.vgCdRubFeriasIndenizadasACTSJC,pkgpag_var.vgFolha.CdFolhaPagamentoNormalAnt);

          else

              PKGPAG_POS.P010392FeriasIndenizadasACTSJC(PKGPAG_VAR.vgCdRubFeriasIndenizadasACTSJC);

          end if;

          PKGPAG_GERAL.PLogTrace('CAL - Ferias indenizadas ACT SJC',
                                 null,
                                 PKGPAG_VAR.vgTmInicio);

        END IF;

        IF PKGPAG_VAR.vgCdRubFeriasIndenizadasVinc is not null
          THEN

               pkgpag_pos.P011156FeriasIndenizadasVinc(PKGPAG_VAR.vgCdRubFeriasIndenizadasVinc);

         END IF;

        -------------------------------------------------------------------------------
        -- Abono pecuniario
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubAbonoPecuniario IS NOT NULL THEN

          PKGPAG_POS.PAbonoPecuniario(PKGPAG_VAR.vgCdVinculo,
                                      PKGPAG_VAR.vgFolha,
                                      PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubAbonoPecuniario),
                                      PKGPAG_VAR.vgFormExpr);

        END IF;

        -------------------------------------------------------------------------------
        -- Diferenca de Abono pecuniario
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubDifAbonoPecuniario IS NOT NULL THEN

          PKGPAG_POS.PAbonoPecuniario(PKGPAG_VAR.vgCdVinculo,
                                      PKGPAG_VAR.vgFolha,
                                      PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubDifAbonoPecuniario),
                                      PKGPAG_VAR.vgFormExpr);

        END IF;

        IF PKGPAG_VAR.vgCdRubAbono13Ferias IS NOT NULL THEN

          PKGPAG_POS.PAbonoPecuniario(PKGPAG_VAR.vgCdVinculo,
                                      PKGPAG_VAR.vgFolha,
                                      PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubAbono13Ferias),
                                      PKGPAG_VAR.vgFormExpr);

        END IF;

        PKGPAG_GERAL.PLogProc('CAL04030516','CAL04030517','Proc Adiant. Ferias');

        -------------------------------------------------------------------------------
        -- Adiantamento de salario/ferias
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubAdiantSalFerias IS NOT NULL THEN

          PKGPAG_POS.PAdiantamentoSalarioFerias(PKGPAG_VAR.vgCdVinculo,
                                                PKGPAG_VAR.vgFolha,
                                                PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubAdiantSalFerias),
                                                PKGPAG_VAR.vgFormExpr);

        END IF;

        -------------------------------------------------------------------------------
        -- Pagamento Media de Horas Extras Cidasc/ INMETRO 01-0201
        -------------------------------------------------------------------------------

        IF pkgpag_var.vgFolha.CdAgrupamento in (4, 276) -- Cidasc e INMETRO
          AND pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                                pCdRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,201)) > 0

           THEN

           IF NOT fPossuiPagamentoMediaFerias(PKGPAG_VAR.vgCdVinculo,
                                                       PKGPAG_VAR.vgFolha.dtInicioMes,
                                                       PKGPAG_VAR.vgFolha.cdOrgao,
                                                       PKGPAG_VAR.vgFolha.CdAgrupamento)
             THEN

             vVlRubrica010201 := 0;

             vCdExpressaoFormula := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr => PKGPAG_VAR.vgFormExpr,
                                                                           pCdRubricaAgrupamento     => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,201),
                                                                           pCdRelacaoVinculo         => pkgpag_var.vgCEF(1).CdRelacaoVinculo);

             UPDATE EPagHistoricoRubricaVinculo HRV
                   SET HRV.CdExpressaoFormCalc = vCdExpressaoFormula
                 WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                   AND HRV.CdVinculo = PKGPAG_VAR.vgCdVinculo
                   AND HRV.CdRubricaAgrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,201);

             PKGPAG_FB.PProcessaFormulasBases(pFolha     => PKGPAG_VAR.vgFolha,
                                              pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                              pCdRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,201),
                                              ptplocal   => 2,
                                              pTpProcessamento => 1);

             vVlRubrica010201 := pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                                          pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                                                          pCdRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,201));

             BEGIN

               UPDATE epaghistoricorubricarelvinc hrvv
                  SET hrvv.vlintegral     = vvlrubrica010201,
                      hrvv.vlproporcional = vvlrubrica010201,
                      hrvv.vlreal         = vvlrubrica010201
                WHERE hrvv.cdfolhapagamento =
                      pkgpag_var.vgfolha.cdfolhapagamento
                  AND hrvv.cdvinculo = pkgpag_var.vgcdvinculo
                  AND hrvv.cdrubricaagrupamento =
                      pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,
                                                   1,
                                                   201)
                  AND hrvv.cdrelacaovinculo = pkgpag_var.vgcef(1)
                     .cdrelacaovinculo;

               DELETE epaghistoricorubricarelvinc hrvv
                WHERE hrvv.cdfolhapagamento =
                      pkgpag_var.vgfolha.cdfolhapagamento
                  AND hrvv.cdvinculo = pkgpag_var.vgcdvinculo
                  AND hrvv.cdrubricaagrupamento =
                      pkgpag_geral.fretornarubrica(pkgpag_var.vgfolha.cdagrupamento,
                                                   1,
                                                   201)
                  AND hrvv.cdrelacaovinculo <> pkgpag_var.vgcef(1)
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

        IF PKGPAG_VAR.vgCdRubDifUmTercoFerias IS NOT NULL THEN

          PKGPAG_POS.PDiferencaUmTercoFerias(PKGPAG_VAR.vgCdVinculo,
                                             PKGPAG_VAR.vgFolha,
                                             PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubDifUmTercoFerias),
                                             PKGPAG_VAR.vgFormExpr);

          IF pkgpag_var.vgFolha.CdAgrupamento = 4 -- Cidasc
            THEN

              BEGIN

              UPDATE epaghistoricorubricarelvinc hrv
                  SET vlproporcional  = NULL
                WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdVinculo       = PKGPAG_VAR.vgCdVinculo
                  AND HRV.CdRubricaAgrupamento IN (48135,61915,61895,61896);

              PKGPAG_FB.PProcessaFormulasBases(pFolha     => PKGPAG_VAR.vgFolha,
                                         pCdVinculo       => PKGPAG_VAR.vgCdVinculo,
                                         pCdRubrica       => 48135,
                                         ptplocal         => 1,
                                         pTpProcessamento => 1);

              UPDATE epaghistoricorubricavinculo hrv
                  SET vlpagamento = (select sum(vlreal)
                                      from epaghistoricorubricarelvinc hrv1
                                       WHERE HRV1.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                                         AND HRV1.CdVinculo       = PKGPAG_VAR.vgCdVinculo
                                         AND HRV1.CdRubricaAgrupamento = 48135)
                WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdVinculo       = PKGPAG_VAR.vgCdVinculo
                  AND HRV.CdRubricaAgrupamento = 48135;

                   
               PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                pCdVinculo       => PKGPAG_VAR.vgCdVinculo,
                                                pCdRubrica       => 61915,
                                                ptplocal         => 2,
                                                pTpProcessamento => 2);    
                                                
               PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                pCdVinculo       => PKGPAG_VAR.vgCdVinculo,
                                                pCdRubrica       => 61895,
                                                ptplocal         => 2,
                                                pTpProcessamento => 2);  

               PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                pCdVinculo       => PKGPAG_VAR.vgCdVinculo,
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

        IF PKGPAG_VAR.vgCdRubDevUmTercoFerias IS NOT NULL and
          (PKGPAG_VAR.vgVinculo.DtDesligamento is null or
           (trunc(PKGPAG_VAR.vgVinculo.DtDesligamento) > trunc(pkgpag_var.vgFolha.DtCalculo)) or
           (PKGPAG_VAR.vgVinculo.DtDesligamento is not null and trunc(pkgpag_geral.FObterDtInclusaoAfaDefinitivo(PKGPAG_VAR.vgVinculo.cdVinculo)) > trunc(pkgpag_var.vgFolha.DtCalculoAnt))) THEN

          PKGPAG_POS.PDevolucaoUmTercoFerias(PKGPAG_VAR.vgCdVinculo,
                                             PKGPAG_VAR.vgFolha,
                                             PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubDevUmTercoFerias),
                                             PKGPAG_VAR.vgFormExpr);

        END IF;
        
        ---------------------------------------------------------------------------------
        -- Geracao da devolucao de antecipacao de 13 e 13 salario quando
        -- a recisao ocorre antes do mes de processamento
        ---------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubricaDevAnt13 > 0 THEN

          PKGPAG_POS.PRescisaoMesAnterior(pFolha     => PKGPAG_VAR.vgFolha,
                                          pVinculo   => rVinculo,
                                          pDtCalculo => PKGPAG_VAR.vDtCalculo);

        END IF;

        IF pkgpag_var.vgAPO.Count > 0 AND
           pkgpag_geral.fpossuilancfinanceiro (pcdvinculo => PKGPAG_VAR.vgCdVinculo,
                                                   pfolha => PKGPAG_VAR.vgFolha,
                                               pcdrubrica => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                          pcdtiporubrica => 5,
                                                                                              pNuRubrica => 9985))

          THEN

           pkgpag_pos.PBloqueioRemunApo(PKGPAG_VAR.vgAPO,
                                        PKGPAG_VAR.vgFolha,
                                        PKGPAG_GERAL.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                          pcdtiporubrica => 5,
                                                                                              pNuRubrica => 9985));
        END IF;


        IF PKGPAG_VAR.vgFolha.cdorgao in (25,27) and 
           pkgpag_var.vgRelVincPrincipal.CdRelTrabPagamento not in (2,15,18) and
           PKGPAG_VAR.vgFolha.cdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal and
           not pkgpag_geral.fpossuilancfinanceiro (pcdvinculo => rVinculo.CdVinculo,
                                                   pfolha => PKGPAG_VAR.vgFolha,
                                                   pcdrubrica => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                              pcdtiporubrica => 9,
                                                                                              pNuRubrica => 582)) THEN
                                                                                              
             pkgpag_alimentacao.pDescontoDiasAuxAlimEmpresas(pCdVinculo => rVinculo.CdVinculo);

        end if;

        IF rVinculo.CdRegimePrevidenciario IN
           (PKGPAG_TIPO.cnRegPrevGeral, PKGPAG_TIPO.cnRegPrevNaoPossui) THEN

          --------------------------------------------------------------------------------------
          -- A base de baixa de ferias e reprocessada apos o calculo das ferias e antes
          -- da exclusao das rubricas que nao compoe a folha de ferias para obter o valor
          --------------------------------------------------------------------------------------

          IF PKGPAG_VAR.vgCdRubBaseBaixa IS NOT NULL THEN

            PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                             pCdVinculo       => rVinculo.CdVinculo,
                                             pCdRubrica       => PKGPAG_VAR.vgCdRubBaseBaixa,
                                             pTpProcessamento => 2,
                                             pTpLocal         => 2);

            vvlBaseBaixa := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                              pCdVinculo        => rVinculo.CdVinculo,
                                                              pCdRubrica        => PKGPAG_VAR.vgCdRubBaseBaixa);

          END IF;

        END IF;


        PKGPAG_GERAL.PLogProc('CAL04030517','CAL04030518','Exc Rubrica e Processa');

        ----------------------------------------------------------------------------------------------------
        -- Exclui as rubricas geradas  pois estas foram geradas para poder calcular rubricas de ferias e 13o
        ----------------------------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgFolha.CdTipoFolha NOT IN
           (--PKGPAG_TIPO.cnTpFolhaNormal,
            PKGPAG_TIPO.cnTpFolhaBolsista,
            PKGPAG_TIPO.cnTpFolhaResidente,
            PKGPAG_TIPO.cnTpFolhaPesquisador,
            PKGPAG_TIPO.cnTpFolhaConvenio,
            PKGPAG_TIPO.cnTpFolhaOutras,
            --PKGPAG_TIPO.cnTpFolhaBEP,
            PKGPAG_TIPO.cnTpFolhaServAfast,
            PKGPAG_TIPO.cnTpFolhaFunebre,
            PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
            pkgpag_tipo.cnTpFolhaRescisaoPesquisador) THEN

          IF PKGPAG_VAR.vgFolha.FlPagaTodasRubricas = 'N' THEN

            PKGPAG_GERAL.PExcluiRubricas(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                         rVinculo.CdVinculo,
                                         PKGPAG_VAR.vgFolha.InPagamentoRubrica);

            IF PKGPAG_VAR.vgFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaNormal THEN                              

              PKGPAG_FB.PProcessaFormulasBasestotal (pFolha           => PKGPAG_VAR.vgFolha,
                                                     pCdVinculo       => rVinculo.CdVinculo,
                                                     pTpProcessamento => 2,
                                                     pTpLocal         => 2);
                                             
            END IF;                                 

            IF PKGPAG_VAR.vgCdRubBaseBaixa > 0 AND vvlBaseBaixa > 0 THEN

              UPDATE EPagHistoricoRubricaVinculo HRV
                 SET HRV.vlPagamento = vvlBaseBaixa
               WHERE HRV.CdVinculo = rVinculo.CdVinculo
                 AND HRV.CdFolhaPagamento =
                     PKGPAG_VAR.vgFolha.CdFolhaPagamento
                 AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseBaixa;

              ----------------------------------------------------------------------
              -- Recalcula a modalidade 56 - FGTS de Ferias
              ----------------------------------------------------------------------

              IF PKGPAG_VAR.vgCdRubFeriasFGTS > 0 THEN

                PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                 pCdVinculo       => rVinculo.CdVinculo,
                                                 pCdRubrica       => PKGPAG_VAR.vgCdRubFeriasFGTS,
                                                 pTpProcessamento => 2,
                                                 pTpLocal         => 2);

              END IF;

            END IF;

          END IF;

        END IF;

        PKGPAG_GERAL.PLogProc('CAL04030518','CAL04030519','Teto Governador');

        -------------------------------------------------------------------------------
        -- Teto do governador
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubDescTetoGovernador IS NOT NULL THEN

          PKGPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo        => rVinculo.CdVinculo);

          IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_VAR.vgCdRubDescTetoGovernador) THEN

            PKGPAG_POS.PDescontoTetoGovernador(pFolha                => PKGPAG_VAR.vgFolha,
                                               pCdVinculo            => rVinculo.CdVinculo,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDescTetoGovernador);
          END IF;

          IF PKGPAG_VAR.vgVlTotalProventos > 0 THEN

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaTetoGov,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => PKGPAG_POS.RetornaValorRefBloqRemun(rVinculo.CdVinculo,
                                                                                                               PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                               PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                                               PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                                                               PKGPAG_VAR.vgFolha.NuMesReferencia),
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

          END IF;

        END IF;
        --
        -- SIG-6578 GEREF - Base 13
        -- Reprocessar base 13 apos a inclusao da rubrica de abatimento do teto
        if PKGPAG_VAR.vgCdRubBase13Sal > 0 and
           pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                 rVinculo.CdVinculo,
                                             PKGPAG_VAR.vgCdRubricaTetoGov) > 0 then

               PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                    pCdVinculo            => rVinculo.CdVinculo,
                                            pCdRubrica       => PKGPAG_VAR.vgCdRubBase13Sal,
                                            pTpProcessamento => 2,
                                            pTpLocal         => 2);

         END IF;
        -------------------------------------------------------------------------------
        -- Teto do governador - 13 Salario
        -------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubDescTetoGovernador13 IS NOT NULL AND
           NOT PKGPAG_VAR.bReprocessou13Sal THEN

          IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_VAR.vgCdRubDescTetoGovernador13) THEN

            PKGPAG_POS.PDescontoTetoGovernador13(pFolha                => PKGPAG_VAR.vgFolha,
                                                 pCdVinculo            => rVinculo.CdVinculo,
                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDescTetoGovernador13);
          END IF;

        END IF;

        ---------------------------------------------------------------------------
        -- Reprocessa a formula da Contribuicao Sindical para descontar o teto.
        ---------------------------------------------------------------------------

        IF PKGPAG_VAR.vgListaContribSind.COUNT > 0 THEN

          i := PKGPAG_VAR.vgListaContribSind.FIRST;

          WHILE i <= PKGPAG_VAR.vgListaContribSind.LAST LOOP

            IF PKGPAG_VAR.vgListaContribSind.EXISTS(i) THEN

              IF PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                   rVinculo.CdVinculo,
                                                   PKGPAG_VAR.vgListaContribSind(i)) > 0 THEN

                vCdExpressaoFormula := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                              pCdRubricaAgrupamento => i,
                                                                              pCdRelacaoVinculo     => 0);

                UPDATE EPagHistoricoRubricaVinculo HRV
                   SET HRV.CdExpressaoFormCalc = vCdExpressaoFormula
                 WHERE HRV.CdFolhaPagamento =
                       PKGPAG_VAR.vgFolha.CdFolhaPagamento
                   AND HRV.CdVinculo = rVinculo.CdVinculo
                   AND HRV.CdRubricaAgrupamento = i;

                PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                 pCdVinculo       => rVinculo.CdVinculo,
                                                 pCdRubrica       => i,
                                                 pTpProcessamento => 1,
                                                 pTpLocal         => 2);

                i := PKGPAG_VAR.vgListaContribSind.LAST + 1;

              END IF;

            END IF;

            i := PKGPAG_VAR.vgListaContribSind.NEXT(i);

          END LOOP;

        END IF;

        PKGPAG_GERAL.PLogProc('CAL04030519','CAL04030520','Retroativo');

        IF PKGPAG_VAR.vPagaSitDisposicao NOT IN
           ('PAG-DEST-CALCULO-ORIGEM',
            'PAG-ORIGEM-CALCULO-DEST',
            'NAO-DISPOSICAO') THEN

          ------------------------------------------------------------------------------
          -- Processa retroativos - Exercicios findos
          ------------------------------------------------------------------------------

          PKGPAG_RT.PRetroativos(PKGPAG_VAR.vgFolha,
                                 rVinculo.CdVinculo,
                                 pFlCalculoDefinitivo);
          --
          -- Trecho comentado e implementado na pkgpag_rt o recalculo das rubricas
          -- REPROCESSA A RUBRICA 05-0260
          --
         /* begin

          vHistRubRelVinc.Vlreal := null;

          select *
            into vHistRubRelVinc
             from epaghistoricorubricarelvinc hrv
           where hrv.cdrubricaagrupamento = 56601
             and hrv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
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
                  and hv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
                  and hv.cdvinculo = rVinculo.CdVinculo;

             exception
               when no_data_found then
                 PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => vHistRubRelVinc.CdFolhaPagamento,
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

             PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
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
             and hrv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
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
                  and hv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
                  and hv.cdvinculo = rVinculo.CdVinculo;

             exception
               when no_data_found then
                 PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => vHistRubRelVinc.CdFolhaPagamento,
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
          PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
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
             and hrv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
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
                  and hv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
                  and hv.cdvinculo = rVinculo.CdVinculo;

             exception
               when no_data_found then
                 PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => vHistRubRelVinc.CdFolhaPagamento,
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
             PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                              pCdVinculo       => rVinculo.CdVinculo,
                                              pCdRubrica       => 56818,
                                              pTpProcessamento => 1, --formula de calculo
                                              pTpLocal         => 2);

          end if; */


          PAjustarContrachequeCCO(pCdVinculo            => rVinculo.CdVinculo,
                                  pCdAgrupamento        => pkgpag_var.vgfolha.cdagrupamento,
                                  pCdOrgao              => pkgpag_var.vgfolha.cdorgao,
                                  pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                  pCdTipoFolhaPagamento => pkgpag_var.vgFolha.CdTipoFolhaPagamento,
                                  pDataInicioMes        => pkgpag_var.vgfolha.dtiniciomes,
                                  pDataFimMes           => pkgpag_var.vgfolha.dtfimmes,
                                  pDataCalculo          => pkgpag_var.vgfolha.dtcalculo);

          ------------------------------------------------------------------------------
          -- Caso o vinculo possua
          ------------------------------------------------------------------------------

          IF (NOT bGerouTotalizadoras) AND
             rVinculo.DtDesligamento < PKGPAG_VAR.vgFolha.DtInicioMes THEN

            bGerouTotalizadoras := PKGPAG_GERAL.FGeraRubricasTotalizadoras(PKGPAG_VAR.vgFolha,
                                                                           rVinculo.CdVinculo);

          END IF;

          ------------------------------------------------------------------------------
          -- Restituicao ao erario
          ------------------------------------------------------------------------------

          IF pkgpag_var.bGerouDescontoIRESA
            AND pkgpag_var.vgCdRubDescontoIRESA IS NOT NULL
            AND pkgpag_var.vgVlDescontoIRESA > 0
            AND pkgpag_var.vgFolha.CdOrgao <> 443

             THEN

                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaErario,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 11);

                PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                                 pCdVinculo       => rVinculo.CdVinculo,
                                                 pCdRubrica       => PKGPAG_VAR.vgCdRubricaErario,
                                                 pTpProcessamento => 2,
                                                 pTpLocal         => 2);

               vVlMargemErario := pkgpag_re.FRetornaValorMargem(pkgpag_var.vgFolha.CdFolhaPagamento,
                                                                 pkgpag_var.vgFolha.CdTipoFolha,
                                                                 rVinculo.CdVinculo,
                                                                 PKGPAG_VAR.vgCdRubricaErario,
                                                                 0,
                                                                 'S');

                IF pkgpag_var.vgvldescontoiresa > vVlMargemErario
                   THEN

                     UPDATE EPagHistoricoRubricaVinculo HRV
                        SET VlPagamento = vVlMargemErario
                      WHERE HRV.CdVinculo = rVinculo.CdVinculo
                        AND HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                        AND HRV.CdRubricaAgrupamento = pkgpag_var.vgCdRubDescontoIRESA;

                     UPDATE EPagHistoricoRubricaRelVinc HRR
                        SET HRR.Vlproporcional = vVlMargemErario,
                            hrr.vlintegral = vVlMargemErario
                      WHERE HRR.CdVinculo = rVinculo.CdVinculo
                        AND HRR.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                        AND HRR.CdRubricaAgrupamento = pkgpag_var.vgCdRubDescontoIRESA;

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
                           PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                           pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,9,1573),
                           rVinculo.CdVinculo ,
                           1,
                           null,
                           pkgpag_var.vgvldescontoiresa - vVlMargemErario,
                           1,
                           100,
                           systimestamp,
                           null,
                           null,
                           4,
                           null);

                END IF;

                DELETE ePagHistoricoRubricaVinculo HRV
                 WHERE HRV.CDRUBRICAAGRUPAMENTO = PKGPAG_VAR.vgCdRubricaErario
                   AND HRV.CdVinculo = rVinculo.CdVinculo
                   AND HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento;

          END IF;

           PKGPAG_RE.PRestituicaoErario(PKGPAG_VAR.vgFolha,
                                       rVinculo.CdVinculo,
                                       pFlCalculoDefinitivo,
                                       'S');

        END IF;

        PKGPAG_GERAL.PLogProc('CAL04030520','CAL04030521','Vale e Diversos');

        ------------------------------------------------------------------------------
        -- Desconto de vale transporte
        ------------------------------------------------------------------------------

        IF PKGPAG_VAR.vgCdRubValeTransporte IS NOT NULL OR
           ((PKGPAG_VAR.vgAfastTempRemunMesAnt.Count > 0 or
             PKGPAG_VAR.vgIndiceFaltasMesAnterior > 0) AND
            PKGPAG_VAR.vgFolha.CdAgrupamento = 176 AND
            PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaBolsista) THEN

          PKGPAG_POS.PDescontoValeTransporte(rVinculo.CdVinculo,
                                             PKGPAG_VAR.vgFolha,
                                             PKGPAG_VAR.vgCdRubValeTransporte,
                                             pFlCalculoDefinitivo,
                                             PKGPAG_VAR.vDtCalculo);

        END IF;

        -----------------------------------------------------------------------------------
        -- Atualiza o valor da base contribuicao do plano de saude ( Modalidade 21)
        -- abatendo as rubricas do tipo 8 que fazem parte da expressao do calculo da base
        -----------------------------------------------------------------------------------

        /*if nvl(PKGPAG_VAR.vgIndiceFaltasMesAnterior,0) < 30 then
           -- Solicitacao de Sustentacao  #79983
           -- 12316/2018 - FALTAS PRIORIDADE SOBRE DESC SC SAUDE
           -- Somente descontar plano de saude se o total de faltas do mes anterior nao estiver zerando o contra cheque.
           -- na rotina de liquido negativo eh feito um ajuste especifico nesta rubrica de faltas e o calculo
           -- acabava compensando as diferencas, ou seja, permitia o desconto do scsaude e depois ajustava a diferenca no
           -- desconto de faltas.

            IF PKGPAG_VAR.vgCdRubricaBasePlanoSaude > 0 THEN

              PKGPAG_FB.PAtualizaBaseCalculo(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo        => rVinculo.CdVinculo,
                                             pCdRubrica        => PKGPAG_VAR.vgCdRubricaBasePlanoSaude);
            END IF;

            -------------------------------------------------------------------------------
            -- Desconto de plano de saude de titular
            -------------------------------------------------------------------------------

            IF PKGPAG_VAR.vgCdRubDescPlanSauTit IS NOT NULL THEN

              PKGPAG_POS.PDescontoPlanoSaudeTitular(pCdVinculo => rVinculo.CdVinculo,
                                                    pFolha     => PKGPAG_VAR.vgFolha,
                                                    pRubrica   => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubDescPlanSauTit));

              PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo);

              if PKGPAG_VAR.vgVlTotalProventos < PKGPAG_VAR.vgVlTotalDescontos then

                 vVlRubrica := 0;

                 vVlRubrica := PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                 rVinculo.CdVinculo,
                                                                 PKGPAG_VAR.vgCdRubDescPlanSauTit) -
                                                                 (PKGPAG_VAR.vgVlTotalDescontos - PKGPAG_VAR.vgVlTotalProventos);

                 vVlCalculadoRubrica.vlIntegral := vVlRubrica;

                 pAtualizaValorRubrica(rVinculo.CdVinculo,  PKGPAG_VAR.vgFolha.CdFolhaPagamento, PKGPAG_VAR.vgCdRubDescPlanSauTit, vVlCalculadoRubrica);

                 PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo);

              end if;

            END IF;

            ---------------------------------------------------------------------------------
            -- Patronal de SC saude
            ---------------------------------------------------------------------------------

            IF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                 pCdVinculo        => rVinculo.CdVinculo,
                                                 pCdRubrica        => PKGPAG_VAR.vgCdRubricaBasePSPatronal) = 0 THEN

              IF NVL(PKGPAG_VAR.vgCdRubricaBasePSPatronal, 0) > 0 THEN

                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                      pCdVinculo            => rVinculo.CdVinculo,
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
                                               pCdVinculo       => rVinculo.CdVinculo,
                                               pCdRubrica       => PKGPAG_VAR.vgCdRubricaBasePSPatronal,
                                               pTpProcessamento => 2, -- Processa base de calculo
                                               pTpLocal         => 2); -- no vinculo
            END IF;

            --------------------------------------------------------------------------------
            -- Desconto de plano de saude de agregados
            --------------------------------------------------------------------------------

            IF PKGPAG_VAR.vgCdRubDescPlanSauAgr IS NOT NULL and
               PKGPAG_VAR.vgVlTotalProventos > PKGPAG_VAR.vgVlTotalDescontos

              THEN

              PKGPAG_POS.PDescontoPlanoSaudeAgreg(pCdVinculo => rVinculo.CdVinculo,
                                                  pFolha     => PKGPAG_VAR.vgFolha,
                                                  pRubrica   => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubDescPlanSauAgr));

            END IF;

            --------------------------------------------------------------------------------
            -- Desconto de co-participacao
            --------------------------------------------------------------------------------

            IF PKGPAG_VAR.vgCdEventoDescCoPart IS NOT NULL and
               PKGPAG_VAR.vgVlTotalProventos > PKGPAG_VAR.vgVlTotalDescontos THEN

              PKGPAG_POS.PDescontoCoParticipacao(pCdVinculo           => rVinculo.CdVinculo,
                                                 pFolha               => PKGPAG_VAR.vgFolha,
                                                 pRubrica             => PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoDescCoPart)
                                                                                              .CdRubricaAgrupamento),
                                                 pEvento              => PKGPAG_VAR.vgEvento(PKGPAG_VAR.vgCdEventoDescCoPart),
                                                 pFlCalculoDefinitivo => pFlCalculoDefinitivo);
            END IF;

        end if;*/

        PKGPAG_GERAL.PLogProcFim('CAL04030521');

      ELSE

        GOTO FIM_LOOP;

      END IF;

    END IF;

    PKGPAG_GERAL.PLogProcFim('CAL040305');

    if  (PKGPAG_VAR.vgVinculo.DtDesligamento <= PKGPAG_VAR.vgFolha.DtFimMes) then
    -- A partir de Dezembro 2023 somente gerar rubricas de 13 na folha normal para casos de rescisao
    -- DESCONTO 08-0023 E 08-0024 para quem tem as bases 09-9024 e 09-9023 no mes anterior
    --
        IF rvinculo.DtAdmissao < PKGPAG_VAR.vgFolha.DtInicioMes
          AND (PKGPAG_VAR.vgCdRubBase080023DescParcial IS NOT NULL
               OR PKGPAG_VAR.vgCdRubBase080024DescParcial IS NOT NULL)
          AND PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal
          AND PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal
        THEN
            pkgpag_pos.PSaldoDevolucao13(pCdVinculo => rVinculo.CdVinculo, pFolha => PKGPAG_VAR.vgFolha);
        END IF;

        IF rvinculo.DtAdmissao < PKGPAG_VAR.vgFolha.DtInicioMes
          AND PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaCtisp
          AND PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal
        THEN
            pkgpag_pos.PSaldoDevolucao13Ctisp(pCdVinculo => rVinculo.CdVinculo, pFolha => PKGPAG_VAR.vgFolha);
        END IF;

    end if;

    if pkgpag_var.vgFolha.CdTipoFolhaPagamento NOT IN (1505,1525,1526) then
        PKGPAG_POS.PAjustarSaldoDevedor13(pCdVinculo => rVinculo.CdVinculo,
                                             pFolha => PKGPAG_VAR.vgFolha);
    end if;


    -------------------------------------------------------------------
    -- Processa tributacoes e pensoes alimenticias
    --------------------------------------------------------------------------

    vvlBaseIprev13SalResc := pkgpag_geral.fretornavaloroutrasrv(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                      pcdvinculo => rVinculo.CdVinculo,
                                      pcdrubricaagrupamento => pkgpag_geral.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                 pcdtiporubrica => 1,
                                                                                 pNuRubrica => 1023));

    IF NVL(vvlBaseIprev13SalResc.vlProporcional,0) = 0 THEN
      vvlBaseIprev13SalResc.vlProporcional := PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                 pcdvinculo => RVINCULO.CdVinculo,
                                                                 pcdrubrica => pkgpag_geral.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                            pcdtiporubrica => 1,
                                                                                                            pNuRubrica => 1023));
    END IF;
    -- Solicitacao de Sustentacao #77583
    -- Para a Defensoria Publica, Caso haja a rubrica 01-1023, esta assume a base do BASE-IPESC-13 09-0920
    IF NVL(vvlBaseIprev13SalResc.vlProporcional,0) > 0
      AND pkgpag_var.vgCdRubBaseIPESC13 > 0
      AND NOT pkgpag_geral.fpossuilancfinanceiro(rVinculo.CdVinculo,
                                                  PKGPAG_VAR.vgFolha,
                                                  pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,920))  THEN

      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => pkgpag_var.vgCdRubBaseIPESC13,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

    END IF;

    PAtualizaBaseSCSaude(rVinculo.CdVinculo);

    -- Nao processa para folha PDVI CIASC
    IF PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento <> 765

       THEN
      -- 765 = FOLHA PDVI

      IF PKGPAG_VAR.vgFolha.cdTipoFolha = PKGPAG_TIPO.cnTpFolhaServAfast
        THEN

        PDifVlPagamentoVincSemRemun(pCdVinculo        => rVinculo.CdVinculo,
                                                  pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pNuAnoReferencia  => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                  pNuMesReferencia  => PKGPAG_VAR.vgFolha.NuMesReferencia,
                                                  pCdTipoFolha      => PKGPAG_VAR.vgFolha.CdTipoFolha,
                                                  pCdTipoCalculo    => PKGPAG_VAR.vgFolha.CdTipoCalculo);

      END IF;

      if PKGPAG_VAR.vgFolha.cdorgao = 25 -- Reprocessar base

         THEN

          PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => 49218,
                                           pTpProcessamento => 2, -- Processa base de calculo  Patronal Ceres
                                           pTpLocal         => 2);

          if nvl(pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                        rVinculo.CdVinculo,
                                                        pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803)),0) > 0 then

              PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                               pCdVinculo       => rVinculo.CdVinculo,
                                               pCdRubrica       => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803),
                                               pTpProcessamento => 1, -- Processa base de c?lculo
                                               pTpLocal         => 2);


              delete epaghistoricorubricarelvinc rvc
               where rvc.cdvinculo = rVinculo.CdVinculo
                 and rvc.cdfolhapagamento =  PKGPAG_VAR.vgFolha.CdFolhaPagamento
                 and rvc.cdhistcargoefetivo is null
                 and rvc.cdrubricaagrupamento =   pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803);

              update epaghistoricorubricarelvinc rvc
                 set rvc.vlintegral = pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                        rVinculo.CdVinculo,
                                                                        pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                     rvc.vlreal = pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                        rVinculo.CdVinculo,
                                                                        pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                     rvc.vlproporcional = pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                        rVinculo.CdVinculo,
                                                                        pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803))
               where rvc.cdvinculo = rVinculo.CdVinculo
                 and rvc.cdfolhapagamento =  PKGPAG_VAR.vgFolha.CdFolhaPagamento
                 and rvc.cdhistcargoefetivo is not null
                 and rvc.cdrubricaagrupamento =   pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803);


          end if;

      end if;

      IF pkgpag_var.vgFolha.cdtipofolha <> PKGPAG_TIPO.cnTpFolhaInstPensao THEN            

          -- Quando não observa limite de erário, processa o erário antes da tributação apenas
          -- das rubricas que estão na base do IR, para evitar líquido negativo
          PKGPAG_RE.PRestituicaoErario(PKGPAG_VAR.vgFolha,
                                       rVinculo.CdVinculo,
                                       pFlCalculoDefinitivo,
                                       'N',
                                       'S');
                                       
          PKGPAG_GERAL.PLogProcIni('CAL0404','Tributacao');

          PKGPAG_GERAL.PLogProcIni('CAL040401','Processa Trib e Pensao');
          
          -- Gerar lancamentos financeiros de tributação caso exista
/*       
          IF vQtdeNaoLancados > 0 THEN
         
             PKGPAG_LF.PLancamentosFinanceiros(pFolha           => PKGPAG_VAR.vgFolha,
                                               pCdVinculo       => rVinculo.CdVinculo,
                                               pFormExpr        => PKGPAG_VAR.vgFormExpr,
                                               pDtCalculo       => pDtCalculo,
                                               pLstRubTrib      => pTributacao.lstRubTrib,
                                               pFlTributacao    => 'S',
                                               pQtdeNaoLancados => vQtdeNaoLancados);
          END IF;
*/                                                   
          PKGPAG_TRIBUTACAO.PProcessaTributacaoEPensao(pTributacao     => PTributacao,
                                                       pCdPessoa       => rVinculo.CdPessoa,
                                                       pCdVinculo      => rVinculo.CdVinculo);

          PKGPAG_GERAL.PLogProc('CAL040401','CAL040402','Processa Base Consig');
 
          -- Processa os descontos de adiantamento salarial
          PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              rVinculo.CdVinculo);
                                              
          PKGPAG_LF.PDescontoAntecipSal(pFolha     => PKGPAG_VAR.vgFolha,
                                        pCdVinculo => rVinculo.CdVinculo);                      
                                
                               
          -- Processa os erários das rubricas que não estão na base de IR
          PKGPAG_RE.PRestituicaoErario(PKGPAG_VAR.vgFolha,
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
          if pkgpag_var.vgFolha.CdOrgao = 7 then

            if pkgpag_var.vgFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaFerias and
               pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgCdFolhaFerias,
                                                 pcdvinculo => rVinculo.CdVinculo,
                                                 pcdrubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,216)) > 0 and
                                                 pkgpag_var.vgfolha.cdtipofolhapagamento <> 1686 ----folhaPDVI SIG 11660

              then


                 PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                       pCdVinculo            => rVinculo.CdVinculo,
                                                       pCdExpressaoFormCalc  => NULL,
                                                       pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,4,216), --09-1008
                                                       pNuSufixoRubrica      => 1,
                                                       pVlPagamento          => pkgpag_geral.fretornavalorrubrica(
                                                                                      pcdfolhapagamento => PKGPAG_VAR.vgCdFolhaFerias,
                                                                                      pcdvinculo => rVinculo.CdVinculo,
                                                                                      pcdrubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,216)),
                                                       pVlIndice             => NULL,
                                                       pCdTipoOrigemRubrica  => 1);


            end if;

          end if;

       elsif PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = pkgpag_tipo.cnRegPrevCPSM then

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => rVinculo.CdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseCPSM,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

          PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => PKGPAG_VAR.vgCdRubBaseCPSM,
                                           pTpProcessamento => 2,
                                           pTpLocal         => 2);

          if pkgpag_geral.fretornavalorrubrica(
             pkgpag_var.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo,
             pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,38)) > 0 then

             begin

             PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                              pCdVinculo       => rVinculo.CdVinculo,
                                              pCdRubrica       => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,38),
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

   if PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = pkgpag_tipo.cnRegPrevCPSM and
      pkgpag_geral.fretornavalorrubrica(pkgpag_var.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo,
                                        pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,38)) > 0
      then

         begin

         vVlRubrica := pkgpag_fb.fCalculaFormula(pcdvinculo => rVinculo.CdVinculo,
                                                    pAnoMes => to_char(pkgpag_var.vgFolha.DtInicioMes,'yyyymm'),
                                                    pcdrubricaagrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,38),
                                                    pDeFormula => vDeFormula, pFlCalculoDefinitivo => pkgpag_var.vgFolha.FlCalculoDefinitivo );

          vvlCalculadoRubrica.vlIntegral := vVlRubrica;
          vvlCalculadoRubrica.vlProporcional := vVlRubrica;
          vvlCalculadoRubrica.vlReal := vVlRubrica;
          pkgpag_cal.pAtualizaValorRubrica(pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,38),
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

    IF (PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal OR
       PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaResidente OR
       PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFunebre OR
       (PKGPAG_VAR.vgFolha.cdorgao = 25 AND PKGPAG_VAR.vgFolha.CdTipoFolha = 10) OR -- Folha PDI da CIDASC       
       (PKGPAG_VAR.vgFolha.cdorgao = 583 AND PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaRescisao) -- Folha de Rescisão da SC Porto
       ) AND
       PKGPAG_VAR.vgFolha.CdTipoCalculo NOT IN
       (PKGPAG_TIPO.cnTpCalculoSupl) THEN

      --
      -- Processar cartoes de credito primeiro
      -- 10107/2017 - FOLHA - EN: FWD: EN: INADIMPLENCIA CARTAO DE CREDITO - LIMITE EMPREST.
      --

      pkgpag_var.vgValorAcumulado_CC := 0;

     IF PKGPAG_VAR.vgCdRubricaBaseCSG_CC IS NOT NULL
        THEN

         PKGPAG_CNS.PProcessaBaseConsig(pFolha               => PKGPAG_VAR.vgFolha,
                                         pCdVinculo           => rVinculo.CdVinculo,
                                         pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                         pDtCalculo           => pDtCalculo,
                                       pFlCartaoCredito     => 'S');
      END IF;

        PKGPAG_CNS.PProcessaBaseConsig(pFolha               => PKGPAG_VAR.vgFolha,
                                       pCdVinculo           => rVinculo.CdVinculo,
                                       pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                       pDtCalculo           => pDtCalculo,
                                       pFlCartaoCredito     => 'N');

    END IF;

    PKGPAG_GERAL.PLogProc('CAL040402','CAL040403','Gera Desc Tesouro');

    ------------------------------------------------------------------------------------
    -- Caso haja indicativo de que houveram pagamentos via tesouraria (Tipo rubrica = 3)
    -- ira gerar a rubrica de desconto 7-9999
    ------------------------------------------------------------------------------------
    IF PKGPAG_VAR.bPossuiLancTesouraria THEN

      PKGPAG_LF.PGeraDescontoLancTesouro(pFolha     => PKGPAG_VAR.vgFolha,
                                         pCdVinculo => rVinculo.CdVinculo);

    END IF;

    PKGPAG_GERAL.PLogProc('CAL040403','CAL040405','Atualiz Totalizadoras');

    PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                        rVinculo.CdVinculo);

    PKGPAG_GERAL.PLogProc('CAL040405','CAL040406','Ver Rescisao');

    ---------------------------------------------------------------------------------------------------------
    -- Caso o vinculo teve recisao
    ---------------------------------------------------------------------------------------------------------
    IF (PKGPAG_VAR.vgVinculo.DtDesligamento <= PKGPAG_VAR.vgFolha.DtFimMes) AND
       (PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                          rVinculo.CdVinculo,
                                          PKGPAG_VAR.vgCdRubricaDevAnt13) > 0)

      THEN

      vVlDescReal050524 := nvl(PKGPAG_GERAL.FRetornaValorRubrica(
                                 PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                 rVinculo.CdVinculo,
                                 PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,0524)),0);

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
           and fp.nuanoreferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia
           and (fp.numesreferencia < PKGPAG_VAR.vgFolha.NuMesReferencia OR (fp.numesreferencia = PKGPAG_VAR.vgFolha.NuMesReferencia AND tfp.cdtipofolha <> PKGPAG_VAR.vgFolha.cdtipofolha))
           and fp.flcalculodefinitivo = 'S'
           and H1.Cdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,0524)
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
              HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento AND
              HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                               5,
                                                                               0524);


        PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                        rVinculo.CdVinculo);

      ELSIF PKGPAG_VAR.vgVlTotalProventos < PKGPAG_VAR.vgVlTotalDescontos
        THEN

        vVlDescReal050524 := nvl(PKGPAG_GERAL.FRetornaValorRubrica(
                                 PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                 rVinculo.CdVinculo,
                                 PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,0524)),0);
                                 
        vVlDesc050524 := vVlDescReal050524 - (PKGPAG_VAR.vgVlTotalDescontos - PKGPAG_VAR.vgVlTotalProventos); 
        
        IF vVlDesc050524 < 0 THEN
          
           vVlDesc050524 := 0;
          
        END IF;

        vVlNaoDesc050524 := vVlDescReal050524 - vVlDesc050524;
       
        if vVlDesc050524 > PKGPAG_VAR.vgVlTotalProventos then
           
           vVlNaoDesc050524 := vVlNaoDesc050524 + (vVlDesc050524 - PKGPAG_VAR.vgVlTotalProventos);
          
           vVlDesc050524 := PKGPAG_VAR.vgVlTotalProventos;
           
        end if;

        -- Solicitacao de Sustentacao #71672: Rubrica 05-0524
        -- Nao gerar liquido negativo para ACT sem a presenca de remuneracao
        IF PKGPAG_VAR.vgFolha.CdOrgao = 41 AND --Orgao 2001
            PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT AND
            PKGPAG_VAR.vgVlTotalProventos = 0 THEN

              PKGPAG_VAR.vgVlTotalDescontos := 0;
        END IF;

        -- Nr da solicitacao: 6087/2014
        -- Correcao do calculo da rubrica 09-9524 e das rubricas 05-1023 e 05-0524.
        -- Alterado update abaixo para acertar os valores das rubricas
        --
        UPDATE EPagHistoricoRubricaVinculo HRV
          SET VlPagamento = vVlDesc050524
        WHERE HRV.CdVinculo = rVinculo.CdVinculo 
          AND HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento 
          AND HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                               5,
                                                                               0524);
        

        PKGPAG_VAR.vgVlBaseTotDSC := PKGPAG_VAR.vgVlTotalDescontos;

        --
        -- Desconsiderar da Base dos Descontos o total de faltas
        --

        vVlDescFaltas := nvl(PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                             rVinculo.CdVinculo,
                                             PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                25)),0);

        IF vVlDescFaltas > 0 AND
           PKGPAG_VAR.vgVlBaseTotalLiquida < 0 THEN

           PKGPAG_VAR.vgVlBaseTotDSC := PKGPAG_VAR.vgVlTotalDescontos - vVlDescFaltas;

        END IF;

        IF PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                             rVinculo.CdVinculo,
                                             PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado) > 0 THEN
               
          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.vlPagamento = HRV.vlPagamento + vVlNaoDesc050524
           WHERE HRV.cdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.cdVinculo = rVinculo.CdVinculo
             AND HRV.cdRubricaAgrupamento = PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado;  
                                       
        ELSE
          
           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                 pCdVinculo            => rVinculo.CdVinculo,
                                                 pCdExpressaoFormCalc  => NULL,
                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado,
                                                 pNuSufixoRubrica      => 1,
                                                 pVlPagamento          => vVlNaoDesc050524,
                                                 pVlIndice             => NULL,
                                                 pCdTipoOrigemRubrica  => 1);

        END IF;
                
        --
        -- Acertar valores das rubricas para nao gerar liquido negativo
        --

        PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            rVinculo.CdVinculo);

        /*IF PKGPAG_VAR.vgVlTotalProventos < PKGPAG_VAR.vgVlTotalDescontos

          THEN

         --  05-0524-01 ADIANT 13. SALARIO
         vVlDesc050524 := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo        => rVinculo.CdVinculo,
                                             pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                               5,
                                                                                              0524));
         IF PKGPAG_VAR.vgVlTotalDescontos - vVlDesc050524 > PKGPAG_VAR.vgVlTotalProventos
           THEN
           --Base tem q considerar o valor já pago do adiantamento
           PKGPAG_VAR.vgVlBaseTotDSC := PKGPAG_VAR.vgVlTotalDescontos - vVlDesc050524;

         END IF;

         vVlDesc050524 := PKGPAG_VAR.vgVlTotalDescontos - PKGPAG_VAR.vgVlTotalProventos;

         UPDATE EPagHistoricoRubricaVinculo HRV
             SET VlPagamento = vlPagamento - vVlDesc050524 --(PKGPAG_VAR.vgVlBaseTotDSC -
                               --PKGPAG_VAR.vgVlTotalProventos)
           WHERE HRV.CdVinculo = rVinculo.CdVinculo
             AND HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
             AND (vlPagamento -
                 (PKGPAG_VAR.vgVlBaseTotDSC - PKGPAG_VAR.vgVlTotalProventos)) > 0
             AND HRV.CdRubricaAgrupamento in
                 (PKGPAG_VAR.vgCdRubricaDevAnt13,
                  PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                               5,
                                               0524));
        END IF;*/
        

      END IF;

       --se não houver valor de proventos não gera o desconto
       IF (nvl(PKGPAG_VAR.vgVlTotalDescontos,0) = nvl(vVlDesc050524,0)
             AND nvl(PKGPAG_VAR.vgVlTotalProventos,0) = 0)
             --ou se já houve o desc de adiantamento em folha anterior
             OR (FPossuiDescAdiantamento13(rVinculo.CdVinculo,
                                       PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                               5,
                                               0524),
                                       PKGPAG_VAR.vgFolha.nuAnoReferencia,
                                       PKGPAG_VAR.vgFolha.nuMesReferencia)) > 0 THEN

            UPDATE EPagHistoricoRubricaVinculo HRV
             SET VlPagamento = 0
           WHERE HRV.CdVinculo = rVinculo.CdVinculo
             AND HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento in
                 (PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                               5,
                                               0524));

        END IF;

        PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              rVinculo.CdVinculo);

    END IF;

    PKGPAG_GERAL.PLogProcFim('CAL040406');
    
    PKGPAG_GERAL.PLogProc('CAL0404','CAL0405','Liq Negativo');

    ------------------------------------------------------------------------------------
    -- Atualmente so executa o evento PDescontoLiqNegativo para o CIASC e SC Parcerias e SANTUR
    ------------------------------------------------------------------------------------

    IF PKGPAG_VAR.vgFolha.CdAgrupamento IN (2, 3, 5, 6, 136) AND
       PKGPAG_VAR.vgFolha.CdTipoCalculo <>
       PKGPAG_TIPO.cnTpCalculoRecalcCompl THEN

      PKGPAG_POS.PDescontoLiqNegativo(pFolha     => PKGPAG_VAR.vgFolha,
                                      pCdVinculo => rVinculo.CdVinculo);

    END IF;

    PKGPAG_POS.PLiqNegativo(pFolha     => PKGPAG_VAR.vgFolha,
                            pCdVinculo => rVinculo.CdVinculo);

    -----------------------------------------------------------------
    -- Gera rubricas totalizadoras de Total de Proventos e Descontos
    -----------------------------------------------------------------

    PKGPAG_GERAL.PLogProc('CAL0405','CAL0406','Rub Tot');

    PKGPAG_GERAL.PAtualizaTotalizadoras(PKGPAG_VAR.vgFolha.CdFolhaPagamento,rVinculo.CdVinculo);

    IF PKGPAG_VAR.vgVlTotalProventos <> 0 OR
       PKGPAG_VAR.vgVlTotalDescontos <> 0 THEN

      IF PKGPAG_VAR.vgCdRubricaBaseTotPrv > 0 THEN

        IF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo        => rVinculo.CdVinculo,
                                             pCdRubrica        => PKGPAG_VAR.vgCdRubricaBaseTotPrv) = 0 THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => rVinculo.CdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotPrv,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => NVL(PKGPAG_VAR.vgVlTotalProventos,
                                                                             0),
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

        ELSE

          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.VlPagamento = NVL(PKGPAG_VAR.vgVlTotalProventos, 0)
           WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdVinculo = rVinculo.CdVinculo
             AND HRV.CdRubricaAgrupamento =
                 PKGPAG_VAR.vgCdRubricaBaseTotPrv;

        END IF;

      END IF;

      IF PKGPAG_VAR.vgCdRubricaBaseTotDsc > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => rVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotDsc,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => NVL(PKGPAG_VAR.vgVlTotalDescontos,
                                                                           0),
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

      END IF;

      IF PKGPAG_VAR.vgCdRubricaBaseTotLiq > 0 THEN

        PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => rVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseTotLiq,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => PKGPAG_VAR.vgVlBaseTotalLiquida,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

      END IF;

    END IF;

    PKGPAG_GERAL.PLogProc('CAL0406','CAL0407','Desc Facult');

    ---------------------------------------------------------------
    -- Gera rubrica totalizador de Total de descontos facultativos
    ---------------------------------------------------------------

    IF PKGPAG_VAR.vgCdRubBaseDescFacultativos > 0 THEN

      PKGPAG_VAR.vgVlTotalDescontosFacult := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                               pCdVinculo        => rVinculo.CdVinculo,
                                                                               pCdRubrica        => PKGPAG_VAR.vgCdRubricaCSGProc) +

                                             PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                               pCdVinculo        => rVinculo.CdVinculo,
                                                                               pCdRubrica        => PKGPAG_VAR.vgCdRubricaCSGNaoProc) +

                                              PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                pCdVinculo        => rVinculo.CdVinculo,
                                                                                pCdRubrica        => PKGPAG_VAR.vgCdRubricaCSGProcCC) ;

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => rVinculo.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDescFacultativos,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => NVL(PKGPAG_VAR.vgVlTotalDescontosFacult,
                                                                         0),
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);
    END IF;

    PKGPAG_GERAL.PLogProc('CAL0407','CAL0408','Rot Pos Calc');

    ------------------------------------------------------------------
    -- Regera a base do abono da SSP
    -- Motivo: A base e calculada em todas as relacoes, ao
    -- consolidar no vinculo ela pode subir "dobrada"
    ------------------------------------------------------------------

    IF PKGPAG_VAR.vgRubrica.EXISTS(PKGPAG_VAR.vgCdRubBaseAbonoSeguranca) THEN

      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseAbonoSeguranca,
                                       pTpProcessamento => 2, -- Processa base de calculo
                                       pTpLocal         => 2); -- no vinculo

    END IF;

    -------------------------------------------------------------------
    -- Gera capa
    -------------------------------------------------------------------

    IF PKGPAG_VAR.vPagaSitDisposicao NOT IN
       ('PAG-DEST-CALCULO-ORIGEM',
        'PAG-ORIGEM-CALCULO-DEST',
        'NAO-DISPOSICAO') or
        -- SIG-5023 NAO gerou capa do contracheque
        PKGPAG_VAR.vgVlTotalProventos > 0 THEN

      PKGPAG_GERAL.PGeraCapaLote(pCdFolhaPagamento      => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                 pCdVinculo             => rVinculo.CdVinculo,
                                 pFlAtivo               => pkgpag_geral.fflativo(rvinculo.CdVinculo, rvinculo.CdSituacaoPrevidenciaria),
                                 pMotAfast              => PKGPAG_VAR.vMotAfast,
                                 pFlPagamentoBloqueado  => rVinculo.FlPagamentoBloqueado,
                                 pVlPercentContribIndiv => pTributacao.inss.VlALiquotaContribIndiv);

    END IF;

    ----------------------------------------------------------------
    -- Executa rotina de pos calculo
    -- Nao deve conquistar PA de licenca premio com mais de 70 anos
    ----------------------------------------------------------------

    BEGIN

    IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
       PKGPAG_VAR.vgFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoSupl THEN

      IF MONTHS_BETWEEN(PKGPAG_VAR.vgFolha.DtFimMes,
                        PKGPAG_VAR.vgVinculo.DtNascimento) <
         PKGPAG_TIPO.cnMesesIdade70 THEN

        PKGPAG_PC.PGeraPerAquisLicPre(pVinculo             => rVinculo,
                                      pDtFimMes            => PKGPAG_VAR.vgFolha.DtFimMes,
                                      pCdTipoLicencaPremio => 1); -- Licenca Premio

        PKGPAG_PC.PGeraPerAquisLicPre(pVinculo             => rVinculo,
                                      pDtFimMes            => PKGPAG_VAR.vgFolha.DtFimMes,
                                      pCdTipoLicencaPremio => 2); -- Premio Assiduidade

      END IF;

    END IF;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;

    END;

    -- Valor Patronal INSS

    IF NVL(PKGPAG_VAR.vgCdRubBaseValorPatINSS, 0) > 0

     THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => rVinculo.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseValorPatINSS,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseValorPatINSS,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

    END IF;

    --
    -- Base Patronal IPREV FF
    -- Solicitacao de Sustentacao #68483
    -- 8505/2016 - FOLHA - - IDENTIFICACAO DA NAO GERACAO DO CODIGO 09-1017-PATRONAL DO IPREV FF
    --
    IF rVinculo.CdRegimePrevidenciario = pkgpag_tipo.cnRegPrevProprio
      AND rVinculo.CdSituacaoPrevidenciaria = pkgpag_tipo.cnSitPrevAtivo
      AND NVL(PKGPAG_VAR.vgCdRubBaseIPREVFF,0) > 0
      AND NVL(PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                        pcdvinculo => rVinculo.CdVinculo,
                                                        pcdrubrica => PKGPAG_VAR.vgCdRubBaseIPREVFF),0) = 0
     THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => rVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIPREVFF,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);

      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIPREVFF,
                                       pTpProcessamento => 2, -- Processa base de calculo
                                       pTpLocal         => 2); -- no vinculo

    END IF;
    --
    -- SIG-2236
    -- SEA - 14003/2019 - Patronal de IPREV para servidor INATIVO -- Nao deve gerar a patronal
    --
    IF rVinculo.CdRegimePrevidenciario = pkgpag_tipo.cnRegPrevProprio
      AND rVinculo.CdSituacaoPrevidenciaria IN (pkgpag_tipo.cnSitPrevInstPensao, pkgpag_tipo.cnSitPrevFalecido)
      AND NVL(PKGPAG_VAR.vgCdRubBaseIPREVFF,0) > 0
      AND NVL(PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                        pcdvinculo => rVinculo.CdVinculo,
                                                        pcdrubrica => PKGPAG_VAR.vgCdRubBaseIPREVFF),0) > 0
     THEN

         delete epaghistoricorubricavinculo hrvc
           where hrvc.cdvinculo = rVinculo.CdVinculo
             and hrvc.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
             and hrvc.cdrubricaagrupamento = PKGPAG_VAR.vgCdRubBaseIPREVFF;

    END IF;


    IF PKGPAG_VAR.vgFolha.cdorgao = 25 -- Reprocessar base

     THEN

      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 49218,
                                       pTpProcessamento => 2, -- Processa base de calculo  Patronal Ceres
                                       pTpLocal         => 2);

      if nvl(pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803)),0) > 0 then

          PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                           pCdVinculo       => rVinculo.CdVinculo,
                                           pCdRubrica       => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803),
                                           pTpProcessamento => 1, -- Processa base de c?lculo
                                           pTpLocal         => 2);


          delete epaghistoricorubricarelvinc rvc
           where rvc.cdvinculo = rVinculo.CdVinculo
             and rvc.cdfolhapagamento =  PKGPAG_VAR.vgFolha.CdFolhaPagamento
             and rvc.cdhistcargoefetivo is null
             and rvc.cdrubricaagrupamento =   pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803);

          update epaghistoricorubricarelvinc rvc
             set rvc.vlintegral = pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    rVinculo.CdVinculo,
                                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                 rvc.vlreal = pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    rVinculo.CdVinculo,
                                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803)),
                 rvc.vlproporcional = pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    rVinculo.CdVinculo,
                                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803))
           where rvc.cdvinculo = rVinculo.CdVinculo
             and rvc.cdfolhapagamento =  PKGPAG_VAR.vgFolha.CdFolhaPagamento
             and rvc.cdhistcargoefetivo is not null
             and rvc.cdrubricaagrupamento =   pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,803);


      end if;

      --
      -- Alterar codigos das rubricas de ferias para comissionados que optaram pelo recebimento: PELO CARGO COMISSIONADO ou PELO F.G. OU F.T.G
      --
      if pkgpag_var.vgcco.count > 0
        then
        for i in pkgpag_var.vgcco.first .. pkgpag_var.vgcco.last
        loop

        if pkgpag_var.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaFerias and
         --pkgpag_var.vgcco.count > 0 and
         fretornaopcaoremuneracaocco(pcdhistcargocom => pkgpag_var.vgcco(i).cdhistcargocom,
                                                               pdtiniciomes => pkgpag_var.vgfolha.dtiniciomes,
                                                               pdtfimmes => pkgpag_var.vgfolha.dtfimmes)  in (3,6)
         then

           if nvl(pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,7)),0) > 0 then

             pAtualizaValorRubrica (pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,7),
                                    pValorRubrica => vvlCalculadoRubrica,
                                    pCdOutraRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,1207));


           end if;

           if nvl(pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,56)),0) > 0 then

              pAtualizaValorRubrica (pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,56),
                                    pValorRubrica => vvlCalculadoRubrica,
                                    pCdOutraRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,1256));

           end if;

           if nvl(pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                    rVinculo.CdVinculo,
                                                    pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,83)),0) > 0 then

              pAtualizaValorRubrica (pCdVinculo => rVinculo.CdVinculo,
                                    pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                    pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,83),
                                    pValorRubrica => vvlCalculadoRubrica,
                                    pCdOutraRubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,1283));

           end if;

      end if;

      end loop;

     end if;
    end if;

    BEGIN

        IF PKGPAG_VAR.vgFolha.cdorgao = 25
        AND nvl(pkgpag_var.vgValorCalculoRubrica(49205).VlLimiteInferior, 0) > 0
        AND pkgpag_geral.fretornavalorrubrica(pcdfolhapagamento  => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                    pcdvinculo           => rVinculo.CdVinculo,
                                                                    pcdrubrica           => 49205,
                                                                    pnusufixo            => 1) < nvl(pkgpag_var.vgValorCalculoRubrica(49205).VlLimiteInferior, 0) THEN

        vvlCalculadoRubrica.vlIntegral := pkgpag_var.vgValorCalculoRubrica(49205).VlLimiteInferior;

        pAtualizaValorRubrica (rVinculo.CdVinculo,
                               PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                               49205,
                               vvlCalculadoRubrica);

        END IF;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END ;                                                                   

    IF PKGPAG_VAR.vgFolha.cdorgao = 27 -- forcar o calculo das ferias

     THEN

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => rVinculo.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => 44591, --09-1008
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 44591,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- BASE CASACARESC  09-0955
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 44581,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- BASE SAUDE PATRONAL 09-0380
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => rVinculo.CdVinculo,
                                       pCdRubrica       => 45639,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- BASE BAIXA DE FERIAS INDENIZADAS 09-2007
      IF PKGPAG_GERAL.fRetornaValorRubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                  pcdvinculo => rVinculo.CdVinculo,
                                                  pcdrubrica => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,294)) > 0
       THEN

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => rVinculo.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => 47724,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);

         PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                          pCdVinculo       => rVinculo.CdVinculo,
                                          pCdRubrica       => 47724,
                                          pTpProcessamento => 2, -- Processa base de c?lculo
                                          pTpLocal         => 2);
      END IF;

    END IF;

    if pkgpag_geral.fpossuilancfinanceiro(rVinculo.CdVinculo,
                                          PKGPAG_VAR.vgFolha,
                                          pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,8184))
      and nvl(pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                rVinculo.CdVinculo,
                                                pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,8184)),0) > 0 then

      begin

      delete epaghistoricorubricavinculo hrv
       where cdvinculo = rVinculo.CdVinculo
         and cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
         and cdrubricaagrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,8184)
         and hrv.cdtipoorigemrubrica <> 2;

      delete epaghistoricorubricarelvinc hrr
       where cdvinculo = rVinculo.CdVinculo
         and cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
         and cdrubricaagrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,8184)
         and hrr.cdtipoorigemrubrica <> 2;

       exception
         when others then
           null;
       end;

    end if;
    --
    -- GERAR OCORRENCIA DE ERRO PARA LIQUIDO NEGATIVO DE PENSIONISTA -- Solicitacao de Sustentacao #64581
    --
    IF pkgpag_var.bPossuiPensao
      THEN

         PKGPAG_GERAL.pValidaTotalPensao(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                pcdvinculo => rVinculo.CdVinculo);
    END IF;

    --
    -- Exclusao de rubricas de base de pensao com valor = 1
    --
    IF NVL(pkgpag_geral.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                rVinculo.CdVinculo,
                                                pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,9053)),0) <= 1
       THEN

         DELETE FROM EpagHistoricoRubricaVinculo HRV
               WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                AND  HRV.CdVinculo = rVinculo.CdVinculo
                AND  HRV.Cdrubricaagrupamento in (pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,9052),
                                                  pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,9053));

    END IF;

    PKGPAG_GERAL.PExcluiValoresZerados(pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                       pCdVinculo        => rVinculo.CdVinculo);

    PKGPAG_GERAL.PLogProc('CAL0408','CAL0409','Del Hist Rub');

    IF PKGPAG_VAR.vgVlTotalProventos = 0 AND
       PKGPAG_VAR.vgVlTotalDescontos = 0 THEN

      DELETE FROM EpagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
         AND HRV.CdVinculo = rVinculo.CdVinculo;

    ELSIF PKGPAG_VAR.vListaRubricas.EXISTS(8774) THEN

      IF PKGPAG_VAR.vgVlTotalProventos = PKGPAG_VAR.vListaRubricas(8774) THEN

        PKGPAG_GERAL.PExcluirPagVinc(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                     rVinculo.CdVinculo);

      END IF;

    ELSIF PKGPAG_VAR.vgFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoSupl THEN

      PExpurgarTotalizadoras(pFolha   => PKGPAG_VAR.vgFolha,
                             pVinculo => rVinculo);

    else
      null;
    END IF;

    PKGPAG_GERAL.PLogProcFim('CAL0409');
    
    ------------------------------------------------------------------------------
    -- Garante que rubricas nao terao sufixos duplicados no contracheque
    ------------------------------------------------------------------------------

    --PKGPAG_GERAL.PLogProcIni ('CAL0410','Trata Sufixo Duplicado');

    --PTrataSufixosDuplicados(pCdVinculo        => rVinculo.CdVinculo,
    --                        pCdFolhaPagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento);

    --PKGPAG_GERAL.PLogProcFim ('CAL0410');
    
    PKGPAG_GERAL.PLogProcIni('CAL0411','Pedido DGRH');

    --------------------------------------------------------------------------------------
    -- Caso a origem do calculo seja previa, 1 calculo ou 2 calculo
    -- realiza a copia dos contra-cheques da normal para a
    -- folha do tipo de calculo
    --------------------------------------------------------------------------------------

    IF PKGPAG_VAR.vgFolhaOrigem.CdTipoCalculo IN (7, 8, 9) THEN

      PCopiaContraCheques(pCdFolhaOrigem  => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                          pCdFolhaDestino => PKGPAG_VAR.vgFolhaOrigem.CdFolhaPagamento,
                          pCdVinculo      => rVinculo.CdVinculo);

    END IF;

    PKGPAG_GERAL.PLogProcFim('CAL0411');
    
   IF pFlCalculoDefinitivo = 'S'

    THEN
    -- Conta os dias de falta que seao descontados
    -- e salva na variavel  vNuFaltas
   ------------------------------------------------------------------------------

   -- Inicializa a variavel
    vNuFaltas:= tFalta();
    vNuFaltas.Extend(12);

    if   pkgpag_var.vgFaltas.count > 0
        and (PKGPAG_VAR.vgIndiceFaltasMesAnterior  > 0 or  PKGPAG_VAR.vgIndiceFaltasMesAtual > 0) then

          for i in pkgpag_var.vgFaltas.first .. pkgpag_var.vgFaltas.last
            loop

              if pkgpag_var.vgFaltas(i).FlAbonado = 'N' then

              vNuMEsFalta := to_char( pkgpag_var.vgFaltas(i).DtFrequencia,'mm');
               vNuFaltas(vnuMesFalta) :=  NVL(vNufaltas(vNumesFalta),0) +
                                        (pkgpag_var.vgfaltas(i).numfracaofalta / pkgpag_var.vgFaltas(i).denfracaofalta);
              --vNuFaltas(vnuMesFalta) :=  NVL(vNufaltas(vNumesFalta),0) + 1;

               end if;
           end loop;

           if PKGPAG_VAR.vgIndiceFaltasMesAtual > 0 -- Evento 82
             then
                PKGPAG_POS.PAtualizaEventoVinculo(pCdVinculo     => rVinculo.CdVinculo,
                                                                                  pFolha         => PKGPAG_VAR.vgFolha,
                                                                                  pCdTipoEvento  => 4,
                                                                                  pCdRubrica => PKGPAG_VAR.vgCdRubEvento82,
                                                                                  pVlIndice => PKGPAG_VAR.vgIndiceFaltasMesAtual ); --

           end if;

           if PKGPAG_VAR.vgIndiceFaltasMesAnterior > 0 -- Evento 81
             then

                 for i in 1 .. 12
                   loop

                      if vNuFaltas(i) is not null
                        then
                            PKGPAG_POS.PAtualizaEventoVinculo(pCdVinculo     => rVinculo.CdVinculo,
                                                                                  pFolha         => PKGPAG_VAR.vgFolha,
                                                                                              pCdTipoEvento  => 4,
                                                                                              pCdRubrica => PKGPAG_VAR.vgCdRubEvento81,
                                                                                              pVlIndice => vNuFaltas(i),
                                                                                              pNuMes => i,
                                                                                              pNuAno => case when i > pkgpag_var.vgfolha.numesreferencia
                                                                                                                  then  pkgpag_var.vgfolha.nuanoreferencia -1
                                                                                                                  else  pkgpag_var.vgfolha.nuanoreferencia end) ;

                     end if;

                   end loop;

           end if;

      end if;

    END IF;

   -- pPossuiLancFinSemRegistro(pkgpag_var.vgFolha, rVinculo.CdVinculo);

    IF PKGPAG_VAR.vgFolha.cdtipofolha in (pkgpag_tipo.cnTpFolhaServAfast) THEN
      UPDATE eafaafastamentovinculo Afa
         SET Afa.Flanulado = PKGPAG_TIPO.cnN
       WHERE Afa.Cdafastamento in (select a.cdafastamento
                                     from epaghistfolhaservafast a
                                    where a.cdfolhapagamento = pkgpag_var.vgFolha.cdFolhaPagamento
                                      and a.cdvinculo = rVinculo.CdVinculo);
      delete epaghistfolhaservafast a
       where a.cdfolhapagamento = pkgpag_var.vgFolha.cdFolhaPagamento
         and a.cdvinculo = rVinculo.CdVinculo;
    END IF;

    -- Expugar contra-cheque "Outras Folhas" que não possuem valor - EXTRATOR
    IF pkgpag_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766)
      AND pkgpag_var.vgFolha.FlCalculoDefinitivo = 'S'
      THEN

      for dados in (select capa.cdfolhapagamento,
                           capa.cdvinculo
                      from epagcapahistrubricavinculo capa
                     Where capa.cdfolhapagamento = pkgpag_var.vgFolha.CdFolhaPagamento
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


 PROCEDURE PGeraTotalizadoras(pCalculo          IN PKGPAG_CAL.rCalculo,
                             pCdVinculo        IN INTEGER,
                             pCdFolhaPagamento IN INTEGER) IS

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
                                pFlPagamentoBloqueado     => PKGPAG_VAR.vgVinculo.FlPagamentoBloqueado);



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

  /*-----------------------------------------------------------------------------------------/
      Objetivo: Processamento do Vinculo - Parte Suplementar
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE PProcessarVincCalcSupl(rVinculo             IN PKGPAG_TIPO.rVinculo,
                                   pVlDiferencaValor    IN NUMBER,
                                   pFlCalculoDefinitivo IN CHAR) IS

  BEGIN
 
    PKGPAG_GERAL.PLogProcIni('CAL040301','Folha Sup');

    PKGPAG_VAR.vgFaseCalculo := PKGPAG_TIPO.cnFaseCalculoSuplementar;

    PKGPAG_VAR.vgVinculo := rVinculo;

    PKGPAG_VAR.vgFolhaOrigem := PKGPAG_VAR.vgFolhaOrigemAux;

    PProcessaFolhaSuplementar(PKGPAG_VAR.vgFolha,
                              PKGPAG_VAR.vgFolhaOrigem,
                              PKGPAG_VAR.vgFolhaRecalculo,
                              rVinculo.CdVinculo,
                              pFlCalculoDefinitivo,
                              pVlDiferencaValor,
                              rVinculo.CdFolhaPagamentoNormal);

    PKGPAG_GERAL.PLogProcFim('CAL040301');
    
    PProcessarVincCalcErario(rVinculo             => rVinculo,
                             pFlCalculoDefinitivo => pFlCalculoDefinitivo);

  END;
  
  FUNCTION FFormatarMatricula (pCdVinculo IN INTEGER) RETURN VARCHAR2 IS
     vMatricula VARCHAR2(12);
  BEGIN
     SELECT LPAD(NUMATRICULA,7,'0') || '-' || NUDVMATRICULA || '-' || LPAD(NUSEQMATRICULA,2,'0')
       INTO vMatricula
       FROM ECADVINCULO
      WHERE CdVinculo = pCdVinculo;   
  
     RETURN vMatricula;
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
                                    pFlPagaAdiantamento  IN CHAR,
                                    pTributacao      IN OUT NOCOPY PKGPAG_TRIBUTACAO.rTributacao) IS

    rVinculo PKGPAG_TIPO.rVinculo;

    ---- INICIO DO CaLCULO DA FOLHA APoS ARMAZRNAMENTO DE INFORMAcoES DO ViNCULO ----

  BEGIN
     
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
    IF pkgpag_var.vgFolha.cdtipofolha <> PKGPAG_TIPO.cnTpFolhaInstPensao THEN
      rVinculo.DtDesligamento           := pRegVinc.DtDesligamento;
    END IF;
    rVinculo.DtNascimento             := pRegVinc.DtNascimento;
    rVinculo.DtInclusao               := pRegVinc.DtInclusao;
    rVinculo.FlSexo                   := pRegVinc.FlSexo;
    rVinculo.CdOpcaoAuxilioAli        := pRegVinc.CdOpcaoAuxilioAli;
    rVinculo.FlOutroVincCalculado     := pRegVinc.FlOutroVincCalculado;
    rVinculo.FlOutroVincACalcular     := pRegVinc.FlOutroVincACalcular;
    rVinculo.CdFolhaPagamentoNormal   := PKGPAG_GERAL.FCodigoFolhaNormalVinc(pCdVinculo => rVinculo.CdVinculo,
                                                                             pFolha     => PKGPAG_VAR.vgFolha);

    rVinculo.bPossuiObito := CASE
                               WHEN pRegVinc.FlPossuiObito = 1 AND
                                    pkgpag_var.vgFolha.cdtipofolha <> PKGPAG_TIPO.cnTpFolhaInstPensao THEN
                                TRUE
                               ELSE
                                FALSE
                             END;

    rVinculo.FlPagamentoBloqueado := 'N';

    if rVinculo.CdOrgao = 2
        and rVinculo.CdOrgao <> pkgpag_var.vgFolha.CdOrgao
        and pkgpag_var.vgFolha.CdTipoFolhaPagamento IN (1505,1525,1526,1766) then

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

    PKGPAG_GERAL.PSetaDadosBancarios(rVinculo.CdVinculo,
                                     PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                     PKGPAG_VAR.vgFolha.NuMesReferencia,
                                     pDtCalculo);

    PKGPAG_GERAL.PLogProcIni('CAL0403','Calculao');

    PKGPAG_GERAL.PLogProcIni('CAL040301','Carregar Folha Vinculo');
                                  
    PKGPAG_GERAL.PCarregarFolhaVinculo (pCdCalculo          => pCalculo.cdCalculo, 
                                        pCdPessoa           => rVinculo.CdPessoa,
                                        pFlIniciarPessoa    => 1);

    PKGPAG_GERAL.PLogProcFim('CAL040301');

    CASE

    /*----------------------------------------------------------------------------*/
    -- Fluxo para tipo de calculo NORMAL/RECALCULO/SIMULACAO/CALCULO RETROATIVO
    /*----------------------------------------------------------------------------*/

      WHEN PKGPAG_VAR.vgFolha.CdTipoCalculo IN
           (PKGPAG_TIPO.cnTpCalculoNormal,
            PKGPAG_TIPO.cnTpCalculoRecalculoMes,
            PKGPAG_TIPO.cnTpCalculoRecalcCompl,
            PKGPAG_TIPO.cnTpCalculoSimulacao)
      THEN

        PProcessarVincCalcIntegral(pCalculo             => pCalculo,
                                   rVinculo             => rVinculo,
                                   pDtCalculo           => pDtCalculo,
                                   pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                   pFlPagaAdiantamento  => pFlPagaAdiantamento,
                                   pTributacao          => pTributacao);

    -----------------------------------------------------------------------------
    -- Fluxo para tipo de calculo SUPLEMENTAR
    -----------------------------------------------------------------------------

      WHEN PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl THEN

        PProcessarVincCalcSupl(rVinculo             => rVinculo,
                               pVlDiferencaValor    => pVlDiferencaValor,
                               pFlCalculoDefinitivo => pFlCalculoDefinitivo);

    -----------------------------------------------------------------------------
    -- Fluxo para tipo de calculo NORMAL e SUPLEMENTAR
    -----------------------------------------------------------------------------
     /*Gerar apenas para ACTs: foi utilizado o regime pois essa folha é aberta apenas para Educação*/
      WHEN PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes AND 
           rVinculo.CdRegimePrevidenciario = PKGPAG_TIPO.cnRegPrevGeral THEN 

        PProcessarVincCalcIntegral(pCalculo             => pCalculo,
                                   rVinculo             => rVinculo,
                                   pDtCalculo           => pDtCalculo,
                                   pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                   pFlPagaAdiantamento  => pFlPagaAdiantamento,
                                   pTributacao          => pTributacao);

        PProcessarVincCalcSupl(rVinculo             => rVinculo,
                               pVlDiferencaValor    => pVlDiferencaValor,
                               pFlCalculoDefinitivo => pFlCalculoDefinitivo);

    else
      null;
    END CASE;

    IF pRegVinc.CdRegimePrevidenciario <> PKGPAG_TIPO.cnRegPrevGeral THEN
      PExcluirRubricasCLT(pCdVinculo => rVinculo.Cdvinculo,
                          pCdFolhaPagamento => PKGPAG_VAR.vgFolha.Cdfolhapagamento,
                          pCdAgrupamento => PKGPAG_VAR.vgFolha.cdAgrupamento);
    END IF;

    PKGPAG_GERAL.PLogProcFim('CAL0403');

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
    vTributacao          PKGPAG_TRIBUTACAO.rTributacao;

    vContador      INTEGER;
    vContadorGeral INTEGER;
    vContadorVinc  INTEGER;

    vNuVinculosVigentes INTEGER DEFAULT 0;

    vTmIni INTEGER;
    vTmTot INTEGER;
    
    vMsgCalculo     VARCHAR2(100);

    CURSOR cVinc IS
      SELECT CdFolhaPagamento,
             MAX(CdOrgaoExercicio) as CdOrgaoFolha,
             max(CdOrgaoVinculo) as CdOrgao,
             max(CdPessoa) as CdPessoa,
             max(NuSeqMatricula) as NuSeqMatricula,
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
             max(FlOutroVincACalcular) as FlOutroVincACalcular,
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
                FlContribIndiv, -- Primeiro Empregado, depois Contrib. Individual (Manual MOS - eSocial)
                Nuseqmatricula;

  BEGIN

--begin
    PKGPAG_VAR.vgCalculo := pCalculo;

    PKGPAG_VAR.vCdPessoa := NULL;

    PKGPAG_GERAL.PLogProcIni('CAL','PACKAGE CAL');

    -- seta Timer de inicio do calculo da folha ( diferenca de valores / 100 = segundos de duracao)

    vTmIni := DBMS_UTILITY.get_time;

    -- Inicializa dados Ant

    vCdFolhaPagamentoAnt := 0;
    vCdOrgaoAnt          := 0;
    vCdPessoaAnt         := 0;

    vContadorGeral       := 0;
    vContadorVinc        := 0;

    /* insert into Epagrelatorio(Cdtpgeracao, deRel) values (2121, vsql);
    commit;*/


    vMsgCalculo := NULL;
    pCalculoRetorno.DeParametros := NULL;
    pCalculoRetorno.CdMensagem   := 0;    

    PKGPAG_VAR.vCdHistParamCalc := pCalculo.CdHistoricoParamCalculo;
    PKGPAG_VAR.bTrace           := pTrace;
    PKGPAG_VAR.bLog             := pLog;

    FOR rVinc IN cVinc

     LOOP

      PKGPAG_GERAL.PLogProcIni('CAL01','Teste Quebra Folha');

      vContadorVinc := vContadorVinc + 1;

      -- Testa quebra de orgao. Apos finalizar um orgao, realiza as atualizacoes necessarias

      IF rVinc.CdFolhaPagamento <> vCdFolhaPagamentoAnt OR
         rVinc.CdOrgaoFolha <> vCdOrgaoAnt THEN

        PKGPAG_GERAL.PLogProcIni('CAL0101','Atualiza Parm Execucao');

        -- Processar dados do orgao anterior

        IF vCdOrgaoAnt <> 0 THEN
          PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo             => pCalculo,
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

        IF PKGPAG_TAR.FInterromperProcessamento(pCalculo) THEN

          PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo  => pCalculo,
                                                pCdOrgao  => vCdOrgaoAnt,
                                                pInStatus => 3);

          RAISE PKGPAG_VAR.eInterrupCalc;

        END IF;

        PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo  => pCalculo,
                                              pCdOrgao  => rVinc.CdOrgaoFolha,
                                              pInStatus => 1);

        PKGPAG_GERAL.PLogProc('CAL0101','CAL0102','Armazena Info Proc');

        PKGPAG_PARAM.PArmazenaInfoProc(rVinc.CdFolhaPagamento, pDtCalculo, rVinc.cdOrgao);

        vgTabCdFolhaPagamentoDifMes := FOBtemFolhaDifMes(pFolha => PKGPAG_VAR.vgFolha);

        PKGPAG_GERAL.PLogProcFim('CAL0102');

        if rVinc.cdfolhapagamento != vCdFolhaPagamentoAnt then
          PKGPAG_GERAL.PLogProcIni('CAL0103','Ins parc faltantes RET/ERA');
          PInsPagamentoLancFaltantes(rvinc.cdvinculo, pCalculo,  NVL(pFlDefinitivo, 'N'));--, pDtInicioMes);
          PKGPAG_GERAL.PLogProcFim('CAL0103');
        end if;        
    
        PKGPAG_TRIBUTACAO.PInicializarControle (pTributacao => vTributacao,
                                                pFolha      => PKGPAG_VAR.vgFolha);
           
        vCdFolhaPagamentoAnt := rVinc.CdFolhaPagamento;
        vCdOrgaoAnt          := rVinc.CdOrgaoFolha;
        vCdPessoaAnt         := 0; -- Forca quebra de pessoa
      END IF;

      PKGPAG_GERAL.PLogProc('CAL01','CAL04','Calculo Pessoas');

      -- Testa se Atualiza estatisticas

      vTmTot := DBMS_UTILITY.get_time - vTmIni;
      if vTmTot >= 3000 THEN
        -- 30 segundos ou 3000 ms

        ------------------------------------------------------------------------------------------------
        -- Atualiza a quantidade de pessoas calculadas do registro de parametros (no orgao e no geral)
        ------------------------------------------------------------------------------------------------

        PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo             => pCalculo,
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

        PKGPAG_GERAL.PLogProcIni('CAL0401','Ver Vigentes');

        vNuVinculosVigentes := PKGPAG_GERAL.FVinculosVigentes(vCdPessoaAnt,
                                                              trunc(pDtCalculo,
                                                                    'MM'));

        PKGPAG_GERAL.PLogProcFim('CAL0401');

        IF (MOD(vContadorGeral, 100) = 0 OR vNuVinculosVigentes > 1) AND
           pCalculo.FlGeral <> 'I' THEN

          COMMIT;

          IF PKGPAG_TAR.FInterromperProcessamento(pCalculo) THEN

            PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo  => pCalculo,
                                                  pCdOrgao  => vCdOrgaoAnt,
                                                  pInStatus => 3);

            RAISE PKGPAG_VAR.eInterrupCalc;

          END IF;

        END IF;

        vCdPessoaAnt := rVinc.CdPessoa;
        
        -- Quebrou pessoa, precisa excluir os contracheques que serão calculados/recalculados


        -- Caso Nao seja um calculo geral, exclui os registros de pagamento da folha
 
        IF pCalculo.FlGeral IN ('I', 'N') THEN
 
           IF PKGPAG_VAR.vgFolhaOrigem.CdTipoCalculo IN (7, 8, 9) THEN
 
              PKGPAG_GERAL.PExcluirPagPessoa(PKGPAG_VAR.vgFolhaOrigem.CdFolhaPagamento,
                                             rVinc.CdPessoa);
 
           END IF;
 
           PKGPAG_GERAL.PExcluirPagPessoa(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                          rVinc.CdPessoa);
  
        END IF;

      END IF;

      BEGIN

        PProcessarVinculoNormal(pCalculo             => pCalculo,
                                pRegVinc             => rVinc,
                                pDtCalculo           => pDtCalculo,
                                pVlDiferencaValor    => pVlDiferencaValor,
                                pFlCalculoDefinitivo => pFlDefinitivo,
                                pFlPagaAdiantamento  => pFlPagaAdiantamento13sal,
                                pTributacao          => vTributacao);


        -- Tratamento de Exceptions que devem continuar o processamento
      EXCEPTION

        WHEN PKGPAG_VAR.eNaoRodaFolhaNormal THEN

          RAISE PKGPAG_VAR.eNaoRodaFolhaNormal;

        WHEN PKGPAG_VAR.eRubTetoInexistente THEN

          RAISE PKGPAG_VAR.eRubTetoInexistente;

        WHEN PKGPAG_VAR.eFolhaEmExecucao THEN

          RAISE PKGPAG_VAR.eFolhaEmExecucao;

        WHEN PKGPAG_VAR.eDependenciaFormula THEN

          RAISE PKGPAG_VAR.eDependenciaFormula;

        WHEN PKGPAG_VAR.eChaveDuplicada THEN

          RAISE PKGPAG_VAR.eChaveDuplicada;

        WHEN PKGPAG_VAR.eSemBaseIRRF THEN

          RAISE PKGPAG_VAR.eSemBaseIRRF;

        WHEN PKGPAG_VAR.eSemBaseIRRFFerias THEN

          RAISE PKGPAG_VAR.eSemBaseIRRFFerias;

        WHEN PKGPAG_VAR.eSemBaseIRRF13 THEN

          RAISE PKGPAG_VAR.eSemBaseIRRF13;

        WHEN OTHERS THEN

          pCalculoRetorno.CdMensagem := 1;

          pCalculoRetorno.DeParametros := '';

          PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  pCalculo.CdHistoricoParamCalculo,
                                  rVinc.CdPessoa,
                                  '** Alerta: PProcessarCalculoNormal: ' ||
                                  DBMS_UTILITY.format_error_stack  || '--' || DBMS_UTILITY.format_error_backtrace,                         
                                  rVinc.CdVinculo);
          -- RAISE; -- Faz com que o erro suba para procedimento chamador e interrompe processamento

        IF PKGPAG_VAR.vgFolha.cdtipofolha in (pkgpag_tipo.cnTpFolhaServAfast) THEN
          UPDATE eafaafastamentovinculo Afa
             SET Afa.Flanulado = PKGPAG_TIPO.cnN
           WHERE Afa.Cdafastamento in (select a.cdafastamento
                                         from epaghistfolhaservafast a
                                        where a.cdfolhapagamento = pkgpag_var.vgFolha.cdFolhaPagamento
                                          and a.cdvinculo = rVinc.CdVinculo);
          delete epaghistfolhaservafast a
           where a.cdfolhapagamento = pkgpag_var.vgFolha.cdFolhaPagamento
             and a.cdvinculo = rVinc.CdVinculo;
        END IF;

      END;

      IF pCalculo.FlGeral = 'I' THEN

         IF vMSgCalculo IS not NULL THEN
            vMSgCalculo := vMSgCalculo || ', ';
         END IF;
         
         vMSgCalculo := vMSgCalculo || FFormatarMatricula (pCdVinculo => rVinc.CdVinculo);
          
      END IF;
        
      PKGPAG_GERAL.PLogProcFim('CAL04');

    END LOOP;
                                          
    IF pCalculo.FlGeral = 'I' AND pCalculoRetorno.CdMensagem = 0 THEN

       pCalculoRetorno.CdMensagem   := 4050;
       pCalculoRetorno.DeParametros := 'Novo Cálculo Processado com sucesso';
                  
       IF vContadorVinc > 1 THEN -- Multiplos Vinculos        
          pCalculoRetorno.DeParametros := pCalculoRetorno.DeParametros 
                                          || ' para as matrículas ' || vMsgCalculo;
       end IF;
       
    END IF;
    
    -- Processa quebras

    IF vCdOrgaoAnt <> 0 THEN

      PKGPAG_TAR.PAtualizaParametroExecucao(pCalculo             => pCalculo,
                                            pCdOrgao             => vCdOrgaoAnt,
                                            pQtPessoasCalculadas => vContador);
      vContador := 0;

    END IF;

    PKGPAG_GERAL.PLogProcFim('CAL');

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

    WHEN PKGPAG_VAR.eNaoRodaFolhaNormal THEN

      pCalculoRetorno.CdMensagem := 2471;

      pCalculoRetorno.DeParametros := '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Nao e permitido executar folha normal/calculo normal para orgao nao implantado.',
                              PKGPAG_VAR.vgCdVinculo);

    WHEN PKGPAG_VAR.eRubTetoInexistente THEN

      pCalculoRetorno.CdMensagem := 2561;

      pCalculoRetorno.DeParametros := '';

    WHEN PKGPAG_VAR.eFolhaEmExecucao THEN

      pCalculoRetorno.CdMensagem := 2649;

      pCalculoRetorno.DeParametros := '';

    WHEN PKGPAG_VAR.eDependenciaFormula THEN

      pCalculoRetorno.CdMensagem := 2164;

      pCalculoRetorno.DeParametros := '';

    WHEN PKGPAG_VAR.eChaveDuplicada THEN

      pCalculoRetorno.CdMensagem := 2164;

      pCalculoRetorno.DeParametros := '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Chave duplicada ao executar folha suplementar.',
                              PKGPAG_VAR.vgCdVinculo);

    WHEN PKGPAG_VAR.eSemBaseIRRF THEN

      pCalculoRetorno.CdMensagem := 2430;

      pCalculoRetorno.DeParametros := '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Nao foi encontrada a rubrica referente a base do IRRF. Folha nao calculada.',
                              PKGPAG_VAR.vgCdVinculo);

    WHEN PKGPAG_VAR.eSemBaseIRRFFerias THEN

      pCalculoRetorno.CdMensagem := 2431;

      pCalculoRetorno.DeParametros := '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Nao foi encontrada a rubrica referente a base do IRRF de ferias. Folha nao calculada.',
                              PKGPAG_VAR.vgCdVinculo);

    WHEN PKGPAG_VAR.eSemBaseIRRF13 THEN

      pCalculoRetorno.CdMensagem := 2432;

      pCalculoRetorno.DeParametros := '';

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              pCalculo.CdHistoricoParamCalculo,
                              PKGPAG_VAR.vCdPessoa,
                              'Nao foi encontrada a rubrica referente a base do IRRF de 13o. Folha nao calculada.',
                              PKGPAG_VAR.vgCdVinculo);

     WHEN OTHERS THEN

        pCalculoRetorno.CdMensagem := 1;

        pCalculoRetorno.DeParametros := '';

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                pCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vCdPessoa,
                                DBMS_UTILITY.format_error_stack  || '--' || DBMS_UTILITY.format_error_backtrace,                         
                                PKGPAG_VAR.vgCdVinculo);


        IF PKGPAG_VAR.vgFolha.cdtipofolha in (pkgpag_tipo.cnTpFolhaServAfast) THEN
          UPDATE eafaafastamentovinculo Afa
             SET Afa.Flanulado = PKGPAG_TIPO.cnN
           WHERE Afa.Cdafastamento in (select a.cdafastamento
                                         from epaghistfolhaservafast a
                                        where a.cdfolhapagamento = pkgpag_var.vgFolha.cdFolhaPagamento
                                          and a.cdvinculo = PKGPAG_VAR.vgCdVinculo);
          delete epaghistfolhaservafast a
           where a.cdfolhapagamento = pkgpag_var.vgFolha.cdFolhaPagamento
             and a.cdvinculo = PKGPAG_VAR.vgCdVinculo;
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

    PKGPAG_GERAL.PIniciarLogProc;

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

        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                vCalculo.CdHistoricoParamCalculo,
                                PKGPAG_VAR.vCdPessoa,
                                '** Erro (PProcessarCalculoNormal-Paralelo): ' ||
                                SQLERRM,
                                PKGPAG_VAR.vgCdVinculo);

    END;

    PKGPAG_TAR.PFinalizarJob(pCdJobId, vCalculoRetorno.DeParametros);

    PKGPAG_GERAL.PFinalizarLogProc(pCalculo => vCalculo);

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
   VFOLHA           PKGPAG_TIPO.RFOLHA;
   VNUMESREFERENCIA CHAR(2);
   VNURUBRICA       VARCHAR2(7);
   VNUPARCELA       INTEGER;

 BEGIN
 
   VDTFIMMESANT           := PKGPAG_VAR.VGFOLHA.DTINICIOMES - 1;
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

       PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => LANC.CDLANCAMENTOFINANCEIRO,
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
             PKGPAG_PC.PATUALIZASITUACAORETRO(LANC.CDVINCULO, VFOLHA);
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
             PKGPAG_PC.PATUALIZASITUACAOERARIO(LANC.CDVINCULO, VFOLHA);
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

         PKGPAG_GERAL.PINSERELOG(PKGPAG_VAR.BLOG,
                                 PKGPAG_VAR.VCDHISTPARAMCALC,
                                 LANC.CDPESSOA,
                                 VMSG,
                                 LANC.CDVINCULO,
                                 24); --Lançamento financeiro - parcela não computada

       END IF;

     ELSIF LANC.INPERIODICIDADE = PKGPAG_TIPO.CNQ AND
           (LANC.NUPARCELAS IS NOT NULL OR LANC.NUPARCELAS > 0) THEN

       SELECT R.NURUBRICAFMT
         INTO VNURUBRICA
         FROM VPAGRUBRICAAGRUPAMENTO R
        WHERE R.CDRUBRICAAGRUPAMENTO = LANC.CDRUBRICAAGRUPAMENTO;

       PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => LANC.CDLANCAMENTOFINANCEIRO,
                                           pNuAnoReferencia => PKGPAG_VAR.VGFOLHA.NUANOREFERENCIA,
                                           pNuMesreferencia => PKGPAG_VAR.VGFOLHA.NUMESREFERENCIA,
                                           pNuParcela => LANC.QTPARCELAS,
                                           pValorParcela => LANC.VLPAGAMENTO,
                                           pDataUltimaAlteracao => SYSTIMESTAMP);

       VMSG := 'O respectivo lançamento financeiro foi registrado. Rubrica:' ||
               VNURUBRICA || ', parcela ' || LANC.QTPARCELAS ||
               ' - valor R$ ' || LANC.VLPAGAMENTO;

       PKGPAG_GERAL.PINSERELOG(PINSERE                  => PKGPAG_VAR.BLOG,
                               PCDHISTORICOPARAMCALCULO => PKGPAG_VAR.VCDHISTPARAMCALC,
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

        PKGPAG_GERAL.PINSERELOG(PINSERE                  => PKGPAG_VAR.BLOG,
                               PCDHISTORICOPARAMCALCULO => PKGPAG_VAR.VCDHISTPARAMCALC,
                               PCDPESSOA                => LANC.CDPESSOA,
                               PDELOG                   => VMSG,
                               PCDVINCULO               => LANC.CDVINCULO,
                               PCDTIPOOCORRENCIA        => 2, -- Ocorrencia
                               PCDMOTIVOOCORRENCIA      => 24); --Lançamento financeiro - parcela não computada
     END IF;

   END LOOP;

 EXCEPTION

   WHEN OTHERS THEN
     PKGPAG_GERAL.PINSERELOG(PKGPAG_VAR.BLOG,
                             NULL,
                             PCDVINCULO,
                             '** Erro (pkgpag_cal.PINSPAGAMENTOLANCFALTANTES): ' ||
                             SQLERRM);

 END PINSPAGAMENTOLANCFALTANTES;

PROCEDURE PZerarValorPgtoCopPlanoSaude(pCdVinculo       IN INTEGER,
                                       pNuAnoReferencia IN INTEGER,
                                       pNuMesReferencia IN INTEGER) IS
BEGIN
 
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
 
   if FPossuiVinculoCCOProvDestino(pCdVinculo, pCdOrgao, pDataCalculo, pDataFimMes)
     and pCdAgrupamento <> 134 -- Excecao PM e Bombeiros
     and pkgpag_var.vgFolha.CdTipoFolhaPagamento NOT IN (1505,1525,1526,1766) -- Folhas PRODEX excecao
     then

       if pkgpag_var.vgfolha.cdorgao <> PKGPAG_GERAL.FObterOrgaoExercicioCCO(pcdvinculo => pCdVinculo,
                                                                             pdatareferencia => pDataCalculo) then
         pkgpag_geral.pexcluirpagvinc (pCdFolhaPagamento, pCdVinculo);
       end if;

   end if;
 END;

END PKGPAG_CAL;
/
