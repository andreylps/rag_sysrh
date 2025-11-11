create or replace package PKGPAG_RETROATIVO is

TYPE rBlocos IS RECORD
    (CdFormulaCalculoBloco            EPAGFORMULACALCULOBLOCO.Cdformulacalculobloco%TYPE,
     CdExpressaoFormCalcNuNivel       EPAGFORMULACALCULOBLOCO.Cdexpressaoformcalc%TYPE,
     SgBloco                          EPAGFORMULACALCULOBLOCO.SgBloco%TYPE,
     CdTipoMnemonico                  EPAGFORMULACALCBLOCOEXPRESSAO.Cdtipomneumonico%TYPE,
     SgTipoMnemonico                  EPAGTIPOMNEUMONICO.SGTIPOMNEUMONICO%TYPE);

TYPE tBlocos IS TABLE OF rBlocos INDEX BY PLS_INTEGER;

vDeFormExp string(60);

vDtFimSubst date;

vCdFormulaCalculo number;

vFlIndiceHora char(1);

vCdVersao number;

vCdHistForm number;

vCdExpForm number;

vVlRub1056 number(13,2);

vVlRub1156 number(13,2);

vAnoMesFerias char(6);

vCdFolhaFerias number;

PROCEDURE PLISTARETROATIVO (pCdOrgao number, pCdVinculo number, pImplantado char,
                            pCdPagRetroativo number, pMaiorQue number, cResultado OUT TYPES.ref_cursor);

PROCEDURE PLISTARETROATIVOSINT (pCdOrgao number, pCdVinculo number, cResultado OUT TYPES.ref_cursor);

PROCEDURE PLISTARETROATIVOSINTORGAO (cResultado OUT TYPES.ref_cursor);

PROCEDURE PLISTAVINCORGAOS (cResultado OUT TYPES.ref_cursor);

PROCEDURE PGERAARQUIVORETROATIVO (pCdOrgao number, pCdVinculo number,
                                  pProcesso CHAR, pDescricao CHAR,
                                  pData DATE,
                                  pMesAnoIni CHAR,
                                  pMesAnoFim CHAR,
                                  pCdProcesso NUMBER,
                                  pCdPagRetroativo NUMBER,
                                  pMaiorQue number,
                                  cResultado OUT TYPES.ref_cursor);

--PROCEDURE PINCLUIRUBRICAFATOGERADOR (pTipoRetroativo number, pCdRubrica number,pCdPagRetroativo NUMBER);

PROCEDURE PINCLUI1001 (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER);

PROCEDURE PVALOROUTRARUBRICA (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                              pCdRubrica NUMBER);

PROCEDURE PCALCULARUBINDICE (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                             pCdRubrica NUMBER);

PROCEDURE PCALCULARUB13 (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                         pCdRubrica NUMBER);

PROCEDURE PCALCULAFERIAS(pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                         pCdRubrica NUMBER);

PROCEDURE PCALCULO1001 (pAnoMesIni char, pAnoMesFim char, pCdVinculo NUMBER, pAgrupamento number);

procedure PACERTASALORIGEM;

PROCEDURE PINSERERETROATIVORUBVINCULO;

PROCEDURE PLISTAEXCEDEULIMITE ;

PROCEDURE PULTIMAFOLHAVINCULO (pCdPagRetroativo NUMBER);

PROCEDURE PRECALCULADECIMO (pAnoMes CHAR , pCdProcesso NUMBER);

PROCEDURE PACERTAPROGRESSAO (pNuRubrica number);

PROCEDURE PCALCULARUBRICAPROCESSO (pCdRubrica NUMBER, pCdPagRetroativo NUMBER, pCdVinculo NUMBER);

PROCEDURE PCALCULOPROGRESSAORETROATIVO (pDtIni DATE, pCdVinculo NUMBER, pNuRubrica number,
                                        pTipoRubrica number, pAgrupamento number, pCdPagRetroativo number);

PROCEDURE PINCLUIRETROATIVO (pCdOrgao number, pCdVinculo number, pCdFolhaPagamento number,
                             pCdRubricaAgrupamento number, pAnoMes char,
                             pVlPagamento number, pVlProgressao number, pCdProcesso number DEFAULT NULL,
                             pCdPagRetroativo number DEFAULT NULL,
                             pVlRetroativo number DEFAULT 0);

PROCEDURE PRECALCULARUBRICAS (pTipoRubrica number, pAgrupamento number, pNuRubFatoGerador number,
                              pNuRubCalculada number, pCdVinculo number,
                              pAnoMesIni char, pAnoMesFim char, pCdProcesso number);

PROCEDURE PINCLUIRUBRICAPROCESSO (pCdRubrica NUMBER, pAnoMesFim CHAR, pcdvinculo NUMBER);

PROCEDURE PRECALCULA13 (pTipoRubrica number, pAgrupamento number,
                        pNuRubCalculada number, pCdVinculo NUMBER, pAnoMesIni char, pAnoMesFim char);
/*PROCEDURE PPROCURAFORMULAS (pNuRubrica number, pTipoRubrica number, pAgrupamento number);*/
FUNCTION FRETORNAVALORSALARIO(vNuNivel number, vNuReferencia string, vNuAno number, vNuMes number,
                              vCdEstruturaCarreira number, vCdAgrupamento number, vNuVersao number)
                              RETURN NUMBER;

FUNCTION FRECALCULABASES (pBase char, pAgrupamento number, pAnoMes char,
                          pCdVinculo number, pCdFolha number, pCdOrgao number, pNuRubCalculada number) return number;

FUNCTION FBASEINC(pCdVinculo number, pAnoMes char, pCdRubrica number, pCdOrgao number) return number;

FUNCTION FOUTROVALORPAGORETROATIVO(pCdVinculo number,
                                   pCdFolha number,
                                   pCdRubrica number, pCdPagRetroativo number) RETURN NUMBER;

FUNCTION FPossuiVinculoCCO(pCdVinculo INTEGER, pCdOrgao INTEGER, pAnoMes CHAR) RETURN INTEGER;

procedure preprocessarubricasret (pnurubrica number);

PROCEDURE PRECALCULABASEFERIAS (pBase char, pAgrupamento number);

-- Processo SED 5770/18 ref.DJ recalculo de IR sob 04-0519 da GREVE de 2015 do MAG
FUNCTION FIRRFRRASED577018(pBaseCalculoIRRF number,
                           pNM integer) RETURN NUMBER;

FUNCTION FNuMesesRRASED577018(pCdVinculo IN INTEGER) RETURN INTEGER;

FUNCTION FIRRFSED577018(pBaseCalculoIRRF number) RETURN NUMBER;

FUNCTION FIRRFOutrosSED577018(pCdVinculo INTEGER) RETURN NUMBER;

FUNCTION FBaseIRRFOutrosSED577018(pCdVinculo INTEGER) RETURN NUMBER;

FUNCTION FBaseIRRFSED577018(pBaseCalculoIRRF number,
                            pAbatPorDepIRRF number DEFAULT 0,
                            pAabatIRRFMaior65 number DEFAULT 0) RETURN NUMBER;

PROCEDURE ProcessoSED577018(cResultado OUT TYPES.ref_cursor);

PROCEDURE PGeraLFProcessoSED577018;

end PKGPAG_RETROATIVO;
/
create or replace package body PKGPAG_RETROATIVO is

-- Somar ano da rubrica
FUNCTION FSomarAno(pCdVinculo            IN INTEGER,
                   pNuAnoReferencia      IN INTEGER,
                   pNuMesReferencia      IN INTEGER,
                   pCdAgrupamento        IN INTEGER,
                   pCdRubricaAgrupamento IN INTEGER,
                   pCdTipoRubrica        IN CHAR,
                   pNuRubrica            IN INTEGER)

   RETURN NUMBER IS

   vNuMesInicio  INTEGER;
   vSQL          VARCHAR2(2000);
   vVlPagamento NUMBER(13,2);
   vDtAdmissao DATE;

BEGIN

     SELECT EV.DtAdmissao
       INTO vDtAdmissao
       from ECADVINCULO EV
      WHERE EV.CDVINCULO = PCDVINCULO;

     IF pNuMesReferencia > 1 THEN

       IF TO_CHAR(vDtAdmissao,'YYYY') < to_char(pNuAnoReferencia) THEN

         vNuMesInicio := 1;

       ELSIF pNuMesReferencia > 1 THEN

         vNuMesInicio := to_number(TO_CHAR(vDtAdmissao,'MM'));

       else
         null;
       END IF;

       vSQL := 'SELECT SUM(vlPagamento) '||
               'FROM ePagHistoricoRubricaVinculo HRV '||
               'INNER JOIN EPagFolhaPagamento FP '||
               'ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento '||
               'INNER JOIN EPagTipoFolhaPagamento TFP '||
               'ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento '||
               'WHERE HRV.CdVinculo = :pCdVinculo AND '||
               'FP.NuAnoReferencia = :pNuAnoReferencia AND '||
               '((FP.NuMesReferencia BETWEEN :pNuMesInicio AND :pNuMesFim AND '||
               'FP.FlCalculoDefinitivo = ''S'') ) AND ' ||
               'HRV.CdRubricaAgrupamento IN (SELECT CdRubricaAgrupamento '||
               'FROM EPagRubricaAgrupamento RA '||
               'INNER JOIN EPagRubrica R '||
               'ON RA.CdRubrica = R.CdRubrica ';

       IF pCdTipoRubrica = 1 THEN

         vSQL := vSQL || ' WHERE R.CdTipoRubrica IN (1,2,3) AND ';

       ELSIF pCdTipoRubrica = 5 THEN

         vSQL := vSQL || ' WHERE R.CdTipoRubrica IN (5,6,7) AND ';

       ELSIF pCdTipoRubrica = 8 THEN

         vSQL := vSQL || ' WHERE R.CdTipoRubrica IN (8) AND ';

       ELSE

         vSQL := vSQL || ' WHERE 1=2 AND ';

       END IF;

       vSQL := vSQL || ' R.NuRubrica = :pNuRubrica AND RA.CdAgrupamento = :pCdAgrupamento)';

       EXECUTE IMMEDIATE vSQL
          INTO vVlPagamento
         USING pCdVinculo,
               pNuAnoReferencia,
               vNuMesInicio,
               pNuMesReferencia,
               pNuRubrica,
               pCdAgrupamento;

      RETURN NVL(vVlPagamento,0.0);

  ELSE

    RETURN 0;

  END IF;

EXCEPTION

  WHEN OTHERS THEN

    --DBMS_OUTPUT.PUT_LINE('Somano' || SQLERRM);

    --DBMS_OUTPUT.PUT_LINE(vSQL);

    RETURN 0;

END;

----------------------------------------------------------------
-- pTpRetorno       pTpIndice
-- 1 - Valor        1 - Valor
-- 2 - Indice       2 - Hora/Minuto
----------------------------------------------------------------

FUNCTION FMneMediaTempo(pCdVinculo            IN INTEGER,
                        pNuAnoReferencia      IN INTEGER,
                        pNuMesReferencia      IN INTEGER,
                        pCdTipoRubrica        IN INTEGER,
                        pCdAgrupamento        IN INTEGER,
                        pCdRubricaAgrupamento IN INTEGER,
                        pNuMesesRetroativos   IN INTEGER,
                        pNuRubrica            IN INTEGER,
                        pTpRetorno            IN INTEGER DEFAULT 1,
                        pTpIndice             IN INTEGER DEFAULT 1)

   RETURN NUMBER IS

   vVlPagamento      NUMBER(13,2);
   vVlIndice         NUMBER(13,4);
   --vNuRubrica        INTEGER;
   v1                INTEGER;
   v2                INTEGER;
   vNuAnoMesInicio   INTEGER;
   vNuAnoMesFim      INTEGER;

BEGIN

  IF pCdTipoRubrica = 1 THEN

    -- Caso o tipo de retorno seja por valor (1), soma os iniciais 1 e 2
    IF pTpRetorno = 1 THEN

       v1:= 1; v2:= 2;

    ELSE

     -- Caso o tipo de retorno seja por ?ndice (2), soma apenas o inicial 1

      v1:= 1; v2:= 1;

    END IF;

  ELSIF pCdTipoRubrica = 5 THEN

    -- Caso o tipo de retorno seja por valor (1), soma os iniciais 5 e 6
    IF pTpRetorno = 1 THEN

      v1:= 5; v2:= 6;

    ELSE

     -- Caso o tipo de retorno seja por ?ndice (2), soma apenas o inicial 5

      v1:= 5; v2:= 5;

    END IF;

  ELSIF pCdTipoRubrica = 9 THEN

     v1:= 9;  v2:= 9;

  else
    null;
  END IF;

  ----------------------------------------------------------------------------
  -- Alimenta as vari?veis vNuAnoMesInicio e vNuAnoMesFim
  -- vNuAnoMesFim recebe o ano/mes anterior ao mes de processamento
  -----------------------------------------------------------------------------

  IF pNuMesesRetroativos > 1 THEN

    vNuAnoMesInicio := to_number(TO_CHAR(ADD_MONTHS(TO_DATE(pNuAnoReferencia * 100 + pNuMesReferencia, 'YYYYMM'), -(pNuMesesRetroativos-1)), 'YYYYMM'));

    vNuAnoMesFim := to_number(TO_CHAR(ADD_MONTHS(TO_DATE(pNuAnoReferencia * 100 + pNuMesReferencia,'YYYYMM'), -1), 'YYYYMM'));

  ELSE

    vNuAnoMesInicio := to_number(to_char(pNuAnoReferencia * 100 + pNuMesReferencia, 'YYYYMM'));

    vNuAnoMesFim := to_number(TO_CHAR(pNuAnoReferencia * 100 + pNuMesReferencia, 'YYYYMM'));

  END IF;

  --------------------------------------------------------------------------------------
  -- A leitura est? sendo feita no vinculo pois n?o exitem
  -- registros de rela??o de v?nculo em org?os implantados durante o ano 2011 (vide SSP)
  -- Pela mesma raz?o a leitura ? feita apenas na rela??o de v?nculo principal quando o tipo
  -- de retorno ? valor. Quando o valor for retorno ?ndice l? para todas
  --------------------------------------------------------------------------------------

      SELECT SUM(HRV.VlPagamento) AS VlPagamento,
             SUM(
             CASE pTpIndice
               WHEN 1 THEN
                 HRV.VlIndiceRubrica
             ELSE
               CASE
                  WHEN O.NuAnoMesImplantacao <= FP.NuAnoMesReferencia THEN
                   TO_NUMBER(TRUNC((HRV.VlIndiceRubrica/POWER(10,LENGTH(LPAD(HRV.VlIndiceRubrica,4,'0'))-2)))||'.'||
                             LPAD(TRUNC((HRV.VlIndiceRubrica-TRUNC(HRV.VlIndiceRubrica,-2))/60*100),2,'0'))
               ELSE
                    TO_NUMBER(TRUNC((HRV.VlIndiceRubrica*100/POWER(10,LENGTH(LPAD(HRV.VlIndiceRubrica*100,4,'0'))-2)))||'.'||
                             LPAD(TRUNC((HRV.VlIndiceRubrica*100-TRUNC(HRV.VlIndiceRubrica*100,-2))/60*100),2,'0'))
               END
             END) AS VlIndice
        INTO vVlPagamento,
             vVlIndice
        FROM EPagHistoricoRubricaVinculo HRV
       INNER JOIN EPagFolhaPagamento FP
          ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
       INNER JOIN EPagTipoFolhaPagamento TFP
          ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento
       INNER JOIN EPagRubricaAgrupamento RA
          ON RA.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
      INNER JOIN ECadOrgao O
              ON O.CdOrgao = FP.CdOrgao
       WHERE HRV.CdVinculo = pCdVinculo AND
             FP.CdTipoCalculo IN (1, 5) AND
             ((FP.FlCalculoDefinitivo = 'S' AND
             FP.NuAnoMesReferencia BETWEEN vNuAnoMesInicio AND vNuAnoMesFim) OR
             (FP.NuAnoReferencia = pNuAnoReferencia AND
             FP.NuMesReferencia = pNuMesReferencia AND TFP.CdTipoFolha = 1)) AND
             HRV.CdRubricaAgrupamento  IN (SELECT CdRubricaAgrupamento
                                             FROM EPagRubricaAgrupamento RA
                                            INNER JOIN EPagRubrica R
                                               ON RA.CdRubrica = R.CdRubrica
                                            WHERE R.NuRubrica = pNuRubrica AND
                                            R.CdTipoRubrica IN (v1, v2) AND
                                            RA.CdAgrupamento = pCdAgrupamento);

   IF pTpRetorno = 1 THEN

     RETURN NVL(vVlPagamento,0.0)/pNuMesesRetroativos;

   ELSE

       RETURN NVL(vVlIndice,0.0)/pNuMesesRetroativos;

   END IF;

EXCEPTION

  WHEN OTHERS THEN

    RETURN 0;

END;

FUNCTION FPROCURAFORMULAS (pNuRubrica number, pAnoMes CHAR)

  return string is

vAno NUMBER := SUBSTR(pAnoMes,1,4);
--vMes NUMBER := SUBSTR(pAnoMes,5,2);

BEGIN

     SELECT PAG115.DEFORMULAEXPRESSAO, PAGA88.CDFORMULACALCULO, PAG115.FLVALORHORAMINUTO
       INTO vDeFormExp, vCdFormulaCalculo, vFlIndiceHora
       FROM EPAGFORMULACALCULO PAGA88
      INNER JOIN VPAGRUBRICAAGRUPAMENTO VP ON (VP.cdrubricaagrupamento = PAGA88.CDRUBRICAAGRUPAMENTO)
      INNER JOIN EPAGFORMULAVERSAO PAG112
              ON (PAG112.CDFORMULACALCULO = PAGA88.CDFORMULACALCULO)
      INNER JOIN EPAGHISTFORMULACALCULO PAG116
              ON (PAG116.CDFORMULAVERSAO = PAG112.CDFORMULAVERSAO AND
               (PAG116.NUANOFIM IS NULL OR PAG116.NUANOFIM <= vAno))
      INNER JOIN EPAGEXPRESSAOFORMCALC PAG115
              ON (PAG115.CDHISTFORMULACALCULO = PAG116.CDHISTFORMULACALCULO)
      INNER JOIN EPAGRUBRICAAGRUPAMENTO ERUBA
              ON (ERUBA.CDRUBRICAAGRUPAMENTO = PAGA88.CDRUBRICAAGRUPAMENTO)
      INNER JOIN EPAGRUBRICA EPR ON (EPR.CDRUBRICA = ERUBA.CDRUBRICA AND EPR.CDTIPORUBRICA=1)
      WHERE vp.CDRUBRICAAGRUPAMENTO=pNuRubrica
      AND   FLEXPGERAL = 'S'
      AND   ROWNUM < 2;

      RETURN vDeFormExp;

END FPROCURAFORMULAS;

FUNCTION FPROCURAFORMULASBASES (pNuRubrica number)

  return string is

BEGIN

     SELECT DISTINCT hb2.deformula, BV2.CDBASECALCULO, BV2.CDVERSAOBASECALCULO, hb2.cdhistbasecalculo--,
              --       ex2.cdbasecalculoblocoexpressao
      INTO vDeFormExp, vCdFormulaCalculo, vCdVersao, vCdHistForm --, vCdExpForm
      FROM epagrubricaagrupamento RUBM2
     INNER JOIN epagbasecalculo base2 ON base2.cdbasecalculo = rubm2.cdbasecalculo
     INNER JOIN epagbasecalculoversao bv2 ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
     INNER JOIN ePagHistBaseCalculo hb2 ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
     WHERE RUBM2.CdRubricaAgrupamento = pNuRubrica;

     RETURN vDeFormExp;

END FPROCURAFORMULASBASES;

-- Verificar se possui comissionado no periodo

FUNCTION FPossuiVinculoCCO(pCdVinculo IN INTEGER,
                           pCdOrgao   IN INTEGER,
                           pAnoMes    IN CHAR)
  RETURN INTEGER IS

  vCont INTEGER;
  vDtInicio DATE; -- := '01' || SUBSTR(pAnoMes,5,2) || SUBSTR(pAnoMes,1,4);
  vDtFim DATE := LAST_DAY(vDtInicio);

BEGIN

  vDtInicio := to_date(pAnoMes ||'01', 'YYYYMMDD');

  SELECT 1
    INTO vCont
    FROM ECadHistCargoCom HCC
   WHERE HCC.CdVinculo = pCdVinculo AND
         HCC.CdOrgaoExercicio = pCdOrgao AND
         HCC.CdCargoComRemuneracao IS NULL AND
         (HCC.DtInicio <= vDtFim AND
         (HCC.DtFim >= vDtInicio OR HCC.DtFim IS NULL)) AND
         HCC.Flanulado = 'N' AND
         ROWNUM < 2;

  RETURN VCONT;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN 0;

END;

FUNCTION FCEFCHO (pCdVinculo IN INTEGER,
                  pAnoMes    IN CHAR)
    RETURN INTEGER IS

    vNuCho number :=0 ;

BEGIN

    SELECT HC.NuCargaHoraria
      INTO vNuCho
      FROM ECadHistCargoEfetivo HE
      INNER JOIN ECadLocalTrabalho LT
              ON LT.CdHistCargoEfetivo = HE.CdHistCargoEfetivo
      INNER JOIN ECadHIstCargaHoraria HC
              ON HC.CdHistCargoEfetivo = HE.CdHistCargoEfetivo
           WHERE HE.CdVinculo = pCdVinculo
             AND TO_CHAR(HC.DTINICIAL,'YYYYMM') <= to_char(pAnoMes)
             AND (TO_CHAR(HC.DTFIM,'YYYYMM') >= to_char(pAnoMes) OR HC.DTFIM is null)
             AND HE.FlAnulado = 'N'
             AND HC.FlAnulado = 'N';

    RETURN vNuCho;

    EXCEPTION
      WHEN OTHERS
        THEN
          vNuCho := 200;
          RETURN vNuCho;

END;
-- Retornar valor das gratifica??es de produtividade

FUNCTION FRetornaValorFixoGrat(pCdVinculo             IN INTEGER,
                               pCdEstruturaCarreira   IN INTEGER,
                               pNuNivelPagamento      IN CHAR,
                               pNuReferenciaPagamento IN CHAR,
                               pCdTipoAtipratFaz      IN INTEGER,
                               pAnoMes char,
                               pCdFolha IN INTEGER,
                               pNuRubrica IN INTEGER,
                               pCdOrgao IN INTEGER)

   RETURN NUMBER IS

   vAno              char(4) := SUBSTR(pAnoMes,1,4);
   vMes              char(2) := SUBSTR(pAnoMes,5,2);
   vCdValorGeralCEFAGrup        INTEGER;
   vCdHistValorGeralCEFAGrup    INTEGER;
   vCdRubricaAgrupamento        INTEGER;
   vVlFixoCEF                   NUMBER(13,2);
   vVlFixo                      NUMBER(13,2);
   vCdValorGeralCEFAgrupLimite  INTEGER;
   vFlAplicaPercentSobreRubrica CHAR(1);
--    vVlRubricaAgrupamento        NUMBER(13,2); -- Valor da rubrica
   vVlFixoCEFLimite             NUMBER(13,2);
   vVlPagamento                 NUMBER(13,2) :=0;
   vVlIndice                    NUMBER(5,2);
   --vCount                       number := 0;
   vNuValorCCO                  number(13,2);
   vDtInicio DATE; -- := '01' || SUBSTR(pAnoMes,5,2) || SUBSTR(pAnoMes,1,4);
   vDtFim DATE := LAST_DAY(vDtInicio);

BEGIN

   vDtInicio := to_date(pAnoMes ||'01', 'YYYYMMDD');

    -- Verificar se tem comissionado

    FOR F_CCO IN (SELECT HCC.NUREFERENCIA, HCC.NUNIVEL, ECC.CDCARGOCOMISSIONADO CDCARGOCOM,
                          ECC.CDGRUPOOCUPACIONAL
                     FROM ECadHistCargoCom HCC
                    INNER JOIN ECadCargoComissionado ECC ON ECC.CDCARGOCOMISSIONADO = HCC.CDCARGOCOMISSIONADO
                    WHERE HCC.CdVinculo = pCdVinculo
                      AND HCC.CdOrgaoExercicio = pCdOrgao
                      AND HCC.CdCargoComRemuneracao IS NULL
                      AND(HCC.DtInicio <= vDtFim
                      AND(HCC.DtFim >= vDtInicio OR HCC.DtFim IS NULL))
                      AND HCC.Flanulado = 'N'
                      AND ROWNUM < 2)
      LOOP

      /*CargaHorariaPadrao     ECadEvolucaoCCOCargaHoraria.NuCargaHoraria%TYPE,
    CdUnidadeOrganizacional  ECadLocalTrabalho.CdUnidadeOrganizacional%TYPE,
    CdMotivoMovimentacao     EMovMovimentacao.CdMotivoMovimentacao%TYPE,
    CdInstitutoMovimentacao  EMovMovimentacao.CdInstitutoMovimentacao%TYPE,
      */
       BEGIN

       SELECT NuValor, VlIndice
         INTO vNuValorCCO, vVlIndice
           FROM (SELECT NuValor, VlIndice
                   FROM (SELECT VV.NuValor, HAF.VlIndice,
                                CASE
                                  WHEN VV.DeNivel = F_CCO.NUReferencia AND
                                       VV.DeCodigo = F_CCO.NuNivel THEN  1
                                  WHEN VV.CdGrupoOcupacional = F_CCO.CdGrupoOcupacional AND
                                       VV.CdCargoComissionado = F_CCO.CdCargoCom THEN 2
                                  WHEN VV.CdGrupoOcupacional = F_CCO.CdGrupoOcupacional AND
                                       VV.CdCargoComissionado IS NULL THEN 3
                                END AS NIVEL
                           FROM EpagGratAtivFazendaria AF
                          INNER JOIN EpagHistGratAtivFazendaria HAF
                             ON AF.CdGratAtivFazendaria = HAF.CdGratAtivFazendaria
                          INNER JOIN EPagHistGratAtivfazendvalvenc VV
                             ON HAF.CdHistAtivFazendaria = VV.CdHistAtivFazendaria
                          WHERE AF.CdAgrupamento = 1
                            AND AF.CdTipoGratAtivFazendaria = pCdTipoAtipratFaz
                            AND (VV.CdCargoComissionado = F_CCO.CDCARGOCOM OR
                                (VV.CdGrupoOcupacional = F_CCO.CdGrupoOcupacional AND
                                 VV.CdCargoComissionado IS NULL)
                             OR (VV.DeNivel = F_CCO.NuReferencia AND VV.DeCodigo = F_CCO.NuNivel))
                             AND ((HAF.NuAnoInicioVigencia < vAno OR
                                  (HAF.NuAnoInicioVigencia = vAno AND
                                   HAF.NuMesInicioVigencia <= vMes))
                             AND (HAF.NuAnoFimVigencia > vAno OR
                                 (HAF.NuAnoFimVigencia = vAno AND
                                  HAF.NuMesFimVigencia >= vMes) OR
                                  HAF.NuMesFimVigencia IS NULL))) ORDER BY NIVEL)
                          WHERE ROWNUM < 2;

           EXCEPTION
             WHEN NO_DATA_FOUND
               THEN vNuValorCCO := 0 ;

           END;

      END LOOP;

      IF vNuValorCCO <> 0
        THEN
          vVlFixo := vNuValorCCO * vVlIndice / 100;
          RETURN vVlFixo;
      END IF;

      -- N?o achou comissionado no per?odo, segue verificando o valor da tabela.

      SELECT CdValorGeralCEFAGrup, VlIndice, CdRubricaAgrupamento, VlFixoCEF,
             CdValorGeralCEFAgrupLimite, FlAplicaPercentSobreRubrica
        INTO vCdValorGeralCEFAGrup,
             vVlIndice,
             vCdRubricaAgrupamento,
             vVlFixoCEF,
             vCdValorGeralCEFAgrupLimite,
             vFlAplicaPercentSobreRubrica
      FROM ( SELECT VS.CdValorGeralCEFAGrup,
                    HAF.VlIndice,
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
              WHERE AF.CdAgrupamento = 1 AND
                    AF.CdTipoGratAtivFazendaria = pCdTipoAtipratFaz AND
                    ((HAF.NuAnoInicioVigencia < vAno OR
                    (HAF.NuAnoInicioVigencia = vAno AND
                    HAF.NuMesInicioVigencia <= vMes))
                    AND
                    (HAF.NuAnoFimVigencia > vAno OR
                    (HAF.NuAnoFimVigencia = vAno AND
                    HAF.NuMesFimVigencia >= vMes) OR
                    HAF.NuMesFimVigencia IS NULL))
              ORDER BY Nivel)
      WHERE ROWNUM = 1;

    -- Procura por comissionado no per?odo, se encontrar retorna o valor

      --
      --
      --END IF;

      BEGIN
      -- Verifica se tem no contra-cheque a rubrica do parametro e paga valor fixo.
      -- As exce??es s?o tratadas posteriormente
      IF vCdRubricaAgrupamento is not null and pNuRubrica not in (483,484,560)
        THEN
          BEGIN

          SELECT EPH1.VLPAGAMENTO
            INTO vVlPagamento
            FROM EPAGHISTORICORUBRICAVINCULO EPH1
           WHERE EPH1.CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupamento
             AND EPH1.CDVINCULO = PCDVINCULO
             AND EPH1.CDFOLHAPAGAMENTO = PCDFOLHA;

          vVlFixo := vVlFixoCef * vVlIndice / 100;
          -- Se achou retorna o valor fixo a ser pago
          RETURN vVlFixo;

          EXCEPTION
            WHEN NO_DATA_FOUND
              THEN vVlFixo := 0;

          END;

      END IF;

      vCdHistValorGeralCEFAGrup := PKGPAG_GERAL.FTabelaValorGeral(vCdValorGeralCEFAGrup,
                                                                  1, vAno, vMes);
      BEGIN

        vVlPagamento := 0;

        IF pNuRubrica in (483,484,560)
           THEN
             BEGIN

             SELECT EPH1.VLPAGAMENTO
               INTO vVlPagamento
               FROM EPAGHISTORICORUBRICAVINCULO EPH1
              WHERE EPH1.CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupamento
                AND EPH1.CDVINCULO = PCDVINCULO
                AND EPH1.CDFOLHAPAGAMENTO = PCDFOLHA;

             if vVlPagamento > 0
               then
                 vVlPagamento := vVlPagamento;
               end if;

             EXCEPTION
               WHEN NO_DATA_FOUND
                 THEN vVlPagamento := 0;
            END;

        END IF;

        SELECT (V.vlFixo + vVlPagamento) * vVlIndice / 100
          INTO vVlFixo
          FROM EPagValorEspecCEFAgrup V
         WHERE V.CdHistValorGeralCEFAgrup = vCdHistValorGeralCEFAGrup
           AND V.NuNivel = pNuNivelPagamento
           AND V.NuReferencia = pNuReferenciaPagamento;

        -- Caso a tabela limitadora seja informada
        IF vCdValorGeralCEFAgrupLimite IS NOT NULL THEN   -- LIMITE ESPECIFICO/GERAL
         -- Busca a tabela geral limitadora
           vCdHistValorGeralCEFAGrup := PKGPAG_GERAL.FTabelaValorGeral(vCdValorGeralCEFAgrupLimite,
                                                                       1, vAno, vMes);
          BEGIN

          SELECT V.vlFixo
            INTO vVlFixoCEFLimite
            FROM EPagValorEspecCEFAgrup V
           WHERE V.CdHistValorGeralCEFAgrup = vCdHistValorGeralCEFAGrup
             AND V.NuNivel = pNuNivelPagamento
             AND V.NuReferencia = pNuReferenciaPagamento;

           IF NVL(vVlFixoCEFLimite, 0) > 0 AND vVlFixoCEFLimite < vVlFixo
            THEN
              vVlFixo := vVlFixoCEFLimite;

           END IF ;

           EXCEPTION

            WHEN NO_DATA_FOUND THEN

             RETURN vVlFixo;

          END;

       END IF;

       RETURN vVlFixo;

       EXCEPTION

         WHEN NO_DATA_FOUND THEN

       RETURN 0;
      END;

  END;
  EXCEPTION

   WHEN NO_DATA_FOUND THEN

  RETURN 0;

