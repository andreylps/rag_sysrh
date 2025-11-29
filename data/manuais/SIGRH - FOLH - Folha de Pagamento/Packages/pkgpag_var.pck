CREATE OR REPLACE PACKAGE PKGPAG_VAR IS

/*--------------------------------------------------------------------------------------/
  VARIAVEIS GLOBAIS
/--------------------------------------------------------------------------------------*/

  bTrace                 BOOLEAN DEFAULT FALSE;

  bLog                   BOOLEAN DEFAULT TRUE;

  bCalculaVinculo        BOOLEAN;

  vgVinculo              PKGPAG_TIPO.rVinculo;
  
  vgMenorAnoMesFolPag    INTEGER;

 -- vgDtInicio             TIMESTAMP;

  vgTmInicio             INTEGER;

  eDependenciaFormula    EXCEPTION;

  eChaveDuplicada        EXCEPTION;

  eRubErarioInexistente  EXCEPTION;

  eRubBaseConsig         EXCEPTION;

  ePercErarioIncorreto   EXCEPTION;

  eInterrupCalc          EXCEPTION;

  eSemBaseIRRF           EXCEPTION;

  eSemBaseIRRFFerias     EXCEPTION;

  eSemBaseIRRF13         EXCEPTION;

  eSemBaseValeTransp     EXCEPTION;

  eParamConsig           EXCEPTION;

  eNaoRodaFolhaNormal    EXCEPTION;

  eRubTetoInexistente    EXCEPTION;

  eFolhaEmExecucao       EXCEPTION;

  vgGlobal_Name          VARCHAR2(100);

  vDtCalculo             DATE; -- Data de calculo

  vDtCalculoAnt          DATE; -- Data do ultimo calculo definitivo

  vDtInicioComissao      DATE := null; -- Data inicial do exercicio da participacao em comissao

  vgDtInicioComissao     PKGPAG_TIPO.tData;

  vDtFimComissao         DATE := null; -- Data final do exercicio da participacao em comissao

  vgDtFimComissao        PKGPAG_TIPO.tData;
  
  bdescrubisentaformula  BOOLEAN;

  /* Variaveis utilizadas para consolidac?o dos historicos de pagamento
     do vinculo, quando este recebeu pagamento por uma relac?o de vinculo
     de cargo comissionado                                               */

  bVinculoComCCO              BOOLEAN DEFAULT FALSE;

  bVinculoComCEF              BOOLEAN DEFAULT FALSE;

  bPagaCEF                    BOOLEAN DEFAULT TRUE;

  bPossuiDisposicao           BOOLEAN DEFAULT FALSE;

  bPossuiIprevCCO             BOOLEAN DEFAULT FALSE;

  bPossuiPensao               BOOLEAN DEFAULT FALSE;

  bPossuiDuploVinculoAno         BOOLEAN DEFAULT FALSE;

  vCdRelacaoTrabalhoCCO       INTEGER DEFAULT NULL;

  vCdOpcaoRemuneracaoCCO      INTEGER DEFAULT NULL;

  bTemDireitoLancFin          BOOLEAN DEFAULT NULL;

  bPossuiObito                BOOLEAN DEFAULT FALSE;

  bPossuiLancTesouraria       BOOLEAN DEFAULT FALSE;

  bPossuiEventoHoraAulaAtiv   BOOLEAN;

  bPossuiCtisp                BOOLEAN DEFAULT FALSE;

  bGeraPagamentoCTISP         BOOLEAN DEFAULT TRUE;

  bGerouDescontoIRESA         BOOLEAN DEFAULT FALSE;

  vgVlDescontoIRESA           NUMBER(13,2);
  -- Valor fixo com base no Nivel/Referencia do CEF

  vgValorFixoCEF              PKGPAG_TIPO.rValorFixo;

  vgValorFixoCEFAnt           pkgpag_tipo.rValorPagamento;

  vgDtInicioCefAnt            DATE;

  vgDtFimCefAnt               DATE;

  vgValorSalarioCEF           NUMBER(13,2);

  -- Variavel vetor que contera as remunerac?es fixas do cargo efetivo em calculo

  vgFixoCEF                   PKGPAG_TIPO.tFixoCEF;

  vCdHistParamCalc            INTEGER;

  vCdPessoa                   INTEGER;

  vgCdVinculo                 INTEGER;

  vgCdOrgaoVinculo            INTEGER;

  vgCdSitPrevidenciariaAtual  INTEGER;

  -- Variavel que armazena o tipo de relac?o de vinculo da rubrica impeditiva
  vCdRelacaoRubImpeditiva          INTEGER := 0;

  vgFolha                     PKGPAG_TIPO.rFolha;

  vgFolhaOrigem               PKGPAG_TIPO.rFolha;

  vgFolhaOrigemAux            PKGPAG_TIPO.rFolha;

  vgFolhaAuxiliar             PKGPAG_TIPO.rFolha;

  vgFolhaNormalAnt            PKGPAG_TIPO.rFolha;

  vgFolhaRecalculo            PKGPAG_TIPO.rFolha;

  vgParamPagamento            ePagAgrupamentoParametro%ROWTYPE;

  vgParamOrgao                EPagOrgaoParametro%ROWTYPE;

  vgCdRubAgrup1001                 INTEGER;

  vgCdRubCalculada                 INTEGER;

  vgCdRubAgrupDifDescIPESC         INTEGER;

  vgCdRubAgrupDevDescIPESC         INTEGER;

  vgCdRubAgrupDifDescIPESC2008     INTEGER;

  vgCdRubAgrupDevDescIPESC2008     INTEGER;

  vgCdRubValeTransporte            INTEGER;

  vgCdRubDescTetoGovernador        INTEGER;

  vgCdRubDescTetoGovernador13      INTEGER;

  vgCdRubDescPlanSauTit            INTEGER;

  vgCdRubDescPlanSauAgr            INTEGER;

  --vgCdRubDescCoPart                INTEGER;

  vgCdEventoDescCoPart              INTEGER;

  vgCdEventoRescisaoACT            INTEGER;

  vgCdRubUmTercoFerias             INTEGER;

  vgCdRubAbonoPecuniario           INTEGER;

  vgCdRubDifAbonoPecuniario        INTEGER;

  vgCdRubAdiantSalFerias           INTEGER;

  vgCdRubDifUmTercoFerias          INTEGER;

  vgCdRubDevUmTercoFerias          INTEGER;

  vgCdRubBloqRetroativo            INTEGER;

  vgCdRubBloqueioRescisao          INTEGER;

  vgCdRubDepositoJud               INTEGER;

  vgCdRubricaDevAnt13              INTEGER;

  vgCdRubFeriasIndenizadas         INTEGER;

  vgCdRubFeriasIndenizadasACTSJC   INTEGER;

  vgCdRubFeriasIndenizadasVinc   INTEGER;

  vgCdRubFeriasIndenUmTerco        INTEGER;

  vgCdRubDevAnt13NaoEfetuado       INTEGER;

  vgCdRubDescontoIRESA             INTEGER;

  vgCdValRefTetoDecJud             INTEGER;
  
  vgCdMotivoConvocacao             integer;

  vgCarreira                       PKGPAG_TIPO.tCarreira;

  vgEvento                         PKGPAG_TIPO.tEvento;

  vgVantagem                       PKGPAG_TIPO.tVantagemPecuniaria;

  vgRegraSalFamilia                PKGPAG_TIPO.tSalFamilia;

  vgRubrica                        PKGPAG_TIPO.tRubrica;

  vgValorCalculoRubrica            PKGPAG_TIPO.tValorCalculoRubrica;

  vgRubricaLanc                    PKGPAG_TIPO.tRubrica;

  vgValorReferenciaMAXINSS         NUMBER(13,2);

  vgValorReferenciaVLDCI           NUMBER(13,2);

  vgValorReferencia                PKGPAG_TIPO.tValorReferencia;

  vgRubricaExcludente              PKGPAG_TIPO.tRubExcludente;

  vgFormExpr                       PKGPAG_TIPO.tFormulaCalculo;

  vgBaseExpr                       PKGPAG_TIPO.tBaseCalculo;

  vgAuxilioAli                     PKGPAG_TIPO.tAuxilioAli;

  vgAuxilioAliAnt                  PKGPAG_TIPO.tAuxilioAli;

  vgCEF                            PKGPAG_TIPO.tCEF;

  vgFUC                            PKGPAG_TIPO.tFUC;

  vgFUCSubst                       PKGPAG_TIPO.tFUC;

  vgCCO                            PKGPAG_TIPO.tCCO;

  vgCCOSubst                       PKGPAG_TIPO.tCCO;

  vgAPO                            PKGPAG_TIPO.tCEF;

  vgAPOSemParidade                 PKGPAG_TIPO.tCEF;

  vgBOL                            PKGPAG_TIPO.tBOL;

  vgPensaoNaoPrev                  PKGPAG_TIPO.tPensaoNaoPrev;

  vgPensaoPrev                     PKGPAG_TIPO.tPensaoPrev;

  vgRelVinc                        PKGPAG_TIPO.tRelVinc;

  vgLsInvRel                       PKGPAG_TIPO.rLsInvRel;

  vgLsInvRelVinc                   PKGPAG_TIPO.rLsInvRel;

  vgLancComplementar               PKGPAG_TIPO.tLancComplementar;

  vgLancFinanceiro                 PKGPAG_TIPO.tLancFinanceiro;

  vgVlTotalDescErarioMes           NUMBER(13,2);

  vgContribPlanoSaudeAgregado      PKGPAG_TIPO.tContribPlanoSaudeAgregado;

  vPagaSitDisposicao               VARCHAR2(30);

  vgRelVincPrincipal               PKGPAG_TIPO.rRelVincPrincipal;

  vgCargaHoraria                   PKGPAG_TIPO.tCargaHoraria;

  vgCargaHorariaCEF                PKGPAG_TIPO.tCargaHoraria;

  vgCargaHorariaCCO                PKGPAG_TIPO.tCargaHoraria;

  vgCargaHorariaFUC                PKGPAG_TIPO.tCargaHoraria;

  vgCargaHorariaAPO                PKGPAG_TIPO.tCargaHoraria;

  vgNuDiasCargaHorariaZero         NUMBER;
  
  vgRubAnoMesFixo                  INTEGER;
  -- Numero de faltas integrais

  vgCdRubEvento81       INTEGER;

  vgCdRubEvento82       INTEGER;

  vgFaltas                         PKGMOVFRE.tipoTabFalta;

  vgIndiceFaltas                   NUMBER;  -- Quantidade de faltas  (em decimal)

  vgIndiceRub010431                   NUMBER;  -- Quantidade de faltas  (em decimal)

  vgIndiceFaltasMesAtual           NUMBER;  -- Quantidade de faltas mes da folha (em decimal)

 vgIndiceFaltasMesAnterior        NUMBER;  -- Quantidade de faltas mes anterior ao da folha (em decimal)

  vgIndiceFaltasSomenteDiasUteis   NUMBER;  -- Quantidade de faltas em dias uteis (em decimal)

  vgIndiceAbonoRetro               NUMBER;  -- Quantidade de abonos retroativos  (em decimal)

  vgIndiceAbonoRetroDiasUteis      NUMBER;  -- Quantidade de abonos retroativos  (em decimal) dias uteis.

   vgFalta tFalta;

  -- Menor data dos afastamentos retroativos lancados no periodo da folha

  vgDtMinDataAfastRetro            DATE;

  -- Registro de apurac?o de frequencia

  vgApuracaoFrequencia             EMovApuracaoFrequencia%ROWTYPE;

  -- Parametro de vale transporte

  vgIndicadorValeTransp            EVtrHistOrgaoIndicadorVale%ROWTYPE;

  -- Parametros de ferias do orgao

  vgOrgaoFeriasParam               EMovOrgaoFerias%ROWTYPE;

  -- Parametros de frequencia do orgao

  vgOrgaoFrequenciaParam           EMovOrgaoFrequencia%ROWTYPE;

  vgRegRelVincFolha                INTEGER DEFAULT 0;

  -- Codigo da rubrica referente a Restituic?o do Erario

  vgCdRubricaErario             INTEGER;

  -- Codigo da rubrica referente a base de consignac?o

  vgCdRubricaBaseConsig         INTEGER;
  vgTblRubCNSAlim               PKGPAG_TIPO.tPensaoAlim;
  -- Codigo da rubrica referente a base de total liquido

  vgCdRubricaBaseTotLiq          INTEGER;

  -- Codigo da rubrica referente a base de total de descontos

  vgCdRubricaBaseTotDsc          INTEGER;

  -- Codigo da rubrica referente a base de ferias

  vgCdRubricaBaseFerias          INTEGER;

  -- Codigo da rubrica referente a base de baixa de ferias

  vgCdRubBaseBaixa               INTEGER;

  vgCdRubFeriasFGTS              INTEGER;

  vgCdRubBaseValorPatINSS        INTEGER;

  -- Codigo da rubrica referente a base de total de proventos

  vgCdRubricaBaseTotPrv          INTEGER;

  -- Codigo da rubrica referente a margem consignavel liquida

  vgCdRubricaBaseCsgLiq          INTEGER;
  
  -- Código de rubrica de margem bruta para consignações não geridas pelo E-Consig
  
  vgCdRubBaseCsgBrutaOutros      INTEGER;
  
  -- Código de rubrica de margem líquida para consignações não geridas pelo E-Consig
  
  vgCdRubBaseCsgLiqOutros        INTEGER;

  -- Codigo da rubrica referente a margem de reserva futura das consignacoes

  vgCdRubBaseCsgMargFut          INTEGER;

  -- Codigo da rubrica associada a modalidade de margem consignavel bruta de cart?o de credito

  vgCdRubricaBaseCSG_CC          INTEGER;
  vgCdRubricaBaseCsgLiq_CC       INTEGER;

  vgValorAcumulado_CC              NUMBER(13,2);

  -- Codigo da rubrica referente a consignacoes processadas

  vgCdRubricaCSGProc             INTEGER;

  -- Codigo da rubrica referente a consignacoes nao processadas ou residuos

  vgCdRubricaCSGNaoProc          INTEGER;

  -- Codigo da rubrica referente a base de contribuic?o de plano de saude

  vgCdRubricaBasePlanoSaude      INTEGER;

  -- Codigo da rubrica referente a base de contribuic?o de plano de saude patronal

  vgCdRubricaBasePSPatronal      INTEGER;

  -- Codigo da rubrica referente a base de co-participac?o do plano de saude

  vgCdRubricaBaseCoParticip      INTEGER;

  -- Codigo da rubrica referente a valor de desconto de dependentes de IRRF

  vgCdRubricaDescDepIRRF         INTEGER;

  vgCdRubricaBaseINSSPat         INTEGER;

  -- Codigo da rubrica referente a base do teto do governador

  vgCdRubricaBaseTetoGov         INTEGER;

  -- Codigo da rubrica referente a base do teto do governador de 13

  vgCdRubricaBaseTetoGov13       INTEGER;

   -- Codigo da rubrica referente a base de 13 salario

   vgCdRubBase13Sal               INTEGER;

   -- Codigo da rubrica associada a base de Abono para a Seguranca Publica

   vgCdRubBaseAbonoSeguranca     INTEGER;

   -- Codigo da rubrica referente ao teto do governador

  vgCdRubricaTetoGov             INTEGER;

  -- Codigo da rubrica de desconto de dias afastados

  vgCdRubAgrupDescDiasAfast      INTEGER;

  -- Codigo Base EPAGRI

  vgCdRubBaseCeres               INTEGER;

  --Parametro desco 08-0024

  vgCdRubDevProv13Sal            INTEGER;

  --

  vgNuDiasSubst                  INTEGER;

  vgNuDiasSubstFUC               INTEGER;

  vgNuDiasFUC                    INTEGER;

  vgNuDiasFeriasNaoPagas         INTEGER;

  vgNuDiasFeriasPrevistos        INTEGER;

  --
  vgNuDiasCEF                    INTEGER;

  vgNuDiasCCO                    INTEGER;

  vgNuDiasApo                    INTEGER;
  
  vgNuDiasCtisp                  INTEGER;

  vgCdRubBaseDeducaoInativo      INTEGER;

  vgCdRubricaCSGProcCC           INTEGER;

  vgCdRubBaseFGTS                INTEGER;

  vgCdRubBaseFGTS13              INTEGER;

  vgCdRubVlFGTS                  INTEGER;

  vgCdRubVlFGTS13                INTEGER;

  vgCdRubBaseIPREVFP             INTEGER;

  vgCdRubBaseIPREVFF             INTEGER;

  vgCdRubBaseProv13PatFP         INTEGER;

  vgCdRubBaseProv13PatFF         INTEGER;
  
  vgCdRubBaseProv13FT            INTEGER;
  
  vgCdRubBaseIPREVFT             INTEGER;

  vgCdRubBaseProv13PatINSS       INTEGER;

  vgCdRubBaseProv13PatINSSCLT    INTEGER;

  vgCdRubBaseCSPM                integer;

  vgCdRubDescCSPM                integer;

  vgCdRubBaseProv13VlFGTS        INTEGER;

  vgCdRubBaseINSSCLT             INTEGER;

  vgCdRubDeducaoIRRFOutros       INTEGER;

  vgCdRubBaseIRRFOutros          INTEGER;

  vgCdRubBaseSCSAUDEOutros       INTEGER;

  vgCdRubDeducaoSCSAUDEOutros    INTEGER;

  vgCdRubBaseRateio              INTEGER;

  vgCdBaseSalMaternidade         INTEGER;

  vgCdRubBaseDescFacultativos    INTEGER;

  vgCdRubBase080023DescParcial   INTEGER;

  vgCdRubBase080024DescParcial   INTEGER;

  bProcessaBloqueio              BOOLEAN;

  bFlPossuiProventos             BOOLEAN;
  
  bProcessandoDuploVinculo       BOOLEAN := false;

