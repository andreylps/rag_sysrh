CREATE OR REPLACE PACKAGE PKGPAG_TIPO IS

/*-------------------------------------------------------------------------------------/
  CONSTANTES
/*--------------------------------------------------------------------------------------*/

/* Numero de meses correspondente a 65 anos */

  cnMesesIdadeApo         CONSTANT NUMBER(3) := 780;

/* Numero de meses correspondente a 70 anos */

  cnMesesIdade70          CONSTANT NUMBER(3) := 840;

/* Constantes de Relac?o de Trabalho */

  cnRelResidente          CONSTANT NUMBER(1) := 1;

  cnRelEstagiario         CONSTANT NUMBER(1) := 2;

  cnRelTrabEfetivo        CONSTANT NUMBER(1) := 5;

  cnRelACT                CONSTANT NUMBER(1) := 3;

  cnRelTrabMilitar        CONSTANT NUMBER(1) := 8;

  cnRelTrabDisposicao     CONSTANT NUMBER(2) := 10;

  cnRelPesquisador        CONSTANT NUMBER(2) := 16;

  cnRelCTISP              CONSTANT NUMBER(2) := 17;

/* Constantes de Tipo de Calculo */

  cnTpCalculoNormal       CONSTANT NUMBER(2) := 1;

  cnTpCalculoSimulacao    CONSTANT NUMBER(2) := 2;

  cnTpCalculoRecalculoMes CONSTANT NUMBER(2) := 3;

  cnTpCalculoRetroativo   CONSTANT NUMBER(2) := 4;

  cnTpCalculoSupl         CONSTANT NUMBER(2) := 5;

  cnTpCalculoRecalcCompl  CONSTANT NUMBER(2) := 6;

  cnTpCalculoPrimeiro     CONSTANT NUMBER(2) := 7;

  cnTpCalculoSegundo      CONSTANT NUMBER(2) := 8;

  cnTpCalculoPrevia       CONSTANT NUMBER(2) := 9;

  cnTpCalculoAnterior     CONSTANT NUMBER(2) := 10;

  cnTpCalculoExcluido     CONSTANT NUMBER(2) := 11;

  cnTpCalculoDifMes       CONSTANT NUMBER(2) := 12;

  cnTpCalculoTesteRegressao   CONSTANT NUMBER(2) := 13;

  cnTpCalculoTesteRegressaoAnt CONSTANT NUMBER(2) := 14;

  cnTpCalculoIndividualGeral CONSTANT NUMBER(2) := 15;

  cnTpCalculoIndividualGeralAnt CONSTANT NUMBER(2) := 16;

  /* Constantes de Tipo de Relacao */

  cnTpRelacaoEfetivo         CONSTANT INTEGER := 1;

  cnTpRelacaoComissionado    CONSTANT INTEGER := 2;

  cnTpRelacaoFuncaoChefia    CONSTANT INTEGER := 3;

  cnTpRelacaoAposentadoria   CONSTANT INTEGER := 4;

  cnTpRelacaoEstagio         CONSTANT INTEGER := 5;

  cnTpRelacaoPensaoPrev      CONSTANT INTEGER := 6;

  cnTpRelacaoPensaoNaoPrev   CONSTANT INTEGER := 7;

  cnTpRelacaoExParlamentar   CONSTANT INTEGER := 8;

  cnTpRelacaoAuxilioReclusao CONSTANT INTEGER := 9;

  /* Constante de Tipo de Global que contem a relacao */

  cnRelVincCEF               CONSTANT CHAR := 'A';

  cnRelVincFUC               CONSTANT CHAR := 'B';

  cnRelVincFUCSubst          CONSTANT CHAR := 'C';

  cnRelVincCCO               CONSTANT CHAR := 'D';

  cnRelVincCCOSubst          CONSTANT CHAR := 'E';

  cnRelVincAPO               CONSTANT CHAR := 'F';

  cnRelVincAPOSemParidade    CONSTANT CHAR := 'G';

  cnRelVincBOL               CONSTANT CHAR := 'H';

  cnRelVincPensaoNaoPrev     CONSTANT CHAR := 'I';

/* Constantes de Fase de Calculo */

  cnFaseCalculoIntegral     CONSTANT INTEGER := 1;

  cnFaseCalculoSuplementar  CONSTANT INTEGER := 2;

/* Constantes de Tipo de Rubrica */

  cnTpRubDevDesc          CONSTANT NUMBER(1) := 4;

  cnTpRubDesconto         CONSTANT NUMBER(1) := 5;

  cnTpRubDifDesc          CONSTANT NUMBER(1) := 6;

  cnTpRubTotalizadora     CONSTANT NUMBER(1) := 9;

  /* Contantes de Situacoes previdenciarias */

  cnSitPrevAtivo              CONSTANT NUMBER(2) := 1;

  cnSitPrevAposentado         CONSTANT NUMBER(2) := 2;

  cnSitPrevInstPensao         CONSTANT NUMBER(2) := 3;

  cnSitPrevPensaoNaoPrev      CONSTANT NUMBER(2) := 4;

  cnSitPrevFalecidoSemPensao  CONSTANT NUMBER(2) := 5;

  cnSitPrevSemVincPrev        CONSTANT NUMBER(2) := 6;

  cnSitPrevApoEncerrada       CONSTANT NUMBER(2) := 7;

  cnSitPrevApoCompulsoria     CONSTANT NUMBER(2) := 8;

  cnSitPrevPensaoPrev         CONSTANT NUMBER(2) := 9;

  cnSitPrevAuxilioReclusao    CONSTANT NUMBER(2) := 10;

  cnSitPrevExParlamentar      CONSTANT NUMBER(2) := 11;

  cnSitPrevFalecido           CONSTANT NUMBER(2) := 12;

/* Contantes de Tipo de Folha */

  cnTpFolhaNormal           CONSTANT NUMBER(2) := 1;

  cnTpFolhaRescisao         CONSTANT NUMBER(2) := 2;

  cnTpFolha13               CONSTANT NUMBER(2) := 3;

  cnTpFolhaFerias           CONSTANT NUMBER(2) := 4;

  cnTpFolhaAdiant13         CONSTANT NUMBER(2) := 5;

  cnTpFolhaInstPensao       CONSTANT NUMBER(2) := 6;

  cnTpFolhaAposentadoria    CONSTANT NUMBER(2) := 7;

  cnTpFolhaAposentadoria13  CONSTANT NUMBER(2) := 8;

  cnTpFolhaAposAdiant13     CONSTANT NUMBER(2) := 9;

  cnTpFolhaOutras           CONSTANT NUMBER(2) := 10;

  cnTpFolhaBolsista         CONSTANT NUMBER(2) := 11;

  cnTpFolhaResidente        CONSTANT NUMBER(2) := 12;

  cnTpFolhaNormalCalcAnt    CONSTANT NUMBER(2) := 13;

  cnTpFolhaResidente13      CONSTANT NUMBER(2) := 14;

  cnTpFolhaPesquisador      CONSTANT NUMBER(2) := 15;

  cnTpFolhaComissionadoPuro CONSTANT NUMBER(2) := 16;

  cnTpFolhaFunebre          CONSTANT NUMBER(2) := 17;

  cnTpFolhaFunebre13        CONSTANT NUMBER(2) := 18;

  cnTpFolhaCtisp            CONSTANT NUMBER(2) := 19;

  cnTpFolhaCtisp13          CONSTANT NUMBER(2) := 20;

  cnTpFolhaAdiant13Ctisp    CONSTANT NUMBER(2) := 21;

  cnTpFolhaServAfast          CONSTANT NUMBER(2) := 22;

  cnTpFolhaRescisaoEstagiario CONSTANT NUMBER(2) := 23;

  cnTpFolhaBEP                CONSTANT NUMBER(2) := 24;

  cnTpFolhaRescisaoPesquisador CONSTANT NUMBER(2) := 25;

  cnTpFolhaProdex13         CONSTANT NUMBER(2) := 26;

  cnTpFolhaHonorarios13     CONSTANT NUMBER(2) := 27;

  cnTpFolhaHonorarProcuradores13 CONSTANT NUMBER(2) := 28;
  
  cnTpFolhaConvenio              CONSTANT NUMBER(2) := 29;


/* Constantes de Modalidade de rubrica  */

  cnModRubSalIPESC        CONSTANT NUMBER(2) := 1;

  cnModRubSalBaseINSS     CONSTANT NUMBER(2) := 2;

  cnModRubBaseIRRF        CONSTANT NUMBER(2) := 3;

  cnModRubBaseIRRFFerias  CONSTANT NUMBER(2) := 4;

  cnModRubBaseValeTransp  CONSTANT NUMBER(2) := 7;

  cnModRubSalBaseINSSPat  CONSTANT NUMBER(2) := 11;

  cnModRubSalBaseINSS13   CONSTANT NUMBER(2) := 12;

  cnModRubSalBaseIRRF13   CONSTANT NUMBER(2) := 13;

  cnModRubSalBaseIPESC13  CONSTANT NUMBER(2) := 15;

  cnModRubBaseCSGProcCC   CONSTANT NUMBER(2) := 30;

  cnModRubBaseFGTS        CONSTANT NUMBER(2) := 31;

  cnModRubBaseFGTS13      CONSTANT NUMBER(2) := 32;

  cnModRubVlFGTS          CONSTANT NUMBER(2) := 33;

  cnModRubVlFGTS13        CONSTANT NUMBER(2) := 47;

  cnModRubBaseIPREVFP     CONSTANT NUMBER(2) := 34;

  cnModRubBaseIPREVFF     CONSTANT NUMBER(2) := 35;

  cnModRubBaseINSSCLT     CONSTANT NUMBER(2) := 37;

  cnModRubBaseDeducaoInativo CONSTANT NUMBER(2) := 38;

/* Constantes de Regime de Trabalho */

  cnRegTrabCLT            CONSTANT NUMBER(1) := 1;

  cnRegTrabEstatutario    CONSTANT NUMBER(1) := 2;

  cnRegTrabAdmEspecial    CONSTANT NUMBER(1) := 3;

/* Constantes de Regime Previdenciario */

  cnRegPrevGeral          CONSTANT NUMBER(1) := 1;

  cnRegPrevProprio        CONSTANT NUMBER(1) := 2;

  cnRegPrevNaoPossui      CONSTANT NUMBER(1) := 3;

  cnRegPrevPropOutros     CONSTANT NUMBER(1) := 4;

  cnRegPrevCPSM           CONSTANT NUMBER(1) := 5;

/* Constantes de Tributacao do IPESC/IPREV */

  cnTpTrbAtivo            CONSTANT NUMBER(1) := 1;

  cnTpTrbInativo          CONSTANT NUMBER(1) := 2;

  cnTpTrbParcial          CONSTANT NUMBER(1) := 3;

  cnN                     CHAR(1) := 'N';

  cnS                     CHAR(1) := 'S';

  cnD                     CHAR(1) := 'D';

  cnR                     CHAR(1) := 'R';

  cnT                     CHAR(1) := 'T';

  cnP                     CHAR(1) := 'P';

  cnQ                     CHAR(1) := 'Q';

  cn1                     INTEGER := 1;

  cn2                     INTEGER := 2;

/* >>> COLOCAR NOME NESSA SECAO <<< */

  cnTipoModInvalidez      INTEGER := 2;

  cnDtMax                 DATE := TO_DATE('01/01/4000', 'DD/MM/YYYY');