END;

FUNCTION FMneCELG(pCdValorGeralCEFAgrup IN INTEGER,
                              pNuVersao             IN INTEGER,
                              pAnoMes               IN VARCHAR2,
                              pNuNivel              IN VARCHAR2,
                              pNuReferencia         IN VARCHAR2)

  RETURN NUMBER IS

  vVlFixo NUMBER(13,2);

  vAno              char(4) := SUBSTR(pAnoMes,1,4);

  vMes              char(2) := SUBSTR(pAnoMes,5,2);

BEGIN

   SELECT VlFixo
     INTO vVlFixo
     FROM (SELECT VE.Vlfixo, NVGA.NuVersao
             FROM EPagValorGeralCEFAgrup VGA
            INNER JOIN EPagValorGeralCEFAgrupVersao NVGA
               ON VGA.CdValorGeralCEFAGrup= NVGA.CdValorGeralCEFAGrup
            INNER JOIN EPagHistValorGeralCEFAgrup HVGA
               ON NVGA.CdValorGeralCEFAgrupVersao= HVGA.CdValorGeralCEFAgrupVersao
            INNER JOIN EPagValorEspecCEFAgrup VE
               ON HVGA.CdHistValorGeralCEFAgrup = VE.CdHistValorGeralCEFAgrup
            WHERE NVGA.NuVersao IN (1) AND
                  NVGA.CdValorGeralCEFAgrup = pCdValorGeralCEFAgrup AND
                  VE.NuNivel = pNuNivel AND
                  VE.NuReferencia = pNuReferencia AND
                 ((HVGA.NuAnoInicioVigencia < vAno OR
                 (HVGA.NuAnoInicioVigencia = vAno AND
                  HVGA.NuMesInicioVigencia <= vMes))
                 AND
                 (HVGA.NuAnoFimVigencia > vAno OR
                 (HVGA.NuAnoFimVigencia = vAno AND
                  HVGA.NuMesFimVigencia >= vMes) OR
                  HVGA.NuAnoFimVigencia IS NULL))
           ORDER BY NVGA.NuVersao DESC)
   WHERE ROWNUM < 2;

   RETURN vVlFixo;

EXCEPTION

  WHEN OTHERS THEN

    RETURN 0;

END;

FUNCTION FCCOSUBST(pCdVinculo number, pAnoMes char, pCdOrgao number, pDtCalculo DATE)

  return number is

  vNuReferencia varchar2(10);
  vNuNivelComissionado number;
  vCdRelacaoTrabalho number;
  vAno              char(4) := SUBSTR(pAnoMes,1,4);
  vMes              char(2) := SUBSTR(pAnoMes,5,2);
  vVlFixo number(13,2) := 0;
  vDtFim  date := LAST_DAY(pDtCalculo);  -- Ultimo dia do mes do calculo

BEGIN

  SELECT ecc.nureferencia, ecc.nunivel, ecc.cdrelacaotrabalho, ecc.dtfim
   into vNuReferencia, vNuNivelComissionado, vCdRelacaoTrabalho, vDtFimSubst
    from ecadhistcargocom ecc
   where ecc.cdvinculo = pCdVinculo
     and ecc.flanulado = 'N'
     and ecc.fltipoprovimento = 'S'
     and ((ecc.dtinicio <= vDtFim AND
           to_char(ecc.dtfim,'YYYYMM') >= to_char(pDtCalculo,'YYYYMM') OR ecc.DtFim IS NULL))
     AND ROWNUM = 1;

   vVlFixo := PKGPAG_GERAL.FRetornaValorFixoCCO(vNuReferencia,
                         vNuNivelComissionado,vCdRelacaoTrabalho,
                         1, pCdOrgao,1, vAno, vMes);

   if vDtFimSubst <= pDtCalculo -- Proporcionalizar
      then
         vVlFixo := vVlFixo / 30 * to_number(to_char(vDtFimSubst,'DD'));
   end if;

   RETURN vVlFixo;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;

END FCCOSUBST;

FUNCTION FBASEINC(pCdVinculo number, pAnoMes char, pCdRubrica number, pCdOrgao number)

  RETURN NUMBER IS

  vvlFixo           NUMBER(13,2);
  vAno              char(4) := SUBSTR(pAnoMes,1,4);
  vMes              char(2) := SUBSTR(pAnoMes,5,2);
  vCdPadraoFUCAgrup INTEGER;
  vVlReferencia     NUMBER(13,2);
  --vCdIncorporacao   number;
  vVlPerc           number(11,4) :=0;
  vVlSoma           number(13,2) :=0;
  vCount            number :=0;

BEGIN

  -- Verifica quantos tem para no final somar os percentuais ou retonar o valor somente.
  SELECT count(*)
    INTO vCount
    FROM EbpcIncorporacaoAtivo IA
   WHERE IA.CdVinculo = pCdVinculo
     AND IA.CdRubricaAgrupamento = pCdRubrica
     AND ((IA.NuAnoInicio < vAno OR (IA.NuAnoInicio = vAno
     AND   IA.NuMesInicio <= vMes))
     AND (IA.NuAnoFim > vAno OR (IA.NuAnoFim = vAno
     AND  IA.NuMesFim >= vMes) OR IA.NuAnoFim IS NULL));

  FOR vIncorp IN (SELECT IA.CdTipoIncorporacaoAtivo,
                         IA.CdValorReferencia,
                         IA.NuNivelCEF,
                         IA.NuReferenciaCEF,
                         IA.CdValorGeralCEFAgrup,
                         IA.FlUtilizaBaseNiveRefCEF,
                         IA.DeCodigoComissionado,
                         IA.NuNivelComissionado,
                         IA.FlUtilizaTabPropria,
                         IA.DePadraoFUC,
                         IA.QtValorReferencia,
                         IA.VlMinimoRecebimento,
                         IA.FlAtualizacaoConstante,
                         IA.CdBaseIncorporacaoAtivo,
                         IA.Vlpercproporcionalidade,
                         CASE WHEN IA.CdRelacaoTrabalho IS NULL THEN
                           6
                         ELSE
                           IA.CdRelacaoTrabalho
                         END CdRelacaoTrabalho
                    FROM EbpcIncorporacaoAtivo IA
                   WHERE IA.CdVinculo = pCdVinculo
                     AND IA.CdRubricaAgrupamento = pCdRubrica
                     AND ((IA.NuAnoInicio < vAno OR (IA.NuAnoInicio = vAno AND
                           IA.NuMesInicio <= vMes))
                     AND (IA.NuAnoFim > vAno OR (IA.NuAnoFim = vAno AND
                      IA.NuMesFim >= vMes) OR IA.NuAnoFim IS NULL)))

   LOOP
     -- Para quem tem mais de um para a mesma rubrica soma e aplica o percentual, sen?o retorna o valor
     -- e o percentual ? calculado depois.
     vVlPerc := vIncorp.Vlpercproporcionalidade;

     CASE vIncorp.CdBaseIncorporacaoAtivo

       WHEN 1 THEN -- Exige o nivel/referencia do cargo efetivo

           BEGIN

           SELECT VlFixo
             INTO vVlFixo
             FROM (SELECT VE.Vlfixo, NVGA.NuVersao
                     FROM EPagValorGeralCEFAgrup VGA
                     INNER JOIN EPagValorGeralCEFAgrupVersao NVGA
                             ON VGA.CdValorGeralCEFAGrup= NVGA.CdValorGeralCEFAGrup
                     INNER JOIN EPagHistValorGeralCEFAgrup HVGA
                             ON NVGA.CdValorGeralCEFAgrupVersao= HVGA.CdValorGeralCEFAgrupVersao
                     INNER JOIN EPagValorEspecCEFAgrup VE
                             ON HVGA.CdHistValorGeralCEFAgrup = VE.CdHistValorGeralCEFAgrup
                     WHERE NVGA.NuVersao = 1
                       AND NVGA.CdValorGeralCEFAgrup = vInCorp.Cdvalorgeralcefagrup
                       AND VE.NuNivel = vInCorp.Nunivelcef
                       AND VE.NuReferencia = vInCorp.Nureferenciacef
                       AND ((HVGA.NuAnoInicioVigencia < vAno OR
                           (HVGA.NuAnoInicioVigencia = vAno AND
                            HVGA.NuMesInicioVigencia <= vMes))
                       AND (HVGA.NuAnoFimVigencia > vAno OR
                           (HVGA.NuAnoFimVigencia = vAno AND
                            HVGA.NuMesFimVigencia >= vMes) OR
                            HVGA.NuAnoFimVigencia IS NULL))
           ORDER BY NVGA.NuVersao DESC)
           WHERE ROWNUM < 2;

           EXCEPTION
             WHEN NO_DATA_FOUND THEN

                RETURN 0;
           END;

       WHEN 2 THEN -- Exige o codigo/nivel do cargo comissionado

         IF vIncorp.FlUtilizaTabPropria = 'N'
           THEN

           vVlFixo := PKGPAG_GERAL.FRetornaValorFixoCCO(vIncorp.DeCodigoComissionado,
                         vIncorp.NuNivelComissionado,vIncorp.CdRelacaoTrabalho,
                         1, pCdOrgao,1, vAno, vMes);
          ELSE

           BEGIN

             SELECT VCI.VlFixo
               INTO vvlFixo
               FROM EBpcCargoComIncorp CCI
              INNER JOIN EBpcValorCargoComIncorp VCI
                 ON CCI.CdCargoComIncorp = VCI.CdCargoComIncorp
              WHERE VCI.NmCodigo = vIncorp.DeCodigoComissionado AND
                    CCI.CdAgrupamento = 1 AND
                    VCI.CdNivel = vIncorp.NuNivelComissionado AND
                    ((CCI.NuAnoInicio < vAno OR
                    (CCI.NuAnoInicio = vAno AND
                     CCI.NuMesInicio <= vMes))
                    AND
                    (CCI.NuAnoFim > vAno OR
                    (CCI.NuAnoFim = vAno AND
                     CCI.NuMesFim >= vMes) OR
                     CCI.NuAnoFim IS NULL));

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                vVlFixo := 0;

            END;

         END IF;

       WHEN 3 THEN -- Exige o padr?o da func?o de chefia

         BEGIN

           SELECT PFA.CdPadraoFUCAgrup
             INTO vCdPadraoFUCAgrup
             FROM EPagPadraoFucAgrup PFA
            WHERE PFA.NmPadrao = vIncorp.DePadraoFUC AND
                  PFA.CdAgrupamento = 1;

         EXCEPTION

           WHEN NO_DATA_FOUND THEN

             RETURN 0;

         END;

         IF vIncorp.FlUtilizaTabPropria = 'N'
           THEN

           vVlFixo := PKGPAG_GERAL.FRetornaValorFixoFUC(vCdPadraoFUCAgrup,1,pCdOrgao,
                                                        1, vAno, vMes);

         ELSE

           BEGIN

             SELECT VFI.VlFixo
               INTO vvlFixo
               FROM EBpcFuncaoChefiaIncorp FCI
              INNER JOIN EBpcValorFuncaoChefiaIncorp VFI
                 ON FCI.CdFuncaoChefiaIncorp = VFI.CdFuncaoChefiaIncorp
              WHERE FCI.CdAgrupamento = 1 AND
                    VFI.CdPadraoFUCAgrup = vCdPadraoFUCAgrup AND
                    ((FCI.NuAnoInicio < vAno OR
                    (FCI.NuAnoInicio = vAno AND
                     FCI.NuMesInicio <= vMes))
                    AND
                    (FCI.NuAnoFim > vAno OR
                    (FCI.NuAnoFim = vAno AND
                     FCI.NuMesFim >= vMes) OR
                     FCI.NuAnoFim IS NULL));

              RETURN vvlFixo;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                RETURN 0;

            END;

          END IF;

       WHEN 4 THEN -- Exige um valor de referencia

          IF vIncorp.CdValorReferencia IS NOT NULL THEN

            BEGIN
              select ephrv.vlreferencia
                into vVlReferencia
                from EPagValorReferencia epv
                inner join epagvalorreferenciaversao eprv
                        on (eprv.cdvalorreferencia = epv.cdvalorreferencia)
                inner join epaghistvalorreferencia ephrv
                        on (ephrv.cdvalorreferenciaversao = eprv.cdvalorreferenciaversao)
                where epv.cdvalorreferencia = vInCorp.Cdvalorreferencia
                AND eprv.nuversao = 1
                AND ((ephrv.nuanoiniciovigencia < vAno OR
                     (ephrv.nuanoiniciovigencia = vAno AND
                      ephrv.numesiniciovigencia <= vMes))
                AND  (ephrv.nuanofimvigencia > vAno OR
                     (ephrv.nuanofimvigencia = vAno AND
                      ephrv.numesfimvigencia >= vMes) OR
                      ephrv.nuanofimvigencia IS NULL));

              vVlFixo := vVlReferencia*vIncorp.Qtvalorreferencia;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                vVlFixo := 0;

            END;

          END IF;

       WHEN 5 THEN -- Considera o valor do nivel/referencia do cargo efetivo atual do servidor

         IF PKGPAG_VAR.vgValorFixoCEF.VlFixo IS NOT NULL THEN

          RETURN PKGPAG_VAR.vgValorFixoCEF.VlFixo;

         END IF;

       ELSE

         vVlFixo := 0;

    END CASE;
    if vCount > 1
      then
        vVlSoma := vVlSoma + (vVlFixo * vVlPerc / 100);
    else
        vVlSoma := vVlFixo;
    end if;

   END LOOP ;

   RETURN vVlSoma;

END;

FUNCTION FVALORINC(pCdIncorporcaoAtivo number, pAnoMes char, pCdOrgao number)

  RETURN NUMBER IS

  vvlFixo           NUMBER(13,2);
  vAno              char(4) := SUBSTR(pAnoMes,1,4);
  vMes              char(2) := SUBSTR(pAnoMes,5,2);
  vCdPadraoFUCAgrup INTEGER;
  vVlReferencia     NUMBER(13,2);
  --vCdIncorporacao   number;
  vVlPerc           number(11,4) :=0;
  vVlSoma           number(13,2) :=0;
  --vCount            number :=0;

BEGIN

  FOR vIncorp in (
  SELECT IA.CdTipoIncorporacaoAtivo,IA.CdValorReferencia,IA.NuNivelCEF,
         IA.NuReferenciaCEF,IA.CdValorGeralCEFAgrup,IA.FlUtilizaBaseNiveRefCEF,
         IA.DeCodigoComissionado,IA.NuNivelComissionado,IA.FlUtilizaTabPropria,
         IA.DePadraoFUC,IA.QtValorReferencia,IA.VlMinimoRecebimento,
         IA.FlAtualizacaoConstante,IA.CdBaseIncorporacaoAtivo,
         IA.Vlpercproporcionalidade,
         CASE WHEN IA.CdRelacaoTrabalho IS NULL THEN
                  6
              ELSE
                 IA.CdRelacaoTrabalho
              END CdRelacaoTrabalho
         FROM EbpcIncorporacaoAtivo IA
        WHERE IA.CdIncorporacaoAtivo = pCdIncorporcaoAtivo)

   LOOP
     -- Para quem tem mais de um para a mesma rubrica soma e aplica o percentual, sen?o retorna o valor
     -- e o percentual ? calculado depois.
     vVlPerc := vIncorp.Vlpercproporcionalidade;

     CASE vIncorp.CdBaseIncorporacaoAtivo

       WHEN 1 THEN -- Exige o nivel/referencia do cargo efetivo

           BEGIN

           SELECT VlFixo
             INTO vVlFixo
             FROM (SELECT VE.Vlfixo, NVGA.NuVersao
                     FROM EPagValorGeralCEFAgrup VGA
                     INNER JOIN EPagValorGeralCEFAgrupVersao NVGA
                             ON VGA.CdValorGeralCEFAGrup= NVGA.CdValorGeralCEFAGrup
                     INNER JOIN EPagHistValorGeralCEFAgrup HVGA
                             ON NVGA.CdValorGeralCEFAgrupVersao= HVGA.CdValorGeralCEFAgrupVersao
                     INNER JOIN EPagValorEspecCEFAgrup VE
                             ON HVGA.CdHistValorGeralCEFAgrup = VE.CdHistValorGeralCEFAgrup
                     WHERE NVGA.NuVersao = 1
                       AND NVGA.CdValorGeralCEFAgrup = vInCorp.Cdvalorgeralcefagrup
                       AND VE.NuNivel = vInCorp.Nunivelcef
                       AND VE.NuReferencia = vInCorp.Nureferenciacef
                       AND ((HVGA.NuAnoInicioVigencia < vAno OR
                           (HVGA.NuAnoInicioVigencia = vAno AND
                            HVGA.NuMesInicioVigencia <= vMes))
                       AND (HVGA.NuAnoFimVigencia > vAno OR
                           (HVGA.NuAnoFimVigencia = vAno AND
                            HVGA.NuMesFimVigencia >= vMes) OR
                            HVGA.NuAnoFimVigencia IS NULL))
           ORDER BY NVGA.NuVersao DESC)
           WHERE ROWNUM < 2;

           EXCEPTION
             WHEN NO_DATA_FOUND THEN

                RETURN 0;
           END;

       WHEN 2 THEN -- Exige o codigo/nivel do cargo comissionado

         IF vIncorp.FlUtilizaTabPropria = 'N'
           THEN

           vVlFixo := PKGPAG_GERAL.FRetornaValorFixoCCO(vIncorp.DeCodigoComissionado,
                         vIncorp.NuNivelComissionado,vIncorp.CdRelacaoTrabalho,
                         1, pCdOrgao,1, vAno, vMes);
          ELSE

           BEGIN

             SELECT VCI.VlFixo
               INTO vvlFixo
               FROM EBpcCargoComIncorp CCI
              INNER JOIN EBpcValorCargoComIncorp VCI
                 ON CCI.CdCargoComIncorp = VCI.CdCargoComIncorp
              WHERE VCI.NmCodigo = vIncorp.DeCodigoComissionado AND
                    CCI.CdAgrupamento = 1 AND
                    VCI.CdNivel = vIncorp.NuNivelComissionado AND
                    ((CCI.NuAnoInicio < vAno OR
                    (CCI.NuAnoInicio = vAno AND
                     CCI.NuMesInicio <= vMes))
                    AND
                    (CCI.NuAnoFim > vAno OR
                    (CCI.NuAnoFim = vAno AND
                     CCI.NuMesFim >= vMes) OR
                     CCI.NuAnoFim IS NULL));

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                vVlFixo := 0;

            END;

         END IF;

       WHEN 3 THEN -- Exige o padr?o da func?o de chefia

         BEGIN

           SELECT PFA.CdPadraoFUCAgrup
             INTO vCdPadraoFUCAgrup
             FROM EPagPadraoFucAgrup PFA
            WHERE PFA.NmPadrao = vIncorp.DePadraoFUC AND
                  PFA.CdAgrupamento = 1;

         EXCEPTION

           WHEN NO_DATA_FOUND THEN

             RETURN 0;

         END;

         IF vIncorp.FlUtilizaTabPropria = 'N'
           THEN

           vVlFixo := PKGPAG_GERAL.FRetornaValorFixoFUC(vCdPadraoFUCAgrup,1,pCdOrgao,
                                                        1, vAno, vMes);

         ELSE

           BEGIN

             SELECT VFI.VlFixo
               INTO vvlFixo
               FROM EBpcFuncaoChefiaIncorp FCI
              INNER JOIN EBpcValorFuncaoChefiaIncorp VFI
                 ON FCI.CdFuncaoChefiaIncorp = VFI.CdFuncaoChefiaIncorp
              WHERE FCI.CdAgrupamento = 1 AND
                    VFI.CdPadraoFUCAgrup = vCdPadraoFUCAgrup AND
                    ((FCI.NuAnoInicio < vAno OR
                    (FCI.NuAnoInicio = vAno AND
                     FCI.NuMesInicio <= vMes))
                    AND
                    (FCI.NuAnoFim > vAno OR
                    (FCI.NuAnoFim = vAno AND
                     FCI.NuMesFim >= vMes) OR
                     FCI.NuAnoFim IS NULL));

              RETURN vvlFixo;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                RETURN 0;

            END;

          END IF;

       WHEN 4 THEN -- Exige um valor de referencia

          IF vIncorp.CdValorReferencia IS NOT NULL THEN

            BEGIN
              select ephrv.vlreferencia
                into vVlReferencia
                from EPagValorReferencia epv
                inner join epagvalorreferenciaversao eprv
                        on (eprv.cdvalorreferencia = epv.cdvalorreferencia)
                inner join epaghistvalorreferencia ephrv
                        on (ephrv.cdvalorreferenciaversao = eprv.cdvalorreferenciaversao)
                where epv.cdvalorreferencia = vInCorp.Cdvalorreferencia
                AND eprv.nuversao = 1
                AND ((ephrv.nuanoiniciovigencia < vAno OR
                     (ephrv.nuanoiniciovigencia = vAno AND
                      ephrv.numesiniciovigencia <= vMes))
                AND  (ephrv.nuanofimvigencia > vAno OR
                     (ephrv.nuanofimvigencia = vAno AND
                      ephrv.numesfimvigencia >= vMes) OR
                      ephrv.nuanofimvigencia IS NULL));

              vVlFixo := vVlReferencia*vIncorp.Qtvalorreferencia;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                vVlFixo := 0;

            END;

          END IF;

       WHEN 5 THEN -- Considera o valor do nivel/referencia do cargo efetivo atual do servidor

         IF PKGPAG_VAR.vgValorFixoCEF.VlFixo IS NOT NULL THEN

          RETURN PKGPAG_VAR.vgValorFixoCEF.VlFixo;

         END IF;

       ELSE

         vVlFixo := 0;

    END CASE;

    vVlSoma := vVlSoma + (vVlFixo * vVlPerc / 100);

   END LOOP ;

   RETURN vVlSoma;

END;

FUNCTION FPERCENTUALINC(pCdVinculo number, pAnoMes char, pCdRubrica number, pCdOrgao number)

  RETURN NUMBER IS

  vvlFixo           NUMBER(13,2);
  vAno              char(4) := SUBSTR(pAnoMes,1,4);
  vMes              char(2) := SUBSTR(pAnoMes,5,2);
  --vCdIncorporacao   number;

BEGIN

  SELECT SUM(IA.VLPERCPROPORCIONALIDADE)
    INTO vVlFixo
    FROM EbpcIncorporacaoAtivo IA
   WHERE IA.CdVinculo = pCdVinculo
     AND IA.CdRubricaAgrupamento = pCdRubrica
     AND ((IA.NuAnoInicio < vAno OR (IA.NuAnoInicio = vAno AND
           IA.NuMesInicio <= vMes))
     AND (IA.NuAnoFim > vAno OR (IA.NuAnoFim = vAno AND
          IA.NuMesFim >= vMes) OR IA.NuAnoFim IS NULL));

  RETURN vVlFixo;

  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RETURN 0;

END;

FUNCTION FRETORNABLOCOSFORMULA (pCdExpForm IN INTEGER)
  RETURN PKGPAG_RETROATIVO.tBlocos IS

  vBlocos PKGPAG_RETROATIVO.tBlocos;

BEGIN

  FOR vB IN (SELECT PAG113.CdFormulaCalculoBloco,
               PAG113.CdExpressaoFormCalc,
               PAG113.SgBloco,
               PAG114.CdTipoMneumonico,
               PAG82.SgTipoMneumonico
          FROM EPAGFORMULACALCULOBLOCO PAG113
         INNER JOIN EPAGFORMULACALCBLOCOEXPRESSAO PAG114 ON (PAG114.CDFORMULACALCULOBLOCO = PAG113.CDFORMULACALCULOBLOCO)
         INNER JOIN EPAGTIPOMNEUMONICO PAG82 ON (PAG82.CDTIPOMNEUMONICO = PAG114.CDTIPOMNEUMONICO)
         WHERE PAG113.CdExpressaoFormCalc = PCdExpForm
         ORDER BY CdFormulaCalculoBloco ASC)
  LOOP

    vBlocos(vB.CdFormulaCalculoBloco) := vB;

  END LOOP;

  RETURN vBlocos;

END FRETORNABLOCOSFORMULA;

FUNCTION FRETORNABLOCOSBASES (pCdExpForm IN INTEGER)
  RETURN PKGPAG_RETROATIVO.tBlocos IS

  vBlocos PKGPAG_RETROATIVO.tBlocos;

BEGIN

  FOR vB IN (select epb.cdbasecalculobloco,
                    ex2.cdbasecalculoblocoexpressao,
                    epb.sgbloco,
                    ex2.cdtipomneumonico,
                  pag82.sgtipomneumonico from epagbasecalculobloco epb
              INNER JOIN epagbasecalculoblocoexpressao ex2 ON ex2.cdbasecalculobloco = epb.cdbasecalculobloco
              INNER JOIN EPAGTIPOMNEUMONICO PAG82 ON (PAG82.CDTIPOMNEUMONICO = ex2.CDTIPOMNEUMONICO)
              where epb.cdhistbasecalculo=pCdExpForm
              ORDER BY epb.CdBASECalculoBloco ASC)
  LOOP

    vBlocos(vB.CdBASECalculoBloco) := vB;

  END LOOP;

  RETURN vBlocos;

END FRETORNABLOCOSBASES;

FUNCTION FRUBRICASBLOCO (pCdFormCalcBlocoExp number)
   RETURN STRING IS

   vInRubricas string(5000) := null ;

BEGIN

   -- Rubricas que fazem parte do bloco de rubricas
   FOR F_RUB IN (
       SELECT PAG126.CdRubricaAgrupamento
         FROM EPAGFORMCALCBLOCOEXPRUBAGRUP PAG126
        WHERE PAG126.CdFormulaCalcBlocoExpressao = pCdFormCalcBlocoExp)
   LOOP
      vInRubricas := vInRubricas || case when vInRubricas is not null then ',' else '' end || F_RUB.CDRUBRICAAGRUPAMENTO;
   END LOOP;

   RETURN vInRubricas;

END FRUBRICASBLOCO;

FUNCTION FRUBRICASBLOCOBASE (pBase char, pSgBloco char)
   RETURN STRING IS

   vInRubricas string(5000) := null ;

BEGIN

   -- Rubricas que fazem parte do bloco para a base de calculo
   FOR F_RUB IN (select ebr.cdbasecalculoblocoexpressao, ebr.cdrubricaagrupamento, ebb.sgbloco
                   from epagbasecalculo eb
                  inner join epagbasecalculoversao ev on (ev.cdbasecalculo = eb.cdbasecalculo)
                  inner join epaghistbasecalculo eh on (eh.cdversaobasecalculo = ev.cdversaobasecalculo)
                  inner join epagbasecalculobloco ebb on (eh.cdhistbasecalculo = ebb.cdhistbasecalculo)
                  inner join epagbasecalculoblocoexpressao ebe on (ebe.cdbasecalculobloco = ebb.cdbasecalculobloco)
                  inner join epagbasecalcblocoexprrubagrup ebr on (ebr.cdbasecalculoblocoexpressao = ebe.cdbasecalculoblocoexpressao)
                  where eb.cdagrupamento=1
                    and eb.sgbasecalculo = pBase
                    and eh.nuanofimvigencia is null
                    and ebb.SGBLOCO = pSgBloco)
   LOOP
      vInRubricas := vInRubricas || case when vInRubricas is not null then ',' else '' end || F_RUB.CDRUBRICAAGRUPAMENTO;
   END LOOP;

   RETURN vInRubricas;

END FRUBRICASBLOCOBASE;

FUNCTION FRUBRICASTMPFORMULA (pCdFolha number, pCdVinculo number, pCdFormCalcBlocoExp number,
                              pCdPagRetroativo number)
   RETURN STRING IS

   vNotInRubricas string(5000) := null ;

BEGIN

   -- Rubricas que fazem parte do bloco de rubricas
   FOR F_RUB IN (

       SELECT DISTINCT (ETR.CDRUBRICA)
         FROM EPAGRETROATIVOVINCULOFOLHA ETR
        WHERE ETR.CdFolha = pCdFolha
          AND ETR.CdVinculo = pCdVinculo
          AND ETR.Cdpagretroativo = pCdPagRetroativo
          AND ETR.CDRUBRICA IN (SELECT PAG126.CdRubricaAgrupamento
                                  FROM EPAGFORMCALCBLOCOEXPRUBAGRUP PAG126
                                 WHERE PAG126.CdFormulaCalcBlocoExpressao = pCdFormCalcBlocoExp))

      -- select etfr.cdrubricaagrupamento
      --   from ePAGRETROATIVOformula etfr
      --  where etfr.cdrubricaformula = pCdRubricaFormula)

   LOOP
      vNotInRubricas := vNotInRubricas || case when vNotInRubricas is not null then ',' else '' end || F_RUB.CDRUBRICA;
   END LOOP;

   RETURN vNotInRubricas;

END FRUBRICASTMPFORMULA;

-- Rubricas da BASE que est?o recalculadas no retroativo

FUNCTION FRUBRICASTMPBASE (pCdFolha number, pCdVinculo number)
   RETURN STRING IS

   vNotInRubricas string(5000) := null ;

BEGIN

   -- Rubricas que fazem parte do bloco de rubricas
   FOR F_RUB IN (

       SELECT DISTINCT (ETR.CDRUBRICA)
         FROM EPAGRETROATIVOVINCULOFOLHA ETR
        WHERE ETR.CdFolha = pCdFolha
          AND ETR.CdVinculo = pCdVinculo
          AND ETR.CDRUBRICA IN (8451,8336,10411,8852,10603,10712,8342,10730,8220,10700,8566,10767,
                                37575,10790,22757,10513,10736,10784,10357,10483,10351,10489,24597,
                                23637,23677,24589,33297,33303,24457,24657))

      -- select etfr.cdrubricaagrupamento
      --   from ePAGRETROATIVOformula etfr
      --  where etfr.cdrubricaformula = pCdRubricaFormula)

   LOOP
      vNotInRubricas := vNotInRubricas || case when vNotInRubricas is not null then ',' else '' end || F_RUB.CDRUBRICA;
   END LOOP;

   RETURN vNotInRubricas;

END FRUBRICASTMPBASE;

FUNCTION FFORMULABLOCOEXPRESSAO (pCdFormCalcBloco number)
   RETURN NUMBER IS

   vCdFormCalcBlocoExp number;

