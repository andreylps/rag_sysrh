CREATE OR REPLACE PACKAGE PKGPAG IS

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure chamada pelo agendador para execucao da tarefa de folha de pagamento
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PExecutaProcCFAgendador (pCdTarefa           IN INTEGER);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure chamada pelo sistema para execucao da tarefa de folha de pagamento
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PContarACalcular (pCdTarefa       IN INTEGER,
                            pQtdeACalcular OUT INTEGER);

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure chamada pelo sistema para execucao de calculo individual
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PEntrarCalculoIndividual (pCdFolhaPagamento        IN INTEGER,
                                    pCdVinculo               IN INTEGER,
                                    pDtCalculo               IN DATE,
                                    pCdMensagem              OUT INTEGER,
                                    pDeParametros            OUT VARCHAR2);

/*-----------------------------------------------------------------------------------------/
     Objetivo: Definir a ordem de execucao das formulas e bases de calculo
     Retorno : 0 - Nao existe dependencia mutua
               2164 - Existe dependencia mutua (codigo da msg)
/*-----------------------------------------------------------------------------------------*/
FUNCTION FExisteDependenciaMutua(pCdAgrupamento        IN INTEGER,
                                 pCdOrgao              IN INTEGER,
                                 pNuAnoReferencia      IN INTEGER,
                                 pNuMesReferencia      IN INTEGER,
                                 pCdRubricaAgrupamento IN INTEGER DEFAULT NULL,
                                 pSgBaseCalculo        IN VARCHAR2 DEFAULT NULL)
  RETURN INTEGER;

/*-----------------------------------------------------------------------------------------/
     Objetivo: Retornar os salarios de contribuicao conforme os parametros de vinculo e
               periodo de referencia informados.
/*-----------------------------------------------------------------------------------------*/
PROCEDURE PPesquisaSalContribApo (pCdVinculo         IN INTEGER,
                                  pNuMesInicio       IN INTEGER,
                                  pNuAnoInicio       IN INTEGER,
                                  pNuMesFim          IN INTEGER,
                                  pNuAnoFim          IN INTEGER,
                                  pNuMesAplicIndice  IN INTEGER,
                                  pNuAnoAplicIndice  IN INTEGER,
                                  Resultado          OUT types.ref_cursor);

/*-----------------------------------------------------------------------------------------/
     Objetivo: Recuperar Dados da Rubrica
     Parametro: [N] para retornar o numero ou
                [D] para retornar a descricao
/*-----------------------------------------------------------------------------------------*/
FUNCTION FRecuperarNmRubricaAgr(pCdRubricaAgrupamento IN NUMBER,
                                pTipoConsulta         VARCHAR2)
  RETURN VARCHAR2;

/*-----------------------------------------------------------------------------------------/
     Objetivo: Emitir Proventos
     -- [I]nstrucao ou [C]oncessao
/*-----------------------------------------------------------------------------------------*/
PROCEDURE PEmitirProventosVantPecApo(p_CdVinculoContra     IN NUMBER DEFAULT 0,
                                     p_FlTipoPesquisa      IN STRING DEFAULT NULL, -- [I]nstrucao ou [C]oncessao
                                     Resultado             OUT types.ref_cursor
);

PROCEDURE PValidarExpressao (PExpressao IN VARCHAR2, PRetorno OUT NUMBER);