/* Constantes para verificacao de Afastamento */

  cnAfastadoNao          CHAR(1) := 'N';

  cnAfastadoMesTodo      CHAR(1) := 'M';

  cnAfastadoParcial      CHAR(1) := 'P';

/* Constantes de Folha para Tributacao */

  cnSgTribIRRF           VARCHAR2(4) := 'IRRF';
  cnSgTribIPRV           VARCHAR2(4) := 'IPRV';
  cnSgTribINSS           VARCHAR2(4) := 'INSS';
  cnSgTribCPSM           VARCHAR2(4) := 'CPSM';

  cnTpMesTribAtual       CHAR(1) := 'M';
  cnTpMesTribCaixa       CHAR(1) := 'C';

/* Constantes de Tarefas, Agendamentos, Monitoramento e Controle */

  cnTimeOutEscutaSinalJobs pls_integer := 600; -- em segundos

  -- atualmente, no x86, está calculando em media 25 pessoas por segundo,
  --   mas para monitoramento da pra considerar um pouco menos da metade como margem
  cnQtMediaPessoasPorSegundo pls_integer := 10;

/*--------------------------------------------------------------------------------------/
  TIPOS
/*--------------------------------------------------------------------------------------*/

  TYPE rVinculo IS RECORD
    (CdVinculo                INTEGER,
     CdPessoa                 INTEGER,
     CdOrgao                  INTEGER,
     NuSeqMatricula           INTEGER,
     CdSituacaoPrevidenciaria INTEGER,
     CdRegimeTrabalho         INTEGER,
     CdRegimePrevidenciario   INTEGER,
     DtAdmissao               DATE,
     DtDesligamento           DATE,
     DtNascimento             DATE,
     DtInclusao               DATE,
     FlSexo                   CHAR(1),
     CdOpcaoAuxilioAli        INTEGER,
     FlPagamentoBloqueado     CHAR(1),
     bPossuiObito             BOOLEAN,
     FlOutroVincCalculado     CHAR(1),
     FlOutroVincACalcular     CHAR(1),
     CdFolhaPagamentoNormal   INTEGER,
     CdTipoRegimeProprioPrev  INTEGER,
     PercAtsJudDeterminado    INTEGER -- 18925 - Tiago Von
    );

  TYPE rTipoTabelaCEF IS RECORD
    (CdTabelaUtilizada      INTEGER,
     CdHistNivelRefCefGeral INTEGER,
     CdHistNivelRefCefAgrup INTEGER,
     CdHistNivelRefCefOrgao INTEGER,
     CdValorGeralCEFAgrup   INTEGER);

  TYPE rCargaHoraria IS RECORD
    (NuCargaHoraria  NUMBER(7,4),
     NuCargaHorariaPadrao NUMBER(7,4),
     DtInicio        DATE,
     DtFim           DATE,
     NuChoMensal     NUMBER(7,4),
     NuDiasTrabalhados INTEGER,
     CdHistCargoEfetivo ECadHistCargoEfetivo.CdHistCargoEfetivo%TYPE,
     CdTipoRelacao   NUMBER,
     CdHist          NUMBER,
     NuCargaHorariaTotal NUMBER(7,4));

  TYPE tCargaHoraria IS TABLE OF rCargaHoraria INDEX BY PLS_INTEGER;

  TYPE rValorFixo IS RECORD
    (CdEstruturaCarreira   INTEGER,
     NuNivel               VARCHAR2(3),
     NuReferencia          VARCHAR2(3),
     VlFixo                NUMBER(13,2),
     NuCargaHoraria        NUMBER(7,4),
     DtUltAlteracao        TIMESTAMP,
     CdValorGeralCEFAgrup  INTEGER);

  TYPE rValorCalculoRubrica IS RECORD
    (CdRubricaAgrupamento  INTEGER,
     CdVinculo             INTEGER,
     VlCef                 NUMBER(13,2),
     VlFuc                 NUMBER(13,2),
     VlCCo                 NUMBER(13,2),
     VlApo                 NUMBER(13,2),
     CdRelacaoVinculo      INTEGER,
     VlIndice              NUMBER(13,4),
     DeFormulaExpressao    VARCHAR2(400),
     VlLimiteInferior      NUMBER(13,4));

  TYPE tValorCalculoRubrica IS TABLE OF rValorCalculoRubrica INDEX BY PLS_INTEGER;

  TYPE rOrgao IS RECORD
    (CdOrgao             INTEGER,
     InLotadoExercicio   CHAR(1));

  TYPE tListaValor IS TABLE OF NUMBER(16,6) INDEX BY PLS_INTEGER;

  TYPE rValorReferencia IS RECORD
    (CdValorReferencia     EPagValorReferencia.CdValorReferencia%TYPE,
     VlReferencia          EPagHistValorReferencia.VlReferencia%TYPE,
     FlValeTransporte      EPagValorReferencia.FlValeTransporte%TYPE,
     FlBloqueioRemuneracao EPagValorReferencia.FlBloqueioRemuneracao%TYPE,
     Sgvalorreferencia     EPagValorReferencia.Sgvalorreferencia%TYPE,
     lsValRefCarreira      tListaValor,
     lsValRefPrograma      tListaValor);

  TYPE tValorReferencia IS TABLE OF rValorReferencia INDEX BY PLS_INTEGER;

  TYPE tValorFixo IS TABLE OF rValorFixo INDEX BY PLS_INTEGER;

  TYPE tListaIndVarChar IS TABLE OF INTEGER INDEX BY VARCHAR2(100);
  
  TYPE tLista IS TABLE OF INTEGER INDEX BY PLS_INTEGER;

  TYPE tListaNumber IS TABLE OF TYPENUMBER INDEX BY PLS_INTEGER;

  TYPE tListaOrgao IS TABLE OF rOrgao INDEX BY PLS_INTEGER;

  TYPE rMotAfastTempEx IS RECORD
    (cdhistrubricaagrupamento EPAGRUBAGRUPMOTAFASTTEMPEX.CDHISTRUBRICAAGRUPAMENTO%TYPE,
     cdmotivoafasttemporario  EPAGRUBAGRUPMOTAFASTTEMPEX.CDMOTIVOAFASTTEMPORARIO%TYPE,
     nuperiodo                EPAGRUBAGRUPMOTAFASTTEMPEX.Nuperiodo%TYPE,
     cdperiodoafastamento     EPAGRUBAGRUPMOTAFASTTEMPEX.CdPeriodoAfastamento%TYPE);

  TYPE tMotAfasTempEx IS TABLE OF rMotAfastTempEx  INDEX BY PLS_INTEGER;