BEGIN

   SELECT PAG114.CdFormulaCalcBlocoExpressao
     INTO vCdFormCalcBlocoExp
     FROM EPAGFORMULACALCBLOCOEXPRESSAO PAG114
    WHERE (PAG114.CdFormulaCalculoBloco = pCdFormCalcBloco);

   RETURN vCdFormCalcBlocoExp;

   exception
     when too_many_rows then
       dbms_output.put_line(pCdFormCalcBloco);

END FFORMULABLOCOEXPRESSAO;

FUNCTION FVERSAOFORMULACALC (pCdFormulaCalculo number)
  RETURN NUMBER IS

  vCdFormulaVersao  Number; -- C?digo usado para buscar o historico da formula de c?lculo.

BEGIN

    -- Vers?o da F?rmula de calculo
   SELECT PAG112.CdFormulaVersao
     INTO vCdFormulaVersao
     FROM EPAGFORMULAVERSAO PAG112
    WHERE PAG112.CDFORMULACALCULO = pCdFormulaCalculo; --(PAG112.CdFormulaVersao = 1548)

   RETURN vCdFormulaVersao;

END FVERSAOFORMULACALC;

FUNCTION FHISTFORMULACALCULO (pCdVersao number) RETURN NUMBER IS

   vCdHistFormula number;

   CURSOR cForm is
      SELECT * --PAG116.CdHistFormulaCalculo
--       INTO vCdHistFormula
        FROM EPAGHISTFORMULACALCULO PAG116 -- PROCURAR CDFORMULAVERSAO
       WHERE PAG116.Cdformulaversao = pCdVersao
       ORDER BY PAG116.NUANOFIM, PAG116.NUMESFIM;

BEGIN

   FOR i in CForm
     LOOP
       vCdHistFormula := i.Cdhistformulacalculo;

       if i.NuAnoFim is null
         then
          continue;
       end if;

   END LOOP;

   RETURN vCdHistFormula;

END FHISTFORMULACALCULO;

FUNCTION FEXPRESSAOFORMULA (pCdHist number) return number is

   vCdExpForm number;

BEGIN

   vDeFormExp := null;
   SELECT PAG115.Deformulaexpressao, PAG115.Cdexpressaoformcalc
     INTO vDeFormExp, vCdExpForm
     FROM EPAGEXPRESSAOFORMCALC PAG115  -- ACHAR cdhistformulacalculo
    WHERE (PAG115.CdHistFormulaCalculo = pCdHist)
      AND (PAG115.FlExpGeral = 'S');

   RETURN vCdExpForm;

END FEXPRESSAOFORMULA;

FUNCTION FRETORNACARGAHORARIA (vCdOrgao number, vCdVinculo number, pAnoMes char)
  RETURN NUMBER IS

  vNuCho  Number              := 0;
  vCdHistCargoEfetivo         Number;

BEGIN

     -- Procura no ?rg?o de origem
     SELECT Cef.CdHistCargoEfetivo
       INTO vCdHistCargoEfetivo
       FROM ECADHISTCARGOEFETIVO CEF
      WHERE CEF.CDVINCULO = vCDVINCULO
        AND CEF.FLANULADO = 'N'
        AND CEF.CDORGAOEXERCICIO = vCDORGAO
        AND CEF.CDRELACAOTRABALHO = 5
        AND (TO_CHAR(CEF.DtInicio,'YYYYMM') <= to_char(pAnoMes) AND
             (to_char(CEF.DtFim,'YYYYMM') >= to_char(pAnoMes) OR CEF.DtFim IS NULL))
        AND CEF.CDNATUREZAVINCULO = 1;

      SELECT ECHO.NuCargaHoraria
        INTO vNuCho
        FROM ECADHISTCARGAHORARIA ECHO
       WHERE ECHO.CDHISTCARGOEFETIVO = vCdHistCargoEfetivo
         AND ECHO.FLANULADO = 'N'
         AND (TO_CHAR(ECHO.DTINICIAL,'YYYYMM') <= to_char(pAnoMes) AND
             (to_char(ECHO.DtFim,'YYYYMM') >= to_char(pAnoMes) OR ECHO.DtFim IS NULL))
         AND ROWNUM < 2;

      RETURN vNuCho;

      EXCEPTION
          WHEN NO_DATA_FOUND THEN RETURN VNUCHO;

END FRETORNACARGAHORARIA;

FUNCTION FRETORNAVALORSALARIO(vNuNivel             number,
                                                vNuReferencia        string,
                                                vNuAno               number,
                                                vNuMes               number,
                                                vCdEstruturaCarreira number,
                                                vCdAgrupamento       number,
                                                vNuVersao    number)
  RETURN NUMBER IS

  vCdEstruturaCarreiraCarreira Number;
  vCdValorGeralCefAgrup        Number;
--  vNuVersao                    Number;
  vCdHistValorGeralCEFAgrup    Number;
  vValorSalario                NUMBER(13,2);

BEGIN

  -- Achar CDESTRUTURACARREIRACARREIRA
  select CDESTRUTURACARREIRACARREIRA
    INTO vCdEstruturaCarreiraCarreira
    from ecadestruturacarreira
   where cdestruturacarreira = vCdEstruturaCarreira; -- Vem da movimenta??o da progress?o.

  -- Atrav?s de CDESTRUTURACARREIRACARREIRA acha a tabela utilizada do Agrupamento

  SELECT HNRA.CdValorGeralCEFAgrup
    INTO vCdValorGeralCefAgrup
    FROM EPagNivelRefCEFAgrup NRA
   INNER JOIN EPagNivelRefCEFAgrupVersao NRAV
      ON NRA.CdNivelRefCEFAgrup = NRAV.CdNivelRefCEFAgrup
   INNER JOIN EPagHistNivelRefCefAgrup HNRA
      ON NRAV.CdNivelRefCEFAgrupVersao = HNRA.cdNivelRefCEFAgrupVersao
   INNER JOIN ECadEstruturaCarreira EC
      ON EC.CdAgrupamento = NRA.CdAgrupamento
     AND EC.CdEstruturaCarreira = NRA.CdEstruturaCarreira
   WHERE NRA.CdAgrupamento = vCdAgrupamento
     AND NRAV.NuVersao = vNuVersao
     AND EC.CdEstruturaCarreira = vCdEstruturaCarreiraCarreira
     AND ((HNRA.NuAnoInicioVigencia < vNuAno OR
         (HNRA.NuAnoInicioVigencia = vNuAno AND
         HNRA.NuMesInicioVigencia <= vNuMes)) AND
         (HNRA.NuAnoFimVigencia > vNuAno OR
         (HNRA.NuAnoFimVigencia = vNuANo AND HNRA.NuMesFimVigencia >= vNuMes) OR
         HNRA.NuAnoFimVigencia IS NULL))
   ORDER BY NRAV.NuVersao DESC;

-- Achar o CDHISTVALORGERALCEFAGRUP

   SELECT HVGA.CdHistValorGeralCEFAgrup
     INTO vCdHistValorGeralCEFAgrup
     FROM EPagValorGeralCEFAgrup VGA
     INNER JOIN EPagValorGeralCEFAgrupVersao NVGA
             ON VGA.CdValorGeralCEFAGrup = NVGA.CdValorGeralCEFAGrup
     INNER JOIN EPagHistValorGeralCEFAgrup HVGA
             ON NVGA.CdValorGeralCEFAgrupVersao =
                HVGA.CdValorGeralCEFAgrupVersao
          WHERE NVGA.NuVersao = vNuVersao
            AND NVGA.CdValorGeralCEFAgrup = vCdValorGeralCefAgrup
            AND ((HVGA.NuAnoiniciovigencia < vNuAno OR
                 (HVGA.NuAnoiniciovigencia = vNuAno AND
                  HVGA.NuMesiniciovigencia <= vNuMes)) AND
                 (HVGA.NuAnoFimVigencia > vNuAno OR
                 (HVGA.NuAnoFimVigencia = vNuAno AND
                  HVGA.NuMesFimVigencia >= vNuMes) OR
                  HVGA.NuAnoFimVigencia IS NULL))
     ORDER BY NVGA.NuVersao DESC;

-- E Finalmente achar o valor do salario

   SELECT V.vlFixo
     INTO vValorSalario
     FROM EPagValorEspecCEFAgrup V
     WHERE V.CdHistValorGeralCEFAgrup = vCdHistValorGeralCEFAgrup
       AND V.NUNIVEL = vNuNivel
       AND V.NUREFERENCIA = vNuReferencia;

   RETURN vValorSalario;

   EXCEPTION

       WHEN NO_DATA_FOUND THEN

            RETURN 0;

       WHEN TOO_MANY_ROWS THEN

            RETURN vValorSalario;

END FRETORNAVALORSALARIO;

--
-- Retornar valores ja pagos em outros retroativos para o mesmo vinculo, folha e rubrica
--

FUNCTION FOUTROVALORPAGORETROATIVO(pCdVinculo number,
                                   pCdFolha number,
                                   pCdRubrica number,
                                   pCdPagRetroativo number)
  RETURN NUMBER IS

  vValorRetroativo NUMBER(13,2) :=0 ;

BEGIN

   SELECT SUM(EPR.VLRETROATIVO)
     INTO vValorRetroativo
     FROM EPAGRETROATIVOVINCULOFOLHA EPR
    WHERE EPR.CDVINCULO = pCdVinculo
      AND EPR.CDFOLHA = pCdFolha
      AND EPR.CDRUBRICA = pCdRubrica
      AND EPR.Cdpagretroativo = pCdPagRetroativo;

   IF SQL%NOTFOUND
     then
        RETURN 0;
   end if;
   if vValorRetroativo < 0.05
     then
       RETURN 0;
   end if;

   RETURN vValorRetroativo;

END FOUTROVALORPAGORETROATIVO;

--
-- Acertar o salario origem para calculo posterior se o valor estiver 0
--

procedure PACERTASALORIGEM is

vNuNivelOrigem char(2);
vNuReferenciaOrigem char(1);
vCdEstruturaCarreiraOrigem number;
vVlTabela number(13,2);

begin

 for f_sal in (select evf.anomes, evf.cdvinculo, evf.cdrubrica
                 from epagretroativovinculofolha evf
                where cdrubrica=8451
                  and vltabelaori=0
                order by evf.cdvinculo)
 loop
   begin
   select evr.nunivelorigem, evr.nureferenciaorigem, evr.cdestruturacarreiraorigem
     into vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
     from epagretroativovinculo evr
     where evr.cdvinculo = f_sal.cdvinculo
       and F_sal.Anomes BETWEEN to_char(evr.DTINICIO,'YYYYMM') AND to_char(evr.DTFIM,'YYYYMM')
       and rownum < 2;
   exception -- N?o achou um periodo entao tem que pegar o primeiro
     when no_data_found
       then
       select evr.nunivelorigem, evr.nureferenciaorigem, evr.cdestruturacarreiraorigem
         into vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
         from epagretroativovinculo evr
        where evr.cdvinculo = f_sal.cdvinculo
          and evr.DTINICIO = (select min(evr2.dtinicio) from epagretroativovinculo evr2
                                   where evr2.cdvinculo = f_sal.cdvinculo);

   end;
   vVlTabela :=  fretornavalorsalario(vNunivelOrigem, vNureferenciaorigem, SUBSTR(F_SAL.ANOMES,1,4),
                                       SUBSTR(F_SAL.ANOMES,5,2),vcdestruturacarreiraorigem , 1, 1);

   update epagretroativovinculofolha
     set  vltabelaori = vVlTabela
     where cdvinculo = f_sal.cdvinculo
       and cdrubrica = f_sal.cdrubrica
       and anomes    = f_sal.anomes
       and vltabelaori = 0;
   commit;
   end loop;
End PACERTASALORIGEM;
--
-- INSERIR A RUBRICA PARA OS VINCULOS SEM DIFERENCA DE SALARIO NO PERIODO
--
/*PROCEDURE PINCLUIRUBRICAFATOGERADOR (pTipoRetroativo NUMBER, pCdRubrica NUMBER, pCdPagRetroativo NUMBER) IS

vCount number := 0;

BEGIN

for f_vinc in (select vp.cdorgao, eh.cdvinculo, vp.cdfolhapagamento, vp.nuanomesreferencia, eh.vlpagamento
                  --from epagretroativovinculo evt
                  from epaghistoricorubricavinculo eh --on (eh.cdvinculo = evt.cdvinculo)
                  inner join vpagfolhapagamento vp on (vp.cdfolhapagamento = eh.cdfolhapagamento)
                       where cdrubricaagrupamento = pCdRubrica
                         and vp.nuanomesreferencia between '201405' and '201405'
                         and vp.flcalculodefinitivo = 'S'
                         and vp.cdtipocalculo=1
                         and vp.cdtipofolhaPAGAMENTO=2)

loop
     begin
     vCount := 0;
     select 1
      into vCount
      from epagretroativovinculofolha epf
            where epf.cdvinculo = f_vinc.cdvinculo
              and epf.cdfolha = f_vinc.cdfolhapagamento
              and epf.cdrubrica = pCdRubrica;
      exception
      when no_data_found
        then
          vCount := 0;
          INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                              ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,Cdpagretroativo)
          VALUES(f_vinc.cdorgao, f_vinc.cdvinculo, f_vinc.cdfolhapagamento, pCdRubrica,
                 f_vinc.nuanomesreferencia, f_vinc.vlpagamento, 0, 0, 0, pCdPagRetroativo );
          commit;

      --end if;
      end;
end loop;

END PINCLUIRUBRICAFATOGERADOR;*/
--
-- Incluir as rubricas definidas no processo da tabela EPAGRETROATIVOPROCESSO
--
PROCEDURE PINCLUIRUBRICAPROCESSO (pCdRubrica NUMBER, pAnoMesFim CHAR, pCdVinculo NUMBER) IS

--vCount number := 0;
--vAnoMesIni char(6);
--vCdOrgao number;
--vCdVinculo number;
--vCdFolha number;
--vAnoMes CHAR(6);
--vVlRecebido number(13,2);
--vVlOrigem number(13,2);
--vVlDestino number(13,2);
--vVlDiferenca number(13,2);
--vCdPagRetroativo number;
--vCdProcesso number;

BEGIN

INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA, ANOMES, VLRECEBIDO, VLTABELAORI, VLTABELADEST, VLDIFERENCA,
                                        CDPAGRETROATIVOPROCESSO, CDPAGRETROATIVO, VLOUTRORETROATIVO)

select vp.cdorgao, eh.cdvinculo, eh.cdfolhapagamento, 10724, vp.nuanomesreferencia,
           sum (case when eh.cdrubricaagrupamento in (10724,10279,33257,33263)
                 then vlpagamento else 0 end) as VLRECEBIDO,
           0 as VLTABELAORI,
           0 as VLTABELADEST,
           sum (case when eh.cdrubricaagrupamento = 8451
                 then vlpagamento * (epr.percentual/100) else 0 end) as VLDIFERENCA,
      epr.cdprocessoretroativo, epr.cdpagretroativo, 0
      from epaghistoricorubricavinculo eh --on (eh.cdvinculo = evt.cdvinculo)
      inner join epagretroativoprocesso epr on epr.cdvinculo = eh.cdvinculo
      inner join epagfolhapagamento vp on (vp.cdfolhapagamento = eh.cdfolhapagamento)
      where eh.cdrubricaagrupamento IN (8451,10724,10279,33257,33263)
        and vp.nuanomesreferencia between 200604 and 201406
        and vp.nuanomesreferencia >= to_number(to_char(epr.dtinicio,'YYYYMM'))
        and vp.nuanomesreferencia < (select max(epp.nuanoinicio * 100 + epp.numesinicio)
                                       from ebpcincorporacaoativo epp
                                       where epp.cdvinculo = epr.cdvinculo
                                         and epp.cdrubricaagrupamento = 10724)

        and vp.flcalculodefinitivo = 'S'
        and vp.cdtipocalculo = 1
        and vp.cdtipofolhaPAGAMENTO = 2
      group by vp.cdorgao, eh.cdvinculo, eh.cdfolhapagamento, vp.nuanomesreferencia, epr.cdprocessoretroativo, epr.cdpagretroativo
        having (sum (case when eh.cdrubricaagrupamento = 8451
                          then vlpagamento * (epr.percentual/100) else 0 end) -
                nvl(sum (case when eh.cdrubricaagrupamento in (10724,10279,33257,33263)
                     then vlpagamento else 0 end),0)) > 0.1;

/*for f_proc in (select *
                 from epagretroativoprocesso epr
                where epr.cdrubrica = pCdRubrica
                and   epr.cdvinculo = pcdvinculo)

loop

    vAnoMesIni := to_char(f_proc.dtinicio,'YYYYMM');

    vVlDiferenca := 0;

    select vp.cdorgao, eh.cdvinculo, eh.cdfolhapagamento, vp.nuanomesreferencia,
           sum (case when cdrubricaagrupamento in (10724,10279,33257,33263)
                 then vlpagamento else 0 end) as VLRECEBIDO,
           0 as VLTABELAORI,
           0 as VLTABELADEST,
           sum (case when cdrubricaagrupamento = 8451
                 then vlpagamento * (f_proc.percentual/100) else 0 end), -- VLDIFERENCA
           f_proc.cdprocessoretroativo,
           f_proc.cdpagretroativo
      into vCdOrgao, vCdVinculo, vCdFolha, vAnoMes, vVlRecebido, vVlOrigem, vVlDestino, vVlDiferenca,
           vCdProcesso, vCdPagRetroativo
      from epaghistoricorubricavinculo eh --on (eh.cdvinculo = evt.cdvinculo)
      inner join vpagfolhapagamento vp on (vp.cdfolhapagamento = eh.cdfolhapagamento)
      where cdrubricaagrupamento IN (8451,10724,10279,33257,33263)
        and vp.nuanomesreferencia between vAnoMesIni and pAnoMesFim
        and eh.cdvinculo = f_proc.cdvinculo
        and vp.flcalculodefinitivo = 'S'
        and vp.cdtipocalculo = 1
        and vp.cdtipofolhaPAGAMENTO = 2
      group by vp.cdorgao, eh.cdvinculo, eh.cdfolhapagamento, vp.nuanomesreferencia
        having (sum (case when cdrubricaagrupamento = 8451
                          then vlpagamento * (f_proc.percentual/100) else 0 end) -
                nvl(sum (case when cdrubricaagrupamento in (10724,10279,33257,33263)
                     then vlpagamento else 0 end),0)) > 0.5;

      if vVlDiferenca > 0
        then
          PINCLUIRETROATIVO (vCdOrgao, vCdVinculo, vCdFolha, pCdRubrica , vAnoMes, vVlRecebido, vVlDiferenca,
                             vCdProcesso, vCdPagRetroativo);
      end if;

\* INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                            ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,
                                            CDPAGRETROATIVOPROCESSO, CDPAGRETROATIVO)

   commit;
*\
end loop;*/

END PINCLUIRUBRICAPROCESSO;

--
-- Incluir as rubricas definidas no processo da tabela EPAGRETROATIVOPROCESSO
--
PROCEDURE PCALCULARUBRICAPROCESSO (pCdRubrica NUMBER, pCdPagRetroativo NUMBER, pCdVinculo NUMBER) IS

--vCount number := 0;
vAnoMesIni pls_integer;
--vCdOrgao number;
--vCdVinculo number;
--vCdFolha number;
vDia number;
vAnoMesFim pls_integer;
vVlRecebido number(13,2);
--vVlOrigem number(13,2);
--vVlDestino number(13,2);
vVlDiferenca number(13,2);
--vCdPagRetroativo number;
--vCdProcesso number;

BEGIN

for c_proc in (select eproc.cdvinculo, eproc.dtinicio, eproc.percentual
                 from epagretroativoprocesso eproc
                where cdpagretroativo = pCdPagRetroativo
                  and cdvinculo = CASE WHEN pCdVinculo is NOT NULL THEN pCdVinculo
                                       ELSE eproc.cdvinculo END)

loop
   vAnoMesIni := to_number(to_char(c_proc.dtinicio,'YYYYMM'));
   --vAnoMesFim := to_char(add_months(c_proc.dtimplantacao,-1), 'YYYYMM');

   for c_fol in (select ecp.cdfolhapagamento, vp.cdorgao, vp.nuanomesreferencia
                   from epagcapahistrubricavinculo ecp --on (eh.cdvinculo = evt.cdvinculo)
                  inner join epagfolhapagamento vp on (vp.cdfolhapagamento = ecp.cdfolhapagamento)
                  where vp.nuanomesreferencia between vAnoMesIni and vAnoMesFim
                    and ecp.cdvinculo = c_proc.cdvinculo
                    and vp.flcalculodefinitivo = 'S'
                    and vp.cdtipocalculo = 1
                    and vp.cdtipofolhaPAGAMENTO = 2)

    loop
       vVlRecebido := 0 ;
       -- Para o primeiro mes proporcionalizar
       vVlDiferenca := (1513.21 * c_proc.percentual / 100);

       if vAnoMesIni = c_fol.nuanomesreferencia and to_number(to_char(c_proc.dtinicio,'DD')) > 1
         then

          vDia := to_number(to_char(last_day(c_proc.dtinicio),'DD')) - to_number(to_char(c_proc.dtinicio,'DD')) + 1;

          if vDia < 30
            then

              vVlDiferenca := vVlDiferenca / 30 * vDia;

          end if;

       end if;

       begin
         select vlpagamento
           into vVlRecebido
           from epaghistoricorubricavinculo
          where cdvinculo = c_proc.cdvinculo
            and cdfolhapagamento = c_fol.cdfolhapagamento
            and cdrubricaagrupamento = pCdRubrica;

          INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                                   ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,Cdpagretroativo)
          VALUES(c_fol.cdorgao, c_proc.cdvinculo, c_fol.cdfolhapagamento, pCdRubrica,
                 c_fol.nuanomesreferencia, vVlRecebido, 0, 0, vVlDiferenca, pCdPagRetroativo );
          commit;

       exception
         when no_data_found

         then
          INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                                   ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,Cdpagretroativo)
          VALUES(c_fol.cdorgao, c_proc.cdvinculo, c_fol.cdfolhapagamento, pCdRubrica,
                 c_fol.nuanomesreferencia, 0, 0, 0, vVlDiferenca, pCdPagRetroativo );
          commit;
        end;

    end loop;

end loop;

/*for f_proc in (select *
                 from epagretroativoprocesso epr
                where epr.cdrubrica = pCdRubrica
                and   epr.cdvinculo = pcdvinculo)

loop

    vAnoMesIni := to_char(f_proc.dtinicio,'YYYYMM');

    vVlDiferenca := 0;

    select vp.cdorgao, eh.cdvinculo, eh.cdfolhapagamento, vp.nuanomesreferencia,
           sum (case when cdrubricaagrupamento in (10724,10279,33257,33263)
                 then vlpagamento else 0 end) as VLRECEBIDO,
           0 as VLTABELAORI,
           0 as VLTABELADEST,
           sum (case when cdrubricaagrupamento = 8451
                 then vlpagamento * (f_proc.percentual/100) else 0 end), -- VLDIFERENCA
           f_proc.cdprocessoretroativo,
           f_proc.cdpagretroativo
      into vCdOrgao, vCdVinculo, vCdFolha, vAnoMes, vVlRecebido, vVlOrigem, vVlDestino, vVlDiferenca,
           vCdProcesso, vCdPagRetroativo
      from epaghistoricorubricavinculo eh --on (eh.cdvinculo = evt.cdvinculo)
      inner join vpagfolhapagamento vp on (vp.cdfolhapagamento = eh.cdfolhapagamento)
      where cdrubricaagrupamento IN (8451,10724,10279,33257,33263)
        and vp.nuanomesreferencia between vAnoMesIni and pAnoMesFim
        and eh.cdvinculo = f_proc.cdvinculo
        and vp.flcalculodefinitivo = 'S'
        and vp.cdtipocalculo = 1
        and vp.cdtipofolhaPAGAMENTO = 2
      group by vp.cdorgao, eh.cdvinculo, eh.cdfolhapagamento, vp.nuanomesreferencia
        having (sum (case when cdrubricaagrupamento = 8451
                          then vlpagamento * (f_proc.percentual/100) else 0 end) -
                nvl(sum (case when cdrubricaagrupamento in (10724,10279,33257,33263)
                     then vlpagamento else 0 end),0)) > 0.5;

      if vVlDiferenca > 0
        then
          PINCLUIRETROATIVO (vCdOrgao, vCdVinculo, vCdFolha, pCdRubrica , vAnoMes, vVlRecebido, vVlDiferenca,
                             vCdProcesso, vCdPagRetroativo);
      end if;

\* INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                            ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,
                                            CDPAGRETROATIVOPROCESSO, CDPAGRETROATIVO)

   commit;
*\
end loop;*/

END PCALCULARUBRICAPROCESSO;

--
-- Procedure para calcular o retroativo dos vinculos que constam na tabele EPAGRETROATIVOVINCULO
-- conforme progressao implementada no SIGRH referente ao periodo de 2007 a 2012.
-- Esta procedure calcula as diferen?as da rubrica 01-0001, que ? o provento que tem influencia
-- direta na progress?o e tamb?m para as rubricas de produtividade (benef?cios) que tem tabela
-- pr?pria para c?lculo. Com base neste recalculo ? que ser?o feitos os c?lculos das demais
-- rubricas que s?o influenciadas pela diferen?a. ex: tri?nios.
-- Usa os parametros pDtIni = Data inicial do c?lculo, que ? apurado por ano por quest?o de
-- e deve ser sempre o primeiro dia do ano a ser calculado, para o calculo incrementar os
-- 12 meses do ano; pCdVinculo = informar se calcular para apenas um vinculo;
-- pNuRubrica = numero da rubrica a ser recalculada; pTipoRubrica = tipo da rubrica;
-- pAgrupamento = N?mero do agrupamento
--
PROCEDURE PCALCULOPROGRESSAORETROATIVO (pDtIni DATE, pCdVinculo NUMBER, pNuRubrica number,
                                        pTipoRubrica number, pAgrupamento number,
                                        pCdPagRetroativo number)  IS

vAnoMes                     string(6) := To_Char(pDtIni,'YYYYMM');
--vAnoMes                     string(6) := pAno || '01';
vValorDiferenca             number(13,2);
vValorProgressao            number(13,2);
vVlFixo                     number(13,2);
--vVlOrigem                   number(13,2);
vVlProdutividade            number(13,2);
vCdRubricaAgrupamento       number;
vCdRubrica1001              number;
vVl1001                     number(13,2);
vVlTabela                   number(13,2);
vCdTipoAtipratFaz           number;
vAno                        string(4);
vMes                        string(2);
--vCount                      number;
vNuNivelOrigem              char(2);
vNuNivelDestino             char(2);
vNuReferenciaOrigem         char(1);
vNuReferenciaDestino        char(1);
vCdEstruturaCarreiraOrigem  number;
vCdEstruturaCarreiraDestino number;
vVlRetroativo number(13,2) :=0;

vAnoMesF string(6) := To_Char(LAST_DAY(ADD_MONTHS(pDtIni,11)),'YYYYMM');
--vAnoMesF                    string(6) := pAno || '12';
vCdVinculo                  number;
vValorTabelaOri             number(13,2); -- Valor da tabela original usado para ver se teve proporcionalidade

Cursor cProgressao is

   SELECT distinct(ETMD.Cdvinculo) from EPAGRETROATIVOVINCULO ETMD
    WHERE ETMD.CDVINCULO =
            CASE WHEN pCdVinculo IS NOT NULL THEN pCdVinculo
                 ELSE ETMD.CDVINCULO END
      AND ETMD.CDPAGRETROATIVO = pCdPagRetroativo;

