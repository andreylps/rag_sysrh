create or replace package PKGCMP is

  -- Author  : MLACERDA
  -- Created : 04/09/2025 07:58:28
  -- Purpose : Comparativo de folhas
 
PROCEDURE PGerarDuploVinculo (pNmCmp IN VARCHAR2, pNuAnoMesReferencia IN INTEGER);

PROCEDURE PGerarResumo (pNmCmp IN VARCHAR2, pCdVinculo IN INTEGER DEFAULT NULL);

PROCEDURE PAtualizarAcertoLF (pNmCmp IN VARCHAR2);

PROCEDURE PCriarHistParamCalculo (pFlCalculoNovo IN INTEGER);

PROCEDURE PCriarCmpHistParamCalc (pNuAno IN INTEGEr, pNuMes IN INTEGER);

PROCEDURE PReagendarProxima (pCdTarefa IN INTEGER);

PROCEDURE PExecutaProcCFAgendador (pCdTarefa IN INTEGER);

PROCEDURE PLimparFolhaPagamento (pCdFolhaPagamento IN INTEGER);


PROCEDURE PImprimirCC (pCdFolhaPagamento IN INTEGER, pCdVinculo IN INTEGER,
   pOmitirIndINSS INTEGER DEFAULT 0);
/*

-- DROP table ecmpresumo;

create table ecmpresumo
(
  nmcmp                    VARCHAR2(50) not null,
  cdagrupamento            INTEGER,
  CdTipoFolha              INTEGER,
  CdTipoFolhaPagamento     INTEGER,
  cdorgao                  INTEGER,
  cdvinculo                INTEGER not null,
  cdpessoa                 NUMBER,
  NuSeqFolhaComum          INTEGER,
  flduplovinculo           NUMBER,
  nmrubrica                VARCHAR2(100),
  tprubrica                CHAR(1),
  rubrica                  VARCHAR2(7),
  matr                     VARCHAR2(12),
  nmpessoa                 VARCHAR2(90),
  indice_origem            NUMBER,
  vl_origem                NUMBER,
  indice_teste             NUMBER,
  vl_teste                 NUMBER,
  vl_dif                   NUMBER,
  tem_teste                NUMBER,
  tem_origem               NUMBER,
  pago                     VARCHAR2(11),
  tem_dif                  NUMBER,
  tem_dif_tolerancia       NUMBER,
  numatricula              VARCHAR2(7),
  nudvmatricula            CHAR(1),
  nuseqmatricula           NUMBER,
  cdhrubricavinculo_origem NUMBER,
  cdhrubricavinculo_teste  NUMBER,
  cdlancfinanceiro_origem  NUMBER,
  cdlancfinanceiro_teste   NUMBER,  
  DEORDEMEXECUCAO_ORIGEM   VARCHAR2(10),
  DEORDEMEXECUCAO_TESTE    VARCHAR2(10),


  CDTIPOFOLHAPAG_ORIGEM    INTEGER,
  CDTIPOFOLHAPAG_TESTE     INTEGER,
  CDTIPOCALCULO_ORIGEM     INTEGER,
  CDTIPOCALCULO_TESTE      INTEGER,
                      
  cdrubricaagrupamento     INTEGER not null,
  nusufixorubrica          NUMBER(2) not null,
  cdFolhaOrigem            INTEGER,
  cdFolhaTeste             INTEGER
);

--create bitmap index tmpxID01CMP on ecmpresumo (nmCmp); 
--create bitmap index tmpxID02CMP on ecmpresumo (tem_dif);
--create index tmpxID03CMP on ecmpresumo (rubrica);
--create index tmpxID04CMP on ecmpresumo (cdpessoa);
--create index tmpxID05CMP on ecmpresumo (cdvinculo);

drop table ecmpresumoant;
create table ecmpresumoant as select * from ecmpresumo where 0=1;


-- drop table ECMPPARAM;
create table ECMPPARAM
(
  nmcmp                VARCHAR2(50) not null,
  cdorgao              INTEGER not null,
  cdtipofolhapagorigem INTEGER not null,
  cdtipofolhapagteste  INTEGER not null,
  cdtipocalculoorigem  INTEGER not null,
  cdtipocalculoteste   INTEGER not null,
  nuanomesreforigem    NUMBER(6) not null,
  nuanomesrefteste     NUMBER(6) not null,
  vldiferenca          NUMBER not null,
  nusequencialorigem   NUMBER(3),
  nusequencialteste    NUMBER(3)
);

-- drop table eCmpDuploVinc;
create table eCmpDuploVinc
(nmCmp   VARCHAR2(50),
 cdpessoa INTEGER not null,
 qtde     NUMBER);

create index INDXTMPDUPVINC on eCmpDuploVinc (NmCmp,CDPESSOA);

-- drop table ecmpAcertoRubrica;
create table ecmpAcertoRubrica
   (nmCmp                  VARCHAR2(50),
    CdOrgao                integer,
    CdVinculo              integer,
    CdRubricaAgrupamento   integer,
    NuSufixoRubrica        integer,
    DeMotivo               varchar2(200),
    vlindice               NUMBER(10,4),
    vllancamentofinanceiro NUMBER(11,2),    
    cdlancamentofinanceiro INTEGER,
    cdLancamentoAnterior   INTEGER,  
    flVigente              char(1) default 'S',
    FlCalculo              char(1) default 'S'
);

create unique index ukcmpacerto on ecmpACERTORUBRICA ( nmCmp, cdvinculo,cdrubricaagrupamento,nusufixorubrica);

create table ECMPHISTPARAMCALC
(
  nuordem              NUMBER,
  cdagrupamento        INTEGER not null,
  cdtipocalculo        INTEGER not null,
  cdtipofolhapagamento INTEGER,
  numescompetencia     NUMBER(2) not null,
  nuanocompetencia     NUMBER(4) not null,
  nusequencialfolha    INTEGER,
  dtcalculo            DATE not null,
  dtprevistacredito    DATE,
  orgaos               VARCHAR2(4000)
);

*/