-- Armazenam informac?es de conta bancaria

  vgDtOpcaoFGTS                  DATE;

  vFlPossuiContaBancoOficial     CHAR(1);

  vgCdAgenciaCredito             ECADHISTDADOSBANCARIOSVINCULO.CDAGENCIACREDITO%TYPE;

  vgNuContaCredito               ECADHISTDADOSBANCARIOSVINCULO.Nucontacredito%type;

  vgNuDvContaCredito             ECADHISTDADOSBANCARIOSVINCULO.Nudvcontacredito%type;

  vgCdAgenciaReceb               ECADHISTDADOSBANCARIOSVINCULO.Cdagenciareceb%type;

  vgNuContaReceb                 ECADHISTDADOSBANCARIOSVINCULO.Nucontareceb%type;

  vgFlTipoContaCredito           ECADHISTDADOSBANCARIOSVINCULO.Fltipocontacredito%type;

  vgNuAgencia                    ECADAGENCIA.Nuagencia%type;

  vgNuDvAgencia                  ECADAGENCIA.Nudvagencia%type;

  vgNuBanco                      ECADBANCO.Nubanco%type;

  bPossuiACT                     BOOLEAN;

  bSemIntersticio                BOOLEAN;

  -- Armazena os valores de aliquota do IPESC

  vAliqIPESCAtivo           PKGPAG_TIPO.rAliquotaIPESC;

  vAliqIPESCInativo         PKGPAG_TIPO.rAliquotaIPESC;

  vAliqIPESCParcial         PKGPAG_TIPO.rAliquotaIPESC;

  vAliqCPSM                 pkgpag_tipo.rAliquotaCPSM;

  vgCdRubBaseCPSM           integer;

  vgCdRubBaseCPSM13         integer;

  vgCdRubDescCPSM           integer;

  vgCdRubDescCPSM13         integer;
  -- Armazena os valores de aliquota do INSS

  vAliqINSS                 PKGPAG_TIPO.rAliquotaINSS;

  vAliqInssContribIndiv     NUMBER(10,4);

  -- Armazena os valores de aliquota do IRRF

  vAliquotaIRRF             PKGPAG_TIPO.rAliquotaIRRF;

  -- Variaveis utilizadas para armazenar os valores da pens?o e IRRF
  -- recalculados em virtude da utilizac?o de rubricas de pens?o na formula
  -- do IRRF

  vgValorIRRFAnterior         NUMBER(13,2);

  vgValorPensaoAnterior       NUMBER(13,2);

  vgValorBasePlanoSaude       NUMBER(13,2);

  vgValorBaseCoPart           NUMBER(13,2);

  vgValorDescLiqNegativo       NUMBER(13,2);

  -- Armazena o codigo da rubrica do agrupamento associada a base do IRRF

  vgCdRubBaseIRRF               INTEGER;

  vgCdRubBaseRRA                INTEGER;

  vgCdRubBaseIRRFFerias         INTEGER;

  vgCdRubBaseIRRF13             INTEGER;

  vgCdRubBaseIPESC              INTEGER;

  vgCdRubBaseIPESC13            INTEGER;

  vgCdRubBaseINSS               INTEGER;

  vgCdRubVlINSSPatronalBruto    INTEGER;

  vgCdRubBaseINSS13             INTEGER;
  
  vgCdRubBaseDeducoesIRRFOutros INTEGER;
  
  vgCdRubBaseDeducoesIRRF       INTEGER;
    
  vgCdRubBaseTotDeducoesIRRF13  INTEGER;
    
  vgCdRubBaseDescSimplif13      INTEGER;
    
  vgCdRubBaseDedIRRFOutros13    INTEGER;
    
  vgCdRubBaseDescSimplifIRRF    INTEGER;

  vgCdRubAgrupDifDescIRRF       INTEGER;

  vgCdRubAgrupDevDescIRRF       INTEGER;

  vgCdRubAgrupDifDescIRRF13     INTEGER;

  vgCdRubAgrupDevDescIRRF13     INTEGER;

  vgCdRubAgrupDifDescIRRFFerias INTEGER;

  vgCdRubAgrupDifDescINSS       INTEGER;

  vgCdRubAgrupDevDescINSS       INTEGER;

  vgCdRubAgrupDifDescINSS13     INTEGER;

  vgCdRubAgrupDevDescINSS13     INTEGER;

  vgCdRubAgrupDevDescIRRFFerias INTEGER;

  vgDeExpressaoBaseIRRF         VARCHAR2(300);

  vgCdRubExigibilidadeSusp      INTEGER;
  
  vgCdRubExigibilidadeSusp13    INTEGER;

  vgCdRubExigibilidadeSuspRRA   INTEGER;

  vgCdRubBaseFaltaRetroNaoDesc  INTEGER;

  vgCdRubBaseAlimRetroNaoDesc   INTEGER;

  vgCdRubBasePensaoNaoDesc      INTEGER;

  vgCdRubBaseDevAd13NaoEfet     INTEGER;

  vgCdValorReferencia100        INTEGER; -- Valor Referencia Bonus Hab 100

  vgCdValorReferencia300        INTEGER; -- Valor Referencia Bonus Hab 300

  vgVlDeducaoDependente         NUMBER(13,2) DEFAULT 0.0;

 vgVlDeducaoDependOutroVinc    NUMBER(13,2) DEFAULT 0.0;

  vgVlBaseTotalLiquida          NUMBER(13,2) DEFAULT 0.0;

  vgVlTotalProventos            NUMBER(13,2);

  vgVlTotalDescontos            NUMBER(13,2);

  vgVlBaseTotDSC                NUMBER(13,2);

  vgVlTotalDescontosFacult      NUMBER(13,2);

  vvlBaseSaldoAuxAlimNaoDesc    NUMBER(13,2);

  vvlSaldoAuxAlimNaoDesc        NUMBER(13,2);
  
  vgVlIndUniforme               NUMBER(13,2); -- Valor referência indenização uniforme

  vNuDiasAuxAlimNaoDesc         NUMBER(5,2);

  vDescAuxAlimNaoDesc           varchar2(500);

  vgVlTotalPensaoLiquida        NUMBER(13,2);

  -- Valor do teto determinado por decis?o judicial

  vgVlRefTetoDecJud            NUMBER(13,2);

  vgCdFolha13                  INTEGER;

  vgCdFolha13Ant               INTEGER;

  vgPercDecJudMargem           NUMBER(9,4);

  vListaRubricas               PKGPAG_TIPO.tListaValor;

  vgListaContribSind           PKGPAG_TIPO.tLista;

  vgRubPermitidasTpFolha       PKGPAG_TIPO.tLista;

  vgListaRubFuncaoPrivativa    PKGPAG_TIPO.tLista;

  -- Armazena o codigo da rubrica do agrupamento associada a base de Desconto do Vale Transporte

  vgCdRubBaseVP               INTEGER;

  -- Armazena a ordem de desconto das consignac?es

  vgOrdemDescConsig           INTEGER;

  -- Lista que armazena as relac?es de trabalho do vinculo

  vgListaRelTrab              PKGPAG_TIPO.tLista;

  bTemPlanoSaudeSaudeNoMes    BOOLEAN DEFAULT FALSE;

 -- Parametro dos dias uteis que devem ser considerados para o auxilio alimentac?o

 vgNuTipoDiaNaoUtil          INTEGER;

 -- Percentual acumulado de Adicional de tempo de servico

 vgPercentAcumATS             PKGPAG_TIPO.tListaValor;

 vgPercentATS         PKGPAG_TIPO.tPercentATS;

 /* Variavel utilizada para calculo da rubrica de recis?o de 13 quando a data de desligamento e
    anterior ao mes de processamento                                                          */

 vgCdRubricaRecisao13        INTEGER;
 vgCdRubricaRecisao13CTISP        INTEGER;
 vgCdRubricaRecisao13PENSAO      INTEGER;
 -------------------------------------------------------------------------------------------------
 -- Variaveis utilizadas para o calculo de adiantamento de 13 salario
 -------------------------------------------------------------------------------------------------

 vgCdFolhaNormal             INTEGER;

 vgCdFolhaRecalculo          INTEGER;

 vgCdFolhaSuplementar        INTEGER;
 
 vgCdFolhaSuplementarVinculo INTEGER;

 vgCdFolhaFerias             INTEGER;

 vgCdFolhaIndenizatoria      INTEGER;

 vgCdRubAgrup13              INTEGER;

 vgCdFolhaReplicada13        INTEGER;

 vgCdRubAgrup13CTISP         INTEGER;

 vgCdRubAdiant13CTISP        INTEGER;

 vgCdRubAgrup13Alt           INTEGER;

 vgCdRubAgrupAntecip13       INTEGER;

 vgCdRubAgrupAntecip13CTISP  INTEGER;

 vgCdRubAgrupAntecip13Alt    INTEGER;

 vgVlBase1467                NUMBER(13,2);

 bReprocessou13Sal           BOOLEAN;

 --------------------------------------------------------------------------------------------------
 -- Variavel que indica se possui abono de permanencia. Utilizado na tributac?o do calc do 13 Sal
 --------------------------------------------------------------------------------------------------

 vgCdRubricaAbonoPerm          INTEGER;
 
 vgDtInicioConcessaoAbonoPerm  DATE;

 --------------------------------------------------------------------------------------------------
 -- Variavel para armazenar parametros de Eventos de recadastramento
 --------------------------------------------------------------------------------------------------

 vgEventoRecadastramento      EPvdHistEventoRecadastramento%ROWTYPE;

 --------------------------------------------------------------------------------------------------
 -- Variavel para armazenar parametros de Eventos de recadastramento
 --------------------------------------------------------------------------------------------------

 vMotAfast                    PKGPAG_TIPO.rMotAfast;

 vgQtFaltas                   INTEGER;

 vgFaseCalculo                INTEGER;

 vgEventoCarreira             PKGPAG_TIPO.tEventoCarreira;

 vgParamCCO                   PKGPAG_TIPO.tParamAgrupCCO;

 vgCdEstruturaCarreira        INTEGER;

 vCdFolhaSuplAux              INTEGER;

 vgCdRubAbono13Ferias         INTEGER;

 vgPercentPensaoNaoPrev       NUMBER(9,4);

 vgListaAfastDecJudAlim       VARCHAR2(4000);

 vgVlPercentReducao           NUMBER(7,4);

 bTemEfetivoOutroOrgao        BOOLEAN;

 bTemEfetivoAnyOrgao          BOOLEAN;

 vgParamATSAcum               PKGPAG_TIPO.tRegraAdicTempServAcum;

 vgMediaCHOHoraAtividade      NUMBER(5,2);

 vgNuIndiceHoraPlantao        NUMBER(13,4);

 vgLimMediaHoraExtra          NUMBER(13,6);

 vgLimMediaAdNoturno          NUMBER(13,6);

 vgCdRubricaHoraPlantao       INTEGER;

 bPossuiFolhaSuplDef          BOOLEAN;

 vgListaOutraRubCondPag       PKGPAG_TIPO.tLista;

 vgCalculo                    PKGPAG_CAL.rCalculo;

 vPercentualTotalATS          PKGPAG_TIPO.tListaValor;

 vgSentenca                   PKGPAG_TIPO.tSentenca;

 vgListaTipoPNPRecad          PKGPAG_TIPO.tLista;

 vgVlIntegralIPREV            NUMBER(13,2);

 -------------------------------------------------------------------------------------------------
 -- Tipos de afastamentos
 -------------------------------------------------------------------------------------------------
 vgAfastTempRemun             PKGPAG_TIPO.tAfastamento;

 vgAfastTempRemunMesAnt       PKGPAG_TIPO.tAfastamento;

 vgAfastTempNaoRemun          PKGPAG_TIPO.tAfastamento;

 vgAfastTempNaoRemunMesAnt    PKGPAG_TIPO.tAfastamento;

 vgAfastDefinitivo            PKGPAG_TIPO.tAfastamento;

 vgAfastRelVinc               PKGPAG_TIPO.tAfastamento;

 vgAfastAnulado               PKGPAG_TIPO.tAfastamento;

 vgAfastAuxAlimentacao        PKGPAG_TIPO.tAfastamento;

 vgNuDiasAfastSemRemun        INTEGER;

 vgNuDiasAfastSemRemunMesAtual INTEGER;

 vgNuDiasAfastRemun           INTEGER;

 vgNuDiasAfastDefinitivo      INTEGER;

 vgNuDiasAfastRelVinc         INTEGER;

 vgNuDiasTrabalhados        INTEGER;

 bPossuiAfastNaoRemunUltDiaMes BOOLEAN;

 bPossuiAfastRemunUltDIaMes    BOOLEAN;

 vgListaEventoAfastDevErario   PKGPAG_TIPO.tLista;

 vgListaEventoAfast11          PKGPAG_TIPO.tLista;

 vgNuDiasAfastRetroativo       INTEGER;

 vgNuDiasAfastAuxAlimRet       INTEGER;

 vgPagCalc                     PKGPAG_TIPO.rpagcalc;

 vgAfastGravidez               PKGPAG_TIPO.rAfastGravidez;

 vgCdAfastAnuladoSemRemun      INTEGER := 0;

 vglindice010229               INTEGER := 0;
 --------------------------------------------------------------------------------------------------
 -- Variavel para armazenar referencias de valor
 --------------------------------------------------------------------------------------------------

 vgFgtsJa                     NUMBER(13,2);
 vgVlEraCTISP                 NUMBER(13,2);
 vgVlRefRetroObito            NUMBER(13,2);
 vgVlCRPECN                   pkgpag_tipo.tListaValor;

 --------------------------------------------------------------------------------------------------
 -- Variavel para armazenar Grau de Escolaridade
 --------------------------------------------------------------------------------------------------

 vgNuGrauEscolaridade                     INTEGER;
 --------------------------------------------------------------------------------------------------
 -- Tratamento do Auxilio Creche
 --------------------------------------------------------------------------------------------------