BEGIN

   -- Busca o c?digo da rubrica
   SELECT R.CdRubricaAgrupamento
     INTO vCdRubricaAgrupamento
     FROM vPagRubricaAgrupamento R
    WHERE R.nurubrica = pNuRubrica
      AND r.cdtiporubrica = pTipoRubrica
      AND r.cdagrupamento = pAgrupamento;

    -- Codigo da rubrica 1001
    SELECT R.CdRubricaAgrupamento
     INTO vCdRubrica1001
     FROM vPagRubricaAgrupamento R
    WHERE R.nurubrica = 1
      AND r.cdtiporubrica = 1
      AND r.cdagrupamento = pAgrupamento;

   -- Busca c?digo da atividade fazendaria para a rubricas de produtividade
    SELECT evp.cdtipogratativfazendaria
      INTO vCdTipoAtipratFaz
      FROM epageventopagagrup eva
     INNER JOIN epaghisteventopagagrup evp on (evp.cdeventopagagrup = eva.cdeventopagagrup)
     where eva.cdrubricaagrupamento = vCdRubricaAgrupamento
     and rownum=1;

   -- Exclui registros antigos
   DELETE EPAGRETROATIVOVINCULOFOLHA ETR
    WHERE ETR.CDRUBRICA = vCdRubricaAgrupamento
      AND ETR.ANOMES BETWEEN VANOMES AND VANOMESF
      AND ETR.CDVINCULO = CASE WHEN pCdVinculo IS NOT NULL THEN pCdVinculo
                               ELSE ETR.CDVINCULO END
      AND ETR.CDPAGRETROATIVO = pCdPagRetroativo ;

   COMMIT;

 BEGIN

  FOR I IN cProgressao LOOP
      -- Procurar folhas de pagamento
     vAnoMes  := To_Char(pDtIni,'YYYYMM');
     vAno     := To_Char(pDtIni,'YYYY');
     vMes     := To_Char(pDtIni,'MM');

     SELECT NuNivelOrigem, NuReferenciaOrigem, CdEstruturaCarreiraOrigem
            INTO vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
            FROM EPAGRETROATIVOVINCULO
           WHERE CDVINCULO =  I.CDVINCULO
             AND DTINICIO = (SELECT MIN(DTINICIO)
                               FROM EPAGRETROATIVOVINCULO
                              WHERE CDVINCULO = I.CDVINCULO);

     BEGIN
      FOR f_rec IN (

      Select vp.cdorgao, vp.cdfolhapagamento, vp.nuanomesreferencia, eh.vlpagamento, vp.dtcalculo
--             et.nunivelorigem, et.nuniveldestino, et.nureferenciaorigem,
--             et.nureferenciadestino, et.cdestruturacarreiraorigem, et.cdestruturacarreiradestino
           from epagfolhapagamento vp
           inner join epaghistoricorubricavinculo eh on (eh.cdfolhapagamento=vp.cdfolhapagamento)
--           inner join EPAGRETROATIVOVINCULO et on (et.cdvinculo = eh.cdvinculo)
           where vp.cdorgao = vp.cdorgao
            and vp.nuanomesreferencia between vAnoMes and vAnoMesF
            and vp.flcalculodefinitivo = 'S'
            and eh.cdvinculo = I.CDVINCULO
--            and vp.dtcalculo between et.dtinicio and et.dtfim
            and eh.cdrubricaagrupamento = vCdRubricaAgrupamento order by vp.nuanomesreferencia
            )

      LOOP
          vAnoMes := To_Char(f_rec.DtCalculo,'YYYYMM');
          vAno    := Substr(vAnoMes,1,4);
          vMes    := Substr(vAnoMes,5,2);

          FOR F_PROG IN (SELECT ET.NUNIVELORIGEM, ET.NUNIVELDESTINO, ET.NUREFERENCIAORIGEM,
                                ET.NUREFERENCIADESTINO,ET.CDESTRUTURACARREIRAORIGEM,
                                ET.CDESTRUTURACARREIRADESTINO, ET.DTINICIO, ET.DTFIM
                           FROM EPAGRETROATIVOVINCULO ET
                          WHERE ET.CDVINCULO = I.CDVINCULO
                            AND ET.CDPAGRETROATIVO = pCdPagRetroativo
                          ORDER BY ET.DTINICIO desc)

          LOOP

            IF F_REC.DTCALCULO BETWEEN F_PROG.DTINICIO AND F_PROG.DTFIM
              THEN
               vNuNivelDestino := f_prog.nuniveldestino;
               vNuReferenciaDestino := f_prog.nureferenciadestino;
               vCdEstruturaCarreiraDestino := f_prog.cdestruturacarreiradestino;
               EXIT;
              ELSE
               -- Se n?o achar na tabela a para os anos anteriores a progressao coloca todos como origem
               vNuNivelDestino := f_prog.nunivelorigem;
               vNuReferenciaDestino := f_prog.nureferenciaorigem;
               vCdEstruturaCarreiraDestino := f_prog.cdestruturacarreiraorigem;
            END IF;

          END LOOP;

          if pNuRubrica <> 1
            then
              /*BEGIN

              SELECT 1
                INTO VCOUNT
                FROM EPAGHISTORICORUBRICAVINCULO EPH1
               WHERE EPH1.CDRUBRICAAGRUPAMENTO = vCdRubrica1001
                 AND EPH1.CDVINCULO = I.CDVINCULO
                 AND EPH1.CDFOLHAPAGAMENTO = F_REC.CDFOLHAPAGAMENTO;

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  CONTINUE;
              END;*/

              BEGIN
              -- Busca valores do 1001 para proporcionalizar se for o caso
              -- e tamb?m se ? necess?rio calcular. S? calcula para quem tem a 1001
              SELECT VLRECEBIDO, VLTABELAORI
                INTO vVl1001, vVlTabela
                FROM EPAGRETROATIVOVINCULOFOLHA ETMR
               WHERE ETMR.CDVINCULO = I.CDVINCULO
                 AND ETMR.CDFOLHA = F_REC.CDFOLHAPAGAMENTO
                 AND ETMR.CDRUBRICA = vCdRubrica1001
                 AND ETMR.Cdpagretroativo = pCdPagRetroativo;

              if vVlTabela = 0
                then
                  vVlTabela := vVl1001;
              end if;
              EXCEPTION

                WHEN NO_DATA_FOUND THEN
                  begin
                  SELECT EPH1.VLPAGAMENTO
                    INTO vVl1001
                    FROM EPAGHISTORICORUBRICAVINCULO EPH1
                   WHERE EPH1.CDRUBRICAAGRUPAMENTO = vCdRubrica1001
                     AND EPH1.CDVINCULO = I.CDVINCULO
                     AND EPH1.CDFOLHAPAGAMENTO = F_REC.CDFOLHAPAGAMENTO;
                  vVlTabela := vVl1001;

                  exception
                    when no_data_found
                      then
                        vVl1001 := 1;
                        vVlTabela := 1;
                  end;
              END;

          end if;
          --
          -- Buscar o valor da tabela de produtividade PAGO para comparar com o RECEBIDO
          -- e proporcionalizar se for o caso
          --
          vVlProdutividade := FRetornaValorFixoGrat(I.CDVINCULO, vCDESTRUTURACARREIRAORIGEM,
                                                  vNuNivelOrigem, vNureferenciaorigem,
                                                  vCdTipoAtipratFaz, vAnoMes, F_REC.Cdfolhapagamento,
                                                  pNuRubrica, F_REC.Cdorgao);

          CASE
             -- Rubrica 01-0001
             WHEN pNuRubrica = 1 THEN

             -- Busca valor tabela origem
                  vValorTabelaOri := fretornavalorsalario(vNunivelOrigem, vNureferenciaorigem,
                                     vAno, vMes,
                                     vcdestruturacarreiraorigem , pAgrupamento, 1);
             -- Busca valor tabela destino
                  vValorProgressao := fretornavalorsalario(vnuniveldestino, vnureferenciadestino,
                                      vAno, vMes,
                                      vcdestruturacarreiradestino, pAgrupamento, 1);

             -- Se encontrou diferen?a entre o valor das tabelas
                 vValorDiferenca := vValorProgressao;

             WHEN pNuRubrica = 129
               THEN
                 -- Verificar valor referente a tabela de origem antes da progressao
                 -- para casos de Contador e Auditor que recebem a 10 niveis a mais da tabela.
                 -- Busca o valor da tabela de origem
                 -- Auditor e contador tem condi??o especial
                 IF vCdEstruturaCarreiraDestino in (64621, 64624)
                   THEN
                    vNuNivelDestino := vNUNIVELDESTINO + 1; -- TESTE PARA UM VINCULO
                    vVlFixo := FRetornaValorFixoGrat(I.CDVINCULO, vCDESTRUTURACARREIRADESTINO,
                                                  vNUNIVELDESTINO, vNureferenciadestino,
                                                  vCdTipoAtipratFaz, vAnoMes, F_REC.Cdfolhapagamento,
                                                  pNuRubrica, F_REC.Cdorgao);
                 else
                    -- Sen?o procura o nivel destino + 1
                    vVlFixo := FRetornaValorFixoGrat(I.CDVINCULO, vCDESTRUTURACARREIRADESTINO,
                                                  vNUNIVELDESTINO, vNureferenciadestino,
                                                  vCdTipoAtipratFaz, vAnoMes, F_REC.CDFOLHAPAGAMENTO,
                                                  pNuRubrica, F_REC.Cdorgao);
                 end if;

                /* vNuNivelOrigem := vNUNIVELORIGEM + 1; */

             -- A rubrica 01-0445 que tamb?m ? paga por nivel referencia e os parametros est?o ligados a
             -- Gratifica??o Atividade de COntrole Interno.
             WHEN pNuRubrica in (445,446,439,456,467,483,484,560,561,563,564)
               THEN
                 vVlFixo := FRetornaValorFixoGrat(I.CDVINCULO, vCDESTRUTURACARREIRADESTINO,
                                                  vNUNIVELDESTINO, vNureferenciadestino,
                                                  vCdTipoAtipratFaz, vAnoMes, F_REC.CDFOLHAPAGAMENTO,
                                                  pNuRubrica, F_REC.Cdorgao);

          END CASE;

          --
          -- Para Retroatio 3 procurar se ja foi calculado no retroativo 4 em processo de pagamento
          --
          IF pCdPagRetroativo = 3
           then
             vVlRetroativo := NVL(FOUTROVALORPAGORETROATIVO( i.CdVinculo, f_rec.cdfolhapagamento,
                                                         vCdRubricaAgrupamento, 4),0);

         END IF;

          IF  pNuRubrica = 1 THEN

              IF vValorTabelaOri < vValorProgressao and f_rec.vlpagamento <= vValorTabelaOri
                    THEN vValorDiferenca := vValorProgressao * ( f_rec.vlpagamento / vValorTabelaOri);
              END IF;

              INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                              ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,
                                              CDPAGRETROATIVO, VLOUTRORETROATIVO)
                    VALUES(F_REC.Cdorgao, I.CDVINCULO,F_REC.CDFOLHAPAGAMENTO,VCDRUBRICAAGRUPAMENTO,
                           F_REC.NUANOMESREFERENCIA,F_REC.VLPAGAMENTO,
                           vValorTabelaOri, vValorProgressao, vValorDiferenca, pCdPagRetroativo,
                           NVL(vVlRetroativo,0));

                --    PRECALCULARUBRICAS(vCdRubricaAgrupamento, F_REC.CDFOLHAPAGAMENTO);

              /*ELSE
                    INSERT INTO EPAGRETROATIVOVINCULOFOLHA
                    VALUES(F_REC.Cdorgao, I.CDVINCULO,F_REC.CDFOLHAPAGAMENTO,vcdrubricaagrupamento,
                          F_REC.NUANOMESREFERENCIA,F_REC.VLPAGAMENTO,
                          vValorTabelaOri, vValorProgressao, vValorDiferenca);
              END IF;
              */
          ELSE

            vValorProgressao := vVlFixo;
            -- Proporcionalizar
            if F_REC.VlPagamento <> 0 and vVlProdutividade <> 0
                then
                if (F_REC.VLPAGAMENTO / vVlProdutividade) < 1
                   then vVlFixo := vVlFixo * (F_REC.VLPAGAMENTO / vVlProdutividade);
                end if;
             end if;
             -- Se o valor fixo for ZERO ou o valor calculado < que o recebido for?a o valor do pagamento.
             if vVlFixo = 0 or (vVlFixo < F_REC.VLPAGAMENTO) or vVlFixo is null
               then
                 vVlFixo := F_REC.VLPAGAMENTO;
             end if;

             INSERT INTO EPAGRETROATIVOVINCULOFOLHA
             (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                              ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,
                                              CDPAGRETROATIVO, VLOUTRORETROATIVO)
                  VALUES(F_REC.Cdorgao, I.CDVINCULO,F_REC.CDFOLHAPAGAMENTO,VCDRUBRICAAGRUPAMENTO,
                         F_REC.NUANOMESREFERENCIA,F_REC.VLPAGAMENTO,
                         vVlProdutividade, vValorProgressao, vVlFixo, pCdPagRetroativo, NVL(vVlRetroativo,0));
          END IF;

          COMMIT;

          vAnoMes := To_Char(ADD_MONTHS(f_rec.DtCalculo,1),'YYYYMM');
          vAno    := Substr(vAnoMes,1,4);
          vMes    := Substr(vAnoMes,5,2);
      END LOOP;
      vCdVinculo := i.cdvinculo;
     END;
  END LOOP;

END;

END PCALCULOPROGRESSAORETROATIVO;

PROCEDURE PVALOROUTRARUBRICA (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                              pCdRubrica NUMBER) IS

vValor number(15,2);

begin

for f_vinc in (select evt.cdfolha, evt.cdvinculo, evt.cdrubrica
                  from epagretroativovinculofolha evt
                         where evt.cdpagretroativo = 7
                           and evt.cdrubrica = 8451)

loop
          BEGIN
          vValor := 0;

          select SUM(hrv.vlpagamento)
            INTO vValor
            FROM EPAGHISTORICORUBRICAVINCULO HRV
             where HRV.cdvinculo = f_vinc.cdvinculo
               and HRV.CDFOLHAPAGAMENTO = F_VINC.CDFOLHA
               AND HRV.CDRUBRICAAGRUPAMENTO = pCdRubrica;

          if vValor <> 0
             then
             update epagretroativovinculofolha evt
                set evt.vloutroretroativo = vValor
              where evt.cdvinculo = f_vinc.cdvinculo
                and evt.CDFOLHA = F_VINC.CDFOLHA
                and evt.cdrubrica = f_vinc.cdrubrica;

          end if;
          commit;

          exception
           when no_data_found
             then
               vValor := 0;

           when others
              then
                vValor := 0;
          END;
          /*SELECT NuNivelOrigem, NuReferenciaOrigem, CdEstruturaCarreiraOrigem
            INTO vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
            FROM EPAGRETROATIVOVINCULO
           WHERE CDVINCULO =  f_vinc.CDVINCULO
             AND DTINICIO = (SELECT MIN(DTINICIO)
                               FROM EPAGRETROATIVOVINCULO
                              WHERE CDVINCULO = f_vinc.CDVINCULO);   */

          -- Busca valor tabela origem

end loop;

end;

PROCEDURE PCALCULARUBINDICE (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                             pCdRubrica NUMBER) IS

vValor number(15,2);

begin

for f_vinc in (select evt.cdfolha, evt.cdorgao, evt.cdvinculo, evt.anomes, evt.vlindicecorrecao
                  from epagretroativovinculofolha evt
                         where evt.cdpagretroativo = 7
                           and evt.cdrubrica = 8451
                           and evt.cdvinculo = case when pcdvinculo is not null then pcdvinculo
                                               else evt.cdvinculo end)

loop
          BEGIN
          vValor := 0;

          select SUM(hrv.vlpagamento)
            INTO vValor
            FROM EPAGHISTORICORUBRICAVINCULO HRV
             where HRV.cdvinculo = f_vinc.cdvinculo
               and HRV.CDFOLHAPAGAMENTO = F_VINC.CDFOLHA
               AND HRV.CDRUBRICAAGRUPAMENTO = pCdRubrica;

          if vValor <> 0
             then
             PINCLUIRETROATIVO (F_VINC.CDORGAO, F_VINC.CdVinculo, F_VINC.CdFolha,
                                pCdRubrica, F_VINC.AnoMes, vValor, (vValor * f_vinc.vlindicecorrecao),
                                7777, 7, 0);

             commit;

          end if;

          exception
           when no_data_found
             then
               vValor := 0;

           when others
              then
                vValor := 0;
          END;

end loop;

end;
--
-- No mes de Dezembro de 2014, gerar a rubrica 01-0023 (13. salario) correspondente a soma das diferencas do mes.
--
PROCEDURE PCALCULARUB13 (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                         pCdRubrica NUMBER) IS

vValor number(15,2);
vValorRec number(15,2);
vSoma     number(15,2);

begin

for f_vinc in (select evt.cdfolha, evt.cdorgao, evt.anomes, evt.cdvinculo
                  from epagretroativovinculofolha evt
                         where evt.cdpagretroativo = 7
                           and evt.cdrubrica = 8451
                           and evt.anomes = '201412'
                           and evt.vlretroativo>0)

loop
          BEGIN
          vValor := 0;
          vValorRec := 0;

          select SUM(evt.vlretroativo), SUM(evt.vldiferenca)
            INTO vValor, vSoma
            FROM epagretroativovinculofolha evt
             where evt.cdvinculo = f_vinc.cdvinculo
               and evt.CDFOLHA = F_VINC.CDFOLHA;

          select SUM(hrv.vlpagamento)
            INTO vValorRec
            FROM epaghistoricorubricavinculo hrv
            inner join epagfolhapagamento fp on hrv.cdfolhapagamento = fp.cdfolhapagamento
                                             and fp.nuanomesreferencia = '201411'
                                             and fp.cdtipofolhapagamento = 105
                                             and fp.cdtipocalculo = 1
                                             and fp.flcalculodefinitivo = 'S'
           where hrv.cdvinculo = f_vinc.cdvinculo
             and hrv.cdrubricaagrupamento = pCdRubrica;

          if vValorRec <> 0
             then
             PINCLUIRETROATIVO (F_VINC.CDORGAO, F_VINC.CdVinculo, F_VINC.CdFolha,
                                pCdRubrica, F_VINC.AnoMes, vValorRec, (vValorRec + vValor),
                                7777, 7, 0);

             commit;

          end if;

          exception
           when no_data_found
             then
               vValor := 0;

           when others
              then
                vValor := 0;
          END;

end loop;

end;

-- No mes de Janeiro de 2015, gerar a rubrica 01-0056 (gratif. de ferias) correspondente
-- a soma das diferencas do mes dividido por 3.

PROCEDURE PCALCULAFERIAS(pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER,
                         pCdRubrica NUMBER) IS

vValor number(15,2);
vValorRec number(15,2);
vSoma     number(15,2);

begin

for f_vinc in (select evt.cdfolha, evt.cdorgao, evt.anomes, evt.cdvinculo
                  from epagretroativovinculofolha evt
                         where evt.cdpagretroativo = 7
                           and evt.cdrubrica = 8451
                           and evt.anomes = '201501'
                           and evt.vlretroativo>0)

loop
          BEGIN
          vValor := 0;
          vValorRec := 0;

          select SUM(evt.vlretroativo/3), SUM(evt.vldiferenca)
            INTO vValor, vSoma
            FROM epagretroativovinculofolha evt
             where evt.cdvinculo = f_vinc.cdvinculo
               and evt.CDFOLHA = F_VINC.CDFOLHA;

          select SUM(hrv.vlpagamento)
            INTO vValorRec
            FROM epaghistoricorubricavinculo hrv
           where hrv.cdvinculo = f_vinc.cdvinculo
             and hrv.cdrubricaagrupamento = pCdRubrica
             and hrv.cdfolhapagamento = f_vinc.cdfolha;

          if vValorRec <> 0
             then
             PINCLUIRETROATIVO (F_VINC.CDORGAO, F_VINC.CdVinculo, F_VINC.CdFolha,
                                pCdRubrica, F_VINC.AnoMes, vValorRec, (vValorRec + vValor),
                                7777, 7, 0);

             commit;

          end if;

          exception
           when no_data_found
             then
               vValor := 0;

           when others
              then
                vValor := 0;
          END;

end loop;

end;

PROCEDURE PINCLUI1001 (pCdPagRetroativo NUMBER, pCdVinculo NUMBER, pAgrupamento NUMBER) IS

vCount    number := 0;
vCdRubrica1001 number;
vValorTabelaOri number(13,2);
vValorProgressao number(13,2);
vValorDiferenca number(13,2);
vValorRetroativo number(13,2) := 0;
--vNuNivelOrigem              char(2);
--vNuReferenciaOrigem         char(1);
--vCdEstruturaCarreiraOrigem  number;

BEGIN

SELECT R.CdRubricaAgrupamento
     INTO vCdRubrica1001
     FROM vPagRubricaAgrupamento R
    WHERE R.nurubrica = 1
      AND r.cdtiporubrica = 1
      AND r.cdagrupamento = pAgrupamento;

for f_vinc in (select vp.cdorgao, evt.cdvinculo, vp.cdfolhapagamento, vp.nuanomesreferencia,
                      eh.vlpagamento, vp.nuanoreferencia, vp.numesreferencia, evt.NuNivelOrigem,
                      evt.NuNivelDestino, evt.NuReferenciaOrigem, evt.NuReferenciaDestino,
                      evt.CdEstruturaCarreiraOrigem, evt.CdEstruturaCarreiraDestino,
                      vp.dtcalculo
                  from epagretroativovinculo evt
                  inner join epaghistoricorubricavinculo eh on (eh.cdvinculo = evt.cdvinculo)
                  inner join epagfolhapagamento vp on (vp.cdfolhapagamento = eh.cdfolhapagamento)
                       where cdrubricaagrupamento = vCdRubrica1001
                         and vp.nuanomesreferencia between to_number(to_char(evt.dtinicio,'YYYYMM')) and to_number(to_char(evt.dtfim,'YYYYMM'))
                         and vp.flcalculodefinitivo = 'S'
                         and vp.cdtipocalculo=1
                         and vp.cdtipofolhapagamento = 2
                         and evt.cdpagretroativo = pCdPagRetroativo
                         and evt.cdvinculo = CASE WHEN pCdVinculo IS NOT NULL
                                                  THEN pCdVinculo
                                                  ELSE evt.CDVINCULO END
                         and vp.cdtipofolhaPAGAMENTO=2
                         and evt.dtfim = to_date('30/09/2015', 'DD/MM/YYYY'))

loop
     begin
     vCount := 0;
     select 1
      into vCount
      from epagretroativovinculofolha epf
            where epf.cdvinculo = f_vinc.cdvinculo
              and epf.cdfolha = f_vinc.cdfolhapagamento
              and epf.cdrubrica = vCdRubrica1001;
      exception
      when no_data_found
        then

          vCount := 0;

         /* select A.Nuniveldestino, A.NUREFERENCIADESTINO, A.CDESTRUTURACARREIRADESTINO
            INTO vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
            from (select mcef.cdestruturacarreiradestino,
                         mn.nuniveldestino,
                         mn.nureferenciadestino
                    from emovmovcargoefetivo mcef
                    inner join emovmovcargoefetivovinc mcefv
                            on mcefv.cdmovcargoefetivo = mcef.cdmovcargoefetivo
                    inner join emovmovcargoefetivonivel mn
                            on mn.cdmovcargoefetivo = mcef.cdmovcargoefetivo
                    where mcefv.cdvinculo = f_vinc.cdvinculo
                      and mcef.dtpublicacao <= f_vinc.dtcalculo
                      and mcef.flanulado = 'N'
                      order by dtmovimentacao desc) A
             where rownum < 2;
             */

          /*SELECT NuNivelOrigem, NuReferenciaOrigem, CdEstruturaCarreiraOrigem
            INTO vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
            FROM EPAGRETROATIVOVINCULO
           WHERE CDVINCULO =  f_vinc.CDVINCULO
             AND DTINICIO = (SELECT MIN(DTINICIO)
                               FROM EPAGRETROATIVOVINCULO
                              WHERE CDVINCULO = f_vinc.CDVINCULO);   */

          -- Busca valor tabela origem
          vValorTabelaOri := fretornavalorsalario(f_vinc.NuNivelOrigem, f_vinc.Nureferenciaorigem,
                                                  f_vinc.NuAnoReferencia, f_vinc.NuMesReferencia,
                                                  f_vinc.Cdestruturacarreiraorigem , pAgrupamento, 1);

          -- Busca valor tabela destino
          vValorProgressao := fretornavalorsalario(f_vinc.Nuniveldestino, f_vinc.Nureferenciadestino,
                                                   f_vinc.NuAnoReferencia, f_vinc.NuMesReferencia,
                                                   f_vinc.Cdestruturacarreiradestino, pAgrupamento, 1);

          vValorDiferenca := vValorProgressao;

         /* if vValorTabelaOri = 0
             then
              vValorTabelaOri := f_vinc.vlpagamento;
          end if;*/

          IF vValorTabelaOri <= vValorProgressao and f_vinc.vlpagamento <= vValorTabelaOri
             THEN vValorDiferenca := vValorProgressao * ( f_vinc.vlpagamento / vValorTabelaOri);
          END IF;
          --
          -- Verificar se tem no processo retroativo 4 e ja recebeu diferenca.
          --
          if pCdPagRetroativo = 3
            then
             begin
               select sum(vlretroativo)
                  into vValorRetroativo
                  from epagretroativovinculofolha epr2
                 where cdpagretroativo = 4
                   and cdrubrica = vCdRubrica1001
                   and vlretroativo > 0
                   and epr2.cdvinculo = f_vinc.cdvinculo
                   and epr2.cdfolha = f_vinc.cdfolhapagamento
                   and epr2.cdorgao = f_vinc.cdorgao;

                IF SQL%NOTFOUND
                  then
                    vValorRetroativo := 0;
                end if;

                END;

          end if;
          -- Se encontrou diferen?a entre o valor das tabelas
--          vValorDiferenca := vValorProgressao;
          INSERT INTO EPAGRETROATIVOVINCULOFOLHA
                (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                 ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA, CDPAGRETROATIVOPROCESSO,
                 CDPAGRETROATIVO, VLOUTRORETROATIVO)
          VALUES(f_vinc.cdorgao, f_vinc.cdvinculo, f_vinc.cdfolhapagamento, vCdRubrica1001,
                 f_vinc.nuanomesreferencia, f_vinc.vlpagamento, vValorTabelaOri, vValorProgressao,
                 vValorDiferenca, 7777, pCdPagRetroativo, vValorRetroativo );
          commit;

      --end if;
      end;
end loop;

END PINCLUI1001;

PROCEDURE PCALCULO1001 (pAnoMesIni char, pAnoMesFim char, pCdVinculo NUMBER, pAgrupamento number)  IS

--vAnoMes                     string(6) := To_Char(pDtIni,'YYYYMM');
--vAnoMes                     string(6) := pAno || '01';
vValorDiferenca             number(13,2);
vValorProgressao            number(13,2);
--vVlFixo                     number(13,2);
--vVlOrigem                   number(13,2);
--vVlProdutividade            number(13,2);
--vCdRubricaAgrupamento       number;
vCdRubrica1001              number;
--vVl1001                     number(13,2);
--vVlTabela                   number(13,2);
--vCdTipoAtipratFaz           number;
vAno                        INTEGER;
vMes                        INTEGER;
--vCount                      number;
vNuNivelOrigem              char(2);
vNuNivelDestino             char(2);
vNuReferenciaOrigem         char(1);
vNuReferenciaDestino        char(1);
vCdEstruturaCarreiraOrigem  number;
vCdEstruturaCarreiraDestino number;

--vAnoMesF string(6) := To_Char(LAST_DAY(ADD_MONTHS(pDtIni,11)),'YYYYMM');
--vAnoMesF                    string(6) := pAno || '12';
--vCdVinculo                  number;
vValorTabelaOri             number(13,2); -- Valor da tabela original usado para ver se teve proporcionalidade

BEGIN

    -- Codigo da rubrica 1001
   SELECT R.CdRubricaAgrupamento
     INTO vCdRubrica1001
     FROM vPagRubricaAgrupamento R
    WHERE R.nurubrica = 1
      AND r.cdtiporubrica = 1
      AND r.cdagrupamento = pAgrupamento;

   FOR F_1001 IN (

      Select eprf.cdfolha, eprf.anomes, eprf.cdvinculo, eprf.cdrubrica, eprf.vlrecebido
        from EPAGRETROATIVOVINCULOFOLHA EPRF
       where EPRF.ANOMES between pAnoMesIni and pAnoMesFim
         and EPRF.CDRUBRICA = vCdRubrica1001
         and eprf.vldiferenca = 0
         AND EPRF.CDVINCULO = CASE WHEN pCdVinculo IS NOT NULL THEN pCdVinculo
                               ELSE EPRF.CDVINCULO END
            )

      LOOP
          begin
          SELECT NuNivelOrigem, NuReferenciaOrigem, CdEstruturaCarreiraOrigem
            INTO vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
            FROM EPAGRETROATIVOVINCULO
           WHERE CDVINCULO =  f_1001.CDVINCULO
             AND DTINICIO = (SELECT MIN(DTINICIO)
                               FROM EPAGRETROATIVOVINCULO
                              WHERE CDVINCULO = f_1001.CDVINCULO);

          exception
            when no_data_found
              then
              delete EPAGRETROATIVOVINCULOFOLHA eprtf
               where eprtf.cdvinculo = f_1001.cdvinculo
                 and eprtf.cdfolha   = f_1001.cdfolha
                 and eprtf.cdrubrica = f_1001.cdrubrica;
              commit;
              continue;
          end;

          BEGIN
          SELECT ET.NUNIVELDESTINO, ET.NUREFERENCIADESTINO, ET.CDESTRUTURACARREIRADESTINO
            INTO vNuNivelDestino, vNuReferenciaDestino, vCdEstruturaCarreiraDestino
            FROM EPAGRETROATIVOVINCULO ET
           WHERE ET.CDVINCULO = F_1001.CDVINCULO
             AND F_1001.ANOMES BETWEEN to_number(To_Char(ET.DTINICIO,'YYYYMM')) AND to_number(To_Char(ET.DTFIM,'YYYYMM'))
             AND ROWNUM < 2;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vNuNivelDestino := vnunivelorigem;
              vNuReferenciaDestino := vnureferenciaorigem;
              vCdEstruturaCarreiraDestino := vcdestruturacarreiraorigem;

          END;

          vAno := SUBSTR(f_1001.AnoMes,1,4);
          vMes := SUBSTR(f_1001.AnoMes,5,2);

          -- Busca valor tabela origem
          vValorTabelaOri := fretornavalorsalario(vNunivelOrigem, vNureferenciaorigem,
                                                   vAno, vMes,
                                                   vcdestruturacarreiraorigem , pAgrupamento, 1);
          -- Busca valor tabela destino
          vValorProgressao := fretornavalorsalario(vnuniveldestino, vnureferenciadestino,
                                                   vAno, vMes,
                                                   vcdestruturacarreiradestino, pAgrupamento, 1);
          -- Se encontrou diferen?a entre o valor das tabelas
          vValorDiferenca := vValorProgressao;

          IF vValorTabelaOri <= vValorProgressao and f_1001.vlrecebido <= vValorTabelaOri
           THEN vValorDiferenca := vValorProgressao * ( f_1001.vlrecebido / vValorTabelaOri);
          END IF;

          update EPAGRETROATIVOVINCULOFOLHA eprtf
             set eprtf.vltabelaori = vValorTabelaOri,
                 eprtf.vltabeladest = vValorProgressao,
                 eprtf.vldiferenca = vValorDiferenca
           where eprtf.cdvinculo = f_1001.cdvinculo
             and eprtf.cdfolha   = f_1001.cdfolha
             and eprtf.cdrubrica = f_1001.cdrubrica;

          commit;

  END LOOP;

END PCALCULO1001;

PROCEDURE PGERAARQUIVORETROATIVO (pCdOrgao number, pCdVinculo number,
                                  pProcesso CHAR, pDescricao CHAR,
                                  pData DATE,
                                  pMesAnoIni CHAR,
                                  pMesAnoFim CHAR,
                                  pCdProcesso NUMBER,
                                  pCdPagRetroativo NUMBER,
                                  pMaiorQue number,
                                  cResultado OUT TYPES.ref_cursor) IS

vCdOrgao number;

vAnoMesFim char(6) := substr(pMesAnoFim,3,4) || substr(pMesAnoFim,1,2);

vAnoMesIni char(6) := substr(pMesAnoIni,3,4) || substr(pMesAnoIni,1,2);

