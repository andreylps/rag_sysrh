CREATE OR REPLACE PACKAGE PKGPAG_TAR IS

/*-----------------------------------------------------------------------------------------/
    Objetivo: Registrar situacao de erro nos controles de tarefa
/*-----------------------------------------------------------------------------------------*/

   PROCEDURE PErroTarefa (pCdHistoricoParamCalculo IN INTEGER DEFAULT NULL,
                          pCdTarefa                IN INTEGER DEFAULT NULL,
                          pInsere                  IN BOOLEAN DEFAULT TRUE,
                          pCdPessoa                IN INTEGER DEFAULT NULL,
                          pDeLog                   IN VARCHAR2 DEFAULT NULL,
                          pCdVinculo               IN INTEGER DEFAULT NULL);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Recebe Chamada do Calculo Individual
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PEntrarCalculoIndividual (pCdFolhaPagamento        IN INTEGER,
                                    pCdVinculo               IN INTEGER,
                                    pDtCalculo               IN DATE,
                                    pFlCalculoDefinitivo     IN CHAR DEFAULT 'X',
                                    pVlDiferencaValor        IN NUMBER DEFAULT 0,
                                    pFlPagaAdiantamento      IN CHAR DEFAULT 'N',
                                    pLog                     IN BOOLEAN DEFAULT TRUE,
                                    pTrace                   IN BOOLEAN DEFAULT TRUE,
                                    pCalculoRetorno         OUT PKGPAG_CAL.rCalculoRetorno);

PROCEDURE PProcessarCalculoIndividual (pCdFolhaPagamento        IN INTEGER,
                                       pCdVinculo               IN INTEGER,
                                       pDtCalculo               IN DATE,
                                       pFlCalculoDefinitivo     IN CHAR,
                                       pCdCalculoContinua       IN INTEGER,
                                       pVlDiferencaValor        IN NUMBER DEFAULT 0,
                                       pFlPagaAdiantamento      IN CHAR DEFAULT 'N',
                                       pLog                     IN BOOLEAN DEFAULT TRUE,
                                       pTrace                   IN BOOLEAN DEFAULT TRUE,
                                       pCalculoRetorno         OUT PKGPAG_CAL.rCalculoRetorno);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Recebe Chamada do Calculo Individual
/*-----------------------------------------------------------------------------------------*/
/*
PROCEDURE PEntrarCalcParaleloIndividual (pCdFolhaPagamento        IN INTEGER,
                                         pCdVinculo               IN INTEGER);
*/


/*-----------------------------------------------------------------------------------------/
    Objetivo:  Recebe Chamada do Calculo Coletivo
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PEntrarCalculoTarefa (pCdTarefa IN INTEGER);

PROCEDURE POrdenarFolhaPagamento (pNuAnoMesReferencia IN INTEGER, pCdFolPagDef IN INTEGER DEFAULT NULL);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Funcao chamada pelo sistema para contar pessoas a Calcular
/*-----------------------------------------------------------------------------------------*/

FUNCTION FContarACalcular (pCdTarefa IN INTEGER) RETURN INTEGER;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de atualizar a situacao do calculo Consulta
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PAtualizaParametroConsulta ( pCalculo                 IN PKGPAG_CAL.rCalculo,
                                       pCdOrgao                 IN INTEGER DEFAULT NULL,
                                       pQtPessoasACalcular      IN INTEGER);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de atualizar a situacao do calculo Execucao
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PAtualizaParametroExecucao ( pCalculo                 IN PKGPAG_CAL.rCalculo,
                                       pCdOrgao                 IN INTEGER,
                                       pInStatus                IN INTEGER DEFAULT NULL,
                                       pQtPessoasCalculadas     IN INTEGER DEFAULT NULL,
                                       pQtPessoasACalcular      IN INTEGER DEFAULT NULL);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Verifica se houve pedido de interrupcao do processamento
/*-----------------------------------------------------------------------------------------*/

FUNCTION FInterromperProcessamento(pCalculo IN PKGPAG_CAL.rCalculo) RETURN BOOLEAN;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Chamado pelo JOB para indicar sua finalizacao
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PFinalizarJob (pJobId IN VARCHAR2, PMensagem VARCHAR2 DEFAULT NULL );

/*-----------------------------------------------------------------------------------------/
    Objetivo: Inicia/Finaliza Trace para TKPROF
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PTraceTKPROF (pBlLigar IN BOOLEAN, pID VARCHAR2 DEFAULT NULL);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Executar Calculo fazendo Trace
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PEntrarCalculoTarefaTKPROF (pCdTarefa IN INTEGER );

FUNCTION FObterFlCalculoDefinitivoFolha ( pCdFolhaPagamento IN INTEGER ) RETURN CHAR;

PROCEDURE PConsolidarFolhaPagamento (pCdFolhaPagamento        IN INTEGER,
                                     pCdHistoricoParamCalculo IN INTEGER,
                                     pCdFolhaPagamentoSubstit IN INTEGER);


function FExisteReferenciaCircularRub return boolean;

END PKGPAG_TAR;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_TAR IS

   cTraceTKPROF CHAR := 'N';

   -- Tabela de Jobs para controle da execucao das tarefas

   type recJob IS RECORD
   (
      CdJobId   VARCHAR2(30),
      cdOrgao   INTEGER,
      DeComando VARCHAR2(200),
      CdCalculo INTEGER
   );

   type tabJob is table of recJob index by pls_integer;
   vTabJob tabJob;
   vProxJob             INTEGER;

   --cNuCalculoSimultaneo INTEGER :=  20; --8 Alterado em 03/12/2018 para 10; --4; Alterado de 4 para 8 para testar o novo servidor.

   gQtdePessoasACalcular INTEGER;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Definir quantidade de processamentos paralelos
/*-----------------------------------------------------------------------------------------*/

   function fNuCalculoSimultaneo return pls_integer is
     vHrAtual pls_integer;
     vDBName varchar2(30);
   begin

     vDBName := pkgpag_param.fCDBName;

     if vDBName = 'PDB_SIGRH' then
       -- Manter a forma antiga por enquanto. 
       --Em breve falar com DBAs pra ver se pode colocar sempre 40
       vHrAtual := to_number(to_char(sysdate, 'HH24MI'));
       if vHrAtual between 2140 and 2359 or vHrAtual between 0000 and 0759 or to_char(sysdate, 'D') in ('1', '7') then
         return 40;
       elsif vHrAtual between 2000 and 2139 then
         return 40;
       elsif vHrAtual between 1900 and 1959 then
         return 30;
       elsif to_char(sysdate, 'MM') = '12' and vHrAtual between 0800 and 1200 then
          -- epoca de rodar varias folhas das 19h as 13h
          -- o processamento de 02/12/2021 nao gerou problemas e Victor concordou
         return 25;
       elsif to_char(sysdate, 'YYYYMMDD') = '20220211' and vHrAtual between 1300 and 1859 then
         -- para casos excepcionais
         return 15;
       else
         -- horario de expediente vespertino: 20 processos causa problemas e parece que mais do que 5 tambem é ruim pro banco
         return 5;
       END IF;
     elsif vDBName in ('PDB_SIGRHSIM', 'PDB_SIGRHQLD', 'PDB_SIGRHHOM') then
       return 20;
     elsif vDBName in ('PDB_SIGRHDES') then
       return 10;
     else
       return 5;
     END IF;
   end;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Buscar parametros da folha de Pagamento
/*-----------------------------------------------------------------------------------------*/

   PROCEDURE PBuscarTipoFolhaPagamento (pCdTipoFolhaPagamento  IN INTEGER ,
                                        pDtCompetencia         IN DATE,
                                        pCdTipoFolha          OUT INTEGER,
                                        pFlIncluiBolsista     OUT CHAR,
                                        pFlIncluiAposentado   OUT CHAR) IS

   BEGIN

      pCdTipoFolha        := NULL;
      pFlIncluiBolsista   := NULL;
      pFlIncluiAposentado := NULL;

      SELECT tf.cdtipofolha,
             htf.flIncluiBolsista,
             htf.flIncluiAposentado
        INTO pCdTipoFolha,
             pFlIncluiBolsista,
             pFlIncluiAposentado
        FROM epagtipofolhapagamento tf
       INNER JOIN epaghisttipofolhapagamento htf
          ON tf.cdtipofolhapagamento = htf.cdtipofolhapagamento
       WHERE tf.cdtipofolhapagamento = pCdTipoFolhaPagamento
         AND to_date(htf.nuanoiniciovigencia * 100 + htf.numesiniciovigencia, 'YYYYMM') <= pDtCompetencia
         AND (to_date(htf.nuanofimvigencia * 100 + htf.numesfimvigencia, 'YYYYMM') >= pDtCompetencia
          OR  htf.nuanofimvigencia IS NULL);

   EXCEPTION
      WHEN OTHERS THEN
         --dbms_output.put_line('Erro ao recuperar parâmetros de cálculo: ' ||  SQLERRM);
         RETURN;
   END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Registrar situacao de erro nos controles de tarefa
/*-----------------------------------------------------------------------------------------*/

   PROCEDURE PErroTarefa (pCdHistoricoParamCalculo IN INTEGER DEFAULT NULL,
                          pCdTarefa                IN INTEGER DEFAULT NULL,
                          pInsere                  IN BOOLEAN DEFAULT TRUE,
                          pCdPessoa                IN INTEGER DEFAULT NULL,
                          pDeLog                   IN VARCHAR2 DEFAULT NULL,
                          pCdVinculo               IN INTEGER DEFAULT NULL) IS

   BEGIN

    IF pCdHistoricoParamCalculo <> 0 THEN

        UPDATE EPagHistoricoParamCalculo pc
           SET pc.instatus = 3
               WHERE pc.cdhistoricoparamcalculo = pCdHistoricoParamCalculo;

        UPDATE epagHistoricoParamCalculoOrgao pc
           SET pc.instatus = 3
               WHERE pc.cdhistoricoparamcalculo = pCdHistoricoParamCalculo;

        IF pDeLog IS NOT NULL THEN
          PKGPAG_GERAL.pInsereLog(pInsere,
                                  pCdHistoricoParamCalculo,
                                  pCdPessoa,
                                  pDeLog,
                                  pCdVinculo);
        END IF;

        UPDATE EAdmTarefa a
           SET a.CdSituacaoTarefa = 3,
               a.dtinicioreal = SYSDATE
         WHERE CdTarefa = pCdTarefa;

    ELSIF pCdTarefa <> 0 THEN

        UPDATE EPagHistoricoParamCalculo pc
           SET pc.instatus = 3
               WHERE pc.cdtarefa = pCdtarefa;

        UPDATE epagHistoricoParamCalculoOrgao pc
           SET pc.instatus = 3
               WHERE pc.cdhistoricoparamcalculo
                  = (select cdhistoricoparamcalculo from EPagHistoricoParamCalculo
                          WHERE cdtarefa = pCdtarefa);

        IF pDeLog IS not NULL THEN
            PKGPAG_GERAL.pInsereLog(pInsere,
                                    pCdHistoricoParamCalculo, -- vai estar nulo
                                    pCdPessoa,
                                    pDeLog,
                                    pCdVinculo);
        END IF;

        UPDATE EAdmTarefa a
           SET a.CdSituacaoTarefa = 3,
           a.dtinicioreal = SYSDATE
         WHERE CdTarefa = pCdTarefa;

    else
      null;
    END IF;

   END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de atualizar a situacao do calculo Execucao
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PAtualizaParametroExecucao ( pCalculo                 IN PKGPAG_CAL.rCalculo,
                                       pCdOrgao                 IN INTEGER,
                                       pInStatus                IN INTEGER DEFAULT NULL, -- 1=Em Andamento, 2=finalizado,
                                       pQtPessoasCalculadas     IN INTEGER DEFAULT NULL,
                                       pQtPessoasACalcular      IN INTEGER DEFAULT NULL
                                       ) IS

  PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

  IF pCalculo.CdHistoricoParamCalculo = 0 THEN -- somente para execucoes batch
     RETURN;
  END IF;

  IF pQtPessoasCalculadas IS NOT NULL THEN

     -- Total do Orgao

     UPDATE EPagHistoricoParamCalculoOrgao po
        SET po.qtpessoascalculadas = nvl(po.qtpessoascalculadas,0) + pQtPessoasCalculadas
      WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
        AND po.cdorgao = pCdOrgao;

     -- Total Geral

     UPDATE EPagHistoricoParamCalculo pc
        SET pc.qtpessoascalculadas = nvl(pc.qtpessoascalculadas,0)  + pQtPessoasCalculadas
      WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo;

  END IF;

  IF pQtPessoasACalcular IS NOT NULL THEN

     IF pQtPessoasACalcular < 0 THEN
       -- inicializando....
       UPDATE EPagHistoricoParamCalculoOrgao po
          SET po.qtpessoas = 0,
              po.qtpessoascalculadas = 0
        WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo;

       UPDATE EPagHistoricoParamCalculo pc
          SET pc.qtpessoas = 0,
              pc.qtpessoascalculadas = 0
        WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo;

     ELSE

       IF pCdOrgao IS NULL or PCdOrgao = 0  THEN
         UPDATE EPagHistoricoParamCalculo pc
            SET pc.qtpessoas = pQtPessoasACalcular
          WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo;
       ELSE
         UPDATE EPagHistoricoParamCalculoOrgao po
            SET po.qtpessoas = pQtPessoasACalcular
          WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
            AND po.cdorgao = pCdOrgao;
       END IF;

     END IF;

  END IF;

  IF pInStatus IS NOT NULL THEN

    CASE
      WHEN pInStatus = 1 THEN -- em andamento

       -- Orgao

       UPDATE EPagHistoricoParamCalculoOrgao po
          SET po.instatus = pInStatus,
              po.DtInicio = SYSDATE
        WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND po.cdorgao = pCdOrgao
          AND nvl(po.InStatus,0) in (0,4) ; -- apenas alterar quando Agendado

       UPDATE EPagHistoricoParamCalculo pc
          SET pc.instatus = pInStatus
        WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND nvl(pc.InStatus,0) in (0,4) ; -- apenas alterar quando Agendado

      WHEN pInStatus = 2 THEN -- finalizado

       UPDATE EPagHistoricoParamCalculoOrgao po
          SET po.instatus = pInStatus,
              po.DtTermino = SYSDATE
        WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND po.cdorgao = pCdOrgao
          AND nvl(po.inStatus,0) NOT IN (2,3); -- Apenas finalizar se algum bloco nao deu erro antes ou finalizou

       UPDATE EPagHistoricoParamCalculo pc
          SET pc.instatus = pInStatus
        WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND pc.instatus IN (9) -- em execucao ou calc duplo vinculo
          AND NOT EXISTS
             (SELECT 1 FROM EPagHistoricoParamCalculoOrgao po
                WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
                  AND NVL(po.instatus,0) <> 2  -- somente encerrar calculo total se todos os orgaos estiverem finalizados
                  AND po.qtpessoas > 0 -- desconsiderar orgaos agendados sem pessoas a calcular
                  and Rownum < 2 );

      WHEN pInStatus = 3 THEN -- erro

       UPDATE EPagHistoricoParamCalculoOrgao po
          SET po.instatus  = pInStatus,
              po.DtTermino = SYSDATE
        WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND po.cdorgao = pCdOrgao
          AND po.inStatus <> pInStatus; -- Apenas se algum bloco nao deu erro antes

       UPDATE EPagHistoricoParamCalculoOrgao po
          SET po.instatus  = pInStatus,
              po.DtInicio  = SYSDATE,
              po.DtTermino = SYSDATE
        WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND nvl(po.instatus,0) in (0,4);

       UPDATE EPagHistoricoParamCalculo pc
          SET pc.instatus = pInStatus
        WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND pc.instatus <> 3; -- com erro

   WHEN pInStatus = 9 THEN -- em andamento

       UPDATE EPagHistoricoParamCalculoOrgao po
          SET po.instatus = pInStatus,
              po.DtInicio = SYSDATE
        WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND po.cdorgao = pCdOrgao
          AND nvl(po.InStatus,0) in (0,1,4); -- apenas alterar quando calc geral finalizado

       UPDATE EPagHistoricoParamCalculo pc
          SET pc.instatus = pInStatus
        WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
          AND nvl(pc.InStatus,0) in (0,1,4); -- apenas alterar quando calc geral finalizado

    END CASE;

  END IF;

  COMMIT;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de ordernar as folhas por ordem de data de execução e se definitiva ou temporaria
    ---------------------------------------------------------------------------------------*/

PROCEDURE POrdenarFolhaPagamento (pNuAnoMesReferencia IN INTEGER, pCdFolPagDef IN INTEGER DEFAULT NULL) IS

   vNuSeq             INTEGER; 
   vDeOrdemExecucao   VARCHAR2(5);

vmsg  varchar2(2000);

     
BEGIN

   vNuSeq := 0;
      
   FOR fp IN ( 
/*     
    #PENDENTE
    
    -- Voltar a ordem default das folhas
     
               with tOrdemOrg as (
                                 select CdOrgao,
                                        row_number() over (order by NuOrdemAgrupamento, NuOrdemOrgaoAgrup) as NuOrdemOrgao
                                   from ( select o.cdOrgao,
                                                 decode (CdAgrupamento, 276,   1, -- IMETRO
                                                                        176,   2, -- DPSC
                                                                        134,   3, -- PMSC
                                                                        1,     4, -- AGPE
                                                                        7,     5, -- MP
                                                                        6,     6, -- SANTUR
                                                                        132,   7, -- PensoesIPREV
                                                                        4,     8, -- CIDASC
                                                                        2,     9, -- CIASC
                                                                        5,    10, -- EPAGRI
                                                                        136,  11, -- SCPA
                                                                              99) as NuOrdemAgrupamento,
                                                 row_number() over (partition by CdAgrupamento order by CdOrgao) as NuOrdemOrgaoAgrup
                                             from vCadOrgao o
                                             ))
*/                                                
               SELECT fp.CdFolhaPagamento, fp.CdOrgao, FlCalculoDefinitivo, DeOrdemExecucao, fp.rowid as rid                      
                 FROM epagfolhapagamento fp
                inner join epagTipoFolhaPagamento tf
                  on tf.cdTipoFolhaPagamento = fp.cdTipoFolhaPagamento  
                WHERE NuAnoMesReferencia = pNuAnoMesReferencia
                ORDER BY DECODE(FlCalculoDefinitivo,'S',NVL(fp.DeOrdemExecucao,'D9999'),'N'), 
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
                            end,
                         decode (fp.cdAgrupamento,276,001,176,002,134,003,1,004,3,005,132,006,5,007,4,008,2,009,136,010,6,011,099),
                         decode(cdorgao, 43, 990, 87, 72, cdorgao),                       
                         fp.cdTipoFolhaPagamento, fp.NuSequencialFolha) LOOP

    
      IF fp.FlCalculoDefinitivo = 'S' THEN
         IF fp.DeOrdemExecucao IS NULL THEN
            IF pCdFolPagDef = fp.CdFolhaPagamento THEN 
               vNuSeq := vNuSeq + 1;
               vDeOrdemExecucao := 'D' || LPAD (vNuSeq,4,'0');
            ELSE
               vDeOrdemExecucao := NULL;
            END IF;   
         ELSE   
            vDeOrdemExecucao := fp.DeOrdemExecucao;            
            vNuSeq := SUBSTR(fp.DeOrdemExecucao,2);
         END IF;
      ELSE
         vNuSeq := vNuSeq + 1;
         vDeOrdemExecucao := 'N' || LPAD (vNuSeq,4,'0');
            
      END IF;

      IF NVL(fp.DeOrdemExecucao,'X') <> vDeOrdemExecucao THEN

         -- dbms_output.put_line ('cdfol/orgao/def: ' || fp.cdfolhapagamento || '/' || fp.cdorgao || '/' || fp.flcalculodefinitivo
         -- || ' -> de ' || fp.deordemexecucao || ' para ' || vDeOrdemExecucao);

         UPDATE EPagFolhaPagamento
               SET DeOrdemExecucao = vDeOrdemExecucao
             WHERE RowId = fp.rid;
      END IF;
          
   END LOOP;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de atualizar a situacao do calculo Consulta
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PAtualizaParametroConsulta ( pCalculo                 IN PKGPAG_CAL.rCalculo,
                                       pCdOrgao                 IN INTEGER DEFAULT NULL,
                                       pQtPessoasACalcular      IN INTEGER)  IS