CURSOR cAuxCreche (pNuAnoReferencia IN INTEGER,
                   pNuMesReferencia IN INTEGER) IS
      SELECT CdOrgao,
             CdBaseCalculo,
             NuIdadeMaxDependente,
             CdValorRefLimite,
             QtUnidValorRefLimite
        FROM EBpcAuxilioCrecheParametro
       WHERE ( NuAnoInicioVigencia < pNuAnoReferencia OR (NuAnoInicioVigencia = pNuAnoReferencia
                                                         AND NuMesInicioVigencia <= pNuMesReferencia) )
        AND (NuAnoFimVigencia > pNuAnoReferencia
            OR (NuAnoFimVigencia = pNuAnoReferencia and NuMesFimVigencia >= pNuMesReferencia)
            OR NuAnoFimVigencia is null)
        AND FlAnulado = 'N';

CURSOR cAuxCrecheFaixa (pNuAnoReferencia  IN INTEGER,
                        pNuMesReferencia  IN INTEGER,
                        pCdOrgao          IN INTEGER) IS

      select
       vlInicialBaseCalculo,
       vlFinalBaseCalculo,
       vlEspecifico,
       qtUnidValorReferencia,
       cdValorReferencia
        from EBPCAUXCRECHEFAIXA f,
             EBPCAUXILIOCRECHEPARAMETRO p
       where f.cdAuxilioCrecheParametro = p.Cdauxiliocrecheparametro
         and ( nuanoiniciovigencia < pNuAnoReferencia
               or (nuanoiniciovigencia = pNuAnoReferencia and numesiniciovigencia <= pNuMesReferencia) )
         and (nuanofimvigencia > pNuAnoReferencia
              or (nuanofimvigencia = pNuAnoReferencia and numesfimvigencia >= pNuMesReferencia)
              or nuanofimvigencia is null)
         and cdOrgao = pCdOrgao
         and flanulado = 'N'
       ORDER BY vlInicialBaseCalculo;