BEGIN

    IF pCdOrgao is not null
      THEN
        SELECT O.CDORGAO
          INTO vCdOrgao
          FROM Ecadhistorgao O
         WHERE O.Cdorgaosirh = pCdOrgao
           AND O.DTFIMVIGENCIA is null;
    END IF;

    OPEN cResultado FOR

    SELECT CAB.LINHA FROM (
    select 'H' || -- Tipo de Registro
       RPAD(pProcesso,20) || -- N? Processo
       rpad(pDescricao,80) || -- Descri??o
       to_char(pData,'DDMMYYYY') || -- Data
       pMesAnoIni   || -- Mes Ano Inicio
       pMesAnoFim  AS LINHA, 0 AS VALOR   -- Mes/ANo Final
       from dual) CAB

    UNION ALL
    -- Rubrica 01-0001
    SELECT INTERNO.LINHA FROM (
    select 'D' ||
           lpad(ev.numatricula,7,0) ||   -- Matricula
           lpad(ev.nudvmatricula,1,0) || -- Digito
           lpad(ev.nuseqmatricula,2,0) || -- Sequencial
           lpad(vr.nurubrica,4,0) ||
           SUBSTR(erv.anomes,5,2) ||
           SUBSTR(erv.anomes,1,4) ||

           CASE WHEN VR.nurubrica NOT IN (33,75,555,188,564,56) -- RUBRICAS COM INCIDENCIA DE IPREV
                THEN LPAD(TRUNC(

                   CASE WHEN (SELECT 1 FROM EPAGRETROATIVOVINCULOFOLHAARQ EQ
                               WHERE EQ.CDVINCULO = ERV.CDVINCULO
                                 AND EQ.CDFOLHA = ERV.CDFOLHA
                                 AND EQ.CDRUBRICA = ERV.CDRUBRICA) = 1
                        THEN (SELECT EQ.VLCALCULADO FROM EPAGRETROATIVOVINCULOFOLHAARQ EQ
                               WHERE EQ.CDVINCULO = ERV.CDVINCULO
                                 AND EQ.CDFOLHA = ERV.CDFOLHA
                                 AND EQ.CDRUBRICA = ERV.CDRUBRICA)
                        ELSE  ERV.VLRETROATIVO
                   END

                 * 100,0),11,0)
                ELSE LPAD(0,11,0) END ||
           CASE WHEN VR.nurubrica IN (33,75,555,188,564,56) -- RUBRICAS SEM INCIDENCIA DE IPREV
                THEN LPAD(TRUNC((erv.vlretroativo) * 100,0),11,0)
                ELSE LPAD(0,11,0) END AS LINHA,

            CASE WHEN (SELECT 1 FROM EPAGRETROATIVOVINCULOFOLHAARQ EQ
                               WHERE EQ.CDVINCULO = ERV.CDVINCULO
                                 AND EQ.CDFOLHA = ERV.CDFOLHA
                                 AND EQ.CDRUBRICA = ERV.CDRUBRICA) = 1
                        THEN (SELECT EQ.VLCALCULADO FROM EPAGRETROATIVOVINCULOFOLHAARQ EQ
                               WHERE EQ.CDVINCULO = ERV.CDVINCULO
                                 AND EQ.CDFOLHA = ERV.CDFOLHA
                                 AND EQ.CDRUBRICA = ERV.CDRUBRICA)
                        ELSE  erv.VLRETROATIVO
            END AS VALOR

     from epagretroativovinculofolha erv
      inner join ecadvinculo ev on ev.cdvinculo = erv.cdvinculo
      inner join ecadpessoa ep on ep.cdpessoa = ev.cdpessoa
--      inner join epagretroativovincultfolha euf on euf.cdvinculo = erv.cdvinculo
      --inner join ecadhistorgao eo on eo.cdorgao = euf.cdorgaoultfolha and eo.dtfimvigencia is null
      inner join vpagrubricaagrupamento vr on vr.cdrubricaagrupamento = erv.cdrubrica
      where --EUf.cdorgaoultfolha = case when vCdOrgao is not null then vCdOrgao else euf.cdorgaoultfolha end
        --and erv.cdvinculo = case when pCdVinculo is not null then pCdVinculo else erv.cdvinculo end
        --AND erv.vlretroativo > 0.30 --pMaiorQue -- Somente quem excedeu a PARAMETRO
        --and
        erv.anomes between vAnoMesIni and vAnoMesFim
       -- AND ERV.CDRUBRICA = 10339 -- 13º Salario
        --and erv.cdpagretroativoprocesso = pCdProcesso -- Para rubricas que n?o tem processo
        --and euf.cdpagretroativo = pCdPagRetroativo
        --and euf.anomesultfolha='201503'
        and erv.cdpagretroativo = pCdPagRetroativo
        and erv.vlretroativo > 0
        --and vr.nurubrica <> 23
        --AND ERV.CDRUBRICA NOT IN (10730,8220,10700,8566)
        -- Abaixo e para excluir quem ultrapassou o teto
        /*and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          --and eh1.cdrubricaagrupamento in (10381,9602))
                          and eh1.cdrubricaagrupamento in (9602))*/
        /*and exists (select 1 -- Verificar se teve progress?o na carreira
                      from epagretroativovinculo eprv
                     where eprv.cdvinculo = erv.cdvinculo
                       and erv.anomes between to_char(eprv.dtinicio,'YYYYMM') and to_char(eprv.dtfim,'YYYYMM')) */

      ) INTERNO

      WHERE INTERNO.VALOR > 0.29 ;--pMaiorQue ;
/*
     UNION ALL
     -- Demais rubricas
     select 'D' ||
           lpad(ev.numatricula,7,0) ||   -- Matricula
           lpad(ev.nudvmatricula,1,0) || -- Digito
           lpad(ev.nuseqmatricula,2,0) || -- Sequencial
           lpad(vr.nurubrica,4,0) ||
           SUBSTR(erv.anomes,5,2) ||
           SUBSTR(erv.anomes,1,4) ||
           LPAD(TRUNC((erv.vldiferenca - erv.vlrecebido) * 100,0),11,0) ||
           LPAD(0,11,0)
      from epagretroativovinculofolha erv
      inner join ecadvinculo ev on ev.cdvinculo = erv.cdvinculo
      inner join ecadpessoa ep on ep.cdpessoa = ev.cdpessoa
      inner join ecadhistorgao eo on eo.cdorgao = erv.cdorgao and eo.dtfimvigencia is null
      inner join vpagrubrica vr on vr.cdrubricaagrupamento = erv.cdrubrica
      where erv.cdorgao = case when vCdOrgao is not null then vCdOrgao else erv.cdorgao end
        and erv.cdvinculo = case when pCdVinculo is not null then pCdVinculo else erv.cdvinculo end
        and erv.vlrecebido not between  (erv.vldiferenca - 0.05) and (erv.vldiferenca + 0.05)
        and erv.cdrubrica <> 8451
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602));*/
--      order by eo.cdorgaosirh, ERV.ANOMES;

END PGERAARQUIVORETROATIVO;

PROCEDURE PINSERERETROATIVORUBVINCULO IS
--
-- Tabela criada apos o processamento que vai armazenar a rela?ao do tabela EPAGHISTORICORUBRICAVINCULO
-- com o retroativo e a diferen?a da rubrica recalculada.
--
vCdHistoricoRubricaVinculo number;

begin

for c_ret in
  (SELECT r.*
     FROM EPAGRETROATIVOVINCULOFOLHA r WHERE r.ANOMES BETWEEN '200701' AND '200712')
  LOOP
    begin
    SELECT eh.cdhistoricorubricavinculo
      into vCdHistoricoRubricaVinculo
      from epaghistoricorubricavinculo eh
     where eh.cdfolhapagamento = c_ret.cdfolha
       and eh.cdvinculo = c_ret.cdvinculo
       and eh.cdrubricaagrupamento = c_ret.cdrubrica
       and eh.vlpagamento = c_ret.vlrecebido
       and rownum < 2;

    exception
       when no_data_found
         then
           /*dbms_output.put_line('NAO ACHOU -> VINC: ' || c_ret.cdvinculo || ' FOLHA -> ' ||
                                 c_ret.cdfolha || ' RUBRICA -> ' || c_ret.cdrubrica);*/

          select eh.cdhistoricorubricavinculo
            into vCdHistoricoRubricaVinculo
            from epaghistoricorubricavinculo eh
            inner join epagfolhapagamento vf on eh.cdfolhapagamento = vf.cdfolhapagamento
            where eh.cdrubricaagrupamento = c_ret.cdrubrica
              and vf.nuanomesreferencia = c_ret.anomes
              and eh.vlpagamento = c_ret.vlrecebido
              and vf.flcalculodefinitivo = 'S';

           -- Procurar folha de 13 de novembro e relacionar com o inserido
           /*vCdHistoricoRubricaVinculo := c_ret.cdvinculo || c_ret.cdrubrica || c_ret.cdfolha;

           INSERT INTO EPAGRETROATIVORUBRICAVINCULO
           VALUES (vCdHistoricoRubricaVinculo, c_ret.vltabelaori, c_ret.vltabeladest, c_ret.vldiferenca);
           commit;
           */continue;

       when too_many_rows
         then
           dbms_output.put_line('ACHOU MAIS DE UM -> VINC: ' || c_ret.cdvinculo || ' FOLHA -> ' ||
                                 c_ret.cdfolha || ' RUBRICA -> ' || c_ret.cdrubrica);
           continue;
    end;

    INSERT INTO EPAGRETROATIVORUBRICAVINCULO
    VALUES (vCdHistoricoRubricaVinculo, c_ret.vltabelaori, c_ret.vltabeladest, c_ret.vldiferenca);

    commit;

  END LOOP;

END;

PROCEDURE PLISTARETROATIVO (pCdOrgao number, pCdVinculo number, pImplantado char,
                            pCdPagRetroativo number, pMaiorQue number,
                            cResultado OUT TYPES.ref_cursor) IS

vCdOrgao number;
--vIndice  number(3,15);

BEGIN

    IF pCdOrgao is not null
      THEN
        SELECT O.CDORGAO
          INTO vCdOrgao
          FROM Ecadhistorgao O
         WHERE O.Cdorgaosirh = pCdOrgao
           AND O.DTFIMVIGENCIA is null;
    END IF;

    OPEN cResultado FOR

    -- RUBRICAS COM VALORES NEGATIVOS
   /* select eo.cdorgaosirh || ' - ' || eo.nmorgao as ORGAO,
           erv.anomes,
           pkgutil.FFormataMatricula(ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula) as MAT,
           ep.nmpessoa,
           lpad(vr.cdtiporubrica,2,0) || '-' || lpad(vr.nurubrica,4,0) as RUB,
           vr.derubricaagrupamento,
           erv.vlrecebido as RECEBIDO,
           erv.vldiferenca as DEVIDO,
           erv.vlretroativo as DIFERENCA, ev.cdvinculo
      from epagretroativovinculofolha erv
      inner join ecadvinculo ev on ev.cdvinculo = erv.cdvinculo --and ev.cdorgao = erv.cdorgao
      inner join ecadpessoa ep on ep.cdpessoa = ev.cdpessoa
      inner join epagretroativovincultfolha euf on euf.cdvinculo = erv.cdvinculo
      inner join ecadhistorgao eo on eo.cdorgao = euf.cdorgaoultfolha and eo.dtfimvigencia is null
      inner join ecadorgao eg on eg.cdorgao = eo.cdorgao
      inner join vpagrubrica vr on vr.cdrubricaagrupamento = erv.cdrubrica
      where eo.cdorgao = case when vCdOrgao is not null then vCdOrgao else eo.cdorgao end
        and erv.cdvinculo = case when pCdVinculo is not null then pCdVinculo else erv.cdvinculo end
        and eg.flimplantado = case when pImplantado is not null then pImplantado else eg.flimplantado end -- ?rg?os implantados 'S'
        --and erv.vlrecebido not between (erv.vldiferenca - 0.29) and (erv.vldiferenca + 0.29)
        and ERV.VLRETROATIVO <= -0.30
        and erv.cdrubrica in (8220,10700,10730,8566) -- Rubrica 01-0001 e as que descontam dela
        and euf.anomesultfolha = '201310'
        -- Os servidores que recebem a rubrica 01-0137 n?o tem diferen?a para receber...
        -- Os servidores que tiveram desconto do teto 05-0983 na? tem diferen?a..
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602))
        and exists (select 1 -- Verificar se teve progress?o na carreira, somente para a 01-0001
                      from epagretroativovinculo eprv
                     where eprv.cdvinculo = erv.cdvinculo
                       and erv.anomes between to_char(eprv.dtinicio,'YYYYMM') and to_char(eprv.dtfim,'YYYYMM'))

UNION ALL*/

-- RUBRICAS COM VALORES POSITIVOS E QUE N?O DESCONTAM DA 01-0001.

select eo.cdorgaosirh || ' - ' || eo.nmorgao as ORGAO,
           --substr(erv.anomes,5,2) || '/' || substr(erv.anomes,1,4) as ANOMES,
           erv.anomes,
           pkgutil.FFormataMatricula(ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula) as MAT,
           ep.nmpessoa,
           lpad(vr.cdtiporubrica,2,0) || '-' || lpad(vr.nurubrica,4,0) as RUB,
           vr.derubricaagrupamento,
           erv.vlrecebido as RECEBIDO,
           erv.vldiferenca as DEVIDO,
           erv.vlretroativo AS DIFERENCA, ev.cdvinculo,
           erv.vloutroretroativo as OUTROS,
           (select erv1.vlindicecorrecao
            from epagretroativovinculofolha erv1
           where  erv1.cdvinculo = erv.cdvinculo
             and  erv1.cdfolha = erv.cdfolha
             and  erv1.cdrubrica = 8451
             and  erv1.vlretroativo > 0) as INDICE
           --(erv.vldiferenca - erv.vlrecebido) as DIFERENCA, ev.cdvinculo
      from epagretroativovinculofolha erv
      -- Inserido para relacionar com a tabela do processo
      --inner join epagretroativoprocesso erp on erp.cdprocessoretroativo = erv.cdpagretroativoprocesso
      inner join ecadvinculo ev on ev.cdvinculo = erv.cdvinculo --and ev.cdorgao = erv.cdorgao
      inner join ecadpessoa ep on ep.cdpessoa = ev.cdpessoa
      inner join epagretroativovincultfolha euf on euf.cdvinculo = erv.cdvinculo
      inner join ecadhistorgao eo on eo.cdorgao = euf.cdorgaoultfolha and eo.dtfimvigencia is null
      inner join ecadorgao eg on eg.cdorgao = eo.cdorgao
      inner join vpagrubricaagrupamento vr on vr.cdrubricaagrupamento = erv.cdrubrica
      where eo.cdorgao = case when vCdOrgao is not null then vCdOrgao else eo.cdorgao end
        and erv.cdvinculo = case when pCdVinculo is not null then pCdVinculo else erv.cdvinculo end
        AND ERV.VLRETROATIVO > pMaiorQue --0.30
        and euf.anomesultfolha='201410'
        --and (erv.vldiferenca - erv.vlrecebido) > 0.30 -- Somente quem excedeu a R$ 0,30
        --and (erv.vldiferenca - erv.vlrecebido) > 0.05
        and eg.flimplantado = case when pImplantado is not null then pImplantado else eg.flimplantado end
        --and erv.cdpagretroativoprocesso < 300
        and erv.cdpagretroativo = pCdPagRetroativo
        and euf.cdpagretroativo = pCdPagRetroativo
        and erv.anomes > '201500'
        and exists (select 1
                      from epagretroativovinculofolha erv1
                           where  erv1.cdvinculo = erv.cdvinculo
                             and  erv1.cdfolha = erv.cdfolha
                             and  erv1.cdrubrica = 8451
                             and  erv1.vlretroativo > 0)
        -- ?rg?os implantados 'S'
        --and erv.cdrubrica NOT in (8451,8220,10700,10730,8566,10405) -- Rubrica 01-0001 e as que descontam dela
        --and euf.anomesultfolha = '201310'
        -- Os servidores que recebem a rubrica 01-0137 n?o tem diferen?a para receber...
        -- Os servidores que tiveram desconto do teto 05-0983 na? tem diferen?a..
        /*and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (9602))*/;
                         -- and eh1.cdrubricaagrupamento in (10381,9602));
        /*and exists (select 1 -- Verificar se teve progress?o na carreira, somente para a 01-0001
                      from epagretroativovinculo eprv
                     where eprv.cdvinculo = erv.cdvinculo
                       and erv.anomes between to_char(eprv.dtinicio,'YYYYMM') and to_char(eprv.dtfim,'YYYYMM')); */

END PLISTARETROATIVO;

PROCEDURE PLISTAEXCEDEULIMITE  IS

  -- Local variables here
  vTotal number (13,2) :=0;
  --vLinha char(500);

begin

  /* Create Global Temporary Table Temp_Vinc (cdvinculo number, cdorgao number,
                        nmorgao varchar(50),
                        matricula char(12)
                        nmpessoa varchar(50)
                        total number(13,2)*/

 DELETE EPAGRETROATIVOEXCEDELIMITE;
 COMMIT;

 for c_vinc in (select cdvinculo
                from epagretroativovinculofolha
                group by cdvinculo
                having sum(vldiferenca-vlrecebido) > 3575.37)

  loop

      select /*eo.cdorgaosirh || ' - ' || eo.nmorgao as ORGAO,
           --substr(erv.anomes,5,2) || '/' || substr(erv.anomes,1,4) as ANOMES,
           erv.anomes,
           pkgutil.FFormataMatricula(ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula) as MAT,
           ep.nmpessoa,
           lpad(vr.cdtiporubrica,2,0) || '-' || lpad(vr.nurubrica,4,0) as RUB,
           vr.derubricaagrupamento,
           erv.vlrecebido as RECEBIDO,
           erv.vldiferenca as DEVIDO,*/
           sum(erv.vldiferenca - erv.vlrecebido) as DIFERENCA
       into vtotal
      from epagretroativovinculofolha erv
--      inner join ecadvinculo ev on ev.cdvinculo = erv.cdvinculo --and ev.cdorgao = erv.cdorgao
--      inner join ecadpessoa ep on ep.cdpessoa = ev.cdpessoa
      inner join epagretroativovincultfolha euf on euf.cdvinculo = erv.cdvinculo
      inner join ecadhistorgao eo on eo.cdorgao = euf.cdorgaoultfolha and eo.dtfimvigencia is null
--      inner join vpagrubrica vr on vr.cdrubricaagrupamento = erv.cdrubrica
      where erv.cdvinculo = c_vinc.cdvinculo
        and (erv.vldiferenca - erv.vlrecebido) > = 0.30
--        and erv.cdrubrica = 8451 -- Rubrica 01-0001
        and euf.anomesultfolha = '201310'
        -- Os servidores que recebem a rubrica 01-0137 n?o tem diferen?a para receber...
        -- Os servidores que tiveram desconto do teto 05-0983 na? tem diferen?a..
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602))
        and exists (select 1 -- Verificar se teve progress?o na carreira, somente para a 01-0001
                      from epagretroativovinculo eprv
                     where eprv.cdvinculo = erv.cdvinculo
                       and erv.anomes between to_char(eprv.dtinicio,'YYYYMM') and to_char(eprv.dtfim,'YYYYMM'));

    if vTotal > 3575.37
      then
        --OPEN CRESULTADO FOR
        insert into EPAGRETROATIVOEXCEDELIMITE
        select distinct ert.cdvinculo, euf.cdorgaoultfolha,  eho.nmorgao,
                        pkgutil.FFormataMatricula(ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula),
                        ep.nmpessoa, vTotal
                       from epagretroativovinculofolha ert
                       inner join epagretroativovincultfolha euf on euf.cdvinculo = ert.cdvinculo
                       inner join ecadvinculo ev on (ev.cdvinculo = ert.cdvinculo)
                       inner join ecadpessoa ep on (ep.cdpessoa = ev.cdpessoa)
                       inner join ecadhistorgao eho on (eho.cdorgao = euf.cdorgaoultfolha and eho.dtfimvigencia is null)
                       where ert.cdvinculo = C_VINC.CDVINCULO;

        commit;

    end if;

   end loop;

--select cdvinculo, sum(vldiferenca-vlrecebido) from epagretroativovinculofolha
--group by erv.cdvinculo
--having sum(vldiferenca-vlrecebido) > 3575.37

end;

-- Created on 30/10/2013 by SILVIOAN
PROCEDURE PULTIMAFOLHAVINCULO (pCdPagRetroativo NUMBER) IS
  -- Alterar a tabela epagretroativovincultfolha com os dados da ultima folha calculada para o vinculo
  -- Local variables here
  VCDORGAO NUMBER;
  VCDFOLHA NUMBER;
  VANOMES CHAR(6);

begin

  delete EPAGRETROATIVOVINCULTFOLHA EF
  where  ef.cdpagretroativo = pCdPagRetroativo;
  -- Test statements here
  FOR C_VINC IN (SELECT distinct(CDVINCULO)
                   FROM EPAGRETROATIVOVINCULOFOLHA EVF
                   --from epagretroativovinculo evf
                  where eVF.cdpagretroativo = pCdPagRetroativo)
  LOOP
     BEGIN
     SELECT EH.CDFOLHAPAGAMENTO, VP.nuanomesreferencia, VP.CDORGAO
       INTO VCDFOLHA, VANOMES, VCDORGAO
       FROM EPAGHISTORICORUBRICAVINCULO EH
       INNER JOIN ePAGFOLHAPAGAMENTO VP ON (VP.cdfolhapagamento = EH.CDFOLHAPAGAMENTO)
       WHERE VP.nuanomesreferencia < 201511

         --AND VP.cdtipofolha = 1
        -- AND VP.cdtipocalculo = 1

         AND VP.CDAGRUPAMENTO = 1
         --AND VP.flcalculodefinitivo = 'S'
         AND EH.CDVINCULO = C_VINC.CDVINCULO
         AND ROWNUM < 2
         order by 1 desc;

      EXCEPTION
      WHEN NO_DATA_FOUND
       THEN
         VCDFOLHA := 0;
      END;

      INSERT INTO EPAGRETROATIVOVINCULTFOLHA
      VALUES(C_VINC.CDVINCULO, VCDFOLHA, VANOMES, VCDORGAO, pCdPagRetroativo);

      commit;
      /*UPDATE EPAGRETROATIVOVINCULTFOLHA EVF
       SET EVF.CDULTFOLHA = VCDFOLHA,
           EVF.ANOMESULTFOLHA = VANOMES,
           EVF.CDORGAOULTFOLHA = VCDORGAO
       WHERE EVF.CDVINCULO = C_VINC.CDVINCULO
         AND EVF.CDPAGRETROATIVO = pCdPagRetroativo;
            */
  END LOOP;

end PULTIMAFOLHAVINCULO;

PROCEDURE PLISTAVINCORGAOS (cResultado OUT TYPES.ref_cursor) IS
--
-- Listar matriculas que est?o no retroativo em mais de um ?rg?o para definir em qual
-- ser? pago
--
BEGIN

OPEN CRESULTADO FOR

select distinct ert.cdvinculo, ert.cdorgao, min(anomes), eho.nmorgao,
 pkgutil.FFormataMatricula(ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula) , ep.nmpessoa
 from epagretroativovinculofolha ert
 inner join ecadvinculo ev on (ev.cdvinculo = ert.cdvinculo)
 inner join ecadpessoa ep on (ep.cdpessoa = ev.cdpessoa)
 inner join ecadhistcargoefetivo cef on (cef.cdvinculo = ert.cdvinculo)-- and cef.cdorgaoexercicio = ert.cdorgao)
 inner join ecadhistorgao eho on (eho.cdorgao = ert.cdorgao and eho.dtfimvigencia is null)
 where ert.cdvinculo in (select cdvinculo as VINC
                          from epagretroativovinculofolha ert2
                          group by cdvinculo
                          having count(distinct(cdorgao))>1)
 group by ert.cdvinculo, ert.cdorgao, eho.nmorgao, ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula, ep.nmpessoa;

END PLISTAVINCORGAOS ;

PROCEDURE PLISTARETROATIVOSINT (pCdOrgao number, pCdVinculo number, cResultado OUT TYPES.ref_cursor) IS
--
-- Lista de matr?culas com direito ao retroativo por ?rg?o
--
vCdOrgao number;

BEGIN

    IF pCdOrgao is not null
      THEN
        SELECT O.CDORGAO
          INTO vCdOrgao
          FROM Ecadhistorgao O
         WHERE O.Cdorgaosirh = pCdOrgao
           AND O.DTFIMVIGENCIA is null;
    END IF;

    OPEN cResultado FOR

    SELECT ORGAO, MAT, PESSOA, SUM(RECEBIDO), SUM(DEVIDO), SUM(DIFERENCA)
FROM (
    select eo.nmorgao as ORGAO,
           pkgutil.FFormataMatricula(ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula) as MAT,
           ep.nmpessoa PESSOA,
           (erv.vlrecebido) as RECEBIDO,
           (erv.vldiferenca) as DEVIDO,
           (erv.vldiferenca - erv.vlrecebido) as DIFERENCA
      from epagretroativovinculofolha erv
      inner join ecadvinculo ev on ev.cdvinculo = erv.cdvinculo --and ev.cdorgao = erv.cdorgao
      inner join ecadpessoa ep on ep.cdpessoa = ev.cdpessoa
      inner join ecadhistorgao eo on eo.cdorgao = erv.cdorgao and eo.dtfimvigencia is null
      where erv.cdorgao = case when vCdOrgao is not null then vCdOrgao else erv.cdorgao end
        and erv.cdvinculo = case when pCdVinculo is not null then pCdVinculo else erv.cdvinculo end
        and (erv.vldiferenca - erv.vlrecebido) >= 0.30 -- Limite de pagamento acima de R$ 0,30.
        and erv.cdrubrica = 8451 -- Rubrica 01-0001
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602))
        --and eo.cdorgaosirh in (3001,3002,3003,3004,3005,3006,3015,3016,3017,3018,3020,3021,3022,3023,3025,
        --                       3027,3030,3031,801,802,2001,2003,2005,1401,1001)
        and exists (select 1 -- Verificar se teve progress?o na carreira, somente para a 01-0001
                      from epagretroativovinculo eprv
                     where eprv.cdvinculo = erv.cdvinculo
                       and erv.anomes between to_char(eprv.dtinicio,'YYYYMM') and to_char(eprv.dtfim,'YYYYMM'))

 UNION ALL

 select eo.nmorgao as ORGAO,
           pkgutil.FFormataMatricula(ev.numatricula, ev.nudvmatricula, ev.nuseqmatricula) as MAT,
           ep.nmpessoa PESSOA,
           (erv.vlrecebido) as RECEBIDO,
           (erv.vldiferenca) as DEVIDO,
           (erv.vldiferenca - erv.vlrecebido) as DIFERENCA
      from epagretroativovinculofolha erv
      inner join ecadvinculo ev on ev.cdvinculo = erv.cdvinculo --and ev.cdorgao = erv.cdorgao
      inner join ecadpessoa ep on ep.cdpessoa = ev.cdpessoa
      inner join ecadhistorgao eo on eo.cdorgao = erv.cdorgao and eo.dtfimvigencia is null
      inner join vpagrubricaagrupamento vr on vr.cdrubricaagrupamento = erv.cdrubrica
      where erv.cdorgao = case when vCdOrgao is not null then vCdOrgao else erv.cdorgao end
        and erv.cdvinculo = case when pCdVinculo is not null then pCdVinculo else erv.cdvinculo end
        and erv.vlrecebido not between  (erv.vldiferenca - 0.05) and (erv.vldiferenca + 0.05)
        and erv.cdrubrica <> 8451 -- Rubrica 01-0001
        -- Os servidores que recebem a rubrica 01-0137 n?o tem diferen?a para receber...
        --and eo.cdorgaosirh in (3001,3002,3003,3004,3005,3006,3015,3016,3017,3018,3020,3021,3022,3023,3025,
        --                       3027,3030,3031,801,802,2001,2003,2005,1401,1001)
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602))
                       ) GRP1
        GROUP BY GRP1.ORGAO, GRP1.MAT, GRP1.PESSOA ;

END PLISTARETROATIVOSINT;

PROCEDURE PLISTARETROATIVOSINTORGAO (cResultado OUT TYPES.ref_cursor) IS
--
-- Lista retroativo total por ?rg?o
--
--vCdOrgao number;

BEGIN

    OPEN cResultado FOR

    SELECT ORGAO, SUM(RECEBIDO), SUM(DEVIDO), SUM(DIFERENCA)
    FROM (

    -- RUBRICAS COM VALORES NEGATIVOS

    select eo.nmorgao as ORGAO,
           (erv.vlrecebido) as RECEBIDO,
           (erv.vldiferenca) as DEVIDO,
           (erv.vldiferenca - erv.vlrecebido) as DIFERENCA
      from epagretroativovinculofolha erv
      inner join epagretroativovincultfolha euf on euf.cdvinculo = erv.cdvinculo
      inner join ecadhistorgao eo on eo.cdorgao = euf.cdorgaoultfolha and eo.dtfimvigencia is null
      where erv.cdrubrica IN (8220,10700,10730,8566)
        and erv.vlrecebido <= - 0.30
        and euf.anomesultfolha = '201310'
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602))
        and exists (select 1 -- Verificar se teve progress?o na carreira, somente para a 01-0001
                      from epagretroativovinculo eprv
                     where eprv.cdvinculo = erv.cdvinculo
                       and erv.anomes between to_char(eprv.dtinicio,'YYYYMM') and to_char(eprv.dtfim,'YYYYMM'))

     UNION ALL

     -- DEMAIS RUBRICAS

     select eo.nmorgao as ORGAO,
           (erv.vlrecebido) as RECEBIDO,
           (erv.vldiferenca) as DEVIDO,
           (erv.vldiferenca - erv.vlrecebido) as DIFERENCA
      from epagretroativovinculofolha erv
      inner join epagretroativovincultfolha euf on euf.cdvinculo = erv.cdvinculo
      inner join ecadhistorgao eo on eo.cdorgao = euf.cdorgaoultfolha and eo.dtfimvigencia is null
      where (erv.vldiferenca - erv.vlrecebido) >= 0.30 -- Limite de pagamento acima de R$ 0,30.
        and erv.cdrubrica NOT IN (8220,10700,10730,8566) -- DEMAIS RUBRICAS
        and euf.anomesultfolha = '201310'
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602))
        and exists (select 1 -- Verificar se teve progress?o na carreira, somente para a 01-0001
                      from epagretroativovinculo eprv
                     where eprv.cdvinculo = erv.cdvinculo
                       and erv.anomes between to_char(eprv.dtinicio,'YYYYMM') and to_char(eprv.dtfim,'YYYYMM'))

   ) GRP1
        GROUP BY GRP1.ORGAO ;

 /*UNION ALL

 select eo.nmorgao as ORGAO,
           (erv.vlrecebido) as RECEBIDO,
           (erv.vldiferenca) as DEVIDO,
           (erv.vldiferenca - erv.vlrecebido) as DIFERENCA
      from epagretroativovinculofolha erv
      inner join ecadhistorgao eo on eo.cdorgao = erv.cdorgao and eo.dtfimvigencia is null
      inner join vpagrubrica vr on vr.cdrubricaagrupamento = erv.cdrubrica
      where erv.vlrecebido not between  (erv.vldiferenca - 0.05) and (erv.vldiferenca + 0.05)
        and erv.cdrubrica <> 8451 -- Rubrica 01-0001
        -- Os servidores que recebem a rubrica 01-0137 n?o tem diferen?a para receber...
        and not exists (select 1
                        from epaghistoricorubricavinculo eh1
                        where eh1.cdvinculo = erv.cdvinculo
                          and eh1.cdfolhapagamento = erv.cdfolha
                          and eh1.cdrubricaagrupamento in (10381,9602))
                       ) GRP1
        GROUP BY GRP1.ORGAO ;*/

END PLISTARETROATIVOSINTORGAO;

--
-- Procedure que calcula as rubricas que s?o dependentes das rubricas de progress?o, aplicando
-- as f?rmulas sobre os rec?lculos e apurando as diferen?as.
-- Parametros: pTipoRubrica = Tipo da rubrica; pAgrupamento=n? do agrupamento;
-- pNuRubCalculada: n? da rubrica a ser calculada.
--
PROCEDURE PRECALCULARUBRICAS (pTipoRubrica number, pAgrupamento number, pNuRubFatoGerador number,
                              pNuRubCalculada number, pCdVinculo NUMBER, pAnoMesIni char, pAnoMesFim char,
                              pCdProcesso number) is

vCdRubricaAgrupamento number;
vBlocosFormula PKGPAG_RETROATIVO.tBlocos;
vBlocosBase PKGPAG_RETROATIVO.tBlocos;
vInRubricas string(5000);
vNotInRubricas string(5000);
vVlIndice number(13,2);
vVlRubricas number(13,2);
vVlRubCalc number(13,2);
vCdFormBlocoExp number;
vSQL VARCHAR2(4000);
vCdFolha number;
vCdVinculo number;
vVlCalculado number(13,2);
vVlPagamento number(13,2);
vFormula varchar2(200);
vFormExp varchar2(200);
--vValorFormula varchar2(15);
vCdOrgao number;
vAnoMes char(6);
vNuCho number;
vSgBlocoIndice char;
vValorBaseInc number(13,2);
vValorBase number(13,2);
vPercApo number(5,2) := 100;
vNuChoProp number(5,2);
vVlCco number(13,2);
vDtCalculo DATE;
vVlCelg number(13,2);
vNuRubCalculada number;
vVlNotInRubricas number(13,2);
vAno    char(4);
vMes    char(2);
vAnoMesAnt char(6);
vCount number;
vCdProcesso number;
vVlDiferenca number(13,2);
vVlSomaAno number(13,2);
vTipo CHAR(1);
vNuAnoMesImplantacao char(6);
vCdPagRetroativo number;
vVlRetroativo number(13,2);

