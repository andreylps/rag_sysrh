CREATE OR REPLACE PACKAGE pkgpag_geral IS

  vgFlPossuiFinRegencia BOOLEAN;

  vgNuSufixoRegencia NUMBER;
  
  FUNCTION fgettime RETURN INTEGER;

  PROCEDURE plogtrace(plocal   IN VARCHAR2,
                      ptrace   IN VARCHAR2,
                      ptimeini IN INTEGER DEFAULT NULL);


  PROCEDURE plogprocini(pordem IN VARCHAR2, pproc IN VARCHAR2);
  
  PROCEDURE plogprocfim(pordem IN VARCHAR2);

  PROCEDURE plogproc(pordemfim IN VARCHAR2, pordemini IN VARCHAR2, pprocini IN VARCHAR2);
  
  PROCEDURE piniciarlogproc;

  PROCEDURE pfinalizarlogproc(pcalculo IN pkgpag_cal.rcalculo);

  PROCEDURE PErroFatal (pMsgErro IN VARCHAR2);
  
  FUNCTION fTratarDatas(pDtInicioMes           IN DATE,
                        pDtFimMes              IN DATE,
                        pDtInicioTrabalho      IN DATE,
                        pDtFimTrabalho         IN DATE,
                        pNudiasTrabalhadosSoma IN OUT INTEGER)

   RETURN pkgpag_tipo.rData;

  FUNCTION fTratarDatas(pDtInicioMes      IN DATE,
                        pDtFimMes         IN DATE,
                        pDtInicioTrabalho IN DATE,
                        pDtFimTrabalho    IN DATE)

   RETURN pkgpag_tipo.rData;

  FUNCTION fproxcarreira(pcdestruturacarreira IN INTEGER)

   RETURN INTEGER;

  FUNCTION fexistecarreira(pcdestruturacarreira IN INTEGER)

   RETURN INTEGER;

  FUNCTION fbuscacarreira(pcdestruturacarreira     IN INTEGER,
                          pCdEstruturaCarreiraProc IN INTEGER) RETURN BOOLEAN;

  FUNCTION farredondavinculado

   RETURN BOOLEAN;

  PROCEDURE parredondainicializa(pvltotaldias IN NUMBER DEFAULT 30);

  FUNCTION farredondaverifica(pvltotal     IN NUMBER,
                              pvlparcela   IN NUMBER,
                              pvlvinculado IN NUMBER DEFAULT 0,
                              pQtDias      IN NUMBER) RETURN NUMBER;

  PROCEDURE PCarregarFolhaVinculo (pCdCalculo          IN INTEGER, 
                                   pCdPessoa           IN INTEGER, 
                                   pNuAnoMesIni        IN INTEGER DEFAULT NULL,
                                   pFlIniciarPessoa    IN INTEGER DEFAULT 0) ;
     
  FUNCTION FRetornaRegimeProprioPrev(pCdVinculo IN INTEGER) RETURN INTEGER;

  FUNCTION FRetornaAliquotaIPESC(pCdTpTributacaoIPESC IN INTEGER,
                                 pNuAnoReferencia     IN INTEGER,
                                 pNuMesReferencia     IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaIPESC;

  FUNCTION FRetornaAliquotaCPSM(pCdTpTributacaoCPSM IN INTEGER,
                                pNuAnoReferencia    IN INTEGER,
                                pNuMesReferencia    IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaCPSM;

  FUNCTION FRetornaAliquotaIRRF(pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER,
                                pCdTipoAliquota  IN INTEGER DEFAULT 1)
   RETURN PKGPAG_TIPO.rAliquotaIRRF;


  FUNCTION FRetornaAliquotaINSS(pNuAnoReferencia IN INTEGER,
                               pNuMesReferencia IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaINSS;
 


  FUNCTION FAgrupUtilizaDescSimp(pCdAgrupamento IN INTEGER,
                                 pNuAnoMesFolha IN INTEGER) RETURN BOOLEAN;
  
  function FConsultarDescEstrutura(pCdEstruturaCarreira in number,
                                   pultimonivel         in integer default 1)

   return string;

  FUNCTION fPagaLanctoFinAfastDefinitivo(pcdvinculo IN INTEGER)

   RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fvisaocalculo(pcdtipocalculo       IN INTEGER,
                         pFlCalculoDefinitivo IN CHAR) RETURN CHAR;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fcodigofolhanormalvinc(pcdvinculo IN INTEGER,
                                  pfolha     IN pkgpag_tipo.rfolha)

   RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION ffolhaemexecucao(pcdfolhapagamento IN INTEGER,
                            pCdPessoa         IN INTEGER) RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fvinculocomproventos(pcdvinculo        IN INTEGER,
                                pCdFolhaPagamento IN INTEGER) RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fpagamentobloqueado(pcdpessoa        IN INTEGER,
                               pcdvinculo       IN INTEGER,
                               pnuanoreferencia IN INTEGER,
                               pnumesreferencia IN INTEGER,
                               pDtNascimento    IN DATE) RETURN CHAR;

  /*--------------------------------------------------------------------------------------/*
    -- Rotina para tratamento de bloqueio de credito
    -- Utilizada
  /*--------------------------------------------------------------------------------------*/

  PROCEDURE ptratabloqueiocredito;

  /*--------------------------------------------------------------------------------------/*
   -- Armazena as rubricas que nao devem ser processadas pelos Eventos em
   -- decorrencia da existencia de lancamentos financeiros ou decisoes judiciais
  /*--------------------------------------------------------------------------------------*/

  FUNCTION frubricaslancamento(pcdvinculo IN INTEGER,
                               pfolha     IN pkgpag_tipo.rfolha)
    RETURN pkgpag_tipo.tlistavalor;

  FUNCTION fretornaindice(pflpropmescomercial IN CHAR,
                          pdtiniciomes        IN DATE,
                          pdtfimmes           IN DATE,
                          pdtinicio           IN DATE,
                          pdtfim              IN DATE)

   RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*
   -- Funcao que retorna o c?digo da folha contendo bases para c?lculo do auxilio funeral
  /*--------------------------------------------------------------------------------------*/
  FUNCTION FFolhaAuxFun(pcdVinculo IN INTEGER,
                        pNuAno     IN INTEGER,
                        PnuMes     IN INTEGER) RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*
   -- Funcao que retorna TRUE caso a rubrica exista em lancamento financeiro
  /*--------------------------------------------------------------------------------------*/

  FUNCTION fpossuilancfinanceiro(pcdvinculo        IN INTEGER,
                                 pfolha            IN pkgpag_tipo.rfolha,
                                 pcdrubrica        IN INTEGER,
                                 pIncluiFinalizado in char default 'N')
    RETURN BOOLEAN;
  /*--------------------------------------------------------------------------------------/*
   -- Funcao que retorna TRUE caso o vinculo possua lancamento de retroativo vigente
  /*--------------------------------------------------------------------------------------*/

  FUNCTION fpossuilancretroativo(pcdvinculo IN INTEGER,
                                 pfolha     IN pkgpag_tipo.rfolha)
    RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*
  -- Retorna se vinculo tem punicao vigente.
   /*--------------------------------------------------------------------------------------*/

  FUNCTION fpossuipunicao(pcdvinculo IN INTEGER,
                          pFolha     IN PKGPAG_TIPO.rFolha) RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*
   -- Armazena as lancamentos complementares.
  /*--------------------------------------------------------------------------------------*/

  FUNCTION frubricaslanccomplementar(pcdvinculo IN INTEGER,
                                     pfolha     IN pkgpag_tipo.rfolha)

   RETURN pkgpag_tipo.tlanccomplementar;

  FUNCTION fpossuilanccomplementar(pcdrubricaagrupamento IN INTEGER,
                                   pnusufixorubrica      IN INTEGER)
    RETURN BOOLEAN;

  -----------------------------------------------------------------------------
  -- Retorna percentual de reducao de salario por motivo de afastamento
  -- remunerado que informa reducao
  -----------------------------------------------------------------------------
  FUNCTION fpercentreducaosalario(pcdvinculo IN INTEGER,
                                  pdtinicio  IN DATE,
                                  pdtfim     IN DATE,
                                  pdtcalculo IN DATE)

   RETURN NUMBER;

  FUNCTION FQtFaltas(pCdVinculo IN INTEGER, pNuAno IN INTEGER) RETURN INTEGER;

  FUNCTION FRetornaCdRubrica(pcdtiporubrica INTEGER,
                             pNuRubrica     INTEGER) RETURN INTEGER;

  /*----------------------------------------------------------------------------
       Funcao: FRetornaRubricaOutroTipo
     Objetivo: Retorna a mesma rubrica com outro tipo para o agrupamento 
         Nota: Caso nao seja encontrada a rubrica, ou exista mais de uma
               rubrica que atenda aos parametros informados e retornado o
               valor '0'
  /-----------------------------------------------------------------------------*/
  FUNCTION FRetornaRubricaOutroTipo (pCdAgrupamento   IN INTEGER,
                                     pNuAnoReferencia IN INTEGER,
                                     pNuMesReferencia IN INTEGER,
                                     pCdRubrica       IN INTEGER,
                                     pCdTipoRubrica   IN INTEGER) RETURN INTEGER;
  
  FUNCTION FRetornaRubricaOutroTipo (pTabRubrica      IN TYPENUMBER,
                                     pNuAnoReferencia IN INTEGER,
                                     pNuMesReferencia IN INTEGER,
                                     pCdTipoRubrica   IN INTEGER) RETURN TYPENUMBER;                                   
  /*-----------------------------------------------------------------------------------------/*
  --    Funcao: FRetornaCodigoRubrica
  --
  -- Retorna o codigo da rubrica associada a um determinado tipo de evento
  --
  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fretornacodigorubrica(pcdagrupamento         IN INTEGER,
                                 pcdtipoeventopagamento IN INTEGER,
                                 pflrubricaalternativa  IN CHAR DEFAULT 'N')
    RETURN INTEGER;

  /*-----------------------------------------------------------------------------------------/*
  --    Funcao: FRetornaRubrica
  --
  --  Objetivo: Retorna o codigo da rubrica do agrupamento com base no tipo e numero da rubrica
  --
  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fretornarubrica(pcdagrupamento INTEGER,
                           pcdtiporubrica INTEGER,
                           pNuRubrica     INTEGER) RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*
   -- Verifica se a rubrica esta contida na lista de rubricas (dos lancamentos financeiros e
   -- decisoes judiciais) do vinculo
  /*--------------------------------------------------------------------------------------*/

  FUNCTION fgerarubrica(prubrica IN INTEGER)

   RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*
   -- Retorna no numero de vinculos vigentes da pessoa
  /*--------------------------------------------------------------------------------------*/

  FUNCTION FVinculosVigentes(pCdPessoa IN INTEGER, pDtInicioMes IN DATE)
    RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*
   -- Retorna no numero de vinculos vigentes da pessoa
  /*--------------------------------------------------------------------------------------*/
  FUNCTION fpossuidecisaojudicial(pcdvinculo       IN INTEGER,
                                  pnuanoreferencia IN INTEGER,
                                  pnumesreferencia IN INTEGER,
                                  pcdrubrica       IN INTEGER,
                                  pvldecisaojud    OUT NUMBER,
                                  pcdvalorref      OUT INTEGER,
                                  pdtiniciodireito OUT DATE,
                                  pDtInclusao      OUT DATE) RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE psetadadosbancarios(pcdvinculo       IN INTEGER,
                                pnuanoreferencia IN INTEGER,
                                pnumesreferencia IN INTEGER,
                                pdtcalculo       IN DATE);

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pinserelog(pinsere                  IN BOOLEAN DEFAULT TRUE,
                       pcdhistoricoparamcalculo IN INTEGER,
                       pcdpessoa                IN INTEGER,
                       pdelog                   IN VARCHAR2,
                       pcdvinculo               IN INTEGER DEFAULT NULL,
                       pcdtipoocorrencia        IN INTEGER DEFAULT 1,
                       pcdmotivoocorrencia      IN INTEGER DEFAULT NULL);

  /*--------------------------------------------------------------------------------------/*
        Funcao: FCalculaValorIntegral

      Objetivo: Calcula o valor integral referente aos dias em que a relacao de vinculo

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fcalculavalorpropdias(pflpropservrelvinc IN CHAR,
                                 pvlpropdias        IN NUMBER,
                                 pdiasmes           IN INTEGER,
                                 pDiasNivelRef      IN INTEGER) RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*
        Funcao: FCalculaValorProp

      Objetivo: Calcula o valor proporcional referente aos dias em que a relacao de vinculo

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fcalculavalorprop(pflpropservrelvinc IN CHAR,
                             pvlproporcional    IN NUMBER,
                             pnudiasmes         IN INTEGER,
                             pdtinicio          IN DATE,
                             pdtFim             IN DATE) RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornadiasdomes(pdtfimmes           IN DATE,
                             pflpropmescomercial IN CHAR)

   RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fdiaslicpremio(pcdvinculo           IN INTEGER,
                          pnuanoreferencia     IN INTEGER,
                          pnumesreferencia     IN INTEGER,
                          pcdtipolicencapremio IN INTEGER,
                          pCdSituacaoPerAquis  IN INTEGER) RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fdiasafasttempnaorem(pcdvinculo           IN INTEGER,
                                pdtiniciomes         IN DATE,
                                pdtfimmes            IN DATE,
                                pdtcalculo           IN DATE,
                                pflacidente          IN CHAR DEFAULT 'N',
                                pflApenasAfastNaoRem IN CHAR DEFAULT 'N')

   RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fdiasafasttemp(pcdvinculo   IN INTEGER,
                          pdtiniciomes IN DATE,
                          pdtfimmes    IN DATE,
                          pdtcalculo   IN DATE,
                          pcdmotivo    IN INTEGER DEFAULT NULL)
    RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fdiasafastgravidez(pcdvinculo   IN INTEGER,
                              pdtiniciomes IN DATE,
                              pdtfimmes    IN DATE,
                              pdtcalculo   IN DATE,
                              prubrica     IN pkgpag_tipo.rrubrica DEFAULT NULL)

   RETURN pkgpag_tipo.rafastgravidez;

  /*--------------------------------------------------------------------------------------/*
    Procedure: PExcluiValoresZerados

     Objetivo:

  /*--------------------------------------------------------------------------------------*/
  PROCEDURE pexcluivaloreszerados(pcdfolhapagamento IN INTEGER,
                                  pcdvinculo        IN INTEGER);

  /*--------------------------------------------------------------------------------------/*
    Procedure: FPossuiInterrupcaoUsufruto

     Objetivo: Verificar se nao existe interrupcao

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fpossuiinterrupcaousufruto(pcdperiodoaquisitivoferias IN INTEGER,
                                      pdtiniciomes               IN DATE,
                                      pdtfimmes                  IN DATE)

   RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*
    Procedure: PExcluiRubrica

     Objetivo:

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pexcluirubricas(pcdfolhapagamento   IN INTEGER,
                            pcdvinculo          IN INTEGER,
                            pinpagamentorubrica IN CHAR);

  /*--------------------------------------------------------------------------------------/*
    Procedure: PExcluiRubrica
     ExcluiRubr
     Objetivo:

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pexcluirubrica(pcdfolhapagamento        IN INTEGER,
                           pcdvinculo               IN INTEGER,
                           pcdrubrica               IN INTEGER,
                           pflexcluiambos           IN CHAR DEFAULT 'N',
                           pflpreservavalorintegral IN CHAR DEFAULT 'N');

  /*--------------------------------------------------------------------------------------/*
    Procedure: PExcluiRubricaSufixo

     Objetivo:

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pexcluirubricasufixo(pcdfolhapagamento IN INTEGER,
                                 pcdvinculo        IN INTEGER,
                                 pcdrubrica        IN INTEGER,
                                 pnusufixo         IN INTEGER,
                                 pflexcluiambos    IN CHAR DEFAULT 'N');

  /*--------------------------------------------------------------------------------------/*
    Procedure: PExcluirPagOrgao

     Objetivo: Exclui os pagamentos realizados na folha de pagamento passada como parametro

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pexcluirpagorgao(pcdfolhapagamento IN INTEGER);

  /*--------------------------------------------------------------------------------------/*
    Procedure: pexcluirpagvincgeral

     Objetivo: Exclui todos os contracheques do vinculo, independente do orgao,
               para um determinado "tipo de folha/tipo de calculo/ano mes referencia/sequencial folha".

  /*--------------------------------------------------------------------------------------*/
  PROCEDURE pexcluircontrachequesvinculo(pCdVinculo            IN INTEGER,
                                         pNuAnoReferencia      IN Epagfolhapagamento.Nuanoreferencia%TYPE,
                                         pNuMesReferencia      IN Epagfolhapagamento.Numesreferencia%TYPE,
                                         pCdTipoFolhaPagamento IN Epagfolhapagamento.Cdtipofolhapagamento%TYPE,
                                         pCdTipoCalculo        IN Epagfolhapagamento.Cdtipocalculo%TYPE,
                                         pNuSequencialFolha    IN Epagfolhapagamento.Nusequencialfolha%TYPE);


   PROCEDURE pexcluircontrachequesPessoa (pCdOrgao              IN INTEGER,
                                          pCdPessoa             IN INTEGER,
                                          pNuAnoReferencia      IN Epagfolhapagamento.Nuanoreferencia%TYPE,
                                          pNuMesReferencia      IN Epagfolhapagamento.Numesreferencia%TYPE,
                                          pCdTipoFolhaPagamento IN Epagfolhapagamento.Cdtipofolhapagamento%TYPE,
                                          pCdTipoCalculo        IN Epagfolhapagamento.Cdtipocalculo%TYPE,
                                          pNuSequencialFolha    IN Epagfolhapagamento.Nusequencialfolha%TYPE);
                                          
  /*--------------------------------------------------------------------------------------/*
    Procedure: PExcluirPagVinc

     Objetivo: Exclui os pagamentos realizados no historico do vinculo com base nos para-
               metros informados.

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pexcluirpagvinc(pcdfolhapagamento IN INTEGER,
                            pcdvinculo        IN INTEGER);

  /*--------------------------------------------------------------------------------------/*
    Procedure: PExcluirPagPessoa

     Objetivo: Exclui os pagamentos realizados para a pessoa

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pexcluirpagpessoa(pcdfolhapagamento IN INTEGER,
                              pcdpessoa         IN INTEGER);

  /*--------------------------------------------------------------------------------------/*
    Funcao: FValorNivelRefGeralAgrup

   Objetivo: Retorna os valores gerais de niveis e referencias para o agrupamento
             e a carga horaria padrao.

       Nota: A carga horaria pode estar definida em algum nivel da carreira
             passada como parametro, seja no Orgao ou no Agrupamento. Inicialmente e
             feita a busca na tabela de valores do Orgao e caso nao encontre,
             realiza a busca na tabela de valores do Agrupamento.

  /*--------------------------------------------------------------------------------------*/

  FUNCTION FValorNivelRefGeralAgrup(pTipoTabelaCEF       IN PKGPAG_TIPO.rTipoTabelaCEF,
                                    pCdEstruturaCarreira IN INTEGER)
    RETURN pkgpag_tipo.tvalorfixo;

  /*--------------------------------------------------------------------------------------/*
     Funcao: FValorNivelRefAgrup

   Objetivo: Retorna os valores de niveis e referencias das carreiras
             para o agrupamento

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fvalornivelrefagrup(pcdhistnivelrefcef IN INTEGER)

   RETURN pkgpag_tipo.tvalorfixo;

  /*--------------------------------------------------------------------------------------/*
     Funcao: FValorNivelRefOrgao

   Objetivo: Retorna os valores de niveis e referencias das carreiras
             para o orgao

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fvalornivelreforgao(pcdhistnivelrefcef IN INTEGER)

   RETURN pkgpag_tipo.tvalorfixo;

  /*--------------------------------------------------------------------------------------/*
     Funcao: FTabelaValorGeral

   Objetivo: Retorna o codigo do historico (vigencia) da tabela geral do agrupamento

  /*--------------------------------------------------------------------------------------*/

  FUNCTION ftabelavalorgeral(pcdtabgeral IN INTEGER,
                             pnuversao   IN INTEGER,
                             pnuano      IN INTEGER,
                             pNuMes      IN INTEGER) RETURN INTEGER;

  FUNCTION fretonavalorfixotab(pnuversaotab           IN INTEGER,
                               pnuanoreferencia       IN INTEGER,
                               pnumesreferencia       IN INTEGER,
                               pcdvalorgeralcefagrup  IN INTEGER,
                               pnunivelpagamento      IN VARCHAR2,
                               pnureferenciapagamento IN VARCHAR2)
    RETURN NUMBER;

  /*-----------------------------------------------------------------------------------------
       Funcao: FRetonaValorNivelRefCEF

     Objetivo: Retornar o valor  com o valor fixo de acordo com a tabela de valores passada
               como parametro
   Argumentos:
  -----------------------------------------------------------------------------------------*/

  FUNCTION fretonavalorfixocef(pcdagrupamento               IN INTEGER,
                               pcdorgao                     IN INTEGER,
                               pnuversaotabcef              IN INTEGER,
                               pnuanoreferencia             IN INTEGER,
                               pnumesreferencia             IN INTEGER,
                               pcdestruturacarreira         IN INTEGER,
                               pcdestruturacarreiracarreira IN INTEGER,
                               pnunivelpagamento            IN VARCHAR2,
                               pnureferenciapagamento       IN VARCHAR2)

   RETURN pkgpag_tipo.rvalorfixo;

  /*-----------------------------------------------------------------------------------------
       Funcao: FRetonaValorNivelRefCEF

     Objetivo: Retornar o valor  com o valor fixo de acordo com a tabela de valores passada
               como parametro
   Argumentos:
  -----------------------------------------------------------------------------------------*/

  FUNCTION fretornavalornivrefgeral(pcdhisttabgeral IN INTEGER,
                                    pnunivel        IN VARCHAR2,
                                    pnureferencia   IN VARCHAR2)

   RETURN NUMBER;

  /*----------------------------------------------------------------------------------------------------*/
  -- Funcao   : FMenorDataAfastRetroativos
  -- Objetivo : Funcao que contabiliza o numero de dias afastados retroativos dos afastamentos com
  --            data de inclusao no mes
  /*----------------------------------------------------------------------------------------------------*/

  FUNCTION fmenordataafastretroativos(pcdvinculo   IN INTEGER,
                                      pdtiniciomes IN DATE,
                                      pDtFimMes    IN DATE) RETURN DATE;

  /*----------------------------------------------------------------------------------------------------*/
  -- Funcao   : FPossuiRegistroObito
  -- Objetivo : Funcao que retorna verdadeiro caso a pessoa possua regitro de obito
  --
  /*----------------------------------------------------------------------------------------------------*/

  FUNCTION fpossuiregistroobito(pcdpessoa            IN INTEGER,
                                pcdagrupamento       IN INTEGER,
                                pFlIgnoraAgrupamento in char default 'N')

   RETURN BOOLEAN;

  /*----------------------------------------------------------------------------------------------------*/
  -- Funcao   : fpossuivinculocco
  --
  /*----------------------------------------------------------------------------------------------------*/

  FUNCTION fpossuivinculocco(pcdvinculo IN INTEGER,
                             pcdorgao   IN INTEGER,
                             pdtinicio  IN DATE,
                             pDtFim     IN DATE)

   RETURN BOOLEAN;
  /*----------------------------------------------------------------------------------------------------*/
  -- Funcao   : FRetornaTipoDiaNaoUtil
  -- Objetivo : Funcao que retorna o parametro dos dias que devem ser considerados no auxilio alimentacao
  --
  /*----------------------------------------------------------------------------------------------------*/

  FUNCTION fretornatipodianaoutil(pcdorgao IN INTEGER)

   RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*
     Funcao: FRetornaValorFixoFUC

   Objetivo: Retorna valor de remuneracao do FUC de acordo com os parametros informados,
             priorizando o valor defindo no orgao.

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornavalorfixofuc(pcdpadraofucagrup IN INTEGER,
                                pcdagrupamento    IN INTEGER,
                                pcdorgao          IN INTEGER,
                                pnuversaotabfuc   IN INTEGER,
                                pnuanoreferencia  IN INTEGER,
                                pNuMesReferencia  IN INTEGER) RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*
     Funcao: FRetornaValorFixoCCO

   Objetivo: Retorna valor de remuneracao do CCO de acordo com os parametros informados,
             priorizando o valor defindo no orgao.

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornavalorfixocco(pnucodigo          IN VARCHAR2,
                                pnunivel           IN VARCHAR2,
                                pcdrelacaotrabalho IN INTEGER,
                                pcdagrupamento     IN INTEGER,
                                pcdorgao           IN INTEGER,
                                pnuversaotabcco    IN INTEGER,
                                pnuanoreferencia   IN INTEGER,
                                pNuMesReferencia   IN INTEGER) RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*

    Funcao: FTipoTabelaCEF

   Objetivo: Retorna registro com as tabelas de valores para cargos efetivos
             de acordo com o ano/mes de processamento,orgao, versao e
             estrutura de carreira passados como parametro.

             Quando a tabela de valores utilizada e a Geral do Agrupamento, e
             necessario buscar tambem os codigos dos historicos das tabelas
             no agrupamento e no orgao, que serao utilizados para encontrar
             o valor da carga horaria padrao.

             1) Busca o valor do campo InTabelaUtilizada da tabela de valores
                do Agrupamento
             2) Se InTabelaUtilizada = 3, busca a definicao na tabela de
                valores do Orgao

    Retorno: Registro contendo:
             - o tipo de tabela utilizada
             - o codigo do historico da tabela de valores gerais do agrupamento
             - o codigo do historico da tabela de valores no agrupamento
             - o codigo do historico da tabela de valores no orgao

        Obs: Caso nao seja encontrada a tabela de valores para os parametros
             informados, o atributo InTabelaUtilizada sera = '0'

  /*--------------------------------------------------------------------------------------*/

  FUNCTION ftipotabelacef(pcdagrupamento       IN INTEGER,
                          pcdorgao             IN INTEGER,
                          pnuversao            IN INTEGER,
                          pnuano               IN INTEGER,
                          pnumes               IN INTEGER,
                          pcdestruturacarreira IN INTEGER)

   RETURN pkgpag_tipo.rtipotabelacef;

  /*--------------------------------------------------------------------------------------/

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fcalculaproporcionalidade(pfolha          IN pkgpag_tipo.rfolha,
                                     prubrica        IN pkgpag_tipo.rrubrica,
                                     pvalorintegral  IN NUMBER DEFAULT NULL,
                                     pnucho          IN NUMBER DEFAULT NULL,
                                     pcef            IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pfuc            IN pkgpag_tipo.rfuc DEFAULT NULL,
                                     pcco            IN pkgpag_tipo.rcco DEFAULT NULL,
                                     pccosubst       IN pkgpag_tipo.rcco DEFAULT NULL,
                                     papo            IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pbol            IN pkgpag_tipo.rbol DEFAULT NULL,
                                     ppnp            IN pkgpag_tipo.rpensaonaoprev DEFAULT NULL,
                                     pdtcalculo      IN DATE DEFAULT NULL,
                                     peventocef      IN CHAR DEFAULT 'N',
                                     pnudiasccosubst IN INTEGER DEFAULT NULL)

   RETURN pkgpag_tipo.rvalorpagamento;

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fpossuiabrangenciarubrica(prubrica                  IN pkgpag_tipo.rrubrica,
                                     pcdorgao                  IN INTEGER,
                                     pcdorgaoexercicio         IN INTEGER,
                                     pcdnaturezavinculo        IN INTEGER DEFAULT NULL,
                                     pcdrelacaotrabalho        IN INTEGER DEFAULT NULL,
                                     pcdregimetrabalho         IN INTEGER DEFAULT NULL,
                                     pcdregimeprevidenciario   IN INTEGER DEFAULT NULL,
                                     pcdsituacaoprevidenciaria IN INTEGER DEFAULT NULL,
                                     pcdestruturacarreira      IN INTEGER DEFAULT NULL,
                                     pcdunidadeorganizacional  IN INTEGER DEFAULT NULL,
                                     pcdfuncaochefia           IN INTEGER DEFAULT NULL,
                                     pcdcargocomissionado      IN INTEGER DEFAULT NULL,
                                     pcdgrupoocupacional       IN INTEGER DEFAULT NULL,
                                     pcdopcaoremuneracao       IN INTEGER DEFAULT NULL,
                                     pflapoorigemcco           IN CHAR DEFAULT NULL,
                                     pfltipoprovimento         IN CHAR DEFAULT NULL,
                                     pflaplicatodosorgaos      IN CHAR DEFAULT 'N',
                                     pflaposemparidade         IN CHAR DEFAULT NULL,
                                     pcdprograma               IN INTEGER DEFAULT NULL,
                                     pcdmotivomovimentacao     IN INTEGER DEFAULT NULL,
                                     pcdinstitutomovimentacao  IN INTEGER DEFAULT NULL,
                                     pflexercicioorigem        IN CHAR DEFAULT 'N',
                                     pcdtiporelacaovinculo     IN INTEGER DEFAULT NULL)
    RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistcef(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pcef                 IN pkgpag_tipo.rcef,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7);

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistfuc(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pfuc                 IN pkgpag_tipo.rfuc,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdexpressaoformula  IN INTEGER DEFAULT NULL,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7,
                             pNuSufixoRubrica     IN INTEGER DEFAULT 1);

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistcco(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pcco                 IN pkgpag_tipo.rcco,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdexpressaoformula  IN INTEGER DEFAULT NULL,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7);

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pValidaTotalPensao(pcdfolhapagamento IN INTEGER,
                               pcdvinculo        IN INTEGER);

  PROCEDURE pinserelancamentovinculo(pcdfolhapagamento            IN INTEGER,
                                     pcdvinculo                   IN INTEGER,
                                     pcdexpressaoformcalc         IN INTEGER,
                                     pcdrubricaagrupamento        IN INTEGER,
                                     pnusufixorubrica             IN INTEGER,
                                     pvlpagamento                 IN NUMBER,
                                     pvlindice                    IN NUMBER DEFAULT NULL,
                                     pnuparcelas                  IN INTEGER DEFAULT NULL,
                                     pcdbaseconsignacao           IN INTEGER DEFAULT NULL,
                                     pcdtipoorigemrubrica         IN INTEGER DEFAULT 1,
                                     pcdlancamentofinanceiro      IN INTEGER DEFAULT NULL,
                                     pdeprocessoretroativo        IN VARCHAR2 DEFAULT NULL,
                                     pvlrestituir                 IN NUMBER DEFAULT NULL,
                                     pvlindicenmrra               IN NUMBER DEFAULT NULL,
                                     pcdtipoindice                IN NUMBER DEFAULT NULL,
                                     pdeindicecontracheque        IN VARCHAR2 DEFAULT NULL,
                                     pcdprocessopagretroativo     IN INTEGER DEFAULT NULL,
                                     pcdhistsentencajudicial      IN INTEGER DEFAULT NULL,
                                     pnuanomesorigem              IN INTEGER DEFAULT NULL,
                                     pcdprocessorestituicaoerario IN INTEGER DEFAULT NULL,
                                     pDeExpressao                 IN VARCHAR2 DEFAULT NULL);

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistapo(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             papo                 IN pkgpag_tipo.rcef,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7,
                             pcdtipoindice        IN INTEGER DEFAULT NULL);

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornavalorrubrica(pcdfolhapagamento    IN INTEGER,
                                pcdvinculo           IN INTEGER,
                                pcdrubrica           IN INTEGER,
                                pnusufixo            IN INTEGER DEFAULT 1,
                                pcdtipoorigemrubrica IN INTEGER DEFAULT NULL)

   RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornasomavalorrubricasupl(pcdfolhapagamento     IN INTEGER,
                                        pcdvinculo            IN INTEGER,
                                        pcdrubricaagrupamento IN INTEGER)

   RETURN NUMBER;
  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornasomavalorrubrica(pdtinicio      IN DATE,
                                    pdtfim         IN DATE,
                                    pcdvinculo     IN INTEGER,
                                    pcdrubrica     IN INTEGER,
                                    pcdtipofolha   IN INTEGER DEFAULT 1,
                                    pcdtipocalculo IN INTEGER DEFAULT 1)

   RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION frecebeurubrica(pcdvinculo     IN INTEGER,
                           pcdrubrica     IN INTEGER,
                           pnuanomes      IN CHAR,
                           pnumeses       IN INTEGER DEFAULT 0,
                           pcdtipocalculo IN INTEGER DEFAULT NULL,
                           pcdtipofolha   IN INTEGER DEFAULT NULL,
                           pcdfolhaatual  IN INTEGER DEFAULT NULL)
    RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornaindicerubrica(pcdfolhapagamento IN INTEGER,
                                 pcdvinculo        IN INTEGER,
                                 pcdrubrica        IN INTEGER,
                                 pnusufixo         IN INTEGER DEFAULT 1,
                                 psomaindice       IN BOOLEAN DEFAULT FALSE,
                                 pData             in date default null)

   RETURN NUMBER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistbol(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pbol                 IN pkgpag_tipo.rbol,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7);

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fidentificaformulacalculo(pformexpr                IN pkgpag_tipo.tformulacalculo,
                                     pcdrubricaagrupamento    IN INTEGER,
                                     pcdrelacaovinculo        IN INTEGER,
                                     pcdestruturacarreira     IN INTEGER DEFAULT NULL,
                                     pcdcargocomissionado     IN INTEGER DEFAULT NULL,
                                     pcdfuncaochefia          IN INTEGER DEFAULT NULL,
                                     pcdunidadeorganizacional IN INTEGER DEFAULT NULL,
                                     pnuformulaespecifica     IN INTEGER DEFAULT NULL)

   RETURN INTEGER;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/

  PROCEDURE pinserelancamentorelacao(pcdfolhapagamento            IN INTEGER,
                                     pcdvinculo                   IN INTEGER,
                                     pcdrelacaovinculo            IN INTEGER,
                                     pcdhistrelacaovinculo        IN INTEGER,
                                     pcdexpressaoformcalc         IN INTEGER,
                                     pcdrubricaagrupamento        IN INTEGER,
                                     pvlintegral                  IN NUMBER,
                                     pvlproporcional              IN NUMBER,
                                     pnusufixorubrica             IN INTEGER,
                                     pnuparcelas                  IN INTEGER DEFAULT NULL,
                                     pvlindice                    IN NUMBER DEFAULT NULL,
                                     pdtiniciorelacao             IN DATE DEFAULT NULL,
                                     pdtdesligamento              IN DATE DEFAULT NULL,
                                     pcdunidadeorganizacional     IN INTEGER DEFAULT NULL,
                                     pcdvantagempecuniaria        IN INTEGER DEFAULT NULL,
                                     pcdrubtotvantagem            IN INTEGER DEFAULT NULL,
                                     pcdincorporacaoativo         IN INTEGER DEFAULT NULL,
                                     pcdlancamentofinanceiro      IN INTEGER DEFAULT NULL,
                                     pvlminrecebincorp            IN NUMBER DEFAULT NULL,
                                     pflatualizacaoconstante      IN CHAR DEFAULT NULL,
                                     pflvigenciapagamento         IN CHAR DEFAULT NULL,
                                     pcdtipoorigemrubrica         IN INTEGER DEFAULT NULL,
                                     pdtinicio                    IN DATE DEFAULT NULL,
                                     pdtfim                       IN DATE DEFAULT NULL,
                                     pvlreal                      IN NUMBER DEFAULT NULL,
                                     pdescritivo                  IN VARCHAR2 DEFAULT NULL,
                                     pvlindicereal                IN NUMBER DEFAULT NULL,
                                     pcdtipoindice                IN NUMBER DEFAULT NULL,
                                     pdeindicecontracheque        IN VARCHAR2 DEFAULT NULL,
                                     pcdprocessopagretroativo     IN INTEGER DEFAULT NULL,
                                     pcdhistsentencajudicial      IN INTEGER DEFAULT NULL,
                                     pnuanomesorigem              IN INTEGER DEFAULT NULL,
                                     pCdProcessoRestituicaoErario IN INTEGER DEFAULT NULL);

  /*-----------------------------------------------------------------------------------------
    Function: FGeraRubricasTotalizadoras

    Objetivo: Gerar historicos de pagamentos para as relacoes de vinculo e vinculo
              com as rubricas do agrupamento cujo tipo e Totalizadora

    Argumentos: pFolha - registro contendo informacoes da folha que esta sendo processada
                pCdVinculo - codigo do vinculo cuja folha esta sendo calculada

  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fgerarubricastotalizadoras(pfolha     IN pkgpag_tipo.rfolha,
                                      pCdVinculo IN INTEGER) RETURN BOOLEAN;

  PROCEDURE patualizatotalizadoras(pcdfolhapagamento IN INTEGER,
                                   pcdvinculo        IN INTEGER);

  PROCEDURE parmazenarelacoesvinculo(pcdvinculo   IN INTEGER,
                                     pflvalidapag IN CHAR DEFAULT 'S');

  PROCEDURE pincluirubricamneurub(pcdrubricaagrupamentoexistente IN INTEGER,
                                  pcdrubricaagrupamentinserir    IN INTEGER,
                                  pcontidaem                     IN INTEGER);

  FUNCTION frubricapermitida(pflpagatodasrubricas  IN CHAR,
                             pcdtipofolha          IN INTEGER,
                             pCdRubricaAgrupamento IN INTEGER) RETURN BOOLEAN;

  FUNCTION fDtInclusaoCef(pcdvinculo IN INTEGER) RETURN DATE;

  FUNCTION fsituacaoprevvigente(pcdvinculo   IN INTEGER,
                                pdtiniciomes IN DATE,
                                pDtFimMes    IN DATE) RETURN INTEGER;

  FUNCTION fflativo(pcdvinculo INTEGER, pcdsituacaoprevidenciaria INTEGER)
    RETURN CHAR;
    
  PROCEDURE pgeracapalote(pcdfolhapagamento       IN INTEGER,
                          pcdvinculo              IN INTEGER,
                          pflativo                IN CHAR,
                          pmotafast               IN pkgpag_tipo.rmotafast,
                          pflpagamentobloqueado   IN CHAR,
                          pVlPercentContribIndiv  IN NUMBER DEFAULT NULL);

  PROCEDURE parmazenacho;

  /*--------------------------------------------------------------------------------------/*
     Funcao: FRetornaValorRubricaRV

   Objetivo: Retorna valores Real, Integral, Proporcional e Indice pagos na relacao de vinculo
             para um determinado vinculo em uma folha.

  /*--------------------------------------------------------------------------------------*/

  FUNCTION fretornavalorrubricarv(pcdfolhapagamento     IN INTEGER,
                                  pcdvinculo            IN INTEGER,
                                  pcdrubricaagrupamento IN INTEGER,
                                  pcdrelacaovinculo     IN INTEGER)
    RETURN pkgpag_tipo.rvalorpagamento;

  FUNCTION fretornavaloroutrasrv(pcdfolhapagamento     IN INTEGER,
                                 pcdvinculo            IN INTEGER,
                                 pcdrubricaagrupamento IN INTEGER)
    RETURN pkgpag_tipo.rvalorpagamento;

  FUNCTION FDisposicaoParcialNoMes(pCEF   IN PKGPAG_TIPO.rCEF,
                                   pFolha IN PKGPAG_TIPO.rFolha)
    RETURN BOOLEAN;

  function fVlTotalProventos13(pcdfolhapagamento IN INTEGER,
                               pcdvinculo        IN INTEGER) return number;

  FUNCTION fVlBaseIPREVComissionadoADisp(pfolha     IN pkgpag_tipo.rfolha,
                                         pCdVinculo IN INTEGER) RETURN NUMBER;

  FUNCTION FObterDtInclusaoAfaDefinitivo(pCdVinculo IN INTEGER) RETURN DATE;

  FUNCTION FAnoMesRecadPensLiberado(pNuAno IN INTEGER, pNuMes IN INTEGER)
    RETURN BOOLEAN;

  FUNCTION FOrgaoUtilizaFolhaPDI(pCdOrgao IN INTEGER) RETURN BOOLEAN;

  /*--------------------------------------------------------------------------------------/*
     Tratamento de bloqueio de pagamento e afastamento tempor?rio de Inativos e Pensionistas
  /*--------------------------------------------------------------------------------------*/

  FUNCTION FTratarBloqPgtoInatEPensoesP(pCdVinculo                     INTEGER,
                                        pCdPessoa                      INTEGER,
                                        pDataNascimento                DATE,
                                        pCdOrgao                       INTEGER,
                                        pCdMotivoAfastamentoTemporario INTEGER,
                                        pNuAnoReferencia               INTEGER,
                                        pNuMesReferencia               INTEGER,
                                        pCdTipoFolha                   INTEGER,
                                        pCdTipoCalculo                 INTEGER,
                                        pDataInicioMes                 DATE,
                                        pInserirLog                    BOOLEAN,
                                        pCdHistoricoParamCalculo       INTEGER)
    RETURN CHAR;

  FUNCTION FTratarBloqPgtoPensoesNaoPrev(pCdVinculo               INTEGER,
                                         pCdPessoa                INTEGER,
                                         pNuAnoReferencia         INTEGER,
                                         pNuMesReferencia         INTEGER,
                                         pCdTipoPensaoNaoPrev     INTEGER,
                                         pInserirLog              BOOLEAN,
                                         pCdHistoricoParamCalculo INTEGER)
    RETURN CHAR;

  PROCEDURE PTratarAfastPorFaltaDeRecad(pCdVinculo                     INTEGER,
                                        pCdPessoa                      INTEGER,
                                        pCdMotivoAfastamentoTemporario INTEGER,
                                        pDataInicioMes                 DATE,
                                        pCdOrgao                       INTEGER,
                                        pCdTipoFolha                   INTEGER,
                                        pInserirLog                    BOOLEAN,
                                        pCdHistoricoParamCalculo       INTEGER,
                                        pFlpagamentobloqueado          IN OUT CHAR);

  PROCEDURE PInserirAfastamentoTemporario(pCdVinculo                     INTEGER,
                                          pCdMotivoAfastamentoTemporario INTEGER,
                                          pDataInicio                    DATE);

  PROCEDURE PExcluirAfastamentoTemporario(pCdVinculo                     INTEGER,
                                          pCdMotivoAfastamentoTemporario INTEGER,
                                          pDataInicio                    DATE,
                                          pCpfCadastrador                CHAR);

  PROCEDURE PObterInfoRecadastramento(pCdVinculo                  IN INTEGER,
                                      pQtdPagamentosBloqueados    OUT INTEGER,
                                      pQtdMesesSemRecadastramento OUT INTEGER);

  FUNCTION FGerarAfastPorFaltaDeRecad(pCdVinculo   IN INTEGER,
                                      pCdTipoFolha IN INTEGER) RETURN BOOLEAN;

  FUNCTION FCreditobloqueadoPensionistaNP(pcdvinculo IN INTEGER,
                                          pnuano     IN INTEGER,
                                          pNuMes     IN INTEGER)
    RETURN BOOLEAN;

  FUNCTION FPossuiAfastTempAnteriorDtRef(pcdvinculo         IN INTEGER,
                                         pcdmotivoafasttemp IN INTEGER,
                                         pDataReferencia    IN DATE)
    RETURN BOOLEAN;

  FUNCTION FPossuiAfastamentoTemporario(pCdVinculo                     INTEGER,
                                        pCdMotivoAfastamentoTemporario INTEGER,
                                        pDataInicio                    DATE,
                                        pCpfCadastrador                CHAR)
    RETURN BOOLEAN;

  FUNCTION FObterDiasAfastamentoTemporario(pDtInicioMes       IN DATE,
                                           pDtFimMes          IN DATE,
                                           pCdVinculo         IN INTEGER,
                                           pListaMotAfastTemp IN sys.odcinumberlist)
    RETURN INTEGER;

  FUNCTION FListaMotivosAfastTempExigidos(pCdRubricaAgrupamento IN INTEGER,
                                          pDataVigencia         IN DATE)
    RETURN sys.odcinumberlist;

  FUNCTION FObterProporcaoDiasAReceberMes(pQualquerDiaDoMes IN DATE,
                                          pDiasAReceber     IN OUT INTEGER)
    RETURN NUMBER;

  FUNCTION FQuantidadeDiasMes(pQualquerDiaDoMes IN DATE) RETURN INTEGER;

  FUNCTION FObterFolhasPagamentoCapa(pCdVinculo           IN INTEGER,
                                     pNuAno               IN INTEGER,
                                     pNuMes               IN INTEGER,
                                     pflCalculoDefinitivo IN CHAR)
    RETURN sys.odcinumberlist;

  FUNCTION FObterOrgaoExercicioCCO(pCdVinculo           IN INTEGER,
                                   pDataReferencia      IN DATE)
    RETURN INTEGER;


  FUNCTION FRubricaPresenteNoContracheque(pCdVinculo            IN INTEGER,
                                          pCdRubricaAgrupamento IN INTEGER,
                                          pCdFolhaPagamento     IN INTEGER)
    RETURN BOOLEAN;
    
  
  FUNCTION FObterInfoRubrica(pCdRubricaAgrupamento IN EPAGRUBRICAAGRUPAMENTO.CDRUBRICAAGRUPAMENTO%TYPE) 
    RETURN PKGPAG_TIPO.rRubrica; 

  FUNCTION FObterQtdDiasIntervaloMes(pDtInicioMes       IN DATE,
                                     pDtFimMes          IN DATE,
                                     pDtInicioIntervalo IN DATE,
                                     pDtFimIntervalo    IN DATE) RETURN INTEGER;

/*-----------------------------------------------------------------------------------------*/

END pkgpag_geral;
/
CREATE OR REPLACE PACKAGE BODY pkgpag_geral IS

  blogproc     BOOLEAN DEFAULT TRUE; -- indica se trace de procedimentos ligado ou nao
  dtreferencia DATE;

  vgvlsomadias          INTEGER;
  vgvlsomaremunpaga     NUMBER;
  vgvlremuneracao       NUMBER;
  vgnutotaldias         NUMBER;
  vgflaplicarvinculado  BOOLEAN;
  vgnudiasafastgravidez NUMBER;

  TYPE treglogproc IS RECORD(
    deproc        VARCHAR2(60),
    nutempoinicio INTEGER,
    nutempofim    INTEGER,
    nutempototal  INTEGER,
    nuentrada     NUMBER,
    nusaida       number,
    ordem         VARCHAR2(20) );

  type tTabLogProc IS TABLE OF tRegLogProc INDEX BY varchar2(60);

  gtablogproc      ttablogproc;
  glogprociniciado CHAR(1) DEFAULT 'N'; -- indica se trace de procedimentos foi iniciado

  /*Grava log para verificacao de tempos e depuracao do calculo do vinculo */

  FUNCTION fgettime RETURN INTEGER IS
  BEGIN
     RETURN dbms_utility.get_time;
  END;

  PROCEDURE plogtrace(plocal   IN VARCHAR2,
                      ptrace   IN VARCHAR2,
                      ptimeini IN INTEGER DEFAULT NULL) IS

    vtmfim INTEGER;

    vtempototal INTEGER;

  BEGIN
 
    IF pkgpag_var.btrace THEN

      vtempototal := NULL;

      vtmfim := dbms_utility.get_time;

      IF ptimeini IS NOT NULL THEN

        vtempototal := vtmfim - ptimeini;

      END IF;

      INSERT INTO ePagLogTrace
        (CDCALCULO,
         cdhistoricoparamcalculo,
         cdvinculo,
         delocal,
         detrace,
         dtlog,
         nutempoinicio,
         nutempofim,
         NUTEMPOTOTAL)
      VALUES
        (PKGPAG_VAR.vgCalculo.cdCalculo,
         pkgpag_var.vgcalculo.cdhistoricoparamcalculo,
         pkgpag_var.vgcdvinculo,
         plocal,
         ptrace,
         systimestamp,
         ptimeini,
         vtmfim,
         vtempototal);

    END IF;

  END;

  PROCEDURE plogprocini(pordem IN VARCHAR2, pproc IN VARCHAR2) IS
    vtmini INTEGER;
  BEGIN
 
    IF blogproc AND glogprociniciado = 'S' THEN
      vtmini := dbms_utility.get_time;

      IF NOT gtablogproc.exists(pOrdem) THEN
        gtablogproc(pordem).deproc := pproc;
        gtablogproc(pordem).nutempototal := 0;
        gtablogproc(pordem).nusaida := 0;
        gtablogproc(pordem).nuentrada := 0;
        gtablogproc(pordem).ordem := pOrdem;        
      END IF;
      gtablogproc(pordem).nutempoinicio := vtmini;
      gtablogproc(pordem).nutempofim := NULL; -- Esperando fim
      gtablogproc(pordem).nuentrada := gtablogproc(pordem).nuentrada + 1;
    END IF;
  END;

  PROCEDURE plogprocfim(pordem IN VARCHAR2) IS
    vtmfim INTEGER;
  BEGIN
 
    IF blogproc AND glogprociniciado = 'S' THEN
      vtmfim := dbms_utility.get_time;

      IF NOT gtablogproc.exists(pordem) THEN
        gtablogproc(pordem).deproc := '* NAO INCLUIDO';
        gtablogproc(pordem).nutempoinicio := NULL;
        gtablogproc(pordem).nutempototal := 0;
        gtablogproc(pordem).nuentrada := 0;
        gtablogproc(pordem).nusaida := 0;
        gtablogproc(pordem).ordem := pOrdem; 

      ELSIF gTabLogProc(pordem).nuTempoFim IS NOT NULL THEN
        -- Fim nao esperado
        gtablogproc(pordem).nutempoinicio := NULL;
      else
        null;
      END IF;

      gtablogproc(pordem).nutempofim := vtmfim; -- Fim registrado
      IF gtablogproc(pordem).nutempoinicio IS NOT NULL THEN
        gTabLogProc(pordem).nuTempoTotal := gTabLogProc(pordem).nuTempoTotal +
                                            (vTmFim - gTabLogProc(pordem).nuTempoInicio);
      END IF;

      gtablogproc(pordem).nusaida := gtablogproc(pordem).nusaida + 1;

    END IF;
  END;

  PROCEDURE plogproc(pordemfim IN VARCHAR2, pordemini IN VARCHAR2, pprocini IN VARCHAR2) IS
  BEGIN
 
    IF blogproc AND glogprociniciado = 'S' THEN
      plogprocfim(pordemfim);
      plogprocini(pordemini, pprocini);
    END IF;
  END;

  PROCEDURE piniciarlogproc IS
  BEGIN
      glogprociniciado := 'S';
      gtablogproc.delete;
      plogprocini('T', 'Total');

  END;

  PROCEDURE pfinalizarlogproc(pcalculo IN pkgpag_cal.rcalculo) IS

    rec VARCHAR2(60);

  BEGIN
 
    plogprocfim('T');

    rec := gtablogproc.first;

    WHILE rec IS NOT NULL LOOP

      INSERT INTO epaglogproc
        (cdcalculo,
         deproc,
         cdhistoricoparamcalculo,
         nutempoinicio,
         nutempofim,
         nutempototal,
         nuentrada,
         nusaida)
      VALUES
        (pcalculo.cdcalculo,
         gtablogproc (rec).ordem || ' - ' || gtablogproc (rec).deproc,
         pcalculo.cdhistoricoparamcalculo,
         gtablogproc (rec).nutempoinicio,
         gtablogproc (rec).nutempofim,
         gtablogproc (rec).nutempototal,
         gtablogproc (rec).nuentrada,
         gtablogproc (rec).nusaida);

      rec := gtablogproc.next(rec);

    END LOOP;

    glogprociniciado := 'N';

  exception
    when others then
      null;
  END;
  
  PROCEDURE PErroFatal (pMsgErro IN VARCHAR2) IS  
  BEGIN
    raise_application_error( -20001,pMsgErro);   
  END;  

  -- Trata datas, limitando a soma de dias trabalhado a 30 dias.
  -- Devera ser passado como parametro uma variavel de entrada e saida,
  -- pNudiasTrabalhadosSoma, que ira controlar a soma de dias trabalhados.
  FUNCTION fTratarDatas(pDtInicioMes           IN DATE,
                        pDtFimMes              IN DATE,
                        pDtInicioTrabalho      IN DATE,
                        pDtFimTrabalho         IN DATE,
                        pNudiasTrabalhadosSoma IN OUT INTEGER)

   RETURN pkgpag_tipo.rData IS

    vData pkgpag_tipo.rData;

  BEGIN
 
    vData := fTratarDatas(pDtInicioMes,
                          pDtFimMes,
                          pDtInicioTrabalho,
                          pDtFimTrabalho);

    pNudiasTrabalhadosSoma := pNudiasTrabalhadosSoma +
                              vData.vNuDiasTrabalhados;

    -- Limita a soma a 30 dias
    IF pNudiasTrabalhadosSoma > 30 THEN

      vData.vNuDiasTrabalhados := vData.vNuDiasTrabalhados -
                                  (pNudiasTrabalhadosSoma - 30);

    END IF;

    RETURN vData;

  END;

  FUNCTION fTratarDatas(pDtInicioMes      IN DATE,
                        pDtFimMes         IN DATE,
                        pDtInicioTrabalho IN DATE,
                        pDtFimTrabalho    IN DATE)

   RETURN pkgpag_tipo.rData IS

    vData              pkgpag_tipo.rData;
    vNudiasMes         INTEGER;
    vNudiasTrabalhados INTEGER;

  BEGIN
 
    vNudiasMes         := LEAST(to_number(TO_CHAR(pDtFimMes, 'DD')), 30) -
                          to_number(TO_CHAR(pDtInicioMes, 'DD')) + 1;
    vNudiasTrabalhados := LEAST(pDtFimTrabalho - pDtInicioTrabalho + 1, 30);

    IF to_number(TO_CHAR(pDtFimMes, 'MM')) = 2 THEN
      -- Para o mes de fevereiro, faz o ajuste
      IF TO_CHAR(pDtFimMes, 'DD') = '28' THEN
        vNudiasMes := LEAST(vNudiasMes + 2, 30);
      ELSIF TO_CHAR(pDtFimMes, 'DD') = '29' THEN
        vNudiasMes := LEAST(vNudiasMes + 1, 30);
      END IF;
    END IF;

    -- Para o mes de fevereiro, se trabalhou o ultimo dia do mes, faz o ajuste
    IF to_number(TO_CHAR(pDtFimTrabalho, 'MM')) = 2 AND
       pDtFimTrabalho >= pDtFimMes THEN
      IF TO_CHAR(pDtFimTrabalho, 'DD') = '28' THEN
        vNudiasTrabalhados := LEAST(vNudiasTrabalhados + 2, 30);
      ELSIF TO_CHAR(pDtFimMes, 'DD') = '29' THEN
        vNudiasTrabalhados := LEAST(vNudiasTrabalhados + 1, 30);
      END IF;
    END IF;

    vData.vNuDiasMes         := vNudiasMes;
    vData.vNuDiasTrabalhados := vNudiasTrabalhados;
    vData.VlIndice           := vNudiasTrabalhados / vNudiasMes;

    RETURN vData;

  END;

  FUNCTION fproxcarreira(pcdestruturacarreira IN INTEGER) RETURN INTEGER IS

  BEGIN
 
    IF pkgpag_var.vgcarreira.exists(pcdestruturacarreira) THEN

      RETURN pkgpag_var.vgcarreira(pcdestruturacarreira).cdestruturacarreirapai;

    ELSE

      RETURN NULL;

    END IF;

  END;

  FUNCTION fexistecarreira(pcdestruturacarreira IN INTEGER) RETURN INTEGER IS

  BEGIN
 
    IF pkgpag_var.vgcarreira.exists(pcdestruturacarreira) THEN

      RETURN pcdestruturacarreira;

    ELSE

      RETURN NULL;

    END IF;

  END;

PROCEDURE PCarregarFolhaVinculo (pCdCalculo          IN INTEGER, 
                                 pCdPessoa           IN INTEGER, 
                                 pNuAnoMesIni        IN INTEGER DEFAULT NULL,
                                 pFlIniciarPessoa    IN INTEGER DEFAULT 0) IS
  
   vFlIncluir            INTEGER;
   vFlCalculoDefinitivo  CHAR(1);
   vCdPessoa             INTEGER;
   vTabVinculo           TYPENUMBER;
   
   vNuAnoMesIni          INTEGER;
   vNuAnoMesFim          INTEGER;
   vFolha13              INTEGER;
     
BEGIN
   
   IF PKGPAG_TIPO.cnTipoFolhaPag13.EXISTS (PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento) THEN
      vFolha13 := 1;
   ELSE
      vFolha13 := 0;
   END IF;
  
   IF pFlIniciarPessoa = 1 THEN
      vNuAnoMesFim  :=  PKGPAG_VAR.vgFolha.NuAnoMesReferencia;
      IF pNuAnoMesIni IS NULL THEN
         vNuAnoMesIni  := TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE (vNuAnoMesFim,'YYYYMM'),-14),'YYYYMM'));
      END IF;

      DELETE ECALFolhaPag
         WHERE CdCalculo = pCdCalculo;
       
   ELSIF pNuAnoMesIni < PKGPAG_VAR.vgMenorAnoMesFolPag THEN
      vNuAnoMesIni  := pNuAnoMesIni;
      vNuAnoMesFim  := TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE (PKGPAG_VAR.vgMenorAnoMesFolPag,'YYYYMM'),-1),'YYYYMM'));
   ELSE
      RETURN;
   END IF;
   
   -- Deve dar Carga
   
   PKGPAG_VAR.vgMenorAnoMesFolPag := vNuAnoMesIni;
        
   SELECT CdVinculo
     BULK COLLECT INTO vTabVinculo
     FROM ECadVinculo
    WHERE CdPessoa = pCdPessoa;       
    
   INSERT INTO ECALFolhaPag
      (CdCalculo,
       cdfolhapagamento,
       cdfolhavincsupl, 
       cdorgao, 
       nuanoreferencia, 
       numesreferencia, 
       cdtipofolhapagamento, 
       cdtipocalculo, 
       flcalculodefinitivo, 
       cdagrupamento, 
       nusequencialfolha, 
       nuanomesreferencia, 
       flfolhafechada, 
       FlMesCorrente,
       FlMesAnterior,
       FlMediaSaude,
       FlUlt12Meses,
       FlAnoCorrente)   
       
   SELECT pCdCalculo,
          FP.cdfolhapagamento,
          FP.cdfolhavincsupl, 
          FP.cdorgao, 
          FP.nuanoreferencia, 
          FP.numesreferencia, 
          FP.cdtipofolhapagamento, 
          FP.cdtipocalculo,
          CASE 
             WHEN FP.FlCalculoDefinitivo = 'N' AND vFolha13 = 1 AND FP.CdTipoCalculo = 1  
               AND (TFP.CdTipoFolha IN (1 ,7 ,12 ,17,19) -- Folhas mensais
                    OR FP.CdTipoFolhaPagamento IN (1526,1505,1525) ) THEN -- PRODEX E  PROCURADORES
                'S'
             ELSE
                FP.FlCalculoDefinitivo
          END AS FlCalculoDefinitivo, 
          FP.cdagrupamento, 
          FP.nusequencialfolha, 
          FP.nuanomesreferencia, 
          FP.flfolhafechada, 
                      

          CASE WHEN FP.NuAnoMesReferencia = PKGPAG_VAR.vgFolha.NuAnoMesReferencia THEN
                  1
               ELSE
                  0
          END AS FlMesCorrente,

          CASE WHEN FP.NuAnoMesReferencia = TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE (PKGPAG_VAR.vgFolha.NuAnoMesReferencia,'YYYYMM'),-1),'YYYYMM')) THEN
                  1
               ELSE
                  0
          END AS FlMesAnterior,

          CASE WHEN FP.NuAnoMesReferencia BETWEEN TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE (PKGPAG_VAR.vgFolha.NuAnoMesReferencia,'YYYYMM'),-14),'YYYYMM'))
                                              AND TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE (PKGPAG_VAR.vgFolha.NuAnoMesReferencia,'YYYYMM'),-3),'YYYYMM')) THEN
                  1
               ELSE
                  0
          END AS FlMediaSaude,

          CASE WHEN FP.NuAnoMesReferencia BETWEEN TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE (PKGPAG_VAR.vgFolha.NuAnoMesReferencia,'YYYYMM'),-11),'YYYYMM'))
                                              AND PKGPAG_VAR.vgFolha.NuAnoMesReferencia THEN
                  1
               ELSE
                  0
          END AS FlUlt12Meses,
                                    
          CASE WHEN FP.NuAnoReferencia = TRUNC (PKGPAG_VAR.vgFolha.NuAnoMesReferencia / 100) THEN
                  1
               ELSE
                  0
          END AS FlAnoCorrente
                             
     FROM EPAGFOLHAPAGAMENTO FP
    INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
       ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento

    WHERE NuAnoMesReferencia BETWEEN vNuAnoMesIni AND vNuAnoMesFim
      AND (NuAnoMesReferencia <>  PKGPAG_VAR.vgFolha.NuAnoMesReferencia OR FP.DeOrdemExecucao <= PKGPAG_VAR.vgFolha.DeOrdemExecucao)                           
                                 
      AND ( FP.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
            OR (CdTipoCalculo IN (1,5)
                AND cdtipofolha NOT IN ( 6 , 17)
                AND EXISTS (SELECT 1
                     FROM EPAGHISTORICORUBRICAVINCULO hrv
                    INNER JOIN TABLE (vTabVinculo) v
                       ON v.Column_value = hrv.cdVinculo
                    WHERE hrv.cdFolhaPagamento = FP.CdFolhaPagamento
                      AND rownum <= 1) ) )                    
    ;                     
   
END;

FUNCTION FRetornaRegimeProprioPrev(pCdVinculo IN INTEGER) RETURN INTEGER IS
   
   vCdRegimeProprioPrev INTEGER;
   
BEGIN
   
   SELECT NVL(EV.Cdtiporegimeproprioprev, 0)
     INTO vCdRegimeProprioPrev
     FROM ECadVinculo EV
    WHERE EV.Cdvinculo = pCdVinculo;
   
   RETURN vCdRegimeProprioPrev;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN 0;
      
END;


FUNCTION FRetornaAliquotaCPSM(pCdTpTributacaoCPSM IN INTEGER,
                              pNuAnoReferencia    IN INTEGER,
                              pNuMesReferencia    IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaCPSM IS
   
   CURSOR cFaixa(pCdHistAliquotaCPSM IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM EtrbaliquotafaixaCPSM F
       WHERE F.CdHistAliquotaCPSM = pCdHistAliquotaCPSM
       ORDER BY F.VlInicial;
   
   vAliquotaCPSM PKGPAG_TIPO.rAliquotaCPSM;
   vFaixa        PKGPAG_TIPO.tFaixaAliquota;
   
BEGIN
   
   SELECT A.CdHistAliquotaCPSM, A.VlAliquotaUnica
     INTO vAliquotaCPSM.CdHistAliquotaCPSM,
          vAliquotaCPSM.VlAliquotaUnica
     FROM ETrbHistAliquotaCPSM A
    WHERE A.CdTipoAliquota = pCdTpTributacaoCPSM
      AND ((A.nuAnoInicio < pNuAnoReferencia OR
          (A.nuAnoInicio = pNuAnoReferencia AND
          A.nuMesInicio <= pNuMesReferencia)) AND
          (A.nuAnoFinal > pNuAnoReferencia OR
          (A.nuAnoFinal = pNuAnoReferencia AND
          A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));
   
   OPEN cFaixa(vAliquotaCPSM.CdHistAliquotaCPSM);
   
   FETCH cFaixa BULK COLLECT
      INTO vFaixa;
   
   CLOSE cFaixa;
   
   vAliquotaCPSM.lFaixa := vFaixa;
   
   RETURN vAliquotaCPSM;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN NULL;
      
END;

FUNCTION FRetornaAliquotaIPESC(pCdTpTributacaoIPESC IN INTEGER,
                               pNuAnoReferencia     IN INTEGER,
                               pNuMesReferencia     IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaIPESC IS
   
   CURSOR cFaixa(pCdHistAliquotaIPESC IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM EtrbaliquotafaixaIPESC F
       WHERE F.CdHistAliquotaIPESC = pCdHistAliquotaIPESC
       ORDER BY F.VlInicial;
   
   vAliquotaIPESC PKGPAG_TIPO.rAliquotaIPESC;
   vFaixa         PKGPAG_TIPO.tFaixaAliquota;
   
BEGIN
   
   SELECT A.CdHistAliquotaIPESC, A.VlAliquotaUnica
     INTO vAliquotaIPESC.CdHistAliquotaIPESC,
          vAliquotaIPESC.VlAliquotaUnica
     FROM ETrbHistAliquotaIPESC A
    WHERE A.CdTipoAliquota = pCdTpTributacaoIPESC
      AND ((A.nuAnoInicio < pNuAnoReferencia OR
          (A.nuAnoInicio = pNuAnoReferencia AND
          A.nuMesInicio <= pNuMesReferencia)) AND
          (A.nuAnoFinal > pNuAnoReferencia OR
          (A.nuAnoFinal = pNuAnoReferencia AND
          A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));
   
   OPEN cFaixa(vAliquotaIPESC.CdHistAliquotaIPESC);
   
   FETCH cFaixa BULK COLLECT
      INTO vFaixa;
   
   CLOSE cFaixa;
   
   vAliquotaIPESC.lFaixa := vFaixa;
   
   RETURN vAliquotaIPESC;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN NULL;
      
END;

FUNCTION FRetornaAliquotaIRRF(pNuAnoReferencia IN INTEGER,
                              pNuMesReferencia IN INTEGER,
                              pCdTipoAliquota  IN INTEGER DEFAULT 1)
   RETURN PKGPAG_TIPO.rAliquotaIRRF IS
   
   CURSOR cFaixa(pCdHistAliquotaIRRF IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM Etrbaliquotafaixairrf F
       WHERE F.CdHistAliquotaIRRF = pCdHistAliquotaIRRF
       ORDER BY F.VlInicial;
   
   vAliquotaIRRF PKGPAG_TIPO.rAliquotaIRRF;
   vFaixa        PKGPAG_TIPO.tFaixaAliquota;
   
BEGIN
   
   SELECT A.CdHistAliquotaIRRF,
          A.VlDeducaoDependente,
          A.VlDeducaoInativo
     INTO vAliquotaIRRF.CdHistAliquotaIRRF,
          vAliquotaIRRF.VlDeducaoDependente,
          vAliquotaIRRF.VlDeducaoInativo
     FROM ETrbHistAliquotaIRRF A
    WHERE A.CdTipoAliquotaIRRF = pCdTipoAliquota
      AND ((A.nuAnoInicio < pNuAnoReferencia OR
          (A.nuAnoInicio = pNuAnoReferencia AND
          A.nuMesInicio <= pNuMesReferencia)) AND
          (A.nuAnoFinal > pNuAnoReferencia OR
          (A.nuAnoFinal = pNuAnoReferencia AND
          A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));
   
   OPEN cFaixa(vAliquotaIRRF.CdHistAliquotaIRRF);
   
   FETCH cFaixa BULK COLLECT
      INTO vFaixa;
   
   CLOSE cFaixa;
   
   IF vFaixa.COUNT > 0 THEN
      
      vAliquotaIRRF.lFaixa := vFaixa;
      
      RETURN vAliquotaIRRF;
      
   ELSE
      
      RETURN NULL;
      
   END IF;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN NULL;
      
END;


FUNCTION FRetornaAliquotaINSS(pNuAnoReferencia IN INTEGER,
                              pNuMesReferencia IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaINSS IS
   
   CURSOR cFaixa(pCdHistAliquotaINSS IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             F.Flaliquotaprogressiva,
             hai.Vlaliqcontribindividual,
             hai.VLTETOCONTRIBINDIVIDUAL
        FROM EtrbaliquotafaixaINSS F
       INNER JOIN etrbhistaliquotainss hai
          ON hai.cdhistaliquotainss = f.cdhistaliquotainss
       WHERE F.CdHistAliquotaINSS = pCdHistAliquotaINSS
       ORDER BY F.VlInicial;
   
   vAliquotaINSS PKGPAG_TIPO.rAliquotaINSS;
   vFaixa        PKGPAG_TIPO.tFaixaAliquota;
   
BEGIN
   
   SELECT A.CdHistAliquotaINSS
     INTO vAliquotaINSS.CdHistAliquotaINSS
     FROM EtrbHistAliquotaINSS A
    WHERE ((A.nuAnoInicio < pNuAnoReferencia OR
          (A.nuAnoInicio = pNuAnoReferencia AND
          A.nuMesInicio <= pNuMesReferencia)) AND
          (A.nuAnoFinal > pNuAnoReferencia OR
          (A.nuAnoFinal = pNuAnoReferencia AND
          A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));
   
   OPEN cFaixa(vAliquotaINSS.CdHistAliquotaINSS);
   
   FETCH cFaixa BULK COLLECT
      INTO vFaixa;
   
   CLOSE cFaixa;
   
   IF vFaixa.COUNT > 0 THEN
      
      vAliquotaINSS.VlTeto                  := 0;
      vAliquotaINSS.VlAliqContribIndividual := 0;
      
      FOR i IN vFaixa.FIRST .. vFaixa.LAST
         
       LOOP

         IF vAliquotaINSS.VlTeto < vFaixa(i).VlFinal THEN
            
            vAliquotaINSS.VlTeto := vFaixa(i).VlFinal;
            
         END IF;
                  
         IF vAliquotaINSS.VlAliqContribIndividual < vFaixa(i).VlAliqContribIndividual THEN
            
            vAliquotaINSS.VlAliqContribIndividual := vFaixa(i).VlAliqContribIndividual;
            
         END IF;
         
      END LOOP;
      
      vAliquotaINSS.lFaixa := vFaixa;
      
      RETURN vAliquotaINSS;
      
   ELSE
      
      RETURN NULL;
      
   END IF;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN NULL;
      
END;

FUNCTION FAgrupUtilizaDescSimp(pCdAgrupamento IN INTEGER,
                               pNuAnoMesFolha IN INTEGER) RETURN BOOLEAN IS
   vUtiliza BOOLEAN := FALSE;
   i        INTEGER;

   TYPE rAdesaoDescSimplificado IS RECORD(
      CdAgrupamento  INTEGER,
      NuAnoMesAdesao INTEGER);

   TYPE tblAdesaoDescSimplificado IS TABLE OF rAdesaoDescSimplificado INDEX BY PLS_INTEGER;
              
   tblInfo  tblAdesaoDescSimplificado;
   
   FUNCTION FObterInfoAdesaoDescSimp RETURN tblAdesaoDescSimplificado IS
      tblInfo tblAdesaoDescSimplificado;
   BEGIN
      
      --CIDASC
      tblInfo(0).CdAgrupamento := 4;
      tblInfo(0).NuAnoMesAdesao := 202306;
      
      --EPAGRI
      tblInfo(1).CdAgrupamento := 5;
      tblInfo(1).NuAnoMesAdesao := 202306;
      
      --PGTC
      tblInfo(2).CdAgrupamento := 133;
      tblInfo(2).NuAnoMesAdesao := 202306;
      
      --DPSC
      tblInfo(3).CdAgrupamento := 176;
      tblInfo(3).NuAnoMesAdesao := 202403;
      
      -- AGPE
      tblInfo(4).CdAgrupamento := 1;
      tblInfo(4).NuAnoMesAdesao := 202404;
      
      RETURN tblInfo;
   END;
   
BEGIN
   
   tblInfo := FObterInfoAdesaoDescSimp();
   
   FOR i IN tblInfo.FIRST .. tblInfo.LAST LOOP
      IF tblInfo(i).CdAgrupamento = pCdAgrupamento AND tblInfo(i)
         .NuAnoMesAdesao <= pNuAnoMesFolha THEN
         vUtiliza := TRUE;
      END IF;
   END LOOP;
   
   RETURN vUtiliza;
END;


 FUNCTION  FPossuiDisposicaoNoOrgao (pCdvinculo IN INTEGER,
                                     pcdOrgao   IN INTEGER,
                                     pDtInicio  IN DATE,
                                     pDtFim     IN DATE) RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
    
 
    SELECT 1
      INTO vcont
      FROM ECadHistCargoEfetivo HCE
     WHERE HCE.CdVinculo = pCdVinculo
       AND HCE.CdOrgaoExercicio = pCdOrgao
       AND HCE.CdRelacaoTrabalho = 10 
       AND HCE.DtInicio <= pDtFim 
       AND (HCE.Dtfim >= pDtInicio OR HCE.DtFim IS NULL)
       AND HCE.FlAnulado = PKGPAG_TIPO.cnN;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

 
  FUNCTION fpossuidisposicaooutroorgao(pcdvinculo IN INTEGER,
                                       pDtInicio  IN DATE) RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vcont
      FROM emovdisposicaoservidor hce
     WHERE HCE.CdVinculo = pCdVinculo
       AND HCE.DTDISPOSICAO > pDtInicio
       AND to_char(hce.Dtdisposicao, 'mmyyyy') =
           to_char(pDtInicio, 'mmyyyy')
       AND HCE.FlAnulado = PKGPAG_TIPO.cnN
       AND hce.cdorgaoexterno <> pkgpag_var.vgFolha.CdOrgao
       AND hce.flpagamento <> 'O'
       AND not exists (select 1
              from ecadorgaoexterno ox
             where ox.cdorgaoexterno = hce.cdorgaoexterno)
       AND ROWNUM < 2;

    IF vcont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION fdisposicaofinalizames(pcdvinculo IN INTEGER,
                                  pdtinicio  OUT DATE,
                                  pdtfim     out DATE) RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    SELECT Case
             when hce.dtinicio < pkgpag_var.vgfolha.dtiniciomes then
              pkgpag_var.vgfolha.dtiniciomes
             else
              hce.dtinicio
           end,
           hce.dtfim,
           1

      INTO pdtinicio, pdtfim, vcont
      FROM ecadhistcargoefetivo hce
     WHERE HCE.CdVinculo = pCdVinculo
       AND HCE.CdRelacaotrabalho = PKGPAG_TIPO.cnRelTrabDisposicao
       AND HCE.DtFim < PKGPAG_VAR.VGFOLHA.DTFIMMES
       AND to_char(HCE.DtFim, 'mmyyyy') =
           to_char(PKGPAG_VAR.VGFOLHA.DTFIMMES, 'mmyyyy')
       AND HCE.FlAnulado = PKGPAG_TIPO.cnN
       AND exists
       (select 1
          from ecadhistcargoefetivo cef
         where cef.cdvinculo = pcdvinculo
           and cef.flprincipal = pkgpag_tipo.cnS
           and (cef.dtfim is null or
                cef.dtfim > pkgpag_var.vgfolha.dtiniciomes)
           and cef.cdorgaoexercicio = pkgpag_var.vgfolha.cdorgao)
       AND ROWNUM < 2;

    IF vcont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION fbuscacarreira(pcdestruturacarreira     IN INTEGER,
                          pcdestruturacarreiraproc IN INTEGER) RETURN BOOLEAN IS

    vcdcarreira INTEGER;

  BEGIN
 
    vcdcarreira := fexistecarreira(pcdestruturacarreira);

    WHILE vcdcarreira IS NOT NULL LOOP

      IF vCdCarreira = pCdEstruturaCarreiraProc THEN
        -- Encontrou

        RETURN TRUE;

      END IF;

      vcdcarreira := fproxcarreira(vcdcarreira);

    END LOOP;

    -- Nao encontrou

    RETURN FALSE;

  END;

  PROCEDURE parredondainicializa(pvltotaldias IN NUMBER DEFAULT 30) IS

  BEGIN
 
    vgvlsomadias         := 0;
    vgvlsomaremunpaga    := 0.0;
    vgvlremuneracao      := 0.0;
    vgnutotaldias        := pvltotaldias;
    vgflaplicarvinculado := TRUE;

  END;

  function FConsultarDescEstrutura(pCdEstruturaCarreira in number,
                                   pultimonivel         in integer default 1)

   return string is

    strDescricao          varchar(4000);
    v_CdEstruturaCarreira number;
    v_DeItemCarreira      varchar(200);

  begin
 
    --// Inicia com a estrutura recebida
    v_CdEstruturaCarreira := pCdEstruturaCarreira;

    While (v_CdEstruturaCarreira is not null) loop
      --// Obter nome da estrutura

      Select i.deitemcarreira, e.cdestruturacarreirapai
        Into v_DeItemCarreira, v_CdEstruturaCarreira
        From ECadEstruturaCarreira e
       Inner Join ECadItemCarreira i
          on (e.cditemcarreira = i.cditemcarreira)
       Where e.cdestruturacarreira = v_CdEstruturaCarreira;

      if pultimonivel <> 1 and v_DeItemCarreira is not null then
        strDescricao := v_DeItemCarreira;
        return(strDescricao);
      else
        strDescricao := v_DeItemCarreira || '\' || strDescricao;
      end if;

    End Loop;

    return(strDescricao);

  end FConsultarDescEstrutura;

  --
  -- TRIBUTACAO PREVIDENCIARIA SOBRE CARGO COMISSIONADO E FUNCAO GRATIFICADA (IPREV) - OPCIONAL
  -- 8623/2016 - TRIBUTACAO PREVIDENCIARIA SOBRE CARGO COMISSIONADO E FUNCAO GRATIFICADA (IPREV)
  --
  FUNCTION FPossuiIprevCCO(pCdVinculo IN INTEGER)

   RETURN BOOLEAN IS

    vCont NUMERIC := 0;

  BEGIN
 
    PKGPAG_VAR.bPossuiIprevCCO := FALSE;

    SELECT 1
      INTO vCont
      FROM EPAGHISTINCIDEIPREVRUBCCO ICCO
     WHERE ICCO.Cdvinculo = pCdVinculo
       AND ICCO.DTINICIODIREITO <= PKGPAG_VAR.vgFolha.DtFimMes
       AND (ICCO.Dtfimdireito IS NULL OR
           ICCO.Dtfimdireito >= PKGPAG_VAR.vgFolha.DtInicioMes)
       AND ICCO.FLANULADO = 'N';

    IF vCont = 1 THEN
      RETURN TRUE;

    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END;

  FUNCTION FArredondaVinculado RETURN BOOLEAN IS

  BEGIN
 
    RETURN vgflaplicarvinculado;
  END;

  FUNCTION farredondaverifica(pvltotal     IN NUMBER,
                              pvlparcela   IN NUMBER,
                              pvlvinculado IN NUMBER DEFAULT 0,
                              pQtDias      IN NUMBER) RETURN NUMBER IS

  BEGIN
 
    IF vgvlremuneracao = 0.0 THEN

      vgvlremuneracao := pvltotal;

    ELSE

      IF vgvlremuneracao <> pvltotal THEN

        vgvlremuneracao := NULL;

      END IF;

    END IF;

    IF pvlvinculado <> pvlparcela THEN
      vgflaplicarvinculado := FALSE;
    END IF;

    vgvlsomaremunpaga := vgvlsomaremunpaga + pvlparcela;

    vgvlsomadias := vgvlsomadias + pqtdias;

    IF vgvlremuneracao IS NOT NULL AND vgvlsomadias >= vgnutotaldias THEN

      vgvlsomaremunpaga := vgvlremuneracao - vgvlsomaremunpaga;

      vgvlremuneracao := NULL;

      IF vgvlsomaremunpaga >= 1.00 THEN

        pkgpag_geral.pinserelog(pkgpag_var.blog,
                                pkgpag_var.vcdhistparamcalc,
                                pkgpag_var.vcdpessoa,
                                'Diferen?a de arredondamento de rubrica muito grande: ' ||
                                vgVlSomaRemunPaga || ' para um total de ' ||
                                pVlTotal,
                                PKGPAG_VAR.vgCdVinculo);
      END IF;

      RETURN vgvlsomaremunpaga;

    ELSE

      RETURN 0.0;

    END IF;

  END;

  FUNCTION fvisaocalculo(pcdtipocalculo       IN INTEGER,
                         pFlCalculoDefinitivo IN CHAR) RETURN CHAR IS

  BEGIN
 
    RETURN CASE WHEN pFlCalculoDefinitivo = 'S' THEN 'S' WHEN pCdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal THEN 'N' WHEN pCdTipoCalculo = PKGPAG_TIPO.cnTpCalculoPrimeiro THEN 'N' WHEN pCdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSegundo THEN 'N' WHEN pCdTipoCalculo = PKGPAG_TIPO.cnTpCalculoPrevia THEN 'N' WHEN pCdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl THEN 'N' ELSE 'S' END;
  END;

  FUNCTION fcodigofolhanormalvinc(pcdvinculo IN INTEGER,
                                  pfolha     IN pkgpag_tipo.rfolha)

   RETURN INTEGER IS

    vcdfolhanormal INTEGER;

  BEGIN
 
    BEGIN

      SELECT hrv.cdfolhapagamento
        INTO vcdfolhanormal
        FROM epaghistoricorubricavinculo hrv
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamentoNormal
         AND ROWNUM < 2;

    EXCEPTION

      WHEN no_data_found THEN

        BEGIN

          SELECT fp.cdfolhapagamento
            INTO vcdfolhanormal
            FROM epagfolhapagamento fp
           INNER JOIN epaghistoricorubricavinculo hrv
              ON hrv.cdfolhapagamento = fp.cdfolhapagamento
           WHERE HRV.CdVinculo = pCdVinculo
             AND FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal
             AND FP.NuAnoReferencia = pFolha.NuAnoReferencia
             AND FP.NuMesReferencia = pFolha.NuMesReferencia
             AND FP.CdTipoFolhaPagamento = pFolha.CdTipoFolhaPagamento
             AND ROWNUM < 2;

        EXCEPTION

          WHEN no_data_found THEN

            vcdfolhanormal := 0;

        END;

    END;

    RETURN vcdfolhanormal;

  END;

  --Armazena dados CTISP
  FUNCTION fArmazenaCTISP(pcdvinculo INTEGER)

   RETURN pkgpag_tipo.rCTISP IS

    vCTISP pkgpag_tipo.rCTISP;

  BEGIN
 
    SELECT OC.CDORGAO,
           OC.CDORGAOEXTERNO,
           OC.DTINICIO,
           OC.DTFIM,
           OC.CDLOCALEXTERNOCTISP
      INTO vCTISP.vCdOrgaoInterno,
           vCTISP.vCdOrgaoExterno,
           vCTISP.vDtInicio,
           vCTISP.vDtFim,
           vCTISP.vCdLocalExternoCTISP
      FROM ECADLOCALEXTERNOCTISP OC
     WHERE OC.CDVINCULO = pcdvinculo
       AND OC.FLANULADO = 'N'
       AND OC.DTINICIO <= PKGPAG_VAR.vgFolha.DtCalculo
       AND (OC.Dtfim IS NULL OR OC.Dtfim >= PKGPAG_VAR.vgFolha.DtCalculo);

    RETURN vCTISP;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END;

  PROCEDURE parmazenacho IS

  BEGIN
 
    CASE pkgpag_var.vgrelvincprincipal.tipo

      WHEN 1 THEN
        -- CEF

        IF pkgpag_var.vgcef.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

            IF PKGPAG_VAR.vgCEF(i)
             .CdHistRelVinc = PKGPAG_VAR.vgRelVincPrincipal.CdHIst THEN

              pkgpag_var.vgrelvincprincipal.nucho        := pkgpag_var.vgvalorfixocef.nucargahoraria;
              PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao := PKGPAG_VAR.vgCEF(i).NuCargaHoraria;

            END IF;

          END LOOP;

        END IF;

      WHEN 2 THEN
        -- CCO

        IF pkgpag_var.vgcco.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST LOOP

            IF PKGPAG_VAR.vgCCO(i)
             .CdHistCargoCom = PKGPAG_VAR.vgRelVincPrincipal.CdHist THEN

              PKGPAG_VAR.vgRelVincPrincipal.NuCHO        := PKGPAG_VAR.vgCCO(i).NuCargaHorariaPadrao;
              PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao := PKGPAG_VAR.vgCCO(i).NuCargaHorariaPadrao;

            END IF;

          END LOOP;

        END IF;

      WHEN 4 THEN
        -- APO

        IF pkgpag_var.vgapo.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST LOOP

            pkgpag_var.vgrelvincprincipal.nucho        := pkgpag_var.vgvalorfixocef.nucargahoraria;
            PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao := PKGPAG_VAR.vgAPO(i).NuCargaHoraria;

          END LOOP;

        END IF;

      ELSE

        NULL;

    END CASE;

  END;

  PROCEDURE pArmazenaCargaHoraria(pCdHist               IN NUMBER,
                                  pCdRelacao            IN NUMBER,
                                  pNuCargaHorariaPadrao IN NUMBER DEFAULT NULL) IS

    i                    integer;
    v1                   integer := 1;
    v2                   integer := 2;
    v3                   integer := 3;
    v4                   integer := 4;
    v30                  integer := 30;
    vNuCargaHorariaTotal NUMBER(7, 4);

  BEGIN
 
    pkgpag_var.vgNuDiasCargaHorariaZero := 0;

    vNuCargaHorariaTotal := 0;

    i := nvl(pkgpag_var.vgCargaHoraria.Last, 0);

    FOR rec IN (SELECT Cho.Nucargahoraria, Cho.Dtinicial, Cho.Dtfim
                  FROM ECadHistCargaHoraria CHO
                 WHERE ((pCdRelacao = v1 AND
                       pCdHist = Cho.Cdhistcargoefetivo) OR
                       (pCdRelacao = v2 AND pCdHist = Cho.Cdhistcargocom) OR
                       (pCdRelacao = v3 AND
                       pCdHist = Cho.Cdhistfuncaochefia) OR
                       (pCdRelacao = v4 AND
                       pCdHist = Cho.CdHistCargoEfetivo))
                   AND CHO.DtInicial <= PKGPAG_VAR.vgFolha.DtFimMes
                   AND (CHO.DtFim >= PKGPAG_VAR.vgFolha.DtInicioMes OR
                       CHO.DtFim IS NULL)
                   AND CHO.Flanulado = 'N'
                 ORDER BY dtinicial) LOOP

      i := i + 1;

      pkgpag_var.vgCargaHoraria(i).NuCargaHoraria := rec.nucargahoraria;

      vNuCargaHorariaTotal := nvl(vNuCargaHorariaTotal, 0) +
                              nvl(rec.nucargahoraria, 0);

      IF rec.DtInicial < PKGPAG_VAR.vgFolha.DtInicioMes

       THEN
        pkgpag_var.vgCargaHoraria(i).DtInicio := PKGPAG_VAR.vgFolha.DtInicioMes;
      ELSE
        pkgpag_var.vgCargaHoraria(i).DtInicio := rec.DtInicial;
      END IF;

      IF rec.DtFim > PKGPAG_VAR.vgFolha.DtFimMes or rec.Dtfim is null THEN
        pkgpag_var.vgCargaHoraria(i).DtFim := PKGPAG_VAR.vgFolha.DtFimMes;
      ELSE
        pkgpag_var.vgCargaHoraria(i).DtFim := rec.DtFim;
      END IF;

      pkgpag_var.vgCargaHoraria(i).NuDiasTrabalhados := pkgpag_var.vgCargaHoraria(i).DtFim - pkgpag_var.vgCargaHoraria(i).DtInicio + v1;

      -- SALVA O NUMERO DE DIAS COM CARGA HORARIA ZERADA
      IF pkgpag_var.vgCargaHoraria(i).NuCargaHoraria = 0 THEN
        pkgpag_var.vgNuDiasCargaHorariaZero := pkgpag_var.vgNuDiasCargaHorariaZero + pkgpag_var.vgCargaHoraria(i).DtFim - pkgpag_var.vgCargaHoraria(i).DtInicio + v1;

        IF pkgpag_var.vgCargaHoraria(i)
         .DtFim = LAST_DAY(PKGPAG_VAR.vgFolha.DtFimMes) THEN

          IF to_number(TO_CHAR(pkgpag_var.vgCargaHoraria(i).DtFim, 'DD')) < v30 THEN
            pkgpag_var.vgNuDiasCargaHorariaZero := pkgpag_var.vgNuDiasCargaHorariaZero + v30 -
                                                   TO_CHAR(pkgpag_var.vgCargaHoraria(i).DtFim,
                                                           'DD');
          ELSIF to_number(TO_CHAR(pkgpag_var.vgCargaHoraria(i).DtFim, 'DD')) > v30 THEN
            pkgpag_var.vgNuDiasCargaHorariaZero := pkgpag_var.vgNuDiasCargaHorariaZero - v1;
          else
            null;
          END IF;
        END IF;

      END IF;

      IF pCdRelacao = 1 THEN
        pkgpag_var.vgCargaHoraria(i).CdHistCargoEfetivo := pCdHist;
      ELSE
        pkgpag_var.vgCargaHoraria(i).CdHistCargoEfetivo := 0;
      END IF;

      pkgpag_var.vgCargaHoraria(i).CdHistCargoEfetivo := pCdHist;
      pkgpag_var.vgCargaHoraria(i).CdTipoRelacao := pCdRelacao;
      pkgpag_var.vgCargaHoraria(i).CdHist := pCdHist;
      pkgpag_var.vgCargaHoraria(i).NuCargaHorariaPadrao := Case
                                                             When pCdRelacao in
                                                                  (v1, v4) Then
                                                              NVL(pkgpag_var.vgValorFixoCEF.NuCargaHoraria,
                                                                  Rec.NuCargaHoraria)
                                                             When pCdRelacao in
                                                                  (v2, v3) Then
                                                              NVL(pNuCargaHorariaPadrao,
                                                                  0)
                                                           End;

    END LOOP;

    pkgpag_var.vgCargaHoraria(i).NuCargaHorariaTotal := nvl(vNuCargaHorariaTotal,
                                                            0);

  END;

  FUNCTION fvinculocomproventos(pcdvinculo        IN INTEGER,
                                pCdFolhaPagamento IN INTEGER) RETURN BOOLEAN IS

    vpossuiproventos INTEGER := 0;

  BEGIN
 
    SELECT 1
      INTO vpossuiproventos
      FROM epaghistoricorubricavinculo hrv
     INNER JOIN epagrubricaagrupamento ra
        ON hrv.cdrubricaagrupamento = ra.cdrubricaagrupamento
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo
       AND R.CdTipoRubrica IN (1, 2, 4, 10, 12)
       AND HRV.VlPagamento > 0
       AND ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION ffolhaemexecucao(pcdfolhapagamento IN INTEGER,
                            pCdPessoa         IN INTEGER) RETURN BOOLEAN IS

    vcont          INTEGER;
    vcdtipocalculo INTEGER;
    vcdtipofolha   INTEGER;
    vdtfimmes      DATE;

  BEGIN
 
    --Seleciona o tipo calculo, tipo folha e a referencia
    SELECT LAST_DAY(TO_DATE(TO_CHAR(p.NuAnoReferencia * 100 +
                                    p.NuMesReferencia),
                            'YYYYMM')),
           p.cdtipocalculo,
           tf.cdtipofolha
      INTO vdtfimmes, vcdtipocalculo, vcdtipofolha
      FROM epagfolhapagamento p
     INNER JOIN epagtipofolhapagamento tf
        ON p.cdtipofolhapagamento = tf.cdtipofolhapagamento
     WHERE cdfolhapagamento = pcdfolhapagamento;

    SELECT COUNT(*)
      INTO vcont
      FROM epaghistoricoparamcalculo pc
     INNER JOIN epaghistoricoparamcalculoorgao hpc
        ON pc.cdhistoricoparamcalculo = hpc.cdhistoricoparamcalculo
     INNER JOIN epagfolhapagamento fp
        ON PC.CdTipoCalculo = FP.CdTipoCalculo
       AND PC.Cdtipofolhapagamento = FP.Cdtipofolhapagamento
       AND PC.NuAnoCompetencia = FP.NuAnoReferencia
       AND PC.NuMesCompetencia = FP.NuMesReferencia
     INNER JOIN epagtipofolhapagamento tfp
        ON tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
     INNER JOIN eadmtarefa t
        ON pc.cdtarefa = t.cdtarefa
     INNER JOIN (SELECT V.CdPessoa, CEF.CdOrgaoExercicio
                   FROM ecadvinculo v
                  INNER JOIN ecadhistcargoefetivo cef
                     ON v.cdvinculo = cef.cdvinculo
                  WHERE (CEF.DtInicio < vDtFimMes AND
                        (CEF.DtFim >= vDtFimMes OR CEF.DtFim IS NULL))
                     OR v.cdsituacaoprevidenciaria = 3 -- insituidor pens?o
                 UNION
                 SELECT V.CdPessoa, CCO.CdOrgaoExercicio
                   FROM ecadvinculo v
                  INNER JOIN ecadhistcargocom cco
                     ON v.cdvinculo = cco.cdvinculo
                  WHERE CCO.DtInicio < vDtFimMes
                    AND (CCO.DtFim >= vDtFimMes OR CCO.DtFim IS NULL)
                 UNION
                 SELECT V.CdPessoa, FUC.CdOrgaoExercicio
                   FROM ecadvinculo v
                  INNER JOIN ecadhistfuncaochefia fuc
                     ON v.cdvinculo = fuc.cdvinculo
                  WHERE FUC.DtInicio < vDtFimMes
                    AND (FUC.DtFim >= vDtFimMes OR FUC.DtFim IS NULL)
                 UNION
                 SELECT V.CdPessoa, V.CdOrgao
                   FROM ecadvinculo v
                  INNER JOIN epvdconcessaoaposentadoria ca
                     ON ca.cdvinculo = v.cdvinculo
                  WHERE CA.DtInicioAposentadoria < vdtFimMes
                    AND (CA.DtFimAposentadoria >= vdtFimMes OR
                        CA.DtFimAposentadoria IS NULL)
                 UNION
                 SELECT V.CdPessoa, V.CdOrgao
                   FROM ecadvinculo v
                  INNER JOIN ecadhistestagio bol
                     ON bol.cdvinculoestagio = v.cdvinculo
                  WHERE BOL.DtInicio < vDtFimMes
                    AND (BOL.DtFim >= vDtFimMes OR BOL.DtFim IS NULL)
                 UNION
                 SELECT V.CdPessoa, V.CdOrgao
                   FROM ecadvinculo v
                  INNER JOIN epvdhistpensaoprevidenciaria pp
                     ON pp.cdvinculo = v.cdvinculo
                  WHERE PP.DtInicio < vDtFimMes
                    AND (PP.DtFim >= vDtFimMes OR PP.DtFim IS NULL)
                 UNION
                 SELECT V.CdPessoa, V.CdOrgao
                   FROM ecadvinculo v
                  INNER JOIN epvdhistpensaonaoprev pnp
                     ON pnp.cdvinculobeneficiario = v.cdvinculo
                  WHERE PNP.DtInicio < vDtFimMes
                    AND (PNP.DtFim >= vDtFimMes OR PNP.DtFim IS NULL)) RV
        ON hpc.cdorgao = rv.cdorgaoexercicio
     WHERE T.CdSituacaoTarefa = 2
       AND RV.CdPessoa = pCdPessoa
       AND TFP.CdTipoFolha = vcdtipofolha
       AND FP.Cdtipocalculo = vcdtipocalculo
       AND FP.CdOrgao = HPC.CdOrgao;

    IF vcont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  END;

  FUNCTION frubricapermitida(pflpagatodasrubricas  IN CHAR,
                             pcdtipofolha          IN INTEGER,
                             pCdRubricaAgrupamento IN INTEGER) RETURN BOOLEAN IS

  BEGIN
 
    IF pFlPagaTodasRubricas = 'N' AND
       pCdTipoFolha in (PKGPAG_TIPO.cnTpFolhaOutras, PKGPAG_TIPO.cnTpFolhaBEP) THEN

      IF pkgpag_var.vgrubpermitidastpfolha.exists(pcdrubricaagrupamento) THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    ELSE

      RETURN TRUE;

    END IF;

  END;

  FUNCTION fpossuiinterrupcaousufruto(pcdperiodoaquisitivoferias IN INTEGER,
                                      pdtiniciomes               IN DATE,
                                      pdtfimmes                  IN DATE)

   RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vcont
      FROM emovferiasfruicaousufruto usu
     WHERE USU.CdPeriodoAquisitivoFerias = pCdPeriodoAquisitivoFerias
       AND USU.InSituacao IN (7, 8)
       AND USU.FlAnulado = PKGPAG_TIPO.cnN
       AND USU.DtInicial < pDtInicioMes
       AND ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION fsituacaoprevvigente(pcdvinculo   IN INTEGER,
                                pdtiniciomes IN DATE,
                                pDtFimMes    IN DATE) RETURN INTEGER IS

    vcdsitprev INTEGER;

  BEGIN
 
    SELECT cdsituacaoprevidenciaria
      INTO vcdsitprev
      FROM (SELECT hspv.cdsituacaoprevidenciaria
              FROM ecadhistsitprevvinculo hspv
             WHERE HSPV.CdVinculo = pCdVinculo
               AND HSPV.DtInicio <= pDtFimMes
               AND NVL(HSPV.DtFim, PKGPAG_TIPO.cnDtMax) >= pDtInicioMes
             ORDER BY hspv.dtinicio)
     WHERE rownum < 2;

    RETURN vcdsitprev;

  EXCEPTION

    WHEN no_data_found THEN

      BEGIN

        SELECT cdsituacaoprevidenciaria
          INTO vcdsitprev
          FROM (SELECT hspv.cdsituacaoprevidenciaria
                  FROM ecadhistsitprevvinculo hspv
                 WHERE hspv.cdvinculo = pcdvinculo
                 ORDER BY hspv.dtinicio DESC)
         WHERE rownum < 2;

        RETURN vcdsitprev;

      EXCEPTION

        WHEN no_data_found THEN

          RETURN 0;

      END;

  END;

  FUNCTION fretornavalornivrefgeral(pcdhisttabgeral IN INTEGER,
                                    pnunivel        IN VARCHAR2,
                                    pnureferencia   IN VARCHAR2)

   RETURN NUMBER IS

    vvlfixo NUMBER(13, 2);

  BEGIN
 
    SELECT v.vlfixo
      INTO vvlfixo
      FROM epagvalorespeccefagrup v
     WHERE V.CdHistValorGeralCEFAgrup = pCdHistTabGeral
       AND V.NuNivel = pNuNivel
       AND V.NuReferencia = pNuReferencia;

    RETURN vvlfixo;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fpagamentobloqueado(pcdpessoa        IN INTEGER,
                               pcdvinculo       IN INTEGER,
                               pnuanoreferencia IN INTEGER,
                               pnumesreferencia IN INTEGER,
                               pDtNascimento    IN DATE) RETURN CHAR IS

    vcont INTEGER;

  BEGIN
 
    IF pkgpag_var.vgeventorecadastramento.flpagamentobloqueado = 'S' THEN

      BEGIN

        IF pkgpag_var.vgFolha.CdOrgao = 33 THEN

          BEGIN

            -- Nao bloqueia se o mes/ano corrente (mes/ano da folha) for menor
            -- que o mes de aniversario do ano seguinte ao inicio da pensao.
            -- Ex: Se o mes de aniversaria for mes 03, e inicio da pensao for 2017
            --     Entao nao bloqueia antes do mes/ano 03/2018.
            select 1
              into vcont
              from epvdhistpensaoprevidenciaria p
             where p.cdvinculo = pCdVinculo
               and p.flanulado = 'N'
               and to_date(to_char(pNuAnoReferencia * 100 +
                                   pNuMesReferencia) || '01',
                           'YYYYMMDD') <=
                   ADD_MONTHS(to_date(to_char(p.dtinicio, 'YYYY') ||
                                      to_char(pDtNascimento, 'MM') || '01',
                                      'YYYYMMDD'),
                              12)
               and rownum < 2;

            return 'N';

          EXCEPTION

            WHEN no_data_found THEN

              BEGIN

                -- Nao bloqueia se pensao encerrou antes do inicio do mes corrente
                select 1
                  into vcont
                  from epvdhistpensaoprevidenciaria p
                 where p.cdvinculo = pCdVinculo
                   and p.flanulado = 'N'
                   and p.dtfim is not null
                   and p.dtfim < to_date(to_char(pNuAnoReferencia * 100 +
                                                 pNuMesReferencia) || '01',
                                         'YYYYMMDD')
                   and rownum < 2;

                return 'N';

              END;

          END;

        ELSE

          -- Caso a aposentadoria foi concedida no ano corrente, nao bloqueia
          SELECT 1
            INTO vcont
            FROM epvdconcessaoaposentadoria ca
           WHERE CA.CdVinculo = pCdVinculo
             AND TO_CHAR(CA.DtInicioAposentadoria, 'YYYY') =
                 to_char(pNuAnoReferencia)
             AND CA.FlAnulado = 'N'
             AND CA.FlAtiva = 'S'
             AND CA.DtFimAposentadoria IS NULL
             AND NOT EXISTS (SELECT 1
                    FROM epvdconcessaoaposentadoria ca1
                   WHERE CA1.CdVinculo = pCdVinculo
                     AND (CA1.DtFimAposentadoria + 1) =
                         CA.DtInicioAposentadoria
                     AND CA1.FlAnulado = 'N')
             AND ROWNUM < 2;

          RETURN 'N';

        END IF;

      EXCEPTION

        WHEN no_data_found THEN

          BEGIN
            -- Se houve recadastramento no ano corrente, nao bloqueia
            SELECT 1
              INTO vcont
              FROM epvdhistrecadastramento r
             WHERE R.CdPessoa = pCdPessoa
               AND R.NuAnoRecadastramento = pNuAnoReferencia
               AND R.FlAnulado = 'N'
               AND ROWNUM < 2;

            RETURN 'N';

          EXCEPTION

            WHEN no_data_found THEN

              --Retorna a data de nascimento
              IF to_char(pdtnascimento, 'DDMM') = '2902' THEN
                DtReferencia := to_date('2802' || to_char(pNuAnoReferencia),
                                        'DDMMYYYY');
              ELSE
                DtReferencia := to_date(to_char(pDtNascimento, 'DDMM') ||
                                        to_char(pNuAnoReferencia),
                                        'DDMMYYYY');
              END IF;

              -- 7934/2015 - FOLHA - NAO OCORRA O BLOQUEIO PARA ANIVERSARIANTES DE 09/2015 INATIVOS
              -- Solicito que nao sejam bloqueados os proventos do mes de dezembro/2015 dos servidores inativos,
              -- aniversariantes de setembro/2015, por falta de recadastramento.
              IF pnumesreferencia = 12 AND
                 TO_CHAR(add_months(dtreferencia, 3), 'YYYYMM') =
                 (LPAD(to_char(pNuAnoReferencia), 4, '0') || 12) THEN
                RETURN 'N';
              END IF;

              -- Aplica o numero de dias de bloqueio
              IF (LPAD(to_char(pNuAnoReferencia), 4, '0') ||
                 LPAD(to_char(pNuMesReferencia), 2, '0')) >= '201110' THEN
                DtReferencia := DtReferencia + NVL(PKGPAG_VAR.vgEventoRecadastramento.NuDiasBloqueioPagamento,
                                                   0);
              ELSE
                dtreferencia := add_months(dtreferencia, 3);
              END IF;

              -- Se a data referencia for menor que a data do calculo, bloqueia o pagamento
              IF TO_CHAR(DtReferencia, 'YYYYMM') <
                 (LPAD(to_char(pNuAnoReferencia), 4, '0') ||
                  LPAD(to_char(pNuMesReferencia), 2, '0')) THEN
                RETURN 'S';

              ELSE
                BEGIN

                  SELECT 1
                    INTO vcont
                    FROM epvdhistrecadastramento r
                   WHERE R.CdPessoa = pCdPessoa
                     AND R.NuAnoRecadastramento = (pNuAnoReferencia - 1)
                     AND R.FlAnulado = 'N'
                     AND ROWNUM < 2;

                  RETURN 'N';

                EXCEPTION

                  WHEN no_data_found THEN

                    BEGIN

                      SELECT 1
                        INTO vcont
                        FROM epvdconcessaoaposentadoria ca
                       WHERE CA.CdVinculo = pCdVinculo
                         AND TO_CHAR(CA.DtInicioAposentadoria, 'YYYY') =
                             to_char(pNuAnoReferencia - 1)
                         AND CA.FlAnulado = 'N'
                         AND CA.FlAtiva = 'S'
                         AND CA.DtFimAposentadoria IS NULL
                         AND NOT EXISTS
                       (SELECT 1
                                FROM epvdconcessaoaposentadoria ca1
                               WHERE CA1.CdVinculo = pCdVinculo
                                 AND (CA1.DtFimAposentadoria + 1) =
                                     CA.DtInicioAposentadoria
                                 AND CA1.FlAnulado = 'N')
                         AND ROWNUM < 2;

                      RETURN 'N';

                    EXCEPTION

                      WHEN no_data_found THEN

                        -- VERIFICA A CARENCIA A PARTIR DO ANIVERSARIO DO ANO ANTERIOR - ROGERIO EM 11/01/2012

                        DtReferencia := CASE
                                          WHEN to_char(pDtNascimento, 'DDMM') = '2902' THEN
                                           to_date('28' || to_char(pDtNascimento, 'MM') ||
                                                   to_char(pNuAnoReferencia - 1),
                                                   'DDMMYYYY')
                                          ELSE
                                           to_date(to_char(pDtNascimento, 'DDMM') ||
                                                   to_char(pNuAnoReferencia - 1),
                                                   'DDMMYYYY')
                                        END;

                        DtReferencia := DtReferencia +
                                        NVL(PKGPAG_VAR.vgEventoRecadastramento.NuDiasBloqueioPagamento,
                                            0);

                        IF TO_CHAR(DtReferencia, 'YYYYMM') <
                           (LPAD(to_char(pNuAnoReferencia), 4, '0') ||
                            LPAD(to_char(pNuMesReferencia), 2, '0')) THEN

                          RETURN 'S';

                        ELSE

                          RETURN 'N';

                        END IF;

                    END;

                END;

              END IF;

          END;

      END;

    ELSE

      RETURN 'N';

    END IF;

  END;

  PROCEDURE ptratabloqueiocredito IS
    vFlBloqueiaNaoRecadastrado     CHAR := pkgpag_var.vgparampagamento.flbloqueianaorecadastrado;
    vCdSituacaoPrevidenciaria      INTEGER := pkgpag_var.vgvinculo.cdsituacaoprevidenciaria;
    vCdVinculo                     INTEGER := pkgpag_var.vgvinculo.cdvinculo;
    vCdPessoa                      INTEGER := pkgpag_var.vgvinculo.cdpessoa;
    vDtNascimento                  DATE := pkgpag_var.vgvinculo.dtnascimento;
    vCdOrgao                       INTEGER := pkgpag_var.vgFolha.CdOrgao;
    vNuAnoReferenciaFolha          INTEGER := pkgpag_var.vgfolha.nuanoreferencia;
    vNuMesReferenciaFolha          INTEGER := pkgpag_var.vgfolha.numesreferencia;
    vCdTipoFolha                   INTEGER := pkgpag_var.vgFolha.CdTipoFolha;
    vCdTipoCalculo                 INTEGER := pkgpag_var.vgFolha.CdTipoCalculo;
    vDataInicioMes                 DATE := pkgpag_var.vgfolha.dtiniciomes;
    vCdMotivoAfastamentoTemporario INTEGER := pkgpag_var.vgParamPagamento.CdMotivoAfastTemporario;
    vInserirLog                    BOOLEAN := pkgpag_var.blog;
    vCdHistoricoParamCalculo       INTEGER := pkgpag_var.vcdhistparamcalc;
    vFlpagamentobloqueado          CHAR := 'N';
    vPossuiAfastamentoTempAnterior BOOLEAN;
    vCdTipoPensaoNaoPrevidenciaria INTEGER;
  BEGIN
 
    IF vFlBloqueiaNaoRecadastrado = 'S' AND
       vCdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaNormal,
                        PKGPAG_TIPO.cnTpFolha13,
                        pkgpag_tipo.cntpfolhaadiant13,
                        PKGPAG_TIPO.cnTpFolhaFunebre,
                        PKGPAG_TIPO.cnTpFolhaServAfast) AND
       vCdTipoCalculo NOT IN (PKGPAG_TIPO.cnTpCalculoRecalculoMes) THEN

      -- afastamento temporario por motivo de bloqueio de pagamento em meses anteriores
      vPossuiAfastamentoTempAnterior := pkgpag_geral.FPossuiAfastTempAnteriorDtRef(pCdVinculo         => vCdVinculo,
                                                                                   pcdmotivoafasttemp => vCdMotivoAfastamentoTemporario,
                                                                                   pDataReferencia    => vDataInicioMes);

      ------------------------------------------------------------------------
      -- Inativos e Pensoes previdenciarias
      ------------------------------------------------------------------------
      IF vCdSituacaoPrevidenciaria IN (2, 9) AND
         NOT vPossuiAfastamentoTempAnterior THEN
        vFlpagamentobloqueado := pkgpag_geral.FTratarBloqPgtoInatEPensoesP(pCdVinculo                     => vCdVinculo,
                                                                           pCdPessoa                      => vCdPessoa,
                                                                           pDataNascimento                => vDtNascimento,
                                                                           pCdOrgao                       => vCdOrgao,
                                                                           pCdMotivoAfastamentoTemporario => vCdMotivoAfastamentoTemporario,
                                                                           pNuAnoReferencia               => vNuAnoReferenciaFolha,
                                                                           pNuMesReferencia               => vNuMesReferenciaFolha,
                                                                           pCdTipoFolha                   => vCdTipoFolha,
                                                                           pCdTipoCalculo                 => vCdTipoCalculo,
                                                                           pDataInicioMes                 => vDataInicioMes,
                                                                           pInserirLog                    => vInserirLog,
                                                                           pCdHistoricoParamCalculo       => vCdHistoricoParamCalculo);

      ELSIF vCdSituacaoPrevidenciaria = 9 AND
            vPossuiAfastamentoTempAnterior THEN
        vFlpagamentobloqueado := 'A'; -- Afastado

        ------------------------------------------------------------------------
        -- Pensoes nao previdenciarias
        ------------------------------------------------------------------------
      ELSIF pkgpag_var.vgpensaonaoprev.count > 0 THEN
        vCdTipoPensaoNaoPrevidenciaria := PKGPAG_VAR.vgPensaoNaoPrev(PKGPAG_VAR.vgPensaoNaoPrev.FIRST).CdTipoPensaoNaoPrev;
        vFlpagamentobloqueado          := pkgpag_geral.FTratarBloqPgtoPensoesNaoPrev(pCdVinculo               => vCdVinculo,
                                                                                     pCdPessoa                => vCdPessoa,
                                                                                     pNuAnoReferencia         => vNuAnoReferenciaFolha,
                                                                                     pNuMesReferencia         => vNuMesReferenciaFolha,
                                                                                     pCdTipoPensaoNaoPrev     => vCdTipoPensaoNaoPrevidenciaria,
                                                                                     pInserirLog              => vInserirLog,
                                                                                     pCdHistoricoParamCalculo => vCdHistoricoParamCalculo);

      ELSE
        NULL;

      END IF;

    END IF;

    IF FAnoMesRecadPensLiberado(vNuAnoReferenciaFolha,
                                vNuMesReferenciaFolha) AND
       vFlpagamentobloqueado = 'S' THEN
      vFlpagamentobloqueado := 'N';
    END IF;

    pkgpag_var.vgvinculo.flpagamentobloqueado := vFlpagamentobloqueado;

    -- SIG-6510 Regra para atualizacao da capa do contracheque
    if vCdOrgao = 14 then

      begin

        SELECT 'S'
          into pkgpag_var.vgvinculo.flpagamentobloqueado
          from ecadhistregraempenhovinc hre
         where hre.cdvinculo = vCdVinculo
           and hre.flanulado = pkgpag_tipo.cnN
           and hre.cdregraempenho = 2
           and hre.dtinicio <=
               last_day(to_date(vNuAnoReferenciaFolha ||
                                lpad(vNuMesReferenciaFolha, 2, 0),
                                'yyyymm'))
           and (hre.dtfim IS NULL OR
               hre.dtfim >= to_date(vNuAnoReferenciaFolha ||
                                     lpad(vNuMesReferenciaFolha, 2, 0),
                                     'yyyymm'));

      exception
        when others then
          null;
      end;

    end if;

  END;

  FUNCTION fdevepagarcco RETURN BOOLEAN IS

    FUNCTION fefetivonoorgao RETURN BOOLEAN IS

    BEGIN
 
      IF pkgpag_var.vgcef.count > 0 THEN

        FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

          IF PKGPAG_VAR.vgCEF(i)
           .CdRelacaoTrabalho = PKGPAG_TIPO.cnRelTrabEfetivo AND PKGPAG_VAR.vgCEF(i)
             .CdOrgaoExercicio = PKGPAG_VAR.vgFolha.CdOrgao AND
              PKGPAG_VAR.vDtCalculo BETWEEN PKGPAG_VAR.vgCEF(i).DtInicio AND PKGPAG_VAR.vgCEF(i).DtFim THEN

            RETURN TRUE;

          END IF;

        END LOOP;

      END IF;

      RETURN FALSE;

    END;

  BEGIN
 
    IF NOT PKGPAG_VAR.bVinculoComCCO AND PKGPAG_VAR.bTemEfetivoOutroOrgao AND
       NOT FEfetivoNoOrgao THEN

      IF pkgpag_var.bpossuidisposicao THEN

        IF NOT (pkgpag_var.vpagasitdisposicao = 'PAG-ORIGEM-CALCULO-ORIGEM') AND
           NOT (pkgpag_var.vpagasitdisposicao = 'PAG-DEST-CALCULO-DEST') THEN

          RETURN FALSE;

        ELSE

          RETURN TRUE;

        END IF;

      ELSE

        RETURN FALSE;

      END IF;

    ELSE

      RETURN TRUE;

    END IF;

  END;

  FUNCTION fretornaopcaoremuneracaocco(pcdhistcargocom IN INTEGER,
                                       pdtiniciomes    IN DATE,
                                       pdtfimmes       IN DATE)

   RETURN INTEGER IS

    vcdopcaoremuneracao INTEGER;

  BEGIN
 
    SELECT cdopcaoremuneracao
      INTO vcdopcaoremuneracao
      FROM (SELECT hrc.cdopcaoremuneracao
              FROM ecadhistopcaoremuneracaocco hrc
             WHERE HRC.CdHistCargoCom = pCdHistCargoCom
               AND HRC.DtInicioVigencia <= pDtFimMes
               AND (HRC.DtFimVigencia >= pDtInicioMes OR
                   HRC.DtFimVigencia IS NULL)
             ORDER BY hrc.dtiniciovigencia DESC)
     WHERE rownum < 2;

    RETURN vcdopcaoremuneracao;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN NULL;

  END;

  PROCEDURE psetadadosbancarios(pcdvinculo       IN INTEGER,
                                pnuanoreferencia IN INTEGER,
                                pnumesreferencia IN INTEGER,
                                pdtcalculo       IN DATE) IS

  BEGIN
 
    IF TO_CHAR(pNuAnoReferencia || lpad(pNuMesReferencia, 2, '0')) >
       '200908' THEN

      SELECT hdb.dtopcaofgts,
             b.floficial,
             hdb.cdagenciacredito,
             hdb.nucontacredito,
             hdb.nudvcontacredito,
             hdb.cdagenciareceb,
             hdb.nucontareceb,
             hdb.fltipocontacredito,
             a.nuagencia,
             a.nudvagencia,
             b.nubanco
        INTO PKGPAG_VAR.vgDtOpcaoFGTS,
             PKGPAG_VAR.vFlPossuiContaBancoOficial,
             PKGPAG_VAR.vgCdAgenciaCredito,
             PKGPAG_VAR.vgNuContaCredito,
             PKGPAG_VAR.vgNuDvContaCredito,
             PKGPAG_VAR.vgCdAgenciaReceb,
             PKGPAG_VAR.vgNuContaReceb,
             PKGPAG_VAR.vgFlTipoContaCredito,
             PKGPAG_VAR.vgNuAgencia,
             PKGPAG_VAR.vgNuDvAgencia,
             PKGPAG_VAR.vgNuBanco
        FROM ecadhistdadosbancariosvinculo hdb
       INNER JOIN ecadagencia a
          ON hdb.cdagenciacredito = a.cdagencia
       INNER JOIN ecadbanco b
          ON a.cdbanco = b.cdbanco
       WHERE HDB.CdVinculo = pCdVinculo
         AND HDB.flanulado = 'N'
         AND HDB.Dtiniciovigencia =
             (SELECT MAX(HDB1.DtInicioVigencia)
                FROM ecadhistdadosbancariosvinculo hdb1
               WHERE pcdvinculo = hdb1.cdvinculo
                 AND hdb1.flanulado = 'N');

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      pkgpag_var.vgdtopcaofgts := NULL;

      pkgpag_var.vflpossuicontabancooficial := 'N';

  END;

  FUNCTION fpossuidecisaojudicial(pcdvinculo       IN INTEGER,
                                  pnuanoreferencia IN INTEGER,
                                  pnumesreferencia IN INTEGER,
                                  pcdrubrica       IN INTEGER,
                                  pvldecisaojud    OUT NUMBER,
                                  pcdvalorref      OUT INTEGER,
                                  pdtiniciodireito OUT DATE,
                                  pDtInclusao      OUT DATE) RETURN BOOLEAN IS

  BEGIN
 
    SELECT epd.vldeterminado,
           epd.cdvalorreferencia,
           epd.dtiniciodireito,
           epd.dtinclusao
      INTO pVlDecisaoJud, pCdValorRef, pDtInicioDireito, pDtInclusao
      FROM epageventopagagrupdecisao epd
     WHERE EPD.CdVinculo = pCdVinculo
       AND EPD.CdRubricaAgrupamento = pCdRubrica
       AND ((EPD.NuAnoInicioDireito < pNuAnoReferencia OR
           (epd.nuanoiniciodireito = pnuanoreferencia AND
           EPD.NuMesInicioDireito <= pNuMesReferencia)) AND
           (epd.nuanofimdireito > pnuanoreferencia OR
           (epd.nuanofimdireito = pnuanoreferencia AND
           epd.numesfimdireito >= pnumesreferencia) OR
           EPD.NuAnoFimDireito IS NULL))
       AND EPD.FlAnulado = 'N'
       AND ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      pvldecisaojud := NULL;

      pcdvalorref := NULL;

      RETURN FALSE;

  END;

  FUNCTION fpercentreducaosalario(pcdvinculo IN INTEGER,
                                  pdtinicio  IN DATE,
                                  pdtfim     IN DATE,
                                  pdtcalculo IN DATE)

   RETURN NUMBER IS

    vvlreducaoremuneracao NUMBER(7, 4);
    vlreducaoremunant     NUMBER(7, 4);
    vnudiasfimfaixa       INTEGER;
    vnudiasiniciofaixa    INTEGER;
    vvlreducao            NUMBER(7, 4);

    vcdhistmotivoafasttemp INTEGER;
    vnudias                INTEGER;
    vdtinicio              DATE;
    vdtfim                 DATE;

  BEGIN
 
    vvlreducao := 0;

    SELECT MAX(cdhistmotivoafasttemp) AS cdhistmotivoafasttemp,
           MAX(dtfim) - MIN(dtinicio) + 1 AS nudias,
           MIN(dtinicio) dtinicio,
           MAX(dtfim) dtfim
      INTO vCdHistMotivoAfastTemp, vNuDias, vDtInicio, vDtFim
      FROM (SELECT hmat.cdhistmotivoafasttemp,
                   dtinicio,
                   least(nvl(dtfim, pdtfim), pdtfim) AS dtfim,
                   decode(dtinicio, MAX(dtinicio) over(), 1, 0) AS flultimo
              FROM eafaafastamentovinculo av
             INNER JOIN eafamotivoafasttemporario mat
                ON av.cdmotivoafasttemporario = mat.cdmotivoafasttemporario
             INNER JOIN eafahistmotivoafasttemp hmat
                ON MAT.CdMotivoAfastTemporario =
                   HMAT.CdMotivoAfastTemporario
             INNER JOIN (SELECT DISTINCT cdhistmotivoafasttemp
                          FROM eafaafastamentoremunerado) ar
                ON ar.cdhistmotivoafasttemp = hmat.cdhistmotivoafasttemp
             WHERE AV.CdVinculo = pCdVinculo
               AND AV.FlAnulado = PKGPAG_TIPO.cnN
               AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
               AND HMAT.FlRemunerado = PKGPAG_TIPO.cnS
               AND AV.DtInicio <= pDtFim
               AND (HMAT.Dtiniciovigencia <= pDtFim AND
                   (HMAT.Dtfimvigencia >= pDtInicio OR
                   HMAT.Dtfimvigencia IS NULL)))
    CONNECT BY PRIOR DtInicio = DtFim + 1
           AND PRIOR CdHistMotivoAfastTemp = CdHistMotivoAfastTemp
     START WITH FlUltimo = 1
            AND DtFim >= pDtInicio;

    IF vcdhistmotivoafasttemp IS NULL THEN

      RETURN 0;

    END IF;

    SELECT nudiasfimfaixa,
           nudiasiniciofaixa,
           vlreducaoremuneracao,
           vlreducaoremunant
      INTO vnudiasfimfaixa,
           vnudiasiniciofaixa,
           vvlreducaoremuneracao,
           vlreducaoremunant
      FROM (SELECT ar.nudiasafastado nudiasfimfaixa,
                   (LAG(AR.NuDiasAfastado, 1, 0)
                    OVER(ORDER BY AR.NuDiasAfastado)) + 1 NuDiasInicioFaixa,
                   ar.vlreducaoremuneracao,
                   (LAG(AR.VlReducaoRemuneracao, 1, 0)
                    OVER(ORDER BY AR.VlReducaoRemuneracao)) VlReducaoRemunAnt
              FROM eafaafastamentoremunerado ar
             WHERE ar.cdhistmotivoafasttemp = vcdhistmotivoafasttemp)
     WHERE vnudias BETWEEN nudiasiniciofaixa AND nudiasfimfaixa;

    IF (vdtinicio + vnudiasiniciofaixa) BETWEEN pdtinicio AND pdtfim THEN

      vVlReducao := VlReducaoRemunAnt *
                    ((vDtInicio + vNuDiasInicioFaixa) - pDtInicio) / 30;

      vVlReducao := vVlReducao +
                    vVlReducaoRemuneracao *
                    LEAST(vDtFim - (vDtInicio + vNuDiasInicioFaixa) + 1, 30) / 30;

    ELSIF vdtfim < pdtfim THEN

      vVlReducao := vVlReducaoRemuneracao *
                    (LEAST(vDtFim - pDtInicio + 1, 30) / 30);

    ELSE

      vvlreducao := vvlreducaoremuneracao;

    END IF;

    RETURN vvlreducao;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fmenordataafastretroativos(pcdvinculo   IN INTEGER,
                                      pdtiniciomes IN DATE,
                                      pDtFimMes    IN DATE) RETURN DATE IS

    vdtminafast DATE;

  BEGIN
 
    SELECT MIN(dtinicio)
      INTO vdtminafast
      FROM eafaafastamentovinculo av
     WHERE AV.CdVinculo = pCdVinculo
       AND AV.FlAnulado = 'N'
       AND (AV.DtInclusao BETWEEN pdtInicioMes AND pdtFimMes)
       AND AV.DtInicio < pDtInicioMes;

    RETURN vdtminafast;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  FUNCTION fpossuiregistroobito(pcdpessoa            IN INTEGER,
                                pcdagrupamento       IN INTEGER,
                                pFlIgnoraAgrupamento in char default 'N')

   RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vcont
      FROM eafaregistroobito ro
     WHERE RO.CdPessoa = pCdPessoa
       AND RO.FlAnulado = 'N'
       AND RO.CdAgrupamento = case
             when pFlIgnoraAgrupamento = 'S' then
              ro.cdagrupamento
             else
              pCdAgrupamento
           end
       AND ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION FFolhaAuxFun(pcdVinculo IN INTEGER,
                        pNuAno     IN INTEGER,
                        PnuMes     IN INTEGER) RETURN INTEGER IS

    VCONT INTEGER;

  BEGIN
 
    FOR vFolha IN (SELECT FP.CDFOLHAPAGAMENTO, FP.CDAGRUPAMENTO
                     FROM EPAGCAPAHISTRUBRICAVINCULO CAPA
                    INNER JOIN EPAGFOLHAPAGAMENTO FP
                       ON CAPA.CDFOLHAPAGAMENTO = FP.CDFOLHAPAGAMENTO
                    INNER JOIN EPAGTIPOFOLHAPAGAMENTO TP
                       ON TP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
                    WHERE TP.CDTIPOFOLHA = 1
                      AND FP.CDTIPOCALCULO = 1
                      AND CAPA.CDVINCULO = pcdVinculo
                      AND (FP.FLCALCULODEFINITIVO = 'S' OR
                          (FP.Nuanoreferencia = pNuAno AND
                          FP.Numesreferencia = pNuMes))
                      AND CAPA.VLPROVENTOS > 0
                    ORDER BY FP.NUANOMESREFERENCIA DESC) LOOP

      BEGIN

        SELECT 1
          INTO vCONT
          FROM EPAGHISTORICORUBRICAVINCULO HRV
         WHERE HRV.CDVINCULO = pcdVinculo
           AND HRV.CDFOLHAPAGAMENTO = vFolha.CDFOLHAPAGAMENTO
           AND HRV.CDRUBRICAAGRUPAMENTO IN
               (SELECT RA1.CDRUBRICAAGRUPAMENTO
                  FROM EPAGRUBRICAAGRUPAMENTO RA
                 INNER JOIN EPAGBASECALCULO BC
                    ON RA.CDBASECALCULO = BC.CDBASECALCULO
                 INNER JOIN EPAGBASECALCULOVERSAO BCV
                    ON BC.CDBASECALCULO = BCV.CDBASECALCULO
                   AND BCV.NUVERSAO = 1
                 INNER JOIN EPAGHISTBASECALCULO HBC
                    ON HBC.CDVERSAOBASECALCULO = BCV.CDVERSAOBASECALCULO
                 INNER JOIN EPAGBASECALCULOBLOCO BCB
                    ON HBC.CDHISTBASECALCULO = BCB.CDHISTBASECALCULO
                 INNER JOIN EPAGBASECALCULOBLOCOEXPRESSAO BCBE
                    ON BCB.CDBASECALCULOBLOCO = BCBE.CDBASECALCULOBLOCO
                 INNER JOIN EPAGBASECALCBLOCOEXPRRUBAGRUP BCBR
                    ON BCBE.CDBASECALCULOBLOCOEXPRESSAO =
                       BCBR.CDBASECALCULOBLOCOEXPRESSAO
                 INNER JOIN EPAGRUBRICAAGRUPAMENTO RA1
                    ON BCBR.CDRUBRICAAGRUPAMENTO = RA1.CDRUBRICAAGRUPAMENTO
                 INNER JOIN EPAGRUBRICA R
                    ON RA1.CDRUBRICA = R.CDRUBRICA
                   AND R.CDTIPORUBRICA = 1
                 WHERE RA.CDMODALIDADERUBRICA = 3 --IN (3,4,13)
                   AND (HBC.NUANOINICIOVIGENCIA * 100 +
                       HBC.NUMESINICIOVIGENCIA) <= PNUANO * 100 + PNUMES
                   AND ((HBC.NUANOFIMVIGENCIA * 100 + HBC.NUMESFIMVIGENCIA) >=
                       PNUANO * 100 + PNUMES OR
                       HBC.NUANOFIMVIGENCIA IS NULL))
           AND ROWNUM < 2;

        RETURN VFOLHA.CDFOLHAPAGAMENTO;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          NULL;

      END;

    END LOOP;

    RETURN 0;

  END;

  FUNCTION fpossuipunicao(pcdvinculo IN INTEGER,
                          pFolha     IN PKGPAG_TIPO.rFolha) RETURN integer IS

    vcont              INTEGER;
    vUltimaDataCalculo DATE;

  BEGIN
 
    vUltimaDataCalculo := pkgpag_cal.FObterUltimaDataCalculo(pDataReferencia      => pFolha.DtCalculo,
                                                             pCdOrgao             => pFolha.CdOrgao,
                                                             pCdTipoFolha         => 1,
                                                             pCdTipoCalculo       => 1,
                                                             pFlCalculoDefinitivo => 'S');
    SELECT 1
      INTO vcont
      FROM erdihistocorrenciadisciplinar edp
     INNER JOIN erdiparametroocorrenciadiscip epp
        ON epp.cdocorrenciadisciplinar = edp.cdocorrenciadisciplinar
       AND epp.flmulta = 'S'
     WHERE edp.cdvinculo = pcdvinculo
       AND edp.flanulado = pkgpag_tipo.cnn
       AND ((EDP.DtInicioOcorrencia <= pFolha.DtFimMes AND
           (EDP.DTFIMOCORRENCIA >= pFolha.DtInicioMes OR
           EDP.DTFIMOCORRENCIA IS NULL)) OR
           (EDP.Dtinclusao > vUltimaDataCalculo AND
           EDP.Dtinclusao < pFolha.DtInicioMes))
       AND rownum < 2;

    RETURN vcont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FVinculosVigentes(pCdPessoa IN INTEGER, pDtInicioMes IN DATE)
    RETURN INTEGER IS

    vcont INTEGER;

  BEGIN
 
    SELECT COUNT(*)
      INTO vcont
      FROM ecadvinculo
     WHERE CdPessoa = pCdPessoa
       AND (DtDesligamento IS NULL OR DtDesligamento >= pDtInicioMes);

    RETURN vcont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fpossuidisposicao(pcdvinculo IN INTEGER,
                             pdtinicio  IN DATE,
                             pDtFim     IN DATE) RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vcont
      FROM ecadhistcargoefetivo hce
     WHERE HCE.CdVinculo = pCdVinculo
       AND HCE.CdRelacaotrabalho = PKGPAG_TIPO.cnRelTrabDisposicao
       AND (HCE.DtInicio <= pDtFim AND
           (HCE.DtFim >= pDtInicio OR HCE.DtFim IS NULL))
       AND HCE.FlAnulado = PKGPAG_TIPO.cnN
       AND ROWNUM < 2;

    IF vcont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION fpagaremuneracaocef(pfolha IN pkgpag_tipo.rfolha,
                               pcef   IN pkgpag_tipo.rcef)

   RETURN BOOLEAN IS

    vcont INTEGER;

    vqtdiasafastdisp INTEGER; -- Quantidade de dias afastado da relacao de
    -- vinculo em decorrencia de disposicao;

    bpaga BOOLEAN;

    bempagamento BOOLEAN;
    vdtinicio    DATE;
    vdtfim       DATE;
    /*------------------------------------------------------------------------------
        Funcao: FPagaNoDestino
      Objetivo: Retorna TRUE caso o pagamento deva ser realizado no destino

          Nota: Esta funcao e chamada quando a relacao de trabalho e do tipo
                "a disposicao"
    /*-----------------------------------------------------------------------------*/

    FUNCTION fpaganodestino(pcdvinculo IN INTEGER)

     RETURN BOOLEAN IS

      vflpagamento CHAR(1);

    BEGIN
 
      SELECT flpagamento
        INTO vflpagamento
        FROM emovservidorrecebido sr
       WHERE SR.CdVinculo = pCdVinculo
         AND SR.DtApresentacao <= pFolha.DtFimMes
         AND (SR.DtFimDisposicao >= pFolha.DtInicioMes OR
             SR.DtFimDisposicao IS NULL);

      IF vflpagamento = 'O' or
         (pFolha.CdOrgao = 2 and pFolha.CdTipoFolhaPagamento = 1505) THEN

        RETURN FALSE;

      ELSE

        RETURN TRUE;

      END IF;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN TRUE;

    END;

  BEGIN
 
    bpaga := FALSE;

    bempagamento := CASE pkgpag_var.vpagasitdisposicao
                      WHEN 'PAG-DEST-ADVINDO-DE-FORA' THEN
                       TRUE
                      WHEN 'PAG-DISP-ONUS-ORIGEM' THEN
                       TRUE
                      WHEN 'PAG-DEST-CALCULO-DEST' THEN
                       TRUE
                      WHEN 'PAG-ORIGEM-CALCULO-ORIGEM' THEN
                       TRUE
                      WHEN 'PAG-ORIGEM-CALCULO-DEST' THEN
                       FALSE
                      WHEN 'PAG-DEST-CALCULO-ORIGEM' THEN
                       FALSE
                      WHEN 'NAO(EFETIVO/DISPOSICAO)' THEN
                       FALSE
                      WHEN 'NAO-DISPOSICAO' THEN
                       FALSE
                    END;

    -- Validar se iniciou outra disposicao em outro orgao dentro do mes da folha e nao paga
    -- SIG-6100

    if fpossuidisposicaooutroorgao(pCef.cdvinculo, pCef.DtInicio) and
       pFolha.CdTipoFolhaPagamento <> 1505 then

      bPaga := FALSE;
      return bPaga;

    end if;

    -----------------------------------------------------------------
    -- Se a relacao de trabalho e a disposicao,
    -- verifica se o pagamento e na origem ou no destino
    -----------------------------------------------------------------

    IF pcef.cdrelacaotrabalho = pkgpag_tipo.cnreltrabdisposicao THEN

      -------------------------------------------------------------------------------
      -- Se o servidor veio a disposicao de outro agrupamento ou de um orgao externo
      -------------------------------------------------------------------------------

      IF pcef.flprincipal = 'S' THEN

        bpaga := fpaganodestino(pcef.cdvinculo);

        pkgpag_var.vgrelvincprincipal.tipo := 1;

        pkgpag_var.vgrelvincprincipal.cdhist := pcef.cdhistrelvinc;

        pkgpag_var.vgrelvincprincipal.cdreltrabpagamento := pcef.cdrelacaotrabalho;

        pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := pcef.cdunidadeorganizacional;

        IF bpaga THEN

          pkgpag_var.vpagasitdisposicao := 'PAG-DEST-ADVINDO-DE-FORA';

        ELSE

          pkgpag_var.vpagasitdisposicao := 'PAG-DISP-ONUS-ORIGEM';

          -- Pq o servidor recebido a disposicao com onus na origem
          -- tem direito a algumas rubricas no destino

          bpaga := TRUE;

        END IF;

        ------------------------------------------------------------------
        -- Se o servidor veio movimentado a disposicao de outro orgao
        -- do mesmo agrupamento ou se tem um comissionado
        ------------------------------------------------------------------

      ELSIF pcef.flprincipal = 'N' AND
            (pCEF.CdOrgaoExercicio = pFolha.cdOrgao OR
            PKGPAG_VAR.bVinculoComCCO) THEN

        SELECT COUNT(*)
          INTO vcont
          FROM eafaafastamentorelvinc av
         INNER JOIN emovmovimentacao m
            ON av.cdhistcargoefetivo = m.cdhistcargoefetivo
         WHERE AV.CdHistCargoEfetivoGerador = pCEF.CdHistRelVinc
           AND AV.DtInicio <= pFolha.DtFimMes /*PKGPAG_VAR.vDtCalculo*/
           AND (AV.DtFim >= pFolha.DtFimMes /*PKGPAG_VAR.vDtCalculo*/
               OR AV.DtFim IS NULL)
           AND Av.DtInicio = M.DtApresentacao
           AND M.FlPagamentoOrigem = 'N'
           AND AV.FlAnulado = PKGPAG_TIPO.cnN;

        IF vcont > 0 THEN

          bpaga := TRUE;

          -- O CALCULO ESTA SENDO FEITO NO ORGAO DA DISPOSICAO
          -- E O PAGAMENTO SERA FEITO TAMBEM PELO ORGAO DA DISPOSICAO
          pkgpag_var.vpagasitdisposicao := 'PAG-DEST-CALCULO-DEST';

          pkgpag_var.vgrelvincprincipal.cdreltrabpagamento := pcef.cdrelacaotrabalho;

        ELSE

          bpaga := FALSE;

          IF NOT pkgpag_var.bvinculocomcco THEN

            -- O CALCULO ESTA SENDO FEITO NO ORGAO DA DISPOSICAO
            -- MAS O PAGAMENTO SERA FEITO PELO ORGAO DE ORIGEM

            IF NOT bempagamento THEN

              pkgpag_var.vpagasitdisposicao := 'PAG-ORIGEM-CALCULO-DEST';

            END IF;

          END IF;

        END IF;
      -- SIG 8109 - adicionado vdtinicio e vdtfim
      ELSIF fdisposicaofinalizames(pkgpag_var.vgvinculo.cdvinculo,
                                   vdtinicio,
                                   vdtfim) and
            pCEF.CdOrgaoExercicio <> pFolha.cdOrgao then

        if pcef.dtinicio = vdtinicio and pcef.dtfim = vdtfim THEN
          bPaga := FALSE;
        ELSE
          bPaga := TRUE;
        END IF;

        return bPaga;

      ELSE

        bpaga := FALSE;

      END IF;

      IF NOT bpaga THEN

        pkgpag_var.btemdireitolancfin := FALSE;

      ELSE

        pkgpag_var.btemdireitolancfin := TRUE;

      END IF;

    ELSIF -- Efetivos no orgao sem novo processo seletivo ou com novo processo seletivo dentro do proprio orgao
     (pCEF.CdOrgaoExercicio = pFolha.cdOrgao AND
     (pCEF.DtFimNovoProcessoSeletivo IS NULL OR
     pCEF.CdOrgaoExercicio = pCEF.cdOrgaoDestProcSeletivo) AND
     (pCEF.CdOrgaoDestMovimentacao IS NULL OR
     pCEF.CdOrgaoExercicio = pCEF.CdOrgaoDestMovimentacao)) OR
     PKGPAG_VAR.bVinculoComCCO OR
    -- Efetivos de outro orgao com novo processo seletivo dentro do orgao em processamento
     (pCEF.CdOrgaoExercicio <> pFolha.cdOrgao AND
     (pCEF.DtFimNovoProcessoSeletivo BETWEEN pFolha.DtInicioMes AND
     pFolha.DtFimMes) AND pCEF.CdOrgaoDestProcSeletivo = pFolha.cdOrgao) OR
    -- Efetivos de outro orgao movimentado definitivamente para dentro do orgao em processamento
     (pCEF.CdOrgaoExercicio <> pFolha.cdOrgao AND
     pCEF.CdOrgaoDestMovimentacao = pFolha.cdOrgao) THEN

      SELECT SUM(dtfim - dtinicio + 1)
        INTO vqtdiasafastdisp
        FROM (SELECT CASE
                       WHEN av.dtinicio <= pfolha.dtiniciomes THEN
                        pfolha.dtiniciomes
                       ELSE
                        av.dtinicio
                     END AS dtinicio,
                     CASE
                       WHEN av.dtfim >= pfolha.dtfimmes OR av.dtfim IS NULL THEN
                        pfolha.dtfimmes
                       ELSE
                        av.dtfim
                     END AS dtfim
                FROM eafaafastamentorelvinc av
               INNER JOIN emovmovimentacao m
                  ON av.cdhistcargoefetivo = m.cdhistcargoefetivo
               WHERE AV.CdHistCargoEfetivo = pCEF.CdHistRelVinc
                 AND AV.DtInicio <= pFolha.DtFimMes /*PKGPAG_VAR.vDtCalculo*/
                 AND (AV.DtFim >= pFolha.DtFimMes /* PKGPAG_VAR.vDtCalculo*/
                     OR AV.DtFim IS NULL)
                 AND AV.CdHistCargoEfetivoGerador IS NOT NULL
                 AND AV.DtInicio = M.DtApresentacao
                 AND M.FlPagamentoOrigem = 'N'
                 AND AV.FlAnulado = PKGPAG_TIPO.cnN);

      -----------------------------------------------------------------------
      -- Se o servidor estiver movimentado a disposicao de outro orgao
      -- do mesmo agrupamento na data do calculo
      -----------------------------------------------------------------------

      IF vqtdiasafastdisp > 0 THEN

        bpaga := FALSE;

        -- O CALCULO ESTA SENDO FEITO NO orgao DE ORIGEM
        -- MAS O PAGAMENTO SERA FEITO PELO orgao DA DISPOSICAO

        IF NOT bempagamento THEN

          pkgpag_var.vpagasitdisposicao := 'PAG-DEST-CALCULO-ORIGEM'; -- OK

        END IF;

        ------------------------------------------------------------------------
        -- Caso o servidor tenha mais de um CEF para o mesmo vinculo, verifica
        -- se ha afastamento da relacao de vinculo para outro cdhistcargoefetivo
        -- desde que o cef tenha iniciado no mes.
        -- (para servidores que eram efetivos e passaram noutro concurso, assumiram,
        -- permaneceram com o mesmo vinculo mas cef diferentes e tiveram disposicao)
        ------------------------------------------------------------------------

      ELSIF pCEF.CdOrgaoExercicio <> pFolha.cdOrgao AND
            pkgpag_var.vpagasitdisposicao = 'PAG-DEST-CALCULO-ORIGEM' AND
            (PCEF.DtFim >= pfolha.DtInicioMes AND
            PCEF.DtFim <= pfolha.DtFimMes) THEN

        SELECT SUM(dtfim - dtinicio + 1)
          INTO vqtdiasafastdisp
          FROM (SELECT CASE
                         WHEN av.dtinicio <= pfolha.dtiniciomes THEN
                          pfolha.dtiniciomes
                         ELSE
                          av.dtinicio
                       END AS dtinicio,
                       CASE
                         WHEN av.dtfim >= pfolha.dtfimmes OR av.dtfim IS NULL THEN
                          pfolha.dtfimmes
                         ELSE
                          av.dtfim
                       END AS dtfim
                  FROM eafaafastamentorelvinc av
                 INNER JOIN ecadhistcargoefetivo cef
                    ON cef.cdhistcargoefetivo = av.cdhistcargoefetivo
                 INNER JOIN emovmovimentacao m
                    ON av.cdhistcargoefetivo = m.cdhistcargoefetivo
                 WHERE cef.cdvinculo = PCEF.CdVinculo
                   AND cef.cdhistcargoefetivo <> pCEF.CdHistRelVinc
                   AND AV.DtInicio <= pFolha.DtFimMes /*PKGPAG_VAR.vDtCalculo*/
                   AND (AV.DtFim >= pFolha.DtFimMes /* PKGPAG_VAR.vDtCalculo*/
                       OR AV.DtFim IS NULL)
                   AND AV.CdHistCargoEfetivoGerador IS NOT NULL
                   AND AV.DtInicio = M.DtApresentacao
                   AND M.FlPagamentoOrigem = 'N'
                   AND AV.FlAnulado = PKGPAG_TIPO.cnN);

        -----------------------------------------------------------------------
        -- Se o servidor estiver movimentado a disposicao de outro orgao
        -- do mesmo agrupamento na data do calculo
        -----------------------------------------------------------------------

        IF vqtdiasafastdisp > 0 THEN

          bpaga := FALSE;

        END IF;
      ELSE

        bpaga := TRUE;

        pkgpag_var.vgrelvincprincipal.cdreltrabpagamento := pcef.cdrelacaotrabalho;

        -- O CALCULO ESTA SENDO FEITO NO orgao DE ORIGEM
        -- E O PAGAMENTO SERA FEITO TAMBEM PELO orgao DE ORIGEM
        pkgpag_var.vpagasitdisposicao := 'PAG-ORIGEM-CALCULO-ORIGEM'; --  OK

      END IF;

    ELSIF pcef.cdorgaoexercicio <> pfolha.cdorgao AND
          pkgpag_var.bpossuidisposicao THEN

      bpaga := FALSE;

    ELSE

      pkgpag_var.vpagasitdisposicao := 'NAO-DISPOSICAO';

    END IF;

    RETURN bpaga;

  END;

  FUNCTION fpossuivinculocco(pcdvinculo IN INTEGER,
                             pcdorgao   IN INTEGER,
                             pdtinicio  IN DATE,
                             pDtFim     IN DATE) RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    --
    -- Alterado de a comparacao com a HCC.DtFim pelo pDtInicio e nao vDtCalculo, pois excluia fim no mes mas anteriores
    -- a data do calculo
    --
    SELECT 1
      INTO vcont
      FROM ecadhistcargocom hcc
     WHERE HCC.CdVinculo = pCdVinculo
       AND HCC.CdOrgaoExercicio = pCdOrgao
       AND HCC.CdCargoComRemuneracao IS NULL
       AND (hcc.dtinicio <= pkgpag_var.vdtcalculo AND
           (HCC.DtFim >= pDtInicio OR HCC.DtFim IS NULL))
       AND HCC.FlAnulado = PKGPAG_TIPO.cnN
       AND ROWNUM < 2;

    IF vcont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION fObterCdOrgaoExercicioTitular(pCdVinculoSubstituto IN INTEGER,
                                         pDtInicio            IN DATE,
                                         pDtFim               IN DATE)
    RETURN INTEGER IS
    vCdOrgao INTEGER;
  BEGIN
 
    SELECT hcc2.cdorgaoexercicio
      INTO vCdOrgao
      FROM ecadhistcargocom hcc
     inner join ecadhistcargocom hcc2
        on hcc.cdhistccotitular = hcc2.cdhistcargocom
     WHERE hcc.cdvinculo = pCdVinculoSubstituto

       AND hcc.fltipoprovimento = pkgpag_tipo.cns
       AND (hcc.dtinicio <= pDtFim AND
           (hcc.dtfim >= pDtInicio OR hcc.dtfim IS NULL))
       AND hcc.flanulado = pkgpag_tipo.cnn
       AND rownum < 2;

    RETURN vCdOrgao;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  --
  -- Verificar se possui vinculo substituto valido no periodo
  --
  FUNCTION fpossuivinculosubst(pcdvinculo IN INTEGER,
                               pdtinicio  IN DATE,
                               pDtFim     IN DATE) RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vcont
      FROM ecadhistcargocom hcc
     WHERE hcc.cdvinculo = pcdvinculo
       AND hcc.fltipoprovimento = pkgpag_tipo.cns
       AND (hcc.dtinicio <= pDtFim AND
           (hcc.dtfim >= pdtinicio OR hcc.dtfim IS NULL))
       AND hcc.flanulado = pkgpag_tipo.cnn
       AND rownum < 2;

    IF vcont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  --
  -- Verificar se quando esta substituindo e por ferias do titular. Neste caso muda a quantidade
  -- minima de dias exigidos em relacao aos demais casos. Retorna 9 quando estiver em ferias e 10
  -- nos demais casos
  -- SOLICITACAO 5888/2014 -Parametros aubstituicao cargo em comissao.
  -- Como a aplicacao nao informa um motivo de substituicao e necessario verificar nos periodos
  -- aquisitivos de ferias e no usufruto no periodo.
  --

  FUNCTION fpossuisubstferias(pcdvinculo IN INTEGER,
                              pcdorgao   IN INTEGER,
                              pdtinicio  IN DATE,
                              pDtFim     IN DATE) RETURN NUMBER IS

    vcont INTEGER := 0;

    --
    -- Solicitacao de Sustentacao #76117
    -- 10382/2017] - FOLHA - PAGAMENTO DE SUBSTITUICAO DE CARGO COMISSIONADO
    --
  BEGIN
 
    SELECT COUNT(*)
      INTO vcont
      FROM ecadhistcargocom hcc
     INNER JOIN ECADHISTCARGOCOM HCC2
        ON HCC.CDHISTCCOTITULAR = HCC2.CDHISTCARGOCOM
     INNER JOIN EMOVPERIODOAQUISITIVOFERIAS EMF
        ON EMF.CDVINCULO = HCC2.CDVINCULO
     INNER JOIN EMOVFERIASFRUICAOUSUFRUTO EUSU
        ON EUSU.CDPERIODOAQUISITIVOFERIAS = EMF.CDPERIODOAQUISITIVOFERIAS
     WHERE hcc.cdvinculo = pcdvinculo
       AND hcc.cdorgaoexercicio = pcdorgao
          --AND hcc.cdcargocomremuneracao IS NULL
       AND (hcc.dtinicio <= pdtfim AND
           (hcc.dtfim >= pdtinicio OR hcc.dtfim IS NULL))
       AND hcc.flanulado = pkgpag_tipo.cnn
       AND hcc2.flanulado = pkgpag_tipo.cnn
       AND (eusu.dtinicial <= pdtfim AND
           (eusu.dtfinal >= pdtinicio OR eusu.dtfinal IS NULL))
       AND hcc.fltipoprovimento = pkgpag_tipo.cns;

    IF vcont > 0 THEN
      RETURN 9;

    ELSE
      RETURN 10;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 10;

  END;

  /*----------------------------------------------------------------------------------------------------*/
  -- FRetornaTipoDiaNaoUtil
  -- Funcao que retorna o parametro dos dias que devem ser considerados no auxilio alimentacao
  --
  /*----------------------------------------------------------------------------------------------------*/

  FUNCTION FRetornaTipoDiaNaoUtil(pCdOrgao IN INTEGER) RETURN INTEGER IS

  BEGIN
 
    -- Parametros: PNuTipoDiaNaoUtil - Identifica o tipo de dias que nao serao considerados dias uteis.
    -- 0 - Todos (Sabados, Domingos, Feriados (nacionais/estaduais/municipais) e Pontos Facultativos (normais e compensaveis))
    -- 1 - Apenas Sabados, Domingos e Feriados
    -- 2 - Apenas Sabados, Domingos e Pontos Facultativos Normais
    -- 3 - Apenas Sabados, Domingos e Pontos Facultativos Compensaveis
    -- 4 - Apenas Sabados, Domingos, Feriados e Pontos Facultativos Normais
    -- 5 - Apenas Sabados, Domingos, Feriados e Pontos Facultativos Compensaveis
    -- 6 - Apenas Sabados, Domingos e Pontos Facultativos Normais e Compensaveis

    IF pkgpag_var.vgauxilioali.count > 0 THEN

      IF pkgpag_var.vgauxilioali.exists(pcdorgao) THEN

        RETURN CASE WHEN PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaFeriado = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFacul = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFaculComp = PKGPAG_TIPO.cnS THEN 0 WHEN PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaFeriado = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFacul = PKGPAG_TIPO.cnN AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFaculComp = PKGPAG_TIPO.cnN THEN 1 WHEN PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaFeriado = PKGPAG_TIPO.cnN AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFacul = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFaculComp = PKGPAG_TIPO.cnN THEN 2 WHEN PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaFeriado = PKGPAG_TIPO.cnN AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFacul = PKGPAG_TIPO.cnN AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFaculComp = PKGPAG_TIPO.cnS THEN 3 WHEN PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaFeriado = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFacul = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFaculComp = PKGPAG_TIPO.cnN THEN 4 WHEN PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaFeriado = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFacul = PKGPAG_TIPO.cnN AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFaculComp = PKGPAG_TIPO.cnS THEN 5 WHEN PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaFeriado = PKGPAG_TIPO.cnN AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFacul = PKGPAG_TIPO.cnS AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlDescontaPontoFaculComp = PKGPAG_TIPO.cnS THEN 6

        ELSE

        0

        END;

      END IF;

    END IF;

    RETURN 0;

  END;

  FUNCTION fpossuilancretroativo(pcdvinculo IN INTEGER,
                                 pfolha     IN pkgpag_tipo.rfolha)

   RETURN BOOLEAN IS

    vcont INTEGER;

  BEGIN
 
    select 1
      into vcont
      from epaglancamentofinanceiro f
     inner join epagrubricaagrupamento ra
        on ra.cdrubricaagrupamento = f.cdrubricaagrupamento
     inner join epagrubrica r
        on ra.cdrubrica = r.cdrubrica
     where F.CdVinculo = pCdVinculo
       and F.DtInicioDireito <= pFolha.dtFimMes
       and (F.DtFimdireito >= pFolha.DtInicioMes or F.DtFimDireito is null)
       and (F.CdProcessoPagRetroativo is not null)
       and F.FlAnulado = PKGPAG_TIPO.cnN
       and R.CdTipoRubrica in (2, 10, 12)
       and f.cdrubricaagrupamento in
           (select ra.cdrubricaagrupamento
              from vpagrubricaagrupamento ra
             where ra.cdrubricaagrupamento = f.cdrubricaagrupamento
               and ra.flsuspensa = PKGPAG_TIPO.cnN)
       and ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION fPagaLanctoFinAfastDefinitivo(pcdvinculo IN INTEGER)
    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    select 1
      into vcont
      from epaglancamentofinanceiro f
     where F.CdVinculo = pCdVinculo
       and F.DtInicioDireito <= pkgpag_var.vgFolha.dtFimMes
       and (F.DtFimdireito >= pkgpag_var.vgFolha.DtInicioMes or
           F.DtFimDireito is null)
       and F.FlAnulado = PKGPAG_TIPO.cnN
       and F.Flpagaafastdefinitivo = PKGPAG_TIPO.cnS
       and f.cdrubricaagrupamento in
           (select ra.cdrubricaagrupamento
              from vpagrubricaagrupamento ra
             where ra.cdrubricaagrupamento = f.cdrubricaagrupamento
               and ra.flsuspensa = PKGPAG_TIPO.cnN)
       and ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    When no_data_found THEN

      return false;

    When others then
      return false;

  end;

  FUNCTION fpossuilancfinanceiro(pcdvinculo        IN INTEGER,
                                 pfolha            IN pkgpag_tipo.rfolha,
                                 pcdrubrica        IN INTEGER,
                                 pIncluiFinalizado in char default 'N')

   RETURN BOOLEAN IS

    vcont INTEGER;

    vValor NUMBER(13, 2);

  BEGIN
 
    if pIncluiFinalizado = 'S' then

      select 1, f.Vllancamentofinanceiro
        into vcont, vValor
        from epaglancamentofinanceiro f
       where F.CdVinculo = pCdVinculo
         and F.FlAnulado = PKGPAG_TIPO.cnN
         and F.Cdrubricaagrupamento = pCdRubrica
         and f.cdrubricaagrupamento in
             (select ra.cdrubricaagrupamento
                from vpagrubricaagrupamento ra
               where ra.cdrubricaagrupamento = f.cdrubricaagrupamento
                 and ra.flsuspensa = PKGPAG_TIPO.cnN)
         and ROWNUM < 2;

    else

      select 1, f.Vllancamentofinanceiro
        into vcont, vValor
        from epaglancamentofinanceiro f
       where F.CdVinculo = pCdVinculo
         and F.DtInicioDireito <= pFolha.dtFimMes
         and (F.DtFimdireito >= pFolha.DtInicioMes or
             F.DtFimDireito is null)
         and F.FlAnulado = PKGPAG_TIPO.cnN
         and F.Cdrubricaagrupamento = pCdRubrica
         and f.cdrubricaagrupamento in
             (select ra.cdrubricaagrupamento
                from vpagrubricaagrupamento ra
               where ra.cdrubricaagrupamento = f.cdrubricaagrupamento
                 and ra.flsuspensa = PKGPAG_TIPO.cnN)
         and ROWNUM < 2;

    end if;

    --
    -- Se for a rubrica de Valor do Cargo Efetivo - Evento 1
    --
    IF pkgpag_var.vgEvento(1).CdRubricaAgrupamento = pCdRubrica THEN
      pkgpag_var.vgValorFixoCEF.VlFixo := vValor;
    END IF;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION frubricaslancamento(pcdvinculo IN INTEGER,
                               pfolha     IN pkgpag_tipo.rfolha)

   RETURN pkgpag_tipo.tlistavalor IS

    vlistarubrica pkgpag_tipo.tlistavalor;
  BEGIN
 
    -- Nao le a rubrica da base da margem consignavel bruta
    -- caso esteja lancada em decisao judicial

    PKGPAG_Geral.vgFlPossuiFinRegencia := FALSE;

    FOR vrubrica IN (select f.cdrubricaagrupamento   as cdrubricaagrupamento,
                            f.vllancamentofinanceiro as vllancamentofinanceiro,
                            f.dtiniciodireito        as DtInicio,
                            f.dtfimdireito           as DtFim,
                            f.nusufixorubrica        as Sufixo,
                            1                        as inTpValor,
                            null                     as cdRefValor
                       from epaglancamentofinanceiro f
                      where F.CdVinculo = pCdVinculo
                        and F.DtInicioDireito <= pFolha.dtFimMes
                        and (F.DtFimdireito >= pFolha.DtInicioMes or
                            F.DtFimDireito is null)
                        and F.FlAnulado = PKGPAG_TIPO.cnN
                        and f.cdrubricaagrupamento in
                            (select ra.cdrubricaagrupamento
                               from vpagrubricaagrupamento ra
                              where ra.cdrubricaagrupamento =
                                    f.cdrubricaagrupamento
                                and ra.flsuspensa = PKGPAG_TIPO.cnN)
                     union all
                     select epd.cdrubricaagrupamento as cdrubricaagrupamento,
                            epd.vldeterminado        as vllancamentofinanceiro,
                            epd.dtiniciodireito      as DtInicio,
                            null                     as DtFim,
                            epd.nusufixorubrica      as Sufixo,
                            epd.intipovalor          as inTpValor,
                            epd.cdvalorreferencia    as cdRefValor
                       from epageventopagagrupdecisao epd
                      where EPD.CdVinculo = pCdVinculo
                        and EPD.FlAnulado = PKGPAG_TIPO.cnN
                        and EPD.CdRubricaAgrupamento NOT IN
                            (nvl(PKGPAG_VAR.vgCdRubricaBaseConsig, 0),
                             nvl(PKGPAG_VAR.vgParamPagamento.Cdrubagrupdesciprevliminar,
                                 0))
                        and ((EPD.NuAnoInicioDireito <
                            pFolha.NuAnoReferencia or
                            (EPD.NuAnoInicioDireito =
                            pFolha.NuAnoReferencia and
                            EPD.NuMesInicioDireito <=
                            pFolha.NuMesReferencia)) and
                            (epd.nuanofimdireito > pfolha.nuanoreferencia or
                            (epd.nuanofimdireito = pfolha.nuanoreferencia and
                            epd.numesfimdireito >= pfolha.numesreferencia) or
                            EPD.NuAnoFimDireito is null))) LOOP

      -- Excecao regencia de classe
      if vrubrica.cdrubricaagrupamento = 10501 and
         (vrubrica.dtinicio > pFolha.DtInicioMes or
         vRubrica.DtFim < pFolha.DtFimMes) then
        Pkgpag_Geral.vgNuSufixoRegencia    := vrubrica.sufixo + 1;
        PKGPAG_Geral.vgFlPossuiFinRegencia := TRUE;
      elsif vrubrica.intpvalor = 1 --Valor fixo
        then
        vlistarubrica(vrubrica.cdrubricaagrupamento) := vrubrica.vllancamentofinanceiro;
      elsif vrubrica.intpvalor = 2 --Referencia de valor
        then
        vlistarubrica(vrubrica.cdrubricaagrupamento) := NVL(PKGPAG_VAR.vgValorReferencia(vrubrica.cdRefValor).VlReferencia, 0);
      end if;

    END LOOP;

    RETURN vlistarubrica;

  END;

  FUNCTION frubricaslanccomplementar(pcdvinculo IN INTEGER,
                                     pfolha     IN pkgpag_tipo.rfolha)

   RETURN pkgpag_tipo.tlanccomplementar IS

    CURSOR clanccomplementar IS

      SELECT lc.cdrubricaagrupamento,
             lc.nusufixorubrica,
             lc.vllancamento,
             r.cdtiporubrica,
             lc.vlindice
        FROM epaglancamentocomplementar lc
       INNER JOIN epagrubricaagrupamento ra
          ON ra.cdrubricaagrupamento = lc.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON r.cdrubrica = ra.cdrubrica
       WHERE LC.CdVinculo = pCdVinculo
         AND LC.CdFolhaPagamento = pFolha.CdFolhaPagamento;

    vlistacomplementar pkgpag_tipo.tlanccomplementar;

  BEGIN
 
    OPEN clanccomplementar;

    FETCH cLancComplementar BULK COLLECT
      INTO vListaComplementar;

    CLOSE clanccomplementar;

    RETURN vlistacomplementar;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN vlistacomplementar;

  END;

  FUNCTION FRetornaCdRubrica(pcdtiporubrica INTEGER,
                             pNuRubrica     INTEGER) RETURN INTEGER IS

    vcdrubrica   INTEGER;

  BEGIN
 
    SELECT cdrubrica 
      INTO vcdrubrica 
      FROM epagrubrica r

     WHERE R.CdTipoRubrica = pCdTipoRubrica
       AND R.NuRubrica = pNuRubrica;

    RETURN vcdrubrica;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;


  /*-----------------------------------------------------------------------------------------/*
  --    Funcao: FRetornaRubrica
  --
  --  Objetivo: Retorna o codigo da rubrica do agrupamento com base no tipo e numero da rubrica
  --
  /*-----------------------------------------------------------------------------------------*/
  FUNCTION fretornarubrica(pcdagrupamento INTEGER,
                           pcdtiporubrica INTEGER,
                           pNuRubrica     INTEGER) RETURN INTEGER IS

    vcdrubricaagrupamento INTEGER;

  BEGIN
 
    SELECT cdrubricaagrupamento
      INTO vcdrubricaagrupamento
      FROM epagrubricaagrupamento ra
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
     WHERE RA.CdAgrupamento = pCdAgrupamento
       AND R.CdTipoRubrica = pCdTipoRubrica
       AND R.NuRubrica = pNuRubrica;

    RETURN vcdrubricaagrupamento;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  ---------------------------------------------------------------------------
  -- FGeraRubrica
  -- E utilizada para duas finalidades:
  -- 1) Caso a rubrica esteja lancada em financeiro, nao permite que ela seja
  --    calculada atraves de eventos
  -- 2) Caso a rubrica esteja com a indicacao de suspensa
  --------------------------------------------------------------------------
  FUNCTION fgerarubrica(prubrica IN INTEGER)

   RETURN BOOLEAN IS

  BEGIN
 
    IF PKGPAG_VAR.vListaRubricas.EXISTS(pRubrica) OR PKGPAG_VAR.vgRubrica(pRubrica)
      .FlSuspensa = PKGPAG_TIPO.cnS THEN

      RETURN FALSE;

    ELSE

      RETURN TRUE;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN TRUE;

  END;

  FUNCTION fpossuilanccomplementar(pcdrubricaagrupamento IN INTEGER,
                                   pnusufixorubrica      IN INTEGER)
    RETURN BOOLEAN IS

  BEGIN
 
    IF pkgpag_var.vglanccomplementar.count > 0 THEN

      FOR i IN PKGPAG_VAR.vgLancComplementar.FIRST .. PKGPAG_VAR.vgLancComplementar.LAST LOOP

        IF PKGPAG_VAR.vgLancComplementar(i)
         .CdRubricaAgrupamento = pCdRubricaAgrupamento AND
            (PKGPAG_VAR.vgLancComplementar(i)
             .NuSufixoRubrica = pNuSufixoRubrica or pnusufixorubrica is null) THEN

          RETURN TRUE;

        END IF;

      END LOOP;

      RETURN FALSE;

    ELSE

      RETURN FALSE;

    END IF;

  END;

  /*----------------------------------------------------------------------------
  --
  -- Funcao: FQtFaltas
  -- Retorna as faltas ocorridas durante o ano
  /*----------------------------------------------------------------------------*/

  FUNCTION FQtFaltas(pCdVinculo IN INTEGER, pNuAno IN INTEGER) RETURN INTEGER IS

    vdtinicio DATE;

    vdtfim DATE;

    vqtfaltas INTEGER;

  BEGIN
 
    vqtfaltas := 0;

    vdtinicio := trunc(to_date(pnuano, 'YYYY'), 'YYYY');

    vdtfim := round(to_date(pnuano, 'YYYY'), 'YYYY');

    SELECT COUNT(*)
      INTO vqtfaltas
      FROM emovfrequenciajornada fj
     INNER JOIN ecadhistjornadatrabalho hj
        ON fj.cdhistjornadatrabalho = hj.cdhistjornadatrabalho
     INNER JOIN ecadlocaltrabalho l
        ON hj.cdlocaltrabalho = l.cdlocaltrabalho
     INNER JOIN ecadhistcargoefetivo cef
        ON l.cdhistcargoefetivo = cef.cdhistcargoefetivo
     INNER JOIN ecadvinculo v
        ON cef.cdvinculo = v.cdvinculo
     WHERE V.CdVinculo = pCdVinculo
       AND FJ.CdTipoRegistroJornada = 2
       AND (FJ.DtFrequencia BETWEEN vDtInicio AND vDtFim)
       AND FJ.FlAnulado = PKGPAG_TIPO.cnN;

    RETURN vqtfaltas;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
  --
  -- Funcao: FDiasAfastMotNaoRem
  /*----------------------------------------------------------------------------*/

  FUNCTION fdiasafasttempnaorem(pcdvinculo           IN INTEGER,
                                pdtiniciomes         IN DATE,
                                pdtfimmes            IN DATE,
                                pdtcalculo           IN DATE,
                                pflacidente          IN CHAR DEFAULT 'N',
                                pflApenasAfastNaoRem IN CHAR DEFAULT 'N')

   RETURN INTEGER IS

    vnudiasafast INTEGER;

    vdtfimmes DATE;

  BEGIN
 
    IF to_char(pdtfimmes, 'DD') = '31' THEN

      vdtfimmes := pdtfimmes - 1;

    ELSE

      vdtfimmes := pdtfimmes;

    END IF;

    SELECT nvl(SUM(diaafastado), 0) AS nudiaafast
      INTO vnudiasafast
      FROM (SELECT cdvinculo, dtdia AS dtdiaafastado, 1 AS diaafastado
              FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                      FROM dual
                    CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                               pdtInicioMes AND vDtFimMes) D
             INNER JOIN (SELECT cdVinculo,
                               CASE
                                 WHEN av.dtinicio < pdtiniciomes THEN
                                  pdtiniciomes
                                 ELSE
                                  av.dtinicio
                               END AS dtinicio,
                               CASE
                                 WHEN (AV.dtFim > vdtFimMes OR
                                      AV.DtFim IS NULL) THEN
                                  vdtfimmes
                                 ELSE
                                  av.dtfim
                               END AS dtfim
                          FROM eafaafastamentovinculo av
                         INNER JOIN eafamotivoafasttemporario mat
                            ON AV.CdMotivoAfastTemporario =
                               MAT.CdMotivoAfastTemporario
                         INNER JOIN eafahistmotivoafasttemp hmat
                            ON MAT.CdMotivoAfastTemporario =
                               HMAT.CdMotivoAfastTemporario
                         WHERE AV.CdVinculo = pCdVinculo
                           AND (HMAT.FlRemunerado = PKGPAG_TIPO.cnN OR
                               (pflApenasAfastNaoRem = 'N' AND
                               HMAT.FlAuxilioDoenca = PKGPAG_TIPO.cnS))
                           AND HMAT.FlAcidenteTrabalho = pFlAcidente
                           AND AV.DtInicio <= pdtFimMes
                           AND (AV.DtFim >= pdtInicioMes OR AV.DtFim IS NULL)
                           AND HMAT.DtInicioVigencia <= pdtCalculo
                           AND (HMAT.DtFimVigencia >= pdtCalculo OR
                               HMAT.DtFimVigencia IS NULL)
                           AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
                           AND AV.FlAnulado = PKGPAG_TIPO.cnN) B
                ON (B.DtInicio <= D.DtDia)
               AND (B.DtFim >= D.DtDia)) A;

    IF vnudiasafast > 30 OR
       (to_char(pdtfimmes, 'DD') = '28' AND vnudiasafast = 28) OR
       (to_char(pdtfimmes, 'DD') = '29' AND vnudiasafast = 29) THEN

      RETURN 30;

    ELSE

      RETURN vnudiasafast;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fDtInclusaoCef(pcdvinculo IN INTEGER) RETURN DATE IS

    vDtInicio DATE;

  BEGIN
 
    SELECT MAX(DtInclusao)
      INTO vDtInicio
      FROM eCadHistCargoEfetivo cef
     WHERE cef.CdVinculo = pCdVinculo
       AND cef.flanulado = 'N'
       AND cef.dtinclusao <= pkgpag_var.vgFolha.DtCalculo;

    RETURN vDtInicio;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;

    WHEN OTHERS THEN
      RETURN NULL;
  END;

  /*----------------------------------------------------------------------------
  --
  -- Funcao: FDiasAfastTemp
  /*----------------------------------------------------------------------------*/

  FUNCTION fdiasafasttemp(pcdvinculo   IN INTEGER,
                          pdtiniciomes IN DATE,
                          pdtfimmes    IN DATE,
                          pdtcalculo   IN DATE,
                          pcdmotivo    IN INTEGER DEFAULT NULL)

   RETURN INTEGER IS

    vnudiasafast INTEGER;

  BEGIN
 
    SELECT nvl(SUM(diaafastado), 0) AS nudiaafast
      INTO vnudiasafast
      FROM (SELECT cdvinculo, dtdia AS dtdiaafastado, 1 AS diaafastado
              FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                      FROM dual
                    CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                               pdtInicioMes AND pdtFimMes) D
             INNER JOIN (SELECT cdVinculo,
                               CASE
                                 WHEN av.dtinicio < pdtiniciomes THEN
                                  pdtiniciomes
                                 ELSE
                                  av.dtinicio
                               END AS dtinicio,
                               CASE
                                 WHEN (AV.dtFim > pdtFimMes OR
                                      AV.DtFim IS NULL) THEN
                                  pdtfimmes
                                 ELSE
                                  av.dtfim
                               END AS dtfim
                          FROM eafaafastamentovinculo av
                         INNER JOIN eafamotivoafasttemporario mat
                            ON AV.CdMotivoAfastTemporario =
                               MAT.CdMotivoAfastTemporario
                         INNER JOIN eafahistmotivoafasttemp hmat
                            ON MAT.CdMotivoAfastTemporario =
                               HMAT.CdMotivoAfastTemporario
                         WHERE av.cdvinculo = pcdvinculo
                              -- MOTIVO DE AFASTAMENTO ESPECIFICO SE PASSADO COMO PARAMETRO
                           AND AV.Cdmotivoafasttemporario = CASE
                                 WHEN pCdMotivo IS NOT NULL THEN
                                  pCdMotivo
                                 ELSE
                                  AV.Cdmotivoafasttemporario
                               END
                           AND av.dtinicio <= pdtfimmes
                           AND (AV.DtFim >= pdtInicioMes OR AV.DtFim IS NULL)
                           AND hmat.dtiniciovigencia <= pdtcalculo
                           AND (HMAT.DtFimVigencia >= pdtCalculo OR
                               HMAT.DtFimVigencia IS NULL)
                           AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
                           AND AV.FlAnulado = PKGPAG_TIPO.cnN) B
                ON (B.DtInicio <= D.DtDia)
               AND (B.DtFim >= D.DtDia)) A;

    IF to_char(pdtfimmes, 'MM') = 2 THEN

      IF (to_char(pdtfimmes, 'DD') = '28' AND vnudiasafast = 28) OR
         (to_char(pdtfimmes, 'DD') = '29' AND vnudiasafast = 29) THEN

        RETURN 30;

      ELSE

        RETURN vnudiasafast;

      END IF;

    ELSE

      IF vnudiasafast > 30 THEN

        RETURN 30;

      ELSE

        RETURN vnudiasafast;

      END IF;

    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
  --
  -- Funcao: FDiasLicPremio
  /*----------------------------------------------------------------------------*/

  FUNCTION fdiaslicpremio(pcdvinculo           IN INTEGER,
                          pnuanoreferencia     IN INTEGER,
                          pnumesreferencia     IN INTEGER,
                          pcdtipolicencapremio IN INTEGER,
                          pCdSituacaoPerAquis  IN INTEGER) RETURN INTEGER IS

    vqtdias INTEGER;

  BEGIN
 
    SELECT SUM(qtdias)
      INTO vqtdias
      FROM eafalicencapremio lp
     INNER JOIN eafaperiodoaquisitivolp pa
        ON lp.cdperiodoaquisitivo = pa.cdperiodoaquisitivo
     WHERE PA.CdVinculo = pCdVinculo
       AND LP.CdSitFruicaoLicencaPremio = pCdSituacaoPerAquis
       AND PA.CdTipoLicencaPremio = pCdTipoLicencaPremio
       AND ((LP.NuAnoPagamento < pNuAnoReferencia) OR
           (LP.NuAnoPagamento = pNuAnoReferencia AND
           LP.NuMesPagamento <= pNuMesReferencia))
       AND NVL(LP.QtDiasPagos, 0) = 0
       AND LP.NuMesPago IS NULL;

    RETURN vqtdias;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
  --
  -- Funcao: FDiasAfastGravidez
  /*----------------------------------------------------------------------------*/

  FUNCTION fdiasafastgravidez(pcdvinculo   IN INTEGER,
                              pdtiniciomes IN DATE,
                              pdtfimmes    IN DATE,
                              pdtcalculo   IN DATE,
                              prubrica     IN pkgpag_tipo.rrubrica DEFAULT NULL)

   RETURN pkgpag_tipo.rafastgravidez IS

    vafastgravidez  pkgpag_tipo.rafastgravidez;
    vlistaafasttemp VARCHAR(500);

    --
    -- EPAGRI. Incluida verificacao do motivo de afastamento exigido na contagem dos dias
    -- Para situacao com 2 tipos de afastamentos e restringir aos dias de cada um.
    --

  BEGIN
 
    IF pRubrica.lsMotAfastTempEx.COUNT > 0 THEN
      FOR i IN pRubrica.lsMotAfastTempEx.FIRST .. pRubrica.lsMotAfastTempEx.LAST LOOP

        vListaAfastTemp := NVL(vListaAfastTemp, '') || pRubrica.lsMotAfastTempEx(i).cdmotivoafasttemporario || ',';

      END LOOP;

      vListaAfastTemp := SUBSTR(vListaAfastTemp,
                                1,
                                LENGTH(vListaAfastTemp) - 1);

      SELECT MIN(a.dtinicioafast),
             MIN(a.dtinclusao),
             nvl(SUM(a.diaafastado), 0) AS nudiaafast
        INTO vafastgravidez.dtinicio,
             vafastgravidez.dtinclusao,
             vafastgravidez.nudias
        FROM (SELECT CdVinculo,
                     dtDia         AS DtDiaAfastado,
                     1             AS DiaAfastado,
                     DtInicioAfast,
                     DtInclusao
                FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                        FROM dual
                      CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                 pdtInicioMes AND pdtFimMes) D
               INNER JOIN (SELECT cdVinculo,
                                 CASE
                                   WHEN av.dtinicio < pdtiniciomes THEN
                                    pdtiniciomes
                                   ELSE
                                    av.dtinicio
                                 END AS dtinicio,
                                 CASE
                                   WHEN (AV.dtFim > pdtFimMes OR
                                        AV.DtFim IS NULL) THEN
                                    pdtfimmes
                                   ELSE
                                    av.dtfim
                                 END AS dtfim,
                                 av.dtinclusao,
                                 av.dtinicio AS dtinicioafast
                            FROM eafaafastamentovinculo av
                           INNER JOIN eafamotivoafasttemporario mat
                              ON AV.CdMotivoAfastTemporario =
                                 MAT.CdMotivoAfastTemporario
                           INNER JOIN eafahistmotivoafasttemp hmat
                              ON MAT.CdMotivoAfastTemporario =
                                 HMAT.CdMotivoAfastTemporario
                           WHERE av.cdvinculo = pcdvinculo
                             AND hmat.flgravidez = pkgpag_tipo.cns
                             AND av.dtinicio <= pdtfimmes
                             AND (AV.DtFim >= pdtInicioMes OR
                                 AV.DtFim IS NULL)
                             AND hmat.dtiniciovigencia <= pdtcalculo
                             AND (HMAT.DtFimVigencia >= pdtCalculo OR
                                 HMAT.DtFimVigencia IS NULL)
                             AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
                             AND AV.FlAnulado = PKGPAG_TIPO.cnN
                             AND AV.Cdmotivoafasttemporario IN
                                 (SELECT to_number(column_value)
                                    FROM TABLE(FSPLIT(vListaAfastTemp)))) B
                  ON (B.DtInicio <= D.DtDia)
                 AND (B.DtFim >= D.DtDia)) A
       INNER JOIN ecadvinculo v
          ON a.cdvinculo = v.cdvinculo
       INNER JOIN ecadpessoa p
          ON v.cdpessoa = p.cdpessoa
       WHERE V.CdVinculo = pCdVinculo
         AND P.FlSexo = 'F';

      IF nvl(vgnudiasafastgravidez, 0) > 0 AND
         (NVL(vgNuDiasAfastGravidez, 0) + vAfastGravidez.NuDias) > 30 THEN

        vafastgravidez.nudias := 30 - nvl(vgnudiasafastgravidez, 0);

      END IF;

    ELSE

      SELECT MIN(a.dtinicioafast),
             MIN(a.dtinclusao),
             nvl(SUM(a.diaafastado), 0) AS nudiaafast
        INTO vafastgravidez.dtinicio,
             vafastgravidez.dtinclusao,
             vafastgravidez.nudias
        FROM (SELECT CdVinculo,
                     dtDia         AS DtDiaAfastado,
                     1             AS DiaAfastado,
                     DtInicioAfast,
                     DtInclusao
                FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                        FROM dual
                      CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                 pdtInicioMes AND pdtFimMes) D
               INNER JOIN (SELECT cdVinculo,
                                 CASE
                                   WHEN av.dtinicio < pdtiniciomes THEN
                                    pdtiniciomes
                                   ELSE
                                    av.dtinicio
                                 END AS dtinicio,
                                 CASE
                                   WHEN (AV.dtFim > pdtFimMes OR
                                        AV.DtFim IS NULL) THEN
                                    pdtfimmes
                                   ELSE
                                    av.dtfim
                                 END AS dtfim,
                                 av.dtinclusao,
                                 av.dtinicio AS dtinicioafast
                            FROM eafaafastamentovinculo av
                           INNER JOIN eafamotivoafasttemporario mat
                              ON AV.CdMotivoAfastTemporario =
                                 MAT.CdMotivoAfastTemporario
                           INNER JOIN eafahistmotivoafasttemp hmat
                              ON MAT.CdMotivoAfastTemporario =
                                 HMAT.CdMotivoAfastTemporario
                           WHERE AV.CdVinculo = pCdVinculo
                             AND HMAT.FlGravidez = PKGPAG_TIPO.cnS
                             AND AV.DtInicio <= pdtFimMes
                             AND (AV.DtFim >= pdtInicioMes OR
                                 AV.DtFim IS NULL)
                             AND HMAT.DtInicioVigencia <= pdtCalculo
                             AND (HMAT.DtFimVigencia >= pdtCalculo OR
                                 HMAT.DtFimVigencia IS NULL)
                             AND HMAT.FlAnulado = PKGPAG_TIPO.cnN
                             AND AV.FlAnulado = PKGPAG_TIPO.cnN) B
                  ON (B.DtInicio <= D.DtDia)
                 AND (B.DtFim >= D.DtDia)) A
       INNER JOIN ecadvinculo v
          ON a.cdvinculo = v.cdvinculo
       INNER JOIN ecadpessoa p
          ON v.cdpessoa = p.cdpessoa
       WHERE V.CdVinculo = pCdVinculo
         AND P.FlSexo = 'F';

    END IF;

    IF to_number(to_char(pdtfimmes, 'MM')) = 2 THEN

      IF (to_char(pdtfimmes, 'DD') = '28' AND vafastgravidez.nudias = 28) OR
         (to_char(pdtfimmes, 'DD') = '29' AND vafastgravidez.nudias = 29) THEN

        vafastgravidez.nudias := 30;

      END IF;

    ELSE

      IF vafastgravidez.nudias > 30 THEN

        vafastgravidez.nudias := 30;

      END IF;

    END IF;

    vgNuDiasAfastGravidez := NVL(vgNuDiasAfastGravidez, 0) +
                             vAfastGravidez.NuDias;

    RETURN vafastgravidez;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN vafastgravidez;

  END;

  FUNCTION fretornavalorrubrica(pcdfolhapagamento    IN INTEGER,
                                pcdvinculo           IN INTEGER,
                                pcdrubrica           IN INTEGER,
                                pnusufixo            IN INTEGER DEFAULT 1,
                                pcdtipoorigemrubrica IN INTEGER DEFAULT NULL)

   RETURN NUMBER IS

    vvlrubrica NUMBER(13, 2);

  BEGIN
 
    SELECT vlpagamento
      INTO vvlrubrica
      FROM epaghistoricorubricavinculo hrv
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo
       AND HRV.CdRubricaAgrupamento = pCdRubrica
       AND HRV.NuSufixoRubrica = pNuSufixo
       AND (HRV.CdTipoOrigemRubrica = pCdTipoOrigemRubrica OR
           pCdTipoOrigemRubrica IS NULL)
       AND ROWNUM < 2;

    RETURN vvlrubrica;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fretornasomavalorrubricasupl(pcdfolhapagamento     IN INTEGER,
                                        pcdvinculo            IN INTEGER,
                                        pcdrubricaagrupamento IN INTEGER)

   RETURN NUMBER IS

    vvlrubricaagrup NUMBER(13, 2);
    vAnoMes         INTEGER;
    vCdOrgao        INTEGER;

  BEGIN
 
    vvlrubricaagrup := 0;

    SELECT f.nuanomesreferencia, f.cdorgao
      INTO vAnoMes, vCdOrgao
      FROM epagFolhaPagamento f
     WHERE f.cdfolhapagamento = pcdfolhapagamento;

    -- essa query teve o plano fixado pelo Victor em 11/02/2022
    -- sql id: 6zduu1k49a615
    SELECT SUM(hrv.vlpagamento)
      INTO vvlrubricaagrup
      FROM epaghistoricorubricavinculo hrv
     WHERE hrv.cdvinculo = pcdvinculo
       AND hrv.cdrubricaagrupamento = pcdrubricaagrupamento
       AND hrv.cdfolhapagamento IN
           (SELECT cdFolhaPagamento
              FROM epagFolhaPagamento fol
             WHERE fol.nuanomesreferencia = vAnoMes
               AND fol.cdorgao = vCdOrgao
               AND fol.cdtipocalculo = pkgpag_tipo.cnTpCalculoSupl
               AND fol.flcalculodefinitivo = 'S');

    IF vvlrubricaagrup > 0 THEN
      RETURN vvlrubricaagrup;

    ELSE
      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fretornasomavalorrubrica(pdtinicio      IN DATE,
                                    pdtfim         IN DATE,
                                    pcdvinculo     IN INTEGER,
                                    pcdrubrica     IN INTEGER,
                                    pcdtipofolha   IN INTEGER DEFAULT 1,
                                    pcdtipocalculo IN INTEGER DEFAULT 1)

   RETURN NUMBER IS

    vvlrubrica NUMBER(13, 2);

  BEGIN
 
    SELECT sum(vlpagamento)
      INTO vvlrubrica
      FROM epaghistoricorubricavinculo hrv
     INNER JOIN epagfolhapagamento fpag
        ON fpag.cdfolhapagamento = hrv.cdfolhapagamento
       AND fpag.flcalculodefinitivo = 'S'
     INNER JOIN epagtipofolhapagamento tfp
        on fpag.cdtipofolhapagamento = tfp.cdtipofolhapagamento
     WHERE HRV.CdVinculo = pCdVinculo
       AND tfp.cdtipofolha = pcdtipofolha
       AND fpag.cdtipocalculo = pcdtipocalculo
       AND HRV.CdRubricaAgrupamento = pCdRubrica
       AND fpag.dtcalculo BETWEEN pdtinicio AND pdtfim;

    IF vvlrubrica > 0 THEN
      RETURN vvlrubrica;

    ELSE
      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  --
  -- Retorna se recebeu rubrica conforme em Folha Definitiva conforme parametros diferentes da folha atual
  --
  FUNCTION frecebeurubrica(pcdvinculo     IN INTEGER,
                           pcdrubrica     IN INTEGER,
                           pnuanomes      IN CHAR,
                           pnumeses       IN INTEGER DEFAULT 0,
                           pcdtipocalculo IN INTEGER DEFAULT NULL,
                           pcdtipofolha   IN INTEGER DEFAULT NULL,
                           pcdfolhaatual  IN INTEGER DEFAULT NULL)

   RETURN NUMBER IS

    vcount       INTEGER;
    vDtIni       DATE := to_date(pNuAnoMes || '01', 'YYYYMMDD');
    vnuanomesini CHAR(6) := to_char(add_months(vdtini, -pnumeses), 'YYYYMM');

  BEGIN
 
    SELECT COUNT(hrv.cdhistoricorubricavinculo)
      INTO vcount
      FROM epaghistoricorubricavinculo hrv
     INNER JOIN epagfolhapagamento fp
        ON fp.cdfolhapagamento = hrv.cdfolhapagamento
     WHERE hrv.cdvinculo = pcdvinculo
       AND hrv.cdrubricaagrupamento = pcdrubrica
       AND fp.cdfolhapagamento <> pcdfolhaatual
       AND fp.nuanomesreferencia BETWEEN vnuanomesini AND pnuanomes
       AND FP.CdTipoFolhaPagamento = CASE
             WHEN pCdTipoFolha IS NOT NULL THEN
              pCdTipoFolha
             ELSE
              FP.Cdtipofolhapagamento
           END
       AND FP.CdTipoCalculo = CASE
             WHEN pCdTipoCalculo IS NOT NULL THEN
              pCdTipoCalculo
             ELSE
              FP.CdtipoCalculo
           END
       AND fp.flcalculodefinitivo = pkgpag_tipo.cns;

    IF SQL%NOTFOUND OR vCount = 0 THEN
      RETURN - 1;
    END IF;

    RETURN vcount;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN - 1;

  END;

  FUNCTION fretornaindicerubrica(pcdfolhapagamento IN INTEGER,
                                 pcdvinculo        IN INTEGER,
                                 pcdrubrica        IN INTEGER,
                                 pnusufixo         IN INTEGER DEFAULT 1,
                                 psomaindice       IN BOOLEAN DEFAULT FALSE,
                                 pData             in date default null)

   RETURN NUMBER IS

    vvlindice NUMBER(13, 4);

    vCdFolha integer;

  BEGIN
 
    if pData is not null then

      begin
        select f.cdfolhapagamento
          into vCdFolha
          from epagfolhapagamento f
         where f.cdtipofolhapagamento =
               pkgpag_var.vgFolha.CdTipoFolhaPagamento
           and f.cdtipocalculo = pkgpag_var.vgFolha.CdTipoCalculo
           and f.cdorgao = pkgpag_var.vgFolha.cdorgao
           and f.flcalculodefinitivo = pkgpag_tipo.cnS
           and f.nuanomesreferencia = to_char(pData, 'yyyymm');

      exception
        when others then
          return 0;

      end;

    else

      vCdFolha := pcdfolhapagamento;

    end if;

    IF NOT (pSomaIndice) THEN

      SELECT vlindicerubrica
        INTO vvlindice
        FROM epaghistoricorubricavinculo hrv
       WHERE HRV.CdFolhaPagamento = vCdFolha
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubrica
         AND HRV.NuSufixoRubrica = pNuSufixo
         AND ROWNUM < 2;
    ELSE
      SELECT SUM(nvl(vlindicerubrica, 0))
        INTO vvlindice
        FROM epaghistoricorubricavinculo hrv
       WHERE HRV.CdFolhaPagamento = vCdFolha
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubrica;

    END IF;

    RETURN vvlindice;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FRetornaRubricaOutroTipo
     Objetivo: Retorna a mesma rubrica com outro tipo para o agrupamento 
         Nota: Caso nao seja encontrada a rubrica, ou exista mais de uma
               rubrica que atenda aos parametros informados e retornado o
               valor '0'
  /-----------------------------------------------------------------------------*/
  FUNCTION FRetornaRubricaOutroTipo (pCdAgrupamento   IN INTEGER,
                                     pNuAnoReferencia IN INTEGER,
                                     pNuMesReferencia IN INTEGER,
                                     pCdRubrica       IN INTEGER,
                                     pCdTipoRubrica   IN INTEGER) RETURN INTEGER IS

    vCdRubricaAgrupamento INTEGER;

  BEGIN

    SELECT RA.CdRubricaAgrupamento
      INTO vCdRubricaAgrupamento
      FROM EpagRubricaAgrupamento RA
     INNER JOIN EPagRubrica R
        ON R.CdRubrica = RA.CdRubrica
     INNER JOIN EPagHistRubricaAgrupamento HRA
        ON HRA.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
     WHERE RA.CdAgrupamento = pCdAgrupamento
       AND R.CdTipoRubrica = pCdTipoRubrica
       AND ((HRA.Nuanoiniciovigencia < pNuAnoReferencia OR
           (HRA.Nuanoiniciovigencia = pNuAnoReferencia AND
           HRA.Numesiniciovigencia <= pNuMesReferencia)) AND
           (HRA.NuAnoFimVigencia > pNuAnoReferencia OR
           (HRA.NuAnoFimVigencia = pNuAnoReferencia AND
           HRA.NuMesFimVigencia >= pNuMesReferencia) OR
           HRA.NuAnoFimVigencia IS NULL))
       AND R.NuRubrica =
           (SELECT NuRubrica
              FROM epagRubrica R1
             INNER JOIN EPagRubricaAgrupamento RA1
                ON R1.CdRubrica = RA1.CdRubrica
             WHERE RA1.CdRubricaAgrupamento = pCdRubrica);

    RETURN vCdRubricaAgrupamento;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FRetornaRubricaOutroTipo (pTabRubrica      IN TYPENUMBER,
                                     pNuAnoReferencia IN INTEGER,
                                     pNuMesReferencia IN INTEGER,
                                     pCdTipoRubrica   IN INTEGER) RETURN TYPENUMBER IS

    vCdRubricaAgrupamento INTEGER;

    vTabRubResult   TYPENUMBER;

  BEGIN
     vTabRubResult := TYPENUMBER();
      
     FOR REC IN (SELECT RAS.CdRubricaAgrupamento
                     
                   FROM TABLE (pTabRubrica) T
                  
                  INNER JOIN EPagRubricaAgrupamento RA1
                     ON T.COLUMN_VALUE = RA1.CdRubricaAgrupamento
              
                  INNER JOIN EPAGRubrica R1
                     ON R1.CdRubrica = RA1.Cdrubrica 
                     
                  INNER JOIN EPAGRubrica RS
                     ON RS.NuRubrica = R1.NuRubrica
                    AND RS.CdTipoRubrica = pCdTipoRubrica
                    
                  INNER JOIN EPAGRubricaAgrupamento RAS
                     ON RAS.CdRubrica = RS.CdRubrica
                    AND RAS.CdAgrupamento = RA1.CdAgrupamento
               
                  INNER JOIN EPagHistRubricaAgrupamento HRA
                     ON HRA.CdRubricaAgrupamento = RAS.CdRubricaAgrupamento
                    AND (HRA.Nuanoiniciovigencia < pNuAnoReferencia
                         OR(HRA.Nuanoiniciovigencia = pNuAnoReferencia AND HRA.Numesiniciovigencia <= pNuMesReferencia)
                         ) 
                    AND (HRA.NuAnoFimVigencia > pNuAnoReferencia 
                         OR (HRA.NuAnoFimVigencia = pNuAnoReferencia AND HRA.NuMesFimVigencia >= pNuMesReferencia) 
                         OR  HRA.NuAnoFimVigencia IS NULL
                         ) ) LOOP
                         
      vTabRubResult.EXTEND;
      vTabRubResult(vTabRubResult.LAST) := rec.CdRubricaAgrupamento;                             

   END LOOP;
   
   RETURN vTabRubResult;

  END;

  --------------------------------------------------------------------------
  -- Retorna o codigo da rubrica associada a um determinado tipo de evento
  --------------------------------------------------------------------------

  FUNCTION fretornacodigorubrica(pcdagrupamento         IN INTEGER,
                                 pcdtipoeventopagamento IN INTEGER,
                                 pflrubricaalternativa  IN CHAR DEFAULT 'N')
    RETURN INTEGER IS

    vcdrubricaagrupamento INTEGER;

  BEGIN
 
    SELECT CASE
             WHEN pflrubricaalternativa <> pkgpag_tipo.cns THEN
              epa.cdrubricaagrupamento
             ELSE
              epa.cdrubagrupoprecebcco
           END
      INTO vcdrubricaagrupamento
      FROM epageventopagagrup epa
     WHERE EPA.CdAgrupamento = pCdAgrupamento
       AND EPA.CdTipoEventoPagamento = pCdTipoEventoPagamento;

    RETURN vcdrubricaagrupamento;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  PROCEDURE pinserelog(pinsere                  IN BOOLEAN DEFAULT TRUE,
                       pcdhistoricoparamcalculo IN INTEGER,
                       pcdpessoa                IN INTEGER,
                       pdelog                   IN VARCHAR2,
                       pcdvinculo               IN INTEGER DEFAULT NULL,
                       pcdtipoocorrencia        IN INTEGER DEFAULT 1,
                       pcdmotivoocorrencia      IN INTEGER DEFAULT NULL) IS

    -- pCdTipoOcorrencia :
    -- 1 - Erro
    -- 2 - Observacoes

    PRAGMA AUTONOMOUS_TRANSACTION;

  BEGIN
 
    IF pinsere THEN

      INSERT INTO EPagLogProcessamento
        (Cdlogprocessamento,
         cdhistoricoparamcalculo,
         cdpessoa,
         delog,
         cdvinculo,
         cdtipoocorrencia,
         cdmotivoocorrencia,
         cdfolhapagamento)
      VALUES
        (sPagLogProcessamento.Nextval,
         pcdhistoricoparamcalculo,
         pcdpessoa,
         pdelog,
         pcdvinculo,
         pcdtipoocorrencia,
         pcdmotivoocorrencia,
         pkgpag_var.vgfolha.cdfolhapagamento);

      COMMIT;

    END IF;

  END;

  FUNCTION fretornadiasdomes(pdtfimmes           IN DATE,
                             pflpropmescomercial IN CHAR)

   RETURN INTEGER IS

  BEGIN
 
    IF pflpropmescomercial = 'N' THEN

      RETURN to_number(to_char(pdtfimmes, 'DD'));

    ELSE

      RETURN 30;

    END IF;

  END;

  FUNCTION fretornadiasdomesrv(pdtfimmes           IN DATE,
                               pflpropmescomercial IN CHAR)

   RETURN INTEGER IS

  BEGIN
 
    IF pflpropmescomercial = 'N' THEN

      RETURN to_number(to_char(pdtfimmes, 'DD'));

    ELSE

      RETURN 30;

    END IF;

  END;

  /*-----------------------------------------------------------------------------------------
     Procedure: FCalculaValorPropDias

      Objetivo: Calcula o valor integral referente aos dias em que a relacao
                de vinculo

  /*-----------------------------------------------------------------------------------------*/
  FUNCTION fcalculavalorpropdias(pflpropservrelvinc IN CHAR,
                                 pvlpropdias        IN NUMBER,
                                 pdiasmes           IN INTEGER,
                                 pDiasNivelRef      IN INTEGER) RETURN NUMBER IS

  BEGIN
 
    IF pflpropservrelvinc = 'S' THEN

      RETURN(pdiasnivelref * pvlpropdias) / pdiasmes;

    ELSE

      RETURN pvlpropdias;

    END IF;

  END;

  /*-----------------------------------------------------------------------------------------
        Funcao: FCalculaValorProp

      Objetivo: Calcula o valor proporcional referente aos dias em que a
                relacao de vinculo

  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fcalculavalorprop(pflpropservrelvinc IN CHAR,
                             pvlproporcional    IN NUMBER,
                             pnudiasmes         IN INTEGER,
                             pdtinicio          IN DATE,
                             pdtFim             IN DATE) RETURN NUMBER IS

    vdiasnivelref INTEGER;

  BEGIN
 
    IF pflpropservrelvinc = 'S' THEN

      vdiasnivelref := (pdtfim - pdtinicio) + 1;

      IF vdiasnivelref >= pnudiasmes OR
         vdiasnivelref = to_number(last_day(pdtinicio), 'DD') THEN

        RETURN pvlproporcional;

      END IF;

      RETURN(vdiasnivelref * pvlproporcional) / pnudiasmes;

    ELSE

      RETURN pvlproporcional;

    END IF;

  EXCEPTION

    WHEN zero_divide THEN

      RETURN 0;

  END;

  /*-----------------------------------------------------------------------------------------
     Procedure: FRetornaIndice

      Objetivo: Retorna o numero de dias em que a relacao esteve no Mes de
                referencia

  /*-----------------------------------------------------------------------------------------*/
  FUNCTION fretornaindice(pflpropmescomercial IN CHAR,
                          pdtiniciomes        IN DATE,
                          pdtfimmes           IN DATE,
                          pdtinicio           IN DATE,
                          pdtfim              IN DATE)

   RETURN INTEGER IS

    vvlindice INTEGER;

  BEGIN
 
    IF pflpropmescomercial = 'S' THEN

      IF (pdtinicio = pdtiniciomes) AND (pdtfim = pdtfimmes) THEN

        vvlindice := 30;

      ELSIF (pdtInicio > pdtInicioMes) OR
            (pdtFim <= pDtFimMes OR pdtFim IS NULL) THEN

        -- Inicio e fim no mes
        IF to_char(pdtiniciomes, 'MM') = '02'
          -- Inclusao para verificar desligado no mes de fevereiro que estava somando 2 dias.
           AND (pkgpag_var.vgvinculo.dtdesligamento IS NULL OR
                pkgpag_var.vgvinculo.dtdesligamento = pdtfimmes) THEN

          --
          -- Se nao tem desligamento no mes e tem outra relacao, para a primeira relacao
          -- nao somar os dias para fechar o mes comercial e retornar o indice sem alteracao.
          --
          IF NOT (pkgpag_var.vgvinculo.dtdesligamento IS NULL AND
              pDtFim < pdtFimMes) THEN

            IF TO_CHAR(pdtFimMes, 'DD') = '28' THEN
              vvlindice := (pdtfim - pdtinicio) + 3;
            ELSIF to_char(pdtfimmes, 'DD') = '29' THEN
              vvlindice := (pdtfim - pdtinicio) + 2;
            END IF;
          ELSE

            vvlindice := (pdtfim - pdtinicio) + 1;

          END IF;

        ELSIF (pdtInicio > pdtInicioMes) AND pdtFim = pDtFimMes AND
              TO_CHAR(pDtFimMes, 'DD') = '31' THEN

          vvlindice := (pdtfim - pdtinicio);

        ELSE

          vvlindice := (pdtfim - pdtinicio) + 1;

        END IF;

      else
        null;
      END IF;

    ELSE

      vvlindice := (pdtfim - pdtinicio) + 1;

    END IF;

    RETURN vvlindice;

  END;

  PROCEDURE pexcluirubricas(pcdfolhapagamento   IN INTEGER,
                            pcdvinculo          IN INTEGER,
                            pinpagamentorubrica IN CHAR) IS

  BEGIN
 
    --1 - As rubricas associadas devem ser pagas

    IF pinpagamentorubrica = '1' THEN

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND hrv.cdrubricaagrupamento NOT IN
             (SELECT ra.cdrubricaagrupamento
                FROM epagrubricaagrupamento ra
               INNER JOIN epagrubrica r
                  ON ra.cdrubrica = r.cdrubrica
               WHERE R.CdTipoRubrica = PKGPAG_TIPO.cnTpRubTotalizadora
                 AND RA.CdAgrupamento = PKGPAG_VAR.vgFolha.CdAgrupamento
              UNION ALL
              SELECT ra.cdrubricaagrupamento
                FROM epagfolhapagamento fp
               INNER JOIN epaghisttipofolhapagamento htfp
                  ON fp.cdtipofolhapagamento = htfp.cdtipofolhapagamento
               INNER JOIN epagtipofolharubrica fr
                  ON HTFP.CdHistTipoFolhaPagamento =
                     FR.cdHistTipoFolhaPagamento
               INNER JOIN epagrubricaagrupamento ra
                  ON fr.cdrubricaagrupamento = ra.cdrubricaagrupamento
              /*INNER JOIN epageventopagagrup epa
                 ON ra.cdrubricaagrupamento = epa.cdrubricaagrupamento
              INNER JOIN epaghisteventopagagrup hep
                 ON epa.cdeventopagagrup = hep.cdeventopagagrup*/
               WHERE HTFP.InPagamentoRubrica = pInPagamentoRubrica
                 AND ((HTFP.NuAnoInicioVigencia < FP.NuAnoReferencia OR
                     (htfp.nuanoiniciovigencia = fp.nuanoreferencia AND
                     HTFP.NumesInicioVigencia <= FP.NuMesReferencia)) AND
                     (htfp.nuanofimvigencia > fp.nuanoreferencia OR
                     (htfp.nuanofimvigencia = fp.nuanoreferencia AND
                     htfp.numesfimvigencia >= fp.numesreferencia) OR
                     htfp.nuanofimvigencia IS NULL))
                    /*AND
                    ((HEP.NuAnorefinicial < FP.NuAnoReferencia OR
                               (hep.nuanorefinicial = fp.nuanoreferencia AND
                    HEP.NuMesrefinicial <= FP.NuMesReferencia))
                    AND
                               (hep.nuanoreffinal > fp.nuanoreferencia OR
                               (hep.nuanoreffinal = fp.nuanoreferencia AND
                               hep.numesreffinal >= fp.numesreferencia) OR
                     HEP.NuAnoRefFinal IS NULL))*/
                 AND FP.CdFolhaPagamento = pcdFolhaPagamento);

      -- 2 - Apenas as rubricas associadas nao devem ser pagas.
    ELSIF pinpagamentorubrica = '2' THEN

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND hrv.cdrubricaagrupamento IN
             (SELECT ra.cdrubricaagrupamento
                FROM epagfolhapagamento fp
               INNER JOIN epaghisttipofolhapagamento htfp
                  ON fp.cdtipofolhapagamento = htfp.cdtipofolhapagamento
               INNER JOIN epagtipofolharubrica fr
                  ON HTFP.CdHistTipoFolhaPagamento =
                     FR.cdHistTipoFolhaPagamento
               INNER JOIN epagrubricaagrupamento ra
                  ON fr.cdrubricaagrupamento = ra.cdrubricaagrupamento
              /*INNER JOIN epageventopagagrup epa
                 ON ra.cdrubricaagrupamento = epa.cdrubricaagrupamento
              INNER JOIN epaghisteventopagagrup hep
                 ON epa.cdeventopagagrup = hep.cdeventopagagrup*/
               WHERE HTFP.InPagamentoRubrica = pInPagamentoRubrica
                 AND ((HTFP.NuAnoInicioVigencia < FP.NuAnoReferencia OR
                     (htfp.nuanoiniciovigencia = fp.nuanoreferencia AND
                     HTFP.NuMesInicioVigencia <= FP.NuMesReferencia)) AND
                     (htfp.nuanofimvigencia > fp.nuanoreferencia OR
                     (htfp.nuanofimvigencia = fp.nuanoreferencia AND
                     htfp.numesfimvigencia >= fp.numesreferencia) OR
                     htfp.nuanofimvigencia IS NULL))
                    /*AND
                    ((HEP.NuAnorefinicial < FP.NuAnoReferencia OR
                           (hep.nuanorefinicial = fp.nuanoreferencia AND
                    HEP.NuMesrefinicial <= FP.NuMesReferencia))
                    AND
                           (hep.nuanoreffinal > fp.nuanoreferencia OR
                           (hep.nuanoreffinal = fp.nuanoreferencia AND
                           hep.numesreffinal >= fp.numesreferencia) OR
                     HEP.NuAnoRefFinal IS NULL))*/
                 AND FP.CdFolhaPagamento = pcdFolhaPagamento);

    else
      null;
    END IF;

  END;

  PROCEDURE pexcluivaloreszerados(pcdfolhapagamento IN INTEGER,
                                  pcdvinculo        IN INTEGER) IS

  BEGIN
 
    if (pkgpag_var.vgFolha.numesreferencia >= 8 AND
       pkgpag_var.vgFolha.nuanoreferencia = 2020) or
       (pkgpag_var.vgFolha.nuanoreferencia > 2020) then

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.VlPagamento = 0
         AND hrv.cdrubricaagrupamento not in
             (nvl(PKGPAG_VAR.vgCdRubricaBaseCsgLiq, 0),
              nvl(pkgpag_var.vgCdRubricaBaseConsig, 0),
              nvl(pkgpag_var.vgCdRubBaseCsgMargFut, 0),
              nvl(pkgpag_var.vgCdRubBaseCsgLiqOutros, 0),
              nvl(pkgpag_var.vgCdRubBaseCsgBrutaOutros, 0));
      -- A 09-1007 - Margem consignavel liquida deve ser gravada no contracheque com valor zero
      -- SIG-5142 Rubricas totalizadoras geradas nos contracheques com valor ZERO
    else

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.VlPagamento = 0;

    end if;

  END;

  PROCEDURE pexcluirubrica(pcdfolhapagamento        IN INTEGER,
                           pcdvinculo               IN INTEGER,
                           pcdrubrica               IN INTEGER,
                           pflexcluiambos           IN CHAR DEFAULT 'N',
                           pflpreservavalorintegral IN CHAR DEFAULT 'N') IS

  BEGIN
 
    IF pFlPreservaValorIntegral = PKGPAG_TIPO.cnS AND
       PKGPAG_VAR.bVinculoComCCO AND
       PKGPAG_VAR.vCdRelacaoRubImpeditiva <> 1 THEN

      -- Alterado para tambem anular a expressao da formula de calculo para evitar que posteriormente.
      -- a rubrica seja recalc
      UPDATE epaghistoricorubricarelvinc hrv
         SET HRV.VlProporcional = 0, HRV.Cdexpressaoformcalc = NULL
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubrica;

    ELSE

      DELETE FROM EPagHistoricoRubricaRelVinc HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubrica;

    END IF;

    IF pflexcluiambos = 'S' THEN

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubrica;

    END IF;

  END;

  PROCEDURE pexcluirubricasufixo(pcdfolhapagamento IN INTEGER,
                                 pcdvinculo        IN INTEGER,
                                 pcdrubrica        IN INTEGER,
                                 pnusufixo         IN INTEGER,
                                 pflexcluiambos    IN CHAR DEFAULT 'N') IS

  BEGIN
 
    DELETE FROM EPagHistoricoRubricaRelVinc HRV
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo
       AND HRV.CdRubricaAgrupamento = pCdRubrica
       AND HRV.NuSufixoRubrica = pNuSufixo;

    IF pflexcluiambos = 'S' THEN

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = pCdRubrica
         AND HRV.NuSufixoRubrica = pNuSufixo;

    END IF;

  END;

  PROCEDURE pexcluirpagorgao(pcdfolhapagamento IN INTEGER) IS

  BEGIN
 
    DELETE FROM EPagHistoricoRubricaRelVinc RV
     WHERE rv.cdfolhapagamento = pcdfolhapagamento;

    DELETE FROM EPagHistoricoRubricaVinculo RV
     WHERE rv.cdfolhapagamento = pcdfolhapagamento;

    DELETE FROM EPagCapaHistRubricaVinculo CV
     WHERE cv.cdfolhapagamento = pcdfolhapagamento;

  END;

  PROCEDURE pexcluircontrachequesPessoa (pCdOrgao              IN INTEGER,
                                         pCdPessoa             IN INTEGER,
                                         pNuAnoReferencia      IN Epagfolhapagamento.Nuanoreferencia%TYPE,
                                         pNuMesReferencia      IN Epagfolhapagamento.Numesreferencia%TYPE,
                                         pCdTipoFolhaPagamento IN Epagfolhapagamento.Cdtipofolhapagamento%TYPE,
                                         pCdTipoCalculo        IN Epagfolhapagamento.Cdtipocalculo%TYPE,
                                         pNuSequencialFolha    IN Epagfolhapagamento.Nusequencialfolha%TYPE) IS

  BEGIN

     FOR fp IN (SELECT fp.cdfolhapagamento
                  FROM epagfolhapagamento fp
                 WHERE fp.cdOrgao = pCdOrgao
                   AND fp.nuanoreferencia = pNuAnoReferencia
                   AND fp.numesreferencia = pNuMesReferencia
                   AND fp.cdtipofolhapagamento = pCdTipoFolhaPagamento
                   AND fp.cdtipocalculo = pCdTipoCalculo
                   AND fp.nusequencialfolha = pNuSequencialFolha
                   AND fp.flfolhafechada = 'N') LOOP
               
       DELETE FROM Epaghistoricorubricarelvinc HRV
        WHERE HRV.CdFolhaPagamento = fp.CdFolhaPagamento
          AND HRV.CdVinculo IN (SELECT CdVinculo
                                  FROM ECadVinculo
                                 WHERE CdPessoa = pCdPessoa);

       DELETE FROM EpaghistoricorubricaVinculo HRV
           WHERE HRV.CdFolhaPagamento = fp.CdFolhaPagamento
             AND HRV.CdVinculo IN (SELECT CdVinculo
                                     FROM ECadVinculo
                                    WHERE CdPessoa = pCdPessoa);

       DELETE FROM EPagCapaHistRubricaVinculo CV
           WHERE CV.CdFolhaPagamento = fp.CdFolhaPagamento
             AND CV.CdVinculo IN (SELECT CdVinculo
                                    FROM ECadVinculo
                                   WHERE CdPessoa = pCdPessoa);

     END LOOP;
     
  END;

  PROCEDURE pexcluircontrachequesvinculo(pCdVinculo            IN INTEGER,
                                         pNuAnoReferencia      IN Epagfolhapagamento.Nuanoreferencia%TYPE,
                                         pNuMesReferencia      IN Epagfolhapagamento.Numesreferencia%TYPE,
                                         pCdTipoFolhaPagamento IN Epagfolhapagamento.Cdtipofolhapagamento%TYPE,
                                         pCdTipoCalculo        IN Epagfolhapagamento.Cdtipocalculo%TYPE,
                                         pNuSequencialFolha    IN Epagfolhapagamento.Nusequencialfolha%TYPE) IS

  BEGIN
 
    DELETE FROM Epaghistoricorubricarelvinc HRV
     WHERE HRV.CdVinculo = pCdVinculo
       AND HRV.CdFolhaPagamento IN
           (

            SELECT fp.cdfolhapagamento
              FROM epagfolhapagamento fp
             WHERE fp.nuanoreferencia = pNuAnoReferencia
               AND fp.numesreferencia = pNuMesReferencia
               AND fp.cdtipofolhapagamento = pCdTipoFolhaPagamento
               AND fp.cdtipocalculo = pCdTipoCalculo
               AND fp.nusequencialfolha = pNuSequencialFolha
               AND fp.flfolhafechada = 'N'
            -- AND    fp.flcalculodefinitivo = 'N'

            );

    DELETE FROM EpaghistoricorubricaVinculo HRV
     WHERE HRV.CdVinculo = pCdVinculo
       AND HRV.CdFolhaPagamento IN
           (

            SELECT fp.cdfolhapagamento
              FROM epagfolhapagamento fp
             WHERE fp.nuanoreferencia = pNuAnoReferencia
               AND fp.numesreferencia = pNuMesReferencia
               AND fp.cdtipofolhapagamento = pCdTipoFolhaPagamento
               AND fp.cdtipocalculo = pCdTipoCalculo
               AND fp.nusequencialfolha = pNuSequencialFolha
               AND fp.flfolhafechada = 'N'
            -- AND    fp.flcalculodefinitivo = 'N'

            );

    DELETE FROM EPagCapaHistRubricaVinculo CV
     WHERE CV.CdVinculo = pCdVinculo
       AND CV.CdFolhaPagamento IN
           (

            SELECT fp.cdfolhapagamento
              FROM epagfolhapagamento fp
             WHERE fp.nuanoreferencia = pNuAnoReferencia
               AND fp.numesreferencia = pNuMesReferencia
               AND fp.cdtipofolhapagamento = pCdTipoFolhaPagamento
               AND fp.cdtipocalculo = pCdTipoCalculo
               AND fp.nusequencialfolha = pNuSequencialFolha
               AND fp.flfolhafechada = 'N'
            -- AND    fp.flcalculodefinitivo = 'N'

            );

  END;

  PROCEDURE pexcluirpagvinc(pcdfolhapagamento IN INTEGER,
                            pcdvinculo        IN INTEGER) IS
  BEGIN

    DELETE FROM Epaghistoricorubricarelvinc HRV
     WHERE HRV.CdFolhaPagamento = pcdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo;
       
    DELETE FROM EpaghistoricorubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pcdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo;

    DELETE FROM EPagCapaHistRubricaVinculo CV
     WHERE CV.CdFolhapagamento = pCdFolhaPagamento
       AND CV.CdVinculo = pCdVinculo;

  END;

  PROCEDURE pexcluirpagpessoa(pcdfolhapagamento IN INTEGER,
                              pcdpessoa         IN INTEGER) IS
  BEGIN

    DELETE FROM Epaghistoricorubricarelvinc HRV
     WHERE HRV.CdFolhaPagamento = pcdFolhaPagamento
       AND HRV.CdVinculo IN
           (SELECT CdVinculo FROM ECadVinculo WHERE CdPessoa = pCdPessoa);

    DELETE FROM EpaghistoricorubricaVinculo HRV
     WHERE HRV.CdFolhaPagamento = pcdFolhaPagamento
       AND HRV.CdVinculo IN
           (SELECT CdVinculo FROM ECadVinculo WHERE CdPessoa = pCdPessoa);

    DELETE FROM EPagCapaHistRubricaVinculo CV
     WHERE CV.CdFolhapagamento = pCdFolhaPagamento
       AND CV.CdVinculo IN
           (SELECT CdVinculo FROM ECadVinculo WHERE CdPessoa = pCdPessoa);

  END;

  /*----------------------------------------------------------------------------
     Funcao: FValorNivelRefGeralAgrup

   Objetivo: Retorna os valores gerais de niveis e referencias para o agrupamento
             e a carga horaria padrao.

       Nota: A carga horaria pode estar definida em algum nivel da carreira
             passada como parametro, seja no Orgao ou no Agrupamento. Inicialmente e
             feita a busca na tabela de valores do Orgao e caso nao encontre,
             realiza a busca na tabela de valores do Agrupamento.
  /*--------------------------------------------------------------------------*/

  FUNCTION FValorNivelRefGeralAgrup(pTipoTabelaCEF       IN PKGPAG_TIPO.rTipoTabelaCEF,
                                    pCdEstruturaCarreira IN INTEGER)
    RETURN pkgpag_tipo.tvalorfixo IS

    CURSOR cvalorfixo(pcdhistvalorgeralcefagrup IN INTEGER) IS
      SELECT pcdestruturacarreira AS cdestruturacarreira,
             v.nunivel,
             v.nureferencia,
             v.vlfixo,
             NULL,
             v.dtultalteracao,
             ptipotabelacef.cdvalorgeralcefagrup
        FROM epagvalorespeccefagrup v
       WHERE v.cdhistvalorgeralcefagrup = pcdhistvalorgeralcefagrup;

    vvalorfixo      pkgpag_tipo.tvalorfixo;
    vnucargahoraria NUMBER(7, 4);
    bachoucho       BOOLEAN;
    vcdestrutura    INTEGER;

  BEGIN
 
    -- Busca a carga horaria no historico de nivel e referencia da
    -- carreira no Orgao. Se nao encontrar, busca a carga horaria
    -- no historico de nivel e referencia da carreira no Agrupamento

    bachoucho := FALSE;

    vcdestrutura := fexistecarreira(pcdestruturacarreira);

    IF pkgpag_var.vgcarreira(vcdestrutura).nucargahoraria IS NOT NULL THEN

      bachoucho := TRUE;

      vnucargahoraria := pkgpag_var.vgcarreira(vcdestrutura).nucargahoraria;

    END IF;

    IF NOT bachoucho THEN

      WHILE vcdestrutura IS NOT NULL LOOP

        BEGIN

          SELECT nucargahorariapadrao
            INTO vnucargahoraria
            FROM epaghistnivelrefcarrceforgao hno
           WHERE HNO.CdHistNivelRefCEFOrgao =
                 pTipoTabelaCEF.CdHistNivelRefCEFOrgao
             AND HNO.CdEstruturaCarreira = vCdEstrutura;

          IF vnucargahoraria > 0 THEN

            bachoucho := TRUE;

            pkgpag_var.vgcarreira(pcdestruturacarreira).nucargahoraria := vnucargahoraria;

            EXIT;

          END IF;

        EXCEPTION

          WHEN OTHERS THEN

            bachoucho := FALSE;

        END;

        vcdestrutura := fproxcarreira(vcdestrutura);

      END LOOP;

    END IF;
    --

    IF NOT bachoucho THEN

      vcdestrutura := fexistecarreira(pcdestruturacarreira);

      WHILE vcdestrutura IS NOT NULL LOOP

        BEGIN

          SELECT nucargahorariapadrao
            INTO vnucargahoraria
            FROM epaghistnivelrefcarrcefagrup hna
           WHERE HNA.CdHistNivelRefCEFAgrup =
                 pTipoTabelaCEF.CdHistNivelRefCEFAgrup
             AND HNA.CdEstruturaCarreira = vCdEstrutura;

          IF vnucargahoraria > 0 THEN

            bachoucho := TRUE;

            pkgpag_var.vgcarreira(pcdestruturacarreira).nucargahoraria := vnucargahoraria;

            EXIT;

          END IF;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN
            bachoucho := FALSE;

          WHEN OTHERS THEN

            NULL;

        END;

        vcdestrutura := fproxcarreira(vcdestrutura);

      END LOOP;

      IF NOT bachoucho THEN

        vnucargahoraria := 0;

        pkgpag_var.vgcarreira(pcdestruturacarreira).nucargahoraria := vnucargahoraria;

      END IF;

    END IF;

    OPEN cvalorfixo(ptipotabelacef.cdhistnivelrefcefgeral);

    FETCH cValorFixo BULK COLLECT
      INTO vValorFixo;

    IF vvalorfixo.count > 0 THEN

      FOR i IN vValorFixo.FIRST .. vValorFixo.LAST LOOP

        vvalorfixo(i).nucargahoraria := vnucargahoraria;

      END LOOP;

    END IF;

    CLOSE cvalorfixo;

    RETURN vvalorfixo;

  END;

  /*----------------------------------------------------------------------------
     Funcao: FValorNivelRefAgrup

   Objetivo: Retorna os valores de niveis e referencias das carreiras
             para o agrupamento
  /*--------------------------------------------------------------------------*/

  FUNCTION fvalornivelrefagrup(pcdhistnivelrefcef IN INTEGER)
    RETURN pkgpag_tipo.tvalorfixo IS

    CURSOR cvalorfixo(pcdhistnivelrefcef IN INTEGER) IS
      SELECT h.cdestruturacarreira,
             v.nunivel,
             v.nureferencia,
             v.vlfixo,
             h.nucargahorariapadrao,
             v.dtultalteracao,
             0
        FROM epaghistnivelrefcarrcefagrup h
       INNER JOIN epagvalorcarreiracefagrup v
          ON h.cdhistnivelrefcarrcefagrup = v.cdhistnivelrefcarrcefagrup
       WHERE h.cdhistnivelrefcefagrup = pcdhistnivelrefcef;

    vvalorfixo pkgpag_tipo.tvalorfixo;

  BEGIN
 
    OPEN cvalorfixo(pcdhistnivelrefcef);

    FETCH cValorFixo BULK COLLECT
      INTO vValorFixo;

    CLOSE cvalorfixo;

    RETURN vvalorfixo;

  END;

  /*----------------------------------------------------------------------------
     Funcao: FValorNivelRefOrgao

   Objetivo: Retorna os valores de niveis e referencias das carreiras
             para o orgao
  /*--------------------------------------------------------------------------*/

  FUNCTION fvalornivelreforgao(pcdhistnivelrefcef IN INTEGER)

   RETURN pkgpag_tipo.tvalorfixo IS

    CURSOR cvalorfixo(pcdhistnivelrefcef IN INTEGER) IS
      SELECT cdestruturacarreira,
             v.nunivel,
             v.nureferencia,
             v.vlfixo,
             h.nucargahorariapadrao,
             v.dtultalteracao,
             0
        FROM epaghistnivelrefcarrceforgao h
       INNER JOIN epagvalornivelrefceforgao v
          ON h.cdhistnivelrefcarrceforgao = v.cdhistnivelrefcarrceforgao
       WHERE h.cdhistnivelrefceforgao = pcdhistnivelrefcef;

    vvalorfixo pkgpag_tipo.tvalorfixo;

  BEGIN
 
    OPEN cvalorfixo(pcdhistnivelrefcef);

    FETCH cValorFixo BULK COLLECT
      INTO vValorFixo;

    CLOSE cvalorfixo;

    RETURN vvalorfixo;

  END;

  /*------------------------------------------------------------------------------/
     Funcao: FTabelaValorGeral

   Objetivo: Retorna o codigo do historico (vigencia) da tabela geral do agrupamento

  /*------------------------------------------------------------------------------*/

  FUNCTION ftabelavalorgeral(pcdtabgeral IN INTEGER,
                             pnuversao   IN INTEGER,
                             pnuano      IN INTEGER,
                             pNuMes      IN INTEGER) RETURN INTEGER IS

    vcdhistvalorgeralcefagrup INTEGER;

  BEGIN
 
    SELECT cdhistvalorgeralcefagrup
      INTO vcdhistvalorgeralcefagrup
      FROM (SELECT hvga.cdhistvalorgeralcefagrup
              FROM epagvalorgeralcefagrup vga
             INNER JOIN epagvalorgeralcefagrupversao nvga
                ON vga.cdvalorgeralcefagrup = nvga.cdvalorgeralcefagrup
             INNER JOIN epaghistvalorgeralcefagrup hvga
                ON NVGA.CdValorGeralCEFAgrupVersao =
                   HVGA.CdValorGeralCEFAgrupVersao
             WHERE NVGA.NuVersao IN (pNuVersao, PKGPAG_TIPO.cn1)
               AND NVGA.CdValorGeralCEFAgrup = pCdTabGeral
               AND ((HVGA.NuAnoiniciovigencia < pNuAno OR
                   (hvga.nuanoiniciovigencia = pnuano AND
                   HVGA.NuMesiniciovigencia <= pNuMes)) AND
                   (hvga.nuanofimvigencia > pnuano OR
                   (hvga.nuanofimvigencia = pnuano AND
                   hvga.numesfimvigencia >= pnumes) OR
                   hvga.nuanofimvigencia IS NULL))
             ORDER BY nvga.nuversao DESC)
     WHERE rownum < 2;

    RETURN vcdhistvalorgeralcefagrup;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

    WHEN too_many_rows THEN

      RETURN 0;

  END ftabelavalorgeral;

  /*--------------------------------------------------------------------------
     Funcao: FTipoTabelaCEF

   Objetivo: Retorna registro com as tabelas de valores para cargos efetivos
             de acordo com o ano/mes de processamento,orgao, versao e
             estrutura de carreira passados como parametro.

             Quando a tabela de valores utilizada e a Geral do Agrupamento, e
             necessario buscar tambem os codigos dos historicos das tabelas
             no agrupamento e no orgao, que serao utilizados para encontrar
             o valor da carga horaria padrao.

             1) Busca o valor do campo InTabelaUtilizada da tabela de valores
                do Agrupamento
             2) Se InTabelaUtilizada = 3, busca a definicao na tabela de
                valores do Orgao

    Retorno: Registro contendo:
             - o tipo de tabela utilizada
             - o codigo do historico da tabela de valores gerais do agrupamento
             - o codigo do historico da tabela de valores no agrupamento
             - o codigo do historico da tabela de valores no orgao

        Obs: Caso nao seja encontrada a tabela de valores para os parametros
             informados, o atributo InTabelaUtilizada sera = '0'
  --------------------------------------------------------------------------------*/
  FUNCTION ftipotabelacef(pcdagrupamento       IN INTEGER,
                          pcdorgao             IN INTEGER,
                          pnuversao            IN INTEGER,
                          pnuano               IN INTEGER,
                          pnumes               IN INTEGER,
                          pcdestruturacarreira IN INTEGER)
    RETURN pkgpag_tipo.rtipotabelacef IS
    /*------------------------------------------------------------------------------*/

    TYPE rTipoTabela IS RECORD(
      InTabelaUtilizada    CHAR(1),
      cdhistnivelrefcef    INTEGER,
      cdvalorgeralcefagrup INTEGER);

    vtptabcef pkgpag_tipo.rtipotabelacef;
    vtptab    rtipotabela;

    /*------------------------------------------------------------------------------*/
    FUNCTION FTabelaValorAgrup RETURN rTipoTabela IS
      /*------------------------------------------------------------------------------*/

      vtptabagrup rtipotabela;

    BEGIN
 
      SELECT intabelautilizada,
             cdhistnivelrefcefagrup,
             cdvalorgeralcefagrup
        INTO vtptabagrup
        FROM (SELECT hnra.intabelautilizada,
                     hnra.cdhistnivelrefcefagrup,
                     hnra.cdvalorgeralcefagrup
                FROM epagnivelrefcefagrup nra
               INNER JOIN epagnivelrefcefagrupversao nrav
                  ON nra.cdnivelrefcefagrup = nrav.cdnivelrefcefagrup
               INNER JOIN epaghistnivelrefcefagrup hnra
                  ON NRAV.CdNivelRefCEFAgrupVersao =
                     HNRA.cdNivelRefCEFAgrupVersao
               INNER JOIN ecadestruturacarreira ec
                  ON EC.CdAgrupamento = NRA.CdAgrupamento
                 AND EC.CdEstruturaCarreira = NRA.CdEstruturaCarreira
               WHERE NRA.CdAgrupamento = pCdAgrupamento
                 AND NRAV.NuVersao IN (pNuVersao, PKGPAG_TIPO.cn1)
                 AND EC.CdEstruturaCarreira = pCdEstruturaCarreira
                 AND ((HNRA.NuAnoInicioVigencia < pNuAno OR
                     (hnra.nuanoiniciovigencia = pnuano AND
                     HNRA.NuMesInicioVigencia <= pNuMes)) AND
                     (hnra.nuanofimvigencia > pnuano OR
                     (hnra.nuanofimvigencia = pnuano AND
                     hnra.numesfimvigencia >= pnumes) OR
                     hnra.nuanofimvigencia IS NULL))
               ORDER BY nrav.nuversao DESC)
       WHERE rownum < 2;

      RETURN vtptabagrup;

    EXCEPTION

      WHEN no_data_found THEN
        RETURN NULL;

      WHEN too_many_rows THEN
        RETURN NULL;

    END ftabelavaloragrup;

    /*------------------------------------------------------------------------------*/
    FUNCTION FTabelaValorOrgao RETURN rTipoTabela IS
      /*------------------------------------------------------------------------------*/

      vtptaborgao rtipotabela;

    BEGIN
 
      SELECT hnro.intabelautilizada,
             hnro.cdhistnivelrefceforgao,
             hnro.cdvalorgeralcefagrup
        INTO vtptaborgao
        FROM epagnivelrefceforgao nro
       INNER JOIN epagnivelrefceforgaoversao nrov
          ON nro.cdnivelrefceforgao = nrov.cdnivelrefceforgao
       INNER JOIN epaghistnivelrefceforgao hnro
          ON nrov.cdnivelrefceforgaoversao = hnro.cdnivelrefceforgaoversao
       INNER JOIN ecadestruturacarreira ec
          ON ec.cdestruturacarreira = nro.cdestruturacarreira
       INNER JOIN ecadorgao o
          ON O.CdOrgao = NRO.CdOrgao
         AND O.CdAgrupamento = EC.CdAgrupamento
       WHERE O.CdOrgao = pCdOrgao
         AND NROV.NuVersao IN (pNuVersao, PKGPAG_TIPO.cn1)
         AND EC.CdEstruturaCarreira = pcdEstruturaCarreira
         AND ((HNRO.NuAnoInicioVigencia < pNuAno OR
             (hnro.nuanoiniciovigencia = pnuano AND
             HNRO.NuMesInicioVigencia <= pNuMes)) AND
             (hnro.nuanofimvigencia > pnuano OR
             (hnro.nuanofimvigencia = pnuano AND
             hnro.numesfimvigencia >= pnumes) OR
             hnro.nuanofimvigencia IS NULL));

      RETURN vtptaborgao;

    EXCEPTION

      WHEN no_data_found THEN
        RETURN NULL;

      WHEN too_many_rows THEN
        RETURN NULL;

    END ftabelavalororgao;

  BEGIN
 
    -- Busca a tabela de valores no agrupamento

    vtptab := ftabelavaloragrup;

    -- Se a tabela de valores utilizada e a de valores gerais

    IF vtptab.intabelautilizada = '1' THEN

      vtptabcef.cdvalorgeralcefagrup := vtptab.cdvalorgeralcefagrup;

      vtptabcef.cdhistnivelrefcefagrup := vtptab.cdhistnivelrefcef;

      vtptabcef.cdhistnivelrefcefgeral := ftabelavalorgeral(vtptab.cdvalorgeralcefagrup,
                                                            pNuVersao,
                                                            pNuAno,
                                                            pnumes);

      IF vtptabcef.cdhistnivelrefcefgeral > 0 THEN

        vtptabcef.cdtabelautilizada := 1;

        -- Busca a tabela de valores no orgao

        vtptab := ftabelavalororgao;

        vtptabcef.cdhistnivelrefceforgao := vtptab.cdhistnivelrefcef;

        RETURN vtptabcef;

      ELSE

        vtptabcef.cdtabelautilizada := 0;

        RETURN vtptabcef;

      END IF;

    ELSIF vtptab.intabelautilizada = '2' THEN

      vtptabcef.cdtabelautilizada := 2;

      vtptabcef.cdhistnivelrefcefagrup := vtptab.cdhistnivelrefcef;

      RETURN vtptabcef;

    ELSIF vtptab.intabelautilizada = '3' THEN

      vtptab := ftabelavalororgao;

      IF vtptab.intabelautilizada = '1' THEN

        vtptabcef.cdvalorgeralcefagrup := vtptab.cdvalorgeralcefagrup;

        vtptabcef.cdhistnivelrefceforgao := vtptab.cdhistnivelrefcef;

        vtptabcef.cdhistnivelrefcefgeral := ftabelavalorgeral(vtptab.cdvalorgeralcefagrup,
                                                              pnuversao,
                                                              pNuAno,
                                                              pNuMes);

        IF vtptabcef.cdhistnivelrefcefgeral > 0 THEN

          /*    vTpTab := FTabelaValorAgrup;*/

          vtptabcef.cdtabelautilizada := 1;

          /*  vTpTabCEF.CdValorGeralCEFAgrup   := vTpTab.CdValorGeralCEFAgrup;

          vTpTabCEF.CdHistNivelRefCefAgrup := vTpTab.CdHistNivelRefCef;*/

          RETURN vtptabcef;

        ELSE

          vtptabcef.cdtabelautilizada := 0;

          RETURN vtptabcef;

        END IF;

      ELSE

        vtptabcef.cdtabelautilizada := 3;

        vtptabcef.cdhistnivelrefceforgao := vtptab.cdhistnivelrefcef;

        RETURN vtptabcef;

      END IF;

    ELSIF vtptab.intabelautilizada IS NULL THEN

      vtptabcef.cdtabelautilizada := 0;

      RETURN vtptabcef;

    else
      null;
    END IF;

  EXCEPTION

    WHEN no_data_found THEN

      vtptabcef.cdtabelautilizada := 0;

      RETURN vtptabcef;

  END;

  FUNCTION fretonavalorfixotab(pnuversaotab           IN INTEGER,
                               pnuanoreferencia       IN INTEGER,
                               pnumesreferencia       IN INTEGER,
                               pcdvalorgeralcefagrup  IN INTEGER,
                               pnunivelpagamento      IN VARCHAR2,
                               pnureferenciapagamento IN VARCHAR2)
    RETURN NUMBER IS

    vvlfixo NUMBER(13, 2);

  BEGIN
 
    SELECT vlfixo
      INTO vvlfixo
      FROM (SELECT VE.VLFIXo
              FROM epagvalorgeralcefagrupversao nvga
             INNER JOIN epaghistvalorgeralcefagrup hvga
                ON NVGA.CdValorGeralCEFAgrupVersao =
                   HVGA.CdValorGeralCEFAgrupVersao
             INNER JOIN epagvalorespeccefagrup ve
                ON VE.CdHistValorGeralCEFAgrup =
                   HVGA.CdHistValorGeralCEFAgrup
               AND VE.NuNivel = pNuNivelPagamento
               AND VE.NuReferencia = pNuReferenciaPagamento
             WHERE NVGA.NuVersao IN (pNuVersaoTab, PKGPAG_TIPO.cn1)
               AND NVGA.CdValorGeralCEFAgrup = pCdValorGeralCEFAgrup
               AND ((HVGA.NuAnoiniciovigencia < pNuAnoReferencia OR
                   (hvga.nuanoiniciovigencia = pnuanoreferencia AND
                   HVGA.NuMesiniciovigencia <= pNuMesReferencia)) AND
                   (hvga.nuanofimvigencia > pnuanoreferencia OR
                   (hvga.nuanofimvigencia = pnuanoreferencia AND
                   hvga.numesfimvigencia >= pnumesreferencia) OR
                   hvga.nuanofimvigencia IS NULL))
             ORDER BY nvga.nuversao DESC)
     WHERE rownum < 2;

    RETURN vvlfixo;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  /*-----------------------------------------------------------------------------------------
       Funcao: FRetonaValorNivelRefCEF

     Objetivo: Retornar o valor  com o valor fixo de acordo com a tabela de valores passada
               como parametro
   Argumentos:
  -----------------------------------------------------------------------------------------*/
  FUNCTION fretonavalorfixocef(pcdagrupamento               IN INTEGER,
                               pcdorgao                     IN INTEGER,
                               pnuversaotabcef              IN INTEGER,
                               pnuanoreferencia             IN INTEGER,
                               pnumesreferencia             IN INTEGER,
                               pcdestruturacarreira         IN INTEGER,
                               pcdestruturacarreiracarreira IN INTEGER,
                               pnunivelpagamento            IN VARCHAR2,
                               pnureferenciapagamento       IN VARCHAR2)
    RETURN pkgpag_tipo.rvalorfixo IS

    vcdestrutura INTEGER;
    i            INTEGER;
    bachouvalor  BOOLEAN;
    vvalorfixo   pkgpag_tipo.tvalorfixo;
    vtptabcef    pkgpag_tipo.rtipotabelacef;
    vCdEstruturaPai integer;

  FUNCTION fbuscacarreirapai(pcdestruturacarreira     IN INTEGER) RETURN integer IS

    vcdcarreirapai INTEGER;

  BEGIN
 
      select ec.cdestruturacarreirapai
           into vcdcarreirapai
           from ecadestruturacarreira ec
          where cdestruturacarreira = pcdestruturacarreira
            and rownum < 2;

      return vcdcarreirapai;

      exception
           when others then
             return null;

    END;

    FUNCTION fbuscavalor RETURN pkgpag_tipo.rvalorfixo IS

    vCdCarreiraPai integer;

    vNuCargaHorariaPai NUMBER(7, 4);

    BEGIN
 
      bachouvalor := FALSE;

      vCdCarreiraPai := fbuscacarreirapai(pcdestruturacarreira);

      vcdestrutura := fexistecarreira(pcdestruturacarreira);

      WHILE vcdestrutura IS NOT NULL LOOP

        i := 1;

        WHILE (NOT bAchouValor) AND (i < (vValorFixo.COUNT + 1)) LOOP

          if vNuCargaHorariaPai is null and vvalorfixo(i).cdestruturacarreira = vCdCarreiraPai then
             vNuCargaHorariaPai := vValorFixo(i).NuCargaHoraria;
          end if;

          IF pnunivelpagamento = vvalorfixo(i).nunivel AND
             pnureferenciapagamento = vvalorfixo(i).nureferencia AND
             vcdestrutura = vvalorfixo(i).cdestruturacarreira THEN

            bachouvalor := TRUE;

            -- SIG-9023 DPE-SC - FOLHA NOVEMBRO - reducao jornada de trabalho
            -- Quando nao encontrar carga horaria da carreira busca no PAI para proporcionalizar corretamente
            if vValorFixo(i).NuCargaHoraria is null and pkgpag_var.vgFolha.CdOrgao = 443 then
               vValorFixo(i).NuCargaHoraria := vNuCargaHorariaPai;
            end if;

            RETURN vvalorfixo(i);

          END IF;

          i := i + 1;

        END LOOP;

        vcdestrutura := fproxcarreira(vcdestrutura);

      END LOOP;

      IF NOT bachouvalor THEN

        RETURN NULL;

      END IF;

    END fbuscavalor;

  BEGIN
 
    vTpTabCEF := FTipoTabelaCEF(pCdAgrupamento,
                                pCdOrgao,
                                pNuVersaoTabCEF,
                                pNuAnoReferencia,
                                pNuMesReferencia,
                                pcdestruturacarreiracarreira);

    IF vtptabcef.cdtabelautilizada <> 0 THEN

      bachouvalor := FALSE;

      IF vtptabcef.cdtabelautilizada = 1 THEN

        vvalorfixo := fvalornivelrefgeralagrup(vtptabcef,
                                               pcdestruturacarreira);

        IF vvalorfixo IS NOT NULL THEN

          i := 1;

          WHILE (NOT bachouvalor) AND (i < (vvalorfixo.count + 1))

           LOOP

            IF pnunivelpagamento = vvalorfixo(i).nunivel AND
               pnureferenciapagamento = vvalorfixo(i).nureferencia THEN

              bachouvalor := TRUE;

              RETURN vvalorfixo(i);

            END IF;

            i := i + 1;

          END LOOP;

          IF NOT bachouvalor THEN

            RETURN NULL;

          END IF;

        ELSE

          RETURN NULL;

        END IF;

      ELSIF vtptabcef.cdtabelautilizada = 2 THEN

        vvalorfixo := fvalornivelrefagrup(vtptabcef.cdhistnivelrefcefagrup);

        RETURN fbuscavalor;

      ELSIF vtptabcef.cdtabelautilizada = 3 THEN

        vvalorfixo := fvalornivelreforgao(vtptabcef.cdhistnivelrefceforgao);

        RETURN fbuscavalor;

      else
        null;
      END IF;

    ELSE

      RETURN NULL;

    END IF;

  END;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fretornavalorfixofuc(pcdpadraofucagrup IN INTEGER,
                                pcdagrupamento    IN INTEGER,
                                pcdorgao          IN INTEGER,
                                pnuversaotabfuc   IN INTEGER,
                                pnuanoreferencia  IN INTEGER,
                                pNuMesReferencia  IN INTEGER) RETURN NUMBER IS

    vvlfixo NUMBER(13, 2);

  BEGIN
 
    SELECT vlfixo
      INTO vvlfixo
      FROM (SELECT VFE.VlFixo
              FROM epagvalorreffucagruporgversao vf
             INNER JOIN epaghistvalorreffucagruporg hvf
                ON VF.CdValorRefFUCAgrupOrgVersao =
                   HVF.CdValorRefFUCAgrupOrgVersao
             INNER JOIN epagvalorreffucagruporgespec vfe
                ON HVF.CdHistValorRefFUCAgrupOrg =
                   VFE.CdHistValorRefFUCAgrupOrg
             WHERE VFE.CdPadraoFUCAgrup = pCdPadraoFucAgrup
               AND VF.NuVersao = pNuVersaoTabFUC
               AND (VF.CdAgrupamento = pCdAgrupamento OR
                   VF.cdOrgao = pCdOrgao)
               AND ((HVF.nuAnoInicioVigencia < pNuAnoReferencia OR
                   (hvf.nuanoiniciovigencia = pnuanoreferencia AND
                   HVF.nuMesInicioVigencia <= pNuMesReferencia)) AND
                   (hvf.nuanofimvigencia > pnuanoreferencia OR
                   (hvf.nuanofimvigencia = pnuanoreferencia AND
                   hvf.numesfimvigencia >= pnumesreferencia) OR
                   hvf.nuanofimvigencia IS NULL))
             ORDER BY vf.cdorgao, vf.cdagrupamento)
     WHERE rownum = 1;

    RETURN vvlfixo;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fretornavalorfixocco(pnucodigo          IN VARCHAR2,
                                pnunivel           IN VARCHAR2,
                                pcdrelacaotrabalho IN INTEGER,
                                pcdagrupamento     IN INTEGER,
                                pcdorgao           IN INTEGER,
                                pnuversaotabcco    IN INTEGER,
                                pnuanoreferencia   IN INTEGER,
                                pNuMesReferencia   IN INTEGER) RETURN NUMBER IS

    vvlfixo NUMBER(13, 2);

  BEGIN
 
    SELECT vlfixo
      INTO vvlfixo
      FROM (SELECT VCE.VlFixo
              FROM epagvalorrefccoagruporgversao vc
             INNER JOIN epaghistvalorrefccoagruporgver hvc
                ON VC.CdValorRefCCOAgrupOrgVersao =
                   HVC.CdValorRefCCOAgrupOrgVersao
             INNER JOIN epagvalorrefccoagruporgespec vce
                ON HVC.CdHistValorRefCCOAgrupOrgVer =
                   VCE.CdHistValorRefCCOAgrupOrgVer
             WHERE VCE.CdRelacaoTrabalho = pCdRelacaoTrabalho
               AND TRIM(VCE.NuNivel) = TRIM(pNuNivel)
               AND TRIM(VCE.NuCodigo) = TRIM(pNuCodigo)
               AND VC.NuVersao = NVL(pNuVersaoTabCCO, 1)
               AND (VC.CdAgrupamento = pCdAgrupamento OR
                   VC.cdOrgao = pCdOrgao)
               AND ((HVC.NuAnoiniciovigencia < pNuAnoReferencia OR
                   (hvc.nuanoiniciovigencia = pnuanoreferencia AND
                   HVC.NuMesiniciovigencia <= pNuMesReferencia)) AND
                   (hvc.nuanofimvigencia > pnuanoreferencia OR
                   (hvc.nuanofimvigencia = pnuanoreferencia AND
                   hvc.numesfimvigencia >= pnumesreferencia) OR
                   hvc.nuanofimvigencia IS NULL))
             ORDER BY vc.cdorgao, vc.cdagrupamento)
     WHERE rownum = 1;

    RETURN vvlfixo;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;
  END;

  FUNCTION facertardiasprop(pnudiasafast                IN INTEGER,
                            pnudiasmes                  IN INTEGER,
                            pdtiniciomes                IN DATE,
                            pdtfimmes                   IN DATE,
                            pdtfimrelacao               IN DATE,
                            pnudiastotal                IN INTEGER,
                            pbafastultdia               IN BOOLEAN,
                            pDtInicioRelacao            IN DATE DEFAULT NULL,
                            pFlPercentReducaoAfastRemun IN CHAR DEFAULT 'N')
    RETURN number IS

    vnudiasresult number;

  BEGIN
 
    -- Calcula dias considerados na proporcao
    vnudiasresult := greatest(0, pnudiastotal - pnudiasafast);

    vnudiasresult := least(least(vnudiasresult, pnudiasmes),
                           to_number(TO_CHAR(PKGPAG_VAR.vgFolha.dtfimmes,
                                             'DD')));

    -- Trata Fevereiro

    IF to_number(to_char(pdtiniciomes, 'MM')) = 2 AND vNuDiasResult < 30 AND
       NOT pbAfastUltDia AND pDtFimRelacao = pdtFimMes THEN
      vNuDiasResult := 30 -
                       (to_number(to_char(pDtFimMes, 'DD')) - vNuDiasResult);
      RETURN vnudiasresult;
    END IF;

    -- Trata Mes 31 Dias, para considerar 30 dias

    IF TO_CHAR(pdtFimMes, 'DD') = '31' AND pDtInicioRelacao = pDtInicioMes AND
       pDtFimRelacao = pdtFimMes AND
       ((vNuDiasResult > 0 AND vNuDiasResult < 30 AND NOT pbAfastUltDia AND
        pnudiastotal <> vNuDiasResult) --SIG-2449
        OR pNuDiasAfast = 1) THEN

      vnudiasresult := vnudiasresult - 1;

    END IF;

    -- #71332: Caso o cef esteja com disposicao/substotuicao, e o numero de dias da substituicao for maior que 0,
    -- nao permite que o vnudiasresult pago seja maior que 30 dias para as duas relacos.
    IF (PKGPAG_VAR.vgCEF.count > 0 AND PKGPAG_VAR.vgCEF(1).cdrelacaotrabalho = 10 AND
       PKGPAG_VAR.bVinculoComCCO AND
       PKGPAG_VAR.vPagaSitDisposicao = 'PAG-DEST-CALCULO-DEST' AND
       pFlPercentReducaoAfastRemun = 'S' AND PKGPAG_VAR.vgnudiassubst <> 0 AND
       vnudiasresult = 30) THEN

      vnudiasresult := vnudiasresult - PKGPAG_VAR.vgnudiassubst;

    END IF;

    RETURN vnudiasresult;

  END;

  FUNCTION FDtInicioComissao RETURN DATE IS
  BEGIN
 
    RETURN PKGPAG_VAR.vgDtInicioComissao(PKGPAG_VAR.vgPagCalc.nusufixorubrica);

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END;

  FUNCTION FDtFimComissao RETURN DATE IS
  BEGIN
 
    RETURN PKGPAG_VAR.vgDtFimComissao(PKGPAG_VAR.vgPagCalc.nusufixorubrica);

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END;

  /*-----------------------------------------------------------------------------------------
    Function: FCalculaProporcionalidadeCEF
    Objetivo: Aplicar sobre o valor integral a proporcionalidade dos dias e carga horaria

    Argumentos:

      pNuDiasMes - Numero de dias no mes. Caso a rubrica indique que o calculo e
                   baseado em mes comercial, o numero de dias utilizado e = 30.
  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fcalculaproporccef(pcef           IN pkgpag_tipo.rcef,
                              pnudiasmes     IN INTEGER,
                              prubrica       IN pkgpag_tipo.rrubrica,
                              pvalorintegral IN NUMBER,
                              pnucho         IN NUMBER,
                              pdtiniciomes   IN DATE,
                              pdtfimmes      IN DATE,
                              pdtcalculo     IN DATE,
                              peventocef     IN CHAR DEFAULT 'N')

   RETURN pkgpag_tipo.rvalorpagamento IS

    --vNuDiasCCO INTEGER;

    vNuDiasCCOSubst INTEGER;

    trotdata pkgafa.tabrotdata;

    vresult pkgpag_tipo.rvalorpagamento;

    --vVlCalculado pkgpag_tipo.rvalorpagamento;

    vnuchopadrao NUMBER(7, 4);

    vdtinicioperiodo DATE;

    vdtfimperiodo DATE;

    vdemensagem VARCHAR2(200) := '';

    vdtinicio DATE;

    vdtfim DATE;

    vnudiasintegral NUMBER;

    vnudiastotal NUMBER;

    vnudiasprop NUMBER;

    vnudiasafastp NUMBER;

    vnudiasafasti NUMBER;

    vnucho NUMBER(7, 4);

    btemafastultimodiai BOOLEAN;

    btemafastultimodiap BOOLEAN;

    btemdifcho BOOLEAN; -- Indica se possui mais de uma carga horaria dentro do mes

    --vvlsomachodias NUMBER(13, 2);

    --vvltotaldias INTEGER;

    vCdHistCargoEfetivo INTEGER;

    vnudiastotalImp INTEGER;

    vNuDiasImpNoMes INTEGER := 0;

    vDtInicioComissao DATE;

    vDtFimComissao DATE;

    vdata DATE;

    i INTEGER := 0;

    vnudiasafastemp INTEGER;

    vQtdDiasMes INTEGER;

  BEGIN
 
    IF pkgpag_geral.fretornarubrica(pkgpag_var.vgFolha.CdAgrupamento,
                                    1,
                                    403) = pRubrica.CdRubricaAgrupamento THEN

      vDtInicioComissao := fDtInicioComissao;

      vDtFimComissao := fDtFimComissao;

    END IF;

    IF vDtInicioComissao IS NOT NULL THEN
      vresult.vlindice := pkgpag_geral.fretornaindice(prubrica.flpropmescomercial,
                                                      pDtInicioMes,
                                                      pDtFimMes,
                                                      vDtInicioComissao,
                                                      vDtFimComissao);
    ELSE
      vresult.vlindice := pkgpag_geral.fretornaindice(prubrica.flpropmescomercial,
                                                      pDtInicioMes,
                                                      pDtFimMes,
                                                      pCEF.DtInicio,
                                                      pCEF.DtFim);
    END IF;

    vresult.vlreal := pvalorintegral;

    vresult.vlproporcional := pkgpag_geral.fcalculavalorpropdias(prubrica.flpropservrelvinc,
                                                                 pvalorintegral,
                                                                 pnudiasmes,
                                                                 vresult.vlindice);

    vresult.vlintegral := vresult.vlproporcional;

    IF prubrica.flpropservrelvinc = 'N' OR
       PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao THEN

      vdtinicio := pdtiniciomes;
      vdtfim    := pdtfimmes;

    ELSIF vDtInicioComissao IS NOT NULL THEN

      vdtinicio := vDtInicioComissao;
      vdtfim    := vDtFimComissao;

    ELSE

      vdtinicio := pcef.dtinicio;
      vdtfim    := pcef.dtfim;

    END IF;

    CASE

    -- Nao proporcionaliza por carga horaria e deduz Afastamentos
      WHEN prubrica.cdrubproporcionalidadecho = 1 THEN

        IF prubrica.flpropafasttempnaoremun = pkgpag_tipo.cns OR
           prubrica.flpropafacomissionado = pkgpag_tipo.cns THEN

          IF PKGPAG_VAR.vgFolha.CdTipoFolha <>
             PKGPAG_TIPO.cnTpFolhaInstPensao AND
             (pCEF.CdRelacaoTrabalho <> 10 OR
             (pCEF.CdRelacaoTrabalho = 10 AND pEventoCEF = 'N')) THEN

            pkgafa.protdatainicializar(NULL, vdtfim);

            i := 0;

            FOR reg IN (SELECT
                        --
                        -- Se a data de inicio do afastamento for menor que a do mes da folha considerar
                        -- somente o mes da folha
                        --
                         CASE
                           WHEN AV.DtInicio >= pdtInicioMes THEN
                            AV.DtInicio
                           ELSE
                            pdtInicioMes
                         END AS dtinicio,
                         av.dtfim,
                         CASE
                           WHEN av.dtinclusao > pkgpag_var.vdtcalculoant THEN -- E retroativo
                            1
                           ELSE
                            to_number(NULL)
                         END AS flretroativo,
                         case
                           when pRubrica.NuRubrica = 574 and
                                PKGPAG_VAR.vgFolha.CdAgrupamento = 1 and -- IRESA
                                hmat.flpartejornada = 'S' and
                                nvl(hmat.vlpercentreducaoiresa, 0) > 0 then
                            hmat.vlpercentreducaoiresa / 100
                           else
                            1
                         end AS diaafastadoprop1,
                         case
                           when pRubrica.NuRubrica = 574 and
                                PKGPAG_VAR.vgFolha.CdAgrupamento = 1 and -- IRESA
                                hmat.flpartejornada = 'S' and
                                nvl(hmat.vlpercentreducaoiresa, 0) > 0 then
                            hmat.vlpercentreducaoiresa / 100
                           else
                            1
                         end AS diaafastadointegral1
                          FROM eafaafastamentovinculo av
                         INNER JOIN eafahistmotivoafasttemp hmat
                            ON Av.CdMotivoAfastTemporario =
                               HMAT.CdMotivoAfastTemporario
                         INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                           MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                      FROM eafahistmotivoafasttemp hmatv
                                     WHERE HMATV.dtInicioVigencia <=
                                           pdtFimMes
                                       AND (hmatv.dtfimvigencia is null or
                                           trunc(hmatv.dtfimvigencia) >=
                                           trunc(pDtInicioMes))
                                     GROUP BY hmatv.cdmotivoafasttemporario) mv
                            ON HMAT.CdMotivoAfastTemporario =
                               MV.CdMotivoAfastTemporario
                           AND hmat.dtiniciovigencia = mv.dtiniciovigencia
                         WHERE pRubrica.FlPropAfastTempNaoRemun =
                               PKGPAG_TIPO.cnS
                           AND av.cdvinculo = pcef.cdvinculo
                           AND av.flanulado = pkgpag_tipo.cnn
                           AND ((av.dtinicio <= pdtfimmes AND
                               (AV.DtFim >= pdtInicioMes OR
                               AV.DtFim IS NULL)))
                           AND (HMAT.FlRemunerado = PKGPAG_TIPO.cnN OR
                               (pRubrica.InGeraRubricaAfastTemp = '1' AND
                               AV.CdMotivoAfastTemporario IN
                               (SELECT cdmotivoafasttemporario
                                    FROM epagrubagrupmotafasttempimp ai
                                   WHERE AI.CdMotivoAfastTemporario =
                                         AV.CdMotivoAfastTemporario
                                     AND AI.CdHistRubricaAgrupamento =
                                         pRubrica.CdHistRubrica
                                     AND NOT EXISTS
                                   (SELECT 1
                                            FROM epagrubagrpmotaftempimpvinc vi
                                           WHERE AI.Cdhistrubricaagrupamento =
                                                 VI.Cdhistrubricaagrupamento
                                             AND AI.CdMotivoAfastTemporario =
                                                 VI.CdMotivoAfastTemporario
                                             AND VI.CdVinculo = pCEF.CdVinculo))) OR
                               (pRubrica.InGeraRubricaAfastTemp = '2' AND
                               ((AV.CdMotivoAfastTemporario NOT IN
                               (SELECT cdmotivoafasttemporario
                                      FROM epagrubagrupmotafasttempimp ai
                                     WHERE AV.CdMotivoAfastTemporario =
                                           AI.CdMotivoAfastTemporario
                                       AND AI.CdHistRubricaAgrupamento =
                                           pRubrica.CdHistRubrica
                                       AND NOT EXISTS
                                     (SELECT 1
                                              FROM epagrubagrpmotaftempimpvinc vi
                                             WHERE AI.Cdhistrubricaagrupamento =
                                                   VI.Cdhistrubricaagrupamento
                                               AND AI.CdMotivoAfastTemporario =
                                                   VI.CdMotivoAfastTemporario
                                               AND VI.CdVinculo =
                                                   pCEF.CdVinculo))) OR
                               (SELECT COUNT(*)
                                     FROM epagrubagrupmotafasttempimp ai
                                    WHERE AI.CdHistRubricaAgrupamento =
                                          pRubrica.CdHistRubrica) = 0)))

                        UNION ALL

                        SELECT av.dtinicio,
                               av.dtfim,
                               CASE
                                 WHEN AV.DtInclusao >
                                      PKGPAG_VAR.vDtCalculoAnt THEN
                                  1
                                 ELSE
                                  to_number(NULL)
                               END AS flretroativo,
                               1 AS diaafastadoprop2,
                               1 AS diaafastadointegral2
                          FROM eafaafastamentovinculo av
                         INNER JOIN eafahistmotivoafastdef hmad
                            ON AV.CdMotivoAfastDefinitivo =
                               HMAD.CdMotivoAfastDefinitivo
                         INNER JOIN (SELECT HMADV.CdMotivoAfastDefinitivo,
                                           MAX(HMADV.DtInicioVigencia) AS DtInicioVigencia
                                      FROM eafahistmotivoafastdef hmadv
                                     WHERE HMADV.dtInicioVigencia <=
                                           pdtFimMes
                                     GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                            ON HMAD.CdMotivoAfastDefinitivo =
                               MV.CdMotivoAfastDefinitivo
                           AND hmad.dtiniciovigencia = mv.dtiniciovigencia
                         WHERE pRubrica.FlPropAfastTempNaoRemun =
                               PKGPAG_TIPO.cnS
                           AND AV.CdVinculo = pCEF.CdVinculo
                           AND AV.FlAnulado = PKGPAG_TIPO.cnN
                           AND HMAD.FlRemunerado = PKGPAG_TIPO.cnN
                           AND ((AV.DtInicio <= pdtFimMes AND
                               (AV.DtFim >= pdtInicioMes OR
                               AV.DtFim IS NULL)) OR (AV.DtInclusao BETWEEN
                               (PKGPAG_VAR.vDtCalculoAnt + 1) AND
                               pDtCalculo))

                        UNION ALL

                        SELECT CASE
                                 WHEN av.dtinicio < pdtiniciomes THEN
                                  pdtiniciomes
                                 ELSE
                                  av.dtinicio
                               END AS dtinicio,
                               CASE
                                 WHEN Av.DtFim > pDtFimMes OR
                                      Av.DtFim IS NULL THEN
                                  pdtfimmes
                                 ELSE
                                  av.dtfim
                               END AS dtfim,
                               CASE
                                 WHEN AV.DtInclusao >
                                      PKGPAG_VAR.vDtCalculoAnt THEN
                                  1
                                 ELSE
                                  to_number(NULL)
                               END AS flretroativo,
                               1 AS diaafastadoprop4,
                               NULL AS diaafastadointegral4
                          FROM eafaafastamentorelvinc av
                         WHERE pRubrica.FlPropAfaComissionado =
                               PKGPAG_TIPO.cnS
                           AND AV.CdHistCargoEfetivo = pCEF.CdHistRelVinc
                           AND AV.CdHistCargoComGerador IS NOT NULL
                           AND AV.FlAnulado = PKGPAG_TIPO.cnN
                           AND ((av.dtinicio <= pdtfimmes AND
                               (AV.Dtfim >= pdtInicioMes OR
                               AV.DtFim IS NULL)) OR (AV.DtInclusao BETWEEN
                               (PKGPAG_VAR.vDtCalculoAnt + 1) AND
                               pDtCalculo))
                           AND EXISTS
                         (SELECT 1
                                  FROM ecadhistcargocom hcc
                                 INNER JOIN (SELECT H.CdHistCargoCom,
                                                   MAX(H.DtInicioVigencia) AS DtInicioVigencia
                                              FROM ecadhistopcaoremuneracaocco h
                                             WHERE H.DtInicioVigencia <=
                                                   pdtFimMes
                                               AND (H.DtFimVigencia >=
                                                   pdtInicioMes OR
                                                   H.DtFimVigencia IS NULL)
                                             GROUP BY h.cdhistcargocom) hor1
                                    ON HCC.CdHistCargoCom =
                                       HOR1.CdHistCargoCom
                                 INNER JOIN ecadhistopcaoremuneracaocco hor
                                    ON HOR1.CdHistCargoCom =
                                       HOR.CdHistCargoCom
                                   AND HOR1.DtInicioVigencia =
                                       HOR.DtInicioVigencia
                                 WHERE HCC.CdHistCargoCom =
                                       AV.CdHistCargoComGerador
                                   AND hcc.flanulado = pkgpag_tipo.cnn
                                   and HCC.CdCargoComRemuneracao IS NULL
                                   AND NOT (PKGPAG_VAR.vgFolha.FlIgnoraInclusaoFutura = 'S' AND
                                        HCC.DtInclusao > pDtCalculo)
                                   AND ((hor.cdopcaoremuneracao = 3 AND
                                       NOT (HCC.FlTipoProvimento IN
                                        (PKGPAG_TIPO.cnS) AND
                                        pRubrica.FlPropAfaCCOSubst =
                                        PKGPAG_TIPO.cnN)) OR
                                       (pRubrica.FlPropAfaFgFtg =
                                       PKGPAG_TIPO.cnS AND
                                       HOR.CdOpcaoRemuneracao IN (6,9)) OR
                                       (pEventoCEF = PKGPAG_TIPO.cnN AND
                                       HCC.CdOpcaoRemuneracao = 2 AND
                                       pRubrica.FlPropAfaComOpcPercCEF = 'S')))) LOOP

              i := i + 1;
              -- FlTem1: Afastado Proporcional
              -- FlTem2: Afastado Integral
              -- FlTem3: Vigencia do Mes
              -- FlTem4: Retroativo

              IF pkgpag_var.vgFolha.cdorgao = 17 AND
                 prubrica.nurubrica = 574 THEN
                -- SIG-473
                -- Foi constatados na folha de novembro o pagamento integral da Indeniza??o por Regime Especial de Trabalho Policia Civil
                --  (c?digo 01-0574), durante afastamento remunerado

                pkgafa.protdatainserirdata(reg.dtinicio,
                                           case when reg.dtfim > pDtFimMes or
                                           reg.DtFim is null then pDtFimMes else
                                           reg.dtfim end,
                                           pfltem1      => reg.diaafastadoprop1,
                                           pfltem2      => reg.diaafastadointegral1,
                                           pFlTem3      => 1,
                                           pfltem4      => reg.flretroativo);
              ELSE
                pkgafa.protdatainserirdata(reg.dtinicio,
                                           reg.dtfim,
                                           pfltem1      => reg.diaafastadoprop1,
                                           pfltem2      => reg.diaafastadointegral1,
                                           pfltem4      => reg.flretroativo);
              END IF;

            END LOOP;

            IF pkgpag_var.vgFolha.cdorgao <> 17 OR
               (pkgpag_var.vgFolha.cdorgao = 17 AND
               prubrica.nurubrica <> 574) OR
               (pkgpag_var.vgFolha.cdorgao = 17 AND
               prubrica.nurubrica = 574 AND
               (i = 0 or (pkgpag_var.vgNuDiasAfastDefinitivo > 0 and
               pkgpag_var.vgNuDiasAfastDefinitivo <
               to_char(pDtFimMes, 'DD')))) THEN

              PKGAFA.PRotDataInserirData(vDtInicio, vDtFim, pFlTem3 => 1); -- Indica vigencia do mes
            END IF;

            pkgafa.protdatacalcular(trotdata);

            vnudiastotal        := 0;
            vnudiasafastp       := 0;
            vnudiasafasti       := 0;
            btemafastultimodiai := FALSE;
            btemafastultimodiap := FALSE;

            FOR reg IN trotdata.first .. trotdata.last LOOP

              -- Para a rubrica 01-0574, proporcionalizar os valores para afastamentos remunerados (Ex.: f?rias)
              IF pkgpag_var.vgFolha.cdorgao = 17 AND
                 prubrica.nurubrica = 574 AND i > 0 AND trotdata(reg).fltem3 IS NOT NULL THEN

                --vnudiasafastp  := vnudiasafastp + (tRotData (reg).DtFim - tRotData (reg).DtIni + 1);
                vNuDiasTotal := least(vNuDiasTotal +
                                      (PCEF.DtFim - PCEF.DtInicio + 1),
                                      31);

              ELSE
                -- soma dias totais
                IF trotdata(reg).fltem3 IS NOT NULL THEN
                  vNuDiasTotal := vNuDiasTotal + (least(tRotData(reg).DtFim - tRotData(reg).DtIni + 1,
                                                        30)); --(tRotData (reg).DtFim - tRotData (reg).DtIni + 1);
                END IF;
              END IF;

              IF tRotData(reg).DtFim = pDtFimMes /*AND TO_CHAR(pdtInicioMes, 'MM') = 2*/
               THEN

                IF trotdata(reg).fltem1 IS NOT NULL THEN

                  btemafastultimodiap := TRUE;

                END IF;

                IF trotdata(reg).fltem2 IS NOT NULL THEN

                  btemafastultimodiai := TRUE;

                END IF;

              END IF;

              -- Se afastamento proporcional (FlTem1) e retroativo/dentro do mes (FlTem4 ou FlTem3)
              IF tRotData(reg).FlTem1 IS NOT NULL AND
                  (tRotData(reg).FlTem4 IS NOT NULL OR tRotData(reg).FlTem3 IS NOT NULL) THEN
                vNuDiasAfastP := vNuDiasAfastP +
                                 (least(tRotData(reg).DtFim - tRotData(reg).DtIni + 1,
                                        30) * nvl(tRotData(reg).FlTem1, 1));
              END IF;

              IF tRotData(reg).FlTem2 IS NOT NULL AND
                  (tRotData(reg).FlTem4 IS NOT NULL OR tRotData(reg).FlTem3 IS NOT NULL) THEN
                vNuDiasAfastI := vNuDiasAfastI +
                                 (least(tRotData(reg).DtFim - tRotData(reg).DtIni + 1,
                                        30) * nvl(tRotData(reg).FlTem2, 1));
              END IF;

            END LOOP;

            -- acerta valores
            vnudiasprop := facertardiasprop(pnudiasafast                => vnudiasafastp,
                                            pnudiasmes                  => pnudiasmes,
                                            pdtiniciomes                => pdtiniciomes,
                                            pdtfimmes                   => pdtfimmes,
                                            pdtfimrelacao               => pcef.dtfim,
                                            pnudiastotal                => vnudiastotal,
                                            pbafastultdia               => btemafastultimodiap,
                                            pdtiniciorelacao            => pcef.dtinicio,
                                            pFlPercentReducaoAfastRemun => pRubrica.FlPercentReducaoAfastRemun);

            vnudiasintegral := facertardiasprop(pnudiasafast                => vnudiasafasti,
                                                pnudiasmes                  => pnudiasmes,
                                                pdtiniciomes                => pdtiniciomes,
                                                pdtfimmes                   => pdtfimmes,
                                                pdtfimrelacao               => pcef.dtfim,
                                                pnudiastotal                => vnudiastotal,
                                                pbafastultdia               => btemafastultimodiai,
                                                pdtiniciorelacao            => pcef.dtinicio,
                                                pFlPercentReducaoAfastRemun => pRubrica.FlPercentReducaoAfastRemun);

            vresult.vlindice := vnudiasprop;

            -- Verificar se o numero de dias proporcionalizados e igual ao numero de dias do mes
            -- Para meses com 28,29 ou 31 dias
            IF vNuDiasProp = to_number(TO_CHAR(pDtFimMes, 'DD')) THEN
              vnudiasprop := pnudiasmes;

            END IF;

            IF vnudiasprop = pnudiasmes THEN

              vresult.vlintegral := pvalorintegral;

              vresult.vlproporcional := pvalorintegral;

            ELSE

              -- Se for relacao de trabalho 'a disposicao', nao for um evento de remuneracao fixa de efetivo
              -- e esteve afastamento (vinculo ou relacao)
              IF pcef.cdrelacaotrabalho = 10 AND peventocef = 'N' THEN

                IF vnudiasafastp > 0 THEN

                  vResult.vlIntegral := vNuDiasIntegral *
                                        (pValorIntegral / pNuDiasMes);

                  vResult.vlProporcional := vNuDiasProp *
                                            (pValorIntegral / pNuDiasMes);

                  -- Se for relacao de trabalho 'a disposicao', nao for um evento de remuneracao fixa de efetivo
                  -- e NAO esteve afastamento (vinculo ou relacao)
                ELSE
                  -- vNuDiasAfastP = 0

                  vresult.vlintegral := pvalorintegral;

                  vresult.vlproporcional := pvalorintegral;

                END IF;
                -- Se esteve afastado mais de 30 dias da relacao de vinculo, mas nao se afastou do vinculo

              ELSIF vnudiasafastp >= 30 AND vnudiasafasti = 0 THEN

                vresult.vlproporcional := 0;

                -- SIG-5310 problema na base do IPREV na folha normal e 13 na SAP
                -- Parametro usado para preservar o valor para a base do IPREV, se 'N' zerar
                if pRubrica.FlPreservaValorIntegral = 'N' and
                   pRubrica.NuRubrica in (1035, 1078, 1350, 1780) and
                   pRubrica.CdTipoRubrica = 1 and
                   pkgpag_var.vgFolha.CdAgrupamento = 1

                 then

                  vResult.vlIntegral := 0;
                  vResult.vlReal     := 0;
                  vResult.vlIndice   := 0;

                else

                  vResult.vlIntegral := vNuDiasIntegral *
                                        (pValorIntegral / pNuDiasMes);

                end if;

              ELSE
                -- SIG-6383 Proporcionalidade de rubrica na inativacao RUBRICA 01-0167 no mes da aposentadoria
                if pRubrica.NuRubrica = 617 and
                   pkgpag_var.vgFolha.CdAgrupamento = 1 and
                   pRubrica.CdTipoRubrica = 1 and
                   pkgpag_var.vgapo.count > 0 and pkgpag_var.vgapo(1)
                  .dtinicio > pkgpag_var.vgFolha.DtInicioMes and pkgpag_var.vgapo(1)
                  .dtinicio < pkgpag_var.vgFolha.DtFimMes then

                  vresult.vlProporcional := pValorIntegral;

                  vResult.vlIntegral := pValorIntegral;

                else

                  vResult.vlIntegral := vNuDiasIntegral *
                                        (pValorIntegral / pNuDiasMes);

                  vResult.vlProporcional := vNuDiasProp *
                                            (pValorIntegral / pNuDiasMes);

                end if;

              END IF;

            END IF;

          END IF;

        END IF;

    -- Aplica proporcionalidade por carga horaria
      WHEN prubrica.cdrubproporcionalidadecho = 2 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          IF NVL(pNuCHO, 0) > 0 THEN

            vnuchopadrao := pnucho;

          ELSIF pkgpag_var.vgvalorfixocef.nucargahoraria IS NOT NULL AND
                pkgpag_var.vgvalorfixocef.nucargahoraria > 0 THEN

            vnuchopadrao := pkgpag_var.vgvalorfixocef.nucargahoraria;

          ELSE

            vnuchopadrao := pkgpag_var.vgCargaHoraria(pkgpag_var.vgCargaHoraria.LAST).NuCargaHoraria;

          END IF;

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

        END IF;

        IF NVL(vNuCHOPadrao, 0) <= 0 THEN
          -- Erro de carga horaria

          -- Se nao ha carga horaria definida, zera a rubrica.
          vResult.vlProporcional := 0;
          vResult.vlIntegral     := 0;
          vResult.vlReal         := 0;

          vDeMensagem := 'Carga horaria padr?o da rubrica ' ||
                         pRubrica.CdTipoRubrica || '-' ||
                         pRubrica.NuRubrica || ' n?o esta definida.';

          pkgpag_geral.pinserelog(pkgpag_var.blog,
                                  pkgpag_var.vcdhistparamcalc,
                                  PKGPAG_VAR.vCdPessoa,
                                  vDeMensagem,
                                  pkgpag_var.vgcdvinculo);
        ELSE

          -- Se nao for a disposicao OU
          -- Se for a disposicao e o evento NAO for de remuneracao fixa OU
          -- Se for disposicao, o evento FOR de remuneracao fixa e possui afastamento temporario no mes
          -- se esta a disposicao com pagamento no destino e tem no destino um cargo comissionado,
          -- deve verificar afastamentos da relacao de vinculo no historico de cargo efetivo correspondente
          -- ao orgao de origem, pois la estara o afastamento temporario para assumir cargo comissionado
          IF pcef.cdrelacaotrabalho <> 10 OR
             (pcef.cdrelacaotrabalho = 10 AND peventocef = 'N') OR
             (pcef.cdrelacaotrabalho = 10 AND peventocef = 'S' AND
             PKGPAG_VAR.vMotAfast.InAfastado =
             PKGPAG_TIPO.cnAfastadoParcial AND
             PKGPAG_VAR.vMotAfast.InTipoAfastamento = 'T') OR
             (pcef.cdrelacaotrabalho = 10 AND PKGPAG_VAR.bVinculoComCCO AND
             PKGPAG_VAR.vPagaSitDisposicao = 'PAG-DEST-CALCULO-DEST') THEN

            IF PKGPAG_VAR.vgFolha.CdTipoFolha <>
               PKGPAG_TIPO.cnTpFolhaInstPensao THEN

              pkgafa.protdatainicializar(vdtinicio, vdtfim);

              IF pCEF.CdRelacaoTrabalho = 10 AND -- DISPOSICAO
                 PKGPAG_VAR.vPagaSitDisposicao = 'PAG-DEST-CALCULO-DEST' AND
                 PKGPAG_VAR.bVinculoComCCO THEN
                BEGIN
                  SELECT hcef.cdhistcargoefetivo
                    INTO vCdHistCargoEfetivo
                    FROM ecadhistcargoefetivo hcef
                   WHERE hcef.cdvinculo = pCEF.CdVinculo
                     AND hcef.cdrelacaotrabalho = 5
                     AND hcef.dtinicio <= pdtiniciomes
                     AND (hcef.dtfim >= pdtfimmes or hcef.dtfim is null)
                     AND rownum < 2;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    vCdHistCargoEfetivo := pCEF.CdHistRelVinc;
                  WHEN OTHERS THEN
                    vCdHistCargoEfetivo := pCEF.CdHistRelVinc;

                END;
              ELSE
                vCdHistCargoEfetivo := pCEF.CdHistRelVinc;
              END IF;

              vnudiastotalImp := 0;

              FOR reg IN (SELECT CASE
                                   WHEN pCEF.CdRelacaoTrabalho = 10 THEN
                                    pdtiniciomes
                                   ELSE
                                    dtinicial
                                 END AS dtinicio,
                                 dtfim,
                                 NULL AS diaafastadoprop1,
                                 NULL AS diaafastadointegral1,
                                 CASE prubrica.flcargahorarialimitada
                                   WHEN 'N' THEN
                                    nucargahoraria
                                   WHEN 'S' THEN
                                    CASE
                                      WHEN nucargahoraria > vnuchopadrao THEN
                                       vnuchopadrao
                                      ELSE
                                       nucargahoraria
                                    END
                                 END nucargahoraria,
                                 0 cdmotivoafast
                            FROM ecadhistcargahoraria hcho
                           WHERE cdhistcargoefetivo = pcef.cdhistrelvinc
                             AND dtinicial <= pcef.dtfim
                             AND (dtfim >= pcef.dtinicio OR dtfim IS NULL)
                             AND flanulado = pkgpag_tipo.cnn

                          UNION ALL

                          SELECT av.dtinicio,
                                 av.dtfim,
                                 case
                                   when pRubrica.NuRubrica = 574 and
                                        PKGPAG_VAR.vgFolha.CdAgrupamento = 1 and -- IRESA
                                        hmat.flpartejornada = 'S' and
                                        nvl(hmat.vlpercentreducaoiresa, 0) > 0 then
                                    hmat.vlpercentreducaoiresa / 100
                                   else
                                    1
                                 end AS diaafastadoprop1,
                                 case
                                   when pRubrica.NuRubrica = 574 and
                                        PKGPAG_VAR.vgFolha.CdAgrupamento = 1 and
                                        hmat.flpartejornada = 'S' and
                                        nvl(hmat.vlpercentreducaoiresa, 0) > 0 then
                                    hmat.vlpercentreducaoiresa / 100
                                   else
                                    1
                                 end AS diaafastadointegral1,
                                 0 AS nucargahoraria,
                                 av.cdmotivoafasttemporario cdmotivoafast
                            FROM eafaafastamentovinculo av
                           INNER JOIN eafahistmotivoafasttemp hmat
                              ON Av.CdMotivoAfastTemporario =
                                 HMAT.CdMotivoAfastTemporario
                           INNER JOIN (SELECT hmatv.cdmotivoafasttemporario,
                                             MAX(hmatv.dtiniciovigencia) AS dtiniciovigencia
                                        FROM eafahistmotivoafasttemp hmatv
                                       WHERE HMATV.dtInicioVigencia <=
                                             pdtFimMes
                                       GROUP BY hmatv.cdmotivoafasttemporario) mv
                              ON HMAT.CdMotivoAfastTemporario =
                                 MV.CdMotivoAfastTemporario
                             AND HMAT.DtInicioVigencia = MV.DtInicioVigencia
                           WHERE av.cdvinculo = pcef.cdvinculo
                             AND av.flanulado = pkgpag_tipo.cnn
                             AND pRubrica.FlPropAfastTempNaoRemun =
                                 PKGPAG_TIPO.cnS
                             AND (HMAT.FlRemunerado = PKGPAG_TIPO.cnN OR
                                 (prubrica.ingerarubricaafasttemp = '1' AND
                                 av.cdmotivoafasttemporario IN
                                 (SELECT cdmotivoafasttemporario
                                      FROM epagrubagrupmotafasttempimp ai
                                     WHERE AI.CdMotivoAfastTemporario =
                                           AV.CdMotivoAfastTemporario
                                       AND AI.CdHistRubricaAgrupamento =
                                           pRubrica.CdHistRubrica
                                       AND NOT EXISTS
                                     (SELECT 1
                                              FROM epagrubagrpmotaftempimpvinc vi
                                             WHERE ai.cdhistrubricaagrupamento =
                                                   vi.cdhistrubricaagrupamento
                                               AND AI.CdMotivoAfastTemporario =
                                                   vi.cdmotivoafasttemporario
                                               AND VI.CdVinculo =
                                                   pCEF.CdVinculo))) OR
                                 (prubrica.ingerarubricaafasttemp = '2' AND
                                 ((av.cdmotivoafasttemporario NOT IN
                                 (SELECT cdmotivoafasttemporario
                                        FROM epagrubagrupmotafasttempimp ai
                                       WHERE AV.CdMotivoAfastTemporario =
                                             AI.CdMotivoAfastTemporario
                                         AND AI.CdHistRubricaAgrupamento =
                                             pRubrica.CdHistRubrica
                                         AND NOT EXISTS
                                       (SELECT 1
                                                FROM epagrubagrpmotaftempimpvinc vi
                                               WHERE ai.cdhistrubricaagrupamento =
                                                     vi.cdhistrubricaagrupamento
                                                 AND AI.CdMotivoAfastTemporario =
                                                     vi.cdmotivoafasttemporario
                                                 AND VI.CdVinculo =
                                                     pCEF.CdVinculo))) OR
                                 (SELECT COUNT(*)
                                       FROM epagrubagrupmotafasttempimp ai
                                      WHERE AI.CdHistRubricaAgrupamento =
                                            pRubrica.CdHistRubrica) = 0)))

                             AND av.dtinicio <= pdtfimmes
                             AND (AV.DtFim >= pdtInicioMes OR
                                 AV.DtFim IS NULL)

                          UNION ALL

                          SELECT av.dtinicio,
                                 av.dtfim,
                                 1                          AS diaafastadoprop2,
                                 1                          AS diaafastadointegral2,
                                 0                          AS nucargahoraria,
                                 av.cdmotivoafasttemporario cdmotivoafast
                            FROM eafaafastamentovinculo av
                           INNER JOIN eafahistmotivoafastdef hmad
                              ON AV.CdMotivoAfastDefinitivo =
                                 HMAD.CdMotivoAfastDefinitivo
                           INNER JOIN (SELECT hmadv.cdmotivoafastdefinitivo,
                                             MAX(hmadv.dtiniciovigencia) AS dtiniciovigencia
                                        FROM eafahistmotivoafastdef hmadv
                                       WHERE HMADV.dtInicioVigencia <=
                                             pdtFimMes
                                       GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                              ON HMAD.CdMotivoAfastDefinitivo =
                                 MV.CdMotivoAfastDefinitivo
                             AND HMAD.Dtiniciovigencia = MV.Dtiniciovigencia
                           WHERE av.cdvinculo = pcef.cdvinculo
                             AND av.flanulado = pkgpag_tipo.cnn
                             AND pRubrica.FlPropAfastTempNaoRemun =
                                 PKGPAG_TIPO.cnS
                             AND hmad.flremunerado = pkgpag_tipo.cnn
                             AND av.dtinicio <= pdtfimmes
                             AND (AV.DtFim >= pdtInicioMes OR
                                 AV.DtFim IS NULL)

                          UNION ALL

                          SELECT CASE
                                   WHEN av.dtinicio < pdtiniciomes THEN
                                    pdtiniciomes
                                   ELSE
                                    av.dtinicio
                                 END AS dtinicio,
                                 CASE
                                   WHEN Av.DtFim > pDtFimMes OR
                                        Av.DtFim IS NULL THEN
                                    pdtfimmes
                                   ELSE
                                    av.dtfim
                                 END AS dtfim,
                                 1 AS diaafastadoprop4,
                                 NULL AS diaafastadointegral4,
                                 0 AS nucargahoraria,
                                 av.cdafastamentorelvinc cdmotivoafast
                            FROM eafaafastamentorelvinc av
                           WHERE pRubrica.FlPropAfaComissionado =
                                 PKGPAG_TIPO.cnS
                             AND AV.CdHistCargoEfetivo = vCdHistCargoEfetivo
                             AND av.cdhistcargocomgerador IS NOT NULL
                                /*AND NOT (PKGPAG_VAR.vgFolha.FlIgnoraInclusaoFutura = 'S' AND
                                AV.DtInclusao > pDtCalculo)*/
                             AND av.dtinicio <= pdtfimmes
                             AND (AV.Dtfim >= pdtInicioMes OR
                                 AV.DtFim IS NULL)
                             AND EXISTS
                           (SELECT 1
                                    FROM ecadhistcargocom hcc
                                   INNER JOIN (SELECT h.cdhistcargocom,
                                                     MAX(h.dtiniciovigencia) AS dtiniciovigencia
                                                FROM ecadhistopcaoremuneracaocco h
                                               WHERE H.DtInicioVigencia <=
                                                     pdtFimMes
                                                 AND (H.DtFimVigencia >=
                                                     pdtInicioMes OR
                                                     h.dtfimvigencia IS NULL)
                                               GROUP BY h.cdhistcargocom) hor1
                                      ON HCC.CdHistCargoCom =
                                         HOR1.CdHistCargoCom
                                   INNER JOIN ecadhistopcaoremuneracaocco hor
                                      ON HOR1.Cdhistcargocom =
                                         HOR.CdHistCargoCom
                                     AND HOR1.DtInicioVigencia =
                                         HOR.DtInicioVigencia
                                   WHERE HCC.CdHistCargoCom =
                                         AV.CdHistCargoComGerador
                                     and hcc.flanulado = pkgpag_tipo.cnn
                                        -- Excecao para a folha de Abril
                                        /* HCC.CdHistCargoCom = CASE WHEN pCEF.CdVinculo = 166727 THEN HCC.CdHistCargoCom
                                        ELSE AV.CdHistCargoComGerador  END   */
                                     AND NOT (PKGPAG_VAR.vgFolha.FlIgnoraInclusaoFutura = 'S' AND
                                          HCC.DtInclusao > pDtCalculo)
                                     AND hcc.cdcargocomremuneracao IS NULL
                                     AND ((HOR.CdOpcaoRemuneracao = 3 AND
                                         NOT (HCC.FlTipoProvimento IN
                                          (PKGPAG_TIPO.cnS) AND
                                          pRubrica.FlPropAfaCCOSubst =
                                          PKGPAG_TIPO.cnN)) OR
                                         (pRubrica.FlPropAfaFgFtg =
                                         PKGPAG_TIPO.cnS AND
                                         hor.cdopcaoremuneracao IN (6,9)) OR
                                         (pEventoCEF = PKGPAG_TIPO.cnN AND
                                         HCC.CdOpcaoRemuneracao = 2 AND
                                         prubrica.flpropafacomopcperccef = 'S')))
                             AND av.flanulado = pkgpag_tipo.cnn)

               LOOP

                pkgafa.protdatainserirdata(CASE
                                           -- SE RUBRICA 01-0403, GRAT PART COMISSAO,
                                           -- SOMENTE CONSIDERAR AFASTAMENTOS
                                           -- DENTRO DO PERIODO DA COMISSAO
                                           WHEN pRubrica.CdRubricaAgrupamento =
                                           10453 AND
                                           vDtInicioComissao IS NOT NULL AND
                                           vDtInicioComissao >
                                           reg.dtinicio THEN
                                           vDtInicioComissao ELSE
                                           reg.dtinicio END,
                                           CASE WHEN
                                           pRubrica.CdRubricaAgrupamento =
                                           10453 AND
                                           vDtFimComissao IS NOT NULL AND
                                           reg.dtfim IS NOT NULL AND
                                           vDtFimComissao < reg.dtfim THEN
                                           vDtFimComissao ELSE reg.dtfim END,

                                           pfltem1  => reg.diaafastadoprop1,
                                           pfltem2  => reg.diaafastadointegral1,
                                           pnusoma1 => reg.nucargahoraria);

              END LOOP;

              IF pkgpag_var.bsemintersticio AND
                 to_char(vdtfim, 'DD') = '31' THEN

                vdtfim := vdtfim - 1;

              END IF;

              PKGAFA.PRotDataInserirData(vDtInicio, vDtFim, pFlTem3 => 1);

              pkgafa.protdatacalcular(trotdata);

              vnudiastotal        := 0;
              vnudiasafastp       := 0;
              vnudiasafasti       := 0;
              vnucho              := 0;
              btemafastultimodiap := FALSE;
              btemafastultimodiai := FALSE;
              btemdifcho          := FALSE;
              --vvlsomachodias      := 0;
              --vvltotaldias        := 0;

              -- FlTem1: Afastado Proporcional
              -- FlTem2: Afastado Integral
              -- FlTem3: Dentro da Vigencia do Mes
              -- NuSoma1: Carga Horaria
              FOR reg IN trotdata.first .. trotdata.last LOOP

                -- soma dias totais
                IF trotdata(reg).fltem3 IS NOT NULL THEN

                  vNuDiasTotal := vNuDiasTotal +
                                  (tRotData(reg).DtFim - tRotData(reg).DtIni + 1);

                  IF trotdata(reg).nusoma1 <> 0 THEN

                    IF vnucho = 0 THEN

                      vnucho := trotdata(reg).nusoma1;

                    ELSE

                      IF tRotData(reg).NuSoma1 <> vNuCHO THEN
                        -- mais de uma carga horaria

                        btemdifcho := TRUE;

                        vnucho := trotdata(reg).nusoma1;

                      END IF;

                    END IF;

                  END IF;

                END IF;

                IF tRotData(reg).DtFim = pDtFimMes /*AND TO_CHAR(pdtInicioMes, 'MM') = 2*/
                 THEN

                  IF trotdata(reg).fltem1 IS NOT NULL THEN

                    btemafastultimodiap := TRUE;

                  END IF;

                  IF trotdata(reg).fltem2 IS NOT NULL THEN

                    btemafastultimodiai := TRUE;

                  END IF;

                END IF;

                IF trotdata(reg)
                 .fltem1 IS NOT NULL or
                    (trotdata(reg).NuSoma1 = 0 and PKGPAG_VAR.bPossuiACT and
                      prubrica.NuRubrica = 1021 and
                      pkgpag_var.vgFolha.CdAgrupamento = 1) THEN
                  vNuDiasAfastP := vNuDiasAfastP +
                                   ((tRotData(reg).DtFim - tRotData(reg).DtIni + 1) *
                                   nvl(tRotData(reg).FlTem1, 1));
                END IF;

                IF trotdata(reg).fltem2 IS NOT NULL THEN
                  vNuDiasAfastI := vNuDiasAfastI +
                                   ((tRotData(reg).DtFim - tRotData(reg).DtIni + 1) *
                                   nvl(tRotData(reg).FlTem2, 1));
                END IF;

                IF prubrica.nurubrica = 229 THEN

                  IF PKGPAG_VAR.vglindice010229 > 0
                    --AND vNuDiasTotal <> vglindice010229 + (tRotData (reg).DtFim - tRotData (reg).DtIni + 1)
                     AND
                     PKGPAG_VAR.vglindice010229 +
                     (tRotData(reg).DtFim - tRotData(reg).DtIni + 1) > 30 THEN

                    vNuDiasTotal := 30 - PKGPAG_VAR.vglindice010229;

                  END IF;

                  PKGPAG_VAR.vglindice010229 := PKGPAG_VAR.vglindice010229 +
                                                (tRotData(reg).DtFim - tRotData(reg).DtIni + 1);


                END IF;

              END LOOP;

              IF btemdifcho THEN

                vnucho := pkgpag_fb.fmnechomedio(1,
                                                 pcef.cdhistrelvinc,
                                                 pdtiniciomes,
                                                 pdtfimmes);

              END IF;

              vnudiasprop := facertardiasprop(pnudiasafast     => vnudiasafastp,
                                              pnudiasmes       => pnudiasmes,
                                              pdtiniciomes     => pdtiniciomes,
                                              pdtfimmes        => pdtfimmes,
                                              pdtfimrelacao    => pcef.dtfim,
                                              pnudiastotal     => vnudiastotal,
                                              pbafastultdia    => btemafastultimodiap,
                                              pdtiniciorelacao => pcef.dtinicio);

              vnudiasintegral := facertardiasprop(pnudiasafast     => vnudiasafasti,
                                                  pnudiasmes       => pnudiasmes,
                                                  pdtiniciomes     => pdtiniciomes,
                                                  pdtfimmes        => pdtfimmes,
                                                  pdtfimrelacao    => pcef.dtfim,
                                                  pnudiastotal     => vnudiastotal,
                                                  pbafastultdia    => btemafastultimodiai,
                                                  pdtiniciorelacao => pcef.dtinicio);

              vresult.vlproporcional := pvalorintegral;
              vresult.vlintegral     := pvalorintegral;
              vresult.vlIndice       := vnudiasprop;

              -- RUBRICA 01-0403: A REGRA DEFINE QUE NAO GERE A RUBRICA NOS AFASTAMENTOS PREVISTOS
              -- NO PARAMETRO DA RUBRICA QUANDO ESTES FOREM IGUAL OU SUPERIOR A 30 DIAS DENTRO DO MES
              /* IF pRubrica.CdRubricaAgrupamento = 10453  AND vnudiastotalImp >= 30 THEN
              vresult.vlproporcional := 0;
              vresult.vlintegral := 0;
              vresult.vlindice := 0;       */
              -- PARAMETRO: Se tem afastamento remunerado, conta os dias

              IF pRubrica.CdRubricaAgrupamento = 10453 AND
                 PKGPAG_VAR.vgAfastTempRemun.COUNT > 0 THEN
                FOR i IN PKGPAG_VAR.vgAfastTempRemun.FIRST .. PKGPAG_VAR.vgAfastTempRemun.LAST LOOP

                  --Para a rubrica 01-0403 verifica se existe afastamento impeditivo
                  IF pRubrica.lsMotAfastTempImp.exists(PKGPAG_VAR.vgAfastTempRemun(i).CdMotivoAfastamento) THEN

                    -- No primeiro LOOP defini uma data inicial para verificar se
                    -- os afastamentos sao continuos ou nao.
                    -- Caso sejam continuos e somarem 30 dias, nao gera a rubrica.
                    IF i = 1 THEN
                      vData := PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfa;
                    END IF;

                    --Soma o numero de dias que o servidor esta afastado no mes
                    IF PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfa = vData THEN

                      vnudiastotalImp := vnudiastotalImp +
                                         (PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfa - PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfa) + 1;

                      vNuDiasImpNoMes := vNuDiasImpNoMes +
                                         (PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfaNoMes - PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfaNoMes) + 1;
                    ELSE

                      vnudiastotalImp := (PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfa - PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfa) + 1;

                      vNuDiasImpNoMes := (PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfaNoMes - PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfaNoMes) + 1;

                    END IF;

                    vData := PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfa + 1;

                  END IF;
                END LOOP;
              END IF;

              -- CASO O AFASTAMENTO SEJA MENOR QUE 30 DIAS PAGA INTEGRAL
              IF (pRubrica.CdRubricaAgrupamento = 10453 AND
                 vnudiastotalImp < 30 AND vnudiasafasti <= vNuDiasImpNoMes) or
                -- Parametro criado para atender a solicitacao SIG-4424
                -- Ignorar os afastamentos do agente politico para pagar na relacao de efetivo
                 (pRubrica.FLIGNORAAFASTCEFAGPOLITICO = 'S' and
                 pkgpag_var.vgCco.Count > 0 and pkgpag_var.vgcco(1).cdrelacaotrabalho = 4) THEN
                -- Os afastamentos sao impeditivos
                vnudiasprop := 30;
              END IF;

              --
              -- 10271/2017 - CTISP - BOMBEIRO
              --
              IF pRubrica.CdRubricaAgrupamento = 20570 AND
                 pkgpag_var.vgcef.count > 1 AND pkgpag_var.vgNuDiasCEF = 30 AND
                 to_char(pkgpag_var.vgFolha.DtFimMes, 'DD') = 31 AND
                 NVL(pkgpag_var.vgValorCalculoRubrica(20570).VlIndice, 0) > 0 THEN
                vnudiasprop := 30 - NVL(pkgpag_var.vgValorCalculoRubrica(20570).VlIndice,
                                        0);
              END IF;

            END IF;

            -- Se existe parametrizacao de locais de trabalho com valores de carga horaria
            -- especificas, assume esta carga horaria
            IF prubrica.lsloccho.first IS NOT NULL THEN

              IF prubrica.lsloccho.exists(pcef.cdunidadeorganizacional) THEN

                vnuchopadrao := prubrica.lsloccho(pcef.cdunidadeorganizacional);

                vnucho := prubrica.lsloccho(pcef.cdunidadeorganizacional);

              END IF;

            END IF;

            --CASO O SERVIDOR POSSUA AFASTAMENTO PARA OCUPAR CARGO COMISSIONADO OU SUBSTITUICAO
            IF PKGPAG_VAR.vgNuDiasSubst > 0 THEN
              --vNuDiasCCO:=  PKGPAG_VAR.vgNuDiasCCO;
              vNuDiasCCOSubst := PKGPAG_VAR.vgNuDiasSubst;

              IF vnudiasprop > 0 AND vnudiasprop <> vnudiasintegral AND
                 vNuDiasCCOSubst > 0 THEN

                IF vnudiasprop + vNuDiasCCOSubst > 30 THEN
                  vnudiasprop := vnudiasprop - 1;
                END IF;
              END IF;
            END IF;

            -- CASO NAO TENHA CARGA HORARIA DEFINIDA PARA INSTITUIDOR DE PENSAO
            IF pkgpag_var.vgFolha.CdTipoFolha =
               pkgpag_tipo.cnTpFolhaInstPensao THEN

              IF NVL(vnucho, 0) = 0 THEN

                vnucho := CASE
                            WHEN NVL(pCEF.NuCargaHoraria, 0) > 0 THEN
                             pCEF.NuCargaHoraria
                            ELSE
                             vnuchopadrao
                          END;
              END IF;
              /*
              IF nvl(vnudiasprop, 0) = 0 THEN
                vnudiasprop := 0;
              END IF;*/

            END IF;

            IF vnudiasprop <> pnudiasmes THEN

              vResult.vlProporcional := round((pValorIntegral / pNuDiasMes) * vNuDiasProp,2);

            END IF;

            IF vNuDiasIntegral <> pnudiasmes THEN

              vResult.vlIntegral := round((pValorIntegral / pNuDiasMes) * vNuDiasIntegral ,2);

            END IF;

            IF vnuchopadrao <> vnucho THEN

              vResult.vlProporcional := ((vResult.vlProporcional /
                                        vNuCHOPadrao) * vNuCHO);

              vResult.vlIntegral := ((vResult.vlIntegral / vNuCHOPadrao) *
                                    vNuCHO);

              vresult.vlreal := ((pValorIntegral / vNuCHOPadrao) * vNuCHO);

            END IF;

            if prubrica.CdRubricaAgrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,9207)
              and pkgpag_var.vgFolha.CdAgrupamento = 134
              and pkgpag_var.vgFolha.cdtipofolha in (1,19)  then
               vResult.vlIntegral := pValorIntegral;
               vResult.vlProporcional := pValorIntegral;
            end if;

            ---------------------------
            -- Acerta 1001 de a disposicao
            ---------------------------
          ELSIF pCEF.CdRelacaoTrabalho = 10 AND
                pEventoCEF = PKGPAG_TIPO.cnS THEN

            SELECT SUM(NuCHO * NuDias) / SUM(NuDias), SUM(NuDias)
              INTO vNuCHO, vNuDiasTotal
              FROM (SELECT A.NuCHO, COUNT(*) AS nuDias
                      FROM (SELECT x.CdHistCargoEfetivo,
                                   y.dtdia,
                                   SUM(1) AS nudias,
                                   SUM(x.nucargahoraria) AS nucho
                              FROM (SELECT pDtInicioMes + (LEVEL - 1) AS dtdia
                                      FROM dual
                                    CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                               pDtInicioMes AND pDtFimMes) y
                             INNER JOIN (SELECT cdhistcargahoraria,
                                               cdhistcargoefetivo,
                                               dtinicial,
                                               CASE
                                                 WHEN dtfim IS NULL THEN
                                                  pdtfimmes
                                                 ELSE
                                                  dtfim
                                               END dtfim,
                                               fltipoocupacao,
                                               CASE
                                                pRubrica.FlCargaHorariaLimitada
                                                 WHEN pkgpag_tipo.cnn THEN
                                                  nucargahoraria
                                                 WHEN pkgpag_tipo.cns THEN
                                                  CASE
                                                    WHEN NuCargaHoraria >
                                                         vNuCHOPadrao THEN
                                                     vnuchopadrao
                                                    ELSE
                                                     nucargahoraria
                                                  END
                                               END nucargahoraria
                                          FROM ecadhistcargahoraria hcho
                                         WHERE CdHistCargoEfetivo =
                                               pCEF.CdHistRelVinc
                                           AND DtInicial <= pdtFimMes
                                           AND (dtFim >= pdtInicioMes OR
                                               dtFim IS NULL)
                                           AND flanulado = pkgpag_tipo.cnn) x
                                ON (x.DtInicial <= y.dtdia)
                               AND (x.DtFim >= y.dtdia)
                             GROUP BY x.cdhistcargoefetivo, y.dtdia) a
                     GROUP BY a.nucho);

            -- acerta valores

            IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

              vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                              pnudiasmes       => pnudiasmes,
                                              pdtiniciomes     => pdtiniciomes,
                                              pdtfimmes        => pdtfimmes,
                                              pdtfimrelacao    => pcef.dtfim,
                                              pnudiastotal     => vnudiastotal,
                                              pbafastultdia    => FALSE,
                                              pdtiniciorelacao => pcef.dtinicio);

              vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                                  pnudiasmes       => pnudiasmes,
                                                  pdtiniciomes     => pdtiniciomes,
                                                  pdtfimmes        => pdtfimmes,
                                                  pdtfimrelacao    => pcef.dtfim,
                                                  pnudiastotal     => vnudiastotal,
                                                  pbafastultdia    => FALSE,
                                                  pdtiniciorelacao => pcef.dtinicio);

              vresult.vlproporcional := pvalorintegral;

              vresult.vlintegral := pvalorintegral;

              vresult.vlindice := vnudiasprop;

              vresult.vlreal := pvalorintegral;

              vResult.vlProporcional := ((pValorIntegral / pNuDiasMes) *
                                        vNuDiasProp / vNuCHOPadrao *
                                        vNuCHO);

              vResult.vlIntegral := ((pValorIntegral / pNuDiasMes) *
                                    vNuDiasIntegral / vNuCHOPadrao *
                                    vNuCHO);

              vresult.vlreal := (pvalorintegral / vnuchopadrao * vnucho);

            END IF;

          else
            null;
          END IF;

        END IF;

    -- Aplica proporcionalidade pela media da carga horaria
      WHEN prubrica.cdrubproporcionalidadecho = 3 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          vnuchopadrao := pnucho;

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

        END IF;

        IF nvl(prubrica.numesesapuracao, 0) > 0 THEN

          vDtInicioPeriodo := ADD_MONTHS(pDtInicioMes,
                                         -pRubrica.NuMesesApuracao);

        ELSE

          vdtinicioperiodo := pdtiniciomes;

        END IF;

        vdtfimperiodo := last_day(pdtiniciomes);

        SELECT SUM(numediacho)
          INTO vnucho
          FROM (SELECT x.CdHistCargoEfetivo,
                       SUM(x.nucargahoraria) / COUNT(DISTINCT dtdia) AS numediacho
                  FROM (SELECT vdtinicioperiodo + (LEVEL - 1) AS dtdia
                          FROM dual
                        CONNECT BY vdtInicioPeriodo + (LEVEL - 1) BETWEEN
                                   vdtInicioPeriodo AND vdtFimPeriodo) y
                 INNER JOIN (SELECT cdhistcargahoraria,
                                   cdhistcargoefetivo,
                                   dtinicial,
                                   CASE
                                     WHEN dtfim IS NULL THEN
                                      vdtfimperiodo
                                     ELSE
                                      dtfim
                                   END dtfim,
                                   fltipoocupacao,
                                   nucargahoraria
                              FROM ecadhistcargahoraria hcho
                             WHERE CdHistCargoEfetivo = pCEF.CdHistRelVinc
                               AND DtInicial < vdtFimPeriodo
                               AND (dtFim > vdtInicioPeriodo OR
                                   dtFim IS NULL)
                               AND FlAnulado = 'N') x
                    ON (x.DtInicial <= y.dtdia)
                   AND (x.DtFim >= y.dtdia)
                 GROUP BY x.cdhistcargoefetivo);

        vnudiastotal := (pcef.dtfim - pcef.dtinicio) + 1;

        -- acerta valores

        vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                        pnudiasmes       => pnudiasmes,
                                        pdtiniciomes     => pdtiniciomes,
                                        pdtfimmes        => pdtfimmes,
                                        pdtfimrelacao    => pcef.dtfim,
                                        pnudiastotal     => vnudiastotal,
                                        pbafastultdia    => FALSE,
                                        pdtiniciorelacao => pcef.dtinicio);

        vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pcef.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => FALSE,
                                            pdtiniciorelacao => pcef.dtinicio);

        vresult.vlindice := vnudiasprop;

        vresult.vlintegral := pvalorintegral;

        vresult.vlreal := pvalorintegral;

        IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

          vResult.vlProporcional := ((pValorIntegral / pNuDiasMes) *
                                    vNuDiasProp / vNuCHOPadrao * vNuCHO);

          vResult.vlIntegral := ((pValorIntegral / pNuDiasMes) *
                                vNuDiasIntegral / vNuCHOPadrao * vNuCHO);

          vresult.vlreal := (pvalorintegral / vnuchopadrao * vnucho);

        END IF;

    END CASE;

    RETURN vresult;

  END;

  /*-----------------------------------------------------------------------------------------
    Function: FCalculaProporcionalidadeFUC
    Objetivo: Aplicar sobre o valor integral a proporcionalidade da carga horaria

    Argumentos:

      pNuDiasMes - Numero de dias no mes. Caso a rubrica indique que o calculo e
                   baseado em mes comercial, o numero de dias utilizado e = 30.
  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fcalculaproporcfuc(pfuc           IN pkgpag_tipo.rfuc,
                              pnudiasmes     IN INTEGER,
                              prubrica       IN pkgpag_tipo.rrubrica,
                              pvalorintegral IN NUMBER,
                              pdtiniciomes   IN DATE,
                              pdtfimmes      IN DATE)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vresult          pkgpag_tipo.rvalorpagamento;
    vnuchopadrao     NUMBER(7, 4);
    vdtinicioperiodo DATE;
    vdtfimperiodo    DATE;
    vdemensagem      VARCHAR2(200);

    vdtinicio    DATE;
    vdtfim       DATE;
    vnudiastotal NUMBER;
    vnudiasprop  NUMBER;
    vnucho       NUMBER(7, 4);
    --vNuDiasFuc   NUMBER;

  BEGIN
 
    vResult.vlIndice := PKGPAG_GERAL.FRetornaIndice(pRubrica.FlPropMesComercial,
                                                    pDtInicioMes,
                                                    pDtFimMes,
                                                    pFUC.DtInicio,
                                                    pFUC.DtFim);

    vResult.VlProporcional := PKGPAG_GERAL.FCalculaValorPropDias(pRubrica.FlPropServRelVinc,
                                                                 pvalorintegral,
                                                                 pnudiasmes,
                                                                 vresult.vlindice);

    vresult.vlreal := pvalorintegral;

    CASE

      WHEN prubrica.cdrubproporcionalidadecho = 1 THEN

        IF prubrica.flpropafasttempnaoremun = pkgpag_tipo.cns THEN

          IF prubrica.flpropservrelvinc = 'N' THEN

            vdtinicio := pdtiniciomes;

            vdtfim := pdtfimmes;

          ELSE

            vdtinicio := pfuc.dtinicio;

            vdtfim := pfuc.dtfim;

          END IF;

          SELECT nudias
            INTO vNuDiasTotal
            FROM (SELECT COUNT(*) AS nudias
                    FROM (SELECT y.dtdia
                            FROM (SELECT vdtinicio + (LEVEL - 1) AS dtdia
                                    FROM dual
                                  CONNECT BY vDtInicio + (LEVEL - 1) BETWEEN
                                             vDtInicio AND vDtFim) y
                           WHERE y.dtdia NOT IN
                                 (SELECT dtdia
                                    FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                            FROM dual
                                          CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                                     pdtInicioMes AND pdtFimMes) D
                                   INNER JOIN (SELECT CASE
                                                       WHEN AV.dtInicio <
                                                            pdtInicioMes THEN
                                                        pdtiniciomes
                                                       ELSE
                                                        av.dtinicio
                                                     END AS dtinicio,
                                                     CASE
                                                       WHEN (AV.dtFim >
                                                            pdtFimMes OR
                                                            AV.DtFim IS NULL) THEN
                                                        pdtfimmes
                                                       ELSE
                                                        av.dtfim
                                                     END AS dtfim
                                                FROM eafaafastamentovinculo av
                                               INNER JOIN eafahistmotivoafasttemp hmat
                                                  ON Av.CdMotivoAfastTemporario =
                                                     HMAT.CdMotivoAfastTemporario
                                               INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                                                 MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                                            FROM eafahistmotivoafasttemp hmatv
                                                           WHERE HMATV.dtInicioVigencia <=
                                                                 pdtFimMes
                                                           GROUP BY hmatv.cdmotivoafasttemporario) mv
                                                  ON HMAT.CdMotivoAfastTemporario =
                                                     MV.CdMotivoAfastTemporario
                                                 AND HMAT.Dtiniciovigencia =
                                                     MV.Dtiniciovigencia
                                               WHERE AV.CdVinculo =
                                                     pFUC.cdVinculo
                                                 AND AV.FlAnulado =
                                                     PKGPAG_TIPO.cnN
                                                 AND (HMAT.FlRemunerado =
                                                     PKGPAG_TIPO.cnN OR
                                                     (prubrica.ingerarubricaafasttemp = '1' AND
                                                     av.cdmotivoafasttemporario IN
                                                     (SELECT cdmotivoafasttemporario
                                                          FROM epagrubagrupmotafasttempimp ai
                                                         WHERE AI.CdMotivoAfastTemporario =
                                                               AV.CdMotivoAfastTemporario
                                                           AND AI.CdHistRubricaAgrupamento =
                                                               pRubrica.CdHistRubrica)) OR
                                                     (prubrica.ingerarubricaafasttemp = '2' AND
                                                     ((av.cdmotivoafasttemporario NOT IN
                                                     (SELECT cdmotivoafasttemporario
                                                            FROM epagrubagrupmotafasttempimp ai
                                                           WHERE AV.CdMotivoAfastTemporario =
                                                                 AI.CdMotivoAfastTemporario
                                                             AND AI.CdHistRubricaAgrupamento =
                                                                 pRubrica.CdHistRubrica)) OR
                                                     (SELECT COUNT(*)
                                                           FROM epagrubagrupmotafasttempimp ai
                                                          WHERE AI.CdHistRubricaAgrupamento =
                                                                pRubrica.CdHistRubrica) = 0)))
                                                 AND AV.DtInicio <= pdtFimMes
                                                 AND (AV.DtFim >= pdtInicioMes OR
                                                     AV.DtFim IS NULL)) B
                                      ON (B.DtInicio <= D.dtdia)
                                     AND (B.DtFim >= D.dtdia)
                                  UNION
                                  SELECT dtdia
                                    FROM (SELECT pdtInicioMes + (LEVEL - 1) AS dtdia
                                            FROM dual
                                          CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                                     pdtInicioMes AND pdtFimMes) D
                                   INNER JOIN (SELECT CASE
                                                       WHEN AV.dtInicio <
                                                            pdtInicioMes THEN
                                                        pdtiniciomes
                                                       ELSE
                                                        av.dtinicio
                                                     END AS dtinicio,
                                                     CASE
                                                       WHEN (AV.dtFim >
                                                            pdtFimMes OR
                                                            AV.DtFim IS NULL) THEN
                                                        pdtfimmes
                                                       ELSE
                                                        av.dtfim
                                                     END AS dtfim
                                                FROM eafaafastamentovinculo av
                                               INNER JOIN eafahistmotivoafastdef hmad
                                                  ON AV.CdMotivoAfastDefinitivo =
                                                     HMAD.CdMotivoAfastDefinitivo
                                               INNER JOIN (SELECT HMADV.CdMotivoAfastDefinitivo,
                                                                 MAX(HMADV.DtInicioVigencia) AS DtInicioVigencia
                                                            FROM eafahistmotivoafastdef hmadv
                                                           WHERE HMADV.dtInicioVigencia <=
                                                                 pdtFimMes
                                                           GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                                  ON HMAD.CdMotivoAfastDefinitivo =
                                                     MV.CdMotivoAfastDefinitivo
                                                 AND HMAD.Dtiniciovigencia =
                                                     MV.Dtiniciovigencia
                                               WHERE AV.CdVinculo =
                                                     pFUC.cdVinculo
                                                 AND AV.FlAnulado =
                                                     PKGPAG_TIPO.cnN
                                                 AND HMAD.FlRemunerado =
                                                     PKGPAG_TIPO.cnN
                                                 AND AV.DtInicio <= pdtFimMes
                                                 AND (AV.DtFim >= pdtInicioMes OR
                                                     AV.DtFim IS NULL)) B
                                      ON (B.DtInicio <= D.dtdia)
                                     AND (B.DtFim >= D.dtdia))) A);

          -- acerta valores

          if vnudiastotal = 2 and
             PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual = 29 and
             to_char(pdtfimmes, 'DD') = '31' then

            vNuDiasTotal := 1;

          end if;

          vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                          pnudiasmes       => pnudiasmes,
                                          pdtiniciomes     => pdtiniciomes,
                                          pdtfimmes        => pdtfimmes,
                                          pdtfimrelacao    => pfuc.dtfim,
                                          pnudiastotal     => vnudiastotal,
                                          pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                          pdtiniciorelacao => pfuc.dtinicio);

          --
          -- SIG-5127 Rubrica nao confere
          --
          if pkgpag_var.vgfolha.cdagrupamento = 176 and pnudiasmes = 30 and
             NVL(pkgpag_var.vgNuDiasSubst, 0) > 0 then
            vNuDiasProp := vNuDiasProp - pkgpag_var.vgNuDiasSubst;
          end if;

          IF pkgpag_var.vgfuc.count > 1 AND
             (pfuc.dtfim IS NULL OR to_char(pfuc.dtfim, 'DD') = '31') and
             vNuDiasProp > 30 THEN
            vnudiasprop := vnudiasprop - 1;
          END IF;

          vresult.vlindice := vnudiasprop;

          IF vnudiasprop <> pnudiasmes THEN

            vResult.vlProporcional := vNuDiasProp *
                                      (pValorIntegral / pNuDiasMes);

          ELSE

            vresult.vlproporcional := pvalorintegral;

          END IF;

        END IF;

      WHEN prubrica.cdrubproporcionalidadecho = 2 THEN

        -- Caso a funcao de chefia possua o indicativo FLPROPORCIONALIZACHO = N
        -- Flag criado para tratar uma excecao na funcao de chefia 'DIRETOR DE ESCOLA 60 - 1 TURNO'
        IF pfuc.Flproporcionalizacho = 'N' THEN
          vresult.vlproporcional := pvalorintegral;

        ELSE
          -- Caso possua efetivo, ira proporcionalizar pelo carga horaria do
          -- efetivo e da carreira do efetivo

          IF pkgpag_var.vgrelvincprincipal.cdreltrabpagamento IN (5, 10) AND
             pkgpag_var.vgvalorfixocef.nucargahoraria IS NOT NULL THEN
            --
            -- Solicitacao de Sustentacao #72477
            -- PGTC - FUNCAO CHEFIA_FOLHA OUTUBRO, tratar carga horaria zero.
            --
            IF NVL(pkgpag_var.vgValorFixoCEF.NuCargaHoraria, 0) <= 0 THEN
              vnuchopadrao := pkgpag_var.vgCargaHoraria(pkgpag_var.vgCargaHoraria.LAST).NuCargaHoraria;
            ELSE
              vnuchopadrao := pkgpag_var.vgValorFixoCEF.NuCargaHoraria;
            END IF;

            SELECT NVL(SUM(NuDias * NuCHO) / SUM(NuDias), 0),
                   NVL(SUM(NuDias), 0)
              INTO vNuCHO, vNuDiasTotal
              FROM (SELECT a.nucho, COUNT(*) AS nudias
                      FROM (SELECT x.cdhistfuncaochefia,
                                   y.dtdia,
                                   SUM(x.nucargahoraria) AS nucho
                              FROM (SELECT pfuc.dtinicio + (LEVEL - 1) AS dtdia
                                      FROM dual
                                    CONNECT BY pFUC.dtInicio + (LEVEL - 1) BETWEEN
                                               pFUC.dtInicio AND pFUC.dtFim) y
                             INNER JOIN (SELECT cdhistcargahoraria,
                                               cdhistfuncaochefia,
                                               CASE
                                                 WHEN pkgpag_var.vgrelvincprincipal.cdreltrabpagamento = 10 THEN
                                                  pfuc.dtinicio
                                                 ELSE
                                                  dtinicial
                                               END dtinicial,
                                               CASE
                                                 WHEN dtfim IS NULL THEN
                                                  pfuc.dtfim
                                                 ELSE
                                                  dtfim
                                               END dtfim,
                                               fltipoocupacao,
                                               CASE
                                                pRubrica.FlCargaHorariaLimitada
                                                 WHEN 'N' THEN
                                                  nucargahoraria
                                                 WHEN 'S' THEN
                                                  CASE
                                                    WHEN NuCargaHoraria >
                                                         vnuchopadrao THEN
                                                     pkgpag_var.vgvalorfixocef.nucargahoraria
                                                    ELSE
                                                     nucargahoraria
                                                  END
                                               END nucargahoraria
                                          FROM ecadhistcargahoraria hcho
                                         WHERE HCHO.CdHistCargoEfetivo =
                                               pfuc.CdHistCargoEfetivoOrigem
                                           and --PKGPAG_VAR.vgRelVincPrincipal.CdHist AND
                                               CASE
                                                 WHEN pkgpag_var.vgrelvincprincipal.cdreltrabpagamento = 10 THEN
                                                  pfuc.dtinicio
                                                 ELSE
                                                  dtinicial
                                               END <= pFUC.dtFim
                                           AND (dtFim >= pFUC.dtInicio OR
                                               dtFim IS NULL)
                                           AND FlAnulado = PKGPAG_TIPO.cnN) x
                                ON (x.DtInicial <= y.dtdia)
                               AND (x.DtFim >= y.dtdia)
                             WHERE y.dtdia NOT IN
                                   (SELECT dtdia
                                      FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                              FROM dual
                                            CONNECT BY pdtInicioMes +
                                                       (LEVEL - 1) BETWEEN
                                                       pdtInicioMes AND
                                                       pdtFimMes) D
                                     INNER JOIN (SELECT CASE
                                                         WHEN AV.dtInicio <
                                                              pdtInicioMes THEN
                                                          pdtiniciomes
                                                         ELSE
                                                          av.dtinicio
                                                       END AS dtinicio,
                                                       CASE
                                                         WHEN (AV.dtFim >
                                                              pdtFimMes OR
                                                              AV.DtFim IS NULL) THEN
                                                          pdtfimmes
                                                         ELSE
                                                          av.dtfim
                                                       END AS dtfim
                                                  FROM eafaafastamentovinculo av
                                                 INNER JOIN eafahistmotivoafasttemp hmat
                                                    ON Av.CdMotivoAfastTemporario =
                                                       HMAT.CdMotivoAfastTemporario
                                                 INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                                                   MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                                              FROM eafahistmotivoafasttemp hmatv
                                                             WHERE HMATV.dtInicioVigencia <=
                                                                   pdtFimMes
                                                             GROUP BY hmatv.cdmotivoafasttemporario) mv
                                                    ON HMAT.CdMotivoAfastTemporario =
                                                       MV.CdMotivoAfastTemporario
                                                   AND HMAT.DtInicioVigencia =
                                                       MV.DtInicioVigencia
                                                 WHERE AV.CdVinculo =
                                                       pFUC.cdVinculo
                                                   AND AV.FlAnulado =
                                                       PKGPAG_TIPO.cnN
                                                   AND pRubrica.FlPropAfastTempNaoRemun =
                                                       PKGPAG_TIPO.cnS
                                                   AND (HMAT.FlRemunerado =
                                                       PKGPAG_TIPO.cnN OR
                                                       (prubrica.ingerarubricaafasttemp = '1' AND
                                                       av.cdmotivoafasttemporario IN
                                                       (SELECT cdmotivoafasttemporario
                                                            FROM epagrubagrupmotafasttempimp ai
                                                           WHERE AI.CdMotivoAfastTemporario =
                                                                 AV.CdMotivoAfastTemporario
                                                             AND AI.CdHistRubricaAgrupamento =
                                                                 pRubrica.CdHistRubrica)) OR
                                                       (prubrica.ingerarubricaafasttemp = '2' AND
                                                       ((av.cdmotivoafasttemporario NOT IN
                                                       (SELECT cdmotivoafasttemporario
                                                              FROM epagrubagrupmotafasttempimp ai
                                                             WHERE AV.CdMotivoAfastTemporario =
                                                                   AI.CdMotivoAfastTemporario
                                                               AND AI.CdHistRubricaAgrupamento =
                                                                   pRubrica.CdHistRubrica)) OR
                                                       (SELECT COUNT(*)
                                                             FROM epagrubagrupmotafasttempimp ai
                                                            WHERE AI.CdHistRubricaAgrupamento =
                                                                  pRubrica.CdHistRubrica) = 0)))
                                                   AND AV.DtInicio <=
                                                       pdtFimMes
                                                   AND (AV.DtFim >=
                                                       pdtInicioMes OR
                                                       AV.DtFim IS NULL)) B
                                        ON (B.DtInicio <= D.dtdia)
                                       AND (B.DtFim >= D.dtdia)
                                    UNION
                                    SELECT dtdia
                                      FROM (SELECT pdtInicioMes + (LEVEL - 1) AS dtdia
                                              FROM dual
                                            CONNECT BY pdtInicioMes +
                                                       (LEVEL - 1) BETWEEN
                                                       pdtInicioMes AND
                                                       pdtFimMes) D
                                     INNER JOIN (SELECT CASE
                                                         WHEN AV.dtInicio <
                                                              pdtInicioMes THEN
                                                          pdtiniciomes
                                                         ELSE
                                                          av.dtinicio
                                                       END AS dtinicio,
                                                       CASE
                                                         WHEN (AV.dtFim >
                                                              pdtFimMes OR
                                                              AV.DtFim IS NULL) THEN
                                                          pdtfimmes
                                                         ELSE
                                                          av.dtfim
                                                       END AS dtfim
                                                  FROM eafaafastamentovinculo av
                                                 INNER JOIN eafahistmotivoafastdef hmad
                                                    ON AV.CdMotivoAfastDefinitivo =
                                                       HMAD.CdMotivoAfastDefinitivo
                                                 INNER JOIN (SELECT HMADV.CdMotivoAfastDefinitivo,
                                                                   MAX(HMADV.DtInicioVigencia) AS DtInicioVigencia
                                                              FROM eafahistmotivoafastdef hmadv
                                                             WHERE HMADV.dtInicioVigencia <=
                                                                   pdtFimMes
                                                             GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                                    ON HMAD.CdMotivoAfastDefinitivo =
                                                       MV.CdMotivoAfastDefinitivo
                                                   AND HMAD.Dtiniciovigencia =
                                                       MV.Dtiniciovigencia
                                                 WHERE AV.cdVinculo =
                                                       pFUC.cdVinculo
                                                   AND AV.FlAnulado =
                                                       PKGPAG_TIPO.cnN
                                                   AND HMAD.FlRemunerado =
                                                       PKGPAG_TIPO.cnN
                                                   AND AV.DtInicio <=
                                                       pdtFimMes
                                                   AND (AV.DtFim >=
                                                       pdtInicioMes OR
                                                       AV.DtFim IS NULL)) B
                                        ON (B.DtInicio <= D.dtdia)
                                       AND (B.DtFim >= D.dtdia))
                             GROUP BY x.cdhistfuncaochefia, y.dtdia) a
                     GROUP BY a.nucho);

            -- acerta valores

            if vnudiastotal = 2 and
               PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual = 29 and
               to_char(pdtfimmes, 'DD') = '31' then

              vNuDiasTotal := 1;

            end if;

            IF pkgpag_var.vgRubrica(pRubrica.CdRubricaAgrupamento)
             .NuRubrica = 433 and pkgpag_var.vgFolha.CdAgrupamento = 134 THEN

              IF vNuCho IS NULL THEN
                vNuCho := vnuchopadrao;
              END IF;

              IF vnudiastotal IS NULL THEN
                vnudiastotal := pkgpag_var.vgNuDiasFUC;
              END IF;

            END IF;

            vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pfuc.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                            pdtiniciorelacao => pfuc.dtinicio);

            -- Rubricas substituicao privativa Policia Militar 2801
            -- Descontar ajustar o indice de dias da substituicao ou descontar, dependendo
            -- do historico da funcao de chefia
            --
            IF pkgpag_var.vgNuDiasSubstFuc > 0 AND pkgpag_var.vgFUCSubst(1)
              .FlFuncaoGratificada = pkgpag_tipo.cnS AND
               pkgpag_var.vgListaRubFuncaoPrivativa.COUNT > 0 AND
               pkgpag_var.vgListaRubFuncaoPrivativa.EXISTS(prubrica.cdrubricaagrupamento) THEN
              IF pFuc.CdHistFuncaoChefia <> pkgpag_var.vgFUCSubst(1).CdHistFuncaoChefia AND
                 pkgpag_var.vgNuDiasFUC > 0

               THEN

                vNuDiasProp := pkgpag_var.vgNuDiasFUC;

              ELSE

                vNuDiasProp := pkgpag_var.vgNuDiasSubstFuc;

              END IF;

            END IF;
            ------SIG-10062
            if pkgpag_var.vgfolha.cdagrupamento = 176 and pnudiasmes = 30 and
               NVL(pkgpag_var.vgNuDiasSubst, 0) > 0 then
               vNuDiasProp := nvl(vNuDiasProp,0) - pkgpag_var.vgNuDiasSubst ;
            end if;


            IF pkgpag_var.vgfuc.count > 1 AND
               (pfuc.dtfim IS NULL OR to_char(pfuc.dtfim, 'DD') = '31')
               and vNuDiasProp > 30 THEN
              vnudiasprop := vnudiasprop - 1;
            END IF;

            vResult.vlIndice := vNuDiasProp;

            IF pNuDiasMes <> vNuDiasProp OR vnuchopadrao <> vNuCHO THEN

              vResult.vlProporcional := ((pValorIntegral / pNuDiasMes) *
                                        vNuDiasProp / vnuchopadrao *
                                        vNuCHO);

            ELSE
              vresult.vlproporcional := pvalorintegral;

            END IF;

            IF vnuchopadrao <> vnucho THEN

              vResult.vlReal := (pValorIntegral / vnuchopadrao * vNuCHO);

            ELSE

              vresult.vlreal := pvalorintegral;

            END IF;

          ELSE

            IF prubrica.flcargahorariapadrao = 'S' THEN

              vnuchopadrao := pfuc.nucargahorariapadrao;

              vdemensagem := 'Carga hor?ria padr?o da fun??o de chefia n?o est? definida.';

            ELSE

              vnuchopadrao := prubrica.nucargahorariasemanal;

              vDeMensagem := 'Carga hor?ria padr?o da rubrica ' ||
                             pRubrica.CdTipoRubrica || '-' ||
                             prubrica.nurubrica || ' n?o est? definida.';

            END IF;

            IF nvl(vnuchopadrao, 0) <= 0 THEN

              pInsereLog(PKGPAG_VAR.bLog,
                         PKGPAG_VAR.vCdHistParamCalc,
                         PKGPAG_VAR.vCdPessoa,
                         vDeMensagem,
                         pkgpag_var.vgcdvinculo);

            ELSE

              SELECT SUM(NuCHO * NuDias) / SUM(NuDias), SUM(NuDias)
                INTO vNuCHO, vNuDiasTotal
                FROM (SELECT a.nucho, COUNT(*) AS nudias
                        FROM (SELECT x.cdhistfuncaochefia,
                                     y.dtdia,
                                     SUM(x.nucargahoraria) AS nucho
                                FROM (SELECT pfuc.dtinicio + (LEVEL - 1) AS dtdia
                                        FROM dual
                                      CONNECT BY pFUC.dtInicio + (LEVEL - 1) BETWEEN
                                                 pFUC.dtInicio AND pFUC.dtFim) y
                               INNER JOIN (SELECT cdhistcargahoraria,
                                                 cdhistfuncaochefia,
                                                 dtinicial,
                                                 CASE
                                                   WHEN dtfim IS NULL THEN
                                                    pfuc.dtfim
                                                   ELSE
                                                    dtfim
                                                 END dtfim,
                                                 fltipoocupacao,
                                                 CASE
                                                  pRubrica.FlCargaHorariaLimitada
                                                   WHEN 'N' THEN
                                                    nucargahoraria
                                                   WHEN 'S' THEN
                                                    CASE
                                                      WHEN NuCargaHoraria >
                                                           vNuCHOPadrao THEN
                                                       vnuchopadrao
                                                      ELSE
                                                       nucargahoraria
                                                    END
                                                 END nucargahoraria
                                            FROM ecadhistcargahoraria hcho
                                           WHERE CdHistFuncaoChefia =
                                                 pFUC.CdHistFuncaoChefia
                                             AND DtInicial < pFUC.dtFim
                                             AND (dtFim > pFUC.dtInicio OR
                                                 dtFim IS NULL)
                                             AND flanulado = pkgpag_tipo.cnn) x
                                  ON (x.DtInicial <= y.dtdia)
                                 AND (x.DtFim >= y.dtdia)
                               WHERE y.dtdia NOT IN
                                     (SELECT dtdia
                                        FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                                FROM dual
                                              CONNECT BY pdtInicioMes +
                                                         (LEVEL - 1) BETWEEN
                                                         pdtInicioMes AND
                                                         pdtFimMes) D
                                       INNER JOIN (SELECT CASE
                                                           WHEN AV.dtInicio <
                                                                pdtInicioMes THEN
                                                            pdtiniciomes
                                                           ELSE
                                                            av.dtinicio
                                                         END AS dtinicio,
                                                         CASE
                                                           WHEN (AV.dtFim >
                                                                pdtFimMes OR
                                                                AV.DtFim IS NULL) THEN
                                                            pdtfimmes
                                                           ELSE
                                                            av.dtfim
                                                         END AS dtfim
                                                    FROM eafaafastamentovinculo av
                                                   INNER JOIN eafahistmotivoafasttemp hmat
                                                      ON Av.CdMotivoAfastTemporario =
                                                         HMAT.CdMotivoAfastTemporario
                                                   INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                                                     MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                                                FROM eafahistmotivoafasttemp hmatv
                                                               WHERE HMATV.dtInicioVigencia <=
                                                                     pdtFimMes
                                                               GROUP BY hmatv.cdmotivoafasttemporario) mv
                                                      ON HMAT.CdMotivoAfastTemporario =
                                                         MV.CdMotivoAfastTemporario
                                                     AND HMAT.DtInicioVigencia =
                                                         MV.DtInicioVigencia
                                                   WHERE AV.CdVinculo =
                                                         pFUC.cdVinculo
                                                     AND AV.FlAnulado =
                                                         PKGPAG_TIPO.cnN
                                                     AND pRubrica.FlPropAfastTempNaoRemun =
                                                         PKGPAG_TIPO.cnS
                                                     AND (HMAT.FlRemunerado =
                                                         PKGPAG_TIPO.cnN OR
                                                         (prubrica.ingerarubricaafasttemp = '1' AND
                                                         av.cdmotivoafasttemporario IN
                                                         (SELECT cdmotivoafasttemporario
                                                              FROM epagrubagrupmotafasttempimp ai
                                                             WHERE AI.CdMotivoAfastTemporario =
                                                                   AV.CdMotivoAfastTemporario
                                                               AND AI.CdHistRubricaAgrupamento =
                                                                   pRubrica.CdHistRubrica)) OR
                                                         (prubrica.ingerarubricaafasttemp = '2' AND
                                                         ((av.cdmotivoafasttemporario NOT IN
                                                         (SELECT cdmotivoafasttemporario
                                                                FROM epagrubagrupmotafasttempimp ai
                                                               WHERE AV.CdMotivoAfastTemporario =
                                                                     AI.CdMotivoAfastTemporario
                                                                 AND AI.CdHistRubricaAgrupamento =
                                                                     pRubrica.CdHistRubrica)) OR
                                                         (SELECT COUNT(*)
                                                               FROM epagrubagrupmotafasttempimp ai
                                                              WHERE AI.CdHistRubricaAgrupamento =
                                                                    pRubrica.CdHistRubrica) = 0)))
                                                     AND AV.DtInicio <=
                                                         pdtFimMes
                                                     AND (AV.DtFim >=
                                                         pdtInicioMes OR
                                                         AV.DtFim IS NULL)) B
                                          ON (B.DtInicio <= D.dtdia)
                                         AND (B.DtFim >= D.dtdia)
                                      UNION
                                      SELECT dtdia
                                        FROM (SELECT pdtInicioMes + (LEVEL - 1) AS dtdia
                                                FROM dual
                                              CONNECT BY pdtInicioMes +
                                                         (LEVEL - 1) BETWEEN
                                                         pdtInicioMes AND
                                                         pdtFimMes) D
                                       INNER JOIN (SELECT CASE
                                                           WHEN AV.dtInicio <
                                                                pdtInicioMes THEN
                                                            pdtiniciomes
                                                           ELSE
                                                            av.dtinicio
                                                         END AS dtinicio,
                                                         CASE
                                                           WHEN (AV.dtFim >
                                                                pdtFimMes OR
                                                                AV.DtFim IS NULL) THEN
                                                            pdtfimmes
                                                           ELSE
                                                            av.dtfim
                                                         END AS dtfim
                                                    FROM eafaafastamentovinculo av
                                                   INNER JOIN eafahistmotivoafastdef hmad
                                                      ON AV.CdMotivoAfastDefinitivo =
                                                         HMAD.CdMotivoAfastDefinitivo
                                                   INNER JOIN (SELECT HMADV.CdMotivoAfastDefinitivo,
                                                                     MAX(HMADV.DtInicioVigencia) AS DtInicioVigencia
                                                                FROM eafahistmotivoafastdef hmadv
                                                               WHERE HMADV.dtInicioVigencia <=
                                                                     pdtFimMes
                                                               GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                                      ON HMAD.CdMotivoAfastDefinitivo =
                                                         MV.CdMotivoAfastDefinitivo
                                                     AND HMAD.Dtiniciovigencia =
                                                         MV.Dtiniciovigencia
                                                   WHERE AV.cdVinculo =
                                                         pFUC.cdVinculo
                                                     AND AV.FlAnulado =
                                                         PKGPAG_TIPO.cnN
                                                     AND HMAD.FlRemunerado =
                                                         PKGPAG_TIPO.cnN
                                                     AND AV.DtInicio <=
                                                         pdtFimMes
                                                     AND (AV.DtFim >=
                                                         pdtInicioMes OR
                                                         AV.DtFim IS NULL)) B
                                          ON (B.DtInicio <= D.dtdia)
                                         AND (B.DtFim >= D.dtdia))
                               GROUP BY x.cdhistfuncaochefia, y.dtdia) a
                       GROUP BY a.nucho);

              -- acerta valores

              if vnudiastotal = 2 and
                 PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual = 29 and
                 to_char(pdtfimmes, 'DD') = '31' then

                vNuDiasTotal := 1;

              end if;

              IF pRubrica.NuRubrica = 433 and
                 pkgpag_var.vgFolha.CdAgrupamento = 134 THEN

                IF vNuCho IS NULL THEN
                  vNuCho := vnuchopadrao;
                END IF;

                IF vnudiastotal IS NULL THEN
                  IF pfuc.DtInicio = pfuc.dtfim THEN
                    vnudiastotal := 1;
                  ELSE
                    vnudiastotal := pkgpag_var.vgNuDiasFUC;
                  END IF;
                END IF;

                IF vnudiastotal > pnudiasmes THEN
                  vnudiastotal := pnudiasmes;
                END IF;

                IF pfuc.CdFuncaoChefia = 6228 then
                   vnudiastotal := 30 ;
                   pkgpag_var.vgNuDiasSubstFuc :=30;
                END IF;

              END IF;

              vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                              pnudiasmes       => pnudiasmes,
                                              pdtiniciomes     => pdtiniciomes,
                                              pdtfimmes        => pdtfimmes,
                                              pdtfimrelacao    => pfuc.dtfim,
                                              pnudiastotal     => vnudiastotal,
                                              pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                              pdtiniciorelacao => pfuc.dtinicio);

              --
              -- Rubricas substituicao privativa Policia Militar 2801
              -- Descontar ajustar o indice de dias da substituicao ou descontar, dependendo
              -- do historico da funcao de chefia
              --
              IF pkgpag_var.vgNuDiasSubstFuc > 0 AND pkgpag_var.vgFUCSubst(1)
                .FlFuncaoGratificada = pkgpag_tipo.cnS AND
                 pkgpag_var.vgListaRubFuncaoPrivativa.COUNT > 0 AND
                 pkgpag_var.vgListaRubFuncaoPrivativa.EXISTS(prubrica.cdrubricaagrupamento) THEN
                IF pFuc.CdHistFuncaoChefia <> pkgpag_var.vgFUCSubst(1).CdHistFuncaoChefia AND
                   pkgpag_var.vgNuDiasFUC > 0

                 THEN

                  vNuDiasProp := pkgpag_var.vgNuDiasFUC;

                ELSE

                  vNuDiasProp := pkgpag_var.vgNuDiasSubstFuc;

                END IF;

                IF vNuDiasProp > pnudiasmes THEN
                  vNuDiasProp := pnudiasmes;
                END IF;
              END IF;

              if pkgpag_var.vgfolha.cdagrupamento = 176 and pnudiasmes = 30 and
                 NVL(pkgpag_var.vgNuDiasSubst, 0) > 0 then
                vNuDiasProp := vNuDiasProp - pkgpag_var.vgNuDiasSubst;
              end if;

              IF pkgpag_var.vgfuc.count > 1 AND
                 (pfuc.dtfim IS NULL OR to_char(pfuc.dtfim, 'DD') = '31') and
                 vNuDiasProp > 30 THEN
                vnudiasprop := vnudiasprop - 1;
              END IF;

              -- AJUSTES
              IF vnudiasprop IS NULL AND pfuc.DtInicio = pfuc.dtfim THEN
                vnudiasprop := 1;
              END IF;

              IF vNuCho IS NULL AND pfuc.DtInicio = pfuc.dtfim THEN
                vNuCho := vnuchopadrao;
              END IF;

              --rubricas de Remunera??o fixa da fun??o de chefia
              /*if pRubrica.nurubrica in (11,211)
                and pkgpag_var.vgFolha.cdorgao = 443 -- defensoria
                and pkgpag_var.vgAfastTempRemun.Count > 0
                and (pfuc.DtFim is not null
                or pfuc.DtFim between pkgpag_var.vgFolha.dtiniciomes and pkgpag_var.vgFolha.dtfimmes)
                then

                   for j in pkgpag_var.vgAfastTempRemun.FIRST .. pkgpag_var.vgAfastTempRemun.LAST
                     loop
                     if pkgpag_var.vgAfastTempRemun(j).DtInicioAfaNoMes <= pfuc.DtFim
                       and pkgpag_var.vgAfastTempRemun(j).DtFimAfaNoMes >= pfuc.DtFim
                        then

                        vnudiasprop := vnudiasprop - (pfuc.DtFim - pkgpag_var.vgAfastTempRemun(j).DtInicioAfaNoMes+1);

                     elsif  pkgpag_var.vgAfastTempRemun(j).DtInicioAfaNoMes <= pfuc.DtFim and
                            pkgpag_var.vgAfastTempRemun(j).DtFimAfaNoMes <= pfuc.DtFim and
                            pFuc.DtInicio between pkgpag_var.vgAfastTempRemun(j).DtInicioAfaNoMes
                                             and pkgpag_var.vgAfastTempRemun(j).DtFimAfaNoMes
                        then

                        vnudiasprop := vnudiasprop - (pkgpag_var.vgAfastTempRemun(j).DtFimAfaNoMes - greatest(pFuc.DtInicio,pkgpag_var.vgAfastTempRemun(j).DtInicioAfaNoMes)+1);

                     else
                       null;
                     end if;

                   end loop;

              end if;*/

              vresult.vlindice := vnudiasprop;

              IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

                vResult.vlProporcional := ((pValorIntegral / pNuDiasMes) *
                                          vNuDiasProp / vNuCHOPadrao *
                                          vNuCHO);

              ELSE
                vresult.vlproporcional := pvalorintegral;

              END IF;

              IF vnuchopadrao <> vnucho THEN

                vresult.vlreal := (pvalorintegral / vnuchopadrao * vnucho);

              ELSE

                vresult.vlreal := pvalorintegral;

              END IF;

            END IF;

          END IF;

        END IF;
      WHEN prubrica.cdrubproporcionalidadecho = 3 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          vnuchopadrao := pfuc.nucargahorariapadrao;

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

        END IF;

        IF nvl(prubrica.numesesapuracao, 0) > 0 THEN

          vDtInicioPeriodo := ADD_MONTHS(pDtInicioMes,
                                         -pRubrica.NuMesesApuracao);

        ELSE

          vdtinicioperiodo := pdtiniciomes;

        END IF;

        vdtfimperiodo := last_day(pdtiniciomes);

        SELECT SUM(numediacho)
          INTO vnucho
          FROM (SELECT x.cdhistfuncaochefia,
                       SUM(x.nucargahoraria) / COUNT(DISTINCT dtdia) AS numediacho
                  FROM (SELECT vdtinicioperiodo + (LEVEL - 1) AS dtdia
                          FROM dual
                        CONNECT BY vdtInicioPeriodo + (LEVEL - 1) BETWEEN
                                   vdtInicioPeriodo AND vdtFimPeriodo) y
                 INNER JOIN (SELECT cdhistcargahoraria,
                                   cdhistfuncaochefia,
                                   dtinicial,
                                   CASE
                                     WHEN dtfim IS NULL THEN
                                      vdtfimperiodo
                                     ELSE
                                      dtfim
                                   END dtfim,
                                   fltipoocupacao,
                                   nucargahoraria
                              FROM ecadhistcargahoraria hcho
                             WHERE CdHistFuncaoChefia =
                                   pFUC.CdHistFuncaoChefia
                               AND DtInicial < vdtFimPeriodo
                               AND (dtFim > vdtInicioPeriodo OR
                                   dtFim IS NULL)
                               AND FlAnulado = PKGPAG_TIPO.cnN) x
                    ON (x.DtInicial <= y.dtdia)
                   AND (x.DtFim >= y.dtdia)
                 GROUP BY x.cdhistfuncaochefia);

        vnudiastotal := (pfuc.dtfim - pfuc.dtinicio) + 1;

        -- acerta valores

        if vnudiastotal = 2 and
           PKGPAG_VAR.vgNuDiasAfastSemRemunMesAtual = 29 and
           to_char(pdtfimmes, 'DD') = '31' then

          vNuDiasTotal := 1;

        end if;

        vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                        pnudiasmes       => pnudiasmes,
                                        pdtiniciomes     => pdtiniciomes,
                                        pdtfimmes        => pdtfimmes,
                                        pdtfimrelacao    => pfuc.dtfim,
                                        pnudiastotal     => vnudiastotal,
                                        pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                        pdtiniciorelacao => pfuc.dtinicio);

        vresult.vlindice := vnudiasprop;

        IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

          vResult.vlProporcional := ((pValorIntegral / pNuDiasMes) *
                                    vNuDiasProp / vNuCHOPadrao * vNuCHO);

        ELSE
          vresult.vlproporcional := pvalorintegral;

        END IF;

        IF vnuchopadrao <> vnucho THEN

          vresult.vlreal := (pvalorintegral / vnuchopadrao * vnucho);

        ELSE

          vresult.vlreal := pvalorintegral;

        END IF;

    END CASE;

    vresult.vlintegral := vresult.vlproporcional;

    RETURN vresult;

  EXCEPTION

    WHEN OTHERS THEN

      vresult.vlproporcional := 0;

      vresult.vlindice := 0;

      RETURN vresult;

  END;

  /*----------------------------------------------------------------------------/
    Procedure: FCalculaPropAPO

    -  Recebe o codigo da relacao de cargo efetivo finalizada

  /----------------------------------------------------------------------------*/
  FUNCTION fcalculaproporcapo(pfolha         IN pkgpag_tipo.rfolha,
                              papo           IN pkgpag_tipo.rcef,
                              pnudiasmes     IN INTEGER,
                              prubrica       IN pkgpag_tipo.rrubrica,
                              pvalorintegral IN NUMBER)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vresult      pkgpag_tipo.rvalorpagamento;
    vvalorfixo   pkgpag_tipo.rvalorfixo;
    vnuchopadrao NUMBER(7, 4);
    vnucho       NUMBER(7, 4);
    vdemensagem  VARCHAR2(200);
    vnudiasprop  INTEGER;

  BEGIN
 
    vresult.vlintegral := pvalorintegral;

    IF nvl(papo.vlpercentpropapo, 0) NOT IN (0, 100) THEN

      IF prubrica.flpropaposparidade = 'S' THEN

        vresult.vlintegral := pvalorintegral * papo.vlpercentpropapo / 100;

      END IF;

    END IF;

    vresult.vlreal := vresult.vlintegral;

    IF prubrica.flpropservrelvinc = 'S' THEN

      vresult.vlindice := pkgpag_geral.fretornaindice(prubrica.flpropmescomercial,
                                                      pfolha.dtiniciomes,
                                                      pfolha.dtfimmes,
                                                      pAPO.DtInicio,
                                                      pAPO.DtFim);
    ELSE

      vresult.vlindice := pkgpag_geral.fretornaindice(prubrica.flpropmescomercial,
                                                      pfolha.dtiniciomes,
                                                      pfolha.dtfimmes,
                                                      pfolha.dtiniciomes,
                                                      pfolha.dtfimmes);

    END IF;

    vresult.vlproporcional := pkgpag_geral.fcalculavalorpropdias(prubrica.flpropservrelvinc,
                                                                 vresult.vlintegral,
                                                                 pnudiasmes,
                                                                 vresult.vlindice);

    vnudiasprop := vresult.vlindice;

    CASE

      WHEN prubrica.cdrubproporcionalidadecho = 1 THEN

        RETURN vresult;

      WHEN prubrica.cdrubproporcionalidadecho = 2 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          -----------------------------------------------------------------------------------
          -- Estudar para saber se e necessario chamar a funcao, uma vez que
          -- na remuneracao fixa do APO o valor ja e armazenado na PKGPAG_VAR.vgValorFixoCEF
          -----------------------------------------------------------------------------------

          vvalorfixo := pkgpag_geral.fretonavalorfixocef(pfolha.cdagrupamento,
                                                         pfolha.cdorgao,
                                                         pfolha.nuversaotabcef,
                                                         pfolha.nuanoreferencia,
                                                         pfolha.numesreferencia,
                                                         papo.cdestruturacarreira,
                                                         papo.cdestruturacarreiracarreira,
                                                         papo.nunivelpagamento,
                                                         papo.nureferenciapagamento);

          vnuchopadrao := vvalorfixo.nucargahoraria;

          vdemensagem := 'Carga hor?ria padr?o da carreira do aposentado n?o est? definida.';

          -- Se existe parametrizacao de locais de trabalho com valores de carga horaria
          -- especificas, assume esta carga horaria

          IF prubrica.lsloccho.first IS NOT NULL THEN

            IF papo.cdunidadeorganizacional IS NOT NULL AND
               prubrica.lsloccho.exists(papo.cdunidadeorganizacional) THEN

              vnuchopadrao := prubrica.lsloccho(papo.cdunidadeorganizacional);

            END IF;

          END IF;

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

          vDeMensagem := 'Carga hor?ria padr?o da rubrica ' ||
                         pRubrica.CdTipoRubrica || '-' ||
                         prubrica.nurubrica || ' n?o est? definida.';

        END IF;

        IF vnuchopadrao <= 0 THEN

          vresult.vlproporcional := 0;

          pInsereLog(PKGPAG_VAR.bLog,
                     PKGPAG_VAR.vCdHistParamCalc,
                     PKGPAG_VAR.vCdPessoa,
                     vDeMensagem,
                     pkgpag_var.vgcdvinculo);
        ELSE

          -- BUSCA CARGA HORARIA DA APOSENTADORIA
          vnucho := papo.nucargahoraria;

          -- LIMITA A CARGA HORARIA PADRAO
          IF prubrica.flcargahorarialimitada = 'S' AND
             vnucho > vnuchopadrao THEN

            vnucho := vnuchopadrao;

          END IF;

          IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

            vResult.vlProporcional := ((vResult.vlIntegral / pNuDiasMes) *
                                      vNuDiasProp / vNuCHOPadrao * vNuCHO);

          ELSE
            vresult.vlproporcional := vresult.vlintegral;

          END IF;

          IF vnuchopadrao <> vnucho THEN

            vresult.vlreal := (vresult.vlintegral / vnuchopadrao * vnucho);

          ELSE

            vresult.vlreal := vresult.vlintegral;

          END IF;

        END IF;

      WHEN prubrica.cdrubproporcionalidadecho = 3 THEN

        NULL;

    END CASE;

    vresult.vlintegral := vresult.vlproporcional;

    RETURN vresult;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  /*--------------------------------------------------------------------------------------/*

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fcalculaproporccco(pcco           IN pkgpag_tipo.rcco,
                              pnudiasmes     IN INTEGER,
                              prubrica       IN pkgpag_tipo.rrubrica,
                              pvalorintegral IN NUMBER,
                              pdtiniciomes   IN DATE,
                              pdtfimmes      IN DATE)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vnuchopadrao     NUMBER(7, 4);
    vdtinicioperiodo DATE;
    vdtfimperiodo    DATE;
    vresult          pkgpag_tipo.rvalorpagamento;
    vdemensagem      VARCHAR2(200);
    vdtinicio        DATE;
    vdtfim           DATE;
    vnudiastotal     NUMBER;
    vnudiasintegral  NUMBER;
    vnudiasprop      NUMBER;
    --vcdtipoorigemrubrica NUMBER;
    vnucho    NUMBER(7, 4);
    vnuindice NUMBER;
    --vnudiasafasti INTEGER := 0;
    vnudiastotalImp  NUMBER := 0;
    vnudiascco       NUMBER;
    vcdRubAgr01_0211 NUMBER;
    vcdRubAgr01_0005 NUMBER;
    vcdRubAgr01_0279 number;
    vcdRubAgr01_0219 number;
    bAbate           BOOLEAN;

  BEGIN
 
    vnudiascco := pcco.QtNuDiasCCO;
    if (vnudiascco > pnudiasmes) then
      vnudiascco := pnudiasmes;
    end if;

    vResult.vlIndice := PKGPAG_GERAL.FRetornaIndice(pRubrica.FlPropMesComercial,
                                                    pDtInicioMes,
                                                    pDtFimMes,
                                                    pCCO.DtInicio,
                                                    pCCO.DtFim);


   -- Para um unico CCO iniciado no dia 2 deve ser considerado o dia 31
   -- SIG-9405 Questionamento de indice
    if vNuDiasCCO = 30 and pkgpag_var.vgCco.Count = 1 and vResult.vlIndice < vNuDiasCco then

       vResult.vlIndice := vNuDiasCCO;

    end if;

    if pcco.FlTipoProvimento = 'S' then
      vResult.vlIndice := pkgpag_var.vgNuDiasSubst;
    else
      if pkgpag_var.vgCCOSubst.count > 0 then

        for i in pkgpag_var.vgCCOSubst.First .. pkgpag_var.vgCCOSubst.last loop
          if pkgpag_var.vgCCOSubst(i)
           .dtinicio between pCco.DtInicio and pCCo.DtFim then

            begin
              vcdRubAgr01_0211 := fretornarubrica(pkgpag_var.vgFolha.cdAgrupamento,
                                                  1,
                                                  211);
              vcdRubAgr01_0219 := fretornarubrica(pkgpag_var.vgFolha.cdAgrupamento,
                                                  1,
                                                  219);
              vcdRubAgr01_0005 := fretornarubrica(pkgpag_var.vgFolha.cdAgrupamento,
                                                  1,
                                                  005);
              vcdRubAgr01_0279 := fretornarubrica(pkgpag_var.vgFolha.cdAgrupamento,
                                                  1,
                                                  279);
              if (pRubrica.CdRubricaAgrupamento IN
                 (vcdRubAgr01_0211, vcdRubAgr01_0005, vcdRubAgr01_0279,vcdRubAgr01_0219)) then
                vresult.vlIndice := vnudiascco;
              else
                vresult.vlIndice := greatest(vnudiascco -
                                             (pkgpag_var.vgCCOSubst(i).dtfim - pkgpag_var.vgCCOSubst(i).dtinicio + 1),
                                             0);
              end if;
            end;
          else
            vresult.vlIndice := vnudiascco;
          end if;
        end loop;

      end if;
    end if;

    IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao THEN

      vresult.vlreal         := pvalorintegral;
      vresult.vlintegral     := pvalorintegral;
      vresult.vlproporcional := pvalorintegral;

      RETURN vresult;

    END IF;

    vresult.vlreal := pvalorintegral;

    vResult.VlProporcional := PKGPAG_GERAL.FCalculaValorPropDias(pRubrica.FlPropServRelVinc,
                                                                 pvalorintegral,
                                                                 pnudiasmes,
                                                                 vresult.vlindice);

    --Se nao aplica CHO e a rubrica manda proporcionalizar os afastamentos temp/def nao remunerados

    CASE
      WHEN prubrica.cdrubproporcionalidadecho = 1 THEN

        IF prubrica.flpropafasttempnaoremun = pkgpag_tipo.cns THEN

          IF prubrica.flpropservrelvinc = 'N' THEN

            vdtinicio := pdtiniciomes;
            vdtfim    := pdtfimmes;

          ELSE

            vdtinicio := pcco.dtinicio;
            vdtfim    := pcco.dtfim;

            --
            -- Solicitacao de Sustentacao #78891
            -- 11606/2018 - SUBSTITUICAO CUMULATIVAMENTE PGE
            --
            if pRubrica.FlPagaSubstituicao = 'S' and
               pkgpag_var.vgNuDiasSubst > 0 and pkgpag_var.vgNuDiascco > 0 then
              for i in pkgpag_var.vgCCOSubst.First .. pkgpag_var.vgCCOSubst.last loop
                if pcco.CdHistCargoCom <> pkgpag_var.vgCCOSubst(i).cdhistcargocom then
                  if pCco.DtInicio = pkgpag_var.vgCCOSubst(i).DtInicio then
                    vdtinicio := pkgpag_var.vgCCOSubst(i).DtFim + 1;
                  end if;

                  if pCco.DtFim <= pkgpag_var.vgCCOSubst(i).DtFim and
                     pCco.DtFim > pkgpag_var.vgCCOSubst(i).DtInicio then
                    vdtfim := pkgpag_var.vgCCOSubst(i).DtInicio - 1;
                  end if;
                end if;
              end loop;
            end if;
          END IF;

          SELECT COUNT(*) AS nudiastotal
            INTO vnudiastotal
            FROM (SELECT y.dtdia
                    FROM (SELECT vdtinicio + (LEVEL - 1) AS dtdia
                            FROM dual
                          CONNECT BY vDtInicio + (LEVEL - 1) BETWEEN
                                     vDtInicio AND vDtFim) y
                   WHERE y.dtdia NOT IN
                         (SELECT dtdia
                            FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                    FROM dual
                                  CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                             pdtInicioMes AND pdtFimMes) D
                           INNER JOIN (SELECT CASE
                                               WHEN av.dtinicio < pdtiniciomes THEN
                                                pdtiniciomes
                                               ELSE
                                                av.dtinicio
                                             END AS dtinicio,
                                             CASE
                                               WHEN (AV.dtFim > pdtFimMes OR
                                                    AV.DtFim IS NULL) THEN
                                                pdtfimmes
                                               ELSE
                                                av.dtfim
                                             END AS dtfim
                                        FROM eafaafastamentovinculo av
                                       INNER JOIN eafahistmotivoafasttemp hmat
                                          ON Av.CdMotivoAfastTemporario =
                                             HMAT.CdMotivoAfastTemporario
                                       INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                                         MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                                    FROM eafahistmotivoafasttemp hmatv
                                                   WHERE HMATV.dtInicioVigencia <=
                                                         pdtFimMes
                                                   GROUP BY hmatv.cdmotivoafasttemporario) mv
                                          ON HMAT.CdMotivoAfastTemporario =
                                             MV.CdMotivoAfastTemporario
                                         AND HMAT.Dtiniciovigencia =
                                             MV.Dtiniciovigencia
                                       WHERE AV.cdVinculo = pCCO.cdVinculo
                                         AND AV.FlAnulado = PKGPAG_TIPO.cnN
                                         AND (HMAT.FlRemunerado =
                                             PKGPAG_TIPO.cnN OR
                                             (prubrica.ingerarubricaafasttemp = '1' AND
                                             av.cdmotivoafasttemporario IN
                                             (SELECT cdmotivoafasttemporario
                                                  FROM epagrubagrupmotafasttempimp ai
                                                 WHERE AI.CdMotivoAfastTemporario =
                                                       AV.CdMotivoAfastTemporario
                                                   AND AI.CdHistRubricaAgrupamento =
                                                       pRubrica.CdHistRubrica)) OR
                                             (prubrica.ingerarubricaafasttemp = '2' AND
                                             ((av.cdmotivoafasttemporario NOT IN
                                             (SELECT cdmotivoafasttemporario
                                                    FROM epagrubagrupmotafasttempimp ai
                                                   WHERE AV.CdMotivoAfastTemporario =
                                                         AI.CdMotivoAfastTemporario
                                                     AND AI.CdHistRubricaAgrupamento =
                                                         pRubrica.CdHistRubrica)) OR
                                             (SELECT COUNT(*)
                                                   FROM epagrubagrupmotafasttempimp ai
                                                  WHERE AI.CdHistRubricaAgrupamento =
                                                        pRubrica.CdHistRubrica) = 0)))
                                         AND AV.DtInicio <= pdtFimMes
                                         AND (AV.DtFim >= pdtInicioMes OR
                                             AV.DtFim IS NULL)) B
                              ON (B.DtInicio <= D.dtdia)
                             AND (B.DtFim >= D.dtdia)
                          UNION
                          SELECT dtdia
                            FROM (SELECT pdtInicioMes + (LEVEL - 1) AS dtdia
                                    FROM dual
                                  CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                             pdtInicioMes AND pdtFimMes) D
                           INNER JOIN (SELECT CASE
                                               WHEN av.dtinicio < pdtiniciomes THEN
                                                pdtiniciomes
                                               ELSE
                                                av.dtinicio
                                             END AS dtinicio,
                                             CASE
                                               WHEN (AV.dtFim > pdtFimMes OR
                                                    AV.DtFim IS NULL) THEN
                                                pdtfimmes
                                               ELSE
                                                av.dtfim
                                             END AS dtfim
                                        FROM eafaafastamentovinculo av
                                       INNER JOIN eafahistmotivoafastdef hmad
                                          ON AV.CdMotivoAfastDefinitivo =
                                             HMAD.CdMotivoAfastDefinitivo
                                       INNER JOIN (SELECT HMADV.CdMotivoAfastDefinitivo,
                                                         MAX(HMADV.DtInicioVigencia) AS DtInicioVigencia
                                                    FROM eafahistmotivoafastdef hmadv
                                                   WHERE HMADV.dtInicioVigencia <=
                                                         pdtFimMes
                                                   GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                          ON HMAD.CdMotivoAfastDefinitivo =
                                             MV.CdMotivoAfastDefinitivo
                                         AND HMAD.Dtiniciovigencia =
                                             MV.Dtiniciovigencia
                                       WHERE AV.CdVinculo = pCCO.CdVinculo
                                         AND AV.FlAnulado = PKGPAG_TIPO.cnN
                                         AND HMAD.FlRemunerado =
                                             PKGPAG_TIPO.cnN
                                         AND AV.DtInicio <= pdtFimMes
                                         AND (AV.DtFim >= pdtInicioMes OR
                                             AV.DtFim IS NULL)) B
                              ON (B.DtInicio <= D.dtdia)
                             AND (B.DtFim >= D.dtdia))
                   GROUP BY y.dtdia);

          -- acerta valores

          if vnudiastotal >
             NVL(pkgpag_var.vgNuDiasCco, pkgpag_var.vgnudiassubst) then
            vnudiastotal := NVL(pkgpag_var.vgNuDiasCco,
                                pkgpag_var.vgnudiassubst);
          end if;

          if vNuDiasTotal > vResult.vlIndice and
             to_char(pDtFimMes, 'DD') = '31' then
            vNuDiasTotal := vResult.vlIndice;
          end if;

          IF pRubrica.FlPagaSubstituicao = 'S' AND
             pkgpag_var.vgNuDiasSubst + vNuDiasTotal > 30 THEN
             
             bAbate := TRUE;
             
             FOR i IN pkgpag_var.vgCCOSubst.First .. pkgpag_var.vgCCOSubst.last LOOP
               
               IF TO_CHAR(pkgpag_var.vgCCOSubst(i).DtFimRelacao,'DD') = 31 THEN
                 
                 bAbate := FALSE;
                                                   
               END IF;
               
             END LOOP;
             
             IF bAbate THEN
               
               vNuDiasTotal := vNuDiasTotal - 1;
               
             END IF;  
             
          END IF;
             
          /*if pkgpag_var.vgfolha.cdagrupamento = 176 and
             NVL(pkgpag_var.vgNuDiasSubst, 0) > 0 then
            vNuDiasProp := vResult.vlIndice;
          else*/
            vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pcco.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                            pdtiniciorelacao => pcco.dtinicio);
          --end if;

          vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                              pnudiasmes       => pnudiasmes,
                                              pdtiniciomes     => pdtiniciomes,
                                              pdtfimmes        => pdtfimmes,
                                              pdtfimrelacao    => pcco.dtfim,
                                              pnudiastotal     => vnudiastotal,
                                              pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                              pdtiniciorelacao => pcco.dtinicio);

          vresult.vlindice := vnudiasprop;

          IF pnudiasmes <> vnudiasprop THEN

            vResult.vlProporcional := (pValorIntegral / pNuDiasMes) *
                                      vNuDiasProp;

          ELSE
            vresult.vlproporcional := pvalorintegral;

          END IF;

          IF pnudiasmes <> vnudiasintegral THEN

            vResult.vlIntegral := (pValorIntegral / pNuDiasMes) *
                                  vNuDiasIntegral;

          ELSE

            vresult.vlintegral := pvalorintegral;

          END IF;

        END IF;

      WHEN prubrica.cdrubproporcionalidadecho = 2 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          vnuchopadrao := pcco.nucargahorariapadrao;

          vdemensagem := 'Carga hor?ria padr?o do cargo comissionado n?o est? definida.';

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

          vDeMensagem := 'Carga hor?ria padr?o da rubrica ' ||
                         pRubrica.CdTipoRubrica || '-' ||
                         prubrica.nurubrica || ' n?o est? definida.';

        END IF;

        IF nvl(vnuchopadrao, 0) <= 0 THEN

          pInsereLog(PKGPAG_VAR.bLog,
                     PKGPAG_VAR.vCdHistParamCalc,
                     PKGPAG_VAR.vCdPessoa,
                     vDeMensagem,
                     pkgpag_var.vgcdvinculo);
        ELSE
          SELECT nvl(SUM(nucho * nudias) / SUM(nudias), 0),
                 nvl(SUM(nudias), 0)
            INTO vNuCHO, vNuDiasTotal
            FROM (SELECT a.nucho, COUNT(*) AS nudias
                    FROM (SELECT x.cdhistcargocom,
                                 y.dtdia,
                                 SUM(x.nucargahoraria) AS nucho
                            FROM (SELECT pcco.dtinicio + (LEVEL - 1) AS dtdia
                                    FROM dual
                                  CONNECT BY pCCO.dtInicio + (LEVEL - 1) BETWEEN
                                             pCCO.dtInicio AND pCCO.dtFim) y
                           INNER JOIN (SELECT cdhistcargahoraria,
                                             cdhistcargocom,
                                             dtinicial,
                                             CASE
                                               WHEN dtfim IS NULL THEN
                                                pcco.dtfim
                                               ELSE
                                                dtfim
                                             END dtfim,
                                             fltipoocupacao,
                                             CASE
                                              pRubrica.FlCargaHorariaLimitada
                                               WHEN 'N' THEN
                                                nucargahoraria
                                               WHEN 'S' THEN
                                                CASE
                                                  WHEN NuCargaHoraria >
                                                       vNuCHOPadrao THEN
                                                   vnuchopadrao
                                                  ELSE
                                                   nucargahoraria
                                                END
                                             END nucargahoraria
                                        FROM ecadhistcargahoraria hcho
                                       WHERE CdHistCargoCom =
                                             pCCO.CdHistCargoCom
                                         AND DtInicial <= pCCO.dtFim
                                         AND (dtFim >= pCCO.dtInicio OR
                                             dtFim IS NULL)
                                         AND FlAnulado = PKGPAG_TIPO.cnN
                                         and nvl(hcho.nucargahoraria, 0) > 0) x
                              ON (x.DtInicial <= y.dtdia)
                             AND (x.DtFim >= y.dtdia)
                           WHERE y.dtdia NOT IN
                                 (SELECT dtdia
                                    FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                            FROM dual
                                          CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                                     pdtInicioMes AND pdtFimMes) D
                                   INNER JOIN (SELECT CASE
                                                       WHEN AV.dtInicio <
                                                            pdtInicioMes THEN
                                                        pdtiniciomes
                                                       ELSE
                                                        av.dtinicio
                                                     END AS dtinicio,
                                                     CASE
                                                       WHEN (AV.dtFim >
                                                            pdtFimMes OR
                                                            AV.DtFim IS NULL) THEN
                                                        pdtfimmes
                                                       ELSE
                                                        av.dtfim
                                                     END AS dtfim
                                                FROM eafaafastamentovinculo av
                                               INNER JOIN eafahistmotivoafasttemp hmat
                                                  ON Av.CdMotivoAfastTemporario =
                                                     HMAT.CdMotivoAfastTemporario
                                               INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                                                 MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                                            FROM eafahistmotivoafasttemp hmatv
                                                           WHERE HMATV.dtInicioVigencia <=
                                                                 pdtFimMes
                                                           GROUP BY hmatv.cdmotivoafasttemporario) mv
                                                  ON HMAT.CdMotivoAfastTemporario =
                                                     MV.CdMotivoAfastTemporario
                                                 AND HMAT.DtInicioVigencia =
                                                     MV.DtInicioVigencia
                                               WHERE AV.CdVinculo =
                                                     pCCO.CdVinculo
                                                 AND AV.FlAnulado =
                                                     PKGPAG_TIPO.cnN
                                                 AND pRubrica.FlPropAfastTempNaoRemun =
                                                     PKGPAG_TIPO.cnS
                                                 AND (HMAT.FlRemunerado =
                                                     PKGPAG_TIPO.cnN OR
                                                     (prubrica.ingerarubricaafasttemp = '1' AND
                                                     av.cdmotivoafasttemporario IN
                                                     (SELECT cdmotivoafasttemporario
                                                          FROM epagrubagrupmotafasttempimp ai
                                                         WHERE AI.CdMotivoAfastTemporario =
                                                               AV.CdMotivoAfastTemporario
                                                           AND AI.CdHistRubricaAgrupamento =
                                                               pRubrica.CdHistRubrica)) OR
                                                     (prubrica.ingerarubricaafasttemp = '2' AND
                                                     ((av.cdmotivoafasttemporario NOT IN
                                                     (SELECT cdmotivoafasttemporario
                                                            FROM epagrubagrupmotafasttempimp ai
                                                           WHERE AV.CdMotivoAfastTemporario =
                                                                 AI.CdMotivoAfastTemporario
                                                             AND AI.CdHistRubricaAgrupamento =
                                                                 pRubrica.CdHistRubrica)) OR
                                                     (SELECT COUNT(*)
                                                           FROM epagrubagrupmotafasttempimp ai
                                                          WHERE AI.CdHistRubricaAgrupamento =
                                                                pRubrica.CdHistRubrica) = 0)))
                                                 AND AV.DtInicio <= pdtFimMes
                                                 AND (AV.DtFim >= pdtInicioMes OR
                                                     AV.DtFim IS NULL)) B
                                      ON (B.DtInicio <= D.dtdia)
                                     AND (B.DtFim >= D.dtdia)
                                  UNION
                                  SELECT dtdia
                                    FROM (SELECT pdtInicioMes + (LEVEL - 1) AS dtdia
                                            FROM dual
                                          CONNECT BY pdtInicioMes + (LEVEL - 1) BETWEEN
                                                     pdtInicioMes AND pdtFimMes) D
                                   INNER JOIN (SELECT CASE
                                                       WHEN AV.dtInicio <
                                                            pdtInicioMes THEN
                                                        pdtiniciomes
                                                       ELSE
                                                        av.dtinicio
                                                     END AS dtinicio,
                                                     CASE
                                                       WHEN (AV.dtFim >
                                                            pdtFimMes OR
                                                            AV.DtFim IS NULL) THEN
                                                        pdtfimmes
                                                       ELSE
                                                        av.dtfim
                                                     END AS dtfim
                                                FROM eafaafastamentovinculo av
                                               INNER JOIN eafahistmotivoafastdef hmad
                                                  ON AV.CdMotivoAfastDefinitivo =
                                                     HMAD.CdMotivoAfastDefinitivo
                                               INNER JOIN (SELECT HMADV.CdMotivoAfastDefinitivo,
                                                                 MAX(HMADV.DtInicioVigencia) AS DtInicioVigencia
                                                            FROM eafahistmotivoafastdef hmadv
                                                           WHERE HMADV.dtInicioVigencia <=
                                                                 pdtFimMes
                                                           GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                                  ON HMAD.CdMotivoAfastDefinitivo =
                                                     MV.CdMotivoAfastDefinitivo
                                                 AND HMAD.Dtiniciovigencia =
                                                     MV.Dtiniciovigencia
                                               WHERE AV.CdVinculo =
                                                     pCCO.cdVinculo
                                                 AND AV.FlAnulado =
                                                     PKGPAG_TIPO.cnN
                                                 AND HMAD.FlRemunerado =
                                                     PKGPAG_TIPO.cnN
                                                 AND AV.DtInicio <= pdtFimMes
                                                 AND (AV.DtFim >= pdtInicioMes OR
                                                     AV.DtFim IS NULL)) B
                                      ON (B.DtInicio <= D.dtdia)
                                     AND (B.DtFim >= D.dtdia))
                           GROUP BY x.cdhistcargocom, y.dtdia) a
                   GROUP BY a.nucho);

          IF vnudiastotal > 30 THEN
            vnudiastotal := 30;
          END IF;

          -- acerta valores
          IF pkgpag_var.vgCCOSubst.count > 0 AND
             prubrica.FlPropAfaCCOSubst = 'S' then
            if vnudiastotal > pkgpag_var.vgNuDiasSubst then
              vnudiastotal := vnudiastotal - pkgpag_var.vgNuDiasSubst;
            end if;

          else

            if vnudiastotal > pkgpag_var.vgNuDiasCco then
              vnudiastotal := pkgpag_var.vgNuDiasCco;
            end if;

          end if;

          IF vNuDiasTotal > vResult.vlIndice AND
             to_char(pDtFimMes, 'DD') = '31' AND
             pcco.DtInicio = pdtiniciomes AND PCCO.DtFim = pdtfimmes THEN
            vNuDiasTotal := vResult.vlIndice;
          END IF;

          if pkgpag_var.vgfolha.cdagrupamento = 176 and
             NVL(pkgpag_var.vgNuDiasSubst, 0) > 0 then
            vNuDiasProp := vResult.vlIndice -  NVL(pkgpag_var.vgNuDiasSubst, 0); /* Demanda 22183/2025 - João Ricardo.*/
          else
            vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pcco.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                            pdtiniciorelacao => pcco.dtinicio);
          end if;

          vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                              pnudiasmes       => pnudiasmes,
                                              pdtiniciomes     => pdtiniciomes,
                                              pdtfimmes        => pdtfimmes,
                                              pdtfimrelacao    => pcco.dtfim,
                                              pnudiastotal     => vnudiastotal,
                                              pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                              pdtiniciorelacao => pcco.dtinicio);

          -- PARAMETRO: Se tem afastamento remunerado, conta os dias
          IF pRubrica.CdRubricaAgrupamento = 10453 AND
             PKGPAG_VAR.vgAfastTempRemun.COUNT > 0 THEN
            FOR i IN PKGPAG_VAR.vgAfastTempRemun.FIRST .. PKGPAG_VAR.vgAfastTempRemun.LAST LOOP

              --Para a rubrica 01-0403 verifica se existe afastamento impeditivo
              IF pRubrica.lsMotAfastTempImp.exists(PKGPAG_VAR.vgAfastTempRemun(i).CdMotivoAfastamento) THEN

                --Soma o numero de dias que o servidor esta afastado
                vnudiastotalImp := vnudiastotalImp +
                                   (PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfa - PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfa) + 1;

              END IF;
            END LOOP;

          END IF;

          -- CASO O AFASTAMENTO SEJA MENOR QUE 30 DIAS PAGA INTEGRAL
          IF pRubrica.CdRubricaAgrupamento = 10453 AND vnudiastotalImp < 30 AND
             vnudiastotalImp > 0 THEN
            -- Todos os afastamentos encontrados sao impeditivos
            vnudiasprop      := 30;
            vnudiasintegral  := 30;
            vresult.vlindice := vnudiasprop;
          END IF;

          -- POG 01-0422: Rubrica de substituicao deve pagar exatamente o numero de dias da substituicao
          IF pRubrica.CdRubricaAgrupamento = 8214 AND
             PKGPAG_VAR.vgCCOSubst.Count = 1 AND
             nvl(pkgpag_var.vgnudiassubst, 0) > 0 THEN

            vnudiasprop := pkgpag_var.vgnudiassubst;

          END IF;

          vresult.vlindice := vnudiasprop;

          IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

            vResult.vlProporcional := ROUND(((pValorIntegral / pNuDiasMes) *
                                            vNuDiasProp / vNuCHOPadrao *
                                            vNuCHO),
                                            2);

          ELSE
            vresult.vlproporcional := pvalorintegral;

          END IF;

          IF pnudiasmes <> vnudiasintegral OR vnuchopadrao <> vnucho THEN

            vResult.vlIntegral := ROUND(((pValorIntegral / pNuDiasMes) *
                                        vNuDiasIntegral / vNuCHOPadrao *
                                        vNuCHO),
                                        2);

          ELSE

            vresult.vlintegral := pvalorintegral;

          END IF;

          IF vnuchopadrao <> vnucho THEN

            vResult.vlReal := ROUND((pValorIntegral / vNuCHOPadrao * vNuCHO),
                                    2);

          ELSE

            vresult.vlreal := pvalorintegral;

          END IF;

        END IF;

      WHEN prubrica.cdrubproporcionalidadecho = 3 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          vnuchopadrao := pcco.nucargahorariapadrao;

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

        END IF;

        IF nvl(prubrica.numesesapuracao, 0) > 0 THEN

          vDtInicioPeriodo := ADD_MONTHS(pDtInicioMes,
                                         -pRubrica.NuMesesApuracao);

        ELSE

          vdtinicioperiodo := pdtiniciomes;

        END IF;

        vdtfimperiodo := last_day(pdtiniciomes);

        SELECT SUM(numediacho)
          INTO vnucho
          FROM (SELECT x.cdhistcargocom,
                       SUM(x.nucargahoraria) / COUNT(DISTINCT dtdia) AS numediacho
                  FROM (SELECT vdtinicioperiodo + (LEVEL - 1) AS dtdia
                          FROM dual
                        CONNECT BY vdtInicioPeriodo + (LEVEL - 1) BETWEEN
                                   vdtInicioPeriodo AND vdtFimPeriodo) y
                 INNER JOIN (SELECT cdhistcargahoraria,
                                   cdhistcargocom,
                                   dtinicial,
                                   CASE
                                     WHEN dtfim IS NULL THEN
                                      vdtfimperiodo
                                     ELSE
                                      dtfim
                                   END dtfim,
                                   fltipoocupacao,
                                   nucargahoraria
                              FROM ecadhistcargahoraria hcho
                             WHERE CdHistCargoCom = pCCO.CdHistCargoCom
                               AND DtInicial < vdtFimPeriodo
                               AND (dtFim > vdtInicioPeriodo OR
                                   dtFim IS NULL)
                               AND FlAnulado = PKGPAG_TIPO.cnN) x
                    ON (x.DtInicial <= y.dtdia)
                   AND (x.DtFim >= y.dtdia)
                 GROUP BY x.cdhistcargocom);

        vnudiastotal := (pcco.dtfim - pcco.dtinicio) + 1;

        -- acerta valores

        vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                        pnudiasmes       => pnudiasmes,
                                        pdtiniciomes     => pdtiniciomes,
                                        pdtfimmes        => pdtfimmes,
                                        pdtfimrelacao    => pcco.dtfim,
                                        pnudiastotal     => vnudiastotal,
                                        pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                        pdtiniciorelacao => pcco.dtinicio);

        vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pcco.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => PKGPAG_VAR.bPossuiAfastNaoRemunUltDiaMes,
                                            pdtiniciorelacao => pcco.dtinicio);

        vresult.vlindice := vnudiasprop;

        IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

          vResult.vlProporcional := ((pValorIntegral / pNuDiasMes) *
                                    vNuDiasProp / vNuCHOPadrao * vNuCHO);

        ELSE
          vresult.vlproporcional := pvalorintegral;

        END IF;

        IF pnudiasmes <> vnudiasintegral OR vnuchopadrao <> vnucho THEN

          vResult.vlIntegral := ((pValorIntegral / pNuDiasMes) *
                                vNuDiasIntegral / vNuCHOPadrao * vNuCHO);

        ELSE

          vresult.vlintegral := pvalorintegral;

        END IF;

        IF vnuchopadrao <> vnucho THEN

          vresult.vlreal := (pvalorintegral / vnuchopadrao * vnucho);

        ELSE

          vresult.vlreal := pvalorintegral;

        END IF;

    END CASE;

    vresult.vlintegral := vresult.vlproporcional;

    RETURN vresult;

  EXCEPTION

    WHEN OTHERS THEN

      vresult.vlintegral := 0;

      vresult.vlproporcional := 0;

      vresult.vlindice := 0;

      RETURN vresult;

  END;

  /*--------------------------------------------------------------------------------------/*
  /*--------------------------------------------------------------------------------------*/

  --10/10/2019 SIG-2506
  FUNCTION fcalculaproporcccosubst(pccosubst      IN pkgpag_tipo.rcco,
                                   pnudiasmes     IN INTEGER,
                                   prubrica       IN pkgpag_tipo.rrubrica,
                                   pvalorintegral IN NUMBER,
                                   pdtiniciomes   IN DATE,
                                   pdtfimmes      IN DATE)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vnuchopadrao     NUMBER(7, 4);
    vdtinicioperiodo DATE;
    vdtfimperiodo    DATE;
    vresult          pkgpag_tipo.rvalorpagamento;
    vdemensagem      VARCHAR2(200);
    vdtinicio        DATE;
    vdtfim           DATE;
    vnudiastotal     NUMBER;
    vnudiasintegral  NUMBER;
    vnudiasprop      NUMBER;
    vnucho           NUMBER(7, 4);
    vnuindice        NUMBER;
    vnudiastotalimp  NUMBER := 0;
    vnudiassubst     NUMBER := 0;

  BEGIN
 
    IF pkgpag_var.vgfolha.cdagrupamento = 176 AND
       nvl(pkgpag_var.vgnudiassubst, 0) > 1000 -- SIG-2286 DPE - folha de setembro NAO ENTRAR MAIS POR ENQUANTO

     THEN
      IF pccosubst.fltipoprovimento = 'S' THEN
        vresult.vlindice := pkgpag_var.vgnudiassubst;
      ELSE
        FOR i IN pkgpag_var.vgccosubst.first .. pkgpag_var.vgccosubst.last LOOP
          IF pkgpag_var.vgccosubst(i)
           .dtinicio BETWEEN pccosubst.dtinicio AND pccosubst.dtfim THEN
            vresult.vlindice := greatest(pccosubst.qtnudiascco -
                                         (pkgpag_var.vgccosubst(i).dtfim - pkgpag_var.vgccosubst(i).dtinicio + 1),
                                         0);
          ELSE
            vresult.vlindice := pccosubst.qtnudiascco;
          END IF;
        END LOOP;
      END IF;

    ELSE
      vnudiassubst := FObterQtdDiasIntervaloMes(pDtInicioMes => pdtiniciomes,  
                                                pDtFimMes => pdtfimmes,
                                                pDtInicioIntervalo => pccosubst.DtInicio,
                                                pDtFimIntervalo => pccosubst.DtFim);
      vresult.vlindice := vnudiassubst; 
    END IF;

    IF pkgpag_var.vgfolha.cdtipofolha = pkgpag_tipo.cntpfolhainstpensao THEN

      vresult.vlreal         := pvalorintegral;
      vresult.vlintegral     := pvalorintegral;
      vresult.vlproporcional := pvalorintegral;

      RETURN vresult;

    END IF;

    vresult.vlreal := pvalorintegral;

    vresult.vlproporcional := pkgpag_geral.fcalculavalorpropdias(prubrica.flpropservrelvinc,
                                                                 pvalorintegral,
                                                                 pnudiasmes,
                                                                 vresult.vlindice);

    --Se nao aplica CHO e a rubrica manda proporcionalizar os afastamentos temp/def nao remunerados
    CASE
      WHEN prubrica.cdrubproporcionalidadecho = 1 THEN

        IF prubrica.flpropafasttempnaoremun = pkgpag_tipo.cns THEN

          IF prubrica.flpropservrelvinc = 'N' THEN

            vdtinicio := pdtiniciomes;
            vdtfim    := pdtfimmes;

          ELSE

            vdtinicio := pccosubst.dtinicio;
            vdtfim    := pccosubst.dtfim;

            --
            -- Solicitacao de Sustentacao #78891
            -- 11606/2018 - SUBSTITUICAO CUMULATIVAMENTE PGE
            --
            IF prubrica.flpagasubstituicao = 'S' AND
               pkgpag_var.vgnudiassubst > 0 AND pkgpag_var.vgnudiascco > 0 THEN
              FOR i IN pkgpag_var.vgccosubst.first .. pkgpag_var.vgccosubst.last LOOP
                IF pccosubst.cdhistcargocom <> pkgpag_var.vgccosubst(i).cdhistcargocom THEN
                  IF pccosubst.dtinicio = pkgpag_var.vgccosubst(i).dtinicio THEN
                    vdtinicio := pkgpag_var.vgccosubst(i).dtfim + 1;
                  END IF;

                  IF pccosubst.dtfim <= pkgpag_var.vgccosubst(i).dtfim AND
                     pccosubst.dtfim > pkgpag_var.vgccosubst(i).dtinicio THEN
                    vdtfim := pkgpag_var.vgccosubst(i).dtinicio - 1;
                  END IF;
                END IF;
              END LOOP;
            END IF;
          END IF;

          SELECT COUNT(*) AS nudiastotal
            INTO vnudiastotal
            FROM (SELECT y.dtdia
                    FROM (SELECT vdtinicio + (LEVEL - 1) AS dtdia
                            FROM dual
                          CONNECT BY vdtinicio + (LEVEL - 1) BETWEEN
                                     vdtinicio AND vdtfim) y
                   WHERE y.dtdia NOT IN
                         (SELECT dtdia
                            FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                    FROM dual
                                  CONNECT BY pdtiniciomes + (LEVEL - 1) BETWEEN
                                             pdtiniciomes AND pdtfimmes) d
                           INNER JOIN (SELECT CASE
                                               WHEN av.dtinicio < pdtiniciomes THEN
                                                pdtiniciomes
                                               ELSE
                                                av.dtinicio
                                             END AS dtinicio,
                                             CASE
                                               WHEN (av.dtfim > pdtfimmes OR
                                                    av.dtfim IS NULL) THEN
                                                pdtfimmes
                                               ELSE
                                                av.dtfim
                                             END AS dtfim
                                        FROM eafaafastamentovinculo av
                                       INNER JOIN eafahistmotivoafasttemp hmat
                                          ON av.cdmotivoafasttemporario =
                                             hmat.cdmotivoafasttemporario
                                       INNER JOIN (SELECT hmatv.cdmotivoafasttemporario,
                                                         MAX(hmatv.dtiniciovigencia) AS dtiniciovigencia
                                                    FROM eafahistmotivoafasttemp hmatv
                                                   WHERE hmatv.dtiniciovigencia <=
                                                         pdtfimmes
                                                   GROUP BY hmatv.cdmotivoafasttemporario) mv
                                          ON hmat.cdmotivoafasttemporario =
                                             mv.cdmotivoafasttemporario
                                         AND hmat.dtiniciovigencia =
                                             mv.dtiniciovigencia
                                       WHERE av.cdvinculo =
                                             pccosubst.cdvinculo
                                         AND av.flanulado = pkgpag_tipo.cnn
                                         AND (hmat.flremunerado =
                                             pkgpag_tipo.cnn OR
                                             (prubrica.ingerarubricaafasttemp = '1' AND
                                             av.cdmotivoafasttemporario IN
                                             (SELECT cdmotivoafasttemporario
                                                  FROM epagrubagrupmotafasttempimp ai
                                                 WHERE ai.cdmotivoafasttemporario =
                                                       av.cdmotivoafasttemporario
                                                   AND ai.cdhistrubricaagrupamento =
                                                       prubrica.cdhistrubrica)) OR
                                             (prubrica.ingerarubricaafasttemp = '2' AND
                                             ((av.cdmotivoafasttemporario NOT IN
                                             (SELECT cdmotivoafasttemporario
                                                    FROM epagrubagrupmotafasttempimp ai
                                                   WHERE av.cdmotivoafasttemporario =
                                                         ai.cdmotivoafasttemporario
                                                     AND ai.cdhistrubricaagrupamento =
                                                         prubrica.cdhistrubrica)) OR
                                             (SELECT COUNT(*)
                                                   FROM epagrubagrupmotafasttempimp ai
                                                  WHERE ai.cdhistrubricaagrupamento =
                                                        prubrica.cdhistrubrica) = 0)))
                                         AND av.dtinicio <= pdtfimmes
                                         AND (av.dtfim >= pdtiniciomes OR
                                             av.dtfim IS NULL)) b
                              ON (b.dtinicio <= d.dtdia)
                             AND (b.dtfim >= d.dtdia)
                          UNION
                          SELECT dtdia
                            FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                    FROM dual
                                  CONNECT BY pdtiniciomes + (LEVEL - 1) BETWEEN
                                             pdtiniciomes AND pdtfimmes) d
                           INNER JOIN (SELECT CASE
                                               WHEN av.dtinicio < pdtiniciomes THEN
                                                pdtiniciomes
                                               ELSE
                                                av.dtinicio
                                             END AS dtinicio,
                                             CASE
                                               WHEN (av.dtfim > pdtfimmes OR
                                                    av.dtfim IS NULL) THEN
                                                pdtfimmes
                                               ELSE
                                                av.dtfim
                                             END AS dtfim
                                        FROM eafaafastamentovinculo av
                                       INNER JOIN eafahistmotivoafastdef hmad
                                          ON av.cdmotivoafastdefinitivo =
                                             hmad.cdmotivoafastdefinitivo
                                       INNER JOIN (SELECT hmadv.cdmotivoafastdefinitivo,
                                                         MAX(hmadv.dtiniciovigencia) AS dtiniciovigencia
                                                    FROM eafahistmotivoafastdef hmadv
                                                   WHERE hmadv.dtiniciovigencia <=
                                                         pdtfimmes
                                                   GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                          ON hmad.cdmotivoafastdefinitivo =
                                             mv.cdmotivoafastdefinitivo
                                         AND hmad.dtiniciovigencia =
                                             mv.dtiniciovigencia
                                       WHERE av.cdvinculo =
                                             pccosubst.cdvinculo
                                         AND av.flanulado = pkgpag_tipo.cnn
                                         AND hmad.flremunerado =
                                             pkgpag_tipo.cnn
                                         AND av.dtinicio <= pdtfimmes
                                         AND (av.dtfim >= pdtiniciomes OR
                                             av.dtfim IS NULL)) b
                              ON (b.dtinicio <= d.dtdia)
                             AND (b.dtfim >= d.dtdia))
                   GROUP BY y.dtdia);

          -- acerta valores

          IF vnudiastotal >
             nvl(pkgpag_var.vgnudiascco, pkgpag_var.vgnudiassubst) THEN
            vnudiastotal := nvl(pkgpag_var.vgnudiascco,
                                pkgpag_var.vgnudiassubst);
          END IF;

          IF (vnudiastotal > vresult.vlindice OR
             (pkgpag_var.vgccosubst.count > 1 AND
             NVL(pkgpag_var.vgNuDiasSubst, 0) = 30)) AND
             to_char(pdtfimmes, 'DD') = '31' THEN
            vnudiastotal := vresult.vlindice;
          END IF;

          IF pkgpag_var.vgfolha.cdagrupamento = 176 AND
             nvl(pkgpag_var.vgnudiassubst, 0) > 0 THEN
            vnudiasprop := vresult.vlindice;
          ELSE
            vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pccosubst.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => pkgpag_var.bpossuiafastnaoremunultdiames,
                                            pdtiniciorelacao => pccosubst.dtinicio);
          END IF;

          vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                              pnudiasmes       => pnudiasmes,
                                              pdtiniciomes     => pdtiniciomes,
                                              pdtfimmes        => pdtfimmes,
                                              pdtfimrelacao    => pccosubst.dtfim,
                                              pnudiastotal     => vnudiastotal,
                                              pbafastultdia    => pkgpag_var.bpossuiafastnaoremunultdiames,
                                              pdtiniciorelacao => pccosubst.dtinicio);

          vresult.vlindice := vnudiasprop;

          IF pnudiasmes <> vnudiasprop THEN

            vresult.vlproporcional := (pvalorintegral / pnudiasmes) *
                                      vnudiasprop;

          ELSE
            vresult.vlproporcional := pvalorintegral;

          END IF;

          IF pnudiasmes <> vnudiasintegral THEN

            vresult.vlintegral := (pvalorintegral / pnudiasmes) *
                                  vnudiasintegral;

          ELSE

            vresult.vlintegral := pvalorintegral;

          END IF;

        END IF;

      WHEN prubrica.cdrubproporcionalidadecho = 2 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          vnuchopadrao := pccosubst.nucargahorariapadrao;

          vdemensagem := 'Carga hor?ria padr?o do cargo comissionado n?o est? definida.';

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

          vdemensagem := 'Carga hor?ria padr?o da rubrica ' ||
                         prubrica.cdtiporubrica || '-' ||
                         prubrica.nurubrica || ' n?o est? definida.';

        END IF;

        IF nvl(vnuchopadrao, 0) <= 0 THEN

          pinserelog(pkgpag_var.blog,
                     pkgpag_var.vcdhistparamcalc,
                     pkgpag_var.vcdpessoa,
                     vdemensagem,
                     pkgpag_var.vgcdvinculo);
        ELSE

          SELECT nvl(SUM(nucho * nudias) / SUM(nudias), 0),
                 nvl(SUM(nudias), 0)
            INTO vnucho, vnudiastotal
            FROM (SELECT a.nucho, COUNT(*) AS nudias
                    FROM (SELECT x.cdhistcargocom,
                                 y.dtdia,
                                 SUM(x.nucargahoraria) AS nucho
                            FROM (SELECT pccosubst.dtinicio + (LEVEL - 1) AS dtdia
                                    FROM dual
                                  CONNECT BY pccosubst.dtinicio + (LEVEL - 1) BETWEEN
                                             pccosubst.dtinicio AND
                                             pccosubst.dtfim) y
                           INNER JOIN (SELECT cdhistcargahoraria,
                                             cdhistcargocom,
                                             dtinicial,
                                             CASE
                                               WHEN dtfim IS NULL THEN
                                                pccosubst.dtfim
                                               ELSE
                                                dtfim
                                             END dtfim,
                                             fltipoocupacao,
                                             CASE
                                              prubrica.flcargahorarialimitada
                                               WHEN 'N' THEN
                                                nucargahoraria
                                               WHEN 'S' THEN
                                                CASE
                                                  WHEN nucargahoraria >
                                                       vnuchopadrao THEN
                                                   vnuchopadrao
                                                  ELSE
                                                   nucargahoraria
                                                END
                                             END nucargahoraria
                                        FROM ecadhistcargahoraria hcho
                                       WHERE cdhistcargocom =
                                             pccosubst.cdhistcargocom
                                         AND dtinicial <= pccosubst.dtfim
                                         AND (dtfim >= pccosubst.dtinicio OR
                                             dtfim IS NULL)
                                         AND flanulado = pkgpag_tipo.cnn
                                         AND nvl(hcho.nucargahoraria, 0) > 0) x
                              ON (x.dtinicial <= y.dtdia)
                             AND (x.dtfim >= y.dtdia)
                           WHERE y.dtdia NOT IN
                                 (SELECT dtdia
                                    FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                            FROM dual
                                          CONNECT BY pdtiniciomes + (LEVEL - 1) BETWEEN
                                                     pdtiniciomes AND pdtfimmes) d
                                   INNER JOIN (SELECT CASE
                                                       WHEN av.dtinicio <
                                                            pdtiniciomes THEN
                                                        pdtiniciomes
                                                       ELSE
                                                        av.dtinicio
                                                     END AS dtinicio,
                                                     CASE
                                                       WHEN (av.dtfim >
                                                            pdtfimmes OR
                                                            av.dtfim IS NULL) THEN
                                                        pdtfimmes
                                                       ELSE
                                                        av.dtfim
                                                     END AS dtfim
                                                FROM eafaafastamentovinculo av
                                               INNER JOIN eafahistmotivoafasttemp hmat
                                                  ON av.cdmotivoafasttemporario =
                                                     hmat.cdmotivoafasttemporario
                                               INNER JOIN (SELECT hmatv.cdmotivoafasttemporario,
                                                                 MAX(hmatv.dtiniciovigencia) AS dtiniciovigencia
                                                            FROM eafahistmotivoafasttemp hmatv
                                                           WHERE hmatv.dtiniciovigencia <=
                                                                 pdtfimmes
                                                           GROUP BY hmatv.cdmotivoafasttemporario) mv
                                                  ON hmat.cdmotivoafasttemporario =
                                                     mv.cdmotivoafasttemporario
                                                 AND hmat.dtiniciovigencia =
                                                     mv.dtiniciovigencia
                                               WHERE av.cdvinculo =
                                                     pccosubst.cdvinculo
                                                 AND av.flanulado =
                                                     pkgpag_tipo.cnn
                                                 AND prubrica.flpropafasttempnaoremun =
                                                     pkgpag_tipo.cns
                                                 AND (hmat.flremunerado =
                                                     pkgpag_tipo.cnn OR
                                                     (prubrica.ingerarubricaafasttemp = '1' AND
                                                     av.cdmotivoafasttemporario IN
                                                     (SELECT cdmotivoafasttemporario
                                                          FROM epagrubagrupmotafasttempimp ai
                                                         WHERE ai.cdmotivoafasttemporario =
                                                               av.cdmotivoafasttemporario
                                                           AND ai.cdhistrubricaagrupamento =
                                                               prubrica.cdhistrubrica)) OR
                                                     (prubrica.ingerarubricaafasttemp = '2' AND
                                                     ((av.cdmotivoafasttemporario NOT IN
                                                     (SELECT cdmotivoafasttemporario
                                                            FROM epagrubagrupmotafasttempimp ai
                                                           WHERE av.cdmotivoafasttemporario =
                                                                 ai.cdmotivoafasttemporario
                                                             AND ai.cdhistrubricaagrupamento =
                                                                 prubrica.cdhistrubrica)) OR
                                                     (SELECT COUNT(*)
                                                           FROM epagrubagrupmotafasttempimp ai
                                                          WHERE ai.cdhistrubricaagrupamento =
                                                                prubrica.cdhistrubrica) = 0)))
                                                 AND av.dtinicio <= pdtfimmes
                                                 AND (av.dtfim >= pdtiniciomes OR
                                                     av.dtfim IS NULL)) b
                                      ON (b.dtinicio <= d.dtdia)
                                     AND (b.dtfim >= d.dtdia)
                                  UNION
                                  SELECT dtdia
                                    FROM (SELECT pdtiniciomes + (LEVEL - 1) AS dtdia
                                            FROM dual
                                          CONNECT BY pdtiniciomes + (LEVEL - 1) BETWEEN
                                                     pdtiniciomes AND pdtfimmes) d
                                   INNER JOIN (SELECT CASE
                                                       WHEN av.dtinicio <
                                                            pdtiniciomes THEN
                                                        pdtiniciomes
                                                       ELSE
                                                        av.dtinicio
                                                     END AS dtinicio,
                                                     CASE
                                                       WHEN (av.dtfim >
                                                            pdtfimmes OR
                                                            av.dtfim IS NULL) THEN
                                                        pdtfimmes
                                                       ELSE
                                                        av.dtfim
                                                     END AS dtfim
                                                FROM eafaafastamentovinculo av
                                               INNER JOIN eafahistmotivoafastdef hmad
                                                  ON av.cdmotivoafastdefinitivo =
                                                     hmad.cdmotivoafastdefinitivo
                                               INNER JOIN (SELECT hmadv.cdmotivoafastdefinitivo,
                                                                 MAX(hmadv.dtiniciovigencia) AS dtiniciovigencia
                                                            FROM eafahistmotivoafastdef hmadv
                                                           WHERE hmadv.dtiniciovigencia <=
                                                                 pdtfimmes
                                                           GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                                  ON hmad.cdmotivoafastdefinitivo =
                                                     mv.cdmotivoafastdefinitivo
                                                 AND hmad.dtiniciovigencia =
                                                     mv.dtiniciovigencia
                                               WHERE av.cdvinculo =
                                                     pccosubst.cdvinculo
                                                 AND av.flanulado =
                                                     pkgpag_tipo.cnn
                                                 AND hmad.flremunerado =
                                                     pkgpag_tipo.cnn
                                                 AND av.dtinicio <= pdtfimmes
                                                 AND (av.dtfim >= pdtiniciomes OR
                                                     av.dtfim IS NULL)) b
                                      ON (b.dtinicio <= d.dtdia)
                                     AND (b.dtfim >= d.dtdia))
                           GROUP BY x.cdhistcargocom, y.dtdia) a
                   GROUP BY a.nucho);

          IF pkgpag_var.vgccosubst.count > 1 THEN

            IF pkgpag_var.vgnudiassubst > 30 AND
               to_char(pccosubst.dtfim, 'DD') = 31 THEN
              vnudiastotal := vnudiastotal - 1;
            END IF;

          END IF;

          -- acerta valores
          IF pkgpag_var.vgccosubst.count > 0 THEN
            IF vnudiastotal > pkgpag_var.vgnudiassubst THEN
              vnudiastotal := pkgpag_var.vgnudiassubst;
            END IF;

          ELSE

            IF vnudiastotal > pkgpag_var.vgnudiascco THEN
              vnudiastotal := pkgpag_var.vgnudiascco;
            END IF;

          END IF;

          IF vnudiastotal > vresult.vlindice AND
             to_char(pdtfimmes, 'DD') = '31' THEN
            vnudiastotal := vresult.vlindice;
          END IF;

          IF pkgpag_var.vgfolha.cdagrupamento = 176 AND
             nvl(pkgpag_var.vgnudiassubst, 0) > 0 THEN
            vnudiasprop := vresult.vlindice;
          ELSE
            vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pccosubst.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => pkgpag_var.bpossuiafastnaoremunultdiames,
                                            pdtiniciorelacao => pccosubst.dtinicio);
          END IF;

          vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                              pnudiasmes       => pnudiasmes,
                                              pdtiniciomes     => pdtiniciomes,
                                              pdtfimmes        => pdtfimmes,
                                              pdtfimrelacao    => pccosubst.dtfim,
                                              pnudiastotal     => vnudiastotal,
                                              pbafastultdia    => pkgpag_var.bpossuiafastnaoremunultdiames,
                                              pdtiniciorelacao => pccosubst.dtinicio);

          -- PARAMETRO: Se tem afastamento remunerado, conta os dias
          IF prubrica.cdrubricaagrupamento = 10453 AND
             pkgpag_var.vgafasttempremun.count > 0 THEN
            FOR i IN pkgpag_var.vgafasttempremun.first .. pkgpag_var.vgafasttempremun.last LOOP

              --Para a rubrica 01-0403 verifica se existe afastamento impeditivo
              IF prubrica.lsmotafasttempimp.exists(pkgpag_var.vgafasttempremun(i).cdmotivoafastamento) THEN

                --Soma o numero de dias que o servidor esta afastado
                vnudiastotalimp := vnudiastotalimp +
                                   (pkgpag_var.vgafasttempremun(i).dtfimafa - pkgpag_var.vgafasttempremun(i).dtinicioafa) + 1;

              END IF;
            END LOOP;

          END IF;

          -- RUBRICA 01-0403: A REGRA DEFINE QUE NAO GERE A RUBRICA NOS AFASTAMENTOS PREVISTOS
          -- NO PARAMETRO DA RUBRICA QUANDO ESTES FOREM IGUAL OU SUPERIOR A 30 DIAS DENTRO DO MES
          /*    IF pRubrica.CdRubricaAgrupamento = 10453  AND vnudiastotalImp >= 30 THEN
          vresult.vlproporcional := 0;
          vresult.vlintegral := 0;
          vresult.vlindice := 0;       */

          -- CASO O AFASTAMENTO SEJA MENOR QUE 30 DIAS PAGA INTEGRAL
          IF prubrica.cdrubricaagrupamento = 10453 AND vnudiastotalimp < 30 AND
             vnudiastotalimp > 0 THEN
            -- Todos os afastamentos encontrados sao impeditivos
            vnudiasprop      := 30;
            vnudiasintegral  := 30;
            vresult.vlindice := vnudiasprop;
          END IF;

          -- POG 01-0422: Rubrica de substituicao deve pagar exatamente o numero de dias da substituicao
          IF prubrica.cdrubricaagrupamento = 8214 AND
             pkgpag_var.vgccosubst.count = 1 AND
             nvl(pkgpag_var.vgnudiassubst, 0) > 0 THEN

            vnudiasprop := pkgpag_var.vgnudiassubst;

          END IF;

          vresult.vlindice := vnudiasprop;

          IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

            vresult.vlproporcional := round(((pvalorintegral / pnudiasmes) *
                                            vnudiasprop / vnuchopadrao *
                                            vnucho),
                                            2);

          ELSE
            vresult.vlproporcional := pvalorintegral;

          END IF;

          IF pnudiasmes <> vnudiasintegral OR vnuchopadrao <> vnucho THEN

            vresult.vlintegral := round(((pvalorintegral / pnudiasmes) *
                                        vnudiasintegral / vnuchopadrao *
                                        vnucho),
                                        2);

          ELSE

            vresult.vlintegral := pvalorintegral;

          END IF;

          IF vnuchopadrao <> vnucho THEN

            vresult.vlreal := round((pvalorintegral / vnuchopadrao * vnucho),
                                    2);

          ELSE

            vresult.vlreal := pvalorintegral;

          END IF;

        END IF;

      WHEN prubrica.cdrubproporcionalidadecho = 3 THEN

        IF prubrica.flcargahorariapadrao = 'S' THEN

          vnuchopadrao := pccosubst.nucargahorariapadrao;

        ELSE

          vnuchopadrao := prubrica.nucargahorariasemanal;

        END IF;

        IF nvl(prubrica.numesesapuracao, 0) > 0 THEN

          vdtinicioperiodo := add_months(pdtiniciomes,
                                         -prubrica.numesesapuracao);

        ELSE

          vdtinicioperiodo := pdtiniciomes;

        END IF;

        vdtfimperiodo := last_day(pdtiniciomes);

        SELECT SUM(numediacho)
          INTO vnucho
          FROM (SELECT x.cdhistcargocom,
                       SUM(x.nucargahoraria) / COUNT(DISTINCT dtdia) AS numediacho
                  FROM (SELECT vdtinicioperiodo + (LEVEL - 1) AS dtdia
                          FROM dual
                        CONNECT BY vdtinicioperiodo + (LEVEL - 1) BETWEEN
                                   vdtinicioperiodo AND vdtfimperiodo) y
                 INNER JOIN (SELECT cdhistcargahoraria,
                                   cdhistcargocom,
                                   dtinicial,
                                   CASE
                                     WHEN dtfim IS NULL THEN
                                      vdtfimperiodo
                                     ELSE
                                      dtfim
                                   END dtfim,
                                   fltipoocupacao,
                                   nucargahoraria
                              FROM ecadhistcargahoraria hcho
                             WHERE cdhistcargocom = pccosubst.cdhistcargocom
                               AND dtinicial < vdtfimperiodo
                               AND (dtfim > vdtinicioperiodo OR
                                   dtfim IS NULL)
                               AND flanulado = pkgpag_tipo.cnn) x
                    ON (x.dtinicial <= y.dtdia)
                   AND (x.dtfim >= y.dtdia)
                 GROUP BY x.cdhistcargocom);

        vnudiastotal := (pccosubst.dtfim - pccosubst.dtinicio) + 1;

        -- acerta valores

        vnudiasprop := facertardiasprop(pnudiasafast     => 0,
                                        pnudiasmes       => pnudiasmes,
                                        pdtiniciomes     => pdtiniciomes,
                                        pdtfimmes        => pdtfimmes,
                                        pdtfimrelacao    => pccosubst.dtfim,
                                        pnudiastotal     => vnudiastotal,
                                        pbafastultdia    => pkgpag_var.bpossuiafastnaoremunultdiames,
                                        pdtiniciorelacao => pccosubst.dtinicio);

        vnudiasintegral := facertardiasprop(pnudiasafast     => 0,
                                            pnudiasmes       => pnudiasmes,
                                            pdtiniciomes     => pdtiniciomes,
                                            pdtfimmes        => pdtfimmes,
                                            pdtfimrelacao    => pccosubst.dtfim,
                                            pnudiastotal     => vnudiastotal,
                                            pbafastultdia    => pkgpag_var.bpossuiafastnaoremunultdiames,
                                            pdtiniciorelacao => pccosubst.dtinicio);

        vresult.vlindice := vnudiasprop;

        IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

          vresult.vlproporcional := ((pvalorintegral / pnudiasmes) *
                                    vnudiasprop / vnuchopadrao * vnucho);

        ELSE
          vresult.vlproporcional := pvalorintegral;

        END IF;

        IF pnudiasmes <> vnudiasintegral OR vnuchopadrao <> vnucho THEN

          vresult.vlintegral := ((pvalorintegral / pnudiasmes) *
                                vnudiasintegral / vnuchopadrao * vnucho);

        ELSE

          vresult.vlintegral := pvalorintegral;

        END IF;

        IF vnuchopadrao <> vnucho THEN

          vresult.vlreal := (pvalorintegral / vnuchopadrao * vnucho);

        ELSE

          vresult.vlreal := pvalorintegral;

        END IF;

    END CASE;

    vresult.vlintegral := vresult.vlproporcional;

    RETURN vresult;

  EXCEPTION

    WHEN OTHERS THEN

      vresult.vlintegral := 0;

      vresult.vlproporcional := 0;

      vresult.vlindice := 0;

      RETURN vresult;

  END;

  FUNCTION fcalculaproporcbol(pbol         IN pkgpag_tipo.rbol,
                              pnudiasmes   IN INTEGER,
                              prubrica     IN pkgpag_tipo.rrubrica,
                              pdtiniciomes IN DATE,
                              pdtfimmes    IN DATE /*,
                              pDtCalculo            IN DATE*/)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vresult        pkgpag_tipo.rvalorpagamento;

    vresultperiodo pkgpag_tipo.rvalorpagamento;

    vbol           pkgpag_tipo.rbol;
    
    vResultDias    INTEGER;
    -----------

    FUNCTION FCalculaValorBolHistPrograma(pBOL             IN PKGPAG_TIPO.rBOL,
                                          pnudiasmes       IN INTEGER,
                                          prubrica         IN pkgpag_tipo.rrubrica,
                                          pdtinicioperiodo IN DATE,
                                          pdtfimperiodo    IN DATE,
                                          pnucargahoraria  IN NUMBER DEFAULT NULL)

     RETURN pkgpag_tipo.rvalorpagamento IS

      CURSOR cprogform(pcdhistprograma INTEGER /*,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            pNuCargaHoraria INTEGER*/) IS
        SELECT pnf.cdcurso,
               pnf.cdcursoagrupador,
               pnf.cdnivelformacao,
               nf.cdgrauescolaridade,
               pnf.vlbolsatrabalho,
               pnf.vlbolsatrabalhopne,
               pnf.nucargahoraria,
               pnf.nucargahorariapne
          FROM ebolprogramanivelformacao pnf
         INNER JOIN ecadnivelformgrauesc nf
            ON pnf.cdnivelformgrauesc = nf.cdnivelformgrauesc
         WHERE pnf.cdhistprograma = pcdhistprograma /*AND
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                PNF.NuCargaHoraria = pNuCargaHoraria*/
         ORDER BY pnf.cdcurso,
                  pnf.cdcursoagrupador,
                  pnf.cdnivelformacao,
                  nf.cdgrauescolaridade;

      vresult pkgpag_tipo.rvalorpagamento;

      vprogform cprogform%ROWTYPE;

      bachouvalor BOOLEAN;

      vvlbolsa NUMBER(13, 2);

      vnudiastotal NUMBER;

      vnuchopadrao NUMBER(7, 4);

      vnucho NUMBER(7, 4);

      vnudiasafastp NUMBER;

      vnudiasprop NUMBER;

      --vnuafastultdia NUMBER;

      --btemafastultimodia BOOLEAN;

    BEGIN
 
      vresult.vlproporcional := 0;

      vresult.vlindice := 0;

      bachouvalor := FALSE;

      OPEN cprogform(pbol.cdhistprograma);

      LOOP

        FETCH cProgForm
          INTO vProgForm;

        EXIT WHEN cprogform%NOTFOUND OR bachouvalor;

        CASE

          WHEN pbol.cdgrauescolaridade = vprogform.cdgrauescolaridade AND
               pbol.cdnivelformacao = vprogform.cdnivelformacao AND
               pbol.cdcursoagrupador = vprogform.cdcursoagrupador AND
               pBOL.CdCurso = vProgForm.CdCurso AND
               pBOL.NuCargaHoraria =
               NVL(vProgForm.NuCargaHoraria, pNuCargaHoraria) THEN

            IF pbol.flocupavagapne = pkgpag_tipo.cnn THEN

              vvlbolsa := nvl(vprogform.vlbolsatrabalho, pbol.vlbolsa);

              vNuCHOPadrao := NVL(vProgForm.NuCargaHoraria,
                                  pBOL.NuCargaHoraria);

            ELSE

              vvlbolsa := nvl(vprogform.vlbolsatrabalhopne, pbol.vlbolsapne);

              vNuCHOPadrao := NVL(vProgForm.NuCargaHorariaPNE,
                                  pBOL.NuCargaHorariaPNE);

            END IF;

            bachouvalor := TRUE;

          WHEN pbol.cdgrauescolaridade = vprogform.cdgrauescolaridade AND
               pbol.cdnivelformacao = vprogform.cdnivelformacao AND
               pBOL.CdCurso = vProgForm.CdCurso AND
               pBOL.NuCargaHoraria =
               NVL(vProgForm.NuCargaHoraria, pNuCargaHoraria) THEN

            CASE pbol.flocupavagapne

              WHEN pkgpag_tipo.cnn THEN

                vvlbolsa := nvl(vprogform.vlbolsatrabalho, pbol.vlbolsa);

                vNuCHOPadrao := NVL(vProgForm.NuCargaHoraria,
                                    pBOL.NuCargaHoraria);

              ELSE

                vVlBolsa := NVL(vProgForm.VlBolsaTrabalhoPNE,
                                pBOL.VlBolsaPNE);

                vNuCHOPadrao := NVL(vProgForm.NuCargaHorariaPNE,
                                    pBOL.NuCargaHorariaPNE);

            END CASE;

            bachouvalor := TRUE;

          WHEN pbol.cdgrauescolaridade = vprogform.cdgrauescolaridade AND
               pBOL.CdNivelFormacao = vProgForm.CdNivelFormacao AND
               pBOL.NuCargaHoraria =
               NVL(vProgForm.NuCargaHoraria, pNuCargaHoraria) THEN

            IF pbol.flocupavagapne = pkgpag_tipo.cnn THEN

              vvlbolsa := nvl(vprogform.vlbolsatrabalho, pbol.vlbolsa);

              vNuCHOPadrao := NVL(vProgForm.NuCargaHoraria,
                                  pBOL.NuCargaHoraria);

            ELSE

              vvlbolsa := nvl(vprogform.vlbolsatrabalhopne, pbol.vlbolsapne);

              vNuCHOPadrao := NVL(vProgForm.NuCargaHorariaPNE,
                                  pBOL.NuCargaHorariaPNE);

            END IF;

            bachouvalor := TRUE;

          ELSE

            NULL;

        END CASE;

      END LOOP;

      CLOSE cprogform;

      --Caso nao encontre regra especifica, busca os valores no programa
      IF NOT bachouvalor THEN

        IF pbol.flocupavagapne = pkgpag_tipo.cnn THEN

          vvlbolsa := pbol.vlbolsa;

          vnuchopadrao := pbol.nucargahoraria;

        ELSE

          vvlbolsa := pbol.vlbolsapne;

          vnuchopadrao := pbol.nucargahorariapne;

        END IF;

      END IF;

      SELECT sum(NuDias),
             SUM(nudiasafast),
             SUM(nudias * nucho) / SUM(nudias)
      --SUM(afastultdia)
        INTO vNuDiasTotal, vNuDiasAfastP, vNuCHO
      --vNuAfastUltDia
        FROM (SELECT nucargahoraria AS nucho,
                     COUNT(*) AS nudias,
                     nvl(SUM(diaafastado), 0) AS nudiasafast
              --nvl(MAX(afastultdia), 0) AS afastultdia
                FROM (SELECT pdtinicioperiodo + (LEVEL - 1) AS dtdia
                        FROM dual
                      CONNECT BY pDtInicioPeriodo + (LEVEL - 1) BETWEEN
                                 pDtInicioPeriodo AND pDtFimPeriodo) Y
               INNER JOIN (SELECT HCH.NuCargaHoraria,
                                 CASE
                                   WHEN hch.dtinicial < pdtinicioperiodo THEN
                                    pdtinicioperiodo
                                   ELSE
                                    hch.dtinicial
                                 END AS dtinicial,
                                 CASE
                                   WHEN (HCH.DtFim > pDtFimPeriodo OR
                                        HCH.dtFim IS NULL) THEN
                                    pdtfimperiodo
                                   ELSE
                                    hch.dtfim
                                 END AS dtfim
                            FROM ecadhistcargahoraria hch
                           WHERE HCH.CdHistEstagio = pBOL.CdHistEstagio
                             AND (HCH.DtInicial <= pDtFimPeriodo AND
                                 HCH.DtFim >= pDtInicioPeriodo OR
                                 HCH.DtFim IS NULL)) X
                  ON (X.DtInicial <= y.dtdia)
                 AND (X.DtFim >= y.dtdia)
                LEFT JOIN (SELECT 1 AS diaafastado,
                                 CASE
                                   WHEN av.dtinicio < pdtinicioperiodo THEN
                                    pdtinicioperiodo
                                   ELSE
                                    av.dtinicio
                                 END AS dtinicio,
                                 CASE
                                   WHEN (AV.dtFim > pDtFimPeriodo OR
                                        AV.DtFim IS NULL) THEN
                                    pdtfimperiodo
                                   ELSE
                                    av.dtfim
                                 END AS dtfim,
                                 CASE
                                   WHEN av.dtfim >= last_day(pdtfimperiodo) THEN
                                    1
                                   ELSE
                                    0
                                 END AS afastultdia
                            FROM eafaafastamentovinculo av
                           INNER JOIN eafahistmotivoafasttemp hmat
                              ON Av.CdMotivoAfastTemporario =
                                 HMAT.CdMotivoAfastTemporario
                           INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                             MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                        FROM eafahistmotivoafasttemp hmatv
                                       WHERE HMATV.dtInicioVigencia <=
                                             pDtFimPeriodo
                                       GROUP BY hmatv.cdmotivoafasttemporario) mv
                              ON HMAT.CdMotivoAfastTemporario =
                                 MV.CdMotivoAfastTemporario
                             AND hmat.dtiniciovigencia = mv.dtiniciovigencia
                           WHERE AV.CdVinculo = pBOL.CdVinculoEstagio
                             AND AV.FlAnulado = PKGPAG_TIPO.cnN
                             AND pRubrica.FlPropAfastTempNaoRemun =
                                 PKGPAG_TIPO.cnS
                             AND (HMAT.FlRemunerado = PKGPAG_TIPO.cnN)) B
                  ON (B.DtInicio <= y.dtdia)
                 AND (B.DtFim >= y.dtdia)
               GROUP BY nucargahoraria);

      -- acerta valores
      vnudiasprop := facertardiasprop(pnudiasafast     => vnudiasafastp,
                                      pnudiasmes       => pnudiasmes,
                                      pdtiniciomes     => pdtinicioperiodo,
                                      pdtfimmes        => least(pdtfimperiodo,
                                                                pkgpag_var.vgFOlha.dtfimmes),
                                      pdtfimrelacao    => pbol.dtfim,
                                      pnudiastotal     => vnudiastotal,
                                      pbafastultdia    => pkgpag_var.bPossuiAfastNaoRemunUltDiaMes,
                                      pdtiniciorelacao => pbol.dtinicio);

      vresult.vlindice := vnudiasprop;

      IF pnudiasmes <> vnudiasprop OR vnuchopadrao <> vnucho THEN

        vResult.vlProporcional := ((vVlBolsa / pNuDiasMes) * vNuDiasProp /
                                  vNuCHOPadrao * vNuCHO);

        vresult.vlreal := (vvlbolsa / vnuchopadrao * vnucho);

      ELSE

        vresult.vlproporcional := vvlbolsa;
        vresult.vlreal         := vvlbolsa;

      END IF;

      RETURN vresult;

    END;

    -----------

  BEGIN
 
    vresult.vlproporcional := 0;

    vresult.vlindice := 0;

    -- Busca vigencias do programa do bolsista dentro do mes

    FOR recHistPrograma IN (SELECT hp.cdhistprograma,
                                   greatest(hp.dtiniciovigencia,
                                            pdtiniciomes) AS dtiniciohistprograma,
                                   least(nvl(hp.dtfimvigencia, pdtfimmes), pdtfimmes) AS dtfimhistprograma,
                                   hp.nucargahoraria
                              FROM ebolhistprograma hp
                             WHERE hp.cdprograma =
                                   (SELECT hp2.cdprograma
                                      FROM ebolhistprograma hp2
                                     WHERE hp2.cdhistprograma =
                                           pBOL.CdHistPrograma)
                               AND hp.flanulado = 'N'
                               AND hp.dtiniciovigencia <= pdtfimmes
                               AND (hp.dtfimvigencia >= pdtiniciomes OR
                                   hp.dtfimvigencia IS NULL)
                             ORDER BY hp.dtiniciovigencia)

     LOOP

      -- Para cada vigencia do programa, busca o valor proporcional ao periodo

      vbol := pbol;

      vbol.cdhistprograma := rechistprograma.cdhistprograma;

      vResultPeriodo := FCalculaValorBolHistPrograma(vBOL,
                                                     pNuDiasMes,
                                                     prubrica,
                                                     rechistprograma.dtiniciohistprograma,
                                                     rechistprograma.dtfimhistprograma,
                                                     rechistprograma.nucargahoraria);

      IF vresultperiodo.vlindice > 0 THEN

        IF vResult.vlIndice + vResultPeriodo.vlIndice > pNuDiasMes THEN
               
           vResultDias := vResultPeriodo.vlIndice - 1;
           
           vResultPeriodo.vlProporcional := vResultPeriodo.vlProporcional/vResultPeriodo.vlIndice * vResultDias;            
                
           vResultPeriodo.vlIndice := vResultDias;            
           
        END IF;
        
        
        -- Soma valores de indice e proporcional
        vResult.vlProporcional := vResult.vlProporcional + vResultPeriodo.vlProporcional;
        
        vResult.vlIndice       := vResult.vlIndice + vResultPeriodo.vlIndice;

        -- Mantem valores real e integral da ultima vigencia
        vresult.vlreal     := vresultperiodo.vlreal;
        
        vresult.vlintegral := vresultperiodo.vlintegral;

      END IF;

    END LOOP;

    RETURN vresult;

  END;

  FUNCTION fcalculaproporcpnp(pfolha         IN pkgpag_tipo.rfolha,
                              ppnp           IN pkgpag_tipo.rpensaonaoprev,
                              pnudiasmes     IN INTEGER,
                              prubrica       IN pkgpag_tipo.rrubrica,
                              pdtiniciomes   IN DATE,
                              pdtfimmes      IN DATE,
                              pvalorintegral IN NUMBER)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vresult pkgpag_tipo.rvalorpagamento;

    vnudiasprop INTEGER;

    vdtinicio DATE;

    vdtfim DATE;

    vnudiastotal NUMBER;

    vnudiasafastp NUMBER;

  BEGIN
 
    IF ppnp.dtinicio > pfolha.dtiniciomes THEN

      vdtinicio := ppnp.dtinicio;

    ELSE

      vdtinicio := pfolha.dtiniciomes;

    END IF;

    IF ppnp.dtfim <= pfolha.dtfimmes THEN

      vdtfim := ppnp.dtfim;

    ELSE

      vdtfim := pfolha.dtfimmes;

    END IF;

    vResult.vlIndice := PKGPAG_GERAL.FRetornaIndice(pRubrica.FlPropMesComercial,
                                                    pDtInicioMes,
                                                    pDtFimMes,
                                                    pPNP.DtInicio,
                                                    pPNP.DtFim);

    -- O flag FlPropApoParidade tambem e utilizado para saber se deve proporcionalizar pelo percentual

    IF prubrica.flpropaposparidade = 'S' THEN

      IF prubrica.flpercentlimitado100 = 'N' THEN

        vResult.vlReal := pValorIntegral *
                          NVL(PKGPAG_VAR.vgPercentPensaoNaoPrev, 100) / 100;

      ELSE

        vResult.vlReal := pValorIntegral *
                          LEAST(NVL(PKGPAG_VAR.vgPercentPensaoNaoPrev, 100),
                                100) / 100;

      END IF;

    ELSE

      vresult.vlreal := pvalorintegral;

    END IF;

    vResult.vlProporcional := PKGPAG_GERAL.FCalculaValorPropDias(pRubrica.FlPropServRelVinc,
                                                                 vresult.vlreal,
                                                                 pnudiasmes,
                                                                 vresult.vlindice);

    IF prubrica.flpropafasttempnaoremun = pkgpag_tipo.cns AND
       PKGPAG_VAR.vgFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaInstPensao THEN

      SELECT NuDias, NuDiasAfast
        INTO vNuDiasTotal, vNuDiasAfastP

        FROM (SELECT COUNT(*) AS nudias,
                     nvl(SUM(diaafastado), 0) AS nudiasafast

                FROM (SELECT DtDia AS DtDiaAfastado,
                             CASE
                               WHEN DiaAfastadoT = 1 OR DiaAfastadoD = 1 THEN
                                1
                               ELSE
                                0
                             END AS diaafastado
                        FROM (SELECT vdtinicio + (LEVEL - 1) AS dtdia
                                FROM dual
                              CONNECT BY vdtInicio + (LEVEL - 1) BETWEEN
                                         vdtInicio AND vdtFim) D
                        LEFT JOIN (SELECT 1 AS DiaAfastadoT,
                                         CASE
                                           WHEN av.dtinicio < vdtinicio THEN
                                            vdtinicio
                                           ELSE
                                            av.dtinicio
                                         END AS dtinicio,
                                         CASE
                                           WHEN (AV.dtFim > pFolha.dtFimMes OR
                                                AV.DtFim IS NULL) THEN
                                            pfolha.dtfimmes
                                           ELSE
                                            av.dtfim
                                         END AS dtfim
                                    FROM eafaafastamentovinculo av
                                   INNER JOIN eafahistmotivoafasttemp hmat
                                      ON Av.CdMotivoAfastTemporario =
                                         HMAT.CdMotivoAfastTemporario
                                   INNER JOIN (SELECT HMATV.CdMotivoAfastTemporario,
                                                     MAX(HMATV.DtInicioVigencia) AS DtInicioVigencia
                                                FROM eafahistmotivoafasttemp hmatv
                                               WHERE HMATV.dtInicioVigencia <=
                                                     pFolha.DtFimMes
                                               GROUP BY hmatv.cdmotivoafasttemporario) mv
                                      ON HMAT.CdMotivoAfastTemporario =
                                         MV.CdMotivoAfastTemporario
                                     AND HMAT.DtInicioVigencia =
                                         MV.DtInicioVigencia
                                   WHERE AV.CdVinculo = pPNP.CdVinculo
                                     AND AV.FlAnulado = PKGPAG_TIPO.cnN
                                     AND (hmat.flremunerado = pkgpag_tipo.cnn OR
                                         (prubrica.ingerarubricaafasttemp = '1' AND
                                         av.cdmotivoafasttemporario IN
                                         (SELECT cdmotivoafasttemporario
                                              FROM epagrubagrupmotafasttempimp ai
                                             WHERE AI.CdMotivoAfastTemporario =
                                                   AV.CdMotivoAfastTemporario
                                               AND AI.CdHistRubricaAgrupamento =
                                                   pRubrica.CdHistRubrica)) OR
                                         (prubrica.ingerarubricaafasttemp = '2' AND
                                         ((av.cdmotivoafasttemporario NOT IN
                                         (SELECT cdmotivoafasttemporario
                                                FROM epagrubagrupmotafasttempimp ai
                                               WHERE AV.CdMotivoAfastTemporario =
                                                     AI.CdMotivoAfastTemporario
                                                 AND AI.CdHistRubricaAgrupamento =
                                                     pRubrica.CdHistRubrica)) OR
                                         (SELECT COUNT(*)
                                               FROM epagrubagrupmotafasttempimp ai
                                              WHERE AI.CdHistRubricaAgrupamento =
                                                    pRubrica.CdHistRubrica) = 0)))
                                     AND ((av.dtinicio <= pfolha.dtfimmes AND
                                         (AV.DtFim >= pFolha.dtInicioMes OR
                                         AV.DtFim IS NULL)) OR
                                         (AV.DtInclusao BETWEEN
                                         (PKGPAG_VAR.vDtCalculoAnt + 1) AND
                                         PKGPAG_VAR.vDtCalculo))) B
                          ON (B.DtInicio <= D.dtDia)
                         AND (B.DtFim >= D.dtdia)

                        LEFT JOIN (SELECT 1 AS DiaAfastadoD,
                                         CASE
                                           WHEN av.dtinicio < vdtinicio THEN
                                            vdtinicio
                                           ELSE
                                            av.dtinicio
                                         END AS dtinicio,
                                         CASE
                                           WHEN (AV.dtFim > pFolha.dtFimMes OR
                                                AV.DtFim IS NULL) THEN
                                            pfolha.dtfimmes
                                           ELSE
                                            av.dtfim
                                         END AS dtfim
                                    FROM eafaafastamentovinculo av
                                   INNER JOIN eafahistmotivoafastdef hmad
                                      ON AV.CdMotivoAfastDefinitivo =
                                         HMAD.CdMotivoAfastDefinitivo
                                   INNER JOIN (SELECT HMADV.CdMotivoAfastDefinitivo,
                                                     MAX(HMADV.DtInicioVigencia) AS DtInicioVigencia
                                                FROM eafahistmotivoafastdef hmadv
                                               WHERE HMADV.dtInicioVigencia <=
                                                     pFolha.DtFimMes
                                               GROUP BY hmadv.cdmotivoafastdefinitivo) mv
                                      ON HMAD.CdMotivoAfastDefinitivo =
                                         MV.CdMotivoAfastDefinitivo
                                     AND HMAD.DtInicioVigencia =
                                         MV.DtInicioVigencia
                                   WHERE AV.CdVinculo = pPNP.CdVinculo
                                     AND AV.FlAnulado = PKGPAG_TIPO.cnN
                                     AND HMAD.FlRemunerado = PKGPAG_TIPO.cnN
                                     AND ((av.dtinicio <= pfolha.dtfimmes AND
                                         (AV.DtFim >= pFolha.dtInicioMes OR
                                         AV.DtFim IS NULL)) OR
                                         (AV.DtInclusao BETWEEN
                                         (PKGPAG_VAR.vDtCalculoAnt + 1) AND
                                         PKGPAG_VAR.vDtCalculo))) C
                          ON (C.DtInicio <= D.dtdia)
                         AND (C.DtFim >= D.dtdia)));

      -- acerta valores

      vnudiasprop := facertardiasprop(pnudiasafast     => vnudiasafastp,
                                      pnudiasmes       => pnudiasmes,
                                      pdtiniciomes     => pdtiniciomes,
                                      pdtfimmes        => pdtfimmes,
                                      pdtfimrelacao    => ppnp.dtfim,
                                      pnudiastotal     => vnudiastotal,
                                      pbafastultdia    => FALSE,
                                      pdtiniciorelacao => ppnp.dtinicio);

      vresult.vlindice := vnudiasprop;

      IF vnudiasprop <> pnudiasmes THEN
        vResult.vlProporcional := vNuDiasProp *
                                  (vResult.vlReal / pNuDiasMes);
      ELSE
        vresult.vlproporcional := vresult.vlreal;
      END IF;

    END IF;

    vresult.vlintegral := vresult.vlproporcional;

    RETURN vresult;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  /*--------------------------------------------------------------------------------------/

  /*--------------------------------------------------------------------------------------*/
  FUNCTION fcalculaproporcionalidade(pfolha          IN pkgpag_tipo.rfolha,
                                     prubrica        IN pkgpag_tipo.rrubrica,
                                     pvalorintegral  IN NUMBER DEFAULT NULL,
                                     pnucho          IN NUMBER DEFAULT NULL,
                                     pcef            IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pfuc            IN pkgpag_tipo.rfuc DEFAULT NULL,
                                     pcco            IN pkgpag_tipo.rcco DEFAULT NULL,
                                     pccosubst       IN pkgpag_tipo.rcco DEFAULT NULL,
                                     papo            IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pbol            IN pkgpag_tipo.rbol DEFAULT NULL,
                                     ppnp            IN pkgpag_tipo.rpensaonaoprev DEFAULT NULL,
                                     pdtcalculo      IN DATE DEFAULT NULL,
                                     peventocef      IN CHAR DEFAULT 'N',
                                     pnudiasccosubst IN INTEGER DEFAULT NULL)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vnudiasmes INTEGER;

    vvalorpagamento pkgpag_tipo.rvalorpagamento;

  BEGIN
 
    vnudiasmes := fretornadiasdomesrv(pdtfimmes           => pfolha.dtfimmes,
                                      pflpropmescomercial => prubrica.flpropmescomercial);

    CASE

      WHEN pcef.cdvinculo IS NOT NULL THEN

        vvalorpagamento := fcalculaproporccef(pcef           => pcef,
                                              pnudiasmes     => vnudiasmes,
                                              prubrica       => prubrica,
                                              pvalorintegral => pvalorintegral,
                                              pnucho         => pnucho,
                                              pdtiniciomes   => pfolha.dtiniciomes,
                                              pdtfimmes      => pfolha.dtfimmes,
                                              pdtcalculo     => pdtcalculo,
                                              peventocef     => peventocef);

      WHEN pfuc.cdvinculo IS NOT NULL THEN

        vvalorpagamento := fcalculaproporcfuc(pfuc           => pfuc,
                                              pnudiasmes     => vnudiasmes,
                                              prubrica       => prubrica,
                                              pvalorintegral => pvalorintegral,
                                              pdtiniciomes   => pfolha.dtiniciomes,
                                              pdtfimmes      => pfolha.dtfimmes);

      WHEN pcco.cdvinculo IS NOT NULL AND pcco.FlTipoProvimento <> 'S' THEN

        vvalorpagamento := fcalculaproporccco(pcco           => pcco,
                                              pnudiasmes     => vnudiasmes,
                                              prubrica       => prubrica,
                                              pvalorintegral => pvalorintegral,
                                              pdtiniciomes   => pfolha.dtiniciomes,
                                              pdtfimmes      => pfolha.dtfimmes);

      WHEN pccosubst.cdvinculo IS NOT NULL OR
           (pcco.cdvinculo IS NOT NULL AND pcco.FlTipoProvimento = 'S') THEN

        IF pccosubst.cdvinculo IS NOT NULL THEN
          vvalorpagamento := fcalculaproporcccosubst(pccosubst      => pccosubst,
                                                     pnudiasmes     => vnudiasmes,
                                                     prubrica       => prubrica,
                                                     pvalorintegral => pvalorintegral,
                                                     pdtiniciomes   => pfolha.dtiniciomes,
                                                     pdtfimmes      => pfolha.dtfimmes);
        ELSE
          vvalorpagamento := fcalculaproporcccosubst(pccosubst      => pcco,
                                                     pnudiasmes     => vnudiasmes,
                                                     prubrica       => prubrica,
                                                     pvalorintegral => pvalorintegral,
                                                     pdtiniciomes   => pfolha.dtiniciomes,
                                                     pdtfimmes      => pfolha.dtfimmes);
        END IF;

      WHEN papo.cdvinculo IS NOT NULL THEN

        vValorPagamento := FCalculaProporcAPO(pFolha         => pFolha,
                                              pAPO           => pAPO,
                                              pnudiasmes     => vnudiasmes,
                                              prubrica       => prubrica,
                                              pvalorintegral => pvalorintegral);

      WHEN pbol.cdvinculoestagio IS NOT NULL THEN

        vvalorpagamento := fcalculaproporcbol(pbol         => pbol,
                                              pnudiasmes   => vnudiasmes,
                                              prubrica     => prubrica,
                                              pdtiniciomes => pfolha.dtiniciomes,
                                              pdtfimmes    => pfolha.dtfimmes);

      WHEN ppnp.cdhistpensaonaoprev IS NOT NULL THEN

        vValorPagamento := FCalculaProporcPNP(pFolha         => pFolha,
                                              pPNP           => pPNP,
                                              pnudiasmes     => vnudiasmes,
                                              prubrica       => prubrica,
                                              pdtiniciomes   => pfolha.dtiniciomes,
                                              pdtfimmes      => pfolha.dtfimmes,
                                              pvalorintegral => pvalorintegral);

      ELSE

        vvalorpagamento := NULL;

    END CASE;

    -----------------------------------------------------------------------------------------------------
    -- Apos realizar a proporcionalidade, verifica se a rubrica esta parametrizada para
    -- aplicar o percentual de reducao de afastamentos remunerados
    -----------------------------------------------------------------------------------------------------

    IF pRubrica.FlPercentReducaoAfastRemun = PKGPAG_TIPO.cnS AND
       PKGPAG_VAR.vgVlPercentReducao > 0 THEN

      vValorPagamento.vlIntegral := vValorPagamento.vlIntegral *
                                    ((100 - PKGPAG_VAR.vgVlPercentReducao) / 100);

      vValorPagamento.vlProporcional := vValorPagamento.vlProporcional *
                                        ((100 -
                                        PKGPAG_VAR.vgVlPercentReducao) / 100);

    END IF;

    RETURN vvalorpagamento;

  END;

  /*------------------------------------------------------------------------

  ------------------------------------------------------------------------*/

  FUNCTION fpossuiabrangenciarubrica(prubrica                  IN pkgpag_tipo.rrubrica,
                                     pcdorgao                  IN INTEGER,
                                     pcdorgaoexercicio         IN INTEGER,
                                     pcdnaturezavinculo        IN INTEGER DEFAULT NULL,
                                     pcdrelacaotrabalho        IN INTEGER DEFAULT NULL,
                                     pcdregimetrabalho         IN INTEGER DEFAULT NULL,
                                     pcdregimeprevidenciario   IN INTEGER DEFAULT NULL,
                                     pcdsituacaoprevidenciaria IN INTEGER DEFAULT NULL,
                                     pcdestruturacarreira      IN INTEGER DEFAULT NULL,
                                     pcdunidadeorganizacional  IN INTEGER DEFAULT NULL,
                                     pcdfuncaochefia           IN INTEGER DEFAULT NULL,
                                     pcdcargocomissionado      IN INTEGER DEFAULT NULL,
                                     pcdgrupoocupacional       IN INTEGER DEFAULT NULL,
                                     pcdopcaoremuneracao       IN INTEGER DEFAULT NULL,
                                     pflapoorigemcco           IN CHAR DEFAULT NULL,
                                     pfltipoprovimento         IN CHAR DEFAULT NULL,
                                     pflaplicatodosorgaos      IN CHAR DEFAULT 'N',
                                     pflaposemparidade         IN CHAR DEFAULT NULL,
                                     pcdprograma               IN INTEGER DEFAULT NULL,
                                     pcdmotivomovimentacao     IN INTEGER DEFAULT NULL,
                                     pcdinstitutomovimentacao  IN INTEGER DEFAULT NULL,
                                     pflexercicioorigem        IN CHAR DEFAULT 'N',
                                     pcdtiporelacaovinculo     IN INTEGER DEFAULT NULL)
    RETURN BOOLEAN IS

    brubricapermitida BOOLEAN;

    batendeuabrangencia BOOLEAN;

    bpossuictisp BOOLEAN;

    bUopermitida boolean;

    vcdestrutura INTEGER;

    vnuperiodo INTEGER;

    vcdestruturacarreira INTEGER := pcdestruturacarreira;

    vcdfuncaochefia INTEGER := pcdfuncaochefia;

    vNuDiasAfastTemp INTEGER := 0;

    vDtAfastRemunAnt DATE := NULL;

    vCdRelacaoTrabalho INTEGER := 0;

    vParamConvocacao integer;

    FUNCTION fafastadorelvinc(pcdtiporelvinc   IN INTEGER,
                              pcdhistrelvinc   IN INTEGER,
                              pdtiniciorelacao IN DATE,
                              pDtFimRelacao    IN DATE) RETURN BOOLEAN IS

      vsql VARCHAR2(4000);

      vdias INTEGER;

    BEGIN
 
      vsql := 'SELECT (:pDtFimRelacao - :pDtInicioRelacao + 1) - COUNT(DiaAfastado) ' ||
              '  FROM  ' || ' (SELECT DISTINCT dtDia,  1 AS DiaAfastado ' ||
              '   FROM (SELECT :pDtInicioRelacao + (LEVEL - 1) AS dtdia ' ||
              '           FROM dual ' ||
              '        CONNECT BY :pDtInicioRelacao + (LEVEL - 1) ' ||
              '        BETWEEN :pDtInicioRelacao AND :pDtFimRelacao) D ' ||
              '   INNER JOIN ' || '      (SELECT CASE ' ||
              '                WHEN Av.DtInicio <= :pDtInicioRelacao THEN ' ||
              '                   :pDtInicioRelacao ' ||
              '                ELSE ' || '                   Av.DtInicio ' ||
              '               END AS DtInicio, ' || '               CASE ' ||
              '                 WHEN Av.DtFim >= :pDtFimRelacao OR Av.DtFim IS NULL THEN ' ||
              '                   :pDtFimRelacao ' ||
              '                 ELSE ' || '                   Av.DtFim ' ||
              '               END AS DtFim ' ||
              '           FROM EAfaAfastamentoRelVinc AV ';

      CASE pcdtiporelvinc

        WHEN 1 THEN

          vSQL := vSQL ||
                  '  WHERE AV.CdHistCargoEfetivo = :pCdHistRelVinc AND ';

        WHEN 2 THEN

          vSQL := vSQL ||
                  '  WHERE AV.CdHistCargoCom = :pCdHistRelVinc AND ';

        WHEN 3 THEN

          vSQL := vSQL ||
                  '  WHERE AV.CdHistFuncaoChefia = :pCdHistRelVinc AND ';

      END CASE;

      vsql := vsql || ' AV.DtInicio <= :pDtFimRelacao AND ' ||
              ' (AV.DtFim >= :pDtInicioRelacao OR AV.DtFim IS NULL) AND ' ||
              ' AV.FlAnulado = ''N'') B ' ||
              ' ON (B.DtInicio <= D.Dtdia) AND (B.DtFim >= D.dtdia)) ';

      EXECUTE IMMEDIATE vSQL
        INTO vDias
        USING pdtfimrelacao, --1
      pdtiniciorelacao, --2
      pdtiniciorelacao, --3
      pdtiniciorelacao, --4
      pdtiniciorelacao, --5
      pdtfimrelacao, --6
      pdtiniciorelacao, --7
      pdtiniciorelacao, --8
      pdtfimrelacao, --9
      pdtfimrelacao, --10
      pcdhistrelvinc, --11
      pdtfimrelacao, --12
      pdtiniciorelacao; --13

      IF nvl(vdias, 0) = 0 THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    END;

    FUNCTION fAbrangeciaModeloApo(prubrica IN pkgpag_tipo.rrubrica)
      RETURN BOOLEAN IS

    BEGIN
 
      -- SE A LISTA DE MODELOS DE APOSENTADORIA DA RUBRICA ESTA VAZIA
      -- ENTAO ABRANGENCIA ESTA OK, NAO PRECISA SER VERIFICADA
      IF prubrica.lsModeloApo.COUNT = 0 THEN
        RETURN TRUE;
      END IF;

      -- VERIFICA POSSIVEIS APOSENTADORIAS COM PARIDADE DO VINCULO
      IF pkgpag_var.vgAPO.COUNT > 0 THEN
        FOR i IN pkgpag_var.vgAPO.FIRST .. pkgpag_var.vgAPO.LAST LOOP

          IF prubrica.lsModeloApo.EXISTS(pkgpag_var.vgAPO(i).cdmodeloaposentadoria) THEN
            RETURN TRUE;
          END IF;

        END LOOP;
      END IF;

      -- VERIFICA POSSIVEIS APOSENTADORIAS SEM PARIDADE DO VINCULO
      IF pkgpag_var.vgAPOSemParidade.COUNT > 0 THEN
        FOR i IN pkgpag_var.vgAPOSemParidade.FIRST .. pkgpag_var.vgAPOSemParidade.LAST LOOP

          IF prubrica.lsModeloApo.EXISTS(pkgpag_var.vgAPOSemParidade(i).cdmodeloaposentadoria) THEN
            RETURN TRUE;
          END IF;

        END LOOP;
      END IF;

      -- SE NAO ENCONTROU MODELO DE APOSENTADORIA, RETORNA FALSO
      RETURN FALSE;

    END;

    FUNCTION fPossuiExcecaoAfast(pCdVinculo     IN INTEGER,
                                 pCdMotivoAfast IN INTEGER,
                                 pCdHistRubrica IN INTEGER,
                                 pNuRubrica     in integer)

     RETURN BOOLEAN IS

      vCont INTEGER := 0;

    BEGIN
 
      SELECT 1
        INTO vCont
        FROM epagrubagrpmotaftempimpvinc vi
       WHERE vi.cdvinculo = pCdVinculo
         AND vi.Cdmotivoafasttemporario = pCdMotivoAfast
         AND vi.cdhistrubricaagrupamento = pCdHistRubrica
         AND rownum < 2;

      IF vCont > 0 THEN
        RETURN TRUE;
      END IF;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        if pNuRubrica = 574 then
          vCont := 0;
          BEGIN
            SELECT 1
              INTO vCont
              from eafahistmotivoafasttemp hmat
             where HMAT.CdMotivoAfastTemporario = pCdMotivoAfast
               and trunc(HMAT.dtInicioVigencia) <=
                   trunc(pkgpag_var.vgFolha.DtFimMes)
               and (hmat.dtfimvigencia is null or
                   trunc(hmat.dtfimvigencia) >=
                   trunc(pkgpag_var.vgFolha.DtInicioMes))
               and nvl(hmat.vlpercentreducaoiresa, 0) > 0
               AND rownum < 2;

            IF vCont > 0 THEN
              RETURN TRUE;
            END IF;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN FALSE;
          END;
        else
          return false;
        end if;

    END;

    FUNCTION flotadoemexercicio(prubrica IN pkgpag_tipo.rrubrica,
                                pcdorgao IN INTEGER)

     RETURN BOOLEAN IS

      velotado BOOLEAN := FALSE;

      vemexercicio BOOLEAN := FALSE;

      vtporgaolotado INTEGER := 0;

      vtporgaoexercicio INTEGER := 0;

      vAfastadoRelVinc BOOLEAN := FALSE;

    BEGIN
 
      --- Indica como lotado todo servidor em que o orgao do vinculo esta dentre os
      --- orgaos permitidos pela rubrica

      IF prubrica.lsorgao.exists(pcdorgao) THEN

        velotado := TRUE;

        vtporgaolotado := prubrica.lsorgao(pcdorgao).inlotadoexercicio;

        IF PKGPAG_VAR.vgCEF.COUNT > 0 AND pCdEstruturaCarreira IS NOT NULL AND PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho = 10 AND PKGPAG_VAR.vgCEF(1).FlPrincipal = 'S' AND
           pkgpag_var.vgcco.count = 0 AND pkgpag_var.vgccosubst.count = 0 THEN

          velotado := FALSE;

          vtporgaolotado := 0;

        END IF;

        IF (PKGPAG_VAR.vgAPO.COUNT > 0 OR
           PKGPAG_VAR.vgAPOSemParidade.COUNT > 0) AND
           pcdsituacaoprevidenciaria = 2 THEN

          vemexercicio := TRUE;

          vtporgaoexercicio := prubrica.lsorgao(pcdorgao).inlotadoexercicio;

        END IF;

      END IF;
      -----
      ----- Indica como em exercicio todo servidor em que o orgao de exercico do efetivo
      ----- esta dentre os orgaos permitidos pela rubrica e desde que o servidor nao esteja
      ----- afastado da sua relacao de vinculo
      ----- E tambem os que tem comissionado ou estao substituindo com relacao de trabalho 5 e 10.
      -----

      IF pkgpag_var.vgcef.count > 0 AND pcdestruturacarreira IS NOT NULL THEN

        FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

          IF pkgpag_var.vgcef(i).cdestruturacarreira = pcdestruturacarreira THEN

            IF prubrica.lsorgao.exists(pkgpag_var.vgcef(i).cdorgaoexercicio) OR
               (pRubrica.lsOrgao.EXISTS(pCdOrgao) AND
                pFlExercicioOrigem = 'S') THEN

              vAfastadoRelVinc := FAfastadoRelVinc(1,
                                                   PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                   pkgpag_var.vgcef(i).dtinicio,
                                                   PKGPAG_VAR.vgCEF(i).DtFim);

              IF NOT vAfastadoRelVinc OR (PKGPAG_VAR.vgCCO.COUNT > 0 AND PKGPAG_VAR.vgCEF(i).CdOrgaoExercicio = PKGPAG_VAR.vgCCO(1).CdOrgaoExercicio AND PKGPAG_VAR.vgCEF(i)
                 .CdRelacaoTrabalho in (5, 10)) -- Incluido a disposicao em 08/04/14
                 OR (PKGPAG_VAR.vgCCOSubst.COUNT > 0 AND PKGPAG_VAR.vgCEF(i).CdOrgaoExercicio = PKGPAG_VAR.vgCCOSubst(1).CdOrgaoExercicio AND PKGPAG_VAR.vgCEF(i)
                 .CdRelacaoTrabalho in (5, 10))

               THEN

                vemexercicio := TRUE;

                --- O servidor que esta a disposicao do destino pelo instituto da convocacao
                ---- o sistema deve entende-lo como em exercicio na origem (orgao do vinculo)

                IF pFlExercicioOrigem = 'S' AND PKGPAG_VAR.vgCEF(i).CdRelacaoTrabalho = 10 THEN

                  vTpOrgaoExercicio := pRubrica.lsOrgao(pCdOrgao).InLotadoExercicio;

                ELSE

                  vTpOrgaoExercicio := pRubrica.lsOrgao(PKGPAG_VAR.vgCEF(i).CdOrgaoExercicio).InLotadoExercicio;

                END IF;

                --- pFlExercicioOrigem = CAMPO QUE INDICA SE O INSTITUTO DA MOVIMENTACAO DETERMINADA EXERCICIO NA ORIGEM

              ELSIF pFlExercicioOrigem = 'S' AND PKGPAG_VAR.vgCEF(i).CdRelacaoTrabalho = 5 THEN

                vemexercicio := TRUE;

                vTpOrgaoExercicio := pRubrica.lsOrgao(pCdOrgao).InLotadoExercicio;

              else
                null;
              END IF;

              --
              -- Verificar se existe movimentacao e se a mesma esta na lista das permitidas
              -- para quem esta a disposicao
              -- 9805/2017 - FOLHA - RUBRICA 01-0129 SEF
              --
            ELSIF pFlExercicioOrigem = 'N' AND PKGPAG_VAR.vgCEF(i).CdRelacaoTrabalho = 10 AND
                  prubrica.ingerarubricamotmovi = '2' AND
                  prubrica.lsmovinstituto.count > 0 AND
                  pCdMotivoMovimentacao IS NOT NULL

             THEN

              FOR i IN pRubrica.lsMovInstituto.FIRST .. pRubrica.lsMovInstituto.LAST LOOP

                IF pRubrica.lsMovInstituto(i).CdMotivoMovimentacao IS NOT NULL AND
                    pCdMotivoMovimentacao = pRubrica.lsMovInstituto(i).CdMotivoMovimentacao

                 THEN

                  vemexercicio := TRUE;

                  vTpOrgaoExercicio := pRubrica.lsOrgao(pCdOrgao).InLotadoExercicio;

                END IF;

              END LOOP;

            else
              null;
            END IF;

          END IF;

        END LOOP;

        ----- Indica como em exercicio todo servidor em que o orgao de exercico do comissionado
        ----- esta dentre os orgaos permitidos pela rubrica e desde que o servidor nao esteja
        ----- afastado da sua relacao de vinculo

        IF pkgpag_var.vgcco.count > 0 AND pcdcargocomissionado IS NOT NULL THEN

          FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST LOOP

            IF PKGPAG_VAR.vgCCO(i)
             .CdCargoComissionado = pCdCargoComissionado THEN

              IF pRubrica.lsOrgao.EXISTS(PKGPAG_VAR.vgCCO(i).CdOrgaoExercicio) THEN

                IF (prubrica.FLPagaEfetivoOrgao = 'S' AND
                   NOT prubrica.lsorgao.exists(pcdorgao)) -- 22
                 THEN
                  -- SIG-1440 par?metro lotado e ou em exercicio
                  -- Somente efetivos dos ?rg?os permitidos tem direito.
                  -- Se um efetivo de outro ?rg?o for assumir comissionado n?o deve receber.
                  vemexercicio := FALSE;

                ELSE

                  IF NOT FAfastadoRelVinc(1,
                                          PKGPAG_VAR.vgCCO(i).CdHistCargoCom,
                                          pkgpag_var.vgcco(i).dtinicio,
                                          pkgpag_var.vgcco(i).dtfim) THEN

                    vemexercicio      := TRUE;
                    vTpOrgaoExercicio := pRubrica.lsOrgao(PKGPAG_VAR.vgCCO(i).CdOrgaoExercicio).InLotadoExercicio;

                  ELSE

                    vemexercicio := FALSE;

                  END IF;

                END IF;

              END IF;

            END IF;

          END LOOP;

        END IF;

        ----- Indica como em exercicio todo servidor em que o orgao de exercico da funcao
        ----- esta dentre os orgaos permitidos pela rubrica e desde que o servidor nao esteja
        ----- afastado da sua relacao de vinculo

        IF pkgpag_var.vgfuc.count > 0 AND vcdfuncaochefia IS NOT NULL THEN

          FOR i IN PKGPAG_VAR.vgFUC.FIRST .. PKGPAG_VAR.vgFUC.LAST LOOP

            IF prubrica.lsorgao.exists(pkgpag_var.vgfuc(i).cdorgaoexercicio) THEN

              IF NOT FAfastadoRelVinc(1,
                                      PKGPAG_VAR.vgFUC(i).CdHistFuncaoChefia,
                                      pkgpag_var.vgfuc(i).dtinicio,
                                      pkgpag_var.vgfuc(i).dtfim) THEN

                vemexercicio := TRUE;

                vTpOrgaoExercicio := pRubrica.lsOrgao(PKGPAG_VAR.vgFUC(i).CdOrgaoExercicio).InLotadoExercicio;

              END IF;

            END IF;

          END LOOP;

        END IF;

      END IF;

      --- Indica como lotado e em exercicio todo comissionado que esteja com orgao de exercicio dentre
      --- os orgaos permitidos pela rubrica.
      --- Apesar de verificar o exercicio, todo comissionado em exercicio e como se lotado tambem estivesse

      IF pkgpag_var.vgcco.count > 0 AND pcdcargocomissionado IS NOT NULL THEN

        FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST LOOP

          IF pkgpag_var.vgcco(i).cdcargocomissionado = pcdcargocomissionado THEN

            IF prubrica.lsorgao.exists(pkgpag_var.vgcco(i).cdorgaoexercicio) THEN

              velotado := TRUE;

              vemexercicio := TRUE;

              vTpOrgaoLotado    := pRubrica.lsOrgao(PKGPAG_VAR.vgCCO(i).CdOrgaoExercicio).InLotadoExercicio;
              vTpOrgaoExercicio := pRubrica.lsOrgao(PKGPAG_VAR.vgCCO(i).CdOrgaoExercicio).InLotadoExercicio;

            END IF;

          END IF;

        END LOOP;

      END IF;

      IF PKGPAG_VAR.vgCCOSubst.COUNT > 0 AND
         pCdCargoComissionado IS NOT NULL THEN

        FOR i IN PKGPAG_VAR.vgCCOSubst.FIRST .. PKGPAG_VAR.vgCCOSubst.LAST LOOP

          IF PKGPAG_VAR.vgCCOSubst(i)
           .CdCargoComissionado = pCdCargoComissionado THEN

            IF pRubrica.lsOrgao.EXISTS(PKGPAG_VAR.vgCCOSubst(i).CdOrgaoExercicio) THEN

              velotado := TRUE;

              vemexercicio := TRUE;

              vTpOrgaoLotado    := pRubrica.lsOrgao(PKGPAG_VAR.vgCCOSubst(i).CdOrgaoExercicio).InLotadoExercicio;
              vTpOrgaoExercicio := pRubrica.lsOrgao(PKGPAG_VAR.vgCCOSubst(i).CdOrgaoExercicio).InLotadoExercicio;

            END IF;

          END IF;

        END LOOP;

      END IF;

      IF vTpOrgaoLotado IN ('1') THEN
        -- EXIGE LOTADO

        IF velotado THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      ELSIF vTpOrgaoExercicio IN ('2') THEN
        -- EXIGE EM EXERCICIO

        IF vemexercicio THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      ELSIF vTpOrgaoLotado IN ('3') OR vTpOrgaoExercicio IN ('3') THEN
        -- EXIGE LOTADO OU EM EXERCICIO

        IF velotado OR vemexercicio THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      ELSIF vTpOrgaoLotado IN ('4') AND vTpOrgaoExercicio IN ('4') THEN
        -- EXIGE LOTADO E EM EXERCICIO

        IF velotado AND vemexercicio THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      else
        null;
      END IF;

      RETURN FALSE;

    exception
      when others then
        return false;

    END;

  BEGIN
     
    IF prubrica.flsuspensa = pkgpag_tipo.cns THEN

      RETURN FALSE;

    END IF;

    IF pRubrica.FlImpedeIdadeCompulsoria = 'S' AND
       PKGPAG_VAR.vgCEF.COUNT > 0 THEN
      -- Nao pagar para acima de 75 anos pra quem tem CEF
      IF MONTHS_BETWEEN(PKGPAG_VAR.vgFolha.DtFimMes,
                        PKGPAG_VAR.vgVinculo.DtNascimento) >= 900 THEN
        RETURN FALSE;
      END IF;
    END IF;

    -- Caso a rubrica nao se aplique a todos os orgaos, verifica se o orgao do vinculo ou
    -- da relacao de vinculo esta contemplado na lista de orgaos associados e rubrica,
    -- utilizando o indicativo InLotadoExercicio.

    IF prubrica.flaplicarubricaorgaos = 'N' THEN

      IF pFlAplicaTodosOrgaos = 'N' AND
         NOT FLotadoEmExercicio(pRubrica, pCdOrgao) THEN

        RETURN FALSE;

      END IF;

    END IF;

    -- Verifica a abrangencia para as relacoes de vinculo de aposentadoria e pensoes
    IF pcdsituacaoprevidenciaria IN (2, 3, 4, 5, 7, 9, 10, 11) OR
     (pCdSituacaoPrevidenciaria = 1 AND PKGPAG_VAR.vgVinculo.DtDesligamento < pkgpag_var.vgfolha.DtInicioMes) THEN
     -- ACTs com situacao previd. "Ativo" e data de desligamento no mês anterior, também precisa verifica a abrangencia

      -- Verifica modelo de aposentadoria
      IF NOT fAbrangeciaModeloApo(pRubrica) THEN

        RETURN FALSE;

      END IF;

      -- Verificacao de abrangencia para Aposentados com CTISP

      bpossuictisp := FALSE;

      IF pkgpag_var.vgcef.count > 0 THEN

        FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

          IF pkgpag_var.vgcef(i).cdrelacaotrabalho = pkgpag_tipo.cnrelctisp THEN

            bpossuictisp := TRUE;

          END IF;

        END LOOP;

      END IF;

      --
      -- Somente permitir para quem tem CTISP se na lista tiver somente CTISP e mais nenhuma
      --
      IF NOT bPossuiCTISP AND
         pRubrica.lsRelTrab.EXISTS(PKGPAG_TIPO.cnRelCTISP) AND
         pRubrica.lsRelTrab.FIRST = pRubrica.lsRelTrab.LAST THEN

        RETURN FALSE;

      END IF;

      IF pCdSituacaoPrevidenciaria = 2 AND
         NOT pRubrica.lsSitPrev.EXISTS(pCdSituacaoPrevidenciaria) AND
         prubrica.flpermiteapooriginadocco = 'N' THEN

        RETURN FALSE;

      END IF;

      IF pCdSituacaoPrevidenciaria = 2 AND
         NOT pRubrica.lsSitPrev.EXISTS(pCdSituacaoPrevidenciaria) AND
         prubrica.flpermiteapooriginadocco = 'S' AND pflapoorigemcco = 'N' THEN

        RETURN FALSE;

      END IF;

      IF pCdSituacaoPrevidenciaria = 2 AND
         pRubrica.lsSitPrev.EXISTS(pCdSituacaoPrevidenciaria) AND
         prubrica.flpermiteapooriginadocco = 'N' AND pflapoorigemcco = 'S' THEN

        RETURN FALSE;

      END IF;

      IF pCdSituacaoPrevidenciaria = 2 AND
         pCdUnidadeOrganizacional IS NOT NULL THEN

        IF prubrica.lsuo.count > 0 THEN

          IF NOT prubrica.lsuo.exists(pcdunidadeorganizacional) THEN

            RETURN FALSE;

          END IF;

        END IF;

      END IF;

      IF pcdrelacaotrabalho IS NOT NULL THEN

        IF NOT prubrica.lsreltrab.exists(pcdrelacaotrabalho) THEN

          RETURN FALSE;

        END IF;

      END IF;

      IF pflaposemparidade IS NOT NULL THEN

        IF prubrica.flpagaaposemparidade = 'N' AND pflaposemparidade = 'S' THEN

          RETURN FALSE;

        END IF;

      END IF;

      IF (pCdSituacaoPrevidenciaria IN (2, 3) AND
         (pflapoorigemcco IS NULL OR pflapoorigemcco = 'N')) OR
         (pCdSituacaoPrevidenciaria = 1 AND
          PKGPAG_VAR.vgVinculo.DtDesligamento < pkgpag_var.vgfolha.DtInicioMes) THEN

        if pCdEstruturaCarreira IS NOT NULL then
          vcdestruturacarreira := pcdestruturacarreira;
        elsif pkgpag_var.vgcef.count > 0 THEN
          vcdestruturacarreira := pkgpag_var.vgcef(1).cdestruturacarreira;
        else
          null;
        end if;

        if vcdestruturacarreira is null then

          begin

            -- Para inativo/aposentado pega a carreira anterior a data da aposentadoria
            if pcdsituacaoprevidenciaria in (2) then
              select cef.cdestruturacarreira
              --ec.cdestruturacarreiracarreira
                into vcdestruturacarreira
                from epvdconcessaoaposentadoria ca
               inner join ecadhistcargoefetivo cef
                  on cef.cdvinculo = ca.cdvinculo
               inner join ecadestruturacarreira ec
                  on cef.cdestruturacarreira = ec.cdestruturacarreira
               where ca.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
                 and ca.cdorgaoexercicio = pkgpag_var.vgfolha.cdorgao
                 and ca.flativa = pkgpag_tipo.cns
                 and ca.flanulado = pkgpag_tipo.cnn
                 and cef.cdrelacaotrabalho <>
                     pkgpag_tipo.cnreltrabdisposicao
                 and ((ca.dtinicioaposentadoria <=
                     pkgpag_var.vgFolha.dtfimmes) and
                     (ca.dtfimaposentadoria >=
                     pkgpag_var.vgFolha.dtiniciomes or
                     ca.dtfimaposentadoria is null))
                    --and cef.flefetivacao = pkgpag_tipo.cnt
                 and cef.dtfim =
                     (select max(dtfim)
                        from ecadhistcargoefetivo cef
                       where cef.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
                         and cef.cdrelacaotrabalho <>
                             pkgpag_tipo.cnreltrabdisposicao
                            --and cef.flefetivacao = pkgpag_tipo.cnt
                         and cef.flanulado = pkgpag_tipo.cnn)
                 and rownum < 2
               order by ca.dtinicioaposentadoria desc;

            else
              select cdestruturacarreira
                into vcdestruturacarreira
                from (select distinct c.cdestruturacarreira,
                                      c.cdfolhapagamento
                        from epagcapahistrubricavinculo c,
                             epagfolhapagamento         fpant,
                             epagfolhapagamento         fp
                       where c.cdfolhapagamento = fpant.cdfolhapagamento
                         and fpant.cdtipofolhapagamento =
                             fp.cdtipofolhapagamento
                         and fpant.cdorgao = fp.cdorgao
                         and fpant.flcalculodefinitivo = 'S'
                         and fpant.nuanomesreferencia =
                             (select max(fpa2.nuanomesreferencia)
                                from epagfolhapagamento fpa2
                               where fpa2.cdtipofolhapagamento =
                                     fpant.cdtipofolhapagamento
                                 and fpa2.cdorgao = fpant.cdorgao
                                 and fpa2.flcalculodefinitivo = 'S'
                                 and fpa2.nuanomesreferencia <
                                     fp.nuanomesreferencia)
                         and fp.cdfolhapagamento =
                             pkgpag_var.vgFolha.cdfolhapagamento
                         and c.cdvinculo = pkgpag_var.vgvinculo.cdvinculo
                       order by c.cdfolhapagamento desc)
               where rownum <= 1;
            end if;

          exception
            when others then
              vcdestruturacarreira := null;
          end;

        end if;

        if vcdestruturacarreira is not null then
          IF prubrica.ingerarubricacarreira = '1' THEN

            -- Algumas carreiras impedem a geracao da rubrica
            vcdestrutura := fexistecarreira(vcdestruturacarreira);
            WHILE vcdestrutura IS NOT NULL LOOP
              IF prubrica.lscarreira.exists(vcdestrutura) THEN
                RETURN FALSE;
              END IF;
              vcdestrutura := fproxcarreira(vcdestrutura);
            END LOOP;

          ELSIF prubrica.ingerarubricacarreira = '2' THEN

            -- Algumas carreiras exigem a geracao da rubrica
            brubricapermitida := FALSE;
            vcdestrutura      := fexistecarreira(vcdestruturacarreira);
            WHILE vcdestrutura IS NOT NULL LOOP
              IF prubrica.lscarreira.exists(vcdestrutura) THEN
                brubricapermitida := TRUE;
                EXIT;
              END IF;
              vcdestrutura := fproxcarreira(vcdestrutura);
            END LOOP;

            IF NOT brubricapermitida THEN
              RETURN FALSE;
            END IF;

          else
            null;
          END IF;

          /*elsif pRubrica.CdRubricaAgrupamento = 8864 then -- provisorio, chamado 12820 Rubrica 01-0131 Pos gradua??o

          PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                  PKGPAG_VAR.vCdHistParamCalc,
                                  pkgpag_var.vgvinculo.cdpessoa,
                                  'Nao foi possivel identificar a carreira antes da aposentadoria - chamado 12820',
                                  pkgpag_var.vgvinculo.cdvinculo);*/

        else
          null;
        end if;
      END IF;

      IF NOT pcdsituacaoprevidenciaria = 2 THEN

        IF NOT prubrica.lssitprev.exists(pcdsituacaoprevidenciaria) THEN

          RETURN FALSE;

        END IF;

      END IF;

      -- Verifica a abrangencia para a relacao de vinculo funcao de chefia
      --ELSIF pCdFuncaoChefia IS NOT NULL THEN
    ELSE

      -- IMPLEMENTACAO DA REGRA DE ABRANGENCIA DA RUBRICA REFERENTE AO FlGeraRubricaFUCIncideCEF
      IF vcdfuncaochefia IS NULL AND
         prubrica.FlGeraRubricaFUCIncideCEF = 'S' AND
         PKGPAG_VAR.vgCEF.COUNT > 0 AND PKGPAG_VAR.vgFUC.COUNT > 0 THEN

        vcdfuncaochefia := PKGPAG_VAR.vgFUC(PKGPAG_VAR.vgFUC.LAST).cdfuncaochefia;

      END IF;

      --
      -- Para a Rubrica 279 so pode pagar na relacao de efetivo se existir uma funcao de chefia
      -- ativa
      -- Solicitacao de Sustentacao #77930
      -- SEA/PGE - Rubrica 01-0279
      --

      if pRubrica.NuRubrica = 279 and pcdtiporelacaovinculo = 1 and
         vcdfuncaochefia is null THEN
        return false;
      end if;

      IF vcdfuncaochefia IS NOT NULL THEN

        --  Algumas funcoes de chefia impedem a geracao da rubrica.
        IF prubrica.ingerarubricafuc = '1' THEN

          IF prubrica.lsfuc.exists(vcdfuncaochefia) THEN

            RETURN FALSE;

          END IF;

          -- Algumas funcoes de chefia exigem a geracao da rubrica.
        ELSIF prubrica.ingerarubricafuc = '2' THEN

          IF NOT prubrica.lsfuc.exists(vcdfuncaochefia) THEN

            RETURN FALSE;

          END IF;

          -- Nenhuma funcao de chefia permite a geracao da rubrica.
        ELSIF prubrica.ingerarubricafuc = '4' THEN

          RETURN FALSE;

        else
          null;
        END IF;

        -- Verifica se a rubrica paga substituicao ou ato de responder e se a efetivacao
        -- do historico de funcao de chefia e = 'S' (Substituicao) ou = 'R' (Responder)
        IF prubrica.flpagasubstituicao = 'N' AND pfltipoprovimento = 'S' THEN

          RETURN FALSE;

        ELSIF prubrica.flpagarespondendo = 'N' AND pfltipoprovimento = 'R' THEN

          RETURN FALSE;

        else
          null;
        END IF;

      END IF;

      --ELSE
      -- Verifica a abrangencia para a relacoes de vinculo de CEF, CCO e BOL

      IF pcdunidadeorganizacional IS NOT NULL THEN

        IF prubrica.lsuo.count > 0 THEN

          -- Algumas unidades organizacionais impedem a geracao da rubrica
          IF prubrica.InGeraRubricaUO = 1 THEN

            IF prubrica.lsuo.exists(pcdunidadeorganizacional) OR
               (pkgpag_var.vgCCO.Count > 0 AND
                pcdunidadeorganizacional <> pkgpag_var.vgCCO(1).CdUnidadeOrganizacional AND
                prubrica.lsuo.exists(pkgpag_var.vgCCO(1).CdUnidadeOrganizacional)) THEN

              RETURN FALSE;

            END IF;

            -- Algumas unidades organizacionais permitem a geracao da rubrica
          ELSIF prubrica.InGeraRubricaUO = 2 THEN

            IF NVL(pkgpag_var.vgCCO.Count, 0) = 0 AND
               NOT prubrica.lsuo.exists(pcdunidadeorganizacional) THEN

              RETURN FALSE;

            END IF;

            IF pkgpag_var.vgCCO.Count > 0 then

              bUopermitida := false;

              for i in pkgpag_var.vgCCO.first .. pkgpag_var.vgCCO.last loop

                if prubrica.lsuo.exists(pkgpag_var.vgCCO(i).CdUnidadeOrganizacional) and
                   (NVL(pcdcargocomissionado, 0) = 0 or
                    pcdcargocomissionado = pkgpag_var.vgCCO(i).CdCargoComissionado) then

                  bUopermitida := true;

                end if;

              end loop;

              if bUoPermitida = false then

                return false;

              end if;

            END IF;

          else
            null;
          END IF;

        END IF;

      END IF;

      -- Natureza de vinculo
      IF pcdnaturezavinculo IS NOT NULL THEN

        IF NOT prubrica.lsnatvinc.exists(pcdnaturezavinculo) THEN

          RETURN FALSE;

        END IF;

      END IF;

      -- Situacao previdenciaria
      IF pcdsituacaoprevidenciaria IS NOT NULL THEN

        IF NOT prubrica.lssitprev.exists(pcdsituacaoprevidenciaria) THEN

          RETURN FALSE;

        END IF;

      END IF;

      -- Relacao de trabalho
      IF pcdrelacaotrabalho IS NOT NULL THEN

        vCdRelacaoTrabalho := pCdRelacaoTrabalho;

        -- Caso a relacao de trabalho seja de FG ou FTG verifica o atributo
        -- FlPermiteFGFTG para saber se paga o vinculo caso este nao possua
        -- um cargo efetivo
        -- E permitido, manter o seu cargo com a FG/;FTG e a substituicao ser
        -- pela opcao do comissionado que e mais vantajoso
        IF pkgpag_var.vgCCOSubst.count > 0 AND pkgpag_var.vgCCO.count > 0 and pkgpag_var.vgCCOSubst(1).CdOpcaoRemuneracao <> 3
           and pcdrelacaotrabalho <> 10 THEN
          -- se o vinculo possuir uma relacao de trabalho cco e substituicao cco,
          -- considera a relacao trab do cco desde que a opcao de remuneracao nao seja
          -- pelo comissionado (3)
          -- e nao esteja a disposicao
          vCdRelacaoTrabalho := pkgpag_var.vgCCO(1).cdrelacaotrabalho;
        END IF;
        -- SIG-5577 Substituicao - erro gratificacao - Gerando rubrica indevida 01-0477
        -- parametro nao permite pagamento para comissionados puros
        IF pkgpag_var.vgCCOSubst.count > 0 AND pkgpag_var.vgCCO.count > 0 and pkgpag_var.vgCCOSubst(1).CdOpcaoRemuneracao = 3 AND
           NOT pRubrica.lsRelTrab.EXISTS(pCdRelacaoTrabalho) THEN
          RETURN FALSE;
        END IF;
        
        IF vCdRelacaoTrabalho IN (6, 9, 12, 13) AND
           NOT pRubrica.lsRelTrab.EXISTS(pCdRelacaoTrabalho) AND
           prubrica.flpermitefgftg = 'N' THEN

          IF NOT
              (pRubrica.FlPagaSubstituicao = 'S' AND pFlTipoProvimento = 'S') THEN

            RETURN FALSE;

          END IF;

        END IF;

        IF vCdRelacaoTrabalho IN (6, 9, 12, 13) AND
           pRubrica.lsRelTrab.EXISTS(vCdRelacaoTrabalho) AND
           pRubrica.FlPermiteFGFTG = 'N' AND
           PKGPAG_VAR.bVinculoComCEF = FALSE and pcdrelacaotrabalho <> 4 THEN
          -- <> Agente politico

          RETURN FALSE;

        END IF;

        IF vCdRelacaoTrabalho IN (6, 9, 12, 13) AND
           NOT pRubrica.lsRelTrab.EXISTS(vCdRelacaoTrabalho) AND
           pRubrica.FlPermiteFGFTG = 'S' AND
           PKGPAG_VAR.bVinculoComCEF = TRUE THEN

          if pkgpag_var.vgFolha.CdAgrupamento = 133 and
             pCdRelacaoTrabalho = 6 and pkgpag_var.vgCCOSubst.count > 0 and
             pRubrica.FlPagaSubstituicao = 'S' then

            null;

          else

            RETURN FALSE;

          end if;

        END IF;

        IF vcdrelacaotrabalho NOT IN (6, 9, 12, 13 ) THEN

          IF NOT prubrica.lsreltrab.exists(vcdrelacaotrabalho) 
          and not prubrica.CdRubricaAgrupamento = pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,0018) THEN

            RETURN FALSE;

          END IF;

        END IF;

      END IF;

      -- Regime de trabalho
      IF pcdregimetrabalho IS NOT NULL THEN

        IF NOT prubrica.lsregtrab.exists(pcdregimetrabalho) THEN

          RETURN FALSE;

        END IF;

      END IF;

      -- Regime Previdenciario

      IF pcdregimeprevidenciario IS NOT NULL THEN

        IF NOT prubrica.lsregprev.exists(pcdregimeprevidenciario) THEN

          RETURN FALSE;

        END IF;

      END IF;

      -- Cargo Comissionado
      IF pCdCargoComissionado IS NOT NULL AND
         pCdGrupoOcupacional IS NOT NULL THEN

        IF pcdopcaoremuneracao IN ( /*2,*/ 4, 5, 7) THEN

          RETURN FALSE;

        END IF;

        IF (pCdTipoRelacaoVinculo = 1 AND
           pRubrica.FlGeraRubricaCCOIncideCEF = 'N') THEN

          NULL;

          -- Rever para grupo
          -- Alguns cargos comissionados/grupos ocupacionais impedem a geracao da rubrica.
        ELSIF prubrica.ingerarubricacco = '1' THEN

          IF prubrica.lscco.exists(pcdcargocomissionado) AND
             prubrica.lsgrupoocupacional.exists(pcdgrupoocupacional) THEN

            RETURN FALSE;

          END IF;

          -- Alguns cargos comissionados/grupos ocupacionais exigem a geracao da rubrica.
        ELSIF prubrica.ingerarubricacco = '2' THEN

          IF NOT (prubrica.lscco.exists(pcdcargocomissionado) AND
              prubrica.lsgrupoocupacional.exists(pcdgrupoocupacional)) THEN

            RETURN FALSE;

          END IF;

        else
          null;
        END IF;

        -- Caso a rubrica nao pague substituicao e o provimento da relacao de CCO
        -- seja de subtituicao, nao paga a rubrica
        IF prubrica.flpagasubstituicao = 'N' AND pfltipoprovimento = 'S' THEN

          RETURN FALSE;

        END IF;

      END IF;

      -- Alguns cargos comissionados permitem a geracao da rubrica sendo pre-requisito
      -- para geracao para a relacao de efetivo
      -- SIG-4500
      -- PGTC - Rubrica 01-0030 - SIGRH deixou de lancar automaticamente
      if pCdTipoRelacaoVinculo = 1 and
         pRubrica.FlGeraRubricaCCOIncideCEF = 'S' and
         prubrica.ingerarubricacco = '2' and
         pkgpag_var.vgFolha.CdOrgao = 46 THEN

        if nvl(pkgpag_var.vgcco.count, 0) = 0 then

          return false;

        elsiF NOT
               prubrica.lscco.exists(pkgpag_var.vgcco(pkgpag_var.vgcco.last).cdcargocomissionado) THEN

          RETURN FALSE;

        end if;

      end if;

      --
      -- Verificar se tem efetivo e usar a estrutura da carreira do efetivo.
      -- A partir daqui foi substituido o pCdEstruturaCarreira por vCdEstruturaCarreira
      --
      IF PKGPAG_VAR.vgCEF.COUNT > 0 and vCdEstruturaCarreira IS NULL THEN
        vcdestruturacarreira := pkgpag_var.vgcef(1).cdestruturacarreira;

      END IF;

      -- Carreira
      IF vcdestruturacarreira IS NOT NULL THEN

        -- Incluido em 08/09/2011
        -- Caso a rubrica esteja parametrizada para levar em consideracao
        -- o cargo comissionado e o parametro nao esta informado
        IF prubrica.lscco.count > 0 and
           prubrica.flgerarubricacarreiraincidecco = 'S' AND
           ((nvl(pkgpag_var.vgcco.count, 0) = 0) or
           (pkgpag_var.vgcco.count > 0 and not
            prubrica.lscco.exists(pkgpag_var.vgcco(pkgpag_var.vgcco.last).cdcargocomissionado)))

         THEN

          -- Alguns cargos comissionados/grupos ocupacionais exigem a geracao da rubrica.
          -- Incluida verificacao se nao possui funcao de chefia.
          -- Nao estava gerando e retornava FALSE aqui. Coisa braba.
          IF prubrica.ingerarubricacco = '2' AND vcdfuncaochefia IS NULL AND
             prubrica.CdRubricaAgrupamento not in (12214, 37847) THEN

            RETURN FALSE;

          END IF;

        END IF;

        IF (pCdTipoRelacaoVinculo = 2 AND
           pRubrica.FlGeraRubricaCarreiraIncideCCO = 'N') OR
           (pCdTipoRelacaoVinculo = 4 AND
           pRubrica.FlGeraRubricaCarreiraIncideAPO = 'N') THEN

          NULL;

          -- Algumas carreiras impedem a geracao da rubrica
        ELSIF prubrica.ingerarubricacarreira = '1' THEN

          vcdestrutura := fexistecarreira(vcdestruturacarreira);

          WHILE vcdestrutura IS NOT NULL LOOP

            IF prubrica.lscarreira.exists(vcdestrutura) THEN

              -- Excecao para a Saude quando tem comissionado para o trienio.

              if pRubrica.NuRubrica = 18 and pkgpag_var.vgcco.count > 0 and
                 pCdOrgao = 28 then

                vcdestrutura := vcdestrutura;

              ELSE

                RETURN FALSE;

              END IF;

            END IF;

            vcdestrutura := fproxcarreira(vcdestrutura);

          END LOOP;

          -- Algumas carreiras exigem a geracao da rubrica

        ELSIF prubrica.ingerarubricacarreira = '2' THEN

          brubricapermitida := FALSE;

          vcdestrutura := fexistecarreira(vcdestruturacarreira);

          WHILE vcdestrutura IS NOT NULL LOOP

            IF prubrica.lscarreira.exists(vcdestrutura) THEN

              brubricapermitida := TRUE;

              EXIT;

            END IF;

            vcdestrutura := fproxcarreira(vcdestrutura);

          END LOOP;

          IF NOT brubricapermitida THEN

            RETURN FALSE;

          END IF;

        else
          null;
        END IF;

        IF prubrica.flpagasubstituicao = 'N' AND pfltipoprovimento = 'S' THEN

          RETURN FALSE;

        ELSIF prubrica.flpagarespondendo = 'N' AND pfltipoprovimento = 'R' THEN

          RETURN FALSE;

        else
          null;
        END IF;

      END IF;

    END IF;

    -- Motivos de Movimentacao / Instituto

    -- Alguns motivos/insitutos impedem/permitem a geracao
    -- So e validado para relacao de efetivo a disposicao

    batendeuabrangencia := FALSE;

    IF pcdrelacaotrabalho = pkgpag_tipo.cnreltrabdisposicao THEN

      IF prubrica.lsmovinstituto.count > 0 THEN

        IF prubrica.ingerarubricamotmovi IN ('1', '2') THEN

          FOR i IN pRubrica.lsMovInstituto.FIRST .. pRubrica.lsMovInstituto.LAST LOOP

            IF pRubrica.lsMovInstituto(i).CdMotivoMovimentacao IS NOT NULL AND pRubrica.lsMovInstituto(i).CdInstitutoMovimentacao IS NOT NULL THEN

              IF pCdMotivoMovimentacao = pRubrica.lsMovInstituto(i).CdMotivoMovimentacao AND
                 pCdInstitutoMovimentacao = pRubrica.lsMovInstituto(i).CdInstitutoMovimentacao THEN

                batendeuabrangencia := TRUE;

              END IF;

            ELSIF pRubrica.lsMovInstituto(i).CdMotivoMovimentacao IS NOT NULL THEN

              IF pCdMotivoMovimentacao = pRubrica.lsMovInstituto(i).CdMotivoMovimentacao THEN

                batendeuabrangencia := TRUE;

              END IF;

            ELSIF pRubrica.lsMovInstituto(i).CdInstitutoMovimentacao IS NOT NULL THEN

              IF pCdInstitutoMovimentacao = pRubrica.lsMovInstituto(i).CdInstitutoMovimentacao THEN

                batendeuabrangencia := TRUE;

              END IF;

            else
              null;
            END IF;

          END LOOP;

          -- Se os motivos/institutos impedem

          IF prubrica.ingerarubricamotmovi = '1' AND batendeuabrangencia THEN

            RETURN FALSE;

          ELSIF pRubrica.InGeraRubricaMotMovi = '2' AND
                NOT bAtendeuAbrangencia THEN

            RETURN FALSE;

          else
            null;
          END IF;

        END IF;

      END IF;

    END IF;
    --
    -- Verificar Parametro - Motivos de Afastamento Temporarios Remunerados Exigidos para a Geracao da Rubrica
    --

    IF pRubrica.lsMotAfastTempEx.COUNT > 0 THEN
      FOR i IN pRubrica.lsMotAfastTempEx.FIRST .. pRubrica.lsMotAfastTempEx.LAST LOOP

        CASE
          WHEN pRubrica.lsMotAfastTempEx(i).CdPeriodoAfastamento = 1 THEN
            vnuperiodo := 0;

          WHEN pRubrica.lsMotAfastTempEx(i).CdPeriodoAfastamento = 2 THEN
            vnuperiodo := 1;

          ELSE
            vnuperiodo := prubrica.lsmotafasttempex(i).nuperiodo;

        END CASE;

        IF fdiasafasttemp(pkgpag_var.vgvinculo.cdvinculo,
                          ADD_MONTHS(PKGPAG_VAR.vgFolha.DtInicioMes,
                                     -vNuPeriodo),
                          add_months(pkgpag_var.vgfolha.dtfimmes,
                                     -vnuperiodo),
                          pkgpag_var.vgfolha.dtcalculo,
                          pRubrica.lsMotAfastTempEx(i).cdmotivoafasttemporario) > 0

         THEN

          RETURN TRUE;

        END IF;

      END LOOP;

      RETURN FALSE;

    END IF;

    -- Deve ser aplicada a proporcionalidade dos afastamentos temporarios nao remunerados
    -- ao inves de descontar dias nao trabalhados e ao inves de respeitar a base de calculo ja proporcionalizada
    IF pRubrica.lsMotAfastTempImp.COUNT > 0 AND
       PKGPAG_VAR.vgAfastTempRemun.COUNT > 0 AND
       pRubrica.CdRubricaAgrupamento NOT IN (10453)

     THEN
      --
      -- Para auxilio alimentacao disposicao deve verificar a opcao de recebimento do cadastro
      --
      IF pRubrica.NuRubrica = 157 AND pRubrica.CdTipoRubrica = 1 AND
         pkgpag_var.vgvinculo.cdopcaoauxilioali = 1 THEN

        NULL;

      ELSE

        vNuDiasAfastTemp := 0;

        FOR i IN PKGPAG_VAR.vgAfastTempRemun.FIRST .. PKGPAG_VAR.vgAfastTempRemun.LAST LOOP

          IF pRubrica.lsMotAfastTempImp.exists(PKGPAG_VAR.vgAfastTempRemun(i).CdMotivoAfastamento) then

            --Verifica se os afastamentos s?o ininterruptos, caso n?o seja, come?a a contar novamente.
            IF vDtAfastRemunAnt is not null and
              -- o fim do afastamento anterior n?o pode ser igual que a data inicial do outro afastamento
               (vDtAfastRemunAnt <> PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfa OR
               vDtAfastRemunAnt <> PKGPAG_VAR.vgAfastTempRemun(i).DtInicioAfa - 1) THEN
              vNuDiasAfastTemp := PKGPAG_VAR.vgAfastTempRemun(i).NuDiasAfastMes;
            ELSE
              vNuDiasAfastTemp := vNuDiasAfastTemp + PKGPAG_VAR.vgAfastTempRemun(i).NuDiasAfastMes;
            END IF;

            vDtAfastRemunAnt := PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfa;

            -- CASO O SERVIDOR ESTEJA AFASTADO O MES TODO
            IF vNuDiasAfastTemp >= 30 or
               vNuDiasAfastTemp =
               to_char(pkgpag_var.vgFolha.dtfimmes, 'dd') THEN
              --  Alguns afastamentos impedem a geracao da rubrica.
              IF prubrica.ingerarubricaafasttemp = '1'
                -- Solicitacao de Sustentacao #77638
                -- 10823/2017 - FOLHA - INSALUBRIDADE ORGAO 1301
                -- Verificar excecoes
                 AND NOT fPossuiExcecaoAfast(pkgpag_var.vgVinculo.CdVinculo,
                                             PKGPAG_VAR.vgAfastTempRemun(i).CdMotivoAfastamento,
                                             pRubrica.CdHistRubrica,
                                             pRubrica.NuRubrica) then

                RETURN FALSE;
              END IF;
            end if;

          END IF;

        END LOOP;

      END IF;

    END IF;

    IF pcdprograma IS NOT NULL THEN

      -- Alguns programas impedem a geracao

      IF prubrica.ingerarubricaprograma = '1' THEN

        IF prubrica.lsprograma.exists(pcdprograma) THEN

          RETURN FALSE;

        END IF;

        -- Alguns programas permitem a geracao

      ELSIF prubrica.ingerarubricaprograma = '2' THEN

        IF NOT prubrica.lsprograma.exists(pcdprograma) THEN

          RETURN FALSE;

        END IF;

      else
        null;
      END IF;

    END IF;

    --
    -- Validar parametro Motivos de Convocacao em Relacao a Geracao da Rubrica
    -- SIG-10075 Designacao CTISP - PROGRAMA ESCOLA MAIS SEGURA
    --
    IF pRubrica.lsMotivoConvocacao.count > 0 and
       nvl(pkgpag_var.vgCdMotivoConvocacao,0) <> 0 then

      begin

      if not pRubrica.lsMotivoConvocacao.exists(pkgpag_var.vgCdMotivoConvocacao) then
         return false;
      end if;

      exception
        when others then
          null;
      end;

    END IF;

    RETURN TRUE;

  END;

  /*-----------------------------------------------------------------------------------------
      Funcao: PAtualizaHistCEF
    Objetivo: Insere/Atualiza registro com o valor integral associado a rubrica
  -----------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistcef(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pcef                 IN pkgpag_tipo.rcef,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7) IS

  BEGIN
 
    IF fpossuiabrangenciarubrica(prubrica                  => prubrica,
                                 pcdorgao                  => pkgpag_var.vgcdorgaovinculo,
                                 pcdorgaoexercicio         => pcef.cdorgaoexercicio,
                                 pcdnaturezavinculo        => pcef.cdnaturezavinculo,
                                 pcdrelacaotrabalho        => pcef.cdrelacaotrabalho,
                                 pcdregimetrabalho         => pcef.cdregimetrabalho,
                                 pcdregimeprevidenciario   => pcef.cdregimeprevidenciario,
                                 pcdsituacaoprevidenciaria => pcef.cdsituacaoprevidenciaria,
                                 pcdunidadeorganizacional  => pcef.cdunidadeorganizacional,
                                 pcdestruturacarreira      => pcef.cdestruturacarreira,
                                 pfltipoprovimento         => pcef.flefetivacao,
                                 pcdmotivomovimentacao     => pcef.cdmotivomovimentacao,
                                 pcdinstitutomovimentacao  => pcef.cdinstitutomovimentacao,
                                 pFlExercicioOrigem        => pCEF.FlExercicioOrigem) THEN

      INSERT INTO EPagHistoricoRubricaRelVinc
        (cdhistoricorubricarelvinc,
         cdfolhapagamento,
         cdrubricaagrupamento,
         nusufixorubrica,
         vlintegral,
         vlproporcional,
         vlreal,
         cdvinculo,
         cdhistcargoefetivo,
         cdrelacaovinculo,
         cdchave,
         qtparcelas,
         vlindicerubrica,
         cdtipoorigemrubrica,
         dtinicio,
         dtfim,
         cdtipoindice)
      VALUES
        (SPagHistoricoRubricaRelVinc.NEXTVAL,
         pfolha.cdfolhapagamento,
         prubrica.cdrubricaagrupamento,
         1,
         trunc(pvalorintegral, 2),
         trunc(pvalorproporcional, 2),
         pvalorreal,
         pcef.cdvinculo,
         pcef.cdhistrelvinc,
         1,
         pcef.cdhistrelvinc,
         1,
         pvalorindice,
         pcdtipoorigemrubrica,
         pcef.dtinicio,
         pcef.dtfim,
         prubrica.cdtipoindice);

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      --dbms_output.put_line(SQLERRM);
      null;

  END;

  /*-----------------------------------------------------------------------------------------
    Procedure: PAtualizaHistFUC
     Objetivo:
  -----------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistfuc(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pfuc                 IN pkgpag_tipo.rfuc,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdexpressaoformula  IN INTEGER DEFAULT NULL,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7,
                             pNuSufixoRubrica     IN INTEGER DEFAULT 1) IS

  BEGIN
 
    IF fpossuiabrangenciarubrica(prubrica             => prubrica,
                                 pcdorgao             => pkgpag_var.vgcdorgaovinculo,
                                 pcdorgaoexercicio    => pfuc.cdorgaoexercicio,
                                 pcdfuncaochefia      => pfuc.cdfuncaochefia,
                                 pfltipoprovimento    => pfuc.flefetivacao,
                                 pcdestruturacarreira => pkgpag_var.vgcdestruturacarreira) THEN

      INSERT INTO EPagHistoricoRubricaRelVinc
        (cdhistoricorubricarelvinc,
         cdfolhapagamento,
         cdrubricaagrupamento,
         nusufixorubrica,
         vlintegral,
         vlproporcional,
         vlreal,
         cdvinculo,
         cdhistfuncaochefia,
         cdrelacaovinculo,
         cdchave,
         qtparcelas,
         vlindicerubrica,
         cdexpressaoformcalc,
         cdtipoorigemrubrica,
         dtinicio,
         dtfim,
         cdtipoindice)
      VALUES
        (SPagHistoricoRubricaRelVinc.NEXTVAL,
         pfolha.cdfolhapagamento,
         prubrica.cdrubricaagrupamento,
         pNuSufixoRubrica,
         trunc(pvalorintegral, 2),
         trunc(pvalorproporcional, 2),
         trunc(pvalorreal, 2),
         pfuc.cdvinculo,
         pfuc.cdhistfuncaochefia,
         3,
         pfuc.cdhistfuncaochefia,
         1,
         pvalorindice,
         pcdexpressaoformula,
         pcdtipoorigemrubrica,
         pfuc.dtinicio,
         pfuc.dtfim,
         prubrica.cdtipoindice);

      IF NOT pkgpag_var.bflpossuiproventos THEN

        pkgpag_var.bflpossuiproventos := pvalorproporcional > 0;

      END IF;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      NULL;

  END;

  PROCEDURE patualizahistcco(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pcco                 IN pkgpag_tipo.rcco,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdexpressaoformula  IN INTEGER DEFAULT NULL,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7) IS

    binsere BOOLEAN;

  BEGIN
 
    binsere := FALSE;

    IF pkgpag_geral.fgerarubrica(prubrica.cdrubricaagrupamento) THEN

      IF ((pCCO.CdRelacaoTrabalho IN (4, 6, 13) and
         pCCO.CdOpcaoRemuneracao in (2) and pFolha.CdAgrupamento <> 133) OR
         (pCCO.CdOpcaoRemuneracao = 5 AND pFolha.CdAgrupamento = 134 -- Agrupamento Militar
         )) THEN

        binsere := TRUE;

      ELSE

        bInsere := FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                             pcdorgao                  => pkgpag_var.vgcdorgaovinculo,
                                             pcdorgaoexercicio         => pcco.cdorgaoexercicio,
                                             pcdnaturezavinculo        => pcco.cdnaturezavinculo,
                                             pcdrelacaotrabalho        => pcco.cdrelacaotrabalho,
                                             pcdregimetrabalho         => pcco.cdregimetrabalho,
                                             pcdregimeprevidenciario   => pcco.cdregimeprevidenciario,
                                             pcdsituacaoprevidenciaria => pcco.cdsituacaoprevidenciaria,
                                             pcdcargocomissionado      => pcco.cdcargocomissionado,
                                             pcdgrupoocupacional       => pcco.cdgrupoocupacional,
                                             pcdopcaoremuneracao       => pcco.cdopcaoremuneracao,
                                             pcdunidadeorganizacional  => pcco.cdunidadeorganizacional,
                                             pcdestruturacarreira      => pkgpag_var.vgcdestruturacarreira,
                                             pfltipoprovimento         => pcco.fltipoprovimento);
      END IF;

    END IF;

    IF binsere THEN

      INSERT INTO EPagHistoricoRubricaRelVinc
        (cdhistoricorubricarelvinc,
         cdfolhapagamento,
         cdrubricaagrupamento,
         nusufixorubrica,
         vlintegral,
         vlproporcional,
         vlreal,
         cdvinculo,
         cdhistcargocom,
         cdrelacaovinculo,
         cdchave,
         qtparcelas,
         vlindicerubrica,
         cdexpressaoformcalc,
         cdtipoorigemrubrica,
         dtinicio,
         dtfim,
         cdtipoindice)
      VALUES
        (SPagHistoricoRubricaRelVinc.NEXTVAL,
         pfolha.cdfolhapagamento,
         prubrica.cdrubricaagrupamento,
         1,
         trunc(pvalorintegral, 2),
         trunc(pvalorproporcional, 2),
         trunc(pvalorreal, 2),
         pcco.cdvinculo,
         pcco.cdhistcargocom,
         2,
         pcco.cdhistcargocom,
         1,
         pvalorindice,
         pcdexpressaoformula,
         pcdtipoorigemrubrica,
         pcco.dtinicio,
         pcco.dtfim,
         prubrica.cdtipoindice);

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      --DBMS_OUTPUT.PUT_LINE('Deu pau na insercao CCO SUBST!!!!!');
      NULL;

  END;

  /*-----------------------------------------------------------------------------------------
    Procedure: PAtualizaHistAPO
     Objetivo:
  -----------------------------------------------------------------------------------------*/
  PROCEDURE patualizahistapo(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             papo                 IN pkgpag_tipo.rcef,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7,
                             pcdtipoindice        IN INTEGER DEFAULT NULL) IS

  BEGIN
 
    IF fpossuiabrangenciarubrica(prubrica                  => prubrica,
                                 pcdorgao                  => pkgpag_var.vgcdorgaovinculo,
                                 pcdorgaoexercicio         => papo.cdorgaoexercicio,
                                 pcdsituacaoprevidenciaria => papo.cdsituacaoprevidenciaria,
                                 pcdestruturacarreira      => papo.cdestruturacarreira,
                                 pflapoorigemcco           => papo.florigemcco) THEN

      INSERT INTO EPagHistoricoRubricaRelVinc
        (cdhistoricorubricarelvinc,
         cdfolhapagamento,
         cdrubricaagrupamento,
         nusufixorubrica,
         vlintegral,
         vlproporcional,
         vlreal,
         cdvinculo,
         cdconcessaoaposentadoria,
         cdrelacaovinculo,
         cdchave,
         qtparcelas,
         vlindicerubrica,
         cdtipoorigemrubrica,
         dtinicio,
         dtfim,
         cdtipoindice)
      VALUES
        (SPagHistoricoRubricaRelVinc.NEXTVAL,
         pfolha.cdfolhapagamento,
         prubrica.cdrubricaagrupamento,
         1,
         trunc(pvalorintegral, 2),
         trunc(pvalorproporcional, 2),
         trunc(pvalorreal, 2),
         papo.cdvinculo,
         papo.cdhistrelvinc,
         4,
         papo.cdhistrelvinc,
         1,
         pvalorindice,
         pcdtipoorigemrubrica,
         papo.dtinicio,
         papo.dtfim,
         nvl(pcdtipoindice, prubrica.cdtipoindice));

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      NULL;

  END;

  /*-----------------------------------------------------------------------------------------
    Procedure: PAtualizaHistBOL
     Objetivo:
  -----------------------------------------------------------------------------------------*/

  PROCEDURE patualizahistbol(pfolha               IN pkgpag_tipo.rfolha,
                             prubrica             IN pkgpag_tipo.rrubrica,
                             pbol                 IN pkgpag_tipo.rbol,
                             pvalorintegral       IN NUMBER,
                             pvalorproporcional   IN NUMBER,
                             pvalorreal           IN NUMBER,
                             pvalorindice         IN NUMBER,
                             pcdtipoorigemrubrica IN INTEGER DEFAULT 7) IS

  BEGIN
 
    IF fpossuiabrangenciarubrica(prubrica                  => prubrica,
                                 pcdorgao                  => pkgpag_var.vgcdorgaovinculo,
                                 pcdorgaoexercicio         => pbol.cdorgaoexercicio,
                                 pcdnaturezavinculo        => pbol.cdnaturezavinculo,
                                 pcdrelacaotrabalho        => pbol.cdrelacaotrabalho,
                                 pcdregimetrabalho         => pbol.cdregimetrabalho,
                                 pcdregimeprevidenciario   => pbol.cdregimeprevidenciario,
                                 pcdsituacaoprevidenciaria => pbol.cdsituacaoprevidenciaria,
                                 pcdprograma               => pbol.cdprograma) THEN

      INSERT INTO EPagHistoricoRubricaRelVinc
        (cdhistoricorubricarelvinc,
         cdfolhapagamento,
         cdrubricaagrupamento,
         nusufixorubrica,
         vlintegral,
         vlproporcional,
         vlreal,
         cdvinculo,
         cdhistestagio,
         cdrelacaovinculo,
         cdchave,
         qtparcelas,
         vlindicerubrica,
         cdtipoorigemrubrica,
         cdtipoindice)
      VALUES
        (SPagHistoricoRubricaRelVinc.NEXTVAL,
         pfolha.cdfolhapagamento,
         prubrica.cdrubricaagrupamento,
         1,
         trunc(pvalorintegral, 2),
         trunc(pvalorproporcional, 2),
         trunc(pvalorreal, 2),
         pbol.cdvinculoestagio,
         pbol.cdhistestagio,
         5,
         pbol.cdhistestagio,
         1,
         pvalorindice,
         pcdtipoorigemrubrica,
         prubrica.cdtipoindice);

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      NULL;

  END;

  /*-----------------------------------------------------------------------------------------
    Function: FIdentificaFormulaCalculo

    Objetivo: Identificao da formula de calculo

        Nota:  Busca a formula de calculo obedecendo o seguinte criterio:
              1) Busca uma formula especifica
              2) Busca a formula associada e unidade org. do local de trabalho.
              3) Busca a formula da estrutura de carreira do cargo efetivo.
              4) Busca a formula na hierarquia das estruturas de carreira.
              5) Busca a formula geral.

    Argumentos:

  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fidentificaformulacalculo(pformexpr                IN pkgpag_tipo.tformulacalculo,
                                     pcdrubricaagrupamento    IN INTEGER,
                                     pcdrelacaovinculo        IN INTEGER,
                                     pcdestruturacarreira     IN INTEGER DEFAULT NULL,
                                     pcdcargocomissionado     IN INTEGER DEFAULT NULL,
                                     pcdfuncaochefia          IN INTEGER DEFAULT NULL,
                                     pcdunidadeorganizacional IN INTEGER DEFAULT NULL,
                                     pnuformulaespecifica     IN INTEGER DEFAULT NULL)

   RETURN INTEGER IS

    vcdestrutura INTEGER;

  BEGIN
 
    IF pnuformulaespecifica IS NOT NULL THEN

      FOR i IN pFormExpr.FIRST .. pFormExpr.LAST LOOP

        IF pformexpr.exists(i) THEN

          IF pFormExpr(i).CdRubricaAgrupamento = pCdRubricaAgrupamento AND pFormExpr(i)
             .NuFormulaEspecifica = pNuFormulaEspecifica THEN

            RETURN pformexpr(i).cdexpressaoformcalc;

          END IF;

        END IF;

      END LOOP;

      -- Caso nao tenha encontrado a formula especifica, retorna 0

      RETURN 0;

    END IF;

    -- Busca formula na Unidade se as relacoes de vinculo forem de CEF, CCO e FUC

    IF pcdrelacaovinculo IN (1, 2, 3) THEN

      FOR i IN pFormExpr.FIRST .. pFormExpr.LAST LOOP

        IF pformexpr.exists(i) THEN

          IF pFormExpr(i).CdRubricaAgrupamento = pCdRubricaAgrupamento AND pFormExpr(i)
             .CdUnidadeOrganizacional = pCdUnidadeOrganizacional THEN

            RETURN pformexpr(i).cdexpressaoformcalc;

          END IF;

        END IF;

      END LOOP;

    END IF;

    -- Busca formula para Cargos efetivos

    IF pcdrelacaovinculo IN (0, 1, 4) AND pcdestruturacarreira IS NOT NULL THEN

      -- Busca a formula na hierarquia das estruturas de carreira.

      vcdestrutura := fexistecarreira(pcdestruturacarreira);

      WHILE vcdestrutura IS NOT NULL LOOP

        FOR i IN pFormExpr.FIRST .. pFormExpr.LAST LOOP

          IF pformexpr.exists(i) THEN

            IF pFormExpr(pFormExpr(i).CdExpressaoFormCalc)
             .CdRubricaAgrupamento = pCdRubricaAgrupamento AND pFormExpr(pFormExpr(i).CdExpressaoFormCalc)
               .CdEstruturaCarreira = vCdEstrutura THEN

              RETURN pformexpr(i).cdexpressaoformcalc;

            END IF;

          END IF;

        END LOOP;

        vcdestrutura := fproxcarreira(vcdestrutura);

      END LOOP;

    END IF;

    -- Busca formula para CCO

    IF pcdrelacaovinculo = 2 THEN

      FOR i IN pFormExpr.FIRST .. pFormExpr.LAST LOOP

        IF pformexpr.exists(i) THEN

          IF pFormExpr(pFormExpr(i).CdExpressaoFormCalc)
           .CdRubricaAgrupamento = pCdRubricaAgrupamento AND pFormExpr(pFormExpr(i).CdExpressaoFormCalc)
             .CdCargoComissionado = pCdCargoComissionado THEN

            RETURN pformexpr(i).cdexpressaoformcalc;

          END IF;

        END IF;

      END LOOP;

    END IF;

    -- Busca formula GERAL

    FOR i IN pFormExpr.FIRST .. pFormExpr.LAST LOOP

      IF pformexpr.exists(i) THEN

        IF pFormExpr(pFormExpr(i).CdExpressaoFormCalc)
         .CdRubricaAgrupamento = pCdRubricaAgrupamento AND pFormExpr(pFormExpr(i).CdExpressaoFormCalc).FlExpGeral = 'S' THEN

          RETURN pformexpr(i).cdexpressaoformcalc;

        END IF;

      END IF;

    END LOOP;

    RETURN 0;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END fidentificaformulacalculo;

  /*-----------------------------------------------------------------------------------------
    Procedure: PInsereLancamentoVinculo
     Objetivo:
  -----------------------------------------------------------------------------------------*/

  PROCEDURE pinserelancamentovinculo(pcdfolhapagamento            IN INTEGER,
                                     pcdvinculo                   IN INTEGER,
                                     pcdexpressaoformcalc         IN INTEGER,
                                     pcdrubricaagrupamento        IN INTEGER,
                                     pnusufixorubrica             IN INTEGER,
                                     pvlpagamento                 IN NUMBER,
                                     pvlindice                    IN NUMBER DEFAULT NULL,
                                     pnuparcelas                  IN INTEGER DEFAULT NULL,
                                     pcdbaseconsignacao           IN INTEGER DEFAULT NULL,
                                     pcdtipoorigemrubrica         IN INTEGER DEFAULT 1,
                                     pcdlancamentofinanceiro      IN INTEGER DEFAULT NULL,
                                     pdeprocessoretroativo        IN VARCHAR2 DEFAULT NULL,
                                     pvlrestituir                 IN NUMBER DEFAULT NULL,
                                     pvlindicenmrra               IN NUMBER DEFAULT NULL,
                                     pcdtipoindice                IN NUMBER DEFAULT NULL,
                                     pdeindicecontracheque        IN VARCHAR2 DEFAULT NULL,
                                     pcdprocessopagretroativo     IN INTEGER DEFAULT NULL,
                                     pcdhistsentencajudicial      IN INTEGER DEFAULT NULL,
                                     pnuanomesorigem              IN INTEGER DEFAULT NULL,
                                     pCdProcessoRestituicaoErario IN INTEGER DEFAULT NULL,
                                     pDeExpressao                 IN VARCHAR2 DEFAULT NULL) IS

    vcdtipoindice INTEGER;

  BEGIN
 
    IF pcdrubricaagrupamento IS NULL THEN

      pInsereLog(PKGPAG_VAR.bLog,
                 PKGPAG_VAR.vCdHistParamCalc,
                 pkgpag_var.vgvinculo.cdpessoa,
                 'Erro ao inserir registro no contra-cheque: pcdrubricaagrupamento IS NULL',
                 pkgpag_var.vgvinculo.cdvinculo,
                 2);

      RETURN;

    END IF;

    if pcdrubricaagrupamento = 0 then

      return;

    end if;

    vcdtipoindice := NULL;

    IF pcdtipoindice IS NULL THEN

      vCdTipoIndice := PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).CdTipoIndice;

    ELSE

      vcdtipoindice := pcdtipoindice;

    END IF;

    INSERT INTO EPagHistoricoRubricaVinculo
      (cdhistoricorubricavinculo,
       cdfolhapagamento,
       cdrubricaagrupamento,
       cdvinculo,
       nusufixorubrica,
       vlpagamento,
       vlindicerubrica,
       cdexpressaoformcalc,
       qtparcelas,
       cdbaseconsignacao,
       cdtipoorigemrubrica,
       cdlancamentofinanceiro,
       deprocessoretroativo,
       vlmontanteretroativo,
       vlindicenmrra,
       cdtipoindice,
       deindicecontracheque,
       cdprocessopagretroativo,
       cdhistsentencajudicial,
       nuanomesorigem,
       CdProcessoRestituicaoErario,
       DeExpressao)

    VALUES
      (sPagHistoricoRubricaVinculo.NEXTVAL,
       pcdfolhapagamento,
       pcdrubricaagrupamento,
       pcdvinculo,
       pnusufixorubrica,
       trunc(pvlpagamento, 2),
       pvlindice,
       pcdexpressaoformcalc,
       pnuparcelas,
       pcdbaseconsignacao,
       pcdtipoorigemrubrica,
       pcdlancamentofinanceiro,
       pdeprocessoretroativo,
       pvlrestituir,
       pvlindicenmrra,
       vcdtipoindice,
       pdeindicecontracheque,
       pcdprocessopagretroativo,
       pcdhistsentencajudicial,
       pnuanomesorigem,
       pCdProcessoRestituicaoErario,
       pDeExpressao);

  EXCEPTION

    WHEN OTHERS THEN

      pInsereLog(PKGPAG_VAR.bLog,
                 PKGPAG_VAR.vCdHistParamCalc,
                 pkgpag_var.vgvinculo.cdpessoa,
                 'Erro ao inserir registro no contra-cheque: ' || SQLERRM ||
                 ' - ' || pCdRubricaAgrupamento,
                 pkgpag_var.vgvinculo.cdvinculo);

  END;

  /*-----------------------------------------------------------------------------------------
    Procedure: PInsereLancamentoRelacao
     Objetivo:
  -----------------------------------------------------------------------------------------*/

  PROCEDURE pinserelancamentorelacao(pcdfolhapagamento            IN INTEGER,
                                     pcdvinculo                   IN INTEGER,
                                     pcdrelacaovinculo            IN INTEGER,
                                     pcdhistrelacaovinculo        IN INTEGER,
                                     pcdexpressaoformcalc         IN INTEGER,
                                     pcdrubricaagrupamento        IN INTEGER,
                                     pvlintegral                  IN NUMBER,
                                     pvlproporcional              IN NUMBER,
                                     pnusufixorubrica             IN INTEGER,
                                     pnuparcelas                  IN INTEGER DEFAULT NULL,
                                     pvlindice                    IN NUMBER DEFAULT NULL,
                                     pdtiniciorelacao             IN DATE DEFAULT NULL,
                                     pdtdesligamento              IN DATE DEFAULT NULL,
                                     pcdunidadeorganizacional     IN INTEGER DEFAULT NULL,
                                     pcdvantagempecuniaria        IN INTEGER DEFAULT NULL,
                                     pcdrubtotvantagem            IN INTEGER DEFAULT NULL,
                                     pcdincorporacaoativo         IN INTEGER DEFAULT NULL,
                                     pcdlancamentofinanceiro      IN INTEGER DEFAULT NULL,
                                     pvlminrecebincorp            IN NUMBER DEFAULT NULL,
                                     pflatualizacaoconstante      IN CHAR DEFAULT NULL,
                                     pflvigenciapagamento         IN CHAR DEFAULT NULL,
                                     pcdtipoorigemrubrica         IN INTEGER DEFAULT NULL,
                                     pdtinicio                    IN DATE DEFAULT NULL,
                                     pdtfim                       IN DATE DEFAULT NULL,
                                     pvlreal                      IN NUMBER DEFAULT NULL,
                                     pdescritivo                  IN VARCHAR2 DEFAULT NULL,
                                     pvlindicereal                IN NUMBER DEFAULT NULL,
                                     pcdtipoindice                IN NUMBER DEFAULT NULL,
                                     pdeindicecontracheque        IN VARCHAR2 DEFAULT NULL,
                                     pcdprocessopagretroativo     IN INTEGER DEFAULT NULL,
                                     pcdhistsentencajudicial      IN INTEGER DEFAULT NULL,
                                     pnuanomesorigem              IN INTEGER DEFAULT NULL,
                                     pCdProcessoRestituicaoErario IN INTEGER DEFAULT NULL) IS
    vinsert VARCHAR2(800);
    vvalues VARCHAR2(800);
    vsql    VARCHAR2(2000);

    vcdtipoindice INTEGER;

  BEGIN
 
    IF pcdrubricaagrupamento IS NULL THEN

      pInsereLog(PKGPAG_VAR.bLog,
                 PKGPAG_VAR.vCdHistParamCalc,
                 pkgpag_var.vgvinculo.cdpessoa,
                 'Erro ao inserir registro no contra-cheque da rela??o de v?nculo: pcdrubricaagrupamento IS NULL',
                 pkgpag_var.vgvinculo.cdvinculo,
                 2);

      RETURN;

    END IF;

    if pcdrubricaagrupamento = 0 then

      return;

    end if;

    vcdtipoindice := NULL;

    IF pcdtipoindice IS NULL THEN

      vCdTipoIndice := PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).CdTipoIndice;

    ELSE

      vcdtipoindice := pcdtipoindice;

    END IF;

    vInsert := 'INSERT ' || 'INTO EPagHistoricoRubricaRelVinc' ||
               '    (CdHistoricoRubricaRelVinc,' || 'CdFolhaPagamento,' ||
               'CdRubricaAgrupamento,' || 'CdRelacaoVinculo,' ||
               'CdVinculo,';

    vValues := ' VALUES ' || '(SPagHistoricoRubricaRelVinc.NEXTVAL,' ||
               ':pCdFolhaPagamento,' || ':pCdRubricaAgrupamento,' ||
               ':pCdRelacaoVinculo,' || ':pCdVinculo,' ||
               ':pCdHistRelacaoVinculo,' || ':pCdChave,' ||
               ':pNuSufixoRubrica,' || ':pVlIntegral,' ||
               ':pVlProporcional,' || ':pQtParcelas,' ||
               ':pVlIndiceRubrica,' || ':pCdExpressaoFormCalc,' ||
               ':pCdVantagemPecuniaria,' ||
               ':pCdRubricaTotalizadoraVantagem,' ||
               ':pCdIncorporacaoAtivo,' || ':pVlMinRecebIncorp,' ||
               ':pFlAtualizacaoConstante,' || ':pFlVigenciaPagamento,' ||
               ':pCdLancamentoFinanceiro,' || ':pDtInicioRelacao,' ||
               ':pDtDesligamento,' || ':pCdUnidadeOrganizacional,' ||
               ':pCdTipoOrigemRubrica,' || ':pDtInicio,' || ':pDtFim,' ||
               ':pVlReal,' || ':pDescritivo,' || ':pVlIndiceReal,' ||
               ':pCdTipoIndice,' || ':pDeIndiceContraCheque,' ||
               ':pCdProcessoPagRetroativo,' || ':pCdHistSentencaJudicial,' ||
               ':pNuAnoMesOrigem,' || ':pCdProcessoRestituicaoErario)';

    CASE pcdrelacaovinculo

      WHEN 1 THEN

        vinsert := vinsert || 'CdHistCargoEfetivo,';

      WHEN 2 THEN

        vinsert := vinsert || 'CdHistCargoCom,';

      WHEN 3 THEN

        vinsert := vinsert || 'CdHistFuncaoChefia,';

      WHEN 4 THEN

        vinsert := vinsert || 'CdConcessaoAposentadoria,';

      WHEN 5 THEN

        vinsert := vinsert || 'CdHistEstagio,';

      WHEN 6 THEN

        vinsert := vinsert || 'CdHistPensaoPrevidenciaria,';

      WHEN 7 THEN

        vinsert := vinsert || 'CdHistPensaoNaoPrev,';

      WHEN 8 THEN

        vinsert := vinsert || 'CdHistPensaoExParlamentar,';

      WHEN 9 THEN

        vinsert := vinsert || 'CdAuxilioReclusao,';

      ELSE

        NULL;

    END CASE;

    vInsert := vInsert || 'CdChave,' || 'NuSufixoRubrica,' || 'VlIntegral,' ||
               'VlProporcional,' || 'QtParcelas,' || 'VlIndiceRubrica,' ||
               'CdExpressaoFormCalc,' || 'CdVantagemPecuniaria,' ||
               'CdRubricaTotalizadoraVantagem,' || 'CdIncorporacaoAtivo,' ||
               'VlMinRecebIncorp,' || 'FlAtualizacaoConstante,' ||
               'FlVigenciaPagamento,' || 'CdLancamentoFinanceiro,' ||
               'DtInicioRelacao,' || 'DtDesligamento,' ||
               'CdUnidadeOrganizacional,' || 'CdTipoOrigemRubrica,' ||
               'DtInicio,' || 'DtFim,' || 'VlReal,' || 'DeExpressao,' ||
               'VlIndiceReal,' || 'CdTipoIndice,' ||
               'DeIndiceContraCheque,' || 'CdProcessoPagRetroativo,' ||
               'CdHistSentencaJudicial,' || 'NuAnoMesOrigem,' ||
               'CdProcessoRestituicaoErario)';

    vsql := vinsert || vvalues;

    EXECUTE IMMEDIATE vSQL
      USING pCdFolhaPagamento, pCdRubricaAgrupamento, pCdRelacaoVinculo, pCdVinculo, pCdHistRelacaoVinculo, pCdHistRelacaoVinculo, pNuSufixoRubrica, TRUNC(pVlIntegral, 2), TRUNC(pVlProporcional, 2), pNuParcelas, pvlIndice, pCdExpressaoFormCalc, pCdVantagemPecuniaria, pCdRubTotVantagem, pCdIncorporacaoAtivo, pVlMinRecebIncorp, pFlAtualizacaoConstante, pFlVigenciaPagamento, pCdLancamentoFinanceiro, pDtInicioRelacao, pDtDesligamento, pCdUnidadeOrganizacional, pCdTipoOrigemRubrica, pDtInicio, pDtFim, NVL(pVlReal, TRUNC(pVlProporcional, 2)), substr(pDescritivo, 1, 200), pVlIndiceReal, vCdTipoIndice, pDeIndiceContraCheque, pCdProcessoPagRetroativo, pCdHistSentencaJudicial, pNuAnoMesOrigem, pCdProcessoRestituicaoErario;

  EXCEPTION

    WHEN OTHERS THEN

      pInsereLog(PKGPAG_VAR.bLog,
                 PKGPAG_VAR.vCdHistParamCalc,
                 pkgpag_var.vcdpessoa,
                 'CdRubricaAgrupamento: ' || pCdRubricaAgrupamento ||
                 'Erro ao inserir registro no contra-cheque da rela??o de v?nculo:  ' ||
                 SQLERRM,
                 PKGPAG_VAR.vgCdVinculo);

  END pinserelancamentorelacao;

  -- POG: CHAMADO #64988 - 8035/2016 - FOLHA - TRIBUTACAO DO IPREV DA FUNCIONALIDADE DE RETENCAO DE IPREV DE OUTROS AGRUPAMENTOS
  -- BUSCAR BASE DO IPREV PARA COMISSIONADOS A DISPOSICAO
  -- QUE APRESENTAM LANCAMENTO FINANCEIRO ZERADO NA 01-0001, ORIGINADO DO CAMPO "Base de contribuicao do IPREV"
  -- DA TELA "Alterar Designacao/Nomeacao de Comissionado em Vinculo Existente"
  FUNCTION fvlbaseiprevcomissionadoadisp(pfolha     IN pkgpag_tipo.rfolha,
                                         pcdvinculo IN INTEGER) RETURN NUMBER IS

    vvlbaseiprevcomissionadoadisp NUMBER(13, 2);

  BEGIN
 
    SELECT lf.vlintegraliprev
      INTO vvlbaseiprevcomissionadoadisp
      FROM emovservidorrecebido sr
     INNER JOIN ecadvinculo v
        ON v.cdvinculo = sr.cdvinculo
     INNER JOIN epaglancamentofinanceiro lf
        ON lf.cdvinculo = sr.cdvinculo
     WHERE sr.cdorgaorecebimento = pfolha.cdorgao
       AND sr.cdvinculo = pcdvinculo
       AND sr.dtapresentacao <= pfolha.dtfimmes
       AND (sr.dtfimdisposicao IS NULL OR
           sr.dtfimdisposicao >= pfolha.dtiniciomes)
       AND v.cdregimeprevidenciario = pkgpag_tipo.cnregprevproprio -- 2
       AND lf.cdrubricaagrupamento = pkgpag_var.vgcdrubagrup1001 -- 8451
       AND lf.dtfimdireito IS NULL
       AND lf.flautomatico = 'S'
       AND lf.flanulado = 'N'
       AND lf.cdrubricaagrupamento IN
           (SELECT ra.cdrubricaagrupamento
              FROM vpagrubricaagrupamento ra
             WHERE ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
               AND ra.flsuspensa = pkgpag_tipo.cnn)
       AND rownum < 2;

    RETURN vvlbaseiprevcomissionadoadisp;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fgerarubricastotalizRelVinc(pfolha     IN pkgpag_tipo.rfolha,
                                       pCdVinculo IN INTEGER) RETURN BOOLEAN IS

    bgeroutotalizadoras BOOLEAN DEFAULT FALSE;


    bpassou29677 BOOLEAN;

    bpassou29637 BOOLEAN;

    vVlBaseIPREVComissionadoADisp NUMBER(13, 2);

    vvlpagamento pkgpag_tipo.rvalorpagamento;

    vVlDecisaoJudicial NUMBER(13, 2);

    vCdDecisao INTEGER;

    vDtIniDecJud DATE;

    vDtFimDecJuc DATE;

    bvlceffixonulo BOOLEAN;

    CURSOR cgerarubtotalrv IS
      SELECT DISTINCT HRV.CdVinculo,
                      CASE
                        WHEN cdhistcargoefetivo IS NOT NULL THEN
                         1
                        WHEN cdhistcargocom IS NOT NULL THEN
                         2
                        WHEN cdhistfuncaochefia IS NOT NULL THEN
                         3
                        WHEN cdconcessaoaposentadoria IS NOT NULL THEN
                         4
                        WHEN cdhistestagio IS NOT NULL THEN
                         5
                        WHEN cdhistpensaoprevidenciaria IS NOT NULL THEN
                         6
                        WHEN cdhistpensaonaoprev IS NOT NULL THEN
                         7
                        WHEN cdhistpensaoexparlamentar IS NOT NULL THEN
                         8
                        ELSE
                         9
                      END AS cdrelacaovinculo,
                      hrv.cdhistcargoefetivo,
                      hrv.cdhistcargocom,
                      hrv.cdhistestagio,
                      hrv.cdhistfuncaochefia,
                      hrv.cdhistauxilioreclusao,
                      hrv.cdhistpensaoexparlamentar,
                      hrv.cdhistpensaonaoprev,
                      hrv.cdhistpensaoprevidenciaria,
                      hrv.cdconcessaoaposentadoria,
                      r.cdrubricaagrupamento,
                      r.cdmodalidaderubrica,
                      hrv.cdchave
        FROM epaghistoricorubricarelvinc hrv
       CROSS JOIN (SELECT RA.CdRubricaAgrupamento, RA.CdModalidadeRubrica
                     FROM epagrubricaagrupamento ra
                    INNER JOIN epagbasecalculo bc
                       on BC.CdBaseCalculo = RA.CdBaseCalculo
                      AND BC.CdAgrupamento = pFolha.CdAgrupamento
                    INNER JOIN epaghistrubricaagrupamento hra
                       ON ra.cdrubricaagrupamento = hra.cdrubricaagrupamento
                     LEFT JOIN epagmodalidaderubrica mr
                       ON mr.cdmodalidaderubrica = ra.cdmodalidaderubrica
                    WHERE ((hra.nuanoiniciovigencia < pfolha.nuanoreferencia OR
                          (HRA.NuAnoInicioVigencia =
                          pFolha.NuAnoReferencia AND
                          HRA.NuMesInicioVigencia <=
                          pFolha.NuMesReferencia)) AND
                          (hra.nuanofimvigencia > pfolha.nuanoreferencia OR
                          (hra.nuanofimvigencia = pfolha.nuanoreferencia AND
                          hra.numesfimvigencia >= pfolha.numesreferencia) OR
                          HRA.NuAnoFimVigencia IS NULL))
                      AND RA.CdAgrupamento = pFolha.CdAgrupamento
                      AND (MR.FlAutomatico = PKGPAG_TIPO.cnN OR
                          RA.CdModalidadeRubrica IS NULL)) R
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND (HRV.CdVinculo = pCdVinculo);
    
    PROCEDURE pinsereregistro(pcdfolhapagamento           IN INTEGER,
                              pcdrubricaagrupamento       IN INTEGER,
                              pcdvinculo                  IN INTEGER,
                              pcdrelacaovinculo           IN INTEGER,
                              pcdhistcargoefetivo         IN INTEGER,
                              pcdhistcargocom             IN INTEGER,
                              pcdhistestagio              IN INTEGER,
                              pcdhistfuncaochefia         IN INTEGER,
                              pcdhistauxilioreclusao      IN INTEGER,
                              pcdhistpensaoexparlamentar  IN INTEGER,
                              pcdhistpensaonaoprev        IN INTEGER,
                              pcdhistpensaoprevidenciaria IN INTEGER,
                              pcdconcessaoaposentadoria   IN INTEGER,
                              pcdchave                    IN INTEGER) IS

    BEGIN
 
      INSERT INTO EPagHistoricoRubricaRelVinc
        (cdhistoricorubricarelvinc,
         cdfolhapagamento,
         cdrubricaagrupamento,
         nusufixorubrica,
         vlintegral,
         vlproporcional,
         cdvinculo,
         cdrelacaovinculo,
         cdhistcargoefetivo,
         cdhistcargocom,
         cdhistestagio,
         cdhistfuncaochefia,
         cdhistauxilioreclusao,
         cdhistpensaoexparlamentar,
         cdhistpensaonaoprev,
         cdhistpensaoprevidenciaria,
         cdconcessaoaposentadoria,
         qtparcelas,
         vlindicerubrica,
         cdchave,
         cdtipoorigemrubrica)
      VALUES
        (SPagHistoricoRubricaRelVinc.NEXTVAL,
         pcdfolhapagamento,
         pcdrubricaagrupamento,
         1,
         NULL,
         NULL,
         pcdvinculo,
         pcdrelacaovinculo,
         pcdhistcargoefetivo,
         pcdhistcargocom,
         pcdhistestagio,
         pcdhistfuncaochefia,
         pcdhistauxilioreclusao,
         pcdhistpensaoexparlamentar,
         pcdhistpensaonaoprev,
         pcdhistpensaoprevidenciaria,
         pcdconcessaoaposentadoria,
         1,
         NULL,
         pcdchave,
         1);

    EXCEPTION

      WHEN OTHERS THEN

        pInsereLog(PKGPAG_VAR.bLog,
                   PKGPAG_VAR.vCdHistParamCalc,
                   pkgpag_var.vcdpessoa,
                   'Erro ao inserir registro de rubrica totalizadora: ' ||
                   SQLERRM,
                   PKGPAG_VAR.vgCdVinculo);

    END;

    PROCEDURE xx(pcdfolhapagamento           IN INTEGER,
                 pcdrubricaagrupamento       IN INTEGER,
                 pcdvinculo                  IN INTEGER,
                 pcdrelacaovinculo           IN INTEGER,
                 pcdhistcargoefetivo         IN INTEGER,
                 pcdhistcargocom             IN INTEGER,
                 pcdhistestagio              IN INTEGER,
                 pcdhistfuncaochefia         IN INTEGER,
                 pcdhistauxilioreclusao      IN INTEGER,
                 pcdhistpensaoexparlamentar  IN INTEGER,
                 pcdhistpensaonaoprev        IN INTEGER,
                 pcdhistpensaoprevidenciaria IN INTEGER,
                 pcdconcessaoaposentadoria   IN INTEGER,
                 pcdchave                    IN INTEGER) IS

    BEGIN
 
      IF pkgpag_var.vgcef.count > 0 THEN

        IF NOT (pkgpag_var.vgcef(1).cdestruturacarreira = 76233) THEN

          pinsereregistro(pcdfolhapagamento           => pcdfolhapagamento,
                          pcdrubricaagrupamento       => pcdrubricaagrupamento,
                          pcdvinculo                  => pcdvinculo,
                          pcdrelacaovinculo           => pcdrelacaovinculo,
                          pcdhistcargoefetivo         => pcdhistcargoefetivo,
                          pcdhistcargocom             => pcdhistcargocom,
                          pcdhistestagio              => pcdhistestagio,
                          pcdhistfuncaochefia         => pcdhistfuncaochefia,
                          pcdhistauxilioreclusao      => pcdhistauxilioreclusao,
                          pcdhistpensaoexparlamentar  => pcdhistpensaoexparlamentar,
                          pcdhistpensaonaoprev        => pcdhistpensaonaoprev,
                          pcdhistpensaoprevidenciaria => pcdhistpensaoprevidenciaria,
                          pcdconcessaoaposentadoria   => pcdconcessaoaposentadoria,
                          pcdchave                    => pcdchave);

        END IF;

      ELSIF pkgpag_var.vgapo.count > 0 THEN

        IF NOT (pkgpag_var.vgapo(1).cdestruturacarreira = 76233) THEN

          pinsereregistro(pcdfolhapagamento           => pcdfolhapagamento,
                          pcdrubricaagrupamento       => pcdrubricaagrupamento,
                          pcdvinculo                  => pcdvinculo,
                          pcdrelacaovinculo           => pcdrelacaovinculo,
                          pcdhistcargoefetivo         => pcdhistcargoefetivo,
                          pcdhistcargocom             => pcdhistcargocom,
                          pcdhistestagio              => pcdhistestagio,
                          pcdhistfuncaochefia         => pcdhistfuncaochefia,
                          pcdhistauxilioreclusao      => pcdhistauxilioreclusao,
                          pcdhistpensaoexparlamentar  => pcdhistpensaoexparlamentar,
                          pcdhistpensaonaoprev        => pcdhistpensaonaoprev,
                          pcdhistpensaoprevidenciaria => pcdhistpensaoprevidenciaria,
                          pcdconcessaoaposentadoria   => pcdconcessaoaposentadoria,
                          pcdchave                    => pcdchave);

        END IF;

      ELSIF pkgpag_var.vgcco.count > 0 THEN

        pinsereregistro(pcdfolhapagamento           => pcdfolhapagamento,
                        pcdrubricaagrupamento       => pcdrubricaagrupamento,
                        pcdvinculo                  => pcdvinculo,
                        pcdrelacaovinculo           => pcdrelacaovinculo,
                        pcdhistcargoefetivo         => pcdhistcargoefetivo,
                        pcdhistcargocom             => pcdhistcargocom,
                        pcdhistestagio              => pcdhistestagio,
                        pcdhistfuncaochefia         => pcdhistfuncaochefia,
                        pcdhistauxilioreclusao      => pcdhistauxilioreclusao,
                        pcdhistpensaoexparlamentar  => pcdhistpensaoexparlamentar,
                        pcdhistpensaonaoprev        => pcdhistpensaonaoprev,
                        pcdhistpensaoprevidenciaria => pcdhistpensaoprevidenciaria,
                        pcdconcessaoaposentadoria   => pcdconcessaoaposentadoria,
                        pcdchave                    => pcdchave);

      ELSIF pkgpag_var.vgccosubst.count > 0 THEN

        pinsereregistro(pcdfolhapagamento           => pcdfolhapagamento,
                        pcdrubricaagrupamento       => pcdrubricaagrupamento,
                        pcdvinculo                  => pcdvinculo,
                        pcdrelacaovinculo           => pcdrelacaovinculo,
                        pcdhistcargoefetivo         => pcdhistcargoefetivo,
                        pcdhistcargocom             => pcdhistcargocom,
                        pcdhistestagio              => pcdhistestagio,
                        pcdhistfuncaochefia         => pcdhistfuncaochefia,
                        pcdhistauxilioreclusao      => pcdhistauxilioreclusao,
                        pcdhistpensaoexparlamentar  => pcdhistpensaoexparlamentar,
                        pcdhistpensaonaoprev        => pcdhistpensaonaoprev,
                        pcdhistpensaoprevidenciaria => pcdhistpensaoprevidenciaria,
                        pcdconcessaoaposentadoria   => pcdconcessaoaposentadoria,
                        pcdchave                    => pcdchave);

      else
        null;
      END IF;

    END;

  BEGIN
 
    IF pFolha.CdTipoFolha NOT IN
       (PKGPAG_TIPO.cnTpFolha13,
        PKGPAG_TIPO.cnTpFolhaAdiant13,
        pkgpag_tipo.cntpfolharesidente13,
        pkgpag_tipo.cnTpFolhaCtisp13,
        pkgpag_tipo.cnTpFolhaAdiant13Ctisp) AND
       pfolha.cdtipocalculo <> pkgpag_tipo.cntpcalculosupl THEN

      bpassou29677 := FALSE;

      bpassou29637 := FALSE;

      FOR rGeraRubTotalRV IN cGeraRubTotalRV LOOP

        bgeroutotalizadoras := TRUE;

        /* Obs: gera a base do IPESC e de Contribuicao de plano de saude para o cargos efetivos e
        aposentadoria desde que esta relacao tenha iniciado no mes de processamento e apos o dia 1?

        gera a rubrica de provisao de ferias para as relacoes de CEF, CCO, e FUC*/
        --
        -- 7588/2015 - FOLHA - BASE SC SAUDE
        -- NAO GERAR AS BASES DO SC SAUDE 09-0937 E 09-0938 PARA VINCULOS DE ACT.
        --

        -- POG para gerar 09-0916 na 801 para quem tem subsidio e não tem 01-0001
        bvlceffixonulo := FALSE;

        IF rGeraRubTotalRV.Cdrubricaagrupamento IN (9561, 11120) AND
          --pFolha.CdOrgao = 14 AND
           pFolha.CdAgrupamento = 1 AND
           (nvl(PKGPAG_VAR.vgValorFixoCEF.vlFixo, 0) = 0) AND
           rGeraRubTotalRV.Cdrelacaovinculo IN (1, 4) THEN
          bvlceffixonulo                   := TRUE;
          PKGPAG_VAR.vgValorFixoCEF.vlFixo := 1;
        END IF;
        -------------------------------------------------------------------------
        IF (rGeraRubTotalRV.CdModalidadeRubrica IN (21, 22) AND
           PKGPAG_VAR.bPossuiACT) OR
          --
          -- 9911/2017 - FOLHA - - BASE 09-0903 PARA SERVIDOR INATIVO "SEM CONTRIBUICAO"
          --
           (rGeraRubTotalRV.CdModalidadeRubrica = 2 AND
           pkgpag_var.vgVinculo.CdRegimePrevidenciario = 3) -- SEM CONTRIBUICAO PREVIDENCIARIA
         THEN

          NULL;

          -- Solicitacao de Sustentacao #70959
          -- CIDASC - Rubrica nao respeita a parametrizacao
          -- A rubrica 09-0992 esta parametrizada para nao ser gerada para relacao de trabalho Jovem Aprendiz, mas continua gerando.
          -- #SIG-4374: O mesmo foi solicitado para a rubrica 09-1380
        ELSIF rGeraRubTotalRV.Cdrubricaagrupamento in (49205, 61896) -- 09-0992 e 09-1380 CIDASC
              AND PKGPAG_VAR.vgCEF.COUNT > 0 AND PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho = 18 -- Jovem Aperendiz

         THEN

          NULL;
          
        --- SIG-11613 -------------------------------------------------------------
        ELSIF rGeraRubTotalRV.CdRubricaAgrupamento IN 
          (PKGPAG_VAR.vgCdRubBaseDescSimplifIRRF, PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros) AND
           (rGeraRubTotalRV.Cdrelacaovinculo = 2 AND PKGPAG_VAR.vgCEF.count > 0)  THEN
            
            NULL;    
        ---------------------------------------------------------------------------
        
        ELSIF (rGeraRubTotalRV.CdModalidadeRubrica NOT IN
              (1, /*2,*/
                3,
                4,
                7,
                8,
                9,
                12,
                13,
                14,
                15,
                21,
                28,
                29,
                36,
                52,
                53,
                54,
                55,
                56,
                57,
                59,
                88,
                89) OR rgerarubtotalrv.cdmodalidaderubrica IS NULL) OR
              (rgerarubtotalrv.cdmodalidaderubrica IN (1, 21, 36) AND
              rgerarubtotalrv.cdrelacaovinculo IN (1, 4) AND
              ((PKGPAG_VAR.vgValorFixoCEF.vlFixo > 0 OR
              pkgpag_geral.fpossuilancfinanceiro(pcdvinculo => pcdvinculo,
                                                    pFolha     => pFolha,
                                                    pcdrubrica => pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                               1,
                                                                                               1)) OR
              pkgpag_geral.fpossuidecisaojudicial(pcdvinculo,
                                                     pFolha.nuanoreferencia,
                                                     pFolha.numesreferencia,
                                                     pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                  1,
                                                                                  1),
                                                     vVlDecisaoJudicial,
                                                     vCdDecisao,
                                                     vDtIniDecJud,
                                                     vDtFimDecJuc)) OR
              pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaBEP,PKGPAG_TIPO.cnTpFolhaOutras) OR
              pkgpag_var.vpagasitdisposicao = 'PAG-DEST-ADVINDO-DE-FORA' OR
              -- Solicitacao de Sustentacao #79790
              -- 12169/2018 - FOLHA - - INCIDENCIA DE IPREV NA RELACAO DE VINCULO DECISAO JUDICIAL
              (pFolha.CdAgrupamento = 134 and pkgpag_var.vgcef.count > 0 and pkgpag_var.vgcef(1).nunivelpagamento = 99 and pkgpag_var.vgcef(1).nureferenciapagamento = 'Z' and pkgpag_var.vgcef(1)
              .cdestruturacarreira = 87050))) OR

              (rgerarubtotalrv.cdmodalidaderubrica = 21 and
              pFolha.CdAgrupamento = 132) OR

              (rgerarubtotalrv.cdmodalidaderubrica = 1 AND
              rGeraRubTotalRV.CdRelacaoVinculo IN (1, 3) AND
              pFolha.CdAgrupamento = 6) OR

             -- Solicitacao de Sustentacao #64308
             -- PGTC - Nao esta gerando a base de IPREV e desconto de IPREV
              (rgerarubtotalrv.cdmodalidaderubrica = 1 AND
              rGeraRubTotalRV.CdRelacaoVinculo = 2 AND
              pFolha.CdAgrupamento = 133) OR

              (rgerarubtotalrv.cdmodalidaderubrica = 15 AND
              rgerarubtotalrv.cdrelacaovinculo IN (1, 4) AND
              PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN
              pFolha.DtInicioMes AND pFolha.DtFimMes and
              pFolha.CdTipoFolha <> pkgpag_tipo.cntpfolhafunebre) OR

              (rGeraRubTotalRV.CdModalidadeRubrica = 8 AND
              (PKGPAG_VAR.bPossuiACT OR pFolha.CdAgrupamento IN (2, 136)) AND
              pkgpag_var.vgvinculo.cdsituacaoprevidenciaria = 1) OR

              (rGeraRubTotalRV.CdModalidadeRubrica = 9 AND
              pFolha.NuMesReferencia <> 12 AND
              pFolha.CdTipoFolha IN
              (PKGPAG_TIPO.cnTpFolhaNormal,
                PKGPAG_TIPO.cnTpFolhaFunebre,
                PKGPAG_TIPO.cnTpFolhaServAfast)) OR

             -- Gera base do IPREV para pensionistas
              (rGeraRubTotalRV.CdModalidadeRubrica = 1 AND
              rgerarubtotalrv.cdrelacaovinculo = 6) OR

             -- Gera base do IPREV para instituidores comissionados
              (rGeraRubTotalRV.CdModalidadeRubrica = 1 AND
              rgerarubtotalrv.cdrelacaovinculo = 2 AND
              pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaInstPensao) OR

              (rGeraRubTotalRV.CdModalidadeRubrica = 1 AND
              pkgpag_var.vgPensaoNaoPrev.count > 0 AND pkgpag_var.vgPensaoNaoPrev(1).CdTipoPensaoNaoPrev = 83)

         THEN

          -- POG para gerar 09-0916 na 801 para quem tem subsidio e não tem 01-0001
          IF rGeraRubTotalRV.Cdrubricaagrupamento IN (9561, 11120) AND
            --pFolha.CdOrgao = 14 AND
             pFolha.CdAgrupamento = 1 AND bvlceffixonulo THEN
            PKGPAG_VAR.vgValorFixoCEF.vlFixo := NULL;
          END IF;

          IF (rGeraRubTotalRV.CdModalidadeRubrica = 68 AND
             PKGPAG_VAR.vgVinculo.FlSexo = 'M') OR
             (rGeraRubTotalRV.CdModalidadeRubrica = 2 AND
             PKGPAG_VAR.vgVinculo.CdOrgao = 34) OR
            -- Nao gera BASE IPREV para Regime Geral(INSS)
             (rGeraRubTotalRV.CdModalidadeRubrica = 1 AND
             pkgpag_var.vgVinculo.CdRegimePrevidenciario = 1) THEN

            NULL;

            --
            -- Epagri. Nao gerar base FGTS para afastados por auxilio doenca, exceto quando acidente de trabalho
            --
          ELSIF rGeraRubTotalRV.CdModalidadeRubrica = 31 AND
                PKGPAG_VAR.vMotAfast.InTipoAfastamento <> 'D' AND
                (PKGPAG_VAR.vMotAfast.FlAuxilioDoenca = PKGPAG_TIPO.cnS OR
                pkgpag_var.vgAfastTempNaoRemun.COUNT > 0) AND
                PKGPAG_VAR.vgParamOrgao.FlAuxilioDoenca = PKGPAG_TIPO.cnS AND
                PKGPAG_VAR.vMotAfast.FlAcidenteTrabalho = PKGPAG_TIPO.cnN AND
                pFolha.CdOrgao = 27 AND PKGPAG_VAR.vMotAfast.InAfastado <>
                PKGPAG_TIPO.cnAfastadoParcial -- Parcial

           THEN

            NULL;
            --
            -- Solicitacao de Sustentacao #69153
            -- 8630/2016 - FOLHA - - SERVIDOR ACT COM FGTS
            -- FGTS somente deve ser gerado para relacao de vinculo de CLT.
            --
          ELSIF rGeraRubTotalRV.CdModalidadeRubrica = 31 AND
                PKGPAG_VAR.vgVinculo.CdRegimeTrabalho <>
                PKGPAG_TIPO.cnRegTrabCLT THEN

            NULL;

            -- Se vinculo e CLT porem nao contem data de opcao de FGTS,
            -- Entao nao gera rubricas de FGTS
          ELSIF rGeraRubTotalRV.CdModalidadeRubrica = 31 AND
                PKGPAG_VAR.vgVinculo.CdRegimeTrabalho =
                PKGPAG_TIPO.cnRegTrabCLT AND
                PKGPAG_VAR.vgDtOpcaoFGTS IS NULL THEN

            NULL;

          ELSIF rGeraRubTotalRV.CdRubricaAgrupamento = 29677 AND
                NOT bPassou29677 AND pFolha.CdOrgao = 38 THEN

            xx(pcdfolhapagamento           => pfolha.cdfolhapagamento,
               pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
               pcdvinculo                  => rgerarubtotalrv.cdvinculo,
               pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
               pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
               pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
               pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
               pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
               pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
               pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
               pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
               pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
               pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
               pcdchave                    => rgerarubtotalrv.cdchave);

            bpassou29677 := TRUE;

          ELSIF rGeraRubTotalRV.CdRubricaAgrupamento = 29637 AND
                NOT bPassou29637 AND pFolha.CdOrgao = 8 THEN

            xx(pcdfolhapagamento           => pfolha.cdfolhapagamento,
               pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
               pcdvinculo                  => rgerarubtotalrv.cdvinculo,
               pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
               pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
               pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
               pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
               pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
               pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
               pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
               pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
               pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
               pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
               pcdchave                    => rgerarubtotalrv.cdchave);

            bpassou29637 := TRUE;

          ELSIF rgerarubtotalrv.cdrubricaagrupamento NOT IN (29677, 29637)
                AND NOT PKGPAG_LF.FPossuiLancamentoFinanceiro(rgerarubtotalrv.cdrubricaagrupamento) THEN

            pinsereregistro(pcdfolhapagamento           => pfolha.cdfolhapagamento,
                            pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
                            pcdvinculo                  => rgerarubtotalrv.cdvinculo,
                            pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
                            pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
                            pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
                            pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
                            pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
                            pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
                            pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
                            pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
                            pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
                            pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
                            pcdchave                    => rgerarubtotalrv.cdchave);

          else
            null;
          END IF;

        ELSIF (rGeraRubTotalRV.CdModalidadeRubrica IN (1, 21, 36) AND
              rGeraRubTotalRV.CdConcessaoAposentadoria IS NOT NULL) THEN

          IF pkgpag_var.vgapo.count > 0 THEN

            -- Gera as totalizadoras do IPESC apenas se a relacao comecou antes do inicio do mes de processamento

            IF (rGeraRubTotalRV.CdModalidadeRubrica = 1 AND
               ((PKGPAG_VAR.vgApo(1).DtInicioRelacao <= pFolha.DtInicioMes) OR
               pkgpag_var.vgNuDiasApo >= 30)) OR
               rgerarubtotalrv.cdmodalidaderubrica IN (21, 36) THEN

              pinsereregistro(pcdfolhapagamento           => pfolha.cdfolhapagamento,
                              pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
                              pcdvinculo                  => rgerarubtotalrv.cdvinculo,
                              pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
                              pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
                              pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
                              pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
                              pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
                              pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
                              pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
                              pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
                              pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
                              pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
                              pcdchave                    => rgerarubtotalrv.cdchave);

            END IF;

          END IF;

          IF pkgpag_var.vgaposemparidade.count > 0 THEN

            IF (rGeraRubTotalRV.CdModalidadeRubrica = 1 AND
               (PKGPAG_VAR.vgAPOSemParidade(1)
               .DtInicioRelacao <= pFolha.DtInicioMes)) OR
               rgerarubtotalrv.cdmodalidaderubrica IN (21, 36) THEN

              pinsereregistro(pcdfolhapagamento           => pfolha.cdfolhapagamento,
                              pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
                              pcdvinculo                  => rgerarubtotalrv.cdvinculo,
                              pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
                              pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
                              pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
                              pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
                              pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
                              pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
                              pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
                              pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
                              pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
                              pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
                              pcdchave                    => rgerarubtotalrv.cdchave);

            END IF;

          END IF;

        ELSIF rgerarubtotalrv.cdmodalidaderubrica IN (21, 36) AND
              (rGeraRubTotalRV.CdHistCargoCom IS NOT NULL AND
              (PKGPAG_VAR.vgValorFixoCEF.vlFixo = 0 OR
              PKGPAG_VAR.vgValorFixoCEF.vlFixo IS NULL) AND
              nvl(pkgpag_var.vgvlintegraliprev, 0) = 0) THEN

          -- Se for cargo comissionado puro gera a rubrica, senao ela ja foi incluida atraves do CEF

          pinsereregistro(pcdfolhapagamento           => pfolha.cdfolhapagamento,
                          pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
                          pcdvinculo                  => rgerarubtotalrv.cdvinculo,
                          pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
                          pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
                          pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
                          pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
                          pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
                          pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
                          pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
                          pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
                          pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
                          pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
                          pcdchave                    => rgerarubtotalrv.cdchave);

        ELSIF rGeraRubTotalRV.CdModalidadeRubrica IN (53, 54, 55, 57) AND
              pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal THEN

          IF pfolha.cdagrupamento <> 136 OR
             ((PKGPAG_VAR.vgCCO.COUNT > 0 AND PKGPAG_VAR.vgCEF.COUNT = 0 AND PKGPAG_VAR.vgCCO(1)
             .CdRelacaoTrabalho NOT IN ( /*13,*/ 15)) OR
             (pkgpag_var.vgcef.count > 0)) THEN

            -- Se for Comissionado puro e nao for Conselheiro, gera as bases das modalidades acima

            pinsereregistro(pcdfolhapagamento           => pfolha.cdfolhapagamento,
                            pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
                            pcdvinculo                  => rgerarubtotalrv.cdvinculo,
                            pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
                            pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
                            pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
                            pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
                            pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
                            pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
                            pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
                            pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
                            pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
                            pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
                            pcdchave                    => rgerarubtotalrv.cdchave);

          END IF;

        ELSIF rGeraRubTotalRV.CdModalidadeRubrica IN (52, 56) AND
              pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias THEN

          IF (PKGPAG_VAR.vgCCO.COUNT > 0 AND PKGPAG_VAR.vgCEF.COUNT = 0 AND PKGPAG_VAR.vgCCO(1).CdRelacaoTrabalho <> 15) OR
             (PKGPAG_VAR.vgCEF.COUNT > 0) THEN

            pinsereregistro(pcdfolhapagamento           => pfolha.cdfolhapagamento,
                            pcdrubricaagrupamento       => rgerarubtotalrv.cdrubricaagrupamento,
                            pcdvinculo                  => rgerarubtotalrv.cdvinculo,
                            pcdrelacaovinculo           => rgerarubtotalrv.cdrelacaovinculo,
                            pcdhistcargoefetivo         => rgerarubtotalrv.cdhistcargoefetivo,
                            pcdhistcargocom             => rgerarubtotalrv.cdhistcargocom,
                            pcdhistestagio              => rgerarubtotalrv.cdhistestagio,
                            pcdhistfuncaochefia         => rgerarubtotalrv.cdhistfuncaochefia,
                            pcdhistauxilioreclusao      => rgerarubtotalrv.cdhistauxilioreclusao,
                            pcdhistpensaoexparlamentar  => rgerarubtotalrv.cdhistpensaoexparlamentar,
                            pcdhistpensaonaoprev        => rgerarubtotalrv.cdhistpensaonaoprev,
                            pcdhistpensaoprevidenciaria => rgerarubtotalrv.cdhistpensaoprevidenciaria,
                            pcdconcessaoaposentadoria   => rgerarubtotalrv.cdconcessaoaposentadoria,
                            pcdchave                    => rgerarubtotalrv.cdchave);

          END IF;

          -- POG: CHAMADO #64988 - 8035/2016 - FOLHA - TRIBUTACAO DO IPREV DA FUNCIONALIDADE DE RETENCAO DE IPREV DE OUTROS AGRUPAMENTOS
          -- INSERIR BASE DO IPREV PARA COMISSIONADOS A DISPOSICAO
          -- QUE APRESENTAM LANCAMENTO FINANCEIRO ZERADO NA 01-0001, ORIGINADO DO CAMPO "Base de contribuicao do IPREV"
          -- DA TELA "Alterar Designacao/Nomeacao de Comissionado em Vinculo Existente"
        ELSIF rgerarubtotalrv.cdrubricaagrupamento =
              NVL(PKGPAG_VAR.vgCdRubBaseIPESC, 0) /*9561*/
              and rgerarubtotalrv.cdrelacaovinculo =
              PKGPAG_TIPO.cnTpRelacaoComissionado and
              rgerarubtotalrv.cdhistcargocom is not null THEN
          --
          -- Verificar se ja inclui a rubrica na tabela para nao duplicar.
          -- Solicitacao de Sustentacao #70166
          -- 8779/2016 - FOLHA - CALCULO DO IPREV EM AGRUPAMENTOS DISTINTOS
          --
          vvlpagamento := fretornavaloroutrasrv(pcdfolhapagamento     => pfolha.cdfolhapagamento,
                                                pcdvinculo            => pCdVinculo,
                                                pcdrubricaagrupamento => PKGPAG_VAR.vgCdRubBaseIPESC);

          IF NVL(vvlpagamento.vlProporcional, 0) = 0 THEN

            vVlBaseIPREVComissionadoADisp := fVlBaseIPREVComissionadoADisp(pfolha,
                                                                           pCdVinculo);

            IF vVlBaseIPREVComissionadoADisp IS NOT NULL THEN

              INSERT INTO EPagHistoricoRubricaRelVinc
                (cdhistoricorubricarelvinc,
                 cdfolhapagamento,
                 cdrubricaagrupamento,
                 nusufixorubrica,
                 vlintegral,
                 vlproporcional,
                 cdvinculo,
                 cdrelacaovinculo,
                 cdhistcargoefetivo,
                 cdhistcargocom,
                 cdhistestagio,
                 cdhistfuncaochefia,
                 cdhistauxilioreclusao,
                 cdhistpensaoexparlamentar,
                 cdhistpensaonaoprev,
                 cdhistpensaoprevidenciaria,
                 cdconcessaoaposentadoria,
                 qtparcelas,
                 vlindicerubrica,
                 cdchave,
                 cdtipoorigemrubrica)
              VALUES
                (SPagHistoricoRubricaRelVinc.NEXTVAL,
                 pfolha.cdfolhapagamento,
                 rgerarubtotalrv.cdrubricaagrupamento,
                 1,
                 vVlBaseIPREVComissionadoADisp,
                 vVlBaseIPREVComissionadoADisp,
                 rgerarubtotalrv.cdvinculo,
                 rgerarubtotalrv.cdrelacaovinculo,
                 rgerarubtotalrv.cdhistcargoefetivo,
                 rgerarubtotalrv.cdhistcargocom,
                 rgerarubtotalrv.cdhistestagio,
                 rgerarubtotalrv.cdhistfuncaochefia,
                 rgerarubtotalrv.cdhistauxilioreclusao,
                 rgerarubtotalrv.cdhistpensaoexparlamentar,
                 rgerarubtotalrv.cdhistpensaonaoprev,
                 rgerarubtotalrv.cdhistpensaoprevidenciaria,
                 rgerarubtotalrv.cdconcessaoaposentadoria,
                 1,
                 NULL,
                 rgerarubtotalrv.cdchave,
                 1);

              --Salva o valor que foi cadastrado para calculodo IPREV
              --SIG-3204 base de c?lculo foi cadastrada na funcionalidade "manter comissionado no mesmo v?nculo"
              pkgpag_var.vgvlintegraliprev := vVlBaseIPREVComissionadoADisp;

            END IF;

          END IF;

        else
          null;
        END IF;

      END LOOP;

    END IF;

    RETURN bgeroutotalizadoras;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

  FUNCTION fgerarubricastotalizVinculo (pfolha     IN pkgpag_tipo.rfolha,
                                        pCdVinculo IN INTEGER) RETURN BOOLEAN IS

    bgeroutotalizadoras BOOLEAN DEFAULT FALSE;

    bRubricaPresenteContracheque BOOLEAN;

    vCdModalidadeRubrica INTEGER;

    CURSOR cgerarubtotalvinc IS
      SELECT DISTINCT HV.CdVinculo,
                      r.cdrubricaagrupamento,
                      r.cdmodalidaderubrica
        FROM epaghistoricorubricavinculo hv
       CROSS JOIN (SELECT RA.CdRubricaAgrupamento, RA.CdModalidadeRubrica
                     FROM epagrubricaagrupamento ra
                    INNER JOIN epagrubrica r
                       ON ra.cdrubrica = r.cdrubrica
                    INNER JOIN epaghistrubricaagrupamento hra
                       ON ra.cdrubricaagrupamento = hra.cdrubricaagrupamento
                    WHERE R.CdTipoRubrica = PKGPAG_TIPO.cnTpRubTotalizadora
                      AND RA.CdBaseCalculo IS NOT NULL
                      AND ((HRA.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                          (HRA.NuAnoInicioVigencia =
                          pFolha.NuAnoReferencia AND
                          HRA.NuMesInicioVigencia <=
                          pFolha.NuMesReferencia)) AND
                          (hra.nuanofimvigencia > pfolha.nuanoreferencia OR
                          (hra.nuanofimvigencia = pfolha.nuanoreferencia AND
                          hra.numesfimvigencia >= pfolha.numesreferencia) OR
                          HRA.NuAnoFimVigencia IS NULL))
                      AND RA.CdAgrupamento = pFolha.CdAgrupamento) R
       WHERE HV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND (HV.CdVinculo = pCdVinculo);

    PROCEDURE pinsereregistroVinculo (pcdfolhapagamento           IN INTEGER,
                                      pcdrubricaagrupamento       IN INTEGER,
                                      pcdvinculo                  IN INTEGER) IS
                                      
    BEGIN
                                           
       INSERT INTO EPagHistoricoRubricaVinculo
            (cdhistoricorubricavinculo,
             cdfolhapagamento,
             cdrubricaagrupamento,
             cdvinculo,
             nusufixorubrica,
             vlpagamento,
             qtparcelas,
             vlindicerubrica,
             cdtipoorigemrubrica)
        VALUES
            (SPagHistoricoRubricaVinculo.NEXTVAL,
             pcdfolhapagamento,
             pcdrubricaagrupamento,
             pcdvinculo,
             1,
             0,
             1,
             0,
             1);

    END;
    
  BEGIN
 

    IF (pkgpag_var.vgvinculo.dtdesligamento < pfolha.dtiniciomes) OR
       pFolha.CdTipoFolha IN
       (PKGPAG_TIPO.cnTpFolha13,
        PKGPAG_TIPO.cnTpFolhaAdiant13,
        pkgpag_tipo.cntpfolharesidente13,
        pkgpag_tipo.cnTpFolhaCtisp13,
        pkgpag_tipo.cnTpFolhaAdiant13Ctisp,
        pkgpag_tipo.cnTpFolhaFunebre13) OR
       pfolha.cdtipocalculo = pkgpag_tipo.cntpcalculosupl THEN

      FOR rGeraRubTotalVinc IN cGeraRubTotalVinc LOOP

        bgeroutotalizadoras := TRUE;

        -- A base do erario (14) e calculada na rotina de erario
        -- A base da margem consignavel bruta (10) e calculada na rotina de consignacao

        -- Solicitacao de Sustentacao #64112
        -- 7901/2015 - FOLHA - LANCAMENTO FINANCEIRO COMPLEMENTAR
        -- Rubricas de bases terem o mesmo comportamento das demais
        -- em folhas de decimo terceiro via lancamento complementar.

        IF (pkgpag_var.vgFolha.CdTipoFolha IN
           (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaResidente13) AND
           pkgpag_geral.fpossuilanccomplementar(pcdrubricaagrupamento => rgerarubtotalvinc.cdrubricaagrupamento,
                                                 pnusufixorubrica      => 1)) OR
           (rGeraRubTotalVinc.CdModalidadeRubrica in (12, 82) AND
           pkgpag_var.vgVinculo.CdRegimePrevidenciario <> 1) -- GERAL/INSS
         THEN

          CONTINUE;

        END IF;

        IF FAgrupUtilizaDescSimp(pCdAgrupamento => pFolha.CdAgrupamento,
                                 pNuAnoMesFolha => (pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia) THEN
          vCdModalidadeRubrica := nvl(rGeraRubTotalVinc.CdModalidadeRubrica, 0);
        ELSE
          vCdModalidadeRubrica := rGeraRubTotalVinc.CdModalidadeRubrica;
        END IF;

        IF NOT (vCdModalidadeRubrica IN (3,
                                                          4,
                                                          7,
                                                          9,
                                                          10,
                                                          11,
                                                          12,
                                                          13,
                                                          14,
                                                          28,
                                                          29,
                                                          34,
                                                          35,
                                                          36,
                                                          37,
                                                          52,
                                                          53,
                                                          54,
                                                          55,
                                                          56,
                                                          59,
                                                          88,
                                                          89,
                                                          111,
                                                          112,
                                                          115,
                                                          116,
                                                          117,
                                                          118,
                                                          119,
                                                          120))
        -- OR rGeraRubTotalVinc.CdModalidadeRubrica is null

         THEN
          --
          -- 7588/2015 - FOLHA - BASE SC SAUDE
          -- NAO GERAR AS BASES DO SC SAUDE 09-0937 E 09-0938 PARA VINCULOS DE ACT.
          --
          /* IF NOT (rGeraRubTotalVinc.cdmodalidaderubrica IN (15)
          AND pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13)
          AND PKGPAG_VAR.vgFolha.Cdorgao = 33)
          THEN*/

          bRubricaPresenteContracheque := FRubricaPresenteNoContracheque(pCdVinculo => rgerarubtotalvinc.cdvinculo,
                                                                         pCdRubricaAgrupamento => rgerarubtotalvinc.cdrubricaagrupamento,
                                                                         pCdFolhaPagamento => pfolha.cdfolhapagamento);

          IF NOT (rGeraRubTotalVinc.CdModalidadeRubrica IN (21, 22) AND PKGPAG_VAR.bPossuiAct) AND
             NOT bRubricaPresenteContracheque AND
             NOT (pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,09,0380) = rgerarubtotalvinc.cdrubricaagrupamento
                  and pfolha.CdOrgao in ( 27,25) AND (PKGPAG_VAR.vgCEF.COUNT > 0) AND (PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho <> 18)) AND
             NOT (pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,09,1380) = rgerarubtotalvinc.cdrubricaagrupamento
                  and pfolha.CdOrgao in ( 27,25) AND (PKGPAG_VAR.vgCEF.COUNT > 0) AND (PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho <> 18))  THEN

             PInsereRegistroVinculo (pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                     pCdRubricaAgrupamento => rgerarubtotalvinc.cdRubricaAgrupamento,
                                     pCdVinculo            => rgerarubtotalvinc.cdVinculo);                            

          END IF;
          -- END IF;

        ELSIF rGeraRubTotalVinc.cdmodalidaderubrica IN (111) AND
              PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario =
              pkgpag_tipo.cnRegPrevCPSM THEN

          PInsereRegistroVinculo (pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                  pCdRubricaAgrupamento => rgerarubtotalvinc.cdRubricaAgrupamento,
                                  pCdVinculo            => rgerarubtotalvinc.cdVinculo);

        ELSIF rGeraRubTotalVinc.cdmodalidaderubrica IN (112) AND
              PKGPAG_VAR.vgFolha.Cdorgao = 33 THEN

          PInsereRegistroVinculo (pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                  pCdRubricaAgrupamento => rgerarubtotalvinc.cdRubricaAgrupamento,
                                  pCdVinculo            => rgerarubtotalvinc.cdVinculo);

        END IF;

      END LOOP;

      --
      -- Para desligados na EPAGRI que tem Decisao Judicial com referencia a rubrica 01-0080
      -- gerar as bases 09-0380 e 09-1380
      --
      IF pFolha.CdOrgao IN (25, 27) AND (PKGPAG_VAR.vgCEF.COUNT > 0) AND (PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho <> 18 /*Jovem Aperendiz*/
         ) THEN

        PInsereRegistroVinculo (pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                pCdRubricaAgrupamento => PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 9, 380),
                                pCdVinculo            => pkgpag_var.vgvinculo.cdvinculo);

        PInsereRegistroVinculo (pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                pCdRubricaAgrupamento => PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 9, 1380),
                                pCdVinculo            => pkgpag_var.vgvinculo.cdvinculo);


        --
        -- Solicitacao de Sustentacao #64583
        -- BASE PATRONAL DO IPREV NO 13. SALARIO
        --
        IF pkgpag_var.vgVinculo.CdRegimePrevidenciario = 2 -- IPREV
         THEN

          PInsereRegistroVinculo (pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                  pCdRubricaAgrupamento => PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 9, 1017),
                                  pCdVinculo            => pkgpag_var.vgvinculo.cdvinculo);

        END IF;
      END IF;

    END IF;

    RETURN bgeroutotalizadoras;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

  /*-----------------------------------------------------------------------------------------
    Function: FGeraRubricasTotalizadoras

    Objetivo: Gerar historicos de pagamentos para as relacoes de vinculo e vinculo
              com as rubricas do agrupamento cujo tipo e Totalizadora

    Argumentos: pFolha - registro contendo informacoes da folha que esta sendo processada
                pCdVinculo - codigo do vinculo cuja folha esta sendo calculada

  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fgerarubricastotalizadoras(pfolha     IN pkgpag_tipo.rfolha,
                                      pCdVinculo IN INTEGER) RETURN BOOLEAN IS

  BEGIN
      
      RETURN fgerarubricastotalizRelVinc (pFolha     => pFolha,
                                          pCdVinculo => pCdVinculo)
             OR                      
             fgerarubricastotalizVinculo (pFolha     => pFolha,
                                          pCdVinculo => pCdVinculo);
  
  END;

  /* ---------------------------------------------------------------------------------------------------------------- */

  /* ---------------------------------------------------------------------------------------------------------------- */
  PROCEDURE patualizatotalizadoras(pcdfolhapagamento IN INTEGER,
                                   pcdvinculo        IN INTEGER) IS

    --vVlDescontoPensao NUMBER(13,2) := 0;

    --vVlProventoPensao NUMBER(13,2) := 0;

    --vNumeroPensoes NUMBER;

  BEGIN
 
    -- Seleciona Total de Proventos

    SELECT nvl(SUM(vlpagamento), 0)
      INTO pkgpag_var.vgvltotalproventos
      FROM epaghistoricorubricavinculo hrv1
     INNER JOIN epagrubricaagrupamento ra
        ON hrv1.cdrubricaagrupamento = ra.cdrubricaagrupamento
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
     WHERE HRV1.CdFolhaPagamento = pCdFolhaPagamento
       AND HRV1.CdVinculo = pCdVinculo
       AND R.CdTipoRubrica IN (1, 2, 3, 4, 10, 12);

    -- Seleciona Total de Descontos

    SELECT nvl(SUM(vlpagamento), 0)
      INTO pkgpag_var.vgvltotaldescontos
      FROM epaghistoricorubricavinculo hrv1
     INNER JOIN epagrubricaagrupamento ra
        ON hrv1.cdrubricaagrupamento = ra.cdrubricaagrupamento
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
     WHERE HRV1.CdFolhaPagamento = pCdFolhaPagamento
       AND HRV1.CdVinculo = pCdVinculo
       AND R.CdTipoRubrica IN (5, 6, 7, 8, 11, 13);

    -- Seleciona Total Liquido

    pkgpag_var.vgvlbasetotalliquida := nvl(pkgpag_var.vgvltotalproventos, 0) -
                                       nvl(pkgpag_var.vgvltotaldescontos, 0);

  END;

  PROCEDURE pValidaTotalPensao(pcdfolhapagamento IN INTEGER,
                               pcdvinculo        IN INTEGER) IS

    vVlDescontoPensao NUMBER(13, 2) := 0;

    vVlProventoPensao NUMBER(13, 2) := 0;

    vNumeroPensoes NUMBER;

  BEGIN
 
    SELECT count(hrv1.nusufixorubrica)
      INTO vNumeroPensoes
      FROM epaghistoricorubricavinculo hrv1
     INNER JOIN epagrubricaagrupamento ra
        ON hrv1.cdrubricaagrupamento = ra.cdrubricaagrupamento
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
     WHERE HRV1.CdFolhaPagamento = pCdFolhaPagamento
       AND HRV1.CdVinculo = pCdVinculo
       AND R.CdTipoRubrica IN (5, 6, 7, 8, 11, 13)
       AND RA.Flpensaoalimenticia = PKGPAG_TIPO.cnS;

    FOR i in 1 .. vNumeroPensoes LOOP

      vVlProventoPensao := 0;

      vVlDescontoPensao := 0;

      SELECT nvl(SUM(vlpagamento), 0)
        INTO vVlProventoPensao
        FROM epaghistoricorubricavinculo hrv1
       INNER JOIN epagrubricaagrupamento ra
          ON hrv1.cdrubricaagrupamento = ra.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON r.cdrubrica = ra.cdrubrica
       WHERE HRV1.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV1.CdVinculo = pCdVinculo
         AND HRV1.Nusufixorubrica = i
         AND RA.Flpensaoalimenticia = PKGPAG_TIPO.cnS
         AND R.CdTipoRubrica IN (1, 2, 3, 4, 10, 12);

      SELECT nvl(SUM(vlpagamento), 0)
        INTO vVlDescontoPensao
        FROM epaghistoricorubricavinculo hrv1
       INNER JOIN epagrubricaagrupamento ra
          ON hrv1.cdrubricaagrupamento = ra.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON r.cdrubrica = ra.cdrubrica
       WHERE HRV1.CdFolhaPagamento = pCdFolhaPagamento
         AND HRV1.CdVinculo = pCdVinculo
         AND HRV1.Nusufixorubrica = i
         AND R.CdTipoRubrica IN (5, 6, 7, 8, 11, 13)
         AND RA.Flpensaoalimenticia = PKGPAG_TIPO.cnS;

      IF vVlProventoPensao > vVlDescontoPensao

       THEN
        pkgpag_geral.pinserelog(pinsere                  => pkgpag_var.blog,
                                pcdhistoricoparamcalculo => pkgpag_var.vcdhistparamcalc,
                                pcdpessoa                => pkgpag_var.vcdpessoa,
                                pdelog                   => 'Pensionista com saldo negativo.',
                                pcdvinculo               => pcdvinculo,
                                pCdTipoOcorrencia        => 1, -- Erro
                                pcdmotivoocorrencia      => 23);

      END IF;

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      --vVlProventoPensao := 0;
      null;
  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de Aposentadoria com Paridade
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaoapocomparidade(pcdvinculo IN INTEGER) IS

    i INTEGER;

    vtapo pkgpag_tipo.tcef;

    vnunivelpagamento VARCHAR2(3);

    vnureferenciapagamento VARCHAR2(3);

    vcdestruturacarreira INTEGER;

    vcdestruturacarreiracarreira INTEGER;

    CURSOR capoparidade(pcdvinculo   IN INTEGER,
                        pcdorgao     IN INTEGER,
                        pdtiniciomes IN DATE,
                        pdtfimmes    IN DATE) IS

      SELECT ca.cdvinculo,
             4 AS cdrelacaovinculo,
             ca.cdconcessaoaposentadoria AS cdhistrelvinc,
             cef.cdrelacaotrabalho,
             v.cdregimetrabalho,
             0 AS cdnaturezavinculo,
             v.cdregimeprevidenciario,
             hsp.cdsituacaoprevidenciaria,
             cef.cdestruturacarreira,
             ec.cdestruturacarreiracarreira,
             CASE
               WHEN ca.dtinicioaposentadoria < pdtiniciomes THEN
                pdtiniciomes
               ELSE
                ca.dtinicioaposentadoria
             END AS dtinicio,
             CASE
               WHEN CA.DtFimAposentadoria IS NULL AND
                    CA.DtInicioAposentadoria BETWEEN pdtInicioMes AND
                    pdtFimMes THEN
                CASE
                  WHEN to_char(ca.dtinicioaposentadoria, 'MM') = 2 THEN
                   pdtfimmes
                  WHEN to_char(pdtfimmes, 'DD') > 30 THEN
                   pdtfimmes - 1
                  ELSE
                   pdtfimmes
                END
               WHEN CA.DtFimAposentadoria IS NULL OR
                    CA.DtFimAposentadoria > pdtFimMes THEN
                pdtfimmes
               ELSE
                ca.dtfimaposentadoria
             END AS dtfim,
             ca.dtinicioaposentadoria AS dtiniciorelacao,
             ca.dtfimaposentadoria AS dtfimrelacao,
             cef.cdhistcargoefetivo,
             cef.nunivelpagamento,
             cef.nureferenciapagamento,
             ca.vlpercentpropapo,
             ca.cdmodeloaposentadoria,
             cef.cdorgaoexercicio,
             cef.flprincipal,
             ca.cdunidadeorganizacional,
             ca.florigemcco,
             cef.flefetivacao,
             0 AS nucargahoraria,
             NULL AS tidnucargahoraria,
             cef.cdorgaodestprocseletivo,
             cef.dtfimnovoprocessoseletivo,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             'N' AS flexercicioorigem,
             0 AS cdorgaodestmovimentacao,
             ca.dtinclusao
        FROM epvdconcessaoaposentadoria ca
       INNER JOIN ecadvinculo v
          ON ca.cdvinculo = v.cdvinculo
       INNER JOIN epvdmodeloaposentadoria ma
          ON ca.cdmodeloaposentadoria = ma.cdmodeloaposentadoria
       INNER JOIN ecadhistsitprevvinculo hsp
          ON CA.CdVinculo = HSP.CdVinculo
         AND (CA.DtInicioAposentadoria BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       INNER JOIN ecadhistcargoefetivo cef
          ON cef.cdvinculo = ca.cdvinculo
       INNER JOIN ecadestruturacarreira ec
          ON cef.cdestruturacarreira = ec.cdestruturacarreira
       WHERE V.CdVinculo = pCdVinculo
         AND CA.CdOrgaoExercicio = pCdOrgao
         AND CA.FlAtiva = PKGPAG_TIPO.cnS
         AND CA.FlAnulado = PKGPAG_TIPO.cnN
         AND MA.FlParidade = PKGPAG_TIPO.cnS
         AND CEF.CdRelacaotrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao
         AND ((CA.DtInicioAposentadoria <= pdtFimMes) AND
             (CA.DtFimAposentadoria >= pdtInicioMes OR
             CA.DtFimAposentadoria IS NULL))
         AND CEF.FlEfetivacao = PKGPAG_TIPO.cnT
         AND CEF.FlAnulado = PKGPAG_TIPO.cnN
         AND CEF.DtFim =
             (SELECT MAX(dtFim)
                FROM ecadhistcargoefetivo cef
               WHERE CEF.CdVinculo = pCdVinculo
                 AND CEF.CdRelacaoTrabalho <>
                     PKGPAG_TIPO.cnRelTrabDisposicao
                 AND CEF.FlEfetivacao = PKGPAG_TIPO.cnT
                 AND CEF.FlAnulado = PKGPAG_TIPO.cnN)
       ORDER BY ca.dtinicioaposentadoria DESC;

  BEGIN
 
    pkgpag_var.vgapo := vtapo;

    i := 0;

    FOR vAPOParidade IN cAPOParidade(pCdVinculo,
                                     PKGPAG_VAR.vgFolha.CdOrgao,
                                     pkgpag_var.vgfolha.dtiniciomes,
                                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      i := i + 1;

      --PKGPAG_VAR.vgAPO(i) := vAPOParidade;

      pkgpag_var.vgapo(i).cdvinculo := vapoparidade.cdvinculo;
      pkgpag_var.vgapo(i).cdrelacaovinculo := vapoparidade.cdrelacaovinculo;
      pkgpag_var.vgapo(i).cdhistrelvinc := vapoparidade.cdhistrelvinc;
      pkgpag_var.vgapo(i).cdrelacaotrabalho := vapoparidade.cdrelacaotrabalho;
      pkgpag_var.vgapo(i).cdregimetrabalho := vapoparidade.cdregimetrabalho;
      pkgpag_var.vgapo(i).cdnaturezavinculo := vapoparidade.cdnaturezavinculo;
      pkgpag_var.vgapo(i).cdregimeprevidenciario := vapoparidade.cdregimeprevidenciario;
      pkgpag_var.vgapo(i).cdsituacaoprevidenciaria := vapoparidade.cdsituacaoprevidenciaria;
      pkgpag_var.vgapo(i).cdestruturacarreira := vapoparidade.cdestruturacarreira;
      pkgpag_var.vgapo(i).cdestruturacarreiracarreira := vapoparidade.cdestruturacarreiracarreira;
      pkgpag_var.vgapo(i).dtinicio := vapoparidade.dtinicio;
      pkgpag_var.vgapo(i).dtfim := vapoparidade.dtfim;
      pkgpag_var.vgapo(i).dtiniciorelacao := vapoparidade.dtiniciorelacao;
      pkgpag_var.vgapo(i).dtfimrelacao := vapoparidade.dtfimrelacao;
      pkgpag_var.vgapo(i).cdhistcargoefetivo := vapoparidade.cdhistcargoefetivo;
      pkgpag_var.vgapo(i).nunivelpagamento := vapoparidade.nunivelpagamento;
      pkgpag_var.vgapo(i).nureferenciapagamento := vapoparidade.nureferenciapagamento;
      pkgpag_var.vgapo(i).vlpercentpropapo := vapoparidade.vlpercentpropapo;
      pkgpag_var.vgapo(i).cdmodeloaposentadoria := vapoparidade.cdmodeloaposentadoria;
      pkgpag_var.vgapo(i).cdorgaoexercicio := vapoparidade.cdorgaoexercicio;
      pkgpag_var.vgapo(i).flprincipal := vapoparidade.flprincipal;
      pkgpag_var.vgapo(i).cdunidadeorganizacional := vapoparidade.cdunidadeorganizacional;
      pkgpag_var.vgapo(i).florigemcco := vapoparidade.florigemcco;
      pkgpag_var.vgapo(i).flefetivacao := vapoparidade.flefetivacao;
      pkgpag_var.vgapo(i).nucargahoraria := vapoparidade.nucargahoraria;
      pkgpag_var.vgapo(i).tidnucargahoraria := NULL;
      pkgpag_var.vgapo(i).cdorgaodestprocseletivo := vapoparidade.cdorgaodestprocseletivo;
      pkgpag_var.vgapo(i).dtfimnovoprocessoseletivo := vapoparidade.dtfimnovoprocessoseletivo;
      pkgpag_var.vgapo(i).cdmotivomovimentacao := vapoparidade.cdmotivomovimentacao;
      pkgpag_var.vgapo(i).cdinstitutomovimentacao := vapoparidade.cdinstitutomovimentacao;
      pkgpag_var.vgapo(i).flexercicioorigem := vapoparidade.flexercicioorigem;
      pkgpag_var.vgapo(i).cdorgaodestmovimentacao := vapoparidade.cdorgaodestmovimentacao;
      pkgpag_var.vgapo(i).dtinclusao := vapoparidade.dtinclusao;

      ------------------------------------------------------------
      -- Seleciona a carga horaria na data do calculo
      ------------------------------------------------------------

      -- PRIORIZA CARGA HORARIA DO APOSENTADO
      BEGIN

        SELECT nucargahoraria
          INTO pkgpag_var.vgapo(i).nucargahoraria
          FROM (SELECT nucargahoraria
                  FROM ecadhistcargahoraria cho
                 WHERE CHO.Cdconcessaoaposentadoria =
                       vAPOParidade.cdhistrelvinc
                   AND CHO.FlAnulado = 'N'
                   AND CHO.DtInicial <= PKGPAG_VAR.vgFolha.DtFimMes /*AND
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              CHO.FlTipoOcupacao = 'D'*/
                 ORDER BY DtInicial DESC)
         WHERE ROWNUM < 2;

        -- SE NAO ENCONTROU, BUSCA CARGA HORARIA DO EFETIVO
      EXCEPTION

        WHEN no_data_found THEN

          BEGIN

            SELECT nucargahoraria
              INTO pkgpag_var.vgapo(i).nucargahoraria
              FROM (SELECT nucargahoraria
                      FROM ecadhistcargahoraria cho
                     WHERE CHO.CdHistCargoEfetivo =
                           vAPOParidade.CdHistCargoEfetivo
                       AND CHO.FlAnulado = 'N'
                       AND CHO.DtInicial <= PKGPAG_VAR.vgFolha.DtFimMes
                       AND CHO.FlTipoOcupacao = 'D'
                     ORDER BY DtInicial DESC)
             WHERE ROWNUM < 2;

          EXCEPTION

            WHEN no_data_found THEN

              NULL;

          END;

      END;
      /*---------------------------------------------------------------------------------*/
      -- Verifica se existe progressao da aposentadoria na tabela ecadhistnivelrefcefinativo
      /*----------------------------------------------------------------------------------*/

      pkgpag_var.vgapo(i).nunivelpagamentocef := pkgpag_var.vgapo(i).nunivelpagamento;

      pkgpag_var.vgapo(i).nureferenciapagamentocef := pkgpag_var.vgapo(i).nureferenciapagamento;

      pkgpag_var.vgapo(i).cdestruturacarreiracef := pkgpag_var.vgapo(i).cdestruturacarreira;

      pkgpag_var.vgapo(i).cdestruturacarreiracarreiracef := pkgpag_var.vgapo(i).cdestruturacarreiracarreira;

      BEGIN

        SELECT DISTINCT NuNivelPagamento,
               NuReferenciaPagamento,
               cdestruturacarreira,
               cdestruturacarreiracarreira
          INTO vNuNivelPagamento,
               vNuReferenciaPagamento,
               vCdEstruturaCarreira,
               vCdEstruturaCarreiraCarreira
          FROM (SELECT I.NuNivelPagamento,
                       I.NuReferenciaPagamento,
                       ec.cdestruturacarreira,
                       ec.cdestruturacarreiracarreira
                  FROM ecadhistnivelrefcefinativo i
                  LEFT JOIN ecadestruturacarreira ec
                    ON ec.cdestruturacarreira = i.cdestruturacarreira
                   AND ec.flanulado = 'N'
                 WHERE I.CdConcessaoAposentadoria =
                       vAPOParidade.CdHistRelVinc
                   AND I.FlAnulado = 'N'
                   AND I.DtInicio <= PKGPAG_VAR.vgFolha.DtFimMes
                   AND (I.DtFim >= PKGPAG_VAR.vgFolha.DtInicioMes OR
                       I.dtFim IS NULL)
                 ORDER BY i.dtinicio DESC);

        pkgpag_var.vgapo(i).nunivelpagamento := vnunivelpagamento;

        pkgpag_var.vgapo(i).nureferenciapagamento := vnureferenciapagamento;

      EXCEPTION

        when no_data_found then

          NULL;

        WHEN OTHERS THEN
          null;
          /*PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
          PKGPAG_VAR.vCdHistParamCalc,
          PKGPAG_VAR.vCdPessoa,
          'mais de um nivel/referencia de inativo encontrados no periodo',
          PKGPAG_VAR.vgCdVinculo);*/
      END;

      -- Se encontrou cdestrutura carreira em ecadhistnivelrefcefinativo utiliza esta
      IF vCdEstruturaCarreira IS NOT NULL THEN

        pkgpag_var.vgapo(i).cdestruturacarreira := vcdestruturacarreira;

        pkgpag_var.vgapo(i).cdestruturacarreiracarreira := vcdestruturacarreiracarreira;

      ELSE

        BEGIN

          SELECT M.CdEstruturaCarreiraDestino,
                 EC.CdEstruturaCarreiraCarreira
            INTO vCdEstruturaCarreira, vCdEstruturaCarreiraCarreira
            FROM emovmudancacargoefetivoinativo m
           INNER JOIN ecadestruturacarreira ec
              ON m.cdestruturacarreiradestino = ec.cdestruturacarreira
           WHERE M.CdConcessaoAposentadoria = vAPOParidade.CdHistRelVinc
             AND M.FlAnulado = 'N'
             AND M.DtMudanca <= PKGPAG_VAR.vgFolha.DtFimMes
             AND (M.DtFimMudanca >= PKGPAG_VAR.vgFolha.DtInicioMes OR
                 M.DtFimMudanca IS NULL)
             AND ROWNUM < 2;

          pkgpag_var.vgapo(i).cdestruturacarreira := vcdestruturacarreira;

          pkgpag_var.vgapo(i).cdestruturacarreiracarreira := vcdestruturacarreiracarreira;

        EXCEPTION

          WHEN OTHERS THEN

            NULL;

        END;

      END IF;

      -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
      -- e o codigo da relacao de vinculo

      pkgpag_var.vgrelvincprincipal.tipo := 4;

      pkgpag_var.vgrelvincprincipal.cdhist := vapoparidade.cdhistrelvinc;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vapoparidade.cdunidadeorganizacional;

      pkgpag_var.vgNuDiasApo := pkgpag_var.vgNuDiasApo +
                                (pkgpag_var.vgapo(i).dtfim - pkgpag_var.vgapo(i).dtinicio + 1);

    END LOOP;

    if pkgpag_var.vgNuDiasApo < 30 and
       pkgpag_var.vgNuDiasApo =
       to_number(to_char(pkgpag_var.vgFolha.DtFimMes, 'DD')) then
      pkgpag_var.vgNuDiasApo := 30;
    end if;
    -- Sem intersticio e com 2 aposentadorias, deixa so o ultimo
    if pkgpag_var.vgNuDiasApo = 30 and pkgpag_var.vgapo.count = 2 then
      pkgpag_var.vgapo(1).dtiniciorelacao := pkgpag_var.vgapo(2).dtiniciorelacao;
      pkgpag_var.vgapo.delete(2);
      pkgpag_var.vgapo(1).dtinicio := pkgpag_var.vgFolha.DtInicioMes;
    end if;

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de Instituidor com Aposentadoria com Paridade
  /*-------------------------------------------------------------------------*/

  PROCEDURE pArmazenaInstituidorApoComPar(pcdvinculo IN INTEGER) IS

    i INTEGER;

    vtapo pkgpag_tipo.tcef;

    vnunivelpagamento VARCHAR2(3);

    vnureferenciapagamento VARCHAR2(3);

    vcdestruturacarreira INTEGER;

    vcdestruturacarreiracarreira INTEGER;

    vCdHistNivelRefCefInativo INTEGER;

    --vDtInicioRefCefInativo    DATE;

    CURSOR capoparidade(pcdvinculo   IN INTEGER,
                        pcdorgao     IN INTEGER,
                        pdtiniciomes IN DATE,
                        pdtfimmes    IN DATE) IS
      WITH OB AS
       (SELECT O.cdpessoa as cdpessoa, O.dtobito as dtobito
          FROM eafaregistroobito O
         inner join ecadvinculo VI
            on VI.cdpessoa = O.cdpessoa
         WHERE o.flanulado = 'N'
           and VI.cdvinculo = pCdVinculo
           and O.cdagrupamento <> 132 -- agrupamento dos pensionistas
           and rownum < 2),

      SIT AS
       (select hsp.cdvinculo, hsp.cdsituacaoprevidenciaria
          from ecadhistsitprevvinculo hsp
         where hsp.dtinicio =
               (select max(hsp.dtinicio)
                  from ecadhistsitprevvinculo hsp
                 where cdvinculo = pCdVinculo
                   and hsp.cdsituacaoprevidenciaria <>
                       pkgpag_tipo.cnSitPrevInstPensao)
           and hsp.cdvinculo = pCdVinculo),

      APO AS
       (SELECT A.Cdvinculo,
               A.Cdconcessaoaposentadoria,
               A.Cdmodeloaposentadoria,
               A.DtInicioAposentadoria,
               A.dtfimaposentadoria,
               A.Dtinclusao,
               A.florigemcco,
               A.cdunidadeorganizacional,
               A.vlpercentpropapo,
               A.CdOrgaoExercicio
          FROM (SELECT ca.Cdvinculo,
                       ca.Cdconcessaoaposentadoria,
                       ca.Cdmodeloaposentadoria,
                       nvl(ret.dtinicioaposentadoria,
                           ca.DtInicioAposentadoria) as DtInicioAposentadoria,
                       nvl(ret.dtfimaposentadoria, ca.dtfimaposentadoria) as DtFimAposentadoria,
                       ca.Dtinclusao,
                       ca.florigemcco,
                       ca.cdunidadeorganizacional,
                       ca.vlpercentpropapo,
                       ca.CdOrgaoExercicio
                  FROM epvdconcessaoaposentadoria ca
                  left join epvdconcessaoaposentadoria ret
                    on ret.cdconcessaoaposentadoria =
                       ca.cdconcessaoaposentadoriaretif
                 INNER JOIN epvdmodeloaposentadoria ma
                    ON ca.cdmodeloaposentadoria = ma.cdmodeloaposentadoria
                 WHERE ca.CdVinculo = pCdVinculo
                   AND ca.CdOrgaoExercicio = pCdOrgao
                   AND ca.FlAtiva = 'S'
                   AND ca.FlAnulado = 'N'
                   AND ma.FlParidade = 'S'
                   AND NOT EXISTS
                 (SELECT 1
                          FROM epvdconcessaoaposentadoria ca2
                         INNER JOIN epvdmodeloaposentadoria ma2
                            ON ca2.cdmodeloaposentadoria =
                               ma2.cdmodeloaposentadoria
                         WHERE ca2.CdVinculo = pCdVinculo
                           AND ca2.CdOrgaoExercicio = pCdOrgao
                           AND ca2.FlAtiva = 'S'
                           AND ca2.FlAnulado = 'N'
                           AND ma2.FlParidade = 'N'
                           AND ca2.dtinicioaposentadoria >
                               ca.dtinicioaposentadoria)
                 ORDER BY ca.dtinicioaposentadoria DESC) A
         WHERE rownum < 2)

      SELECT ca.cdvinculo,
             4 AS cdrelacaovinculo,
             ca.cdconcessaoaposentadoria AS cdhistrelvinc,
             cef.cdrelacaotrabalho,
             v.cdregimetrabalho,
             0 AS cdnaturezavinculo,
             v.cdregimeprevidenciario,
             s.cdsituacaoprevidenciaria,
             cef.cdestruturacarreira,
             ec.cdestruturacarreiracarreira,
             CASE
               WHEN ca.dtinicioaposentadoria < pdtiniciomes THEN
                pdtiniciomes
               ELSE
                ca.dtinicioaposentadoria
             END AS dtinicio,
             pdtfimmes AS dtfim,
             ca.dtinicioaposentadoria AS dtiniciorelacao,
             ca.dtfimaposentadoria AS dtfimrelacao,
             cef.cdhistcargoefetivo,
             cef.nunivelpagamento,
             cef.nureferenciapagamento,
             ca.vlpercentpropapo,
             ca.cdmodeloaposentadoria,
             cef.cdorgaoexercicio,
             cef.flprincipal,
             ca.cdunidadeorganizacional,
             ca.florigemcco,
             cef.flefetivacao,
             0 AS nucargahoraria,
             NULL AS tidnucargahoraria,
             cef.cdorgaodestprocseletivo,
             cef.dtfimnovoprocessoseletivo,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             'N' AS flexercicioorigem,
             0 AS cdorgaodestmovimentacao,
             ca.dtinclusao,
             o.dtobito - 1 AS dtanteriorobito -- Data fim das relacoes
        FROM APO ca
       INNER JOIN ecadvinculo v
          ON ca.cdvinculo = v.cdvinculo
         AND ca.cdorgaoexercicio = v.cdorgao
       INNER JOIN SIT S
          ON s.cdvinculo = pCdVinculo
       INNER JOIN ecadhistcargoefetivo cef
          ON cef.cdvinculo = ca.cdvinculo
       INNER JOIN ecadestruturacarreira ec
          ON cef.cdestruturacarreira = ec.cdestruturacarreira
      -- busca apenas um registro de obito
        LEFT JOIN OB o
          on o.cdpessoa = v.cdpessoa

       WHERE CEF.CdRelacaotrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao
         AND CEF.FlEfetivacao = PKGPAG_TIPO.cnT
         AND CEF.DtFim =
             (SELECT MAX(dtFim)
                FROM ecadhistcargoefetivo cef
               WHERE CEF.CdVinculo = pCdVinculo
                 AND CEF.CdRelacaoTrabalho <>
                     PKGPAG_TIPO.cnRelTrabDisposicao
                 AND CEF.FlEfetivacao = PKGPAG_TIPO.cnT
                 AND CEF.FlAnulado = PKGPAG_TIPO.cnN);

  BEGIN
 
    pkgpag_var.vgapo := vtapo;

    i := 0;

    FOR vAPOParidade IN cAPOParidade(pCdVinculo,
                                     PKGPAG_VAR.vgFolha.CdOrgao,
                                     pkgpag_var.vgfolha.dtiniciomes,
                                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      i := i + 1;

      --PKGPAG_VAR.vgAPO(i) := vAPOParidade;

      pkgpag_var.vgapo(i).cdvinculo := vapoparidade.cdvinculo;
      pkgpag_var.vgapo(i).cdrelacaovinculo := vapoparidade.cdrelacaovinculo;
      pkgpag_var.vgapo(i).cdhistrelvinc := vapoparidade.cdhistrelvinc;
      pkgpag_var.vgapo(i).cdrelacaotrabalho := vapoparidade.cdrelacaotrabalho;
      pkgpag_var.vgapo(i).cdregimetrabalho := vapoparidade.cdregimetrabalho;
      pkgpag_var.vgapo(i).cdnaturezavinculo := vapoparidade.cdnaturezavinculo;
      pkgpag_var.vgapo(i).cdregimeprevidenciario := vapoparidade.cdregimeprevidenciario;
      pkgpag_var.vgapo(i).cdsituacaoprevidenciaria := vapoparidade.cdsituacaoprevidenciaria;
      pkgpag_var.vgapo(i).cdestruturacarreira := vapoparidade.cdestruturacarreira;
      pkgpag_var.vgapo(i).cdestruturacarreiracarreira := vapoparidade.cdestruturacarreiracarreira;
      pkgpag_var.vgapo(i).dtinicio := vapoparidade.dtinicio;
      pkgpag_var.vgapo(i).dtfim := vapoparidade.dtfim;
      pkgpag_var.vgapo(i).dtiniciorelacao := vapoparidade.dtiniciorelacao;
      pkgpag_var.vgapo(i).dtfimrelacao := vapoparidade.dtfimrelacao;
      pkgpag_var.vgapo(i).cdhistcargoefetivo := vapoparidade.cdhistcargoefetivo;
      pkgpag_var.vgapo(i).nunivelpagamento := vapoparidade.nunivelpagamento;
      pkgpag_var.vgapo(i).nureferenciapagamento := vapoparidade.nureferenciapagamento;
      pkgpag_var.vgapo(i).vlpercentpropapo := vapoparidade.vlpercentpropapo;
      pkgpag_var.vgapo(i).cdmodeloaposentadoria := vapoparidade.cdmodeloaposentadoria;
      pkgpag_var.vgapo(i).cdorgaoexercicio := vapoparidade.cdorgaoexercicio;
      pkgpag_var.vgapo(i).flprincipal := vapoparidade.flprincipal;
      pkgpag_var.vgapo(i).cdunidadeorganizacional := vapoparidade.cdunidadeorganizacional;
      pkgpag_var.vgapo(i).florigemcco := vapoparidade.florigemcco;
      pkgpag_var.vgapo(i).flefetivacao := vapoparidade.flefetivacao;
      pkgpag_var.vgapo(i).nucargahoraria := vapoparidade.nucargahoraria;
      pkgpag_var.vgapo(i).tidnucargahoraria := NULL;
      pkgpag_var.vgapo(i).cdorgaodestprocseletivo := vapoparidade.cdorgaodestprocseletivo;
      pkgpag_var.vgapo(i).dtfimnovoprocessoseletivo := vapoparidade.dtfimnovoprocessoseletivo;
      pkgpag_var.vgapo(i).cdmotivomovimentacao := vapoparidade.cdmotivomovimentacao;
      pkgpag_var.vgapo(i).cdinstitutomovimentacao := vapoparidade.cdinstitutomovimentacao;
      pkgpag_var.vgapo(i).flexercicioorigem := vapoparidade.flexercicioorigem;
      pkgpag_var.vgapo(i).cdorgaodestmovimentacao := vapoparidade.cdorgaodestmovimentacao;
      pkgpag_var.vgapo(i).dtinclusao := vapoparidade.dtinclusao;

      ------------------------------------------------------------
      -- Seleciona a carga horaria na data do calculo
      ------------------------------------------------------------

      -- PRIORIZA CARGA HORARIA DO APOSENTADO
      BEGIN

        SELECT nucargahoraria
          INTO pkgpag_var.vgapo(i).nucargahoraria
          FROM (SELECT nucargahoraria
                  FROM ecadhistcargahoraria cho
                 WHERE CHO.Cdconcessaoaposentadoria =
                       vAPOParidade.cdhistrelvinc
                   AND CHO.FlAnulado = 'N'
                   AND CHO.DtInicial <= PKGPAG_VAR.vgFolha.DtFimMes /*AND
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              CHO.FlTipoOcupacao = 'D'*/
                 ORDER BY DtInicial DESC)
         WHERE ROWNUM < 2;

        -- SE NAO ENCONTROU, BUSCA CARGA HORARIA DO EFETIVO
      EXCEPTION

        WHEN no_data_found THEN

          BEGIN

            SELECT nucargahoraria
              INTO pkgpag_var.vgapo(i).nucargahoraria
              FROM (SELECT nucargahoraria
                      FROM ecadhistcargahoraria cho
                     WHERE CHO.CdHistCargoEfetivo =
                           vAPOParidade.CdHistCargoEfetivo
                       AND CHO.FlAnulado = 'N'
                       AND CHO.DtInicial <= PKGPAG_VAR.vgFolha.DtFimMes
                       AND CHO.FlTipoOcupacao = 'D'
                     ORDER BY DtInicial DESC)
             WHERE ROWNUM < 2;

          EXCEPTION

            WHEN no_data_found THEN

              NULL;

          END;

      END;
      /*---------------------------------------------------------------------------------*/
      -- Verifica se existe progressao da aposentadoria na tabela ecadhistnivelrefcefinativo
      /*----------------------------------------------------------------------------------*/

      pkgpag_var.vgapo(i).nunivelpagamentocef := pkgpag_var.vgapo(i).nunivelpagamento;

      pkgpag_var.vgapo(i).nureferenciapagamentocef := pkgpag_var.vgapo(i).nureferenciapagamento;

      pkgpag_var.vgapo(i).cdestruturacarreiracef := pkgpag_var.vgapo(i).cdestruturacarreira;

      pkgpag_var.vgapo(i).cdestruturacarreiracarreiracef := pkgpag_var.vgapo(i).cdestruturacarreiracarreira;

      FOR APO IN (SELECT ca.cdconcessaoaposentadoria,
                         ca.cdvinculo,
                         ca.dtretificacao
                    FROM epvdconcessaoaposentadoria ca
                    left join epvdconcessaoaposentadoria ret
                      on ret.cdconcessaoaposentadoriaretif =
                         ca.cdconcessaoaposentadoria
                   WHERE ca.cdvinculo = pCdVinculo
                     AND CA.CdOrgaoExercicio = pkgpag_var.vgfolha.CdOrgao
                     AND CA.FlAtiva = PKGPAG_TIPO.cnS
                     AND CA.FlAnulado = PKGPAG_TIPO.cnN
                     and ((ca.dtinicioaposentadoria <
                         pkgpag_var.vgFolha.DtFimMes and
                         ret.dtinicioaposentadoria is not null and
                         ret.dtinicioaposentadoria >
                         pkgpag_var.vgFolha.DtFimMes) or
                         (ret.dtinicioaposentadoria is null and
                         ca.dtinicioaposentadoria <
                         pkgpag_var.vgFolha.DtFimMes))
                         ORDER BY 1) LOOP

        BEGIN
          SELECT I2.CDHISTNIVELREFCEFINATIVO
            INTO vCdHistNivelRefCefInativo
            FROM ecadhistnivelrefcefinativo i2
           WHERE I2.CdConcessaoAposentadoria = APO.CDCONCESSAOAPOSENTADORIA
             AND I2.FlAnulado = 'N'
             AND I2.DTINICIO = (SELECT max(I3.DTINICIO)
                                  FROM ecadhistnivelrefcefinativo i3
                                 WHERE I3.CdConcessaoAposentadoria =
                                       APO.CDCONCESSAOAPOSENTADORIA
                                   AND I3.FlAnulado = 'N')
             AND ROWNUM < 2;


          SELECT ECINA.NuNivelPagamento,
                 ECINA.NuReferenciaPagamento,
                 ec.cdestruturacarreira,
                 ec.cdestruturacarreiracarreira
            INTO vNuNivelPagamento,
                 vNuReferenciaPagamento,
                 vCdEstruturaCarreira,
                 vCdEstruturaCarreiraCarreira
            FROM ecadhistnivelrefcefinativo ECINA
            LEFT JOIN ecadestruturacarreira ec
              ON ec.cdestruturacarreira = ECiNA.cdestruturacarreira
             AND ec.flanulado = 'N'
           WHERE ECiNA.cdhistnivelrefcefinativo = vCdHistNivelRefCefInativo;

          pkgpag_var.vgapo(i).nunivelpagamento := vnunivelpagamento;

          pkgpag_var.vgapo(i).nureferenciapagamento := vnureferenciapagamento;

        EXCEPTION

          WHEN OTHERS THEN

            NULL;

        END;

        -- Se encontrou cdestrutura carreira em ecadhistnivelrefcefinativo utiliza esta
        IF vCdEstruturaCarreira IS NOT NULL THEN

          pkgpag_var.vgapo(i).cdestruturacarreira := vcdestruturacarreira;

          pkgpag_var.vgapo(i).cdestruturacarreiracarreira := vcdestruturacarreiracarreira;

        ELSE

          BEGIN

            SELECT EC.CDESTRUTURACARREIRA, EC.CDESTRUTURACARREIRACARREIRA
              INTO vCdEstruturaCarreira, vcdestruturacarreiracarreira
              FROM emovmudancacargoefetivoinativo m
             INNER JOIN ecadestruturacarreira ec
                ON m.cdestruturacarreiradestino = ec.cdestruturacarreira
             WHERE M.CdConcessaoAposentadoria =
                   APO.Cdconcessaoaposentadoria
               AND M.FlAnulado = 'N'
               AND M.DTMUDANCA = (SELECT MAX(M1.DTMUDANCA)
                                    FROM emovmudancacargoefetivoinativo m1
                                   WHERE M1.CdConcessaoAposentadoria =
                                         APO.Cdconcessaoaposentadoria
                                     AND M1.FlAnulado = 'N');

            pkgpag_var.vgapo(i).cdestruturacarreira := vcdestruturacarreira;

            pkgpag_var.vgapo(i).cdestruturacarreiracarreira := vcdestruturacarreiracarreira;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                pkgpag_var.vgapo(i).cdestruturacarreira := vapoparidade.cdestruturacarreira;
                pkgpag_var.vgapo(i).cdestruturacarreiracarreira := vapoparidade.cdestruturacarreiracarreira;
              END;

            WHEN OTHERS THEN

              NULL;

          END;

        END IF;

      END LOOP;

      -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
      -- e o codigo da relacao de vinculo

      pkgpag_var.vgrelvincprincipal.tipo := 4;

      pkgpag_var.vgrelvincprincipal.cdhist := vapoparidade.cdhistrelvinc;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vapoparidade.cdunidadeorganizacional;

      pkgpag_var.vgNuDiasApo := pkgpag_var.vgNuDiasApo +
                                (pkgpag_var.vgapo(i).dtfim - pkgpag_var.vgapo(i).dtinicio + 1);

    END LOOP;

    if pkgpag_var.vgNuDiasApo < 30 and
       pkgpag_var.vgNuDiasApo =
       to_number(to_char(pkgpag_var.vgFolha.DtFimMes, 'DD')) then
      pkgpag_var.vgNuDiasApo := 30;
    end if;

    -- Sem intersticio e com 2 aposentadorias, deixa so o ultimo
    if pkgpag_var.vgNuDiasApo = 30 and pkgpag_var.vgapo.count = 2 then
      pkgpag_var.vgapo(1).dtiniciorelacao := pkgpag_var.vgapo(2).dtiniciorelacao;
      pkgpag_var.vgapo.delete(2);
      pkgpag_var.vgapo(1).dtinicio := pkgpag_var.vgFolha.DtInicioMes;
    end if;

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de Aposentadoria sem Paridade
  /*-------------------------------------------------------------------------*/

  PROCEDURE pArmazenaInstituidorApoSemPar(pcdvinculo IN INTEGER) IS

    i INTEGER;

    vtaposemparidade pkgpag_tipo.tcef;

    CURSOR caposemparidade(pcdvinculo   IN INTEGER,
                           pcdorgao     IN INTEGER,
                           pdtiniciomes IN DATE,
                           pdtfimmes    IN DATE) IS

      WITH OB AS -- Busca os dados do obito
       (SELECT O.cdpessoa as cdpessoa, O.dtobito as dtobito
          FROM eafaregistroobito O
         inner join ecadvinculo VI
            on VI.cdpessoa = O.cdpessoa
         WHERE o.flanulado = PKGPAG_TIPO.cnN
           and VI.cdvinculo = pCdVinculo
           and O.cdagrupamento <> 132 -- agrupamento dos pensionistas
           and rownum < 2),
      SIT AS
       (select hsp.cdsituacaoprevidenciaria, hsp.cdvinculo
          from ecadhistsitprevvinculo hsp
         where hsp.dtinicio =
               (select max(hsp.dtinicio)
                  from ecadhistsitprevvinculo hsp
                 where cdvinculo = pCdVinculo
                   and hsp.cdsituacaoprevidenciaria <>
                       pkgpag_tipo.cnSitPrevInstPensao)
           and hsp.cdvinculo = pCdVinculo),
      APO AS
       (SELECT A.Cdvinculo,
               A.Cdconcessaoaposentadoria,
               A.Cdmodeloaposentadoria,
               A.DtInicioAposentadoria,
               A.dtfimaposentadoria,
               A.Dtinclusao,
               A.florigemcco,
               A.cdunidadeorganizacional,
               A.vlpercentpropapo,
               a.cdorgaoexercicio
          FROM (SELECT ca.Cdvinculo,
                       ca.Cdconcessaoaposentadoria,
                       ca.Cdmodeloaposentadoria,
                       nvl(ret.dtinicioaposentadoria,
                           ca.DtInicioAposentadoria) as DtInicioAposentadoria,
                       nvl(ret.dtfimaposentadoria, ca.dtfimaposentadoria) as DtFimAposentadoria,
                       ca.Dtinclusao,
                       ca.florigemcco,
                       ca.cdunidadeorganizacional,
                       ca.vlpercentpropapo,
                       ca.cdorgaoexercicio
                  FROM epvdconcessaoaposentadoria ca
                  left join epvdconcessaoaposentadoria ret
                    on ret.cdconcessaoaposentadoria =
                       ca.cdconcessaoaposentadoriaretif
                 INNER JOIN epvdmodeloaposentadoria ma
                    ON ca.cdmodeloaposentadoria = ma.cdmodeloaposentadoria
                 WHERE ca.CdVinculo = pCdVinculo
                   AND ca.CdOrgaoExercicio = pCdOrgao
                   AND ca.FlAtiva = 'S'
                   AND ca.FlAnulado = 'N'
                   AND ma.FlParidade = 'N'
                   AND NOT EXISTS
                 (SELECT 1
                          FROM epvdconcessaoaposentadoria ca2
                         INNER JOIN epvdmodeloaposentadoria ma2
                            ON ca2.cdmodeloaposentadoria =
                               ma2.cdmodeloaposentadoria
                         WHERE ca2.CdVinculo = pCdVinculo
                           AND ca2.CdOrgaoExercicio = pCdOrgao
                           AND ca2.FlAtiva = 'S'
                           AND ca2.FlAnulado = 'N'
                           AND ma2.FlParidade = 'S'
                           AND ca2.dtinicioaposentadoria >
                               ca.dtinicioaposentadoria)
                 ORDER BY ca.dtinicioaposentadoria DESC) A
         WHERE rownum < 2)

      SELECT ca.cdvinculo,
             4 AS cdrelacaovinculo,
             ca.cdconcessaoaposentadoria AS cdhistrelvinc,
             0 AS cdrelacaotrabalho,
             v.cdregimetrabalho,
             0 AS cdnaturezavinculo,
             v.cdregimeprevidenciario,
             s.cdsituacaoprevidenciaria,
             0 AS cdestruturacarreira,
             0 AS cdestruturacarreiracarreira,
             CASE
               WHEN ca.dtinicioaposentadoria < pdtiniciomes THEN
                pdtiniciomes
               ELSE
                ca.dtinicioaposentadoria
             END AS dtinicio,
             pdtfimmes AS dtfim,
             ca.dtinicioaposentadoria AS dtiniciorelacao,
             ca.dtfimaposentadoria AS dtfimrelacao,
             0 AS cdhistcargoefetivo,
             '0' AS nunivelpagamento,
             '0' AS nureferenciapagamento,
             ca.vlpercentpropapo,
             ca.cdmodeloaposentadoria,
             0 AS cdorgaoexercicio,
             NULL AS flprincipal,
             ca.cdunidadeorganizacional,
             ca.florigemcco,
             '' AS flefetivacao,
             0 AS nucargahoraria,
             NULL AS tidnucargahoraria,
             0 AS cdorgaodestprocseletivo,
             pdtiniciomes AS dtfimnovoprocessoseletivo,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             'N' AS flexercicioorigem,
             0 AS cdorgaodestmovimentacao,
             ca.dtinclusao,
             o.dtobito - 1 AS dtanteriorobito -- Data fim das relacoes
        FROM APO ca
       INNER JOIN ecadvinculo v
          ON ca.cdvinculo = v.cdvinculo
         AND ca.cdorgaoexercicio = v.cdorgao
       INNER JOIN SIT S
          ON s.cdvinculo = pCdVinculo
        LEFT JOIN OB o
          on o.cdpessoa = v.cdpessoa
       ORDER BY ca.dtinicioaposentadoria DESC;

  BEGIN
 
    pkgpag_var.vgaposemparidade := vtaposemparidade;

    i := 0;

    FOR vaposemparidade IN caposemparidade(pcdvinculo,
                                           pkgpag_var.vgfolha.cdorgao,
                                           pkgpag_var.vgfolha.dtiniciomes,
                                           PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      i := i + 1;

      -- PKGPAG_VAR.vgAPOSemParidade(i) := vAPOSemParidade;

      pkgpag_var.vgaposemparidade(i).cdvinculo := vaposemparidade.cdvinculo;
      pkgpag_var.vgaposemparidade(i).cdrelacaovinculo := vaposemparidade.cdrelacaovinculo;
      pkgpag_var.vgaposemparidade(i).cdhistrelvinc := vaposemparidade.cdhistrelvinc;
      pkgpag_var.vgaposemparidade(i).cdrelacaotrabalho := vaposemparidade.cdrelacaotrabalho;
      pkgpag_var.vgaposemparidade(i).cdregimetrabalho := vaposemparidade.cdregimetrabalho;
      pkgpag_var.vgaposemparidade(i).cdnaturezavinculo := vaposemparidade.cdnaturezavinculo;
      pkgpag_var.vgaposemparidade(i).cdregimeprevidenciario := vaposemparidade.cdregimeprevidenciario;
      pkgpag_var.vgaposemparidade(i).cdsituacaoprevidenciaria := vaposemparidade.cdsituacaoprevidenciaria;
      pkgpag_var.vgaposemparidade(i).cdestruturacarreira := vaposemparidade.cdestruturacarreira;
      pkgpag_var.vgaposemparidade(i).cdestruturacarreiracarreira := vaposemparidade.cdestruturacarreiracarreira;
      pkgpag_var.vgaposemparidade(i).dtinicio := vaposemparidade.dtinicio;
      pkgpag_var.vgaposemparidade(i).dtfim := vaposemparidade.dtfim;
      pkgpag_var.vgaposemparidade(i).dtiniciorelacao := vaposemparidade.dtiniciorelacao;
      pkgpag_var.vgaposemparidade(i).dtfimrelacao := vaposemparidade.dtfimrelacao;
      pkgpag_var.vgaposemparidade(i).cdhistcargoefetivo := vaposemparidade.cdhistcargoefetivo;
      pkgpag_var.vgaposemparidade(i).nunivelpagamento := vaposemparidade.nunivelpagamento;
      pkgpag_var.vgaposemparidade(i).nureferenciapagamento := vaposemparidade.nureferenciapagamento;
      pkgpag_var.vgaposemparidade(i).vlpercentpropapo := vaposemparidade.vlpercentpropapo;
      pkgpag_var.vgaposemparidade(i).cdmodeloaposentadoria := vaposemparidade.cdmodeloaposentadoria;
      pkgpag_var.vgaposemparidade(i).cdorgaoexercicio := vaposemparidade.cdorgaoexercicio;
      pkgpag_var.vgaposemparidade(i).flprincipal := vaposemparidade.flprincipal;
      pkgpag_var.vgaposemparidade(i).cdunidadeorganizacional := vaposemparidade.cdunidadeorganizacional;
      pkgpag_var.vgaposemparidade(i).florigemcco := vaposemparidade.florigemcco;
      pkgpag_var.vgaposemparidade(i).flefetivacao := vaposemparidade.flefetivacao;
      pkgpag_var.vgaposemparidade(i).nucargahoraria := vaposemparidade.nucargahoraria;
      pkgpag_var.vgaposemparidade(i).tidnucargahoraria := NULL;
      pkgpag_var.vgaposemparidade(i).cdorgaodestprocseletivo := vaposemparidade.cdorgaodestprocseletivo;
      pkgpag_var.vgaposemparidade(i).dtfimnovoprocessoseletivo := vaposemparidade.dtfimnovoprocessoseletivo;
      pkgpag_var.vgaposemparidade(i).cdmotivomovimentacao := vaposemparidade.cdmotivomovimentacao;
      pkgpag_var.vgaposemparidade(i).cdinstitutomovimentacao := vaposemparidade.cdinstitutomovimentacao;
      pkgpag_var.vgaposemparidade(i).flexercicioorigem := vaposemparidade.flexercicioorigem;
      pkgpag_var.vgaposemparidade(i).cdorgaodestmovimentacao := vaposemparidade.cdorgaodestmovimentacao;
      pkgpag_var.vgaposemparidade(i).dtinclusao := vaposemparidade.dtinclusao;

      -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
      -- e o codigo da relacao de vinculo

      pkgpag_var.vgrelvincprincipal.tipo := 4;

      pkgpag_var.vgrelvincprincipal.cdhist := vaposemparidade.cdhistrelvinc;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vaposemparidade.cdunidadeorganizacional;

    END LOOP;

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de Aposentadoria sem Paridade
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaoaposemparidade(pcdvinculo IN INTEGER) IS

    i INTEGER;

    vtaposemparidade pkgpag_tipo.tcef;

    CURSOR caposemparidade(pcdvinculo   IN INTEGER,
                           pcdorgao     IN INTEGER,
                           pdtiniciomes IN DATE,
                           pdtfimmes    IN DATE) IS

      SELECT ca.cdvinculo,
             4 AS cdrelacaovinculo,
             ca.cdconcessaoaposentadoria AS cdhistrelvinc,
             0 AS cdrelacaotrabalho,
             v.cdregimetrabalho,
             0 AS cdnaturezavinculo,
             v.cdregimeprevidenciario,
             hsp.cdsituacaoprevidenciaria,
             0 AS cdestruturacarreira,
             0 AS cdestruturacarreiracarreira,
             CASE
               WHEN ca.dtinicioaposentadoria < pdtiniciomes THEN
                pdtiniciomes
               ELSE
                ca.dtinicioaposentadoria
             END AS dtinicio,
             CASE
               WHEN ca.dtfimaposentadoria IS NULL THEN
                pdtfimmes
               ELSE
                ca.dtfimaposentadoria
             END AS dtfim,
             ca.dtinicioaposentadoria AS dtiniciorelacao,
             ca.dtfimaposentadoria AS dtfimrelacao,
             0 AS cdhistcargoefetivo,
             '0' AS nunivelpagamento,
             '0' AS nureferenciapagamento,
             ca.vlpercentpropapo,
             ca.cdmodeloaposentadoria,
             0 AS cdorgaoexercicio,
             NULL AS flprincipal,
             ca.cdunidadeorganizacional,
             ca.florigemcco,
             '' AS flefetivacao,
             0 AS nucargahoraria,
             NULL AS tidnucargahoraria,
             0 AS cdorgaodestprocseletivo,
             pdtiniciomes AS dtfimnovoprocessoseletivo,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             'N' AS flexercicioorigem,
             0 AS cdorgaodestmovimentacao,
             ca.dtinclusao
        FROM epvdconcessaoaposentadoria ca
       INNER JOIN ecadvinculo v
          ON ca.cdvinculo = v.cdvinculo
       INNER JOIN epvdmodeloaposentadoria ma
          ON ca.cdmodeloaposentadoria = ma.cdmodeloaposentadoria
       INNER JOIN ecadhistsitprevvinculo hsp
          ON CA.CdVinculo = HSP.CdVinculo
         AND (CA.DtInicioAposentadoria BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       WHERE V.CdVinculo = pCdVinculo
         AND CA.FlAnulado = PKGPAG_TIPO.cnN
         AND CA.FlAtiva = PKGPAG_TIPO.cnS
         AND CA.CdOrgaoExercicio = pCdOrgao
         AND MA.FlParidade = PKGPAG_TIPO.cnN
         AND ((CA.Dtinicioaposentadoria <= pdtFimMes) AND
             (CA.DtFimaposentadoria >= pdtInicioMes OR
             CA.DtFimaposentadoria IS NULL))
       ORDER BY ca.dtinicioaposentadoria DESC;

  BEGIN
 
    pkgpag_var.vgaposemparidade := vtaposemparidade;

    i := 0;

    FOR vaposemparidade IN caposemparidade(pcdvinculo,
                                           pkgpag_var.vgfolha.cdorgao,
                                           pkgpag_var.vgfolha.dtiniciomes,
                                           PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      i := i + 1;

      -- PKGPAG_VAR.vgAPOSemParidade(i) := vAPOSemParidade;

      pkgpag_var.vgaposemparidade(i).cdvinculo := vaposemparidade.cdvinculo;
      pkgpag_var.vgaposemparidade(i).cdrelacaovinculo := vaposemparidade.cdrelacaovinculo;
      pkgpag_var.vgaposemparidade(i).cdhistrelvinc := vaposemparidade.cdhistrelvinc;
      pkgpag_var.vgaposemparidade(i).cdrelacaotrabalho := vaposemparidade.cdrelacaotrabalho;
      pkgpag_var.vgaposemparidade(i).cdregimetrabalho := vaposemparidade.cdregimetrabalho;
      pkgpag_var.vgaposemparidade(i).cdnaturezavinculo := vaposemparidade.cdnaturezavinculo;
      pkgpag_var.vgaposemparidade(i).cdregimeprevidenciario := vaposemparidade.cdregimeprevidenciario;
      pkgpag_var.vgaposemparidade(i).cdsituacaoprevidenciaria := vaposemparidade.cdsituacaoprevidenciaria;
      pkgpag_var.vgaposemparidade(i).cdestruturacarreira := vaposemparidade.cdestruturacarreira;
      pkgpag_var.vgaposemparidade(i).cdestruturacarreiracarreira := vaposemparidade.cdestruturacarreiracarreira;
      pkgpag_var.vgaposemparidade(i).dtinicio := vaposemparidade.dtinicio;
      pkgpag_var.vgaposemparidade(i).dtfim := vaposemparidade.dtfim;
      pkgpag_var.vgaposemparidade(i).dtiniciorelacao := vaposemparidade.dtiniciorelacao;
      pkgpag_var.vgaposemparidade(i).dtfimrelacao := vaposemparidade.dtfimrelacao;
      pkgpag_var.vgaposemparidade(i).cdhistcargoefetivo := vaposemparidade.cdhistcargoefetivo;
      pkgpag_var.vgaposemparidade(i).nunivelpagamento := vaposemparidade.nunivelpagamento;
      pkgpag_var.vgaposemparidade(i).nureferenciapagamento := vaposemparidade.nureferenciapagamento;
      pkgpag_var.vgaposemparidade(i).vlpercentpropapo := vaposemparidade.vlpercentpropapo;
      pkgpag_var.vgaposemparidade(i).cdmodeloaposentadoria := vaposemparidade.cdmodeloaposentadoria;
      pkgpag_var.vgaposemparidade(i).cdorgaoexercicio := vaposemparidade.cdorgaoexercicio;
      pkgpag_var.vgaposemparidade(i).flprincipal := vaposemparidade.flprincipal;
      pkgpag_var.vgaposemparidade(i).cdunidadeorganizacional := vaposemparidade.cdunidadeorganizacional;
      pkgpag_var.vgaposemparidade(i).florigemcco := vaposemparidade.florigemcco;
      pkgpag_var.vgaposemparidade(i).flefetivacao := vaposemparidade.flefetivacao;
      pkgpag_var.vgaposemparidade(i).nucargahoraria := vaposemparidade.nucargahoraria;
      pkgpag_var.vgaposemparidade(i).tidnucargahoraria := NULL;
      pkgpag_var.vgaposemparidade(i).cdorgaodestprocseletivo := vaposemparidade.cdorgaodestprocseletivo;
      pkgpag_var.vgaposemparidade(i).dtfimnovoprocessoseletivo := vaposemparidade.dtfimnovoprocessoseletivo;
      pkgpag_var.vgaposemparidade(i).cdmotivomovimentacao := vaposemparidade.cdmotivomovimentacao;
      pkgpag_var.vgaposemparidade(i).cdinstitutomovimentacao := vaposemparidade.cdinstitutomovimentacao;
      pkgpag_var.vgaposemparidade(i).flexercicioorigem := vaposemparidade.flexercicioorigem;
      pkgpag_var.vgaposemparidade(i).cdorgaodestmovimentacao := vaposemparidade.cdorgaodestmovimentacao;
      pkgpag_var.vgaposemparidade(i).dtinclusao := vaposemparidade.dtinclusao;

      -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
      -- e o codigo da relacao de vinculo

      pkgpag_var.vgrelvincprincipal.tipo := 4;

      pkgpag_var.vgrelvincprincipal.cdhist := vaposemparidade.cdhistrelvinc;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vaposemparidade.cdunidadeorganizacional;

      pkgpag_var.vgNuDiasApo := pkgpag_var.vgNuDiasApo +
                                (pkgpag_var.vgaposemparidade(i).dtfim - pkgpag_var.vgaposemparidade(i).dtinicio + 1);

    END LOOP;

    if pkgpag_var.vgNuDiasApo < 30 and
       pkgpag_var.vgNuDiasApo =
       to_number(to_char(pkgpag_var.vgFolha.DtFimMes, 'DD')) then
      pkgpag_var.vgNuDiasApo := 30;
    end if;

    -- Sem intersticio e com 2 aposentadorias, deixa so o ultimo
    if pkgpag_var.vgNuDiasApo = 30 and
       pkgpag_var.vgaposemparidade.count = 2 then
      pkgpag_var.vgaposemparidade(1).dtiniciorelacao := pkgpag_var.vgaposemparidade(2).dtiniciorelacao;
      pkgpag_var.vgaposemparidade.delete(2);
      pkgpag_var.vgaposemparidade(1).dtinicio := pkgpag_var.vgFolha.DtInicioMes;
    end if;

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de Bolsita
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaobolsista(pcdvinculo IN INTEGER) IS

    i INTEGER;

    vtbol pkgpag_tipo.tbol;

    /* Cursor cBOL: Seleciona as relacoes de vinculo de bolsistas  */

    CURSOR cbol(pcdvinculo   IN INTEGER,
                pdtiniciomes IN DATE,
                pdtfimmes    IN DATE) IS
      SELECT he.cdvinculoestagio,
             he.cdhistestagio,
             v.cdorgao AS cdorgaoexercicio,
             he.cdrelacaotrabalho,
             he.cdregimetrabalho,
             he.cdnaturezavinculo,
             hsp.cdsituacaoprevidenciaria,
             v.cdregimeprevidenciario,
             hp.cdhistprograma,
             he.flocupavagapne,
             he.cdgrauescolaridade,
             he.cdnivelformacao,
             he.cdcursoagrupador,
             he.cdcurso,
             CASE
               WHEN HE.DtInicio < pdtInicioMes THEN
                pdtiniciomes
               ELSE
                he.dtinicio
             END AS dtinicio,
             CASE
               WHEN HE.DtFim > pdtFimMes OR HE.DtFim IS NULL THEN
                pdtfimmes
               ELSE
                he.dtfim
             END AS dtfim,
             he.dtinicio AS dtiniciorelacao,
             he.dtfim AS dtfimrelacao,
             hp.vlbolsa,
             hp.vlbolsapne,
             nvl(echo.nucargahoraria, hp.nucargahoraria) as NuCargaHorariaPadrao,
             nvl(echo.nucargahoraria, hp.nucargahoraria),
             hp.nucargahorariapne,
             lt.cdunidadeorganizacional,
             he.cdprograma,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             hp.dtinclusao
        FROM ecadhistestagio he
       INNER JOIN ecadvinculo v
          ON v.cdvinculo = he.cdvinculoestagio
       INNER JOIN (SELECT LT.CdHistEstagio, MAX(DtInicio) AS DtInicio
                     FROM ecadlocaltrabalho lt
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                      AND LT.DtInicio <= pdtFimMes
                    GROUP BY lt.cdhistestagio) lt1
          ON lt1.cdhistestagio = he.cdhistestagio
       INNER JOIN ecadlocaltrabalho lt
          ON LT.CdHistEstagio = LT1.CdHistEstagio
         AND LT.DtInicio = LT1.DtInicio
         AND LT.FlAnulado = PKGPAG_TIPO.cnN
       INNER JOIN ebolhistprograma hp
          ON he.cdprograma = hp.cdprograma
        LEFT JOIN ecadhistcargahoraria echo
          ON echo.cdhistestagio = he.cdhistestagio
        LEFT JOIN ecadhistsitprevvinculo hsp
          ON HE.CdVinculoEstagio = HSP.CdVinculo
         AND (HE.DtInicio BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       WHERE V.CdVinculo = pCdVinculo
         AND (HE.DtInicio <= pdtFimMes AND HE.DtFim >= pdtInicioMes)
         AND (HP.DtInicioVigencia <= PKGPAG_VAR.vdtCalculo AND
             (HP.DtFimVigencia >= PKGPAG_VAR.vdtCalculo OR
             HP.dtFimVigencia IS NULL));

  BEGIN
 
    pkgpag_var.vgbol := vtbol;

    i := 0;

    FOR vBOL IN cBOL(pCdVinculo,
                     PKGPAG_VAR.vgFolha.DtInicioMes,
                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      i := i + 1;

      pkgpag_var.vgbol(i) := vbol;

      -------------------------------------------------------------------------------
      -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
      -- e o codigo da relacao de vinculo
      -------------------------------------------------------------------------------

      pkgpag_var.vgrelvincprincipal.tipo := 5;

      pkgpag_var.vgrelvincprincipal.cdhist := vbol.cdhistestagio;

      IF vbol.cdrelacaotrabalho = pkgpag_tipo.cnrelresidente THEN

        pkgpag_var.vgrelvincprincipal.cdreltrabpagamento := pkgpag_tipo.cnrelresidente;

      ELSIF vbol.cdrelacaotrabalho = pkgpag_tipo.cnrelpesquisador THEN

        pkgpag_var.vgrelvincprincipal.cdreltrabpagamento := pkgpag_tipo.cnrelpesquisador;

      ELSE

        pkgpag_var.vgrelvincprincipal.cdreltrabpagamento := pkgpag_tipo.cnrelestagiario;

      END IF;

      pkgpag_var.vglistareltrab(vbol.cdrelacaotrabalho) := vbol.cdrelacaotrabalho;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vbol.cdunidadeorganizacional;

    END LOOP;

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de efetivo
  /*-------------------------------------------------------------------------*/

  FUNCTION fUnidadeExercicioCEF(pCdHistCargoEfetivo IN INTEGER,
                                pDtInicio           IN DATE,
                                pDtFim              IN DATE) RETURN INTEGER IS

    vCdUnidadeOrganizacional INTEGER;

  BEGIN
 
    SELECT CDUNIDADEORGANIZACIONAL
      INTO vCdUnidadeOrganizacional
      FROM (SELECT 1                          NORDER,
                   LT.CDUNIDADEORGANIZACIONAL,
                   LT.DTINICIO                AS DTINICIO
              FROM ecadlocaltrabalho lt
             WHERE LT.CdHistCargoEfetivo = pCdHistCargoEfetivo
               AND LT.FlDefinitiva = 'N'
               AND LT.FlAnulado = 'N'
               AND LT.DtInicio <= pDtFim
               AND (LT.DtFim >= pDtInicio OR LT.DtFim IS NULL)

            UNION ALL

            SELECT 2                          NORDER,
                   LT.CDUNIDADEORGANIZACIONAL,
                   LT.DTINICIO                AS DTINICIO
              FROM ecadlocaltrabalho lt
             WHERE LT.CdHistCargoEfetivo = pCdHistCargoEfetivo
               AND LT.FlDefinitiva = 'S'
               AND LT.FlAnulado = 'N'
               AND LT.DtInicio <= pDtFim
               AND (LT.DtFim >= pDtInicio OR LT.DtFim IS NULL)

             ORDER BY NORDER, DTINICIO DESC)
     WHERE ROWNUM < 2;

    RETURN vCdUnidadeOrganizacional;

  END;

  PROCEDURE parmazenarelacaoefetivo(pcdvinculo   IN INTEGER,
                                    pflvalidapag IN CHAR DEFAULT 'S') IS

    i INTEGER;
    c INTEGER;

    vcefaux        pkgpag_tipo.rcef;
    vtcef          pkgpag_tipo.tcef;
    vtcargahoraria pkgpag_tipo.tCargaHoraria;

    TYPE rMotivoMov IS RECORD(
      CdMotivoMovimentacao    INTEGER,
      cdinstitutomovimentacao INTEGER,
      flexercicioorigem       CHAR(1));

    vmotivoinstituto rmotivomov;

    vdtincioanterior DATE;

    vSemIntersticioCEFAnterior BOOLEAN := FALSE;

    /* Cursor cCEF: Seleciona as relacoes de vinculo com os historicos de niveis e
    referencias vigentes no Ano/Mes de referencia e os respectivas
    datas de inicio e fim                                            */

    CURSOR ccef(pcdvinculo   IN INTEGER,
                pdtiniciomes IN DATE,
                pdtfimmes    IN DATE) IS
      SELECT ce.cdvinculo,
             1 AS cdrelacaovinculo,
             ce.cdhistcargoefetivo AS cdhistrelvinc,
             ce.cdrelacaotrabalho,
             ce.cdregimetrabalho,
             ce.cdnaturezavinculo,
             ce.cdregimeprevidenciario,
             hsp.cdsituacaoprevidenciaria,
             ce.cdestruturacarreira,
             ec.cdestruturacarreiracarreira,
             CASE
               WHEN CE.DtInicio < pdtInicioMes THEN
                pdtiniciomes
               ELSE
                ce.dtinicio
             END AS dtinicio,
             CASE
               WHEN CE.DtFim > pdtFimMes OR CE.DtFim IS NULL THEN
                pdtfimmes
               ELSE
                ce.dtfim
             END AS dtfim,
             ce.dtinicio AS dtiniciorelacao,
             ce.dtfim AS dtfimrelacao,
             ce.cdhistcargoefetivo,
             ce.nunivelpagamento,
             ce.nureferenciapagamento,
             0 AS vlpercentpropapo,
             ce.cdorgaoexercicio,
             ce.flprincipal,
             lt.cdunidadeorganizacional,
             NULL AS florigemcco,
             ce.flefetivacao,
             0 AS nucargahoraria,
             ce.cdorgaodestprocseletivo,
             ce.dtfimnovoprocessoseletivo,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             'N' AS flexercicioorigem,
             cdorgaodestmovimentacao,
             ce.dtinclusao,
             CASE
               WHEN cp.dtinicio IS NOT NULL THEN
                cp.dtinicio
               ELSE
                ce.dtinicio
             END AS dtinicioVinculo
        FROM ecadhistcargoefetivo ce
       INNER JOIN ecadhistsitprevvinculo hsp
          ON CE.CdVinculo = HSP.CdVinculo
         AND (CE.DtInicio BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       INNER JOIN ecadestruturacarreira ec
          ON ce.cdestruturacarreira = ec.cdestruturacarreira
       INNER JOIN (SELECT LT.CdHistCargoEfetivo, MAX(DtInicio) AS DtInicio
                     FROM ecadlocaltrabalho lt
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                      AND LT.DtInicio <= pdtFimMes
                      AND LT.CdHistCargoEfetivo IS NOT NULL
                    GROUP BY lt.cdhistcargoefetivo) lt1
          ON lt1.cdhistcargoefetivo = ce.cdhistcargoefetivo
       INNER JOIN ecadlocaltrabalho lt
          ON LT.CdHistCargoEfetivo = LT1.CdHistCargoEfetivo
         AND LT.DtInicio = LT1.DtInicio
         AND (LT.DtFim >= pdtInicioMes OR LT.DtFim IS NULL)
         AND LT.FlDefinitiva = 'S'
         AND LT.FlAnulado = PKGPAG_TIPO.cnN

      --Armazena a data inicio do vinculo
        left join (select min(cefp.Dtinicio) DtInicio, cefp.cdvinculo
                     from ecadhistcargoefetivo cefp
                    where cefp.flanulado = PKGPAG_TIPO.cnN
                      and cefp.flprincipal = PKGPAG_TIPO.cnS
                      and ((cefp.DtInicio <= pdtfimmes) AND
                          (cefp.dtFim >= pdtInicioMes OR cefp.dtFim IS NULL))
                      and cefp.cdvinculo = pCdVinculo
                    group by cdvinculo) cp
          on cp.cdvinculo = ce.cdvinculo

       WHERE (CE.CdVinculo = pCdVinculo)
         AND ((CE.DtInicio <= pdtFimMes) AND
             (CE.dtFim >= pdtInicioMes OR CE.dtFim IS NULL))
         AND CE.FlEfetivacao = PKGPAG_TIPO.cnT
         AND CE.FlAnulado = PKGPAG_TIPO.cnN
       ORDER BY decode(ce.cdrelacaotrabalho, 5, 99, ce.cdrelacaotrabalho),
                CE.DtInicio,
                EC.CdEstruturaCarreiraCarreira,
                CE.CdHistCargoEfetivo;
    --ORDER BY CE.DtInicio DESC,EC.CdEstruturaCarreiraCarreira, CE.CdHistCargoEfetivo;

    FUNCTION fretornamotivoinstituto(pcef IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pcco IN pkgpag_tipo.rcco DEFAULT NULL,
                                     papo IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pbol IN pkgpag_tipo.rbol DEFAULT NULL)
      RETURN rmotivomov IS

      vmotivomov rmotivomov;

    BEGIN
 
      IF pcef.cdvinculo IS NOT NULL THEN

        IF pcef.cdrelacaotrabalho = pkgpag_tipo.cnreltrabdisposicao THEN

          BEGIN

            SELECT m.cdmotivomovimentacao,
                   m.cdinstitutomovimentacao,
                   m.flexercicioorigem
              INTO vmotivomov.cdmotivomovimentacao,
                   vmotivomov.cdinstitutomovimentacao,
                   vmotivomov.flexercicioorigem
              FROM (SELECT m.cdmotivomovimentacao,
                           m.cdinstitutomovimentacao,
                           inst.flexercicioorigem
                      FROM eafaafastamentorelvinc av
                     INNER JOIN emovmovimentacao m
                        ON av.cdhistcargoefetivo = m.cdhistcargoefetivo
                     INNER JOIN Emovinstitutomovimentacao inst
                        on inst.cdinstitutomovimentacao =
                           M.CdInstitutoMovimentacao
                     WHERE AV.CdHistCargoEfetivoGerador = pCEF.CdHistRelVinc
                       AND AV.DtInicio <= PKGPAG_VAR.vDtCalculo
                       AND (AV.Dtfim >= PKGPAG_VAR.vDtCalculo OR
                           AV.Dtfim IS NULL)
                       AND AV.DtInicio = M.DtApresentacao
                       AND M.FlPagamentoOrigem = 'N'
                       AND AV.FlAnulado = PKGPAG_TIPO.cnN
                     ORDER BY m.dtapresentacao DESC) m
             WHERE rownum < 2;

            RETURN vmotivomov;

          EXCEPTION

            WHEN no_data_found THEN

              NULL;

          END;

        ELSIF pCEF.CdRelacaoTrabalho = PKGPAG_TIPO.cnRelTrabEfetivo AND
              pCEF.FlEfetivacao = 'T' THEN

          BEGIN

            SELECT m.cdmotivomovimentacao,
                   m.cdinstitutomovimentacao,
                   m.flexercicioorigem
              INTO vmotivomov.cdmotivomovimentacao,
                   vmotivomov.cdinstitutomovimentacao,
                   vmotivomov.flexercicioorigem
              FROM (SELECT m.cdmotivomovimentacao,
                           m.cdinstitutomovimentacao,
                           inst.flexercicioorigem
                      FROM emovmovimentacao m
                     INNER JOIN Emovinstitutomovimentacao inst
                        on INST.cdinstitutomovimentacao =
                           M.CdInstitutoMovimentacao
                     WHERE M.CdHistCargoEfetivo = pCEF.CdHistRelVinc
                       AND M.DtApresentacao <= pCEF.DtFim
                     ORDER BY m.dtapresentacao DESC) m
             WHERE rownum < 2;

            RETURN vmotivomov;

          EXCEPTION

            WHEN no_data_found THEN

              NULL;

          END;

        else
          null;
        END IF;

      END IF;

      RETURN vmotivomov;

    END;

  BEGIN
 
    pkgpag_var.bpagacef := FALSE;

    pkgpag_var.vgcef := vtcef;

    pkgpag_var.vgCargaHoraria := vtcargahoraria;

    pkgpag_var.btemefetivooutroorgao := FALSE;

    pkgpag_var.btemefetivoanyorgao := FALSE;

    i := 0;

    ----------------------------------------------------------------------------
    -- Armazena as faltas ocorridas durante o ano - Para calculo do 13 salario
    ----------------------------------------------------------------------------

    pkgpag_var.vgqtfaltas := pkgpag_geral.fqtfaltas(pcdvinculo => pkgpag_var.vgvinculo.cdvinculo,
                                                    pnuano     => pkgpag_var.vgfolha.nuanoreferencia);

    c := 0;

    FOR vCEF IN cCEF(pCdVinculo,
                     PKGPAG_VAR.vgFolha.DtInicioMes,
                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      ----------------------------------------------------------------------------
      -- Armazena as relacoes de trabalho de cargo efetivo do vinculo
      ----------------------------------------------------------------------------

      pkgpag_var.vglistareltrab(vcef.cdrelacaotrabalho) := vcef.cdrelacaotrabalho;

      ----------------------------------------------------------------------------
      -- Armazena a carreira do CEF para ser utilizada verificacao de abrangencia
      -- para as demais relacoes de vinculo (CCO e FUC)
      ----------------------------------------------------------------------------

      pkgpag_var.vgcdestruturacarreira := vcef.cdestruturacarreira;

      IF vcef.cdrelacaotrabalho = pkgpag_tipo.cnrelact THEN

        pkgpag_var.bpossuiact := TRUE;

      END IF;

      pkgpag_var.btemefetivoanyorgao := TRUE;

      IF vcef.cdorgaoexercicio <> pkgpag_var.vgfolha.cdorgao THEN

        pkgpag_var.btemefetivooutroorgao := TRUE;

        IF vdtincioanterior = vcef.dtfim + 1 THEN

          pkgpag_var.bsemintersticio := TRUE;

          vSemIntersticioCEFAnterior := TRUE;

        ELSE

          vSemIntersticioCEFAnterior := FALSE;

        END IF;

      END IF;

      -- Formatar para o tipo

      vcefaux.cdvinculo                   := vcef.cdvinculo;
      vcefaux.cdrelacaovinculo            := vcef.cdrelacaovinculo;
      vcefaux.cdhistrelvinc               := vcef.cdhistrelvinc;
      vcefaux.cdrelacaotrabalho           := vcef.cdrelacaotrabalho;
      vcefaux.cdregimetrabalho            := vcef.cdregimetrabalho;
      vcefaux.cdnaturezavinculo           := vcef.cdnaturezavinculo;
      vcefaux.cdregimeprevidenciario      := vcef.cdregimeprevidenciario;
      vcefaux.cdsituacaoprevidenciaria    := vcef.cdsituacaoprevidenciaria;
      vcefaux.cdestruturacarreira         := vcef.cdestruturacarreira;
      vcefaux.cdestruturacarreiracarreira := vcef.cdestruturacarreiracarreira;
      vcefaux.dtinicio                    := vcef.dtinicio;
      vcefaux.dtfim                       := vcef.dtfim;
      vcefaux.dtiniciorelacao             := vcef.dtiniciorelacao;
      vcefaux.dtfimrelacao                := vcef.dtfimrelacao;
      vcefaux.cdhistcargoefetivo          := vcef.cdhistcargoefetivo;
      vcefaux.nunivelpagamento            := vcef.nunivelpagamento;
      vcefaux.nureferenciapagamento       := vcef.nureferenciapagamento;
      vcefaux.vlpercentpropapo            := vcef.vlpercentpropapo;
      vcefaux.cdorgaoexercicio            := vcef.cdorgaoexercicio;
      vcefaux.flprincipal                 := vcef.flprincipal;
      vcefaux.florigemcco                 := vcef.florigemcco;
      vcefaux.flefetivacao                := vcef.flefetivacao;
      vcefaux.nucargahoraria              := vcef.nucargahoraria;
      vcefaux.tidnucargahoraria           := NULL;
      vcefaux.cdorgaodestprocseletivo     := vcef.cdorgaodestprocseletivo;
      vcefaux.dtfimnovoprocessoseletivo   := vcef.dtfimnovoprocessoseletivo;
      vcefaux.cdmotivomovimentacao        := vcef.cdmotivomovimentacao;
      vcefaux.cdinstitutomovimentacao     := vcef.cdinstitutomovimentacao;
      vcefaux.flexercicioorigem           := vcef.flexercicioorigem;
      vcefaux.cdorgaodestmovimentacao     := vcef.cdorgaodestmovimentacao;
      vcefaux.dtinclusao                  := vcef.dtinclusao;
      vcefaux.DtInicioVinculo             := vcef.dtinicioVinculo;
      vcefaux.NuCargaHorariaPadrao        := PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria;

      --
      -- Buscar Unidade Organizacional de Exercicio
      --

      BEGIN

        vcefaux.cdunidadeorganizacional := fUnidadeExercicioCEF(vcef.cdhistrelvinc,
                                                                PKGPAG_VAR.vgFolha.DtInicioMes,
                                                                PKGPAG_VAR.vgFolha.DtFimMes);

      EXCEPTION
        WHEN OTHERS THEN

          vcefaux.cdunidadeorganizacional := vcef.cdunidadeorganizacional;

      END;

      --
      -- Buscar carreira destino da ultima movimentacao no mes do calculo
      --

      BEGIN
        WITH MOV AS
         (SELECT EMC.CDESTRUTURACARREIRADESTINO
            FROM EMOVMOVCARGOEFETIVO EMC
           INNER JOIN EMOVMOVCARGOEFETIVOVINC EMV
              ON EMV.CDMOVCARGOEFETIVO = EMC.CDMOVCARGOEFETIVO
             AND EMV.CDVINCULO = vCef.CdVinculo
             AND EMC.FLANULADO = 'N'
             AND EMC.DTMOVIMENTACAO <= PKGPAG_VAR.vgFolha.DtFimMes
           ORDER BY EMC.DTMOVIMENTACAO DESC)
        SELECT MOV.CDESTRUTURACARREIRADESTINO,
               EC.CDESTRUTURACARREIRACARREIRA
          INTO vcefaux.cdestruturacarreira,
               vcefaux.cdestruturacarreiracarreira
          FROM MOV
         INNER JOIN ECADESTRUTURACARREIRA EC
            ON EC.CDESTRUTURACARREIRA = MOV.CDESTRUTURACARREIRADESTINO
         WHERE ROWNUM < 2;

      EXCEPTION
        WHEN OTHERS THEN
          vcefaux.cdestruturacarreira         := vcef.cdestruturacarreira;
          vcefaux.cdestruturacarreiracarreira := vcef.cdestruturacarreiracarreira;
      END;

      IF FPagaRemuneracaoCEF(PKGPAG_VAR.vgFolha, vCEFAux) OR
         pflvalidapag = 'N' OR vSemIntersticioCEFAnterior OR
         (vcef.cdorgaoexercicio = pkgpag_var.vgfolha.cdorgao AND
          PKGPAG_VAR.vgFolha.CdTipoFolha IN
          (PKGPAG_TIPO.cnTpFolhaAdiant13, PKGPAG_TIPO.cnTpFolha13)) THEN

        -- A ordenacao pega o cef de maior data inicio primeiro

        vdtincioanterior := vcefaux.dtinicio;

        i := i + 1;

        vtcef(i) := vcefaux;

        pkgpag_var.bpagacef := TRUE;

        ------------------------------------------------------------
        -- Carrega TID de Carga Horaria do mes
        ------------------------------------------------------------

        pkgtid.psetlimitar(ptid     => vtcef(i).tidnucargahoraria,
                           pdatamin => pkgpag_var.vgfolha.dtiniciomes,
                           pdatamax => pkgpag_var.vgfolha.dtfimmes);

        pkgtid.pmodosomar(ptid     => vtcef(i).tidnucargahoraria,
                          pflsomar => TRUE);

        FOR rec IN (SELECT dtinicial, dtfim, nucargahoraria
                      FROM ecadhistcargahoraria cho
                     WHERE CHO.CdHistCargoEfetivo =
                           vCEFAux.CdHistCargoEfetivo
                       AND CHO.FlAnulado = 'N'
                       AND CHO.DtInicial <= PKGPAG_VAR.vgFolha.DtFimMes
                       AND (CHO.DtFim >= PKGPAG_VAR.vgFolha.DtInicioMes OR
                           CHO.DtFim IS NULL)
                     ORDER BY dtinicial) LOOP

          pkgtid.pinserir(ptid     => vtcef(i).tidnucargahoraria,
                          PDataIni => rec.DtInicial,
                          PDataFim => rec.DtFim,
                          pvalor   => rec.nucargahoraria);
          --
          -- Colocada a inicializacao fora do loop
          --
          c := c + 1;

          PKGPAG_VAR.vgNuDiasCef := PKGPAG_VAR.vgNuDiasCef +
                                    (vCef.DtFim - vCef.DtInicio + 1);

        END LOOP;

        IF pkgpag_var.vgNuDiasCef > 30 THEN
          pkgpag_var.vgNuDiasCef := 30;
        END IF;

        pArmazenaCargaHoraria(vCefAux.CdHistCargoEfetivo, 1);
        ------------------------------------------------------------
        -- Seleciona a carga horaria principal
        ------------------------------------------------------------
        BEGIN

          vtCEF(i).NuCargaHoraria := PKGTID.FConsultar(PTID  => vtCEF(i).TIDNuCargaHoraria,
                                                       PData => vtCEF(i).TIDNuCargaHoraria.intervalos(vtCEF(i).TIDNuCargaHoraria.intervalos.LAST).dtIni -- ultima do mes
                                                       );

        EXCEPTION
          WHEN OTHERS THEN
            pkgpag_geral.pinserelog(pkgpag_var.blog,
                                    pkgpag_var.vcdhistparamcalc,
                                    pkgpag_var.vcdpessoa,
                                    'Excecao gerada em PKGPAG_GERAL.PArmazenaRelacaoEfetivo -  PKGTID.FConsultar. N?o retornou valor em vtCEF(i).NuCargaHoraria ',
                                    pkgpag_var.vgcdvinculo);
        END;

        ------------------------------------------------------------
        -- Seleciona o historico de nivel/referencia
        ------------------------------------------------------------

        FOR vHP IN (SELECT NuNivelPagamento, NuReferenciaPagamento
                      FROM (SELECT hnr.nunivelpagamento,
                                   hnr.nureferenciapagamento,
                                   hnr.dtinicio
                              FROM ecadhistnivelrefcef hnr
                             WHERE HNR.CdHistCargoEfetivo =
                                   vCEFAux.CdHistRelVinc
                               AND HNR.FlAnulado = 'N'
                               AND ((HNR.DtInicio <=
                                   PKGPAG_VAR.vgFolha.dtFimMes) AND
                                   (HNR.dtFim >=
                                   PKGPAG_VAR.vgFolha.dtInicioMes OR
                                   HNR.dtFim IS NULL))
                             ORDER BY dtinicio DESC)
                     WHERE ROWNUM < PKGPAG_TIPO.cn2) LOOP

          vtcef(i).nunivelpagamento := vhp.nunivelpagamento;

          vtcef(i).nureferenciapagamento := vhp.nureferenciapagamento;

        END LOOP;

        ------------------------------------------------------------
        -- Busca a ultima movimentacao dentro do mes
        ------------------------------------------------------------

        vmotivoinstituto := fretornamotivoinstituto(pcef => vtcef(i));

        vtcef(i).cdmotivomovimentacao := vmotivoinstituto.cdmotivomovimentacao;

        vtcef(i).cdinstitutomovimentacao := vmotivoinstituto.cdinstitutomovimentacao;

        vtcef(i).flexercicioorigem := vmotivoinstituto.flexercicioorigem;

        --------------------------------------------------------------------------
        -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
        -- e o codigo da relacao de vinculo
        --------------------------------------------------------------------------

        pkgpag_var.vgrelvincprincipal.tipo := 1;

        pkgpag_var.vgrelvincprincipal.cdhist := vcefaux.cdhistrelvinc;

        pkgpag_var.vgrelvincprincipal.dtiniciorelacao := vcefaux.dtiniciorelacao;

        pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vcefaux.cdunidadeorganizacional;

        -- Ajusta data inicio da relacao a disposicao,
        -- quando houver cargo efetivo vigente
        -- e a disposcao inciar apos o inicio do mes da folha
      ELSIF vcefaux.cdorgaoexercicio <> PKGPAG_VAR.vgFolha.cdorgao AND
            vcefaux.cdrelacaotrabalho = pkgpag_tipo.cnRelTrabEfetivo AND
            vcefaux.DtInicio <= PKGPAG_VAR.vgFolha.DtInicioMes AND
            pkgpag_var.bpossuidisposicao AND i > 0 AND vtcef(i)
           .cdrelacaotrabalho = pkgpag_tipo.cnreltrabdisposicao AND vtcef(i)
           .dtinicio > PKGPAG_VAR.vgFolha.DtInicioMes THEN
        BEGIN

          vtcef(i).dtinicio := PKGPAG_VAR.vgFolha.DtInicioMes;

        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

      else
        null;
      END IF;

    END LOOP;

    pkgpag_var.vgcef := vtcef;

    /*IF vCEFAux.CdHistCargoEfetivo IS NOT NULL THEN
      c := pkgpag_fb.fmnechomedio(1,vCEFAux.CdHistCargoEfetivo,PKGPAG_VAR.vgFolha.DtInicioMes,PKGPAG_VAR.vgFolha.DtFimMes);
    END IF;*/

  END;

  ----------------------------------------------------------------------------

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de efetivo do instituidor de pensao
  /*-------------------------------------------------------------------------*/

  PROCEDURE pArmazenaInstituidorEfetivo(pcdvinculo   IN INTEGER,
                                        pflvalidapag IN CHAR DEFAULT 'S') IS

    i INTEGER;
    c INTEGER;

    vcefaux        pkgpag_tipo.rcef;
    vtcef          pkgpag_tipo.tcef;
    vtcargahoraria pkgpag_tipo.tCargaHoraria;

    TYPE rMotivoMov IS RECORD(
      CdMotivoMovimentacao    INTEGER,
      cdinstitutomovimentacao INTEGER,
      flexercicioorigem       CHAR(1));

    vmotivoinstituto rmotivomov;

    vdtincioanterior DATE;

    vSemIntersticioCEFAnterior BOOLEAN := FALSE;

    /* Cursor cCEF: Seleciona as relacoes de vinculo com os historicos de niveis e
    referencias vigentes no Ano/Mes de referencia e os respectivas
    datas de inicio e fim                                            */

    CURSOR ccef(pcdvinculo   IN INTEGER,
                pdtiniciomes IN DATE,
                pdtfimmes    IN DATE) IS

      WITH OB AS -- Busca os dados do obito
       (SELECT O.cdpessoa as cdpessoa, O.dtobito as dtobito
          FROM eafaregistroobito O
         inner join ecadvinculo VI
            on VI.cdpessoa = O.cdpessoa
         WHERE o.flanulado = PKGPAG_TIPO.cnN
           and VI.cdvinculo = pCdVinculo
           and O.cdagrupamento <> 132 -- agrupamento dos pensionistas
           and rownum < 2),
      SIT AS
       (select hsp.cdsituacaoprevidenciaria, hsp.cdvinculo
          from ecadhistsitprevvinculo hsp
         where hsp.dtinicio =
               (select max(hsp.dtinicio)
                  from ecadhistsitprevvinculo hsp
                 where cdvinculo = pCdVinculo
                   and hsp.cdsituacaoprevidenciaria <>
                       pkgpag_tipo.cnSitPrevInstPensao)
           and hsp.cdvinculo = pCdVinculo)

      SELECT ce.cdvinculo,
             1 AS cdrelacaovinculo,
             ce.cdhistcargoefetivo AS cdhistrelvinc,
             ce.cdrelacaotrabalho,
             ce.cdregimetrabalho,
             ce.cdnaturezavinculo,
             ce.cdregimeprevidenciario,
             s.cdsituacaoprevidenciaria,
             ce.cdestruturacarreira,
             ec.cdestruturacarreiracarreira,
             CASE
               WHEN CE.DtInicio < pdtInicioMes THEN
                pdtiniciomes
               ELSE
                ce.dtinicio
             END AS dtinicio,
             pdtfimmes AS dtfim,
             ce.dtinicio AS dtiniciorelacao,
             ce.dtfim AS dtfimrelacao,
             ce.cdhistcargoefetivo,
             ce.nunivelpagamento,
             ce.nureferenciapagamento,
             0 AS vlpercentpropapo,
             ce.cdorgaoexercicio,
             ce.flprincipal,
             lt.cdunidadeorganizacional,
             NULL AS florigemcco,
             ce.flefetivacao,
             0 AS nucargahoraria,
             ce.cdorgaodestprocseletivo,
             ce.dtfimnovoprocessoseletivo,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             'N' AS flexercicioorigem,
             cdorgaodestmovimentacao,
             ce.dtinclusao,
             CASE
               WHEN cp.dtinicio IS NOT NULL THEN
                cp.dtinicio
               ELSE
                ce.dtinicio
             END AS dtinicioVinculo
        FROM ecadhistcargoefetivo ce
       INNER JOIN ecadvinculo v
          on v.cdvinculo = ce.cdvinculo
         AND v.cdorgao = ce.cdorgaoexercicio
      -- Busca apenas um registro de obito
        LEFT JOIN OB o
          on o.cdpessoa = v.cdpessoa

       INNER JOIN SIT S
          on s.cdvinculo = pCdVinculo

       INNER JOIN ecadestruturacarreira ec
          ON ce.cdestruturacarreira = ec.cdestruturacarreira

       INNER JOIN ecadlocaltrabalho lt
          ON LT.CdHistCargoEfetivo = CE.CdHistCargoEfetivo
         AND LT.DtInicio =
             (SELECT MAX(DtInicio) AS DtInicio
                FROM ecadlocaltrabalho lt
               WHERE LT.CdVinculo = CE.CdVinculo
                 AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                 AND LT.FlAnulado = PKGPAG_TIPO.cnN
                 AND LT.DtInicio <= pdtFimMes
                 AND LT.CdHistCargoEfetivo = CE.CdHistCargoEfetivo)
         AND LT.FlDefinitiva = 'S'
         AND LT.FlAnulado = PKGPAG_TIPO.cnN

      --Armazena a data inicio do vinculo
        left join (select min(cefp.Dtinicio) DtInicio, cefp.cdvinculo
                     from ecadhistcargoefetivo cefp
                    where cefp.flanulado = PKGPAG_TIPO.cnN
                      and cefp.flprincipal = PKGPAG_TIPO.cnS
                      and cefp.DtInicio <= pdtfimmes
                      and cefp.cdvinculo = pCdVinculo
                      and cefp.cdrelacaotrabalho not in (10, 17)
                      AND cefp.cdorgaoexercicio = pkgpag_var.vgFolha.CdOrgao
                    group by cdvinculo) cp
          on cp.cdvinculo = ce.cdvinculo

       WHERE CE.CdVinculo = pCdVinculo
         AND CE.DtInicio <= pdtFimMes
         AND CE.FlEfetivacao = PKGPAG_TIPO.cnT
         AND CE.FlAnulado = PKGPAG_TIPO.cnN
         AND CE.CDRELACAOTRABALHO not in (10, 17)
         AND CE.Dtinicio =
             (SELECT MAX(dtInicio)
                FROM ecadhistcargoefetivo cef
               WHERE CEF.CdVinculo = pCdVinculo
                 AND CEF.FlAnulado = PKGPAG_TIPO.cnN
                 AND CEF.FlEfetivacao = PKGPAG_TIPO.cnT
                 AND CEF.CDRELACAOTRABALHO not in (10, 17)
                 AND cef.cdorgaoexercicio = pkgpag_var.vgFolha.CdOrgao)
         AND NOT EXISTS
      -- Solicitacao de Sustentacao #80284
      -- 12554/2018 - INSTITUIDOR GERENDO RUBRICAS INDEVIDAS
      -- Colocada validacao de data inicio da aposentadoria
       (select 1
                from epvdconcessaoaposentadoria epp
               where epp.cdvinculo = pCdVinculo
                 and epp.flanulado = PKGPAG_TIPO.cnN
                    --AND epp.CdOrgaoExercicio = pkgpag_var.vgFolha.CdOrgao
                 AND epp.FlAtiva = PKGPAG_TIPO.cnS
                 and epp.dtinicioaposentadoria > ce.dtinicio)
       ORDER BY CE.DtInicio DESC,
                EC.CdEstruturaCarreiraCarreira,
                CE.CdHistCargoEfetivo;

    FUNCTION fretornamotivoinstituto(pcef IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pcco IN pkgpag_tipo.rcco DEFAULT NULL,
                                     papo IN pkgpag_tipo.rcef DEFAULT NULL,
                                     pbol IN pkgpag_tipo.rbol DEFAULT NULL)
      RETURN rmotivomov IS

      vmotivomov rmotivomov;

    BEGIN
 
      IF pcef.cdvinculo IS NOT NULL THEN

        IF pcef.cdrelacaotrabalho = pkgpag_tipo.cnreltrabdisposicao THEN

          BEGIN

            SELECT m.cdmotivomovimentacao,
                   m.cdinstitutomovimentacao,
                   m.flexercicioorigem
              INTO vmotivomov.cdmotivomovimentacao,
                   vmotivomov.cdinstitutomovimentacao,
                   vmotivomov.flexercicioorigem
              FROM (SELECT m.cdmotivomovimentacao,
                           m.cdinstitutomovimentacao,
                           inst.flexercicioorigem
                      FROM eafaafastamentorelvinc av
                     INNER JOIN emovmovimentacao m
                        ON av.cdhistcargoefetivo = m.cdhistcargoefetivo
                     INNER JOIN Emovinstitutomovimentacao inst
                        on inst.cdinstitutomovimentacao =
                           M.CdInstitutoMovimentacao
                     WHERE AV.CdHistCargoEfetivoGerador = pCEF.CdHistRelVinc
                       AND AV.DtInicio <= PKGPAG_VAR.vDtCalculo
                       AND (AV.Dtfim >= PKGPAG_VAR.vDtCalculo OR
                           AV.Dtfim IS NULL)
                       AND AV.DtInicio = M.DtApresentacao
                       AND M.FlPagamentoOrigem = 'N'
                       AND AV.FlAnulado = PKGPAG_TIPO.cnN
                     ORDER BY m.dtapresentacao DESC) m
             WHERE rownum < 2;

            RETURN vmotivomov;

          EXCEPTION

            WHEN no_data_found THEN

              NULL;

          END;

        ELSIF pCEF.CdRelacaoTrabalho = PKGPAG_TIPO.cnRelTrabEfetivo AND
              pCEF.FlEfetivacao = 'T' THEN

          BEGIN

            SELECT m.cdmotivomovimentacao,
                   m.cdinstitutomovimentacao,
                   m.flexercicioorigem
              INTO vmotivomov.cdmotivomovimentacao,
                   vmotivomov.cdinstitutomovimentacao,
                   vmotivomov.flexercicioorigem
              FROM (SELECT m.cdmotivomovimentacao,
                           m.cdinstitutomovimentacao,
                           inst.flexercicioorigem
                      FROM emovmovimentacao m
                     INNER JOIN Emovinstitutomovimentacao inst
                        on INST.cdinstitutomovimentacao =
                           M.CdInstitutoMovimentacao
                     WHERE M.CdHistCargoEfetivo = pCEF.CdHistRelVinc
                       AND M.DtApresentacao <= pCEF.DtFim
                     ORDER BY m.dtapresentacao DESC) m
             WHERE rownum < 2;

            RETURN vmotivomov;

          EXCEPTION

            WHEN no_data_found THEN

              NULL;

          END;

        else
          null;
        END IF;

      END IF;

      RETURN vmotivomov;

    END;

  BEGIN
 
    pkgpag_var.bpagacef := FALSE;

    pkgpag_var.vgcef := vtcef;

    pkgpag_var.vgCargaHoraria := vtcargahoraria;

    pkgpag_var.btemefetivooutroorgao := FALSE;

    pkgpag_var.btemefetivoanyorgao := FALSE;

    i := 0;

    ----------------------------------------------------------------------------
    -- Armazena as faltas ocorridas durante o ano - Para calculo do 13 salario
    ----------------------------------------------------------------------------

    pkgpag_var.vgqtfaltas := pkgpag_geral.fqtfaltas(pcdvinculo => pkgpag_var.vgvinculo.cdvinculo,
                                                    pnuano     => pkgpag_var.vgfolha.nuanoreferencia);

    c := 0;

    FOR vCEF IN cCEF(pCdVinculo,
                     PKGPAG_VAR.vgFolha.DtInicioMes,
                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      ----------------------------------------------------------------------------
      -- Armazena as relacoes de trabalho de cargo efetivo do vinculo
      ----------------------------------------------------------------------------

      pkgpag_var.vglistareltrab(vcef.cdrelacaotrabalho) := vcef.cdrelacaotrabalho;

      ----------------------------------------------------------------------------
      -- Armazena a carreira do CEF para ser utilizada verificacao de abrangencia
      -- para as demais relacoes de vinculo (CCO e FUC)
      ----------------------------------------------------------------------------

      pkgpag_var.vgcdestruturacarreira := vcef.cdestruturacarreira;

      IF vcef.cdrelacaotrabalho = pkgpag_tipo.cnrelact THEN

        pkgpag_var.bpossuiact := TRUE;

      END IF;

      pkgpag_var.btemefetivoanyorgao := TRUE;

      IF vcef.cdorgaoexercicio <> pkgpag_var.vgfolha.cdorgao THEN

        pkgpag_var.btemefetivooutroorgao := TRUE;

        IF vdtincioanterior = vcef.dtfim + 1 THEN

          pkgpag_var.bsemintersticio := TRUE;

          vSemIntersticioCEFAnterior := TRUE;

        ELSE

          vSemIntersticioCEFAnterior := FALSE;

        END IF;

      END IF;
      --
      -- Se situacao previdenciaria = instituidor de pensao, procurar a ultima quando vivo
      --
      IF vCef.cdsituacaoprevidenciaria = 3 THEN
        BEGIN
          SELECT hsp.cdsituacaoprevidenciaria
            INTO vCef.cdsituacaoprevidenciaria
            FROM ecadhistsitprevvinculo hsp
           WHERE HSP.CdVinculo = vCef.CdVinculo
             AND HSP.Cdsituacaoprevidenciaria <> 3
             AND HSP.Dtinicio =
                 (SELECT MAX(DTINICIO)
                    FROM ecadhistsitprevvinculo hsp
                   WHERE HSP.CdVinculo = vCef.CdVinculo
                     AND HSP.Cdsituacaoprevidenciaria <> 3)
             AND HSP.Cdsituacaoprevidenciaria <> 3
             AND ROWNUM < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vCef.cdsituacaoprevidenciaria := 1;

          WHEN OTHERS THEN
            vCef.cdsituacaoprevidenciaria := 1;
        END;
      END IF;

      -- Formatar para o tipo

      vcefaux.cdvinculo                   := vcef.cdvinculo;
      vcefaux.cdrelacaovinculo            := vcef.cdrelacaovinculo;
      vcefaux.cdhistrelvinc               := vcef.cdhistrelvinc;
      vcefaux.cdrelacaotrabalho           := vcef.cdrelacaotrabalho;
      vcefaux.cdregimetrabalho            := vcef.cdregimetrabalho;
      vcefaux.cdnaturezavinculo           := vcef.cdnaturezavinculo;
      vcefaux.cdregimeprevidenciario      := vcef.cdregimeprevidenciario;
      vcefaux.cdsituacaoprevidenciaria    := vcef.cdsituacaoprevidenciaria;
      vcefaux.cdestruturacarreira         := vcef.cdestruturacarreira;
      vcefaux.cdestruturacarreiracarreira := vcef.cdestruturacarreiracarreira;
      vcefaux.dtinicio                    := vcef.dtinicio;
      vcefaux.dtfim                       := vcef.dtfim;
      vcefaux.dtiniciorelacao             := vcef.dtiniciorelacao;
      vcefaux.dtfimrelacao                := vcef.dtfimrelacao;
      vcefaux.cdhistcargoefetivo          := vcef.cdhistcargoefetivo;
      vcefaux.nunivelpagamento            := vcef.nunivelpagamento;
      vcefaux.nureferenciapagamento       := vcef.nureferenciapagamento;
      vcefaux.vlpercentpropapo            := vcef.vlpercentpropapo;
      vcefaux.cdorgaoexercicio            := vcef.cdorgaoexercicio;
      vcefaux.flprincipal                 := vcef.flprincipal;
      vcefaux.cdunidadeorganizacional     := vcef.cdunidadeorganizacional;
      vcefaux.florigemcco                 := vcef.florigemcco;
      vcefaux.flefetivacao                := vcef.flefetivacao;
      vcefaux.nucargahoraria              := vcef.nucargahoraria;
      vcefaux.tidnucargahoraria           := NULL;
      vcefaux.cdorgaodestprocseletivo     := vcef.cdorgaodestprocseletivo;
      vcefaux.dtfimnovoprocessoseletivo   := vcef.dtfimnovoprocessoseletivo;
      vcefaux.cdmotivomovimentacao        := vcef.cdmotivomovimentacao;
      vcefaux.cdinstitutomovimentacao     := vcef.cdinstitutomovimentacao;
      vcefaux.flexercicioorigem           := vcef.flexercicioorigem;
      vcefaux.cdorgaodestmovimentacao     := vcef.cdorgaodestmovimentacao;
      vcefaux.dtinclusao                  := vcef.dtinclusao;
      vcefaux.DtInicioVinculo             := vcef.dtinicioVinculo;
      vcefaux.NuCargaHorariaPadrao        := PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria;

      --
      -- Buscar carreira destino da ultima movimentacao no mes do calculo
      --

      BEGIN
        WITH MOV AS
         (SELECT EMC.CDESTRUTURACARREIRADESTINO
            FROM EMOVMOVCARGOEFETIVO EMC
           INNER JOIN EMOVMOVCARGOEFETIVOVINC EMV
              ON EMV.CDMOVCARGOEFETIVO = EMC.CDMOVCARGOEFETIVO
             AND EMV.CDVINCULO = vCef.CdVinculo
             AND EMC.FLANULADO = 'N'
             AND EMC.DTMOVIMENTACAO <= PKGPAG_VAR.vgFolha.DtFimMes
           ORDER BY EMC.DTMOVIMENTACAO DESC)
        SELECT MOV.CDESTRUTURACARREIRADESTINO,
               EC.CDESTRUTURACARREIRACARREIRA
          INTO vcefaux.cdestruturacarreira,
               vcefaux.cdestruturacarreiracarreira
          FROM MOV
         INNER JOIN ECADESTRUTURACARREIRA EC
            ON EC.CDESTRUTURACARREIRA = MOV.CDESTRUTURACARREIRADESTINO
         WHERE ROWNUM < 2;

      EXCEPTION
        WHEN OTHERS THEN
          vcefaux.cdestruturacarreira         := vcef.cdestruturacarreira;
          vcefaux.cdestruturacarreiracarreira := vcef.cdestruturacarreiracarreira;
      END;

      IF FPagaRemuneracaoCEF(PKGPAG_VAR.vgFolha, vCEFAux) OR
         pflvalidapag = 'N' OR vSemIntersticioCEFAnterior THEN

        -- A ordenacao pega o cef de maior data inicio primeiro

        vdtincioanterior := vcefaux.dtinicio;

        i := i + 1;

        vtcef(i) := vcefaux;

        pkgpag_var.bpagacef := TRUE;

        ------------------------------------------------------------
        -- Carrega TID de Carga Horaria do mes
        ------------------------------------------------------------

        pkgtid.psetlimitar(ptid     => vtcef(i).tidnucargahoraria,
                           pdatamin => pkgpag_var.vgfolha.dtiniciomes,
                           pdatamax => pkgpag_var.vgfolha.dtfimmes);

        pkgtid.pmodosomar(ptid     => vtcef(i).tidnucargahoraria,
                          pflsomar => TRUE);

        FOR rec IN (SELECT *
                      FROM (SELECT dtinicial, NULL AS dtfim, nucargahoraria
                              FROM ecadhistcargahoraria cho
                             WHERE CHO.CdHistCargoEfetivo =
                                   vCEFAux.CdHistCargoEfetivo
                               AND CHO.FlAnulado = 'N'
                               AND CHO.FLTIPOOCUPACAO = 'D'
                               AND CHO.DtInicial <=
                                   PKGPAG_VAR.vgFolha.DtFimMes
                             ORDER BY dtinicial DESC)
                     WHERE ROWNUM < 2) LOOP

          pkgtid.pinserir(ptid     => vtcef(i).tidnucargahoraria,
                          PDataIni => rec.DtInicial,
                          PDataFim => rec.DtFim,
                          pvalor   => rec.nucargahoraria);
          --
          -- Colocada a inicializacao fora do loop
          --
          c := c + 1;

          pkgpag_var.vgCargaHoraria(c).NuCargaHoraria := rec.nucargahoraria;

          IF rec.DtInicial < PKGPAG_VAR.vgFolha.DtInicioMes THEN
            pkgpag_var.vgCargaHoraria(c).DtInicio := PKGPAG_VAR.vgFolha.DtInicioMes;
          ELSE
            pkgpag_var.vgCargaHoraria(c).DtInicio := rec.DtInicial;
          END IF;

          IF rec.DtFim > PKGPAG_VAR.vgFolha.DtFimMes or rec.Dtfim is null THEN
            pkgpag_var.vgCargaHoraria(c).DtFim := PKGPAG_VAR.vgFolha.DtFimMes;
          ELSE
            pkgpag_var.vgCargaHoraria(c).DtFim := rec.DtFim;
          END IF;

          pkgpag_var.vgCargaHoraria(c).CdHistCargoEfetivo := vCEFAux.CdHistCargoEfetivo;
          pkgpag_var.vgCargaHoraria(c).CdTipoRelacao := 1; -- Efetivo

        END LOOP;

        -- pArmazenaCargaHoraria (vCefAux.CdHistCargoEfetivo,1);
        ------------------------------------------------------------
        -- Seleciona a carga horaria principal
        ------------------------------------------------------------
        BEGIN

          vtCEF(i).NuCargaHoraria := PKGTID.FConsultar(PTID  => vtCEF(i).TIDNuCargaHoraria,
                                                       PData => vtCEF(i).TIDNuCargaHoraria.intervalos(vtCEF(i).TIDNuCargaHoraria.intervalos.LAST).dtIni -- ultima do mes
                                                       );

        EXCEPTION
          WHEN OTHERS THEN

            pkgpag_geral.pinserelog(pkgpag_var.blog,
                                    pkgpag_var.vcdhistparamcalc,
                                    pkgpag_var.vcdpessoa,
                                    'Excecao gerada em PKGPAG_GERAL.PArmazenaRelacaoEfetivo -  PKGTID.FConsultar. N?o retornou valor em vtCEF(i).NuCargaHoraria ',
                                    pkgpag_var.vgcdvinculo);

        END;

        ------------------------------------------------------------
        -- Seleciona o historico de nivel/referencia
        ------------------------------------------------------------

        FOR vHP IN (SELECT NuNivelPagamento, NuReferenciaPagamento
                      FROM (SELECT hnr.nunivelpagamento,
                                   hnr.nureferenciapagamento,
                                   hnr.dtinicio
                              FROM ecadhistnivelrefcef hnr
                             WHERE HNR.CdHistCargoEfetivo =
                                   vCEFAux.CdHistRelVinc
                               AND HNR.FlAnulado = 'N'
                               AND HNR.DtInicio <=
                                   PKGPAG_VAR.vgFolha.dtFimMes
                             ORDER BY dtinicio DESC)
                     WHERE ROWNUM < 2) LOOP

          vtcef(i).nunivelpagamento := vhp.nunivelpagamento;

          vtcef(i).nureferenciapagamento := vhp.nureferenciapagamento;

        END LOOP;

        ------------------------------------------------------------
        -- Busca a ultima movimentacao dentro do mes
        ------------------------------------------------------------

        vmotivoinstituto := fretornamotivoinstituto(pcef => vtcef(i));

        vtcef(i).cdmotivomovimentacao := vmotivoinstituto.cdmotivomovimentacao;

        vtcef(i).cdinstitutomovimentacao := vmotivoinstituto.cdinstitutomovimentacao;

        vtcef(i).flexercicioorigem := vmotivoinstituto.flexercicioorigem;

        --------------------------------------------------------------------------
        -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
        -- e o codigo da relacao de vinculo
        --------------------------------------------------------------------------

        pkgpag_var.vgrelvincprincipal.tipo := 1;

        pkgpag_var.vgrelvincprincipal.cdhist := vcefaux.cdhistrelvinc;

        pkgpag_var.vgrelvincprincipal.dtiniciorelacao := vcefaux.dtiniciorelacao;

        pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vcefaux.cdunidadeorganizacional;

      END IF;

    END LOOP;

    pkgpag_var.vgcef := vtcef;

    --c := pkgpag_fb.fmnechomedio(1,vCEFAux.CdHistCargoEfetivo,PKGPAG_VAR.vgFolha.DtInicioMes,PKGPAG_VAR.vgFolha.DtFimMes);

  END;

  --------------------------------------------------------------------

  PROCEDURE pArmazenaInstituidorComiss(pcdvinculo IN INTEGER) IS

    i          INTEGER;
    vtcco      pkgpag_tipo.tcco;
    vnudiascco INTEGER;
    -- vnudiasminsubst INTEGER;

    CURSOR ccco(pcdvinculo IN INTEGER,
                pcdorgao   IN INTEGER,
                pdtinicio  IN DATE,
                pdtfim     IN DATE) IS

      WITH OB AS -- Busca os dados do obito
       (SELECT O.cdpessoa as cdpessoa, O.dtobito as dtobito
          FROM eafaregistroobito O
         inner join ecadvinculo VI
            on VI.cdpessoa = O.cdpessoa
         WHERE o.flanulado = PKGPAG_TIPO.cnN
           and VI.cdvinculo = pCdVinculo
           and O.cdagrupamento <> 132 -- agrupamento dos pensionistas
           and rownum < 2),
      SIT AS
       (select hsp.cdvinculo, hsp.cdsituacaoprevidenciaria
          from ecadhistsitprevvinculo hsp
         where hsp.dtinicio =
               (select max(hsp.dtinicio)
                  from ecadhistsitprevvinculo hsp
                 where cdvinculo = pCdVinculo
                   and hsp.cdsituacaoprevidenciaria <>
                       pkgpag_tipo.cnSitPrevInstPensao)
           and hsp.cdvinculo = pCdVinculo)

      SELECT HCC.CdVinculo,
             hcc.cdhistcargocom,
             hcc.cdcargocomissionado,
             hcc.cdorgaoexercicio,
             c.cdgrupoocupacional,
             hcc.cdrelacaotrabalho,
             hcc.cdnaturezavinculo,
             hcc.cdregimeprevidenciario,
             s.cdsituacaoprevidenciaria,
             hcc.cdregimetrabalho,
             hcc.cdopcaoremuneracao,
             CASE
               WHEN hcc.dtinicio < pdtInicio THEN
                pdtInicio
               ELSE
                hcc.dtinicio
             END AS dtinicio,
             pdtfim AS dtfim,
             hcc.dtinicio AS dtiniciorelacao,
             hcc.dtfim AS dtfimrelacao,
             hcc.nunivel,
             hcc.nureferencia,
             nvl(ech.nucargahoraria, 0) AS nucargahoraria,
             nvl(ech.nucargahoraria, 0) AS nucargahorariapadrao,
             lt.cdunidadeorganizacional,
             hcc.fltipoprovimento,
             hcc.dtinclusao,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             flpagasubsidio,
             0 as QtNuDiasCCO
        FROM ecadhistcargocom hcc
       INNER JOIN ecadcargocomissionado c
          ON hcc.cdcargocomissionado = c.cdcargocomissionado
       INNER JOIN SIT S
          ON s.cdvinculo = pCdVinculo
       INNER JOIN ecadvinculo v
          on v.cdvinculo = hcc.cdvinculo
         AND v.cdorgao = hcc.cdorgaoexercicio
      -- Busca apenas um registro de obito
        LEFT JOIN OB o
          ON o.cdpessoa = v.cdpessoa
       INNER JOIN (SELECT LT.CdHistCargoCom, MAX(DtInicio) AS DtInicio
                     FROM ecadlocaltrabalho lt
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                      AND LT.CdHistCargoCom IS NOT NULL
                      AND LT.DtInicio <= pDtFim
                    GROUP BY lt.cdhistcargocom) lt1
          ON lt1.cdhistcargocom = hcc.cdhistcargocom
       INNER JOIN ecadlocaltrabalho lt
          ON LT.CdHistCargoCom = LT1.CdHistCargoCom
         AND LT.DtInicio = LT1.DtInicio
       INNER JOIN ecadevolucaocargocomissionado ecc
          ON hcc.cdcargocomissionado = ecc.cdcargocomissionado
       INNER JOIN ecadevolucaoccocargahoraria ech
          ON ECC.CdEvolucaoCargoComissionado =
             ECH.CdEvolucaoCargoComissionado
         AND ECC.DtInicioVigencia <= PKGPAG_VAR.vdtCalculo
         AND ECH.FlPadrao = PKGPAG_TIPO.cnS

       WHERE HCC.CdVinculo = pCdVinculo
         AND HCC.CdCargoComRemuneracao IS NULL
         AND HCC.FlTipoProvimento IN (PKGPAG_TIPO.cnD, PKGPAG_TIPO.cnN)
         AND (HCC.DtInicio <= pDtFim)
         AND HCC.FlAnulado = PKGPAG_TIPO.cnN
         AND hcc.cdhistcargoefetivoorigem IS NULL
         AND hcc.cdorgaoexercicio = pkgpag_var.vgFolha.CdOrgao
         AND hcc.dtfim = o.dtobito - 1
       ORDER BY hcc.dtfim ASC;

  BEGIN
 
    pkgpag_var.vgcco := vtcco;
    i                := 0;
    vnudiascco       := 0;

    FOR vCCO IN cCCO(pCdVinculo,
                     PKGPAG_VAR.vgFolha.CdOrgao,
                     pkgpag_var.vgfolha.dtiniciomes,
                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      -- Tratamento para desconsiderar CCOs incluidos pos-folha
      -- quando recalculo especial

      IF pkgpag_var.vgfolha.flignorainclusaofutura = 'S' AND
         vcco.dtinclusao >= (pkgpag_var.vgfolha.dtcalculo + 1) THEN
        NULL;
      ELSIF fdevepagarcco THEN
        i          := i + 1;
        vnudiascco := vnudiascco + (vcco.dtfim - vcco.dtinicio + 1);
        -- Busca a opcao de remuneracao (ultima dentro do mes de processamento)
        vcco.cdopcaoremuneracao := fretornaopcaoremuneracaocco(pcdhistcargocom => vcco.cdhistcargocom,
                                                               pdtiniciomes    => to_date('01/01/1900',
                                                                                          'DD/MM/YYYY'),
                                                               pdtfimmes       => pkgpag_var.vgfolha.dtfimmes);

        IF vcco.cdopcaoremuneracao IS NULL THEN
          pkgpag_geral.pinserelog(pkgpag_var.blog,
                                  pkgpag_var.vcdhistparamcalc,
                                  pkgpag_var.vcdpessoa,
                                  'O cargo comissionado n?o possui historico de op??o de remunera??o vigente.',
                                  PKGPAG_VAR.vgCdVinculo,
                                  2);
        END IF;

        pkgpag_var.vgcco(i) := vcco;
        pkgpag_var.vglistareltrab(vcco.cdrelacaotrabalho) := vcco.cdrelacaotrabalho;

        IF (PKGPAG_VAR.vgFolha.CdTipoCalculo in
           (PKGPAG_TIPO.cnTpCalculoRecalculoMes) AND
           NVL(PKGPAG_VAR.vgFolha.NuAnoMesImplantacao, '400001') >
           (PKGPAG_VAR.vgFolha.NuAnoReferencia ||
           LPAD(PKGPAG_VAR.vgFolha.NuMesReferencia, 2, '0')) AND
           vcco.dtinclusao > pkgpag_var.vdtcalculo AND
           vcco.cdorgaoexercicio <> pkgpag_var.vgvinculo.cdorgao) OR
           (vCCO.CdOpcaoRemuneracao = 5 AND -- comissionado com opcao militar na origem
           vCCO.CdOrgaoExercicio <> PKGPAG_VAR.vgVinculo.CdOrgao AND
           PKGPAG_VAR.vgFolha.CdOrgao = vCCO.CdOrgaoExercicio)
        -- OR(vCCO.CdOrgaoExercicio <> PKGPAG_VAR.vgVinculo.CdOrgao AND vCCO.CdOpcaoRemuneracao = 6 AND
        -- vCCO.dtfim < PKGPAG_VAR.vgFolha.DtCalculo AND PKGPAG_VAR.vgFolha.CdOrgao <> PKGPAG_VAR.vgVinculo.CdOrgao AND NOT PKGPAG_VAR.bPossuiDisposicao ) /* FABIO - TESTE para nao pagar no orgao de exercicio do CCO quando ja terminou a relacao vinculo */
         THEN
          pkgpag_var.bcalculavinculo := FALSE;
        ELSE
          pkgpag_var.bcalculavinculo := TRUE;
        END IF;

        -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
        -- e o codigo da relacao de vinculo
        IF (vCCO.CdOpcaoRemuneracao = 3 AND
           vCCO.DtFim >= PKGPAG_VAR.vgFolha.DtCalculo) OR
           pkgpag_var.vgcef.count = 0 THEN
          pkgpag_var.vgrelvincprincipal.tipo                    := 2;
          pkgpag_var.vgrelvincprincipal.cdhist                  := vcco.cdhistcargocom;
          pkgpag_var.vgrelvincprincipal.cdreltrabpagamento      := vcco.cdrelacaotrabalho;
          pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vcco.cdunidadeorganizacional;
        ELSIF vcco.cdopcaoremuneracao IN (6,9) THEN
          pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vcco.cdunidadeorganizacional;
        else
          null;
        END IF;

        -- Alteracao realizada para limitar a 30 dias caso ele possua mais de um
        -- CCO dentro do mes
        IF i > 1 THEN
          IF vnudiascco > 30 THEN
            pkgpag_var.vgcco(i).dtfim := pkgpag_var.vgcco(i).dtfim - 1;
          END IF;
        END IF;
      else
        null;
      END IF;

      begin
        pkgpag_var.vgcco(i).QtNuDiasCCO := pkgpag_var.vgcco(i).dtfim - pkgpag_var.vgcco(i).dtinicio + 1;
      exception
        when others then
          null;
      end;
      pArmazenaCargaHoraria(vCCO.CdHistCargoCom,
                            2,
                            vcco.NuCargaHorariaPadrao);
    END LOOP;

    PKGPAG_VAR.vgNuDiasCCO     := vNuDiasCCO;
    PKGPAG_VAR.bPossuiIprevCCO := FPossuiIprevCCO(pCdVinculo);

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de comissionado
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaocomissionado(pcdvinculo IN INTEGER) IS

    i                        INTEGER;
    vtcco                    pkgpag_tipo.tcco;
    vnudiascco               INTEGER;
    vnudiasminsubst          INTEGER;
    vCdOrgaoExercicioTitular INTEGER;

    CURSOR ccco(pcdvinculo IN INTEGER,
                pcdorgao   IN INTEGER,
                pdtinicio  IN DATE,
                pdtfim     IN DATE) IS
      SELECT HCC.CdVinculo,
             hcc.cdhistcargocom,
             hcc.cdcargocomissionado,
             hcc.cdorgaoexercicio,
             c.cdgrupoocupacional,
             hcc.cdrelacaotrabalho,
             hcc.cdnaturezavinculo,
             hcc.cdregimeprevidenciario,
             hsp.cdsituacaoprevidenciaria,
             hcc.cdregimetrabalho,
             hcc.cdopcaoremuneracao,
             CASE
               WHEN hcc.dtinicio < pdtinicio THEN
               ----------------------
                CASE
                  WHEN (SELECT 1
                          FROM ECADHISTCARGOCOM HCC2
                         WHERE HCC2.CDVINCULO = HCC.CDVINCULO
                           AND HCC2.CDHISTCARGOCOMORIGEM = HCC.CDHISTCARGOCOM
                           AND HCC2.CDCARGOCOMREMUNERACAO IS NULL
                           AND HCC2.Dtfim >= pDtInicio
                           AND TO_CHAR(HCC2.DTfim, 'MMYYYY') =
                               TO_CHAR(pDtInicio, 'MMYYYY')
                           AND HCC2.Dtinicio > HCC.DTFIM
                           AND HCC2.FLANULADO = 'N'
                           AND HCC2.FLTIPOPROVIMENTO <> PKGPAG_TIPO.cnD ) = 1 THEN
                   (SELECT (HCC2.DTfim + 1)
                      FROM ECADHISTCARGOCOM HCC2
                     WHERE HCC2.CDVINCULO = HCC.CDVINCULO
                       AND HCC2.CDHISTCARGOCOMORIGEM = HCC.CDHISTCARGOCOM
                       AND HCC2.CDCARGOCOMREMUNERACAO IS NULL
                       AND HCC2.Dtfim >= pDtInicio
                       AND TO_CHAR(HCC2.DTfim, 'MMYYYY') =
                           TO_CHAR(pDtInicio, 'MMYYYY')
                       AND HCC2.FLANULADO = 'N')
                  ELSE
                   pdtinicio
                END
             ---------------
               ELSE
                hcc.dtinicio
             END dtinicio,
             CASE
               WHEN (hcc.dtfim IS NULL) OR (hcc.dtfim > pdtfim) THEN
                CASE
                  WHEN (SELECT 1
                          FROM ECADHISTCARGOCOM HCC2
                         WHERE hcc2.cdvinculo = hcc.cdvinculo
                           AND HCC2.CDHISTCARGOCOMORIGEM = HCC.CDHISTCARGOCOM
                           AND hcc2.cdcargocomremuneracao IS NULL
                           AND hcc2.dtinicio > pdtinicio
                           AND TO_CHAR(HCC2.DTINICIO, 'MMYYYY') =
                               TO_CHAR(pDtInicio, 'MMYYYY')
                           AND HCC2.FLANULADO = 'N'
                           AND HCC2.FLTIPOPROVIMENTO <> PKGPAG_TIPO.cnD) = 1 THEN
                   (SELECT (HCC2.DTINICIO - 1)
                      FROM ECADHISTCARGOCOM HCC2
                     WHERE hcc2.cdvinculo = hcc.cdvinculo
                       AND hcc2.cdhistcargocomorigem = hcc.cdhistcargocom
                       AND hcc2.cdcargocomremuneracao IS NULL
                       AND hcc2.dtinicio > pdtinicio
                       AND TO_CHAR(HCC2.DTINICIO, 'MMYYYY') =
                           TO_CHAR(pDtInicio, 'MMYYYY')
                       AND hcc2.flanulado = 'N')
                  ELSE
                   pdtfim
                END
               ELSE
                hcc.dtfim
             END dtfim,
             hcc.dtinicio AS dtiniciorelacao,
             hcc.dtfim AS dtfimrelacao,
             hcc.nunivel,
             hcc.nureferencia,
             nvl(ech.nucargahoraria, 0) AS nucargahoraria,
             nvl(ech.nucargahoraria, 0) AS nucargahorariapadrao,
             lt.cdunidadeorganizacional,
             hcc.fltipoprovimento,
             hcc.dtinclusao,
             0 AS cdmotivomovimentacao,
             0 AS cdinstitutomovimentacao,
             flpagasubsidio,
             0 as QtNuDiasCCO
        FROM ecadhistcargocom hcc
       INNER JOIN ecadcargocomissionado c
          ON hcc.cdcargocomissionado = c.cdcargocomissionado
       INNER JOIN ecadhistsitprevvinculo hsp
          ON HCC.CdVinculo = HSP.CdVinculo
         AND (HCC.DtInicio BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       INNER JOIN (SELECT LT.CdHistCargoCom, MAX(DtInicio) AS DtInicio
                     FROM ecadlocaltrabalho lt
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                      AND LT.CdHistCargoCom IS NOT NULL
                      AND LT.DtInicio <= pDtFim
                    GROUP BY lt.cdhistcargocom) lt1
          ON lt1.cdhistcargocom = hcc.cdhistcargocom
       INNER JOIN ecadlocaltrabalho lt
          ON LT.CdHistCargoCom = LT1.CdHistCargoCom
         AND LT.DtInicio = LT1.DtInicio
         AND (LT.DtFim >= pdtInicio OR LT.DtFim IS NULL)
       INNER JOIN ecadevolucaocargocomissionado ecc
          ON hcc.cdcargocomissionado = ecc.cdcargocomissionado
       INNER JOIN ecadevolucaoccocargahoraria ech
          ON ECC.CdEvolucaoCargoComissionado =
             ECH.CdEvolucaoCargoComissionado
         AND (ECC.DtInicioVigencia <= PKGPAG_VAR.vdtCalculo AND
             (ECC.DtFimvigencia >= PKGPAG_VAR.vdtCalculo OR
             ECC.Dtfimvigencia IS NULL))
         AND ECH.FlPadrao = PKGPAG_TIPO.cnS
       WHERE HCC.CdVinculo = pCdVinculo
         AND (HCC.CdCargoComRemuneracao IS NULL OR
             (HCC.CDCARGOCOMREMUNERACAO IS NOT NULL AND EXISTS
              (SELECT 1
                  FROM ECADHISTCARGOCOM HCC2
                 WHERE hcc2.cdvinculo = hcc.cdvinculo
                   AND hcc2.cdhistcargocomorigem = hcc.cdhistcargocom
                   AND hcc2.dtinicio > pdtinicio
                   AND hcc2.cdcargocomremuneracao IS NULL
                   AND TO_CHAR(HCC2.DTINICIO, 'MMYYYY') =
                       TO_CHAR(pDtInicio, 'MMYYYY')
                   AND HCC2.FLANULADO = PKGPAG_TIPO.cnN)))
         AND HCC.FlTipoProvimento IN (PKGPAG_TIPO.cnD, PKGPAG_TIPO.cnN)
         AND (HCC.DtInicio <= pDtFim AND
             (HCC.DtFim >= pDtInicio OR HCC.DtFim IS NULL))
         AND HCC.FlAnulado = PKGPAG_TIPO.cnN
       ORDER BY hcc.dtfim, hcc.dtinicio;

    CURSOR cccosubst(pcdvinculo      IN INTEGER,
                     pcdorgao        IN INTEGER,
                     pdtinicio       IN DATE,
                     pdtfim          IN DATE,
                     pnudiasminsubst IN INTEGER) IS
      SELECT *
        FROM (SELECT HCC.CdVinculo,
                     hcc.cdhistcargocom,
                     hcc.cdcargocomissionado,
                     hcc.cdorgaoexercicio,
                     c.cdgrupoocupacional,
                     hcc.cdrelacaotrabalho,
                     hcc.cdnaturezavinculo,
                     hcc.cdregimeprevidenciario,
                     hsp.cdsituacaoprevidenciaria,
                     hcc.cdregimetrabalho,
                     hcc.cdopcaoremuneracao,
                     CASE
                       WHEN hcc.dtinicio < pdtinicio THEN
                        pdtinicio
                       ELSE
                        hcc.dtinicio
                     END dtinicio,
                     CASE
                       WHEN (hcc.dtfim IS NULL) OR (hcc.dtfim > pdtfim) THEN
                        pdtfim
                       ELSE
                        hcc.dtfim
                     END dtfim,
                     hcc.dtinicio AS dtiniciorelacao,
                     hcc.dtfim AS dtfimrelacao,
                     hcc.nunivel,
                     hcc.nureferencia,
                     nvl(ech.nucargahoraria, 0) AS nucargahoraria,
                     nvl(ech.nucargahoraria, 0) AS nucargahorariapadrao,
                     lt.cdunidadeorganizacional,
                     hcc.fltipoprovimento,
                     hcc.dtinclusao,
                     0 AS cdmotivomovimentacao,
                     0 AS cdinstitutomovimentacao,
                     flpagasubsidio,
                     0 as QtNuDiasCCO
                FROM ecadhistcargocom hcc
               INNER JOIN ecadhistsitprevvinculo hsp
                  ON HCC.CdVinculo = HSP.CdVinculo
                 AND (HCC.DtInicio BETWEEN HSP.DtInicio AND
                     NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
               INNER JOIN ecadcargocomissionado c
                  ON hcc.cdcargocomissionado = c.cdcargocomissionado
               INNER JOIN (SELECT lt.cdhistcargocom,
                                 MAX(dtinicio) AS dtinicio
                            FROM ecadlocaltrabalho lt
                           WHERE LT.CdVinculo = pCdVinculo
                             AND LT.FlDefinitiva = PKGPAG_TIPO.cnS
                             AND LT.FlAnulado = PKGPAG_TIPO.cnN
                             AND LT.CdHistCargoCom IS NOT NULL
                             AND LT.DtInicio <= pDtFim
                           GROUP BY lt.cdhistcargocom) lt1
                  ON lt1.cdhistcargocom = hcc.cdhistcargocom
               INNER JOIN ecadlocaltrabalho lt
                  ON LT.CdHistCargoCom = LT1.CdHistCargoCom
                 AND LT.Dtinicio = LT1.DtInicio
                 AND (LT.DtFim >= pdtInicio OR LT.DtFim IS NULL)
               INNER JOIN ecadevolucaocargocomissionado ecc
                  ON hcc.cdcargocomissionado = ecc.cdcargocomissionado
               INNER JOIN ecadevolucaoccocargahoraria ech
                  ON ECC.CdEvolucaoCargoComissionado =
                     ECH.CdEvolucaoCargoComissionado
                 AND (ECC.DtInicioVigencia <= PKGPAG_VAR.vdtCalculo AND
                     (ECC.Dtfimvigencia >= PKGPAG_VAR.vdtCalculo OR
                     ECC.Dtfimvigencia IS NULL))
                 AND ECH.FlPadrao = PKGPAG_TIPO.cnS
               WHERE HCC.CdVinculo = pCdVinculo
                 AND HCC.FlTipoProvimento = PKGPAG_TIPO.cnS
                 AND (HCC.DtInicio <= pDtFim AND
                     (HCC.DtFim >= pDtInicio OR HCC.DtFim IS NULL))
                 AND HCC.FlAnulado = PKGPAG_TIPO.cnN
                 AND (NVL(HCC.DtFim, PKGPAG_TIPO.cnDtMax) - HCC.Dtinicio + 1 >
                     pNuDiasMinSubst) -- AQUI
               ORDER BY hcc.dtinicio DESC);
    --WHERE ROWNUM = 1 ;

  BEGIN
 
    pkgpag_var.vgcco := vtcco;
    i                := 0;
    vnudiascco       := 0;

    FOR vCCO IN cCCO(pCdVinculo,
                     PKGPAG_VAR.vgFolha.CdOrgao,
                     pkgpag_var.vgfolha.dtiniciomes,
                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      -- Tratamento para desconsiderar CCOs incluidos pos-folha
      -- quando recalculo especial

      IF pkgpag_var.vgfolha.flignorainclusaofutura = 'S' AND
         vcco.dtinclusao >= (pkgpag_var.vgfolha.dtcalculo + 1) THEN
        NULL;
      ELSIF fdevepagarcco THEN
        i          := i + 1;
        vnudiascco := vnudiascco + (vcco.dtfim - vcco.dtinicio + 1);

        -- Para um unico CCO iniciado no dia 2 deve ser considerado o dia 31
        -- SIG-9405 Questionamento de indice
        if vNuDiasCCO = 30 and pkgpag_var.vgCco.Count > 1 and
           vcco.dtinicio > pkgpag_var.vgfolha.dtiniciomes then
          vNuDiasCCO := vNuDiasCCO - 1;
        end if;
        -- Busca a opcao de remuneracao (ultima dentro do mes de processamento)
        vcco.cdopcaoremuneracao := fretornaopcaoremuneracaocco(pcdhistcargocom => vcco.cdhistcargocom,
                                                               pdtiniciomes    => pkgpag_var.vgfolha.dtiniciomes,
                                                               pdtfimmes       => pkgpag_var.vgfolha.dtfimmes);

        IF vcco.cdopcaoremuneracao IS NULL THEN
          pkgpag_geral.pinserelog(pkgpag_var.blog,
                                  pkgpag_var.vcdhistparamcalc,
                                  pkgpag_var.vcdpessoa,
                                  'O cargo comissionado n?o possui historico de op??o de remunera??o vigente.',
                                  PKGPAG_VAR.vgCdVinculo,
                                  2);
        END IF;

        pkgpag_var.vgcco(i) := vcco;
        pkgpag_var.vglistareltrab(vcco.cdrelacaotrabalho) := vcco.cdrelacaotrabalho;

        IF (PKGPAG_VAR.vgFolha.CdTipoCalculo in
           (PKGPAG_TIPO.cnTpCalculoRecalculoMes) AND
           NVL(PKGPAG_VAR.vgFolha.NuAnoMesImplantacao, '400001') >
           (PKGPAG_VAR.vgFolha.NuAnoReferencia ||
           LPAD(PKGPAG_VAR.vgFolha.NuMesReferencia, 2, '0')) AND
           vcco.dtinclusao > pkgpag_var.vdtcalculo AND
           vcco.cdorgaoexercicio <> pkgpag_var.vgvinculo.cdorgao) OR
           (vCCO.CdOpcaoRemuneracao = 5 AND -- comissionado com opcao militar na origem
           vCCO.CdOrgaoExercicio = PKGPAG_VAR.vgFolha.CdOrgao AND
           vCCO.CdOrgaoExercicio <> PKGPAG_VAR.vgVinculo.CdOrgao)
        -- OR (vCCO.CdOrgaoExercicio <> PKGPAG_VAR.vgVinculo.CdOrgao AND vCCO.CdOpcaoRemuneracao = 6 AND
        -- vCCO.dtfim < PKGPAG_VAR.vgFolha.DtCalculo AND PKGPAG_VAR.vgFolha.CdOrgao <> PKGPAG_VAR.vgVinculo.CdOrgao AND NOT PKGPAG_VAR.bPossuiDisposicao ) /* FABIO - TESTE para nao pagar no orgao de exercicio do CCO quando ja terminou a relacao vinculo */
         THEN
          pkgpag_var.bcalculavinculo := FALSE;
        ELSE
          pkgpag_var.bcalculavinculo := TRUE;
        END IF;

        -- Atualiza variaveis globais com o tipo de relacao de vinculo principal
        -- e o codigo da relacao de vinculo
        IF (vCCO.CdOpcaoRemuneracao = 3 AND
           vCCO.DtFim >= PKGPAG_VAR.vgFolha.DtCalculo) OR
           pkgpag_var.vgcef.count = 0 THEN
           
           IF pkgpag_var.vgfolha.cdAgrupamento = 1 THEN
             
            -- FIXADO O VINCULO POIS O CLIENTE NAO ESTA SEGURO DE USAR A CONDICAO ABAIXO
            -- DA FUNCAO FPossuiDisposicaoNoOrgao
            IF pkgpag_var.vgcef.count = 0 OR vcco.cdVinculo = 940803/* OR 
              FPossuiDisposicaoNoOrgao(vcco.CdVinculo,
                                       PKGPAG_VAR.vgFolha.CdOrgao, 
                                       PKGPAG_VAR.vgFolha.DtInicioMes, 
                                       PKGPAG_VAR.vgFolha.DtFimMes)*/ THEN
              pkgpag_var.vgrelvincprincipal.tipo := 2;  
            END IF;             
           
           ELSE
             pkgpag_var.vgrelvincprincipal.tipo := 2;   
           END IF;

          pkgpag_var.vgrelvincprincipal.cdhist                  := vcco.cdhistcargocom;
          pkgpag_var.vgrelvincprincipal.cdreltrabpagamento      := vcco.cdrelacaotrabalho;
          pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vcco.cdunidadeorganizacional;
        ELSIF vcco.cdopcaoremuneracao IN (6,9) THEN
          pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := vcco.cdunidadeorganizacional;
        else
          null;
        END IF;

        -- Alteracao realizada para limitar a 30 dias caso ele possua mais de um
        -- CCO dentro do mes
        IF i > 1 THEN
          IF vnudiascco > 30 THEN
            pkgpag_var.vgcco(i).dtfim := pkgpag_var.vgcco(i).dtfim - 1;
          END IF;
        END IF;
      else
        null;
      END IF;

      begin
        pkgpag_var.vgcco(i).QtNuDiasCCO := pkgpag_var.vgcco(i).dtfim - pkgpag_var.vgcco(i).dtinicio + 1;
        -- Para um unico CCO iniciado no dia 2 deve ser considerado o dia 31
        -- SIG-9405 Questionamento de indice
        if pkgpag_var.vgcco(i).QtNuDiasCCO = 30
          and pkgpag_var.vgcco(i).dtinicio > pkgpag_var.vgfolha.dtiniciomes
          and pkgpag_var.vgcco.count > 1 then
          pkgpag_var.vgcco(i).QtNuDiasCCO := pkgpag_var.vgcco(i).QtNuDiasCCO - 1;
        end if;
      exception
        when others then
          null;
      end;
      pArmazenaCargaHoraria(vCCO.CdHistCargoCom,
                            2,
                            vcco.NuCargaHorariaPadrao);
    END LOOP;

    PKGPAG_VAR.vgNuDiasCCO     := vNuDiasCCO;
    PKGPAG_VAR.bPossuiIprevCCO := FPossuiIprevCCO(pCdVinculo);

    /* ----------------------------------------------------------------------------------*/
    -- CARGO COMISSIONADO / SUBSTITUICAO
    /* -----------------------------------------------------------------------------------*/
    pkgpag_var.vgccosubst    := vtcco;
    pkgpag_var.vgnudiassubst := 0;
    i                        := 0;
    vnudiasminsubst          := 0;
    IF fPossuiVinculoSubst(pCdVinculo,
                           pkgpag_var.vgfolha.dtiniciomes,
                           PKGPAG_VAR.vgFolha.DtFimMes) THEN
      vCdOrgaoExercicioTitular := fObterCdOrgaoExercicioTitular(pcdvinculo,
                                                                pkgpag_var.vgfolha.dtiniciomes,
                                                                pkgpag_var.vgfolha.dtfimmes);

      vnudiasminsubst :=  CASE
                           WHEN pkgpag_var.vgFolha.CdAgrupamento NOT IN (1, 134, 176) THEN
                            10
                           WHEN pkgpag_var.vgFolha.cdOrgao IN (17) THEN
                            15
                           ELSE
                            1 END;
                      /*fpossuisubstferias(pcdvinculo,
                                            vCdOrgaoExercicioTitular,
                                            pkgpag_var.vgfolha.dtiniciomes,
                                            pkgpag_var.vgfolha.dtfimmes);*/

      FOR vCCOSubst IN cCCOSubst(pCdVinculo,
                                 PKGPAG_VAR.vgFolha.CdOrgao,
                                 pkgpag_var.vgfolha.dtiniciomes,
                                 PKGPAG_VAR.vgFolha.DtFimMes,
                                 vNuDiasMinSubst) LOOP
        -- Tratamento para desconsiderar CCOs incluidos pos-folha
        -- quando recalculo especial
        IF pkgpag_var.vgfolha.flignorainclusaofutura = 'S' AND
           vccosubst.dtinclusao >= (pkgpag_var.vgfolha.dtcalculo + 1) THEN
          NULL;
        ELSIF fdevepagarcco THEN
          i := i + 1;
          pkgpag_var.vgccosubst(i) := vccosubst;
          PKGPAG_VAR.vgNuDiasSubst := PKGPAG_VAR.vgNuDiasSubst +
                                      (PKGPAG_VAR.vgCCOSubst(i).DtFim - PKGPAG_VAR.vgCCOSubst(i).DtInicio + 1);
          PKGPAG_VAR.vgCCOSubst(i).CdOpcaoRemuneracao := FRetornaOpcaoRemuneracaoCCO(pCdHistCargoCom => PKGPAG_VAR.vgCCOSubst(i).CdHistCargoCom,
                                                                                     pdtiniciomes    => pkgpag_var.vgfolha.dtiniciomes,
                                                                                     pdtfimmes       => pkgpag_var.vgfolha.dtfimmes);
          IF PKGPAG_VAR.vgCCOSubst(i).CdOpcaoRemuneracao IS NULL THEN
            pkgpag_geral.pinserelog(pkgpag_var.blog,
                                    pkgpag_var.vcdhistparamcalc,
                                    pkgpag_var.vcdpessoa,
                                    'O cargo comissionado n?o possui historico de op??o de remunera??o vigente.',
                                    PKGPAG_VAR.vgCdVinculo,
                                    2);
          END IF;
        else
          null;
        END IF;
        pArmazenaCargaHoraria(vCCOSubst.CdHistCargoCom, 2);
      END LOOP;
    END IF;
  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de pensao nao previdenciaria
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaopensaonaoprev(pcdvinculo IN INTEGER) IS

    vtpensaonaoprev pkgpag_tipo.tpensaonaoprev;

    CURSOR cpensaonaoprev(pcdvinculo   IN INTEGER,
                          pcdorgao     IN INTEGER,
                          pdtiniciomes IN DATE,
                          pdtfimmes    IN DATE) IS
      SELECT hnp.cdvinculobeneficiario,
             hnp.cdhistpensaonaoprev,
             v.cdorgao AS cdorgaoexercicio,
             hnp.cdtipopensaonaoprev,
             hnp.cdvinculobeneficiario,
             hnp.cdpessoa,
             hnp.cdnaturezavinculo,
             v.cdregimetrabalho,
             v.cdregimeprevidenciario,
             hnp.cdsituacaoprevidenciaria,
             v.cdunidadeorganizacional,
             CASE
               WHEN HNP.DtInicio < pdtInicioMes THEN
                pdtiniciomes
               ELSE
                hnp.dtinicio
             END AS dtinicio,
             CASE
               WHEN HNP.DtFim > pdtFimMes OR HNP.DtFim IS NULL THEN
                pdtfimmes
               ELSE
                hnp.dtfim
             END AS dtfim,
             hnp.dtinicio AS dtiniciorelacao,
             hnp.dtfim AS dtfimrelacao,
             hnp.cdhistpensaonaoprevorigem,
             0 as NuCargaHoraria,
             0 as NuCargaHorariaPadrao,
             hnp.flprincipal,
             hnp.flparidaderemuneratoria,
             hnp.flpaga13,
             hnp.fladianta13,
             hnp.dtinclusao
        FROM epvdhistpensaonaoprev hnp
       INNER JOIN ecadvinculo v
          ON v.cdvinculo = hnp.cdvinculobeneficiario
       WHERE V.CdOrgao = pCdOrgao
         AND HNP.CdVinculoBeneficiario = pCdVinculo
         AND HNP.DtInicio <= pdtFimMes
         AND (to_char(HNP.DtFim,'yyyy') >= to_char(pdtInicioMes,'yyyy') OR HNP.DtFim IS NULL)
         AND HNP.FlAnulado = PKGPAG_TIPO.cnN;

  BEGIN
 
    pkgpag_var.vgpensaonaoprev := vtpensaonaoprev;

    OPEN cPensaoNaoPrev(pCdVinculo,
                        PKGPAG_VAR.vgFolha.CdOrgao,
                        pkgpag_var.vgfolha.dtiniciomes,
                        pkgpag_var.vgfolha.dtfimmes);

    FETCH cPensaoNaoPrev BULK COLLECT
      INTO PKGPAG_VAR.vgPensaoNaoPrev;

    CLOSE cpensaonaoprev;

    IF pkgpag_var.vgpensaonaoprev.count > 0 THEN

      pkgpag_var.vgrelvincprincipal.tipo := 7;

      PKGPAG_VAR.vgRelVincPrincipal.CdHist := PKGPAG_VAR.vgPensaoNaoPrev(1).CdHistPensaoNaoPrev;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := PKGPAG_VAR.vgPensaoNaoPrev(1).cdunidadeorganizacional;

    END IF;
  END;

  PROCEDURE pArmazenaInstituidorPNP(pcdvinculo IN INTEGER) IS

    vtpensaonaoprev pkgpag_tipo.tpensaonaoprev;

    CURSOR cpensaonaoprev(pcdvinculo   IN INTEGER,
                          pcdorgao     IN INTEGER,
                          pdtiniciomes IN DATE,
                          pdtfimmes    IN DATE) IS
      SELECT hnp.cdvinculobeneficiario,
             hnp.cdhistpensaonaoprev,
             v.cdorgao AS cdorgaoexercicio,
             hnp.cdtipopensaonaoprev,
             hnp.cdvinculobeneficiario,
             hnp.cdpessoa,
             hnp.cdnaturezavinculo,
             v.cdregimetrabalho,
             v.cdregimeprevidenciario,
             hnp.cdsituacaoprevidenciaria,
             v.cdunidadeorganizacional,
             CASE
               WHEN HNP.DtInicio < pdtInicioMes THEN
                pdtiniciomes
               ELSE
                hnp.dtinicio
             END AS dtinicio,
             pdtfimmes AS dtfim,
             hnp.dtinicio AS dtiniciorelacao,
             hnp.dtfim AS dtfimrelacao,
             hnp.cdhistpensaonaoprevorigem,
             0 as NuCargaHoraria,
             0 as NuCargaHorariaPadrao,
             hnp.flprincipal,
             hnp.flparidaderemuneratoria,
             hnp.flpaga13,
             hnp.fladianta13,
             hnp.dtinclusao
        FROM epvdhistpensaonaoprev hnp
       INNER JOIN ecadvinculo v
          ON v.cdvinculo = hnp.cdvinculobeneficiario
       INNER JOIN (select distinct ipp.cdvinculo
                     from epvdinstituidorpensaoprev ipp
                    inner join epvdhistpensaoprevidenciaria hpp
                       on hpp.cdhistpensaoprevidenciaria =
                          ipp.cdhistpensaoprevidenciaria
                    where ipp.flanulado = 'N'
                      and hpp.flanulado = 'N'
                      and hpp.dtinicio <= pdtFimMes
                      and (hpp.dtfim >= pdtInicioMes or hpp.dtfim is null)) ip
          ON ip.cdvinculo = v.cdvinculo
       WHERE V.CdOrgao = pCdOrgao
         AND HNP.CdVinculoBeneficiario = pCdVinculo
         AND HNP.DtInicio =
             (select max(pnp2.dtinicio)
                from epvdhistpensaonaoprev pnp2
               where pnp2.cdvinculobeneficiario = hnp.cdvinculobeneficiario
                 AND pnp2.flanulado = 'N')
         AND HNP.FlAnulado = PKGPAG_TIPO.cnN;

  BEGIN
 
    pkgpag_var.vgpensaonaoprev := vtpensaonaoprev;

    OPEN cPensaoNaoPrev(pCdVinculo,
                        PKGPAG_VAR.vgFolha.CdOrgao,
                        pkgpag_var.vgfolha.dtiniciomes,
                        pkgpag_var.vgfolha.dtfimmes);

    FETCH cPensaoNaoPrev BULK COLLECT
      INTO PKGPAG_VAR.vgPensaoNaoPrev;

    CLOSE cpensaonaoprev;

    IF pkgpag_var.vgpensaonaoprev.count > 0 THEN

      pkgpag_var.vgrelvincprincipal.tipo := 7;

      PKGPAG_VAR.vgRelVincPrincipal.CdHist := PKGPAG_VAR.vgPensaoNaoPrev(1).CdHistPensaoNaoPrev;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := PKGPAG_VAR.vgPensaoNaoPrev(1).cdunidadeorganizacional;

    END IF;
  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de pensao previdenciaria
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaopensaoprev(pcdvinculo IN INTEGER) IS

    vtpensaoprev pkgpag_tipo.tpensaoprev;
    i            INTEGER := 0;

  BEGIN
 
    pkgpag_var.vgpensaoprev := vtpensaoprev;
    IF pkgpag_var.vgfolha.cdorgao = 33  -- adicao devido a sol. sig-7062 ago/2022

    THEN
      PKGPAG_VAR.vMotAfast := pkgpag_cal.FAfastSemRemun(pcdvinculo,
                                                        PKGPAG_VAR.vgFolha.DtInicioMes,
                                                        PKGPAG_VAR.vgFolha.DtFimMes,
                                                        PKGPAG_VAR.vDtCalculo);

   END IF;


    FOR pensaoprev IN pkgpag_pensaoprevidenciaria.cPensaoPrevidenciaria(pcdvinculo,
                                                                        pkgpag_var.vgfolha.nuanoreferencia * 100 +
                                                                        pkgpag_var.vgfolha.numesreferencia) LOOP

      i := i + 1;

      vtpensaoprev(i).cdhistpensaoprevidenciaria := pensaoprev.cdhistpensaoprevidenciaria;
      vtpensaoprev(i).cdvinculo := pensaoprev.cdvinculo;
      vtpensaoprev(i).dtinicio := greatest(pensaoprev.dtinicio,
                                           pkgpag_var.vgfolha.dtInicioMes);
      vtpensaoprev(i).dtfim := least(nvl(pensaoprev.dtfim,
                                         pkgpag_var.vgfolha.dtFimMes),
                                     pkgpag_var.vgfolha.dtFimMes);
      vtpensaoprev(i).flpessoainvalida := pensaoprev.flpessoainvalida;
      vtpensaoprev(i).cdnaturezavinculo := pensaoprev.cdnaturezavinculo;
      vtpensaoprev(i).cdunidadeorganizacional := pensaoprev.cdunidadeorganizacional;
      vtpensaoprev(i).cddocumento := pensaoprev.cddocumento;
      vtpensaoprev(i).cdtipopublicacao := pensaoprev.cdtipopublicacao;
      vtpensaoprev(i).dtpublicacao := pensaoprev.dtpublicacao;
      vtpensaoprev(i).nupublicacao := pensaoprev.nupublicacao;
      vtpensaoprev(i).nupaginicial := pensaoprev.nupaginicial;
      vtpensaoprev(i).cdmeiopublicacao := pensaoprev.cdmeiopublicacao;
      vtpensaoprev(i).deoutromeio := pensaoprev.deoutromeio;
      vtpensaoprev(i).nucpfcadastrador := pensaoprev.nucpfcadastrador;
      vtpensaoprev(i).dtinclusao := pensaoprev.dtinclusao;
      vtpensaoprev(i).dtanulado := pensaoprev.dtanulado;
      vtpensaoprev(i).flanulado := pensaoprev.flanulado;
      vtpensaoprev(i).dtultalteracao := pensaoprev.dtultalteracao;
      vtpensaoprev(i).cdgrauparentescoprevfin := pensaoprev.cdgrauparentescoprevfin;
      vtpensaoprev(i).deobservacao := pensaoprev.deobservacao;
      vtpensaoprev(i).cdrelacaovinculo := 6;

    END LOOP;

    pkgpag_var.vgpensaoprev := vtpensaoprev;

    IF pkgpag_var.vgpensaoprev.count > 0 THEN

      pkgpag_var.vgrelvincprincipal.tipo := 6;

      PKGPAG_VAR.vgRelVincPrincipal.CdHist := PKGPAG_VAR.vgPensaoPrev(1).CdHistPensaoPrevidenciaria;

      pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := PKGPAG_VAR.vgPensaoPrev(1).cdunidadeorganizacional;

    END IF;
  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo de funcao chefia
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaofuncaochefia(pcdvinculo IN INTEGER) IS

    i INTEGER;

    /* Cursor cFUC: Seleciona as relacoes de vinculo vigentes no Ano/Mes e os
    respectivas datas de inicio e fim                        */

    CURSOR cfuc(pcdvinculo   IN INTEGER,
                pcdorgao     IN INTEGER,
                pdtiniciomes IN DATE,
                pdtfimmes    IN DATE) IS
      SELECT *
        FROM (SELECT hfc.cdvinculo,
                     hfc.cdhistfuncaochefia,
                     hsp.cdsituacaoprevidenciaria,
                     hfc.cdfuncaochefia,
                     hfc.cdtipofuncaochefia,
                     hfc.cdorgaoexercicio,
                     CASE
                       WHEN HFC.DtInicio < pdtInicioMes THEN
                        pdtiniciomes
                       ELSE
                        hfc.dtinicio
                     END AS dtinicio,
                     CASE
                       WHEN hfc.dtfim IS NULL THEN
                        pdtfimmes
                       WHEN hfc.dtfim IS NOT NULL THEN
                        CASE
                          WHEN HFC.DtFim > pdtFimMes THEN
                           pdtfimmes
                          ELSE
                           hfc.dtfim
                        END
                     END AS dtfim,
                     hfc.dtinicio AS dtiniciorelacao,
                     hfc.dtfim AS dtfimrelacao,
                     lt.cdunidadeorganizacional,
                     efc.cdpadraofucagrup,
                     efc.flfuncaogratificada,
                     nvl(eic.nucargahoraria, 0) AS nucargahoraria,
                     nvl(eic.nucargahoraria, 0) AS nucargahorariapadrao,
                     hfc.flefetivacao,
                     efc.cdevolucaofuncaochefia,
                     efc.cdtipounidorg,
                     hfc.dtinclusao,
                     efc.flproporcionalizacho,
                     efc.cdtipofuncaochefia as cdtipofuncaoprivativa,
                     hfc.cdhistcargoefetivoorigem
                FROM ecadhistfuncaochefia hfc
               INNER JOIN ecadhistsitprevvinculo hsp
                  ON HFC.CdVinculo = HSP.CdVinculo
                 AND (HFC.DtInicio BETWEEN HSP.DtInicio AND
                     NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
               INNER JOIN ecadevolucaofuncaochefia efc
                  ON hfc.cdfuncaochefia = efc.cdfuncaochefia
               INNER JOIN (SELECT lt.cdhistfuncaochefia,
                                 MAX(dtinicio) AS dtinicio
                            FROM ecadlocaltrabalho lt
                           WHERE LT.CdVinculo = pCdVinculo
                             AND LT.CdHistFuncaoChefia IS NOT NULL
                             AND LT.DtInicio <= pdtFimMes
                             AND LT.FlAnulado = PKGPAG_TIPO.cnN
                           GROUP BY lt.cdhistfuncaochefia) lt1
                  ON lt1.cdhistfuncaochefia = hfc.cdhistfuncaochefia
               INNER JOIN ecadlocaltrabalho lt
                  ON LT.CdHistFuncaoChefia = LT1.CdHistFuncaoChefia
                 AND LT.DtInicio = LT1.DtInicio
                 AND (LT.DtFim >= pdtInicioMes OR LT.DtFim IS NULL)
               INNER JOIN ecadevolucaofucitemcargahor eic
                  ON EFC.CdEvolucaoFuncaoChefia = EIC.CdEvolucaoFuncaoChefia
                 AND (EFC.DtInicioVigencia <= PKGPAG_VAR.vdtCalculo AND
                     (EFC.Dtfimvigencia >= PKGPAG_VAR.vdtCalculo OR
                     EFC.Dtfimvigencia IS NULL))
                 AND EIC.FlPadrao = PKGPAG_TIPO.cnS
                 AND EFC.FlFuncaoGratificada = PKGPAG_TIPO.cnS
               WHERE HFC.CdVinculo = pCdVinculo
                 AND PKGPAG_VAR.vPagaSitDisposicao IN
                     ('PAG-DEST-CALCULO-DEST',
                      'PAG-ORIGEM-CALCULO-ORIGEM',
                      'PAG-DEST-ADVINDO-DE-FORA',
                      'PAG-DISP-ONUS-ORIGEM')
                 AND EXISTS
               (SELECT CdHistCargoEfetivo
                        FROM ecadhistcargoefetivo cef
                       WHERE CEF.CdVinculo = pCdVinculo
                         AND CEF.CdHistCargoEfetivo =
                             HFC.CdHistCargoEfetivoOrigem
                         AND CEF.FlAnulado = PKGPAG_TIPO.cnN)
                 AND HFC.FlEfetivacao = PKGPAG_TIPO.cnT
                 AND ((HFC.DtInicio <= pdtFimMes) AND
                     (HFC.DtFim >= pdtInicioMes OR HFC.DtFim IS NULL))
                 AND HFC.FlAnulado = PKGPAG_TIPO.cnN
                 AND (HFC.InPagamento = 'D' OR HFC.InPagamento IS NULL)
                 AND NOT EXISTS
               (SELECT 1
                        FROM ecadhistcargocom cco
                       WHERE CCO.CdVinculo = HFC.CdVinculo
                         AND CCO.CdCargoComRemuneracao IS NULL
                         AND CCO.FlAnulado = PKGPAG_TIPO.cnN
                         AND CCO.FlTipoProvimento IN
                             (PKGPAG_TIPO.cnD, PKGPAG_TIPO.cnN)
                         AND (CCO.DtInicio <= pDtFimMes)
                         AND (CCO.DtFim >= pDtInicioMes OR CCO.DtFim IS NULL)
                         AND (HFC.DtInicio BETWEEN CCO.DtInicio AND
                             NVL(CCO.DtFim, PKGPAG_TIPO.cnDtMax) OR
                             CCO.DtInicio BETWEEN HFC.DtInicio AND
                             NVL(HFC.DtFim, PKGPAG_TIPO.cnDtMax)))
               ORDER BY hfc.dtinicio DESC);

    /* Cursor cFUCSubst: Seleciona as relacoes de vinculo vigentes no Ano/Mes e os
    respectivas datas de inicio e fim                        */

    CURSOR cfucsubst(pcdvinculo   IN INTEGER,
                     pcdorgao     IN INTEGER,
                     pdtiniciomes IN DATE,
                     pdtfimmes    IN DATE) IS
      SELECT hfc.cdvinculo,
             hfc.cdhistfuncaochefia,
             hsp.cdsituacaoprevidenciaria,
             hfc.cdfuncaochefia,
             hfc.cdtipofuncaochefia,
             hfc.cdorgaoexercicio,
             CASE
               WHEN HFC.DtInicio < pdtInicioMes THEN
                pdtiniciomes
               ELSE
                hfc.dtinicio
             END AS dtinicio,
             CASE
               WHEN hfc.dtfim IS NULL THEN
                pdtfimmes
               WHEN hfc.dtfim IS NOT NULL THEN
                CASE
                  WHEN HFC.DtFim > pdtFimMes THEN
                   pdtfimmes
                  ELSE
                   hfc.dtfim
                END
             END AS dtfim,
             hfc.dtinicio AS dtiniciorelacao,
             hfc.dtfim AS dtfimrelacao,
             lt.cdunidadeorganizacional,
             efc.cdpadraofucagrup,
             efc.flfuncaogratificada,
             nvl(eic.nucargahoraria, 0) AS nucargahoraria,
             nvl(eic.nucargahoraria, 0) AS nucargahorariapadrao,
             hfc.flefetivacao,
             efc.cdevolucaofuncaochefia,
             efc.cdtipounidorg,
             hfc.dtinclusao,
             efc.flproporcionalizacho,
             efc.cdtipofuncaochefia as CdTipoFuncaoChefiaPrivativa,
             hfc.cdhistcargoefetivoorigem
        FROM ecadhistfuncaochefia hfc
       INNER JOIN ecadhistsitprevvinculo hsp
          ON HFC.CdVinculo = HSP.CdVinculo
         AND (HFC.DtInicio BETWEEN HSP.DtInicio AND
             NVL(HSP.DtFim, PKGPAG_TIPO.cnDtMax))
       INNER JOIN (SELECT LT.CdHistFuncaoChefia, MAX(DtInicio) AS DtInicio
                     FROM ecadlocaltrabalho lt
                    WHERE LT.CdVinculo = pCdVinculo
                      AND LT.CdHistFuncaoChefia IS NOT NULL
                      AND LT.DtInicio <= pDtFimMes
                      AND LT.FlAnulado = PKGPAG_TIPO.cnN
                    GROUP BY lt.cdhistfuncaochefia) lt1
          ON lt1.cdhistfuncaochefia = hfc.cdhistfuncaochefia
       INNER JOIN ecadlocaltrabalho lt
          ON LT.CdHistFuncaoChefia = LT1.CdHistFuncaoChefia
         AND LT.DtInicio = LT1.DtInicio
         AND (LT.DtFim >= pdtInicioMes OR LT.DtFim IS NULL)
       INNER JOIN ecadevolucaofuncaochefia efc
          ON hfc.cdfuncaochefia = efc.cdfuncaochefia
       INNER JOIN ecadevolucaofucitemcargahor eic
          ON EFC.CdEvolucaoFuncaoChefia = EIC.CdEvolucaoFuncaoChefia
         AND (EFC.dtInicioVigencia <= PKGPAG_VAR.vdtCalculo AND
             (EFC.Dtfimvigencia >= PKGPAG_VAR.vdtCalculo OR
             EFC.Dtfimvigencia IS NULL))
         AND EIC.FlPadrao = PKGPAG_TIPO.cnS
         AND EFC.FlFuncaoGratificada = PKGPAG_TIPO.cnS
       WHERE (HFC.CdVinculo = pCdVinculo)
         AND HFC.FlEfetivacao IN (PKGPAG_TIPO.cnS, PKGPAG_TIPO.cnR)
         AND ((HFC.DtInicio <= pdtFimMes) AND
             (HFC.DtFim >= pdtInicioMes OR HFC.DtFim IS NULL))
         AND HFC.Flanulado = PKGPAG_TIPO.cnN
         AND NOT EXISTS
       (SELECT 1
                FROM ecadhistcargocom cco
               WHERE CCO.CdVinculo = HFC.CdVinculo
                 AND CCO.CdCargoComRemuneracao IS NULL
                 AND CCO.FlAnulado = PKGPAG_TIPO.cnN
                 AND CCO.FlTipoProvimento IN
                     (PKGPAG_TIPO.cnD, PKGPAG_TIPO.cnN)
                 AND (CCO.DtInicio <= pDtFimMes)
                 AND (CCO.DtFim >= pDtInicioMes OR CCO.DtFim IS NULL))
         AND (NVL(HFC.DtFim, pDtFimMes) - HFC.Dtinicio + 1 >=
             --exceto para Militares e DPE, REGRA DA SUBSTITUI??O DE CARGO COMISSIONADO QUE TEM O MINIMO DE 10 DIAS
             CASE
               WHEN pkgpag_var.vgFolha.CdAgrupamento NOT IN (1, 134, 176) THEN
                10
               WHEN pkgpag_var.vgFolha.cdOrgao IN (17) THEN
                15
               ELSE
                1
             END)
       ORDER BY hfc.dtinicio DESC;

  BEGIN
 
    /* ----------------------------------------------------------------------------------*/
    -- FUNCAO DE CHEFIA
    /* -----------------------------------------------------------------------------------*/

    pkgpag_var.vgfuc.delete;

    pkgpag_var.vgNuDiasFUC := 0;

    i := 0;

    FOR vFUC IN cFUC(pCdVinculo,
                     PKGPAG_VAR.vgFolha.CdOrgao,
                     pkgpag_var.vgfolha.dtiniciomes,
                     PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      IF pkgpag_var.vgfolha.flignorainclusaofutura = 'S' AND
         vfuc.dtinclusao >= (pkgpag_var.vgfolha.dtcalculo + 1) THEN

        NULL;

      ELSE

        i := i + 1;

        pkgpag_var.vgfuc(i) := vfuc;

        pkgpag_var.vgNuDiasFUC := pkgpag_var.vgNuDiasFUC + pkgpag_var.vgfuc(i).DtFim - pkgpag_var.vgfuc(i).DtInicio + 1;

      END IF;

      pArmazenaCargaHoraria(vFuc.CdHistFuncaoChefia,
                            3,
                            vFuc.NuCargaHorariaPadrao);

    END LOOP;

    /* ----------------------------------------------------------------------------------*/
    -- FUNCAO DE CHEFIA / SUBSTITUICAO
    /* -----------------------------------------------------------------------------------*/

    pkgpag_var.vgfucsubst.delete;

    i := 0;

    pkgpag_var.vgNuDiasSubstFUC := 0;

    FOR vFUCSubst IN cFUCSubst(pCdVinculo,
                               PKGPAG_VAR.vgFolha.CdOrgao,
                               pkgpag_var.vgfolha.dtiniciomes,
                               PKGPAG_VAR.vgFolha.DtFimMes) LOOP

      IF pkgpag_var.vgfolha.flignorainclusaofutura = 'S' AND
         vfucsubst.dtinclusao >= (pkgpag_var.vgfolha.dtcalculo + 1) THEN

        NULL;

      ELSE

        i := i + 1;

        pkgpag_var.vgfucsubst(i) := vfucsubst;

        pkgpag_var.vgNuDiasSubstFUC := pkgpag_var.vgNuDiasSubstFUC + pkgpag_var.vgfucsubst(i).DtFim - pkgpag_var.vgfucsubst(i).DtInicio + 1;

        IF pkgpag_var.vgNuDiasSubstFUC > 30 THEN
          pkgpag_var.vgNuDiasSubstFUC := 30;
        END IF;

        --
        -- Se nao existe tipo de funcao de chefia no registro da substituicao
        -- procura no registro do substituido
        --
        IF pkgpag_var.vgfucsubst(i).cdtipofuncaochefia IS NULL THEN
          BEGIN

            SELECT fff.cdtipofuncaochefia
              INTO pkgpag_var.vgfucsubst(i).cdtipofuncaochefia
              FROM ecadhistfuncaochefia fff
             WHERE fff.cdhistfuncaochefia =
                   (SELECT fff1.cdhistfuctitular
                      FROM ecadhistfuncaochefia fff1
                     WHERE fff1.cdhistfuncaochefia = pkgpag_var.vgfucsubst(i).cdhistfuncaochefia);

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              pkgpag_var.vgfucsubst(i).cdtipofuncaochefia := NULL;
          END;
        END IF;
      END IF;

      pArmazenaCargaHoraria(vFucSubst.CdHistFuncaoChefia,
                            3,
                            vFucSubst.NuCargaHorariaPadrao);

    END LOOP;

    IF pkgpag_var.vgNuDiasSubstFUC > 0 AND pkgpag_var.vgNuDiasFUC > 0 AND
       pkgpag_var.vgnudiasfuc = 30 THEN

      pkgpag_var.vgNuDiasFUC := 30 - pkgpag_var.vgNuDiasSubstFUC;

    END IF;

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes de vinculo e monta listas invertidas
  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacaorelvinc IS

    virelvinc INTEGER;

    vregrelvinc    pkgpag_tipo.rrelvinc;
    vlsinvrelvazio pkgpag_tipo.rlsinvrel;

    PROCEDURE padicionarrelvinc(pirel IN INTEGER) IS

    BEGIN
 
      virelvinc := virelvinc + 1;

      vregrelvinc.irelvinc := virelvinc;
      vregrelvinc.irel     := pirel;

      pkgpag_var.vgrelvinc(virelvinc) := vregrelvinc;

    END;

  BEGIN
 
    virelvinc := 0;

    pkgpag_var.vgrelvinc.delete;

    pkgpag_var.vglsinvrel := vlsinvrelvazio;

    pkgpag_var.vglsinvrelvinc := vlsinvrelvazio;

    -- Relacao CEF

    IF pkgpag_var.vgcef.count > 0 THEN

      FOR irel IN pkgpag_var.vgcef.first .. pkgpag_var.vgcef.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.cef := pkgpag_var.vgcef(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvinccef;
        vregrelvinc.cdrelacaovinculo        := vregrelvinc.cef.cdrelacaovinculo;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.cef.cdhistrelvinc;
        vregrelvinc.cdrelacaotrabalho       := vregrelvinc.cef.cdrelacaotrabalho;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.cef.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.cef.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.cef.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.cef.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.cef.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.cef.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.cef(vregrelvinc.cef.cdhistrelvinc) := irel;
        pkgpag_var.vglsinvrelvinc.cef(vregrelvinc.cef.cdhistrelvinc) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao FUC

    IF pkgpag_var.vgfuc.count > 0 THEN

      FOR irel IN pkgpag_var.vgfuc.first .. pkgpag_var.vgfuc.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.fuc := pkgpag_var.vgfuc(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvincfuc;
        vregrelvinc.cdrelacaovinculo        := pkgpag_tipo.cntprelacaofuncaochefia;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.fuc.cdhistfuncaochefia;
        vregrelvinc.cdrelacaotrabalho       := NULL;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.fuc.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.fuc.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.fuc.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.fuc.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.fuc.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.fuc.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.fuc(vregrelvinc.fuc.cdhistfuncaochefia) := irel;
        pkgpag_var.vglsinvrelvinc.fuc(vregrelvinc.fuc.cdhistfuncaochefia) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao FUCSubst

    IF pkgpag_var.vgfucsubst.count > 0 THEN

      FOR irel IN pkgpag_var.vgfucsubst.first .. pkgpag_var.vgfucsubst.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.fucsubst := pkgpag_var.vgfucsubst(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvincfucsubst;
        vregrelvinc.cdrelacaovinculo        := NULL;
        vregrelvinc.cdhistrelvinc           := pkgpag_tipo.cntprelacaofuncaochefia;
        vregrelvinc.cdrelacaotrabalho       := NULL;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.fucsubst.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.fucsubst.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.fucsubst.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.fucsubst.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.fucsubst.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.fucsubst.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.fucsubst(vregrelvinc.fucsubst.cdhistfuncaochefia) := irel;
        pkgpag_var.vglsinvrelvinc.fucsubst(vregrelvinc.fucsubst.cdhistfuncaochefia) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao CCO

    IF pkgpag_var.vgcco.count > 0 THEN

      FOR irel IN pkgpag_var.vgcco.first .. pkgpag_var.vgcco.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.cco := pkgpag_var.vgcco(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvinccco;
        vregrelvinc.cdrelacaovinculo        := pkgpag_tipo.cntprelacaocomissionado;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.cco.cdhistcargocom;
        vregrelvinc.cdrelacaotrabalho       := vregrelvinc.cco.cdrelacaotrabalho;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.cco.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.cco.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.cco.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.cco.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.cco.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.cco.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.cco(vregrelvinc.cco.cdhistcargocom) := irel;
        pkgpag_var.vglsinvrelvinc.cco(vregrelvinc.cco.cdhistcargocom) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao CCOSubst

    IF pkgpag_var.vgccosubst.count > 0 THEN

      FOR irel IN pkgpag_var.vgccosubst.first .. pkgpag_var.vgccosubst.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.ccosubst := pkgpag_var.vgccosubst(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvincccosubst;
        vregrelvinc.cdrelacaovinculo        := pkgpag_tipo.cntprelacaocomissionado;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.ccosubst.cdhistcargocom;
        vregrelvinc.cdrelacaotrabalho       := vregrelvinc.ccosubst.cdrelacaotrabalho;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.ccosubst.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.ccosubst.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.ccosubst.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.ccosubst.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.ccosubst.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.ccosubst.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.ccosubst(vregrelvinc.ccosubst.cdhistcargocom) := irel;
        pkgpag_var.vglsinvrelvinc.ccosubst(vregrelvinc.ccosubst.cdhistcargocom) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao APO

    IF pkgpag_var.vgapo.count > 0 THEN

      FOR irel IN pkgpag_var.vgapo.first .. pkgpag_var.vgapo.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.apo := pkgpag_var.vgapo(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvincapo;
        vregrelvinc.cdrelacaovinculo        := vregrelvinc.apo.cdrelacaovinculo;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.apo.cdhistrelvinc;
        vregrelvinc.cdrelacaotrabalho       := vregrelvinc.apo.cdrelacaotrabalho;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.apo.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.apo.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.apo.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.apo.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.apo.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.apo.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.apo(vregrelvinc.apo.cdhistrelvinc) := irel;
        pkgpag_var.vglsinvrelvinc.apo(vregrelvinc.apo.cdhistrelvinc) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao APOSemParidade

    IF pkgpag_var.vgaposemparidade.count > 0 THEN

      FOR irel IN pkgpag_var.vgaposemparidade.first .. pkgpag_var.vgaposemparidade.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.aposemparidade := pkgpag_var.vgaposemparidade(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvincaposemparidade;
        vregrelvinc.cdrelacaovinculo        := vregrelvinc.aposemparidade.cdrelacaovinculo;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.aposemparidade.cdhistrelvinc;
        vregrelvinc.cdrelacaotrabalho       := vregrelvinc.aposemparidade.cdrelacaotrabalho;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.aposemparidade.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.aposemparidade.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.aposemparidade.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.aposemparidade.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.aposemparidade.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.aposemparidade.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.aposemparidade(vregrelvinc.aposemparidade.cdhistrelvinc) := irel;
        pkgpag_var.vglsinvrelvinc.aposemparidade(vregrelvinc.aposemparidade.cdhistrelvinc) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao BOL

    IF pkgpag_var.vgbol.count > 0 THEN

      FOR irel IN pkgpag_var.vgbol.first .. pkgpag_var.vgbol.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.bol := pkgpag_var.vgbol(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvincbol;
        vregrelvinc.cdrelacaovinculo        := pkgpag_tipo.cntprelacaoestagio;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.bol.cdhistestagio;
        vregrelvinc.cdrelacaotrabalho       := vregrelvinc.bol.cdrelacaotrabalho;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.bol.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.bol.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.bol.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.bol.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.bol.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.bol.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.bol(vregrelvinc.bol.cdhistestagio) := irel;
        pkgpag_var.vglsinvrelvinc.bol(vregrelvinc.bol.cdhistestagio) := virelvinc;

      END LOOP;

    END IF;

    -- Relacao PensaoNaoPrev

    IF pkgpag_var.vgpensaonaoprev.count > 0 THEN

      FOR irel IN pkgpag_var.vgpensaonaoprev.first .. pkgpag_var.vgpensaonaoprev.last LOOP

        vregrelvinc := NULL;

        vregrelvinc.pensaonaoprev := pkgpag_var.vgpensaonaoprev(irel);

        vregrelvinc.tipo                    := pkgpag_tipo.cnrelvincpensaonaoprev;
        vregrelvinc.cdrelacaovinculo        := pkgpag_tipo.cntprelacaopensaonaoprev;
        vregrelvinc.cdhistrelvinc           := vregrelvinc.pensaonaoprev.cdhistpensaonaoprev;
        vregrelvinc.cdrelacaotrabalho       := NULL;
        vregrelvinc.cdunidadeorganizacional := vregrelvinc.pensaonaoprev.cdunidadeorganizacional;
        vregrelvinc.dtinicio                := vregrelvinc.pensaonaoprev.dtinicio;
        vregrelvinc.dtfim                   := vregrelvinc.pensaonaoprev.dtfim;
        vregrelvinc.dtiniciorelacao         := vregrelvinc.pensaonaoprev.dtiniciorelacao;
        vregrelvinc.dtfimrelacao            := vregrelvinc.pensaonaoprev.dtfimrelacao;
        vregrelvinc.dtinclusao              := vregrelvinc.pensaonaoprev.dtinclusao;

        padicionarrelvinc(irel);

        pkgpag_var.vglsinvrel.pensaonaoprev(vregrelvinc.pensaonaoprev.cdhistpensaonaoprev) := irel;
        pkgpag_var.vglsinvrelvinc.pensaonaoprev(vregrelvinc.pensaonaoprev.cdhistpensaonaoprev) := virelvinc;

      END LOOP;

    END IF;

  END;

  /*-------------------------------------------------------------------------*/
  --  Armazena todas as relacoes do vinculo
  /*      Objetivo: Armazena as relacoes de vinculo em variaveis globais

    A relacao de vinculo principal de um vinculo sera sempre, obedecendo a ordem abaixo:

      a) A relacao de vinculo de ex-parlamentar, pois neste caso o vinculo tera apenas esta relacao ou,
      b) A relacao de vinculo de pensao nao previdenciaria, pois neste caso o vinculo tera apenas esta relacao ou,
      c) A relacao de vinculo de pensao previdenciaria, pois neste caso o vinculo tera apenas esta relacao ou,
      d) A relacao de vinculo de auxilio reclusao, pois neste caso o vinculo tera apenas esta relacao ou,
      e) A relacao de vinculo de bolsista, pois neste caso o vinculo tera apenas esta relacao ou,
      f) A relacao de vinculo de aposentadoria vigente, pois neste caso o vinculo tera apenas esta relacao ou,
      g) A relacao de vinculo de cargo comissionado quando o vinculo a possuir no mes/ano do calculo, como nomeado/designado, com opcao de recebimento pelo
         proprio comissionado e sem apontamento para recebimento para outro comissionado ou,
      h) A relacao de vinculo de cargo efetivo quando o vinculo o possuir no mes/ano do calculo, como titular com apontamento de relacao de vinculo principal.

  As relacoes de vinculo com provimento igual a substituicao ou pelo ato de responder nunca serao
  consideradas como relacoes principais.

  As relacoes de vinculo de funcao de chefia nunca serao consideradas como relacoes principais. */

  /*-------------------------------------------------------------------------*/

  PROCEDURE parmazenarelacoesvinculo(pcdvinculo   IN INTEGER,
                                     pflvalidapag IN CHAR DEFAULT 'S') IS

    vData pkgpag_tipo.tData;

    vCont INTEGER := 0;

    vCdSitPrev INTEGER := 0;

    vtapo pkgpag_tipo.tcef;

    vtaposemparidade pkgpag_tipo.tcef;

    FUNCTION fSitPrevVigente(pCdVinculo INTEGER)

     RETURN INTEGER IS

      vCdSitPrev INTEGER;

    BEGIN
 
      select hsp.cdsituacaoprevidenciaria
        into vCdSitPrev
        from ecadhistsitprevvinculo hsp
       where hsp.dtinicio = (select max(hsp.dtinicio)
                               from ecadhistsitprevvinculo hsp
                              where cdvinculo = pCdVinculo)
         and hsp.cdvinculo = pCdVinculo;

      RETURN vCdSitPrev;
    END;

    FUNCTION fretornaultimarelacao(pcdvinculo IN INTEGER)

     RETURN pkgpag_tipo.rrelvincprincipal IS

      vrelacaotrabalho pkgpag_tipo.rrelvincprincipal;

    BEGIN
 
      vrelacaotrabalho.tipo                    := NULL;
      vrelacaotrabalho.cdhist                  := NULL;
      vrelacaotrabalho.cdreltrabpagamento      := 0;
      vrelacaotrabalho.dtiniciorelacao         := NULL;
      vrelacaotrabalho.cdunidadeorganizacional := NULL;
      vrelacaotrabalho.nuchorelacao            := NULL;

      SELECT pkgpag_tipo.cntprelacaoestagio,
             cdhistestagio,
             cdrelacaotrabalho,
             dtinicio,
             cdunidadeorganizacional
        INTO vrelacaotrabalho.tipo,
             vrelacaotrabalho.cdhist,
             vrelacaotrabalho.cdreltrabpagamento,
             vrelacaotrabalho.dtiniciorelacao,
             vrelacaotrabalho.cdunidadeorganizacional
        FROM (SELECT he.cdhistestagio,
                     he.cdrelacaotrabalho,
                     he.dtinicio,
                     NULL AS cdunidadeorganizacional
                FROM ecadhistestagio he
               INNER JOIN ecadlocaltrabalho lt
                  ON he.cdhistestagio = lt.cdhistestagio
               WHERE he.cdvinculoestagio = pcdvinculo
               ORDER BY he.dtinicio DESC, lt.dtinicio DESC)
       WHERE rownum < 2;

      RETURN vrelacaotrabalho;

    EXCEPTION

      WHEN no_data_found THEN

        BEGIN

          SELECT pkgpag_tipo.cntprelacaocomissionado,
                 cdhistcargocom,
                 cdrelacaotrabalho,
                 dtinicio,
                 cdunidadeorganizacional,
                 nucargahoraria
            INTO vrelacaotrabalho.tipo,
                 vrelacaotrabalho.cdhist,
                 vrelacaotrabalho.cdreltrabpagamento,
                 vrelacaotrabalho.dtiniciorelacao,
                 vrelacaotrabalho.cdunidadeorganizacional,
                 vrelacaotrabalho.nuchorelacao
            FROM (SELECT cc.cdhistcargocom,
                         cc.cdrelacaotrabalho,
                         cc.dtinicio,
                         lt.cdunidadeorganizacional,
                         hc.nucargahoraria
                    FROM ecadhistcargocom cc
                   INNER JOIN ecadlocaltrabalho lt
                      ON lt.cdhistcargocom = cc.cdhistcargocom
                   INNER JOIN ecadhistcargahoraria hc
                      ON cc.cdhistcargocom = hc.cdhistcargocom
                   WHERE CC.CdVinculo = pCdVinculo
                     AND CC.FlAnulado = 'N'
                     AND HC.FlAnulado = 'N'
                   ORDER BY CC.DtFim     DESC,
                            CC.DtInicio  DESC,
                            LT.DtInicio  DESC,
                            HC.DtInicial DESC)
           WHERE rownum < 2;

          RETURN vrelacaotrabalho;

        EXCEPTION

          WHEN no_data_found THEN

            BEGIN

              SELECT pkgpag_tipo.cntprelacaoefetivo,
                     cdhistcargoefetivo,
                     cdrelacaotrabalho,
                     dtinicio,
                     cdunidadeorganizacional,
                     nucargahoraria
                INTO vrelacaotrabalho.tipo,
                     vrelacaotrabalho.cdhist,
                     vrelacaotrabalho.cdreltrabpagamento,
                     vrelacaotrabalho.dtiniciorelacao,
                     vrelacaotrabalho.cdunidadeorganizacional,
                     vrelacaotrabalho.nuchorelacao
                FROM (SELECT he.cdhistcargoefetivo,
                             he.cdrelacaotrabalho,
                             he.dtinicio,
                             lt.cdunidadeorganizacional,
                             hc.nucargahoraria
                        FROM ecadhistcargoefetivo he
                       INNER JOIN ecadlocaltrabalho lt
                          ON lt.cdhistcargoefetivo = he.cdhistcargoefetivo
                       INNER JOIN ecadhistcargahoraria hc
                          ON hc.cdhistcargoefetivo = he.cdhistcargoefetivo
                       WHERE HE.CdVinculo = pCdVinculo
                         AND HE.FlAnulado = 'N'
                         AND HC.FlAnulado = 'N'
                       ORDER BY HE.DTFIM     DESC,
                                HE.DtInicio  DESC,
                                LT.DtInicio  DESC,
                                HC.DtInicial DESC)
               WHERE rownum < 2;

              IF vrelacaotrabalho.cdreltrabpagamento =
                 PKGPAG_TIPO.cnRelCTISP AND pkgpag_var.vgfolha.cdtipofolha =
                 PKGPAG_TIPO.cnTpFolhaNormal AND
                 pkgpag_var.vgVinculo.nuseqmatricula < 30 THEN

                SELECT pkgpag_tipo.cntprelacaoefetivo,
                       cdhistcargoefetivo,
                       cdrelacaotrabalho,
                       dtinicio,
                       cdunidadeorganizacional,
                       nucargahoraria
                  INTO vrelacaotrabalho.tipo,
                       vrelacaotrabalho.cdhist,
                       vrelacaotrabalho.cdreltrabpagamento,
                       vrelacaotrabalho.dtiniciorelacao,
                       vrelacaotrabalho.cdunidadeorganizacional,
                       vrelacaotrabalho.nuchorelacao
                  FROM (SELECT he.cdhistcargoefetivo,
                               he.cdrelacaotrabalho,
                               he.dtinicio,
                               lt.cdunidadeorganizacional,
                               hc.nucargahoraria
                          FROM ecadhistcargoefetivo he
                         INNER JOIN ecadlocaltrabalho lt
                            ON lt.cdhistcargoefetivo = he.cdhistcargoefetivo
                         INNER JOIN ecadhistcargahoraria hc
                            ON hc.cdhistcargoefetivo = he.cdhistcargoefetivo
                         WHERE HE.CdVinculo = pCdVinculo
                           AND HE.FlAnulado = 'N'
                           AND HC.FlAnulado = 'N'
                         ORDER BY he.cdrelacaotrabalho,
                                  HE.DTFIM             DESC,
                                  HE.DtInicio          DESC,
                                  LT.DtInicio          DESC,
                                  HC.DtInicial         DESC)
                 WHERE rownum < 2;
              END IF;

              RETURN vrelacaotrabalho;

            EXCEPTION

              WHEN no_data_found THEN

                RETURN vrelacaotrabalho;

            END;

        END;

    END;

    FUNCTION fRetornaGrauEscolaridade(pcdVinculo IN INTEGER)

     RETURN INTEGER IS

      vGrauEscolaridade INTEGER;

    BEGIN
 
      SELECT NVL(MAX(NFGE.Cdnivelformacao), 3)
        INTO vGrauEscolaridade
        FROM ecadPessoaCurriculo PC
       INNER JOIN EcadVinculo v
          ON V.Cdpessoa = PC.Cdpessoa
       INNER JOIN EcadNivelFormGrauEsc NFGE
          ON PC.CdNivelFormGrauEsc = NFGE.CdNivelFormGrauEsc
       WHERE V.Cdvinculo = pcdVinculo
         AND PC.CdSituacaoCurso = 2 --concluido
         AND NFGE.Cdnivelformacao IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
            --1 ANOS INICIAIS (1/4 SERIE)
            --2 ANOS FINAIS (5/8 SERIE)
            --3 REGULAR
            --4 PROFISSIONALIZANTE
            --5 GRADUACAO
            --6 GRADUACAO TECNOLOGICA
            --7 ESPECIALIZACAO
            --8 MESTRADO
            --9 DOUTORADO
            --10  POS DOUTORADO
            --11  ANALFABETO
         AND pc.flanulado = 'N';

      RETURN vGrauEscolaridade;
    END;

  BEGIN
 
    -- PKGPAG_VAR.vgDtInicio      := SYSTIMESTAMP;

    pkgpag_var.bcalculavinculo := TRUE;

    -- Inicializar variavel global dias afastados por gravidez no mes para tratar afastamentos distintos. EPAGRI
    vgnudiasafastgravidez := 0;

    /* ----------------------------------------------------------------------------------*/
    /* Inicializa as variaveis globais da relacao de vinculo principal                   */
    /* ----------------------------------------------------------------------------------*/

    pkgpag_var.vgrelvincprincipal.tipo := NULL;

    pkgpag_var.vgrelvincprincipal.cdhist := NULL;

    pkgpag_var.vgrelvincprincipal.cdreltrabpagamento := NULL;

    pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional := NULL;

    pkgpag_var.bpossuiact := FALSE;

    pkgpag_var.bPossuiPensao := FALSE;

    PKGPAG_VAR.bPossuiIprevCCO := FPossuiIprevCCO(pCdVinculo);

    pkgpag_var.vgDtInicioComissao := vData;

    pkgpag_var.vgDtFimComissao := vData;

    pkgpag_var.vgNuDiasCef := 0;

    pkgpag_var.vgNuDiasApo := 0;

    PKGPAG_VAR.bPossuiCtisp := FALSE;

    pkgpag_var.vgNuDiasCargaHorariaZero := 0;

    pkgpag_var.vgCdMotivoConvocacao := 0; -- Motivo convocacao CTISP

    pkgpag_var.vgNuDiasCtisp := 0;
    
    --
    -- Solicitacao de Sustentacao #71742
    -- 9142/2016 - FOLHA - - NAO ESTA CALCULANDO IPREV
    --
    BEGIN

      SELECT cdsituacaoprevidenciaria
        INTO PKGPAG_VAR.vgCdSitPrevidenciariaAtual
        FROM (SELECT hspv.cdsituacaoprevidenciaria
                FROM ecadhistsitprevvinculo hspv
               WHERE HSPV.CdVinculo = pCdVinculo
                 AND HSPV.DtInicio <= pkgpag_var.vgfolha.dtfimmes
                 AND NVL(HSPV.DtFim, PKGPAG_TIPO.cnDtMax) >=
                     pkgpag_var.vgfolha.dtiniciomes
               ORDER BY hspv.dtinicio DESC)
       WHERE rownum < 2;

    EXCEPTION
      WHEN OTHERS THEN

        PKGPAG_VAR.vgCdSitPrevidenciariaAtual := 0;

    END;

    /* ----------------------------------------------------------------------------------*/
    /* Carga de outras informacoes do vinculo                                            */
    /* ----------------------------------------------------------------------------------*/

    pkgpag_var.bvinculocomcco := fpossuivinculocco(pcdvinculo,
                                                   pkgpag_var.vgfolha.cdorgao,
                                                   pkgpag_var.vgfolha.dtiniciomes,
                                                   pkgpag_var.vgfolha.dtfimmes);

    pkgpag_var.bpossuidisposicao := fpossuidisposicao(pcdvinculo,
                                                      pkgpag_var.vgfolha.dtiniciomes,
                                                      pkgpag_var.vgfolha.dtfimmes);

    IF pkgpag_var.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaInstPensao THEN

      vCdSitPrev := fsitprevvigente(pcdvinculo);

      IF vCdSitPrev in (pkgpag_tipo.cnSitPrevInstPensao,
                        pkgpag_tipo.cnSitPrevExParlamentar) THEN

        PArmazenaInstituidorEfetivo(pCdVinculo, pFlValidaPag);

        -- Solicitacaoo de Sustentacao #80284
        -- 12554/2018 - INSTITUIDOR GERENDO RUBRICAS INDEVIDAS

        pkgpag_var.vgapo            := vtapo;
        pkgpag_var.vgaposemparidade := vtaposemparidade;

        if pkgpag_var.vgRelVincPrincipal.tipo is null then
          pArmazenaInstituidorApoComPar(pcdvinculo);
          pArmazenaInstituidorApoSemPar(pcdvinculo);
          pArmazenaInstituidorPNP(pcdvinculo);
        end if;

        pArmazenaInstituidorComiss(pcdvinculo);

      ELSE

        RETURN;

      END IF;

    ELSE
       
      parmazenarelacaoapocomparidade(pcdvinculo);
      parmazenarelacaoaposemparidade(pcdvinculo);
      parmazenarelacaobolsista(pcdvinculo);
      pArmazenaRelacaoEfetivo(pCdVinculo, pFlValidaPag);
      parmazenarelacaocomissionado(pcdvinculo);
      parmazenarelacaopensaonaoprev(pcdvinculo);
      parmazenarelacaopensaoprev(pcdvinculo);
      parmazenarelacaofuncaochefia(pcdvinculo);

    END IF;

    parmazenarelacaorelvinc;

    IF pkgpag_var.vgrelvincprincipal.tipo IS NULL THEN

      pkgpag_var.vgrelvincprincipal := fretornaultimarelacao(pcdvinculo);

    END IF;

    IF pkgpag_var.vgrelvincprincipal.cdreltrabpagamento =
       PKGPAG_TIPO.cnRelCTISP THEN

      PKGPAG_VAR.bPossuiCtisp := TRUE;
      
      IF pkgpag_var.vgcef.count > 0 THEN

        FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

          IF pkgpag_var.vgcef(i).cdrelacaotrabalho = pkgpag_tipo.cnrelctisp THEN
             
             pkgpag_var.vgNuDiasCtisp := pkgpag_var.vgNuDiasCtisp +
             pkgpag_var.vgcef(i).DtFim - pkgpag_var.vgcef(i).DtInicio + 1;
             
             if pkgpag_var.vgNuDiasCtisp > 30 then
                pkgpag_var.vgNuDiasCtisp := 30;
             end if;
             
           
          END IF;

        END LOOP;

      END IF;

      BEGIN

        SELECT 1
          INTO vCont
          FROM epvdconvocacaoaposentado conv
         WHERE conv.cdvinculo = pcdvinculo -- conv.cdconcessaoaposentadoria = pkgpag_VAR.vgapo(1).cdhistrelvinc
           AND conv.dtinicioconvocacao <= pkgpag_var.vgFolha.DtFimMes
           AND (conv.dtfimconvocacao IS NULL OR
               conv.dtfimconvocacao > pkgpag_var.vgfolha.DtInicioMes)
           AND conv.flgerarpagamento = 'N'
           AND conv.flanulado = 'N'
           AND ROWNUM < 2;

        IF vCont = 1 THEN
          pkgpag_var.bGeraPagamentoCTISP := FALSE;
          pkgpag_var.vgCdMotivoConvocacao := 0;
        END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          pkgpag_var.bGeraPagamentoCTISP := TRUE;

        WHEN OTHERS THEN
          pkgpag_var.bGeraPagamentoCTISP := TRUE;

      END;

      if pkgpag_var.bGeraPagamentoCTISP then

         begin

         SELECT conv.cdmotivoconvocacao
          INTO pkgpag_var.vgCdMotivoConvocacao
          FROM epvdconvocacaoaposentado conv
         WHERE conv.cdvinculo = pcdvinculo -- conv.cdconcessaoaposentadoria = pkgpag_VAR.vgapo(1).cdhistrelvinc
           AND conv.dtinicioconvocacao <= pkgpag_var.vgFolha.DtFimMes
           AND (conv.dtfimconvocacao IS NULL OR
               conv.dtfimconvocacao > pkgpag_var.vgfolha.DtInicioMes)
           AND conv.flgerarpagamento = 'S'
           AND ROWNUM < 2;

         exception
           when others then
             pkgpag_var.vgCdMotivoConvocacao := 0;
         end;

      end if;

    END IF;

    pkgpag_var.vgNuGrauEscolaridade := fRetornaGrauEscolaridade(pcdvinculo);

    pkgpag_var.vgCdFolhaSuplementarVinculo := null;

    begin

      select cp.cdfolhapagamento
        into pkgpag_var.vgCdFolhaSuplementarVinculo
        from epagcapahistrubricavinculo cp
       inner join epagfolhapagamento fp
               on fp.cdfolhapagamento = cp.cdfolhapagamento
       where cp.cdvinculo = pCdVinculo
         and fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoSupl
         and fp.nuanomesreferencia = to_char(pkgpag_var.vgfolha.dtcalculoant,'yyyymm')
         and fp.flcalculodefinitivo = pkgpag_tipo.cnS;

      exception
        when others
          then
            pkgpag_var.vgCdFolhaSuplementarVinculo := null;

    end;

  END;

  ----------------------------------------------------------------------------------------
  --
  ----------------------------------------------------------------------------------------

  PROCEDURE pincluirubricamneurub(pcdrubricaagrupamentoexistente IN INTEGER,
                                  pcdrubricaagrupamentinserir    IN INTEGER,
                                  pcontidaem                     IN INTEGER) IS

  BEGIN
 
    IF pcontidaem IN (1, 3) THEN

      FOR vbasecalcblocoexpr IN (SELECT rub.cdbasecalculoblocoexpressao
                                   FROM epagbasecalcblocoexprrubagrup rub
                                  INNER JOIN epagbasecalculoblocoexpressao exp
                                     ON EXP.CdBaseCalculoBlocoExpressao =
                                        RUB.CdBaseCalculoBlocoExpressao
                                  INNER JOIN epagbasecalculobloco bl
                                     ON BL.CdBaseCalculoBloco =
                                        EXP.CdBaseCalculoBloco
                                  INNER JOIN epaghistbasecalculo hbs
                                     ON HBS.CdHistBaseCalculo =
                                        BL.CdHistBaseCalculo
                                    AND HBS.NuAnoFimVigencia IS NULL
                                  INNER JOIN epagbasecalculoversao v
                                     ON V.CdVersaoBaseCalculo =
                                        HBS.CdVersaoBaseCalculo
                                    AND V.NuVersao = 1
                                  INNER JOIN epagbasecalculo bc
                                     ON V.CdBaseCalculo = BC.CdBaseCalculo
                                    AND BC.CdOrgao IS NULL
                                  WHERE rub.cdrubricaagrupamento =
                                        pcdrubricaagrupamentoexistente) LOOP

        BEGIN

          INSERT INTO epagbasecalcblocoexprrubagrup
            (cdbasecalculoblocoexpressao, cdrubricaagrupamento)
          VALUES
            (vbasecalcblocoexpr.cdbasecalculoblocoexpressao,
             pcdrubricaagrupamentinserir);

        EXCEPTION

          WHEN OTHERS THEN

            NULL;

        END;

      END LOOP;

    END IF;

    IF pcontidaem IN (2, 3) THEN

      FOR vformcalcblocoexpr IN (SELECT rub2.cdformulacalcblocoexpressao
                                   FROM epagformcalcblocoexprubagrup rub2
                                  INNER JOIN EPAGFORMULACALCBLOCOEXPRESSAO EXP2
                                     ON EXP2.CDFORMULACALCBLOCOEXPRESSAO =
                                        rub2.cdformulacalcblocoexpressao
                                  INNER JOIN EPAGFORMULACALCULOBLOCO BL2
                                     ON BL2.CDFORMULACALCULOBLOCO =
                                        exp2.cdformulacalculobloco
                                  INNER JOIN EPAGEXPRESSAOFORMCALC EFC
                                     ON EFC.CDEXPRESSAOFORMCALC =
                                        bl2.cdexpressaoformcalc
                                  INNER JOIN EPAGHISTFORMULACALCULO HBS2
                                     ON HBS2.CDHISTFORMULACALCULO =
                                        efc.cdhistformulacalculo
                                    AND hbs2.nuanofim IS NULL
                                  INNER JOIN EPAGFORMULAVERSAO V2
                                     ON V2.CDFORMULAVERSAO =
                                        hbs2.cdformulaversao
                                    AND v2.nuformulaversao = 1
                                  INNER JOIN EPAGFORMULACALCULO FORM
                                     ON FORM.CDFORMULACALCULO =
                                        v2.cdformulacalculo
                                    AND form.cdorgao IS NULL
                                  WHERE rub2.cdrubricaagrupamento =
                                        pcdrubricaagrupamentoexistente) LOOP

        BEGIN

          INSERT INTO epagformcalcblocoexprubagrup
            (cdformulacalcblocoexpressao, cdrubricaagrupamento)
          VALUES
            (vformcalcblocoexpr.cdformulacalcblocoexpressao,
             pcdrubricaagrupamentinserir);

        EXCEPTION

          WHEN OTHERS THEN

            NULL;

        END;

      END LOOP;

    END IF;

  END;


  FUNCTION fflativo(pcdvinculo INTEGER, pcdsituacaoprevidenciaria INTEGER)
    RETURN CHAR IS

    vflativo  CHAR := 'S';

  BEGIN
 
    IF pkgpag_var.vgvinculo.bpossuiobito = TRUE THEN

      SELECT CASE
               WHEN COUNT(*) > 0 THEN
                'N' -- MANTER COMO "INATIVO", MESMO DEPOIS DE FALECIDOS, OS SERVIDORES QUE ERAM APOSENTADOS
               ELSE
                'S'
             END
        INTO vflativo
        FROM ecadhistsitprevvinculo sp
       INNER JOIN ecadvinculo v
          ON sp.cdvinculo = v.cdvinculo
       INNER JOIN ecadpessoa p
          ON p.cdpessoa = v.cdpessoa
        LEFT JOIN eafaregistroobito o
          ON o.cdpessoa = p.cdpessoa
       WHERE v.cdvinculo = pcdvinculo
         AND sp.dtfim = o.dtobito - 1
         AND sp.cdsituacaoprevidenciaria = 2
         and o.flanulado = PKGPAG_TIPO.cnN;

    ELSE


        vflativo := CASE
                      WHEN pcdsituacaoprevidenciaria <> 2 THEN
                       'S'
                      ELSE
                       'N'
                    END;

    END IF;

    RETURN vflativo;

  EXCEPTION

    WHEN OTHERS THEN

      vflativo := CASE
                    WHEN pcdsituacaoprevidenciaria <> 2 THEN
                     'S'
                    ELSE
                     'N'
                  END;

  END;
  
  
  FUNCTION FRetornaOrdemCalculo(pcdVinculo IN INTEGER, pFolha  IN PKGPAG_TIPO.rFolha) 
    
    RETURN INTEGER IS
    
    vNuOrdemCalculo INTEGER;
    
  BEGIN
   
   -- Para cálculo do tipo normal, olha apenas para calculo normal, dentro
   -- do mesmo agrupamento
   --

    SELECT NVL(MAX(NuOrdemCalculo),0)
      INTO vNuOrdemCalculo
      FROM EPagCapaHistRubricaVinculo CP
     INNER JOIN EPagFolhaPagamento FP 
        ON FP.CdFolhaPagamento = CP.Cdfolhapagamento
     INNER JOIN ECadVinculo V
        ON V.CdVinculo = CP.Cdvinculo
     WHERE FP.NuAnoReferencia = pFolha.NuAnoReferencia AND
           FP.NuMesReferencia = pFolha.NuMesReferencia AND
           FP.CdAgrupamento = pFolha.CdAgrupamento  AND
           V.CdPessoa = PKGPAG_VAR.vgVinculo.CdPessoa AND
           FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal,
                                PKGPAG_TIPO.cnTpCalculoRecalculoMes,
                                PKGPAG_TIPO.cnTpCalculoSupl,
                                PKGPAG_TIPO.cnTpCalculoPrevia) AND
           ((pFolha.FlCalculoDefinitivo = 'S' AND FP.FlCalculoDefinitivo = 'S') OR
            (pFolha.FlCalculoDefinitivo = 'N')); 
            
       RETURN (vNuOrdemCalculo + 1);     

  END;
  
  ------------------------------------------------------------------------------------
  -- Procedure: PGeraCapaLote
  --  Objetivo: Selecionar informacoes para o processamento
  -------------------------------------------------------------------------------------

  PROCEDURE pgeracapalote(pcdfolhapagamento       IN INTEGER,
                          pcdvinculo              IN INTEGER,
                          pflativo                IN CHAR,
                          pmotafast               IN pkgpag_tipo.rmotafast,
                          pflpagamentobloqueado   IN CHAR,
                          pVlPercentContribIndiv  IN NUMBER DEFAULT NULL) IS

    vcdrelacaotrabalho        INTEGER;
    vcdregimetrabalho         INTEGER;
    vnucho                    NUMBER(7, 4);
    vnuchorelacao             NUMBER(7, 4);
    vcdgrupoocupacional       INTEGER;
    vcdlocalidade             INTEGER;
    vcdvalorgeralcefagrup     INTEGER;
    vcdcargocomissionado      INTEGER;
    vnunivelcef               VARCHAR2(3);
    vnureferenciacef          VARCHAR2(3);
    vnureferenciacco          VARCHAR2(10);
    vnunivelcco               VARCHAR2(10);
    vcdestruturacarreira      INTEGER;
    vcdsituacaoprevidenciaria INTEGER;
    vcdnaturezavinculo        INTEGER;
    vcdunidadeorganizacional  INTEGER;
    vcdorgaointernoctisp      INTEGER;
    vcdorgaoexternoctisp      INTEGER;
    vCTISP                    pkgpag_tipo.rCTISP;
    vCdCentroCusto            integer;
    vInAposentadoriaEspecial  integer;
    vCdOrgaoOrigemPensionista integer;
    vNuOrdemCalculo           integer;

  BEGIN
 
    if pkgpag_var.vgvltotalproventos > 0 or pkgpag_var.vgvltotaldescontos > 0 then

      PAtualizaTotalizadoras(pcdfolhapagamento => pcdfolhapagamento,
                             pcdvinculo        => pcdvinculo);

      parmazenacho;

      vcdregimetrabalho         := pkgpag_var.vgvinculo.cdregimetrabalho;
      vcdsituacaoprevidenciaria := pkgpag_var.vgvinculo.cdsituacaoprevidenciaria;
      vcdrelacaotrabalho        := pkgpag_var.vgrelvincprincipal.cdreltrabpagamento;
      vnucho                    := pkgpag_var.vgrelvincprincipal.nucho;
      vnuchorelacao             := pkgpag_var.vgrelvincprincipal.nuchorelacao;
      vcdunidadeorganizacional  := pkgpag_var.vgrelvincprincipal.cdunidadeorganizacional;
      
      -----------------------------------------------------------------------------------
      --
      -----------------------------------------------------------------------------------
     
      vNuOrdemCalculo := FRetornaOrdemCalculo(pCdVinculo => pcdVinculo,
                                              pFolha     => PKGPAG_VAR.vgFolha);

      -- outros dados do vinculo --------------------------------------------
      begin
        select v.cdcentrocusto, v.inaposentadoriaespecial
          into vCdCentroCusto, vInAposentadoriaEspecial
          from ecadvinculo v
         where v.cdvinculo = pcdvinculo;
      exception
        when others then
          vCdCentroCusto           := null;
          vInAposentadoriaEspecial := null;
      end;
      -----------------------------------------------------------------------

      -- Caso a relacao trabalho seja CTISP, salva o orgao interno e externo (default 0)
      IF pkgpag_var.vgrelvincprincipal.cdreltrabpagamento =
         PKGPAG_TIPO.cnRelCTISP AND (PKGPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
         PKGPAG_VAR.vgVinculo.DtDesligamento >= pkgpag_var.vgFolha.DtInicioMes) THEN

        vCTISP := fArmazenaCTISP(pcdvinculo);

        vcdorgaointernoctisp := vCTISP.vCdOrgaoInterno;
        vcdorgaoexternoctisp := vCTISP.vCdOrgaoExterno;

        IF NVL(vcdorgaointernoctisp, 0) = 0 AND
           NVL(vcdorgaoexternoctisp, 0) = 0 THEN
          vcdorgaointernoctisp := pkgpag_var.vgFolha.cdorgao;
        END IF;

      END IF;

       -- Caso a relacao trabalho seja CTISP do orgao 2102, salva o orgao interno e externo para orgão da folha

      IF pkgpag_var.vgrelvincprincipal.cdreltrabpagamento =
         PKGPAG_TIPO.cnRelCTISP AND PKGPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
         pkgpag_var.vgFolha.cdorgao = 443
          THEN

        vCTISP := fArmazenaCTISP(pcdvinculo);

        vcdorgaointernoctisp := vCTISP.vCdOrgaoInterno;
        vcdorgaoexternoctisp := vCTISP.vCdOrgaoExterno;

        IF NVL(vcdorgaointernoctisp, 0) = 0 AND
           NVL(vcdorgaoexternoctisp, 0) = 0 THEN
          vcdorgaointernoctisp := pkgpag_var.vgFolha.cdorgao;
        END IF;

      END IF;

      -- Caso seja folha do 1505, salva orgao de origem do instituidor
      IF pkgpag_var.vgfolha.CdOrgao = 33 THEN

        vCdOrgaoOrigemPensionista := pkgpag_pensaoprevidenciaria.fCdOrgaoOrigemPensionista(pCdVinculoPensionista => pcdvinculo);

      END IF;

      CASE pkgpag_var.vgrelvincprincipal.tipo

        WHEN 1 THEN
          -- CEF

          IF pkgpag_var.vgcef.count > 0 THEN

            FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

              vcdnaturezavinculo    := pkgpag_var.vgcef(i).cdnaturezavinculo;
              vnunivelcef           := pkgpag_var.vgvalorfixocef.nunivel;
              vnureferenciacef      := pkgpag_var.vgvalorfixocef.nureferencia;
              vcdestruturacarreira  := pkgpag_var.vgvalorfixocef.cdestruturacarreira;

              IF vcdestruturacarreira IS NULL THEN
                 vcdestruturacarreira := pkgpag_var.vgcef(i).cdestruturacarreira;
              END IF;

              if vnunivelcef is null then
                 vNuNivelCef := pkgpag_var.vgcef(i).nunivelpagamento;
              end if;

              if vnureferenciacef is null then
                 vNuReferenciaCef := pkgpag_var.vgcef(i).nureferenciapagamento;
              end if;

              vcdvalorgeralcefagrup := pkgpag_var.vgvalorfixocef.cdvalorgeralcefagrup;

            END LOOP;

          END IF;

        WHEN 2 THEN
          -- CCO

          IF pkgpag_var.vgcco.count > 0 THEN

            FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST LOOP

              vnureferenciacco     := pkgpag_var.vgcco(i).nureferencia;
              vnunivelcco          := pkgpag_var.vgcco(i).nunivel;
              vnucho               := pkgpag_var.vgcco(i).nucargahorariapadrao;
              vnuchorelacao        := pkgpag_var.vgcco(i).nucargahorariapadrao;
              vcdcargocomissionado := pkgpag_var.vgcco(i).cdcargocomissionado;
              vcdgrupoocupacional  := pkgpag_var.vgcco(i).cdgrupoocupacional;
              vcdnaturezavinculo   := pkgpag_var.vgcco(i).cdnaturezavinculo;

            END LOOP;

          END IF;

        WHEN 4 THEN
          -- APO

          IF pkgpag_var.vgapo.count > 0 THEN

            FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST LOOP

              vnucho               := pkgpag_var.vgvalorfixocef.nucargahoraria;
              vnunivelcef          := pkgpag_var.vgvalorfixocef.nunivel;
              vnureferenciacef     := pkgpag_var.vgvalorfixocef.nureferencia;
              vcdestruturacarreira := pkgpag_var.vgvalorfixocef.cdestruturacarreira;
              vnuchorelacao        := pkgpag_var.vgapo(i).nucargahoraria;
              vcdnaturezavinculo   := pkgpag_var.vgapo(i).cdnaturezavinculo;

            END LOOP;

          END IF;

        ELSE

          NULL;

      END CASE;
      --
      -- Na da solicitacao: 7427/2015
      -- QUANDO O SERVIDOR POSSUIR FUNCAO DE CHEFIA,
      --  GRAVAR A UNIDADE ORGANIZACIONAL DO LOCAL DE TRABALHO DA FUNCAO NA CAPA DE PAGAMENTO.
      -------------------------------------------------------
      -- Na da solicitacao: 7834/2015
      -- CASO O SERVIDOR EXERCA UMA FUNCAO DE CHEFIA EM ORGAO NO QUAL ESTA A DISPOSICAO E
      -- O ONUS DO PAGAMENTO FOR PARA O ORGAO DESTINO, DEVERA PREVALECER A UNIDADE ORGANIZACIONAL
      -- DO LOCAL DE TRABALHO DA FUNCAO DE CHEFIA;
      IF pkgpag_var.vgFUC.Count > 0
        --AND PKGPAG_VAR.vPagaSitDisposicao = 'PAG-DEST-ADVINDO-DE-FORA'
         AND pkgpag_var.vgFuc(1)
        .CdOrgaoExercicio = pkgpag_var.vgCdOrgaoVinculo AND
         (pkgpag_var.vgFuc(1)
         .DtFimRelacao IS NULL OR trunc(pkgpag_var.vgFuc(1).DtFimRelacao) >=
          trunc(pkgpag_var.vgFolha.dtcalculo)) THEN

        vcdunidadeorganizacional := pkgpag_var.vgFuc(1).CdUnidadeOrganizacional;

      END IF;
      -------------------------------------------------------
      --
      -------------------------------------------------------

      DELETE FROM EPagCapaHistRubricaVinculo CV
       WHERE CV.CdFolhapagamento = pCdFolhaPagamento
         AND CV.CdVinculo = pCdVinculo;

      --  alter table EPagCapaHistRubricaVinculo add nuCHORelacao integer;

      -------------------------------------------------------
      --
      -------------------------------------------------------

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
         cdsituacaoprevidenciaria,
         nuchorelacao,
         cdnaturezavinculo,
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
         CDORGAOINTERNO,
         CDORGAOEXTERNO,
         cdCentroCusto,
         inAposentadoriaEspecial,
         cdOrgaoOrigemPensionista,
         NuOrdemCalculo,
         vlPercentContribIndiv
         )
      VALUES
        (pCdFolhaPagamento,
         pcdvinculo,
         pkgpag_var.vgvltotalproventos,
         pkgpag_var.vgvltotaldescontos,
         CASE pMotAfast.InTipoAfastamento WHEN 'T' THEN
         pMotAfast.CdChaveMotivo ELSE NULL END,
         CASE pMotAfast.InTipoAfastamento WHEN 'D' THEN
         pMotAfast.CdChaveMotivo ELSE NULL END,
         2,
         case when pkgpag_var.vgFolha.CdTipoFolha in
         (pkgpag_tipo.cnTpFolhaCtisp, pkgpag_tipo.cnTpFolhaCtisp13) then 'N' else
         pflativo end, -- Folha CTISP sempre INATIVO
         pflpagamentobloqueado,
         vcdrelacaotrabalho,
         vcdregimetrabalho,
         vnucho,
         vcdgrupoocupacional,
         vcdlocalidade,
         vcdvalorgeralcefagrup,
         vcdcargocomissionado,
         vnunivelcef,
         vnureferenciacef,
         vnureferenciacco,
         vnunivelcco,
         vcdestruturacarreira,
         vcdsituacaoprevidenciaria,
         vnuchorelacao,
         vcdnaturezavinculo,
         vcdunidadeorganizacional,
         PKGPAG_VAR.vgCdAgenciaCredito,
         PKGPAG_VAR.vgNuContaCredito,
         PKGPAG_VAR.vgNuDvContaCredito,
         PKGPAG_VAR.vgCdAgenciaReceb,
         PKGPAG_VAR.vgNuContaReceb,
         PKGPAG_VAR.vgFlTipoContaCredito,
         PKGPAG_VAR.vgNuAgencia,
         PKGPAG_VAR.vgNuDvAgencia,
         PKGPAG_VAR.vgNuBanco,
         vcdorgaointernoctisp,
         vcdorgaoexternoctisp,
         vCdCentroCusto,
         vInAposentadoriaEspecial,
         vCdOrgaoOrigemPensionista,
         vNuOrdemCalculo,
         pVlPercentContribIndiv);


        pkgpag_var.vgvalorfixocef.nunivel      := null;
        pkgpag_var.vgvalorfixocef.nureferencia := null;
        pkgpag_var.vgvalorfixocef.cdestruturacarreira := null;
    end if;
  END;

  FUNCTION fretornavalorrubricarv(pcdfolhapagamento     IN INTEGER,
                                  pcdvinculo            IN INTEGER,
                                  pcdrubricaagrupamento IN INTEGER,
                                  pcdrelacaovinculo     IN INTEGER)
    RETURN pkgpag_tipo.rvalorpagamento IS

    vvlpagamento pkgpag_tipo.rvalorpagamento;

  BEGIN
 
    SELECT nvl(hrv.vlreal, 0),
           nvl(hrv.vlintegral, 0),
           nvl(hrv.vlproporcional, 0),
           hrv.vlindicerubrica
      INTO vvlpagamento.vlreal,
           vvlpagamento.vlintegral,
           vvlpagamento.vlproporcional,
           vvlpagamento.vlindice
      FROM epaghistoricorubricarelvinc hrv
     WHERE hrv.cdfolhapagamento = pcdfolhapagamento
       AND hrv.cdvinculo = pcdvinculo
       AND hrv.cdrubricaagrupamento = pcdrubricaagrupamento
       AND hrv.cdrelacaovinculo = pcdrelacaovinculo
       AND rownum < 2;

    RETURN vvlpagamento;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  FUNCTION fretornavaloroutrasrv(pcdfolhapagamento     IN INTEGER,
                                 pcdvinculo            IN INTEGER,
                                 pcdrubricaagrupamento IN INTEGER)
    RETURN pkgpag_tipo.rvalorpagamento IS

    vvlpagamento pkgpag_tipo.rvalorpagamento;

  BEGIN
 
    SELECT sum(nvl(hrv.vlreal, 0)),
           sum(nvl(hrv.vlintegral, 0)),
           sum(nvl(hrv.vlproporcional, 0)),
           sum(nvl(hrv.vlindicerubrica, 0))
      INTO vvlpagamento.vlreal,
           vvlpagamento.vlintegral,
           vvlpagamento.vlproporcional,
           vvlpagamento.vlindice
      FROM epaghistoricorubricarelvinc hrv
     WHERE hrv.cdfolhapagamento = pcdfolhapagamento
       AND hrv.cdvinculo = pcdvinculo
       AND hrv.cdrubricaagrupamento = pcdrubricaagrupamento;

    RETURN vvlpagamento;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  -- Verifica disposicao finalizada ou iniciada no mes
  -- Obs: nao contempla vinculos finalizados no mes
  FUNCTION FDisposicaoParcialNoMes(pCEF   IN PKGPAG_TIPO.rCEF,
                                   pFolha IN PKGPAG_TIPO.rFolha)
    RETURN BOOLEAN IS

    vNuDiasDisposicao INTEGER := 0;

  BEGIN
 
    -- CONSIDERA QUE HOUVE A DISPOSICAO PARCIAL NO MES SE:

    -- 1) A RELACAO A SER VERIFICA FOR A DISPOSICAO

    IF pCEF.CdRelacaoTrabalho <> 10 THEN
      RETURN FALSE;
    END IF;

    -- 2) E A DATA DE DESLIGAMENTO DO VINCULO FOR MAIOR DO QUE O FINAL DO MES

    IF (PKGPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
       PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtFimMes) THEN
      RETURN FALSE;
    END IF;

    -- CONTA O NUMERO TOTAL DE DIAS A DISPOSICAO, BASEADO NOS CARGOS EFETIVOS CARREGADOS NO INICIO DO CALCULO
    FOR j IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST LOOP

      IF PKGPAG_VAR.vgCEF(j).CdRelacaoTrabalho = 10 THEN
        vNuDiasDisposicao := vNuDiasDisposicao +
                             (LEAST(NVL(PKGPAG_VAR.vgCEF(j).DtFimRelacao,
                                        pFolha.DtFimMes),
                                    pFolha.DtFimMes) -
                             GREATEST(PKGPAG_VAR.vgCEF(j).DtInicioRelacao,
                                       pFolha.DtInicioMes) + 1);
      END IF;

    END LOOP;

    -- 3) E O TOTAL DE DIAS A DISPOSICAO FOR MENOR QUE O TOTAL DE DIAS NO MES
    IF vNuDiasDisposicao < (pFolha.DtFimMes - pFolha.DtInicioMes + 1) THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

  function fVlTotalProventos13(pcdfolhapagamento IN INTEGER,
                               pcdvinculo        IN INTEGER) return number IS

    vVlTotalProventos13 number;

  BEGIN
 
    -- Seleciona Total de Proventos de 13?

    SELECT nvl(SUM(hrv.vlpagamento), 0)
      INTO vVlTotalProventos13
      FROM epaghistoricorubricavinculo hrv
     INNER JOIN epagrubricaagrupamento ra
        ON hrv.cdrubricaagrupamento = ra.cdrubricaagrupamento
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
     WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
       AND HRV.CdVinculo = pCdVinculo
       AND R.CdTipoRubrica IN (1, 2, 3, 4, 10, 12)
       and ra.flpropria13 = 'S';

    return vVlTotalProventos13;

  END;

  FUNCTION FObterDtInclusaoAfaDefinitivo(pCdVinculo IN INTEGER) RETURN DATE IS
    vDtInclusaoAfaDefinitivo DATE;
  BEGIN
 
    select DTINCLUSAO
      into vDtInclusaoAfaDefinitivo
      from eafaafastamentovinculo
     where cdvinculo = pCdVinculo
       and fltipoafastamento = 'D'
       and flanulado = 'N';

    RETURN vDtInclusaoAfaDefinitivo;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN TOO_MANY_ROWS THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION FAnoMesRecadPensLiberado(pNuAno IN INTEGER, pNuMes IN INTEGER)
    RETURN BOOLEAN IS
  BEGIN
    RETURN(pNuAno = 2020 AND pNuMes IN (3, 4, 5, 6, 7, 8, 9, 10, 11, 12)) OR pNuAno >= 2021;
  END;

  FUNCTION FOrgaoUtilizaFolhaPDI(pCdOrgao IN INTEGER) RETURN BOOLEAN IS
  BEGIN
     RETURN(pCdOrgao IS NOT NULL) AND(pCdOrgao in (25, 683));
  END;

  PROCEDURE PInserirAfastamentoTemporario(pCdVinculo                     INTEGER,
                                          pCdMotivoAfastamentoTemporario INTEGER,
                                          pDataInicio                    DATE) IS
  BEGIN
 
    INSERT INTO EAfaAfastamentoVinculo
      (cdafastamento,
       cdvinculo,
       fltipoafastamento,
       cdmotivoafasttemporario,
       dtinicio,
       dtfim,
       nucpfcadastrador,
       dtinclusao,
       dtultalteracao,
       flremunerado)
    VALUES
      (safaafastamentovinculo.nextval,
       pcdvinculo,
       'T',
       pCdMotivoAfastamentoTemporario,
       pDataInicio,
       NULL,
       '00000000000',
       SYSDATE,
       systimestamp,
       'N');
  END;

  PROCEDURE PObterInfoRecadastramento(pCdVinculo                  IN INTEGER,
                                      pQtdPagamentosBloqueados    OUT INTEGER,
                                      pQtdMesesSemRecadastramento OUT INTEGER) IS
  BEGIN
 
    SELECT SUM(CASE flpagamentobloqueado
                 WHEN 'S' THEN
                  1
                 ELSE
                  0
               END),
           SUM(CASE flrecadastrado
                 WHEN 'N' THEN
                  1
                 ELSE
                  0
               END)
      INTO pQtdPagamentosBloqueados, pQtdMesesSemRecadastramento
      FROM (SELECT FlPagamentoBloqueado, FlRecadastrado
              FROM (SELECT CV.FlPagamentoBloqueado, CV.FlRecadastrado
                      FROM epagcapahistrubricavinculo cv
                     INNER JOIN epagfolhapagamento fp
                        ON fp.cdfolhapagamento = cv.cdfolhapagamento
                     INNER JOIN epagtipofolhapagamento tfp
                        ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
                     WHERE CV.CdVinculo = pCdVinculo
                       AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
                       AND FP.CdTipoCalculo IN
                           (PKGPAG_TIPO.cnTpCalculoNormal,
                            PKGPAG_TIPO.cnTpCalculoSupl)
                       AND TFP.CdTipoFolha NOT IN
                           (PKGPAG_TIPO.cnTpFolha13,
                            pkgpag_tipo.cntpfolhaadiant13)
                     ORDER BY FP.NuAnoReferencia DESC,
                              FP.NuMesReferencia DESC)
             WHERE rownum < 3);
  END;

  -----------------------------------------------------------------------------------------------
  --  Gera afastamento por nao recadastramento
  --  Caso as duas ultimas capas estejam com FlBloqueado = 'S' and FlRecadastrado = 'N' indicara
  --  que deve ser gerado afastamento no primeiro dia do mes/ano do processamento para o servidor
  -----------------------------------------------------------------------------------------------
  FUNCTION FGerarAfastPorFaltaDeRecad(pCdVinculo   IN INTEGER,
                                      pCdTipoFolha IN INTEGER) RETURN BOOLEAN IS
    vnupagbloqueado    INTEGER;
    vnunaorecadastrado INTEGER;
    vGerarAfastamento  BOOLEAN := FALSE;

  BEGIN
 
    IF pCdTipoFolha NOT IN
       (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaAdiant13) THEN

      pkgpag_geral.PObterInfoRecadastramento(pCdVinculo                  => pCdVinculo,
                                             pQtdPagamentosBloqueados    => vnupagbloqueado,
                                             pQtdMesesSemRecadastramento => vnunaorecadastrado);

      -- Caso tenha se passado 90 dias da data de recadastramento e o servidor nao tenha se recadastrado,
      -- inclui um afastamento para o vinculo.
      IF vnupagbloqueado = 2 AND vnunaorecadastrado >= 2 THEN
        vGerarAfastamento := TRUE;
      END IF;

    END IF;

    RETURN vGerarAfastamento;
  END;

  PROCEDURE PTratarAfastPorFaltaDeRecad(pCdVinculo                     INTEGER,
                                        pCdPessoa                      INTEGER,
                                        pCdMotivoAfastamentoTemporario INTEGER,
                                        pDataInicioMes                 DATE,
                                        pCdOrgao                       INTEGER,
                                        pCdTipoFolha                   INTEGER,
                                        pInserirLog                    BOOLEAN,
                                        pCdHistoricoParamCalculo       INTEGER,
                                        pFlpagamentobloqueado          IN OUT CHAR) IS
  BEGIN
 
    IF pFlpagamentobloqueado = 'S' THEN
      IF pkgpag_geral.FGerarAfastPorFaltaDeRecad(pCdVinculo   => pCdVinculo,
                                                 pCdTipoFolha => pCdTipoFolha) THEN

        pkgpag_geral.PInserirAfastamentoTemporario(pCdVinculo                     => pCdVinculo,
                                                   pCdMotivoAfastamentoTemporario => pCdMotivoAfastamentoTemporario,
                                                   pDataInicio                    => pDataInicioMes);

        pkgpag_geral.pinserelog(pinsere                  => pInserirLog,
                                pcdhistoricoparamcalculo => pCdHistoricoParamCalculo,
                                pcdpessoa                => pCdPessoa,
                                pdelog                   => 'Servidor afastado por terceiro mes consecutivo sem recadastramento.',
                                pcdvinculo               => pCdVinculo,
                                pCdTipoOcorrencia        => 2, -- Ocorrencia
                                pcdmotivoocorrencia      => 12);

        -- Se o afastamento foi inserido, a informacao de que o pagamento esta bloqueado deve
        -- ser alterado para NAO -> 04/06/2012
        IF pCdOrgao = 33 THEN
          pFlpagamentobloqueado := 'A';
        ELSE
          pFlpagamentobloqueado := 'N';
        END IF;
      ELSE
        pkgpag_geral.pinserelog(pinsere                  => pInserirLog,
                                pcdhistoricoparamcalculo => pCdHistoricoParamCalculo,
                                pcdpessoa                => pCdPessoa,
                                pdelog                   => 'Servidor com pagamento bloqueado.',
                                pcdvinculo               => pCdVinculo,
                                pCdTipoOcorrencia        => 2, -- Ocorrencia
                                pcdmotivoocorrencia      => 11);

      END IF;
    END IF;
  END;

  FUNCTION FTratarBloqPgtoPensoesNaoPrev(pCdVinculo               INTEGER,
                                         pCdPessoa                INTEGER,
                                         pNuAnoReferencia         INTEGER,
                                         pNuMesReferencia         INTEGER,
                                         pCdTipoPensaoNaoPrev     INTEGER,
                                         pInserirLog              BOOLEAN,
                                         pCdHistoricoParamCalculo INTEGER)
    RETURN CHAR IS
    vFlpagamentobloqueado CHAR;
  BEGIN
 
    --O IF abaixo nao faz sentido como esta
    IF NOT pkgpag_var.vglistatipopnprecad.exists(pCdTipoPensaoNaoPrev) THEN
      vFlpagamentobloqueado := 'N';
    END IF;

    IF pkgpag_geral.FCreditobloqueadoPensionistaNP(pcdvinculo => pCdVinculo,
                                                   pnuano     => pNuAnoReferencia,
                                                   pnumes     => pNuMesReferencia) THEN
      vFlpagamentobloqueado := 'S';
      pkgpag_geral.pinserelog(pinsere                  => pInserirLog,
                              pcdhistoricoparamcalculo => pCdHistoricoParamCalculo,
                              pcdpessoa                => pCdPessoa,
                              pdelog                   => 'Servidor com pagamento bloqueado.',
                              pcdvinculo               => pCdVinculo,
                              pCdTipoOcorrencia        => 2, -- Ocorrencia
                              pcdmotivoocorrencia      => 11);
    ELSE
      vFlpagamentobloqueado := 'N';
    END IF;

    RETURN vFlpagamentobloqueado;
  END;

  FUNCTION FCreditobloqueadoPensionistaNP(pcdvinculo IN INTEGER,
                                          pnuano     IN INTEGER,
                                          pNuMes     IN INTEGER)
    RETURN BOOLEAN IS

    vcont INTEGER;
  BEGIN
 
    SELECT 1
      INTO vcont
      FROM epvdbloqueiocreditopensionista cp
     WHERE CP.CdVinculo = pCdVinculo
       AND (CP.NuAnoCompetencia * 100 + CP.NuMesCompetencia) <=
           (pNuAno * 100 + pNuMes)
       AND CP.InSituacao = 1
       AND ROWNUM < 2; -- Bloqueado

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  FUNCTION FTratarBloqPgtoInatEPensoesP(pCdVinculo                     INTEGER,
                                        pCdPessoa                      INTEGER,
                                        pDataNascimento                DATE,
                                        pCdOrgao                       INTEGER,
                                        pCdMotivoAfastamentoTemporario INTEGER,
                                        pNuAnoReferencia               INTEGER,
                                        pNuMesReferencia               INTEGER,
                                        pCdTipoFolha                   INTEGER,
                                        pCdTipoCalculo                 INTEGER,
                                        pDataInicioMes                 DATE,
                                        pInserirLog                    BOOLEAN,
                                        pCdHistoricoParamCalculo       INTEGER)
    RETURN CHAR IS

    vFlpagamentobloqueado CHAR;
    vCpfCadastrador       CHAR(11) := '00000000000'; -- Gerado pelo calculo
  BEGIN
 
    IF pCdTipoFolha NOT IN
       (PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaAdiant13) AND
       pCdTipoCalculo NOT IN
       (PKGPAG_TIPO.cnTpCalculoRecalculoMes, PKGPAG_TIPO.cnTpCalculoSupl) THEN

      IF pkgpag_geral.FPossuiAfastamentoTemporario(pCdVinculo                     => pCdVinculo,
                                                   pCdMotivoAfastamentoTemporario => pCdMotivoAfastamentoTemporario,
                                                   pDataInicio                    => pDataInicioMes,
                                                   pCpfcadastrador                => vCpfCadastrador) THEN

        pkgpag_geral.PExcluirAfastamentoTemporario(pCdVinculo                     => pCdVinculo,
                                                   pCdMotivoAfastamentoTemporario => pCdMotivoAfastamentoTemporario,
                                                   pDataInicio                    => pDataInicioMes,
                                                   pCpfcadastrador                => vCpfCadastrador);
      END IF;
    END IF;

    vFlpagamentobloqueado := pkgpag_geral.fpagamentobloqueado(pcdpessoa        => pCdPessoa,
                                                              pcdvinculo       => pCdVinculo,
                                                              pnuanoreferencia => pNuAnoReferencia,
                                                              pnumesreferencia => pNuMesReferencia,
                                                              pdtnascimento    => pDataNascimento);

    IF NOT FAnoMesRecadPensLiberado(pNuAnoReferencia, pNuMesReferencia) THEN
      pkgpag_geral.PTratarAfastPorFaltaDeRecad(pCdVinculo                     => pCdVinculo,
                                               pcdpessoa                      => pCdPessoa,
                                               pCdMotivoAfastamentoTemporario => pCdMotivoAfastamentoTemporario,
                                               pDataInicioMes                 => pDataInicioMes,
                                               pCdOrgao                       => pCdOrgao,
                                               pCdTipoFolha                   => pCdTipoFolha,
                                               pInserirLog                    => pInserirLog,
                                               pCdHistoricoParamCalculo       => pCdHistoricoParamCalculo,
                                               pFlPagamentoBloqueado          => vFlpagamentobloqueado);
    END IF;

    RETURN vFlpagamentobloqueado;
  END;

  FUNCTION FPossuiAfastTempAnteriorDtRef(pcdvinculo         IN INTEGER,
                                         pcdmotivoafasttemp IN INTEGER,
                                         pDataReferencia    IN DATE)
    RETURN BOOLEAN IS
    vcont INTEGER;
  BEGIN
 
    SELECT 1
      INTO vcont
      FROM eafaafastamentovinculo av
     WHERE AV.CdVinculo = pCdVinculo
       AND AV.CdMotivoAfastTemporario = pCdMotivoAfastTemp
       AND AV.DtInicio < pDataReferencia
       AND AV.DtFim IS NULL
       AND AV.FlAnulado = 'N'
       AND ROWNUM < 2;

    RETURN TRUE;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN FALSE;

  END;

  PROCEDURE PExcluirAfastamentoTemporario(pCdVinculo                     INTEGER,
                                          pCdMotivoAfastamentoTemporario INTEGER,
                                          pDataInicio                    DATE,
                                          pCpfcadastrador                CHAR) IS
  BEGIN
 
    DELETE FROM EAfaAfastamentoVinculo AV
     WHERE AV.CdVinculo = pCdVinculo
       AND AV.CdMotivoAfastTemporario = pCdMotivoAfastamentoTemporario
       AND AV.DtInicio = pDataInicio
       AND AV.NuCPFCadastrador = pCpfcadastrador;
  END;

  FUNCTION FPossuiAfastamentoTemporario(pCdVinculo                     INTEGER,
                                        pCdMotivoAfastamentoTemporario INTEGER,
                                        pDataInicio                    DATE,
                                        pCpfCadastrador                CHAR)
    RETURN BOOLEAN IS
    vCount INTEGER := 0;
  BEGIN
 
    SELECT 1
      INTO vCount
      FROM EAfaAfastamentoVinculo AV
     WHERE AV.CdVinculo = pcdvinculo
       AND AV.CdMotivoAfastTemporario = pCdMotivoAfastamentoTemporario
       AND AV.DtInicio = pDataInicio
       AND AV.NuCPFCadastrador = pCpfCadastrador
       AND ROWNUM < 2;

    RETURN vCount > 0;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
    WHEN OTHERS THEN
      RETURN FALSE;
  END;

  FUNCTION FObterDiasAfastamentoTemporario(pDtInicioMes       IN DATE,
                                           pDtFimMes          IN DATE,
                                           pCdVinculo         IN INTEGER,
                                           pListaMotAfastTemp IN sys.odcinumberlist)
    RETURN INTEGER IS
    vNuDiasAfast INTEGER := 0;
  BEGIN
 
    FOR rec IN (SELECT (DtFim - DtInicio) + 1 as NuDiasAfast
                  FROM (SELECT CASE
                                 WHEN AF.DtInicio < pDtInicioMes THEN
                                  pDtInicioMes
                                 ELSE
                                  AF.Dtinicio
                               END AS DtInicio,
                               CASE
                                 WHEN AF.DtFim > pDtFimMes OR AF.DtFim IS NULL THEN
                                  pDtFimMes
                                 ELSE
                                  AF.DtFim
                               END AS DtFim
                          FROM EAfaAfastamentoVinculo AF
                         WHERE AF.CdVinculo = pCdVinculo
                           AND AF.Cdmotivoafasttemporario IN
                               (SELECT column_value
                                  FROM TABLE(pListaMotAfastTemp))
                           AND AF.DtInicio <= pDtFimMes
                           AND (AF.DtFim >= pDtInicioMes OR AF.DtFim IS NULL)
                           AND AF.FlAnulado = 'N')) LOOP

      vNuDiasAfast := vNuDiasAfast + rec.NuDiasAfast;

    END LOOP;

    RETURN LEAST(vNuDiasAfast, 30);

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;
  END;

  FUNCTION FListaMotivosAfastTempExigidos(pCdRubricaAgrupamento IN INTEGER,
                                          pDataVigencia         IN DATE)
    RETURN sys.odcinumberlist IS
    vListaMotivos     sys.odcinumberlist := sys.odcinumberlist();
    pAnoMesReferencia INTEGER;
  BEGIN
 
    pAnoMesReferencia := extract(year from pDataVigencia) * 100 +
                         extract(month from pDataVigencia);
    select cdmotivoafasttemporario
      bulk collect
      into vListaMotivos
      from epagrubagrupmotafasttempex
     where cdhistrubricaagrupamento in
           (select hragr.cdhistrubricaagrupamento
              from epaghistrubricaagrupamento hragr
             where hragr.cdrubricaagrupamento = pCdRubricaAgrupamento
               and (hragr.nuanoiniciovigencia * 100 +
                   hragr.numesiniciovigencia) <= pAnoMesReferencia
               and ((hragr.nuanofimvigencia * 100 + hragr.numesfimvigencia) >=
                   pAnoMesReferencia or hragr.nuanofimvigencia is null));
    RETURN vListaMotivos;
  END;

  FUNCTION FObterProporcaoDiasAReceberMes(pQualquerDiaDoMes IN DATE,
                                          pDiasAReceber     IN OUT INTEGER)
    RETURN NUMBER IS
    vNuDiasMes INTEGER;
    vMes       INTEGER;
    vProporcao NUMBER;
  BEGIN
 
    vNuDiasMes := FQuantidadeDiasMes(pQualquerDiaDoMes);
    vMes       := EXTRACT(MONTH FROM pQualquerDiaDoMes);

    IF vMes = 2 THEN
      IF vNuDiasMes = pDiasAReceber THEN
        pDiasAReceber := 30;
      END IF;
      vNuDiasMes := 30;
    END IF;

    IF vNuDiasMes > 30 THEN
      vNuDiasMes := 30;
    END IF;

    IF pDiasAReceber > 30 THEN
      pDiasAReceber := 30;
    END IF;

    vProporcao := pDiasAReceber / vNuDiasMes;
    RETURN vProporcao;
  END;

  FUNCTION FQuantidadeDiasMes(pQualquerDiaDoMes IN DATE) RETURN INTEGER IS
    vPrimeiroDiaMes DATE;
    vUltimoDiaMes   DATE;
  BEGIN
 
    vUltimoDiaMes   := LAST_DAY(pQualquerDiaDoMes);
    vPrimeiroDiaMes := LAST_DAY(add_months(pQualquerDiaDoMes, -1)) + 1;

    RETURN vUltimoDiaMes - vPrimeiroDiaMes + 1;
  END;

  FUNCTION FObterFolhasPagamentoCapa(pCdVinculo           IN INTEGER,
                                     pNuAno               IN INTEGER,
                                     pNuMes               IN INTEGER,
                                     pflCalculoDefinitivo IN CHAR)
    RETURN sys.odcinumberlist IS
    vListaFolhasPagamento sys.odcinumberlist := sys.odcinumberlist();
  BEGIN
 
    select fpg.cdfolhapagamento
      bulk collect
      into vListaFolhasPagamento
      from epagfolhapagamento fpg
     inner join epagcapahistrubricavinculo cap
        on fpg.cdfolhapagamento = cap.cdfolhapagamento
     where fpg.nuanoreferencia = pNuAno
       and fpg.numesreferencia = pNuMes
       and fpg.flcalculodefinitivo = pflCalculoDefinitivo
       and cap.cdvinculo = pcdvinculo;

    RETURN vListaFolhasPagamento;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION FObterOrgaoExercicioCCO(pCdVinculo           IN INTEGER,
                                   pDataReferencia      IN DATE) RETURN INTEGER IS

    vCdOrgaoExercicioCCO INTEGER;
  BEGIN
 
    select cdorgaoexercicio
      into vCdOrgaoExercicioCCO
      from ecadhistcargocom
     where cdvinculo = pCdVinculo
       and flanulado = 'N'
       and (dtfim is null or
           (pDataReferencia >= dtinicio and pDataReferencia <= dtfim));

    RETURN vCdOrgaoExercicioCCO;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;
  END;

  FUNCTION FRubricaPresenteNoContracheque(pCdVinculo            IN INTEGER,
                                          pCdRubricaAgrupamento IN INTEGER,
                                          pCdFolhaPagamento     IN INTEGER) RETURN BOOLEAN IS
    i integer := 0;
  BEGIN
 
    select count(rv.cdrubricaagrupamento)
      into i
      from epaghistoricorubricavinculo rv
     where rv.cdvinculo = pCdVinculo
       and rv.cdrubricaagrupamento = pCdRubricaAgrupamento
       and rv.cdfolhapagamento = pCdFolhaPagamento;

     RETURN i>0;

  EXCEPTION
     WHEN OTHERS THEN
       RETURN FALSE;
  END;
  
  FUNCTION FObterInfoRubrica(pCdRubricaAgrupamento IN EPAGRUBRICAAGRUPAMENTO.CDRUBRICAAGRUPAMENTO%TYPE) RETURN PKGPAG_TIPO.rRubrica IS
    vRubrica PKGPAG_TIPO.rRubrica;
  BEGIN
    vRubrica.cdRubricaAgrupamento := pCdRubricaAgrupamento;
  
    SELECT RAGR.CDRUBRICAAGRUPAMENTO,
           RAGR.CDAGRUPAMENTO,
           RUB.NURUBRICA,
           RUB.CDTIPORUBRICA
      INTO vRubrica.CdRubricaAgrupamento,
           vRubrica.CdAgrupamento,
           vRubrica.NuRubrica,
           vRubrica.CdTipoRubrica
      FROM EPAGRUBRICAAGRUPAMENTO RAGR
     INNER JOIN EPAGRUBRICA RUB
        ON RAGR.CDRUBRICA = RUB.CDRUBRICA
     WHERE RAGR.CDRUBRICAAGRUPAMENTO = pCdRubricaAgrupamento;
  
    RETURN vRubrica;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN vRubrica;
      
    WHEN TOO_MANY_ROWS THEN
      RETURN vRubrica;  
    
    WHEN OTHERS THEN
      RETURN vRubrica;         
  END;  
  
  FUNCTION FObterQtdDiasIntervaloMes(pDtInicioMes       IN DATE,
                                     pDtFimMes          IN DATE,
                                     pDtInicioIntervalo IN DATE,
                                     pDtFimIntervalo    IN DATE) RETURN INTEGER IS
    vQtdDiasIntervaloMes  INTEGER := 0;  
    vDtInicioIntervaloMes DATE;
    vDtFimIntervaloMes    DATE;                                   
  BEGIN    
    vDtInicioIntervaloMes := pDtInicioIntervalo;
    IF pDtInicioIntervalo < pDtInicioMes THEN
      vDtInicioIntervaloMes := pDtInicioMes;
    END IF;  
    
    vDtFimIntervaloMes := pDtFimIntervalo;
    IF pDtFimIntervalo > pDtFimMes THEN
      vDtFimIntervaloMes := pDtFimMes;
    END IF;
  
    vQtdDiasIntervaloMes:= (vDtFimIntervaloMes - vDtInicioIntervaloMes) + 1;
      
    RETURN vQtdDiasIntervaloMes;
  END;                                  

END pkgpag_geral;
/