/*
--- Criar parametrização

DELETE ECMPPARAM;
INSERT INTO ECMPPARAM
selecT 
  'NORMAL' nmCmp,
  CdOrgao,
  MAX(DECODE (CdTipoCalculo,2,CdTipoFolhaPagamento,0)) as cdtipofolhapagorigem,
  MAX(DECODE (CdTipoCalculo,1,CdTipoFolhaPagamento,0)) as cdtipofolhapagteste,
  MAX(DECODE (CdTipoCalculo,2,CdTipoCalculo,0)) as cdtipocalculoorigem,
  MAX(DECODE (CdTipoCalculo,1,CdTipoCalculo,0)) as cdtipocalculoteste,
  MAX(DECODE (CdTipoCalculo,2,NuAnoMesReferencia,0)) as nuanomesreforigem,
  MAX(DECODE (CdTipoCalculo,1,NuAnoMesReferencia,0)) as nuanomesrefteste,
  0.01 vldiferenca,
  MAX(DECODE (CdTipoCalculo,2,NuSequencialFolha,0)) as nusequencialorigem,
  MAX(DECODE (CdTipoCalculo,1,NuSequencialFolha,0)) as nusequencialteste
 
  from epagfolhapagamento
 where nuanomesreferencia = 202505
   and cdtipocalculo in (1,2)
  and cdtipofolhapagamento = 2
  GROUP BY CdOrgao;
*/

/* Reagendar automatico de execucoes

-- Mudar a tarefa

UPDATE eadmtipotarefa 
   SET DeClasse = case when instr(DeClasse,'PKGPAG') > 0 THEN 'PKGCMP' ELSE 'PKGPAG' END || '.PExecutaProcCFAgendador' 
 where cdtipotarefa = 6;
 

*/

end PKGCMP;
/
create or replace package body PKGCMP is

CROT_CALCULO_ANTIGO   CONSTANT VARCHAR2(11) := '11111111111';
CROT_CALCULO_NOVO     CONSTANT VARCHAR2(11) := '22222222222';
 
PROCEDURE PImprimirCC (pCdFolhaPagamento IN INTEGER, pCdVinculo IN INTEGER,
   pOmitirIndINSS INTEGER DEFAULT 0) IS 
begin

   DBMS_OUTPUT.PUT_LINE (' RUBRICA   DESCRICAO                                  INDICE      VALOR    CDRUBAGRUP   LANC FINANC   DT ULT ALTERACAO');
     
   FOR rec in (select r.nurubricafmt || '-' || lpad ( nusufixorubrica,2,'0') as Rubrica, r.derubricaagrupamentofmt as descricao, vlindicerubrica, vlpagamento, h.cdrubricaagrupamento, h.cdlancamentofinanceiro, H.DTULTALTERACAO,r.nurubricafmt, h.deexpressao
                 from epaghistoricorubricavinculo h
                inner join vpagrubricaagrupamento r
                   on r.cdrubricaagrupamento = h.cdrubricaagrupamento
                where cdVinculo = pCdVinculo and cdFolhaPagamento = pCdFolhaPagamento order by r.cdtiporubrica,r.nurubrica,h.nusufixorubrica) LOOP
                   

       DBMS_OUTPUT.PUT_LINE (rec.Rubrica || ' ' ||
                             rpad (rec.Descricao,35,' ') || ' ' ||
                             lpad (case
                                      when pOmitirIndINSS = 1 AND rec.NuRubricafmt IN ('05-0512','05-0516','05-0216') then
                                           ' '
                                      else nvl(to_char(rec.vlindicerubrica), ' ')
                                   end       
                                  ,10,' ') || ' ' ||
                             lpad (rec.vlpagamento,13,' ') || '    ' ||
                             lpad (rec.cdrubricaagrupamento,10,' ') || '       ' || 
                             rec.cdlancamentofinanceiro
                             || '  ' 
                       --      ||  TO_CHAR (REC.DTULTALTERACAO,'DD/MM/YYYY HH24:MI:SS')                             
                             );
                   
   END LOOP;
END;

PROCEDURE PGerarDuploVinculo  (pNmCmp IN VARCHAR2, pNuAnoMesReferencia IN INTEGER) IS
   
BEGIN
   DELETE eCmpDuploVinc WHERE NmCmp = pNmCmp;

   INSERT INTO eCmpDuploVinc      
      select pNmCmp as nmcmp, cdpessoa, COUNT (*) as QTDE
      from (SELECT DISTINCT CDPESSOA, HRV.CDVINCULO 
              FROM EPAGHISTORICORUBRICAVINCULO hrv
             INNER JOIN ECADVINCULO V
                ON HRV.CdVinculo = V.CdVinculo
             INNER JOIN EPAGFOLHAPAGAMENTO FP
                ON FP.CdFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
             WHERE FP.NUANOMESREFERENCIA = pNuAnoMesReferencia 
               AND fp.cdTipoCalculo NOT IN (7,8,9,10,11)  
            )
      group by cdpessoa     
      having COUNT (*) > 1      
      ;  

END;


PROCEDURE PGerarResumo (pNmCmp IN VARCHAR2, pCdVinculo IN INTEGER DEFAULT NULL) IS
   