BEGIN

   -- Acha o c?digo da rubrica Fato gerador do processo devida a partir desta rubrica
   SELECT V.CDRUBRICAAGRUPAMENTO
     INTO vCdRubricaAgrupamento
     FROM vpagrubricaagrupamento v
    WHERE v.cdagrupamento = pAgrupamento
      AND v.nurubrica = pNuRubFatoGerador
      AND v.cdtiporubrica = 1;

   SELECT V.CDRUBRICAAGRUPAMENTO
     INTO vNuRubCalculada
     FROM vpagrubricaagrupamento v
    WHERE v.cdagrupamento = pAgrupamento
      AND v.nurubrica = pNuRubCalculada
      AND v.cdtiporubrica = pTipoRubrica;

   IF pTipoRubrica = 9 -- Bases de calculo
     THEN

      vFormula := FPROCURAFORMULASBases (vNuRubCalculada);

      vBlocosBase := FRETORNABLOCOSBASES(vCdHistForm);

   ELSE

      vFlIndiceHora := 'N';

      vFormula := FPROCURAFORMULAS (vNuRubCalculada, pAnoMesFim);

      vCdVersao := FVERSAOFORMULACALC(vCdFormulacalculo);

      vCdHistForm := FHISTFORMULACALCULO(vCdVersao);

      vCdExpForm := FEXPRESSAOFORMULA(vCdHistForm);

      vBlocosFormula := FRETORNABLOCOSFORMULA(vCdExpForm);

   END IF;

   vFormula := REPLACE(vFormula,'=','');

   vFormula := REPLACE(vFormula,',','.');

   --
   -- Verificar o tipo de retroativo P-Processo; F-Progress?o Funcional.
   --

   SELECT EPAR.TIPO
     INTO vTipo
     FROM EPAGRETROATIVO EPAR
    WHERE EPAR.CDPAGRETROATIVO = pCdProcesso;

    DELETE EPAGRETROATIVOVINCULOFOLHA EPR
     WHERE EPR.CDRUBRICA = vNuRubCalculada
       AND EPR.CDVINCULO = CASE WHEN pCdVinculo IS NOT NULL THEN pCdVinculo
                                ELSE EPR.CDVINCULO END
       AND EPR.ANOMES BETWEEN pAnoMesIni and pAnoMesFim
       AND EPR.Cdpagretroativoprocesso = CASE WHEN vTipo = 'P'
                                              THEN (SELECT EPP.CDPROCESSORETROATIVO
                                                      FROM EPAGRETROATIVOPROCESSO EPP
                                                     WHERE EPP.CDVINCULO = EPR.CDVINCULO
                                                       AND EPP.CDPAGRETROATIVO = pCdProcesso)

                                              ELSE (SELECT EPR1.CDPAGRETROATIVOPROCESSO
                                                      FROM EPAGRETROATIVOVINCULO EPRV
                                                     INNER JOIN EPAGRETROATIVOVINCULOFOLHA EPR1
                                                             ON EPR1.CDVINCULO = EPRV.CDVINCULO
                                                     WHERE EPRV.CDVINCULO = EPR.CDVINCULO
                                                      AND EPRV.CDPAGRETROATIVO = pCdProcesso
                                                       AND EPR1.CDPAGRETROATIVOPROCESSO IS NOT NULL
                                                       AND ROWNUM < 2)
                                              END;

   COMMIT;

   FOR F_RET IN (SELECT etrt.cdfolha, etrt.cdorgao, etrt.cdvinculo, etrt.cdpagretroativoprocesso, etrt.cdpagretroativo, etrt.vlrecebido, etrt.vltabelaori
                   FROM EPAGRETROATIVOVINCULOFOLHA ETRT
                  WHERE ETRT.CDRUBRICA = VCDRUBRICAAGRUPAMENTO
                    AND ETRT.CDVINCULO =  CASE WHEN pCdVinculo IS NOT NULL THEN pCdVinculo
                                               ELSE ETRT.CDVINCULO END
                    AND ETRT.ANOMES BETWEEN pAnoMesIni and pAnoMesFim)
                   /*\* AND ETRT.CDPAGRETROATIVOPROCESSO =
                                         CASE WHEN vTipo = 'P'
                                              THEN (SELECT EPP.CDPROCESSORETROATIVO
                                                      FROM EPAGRETROATIVOPROCESSO EPP
                                                     WHERE EPP.CDVINCULO = ETRT.CDVINCULO
                                                       AND EPP.CDPAGRETROATIVO = pCdProcesso)

                                              ELSE (SELECT EPR1.CDPAGRETROATIVOPROCESSO
                                                      FROM EPAGRETROATIVOVINCULO EPRV
                                                     INNER JOIN EPAGRETROATIVOVINCULOFOLHA EPR1
                                                             ON EPR1.CDVINCULO = EPRV.CDVINCULO
                                                     WHERE EPRV.CDVINCULO = ETRT.CDVINCULO
                                                      AND EPRV.CDPAGRETROATIVO = pCdProcesso
                                                       AND EPR1.CDPAGRETROATIVOPROCESSO IS NOT NULL
                                                       AND ROWNUM < 2*\
                                         END)
                    \*AND ETRT.Vlretroativo > 0*\)*/

   LOOP
   -- Procura as formulas da rubrica
   -- Codigo do processo se tiver

   IF vTipo = 'P'
     THEN

      SELECT EPT.CDPROCESSORETROATIVO, EPT.CDPAGRETROATIVO
        INTO vCdProcesso, vCdPagRetroativo
        FROM EPAGRETROATIVOPROCESSO EPT
        WHERE EPT.CDVINCULO = F_RET.CDVINCULO;

   ELSE

      vCdProcesso := F_RET.CdPagRetroativoProcesso;
      vCdPagRetroativo := F_RET.CdPagRetroativo;

   END IF;

   BEGIN
      FOR f_form IN (select * from epaghistoricorubricavinculo eh
                          --   inner join EPAGRETROATIVOFORMULA etf on (eh.cdrubricaagrupamento = etf.cdrubricaformula)
                                                             -- and (etf.cdrubricaagrupamento = vCdRubricaAgrupamento)
                      WHERE eh.cdfolhapagamento = F_RET.CDFOLHA
                        and eh.cdvinculo = F_RET.CDVINCULO
                        and eh.cdrubricaagrupamento = vNuRubCalculada)

      LOOP
        -- Se for a rubrica 156 e tiver valor da 56 no mes anterior cai fora.

        vFormExp := vFormula;

        vDtFimSubst := null;

        vVlIndice := f_form.vlindicerubrica;

        vVlPagamento := f_form.vlpagamento;

        vCdFolha := F_RET.CDFOLHA;

        vCdVinculo := F_RET.CDVINCULO;

        SELECT epf.CdOrgao, epf.nuanomesreferencia, epf.dtcalculo
           into vCdOrgao, vAnoMes, vDtCalculo
           from EPAGFOLHAPAGAMENTO EPF
          where epf.cdfolhapagamento = vCdFolha;

        SELECT o.nuanomesimplantacao
          INTO vNuAnoMesImplantacao
          FROM ECADORGAO o
         WHERE o.cdorgao = vCdOrgao;

         if pNuRubCalculada = 156
           then
             IF SUBSTR(vAnoMes,5,2) = '01'
               THEN
                vAnoMesAnt := SUBSTR(VAnoMes,1,4) - 1 || '12';
             ELSE
                vAnoMesAnt := vAnoMes - 1;
             END IF;
             begin

             select 1
                into vCount
                from epaghistoricorubricavinculo eh
                inner join epagfolhapagamento vp on vp.cdfolhapagamento = eh.cdfolhapagamento
                                             and vp.nuanomesreferencia=vAnoMesAnt
                where cdvinculo = f_ret.cdvinculo
                 and vp.flcalculodefinitivo='S'
                 and eh.cdrubricaagrupamento = 10405
                 --and VP.cdtipofolha = 1
                 --AND VP.cdtipocalculo = 1
                AND VP.CDAGRUPAMENTO = 1;

             exception
               when no_data_found
                 then
                   vCount := 0;
             end;

             if vCount = 1
               then
                 continue;
             end if;

        end if;

        IF pNuRubCalculada = 56
           then

           IF vAnoMes = '201412'
             THEN
             vAnoMesFerias := 0;
           END IF;

           IF SUBSTR(vAnoMes,5,2) = 12
             THEN
              vAnoMesFerias := SUBSTR(vAnoMes,1,4) + 1 || '01';
           ELSE
              vAnoMesFerias := vAnoMes + 1;
           END IF;

           -- Para ferias procurar a folha normal, calculo normal do proximo mes ao recebido
           begin

           select distinct(vp.cdfolhapagamento)
              into vCdFolhaFerias
              from epaghistoricorubricavinculo eh
              inner join epagfolhapagamento vp on vp.cdfolhapagamento = eh.cdfolhapagamento
                                              and vp.nuanomesreferencia=vAnoMesFerias
              where cdvinculo = vCdVinculo
              and vp.flcalculodefinitivo = 'S'
              and vp.cdtipocalculo = 1
              and vp.cdtipofolhaPAGAMENTO = 2
              AND VP.CDAGRUPAMENTO = 1
              and rownum <2;

           exception
             when no_data_found
               then

               begin
               SELECT vfp.CdFolhaPagamento
                 INTO vCdFolhaFerias
                 FROM epagfolhapagamento vfp
                WHERE vfp.nuanomesreferencia = to_number(vAnoMesFerias)
                  and vfp.cdtipocalculo = 1
                  and vfp.cdtipofolhaPAGAMENTO = 2
                  AND vfp.cdorgao = vCdOrgao
                  AND vfp.cdagrupamento = pAgrupamento
                  AND vfp.flcalculodefinitivo = 'S';
               exception
                 when others
                  then
                    vCdFolhaFerias := 0;
             end;
           end;

          /* (select cdrubrica, vlretroativo, (vlretroativo / 3)
                                  from epagretroativovinculofolha
                                 where cdpagretroativoprocesso=203
                                   and cdrubrica not in (10339,10405)
                                   and vlretroativo > 0
                                   and cdvinculo = 263509
                                   and cdfolha = 3500)*/

           vSQL := 'SELECT sum(VlRetroativo/3) ' ||
                   'FROM Epagretroativovinculofolha etf '||
                   'WHERE etf.CdFolha = :vCdFolha ' ||
                   '  AND etf.CdVinculo = :vCdVinculo ' ||
                   '  AND etf.CdPagRetroativo = :vCdPagRetroativo ' ||
                   '  AND etf.VlRetroativo > 0 ' ||
                   '  AND etf.CdRubrica not in ( 10339, 10405)' ;

           EXECUTE IMMEDIATE vSQL INTO vVlCalculado
                       USING vCdfolhaFerias, vCDVINCULO, vCdPagRetroativo;

           if NVL(vVlCalculado,0) = 0
             then
               continue;
           end if;

           vVlCalculado := vVlCalculado + f_form.vlpagamento;

           GOTO inclui_ferias;

        END IF;

        FOR i IN vBlocosFormula.FIRST .. vBlocosFormula.LAST

        LOOP
          CASE
             -- Rubrica de ferias

             WHEN pNuRubCalculada = 156 and vBlocosFormula(i).SgTipoMnemonico = 'RUB'
               THEN
                 vVlRubCalc := 0;
                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vVlRubCalc);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'IND'
               THEN

                 if vNuRubCalculada <> 10411
                   then
                    -- Verifica se e rubrica de incorporacao com indice e busca
                     vVlIndice := FPERCENTUALINC(F_RET.Cdvinculo, vAnoMes, vNuRubCalculada,
                                              vCdOrgao);

                      if vVlIndice > 100 or vVlIndice = 0  or vVlIndice is null
                         then vVlIndice := f_form.vlindicerubrica;
                      end if;
                    else   --  Para rubrica de insalubridade informado em horas

                        if NVL(vVlIndice,0)= 0
                         then
                          BEGIN

                          SELECT SUM(EFIN.VLINDICE/100)
                             INTO vVlIndice
                             FROM EPaglancamentoFinanceiro EFIN
                            WHERE EFIN.CDRUBRICAAGRUPAMENTO = 10411
                              AND EFIN.CDVINCULO = F_RET.CDVINCULO
                              AND TO_CHAR(EFIN.DTINICIODIREITO,'YYYYMM') = vAnoMes
                              AND TO_CHAR(EFIN.DTFIMDIREITO,'YYYYMM') = vAnoMes
                              AND EFIN.Flanulado = 'N';

                          IF SQL%NOTFOUND
                            then
                             vVlIndice := f_form.vlindicerubrica;
                          end if;

                          END;

                        end if;

                  end if;

                  vSgBlocoIndice := vBlocosFormula(i).SgBloco;

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'PossuiDecJudicial'
               THEN
                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, 0);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'BAS'
               THEN

                 vValorBase := 0;

                 IF pNuRubCalculada = 56
                    then

                    vSQL := 'SELECT sum(VlRetroativo)/3 ' ||
                              'FROM Epagretroativovinculofolha etf '||
                             'WHERE etf.CdFolha = :vCdFolha ' ||
                             '  AND etf.CdVinculo = :vCdVinculo ' ||
                             '  AND etf.CdPagRetroativoProcesso = :vCdProcesso ' ||
                             '  AND etf.VlRetroativo > 0 ' ||
                             '  AND etf.CdRubrica not in ( 10339, 10405)' ;

                     EXECUTE IMMEDIATE vSQL INTO vVlCalculado
                              USING vCdfolha, vCDVINCULO, vCdProcesso;
                 END IF;

                 IF pNuRubCalculada in (56,156) and vBlocosFormula(i).SgBloco = 'A'
                   THEN
                    vValorBase := FRECALCULABASES('BFER', pAgrupamento, vAnoMes, F_RET.CdVinculo, vCdFolha, F_RET.CdOrgao, pNuRubCalculada);
                    --vVlIndice := 30;
                    vVlPagamento := vVlPagamento + vVlRub1156;

                    vVlIndice := vVlPagamento / (vVlRub1056 / 3 / 30);

                 END IF;

                 IF pNuRubCalculada = 23
                   THEN
                    vValorBase := FRECALCULABASES('B13SA', pAgrupamento, vAnoMes, F_RET.CdVinculo, vCdFolha, F_RET.CdOrgao, pNuRubCalculada);
                 END IF;
                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vValorBase);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'RUB' and pNuRubCalculada <> 156
               THEN
                  vCdFormBlocoExp := FFORMULABLOCOEXPRESSAO(vBlocosFormula(i).CdFormulaCalculoBloco);
                  -- Mnemonico RUB acha as rubricas
                  vInRubricas := FRUBRICASBLOCO(vCdFormBlocoExp);
                  -- Acha as rubricas recalculadas que fazem parte da formula
                  vNotInRubricas := FRUBRICASTMPFORMULA(vCdFolha, vCdVinculo, vCdFormBlocoExp, vCdPagRetroativo);
                  vVlRubricas := 0;
                  vVlRubCalc := 0;
                  vVlNotInRubricas := 0;
                  -- Somar rubricas da base de calculo da folha
                  vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                          'FROM epagHistoricoRubricaVinculo HRV '||
                          'WHERE HRV.CdFolhaPagamento = :vCdFolha ' ||
                          '  AND HRV.CdVinculo = :vCdVinculo ' ||
                          '  AND HRV.CdRubricaAgrupamento in ( ' || vInRubricas || ')' ;

                  EXECUTE IMMEDIATE vSQL INTO vVlRubricas
                              USING vCdfolha, vCDVINCULO;

                  -- Somar as rubricas a serem descontadas da base original
                  vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                          'FROM epagHistoricoRubricaVinculo HRV '||
                          'WHERE HRV.CdFolhaPagamento = :vCdFolha ' ||
                          '  AND HRV.CdVinculo = :vCdVinculo ' ||
                          '  AND HRV.CdRubricaAgrupamento in ( ' || vNotInRubricas || ')';

                   EXECUTE IMMEDIATE vSQL INTO vVlNotInRubricas
                              USING vCdfolha, vCDVINCULO;

                  -- Somar valor das rubricas recalculadas que fazem parte da formula

                   vSQL := 'SELECT sum(case when ETR.CDRUBRICA = 10724
                                               then ETR.vlRetroativo
                                               else ETR.VlDiferenca end) ' ||
                              'FROM EPAGRETROATIVOVINCULOFOLHA ETR '||
                              'WHERE ETR.CdFolha = :vCdFolha ' ||
                              '  AND ETR.CdVinculo = :vCdVinculo ' ||
                              '  AND ETR.CdPagRetroativo = :vCdPagRetroativo ' ||
                              '  AND ETR.CdRubrica in ( ' || vInRubricas || ')';
                  --END IF;

                  EXECUTE IMMEDIATE vSQL INTO vVlRubCalc
                              USING vCdfolha, vCDVINCULO, vCdPagRetroativo;

                  -- Ajusta valor para o que deveria ter sido pago
                  --vVlRubCalc := vVlRubricas - f_ret.vlrecebido + f_ret.vldiferenca;

                  vVlRubCalc := NVL(vVlRubCalc,0) + (NVL(vVlRubricas,0) - NVL(vVlNotInRubricas,0));

                  if vDtFimSubst is not null and vDtFimSubst <= vDtCalculo
                    then
                      vVlRubCalc := vVlRubCalc / 30 * to_number(to_char(vDtFimSubst,'DD'));
                  end if;

                  vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vVlRubCalc);

              WHEN vBlocosFormula(i).SgTipoMnemonico = 'CHO'
                THEN

                   vNuCho := FRETORNACARGAHORARIA(f_ret.cdorgao, f_ret.cdvinculo, vAnoMes);

                   CASE
                     when vNuCho in (20,30,40) and f_ret.cdvinculo not in (173440,248633,367129)
                       then
                         vNuCho := vNuCho * 5;

                     when vNuCho in (30)
                       then
                         vNuCho := vNuCho * 4;

                     when vNuCho = 0
                       then
                         vNuCho := 200;

                    END CASE;

                   /*vNuCho := 200;

                   IF f_ret.vlrecebido < f_ret.vltabelaori THEN
                      vNuCho := 200 * (f_ret.vlrecebido / f_ret.vltabelaori);
                   END IF;*/

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, TRUNC(vNuCho,2));

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'BASINC'
               THEN
                 vAno := SUBSTR(vAnoMes,1,4);
                 vMes := SUBSTR(vAnoMes,5,2);
                 /*vValorBaseInc := 0;

                 FOR vIncorp IN (SELECT * FROM EbpcIncorporacaoAtivo IA
                                  WHERE IA.CdVinculo = f_ret.CdVinculo
                                    AND IA.CdRubricaAgrupamento = vNuRubCalculada
                                    AND ((IA.NuAnoInicio < vAno OR (IA.NuAnoInicio = vAno AND
                                          IA.NuMesInicio <= vMes))
                                    AND (IA.NuAnoFim > vAno OR (IA.NuAnoFim = vAno AND
                                         IA.NuMesFim >= vMes) OR IA.NuAnoFim IS NULL)))
                 LOOP
                   vValorBaseInc := vValorBaseInc + FVALORINC(vIncorp.Cdincorporacaoativo, vAnoMes, vCdOrgao);

                 END LOOP;*/

                 vValorBaseInc := FBaseInc(f_ret.cdvinculo, vAnoMes, vNuRubCalculada, vCdOrgao);

                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vValorBaseInc);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'APO'
               THEN
                 BEGIN
                 SELECT EAPO.Vlpercentpropapo
                   INTO vPercApo
                   FROM epvdconcessaoaposentadoria EAPO
                  WHERE EAPO.CDVINCULO = F_RET.CDVINCULO
                    AND TO_CHAR(EAPO.DTINICIOAPOSENTADORIA,'YYYYMM') <= vAnoMes
                    AND EAPO.Dtfimaposentadoria is null
                    AND FLANULADO = 'N'
                    AND ROWNUM < 2;

                 EXCEPTION
                   WHEN NO_DATA_FOUND
                     THEN vPercApo := 100;
                 END;

                 if vPercApo is null
                   THEN vPercApo := 100;
                 end if;

                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vPercApo);

              WHEN vBlocosFormula(i).SgTipoMnemonico = 'CHOProp'
                THEN

                   vNuChoProp := (f_ret.vlrecebido / f_ret.vltabelaori);

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vNuChoProp);

              WHEN vBlocosFormula(i).SgTipoMnemonico = 'CCOSubst'
                THEN

                   vVlCco :=  FCCOSUBST(F_RET.CdVinculo, vAnoMes, vCdOrgao, vDtCalculo);

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vVlCco);

              WHEN vBlocosFormula(i).SgTipoMnemonico = 'CELG'
                THEN

                   vVlCelg := FMneCELG(670, 1, vAnoMes, 13, 'A');

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vVlCelg);

           END CASE;
         END LOOP;

         IF pNuRubCalculada = 75
           THEN
             vVlIndice := (vVlPagamento * vNuCho) / (vVlRubricas * 1.5);
             vFormExp := REPLACE(vFormExp, vSgBlocoIndice, vVlIndice);
         ELSE IF pNuRubCalculada in (265,188) -- Indice ja e aplicado na BASE da incorporacao
           then
              vVlIndice := 100;
              vFormExp := REPLACE(vFormExp, vSgBlocoIndice, vVlIndice);
           end if;
         END IF;

         if vFlIndiceHora = 'S' --and vVlIndice is not null
           then
              IF vNuAnoMesImplantacao <= vAnoMes
                 THEN
                   vVlIndice := TO_NUMBER(TRUNC((vVlIndice/POWER(10,LENGTH(LPAD(vVlIndice,4,'0'))-2)))||'.'||
                                          LPAD(TRUNC((vVlIndice-TRUNC(vVlIndice,-2))/60*100),2,'0'));

              ELSE
                     vVlIndice := TO_NUMBER(TRUNC((vVlIndice*100/POWER(10,LENGTH(LPAD(vVlIndice*100,4,'0'))-2)))||'.'||
                                            LPAD(TRUNC((vVlIndice*100-TRUNC(vVlIndice*100,-2))/60*100),2,'0'));
              END IF;
         end if;

         IF vVlIndice <> 0 and pNuRubCalculada not in (75, 265, 188) -- Verificar se o indice migrado esta coerente
           THEN
             IF vVlIndice = vVlPagamento
               THEN vVlIndice := vVlIndice / vVlRubricas;
             ELSE IF vNuRubCalculada IN (8864) and vVlIndice = 100
               THEN
                    vVlIndice := vVlCelg / vVlPagamento;
               end if;

             END IF;
             vFormExp := REPLACE(vFormExp, vSgBlocoIndice, vVlIndice);
         END IF;

         vVlCalculado := PKGMATH.FCalcular(vFormExp);

         --
         -- Para o retroativo 3 verificar se ja teve valor calculado para a rubrica
         -- em no retroativo 4
         --
         IF vCdPagRetroativo = 3
           then
             vVlRetroativo := NVL(FOUTROVALORPAGORETROATIVO( vCdVinculo, vCdFolha, vNuRubCalculada, 4),0);

         END IF;

         IF vVlCalculado <= 0 or vVlCalculado is null
           THEN
             vVlCalculado := vVlPagamento;
         END IF;

         IF vVlCalculado < vVlPagamento and pNuRubCalculada = 56
           then
             vVlCalculado := vVlPagamento;
         END IF;

         IF pNuRubCalculada in (265,188)
           THEN
           IF vVlRubCalc > vVlRubricas
             THEN
               vVlCalculado := vVlPagamento - (vVlRubCalc - vVlRubricas);
             ELSE
               vVlCalculado := vVlPagamento;
           END IF;
         END IF;
         -- Proporcionalizar pela 1001

         /*if (f_ret.vlrecebido / f_ret.vltabelaori) < 1
            then vVlCalculado := vVlCalculado * (f_ret.vlrecebido / f_ret.vltabelaori);
         end if;
         */--IF (vVlCalculado <> vVlPagamento) or (vVlCalculado = 0 and vVlPagamento<>0) THEN
            -- Verificar se o valor foi muito alto indica que o indice veio errado da migracao
            IF (vVlCalculado/60) > vVlPagamento THEN
               vVlCalculado := vVlCalculado/100;
            END IF;

            <<inclui_ferias>>

            if pNuRubCalculada in (56, 156)

              then -- Se recebeu Valor do Teto n?o inclui retroativo

                vVlDiferenca := vVlCalculado - vVlPagamento;

                vVlSomaAno := 0;

                begin

                select sum(eh.vlpagamento)
                  into vVlSomaAno
                  from epaghistoricorubricavinculo eh
                 inner join epagfolhapagamento vp
                         on vp.cdfolhapagamento = eh.cdfolhapagamento
                        and vp.nuanoreferencia = to_number(SUBSTR(vAnoMesFerias,1,4))
                 where cdvinculo = f_ret.cdvinculo
                   and vp.flcalculodefinitivo='S'
                   and eh.cdrubricaagrupamento in (10406, 10096)
                   --and VP.cdtipofolha = 1
                   --AND VP.cdtipocalculo = 1
                   AND VP.CDAGRUPAMENTO = 1;
                 -- Se a Soma do Recebido com o SomaAno do retrotativo excedeu 5000 n?o paga

                 if (vVlPagamento + NVL(vVlSomaAno,0)) >= 5000
                   then
                     continue;
                 end if;

                  IF vCdPagRetroativo = 3
                    then
                      vVlRetroativo := NVL(FOUTROVALORPAGORETROATIVO( vCdVinculo, vCdFolhaFerias,
                                                                      vNuRubCalculada, 4),0);

                  END IF;

                 -- For?a o teto quando a Soma excede 5000
                 if (vVlPagamento + NVL(vVlSomaAno,0) + vVlDiferenca) >= 5000
                   then
                     vVlCalculado := 5000;
                   else
                     vVlSomaAno := 0;
                 end if;
                 -- Quando n?o encontrou retroativo testa a soma
                 exception
                   when others
                     then
                       if (vVlPagamento + vVlDiferenca) >= 5000
                         then
                           vVlCalculado := 5000;
                        end if;
                 end;

                PINCLUIRETROATIVO (vCdOrgao,  vCdVinculo, vCdFolhaFerias, vNuRubCalculada,
                                    vAnoMesFerias, (vVlPagamento + nvl(vVlSomaAno,0)),  vVlCalculado, vCdProcesso,
                                    vCdPagRetroativo, NVL(vVlRetroativo,0));
              else
                 --
                 -- Somar se ja existir para tratar rubricas duplicadas na folha e para n?o duplicar o calculo.
                 --
                 BEGIN
                    UPDATE Epagretroativovinculofolha EPT
                     SET   EPT.Vlrecebido = EPT.VLRECEBIDO + vVlPagamento,
                           EPT.Vldiferenca = EPT.VlDiferenca + vVlCalculado
                     WHERE EPT.CdOrgao = vCdOrgao
                       AND EPT.CdFolha = vCdFolha
                       AND EPT.CdVinculo = vCdVinculo
                       AND EPT.CdRubrica = vNuRubCalculada
                       AND EPT.Anomes = vAnoMes
                       AND EPT.Cdpagretroativo = vCdPagRetroativo
                       AND EPT.CdPagRetroativoProcesso = vCdProcesso;

                    IF SQL%NOTFOUND
                       THEN
                       PINCLUIRETROATIVO (vCdOrgao,  vCdVinculo, vCdFolha, vNuRubCalculada,
                                          vAnoMes, vVlPagamento,  vVlCalculado, vCdProcesso, vCdPagRetroativo,
                                          NVL(vVlRetroativo,0));
                    END IF;

                 END;
            end if;

         --END IF;

      END LOOP;
    END;

    END LOOP;
END PRECALCULARUBRICAS;

PROCEDURE PRECALCULA13 (pTipoRubrica number, pAgrupamento number,
                        pNuRubCalculada number, pCdVinculo NUMBER, pAnoMesIni char, pAnoMesFim char) is

vCdRubricaAgrupamento number;
vBlocosFormula PKGPAG_RETROATIVO.tBlocos;
vBlocosBase PKGPAG_RETROATIVO.tBlocos;
vInRubricas string(5000);
vNotInRubricas string(5000);
vVlIndice number(13,2);
vVlRubricas number(13,2);
vVlRubCalc number(13,2);
vCdFormBlocoExp number;
vSQL VARCHAR2(4000);
vCdFolha number;
vCdVinculo number;
vVlCalculado number(13,2);
vVlPagamento number(13,2);
vFormula varchar2(200);
vFormExp varchar2(200);
--vValorFormula varchar2(15);
vCdOrgao number;
vAnoMes char(6);
--vNuCho number;
vSgBlocoIndice char;
vValorBaseInc number(13,2);
vValorBase number(13,2);
vPercApo number(5,2) := 100;
--vNuChoProp number(5,2);
vVlCco number(13,2);
vDtCalculo DATE;
vVlCelg number(13,2);
vNuRubCalculada number;
vVlNotInRubricas number(13,2);
vDtAdm date;
vMesInicio number;
vAno number;

BEGIN

   -- Acha o c?digo da rubrica 01-0001, j? que a progress?o ? devida a partir desta rubrica
   SELECT V.CDRUBRICAAGRUPAMENTO
     INTO vCdRubricaAgrupamento
     FROM vpagrubricaagrupamento v
    WHERE v.cdagrupamento = pAgrupamento
      AND v.nurubrica = 1
      AND v.cdtiporubrica = 1;

   SELECT V.CDRUBRICAAGRUPAMENTO
     INTO vNuRubCalculada
     FROM vpagrubricaagrupamento v
    WHERE v.cdagrupamento = pAgrupamento
      AND v.nurubrica = pNuRubCalculada
      AND v.cdtiporubrica = pTipoRubrica;

   IF pTipoRubrica = 9 -- Bases de calculo
     THEN

      vFormula := FPROCURAFORMULASBases (vNuRubCalculada);

      vBlocosBase := FRETORNABLOCOSBASES(vCdHistForm);

   ELSE

      vFormula := FPROCURAFORMULAS (vNuRubCalculada, pAnoMesFim);

      vCdVersao := FVERSAOFORMULACALC(vCdFormulacalculo);

      vCdHistForm := FHISTFORMULACALCULO(vCdVersao);

      vCdExpForm := FEXPRESSAOFORMULA(vCdHistForm);

      vBlocosFormula := FRETORNABLOCOSFORMULA(vCdExpForm);

   END IF;

   vFormula := REPLACE(vFormula,'=','');

   vFormula := REPLACE(vFormula,',','.');

   DELETE EPAGRETROATIVOVINCULOFOLHA EPR
    WHERE EPR.CDRUBRICA = vNuRubCalculada
      AND EPR.CDVINCULO = CASE WHEN pCdVinculo IS NOT NULL THEN pCdVinculo
                               ELSE EPR.CDVINCULO END
      AND EPR.ANOMES BETWEEN pAnoMesIni and pAnoMesFim ;

   COMMIT;

   FOR F_RET IN (SELECT distinct cdvinculo FROM EPAGRETROATIVOVINCULO epr
                  WHERE epr.CDVINCULO =  CASE WHEN pCdVinculo IS NOT NULL THEN pCdVinculo
                                               ELSE Epr.CDVINCULO END)

   LOOP