/*

RENAME ECALFB TO XCALFB;

-- somente quando nao tiver mais XTMPAG
RENAME ECALPROCESSAMENTOINDIVIDUAL TO XCALPROCESSAMENTOINDIVIDUAL;
RENAME ECALFOLHAMES TO XCALFOLHAMES;
RENAME ECALFOLHAMESANT TO XCALFOLHAMESANT;
RENAME ECALFOLHAMESCAIXA TO XCALFOLHAMESCAIXA;
RENAME ECALFOLHATRIBIRRF TO XCALFOLHATRIBIRRF;
RENAME ECALORGAOCALCULO TO XCALORGAOCALCULO;

ALTER TABLE ECALVINCFOLHA
   ADD (FlContribIndiv  INTEGER,
        DeOrdemExecucao  VARCHAR2(5) );

ALTER TABLE epagfolhapagamento 
   ADD (DeOrdemExecucao  VARCHAR2(5) );
   

DROP TABLE ECALFOLHAPAG;

CREATE TABLE ECALFOLHAPAG AS 
SELECT 0 CdCalculo,
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
       0 FlMesCorrente,
       0 FlMesAnterior,
       0 FlMediaSaude,
       0 FlUlt12Meses,
       0 FlAnoCorrente             
  FROM EPAGFOLHAPAGAMENTO FP
 WHERE 1=0;
 
 
 CREATE INDEX IDXCALFOLHAPAG ON ECALFOLHAPAG (CdCalculo);
  
 
 alter table epagcapahistrubricavinculo
add (vlPercentContribIndiv  NUMBER(4,2) );
 
 
   
*/

END PKGPAG;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG IS

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure chamada pelo agendador para execucao da folha de pagamento
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PExecutaProcCFAgendador(pCdTarefa IN INTEGER) IS

  vCdMensagem   number;
  vDeParametros varchar2(100);
  vInterrompe   char(1) := 'N';
  vCount        integer;
  vCountGeral   integer := 0;

BEGIN
   
  PKGPAG_TAR.PEntrarCalculoTarefa(pCdTarefa => pCdTarefa);

  PKGPOSCALC.PEntrarCalculoTarefa(pCdTarefa => pCdTarefa);

  BEGIN
    UPDATE EAdmTarefa T
       SET T.DtTerminoReal = SYSDATE, T.CdSituacaoTarefa = 4
     WHERE T.CdTarefa = pCdTarefa
       AND T.CdSituacaoTarefa <> 3; -- Situacao de erro

    UPDATE epaghistoricoparamcalculo p
       SET p.instatus = 2 --finalizado
     WHERE p.cdhistoricoparamcalculo IN
           (SELECT hpc.cdhistoricoparamcalculo
              FROM epaghistoricoparamcalculo hpc
             INNER JOIN EAdmTarefa T
                ON T.CdTarefa = HPC.CdTarefa
             INNER JOIN epagtipofolhapagamento tf
                ON tf.cdtipofolhapagamento = hpc.cdtipofolhapagamento
             WHERE hpc.instatus = 1
               AND T.CdSituacaoTarefa = 4);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
   -- Reprocessa individual

   /*vCount := 0;

   begin

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
    (pCdTarefa,
     'RECALCULO DUPLO VINCULO INICIADO! - ' || to_char(sysdate,'DD/MM/YYYY hh24:mi:ss'),
     0,0,0,0,0,0);

     vCount := 0;

     exception
       when others
         then null;

   end;

   for rep in (select count(*) over() as qtde,calc.cdvinculo, calc.cdfolhapagamento, calc.nusegmento
               from tmppagcalculocoletivo calc
                where calc.flcalculado='J'
                group by calc.cdvinculo, calc.nusegmento, calc.cdfolhapagamento)
   loop

      vCount := vCount + 1;

      begin

        begin

        select 'S'
          into vInterrompe
          from tmppagcalculocoletivo
          where flCalculado = 'K'
            and rownum < 2;

        if nvl(vInterrompe,'N') = 'S' then
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
            (pCdTarefa,
             'RECALCULO DUPLO VINCULO INTERROMPIDO! - ' || to_char(sysdate,'DD/MM/YYYY hh24:mi:ss'),
             0,0,0,0,0,0);
      exit;
        end if;

        exception
     when others
      then null;
        end;

        if vCount = 10 then

           vCountGeral := vCountGeral + vCount;

           begin

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
            (pCdTarefa,
             'RECALCULO DUPLO VINCULO ' || vCountGeral || ' DE ' || rep.qtde || ' - ' ||
             to_char(sysdate,'DD/MM/YYYY hh24:mi:ss'),
             0,0,0,0,0,0);

             vCount := 0;

             exception
        when others
         then null;

             end;

        end if;

        PEntrarCalculoIndividual(rep.cdfolhapagamento, rep.cdvinculo, pkgpag_var.vgFolha.DtCalculo, vCdMensagem, vDeParametros);

        update tmppagcalculocoletivo tpc
           set tpc.flcalculado = 'R',
               tpc.dtultalteracao = sysdate
         where tpc.cdvinculo = rep.cdvinculo
           and tpc.nusegmento = rep.nusegmento
           and tpc.cdfolhapagamento = rep.cdfolhapagamento;

        commit;

        exception
     when no_data_found then
      null;

          when others then
      null;

      end;
   end loop;

   begin

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
    (pCdTarefa,
     'RECALCULO DUPLO VINCULO FINALIZADO! - ' || to_char(sysdate,'DD/MM/YYYY hh24:mi:ss'),
     0,0,0,0,0,0);

     vCount := 0;

     exception
       when others
         then null;

   end;*/

   COMMIT;