BEGIN

  IF pCalculo.CdHistoricoParamCalculo <> 0 THEN -- somente para execucoes batch

      IF pCdOrgao is NOT NULL THEN

          UPDATE EPagHistoricoParamCalculoOrgao po
             SET po.qtpessoas = pQtPessoasACalcular
           WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
             AND po.cdorgao = pCdOrgao;

      ELSE

          IF pQtPessoasACalcular < 0 THEN
             -- inicializando ...

            UPDATE EPagHistoricoParamCalculoOrgao po
               SET po.qtpessoas = 0,
                   po.qtpessoascalculadas = 0
             WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo;

          ELSE
            UPDATE EPagHistoricoParamCalculo pc
               SET pc.qtpessoas = pQtPessoasACalcular
             WHERE pc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo;

          END IF;

      END IF;

  END IF;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure para fechar a folha de pagamento de um orgao
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PConsolidarFolhaPagamento (pCdFolhaPagamento        IN INTEGER,
                                     pCdHistoricoParamCalculo IN INTEGER,
                                     pCdFolhaPagamentoSubstit IN INTEGER) IS

BEGIN

  IF pCdHistoricoParamCalculo <> 0 THEN

     DELETE
          FROM EPagFolhaConsolidada FC
         WHERE FC.CdFolhaPagamento =  pCdFolhaPagamento;

     INSERT
            INTO EPagFolhaConsolidada FC
                (CdFolhaPagamento,
                 CdTipoSituacao,
                 CdRubricaAgrupamento,
                 NuSufixoRubrica,
                 CdHistoricoParamCalculo,
                 QtOcorrencia,
                 VlTotal)
          SELECT CP.CdFolhaPagamento,
                 CASE CP.Flativo
                   WHEN 'S' THEN
                     1
                   ELSE
                     2
                 END AS CdTipoSituacao,
                 HRV.CdRubricaAgrupamento,
                 HRV.NuSufixoRubrica,
                 pCdHistoricoParamCalculo,
                 COUNT(*),
                 SUM(VlPagamento)
            FROM EPagHistoricoRubricaVinculo HRV
           INNER JOIN EPagCapaHistRubricaVinculo CP
              ON CP.CdFolhaPagamento = HRV.CdFolhaPagamento AND
                 CP.CdVinculo = HRV.CdVinculo
           WHERE CP.CdFolhaPagamento =  pCdFolhaPagamento
           GROUP BY CP.CdFolhaPagamento,
                    CASE CP.Flativo
                      WHEN 'S' THEN
                        1
                      ELSE
                        2
                    END,
                    HRV.CdRubricaAgrupamento,
                    HRV.NuSufixoRubrica,
                    pCdHistoricoParamCalculo;

     IF pCdFolhaPagamentoSubstit IS NOT NULL THEN

       DELETE
          FROM EPagFolhaConsolidada FC
         WHERE FC.CdFolhaPagamento =  pCdFolhaPagamentoSubstit;

       INSERT
         INTO EPagFolhaConsolidada
             (CdFolhaPagamento,
              CdTipoSituacao,
              CdRubricaAgrupamento,
              NuSufixoRubrica,
              CdHistoricoParamCalculo,
              QtOcorrencia,
              VlTotal)
       SELECT pCdFolhaPagamentoSubstit,
              CdTipoSituacao,
              CdRubricaAgrupamento,
              NuSufixoRubrica,
              CdHistoricoParamCalculo,
              QtOcorrencia,
              VlTotal
         FROM EPagFolhaConsolidada
        WHERE CdFolhaPagamento = pCdFolhaPagamento;
     END IF;
  END IF;
END;

PROCEDURE PLiberaFolhas(pCalculo      IN PKGPAG_CAL.rCalculo,
                        pFlDefinitivo IN CHAR) IS

BEGIN

  IF pFlDefinitivo = 'S' AND pCalculo.FlGeral = 'S' THEN

    UPDATE Epaghistoricoparamcalculoorgao HP
       SET HP.InStatus = 2
     WHERE HP.CdHistoricoParamCalculo = pCalculo.CdHistoricoParamCalculo AND
           HP.InStatus IN (0,4) ;

    FOR vRec IN (SELECT HP.CdTipoCalculo,
                        HP.CdTipoFolhaPagamento,
                        HP.Nuanocompetencia,
                        HP.NuMesCompetencia,
                        HP.NuSequencial
                   FROM EPagHistoricoParamcalculo  HP
                  WHERE HP.CdHistoricoParamCalculo = pCalculo.CdHistoricoParamCalculo)
     LOOP

       UPDATE EPagFolhaPagamento FP
          SET FP.FlCalculoDefinitivo = 'S',
              FP.FlPortalLiberado = 'N'
        WHERE FP.NuAnoReferencia = vRec.NuAnoCompetencia AND
              FP.NuMesReferencia = vRec.NuMesCompetencia AND
              FP.CdTipoFolhaPagamento = vRec.CdTipoFolhaPagamento AND
              FP.CdTipoCalculo = vRec.CdTipoCalculo AND
              FP.NuSequencialFolha = vRec.NuSequencial;

     END LOOP;

  END IF;

END;
/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure para fechar a folha de pagamento de um orgao
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PFechaFolhaPagamento (pCalculo           IN PKGPAG_CAL.rCalculo,
                                pCdOrgao           IN INTEGER,
                                pCdFolhaPagamento  IN INTEGER,
                                pFlDefinitivo      IN CHAR,
                                pDtCalculo         IN DATE,
                                pDtPrevistaCredito IN DATE,
                                pNuMesCompetencia  IN NUMBER,
                                pNuAnoCompetencia  IN NUMBER,
                                pbLog              IN BOOLEAN) IS

  PRAGMA AUTONOMOUS_TRANSACTION;

  vCont              INTEGER;
  vCdApuracao        INTEGER;
  vErro              INTEGER;

BEGIN

  PKGPAG_GERAL.PLogProcIni ('TAR0401','FechaFolhaPagamento');

  IF pFlDefinitivo ='S' THEN

    UPDATE Esegparametro P
       SET P.VlParametro = lpad (pNuAnoCompetencia,4,'0') || lpad (pNuMesCompetencia,2,'0')
     WHERE P.CdParametro = 43 AND P.VlParametro < lpad (pNuAnoCompetencia,4,'0') || lpad (pNuMesCompetencia,2,'0') ;

  END IF;

  UPDATE EPagFolhaPagamento fp
     SET fp.flcalculodefinitivo = decode(pFlDefinitivo,'S','S',fp.flcalculodefinitivo),
         fp.dtcalculo = pDtCalculo,
         fp.dtprimeiroprocessamento = decode(fp.dtprimeiroprocessamento,NULL,trunc(SYSDATE),fp.dtprimeiroprocessamento),
         fp.dtultimoprocessamento = trunc(SYSDATE),
         fp.dtprevisaocredito = pDtPrevistaCredito
   WHERE fp.cdfolhapagamento = pCdFolhaPagamento;

  -- Trata apuracao de frequencia

  PKGPAG_GERAL.PLogProc ('TAR0401','TAR0402','Apuracao Frequencia');

  BEGIN

     SELECT COUNT(*)
       INTO vCont
       FROM EPagFolhaPagamento F
      WHERE F.CdFolhaPagamento = pCdFolhaPagamento AND
            F.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal;

      IF vCont > 0 THEN

        PKGMOV.PGeraPeriodoApuracaoFrequencia(pCdOrgao              => pCdOrgao,
                                              pNuMes                => CASE WHEN pNuMesCompetencia = 12 THEN
                                                                          1
                                                                       ELSE
                                                                          pNuMesCompetencia  + 1
                                                                       END,
                                              pNuAno                => CASE WHEN pNuMesCompetencia = 12 THEN
                                                                         pNuAnoCompetencia + 1
                                                                       ELSE
                                                                         pNuAnoCompetencia
                                                                       END,
                                              pCdApuracaoFrequencia => vCdApuracao,
                                              pErro                 => vErro);

         IF NVL(vErro,0) <> 0 THEN

           PKGPAG_GERAL.PInsereLog(pbLog,
                                   pCalculo.CdHistoricoParamCalculo,
                                   null,
                                  'Erro ao gerar período de apuração (Órgao:'|| PKGPAG_VAR.vgApuracaoFrequencia.CdOrgao ||'): ' || vErro,
                                   null);
         END IF;

       END IF;

    EXCEPTION

      WHEN OTHERS THEN

         PKGPAG_GERAL.PInsereLog(pbLog,
                                 pCalculo.CdHistoricoParamCalculo,
                                 null,
                                 'Erro ao gerar período de apuração: '|| SQLERRM,
                                 null);
  END;

  PKGPAG_GERAL.PLogProcFim ('TAR0402');
  
  COMMIT;

END PFechaFolhaPagamento;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Excluir registros de folha de pagamento
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PAlterarRefFolhaPagamento (pCdFolhaPagamentoOrig IN INTEGER,
                                     pCdFolhaPagamentoDest IN INTEGER) IS

BEGIN

   /* -- Select que monta o update abaixo:

      select '   UPDATE ' || RPAD(cpai.table_name,30,' ')
          || ' set ' || RPAD(colunapai.column_name,21,' ') || ' = pCdFolhaPagamentoDest where '
          || RPAD(colunapai.column_name,21,' ')|| ' = pCdFolhaPagamentoOrig;'

       from user_constraints cpai,
            user_constraints cfilho,
            useR_cons_columns colunapai
      where cpai.constraint_type = 'R'
        and cfilho.constraint_type in ('P','U')
        and cpai.r_constraint_name = cfilho.CONSTRAINT_NAME
        and cfilho.table_name = 'EPAGFOLHAPAGAMENTO'
        and colunapai.constraint_name = cpai.CONSTRAINT_NAME
        and cpai.table_name not in ('EPAGHISTORICORUBRICARELVINC',-- Tabelas que serao mantidas
                                    'EPAGHISTORICORUBRICAVINCULO',
                                    'EPAGCAPAHISTRUBRICAVINCULO',
                                    'EPAGFOLHACONSOLIDADA',
                                    'EPAGFOLHACONSOLIDADADETALHE'
                                    )
       order by cpai.table_name;

   */

   UPDATE EPAGCONFERENCIACREDITOBANCARIO set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGCONFERENCIAEMPENHO         set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGCONFERENCIAFOLHA           set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGCONFERENCIAFOLHAPENSAO     set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGFOLHAPAGAMENTO             set CDFOLHAVINCSUPL       = pCdFolhaPagamentoDest where CDFOLHAVINCSUPL       = pCdFolhaPagamentoOrig;
   UPDATE EPAGFOLHAPAGAMENTO             set CDFOLHAORIGEM         = pCdFolhaPagamentoDest where CDFOLHAORIGEM         = pCdFolhaPagamentoOrig;
   UPDATE EPAGFOLHAPAGAMENTO             set CDFOLHASUPLAGLUT      = pCdFolhaPagamentoDest where CDFOLHASUPLAGLUT      = pCdFolhaPagamentoOrig;
   UPDATE EPAGFOLHAPAGRUBRICA            set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGFOLHASUPTRANSFORMADA       set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGHISTRUBRICAVINCANULADO     set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGLANCAMENTOCOMPLEMENTAR     set CDFOLHAPAGAMENTO      = pCdFolhaPagamentoDest where CDFOLHAPAGAMENTO      = pCdFolhaPagamentoOrig;
   UPDATE EPAGLANCAMENTOFINANCEIRO       set CDFOLHAPAGSUPLEMENTAR = pCdFolhaPagamentoDest where CDFOLHAPAGSUPLEMENTAR = pCdFolhaPagamentoOrig;

   -- Acerto finalizado
END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Trocar Dados de Folhas de Pagamento
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PMoverFolhaPagamento (pCdFolhaPagamentoOrig IN INTEGER,
                                pCdFolhaPagamentoDest IN INTEGER) IS

   vRegOrig           EPagFolhaPagamento%rowTYPE;
   vRegDest           EPagFolhaPagamento%rowTYPE;
   vNuSequencialAux   integer;
begin

   SELECT *
     INTO vRegOrig
     FROM EPagFolhaPagamento
    where cdFolhaPagamento = pCdFolhaPagamentoOrig;

   SELECT *
     INTO vRegDest
     FROM EPagFolhaPagamento
    where cdFolhaPagamento = pCdFolhaPagamentoDest;

   -- Troca Ids

   vRegOrig.Cdfolhapagamento := pCdFolhaPagamentoDest;
   vRegDest.Cdfolhapagamento := pCdFolhaPagamentoOrig;

   -- Altera

   vNuSequencialAux           := vRegDest.NuSequencialFolha;
   vRegDest.NuSequencialFolha := NULL;

    UPDATE EPagFolhaPagamento FOrig
      --SET row = vRegDest
      SET FOrig.Nusequencialfolha = vRegDest.Nusequencialfolha,
          FOrig.Cdtipocalculo = vRegDest.Cdtipocalculo
    WHERE cdFolhaPagamento = pCdFolhaPagamentoOrig;

   UPDATE EPagFolhaPagamento FDest
      --SET row = vRegOrig
      SET FDest.Nusequencialfolha = vRegOrig.Nusequencialfolha,
          FDest.Cdtipocalculo = vRegOrig.Cdtipocalculo
    WHERE cdFolhaPagamento = pCdFolhaPagamentoDest;

   UPDATE EPagFolhaPagamento
      SET NuSequencialFolha = vNuSequencialAux
    WHERE cdFolhaPagamento = pCdFolhaPagamentoOrig;

   /*UPDATE EPagFolhaPagamento
      SET row = vRegDest
    WHERE cdFolhaPagamento = pCdFolhaPagamentoOrig;

   UPDATE EPagFolhaPagamento
      SET row = vRegOrig
    WHERE cdFolhaPagamento = pCdFolhaPagamentoDest;

   UPDATE EPagFolhaPagamento
      SET NuSequencialFolha = vNuSequencialAux
    WHERE cdFolhaPagamento = pCdFolhaPagamentoOrig;   */

   PAlterarRefFolhaPagamento (pCdFolhaPagamentoOrig => pCdFolhaPagamentoDest,
                              pCdFolhaPagamentoDest => null);

   PAlterarRefFolhaPagamento (pCdFolhaPagamentoOrig => pCdFolhaPagamentoOrig,
                              pCdFolhaPagamentoDest => pCdFolhaPagamentoDest);

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Excluir registros de folha de pagamento
/*-----------------------------------------------------------------------------------------*/

FUNCTION FExcluirFolhaPagamento (pCdFolhaPagamento IN INTEGER
                                 ) RETURN INTEGER IS

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

     -- Alterando referencias a esta folha para a nova folha (ou NULL se nao foi criada nova folha);

    PAlterarRefFolhaPagamento (pCdFolhaPagamentoOrig => pCdFolhaPagamento,
                               pCdFolhaPagamentoDest => novoReg.cdFolhaPagamento);

    RETURN novoReg.cdFolhaPagamento;

end;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Armazena o Calculo Anterior e retorna novo codigo de folha de pagamento
/*-----------------------------------------------------------------------------------------*/

FUNCTION FArmazenaCalculoAnterior ( pCdFolhaPagamento   IN  INTEGER,
                                    pCdTipoCalculoNovo  IN  INTEGER ) RETURN INTEGER IS

  vNovoReg                 EPagFolhaPagamento%rowTYPE;

  vCdFolhaPagamentoBKP     INTEGER;

  vNuSequencialFolha       INTEGER;

BEGIN

  -- Buscar folha de pagamento de backup

  vCdFolhaPagamentoBKP     := NULL;

  SELECT fpant.cdFolhaPagamento as CdFolhaPagamentoBKP
    INTO vCdFolhaPagamentoBKP
    FROM epagfolhapagamento fp
    LEFT JOIN epagfolhapagamento fpant
      ON fpant.cdorgao = fp.cdorgao
     AND fpant.nuanoreferencia = fp.nuanoreferencia
     AND fpant.numesreferencia = fp.numesreferencia
     AND fpant.CdTipoCalculo = pCdTipoCalculoNovo -- Backup e do mesmo de calculo do parametro
     AND fpant.cdtipofolhapagamento = fp.Cdtipofolhapagamento
   WHERE fp.cdFolhaPagamento = pCdFolhaPagamento;

  IF vCdFolhaPagamentoBKP IS NOT NULL THEN -- Apagar dados anteriores

    vCdFolhaPagamentoBkp :=  FExcluirFolhaPagamento (vCdFolhaPagamentoBkp);

  ELSE -- Nao existindo, criar a folha para backup

    BEGIN

     SELECT nvl(MAX(fpcont.nusequencialfolha),0) + 1
          INTO vNuSequencialFolha
          FROM epagfolhapagamento fp
     LEFT JOIN epagfolhapagamento fpcont
            ON fpcont.cdorgao = fp.cdorgao
           AND fpcont.nuanoreferencia = fp.nuanoreferencia
           AND fpcont.numesreferencia = fp.numesreferencia
           and fpcont.cdtipofolhapagamento = fp.Cdtipofolhapagamento
         WHERE fp.cdFolhaPagamento = pCdFolhaPagamento;

    EXCEPTION
      WHEN OTHERS THEN
       vNuSequencialFolha := 1;

    END;

    SELECT *
      INTO vNovoReg
      FROM EPagFolhaPagamento where cdFolhaPagamento = pCdFolhaPagamento;

    vNovoReg.CdFolhaPagamento     := sPagFolhaPagamento.NEXTVAL;
    vNovoReg.NuSequencialFolha    := vNuSequencialFolha;
    vNovoReg.CdTipoCalculo        := pCdTipoCalculoNovo;
    vNovoReg.flcalculodefinitivo  := 'N';

    INSERT
      INTO EPagFolhaPagamento
      VALUES vNovoReg;

    vCdFolhaPagamentoBkp := vNovoReg.CdFolhaPagamento;

  END IF;

  PMoverFolhaPagamento (pCdFolhaPagamentoOrig => pcdFolhaPagamento,
                        pCdFolhaPagamentoDest => vCdFolhaPagamentoBkp);

  RETURN vCdFolhaPagamentoBkp;

