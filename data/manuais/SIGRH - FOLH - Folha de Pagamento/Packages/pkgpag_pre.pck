CREATE OR REPLACE PACKAGE PKGPAG_PRE IS

  cnTpEfetivo CONSTANT NUMBER(2) := 1;

  cnTpComissionado CONSTANT NUMBER(2) := 2;

  cnTpFuncaoChefia CONSTANT NUMBER(2) := 3;

  cnTpAposentadoria CONSTANT NUMBER(2) := 4;

  cnTpEstagio CONSTANT NUMBER(2) := 5;

  cnTpPensaoPrev CONSTANT NUMBER(2) := 6;

  cnTpPensaoNaoPrev CONSTANT NUMBER(2) := 7;

  cnTpExParlamentar CONSTANT NUMBER(2) := 8;

  cnTpAuxReclusao CONSTANT NUMBER(2) := 9;

  cnTpLancFinanc CONSTANT NUMBER(2) := 10;

  cnTpDesligados CONSTANT NUMBER(2) := 11;

  cnTpDifMes CONSTANT NUMBER(2) := 12;

  cnTpDecTer CONSTANT NUMBER(2) := 13;

  --

  cnFlCalcSim CONSTANT NUMBER(1) := 1;

  cnFlCalcNao CONSTANT NUMBER(1) := 0;

  /*----------------------------------------------------------------------------*/
  --  Procedure : PGerarTabelaFolha
  --
  -- Objetivo : Gera registros com as folhas de pagamento a considerar no calculo
  /*-----------------------------------------------------------------------------*/

  PROCEDURE PGerarTabelaFolha(pCalculo             IN PKGPAG_CAL.rCalculo,
                              pNuMesCompetencia    IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                              pNuAnoCompetencia    IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                              pCdTipoFolha         IN INTEGER,
                              pCdTipoCalculo       IN INTEGER,
                              pFlCalculoDefinitivo IN CHAR,
                              pDtPrevisaoCredito   IN DATE,
                              pNuSequencial        IN INTEGER);

  /*-------------------------------------------------------------------------*/
  --  Func?o : PInicializarRelVincFolha
  --
  -- Objetivo : Cria chave para tabela de vinculos para calculo
  /*--------------------------------------------------------------------------*/

  FUNCTION PInicializarRelVincFolha RETURN INTEGER;

  /*-------------------------------------------------------------------------/
     Objetivo : Exclui dados na tabela de vinculos para calculo
  /*--------------------------------------------------------------------------*/

  PROCEDURE PFinalizarRelVincFolha(pCdCalculo INTEGER);

  /*-------------------------------------------------------------------------/
     Objetivo : Gerar / Contar relac?es de vinculos a calcular
  /*--------------------------------------------------------------------------*/

  PROCEDURE PGerarRelVincFolha(pCalculo                  IN PKGPAG_CAL.rCalculo,
                               pNuMesCompetencia         IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                               pNuAnoCompetencia         IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                               pCdSituacaoPrevidenciaria IN INTEGER,
                               pCdRelacaoTrabalho        IN INTEGER,
                               pCdTipoFolha              IN INTEGER,
                               pCdTipoFolhaPagamento     IN INTEGER,
                               pFlCalculoDefinitivo      IN CHAR,
                               pDtCalculo                IN DATE,
                               pFlIncluiBolsista         IN CHAR,
                               pFlIncluiAposentado       IN CHAR,
                               pInSubordinadas           IN INTEGER,
                               pCdUnidadeOrganizacional  IN INTEGER,
                               pCdTipoCalculo            IN INTEGER,
                               pNuSequencial             IN INTEGER,
                               pFlVinculo                IN CHAR,
                               pCdFolhaPagamento         IN INTEGER,
                               pCdVinculo                IN INTEGER,
                               pCdOrgao                  IN INTEGER,
                               pCdPessoa                 IN INTEGER,
                               pChecagem                 IN INTEGER DEFAULT 0,
                               pCdAgrupamento            IN INTEGER DEFAULT NULL);

  PROCEDURE PChecarTodosSqls;

  FUNCTION FRetornarSqlPDI(pCdOrgao              IN INTEGER,
                           pCdTipoFolha          IN INTEGER,
                           pCdTipoFolhaPagamento IN INTEGER) RETURN VARCHAR2;

  FUNCTION FEhFolhaProdexPGE(pCdTipoFolhaPagamento IN INTEGER) RETURN BOOLEAN;                         

                           
  /*
   drop table ecalvincfolha;
   CREATE TABLE ecalvincfolha
    ( cdvincfolha  number
     ,CdCalculo  number
     ,CdCalculoPai  number
     ,cdfolhapagamento  integer  not null
     ,cdRelacaoTrabalho integer null
     ,cdorgaovinculo  integer   not null
     ,cdorgaoexercicio  number
     ,cdvinculo  integer  not null
     ,nuSeqMatricula integer not null
     ,cdpessoa  integer not null
     ,cdrelacaovinculo  number
     ,cdhistvinculo  number
     ,dtInicioRelacao date null
     ,dtFimRelacao date null
     ,cdsituacaoprevidenciaria  number
     ,cdregimetrabalho  integer
     ,cdregimeprevidenciario  integer not null
     ,dtadmissao  date  not null
     ,dtdesligamento  date
     ,dtnascimento  date
     ,dtinclusao  date not null
     ,flsexo  char(1)
     ,cdopcaoauxilioali  integer  not null
     ,flobito  number
     ,flOutroVincCalculado          CHAR(1)
     ,flOutroVincACalcular          CHAR(1)
     ,flcalcular  number)
   TABLESPACE SIGRH_DATA_MEDIUM;

  create index IDXCALVINCFOLHACALCUL on ecalvincfolha (cdcalculo, cdfolhapagamento, cdPessoa)
  tablespace SIGRH_INDX_MEDIUM;

  create index IDXCALVINCFOLHAVINC on ecalvincfolha (cdcalculo, cdvinculo)
  tablespace SIGRH_INDX_MEDIUM;

  create index IDXCALCALCULOPAI on ecalvincfolha (cdcalculoPai)
  tablespace SIGRH_INDX_MEDIUM;

   DROP TABLE ECalSituacaoPrevidenciaria;

  create table ECalSituacaoPrevidenciaria
   (cdCalculo integer not null,
    cdvinculo integer not null,
    cdSituacaoPrevidenciaria integer)
  tablespace SIGRH_DATA_MEDIUM;

  create index IDXCALSITUACAOPREVIDENCIARIA on ECalSituacaoPrevidenciaria (cdcalculo, cdvinculo)
  tablespace SIGRH_INDX_MEDIUM;

  drop table ECalCalculo;
  create table ECalCalculo
  (
    CdCalculo                     INTEGER not null,
    CdCalculoPai                  INTEGER not null,
    CdPessoaMin                   INTEGER,
    CdPessoaMax                   INTEGER,
    CdTarefa                      INTEGER,
    CdHistoricoParamCalculo       INTEGER,
    CdFolhaPagamento              INTEGER,
    CdOrgao                       INTEGER,
    FlGeral                       CHAR,
    InTipoExecucao                INTEGER,
    CDAGRUPAMENTO                 INTEGER not null,
    DTCALCULO                     DATE not null,
    NUMESCOMPETENCIA              NUMBER(2) not null,
    NUANOCOMPETENCIA              NUMBER(4) not null,
    CDTIPOCALCULO                 INTEGER not null,
    FLDEFINITIVO                  CHAR(1) not null,
    FLPAGAADIANTAMENTO13SAL       CHAR(1) not null,
    DTPREVISTACREDITO             DATE,
    FLSALVARVALORESCALCULOVIGENTE CHAR(1) not null,
    VLDIFERENCAVALOR              NUMBER(9,2),
    FlLog                         CHAR(1),
    FlTrace                       CHAR(1),
  )
   TABLESPACE SIGRH_DATA_SMALL;

  create index IDXCALCALCULO on ECalCalculo (cdCalculo)
  tablespace SIGRH_INDX_SMALL;

  create index IDXCALCALCPAI on ECalCalculo (cdCalculoPai)
  tablespace SIGRH_INDX_SMALL;

  /*---------------------------------------------------------------------------------------------
    Tabela contendo subconjunto de folhas de pagamento dos org?os no mes de calculo
   ---------------------------------------------------------------------------------------------

  drop table ECALFOLHATRIB;

  CREATE TABLE ECALFOLHATRIB
  (
    CDCALCULOPAI               NUMBER NOT NULL,
    SGTRIBUTO                  VARCHAR2(4) NOT NULL,
    TPMES                      CHAR(1) NOT NULL,
    CDFOLHAPAGAMENTO           INTEGER,
    CDFOLHAVINCSUPL            INTEGER,
    CDFOLHAORIGEM              INTEGER,
    CDFOLHASUPLAGLUT           INTEGER,
    CDORGAO                    INTEGER,
    NUANOREFERENCIA            NUMBER(4) NOT NULL,
    NUMESREFERENCIA            NUMBER(2) NOT NULL,
    CDTIPOFOLHAPAGAMENTO       INTEGER NOT NULL,
    CDTIPOCALCULO              INTEGER NOT NULL,
    DTABERTURA                 DATE NOT NULL,
    DTCALCULO                  DATE,
    DTPREVISAOCREDITO          DATE,
    DTCREDITO                  DATE,
    FLCALCULODEFINITIVO        CHAR(1) NOT NULL,
    CDAGRUPAMENTO              INTEGER,
    CDTIPOFOLHA                INTEGER NOT NULL,
    NUANOMESIMPLANTACAO        NUMBER(6),
    FLIMPLANTADO               CHAR(1)
  )
  tablespace SIGRH_DATA_SMALL;

  create index IDXCALFOLHATRIB1 on ECALFOLHATRIB (CDCALCULOPAI, SGTRIBUTO, TPMES, CDFOLHAPAGAMENTO)
  tablespace SIGRH_INDX_SMALL;

  - Tabelas Antigas a apagar

  drop table ECALFOLHAMES;
  drop table ECALFOLHAMESCAIXA;
  drop table ECALFOLHAMESANT;

  CREATE TABLE ECALFOLHAMES
  (
    CDCALCULOPAI               NUMBER NOT NULL,
    CDFOLHAPAGTO               INTEGER,
    CDFOLHAPAGAMENTONORMAL     INTEGER,
    CDFOLHAPAGAMENTOESPEC      INTEGER,
    CDFOLHAVINCSUPL            INTEGER,
    CDFOLHAORIGEM              INTEGER,
    CDFOLHASUPLAGLUT           INTEGER,
    CDORGAO                    INTEGER,
    NUANOREFERENCIA            NUMBER(4) NOT NULL,
    NUMESREFERENCIA            NUMBER(2) NOT NULL,
    CDTIPOFOLHAPAGAMENTO       INTEGER NOT NULL,
    CDTIPOCALCULO              INTEGER NOT NULL,
    DTABERTURA                 DATE NOT NULL,
    DTCALCULO                  DATE,
    DTPREVISAOCREDITO          DATE,
    DTCREDITO                  DATE,
    FLCALCULODEFINITIVO        CHAR(1) NOT NULL,
    CDAGRUPAMENTO              INTEGER,
    CDTIPOFOLHA                INTEGER NOT NULL,
    NUANOMESIMPLANTACAO        NUMBER(6),
    FLIMPLANTADO               CHAR(1)
  )
  tablespace SIGRH_DATA_SMALL;

  create index IDXCALFOLHAMES1 on ECALFOLHAMES (CDCALCULOPAI, CDFOLHAPAGTO)
  tablespace SIGRH_INDX_SMALL;

  create index IDXCALFOLHAMES2 on ECALFOLHAMES (CDCALCULOPAI, CDFOLHAPAGAMENTONORMAL)
  tablespace SIGRH_INDX_SMALL;

  create index IDXCALFOLHAMES3 on ECALFOLHAMES (CDCALCULOPAI, CDFOLHAPAGAMENTOESPEC)
  tablespace SIGRH_INDX_SMALL;

  ---------------------------------------------------------------------------------------------
   -- Tabela contendo subconjunto de folhas de pagamento dos org?os no mes anterior de calculo
  ---------------------------------------------------------------------------------------------
  CREATE TABLE ECALFOLHAMESANT
  (
    CDCALCULOPAI               NUMBER NOT NULL,
    CDFOLHAPAGTO               INTEGER,
    CDFOLHAPAGAMENTONORMAL     INTEGER,
    CDFOLHAPAGAMENTOESPEC      INTEGER,
    CDFOLHAVINCSUPL            INTEGER,
    CDFOLHAORIGEM              INTEGER,
    CDFOLHASUPLAGLUT           INTEGER,
    CDORGAO                    INTEGER,
    NUANOREFERENCIA            NUMBER(4) NOT NULL,
    NUMESREFERENCIA            NUMBER(2) NOT NULL,
    CDTIPOFOLHAPAGAMENTO       INTEGER NOT NULL,
    CDTIPOCALCULO              INTEGER NOT NULL,
    DTABERTURA                 DATE NOT NULL,
    DTCALCULO                  DATE,
    DTPREVISAOCREDITO          DATE,
    DTCREDITO                  DATE,
    FLCALCULODEFINITIVO        CHAR(1) NOT NULL,
    CDAGRUPAMENTO              INTEGER,
    CDTIPOFOLHA                INTEGER NOT NULL,
    NUANOMESIMPLANTACAO        NUMBER(6),
    FLIMPLANTADO               CHAR(1)
  )
  tablespace SIGRH_DATA_SMALL;

  create index IDXCALFOLHAMESANT1 on ECALFOLHAMESANT (CDCALCULOPAI, CDFOLHAPAGTO)
  tablespace SIGRH_INDX_SMALL;

  create index IDXCALFOLHAMESANT2 on ECALFOLHAMESANT (CDCALCULOPAI, CDFOLHAPAGAMENTONORMAL)
  tablespace SIGRH_INDX_SMALL;

  create index IDXCALFOLHAMESANT3 on ECALFOLHAMESANT (CDCALCULOPAI, CDFOLHAPAGAMENTOESPEC)
  tablespace SIGRH_INDX_SMALL;

  ---------------------------------------------------------------------------------------------
   -- Tabela contendo subconjunto de folhas de pagamento dos org?os com o credito no mesmo mes
   -- da folha que esta sendo calculada
  ---------------------------------------------------------------------------------------------

  CREATE TABLE ECALFOLHAMESCAIXA
  (
    CDCALCULOPAI               NUMBER NOT NULL,
    CDFOLHAPAGTO               INTEGER,
    CDFOLHAPAGAMENTONORMAL     INTEGER,
    CDFOLHAPAGAMENTOESPEC      INTEGER,
    CDFOLHAVINCSUPL            INTEGER,
    CDFOLHAORIGEM              INTEGER,
    CDFOLHASUPLAGLUT           INTEGER,
    CDORGAO                    INTEGER,
    NUANOREFERENCIA            NUMBER(4) NOT NULL,
    NUMESREFERENCIA            NUMBER(2) NOT NULL,
    CDTIPOFOLHAPAGAMENTO       INTEGER NOT NULL,
    CDTIPOCALCULO              INTEGER NOT NULL,
    DTABERTURA                 DATE NOT NULL,
    DTCALCULO                  DATE,
    DTPREVISAOCREDITO          DATE,
    DTCREDITO                  DATE,
    FLCALCULODEFINITIVO        CHAR(1) NOT NULL,
    CDAGRUPAMENTO              INTEGER,
    CDTIPOFOLHA                INTEGER NOT NULL,
    NUANOMESIMPLANTACAO        NUMBER(6),
    FLIMPLANTADO               CHAR(1)
  )
  tablespace SIGRH_DATA_SMALL;

  create index IDXCALFOLHAMESCAIXA1 on ECALFOLHAMESCAIXA (CDCALCULOPAI, CDFOLHAPAGTO)
  tablespace SIGRH_INDX_SMALL;

  create index IDXCALFOLHAMESCAIXA2 on ECALFOLHAMESCAIXA (CDCALCULOPAI, CDFOLHAPAGAMENTONORMAL)
  tablespace SIGRH_INDX_SMALL;

  create index IDXCALFOLHAMESCAIXA3 on ECALFOLHAMESCAIXA (CDCALCULOPAI, CDFOLHAPAGAMENTOESPEC)
  tablespace SIGRH_INDX_SMALL;

  ---------------------------------------------------------------------------------*/