EXCEPTION

  WHEN OTHERS THEN

     PKGPAG_TAR.PErroTarefa (pCdTarefa => pCdTarefa);

     COMMIT;

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Funcao chamada pelo sistema para execucao da tarefa de folha de pagamento
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PContarACalcular (pCdTarefa       IN INTEGER,
                            pQtdeACalcular OUT INTEGER) IS

BEGIN

  pQtdeACalcular := PKGPAG_TAR.FContarACalcular (pCdTarefa => pCdTarefa);

END;

/*-----------------------------------------------------------------------------------------/
    Objetivo: Procedure chamada pelo sistema para execucao de calculo individual
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PEntrarCalculoIndividual (pCdFolhaPagamento        IN INTEGER,
                                    pCdVinculo               IN INTEGER,
                                    pDtCalculo               IN DATE,
                                    pCdMensagem              OUT INTEGER,
                                    pDeParametros            OUT VARCHAR2) IS

  vCalculoRetorno PKGPAG_CAL.rCalculoRetorno;

BEGIN

  PKGPAG_TAR.PEntrarCalculoIndividual (pCdFolhaPagamento            =>  pCdFolhaPagamento
                                      ,pCdVinculo                   =>  pCdVinculo
                                      ,pDtCalculo                   =>  pDtCalculo
                                      ,pCalculoRetorno              =>  vCalculoRetorno);

  pCdMensagem   := vCalculoRetorno.CdMensagem;
  pDeParametros := vCalculoRetorno.DeParametros;

  PKGPOSCALC.PEntrarCalculoIndividual (pCdFolhaPagamento  => pCdFolhaPagamento ,
                                       pCdVinculo         => pCdVinculo);


  IF pCdMensagem = 4050 THEN
     pCdMensagem := 0;
  END IF;

END;

/*-----------------------------------------------------------------------------------------/
     Objetivo: Definir a ordem de execucao das formulas e bases de calculo
     Retorno : 0 - Nao existe dependencia mutua
               2164 - Existe dependencia mutua (codigo da msg)
/*-----------------------------------------------------------------------------------------*/