END;

/*----------------------------------------------------------------------------------------/*
    Funcao: PObtemOrdemCalculo
  Objetivo: Registra nas rubricas as ordens de calculo que devem ser obedecidas.
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PObtemOrdemCalculo ( pCdAgrupamento    IN INTEGER,
                               pNuVersaoBaseCalc IN INTEGER,
                               pNuVersaoFormCalc IN INTEGER,
                               pNuAnoReferencia  IN INTEGER,
                               pNuMesReferencia  IN INTEGER,
                               pCdCalculoPai     IN INTEGER,
                               pFlPersistir      IN INTEGER) IS

    TYPE rCaminhoRA IS RECORD (
       cdRAPai    VARCHAR2(15),
       cdRADep    VARCHAR2(15)
       );

    TYPE rNoRA IS RECORD (
       cdRA    VARCHAR2(15),
       qtDep   INTEGER,
       nuOrdem INTEGER
       );

    TYPE tCaminhoRA is table of rCaminhoRA index by PLS_INTEGER;
    TYPE tNoRA     is table of rNoRA       index by VARCHAR2(15);

    n                  VARCHAR2(15);
    vCaminhoRA         tCaminhoRA;
    vCaminhoRAAux      tCaminhoRA;
    vNoRA              tNoRA;

  -------  Procedures Internas ---------

 /*-----------------------------------------------------------------------------------------
        Objetivo: Adicionar Rubrica Agrupamento a array para Ordenacao
  -----------------------------------------------------------------------------------------*/

    PROCEDURE PAdicionarRAOrdenacao (pNoRA IN OUT tNoRA, pCaminhoRA IN OUT tCaminhoRA,  pCaminhoRAAux IN tCaminhoRA) IS

    vCaminhoCont INTEGER;
    vNoPai       VARCHAR2(15);

    BEGIN

      IF pCaminhoRAAux.COUNT > 0 THEN

        FOR i in pCaminhoRAAux.FIRST..pCaminhoRAAux.LAST LOOP

          vNoPai := pCaminhoRAAux (i).CdRaPai;

          IF NOT pNoRa.EXISTS( vNoPai ) THEN
             pNoRa (vNoPai ).cdRA    := vNoPai ;
             pNoRa (vNoPai ).nuOrdem := 0;
             pNoRa (vNoPai ).qtDep   := 0;
          END IF;

          pNoRa ( vNoPai ).qtDep := pNoRa (vNoPai).qtDep + 1;

          vCaminhoCont := NVL(pCaminhoRA.LAST,0) + 1;

          pCaminhoRA (vCaminhoCont).cdRaPai    := vNoPai;
          pCaminhoRA (vCaminhoCont).cdRaDep    :=  pCaminhoRAAux (i).CdRaDep;

        END LOOP;
      END IF;

    END;

 /*-----------------------------------------------------------------------------------------
        Objetivo: Gravar em Arquivo Ordenacao
  -----------------------------------------------------------------------------------------*/

    PROCEDURE PGravarOrdenacao (pCdCalculoPai     IN INTEGER,
                                pNuVersaoBaseCalc IN INTEGER,
                                pNuVersaoFormCalc IN INTEGER,
                                pNoRA             IN tNoRA) IS

    n                  VARCHAR2(15);

    BEGIN

      DELETE ECalRubricaAgrupamentoOrdem
       WHERE CdCalculoPai        = pCdCalculoPai;

      n := pNoRA.FIRST;
      WHILE n IS NOT NULL LOOP

       IF pNoRA(n).nuOrdem <> 0 AND SUBSTR (pNoRA(n).CdRa,1,1) <> 'B' THEN -- Desprezar Bases

         INSERT INTO ECalRubricaAgrupamentoOrdem
            ( CdCalculoPai,
              NuVersaoBaseCalc,
              NuVersaoFormCalc,
              CdRubricaAgrupamento,
              NuOrdem)
            VALUES
            ( pCdCalculoPai,
              pNuVersaoBaseCalc,
              pNuVersaoFormCalc,
              TO_NUMBER(vNoRA(n).CdRa),
              pNoRA(n).NuOrdem
             );
        END IF;
        n := pNoRA.NEXT(n);  -- get subscript of next element
      END LOOP;
    END;

 /*-----------------------------------------------------------------------------------------
        Objetivo: Ordenar Rubrica Agrupamento

        -- Chave   - cdHistoricoRubricaRelVinc
        -- cdRA    - cdRubricaAgrupamento
        -- nuRowid - rowId de ePagHistoricoRubricaRelVinc
  -----------------------------------------------------------------------------------------*/

    FUNCTION FOrdenarRAOrdenacao (pNoRA IN OUT tNoRA, pCaminhoRA IN OUT tCaminhoRA) RETURN BOOLEAN IS

      bExisteDependencia BOOLEAN;
      bExiste            BOOLEAN;
      bRenumerou         BOOLEAN;
      vChaveDependencia  VARCHAR2(15);
      vOrdem             INTEGER;
      c                  INTEGER;
      n                  VARCHAR2(15);
      vtmp               varchar2(100);
      vMensagem          VARCHAR2(2000);

    BEGIN

      vOrdem := 1;

      bRenumerou         := TRUE;
      bExisteDependencia := TRUE;

      WHILE ( bExisteDependencia AND bRenumerou) LOOP

        bRenumerou         := FALSE;
        bExisteDependencia := FALSE;

        -- Percorrer todos os caminhos com destino sem dependencias

        c := pCaminhoRA.FIRST;
        WHILE c IS NOT NULL LOOP

           bExiste := false;

           IF pNoRA.EXISTS (pCaminhoRA(c).cdRaDep ) THEN  -- Encontrou dependente

              IF pNoRA(pCaminhoRA(c).cdRaDep).nuOrdem = 0 THEN -- ainda nao renumerado, contar como dependencia
                 bExiste := TRUE;
              end if;
           END IF;

           IF NOT bExiste THEN -- Nao Encontrou o dependente, excluir caminho e subtrair dependencias do no pai
              pNoRa (pCaminhoRA(c).cdRaPai).qtDep := pNoRa (pCaminhoRA(c).cdRaPai).qtDep - 1;
              pCaminhoRA.DELETE(c);
           END IF;
           c := pCaminhoRA.NEXT(c);

        END LOOP;

        -- Indicar ordem dos nos sem dependentes

        vOrdem := vOrdem + 1;

        n := pNoRA.FIRST;
        WHILE n IS NOT NULL LOOP

          IF pNoRA(n).NuOrdem = 0 THEN -- Nao ordenado ainda

            IF pNoRA(n).qtDep = 0 THEN
               pNoRA(n).NuOrdem   := vOrdem;
               bRenumerou         := TRUE;
            ELSE
               vChaveDependencia  := pNoRA(n).cdRA;
               bExisteDependencia := TRUE;
            END IF;

          END IF;
          n := pNoRA.NEXT(n);  -- get subscript of next element
        END LOOP;

      END LOOP;

      IF NOT bExisteDependencia THEN
         RETURN TRUE;
      ELSE -- Saiu deixando dependencias, formula circular

        vMensagem := 'Rubrica ' ;

        -- montar mensagem de erro
        bExiste := TRUE;

        WHILE bExiste LOOP
           IF SUBSTR (vChaveDependencia,1,1) = 'B' THEN -- Base
             vMensagem := vMensagem || ' => ' || vChaveDependencia || ' ';

             select nmbasecalculo
               into vtmp
             from epagbasecalculo where cdbasecalculo = to_number(substr(vChaveDependencia,2));

             vMensagem := vMensagem || '(' || vtmp  || ')';

           ELSIF PKGPAG_VAR.vgRubrica.exists( to_number(vChaveDependencia) ) THEN

             vMensagem := vMensagem || ' => ' || vChaveDependencia || ' ';

             selecT

               LPAD(r.CdTipoRubrica,2,'0')
               || '-' || LPAD(r.NuRubrica,4,'0')
               || ' ' || derubricaagrupamento

              into vtmp
              from epaghistrubricaagrupamento hra, epagrubrica r, epagrubricaagrupamento ra
               where ra.cdrubricaagrupamento = to_number(vChaveDependencia)
                 and hra.cdrubricaagrupamento (+) = ra.cdrubricaagrupamento
                 and ra.cdrubrica = r.cdrubrica
                 and nuanofimvigencia (+)  is null;

             vMensagem := vMensagem || '(' || vtmp  ||  ')';

           ELSE

             vMensagem := vMensagem || ' => ' || vChaveDependencia || ' ';
           END IF;

           bExiste := FALSE;
           c := pCaminhoRA.FIRST;
           WHILE c IS NOT NULL LOOP

             IF pCaminhoRA(c).cdRaPai = vChaveDependencia THEN
             -- encontrou no inedito com dependencia
                vChaveDependencia := pCaminhoRA(c).cdRaDep;
                bExiste := TRUE;
                pCaminhoRA.DELETE(c);
                EXIT;
             END IF;
             c := pCaminhoRA.NEXT (c);

           END LOOP;

         END LOOP;

         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'Processamento abortado. Encontrada dependência mútua entre formulas/bases: ' ||
                                 vMensagem,
                                 PKGPAG_VAR.vgCdVinculo);

         RETURN FALSE;

      END IF;

    END;

  -------  Bloco Principal ---------

  BEGIN

    -- Temporario ate retirar todas as dependencias de vigencias anteriores a 2012/07

    IF pNuAnoReferencia <= 2011 OR
        (pNuAnoReferencia =2012 AND pNuMesReferencia <=6) THEN

      RETURN;

    END IF;

    -- Adicionar as dependencias a ordenar

    -- Formula de Calculo -> RubricaAgrupamento

    SELECT FCV.CdRubricaAgrupamento as CdPai,FCBA.CdRubricaAgrupamento as CdDep
      BULK COLLECT INTO vCaminhoRAAux
           FROM ( SELECT FCV.CdFormulaVersao,FC.CdRubricaAgrupamento,
                         ROW_NUMBER() OVER (PARTITION BY FCV.CDFORMULACALCULO ORDER BY FCV.NUFormulaVersao DESC) AS UltVersao
                    FROM Epagformulacalculo FC
                   INNER JOIN Epagformulaversao FCV
                           ON FCV.CdFormulaCalculo = FC.CdFormulaCalculo
                          AND FCV.NuFormulaVersao in ('1', pNuVersaoFormCalc)
                   WHERE FC.CdAgrupamento = pCdAgrupamento
                 --and fc.cdrubricaagrupamento <> 9924
                     and (fc.cdrubricaagrupamento <> 9924 and pNuAnoReferencia * 100 + pNuMesReferencia < 202007
                         or pNuAnoReferencia * 100 + pNuMesReferencia >= 202007)) FCV
           INNER JOIN EPagHistFormulaCalculo HFC
                   ON HFC.CdFormulaVersao = FCV.CdFormulaVersao
                  AND ( HFC.NuAnoInicio < pNuAnoReferencia
                        OR (HFC.NuAnoInicio = pNuAnoReferencia AND HFC.NuMesInicio <= pNuMesReferencia) )
                  AND ( HFC.NuAnoFim > pNuAnoReferencia
                        OR HFC.NuAnoFim IS NULL
                        OR (HFC.NuAnoFim = pNuAnoReferencia AND HFC.NuMesFim >= pNuMesReferencia)  )
           INNER JOIN EPagExpressaoFormCalc FCE
                   ON FCE.CdHistFormulaCalculo = HFC.CdHistFormulaCalculo
           INNER JOIN EPagFormulaCalculoBloco FCB
                   ON FCB.Cdexpressaoformcalc = FCE.Cdexpressaoformcalc
           INNER JOIN EPagFormulaCalcBlocoExpressao FCBE
                   ON FCBE.Cdformulacalculobloco = FCB.Cdformulacalculobloco
                  AND (FCBE.Inmes IS NULL OR (FCBE.Inmes NOT IN ('AN','RI')))
           INNER JOIN EPagFormCalcBlocoExpRubAgrup FCBA
                   ON FCBA.Cdformulacalcblocoexpressao = FCBE.Cdformulacalcblocoexpressao
           WHERE FCV.UltVersao = 1;

    PAdicionarRAOrdenacao (vNoRa,vCaminhoRA,vCaminhoRAAux);

    -- Por causa do média férias

    SELECT FCV.CdRubricaAgrupamento as CdPai,FCBE.CdRubricaAgrupamento as CdDep
      BULK COLLECT INTO vCaminhoRAAux
           FROM ( SELECT FCV.CdFormulaVersao,FC.CdRubricaAgrupamento,
                         ROW_NUMBER() OVER (PARTITION BY FCV.CDFORMULACALCULO ORDER BY FCV.NUFormulaVersao DESC) AS UltVersao
                    FROM Epagformulacalculo FC
                   INNER JOIN Epagformulaversao FCV
                           ON FCV.CdFormulaCalculo = FC.CdFormulaCalculo
                          AND FCV.NuFormulaVersao in ('1', pNuVersaoFormCalc)
                   WHERE FC.CdAgrupamento = pCdAgrupamento) FCV
           INNER JOIN EPagHistFormulaCalculo HFC
                   ON HFC.CdFormulaVersao = FCV.CdFormulaVersao
                  AND ( HFC.NuAnoInicio < pNuAnoReferencia
                        OR (HFC.NuAnoInicio = pNuAnoReferencia AND HFC.NuMesInicio <= pNuMesReferencia) )
                  AND ( HFC.NuAnoFim > pNuAnoReferencia
                        OR HFC.NuAnoFim IS NULL
                        OR (HFC.NuAnoFim = pNuAnoReferencia AND HFC.NuMesFim >= pNuMesReferencia)  )
           INNER JOIN EPagExpressaoFormCalc FCE
                   ON FCE.CdHistFormulaCalculo = HFC.CdHistFormulaCalculo
           INNER JOIN EPagFormulaCalculoBloco FCB
                   ON FCB.Cdexpressaoformcalc = FCE.Cdexpressaoformcalc
           INNER JOIN EPagFormulaCalcBlocoExpressao FCBE
                   ON FCBE.Cdformulacalculobloco = FCB.Cdformulacalculobloco
                  AND (FCBE.Inmes IS NULL OR (FCBE.Inmes NOT IN ('AN','RI')))
           WHERE FCV.UltVersao = 1 AND FCBE.Cdrubricaagrupamento IS NOT NULL AND
           FCBE.Cdtipomneumonico = 77;

    PAdicionarRAOrdenacao (vNoRa,vCaminhoRA,vCaminhoRAAux);

    -- Formula de Calculo -> Base de Calculo

    SELECT FCV.CdRubricaAgrupamento as CdPai,'B' || FCBE.Cdbasecalculo as CdDep
      BULK COLLECT INTO vCaminhoRAAux
           FROM
            ( SELECT FCV.CdFormulaVersao,FC.CdRubricaAgrupamento,
                      ROW_NUMBER() OVER (PARTITION BY FCV.CDFORMULACALCULO ORDER BY FCV.NUFormulaVersao DESC) AS UltVersao
                     FROM  Epagformulacalculo FC
                       INNER JOIN Epagformulaversao FCV
                               ON FCV.CdFormulaCalculo = FC.CdFormulaCalculo
                                AND FCV.NuFormulaVersao in ('1', pNuVersaoFormCalc)
                                WHERE FC.CdAgrupamento = pCdAgrupamento
            ) FCV
           INNER JOIN EPagHistFormulaCalculo HFC
                   ON HFC.CdFormulaVersao = FCV.CdFormulaVersao
                  AND ( HFC.NuAnoInicio < pNuAnoReferencia
                        OR (HFC.NuAnoInicio = pNuAnoReferencia AND HFC.NuMesInicio <= pNuMesReferencia) )
                  AND ( HFC.NuAnoFim > pNuAnoReferencia
                        OR HFC.NuAnoFim IS NULL
                        OR (HFC.NuAnoFim = pNuAnoReferencia AND HFC.NuMesFim >= pNuMesReferencia)  )
           INNER JOIN EPagExpressaoFormCalc FCE
                   ON FCE.CdHistFormulaCalculo = HFC.CdHistFormulaCalculo
           INNER JOIN EPagFormulaCalculoBloco FCB
                   ON FCB.Cdexpressaoformcalc = FCE.Cdexpressaoformcalc
           INNER JOIN EPagFormulaCalcBlocoExpressao FCBE
                   ON FCBE.Cdformulacalculobloco = FCB.Cdformulacalculobloco
                  AND FCBE.Cdbasecalculo IS NOT NULL
                WHERE FCV.UltVersao = 1;

    PAdicionarRAOrdenacao (vNoRa,vCaminhoRA,vCaminhoRAAux);

    -- RubricaAgrupamento -> Base de Calculo

    SELECT RA.CdRubricaAgrupamento as CdPai,'B'|| RA.Cdbasecalculo as CdDep
       BULK COLLECT INTO vCaminhoRAAux
          FROM EPagRubricaAgrupamento RA
          WHERE RA.CdBaseCalculo IS NOT NULL
            AND RA.CdAgrupamento = pCdAgrupamento;

    PAdicionarRAOrdenacao (vNoRa,vCaminhoRA,vCaminhoRAAux);

    -- Base de Calculo -> RubricaAgrupamento

    SELECT 'B' || BCV.Cdbasecalculo as CdPai,BCRA.Cdrubricaagrupamento as CdDep
       BULK COLLECT INTO vCaminhoRAAux
           FROM
            ( SELECT BCV.CdVersaoBaseCalculo,Bc.CdBaseCalculo,
                    ROW_NUMBER() OVER (PARTITION BY BCV.CDBASECALCULO ORDER BY BCV.NUVersao DESC) AS UltVersao
                   FROM  EpagBaseCalculo BC
                     INNER JOIN EpagBaseCalculoVersao BCV
                             ON BCV.CdBaseCalculo = BC.CdBaseCalculo
                              aND BCV.NuVersao in ('1', pNuVersaoBaseCalc)
                              WHERE BC.CdAgrupamento = pCdAgrupamento

             ) BCV
            INNER JOIN EPagHistBaseCalculo HBC
                   ON HBC.Cdversaobasecalculo = BCV.CdVersaoBaseCalculo
                  AND ( HBC.NuAnoInicioVigencia < pNuAnoReferencia
                      OR (HBC.NuAnoInicioVigencia = pNuAnoReferencia AND HBC.NuMesInicioVigencia <= pNuMesReferencia) )
                  AND  (HBC.NuAnoFimVigencia > pNuAnoReferencia
                      OR HBC.NuAnoFimVigencia IS NULL
                      OR (HBC.NuAnoFimVigencia = pNuAnoReferencia AND HBC.NuMesFimVigencia >= pNuMesReferencia ) )
           INNER JOIN EPagBaseCalculoBloco BCB
                   ON  BCB.Cdhistbasecalculo = HBC.CdHistBaseCalculo
           INNER JOIN EPagBaseCalculoBlocoExpressao BCE
                   ON BCE.CdBaseCalculoBloco = BCB.CdBaseCalculoBloco
                  AND (BCE.Inmes IS NULL OR (BCE.Inmes NOT IN ('AN','RI')))
           INNER JOIN Epagbasecalcblocoexprrubagrup BCRA
                   ON BCRA.CdBaseCalculoBlocoExpressao = BCE.CdBaseCalculoBlocoExpressao
                WHERE BCV.UltVersao = 1;

    PAdicionarRAOrdenacao (vNoRa,vCaminhoRA,vCaminhoRAAux);

    --   RubricaAgrupamento ->  Vantagem Pecuniaria

    SELECT VP.CdRubricaAgrupamento as CdPai,
           HVP.CdRubricaAgrupamento AS CdDep -- CdRubricaTotalizadoraVantagem
      BULK COLLECT INTO vCaminhoRAAux
         FROM Ebpcvantagempecuniaria VP
        INNER JOIN Ebpchistvantagempecuniaria HVP
                ON HVP.Cdvantagempecuniaria = VP.Cdvantagempecuniaria
               AND HVP.CdRubricaAgrupamento IS NOT NULL
               AND ( HVP.NuAnoInicio < pNuAnoReferencia
                     OR (HVP.NuAnoInicio = pNuAnoReferencia AND HVP.NuMesInicio <= pNuMesReferencia) )
               AND ( HVP.NuAnoFim > pNuAnoReferencia
                     OR HVP.NuMesFim IS NULL
                     OR (HVP.NuAnoFim = pNuAnoReferencia AND HVP.NuMesFim >= pNuMesReferencia) )
        INNER JOIN EPagHistRubricaAgrupamento HRA
                ON HRA.CdRubricaAgrupamento = VP.CdRubricaAgrupamento
               AND ( HRA.NuAnoInicioVigencia <pNuAnoReferencia
                    OR (HRA.NuAnoInicioVigencia = pNuAnoReferencia AND HRA.NuMesInicioVigencia <= pNuMesReferencia) )
               AND ( HRA.NuAnoFimVigencia > pNuAnoReferencia
                    OR HRA.NuMesFimVigencia IS NULL
                    OR (HRA.NuAnoFimVigencia = pNuAnoReferencia AND HRA.NuMesFimVigencia >= pNuMesReferencia)
                    )
             WHERE CdAgrupamento = pCdAgrupamento OR
                   CdOrgao IN (SELECT CdOrgao FROM ECadOrgao WHERE CdAgrupamento = pCdAgrupamento);

    PAdicionarRAOrdenacao (vNoRa,vCaminhoRA,vCaminhoRAAux);

     -- Chamar Ordenacao
    IF NOT FOrdenarRAOrdenacao (vNoRa,vCaminhoRA) THEN
       RAISE PKGPAG_VAR.eDependenciaFormula;
    END IF;
   
    IF pFlPersistir = 1 THEN
  
       PGravarOrdenacao (pCdCalculoPai     => pCdCalculoPai,
                         pNuVersaoBaseCalc => pNuVersaoBaseCalc,
                         pNuVersaoFormCalc => pNuVersaoFormCalc,
                         pNoRA             => vNoRa);
                      
    END IF;
    
  END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedimentos anteriores ao calculo paralelo
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PPreCalculoFolha (pCalculo           IN PKGPAG_CAL.rCalculo,
                            pCdFolhaPagamento  IN INTEGER,
                            pCdOrgao           IN INTEGER,
                            pFlDefinitivo      IN CHAR,
                            pDtCalculo         IN DATE,
                            pNuMesCompetencia  IN NUMBER,
                            pNuAnoCompetencia  IN NUMBER,
                            pDtPrevistaCredito IN DATE,
                            pFlLog             IN CHAR
                            ) IS