END PKGPAG_PRE;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_PRE IS

  /*-------------------------------------------------------------------------*/
  --  Funcão : PInicializarRelVincFolha
  --
  -- Objetivo : Cria chave para tabela de vinculos para calculo
  /*--------------------------------------------------------------------------*/


  FUNCTION PInicializarRelVincFolha RETURN INTEGER IS

    vCdCalculo INTEGER;

  BEGIN

    select SCALCALCULO.nextval into vCdCalculo from dual;

    RETURN vCdCalculo;

  END;

  /*-------------------------------------------------------------------------*/
  --  Funcão : PFinalizarRelVincFolha
  --
  -- Objetivo : Exclui dados na tabela de vinculos para calculo
  /*--------------------------------------------------------------------------*/

  PROCEDURE PFinalizarRelVincFolha(pCdCalculo INTEGER) IS

  BEGIN

    DELETE FROM eCalVincFolha WHERE CdCalculoPai = pCdCalculo;
    DELETE FROM ECalRubricaAgrupamentoOrdem WHERE CdCalculoPai = pCdCalculo;

    DELETE FROM ECalFolhaTrib WHERE CdCalculoPai = pCdCalculo;
    DELETE FROM ECalFolhaPag  WHERE CdCalculo = pCdCalculo;

  END;

  /*-------------------------------------------------------------------------*/
  --  Funcão : PInserirRelVincFolha
  --
  -- Objetivo : Inserir dados na tabela de vinculos para calculo
  /*--------------------------------------------------------------------------*/

  PROCEDURE PInserirRelVincFolha(pInTipoExecucao IN INTEGER, pSql IN VARCHAR2, pLstPessoa IN OUT NOCOPY PKGPAG_TIPO.tLista) IS

    vSql        VARCHAR2(5000);
    vCursor     TYPES.REF_CURSOR;
    vTimeIni    INTEGER;
    vTimeTotal  INTEGER;

    TYPE rDadosSql IS RECORD (
       CdPessoa          INTEGER,
       CdHistVinculo     INTEGER,          
       CdRelacaoTrabalho INTEGER,
       DtInicioRelacao   DATE,
       DtFimRelacao      DATE);

    TYPE tDadosSql IS TABLE OF rDadosSql;       

    vTabDados            tDadosSql;
     
    PROCEDURE PExibir (vTexto IN VARCHAR2) IS
       sqlparte1 varchar2(1000);
       sqlparte2 varchar2(1000);
       sqlparte3 varchar2(1000);
       sqlparte4 varchar2(1000);       
    BEGIN
 
       sqlparte1 := substr(psql, 1, 800);
       sqlparte2 := substr(psql, 1 + 1 * 800, 800);
       sqlparte3 := substr(psql, 1 + 2 * 800, 800);
       sqlparte4 := substr(psql, 1 + 3 * 800, 800);

       dbms_output.put_line(lpad ('-',70,'-'));
       dbms_output.put_line(sqlparte1);
       dbms_output.put_line(sqlparte2);
       dbms_output.put_line(sqlparte3);
       dbms_output.put_line(sqlparte4);
            
    END;
    
  BEGIN

     IF pSql IS NULL THEN       
        RETURN;
     END IF;     

     IF pInTipoExecucao = 1 THEN -- Somente Contar
        vSql := pSql;     
        
        -- pExibir(vSql);
        
        vTimeIni := dbms_utility.get_time;
              
        OPEN  vCursor FOR vSql;  
        FETCH vCursor
         BULK COLLECT INTO vTabDados;
        CLOSE vCursor;

        vTimeTotal := dbms_utility.get_time - VTimeIni;
        
        -- DBMS_OUTPUT.PUT_LINE (( vTimeTotal / 100) || ' segundos');
 
        IF vTabDados.COUNT > 0 THEN         
           FOR rec IN vTabDados.FIRST .. vTabDados.LAST LOOP               
             plstPessoa ( vTabDados(rec).CdPessoa ) := 1;
           END LOOP;          
        END IF;
                      
     ELSE
        vSql := 'INSERT INTO ECalVincFolha'
                 || ' (CdFolhaPagamento,'
                 || '  DeOrdemExecucao,'
                 || '  CdOrgaoVinculo,'
                 || '  CdOrgaoExercicio,'
                 || '  CdVinculo,'
                 || '  CdPessoa,'
                 || '  NuSeqMatricula,'
                 || '  CdSituacaoPrevidenciaria,'
                 || '  CdRegimeTrabalho,'
                 || '  CdRegimePrevidenciario,'
                 || '  DtAdmissao,'
                 || '  DtDesligamento,'
                 || '  DtNascimento,'
                 || '  DtInclusao,'
                 || '  FlSexo,'
                 || '  CdOpcaoAuxilioAli,'
                 || '  CdVincFolha,'
                 || '  CdCalculo,'
                 || '  CdCalculoPai,'
                 || '  CdRelacaoVinculo,'
                 || '  CdHistVinculo,'                
                 || '  CdRelacaoTrabalho,'
                 || '  DtInicioRelacao,'
                 || '  DtFimRelacao'
                 || ') '
                 || pSql;

        EXECUTE IMMEDIATE vSql;
      
     END IF;
   
  end;

  /*-------------------------------------------------------------------------*/
  --  Funcão : PConsolidarRelVinFolha
  --
  -- Objetivo : Consolidar os registros de relac?es de vinculos para calculo
  /*--------------------------------------------------------------------------*/

  procedure PConsolidarRelVinFolha(pCdCalculo           IN INTEGER,
                                   pNuMesCompetencia    IN INTEGER,
                                   pNuAnoCompetencia    IN INTEGER,
                                   pDtCompetenciaIni    IN DATE,
                                   pDtCompetenciaFim    IN DATE,
                                   pFlCalculoDefinitivo IN CHAR,
                                   pCdTipoCalculo       IN INTEGER,
                                   pDtCalculo               IN DATE,
                                   pCdTipoFolhaPagamento in integer default null
                                 ) IS

     vVisaoCalculo    CHAR (1);
  BEGIN
    
    vVisaoCalculo := PKGPAG_GERAL.FVisaoCalculo(pCdTipoCalculo, pFlCalculoDefinitivo);
     
    -- Marcar casos onde existe comissionado em outro orgao

    PKGPAG_GERAL.PLogProcIni ('PRE0118','Consolidar Rel Vinc Folha');

    PKGPAG_GERAL.PLogProc('PRE011801','PRE011802','Trata Prodex');
    

    if NOT FEhFolhaProdexPGE(pCdTipoFolhaPagamento)
       and pkgpag_var.vgFolha.cdTipoFolha not in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13)
    then

    update ecalvincfolha v
       set flCalcular = cnFlCalcNao -- N?o Calcular
     where CdCalculo = pCdCalculo
      and exists (select 1 from eCadHistCargoCom HCC, ecadOrgao OCC,ecadOrgao OV
             where HCC.CdVinculo = V.CdVinculo
               AND HCC.CdOrgaoExercicio = OCC.CdOrgao
               AND v.CdOrgaoExercicio = OV.CdOrgao
               AND OV.CdAgrupamento = OCC.CdAgrupamento
               AND HCC.CdOrgaoExercicio <> v.CdOrgaoExercicio
               AND HCC.CdCargoComRemuneracao IS NULL
               AND HCC.FlAnulado = 'N'
               AND HCC.DtInicio <= pDtCalculo
               AND (HCC.DtFim >= pDtCalculo OR HCC.DtFim IS NULL));
    end if;

    PKGPAG_GERAL.PLogProc('PRE011801','PRE011802','Marcar Existe LF');
    
    -- Marcar casos onde existe lancamento financeiro ou Desligados - prioridade sobre outros

    update ecalvincfolha v
       set flCalcular = cnFlCalcSim --  Calcular
     where CdCalculo = pCdCalculo
      and exists (select 1 from ecalvincfolha vi
             where CdCalculo = pCdCalculo
               AND vi.CdVinculo = V.CdVinculo
               AND vi.cdrelacaovinculo in (cnTpLancFinanc, cnTpDesligados));

    -- Marcar casos onde existe efetivo em outro orgao oriundo de movimentac?o

    PKGPAG_GERAL.PLogProc('PRE011802','PRE011803','Efetivos de movimentacao');

    update ecalvincfolha v
       set flCalcular = 4 --cnFlCalcNao -- N?o Calcular
     where CdCalculo = pCdCalculo
      and exists (select 1 from Ecadhistcargoefetivo CEF, ecadOrgao OCC,ecadOrgao OV
             where CEF.CdVinculo = V.CdVinculo
               AND CEF.CdOrgaoExercicio = OCC.CdOrgao
               AND V.CdOrgaoExercicio = OV.CdOrgao
               AND OV.CdAgrupamento = OCC.CdAgrupamento
               AND CEF.CdOrgaoDestMovimentacao IS NULL
               AND CEF.CdrelacaoTrabalho = PKGPAG_TIPO.cnRelTrabEfetivo
               AND CEF.CdOrgaoExercicio <> V.CdOrgaoExercicio
               AND CEF.FlAnulado = 'N'
                     AND (v.DtFimRelacao < CEF.DtInicio OR v.Cdrelacaovinculo IN (cnTpLancFinanc,cnTpDesligados) )
               AND CEF.DtInicio <= pDtCalculo
               AND (CEF.DtFim >= pDtCalculo OR CEF.DtFim IS NULL));

    PKGPAG_GERAL.PLogProc('PRE011803','PRE011804','Verificar movimentacao para pag destino');
   
    IF NOT FEhFolhaProdexPGE(pCdTipoFolhaPagamento) THEN               

       -- Marcar para não calcular vinculos que estao com movimentação para pagamento no orgão destino

 update ecalvincfolha v
       set flCalcular = 4 ---- Não Calcular
     where CdCalculo = pCdCalculo
      and exists (select 1 from EMOVMOVIMENTACAO emo
                  inner join ecadhistcargoefetivo cgo
                        on emo.cdhistcargoefetivo = cgo.cdhistcargoefetivo
                  and cgo.cdvinculo = V.CdVinculo
                  and emo.dtfimmovimentacao is null
                  and emo.flanulado = 'N'
                  and emo.cdhistcargoefetivodestino is not null
                  and v.CdOrgaoExercicio <> emo.cdorgaodestino
                  and emo.cdmotivomovimentacao = 348---pagamento no destino
                  and cgo.CdOrgaoDestMovimentacao is null
                  and cgo.CdrelacaoTrabalho = PKGPAG_TIPO.cnRelTrabEfetivo
                  and emo.flpagamentoorigem = 'N'
                  and cgo.DtInicio <= pDtCalculo
                  and (cgo.DtFim >= pDtCalculo OR cgo.DtFim IS NULL));

    END IF;              

    -- Marcar que é contribuinte Individual

    PKGPAG_GERAL.PLogProc('PRE011804','PRE011805','Verificar contribuinte individual');
   
    UPDATE Ecalvincfolha Cal
       SET FlContribIndiv = 1
     WHERE CdCalculo = pCdCalculo
       AND EXISTS 
          (SELECT 1 
             FROM etrbrecolhimentoavulso T
            WHERE FlAnulado = 'N'
              AND CdObjetoRecolhimento = 1
              AND (NuAnoInicio < pNuAnoCompetencia OR (NuAnoInicio = pNuAnoCompetencia AND NuMesInicio <= pNuMesCompetencia))
              AND (NuAnoFim > pNuAnoCompetencia OR (NuAnoFim = pNuAnoCompetencia AND NuMesFim >= pNuMesCompetencia) OR NuAnoFim IS NULL)
              AND VlAliquotaUnica IS NOT NULL
              AND CdPessoa = Cal.CdPessoa
              AND (CdVinculo IS NULL OR CdVinculo = Cal.CdVinculo) 
           );
               
    UPDATE Ecalvincfolha Cal
       SET FlContribIndiv = 0
     WHERE CdCalculo = pCdCalculo
       AND FlContribIndiv IS NULL;   