TYPE rMotAfastTempImp IS RECORD
    (cdhistrubricaagrupamento EPAGRUBAGRUPMOTAFASTTEMPEX.CDHISTRUBRICAAGRUPAMENTO%TYPE,
     cdmotivoafasttemporario  EPAGRUBAGRUPMOTAFASTTEMPEX.CDMOTIVOAFASTTEMPORARIO%TYPE);

  TYPE tMotAfastTempImp IS TABLE OF rMotAfastTempImp  INDEX BY PLS_INTEGER;

  TYPE rRegCarreira IS RECORD
   (CdEstruturaCarreira      INTEGER,
    CdEstruturaCarreiraPai   INTEGER,
    NuCargaHoraria           NUMBER(7,4)
    );

  TYPE tCarreira is table of rRegCarreira INDEX BY PLS_INTEGER;

  TYPE rMotMovInstituto IS RECORD
    (CdMotivoMovimentacao    INTEGER,
     CdInstitutoMovimentacao INTEGER);

  TYPE tListaMovInstituto IS TABLE OF rMotMovInstituto INDEX BY PLS_INTEGER;

  TYPE rValorPagamento IS RECORD
    (vlIntegral       NUMBER,
     vlProporcional   NUMBER,
     vlReal           NUMBER,
     vlIndice         NUMBER,
     deexpressao      VARCHAR2(200)); -- SIG-2630);

  TYPE rExprPagamento IS RECORD
    (DeExprIntegral       VARCHAR2(500),
     DeExprProporcional   VARCHAR2(500),
     DeExprReal           VARCHAR2(500));

  TYPE rFolha IS RECORD
    (CdFolhaPagamento              Epagfolhapagamento.CdFolhaPagamento%TYPE,
     CdOrgao                       Epagfolhapagamento.cdOrgao%TYPE,
     CdAgrupamento                 Epagfolhapagamento.cdOrgao%TYPE,
     NuAnoReferencia               Epagfolhapagamento.nuAnoReferencia%TYPE,
     NuMesReferencia               Epagfolhapagamento.nuMesReferencia%TYPE,
     CdTipoFolhaPagamento          Epagfolhapagamento.CdTipoFolhaPagamento%TYPE,
     CdTipoFolha                   Epagtipofolhapagamento.Cdtipofolha%TYPE,
     CdTipoCalculo                 Epagfolhapagamento.CdTipoCalculo%TYPE,
     NuVersaoTabcef                Epagfolhapagamento.Nuversaotabcef%TYPE,
     NuVersaoTabfuc                Epagfolhapagamento.Nuversaotabfuc%TYPE,
     NuVersaoTabcco                Epagfolhapagamento.Nuversaotabcco%TYPE,
     NuVersaoTabValorReferencia    Epagfolhapagamento.Nuversaotabvalorreferencia%TYPE,
     NuVersaoBaseCalculo           Epagfolhapagamento.Nuversaobasecalculo%TYPE,
     NuVersaoFormulaCalculo        Epagfolhapagamento.Nuversaoformulacalculo%TYPE,
     FlLancamentoFinanceiro        Epagfolhapagamento.FlLancamentoFinanceiro%TYPE,
     FlLancFinancComplementar      Epagfolhapagamento.Fllancfinanccomplementar%TYPE,
     CdFolhaVincSupl               Epagfolhapagamento.CdFolhaVincSupl%TYPE,
     CdFolhaOrigem                 Epagfolhapagamento.CdFolhaOrigem%TYPE,
     CdHistTipoFolhaPagamento      EPagHistTipoFolhaPagamento.cdHistTipoFolhaPagamento%TYPE,
     FlPagaTodasRubricas           EPagHistTipoFolhaPagamento.flPagaTodasRubricas%TYPE,
     InPagamentoRubrica            EPagHistTipoFolhaPagamento.Inpagamentorubrica%TYPE,
     FlCalculoDefinitivo           EPagFolhaPagamento.FlCalculoDefinitivo%TYPE,
     DtPrevisaoCredito             EPagFolhaPagamento.DtPrevisaoCredito%TYPE,
     DtInicioMes                   DATE,
     DtFimMes                      DATE,
     FlIncluiFerias                EPagHistTipoFolhaPagamento.FlIncluiFerias%TYPE,
     FlIncluiAdiantamento13        EPagHistTipoFolhaPagamento.FlIncluiAdiantamento13%TYPE,
     FlOrgaoImplantado             ECadOrgao.FlImplantado%TYPE,
     NuAnoMesImplantacao           ECadOrgao.NuAnoMesImplantacao%TYPE,
     DtAbertura                    EPagFolhaPagamento.DtAbertura%TYPE,
     DtCalculo                     EPagFolhaPagamento.DtCalculo%TYPE,
     CdFolhaPagamentoNormal        EPagFolhaPagamento.CdFolhaPagamento%TYPE,
     CdFolhaPagamentoNormalAnt     EPagFolhaPagamento.CdFolhaPagamento%TYPE,
     DtCalculoAnt                  EPagFolhaPagamento.DtCalculo%TYPE,
     NuSequencialFolha             EPagFolhaPagamento.NuSequencialFolha%TYPE,
     FlIgnoraInclusaoFutura        EPagFolhaPagamento.FlIgnoraInclusaoFutura%TYPE,
     CdTipoOrgao                   ECadHistOrgao.CdTipoOrgao%TYPE,
     NuAnoMesReferencia            EPagFolhaPagamento.NuAnoMesReferencia%TYPE,
     DeOrdemExecucao               EPagFolhaPagamento.DeOrdemExecucao%TYPE      
    );

  TYPE rAuxilioAli IS RECORD
    (CdParametroOrgao          EAliParametroOrgao.CdParametroOrgao%TYPE,
     FlPecunia                 EAliParametroOrgao.FlPecunia%TYPE,
     NuDiaInicioApuracao       EAliParametroOrgao.NuDiaInicioApuracao%TYPE,
     NuDias                    EAliParametroOrgao.NuDias%TYPE,
     NuDiasLimite              EAliParametroOrgao.NuDiasLimite%TYPE,
     FlDescontaFeriado         EAliParametroOrgao.FlDescontaFeriado%TYPE,
     FlDescontaPontoFacul      EAliParametroOrgao.FlDescontaPontoFacul%TYPE,
     FlDescontaPontoFaculComp  EAliParametroOrgao.FlDescontaPontoFaculComp%TYPE,
     FlDescontaFalta           EAliParametroOrgao.FlDescontaFalta%TYPE,
     CdOperacaoAbatimento      EAliParametroOrgao.CdOperacaoAbatimento%TYPE,
     InCompetenciaApuracaoDias EAliParametroOrgao.InCompetenciaApuracaoDias%TYPE,
     FlPriorizaCCO             EAliParametroOrgao.FlPriorizaCCO%TYPE,
     CdValorAuxilio            EAliValorAuxilio.CdValorAuxilio%TYPE,
     VlAuxilioCEF              EAliValorAuxilio.VlAuxilioCEF%TYPE,
     VlAuxilioCCO              EAliValorAuxilio.VlAuxilioCCO%TYPE,
     CdBaseCalculo             EAliValorAuxilio.CdBaseCalculo%TYPE,
     CdRubricaAgrupamento      EPagRubricaAgrupamento.CdRubricaAgrupamento%TYPE,
     FlVerificaVinculo         BOOLEAN,
     FlVerificaUO              BOOLEAN,
     FlVerificaCarreira        BOOLEAN,
     lsOpcaoRemuneracao        tLista,
     lsRelTrab                 tLista,
     lsSitPrev                 tLista);

  TYPE tAuxilioAli IS TABLE OF rAuxilioAli INDEX BY PLS_INTEGER;

  TYPE rEvento IS RECORD
    (CdEventoPagAgrup           Epageventopagagrup.CdEventoPagAgrup%TYPE,
     CdHistEventoPagAgrup       EpagHisteventopagagrup.CdHistEventoPagAgrup%TYPE,
     CdAgrupamento              Epageventopagagrup.CdAgrupamento%TYPE,
     CdRubricaAgrupamento       Epageventopagagrup.CdRubricaAgrupamento%TYPE,
     CdRubAgrupAlternativa1     Epageventopagagrup.CdRubAgrupOpRecebCCO%TYPE,
     CdRubAgrupAlternativa2     Epageventopagagrup.CdRubricaAgrupAlternativa2%TYPE,
     CdRubAgrupAlternativa3     Epageventopagagrup.CdRubricaAgrupAlternativa3%TYPE,
     CdTipoEventoPagamento      Epageventopagagrup.CdTipoEventoPagamento%TYPE,
     DeEvento                   Epageventopagagrup.DeEvento%TYPE,
     CdTipoRubrica              EPagRubrica.CdTipoRubrica%TYPE,
     NuRubrica                  EPagRubrica.NuRubrica%TYPE,
     CdTipoFuncaoChefia         Epaghisteventopagagrup.CdTipoFuncaoChefia%TYPE,
     CdRelacaoTrabalho          Epaghisteventopagagrup.CdRelacaoTrabalho%TYPE,
     CdTipoRisco                Epaghisteventopagagrup.CdTipoRisco%TYPE,
     CdTipoGratAtivFazendaria   Epaghisteventopagagrup.CdTipoGratAtivFazendaria%TYPE,
     CdTipoTempoServico         Epaghisteventopagagrup.CdTipoTempoServico%TYPE,
     DtInicioConquistaPerAquis  EpagHisteventopagagrup.DtInicioConquistaPerAquis%TYPE,
     DtFimConquistaPerAquis     EpagHisteventopagagrup.DtFimConquistaPerAquis%TYPE,
     NuMesPagamento             EpagHisteventopagagrup.NuMesPagamento%TYPE,
     CdTipoComConselhoGrupo     EpagHisteventopagagrup.Cdtipocomconselhogrupo%TYPE,
     NuFormulaEspecifica        EpagHisteventopagagrup.NuFormulaEspecifica%TYPE,
     InAcaoCarreira             EpagHisteventopagagrup.InAcaoCarreira%TYPE,
     FlUtilizaFormulaCalculo    EpagHisteventopagagrup.FlUtilizaFormulaCalculo%TYPE,
     CdTipoFalta                EpagHisteventopagagrup.CdTipoFalta%TYPE,
     CdTipoPensaoNaoPrev        Epaghisteventopagagrup.CdTipoPensaoNaoPrev%TYPE,
     CdGrauEscolaridade         Epaghisteventopagagrup.Cdgrauescolaridade%TYPE
     );
     
  TYPE tEvento IS TABLE OF rEvento INDEX BY PLS_INTEGER;

  TYPE tFalta is VARRAY(12) of NUMBER;

  TYPE rCarreira IS RECORD
    (Carreira tLista);

  TYPE tEventoCarreira IS TABLE OF rCarreira INDEX BY PLS_INTEGER;

  TYPE tRubAbrangencia IS TABLE OF INTEGER INDEX BY PLS_INTEGER;

  TYPE rRubrica IS RECORD
    (CdRubricaAgrupamento          EpagHistRubricaAgrupamento.CdRubricaAgrupamento%TYPE,
     CdTipoRubrica                 EpagRubrica.CdTipoRubrica%TYPE,
     NuRubrica                     EpagRubrica.NuRubrica%TYPE,
     CdBaseCalculo                 EpagRubricaAgrupamento.CdBaseCalculo%TYPE,
     CdOrgao                       EpagHistRubricaAgrupamento.CdRubricaAgrupamento%TYPE,
     CdAgrupamento                 EpagRubricaAgrupamento.Cdagrupamento%TYPE,
     CdHistRubrica                 EpagHistRubricaAgrupamento.CdHistRubricaAgrupamento%TYPE,
     FlEmpenhadaFilial             EpagRubricaAgrupamento.FlEmpenhadaFilial%TYPE,
     FlIncorporacao                EpagRubricaAgrupamento.FlIncorporacao%TYPE,
     FlPensaoAlimenticia           EpagRubricaAgrupamento.FlPensaoAlimenticia%TYPE,
     FlTributacao                  EpagRubricaAgrupamento.FlTRibutacao%TYPE,
     FlConsignacao                 EpagRubricaAgrupamento.FlConsignacao%TYPE,
     FlPermiteAfastAcidente        EpagHistRubricaAgrupamento.FlPermiteAfastacidente%TYPE,
     FlBloqLancFinanc              EpagHistRubricaAgrupamento.FlBloqLancFinanc%TYPE,
     InPossuiValorInformado        EpagHistRubricaAgrupamento.InPossuiValorInformado%TYPE,
     InLancPropRelVinc             EpagHistRubricaAgrupamento.InLancPropRelVinc%TYPE,
     CdRelacaoTrabalho             EpagHistRubricaAgrupamento.CdRelacaoTrabalho%TYPE,
     CdRubProporcionalidadeCHO     EpagHistRubricaAgrupamento.CdRubProporcionalidadeCHO%TYPE,
     FlCargaHorariaPadrao          EpagHistRubricaAgrupamento.FlCargaHorariaPadrao%TYPE,
     NuCargaHorariaSemanal         NUMBER(7,4),
     NuMesesApuracao               EpagHistRubricaAgrupamento.NuMesesApuracao%TYPE,
     FlPropMesComercial            EpagHistRubricaAgrupamento.FlPropMesComercial%TYPE,
     FlPropAposParidade            EpagHistRubricaAgrupamento.FlPropAposParidade%TYPE,
     FlPropServRelVinc             EpagHistRubricaAgrupamento.FlPropServRelVinc%TYPE,
     FlPropAfastTempNaoRemun       EpagHistRubricaAgrupamento.FlPropAfastTempNaoRemun%TYPE,
     InImpedimentoRubrica          EpagHistRubricaAgrupamento.InImpedimentoRubrica%TYPE,
     InRubricasExigidas            EpagHistRubricaAgrupamento.InRubricasExigidas%TYPE,
     CdModalidadeRubrica           EpagRubricaAgrupamento.CdModalidadeRubrica%TYPE,
     InGeraRubricaCarreira         EpagHistRubricaAgrupamento.InGeraRubricaCarreira%TYPE,
     InGeraRubricaFUC              EpagHistRubricaAgrupamento.InGeraRubricaFUC%TYPE,
     InGeraRubricaCCO              EpagHistRubricaAgrupamento.InGeraRubricaCCO%TYPE,
     InGeraRubricaUO               EpagHistRubricaAgrupamento.InGeraRubricaUO%TYPE,
     InGeraRubricaAfastTemp        EpagHistRubricaAgrupamento.InGeraRubricaAfastTemp%TYPE,
     FlAplicaRubricaOrgaos         EpagHistRubricaAgrupamento.FlAplicaRubricaOrgaos%TYPE,
     FlPermiteAPOOriginadoCCO      EpagHistRubricaAgrupamento.FlPermiteAPOOriginadoCCO%TYPE,
     FlPermiteFGFTG                EpagHistRubricaAgrupamento.FlPermiteFGFTG%TYPE,
     FlPagaSubstituicao            EpagHistRubricaAgrupamento.FlPagaSubstituicao%TYPE,
     FlPagaRespondendo             EpagHistRubricaAgrupamento.FlPagaRespondendo%TYPE,
     FlConsolidaRubrica            EpagHistRubricaAgrupamento.FlConsolidaRubrica%TYPE,
     FlPropAfaFgFtg                EpagHistRubricaAgrupamento.FlPropAfaFgFtg%TYPE,
     FlCargaHorariaLimitada        EpagHistRubricaAgrupamento.FlCargaHorariaLimitada%TYPE,
     FlPropAfaComissionado         EpagHistRubricaAgrupamento.FlPropAfaComissionado%TYPE,
     FlPropAfaComOpcPercCEF        EpagHistRubricaAgrupamento.FlPropAfaComOpcPercCEF%TYPE,
     FlPreservaValorIntegral       EpagHistRubricaAgrupamento.FlPreservaValorIntegral%TYPE,
     FlPagaApoSemParidade          EpagHistRubricaAgrupamento.FlPagaApoSemParidade%TYPE,
     InGeraRubricaMotMovi          EpagHistRubricaAgrupamento.InGeraRubricaMotMovi%TYPE,
     FlPercentLimitado100          EpagHistRubricaAgrupamento.Flpercentlimitado100%TYPE,
     InGeraRubricaPrograma         EpagHistRubricaAgrupamento.InGeraRubricaPrograma%TYPE,
     FlPropAfaCCOSubst             EpagHistRubricaAgrupamento.FlPropAfaCCOSubst%TYPE,
     FlImpedeIdadeCompulsoria      EpagHistRubricaAgrupamento.FlImpedeIdadeCompulsoria%TYPE,
     FlGeraRubricaCarreiraIncideCCO EpagHistRubricaAgrupamento.FlGeraRubricaCarreiraIncideCCO%TYPE,
     FlGeraRubricaCarreiraIncideAPO EpagHistRubricaAgrupamento.FlGeraRubricaCarreiraIncideAPO%TYPE,
     FlGeraRubricaCCOIncideCEF     EpagHistRubricaAgrupamento.FlGeraRubricaCCOIncideCEF%TYPE,
     FlGeraRubricaFUCIncideCEF     EpagHistRubricaAgrupamento.FlGeraRubricaFUCIncideCEF%TYPE,
     FlSuspensa                    EPagHistRubricaAgrupamento.FlSuspensa%TYPE,
     NuOrdemCalculo                EPagHistoricoRubricaRelVinc.NuOrdemCalculo%TYPE,
     FlPercentReducaoAfastRemun    EPagHistRubricaAgrupamento.FlPercentReducaoAfastRemun%TYPE,
     FlPagaMaiorRV                 EPagHistRubricaAgrupamento.FlPagaMaiorRV%TYPE,
     CdTipoIndice                  EPagHistRubricaAgrupamento.CdTipoIndice%TYPE,
     FLPagaEfetivoOrgao            EPagHistRubricaAgrupamento.FLPagaEfetivoOrgao%TYPE,
     FLIGNORAAFASTCEFAGPOLITICO    Epaghistrubricaagrupamento.Flignoraafastcefagpolitico%TYPE,
     lsOrgao                       tListaOrgao,
     lsMotivoConvocacao            tLista,
     lsNatVinc                     tLista,
     lsRegPrev                     tLista,
     lsRegTrab                     tLista,
     lsSitPrev                     tLista,
     lsRelTrab                     tLista,
     lsFUC                         tLista,
     lsCarreira                    tLista,
     lsCCO                         tLista,
     lsGrupoOcupacional            tLista,
     lsRubExigida                  tLista,
     lsRubImpeditiva               tLista,
     lsUO                          tLista,
     lsMovInstituto                tListaMovInstituto,
     lsPrograma                    tLista,
     lsMotAfastTempEx              tMotAfasTempEx,
     lsMotAfastTempImp             tLista,
     lsLocCHO                      tListaValor,
     lsModeloApo                   tLista,
     flRubAntecipSal               EPagRubricaAgrupamento.flRubAntecipSal%TYPE);

  TYPE tRubrica IS TABLE OF rRubrica INDEX BY PLS_INTEGER;

  /* Este tipo de registro e utilizado para processar os registros
     de relacoes de vinculo de Cargo Efetivo e Aposentadoria com
     paridade
                                                */
  TYPE rCEF IS RECORD (
    CdVinculo                      ECadHistCargoEfetivo.CdVinculo%TYPE,
    CdRelacaoVinculo               EcadRelacaoVinculo.CdRelacaoVinculo%TYPE,
    CdHistRelVinc                  ECadHistCargoEfetivo.CdHistCargoEfetivo%TYPE,
    CdRelacaoTrabalho              ECadHistCargoEfetivo.CdRelacaoTrabalho%TYPE,
    CdRegimeTrabalho               ECadHistCargoEfetivo.CdRegimeTrabalho%TYPE,
    CdNaturezaVinculo              ECadHistCargoEfetivo.CdNaturezaVinculo%TYPE,
    CdRegimePrevidenciario         ECadHistCargoEfetivo.CdRegimePrevidenciario%TYPE,
    CdSituacaoPrevidenciaria       ECadHistCargoEfetivo.CdSituacaoPrevidenciaria%TYPE,
    CdEstruturaCarreira            ECadHistCargoEfetivo.CdEstruturaCarreira%TYPE,
    CdEstruturaCarreiraCarreira    ECadEstruturaCarreira.CdEstruturaCarreira%TYPE,
    CdEstruturaCarreiraCEF         ECadHistCargoEfetivo.CdEstruturaCarreira%TYPE,
    CdEstruturaCarreiraCarreiraCEF ECadEstruturaCarreira.CdEstruturaCarreira%TYPE,
    DtInicio                       ECadHistCargoEfetivo.DtInicio%TYPE,
    DtFim                          ECadHistCargoEfetivo.DtFim%TYPE,
    DtInicioRelacao                ECadHistCargoEfetivo.DtInicio%TYPE,
    DtFimRelacao                   ECadHistCargoEfetivo.DtFim%TYPE,
    CdHistCargoEfetivo             ECadHistCargoEfetivo.CdHistCargoEfetivo%TYPE,
    NuNivelPagamento               ECadHistNivelRefCEF.NuNivelPagamento%TYPE,
    NuReferenciaPagamento          ECadHistNivelRefCEF.NuReferenciaPagamento%TYPE,
    NuNivelPagamentoCEF            ECadHistNivelRefCEF.NuNivelPagamento%TYPE,
    NuReferenciaPagamentoCEF       ECadHistNivelRefCEF.NuReferenciaPagamento%TYPE,
    VlPercentPropAPO               EPvdConcessaoAposentadoria.Vlpercentpropapo%TYPE,
    CdModeloAposentadoria          Epvdconcessaoaposentadoria.Cdmodeloaposentadoria%TYPE,
    CdOrgaoExercicio               ECadHistCargoEfetivo.CdOrgaoExercicio%TYPE,
    FlPrincipal                    ECadHistCargoEfetivo.FlPrincipal%TYPE,
    CdUnidadeOrganizacional        ECadLocalTrabalho.CdUnidadeOrganizacional%TYPE,
    FlOrigemCCO                    EPvdConcessaoAposentadoria.FlOrigemCCO%TYPE,
    FlEfetivacao                   ECadHistCargoEfetivo.FlEfetivacao%TYPE,
    NuCargaHoraria                 NUMBER(7,4),
    NuCargaHorariaPadrao           NUMBER(7,4),
    CdTipoIndice                   INTEGER,
    TIDNuCargaHoraria              PKGTID.tTID,
    CdOrgaoDestProcSeletivo        INTEGER,
    DtFimNovoProcessoSeletivo      DATE,
    CdMotivoMovimentacao           EMovMovimentacao.CdMotivoMovimentacao%TYPE,
    CdInstitutoMovimentacao        EMovMovimentacao.CdInstitutoMovimentacao%TYPE,
    FlExercicioOrigem              EMovInstitutoMovimentacao.FlExercicioOrigem%TYPE,
    CdOrgaoDestMovimentacao        ECadOrgao.CdOrgao%TYPE,
    DtInclusao                     ECadHistCargoEfetivo.DtInclusao%TYPE,
    DtInicioVinculo                ECadHistCargoEfetivo.DtInclusao%TYPE
    );

  TYPE tCEF IS TABLE OF rCEF INDEX BY PLS_INTEGER;

  TYPE rFUC IS RECORD (
    CdVinculo                ECadHistFuncaoChefia.CdVinculo%TYPE,
    CdHistFuncaoChefia       ECadHistFuncaoChefia.CdHistFuncaoChefia%TYPE,
    CdSituacaoPrevidenciaria ECadHistFuncaoChefia.CdSituacaoPrevidenciaria%TYPE,
    CdFuncaoChefia           ECadHistFuncaoChefia.CdFuncaoChefia%TYPE,
    CdTipoFuncaoChefia       ECadHistFuncaoChefia.CdTipoFuncaoChefia%TYPE,
    CdOrgaoExercicio         ECadHistFuncaoChefia.CdOrgaoExercicio%TYPE,
    DtInicio                 ECadHistFuncaoChefia.DtInicio%TYPE,
    DtFim                    ECadHistFuncaoChefia.DtFim%TYPE,
    DtInicioRelacao          ECadHistFuncaoChefia.DtInicio%TYPE,
    DtFimRelacao             ECadHistFuncaoChefia.DtFim%TYPE,
    CdUnidadeOrganizacional  ECadLocalTrabalho.CdUnidadeOrganizacional%TYPE,
    CdPadraoFucAgrup         ECadEvolucaoFuncaoChefia.CdPadraoFucAgrup%TYPE,
    FlFuncaoGratificada      ECadEvolucaoFuncaoChefia.FlFuncaoGratificada%TYPE,
    NuCargaHoraria           NUMBER(7,4),
    NuCargaHorariaPadrao     NUMBER(7,4),
    FlEfetivacao             ECadHistFuncaoChefia.FlEfetivacao%TYPE,
    CdEvolucaoFuncaoChefia   ECadEvolucaoFuncaoChefia.CdEvolucaoFuncaoChefia%TYPE,
    CdTipoUnidOrg            ECadEvolucaoFuncaoChefia.CdTipoUnidOrg%TYPE,
    DtInclusao               ECadHistFuncaoChefia.DtInclusao%TYPE,
    Flproporcionalizacho           ECadEvolucaoFuncaoChefia.Flproporcionalizacho%TYPE,
    CdTipoFuncaoChefiaPrivativa  Ecadevolucaofuncaochefia.CdTipoFuncaoChefia%TYPE,
    CdHistCargoEfetivoOrigem ecadhistfuncaochefia.cdhistcargoefetivoorigem%TYPE);

  TYPE tFUC IS TABLE OF rFUC INDEX BY PLS_INTEGER;

  TYPE rCCO IS RECORD (
    CdVinculo                ECadHistCargoCom.CdVinculo%TYPE,
    CdHistCargoCom           ECadHistCargoCom.CdHistCargoCom%TYPE,
    CdCargoComissionado      ECadHistCargoCom.CdCargoComissionado%TYPE,
    CdOrgaoExercicio         ECadHistCargoCom.CdOrgaoExercicio%TYPE,
    CdGrupoOcupacional       ECadCargoComissionado.CdGrupoOcupacional%TYPE,
    CdRelacaoTrabalho        ECadHistCargoCom.CdRelacaoTrabalho%TYPE,
    CdNaturezaVinculo        ECadHistCargoCom.CdRelacaoTrabalho%TYPE,
    CdRegimePrevidenciario   ECadHistCargoCom.CdRelacaoTrabalho%TYPE,
    CdSituacaoPrevidenciaria ECadHistCargoCom.CdRelacaoTrabalho%TYPE,
    CdRegimeTrabalho         ECadHistCargoCom.CdRelacaoTrabalho%TYPE,
    CdOpcaoRemuneracao       ECadHistCargoCom.CdOpcaoRemuneracao%TYPE,
    DtInicio                 ECadHistCargoCom.DtInicio%TYPE,
    DtFim                    ECadHistCargoCom.DtFim%TYPE,
    DtInicioRelacao          ECadHistCargoCom.DtInicio%TYPE,
    DtFimRelacao             ECadHistCargoCom.DtFim%TYPE,
    NuReferencia             ECadHistCargoCom.NuReferencia%TYPE,
    NuNivel                  ECadHistCargoCom.NuNivel%TYPE,
    NuCargaHoraria           NUMBER(7,4),
    NuCargaHorariaPadrao     NUMBER(7,4),
    CdUnidadeOrganizacional  ECadLocalTrabalho.CdUnidadeOrganizacional%TYPE,
    FlTipoProvimento         ECadHistCargoCom.FlTipoProvimento%TYPE,
    DtInclusao               ECadHistCargoCom.DtInclusao%TYPE,
    CdMotivoMovimentacao     EMovMovimentacao.CdMotivoMovimentacao%TYPE,
    CdInstitutoMovimentacao  EMovMovimentacao.CdInstitutoMovimentacao%TYPE,
    FlPagaSubsidio           ECadHistCargoCom.FlPagaSubsidio%TYPE,
    QtNuDiasCCO              INTEGER);

  TYPE tCCO IS TABLE OF rCCO INDEX BY PLS_INTEGER;

  TYPE rBOL IS RECORD (
    CdVinculoEstagio         ECadHistEstagio.CdVinculoEstagio%TYPE,
    CdHistEstagio            ECadHistEstagio.CdHistEstagio%TYPE,
    CdOrgaoExercicio         ECadVinculo.CdOrgao%TYPE,
    CdRelacaoTrabalho        ECadHistEstagio.CdRelacaoTrabalho%TYPE,
    CdRegimeTrabalho         ECadHistEstagio.CdRegimeTrabalho%TYPE,
    CdNaturezaVinculo        ECadHistEstagio.CdNaturezaVinculo%TYPE,
    CdSituacaoPrevidenciaria ECadVinculo.CdSituacaoPrevidenciaria%TYPE,
    CdRegimePrevidenciario   ECadVinculo.CdRegimePrevidenciario%TYPE,
    CdHistPrograma           EBolHistPrograma.CdHistPrograma%TYPE,
    FlOcupaVagaPNE           ECadHistEstagio.FlOcupaVagaPNE%TYPE,
    CdGrauEscolaridade       ECadHistEstagio.CdGrauEscolaridade%TYPE,
    CdNivelFormacao          ECadHistEstagio.CdNivelFormacao%TYPE,
    CdCursoAgrupador         ECadHistEstagio.CdCursoAgrupador%TYPE,
    CdCurso                  ECadHistEstagio.CdCurso%TYPE,
    DtInicio                 ECadHistEstagio.DtInicio%TYPE,
    DtFim                    ECadHistEstagio.DtFim%TYPE,
    DtInicioRelacao          ECadHistEstagio.DtInicio%TYPE,
    DtFimRelacao             ECadHistEstagio.DtFim%TYPE,
    VlBolsa                  EBolHistPrograma.VlBolsa%TYPE,
    VlBolsaPNE               EBolHistPrograma.VlBolsaPNE%TYPE,
    NuCargaHoraria           NUMBER(7,4),
    NuCargaHorariaPNE        NUMBER(7,4),
    NuCargaHorariaPadrao     NUMBER(7,4),
    CdUnidadeOrganizacional  ECadLocalTrabalho.CdUnidadeOrganizacional%TYPE,
    CdPrograma               ECadHistEstagio.CdPrograma%TYPE,
    CdMotivoMovimentacao     EMovMovimentacao.CdMotivoMovimentacao%TYPE,
    CdInstitutoMovimentacao  EMovMovimentacao.CdInstitutoMovimentacao%TYPE,
    DtInclusao               ECadHistEstagio.DtInclusao%TYPE);

  TYPE tBOL IS TABLE OF rBOL INDEX BY PLS_INTEGER;

  TYPE rPensaoNaoPrev IS RECORD (
    CdVinculo                   Epvdhistpensaonaoprev.Cdvinculobeneficiario%TYPE,
    CdHistPensaoNaoPrev         Epvdhistpensaonaoprev.Cdhistpensaonaoprev%TYPE,
    CdOrgaoExercicio            ECadVinculo.CdOrgao%TYPE,
    CdTipoPensaoNaoPrev         Epvdhistpensaonaoprev.CdTipoPensaoNaoPrev%TYPE,
    CdVinculoBeneficiario       Epvdhistpensaonaoprev.CdVinculoBeneficiario%TYPE,
    CdPessoa                    Epvdhistpensaonaoprev.CdPessoa%TYPE,
    CdNaturezaVinculo           Epvdhistpensaonaoprev.CdNaturezaVinculo%TYPE,
    CdRegimeTrabalho            ECadVinculo.CdRegimeTrabalho%TYPE,
    CdRegimePrevidenciario      ECadVinculo.CdRegimePrevidenciario%TYPE,
    CdSituacaoPrevidenciaria    Epvdhistpensaonaoprev.CdSituacaoPrevidenciaria%TYPE,
    CdUnidadeOrganizacional     ECadVinculo.CdUnidadeOrganizacional%TYPE,
    DtInicio                    Epvdhistpensaonaoprev.DtInicio%TYPE,
    DtFim                       Epvdhistpensaonaoprev.DtFim%TYPE,
    DtInicioRelacao             Epvdhistpensaonaoprev.DtInicio%TYPE,
    DtFimRelacao                Epvdhistpensaonaoprev.DtFim%TYPE,
    CdHistPensaoNaoPrevOrigem   Epvdhistpensaonaoprev.CdHistPensaoNaoPrevOrigem%TYPE,
    NuCargaHoraria              NUMBER(7,4),
    NuCargaHorariaPadrao        NUMBER(7,4),
    FlPrincipal                 Epvdhistpensaonaoprev.FlPrincipal%TYPE,
    FlParidadeRemuneratoria     Epvdhistpensaonaoprev.FlParidadeRemuneratoria%TYPE,
    FlPaga13                    Epvdhistpensaonaoprev.FlPaga13%TYPE,
    FlAdianta13                 Epvdhistpensaonaoprev.FlAdianta13%TYPE,
    DtInclusao                  Epvdhistpensaonaoprev.DtInclusao%TYPE);

  TYPE tPensaoNaoPrev IS TABLE OF rPensaoNaoPrev INDEX BY PLS_INTEGER;

  TYPE rPensaoPrev IS RECORD (
    cdhistpensaoprevidenciaria epvdhistpensaoprevidenciaria.cdhistpensaoprevidenciaria%TYPE,
    cdvinculo                  epvdhistpensaoprevidenciaria.cdvinculo%TYPE,
    dtinicio                   epvdhistpensaoprevidenciaria.dtinicio%TYPE,
    dtfim                      epvdhistpensaoprevidenciaria.dtfim%TYPE,
    flpessoainvalida           epvdhistpensaoprevidenciaria.flpessoainvalida%TYPE,
    cdnaturezavinculo          epvdhistpensaoprevidenciaria.cdnaturezavinculo%TYPE,
    cdunidadeorganizacional    epvdhistpensaoprevidenciaria.cdunidadeorganizacional%TYPE,
    cddocumento                epvdhistpensaoprevidenciaria.cddocumento%TYPE,
    cdtipopublicacao           epvdhistpensaoprevidenciaria.cdtipopublicacao%TYPE,
    dtpublicacao               epvdhistpensaoprevidenciaria.dtpublicacao%TYPE,
    nupublicacao               epvdhistpensaoprevidenciaria.nupublicacao%TYPE,
    nupaginicial               epvdhistpensaoprevidenciaria.nupaginicial%TYPE,
    cdmeiopublicacao           epvdhistpensaoprevidenciaria.cdmeiopublicacao%TYPE,
    deoutromeio                epvdhistpensaoprevidenciaria.deoutromeio%TYPE,
    nucpfcadastrador           epvdhistpensaoprevidenciaria.nucpfcadastrador%TYPE,
    dtinclusao                 epvdhistpensaoprevidenciaria.dtinclusao%TYPE,
    dtanulado                  epvdhistpensaoprevidenciaria.dtanulado%TYPE,
    flanulado                  epvdhistpensaoprevidenciaria.flanulado%TYPE,
    dtultalteracao             epvdhistpensaoprevidenciaria.dtultalteracao%TYPE,
    cdgrauparentescoprevfin    epvdhistpensaoprevidenciaria.cdgrauparentescoprevfin%TYPE,
    deobservacao               epvdhistpensaoprevidenciaria.deobservacao%TYPE,
    cdrelacaovinculo           INTEGER
  );

  TYPE tPensaoPrev IS TABLE OF rPensaoPrev INDEX BY PLS_INTEGER;