BEGIN

   dbms_mview.refresh ('sigrh.vpagrubricaagrupamento', nested => true);

   PKGPAG_PARAM.PArmazenaInfoFolha (pCdFolhaPagamento => pCdFolhaPagamento );

   IF pCalculo.FlGeral <> 'I' THEN -- Calculo nao individual

      -- Caso o parametro FlDefinitivo = 'S', fecha a respectiva folha de pagamento

      PFechaFolhaPagamento(pCalculo,
                           pCdOrgao,
                           pCdFolhaPagamento,
                           pFlDefinitivo,
                           pDtCalculo,
                           pDtPrevistaCredito,
                           pNuMesCompetencia,
                           pNuAnoCompetencia,
                           CASE pFlLog
                               WHEN 'S' THEN
                                 TRUE
                               ELSE
                                 FALSE
                           END);

   END IF;
   
   POrdenarFolhaPagamento (pNuAnoMesReferencia => pNuAnoCompetencia * 100 + pNuMesCompetencia,
                           pCdFolPagDef        => CASE pFlDefinitivo
                                                     WHEN 'S' THEN
                                                        pCdFolhaPagamento
                                                     ELSE
                                                        NULL
                                                  END);
                              
END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedimentos anteriores ao calculo sequencial
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PPreCalculoSequencial (pCalculo             IN PKGPAG_CAL.rCalculo,
                             pCdAgrupamento       IN INTEGER,
                             pFlDefinitivo        IN CHAR,
                             pNuMesCompetencia    IN INTEGER,
                             pNuAnoCompetencia    IN INTEGER,
                             pDtCalculo           IN DATE,
                             pDtPrevistaCredito   IN DATE,
                             pCdTipoFolha         IN INTEGER,
                             pCdTipoCalculo       IN INTEGER,
                             pFlLog               IN CHAR) IS

  vFlag INTEGER;

BEGIN

   vFlag := 0;

   FOR vCal IN ( SELECT DISTINCT cdfolhapagamento,
                                 cdOrgaoExercicio as CdOrgao
                            from ecalvincfolha v
                           WHERE CdCalculo = pCalculo.CdCalculo)
   LOOP

     PPreCalculoFolha (pCalculo           => pCalculo,
                       pCdFolhaPagamento  => vCal.CdFolhaPagamento,
                       pCdOrgao           => vCal.CdOrgao,
                       pFlDefinitivo      => pFldefinitivo,
                       pDtCalculo         => pDtcalculo,
                       pNuMesCompetencia  => pNuMesCompetencia,
                       pNuAnoCompetencia  => pNuAnoCompetencia,
                       pDtPrevistaCredito => pDtPrevistaCredito,
                       pFlLog             => pFlLog);

     IF vFlag = 0 THEN -- somente uma vez, e depois de garantir que o armazenarFolha foi executado
        vFlag := 1;

        PObtemOrdemCalculo (pCdAgrupamento    => pCdAgrupamento,
                            pNuAnoReferencia  => pNuAnoCompetencia,
                            pNuMesReferencia  => pNuMesCompetencia,
                            pNuVersaoBaseCalc => nvl (PKGPAG_VAR.vgFolha.NuVersaoBaseCalculo, PKGPAG_TIPO.cn1),
                            pNuVersaoFormCalc => nvl (PKGPAG_VAR.vgFolha.NuVersaoFormulaCalculo, PKGPAG_TIPO.cn1),
                            pCdCalculoPai     => pCalculo.CdCalculoPai,
                            pFlPersistir      => 1);

     END IF;

   END LOOP;

   -- Se existem folhas a calcular
   IF vFlag = 1 THEN

     PKGPAG_PRE.PGerarTabelaFolha(pCalculo               => pCalculo,
                                  pNuMesCompetencia      => pNuMesCompetencia,
                                  pNuAnoCompetencia      => pNuAnoCompetencia,
                                  pCdTipoFolha           => pCdTipoFolha,
                                  pCdTipoCalculo         => pCdTipoCalculo,
                                  pFlCalculoDefinitivo   => pFlDefinitivo,
                                  pDtPrevisaoCredito     => pDtPrevistaCredito,
                                  pNuSequencial          => PKGPAG_VAR.vgFolha.NuSequencialFolha);

   END IF;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedimentos anteriores ao calculo paralelo
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PPreCalculoParalelo (pCalculo             IN PKGPAG_CAL.rCalculo,
                               pFlDefinitivo        IN CHAR,
                               pNuMesCompetencia    IN INTEGER,
                               pNuAnoCompetencia    IN INTEGER,
                               pCdTipoFolha         IN INTEGER,
                               pCdTipoCalculo       IN INTEGER,
                               pDtPrevisaoCredito   IN DATE) IS

  vFlag            INTEGER;

BEGIN

   vFlag := 0;

   FOR vCal IN ( SELECT DISTINCT
                    CdAgrupamento,
                    CdFolhaPagamento,
                    CdOrgao,
                    FlDefinitivo,
                    DtCalculo,
                    CdTipoCalculo,
                    DtPrevistaCredito,
                    NuMesCompetencia,
                    NuAnoCompetencia,
                    FlSalvarValoresCalculoVigente,
                    FlLog
                 FROM ECalCalculo
                 WHERE CdCalculoPai = pCalculo.CdCalculoPai)
   LOOP

     PPreCalculoFolha (pCalculo           => pCalculo,
                       pCdFolhaPagamento  => vCal.CdFolhaPagamento,
                       pCdOrgao           => vCal.CdOrgao,
                       pFlDefinitivo      => vCal.FlDefinitivo,
                       pDtCalculo         => vCal.DtCalculo,
                       pNuMesCompetencia  => vCal.NuMesCompetencia,
                       pNuAnoCompetencia  => vCal.NuAnoCompetencia,
                       pDtPrevistaCredito => vCal.Dtprevistacredito,
                       pFlLog             => vCal.FlLog);

     IF vFlag = 0 THEN -- somente uma vez, e depois de garantir que o armazenarFolha foi executado
        vFlag := 1;

        PObtemOrdemCalculo (pCdAgrupamento    => vCal.CdAgrupamento,
                            pNuAnoReferencia  => vCal.NuAnoCompetencia,
                            pNuMesReferencia  => vCal.NuMesCompetencia,
                            pNuVersaoBaseCalc => nvl (PKGPAG_VAR.vgFolha.NuVersaoBaseCalculo, PKGPAG_TIPO.cn1),
                            pNuVersaoFormCalc => nvl (PKGPAG_VAR.vgFolha.NuVersaoFormulaCalculo, PKGPAG_TIPO.cn1),
                            pCdCalculoPai     => pCalculo.CdCalculoPai,
                            pFlPersistir      => 1);

     END IF;

   END LOOP;

   -- Se existem folhas a calcular
   IF vFlag = 1 THEN

     PKGPAG_PRE.PGerarTabelaFolha(pCalculo               => pCalculo,
                                  pNuMesCompetencia      => pNuMesCompetencia,
                                  pNuAnoCompetencia      => pNuAnoCompetencia,
                                  pCdTipoFolha           => pCdTipoFolha,
                                  pCdTipoCalculo         => pCdTipoCalculo,
                                  pFlCalculoDefinitivo   => pFlDefinitivo,
                                  pDtPrevisaoCredito     => pDtPrevisaoCredito,
                                  pNuSequencial          => PKGPAG_VAR.vgFolha.NuSequencialFolha);

   END IF;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedimentos anteriores ao calculo da folha
/*-----------------------------------------------------------------------------------------*/
PROCEDURE PPosCalculoFolha (pCalculo                 IN PKGPAG_CAL.rCalculo,
                            pCdOrgao                 IN INTEGER,
                            pCdFolhaPagamento        IN INTEGER) IS

BEGIN

   -- Atualiza o status do registro de parametros do orgao para "Finalizado"

   -- select ja estava finalizado nao tem problema
   PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao =>pCdOrgao, pInStatus => 2 );

   PKGPAG_PARAM.PArmazenaInfoFolha (pCdFolhaPagamento => pCdFolhaPagamento );

   -----------------------------------------------------------------------------------------------
   -- Gera registros na tabela de folha consolidada
   -----------------------------------------------------------------------------------------------

   IF PKGPAG_VAR.vgFolhaOrigem.CdTipoCalculo IN (7,8,9) THEN

      PConsolidarFolhaPagamento (pCdFolhaPagamento         =>pCdFolhaPagamento,
                                 pCdHistoricoParamCalculo  => pCalculo.CdHistoricoParamCalculo,
                                 pCdFolhaPagamentoSubstit  => PKGPAG_VAR.vgFolha.CdFolhaPagamento);

   ELSE

      PConsolidarFolhaPagamento (pCdFolhaPagamento         => pCdFolhaPagamento,
                                 pCdHistoricoParamCalculo  => pCalculo.CdHistoricoParamCalculo,
                                 pCdFolhaPagamentoSubstit  => NULL);

   END IF;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedimentos posteriores ao calculo sequencial
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PPosCalculoSequencial (pCalculo IN PKGPAG_CAL.rCalculo) IS

BEGIN

   FOR vCal IN ( SELECT DISTINCT cdfolhapagamento,
                                 cdOrgaoExercicio as CdOrgao
                            from ecalvincfolha v
                           WHERE CdCalculo = pCalculo.CdCalculo)
   LOOP

          PPosCalculoFolha (pCalculo                 => pCalculo,
                            pCdOrgao                 => vCal.Cdorgao,
                            pCdFolhaPagamento        => vCal.Cdfolhapagamento);

   END LOOP;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedimentos posteriores ao calculo paralelo
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PPosCalculoParalelo (pCalculo      IN PKGPAG_CAL.rCalculo,
                               pFlDefinitivo IN CHAR) IS

BEGIN

   FOR vCal IN ( SELECT DISTINCT
                    CdOrgao,
                    CdFolhaPagamento
                 FROM ECalCalculo
                 WHERE CdCalculoPai = pCalculo.CdCalculoPai)
   LOOP

          PPosCalculoFolha (pCalculo                 => pCalculo,
                            pCdOrgao                 => vCal.Cdorgao,
                            pCdFolhaPagamento        => vCal.Cdfolhapagamento);

   END LOOP;

   PLiberaFolhas(pCalculo        => pCalculo,
                 pFlDefinitivo   => pFlDefinitivo);

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Verifica se houve pedido de interrupcao do processamento
/*-----------------------------------------------------------------------------------------*/

FUNCTION FInterromperProcessamento(pCalculo IN PKGPAG_CAL.rCalculo)

 RETURN BOOLEAN IS

 vFlInterrupcao CHAR(1);

BEGIN

 IF pCalculo.CdHistoricoParamCalculo <> 0 THEN

   SELECT P.FlInterrupcao
     INTO vFlInterrupcao
     FROM ePagProcFolhaControle P
    WHERE P.CdHistoricoParamCalculo = pCalculo.CdHistoricoParamCalculo;

   IF vFlInterrupcao = 'S' THEN
     RETURN TRUE;

   END IF;

 END IF;

 RETURN FALSE;

EXCEPTION

 WHEN NO_DATA_FOUND THEN

   RETURN FALSE;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Inicializar procedimento de execucao de Jobs
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PInicializarJobs IS

BEGIN
--pInsereLogDebug('t', 37, null);

null; --   vTabJob := tabJob();

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Finalizar um Job individual - Chamado pela tarefa ao concluir e commitar
    Exemplo:

      dbms_lock.sleep(10);
      PFinalizarJob (pJobId,'FIM');
      commit;
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PFinalizarJob (pJobId IN VARCHAR2, PMensagem VARCHAR2 DEFAULT NULL ) IS
  vName VARCHAR2(30);
  vCnt pls_integer;
  vManterLoop boolean;
  vAlertExistiu boolean;
  vErrMsg varchar2(300);

  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  vCnt := 1;
  vName := null;
  vManterLoop := true;
  vAlertExistiu := false;
  while vManterLoop loop
    dbms_session.sleep(1);
    begin
      select dai.name
        into vName
        from sys.dbms_alert_info dai
       where dai.name = pJobId;
      if not vAlertExistiu then
        dbms_alert.signal (pJobId, pMensagem);
        commit;
        vAlertExistiu := true;
      end if;
--pInsereLogDebug('t', 998, pJobId, null);
    exception
    when no_data_found then
--pInsereLogDebug('t', 997, pJobId, null);
      if vAlertExistiu or vCnt > 30 then -- 30 tentativas = 30s, por causa do sleep
        vManterLoop := false;
      end if;
      -- gambi para nao ficar mais sem finalizar calculo
      --  ver documentacao da dbms_alert.set_defaults
      vCnt := vCnt + 1;
    when others then
      vErrMsg := sqlerrm;
--pInsereLogDebug('t', 996, pJobId, vErrMsg);
      null;
    end;
  end loop;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Cria um Job para execucao em paralelo
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PCriarJob (PCdJobId IN VARCHAR2, pCdOrgao IN INTEGER, PComando IN VARCHAR2, PCdCalculo IN INTEGER)  IS

vI       integer;

BEGIN

    IF vTabJob.LAST IS NULL THEN
       vI := 1;
    else
       vI := vTabJob.LAST + 1;
    END IF;

    vTabJob (vI).CdJobId   := PCdJobId;
    vTabJob (vI).CdOrgao   := PCdOrgao;
    vTabJob (vI).CdCalculo := PCdCalculo;

    if substr(PComando, -1) != ';'
    then
        vTabJob (vI).DeComando := PComando || ';';
    else
        vTabJob (vI).DeComando := PComando;
    end if;
--pInsereLogDebug('t', 31, PCdCalculo, PCdJobId);

END;


PROCEDURE PProcessarJobs (pCalculo IN PKGPAG_CAL.rCalculo) IS   
   
   vName              VARCHAR2(30);   
   vMessage           VARCHAR2(255);   
   vStatus            pls_integer;   
   vTimeOut           pls_integer := 600; -- Timeout   
   
   type tArraySeqByJob is table of INTEGER index by VARCHAR2(30);   
   vAlerts            tArraySeqByJob;   
   vJobNum            binary_integer;   
   vInterromper       BOOLEAN;   
   vCdOrgaoFinalizado INTEGER;  
   vProxJob           INTEGER;
   vCdOrgaoExecucao   INTEGER;   
   vNuCalcExecucao    INTEGER;   
   
   PROCEDURE PExecutarJobs IS   
      
      vJobNum    binary_integer;
            
   BEGIN      

      WHILE vProxJob IS NOT NULL LOOP
 
         IF vNuCalcExecucao = 0 THEN 
            
            vCdOrgaoExecucao := vTabJob(vProxJob).cdOrgao;
            
         ELSIF vCdOrgaoExecucao <> vTabJob (vProxJob).CdOrgao THEN
            
            EXIT;
            
         END IF;
         
         -- Limita simultanedade
         
         IF vNuCalcExecucao >= fNuCalculoSimultaneo THEN
         
            EXIT;
         
         END IF;
         
         -- Executar
            
         vNuCalcExecucao := vNuCalcExecucao + 1;
         dbms_job.submit(vJobNum, vTabJob (vProxJob).DeComando); 
                    
         vProxJob := vTabJob.NEXT(vProxJob);   
      END LOOP;
      
      COMMIT;
      
   END;
  