FUNCTION FExisteDependenciaMutua(pCdAgrupamento        IN INTEGER,
                                 pCdOrgao              IN INTEGER,
                                 pNuAnoReferencia      IN INTEGER,
                                 pNuMesReferencia      IN INTEGER,
                                 pCdRubricaAgrupamento IN INTEGER DEFAULT NULL,
                                 pSgBaseCalculo        IN VARCHAR2 DEFAULT NULL)
 RETURN INTEGER IS

  FUNCTION FTemDependencia(pCdRubAgrp IN INTEGER)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN

    SELECT COUNT(*)
      INTO vCont
      FROM (SELECT FC.CdRubricaagrupamento,
                   FC.Cdagrupamento,
                   DECODE(FCBA.CdOrgao, NULL, FC.CdOrgao, FCBA.CdOrgao) AS CdOrgao,
                   DECODE(FCBA.CdRubricaFilha, NULL,x.CdRubricaFilha,FCBA.cdRubricaFilha) cdRubricaFilha,
                   HFC.NuAnoInicio,
                   HFC.NuMesInicio,
                   HFC.NuAnoFim,
                   HFC.NuMesfim
             FROM (SELECT FBE.CdFormulaCalcBlocoExpressao,
                          FBE.CdFormulaCalculoBloco,
                          BC.Sgbasecalculo
                     FROM EpagFormulaCalcBlocoExpressao FBE
                     LEFT JOIN Epagbasecalculo BC
                       ON FBE.Cdbasecalculo = BC.CdBaseCalculo) FBE
             LEFT JOIN (SELECT BC.CdBaseCalculo,
                               BC.CdOrgao,
                               BC.SgBaseCalculo,
                               BCBA.CdRubricaagrupamento AS CdRubricaFilha
                          FROM EPagBaseCalculo BC
                         INNER JOIN Epagbasecalculoversao BCV
                            ON BC.Cdbasecalculo = BCV.Cdbasecalculo
                         INNER JOIN EpagHistBaseCalculo HBC
                            ON HBC.CdVersaoBaseCalculo = BCV.CdVersaoBaseCalculo
                         INNER JOIN Epagbasecalculobloco BCB
                            ON BCB.CdHistBaseCalculo = HBC.CdHistBaseCalculo
                         INNER JOIN EpagBaseCalculoBlocoExpressao BCE
                            ON BCB.CdBaseCalculoBloco = BCE.CdBaseCalculoBloco
                         INNER JOIN  Epagbasecalcblocoexprrubagrup BCBA
                            ON BCE.CdBaseCalculoBlocoExpressao = BCBA.CdBaseCalculoBlocoExpressao
                         WHERE (BC.CdAgrupamento = pCdAgrupamento OR
                               BC.CdOrgao = pcdOrgao)/* AND
                               BCV.NuVersao = pnuVersao*/ AND
                               BCBA.CdRubricaAgrupamento IN
                               (SELECT CdRubricaAgrupamento
                                  FROM EPagFormulaCalculo F
                                 INNER JOIN EpagFormulaVersao FV
                                    ON F.CdFormulaCalculo = FV.CdFormulaCalculo
                                 INNER JOIN EpagHistFormulaCalculo HFC
                                    ON HFC.CdFormulaVersao = FV.CdFormulaVersao
                                 WHERE (F.CdAgrupamento = pCdAgrupamento OR
                                        F.CdOrgao = pcdOrgao) /*AND
                                        FV.NuFormulaVersao = pNuVersao*/)) FCBA
                   ON FCBA.sgBaseCalculo = FBE.sgBaseCalculo
              LEFT JOIN ( SELECT FCBA.CdFormulaCalcBlocoExpressao,
                                 FCBA.CdRubricaagrupamento AS CdRubricaFilha
                            FROM EPagFormCalcBlocoExpRubAgrup FCBA
                           WHERE FCBA.CdRubricaAgrupamento IN
                                (SELECT CdRubricaAgrupamento
                                   FROM EPagformulacalculo F
                                  INNER JOIN EpagFormulaVersao FV
                                     ON F.CdFormulaCalculo = FV.CdFormulaCalculo
                                  INNER JOIN EpagHistFormulaCalculo HFC
                                     ON HFC.CdFormulaVersao = FV.CdFormulaVersao
                                  WHERE (F.CdAgrupamento = pCdAgrupamento OR
                                         F.CdOrgao = pcdOrgao) /*AND
                                         FV.NuFormulaVersao = pNuVersao*/)) X
                      ON X.CdFormulaCalcBlocoExpressao =  FBE.CdFormulaCalcBlocoExpressao
              INNER JOIN EPagFormulaCalculobloco FCB
                      ON FCB.CdFormulaCalculoBloco = FBE.CdFormulaCalculoBloco
              INNER JOIN EPagExpressaoFormCalc EFC
                      ON EFC.CdExpressaoFormCalc = FCB.CdExpressaoFormCalc
              INNER JOIN EpagHistFormulaCalculo HFC
                      ON EFC.CdHistFormulaCalculo= HFC.CdHistFormulaCalculo
              INNER JOIN Epagformulaversao FV
                      ON FV.CdFormulaVersao = HFC.CdFormulaVersao
              INNER JOIN Epagformulacalculo FC
                      ON FV.CdFormulaCalculo = FC.CdFormulaCalculo
       WHERE (FC.CdAgrupamento = pCdAgrupamento OR
              FC.CdOrgao = pCdOrgao) /*AND
              FV.NuFormulaVersao = pNuVersao*/) A
     START WITH A.CdRubricaAgrupamento = pCdRubAgrp AND
                ((A.NuAnoInicio < pNuAnoReferencia OR
                (A.NuAnoInicio = pNuAnoReferencia AND
                A.NuMesInicio <= pNuMesReferencia))
                AND
                (A.NuAnoFim > pNuAnoReferencia OR
                (A.NuAnoFim = pNuAnoReferencia AND
                A.NuMesFim >= pNuMesReferencia) OR
                A.NuAnoFim IS NULL))
     CONNECT BY PRIOR CdRubricaFilha = A.CdRubricaAgrupamento AND
                      ((A.NuAnoInicio < pNuAnoReferencia OR
                      (A.NuAnoInicio = pNuAnoReferencia AND
                      A.NuMesInicio <= pNuMesReferencia))
                      AND
                      (A.NuAnoFim > pNuAnoReferencia OR
                      (A.NuAnoFim = pNuAnoReferencia AND
                      A.NuMesFim >= pNuMesReferencia) OR
                      A.NuAnoFim IS NULL));

    RETURN FALSE;

  EXCEPTION

    WHEN OTHERS THEN

      IF SQLCODE = -1436 THEN

         RETURN TRUE;

       ELSE

         RETURN FALSE;

      END IF;

  END;