/*
#PENDENTE

-- colocar estes casos também como contribuinte individual

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
        


*/







    -- Marcar para n?o calcular vinculos utilizados em mais de um agrupamento --> erro de dados

    PKGPAG_GERAL.PLogProc('PRE011805','PRE011806','Verificar erro de dados');
    
    update ecalvincfolha
       set flCalcular = cnFlCalcNao -- N?o Calcular
         where rowid in
         (
         select v.rowid
                       from ecalvincfolha v, ecadorgao oe, ecadorgao ov
                      where oe.cdorgao = v.cdorgaoexercicio
                        and ov.cdorgao = v.cdorgaovinculo
                        and v.cdorgaoexercicio <> v.cdorgaovinculo
                        and oe.cdagrupamento <> ov.cdagrupamento
               and cdCalculo = pCdCalculo
         );

    -- registrar obitos por agrupamento

    PKGPAG_GERAL.PLogProc('PRE011806','PRE011807','Buscar dados de obito');

    update ecalvincfolha ext
       set flobito = 1
     where CdCalculo = pCdCalculo
       and (cdorgaoExercicio, cdpessoa) in
                 (select O.cdorgao,RO.cdpessoa from Eafaregistroobito RO, ECadOrgao O
             WHERE RO.FlAnulado = 'N'
               and RO.cdAgrupamento = O.CdAgrupamento);

    -- registrar situacao previdenciaria onde encontrou intervalo

    PKGPAG_GERAL.PLogProc('PRE011807','PRE011808','Buscar sit Prev');

     DELETE from ECalSituacaoPrevidenciaria
         where CdCalculo = pCdCalculo;

    insert into ECalSituacaoPrevidenciaria
            select CdCalculo, CdVinculo, CdSituacaoPrevidenciaria from
                (
                SELECT CALINT.CdCalculo, CALINT.CDVINCULO,
                     ROW_NUMBER() OVER(PARTITION BY hspv.cdVINCULO ORDER BY HSPV.DtInicio) AS ORDEM,
                     hspv.CdSituacaoPrevidenciaria
                FROM ECadHistSitPrevVinculo HSPV, Ecalvincfolha CALINT
               WHERE CALINT.CdCalculo = pCdCalculo
                      AND HSPV.CdVinculo = CALINT.CdVinculo AND
                          HSPV.DtInicio <= pDtCompetenciaFim AND
                         ( HSPV.DtFim >= pDtCompetenciaIni or HSPV.DtFim is NULL)
                ) SINT
       where SINT.ordem = 1;

    UPDATE Ecalvincfolha Cal
       SET cdSituacaoPrevidenciaria = nvl((select cdSituacaoPRevidenciaria
                                            from ECalSituacaoPrevidenciaria T
                                           where T.CdCalculo = Cal.CdCalculo
                                                      and T.cdvinculo = Cal.cdvinculo),0)
     where CdCalculo = pCdCalculo;

    -- registrar situacao previdenciaria onde nao encontrou intervalo

     DELETE from ECalSituacaoPrevidenciaria
         where CdCalculo = pCdCalculo;

    insert into ECalSituacaoPrevidenciaria
             select CdCalculo, CdVinculo, CdSituacaoPrevidenciaria from
                (
                SELECT CALINT.CdCalculo, CALINT.CDVINCULO,
                     ROW_NUMBER() OVER(PARTITION BY hspv.cdVINCULO ORDER BY HSPV.DtInicio DESC) AS ORDEM,
                     hspv.CdSituacaoPrevidenciaria
                FROM ECadHistSitPrevVinculo HSPV, Ecalvincfolha CALINT
               WHERE CALINT.CdCalculo = pCdCalculo
                 AND HSPV.CdVinculo = CALINT.CdVinculo
                      AND CALINT.cdsituacaoprevidenciaria = 0
                ) SINT
       where SINT.ordem = 1;

    UPDATE Ecalvincfolha Cal
       SET cdSituacaoPrevidenciaria = nvl((select cdSituacaoPRevidenciaria
                                            from ECalSituacaoPrevidenciaria T
                                           where T.CdCalculo = Cal.CdCalculo
                                                      and T.cdvinculo = Cal.cdvinculo),0)
     where CdCalculo = pCdCalculo
       AND cdsituacaoprevidenciaria = 0;

    -- limpar tabela

     DELETE from ECalSituacaoPrevidenciaria
         where CdCalculo = pCdCalculo;

    -- identificar pessoas com mais de um vinculo calculado

    PKGPAG_GERAL.PLogProc('PRE011808','PRE011809','pessoas com mais de um vinculo');

    UPDATE Ecalvincfolha Cal
       SET Cal.FlOutroVincCalculado = 'N'
     where cdCalculo = pCdCalculo
        AND cdPessoa in
        (   select cdpessoa from
            (
              select cdpessoa, cdvinculo
                                  from Ecadvinculo v
                                 WHERE v.dtadmissao <= pDtCompetenciaFim
                  AND (v.dtdesligamento >= pDtCompetenciaIni
                   OR v.dtdesligamento IS NULL)
                                   AND v.flanulado = 'N'
                                union
                                select cdpessoa, cdvinculo
                                  from Ecalvincfolha
                                 where cdCalculo = pCdCalculo
               and cdrelacaovinculo = cnTpLancFinanc
            )
                         group by cdpessoa
             having count (*) > 1
         );

    UPDATE ECalVincFolha Cal
       SET Cal.FlOutroVincCalculado = 'S'
     where CdCalculo = pCdCalculo
       AND Cal.FlOutroVincCalculado = 'N'
       AND EXISTS
     (SELECT 1
              FROM ECadVinculo V
             INNER JOIN EPagHistoricoRubricaVinculo HRV
                ON V.CdVinculo = HRV.CdVinculo
             INNER JOIN EPagFolhaPagamento FP
                ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
             INNER JOIN EPagTipoFolhaPagamento TFP
                ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
                  WHERE FP.NuAnoReferencia = pNuAnoCompetencia AND
                        FP.NuMesReferencia = pNuMesCompetencia AND
                        ( (FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                           FP.FlCalculoDefinitivo = DECODE(vVisaoCalculo, 'S', 'S',FP.FlCalculoDefinitivo) )
                           OR (FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS)
                         )
               AND V.cdPessoa = Cal.CdPessoa);

    -- identificar pessoas com mais de um vinculo a calcular

    UPDATE ECalVincFolha Cal
       SET Cal.FlOutroVincACalcular = 'S'
     WHERE CdCalculo = pCdCalculo
         AND CdPessoa IN
                ( SELECT CdPessoa FROM
                  (
                  SELECT V.CdPessoa, V.CdVinculo FROM ECalVincFolha V
                                 WHERE V.CdCalculo = pCdCalculo
                  GROUP BY V.CdPessoa, V.CdVinculo
                  )
                         GROUP By CdPessoa
                  HAVING COUNT (*) > 1
                );

    PKGPAG_GERAL.PLogProcFim ('PRE011809');
    
    -- Futuras Otimizac?es

    /*

         PKGPAG_VAR.vgDtMinDataAfastRetro := PKGPAG_GERAL.FMenorDataAfastRetroativos(rVinculo.CdVinculo,
                                                                                     PKGPAG_VAR.vgFolha.DtInicioMes,
                                                                                     PKGPAG_VAR.vgFolha.DtFimMes);
         PKGPAG_GERAL.PArmazenaRelacoesVinculo(rVinculo.CdVinculo);
    */
    
     PKGPAG_GERAL.PLogProcFim ('PRE0118');

  end;

  PROCEDURE PGerarTabelaFolha(pCalculo             IN PKGPAG_CAL.rCalculo,
                              pNuMesCompetencia    IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                              pNuAnoCompetencia    IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                              pCdTipoFolha         IN INTEGER,
                              pCdTipoCalculo       IN INTEGER,
                              pFlCalculoDefinitivo IN CHAR,
                              pDtPrevisaoCredito   IN DATE,
                              pNuSequencial        IN INTEGER) IS

    vDtAnoMes          INTEGER;
    vCdTipoCalculoCalc INTEGER;

  BEGIN

    -- Fim Retirar

    IF pCdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoPrimeiro,
                          PKGPAG_TIPO.cnTpCalculoSegundo,
                          PKGPAG_TIPO.cnTpCalculoPrevia) THEN

      vCdTipoCalculoCalc := PKGPAG_TIPO.cnTpCalculoNormal;
    ELSE
      vCdTipoCalculoCalc := pCdTipoCalculo;
    END IF;

    vDtAnoMes := pNuAnoCompetencia*100 + pNuMesCompetencia;

    INSERT INTO ECalFolhaTrib
      SELECT pCalculo.CdCalculoPai AS CdCalculoPai,
             TRIB.SgTributo,
             PKGPAG_TIPO.cnTpMesTribAtual AS TpMes, -- M = Proprio Mes, C = Mes de Credito
             FP.CdFolhaPagamento,
             FP.CdFolhavincsupl,
             FP.CdFolhaorigem,
             FP.CdFolhasuplaglut,
             FP.CdOrgao,
             FP.NuAnoreferencia,
             FP.NuMesreferencia,
             FP.CdTipoFolhaPagamento,
             FP.CdTipoCalculo,
             FP.DtAbertura,
             FP.DtCalculo,
             FP.DtPrevisaoCredito,
             FP.DtCredito,
             FP.FlCalculoDefinitivo,
             FP.CdAgrupamento,
             TFP.CdTipoFolha,
             O.NuAnoMesImplantacao,
             CASE
               WHEN O.Nuanomesimplantacao <= FP.Nuanomesreferencia THEN
                'S'
               ELSE
                'N'
             END AS FlImplantado
        FROM EPagFolhaPagamento FP
       INNER JOIN EPagTipoFolhaPagamento TFP
          ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento
       INNER JOIN ECadOrgao O
          ON FP.CdOrgao = O.CdOrgao
       INNER JOIN EPagTipoFolhaCalculo FLC
          ON FLC.Cdtipocalculo = vCdTipoCalculoCalc
         AND FLC.CdTipoFolha = pCdTipoFolha
       INNER JOIN EPagTipoFolhaCalculo FLT
          ON FLT.Cdtipocalculo = FP.CdTipoCalculo
         AND FLT.CdTipoFolha = TFP.CdTipoFolha
       INNER JOIN EPagTribTipoFolhaCalculo TRIB
          ON TRIB.CdTipoFolhaCalculoCalc = FLC.Cdtipofolhacalculo
         AND TRIB.CdTipoFolhaCalculoTrib = FLT.Cdtipofolhacalculo
       AND (TRIB.FlDefinitivoCalc = '*' OR  TRIB.FlDefinitivoCalc = pFlCalculoDefinitivo)
       AND (TRIB.FlDefinitivoTrib = '*' OR  TRIB.FlDefinitivoTrib = FP.FlCalculoDefinitivo)
    WHERE FP.NuAnoMesReferencia = vDtAnoMes;

    INSERT INTO ECalFolhaTrib
      SELECT pCalculo.CdCalculoPai AS CdCalculoPai,
             TRIB.SgTributo,
             PKGPAG_TIPO.cnTpMesTribCaixa AS TpMes, -- M = Proprio Mes, C = Mes de Credito
             FP.CdFolhaPagamento,
             FP.CdFolhavincsupl,
             FP.CdFolhaorigem,
             FP.CdFolhasuplaglut,
             FP.CdOrgao,
             FP.NuAnoreferencia,
             FP.NuMesreferencia,
             FP.CdTipoFolhaPagamento,
             FP.CdTipoCalculo,
             FP.DtAbertura,
             FP.DtCalculo,
             FP.DtPrevisaoCredito,
             FP.DtCredito,
             FP.FlCalculoDefinitivo,
             FP.CdAgrupamento,
             TFP.CdTipoFolha,
             O.NuAnoMesImplantacao,
             CASE
               WHEN O.Nuanomesimplantacao <= FP.Nuanomesreferencia THEN
                'S'
               ELSE
                'N'
             END AS FlImplantado
        FROM EPagFolhaPagamento FP
       INNER JOIN EPagTipoFolhaPagamento TFP
          ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento
       INNER JOIN ECadOrgao O
          ON FP.CdOrgao = O.CdOrgao
       INNER JOIN EPagTipoFolhaCalculo FLC
          ON FLC.Cdtipocalculo = vCdTipoCalculoCalc
         AND FLC.CdTipoFolha = pCdTipoFolha
       INNER JOIN EPagTipoFolhaCalculo FLT
          ON FLT.Cdtipocalculo = FP.CdTipoCalculo
         AND FLT.CdTipoFolha = TFP.CdTipoFolha
       INNER JOIN EPagTribTipoFolhaCalculo TRIB
          ON TRIB.CdTipoFolhaCalculoCalc = FLC.Cdtipofolhacalculo
         AND TRIB.CdTipoFolhaCalculoTrib = FLT.Cdtipofolhacalculo
       AND (TRIB.FlDefinitivoCalc = '*' OR  TRIB.FlDefinitivoCalc = pFlCalculoDefinitivo)
       AND (TRIB.FlDefinitivoTrib = '*' OR  TRIB.FlDefinitivoTrib = FP.FlCalculoDefinitivo)
    WHERE TO_CHAR(NVL(FP.DtPrevisaoCredito,TO_DATE(FP.NuAnoMesReferencia,'YYYYMM')),'YYYYMM') = TO_CHAR(pDtPrevisaoCredito,'YYYYMM')
      -- mesmo sendo regime de caixa, considerar apenas as folhas da referencia que está sendo calculada
      AND FP.NuAnoMesReferencia = vDtAnoMes;
    
  END;

  /*-------------------------------------------------------------------------*/
  --  Funcão : FChecarSintaxe
  --
  -- Objetivo : Checar Sintaxe de SQL em texto
  /*--------------------------------------------------------------------------*/

  PROCEDURE PChecarSintaxe(pSQL IN VARCHAR2) IS

    vCursor  INTEGER;
    vSqlErro VARCHAR2(500);

  BEGIN

    IF pSql IS NULL THEN
      RETURN;
    END IF;

    vSqlErro := NULL;
    BEGIN

      vCursor := dbms_sql.open_cursor();
      dbms_sql.parse(vCursor, pSQL, dbms_sql.native);
      dbms_sql.close_cursor(vCursor);

    EXCEPTION
      WHEN OTHERS THEN
        vSqlErro := SQLERRM;
        dbms_sql.close_cursor(vCursor);
    END;

    /*IF vSqlErro is NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('+------------------------------------------------------------------------------+');
      DBMS_OUTPUT.PUT_LINE('Erro:' || vSqlErro);
      DBMS_OUTPUT.PUT_LINE('SQL:');
      DBMS_OUTPUT.PUT_LINE(pSql);
    END IF; --*/

  END;

  PROCEDURE PChecarTodosSqls IS

    vCalculo PKGPAG_CAL.rCalculo;

  BEGIN

    vCalculo.CdTarefa                := 1;
    vCalculo.CdHistoricoParamCalculo := 2;
    vCalculo.CdCalculo               := 3;
    vCalculo.InTipoExecucao          := 1; -- Contar

   FOR rec IN (
                     select flGeral,
                       02 as NuMesCompetencia,
                       2025 as NuAnoCompetencia,
                       to_date('20/02/2025', 'DD/MM/YYYY') as DtCalculo,
                       1 as NuSequencial,
                       CdTipoCalculo,
                       flVinculo,
                       CdUnidadeOrganizacional,
                       flCalculoDefinitivo,
                       TF.CdTipoFolhaPagamento,
                       CdSituacaoPrevidenciaria,
                       CdTipoFolha,
                       CdRelacaoTrabalho,
                       FlIncluiBolsista,
                       FlIncluiAposentado,
                       InSubordinadas,
                       CdOrgao,
                       CdPessoa,
                       CdVinculo
                  from

                     (select 'S' as flGeral , 'N' flVinculo from dual union all
                      select 'N' as flGeral , 'N' flVinculo from dual union all
                      select 'N' as flGeral , 'S' flVinculo from dual)

                   INNER JOIN
                     (select 'S' as flIncluiBolsista from dual union all
                      select 'N'                        from dual)
                    ON 1 = 1

                   INNER JOIN
                     (select 'S' as flIncluiAposentado from dual union all
                      select 'N'                        from dual)
                    ON 1 = 1

                   INNER JOIN
                     (select 1 as CdUnidadeOrganizacional, 1 InSubordinadas  from dual union all
                      select 1 as CdUnidadeOrganizacional, 2 InSubordinadas  from dual union all
                      select null,null                        from dual)
                    ON 1 = 1

                   INNER JOIN
                     (select 1 as CdSituacaoPrevidenciaria from dual union all
                      select null                        from dual)
                    ON 1 = 1

                   INNER JOIN
                     (select 5 as CdRelacaoTrabalho from dual union all
                      select null                        from dual)
                    ON 1 = 1

                   INNER JOIN
                        (select distinct cdtipofolhapagamento,cdtipocalculo ,FlCalculoDefinitivo
                              from Epagfolhapagamento
                             where CdTipoCalculo not in (10, 11, 2, 7, 8, 9)
                                 and cdagrupamento in ( 1,7)
                                 ) FP
                    on 1 = 1
                 INNER JOIN EPagTipoFolhaPagamento TF
                    ON TF.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
                    
                 inner join (SELECT NULL as CdOrgao, NULL as CdPessoa, 1 as CdVinculo FROM DUAL UNION ALL
                             SELECT 1 as CdOrgao, 1 as CdPessoa, NULL as CdVinculo FROM DUAL UNION ALL
                             SELECT NULL as CdOrgao, NULL as CdPessoa, NULL as CdVinculo FROM DUAL)
                    ON 1=1

                -- WHERE rownum <=  500

                ) LOOP

      PKGPAG_PRE.PGerarRelVincFolha(pCalculo                  => vCalculo,
                                    pNuMesCompetencia         => rec.NuMesCompetencia,
                                    pNuAnoCompetencia         => rec.NuAnoCompetencia,
                                    pCdSituacaoPrevidenciaria => rec.CdSituacaoPrevidenciaria,
                                    pCdRelacaoTrabalho        => rec.CdRelacaoTrabalho,
                                    pCdTipoFolha              => rec.CdTipoFolha,
                                    pCdTipoFolhaPagamento     => rec.CdTipoFolhaPagamento,
                                    pFlCalculoDefinitivo      => rec.Flcalculodefinitivo,
                                    pDtCalculo                => rec.DtCalculo,
                                    pFlIncluiBolsista         => rec.FlIncluiBolsista,
                                    pFlIncluiAposentado       => rec.FlIncluiAposentado,
                                    pInSubordinadas           => rec.InSubordinadas,
                                    pCdUnidadeOrganizacional  => rec.CdUnidadeOrganizacional,
                                    pCdTipoCalculo            => rec.CdTipoCalculo,
                                    pNuSequencial             => rec.NuSequencial,
                                    pFlVinculo                => rec.FlVinculo,
                                    pCdFolhaPagamento         => NULL,
                                    pCdVinculo                => rec.cdVinculo,
                                    pCdOrgao                  => rec.cdOrgao,
                                    pCdPessoa                 => rec.cdPessoa,
                                    pChecagem                 => 1);
    end loop;

  END;

  FUNCTION FFORMAT_LAST_HOUR(pData IN DATE) RETURN STRING IS

  BEGIN

    RETURN 'TO_DATE (''' || TO_CHAR(pData, 'YYYYMMDD') || '235959'',''YYYYMMDDHH24MISS'')';

  END;

  FUNCTION FFORMAT_DATE(pData IN DATE) RETURN STRING IS

  BEGIN

    RETURN 'TO_DATE (''' || TO_CHAR(pData, 'YYYYMMDD') || ''',''YYYYMMDD'')';

  END;


  PROCEDURE PAtualizarContadoresOrgao (pCalculo IN PKGPAG_CAL.rCalculo, pCdOrgao IN INTEGER, pQtdePessoa IN INTEGER) IS

  BEGIN

     PKGPAG_TAR.PAtualizaParametroConsulta(pCalculo            => pCalculo,
                                           pCdOrgao            => pCdOrgao,
                                           pQtPessoasACalcular => pQtdePessoa);

  END;

  /*-------------------------------------------------------------------------*/
  --  Funcão : PGerarRelVincFolha
  --
  -- Objetivo : Gerar / Contar relac?es de vinculos a calcular
  /*--------------------------------------------------------------------------*/

  PROCEDURE PGerarRelVincFolha(pCalculo                  IN PKGPAG_CAL.rCalculo,
                               pNuMesCompetencia         IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                               pNuAnoCompetencia         IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                               pCdSituacaoPrevidenciaria IN INTEGER,
                               pCdRelacaoTrabalho        IN INTEGER,
                               pCdTipoFolha              IN INTEGER,
                               pCdTipoFolhaPagamento     IN INTEGER,
                               pFlCalculoDefinitivo      IN CHAR,
                               pDtCalculo                IN DATE,
                               pFlIncluiBolsista         IN CHAR,
                               pFlIncluiAposentado       IN CHAR,
                               pInSubordinadas           IN INTEGER,
                               pCdUnidadeOrganizacional  IN INTEGER,
                               pCdTipoCalculo            IN INTEGER,
                               pNuSequencial             IN INTEGER,
                               pFlVinculo                IN CHAR,
                               pCdFolhaPagamento         IN INTEGER,
                               pCdVinculo                IN INTEGER,
                               pCdOrgao                  IN INTEGER,
                               pCdPessoa                 IN INTEGER,
                               pChecagem                 IN INTEGER DEFAULT 0,
                               pCdAgrupamento            IN INTEGER DEFAULT NULL) IS

    vDtCalculoAnt     EPagHistoricoParamCalculo.DtCalculo%TYPE;
    vTratar           VARCHAR2(30);
    vAux              VARCHAR2(9999);
    vDtCompetenciaIni DATE;
    vDtCompetenciaFim DATE;
    vDtUltDiaAno      DATE;
    vCdTipoFolhaEquiv INTEGER;
    vCdTipoFolhaPagEquiv epagtipofolhapagamento.cdtipofolhapagamento%type;
    vSqlFiltroOrgao   varchar2(50);

    vlstPessoa        PKGPAG_TIPO.tLista;   

    vSql13Salario        VARCHAR2(9999);
    vSqlEfetivo          VARCHAR2(9999);
    vSqlComissionado     VARCHAR2(9999);
    vSqlComissionadoPuro VARCHAR2(9999);
    vSqlEstagio          VARCHAR2(9999);
    vSqlFuncaoChefia     VARCHAR2(9999);
    vSqlPensaoPrev       VARCHAR2(9999);
    vSqlPensaoNaoPrev    VARCHAR2(9999);
    vSqlAuxReclusao      VARCHAR2(9999);
    vSqlExParlamentar    VARCHAR2(9999);
    vSqlAposentadoria    VARCHAR2(9999);
    vSqlLancFinanc       VARCHAR2(9999);
    vSqlDesligados       VARCHAR2(9999);
    vSqlDifAPagar        VARCHAR2(9999);

    vTrecho              VARCHAR2(9999);
    
    cSelPesVinc VARCHAR2(1000);

    vFlCalculando13               BOOLEAN;
    vFlCalculandoEstagio          BOOLEAN;
    vFlCalculandoDifMes           BOOLEAN;
    vFlCalculandoComissionadoPuro BOOLEAN;
    vFlCalculandoServAfastados    BOOLEAN;
    vFlCalculandoConvenio         BOOLEAN;
    vCdFolha13Ant integer;

   TYPE rTabFolPagamento IS RECORD
      ( CdFolhaPagamento     INTEGER,
        CdTipoFolhaPagamento INTEGER,
        CdOrgao              INTEGER,
        DeOrdemExecucao      VARCHAR2(5)
      ); 

    TYPE tTabFolPagamento IS TABLE OF rTabFolPagamento;

    vFol tTabFolPagamento;

    PROCEDURE PTrocaTudo(PTratar IN VARCHAR2, PValor IN VARCHAR2) IS

    BEGIN

      vSql13Salario        := replace(vSql13Salario, PTratar, PValor);
      vSqlEfetivo          := replace(vSqlEfetivo, PTratar, PValor);
      vSqlComissionado     := replace(vSqlComissionado, PTratar, PValor);
      vSqlComissionadoPuro := replace(vSqlComissionadoPuro, PTratar, PValor);
      vSqlEstagio          := replace(vSqlEstagio, PTratar, PValor);
      vSqlFuncaoChefia     := replace(vSqlFuncaoChefia, PTratar, PValor);
      vSqlPensaoPrev       := replace(vSqlPensaoPrev, PTratar, PValor);
      vSqlPensaoNaoPrev    := replace(vSqlPensaoNaoPrev, PTratar, PValor);
      vSqlAuxReclusao      := replace(vSqlAuxReclusao, PTratar, PValor);
      vSqlExParlamentar    := replace(vSqlExParlamentar, PTratar, PValor);
      vSqlAposentadoria    := replace(vSqlAposentadoria, PTratar, PValor);
      vSqlLancFinanc       := replace(vSqlLancFinanc, PTratar, PValor);
      vSqlDesligados       := replace(vSqlDesligados, PTratar, PValor);
      vSqlDifAPagar        := replace(vSqlDifAPagar, PTratar, PValor);

    END;

  BEGIN
     
    PKGPAG_GERAL.PLogProcIni ('PRE01','PGerarRelVincFolha');

    vDtCompetenciaIni := to_date(pNuAnoCompetencia * 100 + pNuMesCompetencia, 'YYYYMM');

    vDtCompetenciaFim := LAST_DAY(vDtCompetenciaIni);

    vDtUltDiaAno := to_date(pNuAnoCompetencia * 10000 + 1231, 'YYYYMMDD');

    -- Monta Flags por tipo folha e tipo calculo

    vFlCalculando13               := FALSE;
    vFlCalculandoEstagio          := FALSE;
    vFlCalculandoDifMes           := FALSE;
    vFlCalculandoComissionadoPuro := FALSE;
    vFlCalculandoServAfastados    := FALSE;
    vFlCalculandoConvenio         := FALSE;
    
     IF pCdTipoFolha IN ( PKGPAG_TIPO.cnTpFolha13,
                          PKGPAG_TIPO.cnTpFolhaAdiant13,
                          PKGPAG_TIPO.cnTpFolhaResidente13,
                          PKGPAG_TIPO.cnTpFolhaFunebre13,
                          pkgpag_tipo.cnTpFolhaCtisp13,
                          pkgpag_tipo.cnTpFolhaAdiant13Ctisp,
                          pkgpag_tipo.cnTpFolhaProdex13,
                          pkgpag_tipo.cnTpFolhaHonorarios13,
                          pkgpag_tipo.cnTpFolhaHonorarProcuradores13) THEN

        vFlCalculando13 := TRUE;

     END IF;

     IF pCdTipoFolha in ( PKGPAG_TIPO.cnTpFolhaBolsista,
                          PKGPAG_TIPO.cnTpFolhaResidente,
                          PKGPAG_TIPO.cnTpFolhaPesquisador,
                          PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                          pkgpag_tipo.cntpfolharescisaopesquisador) THEN

      vFlCalculandoEstagio := TRUE;

    END IF;

    IF pCdTipoFolha in (PKGPAG_TIPO.cnTpFolhaComissionadoPuro) THEN

      vFlCalculandoComissionadoPuro := TRUE;

    END IF;

    IF pCdTipoCalculo in (PKGPAG_TIPO.cnTpCalculoDifMes) THEN

      vFlCalculandoDifMes := TRUE;

    END IF;

    IF pCdTipoCalculo in (PKGPAG_TIPO.cnTpFolhaServAfast) THEN

      vFlCalculandoServAfastados := TRUE;

    END IF;
    
    IF pCdTipoFolha = PKGPAG_TIPO.cnTpFolhaConvenio THEN
      
      vFlCalculandoConvenio := TRUE;
      
    END IF;   

    --  Monta Vetor de Folhas a Calcular
    vFol := tTabFolPagamento();

    vFol.DELETE;

    IF pCalculo.flGeral = 'I' THEN
      FOR rec IN (SELECT fp.CdFolhaPagamento,
                         fp.CdTipoFolhaPagamento,
                         fp.CdOrgao,
                         fp.DeOrdemExecucao
                    FROM EPagFolhaPagamento fp
                   WHERE fp.cdfolhapagamento = pCdFolhaPagamento) LOOP
        vFol.EXTEND;
        vFol(vFol.LAST) := rec;
      END LOOP;
    ELSE
      FOR rec IN (SELECT fp.CdFolhaPagamento,
                         fp.CdTipoFolhaPagamento,
                         fp.CdOrgao,
                         fp.DeOrdemExecucao
                    FROM EPagHistoricoParamCalculoOrgao po
                   INNER JOIN epagfolhapagamento fp
                      ON po.cdorgao = fp.cdorgao
                     AND fp.nuanoreferencia = to_number(to_char(vDtCompetenciaIni, 'YYYY'))
                     AND fp.numesreferencia = to_number(to_char(vDtCompetenciaIni, 'MM'))
                     AND fp.cdtipofolhapagamento = pCdTipoFolhaPagamento
                     AND fp.cdtipocalculo = pCdTipoCalculo
                     AND fp.nusequencialfolha = pNuSequencial
                   WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
                   order by fp.DeOrdemExecucao) LOOP
        vFol.EXTEND;
        vFol(vFol.LAST) := rec;
      END LOOP;
    END IF;

    IF vFol.COUNT = 0 THEN
      RETURN;
    END IF;

    -- Identifica o tipo de folha equivalente a folha de 13o que sera calculada

    vCdTipoFolhaEquiv := NULL;
    vCdTipoFolhaPagEquiv := null;
    IF vFlCalculando13 THEN
      IF pCdTipoFolha = PKGPAG_TIPO.cnTpFolhaResidente13 THEN
        vCdTipoFolhaEquiv := PKGPAG_TIPO.cnTpFolhaResidente;
      ELSIF pCdTipoFolha in (pkgpag_tipo.cnTpFolhaCtisp13, pkgpag_tipo.cnTpFolhaAdiant13Ctisp) then
        vCdTipoFolhaEquiv := pkgpag_tipo.cnTpFolhaCtisp;
      ELSIF pCdTipoFolha = pkgpag_tipo.cnTpFolhaProdex13 THEN
        vCdTipoFolhaPagEquiv := 1526;
      ELSIF pCdTipoFolha = pkgpag_tipo.cnTpFolhaHonorarios13 THEN
        vCdTipoFolhaPagEquiv := 1505;
      ELSIF pCdTipoFolha = pkgpag_tipo.cnTpFolhaHonorarProcuradores13 THEN
        vCdTipoFolhaPagEquiv := 1525;
      ELSE
        vCdTipoFolhaEquiv := PKGPAG_TIPO.cnTpFolhaNormal;
      END IF;
    END IF;

    vSqlFiltroOrgao := '= [CDORGAO]';

    -- Parametros Unitarios (n?o possuem outros parametros) s?o delimitadas por [..]
    -- Blocos de Parametros (que podem possuir outros parametros) s?o delimitados por #..#

    ------------------------------------------------------
    -- Monta Constantes
    ------------------------------------------------------

    -- Campos de Select constantes

    IF pCalculo.InTipoExecucao = 1 THEN -- Apenas contar

       cSelPesVinc :=
                'SELECT '              
             || ' V.CdPessoa,';
    ELSE

       cSelPesVinc :=
                'SELECT '
             || ' [CDFOLHAPAGAMENTO], '
             || ' ''[DEORDEMEXECUCAO]'', '
             || ' V.cdOrgao as cdOrgaoVinculo,'
             || ' [COLCDORGAO] as cdOrgaoExercicio,'
             || ' V.CdVinculo,'
             || ' V.CdPessoa,'
             || ' V.NuSeqMatricula,'
             || ' 0 AS CdSituacaoPrevidenciaria,'
             || ' V.CdRegimeTrabalho,'
             || ' V.CdRegimePrevidenciario,'
             || ' V.DtAdmissao,'
             || ' V.DtDesligamento,'
             || ' P.DtNascimento,'
             || ' V.DtInclusao,'
             || ' P.FlSexo,'
             || ' V.CdOpcaoAuxilioAli,'
             || ' SCalVincFolha.nextval,'
             || ' [CDCALCULO],'
             || ' null,'
             || ' [CDTIPORELACAO],';

    END IF;
    
    FOR fp IN vFol.FIRST .. vFol.LAST LOOP

      -- Inicializa

      vSql13Salario        := NULL;
      vSqlEfetivo          := NULL;
      vSqlComissionado     := NULL;
      vSqlComissionadoPuro := NULL;
      vSqlEstagio          := NULL;
      vSqlFuncaoChefia     := NULL;
      vSqlPensaoPrev       := NULL;
      vSqlPensaoNaoPrev    := NULL;
      vSqlAuxReclusao      := NULL;
      vSqlExParlamentar    := NULL;
      vSqlAposentadoria    := NULL;
      vSqlLancFinanc       := NULL;
      vSqlDesligados       := NULL;
      vSqlDifAPagar        := NULL;

      ------------------------------------------------------
      -- Monta os SQLs dos vinculos e relac?es de vinculo --
      ------------------------------------------------------

        /**************
      -- Folha Ctisp
      **************/
      IF  pCdRelacaoTrabalho IS NULL AND pCdTipoFolha in (PKGPAG_TIPO.cnTpFolhaCtisp, pkgpag_tipo.cnTpFolhaCtisp13, pkgpag_tipo.cnTpFolhaAdiant13Ctisp) THEN

        vSqlEfetivo := cSelPesVinc ||
                       ' cef.cdhistcargoefetivo as cdHistVinculo,' ||
                       ' cef.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                       ' cef.DtInicio as DtInicioRelacao,' ||
                       ' cef.DtFim as DtFimRelacao' ||
                       ' FROM ecadvinculo v' ||
                       ' INNER JOIN ecadorgao org ' ||
                       ' on org.cdorgao = v.cdorgao ' ||
                       ' INNER JOIN ecadPessoa p' ||
                       ' ON v.cdPessoa = p.cdPessoa' ||
                       ' INNER JOIN ( ' ||
                       ' select distinct conv.cdvinculo ' ||
                       ' from epvdconvocacaoaposentado conv ' ||
                       ' where conv.flanulado = ''N'' ' ||
                       ' and conv.flgerarpagamento = ''S'' ' ||
                       ' and conv.dtinicioconvocacao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                       ' and ( conv.dtfimconvocacao >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                       ' or conv.dtfimconvocacao is null) ' ||
                       ' ) cv ' ||
                       ' ON cv.cdvinculo = v.cdvinculo ' ||

                       ' #VINCULOS#' ||
                       ' INNER JOIN ecadhistcargoefetivo cef' ||
                       ' ON v.cdvinculo = cef.cdvinculo' ||
                       ' AND cef.flanulado = ''N''' ||
                       ' AND cef.cdrelacaotrabalho <> 10' ||
                       ' AND [COLCDORGAO] '|| vSqlFiltroOrgao || ' #UNIDORG#' ||
                       ' #RELTRAB#' ||
                       ' WHERE v.flanulado = ''N''' ||
                       ' #CONVENIO#' ||
                       ' #SITPREV#';


      elsif  pCdTipoFolha  = PKGPAG_TIPO.cnTpFolhaServAfast THEN

        vSqlEfetivo := cSelPesVinc ||
                       ' cef.cdhistcargoefetivo as cdHistVinculo,' ||
                       ' cef.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                       ' cef.DtInicio as DtInicioRelacao,' ||
                       ' cef.DtFim as DtFimRelacao' ||
                       ' FROM ecadvinculo v' ||
                       ' INNER JOIN ecadorgao org ' ||
                       ' on org.cdorgao = v.cdorgao ' ||
                       ' INNER JOIN ecadPessoa p' ||
                       ' ON v.cdPessoa = p.cdPessoa' ||
                       ' #VINCULOS#' ||
                       ' INNER JOIN ecadhistcargoefetivo cef' ||
                       ' ON v.cdvinculo = cef.cdvinculo' ||
                       ' AND cef.flanulado = ''N''' ||
                       ' AND cef.cdrelacaotrabalho <> 10' ||
                       ' AND [COLCDORGAO] '|| vSqlFiltroOrgao || ' #UNIDORG#' ||

                       ' INNER JOIN EAfaAfastamentoVinculo AV' ||
                       ' ON V.CdVinculo = AV.cdVinculo ' ||
                       ' INNER JOIN eafahistmotivoafasttemp AT' ||
                       ' ON AT.cdmotivoafasttemporario = AV.cdmotivoafasttemporario ' ||
                       ' AND AT.flremunerado =''N''' || -- AFAST TEMP
                       ' AND AT.dtiniciovigencia <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                       ' AND (AT.dtfimvigencia >= ' || FFORMAT_DATE(vDtCompetenciaIni) || ' OR AT.dtfimvigencia is null) ' ||

                       ' WHERE ' ||
                       ' CEF.DTINICIO <= '  || FFORMAT_DATE(vDtCompetenciaFim) || --CARGO EFETIVO
                       ' AND (CEF.DTFIM >=  ' || FFORMAT_DATE(vDtCompetenciaIni) || ' OR  CEF.DTFIM is null) '||

                       ' AND (V.DtDesligamento is null or V.DtDesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni)  || ') ' ||--VINCULO
                       ' AND V.flanulado = ''N''' ||
                       ' #CONVENIO#' ||
                       ' AND AV.FlAnulado = ''N''' ||

                       ' AND AV.DtInicio <=  ' || FFORMAT_DATE(vDtCompetenciaFim) || -- AFAST VINC
                       ' AND (AV.DtFim >= ' || FFORMAT_DATE(vDtCompetenciaIni) || ' OR AV.DtFim IS NULL)';

      else

      /**************
      -- Decimo Terceiro
      **************/

      IF vFlCalculando13 THEN

         if pCdTipoFolha in (pkgpag_tipo.cnTpFolhaCtisp13, pkgpag_tipo.cnTpFolhaAdiant13Ctisp)
           then

            vSql13Salario := vSqlEfetivo;

         else

            if pCdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl then

              vSql13Salario  := cSelPesVinc ||
                             ' null as cdHistVinculo,' ||
                             ' null as CdRelacaoTrabalho,' ||
                             ' null as DtInicioRelacao,' ||
                             ' null as DtFimRelacao' ||
                             ' FROM (' ||
                             '    WITH tabFolha as (' ||
                             '            select poi.cdFolhaPagamento,poi.cdOrgao,fpi.cdFolhaOrigem as CdFolhaPagamentoN,fpi.cdFolhaVincSupl as CdFolhaPagamentoRec ' ||
                             '            FROM epagfolhapagamento poi' ||
                             '             INNER JOIN epagfolhapagamento fpi' ||
                             '                ON poi.cdorgao = fpi.cdorgao' ||
                             '               AND fpi.nuanoreferencia = ' || to_char (vDtCompetenciaIni,'YYYY') ||
                             '               AND fpi.numesreferencia = ' || to_char (vDtCompetenciaIni,'MM') ||

                             '             INNER JOIN epagTipoFolhaPagamento tfi' ||
                             '                ON fpi.Cdtipofolhapagamento = tfi.cdtipofolhapagamento';

             vSql13Salario := vSql13Salario ||'             WHERE' ||
                             '                  poi.cdFolhaPagamento = [CDFOLHAPAGAMENTO]' ||
                             '             AND (fpi.cdTipoCalculo    = ' || PKGPAG_TIPO.cnTpCalculoNormal ||
                             '                  OR fpi.cdTipoCalculo = ' || PKGPAG_TIPO.cnTpCalculoSupl ||
                             '                  )' ||
                             '      )' ||
                             '      SELECT DISTINCT tabFolha.CdFolhaPagamento, tabFolha.CdOrgao,HRV.CdVinculo' ||
                             '        FROM EPagHistoricoRubricaVinculo HRV, tabFolha ' ||
                             '       WHERE HRV.CdFolhaPagamento in (tabFolha.CdFolhaPagamentoN, tabFolha.CdFolhaPagamentoRec) ' ||
                             '      UNION ' ||
                             '      SELECT tabFolha.CdFolhaPagamento, tabFolha.CdOrgao,LC.CdVinculo' ||
                             '        FROM Epaglancamentocomplementar LC, tabFolha ' ||
                             '       WHERE LC.CdFolhaPagamento = tabFolha.CdFolhaPagamento' || --N
                             ' ) vinor' ||

                             ' INNER JOIN  ecadvinculo v' ||
                             ' ON v.CdVinculo = vinor.cdVinculo' ||
                             ' #VINCULOS#' ||
                             ' INNER JOIN ecadPessoa p' ||
                             ' ON v.cdPessoa = p.cdPessoa';


            else

             vSql13Salario  := cSelPesVinc ||
                             ' null as cdHistVinculo,' ||
                             ' null as CdRelacaoTrabalho,' ||
                             ' null as DtInicioRelacao,' ||
                             ' null as DtFimRelacao' ||
                             ' FROM (' ||
                             '    WITH tabFolha as (' ||
                             '            select poi.cdFolhaPagamento,poi.cdOrgao,fpi.cdFolhaPagamento as CdFolhaPagamentoN, nvl(fpn.CdFolhaPagamento,0) as CdFolha13Def' ||
                             '            FROM epagfolhapagamento poi' ||
                             '             INNER JOIN epagfolhapagamento fpi' ||
                             '                ON poi.cdorgao = fpi.cdorgao' ||
                             '               AND fpi.nuanoreferencia = ' || to_char (vDtCompetenciaIni,'YYYY') ||
                             '               AND fpi.numesreferencia = ' || to_char (vDtCompetenciaIni,'MM') ||
                             -- FOLHA 13 DEFINITIVA
                             '             left outer JOIN epagfolhapagamento fpn  ON poi.cdorgao = fpn.cdorgao  ' ||
                             '             AND fpn.nuanoreferencia = ' || to_char (vDtCompetenciaIni,'YYYY') ||
                             '             AND fpn.numesreferencia <> ' || to_char (vDtCompetenciaIni,'MM') ||
                             '             AND fpn.FlCalculoDefinitivo = ''S''' ||
                             '             AND fpn.cdtipofolhapagamento = poi.cdtipofolhapagamento ' ||
                             '             AND fpn.cdorgao = poi.cdorgao ' ||
                             --
                             '             INNER JOIN epagTipoFolhaPagamento tfi' ||
                             '                ON fpi.Cdtipofolhapagamento = tfi.cdtipofolhapagamento';

             if vCdTipoFolhaEquiv is not null then
               vSql13Salario := vSql13Salario ||'               AND tfi.cdtipoFolha = ' || vCdTipoFolhaEquiv;
             elsif vCdTipoFolhaPagEquiv is not null then
               vSql13Salario := vSql13Salario ||'               AND tfi.cdtipoFolhaPagamento = ' || vCdTipoFolhaPagEquiv;
             else
               null;
             end if;

             vSql13Salario := vSql13Salario ||'             WHERE' ||
                             '                  poi.cdFolhaPagamento = [CDFOLHAPAGAMENTO]' ||
                             '             AND (fpi.cdTipoCalculo    = ' || PKGPAG_TIPO.cnTpCalculoNormal ||
                             '                  OR fpi.cdTipoCalculo = ' || PKGPAG_TIPO.cnTpCalculoSupl ||
                             '                  AND fpi.FlCalculoDefinitivo = ''S'')' ||
                             '      )' ||
                             '      SELECT DISTINCT tabFolha.CdFolhaPagamento, tabFolha.CdOrgao,HRV.CdVinculo' ||
                             '        FROM EPagHistoricoRubricaVinculo HRV, tabFolha ' ||
                             '       WHERE HRV.CdFolhaPagamento in (tabFolha.CdFolhaPagamentoN, tabfolha.CdFolha13Def)' ||
                             '      UNION ' ||
                             '      SELECT tabFolha.CdFolhaPagamento, tabFolha.CdOrgao,LC.CdVinculo' ||
                             '        FROM Epaglancamentocomplementar LC, tabFolha ' ||
                             '       WHERE LC.CdFolhaPagamento = tabFolha.CdFolhaPagamento' || --N
                             ' ) vinor' ||

                             ' INNER JOIN  ecadvinculo v' ||
                             ' ON v.CdVinculo = vinor.cdVinculo' ||
                             ' #VINCULOS#' ||
                             ' INNER JOIN ecadPessoa p' ||
                             ' ON v.cdPessoa = p.cdPessoa';

          end if;

          end if;

      END IF;

      /**************
      -- Efetivo/Comissionado
      **************/

       IF NOT ( vFlCalculandoEstagio OR vFlCalculando13 OR vFlCalculandoComissionadoPuro OR vFlCalculandoConvenio OR
               (pCdTipoFolha in (PKGPAG_TIPO.cnTpFolhaInstPensao, pkgpag_tipo.cnTpFolhaCtisp, pkgpag_tipo.cnTpFolhaServAfast) ) ) THEN



         if (vFol(fp).CdTipoFolhaPagamento in (1505) and vFol(fp).CdOrgao = 2)
           OR vFol(fp).CdTipoFolhaPagamento in (1525,1526)
           or (vFol(fp).CdOrgao = 2 and pkgpag_var.vgFolha.cdTipoFolha in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13))
         then
         SELECT NVL(MAX(FP.DtCalculo), ADD_months(trunc(max(FPA.DtCalculo), 'MM'), -1))
            INTO vDtCalculoAnt
            FROM EPagFolhaPagamento FP, EpagFolhaPagamento FPA
           WHERE FPA.Cdfolhapagamento = pCdFolhaPagamento
             AND FP.CdTipoCalculo = CASE
                                      WHEN FPA.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoRecalculoMes,PKGPAG_TIPO.cnTpCalculoSupl) THEN
                                        PKGPAG_TIPO.cnTpCalculoNormal
                                      ELSE
                                        FPA.CdTipoCalculo
                                     END
             AND FP.CdTipoFolhaPagamento = FPA.CdTipoFolhaPagamento
             and fp.cdorgao = fpa.cdorgao
             AND ((FP.NuAnoReferencia = FPA.NuAnoReferencia
               AND FP.NuMesReferencia < FPA.NuMesReferencia)
                OR FP.NuAnoReferencia < FPA.NuAnoReferencia);

        vSqlEfetivo := cSelPesVinc ||
                       ' cef.cdhistcargoefetivo as cdHistVinculo,' ||
                       ' cef.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                       ' cef.DtInicio as DtInicioRelacao,' ||
                       ' cef.DtFim as DtFimRelacao' ||
                         ' FROM ecadvinculo v' ||
                         ' INNER JOIN epaglancamentofinanceiro lf' ||
                         ' ON lf.cdvinculo = v.cdvinculo' ||
                         ' INNER JOIN epagtipofolharubrica rf' ||
                         ' ON rf.cdrubricaagrupamento = lf.cdrubricaagrupamento' ||
                         ' INNER JOIN epaghisttipofolhapagamento th' ||
                         ' ON rf.cdhisttipofolhapagamento = th.cdhisttipofolhapagamento' ||
                         ' AND th.cdtipofolhapagamento = ' || vFol(fp).CdTipoFolhaPagamento ||
                         ' INNER JOIN ecadPessoa p' ||
                         ' ON v.cdPessoa = p.cdPessoa' ||
                         ' #VINCULOS#' ||
                         ' INNER JOIN ecadhistcargoefetivo cef' ||
                         ' ON v.cdvinculo = cef.cdvinculo' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||
                         ' #DIFMES#' ||
                         ' WHERE ((v.dtadmissao <= ' || FFORMAT_DATE (vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE (NVL(vDtCalculoAnt,vDtCompetenciaIni)) ||
                         '  OR  v.dtdesligamento IS NULL)' ||
                         ' AND cef.dtinicio <= ' || FFORMAT_DATE (vDtCompetenciaFim) ||
                         ' AND (cef.dtfim >= ' || FFORMAT_DATE (NVL(vDtCalculoAnt,vDtCompetenciaIni)) ||
                         '  OR  cef.dtfim IS NULL)) ' ||
                         '  OR (LF.FLPAGAAFASTDEFINITIVO = ''S'' ' ||
                         ' AND cef.cdhistcargoefetivo = ' ||
                          ' (select max(cdhistcargoefetivo) ' ||
                          '    from ecadhistcargoefetivo ' ||
                          '   WHERE cdvinculo = V.CDVINCULO ' ||
                          '     AND flanulado = ''N'' ' ||
                          '     AND cdorgaoexercicio = 2)) )' ||
                          ' AND cef.cdrelacaotrabalho <> 17 ' ||
                          ' AND cef.flanulado = ''N''' ||
                          ' AND v.flanulado = ''N''' ||
                          ' #CONVENIO#' ||
                          ' #SITPREV#' ||
                          ' AND LF.DtInicioDireito <  add_months(trunc (' || FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM''),1)' ||
                          ' AND ( LF.DtFimDireito >=  trunc ( ' ||  FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM'')' ||
                          ' OR LF.DtFimDireito IS NULL) ' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);


           vSqlComissionado := cSelPesVinc ||
                            ' cco.cdhistcargocom as cdHistVinculo,' ||
                            ' cco.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                            ' cco.DtInicio as DtInicioRelacao,' ||
                            ' cco.DtFim as DtFimRelacao' ||
                            ' FROM ecadvinculo v' ||
                            ' INNER JOIN ecadPessoa p' ||
                            ' ON v.cdPessoa = p.cdPessoa' ||
                            ' #VINCULOS#' ||
                            ' INNER JOIN ecadhistcargocom cco' ||
                            ' ON v.cdvinculo = cco.cdvinculo' ||
                            ' AND cco.flanulado = ''N''' ||
                            ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                            ' INNER JOIN epaglancamentofinanceiro lf' ||
                            ' ON lf.cdvinculo = v.cdvinculo' ||
                            ' INNER JOIN epagtipofolharubrica rf' ||
                            ' ON rf.cdrubricaagrupamento = lf.cdrubricaagrupamento' ||
                            ' INNER JOIN epaghisttipofolhapagamento th' ||
                            ' ON rf.cdhisttipofolhapagamento = th.cdhisttipofolhapagamento' ||
                            ' AND th.cdtipofolhapagamento = ' || vFol(fp).CdTipoFolhaPagamento ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||
                         ' #DIFMES#' ||
                         ' WHERE ((v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(NVL(vDtCalculoAnt,vDtCompetenciaIni)) ||
                            ' OR  v.dtdesligamento IS NULL)' ||
                            ' AND cco.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                            ' AND (cco.dtfim >= ' || FFORMAT_DATE(NVL(vDtCalculoAnt,vDtCompetenciaIni)) ||
                            ' OR  cco.dtfim IS NULL))' ||
                            ' OR (LF.FLPAGAAFASTDEFINITIVO = ''S''  ' ||
                            ' AND cco.cdhistcargocom = ' ||
                            ' (select max(cdhistcargocom) ' ||
                            '    from ecadhistcargocom ' ||
                            '   WHERE cdvinculo = V.CDVINCULO ' ||
                            '     AND flanulado = ''N'' ' ||
                            '     AND cdorgaoexercicio = 2))) ' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                           ' AND LF.DtInicioDireito <  add_months(trunc (' || FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM''),1)' ||
                          ' AND ( LF.DtFimDireito >=  trunc ( ' ||  FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM'')' ||
                          ' OR LF.DtFimDireito IS NULL) ' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

           else

             vSqlEfetivo := cSelPesVinc ||
                         ' cef.cdhistcargoefetivo as cdHistVinculo,' ||
                         ' cef.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                         ' cef.DtInicio as DtInicioRelacao,' ||
                         ' cef.DtFim as DtFimRelacao' ||
                         ' FROM ecadvinculo v' ||
                         ' INNER JOIN ecadPessoa p' ||
                         ' ON v.cdPessoa = p.cdPessoa' ||
                         ' #VINCULOS#' ||
                         ' INNER JOIN ecadhistcargoefetivo cef' ||
                         ' ON v.cdvinculo = cef.cdvinculo' ||
                         ' AND cef.dtinicio <= ' || FFORMAT_DATE (vDtCompetenciaFim) ||
                         ' AND (cef.dtfim >= ' || FFORMAT_DATE (vDtCompetenciaIni) ||
                         ' OR  cef.dtfim IS NULL)' ||
                         ' AND cef.cdrelacaotrabalho <> 17 ' ||
                         ' AND cef.flanulado = ''N''' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE (vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE (vDtCompetenciaIni) ||
                       ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);


            vSqlComissionado := cSelPesVinc ||
                            ' cco.cdhistcargocom as cdHistVinculo,' ||
                            ' cco.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                            ' cco.DtInicio as DtInicioRelacao,' ||
                            ' cco.DtFim as DtFimRelacao' ||
                            ' FROM ecadvinculo v' ||
                            ' INNER JOIN ecadPessoa p' ||
                            ' ON v.cdPessoa = p.cdPessoa' ||
                            ' #VINCULOS#' ||
                            ' INNER JOIN ecadhistcargocom cco' ||
                            ' ON v.cdvinculo = cco.cdvinculo' ||
                         ' AND cco.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (cco.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                            ' OR  cco.dtfim IS NULL)' ||
                            ' AND cco.flanulado = ''N''' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                            ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);


        end if;

      END IF;

      /**************
      -- Comissionado Puro
      **************/

      IF (vFlCalculandoComissionadoPuro) THEN

        vSqlComissionadoPuro := cSelPesVinc ||
                                ' cco.cdhistcargocom as cdHistVinculo,' ||
                                ' cco.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                                ' cco.DtInicio as DtInicioRelacao,' ||
                                ' cco.DtFim as DtFimRelacao' ||
                                ' FROM ecadvinculo v' ||
                                ' INNER JOIN ecadPessoa p' ||
                                ' ON v.cdPessoa = p.cdPessoa' ||
                                ' #VINCULOS#' ||
                                ' INNER JOIN ecadhistcargocom cco' ||
                                ' ON v.cdvinculo = cco.cdvinculo' ||
                         ' AND cco.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (cco.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                ' OR  cco.dtfim IS NULL)' ||
                                ' AND cco.flanulado = ''N''' ||
                                ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                ' OR  v.dtdesligamento IS NULL)' ||
                                ' AND v.flanulado = ''N''' ||
                                ' AND cco.cdhistcargoefetivoorigem IS NULL ' ||
                                ' #CONVENIO#' ||
                                ' #SITPREV#' ||
                                pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

      END IF;

      /**************
      -- Convênio
      **************/
      IF vFlCalculandoConvenio THEN
          
           vSqlEstagio := cSelPesVinc ||
                         ' bol.cdhistestagio as cdHistVinculo,' ||
                         ' bol.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                         ' bol.DtInicio as DtInicioRelacao,' ||
                         ' bol.DtFim as DtFimRelacao' ||
                           ' FROM ecadvinculo v' ||
                           ' INNER JOIN ecadPessoa p' ||
                           ' ON v.cdPessoa = p.cdPessoa' ||
                           ' #VINCULOS#' ||
                         ' INNER JOIN ecadhistestagio bol' ||
                         ' ON v.cdvinculo = bol.cdvinculoestagio' ||
                           ' AND bol.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                           ' AND (bol.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                         ' OR  bol.dtfim IS NULL)' ||
                         ' AND bol.flanulado = ''N''' ||
                           ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                           ' #UNIDORG#' ||
                           ' #RELTRAB#' ||
                           ' #DIFMES#' ||
                         ' INNER JOIN ecadhistregraempenhovinc rec' ||
                         ' ON rec.cdvinculo = v.cdvinculo' ||  
                           ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                           ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                         ' OR  v.dtdesligamento IS NULL)' ||
                           ' AND v.flanulado = ''N''' ||
                           ' AND rec.flanulado = ''N''' ||
                           ' AND rec.cdregraempenho = 4' ||
                           ' AND rec.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                           ' AND (rec.dtfim IS NULL OR rec.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaFim) || ')' ||
                           ' #SITPREV#' ||
                           pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);
                           
         vSqlEfetivo := cSelPesVinc ||
                       ' cef.cdhistcargoefetivo as cdHistVinculo,' ||
                       ' cef.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                       ' cef.DtInicio as DtInicioRelacao,' ||
                       ' cef.DtFim as DtFimRelacao' ||
                         ' FROM ecadvinculo v' ||
                         ' INNER JOIN ecadPessoa p' ||
                         ' ON v.cdPessoa = p.cdPessoa' ||
                         ' #VINCULOS#' ||
                       ' INNER JOIN ecadhistregraempenhovinc rec' ||
                         ' ON rec.cdvinculo = v.cdvinculo' ||    
                       ' INNER JOIN ecadhistcargoefetivo cef' ||
                       ' ON v.cdvinculo = cef.cdvinculo' ||
                         ' AND cef.dtinicio <= ' || FFORMAT_DATE (vDtCompetenciaFim) ||
                         ' AND (cef.dtfim >= ' || FFORMAT_DATE (vDtCompetenciaIni) ||
                       ' OR  cef.dtfim IS NULL)' ||
                       ' AND cef.cdrelacaotrabalho <> 17 ' ||
                       ' AND cef.flanulado = ''N''' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE (vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE (vDtCompetenciaIni) ||
                       ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' AND rec.flanulado = ''N''' ||
                         ' AND rec.cdregraempenho = 4' ||
                         ' AND rec.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (rec.dtfim IS NULL OR rec.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaFim) || ')' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);
                         
         vSqlLancFinanc := cSelPesVinc ||
                              ' lf.cdlancamentofinanceiro as cdHistVinculo,' ||
                              ' null AS CdRelacaoTrabalho,' ||
                              ' null AS DtInicioRelacao,' ||
                                ' null AS DtFimRelacao' ||
                                ' FROM ecadVinculo v ' ||
                              ' INNER JOIN ecadPessoa p' ||
                                ' ON v.CdPessoa = p.CdPessoa' ||
                                ' #VINCULOS# and v.nuseqmatricula not in (30,31) ' ||
                              ' INNER JOIN ecadhistregraempenhovinc rec' ||
                                ' ON rec.cdvinculo = v.cdvinculo' ||    
                              ' INNER JOIN EPagLancamentoFinanceiro LF' ||
                              '    ON V.cdVinculo = LF.cdVinculo ' ||
                                ' AND lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento from vpagrubricaagrupamento ra where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento and ra.flsuspensa = ''N'') ' ||
                                ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                                ' #UNIDORG#' ||
                              ' INNER JOIN epagrubricaagrupamento ra ' ||
                              '         ON LF.cdrubricaagrupamento = ra.cdrubricaagrupamento ' ||
                              ' INNER JOIN epagrubrica r ON r.cdrubrica = ra.cdrubrica ' ||
                              '        AND R.CdTipoRubrica IN (1,2,3,4,10,12)' || -- Somente para proventos
                                ' WHERE V.DtDesligamento < ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                ' AND LF.DtInicioDireito <  add_months(trunc (' || FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM''),1)' ||
                                ' AND ( LF.DtFimDireito >=  trunc ( ' ||  FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM'')' ||
                              ' OR LF.DtFimDireito IS NULL) AND LF.FlPagaAfastDefinitivo = ''S''' ||
                              ' AND v.flAnulado = ''N''' || -- acrescentado. so tem no SQL interno
                              ' AND rec.flanulado = ''N''' ||
                              ' AND rec.cdregraempenho = 4' ||
                              ' AND rec.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                              ' AND (rec.dtfim IS NULL OR rec.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaFim) || ')' ||
                              pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

         vSqlDesligados := cSelPesVinc ||
                              ' V.cdVinculo as cdHistVinculo,' ||
                              ' null as CdRelacaoTrabalho,' ||
                              ' null as DtInicioRelacao,' ||
                                ' null as DtFimRelacao' ||
                                ' FROM ecadVinculo v ' ||
                              ' INNER JOIN ecadPessoa p' ||
                                ' ON v.cdPessoa = p.cdPessoa' ||
                                ' #VINCULOS#' ||
                              ' INNER JOIN ecadhistregraempenhovinc rec' ||
                                ' ON rec.cdvinculo = v.cdvinculo' ||      
                              ' INNER JOIN EAfaAfastamentoVinculo AV' ||
                              '   ON V.CdVinculo = AV.cdVinculo ' ||
                              ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                                ' #UNIDORG#' ||
                              ' WHERE AV.FlTipoAfastamento = ''D''' ||
                              '  AND AV.FlAnulado = ''N''' ||
                              '  AND V.DtDesligamento < ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                              '  AND AV.DtInclusao BETWEEN ' || FFORMAT_DATE(vDtCalculoAnt + 1) ||
                              --'  AND AV.DtInclusao BETWEEN ' || FFORMAT_DATE(ADD_MONTHS(vDtCompetenciaIni, -1)) ||
                              '  AND ' || FFORMAT_LAST_HOUR(pDtCalculo) ||
                              '  AND v.flanulado = ''N''' || -- acrescentado. so tem no SQL interno
                              ' AND rec.flanulado = ''N''' ||
                              ' AND rec.cdregraempenho = 4' ||
                              ' AND rec.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                              ' AND (rec.dtfim IS NULL OR rec.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaFim) || ')' ||
                              pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);                         
                         
      END IF;  
 
      /**************
      -- Estagio
      **************/

      IF (vFlCalculandoEstagio OR pFlIncluiBolsista = 'S') THEN

        vSqlEstagio := cSelPesVinc ||
                       ' bol.cdhistestagio as cdHistVinculo,' ||
                       ' bol.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                       ' bol.DtInicio as DtInicioRelacao,' ||
                       ' bol.DtFim as DtFimRelacao' ||
                       ' FROM ecadvinculo v' ||
                       ' INNER JOIN ecadPessoa p' ||
                       ' ON v.cdPessoa = p.cdPessoa' ||
                       ' #VINCULOS#' ||
                       ' INNER JOIN ecadhistestagio bol' ||
                       ' ON v.cdvinculo = bol.cdvinculoestagio' ||
                       ' AND bol.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                       ' AND (bol.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                       ' OR  bol.dtfim IS NULL)' ||
                       ' AND bol.flanulado = ''N''' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                       ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);
      END IF;

      /**************
      -- Aposentadoria
      **************/

       IF pCdRelacaoTrabalho IS NULL AND pCdTipoFolha NOT IN (PKGPAG_TIPO.cnTpFolhaInstPensao, Pkgpag_Tipo.cnTpFolhaServAfast) THEN
         IF pCdTipoFolha = PKGPAG_TIPO.cnTpFolhaAposentadoria OR pFlIncluiAposentado = 'S' THEN

          if (vFol(fp).CdTipoFolhaPagamento in (1505,1525,1526)
              or pkgpag_var.vgFolha.cdTipoFolha in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13))
             and vFol(fp).CdOrgao = 2
          then
          vSqlAposentadoria := cSelPesVinc ||
                               ' ap.cdconcessaoaposentadoria as cdHistVinculo,' ||
                               ' null as CdRelacaoTrabalho,' ||
                               ' ap.DtInicioAposentadoria as DtInicioRelacao,' ||
                               ' ap.DtFimAposentadoria as DtFimRelacao' ||
                               ' FROM ecadvinculo v' ||
                           ' INNER JOIN epaglancamentofinanceiro lf' ||
                            ' ON lf.cdvinculo = v.cdvinculo' ||
                            ' INNER JOIN epagtipofolharubrica rf' ||
                            ' ON rf.cdrubricaagrupamento = lf.cdrubricaagrupamento' ||
                            ' INNER JOIN epaghisttipofolhapagamento th' ||
                            ' ON rf.cdhisttipofolhapagamento = th.cdhisttipofolhapagamento' ||
                            ' AND th.cdtipofolhapagamento = ' || vFol(fp).CdTipoFolhaPagamento ||
                               ' INNER JOIN ecadPessoa p' ||
                               ' ON v.cdPessoa = p.cdPessoa' ||
                               ' #VINCULOS#' ||
                               ' INNER JOIN epvdconcessaoaposentadoria ap' ||
                               ' ON v.cdvinculo = ap.cdvinculo' ||
                           ' AND ap.dtinicioaposentadoria <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                           ' AND (ap.dtfimaposentadoria >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                               ' OR  ap.dtfimaposentadoria IS NULL)' ||
                               ' AND ap.flanulado = ''N''' ||
                               ' AND ap.flativa = ''S''' ||
                               ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                           ' #UNIDORG#' ||
                           ' #DIFMES#' ||
                           ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                           ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                               ' OR  v.dtdesligamento IS NULL)' ||
                           ' AND v.flanulado = ''N''' ||
                           ' #CONVENIO#' ||
                           ' #SITPREV#'||
                           ' AND LF.DtInicioDireito <  add_months(trunc (' || FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM''),1)' ||
                           ' AND ( LF.DtFimDireito >=  trunc ( ' ||  FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM'')' ||
                           ' OR LF.DtFimDireito IS NULL) ' ||
                           pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

            else

            vSqlAposentadoria := cSelPesVinc ||
                               ' ap.cdconcessaoaposentadoria as cdHistVinculo,' ||
                               ' null as CdRelacaoTrabalho,' ||
                               ' ap.DtInicioAposentadoria as DtInicioRelacao,' ||
                               ' ap.DtFimAposentadoria as DtFimRelacao' ||
                               ' FROM ecadvinculo v' ||
                               ' INNER JOIN ecadPessoa p' ||
                               ' ON v.cdPessoa = p.cdPessoa' ||
                               ' #VINCULOS#' ||
                               ' INNER JOIN epvdconcessaoaposentadoria ap' ||
                               ' ON v.cdvinculo = ap.cdvinculo' ||
                               ' AND ap.dtinicioaposentadoria <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                               ' AND (ap.dtfimaposentadoria >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                               ' OR  ap.dtfimaposentadoria IS NULL)' ||
                               ' AND ap.flanulado = ''N''' ||
                               ' AND ap.flativa = ''S''' ||
                               ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                           ' #UNIDORG#' ||
                           ' #DIFMES#' ||
                           ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                           ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                               ' OR  v.dtdesligamento IS NULL)' ||
                           ' AND v.flanulado = ''N''' ||
                           ' #CONVENIO#' ||
                           ' #SITPREV#'||
                           pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

          end if;

        END IF;

      END IF;

      /**************
      -- Folha Instituidores
      **************/
      IF  pCdRelacaoTrabalho IS NULL AND pCdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao THEN

        vSqlEfetivo := cSelPesVinc ||
                       ' cef.cdhistcargoefetivo as cdHistVinculo,' ||
                       ' cef.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                       ' cef.DtInicio as DtInicioRelacao,' ||
                       ' cef.DtFim as DtFimRelacao' ||
                       ' FROM ecadvinculo v' ||
                       ' INNER JOIN ecadorgao org ' ||
                       ' on org.cdorgao = v.cdorgao ' ||
                       ' INNER JOIN ecadPessoa p' ||
                       ' ON v.cdPessoa = p.cdPessoa' ||

                      -- BUSCA REGISTRO DE OBITO (apenas um registro)
                       /*' INNER JOIN eafaregistroobito o on o.cdpessoa = p.cdpessoa ' ||
                       ' and o.cdagrupamento = org.cdagrupamento ' ||
                       ' and o.flanulado = ''N'' ' ||*/

                       ' INNER JOIN ( ' ||
                       ' select distinct ipp.cdvinculo ' ||
                       ' from epvdinstituidorpensaoprev ipp ' ||
                       ' inner join epvdhistpensaoprevidenciaria hpp ' ||
                       ' on hpp.cdhistpensaoprevidenciaria = ipp.cdhistpensaoprevidenciaria ' ||
                       ' where ipp.flanulado = ''N'' ' ||
                       ' and hpp.flanulado = ''N'' ' ||
                       ' and hpp.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                       ' and ( hpp.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                       ' or hpp.dtfim is null) ' ||
                       ' ) ip ' ||
                       ' ON ip.cdvinculo = v.cdvinculo ' ||
                       ' #VINCULOS#' ||
                       ' INNER JOIN ecadhistcargoefetivo cef' ||
                       ' ON v.cdvinculo = cef.cdvinculo' ||
                       ' AND cef.flanulado = ''N''' ||
                       ' AND cef.cdrelacaotrabalho <> 10' ||

                       ' AND cef.dtinicio = (' ||
                       '    select max(cef2.dtinicio)' ||
                       '    from ecadhistcargoefetivo cef2' ||
                       '    where  cef2.cdvinculo = cef.cdvinculo' ||
                       '    AND cef2.flanulado = ''N'' ' ||
                       '    AND cef2.cdrelacaotrabalho <> 10' ||
                       ')' ||

                       ' AND [COLCDORGAO] '|| vSqlFiltroOrgao || ' #UNIDORG#' ||
                       ' #RELTRAB#' ||

                      -- Busca o ultimo local trabalho
                      ' INNER JOIN ecadlocaltrabalho LT ' ||
                      ' ON LT.CdHistCargoEfetivo = cef.CdHistCargoEfetivo ' ||
                      ' AND LT.DtInicio = ' ||
                      '                (SELECT MAX(DtInicio) AS DtInicio ' ||
                      '                   FROM ecadlocaltrabalho lt' ||
                      '                   WHERE LT.CdVinculo = v.CdVinculo' ||
                      '                   AND LT.FlDefinitiva = ''S'' ' ||
                      '                   AND LT.FlAnulado = ''N'' ' ||
                      '                   AND LT.DtInicio <= ' ||
                                          FFORMAT_DATE(vDtCompetenciaFim) ||
                      '                   AND LT.CdHistCargoEfetivo = cef.CdHistCargoEfetivo) ' ||
                      ' AND LT.FlDefinitiva = ''S'' ' ||
                      ' AND LT.FlAnulado = ''N'' ' ||

                      ' WHERE v.flanulado = ''N''' ||

                      ' AND NOT EXISTS  ( ' ||
                      '    select 1 from epvdconcessaoaposentadoria apo ' ||
                      '    where apo.cdvinculo = cef.cdvinculo ' ||
                      '    and apo.flanulado = ''N'' ' ||
                      '    and apo.FlAtiva = ''S'' ' ||
                      '    and apo.dtinicioaposentadoria > cef.dtinicio) ' ||

                       -- POG PARA COMPARATIVO DURANTE A IMPLANTAC?O
                       -- RETIRAR QUANDO IMPLANTAR AS PENS?ES
                       /*' AND ( ''' || pCalculo.FlGeral || ''' = ''I'' ' ||
                       ' OR ' || pCdTipoCalculo || ' = 1 ' ||
                       ' OR EXISTS ( ' ||
                       ' select 1 ' ||
                       ' from epagfolhapagamento fp ' ||
                       ' inner join epaghistoricorubricavinculo hrv ' ||
                       ' on hrv.cdfolhapagamento = fp.cdfolhapagamento ' ||
                       ' where hrv.cdvinculo = v.cdvinculo ' ||
                       ' and   fp.cdorgao = [COLCDORGAO] '||
                       ' and   fp.nuanoreferencia = ' || to_char (vDtCompetenciaIni,'YYYY') ||
                       ' and   fp.numesreferencia = ' || to_char (vDtCompetenciaIni,'MM') ||
                       ' and   fp.cdtipocalculo = 1 ' ||
                       ' and   fp.cdtipofolhapagamento = ' || pCdTipoFolhaPagamento ||
                       ' ) ) ' ||*/

                       -- Regime proprio - IPREV
                       ' AND v.cdregimeprevidenciario in ( ' ||  PKGPAG_TIPO.cnRegPrevProprio || ', ' || PKGPAG_TIPO.cnRegPrevCPSM || ' ) ' ||
                       ' #CONVENIO#' ||
                       ' #SITPREV#';

        vSqlComissionado := cSelPesVinc ||
                         ' cco.cdhistcargocom as cdHistVinculo,' ||
                         ' cco.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                         ' cco.DtInicio as DtInicioRelacao,' ||
                         ' cco.DtFim as DtFimRelacao' ||
                         ' FROM ecadvinculo v' ||
                         ' INNER JOIN ecadorgao org ' ||
                         ' ON org.cdorgao = v.cdorgao ' ||
                         ' INNER JOIN ecadPessoa p' ||
                         ' ON v.cdPessoa = p.cdPessoa' ||

                         -- BUSCA REGISTRO DE OBITO (apenas um registro)
                         ' INNER JOIN eafaregistroobito o on o.cdpessoa = p.cdpessoa ' ||
                         ' and o.cdagrupamento = org.cdagrupamento ' ||
                         ' and o.flanulado = ''N'' ' ||
                         ' #VINCULOS#' ||
                         ' INNER JOIN ecadhistcargocom cco' ||
                         ' ON v.cdvinculo = cco.cdvinculo' ||
                         ' AND cco.flanulado = ''N''' ||
                         ' AND cco.cdhistcargoefetivoorigem IS NULL ' ||
                         ' AND cco.dtfim = o.dtobito-1 ' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #RELTRAB#' ||

                         ' WHERE v.flanulado = ''N''' ||
                         -- Regime proprio - IPREV
                         ' AND v.cdregimeprevidenciario = ' ||  PKGPAG_TIPO.cnRegPrevProprio ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#';

        vSqlAposentadoria := cSelPesVinc ||
                               ' ap.cdconcessaoaposentadoria as cdHistVinculo,' ||
                               ' null as CdRelacaoTrabalho,' ||
                               ' ap.DtInicioAposentadoria as DtInicioRelacao,' ||
                               ' ap.DtFimAposentadoria as DtFimRelacao' ||
                               ' FROM ecadvinculo v' ||
                               ' INNER JOIN ecadPessoa p' ||
                               ' ON v.cdPessoa = p.cdPessoa' ||
                              -- BUSCA REGISTRO DE OBITO
                               ' INNER JOIN ( ' ||
                               ' select distinct ipp.cdvinculo ' ||
                               ' from epvdinstituidorpensaoprev ipp ' ||
                               ' inner join epvdhistpensaoprevidenciaria hpp ' ||
                               ' on hpp.cdhistpensaoprevidenciaria = ipp.cdhistpensaoprevidenciaria ' ||
                               ' where ipp.flanulado = ''N'' ' ||
                               ' and hpp.flanulado = ''N'' ' ||
                               ' and hpp.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                               ' and ( hpp.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                               ' or hpp.dtfim is null) ' ||
                               ' ) ip ' ||
                               ' ON ip.cdvinculo = v.cdvinculo ' ||
                               ' #VINCULOS#' ||
                               ' INNER JOIN epvdconcessaoaposentadoria ap' ||
                               ' ON v.cdvinculo = ap.cdvinculo' ||
                               ' AND ap.flanulado = ''N''' ||
                               ' AND ap.flativa = ''S''' ||
                               ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                                 ' #UNIDORG#' ||
                                 ' #DIFMES#' ||
                               ' WHERE v.flanulado = ''N''' ||

                               ' AND NOT EXISTS  ( ' ||
                               '    select 1 from epvdconcessaoaposentadoria apo ' ||
                               '    where apo.cdvinculo = ap.cdvinculo ' ||
                               '    and apo.flanulado = ''N'' ' ||
                               '    and apo.FlAtiva = ''S'' ' ||
                               '    and apo.dtinicioaposentadoria > ap.dtinicioaposentadoria) ' ||

                              -- POG PARA COMPARATIVO DURANTE A IMPLANTAC?O
                              -- RETIRAR QUANDO IMPLANTAR AS PENS?ES
                              /*  ' AND ( ''' || pCalculo.FlGeral || ''' = ''I'' ' ||
                                ' OR ' || pCdTipoCalculo || ' = 1 ' ||
                                ' OR EXISTS ( ' ||
                                    ' select 1 ' ||
                                    ' from epagfolhapagamento fp ' ||
                                    ' inner join epaghistoricorubricavinculo hrv ' ||
                                    ' on hrv.cdfolhapagamento = fp.cdfolhapagamento ' ||
                                    ' where hrv.cdvinculo = v.cdvinculo ' ||
                                    ' and   fp.cdorgao = [COLCDORGAO] '||
                                    ' and   fp.nuanoreferencia = ' || to_char (vDtCompetenciaIni,'YYYY') ||
                                    ' and   fp.numesreferencia = ' || to_char (vDtCompetenciaIni,'MM') ||
                                    ' and   fp.cdtipocalculo = 1 ' ||
                                    ' and   fp.cdtipofolhapagamento = ' || pCdTipoFolhaPagamento ||
                                 ' )) ' ||*/
                               ' #CONVENIO#' ||  
                               ' #SITPREV#';

          vSqlPensaoNaoPrev := cSelPesVinc ||
                             ' pnp.cdhistpensaonaoprev as cdHistVinculo,' ||
                             ' null as CdRelacaoTrabalho,' ||
                             ' pnp.DtInicio as DtInicioRelacao,' ||
                             ' pnp.DtFim as DtFimRelacao' ||
                             ' FROM ecadvinculo v' ||
                             ' INNER JOIN ecadPessoa p' ||
                             ' ON v.cdPessoa = p.cdPessoa' ||
                             ' #VINCULOS#' ||
                             ' INNER JOIN ( ' ||
                             '  select distinct ipp.cdvinculo ' ||
                             '  from epvdinstituidorpensaoprev ipp ' ||
                             '  inner join epvdhistpensaoprevidenciaria hpp ' ||
                             '  on hpp.cdhistpensaoprevidenciaria = ipp.cdhistpensaoprevidenciaria ' ||
                             '  where ipp.flanulado = ''N'' ' ||
                             '  and hpp.flanulado = ''N'' ' ||
                             '  and hpp.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                             '  and ( hpp.dtfim >=  ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                             '  or hpp.dtfim is null)  ' ||
                             '  ) ip  ' ||
                             ' ON ip.cdvinculo = v.cdvinculo ' ||
                             ' INNER JOIN epvdhistpensaonaoprev pnp' ||
                             ' ON ip.cdvinculo = pnp.cdvinculobeneficiario' ||
                             ' AND v.cdsituacaoprevidenciaria = 3 ' ||
                             ' AND pnp.dtinicio = (' ||
                             '    select max(pnp2.dtinicio)' ||
                             '    from epvdhistpensaonaoprev pnp2' ||
                             '    where  pnp2.cdvinculobeneficiario = pnp.cdvinculobeneficiario' ||
                             '    AND pnp2.flanulado = ''N'' ' ||
                             ')' ||
                             ' AND pnp.flanulado = ''N''' ||
                             ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#';

      END IF;

      end if;
      /**************
      -- Outras Relac?es
      **************/

      -- So inclui as relac?es de vinculo restantes se n?o existir filtro por Relac?o de Trabalho, pois as mesmas
      -- n?o possuem relac?o de trabalho.

       IF NOT ( pCdRelacaoTrabalho IS NOT NULL
                OR vFlCalculandoEstagio
                OR vFlCalculando13
                OR vFlCalculandoComissionadoPuro
                OR vFlCalculandoConvenio
                OR vFol(fp).CdTipoFolhaPagamento in (1505,1525,1526)
             ----  or pkgpag_var.vgFolha.cdTipoFolha in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13)
                or pCdTipoFolha in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13)
                OR pCdTipoFolha in (PKGPAG_TIPO.cnTpFolhaInstPensao, pkgpag_tipo.cnTpFolhaCtisp, pkgpag_tipo.cnTpFolhaServAfast) ) THEN

        vSqlFuncaoChefia := cSelPesVinc ||
                            ' fuc.cdhistfuncaochefia as cdHistVinculo,' ||
                            ' fuc.CdRelacaoTrabalho as CdRelacaoTrabalho,' ||
                            ' fuc.DtInicio as DtInicioRelacao,' ||
                            ' fuc.DtFim as DtFimRelacao' ||
                            ' FROM ecadvinculo v' ||
                            ' INNER JOIN ecadPessoa p' ||
                            ' ON v.cdPessoa = p.cdPessoa' ||
                            ' #VINCULOS#' ||
                            ' INNER JOIN ecadhistfuncaochefia fuc' ||
                            ' ON v.cdvinculo = fuc.cdvinculo' ||
                            ' AND fuc.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                            ' AND (fuc.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                            ' OR  fuc.dtfim IS NULL)' ||
                            ' AND fuc.flanulado = ''N''' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                            ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

        vSqlPensaoPrev := cSelPesVinc ||
                          ' pp.cdhistpensaoprevidenciaria as cdHistVinculo,' ||
                          ' null as CdRelacaoTrabalho,' ||
                          ' pp.DtInicio as DtInicioRelacao,' ||
                          ' pp.DtFim as DtFimRelacao' ||
                          ' FROM ecadvinculo v' ||
                          ' INNER JOIN ecadPessoa p' ||
                          ' ON v.cdPessoa = p.cdPessoa' ||
                          ' #VINCULOS#' ||
                          ' INNER JOIN epvdhistpensaoprevidenciaria pp' ||
                          ' ON v.cdvinculo = pp.cdvinculo' ||
                          ' AND pp.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                          ' AND (pp.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                          ' OR  pp.dtfim IS NULL)' ||
                          ' AND pp.flanulado = ''N''' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                          ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

        vSqlPensaoNaoPrev := cSelPesVinc ||
                             ' pnp.cdhistpensaonaoprev as cdHistVinculo,' ||
                             ' null as CdRelacaoTrabalho,' ||
                             ' pnp.DtInicio as DtInicioRelacao,' ||
                             ' pnp.DtFim as DtFimRelacao' ||
                             ' FROM ecadvinculo v' ||
                             ' INNER JOIN ecadPessoa p' ||
                             ' ON v.cdPessoa = p.cdPessoa' ||
                             ' #VINCULOS#' ||
                             ' INNER JOIN epvdhistpensaonaoprev pnp' ||
                             ' ON v.cdvinculo = pnp.cdvinculobeneficiario' ||
                         ' AND pnp.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (pnp.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                             ' OR  pnp.dtfim IS NULL)' ||
                             ' AND pnp.flanulado = ''N''' ||
                             ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                             ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

        vSqlAuxReclusao := cSelPesVinc ||
                           ' ar.cdhistauxilioreclusao as cdHistVinculo,' ||
                           ' null as CdRelacaoTrabalho,' ||
                           ' ar.DtInicio as DtInicioRelacao,' ||
                           ' ar.DtFim as DtFimRelacao' ||
                           ' FROM ecadvinculo v' ||
                           ' INNER JOIN ecadPessoa p' ||
                           ' ON v.cdPessoa = p.cdPessoa' ||
                           ' #VINCULOS#' ||
                           ' INNER JOIN epvdhistauxilioreclusao ar' ||
                           ' ON v.cdvinculo = ar.cdvinculo' ||
                           ' AND ar.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                           ' AND (ar.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                           ' OR  ar.dtfim IS NULL)' ||
                           ' AND ar.flanulado = ''N''' ||
                         ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                           ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

        vSqlExParlamentar := cSelPesVinc ||
                             ' pep.cdhistpensaoexparlamentar as cdHistVinculo,' ||
                             ' null as CdRelacaoTrabalho,' ||
                             ' pep.DtInicio as DtInicioRelacao,' ||
                             ' pep.DtFim as DtFimRelacao' ||
                             ' FROM ecadvinculo v' ||
                             ' INNER JOIN ecadPessoa p' ||
                             ' ON v.cdPessoa = p.cdPessoa' ||
                             ' #VINCULOS#' ||
                             ' INNER JOIN  epvdhistpensaoexparlamentar pep' ||
                             ' ON v.cdvinculo = pep.cdvinculo' ||
                             ' AND pep.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                             ' AND (pep.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                             ' OR  pep.dtfim IS NULL)' ||
                             ' AND pep.flanulado = ''N''' ||
                             ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                         ' #UNIDORG#' ||
                         ' #DIFMES#' ||
                         ' WHERE v.dtadmissao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                         ' AND (v.dtdesligamento >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                             ' OR  v.dtdesligamento IS NULL)' ||
                         ' AND v.flanulado = ''N''' ||
                         ' #CONVENIO#' ||
                         ' #SITPREV#' ||
                         pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

      END IF;

      /**************
      -- Lanc. Fin./Desligados
      **************/

      ---------------------------------------------------------------------------------------------
      -- Caso n?o sejam definidos os parametros abaixo,
      -- seleciona vinculos finalizados que possuem lancamentos financeiros vigentes no
      -- ano e mes do processamento ou que possuam afastamento definitivo com data de inclus?o
      -- entre a data do calculo anterior e o calculo atual
      ---------------------------------------------------------------------------------------------

      IF pCdTipoFolha NOT IN (PKGPAG_TIPO.cnTpFolhaInstPensao, PKGPAG_TIPO.cnTpFolhaServAfast)
         AND (NOT vFlCalculando13)
         AND (NOT vFlCalculandoDifMes)
         AND (NOT vFlCalculandoConvenio)
         AND pCalculo.InTipoExecucao in (1, 2)
      THEN

        IF pCdFolhaPagamento IS NULL or pCdFolhaPagamento = 0 THEN
          SELECT NVL(MAX(DtCalculo), trunc(vDtCompetenciaIni - 1, 'MM'))
            INTO vDtCalculoAnt
            FROM EPagFolhaPagamento FP
           WHERE FP.CdTipoCalculo = pCdTipoCalculo
             AND FP.CdTipoFolhaPagamento = pCdTipoFolhaPagamento
             --and FP.DtCalculo < vDtCalculo
             and fp.cdorgao = vFol(fp).CdOrgao
             AND ((FP.NuAnoReferencia = to_number(to_char(vDtCompetenciaIni, 'YYYY'))
               AND FP.NuMesReferencia < to_number(to_char(vDtCompetenciaIni, 'MM')))
                OR FP.NuAnoReferencia < to_number(to_char(vDtCompetenciaIni, 'YYYY')));
        ELSE
          SELECT NVL(MAX(FP.DtCalculo), ADD_months(trunc(max(FPA.DtCalculo), 'MM'), -1))
            INTO vDtCalculoAnt
            FROM EPagFolhaPagamento FP, EpagFolhaPagamento FPA
           WHERE FPA.Cdfolhapagamento = pCdFolhaPagamento
             AND FP.CdTipoCalculo = CASE
                                      WHEN FPA.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoRecalculoMes,PKGPAG_TIPO.cnTpCalculoSupl) THEN
                                        PKGPAG_TIPO.cnTpCalculoNormal
                                      ELSE
                                        FPA.CdTipoCalculo
                                     END
             AND FP.CdTipoFolhaPagamento = FPA.CdTipoFolhaPagamento
             and fp.cdorgao = fpa.cdorgao
             AND ((FP.NuAnoReferencia = FPA.NuAnoReferencia
               AND FP.NuMesReferencia < FPA.NuMesReferencia)
                OR FP.NuAnoReferencia < FPA.NuAnoReferencia);
        END IF;


        IF pkgpag_tipo.cnTpFolhaCtisp = pCdTipoFolha then

            vSqlLancFinanc := cSelPesVinc ||
                                    ' lf.cdlancamentofinanceiro as cdHistVinculo,' ||
                                    ' null AS CdRelacaoTrabalho,' ||
                                    ' null AS DtInicioRelacao,' ||
                                    ' null AS DtFimRelacao' ||
                                    ' FROM ecadVinculo v ' ||
                                    ' INNER JOIN ecadPessoa p' ||
                                    ' ON v.CdPessoa = p.CdPessoa' ||                                    
                                    ' #VINCULOS# and v.nuseqmatricula in (30,31) ' ||
                                     ' INNER JOIN ( ' ||
                                     ' select distinct conv.cdvinculo ' ||
                                     ' from epvdconvocacaoaposentado conv ' ||
                                     ' where conv.flanulado = ''N'' ' ||
                                     ' and conv.flgerarpagamento = ''S'' ' ||
                                     ' and conv.dtinicioconvocacao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                                     --' and ( conv.dtfimconvocacao >= ' || FFORMAT_DATE(vDtCompetenciaIni) || ' or conv.dtfimconvocacao is null) ' || comentado no chamado 80276
                                     ' ) cv ' ||
                                     ' ON cv.cdvinculo = v.cdvinculo ' ||
                                  ' INNER JOIN EPagLancamentoFinanceiro LF' ||
                                  '    ON V.cdVinculo = LF.cdVinculo ' ||
                                    ' AND lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento from vpagrubricaagrupamento ra where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento and ra.flsuspensa = ''N'') ' ||
                                    ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                                    ' #UNIDORG#' ||
                                  ' INNER JOIN epagrubricaagrupamento ra ' ||
                                  '         ON LF.cdrubricaagrupamento = ra.cdrubricaagrupamento ' ||
                                  ' INNER JOIN epagrubrica r ON r.cdrubrica = ra.cdrubrica ' ||
                                  '        AND R.CdTipoRubrica IN (1,2,3,4,10,12)' || -- Somente para proventos
                                    ' WHERE V.DtDesligamento < ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                    ' AND LF.DtInicioDireito <  add_months(trunc (' || FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM''),1)' ||
                                    ' AND ( LF.DtFimDireito >=  trunc ( ' ||  FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM'')' ||
                                  ' OR LF.DtFimDireito IS NULL) AND LF.FlPagaAfastDefinitivo = ''S''' ||
                                  ' #CONVENIO#' ||
                                  ' AND v.flAnulado = ''N'''; -- acrescentado. so tem no SQL interno


              vSqlDesligados := cSelPesVinc ||
                                  ' V.cdVinculo as cdHistVinculo,' ||
                                  ' null as CdRelacaoTrabalho,' ||
                                  ' null as DtInicioRelacao,' ||
                                  ' null as DtFimRelacao' ||
                                  ' FROM ecadVinculo v ' ||
                                  ' INNER JOIN ecadPessoa p' ||
                                  ' ON v.cdPessoa = p.cdPessoa' ||
                                  ' INNER JOIN ( ' ||
                                     ' select distinct conv.cdvinculo ' ||
                                     ' from epvdconvocacaoaposentado conv ' ||
                                     ' where conv.flanulado = ''N'' ' ||
                                     ' and conv.flgerarpagamento = ''S'' ' ||
                                     ' and conv.dtinicioconvocacao <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                                     ' and ( conv.dtfimconvocacao >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                     ' or conv.dtfimconvocacao is null) ' ||
                                     ' ) cv ' ||
                                     ' ON cv.cdvinculo = v.cdvinculo ' ||                               
                                  ' #VINCULOS#' ||
                                  ' INNER JOIN EAfaAfastamentoVinculo AV' ||
                                  '   ON V.CdVinculo = AV.cdVinculo ' ||
                                  ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                                  ' #UNIDORG#' ||
                                ' WHERE AV.FlTipoAfastamento = ''D''' ||
                                '  AND AV.FlAnulado = ''N''' ||
                                '  AND V.DtDesligamento < ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                '  AND AV.DtInclusao BETWEEN ' || FFORMAT_DATE(vDtCalculoAnt + 1) ||
                                --'  AND AV.DtInclusao BETWEEN ' || FFORMAT_DATE(ADD_MONTHS(vDtCompetenciaIni, -1)) ||
                                '  AND ' || FFORMAT_LAST_HOUR(pDtCalculo) ||
                                ' #CONVENIO#' ||
                                '  AND v.flanulado = ''N'''; -- acrescentado. so tem no SQL interno


        else

            if vFol(fp).CdTipoFolhaPagamento not in (1505,1525,1526) then

            vSqlLancFinanc := cSelPesVinc ||
                                ' lf.cdlancamentofinanceiro as cdHistVinculo,' ||
                                ' null AS CdRelacaoTrabalho,' ||
                                ' null AS DtInicioRelacao,' ||
                                ' null AS DtFimRelacao' ||
                                ' FROM ecadVinculo v ' ||
                                ' INNER JOIN ecadPessoa p' ||
                                ' ON v.CdPessoa = p.CdPessoa' ||
                                ' #VINCULOS# and v.nuseqmatricula not in (30,31) ' ||
                                ' INNER JOIN EPagLancamentoFinanceiro LF' ||
                                '    ON V.cdVinculo = LF.cdVinculo ' ||
                                ' AND lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento from vpagrubricaagrupamento ra where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento and ra.flsuspensa = ''N'') ' ||
                                ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                                ' #UNIDORG#' ||
                              ' INNER JOIN epagrubricaagrupamento ra ' ||
                              '         ON LF.cdrubricaagrupamento = ra.cdrubricaagrupamento ' ||
                              ' INNER JOIN epagrubrica r ON r.cdrubrica = ra.cdrubrica ' ||
                              '        AND R.CdTipoRubrica IN (1,2,3,4,10,12)' || -- Somente para proventos
                                ' WHERE V.DtDesligamento < ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                ' AND LF.DtInicioDireito <  add_months(trunc (' || FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM''),1)' ||
                                ' AND ( LF.DtFimDireito >=  trunc ( ' ||  FFORMAT_DATE(vDtCompetenciaIni) || ', ''MM'')' ||
                              ' OR LF.DtFimDireito IS NULL) AND LF.FlPagaAfastDefinitivo = ''S''' ||
                              ' #CONVENIO#' ||
                              ' AND v.flAnulado = ''N''' || -- acrescentado. so tem no SQL interno
                              pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

              vSqlDesligados := cSelPesVinc ||
                                ' V.cdVinculo as cdHistVinculo,' ||
                                ' null as CdRelacaoTrabalho,' ||
                                ' null as DtInicioRelacao,' ||
                                ' null as DtFimRelacao' ||
                                ' FROM ecadVinculo v ' ||
                                ' INNER JOIN ecadPessoa p' ||
                                ' ON v.cdPessoa = p.cdPessoa' ||
                                ' #VINCULOS#' ||
                                ' INNER JOIN EAfaAfastamentoVinculo AV' ||
                                '   ON V.CdVinculo = AV.cdVinculo ' ||
                                ' AND [COLCDORGAO] '|| vSqlFiltroOrgao ||
                                ' #UNIDORG#' ||
                              ' WHERE AV.FlTipoAfastamento = ''D''' ||
                              '  AND AV.FlAnulado = ''N''' ||
                              '  AND V.DtDesligamento < ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                              '  AND AV.DtInclusao BETWEEN ' || FFORMAT_DATE(vDtCalculoAnt + 1) ||
                              --'  AND AV.DtInclusao BETWEEN ' || FFORMAT_DATE(ADD_MONTHS(vDtCompetenciaIni, -1)) ||
                              '  AND ' || FFORMAT_LAST_HOUR(pDtCalculo) ||
                              ' #CONVENIO#' ||
                              '  AND v.flanulado = ''N''' || -- acrescentado. so tem no SQL interno
                              pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

          end if;

        end if;

      end if;

      /**************
      -- Dif a Pagar
      **************/

       IF pCdTipoFolha in ( PKGPAG_TIPO.cnTpFolhaNormal )
          AND NOT vFlCalculandoDifMes
          AND pNuMesCompetencia <> 1 THEN -- Janeiro nao paga diferenca de dez, que e exercicio findo

         vSqlDifAPagar := cSelPesVinc ||
                           ' V.cdVinculo as cdHistVinculo,' ||
                           ' null as CdRelacaoTrabalho,' ||
                           ' null as DtInicioRelacao,' ||
                           ' null as DtFimRelacao' ||
                           ' FROM ecadVinculo v ' ||
                           ' INNER JOIN ecadPessoa p' ||
                           ' ON v.cdPessoa = p.cdPessoa' ||
                           ' #VINCULOS#' ||
                           ' INNER JOIN' ||
                      '   (SELECT DISTINCT h.CdVinculo, fa.CdOrgao' ||
                      '           FROM EPagHistoricoRubricaVinculo H' ||
                      '           INNER JOIN EPagFolhaPagamento fa' ||
                      '               ON fa.CdFolhaPagamento = H.CdFolhaPagamento' ||
                      '              WHERE fa.NuAnoReferencia = ' || pNuAnoCompetencia ||
                      '                AND fa.NuMesReferencia < ' || pNuMesCompetencia ||
                      '                AND fa.CdTipoCalculo = ' || PKGPAG_TIPO.cnTpCalculoDifMes ||
                      '                AND fa.CdTipoFolhaPagamento = [CDTIPOFOLHAPAGAMENTO]' ||
                      '                AND fa.CdOrgao = [CDORGAO] ' ||
                      '                AND H.NuSufixoRubrica = ' || pNuMesCompetencia || ') H' ||
                      '    ON H.CdVinculo = V.CdVinculo' ||
                      '   AND H.CdOrgao = [COLCDORGAO]' ||
                      ' #UNIDORG#' ||
                      ' WHERE [COLCDORGAO] '|| vSqlFiltroOrgao ||
                      '   AND v.flanulado = ''N''' ||
                      pkgpag_pre.FRetornarSqlPDI(vFol(fp).CdOrgao, pCdTipoFolha, pCdTipoFolhaPagamento);

      END IF;

      /**************
      -- Tratamento de Blocos de Parametros
      **************/

      --
      vTratar := '#VINCULOS#';
      --

      IF pCalculo.FlGeral = 'I' THEN

         IF pCdVinculo IS NOT NULL THEN
            vAux := ' AND v.cdVinculo = ' || pCdVinculo;
         ELSE
            vAux := ' AND v.CdPessoa = ' || pCdPessoa;
         END IF;

      ELSIF pFlVinculo <> 'N' THEN

        vAux := ' INNER JOIN EPagHistoricoParamCalcPessoa PCP ' ||
                '    ON PCP.CdHistoricoParamCalculo = '|| pCalculo.CdHistoricoParamCalculo ||
                ' INNER JOIN ECadVinculo PPV ' ||
                '    ON PPV.CdVinculo = PCP.CdVinculo ' ||
                '   AND v.CdPessoa = PPV.CdPessoa';
      ELSE
        vAux := '';

      END IF;

      PTrocaTudo(vTratar, vAux);

      --
      vTratar := '#CONVENIO#';
      --
      
      vAux := ' AND NOT EXISTS (SELECT 1 FROM ecadhistregraempenhovinc rec ' ||
            '                    WHERE rec.cdvinculo = v.cdvinculo' || 
            '                      AND rec.flanulado = ''N''' ||
            '                      AND rec.cdregraempenho = 4' || /* Não devem entrar pois entram na folha de convênio */
            '                      AND rec.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
            '                      AND (rec.dtfim IS NULL OR rec.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaFim) || '))';
      
      PTrocaTudo(vTratar, vAux);

      --
      vTratar := '#SITPREV#';
      --

       IF pCdSituacaoPrevidenciaria IS NOT NULL THEN -- Se existe filtro por Situac?o Previdenciaria
          vAux := ' AND v.cdsituacaoprevidenciaria = ' || pCdSituacaoPrevidenciaria;
      else
        vAux := '';
      end if;

      PTrocaTudo(vTratar, vAux);

      --
      vTratar := '#UNIDORG#';
      --

       IF pCalculo.flGeral <> 'I'
          AND pCdUnidadeOrganizacional IS NOT NULL
          AND pInSubordinadas = 1 THEN -- Se existe filtro por UO e indicar que N?O deve incluir as subordinadas

        vAux := ' AND lt.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                ' AND (lt.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                 ' OR  lt.dtfim IS NULL)' ||
                                 ' AND lt.flanulado = ''N''' ||
                                 ' AND lt.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional;

          vSqlEfetivo      := replace (vSqlEfetivo,vTratar,
                               ' INNER JOIN ecadlocaltrabalho lt' ||
                                 ' ON cef.cdhistcargoefetivo = lt.cdhistcargoefetivo' ||
                                 vAux);

          vSqlComissionado := replace (vSqlComissionado,vTratar,
                                    ' INNER JOIN ecadlocaltrabalho lt' ||
                                 ' ON  cco.cdhistcargocom = lt.cdhistcargocom' ||
                                 vAux);

          vSqlComissionadoPuro := replace (vSqlComissionadoPuro,vTratar,
                                        ' INNER JOIN ecadlocaltrabalho lt' ||
                                 ' ON  cco.cdhistcargocom = lt.cdhistcargocom' ||
                                 vAux);

          vSqlEstagio      := replace (vSqlEstagio,vTratar,
                               ' INNER JOIN ecadlocaltrabalho lt' ||
                                 ' ON  bol.cdhistestagio = lt.cdhistestagio' ||
                                 vAux);

          vSqlFuncaoChefia := replace (vSqlFuncaoChefia,vTratar,
                                    ' INNER JOIN ecadlocaltrabalho lt' ||
                                 ' ON  fuc.cdHistfuncaochefia = lt.cdHistfuncaochefia' ||
                                 vAux);

          vSqlPensaoPrev := replace (vSqlPensaoPrev,vTratar,
                                 ' AND pp.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional);

        -- Comentado por coluna n?o existir (pnp.cdunidadeorganizacional - ventura - 22/04/2014
        --vSqlPensaoNaoPrev := replace (vSqlPensaoNaoPrev,vTratar,
        --                       ' AND pnp.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional);
        vSqlPensaoNaoPrev := replace(vSqlPensaoNaoPrev, vTratar, '');

          vSqlAuxReclusao := replace (vSqlAuxReclusao,vTratar,
                                 ' AND ar.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional);

          vSqlExParlamentar := replace (vSqlExParlamentar,vTratar,
                                 ' AND pep.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional);

          vSqlAposentadoria := replace (vSqlAposentadoria,vTratar,
                                 ' AND ap.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional);

       ELSIF pCalculo.flGeral <> 'I'
         AND pCdUnidadeOrganizacional IS NOT NULL
         AND pInSubordinadas = 2 THEN -- Se existe filtro por UO e indicar que deve incluir as subordinadas

        vAux := ' AND lt.dtinicio <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                ' AND (lt.dtfim >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                  ' OR  lt.dtfim IS NULL)' ||
                                  ' AND lt.flanulado = ''N''' ||
                                  ' INNER JOIN (' ||
                                  ' SELECT huo.cdunidadeorganizacional' ||
                '  FROM ecadhistunidadeorganizacional huo' ||
                                  '  START WITH huo.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional ||
                '  CONNECT BY PRIOR huo.cdunidadeorganizacional = huo.cduosuphierarq' ||
                                                ' AND huo.dtiniciovigencia <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                                                ' AND (huo.dtfimvigencia >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                                ' OR  huo.dtfimvigencia IS NULL)' ||
                                  ' ) uo';

          vSqlEfetivo      := replace (vSqlEfetivo,vTratar,
                               ' INNER JOIN ecadlocaltrabalho lt' ||
                                  ' ON cef.cdhistcargoefetivo = lt.cdhistcargoefetivo' ||
                                  vAux ||
                               ' ON lt.cdunidadeorganizacional = uo.cdunidadeorganizacional');

          vSqlComissionado := replace (vSqlComissionado,vTratar,
                                    ' INNER JOIN ecadlocaltrabalho lt' ||
                                  ' ON  cco.cdhistcargocom = lt.cdhistcargocom' ||
                                  vAux ||
                                    ' ON lt.cdunidadeorganizacional = uo.cdunidadeorganizacional');

          vSqlComissionadoPuro := replace (vSqlComissionadoPuro,vTratar,
                                        ' INNER JOIN ecadlocaltrabalho lt' ||
                                  ' ON  cco.cdhistcargocom = lt.cdhistcargocom' ||
                                  vAux ||
                                        ' ON lt.cdunidadeorganizacional = uo.cdunidadeorganizacional');

          vSqlEstagio := replace (vSqlEstagio,vTratar,
                               ' INNER JOIN ecadlocaltrabalho lt' ||
                                  ' ON  bol.cdhistestagio = lt.cdhistestagio' ||
                                  vAux ||
                               ' ON lt.cdunidadeorganizacional = uo.cdunidadeorganizacional');

          vSqlFuncaoChefia := replace (vSqlFuncaoChefia,vTratar,
                                    ' INNER JOIN ecadlocaltrabalho lt' ||
                                  ' ON  fuc.cdHistfuncaochefia = lt.cdHistfuncaochefia' ||
                                  vAux ||
                                    ' ON lt.cdunidadeorganizacional = uo.cdunidadeorganizacional');

          vAux              :=    ' INNER JOIN (' ||
                                  ' SELECT huo.cdunidadeorganizacional' ||
                '  FROM ecadhistunidadeorganizacional huo' ||
                                  '  START WITH huo.cdunidadeorganizacional = ' || pCdUnidadeOrganizacional ||
                '  CONNECT BY PRIOR huo.cdunidadeorganizacional = huo.cduosuphierarq' ||
                                                ' AND huo.dtiniciovigencia <= ' || FFORMAT_DATE(vDtCompetenciaFim) ||
                                                ' AND (huo.dtfimvigencia >= ' || FFORMAT_DATE(vDtCompetenciaIni) ||
                                                ' OR  huo.dtfimvigencia IS NULL)' ||
                                  ' ) uo';

          vSqlPensaoPrev := replace (vSqlPensaoPrev,vTratar,
                                  vAux ||
                                  ' ON pp.cdunidadeorganizacional = uo.cdunidadeorganizacional');

        -- Comentado por coluna n?o existir (pnp.cdunidadeorganizacional - ventura - 22/04/2014

        --vSqlPensaoNaoPrev := replace (vSqlPensaoNaoPrev,vTratar,
        --                        vAux ||
        --                        ' ON pnp.cdunidadeorganizacional = uo.cdunidadeorganizacional');
        vSqlPensaoNaoPrev := replace(vSqlPensaoNaoPrev, vTratar, '');

          vSqlAuxReclusao := replace (vSqlAuxReclusao,vTratar,
                                   vAux ||
                                   ' ON ar.cdunidadeorganizacional = uo.cdunidadeorganizacional');

          vSqlExParlamentar := replace (vSqlExParlamentar,vTratar,
                                     vAux ||
                                     ' ON pep.cdunidadeorganizacional = uo.cdunidadeorganizacional');

          vSqlAposentadoria := replace (vSqlAposentadoria,vTratar,
                                     vAux ||
                                     ' ON ap.cdunidadeorganizacional = uo.cdunidadeorganizacional');

      ELSE

        PTrocaTudo(vTratar, '');

      END IF;

      vSqlLancFinanc := replace(vSqlLancFinanc, vTratar, '');
      vSqlDesligados := replace(vSqlDesligados, vTratar, '');
      vSql13Salario  := replace(vSql13Salario, vTratar, '');
      vSqlDifAPagar  := replace(vSqlDifAPagar, vTratar, '');

      --
      vTratar := '#DIFMES#';
      --
      IF vFlCalculandoDifMes THEN

        -- Verifica se ha pagamento em folha normal e suplementar
        vAux := ' INNER JOIN EPagFolhaPagamento FPP ' ||
                '   ON fpp.cdorgao '|| vSqlFiltroOrgao ||
                   '  AND fpp.nuanoreferencia = ' || to_char (vDtCompetenciaIni,'YYYY') ||
                   '  AND fpp.numesreferencia = ' || to_char (vDtCompetenciaIni,'MM') ||
                   '  AND fpp.cdtipofolhapagamento = ' || pCdTipoFolhaPagamento ||
                   '  AND fpp.cdtipocalculo = ' || PKGPAG_TIPO.cnTpCalculoNormal ||
                '  AND [SGRELACAO].dtinclusao > (fpp.DtCalculo + 1 - 1/86400) ' ||
                   '  AND [SGRELACAO].dtinclusao <= ' || FFORMAT_LAST_HOUR (vDtUltDiaAno) ||
                '  AND NOT EXISTS (SELECT 1 FROM EPagHistoricoRubricaVinculo HRV' ||
                '                   WHERE HRV.CdVinculo =  [SGRELACAO].[COLVINCULORELACAO]' ||
                '                     AND HRV.CdFolhaPagamento = fpp.CdFolhaPagamento' ||
                '                     AND ROWNUM < 2 ' ||
                   '                  UNION ' ||
                   '                  SELECT 1 ' ||
                '                    FROM EPagHistoricoRubricaVinculo HRV ' ||
                '                    INNER JOIN EPAGFOLHAPAGAMENTO FP on FP.Cdfolhapagamento = HRV.Cdfolhapagamento ' ||
                '                    WHERE HRV.CdVinculo = [SGRELACAO].[COLVINCULORELACAO] ' ||
                '                    AND fp.cdorgao = fpp.cdorgao ' ||
                   '                    AND fp.nuanoreferencia = ' || to_char (vDtCompetenciaIni,'YYYY') ||
                   '                    AND fp.numesreferencia = ' || to_char (vDtCompetenciaIni,'MM') ||
                   '                    AND fp.cdtipofolhapagamento = ' || pCdTipoFolhaPagamento ||
                   '                    AND fp.cdtipocalculo = ' || PKGPAG_TIPO.cnTpCalculoSupl ||
                '                    AND ROWNUM < 2 ' ||
                '                  ) ';

      ELSE
        vAux := '';
      END IF;

      PTrocaTudo(vTratar, vAux);

      --
      vTratar := '#RELTRAB#';
      --

       IF pCdRelacaoTrabalho IS NOT NULL THEN -- Se existe filtro por Relac?o de Trabalho
          vSqlEfetivo      := replace (vSqlEfetivo,vTratar,
                                 ' AND cef.cdrelacaotrabalho = ' || pCdRelacaoTrabalho);
          vSqlComissionado := replace (vSqlComissionado,vTratar,
                                 ' AND cco.cdrelacaotrabalho = ' || pCdRelacaoTrabalho);
          vSqlComissionadoPuro := replace (vSqlComissionadoPuro,vTratar,
                                 ' AND cco.cdrelacaotrabalho = ' || pCdRelacaoTrabalho);
      ELSE
        vSqlEfetivo          := replace(vSqlEfetivo, vTratar, '');
        vSqlComissionado     := replace(vSqlComissionado, vTratar, '');
        vSqlComissionadoPuro := replace(vSqlComissionadoPuro, vTratar, '');
      END IF;

      IF pCdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaBolsista, PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario) THEN
          vSqlEstagio       := replace (vSqlEstagio,vTratar,
                                 ' AND bol.cdrelacaotrabalho = ' || PKGPAG_TIPO.cnRelEstagiario);
      ELSIF pCdTipoFolha = PKGPAG_TIPO.cnTpFolhaResidente THEN
          vSqlEstagio       := replace (vSqlEstagio,vTratar,
                                 ' AND bol.cdrelacaotrabalho = ' || PKGPAG_TIPO.cnRelResidente);
      ELSIF pCdTipoFolha in (PKGPAG_TIPO.cnTpFolhaPesquisador, pkgpag_tipo.cnTpFolhaRescisaoPesquisador,PKGPAG_TIPO.cnTpFolhaConvenio) THEN
          vSqlEstagio       := replace (vSqlEstagio,vTratar,
                                 ' AND bol.cdrelacaotrabalho = ' || PKGPAG_TIPO.cnRelPesquisador);
       ELSIF pCdRelacaoTrabalho IS NOT NULL THEN -- Se existe filtro por Relac?o de Trabalho
          vSqlEstagio       := replace (vSqlEstagio,vTratar,
                                 ' AND bol.cdrelacaotrabalho = ' || pCdRelacaoTrabalho);
      ELSE
        vSqlEstagio := replace(vSqlEstagio, vTratar, '');
      END IF;

      /**************
      -- Tratamento de Parametros Unitarios
      **************/

      --
      vTratar := '[COLVINCULORELACAO]';
      --

      vSql13Salario        := replace(vSql13Salario, vTratar, 'CdVinculo');
      vSqlEfetivo          := replace(vSqlEfetivo, vTratar, 'CdVinculo');
       vSqlComissionado := replace (vSqlComissionado,vTratar,'CdVinculo');
       vSqlComissionadoPuro := replace (vSqlComissionadoPuro,vTratar,'CdVinculo');
       vSqlEstagio      := replace (vSqlEstagio,vTratar,'CdVinculoEstagio');
       vSqlFuncaoChefia := replace (vSqlFuncaoChefia,vTratar,'CdVinculo');
      vSqlPensaoPrev       := replace(vSqlPensaoPrev, vTratar, 'CdVinculo');
       vSqlPensaoNaoPrev:= replace (vSqlPensaoNaoPrev,vTratar,'CdVinculoBeneficiario');
      vSqlAuxReclusao      := replace(vSqlAuxReclusao, vTratar, 'CdVinculo');
       vSqlExParlamentar:= replace (vSqlExParlamentar,vTratar,'CdVinculo');
       vSqlAposentadoria:= replace (vSqlAposentadoria,vTratar,'CdVinculo');
      vSqlLancFinanc       := replace(vSqlLancFinanc, vTratar, 'CdVinculo');
      vSqlDesligados       := replace(vSqlDesligados, vTratar, 'CdVinculo');
      vSqlDifAPagar        := replace(vSqlDifAPagar, vTratar, 'CdVinculo');

      --
      vTratar := '[COLCDORGAO]';
      --

       vSql13Salario    := replace (vSql13Salario,vTratar,'vinor.cdOrgao');
       vSqlEfetivo      := replace (vSqlEfetivo,vTratar,'cef.cdorgaoexercicio');
       vSqlComissionado := replace (vSqlComissionado,vTratar,'cco.cdorgaoexercicio');
       vSqlComissionadoPuro := replace (vSqlComissionadoPuro,vTratar,'cco.cdorgaoexercicio');
      vSqlEstagio          := replace(vSqlEstagio, vTratar, 'v.cdorgao');
       vSqlFuncaoChefia := replace (vSqlFuncaoChefia,vTratar,'v.cdorgao');
      vSqlPensaoPrev       := replace(vSqlPensaoPrev, vTratar, 'v.cdorgao');
       vSqlPensaoNaoPrev:= replace (vSqlPensaoNaoPrev,vTratar,'v.cdorgao');
      vSqlAuxReclusao      := replace(vSqlAuxReclusao, vTratar, 'v.cdorgao');
       vSqlExParlamentar:= replace (vSqlExParlamentar,vTratar,'v.cdorgao');
       vSqlAposentadoria:= replace (vSqlAposentadoria,vTratar,'v.cdorgao');
      vSqlLancFinanc       := replace(vSqlLancFinanc, vTratar, 'v.cdorgao');
      vSqlDesligados       := replace(vSqlDesligados, vTratar, 'v.cdorgao');
      vSqlDifAPagar        := replace(vSqlDifAPagar, vTratar, 'v.cdorgao');

      --
      vTratar := '[SGRELACAO]';
      --
      vSqlEfetivo          := replace(vSqlEfetivo, vTratar, 'cef');
      vSqlComissionado     := replace(vSqlComissionado, vTratar, 'cco');
      vSqlComissionadoPuro := replace(vSqlComissionadoPuro, vTratar, 'cco');
      vSqlEstagio          := replace(vSqlEstagio, vTratar, 'bol');
      vSqlFuncaoChefia     := replace(vSqlFuncaoChefia, vTratar, 'fuc');
      vSqlPensaoPrev       := replace(vSqlPensaoPrev, vTratar, 'pp');
      vSqlPensaoNaoPrev    := replace(vSqlPensaoNaoPrev, vTratar, 'pnp');
      vSqlAuxReclusao      := replace(vSqlAuxReclusao, vTratar, 'ar');
      vSqlExParlamentar    := replace(vSqlExParlamentar, vTratar, 'pep');
      vSqlAposentadoria    := replace(vSqlAposentadoria, vTratar, 'ap');

      --
      vTratar := '[CDTIPORELACAO]';
      --

      vSql13Salario        := replace(vSql13Salario, vTratar, cnTpDecTer);
      vSqlEfetivo          := replace(vSqlEfetivo, vTratar, cnTpEfetivo);
       vSqlComissionado   := replace (vSqlComissionado,   vTratar, cnTpComissionado);
       vSqlComissionadoPuro := replace (vSqlComissionadoPuro,  vTratar, cnTpComissionado);
      vSqlEstagio          := replace(vSqlEstagio, vTratar, cnTpEstagio);
       vSqlFuncaoChefia   := replace (vSqlFuncaoChefia,   vTratar, cnTpFuncaoChefia);
       vSqlPensaoPrev     := replace (vSqlPensaoPrev,     vTratar, cnTpPensaoPrev);
       vSqlPensaoNaoPrev  := replace (vSqlPensaoNaoPrev,  vTratar, cnTpPensaoNaoPrev);
       vSqlAuxReclusao    := replace (vSqlAuxReclusao,    vTratar, cnTpAuxReclusao);
       vSqlExParlamentar  := replace (vSqlExParlamentar,  vTratar, cnTpExParlamentar);
       vSqlAposentadoria  := replace (vSqlAposentadoria,  vTratar, cnTpAposentadoria);
       vSqlLancFinanc     := replace (vSqlLancFinanc,     vTratar, cnTpLancFinanc);
       vSqlDesligados     := replace (vSqlDesligados,     vTratar, cnTpDesligados);
      vSqlDifAPagar        := replace(vSqlDifAPagar, vTratar, cnTpDifMes);

      PTrocaTudo('[CDFOLHAPAGAMENTO]', vFol(fp).CdFolhaPagamento);
      PTrocaTudo('[DEORDEMEXECUCAO]', vFol(fp).DeOrdemExecucao);
      PTrocaTudo('[CDTIPOFOLHAPAGAMENTO]', vFol(fp).CdTipoFolhaPagamento);
      PTrocaTudo('[CDCALCULO]', pCalculo.CdCalculo);
     
      PTrocaTudo('[CDORGAO]', vFol(fp).CdOrgao);

      IF pChecagem = 0 THEN

         vLstPessoa.DELETE;

         PKGPAG_GERAL.PLogProcIni ('PRE0101','RelVinc 13 Salario');
         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSql13Salario,vLstPessoa);

         PKGPAG_GERAL.PLogProc ('PRE0101','PRE0102','RelVinc Efetivo');                 
         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlEfetivo,vLstPessoa);
         
         PKGPAG_GERAL.PLogProc ('PRE0102','PRE0103','RelVinc Comissionado');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlComissionado,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0103','PRE0104','RelVinc Comissionado Puro');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlComissionadoPuro,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0104','PRE0105','RelVinc Funcao Chefia');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlFuncaoChefia,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0105','PRE0106','RelVinc Aposentadoria');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlAposentadoria,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0106','PRE0107','RelVinc Estagio');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlEstagio,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0107','PRE0108','RelVinc Pensao Prev');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlPensaoPrev,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0108','PRE0109','RelVinc Pensao Nao Prev');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlPensaoNaoPrev,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0109','PRE0110','RelVinc Ex Parlamentar');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlExParlamentar,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0110','PRE0111','RelVinc Aux Reclusao');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlAuxReclusao,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0111','PRE0112','RelVinc Lanc Financ');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlLancFinanc,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0112','PRE0113','RelVinc Desligados');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlDesligados,vLstPessoa);
         PKGPAG_GERAL.PLogProc ('PRE0113','PRE0114','RelVinc Dif a Pagar');

         PInserirRelVincFolha(pCalculo.InTipoExecucao,vSqlDifAPagar,vLstPessoa);
   
         PKGPAG_GERAL.PLogProcFim ('PRE0114');
         
         IF pCalculo.InTipoExecucao = 1 THEN -- Apenas Contar

            PKGPAG_GERAL.PLogProcIni ('PRE0115', 'Atualizar Contadores Orgao');
         
            PAtualizarContadoresOrgao (pCalculo    => pCalculo,
                                       pCdOrgao    => vFol(fp).CdOrgao,
                                       pQtdePessoa => vLstPessoa.COUNT);
           
            PKGPAG_GERAL.PLogProcFim ('PRE0115');                          
                                       
         END IF;


      ELSE

        PChecarSintaxe(vSql13Salario);
        PChecarSintaxe(vSqlEfetivo);
        PChecarSintaxe(vSqlComissionado);
        PChecarSintaxe(vSqlComissionadoPuro);
        PChecarSintaxe(vSqlFuncaoChefia);
        PChecarSintaxe(vSqlAposentadoria);
        PChecarSintaxe(vSqlEstagio);
        PChecarSintaxe(vSqlPensaoPrev);
        PChecarSintaxe(vSqlPensaoNaoPrev);
        PChecarSintaxe(vSqlExParlamentar);
        PChecarSintaxe(vSqlAuxReclusao);
        PChecarSintaxe(vSqlLancFinanc);
        PChecarSintaxe(vSqlDesligados);
        PChecarSintaxe(vSqlDifAPagar);

      END IF;

    END LOOP;

    -- Testa consolidacão

    IF pCalculo.InTipoExecucao = 2 THEN -- Calcular, não apenas contar

       -- Marcar valores default

       PKGPAG_GERAL.PLogProcIni ('PRE0117', 'Atualizar valores default');   
            
       update ecalvincfolha v
          set flCalcular = cnFlCalcSim, -- Calcular
              FlObito    = 0
        where CdCalculo = pCalculo.CdCalculo;

       PKGPAG_GERAL.PLogProcFim ('PRE0117');

       IF NOT pCdTipoFolha in ( PKGPAG_TIPO.cnTpFolha13
                              , PKGPAG_TIPO.cnTpFolhaAdiant13
                              , PKGPAG_TIPO.cnTpFolhaResidente13
                              , pkgpag_tipo.cnTpFolhaCtisp13
                              , pkgpag_tipo.cnTpFolhaAdiant13Ctisp
                              , pkgpag_tipo.cnTpFolhaProdex13
                              , pkgpag_tipo.cnTpFolhaHonorarios13
                              , pkgpag_tipo.cnTpFolhaHonorarProcuradores13
                              )  THEN -- Executar a folha, portanto, consolidar informac?es

         PConsolidarRelVinFolha(pCdCalculo           => pCalculo.CdCalculo,
                                pNuMesCompetencia    => pNuMesCompetencia,
                                pNuAnoCompetencia    => pNuAnoCompetencia,
                                pDtCompetenciaIni    => vDtCompetenciaIni,
                                pDtCompetenciaFim    => vDtCompetenciaFim,
                                pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                pCdTipoCalculo       => pCdTipoCalculo,
                                pDtCalculo           => pDtCalculo,
                                pCdTipoFolhaPagamento => pCdTipoFolhaPagamento);

      END IF;
    END IF;
    
    PKGPAG_GERAL.PLogProcFim ('PRE01');

  end;

FUNCTION FRetornarSqlPDI(pCdOrgao              IN INTEGER,
                         pCdTipoFolha          IN INTEGER,
                         pCdTipoFolhaPagamento IN INTEGER) RETURN VARCHAR2 IS
  vSql VARCHAR2 (1000) := '';
BEGIN

  IF PKGPAG_GERAL.FOrgaoUtilizaFolhaPDI(pCdOrgao) THEN
    IF pCdTipoFolha IN (pkgpag_tipo.cnTpFolhaOutras, PKGPAG_TIPO.cnTpFolhaBEP)
       or (pCdTipoFolha = pkgpag_tipo.cnTpFolhaRescisao and pCdOrgao in (3, 7, 25, 26, 27, 37, 723) and pCdTipoFolhaPagamento not in (925, 1205, 1045, 731, 609))
    THEN
      vSql := vSql || ' AND v.cdvinculo IN ';
    ELSE
      vSql := vSql || ' AND v.cdvinculo NOT IN ';
    END IF;
    vSql := vSql ||
    '(SELECT vin.cdvinculo ' ||
    '  FROM eafaafastamentovinculo avi ' ||
    ' INNER JOIN ecadvinculo vin ' ||
    '    ON avi.cdvinculo = vin.cdvinculo ' ||
    ' WHERE vin.cdorgao = ' || pCdOrgao ||
    '   AND avi.flAnulado = ''N'' ' ||
    '   AND cdmotivoafastdefinitivo IN ' ||
    '       (SELECT cdmotivoafastdefinitivo ' ||
    '          FROM eafamotivoafastdefinitivo ' ||
    '        WHERE cdtipoafastamento = 3))';
  END IF;
  RETURN vSql;
END;

FUNCTION FEhFolhaProdexPGE(pCdTipoFolhaPagamento IN INTEGER) RETURN BOOLEAN IS
BEGIN  
  RETURN pCdTipoFolhaPagamento IN (1505, 1525, 1526, 1766);
END;  

END PKGPAG_PRE;
/