BEGIN 

    if vTabJob.count = 0 THEN -- sem jobs   
       RETURN;   
    END IF;   
   
    vInterromper := FInterromperProcessamento(pCalculo); 
    IF vInterromper THEN
       RETURN;
    END IF;
    
    -- Registrar Alertas a ouvir   
   
    for nIndex in vTabJob.first..vTabJob.last   
    loop   
       dbms_alert.register ( vTabJob (nIndex).CdJobId );   
       vAlerts( vTabJob (nIndex).CdJobId ) :=  vTabJob (nIndex).CdOrgao; -- Recebe o codigo do orgao do calculo   
    end loop;   

    -- Executa primeiros jo    
    
    vNuCalcExecucao  := 0;               
    vProxJob         := vTabJob.first;    
    
    pExecutarJobs;

    -- Aguardar Alertas   
   
    while (vAlerts.count > 0)   
    loop   
       dbms_alert.waitany(vName, vMessage, vStatus, vTimeOut);   
       IF vStatus <> 0 THEN -- timeout   
          NULL; -- Aguardar retorno dos processos   
       ELSE 
          vNuCalcExecucao := vNuCalcExecucao - 1;  
          vCdOrgaoFinalizado := vAlerts (vName);   
          dbms_alert.remove(vName);   
          vAlerts.delete   (vName);   
   
          IF NOT vInterromper THEN -- Processo ja nao estava em interrupcao   
   
             vInterromper := FInterromperProcessamento(pCalculo);   
   
             IF vInterromper THEN -- interromper, cancelar execucoes pendentes   
               IF vProxJob IS NOT NULL THEN -- existem jobs restantes   
                   FOR jIndex IN vProxJob .. vTabJob.last   
                   LOOP   
                      dbms_alert.remove( vTabJob (jIndex).CdJobId);   
                      vAlerts.delete( vTabJob (jIndex).CdJobId);   
                   END LOOP;   
                   vProxJob := NULL;   
               END IF;   
             ELSE  -- nao interromper ,submeter jobs restantes select existir   
   
               -- Finaliza situacao do calculo folha do orgao se nao tem mais jobs para ela   
               vName := vAlerts.FIRST;   
               WHILE vName IS NOT NULL   
               LOOP   
                 IF vAlerts (vName) = vCdOrgaoFinalizado THEN -- ainda falta concluir   
                    vCdOrgaoFinalizado := NULL;   
                    EXIT;   
                 END IF;   
                 vName := vAlerts.NEXT(vName);   
               END LOOP;   
   
               -- se deve finalizar o orgao   
               IF vCdOrgaoFinalizado IS NOT NULL THEN   
                  PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoFinalizado, pInStatus => 2 );   
               END IF;   
   
               IF vProxJob IS NOT NULL THEN -- existem jobs restantes   
   
                  PExecutarJobs;
                  
               END IF;   
   
             END IF;   
           END IF;   
       END IF;   
    end loop;   
   
END;
PROCEDURE PSubmeterJobCalculo(rJob IN recJob) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  vJobNum  binary_integer;
BEGIN

  dbms_job.submit(vJobNum, rJob.DeComando);

  update ecalcalculo set
         jobid = vJobNum
   where cdcalculo = rJob.CdCalculo;

  commit;
END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Executar Jobs
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PExecutarJobs IS
  --vJobNum  binary_integer;
BEGIN

    vProxJob := 0;
    IF vTabJob.first IS NOT NULL THEN
        for nIndex in vTabJob.first..vTabJob.last
        loop

           vProxJob :=nIndex;
           if vProxJob > fNuCalculoSimultaneo THEN
             EXIT;
           END IF;

           PSubmeterJobCalculo(vTabJob(nIndex));

           vProxJob := 0;
        end loop;
    end if;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Aguardar conclusao dos Jobs criados
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PAguardarJobs (pCalculo IN PKGPAG_CAL.rCalculo) IS

  vName              VARCHAR2(30);
  vMessage           VARCHAR2(255);
  vStatus            pls_integer;
  vIntAux            pls_integer;

  type tArraySeqByJob is table of INTEGER index by VARCHAR2(30);
  vAlerts            tArraySeqByJob;
  --vJobNum            binary_integer;
  vInterromper       BOOLEAN;
  vCdOrgaoFinalizado INTEGER;

  vDtIniMonitoramento date;
  vTempoMonitoramento pls_integer; -- em segundos
  vTempoMinimoParaMonitorar pls_integer := 540; -- em segundos; só começa a monitorar depois desse tempo
  vQtPessoasCalculadas pls_integer;

BEGIN
 
  vName := null;
  vInterromper := FALSE;

  if vTabJob.count = 0 THEN -- sem jobs
     RETURN;
  END IF;

  -- Registrar Alertas a ouvir

  for nIndex in vTabJob.first..vTabJob.last
  loop
--pInsereLogDebug('t', 20, pCalculo.CdCalculo, nIndex);
     dbms_alert.register ( vTabJob (nIndex).CdJobId );
     vAlerts( vTabJob (nIndex).CdJobId ) :=  vTabJob (nIndex).CdOrgao; -- Recebe o codigo do orgao do calculo
  end loop;

  if pkgpag_param.fCDBName = 'PDB_SIGRH' -- para fazer sempre o monitoramento nas bases de desenvolvimento
     and to_number(to_char(sysdate, 'HH24MI')) between 1300 and 1900 -- nao monitorar processamentos iniciados em horario de expediente
  then
    vDtIniMonitoramento := null;
  else
    vDtIniMonitoramento := sysdate;
    begin
      select hpc.qtpessoas
        into vIntAux
        from epaghistoricoparamcalculo hpc
       where hpc.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
         and hpc.cdagrupamento in (1, 134);
    exception
    when no_data_found then
      vIntAux := 0;
    end;
    if vIntAux <= 5000 then
      -- conforme regra da pkgpag_monitoramento.qtd_calculos_em_andamento,
      --   considerar apenas processamentos com mais de 5000 pessoas
      vDtIniMonitoramento := null;
    end if;
  end if;
  if vDtIniMonitoramento is not null and fNuCalculoSimultaneo < 10 then
    pkgpag_tipo.cnQtMediaPessoasPorSegundo := 4;
  end if;

  -- Aguardar Alertas
  while (vAlerts.count > 0)
  loop
--pInsereLogDebug('t', 11, pCalculo.CdCalculo, pCalculo.CdHistoricoParamCalculo);
     dbms_alert.waitany(vName, vMessage, vStatus, pkgpag_tipo.cnTimeOutEscutaSinalJobs);

     -- monitoramento de qtde de pessoas calculadas
     if vDtIniMonitoramento is not null then
       vTempoMonitoramento := (sysdate - vDtIniMonitoramento) * 24 * 60 * 60;
       if vTempoMonitoramento > vTempoMinimoParaMonitorar then
         vQtPessoasCalculadas := 999; -- .fQtdePessoasCalculadas(pCalculo.CdHistoricoParamCalculo);
         if vQtPessoasCalculadas < vTempoMonitoramento * pkgpag_tipo.cnQtMediaPessoasPorSegundo then
           begin
             select m.quantidade
               into vIntAux
               from eadmmonitoramento m
              where m.tipo = 'MPFP'
                and m.parametro = 'BQPC'
                and m.chave = 'CDHISTORICOPARAMCALCULO'
                and to_number(m.valor) = pCalculo.CdHistoricoParamCalculo;
           exception
           when no_data_found then
             vIntAux := 0;
           when others then
             vIntAux := 2;
           end;
           if vIntAux <= 0 then
             pkgpag_monitoramento.p_insere_reg_monitoramento('MPFP', 'BQPC', 'CDHISTORICOPARAMCALCULO', pCalculo.CdHistoricoParamCalculo, 1);
           end if;
         end if;
       end if;
     end if;

--pInsereLogDebug('t', 21, pCalculo.CdCalculo, null, vName, vStatus);
     IF vStatus <> 0 THEN -- timeout
        NULL; -- Aguardar retorno dos processos
     ELSE
--pInsereLogDebug('t', 22, pCalculo.CdCalculo, null, vName, vStatus);

        vCdOrgaoFinalizado := vAlerts (vName);
        dbms_alert.remove(vName);
        vAlerts.delete   (vName);

        IF NOT vInterromper THEN -- Processo ja nao estava em interrupcao

--pInsereLogDebug('t', 23, pCalculo.CdCalculo, null, vName, vStatus);

           vInterromper := FInterromperProcessamento(pCalculo);

           IF vInterromper THEN -- interromper, cancelar execucoes pendentes
             IF vProxJob <> 0 THEN -- existem jobs restantes
                 FOR jIndex IN vProxJob .. vTabJob.last
                 LOOP
--pInsereLogDebug('t', 24, pCalculo.CdCalculo, jIndex, vName, vStatus);
                    dbms_alert.remove( vTabJob (jIndex).CdJobId);
                    vAlerts.delete( vTabJob (jIndex).CdJobId);
                 END LOOP;
                 vProxJob := 0;
             END IF;
           ELSE  -- nao interromper ,submeter jobs restantes select existir

--pInsereLogDebug('t', 25, pCalculo.CdCalculo, null, vName, vStatus);

             -- Finaliza situacao do calculo folha do orgao se nao tem mais jobs para ela
             vName := vAlerts.FIRST;
             WHILE vName IS NOT NULL
             LOOP
               IF vAlerts (vName) = vCdOrgaoFinalizado THEN -- ainda falta concluir
                  vCdOrgaoFinalizado := NULL;
                  EXIT;
               END IF;
               vName := vAlerts.NEXT(vName);
             END LOOP;

             -- se deve finalizar o orgao
             IF vCdOrgaoFinalizado IS NOT NULL THEN
                PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => vCdOrgaoFinalizado, pInStatus => 2 );
             END IF;

             IF vProxJob <> 0 THEN -- existem jobs restantes

--pInsereLogDebug('t', 26, pCalculo.CdCalculo, null, vName, vStatus);

                 -- Submete proximo job
                 PSubmeterJobCalculo(vTabJob(vProxJob));

                 commit;

                 vProxJob := vProxJob + 1;
                 if vProxJob > vTabJob.last THEN
                    vProxJob := 0;
                 end if;

             END IF;

           END IF;
         END IF;
     END IF;
  end loop;

exception
when others then
  --pInsereLogDebug('t', 99, sqlerrm);
  null;
END;

PROCEDURE PTraceTKPROF  (pBlLigar IN BOOLEAN, pID VARCHAR2 DEFAULT NULL) IS

vNomeArquivo VARCHAR2(50);