/* Tipo Generico de Relacao de Vinculo */

 TYPE rRelVinc IS RECORD
      (
      iRelVinc                       INTEGER,
      CdRelacaoVinculo               EcadRelacaoVinculo.CdRelacaoVinculo%TYPE,
      CdHistRelVinc                  ECadHistCargoEfetivo.CdHistCargoEfetivo%TYPE,
      CdRelacaoTrabalho              ECadHistCargoEfetivo.CdRelacaoTrabalho%TYPE,
      CdUnidadeOrganizacional        ECadLocalTrabalho.CdUnidadeOrganizacional%TYPE,
      DtInicio                       ECadHistCargoEfetivo.DtInicio%TYPE,
      DtFim                          ECadHistCargoEfetivo.DtFim%TYPE,
      DtInicioRelacao                ECadHistCargoEfetivo.DtInicio%TYPE,
      DtFimRelacao                   ECadHistCargoEfetivo.DtFim%TYPE,
      DtInclusao                     ECadHistCargoEfetivo.DtInclusao%TYPE,
      iRel                           INTEGER,
      Tipo                           CHAR,
      CEF                            rCEF,
      FUC                            rFUC,
      FUCSubst                       rFUC,
      CCO                            rCCO,
      CCOSubst                       rCCO,
      APO                            rCEF,
      APOSemParidade                 rCEF,
      BOL                            rBOL,
      PensaoNaoPrev                  rPensaoNaoPrev
      );

  TYPE tRelVinc IS TABLE OF rRelVinc INDEX BY PLS_INTEGER;