BEGIN

  /*IF pCdRubricaAgrupamento IS NOT NULL THEN

    IF FTemDependencia(pCdRubricaAgrupamento) THEN

      RETURN 2164;

    ELSE

      RETURN 0;

    END IF;

  ELSE*/
  /*
    FOR vRub IN (SELECT BC.CdBaseCalculo,
                        BC.CdOrgao,
                        BC.SgBaseCalculo,
                        BCBA.CdRubricaagrupamento
                   FROM EPagBaseCalculo BC
                  INNER JOIN Epagbasecalculoversao BCV
                     ON BC.CdBaseCalculo = BCV.CdBaseCalculo
                  INNER JOIN EpagHistBaseCalculo HBC
                     ON HBC.CdVersaoBaseCalculo = BCV.CdVersaoBaseCalculo
                  INNER JOIN Epagbasecalculobloco BCB
                     ON BCB.CdHistBaseCalculo = HBC.CdHistBaseCalculo
                  INNER JOIN EpagBaseCalculoBlocoExpressao BCE
                     ON BCB.CdBaseCalculoBloco = BCE.CdBaseCalculoBloco
                  INNER JOIN  Epagbasecalcblocoexprrubagrup BCBA
                     ON BCE.CdBaseCalculoBlocoExpressao = BCBA.CdBaseCalculoBlocoExpressao
                  WHERE (BC.CdAgrupamento = pCdAgrupamento OR
                         BC.CdOrgao = pcdOrgao)\* AND
                         BCV.NuVersao = pnuVersao*\ AND
                         BC.SgBaseCalculo = pSgBaseCalculo AND
                         HBC.NUANOFIMVIGENCIA IS NULL AND
                         BCBA.CdRubricaAgrupamento IN
                              (SELECT CdRubricaAgrupamento
                                 FROM EPagformulacalculo F
                                INNER JOIN EpagFormulaVersao FV
                                   ON F.CdFormulaCalculo = FV.CdFormulaCalculo
                                INNER JOIN EpagHistFormulaCalculo HFC
                                   ON HFC.CdFormulaVersao = FV.CdFormulaVersao
                                WHERE (F.CdAgrupamento = pCdAgrupamento OR
                                       F.CdOrgao = pcdOrgao)\* AND
                                       FV.NuFormulaVersao = pNuVersao*\))
    LOOP

      IF FTemDependencia(vRub.CdRubricaagrupamento) THEN

        RETURN 2164;

      END IF;

    END LOOP;  */

    RETURN 0;

  --END IF;

