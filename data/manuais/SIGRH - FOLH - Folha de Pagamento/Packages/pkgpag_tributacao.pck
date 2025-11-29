CREATE OR REPLACE PACKAGE PKGPAG_TRIBUTACAO IS

TYPE rTribDependente IS RECORD (
   NuCPF               VARCHAR2(11),
   vlSaldoDeducao      NUMBER
);

TYPE tTribDependente IS TABLE OF rTribDependente;

TYPE rTribIRRF IS RECORD (
   FlPermiteDescSimpl        INTEGER,
   NuDependentes             INTEGER,
   vlDeducaoDependente       NUMBER,
   dep                       tTribDependente,
   FlAplicaDeducaoInativo    BOOLEAN,
   VlDeducaoInativo          NUMBER,  
   bDescRubIsentaIRRF        BOOLEAN,
   bDescRubIsentaDescIRRF    BOOLEAN,
   FlIsentoIRRF              BOOLEAN,
   CdRubAgrupDescIRRF        INTEGER, 
   CdRubBaseIRRF             INTEGER,
   CdRubAgrupDifDescIRRF     INTEGER,     
   CdRubAgrupDevDescIRRF     INTEGER,     
   CdRubBaseDeducaoInativo   INTEGER,   
   CdRubExigibilidadeSusp    INTEGER,
   vlDeducaoInativoReal      NUMBER,   
   vlDescSimp                NUMBER,
   vlPercentResExterior      NUMBER 
);
 
TYPE rRecolhimentoTrib IS RECORD (

  NuCNPJ                     VARCHAR2(14),
  CdVinculo                  INTEGER,
  flrecolhimentoteto         CHAR(1),
  vlbaserecolhimento         NUMBER(13,2),
  vlrecolhimento             NUMBER(13,2),
  vlaliquotaunica            NUMBER(7,4)
  );   
   
TYPE tRecolhimentoTrib IS TABLE OF rRecolhimentoTrib;

TYPE tOrgSIGRH IS TABLE OF PLS_INTEGER
   INDEX BY VARCHAR2(14);
   
TYPE rTribINSS IS RECORD (
   inssControle              PKGPAG_INSS.rINSSControle,
   orgSIGRH                  tOrgSIGRH,
   VlALiquotaContribIndiv    NUMBER,
   bDescRubIsentaINSS        BOOLEAN,
   CdRubAgrupDescINSS        INTEGER,
   CdRubSalBaseINSS          INTEGER,
   CdRubAgrupDifDescINSS     INTEGER,
   CdRubAgrupDevDescINSS     INTEGER,
   CdRubAgrupDescINSS13      INTEGER,
   CdRubSalBaseINSS13        INTEGER,
   CdRubAgrupDifDescINSS13   INTEGER,
   CdRubAgrupDevDescINSS13   INTEGER,
   VlTetoDescINSSContribIndiv NUMBER,
   VlTetoDescINSS             NUMBER
);

TYPE rTribCalcINSS IS RECORD (
   recolhimento              tRecolhimentoTrib,
   TpTributacao              INTEGER,
   CdRubDescINSS             INTEGER,
   CdRubBaseINSS             INTEGER,
   CdRubDifINSS              INTEGER,
   CdRubDevINSS              INTEGER
);

TYPE rTribCalcIPREV IS RECORD (

   CdRubDescIprev            INTEGER,
   CdRubDifDesc              INTEGER,
   CdRubDevDesc              INTEGER,
   CdRubBaseIprev            INTEGER, 
   CdRubDescIprev2008        INTEGER,
   CdRubDifDesc2008          INTEGER,
   CdRubDevDesc2008          INTEGER,                                                     
   CdRubDescSCFuturo13       INTEGER,
   CdRubDifSCFuturo13        INTEGER,
   CdRubDevSCFuturo13        INTEGER 
);

TYPE rTribIPREV IS RECORD (
   bDescRubIsentaIPREV       BOOLEAN,
   FlCpsmParaIprev           INTEGER,
   CdRubAgrupDescIprev       INTEGER,
   CdRubAgrupDescIprev13     INTEGER,  
   CdRubAgrupDifDesc         INTEGER,
   CdRubAgrupDevDesc         INTEGER,
   CdRubBaseIprev            INTEGER,
   CdRubBaseIprev13          INTEGER,  
   CdRubAgrupDescIprev2008   INTEGER,
   CdRubAgrupDescIprev200813 INTEGER, 
   CdRubAgrupDifDesc2008     INTEGER,
   CdRubAgrupDevDesc2008     INTEGER,                                                   
   CdRubAgrupDescSCFuturo13  INTEGER,
   CdRubAgrupDifSCFuturo13   INTEGER,
   CdRubAgrupDevSCFuturo13   INTEGER    
);

TYPE rTribRub IS RECORD (
   
   CdRubBaseSCPREV13         INTEGER,
   CdRubDescSCPREVPATN13     INTEGER,
   CdRubDescSCPREVFACN13     INTEGER,
   CdRubBaseSCPREVPAT13      INTEGER,
   CdRubProvGRAT13           INTEGER,
   CdRubDescGRAT13           INTEGER,
   CdRubDescADIANT13         INTEGER,
   CdRubProvAUXALIM          INTEGER,
   CdRubDescINSSFERIAS       INTEGER,
   CdRubProvGRAT13CTISP      INTEGER,
   CdRubProvFERIASCTISP      INTEGER,
   CdRubDescCPSM             INTEGER,
   CdRubDescINSS             INTEGER,
   CdRubDescPENSAOALSALMIN   INTEGER,
   CdRubBaseINSS             INTEGER,
   CdRubProvABONOPERM        INTEGER,
   CdRubDescRESSARCIPREVSC   INTEGER,
   CdRubBaseBASEIPREV        INTEGER,
   CdRubBaseBASEIPREV13      INTEGER,
   CdRubDescIPREVFF          INTEGER,
   CdRubDescRESSARIPREVFP    INTEGER,
   CdRubBaseOPCAOART27       INTEGER,
   CdRubDescCONTIPREV13      INTEGER,
   CdRubBaseSCPREV           INTEGER,
   CdRubBaseESTENDSCPREV     INTEGER,
   CdRubDescBLOQUEIOREM      INTEGER,
   CdRubDescBLOQUEIOREM13    INTEGER,
   CdRubProvRESC13           INTEGER,
   CdRubBaseDEDIRSCPREV      INTEGER,
   CdRubBaseDEDIRSCPREV13    INTEGER,
   CdRubProvABONPERM13       INTEGER,
   CdRubDescIPREVART2713     INTEGER,
   CdRubDescIPREVPART27      INTEGER,
   CdRubDescSCPREVPATRNOR    INTEGER,
   CdRubBaseSCPREVPatronal   INTEGER,
   CdRubDescSCPREVPATADIC    INTEGER,
   CdRubDescSCPREVFACNOR     INTEGER,
   CdRubDescSCPREVFACADIC    INTEGER,
   CdRubDescIPREVJUDICIAL    INTEGER,
   CdRubBaseBASANUALINSS13   INTEGER,
   CdRubBaseDESCANUALINSS13  INTEGER,
   CdRubDescIRRFJUD          INTEGER,
   CdRubBaseIRRFPENSAO       INTEGER,
   CdRubBaseIRRFBASEPENSAO   INTEGER,
   CdRubBaseIRRF12PORC       INTEGER,
   CdRubBaseIRRF12PORC13     INTEGER,
   CdRubBaseCPSM             INTEGER,
   CdRubBaseCPSM13           INTEGER,
   CdRubBaseVariosVincINSS   INTEGER,
   CdRubDescVariosVincINSS   INTEGER,
   CdRubPatronalAssociacao   INTEGER
 
);

TYPE rTribCalculo IS RECORD (
   inss                      rTribCalcINSS,
   iprev                     rTribCalcIPREV
);

TYPE rTributacao IS RECORD (
   -- Parametros de inicializacao
   pFolha                    PKGPAG_TIPO.rFolha,
   TotRub                    PKGPAG_TIPO.tListaNumber,
   folPermitida              TYPENUMBER,
   rub                       rTribRub,
   inss                      rTribINSS,
   -- Parametros do vinculo
   CdPessoa                  INTEGER,
   CdVinculo                 INTEGER,
   TipoPrev                  INTEGER,
   irrf                      rTribIRRF,
   iprev                     rTribIPREV, 
   -- Parametros do calculo corrente
   calc                      rTribCalculo,
   lstRubTrib                PKGPAG_TIPO.tLista 
);
                               
PROCEDURE PInicializarVinculo (pTributacao IN OUT NOCOPY rTributacao);

PROCEDURE PInicializarControle (pTributacao OUT PKGPAG_TRIBUTACAO.rTributacao,
                                pFolha       IN PKGPAG_TIPO.rFolha);
-----------------------------------------------------------------------------------------
--  Procedure  : PProcessaTributacao
--
--    Objetivo : Realizar a tributacao a ser paga pelo vinculo que esta processado. As
--             tributacoes envolvidas sao a de INSS, IRRF (RRA) e IPREV/IPESC
--
-----------------------------------------------------------------------------------------
PROCEDURE PProcessaTributacaoEPensao(pTributacao  IN OUT NOCOPY rTributacao,
                                     pCdPessoa        IN INTEGER,
                                     pCdVinculo       IN INTEGER);

PROCEDURE PSetaRubricasIsentas(pFolha     IN PKGPAG_TIPO.rFolha,
                               pCdVinculo IN INTEGER);
                               
END PKGPAG_TRIBUTACAO;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_TRIBUTACAO IS

-- analisar o porquê
----       pkgpag_var.bPossuiDuploVinculoAno := FALSE; -- Tratar porque FB usa

bIsencaoParcialIPREV BOOLEAN; -- Variável utilizada para indicar se o servidor possui descisão judicial da rubrica 05-0924

CTRIB_TIPO_NORMAL     CONSTANT INTEGER := 1;
CTRIB_TIPO_DECTER     CONSTANT INTEGER := 2;
CTRIB_TIPO_FERIAS     CONSTANT INTEGER := 3;
CTRIB_TIPO_RRA        CONSTANT INTEGER := 4;

-- Agrupamentos

CAGR_AGPE             CONSTANT INTEGER := 1;
CAGR_CIASC            CONSTANT INTEGER := 2;
CAGR_COHAB            CONSTANT INTEGER := 3;
CAGR_CIDASC           CONSTANT INTEGER := 4;
--CAGR_EPAGRI           CONSTANT INTEGER := 5;
--CAGR_SANTUR           CONSTANT INTEGER := 6;
--CAGR_MP               CONSTANT INTEGER := 7;
--CAGR_ICEPA            CONSTANT INTEGER := 8;
--CAGR_SEDAPP           CONSTANT INTEGER := 9;
--CAGR_OEIP             CONSTANT INTEGER := 11;
--CAGR_PensoesIPREV     CONSTANT INTEGER := 132;
--CAGR_PGTC             CONSTANT INTEGER := 133;
CAGR_PMSC             CONSTANT INTEGER := 134;
--CAGR_SCPA             CONSTANT INTEGER := 136;
--CAGR_DPSC             CONSTANT INTEGER := 176;
--CAGR_IMETRO           CONSTANT INTEGER := 276;
--CAGR_PDVI             CONSTANT INTEGER := 340;

-- Orgaos

CORG_CIASC            CONSTANT INTEGER := 3;
CORG_EPAGRI           CONSTANT INTEGER := 27;
CORG_CLTIMETRO        CONSTANT INTEGER := 563;
CORG_SAS              CONSTANT INTEGER := 4;
CORG_SDE              CONSTANT INTEGER := 5;
CORG_SCPAR            CONSTANT INTEGER := 383;
CORG_COHAB            CONSTANT INTEGER := 7;

CPREV_INSS            CONSTANT INTEGER := 1;
CPREV_IPREV           CONSTANT INTEGER := 2;
CPREV_CPSM            CONSTANT INTEGER := 3;
    
  bIsencaoPercialIPREV BOOLEAN; -- Varável utilizada para indicar se o servidor possui descisão judicial da rubrica 05-0924
   
--------------------------------------------------------------------------------
-- Variaveis que identificam as isencoes do vinculo
---------------------------------------------------------------------------------
   
TYPE rBase IS RECORD (
   FlCalcular                INTEGER,
   FlPossuiOutroVinculo      INTEGER,
   VlBaseAtual               NUMBER,
   VlBaseAtualSemDepJuizo    NUMBER,
   VlDeduzidoAtual           NUMBER,
   vlBaseOutrosForaSIGRH     NUMBER,
   vlAbat65AnosOutrosSIGRH   NUMBER,
   vlAbat65AnosOutrosSIRH    NUMBER,                                        
   vlBaseOutroVincMesmaFol   NUMBER,
   vlBaseOutroVincOutraFol   NUMBER,
   vlBaseMesmoVincOutraFol   NUMBER,
   vlDeduzOutroVincMesmaFol  NUMBER,
   vlDeduzOutroVincOutraFol  NUMBER,
   vlDeduzMesmoVincOutraFol  NUMBER,
   VlDeducaoDependOutroVinc  NUMBER,
   VlDescRubDepJuizo         NUMBER,
   VlDescRubIsentaIRRF       NUMBER
   );
      
CURSOR cSentenca (pFolha IN PKGPAG_TIPO.rFolha, pCdvinculo IN INTEGER, pDtInicioPensao13 IN DATE) IS
   SELECT SJ.CdSentencaJudicial,
          HSJ.CdTipoPensaoAlimenticia,
          SJ.NuSequencial,
          HSJ.FlPagamento13,
          HTP.FlPagamentoValorFixo,
          TPR.CdRubricaAgrupamento,
          TPR.CdHistTipoPensaoRubrica,
          R.NuRubrica,
          SR.CdOutraRubrica,
          SR.FlDescAnteriorAplicPercent,
          SR.VlPercentPensao,
          SR.VlFixo,
          HSJ.CdHistSentencaJudicial,
          HSJ.Flpagamentoferias,
          HSJ.FlpagaRetroativo as FlPagamentoRetroativo,
          0 as CdExpressaoFormCalc
     FROM ePenSentencaJudicial SJ
    INNER JOIN EPenHistSentencaJudicial HSJ
       ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
    INNER JOIN EPenTipoPensaoAlimenticia TPA
       ON HSJ.CdTipoPensaoAlimenticia = TPA.CdTipoPensaoAlimenticia
    INNER JOIN EPenHistTipoPensao HTP
       ON TPA.CdTipoPensaoAlimenticia = HTP.CdTipoPensaoAlimenticia
    INNER JOIN EPenHistTipoPensaoRubrica TPR
       ON TPR.CdHistTipoPensao = HTP.CdHistTipoPensao
    INNER JOIN EPenSentencaRubrica SR
       ON SR.CdHistSentencaJudicial = HSJ.CdHistSentencaJudicial
      AND SR.CdHistTipoPensaoRubrica = TPR.CdHistTipoPensaoRubrica
    INNER JOIN EPagRubricaAgrupamento RA
       ON TPR.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
    INNER JOIN EPagRubrica R
       ON R.CdRubrica = RA.CdRubrica
    WHERE SJ.CdVinculo = pCdVinculo
      AND HSJ.FlAnulado = PKGPAG_TIPO.cnN
      AND HSJ.Dtiniciovigencia <= pFolha.DtFimMes
      AND ((HSJ.DtFimVigencia >= CASE
             WHEN pFolha.CdTipoFolha IN
                  (PKGPAG_TIPO.cnTpFolha13,
                   pkgpag_tipo.cnTpFolhaCtisp13) THEN
              pDtInicioPensao13
             ELSE
              pFolha.DtInicioMes
          END) OR HSJ.DtFimVigencia IS NULL)
      AND ((HTP.NuAnoInicio < pFolha.NuAnoReferencia OR
          (HTP.NuAnoInicio = pFolha.NuAnoReferencia AND
          HTP.NuMesInicio <= pFolha.NuMesReferencia)) AND
          (HTP.NuAnoFim > pFolha.NuAnoReferencia OR
          (HTP.NuAnoFim = pFolha.NuAnoReferencia AND
          HTP.NuMesFim >= pFolha.NuMesReferencia) OR
          HTP.NuAnoFim IS NULL))
    GROUP BY SJ.CdSentencaJudicial,
             HSJ.CdTipoPensaoAlimenticia,
             SJ.NuSequencial,
             HSJ.FlPagamento13,
             HTP.FlPagamentoValorFixo,
             TPR.CdRubricaAgrupamento,
             TPR.CdHistTipoPensaoRubrica,
             R.NuRubrica,
             SR.CdOutraRubrica,
             SR.FlDescAnteriorAplicPercent,
             SR.VlPercentPensao,
             SR.VlFixo,
             HSJ.Flpagamentoferias,
             HSJ.FlPagaRetroativo,
             hsj.cdhistsentencajudicial
    ORDER BY R.NuRubrica;

SUBTYPE rSentenca IS cSentenca%ROWTYPE;

TYPE tSentenca IS TABLE OF rSentenca;
  
PROCEDURE P_____________Genericas IS
BEGIN
   NULL;
END;

PROCEDURE PDebug (pMsg IN VARCHAR2) IS
   vvalor   varchar2(32000);
BEGIN

    select chr(10) || LISTAGG (max(deexpressao) || ': ' || MAX(nurubricafmt || ' - ' || descricao) || ' => ' || max(vlpagamento) || ' qtde = ' || count (*),CHR(10)) WITHIN GROUP (ORDER BY MAX(nurubricafmt))
      into vValor
      from vpagcc
     where cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
       and cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
       and nurubricafmt in ('05-0512') --'09-0916', '05-0512','09-0903','09-1666')
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
        
   DBMS_OUTPUT.PUT_LINE ('TRB: ' || pMsg || VVALOR);  
   DBMS_OUTPUT.PUT_LINE ('---------------------------------------------------------------------'); 

END;

FUNCTION FRetornaRubricaOutroTipo(pTributacao           IN rTributacao,
                              pCdRubricaAgrupamento IN INTEGER,
                              pCdTipoRubrica        IN INTEGER) RETURN INTEGER IS
   
BEGIN
   
   RETURN PKGPAG_GERAL.FRetornaRubricaOutroTipo (pCdAgrupamento   => pTributacao.pFolha.CdAgrupamento,
                                                 pNuAnoReferencia => pTributacao.pFolha.NuAnoReferencia,
                                                 pNuMesReferencia => pTributacao.pFolha.NuMesReferencia,
                                                 pCdRubrica       => pCdRubricaAgrupamento,
                                                 pCdTipoRubrica   => pCdTipoRubrica);

END;

FUNCTION FRetornaValorRubIsentas(pCdVinculo         IN INTEGER,
                                 pFolha             IN PKGPAG_TIPO.rFolha,
                                 pCdTipoDesconto    IN INTEGER,
                                 pFlDepositoEmJuizo IN CHAR DEFAULT 'N')
   
 RETURN NUMBER IS
   
   vvlRubIsentas NUMBER(13, 2);
   
BEGIN
   
   SELECT SUM(HRV.VlPagamento)
     INTO vvlRubIsentas
     FROM EPagHistoricoRubricaVinculo HRV
    INNER JOIN ETrbIsencaoRubrica TR
       ON TR.CdVinculo = HRV.CdVinculo
      AND TR.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
    INNER JOIN ETrbHistIsencaoRubrica HTR
       ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
    WHERE TR.CdVinculo = pCdVinculo
      AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
      AND CASE pCdTipoDesconto
             WHEN 1 THEN
              TR.FlRubricaIsentaINSS
             WHEN 2 THEN
              TR.FlRubricaIsentaIRRF
             WHEN 3 THEN
              TR.FlRubricaIsentaIPESC
          END = PKGPAG_TIPO.cnS
      AND ((HTR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
          (HTR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
          HTR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
          (HTR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
          (HTR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
          HTR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
          HTR.NuMesFimVigencia IS NULL) AND TR.FLDEPOSITOEMJUIZO = CASE
             WHEN pFlDepositoEmJuizo = 'S' THEN
              pFlDepositoEmJuizo
             ELSE
              TR.FLDEPOSITOEMJUIZO
          END);
   
   RETURN NVL(vvlRubIsentas, 0);
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN 0;
      
END;


PROCEDURE PAlterarLancamentoVinculo (pCdFolhaPagamento        IN INTEGER,
                                     pCdVinculo               IN INTEGER,
                                     pCdRubricaAgrupamento    IN INTEGER,
                                     pVlPagamento             IN NUMBER,
                                     pCdTipoOrigemRubrica     IN INTEGER DEFAULT 10,
                                     pCdProcessoPagRetroativo IN INTEGER DEFAULT NULL

                                                                                               
                         ) IS
    
    vcdtipoindice INTEGER;
    
BEGIN
                                     
   DELETE FROM EPagHistoricoRubricaRelVinc HRV
    WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
      AND HRV.CdVinculo = pCdVinculo
      AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento;

   vCdTipoIndice := PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).CdTipoIndice;

   UPDATE EPagHistoricoRubricaVinculo HRV
      SET VlPagamento             = trunc(pvlpagamento, 2),
          CdTipoIndice            = vCdTipoIndice,
          CdExpressaoFormCalc     = NULL,
          NuSufixoRubrica         = 1,
          vlindicerubrica         = NULL,
          CdTipoOrigemRubrica     = pCdTipoOrigemRubrica,
          CdProcessoPagRetroativo = pCdProcessoPagRetroativo
    WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
      AND HRV.CdVinculo = pCdVinculo
      AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento;
 
   IF sql%rowcount = 0 THEN -- Não existia                  

      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pCdFolhaPagamento,
                                            pCdVinculo               => pCdVinculo,
                                            pCdExpressaoFormCalc     => NULL,
                                            pCdRubricaAgrupamento    => pCdRubricaAgrupamento,
                                            pNuSufixoRubrica         => 1,
                                            pVlPagamento             => trunc(pvlpagamento, 2),
                                            pVlIndice                => NULL,
                                            pCdTipoOrigemRubrica     => pCdTipoOrigemRubrica,
                                            pCdProcessoPagRetroativo => pCdProcessoPagRetroativo);      
                                                            
   END IF;
 
END;


PROCEDURE PProcessaFormula (pfolha          IN pkgpag_tipo.rfolha,
                            pcdvinculo       IN INTEGER,
                            pcdrubrica       IN INTEGER,
                            ptpprocessamento IN INTEGER,
                            ptplocal         IN INTEGER,
                            ptptributacao    IN INTEGER,
                            pindprocretro    IN INTEGER,
                            pcdmnemonico     IN INTEGER,
                            pNuSufixoRubrica IN INTEGER) IS

BEGIN
   
   PKGPAG_FB.PProcessaFormulasBases(pfolha           => pFolha,
                                    pcdvinculo       => pCdVinculo,
                                    pcdrubrica       => pCdRubrica,
                                    ptpprocessamento => pTpProcessamento,
                                    ptplocal         => pTpLocal,
                                    ptptributacao    => pTpTributacao,
                                    pindprocretro    => pIndProcRetro,
                                    pcdmnemonico     => pCdMnemonico,
                                    pNuSufixoRubrica => pNuSufixoRubrica);

END;

PROCEDURE PProcessaBase (pTributacao      IN rTributacao,
                         pcdrubrica       IN INTEGER,
                         ptptributacao    IN INTEGER DEFAULT NULL,
                         pindprocretro    IN INTEGER DEFAULT NULL,
                         pcdmnemonico     IN INTEGER DEFAULT NULL,
                         pNuSufixoRubrica IN INTEGER DEFAULT NULL) IS

BEGIN
                       
   PProcessaFormula (pfolha           => pTributacao.pFolha,
                     pcdvinculo       => pTributacao.CdVinculo,
                     pcdrubrica       => pCdRubrica,
                     ptpprocessamento => 2, -- Base
                     ptplocal         => 2,
                     ptptributacao    => pTpTributacao,
                     pindprocretro    => pIndProcRetro,
                     pcdmnemonico     => pCdMnemonico,
                     pNuSufixoRubrica => pNuSufixoRubrica);

END;

PROCEDURE PProcessaRubrica (pTributacao      IN rTributacao,
                            pcdrubrica       IN INTEGER,
                            ptptributacao    IN INTEGER DEFAULT NULL,
                            pindprocretro    IN INTEGER DEFAULT NULL,
                            pcdmnemonico     IN INTEGER DEFAULT NULL,
                            pNuSufixoRubrica IN INTEGER DEFAULT NULL) IS

BEGIN
                       
   PProcessaFormula (pfolha           => pTributacao.pFolha,
                     pcdvinculo       => pTributacao.CdVinculo,
                     pcdrubrica       => pCdRubrica,
                     ptpprocessamento => 1, -- Prov/Desc
                     ptplocal         => 2,
                     ptptributacao    => pTpTributacao,
                     pindprocretro    => pIndProcRetro,
                     pcdmnemonico     => pCdMnemonico,
                     pNuSufixoRubrica => pNuSufixoRubrica);

END;

FUNCTION FProcessaBase (pTributacao      IN rTributacao,
                        pcdrubrica       IN INTEGER,
                        ptptributacao    IN INTEGER DEFAULT NULL,
                        pindprocretro    IN INTEGER DEFAULT NULL,
                        pcdmnemonico     IN INTEGER DEFAULT NULL,
                        pNuSufixoRubrica IN INTEGER DEFAULT NULL) RETURN NUMBER IS

BEGIN
                       
   PProcessaBase (pTributacao      => pTributacao,
                  pcdrubrica       => pCdRubrica,
                  ptptributacao    => pTpTributacao,
                  pindprocretro    => pIndProcRetro,
                  pcdmnemonico     => pCdMnemonico,
                  pNuSufixoRubrica => pNuSufixoRubrica);

   RETURN pkgpag_geral.fretornavalorrubrica(pTributacao.pFolha.CdFolhaPagamento,
                                            pTributacao.CdVinculo,
                                            pCdRubrica);
END;

FUNCTION FProcessaRubrica (pTributacao      IN rTributacao,
                           pcdrubrica       IN INTEGER,
                           ptptributacao    IN INTEGER DEFAULT NULL,
                           pindprocretro    IN INTEGER DEFAULT NULL,
                           pcdmnemonico     IN INTEGER DEFAULT NULL,
                           pNuSufixoRubrica IN INTEGER DEFAULT NULL) RETURN NUMBER IS

BEGIN
                       
   PProcessaRubrica (pTributacao      => pTributacao,
                     pcdrubrica       => pCdRubrica,
                     ptptributacao    => pTpTributacao,
                     pindprocretro    => pIndProcRetro,
                     pcdmnemonico     => pCdMnemonico,
                     pNuSufixoRubrica => pNuSufixoRubrica);

   RETURN pkgpag_geral.fretornavalorrubrica(pTributacao.pFolha.CdFolhaPagamento,
                                            pTributacao.CdVinculo,
                                            pCdRubrica);
END;


PROCEDURE PApagarCalculo (pCdFolhaPagamento IN INTEGER, pCdVinculo IN INTEGER, pCdRubricaAgrupamento IN INTEGER) IS
   
BEGIN

   DELETE FROM EPagHistoricoRubricaVinculo HRV
    WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
      AND HRV.CdVinculo = pCdVinculo
      AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento;
                
END;
 
PROCEDURE PApagarCalculo (pTributacao IN rTributacao, pCdRubricaAgrupamento IN INTEGER) IS
   
BEGIN

   PApagarCalculo (pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento, 
                   pCdVinculo            => pTributacao.CdVinculo,
                   pCdRubricaAgrupamento => pCdRubricaAgrupamento);
                
END;

FUNCTION FAlterarCalculo (pCdFolhaPagamento IN INTEGER, pCdVinculo IN INTEGER, pCdRubricaAgrupamento IN INTEGER, 
                          pNuSufixoRubrica  IN INTEGER, pValor IN NUMBER,
                          pvlindice         IN NUMBER DEFAULT NULL,
                          pFlForcarIndice   IN INTEGER DEFAULT NULL,
                          pDeExpressao      IN VARCHAR2 DEFAULT NULL) RETURN INTEGER IS

BEGIN

   UPDATE EPAGHISTORICORUBRICAVINCULO
      SET VLPAGAMENTO = pValor,
          VLINDICERUBRICA = CASE WHEN pFlForcarIndice = 1 THEN pvlindice ELSE NVL(pvlIndice,VLINDICERUBRICA) END,
          DEEXPRESSAO = pDeExpressao
    WHERE CDFOLHAPAGAMENTO = pCdFolhaPagamento
      AND CDVINCULO = pCdVinculo
      AND CDRUBRICAAGRUPAMENTO = pCdRubricaAgrupamento
      AND (pNuSufixoRubrica IS NULL OR pNuSufixoRubrica = NUSUFIXORUBRICA);
      
   IF sql%rowcount = 0 THEN -- Não existia
      RETURN 0;
   ELSE
      RETURN 1;
   END IF;
END;
        
PROCEDURE PAlterarCalculo (pTributacao IN rTributacao, pCdRubricaAgrupamento IN INTEGER, 
                           pNuSufixoRubrica  IN INTEGER, pValor IN NUMBER,
                           pvlindice         IN NUMBER DEFAULT NULL,
                           pFlForcarIndice   IN INTEGER DEFAULT NULL,
                           pDeExpressao      IN VARCHAR2 DEFAULT NULL) IS
BEGIN         

   IF FAlterarCalculo (pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                       pCdVinculo            => pTributacao.CdVinculo,
                       pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                       pNuSufixoRubrica      => pNuSufixoRubrica,
                       pValor                => pValor,
                       pvlindice             => pVlIndice,
                       pFlForcarIndice       => pFlForcarIndice,
                       pDeExpressao          => pDeExpressao) IS NULL THEN
      NULL;
   END IF;
                             
END;
                   
PROCEDURE PCriarCalculo (pTributacao IN rTributacao, pCdRubricaAgrupamento IN INTEGER,
                         pNuSufixoRubrica IN INTEGER, pCdTipoOrigemRubrica IN INTEGER, pValor IN NUMBER,
                         pvlindice IN NUMBER DEFAULT NULL,
                         pFlForcarIndice IN INTEGER DEFAULT NULL,
                         pDeExpressao    IN VARCHAR2 DEFAULT NULL) IS
   vExiste  INTEGER; 
BEGIN

   vExiste := FAlterarCalculo (pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                               pCdVinculo            => pTributacao.CdVinculo,
                               pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                               pNuSufixoRubrica      => pNuSufixoRubrica,
                               pValor                => pValor,
                               pvlindice             => pvlindice,
                               pFlForcarIndice       => pFLForcarIndice,
                               pDeExpressao          => pDeExpressao);
                               
   IF vExiste = 0 THEN
         
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PCdRubricaAgrupamento,
                                            pNuSufixoRubrica      => pNuSufixoRubrica,
                                            pVlPagamento          => pValor,
                                            pvlindice             => pvlindice,
                                            pCdTipoOrigemRubrica  => pCdTipoOrigemRubrica,
                                            pDeExpressao          => pDeExpressao);
   END IF;

END;

FUNCTION FExisteRubrica (pTributacao IN rTributacao, pCdRubrica IN INTEGER, pNuSufixo IN INTEGER DEFAULT NULL) RETURN INTEGER IS
   vFlExiste INTEGER;
BEGIN   
   
   SELECT NVL(MAX(1),0)
     INTO vFlExiste
     FROM EPagHistoricoRubricaVinculo HRV
    WHERE CdVinculo = pTributacao.CdVinculo
      AND CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
      AND CdRubricaAgrupamento = pCdRubrica
      AND (pNuSufixo IS NULL OR pNuSufixo = HRV.NuSufixoRubrica)
      ;
      
   RETURN vFlExiste;
   
END;    
     

FUNCTION FRetornaValorRubrica (pTributacao IN rTributacao, pCdRubrica IN INTEGER, pNuSufixo IN INTEGER DEFAULT 1) RETURN NUMBER IS

BEGIN   
   
   RETURN PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo        => pTributacao.CdVinculo,
                                            pCdRubrica        => pCdRubrica,
                                            pNuSufixo         => pNuSufixo);
END;    
                     
PROCEDURE P_____________FGTS IS
BEGIN
   NULL;
END;


/*-----------------------------------------------------------------------------------------/
  Procedure  : PProcessaTributacaoFGTS
      
    Objetivo : Separar o FGTS do INSS, antes dentro da rotina do INSS era feito o FGTS
               sao independentes visto que alguem que ja tenha recolhido o INSS pelo teto
               em um outro agrupamento pode ter direito ao FGTS em outro.
    Solicitacao de Sustentacao #69392
    8654/2016 - GFIP - - SERVIDOR CELETISTA SEM FGTS NO 1056
/-----------------------------------------------------------------------------------------*/

PROCEDURE PProcessaTributacaoFGTS(pTributacao IN rTributacao) IS
   
BEGIN
   
   -- CALCULA FGTS
   IF ((PKGPAG_VAR.vgVinculo.CdRegimeTrabalho = PKGPAG_TIPO.cnRegTrabCLT) OR
      -- Excecao CIDASC Presidente SIG-5839
      (PKGPAG_VAR.vgVinculo.CdRegimeTrabalho = 6 AND
      pTributacao.pFolha.CdORgao = 25)) AND PKGPAG_VAR.vgDtOpcaoFGTS IS NOT NULL THEN
      
      IF PKGPAG_VAR.vgVinculo.CdRegimeTrabalho = 6 AND
         pTributacao.pFolha.CdORgao = 25 AND
         (pTributacao.pfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaRescisao OR
         pTributacao.pFolha.cdtipofolha <> PKGPAG_TIPO.cnTpFolhaRescisao) THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.cdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseFGTS,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.cdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubVlFGTS,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseFGTS IS NOT NULL THEN
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseFGTS,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseFGTS13 IS NOT NULL THEN
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseFGTS13,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
      END IF;
      
      IF PKGPAG_VAR.vgCdRubVlFGTS IS NOT NULL THEN
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubVlFGTS,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseProv13VlFGTS IS NOT NULL THEN
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubVlFGTS13 IS NOT NULL THEN
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubVlFGTS13,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
      END IF;
      
      IF NOT (PKGPAG_VAR.vgFolha.CdOrgao = CORG_EPAGRI AND
          PKGPAG_VAR.bVinculoComCCO = TRUE) THEN
         
         PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => PKGPAG_VAR.vgCdRubricaBaseINSSPat,
                                     pFlExcluiAmbos    => 'S');
      END IF;
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                  pFlExcluiAmbos    => 'S');
      
      -- EXCLUI BASES DE FGTS
   ELSE
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseFGTS,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseFGTS13,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubVlFGTS,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubVlFGTS13,
                                  pFlExcluiAmbos    => 'S');
      
   END IF;
   
END;

 
                                 
PROCEDURE P_____________SCPREV IS
BEGIN
   NULL;
END;

PROCEDURE PExcluirRubricaDoContraCheque(pCdVinculo            IN INTEGER,
                                        pCdFolhaPagamento     IN INTEGER,
                                        pCdRubricaAgrupamento IN INTEGER) IS
BEGIN
   DELETE FROM epaghistoricorubricavinculo
    WHERE cdvinculo = pCdVinculo
      AND cdfolhapagamento = pCdFolhaPagamento
      AND cdrubricaagrupamento = pCdRubricaAgrupamento
      AND cdtipoorigemrubrica <> 17; -- exceto lancamento complementar
END;


PROCEDURE PAtualizarValorPgtoRubrica(pCdVinculo            IN INTEGER,
                                     pCdFolhaPagamento     IN INTEGER,
                                     pCdRubricaAgrupamento IN INTEGER,
                                     pValorPagamento       IN NUMBER) IS
BEGIN
   UPDATE epaghistoricorubricavinculo
      SET vlpagamento = pValorPagamento
    WHERE cdVinculo = pCdVinculo
      AND cdfolhapagamento = pCdFolhaPagamento
      AND cdrubricaagrupamento = pCdRubricaAgrupamento;
END;                                
                                    
PROCEDURE PProcessarRubricaSCPREV13(pTributacao                    IN rTributacao,
                                    pFormExpr                      IN PKGPAG_TIPO.tFormulaCalculo,
                                    pCdRubricaAgrupamento          IN INTEGER,
                                    pTpProcessamento               IN INTEGER,
                                    pValorIndiceRubrica            IN NUMBER,
                                    pValorMinimoContribuicaoSCPREV IN NUMBER,
                                    pCdTipoOrigemRubrica           IN INTEGER DEFAULT 1) IS

   vCdExpressaoFormula   INTEGER := NULL;
   vValorRubrica         NUMBER;
   
BEGIN

   PExcluirRubricaDoContraCheque(pTributacao.CdVinculo,
                                 pTributacao.pFolha.CdFolhaPagamento,
                                 pCdRubricaAgrupamento);

   IF pCdRubricaAgrupamento in (pTributacao.rub.CdRubBaseSCPREV13,pTributacao.rub.CdRubBaseSCPREVPAT13) THEN

      vValorRubrica := FRetornaValorRubrica(pTributacao => pTributacao,
                                            pCdRubrica  => pCdRubricaAgrupamento);
      IF vValorRubrica > 0 THEN
         RETURN;
      END IF;
      
   ELSE
      
      vCdExpressaoFormula := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => pFormExpr,
                                                                    pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                                    pCdRelacaoVinculo     => 0);
   END IF;
   
   pkgpag_geral.pinserelancamentovinculo(pcdfolhapagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                         pcdvinculo            => pTributacao.Cdvinculo,
                                         pcdexpressaoformcalc  => vCdExpressaoFormula,
                                         pcdrubricaagrupamento => pCdRubricaAgrupamento,
                                         pnusufixorubrica      => 1,
                                         pvlpagamento          => 0,
                                         pvlindice             => pValorIndiceRubrica,
                                         pcdtipoorigemrubrica  => pCdTipoOrigemRubrica);
   
   PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                    pCdVinculo       => pTributacao.CdVinculo,
                                    pCdRubrica       => pCdRubricaAgrupamento,
                                    pTpProcessamento => pTpProcessamento, -- 1 Processa fÓrmulas de calculo, 2 Processa base de cálculo
                                    pTpLocal         => 2); -- no vinculo
 
   IF NOT pCdRubricaAgrupamento in (pTributacao.rub.CdRubBaseSCPREV13,pTributacao.rub.CdRubBaseSCPREVPAT13) THEN

      vValorRubrica := FRetornaValorRubrica(pTributacao => pTributacao,
                                            pcdrubrica  => pCdRubricaAgrupamento);
      
      IF (pValorMinimoContribuicaoSCPREV IS NOT NULL) AND
         (vValorRubrica < pValorMinimoContribuicaoSCPREV) THEN
         PKGPAG_TRIBUTACAO.PAtualizarValorPgtoRubrica(pCdVinculo            => pTributacao.CdVinculo,
                                                      pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                      pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                      pValorPagamento       => pValorMinimoContribuicaoSCPREV);
      END IF;
   END IF;
   
END;

PROCEDURE PProcessarBase13SCPrev(pTributacao                    IN rTributacao,
                                 pCdRegimeProprioPrev           IN INTEGER,
                                 pFormExpr                      IN PKGPAG_TIPO.tFormulaCalculo,
                                 pValorMinimoContribuicaoSCPREV IN NUMBER,
                                 pValorRubrica9_920             IN NUMBER) IS
   
   vCdRubricaAgrupamento9_963  INTEGER;
   vCdRubricaAgrupamento1_0023 INTEGER;
   vValorRubrica1_0023         NUMBER;
   vValorRubrica9_963          NUMBER;
   vValorMaximoRubrica9_963    NUMBER;
BEGIN
   vCdRubricaAgrupamento9_963 := pTributacao.rub.CdRubBaseSCPREV13;
   
   PProcessarRubricaSCPREV13(pTributacao                    => pTributacao,
                             pFormExpr                      => pFormExpr,
                             pCdRubricaAgrupamento          => pTributacao.rub.CdRubBaseSCPREV13,
                             pTpProcessamento               => 2,
                             pValorIndiceRubrica            => NULL,
                             pValorMinimoContribuicaoSCPREV => pValorMinimoContribuicaoSCPREV,
                             pCdTipoOrigemRubrica           => 10);
   
   vValorRubrica9_963 := FRetornaValorRubrica(pTributacao => pTributacao,
                                              pcdrubrica  => vCdRubricaAgrupamento9_963);
   
   vCdRubricaAgrupamento1_0023 := pTributacao.rub.CdRubProvGRAT13;
   vValorRubrica1_0023         := FRetornaValorRubrica(pTributacao => pTributacao,
                                                       pcdrubrica  => vCdRubricaAgrupamento1_0023);
   
   vValorMaximoRubrica9_963 := vValorRubrica1_0023 - pValorRubrica9_920;
   IF (pCdRegimeProprioPrev = 3) AND
      (vValorRubrica9_963 > vValorMaximoRubrica9_963) THEN
      PKGPAG_TRIBUTACAO.PAtualizarValorPgtoRubrica(pCdVinculo            => pTributacao.CdVinculo,
                                                   pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                   pCdRubricaAgrupamento => vCdRubricaAgrupamento9_963,
                                                   pValorPagamento       => vValorMaximoRubrica9_963);
   END IF;
END;


FUNCTION FObterValorIndiceRubrica(pCdVinculo     IN INTEGER,
                                  pCdRubrica     IN INTEGER,
                                  pDataInicioMes IN DATE,
                                  pDataFimMes    IN DATE,
                                  pFlAnulado     IN CHAR) RETURN NUMBER IS
   vValorIndiceRubrica NUMBER(10, 4) := 0;
BEGIN
   SELECT f.vlindice
     INTO vValorIndiceRubrica
     FROM epaglancamentofinanceiro f
    WHERE F.CdVinculo = pCdVinculo
      AND F.DtInicioDireito <= pDataFimMes
      AND (F.DtFimdireito >= pDataInicioMes OR F.DtFimDireito IS NULL)
      AND F.FlAnulado = pFlAnulado
      AND F.Cdrubricaagrupamento = pCdRubrica
      AND ROWNUM < 2;
   
   RETURN nvl(vValorIndiceRubrica, 0);
EXCEPTION
   WHEN no_data_found THEN
      RETURN 0;
   WHEN OTHERS THEN
      RETURN 0;
END;

PROCEDURE PCalculaDeducaoIRRFSCPREV(pTributacao IN rTributacao) IS
   
   vCdRubricaAgrupamento INTEGER;
   --vCdExpressaoFormCalc  INTEGER;
   
BEGIN
   
   PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                    pCdVinculo       => pTributacao.CdVinculo,
                                    pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIRRF13,
                                    pTpProcessamento => 2,
                                    pTpLocal         => 2);
   
   -- Verifica se gerou Base Deducao IRRF SCPREV: somEnte gera a 09-1025 se gerou a 09-9908
   IF FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => pTributacao.rub.CdRubBaseIRRF12PORC) <= 0 THEN
      RETURN;
   END IF;
   
   -- Gera a 09-1025
   vCdRubricaAgrupamento := pTributacao.rub.CdRubBaseDEDIRSCPREV;
   
   IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
   END IF;
   
   DELETE epaghistoricorubricavinculo hv
    WHERE hv.cdvinculo = pTributacao.CdVinculo
      AND hv.cdfolhapagamento = pTributacao.pFolha.CdFolhaPagamento
      AND hv.cdrubricaagrupamento = pTributacao.rub.CdRubBaseDEDIRSCPREV;
   
   PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.cdFolhaPagamento,
                                         pCdVinculo            => pTributacao.CdVinculo,
                                         pCdExpressaoFormCalc  => NULL,
                                         pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                         pNuSufixoRubrica      => 1,
                                         pVlPagamento          => 0,
                                         pVlIndice             => NULL,
                                         pCdTipoOrigemRubrica  => 1);
   
   PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                    pCdVinculo       => pTributacao.CdVinculo,
                                    pCdRubrica       => vCdRubricaAgrupamento,
                                    ptplocal         => 2,
                                    ptpprocessamento => 2);
   
EXCEPTION
   WHEN OTHERS THEN
      RETURN;
      
END;

PROCEDURE PCalculaDeducaoIRRFSCPREV13(pTributacao IN rTributacao) IS
   
   vCdRubricaAgrupamento INTEGER;
   
   vVlBase pkgpag_tipo.rValorPagamento;
   
BEGIN
   
   PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                    pCdVinculo       => pTributacao.CdVinculo,
                                    pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIRRF13,
                                    pTpProcessamento => 2,
                                    pTpLocal         => 2);
   
   -- Verifica se gerou Base Deducao IRRF SCPREV: somEnte gera a 09-1045 se gerou a 09-9909
   IF FRetornaValorRubrica(pTributacao => pTributacao,
                           pcdRubrica  => pTributacao.rub.CdRubBaseIRRF12PORC13) <= 0 THEN
      RETURN;
   END IF;
   
   -- Gera a 09-1045
   vCdRubricaAgrupamento := pTributacao.rub.CdRubBaseDEDIRSCPREV13;
   
   IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
   END IF;
   
   vvlBase := PKGPAG_FB.FRetornaValorBaseCalculo(pfolha            => pTributacao.pFolha,
                                                 pcdvinculo        => pTributacao.CdVinculo,
                                                 pcdtipohistorico  => 2,
                                                 pcdrelacaovinculo => 0,
                                                 pcdbasecalculo    => pkgpag_var.vgrubrica(vCdRubricaAgrupamento).cdbasecalculo,
                                                 pcdchave          => pTributacao.CdVinculo);
   
   DELETE epaghistoricorubricavinculo hv
    WHERE hv.cdvinculo = pTributacao.CdVinculo
      AND hv.cdfolhapagamento = pTributacao.pFolha.CdFolhaPagamento
      AND hv.cdrubricaagrupamento = pTributacao.rub.CdRubBaseDEDIRSCPREV13;
   
   PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.cdFolhaPagamento,
                                         pCdVinculo            => pTributacao.CdVinculo,
                                         pCdExpressaoFormCalc  => NULL,
                                         pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                         pNuSufixoRubrica      => 1,
                                         pVlPagamento          => 0,
                                         pVlIndice             => NULL,
                                         pCdTipoOrigemRubrica  => 1);
   
   PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                    pCdVinculo       => pTributacao.CdVinculo,
                                    pCdRubrica       => vCdRubricaAgrupamento,
                                    ptplocal         => 2,
                                    ptpprocessamento => 2);
   
EXCEPTION
   WHEN OTHERS THEN
      RETURN;
      
END;

PROCEDURE PCalculaBaseEstendidaSCPREV(pTributacao IN rTributacao) IS
   
   vCdRubBaseScprev       INTEGER;
   vvlBaseEstendidaScPrev pkgpag_tipo.rvalorpagamento;
   
BEGIN
   
   --------------------------------------------------------------------------------------------------------------
   -- SIG-7952 INCONSISTENCIA NO CALCULO DA RUBRICA 05-1925
   -- Base estendida so deve ser gerada para quem tem lancamento financeiro da rubrica 09-0962
   -- caso contrario nao inclui a base estendida do SCPREV
   
   vCdRubBaseScprev := pTributacao.rub.CdRubBaseESTENDSCPREV;
   
   --------------------------------------------------------------------------------------------------------------
   
   IF (PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                          pTributacao.pFolha,
                                          vCdRubBaseScprev) AND
      to_char(pTributacao.pfolha.DtCalculo, 'yyyymm') >= 202203) OR
      to_char(pTributacao.pfolha.DtCalculo, 'yyyymm') < 202203 THEN
      
      --
      -- Verificar optantes do SCPREV
      --
      
      IF NVL(vCdRubBaseScprev, 0) > 0 AND
         (PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                             pTributacao.pFolha,
                                             vCdRubBaseScprev) OR
          pkgpag_var.vgcef.Count > 0) THEN
         
         IF pkgpag_var.vgcco.Count = 0 AND pkgpag_var.vgfuc.count = 0
            
          THEN
            
            DELETE EPAGHISTORICORUBRICAVINCULO HRV
             WHERE HRV.CdVinculo = pTributacao.CdVinculo
               AND HRV.CdFolhaPagamento =
                   pTributacao.pFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento = vCdRubBaseScprev;
            
            DELETE EPAGHISTORICORUBRICARELVINC HRV1
             WHERE HRV1.CdVinculo = pTributacao.CdVinculo
               AND HRV1.CdFolhaPagamento =
                   pTributacao.pFolha.CdFolhaPagamento
               AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev;
            
         ELSE
            
            vvlBaseEstendidaScPrev.vlProporcional := 0;
            
            vvlBaseEstendidaScPrev.vlIntegral := 0;
            
            vvlBaseEstendidaScPrev := PKGPAG_FB.FRetornaValorBaseCalculo(pfolha            => pTributacao.pFolha,
                                                                         pcdvinculo        => pTributacao.CdVinculo,
                                                                         pcdtipohistorico  => 2,
                                                                         pcdrelacaovinculo => 0,
                                                                         pcdbasecalculo    => pkgpag_var.vgrubrica(vCdRubBaseScprev).cdbasecalculo, --vcdbasecalculo,
                                                                         pcdchave          => pTributacao.CdVinculo);
            
            IF vvlBaseEstendidaScPrev.vlIntegral > 0 -- vvlBaseEstendidaScPrev.vlProporcional > 0
             THEN
               
               UPDATE EPagHistoricoRubricaVinculo HRV
                  SET HRV.vlPagamento = vvlBaseEstendidaScPrev.vlIntegral
                WHERE HRV.CdVinculo = pTributacao.CdVinculo
                  AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                  AND HRV.CdRubricaAgrupamento = vCdRubBaseScprev;
               
               UPDATE EPAGHISTORICORUBRICARELVINC HRV1
                  SET HRV1.vlProporcional     = vvlBaseEstendidaScPrev.vlIntegral,
                      HRV1.vlReal             = vvlBaseEstendidaScPrev.vlIntegral,
                      HRV1.vlIntegral         = vvlBaseEstendidaScPrev.vlintegral,
                      HRV1.Cdhistcargoefetivo = pkgpag_var.vgcef(1).CdHistCargoEfetivo,
                      HRV1.CdChave            = hrv1.cdhistcargocom
                WHERE HRV1.CdVinculo = pTributacao.CdVinculo
                  AND HRV1.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                  AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev
                  AND HRV1.Cdhistcargocom IS NOT NULL;
               
               DELETE EPAGHISTORICORUBRICARELVINC HRV1
                WHERE HRV1.CdVinculo = pTributacao.CdVinculo
                  AND HRV1.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                  AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev
                  AND HRV1.CDHISTCARGOEFETIVO IS NOT NULL
                  AND HRV1.Cdhistcargocom IS NULL;
               
            END IF;
            
         END IF;
         
      END IF;
   ELSE
      
      DELETE EPAGHISTORICORUBRICAVINCULO HRV
       WHERE HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = vCdRubBaseScprev;
      
      DELETE EPAGHISTORICORUBRICARELVINC HRV1
       WHERE HRV1.CdVinculo = pTributacao.CdVinculo
         AND HRV1.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev;
      
   END IF;
   
END;


PROCEDURE PCalculaSCPREV13(pTributacao IN rTributacao) IS
   
   vCdRubBaseScprev13 INTEGER;
   --vCdExpressaoFormula integer;
   vVlIndiceRub NUMBER(10, 4) := 0;
   vVMPSCPREV   NUMBER(13, 4) := PKGPAG_PARAM.FValorReferencia('VMP SCPREV');
   
   vCdRubricaAgrupamento9_1925 INTEGER;
   vCdRubricaAgrupamento5_1925 INTEGER;
   vCdRubricaAgrupamento5_1927 INTEGER;
   vCdRubricaAgrupamento9_920  INTEGER;
   vValorRubrica9_920          NUMBER;
   vCdRegimeProprioPrev        INTEGER;
   vAliquotaINSS               pkgpag_tipo.rAliquotaINSS;
BEGIN
   
   --
   -- Verificar optantes do SCPREV
   --
   -- Fundo Financeiro LC 662/15
   --
   vCdRegimeProprioPrev := PKGPAG_GERAL.FRetornaRegimeProprioPrev(pTributacao.CdVinculo);
   vAliquotaINSS        := PKGPAG_VAR.vAliqINSS;
   
   vCdRubricaAgrupamento9_920 := pTributacao.rub.CdRubBaseBASEIPREV13;
   vValorRubrica9_920         := FRetornaValorRubrica(pTributacao => pTributacao,
                                                      pcdrubrica  => vCdRubricaAgrupamento9_920);
   IF (vCdRegimeProprioPrev = 3 AND
      vValorRubrica9_920 > vAliquotaINSS.VlTeto) THEN
      vValorRubrica9_920 := vAliquotaINSS.VlTeto;
      PAtualizarValorPgtoRubrica(pCdVinculo            => pTributacao.CdVinculo,
                                 pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                 pCdRubricaAgrupamento => vCdRubricaAgrupamento9_920,
                                 pValorPagamento       => vValorRubrica9_920);
   END IF;
   
   vCdRubBaseScprev13 := pTributacao.rub.CdRubBaseSCPREV13;
   
   PProcessarBase13SCPrev(pTributacao                    => pTributacao,
                          pCdRegimeProprioPrev           => vCdRegimeProprioPrev,
                          pFormExpr                      => pkgpag_var.vgFormExpr,
                          pValorMinimoContribuicaoSCPREV => vVMPSCPREV,
                          pValorRubrica9_920             => vValorRubrica9_920);
   
   --Não entendi o motivo da exclusão
   vCdRubricaAgrupamento9_1925 := pTributacao.rub.CdRubBaseSCPREVPatronal;
   
   PExcluirRubricaDoContraCheque(pTributacao.CdVinculo,
                                 pkgpag_var.vgFolha.CdFolhaPagamento,
                                 vCdRubricaAgrupamento9_1925);
   
   CASE
      WHEN vCdRegimeProprioPrev IN (1, 3, 4) THEN
         vCdRubricaAgrupamento5_1925 := pTributacao.rub.CdRubDescSCPREVPATRNOR;
         
         vVlIndiceRub := FObterValorIndiceRubrica(pTributacao.CdVinculo,
                                                  vCdRubricaAgrupamento5_1925,
                                                  pkgpag_var.vgFolha.DtInicioMes,
                                                  pkgpag_var.vgFolha.dtFimMes,
                                                  PKGPAG_TIPO.cnN);
         
         IF nvl(vCdRubBaseScprev13, 0) > 0 AND nvl(vVlIndiceRub, 0) > 0 THEN
            PProcessarRubricaSCPREV13(pTributacao                    => pTributacao,
                                      pFormExpr                      => pkgpag_var.vgFormExpr,
                                      pCdRubricaAgrupamento          => pTributacao.rub.CdRubDescSCPREVPATN13,
                                      pTpProcessamento               => 1,
                                      pValorIndiceRubrica            => vVlIndiceRub,
                                      pValorMinimoContribuicaoSCPREV => vVMPSCPREV);
            
            PProcessarRubricaSCPREV13(pTributacao                    => pTributacao,
                                      pFormExpr                      => pkgpag_var.vgFormExpr,
                                      pCdRubricaAgrupamento          => pTributacao.rub.CdRubBaseSCPREVPAT13,
                                      pTpProcessamento               => 2,
                                      pValorIndiceRubrica            => NULL,
                                      pValorMinimoContribuicaoSCPREV => vVMPSCPREV,
                                      pCdTipoOrigemRubrica           => 10);
         END IF;
         
         vCdRubricaAgrupamento5_1927 := pTributacao.rub.CdRubDescSCPREVFACNOR;
         vVlIndiceRub                := FObterValorIndiceRubrica(pTributacao.CdVinculo,
                                                                 vCdRubricaAgrupamento5_1927,
                                                                 pkgpag_var.vgFolha.DtInicioMes,
                                                                 pkgpag_var.vgFolha.dtFimMes,
                                                                 PKGPAG_TIPO.cnN);
         
         IF nvl(vCdRubBaseScprev13, 0) > 0 AND nvl(vVlIndiceRub, 0) > 0 THEN
            PProcessarRubricaSCPREV13(pTributacao                    => pTributacao,
                                      pFormExpr                      => pkgpag_var.vgFormExpr,
                                      pCdRubricaAgrupamento          => pTributacao.rub.CdRubDescSCPREVFACN13,
                                      pTpProcessamento               => 1,
                                      pValorIndiceRubrica            => vVlIndiceRub,
                                      pValorMinimoContribuicaoSCPREV => vVMPSCPREV);
         END IF;
         
         IF (vCdRegimeProprioPrev = 1) THEN
            PExcluirRubricaDoContraCheque(pTributacao.CdVinculo,
                                          pkgpag_var.vgFolha.CdFolhaPagamento,
                                          vCdRubBaseScprev13);
         END IF;
   END CASE;
   
   PCalculaDeducaoIRRFSCPREV(pTributacao => pTributacao);
   
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END;


PROCEDURE PCalculaBaseDeducIRRFSCPREV13(pTributacao IN rTributacao) IS
   
   vCdRubricaAgrupamento INTEGER;
   
BEGIN
   
   vCdRubricaAgrupamento := pTributacao.rub.CdRubBaseIRRF12PORC13;
   
   IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
   END IF;
   
   IF (FRetornaValorRubrica(pTributacao => pTributacao,
                            pcdrubrica  => pTributacao.rub.CdRubDescSCPREVPATN13) > 0 OR
       FRetornaValorRubrica(pTributacao => pTributacao,
                            pcdrubrica  => pTributacao.rub.CdRubDescSCPREVFACN13) > 0) THEN
      
      IF FRetornaValorRubrica(pTributacao => pTributacao,
                              pcdrubrica  => pTributacao.rub.CdRubBaseIRRF12PORC13) = 0 THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.cdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => vCdRubricaAgrupamento,
                                          ptplocal         => 2,
                                          ptpprocessamento => 2);
      END IF;
      
   ELSE
      
      PExcluirRubricaDoContraCheque(pTributacao.CdVinculo,
                                    pTributacao.pFolha.CdFolhaPagamento,
                                    pTributacao.rub.CdRubBaseIRRF12PORC13);
      
   END IF;
   
EXCEPTION
   WHEN OTHERS THEN
      RETURN;
      
END;


PROCEDURE PCalculaBaseDeducaoIRRFSCPREV(pTributacao IN rTributacao) IS
   
   vCdRubricaAgrupamento INTEGER;
   --vCdExpressaoFormCalc  INTEGER;
   
BEGIN
   
   vCdRubricaAgrupamento := pTributacao.rub.CdRubBaseIRRF12PORC;
   
   IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
   END IF;
   
   IF (PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                          PKGPAG_VAR.vgFolha,
                                          pTributacao.rub.CdRubDescSCPREVPATRNOR)) OR
      PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                          PKGPAG_VAR.vgFolha,
                                          pTributacao.rub.CdRubDescSCPREVPATADIC) OR
      PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                          PKGPAG_VAR.vgFolha,
                                          pTributacao.rub.CdRubDescSCPREVFACNOR) OR
      PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                          PKGPAG_VAR.vgFolha,
                                          pTributacao.rub.CdRubDescSCPREVFACADIC) OR
      (pkgpag_var.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13) AND
      (FRetornaValorRubrica(pTributacao => pTributacao,
                            pcdrubrica  => pTributacao.rub.CdRubDescSCPREVPATN13) > 0 OR
       FRetornaValorRubrica(pTributacao => pTributacao,
                            pcdrubrica  => pTributacao.rub.CdRubDescSCPREVFACN13) > 0)) THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.cdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);
      
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => pTributacao.CdVinculo,
                                       pCdRubrica       => vCdRubricaAgrupamento,
                                       ptplocal         => 2,
                                       ptpprocessamento => 2);
      
   ELSE
      RETURN;
      
   END IF;
   
EXCEPTION
   WHEN OTHERS THEN
      RETURN;
      
END;

PROCEDURE PCalculaPatronalSCPREV(pTributacao IN rTributacao) IS
   
   vCdRubricaAgrupamento INTEGER;
   
BEGIN
   
   vCdRubricaAgrupamento := pTributacao.rub.CdRubBaseSCPREVPatronal;
   
   IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
   END IF;
   
   IF FRetornaValorRubrica(pTributacao => pTributacao,
                           pcdrubrica  => pTributacao.rub.CdRubDescSCPREVPATRNOR) > 0 THEN
      
      
      IF FRetornaValorRubrica(pTributacao => pTributacao,
                             pcdrubrica   => vCdRubricaAgrupamento) = 0 THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.cdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
         
      END IF;
      
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                       pCdVinculo       => pTributacao.CdVinculo,
                                       pCdRubrica       => vCdRubricaAgrupamento,
                                       ptplocal         => 2,
                                       ptpprocessamento => 2);
      
   ELSE
      RETURN;
      
   END IF;
   
EXCEPTION
   WHEN OTHERS THEN
      RETURN;
      
END;



PROCEDURE PFundoFinanceiroAutomatico(pTributacao IN rTributacao) IS
   
   vCdRubricaAgrupagmento INTEGER;
  

   -- Verifica se está passou a receber acima do teto no mês
   FUNCTION FUltrapassouTetoRGPSnoMes(pCdVinculo IN INTEGER,
                                      pfolha     IN pkgpag_tipo.rfolha)
      RETURN BOOLEAN IS
      
      vCdRubBase            INTEGER := 0;
      vCdBaseCalculo        INTEGER := 0;
      vVlBase               pkgpag_tipo.rvalorpagamento;
      vRecebeuRubricaMesAnt NUMBER;
      
   BEGIN
      
      vCdRubBase := pTributacao.rub.CdRubBaseSCPREV;
      
      -- Se gerou rubrica 09-0961 no mês anterior, siginifica que já estava acima do teto,
      -- então não deve considerar
      vRecebeuRubricaMesAnt := pkgpag_geral.frecebeurubrica(pcdvinculo    => pCdVinculo,
                                                            pcdrubrica    => vCdRubBase,
                                                            pnuanomes     => pfolha.NuAnoMesReferencia,
                                                            pnumeses      => 1,
                                                            pcdfolhaatual => pfolha.CdFolhaPagamento);
      IF vRecebeuRubricaMesAnt > 0 THEN
         RETURN FALSE;
      END IF;
      
      -- Verifica
      vCdBaseCalculo := pkgpag_var.vgrubrica(vCdRubBase).cdbasecalculo;
      
      vVlBase := PKGPAG_FB.FRetornaValorBaseCalculo(pfolha            => pfolha,
                                                    pcdvinculo        => pCdVinculo,
                                                    pcdtipohistorico  => 2,
                                                    pcdrelacaovinculo => 0,
                                                    pcdbasecalculo    => vCdBaseCalculo,
                                                    pcdchave          => pCdVinculo);
      
      IF NVL(vVlBase.vlProporcional, 0) > 0 THEN
         RETURN TRUE;
      END IF;
      
   EXCEPTION
      WHEN OTHERS THEN
         RETURN FALSE;
   END;
 
BEGIN
   
   -- Implementa fundo financeiro acima do teto apenas para ingressantes
   -- ou para servidores que ultrapassaram teto no mês
   
   -- Só implementa regra quando rodar folha NORMAL
   IF NOT (pTributacao.pfolha.CdTipoFolha = 1 AND pTributacao.pfolha.cdtipocalculo = 1) THEN
      RETURN;
   END IF;
   
   -- Se não possui remuneração acima do teto, retorna
   IF NOT FUltrapassouTetoRGPSnoMes(pCdVinculo => pTributacao.CdVinculo,
                                    pfolha     => pTributacao.pfolha) THEN
      RETURN;
   END IF;
   
   vCdRubricaAgrupagmento := pTributacao.rub.CdRubDescSCPREVPATRNOR;
   
   -- Se já tem a rubrica lançada em financeiro, retorna
   IF pkgpag_geral.fpossuilancfinanceiro(pcdvinculo        => pTributacao.CdVinculo,
                                         pfolha            => pTributacao.pfolha,
                                         pcdrubrica        => vCdRubricaAgrupagmento,
                                         pIncluiFinalizado => 'S') THEN
      RETURN;
   END IF;
   
   -- Insere rubrica em financeiro
   INSERT INTO epaglancamentofinanceiro
      (CDLANCAMENTOFINANCEIRO,
       CDVINCULO,
       NUSUFIXORUBRICA,
       DTINICIODIREITO,
       FLVALORPROPORCIONAL,
       FLPAGAAFASTDEFINITIVO,
       NUCPFCADASTRADOR,
       DTINCLUSAO,
       DTULTALTERACAO,
       FLDECISAOJUDICIAL,
       FLFOLHASUPLEMENTAR,
       VLINDICE,
       FLANULADO,
       CDRUBRICAAGRUPAMENTO,
       INPERIODICIDADE,
       FLACERTOAUTO13SAL,
       FLPROPDEMITIDONOMES,
       FLPAGAAFASTTEMPSEMREMUN,
       FLAUTOMATICO)
   VALUES
      (spaglancamentofinanceiro.nextval,
       pTributacao.CdVinculo,
       1,
       trunc(pTributacao.pfolha.DtCalculo, 'MM'),
       'N',
       'N',
       '11111111111',
       trunc(SYSDATE),
       trunc(SYSDATE),
       'N',
       'N',
       8,
       'N',
       vCdRubricaAgrupagmento,
       'Q',
       'N',
       'N',
       'N',
       'N');
   
   -- Finalizar rubrica 05-1927 do financeiro
   vCdRubricaAgrupagmento := pTributacao.rub.CdRubDescSCPREVFACNOR;
   
   UPDATE EPAGLANCAMENTOFINANCEIRO LF
      SET LF.DTFIMDIREITO   = TRUNC(pTributacao.pfolha.DtCalculo, 'MM') - 1,
          LF.DTULTALTERACAO = TRUNC(SYSDATE)
    WHERE LF.CDVINCULO = pTributacao.CdVinculo
      AND LF.CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupagmento;
   
   DELETE EPAGHISTORICORUBRICARELVINC HRV1
    WHERE HRV1.CdVinculo = pTributacao.CdVinculo
      AND HRV1.CdFolhaPagamento = pTributacao.pfolha.CdFolhaPagamento
      AND HRV1.CdRubricaAgrupamento = vCdRubricaAgrupagmento;
   
   DELETE EPAGHISTORICORUBRICAVINCULO HRV
    WHERE HRV.CdVinculo = pTributacao.CdVinculo
      AND HRV.CdFolhaPagamento = pTributacao.pfolha.CdFolhaPagamento
      AND HRV.CdRubricaAgrupamento = vCdRubricaAgrupagmento;
   
   -- Finalizar rubrica 05-1928 do financeiro
   vCdRubricaAgrupagmento := pTributacao.rub.CdRubDescSCPREVFACADIC;
   
   UPDATE EPAGLANCAMENTOFINANCEIRO LF
      SET LF.DTFIMDIREITO   = trunc(pTributacao.pfolha.DtCalculo, 'MM') - 1,
          LF.DTULTALTERACAO = TRUNC(SYSDATE)
    WHERE LF.CDVINCULO = pTributacao.CdVinculo
      AND LF.CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupagmento;
   
   DELETE EPAGHISTORICORUBRICARELVINC HRV1
    WHERE HRV1.CdVinculo = pTributacao.CdVinculo
      AND HRV1.CdFolhaPagamento = pTributacao.pfolha.CdFolhaPagamento
      AND HRV1.CdRubricaAgrupamento = vCdRubricaAgrupagmento;
   
   DELETE EPAGHISTORICORUBRICAVINCULO HRV
    WHERE HRV.CdVinculo = pTributacao.CdVinculo
      AND HRV.CdFolhaPagamento = pTributacao.pfolha.CdFolhaPagamento
      AND HRV.CdRubricaAgrupamento = vCdRubricaAgrupagmento;
   
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END;

PROCEDURE PCalculaFundoFinanceiro(pTributacao IN rTributacao) IS
   
   -- Monta variavel para executar formula de uma rubrica e retornar o valor calculado
   --

   PROCEDURE pExecutaFormulaRegimePrev(pCdVinculo            IN INTEGER,
                                       pCdRubricaAgrupamento IN INTEGER,
                                       pCalculaBasePatronal  IN BOOLEAN DEFAULT FALSE) IS
      
      vCdExpressaoFormCalc INTEGER;
      --vPagCalc pkgpag_tipo.rPagCalc;
      vValor NUMBER(13, 2);
      --vformexpr pkgpag_tipo.rformulacalculo;
      vVlIndiceRub      NUMBER(13, 4);
      vVlLancFinanceiro NUMBER(13, 4) := 0;
      vVMPSCPREV        NUMBER(13, 4);
      
   BEGIN
      
      vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                     pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                                     pCdRelacaoVinculo     => pkgpag_var.vgCEF(1).CdRelacaoVinculo);
      
      IF nvl(vCdExpressaoFormCalc, 0) > 0 THEN
         
         vVlIndiceRub := 0;
         
         SELECT vlindice, vllancamentofinanceiro
           INTO vvlindicerub, vvllancfinanceiro
           FROM (SELECT lf.vlindice, lf.vllancamentofinanceiro
                   FROM epaglancamentofinanceiro lf
                  WHERE lf.cdvinculo = pcdvinculo
                    AND lf.cdrubricaagrupamento = pcdrubricaagrupamento
                    AND lf.nusufixorubrica = 1
                  ORDER BY lf.dtiniciodireito DESC)
          WHERE rownum < 2;
         
         DELETE epaghistoricorubricarelvinc hrv1
          WHERE hrv1.cdvinculo = pcdvinculo
            AND hrv1.cdfolhapagamento = pkgpag_var.vgfolha.cdfolhapagamento
            AND hrv1.cdrubricaagrupamento = pcdrubricaagrupamento;
         
         DELETE epaghistoricorubricavinculo hrv
          WHERE hrv.cdvinculo = pcdvinculo
            AND hrv.cdfolhapagamento = pkgpag_var.vgfolha.cdfolhapagamento
            AND hrv.cdrubricaagrupamento = pcdrubricaagrupamento;
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                               pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 1,
                                               pVlIndice             => vVlIndiceRub,
                                               pCdTipoOrigemRubrica  => 1);
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => pCdRubricaAgrupamento,
                                          pTpProcessamento => 1,
                                          pTpLocal         => 2);
         
         vVMPSCPREV := PKGPAG_PARAM.FValorReferencia('VMP SCPREV');
         
         -- Caso não possua lançamento financeiro calcula o SCPREV
         IF NOT
             PKGPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                                PKGPAG_VAR.vgFolha,
                                                pTributacao.rub.CdRubBaseSCPREVPatronal) AND
            pTributacao.rub.CdRubBaseSCPREVPatronal = pCdRubricaAgrupamento THEN
            IF pCalculaBasePatronal THEN
               
               vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                              pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseSCPREVPatronal,
                                                                              pCdRelacaoVinculo     => pkgpag_var.vgCEF(1).CdRelacaoVinculo);
               
               DELETE EPAGHISTORICORUBRICARELVINC HRV1
                WHERE HRV1.CdVinculo = pCdVinculo
                  AND HRV1.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV1.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal;
               
               DELETE EPAGHISTORICORUBRICAVINCULO HRV
                WHERE HRV.CdVinculo = pCdVinculo
                  AND HRV.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal;
               
               PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                     pCdVinculo            => pCdVinculo,
                                                     pCdExpressaoFormCalc  => NULL,
                                                     pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseSCPREVPatronal,
                                                     pNuSufixoRubrica      => 1,
                                                     pVlPagamento          => 0,
                                                     pVlIndice             => NULL,
                                                     pCdTipoOrigemRubrica  => 10);
               
               PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                pCdVinculo       => pCdVinculo,
                                                pCdRubrica       => pTributacao.rub.CdRubBaseSCPREVPatronal,
                                                pTpProcessamento => 2, -- Processa base de c?lculo
                                                pTpLocal         => 2);
               
            ELSE
               
               DELETE EPAGHISTORICORUBRICAVINCULO HRV
                WHERE HRV.CdVinculo = pCdVinculo
                  AND HRV.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal;
               
               DELETE EPAGHISTORICORUBRICARELVINC HRV1
                WHERE HRV1.CdVinculo = pCdVinculo
                  AND HRV1.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV1.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal;
               
            END IF;
            
         ELSIF NVL(vVlLancFinanceiro, 0) > 0 THEN
            
            UPDATE EPAGHISTORICORUBRICAVINCULO HRV
               SET HRV.Vlpagamento = vVlLancFinanceiro
             WHERE HRV.CdVinculo = pCdVinculo
               AND HRV.CdFolhaPagamento =
                   PKGPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento IN
                   (pCdRubricaAgrupamento,
                    pTributacao.rub.CdRubBaseSCPREVPatronal);
            
            UPDATE EPAGHISTORICORUBRICARELVINC HRV1
               SET HRV1.vlProporcional = vVlLancFinanceiro,
                   HRV1.vlReal         = vVlLancFinanceiro,
                   HRV1.vlIntegral     = vVlLancFinanceiro
             WHERE HRV1.CdVinculo = pCdVinculo
               AND HRV1.CdFolhaPagamento =
                   PKGPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV1.CdRubricaAgrupamento IN
                   (pCdRubricaAgrupamento,
                    pTributacao.rub.CdRubBaseSCPREVPatronal);
            
            UPDATE EPAGHISTORICORUBRICAVINCULO HRV
               SET HRV.Vlpagamento = vVlLancFinanceiro,
                   HRV.deexpressao = vVlLancFinanceiro * 100 / vVlIndiceRub ||
                                     ' * ' || vVlIndiceRub || ' /100'
             WHERE HRV.CdVinculo = pCdVinculo
               AND HRV.CdFolhaPagamento =
                   PKGPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento IN
                   (pCdRubricaAgrupamento,
                    pTributacao.rub.CdRubBaseSCPREVPatronal);
            
            UPDATE EPAGHISTORICORUBRICARELVINC HRV1
               SET HRV1.vlProporcional = vVlLancFinanceiro,
                   HRV1.vlReal         = vVlLancFinanceiro,
                   HRV1.vlIntegral     = vVlLancFinanceiro
             WHERE HRV1.CdVinculo = pCdVinculo
               AND HRV1.CdFolhaPagamento =
                   PKGPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV1.CdRubricaAgrupamento IN
                   (pCdRubricaAgrupamento,
                    pTributacao.rub.CdRubBaseSCPREVPatronal);
         ELSE
            NULL;
         END IF;
         -- APLICA VALOR MINIMO SCPREV
         
         vValor := FRetornaValorRubrica(pTributacao => pTributacao,
                                        pcdrubrica  => pCdRubricaAgrupamento);
         IF vVMPSCPREV IS NOT NULL THEN
            
            IF vValor > 0 AND vValor < vVMPSCPREV THEN
               
               UPDATE EPAGHISTORICORUBRICAVINCULO HRV
                  SET HRV.Vlpagamento = vVMPSCPREV
                WHERE HRV.CdVinculo = pCdVinculo
                  AND HRV.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento;
               
               UPDATE EPAGHISTORICORUBRICARELVINC HRV1
                  SET HRV1.VLPROPORCIONAL = vVMPSCPREV
                WHERE HRV1.CdVinculo = pCdVinculo
                  AND HRV1.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV1.CdRubricaAgrupamento = pCdRubricaAgrupamento;
               
            END IF;
            
            IF NOT
                PKGPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                                   PKGPAG_VAR.vgFolha,
                                                   pTributacao.rub.CdRubBaseSCPREVPatronal) AND
               (FRetornaValorRubrica(pTributacao => pTributacao,
                                     pcdrubrica  => pTributacao.rub.CdRubBaseSCPREVPatronal) < vVMPSCPREV) THEN
               UPDATE EPAGHISTORICORUBRICAVINCULO HRV
                  SET HRV.Vlpagamento = vVMPSCPREV
                WHERE HRV.CdVinculo = pCdVinculo
                  AND HRV.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal;
               
               UPDATE EPAGHISTORICORUBRICARELVINC HRV1
                  SET HRV1.VLPROPORCIONAL = vVMPSCPREV
                WHERE HRV1.CdVinculo = pCdVinculo
                  AND HRV1.CdFolhaPagamento =
                      PKGPAG_VAR.vgFolha.CdFolhaPagamento
                  AND HRV1.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal;
               
            END IF;
            
         END IF;
         
         IF NOT
             PKGPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                                PKGPAG_VAR.vgFolha,
                                                pTributacao.rub.CdRubBaseSCPREVPatronal) THEN
            
            PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                             pCdVinculo       => pCdVinculo,
                                             pCdRubrica       => pTributacao.rub.CdRubBaseSCPREVPatronal,
                                             pTpProcessamento => 2, -- Processa base de c?lculo
                                             pTpLocal         => 2);
            
         END IF;
         
      END IF;
      
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
         
   END;




BEGIN
   
   CASE
   --
   -- Fundo Financeiro LC 662/15
   --
      WHEN PKGPAG_GERAL.FRetornaRegimeProprioPrev(pTributacao.CdVinculo) IN (3, 4)  THEN
         
         PFundoFinanceiroAutomatico(pTributacao => pTributacao);
         
         IF PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                               PKGPAG_VAR.vgFolha,
                                               pTributacao.rub.CdRubBaseSCPREVPatronal) THEN
            
            DELETE EPAGHISTORICORUBRICARELVINC HRV1
             WHERE HRV1.CdVinculo = pTributacao.CdVinculo
               AND HRV1.CdFolhaPagamento =
                   PKGPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV1.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal
               AND HRV1.Cdtipoorigemrubrica <> 2;
            
            DELETE EPAGHISTORICORUBRICAVINCULO HRV
             WHERE HRV.CdVinculo = pTributacao.CdVinculo
               AND HRV.CdFolhaPagamento =
                   PKGPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseSCPREVPatronal
               AND HRV.Cdtipoorigemrubrica <> 2;
            
         END IF;
         
         IF PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                               PKGPAG_VAR.vgFolha,
                                               pTributacao.rub.CdRubDescSCPREVPATRNOR) THEN
            
            pExecutaFormulaRegimePrev(pTributacao.CdVinculo,
                                      pTributacao.rub.CdRubDescSCPREVPATRNOR,
                                      TRUE);
            
         END IF;
         
         IF PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                               PKGPAG_VAR.vgFolha,
                                               pTributacao.rub.CdRubDescSCPREVPATADIC) THEN
            
            pExecutaFormulaRegimePrev(pTributacao.CdVinculo,
                                      pTributacao.rub.CdRubDescSCPREVPATADIC);
            
         END IF;
         
         IF PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                               PKGPAG_VAR.vgFolha,
                                               pTributacao.rub.CdRubDescSCPREVFACNOR) THEN
            
            pExecutaFormulaRegimePrev(pTributacao.CdVinculo,
                                      pTributacao.rub.CdRubDescSCPREVFACNOR);
            
         END IF;
         
         IF PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                               PKGPAG_VAR.vgFolha,
                                               pTributacao.rub.CdRubDescSCPREVFACADIC) THEN
            
            pExecutaFormulaRegimePrev(pTributacao.CdVinculo,
                                      pTributacao.rub.CdRubDescSCPREVFACADIC);
            
         END IF;
         
   --
   -- Fundo Financeiro
   --
      WHEN PKGPAG_GERAL.FRetornaRegimeProprioPrev(pTributacao.CdVinculo) = 1
         
       THEN
         
         IF PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                               PKGPAG_VAR.vgFolha,
                                               pTributacao.rub.CdRubDescSCPREVFACNOR) THEN
            
            pExecutaFormulaRegimePrev(pTributacao.CdVinculo,
                                      pTributacao.rub.CdRubDescSCPREVFACNOR);
            
         END IF;
         
         IF PKGPAG_GERAL.fpossuilancfinanceiro(pTributacao.CdVinculo,
                                               PKGPAG_VAR.vgFolha,
                                               pTributacao.rub.CdRubDescSCPREVFACADIC) THEN
            
            pExecutaFormulaRegimePrev(pTributacao.CdVinculo,
                                      pTributacao.rub.CdRubDescSCPREVFACADIC);
            
         END IF;
         
         DELETE EPAGHISTORICORUBRICARELVINC HRV1
          WHERE HRV1.CdVinculo = pTributacao.CdVinculo
            AND HRV1.CdFolhaPagamento =
                PKGPAG_VAR.vgFolha.CdFolhaPagamento
            AND HRV1.CdRubricaAgrupamento IN
                (pTributacao.rub.CdRubBaseSCPREVPatronal,pTributacao.rub.CdRubDescSCPREVPATADIC);
         
         DELETE EPAGHISTORICORUBRICAVINCULO HRV
          WHERE HRV.CdVinculo = pTributacao.CdVinculo
            AND HRV.CdFolhaPagamento =
                PKGPAG_VAR.vgFolha.CdFolhaPagamento
            AND HRV.CdRubricaAgrupamento IN
                (pTributacao.rub.CdRubBaseSCPREVPatronal,pTributacao.rub.CdRubDescSCPREVPATADIC);
         
      ELSE
         
         NULL;
         
   END CASE;
   
END;


PROCEDURE PProcessaSCPREV(pTributacao IN rTributacao) IS
BEGIN
   
   PDebug ('PProcessaSCPREV');
   
   IF pTributacao.pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13) AND
      PKGPAG_GERAL.FRetornaRegimeProprioPrev(pTributacao.CdVinculo) IN
      (1, 3, 4) THEN
      
      PCalculaSCPREV13(pTributacao => pTributacao);
      PCalculaBaseDeducIRRFSCPREV13(pTributacao => pTributacao);
      PCalculaDeducaoIRRFSCPREV13(pTributacao => pTributacao);
      
   ELSE
      
      PCalculaBaseEstendidaSCPREV(pTributacao => pTributacao);
      PCalculaFundoFinanceiro(pTributacao => pTributacao);
      PCalculaBaseDeducaoIRRFSCPREV(pTributacao => pTributacao);
      PCalculaDeducaoIRRFSCPREV(pTributacao => pTributacao);
      
   END IF;
   
   PCalculaPatronalSCPREV(pTributacao => pTributacao);
   
END;

PROCEDURE P_____________CPSM IS
BEGIN
   NULL;
END;

/*-----------------------------------------------------------------------------------------/
  Procedure  : PCalculacpsm
      
    Objetivo : Realizar o calculo de contribuicao do IPESC/IPREV
      
/-----------------------------------------------------------------------------------------*/


PROCEDURE PCalculaCPSM13(pTributacao IN rTributacao) IS
   
   --vvlContribuicao      NUMBER(15,4);
   vVlTetoGovernador NUMBER;
   vVlBase           NUMBER;
   vVlCPSM           NUMBER;
   vAliquota         NUMBER;
   
   PROCEDURE pRetornaBaseCPSM(pVlBase OUT NUMBER) IS
      
   BEGIN
      
      SELECT hrv.vlpagamento
        INTO pVlBase
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.CdRubricaAgrupamento = pkgpag_var.vgCdRubBaseIPESC13
         AND ROWNUM < 2;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pkgpag_var.vgCdRubBaseIPESC13,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => pkgpag_var.vgCdRubBaseIPESC13,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2);
         
         pVlBase := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pCdRubrica  => pkgpag_var.vgCdRubBaseIPESC13);
         
   END;
   
   PROCEDURE pRetornaBaseCPSM13(pVlBase OUT NUMBER) IS
      
   BEGIN
      
      SELECT hrv.vlpagamento
        INTO pVlBase
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.CdRubricaAgrupamento = pkgpag_var.vgCdRubBaseCPSM13
         AND ROWNUM < 2;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pkgpag_var.vgCdRubBaseCPSM13,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => pkgpag_var.vgCdRubBaseCPSM13,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2);
         
         pVlBase := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pCdRubrica  => pkgpag_var.vgCdRubBaseCPSM13);
         
   END;
   
   PROCEDURE PAtualizaValorcpsm(pvlContribuicao IN NUMBER) IS
      
      vCdExpressaoFormCalc INTEGER;
      vValorContribcpsm    NUMBER;
      
   BEGIN
      
      vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                     pCdRubricaAgrupamento => pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                                                     pCdRelacaoVinculo     => 0);
      
      IF vCdExpressaoFormCalc <> 0 THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => pkgpag_var.vgVinculo.CdVinculo,
                                               pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                               pCdRubricaAgrupamento => pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10);
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                          pCdVinculo       => pkgpag_var.vgVinculo.CdVinculo,
                                          pCdRubrica       => pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                          pTpProcessamento => 1,
                                          pTpLocal         => 2);
         
         vValorContribcpsm := FRetornaValorRubrica(pTributacao => pTributacao,
                                                   pcdrubrica  => pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13);
         
         IF vValorContribcpsm > pvlContribuicao THEN
            
            vValorContribcpsm := trunc(pVlContribuicao, 2);
            
         END IF;
         
         UPDATE EPagHistoricoRubricaVinculo HRV
            SET HRV.Vlpagamento = vValorContribcpsm
          WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
            AND HRV.CdFolhaPagamento =
                pkgpag_var.vgFolha.CdFolhaPagamento
            AND HRV.CdRubricaAgrupamento =
                pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13;
         
      END IF;
      
   EXCEPTION
      
      WHEN OTHERS THEN
         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'PKGPAG_TRIBUTACAO.PAtualizaValorCPSM13',
                                 PKGPAG_VAR.vgCdVinculo);
   END;
   
   PROCEDURE pInsereRubricaCPSM(pCdVinculo        IN INTEGER,
                                pCdFolhaPagamento IN INTEGER,
                                pVlRubrica        IN INTEGER,
                                pVlIndice         IN NUMBER) IS
      
   BEGIN
      
      pkgpag_geral.pexcluirubrica(pCdFolhaPagamento,
                                  pCdVinculo,
                                  pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                  'S',
                                  'N');
      
      IF pvlRubrica >= 0.01 THEN
         
         INSERT INTO EpagHistoricoRubricaVinculo
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
             CdTipoOrigemRubrica,
             CdTipoIndice)
         VALUES
            (Spaghistoricorubricavinculo.NEXTVAL,
             pCdFolhaPagamento,
             pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
             pCdVinculo,
             1,
             NULL,
             TRUNC(pvlRubrica, 2),
             1,
             pvlIndice,
             systimestamp,
             10,
             PKGPAG_VAR.vgRubrica(pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13).CdTipoIndice);
         
      END IF;
      
   END;
   
   PROCEDURE pAplicaAliquotaCPSM(pVlBase   IN NUMBER,
                                 pVlCPMS   OUT NUMBER,
                                 pVlIndice OUT NUMBER) IS
      
      i INTEGER := 0;
      
   BEGIN
      
      IF pkgpag_var.vAliqCPSM.lFaixa.COUNT > 0 THEN
         
         WHILE i < (pkgpag_var.vAliqCPSM.lFaixa.COUNT)
            
          LOOP
            
            i := i + 1;
            
            IF pvlBase BETWEEN pkgpag_var.vAliqCPSM.lFaixa(i).vlInicial AND pkgpag_var.vAliqCPSM.lFaixa(i).vlFinal THEN
               
               pVlCPMS := pvlBase * pkgpag_var.vAliqCPSM.lFaixa(i).VlAliquota / 100;
               
               pVlCPMS := pVlCPMS - nvl(pkgpag_var.vAliqCPSM.lFaixa(i).VlParcelaDeducao,
                                        0);
               
               IF pVlCPMS = 0 AND
                  pvlBase * pkgpag_var.vAliqCPSM.lFaixa(i).VlAliquota = 0 THEN
                  RETURN;
               END IF;
               
               pVlIndice := pkgpag_var.vAliqCPSM.lFaixa(i).VlAliquota;
               
               i := pkgpag_var.vAliqCPSM.lFaixa.COUNT + 1;
               
            END IF;
            
         END LOOP;
         
      ELSIF pkgpag_var.vAliqCPSM.VlAliquotaUnica IS NOT NULL THEN
         
         pVlCPMS := pvlBase * pkgpag_var.vAliqCPSM.VlAliquotaUnica / 100;
         
         IF pVlCPMS = 0 THEN
            RETURN;
         END IF;
         
         pVlIndice := pkgpag_var.vAliqCPSM.VlAliquotaUnica;
         
      END IF;
      
   END;
   
BEGIN
   
   PDebug ('PCalculaCPSM13');
   
   IF pTributacao.pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13) AND
      PKGPAG_VAR.vgFolha.Cdorgao = 33 THEN
      
      PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pTributacao.CdVinculo,
                                        pCdRubrica        => pTributacao.rub.CdRubDescCPSM,
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pTributacao.CdVinculo,
                                        pCdRubrica        => pTributacao.rub.CdRubBaseBASEIPREV13,
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');
      
   END IF;
   
   PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                               pCdVinculo        => pTributacao.CdVinculo,
                               pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSS13,
                               pFlExcluiAmbos    => 'S');
   ------------------------------------------------------------------------------------------------------
   -- Calcula o CPSM 13
   ------------------------------------------------------------------------------------------------------
   
   PKGPAG_GERAL.PLogProcIni('TRI0202','Processa Trib cpsm');
   
   IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_VAR.vgCdRubDescTetoGovernador) THEN
      
      vvlTetoGovernador := FRetornaValorRubrica(pTributacao => pTributacao,
                                                pcdrubrica  => PKGPAG_VAR.vgCdRubricaTetoGov);
   ELSE
      
      vvlTetoGovernador := 0;
      
   END IF;
   ----------------------------------------------------------------------------------------------------------
   
   IF pkgpag_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13 IS NULL THEN
      RETURN;
   END IF;
   
   IF pTributacao.pFolha.CdTipoFolha IN
      (PKGPAG_TIPO.cnTpFolha13, pkgpag_tipo.cnTpFolhaAdiant13) AND
      PKGPAG_VAR.vgFolha.Cdorgao = 33 THEN
      pRetornaBaseCPSM13(vVlBase);
   ELSE
      
      pRetornaBaseCPSM(vVlBase);
   END IF;
   
   IF vVlBase > 0 THEN
      pAplicaAliquotaCPSM(vVlBase, vVlCPSM, vAliquota);
      pInsereRubricaCPSM(pTributacao.CdVinculo,
                         pTributacao.pFolha.CdFolhaPagamento,
                         vVlCPSM,
                         vAliquota);
   END IF;
   
   PKGPAG_GERAL.PLogProcFim('TRI0202');
END;

PROCEDURE PCalculaCPSM(pTributacao IN rTributacao) IS
   
   --vvlContribuicao      NUMBER(15,4);
   vVlTetoGovernador NUMBER;
   vVlBase           NUMBER;
   vVlCPSM           NUMBER;
   vAliquota         NUMBER;
   
   PROCEDURE pRetornaBaseCPSM(pVlBase OUT NUMBER) IS
      
   BEGIN
      
      SELECT hrv.vlpagamento
        INTO pVlBase
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseCPSM
         AND ROWNUM < 2;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseCPSM,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseCPSM,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2);
         
         pVlBase := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pCdRubrica  => PKGPAG_VAR.vgCdRubBaseCPSM);
         
   END;
   
   PROCEDURE PAtualizaValorcpsm(pvlContribuicao IN NUMBER) IS
      
      vCdExpressaoFormCalc INTEGER;
      vValorContribcpsm    NUMBER;
      
   BEGIN
      
      vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                     pCdRubricaAgrupamento => pkgpag_var.vgCdRubDescCPSM,
                                                                     pCdRelacaoVinculo     => 0);
      
      IF vCdExpressaoFormCalc <> 0 THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => pkgpag_var.vgVinculo.CdVinculo,
                                               pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                               pCdRubricaAgrupamento => pkgpag_var.vgCdRubDescCPSM,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10);
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                          pCdVinculo       => pkgpag_var.vgVinculo.CdVinculo,
                                          pCdRubrica       => pkgpag_var.vgCdRubDescCPSM,
                                          pTpProcessamento => 1,
                                          pTpLocal         => 2);
         
         vValorContribcpsm := FRetornaValorRubrica(pTributacao => pTributacao,
                                                   pcdrubrica  => pkgpag_var.vgCdRubDescCPSM);
         
         IF vValorContribcpsm > pvlContribuicao THEN
            
            vValorContribcpsm := trunc(pVlContribuicao, 2);
            
         END IF;
         
         /*UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.Vlpagamento = 0
         WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
           AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;*/
         
         UPDATE EPagHistoricoRubricaVinculo HRV
            SET HRV.Vlpagamento = vValorContribcpsm
          WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
            AND HRV.CdFolhaPagamento =
                pkgpag_var.vgFolha.CdFolhaPagamento
            AND HRV.CdRubricaAgrupamento = pkgpag_var.vgCdRubDescCPSM;
         
      END IF;
      
   EXCEPTION
      
      WHEN OTHERS THEN
         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'PKGPAG_TRIBUTACAO.PAtualizaValorCPSM',
                                 PKGPAG_VAR.vgCdVinculo);
   END;
   
   PROCEDURE pInsereRubricaCPSM(pCdVinculo        IN INTEGER,
                                pCdFolhaPagamento IN INTEGER,
                                pVlRubrica        IN INTEGER,
                                pVlIndice         IN NUMBER) IS
      
   BEGIN
      
      pkgpag_geral.pexcluirubrica(pCdFolhaPagamento,
                                  pCdVinculo,
                                  pkgpag_var.vgCdRubDescCPSM,
                                  'S',
                                  'N');
      
      IF pvlRubrica >= 0.01 THEN
         
         BEGIN
            
            INSERT INTO EpagHistoricoRubricaVinculo
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
                CdTipoOrigemRubrica,
                CdTipoIndice)
            VALUES
               (Spaghistoricorubricavinculo.NEXTVAL,
                pCdFolhaPagamento,
                nvl(pkgpag_var.vgCdRubDescCPSM,
                    pTributacao.rub.CdRubDescCPSM),
                pCdVinculo,
                1,
                NULL,
                TRUNC(pvlRubrica, 2),
                1,
                pvlIndice,
                systimestamp,
                10,
                5);
            
         EXCEPTION
            WHEN OTHERS THEN
               PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                       PKGPAG_VAR.vCdHistParamCalc,
                                       PKGPAG_VAR.vCdPessoa,
                                       'PKGPAG_TRIBUTACAO.PAtualizaValorCPSM',
                                       PKGPAG_VAR.vgCdVinculo);
         END;
      END IF;
      
   END;
   
   PROCEDURE pAplicaAliquotaCPSM(pVlBase   IN NUMBER,
                                 pVlCPMS   OUT NUMBER,
                                 pVlIndice OUT NUMBER) IS
      
      i INTEGER := 0;
      
   BEGIN
      
      IF pkgpag_var.vAliqCPSM.lFaixa.COUNT > 0 THEN
         
         WHILE i < (pkgpag_var.vAliqCPSM.lFaixa.COUNT)
            
          LOOP
            
            i := i + 1;
            
            IF pvlBase BETWEEN pkgpag_var.vAliqCPSM.lFaixa(i).vlInicial AND pkgpag_var.vAliqCPSM.lFaixa(i).vlFinal THEN
               
               pVlCPMS := pvlBase * pkgpag_var.vAliqCPSM.lFaixa(i).VlAliquota / 100;
               
               pVlCPMS := pVlCPMS - nvl(pkgpag_var.vAliqCPSM.lFaixa(i).VlParcelaDeducao,
                                        0);
               
               IF pVlCPMS = 0 AND
                  pvlBase * pkgpag_var.vAliqCPSM.lFaixa(i).VlAliquota = 0 THEN
                  RETURN;
               END IF;
               
               pVlIndice := pkgpag_var.vAliqCPSM.lFaixa(i).VlAliquota;
               
               i := pkgpag_var.vAliqCPSM.lFaixa.COUNT + 1;
               
            END IF;
            
         END LOOP;
         
      ELSIF pkgpag_var.vAliqCPSM.VlAliquotaUnica IS NOT NULL THEN
         
         pVlCPMS := pvlBase * pkgpag_var.vAliqCPSM.VlAliquotaUnica / 100;
         
         IF pVlCPMS = 0 THEN
            RETURN;
         END IF;
         
         pVlIndice := pkgpag_var.vAliqCPSM.VlAliquotaUnica;
         
      END IF;
      
   END;
   
BEGIN
   
   PDebug ('PCalculaCPSM');
   
   ------------------------------------------------------------------------------------------------------
   -- Calcula o CPSM
   ------------------------------------------------------------------------------------------------------
   
   PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => nvl(pTributacao.rub.CdRubDescCPSM,
                                                              0),
                                     pnusufixo         => 1,
                                     pFlExcluiAmbos    => 'S');
   
   PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => nvl(pTributacao.rub.CdRubDescIPREVJUDICIAL,
                                                              0),
                                     pnusufixo         => 1,
                                     pFlExcluiAmbos    => 'S');
   
   PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => nvl(pkgpag_var.vgCdRubBaseIPESC,
                                                              0),
                                     pnusufixo         => 1,
                                     pFlExcluiAmbos    => 'S');
   
   PKGPAG_GERAL.PLogProcIni('TRI0202','Processa Trib cpsm');
   
   IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_VAR.vgCdRubDescTetoGovernador) THEN
      
      vvlTetoGovernador := FRetornaValorRubrica(pTributacao => pTributacao,
                                                pCdRubrica  => PKGPAG_VAR.vgCdRubricaTetoGov);
   ELSE
      
      vvlTetoGovernador := 0;
      
   END IF;
   ----------------------------------------------------------------------------------------------------------
   
   IF pkgpag_var.vgCdRubDescCPSM IS NULL THEN
      pkgpag_var.vgCdRubDescCPSM := pkgpag_var.vgParamPagamento.CdRubricaAgrupDescCPSM;
   END IF;
   
   pRetornaBaseCPSM(vVlBase);
   IF vVlBase > 0 THEN
      pAplicaAliquotaCPSM(vVlBase, vVlCPSM, vAliquota);
      pInsereRubricaCPSM(pTributacao.CdVinculo,
                         pTributacao.pFolha.CdFolhaPagamento,
                         vVlCPSM,
                         vAliquota);
   END IF;
  
   PKGPAG_GERAL.PLogProcFim('TRI0202');
END;

PROCEDURE P_____________IPREV IS
BEGIN
   NULL;
END;


PROCEDURE PAjustaIPREV(pTributacao IN rTributacao, pCdRubricaGerada IN Epagrubricaagrupamento.Cdrubricaagrupamento%TYPE) IS
   
   vVl080023 Epaghistoricorubricavinculo.Vlpagamento%TYPE;
   vVl080024 Epaghistoricorubricavinculo.Vlpagamento%TYPE;
   --vVl050944         Epaghistoricorubricavinculo.Vlpagamento%TYPE;
   vCdFolha13Ant       Epagfolhapagamento.Cdfolhapagamento%TYPE;
   vCdRubricaDescIpesc Epagrubricaagrupamento.Cdrubricaagrupamento%TYPE;
   
   FUNCTION fFolha13MesAnt(pCdFolhaNormalAnt IN INTEGER) RETURN INTEGER IS
      
      vCdFolha13Ant INTEGER;
      
   BEGIN
      
      WITH fol AS
       (SELECT f.cdorgao, f.nuanomesreferencia
          FROM epagfolhapagamento f
         WHERE f.cdfolhapagamento = pCdFolhaNormalAnt)
      SELECT ff.cdFolhaPagamento
        INTO vCdFolha13Ant
        FROM Epagfolhapagamento ff
       INNER JOIN epagtipofolhapagamento tfp
          ON ff.cdtipofolhapagamento = tfp.cdtipofolhapagamento
       INNER JOIN fol f
          ON f.cdorgao = ff.cdorgao
         AND f.nuanomesreferencia = ff.nuanomesreferencia
       WHERE ff.flcalculodefinitivo = 'S'
         AND tfp.cdtipofolha = pkgpag_tipo.cnTpFolha13;
      
      RETURN vCdFolha13Ant;
      
   EXCEPTION
      WHEN no_data_found THEN
         RETURN 0;
      WHEN OTHERS THEN
         RETURN 0;
         
   END;
   
BEGIN
   
   vCdRubricaDescIpesc := pTributacao.rub.CdRubDescCONTIPREV13;
   
   vVl080023 := FRetornaValorRubrica(pTributacao => pTributacao,
                                     pcdrubrica  => pTributacao.rub.CdRubDescGRAT13);
   
   vVl080024 := FRetornaValorRubrica(pTributacao => pTributacao,
                                    pcdrubrica   => pTributacao.rub.CdRubDescADIANT13);
   
   vCdFolha13Ant := fFolha13MesAnt(pTributacao.pFolha.CdFolhaPagamentoNormalAnt);
   
   /*vVl050944 := PKGPAG_GERAL.fretornavalorrubrica(pcdvinculo => pCdVinculo,
   pCdFolhaPagamento => pFolha.CdFolhaPagamento,
   pcdrubrica => PKGPAG_VAR.vgParamPagamento.CDRUBAGRUPDESCIPESCSOBRE13);*/
   
   IF (nvl(vVl080023, 0) > 0 OR nvl(vVl080024, 0) > 0) AND
      (vCdRubricaDescIpesc = pCdRubricaGerada) /*(nvl(vVl050944, 0) > 0)*/
    THEN
      PKGPAG_DT.PReprocessa13Salario(pCdVinculo        => pTributacao.CdVinculo,
                                     pCdAgrupamento    => pTributacao.pFolha.CdAgrupamento,
                                     pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdFolha13Ant     => vCdFolha13Ant,
                                     pCdFolha13        => pTributacao.pFolha.CdFolhaPagamento);
      
      PKGPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pcdvinculo        => pTributacao.CdVinculo,
                                  pcdrubrica        => PKGPAG_VAR.vgParamPagamento.CDRUBAGRUPDESCIPESCSOBRE13,
                                  pflexcluiambos    => 'S');
   END IF;
END;


FUNCTION FRetornaAliquotaIPESCRescisao(pCdTpTributacaoIPESC IN INTEGER,
                                       pNuAnoReferencia     IN INTEGER,
                                       pNuMesReferencia     IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaIPESC IS
   
   CURSOR cFaixa(pCdHistAliquotaIPESC IN INTEGER,
                 pVlIndiceRescisao    IN NUMBER) IS
      SELECT (F.VlInicial * pVlIndiceRescisao / 12) VlInicial,
             (F.VlFinal * pVlIndiceRescisao / 12) VlFinal,
             F.VlAliquota,
             (F.VlParcelaDeducao * pVlIndiceRescisao / 12) VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM EtrbaliquotafaixaIPESC F
       WHERE F.CdHistAliquotaIPESC = pCdHistAliquotaIPESC
       ORDER BY F.VlInicial;
   
   vAliquotaIPESCRescisao PKGPAG_TIPO.rAliquotaIPESC;
   vFaixaRescisao         PKGPAG_TIPO.tFaixaAliquota;
   vIndiceRescisao        NUMBER;
   
BEGIN
   
   SELECT A.CdHistAliquotaIPESC, A.VlAliquotaUnica
     INTO vAliquotaIPESCRescisao.CdHistAliquotaIPESC,
          vAliquotaIPESCRescisao.VlAliquotaUnica
     FROM ETrbHistAliquotaIPESC A
    WHERE A.CdTipoAliquota = pCdTpTributacaoIPESC
      AND ((A.nuAnoInicio < pNuAnoReferencia OR
          (A.nuAnoInicio = pNuAnoReferencia AND
          A.nuMesInicio <= pNuMesReferencia)) AND
          (A.nuAnoFinal > pNuAnoReferencia OR
          (A.nuAnoFinal = pNuAnoReferencia AND
          A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));
   
   vIndiceRescisao := pkgpag_geral.fretornaindicerubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                         PKGPAG_VAR.VGVINCULO.cdvinculo,
                                                         PKGPAG_VAR.vgCdRubricaRecisao13);
   
   OPEN cFaixa(vAliquotaIPESCRescisao.CdHistAliquotaIPESC,
               vIndiceRescisao);
   
   FETCH cFaixa BULK COLLECT
      INTO vFaixaRescisao;
   
   CLOSE cFaixa;
   
   vAliquotaIPESCRescisao.lFaixa := vFaixaRescisao;
   
   RETURN vAliquotaIPESCRescisao;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN NULL;
      
END;


PROCEDURE PGeraAbonoPermanencia13(pTributacao         IN rTributacao,
                                  pCdRubricaAbonoPerm IN INTEGER,
                                  pVlIPESC            IN NUMBER) IS
   
BEGIN
   
   IF pTributacao.pFolha.CdTipoFolha IN
      (PKGPAG_TIPO.cnTpFolha13, pkgpag_tipo.cnTpFolhaFunebre13) AND
      NOT pkgpag_geral.fpossuilanccomplementar(pTributacao.rub.CdRubProvABONPERM13,
                                               NULL) THEN
      
      IF pCdRubricaAbonoPerm > 0 AND pVlIPESC > 0.0 THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pTributacao.rub.CdRubProvABONPERM13,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => pVlIPESC,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
      END IF;
      
   END IF;
   
END;

---------------------------------------------------------
-- Exclui abono permanência se não há desconto do IPREV
---------------------------------------------------------
PROCEDURE PExcluiAbonoPermanencia(pTributacao IN rTributacao,
                                  pVlIPESC    IN NUMBER) IS
   
BEGIN
   
   IF pTributacao.pFolha.CdAgrupamento = 1 AND pVlIPESC = 0 THEN
      
      PKGPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pcdrubrica        => pTributacao.rub.CdRubProvABONOPERM);
      
   END IF;
   
END;


/*-----------------------------------------------------------------------------------------/
  Procedure  : PCalculaIPREV
      
    Objetivo : Realizar o calculo de contribuicao do IPESC/IPREV
      
/-----------------------------------------------------------------------------------------*/
PROCEDURE PCalculaIPREV(pTributacao    IN OUT NOCOPY rTributacao,
                        pTpTributacao             IN INTEGER,                            
                        pbPrima                   IN BOOLEAN) IS

   vVlDescIprev          NUMBER;
                       
   vvlContribuicao       NUMBER(15, 4);
   vvlDescRubIsentaIPREV NUMBER(15, 4);
   vvlBase               NUMBER(15, 4);
   vCdIsencaoParteContr  INTEGER;
   vvlTetoGovernador     NUMBER(15, 4);
   vAliquotaINSS         PKGPAG_TIPO.rAliquotaINSS;
   vNuDiasApo            INTEGER;
   vCont                 INTEGER;
   vCdRubricaIPREV       INTEGER;
   vVlBaseIprevEfetivo   pkgpag_tipo.rValorPagamento;
   vAliqIPESCRescisao    PKGPAG_TIPO.rAliquotaIPESC;
   vIgnoraFinanceiro     BOOLEAN := FALSE;
   vCdRubAgrupDescIPESC  Epagrubricaagrupamento.Cdrubricaagrupamento%TYPE;
   
   CURSOR cBaseIPrev(pCdSituacaoPrevidenciaria IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (B.VlBase - vvlDescRubIsentaIPREV) AS vlBase,
             B.VlDeduzido,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT cdPessoa,
                     SUM(vlBase) AS VlBase,
                     SUM(vlDeduzido) AS vlDeduzido
                FROM (SELECT CdPessoa,
                             CASE
                                WHEN CdRubricaAgrupamento = pTributacao.calc.iprev.CdRubBaseIPrev THEN
                                 nvl(vlPago, 0)
                             END AS vlBase,
                             CASE
                                WHEN CdRubricaAgrupamento IN
                                     (pTributacao.calc.iprev.CdRubDescIPrev,
                                      pTributacao.calc.iprev.CdRubDifDesc,
                                      pTributacao.calc.iprev.CdRubDescIprev2008,
                                      pTributacao.calc.iprev.CdRubDifDesc2008) THEN
                                 nvl(vlPago, 0)
                                WHEN CdRubricaAgrupamento IN
                                     (pTributacao.calc.iprev.CdRubDevDesc,
                                      pTributacao.calc.iprev.CdRubDevDesc2008) THEN
                                 nvl(vlPago, 0) * -1
                             END AS vlDeduzido
                        FROM (SELECT V.CdPessoa,
                                     RV.CdRubricaAgrupamento,
                                     SUM(RV.vlPagamento) AS vlPago
                                FROM EPagHistoricoRubricaVinculo RV
                                 
                               INNER JOIN ECalFolhaTrib FP
                                  ON FP.SGTRIBUTO =
                                     PKGPAG_TIPO.cnSgTribIPRV
                                 AND FP.TPMES =
                                     PKGPAG_TIPO.cnTpMesTribAtual
                                 AND FP.CdCalculoPai =
                                     PKGPAG_VAR.vgCalculo.CdCalculoPai
                                 AND FP.CdFolhaPagamento =
                                     RV.CdFolhaPagamento
                               INNER JOIN ECadVinculo V
                                  ON V.CdVinculo = RV.CdVinculo
                               WHERE V.CdPessoa = pTributacao.CdPessoa
                                 AND (RV.CdRubricaAgrupamento IN
                                     (pTributacao.calc.iprev.CdRubBaseIPrev,
                                       pTributacao.calc.iprev.CdRubDescIPrev,
                                       pTributacao.calc.iprev.CdRubDifDesc,
                                       pTributacao.calc.iprev.CdRubDevDesc,
                                       pTributacao.calc.iprev.CdRubDescIPrev2008,
                                       pTributacao.calc.iprev.CdRubDifDesc2008,
                                       pTributacao.calc.iprev.CdRubDevDesc2008))
                                 AND -- Desconsiderar a folha normal do orgao quando fazendo recalculo
                                     (NOT
                                      (pTributacao.pFolha.CdTipoCalculo IN
                                      (PKGPAG_TIPO.cnTpCalculoRecalculoMes) -- Fazendo Recalculo
                                      AND
                                      ((RV.CdVinculo = pTributacao.CdVinculo AND
                                      (FP.CdFolhaPagamento =
                                      PKGPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                      (FP.CdFolhaPagamento <>
                                      pTributacao.pFolha.CdFolhaPagamento AND
                                      FP.CdTipoCalculo IN
                                      (PKGPAG_TIPO.cnTpCalculoRecalculoMes)))) OR
                                      (RV.CdVinculo <> pTributacao.CdVinculo AND
                                      FP.CdTipoCalculo IN
                                      (PKGPAG_TIPO.cnTpCalculoRecalculoMes)))))
                                       
                                 AND (NOT (pTributacao.pFolha.CdTipoCalculo =
                                      PKGPAG_TIPO.cnTpCalculoDifMes AND
                                      PKGPAG_VAR.vgFaseCalculo =
                                      PKGPAG_TIPO.cnFaseCalculoIntegral AND
                                      ((RV.CdVinculo = pTributacao.CdVinculo AND
                                      (FP.CdFolhaPagamento =
                                      PKGPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                      (FP.CdFolhaPagamento <>
                                      pTributacao.pFolha.CdFolhaPagamento AND
                                      FP.CdTipoCalculo =
                                      PKGPAG_TIPO.cnTpCalculoDifMes))) OR
                                      (RV.CdVinculo <> pTributacao.CdVinculo AND
                                      FP.CdTipoCalculo =
                                      PKGPAG_TIPO.cnTpCalculoDifMes))))
                                       
                                 AND
                                    /*    (FP.CdFolhaPagamentoNormal <> PKGPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                    FP.CdFolhaPagamentoEspec = pFolha.CdFolhaPagamento) AND */
                                     NOT EXISTS
                               (SELECT 1
                                        FROM ETrbRecolhimentoAvulso T
                                       WHERE T.CdPessoa = V.CdPessoa
                                         AND T.CdObjetoRecolhimento = 2
                                         AND T.FlAnulado = PKGPAG_TIPO.cnN
                                         AND ((T.NuAnoInicio <
                                             pTributacao.pFolha.NuAnoReferencia OR
                                             (T.NuAnoInicio =
                                             pTributacao.pFolha.NuAnoReferencia AND
                                             T.NuMesInicio <=
                                             pTributacao.pFolha.NuMesReferencia)) AND
                                             (T.nuAnoFim >
                                             pTributacao.pFolha.NuAnoReferencia OR
                                             (T.nuAnoFim =
                                             pTributacao.pFolha.NuAnoReferencia AND
                                             T.nuMesFim >=
                                             pTributacao.pFolha.NuMesReferencia) OR
                                             T.nuAnoFim IS NULL)))
                               GROUP BY V.CdPessoa, RV.CdRubricaAgrupamento))
               GROUP BY CdPessoa) B
       INNER JOIN ecadVinculo V
          ON V.CdPessoa = B.CdPessoa
       WHERE V.CdVinculo = pTributacao.CdVinculo;
   
   CURSOR cBaseAliqUnica(pCdSituacaoPrevidenciaria IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (A.VlBase - vvlDescRubIsentaIPREV) AS VlBase,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT RV.CdVinculo, SUM(RV.vlPagamento) AS vlBase
                FROM Epaghistoricorubricavinculo RV
               WHERE RV.CdRubricaAgrupamento = pTributacao.calc.iprev.CdRubBaseIPrev
                 AND RV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                 AND RV.cdVinculo = pTributacao.CdVinculo
               GROUP BY RV.CdVinculo) A
       INNER JOIN ECadVinculo V
          ON V.CdVinculo = A.CdVinculo
       WHERE V.CdVinculo = pTributacao.CdVinculo
         AND NOT EXISTS
       (SELECT 1
                FROM ETrbIsencaoParteContribuicao IC
               INNER JOIN Etrbhistisencaopartecontrib HIC
                  ON IC.Cdisencaopartecontribuicao =
                     HIC.Cdisencaopartecontribuicao
               WHERE V.CdVinculo = IC.Cdvinculo
                 AND HIC.Flanulado = PKGPAG_TIPO.cnN
                 AND ((HIC.nuAnoInicioVigencia < pTributacao.pFolha.NuAnoReferencia OR
                     (HIC.nuAnoInicioVigencia = pTributacao.pFolha.NuAnoReferencia AND
                     HIC.nuMesInicioVigencia <= pTributacao.pFolha.NuMesReferencia)) AND
                     (HIC.nuAnoFimVigencia > pTributacao.pFolha.NuAnoReferencia OR
                     (HIC.nuAnoFimVigencia = pTributacao.pFolha.NuAnoReferencia AND
                     HIC.nuMesFimVigencia > pTributacao.pFolha.NuMesReferencia) OR
                     HIC.nuAnoFimVigencia IS NULL)));
 
   -- A verificação da isenção é feita antes. Por conta da forma de trabalho adotada
   -- o servidor pode ter isenção parcial desde que tenha decisão judicial de tributação e bloqueio 
   -- na rubrica 05-0924
  
   CURSOR cBaseAliqUnicaIsencao(pCdSituacaoPrevidenciaria IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (A.VlBase - vvlDescRubIsentaIPREV) AS VlBase,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT RV.CdVinculo, SUM(RV.vlPagamento) AS vlBase
                FROM EPagHistoricoRubricaVinculo RV
               WHERE RV.Cdrubricaagrupamento = pTributacao.calc.iprev.CdRubBaseIPrev
                 AND RV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                 AND RV.cdVinculo = pTributacao.CdVinculo
               GROUP BY RV.CdVinculo) A
       INNER JOIN ECadVinculo V
          ON V.CdVinculo = A.CdVinculo
 /*           
       INNER JOIN ETrbIsencaoParteContribuicao IC
          ON V.CdVinculo = IC.Cdvinculo
       INNER JOIN Etrbhistisencaopartecontrib HIC
          ON IC.Cdisencaopartecontribuicao =
             HIC.Cdisencaopartecontribuicao
         AND HIC.FlAnulado = PKGPAG_TIPO.cnN
         AND ((HIC.NuAnoInicioVigencia < pTributacao.pFolha.NuAnoReferencia OR
             (HIC.NuAnoInicioVigencia = pTributacao.pFolha.NuAnoReferencia AND
             HIC.NuMesInicioVigencia <= pTributacao.pFolha.NuMesReferencia)) AND
             (HIC.NuAnoFimVigencia > pTributacao.pFolha.NuAnoReferencia OR
             (HIC.NuAnoFimVigencia = pTributacao.pFolha.NuAnoReferencia AND
             HIC.NuMesFimVigencia >= pTributacao.pFolha.NuMesReferencia) OR
             HIC.NuAnoFimVigencia IS NULL))
*/             
       WHERE V.CdVinculo = pTributacao.CdVinculo
         AND V.CdSituacaoPrevidenciaria = CASE
                WHEN PKGPAG_VAR.vgFolha.CdTipoFolha =
                     PKGPAG_TIPO.cnTpFolhaFunebre THEN
                 v.Cdsituacaoprevidenciaria
                ELSE
                 pCdSituacaoPrevidenciaria
             END
         AND ROWNUM < 2;
   
   CURSOR cBasePNPDecJudRem(pCdSituacaoPrevidenciaria IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (A.VlBase - vvlDescRubIsentaIPREV) AS VlBase,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT RV.CdVinculo, SUM(RV.vlPagamento) AS vlBase
                FROM EPagHistoricoRubricaVinculo RV
               WHERE RV.Cdrubricaagrupamento = pTributacao.calc.iprev.CdRubBaseIPrev
                 AND RV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                 AND RV.cdVinculo = pTributacao.CdVinculo
               GROUP BY RV.CdVinculo) A
       INNER JOIN ECadVinculo V
          ON V.CdVinculo = A.CdVinculo
       WHERE V.CdVinculo = pTributacao.CdVinculo
         AND V.CdSituacaoPrevidenciaria = pCdSituacaoPrevidenciaria
         AND ROWNUM < 2;
   
   PROCEDURE PReGeraBasesIPREV(pCdTipoRegimeProprioPrev INTEGER) IS
     
   BEGIN
      
      IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria NOT IN
         (PKGPAG_TIPO.cnSitPrevAposentado,
          PKGPAG_TIPO.cnSitPrevPensaoPrev) AND pbPrima THEN
         
         IF pCdTipoRegimeProprioPrev IN (1, 3) THEN
            
            BEGIN
               
               SELECT 1
                 INTO vCont
                 FROM EPagHistoricoRubricaVinculo HRV
                WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                  AND HRV.CdVinculo = pTributacao.CdVinculo
                  AND HRV.CdRubricaAgrupamento =
                      PKGPAG_VAR.vgCdRubBaseIPREVFF
                  AND ROWNUM < 2;
               
            EXCEPTION
               
               WHEN NO_DATA_FOUND THEN
                  
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pTributacao.CdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIPREVFF,
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => 0,
                                                        pVlIndice             => NULL,
                                                        pCdTipoOrigemRubrica  => 1);
                  
            END;
            
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pTributacao.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseProv13PatFF, --321
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);
            
         ELSIF pCdTipoRegimeProprioPrev = 4 THEN
            
            BEGIN
               
               SELECT 1
                 INTO vCont
                 FROM EPagHistoricoRubricaVinculo HRV
                WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                  AND HRV.CdVinculo = pTributacao.CdVinculo
                  AND HRV.CdRubricaAgrupamento =
                      PKGPAG_VAR.vgCdRubBaseIPREVFT
                  AND ROWNUM < 2;
               
            EXCEPTION
               
               WHEN NO_DATA_FOUND THEN
                  
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pTributacao.CdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => pkgpag_var.vgCdRubBaseIPREVFT,
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => 0,
                                                        pVlIndice             => NULL,
                                                        pCdTipoOrigemRubrica  => 1);
                  
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pTributacao.CdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => pkgpag_var.vgCdRubBaseProv13FT, --341
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => 0,
                                                        pVlIndice             => NULL,
                                                        pCdTipoOrigemRubrica  => 1);
            END;
            
         ELSE
            
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pTributacao.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIPREVFP,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);
            
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pTributacao.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseProv13PatFP, --79
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);
            
         END IF;
         
      END IF;
      
   END;
   
   PROCEDURE PAtualizaBaseIPESC(pvlBase    IN NUMBER,
                                pbCCO      IN BOOLEAN DEFAULT FALSE,
                                pbAtualiza IN BOOLEAN DEFAULT FALSE) IS
      
   BEGIN
      
      IF vvlDescRubIsentaIPREV > 0 OR pbCCO OR pbAtualiza THEN
         
         UPDATE EPagHistoricoRubricaVinculo HRV
            SET HRV.Vlpagamento = pvlBase
          WHERE HRV.CdVinculo = pTributacao.CdVinculo
            AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
            AND HRV.CdRubricaAgrupamento = pTributacao.calc.iprev.CdRubBaseIPrev;
         
         IF pbCCO THEN
            
            UPDATE EPagHistoricoRubricaVinculo HRV
               SET HRV.Vlpagamento = 0
             WHERE HRV.CdVinculo = pTributacao.CdVinculo
               AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseOPCAOART27;
            
         END IF;
         
         IF pbAtualiza THEN
            
            UPDATE EPagHistoricoRubricaRelVinc HRVI
               SET HRVI.Vlproporcional = pvlBase,
                   HRVI.VlReal         = pvlBase,
                   HRVI.Dtinicio       = pkgpag_var.vgRelVinc(1).DtInicio,
                   HRVI.Dtfim          = pkgpag_var.vgRelVinc(1).DtFim
             WHERE HRVI.CdVinculo = pTributacao.CdVinculo
               AND HRVI.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
               AND HRVI.CdRubricaAgrupamento = pTributacao.calc.iprev.CdRubBaseIPrev;
            
         END IF;
         
      END IF;
      
   EXCEPTION
      WHEN OTHERS THEN
         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'PKGPAG_TRIBUTACAO.PAtualizaBaseIPESC',
                                 PKGPAG_VAR.vgCdVinculo);
         
   END;
   
   PROCEDURE PAtualizaValorIPESC(pvlContribuicao IN NUMBER,
                                 pCdRubricaIpesc INTEGER) IS
      
   BEGIN
      
      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.Vlpagamento = pvlContribuicao
       WHERE HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;
      
   EXCEPTION
      WHEN OTHERS THEN
         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'PKGPAG_TRIBUTACAO.PAtualizaValorIPESC',
                                 PKGPAG_VAR.vgCdVinculo);
         
   END;
   
   PROCEDURE PAtualizaValorCPSM(pFolha          IN PKGPAG_TIPO.rFolha,
                                pCdVinculo      IN INTEGER,
                                pvlContribuicao IN NUMBER,
                                pCdRubricaIpesc IN INTEGER,
                                pCdRubricaCPSM  IN INTEGER) IS
      
      vCdExpressaoFormCalc INTEGER;
      vValorContribCPSM    NUMBER;
      vPossuiLFRubricaCPSM BOOLEAN;
      vVlIprevProp         NUMBER := 0;
      vVlCPSMProp          NUMBER := 0;
      vVlBase              NUMBER := 0;
      
   BEGIN
      
      vPossuiLFRubricacpsm := PKGPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                                                 pFolha,
                                                                 pCdRubricacpsm);
      
      IF NOT vPossuiLFRubricacpsm THEN
         
         vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                        pCdRubricaAgrupamento => pCdRubricacpsm,
                                                                        pCdRelacaoVinculo     => 0);
         IF vCdExpressaoFormCalc <> 0 THEN
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pkgpag_var.vgFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pkgpag_var.vgVinculo.CdVinculo,
                                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                  pCdRubricaAgrupamento => pCdRubricacpsm,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 10);
            
            PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                             pCdVinculo       => pkgpag_var.vgVinculo.CdVinculo,
                                             pCdRubrica       => pCdRubricacpsm,
                                             pTpProcessamento => 1,
                                             pTpLocal         => 2);
            
         END IF;
         
         vValorContribcpsm := FRetornaValorRubrica(pTributacao => pTributacao,
                                                   pcdrubrica  => pCdRubricacpsm,
                                                   pnusufixo   => 1);
         
         vVlBase := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pcdrubrica  => pTributacao.rub.CdRubBaseBASEIPREV);
         
         IF vValorContribcpsm > pvlContribuicao THEN
            
            IF pFolha.NuAnoReferencia = 2020 AND
               pFolha.NuMesReferencia = 3 THEN
               
               vVlIprevProp := trunc(pVlContribuicao / 30 * 16, 2);
               
               vVlCPSMProp := vVlIprevProp;
               
               vValorContribCPSM := vValorContribCPSM / 30 * 14;
               
            ELSE
               
               vValorContribcpsm := trunc(pVlContribuicao, 2);
               
            END IF;
            
         END IF;
         
      END IF;
      
      IF vVlCPSMProp > 0 THEN
         
         pkgpag_geral.pinserelancamentovinculo(pcdfolhapagamento     => pFolha.CdFolhaPagamento,
                                               pcdvinculo            => pkgpag_var.vgVinculo.CdVinculo,
                                               pcdexpressaoformcalc  => NULL,
                                               pcdrubricaagrupamento => pCdRubricacpsm,
                                               pnusufixorubrica      => 2,
                                               pvlpagamento          => vValorContribCPSM,
                                               pcdtipoorigemrubrica  => 10,
                                               pDeExpressao          => vVlBase ||
                                                                        '* 0.095 / 30 * 14');
         
      ELSE
         
         vVlCPSMProp := vValorContribCPSM;
         
      END IF;
      
      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.Vlpagamento = 0
       WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;
      
      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET HRV.Vlintegral = 0, HRV.VlReal = 0, HRV.Vlproporcional = 0
       WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;
      
      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.Vlpagamento = vVlCPSMProp
       WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricacpsm
         AND HRV.Nusufixorubrica = 1;
      
      -- Trocar codigo da base
      
      DELETE EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseCPSM
         AND HRV.Nusufixorubrica = 1;
      
      DELETE EPagHistoricoRubricaRelVinc HRV
       WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseCPSM
         AND HRV.Nusufixorubrica = 1;
      
      UPDATE EPagHistoricoRubricaVinculo HRV
         SET hrv.cdrubricaagrupamento = pTributacao.rub.CdRubBaseCPSM
       WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseBASEIPREV;
      
      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET hrv.cdrubricaagrupamento = pTributacao.rub.CdRubBaseCPSM 
       WHERE HRV.CdVinculo = pkgpag_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = pkgpag_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pTributacao.rub.CdRubBaseBASEIPREV;
      
   EXCEPTION
      
      WHEN OTHERS THEN
         NULL;
   END;
   
   FUNCTION FCalculaIPESC
      
    RETURN BOOLEAN IS
      
   BEGIN
      
      IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento =
         PKGPAG_TIPO.cnRelResidente THEN
         
         RETURN FALSE;
         
         /*ELSE
               
         SELECT COUNT(*)
           INTO vCont
           FROM ECadVinculo V
          WHERE V.CdVinculo = pCdVinculo
            AND V.CdRegimePrevidenciario in
                (PKGPAG_TIPO.cnRegPrevProprio, pkgpag_tipo.cnRegPrevCPSM);
               
         IF vCont > 0 THEN
               
           RETURN TRUE;
               
         ELSE
               
           RETURN FALSE;
               
         END IF;*/
         
      END IF;
      
      RETURN TRUE;
      
   END;
   
   FUNCTION FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev IN INTEGER,
                                     pcdRubrica1              IN INTEGER,
                                     pcdRubrica2              IN INTEGER,
                                     pcdRubricaDescSCFuturo13 IN INTEGER)
      RETURN INTEGER IS
      
   BEGIN
      
      IF pCdTipoRegimeProprioPrev = 1 THEN
         
         RETURN pcdRubrica1;
         
      ELSIF pCdTipoRegimeProprioPrev = 4 AND
            pcdRubricaDescSCFuturo13 IS NOT NULL THEN
         
         RETURN pcdRubricaDescSCFuturo13;
         
      ELSE
         
         RETURN pcdRubrica2;
         
      END IF;
      
   END;
   
   FUNCTION FRubricaGerada(pCdTipoRegimeProprioPrev IN INTEGER,
                           pvlDeduzido              IN NUMBER,
                           pvlContribuicao          IN NUMBER)
      RETURN INTEGER IS
      
   BEGIN
      
      CASE
         
         WHEN pvlDeduzido > 0 THEN
            
            CASE
               
               WHEN pvlContribuicao > 0 THEN
                  
                  CASE
                     
                     WHEN PKGPAG_VAR.vgFaseCalculo =
                          PKGPAG_TIPO.cnFaseCalculoIntegral THEN
                        
                        RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                                        pTributacao.calc.iprev.CdRubDescIPrev,
                                                        pTributacao.calc.iprev.CdRubDescIPrev2008,
                                                        pTributacao.calc.iprev.CdRubDescSCFuturo13);
                        
                     ELSE
                        
                        RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                                        pTributacao.calc.iprev.CdRubDifDesc,
                                                        pTributacao.calc.iprev.CdRubDifDesc2008,
                                                        pTributacao.calc.iprev.CdRubDifSCFuturo13); --  gera rubrica do tipo 6
                     
                  END CASE;
                  
               WHEN pvlContribuicao < 0 THEN
                  
                  RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                                  pTributacao.calc.iprev.CdRubDevDesc,
                                                  pTributacao.calc.iprev.CdRubDevDesc2008,
                                                  pTributacao.calc.iprev.CdRubDevSCFuturo13); --  gera rubrica do tipo 4
               
            END CASE;
            
         WHEN pvlDeduzido = 0 THEN
            
            CASE
               
               WHEN pvlContribuicao > 0 THEN
                  
                  RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                                  pTributacao.calc.iprev.CdRubDescIPrev,
                                                  pTributacao.calc.iprev.CdRubDescIPrev2008,
                                                  pTributacao.calc.iprev.CdRubDescSCFuturo13);
                  
               ELSE
                  
                  RETURN 0;
                  
            END CASE;
            
      END CASE;
      
   END;
   
   PROCEDURE InsereRubricaIPESC(pCdVinculo        IN INTEGER,
                                pCdRubricaGerada  IN INTEGER,
                                pCdFolhaPagamento IN INTEGER,
                                pVlRubrica        IN INTEGER,
                                pVlIndice         IN NUMBER) IS
      
      vvlRubrica NUMBER(15, 4);
      
   BEGIN
      
      vCdRubricaIprev := pCdRubricaGerada;
      
      IF pCdRubricaGerada IN
         (pTributacao.calc.iprev.CdRubDifDesc,
          pTributacao.calc.iprev.CdRubDevDesc,
          pTributacao.calc.iprev.CdRubDifDesc2008,
          pTributacao.calc.iprev.CdRubDevDesc2008) THEN
         
         vvlRubrica := ABS(pVlRubrica);
         
      ELSE
         
         vvlRubrica := pVlRubrica;
         
      END IF;
      
      IF pCdRubricaGerada > 0 AND vvlRubrica >= 0.01 THEN
         
         INSERT INTO EpagHistoricoRubricaVinculo
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
             CdTipoOrigemRubrica,
             CdTipoIndice)
         VALUES
            (Spaghistoricorubricavinculo.NEXTVAL,
             pCdFolhaPagamento,
             pCdRubricaGerada,
             pCdVinculo,
             1,
             NULL,
             TRUNC(vvlRubrica, 2),
             1,
             pvlIndice,
             systimestamp,
             10,
             PKGPAG_VAR.vgRubrica(pCdRubricaGerada).CdTipoIndice);
         
         vVlDescIprev := TRUNC(vvlRubrica, 2);
         
      ELSE
         
         vVlDescIprev := 0.0;
         
      END IF;
      
   END;
   
   PROCEDURE pAplicaAliquotaIsolada(lFaixa IN PKGPAG_TIPO.tFaixaAliquota) IS
      
      i                INTEGER;
      vCdRubricaGerada INTEGER;
      vvlBase          NUMBER(15, 4);
      
   BEGIN
      
      FOR c IN cBaseAliqUnica(pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP
         
         i := 0;
         
         IF nvl(c.vlBase, 0) > vvlTetoGovernador AND
            vvlTetoGovernador > 0 THEN
            
            vvlBase := vvlTetoGovernador;
            
         ELSE
            
            vvlBase := c.vlBase;
            
         END IF;
         
         WHILE i < (lFaixa.COUNT)
            
          LOOP
            
            i := i + 1;
            
            IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN
               
               PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                  pbAtualiza => CASE
                                                   WHEN pkgpag_var.vgNuDiasApo > 0 THEN
                                                    TRUE
                                                   ELSE
                                                    FALSE
                                                END);
               
               vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;
               
               vvlContribuicao := vvlContribuicao -
                                  nvl(lFaixa(i).VlParcelaDeducao, 0);
               
               IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                  
                  IF PKGPAG_VAR.VGFOLHA.CDORGAO = 33 AND -- sig 7062
                     pkgpag_geral.fpossuiregistroobito(pkgpag_var.vCdPessoa,
                                                       pkgpag_var.vgFolha.cdAgrupamento,
                                                       'S') THEN
                     
                     vvlContribuicao := vvlContribuicao *
                                        PKGPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                                                      pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia,
                                                                                      pFlIntegral           => TRUE) /
                                        pkgpag_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pTributacao.CdVinculo,
                                                                                         pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia);
                  ELSE
                     vvlContribuicao := vvlContribuicao *
                                        PKGPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                                                      pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia) /
                                        pkgpag_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pTributacao.CdVinculo,
                                                                                         pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia);
                  END IF;
               END IF;
               
               IF vvlContribuicao = 0 AND
                  vvlBase * lFaixa(i).VlAliquota = 0 THEN
                  RETURN;
               END IF;
               
               IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = pkgpag_tipo.cnRegPrevCPSM AND
                  pTributacao.iprev.FlCpsmParaIprev = 1 THEN
                  
                  vCdRubricaGerada := pTributacao.calc.iprev.CdRubDescIPrev;
                  
               ELSE
                  
                  vCdRubricaGerada := FRubricaGerada(c.CdTipoRegimeProprioPrev,
                                                     0,
                                                     vvlContribuicao);
               END IF;
               
               -- SIG-7288
               -- SIGRH - [Chamado 16784/2021] - PROPORCIONALIZAR PARA 20 DIAS VALORES DA RUBRICA 05-0924-01 SERVIDORES INATIVOS DO AGPE
               IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 2 AND
                  (pkgpag_var.vgFolha.nuanoreferencia = 2021 AND
                  pkgpag_var.vgFolha.numesreferencia = 11) AND pkgpag_var.vgrubrica(vCdRubricaGerada).NuRubrica = 924 AND pkgpag_var.vgrubrica(vCdRubricaGerada).CdTipoRubrica = 5 AND
                  pTributacao.pFolha.CdAgrupamento IN (1, 132, 133) THEN
                  
                  vvlContribuicao := vvlContribuicao / 30 * 20;
                  
               END IF;
               
               InsereRubricaIPESC(c.CdVinculo,
                                  vCdRubricaGerada,
                                  pTributacao.pFolha.CdFolhaPagamento,
                                  vvlContribuicao,
                                  lFaixa(i).VlAliquota);
               
               PAjustaIPREV(pTributacao      => pTributacao,
                            pCdRubricaGerada => vCdRubricaGerada);
               
               PRegeraBasesIPREV(c.cdtiporegimeproprioprev);
               
               i := lFaixa.COUNT + 1;
               
            END IF;
            
         END LOOP;
         
      END LOOP;
      
   END;
   
   PROCEDURE pAplicaAliquotaIsenPNP(lFaixa IN PKGPAG_TIPO.tFaixaAliquota) IS
      
      i INTEGER;
      
      vCdRubricaGerada INTEGER;
      
      vvlBase NUMBER(15, 4);
      
   BEGIN
      
      FOR c IN cBasePNPDecJudRem(pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP
         
         i       := 0;
         vvlBase := c.vlBase;
         
         WHILE i < (lFaixa.COUNT)
            
          LOOP
            
            i := i + 1;
            
            IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN
               
               vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;
               
               vvlContribuicao := vvlContribuicao -
                                  nvl(lFaixa(i).VlParcelaDeducao, 0);
               
               vCdRubricaGerada := FRubricaGerada(c.CdTipoRegimeProprioPrev,
                                                  0,
                                                  vvlContribuicao);
               
               InsereRubricaIPESC(c.CdVinculo,
                                  vCdRubricaGerada,
                                  pTributacao.pFolha.CdFolhaPagamento,
                                  vvlContribuicao,
                                  lFaixa(i).VlAliquota);
               
               PRegeraBasesIPREV(c.cdtiporegimeproprioprev);
               
               i := lFaixa.COUNT + 1;
               
            END IF;
            
         END LOOP;
         
      END LOOP;
      
   END;
   
   PROCEDURE pAplicaAliquotaIsoladaIsen(lFaixa IN PKGPAG_TIPO.tFaixaAliquota) IS
      
      i INTEGER;
      
      vCdRubricaGerada INTEGER;
      
      vvlBase NUMBER(15, 4);
      
   BEGIN
      
      FOR c IN cBaseAliqUnicaIsencao(pCdSituacaoPrevidenciaria => PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP
         
         i := 0;
         
         IF c.vlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN
            
            vvlBase := vvlTetoGovernador;
            
         ELSE
            
            vvlBase := c.vlBase;
            
         END IF;
         
         WHILE i < (lFaixa.COUNT)
            
          LOOP
            
            i := i + 1;
            
            IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN
               
               PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                  pbAtualiza => CASE
                                                   WHEN pkgpag_var.vgNuDiasApo > 0 THEN
                                                    TRUE
                                                   ELSE
                                                    FALSE
                                                END);
               
               vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;
               
               vvlContribuicao := vvlContribuicao -
                                  nvl(lFaixa(i).VlParcelaDeducao, 0);
               
               IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                  vvlContribuicao := vvlContribuicao *
                                     PKGPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                                                   pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia) /
                                     pkgpag_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pTributacao.CdVinculo,
                                                                                      pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia);
                  /*
                        
                                vvlContribuicao *
                                                   PKGPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => pCdVinculo,
                                                                                                 pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                                          pFolha.NuMesReferencia) / 100;
                  */
               END IF;
               
               vCdRubricaGerada := FRubricaGerada(c.CdTipoRegimeProprioPrev,
                                                  0,
                                                  vvlContribuicao);
               
               InsereRubricaIPESC(c.CdVinculo,
                                  vCdRubricaGerada,
                                  pTributacao.pFolha.CdFolhaPagamento,
                                  vvlContribuicao,
                                  lFaixa(i).VlAliquota);
               
               PAjustaIPREV(pTributacao      => pTributacao,
                            pCdRubricaGerada => vCdRubricaGerada);
               
               PRegeraBasesIPREV(c.cdtiporegimeproprioprev);
               
               i := lFaixa.COUNT + 1;
               
            END IF;
            
         END LOOP;
         
      END LOOP;
      
   END;
   
   PROCEDURE PAplicaAliquotaApoMesAnt IS
      
      i INTEGER;
      
      vCdRubricaGerada INTEGER := pTributacao.rub.CdRubDescIPREVFF; -- 05-0924;
      
      vvlBase NUMBER(15, 4);
      
      vVlBaseRealAnt pkgpag_tipo.rvalorpagamento;
      
      lFaixa PKGPAG_TIPO.tFaixaAliquota := PKGPAG_VAR.vAliqIPESCInativo.lFaixa;
      
      vCdBaseCalculo INTEGER;
      
      --vVlBloqueio             NUMBER(15,4);
      
      vNuDias INTEGER := 0;
      
      vNuDiasPropApo INTEGER := 0;
      
      --vVlIndice               number(10,4);
      
   BEGIN
      
      -- Se data da aposentadoria NAO foi no mes anterior, entao nao gera aliquota
      IF NOT
          (PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 2 AND
          PKGPAG_VAR.vgApo.count > 0 AND PKGPAG_VAR.vgApo(1)
          .DtInicioRelacao > trunc(PKGPAG_VAR.vgFolha.DtCalculoAnt, 'mm') AND PKGPAG_VAR.vgApo(1)
          .DtInicioRelacao < PKGPAG_VAR.vgFolha.dtInicioMes) THEN
         
         RETURN;
         
      END IF;
      
      pkgpag_param.PArmazenaInfoFolhaNormalAnt(PKGPAG_VAR.vgFolha.cdFolhaPagamentoNormalAnt);
      
      --
      -- Para retroativos que possuem processos de compensacao associados
      --
      
      vCdBaseCalculo := pkgpag_var.vgrubrica(pTributacao.rub.CdRubBaseBASEIPREV).cdbasecalculo;
      
      vVlBaseRealAnt := pkgpag_fb.fretornavalorbasecalculo(pFolha            => pkgpag_var.vgFolhaNormalAnt,
                                                           pCdVinculo        => pTributacao.cdvinculo,
                                                           pCdTipoHistorico  => 2,
                                                           pCdRelacaoVinculo => 0,
                                                           pCdBaseCalculo    => vcdbasecalculo,
                                                           pCdChave          => pTributacao.cdvinculo,
                                                           pCdFolhaAnt       => PKGPAG_VAR.vgFolha.cdFolhaPagamentoNormalAnt);
      
      SELECT hrv.vlproporcional AS vlBase,
             (hrv.dtfim - hrv.dtinicio + 1)
        INTO vvlBase, vNuDias
        FROM epaghistoricorubricarelvinc hrv
       WHERE hrv.cdfolhapagamento =
             PKGPAG_VAR.vgFolha.cdFolhaPagamentoNormalAnt -- FOLHA MES APOSENTADORIA
         AND hrv.cdrubricaagrupamento = pTributacao.rub.CdRubBaseBASEIPREV  -- 09-0916-01 BASE CAL-IPREV
         AND hrv.cdvinculo = pTributacao.CdVinculo
         AND hrv.cdhistcargoefetivo IS NOT NULL;
      
      IF vVlBaseRealAnt.vlProporcional > vvlTetoGovernador AND
         vvlTetoGovernador > 0 THEN
         vvlBaseRealAnt.vlProporcional := vvlTetoGovernador;
         
         vVlBase := vVlBaseRealAnt.VlProporcional / 30 * vNuDias;
         
      ELSE
         
         vVlBase := vVlBaseRealAnt.vlProporcional - vVlBase;
         
         IF vvlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN
            
            vvlBase := vvlTetoGovernador;
            
         END IF;
         
         ---------------------
      END IF;
      
      i := 0;
      
      IF vCdIsencaoParteContr IS NOT NULL THEN
         
         lFaixa := PKGPAG_VAR.vAliqIPESCParcial.lFaixa;
         
      END IF;
      
      vNuDiasPropApo := 30 - nvl(vNuDias, 0);
      
      WHILE i < (lFaixa.COUNT)
         
       LOOP
         
         i := i + 1;
         
         IF vvlBase BETWEEN CASE WHEN lFaixa(i).vlInicial > 0
          THEN(lFaixa(i).vlInicial / 30 * vNuDiasPropApo) ELSE lFaixa(i).vlInicial
          END AND CASE WHEN lFaixa(i).vlFinal < 9999999
          THEN(lFaixa(i).vlFinal / 30 * vNuDiasPropApo) ELSE lFaixa(i).vlFinal END THEN
            
            vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;
            
            vvlContribuicao := vvlContribuicao -
                               (nvl(lFaixa(i).VlParcelaDeducao, 0) / 30 *
                               vNuDiasPropApo);
            
            IF vvlContribuicao >= 0.01 THEN
               
               INSERT INTO EpagHistoricoRubricaVinculo
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
                   CdTipoOrigemRubrica,
                   CdTipoIndice)
               VALUES
                  (Spaghistoricorubricavinculo.NEXTVAL,
                   PKGPAG_VAR.vgFolha.cdfolhapagamento,
                   vCdRubricaGerada,
                   pTributacao.CdVinculo,
                   2,
                   NULL,
                   TRUNC(vvlContribuicao, 2),
                   1,
                   lFaixa(i).VlAliquota,
                   systimestamp,
                   10,
                   PKGPAG_VAR.vgRubrica(vCdRubricaGerada).CdTipoIndice);
               
            END IF;
            
            EXIT;
            
         END IF;
         ---------------------
         
      END LOOP;
      
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
         
   END;
   
   PROCEDURE pAplicaAliquota(lFaixa IN PKGPAG_TIPO.tFaixaAliquota) IS
      
      i INTEGER;
      
      vCdRubricaGerada INTEGER;
      
      vvlBase NUMBER(15, 4);
      
   BEGIN
      
      FOR c IN cBaseIprev(PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP
         
         i := 0;
         
         IF c.vlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN
            
            vvlBase := vvlTetoGovernador;
            
         ELSE
            
            vvlBase := c.vlBase;
            
         END IF;
         
         WHILE i < (lFaixa.COUNT)
            
          LOOP
            
            i := i + 1;
            
            IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN
               
               PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                  pbAtualiza => CASE
                                                   WHEN pkgpag_var.vgNuDiasApo > 0 THEN
                                                    TRUE
                                                   ELSE
                                                    FALSE
                                                END);
               
               vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;
               
               vvlContribuicao := vvlContribuicao -
                                  nvl(lFaixa(i).VlParcelaDeducao, 0) -
                                  nvl(c.vlDeduzido, 0);
               
               vCdRubricaGerada := FRubricaGerada(c.CdTipoRegimeProprioPrev,
                                                  nvl(c.vlDeduzido, 0),
                                                  vvlContribuicao);
               
               InsereRubricaIPESC(c.CdVinculo,
                                  vCdRubricaGerada,
                                  pTributacao.pFolha.CdFolhaPagamento,
                                  vvlContribuicao,
                                  lFaixa(i).VlAliquota);
               
               PRegeraBasesIPREV(c.cdtiporegimeproprioprev);
               
               i := lFaixa.COUNT + 1;
               
            END IF;
            
         END LOOP;
         
      END LOOP;
      
   END;
   
BEGIN
   
   PDebug ('PCalculaIPREV');
 
   IF NOT pTpTributacao IN (CTRIB_TIPO_NORMAL,CTRIB_TIPO_DECTER) THEN
      RETURN;
   END IF;
     
   IF PKGPAG_TIPO.cnTipoFolhaPagHonor13.EXISTS (pTributacao.pFolha.CdTipoFolha)
      OR PKGPAG_TIPO.cnTipoFolhaPagHonor.EXISTS (pTributacao.pFolha.CdTipoFolhaPagamento) THEN
      RETURN;
   END IF;
   

   IF pTpTributacao IN (CTRIB_TIPO_NORMAL, CTRIB_TIPO_RRA) THEN -- Tributacao normal e RRA
  
      pTributacao.calc.iprev.CdRubDescIprev2008    := pTributacao.iprev.CdRubAgrupDescIprev2008;
      pTributacao.calc.iprev.CdRubDescIprev        := pTributacao.iprev.CdRubAgrupDescIprev;
      pTributacao.calc.iprev.CdRubBaseIprev        := pTributacao.iprev.CdRubBaseIprev;
      
      pTributacao.calc.iprev.CdRubDifDesc          := pTributacao.iprev.CdRubAgrupDifDesc;
      pTributacao.calc.iprev.CdRubDifDesc2008      := pTributacao.iprev.CdRubAgrupDifDesc2008;
      pTributacao.calc.iprev.CdRubDevDesc          := pTributacao.iprev.CdRubAgrupDevDesc;
      pTributacao.calc.iprev.CdRubDevDesc2008      := pTributacao.iprev.CdRubAgrupDevDesc2008;

      pTributacao.calc.iprev.CdRubDescSCFuturo13   := NULL;
      pTributacao.calc.iprev.CdRubDifSCFuturo13    := NULL;
      pTributacao.calc.iprev.CdRubDevSCFuturo13    := NULL;     
    
   ELSE -- 13o salario

      pTributacao.calc.iprev.CdRubDescIprev2008    := pTributacao.iprev.CdRubAgrupDescIprev200813;
      pTributacao.calc.iprev.CdRubDescIprev        := pTributacao.iprev.CdRubAgrupDescIprev13;
      pTributacao.calc.iprev.CdRubBaseIprev        := pTributacao.iprev.CdRubBaseIprev13;

      pTributacao.calc.iprev.CdRubDifDesc          := NULL;
      pTributacao.calc.iprev.CdRubDifDesc2008      := NULL;
      pTributacao.calc.iprev.CdRubDevDesc          := NULL;
      pTributacao.calc.iprev.CdRubDevDesc2008      := NULL;
            
      pTributacao.calc.iprev.CdRubDescSCFuturo13   := pTributacao.iprev.CdRubAgrupDescSCFuturo13;
      pTributacao.calc.iprev.CdRubDifSCFuturo13    := pTributacao.iprev.CdRubAgrupDifSCFuturo13;
      pTributacao.calc.iprev.CdRubDevSCFuturo13    := pTributacao.iprev.CdRubAgrupDevSCFuturo13;
     
   END IF;   
     
   ------------------------------------------------------------------------------------------------------
   -- Calcula o IPrev
   ------------------------------------------------------------------------------------------------------
   
   PKGPAG_GERAL.PLogProcIni('TRI0202','Processa Trib IPREV');
   
   IF FCalculaIPESC OR
      (pkgpag_var.vgPensaoNaoPrev.count > 0 AND pkgpag_var.vgPensaoNaoPrev(1).CdTipoPensaoNaoPrev = 83) THEN
      
      -- Exclui bases de INSS
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSS,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubVlINSSPatronalBruto,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSS13,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseFGTS,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseFGTS13,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubVlFGTS,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubVlFGTS13,
                                  pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pTributacao.CdVinculo,
                                        pCdRubrica        => nvl(PKGPAG_VAR.vgCdRubBaseCPSM,
                                                                 pTributacao.rub.CdRubBaseCPSM),
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');
      
      PKGPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pTributacao.CdVinculo,
                                        pCdRubrica        => nvl(PKGPAG_VAR.vgCdRubBaseCPSM13,
                                                                 pTributacao.rub.CdRubBaseCPSM13),
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');
      
      IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_VAR.vgCdRubDescTetoGovernador) THEN
         
         vvlTetoGovernador := FRetornaValorRubrica(pTributacao => pTributacao,
                                                   pCdRubrica  => PKGPAG_VAR.vgCdRubricaTetoGov);
         
         vNuDiasApo := 0;
         
         IF PKGPAG_VAR.vgApo.count > 0 AND PKGPAG_VAR.vgApo(1).DtInicioRelacao > pTributacao.PFolha.DtInicioMes 
            AND PKGPAG_VAR.vgApo(1).DtInicioRelacao < pTributacao.PFolha.DtFimMes THEN
            
            IF PKGPAG_VAR.vgApo(1).DtFimRelacao IS NULL THEN
               
               vNuDiasApo := 30 - to_char(PKGPAG_VAR.vgApo(1).DtInicioRelacao,
                                          'dd') + 1;
               
            ELSE
               
               vNuDiasApo := nvl(PKGPAG_VAR.vgApo(1).DtFimRelacao,
                                 pTributacao.pFolha.DtFimMes) - PKGPAG_VAR.vgApo(1).DtInicioRelacao + 1;
               
            END IF;
            
            IF pkgpag_var.vgNuDiasApo < 30 THEN
               
               vvlTetoGovernador := vvlTetoGovernador / 30 *
                                    (30 - pkgpag_var.vgNuDiasApo);
               
            END IF;
         END IF;
         
      ELSE
         
         vvlTetoGovernador := 0;
         
      END IF;
      ----------------------------------------------------------------------------------------------------------
      
      vvlDescRubIsentaIPREV := 0;
      
      IF pTributacao.iprev.bDescRubIsentaIPREV THEN
         
         vvlDescRubIsentaIPREV := FRetornaValorRubIsentas(pCdVinculo      => pTributacao.CdVinculo,
                                                          pFolha          => pTributacao.pFolha,
                                                          pCdTipoDesconto => 3);
      END IF;
            
      IF PKGPAG_GERAL.FGeraRubrica(pRubrica => pTributacao.iprev.CdRubAgrupDescIprev) AND
          PKGPAG_GERAL.FGeraRubrica(pRubrica => pTributacao.iprev.CdRubAgrupDescIprev2008) AND 
          NOT PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pTributacao.iprev.CdRubAgrupDescIprev, pNuSufixoRubrica => 1) AND 
          NOT PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pTributacao.iprev.CdRubAgrupDescIprev2008, pNuSufixoRubrica => 1) THEN

         IF bIsencaoParcialIPREV THEN
          
           vCdIsencaoParteContr := 1;
          
         ELSE

            BEGIN
               
               SELECT IC.CdIsencaoParteContribuicao
                 INTO vCdIsencaoParteContr
                 FROM (SELECT IC.CdVinculo, IC.CdIsencaoParteContribuicao
                         FROM EtrbIsencaoParteContribuicao IC
                        INNER JOIN Etrbhistisencaopartecontrib HIC
                           ON IC.Cdisencaopartecontribuicao =
                              HIC.Cdisencaopartecontribuicao
                          AND HIC.FlAnulado = PKGPAG_TIPO.cnN
                          AND ((HIC.nuAnoInicioVigencia <
                              pTributacao.pFolha.NuAnoReferencia OR
                              (HIC.nuAnoInicioVigencia =
                              pTributacao.pFolha.NuAnoReferencia AND
                              HIC.nuMesInicioVigencia <=
                              pTributacao.pFolha.NuMesReferencia)) AND
                              (HIC.nuAnoFimVigencia >
                              pTributacao.pFolha.NuAnoReferencia OR
                              (HIC.nuAnoFimVigencia =
                              pTributacao.pFolha.NuAnoReferencia AND
                              HIC.nuMesFimVigencia >
                              pTributacao.pFolha.NuMesReferencia) OR
                              HIC.nuAnoFimVigencia IS NULL))) IC
                WHERE IC.CdVinculo = pTributacao.CdVinculo
                  AND ROWNUM < 2;
               
            EXCEPTION
               
               WHEN NO_DATA_FOUND THEN
                  
                  vCdIsencaoParteContr := NULL;
                  
            END;
         
         END IF;
         
         ----------------------------------------------------------------------------------------------------------
         -- TRIBUTA APOSENTADORIA MES ANTERIOR
         ----------------------------------------------------------------------------------------------------------
         PAplicaAliquotaApoMesAnt;
         ----------------------------------------------------------------------------------------------------------
         
         -- SIG-4924
         -- SIG-4746 DPE - Folha de setembro - comissionados
         IF pkgpag_var.vgVlIntegralIPREV > 0 AND
            pkgpag_var.vgVlIntegralIPREV <>
            FRetornaValorRubrica(pTributacao => pTributacao,
                                 pCdRubrica  => pkgpag_var.vgCdRubBaseIPESC) AND
            pTributacao.pFolha.CdOrgao = 443 AND pkgpag_var.vgCef.Count > 0 THEN
            
            -- Retorna valor da base da relacao de efetivo
            vVlBaseIprevEfetivo := pkgpag_fb.fretornavalorbasecalculo(pTributacao.pFolha,
                                                                      PKGPAG_VAR.vgVinculo.CdVinculo,
                                                                      1,
                                                                      1,
                                                                      pkgpag_var.vgRubrica          (pkgpag_var.vgCdRubBaseIPESC).cdbasecalculo,
                                                                      pkgpag_var.vgCef              (1).cdhistcargoefetivo);
            -- Se contem valor na base, excluir os demais das outras relacoes
            
            IF nvl(vVlBaseIprevEfetivo.vlIntegral, 0) > 0 THEN
               
               BEGIN
                  
                  DELETE epaghistoricorubricarelvinc rv
                   WHERE rv.cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                     AND rv.cdfolhapagamento = pTributacao.pFolha.CdFolhaPagamento
                     AND rv.cdrubricaagrupamento =  pkgpag_var.vgCdRubBaseIPESC
                     AND rv.cdhistcargoefetivo IS NULL;
                  
               EXCEPTION
                  WHEN OTHERS THEN
                     NULL;
               END;
               
               PAtualizaBaseIPESC(pVlBase    => vVlBaseIprevEfetivo.vlIntegral,
                                  pbCCO      => FALSE,
                                  pbAtualiza => TRUE);
            END IF;
            
         END IF;
         
         CASE
            
            WHEN PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 1
                --
                --  Solicitacao de Sustentacao #71742
                --  9142/2016 - FOLHA - - NAO ESTA CALCULANDO IPREV QUANDO VOLTA DE APOSENTADORIA NO MES.
                --
                 OR (PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 2 AND
                 NVL(PKGPAG_VAR.vgCdSitPrevidenciariaAtual, 0) = 1)
                --
                --  Solicitacao de Sustentacao 15720/2021
                --  base 09-0920 – Base IPREV 13
                --
                 OR (PKGPAG_GERAL.FSituacaoPrevVigente(pCdVinculo   => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                       pDtInicioMes => TRUNC((PKGPAG_VAR.vgFolha.dtcalculoant),
                                                                             'MM'),
                                                       pDtFimMes    => last_day(PKGPAG_VAR.vgFolha.dtcalculoant)) IN (1) AND
                 PKGPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
                 PKGPAG_VAR.vgVinculo.DtDesligamento <
                 PKGPAG_VAR.vgFolha.DtInicioMes AND
                 NVL(PKGPAG_VAR.vgCdRubricaRecisao13, 0) > 0) THEN
               
               CASE
                  
                  WHEN PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica IS NOT NULL THEN
                     
                     FOR c IN cBaseAliqUnica(PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP
                        
                        IF c.vlBase > vvlTetoGovernador AND
                           vvlTetoGovernador > 0 THEN
                           
                           vvlBase := vvlTetoGovernador;
                           
                        ELSE
                           
                           vvlBase := c.vlBase;
                           
                        END IF;
                        
                        PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                           pbAtualiza => CASE
                                                            WHEN pkgpag_var.vgNuDiasApo > 0 THEN
                                                             TRUE
                                                            ELSE
                                                             FALSE
                                                         END);
                        
                        --
                        -- Solicitacao de Sustentacao #68791
                        -- 8554/2016 - FOLHA - - CALCULO DO IPREV (PREVIDENCIA COMPLEMENTAR)
                        --
                        IF NVL(PKGPAG_GERAL.FRetornaRegimeProprioPrev(PKGPAG_VAR.vgVinculo.CdVinculo),
                               0) IN (3, 4) THEN
                           
                           vAliquotaINSS := PKGPAG_GERAL.FRetornaAliquotaINSS(pTributacao.pFolha.NuAnoReferencia,
                                                                              pTributacao.pFolha.NuMesReferencia);
                           
                           IF vVlBase > vAliquotaINSS.vlTeto THEN
                              vVlBase := vAliquotaINSS.vlTeto;
                              IF NVL(vvlDescRubIsentaIPREV, 0) = 0 THEN
                                 vvlDescRubIsentaIPREV := 0.01;
                              END IF;
                              --
                              -- Ajustar a base pelo Teto do INSS
                              --
                              PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                                 pbAtualiza => CASE
                                                                  WHEN pkgpag_var.vgNuDiasApo > 0 THEN
                                                                   TRUE
                                                                  ELSE
                                                                   FALSE
                                                               END);
                              
                           END IF;
                           
                        END IF;
                        
                        vvlContribuicao := vvlBase *
                                           PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100;
                        
                        vCdRubAgrupDescIPESC := FRetornaRubricaDescIPESC(c.CdTipoRegimeProprioPrev,
                                                                         pTributacao.calc.iprev.CdRubDescIPrev,
                                                                         pTributacao.calc.iprev.CdRubDescIPrev2008,
                                                                         pTributacao.calc.iprev.CdRubDescSCFuturo13);
                        
                        InsereRubricaIPESC(pTributacao.CdVinculo,
                                           vCdRubAgrupDescIPESC,
                                           pTributacao.pFolha.CdFolhaPagamento,
                                           vvlContribuicao,
                                           PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica);
                        
                        PAjustaIPREV(pTributacao      => pTributacao,
                                     pCdRubricaGerada => vCdRubAgrupDescIPESC);
                        
                        PReGeraBasesIPREV(c.CdTipoRegimeProprioPrev);
                        
                     END LOOP;
                     --
                     -- 8623/2016 - TRIBUTACAO PREVIDENCIARIA SOBRE CARGO COMISSIONADO E FUNCAO GRATIFICADA (IPREV)
                     --
                     IF pkgpag_var.bPossuiIprevCCO THEN
                        
                        IF pTributacao.pFolha.CdTipoFolha <> pkgpag_tipo.cnTpFolha13 THEN
                           
                           IF NVL(pkgpag_geral.fretornaindicerubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                     PKGPAG_VAR.VGVINCULO.cdvinculo,
                                                                     pTributacao.rub.CdRubBaseOPCAOART27),
                                  0) = 0 THEN
                              
                              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                                    pCdVinculo            => pTributacao.CdVinculo,
                                                                    pCdExpressaoFormCalc  => NULL,
                                                                    pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseOPCAOART27,
                                                                    pNuSufixoRubrica      => 1,
                                                                    pVlPagamento          => 0,
                                                                    pVlIndice             => NULL,
                                                                    pCdTipoOrigemRubrica  => 1);
                           END IF;
                           
                           IF NVL(pkgpag_geral.fretornaindicerubrica(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                     PKGPAG_VAR.VGVINCULO.cdvinculo,
                                                                     pTributacao.rub.CdRubBaseESTENDSCPREV),
                                  0) = 0 THEN
                              
                              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                                    pCdVinculo            => pTributacao.CdVinculo,
                                                                    pCdExpressaoFormCalc  => NULL,
                                                                    pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseESTENDSCPREV,
                                                                    pNuSufixoRubrica      => 1,
                                                                    pVlPagamento          => 0,
                                                                    pVlIndice             => NULL,
                                                                    pCdTipoOrigemRubrica  => 1);
                           END IF;
                           
                           PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                                            pCdVinculo       => pTributacao.CdVinculo,
                                                            pCdRubrica       => pTributacao.rub.CdRubBaseOPCAOART27,
                                                            pTpProcessamento => 2,
                                                            pTpLocal         => 2);
                           
                           PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                                            pCdVinculo       => pTributacao.CdVinculo,
                                                            pCdRubrica       => pTributacao.rub.CdRubBaseESTENDSCPREV,
                                                            pTpProcessamento => 2,
                                                            pTpLocal         => 2);
                        END IF;
                        
                        --
                        -- Excecao PGTC, manter na mesma rubrica
                        --
                        IF pTributacao.pFolha.CdAgrupamento = 133 THEN
                           
                           -- PGTC - Problema com contribuicao previdenciaria de servidor
                           -- Conforme sugestao da AGPE substituir o valor da Base Iprev pelo valor da 09-0962 para os comissionados
                           IF pkgpag_var.vgCco.Count > 0 THEN
                              
                              vvlBase := FRetornaValorRubrica(pTributacao => pTributacao,
                                                              pCdRubrica  => pTributacao.rub.CdRubBaseESTENDSCPREV);
                              
                           ELSE
                              
                              vvlBase := vVlBase + FRetornaValorRubrica(pTributacao => pTributacao,
                                                                        pCdRubrica  => pTributacao.rub.CdRubBaseOPCAOART27);
                              
                           END IF;
                           -- SIG-2725
                           --
                           -- Solicitacao de Sustentacao #76721
                           -- PGJTC - Problema com limitacao da contribuicao previdenciaria de servidora
                           --
                           IF vvlBase > vvlTetoGovernador AND
                              vvlTetoGovernador > 0 THEN
                              
                              vvlBase := vvlTetoGovernador;
                              
                           END IF;
                           
                           PAtualizaBaseIPESC(pvlBase => vvlBase,
                                              pbCCO   => TRUE);
                           
                           vvlContribuicao := vvlBase *
                                              PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100;
                           
                           PAtualizaValorIPESC(vVlContribuicao,
                                               FRetornaRubricaDescIPESC(1,
                                                                        pTributacao.calc.iprev.CdRubDescIPrev,
                                                                        pTributacao.calc.iprev.CdRubDescIPrev2008,
                                                                        pTributacao.calc.iprev.CdRubDescSCFuturo13));
                           
                           --
                           -- Ajuste para quem tem Abono Permanencia
                           --
                           IF pkgpag_geral.fpossuilancfinanceiro(pcdvinculo => pTributacao.CdVinculo,
                                                                 pfolha     => pTributacao.pFolha,
                                                                 pcdrubrica => pTributacao.rub.CdRubProvABONOPERM)
                              
                            THEN
                              
                              PAtualizaValorIPESC(vVlContribuicao,
                                                  pTributacao.rub.CdRubProvABONOPERM);
                              
                           END IF;
                           
                        ELSE
                           
                           IF pTributacao.pFolha.CdTipoFolha =
                              pkgpag_tipo.cnTpFolha13 AND
                              FRetornaValorRubrica(pTributacao => pTributacao,
                                                   pCdRubrica  => pTributacao.rub.CdRubDescIPREVART2713) = 0 THEN
                              InsereRubricaIPESC(pTributacao.CdVinculo,
                                                 pTributacao.rub.CdRubDescIPREVART2713,
                                                 pTributacao.pFolha.CdFolhaPagamento,
                                                 FRetornaValorRubrica(pTributacao => pTributacao,
                                                                      pCdRubrica  => pTributacao.rub.CdRubBaseOPCAOART27) *
                                                 PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100,
                                                 PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica);
                              
                           ELSIF pTributacao.pFolha.CdTipoFolha <> pkgpag_tipo.cnTpFolha13 THEN
                              InsereRubricaIPESC(pTributacao.CdVinculo,
                                                 pTributacao.rub.CdRubDescIPREVPART27,
                                                 pTributacao.pFolha.CdFolhaPagamento,
                                                 FRetornaValorRubrica(pTributacao => pTributacao,
                                                                      pCdRubrica  => pTributacao.rub.CdRubBaseOPCAOART27) *
                                                 PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100,
                                                 PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica);
                           ELSE
                              NULL;
                           END IF;
                        END IF;
                     END IF;
                     
                  WHEN PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica IS NULL THEN
                     
                     pAplicaAliquotaIsolada(PKGPAG_VAR.vAliqIPESCAtivo.lFaixa);
                     
               END CASE;
               
            WHEN PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria IN (2, 9) AND
                 vCdIsencaoParteContr IS NULL
                --
                --  Solicitacao de Sustentacao 15720/2021
                --  base 09-0920 – Base IPREV 13
                --
                 OR (PKGPAG_GERAL.FSituacaoPrevVigente(pCdVinculo   => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                       pDtInicioMes => TRUNC((PKGPAG_VAR.vgFolha.dtcalculoant),
                                                                             'MM'),
                                                       pDtFimMes    => last_day(PKGPAG_VAR.vgFolha.dtcalculoant)) IN
                 (2, 9) AND
                 PKGPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
                 PKGPAG_VAR.vgVinculo.DtDesligamento <
                 PKGPAG_VAR.vgFolha.DtInicioMes AND
                 NVL(PKGPAG_VAR.vgCdRubricaRecisao13, 0) > 0) THEN
               
               CASE
                  
                  WHEN PKGPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica IS NOT NULL THEN
                     
                     FOR c IN cBaseAliqUnica(PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP
                        
                        IF c.vlBase > vvlTetoGovernador AND
                           vvlTetoGovernador > 0 THEN
                           
                           vvlBase := vvlTetoGovernador;
                           
                        ELSE
                           
                           vvlBase := c.vlBase;
                           
                        END IF;
                        
                        PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                           pbAtualiza => CASE
                                                            WHEN pkgpag_var.vgNuDiasApo > 0 THEN
                                                             TRUE
                                                            ELSE
                                                             FALSE
                                                         END);
                        
                        vvlContribuicao := vvlBase *
                                           PKGPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica / 100;
                        
                        IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                           vvlContribuicao := vvlContribuicao *
                                              PKGPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                                                            pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia) /
                                              pkgpag_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pTributacao.CdVinculo,
                                                                                               pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia);

                        END IF;
                        
                        InsereRubricaIPESC(pTributacao.CdVinculo,
                                           FRetornaRubricaDescIPESC(c.CdTipoRegimeProprioPrev,
                                                                    pTributacao.calc.iprev.CdRubDescIPrev,
                                                                    pTributacao.calc.iprev.CdRubDescIPrev2008,
                                                                    pTributacao.calc.iprev.CdRubDescSCFuturo13),
                                           pTributacao.pFolha.CdFolhaPagamento,
                                           vvlContribuicao,
                                           PKGPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica);
                        
                        PReGeraBasesIPREV(c.CdTipoRegimeProprioPrev);
                        
                     END LOOP;
                     
                  WHEN PKGPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica IS NULL THEN
                     
                     IF PKGPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
                        PKGPAG_VAR.vgVinculo.DtDesligamento <
                        PKGPAG_VAR.vgFolha.DtInicioMes AND
                        NVL(PKGPAG_VAR.vgCdRubricaRecisao13, 0) > 0 THEN
                        
                        vAliqIPESCRescisao := FRetornaAliquotaIPESCRescisao(PKGPAG_TIPO.cnTpTrbInativo,
                                                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                            PKGPAG_VAR.vgFolha.NuMesReferencia);
                        
                        IF PKGPAG_VAR.VGFOLHA.CDORGAO = 33 AND -- sig 7062
                           pkgpag_geral.fpossuiregistroobito(pkgpag_var.vCdPessoa,
                                                             pkgpag_var.vgFolha.cdAgrupamento,
                                                             'S') THEN
                           -- pAplicaAliquotaIsolada(vAliqIPESCRescisao.lFaixa);
                           pAplicaAliquotaIsolada(PKGPAG_VAR.vAliqIPESCInativo.lFaixa);
                        ELSE
                           pAplicaAliquotaIsolada(vAliqIPESCRescisao.lFaixa);
                        END IF;
                     ELSE
                        
                        pAplicaAliquotaIsolada(PKGPAG_VAR.vAliqIPESCInativo.lFaixa);
                     END IF;
                     --fim modificacao sig-7062
                     IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                        vvlContribuicao := vvlContribuicao *
                                           PKGPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                                                         pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia) /
                                           pkgpag_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pTributacao.CdVinculo,
                                                                                            pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia);
                     END IF;
                     
               END CASE;
               
         -- Situação Não Previdenciária
            WHEN PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria IN (4)
                --
                --#80348
                -- TipoPensaoNaoPrev: Decisão Judicial com remuneração
                -- Ocorre o abatimento do teto do RGPS
                --
                 AND
                 (pkgpag_var.vgPensaoNaoPrev.count > 0 AND pkgpag_var.vgPensaoNaoPrev(1).CdTipoPensaoNaoPrev = 83) THEN
               
               pAplicaAliquotaIsenPNP(PKGPAG_VAR.vAliqIPESCInativo.lFaixa);
               
            WHEN PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria IN (2, 9) AND
                 vCdIsencaoParteContr IS NOT NULL THEN
               
               CASE
                  
                  WHEN PKGPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica IS NOT NULL THEN
                     
                     FOR c IN cBaseAliqUnicaIsencao(PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP
                        
                        IF c.vlBase > vvlTetoGovernador AND
                           vvlTetoGovernador > 0 THEN
                           
                           vvlBase := vvlTetoGovernador;
                           
                        ELSE
                           
                           vvlBase := c.vlBase;
                           
                        END IF;
                        
                        PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                           pbAtualiza => CASE
                                                            WHEN pkgpag_var.vgNuDiasApo > 0 THEN
                                                             TRUE
                                                            ELSE
                                                             FALSE
                                                         END);
                        
                        vvlContribuicao := vvlBase *
                                           PKGPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica / 100;
                        
                        IF PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                           vvlContribuicao := vvlContribuicao *
                                              PKGPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                                                            pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia) /
                                              pkgpag_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pTributacao.CdVinculo,
                                                                                               pAnoMesReferencia     => pTributacao.pFolha.NuAnoMesReferencia);
                           

                        END IF;
                        
                        InsereRubricaIPESC(pTributacao.CdVinculo,
                                           FRetornaRubricaDescIPESC(c.CdTipoRegimeProprioPrev,
                                                                    pTributacao.calc.iprev.CdRubDescIPrev,
                                                                    pTributacao.calc.iprev.CdRubDescIPrev2008,
                                                                    pTributacao.calc.iprev.CdRubDescSCFuturo13),
                                           pTributacao.pFolha.CdFolhaPagamento,
                                           vvlContribuicao,
                                           PKGPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica);
                        
                        PReGeraBasesIPREV(c.CdTipoRegimeProprioPrev);
                        
                     END LOOP;
                     
                  WHEN PKGPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica IS NULL THEN
                     
                     pAplicaAliquotaIsoladaIsen(PKGPAG_VAR.vAliqIPESCParcial.lFaixa);
                     
               END CASE;
               
            ELSE
               
               vvlContribuicao := 0;
               
         END CASE;
         
         IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = pkgpag_tipo.cnRegPrevCPSM AND
            pTributacao.iprev.FlCpsmParaIprev = 0 THEN
            
            PAtualizaValorCPSM(pTributacao.pfolha,
                               pTributacao.CdVinculo,
                               vVlContribuicao,
                               vCdRubricaIPREV,
                               pTributacao.rub.CdRubDescCPSM);
         END IF;
         
      END IF;
      
   END IF;
 
--- vem de outra rotina

      ---------------------------------------------------------------------------------
      -- Gera Abono de permanencia na folha de 13 salario com o mesmo valor do IPREV
      -- caso a rubrica exista na folha normal/definitiva
      ---------------------------------------------------------------------------------
      
      PGeraAbonoPermanencia13(pTributacao         => pTributacao,
                              pCdRubricaAbonoPerm => PKGPAG_VAR.vgCdRubricaAbonoPerm,
                              pVlIPESC            => vVlDescIprev);
      
      PExcluiAbonoPermanencia(pTributacao => pTributacao,
                              pVlIPESC    => vVlDescIprev);  
   
   PKGPAG_GERAL.PLogProcFim('TRI0202');
END;

PROCEDURE P_____________IRRF IS
BEGIN
   NULL;
END;

FUNCTION FValoresSomados (pDeExpressao IN VARCHAR2) RETURN NUMBER IS

   vI           INTEGER; 
   vRetorno     NUMBER (13,2);
   vDeFormula   VARCHAR2(500);   

BEGIN
   
   vDeFormula := '';
   vI         := 0;
               
   FOR z IN 1 .. length(pDeExpressao) LOOP

     IF substr(pDeExpressao, z, 1) = '-' THEN
        vI := 1;
     ELSIF substr(pDeExpressao, z, 1) = '+' THEN
        vI := 0;
     END IF;
               
     IF vI = 0 THEN
        vDeFormula := vDeFormula || substr(pDeExpressao, z,1);
      END IF;
      
   END LOOP;
  
   vRetorno := nvl(pkgmath.fcalcular(vDeFormula), 0);
   
   RETURN vRetorno;
   
END;

PROCEDURE PReprocessarFormulaRubrica(pFolha                IN pkgpag_tipo.rfolha,
                                     pCdVinculo            IN INTEGER,
                                     pCdRubricaAgrupamento IN INTEGER,
                                     pTpTributacao         IN INTEGER,
                                     pIndProcRetro         IN INTEGER) IS
   
   vCdProcessoPagRetroativo INTEGER := NULL;
   
BEGIN
   
   IF pIndProcRetro IS NOT NULL THEN
      vCdProcessoPagRetroativo := PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo;
   END IF;
   
   PAlterarLancamentoVinculo (pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                              pCdVinculo               => pCdVinculo,
                              pCdRubricaAgrupamento    => pCdRubricaAgrupamento,
                              pVlPagamento             => 0,
                              pCdTipoOrigemRubrica     => 1,
                              pCdProcessoPagRetroativo => vCdProcessoPagRetroativo);  
   
   PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                    pCdVinculo       => pCdVinculo,
                                    pCdRubrica       => pCdRubricaAgrupamento,
                                    pTpProcessamento => 2,
                                    pTpLocal         => 2,
                                    pTpTributacao    => pTpTributacao,
                                    pindprocretro    => pIndProcRetro);
   
END;

PROCEDURE PAtualizarDeducoesLegaisIRRF(pTributacao   IN rTributacao,
                                       pTpTributacao IN INTEGER,
                                       pIndProcRetro IN INTEGER) IS
   
BEGIN

   IF NOT pTributacao.irrf.FlIsentoIRRF THEN
           
      IF PKGPAG_VAR.vgCdRubBaseDeducoesIRRF IS NOT NULL THEN
         PReprocessarFormulaRubrica(pFolha                => pTributacao.pFolha,
                                    pCdVinculo            => pTributacao.CdVinculo,
                                    pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                    pTpTributacao         => pTpTributacao,
                                    pIndProcRetro         => pIndProcRetro);
            
         IF pTributacao.pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolha13 THEN
            PKGPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pTributacao.pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pTributacao.CdVinculo,
                                        pCdRubrica        => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                        pFlExcluiAmbos    => 'S');
         END IF;
      END IF;
         
   END IF;
   
   IF PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13 IS NOT NULL THEN
      PKGPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                  pFlExcluiAmbos    => 'S');
      
      IF pTributacao.irrf.CdRubBaseIRRF = pkgpag_var.vgCdRubBaseIRRF13 AND
         FRetornaValorRubrica(pTributacao => pTributacao,
                              pCdRubrica  => pkgpag_var.vgCdRubBaseIRRF13) > 0 THEN
         
         PReprocessarFormulaRubrica(pFolha                => pTributacao.pFolha,
                                    pCdVinculo            => pTributacao.CdVinculo,
                                    pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                    pTpTributacao         => pTpTributacao,
                                    pIndProcRetro         => pIndProcRetro);
         
      END IF;
   END IF;
END;

/*-----------------------------------------------------------------------------------------/
   Objetivo: Retorna o numero de dependentes que nao possuem
             registro de obito e finaliza as dependencias de
             imposto de Renda
      
/*-----------------------------------------------------------------------------------------*/
FUNCTION FDependenteOutroVinculo(pCdPessoa    IN INTEGER,
                                 pCdVinculo   IN INTEGER,
                                 pDtInicioMes IN DATE,
                                 pDtFimMes    IN DATE) RETURN INTEGER IS
   
   vCont         INTEGER DEFAULT 0;
   vCdDependente INTEGER DEFAULT 0;
   
BEGIN
   
   FOR vDependente IN (SELECT DI.CdDependenteVinculoIRRF,
                              D.CdDependente,
                              D.NmDependente,
                              DtNascimento,
                              DI.DtFimDependencia,
                              DI.FlEstudante,
                              D.FlInvalidez,
                              GP.FlFinalizaDependenciaIRRF,
                              GP.FlPensaoVitalicia
                         FROM ECadDependenteVinculo DV
                        INNER JOIN ECadDependenteVinculoIRRF DI
                           ON DV.CdDependenteVinculo =
                              DI.CdDependenteVinculo
                        INNER JOIN ECadPessoaDependente PD
                           ON PD.CdDependente = DV.CdDependente
                        INNER JOIN ECadDependente D
                           ON D.CdDependente = PD.CdDependente
                        INNER JOIN ECadGrauParentescoprevfin GP
                           ON GP.CdGrauParentescoPrevFin =
                              PD.CdGrauParentescoPrevFin
                          
                        INNER JOIN ECadVinculo V
                           ON V.CdVinculo = dv.CdVinculo
                          
                        WHERE PD.CdResponsavel = pCdPessoa
                          AND DI.DtInicioDependencia <= pDtFimMes
                          AND (DI.DtFimdependencia >= pDtInicioMes OR
                              DI.DtFimDependencia IS NULL)
                          AND V.Cdvinculo <> pCdVinculo
                          AND V.CdPessoa = PD.CdResponsavel
                          AND NOT EXISTS
                        (SELECT 1
                                 FROM EAfaRegistroObito RO
                                WHERE RO.CdDependente = DV.CdDependente
                                  AND RO.FlAnulado = PKGPAG_TIPO.cnN)
                          AND EXISTS
                        (SELECT 1
                                 FROM ecadvinculo v
                                INNER JOIN ecadorgao o
                                   ON v.cdorgao = o.cdorgao
                                WHERE v.cdvinculo = DV.CdVinculo
                                  AND (v.dtDesligamento >= pDtInicioMes OR
                                      v.dtdesligamento IS NULL)
                                  AND o.cdagrupamento =
                                      PKGPAG_VAR.vgFolha.CdAgrupamento)
                          
                        ORDER BY D.CdDependente
                          
                       )
      
    LOOP
      
      IF vCdDependente <> vDependente.Cddependente THEN
         vCont         := vCont + 1;
         vCdDependente := vDependente.Cddependente;
      END IF;
      
      IF vDependente.FlInvalidez = 'N' THEN
         
         IF vDependente.FlFinalizaDependenciaIRRF = 'S' AND
            vDependente.FlPensaoVitalicia = 'N' AND
            ((MONTHS_BETWEEN(pDtFimMes, vDependente.DtNascimento) >
            21 * 12 AND -- 21 anos NAO estudante
            vDependente.FlEstudante = 'N') OR
            ((MONTHS_BETWEEN(pDtFimMes, vDependente.DtNascimento) >
            25 * 12 AND -- 25 anos estudante
            vDependente.FlEstudante = 'S'))) AND
            vDependente.DtFimDependencia IS NULL THEN
            
            UPDATE ECadDependenteVinculoIRRF DV
               SET DV.DtFimDependencia = pDtFimMes,
                   DV.DtUltAlteracao   = SYSTIMESTAMP
             WHERE DV.CdDependenteVinculoIRRF =
                   vDependente.CdDependenteVinculoIRRF;
            
            PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                    pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                    pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                    pDeLog                   => 'Finalização de dependência de IRRF : ' ||
                                                                vDependente.NmDependente,
                                    pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                    pCdTipoOcorrencia        => 2, -- Ocorrencia
                                    pCdMotivoOcorrencia      => 7); -- Finalizacao de dependencia de IRRF
            
         END IF;
         
      END IF;
      
   END LOOP;
   
   RETURN vCont;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN 0;
      
END;



-----------------------------------------------------------------------
-- Soma as rubricas de retroativos de 13 salario e Ferias pois estes
-- nao estao presentes na base de IR normal

-- Este valor e somado a base de IRRF quando e tributacao de RRA
-----------------------------------------------------------------------

FUNCTION FRetornaOutrosValoresRRA(pFolha                   IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo               IN INTEGER,
                                  pCdProcessoPagRetroativo IN INTEGER)
   RETURN NUMBER IS
   
   vvlRubrica NUMBER(13, 2);
   
BEGIN
   
   vvlRubrica := 0;
   
   IF NOT PKGPAG_RT.vgDecJudRetro.EXISTS(pCdProcessoPagRetroativo) OR
      (PKGPAG_RT.vgDecJudRetro.EXISTS(pCdProcessoPagRetroativo) AND PKGPAG_RT.vgDecJudRetro(pCdProcessoPagRetroativo).FlIsentaIRRF = 'N') THEN
      
      --
      -- Solicitacao de Sustentacao #78208
      -- 11146/2017 - FOLHA - - INCLUSAO DO 12-1914 E 10-1914 NA BASE DE IRRF DE RRA
      -- 10613/2017 - FOLHA - - BLOQUEIO 13º (02-0984) CONSIDERAR COMO MONTANTE PARA RRA
      --
      SELECT NVL(SUM(HV.VlPagamento * CASE
                        WHEN r.cdtiporubrica = 5 THEN
                         -1
                        ELSE
                         1
                     END),
                 0) AS VlProporcional
        INTO vvlRubrica
        FROM EpagHistoricoRubricaVinculo HV
       INNER JOIN EPagRubricaAgrupamento RA
          ON RA.CdRubricaAgrupamento = HV.CdRubricaAgrupamento
       INNER JOIN EPagRubrica R
          ON R.CdRubrica = RA.CdRubrica
       WHERE HV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HV.CdVinculo = pCdVinculo
         AND HV.Cdprocessopagretroativo = pCdProcessoPagRetroativo
         AND
            -- 13 sal e ferias
             ((R.CdTipoRubrica IN (10, 12) AND
             R.NuRubrica IN (23, 56, 156, 1914, 984))
             -- bloqueio
             OR R.Cdtiporubrica = 5 AND R.Nurubrica IN (1984, 2984));
      
   END IF;
   
   RETURN vvlRubrica;
   
EXCEPTION
   
   WHEN NO_DATA_FOUND THEN
      
      RETURN 0;
      
END;

-----------------------------------------------------------------------
-- Soma as rubricas de Iprev (06-0915 e 06-0926)

-- Este valor e somado a base de IRRF de RRA para calculo do NM
-----------------------------------------------------------------------

FUNCTION FRetornaIprevRRA(pFolha                   IN PKGPAG_TIPO.rFolha,
                          pCdVinculo               IN INTEGER,
                          pCdProcessoPagRetroativo IN INTEGER)
   RETURN NUMBER IS
   
   vvlRubrica NUMBER(13, 2);
   
BEGIN
   
   SELECT NVL(SUM(HV.VlPagamento), 0) AS VlProporcional
     INTO vvlRubrica
     FROM EpagHistoricoRubricaVinculo HV
    INNER JOIN EPagRubricaAgrupamento RA
       ON RA.CdRubricaAgrupamento = HV.CdRubricaAgrupamento
    INNER JOIN EPagRubrica R
       ON R.CdRubrica = RA.CdRubrica
    WHERE HV.CdFolhaPagamento = pFolha.CdFolhaPagamento
      AND HV.CdVinculo = pCdVinculo
      AND HV.CdProcessoPagRetroativo = pCdProcessoPagRetroativo
      AND (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915, 926));
   
   RETURN vvlRubrica;
   
EXCEPTION
   
   WHEN NO_DATA_FOUND THEN
      
      RETURN 0;
      
END;


PROCEDURE PInsereDepositoEmJuizo(pTributacao IN rTributacao,
                                 pVlBase     IN INTEGER,
                                 pVlLiquido  IN INTEGER) IS
   
   vVlBase    NUMBER(13, 2);
   vVlLiquido NUMBER(13, 2);
   vVlIndice  NUMBER(13, 2);
   i          NUMERIC;
   vSufixo    NUMERIC := 1;
   vCdRubrica INTEGER;
   vDeRubrica VARCHAR(25);
   vNmRubrica VARCHAR(150);
   
BEGIN
   
   vCdRubrica := pTributacao.rub.CdRubDescIRRFJUD;
   
   vDeRubrica := 'Dep. Juízo Ref. Rubrica ';
   
   FOR Juizo IN (SELECT HRV.CDRUBRICAAGRUPAMENTO,
                        HRV.Nusufixorubrica,
                        HRV.Vlpagamento,
                        0,
                        HRV.Vlindicerubrica,
                        HTR.Cdhistisencaorubrica
                   FROM EPagHistoricoRubricaVinculo HRV
                  INNER JOIN ETrbIsencaoRubrica TR
                     ON TR.CdVinculo = HRV.CdVinculo
                    AND TR.CdRubricaAgrupamento =
                        HRV.CdRubricaAgrupamento
                  INNER JOIN ETrbHistIsencaoRubrica HTR
                     ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                  WHERE TR.CdVinculo = pTributacao.CdVinculo
                    AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                    AND TR.FlRubricaIsentaIRRF = 'S'
                    AND ((HTR.NuAnoInicioVigencia <
                        pTributacao.pFolha.NuAnoReferencia OR
                        (HTR.NuAnoInicioVigencia =
                        pTributacao.pFolha.NuAnoReferencia AND
                        HTR.NuMesInicioVigencia <=
                        pTributacao.pFolha.NuMesReferencia)) AND
                        (HTR.NuAnoFimVigencia > pTributacao.pFolha.NuAnoReferencia OR
                        (HTR.NuAnoFimVigencia = pTributacao.pFolha.NuAnoReferencia AND
                        HTR.NuMesFimVigencia >= pTributacao.pFolha.NuMesReferencia) OR
                        HTR.NuMesFimVigencia IS NULL) AND
                        TR.FLDEPOSITOEMJUIZO = 'S'))
      
    LOOP
      
      vVlLiquido := 0;
      vVlBase    := pVlBase + Juizo.VlPagamento;
      i          := 0;
      
      WHILE i < (PKGPAG_VAR.vAliquotaIRRF.lFaixa.COUNT) LOOP
         
         i := i + 1;
         
         IF vVlBase BETWEEN PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).vlInicial AND PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).vlFinal THEN
            
            vVlLiquido := vvlBase * PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota / 100;
            
            vvlLiquido := vvlLiquido - NVL(PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).VlParcelaDeducao,
                                           0);
            
            vvlIndice := PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota;
            
            i := PKGPAG_VAR.vAliquotaIRRF.lFaixa.COUNT + 1;
            
         END IF;
         
      END LOOP;
      
      SELECT lpad(vp.cdtiporubrica, 2, 0) || '-' ||
             lpad(vp.nurubrica, 4, 0) || ' ' ||
             substr(vp.derubricaagrupamento, 1, 100)
        INTO vNmRubrica
        FROM vPagRubrica vp
       WHERE vp.cdrubricaagrupamento = Juizo.Cdrubricaagrupamento;
      
      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.Nusufixorubrica = vSufixo
         AND HRV.CdRubricaAgrupamento = vCdRubrica
         AND HRV.Cdhistsentencajudicial = Juizo.Cdhistisencaorubrica;
      
      PKGPAG_GERAL.pinserelancamentovinculo(pcdfolhapagamento       => pTributacao.pFolha.CdFolhaPagamento,
                                            pcdvinculo              => pTributacao.CdVinculo,
                                            pcdexpressaoformcalc    => NULL,
                                            pcdrubricaagrupamento   => vCdRubrica,
                                            pnusufixorubrica        => vSufixo,
                                            pvlpagamento            => vvlLiquido -
                                                                       pVlLiquido,
                                            pvlindice               => vVlIndice,
                                            pcdtipoorigemrubrica    => 3,
                                            pcdtipoindice           => PKGPAG_VAR.vgRubrica(vCdRubrica).CdTipoIndice,
                                            pcdhistsentencajudicial => Juizo.Cdhistisencaorubrica,
                                            pDeexpressao            => vDeRubrica ||
                                                                       vNmRubrica);
      
      vSufixo := vSufixo + 1;
      
   END LOOP;
   
END;

------------------------------------------------------------------------------
--     Funcao: FValorIsentoRetIRRF
--   Objetivo: Retorna o valor das rubricas do tipo 2 que devem ser abatidos do
--             valor da base de imposto de renda normal
------------------------------------------------------------------------------

FUNCTION FValorIsentoRetIRRF(pFolha         IN PKGPAG_TIPO.rFolha,
                             pCdVinculo     IN INTEGER,
                             pCdRubBaseIRRF IN INTEGER)
   
 RETURN NUMBER IS
   
   vVlResultado NUMBER(13, 2);
   
   vVlRetroativo NUMBER(13, 2);
   
   i INTEGER;
   
   vCdHistBase INTEGER;
BEGIN
   
   vVlResultado := 0;
   
   IF PKGPAG_RT.vgDecJudRetro.COUNT > 0 THEN
      
      i := PKGPAG_RT.vgDecJudRetro.FIRST;
      
      vCdHistBase := PKGPAG_VAR.vgBaseExpr(PKGPAG_VAR.vgRubrica(pCdRubBaseIRRF).CdBaseCalculo).CdHistBaseCalculo;
      
      WHILE i IS NOT NULL LOOP
         
         IF PKGPAG_RT.vgDecJudRetro(i).FlIsentaIRRF = 'S' THEN
            
            SELECT SUM(VlPagamento)
              INTO vVlRetroativo
              FROM EPagHistoricoRubricaVinculo HRV
             INNER JOIN (SELECT EXRA.CdRubricaAgrupamento
                           FROM EPagBaseCalcBlocoExprRubAgrup EXRA
                          INNER JOIN EPagBaseCalculoBlocoExpressao BCE
                             ON BCE.CdBaseCalculoBlocoExpressao =
                                EXRA.CdBaseCalculoBlocoExpressao
                          INNER JOIN EPagBaseCalculoBloco BCB
                             ON BCB.CdBaseCalculoBloco =
                                BCE.CdBaseCalculoBloco
                          WHERE BCB.CdHistBaseCalculo = vCdHistBase) BASE
                ON BASE.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
             INNER JOIN EPagRubricaAgrupamento RA
                ON RA.CdRubricaAgrupamento = BASE.CdRubricaAgrupamento
             INNER JOIN EPagRubrica R
                ON R.CdRubrica = RA.CdRubrica
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdProcessoPagRetroativo = PKGPAG_RT.vgDecJudRetro(i).CdProcessoPagRetroativo
               AND R.CdTipoRubrica = 2;
            
            vVlResultado := NVL(vVlResultado, 0) + NVL(vVlRetroativo, 0);
            
         END IF;
         
         i := PKGPAG_RT.vgDecJudRetro.NEXT(i);
         
      END LOOP;
      
   END IF;
   
   RETURN vVlResultado;
   
END;

------------------------------------------------------------------------------
--     Funcao: FValorIsentoRetIRRFRRA
--   Objetivo: Retorna o valor das rubricas do tipo 10 e 12 que devem ser abatidos do
--             valor da base de imposto de renda de RRA
------------------------------------------------------------------------------
FUNCTION FValorIsentoRetIRRFRRA(pFolha                   IN PKGPAG_TIPO.rFolha,
                                pCdVinculo               IN INTEGER,
                                pCdProcessoPagRetroativo IN INTEGER,
                                pCdRubBaseIRRF           IN INTEGER)
   RETURN NUMBER IS
   
   vVlResultado NUMBER(13, 2);
   
   vVlResultOutros NUMBER(13, 2);
   
   vCdHistBase INTEGER;
   
BEGIN
   
   vVlResultado := 0;
   
   vVlResultOutros := 0;
   
   IF PKGPAG_RT.vgDecJudRetro.EXISTS(pCdProcessoPagRetroativo) THEN
      
      IF PKGPAG_RT.vgDecJudRetro(pCdProcessoPagRetroativo).FlIsentaIRRF = 'S' THEN
         
         vCdHistBase := PKGPAG_VAR.vgBaseExpr(PKGPAG_VAR.vgRubrica(pCdRubBaseIRRF).CdBaseCalculo).CdHistBaseCalculo;
         
         SELECT SUM(VlPagamento)
           INTO vVlResultado
           FROM EPagHistoricoRubricaVinculo HRV
          INNER JOIN (SELECT EXRA.CdRubricaAgrupamento
                        FROM EPagBaseCalcBlocoExprRubAgrup EXRA
                       INNER JOIN EPagBaseCalculoBlocoExpressao BCE
                          ON BCE.CdBaseCalculoBlocoExpressao =
                             EXRA.CdBaseCalculoBlocoExpressao
                       INNER JOIN EPagBaseCalculoBloco BCB
                          ON BCB.CdBaseCalculoBloco =
                             BCE.CdBaseCalculoBloco
                       WHERE BCB.CdHistBaseCalculo = vCdHistBase) BASE
             ON BASE.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
          INNER JOIN EPagRubricaAgrupamento RA
             ON RA.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
          INNER JOIN EPagRubrica R
             ON R.CdRubrica = RA.CdRubrica
          WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
            AND HRV.CdVinculo = pCdVinculo
            AND HRV.CdProcessoPagRetroativo = pCdProcessoPagRetroativo
            AND R.CdTipoRubrica IN (10, 12);
         
         SELECT NVL(SUM(HV.VlPagamento), 0) AS VlProporcional
           INTO vVlResultOutros
           FROM EpagHistoricoRubricaVinculo HV
          INNER JOIN EPagRubricaAgrupamento RA
             ON RA.CdRubricaAgrupamento = HV.CdRubricaAgrupamento
          INNER JOIN EPagRubrica R
             ON R.CdRubrica = RA.CdRubrica
          WHERE HV.CdFolhaPagamento = pFolha.CdFolhaPagamento
            AND HV.CdVinculo = pCdVinculo
            AND HV.Cdprocessopagretroativo = pCdProcessoPagRetroativo
            AND (R.CdTipoRubrica IN (10, 12) AND
                R.NuRubrica IN (23, 56, 156, 1914, 984));
         
         vVlResultado := NVL(vVlResultado, 0) + NVL(vVlResultOutros, 0);
         
      END IF;
      
   END IF;
   
   RETURN vVlResultado;
   
END;


FUNCTION FIsentoIRRFVinculoApo(pCdVinculo IN INTEGER,
                               pFolha     IN PKGPAG_TIPO.rFolha)
   
 RETURN BOOLEAN IS
   
   vCont INTEGER;
   
BEGIN
   
   SELECT 1
     INTO vCont
     FROM ETrbIsencaoIRRF IR
    INNER JOIN ETrbHistIsencaoIRRF HIR
       ON IR.CdIsencaoIRRF = HIR.CdIsencaoIRRF
    INNER JOIN ECadVinculo V2
       ON V2.CdVinculo = IR.CdVinculo
    WHERE V2.CdPessoa = (SELECT V.CdPessoa
                           FROM ECadVinculo V
                          WHERE V.CdVinculo = pCdVinculo)
      AND V2.Cdvinculo <> pCdVinculo
      AND V2.CdSituacaoPrevidenciaria = 2 -- Inativo/Aposentado
      AND (V2.DtDesligamento IS NULL OR
          V2.DtDesligamento >= pFolha.DtInicioMes)
      AND HIR.FlAnulado = PKGPAG_TIPO.cnN
      AND ((HIR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
          (HIR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
          HIR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
          (HIR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
          (HIR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
          HIR.NuMesFimVigencia > pFolha.NuMesReferencia) OR
          HIR.NuAnoFimVigencia IS NULL));
   
   RETURN TRUE;
   
EXCEPTION
   
   WHEN NO_DATA_FOUND THEN
      
      RETURN FALSE;
      
   WHEN TOO_MANY_ROWS THEN
      
      RETURN TRUE;
      
END;


FUNCTION FRetornaVlSomaAnoRubrica(pCdVinculo IN INTEGER,
                                  pFolha     IN PKGPAG_TIPO.rFolha,
                                  pNuTipoRub IN INTEGER,
                                  pNuRubrica IN INTEGER) RETURN NUMBER IS
   VVL050546 NUMBER(13, 2);
   
BEGIN
   
   SELECT SUM(RV.VLPAGAMENTO)
     INTO VVL050546
     FROM EPAGHISTORICORUBRICAVINCULO RV
    INNER JOIN EPAGFOLHAPAGAMENTO FP
       ON FP.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
      AND FP.NUANOREFERENCIA = pFOlha.NuAnoReferencia
      AND FP.cdAgrupamento = pFolha.CdAgrupamento
      AND ( /*(fp.cdtipofolhapagamento = pkgpag_var.vgFolha.cdtipofolhapagamento AND fp.cdtipocalculo = pkgpag_var.vgFolha.cdtipocalculo AND (pkgpag_var.vgFolha.FlCalculoDefinitivo = 'N' AND
                                                                      fp.flcalculodefinitivo IN ('S', 'N')) OR
                                                                      (pkgpag_var.vgFolha.FlCalculoDefinitivo = 'S' AND
                                                                      fp.flcalculodefinitivo = 'S')) OR*/
           fp.flcalculodefinitivo = 'S' OR
           (fp.flcalculodefinitivo = 'N' AND fp.cdtipocalculo = 1 AND
           (FP.NUANOMESREFERENCIA = pfolha.NuAnoMesReferencia)))
    INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
       ON FP.CDTIPOFOLHAPAGAMENTO = TFP.CDTIPOFOLHAPAGAMENTO
      
    INNER JOIN VPAGRUBRICAAGRUPAMENTO RUB
       ON RUB.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO
      AND RUB.NURUBRICA IN (pNuRubrica)
      AND RUB.CDTIPORUBRICA = pNuTipoRub
    INNER JOIN ECADVINCULO V
       ON V.CDVINCULO = RV.CDVINCULO
      AND V.CDPESSOA IN (SELECT P.CDPESSOA
                           FROM SIGRH.ECADVINCULO V
                          INNER JOIN ECADPESSOA P
                             ON P.CDPESSOA = V.CDPESSOA
                          WHERE CDVINCULO = pCdVinculo)
    WHERE ((V.CDVINCULO <> pCdVinculo AND
          FP.CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento) OR
          FP.CDFOLHAPAGAMENTO <> pFolha.CdFolhaPagamento AND
          NOT
           (pFolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoRecalculoMes AND
           fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoNormal -- normal
           AND rv.cdvinculo = pCdVinculo AND
           fp.nuanomesreferencia =
           to_char(pFolha.DtInicioMes, 'YYYYMM')))
            
         --Se folha definitiva, busca apenas outras definitivas.
         --Se folha normal, busca definitivas ou normais.
      AND ((FP.FLCALCULODEFINITIVO = 'S' AND
          pFolha.FlCalculoDefinitivo = 'S') OR
          ((FP.FLCALCULODEFINITIVO IN ('N', 'S') AND
          pFolha.FlCalculoDefinitivo = 'N')))
            
      AND
         --Folhas de 13o
          (((pFolha.CdTipoFolha IN
          (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13) /*AND pFolha.NuMesReferencia <> 12*/
          ) OR
          --Se folha 13o Dezembro, não pega folha 13o Novembro
          (pFolha.CdTipoFolha IN
          (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13) AND
          pFolha.NuMesReferencia = 12 AND
          (FP.NUMESREFERENCIA <> 11 OR
          (FP.NUMESREFERENCIA = 11 AND
          TFP.Cdtipofolha NOT IN
          (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13))))) OR
          --Se folha diferente de 13o, não pega 13o do mesmo mês
          (pFolha.CdTipoFolha NOT IN
          (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13) AND
          (TFP.CDTIPOFOLHA NOT IN
          (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13) OR
          (TFP.CDTIPOFOLHA IN
          (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13) AND
          FP.NUANOMESREFERENCIA = pFolha.NuAnoMesReferencia ))))
      
    ORDER BY FP.NUANOMESREFERENCIA DESC;
   
   RETURN NVL(VVL050546, 0);
END;


FUNCTION FRetornaBaseOutraFolAberta(pCdVinculo IN INTEGER,
                                    pFolha     IN PKGPAG_TIPO.rFolha,
                                    pCdRubrica IN INTEGER) RETURN NUMBER IS
   
   vVlBase NUMBER(13, 2);
   
BEGIN
   
   SELECT SUM(RV.VLPAGAMENTO)
     INTO vVlBase
     FROM EPAGHISTORICORUBRICAVINCULO RV
    INNER JOIN EPAGFOLHAPAGAMENTO FP
       ON FP.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
      AND FP.cdAgrupamento = pFolha.CdAgrupamento
      AND fp.flcalculodefinitivo = 'N'
      AND fp.cdtipocalculo = 1
      AND FP.NUANOMESREFERENCIA = pfolha.NuAnoMesReferencia
    INNER JOIN ECADVINCULO V
       ON V.CDVINCULO = RV.CDVINCULO
      AND V.CDPESSOA IN (SELECT P.CDPESSOA
                           FROM SIGRH.ECADVINCULO V
                          INNER JOIN ECADPESSOA P
                             ON P.CDPESSOA = V.CDPESSOA
                          WHERE CDVINCULO = pCdVinculo)
    WHERE V.CDVINCULO <> pCdVinculo
      AND rv.cdrubricaagrupamento = pCdRubrica
    ORDER BY FP.NUANOMESREFERENCIA DESC;
   
   RETURN NVL(vVlBase, 0);
END;


PROCEDURE PAplicarAliquotaIRRF (pVlBase IN NUMBER, pVlNM IN NUMBER, pVlDesc OUT NUMBER, pIndiceDesc OUT NUMBER) IS

BEGIN
   
   pVlDesc     := 0;
   pIndiceDesc := NULL;
      
   FOR i IN 1 .. PKGPAG_VAR.vAliquotaIRRF.lFaixa.COUNT LOOP
 
      IF pVlBase >= PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).vlInicial * pVlNm 
         AND (i = PKGPAG_VAR.vAliquotaIRRF.lFaixa.COUNT OR pVlBase <= PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).vlFinal * pVlNm) THEN
                           
         pVlDesc         := pVlBase * PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota / 100
                            - NVL(PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).VlParcelaDeducao * pVlNm,0);
                                                                  
         pIndiceDesc := PKGPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota;
                           
         EXIT;
                           
      END IF;
                        
   END LOOP;
 
END;

FUNCTION FValoresBaseIRRF (pTributacao IN rTributacao, pCdTipoTributacaoIRRF IN INTEGER, pVlDescRubDepJuizo IN NUMBER,
                           pvlDescRubIsentaIRRF IN NUMBER) return rBase IS

   vBase      rBase;
  vTpMes      CHAR(1);

BEGIN
   
   IF pCdTipoTributacaoIRRF = 1 THEN
      vTpMes := PKGPAG_TIPO.cnTpMesTribCaixa;
   ELSE
      vTpMes := PKGPAG_TIPO.cnTpMesTribAtual;
   END IF;   

   SELECT MAX(1) as FlCalcular,
          MAX(CASE
                 WHEN v.cdvinculo <> pTributacao.CdVinculo THEN
                  1
                 ELSE
                  0
              END) AS FlPossuiOutroVinculo,
                                     
          NVL(SUM(CASE
                     WHEN CdRubricaAgrupamento =
                          pTributacao.irrf.CdRubBaseIRRF AND
                          FP.CdFolhaPagamento =
                          pTributacao.pFolha.CdFolhaPagamento AND
                          V.cdVinculo = pTributacao.CdVinculo THEN
                      RV.vlPagamento
                  END) - pvlDescRubIsentaIRRF,
              0) AS VlBaseAtual,
                                     
          NVL(SUM(CASE
                     WHEN CdRubricaAgrupamento =
                          pTributacao.irrf.CdRubBaseIRRF AND
                          FP.CdFolhaPagamento =
                          pTributacao.pFolha.CdFolhaPagamento AND
                          V.cdVinculo = pTributacao.CdVinculo THEN
                      RV.vlPagamento
                  END) - pVlDescRubDepJuizo,
              0) AS VlBaseAtualSemDepJuizo,
                                     
          NVL(SUM(CASE
                     WHEN FP.CdFolhaPagamento =
                          pTributacao.pFolha.CdFolhaPagamento AND
                          V.CdVinculo = pTributacao.CdVinculo THEN
                      CASE
                         WHEN CdRubricaAgrupamento IN
                              (pTributacao.irrf.CdRubAgrupDescIRRF) THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS VlDeduzidoAtual,
                                     
          NVL(SUM(CASE
                     WHEN CdRubricaAgrupamento =
                          pTributacao.irrf.CdRubBaseIRRF AND
                          FP.CdFolhaPagamento <>
                          pTributacao.pFolha.CdFolhaPagamento AND
                          flImplantado = 'N' THEN
                      RV.vlPagamento
                  END),
              0) AS vlBaseOutrosForaSIGRH,
                                     
          NVL(SUM(CASE
                     WHEN V.CdVinculo <> pTributacao.CdVinculo AND
                          flImplantado = 'S' THEN
                      CASE
                         WHEN CdRubricaAgrupamento IN
                              (pTributacao.irrf.CdRubBaseDeducaoInativo) THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS vlAbat65AnosOutrosSIGRH,
          NVL(SUM(CASE
                     WHEN V.CdVinculo <> pTributacao.CdVinculo AND
                          flImplantado = 'N' THEN
                      CASE
                         WHEN CdRubricaAgrupamento IN
                              (pTributacao.irrf.CdRubBaseDeducaoInativo) THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS vlAbat65AnosOutrosSIRH,
                                     
          /*NVL(SUM(CASE
          WHEN CdRubricaAgrupamento = pTributacao.irrf.CdRubBaseIRRF
               AND (FP.CdFolhaPagamento <> pFolha.CdFolhaPagamento OR V.CdVinculo <> pCdVinculo)
               AND (FP.CdTipoFolha = pFolha.CdTipoFolha AND FP.CdTipoCalculo = pFolha.CdTipoCalculo) THEN
            RV.vlPagamento
          END),0) AS vlBaseOutroVincMesmaFol,*/
                                     
          NVL(SUM(CASE
                     WHEN (FP.CdFolhaPagamento <>
                          pTributacao.pFolha.CdFolhaPagamento OR
                          V.CdVinculo <> pTributacao.CdVinculo) AND
                          (FP.CdTipoFolha =
                          pTributacao.pFolha.CdTipoFolha AND
                          FP.CdTipoCalculo =
                          pTributacao.pFolha.CdTipoCalculo) THEN
                      CASE
                         WHEN CdRubricaAgrupamento IN
                              (pTributacao.irrf.CdRubBaseIRRF) THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS vlBaseOutroVincMesmaFol,
          NVL(SUM(CASE
                     WHEN CdRubricaAgrupamento =
                          pTributacao.irrf.CdRubBaseIRRF AND
                          (FP.CdFolhaPagamento <>
                          pTributacao.pFolha.CdFolhaPagamento OR
                          V.CdVinculo <> pTributacao.CdVinculo) AND
                          (FP.CdTipoFolha <>
                          pTributacao.pFolha.CdTipoFolha OR
                          FP.CdTipoCalculo <>
                          pTributacao.pFolha.CdTipoCalculo) THEN
                      RV.vlPagamento
                  END),
              0) AS vlBaseOutroVincOutraFol,
          NVL(SUM(CASE
                     WHEN CdRubricaAgrupamento =
                          pTributacao.irrf.CdRubBaseIRRF AND
                          (FP.CdFolhaPagamento <>
                          pTributacao.pFolha.CdFolhaPagamento AND
                          V.CdVinculo = pTributacao.CdVinculo) AND
                          (FP.CdTipoFolha <>
                          pTributacao.pFolha.CdTipoFolha OR
                          FP.CdTipoCalculo <>
                          pTributacao.pFolha.CdTipoCalculo) AND
                          pTributacao.pfolha.cdagrupamento <> 132 THEN -- sig-8230 estava causando erro suplementar agrupamento 132
                      RV.vlPagamento
                  END),
              0) AS vlBaseMesmoVincOutraFol, -- necessário devido a folha de Honorários PGE
                                     
          NVL(SUM(CASE
                     WHEN (FP.CdFolhaPagamento <>
                          pTributacao.pFolha.CdFolhaPagamento OR
                          V.CdVinculo <> pTributacao.CdVinculo) AND
                          (FP.CdTipoFolha =
                          pTributacao.pFolha.CdTipoFolha AND
                          FP.CdTipoCalculo =
                          pTributacao.pFolha.CdTipoCalculo) THEN
                      CASE
                         WHEN CdRubricaAgrupamento IN
                              (pTributacao.irrf.CdRubAgrupDescIRRF) THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS vlDeduzOutroVincMesmaFol,
                                     
          NVL(SUM(CASE
                     WHEN (FP.CdFolhaPagamento <>
                          pTributacao.pFolha.CdFolhaPagamento OR
                          V.CdVinculo <> pTributacao.CdVinculo) AND
                          (FP.CdTipoFolha <>
                          pTributacao.pFolha.CdTipoFolha OR
                          FP.CdTipoCalculo <>
                          pTributacao.pFolha.CdTipoCalculo) THEN
                      CASE
                         WHEN CdRubricaAgrupamento IN
                              (pTributacao.irrf.CdRubAgrupDescIRRF) THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS vlDeduzOutroVincOutraFol,
          NVL(SUM(CASE
                     WHEN (FP.CdFolhaPagamento <>
                          pTributacao.pFolha.CdFolhaPagamento AND
                          V.CdVinculo = pTributacao.CdVinculo) AND
                          (FP.CdTipoFolha <>
                          pTributacao.pFolha.CdTipoFolha OR
                          FP.CdTipoCalculo <>
                          pTributacao.pFolha.CdTipoCalculo) AND
                          pTributacao.pfolha.cdagrupamento <> 132 -- sig-8230 estava causando erro suplementar agrupamento 132
                      THEN
                      CASE
                         WHEN CdRubricaAgrupamento IN
                              (pTributacao.irrf.CdRubAgrupDescIRRF) THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS vlDeduzMesmoVincOutraFol, -- necessário devido a folha de Honorários PGE
                                     
          NVL(SUM(CASE
                     WHEN (V.CdVinculo <> pTributacao.CdVinculo) THEN
                      CASE
                         WHEN CdRubricaAgrupamento =
                              PKGPAG_VAR.vgCdRubricaDescDepIRRF THEN
                          RV.vlPagamento
                      END
                  END),
              0) AS VlDeducaoDependOutroVinc,  
          pVlDescRubDepJuizo    as VlDescRubDepJuizo,
          pvlDescRubIsentaIRRF  as VlDescRubIsentaIRRF                        
       INTO vBase                            
       FROM ECadVinculo V
      INNER JOIN ECalFolhaTrib FP
         ON FP.SGTRIBUTO = PKGPAG_TIPO.cnSgTribIRRF
        AND FP.TPMES = vTpMes
        AND FP.CdCalculoPai = PKGPAG_VAR.vgCalculo.CdCalculoPai
                       
        AND EXISTS (SELECT 1 FROM TABLE(pTributacao.FolPermitida)
                     WHERE FP.CdFolhaPagamento = to_number(column_value) )                    

      INNER JOIN EPagHistoricoRubricaVinculo RV
         ON V.CdVinculo = RV.CdVinculo
        AND FP.CdFolhaPagamento = RV.CdFolhaPagamento
      WHERE V.CdPessoa = pTributacao.CdPessoa
        AND RV.CdRubricaAgrupamento IN (pTributacao.irrf.CdRubBaseIRRF,
                                        pTributacao.irrf.CdRubAgrupDescIRRF,
                                        PKGPAG_VAR.vgCdRubricaDescDepIRRF,
                                        pTributacao.irrf.CdRubBaseDeducaoInativo,
                                        pTributacao.irrf.CdRubAgrupDevDescIRRF)
        AND -- Desconsiderar a folha normal do orgao quando fazendo recalculo
            (NOT
                 (pTributacao.pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes -- Fazendo Recalculo
                  AND ( (RV.CdVinculo = pTributacao.CdVinculo AND
                          (FP.CdFolhaPagamento = PKGPAG_VAR.vgVinculo.CdFolhaPagamentoNormal 
                           OR (FP.CdFolhaPagamento <> pTributacao.pFolha.CdFolhaPagamento 
                               AND FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes
                               )
                          )
                        ) 
                       OR
                       (RV.CdVinculo <> pTributacao.CdVinculo AND FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes
                       )
                     )
                 )
             )
                                      
        AND (NOT 
                 (pTributacao.pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes 
                  AND PKGPAG_VAR.vgFaseCalculo = PKGPAG_TIPO.cnFaseCalculoIntegral 
                  AND ( (RV.CdVinculo = pTributacao.CdVinculo AND
                         (FP.CdFolhaPagamento = PKGPAG_VAR.vgVinculo.CdFolhaPagamentoNormal 
                          OR (FP.CdFolhaPagamento <> pTributacao.pFolha.CdFolhaPagamento 
                              AND FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes
                             )
                          )
                         ) 
                         OR
                         (RV.CdVinculo <> pTributacao.CdVinculo AND FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes
                         )
                      )
                 )
             );
                                

   RETURN vBase;

END;


PROCEDURE PPosCalcIRRF(pTributacao              IN rTributacao,
                       pTpTributacao            IN INTEGER,
                       pBase                    IN rBase,
                       pbPrima                  IN BOOLEAN,
                       pIndProcRetro            IN INTEGER,
                       pVlDeducaoInativoReal   OUT NUMBER
                       ) IS

   vDeExpressao              VARCHAR2(200);
   vCdRubDescIRRFGerada      INTEGER;    
   vVlLiquido                NUMBER(13, 2);
   vVlIndiceRubrica          NUMBER(13, 2);
   vVlBaseOutros             NUMBER(13, 2);  
   vVlDeduzidoOutros         NUMBER(13, 2);    
   vVlNM                     NUMBER(4, 1);
   vVlNmReal                 NUMBER(13, 3);
   vVlNmRealDec              NUMBER(13, 3);  
   vvlrubDescSimp            NUMBER(13, 2);
   vVlRub50216               NUMBER(13, 2) := 0; 
   vCdProcPagRetro           INTEGER;   
   vVlIprevRRA               NUMBER(13, 2);   
   vVlBaseIRRFPENSAO         pkgpag_tipo.rValorPagamento;
   vVlAbat65AnosOutrosSIGRH  NUMBER(13, 2);
   vVlBaseAtual              NUMBER(13, 2);
   vVlOutrosRRA              NUMBER(13, 2);
   vVlIsentoRetroIRRF        NUMBER(13, 2);
   vVlIsentoRetroIRRFRRA     NUMBER(13, 2);   
     
   PROCEDURE PAtualizaBaseIRRF(pvlBase IN NUMBER,
                               pVlNm   IN NUMBER DEFAULT NULL) IS
      
   BEGIN
      
      IF pBase.VlDescRubIsentaIRRF > 0 OR vVlOutrosRRA > 0 OR
         vVlIsentoRetroIRRF > 0 OR vVlIsentoRetroIRRFRRA > 0 THEN
         
         UPDATE EPagHistoricoRubricaVinculo HRV
            SET HRV.VlPagamento   = GREATEST(pvlBase, 0),
                HRV.VlIndiceNMRRA = NVL(pVlNm, HRV.VlIndiceNMRRA)
          WHERE HRV.CdVinculo = pTributacao.CdVinculo
            AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
            AND HRV.CdRubricaAgrupamento = pTributacao.irrf.CdRubBaseIRRF;
         
      END IF;
      
   EXCEPTION
      WHEN OTHERS THEN
         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'PKGPAG_TRIBUTACAO.PAtualizaBaseIRRF',
                                 PKGPAG_VAR.vgCdVinculo);
         
   END;  
 
   FUNCTION FRetornaVlDeduzidoOutros(pCdPessoa  IN INTEGER,
                                     pCdVinculo IN INTEGER,
                                     pFolha     IN PKGPAG_TIPO.rFolha)
      RETURN NUMBER IS
      vVlDeduzido NUMBER(13, 2);
      
   BEGIN
      
      SELECT SUM(HRV.vlpagamento)
        INTO vVlDeduzido
        FROM Epaghistoricorubricavinculo HRV
       INNER JOIN Epagfolhapagamento F
          ON F.cdfolhapagamento = HRV.Cdfolhapagamento
       INNER JOIN Ecadvinculo V
          ON V.cdvinculo = HRV.Cdvinculo
       WHERE F.Cdfolhapagamento = pFolha.CdFolhaPagamento
            --  AND F.Nuanomesreferencia = pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
         AND HRV.Cdrubricaagrupamento = pTributacao.irrf.CdRubAgrupDescIRRF
         AND V.cdpessoa = pCdPessoa
         AND HRV.cdvinculo <> pCdVinculo;
      
      RETURN NVL(vVlDeduzido, 0);
      
   EXCEPTION
      
      WHEN OTHERS THEN
         
         RETURN 0;
         
   END;
     
   FUNCTION FRetornaVlBaseOutros(pCdPessoa  IN INTEGER,
                                 pCdVinculo IN INTEGER,
                                 pFolha     IN PKGPAG_TIPO.rFolha)
      RETURN NUMBER IS
      vVlDeduzido NUMBER(13, 2);
      
   BEGIN
      
      SELECT SUM(HRV.vlpagamento)
        INTO vVlDeduzido
        FROM Epaghistoricorubricavinculo HRV
       INNER JOIN Epagfolhapagamento F
          ON F.cdfolhapagamento = HRV.Cdfolhapagamento
       INNER JOIN Ecadvinculo V
          ON V.cdvinculo = HRV.Cdvinculo
       WHERE F.Cdfolhapagamento = pFolha.CdFolhaPagamento
            --  AND F.Nuanomesreferencia = pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
         AND HRV.Cdrubricaagrupamento = pTributacao.irrf.CdRubBaseIRRF
         AND V.cdpessoa = pCdPessoa
         AND HRV.cdvinculo <> pCdVinculo;
      
      RETURN NVL(vVlDeduzido, 0);
      
   EXCEPTION
      
      WHEN OTHERS THEN
         
         RETURN 0;
         
   END;
  
BEGIN
 
   vDeExpressao          := null; 
   
   pVlDeducaoInativoReal := 0;

   vVlIprevRRA           := 0;  
   vVlOutrosRRA          := 0; 
   vCdRubDescIRRFGerada  := NULL;
    
   vCdProcPagRetro       := NULL;  
   IF pIndProcRetro IS NOT NULL THEN
      vCdProcPagRetro := PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo;
   END IF;
  
   --
   -- Solicitacao de Sustentacao #72799
   -- 9375/2016 - FOLHA - - CALCULO DO IRRF DA PENSAO ALIMENTICIA SOMENTE DO 126
   --
   
   vVlBaseIRRFPENSAO := NULL;
   
   IF FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => pTributacao.rub.CdRubBaseIRRFPENSAO) > 0 THEN

      vVlBaseIRRFPENSAO := PKGPAG_FB.FRetornaValorBaseCalculo(pfolha            => pTributacao.pFolha,
                                                              pcdvinculo        => PKGPAG_VAR.vgCdVinculo,
                                                              pcdtipohistorico  => 2,
                                                              pcdrelacaovinculo => 0,
                                                              pcdbasecalculo    => pkgpag_var.vgrubrica(pTributacao.rub.CdRubBaseIRRFPENSAO).cdbasecalculo,
                                                              pcdchave          => pTributacao.cdvinculo);
               
   END IF;

   IF pBase.FlPossuiOutroVinculo = 1 AND
      pTributacao.irrf.VlDeducaoDependente = 0 AND 
       pTributacao.irrf.FlPermiteDescSimpl = 0 THEN
                     
      PKGPAG_VAR.vgVlDeducaoDependOutroVinc := FDependenteOutroVinculo(pTributacao.CdPessoa,
                                                                       pTributacao.CdVinculo,
                                                                       pTributacao.pFolha.DtInicioMes,
                                                                       pTributacao.pFolha.DtFimMes) *
                                                                          PKGPAG_VAR.vAliquotaIRRF.VlDeducaoDependente;
                     
   END IF;
                  
   IF pBase.vlBaseOutroVincMesmaFol <> 0 THEN
                     
      IF --A base BIR13 já soma os valores dos outros vinculos
       pTributacao.irrf.CdRubBaseIRRF = PKGPAG_VAR.vgCdRubBaseIRRF13 THEN
         vVlBaseOutros := 0;
      ELSE
         vVlBaseOutros := pBase.vlBaseOutroVincMesmaFol;
      END IF;
                     
      vVlDeduzidoOutros := pBase.vlDeduzOutroVincMesmaFol;
      --PKGPAG_VAR.vgVlDeducaoDependOutroVinc := pBase.VlDeducaoDependOutroVinc;
                     
   ELSIF pBase.FlPossuiOutroVinculo = 1 THEN
                     
      vVlBaseOutros     := pBase.vlBaseOutroVincOutraFol;
      vVlDeduzidoOutros := pBase.vlDeduzOutroVincOutraFol;
      --PKGPAG_VAR.vgVlDeducaoDependOutroVinc := pBase.VlDeducaoDependOutroVinc;
                     
   ELSIF pBase.vlBaseMesmoVincOutraFol <> 0 THEN
      -- necessário devido a folha de honorários PGE
      vVlBaseOutros     := pBase.vlBaseMesmoVincOutraFol;
      vVlDeduzidoOutros := pBase.vlDeduzMesmoVincOutraFol;
                     
   ELSE
                     
      vVlBaseOutros     := 0;
      vVlDeduzidoOutros := 0;
                     
   END IF;
                  
   IF pTributacao.pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes THEN
                     
      vVlBaseOutros := FRetornaVlBaseOutros(pTributacao.CdPessoa,
                                            pTributacao.CdVinculo,
                                            pTributacao.pFolha);
                     
   END IF;

   pDebug ('PPosCalcIRRF: tipo tributacao: ' || pTpTributacao );
                   
   IF pTpTributacao <> CTRIB_TIPO_RRA THEN

      -- Normal, 13º, Ferias
                       
      vVlNM := 1;
                   
      IF pTributacao.irrf.FlPermiteDescSimpl = 1 THEN

         vVlAbat65AnosOutrosSIGRH  := 0;
         pVlDeducaoInativoReal     := 0;

      ELSE
         vVlAbat65AnosOutrosSIGRH  := pBase.vlAbat65AnosOutrosSIGRH;         
         pVlDeducaoInativoReal     := pTributacao.irrf.VlDeducaoInativo;                        
                       
      END IF;

      ----------------------------------------------------------------------
      -- Se tem mais de 1 vinculo no SIRH como inativo
      -- No SIRH a base ja e Liquida, nao deve deduzir o Abat Maior 65 anos
      ----------------------------------------------------------------------
                     
      IF pBase.vlBaseOutrosForaSIGRH > 0 AND pBase.vlAbat65AnosOutrosSIRH > 0 THEN
                        
         IF pBase.vlAbat65AnosOutrosSIRH <= pTributacao.irrf.VlDeducaoInativo THEN
                           
            pVlDeducaoInativoReal := pTributacao.irrf.VlDeducaoInativo - pBase.vlAbat65AnosOutrosSIRH;
                           
         END IF;
                        
         vVlBaseOutros := fRetornaBaseOutraFolAberta(pTributacao.CdVinculo,
                                                     pTributacao.pFolha,
                                                     pTributacao.irrf.CdRubBaseIRRF);
         
         vDeExpressao := vDeExpressao || '3Base=' || pBase.VlBaseAtual
                                      || '+' || vVlBaseOutros
                                      || '-depen(' || (pTributacao.irrf.VlDeducaoDependente || ')'
                                      || '-' || pVlDeducaoInativoReal
                                      || '=' || vvlLiquido);                                     
                        
         vvlLiquido := (pBase.VlBaseAtual + vVlBaseOutros) -
                       (pTributacao.irrf.VlDeducaoDependente +
                       pVlDeducaoInativoReal);
                        
         vVlBaseIRRFPENSAO.vlReal := (nvl(vVlBaseIRRFPENSAO.VlReal, 0) +
                               vVlBaseOutros) -
                               (pTributacao.irrf.VlDeducaoDependente +
                               pVlDeducaoInativoReal);
                        
      ELSIF vVlAbat65AnosOutrosSIGRH > 0 THEN

         IF vVlAbat65AnosOutrosSIGRH <= pTributacao.irrf.VlDeducaoInativo THEN
                           
            pVlDeducaoInativoReal := pTributacao.irrf.VlDeducaoInativo -
                                     vVlAbat65AnosOutrosSIGRH;
                           
         END IF;
                        
         vvlLiquido := (pBase.VlBaseAtual + vVlBaseOutros) -
                       (pTributacao.irrf.VlDeducaoDependente +
                       PKGPAG_VAR.vgVlDeducaoDependOutroVinc +
                       vVlAbat65AnosOutrosSIGRH +
                       pVlDeducaoInativoReal);
 
         vDeExpressao := vDeExpressao || '4Base=' || pBase.VlBaseAtual
                                      || '+' || vVlBaseOutros
                                      || '-depen(' || (pTributacao.irrf.VlDeducaoDependente || ')'
                                      || '-deoOutr(' || PKGPAG_VAR.vgVlDeducaoDependOutroVinc || ')'
                                      || '-65Ano(' || vVlAbat65AnosOutrosSIGRH|| ')'
                                      || '-' || pVlDeducaoInativoReal
                                      || '=' || vvlLiquido);                                     
                                                        
         vVlBaseIRRFPENSAO.vlReal := (nvl(vVlBaseIRRFPENSAO.VlReal, 0) +
                               vVlBaseOutros) -
                               (pTributacao.irrf.VlDeducaoDependente +
                               PKGPAG_VAR.vgVlDeducaoDependOutroVinc +
                               vVlAbat65AnosOutrosSIGRH +
                               pVlDeducaoInativoReal);
                        
      ELSE

         IF pTributacao.pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolha13 THEN
                           
            IF pTributacao.irrf.FlPermiteDescSimpl = 1 THEN
                                                            
               IF (FRetornaValorRubrica(pTributacao => pTributacao,
                                        pCdRubrica  => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                        pNuSufixo   => 1) +
                   FRetornaValorRubrica(pTributacao => pTributacao,
                                        pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                        pNuSufixo   => 1)) > pTributacao.irrf.vlDescSimp THEN
                                 
                  vvlrubDescSimp := FRetornaValorRubrica(pTributacao => pTributacao,
                                                         pCdRubrica  => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                                         pNuSufixo   => 1)
                                  + FRetornaValorRubrica(pTributacao => pTributacao,
                                                         pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                                         pNuSufixo   => 1);
               ELSE
                                 
                  vvlrubDescSimp := pTributacao.irrf.vlDescSimp;
                                 
                  ------------------------------------------------------
                  -- BASE DESCONTO SIMPLIFICADO IRRF 13 SAL 09-1913   --
                  ------------------------------------------------------
                  IF PKGPAG_VAR.vgCdRubBaseDescSimplif13 IS NOT NULL AND
                     FRetornaValorRubrica(pTributacao => pTributacao,
                                          pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDescSimplif13,
                                          pNuSufixo   => 1) = 0 THEN
                                    
                     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                           pCdVinculo            => pTributacao.CdVinculo,
                                                           pCdExpressaoFormCalc  => NULL,
                                                           pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDescSimplif13,
                                                           pNuSufixoRubrica      => 1,
                                                           pVlPagamento          => 0,
                                                           pVlIndice             => NULL,
                                                           pCdTipoOrigemRubrica  => 10);
                                    
                     PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                                      pCdVinculo       => pTributacao.CdVinculo,
                                                      pCdRubrica       => PKGPAG_VAR.vgCdRubBaseDescSimplif13,
                                                      pTpProcessamento => 2, -- Processa base de calculo
                                                      pTpLocal         => 2);
                                    
                  END IF;
                                 
               END IF;
                     
                        
               vvlLiquido := (pBase.VlBaseAtual + vVlBaseOutros) -vvlrubDescSimp;
 
               vDeExpressao := vDeExpressao || '1Base=' || pBase.VlBaseAtual
                                            || '+' || vVlBaseOutros
                                            || '-simpl(' || vvlrubDescSimp || ')'
                                            || '=' || vvlLiquido;
                                                                   
               vVlBaseIRRFPENSAO.vlReal := nvl(vVlBaseIRRFPENSAO.VlReal, 0) +vVlBaseOutros;
               
            ELSE
                              
               --sig-5337
               --Para folha de 13 salário, não considera a base de outros vinculos pois o calc da
               --09-0015 já considera o somaAno das rubricas
                              
                              
               IF pTributacao.pFolha.CdAgrupamento = CAGR_PMSC THEN
                                 
                  vvlLiquido := pBase.VlBaseAtual -
                                (pTributacao.irrf.VlDeducaoDependente +
                                PKGPAG_VAR.vgVlDeducaoDependOutroVinc +
                                pVlDeducaoInativoReal);
                                 
                  vDeExpressao := vDeExpressao || '5Base=' || pBase.VlBaseAtual
                             || '-dep(' || pTributacao.irrf.VlDeducaoDependente || ')'
                             || '-depOut(' || PKGPAG_VAR.vgVlDeducaoDependOutroVinc || ')'
                             || '-' || pVlDeducaoInativoReal
                             || '=' || vvlLiquido;              
                                
                  vVlBaseIRRFPENSAO.vlReal := pBase.VlBaseAtual -
                                        (pTributacao.irrf.VlDeducaoDependente +
                                        PKGPAG_VAR.vgVlDeducaoDependOutroVinc +
                                        pVlDeducaoInativoReal);
               ELSE
                                 
                  vvlLiquido := pBase.VlBaseAtual - (PKGPAG_VAR.vgVlDeducaoDependOutroVinc + pVlDeducaoInativoReal);
 
                  vDeExpressao := vDeExpressao || '6Base=' || pBase.VlBaseAtual
                             || '-depOut(' || PKGPAG_VAR.vgVlDeducaoDependOutroVinc || ')'
                             || '=' || vvlLiquido; 
                                                             
                  vVlBaseIRRFPENSAO.vlReal := pBase.VlBaseAtual - (PKGPAG_VAR.vgVlDeducaoDependOutroVinc + pVlDeducaoInativoReal);
               END IF;
                              
            END IF;
                           
         ELSE
                           
            IF pTributacao.irrf.FlPermiteDescSimpl = 1 AND
               pTributacao.pFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaFerias AND
               pTpTributacao <> CTRIB_TIPO_FERIAS THEN
                              
               IF pTributacao.pFolha.NuAnoMesReferencia >= 202408 THEN
                                 
                  IF pTpTributacao = CTRIB_TIPO_DECTER THEN
                                    
                     IF (FRetornaValorRubrica(pTributacao => pTributacao,
                                              pCdRubrica  => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                              pNuSufixo   => 1) 
                       + FRetornaValorRubrica(pTributacao => pTributacao,
                                              pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                              pNuSufixo   => 1)) > pTributacao.irrf.vlDescSimp THEN
                                       
                        vvlrubDescSimp := FRetornaValorRubrica(pTributacao => pTributacao,
                                                               pCdRubrica  => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                                               pNuSufixo   => 1)
                                        + FRetornaValorRubrica(pTributacao => pTributacao,
                                                               pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                                               pNuSufixo   =>1);
                     ELSE
                                       
                        vvlrubDescSimp := pTributacao.irrf.vlDescSimp;
                                       
                        -------------------------------------------------------------
                        -- INSERE BASE DESCONTO SIMPLIFICADO IRRF 13 SAL 09-1913   --
                        -------------------------------------------------------------
                        IF PKGPAG_VAR.vgCdRubBaseDescSimplif13 IS NOT NULL AND
                           FRetornaValorRubrica(pTributacao => pTributacao,
                                                pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDescSimplif13,
                                                pNuSufixo   => 1) = 0 THEN
                                          
                           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                                 pCdVinculo            => pTributacao.CdVinculo,
                                                                 pCdExpressaoFormCalc  => NULL,
                                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDescSimplif13,
                                                                 pNuSufixoRubrica      => 1,
                                                                 pVlPagamento          => 0,
                                                                 pVlIndice             => NULL,
                                                                 pCdTipoOrigemRubrica  => 10);
                                          
                           PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                                            pCdVinculo       => pTributacao.CdVinculo,
                                                            pCdRubrica       => PKGPAG_VAR.vgCdRubBaseDescSimplif13,
                                                            pTpProcessamento => 2, -- Processa base de calculo
                                                            pTpLocal         => 2);
                                          
                        END IF;
                                       
                     END IF;
                                    
                  ELSIF pTpTributacao = CTRIB_TIPO_NORMAL THEN
                                    
                     IF FRetornaValorRubrica(pTributacao => pTributacao,
                                              pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                              pNuSufixo   => 1) 
                      + FRetornaValorRubrica(pTributacao => pTributacao,
                                             pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                             pNuSufixo   => 1) > pTributacao.irrf.vlDescSimp THEN
                                       
                        vvlrubDescSimp := FRetornaValorRubrica(pTributacao => pTributacao,
                                                               pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                                               pNuSufixo   => 1)
                                        + FRetornaValorRubrica(pTributacao => pTributacao,
                                                               pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                                               pNuSufixo   => 1);
                     ELSE
                                       
                        vvlrubDescSimp := pTributacao.irrf.vlDescSimp;
                                       
                        -------------------------------------------------------
                        -- INSERE BASE DESCONTO SIMPLIFICADO IRRF  09-1910   --
                        -------------------------------------------------------
                        IF PKGPAG_VAR.vgCdRubBaseDescSimplifIRRF IS NOT NULL AND
                           FRetornaValorRubrica(pTributacao => pTributacao,
                                                pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDescSimplifIRRF,
                                                pNuSufixo   => 1) = 0 THEN
                                          
                           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                                 pCdVinculo            => pTributacao.CdVinculo,
                                                                 pCdExpressaoFormCalc  => NULL,
                                                                 pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDescSimplifIRRF,
                                                                 pNuSufixoRubrica      => 1,
                                                                 pVlPagamento          => 0,
                                                                 pVlIndice             => NULL,
                                                                 pCdTipoOrigemRubrica  => 10);
                                          
                           PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                                            pCdVinculo       => pTributacao.CdVinculo,
                                                            pCdRubrica       => PKGPAG_VAR.vgCdRubBaseDescSimplifIRRF,
                                                            pTpProcessamento => 2, -- Processa base de calculo
                                                            pTpLocal         => 2);
                                          
                        END IF;
                                       
                     END IF;
                                    
                  END IF;
                                 
               ELSE
                                 
                  vvlrubDescSimp := 0;
                                 
               END IF;
                                                                             
               vvlLiquido := (pBase.VlBaseAtual +
                             vVlBaseOutros) -
                             vvlrubDescSimp;
                              
               vDeExpressao := vDeExpressao || '2Base=' || pBase.VlBaseAtual
                             || '+' || vVlBaseOutros
                             || '-simpl(' || vvlrubDescSimp || ')'
                             || '=' || vvlLiquido; 
                          
               vVlBaseIRRFPENSAO.vlReal := nvl(vVlBaseIRRFPENSAO.VlReal,0) + vVlBaseOutros;
            ELSE
                              
               vvlLiquido := (pBase.VlBaseAtual +
                             vVlBaseOutros) -
                             (pTributacao.irrf.VlDeducaoDependente +
                             PKGPAG_VAR.vgVlDeducaoDependOutroVinc +
                             pVlDeducaoInativoReal);

               vDeExpressao := vDeExpressao || '7Base=' || pBase.VlBaseAtual
                             || '+' || vVlBaseOutros
                             || '-dep(' || pTributacao.irrf.VlDeducaoDependente || ')'
                             || '-depOut(' || PKGPAG_VAR.vgVlDeducaoDependOutroVinc || ')'
                             || '-' || pVlDeducaoInativoReal
                             || '=' || vvlLiquido;                      
                              
               vVlBaseIRRFPENSAO.vlReal := (nvl(vVlBaseIRRFPENSAO.VlReal,0) +
                                     vVlBaseOutros) -
                                     (pTributacao.irrf.VlDeducaoDependente +
                                     PKGPAG_VAR.vgVlDeducaoDependOutroVinc +
                                     pVlDeducaoInativoReal);
            END IF;
         END IF;
      END IF;
                   
      vDeExpressao := vDeexpressao || ' Base=' || vvlLiquido;
  
      -------------------------------------------------------------------
      -- Caso existam processos de retroativos isentos do IRRF,
      -- os valores destes serao abatidos da base liquida
      -------------------------------------------------------------------
                     
      vVlIsentoRetroIRRF := FValorIsentoRetIRRF(pFolha         => pTributacao.pFolha,
                                                pCdVinculo     => pTributacao.CdVinculo,
                                                pCdRubBaseIRRF => pTributacao.irrf.CdRubBaseIRRF);
                     
      IF pbPrima THEN
                        
         IF vVlIsentoRetroIRRF > 0 THEN
                           
            BEGIN
                              
               IF pBase.VlDescRubIsentaIRRF > 0 THEN
                               
                  UPDATE EPagHistoricoRubricaVinculo HRV
                     SET HRV.VlPagamento = HRV.vlPagamento + vVlIsentoRetroIRRF
                   WHERE HRV.CdVinculo = pTributacao.CdVinculo
                     AND HRV.CdFolhaPagamento =pTributacao.pFolha.CdFolhaPagamento
                     AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubExigibilidadeSusp;
                                 
               ELSE
                                 
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pTributacao.CdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubExigibilidadeSusp,
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => vVlIsentoRetroIRRF,
                                                        pVlIndice             => NULL,
                                                        pCdTipoOrigemRubrica  => 10);
                                 
               END IF;
                              
            EXCEPTION
               WHEN OTHERS THEN
                  PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                          PKGPAG_VAR.vCdHistParamCalc,
                                          PKGPAG_VAR.vCdPessoa,
                                          'PKGPAG_TRIBUTACAO.vvlDescRubIsentaIRRF',
                                          PKGPAG_VAR.vgCdVinculo);
            END;
                           
         END IF;
                        
      END IF;
                          
      vVlBaseAtual := pBase.VlBaseAtual;
          
      IF vVlIsentoRetroIRRF <> 0 THEN
      
         vVlLiquido := vVlLiquido - vVlIsentoRetroIRRF;

         vVlBaseIRRFPENSAO.vlReal := vVlBaseIRRFPENSAO.vlReal - vVlIsentoRetroIRRF;

         ----------------------------------------------------------------
         -- Abate o valor isento das rubricas de retroativo da base bruta
         ----------------------------------------------------------------
           
         vVlBaseAtual := vVlBaseAtual -  vVlIsentoRetroIRRF;

         vDeExpressao := vDeexpressao || '- isen ' || vVlIsentoRetroIRRF || '=' || vvlLiquido;
      
      END IF;
                  
   ELSE
      -- RRA
                     
      -- Valor uriundo das rubricas de retroativos de exercicios findos, isentas por decisao judicial
      -- e que incidem para na base de IRRF a ser subitraido desta base.
                     
      vVlIsentoRetroIRRFRRA := FValorIsentoRetIRRFRRA(pFolha                   => pTributacao.pFolha,
                                                      pCdVinculo               => pTributacao.CdVinculo,
                                                      pCdProcessoPagRetroativo => PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo,
                                                      pCdRubBaseIRRF           => pTributacao.irrf.CdRubBaseIRRF);
                     
      -- Como a base de IRRF nao soma as rubrias de ferias e 13º, soma estes valores para integralizar
      -- a base que sera transformada em base de IRRF de RRA
                     
      vVlOutrosRRA := vVlOutrosRRA +
                      FRetornaOutrosValoresRRA(pFolha                   => pTributacao.pFolha,
                                               pCdVinculo               => pTributacao.CdVinculo,
                                               pCdProcessoPagRetroativo => PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo);
                     
      -- Gera a rubrica de Exigibilidade suspensa de RRA caso o valor da variavel
      -- vVlIsentoRetroIRRFRRA seja maior que zero.
                     
      IF vVlIsentoRetroIRRFRRA > 0 THEN
                        
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo               => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc     => NULL,
                                               pCdRubricaAgrupamento    => PKGPAG_VAR.vgCdRubExigibilidadeSuspRRA,
                                               pNuSufixoRubrica         => pIndProcRetro,
                                               pVlPagamento             => vVlIsentoRetroIRRFRRA,
                                               pCdProcessoPagRetroativo => PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo,
                                               pVlIndice                => NULL,
                                               pCdTipoOrigemRubrica     => 10);
                        
      END IF;
                     
      vVlIprevRRA := vVlIprevRRA +
                     FRetornaIprevRRA(pFolha                   => pTributacao.pFolha,
                                      pCdVinculo               => pTributacao.CdVinculo,
                                      pCdProcessoPagRetroativo => PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo);
                     
      -- Somente somar se ja tiver base (por cause de bases negativas que geram totalizadoras com valor zero
                     
      IF pBase.VlBaseAtual >= 0 THEN                       
         vVlBaseAtual := pBase.VlBaseAtual + vVlOutrosRRA - vVlIsentoRetroIRRFRRA;
      ELSE
         vVlBaseAtual := pBase.VlBaseAtual;                  
      END IF;
                     
      IF NVL(PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).VlMontante, 0) <= PKGPAG_VAR.vgParamPagamento.VlLimitePagRetroativo THEN
                        
         vVlNM := PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).NuMeses;
                        
         IF pTributacao.pfolha.CdOrgao = 25 AND
                             
            PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).NuMeses = 49 THEN
                           
            vVlNM := 1;
                           
         END IF;
                        
      ELSE
                        
         -- Para calculo do NM deve utilizar a base bruta (por isso soma o valor do IPREV de RRA)
         vVlNmReal := trunc(PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).NuMeses *
                             ((vVlBaseAtual +
                              vVlIprevRRA) / PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).VlMontante),
                            3);
                        
         vVlNmRealDec := vVlNmReal - trunc(vVlNmReal);
                        
         IF substr(vVlNmRealDec, 3, 1) = 5 AND
            substr(vVlNmRealDec, 4, 1) < 5 THEN
            vVlNmReal := vVlNmReal - 0.0100;
         END IF;
                        
         vVlNM := ROUND(vVlNmReal, 1);
                        
      END IF;
                     
      vvlLiquido := vVlBaseAtual;
                     
      PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).VlIndiceNMRRA := vVlNM;
                     
   END IF;
 
   -- Continua
                 
   PAtualizaBaseIRRF(pvlBase => vVlBaseAtual,
                     pVlNM   => CASE
                                   WHEN pTpTributacao <> CTRIB_TIPO_RRA THEN
                                    NULL
                                   ELSE
                                    vVlNM
                                END);
                  
   -- AJUSTA O VALOR PARA O ABATIMENTO MAIOR 65 IRRF.
   -- SE A BASE IRRF FOR MAIOR QUE O ABATIMENTO, MANTEM O VALOR TOTAL DO ABATIMENTO CONFORME TABELA IR
   -- SE A BASE IRRF FOR MENOR QUE O ABATIMENTO, SETA O VALOR DA BASE IRRF
                  
   -- 9816/2017 - MILITARES - FOLHA - - CALCULO DO 09-0910 -ABAT 65 ANOS
   IF pTributacao.pFolha.CdAgrupamento = CAGR_PMSC AND pTpTributacao <> CTRIB_TIPO_NORMAL AND
      (FRetornaValorRubrica(pTributacao => pTributacao, pCdRubrica => pTributacao.rub.CdRubProvFERIASCTISP) > 0 OR
       FRetornaValorRubrica(pTributacao => pTributacao, pCdRubrica => pTributacao.rub.CdRubProvGRAT13CTISP) > 0) AND
       FRetornaValorRubrica(pTributacao => pTributacao, pCdRubrica => pkgpag_var.vgCdRubBaseIRRF) = 0 AND
      vVlBaseAtual < pVlDeducaoInativoReal THEN
                     
      pVlDeducaoInativoReal := vVlBaseAtual;
                     
   ELSIF vVlBaseAtual < pVlDeducaoInativoReal THEN
                     
      pVlDeducaoInativoReal := vVlBaseAtual;
                     
   ELSE
      NULL;
   END IF;
                  
   -- COHAB - INSS de ferias ficticio
   -- Para a COHAB, deduz o valor da rubrica 05-0216 DESCONTO 216 da base de IRRF
   IF pTributacao.pFolha.CdAgrupamento = 3 AND vVlBaseAtual > 0 THEN
      vVlRub50216 := FRetornaValorRubrica(pTributacao => pTributacao,
                                          pCdRubrica  => pTributacao.rub.CdRubDescINSSFERIAS);
                     
      IF vVlRub50216 > 0 THEN
         vvlLiquido := vvlLiquido - vVlRub50216;
         vDeExpressao := vDeexpressao || '- r50216=' || vvlLiquido;

      END IF;
   END IF;
           
   IF vVlBaseAtual > 0 THEN
      IF (pTributacao.pFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13)) OR
         (pTributacao.irrf.CdRubBaseIRRF = PKGPAG_VAR.vgCdRubBaseIRRF13 AND
         pTributacao.pFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolhaNormal,pkgpag_tipo.cnTpFolhaCtisp, PKGPAG_TIPO.cnTpFolhaConvenio)) THEN
         vvlDeduzidoOutros := FretornaVlSomaAnoRubrica(pTributacao.CdVinculo,
                                                       pTributacao.pFolha,
                                                       5,
                                                       546);
                        
      ELSIF pTributacao.pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes THEN
                        
         vvlDeduzidoOutros := FRetornaVlDeduzidoOutros(pTributacao.CdPessoa,
                                                       pTributacao.CdVinculo,
                                                       pTributacao.pFolha);
                        
      END IF;
                     
      IF pTributacao.pFolha.NuAnoMesReferencia >= 202408 AND pTpTributacao = CTRIB_TIPO_RRA THEN
         vvlLiquido    := vvlLiquido - FRetornaValorRubrica(pTributacao => pTributacao,
                                                            pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                                            pNuSufixo   => 1);
         vDeExpressao := vDeexpressao || '-ded=' || vvlLiquido;
                                                   
      END IF;
 
      -- Aplicar tabela de faixas para calculo do IRRF

      vDeExpressao := vDeexpressao || ' calc sobre ' || vvlLiquido;
          
      PAplicarAliquotaIRRF (pVlBase => vvlLiquido, pVlNM => vVlNM, pVlDesc => vvlLiquido, pIndiceDesc => vvlIndiceRubrica);            

      vDeExpressao := vDeexpressao || '=' || vvlLiquido;
      
      IF pTpTributacao <> CTRIB_TIPO_RRA THEN
                                          
         vvlLiquido := vvlLiquido - pBase.vlDeduzidoAtual - NVL(vvlDeduzidoOutros, 0);
        
         vDeExpressao := vDeexpressao || '-' || pBase.vlDeduzidoAtual || '-' || NVL(vvlDeduzidoOutros, 0);              
                                                              
      END IF;       

      vCdRubDescIRRFGerada := NULL;
      
      IF NVL(pBase.vlDeduzidoAtual, 0) + NVL(vvlDeduzidoOutros, 0) >= 0 AND vvlLiquido > 0 THEN
                  
         vCdRubDescIRRFGerada := pTributacao.irrf.CdRubAgrupDescIRRF;
                            
      END IF;                          
                     
      -----------------------------------------------------------------------------
      -- Caso seja Tributacao Normal, gera registros para rubricas automaticas
      -- das modalidades 39 e 40
      -----------------------------------------------------------------------------
                     
      IF pTpTributacao IN (CTRIB_TIPO_NORMAL, CTRIB_TIPO_DECTER) THEN
                        
         -- Insere rubrica automatica (Modalidade 39)
                        
         IF vVlBaseOutros > 0 AND vVlBaseAtual > 0 AND
            pbPrima THEN
                           
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pTributacao.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIRRFOutros,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => vVlBaseOutros,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 10);
         END IF;
                        
         -- Insere rubrica automatica (Modalidade 40)
                        
         IF vVlDeduzidoOutros > 0 AND
            vVlBaseAtual > 0 AND
            NOT FRetornaValorRubrica(pTributacao => pTributacao,
                                     pCdRubrica  => PKGPAG_VAR.vgCdRubDeducaoIRRFOutros) = vVlDeduzidoOutros THEN
                           
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pTributacao.CdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubDeducaoIRRFOutros,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => vVlDeduzidoOutros,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 10);
         END IF;
                        
      END IF;
                     
   END IF;
                  
   --
   -- Se possui valor de IR sobre pensao
   --
                  
   IF vVlBaseIRRFPENSAO.vlReal > 0 AND PKGPAG_VAR.bPossuiPensao THEN
 
      PAplicarAliquotaIRRF (pVlBase     => vVlBaseIRRFPENSAO.vlReal,
                            pVlNM       => vVlNM, 
                            pVlDesc     => vVlBaseIRRFPENSAO.vlReal, 
                            pIndiceDesc => vvlIndiceRubrica);
                          
      IF pTpTributacao <> CTRIB_TIPO_RRA THEN                              
         vVlBaseIRRFPENSAO.vlReal := vVlBaseIRRFPENSAO.vlReal - pBase.vlDeduzidoAtual - vvlDeduzidoOutros;
      END IF;
                      
      -- Valor do IR sobre a base da pensao                  
      PAlterarCalculo (pTributacao => pTributacao, pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseIRRFBASEPENSAO, 
                       pNuSufixoRubrica => NULL, pValor => vVlBaseIRRFPENSAO.vlReal);

      -- Base de calculo do IR da pensao
      PAlterarCalculo (pTributacao => pTributacao, pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseIRRFPENSAO, 
                       pNuSufixoRubrica => NULL, pValor => vVlBaseIRRFPENSAO.vlIntegral);
                    
   END IF;
                       
   -- continua
                
   IF vCdRubDescIRRFGerada IN (pTributacao.irrf.CdRubAgrupDifDescIRRF, pTributacao.irrf.CdRubAgrupDevDescIRRF) THEN
            
      vvlLiquido := ABS(vvlLiquido);
            
   END IF;
         
   IF FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => pkgpag_var.vgCdRubBaseIRRF) = 0 THEN

      PApagarCalculo (pTributacao => pTributacao, pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF);
                 
   END IF;
         
   IF FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => pkgpag_var.vgCdRubBaseIRRF13) = 0 THEN

      PApagarCalculo (pTributacao => pTributacao, pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13);

   END IF;
   -- Ate 15/06/2011 -> vvlLiquido > 10.00
   
   pDebug ('Imposto de renda rubrica ' || vCdRubDescIRRFGerada || ' calculado = ' || vvlLiquido);
         

   IF vCdRubDescIRRFGerada IS NOT NULL AND vvlLiquido > 0 THEN

      IF PKGPAG_GERAL.FGeraRubrica(pRubrica => vCdRubDescIRRFGerada) THEN

         
         PApagarCalculo (pTributacao => pTributacao, pCdRubricaAgrupamento => vCdRubDescIRRFGerada);
                
         INSERT INTO EPagHistoricoRubricaVinculo
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
             CdTipoOrigemRubrica,
             CdTipoIndice,
             cdprocessopagretroativo,
             DeExpressao)
         VALUES
            (Spaghistoricorubricavinculo.NEXTVAL,
             pTributacao.pFolha.CdFolhaPagamento,
             vCdRubDescIRRFGerada,
             pTributacao.CdVinculo,
             1,
             NULL,
             vvlLiquido,
             1,
             vvlIndiceRubrica,
             systimestamp,
             10,
             PKGPAG_VAR.vgRubrica(vCdRubDescIRRFGerada).CdTipoIndice,
             vCdProcPagRetro,
             vDeExpressao);
               
         IF pBase.VlDescRubDepJuizo > 0 THEN
                  
            pInsereDepositoEmJuizo(pTributacao,
                                   FRetornaValorRubrica(pTributacao => pTributacao,
                                                        pCdRubrica  => PKGPAG_VAR.vgCdRubBaseIRRF),
                                   vVlLiquido);
                  
         END IF;
               
      END IF;
            
   END IF; 

END;                        
                                              

FUNCTION FPrepararBaseIRRF (pTributacao              IN rTributacao,
                            pTpTributacao            IN INTEGER,
                            pCdTipoTributacaoIRRF    IN INTEGER,
                            pbPrima                  IN BOOLEAN,
                            pIndProcRetro            IN INTEGER)  RETURN rBase IS 

   vVlBloqueioNormal     NUMBER(13, 2);
   vVlBloqueio13         NUMBER(13, 2);   
   vRetorno              NUMBER;
   vVlDescRubIsentaIRRF  NUMBER(13, 2);
   vVlDescRubDepJuizo    NUMBER(13, 2);
   vBase                 rBase;
   
BEGIN
   
   vBase.FlCalcular := 1;
   
   IF pkgpag_fb.FMneSomaRubMesOutrosVinculos(pkgpag_var.vgVinculo.cdpessoa,
                                             PKGPAG_VAR.vgCdRubricaDescDepIRRF,
                                             pTributacao.pfolha) = 0 THEN
   

      IF NOT PKGPAG_TIPO.cnTipoFolhaPagHonor.EXISTS (pTributacao.pFolha.CdTipoFolhaPagamento) THEN
      
         PCriarCalculo (pTributacao           => pTributacao, 
                        pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaDescDepIRRF, 
                        pNuSufixoRubrica      => 01, 
                        pCdTipoOrigemRubrica  => 1,
                        pValor                => pTributacao.irrf.VlDeducaoDependente
                        );
         
      END IF;
      
   END IF;
 
pDebug ('Marcelo: ' || pTributacao.irrf.VlDeducaoInativo);

  
   IF pTributacao.irrf.FlAplicaDeducaoInativo
      AND (NOT pTributacao.irrf.FlIsentoIRRF)
      AND pkgpag_fb.FMneSomaRubMesOutrosVinculos(pkgpag_var.vgVinculo.cdpessoa,
                                                 PKGPAG_VAR.vgCdRubBaseDeducaoInativo,
                                                 pTributacao.pfolha) = 0 THEN


      PAlterarLancamentoVinculo (pCdFolhaPagamento        => pTributacao.pFolha.CdFolhaPagamento,
                                 pCdVinculo               => pTributacao.CdVinculo,
                                 pCdRubricaAgrupamento    => PKGPAG_VAR.vgCdRubBaseDeducaoInativo,
                                 pVlPagamento             => pTributacao.irrf.VlDeducaoInativo);
                 
   END IF;
   
   PAtualizarDeducoesLegaisIRRF(pTributacao   => pTributacao,
                                pTpTributacao => pTpTributacao,
                                pIndProcRetro => pIndProcRetro);


   IF pTributacao.irrf.bDescRubIsentaDescIRRF THEN

      IF PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaAdiant13) THEN 

         UPDATE EPagHistoricoRubricaVinculo HRV
            SET HRV.Cdrubricaagrupamento = pTributacao.irrf.CdRubExigibilidadeSusp
          WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
            AND HRV.CdVinculo = pTributacao.CdVinculo
            AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIRRF13;  

         vBase.FlCalcular := 0;

      ELSE
         --
         -- Solicitacao de Sustentacao #65575
         -- Solicitacao 8130/2016 - SEA - Servidores com decisao judicial para isencao total de IRRF,
         -- porem sem laudo de molestia grave X Geracao da rubrica 09-0943 - DEDUCAO PARA O IRRF
         -- Para quem tem isencao na rubrica 05-0516 altera a base do IRRF para a base 09-0943
         --

         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIRRF,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2);
            
         IF pkgpag_var.vgDeExpressaoBaseIRRF IS NOT NULL AND
            PKGPAG_VAR.vgCdRubExigibilidadeSusp IS NOT NULL THEN

            vRetorno := FValoresSomados (pDeExpressao => pkgpag_var.vgDeExpressaoBaseIRRF);
                       
            vVlBloqueioNormal := FRetornaValorRubrica(pTributacao,pTributacao.rub.CdRubDescBLOQUEIOREM);
            
            vVlBloqueio13     := FRetornaValorRubrica(pTributacao,pTributacao.rub.CdRubDescBLOQUEIOREM13);
            
            UPDATE EPagHistoricoRubricaVinculo HRV
               SET HRV.Cdrubricaagrupamento = pTributacao.irrf.CdRubExigibilidadeSusp,
                   HRV.Vlpagamento          = vRetorno - vVlBloqueioNormal - vVlBloqueio13
             WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pTributacao.CdVinculo
               AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIRRF;

            vBase.FlCalcular := 0;
                  
         END IF;
      END IF;
                        
   END IF;
    
   IF vBase.FlCalcular = 0 THEN
      
      NULL;
      
   ELSIF pTributacao.irrf.FlIsentoIRRF THEN
   
      PApagarCalculo (pTributacao => pTributacao, pCdRubricaAgrupamento => pTributacao.irrf.CdRubBaseIRRF);

      vBase.FlCalcular := 0;
 
   ELSE    

      IF FProcessaBase (pTributacao      => pTributacao,
                        pCdRubrica       => pTributacao.irrf.CdRubBaseIRRF,
                        pTpTributacao    => pTpTributacao,
                        pIndProcRetro    => pIndProcRetro) <= 0 THEN
            
         vBase.FlCalcular := 0;
                        
      ELSE                  
                    
         ----------------------------------------------------------------------------------
         -- Caso possua rubricas que devem ser descontadas da base do IRRF, soma o valor
         -- das rubricas e desconta (ver cursor)
         ----------------------------------------------------------------------------------
               
         vvlDescRubIsentaIRRF := 0;         
         vVlDescRubDepJuizo   := 0;
               
         PKGPAG_VAR.vgVlDeducaoDependOutroVinc := 0;
               
         IF pTributacao.irrf.bDescRubIsentaIRRF THEN
                  
            IF pTpTributacao <> CTRIB_TIPO_FERIAS THEN
                     
               vvlDescRubIsentaIRRF := FRetornaValorRubIsentas(pCdVinculo      => pTributacao.CdVinculo,
                                                               pFolha          => pTributacao.pFolha,
                                                               pCdTipoDesconto => 2);
                     
               vvlDescRubDepJuizo := FRetornaValorRubIsentas(pCdVinculo         => pTributacao.CdVinculo,
                                                             pFolha             => pTributacao.pFolha,
                                                             pCdTipoDesconto    => 2,
                                                             pFlDepositoEmJuizo => 'S');
            ELSE
                     
               vvlDescRubIsentaIRRF := 0;
                     
            END IF;
                  
            IF vvlDescRubIsentaIRRF > 0 AND pbPrima THEN
                     
               PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                     pCdVinculo            => pTributacao.CdVinculo,
                                                     pCdExpressaoFormCalc  => NULL,
                                                     pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubExigibilidadeSusp,
                                                     pNuSufixoRubrica      => 1,
                                                     pVlPagamento          => vvlDescRubIsentaIRRF,
                                                     pVlIndice             => NULL,
                                                     pCdTipoOrigemRubrica  => 10);
                     
            END IF;
                  
         END IF;
            
         vBase := FValoresBaseIRRF (pTributacao           => pTributacao, 
                                    pCdTipoTributacaoIRRF => pCdTipoTributacaoIRRF,
                                    pVlDescRubDepJuizo    => vVlDescRubDepJuizo,
                                    pvlDescRubIsentaIRRF  => vVlDescRubIsentaIRRF);
                   
      END IF;

   END IF;    
                           
   RETURN vBase;
   
END;

PROCEDURE PProcessaTributacaoIRRF(pTributacao       IN OUT NOCOPY rTributacao,
                                  pTpTributacao     IN INTEGER,
                                  pbPrima           IN BOOLEAN,
                                  pIndProcRetro     IN INTEGER DEFAULT NULL) IS

   vBase        rBase;
   vVlBaseIRRF  NUMBER;
   
BEGIN
  
   PKGPAG_GERAL.PLogProcIni('TRI03','Processa Trib IRRF');
    
   pDebug ('Entrando PProcessaTributacaoIRRF para pTpTributacao=' || pTpTributacao);
   
   PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

   -- Prepara os parametros da parametrizacao conforme tipo de tributacao a ser realizada
   
   CASE
    
      WHEN pTpTributacao IN (CTRIB_TIPO_NORMAL, CTRIB_TIPO_RRA) THEN -- Tributacao normal e RRA
         
         pTributacao.irrf.CdRubAgrupDescIRRF      := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF;        
         pTributacao.irrf.CdRubBaseIRRF           := PKGPAG_VAR.vgCdRubBaseIRRF;        
         pTributacao.irrf.CdRubAgrupDifDescIRRF   := PKGPAG_VAR.vgCdRubAgrupDifDescIRRF;         
         pTributacao.irrf.CdRubAgrupDevDescIRRF   := PKGPAG_VAR.vgCdRubAgrupDevDescIRRF;
         pTributacao.irrf.CdRubBaseDeducaoInativo := PKGPAG_VAR.vgCdRubBaseDeducaoInativo;
         pTributacao.irrf.CdRubExigibilidadeSusp  := PKGPAG_VAR.vgCdRubExigibilidadeSusp;
         
      WHEN pTpTributacao = CTRIB_TIPO_DECTER THEN -- Sobre 13
         
         pTributacao.irrf.CdRubAgrupDescIRRF      := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobre13;         
         pTributacao.irrf.CdRubBaseIRRF           := PKGPAG_VAR.vgCdRubBaseIRRF13;        
         pTributacao.irrf.CdRubAgrupDifDescIRRF   := PKGPAG_VAR.vgCdRubAgrupDifDescIRRF13;         
         pTributacao.irrf.CdRubAgrupDevDescIRRF   := PKGPAG_VAR.vgCdRubAgrupDevDescIRRF13;        
         pTributacao.irrf.CdRubBaseDeducaoInativo := PKGPAG_VAR.vgCdRubBaseDeducaoInativo;
         
         pTributacao.irrf.CdRubExigibilidadeSusp  := PKGPAG_VAR.vgCdRubExigibilidadeSusp;
         IF pTributacao.pFolha.CdAgrupamento = 1 AND PKGPAG_VAR.vgCdRubExigibilidadeSusp13 IS NOT NULL THEN
            pTributacao.irrf.CdRubExigibilidadeSusp  := PKGPAG_VAR.vgCdRubExigibilidadeSusp13;            
         END IF;
         
      WHEN pTpTributacao = CTRIB_TIPO_FERIAS THEN -- Sobre Ferias
         
         pTributacao.irrf.CdRubAgrupDescIRRF      := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias;         
         pTributacao.irrf.CdRubBaseIRRF           := PKGPAG_VAR.vgCdRubBaseIRRFFerias;         
         pTributacao.irrf.CdRubAgrupDifDescIRRF   := PKGPAG_VAR.vgCdRubAgrupDifDescIRRFFerias;         
         pTributacao.irrf.CdRubAgrupDevDescIRRF   := PKGPAG_VAR.vgCdRubAgrupDevDescIRRFFerias;         
         pTributacao.irrf.CdRubBaseDeducaoInativo := PKGPAG_VAR.vgCdRubBaseDeducaoInativo;
         pTributacao.irrf.CdRubExigibilidadeSusp  := PKGPAG_VAR.vgCdRubExigibilidadeSusp;
         
   END CASE;


   IF pTributacao.irrf.vlPercentResExterior IS NOT NULL THEN -- Residente fiscal no exterior
 
      --23654/2025 - GEREF - TRIBUTACAO IRRF SERVIDOR RESIDENTE NO EXTERIOR
      --CLAUDEMIR GOMES - 17/09/2025
           
      IF pTributacao.pFolha.CdAgrupamento = CAGR_AGPE THEN
         
         vVlBaseIRRF := FProcessaBase (pTributacao => pTributacao,
                                       pCdRubrica  => pTributacao.irrf.CdRubBaseIRRF);
                                                                                                                                               
      ELSE                           
       
         PKGPAG_GERAL.PAtualizaTotalizadoras(pTributacao.pFolha.CdFolhaPagamento,pTributacao.CdVinculo);
       
         vVlBaseIRRF := PKGPAG_VAR.vgVlTotalProventos;
       
      END IF;    
      
      IF vVlBaseIRRF > 0 THEN
        
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.cdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pTributacao.irrf.CdRubAgrupDescIRRF,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => pTributacao.irrf.vlPercentResExterior * vVlBaseIRRF/100,
                                               pVlIndice             => pTributacao.irrf.vlPercentResExterior,
                                               pCdTipoOrigemRubrica  => 10);
      END IF;
       
   ELSE
      
      IF pTpTributacao = CTRIB_TIPO_RRA THEN -- Tributacao RRA
            
         pTributacao.irrf.vlDeducaoDependente := 0;     
      ELSE
         pTributacao.irrf.vlDeducaoDependente := pTributacao.irrf.NuDependentes * PKGPAG_VAR.vAliquotaIRRF.VlDeducaoDependente;
            
      END IF;   

      pTributacao.irrf.vlDeducaoInativo := 0;
                     
      IF pTpTributacao <> CTRIB_TIPO_RRA AND pTributacao.irrf.FlAplicaDeducaoInativo THEN

         pTributacao.irrf.vlDeducaoInativo := PKGPAG_VAR.vAliquotaIRRF.VlDeducaoInativo;
       
      END IF;      
       
      /* reestruturacao - sem sentido, orginal incluia a rubrica abate 65 anos
pTributacao.irrf.FlAplicaDeducaoInativo 
         AND NOT FIsentoIRRFVinculoApo(pTributacao.CdVinculo, pTributacao.pFolha) 
         AND to_char(pTributacao.pFolha.DtInicioMes, 'YYYYMM') > '202403' THEN
                  
 
      END IF; 
         
      */
      
      PKGPAG_GERAL.PLogProcIni('TRI0302','Preparar Base IRRF');
            
      vBase := FPrepararBaseIRRF(pTributacao            => pTributacao,
                                 pTpTributacao          => pTpTributacao,
                                 pCdTipoTributacaoIRRF  => PKGPAG_VAR.vgParamPagamento.CdTipoTributacaoIRRF,
                                 pbPrima                => pbPrima,
                                 pIndProcRetro          => pIndProcRetro);

      PKGPAG_GERAL.PLogProcFim ('TRI0302');

      IF vBase.FlCalcular = 1 THEN
            
         PKGPAG_GERAL.PLogProcIni ('TRI0303','Pos Calc IRRF');
            
         PPosCalcIRRF (pTributacao             => pTributacao,
                       pTpTributacao           => pTpTributacao,
                       pBase                   => vBase,
                       pbPrima                 => pbPrima,
                       pIndProcRetro           => pIndProcRetro,
                       pVlDeducaoInativoReal   => pTributacao.irrf.vlDeducaoInativoReal            
                       );  
                           
         PKGPAG_GERAL.PLogProcFim('TRI0303');
            
      END IF;
         

   END IF;
   pDebug ('Saindo PProcessaTributacaoIRRF: ' || pTributacao.irrf.vlDeducaoInativoReal);
         
   PKGPAG_GERAL.PLogProcFim('TRI03'); 
                    
   PKGPAG_GERAL.PLogTrace('TRIBUTACAO - Processa Tributação IRRF',
                          NULL,
                          PKGPAG_VAR.vgTmInicio);
   
END;

PROCEDURE P_____________INSS IS
BEGIN
   NULL;
END;

FUNCTION FTetoDescINSS RETURN NUMBER IS
   
   vVlDesc  NUMBER;
 
BEGIN
  
   vVlDesc     := 0;

   FOR i IN 1 .. PKGPAG_VAR.vAliqINSS.lFaixa.COUNT LOOP
      vVlDesc := vVlDesc
                 + TRUNC((PKGPAG_VAR.vAliqINSS.lFaixa(i).vlFinal - PKGPAG_VAR.vAliqINSS.lFaixa(i).vlInicial + 0.01)
                       * PKGPAG_VAR.vAliqINSS.lFaixa(i).VlAliquota / 100 , 2);

   END LOOP;

   RETURN vVlDesc;

END;


FUNCTION FCarregarRecolhimentoTrib (pTributacao IN rTributacao, pTpTributacao IN INTEGER, pTpRecolhimento IN INTEGER) RETURN tRecolhimentoTrib IS
   
   vRecolhimentoTrib     tRecolhimentoTrib;
   vRecolhimentoTribAux  tRecolhimentoTrib; 
   vTabCNPJ              PKGPAG_TIPO.tListaIndVarChar;
   j                     INTEGER;
   vFlForcarAliquota     INTEGER;
   vVlAliqForcada        NUMBER;
    
BEGIN
   

   -- #PENDENTE apenas para comparativo da reestruturacao força aliquota outros orgaos se atualmente é contrib indiv
   
   vVlAliqForcada   := pTributacao.inss.VlALiquotaContribIndiv;
   vFlForcarAliquota := 1;

   -- continuar
   
   vRecolhimentoTrib := tRecolhimentoTrib();
   
   IF pTpTributacao = CTRIB_TIPO_DECTER THEN
      select NuCNPJ,
             NULL as CdVinculo,
             FlRecolhimentoTeto,
             VlBaseRecolhimento,
             VlRecolhimento,
             CASE 
                 WHEN vFlForcarAliquota = 1 THEN vVlAliqForcada
                 WHEN CdCategoriaESocial BETWEEN 700 AND 799 THEN 11 
             END as VlAliquotaUnica
        BULK COLLECT INTO vRecolhimentoTrib
        
           from etrbrecolhimentoavulso13 T
           
          where cdpessoa = pTributacao.CdPessoa
            and FlAnulado = 'N'
            and CdObjetoRecolhimento = pTpRecolhimento
            AND NuAno = pTributacao.pFolha.NuAnoReferencia
            AND (FlRecolhimentoTeto = PKGPAG_TIPO.cnS OR VlRecolhimento > 0)
            AND NuCNPJ IS NOT NULL;
  
   ELSE
     
      select NuCNPJ,
             CdVinculo,
             FlRecolhimentoTeto,
             VlBaseRecolhimento,
             VlRecolhimento,
              CASE 
                 WHEN vFlForcarAliquota = 1 THEN vVlAliqForcada
                 WHEN VlAliquotaUnica IS NOT NULL THEN VlAliquotaUnica
                 WHEN CdCategoriaESocial BETWEEN 700 AND 799 THEN 11 
             END as VlAliquotaUnica

        BULK COLLECT INTO vRecolhimentoTrib
        
           from etrbrecolhimentoavulso T
           
          where cdpessoa = pTributacao.CdPessoa
            and FlAnulado = 'N'
            and CdObjetoRecolhimento = PKGPAG_TIPO.cn1
            AND (NuAnoInicio < pTributacao.pFolha.NuAnoReferencia OR (NuAnoInicio = pTributacao.pFolha.NuAnoReferencia AND NuMesInicio <= pTributacao.pFolha.NuMesReferencia)) 
            AND (NuAnoFim    > pTributacao.pFolha.NuAnoReferencia OR (NuAnoFim    = pTributacao.pFolha.NuAnoReferencia AND NuMesFim    >= pTributacao.pFolha.NuMesReferencia) OR NuAnoFim IS NULL)
            AND (FlRecolhimentoTeto = PKGPAG_TIPO.cnS OR VlRecolhimento > 0 OR VlAliquotaUnica IS NOT NULL)
            AND NuCNPJ IS NOT NULL;

   END IF;   
     
   IF vRecolhimentoTrib.COUNT > 1 THEN
      -- Eliminar duplicidades e orgaos do SIGRH (exemplo ALESC)

      vRecolhimentoTribAux := vRecolhimentoTrib;
      vTabCNPJ.DELETE;
      vRecolhimentoTrib := tRecolhimentoTrib();
      
      FOR t IN vRecolhimentoTribAux.FIRST .. vRecolhimentoTribAux.LAST LOOP
         
         -- despreza orgaos do SIGRH 
         IF pTributacao.inss.orgSIGRH.EXISTS (vRecolhimentoTribAux(t).NUCNPJ) THEN
            CONTINUE;
         END IF;

         IF NOT vTabCNPJ.EXISTS (vRecolhimentoTribAux(t).NUCNPJ) THEN
            
            vRecolhimentoTrib.EXTEND;
            vRecolhimentoTrib(vRecolhimentoTrib.LAST) := vRecolhimentoTribAux(t);
         
            vTabCNPJ(vRecolhimentoTribAux(t).NUCNPJ) := vRecolhimentoTrib.LAST;
         
         ELSE
            -- "Merge" dos dados
            
            j := vTabCNPJ(vRecolhimentoTribAux(t).NUCNPJ);
            
            IF vRecolhimentoTrib(j).CdVinculo IS NULL OR vRecolhimentoTribAux(t).CdVinculo IS NULL THEN
               vRecolhimentoTrib(j).CdVinculo := NULL;
            END IF;

            IF vRecolhimentoTrib(j).FlRecolhimentoTeto = 'S' OR vRecolhimentoTribAux(t).FlRecolhimentoTeto = 'S' THEN
               vRecolhimentoTrib(j).FlRecolhimentoTeto := 'S';
            END IF;

            IF vRecolhimentoTribAux(t).VlBaseRecolhimento IS NOT NULL THEN
                        
               IF vRecolhimentoTrib(j).VlBaseRecolhimento IS NULL THEN
                  vRecolhimentoTrib(j).VlBaseRecolhimento := vRecolhimentoTribAux(t).VlBaseRecolhimento;
               
               ELSIF vRecolhimentoTribAux(t).VlBaseRecolhimento > vRecolhimentoTrib(j).VlBaseRecolhimento THEN
                  vRecolhimentoTrib(j).VlBaseRecolhimento := vRecolhimentoTribAux(t).VlBaseRecolhimento;               
               END IF;
            
            END IF;

            IF vRecolhimentoTribAux(t).VlRecolhimento IS NOT NULL THEN
                        
               IF vRecolhimentoTrib(j).VlRecolhimento IS NULL THEN
                  vRecolhimentoTrib(j).VlRecolhimento := vRecolhimentoTribAux(t).VlRecolhimento;
               
               ELSIF vRecolhimentoTribAux(t).VlRecolhimento > vRecolhimentoTrib(j).VlRecolhimento THEN
                  vRecolhimentoTrib(j).VlRecolhimento := vRecolhimentoTribAux(t).VlRecolhimento;               
               END IF;
            
            END IF;
                                    
            IF vRecolhimentoTribAux(t).VlAliquotaUnica IS NOT NULL THEN
                        
               IF vRecolhimentoTrib(j).VlAliquotaUnica IS NULL THEN
                  vRecolhimentoTrib(j).VlAliquotaUnica := vRecolhimentoTribAux(t).VlAliquotaUnica;
               
               ELSIF vRecolhimentoTribAux(t).VlAliquotaUnica > vRecolhimentoTrib(j).VlAliquotaUnica THEN
                  vRecolhimentoTrib(j).VlAliquotaUnica := vRecolhimentoTribAux(t).VlAliquotaUnica;               
               END IF;
            
            END IF;

         END IF;
         
      END LOOP;     
      
   END IF;
             
   RETURN vRecolhimentoTrib;
   
END;

FUNCTION FTributouTetoINSS (pRecolhimentoTrib IN tRecolhimentoTrib) RETURN INTEGER IS
  
   vFlTributouTeto  INTEGER;
   
BEGIN

   vFlTributouTeto  := 0;

   IF pRecolhimentoTrib.COUNT > 0 THEN
      FOR i IN pRecolhimentoTrib.FIRST .. pRecolhimentoTrib.LAST LOOP
         IF pRecolhimentoTrib(i).FlRecolhimentoTeto = 'S' THEN
            vFlTributouTeto  := 1;
            EXIT;
         END IF;
      END LOOP;
   END IF;
   
   RETURN vFlTributouTeto;
    
END;
 
FUNCTION FTetoDescINSSContribIndiv (pNuAnoReferencia IN INTEGER, pNuMesReferencia IN INTEGER) RETURN NUMBER IS
 
   vVlTetoDescINSSContribIndiv   NUMBER;
     
BEGIN
   
   SELECT NVL(AH.VlTetoContribIndividual,0)
     INTO vVlTetoDescINSSContribIndiv
     FROM ETRBHISTALIQUOTAINSS AH
    WHERE (AH.NUANOINICIO < pNuAnoReferencia OR (AH.NUANOINICIO = pNuAnoReferencia AND AH.NUMESINICIO <= pNuMesReferencia))
      AND (AH.NUANOFINAL  > pNuAnoReferencia OR (AH.NUANOFINAL  = pNuAnoReferencia AND AH.NUMESFINAL  >= pNuMesReferencia) 
           OR AH.NUANOFINAL IS NULL);

   RETURN vVlTetoDescINSSContribIndiv;
           
END;


PROCEDURE PAtualizaBaseINSS (pTributacao IN rTributacao, pFlReprocessar IN INTEGER DEFAULT NULL, pVlBase IN NUMBER DEFAULT NULL) IS

BEGIN

   IF pFlReprocessar = 1 THEN

      PProcessaBase (pTributacao   => pTributacao,
                     pCdRubrica    => pTributacao.calc.inss.CdRubBaseINSS);
        
   END IF;
   
   IF pVlBase IS NOT NULL THEN
      
      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.Vlpagamento = pvlBase
       WHERE HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pTributacao.calc.inss.CdRubBaseINSS;
      
   END IF;
   
   PProcessaBase (pTributacao   => pTributacao,
                  pCdRubrica    => PKGPAG_VAR.vgCdRubVlINSSPatronalBruto);

END;


PROCEDURE PRegistrarTotVariosVinculos (pTributacao IN rTributacao, pFlDecTerceiro IN INTEGER DEFAULT 0) IS
                                       
   vINSSCalculoAnterior    PKGPAG_INSS.tINSSCalculo;     

BEGIN  
        
   vINSSCalculoAnterior := PKGPAG_INSS.FINSSCalculoAnteriores (pINSSControle  => pTributacao.inss.INSSControle,
                                                               pFlDecTerceiro => pFlDecTerceiro,
                                                               pNuAnoMes      => pTributacao.pFolha.NuAnoMesReferencia);
                                                                                                
   IF vINSSCalculoAnterior IS NULL THEN
      RETURN;
   END IF;
   
   FOR c IN vINSSCalculoAnterior.FIRST .. vINSSCalculoAnterior.LAST LOOP  
           
      IF vINSSCalculoAnterior(c).DeDescricao is null THEN -- MESMO VINCULO
         
         CONTINUE;
         
      END IF;         
   
      IF vINSSCalculoAnterior(c).VlBaseCalculo > 0 THEN
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseVariosVincINSS,
                                               pNuSufixoRubrica      => c,
                                               pVlPagamento          => vINSSCalculoAnterior(c).VlBaseCalculo,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10,
                                               pDeExpressao          => vINSSCalculoAnterior(c).DeDescricao
                                               );
         
      END IF;
      
      IF vINSSCalculoAnterior(c).VlINSS > 0 THEN
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pTributacao.rub.CdRubDescVariosVincINSS,
                                               pNuSufixoRubrica      => c,
                                               pVlPagamento          => vINSSCalculoAnterior(c).VlINSS,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10,
                                               pDeExpressao          => vINSSCalculoAnterior(c).DeDescricao
                                               );         
      END IF;                          
      
   END LOOP;                                    
 
END;
 

PROCEDURE PInsereRubricaINSS(pTributacao       IN rTributacao,
                             pVlRubrica        IN NUMBER,
                             pVlIndice         IN NUMBER,
                             pDescricao        IN VARCHAR2) IS
      
   vCdExpressaoFormCalc INTEGER;
   vCdRubricaGerada     INTEGER;
   vVlRubrica           NUMBER;
   vFlLimitou           BOOLEAN;
         
BEGIN

   IF pVlRubrica > 0 THEN
   
      IF PKGPAG_VAR.vgFaseCalculo = PKGPAG_TIPO.cnFaseCalculoIntegral THEN
         
         IF pTributacao.pFolha.CdAgrupamento = CAGR_COHAB 
         AND pTributacao.pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias then
                
            vCdRubricaGerada := pTributacao.rub.CdRubDescINSSFERIAS;
          
         else
      
            vCdRubricaGerada := pTributacao.calc.inss.CdRubDescINSS;
         end if;
         
      ELSE
         vCdRubricaGerada := pTributacao.calc.inss.CdRubDifINSS;
      END IF;
      
   ELSE -- negativa
 
      vCdRubricaGerada := pTributacao.calc.inss.CdRubDevINSS;

   END IF;      

   IF NOT PKGPAG_GERAL.FGeraRubrica(pRubrica => vCdRubricaGerada) THEN
      RETURN;
   END IF;      
       
   vVlRubrica := pVlRubrica;
   
   -- Trava de Seguranca
   
   IF vCdRubricaGerada = pTributacao.calc.inss.CdRubDescINSS THEN
     
      vFlLimitou := FALSE;
   
      IF pTributacao.inss.VlALiquotaContribIndiv IS NULL THEN
         
         IF vVlRubrica > pTributacao.INSS.VlTetoDescINSS THEN
            vVlRubrica := pTributacao.inss.VlTetoDescINSS;
            vFlLimitou := TRUE;
         END IF;
         
      ELSE

         IF vVlRubrica > pTributacao.INSS.VlTetoDescINSSContribIndiv THEN
            vVlRubrica := pTributacao.inss.VlTetoDescINSSContribIndiv;
            vFlLimitou := TRUE;
         END IF;
                  
      END IF;
      
      IF vFlLimitou THEN

         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'Ocorreu Tentativa de Desconto de INSS acima da Valor de Referencia de Teto',
                                 PKGPAG_VAR.vgCdVinculo);
      END IF;
      
   END IF;
                         
   PCriarCalculo (pTributacao           => pTributacao,
                  pCdRubricaAgrupamento => vCdRubricaGerada,
                  pNuSufixoRubrica      => 1,           
                  pCdTipoOrigemRubrica  => 10, 
                  pValor                => ABS(vVlRubrica),
                  pVlIndice             => pVlIndice,
                  pFlForcarIndice       => 1,
                  pDeExpressao          => pDescricao );

             
   -- Se desconto de INSS13 for por formula, reprocessar
   
   IF vCdRubricaGerada = PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13 THEN
      
      IF pkgpag_var.vgCEF.COUNT > 0 THEN
         
         -- Verifica se tem formula
         vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                        pCdRubricaAgrupamento => vCdRubricaGerada,
                                                                        pCdRelacaoVinculo     => pkgpag_var.vgCEF(1).CdRelacaoVinculo);
                  
         IF nvl(vCdExpressaoFormCalc, 0) > 0 THEN
          
            PProcessaRubrica (pTributacao => pTributacao,
                              pCdRubrica  => vCdRubricaGerada);
                        
         END IF;
                  
      END IF;

   END IF;

EXCEPTION
      
   WHEN OTHERS THEN
               
      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Erro ao processar valor INSS: ' ||
                              SQLERRM,
                              PKGPAG_VAR.vgCdVinculo);
      
END;
   
PROCEDURE PObterINSS13Rescisao(pTributacao      IN OUT NOCOPY rTributacao,
                               pVlBaseTodos        OUT NUMBER, 
                               pVlDescTodos        OUT NUMBER) IS
   
    vVlINSS13FolhaCorrente NUMBER;
BEGIN

   -- Indica que a base de desconto total deverá ser alterada por estar considerando o valor da folha corrente,
   -- o que ocorre quanto tem lancamento financeiro de INSS
   
   -- Antes de processar a Base, ver o valor do INSS da folha corrente, que tem valor
   -- quando é lancamento financeiro, mas não tem e não vem na base quando calculado

   vVlINSS13FolhaCorrente := FRetornaValorRubrica (pTributacao => pTributacao,
                                                   pCdRubrica  => pTributacao.calc.inss.CdRubDescINSS);

   PCriarCalculo (pTributacao           => pTributacao, 
                  pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseDESCANUALINSS13,
                  pNuSufixoRubrica      => 1, 
                  pCdTipoOrigemRubrica  => 10, 
                  pValor                => 0,
                  pVlIndice             => NULL,
                  pFlForcarIndice       => 1);

   pVlDescTodos := FProcessaBase (pTributacao => pTributacao,
                                  pCdRubrica  => pTributacao.rub.CdRubBaseDESCANUALINSS13);                                 

   IF vVlINSS13FolhaCorrente <> 0 THEN  
      pVlDescTodos        := pVlDescTodos - vVlINSS13FolhaCorrente;
      
      -- Alterar a base para não ter o valor da rubrica da folha corrente
      
      PAlterarCalculo (pTributacao           => pTributacao,
                       pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseDESCANUALINSS13,
                       pNuSufixoRubrica      => 1, 
                       pValor                => pVlDescTodos);    
      
   END IF;
                                                                        
   PCriarCalculo (pTributacao           => pTributacao, 
                  pCdRubricaAgrupamento => pTributacao.rub.CdRubBaseBASANUALINSS13,
                  pNuSufixoRubrica      => 1, 
                  pCdTipoOrigemRubrica  => 10, 
                  pValor                => 0,
                  pVlIndice             => NULL,
                  pFlForcarIndice       => 1);
        
   pVlBaseTodos := FProcessaBase (pTributacao => pTributacao,
                                  pCdRubrica  => pTributacao.rub.CdRubBaseBASANUALINSS13);
                            
END;

PROCEDURE PCalculosAnterioresINSS (pTributacao   IN OUT NOCOPY rTributacao,
                                   pVlBaseINSS       IN NUMBER
                                   ) IS
 
   vVlBaseOutros           NUMBER;
   vVlDescOutros           NUMBER;
   vDescricao              VARCHAR2(200);
                                
   vTabRubDescINSS         TYPENUMBER;
   vTabRubBaseINSS         TYPENUMBER;
   vTabRubDifINSS          TYPENUMBER;
   vTabRubDevINSS          TYPENUMBER;
   vTabTodas               TYPENUMBER;
   vTabTipoRubrica         PKGPAG_TIPO.tLista; 
   vIdentRubrica           PKGPAG_TIPO.rIdentRubrica; 
   vFlDecTerceiro          INTEGER;
   vVlDescTodos            NUMBER;
   vVlBaseTodos            NUMBER;

   vVlBaseCalculo          NUMBER;
   vVlBaseAcerto           NUMBER;
   vVlINSS                 NUMBER;
   vVlAliquotaContribIndiv NUMBER;
   vVlBaseRecolhimento     NUMBER;
   vVlRecolhimento         NUMBER;
    
   PROCEDURE PConcatenarTabelas IS
      
      PROCEDURE PCarregarItens (pTipoRubrica IN INTEGER, pTab IN TYPENUMBER) IS         
      BEGIN
         IF pTab.COUNT > 0 THEN
            FOR i IN pTab.FIRST .. pTab.LAST LOOP         
               vTabTodas.EXTEND;
               vTabTodas(vTabTodas.LAST) := pTab(i);
               vTabTipoRubrica (pTab(i)) := pTipoRubrica;
            END LOOP;
         END IF;           
      END;
      
      
   BEGIN
      vTabTipoRubrica.DELETE;
      vTabTodas := TYPENUMBER();
      
      PCarregarItens (pTipoRubrica => 1, pTab => vTabRubDescINSS);
      PCarregarItens (pTipoRubrica => 2, pTab => vTabRubBaseINSS);
      PCarregarItens (pTipoRubrica => 3, pTab => vTabRubDifINSS);
      PCarregarItens (pTipoRubrica => 4, pTab => vTabRubDevINSS);  
      
   END;
    
BEGIN
   
   vVlBaseOutros := 0;
   vVlDescOutros := 0;
 
   IF pTributacao.calc.inss.TpTributacao = CTRIB_TIPO_DECTER THEN
      vFlDecTerceiro := 1;
   ELSE
      vFlDecTerceiro := 0;
   END IF;
                                  
   IF pTributacao.calc.inss.recolhimento.COUNT > 0 THEN
      
      FOR r IN pTributacao.calc.inss.recolhimento.FIRST .. pTributacao.calc.inss.recolhimento.LAST LOOP 

         IF pTributacao.calc.inss.recolhimento(r).VlAliquotaUnica IS NOT NULL THEN
            vVlAliquotaContribIndiv := pTributacao.calc.inss.recolhimento(r).VlAliquotaUnica;
         ELSE            
            vVlAliquotaContribIndiv := NULL;
         END IF;
                  
         vVlRecolhimento     := pTributacao.calc.inss.recolhimento(r).VlRecolhimento;
         vVlBaseRecolhimento := pTributacao.calc.inss.recolhimento(r).VlBaseRecolhimento;
                                                         
         IF pTributacao.calc.inss.recolhimento(r).FlRecolhimentoTeto = 'S' THEN
            IF vVlBaseRecolhimento IS NULL THEN
               vVlBaseRecolhimento := PKGPAG_VAR.vAliqINSS.VlTeto;   
            END IF;

            IF vVlRecolhimento IS NULL THEN

               IF vVlAliquotaContribIndiv IS NOT NULL THEN
                  vVlRecolhimento := pTributacao.inss.VlTetoDescINSSContribIndiv;
               ELSE
                  vVlRecolhimento := pTributacao.inss.VlTetoDescINSS;               
               END IF; 
                  
            END IF;
                         
         END IF;
                  
         vVlBaseOutros := vVlBaseOutros + NVL(vVlBaseRecolhimento,0);
         vVlDescOutros := vVlDescOutros + NVL(vVlRecolhimento,0);
         
         vDescricao := 'Rec Avulso CNPJ ' || pTributacao.calc.inss.recolhimento(r).NUCNPJ
                     || ' base = ' || VVlBaseRecolhimento
                     || case when vVlAliquotaContribIndiv IS NOT NULL THEN ' como contrib indiv' end;

         pdebug ('INSS Calculos anteriores: Rec Avulso CNPJ ' || pTributacao.calc.inss.recolhimento(r).NUCNPJ
                     || ' base = ' || VVlBaseRecolhimento
                     || case when vVlAliquotaContribIndiv IS NOT NULL THEN ' como contrib indiv' end);

         PKGPAG_INSS.PDadosAnteriores (pINSSControle           => pTributacao.inss.INSSControle,
                                       pNuAnoMes               => pTributacao.pFolha.NuAnoMesReferencia,
                                       pFlDecTerceiro          => vFlDecTerceiro,
                                       pNuCnpjOrgao            => pTributacao.calc.inss.recolhimento(r).NUCNPJ,
                                       pCdOrgao                => NULL,
                                       pCdVinculo              => NULL,
                                       pCdTipoFolhaPagamento   => NULL,
                                       pCdTipoCalculo          => 1, -- Folha Normal
                                       pVlBaseCalculo          => VVlBaseRecolhimento,
                                       pVlBaseAcerto           => NULL,
                                       pVlINSS                 => vVlRecolhimento,
                                       pVlAliquotaContribIndiv => vVlAliquotaContribIndiv,
                                       pDescricao              => vDescricao );  
      END LOOP;
      
   END IF;
     
   IF pTributacao.calc.inss.TpTributacao = CTRIB_TIPO_DECTER THEN
               
      PObterINSS13Rescisao(pTributacao  => pTributacao,
                           pVlBaseTodos => vVlBaseTodos,
                           pVlDescTodos => vVlDescTodos);
       
      -- registra pago em outros vinculos no ano/ meses anteriores /ano todo
 
      IF pVlBaseINSS <= vVlBaseTodos AND vVlDescTodos >= 0 THEN
                  
         vVlBaseRecolhimento := vVlBaseTodos - pVlBaseINSS;    
         vVlRecolhimento     := vVlDescTodos;
         
         vVlBaseOutros := vVlBaseOutros + vVlBaseRecolhimento;
         vVlDescOutros := vVlDescOutros + vVlRecolhimento;

         vVlAliquotaContribIndiv := pTributacao.inss.VlALiquotaContribIndiv;
          
         PKGPAG_INSS.PDadosAnteriores (pINSSControle           => pTributacao.inss.INSSControle,
                                       pNuAnoMes               => pTributacao.pFolha.NuAnoMesReferencia,
                                       pFlDecTerceiro          => vFlDecTerceiro,
                                       pNuCnpjOrgao            => NULL,
                                       pCdOrgao                => pTributacao.pFolha.CdOrgao,
                                       pCdVinculo              => NULL,
                                       pCdTipoFolhaPagamento   => NULL,
                                       pCdTipoCalculo          => 1, -- Calculo Normal
                                       pVlBaseCalculo          => VVlBaseRecolhimento,
                                       pVlBaseAcerto           => NULL,
                                       pVlINSS                 => vVlRecolhimento,
                                       pVlAliquotaContribIndiv => vVlAliquotaContribIndiv );
                                       
      END IF;                                                               
  
   ELSE

      vTabRubDescINSS := pTributacao.TotRub (vIdentRubrica.cnIndDescINSS);
      vTabRubBaseINSS := pTributacao.TotRub (vIdentRubrica.cnIndRubBaseINSS);
      vTabRubDifINSS  := pTributacao.TotRub (vIdentRubrica.cnIndDifDescINSS);
      vTabRubDevINSS  := pTributacao.TotRub (vIdentRubrica.cnIndDevDescINSS);     

      pConcatenarTabelas;
      
      -- Ver calculos de outros vinculos executados anteriormente
    
      vVlBaseCalculo          := 0;
      vVlBaseAcerto           := 0;
      vVlINSS                 := 0;
      vVlAliquotaContribIndiv := 0;
                                                  
      FOR r IN (  SELECT FP.CdFolhaPagamento,
                         V.CdVinculo,
                         MAX(FPG.CdOrgao) as CdOrgao,
                         MAX(o.SgOrgao) as SgOrgao,
                         LPAD(MAx(nuSeqMatricula),2,'0') as NuSeqMatricula,
                         MAX(FPG.CdTipoFolhaPagamento) as CdTipoFolhaPagamento,
                         MAX(FPG.CdTipoCalculo) as CdTipoCalculo,
                         MAX(FPG.DeOrdemExecucao) as DeOrdemExecFolha,  
                         MAX(CAPA.Vlpercentcontribindiv) as Vlpercentcontribindiv,                    
                         ROW_NUMBER() OVER (PARTITION BY FP.CdFolhaPagamento, V.CdVinculo ORDER BY RV.CdRubricaAgrupamento DESC) As FlUltimo,
                         RV.CdRubricaAgrupamento,

                         NVL(SUM(VLPagamento),0) as VlRubrica
                         
                    FROM ECadVinculo V
                   INNER JOIN ECalFolhaTrib FP
                      ON FP.SGTRIBUTO = PKGPAG_TIPO.cnSgTribINSS
                     AND FP.TPMES = 'M'
                     AND FP.CdCalculoPai = PKGPAG_VAR.vgCalculo.CdCalculoPai
                                      
                     AND EXISTS (SELECT 1 FROM TABLE(pTributacao.FolPermitida)
                                  WHERE FP.CdFolhaPagamento = to_number(column_value) )                    

                   INNER JOIN EPagHistoricoRubricaVinculo RV
                      ON V.CdVinculo = RV.CdVinculo
                     AND FP.CdFolhaPagamento = RV.CdFolhaPagamento
                   
                   INNER JOIN EPAGFolhaPagamento FPG
                      ON FPG.CdFolhaPagamento = FP.CdFolhaPagamento
                   
                   INNER JOIN VCadOrgao o
                      ON o.cdOrgao = fp.cdOrgao
                                        
                    LEFT JOIN EPagCapaHistRubricaVinculo CAPA
                      ON capa.CdFolhaPagamento = RV.cdFolhaPagamento
                     AND capa.CdVinculo = RV.CdVinculo 
                          
                   INNER JOIN TABLE (vTabTodas) T
                      ON T.column_value = RV.CdRubricaAgrupamento
                              
                   WHERE V.CdPessoa = pTributacao.CdPessoa
                     AND (pTributacao.cdVinculo <> v.CdVinculo OR FP.CdFolhaPagamento <> pTributacao.pFolha.CdFolhaPagamento)
                   
                   GROUP BY FP.CdFolhaPagamento, v.CdVinculo, RV.CdRubricaAgrupamento
                   ORDER BY DeOrdemExecFolha, FP.CdFolhaPagamento, v.CdVinculo, RV.CdRubricaAgrupamento) LOOP
    
         IF pTributacao.calc.inss.tpTributacao = CTRIB_TIPO_DECTER THEN
            vFlDecTerceiro := 1;
         ELSE
            vFlDecTerceiro := 0;      
         END IF;
                
         CASE vTabTipoRubrica (r.CdRubricaAgrupamento)
            WHEN 1 THEN -- DescINSS
               vVlINSS                 := vVlINSS + r.VlRubrica;            
            WHEN 2 THEN -- BaseINSS
               vVlBaseCalculo          := vVlBaseCalculo + r.VlRubrica;
            WHEN 3 THEN -- DifINSS
               vVlINSS                 := vVlINSS + r.VlRubrica;               
            WHEN 4 THEN -- DevINSS
               vVlINSS                 := vVlINSS - r.VlRubrica;
         END CASE;        
    
         IF r.FlUltimo = 1 THEN
            
            IF pTributacao.CdVinculo = r.CdVinculo THEN
               vDescricao := NULL;
               vVlAliquotaContribIndiv := pTributacao.inss.VlALiquotaContribIndiv;
            ELSE                        
               vDescricao := 'Vinc ' || r.sgorgao
                        || ' Seq.  ' || r.NuSeqMatricula 
                        || case when vVlAliquotaContribIndiv IS NOT NULL THEN ' como contrib indiv' end;

               vVlAliquotaContribIndiv := r.Vlpercentcontribindiv;
            END IF;

            pdebug ('INSS Calculos anteriores: Folhas anteriores org ' || r.cdorgao
                        || ' base= ' || vVlBaseCalculo 
                        || case when vVlAliquotaContribIndiv IS NOT NULL THEN ' como contrib indiv' end);
       
            PKGPAG_INSS.PDadosAnteriores (pINSSControle           => pTributacao.inss.INSSControle,
                                          pNuAnoMes               => pTributacao.pFolha.NuAnoMesReferencia,
                                          pFlDecTerceiro          => vFlDecTerceiro,
                                          pNuCNPJOrgao            => NULL,
                                          pCdOrgao                => r.cdorgao,
                                          pCdVinculo              => r.cdvinculo,
                                          pCdTipoFolhaPagamento   => r.CdTipoFolhaPagamento,
                                          pCdTipoCalculo          => r.CdTipoCalculo,
                                          pVlBaseCalculo          => vVlBaseCalculo,
                                          pVlBaseAcerto           => vVlBaseAcerto,
                                          pVlINSS                 => vVlINSS,
                                          pVlAliquotaContribIndiv => vVlAliquotaContribIndiv,
                                          pDescricao              => vDescricao);  

            vVlBaseOutros := vVlBaseOutros + vVlBaseCalculo;
            vVlDescOutros := vVlDescOutros + vVlINSS;

            vVlBaseCalculo          := 0;
            vVlBaseAcerto           := 0;
            vVlINSS                 := 0;
            vVlAliquotaContribIndiv := 0;

         END IF;
         
      END LOOP;
                                         
   END IF;
    
   -- Registrar valores considerados de outras folhas/vinculos

   IF pTributacao.calc.inss.recolhimento.COUNT > 0 
      OR vVlDescOutros > 0 OR vVlBaseOutros > 0 THEN

      pkgpag_var.bPossuiDuploVinculoAno := FALSE; -- Tratar porque FB usa
 
      IF pTributacao.calc.inss.TpTributacao <> CTRIB_TIPO_DECTER THEN
         PRegistrarTotVariosVinculos (pTributacao   => pTributacao);
      END IF;
   END IF;    

END;
  
PROCEDURE PCalculoValoresINSS (pTributacao  IN OUT NOCOPY rTributacao,
                               pFlRecalculo            IN INTEGER,
                               pVlBaseINSS            OUT NUMBER,
                               pVlINSS                OUT NUMBER,
                               pVlIndice              OUT NUMBER,
                               pVlBaseAcerto          OUT NUMBER,
                               pDescricao             OUT VARCHAR2) IS
  
   vINSSCalculo          PKGPAG_INSS.rINSSCalculo;
   vFlDecTerceiro        INTEGER;
   vvlDescRubIsentaINSS  NUMBER(15, 4);
   
BEGIN
  
   pVlIndice := 0;

   -- Caso possua rubricas que devem ser descontadas da base do INSS, soma o valor
   -- das rubricas e desconta (ver cursor)
            
   vvlDescRubIsentaINSS := 0;
            
   IF pTributacao.inss.bDescRubIsentaINSS THEN
               
      vvlDescRubIsentaINSS := FRetornaValorRubIsentas(pCdVinculo      => pTributacao.CdVinculo,
                                                      pFolha          => pTributacao.pFolha,
                                                      pCdTipoDesconto => 1);                                                   
   END IF;
   
   IF pTributacao.calc.inss.tpTributacao = CTRIB_TIPO_DECTER THEN
      vFlDecTerceiro := 1;
   ELSE
      vFlDecTerceiro := 0;      
   END IF;

   pVlBaseAcerto  := 0;
                            
   -- Carregar calculos anteriores

   pVlBaseINSS := FRetornaValorRubrica(pTributacao => pTributacao,
                                       pCdRubrica  => pTributacao.calc.inss.CdRubBaseINSS);

   pDescricao := 'Base ' || pVlBaseINSS;
   
   IF vvlDescRubIsentaINSS <> 0 THEN

       pDebug ('vvlDescRubIsentaINSS = ' || vvlDescRubIsentaINSS);
      
       pVlBaseINSS := pVlBaseINSS - vvlDescRubIsentaINSS;

       pDescricao := pDescricao || '- Isen ' || vvlDescRubIsentaINSS || '=' || pVlBaseINSS;
   
   END IF;
   

   IF pVlBaseINSS < 0 THEN
      pVlBaseINSS := 0;
   END IF;
   
   IF vvlDescRubIsentaINSS > 0 THEN
      
      -- atualizar a base do inss sendo calculado
      
      PAtualizaBaseINSS (pTributacao => pTributacao, pVlBase => pVlBaseINSS);
   
   END IF;
     
   PCalculosAnterioresINSS (pTributacao   => pTributacao,
                            pVlBaseINSS   => pVlBaseINSS);

   
   IF PKGPAG_INSS.FINSSCalculoAnteriores (pINSSControle  => pTributacao.inss.INSSControle,
                                          pFlDecTerceiro => vFlDecTerceiro,
                                          pNuAnoMes      => pTributacao.pFolha.NuAnoMesReferencia).count = 0 -- não tem calculos anteriores
                                          
      AND pVlBaseINSS = 0 THEN
          
      RETURN;
 
   END IF;
                             
   vINSSCalculo := PKGPAG_INSS.FCalcular (pINSSControle            => pTributacao.inss.INSSControle,
                                          pNuAnoMes                => pTributacao.pFolha.NuAnoMesReferencia,
                                          pFlDecTerceiro           => vFlDecTerceiro,
                                          pCdOrgao                 => pTributacao.pFolha.cdorgao,
                                          pCdVinculo               => pTributacao.CdVinculo,
                                          pCdTipoFolhaPagamento    => pTributacao.pFolha.CdTipoFolhaPagamento,    
                                          pCdTipoCalculo           => pTributacao.pFolha.CdTipoCalculo,                
                                          pVlBaseCalculo           => pVlBaseINSS,
                                          pVlALiquotaContribIndiv  => pTributacao.inss.VlALiquotaContribIndiv);

    
   pVlINSS        := vINSSCalculo.VlINSS;
   pVlIndice      := vINSSCalculo.NuPercentFaixa;
   pVlBaseAcerto  := vINSSCalculo.VlBaseAcerto; 
   IF vINSSCalculo.VlDif <> 0 THEN
      pDescricao := pDescricao || ' desc tem dif outr (' || vINSSCalculo.VlDif || ')';
   END IF;

END;
 
FUNCTION FEhContribIndiv RETURN INTEGER IS

   vFlContribuinteIndividual   INTEGER;

BEGIN

   IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelResidente THEN
          
      vFlContribuinteIndividual := 1;
      
   ELSE 

      -- CIASC SIG-2169 Aliquota de INSS de conselheiros
      -- CIASC SIG-8752 Contribuicao Previdenciaria Diretor (individual) Relacao trabalho = 13
      IF (PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento in (15, 13) AND PKGPAG_var.vgFolha.CdOrgao = CORG_CIASC)
      OR (PKGPAG_VAR.vgVinculo.cdregimetrabalho = 6 AND PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> 19)
         -- contribuinte individual (diretores não empregados do regime previdenciário 1 - regime geral(INSS)
      OR (PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 15 AND PKGPAG_var.vgFolha.CdOrgao = CORG_COHAB) THEN

         vFlContribuinteIndividual := 1;

      ELSIF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento IN (15, 19) THEN

         vFlContribuinteIndividual := 1;

      ELSE

         vFlContribuinteIndividual := 0;

      END IF;
         
   END IF;


dbms_output.put_line ('reltrab = == ' ||  PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento || ' result=' ||vFlContribuinteIndividual);
        
   RETURN vFlContribuinteIndividual;
   
END;

PROCEDURE PCalculaINSS(pTributacao IN OUT NOCOPY rTributacao,
                       pTpTributacao   IN INTEGER) IS
 
   vVlBaseINSS          NUMBER;
   vVlINSS              NUMBER;
   vVlBaseAcerto        NUMBER;
   vVlBaseOutros        NUMBER;
   vVlDescOutros        NUMBER;
   vVlIndice            NUMBER;
   vDescricao           VARCHAR2(200);
       
BEGIN
 
   PDebug ('PCalculaINSS');
   
   pTributacao.calc.inss.tpTributacao := pTpTributacao;
     
   IF NOT pTpTributacao IN (CTRIB_TIPO_NORMAL,CTRIB_TIPO_DECTER) THEN
      PDebug ('PCalculaINSS Saiu porque pTpTributacao = ' || pTpTributacao);
      RETURN;
   END IF;
   
   IF PKGPAG_TIPO.cnTipoFolhaPagHonor13.EXISTS (pTributacao.pFolha.CdTipoFolha) OR
      PKGPAG_TIPO.cnTipoFolhaPagHonor.EXISTS (pTributacao.pFolha.CdTipoFolhaPagamento) THEN
   PDebug (' PCalculaINSS saiu por causa dos honorarios');
      RETURN;
   END IF;    

   PDebug ('Continua PCalculaINSS');

   -- Exclusao de Rubricas que não devem existir
   
   IF pTributacao.pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 THEN
      
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => pTributacao.rub.CdRubDescINSS,
                                  pFlExcluiAmbos    => 'S');
   END IF;

   -- Exclui bases de IPESC
            
   PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                               pCdVinculo        => pTributacao.CdVinculo,
                               pCdRubrica        => PKGPAG_VAR.vgCdRubBaseIPESC,
                               pFlExcluiAmbos    => 'S');
            
   PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                               pCdVinculo        => pTributacao.CdVinculo,
                               pCdRubrica        => PKGPAG_VAR.vgCdRubBaseIPESC13,
                               pFlExcluiAmbos    => 'S');
                                  
   --- 
   
   pTributacao.calc.inss.recolhimento := FCarregarRecolhimentoTrib (pTributacao => pTributacao, pTpTributacao => pTpTributacao, pTpRecolhimento => 1); -- INSS
   
 --  IF FTributouTetoINSS (pRecolhimentoTrib => pTributacao.calc.inss.recolhimento) = 1 THEN 
 --     RETURN;
 --  END IF; 
  
   IF pTpTributacao = CTRIB_TIPO_DECTER THEN -- Sobre 13
 
      pTributacao.calc.inss.CdRubDescINSS  := pTributacao.inss.CdRubAgrupDescINSS13;
      pTributacao.calc.inss.CdRubBaseINSS  := pTributacao.inss.CdRubSalBaseINSS13;
      pTributacao.calc.inss.CdRubDifINSS   := pTributacao.inss.CdRubAgrupDifDescINSS13;
      pTributacao.calc.inss.CdRubDevINSS   := pTributacao.inss.CdRubAgrupDevDescINSS13;         
         
   ELSE
      
      pTributacao.calc.inss.CdRubDescINSS  := pTributacao.inss.CdRubAgrupDescINSS;
      pTributacao.calc.inss.CdRubBaseINSS  := pTributacao.inss.CdRubSalBaseINSS;
      pTributacao.calc.inss.CdRubDifINSS   := pTributacao.inss.CdRubAgrupDifDescINSS;
      pTributacao.calc.inss.CdRubDevINSS   := pTributacao.inss.CdRubAgrupDevDescINSS;         
      
   END IF;
     
   IF PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pTributacao.calc.inss.CdRubDescINSS,
                                           pNuSufixoRubrica      => 1) THEN   
      RETURN; -- Manter o valor já lançado
      
   END IF;
   
   PKGPAG_GERAL.PLogProcIni('TRI02','Processa Trib INSS');

   pDebug ('Antes teste existencia base');
   
   IF FExisteRubrica (pTributacao => pTributacao, pCdRubrica => pTributacao.calc.inss.CdRubBaseINSS) = 1 THEN
      PKGPAG_GERAL.PLogProcIni('TRI0201','Processa Trib INSS - Base Existe'); 
      PKGPAG_GERAL.PLogProcFim('TRI0201');
   ELSE   
      PKGPAG_GERAL.PLogProcIni('TRI0202','Processa Trib INSS - Base Não Existe');            
      PKGPAG_GERAL.PLogProcFim('TRI0202');
   END IF;
  
   IF FExisteRubrica (pTributacao => pTributacao, pCdRubrica => pTributacao.calc.inss.CdRubDescINSS) = 1 THEN
      PKGPAG_GERAL.PLogProcIni('TRI0203','Processa Trib INSS - Desc Existe'); 
      PKGPAG_GERAL.PLogProcFim('TRI0203');
   ELSE   
      PKGPAG_GERAL.PLogProcIni('TRI0204','Processa Trib INSS - Desc Não Existe');            
      PKGPAG_GERAL.PLogProcFim('TRI0204');
   END IF;
   
   PKGPAG_INSS.PNovaPessoa (pINSSControle => pTributacao.inss.inssControle);

   pDebug ('Antes cria base inss');
   
   PCriarCalculo (pTributacao           => pTributacao, 
                  pCdRubricaAgrupamento => pTributacao.calc.inss.CdRubBaseINSS,
                  pNuSufixoRubrica      => 1,            
                  pCdTipoOrigemRubrica  => 1, 
                  pValor                => 0);
          
   -- REPROCESSA BASE INSS
   
   pDebug ('Antes processa base inss');
   
   PAtualizaBaseINSS (pTributacao => pTributacao, pFlReprocessar => 1); 

   pDebug ('Depois processa base inss');
                           
   /*------------------------------------------------------------------------------------------------*/
   -- Atualiza as bases de patronais de INSS (CLT e Estatutario) pois as ferias
   -- incidem sobre estas bases
   /*------------------------------------------------------------------------------------------------*/
      
   IF PKGPAG_VAR.vgCdRubricaBaseINSSPat IS NOT NULL
     -- EPAGRI - Excecao
      AND NOT (PKGPAG_VAR.vgFolha.CdOrgao = CORG_EPAGRI AND
       PKGPAG_VAR.bVinculoComCCO = FALSE) THEN
         
      PProcessaBase (pTributacao   => pTributacao,
                     pCdRubrica    => PKGPAG_VAR.vgCdRubricaBaseINSSPat);
         
   END IF;

pdebug ('Vai testar se processa o INSSCLT');
      
   IF PKGPAG_VAR.vgCdRubBaseINSSCLT IS NOT NULL AND
      NOT (PKGPAG_VAR.vgFolha.CdOrgao = CORG_EPAGRI AND
       PKGPAG_VAR.bVinculoComCCO = TRUE) THEN
   -- EPAGRI somente para efetivos
         
      PProcessaBase (pTributacao   => pTributacao,
                     pCdRubrica    => PKGPAG_VAR.vgCdRubBaseINSSCLT);
pdebug ('Processou o INSSCLT');
         
   END IF;
      
   IF PKGPAG_VAR.vgFolha.cdorgao = CORG_CLTIMETRO THEN
         
      -- Trata 09-1666
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubVlINSSPatronalBruto,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);
         
      PProcessaBase (pTributacao   => pTributacao,
                     pCdRubrica    => PKGPAG_VAR.vgCdRubVlINSSPatronalBruto);

         
   END IF;
      
   IF PKGPAG_VAR.vgCdRubBaseProv13PatINSS IS NOT NULL THEN
         
      PProcessaBase (pTributacao   => pTributacao,
                     pCdRubrica    => PKGPAG_VAR.vgCdRubBaseProv13PatINSS);
         
   END IF;
      
   IF PKGPAG_VAR.vgCdRubBaseProv13PatINSSCLT IS NOT NULL THEN
         
      PProcessaBase (pTributacao   => pTributacao,
                     pCdRubrica    => PKGPAG_VAR.vgCdRubBaseProv13PatINSSCLT);
         
   END IF;
              
   IF pTributacao.pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias AND
       PKGPAG_VAR.vgParamPagamento.FlGeraINSSFolhaFerias <> PKGPAG_TIPO.cnS THEN
   PDebug (' PCalculaINSS saiu por causa das ferias');
   
      RETURN;
   END IF; 
                    
   -- Calculo do Desconto de INSS
 
   IF pTpTributacao = CTRIB_TIPO_DECTER 
      OR NOT (pkgpag_var.vMotAfast.inTipoAfastamento = 'D' AND
              pkgpag_var.vMotAfast.InAfastado = 'M' 
              AND pTpTributacao = CTRIB_TIPO_DECTER
              ) THEN

                            
      PCalculoValoresINSS (pTributacao     => pTributacao, 
                           pFlRecalculo    => CASE pTributacao.pFolha.CdTipoCalculo
                                                 WHEN 3 THEN
                                                    1
                                                 ELSE
                                                    0
                                              END,
                           pVlBaseINSS     => vVlBaseINSS,                  
                           pVlINSS         => vVlINSS,
                           pVlIndice       => vVlIndice,
                           pVlBaseAcerto   => vVlBaseAcerto,
                           pDescricao      => vDescricao);

pDebug ('Tributacao -> ' || pTpTributacao || ' Base INSS -> ' || vVlBaseINSS || ', Desc INSS -> ' || vVlINSS);
                                  
   END IF;           
            
   -- Acertos

/*
   pDebug ('CINSS: Agrupamento =' || pTributacao.pFolha.CdAgrupamento);
   pDebug ('CINSS: tipo Folha  =' ||pkgpag_var.vgFolha.CdTipoFolha);
   pDebug ('CINSS: vl inss     =' || vVlINSS);
   pDebug ('CINSS: rub 05-0516 =' || pTributacao.rub.CdRubDescINSSFERIAS);
                               
 
   IF pTributacao.pFolha.CdAgrupamento = CAGR_COHAB 
      AND pkgpag_var.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias 
      AND vVlINSS > 0 THEN
               
      UPDATE epaghistoricorubricavinculo hrv
         SET hrv.cdrubricaagrupamento = pTributacao.rub.CdRubDescINSSFERIAS
       WHERE hrv.cdrubricaagrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescInss
         AND hrv.cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
         AND hrv.cdfolhapagamento = pkgpag_var.vgFolha.CdFolhaPagamento;
               
   END IF;
*/            
   IF PKGPAG_VAR.vgVinculo.CdRegimeTrabalho = PKGPAG_TIPO.cnRegTrabCLT THEN

      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubricaBaseINSSPat,
                                  pFlExcluiAmbos    => 'S');
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                  pFlExcluiAmbos    => 'S');
   ELSE

pdebug ('Excluiu o INSSCLT');
                                                 
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSSCLT,
                                  pFlExcluiAmbos    => 'S');
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseProv13PatINSS,
                                  pFlExcluiAmbos    => 'S');
            
   END IF;
         
   IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario IN (3, 4) OR
      pTributacao.pFolha.CdTipoFolha IN  (PKGPAG_TIPO.cnTpFolhaResidente,PKGPAG_TIPO.cnTpFolhaResidente13) THEN

      -- SEM CONTRIBUICAO OU REGIME PROPRIO DE OUTROS ESTADOS
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseFGTS,
                                  pFlExcluiAmbos    => 'S');
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseFGTS13,
                                  pFlExcluiAmbos    => 'S');
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubVlFGTS,
                                  pFlExcluiAmbos    => 'S');
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                  pFlExcluiAmbos    => 'S');
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubVlFGTS13,
                                  pFlExcluiAmbos    => 'S');
  
pdebug ('excluiu de novo o inssclt');
          
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSSCLT,
                                  pFlExcluiAmbos    => 'S');
            
      PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pTributacao.CdVinculo,
                                  pCdRubrica        => PKGPAG_VAR.vgCdRubBaseProv13PatINSS,
                                  pFlExcluiAmbos    => 'S');
            
      -- NAO DEVE GERAR 09-1005 PARA APOSENTADO NA FOLHA DE 13 SALARIO
      -- #78490
      IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 AND
         PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = PKGPAG_TIPO.cnSitPrevAposentado AND
         PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = 3 THEN -- SEM CONTRIBUICAO PREVIDENCIARIA
               
         PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSS13,
                                     pFlExcluiAmbos    => 'S');
               
      END IF;
            
      IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = 4 THEN
               
         PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => PKGPAG_VAR.vgCdRubricaBaseINSSPat,
                                     pFlExcluiAmbos    => 'S');
               
         PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSS,
                                     pFlExcluiAmbos    => 'S');
               
         PKGPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento,
                                     pCdVinculo        => pTributacao.CdVinculo,
                                     pCdRubrica        => PKGPAG_VAR.vgCdRubBaseINSS13,
                                     pFlExcluiAmbos    => 'S');
               
      END IF;
            
   END IF;

   -- Registrar valor calculado
 
   IF vVlINSS > 0 THEN

      PInsereRubricaINSS(pTributacao  => pTributacao,
                         pVlRubrica   => vVlINSS,
                         pVlIndice    => vVlIndice,
                         pDescricao   => vDescricao);
                                                

   END IF;
      
   PKGPAG_GERAL.PLogProcFim('TRI02');
   
END;

PROCEDURE P_____________RotinaPrincipal IS
BEGIN
   NULL;
END;

PROCEDURE PProcessaTributacaoPrev(pTributacao IN OUT NOCOPY rTributacao,
                                  pTpTributacao   IN INTEGER,
                                  pbPrima         IN BOOLEAN DEFAULT FALSE) IS
       
BEGIN
   
   PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

   CASE pTributacao.TipoPrev
      
      WHEN CPREV_INSS THEN
         
         PCalculaINSS  (pTributacao   => pTributacao, 
                        pTpTributacao => pTpTributacao);
                  
      WHEN CPREV_IPREV THEN
 
         PCalculaIPREV (pTributacao   => pTributacao,
                        pTpTributacao => pTpTributacao,                  
                        pbPrima       => pbPrima);
                         
      WHEN CPREV_CPSM THEN

         IF pTpTributacao = CTRIB_TIPO_NORMAL THEN

            PCalculaCPSM  (pTributacao   => pTributacao);  
        
         ELSIF pTpTributacao = CTRIB_TIPO_DECTER           
            AND pTributacao.pFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaAdiant13, PKGPAG_TIPO.cnTpFolha13) OR
               (pTributacao.pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
                      FRetornaValorRubrica(pTributacao => pTributacao,
                                          pCdRubrica  => pTributacao.rub.CdRubProvRESC13) > 0) THEN
      
            pCalculaCPSM13(pTributacao => pTributacao);
            
         END IF;     
  
      ELSE
         NULL;
   END CASE;
 
   PKGPAG_GERAL.PLogTrace('TRIBUTACAO - Processa Tributação Prev',
                          NULL,
                          PKGPAG_VAR.vgTmInicio);
   
END;


PROCEDURE PSelecionarPrev (pTributacao IN OUT NOCOPY rTributacao) IS
   
BEGIN
   
   pTributacao.TipoPrev := NULL;
 
   -- Verificar quais previdencias deverão ser calculadas

   IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = PKGPAG_TIPO.cnRegPrevProprio THEN
      
      pTributacao.TipoPrev := CPREV_IPREV;
      pTributacao.iprev.FlCpsmParaIprev := 0;    
   
   ELSIF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = PKGPAG_TIPO.cnRegPrevCPSM THEN

      -- Possui liminar revertendo CPSM para IPREV
 
      pTributacao.iprev.FlCpsmParaIprev := pkgpag_fb.fmnepossuidecjudicial(pTributacao.CdVinculo,
                                                                           PKGPAG_VAR.vgParamPagamento.Cdrubagrupdesciprevliminar,
                                                                           pTributacao.pFolha.NuMesReferencia,
                                                                           pTributacao.pFolha.NuAnoReferencia);
                                                                               
      IF pTributacao.iprev.FlCpsmParaIprev = 1 THEN
            
         pTributacao.TipoPrev := CPREV_IPREV;

      ELSE
         
         pTributacao.TipoPrev := CPREV_CPSM;
 
      END IF;
   
   ELSIF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = PKGPAG_TIPO.cnRegPrevGeral 
         OR PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelResidente THEN

         pTributacao.TipoPrev := CPREV_INSS;

   END IF;
   
END;

FUNCTION FParamIPREV (pTributacao IN rTributacao) RETURN rTribIPREV IS

   vTribIPREV  rTribIPREV;  
BEGIN
   
   vTribIPREV := pTributacao.IPREV;

   vTribIPREV.CdRubBaseIprev    := PKGPAG_VAR.vgCdRubBaseIpesc;
   vTribIPREV.CdRubBaseIprev13  := PKGPAG_VAR.vgCdRubBaseIpesc13;
        
   vTribIPREV.CdRubAgrupDescSCFuturo13 := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescSCFuturo13,
                                                                   pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDesconto);
            
   vTribIPREV.CdRubAgrupDifSCFuturo13 := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescSCFuturo13,
                                                                  pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDifDesc);
            
   vTribIPREV.CdRubAgrupDevSCFuturo13 := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                                  pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescSCFuturo13,
                                                                  pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDevDesc);
                                                                                                                                      
   IF PKGPAG_GERAL.FRetornaRegimeProprioPrev(pTributacao.CdVinculo) = 3 THEN
            
      vTribIPREV.CdRubAgrupDescIprev2008 := PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun2016;
            
      vTribIPREV.CdRubAgrupDescIprev     := PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun2016;
            
      vTribIPREV.CdRubAgrupDifDesc := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                               pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDifDesc);
          
      vTribIPREV.CdRubAgrupDifDesc2008 := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                                   pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDifDesc);
                                                                            
            
      vTribIPREV.CdRubAgrupDevDesc := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                               pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDevDesc);
           
      vTribIPREV.CdRubAgrupDevDesc2008 := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                                   pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDevDesc);

      vTribIPREV.CdRubAgrupDescIprev200813 := PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun1613;
            
      vTribIPREV.CdRubAgrupDescIprev13 := PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIprevJun1613;

            
   ELSIF PKGPAG_GERAL.FRetornaRegimeProprioPrev(pTributacao.CdVinculo) = 4 THEN
            
      vTribIPREV.CdRubAgrupDescIprev2008 := PKGPAG_VAR.vgParamPagamento.Cdrubagrupdescscfuturo;
            
      vTribIPREV.CdRubAgrupDescIprev     := PKGPAG_VAR.vgParamPagamento.Cdrubagrupdescscfuturo;
            
      vTribIPREV.CdRubAgrupDifDesc := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.Cdrubagrupdescscfuturo,
                                                               pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDifDesc);
            
      vTribIPREV.CdRubAgrupDifDesc2008 := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.Cdrubagrupdescscfuturo,
                                                                   pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDifDesc);
            
      vTribIPREV.CdRubAgrupDevDesc := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.Cdrubagrupdescscfuturo,
                                                               pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDevDesc);
            
      vTribIPREV.CdRubAgrupDevDesc2008 := FRetornaRubricaOutroTipo(pTributacao           => pTributacao,
                                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgParamPagamento.Cdrubagrupdescscfuturo,
                                                                   pCdTipoRubrica        => PKGPAG_TIPO.cnTpRubDevDesc);
            

      vTribIPREV.CdRubAgrupDescIprev200813 := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIpescJul200813;
            
      vTribIPREV.CdRubAgrupDescIprev13     := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIpescSobre13;

   ELSE
            
      vTribIPREV.CdRubAgrupDescIprev2008   := PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIpescJul2008;            
      vTribIPREV.CdRubAgrupDescIprev       := PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIpesc;            
      vTribIPREV.CdRubAgrupDifDesc         := PKGPAG_VAR.vgCdRubAgrupDifDescIpesc;           
      vTribIPREV.CdRubAgrupDifDesc2008     := PKGPAG_VAR.vgCdRubAgrupDifDescIpesc2008;            
      vTribIPREV.CdRubAgrupDevDesc         := PKGPAG_VAR.vgCdRubAgrupDevDescIpesc;           
      vTribIPREV.CdRubAgrupDevDesc2008     := PKGPAG_VAR.vgCdRubAgrupDevDescIpesc2008; 
      vTribIPREV.CdRubAgrupDescIprev200813 := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIpescJul200813;           
      vTribIPREV.CdRubAgrupDescIprev13     := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIpescSobre13;
                       
   END IF;
   

   IF pTributacao.iprev.FlCpsmParaIprev = 1 THEN
   
      vTribIPREV.CdRubAgrupDescIprev   := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIprevLiminar;
      vTribIPREV.CdRubAgrupDescIprev13 := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIprevLiminar13;
   END IF;
 
   RETURN vTribIPREV;
   
END;

FUNCTION FParamINSS (pTributacao IN rTributacao) RETURN rTribINSS IS
   vTribINSS  rTribINSS; 
   
   FUNCTION FVlALiquotaContribIndiv (pCdVinculo IN INTEGER, pNuAnoReferencia IN INTEGER, pNuMesReferencia IN INTEGER) RETURN NUMBER IS
    
      VVlAliquotaUnica    NUMBER;  
      
   BEGIN
    
      select NVL(MAX(VlAliquotaUnica), CASE WHEN max(CdCategoriaESocial) BETWEEN 700 AND 799 THEN 11 END)
        INTO VVlAliquotaUnica
        from etrbrecolhimentoavulso T           
       where FlAnulado = 'N'
         and CdObjetoRecolhimento = PKGPAG_TIPO.cn1
         and T.CdVinculo = pCdVinculo
         AND (NuAnoInicio < pNuAnoReferencia OR (NuAnoInicio = pNuAnoReferencia AND NuMesInicio <= pNuMesReferencia)) 
         AND (NuAnoFim    > pNuAnoReferencia OR (NuAnoFim    = pNuAnoReferencia AND NuMesFim    >= pNuMesReferencia) OR NuAnoFim IS NULL)
         AND VlAliquotaUnica IS NOT NULL;

      RETURN VVlAliquotaUnica;
      
   END;
  
BEGIN
   
   vTribINSS := pTributacao.inss;

   vTribINSS.VlALiquotaContribIndiv  := FVlALiquotaContribIndiv (pCdVinculo       => pTributacao.CdVinculo,
                                                                 pNuAnoReferencia => pTributacao.pFolha.NuAnoReferencia,
                                                                 pNuMesReferencia => pTributacao.pFolha.NuMesReferencia);
 
   IF vTribINSS.VlALiquotaContribIndiv IS NULL THEN
      IF FEhContribIndiv = 1 THEN
         vTribINSS.VlALiquotaContribIndiv  := PKGPAG_VAR.vAliqINSS.Vlaliqcontribindividual;

      END IF;
   END IF;
   
   RETURN vTribINSS;
   
END;

FUNCTION FInicializaINSS (pTributacao IN rTributacao) RETURN rTribINSS IS
   vTribINSS  rTribINSS;  
BEGIN
   
   vTribINSS := pTributacao.inss;

   vTribINSS.CdRubAgrupDescINSS      := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescINSS;         
   vTribINSS.CdRubSalBaseINSS        := PKGPAG_VAR.vgCdRubBaseINSS;        
   vTribINSS.CdRubAgrupDifDescINSS   := PKGPAG_VAR.vgCdRubAgrupDifDescINSS;         
   vTribINSS.CdRubAgrupDevDescINSS   := PKGPAG_VAR.vgCdRubAgrupDevDescINSS;  
   
   vTribINSS.CdRubAgrupDescINSS13    := PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13;        
   vTribINSS.CdRubSalBaseINSS13      := PKGPAG_VAR.vgCdRubBaseINSS13;         
   vTribINSS.CdRubAgrupDifDescINSS13 := PKGPAG_VAR.vgCdRubAgrupDifDescINSS13;         
   vTribINSS.CdRubAgrupDevDescINSS13 := PKGPAG_VAR.vgCdRubAgrupDevDescINSS13;  

   RETURN vTribINSS;
   
END;


FUNCTION FNumeroDependentesAnt(pCdAgrupamento IN INTEGER,
                               pCdPessoa      IN INTEGER,
                               pCdVinculo     IN INTEGER,
                               pDtInicioMes   IN DATE,
                               pDtFimMes      IN DATE) RETURN INTEGER IS

 vCont         INTEGER DEFAULT 0;
 vCdDependente INTEGER DEFAULT 0;

BEGIN

 FOR vDependente IN (SELECT DI.CdDependenteVinculoIRRF,
                            D.CdDependente,
                            D.NmDependente,
                            DtNascimento,
                            DI.DtFimDependencia,
                            DI.FlEstudante,
                            D.FlInvalidez,
                            GP.FlFinalizaDependenciaIRRF,
                            GP.FlPensaoVitalicia
                       FROM ECadDependenteVinculo DV
                      INNER JOIN ECadDependenteVinculoIRRF DI
                         ON DV.CdDependenteVinculo =
                            DI.CdDependenteVinculo
                      INNER JOIN ECadPessoaDependente PD
                         ON PD.CdDependente = DV.CdDependente
                      INNER JOIN ECadDependente D
                         ON D.CdDependente = PD.CdDependente
                      INNER JOIN ECadGrauParentescoprevfin GP
                         ON GP.CdGrauParentescoPrevFin =
                            PD.CdGrauParentescoPrevFin

                      INNER JOIN ECadVinculo V
                         ON V.CdVinculo = dv.CdVinculo

                      WHERE PD.CdResponsavel = pCdPessoa
                        AND DI.DtInicioDependencia <= pDtFimMes
                        AND (DI.DtFimdependencia >= pDtInicioMes OR
                            DI.DtFimDependencia IS NULL)
                        AND V.Cdvinculo = pCdVinculo
                        AND V.CdPessoa = PD.CdResponsavel
                        AND NOT EXISTS
                      (SELECT 1
                               FROM EAfaRegistroObito RO
                              WHERE RO.CdDependente = DV.CdDependente
                                AND RO.FlAnulado = PKGPAG_TIPO.cnN)
                        AND EXISTS
                      (SELECT 1
                               FROM ecadvinculo v
                              INNER JOIN ecadorgao o
                                 ON v.cdorgao = o.cdorgao
                              WHERE v.cdvinculo = DV.CdVinculo
                                AND (v.dtDesligamento >= pDtInicioMes OR
                                    v.dtdesligamento IS NULL)
                                AND o.cdagrupamento = pCdAgrupamento)

                      ORDER BY D.CdDependente

                     )

  LOOP

   IF vCdDependente <> vDependente.Cddependente THEN
     vCont         := vCont + 1;
     vCdDependente := vDependente.Cddependente;
   END IF;

 END LOOP;

 RETURN vCont;

END;

--23654/2025 - GEREF - TRIBUTACAO IRRF SERVIDOR RESIDENTE NO EXTERIOR
--CLAUDEMIR GOMES - 18/08/2025

FUNCTION FVerificaResidenteExterior 
 RETURN BOOLEAN IS
    
 vResitenteExterior VARCHAR2(1);
    
BEGIN
    
   SELECT 'S' INTO vResitenteExterior
     FROM ecadvinculo v
    INNER JOIN ecadpessoa p
       ON p.cdpessoa = v.cdpessoa
    INNER JOIN ecadendereco e
       ON e.cdendereco = p.cdendereco
    WHERE flenderecoexterior = 'S'
      AND v.dtdesligamento IS NULL
      AND v.cdpessoa = PKGPAG_VAR.vCdPessoa
      AND ROWNUM = 1;
    
   RETURN TRUE;
    
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      
      RETURN FALSE;
      
END;

FUNCTION FRetornaAliquotaIRRFExterior (pNuAnoMesReferencia IN INTEGER) RETURN NUMBER IS
   vVlAliquota   NUMBER;
BEGIN

   SELECT MAX(vlparametro) as VlAliquota
     INTO vVlAliquota
     FROM esegparametro
    WHERE cdparametro = 372; -- Código Indice de tributação IRRF para residente no exterior

   RETURN vVlAliquota;
    
END;

FUNCTION FParamIRRF (pTributacao  IN rTributacao) RETURN rTribIRRF IS
   vTribIRRF        rTribIRRF;   
   
   TYPE tlstDep     IS TABLE OF PLS_INTEGER
      INDEX BY VARCHAR2(200);
      
   vLstDep          tLstDep; 
   vChaveDep        VARCHAR2(200);  

   FUNCTION FIsentoIRRF(pCdVinculo IN INTEGER,
                        pFolha     IN PKGPAG_TIPO.rFolha)
      
    RETURN BOOLEAN IS
      
      vCont INTEGER;
      
   BEGIN
      
      IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelPesquisador THEN
         
         RETURN TRUE;
         
      ELSE
         
         SELECT 1
           INTO vCont
           FROM ETrbIsencaoIRRF IR
          INNER JOIN ETrbHistIsencaoIRRF HIR
             ON IR.CdIsencaoIRRF = HIR.CdIsencaoIRRF
          WHERE IR.CdVinculo = pCdVinculo
            AND HIR.FlAnulado = PKGPAG_TIPO.cnN
            AND ((HIR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                (HIR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                HIR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
                (HIR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                (HIR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                HIR.NuMesFimVigencia > pFolha.NuMesReferencia) OR
                HIR.NuAnoFimVigencia IS NULL));
         
         RETURN TRUE;
         
      END IF;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         RETURN FALSE;
         
      WHEN TOO_MANY_ROWS THEN
         
         RETURN TRUE;
         
   END;
  
   /*-----------------------------------------------------------------------------------------/
      Objetivo: Retorna TRUE caso a pessoa possua relacao de vinculo de
                pensao previdenciaria, pensao nao previdenciaria ou
                auxilio reclusao, seja aposentado e possua mais de 65 anos no dia 1 do
                mes de processamento.
         
   /*-----------------------------------------------------------------------------------------*/
   FUNCTION FAplicaDeducaoInativo(pDtFimMes IN DATE) RETURN BOOLEAN IS
      
   BEGIN
      
      IF MONTHS_BETWEEN(pDtFimMes, PKGPAG_VAR.vgVinculo.DtNascimento) >= PKGPAG_TIPO.cnMesesIdadeApo 
         AND PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria IN (2, 4, 9) THEN
         
         RETURN TRUE;
         
      ELSE
         
         RETURN FALSE;
         
      END IF;
      
   EXCEPTION
      
      WHEN OTHERS THEN
         
         RETURN FALSE;
         
   END;

BEGIN
   
   vTribIRRF := pTributacao.irrf;
  
   vTribIRRF.FlIsentoIRRF := FIsentoIRRF (pCdVinculo => pTributacao.CdVinculo, pFolha => pTributacao.pFolha);

   vTribIRRF.dep := tTribDependente();

   vTribIRRF.vlDeducaoDependente  := 0;
   
   IF FVerificaResidenteExterior THEN
      vTribIRRF.vlPercentResExterior := FRetornaAliquotaIRRFExterior (pNuAnoMesReferencia => pTributacao.pFolha.NuAnoMesReferencia);      
   ELSE
      vTribIRRF.vlPercentResExterior := NULL;
   END IF;
   
   vTribIRRF.FlAplicaDeducaoInativo  := FAplicaDeducaoInativo(pDtFimMes => pTributacao.pFolha.DtFimMes);
   
   vTribIRRF.FlPermiteDescSimpl   :=  CASE WHEN PKGPAG_GERAL.FAgrupUtilizaDescSimp(pCdAgrupamento => pTributacao.pFolha.CdAgrupamento,
                                                                                   pNuAnoMesFolha => pTributacao.pFolha.NuAnoMesReferencia
                                                                                   ) THEN
                                              1
                                           ELSE
                                              0
                                      END;                                      


   vLstDep.DELETE;

/*   

   #PENDENTE

   FOR vDependente IN (SELECT DI.CdDependenteVinculoIRRF,
                              D.CdDependente,
                              D.NmDependente,
                              DtNascimento,
                              DI.DtFimDependencia,
                              DI.FlEstudante,
                              D.FlInvalidez,
                              GP.FlFinalizaDependenciaIRRF,
                              GP.FlPensaoVitalicia,
                              d.Nucpf,
                              o.cdAgrupamento
                         FROM ECadDependenteVinculo DV
                        INNER JOIN ECadDependenteVinculoIRRF DI
                           ON DV.CdDependenteVinculo = DI.CdDependenteVinculo
                        INNER JOIN ECadPessoaDependente PD
                           ON PD.CdDependente = DV.CdDependente
                        INNER JOIN ECadDependente D
                           ON D.CdDependente = PD.CdDependente
                        INNER JOIN ECadGrauParentescoprevfin GP
                           ON GP.CdGrauParentescoPrevFin = PD.CdGrauParentescoPrevFin
                          
                        INNER JOIN ECadVinculo V
                           ON V.CdVinculo = dv.CdVinculo
                           
                        INNER JOIN VCadOrgao o
                           ON o.CdOrgao = v.CdOrgao   
 
                         LEFT JOIN EAfaRegistroObito RO
                           ON RO.CdDependente = DV.CdDependente
                          AND RO.FlAnulado = PKGPAG_TIPO.cnN
                         
                        WHERE PD.CdResponsavel = pTributacao.CdPessoa
                          AND DI.DtInicioDependencia <= pTributacao.pFolha.DtFimMes
                          AND (DI.DtFimdependencia >= pTributacao.pFolha.DtInicioMes OR DI.DtFimDependencia IS NULL)                             
                          AND (ro.DtObito IS NULL OR ro.DtObito >= pTributacao.pFolha.DtInicioMes) 
                              
                          -- será por pessoa dentro do agrupamento AND V.Cdvinculo = pTributacao.CdVinculo
                          AND o.cdagrupamento = pTributacao.pFolha.CdAgrupamento
                          AND V.CdPessoa = PD.CdResponsavel
                          AND ( V.CdVinculo = pTributacao.CdVinculo
                                OR ( v.dtAdmissao <= pTributacao.pFolha.DtFimMes
                                     AND (v.dtDesligamento >= pTributacao.pFolha.DtInicioMes OR v.dtdesligamento IS NULL)
                                   )
                               )
                          
                        ORDER BY D.CdDependente
                          
                       )
      
   LOOP
             
      vChaveDep := to_char(vDependente.dtNascimento,'YYYYMMDD') || vDependente.nmdependente;
            
      IF NOT vLstDep.EXISTS (vChaveDep) THEN
         vTribIRRF.dep.EXTEND;
         vLstDep(vChaveDep) := vTribIRRF.dep.LAST;       
         vTribIRRF.dep ( vLstDep(vChaveDep) ) := NULL;
         vTribIRRF.dep ( vLstDep(vChaveDep) ).vlSaldoDeducao := PKGPAG_VAR.vAliquotaIRRF.VlDeducaoDependente;

      END IF;

      IF vTribIRRF.dep ( vLstDep(vChaveDep) ).NuCPF IS NULL THEN
         vTribIRRF.dep ( vLstDep(vChaveDep) ).NuCPF          := vDependente.NuCPF;
      END IF;
           
      IF vDependente.cdagrupamento = pTributacao.pFolha.CdAgrupamento 
         AND vDependente.FlInvalidez = 'N' THEN
         
         IF vDependente.FlFinalizaDependenciaIRRF = 'S' AND
            vDependente.FlPensaoVitalicia = 'N' AND
            ((MONTHS_BETWEEN(pTributacao.pFolha.DtFimMes, vDependente.DtNascimento) >
            21 * 12 AND -- 21 anos NAO estudante
            vDependente.FlEstudante = 'N') OR
            ((MONTHS_BETWEEN(pTributacao.pFolha.DtFimMes, vDependente.DtNascimento) >
            25 * 12 AND -- 25 anos estudante
            vDependente.FlEstudante = 'S'))) AND
            vDependente.DtFimDependencia IS NULL THEN
            
            UPDATE ECadDependenteVinculoIRRF DV
               SET DV.DtFimDependencia = pTributacao.pFolha.DtFimMes,
                   DV.DtUltAlteracao   = SYSTIMESTAMP
             WHERE DV.CdDependenteVinculoIRRF = vDependente.CdDependenteVinculoIRRF;
            
            PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                    pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                    pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                    pDeLog                   => 'Finalização de dependência de IRRF : ' ||
                                                                vDependente.NmDependente,
                                    pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                    pCdTipoOcorrencia        => 2, -- Ocorrencia
                                    pCdMotivoOcorrencia      => 7); -- Finalizacao de dependencia de IRRF

         END IF;
         
      END IF;
            
   END LOOP;
 
   vTribIRRF.NuDependentes        := vTribIRRF.dep.COUNT;
*/

   vTribIRRF.NuDependentes := FNumeroDependentesAnt(pCdAgrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                    pCdPessoa      => pTributacao.cdPessoa,
                                                    pCdVinculo     => pTributacao.cdVinculo,
                                                    pDtInicioMes   => pTributacao.pFolha.DtInicioMes,
                                                    pDtFimMes      => pTributacao.pFolha.DtFimMes);
  
   vTribIRRF.vlDeducaoDependente  := vTribIRRF.NuDependentes * PKGPAG_VAR.vAliquotaIRRF.VlDeducaoDependente;
 
   vTribIRRF.vlDescSimp           := PKGPAG_PARAM.FValorReferencia('DESCSIMPL');
 
   RETURN vTribIRRF;

END;


PROCEDURE PBuscarRubricaIsenta (pTributacao IN OUT NOCOPY rTributacao) IS 
    
   vNuIsentaRubIRRF     INTEGER;   
   vNuIsentaRubINSS     INTEGER;   
   vNuIsentaRubIPREV    INTEGER;   
   vNuIsentaRubDescIRRF INTEGER;
   
BEGIN

   pTributacao.inss.bDescRubIsentaINSS     := FALSE;     
   pTributacao.irrf.bDescRubIsentaIRRF     := FALSE;      
   pTributacao.iprev.bDescRubIsentaIPREV   := FALSE;       
   pTributacao.irrf.bDescRubIsentaDescIRRF := FALSE;
  
   -- Caso possua seta as variaveis  pTributacao.irrf.bDescRubIsentaIRRF, pTributacao.inss.bDescRubIsentaINSS, pTributacao.iprev.bDescRubIsentaIPREV que
   -- indicarao se e necessario somar os valores destas rubricas para descontar das bases
   
   SELECT SUM(CASE
                 WHEN TR.FlRubricaIsentaIRRF = 'S' THEN
                  1
                 ELSE
                  0
              END),
          SUM(CASE
                 WHEN TR.FlRubricaIsentaINSS = 'S' THEN
                  1
                 ELSE
                  0
              END),
          SUM(CASE
                 WHEN TR.FlRubricaIsentaIPESC = 'S' THEN
                  1
                 ELSE
                  0
              END),
          SUM(CASE
                 WHEN tr.cdrubricaagrupamento =
                      PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF AND
                      TR.FlRubricaIsentaIRRF = 'S' THEN
                  1
                 ELSE
                  0
              END)
     INTO vNuIsentaRubIRRF,
          vNuIsentaRubINSS,
          vNuIsentaRubIPREV,
          vNuIsentaRubDescIRRF
     FROM ETrbIsencaoRubrica TR
    INNER JOIN ETrbHistIsencaoRubrica HTR
       ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
    WHERE TR.CdVinculo = pTributacao.CdVinculo
      AND ((HTR.NuAnoInicioVigencia < pTributacao.pFolha.NuAnoReferencia OR
          (HTR.NuAnoInicioVigencia = pTributacao.pFolha.NuAnoReferencia AND
          HTR.NuMesInicioVigencia <= pTributacao.pFolha.NuMesReferencia)) AND
          (HTR.NuAnoFimVigencia > pTributacao.pFolha.NuAnoReferencia OR
          (HTR.NuAnoFimVigencia = pTributacao.pFolha.NuAnoReferencia AND
          HTR.NuMesFimVigencia >= pTributacao.pFolha.NuMesReferencia) OR
          HTR.NuMesFimVigencia IS NULL));
   
   IF vNuIsentaRubIRRF > 0 THEN
      
      pTributacao.irrf.bDescRubIsentaIRRF := TRUE;
      
   END IF;
   
   IF vNuIsentaRubINSS > 0 THEN
      
      pTributacao.inss.bDescRubIsentaINSS := TRUE;
      
   END IF;
   
   IF vNuIsentaRubIPREV > 0 THEN
      
      pTributacao.iprev.bDescRubIsentaIPREV := TRUE;
      
   END IF;
   
   IF vNuIsentaRubDescIRRF > 0 THEN
      
      pTributacao.irrf.bDescRubIsentaDescIRRF := TRUE;
      
   END IF;
   
EXCEPTION
   
   WHEN NO_DATA_FOUND THEN
      
      NULL;
      
   WHEN OTHERS THEN
      
      NULL;
      
END;

/*-----------------------------------------------------------------------------------------/
  Procedure  : PProcessaTributacao IRRF e Prev
      
    Objetivo : Realizar a tributacao a ser paga pelo vinculo que esta processado. As
               tributacoes envolvidas sao as de INSS, IRRF e IPREV/IPESC
      
   Nota: parametro pTpCalculo adicionado em 14/07/2009
      
         1 - Todas as tributacoes
         2 - Apenas IRRF
      
         parametro pTpTributacao
      
         1 - Tributacao Normal
         2 - Tributacao de 13
         3 - Tributacao de ferias
         4 - RRA
/-----------------------------------------------------------------------------------------*/

PROCEDURE PApagarConsignacao (pCdFolhaPagamento       IN INTEGER, 
                              pCdVinculo              IN INTEGER, 
                              pTabRubricaConsig       IN PKGPAG_TIPO.tLista) IS

   vCdRubricaAgrupamento   INTEGER;
BEGIN
   
   vCdRubricaAgrupamento := pTabRubricaConsig.FIRST;
   
   WHILE vCdRubricaAgrupamento IS NOT NULL LOOP

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = vCdRubricaAgrupamento
         AND HRV.CdLancamentoFinanceiro IS NULL;
         
      vCdRubricaAgrupamento := pTabRubricaConsig.NEXT(vCdRubricaAgrupamento);
   
   END LOOP;
   
END;
                                
PROCEDURE PCalcularConsignacao (pFolha                  IN PKGPAG_TIPO.rFolha, 
                                pCdVinculo              IN INTEGER, 
                                pCdRubricaAgrupamento   IN INTEGER,
                                pTabRubricaSentenca IN OUT PKGPAG_TIPO.tLista, 
                                pTabRubricaConsig   IN OUT PKGPAG_TIPO.tLista) IS
  
   vCdExpressaoFormCalc      INTEGER;
   vCdEstruturaCarreira      INTEGER;
   vTabRubricaConsigInterno  PKGPAG_TIPO.tLista;

BEGIN
  
   IF pTabRubricaSentenca.EXISTS (pCdRubricaAgrupamento) THEN -- rubricas de consignacao da rubrica da sentenca ja calculadas
      RETURN;
   END IF;
         
   pTabRubricaSentenca(pCdRubricaAgrupamento) := 1; -- Foi tratada

   IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN
                  
      vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;
                  
   END IF;
             
   FOR vRub IN (SELECT pag133.cdrubricaagrupamento
                  FROM EPAGFORMCALCBLOCOEXPRUBAGRUP PAG126
                 INNER JOIN epagrubricaagrupamento pag133
                    ON pag126.cdrubricaagrupamento =
                       pag133.cdrubricaagrupamento
                   AND pag133.flconsignacao = 'S'
                 INNER JOIN epagformulacalcblocoexpressao pag127
                    ON pag126.cdformulacalcblocoexpressao =
                       pag127.cdformulacalcblocoexpressao
                 INNER JOIN epagformulacalculobloco pag128
                    ON pag127.cdformulacalculobloco =
                       pag128.cdformulacalculobloco
                 INNER JOIN epagexpressaoformcalc pag129
                    ON pag128.cdexpressaoformcalc =
                       pag129.cdexpressaoformcalc
                 INNER JOIN epaghistformulacalculo pag130
                    ON pag129.cdhistformulacalculo =
                       pag130.cdhistformulacalculo
                 INNER JOIN epagformulaversao pag131
                    ON pag130.cdformulaversao =
                       pag131.cdformulaversao
                 INNER JOIN epagformulacalculo pag132
                    ON pag131.cdformulacalculo =
                       pag132.cdformulacalculo
                 WHERE pag130.nuanofim IS NULL
                   AND pag132.cdrubricaagrupamento = pCdrubricaagrupamento) LOOP 
   
      vTabRubricaConsigInterno := pTabRubricaConsig;
   
      FOR vBasesConsignacao IN (  --Procura as consignacoes associadas a rubrica agrupamento e insere na VbaseConsignacao
                  SELECT BC.CdBaseConsignacao,
                         BC.NuSufixo,
                         BC.VlIndice,
                         BC.VlmensalContratado
                    FROM EPagBaseConsignacao BC
                   INNER JOIN EPagConsignacao C
                      ON BC.CdConsignacao = C.CdConsignacao
                   INNER JOIN EPAGRUBRICAAGRUPAMENTO EPR
                      ON EPR.CDRUBRICA = C.CDRUBRICA
                   INNER JOIN EPagHistConsignacao HC
                      ON C.CdConsignacao = HC.CdConsignacao
                   WHERE CdVinculo = pCdVinculo
                     AND EPR.CDRUBRICAAGRUPAMENTO = vRub.Cdrubricaagrupamento
                     AND ((BC.NuAnoReferenciaInicial < pFolha.NuAnoReferencia OR
                         (BC.NuAnoReferenciaInicial = pFolha.NuAnoReferencia AND
                         (BC.NuMesReferenciaInicial <=
                         pFolha.NuMesReferencia))) AND
                         ((BC.NuAnoReferenciaFinal > pFolha.NuAnoReferencia OR
                         (BC.NuAnoReferenciaFinal = pFolha.NuAnoReferencia AND
                         BC.NuMesReferenciaFinal >= pFolha.NuMesReferencia) OR
                         BC.NuMesReferenciaFinal IS NULL)))
                     AND BC.DtCancelamento IS NULL
                     AND (HC.DtInicioVigencia <= pFolha.DtCalculo AND
                         (HC.DtFimVigencia >= pFolha.DtCalculo OR
                         HC.DtFimVigencia IS NULL))
                     AND BC.FlRegistroAtual = PKGPAG_TIPO.cnS) LOOP
           
      --Para cada cdConsignacao encontrado verifica se ha uma formula associada ou um valor cadastrado.
      --Caso exista, desconta este valor da pensao alimenticia.
                   
         IF pTabRubricaConsig.EXISTS (vRub.CdRubricaAgrupamento) THEN -- se consignacao já calculada           
            CONTINUE;
         END IF;
         
         vTabRubricaConsigInterno (vRub.CdRubricaAgrupamento) := 1; -- indica que foi calculada

         
         vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                        pCdRubricaAgrupamento => vRub.Cdrubricaagrupamento,
                                                                        pCdRelacaoVinculo     => 0,
                                                                        pCdEstruturaCarreira  => vCdEstruturaCarreira);                        
  
         --- Calcular rubricas de consignac?o que fazem parte da formula da pens?o.
         --- Trecho copiado do pacote PKGPAG_CNS porque n?o da para chamar isoladamente
         --- o calculo de uma rubrica com passagem de parametros.
         --- Se o vinculo possuir cargo efetivo, busca formula por Carreira
                          
         --adiciona a formula
         
         FOR rec IN (SELECT 'Não poderia existir' 
                       FROM epaghistoricorubricavinculo rv
                      WHERE rv.cdvinculo = pCdVinculo
                        AND rv.cdfolhapagamento = pFolha.CdFolhaPagamento
                        AND rv.cdrubricaagrupamento = vRub.CdRubricaAgrupamento
                        AND rv.cdbaseconsignacao = vBasesConsignacao.CdBaseConsignacao
                        AND ROWNUM <= 1) LOOP
                        
            PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                    PKGPAG_VAR.vCdHistParamCalc,
                                    PKGPAG_VAR.vCdPessoa,
                                    'Erro ao processar Consignacao para Pensão: Não poderia existir HRV',
                                    PKGPAG_VAR.vgCdVinculo);               
                         
         END LOOP;
           
         IF vCdExpressaoFormCalc <> 0 THEN
                  
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pCdVinculo,
                                                  pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                  pCdRubricaAgrupamento => vRub.Cdrubricaagrupamento,
                                                  pNuSufixoRubrica      => vBasesConsignacao.NuSufixo,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => vBasesConsignacao.VlIndice,
                                                  pCdBaseConsignacao    => vBasesConsignacao.CdBaseConsignacao,
                                                  pCdTipoOrigemRubrica  => 14);
                  
            PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                             pCdVinculo       => pCdVinculo,
                                             pCdRubrica       => vRub.Cdrubricaagrupamento,
                                             pTpProcessamento => 1,
                                             pTpLocal         => 2);
            
         ELSE --adiciona o valor
                                   
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                  pCdVinculo            => pCdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => vRub.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica      => vBasesConsignacao.NuSufixo,
                                                  pVlPagamento          => vBasesConsignacao.VlmensalContratado,
                                                  pVlIndice             => 100,
                                                  pNuParcelas           => NULL,
                                                  pCdBaseConsignacao    => vBasesConsignacao.CdBaseConsignacao,
                                                  pCdTipoOrigemRubrica  => 14);

         END IF;
               
      END LOOP;
                
      pTabRubricaConsig := vTabRubricaConsigInterno;  
       
   END LOOP;

END;

PROCEDURE PPensaoAlimCalc (pTributacao     IN OUT NOCOPY rTributacao,
                           pCdRubBaseIRRF      IN INTEGER,
                           pCdRubAgrupDescIRRF IN INTEGER,
                           pTpTributacao       IN INTEGER,
                           pIndProcRetro       IN INTEGER,
                           pTabSentenca        IN tSentenca                         
                           ) IS

   vVlPensao                 NUMBER(13, 2);
   vvlIRRF                   NUMBER(13, 2);
   vFlCalculando13           BOOLEAN;
   vValorIRRFAnterior        NUMBER;
   vValorPensaoAnterior      NUMBER;
   vMaxTentativa             INTEGER;
   vLstExpressaoIRRF         TYPENUMBER;
   vLstRubricaSentenca       TYPENUMBER;
     
   FUNCTION FLstExpressaoIRRF RETURN TYPENUMBER IS     
      vCdBaseCalculo  INTEGER;             
      vLstExpressao   TYPENUMBER;
   BEGIN
      
      vLstExpressao := TYPENUMBER();

      vCdBaseCalculo := PKGPAG_VAR.vgRubrica(pCdRubBaseIRRF).CdBaseCalculo;
                 
      FOR i IN PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco.FIRST .. PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco.LAST LOOP
         
         FOR j IN PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao.FIRST .. PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao.LAST LOOP
            
            CASE PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao(j).CdTipoMneumonico
               
               WHEN 4 THEN      
                  vLstExpressao.EXTEND;
                  vLstExpressao(vLstExpressao.LAST) := PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao(j).CdExpressao;
               ELSE               
                  NULL;                  
            END CASE;            
         END LOOP;        
      END LOOP;
      
      RETURN vLstExpressao;
      
   END;

   PROCEDURE PCalcularSentenca (pSentenca IN rSentenca) IS
      vFlInserirLancamento   BOOLEAN;
      vSentenca              rSentenca;
   BEGIN
             
      vFlInserirLancamento := TRUE;

      IF pSentenca.CdExpressaoFormCalc IS NULL THEN 
         
         IF FRetornaValorRubrica(pTributacao => pTributacao,
                                 pCdRubrica  => pSentenca.CdRubricaAgrupamento,
                                 pNuSufixo   => pSentenca.NuSequencial) > 0 THEN

            vFlInserirLancamento := FALSE;
                           
            UPDATE EPagHistoricoRubricaVinculo HRV
               SET HRV.VlPagamento            = pSentenca.VlFixo,
                   HRV.Cdhistsentencajudicial = pSentenca.Cdhistsentencajudicial
             WHERE HRV.CdFolhapagamento = pTributacao.pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pTributacao.CdVinculo
               AND HRV.CdRubricaAgrupamento = pSentenca.CdRubricaAgrupamento
               AND HRV.Nusufixorubrica = pSentenca.NuSequencial
               AND hrv.cdtipoorigemrubrica != 2; -- nao atualiza se a rubrica for de LF;
        
         END IF;
             
      ELSE
         NULL;
               
      END IF;
         
      IF vFlInserirLancamento THEN      
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo              => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc    => pSentenca.CdExpressaoFormCalc,
                                               pCdRubricaAgrupamento   => pSentenca.CdRubricaAgrupamento,
                                               pNuSufixoRubrica        => pSentenca.NuSequencial,
                                               pVlPagamento            => CASE
                                                                            WHEN pSentenca.CdExpressaoFormCalc IS NULL THEN
                                                                               pSentenca.VlFixo
                                                                            ELSE
                                                                               0
                                                                            END,
                                               pVlIndice               => CASE
                                                                            WHEN pSentenca.CdExpressaoFormCalc IS NULL THEN
                                                                               NULL
                                                                            ELSE
                                                                               pSentenca.VlPercentPensao
                                                                          END,
                                               pCdProcessoPagRetroativo => CASE
                                                                            --WHEN pSentenca.CdExpressaoFormCalc IS NULL THEN
                                                                            --   NULL
                                                                            WHEN pTpTributacao <> CTRIB_TIPO_RRA THEN
                                                                               NULL
                                                                            ELSE
                                                                               PKGPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo
                                                                            END,
                                                                                                                                                                                                      
                                               pCdTipoOrigemRubrica    => CASE
                                                                             WHEN pTpTributacao IN (CTRIB_TIPO_NORMAL,
                                                                                                    CTRIB_TIPO_DECTER) THEN
                                                                              8
                                                                             WHEN pTpTributacao = CTRIB_TIPO_RRA THEN
                                                                              18
                                                                             ELSE
                                                                              1
                                                                          END,
                                               pcdhistsentencajudicial => pSentenca.Cdhistsentencajudicial);
      END IF;

      IF pSentenca.CdExpressaoFormCalc IS NOT NULL THEN 
                      
         -- Processa a pensao por formula
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pTributacao.CdVinculo,
                                          pCdRubrica       => pSentenca.CdRubricaAgrupamento,
                                          pTpProcessamento => 1, -- Processa formulas de calculo
                                          pTpLocal         => 2, -- no vinculo
                                          pTpTributacao    => pTpTributacao,
                                          pIndProcRetro    => pIndProcRetro);
                        
         IF vFlCalculando13 THEN
                           
            -- Se o valor da rubrica da pensao for <= que 0 e
            -- o valor da rubrica de 13 salario  for > 0, busca o valor da pensao
            -- da folha que foi tomada como base para o calculo da folha de 13 salario
            -- Ocorre com a rubrica de pensao 05-0922
                           
            IF FRetornaValorRubrica(pTributacao => pTributacao,
                                    pCdRubrica  => pSentenca.CdRubricaAgrupamento,
                                    pNuSufixo   =>  pSentenca.NuSequencial) <= 0 AND
               FRetornaValorRubrica(pTributacao => pTributacao,
                                    pCdRubrica  => PKGPAG_VAR.vgCdRubAgrup13) > 0 THEN
                              
               IF NVL(PKGPAG_VAR.vgCdFolhaReplicada13, 0) > 0 THEN
                                 
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pTributacao.CdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => pSentenca.CdRubricaAgrupamento,
                                                        pNuSufixoRubrica      => pSentenca.NuSequencial,
                                                        pVlPagamento          => -- POG Solicitacao de Sustentacao #73185
                                                         CASE
                                                            WHEN pTributacao.CdVinculo = 479565 AND
                                                                 pTributacao.pFolha.NuAnoReferencia = 2016 AND
                                                                 pTributacao.pFolha.NuMesReferencia = 12 AND
                                                                 pTributacao.pFolha.CdTipoFolha = 3 -- 13°
                                                             THEN
                                                                              
                                                             (PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgCdFolhaReplicada13,
                                                                                                pTributacao.CdVinculo,
                                                                                                vSentenca.CdRubricaAgrupamento,
                                                                                                vSentenca.NuSequencial) * 5 / 12)
                                                                           
                                                            ELSE
                                                             PKGPAG_GERAL.FRetornaValorRubrica(PKGPAG_VAR.vgCdFolhaReplicada13,
                                                                                               pTributacao.CdVinculo,
                                                                                               vSentenca.CdRubricaAgrupamento,
                                                                                               vSentenca.NuSequencial)
                                                         END
                                                                          
                                                       ,
                                                        pVlIndice               => NULL,
                                                        pCdTipoOrigemRubrica    => CASE
                                                                                      WHEN pTpTributacao IN (CTRIB_TIPO_NORMAL,
                                                                                                             CTRIB_TIPO_DECTER) THEN
                                                                                       8
                                                                                      WHEN pTpTributacao = CTRIB_TIPO_RRA THEN
                                                                                       18
                                                                                      ELSE
                                                                                       1
                                                                                   END,
                                                        pcdhistsentencajudicial => pSentenca.Cdhistsentencajudicial);
                                 
               END IF;
                              
            END IF;
                           
         END IF;

      END IF;

   END;

BEGIN
 
/*
#PENDENTE

Fazer a derrubada correta das consignaçoes para calcular a pensão como era feito antes

*/



   IF pTabSentenca.COUNT = 0 THEN
      RETURN;
   END IF;
   
   vFlCalculando13 := (pTributacao.pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13,
                                                          PKGPAG_TIPO.cnTpFolhaAdiant13,
                                                          PKGPAG_TIPO.cnTpFolhaCtisp13,
                                                          PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp) );
                                              
   vLstExpressaoIRRF := FLstExpressaoIRRF;

   IF vLstExpressaoIRRF.COUNT = 0 THEN 
      vMaxTentativa := 1;
   ELSIF PKGPAG_VAR.vgParamPagamento.NuAproxIRRFPensao IS NULL THEN
      vMaxTentativa := 1;
   ELSIF PKGPAG_VAR.vgParamPagamento.NuAproxIRRFPensao = 0 THEN
      vMaxTentativa := 1;
   ELSE      
      vMaxTentativa := PKGPAG_VAR.vgParamPagamento.NuAproxIRRFPensao;
   END IF;
   
   vLstRubricaSentenca := TYPENUMBER();  
        
   FOR p IN 1.. vMaxTentativa LOOP
                    
       IF p > 1 THEN -- não precisa apagar na primeira vez pois a sentenca ainda não foi calculada
         DELETE FROM EPagHistoricoRubricaVinculo HRV
          WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
            AND HRV.CdVinculo = pTributacao.CdVinculo
            AND HRV.CdRubricaAgrupamento IN
                   (SELECT column_value
                      FROM TABLE(vLstRubricaSentenca))
            AND HRV.CdLancamentoFinanceiro IS NULL;  
      END IF;
                                                             
       -- Calcular Sentencas

      FOR s IN pTabSentenca.FIRST .. pTabSentenca.LAST LOOP

         PCalcularSentenca (pSentenca => pTabSentenca(s));   
         
         IF p = 1 THEN -- na primeira vez, carregar tabela de rubricas
            vLstRubricaSentenca.EXTEND;
            vLstRubricaSentenca(vLstRubricaSentenca.LAST) := pTabSentenca(s).CdRubricaAgrupamento;
         END IF;
             
      END LOOP;
         
      IF vLstExpressaoIRRF.COUNT > 0 THEN   

         -- somar pensoes
         
         SELECT NVL(SUM(VlPagamento),0)
           INTO vvlPensao
           FROM EPagHistoricoRubricaVinculo HRV
          INNER JOIN EPagBaseCalcBlocoExprRubAgrup BER
             ON HRV.CdRubricaAgrupamento = BER.CdRubricaAgrupamento
          WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
            AND HRV.CdVinculo = pTributacao.CdVinculo
            AND HRV.CdRubricaAgrupamento IN
                (SELECT column_value
                   FROM TABLE(vLstRubricaSentenca))
            AND BER.CdBaseCalculoBlocoExpressao IN
                (SELECT column_value
                   FROM TABLE(vLstExpressaoIRRF));                   
 
         vValorIRRFAnterior := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pCdRubrica  => pCdRubAgrupDescIRRF);
                                                    
         -- Recalcular IRRF  
             
         DELETE FROM epagHistoricoRubricaVinculo HRV
          WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
            AND HRV.CdVinculo = pTributacao.CdVinculo
            AND HRV.CdRubricaAgrupamento = pCdRubAgrupDescIRRF;
 
         PProcessaTributacaoIRRF(pTributacao       => pTributacao,
                                 pTpTributacao     => pTpTributacao,
                                 pIndProcRetro     => pIndProcRetro,
                                 pbPrima           => FALSE);
                                 
         vvlIRRF := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pCdRubrica  => pCdRubAgrupDescIRRF);
         
         IF p > 1 THEN -- Não primeira vez a pensão anterior não foi alimentada entao não pode testar
         
            IF vvlPensao = vValorPensaoAnterior AND vvlIRRF = vValorIRRFAnterior THEN
               EXIT;
            END IF;
         END IF;         

         vValorPensaoAnterior := vvlPensao;
         vValorIRRFAnterior   := vvlIRRF;       
         
      END IF;
                   
   END LOOP;
      
END;                                                          
                             
PROCEDURE PPensaoAlimPrep (pTributacao     IN OUT NOCOPY rTributacao,
                           pTpTributacao       IN INTEGER,
                           pTabSentenca        IN OUT tSentenca                       
                           ) IS
   
   vCdExpressaoFormCalc      INTEGER;
   vFlCalculando13           BOOLEAN;

   vSentenca                 rSentenca;
   vTabSentenca              tSentenca;
   
   vTabRubSentenca           PKGPAG_TIPO.tLista;
      
   FUNCTION FSentencaSuspensa(pCdSentencaJudicial IN INTEGER)
      
    RETURN BOOLEAN IS
      
      vCont INTEGER DEFAULT 0;
      
   BEGIN
      
      SELECT 1
        INTO vCont
        FROM EPenSuspensaoSentenca SS
       WHERE SS.CdSentencaJudicial = pCdSentencaJudicial
         AND ((SS.NuAnoInicio < pTributacao.pFolha.NuAnoReferencia OR
             (SS.NuAnoInicio = pTributacao.pFolha.NuAnoReferencia AND
             SS.NuMesInicio <= pTributacao.pFolha.NuMesReferencia)) AND
             (SS.NuAnoFim > pTributacao.pFolha.NuAnoReferencia OR
             (SS.NuAnoFim = pTributacao.pFolha.NuAnoReferencia AND
             SS.NuMesFim >= pTributacao.pFolha.NuMesReferencia) OR
             SS.NuAnoFim IS NULL));
      
      IF vCont > 0 THEN
         
         RETURN TRUE;
         
      ELSE
         
         RETURN FALSE;
         
      END IF;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         RETURN FALSE;
         
      WHEN TOO_MANY_ROWS THEN
         
         RETURN TRUE;
         
   END;
   
   FUNCTION FExistePagamentoRubrica(pCdOutraRubrica IN INTEGER)
      
    RETURN BOOLEAN IS
      
      vCont INTEGER DEFAULT 0;
      
   BEGIN
      
      SELECT COUNT(*)
        INTO vCont
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = pTributacao.CdVinculo
         AND HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdOutraRubrica;
      
      IF vCont > 0 THEN
         
         RETURN TRUE;
         
      ELSE
         
         RETURN FALSE;
         
      END IF;
      
   END;
 
BEGIN

   IF pTabSentenca.COUNT = 0 THEN
      RETURN;
   END IF;
 
   vFlCalculando13 := (pTributacao.pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13,
                                                          PKGPAG_TIPO.cnTpFolhaAdiant13,
                                                          PKGPAG_TIPO.cnTpFolhaCtisp13,
                                                          PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp) );
                         
   -- Carregar Sentencas
   
   vTabRubSentenca.DELETE;
   
   vTabSentenca := tSentenca();

   FOR s IN pTabSentenca.FIRST .. pTabSentenca.LAST LOOP
      
      vSentenca := pTabSentenca(s);
             
      IF (NOT vFlCalculando13) OR vSentenca.FlPagamento13 = 'S' THEN
        
         IF (NOT FSentencaSuspensa(vSentenca.CdSentencaJudicial)) AND
            PKGPAG_VAR.vgRubrica.EXISTS(vSentenca.CdRubricaAgrupamento) AND
            PKGPAG_GERAL.FRubricaPermitida(pTributacao.pFolha.FlPagaTodasRubricas,
                                           pTributacao.pFolha.CdTipoFolha,
                                           vSentenca.CdRubricaAgrupamento) AND NOT
             PKGPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => vSentenca.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica      => vSentenca.NuSequencial) THEN

             IF (vSentenca.CdOutraRubrica IS NULL) OR
               vTabRubSentenca.EXISTS (vSentenca.CdOutraRubrica) THEN
                 
               IF vSentenca.FlPagamentoValorFixo = 'S' AND
                  vSentenca.CdRubricaAgrupamento NOT IN
                  (PKGPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao,
                   PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensao13) AND
                  pTpTributacao IN (CTRIB_TIPO_NORMAL, CTRIB_TIPO_DECTER) THEN                 
                  
                  vSentenca.CdExpressaoFormCalc := NULL;
                  vTabSentenca.EXTEND;
                  vTabSentenca(vTabSentenca.LAST) := vSentenca;
                  vTabRubSentenca(vSentenca.CdRubricaAgrupamento) := 1;
                  
               ELSIF vSentenca.VlPercentPensao IS NOT NULL THEN
 
                  --
                  -- Indica se permite pensao RRA. Excecao rubrica percentual sobre salario minimo
                  --
                  IF pTpTributacao = CTRIB_TIPO_RRA AND
                     (vSentenca.FlPagamentoRetroativo = 'N' OR
                     vSentenca.Cdrubricaagrupamento = pTributacao.rub.CdRubDescPENSAOALSALMIN) THEN
  
                     CONTINUE;
                  END IF;
                  
                  -- Alteracao em 02/07/2012
                  -- As rubricas de adiantamento de 13 de pensao e pensao de 13 nao devem ser
                  -- calculadas, pois elas sao produto das rubricas de pensao normais
                  
                  IF vSentenca.CdRubricaAgrupamento NOT IN
                     (PKGPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao,
                      PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensao13) THEN
                     
                     vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                                    pCdRubricaAgrupamento => vSentenca.CdRubricaAgrupamento,
                                                                                    pCdRelacaoVinculo     => 0); -- Vinculo
                     
                     IF vCdExpressaoFormCalc > 0 THEN
                       
                        vSentenca.CdExpressaoFormCalc := vCdExpressaoFormCalc;                        
                        vTabSentenca.EXTEND;
                        vTabSentenca(vTabSentenca.LAST) := vSentenca;
                        vTabRubSentenca(vSentenca.CdRubricaAgrupamento) := 1;
                                              
                     ELSE

                        PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                                PKGPAG_VAR.vCdHistParamCalc,
                                                PKGPAG_VAR.vCdPessoa,
                                                'Rubrica de pensão sem fórmula cadastrada:' ||
                                                LPAD(PKGPAG_VAR.vgRubrica(vSentenca.CdRubricaAgrupamento).CdTipoRubrica,
                                                     2,
                                                     '0') || '-' ||
                                                LPAD(PKGPAG_VAR.vgRubrica(vSentenca.CdRubricaAgrupamento).NuRubrica,
                                                     4,
                                                     '0'),
                                                PKGPAG_VAR.vgCdVinculo);
                        
                     END IF;                    
                  END IF;
               END IF;               
            END IF;            
         END IF;         
      END IF;
  
   END LOOP;

   pTabSentenca := vTabSentenca;

   IF vTabSentenca.COUNT > 0 THEN
      PKGPAG_VAR.bPossuiPensao := TRUE;
   END IF;
                          
END;

PROCEDURE PPensaoAlimenticia(pTributacao     IN OUT NOCOPY rTributacao,
                             pCdRubBaseIRRF      IN INTEGER,
                             pCdRubAgrupDescIRRF IN INTEGER,
                             pTpTributacao       IN INTEGER,
                             pIndProcRetro       IN INTEGER) IS
                                   
   vTabSentenca              tSentenca;    
   vTabRubricaSentenca       PKGPAG_TIPO.tLista;
   vTabRubricaConsig         PKGPAG_TIPO.tLista;
   vFlCalculando13           BOOLEAN;
  
   FUNCTION FTrataExigidas(pCdFolhaPagamento     IN INTEGER,
                           pCdVinculo            IN INTEGER,
                           pCdRubricaAgrupamento IN INTEGER)
      
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
            exigem o recebimento desta que n¿o tenham sido pagas ao vinculo.
                  
            Se (vCont = 0) ent¿o exclui o(s) pagamentos da rubrica            */
            
            SELECT COUNT(*)
              INTO vCont
              FROM EpagHistRubricaAgrupExigida E
             WHERE E.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica
               AND NOT EXISTS
             (SELECT 1
                      FROM EPagHistoricoRubricaVinculo HRV
                     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento =
                           E.CdRubricaAgrupamento
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
                       AND HRV.CdRubricaAgrupamento =
                           E.CdRubricaAgrupamento
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
      
      IF vRubrica.lsRubExigida.COUNT > 0 THEN
         
         IF NOT FCumpreExigencia(pCdFolhaPagamento, pCdVinculo, vRubrica) THEN
            
            RETURN TRUE;
            
         END IF;
         
      END IF;
      
      RETURN FALSE;
 
         
      EXCEPTION
         WHEN OTHERS THEN
            RETURN FALSE;
                 
   END;
                
BEGIN
               
   PKGPAG_VAR.bPossuiPensao := FALSE;
   
   IF PKGPAG_TIPO.cnTipoFolhaPag13.EXISTS(pTributacao.pFolha.CdTipoFolha) THEN
      RETURN;
   END IF;

   --
   -- Ciasc - Nao desconta pensao RRA nem em Folha de Recalculo Complementar.
   --
   IF (pTpTributacao = CTRIB_TIPO_RRA OR
      pTributacao.pFolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoRecalcCompl) AND
      pTributacao.pFolha.CdAgrupamento = CAGR_CIASC THEN
      RETURN;
   END IF;

   PKGPAG_GERAL.PLogProcIni('TRI01','Processa Pensao');
   
   PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;
   
   vTabSentenca  := tSentenca();
   vTabRubricaSentenca.DELETE; 
   
   vFlCalculando13 := (pTributacao.pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13,
                                                          PKGPAG_TIPO.cnTpFolhaAdiant13,
                                                          PKGPAG_TIPO.cnTpFolhaCtisp13,
                                                          PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp) );
                                              
   FOR vSentenca IN cSentenca (pFolha => pTributacao.pFolha, pCdvinculo => pTributacao.CdVinculo, pDtInicioPensao13 => to_date(pTributacao.pFolha.NuAnoReferencia || '1201','YYYYMMDD') ) LOOP

      IF pTributacao.pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias AND
         vSentenca.Flpagamentoferias = 'N' THEN
         CONTINUE;
      END IF;

      --
      -- Trata rubricas exigidas
      --

      IF FTrataExigidas(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                        pCdVinculo            => pTributacao.CdVinculo,
                        pCdRubricaAgrupamento => vSentenca.CdRubricaAgrupamento) THEN
         CONTINUE;
      END IF;

      ---
      --- Conforme solicitacao, as rubricas de consignacao que fazer parte da base
      --- da pensao devem ser calculadas antes do processamento da pensao afim de terem
      --- seus valores apurados para a formula.
      ---
     
      IF (NOT vFlCalculando13) THEN
         PCalcularConsignacao (pFolha                => pTributacao.pFolha, 
                               pCdVinculo            => pTributacao.CdVinculo,
                               pCdRubricaAgrupamento => vSentenca.cdRubricaAgrupamento,
                               pTabRubricaSentenca   => vTabRubricaSentenca,
                               pTabRubricaConsig     => vTabRubricaConsig);
       
      END IF;

      vSentenca.CdExpressaoFormCalc := NULL;

      vTabSentenca.EXTEND;
      vTabSentenca(vTabSentenca.LAST) := vSentenca;    
   END LOOP;
 
   PPensaoAlimPrep (pTributacao         => pTributacao,
                    pTpTributacao       => pTpTributacao,
                    pTabSentenca        => vTabSentenca);                  
 
   PPensaoAlimCalc (pTributacao         => pTributacao,
                    pCdRubBaseIRRF      => pCdRubBaseIRRF,
                    pCdRubAgrupDescIRRF => pCdRubAgrupDescIRRF,
                    pTpTributacao       => pTpTributacao,
                    pIndProcRetro       => pIndProcRetro,
                    pTabSentenca        => vTabSentenca);
                                          
   PApagarConsignacao (pCdFolhaPagamento   => pTributacao.pFolha.CdFolhaPagamento,
                       pCdVinculo          => pTributacao.CdVinculo,
                       pTabRubricaConsig   => vTabRubricaConsig);                     
 
   PKGPAG_GERAL.PLogTrace('TRIBUTACAO - Processa Pensão',
                          NULL,
                          PKGPAG_VAR.vgTmInicio);
   
   PKGPAG_GERAL.PLogProcFim('TRI01');    
                     
END;
                             

PROCEDURE PProcessaTributacaoRRA(pTributacao IN OUT NOCOPY rTributacao) IS
   
   vvlBaseRRA NUMBER(13, 2);
   
   FUNCTION FExistePensaoVigenteNoPeriodo(pCdVinculo   IN INTEGER,
                                          pNuAnoInicio IN INTEGER,
                                          pNuMesInicio IN INTEGER,
                                          pNuAnoFim    IN INTEGER,
                                          pNuMesFim    IN INTEGER)
      RETURN BOOLEAN IS
      vQtdPensoesVigentes INTEGER := 0;
      vExiste             BOOLEAN := FALSE;
      vDtInicioPeriodo    DATE;
      vDtFimPeriodo       DATE;
   BEGIN
      vDtInicioPeriodo := TO_DATE('01/' || pNuMesInicio || '/' ||
                                  pNuAnoInicio,
                                  'dd/mm/yyyy');
      vDtFimPeriodo    := TO_DATE('01/' || pNuMesFim || '/' || pNuAnoFim,
                                  'dd/mm/yyyy');
      vDtFimPeriodo    := LAST_DAY(vDtFimPeriodo);
      
      SELECT COUNT(*) AS qtd
        INTO vQtdPensoesVigentes
        FROM epenhistsentencajudicial
       WHERE flanulado = 'N'
         AND cdtipopensaoalimenticia IS NOT NULL
         AND cdsentencajudicial IN
             (SELECT cdsentencajudicial
                FROM epensentencajudicial
               WHERE cdvinculo = pCdVinculo)
         AND ((dtiniciovigencia >= vDtInicioPeriodo AND
             dtiniciovigencia <= vDtFimPeriodo) OR
             (dtfimvigencia >= vDtInicioPeriodo AND
             dtfimvigencia <= vDtFimPeriodo));
      
      vExiste := vQtdPensoesVigentes > 0;
      
      RETURN vExiste;
   END;
   
BEGIN
   
   FOR iProc IN PKGPAG_RT.vgProcessoRetroativo.FIRST .. PKGPAG_RT.vgProcessoRetroativo.LAST LOOP
      
      IF PKGPAG_RT.vgProcessoRetroativo(iProc).VlRestituir > 0 THEN

         UPDATE EPAGHISTORICORUBRICAVINCULO
            SET CDPROCESSOPAGRETROATIVO = PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo
          WHERE CDVINCULO = pTributacao.CdVinculo
            AND CDFOLHAPAGAMENTO = pTributacao.pFolha.CdFolhaPagamento
            AND CDRUBRICAAGRUPAMENTO = PKGPAG_VAR.vgCdRubBaseDeducoesIRRF;
         
         PProcessaTributacaoIRRF(pTributacao    => pTributacao,
                                 pTpTributacao  => CTRIB_TIPO_RRA,
                                 pbPrima        => FALSE,
                                 pIndProcRetro  => iProc);
         
         PPensaoAlimenticia(pTributacao         => pTributacao,
                            pCdRubBaseIRRF      => PKGPAG_VAR.vgCdRubBaseIRRF,
                            pCdRubAgrupDescIRRF => PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF,
                            pTpTributacao       => CTRIB_TIPO_RRA,
                            pIndProcRetro       => iProc);
         
         UPDATE EPAGHISTORICORUBRICAVINCULO
            SET CDPROCESSOPAGRETROATIVO = NULL
          WHERE CDVINCULO = pTributacao.CdVinculo
            AND CDFOLHAPAGAMENTO = pTributacao.pFolha.CdFolhaPagamento
            AND CDRUBRICAAGRUPAMENTO = PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF;
         
         -- Busca o valor da base calculado de IR para gerar a rubrica da BASE do RRA
         
         vvlBaseRRA := FRetornaValorRubrica(pTributacao => pTributacao,
                                            pCdRubrica  => PKGPAG_VAR.vgCdRubBaseIRRF);
         
         IF vvlBaseRRA > 0 THEN
            
            -----------------------------------------------------------------------------------------------
            -- Insere base do RRA
            -----------------------------------------------------------------------------------------------
            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pTributacao.pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pTributacao.CdVinculo,
                                                  pCdExpressaoFormCalc     => NULL,
                                                  pCdRubricaAgrupamento    => PKGPAG_VAR.vgCdRubBaseRRA,
                                                  pNuSufixoRubrica         => PKGPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                                                  pVlPagamento             => vvlBaseRRA,
                                                  pCdProcessoPagRetroativo => PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo,
                                                  pDeProcessoRetroativo    => PKGPAG_RT.vgProcessoRetroativo(iProc).DeProcessoRetroativo,
                                                  pVlIndice                => PKGPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                                                  pVlRestituir             => PKGPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                                                  pCdTipoOrigemRubrica     => 18,
                                                  pVlIndiceNMRRA           => PKGPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA);
            
            BEGIN
               -----------------------------------------------------------------------------------------------
               -- Atualiza informacoes do processo de retroativo na rubrica de desconto de IRRF de RRA
               -----------------------------------------------------------------------------------------------
               UPDATE EPagHistoricoRubricaVinculo HRV
                  SET HRV.CdRubricaagrupamento    = PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescRRA,
                      HRV.NuSufixorubrica         = PKGPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                      HRV.VlIndicerubrica         = PKGPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                      HRV.CdTipoOrigemRubrica     = 18,
                      HRV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo,
                      HRV.DeProcessoRetroativo    = PKGPAG_RT.vgProcessoRetroativo(iProc).DeProcessoRetroativo,
                      HRV.VlMontanteRetroativo    = PKGPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                      HRV.VlIndiceNMRRA           = PKGPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA
                WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                  AND HRV.CdVinculo = pTributacao.CdVinculo
                  AND HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF;
               
            EXCEPTION
               WHEN OTHERS THEN
                  PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                          PKGPAG_VAR.vCdHistParamCalc,
                                          PKGPAG_VAR.vCdPessoa,
                                          'PKGPAG_TRIBUTACAO - Insere Base RRA',
                                          PKGPAG_VAR.vgCdVinculo);
            END;
            
         END IF;
         
         BEGIN
            -----------------------------------------------------------------------------------------------
            -- Atualiza as informacoes das rubricas de pensao alimenticia de RRA
            -----------------------------------------------------------------------------------------------
            
            IF (pTributacao.pFolha.CdAgrupamento <> 176) OR
               (pTributacao.pFolha.CdAgrupamento = 176 AND
               FExistePensaoVigenteNoPeriodo(pCdVinculo   => pTributacao.CdVinculo,
                                              pNuAnoInicio => PKGPAG_RT.vgProcessoRetroativo(iProc).NuAnoInicioRestituicao,
                                              pNuMesInicio => PKGPAG_RT.vgProcessoRetroativo(iProc).NuMesInicioRestituicao,
                                              pNuAnoFim    => PKGPAG_RT.vgProcessoRetroativo(iProc).NuAnoFimRestituicao,
                                              pNuMesFim    => PKGPAG_RT.vgProcessoRetroativo(iProc).NuMesFimRestituicao)) THEN
               
               UPDATE EPagHistoricoRubricaVinculo HRV
                  SET HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensaoAliRRA,
                      -- Comentado por deve manter o mesmo sufixo (o da sentenca)
                      -- HRV.NuSufixorubrica = PKGPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                      HRV.VlIndicerubrica         = PKGPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                      HRV.CdTipoOrigemRubrica     = 18,
                      HRV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo,
                      HRV.DeProcessoRetroativo    = PKGPAG_RT.vgProcessoRetroativo(iProc).DeProcessoRetroativo,
                      HRV.VlMontanteRetroativo    = PKGPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                      HRV.VlIndiceNMRRA           = PKGPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA
                WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
                  AND HRV.CdVinculo = pTributacao.CdVinculo
                  AND HRV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo
                  AND HRV.CdRubricaAgrupamento IN
                      (SELECT RA.CdRubricaAgrupamento
                         FROM EPagRubricaAgrupamento RA
                        WHERE RA.FlPensaoAlimenticia = PKGPAG_TIPO.cnS
                          AND RA.CdAgrupamento = pTributacao.pFolha.CdAgrupamento)
                        
                     /* AND (HRV.CdRubricaAgrupamento,HRV.NuSufixoRubrica)
                     NOT IN
                       -- Nao alterar quando tiver lancamento financeiro para a rubrica de pensao
                       -- afim de que este prevaleca, desde que nao seja oriundo de retroativo.
                            (SELECT LF.CdRubricaAgrupamento, LF.NuSufixoRubrica
                               FROM EPagLancamentoFinanceiro LF
                              WHERE LF.CdVinculo = pCdVinculo AND
                                    LF.DtInicioDireito <= pFolha.DtFimMes
                                AND (LF.DtFimDireito >= pFolha.DtInicioMes OR LF.DtFimDireito IS NULL)
                                AND (   LF.CdProcessoPagRetroativo IS NULL
                                     OR LF.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo)
                                )*/
                  AND HRV.DeProcessoRetroativo IS NULL;
               
            END IF;
            
         EXCEPTION
            WHEN OTHERS THEN
               PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                       PKGPAG_VAR.vCdHistParamCalc,
                                       PKGPAG_VAR.vCdPessoa,
                                       'PKGPAG_TRIBUTACAO - Atualiza informações rubrica pensão RRA',
                                       PKGPAG_VAR.vgCdVinculo);
         END;
         
         -----------------------------------------------------------------------------------------------
         -- Atualiza as informacoes das rubricas de IPREV de exercicios findos (06-0915 e 06-0926
         -----------------------------------------------------------------------------------------------
         BEGIN
            UPDATE EPagHistoricoRubricaVinculo HRV
               SET HRV.NuSufixorubrica      = PKGPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                   HRV.VlIndicerubrica      = PKGPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                   HRV.CdTipoOrigemRubrica  = 18,
                   HRV.VlMontanteRetroativo = PKGPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                   HRV.VlIndiceNMRRA        = PKGPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA
             WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pTributacao.CdVinculo
               AND HRV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo
               AND HRV.CdRubricaAgrupamento IN
                   (pTributacao.rub.CdRubDescRESSARIPREVFP,pTributacao.rub.CdRubDescRESSARCIPREVSC);
         EXCEPTION
            WHEN OTHERS THEN
               PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                       PKGPAG_VAR.vCdHistParamCalc,
                                       PKGPAG_VAR.vCdPessoa,
                                       'PKGPAG_TRIBUTACAO - Atualiza IPREV RRA',
                                       PKGPAG_VAR.vgCdVinculo);
         END;
         
      END IF;
      
   END LOOP;
   
END;


PROCEDURE PGeraPatronalParaAfastado(pVinculo IN PKGPAG_TIPO.rVinculo,
                                    pFolha   IN PKGPAG_TIPO.rFolha) IS
   
   vCdTipoRegimeProprioPrev INTEGER;
   
   vCont INTEGER;
   
BEGIN
   
   IF (NVL(pVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax) <
      pFolha.DtInicioMes) OR
      (PKGPAG_VAR.vMotAfast.InAfastado = PKGPAG_TIPO.cnAfastadoMesTodo) THEN
      
      IF pVinculo.CdSituacaoPrevidenciaria <>
         PKGPAG_TIPO.cnSitPrevAposentado THEN
         
         IF pVinculo.CdRegimePrevidenciario = 2 THEN
            
            SELECT V.CdTipoRegimeProprioPrev
              INTO vCdTipoRegimeProprioPrev
              FROM ECadVinculo V
             WHERE CdVInculo = pVinculo.CdVinculo;
            
            IF vCdTipoRegimeProprioPrev = 1 THEN
               --FF
               
               BEGIN
                  
                  SELECT 1
                    INTO vCont
                    FROM EPagHistoricoRubricaVinculo HRV
                   WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                     AND HRV.CdVinculo = pVinculo.CdVinculo
                     AND HRV.CdRubricaAgrupamento =
                         PKGPAG_VAR.vgCdRubBaseIPREVFF
                     AND ROWNUM < 2;
                  
               EXCEPTION
                  
                  WHEN NO_DATA_FOUND THEN
                     
                     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                           pCdVinculo            => pVinculo.CdVinculo,
                                                           pCdExpressaoFormCalc  => NULL,
                                                           pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIPREVFF,
                                                           pNuSufixoRubrica      => 1,
                                                           pVlPagamento          => 0,
                                                           pVlIndice             => NULL,
                                                           pCdTipoOrigemRubrica  => 10);
                     
               END;
               
            ELSE
               
               BEGIN
                  
                  SELECT 1
                    INTO vCont
                    FROM EPagHistoricoRubricaVinculo HRV
                   WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                     AND HRV.CdVinculo = pVinculo.CdVinculo
                     AND HRV.CdRubricaAgrupamento =
                         PKGPAG_VAR.vgCdRubBaseIPREVFP
                     AND ROWNUM < 2;
                  
               EXCEPTION
                  
                  WHEN NO_DATA_FOUND THEN
                     
                     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                           pCdVinculo            => pVinculo.CdVinculo,
                                                           pCdExpressaoFormCalc  => NULL,
                                                           pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIPREVFP,
                                                           pNuSufixoRubrica      => 1,
                                                           pVlPagamento          => 0,
                                                           pVlIndice             => NULL,
                                                           pCdTipoOrigemRubrica  => 10);
                     
               END;
               
            END IF;
            
         END IF;
         
      END IF;
      
   END IF;
   
END;

PROCEDURE PPossuiLancFinanceiroPensao(pCdVinculo IN INTEGER,
                                      pFolha     IN PKGPAG_TIPO.rFolha) IS
   
BEGIN
   
   FOR RUB IN (SELECT TPR.CdRubricaAgrupamento,
                      LF.Vlindice,
                      LF.Vllancamentofinanceiro,
                      LF.Nusufixorubrica,
                      LF.Nuparcelas,
                      LF.Cdlancamentofinanceiro,
                      LF.Cdprocessopagretroativo
                 FROM ePenSentencaJudicial SJ
                INNER JOIN EPenHistSentencaJudicial HSJ
                   ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
                INNER JOIN EPenTipoPensaoAlimenticia TPA
                   ON HSJ.CdTipoPensaoAlimenticia =
                      TPA.CdTipoPensaoAlimenticia
                INNER JOIN EPenHistTipoPensao HTP
                   ON TPA.CdTipoPensaoAlimenticia =
                      HTP.CdTipoPensaoAlimenticia
                INNER JOIN EPenHistTipoPensaoRubrica TPR
                   ON TPR.CdHistTipoPensao = HTP.CdHistTipoPensao
                INNER JOIN epaghistoricorubricavinculo HRV
                   ON HRV.Cdrubricaagrupamento = TPR.Cdrubricaagrupamento
                  AND HRV.Cdfolhapagamento = pFolha.CdFolhaPagamento
                INNER JOIN Epaglancamentofinanceiro LF
                   ON LF.Cdrubricaagrupamento = TPR.Cdrubricaagrupamento
                  AND LF.NuSufixoRubrica = SJ.Nusequencial
                  AND LF.Flanulado = 'N'
                  AND LF.DtInicioDireito <= pFolha.DtFimMes
                  AND (LF.DtFimDireito >= pFolha.DtInicioMes OR
                      LF.DtFimDireito IS NULL)
                  AND LF.Cdvinculo = pCdVinculo
                WHERE SJ.CdVinculo = pCdVinculo
                  AND HSJ.FlAnulado = PKGPAG_TIPO.cnN
                  AND HSJ.Dtiniciovigencia <= pFolha.DtFimMes
                  AND ((HSJ.DtFimVigencia >= CASE
                         WHEN pFolha.CdTipoFolha IN
                              (PKGPAG_TIPO.cnTpFolha13,
                               pkgpag_tipo.cnTpFolhaCtisp13) THEN
                          to_date('01/12/' || pFolha.NuAnoReferencia,
                                  'DD/MM/YYYY')
                         ELSE
                          pFolha.DtInicioMes
                      END) OR HSJ.DtFimVigencia IS NULL)
                  AND ((HTP.NuAnoInicio < pFolha.NuAnoReferencia OR
                      (HTP.NuAnoInicio = pFolha.NuAnoReferencia AND
                      HTP.NuMesInicio <= pFolha.NuMesReferencia)) AND
                      (HTP.NuAnoFim > pFolha.NuAnoReferencia OR
                      (HTP.NuAnoFim = pFolha.NuAnoReferencia AND
                      HTP.NuMesFim >= pFolha.NuMesReferencia) OR
                      HTP.NuAnoFim IS NULL))
                GROUP BY TPR.CdRubricaAgrupamento,
                         LF.Vlindice,
                         LF.Vllancamentofinanceiro,
                         LF.Nusufixorubrica,
                         LF.Nuparcelas,
                         LF.Cdlancamentofinanceiro,
                         LF.Cdprocessopagretroativo) LOOP
      
      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = RUB.CdRubricaAgrupamento
         AND HRV.Cdlancamentofinanceiro IS NULL;
      
   END LOOP;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      NULL;
      
END;


PROCEDURE PInsereBasesTributacao(pTributacao IN rTributacao) IS 
   
   vVlTotalProventos13 NUMBER;
   
   
BEGIN
          
   vVlTotalProventos13 := pkgpag_geral.fVlTotalProventos13(pTributacao.pFolha.CdFolhaPagamento,
                                                           pTributacao.cdvinculo);
   
   IF PKGPAG_VAR.vgCdRubBaseIRRF IS NOT NULL THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIRRF,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
   END IF;
   
   ------------------------------------------------------------------------------------------------
   -- Calcula a base de IRRF de 13 para futura verificacao se deve realizar este tipo de tributacao
   ------------------------------------------------------------------------------------------------
   
   IF PKGPAG_VAR.vgCdRubBaseIRRF13 IS NOT NULL AND
      NOT PKGPAG_VAR.bReprocessou13Sal AND vVlTotalProventos13 > 0 THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIRRF13,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                       pCdVinculo       => pTributacao.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIRRF13,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/
      
   END IF;
   
   ------------------------------------------------------------------------------------------------------
   -- Calcula a base de IRRF de Ferias para futura verificacao se deve realizar este tipo de tributacao
   ------------------------------------------------------------------------------------------------------
   
   IF PKGPAG_VAR.vgCdRubBaseIRRFFerias IS NOT NULL THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseIRRFFerias,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                       pCdVinculo       => pTributacao.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIRRFFerias,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/
      
   END IF;
   
   IF PKGPAG_VAR.vgCdRubBaseINSS13 IS NOT NULL AND
      NOT PKGPAG_VAR.bReprocessou13Sal AND vVlTotalProventos13 > 0 THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseINSS13,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                       pCdVinculo       => pTributacao.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseINSS13,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/
      
   END IF;
   
   ---------------------------------------------------------------------
   -- Se for regime geral gera as Patronais do INSS CLT e Estatutario
   ---------------------------------------------------------------------
   
   IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = PKGPAG_TIPO.cnRegPrevGeral THEN
      
      IF PKGPAG_VAR.vgCdRubricaBaseINSSPat IS NOT NULL
        -- EPAGRI - Excecao Gerar somente para comissionados
         AND NOT (PKGPAG_VAR.vgFolha.CdOrgao = 27 AND
          PKGPAG_VAR.bVinculoComCCO = FALSE) THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseINSSPat,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10);
         
      END IF;
 
pDebug ('vai testar se inclui vgCdRubBaseINSSCLT');
      
      IF PKGPAG_VAR.vgCdRubBaseINSSCLT IS NOT NULL AND
         NOT (PKGPAG_VAR.vgFolha.CdOrgao = 27 AND
          PKGPAG_VAR.bVinculoComCCO = TRUE) THEN -- EPAGRI somente para efetivos

         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseINSSCLT,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10);
 pDebug ('Incluiu vgCdRubBaseINSSCLT');
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseProv13PatINSS IS NOT NULL THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseProv13PatINSS,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10);
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseProv13PatINSSCLT IS NOT NULL THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10);
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseProv13VlFGTS IS NOT NULL THEN
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pTributacao.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 10);
         
      END IF;
      
   END IF;
   
   ------------------------------------------------------
   -- DEDUCOES LEGAIS PARA IRRF 09-1908                --
   ------------------------------------------------------
   IF PKGPAG_VAR.vgCdRubBaseDeducoesIRRF IS NOT NULL AND
      FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,
                           pNuSufixo   => 1) = 0 THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
   END IF;
   
   ------------------------------------------------------
   -- TOTAL DEDUCOES LEGAIS DO IRRF 13 09-1909         --
   ------------------------------------------------------
   IF PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13 IS NOT NULL AND
      FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                           pNuSufixo   => 1) = 0 THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
   END IF;
   
   --------------------------------------------------------
   -- DEDUCOES LEGAIS PARA IRRF OUTROS VINCULOS 09-1911  --
   --------------------------------------------------------
   -- Usada no cálculo simplificado de IRRF
   IF PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros IS NOT NULL AND
      FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                           pNuSufixo   => 1) = 0 THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                       pCdVinculo       => pTributacao.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/
   END IF;
   
   -------------------------------------------------------------
   -- DEDUCOES LEGAIS PARA IRRF 13 - OUTROS VINCULOS 09-1912  --
   -------------------------------------------------------------
   IF PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13 IS NOT NULL AND
      FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                           pNuSufixo   => 1) = 0 AND
      (pTributacao.pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolha13 OR
      FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => pTributacao.rub.CdRubProvRESC13,
                           pNuSufixo   => 1) > 0) THEN
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pTributacao.pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pTributacao.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);
      
      PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                       pCdVinculo       => pTributacao.CdVinculo,
                                       pCdRubrica       => PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/
   END IF;
   
END;


PROCEDURE PExcluirRubricaDescDepIRRF(pCdFolhaPagamento IN INTEGER,
                                     pCdVinculo        IN INTEGER,
                                     pValorBaseIRRF    IN NUMBER,
                                     pValorBaseIRRF13  IN NUMBER) IS
BEGIN
   
   IF NVL(pValorBaseIRRF, 0) = 0 AND NVL(pValorBaseIRRF13, 0) = 0 THEN
      
      PKGPAG_GERAL.PExcluiRubrica(pcdfolhapagamento => pCdFolhaPagamento,
                                  pcdvinculo        => pCdVinculo,
                                  pcdrubrica        => PKGPAG_VAR.vgCdRubricaDescDepIRRF,
                                  pflexcluiambos    => 'S');
      
   END IF;
   
END;

PROCEDURE PIdentificarRubricas (pCdAgrupamento IN INTEGER, pRub IN OUT NOCOPY rTribRub) IS
   
BEGIN
   
   -- SCPREV
   pRub.CdRubBaseSCPREV13            := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0963); -- BASE DE CONTRIBUICAO DO SCPREV - 13
   pRub.CdRubDescSCPREVPATN13        := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1931); -- SCPREV-PATROCINADO CONTR.NORMAL - 13
   pRub.CdRubDescSCPREVFACN13        := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1932); -- SCPREV-FACULTATIVO CONTR.NORMAL - 13
   pRub.CdRubBaseSCPREVPAT13         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 1935); -- BASE DO PATRONAL SCPREV - 13 SAL

   pRub.CdRubProvGRAT13              := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 01, 0023); -- GRAT 13 SALARIO
   pRub.CdRubDescGRAT13              := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 08, 0023); -- GRAT 13 SALARIO
   pRub.CdRubDescADIANT13            := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 08, 0024); -- ADIANT 13 SALARIO
   pRub.CdRubProvAUXALIM             := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 01, 0157); -- AUX. ALIMENTACAO PROV
   pRub.CdRubDescINSSFERIAS          := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0216); -- INSS-FERIAS
   pRub.CdRubProvGRAT13CTISP         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 01, 0323); -- GRAT 13 SL-CTISP
   pRub.CdRubProvFERIASCTISP         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 01, 0356); -- FERIAS-CTISP
   pRub.CdRubDescCPSM                := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0380); -- CONTRIBUICAO DE PROTECAO SOCIAL DOS MILITARES - CPSM
   pRub.CdRubDescINSS                := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0512); -- I N S S
   pRub.CdRubDescPENSAOALSALMIN      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0574); -- PENSAO AL SALAR MIN (2)
   pRub.CdRubBaseINSS                := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0903); -- SALARIO CONTR.INSS
   pRub.CdRubProvABONOPERM           := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 01, 0914); -- ABONO DE PERMANENCIA
   pRub.CdRubDescRESSARCIPREVSC      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 06, 0915); -- RESS IPREV FUNDO SC SEGURO
   pRub.CdRubBaseBASEIPREV           := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0916); -- BASE DE CALCULO IPREV
   pRub.CdRubBaseBASEIPREV13         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0920); -- BASE DE CALCULO IPREV 13
   pRub.CdRubDescIPREVFF             := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0924); -- IPREV FUNDO SC SEGURO
   pRub.CdRubDescRESSARIPREVFP       := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 06, 0926); -- RESSARCIMENTO IPREV - FP
   pRub.CdRubBaseOPCAOART27          := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0932); -- BASE IPREV - OPCAO DO ART.27 §2º LC 412/08
   pRub.CdRubDescCONTIPREV13         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0944); -- IPREV FUNDO SC SEGURO 13
   pRub.CdRubBaseSCPREV              := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0961); -- BASE DE CONTRIBUICAO DO SCPREV
   pRub.CdRubBaseESTENDSCPREV        := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0962); -- VALOR ESTENDIDO DA BASE SCPREV
   pRub.CdRubDescBLOQUEIOREM         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0983); -- BLOQUEIO REMUNERACAO
   pRub.CdRubDescBLOQUEIOREM13       := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 0984); -- BLOQUEIO REM.13.SAL.
   pRub.CdRubProvRESC13              := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 01, 1023); -- PAGAMENTO RESCISAO 13 SAL
   pRub.CdRubBaseDEDIRSCPREV         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 1025); -- DEDUCAO DE IRRF - SCPREV
   pRub.CdRubBaseDEDIRSCPREV13       := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 1045); -- DEDUCAO DE IRRF - SCPREV - 13º
   pRub.CdRubProvABONPERM13          := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 01, 1914); -- ABONO DE PERMANENCIA DE 13 SAL
   pRub.CdRubDescIPREVART2713        := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1923); -- IPREV - OPCAO ART.27 2 LC412/08 - 13
   pRub.CdRubDescIPREVPART27         := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1924); -- IPREV - OPCAO ART.27 §2º LC 412/08
   pRub.CdRubDescSCPREVPATRNOR       := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1925); -- SCPREV-PATROCINADO CONTR.NORMAL-ART.21 LC 661/15
   pRub.CdRubBaseSCPREVPatronal      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 1925); -- BASE DO PATRONAL DO SCPREV
   pRub.CdRubDescSCPREVPATADIC       := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1926); -- SCPREV-PATROCINADO CONTR.ADIC.-ART.22 INCISO I LC 661/15
   pRub.CdRubDescSCPREVFACNOR        := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1927); -- SCPREV-FACULTATIVO CONTR.NORMAL-ART.21 LC 661/15
   pRub.CdRubDescSCPREVFACADIC       := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1928); -- SCPREV-FACULTATIVO CONTR.ADIC.-ART.22 INCISO I LC 661/15
   pRub.CdRubDescIPREVJUDICIAL       := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 1934); -- IPREV JUDICIAL
   pRub.CdRubBaseBASANUALINSS13      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 2113); -- TOTAL BASES INSS 13 DO ANO DE TODOS OS VINCULOS
   pRub.CdRubBaseDESCANUALINSS13     := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 2114); -- TOTAL DESCONTO INSS 13 DO ANO TODOS VINCULOS
   pRub.CdRubDescIRRFJUD             := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 05, 5516); -- IRRF JUDICIAL
   pRub.CdRubBaseIRRFPENSAO          := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 9052); -- BASE IRRF SOB PENSAO 
   pRub.CdRubBaseIRRFBASEPENSAO      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 9053); -- VALOR IRRF DA BASE IRRF SOB PENSAO 
   pRub.CdRubBaseIRRF12PORC          := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 9908); -- BASE DE IRRF BRUTA - 12%
   pRub.CdRubBaseIRRF12PORC13        := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 9909); -- BASE DE IRRF BRUTA - 12% - 13 SAL
   pRub.CdRubBaseCPSM                := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 9916); -- BASE DA CONTRIBUICAO DE PROTECAO SOCIAL DOS MILITARES
   pRub.CdRubBaseCPSM13              := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 9920); -- BASE CPSM 13 SAL

   pRub.CdRubBaseVariosVincINSS      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 1027); -- BASE DO INSS VARIOS VINCULOS
   pRub.CdRubDescVariosVincINSS      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 1028); -- DESCONTO DO INSS VARIOS VINCULOS

   pRub.CdRubPatronalAssociacao      := PKGPAG_GERAL.FRetornaRubrica (pCdAgrupamento, 09, 0992); -- PATRONAL ASSOCIACAO

END;

FUNCTION FFolPermitida (pCdFolhaPagamento IN INTEGER) RETURN TYPENUMBER IS
   
   vfolPermitida    TYPENUMBER;
   
BEGIN
   
   vfolPermitida :=  TYPENUMBER();
   
   for rec IN ( select f.DeOrdemExecucao, 
                       F.CDFOLHAPAGAMENTO
                  from EPagFolhaPagamento F
                 WHERE EXISTS (SELECT 1 
                                 FROM ECalFolhaTrib FP
                                WHERE F.CdFolhaPagamento = FP.CdFolhaPagamento
                                  AND FP.CdCalculoPai = PKGPAG_VAR.vgCalculo.CdCalculoPai
                               )
                 order by f.NuAnoMesReferencia, f.DeOrdemExecucao                            
                 ) LOOP

      vFolPermitida.EXTEND;
      vFolPermitida(vFolPermitida.LAST) := rec.Cdfolhapagamento;
      
      IF rec.CdFolhaPagamento = pCdFolhaPagamento THEN
         EXIT;
      END IF;
   END LOOP;

   RETURN vfolPermitida;
END;
             

PROCEDURE P_____________RotinasChamadasExternas IS
BEGIN
   NULL;
END;

PROCEDURE PProcessaTributacaoEPensao(pTributacao  IN OUT NOCOPY rTributacao,
                                     pCdPessoa        IN INTEGER,
                                     pCdVinculo       IN INTEGER) IS
   
   vCont             INTEGER;
   vVlBaseIRRF       NUMBER(13, 2);
   vVlBaseIRRF13     NUMBER(13, 2);
   vFlFolha13        BOOLEAN;
   
BEGIN
     
   PKGPAG_GERAL.PLogProcIni ('TRI','Package Tributacao');
   
   PDebug ('PProcessaTributacaoEPensao');
  
   pTributacao.CdPessoa   := pCdPessoa;
   pTributacao.CdVinculo  := pCdVinculo;
   
   PSelecionarPrev (pTributacao => pTributacao);
   
   pkgpag_geral.PAtualizaTotalizadoras(pcdfolhapagamento => pTributacao.pFolha.CdFolhaPagamento,
                                       pcdvinculo        => pcdvinculo);
                                          
   IF PKGPAG_VAR.vgVlTotalProventos <= 0 THEN
      RETURN;
   END IF;
   
   IF (PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario NOT IN (PKGPAG_TIPO.cnRegPrevGeral, pkgpag_tipo.cnRegPrevNaoPossui) OR
      PKGPAG_VAR.vgfolha.cdagrupamento <> CAGR_PMSC) AND -- militares
      PKGPAG_VAR.vgfolha.cdTipoFolha NOT IN (PKGPAG_TIPO.cnTpFolhaBEP) THEN
      
      PProcessaSCPREV(pTributacao => pTributacao);
      
   END IF;  
   
   PBuscarRubricaIsenta (pTributacao => pTributacao);
   
   PInsereBasesTributacao (pTributacao => pTributacao);

   pTributacao.irrf  := FParamIRRF  (pTributacao => pTributacao);
   pTributacao.iprev := FParamIPREV (pTributacao => pTributacao);
   pTributacao.inss  := FParamINSS  (pTributacao => pTributacao);
    
   ----------------------------------------------------------------------------------
   -- Caso o parametro do agrupamento indique que deve tributar o RRA separadamente
   ----------------------------------------------------------------------------------
   
   IF PKGPAG_RT.vgProcessoRetroativo.COUNT > 0 THEN
      
      PProcessaTributacaoRRA(pTributacao => pTributacao);
      
   END IF;
   
   ----------------------------------------------------------------------------------
   -- Tributacao Normal
   ----------------------------------------------------------------------------------
                     
   PProcessaTributacaoPrev(pTributacao     => pTributacao,
                           pTpTributacao   => CTRIB_TIPO_NORMAL,
                           pbPrima         => TRUE);

   PProcessaTributacaoFGTS(pTributacao     => pTributacao);
                                     
   PProcessaTributacaoIRRF(pTributacao       => pTributacao,
                           pTpTributacao     => CTRIB_TIPO_NORMAL,
                           pbPrima           => TRUE);
 
   ----------------------------------------------------------------------------------
   -- Tributacao de 13 salario
   ----------------------------------------------------------------------------------
   ---------------------------------------------------------------------------------
   -- Caso o valor da base para o IRRF/INSS de 13 seja maior que 0,
   -- ira processar a tributacao correspondente e reprocessar as pensoes
   ---------------------------------------------------------------------------------
 
   IF NOT PKGPAG_VAR.bReprocessou13Sal THEN
     
      IF pkgpag_var.vgVinculo.dtdesligamento <= pTributacao.pfolha.DtFimMes OR
         (FRetornaValorRubrica(pTributacao => pTributacao,
                               pCdRubrica  => PKGPAG_VAR.vgCdRubBaseIRRF13) > 0) OR
         (FRetornaValorRubrica(pTributacao => pTributacao,
                               pCdRubrica  => PKGPAG_VAR.vgCdRubBaseINSS13) > 0) OR                                          
                                             
         ((FRetornaValorRubrica(pTributacao => pTributacao,
                                pCdRubrica  => PKGPAG_VAR.vgCdRubExigibilidadeSusp) > 0 OR
                                
          (FRetornaValorRubrica(pTributacao => pTributacao,
                                pCdRubrica  => PKGPAG_VAR.vgCdRubExigibilidadeSusp13) > 0)) AND                            
         PKGPAG_VAR.vgFolha.CdTipoFolha IN
         (PKGPAG_TIPO.cnTpFolha13,
            PKGPAG_TIPO.cnTpFolhaAdiant13,
            PKGPAG_TIPO.cnTpFolhaCtisp13,
            PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp)) THEN
         
         vFlFolha13 := (pTributacao.pFolha.CdTipoFolha = 3);
                           
         PProcessaTributacaoPrev(pTributacao     => pTributacao,
                                 pTpTributacao   => CTRIB_TIPO_DECTER,
                                 pbPrima         => vFlFolha13);
 
         PProcessaTributacaoIRRF(pTributacao     => pTributacao,
                                 pTpTributacao   => CTRIB_TIPO_DECTER,
                                 pbPrima         => vFlFolha13);

         IF pTributacao.pFolha.CdTipoFolha IN
            (PKGPAG_TIPO.cnTpFolha13,
             PKGPAG_TIPO.cnTpFolhaAdiant13,
             PKGPAG_TIPO.cnTpFolhaResidente13,
             PKGPAG_TIPO.cnTpFolhaCtisp13,
             PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp) THEN
            
            -- A condicao acima deve ser retirada quando existir rubrica propria para pagamento de pensao sobre 13 salario
            -- a ser gerada automaticamente quando em folha normal que possuir rescisao de 13 salario
            
            PPensaoAlimenticia(pTributacao         => pTributacao,
                               pCdRubBaseIRRF      => PKGPAG_VAR.vgCdRubBaseIRRF13,
                               pCdRubAgrupDescIRRF => PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobre13,
                               pTpTributacao       => CTRIB_TIPO_DECTER,
                               pIndProcRetro       => NULL);
            
            -------------------------------------------------------------------------------------------------
            -- Transforma as rubricas de 13o sal?rio de pens?es aliment?cias, caso seja folha de 13 sal?rio
            -------------------------------------------------------------------------------------------------
            
            IF pTributacao.pFolha.CdTipoFolha IN
               (PKGPAG_TIPO.cnTpFolha13,
                PKGPAG_TIPO.cnTpFolhaResidente13,
                PKGPAG_TIPO.cnTpFolhaCtisp13) THEN
               
               BEGIN
                  
                  -- Apenas para o agrupamento dos militares 
                  --  PARA FOLHA DE 13:
                  --  ABATE O VALOR DESCONTADO NO ADIANTAMENTO NA RUBRICA 06-0586
                  IF PKGPAG_VAR.vgFolha.CdAgrupamento = CAGR_PMSC THEN
                     
                     UPDATE epagHistoricoRubricaVinculo HRV
                        SET HRV.CdRubricaAgrupamento =
                            (SELECT VAG.cdrubricaagrupamento -- retorna o valor do tipo rubrica 06
                               FROM VPAGRUBRICAAGRUPAMENTO VAG
                              WHERE VAG.cdagrupamento =
                                    PKGPAG_VAR.vgFolha.CdAgrupamento
                                AND VAG.cdtiporubrica = 6
                                AND VAG.nurubrica =
                                    (SELECT VA.nurubrica
                                       FROM VPAGRUBRICAAGRUPAMENTO VA
                                      WHERE VA.CDRUBRICAAGRUPAMENTO =
                                            PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensao13))
                      WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                        AND HRV.CdFolhaPagamento =
                            PKGPAG_VAR.vgFolha.CdFolhaPagamento
                        AND HRV.CdRubricaAgrupamento IN
                            (SELECT RA.CdRubricaAgrupamento
                               FROM EPagRubricaAgrupamento RA
                              INNER JOIN EPagRubrica R
                                 ON R.CdRubrica = RA.CdRubrica
                              WHERE RA.CdAgrupamento =
                                    PKGPAG_VAR.vgFolha.CdAgrupamento
                                AND R.CdTipoRubrica = 6
                                AND RA.FlPensaoAlimenticia = PKGPAG_TIPO.cnS);
                     
                  END IF;
                  
                  UPDATE epagHistoricoRubricaVinculo HRV
                     SET HRV.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupPensao13
                   WHERE HRV.CdVinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                     AND HRV.CdFolhaPagamento =
                         PKGPAG_VAR.vgFolha.CdFolhaPagamento
                     AND HRV.CdRubricaAgrupamento IN
                         (SELECT RA.CdRubricaAgrupamento
                            FROM EPagRubricaAgrupamento RA
                           INNER JOIN EPagRubrica R
                              ON R.CdRubrica = RA.CdRubrica
                           WHERE RA.CdAgrupamento =
                                 PKGPAG_VAR.vgFolha.CdAgrupamento
                             AND R.CdTipoRubrica = 5
                             AND RA.FlPensaoAlimenticia = PKGPAG_TIPO.cnS);
                  
                  -----------------------------------------------------------------------
                  -- Verifica se existe pensoes vigentes e caso a sentenca nao possua
                  -- a rubrica associada ao 13 de pensao, ela e incluida
                  -----------------------------------------------------------------------
                  
               EXCEPTION
                  WHEN OTHERS THEN
                     PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                             PKGPAG_VAR.vCdHistParamCalc,
                                             PKGPAG_VAR.vCdPessoa,
                                             'PKGPAG_TRIBUTACAO - Transforma rubricas 13° de pensões',
                                             PKGPAG_VAR.vgCdVinculo);
               END;
               
               --PAssociaRubricaPensao(pCdVinculo        => PKGPAG_VAR.vgVinculo.CdVinculo,
               --                      pFolha            => PKGPAG_VAR.vgFolha,
               --                      pFlAdiant13Pensao => 'N',
               --                      pFlPensao13       => 'S');
               
            END IF;
            
         END IF;
         
      END IF;
   
   END IF;
   
   ----------------------------------------------------------------------------------
   -- Tributacao de Ferias
   ----------------------------------------------------------------------------------
   
   ---------------------------------------------------------------------------------
   -- Caso o valor da base para o IRRF de ferias seja maior que 0,
   -- ira processar a tributacao correspondente e reprocessar as pensoes
   ---------------------------------------------------------------------------------
   
   IF PKGPAG_VAR.vgCdRubBaseIRRFFerias > 0 AND
      FRetornaValorRubrica(pTributacao => pTributacao,
                           pCdRubrica  => PKGPAG_VAR.vgCdRubBaseIRRFFerias) > 0 THEN
      
      PProcessaTributacaoIRRF(pTributacao       => pTributacao,
                              pTpTributacao     => CTRIB_TIPO_FERIAS,
                              pbPrima           => FALSE);
      
      IF pTributacao.pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaFerias) AND
         PKGPAG_VAR.vgParamPagamento.FlGeraPensaoFolhaFerias = 'S' THEN
         
         PPensaoAlimenticia(pTributacao         => pTributacao,   
                            pCdRubBaseIRRF      => PKGPAG_VAR.vgCdRubBaseIRRFFerias,
                            pCdRubAgrupDescIRRF => PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias,
                            pTpTributacao       => CTRIB_TIPO_FERIAS,
                            pIndProcRetro       => NULL);
         
      END IF;
      
   ELSE
      
      PKGPAG_GERAL.PExcluiRubrica(pTributacao.pFolha.CdFolhaPagamento,
                                  pCdVinculo,
                                  PKGPAG_VAR.vgCdRubBaseIRRFFerias,
                                  'S');
      
   END IF;
   
   /*-------------------------------------------------------------------------------
    -- Inicializa as variaveis para controle do recalculo do IRRF
    -- em virtude de pensoes alimenticias contidas dentro da formula do IRRF
   ---------------------------------------------------------------------------------*/
   
   IF pTributacao.pFolha.CdTipoFolha NOT IN
      (PKGPAG_TIPO.cnTpFolha13,
       PKGPAG_TIPO.cnTpFolhaAdiant13,
       PKGPAG_TIPO.cnTpFolhaResidente13,
       PKGPAG_TIPO.cnTpFolhaFerias,
       PKGPAG_TIPO.cnTpFolhaCtisp13,
       PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp) THEN

      PPensaoAlimenticia(pTributacao         => pTributacao,
                         pCdRubBaseIRRF      => PKGPAG_VAR.vgCdRubBaseIRRF,
                         pCdRubAgrupDescIRRF => PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF,
                         pTpTributacao       => CTRIB_TIPO_NORMAL,
                         pIndProcRetro       => NULL);
      -- Para as pensões alimentícias que possuem LF por valor, só atualiza valor após o cálculo de pensões
      -- uma vez que a rotina de calculo das pensões normal e RRA é a mesma.
      PPossuiLancFinanceiroPensao(pCdVinculo, pTributacao.pFolha);
   END IF;
   
   -------------------------------------------------------------------------------------------------
   --  Se variavel vgValorBaseIRRF e setada na Tributacao
   -------------------------------------------------------------------------------------------------

   vVlBaseIRRF13 := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pCdRubrica  => PKGPAG_VAR.vgCdRubBaseIRRF13);
   
   vVlBaseIRRF   := FRetornaValorRubrica(pTributacao => pTributacao,
                                         pCdRubrica  => pTributacao.irrf.CdRubBaseIRRF);

   
   IF vVlBaseIRRF > 0 OR vVlBaseIRRF13 > 0 THEN
      
      ------------------------------------------------------------------------------------
      -- Insere rubrica automatica (Modalidade 38)
      -- Desde que tenha mais de 65 anos e seja inativo e nao esteja isento de IRRF
      ------------------------------------------------------------------------------------

      pDebug ('pTributacao.irrf.vlDeducaoInativoReal:' || pTributacao.irrf.vlDeducaoInativoReal);
      
      IF pTributacao.irrf.FlAplicaDeducaoInativo THEN
         pDebug ('aplicaDeducaoInativo');
      END IF;   
     
      IF pTributacao.irrf.FlIsentoIRRF THEN
         pDebug ('isento IRRF');
      END IF;       

      IF NVL(pTributacao.irrf.vlDeducaoInativoReal, 0) > 0 AND
         pTributacao.irrf.FlAplicaDeducaoInativo AND
         NOT pTributacao.irrf.FlIsentoIRRF THEN
         
         PAlterarLancamentoVinculo (pCdFolhaPagamento        => pTributacao.pFolha.CdFolhaPagamento,
                                    pCdVinculo               => pCdVinculo,
                                    pCdRubricaAgrupamento    => PKGPAG_VAR.vgCdRubBaseDeducaoInativo,
                                    pVlPagamento             => pTributacao.irrf.vlDeducaoInativoReal);

      END IF;
      
   END IF;
      
   PGeraPatronalParaAfastado(pFolha   => pTributacao.pFolha,
                             pVinculo => PKGPAG_VAR.vgVinculo);
   
   IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = 2 THEN
      
      -- SÓ calcula se não tiver valor
      IF PKGPAG_VAR.vgCdRubBaseIPREVFF IS NOT NULL THEN
         
         BEGIN
            SELECT 1
              INTO vCont
              FROM EPagHistoricoRubricaVinculo HRV
             WHERE HRV.CdFolhaPagamento = pTributacao.pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento =
                   PKGPAG_VAR.vgCdRubBaseIPREVFF
               AND HRV.Vlpagamento > 0
               AND ROWNUM < 2;
            
         EXCEPTION
            
            WHEN NO_DATA_FOUND THEN
               
               PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                                pCdVinculo       => pCdVinculo,
                                                pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIPREVFF,
                                                pTpProcessamento => 2,
                                                pTpLocal         => 2); /*Vinculo*/
            
         END;
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseProv13PatFF,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseIPREVFP IS NOT NULL THEN
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIPREVFP,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseProv13PatFP,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
      END IF;
      
      IF PKGPAG_VAR.vgCdRubBaseIPREVFT IS NOT NULL AND
         PKGPAG_GERAL.FRetornaRegimeProprioPrev(pCdVinculo) = 4 THEN
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseIPREVFT,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => pTributacao.pFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseProv13FT,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2); /*Vinculo*/
         
      END IF;
      
   END IF;
  
   PExcluirRubricaDescDepIRRF(pCdFolhaPagamento => pTributacao.pFolha.cdFolhaPagamento,
                              pCdVinculo        => pCdVinculo,
                              pValorBaseIRRF    => vVlBaseIRRF,
                              pValorBaseIRRF13  => vVlBaseIRRF13);

   -- Processa bases que dependem da bases de Tributacao
         
   IF pTributacao.pFolha.CdAgrupamento = CAGR_CIDASC 
      AND pTributacao.rub.CdRubPatronalAssociacao IS NOT NULL THEN
      
      PProcessaBase (pTributacao => pTributacao,
                     pCdRubrica  => pTributacao.rub.CdRubPatronalAssociacao);
   END IF;
   
   PDebug ('--- Saída PProcessaTributacaoEPensao');

   PKGPAG_GERAL.PLogProcFim ('TRI');
    
END;

PROCEDURE PInicializarVinculo (pTributacao IN OUT NOCOPY rTributacao) IS  
BEGIN
   pTributacao.inss.VlALiquotaContribIndiv  := NULL;
END;

PROCEDURE PSetaRubricasIsentas(pFolha     IN PKGPAG_TIPO.rFolha,
                               pCdVinculo IN INTEGER) IS
     
   vNuIsentaRubFormula    INTEGER; 
   vNuIsencaoParcialIPREV INTEGER;
  
BEGIN

   PKGPAG_VAR.bDescRubIsentaFormula  := FALSE;  
   bIsencaoParcialIPREV              := FALSE;
     
   SELECT SUM(CASE
                 WHEN TR.FlRubricaIsentaFormula = 'S' THEN
                  1
                 ELSE
                  0
              END),
           
          SUM(CASE
                 WHEN tr.cdrubricaagrupamento = PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIPESC 
                    AND TR.FlRubricaIsentaIPESC = 'S' THEN
                   1
                 ELSE
                   0
              END)             
     INTO vNuIsentaRubFormula,vNuIsencaoParcialIPREV
     FROM ETrbIsencaoRubrica TR
    INNER JOIN ETrbHistIsencaoRubrica HTR
       ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
    WHERE TR.CdVinculo = pCdVinculo
      AND ((HTR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
          (HTR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
          HTR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
          (HTR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
          (HTR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
          HTR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
          HTR.NuMesFimVigencia IS NULL));

   IF vNuIsentaRubFormula > 0 THEN
      
      PKGPAG_VAR.bDescRubIsentaFormula := TRUE;
      
   END IF; 
        
   IF vNuIsencaoParcialIPREV > 0 THEN
      
      bIsencaoParcialIPREV := TRUE;
      
   END IF;  
   
EXCEPTION
   
   WHEN NO_DATA_FOUND THEN
      
      NULL;
      
   WHEN OTHERS THEN
      
      NULL;
      
END;

FUNCTION FTabOrgaoSIGRH RETURN tOrgSIGRH IS
   vTabOrgSIGRH   tOrgSIGRH;
   
BEGIN
   vTabOrgSIGRH.DELETE;
   
   FOR rec IN (SELECT NUCNPJ 
                 FROM VCADORGAO o
                WHERE EXISTS (SELECT 1
                               FROM epagfolhapagamento fp
                              inner join epagtipofolhapagamento tfp
                                 on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
                                and tfp.cdtipofolha = 1  
                              where cdorgao = o.CdOrgao) ) LOOP
      vTabOrgSIGRH (rec.NUCNPJ) := 1;                    
   END LOOP;
   
   RETURN vTabOrgSIGRH;
     
END;

FUNCTION FCarregarRubTrib (pTributacao IN rTributacao) RETURN PKGPAG_TIPO.tLista IS
   
   vLstRubTrib    PKGPAG_TIPO.tLista;

   PROCEDURE PAdicionar (pCdRubricaAgrupamento IN INTEGER) IS
      
   BEGIN
      IF pCdRubricaAgrupamento IS NOT NULL THEN
         vLstRubTrib(pCdRubricaAgrupamento) := 1;          
      END IF;
   
   END;


BEGIN
   vLstRubTrib.DELETE;
   
   PAdicionar (pTributacao.inss.CdRubAgrupDescINSS);
   PAdicionar (pTributacao.inss.CdRubAgrupDescINSS13); 
   PAdicionar (PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF);
   PAdicionar (PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobre13);
   PAdicionar (PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias);    

   RETURN vLstRubTrib;
END;

PROCEDURE PInicializarControle (pTributacao OUT PKGPAG_TRIBUTACAO.rTributacao,
                                pFolha       IN PKGPAG_TIPO.rFolha) IS

   vIdentRubrica           PKGPAG_TIPO.rIdentRubrica;
BEGIN

   pTributacao.pFolha := pFolha;
   pTributacao.totRub := PKGPAG_PARAM.FCargaRubTotalizadora (pCdAgrupamento   => NULL,
                                                             pCdOrgao         => NULL,
                                                             pNuAnoReferencia => pTributacao.pFolha.NuAnoReferencia,
                                                             pNuMesReferencia => pTributacao.pFolha.NuMesReferencia);
 
                                                             
   pTributacao.FolPermitida := FFolPermitida (pCdFolhaPagamento => pTributacao.pFolha.CdFolhaPagamento);

   PIdentificarRubricas (pCdAgrupamento => pTributacao.pFolha.CdAgrupamento, pRub => pTributacao.rub);
  
   pTributacao.inss := FInicializaINSS (pTributacao => pTributacao);  
   
   pTributacao.inss.VlTetoDescINSS := FTetoDescINSS;
 
   pTributacao.inss.VlTetoDescINSSContribIndiv := FTetoDescINSSContribIndiv  (pNuAnoReferencia => pTributacao.pFolha.NuAnoReferencia,
                                                                              pNuMesReferencia => pTributacao.pFolha.NuMesReferencia);
   pTributacao.inss.inssControle := PKGPAG_INSS.FInicializarControle; 
   
   pTributacao.inss.orgSIGRH := FTabOrgaoSIGRH;
 
   pTributacao.lstRubTrib := FCarregarRubTrib (pTributacao => pTributacao);

   IF pkgpag_var.vgValorReferenciaMAXINSS > 0
      AND pkgpag_var.vgValorReferenciaMAXINSS <> pTributacao.inss.VlTetoDescINSS THEN
 
      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Valor de Referência de Teto de INSS difere do teto informado na tabela de faixas de INSS',
                              PKGPAG_VAR.vgCdVinculo);
                                   
   END IF; 

END;

END PKGPAG_TRIBUTACAO;
/