BEGIN

   IF pCdVinculo IS NOT NULL THEN
      DELETE eCmpResumo WHERE NmCmp = pNmCmp AND CdVinculo = pCdVinculo;  
   ELSE

      DELETE eCmpResumoAnt WHERE NmCmp = pNmCmp;  
            
      INSERT INTO eCmpResumoAnt 
         SELECT * FROM  eCmpResumo WHERE NmCmp = pNmCmp; 
         
      DELETE eCmpResumo WHERE NmCmp = pNmCmp;  
           
   END IF;

   
   INSERT INTO eCmpResumo
   
      with visao as (
             SELECT 
                     NmCmp,
                     MAX(Cdagrupamento) as CdAgrupamento,
                     MAX(CdTipoFolha) as CdTipoFolha,
                     MAX(CDTIPOFOLHAPAGAMENTO) AS CdTipoFolhaPagamento,
                     CdOrgao,
                     CdVinculo,
                     MAX(CdPessoa) as cdPessoa,
                     NuSeqFolhaComum,
                     MAX(FlDuploVinculo) as FlDuploVinculo,
                     MAX(NuRubricaFMT || '-' || NuSufixoRubrica || ' - ' || DescricaoRubrica) as NmRubrica,
                     MAX(TPRUBRICA) as TpRubrica,
                     MAX(NuRubricaFMT) as Rubrica,
                     MAX(Matr) AS Matr,
                     MAX(NmPessoa) as NmPessoa,
                     SUM(INDICE_ORIGEM) AS INDICE_ORIGEM,
                     SUM(VL_ORIGEM) as VL_ORIGEM,
                     SUM(INDICE_TESTE) AS INDICE_TESTE,
                     SUM(VL_TESTE) as VL_TESTE,             
                     SUM(VL_TESTE) - SUM(VL_ORIGEM) AS VL_DIF,
                     SUM (TEM_TESTE) AS TEM_TESTE,
                     SUM (TEM_ORIGEM) AS TEM_ORIGEM,
                     CASE
                        WHEN SUM (TEM_TESTE) > 0 AND SUM (TEM_ORIGEM) > 0 THEN
                          'AMBOS'
                        WHEN  SUM (TEM_TESTE) > 0 THEN
                          'SÓ TESTE'
                        ELSE
                          'SÓ ORIGINAL'
                     END AS PAGO,     

                     CASE
                       WHEN Abs( SUM(VL_TESTE) - SUM(VL_ORIGEM)) > 0 THEN
                         1
                       ELSE
                         0
                     END as TEM_DIF,
                                 
                     CASE
                       WHEN Abs( SUM(VL_TESTE) - SUM(VL_ORIGEM)) > MAX (VLDIFERENCA) THEN
                         1
                       ELSE
                         0
                     END as TEM_DIF_TOLERANCIA,
                     MAX(NuMatricula) as NuMatricula,
                     MAX(NuDvMatricula) as NuDvMatricula,
                     MAX(NuSeqMatricula) as NuSeqMatricula,
                     MAX (CDHRUBRICAVINCULO_ORIGEM) AS CDHRUBRICAVINCULO_ORIGEM,
                     MAX (CDHRUBRICAVINCULO_TESTE) AS CDHRUBRICAVINCULO_TESTE,
                     MAX (CDLANCFINANCEIRO_ORIGEM) AS CDLANCFINANCEIRO_ORIGEM,
                     MAX (CDLANCFINANCEIRO_TESTE) AS CDLANCFINANCEIRO_TESTE,    

                     MAX (DEORDEMEXECUCAO_ORIGEM) AS DEORDEMEXECUCAO_ORIGEM,
                     MAX (DEORDEMEXECUCAO_TESTE) AS DEORDEMEXECUCAO_TESTE,

                     MAX(CDTIPOFOLHAPAG_ORIGEM) AS CDTIPOFOLHAPAG_ORIGEM,
                     MAX(CDTIPOFOLHAPAG_TESTE)  AS CDTIPOFOLHAPAG_TESTE,
                             
                     MAX(CDTIPOCALCULO_ORIGEM) AS CDTIPOCALCULO_ORIGEM,
                     MAX(CDTIPOCALCULO_TESTE) AS CDTIPOCALCULO_TESTE,
                                                  
                     CdRubricaAgrupamento,
                     NuSufixoRubrica,                    
                     MAX (CdFolhaOrigem) AS CDFolhaOrigem,
                     MAX (CdFolhaTeste) AS CdFolhaTeste
                     
                FROM (
                
                         SELECT 
                             FP.NmCmp,
                             FP.CdAgrupamento,
                             FP.CdTipoFolha,
                             FP.CDTIPOFOLHAPAGAMENTO AS CDTIPOFOLHAPAGAMENTO,                             
                             FP.CdOrgao,           
                             cada39.cdpessoa,  
                             NuSeqFolhaComum,
                             decode (dv.cdpessoa,null,0,1) as flDuploVinculo,    
                             FP.DeOrdemExecucao,     
                             PAGA20.CdRubricaAgrupamento,
                             CADA39.CdVinculo,
                             lpad(CADA39.NuMatricula, 7, '0') || '-' ||
                             CADA39.NuDVMatricula || '-' ||
                             lpad(CADA39.NuSeqMatricula, 2, '0') AS Matr,
                             NuMatricula,
                             NuDvMatricula,
                             NuSeqMatricula,
                             CADAA1.NmPessoa,
                             PAGA34.NURUBRICAFMT,
                             LPAD(PAGA20.NuSufixoRubrica, 2, '0') AS NUSUFIXORUBRICA,                            
                             PAGA34.DETIPORUBRICAPDT as TPRUBRICA,
                             PAGA34.DERUBRICAAGRUPAMENTOFMT  AS DESCRICAORUBRICA,
                             
                             Decode (FP.TIPO,'O',PAGA20.VlIndiceRubrica,0) AS INDICE_ORIGEM,
                             Decode (FP.TIPO,'O',PAGA20.VlPagamento,0) AS VL_ORIGEM,
                             Decode (FP.TIPO,'T',PAGA20.VlIndiceRubrica,0) AS INDICE_TESTE,
                             Decode (FP.TIPO,'T',PAGA20.VlPagamento,0) AS VL_TESTE,
                             Decode (FP.Tipo,'O',1,0) AS TEM_ORIGEM,
                             Decode (FP.Tipo,'T',1,0) AS TEM_TESTE,

                             Decode (FP.Tipo,'O',DEORDEMEXECUCAO,NULL) AS DEORDEMEXECUCAO_ORIGEM,
                             Decode (FP.Tipo,'T',DEORDEMEXECUCAO,NULL) AS DEORDEMEXECUCAO_TESTE,
                             
                             Decode (FP.Tipo,'O',NUSEQUENCIALFOLHA,NULL) AS NUSEQ_ORIGEM,
                             Decode (FP.Tipo,'T',NUSEQUENCIALFOLHA,NULL) AS NUSEQ_TESTE,
                             
                             Decode (FP.TIPO,'O',PAGA20.CDHISTORICORUBRICAVINCULO,0) AS CDHRUBRICAVINCULO_ORIGEM,
                             Decode (FP.TIPO,'T',PAGA20.CDHISTORICORUBRICAVINCULO,0) AS CDHRUBRICAVINCULO_TESTE,
                             Decode (FP.TIPO,'O',NVL(PAGA20.CDLANCAMENTOFINANCEIRO,0),0) AS CDLANCFINANCEIRO_ORIGEM,
                             Decode (FP.TIPO,'T',NVL(PAGA20.CDLANCAMENTOFINANCEIRO,0),0) AS CDLANCFINANCEIRO_TESTE,

                             Decode (FP.TIPO,'O',FP.CDTIPOFOLHAPAGAMENTO,0) AS CDTIPOFOLHAPAG_ORIGEM,
                             Decode (FP.TIPO,'T',FP.CDTIPOFOLHAPAGAMENTO,0) AS CDTIPOFOLHAPAG_TESTE,
                             
                             Decode (FP.TIPO,'O',FP.CDTIPOCALCULO,0) AS CDTIPOCALCULO_ORIGEM,
                             Decode (FP.TIPO,'T',FP.CDTIPOCALCULO,0) AS CDTIPOCALCULO_TESTE,
                                                          
                             Decode (FP.TIPO,'O',PAGA20.CdFolhaPagamento,0) AS CdFolhaOrigem,
                             Decode (FP.TIPO,'T',PAGA20.CdFolhaPAgamento,0) AS CdFolhaTeste,       
                             FP.VLDIFERENCA
                             
                             
                        FROM EPAGHISTORICORUBRICAVINCULO PAGA20
                       INNER JOIN ECADVINCULO CADA39
                          ON PAGA20.CdVinculo = CADA39.CdVinculo
                       INNER JOIN ECADPESSOA CADAA1
                          ON CADA39.CdPessoa = CADAA1.CdPessoa

                       INNER JOIN VPAGRUBRICAAGRUPAMENTO PAGA34
                          ON PAGA20.CdRubricaAgrupamento =
                             PAGA34.CdRubricaAgrupamento
                                              
                       LEFT JOIN eCmpDuploVinc DV
                         ON DV.NmCmp = pNmCmp
                        AND dv.CdPessoa = CADAA1.CdPessoa      
                             
                       INNER JOIN ( SELECT 
                                         PARM.NmCmp,
                                         FP.CdAgrupamento,
                                         FP.CdOrgao,
                                         TFP.CdTipoFolha,
                                         CdFolhaPagamento,
                                         PARM.VLDIFERENCA,
                                         FP.DeOrdemExecucao,
                                         FP.CdTipoFolhaPagamento,
                                         FP.CdTipoCalculo,
                                         FP.NuSequencialFolha,
                                         
                                         CASE  
                                         WHEN (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefOrigem
                                                 AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagOrigem
                                                 AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOOrigem 
                                                 AND ( FP.Nusequencialfolha = PARM.Nusequencialorigem OR  PARM.Nusequencialorigem IS NULL)                                          
                                               ) THEN
                                              PARM.Nusequencialteste
                                         ELSE
                                              FP.NuSequencialFolha
                                         END as NuSeqFolhaComum,
                                         
                                         CASE  
                                         WHEN (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefOrigem
                                                 AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagOrigem
                                                 AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOOrigem 
                                                 AND ( FP.Nusequencialfolha = PARM.Nusequencialorigem OR  PARM.Nusequencialorigem IS NULL)                                          
                                               ) THEN
                                              'O'
                                         ELSE
                                              'T'
                                         END as Tipo
                                      
                                       FROM ECmpParam PARM
                                       
                                       INNER JOIN EPAGFOLHAPAGAMENTO FP
                                          ON  ( (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefOrigem
                                                 AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagOrigem
                                                 AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOOrigem 
                                                 AND ( FP.CdOrgao = PARM.cdOrgao OR PARM.CdOrgao IS NULL)
                                                 AND ( FP.Nusequencialfolha = PARM.Nusequencialorigem OR  PARM.Nusequencialorigem IS NULL)
                                                ) OR
                                                (    FP.NuAnoMesReferencia = PARM.NUANOMESREFTeste
                                                 AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagTeste
                                                 AND FP.cdTipoCalculo = PARM.CdtipocalculoTeste
                                                 AND ( FP.CdOrgao = PARM.cdOrgao OR PARM.CdOrgao IS NULL)
                                                 AND ( FP.Nusequencialfolha = PARM.NusequencialTeste OR  PARM.NusequencialTeste IS NULL)
                                                )
                                              )
                                       INNER JOIN EPAGTIPOFOLHAPAGAMENTO tfp
                                          ON tfp.cdTipoFolhaPAgamento = FP.cdTipoFolhaPagamento       
                                              
                                       
                                       WHERE Parm.NmCmp = pNmCmp
                                  ) FP
                                  
                          ON FP.CdFolhaPagamento = PAGA20.CdFolhaPagamento
                          
                       WHERE (pCdVinculo IS NULL OR pCdVinculo = PAGA20.CdVinculo)
                       
                     )
                         
               GROUP BY NmCmp,
                        CdOrgao,
                        CdVinculo,
                        CdTipoFolhaPagamento,
                        NuSeqFolhaComum,
                        CdRubricaAgrupamento,
                        NuSufixoRubrica
             
      -- ORDER BY NmCmp,CdOrgao,Matr,Rubrica
      )
       select * from visao;