END;

/*-----------------------------------------------------------------------------------------/
     Objetivo: Retornar os salarios de contribuicao conforme os parametros de vinculo e
               periodo de referencia informados.

   -- Autor: Rafael Gomes
   -- Data: 08/04/2008

   -- Alteracao:
   -- Data: 17/11/2009
   -- Quando calcular o VLMes considerando as modalidade rubrica 1, 2 e 25
      sendo que no mes/ano deve ser usada apenas uma
      na sequinte sequencia de prioridade 25, 1 e 2

      -- foi liberado as rubricas com modalidades 1, 2, 25

      -- foi re-feito o calculo do VLmes atraves da vVLPagamentoNovo
         antes de inserir EPAGSALCONTRIBAPOTMP
/*-----------------------------------------------------------------------------------------*/

PROCEDURE PPesquisaSalContribApo (pCdVinculo         IN INTEGER,
                                  pNuMesInicio       IN INTEGER,
                                  pNuAnoInicio       IN INTEGER,
                                  pNuMesFim          IN INTEGER,
                                  pNuAnoFim          IN INTEGER,
                                  pNuMesAplicIndice  IN INTEGER,
                                  pNuAnoAplicIndice  IN INTEGER,
                                  Resultado          OUT types.ref_cursor) IS

BEGIN

    PKGPVD.PPesquisaSalContribApo (pCdVinculo,
                                   pNuMesInicio,
                                   pNuAnoInicio,
                                   pNuMesFim,
                                   pNuAnoFim,
                                   pNuMesAplicIndice,
                                   pNuAnoAplicIndice,
                                   1,
                                   Resultado);

END;

/*-----------------------------------------------------------------------------------------/
     Objetivo: Recuperar Dados da Rubrica
     Parametro: [N] para retornar o numero ou
                [D] para retornar a descricao
/*-----------------------------------------------------------------------------------------*/

FUNCTION FRecuperarNmRubricaAgr(pCdRubricaAgrupamento IN NUMBER,
                                pTipoConsulta         VARCHAR2
                                ) RETURN VARCHAR2 IS
  Result                VARCHAR2(90);
  vNuRubricaAgrupamento VARCHAR2(7);
  vDeRubricaAgrupamento VARCHAR2(90);