vgAuxCreche                  PKGPAG_TIPO.tAuxCreche;

/* Cursor cFolha: Seleciona as relacoes de vinculo com os historicos de niveis e
                  referencias vigentes no Ano/Mes de referencia e os respectivas
                  datas de inicio e fim
*/
  CURSOR cFolha(pcdFolhaPagamento IN INTEGER) IS
   SELECT FP.CdFolhaPagamento,
          FP.CdOrgao,
          O.CdAgrupamento,
          FP.nuAnoReferencia,
          FP.nuMesReferencia,
          FP.CdTipoFolhaPagamento,
          TFP.CdTipoFolha,
          FP.CdTipoCalculo,
          FP.nuVersaoTabCEF,
          FP.nuVersaoTabFUC,
          FP.nuVersaoTabCCO,
          FP.NuVersaoTabvalorreferencia,
          FP.NuVersaoBaseCalculo,
          FP.NuVersaoFormulaCalculo,
          FP.FlLancamentoFinanceiro,
          FP.FlLancFinancComplementar,
          FP.CdFolhaVincSupl,
          FP.CdFolhaOrigem,
          HTFP.CdHistTipoFolhaPagamento,
          HTFP.FlPagaTodasRubricas,
          HTFP.InPagamentoRubrica,
          FP.FlCalculoDefinitivo,
          FP.DtPrevisaoCredito,
          TO_DATE(NuAnoReferencia * 100 + NuMesReferencia, 'YYYYMM') AS DtInicioMes,
          LAST_DAY(TO_DATE(NuAnoReferencia * 100 + NuMesReferencia, 'YYYYMM')) AS DtFimMes,
          HTFP.FlIncluiFerias,
          HTFP.FlIncluiAdiantamento13,
          O.FlImplantado,
          O.NuAnoMesImplantacao,
          FP.DtAbertura,
          FP.DtCalculo,
          0 AS CdFolhaPagamentoNormal,
          0 AS CdFolhaPagamentoNormalAnt,
          TO_DATE(NULL) AS DtCalculoAnt,
          FP.NuSequencialFolha,
          FP.FlIgnoraInclusaoFutura,
          HO.CdTipoOrgao,
          NuAnoMesReferencia,
          DeOrdemExecucao
          
     FROM EPagFolhapagamento FP
    INNER JOIN EPagHistTipoFolhaPagamento HTFP
       ON FP.CdTipoFolhaPagamento = HTFP.CdTipoFolhaPagamento
    INNER JOIN eCadOrgao O
       ON O.CdOrgao = FP.CdOrgao
    INNER JOIN ECadHistOrgao HO
       ON HO.CdOrgao = O.CdOrgao
    INNER JOIN EPagTipoFolhaPagamento TFP
       ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
    WHERE FP.CdFolhaPagamento = pCdFolhaPagamento AND
          ((FP.DtCalculo BETWEEN HO.DtInicioVigencia AND HO.DtFimVigencia) OR
           HO.DtFimVigencia IS NULL) AND
          ((HTFP.NuAnoInicioVigencia < FP.NuAnoReferencia OR
          (HTFP.NuAnoInicioVigencia = FP.NuAnoReferencia AND
           HTFP.NuMesInicioVigencia <= FP.NuMesReferencia))
          AND
          (HTFP.NuAnoFimVigencia > FP.NuAnoReferencia OR
          (HTFP.NuAnoFimVigencia = FP.NuAnoReferencia AND
           HTFP.NuMesFimVigencia >= FP.NuMesReferencia) OR
           HTFP.NuAnoFimVigencia IS NULL));

 /* Cursor cVinculo: Seleciona as relacoes de vinculo com os historicos de niveis e
                     referencias vigentes no Ano/Mes de referencia e os respectivas
                     datas de inicio e fim
*/
  CURSOR cVinculo(pCdPessoa  IN INTEGER,
                  pCdOrgao   IN INTEGER,
                  pDtInicio  IN DATE,
                  pDtFim     IN DATE,
                  pDtCalculo IN DATE) IS

      SELECT V.CdVinculo,
             V.CdPessoa,
             V.CdOrgao,
             0 AS CdSituacaoPrevidenciaria,
             V.CdRegimeTrabalho,
             V.CdRegimePrevidenciario,
             V.DtAdmissao,
             V.DtDesligamento,
             P.DtNascimento,
             V.DtInclusao,
             P.FlSexo,
             V.CdOpcaoAuxilioAli,
             'N' AS FlPagamentoBloqueado
     FROM ECadVinculo V
     INNER JOIN ECadPessoa P
        ON P.CdPessoa = V.CdPessoa
     WHERE V.cdPessoa = pCdPessoa AND
           V.FlAnulado = PKGPAG_TIPO.cnN AND
           (((V.DtAdmissao <= pDtFim AND
            (V.DtDesligamento >= pdtInicio OR V.DtDesligamento IS NULL)) AND
           ((V.CdOrgao = pCdOrgao AND
             NOT EXISTS
                (SELECT 1
                   FROM eCadHistCargoCom HCC
                  WHERE HCC.CdVinculo = V.CdVinculo AND
                        HCC.CdOrgaoExercicio <> pCdOrgao AND
                        HCC.CdCargoComRemuneracao IS NULL AND
                             --- Comentado porque ate ent?o devia considerar o cargo comissionado em qualquer dia dentro do mes/ano do processamento
                        /*(HCC.DtInicio <= pdtFim AND
                        (HCC.DtFim >= pdtInicio OR HCC.DtFim IS NULL))*/
                             --- Agora deve-se considerar se existe cargo comissionado na data do calculo da folha
                        (HCC.DtInicio <= pDtCalculo AND
                        (HCC.DtFim >= pDtCalculo OR HCC.DtFim IS NULL)) AND
                        HCC.FlAnulado = PKGPAG_TIPO.cnN))

                  OR
                  (EXISTS
                     (SELECT 1
                        FROM eCadHistCargoCom HCC
                       WHERE HCC.CdVinculo = V.CdVinculo AND
                             HCC.CdOrgaoExercicio = pCdOrgao AND
                             HCC.CdCargoComRemuneracao IS NULL AND
                             --- Comentado porque ate ent?o devia considerar o cargo comissionado em qualquer dia dentro do mes/ano do processamento
                        /*(HCC.DtInicio <= pdtFim AND
                        (HCC.DtFim >= pdtInicio OR HCC.DtFim IS NULL))*/
                             --- Agora deve-se considerar se existe cargo comissionado na data do calculo da folha
                            (HCC.DtInicio <= pDtCalculo AND
                            (HCC.DtFim >= pDtCalculo OR HCC.DtFim IS NULL)) AND
                            HCC.FlAnulado = PKGPAG_TIPO.cnN))
                  OR
                  (EXISTS
                     (SELECT 1
                        FROM ECadhistcargoefetivo HCEF
                       WHERE HCEF.CdVinculo = V.CdVinculo AND
                             HCEF.Cdorgaoexercicio = pCdOrgao AND
                             (HCEF.DtInicio <= pdtFim AND
                             (HCEF.DtFim >= pdtInicio OR HCEF.DtFim IS NULL)) AND
                             HCEF.FlAnulado = PKGPAG_TIPO.cnN) AND
                             NOT EXISTS
                              (SELECT 1
                                 FROM eCadHistCargoCom HCC
                                WHERE HCC.CdVinculo = V.CdVinculo AND
                                      HCC.CdOrgaoExercicio <> pCdOrgao AND
                                      HCC.CdCargoComRemuneracao IS NULL AND
                                 -- Comentado porque ate ent?o devia considerar o cargo comissionado em qualquer dia dentro do mes/ano do processamento
                                   /*(HCC.DtInicio <= pdtFim AND
                                     (HCC.DtFim >= pdtInicio OR HCC.DtFim IS NULL))*/
                                 --- Agora deve-se considerar se existe cargo comissionado na data do calculo da folha
                                     (HCC.DtInicio <= pDtCalculo AND
                                     (HCC.DtFim >= pDtCalculo OR HCC.DtFim IS NULL)) AND
                                     HCC.FlAnulado = PKGPAG_TIPO.cnN)))) OR
               (V.DtDesligamento < pdtInicio AND
               EXISTS (SELECT 1
                         FROM Epaglancamentofinanceiro F
                         WHERE F.CdVinculo = V.CdVinculo AND
                               F.FlPagaAfastDefinitivo = PKGPAG_TIPO.cnS AND
                               F.DtInicioDireito <= pdtFim AND
                               (F.DtFimDireito >= pdtInicio OR F.DtFimDireito IS NULL))) OR
               EXISTS (SELECT 1
                         FROM eAfaAfastamentoVinculo AV
                        WHERE AV.CdVinculo = V.CdVinculo AND
                              V.CdOrgao = pCdOrgao AND
                              AV.FlTipoAfastamento = PKGPAG_TIPO.cnD AND
                              AV.FlAnulado = PKGPAG_TIPO.cnN AND
                              TRUNC(AV.DtInclusao) BETWEEN (vDtCalculoAnt + 1)AND (pDtCalculo)))
     ORDER BY V.Nuseqmatricula;

 /*Cursores utilizados para identicac?o de das relac?es de vinculo */