END;


PROCEDURE PIncluirAcertoLF (pNmCmp IN VARCHAR2) IS

  rLF EPAGLANCAMENTOFINANCEIRO%ROWTYPE;
  vCdOrgao               INTEGER;
  vCdFolhaPagamento      INTEGER;
  vContador              INTEGER;
  vAnoMes                INTEGER;
  vAnulados              INTEGER;
  vCdLancamentoAnterior  INTEGER;
  
BEGIN

   vCdOrgao  := 0;
   vContador := 0;
   vAnulados := 0;
   for rec in (
              SELECT l.*, rowid as rid
                FROM ECMPACERTORUBRICA L
               WHERE nmCmp = pNmCmp
                 AND FlCalculo = 'S'
                 AND FlVigente = 'S'
                 AND CdLancamentoFinanceiro IS NULL
               ORDER BY CDORGAO
               
               ) loop
     
      IF rec.CdOrgao <> vCdOrgao THEN      
         vCdOrgao  := rec.CdOrgao;
       
       
        select fp.NuAnoMesReferencia, fp.CdFolhaPagamento 
          INTO vAnoMes, vCdFolhaPagamento
          from Ecmpparam p
         INNER JOIN EPagFolhaPagamento FP 
            ON Fp.NuAnoMesReferencia = p.Nuanomesreforigem
           AND fp.cdOrgao = p.Cdorgao
           AND FP.Cdtipofolhapagamento = p.Cdtipofolhapagorigem
           AND fp.CdTipoCalculo = p.Cdtipocalculoorigem
           AND fp.NuSequencialFolha = p.NuSequencialorigem              
         WHERE p.NmCmp = pNmCmp
           AND p.CdOrgao = vCdOrgao;
         
      END IF;

      BEGIN
      
         select VLPAGAMENTO,VLINDICERUBRICA
           INTO rLF.vllancamentofinanceiro, rLF.vlindice 
           from epaghistoricorubricavinculo 
          where cdvinculo =  REC.CDVINCULO
            and cdfolhapagamento= VcDfOLHApAGAMENTO
            AND CDRUBRICAAGRUPAMENTO = rec.cdrubricaagrupamento
            AND NUSUFIXORUBRICA = rec.nusufixorubrica;
             
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
               rLF.vllancamentofinanceiro := 0;
               rLF.vlindice               := 0;          
          
      END;
       
      vContador := vContador + 1;
    
      rLF.cdrubricaagrupamento  := rec.cdRubricaAgrupamento;
      rLF.cdvinculo             := rec.CdVinculo;
      rLF.nusufixorubrica       := rec.NuSufixoRubrica;
         
      rLF.dtiniciodireito       := to_date (vAnoMes,'YYYYMM');
      rLF.dtfimdireito          := LAST_DAY (to_date (vAnoMes,'YYYYMM') );

      rLF.nucpfcadastrador      := '41414141411';
      rLF.inperiodicidade       := 'P';
      rLF.FLPROPDEMITIDONOMES   := 'N';
      rLF.FLPAGAAFASTDEFINITIVO := 'S';   

      BEGIN
        
         selecT cdLancamentoFinanceiro 
           into vCdLancamentoAnterior
           from epaglancamentofinanceiro
          where cdrubricaagrupamento = rLF.cdrubricaagrupamento
            and cdvinculo =  rLF.cdvinculo
            and nusufixorubrica =  rLF.nusufixorubrica
            and dtiniciodireito <= rLF.dtfimdireito
            and (dtfimdireito IS NULL OR dtfimdireito >= rLF.dtiniciodireito)
            and flanulado = 'N';   
      
      EXCEPTION
        
          WHEN NO_DATA_FOUND THEN
               
             vCdLancamentoAnterior := NULL;  
          when others then
            dbms_output.put_line (rLF.cdvinculo || '-' || rLF.cdrubricaagrupamento || '  ' || rLF.nusufixorubrica || ' '  || to_char (rLF.dtiniciodireito,'dd/mm/yyyy') || ' ' ||  to_char (rLF.dtfimdireito,'dd/mm/yyyy') );
            raise;
     
      END;  

      INSERT INTO epaglancamentofinanceiro
       (
         CdLancamentoFinanceiro,
         vlindice,
         vllancamentofinanceiro,
         cdrubricaagrupamento,
         cdvinculo, 
         nusufixorubrica,
         dtiniciodireito,
         dtfimdireito,
         nucpfcadastrador,
         inperiodicidade,
         FLPROPDEMITIDONOMES,
         FLPAGAAFASTDEFINITIVO )
       VALUES 
          (SPAGLANCAMENTOFINANCEIRO.NEXTVAL,
           rLF.vlindice,
           rLF.vllancamentofinanceiro,
           rLF.cdrubricaagrupamento,
           rLF.cdvinculo,
           rLF.nusufixorubrica,   
           rLF.dtiniciodireito,
           rLF.dtfimdireito,
           rLF.nucpfcadastrador,
           rLF.inperiodicidade,
           rLF.FLPROPDEMITIDONOMES,
           rLF.FLPAGAAFASTDEFINITIVO)
       RETURN CdLancamentoFinanceiro
         INTO rLF.CdLancamentoFinanceiro;       
   
      IF vCdLancamentoAnterior IS NOT NULL THEN
         update epaglancamentofinanceiro set flanulado = 'S' where cdLancamentoFinanceiro = vCdLancamentoAnterior;
      END IF;  
   
      UPDATE ECMPACERTORUBRICA L
         set CdLancamentoFinanceiro = rLF.CdLancamentoFinanceiro,
             VlIndice               = rLF.VlIndice,
             vllancamentofinanceiro = rLF.vllancamentofinanceiro,
             CdLancamentoAnterior   = vCdLancamentoAnterior
         WHERE rowid = rec.rid;
  
  end loop;   
    
  DBMS_OUTPUT.PUT_LINE ('Incluidos.....: ' || vContador);
  DBMS_OUTPUT.PUT_LINE ('Anulados......: ' || vAnulados);
  