/* Lista invertida para localizar as relacoes de vinculo */

  TYPE tLsInv IS TABLE OF INTEGER INDEX BY PLS_INTEGER;

  TYPE rLsInvRel IS RECORD

     (CEF                            tLsInv,
      FUC                            tLsInv,
      FUCSubst                       tLsInv,
      CCO                            tLsInv,
      CCOSubst                       tLsInv,
      APO                            tLsInv,
      APOSemParidade                 tLsInv,
      BOL                            tLsInv,
      PensaoNaoPrev                  tLsInv
     );

/* Tipos utilizados nas formulas de  calculo  */

 TYPE rExpressao IS RECORD
    (CdExpressao                  INTEGER,
     CdRubricaAgrupamento         EPagBaseCalculoBlocoExpressao.CdRubricaAgrupamento%TYPE,
     DeOperacao                   EPagBaseCalculoBlocoExpressao.DeOperacao%TYPE,
     CdTipoMneumonico             EPagBaseCalculoBlocoExpressao.CdTipoMneumonico%TYPE,
     InTipoRubrica                EPagBaseCalculoBlocoExpressao.InTipoRubrica%TYPE,
     InRelacaoRubrica             EPagBaseCalculoBlocoExpressao.InRelacaoRubrica%TYPE,
     InMes                        EPagBaseCalculoBlocoExpressao.InMes%TYPE,
     CdValorReferencia            EPagBaseCalculoBlocoExpressao.CdValorReferencia%TYPE,
     CdBaseCalculo                EPagBaseCalculoBlocoExpressao.CdBaseCalculo%TYPE,
     CdTipoAdicionalTempServ      EPagBaseCalculoBlocoExpressao.CdTipoAdicionalTempServ%TYPE,
     CdValorGeralCEFAgrup         EPagBaseCalculoBlocoExpressao.CdValorGeralCEFAgrup%TYPE,
     DeNivel                      EPagBaseCalculoBlocoExpressao.DeNivel%TYPE,
     DeCodigoCCO                  EPagBaseCalculoBlocoExpressao.DeCodigoCCO%TYPE,
     CdEstruturaCarreira          EPagBaseCalculoBlocoExpressao.CdEstruturaCarreira%TYPE,
     DeReferencia                 EPagBaseCalculoBlocoExpressao.DeReferencia%TYPE,
     CdFuncaoChefia               EPagBaseCalculoBlocoExpressao.CdFuncaoChefia%TYPE,
     NuMeses                      EPagBaseCalculoBlocoExpressao.NuMeses%TYPE,
     NuValor                      NUMBER(13,4),
     InTipoRetorno                EPagBaseCalculoBlocoExpressao.InTipoRetorno%TYPE,
     FlValorHoraMinuto            CHAR(1),
     CdFolhaHistorico             INTEGER,
     CdFolhaHistAlt               INTEGER, -- Atributo utilizado para armazenar a folha
     VlResultado                  PKGPAG_TIPO.rValorPagamento,
     NuMesRubrica                 NUMBER(2),
     NuAnoRubrica                 NUMBER(4));

  TYPE tExpressao IS TABLE OF rExpressao INDEX BY PLS_INTEGER;

  TYPE rBlocoExpressao IS RECORD
    (CdBlocoExpressao      INTEGER,
     SgBloco               EPagFormulaCalculoBloco.SgBloco%TYPE,
     FlLimiteParcial       EPagFormulaCalculoBloco.FlLimiteParcial%TYPE,
     lExpressao            tExpressao);

  TYPE tBlocoExpressao IS TABLE OF rBlocoExpressao INDEX BY PLS_INTEGER;

  TYPE rFormulaCalculo IS RECORD
    (CdRubricaAgrupamento         EpagRubricaAgrupamento.CdRubricaAgrupamento%TYPE,
     CdFormulaCalculo             EpagFormulaCalculo.CdFormulaCalculo%TYPE,
     CdHistFormulaCalculo         EpagHistFormulaCalculo.CdHistFormulaCalculo%TYPE,
     CdExpressaoFormCalc          EpagExpressaoFormCalc.CdExpressaoFormCalc%TYPE,
     CdEstruturaCarreira          EpagExpressaoFormCalc.CdEstruturaCarreira%TYPE,
     CdUnidadeOrganizacional      EpagExpressaoFormCalc.CdUnidadeOrganizacional%TYPE,
     CdCargoComissionado          EpagExpressaoFormCalc.CdCargoComissionado%TYPE,
     FlExpGeral                   EpagExpressaoFormCalc.FlExpGeral%TYPE,
     NuFormulaEspecifica          EpagExpressaoFormCalc.NuFormulaEspecifica%TYPE,
     DeFormulaExpressao           EpagExpressaoFormCalc.DeFormulaExpressao%TYPE,
     CdValorRefLimInfParcial      EpagExpressaoFormCalc.CdValorRefLimInfParcial%TYPE,
     NuQtDelimInfParcial          EpagExpressaoFormCalc.NuQtDelimInfParcial%TYPE,
     CdValorRefLimSupParcial      EpagExpressaoFormCalc.CdValorRefLimSupParcial%TYPE,
     NuQtDelimiteSupParcial       EpagExpressaoFormCalc.NuQtDelimiteSupParcial%TYPE,
     CdValorRefLimInfFinal        EpagExpressaoFormCalc.CdValorRefLimInfFinal%TYPE,
     NuQtDelimiteInfFinal         EpagExpressaoFormCalc.NuQtDelimiteInfFinal%TYPE,
     CdValorRefLimSupFinal        EpagExpressaoFormCalc.CdValorRefLimSupFinal%TYPE,
     NuQtDelimiteSupFinal         EpagExpressaoFormCalc.NuQtDelimiteSupFinal%TYPE,
     VlIndiceLimInferiorMensal    EpagExpressaoFormCalc.VlindiceLiminferiorMensal%TYPE,
     VlIndiceLimSuperiorMensal    EpagExpressaoFormCalc.VlIndiceLimSuperiorMensal%TYPE,
     VlIndiceLimSuperiorSemestral EpagExpressaoFormCalc.VlIndiceLimSuperiorSemestral%TYPE,
     VlIndiceLimSuperiorAnual     EpagExpressaoFormCalc.VlIndiceLimSuperiorAnual%TYPE,
     DeIndiceExpressao            EpagExpressaoFormCalc.DeIndiceExpressao%TYPE,
     FlDesprezaPropCHORubrica     EpagExpressaoFormCalc.FlDesprezaPropCHORubrica%TYPE,
     lBloco                       tBlocoExpressao);

  TYPE tFormulaCalculo IS TABLE OF rFormulaCalculo INDEX BY PLS_INTEGER;

 /* Tipos utilizados no calculo das bases de calculo das rubricas totalizadoras */

  TYPE rBaseCalculo IS RECORD
    (CdRubricaAgrupamento        EpagRubricaAgrupamento.CdRubricaAgrupamento%TYPE,
     NuVersao                    EpagBaseCalculoVersao.NuVersao%TYPE,
     CdBaseCalculo               EpagBaseCalculo.CdBaseCalculo%TYPE,
     CdHistBaseCalculo           EpagHistBaseCalculo.CdHistBaseCalculo%TYPE,
     DeFormula                   EpagHistBaseCalculo.DeFormula%TYPE,
     CdValorReferenciaInferior   EpagHistBaseCalculo.CdValorReferenciaInferior%TYPE,
     NuQtdeValReferenciaInferior EpagHistBaseCalculo.NuQtdeValReferenciaInferior%TYPE,
     CdValorReferenciaSuperior   EpagHistBaseCalculo.CdValorReferenciaSuperior%TYPE,
     NuQtdeValReferenciaSuperior EpagHistBaseCalculo.NuQtdeValReferenciaSuperior%TYPE,
     lBloco                      tBlocoExpressao);

  TYPE tBaseCalculo IS TABLE OF rBaseCalculo INDEX BY PLS_INTEGER;

  TYPE tVantagemOrgaos IS TABLE OF INTEGER INDEX BY PLS_INTEGER;

  TYPE tVantagemOutrasRubricas IS TABLE OF INTEGER INDEX BY PLS_INTEGER;

  TYPE rVantagemPecuniaria IS RECORD
    (CdVantagemPecuniaria           EBpcVantagemPecuniaria.CdVantagemPecuniaria%TYPE,
     CdRubricaAgrupamento           EBpcVantagemPecuniaria.CdRubricaAgrupamento%TYPE,
     CdHistVantagemPecuniaria       EBpcHistVantagemPecuniaria.Cdhistvantagempecuniaria%TYPE,
     CdFormaPagVantPecuniaria       EBpcHistVantagemPecuniaria.CdFormaPagVantPecuniaria%TYPE,
     CdTipoGratificacaoProd         EBpcHistVantagemPecuniaria.CdTipoGratificacaoProd%TYPE,
     NuValorDeterminado             EBpcHistVantagemPecuniaria.NuValorDeterminado%TYPE,
     NuIndiceGeralAplicado          EBpcHistVantagemPecuniaria.NuIndiceGeralAplicado%TYPE,
     CdRubricaTotalizadoraVantagem  EbpcHistVantagemPecuniaria.CdRubricaAgrupamento%TYPE,
     NuPeriodoApuracaoFormaPag      EbpcHistVantagemPecuniaria.NuPeriodoApuracaoFormaPag%TYPE,
     FlContabilizaNaoAfastado       EbpcHistVantagemPecuniaria.FlContabilizaNaoAfastado%TYPE,
     Incontabilizamotivosafastament EbpcHistVantagemPecuniaria.Incontabilizamotivosafastament%TYPE,
     CdOutraRubricaCondPag          EbpcHistVantagemPecuniaria.CdOutraRubricaCondPag%TYPE,
     NuMeses                        EbpcHistVantagemPecuniaria.NuMeses%TYPE,
     FlAplicaTodoAgrupamento        EbpcHistVantagemPecuniaria.FlAplicaTodoAgrupamento%TYPE,
     FlDecisaoJudicial              Ebpchistvantagempecuniaria.Flpagavincdecisaojudicial%TYPE,
     tabOrgaosPermitidos            tVantagemOrgaos,
     tabOutrasRubricasCondPag       tVantagemOutrasRubricas);

  TYPE tVantagemPecuniaria IS TABLE OF rVantagemPecuniaria INDEX BY PLS_INTEGER;

  TYPE rSalFamilia IS RECORD
     (CdRegimeTrabalho      INTEGER,
      CdRubricaAgrupamento  INTEGER);

  TYPE tSalFamilia IS TABLE OF rSalFamilia INDEX BY PLS_INTEGER;

  TYPE rRubExcludente IS RECORD
    (CdRubricaExcludente             EPagRubricaExcludente.CdRubricaExcludente%TYPE,
     CdRubricaAgrupamentoExcludente  EPagRubricaExcludente.CdRubricaAgrupamentoExcludente%TYPE,
     CdRubricaAgrupamentoOutraRubEx  EPagRubricaExcludente.CdRubricaAgrupamentoOutraRubEx%TYPE,
     CdRubricaAgrupamentoPagDif      EPagRubricaExcludente.CdRubricaAgrupamentoPagDif%TYPE,
     InTipoRegraRubExcludente        EPagRubricaExcludente.InTipoRegraRubExcludente%TYPE,
     InRubricaPermanece              EPagRubricaExcludente.InRubricaPermanece%TYPE);

  TYPE tRubExcludente IS TABLE OF rRubExcludente INDEX BY PLS_INTEGER;

   TYPE rFaixaAliquota IS RECORD
    (VlInicial               NUMBER(13,2),
     VlFinal                 NUMBER(13,2),
     VlAliquota              NUMBER(10,4),
     VlParcelaDeducao        NUMBER(13,2),
     FlAliquotaProgressiva   CHAR(1),
     Vlaliqcontribindividual NUMBER(10,4),
     Vltetocontribindividual NUMBER(13,2));

  TYPE tFaixaAliquota IS TABLE OF rFaixaAliquota;

  TYPE rAliquotaIRRF IS RECORD
    (CdHistAliquotaIRRF    Etrbhistaliquotairrf.Cdhistaliquotairrf%TYPE,
     VlDeducaoDependente   Etrbhistaliquotairrf.VlDeducaoDependente%TYPE,
     VlDeducaoInativo      Etrbhistaliquotairrf.VlDeducaoInativo%TYPE,
     lFaixa                tFaixaAliquota);

  TYPE rAliquotaIPESC IS RECORD
    (CdHistAliquotaIPESC   EtrbhistaliquotaIPESC.CdhistaliquotaIPESC%TYPE,
     VlAliquotaUnica       EtrbhistaliquotaIPESC.VlAliquotaUnica%TYPE,
     lFaixa                tFaixaAliquota);

  TYPE rAliquotaINSS IS RECORD
    (CdHistAliquotaINSS      EtrbhistaliquotaINSS.CdHistAliquotaINSS%TYPE,
     VlTeto                  NUMBER(13,2),
     VlAliqContribIndividual NUMBER,
     lFaixa                  tFaixaAliquota);

  TYPE rAliquotaCPSM is record
    (Cdhistaliquotacpsm etrbhistaliquotacpsm.Cdhistaliquotacpsm%TYPE,
     VlAliquotaUnica    etrbhistaliquotacpsm.Vlaliquotaunica%TYPE,
     lFaixa             tFaixaAliquota);

  TYPE rMotAfast IS RECORD
    (InAfastado        CHAR(1), -- 'N' = Nao      'P' = Parcial     'T' = Total
     InTipoAfastamento CHAR(1), -- 'D' = Definitivo   'T' = Temporario
     InPagaLancamento  CHAR(1), -- 'S' = Sim    'N' = Nao
     CdChaveMotivo     INTEGER,
     DtInclusao        DATE,
     FlAuxilioDoenca   CHAR(1),
     FlAcidenteTrabalho CHAR(1),
     FlProcessaNaoPaga CHAR(1),
     DtInicio          DATE);

  TYPE rLancComplementar IS RECORD
    (CdRubricaAgrupamento INTEGER,
     NuSufixoRubrica      INTEGER,
     VlLancamento         NUMBER(13,2),
     CdTipoRubrica        INTEGER,
     VlIndice             NUMBER(13,2));

  TYPE tLancComplementar IS TABLE OF rLancComplementar INDEX BY PLS_INTEGER;

  TYPE rParamAgrupCarreira IS RECORD
    (CdEstruturaCarreira  INTEGER,
     CdRubricaAgrupamento INTEGER,
     VlPercentual         NUMBER(13,2));

  TYPE tParamAgrupCarreira IS TABLE OF rParamAgrupCarreira INDEX BY PLS_INTEGER;

  TYPE rParamAgrupCCO IS RECORD
    (CdCargoComissionado  INTEGER,
     CdRubricaAgrupamento INTEGER,
     VlPercentual         NUMBER(13,2));

  TYPE tParamAgrupCCO IS TABLE OF rParamAgrupCCO INDEX BY PLS_INTEGER;

  TYPE rRubPercent IS RECORD
    (CdRubricaAgrupamento INTEGER,
     VlPercentual         NUMBER(13,2));

  TYPE rLancFinanceiro IS RECORD
    (CdTipoLancamento                 INTEGER,
     CdRubricaAgrupamento             INTEGER,
     CdLancamentoFinanceiro           INTEGER,
     NuSufixoRubrica                  INTEGER,
     VlLancamentoFinanceiro           NUMBER(13,2),
     NuParcelas                       INTEGER,
     FlPagaAfastDefinitivo            CHAR(1),
     DtInicio                         DATE,
     DtFim                            DATE,
     FlValorProporcional              CHAR(1),
     VlIndice                         NUMBER(13,4),
     NuParcelasProc                   INTEGER,
     CdProcessoRestituicaoErario      INTEGER,
     CdProcessoPagRetroativo          INTEGER,
     NuFormulaEspecifica              INTEGER,
     FlPropDemitidoNoMes              CHAR(1),
     CdTipoFolhaPagamento             INTEGER,
     VlIntegralIPESC                  NUMBER(11,2),
     FlPagaAfastTempSemRemun          CHAR(1),
     DtInclusao                       DATE);

  TYPE tLancFinanceiro IS TABLE OF rLancFinanceiro INDEX BY PLS_INTEGER;

  TYPE rContribPlanoSaudeAgregado IS RECORD
    (VlMinimo                         NUMBER (13,2),
     VlMaximo                         NUMBER (13,2),
     VlAgregado                       NUMBER (13,2));

  TYPE tContribPlanoSaudeAgregado IS TABLE OF rContribPlanoSaudeAgregado INDEX BY PLS_INTEGER;

 /* Tipos do Auxilio Creche */

  TYPE rAuxCrecheFaixa IS RECORD (
       VlInicialBaseCalculo     EBPCAUXCRECHEFAIXA.vlInicialBaseCalculo%TYPE,
       VlFinalBaseCalculo       EBPCAUXCRECHEFAIXA.vlFinalBaseCalculo%TYPE,
       VlEspecifico             EBPCAUXCRECHEFAIXA.vlEspecifico%TYPE,
       QtUnidValorReferencia    EBPCAUXCRECHEFAIXA.qtUnidValorReferencia%TYPE,
       CdValorReferencia        EBPCAUXCRECHEFAIXA.cdValorReferencia%TYPE
  );

  TYPE tAuxCrecheFaixa IS TABLE OF rAuxCrecheFaixa;

  TYPE rAuxCreche IS RECORD (
     CdOrgao              INTEGER,
     CdBaseCalculo        INTEGER,
     NuIdadeMaxDependente NUMBER(3),
     CdValorRefLimite     INTEGER,
     QtUnidValorRefLimite INTEGER,
     Faixa                tAuxCrecheFaixa
     );

  TYPE tAuxCreche IS TABLE OF rAuxCreche INDEX BY PLS_INTEGER;

  TYPE rRegraAdicTempServAcum IS RECORD
    (CdTipoAdicionalTempServ        EBpcRegraTipoAdicionalTempServ.CdTipoAdicionalTempServ%TYPE,
     CdRegraTipoAdicionalTempServ   EBpcRegraTipoAdicionalTempServ.CdRegraTipoAdicionalTempServ%TYPE,
     VlPercentMaxAcum               EBpcAdicTempServPercentAcum.VlPercentMaxAcum%TYPE,
     DtConquista                    EBpcAdicTempServPercentAcum.DtConquista%TYPE);

  TYPE tRegraAdicTempServAcum IS TABLE OF rRegraAdicTempServAcum INDEX BY PLS_INTEGER;

  /* Tipo para armazenar remuneracoes fixas do CEF do periodo da folha a calcular */

  TYPE rFixoCEF IS RECORD
    ( dtInicio    DATE,
      dtFim       DATE,
      vlFixo      PKGPAG_TIPO.rValorFixo);

  TYPE tFixoCEF IS TABLE OF rFixoCEF;

  TYPE rAfastGravidez IS RECORD (DtInicio   DATE,
                                 DtInclusao DATE,
                                 NuDias     INTEGER);

  TYPE rRelVincPrincipal IS RECORD (Tipo                    INTEGER,
                                    CdHist                  INTEGER,
                                    CdRelTrabPagamento      INTEGER,
                                    NuCHO                   NUMBER(7,4),
                                    NuCHORelacao            NUMBER(7,4),
                                    DtInicioRelacao         DATE,
                                    CdUnidadeOrganizacional INTEGER
                                    );

  TYPE rValorCEFAgrup IS RECORD(CdValorGeralCEFAgrup     INTEGER,
                                CdHistValorGeralCEFAgrup INTEGER);

  TYPE rSentenca IS RECORD (CdSentencaJudicial            Epensentencajudicial.Cdsentencajudicial%TYPE,
                            CdTipoPensaoAlimenticia       Epenhistsentencajudicial.CdTipoPensaoAlimenticia%TYPE,
                            NuSequencial                  Epensentencajudicial.Nusequencial%TYPE,
                            FlPagamento13                 Epenhistsentencajudicial.Flpagamento13%TYPE,
                            FlPagamentoValorFixo          Epenhisttipopensao.Flpagamentovalorfixo%TYPE,
                            CdRubricaAgrupamento          Epenhisttipopensaorubrica.Cdrubricaagrupamento%TYPE,
                            CdHistTipoPensaoRubrica       Epenhisttipopensaorubrica.Cdhisttipopensaorubrica%TYPE,
                            NuRubrica                     EPagRubrica.NuRubrica%TYPE,
                            CdOutraRubrica                Epensentencarubrica.Cdoutrarubrica%TYPE,
                            FlDescAnteriorAplicPercent    Epensentencarubrica.FlDescAnteriorAplicPercent%TYPE,
                            VlPercentPensao               Epensentencarubrica.VlPercentPensao%TYPE,
                            VlFixo                        Epensentencarubrica.VlFixo%TYPE,
                            CdHistSentencaJudicial        Epenhistsentencajudicial.Cdhistsentencajudicial%TYPE,
                            FlPagamentoFerias             Epenhistsentencajudicial.Flpagamentoferias%TYPE,
                            FlPagamentoRetroativo         Epenhistsentencajudicial.FlpagaRetroativo%TYPE);

  TYPE tSentenca IS TABLE OF rSentenca INDEX BY PLS_INTEGER;

  TYPE rAfastamento IS RECORD (CdVinculo           Eafaafastamentovinculo.Cdvinculo%TYPE,
                               CdMotivoAfastamento Eafaafastamentovinculo.Cdmotivoafasttemporario%TYPE,
                               FlGravidez          CHAR(1),
                               NuDiasAfastMes      NUMERIC,
                               FlUltimoDiaMes      CHAR(1),
                               DtInicioAfa         Eafaafastamentovinculo.Dtinicio%TYPE,
                               DtFimAfa            Eafaafastamentovinculo.DtFim%TYPE,
                               DtInicioAfaNoMes    Eafaafastamentovinculo.DtInicio%TYPE,
                               DtFimAfaNoMes       Eafaafastamentovinculo.Dtinicio%TYPE,
                               DtInclusao          Eafaafastamentovinculo.Dtinclusao%TYPE,
                               NuDiasAfastMesAnt   NUMERIC,
                               DtAnulado           Eafaafastamentovinculo.DtAnulado%TYPE,
                               FlParteJornada      EAfaHistMotivoAfastTemp.FlParteJornada%TYPE,
                               VlPercentReducaoIRESA EAfaHistMotivoAfastTemp.VlPercentReducaoIRESA%TYPE);

  TYPE tAfastamento IS TABLE OF rAfastamento INDEX BY PLS_INTEGER;

  TYPE rData IS RECORD
     (vNuDiasMes    INTEGER,
     vNuDiasTrabalhados INTEGER,
     vlIndice               NUMBER(13,2),
     vNuDiasUteis     INTEGER);

  TYPE rCTISP IS RECORD
    (vCdOrgaoInterno INTEGER,
     vCdOrgaoExterno INTEGER,
     vDtInicio DATE,
     vDtFim DATE,
     vCdLocalExternoCTISP INTEGER);

  TYPE tData IS TABLE OF DATE INDEX BY PLS_INTEGER;

  TYPE rDiaUtil IS RECORD
    (CdAgrupamento INTEGER,
     CdOrgao       INTEGER,
     CdVinculo     INTEGER,
     CdUnidadeOrganizacional INTEGER,
     vlValeDia      NUMBER(13,2),
     vQtdeVale      NUMBER(13,2));

  TYPE tDiaUtil IS TABLE OF rDiaUtil INDEX BY PLS_INTEGER;

  TYPE rPagCalc IS RECORD
    (CdHistPagamento               INTEGER,
    cdvinculo                     INTEGER,
    cdrubricaagrupamento          INTEGER,
    cdexpressaoformcalc           INTEGER,
    cdvantagempecuniaria          INTEGER,
    cdrubricatotalizadoravantagem INTEGER,
    cdincorporacaoativo           INTEGER,
    vlminrecebincorp              NUMBER(13, 2),
    flatualizacaoconstante        CHAR(1),
    flvigenciapagamento           CHAR(1),
    nuordemcalculo                INTEGER,
    cdrelacaovinculo              INTEGER,
    cdchave                       INTEGER,
    vlindicerubrica               NUMBER(13, 4),
    cdtipohistorico               INTEGER,
    cdhistcargoefetivo            INTEGER,
    cdhistfuncaochefia            INTEGER,
    cdhistcargocom                INTEGER,
    cdconcessaoaposentadoria      INTEGER,
    cdhistestagio                 INTEGER,
    cdhistpensaoprevidenciaria    INTEGER,
    cdhistpensaonaoprev           INTEGER,
    cdhistpensaoexparlamentar     INTEGER,
    cdhistauxilioreclusao         INTEGER,
    dtiniciorelacao               DATE,
    dtdesligamento                DATE,
    cdunidadeorganizacional       INTEGER,
    cdlancamentofinanceiro        INTEGER,
    dtinicio                      DATE,
    dtfim                         DATE,
    nusufixorubrica               INTEGER,
    vlindicereal                  NUMBER(13, 4));

  TYPE rPercentATS IS RECORD
      (cdrubricaagrupamento          INTEGER,
       vlindiceATS           INTEGER);

  TYPE tPercentATS IS TABLE OF rPercentATS INDEX BY PLS_INTEGER;

  TYPE rPensaoAlim IS RECORD
    (cdRubricaAgrupamento INTEGER,
     cdbase               INTEGER,
     NuSufixo             INTEGER,
     vlBase               NUMBER(13,2));

  TYPE tPensaoAlim IS TABLE OF rPensaoAlim INDEX BY PLS_INTEGER;

 --------------------------------------------------------------------------------------------------
 -- Constantes Complexas
 --------------------------------------------------------------------------------------------------
 
  cnTipoFolhaPag13      CONSTANT tLista := tLista ( PKGPAG_TIPO.cnTpFolha13 => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaAdiant13 => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaResidente13 => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaFunebre13 => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaCtisp13 => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaProdex13 => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaHonorarios13 => 1, 
                                                    PKGPAG_TIPO.cnTpFolhaHonorarProcuradores13 => 1);

  cnTipoFolhaPagHonor   CONSTANT tLista := tLista ( 1505 => 1, 
                                                    1525 => 1, 
                                                    1526 => 1);
 
  cnTipoFolhaPagHonor13 CONSTANT tLista := tLista (PKGPAG_TIPO.cnTpFolhaProdex13              => 1, 
                                                   PKGPAG_TIPO.cnTpFolhaHonorarios13          => 1,
                                                   PKGPAG_TIPO.cnTpFolhaHonorarProcuradores13 => 1);

  TYPE rIdentRubrica IS RECORD (
      -- Modalidade
      
      cnIndRubBaseIPESC                 INTEGER := 001,
      cnIndRubBaseIPESC13               INTEGER := 002,
      cnIndRubBaseINSS                  INTEGER := 003,
      cnIndRubBaseINSS13                INTEGER := 004,
      cnIndRubBaseIRRF                  INTEGER := 005,
      cnIndRubBaseIRRFFerias            INTEGER := 006,
      cnIndRubricaBaseINSSPat           INTEGER := 007,
      cnIndRubBaseINSSCLT               INTEGER := 008,
      cnIndRubBaseIRRF13                INTEGER := 009,
      cnIndRubBaseVP                    INTEGER := 010,
      cnIndRubricaCSGProcCC             INTEGER := 011,
      cnIndRubBaseFGTS                  INTEGER := 012,
      cnIndRubBaseFGTS13                INTEGER := 013,
      cnIndRubBaseCsgBrutaOutros        INTEGER := 014,
      cnIndRubBaseCsgLiqOutros          INTEGER := 015,
      cnIndRubVlFGTS                    INTEGER := 016,
      cnIndRubVlFGTS13                  INTEGER := 017,
      cnIndRubBaseIPREVFP               INTEGER := 018,
      cnIndRubBaseIPREVFF               INTEGER := 019,
      cnIndRubBaseIPREVFT               INTEGER := 020,
      cnIndRubBaseProv13FT              INTEGER := 021,
      cnIndRubricaBaseConsig            INTEGER := 022,
      cnIndRubricaErario                INTEGER := 023,
      cnIndRubricaBaseCsgLiq            INTEGER := 024,
      cnIndRubricaBaseTotPrv            INTEGER := 025,
      cnIndRubricaBaseTotDsc            INTEGER := 026,
      cnIndRubricaBaseTotLiq            INTEGER := 027,
      cnIndRubricaCSGNaoProc            INTEGER := 028,
      cnIndRubricaBasePlanoSaude        INTEGER := 029,
      cnIndRubricaBaseCoParticip        INTEGER := 030,
      cnIndRubricaCSGProc               INTEGER := 031,
      cnIndRubricaDescDepIRRF           INTEGER := 032,
      cnIndRubricaTetoGov               INTEGER := 033,
      cnIndRubricaBaseTetoGov           INTEGER := 034,
      cnIndRubricaBaseCSG_CC            INTEGER := 035,
      cnIndRubricaBaseFerias            INTEGER := 036,
      cnIndRubricaBasePSPatronal        INTEGER := 037,
      cnIndRubBaseDeducaoInativo        INTEGER := 038,
      cnIndRubBaseIRRFOutros            INTEGER := 039,
      cnIndRubDeducaoIRRFOutros         INTEGER := 040,
      cnIndRubBaseSCSAUDEOutros         INTEGER := 041,
      cnIndRubDeducaoSCSAUDEOutros      INTEGER := 042,
      cnIndRubBaseDescFacultativos      INTEGER := 043,
      cnIndRubBloqRetroativo            INTEGER := 044,
      cnIndRubDepositoJud               INTEGER := 045,
      cnIndRubricaBaseTetoGov13         INTEGER := 046,
      cnIndRubBaseDescSimplif13         INTEGER := 047,
      cnIndRubDevAnt13NaoEfetuado       INTEGER := 048,
      cnIndRubBaseRateio                INTEGER := 049,
      cnIndRubBase13Sal                 INTEGER := 050,
      cnIndRubExigibilidadeSusp         INTEGER := 051,
      cnIndRubExigibilidadeSusp13       INTEGER := 052,
      cnIndRubBaseBaixa                 INTEGER := 053,
      cnIndRubFeriasFGTS                INTEGER := 054,
      cnIndRubBaseAbonoSeguranca        INTEGER := 055,
      cnIndRubBaseRRA                   INTEGER := 056,
      cnIndBaseSalMaternidade           INTEGER := 057,
      cnIndRubBaseFaltaRetroNaoDesc     INTEGER := 058,
      cnIndRubBaseAlimRetroNaoDesc      INTEGER := 059,
      cnIndRubBasePensaoNaoDesc         INTEGER := 060,
      cnIndRubBaseDevAd13NaoEfet        INTEGER := 061,
      cnIndRubBase080023DescParcial     INTEGER := 062,
      cnIndRubBase080024DescParcial     INTEGER := 063,
      cnIndRubBaseProv13PatFP           INTEGER := 064,
      cnIndRubBaseProv13PatFF           INTEGER := 065,
      cnIndRubBaseProv13PatINSS         INTEGER := 066,
      cnIndRubBaseProv13PatINSSCLT      INTEGER := 067,
      cnIndRubBaseProv13VlFGTS          INTEGER := 068,
      cnIndRubExigibilidadeSuspRRA      INTEGER := 069,
      cnIndRubBaseValorPatINSS          INTEGER := 070,
      cnIndRubBaseCeres                 INTEGER := 071,
      cnIndRubBaseCPSM                  INTEGER := 072,
      cnIndRubBaseCPSM13                INTEGER := 073,
      cnIndRubricaBaseCsgLiq_CC         INTEGER := 074,
      cnIndRubBaseCsgMargFut            INTEGER := 075,
      cnIndRubBaseDeducoesIRRFOutros    INTEGER := 076,
      cnIndRubBaseDeducoesIRRF          INTEGER := 077,
      cnIndRubBaseTotDeducoesIRRF13     INTEGER := 078,
      cnIndRubBaseDescSimplifIRRF       INTEGER := 079,
      cnIndRubBaseDedIRRFOutros13       INTEGER := 080,
      
      -- Parametro do Agrupamento 

      cnIndAjustesaldodevedor           INTEGER := 201,
      cnIndAjustesaldodevedor13         INTEGER := 202,
      cnIndBloqexercfind13sal           INTEGER := 203,
      cnIndBloqret                      INTEGER := 204,
      cnIndBloqret13sal                 INTEGER := 205,
      cnIndBloqretexercfind             INTEGER := 206,
      cnIndCorbep                       INTEGER := 207,
      cnIndDesccpsmretera               INTEGER := 208,
      cnIndDesccpsmretera13             INTEGER := 209,
      cnIndDesccpsmsobre13              INTEGER := 210,
      cnIndDescinss                     INTEGER := 211,
      cnIndDescinsssobre13              INTEGER := 212,
      cnIndDescipescjul200813           INTEGER := 213,
      cnIndDescipescsobre13             INTEGER := 214,
      cnIndDesciprevantes2008           INTEGER := 215,
      cnIndDesciprevdepois2008          INTEGER := 216,
      cnIndDesciprevliminar             INTEGER := 217,
      cnIndDesciprevliminar13           INTEGER := 218,
      cnIndDescirrf                     INTEGER := 219,
      cnIndDescirrfsobre13              INTEGER := 220,
      cnIndDescirrfsobreferias          INTEGER := 221,
      cnIndDescscfuturo                 INTEGER := 222,
      cnIndDescscfuturo13               INTEGER := 223,
      cnIndDescscfuturoret              INTEGER := 224,
      cnIndDescscfuturoret13            INTEGER := 225,
      cnIndDevajustesaldodev13          INTEGER := 226,
      cnIndIprevfundfinanc              INTEGER := 227,
      cnIndIprevfundfinanc13            INTEGER := 228,
      cnIndIprevfundlc662               INTEGER := 229,
      cnIndIprevfundlc66213             INTEGER := 230,
      cnIndIprevfundprev                INTEGER := 231,
      cnIndIprevjudretera               INTEGER := 232,
      cnIndIprevjudretera13             INTEGER := 233,
      cnIndPensao13                     INTEGER := 234,
      cnIndPensaoalirra                 INTEGER := 235,
      cnIndPgtobep                      INTEGER := 236,
      cnIndRubricaAdiant13pensao        INTEGER := 237,
      cnIndRubricaAgrupdesccpsm         INTEGER := 238,
      cnIndRubricaAgrupdescipesc        INTEGER := 239,
      cnIndRubricaAgrupdescipescjul2008 INTEGER := 240,
      cnIndRubricaAgrupdesciprevjun1613 INTEGER := 241,
      cnIndRubricaAgrupdesciprevjun2016 INTEGER := 242,
      cnIndRubricaAgrupdescrra          INTEGER := 243,
      
      -- Conversão de Tipo de Rubrica

      cnIndDifDescINSS                  INTEGER := 301,
      cnIndDevDescINSS                  INTEGER := 302,   
      cnIndDifDescINSS13                INTEGER := 303,
      cnIndDevDescINSS13                INTEGER := 304
     
   );

END PKGPAG_TIPO;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_TIPO IS

END PKGPAG_TIPO;
/