BEGIN

  SELECT
  -- Numero da rubrica no agrupamento
  lpad(PAGA26.NuTipoRubrica,2,'0') || '-' || lpad(PAGA29.NuRubrica,4,'0') AS NuRubricaAgrupamento,

  -- Descricao da rubrica no agrupamento
  CASE PAGA26.FlTipoAdjacente WHEN 'S' THEN
    CASE WHEN PAGA27.DeTipoRubricaAgrup IS NULL THEN
      PAGA26.DeTipoRubrica || '-' || PAGA35.DeRubricaAgrupamento
    ELSE PAGA27.DeTipoRubricaAgrup || '-' || PAGA35.DeRubricaAgrupamento END
  ELSE PAGA35.DeRubricaAgrupamento
  END AS DeRubricaAgrupamento
  INTO
  vNuRubricaAgrupamento,
  vDeRubricaAgrupamento

  FROM
  EPAGRUBRICA PAGA29
  INNER JOIN EPAGRUBRICAAGRUPAMENTO PAGA34 ON PAGA29.CdRubrica = PAGA34.CdRubrica
  INNER JOIN EPAGHISTRUBRICAAGRUPAMENTO PAGA35 ON PAGA34.CdRubricaAgrupamento = PAGA35.CdRubricaAgrupamento
  INNER JOIN EPAGTIPORUBRICA PAGA26 ON PAGA29.CdTipoRubrica = PAGA26.CdTipoRubrica
  INNER JOIN EPAGTIPORUBRICAAGRUP PAGA27 ON  (PAGA26.CdTipoRubrica = PAGA27.CdTipoRubrica
                                             and paga27.cdagrupamento = paga34.cdagrupamento)

  WHERE
  (PAGA35.NuAnoInicioVigencia < TO_CHAR(SYSDATE, 'YYYY') OR
  ( PAGA35.NuAnoInicioVigencia = TO_CHAR(SYSDATE, 'YYYY') AND
  PAGA35.NuMesInicioVigencia <= TO_CHAR(SYSDATE, 'MM'))) AND
  ( PAGA35.NuAnoFimVigencia > TO_CHAR(SYSDATE, 'YYYY') OR
  ( PAGA35.NuAnoFimVigencia = TO_CHAR(SYSDATE, 'YYYY') AND
  PAGA35.NuMesFimVigencia >= TO_CHAR(SYSDATE, 'MM')) OR
  PAGA35.NuAnoFimVigencia IS NULL)
  -- Para a rubrica agrupamento informada
  AND PAGA34.CDRUBRICAAGRUPAMENTO = pCdRubricaAgrupamento;

  IF (pTipoConsulta = 'N') THEN
    Result := vNuRubricaAgrupamento;
  ELSIF (pTipoConsulta = 'D') then
    Result := vDeRubricaAgrupamento;
  ELSE
  Result := 'ERRO';
  END  IF;

  RETURN(Result);
  -- Caso nao encontre dados
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    Result := NULL;
    RETURN(Result);
END FRecuperarNmRubricaAgr;

/*-----------------------------------------------------------------------------------------/
     Objetivo: Emitir Proventos
     -- [I]nstrucao ou [C]oncessao
/*-----------------------------------------------------------------------------------------*/
PROCEDURE PEmitirProventosVantPecApo(p_CdVinculoContra     IN NUMBER DEFAULT 0,
                                     p_FlTipoPesquisa      IN STRING DEFAULT NULL, -- [I]nstrucao ou [C]oncessao
                                     Resultado             OUT types.ref_cursor ) IS
  v_CdOrgao number := 0;
  v_CdAgrupamento number := 0;
  v_dtUltFolha pls_integer;
  v_cdUltFolha number := 0;
  v_CdRubricaAgrVenc number := 0;
  v_SqlResultadoCrystal varchar2(400);

begin

-- Define o SQL de retorno para o Crystal ou quando houver uma excecao.
    v_SqlResultadoCrystal := '
       Select
               Null as cdrubricaagrupamento,
               Null as CdTipo,
               Null as CdRubrica,
               Null as DeRubrica,
               Null as VlPagamento
       From dual';

  -- Obter o Orgao e o Agrupamento do vinculo
      Select v.cdorgao , o.cdagrupamento
      Into v_CdOrgao, v_CdAgrupamento
      From ECadVinculo v
           Inner Join ECadOrgao o on (o.cdorgao = v.cdorgao)
      Where v.cdvinculo = p_CdVinculoContra;

  -- Obter a rubrica de vencimento
      Select ev.cdrubricaagrupamento Into v_CdRubricaAgrVenc
      From EPagEventoPagAgrup ev
      Where ev.cdagrupamento = v_CdAgrupamento
      and ev.cdtipoeventopagamento = 1;

  -- Obter a data da ultima folha de pagamento aberta no orgao do vinculo