-- Procura as formulas da rubrica
   BEGIN
      FOR f_form IN (select eh.cdfolhapagamento, eh.vlpagamento, vp.nuanomesreferencia, vp.cdorgao,
                            eh.vlindicerubrica, vp.dtcalculo
                        from epaghistoricorubricavinculo eh
                        inner join epagfolhapagamento vp on (eh.cdfolhapagamento = vp.cdfolhapagamento)
                                                             -- and (etf.cdrubricaagrupamento = vCdRubricaAgrupamento)
                      WHERE --vp.cdtipofolha=3
                        --and vp.cdtipocalculo = 1
                        eh.cdvinculo = F_RET.CDVINCULO
                        and eh.cdrubricaagrupamento = vNuRubCalculada
                        and vp.nuanomesreferencia between pAnoMesIni and pAnoMesFim
                        and vp.flcalculodefinitivo='S')

      LOOP

        vFormExp := vFormula;

        vDtFimSubst := null;

        vVlIndice := 0;

        vVlPagamento := f_form.vlpagamento;

        vCdFolha := F_form.Cdfolhapagamento;

        /*vCdVersao := FVERSAOFORMULACALC(f_form.cdformulacalculo);

        vCdHistForm := FHISTFORMULACALCULO(vCdVersao);

        vCdExpForm := FEXPRESSAOFORMULA(vCdHistForm);

        vBlocosFormula := FRETORNABLOCOSFORMULA(vCdExpForm);

        vCdFolha := F_RET.CDFOLHA;

        vFormula := REPLACE(F_FORM.Deformulaexpressao,'=','');

        vFormula := REPLACE(vFormula,',','.');*/

        vCdVinculo := F_RET.CDVINCULO;

        vCdOrgao := f_form.cdorgao;

        vAnoMes := to_char(f_form.nuanomesreferencia);

        vDtCalculo := f_form.dtcalculo;

        vAno := SUBSTR(vAnoMes,1,4);

        /* SELECT epf.CdOrgao, epf.nuanomesreferencia, epf.dtcalculo
           into vCdOrgao, vAnoMes, vDtCalculo
           from EPAGFOLHAPAGAMENTO EPF
          where epf.cdfolhapagamento = vCdFolha;*/

        FOR i IN vBlocosFormula.FIRST .. vBlocosFormula.LAST

        LOOP
          CASE
             WHEN vBlocosFormula(i).SgTipoMnemonico = 'IND'
               THEN
                  -- Verifica se e rubrica de incorporacao com indice e busca
                  vVlIndice := FPERCENTUALINC(F_RET.Cdvinculo, vAnoMes, vNuRubCalculada,
                                              vCdOrgao);

                  if vVlIndice > 100 or vVlIndice = 0  or vVlIndice is null
                     then vVlIndice := f_form.vlindicerubrica;
                  end if;

                  vSgBlocoIndice := vBlocosFormula(i).SgBloco;

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'PossuiDecJudicial'
               THEN
                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, 0);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'QtMesesTrabAno'
               THEN

               SELECT EV.DtAdmissao
               INTO vDtAdm
               from ECADVINCULO EV
               WHERE EV.CDVINCULO = f_ret.cdvinculo;

               IF to_char(vDtAdm,'YYYY') = vAno -- Admitido no ano
                THEN
                  vMesInicio := to_number(to_char(vDtAdm,'MM'));
               ELSE
                vMesInicio := 12;
               END IF;

                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vMesInicio);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'BAS'
               THEN
                 vValorBase := 0;
                 if vBlocosFormula(i).SgBloco = 'A'
                   then
                     vValorBase := FRECALCULABASES('B13SA', pAgrupamento, vAnoMes, F_RET.CdVinculo, vCdFolha, F_form.CdOrgao, pNuRubCalculada);
                 end if;
                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vValorBase);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'RUB'
               THEN
                  vCdFormBlocoExp := FFORMULABLOCOEXPRESSAO(vBlocosFormula(i).CdFormulaCalculoBloco);
                  -- Mnemonico RUB acha as rubricas
                  vInRubricas := FRUBRICASBLOCO(vCdFormBlocoExp);
                  -- Acha as rubricas recalculadas que fazem parte da formula
                  vNotInRubricas := FRUBRICASTMPFORMULA(vCdFolha, vCdVinculo, vCdFormBlocoExp, 3);
                  vVlRubricas := 0;
                  vVlRubCalc := 0;
                  vVlNotInRubricas := 0;
                  -- Somar rubricas da base de calculo da folha
                  vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                          'FROM epagHistoricoRubricaVinculo HRV '||
                          'WHERE HRV.CdFolhaPagamento = :vCdFolha ' ||
                          '  AND HRV.CdVinculo = :vCdVinculo ' ||
                          '  AND HRV.CdRubricaAgrupamento in ( ' || vInRubricas || ')' ;

                  EXECUTE IMMEDIATE vSQL INTO vVlRubricas
                              USING vCdfolha, vCDVINCULO;

                  -- Somar as rubricas a serem descontadas da base original
                  vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                          'FROM epagHistoricoRubricaVinculo HRV '||
                          'WHERE HRV.CdFolhaPagamento = :vCdFolha ' ||
                          '  AND HRV.CdVinculo = :vCdVinculo ' ||
                          '  AND HRV.CdRubricaAgrupamento in ( ' || vNotInRubricas || ')';

                   EXECUTE IMMEDIATE vSQL INTO vVlNotInRubricas
                              USING vCdfolha, vCDVINCULO;

                  -- Somar valor das rubricas recalculadas que fazem parte da formula
                  vSQL := 'SELECT sum(ETR.VlDiferenca) ' ||
                          'FROM EPAGRETROATIVOVINCULOFOLHA ETR '||
                          'WHERE ETR.CdFolha = :vCdFolha ' ||
                          '  AND ETR.CdVinculo = :vCdVinculo ' ||
                          '  AND ETR.CdRubrica in ( ' || vInRubricas || ')';

                  EXECUTE IMMEDIATE vSQL INTO vVlRubCalc
                              USING vCdfolha, vCDVINCULO;

                  -- Ajusta valor para o que deveria ter sido pago
                  --vVlRubCalc := vVlRubricas - f_ret.vlrecebido + f_ret.vldiferenca;

                  vVlRubCalc := vVlRubCalc + (vVlRubricas - vVlNotInRubricas);

                  if vDtFimSubst is not null and vDtFimSubst <= vDtCalculo
                    then
                      vVlRubCalc := vVlRubCalc / 30 * to_number(to_char(vDtFimSubst,'DD'));
                  end if;

                  vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vVlRubCalc);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'BASINC'
               THEN
                   vValorBaseInc := FBASEINC(F_RET.Cdvinculo, vAnoMes, vNuRubCalculada, vCdOrgao);

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vValorBaseInc);

             WHEN vBlocosFormula(i).SgTipoMnemonico = 'APO'
               THEN
                 BEGIN
                 SELECT EAPO.Vlpercentpropapo
                   INTO vPercApo
                   FROM epvdconcessaoaposentadoria EAPO
                  WHERE EAPO.CDVINCULO = F_RET.CDVINCULO
                    AND TO_CHAR(EAPO.DTINICIOAPOSENTADORIA,'YYYYMM') <= vAnoMes
                    AND EAPO.Dtfimaposentadoria is null
                    AND FLANULADO = 'N'
                    AND ROWNUM < 2;

                 EXCEPTION
                   WHEN NO_DATA_FOUND
                     THEN vPercApo := 100;
                 END;

                 if vPercApo is null
                   THEN vPercApo := 100;
                 end if;

                 vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vPercApo);

              /*WHEN vBlocosFormula(i).SgTipoMnemonico = 'CHOProp'
                THEN

                   vNuChoProp := (f_ret.vlrecebido / f_ret.vltabelaori);

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vNuChoProp);*/

              WHEN vBlocosFormula(i).SgTipoMnemonico = 'CCOSubst'
                THEN

                   vVlCco :=  FCCOSUBST(F_RET.CdVinculo, vAnoMes, vCdOrgao, vDtCalculo);

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vVlCco);

              WHEN vBlocosFormula(i).SgTipoMnemonico = 'CELG'
                THEN

                   vVlCelg := FMneCELG(670, 1, vAnoMes, 13, 'A');

                   vFormExp := REPLACE(vFormExp, vBlocosFormula(i).SgBloco, vVlCelg);

           END CASE;
         END LOOP;

         vVlCalculado := PKGMATH.FCalcular(vFormExp);

         IF vVlCalculado < vVlPagamento or vVlCalculado is null
           THEN
             vVlCalculado := vVlPagamento;
         END IF;

         PINCLUIRETROATIVO (vCdOrgao,  vCdVinculo, vCdFolha, vNuRubCalculada,
                            vAnoMes, vVlPagamento,  vVlCalculado, null);

         --END IF;

      END LOOP;
    END;

    END LOOP;
END PRECALCULA13;

--
-- Recalcular as bases de calculo de ferias e 13?
--
FUNCTION FRECALCULABASES (pBase char, pAgrupamento number, pAnoMes char,
                          pCdVinculo number, pCdFolha number, pCdOrgao number, pNuRubCalculada number) return number is

--vBlocosFormula PKGPAG_RETROATIVO.tBlocos;
vInRubricas string(5000);
vNotInRubricas string(5000);
--vVlIndice number(13,2);
vVlRubricas number(13,2);
vVlRubCalc number(13,2);
--vVlRubCalcB number(13,2);
vVlRubDiminui number(13,2);
vVlRubMedia number(13,2);
vVlMediaTempo number(13,2);
vVlSomaE      number(13,2);
vVlSomaF      number(13,2);
--vVlSomaG      number(13,2);
vVlSomaH      number(13,2);
vVlSomaI      number(13,2);
vVlSomaJ      number(13,2);
--vVlBaseAnt    number(13,2);
--vVlBaseRecalculo number(13,2);
--vCdFormBlocoExp number;
vSQL VARCHAR2(4000);
vCdFolha number;
--vCdVinculo number;
--vVlCalculado number(13,2);
--vVlPagamento number(13,2);
--vFormula varchar2(200);
--vFormExp varchar2(200);
--vValorFormula varchar2(15);
--vCdOrgao number;
--vAnoMes char(6);
--vNuCho number;
--vSgBlocoIndice char;
--vValorBaseInc number(13,2);
--vPercApo number(5,2) := 100;
--vNuChoProp number(5,2);
--vVlCco number(13,2);
--vDtCalculo DATE;
--vVlCelg number(13,2);
vNuRubMedia number;
vVlNotInRubricas number(13,2);
vAno       integer := SUBSTR(pAnoMes,1,4);
vMes       integer := SUBSTR(pAnoMes,5,2);
vMesInicio integer;
vDtAdm     DATE;

BEGIN

   CASE
      WHEN pBase = 'BFER' -- Base de F?rias
        -- Para a base de ferias deve ser calculado com base no mes anterior ao da rubrica
        -- paga
        /* Sigla Express?o
         A =[RUB:P;GR1;R;AT]
         B =[RUB:P;GR2;R;AT]
         C =[MEDIATempo:P;010108;R;12;V;V]  */

         then

         vAnoMesFerias := pAnoMes;

         if pNuRubCalculada = 56
           then
             IF pAnoMes = '201412'
               THEN
                 RETURN 0;
             END IF;

             IF SUBSTR(pAnoMes,5,2) = 12
               THEN
                 vAnoMesFerias := SUBSTR(pAnoMes,1,4) + 1 || '01';
             ELSE
                 vAnoMesFerias := pAnoMes + 1;
             END IF;
         END IF;
         -- Para ferias procurar a folha normal, calculo normal do proximo mes ao recebido
         begin

         select distinct(vp.cdfolhapagamento)
             into vCdFolhaFerias
             from epaghistoricorubricavinculo eh
             inner join epagfolhapagamento vp on vp.cdfolhapagamento = eh.cdfolhapagamento
                                             and vp.nuanomesreferencia=vAnoMesFerias
             where cdvinculo = pCdVinculo
             and vp.flcalculodefinitivo='S'
             and vp.flcalculodefinitivo = 'S'
             and vp.cdtipocalculo = 1
             and vp.cdtipofolhaPAGAMENTO = 2
             AND VP.CDAGRUPAMENTO = 1
             and rownum <2;

         exception
           when no_data_found
             then

             begin
             SELECT vfp.CdFolhaPagamento
               INTO vCdFolhaFerias
               FROM epagfolhapagamento vfp
               WHERE vfp.nuanomesreferencia = to_number(vAnoMesFerias)
               --and vfp.cdtipocalculo = 1
               --and vfp.cdtipofolhaPAGAMENTO = 2
               AND vfp.cdorgao = pCdOrgao
               AND vfp.cdagrupamento = pAgrupamento
               AND vfp.flcalculodefinitivo = 'S';
             exception
                when others
                  then
                    vCdFolhaFerias := 0;
             end;
         end;

         -- Calculo bloco A
         vVlRubricas := 0;
         vVlRubCalc := 0;
         vVlNotInRubricas := 0;
         vVlRubDiminui := 0;
         vVlMediaTempo := 0;

         vInRubricas := FRUBRICASBLOCOBASE(pBase,'A');

         vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                   'FROM epagHistoricoRubricaVinculo HRV '||
                  'WHERE HRV.CdFolhaPagamento = :vCdFolhaFerias ' ||
                  '  AND HRV.CdVinculo = :pCdVinculo ' ||
                  '  AND HRV.CdRubricaAgrupamento in ( ' || vInRubricas || ')' ;

         EXECUTE IMMEDIATE vSQL INTO vVlRubricas
                     USING vCdfolhaFerias, pCDVINCULO;

         -- Recalculo Bloco A

         -- Somar valor das rubricas recalculadas que fazem parte da formula
         vSQL := 'SELECT sum(ETR.VlDiferenca), sum(ETR.VlRecebido) ' ||
                   'FROM EPAGRETROATIVOVINCULOFOLHA ETR '||
                  'WHERE ETR.CdFolha = :vCdFolhaFerias ' ||
                  '  AND ETR.CdVinculo = :pCdVinculo ' ||
                  '  AND ETR.CdRubrica in ( ' || vInRubricas || ')';

         EXECUTE IMMEDIATE vSQL INTO vVlRubCalc, vVlNotInRubricas
                     USING pCdfolha, pCDVINCULO;

         -- Codigos das rubricas reprocessadas no retroativo
         /*vNotInRubricas := FRUBRICASTMPBASE(pCdFolha, pCdVinculo);

         if vNotInRubricas is null
           then
             vNotInRubricas := 0;
         end if;
           */
        /* vSQL := 'SELECT sum(ETR.VlRecebido) ' ||
                   'FROM EPAGRETROATIVOVINCULOFOLHA ETR '||
                  'WHERE ETR.CdFolha = :vCdFolhaFerias ' ||
                  '  AND ETR.CdVinculo = :pCdVinculo ' ||
                  '  AND ETR.CdRubrica in ( ' || vNotInRubricas || ')'; */

         /*vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                   'FROM epagHistoricoRubricaVinculo HRV '||
                  'WHERE HRV.CdFolhaPagamento = :vCdFolhaFerias ' ||
                  '  AND HRV.CdVinculo = :pCdVinculo ' ||
                  '  AND HRV.CdRubricaAgrupamento in ( ' || vNotInRubricas || ')' ;   */

         /*EXECUTE IMMEDIATE vSQL INTO vVlNotInRubricas
                     USING vCdfolhaFerias, pCDVINCULO; */

         IF vVlNotInRubricas is null
           THEN
             vVlNotInRubricas := 0;
         END IF;

         vVlRubCalc := vVlRubCalc + (vVlRubricas - vVlNotInRubricas);

         -- Calculo Bloco B

         vInRubricas := FRUBRICASBLOCOBASE(pBase,'B');

         -- Somar rubricas da base de calculo da folha
         vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                   'FROM epagHistoricoRubricaVinculo HRV '||
                  'WHERE HRV.CdFolhaPagamento = :vCdFolhaFerias ' ||
                  '  AND HRV.CdVinculo = :pCdVinculo ' ||
                  '  AND HRV.CdRubricaAgrupamento in ( ' || vInRubricas || ')' ;

         EXECUTE IMMEDIATE vSQL INTO vVlRubDiminui
                      USING vCdfolhaFerias, pCDVINCULO;

         -- Media tempo -- 12 meses da rubrica 01-0108

         SELECT V.CDRUBRICAAGRUPAMENTO
           INTO vNuRubMedia
           FROM vpagrubricaagrupamento v
          WHERE v.cdagrupamento = pAgrupamento
            AND v.nurubrica = 108
            AND v.cdtiporubrica = 1;

         vVlRubMedia := FMneMediaTempo(pCdVinculo, vAno, vMes , 1, -- pCdTipoRubrica,
                                        pAgrupamento,
                                       vNuRubMedia, 12, -- pNuMesesRetroativos
                                       108, 1, 1) ;
         if vVlRubMedia <> 0
           then
             vVlRubMedia := vVlRubMedia;
         end if;

         -- Calculo da Base

         IF vVlRubDiminui is null
           THEN
             vVlRubDiminui := 0;
         END IF;

         vVlRubCalc := vVlRubCalc + vVlRubMedia - vVlRubDiminui;

         vVlRub1056 := vVlRubricas + vVlRubMedia - vVlRubDiminui;

          -- Rubrica da diferenca ja paga no mes posterior que deve ser somada a 1056
         vVlRub1156 := 0;

         if pNuRubCalculada = 56
           then

            BEGIN

            SELECT HRV.VlPagamento
              INTO vVlRub1156
              FROM epagHistoricoRubricaVinculo HRV
             WHERE HRV.CdFolhaPagamento = vCdFolhaFerias
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento = 10095;

             EXCEPTION
               WHEN NO_DATA_FOUND
                THEN
                 vVlRub1156 := 0;
             END;
          end if;

         --vVlRub1056 := vVlRub1056 + vVlRub1156;

         -- Aplicar formula
         -- B =[IND] N
        -- A =[BAS:BFER] S
        -- C =[BAS:FEJUD] N
        -- D =[PossuiDecJudicial:011056]
         -- (A+(C*D))/3/30*B

         /*vVlRubCalc := vVlRubCalc*/

       WHEN pBase = 'B13SA' -- (A+(E/G)+(F/G))-B-(H-I)+J
         THEN
          /*A =[RUB:P;GR1;R;AT]
           B =[RUB:P;GR2;R;AT]
           E =[SOMAAno:P;010180;R]
           F =[SOMAAno:P;010108;R]
           G =[Mes da Folha]
           H =[SOMAAno:P;011023;R]
           I =[SOMAAno:P;050524;R]
           J =[SOMAAno:P;081023;R]*/

         -- Calculo bloco A
         vVlRubricas := 0;
         vVlRubCalc := 0;
         vVlNotInRubricas := 0;
         vVlRubDiminui := 0;
         vVlMediaTempo := 0;

         SELECT vfp.CdFolhaPagamento
           INTO vCdFolha
           FROM epagfolhapagamento vfp
          WHERE vfp.nuanomesreferencia = pAnoMes
            --AND vfp.cdtipofolha = 1
            --AND vfp.cdtipocalculo = 1
            AND vfp.cdorgao = pCdOrgao
            AND vfp.cdagrupamento = pAgrupamento
            AND vfp.flcalculodefinitivo = 'S';

         vInRubricas := FRUBRICASBLOCOBASE(pBase,'A');

         vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                   'FROM epagHistoricoRubricaVinculo HRV '||
                  'WHERE HRV.CdFolhaPagamento = :vCdFolha ' ||
                  '  AND HRV.CdVinculo = :pCdVinculo ' ||
                  '  AND HRV.CdRubricaAgrupamento in ( ' || vInRubricas || ')' ;

         EXECUTE IMMEDIATE vSQL INTO vVlRubricas
                     USING vCdfolha, pCDVINCULO;

         -- Recalculo Bloco A

         -- Somar valor das rubricas recalculadas que fazem parte da formula
         vSQL := 'SELECT sum(ETR.VlDiferenca) ' ||
                   'FROM EPAGRETROATIVOVINCULOFOLHA ETR '||
                  'WHERE ETR.CdFolha = :vCdFolha ' ||
                  '  AND ETR.CdVinculo = :pCdVinculo ' ||
                  '  AND ETR.CdRubrica in ( ' || vInRubricas || ')';

         EXECUTE IMMEDIATE vSQL INTO vVlRubCalc
                     USING vCdfolha, pCDVINCULO;

         -- Codigos das rubricas reprocessadas no retroativo
         vNotInRubricas := FRUBRICASTMPBASE(vCdFolha, pCdVinculo);

         if vNotInRubricas is null
           then
             vNotInRubricas := 0;
           end if;

         vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                   'FROM epagHistoricoRubricaVinculo HRV '||
                  'WHERE HRV.CdFolhaPagamento = :vCdFolha ' ||
                  '  AND HRV.CdVinculo = :pCdVinculo ' ||
                  '  AND HRV.CdRubricaAgrupamento in ( ' || vNotInRubricas || ')' ;

         EXECUTE IMMEDIATE vSQL INTO vVlNotInRubricas
                     USING vCdfolha, pCDVINCULO;

         vVlRubCalc := vVlRubCalc + (vVlRubricas - vVlNotInRubricas);

         -- Calculo Bloco B

         vInRubricas := FRUBRICASBLOCOBASE(pBase,'B');

         -- Somar rubricas da base de calculo da folha
         vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
                   'FROM epagHistoricoRubricaVinculo HRV '||
                  'WHERE HRV.CdFolhaPagamento = :vCdFolha ' ||
                  '  AND HRV.CdVinculo = :pCdVinculo ' ||
                  '  AND HRV.CdRubricaAgrupamento in ( ' || vInRubricas || ')' ;

         EXECUTE IMMEDIATE vSQL INTO vVlRubDiminui
                      USING vCdfolha, pCDVINCULO;

         if vVlRubDiminui is null
           then
             vVlRubDiminui := 0;
         end if;

         -- Bloco E
         -- Media ano 01-0180

         SELECT V.CDRUBRICAAGRUPAMENTO
           INTO vNuRubMedia
           FROM vpagrubricaagrupamento v
          WHERE v.cdagrupamento = pAgrupamento
            AND v.nurubrica = 180
            AND v.cdtiporubrica = 1;

         vVlSomaE := FSomarAno(pCdVinculo, vAno, vMes, pAgrupamento, vNuRubMedia, 1, 180);

         -- Bloco F
         -- Media ano 01-0108

         SELECT V.CDRUBRICAAGRUPAMENTO
           INTO vNuRubMedia
           FROM vpagrubricaagrupamento v
          WHERE v.cdagrupamento = pAgrupamento
            AND v.nurubrica = 108
            AND v.cdtiporubrica = 1;

         vVlSomaF := FSomarAno(pCdVinculo, vAno, vMes, pAgrupamento,vNuRubMedia, 1, 108);

         -- Bloco H
         -- Media ano 01-1023

         SELECT V.CDRUBRICAAGRUPAMENTO
           INTO vNuRubMedia
           FROM vpagrubricaagrupamento v
          WHERE v.cdagrupamento = pAgrupamento
            AND v.nurubrica = 1023
            AND v.cdtiporubrica = 1;

         vVlSomaH := FSomarAno(pCdVinculo, vAno, vMes, pAgrupamento,vNuRubMedia, 1, 1023);

         -- Bloco I
         -- Media ano 05-0524

         SELECT V.CDRUBRICAAGRUPAMENTO
           INTO vNuRubMedia
           FROM vpagrubricaagrupamento v
          WHERE v.cdagrupamento = pAgrupamento
            AND v.nurubrica = 524
            AND v.cdtiporubrica = 5;

         vVlSomaI := FSomarAno(pCdVinculo, vAno, vMes, pAgrupamento, vNuRubMedia, 1, 524);

         -- Bloco J
         -- Media ano 05-0524

         SELECT V.CDRUBRICAAGRUPAMENTO
           INTO vNuRubMedia
           FROM vpagrubricaagrupamento v
          WHERE v.cdagrupamento = pAgrupamento
            AND v.nurubrica = 1023
            AND v.cdtiporubrica = 8;

         vVlSomaJ := FSomarAno(pCdVinculo, vAno, vMes, pAgrupamento, vNuRubMedia, 8, 1023);

         -- Calculo da Base
         -- (A+(E/G)+(F/G))-B-(H-I)+J

         vVlRubCalc := (vVlRubCalc + (vVlSomaE/vMes) + (vVlSomaF/vMes)) -
                        vVlRubDiminui - (vVlSomaH - vVlSomaI) + vVlSomaJ ;

         -- Formula
        -- A =[BAS:B13SA] N
        -- B =[QtMesesTrabAno] N
        -- C =[BAS:B13JU] N
        -- D =[PossuiDecJudicial:011025] N
         -- (A+(C*D))*(B/12)

         SELECT EV.DtAdmissao
           INTO vDtAdm
           from ECADVINCULO EV
          WHERE EV.CDVINCULO = PCDVINCULO;

         IF to_char(vDtAdm,'YYYY') = vAno -- Admitido no ano
           THEN
             vMesInicio := to_number(to_char(vDtAdm,'MM'));
         ELSE
             vMesInicio := 12;
         END IF;

         -- Aplicar formula
         vVlRubCalc := vVlRubCalc * vMesInicio / 12;

    END CASE;

    RETURN vVlRubCalc;

END FRECALCULABASES;

--
-- Procedure criada para calcular a rubrica 01-0056 com base em um determinado ano/mes
-- e a partir de alguns vinculos
--
PROCEDURE PRECALCULABASEFERIAS (pBase char, pAgrupamento number) is

vInRubricas string(5000);
vNotInRubricas string(5000);
vVlRubricas number(13,2);
vVlRubDiminui number(13,2);
vVlRubMedia number(13,2);
vSQL VARCHAR2(4000);
vNuRubMedia number;
--vVlNotInRubricas number(13,2);

BEGIN

 delete epagretroativovinculofolha
  where cdpagretroativo=5;

 commit;

 vAnoMesFerias := 201411;

 vInRubricas := FRUBRICASBLOCOBASE(pBase,'A');

 vNotInRubricas := FRUBRICASBLOCOBASE(pBase,'B');

 SELECT V.CDRUBRICAAGRUPAMENTO
       INTO vNuRubMedia
       FROM vpagrubricaagrupamento v
      WHERE v.cdagrupamento = pAgrupamento
        AND v.nurubrica = 108
        AND v.cdtiporubrica = 1;

 FOR C_VINC IN (SELECT CDVINCULO, CDULTFOLHA, EUF.CDORGAOULTFOLHA
                  FROM EPAGRETROATIVOVINCULTFOLHA EUF
                 WHERE CDPAGRETROATIVO = 5
                 and cdvinculo = 111387)

 LOOP
    -- Para ferias procurar a folha normal, calculo normal do proximo mes ao recebido

     -- Calculo bloco A
     vVlRubricas := 0;
     vVlRubDiminui := 0;
     vVlRubMedia := 0;

     vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
               'FROM epagHistoricoRubricaVinculo HRV '||
              'WHERE HRV.CdFolhaPagamento = :vCdFolhaFerias ' ||
              '  AND HRV.CdVinculo = :pCdVinculo ' ||
              '  AND HRV.CdRubricaAgrupamento in ( ' || vInRubricas || ')' ;

     EXECUTE IMMEDIATE vSQL INTO vVlRubricas
                 USING C_VINC.CDULTFOLHA, C_VINC.CDVINCULO;

     -- Calculo Bloco B
     -- Somar rubricas da base de calculo da folha
     vSQL := 'SELECT sum(HRV.VlPagamento) ' ||
               'FROM epagHistoricoRubricaVinculo HRV '||
              'WHERE HRV.CdFolhaPagamento = :vCdFolhaFerias ' ||
              '  AND HRV.CdVinculo = :pCdVinculo ' ||
              '  AND HRV.CdRubricaAgrupamento in ( ' || vNotInRubricas || ')' ;

     EXECUTE IMMEDIATE vSQL INTO vVlRubDiminui
                  USING C_VINC.CDULTFOLHA, C_VINC.CDVINCULO;

     -- Media tempo -- 12 meses da rubrica 01-0108
     -- Calculo Bloco C

     vVlRubMedia := FMneMediaTempo(C_VINC.CdVinculo, '2014', '10' , 1, -- pCdTipoRubrica,
                                    pAgrupamento,
                                    vNuRubMedia, 12, -- pNuMesesRetroativos
                                    108, 1, 1) ;
     -- Calculo da Base

     IF vVlRubDiminui is null
       THEN
         vVlRubDiminui := 0;
     END IF;

     PINCLUIRETROATIVO (C_VINC.CDORGAOULTFOLHA, C_VINC.CDVINCULO, C_VINC.CDULTFOLHA,
                        10405, 201411, ((NVL(vVlRubricas,0) + NVL(vVlRubMedia,0) - NVL(vVlRubDiminui,0)) / 3),
                        0, null, 5, 0);

 END LOOP;

END PRECALCULABASEFERIAS;

PROCEDURE PINCLUIRETROATIVO (pCdOrgao number, pCdVinculo number, pCdFolhaPagamento number,
                             pCdRubricaAgrupamento number, pAnoMes char,
                             pVlPagamento number, pVlProgressao number, pCdProcesso number DEFAULT NULL,
                             pCdPagRetroativo number DEFAULT NULL,
                             pVlRetroativo number DEFAULT 0) IS

BEGIN

   /*UPDATE ETMPRETROATIVO ETT
      SET ETT.VLDIFERENCA = pVlProgressao
    WHERE ETT.CDORGAO = pCdOrgao
      AND ETT.CDVINCULO = pCdVinculo
      AND ETT.CDFOLHA = pCdFolhaPagamento
      AND ETT.CDRUBRICA = pCdRubricaAgrupamento
      AND ETT.ANOMES = PANOMES;

   COMMIT;

   IF SQL%NOTFOUND
      then
         RAISE NO_DATA_FOUND;
   END IF;

   EXCEPTION

   WHEN NO_DATA_FOUND THEN   */
      INSERT INTO EPAGRETROATIVOVINCULOFOLHA (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,
                                              ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA, CDPAGRETROATIVOPROCESSO,
                                              CDPAGRETROATIVO, VLOUTRORETROATIVO)

      VALUES(pCdorgao, pCDVINCULO, pCDFOLHAPAGAMENTO, pCDRUBRICAAGRUPAMENTO,
             pAnoMes, pVLPAGAMENTO, 0, 0, pVlProgressao, pCdProcesso, pCdPagRetroativo, pVlRetroativo);

   COMMIT;

END PINCLUIRETROATIVO;

PROCEDURE PRECALCULADECIMO (pAnoMes CHAR, pCdProcesso NUMBER) IS
--
-- Recalcular o 13? com base somente nas diferen?as das rubricas que comp?e a base sem processar as formulas
--  por ano e mes, o mes de referencia para calculo ? sempre NOVEMBRO, portanto o parametro a ser passado ? 200711
-- 200811, etc

vAnoMes char(6);
vValor  number(13,2);
vCdFolha number;
vCdProcesso number;
vCdPagRetroativoProcesso number;
vVlRetroativo number(13,2);