END;

PROCEDURE PExcluirAcertoLF (pNmCmp IN VARCHAR2) IS

  vContador          INTEGER;
  
BEGIN

  vContador := 0;
  for rec in (
              SELECT l.*, rowid as rid
                FROM ECMPACERTORUBRICA L
               WHERE NmCmp = pNmCmp
                 AND FlCalculo = 'S'
                 AND FlVigente = 'N'
                 AND CdLancamentoFinanceiro IS NOT NULL) loop
     
    DELETE EPAGLancamentoFinanceiro WHERE CdLancamentoFinanceiro = rec.CdLancamentoFinanceiro;
    
    IF rec.CdLancamentoAnterior IS NOT NULL THEN
       UPDATE EPAGLancamentoFinanceiro
          SET FlAnulado = 'N'
        WHERE CdLancamentoFinanceiro = rec.CdLancamentoAnterior;

    END IF;
          
    vContador := vContador + 1;
    
    UPDATE ECMPACERTORUBRICA L
       set CdLancamentoFinanceiro = NULL,
           CdLancamentoAnterior   = NULL
      WHERE rowid = rec.rid;
  
  end loop;   
    
  DBMS_OUTPUT.PUT_LINE ('Excluidos.....: ' || vContador);
  
END;

PROCEDURE PAtualizarAcertoLF (pNmCmp IN VARCHAR2) IS
BEGIN
   PIncluirAcertoLF (pNmCmp => pNmCmp);
   PExcluirAcertoLF (pNmCmp => pNmCmp);  