if (upper(p_FlTipoPesquisa) = 'I') then

     Select max(f.nuanomesreferencia)
            into v_dtUltFolha
      From
            EPagHistoricoRubricaVinculo h
            Inner Join EPagFolhaPagamento f on (f.cdfolhapagamento = h.cdfolhapagamento)
            Inner Join EPagTipoFolhaPagamento tf on (tf.cdtipofolhapagamento = f.cdtipofolhapagamento)
      Where
            h.cdvinculo = p_CdVinculoContra
            and f.cdorgao = v_CdOrgao
            and f.flcalculodefinitivo = 'N'
            -- Folha normal calculo normal
            and f.cdtipocalculo = 1
            and tf.cdtipofolha  = 1
            /*and f.flfolhareaberta = 'S'*/;

   -- Obter o ultimo processamento de folha aberta individual do servidor excutado pela aplicacao para geracao do relatorio
      Select f.cdfolhapagamento into v_cdUltFolha
      From EPagFolhaPagamento f
           Inner Join EPagTipoFolhaPagamento ti on (f.cdtipoFolhaPagamento = ti.cdTipoFolhaPagamento)
      Where
           f.cdorgao = v_CdOrgao
            -- Folha normal calculo normal
              and f.cdtipocalculo = 1
              and ti.cdtipofolha  = 1

           and f.flcalculodefinitivo = 'N'/*

           and f.flfolhareaberta = 'S'*/
           and f.nuanomesreferencia = v_dtUltFolha;

   -- Obter as rubricas
   Open Resultado For
        Select
               decode(ra.cdrubricaagrupamento, v_CdRubricaAgrVenc, 1,2) as CdTipo,
               ra.cdrubricaagrupamento,
               lpad(ti.nutiporubrica,2,0) ||'-'|| lpad(ru.nuRubrica,4,0)||'-'|| lpad(h.nusufixorubrica,2,0) as CdRubrica,
               ti.nmtiporubrica ||' '|| hra.derubricaagrupamento as DeRubrica,
               FFormataNumero(h.VlPagamento, 2) as VlPagamento

        From EPagHistoricoRubricaVinculo h
             Inner Join EPagRubricaAgrupamento ra on (ra.cdrubricaagrupamento = h.cdrubricaagrupamento)
             Inner Join EPagHistRubricaAgrupamento hra on (hra.cdrubricaagrupamento = ra.cdrubricaagrupamento)
             Inner Join EPagRubrica ru            on (ru.cdrubrica = ra.cdrubrica)
             Inner Join EpagTipoRubrica ti        on (ti.cdtiporubrica = ru.cdtiporubrica)
        Where
             h.cdvinculo = p_CdVinculoContra
             and h.cdfolhapagamento = v_cdUltFolha
             and ru.cdtiporubrica = 1
        Order by 1;
else
     Open Resultado For v_SqlResultadoCrystal;

end if;

exception
    when others then
         Open Resultado For v_SqlResultadoCrystal;

end PEmitirProventosVantPecApo;

PROCEDURE PValidarExpressao (PExpressao IN VARCHAR2, PRetorno OUT NUMBER)  IS
           
    vexpressao  VARCHAR2(800);   -- PKGPAG_FB.tdescformula             
           
BEGIN         
  
  vexpressao := REPLACE(pexpressao, ',', '.');     
  
  If substr(vExpressao,1,1) = '=' THEN
     vExpressao := substr(vExpressao,2);
  END IF;
  
  PRetorno := pkgmath.fcalcular(vexpressao);         
         
  IF PRetorno is NULL THEN
  
    PRetorno := 0;
  
  ELSE
             
    PRetorno := 1;         
             
  END IF;         
          
END;         

END PKGPAG;
/