BEGIN

  IF pBlLigar THEN

     BEGIN

      select 'x' || to_char(sysdate , 'yyyymmddhh24mi') || '_' ||
            replace(replace(replace(Replace(SUBSTR(banner,1,19),'Oracle'),'Enterprise'),'Database'),' ')
            || nvl2(pID, '_' || pID,'')
        into vNomeArquivo
        from v$version
        where banner like 'Oracle%';

       EXCEPTION
         WHEN OTHERS THEN
           vNomeArquivo := '20110000_XX';

     END;

     execute immediate  'ALTER SESSION SET sql_trace = true';
     execute immediate  'ALTER SESSION SET tracefile_identifier =''' || vNomeArquivo || '''';

  ELSE
     execute immediate  'ALTER SESSION SET sql_trace = false';
  END IF;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Executar o paralelismo na folha
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PProcessarSequencial(pCalculo                   IN PKGPAG_CAL.rCalculo,
                               pCdAgrupamento             IN EPagHistoricoParamCalculo.CdAgrupamento%TYPE,
                               pDtCalculo                 IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                               pNuMesCompetencia          IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                               pNuAnoCompetencia          IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                               pCdTipoCalculo             IN EPagHistoricoParamCalculo.CdTipoCalculo%TYPE,
                               pFlDefinitivo              IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                               pFlPagaAdiantamento13sal   IN EPagHistoricoParamCalculo.FlPagaAdiantamento13sal%TYPE,
                               pDtPrevistaCredito         IN EPagHistoricoParamCalculo.DtPrevistaCredito%TYPE,
                               pVlDiferencaValor          IN EPagHistoricoParamcalculo.vlDiferencaValor%TYPE,
                               pCdTipoFolha               IN EPagTipoFolha.CdTipoFolha%TYPE,
                               pLog                       IN BOOLEAN,
                               pTrace                     IN BOOLEAN,
                               pCalculoRetorno           OUT PKGPAG_CAL.rCalculoRetorno) IS

BEGIN

   PKGPAG_GERAL.PLogProcIni ('TAR03','PreCalculoSequencial');

   PPreCalculoSequencial (pCalculo             => pCalculo,
                      pCdAgrupamento       => pCdAgrupamento,
                      pFlDefinitivo        => pFlDefinitivo,
                      pNuMesCompetencia    => pNuMesCompetencia,
                      pNuAnoCompetencia    => pNuAnoCompetencia,
                      pDtCalculo           => pDtCalculo,
                      pDtPrevistaCredito   => pDtPrevistaCredito,
                      pCdTipoFolha         => pCdTipoFolha,
                      pCdTipoCalculo       => pCdTipoCalculo,
                      pFlLog               => 'S');

   PKGPAG_GERAL.PLogProc ('TAR03','TAR04','CalculoSequencial');

   IF pCdTipoFolha IN ( PKGPAG_TIPO.cnTpFolha13
                      , PKGPAG_TIPO.cnTpFolhaAdiant13
                      , PKGPAG_TIPO.cnTpFolhaResidente13
                      , PKGPAG_TIPO.cnTpFolhaFunebre13
                      , PKGPAG_TIPO.cntpfolha13
                      , pkgpag_tipo.cnTpFolhaCtisp13
                      , pkgpag_tipo.cnTpFolhaAdiant13Ctisp
                      , pkgpag_tipo.cnTpFolhaProdex13
                      , pkgpag_tipo.cnTpFolhaHonorarios13
                      , pkgpag_tipo.cnTpFolhaHonorarProcuradores13) THEN

             PKGPAG_DT.PProcessarCalculo13Salario  (pCalculo                   => pCalculo,
                                                    pDtCalculo                 => pDtCalculo,
                                                    pFlDefinitivo              => pFlDefinitivo ,
                                                    pLog                       => pLog,
                                                    pTrace                     => pTrace,
                                                    pCalculoRetorno            => pCalculoRetorno);


   ELSE -- Folha Normal

     PKGPAG_CAL.PProcessarCalculoNormal    (pCalculo                   => pCalculo,
                                            pDtCalculo                 => pDtCalculo,
                                            pFlDefinitivo              => pFlDefinitivo ,
                                            pFlPagaAdiantamento13sal   => pFlPagaAdiantamento13sal,
                                            pVlDiferencaValor          => pVlDiferencaValor,
                                            pLog                       => pLog,
                                            pTrace                     => pTrace,
                                            pCalculoRetorno            => pCalculoRetorno);

   END IF;

   PKGPAG_GERAL.PLogProc ('TAR04','TAR05','PosCalculoSequencial');

   PPosCalculoSequencial (pCalculo);

   PKGPAG_GERAL.PLogProcFim ('TAR05');
   
END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Executar o paralelismo na folha
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PProcessarParalelo(pCalculo                   IN PKGPAG_CAL.rCalculo,
                             pCdAgrupamento             IN EPagHistoricoParamCalculo.CdAgrupamento%TYPE,
                             pDtCalculo                 IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                             pNuMesCompetencia          IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                             pNuAnoCompetencia          IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                             pCdTipoCalculo             IN EPagHistoricoParamCalculo.CdTipoCalculo%TYPE,
                             pFlDefinitivo              IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                             pFlPagaAdiantamento13sal   IN EPagHistoricoParamCalculo.FlPagaAdiantamento13sal%TYPE,
                             pDtPrevistaCredito         IN EPagHistoricoParamCalculo.DtPrevistaCredito%TYPE,
                             pFlGeraFolhaBackup         IN EPagHistoricoParamcalculo.FlSalvarValoresCalculoVigente%TYPE,
                             pVlDiferencaValor          IN EPagHistoricoParamcalculo.vlDiferencaValor%TYPE,
                             pCdTipoFolha               IN EPagTipoFolha.CdTipoFolha%TYPE,
                             pLog                       IN BOOLEAN,
                             pTrace                     IN BOOLEAN) IS

   vCdJobId       VARCHAR2(30);
   vLog           CHAR(1);
   vTrace         CHAR(1);
   vQtPessoasPart NUMBER;
   vCdCalculo     NUMBER;

BEGIN

    PKGPAG_GERAL.PLogProcIni ('TAR03','Segmentacao');

    vQtPessoasPart:= 250; --  power (10,15) - 1; -- 99999999999999 pessoas

    IF cTraceTKPROF = 'S' THEN
       vQtPessoasPart:=  power (10,15) - 1; -- 99999999999999 pessoas
    END IF;

    vLog   := 'N';
    vTrace := 'N';
    if pLog THEN
       vLog := 'S';
    END IF;

    if pTrace THEN
       vTrace := 'S';
    END IF;

    PInicializarJobs;

    -- Dividir por folhas de pagamento

    FOR fol in (  select CdFolhapagamento,
                         CdOrgaoExercicio as CdOrgao,
                         Particao,
                         decode(ordem, 1, 0, cdpessoa) as cdpessoaMin,
                         lead(cdpessoa, 1, power(10, 15)) over (partition by cdfolhapagamento, cdOrgaoExercicio order by cdfolhapagamento, cdpessoa) - 1 as cdpessoaMax

                    from (select cdfolhapagamento,
                                 cdOrgaoExercicio,
                                 cdpessoa,
                                 trunc((row_number()
                                        over(partition by cdfolhapagamento, cdOrgaoExercicio order by cdpessoa) - 1) /  vQtPessoasPart) + 1 as particaoant,
                                 trunc((row_number()
                                        over(partition by cdfolhapagamento, cdOrgaoExercicio order by cdpessoa)) / vQtPessoasPart) + 1 as particao,
                                 row_number() over(partition by cdfolhapagamento, CdOrgaoExercicio order by cdpessoa) as ordem
                            from ecalvincfolha v
                            WHERE CdCalculo = pCalculo.CdCalculo
                          )
                   where particaoant <> particao or ordem = 1
                   order by cdfolhapagamento, particao
                  )
    LOOP

      INSERT INTO ECalCalculo
          ( CdCalculo,
            CdCalculoPai,
            CdTarefa,
            CdHistoricoParamCalculo,
            CdFolhaPagamento,
            CdOrgao,
            FlGeral,
            InTipoExecucao,
            CdPessoaMin,
            CdPessoaMax,
            CDAGRUPAMENTO,
            DTCALCULO,
            NUMESCOMPETENCIA,
            NUANOCOMPETENCIA,
            CDTIPOCALCULO,
            FLDEFINITIVO,
            FLPAGAADIANTAMENTO13SAL,
            DTPREVISTACREDITO,
            FLSALVARVALORESCALCULOVIGENTE,
            VLDIFERENCAVALOR,
            FlLog,
            FlTrace)
         VALUES
          ( SCalCalculo.NEXTVAL,
            pCalculo.CdCalculoPai,
            pCalculo.CdTarefa,
            pCalculo.CdHistoricoParamCalculo,
            fol.CdFolhaPagamento,
            fol.CdOrgao,
            pCalculo.FlGeral,
            pCalculo.InTipoExecucao,
            fol.CdPessoaMin,
            fol.CdPessoaMax,
            pCdAgrupamento,
            pDtCalculo,
            pNuMesCompetencia,
            pNuAnoCompetencia,
            pCdTipoCalculo,
            pFlDefinitivo,
            pFlPagaAdiantamento13sal,
            pDtPrevistaCredito,
            pFlGeraFolhaBackup,
            pVlDiferencaValor,
            vLog,
            vTrace)
            RETURNING CdCalculo
            into vCdCalculo;

      vCdJobId := 'J' || vCdCalculo ;

      UPDATE Ecalvincfolha
         set CdCalculoPai = pCalculo.CdCalculoPai,
             CdCalculo = vCdCalculo
       WHERE CdCalculo = pCalculo.CdCalculoPai
         AND CdFolhaPagamento = fol.CdFolhaPagamento
         and CdPessoa between fol.CdPessoaMin and fol.CdPessoaMax;

       IF pCdTipoFolha IN ( PKGPAG_TIPO.cnTpFolha13
                          , PKGPAG_TIPO.cnTpFolhaAdiant13
                          , PKGPAG_TIPO.cnTpFolhaResidente13
                          , pkgpag_tipo.cnTpFolhaCtisp13
                          , pkgpag_tipo.cnTpFolhaAdiant13Ctisp
                          , pkgpag_tipo.cnTpFolhaProdex13
                          , pkgpag_tipo.cnTpFolhaHonorarios13
                          , pkgpag_tipo.cnTpFolhaHonorarProcuradores13) THEN


             PCriarJob (vCdJobId,fol.CdOrgao,'PKGPAG_DT.PProcessarCalculo13Salario (pCdJobId => ''' || vCdJobId
                                                                          || ''', pCdCalculo => ' || vCdCalculo
                                                                         || ');', vCdCalculo);



       ELSE -- Folha Normal
--pInsereLogDebug('t', 35, vCdCalculo);

          PCriarJob (vCdJobId,fol.CdOrgao,'PKGPAG_CAL.PProcessarCalculoNormal (pCdJobId => ''' || vCdJobId
                                                                       || ''', pCdCalculo => ' || vCdCalculo
                                                                       || ');', vCdCalculo);

       END IF;

    END LOOP;

    COMMIT;

    PKGPAG_GERAL.PLogProc ('TAR03','TAR04','PreCalculo');

    PPreCalculoParalelo (pCalculo             => pCalculo,
                         pFlDefinitivo        => pFlDefinitivo,
                         pNuMesCompetencia    => pNuMesCompetencia,
                         pNuAnoCompetencia    => pNuAnoCompetencia,
                         pCdTipoFolha         => pCdTipoFolha,
                         pCdTipoCalculo       => pCdTipoCalculo,
                         pDtPrevisaoCredito   => pDtPrevistaCredito);

    PKGPAG_GERAL.PLogProc ('TAR04','TAR05','ExecutarJobs');

    PProcessarJobs (pCalculo             => pCalculo);
   /* PExecutarJobs;

    COMMIT;

    PAguardarJobs (pCalculo);
*/
    PKGPAG_GERAL.PLogProc ('TAR05','TAR06','PosCalculo');

    PPosCalculoParalelo (pCalculo       => pCalculo,
                         pFlDefinitivo  => pFlDefinitivo);

    PKGPAG_GERAL.PLogProcFim ('TAR06');
--pInsereLogDebug('t', 36, vCdCalculo);

END;


/*-----------------------------------------------------------------------------------------/
    Objetivo: Atualizar Contadores dos Orgaos
/*-----------------------------------------------------------------------------------------*/

PROCEDURE  PIniciarContadores (pCalculo IN PKGPAG_CAL.rCalculo) IS

BEGIN

   -- Inicializar
   IF pCalculo.InTipoExecucao = 1 THEN
      PAtualizaParametroConsulta(pCalculo => pCalculo, pQtPessoasACalcular => -1 );
   ELSE
      PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => 0, pQtPessoasACalcular => -1 );
   END IF;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Atualizar Contadores dos Orgaos
/*-----------------------------------------------------------------------------------------*/

FUNCTION  FAtualizarContadores (pCalculo IN PKGPAG_CAL.rCalculo)
             RETURN INTEGER IS

   vQtTotalPessoas            INTEGER;

BEGIN

   vQtTotalPessoas := 0;
   
   IF pCalculo.InTipoExecucao = 2 THEN   
   
      FOR vTotOrgao IN ( SELECT CdOrgao, COUNT(*) as QtPessoasACalcular
                           FROM   (SELECT DISTINCT cdfolhapagamento,
                                                   cdorgaoexercicio as cdorgao,
                                                   cdpessoa
                                          FROM Ecalvincfolha
                                          WHERE CdCalculo = pCalculo.CdCalculo  )
                           GROUP BY CdOrgao) LOOP

        PAtualizaParametroExecucao(pCalculo            => pCalculo,
                                   pCdOrgao            => vTotOrgao.CdOrgao,
                                   pQtPessoasACalcular => vTotOrgao.QtPessoasACalcular);

        vQtTotalPessoas := vQtTotalPessoas + vTotOrgao.QtPessoasACalcular;
          
      END LOOP;


   ELSE
      
      SELECT SUM(qtpessoas)
        INTO vQtTotalPessoas
        FROM EPagHistoricoParamCalculoOrgao po
       WHERE po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo;
 
   END IF;

    -- Atualiza a tabela de parametros com o numero total de pessoas
    -- e atualiza para zero os orgaos nos quais nao foram encontradas pessoas

   IF pCalculo.InTipoExecucao = 1 THEN
      PAtualizaParametroConsulta(pCalculo => pCalculo, pQtPessoasACalcular => vQtTotalPessoas );
    ELSE
      PAtualizaParametroExecucao(pCalculo => pCalculo, pCdOrgao => 0, pQtPessoasACalcular => vQtTotalPessoas );
   END IF;

   RETURN vQtTotalPessoas;

END;

FUNCTION FExisteCalculoDefinitivo ( pCdHistoricoParamCalculo   IN EPagHistoricoParamCalculo.CdHistoricoParamCalculo%TYPE,
                                    pNuAnoCompetencia          IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                                    pNuMesCompetencia          IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                                    pCdTipoFolhaPagamento      IN EPagHistoricoParamCalculo.CdTipoFolhaPagamento%TYPE)
  RETURN BOOLEAN IS

  vCont INTEGER;

BEGIN

    SELECT 1
      INTO vCont
      FROM epaghistoricoparamcalculoorgao po
     INNER JOIN epagfolhapagamento fp
        ON po.cdorgao = fp.cdorgao
            AND po.cdhistoricoparamcalculo = pCdHistoricoParamCalculo
            AND fp.nuanoreferencia = pNuAnoCompetencia
            AND fp.numesreferencia = pNuMesCompetencia
            AND fp.cdtipofolhapagamento = pCdTipoFolhaPagamento
            AND fp.cdtipocalculo = PKGPAG_TIPO.cnTpCalculoNormal
            AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS
            AND ROWNUM < 2;

    RETURN TRUE;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN FALSE;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Salvar calculo anterior ou apagar conforme solicitado
/*-----------------------------------------------------------------------------------------*/
PROCEDURE PLimparCalculosAnteriores ( pCalculo                   IN PKGPAG_CAL.rCalculo,
                                      pNuMesCompetencia          IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                                      pNuAnoCompetencia          IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                                      pCdTipoFolhaPagamento      IN EPagHistoricoParamCalculo.CdTipoFolhaPagamento%TYPE,
                                      pNuSequencial              IN EPagHistoricoParamCalculo.NuSequencial%TYPE,
                                      pCdTipoCalculo             IN EPagHistoricoParamCalculo.CdTipoCalculo%TYPE,
                                      pFlGeraFolhaBackup         IN EPagHistoricoParamcalculo.FlSalvarValoresCalculoVigente%TYPE)

  IS

  bFolhaCalculoVazia  BOOLEAN;

  bCalculandoNormal   BOOLEAN;

  vCdFolhaCalculo     INTEGER;

  vCdFolhaNormal      INTEGER;

  vTmp                INTEGER;

  vNuSeqNormal        INTEGER;

BEGIN

   IF pCalculo.FlGeral = 'S' THEN  -- Nao executa tambem para individual

      IF pCdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal THEN
         vNuSeqNormal := pNuSequencial;
      ELSE
         vNuSeqNormal := 1;
      END IF;

      FOR rec IN (SELECT fp.cdOrgao,
                         fp.cdfolhapagamento AS CdFolhaCalculo,
                         fpnor.CdFolhaPagamento as CdFolhaNormal
                    FROM epaghistoricoparamcalculoorgao po
                    INNER JOIN epagfolhapagamento fp
                           ON po.cdorgao = fp.cdorgao
                          AND po.cdhistoricoparamcalculo = pCalculo.CdHistoricoParamCalculo
                          AND fp.nuanoreferencia = pNuAnoCompetencia
                          AND fp.numesreferencia = pNuMesCompetencia
                          AND fp.cdtipofolhapagamento = pCdTipoFolhaPagamento
                          AND fp.cdtipocalculo = pCdTipoCalculo
                          AND fp.nusequencialfolha = pNuSequencial
                    LEFT JOIN EPagFolhaPagamento fpnor
                          ON fpnor.CdOrgao = fp.CdOrgao
                          AND fpnor.CdTipoFolhaPagamento = fp.CdTipoFolhaPagamento
                          AND fpnor.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal
                          AND fpnor.NuANoReferencia = fp.nuanoreferencia
                          AND fpnor.NuMesReferencia = fp.numesreferencia
                          AND fpnor.NuSequencialFolha = vNuSeqNormal
                          AND fpnor.flcalculodefinitivo <> 'S'  --  #80191
                   order by fpnor.DeOrdemExecucao,fp.DeOrdemExecucao) LOOP

         -- Obtem Folhas
         vCdFolhaCalculo := rec.CdFolhaCalculo;
         vCdFolhaNormal  := rec.CdFolhaNormal;

         -- Verifica se o calculo e de tipo calculo normal

         IF vCdFolhaCalculo = vCdFolhaNormal THEN
            bCalculandoNormal := TRUE;
         ELSE
            bCalculandoNormal := FALSE;
         END IF;

         bFolhaCalculoVazia := FALSE;

         -- Verifica se vai tirar Backup em tipo calculo: Anterior,
         --  tirar Backup em tipo calculo: Excluido
         --  ou vai apenas apagar a folha atual

         IF pCdTipoCalculo in (PKGPAG_TIPO.cnTpCalculoNormal,
                               PKGPAG_TIPO.cnTpCalculoPrimeiro,
                               PKGPAG_TIPO.cnTpCalculoSegundo,
                               PKGPAG_TIPO.cnTpCalculoPrevia) THEN

            -- O backup e sempre do TipoCalculo Normal, mesmo que seja Tipocalculo 1a , 2a , Previa

            PKGPAG_GERAL.PLogProcIni ('TAR0001','GeraBackup');

            IF pFlGeraFolhaBackup = 'S' THEN -- Backup em tipo calculo: Anterior

               vCdFolhaNormal := FArmazenaCalculoAnterior( pCdFolhaPagamento  => vCdFolhaNormal,
                                                           pCdTipoCalculoNovo => PKGPAG_TIPO.cnTpCalculoAnterior);

            ELSE -- Backup em tipo calculo: Excluido

               vCdFolhaNormal := FArmazenaCalculoAnterior( pCdFolhaPagamento  => vCdFolhaNormal,
                                                           pCdTipoCalculoNovo => PKGPAG_TIPO.cnTpCalculoExcluido);
            END IF;

            IF bCalculandoNormal THEN
               bFolhaCalculoVazia :=  TRUE; -- Indica que a folha ja esta apagada pelo backup
               vCdFolhaCalculo    := vCdFolhaNormal;
            END IF;

            PKGPAG_GERAL.PLogProcFim ('TAR0001');
            
         END IF;

         ----------------------------------------------------------------------------
         -- Caso a folha do calculo nao esteja vazia
         ----------------------------------------------------------------------------

         IF NOT bFolhaCalculoVazia THEN

           PKGPAG_GERAL.PLogProcIni ('TAR0002','ExcluirFolhaPagamento');

           vTmp := FExcluirFolhaPagamento(vCdFolhaCalculo);

           PKGPAG_GERAL.PLogProcFim ('TAR0002');
           
         END IF;

      END LOOP;

   END IF;

   COMMIT;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure de execucao
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PExecutarTarefa(pCalculo                   IN PKGPAG_CAL.rCalculo,
                          pCdAgrupamento             IN EPagHistoricoParamCalculo.CdAgrupamento%TYPE,
                          pCdRelacaoTrabalho         IN EPagHistoricoParamCalculo.CdRelacaoTrabalho%TYPE,
                          pCdSituacaoPrevidenciaria  IN EPagHistoricoParamCalculo.CdSituacaoPrevidenciaria%TYPE,
                          pCdUnidadeOrganizacional   IN EPagHistoricoParamCalculo.CdUnidadeOrganizacional%TYPE,
                          pInSubordinadas            IN EPagHistoricoParamCalculo.InSubordinadas%TYPE,
                          pDtCalculo                 IN EPagHistoricoParamCalculo.DtCalculo%TYPE,
                          pNuMesCompetencia          IN EPagHistoricoParamCalculo.NuMesCompetencia%TYPE,
                          pNuAnoCompetencia          IN EPagHistoricoParamCalculo.NuAnoCompetencia%TYPE,
                          pCdTipoFolhaPagamento      IN EPagHistoricoParamCalculo.CdTipoFolhaPagamento%TYPE,
                          pNuSequencial              IN EPagHistoricoParamCalculo.NuSequencial%TYPE,
                          pCdTipoCalculo             IN EPagHistoricoParamCalculo.CdTipoCalculo%TYPE,
                          pFlDefinitivo              IN EPagHistoricoParamCalculo.FlDefinitivo%TYPE,
                          pFlPagaAdiantamento13sal   IN EPagHistoricoParamCalculo.FlPagaAdiantamento13sal%TYPE,
                          pDtPrevistaCredito         IN EPagHistoricoParamCalculo.DtPrevistaCredito%TYPE,
                          pFlGeraFolhaBackup         IN EPagHistoricoParamcalculo.FlSalvarValoresCalculoVigente%TYPE,
                          pVlDiferencaValor          IN EPagHistoricoParamcalculo.vlDiferencaValor%TYPE,
                          pCdTipoFolha               IN EPagTipoFolha.Cdtipofolha%TYPE,
                          pFlIncluiBolsista          IN EPagHistTipoFolhaPagamento.FlIncluiBolsista%TYPE,
                          pFlIncluiAposentado        IN EPagHistTipoFolhaPagamento.FlIncluiAposentado%TYPE,
                          pFlVinculo                IN CHAR) IS

   vQtTotalPessoas            INTEGER;
   vCalculoRetorno            PKGPAG_CAL.rCalculoRetorno;
   vCdTipoFolhaPagamento13    INTEGER;

BEGIN

   PKGPAG_GERAL.PLogProcIni ('TAR','PACKAGE TAR');

   PKGPAG_GERAL.PLogProcIni ('TAR00','PLimparCalculosAnteriores');

   PLimparCalculosAnteriores (pCalculo                   => pCalculo,
                              pNuMesCompetencia          => pNuMesCompetencia,
                              pNuAnoCompetencia          => pNuAnoCompetencia,
                              pCdTipoFolhaPagamento      => pCdTipoFolhaPagamento,
                              pNuSequencial              => pNuSequencial,
                              pCdTipoCalculo             => pCdTipoCalculo,
                              pFlGeraFolhaBackup         => pFlGeraFolhaBackup);

   IF pCdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaAdiant13,PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp) THEN
     
      SELECT TFP.cdTipoFolhaPagamento
        INTO vCdTipoFolhaPagamento13
        FROM EPagTipoFolhaPagamento TFP
       WHERE TFP.cdAgrupamento = pCdAgrupamento
         AND TFP.cdTipoFolha = DECODE(pCdTipoFolha,PKGPAG_TIPO.cnTpFolhaAdiant13, PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaCtisp13);                                    

      PLimparCalculosAnteriores (pCalculo                   => pCalculo,
                                 pNuMesCompetencia          => pNuMesCompetencia,
                                 pNuAnoCompetencia          => pNuAnoCompetencia,
                                 pCdTipoFolhaPagamento      => vCdTipoFolhaPagamento13,
                                 pNuSequencial              => pNuSequencial,
                                 pCdTipoCalculo             => pCdTipoCalculo,
                                 pFlGeraFolhaBackup         => pFlGeraFolhaBackup);
   END IF;

   PKGPAG_GERAL.PLogProc('TAR00','TAR01','PGerarRelVincFolha');
   
   -- Gera vinculos para processamento

   PKGPAG_PRE.PGerarRelVincFolha  ( pCalculo                            => pCalculo,
                                    pNuMesCompetencia                   => pNuMesCompetencia,
                                    pNuAnoCompetencia                   => pNuAnoCompetencia,
                                    pCdSituacaoPrevidenciaria           => pCdSituacaoPrevidenciaria,
                                    pCdRelacaoTrabalho                  => pCdRelacaoTrabalho,
                                    pCdTipoFolha                        => pCdTipoFolha,
                                    pCdTipoFolhaPagamento               => pCdTipoFolhaPagamento,
                                    pFlCalculoDefinitivo                => pFlDefinitivo,
                                    pDtCalculo                          => pDtCalculo,
                                    pFlIncluiBolsista                   => pFlIncluiBolsista,
                                    pFlIncluiAposentado                 => pFlIncluiAposentado,
                                    pInSubordinadas                     => pInSubordinadas,
                                    pCdUnidadeOrganizacional            => pCdUnidadeOrganizacional,
                                    pCdTipoCalculo                      => pCdTipoCalculo,
                                    pNuSequencial                       => pNuSequencial,
                                    pFlVinculo                          => pFlVinculo,
                                    pCdFolhaPagamento                   => NULL,
                                    pCdVinculo                          => NULL,
                                    pCdOrgao                            => NULL,
                                    pCdPessoa                           => NULL,
                                    pCdAgrupamento                      => pCdAgrupamento);

   PKGPAG_GERAL.PLogProc ('TAR01','TAR02','Atualiz Cont');

   -- Atualiza contadores

   vQtTotalPessoas := FAtualizarContadores (pCalculo   => pCalculo);

   if vQtTotalPessoas = 0 then
     PKGPAG_GERAL.PInsereLog(true,
                              pCalculo.CdHistoricoParamCalculo,
                              null,
                              'Não foram selecionadas matrículas para este processamento conforme critérios do cálculo!',
                               null);
    PErroTarefa(pCalculo.CdHistoricoParamCalculo, pCalculo.CdTarefa);
   end if;

   PKGPAG_GERAL.PLogProcFim ('TAR02');
   
   --------------------------------------------------------------------------------------------------------
   -- Executa o calculo dos registros selecionados
   --------------------------------------------------------------------------------------------------------

   IF fNuCalculoSimultaneo > 1 and cTraceTKPROF = 'N' THEN -- Calculo em Paralelo

       PProcessarParalelo                (pCalculo                   =>  pCalculo,
                                          pCdAgrupamento             =>  pCdAgrupamento,
                                          pDtCalculo                 =>  pDtCalculo,
                                          pNuMesCompetencia          =>  pNuMesCompetencia,
                                          pNuAnoCompetencia          =>  pNuAnoCompetencia,
                                          pCdTipoCalculo             =>  pCdTipoCalculo,
                                          pFlDefinitivo              =>  pFlDefinitivo ,
                                          pFlPagaAdiantamento13sal   =>  pFlPagaAdiantamento13sal,
                                          pDtPrevistaCredito         =>  pDtPrevistaCredito,
                                          pFlGeraFolhaBackup         =>  pFlGeraFolhaBackup,
                                          pVlDiferencaValor          =>  pVlDiferencaValor,
                                          pCdTipoFolha               =>  pCdTipoFolha,
                                          pLog                       =>  true,
                                          pTrace                     =>  false);

    ELSE   -- Calculo Sequencial

       PProcessarSequencial              (pCalculo                   =>  pCalculo,
                                          pCdAgrupamento             =>  pCdAgrupamento,
                                          pDtCalculo                 =>  pDtCalculo,
                                          pNuMesCompetencia          =>  pNuMesCompetencia,
                                          pNuAnoCompetencia          =>  pNuAnoCompetencia,
                                          pCdTipoCalculo             =>  pCdTipoCalculo,
                                          pFlDefinitivo              =>  pFlDefinitivo ,
                                          pFlPagaAdiantamento13sal   =>  pFlPagaAdiantamento13sal,
                                          pDtPrevistaCredito         =>  pDtPrevistaCredito,
                                          pVlDiferencaValor          =>  pVlDiferencaValor,
                                          pCdTipoFolha               =>  pCdTipoFolha,
                                          pLog                       =>  true,
                                          pTrace                     =>  false,
                                          pCalculoRetorno            => vCalculoRetorno);

   END IF;

   IF pCalculo.FlGeral <> 'I' AND -- Apenas para calculo geral, folha normal e inst de pensao
       PKGPAG_VAR.vgFolha.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoRecalculoMes) AND
       PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao
      THEN

      -- copia
      -- EXECUTA A ROTINA DE MIGRACAO DE CONTRACHEQUE DE SERVIDORES QUE AINDA POSSUEM
      -- VINCULO CALCULADO NO SIRH - INSTITUIDOR DE PENSAO

      -- REALIZA A COPIA DOS CONTRACHEQUES DE INSTITUIDORES DE PENSAO PROVENIENTES DO SIRH
      PKGPAG_POS.PBATIMENTOINSTPENSAO(pkgpag_var.vgFolha.NuAnoReferencia * 100 + pkgpag_var.vgFolha.NuMesReferencia);

   END IF;
   
   PKGPAG_GERAL.PLogProcFim ('TAR');
   
END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Recebe Chamada do Calculo Coletivo
   -- Autor: Rafael Gomes
   -- Data: 22/10/2008
   -- Objetivo: Obter as pessoas cujos vinculos e relacoes de vinculos se enquadram nos parametros de calculo (obtidos
   --           atraves da chave pCdTarefa) e realizar a atividade definida pelo parametro pInTipoExecucao
   --           Valores possiveis de pInTipoExecucao:
   --           1 - Retorna o numero total de pessoas que serao atingidas pelo processamento.
   --           2 - Para cada conjunto orgao/pessoa encontrado, realiza a chamada do processamento.
/*-----------------------------------------------------------------------------------------*/

PROCEDURE pprocessartarefa(pcdtarefa       IN INTEGER,
                           pintipoexecucao IN INTEGER DEFAULT 1) IS

  -- Variaveis

  vcdhistoricoparamcalculo  epaghistoricoparamcalculo.cdhistoricoparamcalculo%TYPE;
  vcdagrupamento            epaghistoricoparamcalculo.cdagrupamento%TYPE;
  vcdrelacaotrabalho        epaghistoricoparamcalculo.cdrelacaotrabalho%TYPE;
  vcdsituacaoprevidenciaria epaghistoricoparamcalculo.cdsituacaoprevidenciaria%TYPE;
  vcdunidadeorganizacional  epaghistoricoparamcalculo.cdunidadeorganizacional%TYPE;
  vinsubordinadas           epaghistoricoparamcalculo.insubordinadas%TYPE;
  vdtcalculo                epaghistoricoparamcalculo.dtcalculo%TYPE;
  vnumescompetencia         epaghistoricoparamcalculo.numescompetencia%TYPE;
  vnuanocompetencia         epaghistoricoparamcalculo.nuanocompetencia%TYPE;
  vcdtipofolhapagamento     epaghistoricoparamcalculo.cdtipofolhapagamento%TYPE;
  vnusequencial             epaghistoricoparamcalculo.nusequencial%TYPE;
  vcdtipocalculo            epaghistoricoparamcalculo.cdtipocalculo%TYPE;
  vfldefinitivo             epaghistoricoparamcalculo.fldefinitivo%TYPE;
  vflpagaadiantamento13sal  epaghistoricoparamcalculo.flpagaadiantamento13sal%TYPE;
  vdtprevistacredito        epaghistoricoparamcalculo.dtprevistacredito%TYPE;
  vflgerafolhabackup        epaghistoricoparamcalculo.flsalvarvalorescalculovigente%TYPE;
  vvldiferencavalor         epaghistoricoparamcalculo.vldiferencavalor%TYPE;

  vflvinculo CHAR(1);

  vdtcompetenciaini DATE;

  vcdtipofolha        epagtipofolha.cdtipofolha%TYPE;
  vflincluibolsista   epaghisttipofolhapagamento.flincluibolsista%TYPE;
  vflincluiaposentado epaghisttipofolhapagamento.flincluiaposentado%TYPE;
  vcalculo            pkgpag_cal.rcalculo;
  vblog               BOOLEAN;
  vqttotalpessoas     INTEGER;

BEGIN

  -- EXECUTE IMMEDIATE 'Alter session set session_cached_cursors=200';

  /*
     select nusim into cNuCalculoSimultaneo
        from tmpsimul
     where cdtarefa = pCdTarefa;
  */

  /*
     create table TMPSIMUL
        ( CDTAREFA INTEGER,
          NUSIM    INTEGER) tablespace SIGRH_DATA_SMALL;
  */

  vblog := TRUE;

  -- Quando o tipo de calculo e recalculo do mes e o tipo de tributacao for igual a 1 - Regime de Caixa (ex.: CIASC)
  -- a data prevista de credito deve ser no primeiro dia do mes posterior ao de referencia da folha

  SELECT hpc.cdagrupamento, hpc.nuanocompetencia, hpc.numescompetencia
    INTO pkgpag_var.vgfolha.cdagrupamento,
         pkgpag_var.vgfolha.nuanoreferencia,
         pkgpag_var.vgfolha.numesreferencia
    FROM epaghistoricoparamcalculo hpc
   WHERE hpc.cdtarefa = pcdtarefa;
  
  SELECT ap.cdtipotributacaoirrf
    INTO pkgpag_var.vgparampagamento.cdtipotributacaoirrf
    FROM epagagrupamentoparametro ap
   WHERE ap.cdagrupamento = pkgpag_var.vgfolha.cdagrupamento
     AND (ap.nuanoiniciovigencia * 100 + ap.numesiniciovigencia) <=
         (pkgpag_var.vgfolha.nuanoreferencia * 100 +
         pkgpag_var.vgfolha.numesreferencia)
     AND ((nvl(ap.nuanofimvigencia, 0) * 100 + nvl(ap.numesfimvigencia, 0)) >=
         (pkgpag_var.vgfolha.nuanoreferencia * 100 +
         pkgpag_var.vgfolha.numesreferencia) OR
         (nvl(ap.nuanofimvigencia, 0) + nvl(ap.numesfimvigencia, 0)) = 0)
     AND rownum < 2;

  -- Obtem os parametros de calculo
  BEGIN
    SELECT p.cdhistoricoparamcalculo,
           p.cdagrupamento,
           p.cdrelacaotrabalho,
           p.cdsituacaoprevidenciaria,
           p.cdunidadeorganizacional,
           p.insubordinadas,
           p.dtcalculo,
           p.numescompetencia,
           p.nuanocompetencia,
           p.cdtipofolhapagamento,
           p.nusequencial,
           p.cdtipocalculo,
           p.fldefinitivo,
           p.flpagaadiantamento13sal,
           CASE pkgpag_var.vgparampagamento.cdtipotributacaoirrf
             WHEN 1 THEN
              nvl(p.dtprevistacredito,
                  (last_day(to_date(p.nuanocompetencia * 100 +
                                    p.numescompetencia,
                                    'YYYYMM')) + 1))
             ELSE
              nvl(p.dtprevistacredito,
                  last_day(to_date(p.nuanocompetencia * 100 +
                                   p.numescompetencia,
                                   'YYYYMM')))
           END CASE,
           p.flsalvarvalorescalculovigente,
           nvl(p.vldiferencavalor, 0),
           nvl((SELECT 'S'
                 FROM epaghistoricoparamcalcpessoa pc
                WHERE pc.cdhistoricoparamcalculo =
                      p.cdhistoricoparamcalculo
                  AND rownum = 1),
               'N') flvinculo
      INTO vcdhistoricoparamcalculo,
           vcdagrupamento,
           vcdrelacaotrabalho,
           vcdsituacaoprevidenciaria,
           vcdunidadeorganizacional,
           vinsubordinadas,
           vdtcalculo,
           vnumescompetencia,
           vnuanocompetencia,
           vcdtipofolhapagamento,
           vnusequencial,
           vcdtipocalculo,
           vfldefinitivo,
           vflpagaadiantamento13sal,
           vdtprevistacredito,
           vflgerafolhabackup,
           vvldiferencavalor,
           vflvinculo
      FROM epaghistoricoparamcalculo p
     WHERE p.cdtarefa = pcdtarefa;
  EXCEPTION
    WHEN OTHERS THEN
      --dbms_output.put_line('Erro ao recuperar parâmetros de cálculo: ' ||  SQLERRM);
      RETURN;
  END;

  vdtcompetenciaini := to_date(vnuanocompetencia || vnumescompetencia,
                               'YYYYMM');

  -- Obtem o tipo de folha e Flags

  pbuscartipofolhapagamento(pcdtipofolhapagamento => vcdtipofolhapagamento,
                            pdtcompetencia        => vdtcompetenciaini,
                            pcdtipofolha          => vcdtipofolha,
                            pflincluibolsista     => vflincluibolsista,
                            pflincluiaposentado   => vflincluiaposentado);

  IF vcdtipofolha IS NULL THEN
    -- inexiste folha
    RETURN;
  END IF;

  ----------------------------------------------------------------------------------
  -- COMENTADO EM 16/06/2014
  -- Motivo: Implementacao de novos flags que permitem ao gestor determinar a
  --         liberacao das consultas do portal e a geracao dos arquivos de empenho
  ----------------------------------------------------------------------------------
  -- Verifica se pode realizar a execucao do processamento
  ----------------------------------------------------------------------------------
  /*
     IF vCdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal,
                           PKGPAG_TIPO.cnTpCalculoPrimeiro,
                           PKGPAG_TIPO.cnTpCalculoSegundo,
                           PKGPAG_TIPO.cnTpCalculoPrevia) THEN

       IF FExisteCalculoDefinitivo(pCdHistoricoParamCalculo => vCdHistoricoParamCalculo,
                                   pNuAnoCompetencia        => vNuAnoCompetencia,
                                   pNuMesCompetencia        => vNuMesCompetencia,
                                   pCdTipoFolhaPagamento    => vCdTipoFolhaPagamento) THEN

         gQtdePessoasACalcular := 0;

         RETURN;

       END IF;

     END IF;
  */
  -- Inicializa calculo
  vcalculo.flgeral := 'N';

  IF vcdrelacaotrabalho IS NULL AND vcdsituacaoprevidenciaria IS NULL AND
     vcdunidadeorganizacional IS NULL AND vflvinculo = 'N' THEN

    vcalculo.flgeral := 'S';
  END IF;

  vcalculo.cdtarefa                := pcdtarefa;
  vcalculo.cdhistoricoparamcalculo := vcdhistoricoparamcalculo;
  vcalculo.intipoexecucao          := pintipoexecucao;
  vcalculo.cdcalculo               := pkgpag_pre.pinicializarrelvincfolha;
  vcalculo.cdcalculopai            := vcalculo.cdcalculo;

  pkgpag_var.vgcalculo := vcalculo;

  -- Inicializar Contadores

  PIniciarContadores(pcalculo => vcalculo);

  ------------------------------------------------------------------------------------------------
  -- Se o tipo de folha for  de folha de adiantamento de 13 salario ou 13 salario
  ------------------------------------------------------------------------------------------------

  IF vcalculo.InTipoExecucao = 1 THEN
    -- Apenas contar

    -- Gera vinculos para contagem

    pkgpag_pre.pgerarrelvincfolha(pcalculo                  => vcalculo,
                                  pnumescompetencia         => vnumescompetencia,
                                  pnuanocompetencia         => vnuanocompetencia,
                                  pcdsituacaoprevidenciaria => vcdsituacaoprevidenciaria,
                                  pcdrelacaotrabalho        => vcdrelacaotrabalho,
                                  pcdtipofolha              => vcdtipofolha,
                                  pcdtipofolhapagamento     => vcdtipofolhapagamento,
                                  pflcalculodefinitivo      => vfldefinitivo,
                                  pdtcalculo                => vdtcalculo,
                                  pflincluibolsista         => vflincluibolsista,
                                  pflincluiaposentado       => vflincluiaposentado,
                                  pinsubordinadas           => vinsubordinadas,
                                  pcdunidadeorganizacional  => vcdunidadeorganizacional,
                                  pcdtipocalculo            => vcdtipocalculo,
                                  pnusequencial             => vnusequencial,
                                  pflvinculo                => vflvinculo,
                                  pcdfolhapagamento         => NULL,
                                  pcdvinculo                => NULL,
                                  pCdOrgao                  => NULL,
                                  pCdPessoa                 => NULL
                                  );

    vqttotalpessoas := FAtualizarContadores(pcalculo => vcalculo);

    gqtdepessoasacalcular := vqttotalpessoas;

  ELSE
    -- Calcular

    pexecutartarefa(pCalculo                  => vCalculo,
                    pcdagrupamento            => vcdagrupamento,
                    pcdrelacaotrabalho        => vcdrelacaotrabalho,
                    pcdsituacaoprevidenciaria => vcdsituacaoprevidenciaria,
                    pcdunidadeorganizacional  => vcdunidadeorganizacional,
                    pinsubordinadas           => vinsubordinadas,
                    pdtcalculo                => vdtcalculo,
                    pnumescompetencia         => vnumescompetencia,
                    pnuanocompetencia         => vnuanocompetencia,
                    pcdtipofolhapagamento     => vcdtipofolhapagamento,
                    pnusequencial             => vnusequencial,
                    pcdtipocalculo            => vcdtipocalculo,
                    pfldefinitivo             => vfldefinitivo,
                    pflpagaadiantamento13sal  => vflpagaadiantamento13sal,
                    pdtprevistacredito        => vdtprevistacredito,
                    pflgerafolhabackup        => vflgerafolhabackup,
                    pvldiferencavalor         => vvldiferencavalor,
                    pcdtipofolha              => vcdtipofolha,
                    pflincluibolsista         => vflincluibolsista,
                    pflincluiaposentado       => vflincluiaposentado,
                    pflvinculo                => vflvinculo);

    IF fNuCalculoSimultaneo > 1 AND ctracetkprof = 'N' THEN
      pkgpag_geral.plogprocini('TAR06','PosCalculo');

      pposcalculoparalelo(pcalculo      => vcalculo,
                          pfldefinitivo => vfldefinitivo);

      pkgpag_geral.plogprocfim('TAR06');

    ELSE
      pkgpag_geral.plogprocini('TAR05','PosCalculoSequencial');

      pposcalculosequencial(vcalculo);

      pkgpag_geral.plogprocfim('TAR05');
    END IF;

    pkgpag_pre.pfinalizarrelvincfolha(vcalculo.cdcalculopai); -- Finaliza calculo excluindo tabelas de trabalho

  END IF;

  --- END IF;

EXCEPTION

  WHEN pkgpag_var.edependenciaformula THEN

    perrotarefa(pcdhistoricoparamcalculo => vcalculo.cdhistoricoparamcalculo,
                pinsere                  => vblog,
                pcdpessoa                => pkgpag_var.vcdpessoa,
                pdelog                   => 'Processamento abortado. Encontrada dependência mútua entre formulas/bases.',
                pcdvinculo               => pkgpag_var.vgcdvinculo);

  WHEN pkgpag_var.echaveduplicada THEN

    perrotarefa(pcdhistoricoparamcalculo => vcalculo.cdhistoricoparamcalculo,
                pinsere                  => vblog,
                pcdpessoa                => pkgpag_var.vcdpessoa,
                pdelog                   => 'Chave duplicada ao processar suplementar.',
                pcdvinculo               => pkgpag_var.vgcdvinculo);

  WHEN pkgpag_var.einterrupcalc THEN

    perrotarefa(pcdhistoricoparamcalculo => vcalculo.cdhistoricoparamcalculo,
                pinsere                  => vblog,
                pcdpessoa                => pkgpag_var.vcdpessoa,
                pdelog                   => 'Processamento interrompido pelo usuário.',
                pcdvinculo               => pkgpag_var.vgcdvinculo);

  WHEN pkgpag_var.enaorodafolhanormal THEN

    perrotarefa(pcdhistoricoparamcalculo => vcalculo.cdhistoricoparamcalculo,
                pinsere                  => vblog,
                pcdpessoa                => pkgpag_var.vcdpessoa,
                pdelog                   => 'Não é permitido executar folha normal/calculo normal temporariamente.',
                pcdvinculo               => pkgpag_var.vgcdvinculo);

  WHEN OTHERS THEN

    perrotarefa(pcdhistoricoparamcalculo => vcalculo.cdhistoricoparamcalculo,
                pinsere                  => vblog,
                pcdpessoa                => pkgpag_var.vcdpessoa,
                pdelog                   => SUBSTR('** Fatal: PEntrarCalculoTarefa: ' ||
                                                   DBMS_UTILITY.format_error_stack  || 
                                                   '--' || DBMS_UTILITY.format_error_backtrace
                                            ,1,2000),                                      
                pcdvinculo               => pkgpag_var.vgcdvinculo);

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo:  Recebe Chamada do Calculo Coletivo
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PEntrarCalculoTarefa (pCdTarefa IN INTEGER) IS

BEGIN

  PKGPAG_GERAL.PIniciarLogProc;

  PProcessarTarefa (pCdTarefa       => pCdTarefa,
                    pInTipoExecucao => 2); -- Execucao

  PKGPAG_GERAL.PFinalizarLogProc (pCalculo => PKGPAG_VAR.vgCalculo );

  COMMIT;

END;

--EXCLUIR
/*
PROCEDURE PEntrarCalcParaleloIndividual (pCdFolhaPagamento        IN INTEGER,
                                         pCdVinculo               IN INTEGER) is


 vCdRetorno PKGPAG_CAL.rCalculoRetorno;
 vDtCalculo date;
 vFlCalculoDefinitivo char(1);

begin

   select ff.dtcalculo, ff.flcalculodefinitivo
     into vDtCalculo, vFlCalculoDefinitivo
     from epagfolhapagamento ff
    where ff.cdfolhapagamento = pCdFolhaPagamento;

   PEntrarCalculoIndividual(pCdFolhaPagamento =>  pCdFolhaPagamento,
                                   pCdVinculo =>  pCdVinculo,
                                   pDtCalculo =>  pkgpag_var.vgFolha.DtCalculo,
                         pFlCalculoDefinitivo =>  pkgpag_var.vgFolha.FlCalculoDefinitivo,
                              pCalculoRetorno =>  vCdRetorno,
                              pParalelo       =>  'S');



   commit;

   exception
   when no_data_found then
    null;

   when others
    then null;

end;

*/
/*-----------------------------------------------------------------------------------------/
    Objetivo: Recebe Chamada do Calculo Individual
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PProcessarCalculoIndividual (pCdFolhaPagamento        IN INTEGER,
                                       pCdVinculo               IN INTEGER,
                                       pDtCalculo               IN DATE,
                                       pFlCalculoDefinitivo     IN CHAR,
                                       pCdCalculoContinua       IN INTEGER,
                                       pVlDiferencaValor        IN NUMBER DEFAULT 0,
                                       pFlPagaAdiantamento      IN CHAR DEFAULT 'N',
                                       pLog                     IN BOOLEAN DEFAULT TRUE,
                                       pTrace                   IN BOOLEAN DEFAULT TRUE,
                                       pCalculoRetorno         OUT PKGPAG_CAL.rCalculoRetorno) IS

  vNuMesCompetencia          NUMBER;
  vNuAnoCompetencia          NUMBER;
  vNuSequencialFolha         INTEGER;
  vCalculo                   PKGPAG_CAL.rCalculo;

  vDtCompetenciaIni          DATE;

  vCdTipoFolha               EPagTipoFolha.Cdtipofolha%TYPE;
  vCdTipoCalculo             EPagFolhaPagamento.CdTipoCalculo%TYPE;
  vCdTipoFolhaPagamento      EPagHistoricoParamCalculo.CdTipoFolhaPagamento%TYPE;

  vFlIncluiBolsista          EPagHistTipoFolhaPagamento.FlIncluiBolsista%TYPE;
  vFlIncluiAposentado        EPagHistTipoFolhaPagamento.FlIncluiAposentado%TYPE;

  vNuversaoformulacalculo    INTEGER;
  vNuversaobasecalculo       INTEGER;
  vCdAgrupamento             INTEGER;

  vDtPrevisaoCredito         DATE;

  vCdPessoa                  INTEGER;
  vCdOrgao                   INTEGER;
  vCdTipoFolhaPagamento13    INTEGER;

BEGIN

   PKGPAG_GERAL.PIniciarLogProc;

   SELECT CdPessoa INTO vCdPessoa
      FROM ECadVinculo where CdVinculo = pCdVinculo;

   IF PKGPAG_GERAL.FFolhaEmExecucao(pCdFolhaPagamento, vCdPessoa) THEN

     pCalculoRetorno.CdMensagem := 2649;

     pCalculoRetorno.DeParametros :=  '';

     RETURN;

   END IF;

   SELECT ho.cdagrupamento,
          fp.nuanoreferencia,
          fp.numesreferencia,
          fp.cdOrgao
    INTO PKGPAG_VAR.vgFolha.cdagrupamento,
         PKGPAG_VAR.vgFolha.nuanoreferencia,
         PKGPAG_VAR.vgFolha.numesreferencia,
         vCdOrgao
    FROM epagfolhapagamento fp
   INNER JOIN ecadhistorgao ho
      on ho.cdorgao = fp.cdorgao
   WHERE fp.cdfolhapagamento = pCdFolhaPagamento
     AND ho.dtfimvigencia is null
     AND ho.flanulado = PKGPAG_TIPO.cnN;

   SELECT ap.cdtipotributacaoirrf
     INTO PKGPAG_VAR.vgParamPagamento.cdtipotributacaoirrf
     FROM epagagrupamentoparametro ap
    WHERE ap.cdagrupamento = PKGPAG_VAR.vgFolha.cdagrupamento
      AND (ap.nuanoiniciovigencia*100+ap.numesiniciovigencia) <=
          (PKGPAG_VAR.vgFolha.nuanoreferencia*100+PKGPAG_VAR.vgFolha.numesreferencia)
      AND (
            (NVL(ap.nuanofimvigencia,0)*100+NVL(ap.numesfimvigencia,0)) >=
            (PKGPAG_VAR.vgFolha.nuanoreferencia*100+PKGPAG_VAR.vgFolha.numesreferencia)
            OR
            (NVL(ap.nuanofimvigencia,0)+NVL(ap.numesfimvigencia,0)) = 0
          )
      AND ROWNUM < 2;

   SELECT nuMesReferencia,
          nuAnoReferencia, 
          cdTipoFolhaPagamento,
          nuversaoformulacalculo,
          nuversaobasecalculo, 
          o.CdAgrupamento, 
          cdTipoCalculo,
     CASE PKGPAG_VAR.vgParamPagamento.cdtipotributacaoirrf
      WHEN 1 THEN
       NVL(DtPrevisaoCredito, (LAST_DAY(TO_DATE(f.NuAnomesReferencia, 'YYYYMM')) + 1))
      ELSE
              NVL(DtPrevisaoCredito, LAST_DAY(TO_DATE(f.NuAnomesReferencia, 'YYYYMM')))
     END CASE,
          nuSequencialFolha
     INTO vNuMesCompetencia,
          vNuAnoCompetencia, 
          vCdTipoFolhaPagamento,
          vNuversaoformulacalculo,
          vNuversaobasecalculo, 
          vCdAgrupamento, 
          vCdTipoCalculo,
          vDtPrevisaoCredito, 
          vNuSequencialFolha
     FROM epagfolhapagamento f, 
          eCadOrgao o
    WHERE cdfolhapagamento = pCdFolhaPagamento
         AND o.cdOrgao = f.cdOrgao;

   -- Excluir todos os contra-cheques atuais do vinculo

   PKGPAG_GERAL.pexcluircontrachequespessoa(
                 pCdOrgao              => vCdorgao,
                 pCdPessoa             => vCdPessoa,
                 pNuAnoReferencia      => vNuAnoCompetencia,
                 pNuMesReferencia      => vNuMesCompetencia,
                 pCdTipoFolhaPagamento => vCdTipoFolhaPagamento,
                 pCdTipoCalculo        => vCdTipoCalculo,
                 pNuSequencialFolha    => vNuSequencialFolha
   );
      
   vCalculo.FlGeral                 := 'I';
   vCalculo.CdTarefa                := NULL;
   vCalculo.CdHistoricoParamCalculo := 0;
   vCalculo.InTipoExecucao          := 2; -- 2 - Processar a folha
      
   IF pCdCalculoContinua IN (0,1) THEN -- Executar completo ou apenas a parte da TAR

      vDtCompetenciaIni := to_date(vNuAnoCompetencia * 100 + vNuMesCompetencia, 'YYYYMM');

      -- Obtem o tipo de folha e Flags

      PBuscarTipoFolhaPagamento (pCdTipoFolhaPagamento => vCdTipoFolhaPagamento,
                                 pDtCompetencia        => vDtCompetenciaIni,
                                 pCdTipoFolha          => vCdTipoFolha,
                                 pFlIncluiBolsista     => vFlIncluiBolsista,
                                 pFlIncluiAposentado   => vFlIncluiAposentado);
                               
      -- Se for folha de adiantamento de 13, exclui também a folha de 13
      IF vCdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaAdiant13,PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp) THEN
        
         SELECT TFP.cdTipoFolhaPagamento
           INTO vCdTipoFolhaPagamento13
           FROM EPagTipoFolhaPagamento TFP
          WHERE TFP.cdAgrupamento = vCdAgrupamento
            AND TFP.cdTipoFolha = DECODE(vCdTipoFolha,PKGPAG_TIPO.cnTpFolhaAdiant13, PKGPAG_TIPO.cnTpFolha13, PKGPAG_TIPO.cnTpFolhaCtisp13);         

         PKGPAG_GERAL.pexcluircontrachequespessoa(
                 pCdOrgao              => vCdorgao,
                 pCdPessoa             => vCdPessoa,
                 pNuAnoReferencia      => vNuAnoCompetencia,
                 pNuMesReferencia      => vNuMesCompetencia,
                 pCdTipoFolhaPagamento => vCdTipoFolhaPagamento13,
                 pCdTipoCalculo        => vCdTipoCalculo,
                 pNuSequencialFolha    => vNuSequencialFolha);

      END IF; 
      
      -- Inicializa calculo


      vCalculo.CdCalculo               := PKGPAG_PRE.PInicializarRelVincFolha;
      vCalculo.CdCalculoPai            := vCalculo.CdCalculo;

      PKGPAG_VAR.vgCalculo             := vCalculo;

      PKGPAG_PRE.PGerarRelVincFolha  ( pCalculo                            => vCalculo,
                                       pNuMesCompetencia                   => vNuMesCompetencia,
                                       pNuAnoCompetencia                   => vNuAnoCompetencia,
                                       pCdSituacaoPrevidenciaria           => NULL,
                                       pCdRelacaoTrabalho                  => NULL,
                                       pCdTipoFolha                        => vCdTipoFolha,
                                       pCdTipoFolhaPagamento               => vCdTipoFolhaPagamento,
                                       pFlCalculoDefinitivo                => pFlCalculoDefinitivo,
                                       pDtCalculo                          => pDtCalculo,
                                       pFlIncluiBolsista                   => vFlIncluiBolsista,
                                       pFlIncluiAposentado                 => vFlIncluiAposentado,
                                       pInSubordinadas                     => NULL,
                                       pCdUnidadeOrganizacional            => NULL,
                                       pCdTipoCalculo                      => vCdTipoCalculo,
                                       pNuSequencial                       => NULL,
                                       pFlVinculo                          => 'S',
                                       pCdFolhaPagamento                   => pCdFolhaPagamento,
                                       pCdVinculo                          => NULL,
                                       pCdOrgao                            => vCdOrgao,
                                       pCdPessoa                           => vCdPessoa                                  
                                       );

      -- Ordenando Rubricas
      BEGIN

        PObtemOrdemCalculo (pCdAgrupamento    => vCdAgrupamento,
                            pNuAnoReferencia  => vNuAnoCompetencia,
                            pNuMesReferencia  => vNuMesCompetencia,
                            pNuVersaoBaseCalc => nvl (vNuversaoformulacalculo, PKGPAG_TIPO.cn1),
                            pNuVersaoFormCalc => nvl (vNuVersaoFormulaCalculo, PKGPAG_TIPO.cn1),
                            pCdCalculoPai     => vCalculo.CdCalculoPai,
                            pFlPersistir      => 1);

        EXCEPTION

         WHEN PKGPAG_VAR.eDependenciaFormula THEN

          pCalculoRetorno.CdMensagem := 2164;

          pCalculoRetorno.DeParametros :=  '';

          RETURN;

      END;

      --
      PKGPAG_PRE.PGerarTabelaFolha(pCalculo               => vCalculo,
                                   pNuMesCompetencia      => vNuMesCompetencia,
                                   pNuAnoCompetencia      => vNuAnoCompetencia,
                                   pCdTipoFolha           => vCdTipoFolha,
                                   pCdTipoCalculo         => vCdTipoCalculo,
                                   pFlCalculoDefinitivo   => pFlCalculoDefinitivo,
                                   pDtPrevisaoCredito     => vDtPrevisaoCredito,
                                   pNuSequencial          => vNuSequencialFolha);

   END IF;
   
   -- Processando calculo

   IF pCdCalculoContinua = 0 OR pCdCalculoContinua > 1 THEN -- Executar completo ou apenas a parte da CAL

      IF pCdCalculoContinua > 1 THEN -- Preparar variaveis da parte 1 que não estão alimentadas para a parte 2
         -- reobter o calculo
         
         vCalculo.CdCalculo               := pCdCalculoContinua;
         vCalculo.CdCalculoPai            := vCalculo.CdCalculo;
         PKGPAG_VAR.vgCalculo             := vCalculo;
        
         IF vCalculo.FlGeral <> 'I' THEN
            DBMS_OUTPUT.PUT_LINE ('Falha em retomar contato individual');
            RAISE NO_DATA_FOUND;
            
         END IF;
      
      END IF;

      IF vCdTipoFolha IN ( PKGPAG_TIPO.cnTpFolha13
                         , PKGPAG_TIPO.cnTpFolhaAdiant13
                         , PKGPAG_TIPO.cnTpFolhaResidente13
                         , PKGPAG_TIPO.cnTpFolhaFunebre13
                         , pkgpag_tipo.cnTpFolhaCtisp13
                         , pkgpag_tipo.cnTpFolhaAdiant13Ctisp
                         , pkgpag_tipo.cnTpFolhaProdex13
                         , pkgpag_tipo.cnTpFolhaHonorarios13
                         , pkgpag_tipo.cnTpFolhaHonorarProcuradores13) then


             PKGPAG_DT.PProcessarCalculo13Salario  (pCalculo                   => vCalculo,
                                                    pDtCalculo                 => pDtCalculo,
                                                    pFlDefinitivo              => pFlCalculoDefinitivo,
                                                    pLog                       => pLog,
                                                    pTrace                     => pTrace,
                                                    pCalculoRetorno            => pCalculoRetorno);


      ELSE -- Folha Normal

        PKGPAG_CAL.PProcessarCalculoNormal    (pCalculo                   => vCalculo,
                                               pDtCalculo                 => pDtCalculo,
                                               pFlDefinitivo              => pFlCalculoDefinitivo,
                                               pFlPagaAdiantamento13sal   => pFlPagaAdiantamento,
                                               pVlDiferencaValor          => pVlDiferencaValor,
                                               pLog                       => pLog,
                                               pTrace                     => pTrace,
                                               pCalculoRetorno            => pCalculoRetorno);

      END IF;

      -- Finaliza calculo excluindo tabelas de trabalho

      IF pCdCalculoContinua IN (0,1) THEN -- manter tabelas para ter varias execucoes da parte 2
    
          PKGPAG_PRE.PFinalizarRelVincFolha (vCalculo.CdCalculo);
          
      END IF;
      
      PKGPAG_GERAL.PFinalizarLogProc( pCalculo => PKGPAG_VAR.vgCalculo);

   END IF;
   
END;

PROCEDURE PEntrarCalculoIndividual (pCdFolhaPagamento        IN INTEGER,
                                    pCdVinculo               IN INTEGER,
                                    pDtCalculo               IN DATE,
                                    pFlCalculoDefinitivo     IN CHAR DEFAULT 'X',
                                    pVlDiferencaValor        IN NUMBER DEFAULT 0,
                                    pFlPagaAdiantamento      IN CHAR DEFAULT 'N',
                                    pLog                     IN BOOLEAN DEFAULT TRUE,
                                    pTrace                   IN BOOLEAN DEFAULT TRUE,
                                    pCalculoRetorno         OUT PKGPAG_CAL.rCalculoRetorno) IS

   vFlCalculoDefinitivo CHAR;
BEGIN

   vFlCalculoDefinitivo := pFlCalculoDefinitivo;
   IF vFlCalculoDefinitivo = 'X' THEN
     vFlCalculoDefinitivo := FObterFlCalculoDefinitivoFolha(pCdFolhaPagamento);
   END IF;
   
   PProcessarCalculoIndividual(pCdFolhaPagamento    => pCdFolhaPagamento,
                               pCdVinculo           => pCdVinculo,
                               pDtCalculo           => pDtCalculo,
                               pFlCalculoDefinitivo => vFlCalculoDefinitivo,
                               pCdCalculoContinua   => 0,
                               pVlDiferencaValor    => pVlDiferencaValor,
                               pFlPagaAdiantamento  => pFlPagaAdiantamento,
                               pLog                 => pLog,
                               pTrace               => pTrace,
                               pCalculoRetorno      => pCalculoRetorno);
END; 

PROCEDURE PEntrarCalculoTarefaTKPROF (pCdTarefa IN INTEGER ) IS

BEGIN

   cTraceTKPROF := 'S';

   PTraceTKPROF (true,'Prep');

   PEntrarCalculoTarefa (pCdTarefa      => pCdTarefa); -- Execucao

   PTraceTKPROF (false);

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Funcao chamada pelo sistema para contar pessoas a Calcular
/*-----------------------------------------------------------------------------------------*/

FUNCTION FContarACalcular (pCdTarefa IN INTEGER) RETURN INTEGER IS

BEGIN

  PProcessarTarefa (pCdTarefa       => pCdTarefa,
                    pInTipoExecucao => 1); -- Contagem

  RETURN gQtdePessoasACalcular;

END;

FUNCTION FObterFlCalculoDefinitivoFolha ( pCdFolhaPagamento IN INTEGER ) RETURN CHAR IS
  vFlCalculoDefinitivo CHAR;
BEGIN

  SELECT flcalculodefinitivo INTO vFlCalculoDefinitivo
  FROM epagfolhapagamento
  WHERE cdfolhapagamento=pCdFolhaPagamento and rownum <= 1;

  RETURN vFlCalculoDefinitivo;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END;

PROCEDURE PEntrarCalculoIndividualPadrao(pCdFolhaPagamento IN INTEGER,
                                          pCdVinculo        IN INTEGER,
                                         pDtCalculo        IN DATE) IS
  pcalculoretorno pkgpag_cal.rcalculoretorno;
BEGIN

  pentrarcalculoindividual(pcdfolhapagamento => pCdFolhaPagamento,
                           pcdvinculo => pCdVinculo,
                           pdtcalculo => pDtCalculo,
                           pcalculoretorno => pcalculoretorno);
END;

FUNCTION FExisteReferenciaCircularRub return boolean is  
BEGIN
   
   FOR agr in (select distinct fp.cdagrupamento
                 from epagfolhapagamento fp
                where fp.nuanomesreferencia = to_number(to_char(add_months(sysdate, -1), 'yyyymm'))
                  and fp.flcalculodefinitivo = 'S') LOOP
  
      BEGIN
         PObtemOrdemCalculo ( pCdAgrupamento    => agr.cdagrupamento,
                              pNuVersaoBaseCalc => 1,
                              pNuVersaoFormCalc => 1,
                              pNuAnoReferencia  => extract(year from sysdate),
                              pNuMesReferencia  => extract(month from sysdate),
                              pCdCalculoPai     => 1,
                              pFlPersistir      => 0);
                                       
      EXCEPTION
         WHEN PKGPAG_VAR.eDependenciaFormula THEN
            RETURN TRUE;
       
      END;
   
   END LOOP;
   
   RETURN FALSE;

end;

END PKGPAG_TAR;
/