CURSOR cRelCEF(pCdVinculo         IN INTEGER,
               pCdRelacaoTrabalho IN INTEGER,
               pDtInicioMes       IN DATE,
               pDtFimMes          IN DATE) IS

     SELECT 1 AS CdTipoRelacao,
            CEF.CdHistCargoEfetivo,
            CEF.CdOrgaoExercicio,
            CEF.CdNaturezaVinculo,
            CEF.CdRelacaoTrabalho,
            CEF.CdRegimetrabalho,
            CEF.CdRegimePrevidenciario,
            HSP.CdSituacaoPrevidenciaria,
            CEF.CdEstruturaCarreira,
            LT.CdUnidadeOrganizacional,
            CEF.FlEfetivacao,
            CEF.DtInicio AS DtInicioRelacao,
            CEF.DtFim    AS DtFimRelacao,
            CASE
              WHEN CEF.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              CEF.Dtinicio
            END DtInicio,
            CASE
              WHEN CEF.DtFim > pdtFimMes OR CEF.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              CEF.DtFim
            END AS DtFim
       FROM ECadHistCargoEfetivo CEF
      INNER JOIN ECadHistSitPrevVinculo HSP
         ON CEF.CdVinculo = HSP.CdVinculo AND
            (CEF.DtInicio BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax))
       INNER JOIN (SELECT LT.CdHistCargoEfetivo,
                       MAX(DtInicio) AS DtInicio
                 FROM eCadLocalTrabalho LT
                WHERE LT.CdVinculo = pCdVinculo AND
                      LT.FlDefinitiva = PKGPAG_TIPO.cnS AND
                      LT.FlAnulado = PKGPAG_TIPO.cnN AND
                      LT.DtInicio <= PKGPAG_VAR.vDtCalculo AND
                      LT.CdHistCargoEfetivo IS NOT NULL
                GROUP BY LT.CdHistCargoEfetivo) LT1
        ON LT1.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo
     INNER JOIN ECadLocalTrabalho LT
        ON LT.CdHistCargoEfetivo = LT1.CdHistCargoEfetivo AND
           LT.FlDefinitiva = PKGPAG_TIPO.cnS AND -- Atenc?o: alterado em 31/05/2010
           LT.DtInicio = LT1.DtInicio AND
           (LT.DtFim >= pdtInicioMes OR LT.DtFim IS NULL) AND
           LT.FlAnulado = PKGPAG_TIPO.cnN
      WHERE CEF.CdVinculo = pCdVinculo AND
            ((CEF.CdRelacaoTrabalho = pCdRelacaoTrabalho OR pCdRelacaoTrabalho NOT IN (3,5,8,10)) OR
             (CEF.FlEfetivacao IN (PKGPAG_TIPO.cnR, PKGPAG_TIPO.cnS))) AND
            CEF.DtInicio <= pDtFimMes AND
            (CEF.DtFim >= pDtInicioMes OR CEF.DtFim IS NULL) AND
            CEF.Flanulado = PKGPAG_TIPO.cnN AND
            pkgpag_var.vgFolha.CdTipoFolha <> pkgpag_tipo.cnTpFolhaInstPensao

     UNION

     -- INSTITUIDOR DE PENSAO
     SELECT 1 AS CdTipoRelacao,
            CEF.CdHistCargoEfetivo,
            CEF.CdOrgaoExercicio,
            CEF.CdNaturezaVinculo,
            CEF.CdRelacaoTrabalho,
            CEF.CdRegimetrabalho,
            CEF.CdRegimePrevidenciario,
            HSP.CdSituacaoPrevidenciaria,
            CEF.CdEstruturaCarreira,
            LT.CdUnidadeOrganizacional,
            CEF.FlEfetivacao,
            CEF.DtInicio AS DtInicioRelacao,
            CEF.DtFim AS DtFimRelacao,
            CASE
              WHEN CEF.DtInicio < pdtInicioMes THEN
               pDtInicioMes
              ELSE
               CEF.Dtinicio
            END DtInicio,
            pDtFimMes AS DtFim
       FROM ECadHistCargoEfetivo CEF
      INNER JOIN ECadVinculo v
         ON v.cdvinculo = CEF.Cdvinculo
      INNER JOIN ECadHistSitPrevVinculo HSP
         ON CEF.CdVinculo = HSP.CdVinculo
        AND (CEF.DtInicio BETWEEN HSP.DtInicio AND
            NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))

      INNER JOIN ecadlocaltrabalho lt1
         ON LT1.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo
        AND LT1.DtInicio =
            (SELECT MAX(DtInicio) AS DtInicio
               FROM ecadlocaltrabalho lt
              WHERE LT.CdVinculo = CEF.CdVinculo
                AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                AND LT.FlAnulado = PKGPAG_TIPO.cnN
                AND LT.DtInicio <= pDtFimMes
                AND LT.CdHistCargoEfetivo IS NOT NULL)
        AND lt1.FlDefinitiva = 'S'
        AND lt1.FlAnulado = 'N'

     /*INNER JOIN (SELECT LT.CdHistCargoEfetivo,
                    MAX(DtInicio) AS DtInicio
              FROM eCadLocalTrabalho LT
             WHERE LT.CdVinculo = pCdVinculo AND
                   LT.FlDefinitiva = PKGPAG_TIPO.cnS AND
                   LT.FlAnulado = PKGPAG_TIPO.cnN AND
                   LT.DtInicio <= PKGPAG_VAR.vDtCalculo AND
                   LT.CdHistCargoEfetivo IS NOT NULL
             GROUP BY LT.CdHistCargoEfetivo) LT1
     ON LT1.CdHistCargoEfetivo = CEF.CdHistCargoEfetivo*/

      INNER JOIN EAfaRegistroObito o
         ON o.cdpessoa = v.cdpessoa
        AND o.cdagrupamento = pkgpag_var.vgFolha.CdAgrupamento
        -- AND rownum = 1 -- busca apenas um dos registros encontrados

      INNER JOIN ECadLocalTrabalho LT
         ON LT.CdHistCargoEfetivo = LT1.CdHistCargoEfetivo
        AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
        AND LT.DtInicio = LT1.DtInicio
        AND --LT.DtFim = o.dtobito-1 AND
            LT.FlAnulado = PKGPAG_TIPO.cnN

      WHERE CEF.CdVinculo = pCdVinculo
        AND ((CEF.CdRelacaoTrabalho = pCdRelacaoTrabalho OR
            pCdRelacaoTrabalho NOT IN (3, 5, 8, 10)) OR
            (CEF.FlEfetivacao IN (PKGPAG_TIPO.cnR, PKGPAG_TIPO.cnS)))
        AND CEF.DtInicio <= pDtFimMes
        AND --CEF.DtFim = o.dtobito-1 AND
            CEF.Flanulado = PKGPAG_TIPO.cnN
        AND pkgpag_var.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaInstPensao
        and o.flanulado = PKGPAG_TIPO.cnN;

  CURSOR cRelCCO(pCdVinculo         IN INTEGER,
                 pDtInicioMes       IN DATE,
                 pDtFimMes          IN DATE,
                 pDtCalculo         IN DATE) IS
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
           LT.CdUnidadeOrganizacional,
           CCO.FlTipoProvimento,
           CCO.DtInicio AS DtInicioRelacao,
           CCO.DtFim AS DtFimRelacao,
           CASE
              WHEN CCO.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              CCO.Dtinicio
            END DtInicio,
            CASE
              WHEN CCO.DtFim > pdtFimMes OR CCO.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              CCO.DtFim
            END AS DtFim
      FROM ECadHistCargoCom CCO
     INNER JOIN ECadHistSitPrevVinculo HSP
        ON CCO.CdVinculo = HSP.CdVinculo AND
           (CCO.DtInicio BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax))
     INNER JOIN ECadCargoComissionado C
        ON CCO.CdCargoComissionado = C.CdCargoComissionado
     INNER JOIN (SELECT LT.CdHistCargoCom,
                      MAX(dtInicio) AS DtInicio
                 FROM ecadLocalTrabalho LT
                WHERE LT.CdVinculo = pCdVinculo AND
                      LT.FlDefinitiva = PKGPAG_TIPO.cnS AND
                      LT.FlAnulado = PKGPAG_TIPO.cnN AND
                      LT.CdHistCargoCom IS NOT NULL AND
                      LT.DtInicio <= pDtFimMes
                GROUP BY LT.CdHistCargoCom) LT1
      ON LT1.CdHistCargoCom = CCO.CdHistCargoCom
   INNER JOIN ECadLocalTrabalho LT
      ON LT.CdHistCargoCom = LT1.CdHistCargoCom AND
         LT.Dtinicio = LT1.DtInicio AND
         (LT.DtFim >= pdtInicioMes OR LT.DtFim IS NULL) AND
         LT.FlAnulado = PKGPAG_TIPO.cnN
     WHERE CCO.CdVinculo = pCdVinculo AND
           ((CCO.DtFim IS NOT NULL OR (CCO.DtFim IS NULL AND CCO.CdCargoComRemuneracao IS NULL)) OR
           CCO.FlTipoProvimento = PKGPAG_TIPO.cnS) AND
           CCO.DtInicio <= pDtFimMes AND
           (CCO.DtFim >= pDtInicioMes OR CCO.DtFim IS NULL) AND
           CCO.Flanulado = PKGPAG_TIPO.cnN;

  CURSOR cRelFUC(pCdVinculo         IN INTEGER,
                 pDtInicioMes       IN DATE,
                 pDtFimMes          IN DATE) IS
    SELECT 3 AS CdTipoRelacao,
           FUC.CdHistFuncaoChefia,
           FUC.CdOrgaoExercicio,
           FUC.CdFuncaoChefia,
           LT.CdUnidadeOrganizacional,
           FUC.FlEfetivacao,
           FUC.DtInicio AS DtInicioRelacao,
           FUC.DtFim AS DtFimRelacao,
           CASE
              WHEN FUC.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              FUC.Dtinicio
            END DtInicio,
            CASE
              WHEN FUC.DtFim > pdtFimMes OR FUC.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              FUC.DtFim
            END AS DtFim
      FROM ECadHistFuncaoChefia FUC
   INNER JOIN (SELECT LT.CdHistFuncaoChefia,
                       MAX(DtInicio) AS DtInicio
                 FROM eCadLocalTrabalho LT
                WHERE LT.CdVinculo = pCdVinculo AND
                      LT.CdHistFuncaoChefia IS NOT NULL AND
                      LT.DtInicio <= PKGPAG_VAR.vDtCalculo AND
                      LT.FlAnulado = PKGPAG_TIPO.cnN
                GROUP BY LT.CdHistFuncaoChefia) LT1
         ON LT1.CdHistFuncaoChefia = FUC.CdHistFuncaoChefia
      INNER JOIN ECadLocalTrabalho LT
         ON  LT.CdHistFuncaoChefia = LT1.CdHistFuncaoChefia AND
             LT.DtInicio = LT1.DtInicio AND
            (LT.DtFim >= pdtInicioMes OR LT.DtFim IS NULL) AND
            LT.FlAnulado = PKGPAG_TIPO.cnN
     INNER JOIN ECadEvolucaoFuncaoChefia EFC
        ON FUC.CdFuncaochefia = EFC.CdFuncaoChefia
     WHERE FUC.CdVinculo = pCdVinculo AND
           FUC.DtInicio <= pDtFimMes AND
           (FUC.DtFim >= pDtInicioMes OR FUC.DtFim IS NULL) AND
           EFC.FlFuncaoGratificada = PKGPAG_TIPO.cnS AND
           EFC.DtInicioVigencia <= PKGPAG_VAR.vDtCalculo AND
          (EFC.DtFimVigencia >=PKGPAG_VAR.vDtCalculo OR EFC.DtFimVigencia IS NULL) AND
           FUC.FlAnulado = PKGPAG_TIPO.cnN;

  CURSOR cRelBOL(pCdVinculo         IN INTEGER,
                 pDtInicioMes       IN DATE,
                 pDtFimMes          IN DATE) IS
    SELECT 5 AS CdTipoRelacao,
           BOL.CdHistEstagio,
           V.CdOrgao AS CdOrgaoExercicio,
           BOL.CdNaturezaVinculo,
           BOL.CdRelacaoTrabalho,
           BOL.CdRegimetrabalho,
           V.CdRegimePrevidenciario,
           V.CdSituacaoPrevidenciaria,
           LT.CdUnidadeOrganizacional,
           BOL.DtInicio,
           BOL.DtFim AS DtDesligamento
      FROM ECadHistEstagio BOL
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = BOL.CdVinculoEstagio
     INNER JOIN (SELECT LT.CdHistEstagio,
                       MAX(DtInicio) AS DtInicio
                 FROM eCadLocalTrabalho LT
                WHERE LT.CdVinculo = pCdVinculo AND
                      LT.FlDefinitiva = PKGPAG_TIPO.cnS AND
                      LT.FlAnulado = PKGPAG_TIPO.cnN AND
                      LT.DtInicio <= PKGPAG_VAR.vDtCalculo
                GROUP BY LT.CdHistEstagio) LT1
        ON LT1.CdHistEstagio = BOL.CdHistEstagio
     INNER JOIN ECadLocalTrabalho LT
        ON LT.CdHistEstagio = LT1.CdHistEstagio AND
           LT.DtInicio = LT1.DtInicio AND
           LT.FlAnulado = PKGPAG_TIPO.cnN
     WHERE V.CdVinculo = pCdVinculo AND
           LT.FlDefinitiva = PKGPAG_TIPO.cnS AND
           BOL.DtInicio <= pDtFimMes AND
           BOL.DtFim >= pDtInicioMes AND
           BOL.FlAnulado = PKGPAG_TIPO.cnN;

  CURSOR cRelOutras(pCdVinculo     IN INTEGER,
                    pCdOrgao       IN INTEGER,
                    pDtInicioMes   IN DATE,
                    pDtFimMes      IN DATE) IS
    SELECT 4 AS CdTipoRelacao,
           APO.CdConcessaoAposentadoria AS CdHistRelVinc,
           APO.CdOrgaoExercicio,
           HSP.CdSituacaoPrevidenciaria,
           APO.FlOrigemCCO,
           APO.DtInicioAposentadoria AS DtInicioRelacao,
           APO.DtFimAposentadoria AS DtFimRelacao,
           CEF.CdEstruturaCarreira,
           CASE
              WHEN APO.DtInicioAposentadoria < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              APO.DtInicioAposentadoria
            END DtInicio,
            CASE
              WHEN APO.DtFimAposentadoria > pdtFimMes OR APO.DtFimAposentadoria IS NULL THEN
                pDtFimMes
            ELSE
              APO.DtFimAposentadoria
            END AS DtFim
      FROM EPvdConcessaoAposentadoria APO
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = APO.CdVinculo
     INNER JOIN ECadHistCargoEfetivo CEF
        ON V.CdVinculo = CEF.CdVinculo AND
           CEF.CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao AND
           CEF.Dtfim = (SELECT MAX(dtFim)
                          FROM ECadHistCargoEfetivo CEF
                         WHERE CEF.CdVinculo = pCdVinculo AND
                               CEF.CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao AND
                               CEF.FlEfetivacao = PKGPAG_TIPO.cnT AND
                               CEF.FlAnulado = PKGPAG_TIPO.cnN)
     INNER JOIN EpvdModeloAposentadoria MA
        ON APO.CdModeloAposentadoria = MA.CdModeloAposentadoria
     INNER JOIN ECadHistSitPrevVinculo HSP
        ON APO.CdVinculo = HSP.CdVinculo AND
           (APO.DtInicioAposentadoria BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax))
     WHERE V.CdVinculo = pCdVinculo AND
           APO.CdOrgaoExercicio = pCdOrgao AND
           MA.FlParidade = PKGPAG_TIPO.cnS AND
           APO.FlAtiva = PKGPAG_TIPO.cnS AND
           APO.DtInicioAposentadoria <= pDtFimMes AND
           (APO.DtFimAposentadoria >= pDtInicioMes OR APO.DtFimAposentadoria IS NULL) AND
           APO.Flanulado = PKGPAG_TIPO.cnN  AND
           pkgpag_var.vgFolha.CdTipoFolha <> pkgpag_tipo.cnTpFolhaInstPensao

    UNION ALL

      SELECT 4 AS CdTipoRelacao,
             APO.CdConcessaoAposentadoria AS CdHistRelVinc,
             APO.CdOrgaoExercicio,
             HSP.CdSituacaoPrevidenciaria,
             APO.FlOrigemCCO,
             APO.DtInicioAposentadoria AS DtInicioRelacao,
             APO.DtFimAposentadoria AS DtFimRelacao,
             NULL AS CdEstruturaCarreira,
             CASE
                WHEN APO.DtInicioAposentadoria < pdtInicioMes THEN
                  pDtInicioMes
              ELSE
                APO.DtInicioAposentadoria
              END DtInicio,
              CASE
                WHEN APO.DtFimAposentadoria > pdtFimMes OR APO.DtFimAposentadoria IS NULL THEN
                  pDtFimMes
              ELSE
                APO.DtFimAposentadoria
              END AS DtFim
      FROM EPvdConcessaoAposentadoria APO
     INNER JOIN ECadVinculo V
        ON APO.CdVinculo = V.CdVinculo
     INNER JOIN EpvdModeloAposentadoria MA
        ON APO.CdModeloAposentadoria = MA.CdModeloAposentadoria
     INNER JOIN ECadHistSitPrevVinculo HSP
       ON APO.CdVinculo = HSP.CdVinculo AND
          (APO.DtInicioAposentadoria BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax))
     WHERE  V.CdVinculo = pCdVinculo AND
            APO.FlAtiva = PKGPAG_TIPO.cnS AND
            APO.CdOrgaoExercicio = pCdOrgao AND
            MA.FlParidade = PKGPAG_TIPO.cnN AND
            ((APO.Dtinicioaposentadoria <= pdtFimMes) AND
            (APO.DtFimaposentadoria >= pdtInicioMes OR APO.DtFimaposentadoria IS NULL)) AND
            APO.Flanulado = PKGPAG_TIPO.cnN  AND
            pkgpag_var.vgFolha.CdTipoFolha <> pkgpag_tipo.cnTpFolhaInstPensao

    UNION ALL

    SELECT 6 AS CdTipoRelacao,
           PP.CdHistPensaoPrevidenciaria AS CdHistRelVinc,
           V.CdOrgao AS CdOrgaoExercicio,
           HSP.CdSituacaoPrevidenciaria,
           NULL,
           PP.DtInicio AS DtInicioRelacao,
           PP.DtFim    AS DtFimRelacao,
           NULL,
           CASE
              WHEN PP.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              PP.DtInicio
            END DtInicio,
            CASE
              WHEN PP.DtFim > pdtFimMes OR PP.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              PP.DtFim
            END AS DtFim
      FROM EPvdHistPensaoPrevidenciaria PP
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = PP.CdVinculo
     INNER JOIN ECadHistSitPrevVinculo HSP
        ON PP.CdVinculo = HSP.CdVinculo AND
           (PP.DtInicio BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax))
     WHERE PP.CdVinculo = pCdVinculo AND
           PP.DtInicio <= pDtFimMes AND
           (PP.DtFim >= pDtInicioMes OR PP.DtFim IS NULL) AND
           PP.FlAnulado = PKGPAG_TIPO.cnN

    UNION ALL

    SELECT 7 AS CdTipoRelacao,
           PNP.CdHistPensaoNaoPrev AS CdHistRelVinc,
           V.CdOrgao AS CdOrgaoExercicio,
           V.CdSituacaoPrevidenciaria,
           NULL,
           PNP.DtInicio AS DtInicioRelacao,
           PNP.DtFim AS DtFimRelacao,
           NULL,
           CASE
              WHEN PNP.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              PNP.DtInicio
            END DtInicio,
            CASE
              WHEN PNP.DtFim > pdtFimMes OR PNP.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              PNP.DtFim
            END AS DtFim
      FROM EPvdHistPensaoNaoPrev PNP
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = PNP.CdVinculoBeneficiario
     WHERE PNP.CdVinculoBeneficiario = pCdVinculo AND
           PNP.DtInicio <= pDtFimMes AND
           (PNP.DtFim >= pDtInicioMes OR PNP.DtFim IS NULL) AND
           PNP.Flanulado = PKGPAG_TIPO.cnN

    UNION ALL

    SELECT 8 AS CdTipoRelacao,
           EP.CdHistPensaoExParlamentar AS CdHistRelVinc,
           V.CdOrgao AS CdOrgaoExercicio,
           V.CdSituacaoPrevidenciaria,
           NULL,
           EP.DtInicio AS DtInicioRelacao,
           EP.DtFim AS DtFimRelacao,
           NULL,
           CASE
              WHEN EP.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              EP.DtInicio
            END DtInicio,
            CASE
              WHEN EP.DtFim > pdtFimMes OR EP.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              EP.DtFim
            END AS DtFim
      FROM EPvdHistPensaoExParlamentar EP
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = EP.CdVinculo
     WHERE EP.CdVinculo = pCdVinculo AND
           EP.DtInicio <= pDtFimMes AND
           (EP.DtFim >= pDtInicioMes OR EP.DtFim IS NULL) AND
           EP.Flanulado = PKGPAG_TIPO.cnN

    UNION ALL

    SELECT 9 AS CdTipoRelacao,
           AR.CdHistAuxilioReclusao AS CdHistRelVinc,
           V.CdOrgao AS CdOrgaoExercicio,
           V.CdSituacaoPrevidenciaria,
           NULL,
           AR.DtInicio AS DtInicioRelacao,
           Ar.DtFim    AS DtFimRelacao,
           NULL,
           CASE
              WHEN AR.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              AR.DtInicio
            END DtInicio,
            CASE
              WHEN AR.DtFim > pdtFimMes OR AR.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              AR.DtFim
            END AS DtFim
      FROM EPvdHistAuxilioReclusao AR
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = AR.CdVinculo
     WHERE AR.CdVinculo = pCdVinculo AND
           AR.DtInicio <= pDtFimMes AND
           (AR.DtFim >= pDtInicioMes OR AR.DtFim IS NULL) AND
           AR.Flanulado = PKGPAG_TIPO.cnN

     UNION ALL

     -- Instituidor de Pensao Aposentado
     SELECT 4 AS CdTipoRelacao,
           APO.CdConcessaoAposentadoria AS CdHistRelVinc,
           APO.CdOrgaoExercicio,
           HSP.CdSituacaoPrevidenciaria,
           APO.FlOrigemCCO,
           APO.DtInicioAposentadoria AS DtInicioRelacao,
           APO.DtFimAposentadoria AS DtFimRelacao,
           CEF.CdEstruturaCarreira,
           CASE
              WHEN APO.DtInicioAposentadoria < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              APO.DtInicioAposentadoria
            END DtInicio,
            pDtFimMes AS DtFim
      FROM EPvdConcessaoAposentadoria APO
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = APO.CdVinculo
     INNER JOIN ECadHistCargoEfetivo CEF
        ON V.CdVinculo = CEF.CdVinculo AND
           CEF.CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao AND
           CEF.Dtfim = (SELECT MAX(dtFim)
                          FROM ECadHistCargoEfetivo CEF
                         WHERE CEF.CdVinculo = pCdVinculo AND
                               CEF.CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao AND
                               CEF.FlEfetivacao = PKGPAG_TIPO.cnT AND
                               CEF.FlAnulado = PKGPAG_TIPO.cnN)
     INNER JOIN EpvdModeloAposentadoria MA
        ON APO.CdModeloAposentadoria = MA.CdModeloAposentadoria
     INNER JOIN EAfaRegistroObito o
        on o.cdpessoa = v.cdpessoa
       AND O.DTINCLUSAO = (SELECT MAX(O2.DTINCLUSAO)
                             FROM EAfaRegistroObito O2
                            WHERE O2.cdpessoa = v.cdpessoa
                              AND O2.FLANULADO = PKGPAG_TIPO.cnN
                              AND O2.CDAGRUPAMENTO = pkgpag_var.vgFolha.CdAgrupamento)
     INNER JOIN ECadHistSitPrevVinculo HSP
        ON APO.CdVinculo = HSP.CdVinculo AND
           (APO.DtInicioAposentadoria BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax)) and
           hsp.dtfim = o.dtobito-1
     WHERE V.CdVinculo = pCdVinculo AND
           APO.CdOrgaoExercicio = pCdOrgao AND
           MA.FlParidade = PKGPAG_TIPO.cnS AND
           APO.FlAtiva = PKGPAG_TIPO.cnS AND
           APO.DtInicioAposentadoria <= pDtFimMes AND
           APO.DtFimAposentadoria = o.dtobito-1 AND
           APO.Flanulado = PKGPAG_TIPO.cnN  AND
           pkgpag_var.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaInstPensao and
           o.flanulado = PKGPAG_TIPO.cnN

    UNION ALL

      SELECT 4 AS CdTipoRelacao,
             APO.CdConcessaoAposentadoria AS CdHistRelVinc,
             APO.CdOrgaoExercicio,
             HSP.CdSituacaoPrevidenciaria,
             APO.FlOrigemCCO,
             APO.DtInicioAposentadoria AS DtInicioRelacao,
             APO.DtFimAposentadoria AS DtFimRelacao,
             NULL AS CdEstruturaCarreira,
             CASE
                WHEN APO.DtInicioAposentadoria < pdtInicioMes THEN
                  pDtInicioMes
              ELSE
                APO.DtInicioAposentadoria
              END DtInicio,
             pDtFimMes AS DtFim
      FROM EPvdConcessaoAposentadoria APO
     INNER JOIN ECadVinculo V
        ON APO.CdVinculo = V.CdVinculo
     INNER JOIN EpvdModeloAposentadoria MA
        ON APO.CdModeloAposentadoria = MA.CdModeloAposentadoria
     INNER JOIN EAfaRegistroObito o on o.cdpessoa = v.cdpessoa
     INNER JOIN ECadHistSitPrevVinculo HSP
       ON APO.CdVinculo = HSP.CdVinculo AND
          (APO.DtInicioAposentadoria BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax)) and
          hsp.dtfim = o.dtobito-1
     WHERE  V.CdVinculo = pCdVinculo AND
            APO.FlAtiva = PKGPAG_TIPO.cnS AND
            APO.CdOrgaoExercicio = pCdOrgao AND
            MA.FlParidade = PKGPAG_TIPO.cnN AND
            APO.Dtinicioaposentadoria <= pdtFimMes AND
            APO.DtFimaposentadoria = o.dtobito-1 AND
            APO.Flanulado = PKGPAG_TIPO.cnN  AND
            pkgpag_var.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaInstPensao and
            o.flanulado = PKGPAG_TIPO.cnN

    union all

    -- Instituidor comissionado

    SELECT 2 AS CdTipoRelacao,
           CCO.CdHistCargoCom,
           CCO.CdOrgaoExercicio,
           HSP.CdSituacaoPrevidenciaria,
           NULL,
           CCO.DtInicio AS DtInicioRelacao,
           CCO.DtFim AS DtFimRelacao,
           null as CdEstruturaCarreira,
           CASE
              WHEN CCO.DtInicio < pdtInicioMes THEN
                pDtInicioMes
            ELSE
              CCO.Dtinicio
            END DtInicio,
            CASE
              WHEN CCO.DtFim > pdtFimMes OR CCO.DtFim IS NULL THEN
                pDtFimMes
            ELSE
              CCO.DtFim
            END AS DtFim
      FROM ECadHistCargoCom CCO
     inner join ecadvinculo v on v.cdvinculo = cco.cdvinculo
     INNER JOIN ECadHistSitPrevVinculo HSP
        ON CCO.CdVinculo = HSP.CdVinculo AND
           (CCO.DtInicio BETWEEN HSP.DtInicio AND NVL(HSP.DtFim,PKGPAG_TIPO.cnDtMax))
     INNER JOIN ECadCargoComissionado C
        ON CCO.CdCargoComissionado = C.CdCargoComissionado
     INNER JOIN EAfaRegistroObito o on o.cdpessoa = v.cdpessoa
     WHERE CCO.CdVinculo = pCdVinculo AND
           ((CCO.DtFim IS NOT NULL OR (CCO.DtFim IS NULL AND CCO.CdCargoComRemuneracao IS NULL)) OR
           CCO.FlTipoProvimento = PKGPAG_TIPO.cnS) AND
           CCO.DtInicio <= pDtFimMes AND
           pkgpag_var.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaInstPensao and
           cco.dtfim = o.dtobito-1 AND
           CCO.Flanulado = PKGPAG_TIPO.cnN and
           o.flanulado = PKGPAG_TIPO.cnN;

END PKGPAG_VAR;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_VAR IS

END PKGPAG_VAR;
/