END;

PROCEDURE PCriarCmpHistParamCalc (pNuAno IN INTEGEr, pNuMes IN INTEGER) IS

   vHParamCalc    ECMPHISTPARAMCALC%ROWTYPE;
   vOrgaos        VARCHAR2(1000);

begin
   
   vHParamCalc := null;
   vHParamCalc.numescompetencia := pNuMes;
   vHParamCalc.nuanocompetencia := pNuAno;   
   vHParamCalc.nuordem          := 0;
                          
   DELETE FROM ECMPHISTPARAMCALC;
       
   FOR rec IN ( 

           SELECT g.*
                                                                   
                  FROM (select FP.*,
                                  CASE
                                     WHEN tf.CdTipoFolha in  (-- Adiantamentos
                                                              PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp,
                                                              PKGPAG_TIPO.cnTpFolhaAdiant13,
                                                              PKGPAG_TIPO.cnTpFolhaAposAdiant13) then
                                          1
                                                                                
                                     WHEN tf.CdTipoFolha in  (--- Rescisoes
                                                              PKGPAG_TIPO.cnTpFolhaRescisao,
                                                              PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                                                              PKGPAG_TIPO.cnTpFolhaRescisaoPesquisador) then

                                          2
                                                   
                                     WHEN tf.CdTipoFolha in  (--- Ferias
                                                              PKGPAG_TIPO.cnTpFolhaFerias) then
                                          decode (fp.cdAgrupamento,4,0,3)
                                                   

                                     WHEN tf.CdTipoFolha in  (-- Normal
                                                              PKGPAG_TIPO.cnTpFolhaNormal,
                                                              PKGPAG_TIPO.cnTpFolhaComissionadoPuro,
                                                              PKGPAG_TIPO.cnTpFolhaBolsista,
                                                              PKGPAG_TIPO.cnTpFolhaResidente,
                                                              PKGPAG_TIPO.cnTpFolhaPesquisador,
                                                              PKGPAG_TIPO.cnTpFolhaConvenio,
                                                              PKGPAG_TIPO.cnTpFolhaCtisp,
                                                              PKGPAG_TIPO.cnTpFolhaAposentadoria,
                                                              PKGPAG_TIPO.cnTpFolhaInstPensao,
                                                              PKGPAG_TIPO.cnTpFolhaFunebre,
                                                              PKGPAG_TIPO.cnTpFolhaServAfast) then
                                          4                             

                                     WHEN tf.CdTipoFolha in  (--- dec terc de normal
                                                              PKGPAG_TIPO.cnTpFolha13,
                                                              PKGPAG_TIPO.cnTpFolhaResidente13,
                                                              PKGPAG_TIPO.cnTpFolhaCtisp13,
                                                              PKGPAG_TIPO.cnTpFolhaAposentadoria13,
                                                              PKGPAG_TIPO.cnTpFolhaFunebre13) then
                                          5                             

                                     WHEN tf.CdTipoFolha in  (--- Outras
                                                              PKGPAG_TIPO.cnTpFolhaOutras,
                                                              PKGPAG_TIPO.cnTpFolhaBEP,
                                                              PKGPAG_TIPO.cnTpFolhaProdex13,
                                                              PKGPAG_TIPO.cnTpFolhaHonorarios13,
                                                              PKGPAG_TIPO.cnTpFolhaHonorarProcuradores13) then 
                                          6
                                     else
                                          9
                                  end as ordem1,
                                  decode (fp.cdAgrupamento,276,001,176,002,134,003,1,004,3,005,132,006,5,007,4,008,2,009,136,010,6,011,099) as ordem2,
                                  decode(fp.cdorgao, 43, 990, 87, 72, fp.cdorgao) as ordem3,
                                  fp.cdTipoFolhaPagamento as ordem4, 
                                  fp.NuSequencialFolha as ordem5                                      
                                                    
                           from epagfolhapagamento FP      
                          inner join epagTipoFolhaPagamento tf
                             on tf.cdTipoFolhaPagamento = fp.cdTipoFolhaPagamento
                          WHERE nuanoreferencia = vHParamCalc.nuanocompetencia
                            AND numesreferencia = vHParamCalc.numescompetencia
                          
                             and cdtipocalculo = 1   
                     ) g
                                        
                 order by ordem1,ordem2, ordem3, ordem4, ordem5, cdorgao) LOOP

         IF vHParamCalc.cdTipoFolhaPagamento IS NULL
               OR ( vHParamCalc.cdTipoFolhaPagamento <> rec.cdTipoFolhaPagamento OR
                    vHParamCalc.NuSequencialFolha <> rec.NuSequencialFolha ) THEN -- quebrou hpc

            IF vHParamCalc.cdTipoFolhaPagamento IS NOT NULL THEN -- Gravar registro anterior
               vHParamCalc.orgaos := vOrgaos;
               INSERT INTO ECMPHISTPARAMCALC values vHParamCalc;
            END IF;
                       
            vHParamCalc.nuordem              := vHParamCalc.nuordem + 1;
            vHParamCalc.cdagrupamento        := rec.CdAgrupamento;
            vHParamCalc.cdtipocalculo        := rec.cdTipoCalculo;
            vHParamCalc.cdtipofolhapagamento := rec.cdTipoFolhaPagamento;
            vHParamCalc.nusequencialFolha    := rec.NuSequencialFolha;
            vHParamCalc.dtcalculo            := rec.DtCalculo;
            vHParamCalc.dtprevistacredito    := rec.dtPrevisaoCredito;
            vHParamCalc.orgaos               := NULL;

         END IF;
         
         IF vOrgaos IS NULL THEN
            vOrgaos := rec.cdOrgao;
         ELSE
            vOrgaos := vOrgaos || ',' || rec.cdOrgao;
         END IF;
                 
         INSERT INTO ECMPHISTPARAMCALC values vHParamCalc;        
    
   END LOOP;
   
   IF vHParamCalc.cdTipoFolhaPagamento IS NOT NULL THEN -- Gravar registro anterior
      vHParamCalc.orgaos := vOrgaos;
      INSERT INTO ECMPHISTPARAMCALC values vHParamCalc;
   END IF;
                   