begin

  delete epagretroativovinculofolha epr
   where epr.cdrubrica = 10339
     and epr.cdpagretroativo = pCdProcesso
     and epr.anomes = SUBSTR(pAnoMes,1,4) || '12';

  commit;

  for f_ret in (select distinct cdvinculo, cdpagretroativo--, cdpagretroativoprocesso
                from epagretroativovinculofolha
                where anomes=pAnoMes
                  and cdpagretroativo = pCdProcesso)
                --select epc.cdvinculo, epc.cdprocessoretroativo  from epagretroativoprocesso epc)
  loop
    for f_prog in (select eh.cdfolhapagamento, eh.vlpagamento, vp.nuanomesreferencia, vp.cdorgao,
                            eh.vlindicerubrica, vp.dtcalculo
                        from epaghistoricorubricavinculo eh
                        inner join epagfolhapagamento vp on (eh.cdfolhapagamento = vp.cdfolhapagamento)
                                                             -- and (etf.cdrubricaagrupamento = vCdRubricaAgrupamento)
                      WHERE --vp.cdtipofolha=3
                        --and vp.cdtipocalculo = 1
                        eh.cdvinculo = F_RET.CDVINCULO
                        and eh.cdrubricaagrupamento = 10339
                        and vp.nuanomesreferencia = pAnoMes
                        and vp.flcalculodefinitivo='S')--select * from epagretroativovinculofolha
               --where cdrubrica=10339 and anomes between '201201' and '201212')

    loop
      vAnoMes := f_prog.nuanomesreferencia + 1;

      begin

      select sum(vldiferenca - vlrecebido), epr.cdfolha, epr.cdpagretroativo
        into vValor , vCdFolha, vCdProcesso
        from epagretroativovinculofolha epr
       where epr.cdvinculo = f_ret.cdvinculo
       and   epr.anomes = vAnoMes
       and epr.cdrubrica <> 10405 --in (10724,10411,8336,8342,8858)
       and epr.cdpagretroativo = pCdProcesso
       --and epr.cdpagretroativoprocesso = f_ret.cdprocessoretroativo
       group by epr.cdfolha, epr.cdpagretroativo;
       exception
         when no_data_found
           then
             continue;

       if vValor < 0 or vValor is null
         then
           vValor := 0;
       end if;
       end;

        IF pCdProcesso = 3
           then
             vVlRetroativo := NVL(FOUTROVALORPAGORETROATIVO( f_ret.CdVinculo, vCdFolha, 10339, 4),0);

        END IF;

        BEGIN

        SELECT ert.cdprocessoretroativo
          INTO vCdPagRetroativoProcesso
          from epagretroativoprocesso ert
           where ert.cdvinculo = f_ret.cdvinculo;

        EXCEPTION
          WHEN OTHERS THEN
             vCdPagRetroativoProcesso := 0;

       END;

       INSERT INTO EPAGRETROATIVOVINCULOFOLHA
       (CDORGAO, CDVINCULO, CDFOLHA, CDRUBRICA,ANOMES,VLRECEBIDO,VLTABELAORI,VLTABELADEST,VLDIFERENCA,
        CDPAGRETROATIVOPROCESSO, CDPAGRETROATIVO, VLOUTRORETROATIVO)
       VALUES(f_prog.cdorgao, f_ret.cdvinculo, vCdFolha, 10339,
              vAnoMes, f_prog.vlpagamento, 0, 0, f_prog.vlpagamento+vvalor, vcdpagretroativoprocesso,
              pCdProcesso, vVlRetroativo );
       commit;

--       dbms_output.put_line('Recebido:' || to_char(f_prog.vlrecebido) || ' Calculado: ' || to_char(vValor) || ' Total: ' || to_char(f_prog.vlrecebido + vValor));

    end loop;
  end loop;

end PRECALCULADECIMO;
/*PROCEDURE PPROCURAFORMULAS (pNuRubrica number, pTipoRubrica number, pAgrupamento number) IS

vCount number := 0;
vCdRubricaAgrupamento number;
vDescricao char(30);
vRubrica char(7);
vCdVersao number;
vCdHistForm number;
vDeFormulaExpressao string(50);
vCdExpForm number;
vBlocosFormula PKGPAG_RETROATIVO.tBlocos;
vCdFormBlocoExp number;
vInRubricas string(5000);

BEGIN

     SELECT V.CDRUBRICAAGRUPAMENTO
       INTO vCdRubricaAgrupamento
       FROM Vpagrubrica v
      WHERE v.cdagrupamento = pAgrupamento
        AND v.nurubrica = pNuRubrica
        AND v.cdtiporubrica = pTipoRubrica;

      DELETE EPAGRETROATIVOFORMULA ETF
         WHERE ETF.CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupamento;

      INSERT INTO EPAGRETROATIVOFORMULA
      SELECT DISTINCT PAGA88.CDFORMULACALCULO, PAGA88.CDRUBRICAAGRUPAMENTO, PAG126.CDRUBRICAAGRUPAMENTO,
        PAG115.DEFORMULAEXPRESSAO, PAGA88.DEFORMULACALCULO,
        LPAD(VP.CDTIPORUBRICA,2,0) || '-' || LPAD(VP.nurubrica,4,0) || ' -> ' || VP.derubricaagrupamento,
        'N'
        FROM EPAGFORMULACALCULO PAGA88
       INNER JOIN VPAGRUBRICA VP ON (VP.cdrubricaagrupamento = PAGA88.CDRUBRICAAGRUPAMENTO)
       INNER JOIN EPAGFORMULAVERSAO PAG112
               ON (PAG112.CDFORMULACALCULO = PAGA88.CDFORMULACALCULO)
       INNER JOIN EPAGHISTFORMULACALCULO PAG116
               ON (PAG116.CDFORMULAVERSAO = PAG112.CDFORMULAVERSAO AND PAG116.NUANOFIM IS NULL)
       INNER JOIN EPAGEXPRESSAOFORMCALC PAG115
               ON (PAG115.CDHISTFORMULACALCULO = PAG116.CDHISTFORMULACALCULO)
       INNER JOIN EPAGFORMULACALCULOBLOCO PAG113
               ON (PAG113.CDEXPRESSAOFORMCALC = PAG115.CDEXPRESSAOFORMCALC)
       INNER JOIN EPAGFORMULACALCBLOCOEXPRESSAO PAG114
               ON (PAG113.CDFORMULACALCULOBLOCO = PAG114.CDFORMULACALCULOBLOCO)
       INNER JOIN EPAGFORMCALCBLOCOEXPRUBAGRUP PAG126
               ON (PAG114.CDFORMULACALCBLOCOEXPRESSAO = PAG126.CDFORMULACALCBLOCOEXPRESSAO)
       INNER JOIN EPAGRUBRICAAGRUPAMENTO ERUBA
               ON (ERUBA.CDRUBRICAAGRUPAMENTO = PAGA88.CDRUBRICAAGRUPAMENTO)
       INNER JOIN EPAGRUBRICA EPR ON (EPR.CDRUBRICA = ERUBA.CDRUBRICA AND EPR.CDTIPORUBRICA=1)
       WHERE PAG126.CDRUBRICAAGRUPAMENTO=vCdRubricaAgrupamento;

      COMMIT;

      \*FOR f_form IN (
        SELECT * FROM ETMPFORMULARUBRICA
                WHERE CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupamento)

      LOOP

        BEGIN
          Select 1
            INTO vCount
            from vpagfolhapagamento vp
            inner join epaghistoricorubricavinculo eh on (eh.cdfolhapagamento=vp.cdfolhapagamento)
            where  vp.nuanomesreferencia between '200701' and '201212'
              and vp.flcalculodefinitivo = 'S'
              and eh.cdrubricaagrupamento = f_form.cdrubricaformula --vCdRubricaAgrupamento
              AND ROWNUM<2;

        IF vCount > 0
            THEN

               UPDATE ETMPFORMULARUBRICA ETF
                  SET ETF.FLTEMFOLHA='S'
                WHERE ETF.CDFORMULACALCULO = F_FORM.CDFORMULACALCULO;

               COMMIT;

               vCdVersao := FVERSAOFORMULACALC(f_form.cdformulacalculo);

               vCdHistForm := FHISTFORMULACALCULO(vCdVersao);

               vCdExpForm := FEXPRESSAOFORMULA(vCdHistForm);

               \*SELECT LPAD(V.CDTIPOrubrica,2,0) || '-' || LPAD(V.nurubrica,4,0)
                 INTO VRUBRICA
                 FROM VPAGRUBRICA V
                WHERE V.cdrubricaagrupamento = F_FORM.CDRUBRICAFORMULA AND ROWNUM < 2;

               SELECT substr(ER.DERUBRICAAGRUPAMENTO,1,30) into vDescricao
                 FROM EPAGHISTRUBRICAAGRUPAMENTO ER
                WHERE ER.CDRUBRICAAGRUPAMENTO = F_FORM.CDRUBRICAFORMULA
                  AND ROWNUM < 2;
               DBMS_OUTPUT.put_line (vRubrica || ' -> ' || vDescricao || ' Formula: ' || f_form.deformulaexpressao);
             --  F_FORM.DEFORMULACALCULO || ' - ' || F_FORM.DERUBRICAAGRUPAMENTO);*\

             DBMS_OUTPUT.put_line (F_FORM.DERUBRICA || '              Formula: ' || f_form.deformulaexpressao);

             \*vBlocosFormula := FRETORNABLOCOSFORMULA(vCdExpForm);

             FOR i IN vBlocosFormula.FIRST .. vBlocosFormula.LAST

             LOOP
                 DBMS_OUTPUT.put_line (vBlocosFormula(i).SgBloco || ' - Mnemonico: ' ||
                                       vBlocosFormula(i).CdTipoMnemonico || ' -> ' ||
                                       vBlocosFormula(i).SgTipoMnemonico);

                 IF vBlocosFormula(i).SgTipoMnemonico = 'RUB' THEN
                    vCdFormBlocoExp := FFORMULABLOCOEXPRESSAO(vBlocosFormula(i).CdFormulaCalculoBloco);
                    vInRubricas := FRUBRICASBLOCO(vCdFormBlocoExp); -- Mnemonico RUB acha as rubricas
                    DBMS_OUTPUT.put_line ('RUBRICAS: ' || vInRubricas);

                 END IF;*\
             END LOOP;*\

        END IF;
         exception
             when no_data_found then
               vCount:=0;
         end;

         vCount := 0;

      END LOOP;
*\
END PPROCURAFORMULAS;*/
--
-- Acertar o valor inicial da produtividade para as rubricas informadas
-- e posteriormente comparar as diferen?as do recebido x devido
--
PROCEDURE PACERTAPROGRESSAO (pNuRubrica number)  IS

vCdRubricaAgrupamento       number;
--vCdRubrica1001              number;
--vVl1001                     number(13,2);
--vVlTabela                   number(13,2);
vCdTipoAtipratFaz           number;
vVlProdutividade            number(13,2);
vNuNivelOrigem              char(2);
--vNuNivelDestino             char(2);
vNuReferenciaOrigem         char(1);
--vNuReferenciaDestino        char(1);
vCdEstruturaCarreiraOrigem  number;
--vCdEstruturaCarreiraDestino number;

BEGIN

   -- Busca o c?digo da rubrica
   SELECT R.CdRubricaAgrupamento
     INTO vCdRubricaAgrupamento
     FROM vpagrubricaagrupamento R
    WHERE R.nurubrica = pNuRubrica
      AND r.cdtiporubrica = 1
      AND r.cdagrupamento = 1;

   -- Busca c?digo da atividade fazendaria para a rubricas de produtividade
    SELECT evp.cdtipogratativfazendaria
      INTO vCdTipoAtipratFaz
      FROM epageventopagagrup eva
     INNER JOIN epaghisteventopagagrup evp on (evp.cdeventopagagrup = eva.cdeventopagagrup)
     where eva.cdrubricaagrupamento = vCdRubricaAgrupamento
     and rownum=1;

    BEGIN
      FOR f_rec IN (Select DISTINCT CDVINCULO, CDFOLHA, CDORGAO, ANOMES
                      FROM EPAGRETROATIVOVINCULOFOLHA
                     where CDRUBRICA = vCdRubricaAgrupamento)

      LOOP
          SELECT NuNivelOrigem, NuReferenciaOrigem, CdEstruturaCarreiraOrigem
            INTO vNuNivelOrigem, vNuReferenciaOrigem, vCdEstruturaCarreiraOrigem
            FROM EPAGRETROATIVOVINCULO
           WHERE CDVINCULO =  f_rec.CDVINCULO
             AND DTINICIO = (SELECT MIN(DTINICIO)
                               FROM EPAGRETROATIVOVINCULO
                              WHERE CDVINCULO = f_rec.CDVINCULO);

          -- Buscar o valor da tabela de produtividade PAGO para comparar com o RECEBIDO
          -- e proporcionalizar se for o caso
          --
          vVlProdutividade := FRetornaValorFixoGrat(f_rec.CDVINCULO, vCDESTRUTURACARREIRAORIGEM,
                                                    vNuNivelOrigem, vNureferenciaorigem,
                                                    vCdTipoAtipratFaz, F_REC.ANOMES, F_REC.CDFOLHA,
                                                    pNuRubrica, F_REC.Cdorgao);

          UPDATE EPAGRETROATIVOVINCULOFOLHA eprf
             SET eprf.vltabelaori = vVlProdutividade
           WHERE EPRF.CDVINCULO = F_REC.CDVINCULO
             AND EPRF.CDFOLHA = F_REC.CDFOLHA
             AND EPRF.CDRUBRICA = vCdRubricaAgrupamento
             AND EPRF.ANOMES = F_REC.ANOMES;

          COMMIT;

      END LOOP;

     END;

END PACERTAPROGRESSAO ;

procedure preprocessarubricasret (pnurubrica number) is

begin

for c_proc in (select distinct cdvinculo
               from epagretroativovinculofolha
               where cdrubrica in (8220,8566))

    loop
      pkgpag_retroativo.precalcularubricas(ptiporubrica => 1,
                                           pagrupamento => 1,
                                           pnurubfatogerador => 1,
                                           pnurubcalculada => pnurubrica,
                                           pcdvinculo => c_proc.cdvinculo,
                                           panomesini => '200701',
                                           panomesfim => '201212',
                                           pcdprocesso => 1);

    end loop;

end preprocessarubricasret;

--
-- Ajustar valores das rubricas criando a tabela EPAGRETROATIVOVINCULOFOLHAARQ
-- para descontar as rubricas com valores negativos das rubricas com valores positivos.
--
procedure PAJUSTAVALORESRUBRICAS IS

  VVALOR NUMBER(13,2) :=0;
  VVALORDEB NUMBER(13,2) :=0;
begin

  -- Test statements here
  DELETE EPAGRETROATIVOVINCULOFOLHAARQ
  COMMIT;
  FOR F_PAG IN (select r.cdfolha, r.cdvinculo, r.cdrubrica, r.vlretroativo
                  from epagretroativovinculofolha r
     where cdrubrica in (10730,8220,10700,8566) -- and cdvinculo=124554 --and anomes='201103'
     and vlretroativo < -0.29 ORDER BY CDVINCULO, VLDIFERENCA )
LOOP
   IF F_PAG.CDRUBRICA = 10700
     THEN
       INSERT INTO EPAGRETROATIVOVINCULOFOLHAARQ
       SELECT CDVINCULO, CDFOLHA, CDRUBRICA, VLRETROATIVO, F_PAG.VLRETROATIVO, (VLRETROATIVO + F_PAG.VLRETROATIVO)
       FROM EPAGRETROATIVOVINCULOFOLHA
       WHERE CDVINCULO = F_PAG.CDVINCULO
         AND CDFOLHA = F_PAG.CDFOLHA
         AND CDRUBRICA = 8451; -- RUBRICA 01-0001;
       COMMIT;
   ELSE
     VVALOR := ABS( F_PAG.VLRETROATIVO); -- VALOR DA RUBRICA NO RECALCULO

     FOR F_RUB IN (SELECT r.cdfolha, r.cdvinculo, r.cdrubrica, r.vlretroativo
                     from epagretroativovinculofolha r
                    where cdrubrica in (8451,23637,23677)
                     and  vlretroativo >= 0.30
                     and  cdvinculo = f_pag.cdvinculo
                     and  cdfolha = f_pag.cdfolha
                     order by vlretroativo desc)
     loop
       IF VVALOR > F_RUB.VLRETROATIVO
         THEN
           VVALORDEB := F_RUB.VLRETROATIVO;
           VVALOR := VVALOR - F_RUB.VLRETROATIVO;
       ELSE
           VVALORDEB := VVALOR;
--           VVALOR := VVALOR + F_RUB.VLRETROATIVO;
       END IF;

       INSERT INTO EPAGRETROATIVOVINCULOFOLHAARQ
       VALUES (F_RUB.CDVINCULO, F_RUB.CDFOLHA, F_RUB.CDRUBRICA, F_RUB.VLRETROATIVO, vvalordeb , f_rub.vlretroativo - VVALORDEB);
       COMMIT;
     end loop;

   END IF;

END LOOP;

end;

-----------------------

FUNCTION FNuMesesRRASED577018(pCdVinculo IN INTEGER) RETURN INTEGER IS

  vCdProcessoRetroativo INTEGER;
  vNumesesRRA INTEGER;

BEGIN

  SELECT r.cdprocessopagretroativo
  INTO   vCdProcessoRetroativo
  FROM   ERETPROCESSOPAGRETROATIVO r
  WHERE  r.nuprocesso = 'Processo SED 5770/18'
  AND    r.cdvinculo =  pCdVinculo;

  -- RETURN PKGPAG_RT.FNuMesesRRA(vCdProcessoRetroativo, 2015+1);

    SELECT COUNT(CASE WHEN NUMESES > 0 THEN 1 END)+
           COUNT(CASE WHEN NUMESES13 > 0 THEN 1 END)
    INTO vNuMesesRRA
    FROM (
        SELECT RD.NUANOCOMPETENCIA, RD.NUMESCOMPETENCIA,
               COUNT(CASE WHEN R.NuRubrica <> 23 THEN 1 END ) AS NUMESES,
               COUNT(CASE WHEN R.NuRubrica = 23 THEN 1 END ) AS NUMESES13
        FROM eretprocessopagretroativo PR
        INNER JOIN eretprocessorestituicoesdevida RD
         ON RD.cdprocessopagretroativo = PR.cdprocessopagretroativo
         AND RD.VLRESTITUIRCOMINCIDENCIA+RD.VLRESTITUIRSEMINCIDENCIA > 0
         AND RD.FLAUTOMATICO = 'N'
        INNER JOIN EPagRubricaAgrupamento RA
         ON RA.CdRubricaAgrupamento = RD.CdRubricaAgrupamento
        INNER JOIN EPagRubrica R
         ON R.CdRubrica = RA.CdRubrica
        WHERE (
                (EXISTS (SELECT 1
                        FROM EPagBaseCalcBlocoExprRubAgrup RX
                        INNER JOIN EPagBaseCalculoBlocoExpressao EX
                         ON RX.CdBaseCalculoBlocoExpressao = EX.CdBaseCalculoBlocoExpressao
                        INNER JOIN EPagBaseCalculoBloco BCB
                         ON BCB.CdBaseCalculoBloco = EX.CdBaseCalculoBloco
                        INNER JOIN EPagHistBaseCalculo HBC
                         ON BCB.CdHistBaseCalculo = HBC.CdHistBaseCalculo
                        INNER JOIN vpagrubricaagrupamento vp
                         ON vp.cdrubricaagrupamento = rx.cdrubricaagrupamento
                         AND vp.cdtiporubrica in (2,10,12)
                        WHERE RX.CdRubricaAgrupamento = RD.CdRubricaAgrupamento
                         AND HBC.CdHistBaseCalculo = (
                              select hbc.cdhistbasecalculo
                              from epaghistbasecalculo hbc
                              inner join epagbasecalculoversao bcv
                              on bcv.cdversaobasecalculo = hbc.cdversaobasecalculo
                              inner join epagbasecalculo bc
                              on bc.cdbasecalculo = bcv.cdbasecalculo
                              where bc.SGBASECALCULO = 'BIRRF' -- BASE DO IMPOSTO DE RENDA
                              --and hbc.nuanofimvigencia is null
                              and hbc.nuanoiniciovigencia = 2015
                              and hbc.numesfimvigencia = 7
                              and bcv.nuversao = 1
                              and bc.cdagrupamento = vp.cdagrupamento
                              and rownum < 2)
                        )
                 )
                 OR
                 ( R.NuRubrica in (23, 56) )
          )
          AND PR.CDPROCESSOPAGRETROATIVO = vCdProcessoRetroativo
          AND RD.NUANOCOMPETENCIA <= 2015
          GROUP BY RD.NUANOCOMPETENCIA, RD.NUMESCOMPETENCIA
      );

      IF vNuMesesRRA <= 0 THEN
        vNuMesesRRA := 1;
      END IF;

      RETURN vNuMesesRRA;

 EXCEPTION
   WHEN OTHERS THEN
     RETURN 0;

END;

FUNCTION FIRRFRRASED577018(pBaseCalculoIRRF number,
                           pNM integer) RETURN NUMBER IS
BEGIN

 CASE
    WHEN pBaseCalculoIRRF <= 1903.98*pNM THEN
         RETURN 0;
    WHEN pBaseCalculoIRRF <= 2826.65*pNM THEN
         RETURN pBaseCalculoIRRF * 0.075 - 142.8*pNM;
    WHEN pBaseCalculoIRRF <= 3751.05*pNM THEN
         RETURN pBaseCalculoIRRF * 0.15 - 354.80*pNM;
    WHEN pBaseCalculoIRRF <= 4664.68*pNM THEN
         RETURN pBaseCalculoIRRF * 0.225 - 636.13*pNM;
    ELSE
         RETURN pBaseCalculoIRRF * 0.275 - 869.36*pNM;
 END CASE;

END;

FUNCTION FIRRFSED577018(pBaseCalculoIRRF number) RETURN NUMBER IS
BEGIN

 CASE
    WHEN pBaseCalculoIRRF <= 1903.98 THEN
         RETURN 0;
    WHEN pBaseCalculoIRRF <= 2826.65 THEN
         RETURN pBaseCalculoIRRF * 0.075 - 142.8;
    WHEN pBaseCalculoIRRF <= 3751.05 THEN
         RETURN pBaseCalculoIRRF * 0.15 - 354.80;
    WHEN pBaseCalculoIRRF <= 4664.68 THEN
         RETURN pBaseCalculoIRRF * 0.225 - 636.13;
    ELSE
         RETURN pBaseCalculoIRRF * 0.275 - 869.36;
 END CASE;

END;

FUNCTION FBaseIRRFSED577018(pBaseCalculoIRRF number,
                   pAbatPorDepIRRF number DEFAULT 0,
                   pAabatIRRFMaior65 number DEFAULT 0) RETURN NUMBER IS
BEGIN
 RETURN pBaseCalculoIRRF-pAbatPorDepIRRF-pAabatIRRFMaior65;
END;

FUNCTION FIRRFOutrosSED577018(pCdVinculo INTEGER) RETURN NUMBER IS
  vCdPessoa     integer := 0;
  vl5516Outros  number  := 0;
BEGIN

  SELECT v.cdpessoa,
         sum(case
           when hrv.cdrubricaagrupamento = 10677 then
               hrv.vlpagamento
           else 0
         end) as vl5516
   INTO  vCdPessoa,
         vl5516Outros
   FROM sigrh.epaghistoricorubricavinculo hrv
   INNER JOIN ecadvinculo v
      ON v.cdvinculo = hrv.cdvinculo
   INNER JOIN sigrh.epagfolhapagamento p
      ON p.cdfolhapagamento = hrv.cdfolhapagamento
     AND p.flcalculodefinitivo = 'S'
     AND p.cdtipofolhapagamento = 2
     AND p.nuanomesreferencia = 201507
   WHERE hrv.cdrubricaagrupamento in (10677)
     AND v.cdpessoa = (select cdpessoa from ecadvinculo where cdvinculo = pCdVinculo)
     AND v.cdvinculo <> pCdVinculo
   group by v.cdpessoa;

   RETURN vl5516Outros;

EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;

END;

FUNCTION FBaseIRRFOutrosSED577018(pCdVinculo INTEGER) RETURN NUMBER IS
  vCdPessoa     integer := 0;
  vVl9908Outros number  := 0;
  vVl9907Outros number  := 0;
  vVl9910Outros number  := 0;
  vVl4519Outros number  := 0;
BEGIN

  SELECT v.cdpessoa,
         sum(case
               when hrv.cdrubricaagrupamento = 9560 then
                   hrv.vlpagamento
               else 0
             end) as vl9908Outros,
         sum(case
               when hrv.cdrubricaagrupamento = 8719 then
                   hrv.vlpagamento
               else 0
             end) as vl9907Outros,
         sum(case
               when hrv.cdrubricaagrupamento = 8718 then
                   hrv.vlpagamento
               else 0
             end) as vl9910Outros,
         sum(case
                 when hrv.cdrubricaagrupamento = 10140 then
                     hrv.vlpagamento
                 else 0
               end) as vl4519Outros
   INTO  vCdPessoa,
         vVl9908Outros,
         vVl9907Outros,
         vVl9910Outros,
         vVl4519Outros
   FROM sigrh.epaghistoricorubricavinculo hrv
   INNER JOIN ecadvinculo v
      ON v.cdvinculo = hrv.cdvinculo
   INNER JOIN sigrh.epagfolhapagamento p
      ON p.cdfolhapagamento = hrv.cdfolhapagamento
     AND p.flcalculodefinitivo = 'S'
     AND p.cdtipofolhapagamento = 2
     AND p.nuanomesreferencia = 201507
   WHERE hrv.cdrubricaagrupamento in (9560, 8718, 8719, 10140)
     AND v.cdpessoa = (select cdpessoa from ecadvinculo where cdvinculo = pCdVinculo)
     AND v.cdvinculo <> pCdVinculo
   group by v.cdpessoa;

   RETURN FbaseIRRFSED577018(vVl9908Outros)-vVl4519Outros;

EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;

END;

PROCEDURE ProcessoSED577018(cResultado OUT TYPES.ref_cursor)
IS

BEGIN

   OPEN cResultado FOR
        with vinculos as (
             SELECT hrv.cdvinculo
                  FROM sigrh.epaghistoricorubricavinculo hrv
                 INNER JOIN sigrh.epagfolhapagamento p
                    ON p.cdfolhapagamento = hrv.cdfolhapagamento
                   AND p.flcalculodefinitivo = 'S'
                   AND p.cdtipofolhapagamento = 2
                   AND p.nuanomesreferencia = 201507
                 WHERE hrv.cdrubricaagrupamento = 10140
                 --AND   hrv.cdvinculo = 626637 --400714
        ),
        folhaNormal201507 as (
            SELECT o.sgorgao,
                   hrv.cdvinculo,
                    sum(case
                     when hrv.cdrubricaagrupamento = 10677 then
                         hrv.vlpagamento
                     else 0
                   end) as vl5516,
                   sum(case
                         when hrv.cdrubricaagrupamento = 10140 then
                             hrv.vlpagamento
                         else 0
                       end) as vl4519,
                   sum(case
                         when hrv.cdrubricaagrupamento = 9560 then
                             hrv.vlpagamento
                         else 0
                       end) as vl9908,
                   sum(case
                         when hrv.cdrubricaagrupamento = 8719 then
                             hrv.vlpagamento
                         else 0
                       end) as vl9907,
                   sum(case
                         when hrv.cdrubricaagrupamento = 8718 then
                             hrv.vlpagamento
                         else 0
                       end) as vl9910
             FROM sigrh.epaghistoricorubricavinculo hrv
             INNER JOIN sigrh.epagfolhapagamento p
                ON p.cdfolhapagamento = hrv.cdfolhapagamento
               AND p.flcalculodefinitivo = 'S'
               AND p.cdtipofolhapagamento = 2
               AND p.nuanomesreferencia = 201507
             INNER JOIN sigrh.vcadorgao o
                ON o.cdorgao = p.cdorgao
             WHERE hrv.cdrubricaagrupamento in (10677, 10140,  9560, 8718, 8719)
             and   hrv.cdvinculo in (select * from vinculos)
             group by o.sgorgao,hrv.cdvinculo
          ),
          baseIRRF as (
             select fp.*,
                    FbaseIRRFSED577018(vl9908)-vl4519 AS baseIRRF,
                    FBaseIRRFOutrosSED577018(fp.cdvinculo) as baseIRRFOutros,
                    FIRRFOutrosSED577018 (fp.cdvinculo) as VL5516Outros
             from folhaNormal201507 fp
             where fp.vl5516 > 0
          ),
          IRRF as (
              select v.numatricula, v.nudvmatricula, v.nuseqmatricula,
                     baseIRRF.*,
                     FIRRFSED577018(baseIRRF.baseIRRF+baseIRRF.baseIRRFOutros) as IRRF,
                     FNuMesesRRASED577018(v.cdvinculo) as FNuMesesRRA
              from baseIRRF
              inner join ecadvinculo v
                    on v.cdvinculo = baseIRRF.cdvinculo
          ),
          IRRFRRA as (
              select IRRF.*, FIRRFRRASED577018(IRRF.vl4519, IRRF.FNuMesesRRA) as IRRFRRA
              from IRRF
          )
          select IRRFRRA.*, VL5516+VL5516Outros-IRRF-IRRFRRA
          from IRRFRRA
          WHERE (VL5516+VL5516Outros-IRRF-IRRFRRA) > 0;

END;

PROCEDURE PGeraLFProcessoSED577018 IS

BEGIN

    FOR rec IN (
        select v2.cdvinculo, a.contra AS valor
        from (
        select v.numatricula, v.nudvmatricula, min(v.nuseqmatricula) as nuseqmatricula, x.contra
        from sigrh.xpto x
        inner join sigrh.ecadvinculo v
              on v.cdvinculo = x.cdpessoa
        group by v.numatricula, v.nudvmatricula, x.contra) a
        inner join sigrh.ecadvinculo v2
              on v2.numatricula = a.numatricula
              and v2.nuseqmatricula = a.nuseqmatricula
        inner join sigrh.vcadorgao o
        on o.cdorgao = v2.cdorgao
        and o.cdagrupamento = 1
    )
    LOOP

    DBMS_OUTPUT.PUT_LINE(
         'INSERT INTO sigrh.EPAGLANCAMENTOFINANCEIRO VALUES ( ' ||
         '       sigrh.SPAGLANCAMENTOFINANCEIRO.nextval, ' ||
                 rec.cdvinculo || ',  ' ||
         '       1,   ' ||
         '       to_date(''01/04/2018'',''DD/MM/YYYY''),  ' ||
         '       to_date(''30/04/2018'',''DD/MM/YYYY''),  ' ||
         '       ''N'',  ' ||
         '       1,  ' ||
         '       ''S'',  ' ||
         '       ''11111111111'',   ' ||
         '       trunc(sysdate),   ' ||
         '       trunc(sysdate),   ' ||
         '      ''N'',   ' ||
         '      ''N'',  ' ||
         '       NULL,  ' ||
                 rec.valor || ', ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       ''N'', ' ||
         '       NULL,  ' ||
         '       11658,  ' ||
         '      ''Q'',  ' ||
         '       NULL,  ' ||
         '       ''N'', ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '      to_date(''01/04/2018'',''DD/MM/YYYY''),  ' ||
         '      ''N'',  ' ||
         '      ''N'',  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       ''S'',  ' ||
         '      NULL,  ' ||
         '       NULL,  ' ||
         '       NULL,  ' ||
         '       ''N'',  ' ||
         '       NULL  ); '
         );
  END LOOP;


END;

end PKGPAG_RETROATIVO;
/