END;                
                 
PROCEDURE PCriarHistParamCalculo (pFlCalculoNovo IN INTEGER) IS
   vCdHist         integer;
   vTabOrgao       PKGSOCConst.tVarchar2;

BEGIN

   FOR rec IN (SELECT * FROM ECMPHISTPARAMCALC
                ORDER BY NUORDEM              
               ) LOOP

      insert into epaghistoricoparamcalculo
          ( cdhistoricoparamcalculo, 
            cdagrupamento, 
            cdtipocalculo,  
            cdtipofolhapagamento, 
            flprocessaagrupamento, 
            fldefinitivo,  
            numescompetencia, 
            nuanocompetencia, 
            nusequencial, 
            dtcalculo, 
            flpagaadiantamento13sal, 
            instatus, 
            nucpfcadastrador, 
            dtinclusao, 
            cdtarefa, 
            dtprocessamento, 
            dtprevistacredito, 
            flsalvarvalorescalculovigente, 
            flbloqnaorecadastrado)
       values (
            SPaghistoricoparamcalculo.nextval, -- cdhistoricoparamcalculo, 
            rec.cdagrupamento,-- cdagrupamento, 
            rec.cdtipocalculo,-- cdtipocalculo,  
            rec.cdtipofolhapagamento,-- cdtipofolhapagamento, 
            'S',-- flprocessaagrupamento, 
            'N',-- fldefinitivo,  
            rec.numescompetencia,-- numescompetencia, 
            rec.nuanocompetencia,-- nuanocompetencia, 
            rec.nusequencialfolha,-- nusequencialfolha, 
            rec.dtcalculo,-- dtcalculo, 
            'N',-- flpagaadiantamento13sal, 
            0,-- instatus, 
            decode (pFlCalculoNovo,0,CROT_CALCULO_ANTIGO,CROT_CALCULO_NOVO), --nucpfcadastrador, 
            sysdate, --dtinclusao, 
            null, --cdtarefa, 
            trunc(sysdatE), --dtprocessamento, 
            rec.dtprevistacredito, --dtprevistacredito, 
            'N', --flsalvarvalorescalculovigente, 
            'N' --flbloqnaorecadastrado
            )
        returning CdHistoricoParamCalculo into vCdHist;
   
      vTabOrgao := PKGSOCUtil.FSplit (pString => rec.orgaos, pSeparador => ',');
 
      FOR p in vTabOrgao.FIRST .. vTabOrgao.LAST LOOP

         insert into epaghistoricoparamcalculoorgao
           values (vCdHist,
                   to_number(vTabOrgao(p)),
                   1,
                   0,
                   0,
                   null,
                   null);

      END LOOP;
      
   END LOOP;  

END;

PROCEDURE PReagendarProxima (pCdTarefa IN INTEGER) IS 

   vCdSituacaoTarefa         INTEGER;
   vCdhistoricoparamcalculo  INTEGER;
   vCdTarefa                 integer;
   vCdAgendamento            integer;
   vDtIni                    DATE;   

BEGIN
   
   IF pCdTarefa IS NULL THEN
      
      select cdsituacaotarefa
        into vCdSituacaoTarefa
        from eadmtarefa 
       where CdTarefa = (select cdtarefa from epaghistoricoparamcalculo
                          where cdhistoricoparamcalculo = ( select max(cdhistoricoparamcalculo)
                                                              from epaghistoricoparamcalculo
                                                             where cdtarefa is not null));
   ELSE                                                          

      select cdsituacaotarefa
        into vCdSituacaoTarefa
        from eadmtarefa 
       where CdTarefa = pCdTarefa;
    
   END IF;
   
   IF  vCdSituacaoTarefa <> 4 THEN
      DBMS_OUTPUT.PUT_LINE ('Nao executou porque ultima remessa tem situacao = ' || vCdSituacaoTarefa);
      RETURN;
   END IF;   
   
   select min(cdhistoricoparamcalculo)
     into vCDhistoricoparamcalculo
     from epaghistoricoparamcalculo
    where cdtarefa is null;

   IF vCdhistoricoparamcalculo IS NULL THEN
      DBMS_OUTPUT.PUT_LINE ('Nao há mais nada a executar');
      RETURN;
   END IF;      

   vDtIni  := SYSDATE + 1 * (1/(24*60));
   
   insert into eadmagendamento
     (cdagendamento, 
      cdtipotarefa, 
      cdperiodicidade, 
      nmagendamento, 
      dtvalidadeinicio, 
      dtinicio, 
      nucpf)
   values
     (sadmagendamento.nextval, --cdagendamento, 
     6, -- cdtipotarefa, 
     4, -- cdperiodicidade, 
     'calc folha', -- nmagendamento, 
     vdtini, -- dtvalidadeinicio, 
     vdtini, -- dtinicio, 
     '11111111111' -- nucpf, 
     )
   returning CdAgendamento into vCdAgendamento;

   insert into eadmtarefa
      (cdtarefa, 
       cdagendamento, 
       cdsituacaotarefa, 
       dtinicio)
   values     
      (sAdmTarefa.nextval, -- cdtarefa, 
       vCdAgendamento, --cdagendamento, 
       1, -- cdsituacaotarefa, 
       vDtIni)
   RETURNING CdTarefa INTO vCdTarefa;
                            
   update epaghistoricoparamcalculo
      set cdtarefa = vCdTarefa
    where cdHistoricoParamCalculo = vcdhistoricoparamcalculo;

   commit;
   
END;

PROCEDURE PLimparFolhaPagamento (pCdFolhaPagamento IN INTEGER) IS 
  
   vNuSequencialFolhaExc    INTEGER;
   novoReg                  EPagFolhaPagamento%rowTYPE;

BEGIN

    SELECT *
      INTO novoReg
      FROM EPagFolhaPagamento
     where cdFolhaPagamento = pCdFolhaPagamento;

    -- Busca novo sequencial para a folha

    BEGIN

     SELECT nvl(MAX(fp.nusequencialfolha),0) + 1
       INTO vNuSequencialFolhaExc
       FROM epagfolhapagamento fp
      WHERE fp.cdorgao              = novoReg.cdorgao
        AND fp.nuanoreferencia      = 1000
        AND fp.numesreferencia      = 01
        AND fp.cdtipofolhapagamento = novoReg.cdtipofolhapagamento;

    EXCEPTION
      WHEN OTHERS THEN
       vNuSequencialFolhaExc := 1;

    END;

    -- Exclusao logica da folha de pagamento

    UPDATE Epagfolhapagamento
       SET NuAnoReferencia = 1000,
           NuMesReferencia = 01,
           NuAnoMesReferencia = 100001,
           nuSequencialFolha  = vNuSequencialFolhaExc,
           Flcalculodefinitivo = 'N',
           DtCalculo = TO_DATE('01/01/1900', 'DD/MM/YYYY'),
           DtPrevisaoCredito = TO_DATE('01/01/1900', 'DD/MM/YYYY'),
           NuCPfCadastrador = LPAD (NuAnoReferencia,4,0)
                           || LPAD (NuMesReferencia,2,0)
                           || decode (FlCalculoDefinitivo,'S','1','0')
                           || LPAD (NuSequencialFolha,3,0)
     WHERE CdFolhaPagamento = pCdFolhaPagamento;

    -- Acerta dados do novo registro e clona

    novoReg.cdFolhaPagamento := SPAGFOLHAPAGAMENTO.NEXTVAL;

    INSERT INTO EPagFolhaPagamento
       values novoReg;

END;



PROCEDURE PExecutaProcCFAgendador (pCdTarefa IN INTEGER) IS
   
   vNuCPFCadastrador   VARCHAR2(11);
   
BEGIN
   
   SELECT nucpfcadastrador 
     into vNuCPFCadastrador
     from epaghistoricoparamcalculo
    where cdtarefa = pCdTarefa;
    
   IF vNuCPFCadastrador = CROT_CALCULO_ANTIGO THEN  

      XTMPAG.PExecutaProcCFAgendador (pCdTarefa => pCdTarefa);

   ELSE
      
      PKGPAG.PExecutaProcCFAgendador (pCdTarefa => pCdTarefa);   
   
   END IF;

   PReagendarProxima (pCdTarefa => pCdTarefa);
  
END;

end PKGCMP;
/
