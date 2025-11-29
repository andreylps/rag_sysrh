CREATE OR REPLACE PACKAGE PKGPAG_BEP IS

FUNCTION FRetornarJurosAcumulados(ref_inicial varchar2,ref_final varchar2,cdvalorref  INTEGER) RETURN NUMBER;

FUNCTION FRetornarJuros(ref_folha varchar2,cdvalorref INTEGER) RETURN NUMBER; 

FUNCTION FValorJurosParcelaAnterior(pCdProcessoBEP INTEGER, pNuParcela INTEGER) return number; 

FUNCTION FContemDetalhamento(pCdProcessamentoBEP INTEGER) RETURN NUMBER;

PROCEDURE cancelarProcessamento(pCDPROCESSAMENTOBEP IN INTEGER);

PROCEDURE obterDataFolha (pCDAgrupamento IN  EPAGFOLHAPAGAMENTO.CDAGRUPAMENTO%TYPE,p_dtInicio OUT DATE,p_referencia OUT VARCHAR2
);                                   

PROCEDURE recuperarRubricasBEP(pCDAgrupamento IN EPAGFOLHAPAGAMENTO.CDAGRUPAMENTO%TYPE, pRubricaPgto OUT EPAGAGRUPAMENTOPARAMETRO.CDRUBAGRUPPGTOBEP%TYPE, pRubricaCorrecao OUT EPAGAGRUPAMENTOPARAMETRO.CDRUBAGRUPCORBEP%TYPE) ;
                                    
PROCEDURE PGeraParcelasAGPE(pCdTarefa IN INTEGER);

PROCEDURE PGeraParcelasDPSC(pCdTarefa IN INTEGER);
  
PROCEDURE PAtualizaParcelasBEP(pCdTarefa IN INTEGER, pCdAgrupamento IN INTEGER);

PROCEDURE Reprocessamento(pCDPROCESSAMENTOBEP IN INTEGER);

PROCEDURE gerarLanctoParcela(pCDPROCESSOBEPPARCELAS IN INTEGER,pCDPROCESSAMENTOBEP IN INTEGER);

PROCEDURE excluirIndividual(pCDPROCESSAMENTOBEPDETALHE IN INTEGER);



END PKGPAG_BEP;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_BEP IS


    -- Recuperar valor de juros acumulados de um Determinado Valor de Referencia(CDVALORREFERENCIA) em um determinado periodo (MMYYYY INICIAL - MMYYYY FINAL)
FUNCTION FRetornarJurosAcumulados(ref_inicial varchar2,
                                  ref_final    varchar2,
                                  cdvalorref  INTEGER)
  RETURN NUMBER IS
  juros_acumulados NUMBER := 0;

BEGIN
  SELECT NVL(SUM(HVR.VLREFERENCIA),0)/100
          INTO juros_acumulados
    FROM EPAGVALORREFERENCIA VR
   INNER JOIN EPAGVALORREFERENCIAVERSAO VRV       ON VRV.CDVALORREFERENCIA = VR.CDVALORREFERENCIA      AND VR.CDVALORREFERENCIA = cdvalorref
   INNER JOIN EPAGHISTVALORREFERENCIA HVR       ON HVR.CDVALORREFERENCIAVERSAO = VRV.CDVALORREFERENCIAVERSAO

   WHERE
         HVR.NUANOINICIOVIGENCIA*100+HVR.NUMESINICIOVIGENCIA >=  ref_inicial
         AND HVR.NUANOINICIOVIGENCIA*100+HVR.NUMESINICIOVIGENCIA <= ref_final;

  RETURN juros_acumulados;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
  WHEN OTHERS THEN
    RAISE;
END FRetornarJurosAcumulados;

FUNCTION FRetornarJuros(ref_folha varchar2, cdvalorref INTEGER)

  RETURN NUMBER IS
  v_juros NUMBER := 0;
                                              
BEGIN
  SELECT NVL(HVR.VLREFERENCIA, 0) / 100 
    INTO v_juros      
    FROM EPAGVALORREFERENCIA VR
   INNER JOIN EPAGVALORREFERENCIAVERSAO VRV ON VRV.CDVALORREFERENCIA = VR.CDVALORREFERENCIA
     AND VR.CDVALORREFERENCIA = cdvalorref
   INNER JOIN EPAGHISTVALORREFERENCIA HVR ON HVR.CDVALORREFERENCIAVERSAO = VRV.CDVALORREFERENCIAVERSAO
  
   WHERE 
         HVR.NUANOINICIOVIGENCIA * 100 + HVR.NUMESINICIOVIGENCIA <= ref_folha
              AND HVR.NUANOFIMVIGENCIA IS NULL OR HVR.NUANOFIMVIGENCIA * 100 + HVR.NUMESFIMVIGENCIA >= ref_folha;

  RETURN v_juros;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
  WHEN OTHERS THEN
    RAISE;       
END FRetornarJuros;  

FUNCTION FValorJurosParcelaAnterior(pCdProcessoBEP INTEGER, pNuParcela INTEGER)

  RETURN NUMBER IS
  v_vlrJuros NUMBER := 0;
                                              
BEGIN
  SELECT NVL(PA.VLJUROS,0)
       INTO v_vlrJuros
   FROM EPAGPROCESSOBEPPARCELAS PA 
              INNER JOIN EPAGPROCESSOBEP PB ON PB.CDPROCESSOBEP = PA.CDPROCESSOBEP
WHERE PA.CDPROCESSOBEP = pCdProcessoBEP and PA.NUPARCELA = (pNuParcela-1);

  RETURN v_vlrJuros;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
  WHEN OTHERS THEN
    RAISE;       
END FValorJurosParcelaAnterior;   

FUNCTION FContemDetalhamento(pCdProcessamentoBEP INTEGER)
  
RETURN NUMBER IS nrDetalhamento NUMBER := 0;

BEGIN
  SELECT COUNT(*) INTO nrDetalhamento FROM EPAGPROCESSAMENTOBEP PB WHERE PB.CDPROCESSAMENTOBEP = pCdProcessamentoBEP;
  RETURN nrDetalhamento;
  
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN -1;
  WHEN OTHERS THEN
    RAISE;
END FContemDetalhamento;  


PROCEDURE obterDataFolha (
    pCDAgrupamento     IN  EPAGFOLHAPAGAMENTO.CDAGRUPAMENTO%TYPE,
    p_dtInicio           OUT DATE,
    p_referencia         OUT VARCHAR2
) IS
BEGIN
  SELECT 
    CASE
                  WHEN LENGTH(MAX(FP.NUANOMESREFERENCIA)) = 6 THEN 
                      TO_DATE(MAX(FP.NUANOMESREFERENCIA) || '01', 'YYYYMMDD')
                  ELSE
                      NULL
    END AS DTINICIO,
    MAX(FP.NUANOMESREFERENCIA) AS REFERENCIA  
      INTO p_dtInicio, p_referencia
FROM 
    EPAGFOLHAPAGAMENTO FP
    INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP ON FP.CDTIPOFOLHAPAGAMENTO = TFP.CDTIPOFOLHAPAGAMENTO AND TFP.CDTIPOFOLHA = 24 -- FOLHA BEP (SC PREV)
WHERE 
    FP.CDAGRUPAMENTO = pCDAgrupamento
    AND FP.FLCALCULODEFINITIVO = 'N'
    AND TO_NUMBER(SUBSTR(FP.NUANOMESREFERENCIA, 1, 6)) >= TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMM'))
GROUP BY 
    FP.CDAGRUPAMENTO;   
       
   EXCEPTION
    WHEN NO_DATA_FOUND THEN

        p_dtInicio := NULL;
        p_referencia := NULL;

       
END obterDataFolha;

PROCEDURE recuperarRubricasBEP(pCDAgrupamento IN EPAGFOLHAPAGAMENTO.CDAGRUPAMENTO%TYPE, pRubricaPgto OUT EPAGAGRUPAMENTOPARAMETRO.CDRUBAGRUPPGTOBEP%TYPE, pRubricaCorrecao OUT EPAGAGRUPAMENTOPARAMETRO.CDRUBAGRUPCORBEP%TYPE) IS 
  
BEGIN
  SELECT DISTINCT 
        NVL(PA.CDRUBAGRUPCORBEP,0) AS CORRECAO, 
        NVL(PA.CDRUBAGRUPPGTOBEP,0) AS PGTO 
        INTO pRubricaCorrecao,pRubricaPgto
    FROM EPAGAGRUPAMENTOPARAMETRO PA
    INNER JOIN EPAGRUBRICAAGRUPAMENTO RA 
        ON RA.CDRUBRICAAGRUPAMENTO IN (PA.CDRUBAGRUPCORBEP, PA.CDRUBAGRUPPGTOBEP)
    WHERE PA.CDAGRUPAMENTO = pCDagrupamento
      AND PA.NUANOFIMVIGENCIA IS NULL;


END recuperarRubricasBEP;

PROCEDURE PGeraParcelasAGPE(pCdTarefa IN INTEGER)  IS 

  BEGIN
   PKGPAG_BEP.PAtualizaParcelasBEP(pCdTarefa => pCdTarefa, pCdAgrupamento => 1);
  EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
 
    
END PGeraParcelasAGPE;

PROCEDURE PGeraParcelasDPSC(pCdTarefa IN INTEGER)  IS 

  BEGIN
   PKGPAG_BEP.PAtualizaParcelasBEP(pCdTarefa => pCdTarefa, pCdAgrupamento => 176);
  EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
 
    
END PGeraParcelasDPSC;


PROCEDURE PAtualizaParcelasBEP (pCdTarefa IN INTEGER,pCdAgrupamento IN INTEGER) IS

   vNuSufixo  INTEGER;
   v_contador INTEGER := 1;
   v_CDProcessamentoBEP INTEGER;
   v_LFParcela INTEGER;
   v_LFJuros INTEGER;
   
   v_dtInicio   DATE;
   v_dtFim      DATE;
   v_referencia VARCHAR2(6);

  

    CURSOR c_agrupamentos is 
     SELECT AGTO.CDAGRUPAMENTO FROM ECADAGRUPAMENTO AGTO WHERE AGTO.CDAGRUPAMENTO = pCdAgrupamento;
     rec_agrupamentos c_agrupamentos%ROWTYPE;


    CURSOR c_processos_bep (p_cdagrupamento NUMBER) IS

      SELECT DISTINCT PB.CDPROCESSOBEP
      FROM EPAGPROCESSOBEP PB
     INNER JOIN EPAGPROCESSOBEPPARCELAS PBP ON PBP.CDPROCESSOBEP = PB.CDPROCESSOBEP
           INNER JOIN ECADVINCULO V ON V.CDVINCULO = PB.CDVINCULO
           INNER JOIN ECADHISTORGAO HO ON HO.CDORGAO = V.CDORGAO AND HO.DTFIMVIGENCIA IS NULL AND HO.FLANULADO = 'N' AND HO.CDAGRUPAMENTO = p_cdagrupamento
     WHERE PBP.INSITUACAOPARCELA = 2;

     rec_processos_bep c_processos_bep%ROWTYPE;


    CURSOR c_parcelas_bep(p_cdagrupamento NUMBER) IS
    SELECT PBP.CDPROCESSOBEP,
           PBP.CDPROCESSOBEPPARCELAS,
           PB.CDVINCULO,
           PBP.NUPARCELA,
           PBP.VLPARCELA,

           (PKGPAG_BEP.FRetornarJuros(TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'YYYYMM'),PB.CDVALORREFERENCIA) * (PBP.VLPARCELA+PKGPAG_BEP.FValorJurosParcelaAnterior(PBP.CDPROCESSOBEP,MIN(PBP.NUPARCELA) OVER (PARTITION BY PBP.CDPROCESSOBEP) )))+PKGPAG_BEP.FValorJurosParcelaAnterior(PBP.CDPROCESSOBEP,MIN(PBP.NUPARCELA) OVER (PARTITION BY PBP.CDPROCESSOBEP)) AS VLJUROS,
           PB.NUPARCELAS,
           HO.CDAGRUPAMENTO,
           TFP.CDTIPOFOLHAPAGAMENTO
      FROM EPAGPROCESSOBEP PB
     INNER JOIN EPAGPROCESSOBEPPARCELAS PBP ON PBP.CDPROCESSOBEP = PB.CDPROCESSOBEP
     INNER JOIN ECADVINCULO V ON V.CDVINCULO = PB.CDVINCULO
     INNER JOIN ECADHISTORGAO HO ON HO.CDORGAO = V.CDORGAO AND (HO.DTFIMVIGENCIA > SYSDATE OR HO.DTFIMVIGENCIA IS NULL) AND HO.CDAGRUPAMENTO = p_cdagrupamento
     INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP ON TFP.CDAGRUPAMENTO = HO.CDAGRUPAMENTO AND TFP.CDTIPOFOLHA = 24 -- BENEFICIO ESPECIAL
     WHERE PBP.INSITUACAOPARCELA = 2;

    rec_parcelas_bep c_parcelas_bep%ROWTYPE;

    CURSOR c_rubricas_bep (p_cdagrupamento NUMBER) IS

    SELECT PA.CDRUBAGRUPPGTOBEP AS RUBRICA_PGTO,
           PA.CDRUBAGRUPCORBEP AS RUBRICA_CORRECAO
      FROM EPAGAGRUPAMENTOPARAMETRO PA
     WHERE PA.CDAGRUPAMENTO = p_cdagrupamento
       AND (PA.NUANOFIMVIGENCIA IS NULL AND PA.NUMESFIMVIGENCIA IS NULL);

    rec_rubricas_bep c_rubricas_bep%ROWTYPE;

BEGIN
    OPEN c_agrupamentos;
LOOP
          FETCH c_agrupamentos INTO rec_agrupamentos;
          EXIT WHEN c_agrupamentos%NOTFOUND;
          
          v_contador := 1; --zera o contador para novo agrupamento
         

          PKGPAG_BEP.obterDataFolha(rec_agrupamentos.CDAGRUPAMENTO,v_dtInicio,v_referencia);
          
          OPEN c_processos_bep(rec_agrupamentos.CDAGRUPAMENTO);
          FETCH c_processos_bep INTO rec_processos_bep;
          IF   c_processos_bep%NOTFOUND THEN
               UPDATE EAdmTarefa T SET T.DtTerminoReal = SYSDATE,T.CdSituacaoTarefa = 4,T.DERELATORIO = 'ATENÇÃO: Não existem Processos/Parcelas BEP com situação de lançamento para essa folha! Processamento encerrado.' WHERE T.CdTarefa = pCdTarefa;

             v_CDProcessamentoBEP := SPAGPROCESSAMENTOBEP.NEXTVAL;
                
             INSERT INTO EPAGPROCESSAMENTOBEP (CDPROCESSAMENTOBEP,
                                               NUANOMESREFERENCIA,
                                               DTPROCESSAMENTO,
                                               DTFIMPROCESSAMENTO,
                                               NUCPFCADASTRADOR,
                                               DTULTALTERACAO,CDAGRUPAMENTO,CDTAREFA)
                                                VALUES(v_CDProcessamentoBEP,to_char(sysdate,'YYYYMM'),SYSDATE,SYSDATE,'22222222222',SYSTIMESTAMP,pCdAgrupamento,pCdTarefa);
             INSERT INTO EPAGPROCESSAMENTOBEPDETALHE (CDPROCESSAMENTOBEPDETALHE,
                                         CDPROCESSAMENTOBEP,
                                         CDPROCESSOBEPPARCELAS,
                                         CDLANCAMENTOFINANCEIROPARCELA,
                                         CDLANCAMENTOFINANCEIROJUROS,
                                         INSITUACAO,
                                         DTULTALTERACAO,
                                         FLCOMPLEMENTAR) 
                                         VALUES
                                         (SPAGPROCESSAMENTOBEPDETALHE.NEXTVAL,
                                         v_CDProcessamentoBEP,  
                                         (SELECT MAX(CDPROCESSOBEPPARCELAS) FROM EPAGPROCESSOBEPPARCELAS),
                                         NULL,
                                         NULL,
                                         3,
                                         SYSTIMESTAMP,
                                         'N');
          END IF;

          OPEN c_parcelas_bep(rec_agrupamentos.CDAGRUPAMENTO);

        LOOP
        FETCH c_parcelas_bep INTO rec_parcelas_bep;
        --COMEÇO
        IF c_parcelas_bep%FOUND THEN
                  -- Verificação se tem folha bep aberta para o mes atual - SE NAO TIVER INTERROMPE A EXECUÇÃO
          IF v_referencia IS NULL OR v_dtInicio IS NULL THEN
                   --- finaliza tarefa do bep
             UPDATE EAdmTarefa T SET T.DtTerminoReal = SYSDATE,T.CdSituacaoTarefa = 4,T.DERELATORIO = 'ATENÇÃO: Não existe folha BEP aberta! Processamento encerrado.' WHERE T.CdTarefa = pCdTarefa;

             v_CDProcessamentoBEP := SPAGPROCESSAMENTOBEP.NEXTVAL;

             INSERT INTO EPAGPROCESSAMENTOBEP (CDPROCESSAMENTOBEP,
                                               NUANOMESREFERENCIA,
                                               DTPROCESSAMENTO,
                                               DTFIMPROCESSAMENTO,
                                               NUCPFCADASTRADOR,
                                               DTULTALTERACAO,CDAGRUPAMENTO,CDTAREFA)
                                                VALUES(v_CDProcessamentoBEP,to_char(sysdate,'YYYYMM'),SYSDATE,SYSDATE,'22222222222',SYSTIMESTAMP,pCdAgrupamento,pCdTarefa);
             INSERT INTO EPAGPROCESSAMENTOBEPDETALHE (CDPROCESSAMENTOBEPDETALHE,
                                         CDPROCESSAMENTOBEP,
                                         CDPROCESSOBEPPARCELAS,
                                         CDLANCAMENTOFINANCEIROPARCELA,
                                         CDLANCAMENTOFINANCEIROJUROS,
                                         INSITUACAO,
                                         DTULTALTERACAO,
                                         FLCOMPLEMENTAR)
                                         VALUES
                                         (SPAGPROCESSAMENTOBEPDETALHE.NEXTVAL,
                                         v_CDProcessamentoBEP,
                                         (SELECT MAX(CDPROCESSOBEPPARCELAS) FROM EPAGPROCESSOBEPPARCELAS),
                                         NULL,
                                         NULL,
                                         3,
                                         SYSTIMESTAMP,
                                         'N');

             return;  
          END IF;
        END IF; 

        EXIT WHEN c_parcelas_bep%NOTFOUND;

        IF v_contador = 1
          THEN
              v_CDProcessamentoBEP := SPAGPROCESSAMENTOBEP.NEXTVAL;
              INSERT INTO EPAGPROCESSAMENTOBEP (CDPROCESSAMENTOBEP,
                                                NUANOMESREFERENCIA,
                                                DTPROCESSAMENTO,
                                                DTFIMPROCESSAMENTO,
                                                NUCPFCADASTRADOR,
                                                DTULTALTERACAO,
                                                CDAGRUPAMENTO,
                                                CDTAREFA) VALUES(v_CDProcessamentoBEP,v_referencia,SYSDATE,NULL,'22222222222',                                                                SYSTIMESTAMP,rec_agrupamentos.CDAGRUPAMENTO,pCdTarefa);
        END IF;
        v_contador := v_contador + 1; 
      

        OPEN c_rubricas_bep(rec_agrupamentos.CDAGRUPAMENTO);

        LOOP
            FETCH c_rubricas_bep INTO rec_rubricas_bep; 
            --
            
            --
            EXIT WHEN c_rubricas_bep%NOTFOUND;

            vNuSufixo := 0;
            --recupera nusufixorubrica
            SELECT NVL(MAX(LP.NUSUFIXORUBRICA), 0)
            into vNuSufixo
            FROM EPAGLANCAMENTOFINANCEIRO LP WHERE LP.CDVINCULO = rec_parcelas_bep.CDVINCULO AND LP.CDRUBRICAAGRUPAMENTO = rec_rubricas_bep.RUBRICA_PGTO AND LP.DTINICIODIREITO = TRUNC(SYSDATE, 'MM');
            -- Insert RUBRICA PAGAMENTO  EPAGLANCAMENTOFINANCEIRO
            
            v_LFParcela := SPAGLANCAMENTOFINANCEIRO.NEXTVAL;
             v_dtFim := LAST_DAY(v_dtInicio);
            
            INSERT INTO EPAGLANCAMENTOFINANCEIRO
                (CDLANCAMENTOFINANCEIRO, CDVINCULO, NUSUFIXORUBRICA, DTINICIODIREITO,DTFIMDIREITO, NUCPFCADASTRADOR, CDRUBRICAAGRUPAMENTO, VLLANCAMENTOFINANCEIRO, INPERIODICIDADE,CDTIPOCALCULO,NUSEQUENCIALFOLHA,CDTIPOFOLHAPAGAMENTO, CDPROCESSOBEPPARCELAS,FLAUTOMATICO,NUPARCELAS,FLPROPDEMITIDONOMES,FLVALORPROPORCIONAL,FLPAGAAFASTDEFINITIVO,FLPAGAAFASTTEMPSEMREMUN)
            VALUES
                (v_LFParcela, rec_parcelas_bep.CDVINCULO, vNuSufixo+1, v_dtInicio,v_dtFim, '22222222222', rec_rubricas_bep.RUBRICA_PGTO, rec_parcelas_bep.VLPARCELA, 'P',1,1,rec_parcelas_bep.CDTIPOFOLHAPAGAMENTO,rec_parcelas_bep.CDPROCESSOBEPPARCELAS,'S',1,'N','N','S','S');
                

            vNuSufixo := 0;
            --recupera nusufixorubrica
            SELECT NVL(MAX(LJ.NUSUFIXORUBRICA), 0)
             into vNuSufixo
             FROM EPAGLANCAMENTOFINANCEIRO LJ WHERE LJ.CDVINCULO = rec_parcelas_bep.CDVINCULO AND LJ.CDRUBRICAAGRUPAMENTO = rec_rubricas_bep.RUBRICA_CORRECAO AND LJ.DTINICIODIREITO = TRUNC(SYSDATE, 'MM');
            -- Insert RUBRICA CORREÇÃO EPAGLANCAMENTOFINANCEIRO
            
            v_LFJuros := SPAGLANCAMENTOFINANCEIRO.NEXTVAL;
            
            INSERT INTO EPAGLANCAMENTOFINANCEIRO
                (CDLANCAMENTOFINANCEIRO, CDVINCULO, NUSUFIXORUBRICA, DTINICIODIREITO,DTFIMDIREITO, NUCPFCADASTRADOR, CDRUBRICAAGRUPAMENTO, VLLANCAMENTOFINANCEIRO, INPERIODICIDADE,CDTIPOCALCULO,NUSEQUENCIALFOLHA,CDTIPOFOLHAPAGAMENTO, CDPROCESSOBEPPARCELAS,FLAUTOMATICO,NUPARCELAS,FLPROPDEMITIDONOMES,FLVALORPROPORCIONAL,FLPAGAAFASTDEFINITIVO,FLPAGAAFASTTEMPSEMREMUN)
            VALUES
                (v_LFJuros, rec_parcelas_bep.CDVINCULO, vNuSufixo+1, v_dtInicio,v_dtFim, '22222222222', rec_rubricas_bep.RUBRICA_CORRECAO, rec_parcelas_bep.VLJUROS, 'P',1,1,rec_parcelas_bep.CDTIPOFOLHAPAGAMENTO, rec_parcelas_bep.CDPROCESSOBEPPARCELAS,'S',1,'N','N','S','S');

            INSERT INTO EPAGPROCESSAMENTOBEPDETALHE VALUES (SPAGPROCESSAMENTOBEPDETALHE.NEXTVAL,v_CDProcessamentoBEP,rec_parcelas_bep.CDPROCESSOBEPPARCELAS,v_LFParcela,v_LFJuros,1,SYSTIMESTAMP,'N');
            -- Update EPAGPROCESSOBEPPARCELAS VLJUROS
            UPDATE EPAGPROCESSOBEPPARCELAS
               SET VLJUROS = rec_parcelas_bep.VLJUROS, INSITUACAOPARCELA = 3 --PAGO
             WHERE CDPROCESSOBEP = rec_parcelas_bep.CDPROCESSOBEP
               AND CDPROCESSOBEPPARCELAS = rec_parcelas_bep.CDPROCESSOBEPPARCELAS;

        END LOOP;
                  -- UDPATE ATULIZAR PARCELA DO BEP (JUROS(pode ter valor do indice atualizado) E VALOR DA PARCELA (pode ter atualizacao do valor do beneficio BEP))
          UPDATE EPAGPROCESSOBEPPARCELAS PBA SET PBA.VLJUROS = rec_parcelas_bep.vljuros, PBA.VLPARCELA = rec_parcelas_bep.vlparcela                                                                                                                    WHERE PBA.CDPROCESSOBEPPARCELAS = rec_parcelas_bep.cdprocessobepparcelas 
          AND PBA.CDPROCESSOBEP = rec_parcelas_bep.cdprocessobep;    

        CLOSE c_rubricas_bep;

    END LOOP; -- LOOP PARCELAS
    CLOSE c_parcelas_bep;
    UPDATE EPAGPROCESSAMENTOBEP PP SET PP.DTFIMPROCESSAMENTO = SYSDATE WHERE PP.CDPROCESSAMENTOBEP = v_CDProcessamentoBEP;

    -- Update EPAGPROCESSOBEPPARCELAS PROXIMA_PARCELA


        LOOP
        FETCH c_processos_bep INTO rec_processos_bep;
        EXIT WHEN c_processos_bep%NOTFOUND;


        UPDATE EPAGPROCESSOBEPPARCELAS
           SET INSITUACAOPARCELA = 2 -- PAGAR NA PROXIMA FOLHA
         WHERE CDPROCESSOBEP = rec_processos_bep.CDPROCESSOBEP
           AND NUPARCELA = (SELECT MIN(PARCELA.NUPARCELA) FROM EPAGPROCESSOBEPPARCELAS PARCELA WHERE PARCELA.CDPROCESSOBEP = rec_processos_bep.CDPROCESSOBEP AND PARCELA.INSITUACAOPARCELA = 1);

        END LOOP;
    CLOSE c_processos_bep;


      UPDATE EPAGPROCESSOBEP PB
         SET PB.INSITUACAOPROCESSO = 3 --SETA PROCESSO COMO FINALIZADO
       WHERE PB.NUPARCELAS =
             (SELECT COUNT(*)
                FROM EPAGPROCESSOBEPPARCELAS PP
               WHERE PP.INSITUACAOPARCELA IN (3)
                 AND PP.CDPROCESSOBEP = PB.CDPROCESSOBEP) -- SOMENTE PROCESSO COM TODAS AS PARCELAS PAGAS
         AND PB.INSITUACAOPROCESSO = 1; -- SOMENTE PROCESSO COM SITUACAO ATIVO


 END LOOP; --LOOP AGRUPAMENTOS
 CLOSE c_agrupamentos;
 

         --- finaliza tarefa do bep
      UPDATE EAdmTarefa T SET T.DtTerminoReal = SYSDATE,T.CdSituacaoTarefa = 4 WHERE T.CdTarefa = pCdTarefa;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PAtualizaParcelasBEP;

PROCEDURE recuperaParcelaProcessamento(pCDPROCESSAMENTOBEP IN INTEGER, pParcelaAtual OUT INTEGER,pParcelaProxima out INTEGER) is


BEGIN


  
SELECT NVL(PB.CDPROCESSOBEPPARCELAS,0) AS PARCELAATUAL,
       NVL((SELECT PBI.CDPROCESSOBEPPARCELAS FROM EPAGPROCESSOBEPPARCELAS PBI WHERE PBI.CDPROCESSOBEP = PB.CDPROCESSOBEP AND PBI.CDPROCESSOBEPPARCELAS = PB.CDPROCESSOBEPPARCELAS+1 AND PBI.NUPARCELA <= P.NUPARCELAS),0) AS PROXIMA_PARCELA
       INTO pParcelaAtual,pParcelaProxima
       FROM EPAGPROCESSAMENTOBEPDETALHE PD
                 INNER JOIN EPAGPROCESSOBEPPARCELAS PB ON PB.CDPROCESSOBEPPARCELAS = PD.CDPROCESSOBEPPARCELAS
                 INNER JOIN EPAGPROCESSOBEP P ON P.CDPROCESSOBEP = PB.CDPROCESSOBEP

WHERE PD.CDPROCESSAMENTOBEP = pCDPROCESSAMENTOBEP;


  
END recuperaParcelaProcessamento;


PROCEDURE Reprocessamento(pCDPROCESSAMENTOBEP IN INTEGER) IS
  
 vAgrupamento ECADAGRUPAMENTO.CDAGRUPAMENTO%TYPE;
 v_rubrica_pagto EPAGAGRUPAMENTOPARAMETRO.CDRUBAGRUPPGTOBEP%TYPE;
 v_rubrica_correcao EPAGAGRUPAMENTOPARAMETRO.CDRUBAGRUPCORBEP%TYPE;

 
 --RECUPERA AS PARCELAS QUE PRECISA ATUALIZAR
    CURSOR c_parcelas_bep(pCDPROCESSAMENTOBEP INTEGER) IS
    
    SELECT PBP.CDPROCESSOBEP,
           PBP.CDPROCESSOBEPPARCELAS,
           PB.CDVINCULO,
           PBP.NUPARCELA,
           PBP.VLPARCELA,
           /*(PKGPAG_BEP.FRetornarJurosAcumulados(TO_CHAR(PB.DTINCLUSAO, 'YYYYMM'),
                                            TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'YYYYMM'),
                                            PB.CDVALORREFERENCIA) *
           PBP.VLPARCELA) AS VLJUROS,*/
           (PKGPAG_BEP.FRetornarJuros(TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'YYYYMM'),PB.CDVALORREFERENCIA)* (PBP.VLPARCELA+PKGPAG_BEP.FValorJurosParcelaAnterior(PBP.CDPROCESSOBEP,MIN(PBP.NUPARCELA) OVER (PARTITION BY PBP.CDPROCESSOBEP) )))+PKGPAG_BEP.FValorJurosParcelaAnterior(PBP.CDPROCESSOBEP,MIN(PBP.NUPARCELA) OVER (PARTITION BY PBP.CDPROCESSOBEP)) AS VLJUROS,
           PB.NUPARCELAS,
           HO.CDAGRUPAMENTO,
           TFP.CDTIPOFOLHAPAGAMENTO,
           LF.CDLANCAMENTOFINANCEIRO,
           PBD.CDPROCESSAMENTOBEPDETALHE,
           PBD.CDPROCESSAMENTOBEP
      FROM EPAGPROCESSOBEP PB
     INNER JOIN EPAGPROCESSOBEPPARCELAS PBP ON PBP.CDPROCESSOBEP = PB.CDPROCESSOBEP
     INNER JOIN ECADVINCULO V ON V.CDVINCULO = PB.CDVINCULO
     INNER JOIN ECADHISTORGAO HO ON HO.CDORGAO = V.CDORGAO AND (HO.DTFIMVIGENCIA > SYSDATE OR HO.DTFIMVIGENCIA IS NULL) 
     INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP ON TFP.CDAGRUPAMENTO = HO.CDAGRUPAMENTO AND TFP.CDTIPOFOLHA = 24 -- BENEFICIO ESPECIAL
     INNER JOIN EPAGPROCESSAMENTOBEPDETALHE PBD ON PBD.CDPROCESSOBEPPARCELAS = PBP.CDPROCESSOBEPPARCELAS AND PBD.CDPROCESSAMENTOBEP =pCDPROCESSAMENTOBEP
     INNER JOIN EPAGLANCAMENTOFINANCEIRO LF ON LF.CDPROCESSOBEPPARCELAS = PBP.CDPROCESSOBEPPARCELAS;

        rec_parcelas_bep c_parcelas_bep%ROWTYPE;
    
 
BEGIN
 
--RECUPERAR AGRUPAMENTO DO PROCESSSAMENTO
SELECT DISTINCT  HO.CDAGRUPAMENTO INTO vAgrupamento
FROM EPAGPROCESSOBEP P
     INNER JOIN EPAGPROCESSOBEPPARCELAS PP ON P.CDPROCESSOBEP = PP.CDPROCESSOBEP
     INNER JOIN ECADVINCULO V ON V.CDVINCULO = P.CDVINCULO    
     INNER JOIN ECADHISTORGAO HO ON HO.CDORGAO = V.CDORGAO AND HO.DTFIMVIGENCIA IS NULL
     INNER JOIN EPAGPROCESSAMENTOBEPDETALHE PBD ON PBD.CDPROCESSOBEPPARCELAS = PP.CDPROCESSOBEPPARCELAS
     INNER JOIN EPAGPROCESSAMENTOBEP PB ON PB.CDPROCESSAMENTOBEP = PBD.CDPROCESSAMENTOBEP AND PB.CDPROCESSAMENTOBEP = pCDPROCESSAMENTOBEP;

--OBTER REFERENCIA FOLHA    
--     PKGPAG_BEP.obterDataFolha(vAgrupamento,v_dtInicio,v_referencia);

--ATUALIZAR VALOR LANÇAMENTOS FINANCEIROS E PARCELA DO BEP

PKGPAG_BEP.recuperarRubricasBEP(vAgrupamento,v_rubrica_pagto,v_rubrica_correcao);


    OPEN c_parcelas_bep(pCDPROCESSAMENTOBEP);
    
      LOOP
      FETCH c_parcelas_bep INTO rec_parcelas_bep;
      EXIT WHEN c_parcelas_bep%NOTFOUND;
      
           -- UPDATE LANÇAMENTO FINANCEIRO PARCELA
              UPDATE EPAGLANCAMENTOFINANCEIRO LF SET LF.VLLANCAMENTOFINANCEIRO = rec_parcelas_bep.vlparcela,LF.DTULTALTERACAO = SYSTIMESTAMP 
                     WHERE LF.CDRUBRICAAGRUPAMENTO = v_rubrica_pagto           
                           AND LF.CDLANCAMENTOFINANCEIRO = rec_parcelas_bep.cdlancamentofinanceiro
                           AND LF.CDPROCESSOBEPPARCELAS = rec_parcelas_bep.cdprocessobepparcelas;
             
          -- UPDATE LANÇAMENTO FINANCEIRO JUROS
          UPDATE EPAGLANCAMENTOFINANCEIRO LF SET LF.VLLANCAMENTOFINANCEIRO = rec_parcelas_bep.vljuros,LF.DTULTALTERACAO = SYSTIMESTAMP 
                 WHERE LF.CDRUBRICAAGRUPAMENTO = v_rubrica_correcao           
                       AND LF.CDLANCAMENTOFINANCEIRO = rec_parcelas_bep.cdlancamentofinanceiro
                       AND LF.CDPROCESSOBEPPARCELAS = rec_parcelas_bep.cdprocessobepparcelas;             
             
          -- UDPATE ATULIZAR PARCELA DO BEP (JUROS(pode ter valor do indice atualizado) E VALOR DA PARCELA (pode ter atualizacao do valor do beneficio BEP))
          UPDATE EPAGPROCESSOBEPPARCELAS PBA SET PBA.VLJUROS = rec_parcelas_bep.vljuros, PBA.VLPARCELA = rec_parcelas_bep.vlparcela                           WHERE PBA.CDPROCESSOBEPPARCELAS = rec_parcelas_bep.cdprocessobepparcelas 
          AND PBA.CDPROCESSOBEP = rec_parcelas_bep.cdprocessobep;    
          
          --UPDATE DO PROCESSAMENTO DETALHE
          UPDATE EPAGPROCESSAMENTOBEPDETALHE PBD SET PBD.DTULTALTERACAO = SYSTIMESTAMP
                 WHERE PBD.CDPROCESSAMENTOBEPDETALHE = rec_parcelas_bep.CDPROCESSAMENTOBEPDETALHE 
                       AND PBD.CDPROCESSAMENTOBEP = rec_parcelas_bep.CDPROCESSAMENTOBEP
                       and PBD.CDPROCESSOBEPPARCELAS = rec_parcelas_bep.Cdprocessobepparcelas;        
          
          --UPDATE DO PROCESSAMENTO                          
          UPDATE EPAGPROCESSAMENTOBEP PB SET PB.DTULTALTERACAO = SYSTIMESTAMP, PB.DTPROCESSAMENTO = SYSDATE, PB.DTFIMPROCESSAMENTO = SYSDATE
                 WHERE PB.CDPROCESSAMENTOBEP = rec_parcelas_bep.Cdprocessamentobep
;

      END LOOP;
    CLOSE c_parcelas_bep;
--COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;  

END Reprocessamento;



PROCEDURE cancelarProcessamento(pCDPROCESSAMENTOBEP IN INTEGER) IS

v_cdProcessamento integer := pCDPROCESSAMENTOBEP;

  CURSOR c_detalheprocessobep IS
       SELECT LF.CDLANCAMENTOFINANCEIRO,
              PD.CDPROCESSAMENTOBEPDETALHE,
              PB.CDPROCESSOBEPPARCELAS,
              PB.CDPROCESSOBEP
       FROM EPAGLANCAMENTOFINANCEIRO LF
            INNER JOIN EPAGPROCESSAMENTOBEPDETALHE PD ON PD.CDPROCESSOBEPPARCELAS = LF.CDPROCESSOBEPPARCELAS AND PD.CDPROCESSAMENTOBEP = v_cdProcessamento 
            INNER JOIN EPAGPROCESSOBEPPARCELAS PB ON PB.CDPROCESSOBEPPARCELAS = PD.CDPROCESSOBEPPARCELAS;
               
  rec_detalheprocessobep c_detalheprocessobep%ROWTYPE;
                
BEGIN
  
  OPEN c_detalheprocessobep;
  
  LOOP
       FETCH c_detalheprocessobep INTO rec_detalheprocessobep;
       EXIT WHEN c_detalheprocessobep%NOTFOUND;
       
       -- Atualiza detalhes do processamento
       UPDATE EPAGPROCESSAMENTOBEPDETALHE 
          SET INSITUACAO = 2, 
              CDLANCAMENTOFINANCEIROJUROS = NULL,
              CDLANCAMENTOFINANCEIROPARCELA = NULL,
              DTULTALTERACAO = CURRENT_TIMESTAMP
        WHERE CDPROCESSAMENTOBEP = v_cdProcessamento;

       -- Deleta os lançamentos financeiros
       DELETE FROM EPAGLANCAMENTOFINANCEIRO 
        WHERE CDLANCAMENTOFINANCEIRO = rec_detalheprocessobep.CDLANCAMENTOFINANCEIRO
          AND CDPROCESSOBEPPARCELAS = rec_detalheprocessobep.CDPROCESSOBEPPARCELAS;

       -- Atualiza situação da parcela do benefício
       UPDATE EPAGPROCESSOBEPPARCELAS 
          SET INSITUACAOPARCELA = 2 
        WHERE CDPROCESSOBEP = rec_detalheprocessobep.CDPROCESSOBEP
          AND CDPROCESSOBEPPARCELAS = rec_detalheprocessobep.CDPROCESSOBEPPARCELAS;

  END LOOP;

  CLOSE c_detalheprocessobep;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Nenhum registro encontrado para o processamento informado.');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;  
END cancelarProcessamento;


PROCEDURE gerarLanctoParcela(pCDPROCESSOBEPPARCELAS IN INTEGER,pCDPROCESSAMENTOBEP IN INTEGER) IS

    v_cdProcessobep integer;
    v_cdProcessoBepParcelas integer;
    v_cdProcessamento integer;
    v_cdProcessamentoDet integer;
    v_cdAgrupamento integer;
    v_valorJuros EPAGPROCESSOBEPPARCELAS.VLJUROS%TYPE;
    v_vlrParcela EPAGPROCESSOBEPPARCELAS.VLPARCELA%TYPE;
    v_cdVinculo integer;
    v_cdTipoFolhaPagamento integer;
    v_rubricaPgto integer;
    v_rubricaJuros integer;
    v_dtInicio   DATE;
    v_dtFim      DATE;
    v_referencia VARCHAR2(6);
    vNuSufixo        integer;
    v_LFParcela INTEGER;
    v_LFJuros INTEGER;


BEGIN

SELECT PARC.CDPROCESSOBEP,
       PARC.CDPROCESSOBEPPARCELAS,
       PD.CDPROCESSAMENTOBEP,
       PD.CDPROCESSAMENTOBEPDETALHE,
       HO.CDAGRUPAMENTO,
       /*(PKGPAG_BEP.FRetornarJurosAcumulados(TO_CHAR(P.DTINCLUSAO, 'YYYYMM'),
                                            TO_CHAR(ADD_MONTHS(SYSDATE, -1),
                                                    'YYYYMM'),
                                            P.CDVALORREFERENCIA) *
       PARC.VLPARCELA) AS VLJUROS, */
       (PKGPAG_BEP.FRetornarJuros(TO_CHAR(ADD_MONTHS(SYSDATE, -1), 'YYYYMM'),P.CDVALORREFERENCIA)* (PARC.VLPARCELA+PKGPAG_BEP.FValorJurosParcelaAnterior(PARC.CDPROCESSOBEP,MIN(PARC.NUPARCELA) OVER (PARTITION BY PARC.CDPROCESSOBEP))))+PKGPAG_BEP.FValorJurosParcelaAnterior(PARC.CDPROCESSOBEP,(MIN(PARC.NUPARCELA) OVER (PARTITION BY PARC.CDPROCESSOBEP))) AS VLJUROS,
       PARC.VLPARCELA,
       V.CDVINCULO,
       TFP.CDTIPOFOLHAPAGAMENTO
  INTO v_cdProcessobep,
       v_cdProcessoBepParcelas,
       v_cdProcessamento,
       v_cdProcessamentoDet,
       v_cdAgrupamento,
       v_valorJuros,
       v_vlrParcela,
       v_cdVinculo,
       v_cdTipoFolhaPagamento
  FROM EPAGPROCESSAMENTOBEPDETALHE PD
 INNER JOIN EPAGPROCESSAMENTOBEP PB     ON PB.CDPROCESSAMENTOBEP = PD.CDPROCESSAMENTOBEP AND PB.CDPROCESSAMENTOBEP = pCDPROCESSAMENTOBEP
 INNER JOIN EPAGPROCESSOBEPPARCELAS PARC     ON PARC.CDPROCESSOBEPPARCELAS = PD.CDPROCESSOBEPPARCELAS    AND PARC.CDPROCESSOBEPPARCELAS = pCDPROCESSOBEPPARCELAS  INNER JOIN EPAGPROCESSOBEP P
    ON P.CDPROCESSOBEP = PARC.CDPROCESSOBEP
 INNER JOIN ECADVINCULO V     ON V.CDVINCULO = P.CDVINCULO
 INNER JOIN ECADHISTORGAO HO     ON HO.CDORGAO = V.CDORGAO    AND HO.DTFIMVIGENCIA IS NULL
 INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP     ON TFP.CDAGRUPAMENTO = HO.CDAGRUPAMENTO
   AND TFP.CDTIPOFOLHA = 24;
 
 PKGPAG_BEP.obterDataFolha(v_cdAgrupamento,v_dtInicio,v_referencia);
 PKGPAG_BEP.recuperarRubricasBEP(v_cdAgrupamento,v_rubricaPgto,v_rubricaJuros);
 
    -- Verificação se tem folha bep aberta para o mes atual
    IF v_referencia IS NULL OR v_dtInicio IS NULL THEN  
       
                   UPDATE EPAGPROCESSAMENTOBEPDETALHE PD
                   SET PD.CDLANCAMENTOFINANCEIROJUROS = v_LFJuros,
                       PD.CDLANCAMENTOFINANCEIROPARCELA = v_LFParcela,
                       PD.DTULTALTERACAO =  CURRENT_TIMESTAMP,
                       PD.INSITUACAO = 3,
                       PD.FLCOMPLEMENTAR = 'S'
                   WHERE PD.CDPROCESSAMENTOBEP = v_cdProcessamento AND PD.CDPROCESSAMENTOBEPDETALHE = v_cdProcessamentoDet;
      
        RAISE_APPLICATION_ERROR(-20001, 'ATENÇÃO: Não existe folha BEP aberta');
      
    ELSE 
 
             vNuSufixo := 0;
            --recupera nusufixorubrica
            SELECT NVL(MAX(LP.NUSUFIXORUBRICA), 0)
            into vNuSufixo
            FROM EPAGLANCAMENTOFINANCEIRO LP WHERE LP.CDVINCULO = v_cdVinculo AND LP.CDRUBRICAAGRUPAMENTO = v_rubricaPgto AND LP.DTINICIODIREITO = v_dtInicio;
            -- Insert RUBRICA PAGAMENTO  EPAGLANCAMENTOFINANCEIRO
            
            v_LFParcela := SPAGLANCAMENTOFINANCEIRO.NEXTVAL;
             v_dtFim := LAST_DAY(v_dtInicio);
            INSERT INTO EPAGLANCAMENTOFINANCEIRO
                (CDLANCAMENTOFINANCEIRO, CDVINCULO, NUSUFIXORUBRICA, DTINICIODIREITO,DTFIMDIREITO,NUCPFCADASTRADOR, CDRUBRICAAGRUPAMENTO, VLLANCAMENTOFINANCEIRO, INPERIODICIDADE,CDTIPOCALCULO,NUSEQUENCIALFOLHA,CDTIPOFOLHAPAGAMENTO, CDPROCESSOBEPPARCELAS,FLAUTOMATICO,NUPARCELAS,FLPROPDEMITIDONOMES,FLVALORPROPORCIONAL,FLPAGAAFASTDEFINITIVO,FLPAGAAFASTTEMPSEMREMUN)
            VALUES
                (v_LFParcela, v_cdVinculo, vNuSufixo+1, v_dtInicio,v_dtFim, '22222222222', v_rubricaPgto, v_vlrParcela, 'P',1,1,v_cdTipoFolhaPagamento,v_cdProcessoBepParcelas,'S',1,'N','N','S','S');
                
                
            vNuSufixo := 0;
            --recupera nusufixorubrica
            SELECT NVL(MAX(LJ.NUSUFIXORUBRICA), 0)
             into vNuSufixo
             FROM EPAGLANCAMENTOFINANCEIRO LJ WHERE LJ.CDVINCULO = v_cdVinculo AND LJ.CDRUBRICAAGRUPAMENTO = v_rubricaJuros AND LJ.DTINICIODIREITO = v_dtInicio;
            -- Insert RUBRICA CORREÇÃO EPAGLANCAMENTOFINANCEIRO
            
            v_LFJuros := SPAGLANCAMENTOFINANCEIRO.NEXTVAL;
            
            INSERT INTO EPAGLANCAMENTOFINANCEIRO
                (CDLANCAMENTOFINANCEIRO, CDVINCULO, NUSUFIXORUBRICA, DTINICIODIREITO,DTFIMDIREITO, NUCPFCADASTRADOR, CDRUBRICAAGRUPAMENTO, VLLANCAMENTOFINANCEIRO, INPERIODICIDADE,CDTIPOCALCULO,NUSEQUENCIALFOLHA,CDTIPOFOLHAPAGAMENTO, CDPROCESSOBEPPARCELAS,FLAUTOMATICO,NUPARCELAS,FLPROPDEMITIDONOMES,FLVALORPROPORCIONAL,FLPAGAAFASTDEFINITIVO,FLPAGAAFASTTEMPSEMREMUN)
            VALUES
                (v_LFJuros, v_cdVinculo, vNuSufixo+1, v_dtInicio,v_dtFim, '22222222222', v_rubricaJuros, v_valorJuros, 'P',1,1,v_cdTipoFolhaPagamento, v_cdProcessoBepParcelas,'S',1,'N','N','S','S');

                
            UPDATE EPAGPROCESSAMENTOBEPDETALHE PD 
                   SET PD.CDLANCAMENTOFINANCEIROJUROS = v_LFJuros,
                       PD.CDLANCAMENTOFINANCEIROPARCELA = v_LFParcela,
                       PD.DTULTALTERACAO =  CURRENT_TIMESTAMP,
                       PD.INSITUACAO = 1,
                       PD.FLCOMPLEMENTAR = 'S'
                   WHERE PD.CDPROCESSAMENTOBEP = v_cdProcessamento AND PD.CDPROCESSAMENTOBEPDETALHE = v_cdProcessamentoDet;
              
            UPDATE EPAGPROCESSAMENTOBEP PP SET PP.DTFIMPROCESSAMENTO = SYSDATE, PP.DTPROCESSAMENTO = SYSDATE, PP.DTULTALTERACAO = CURRENT_TIMESTAMP WHERE PP.CDPROCESSAMENTOBEP = v_cdProcessamento;                       
                      
            UPDATE EPAGPROCESSOBEPPARCELAS
               SET VLJUROS = v_valorJuros, INSITUACAOPARCELA = 3 --PAGO
             WHERE CDPROCESSOBEP = v_cdProcessobep
               AND CDPROCESSOBEPPARCELAS = v_cdProcessoBepParcelas;


        UPDATE EPAGPROCESSOBEPPARCELAS
           SET INSITUACAOPARCELA = 2 -- PAGAR NA PROXIMA FOLHA
         WHERE CDPROCESSOBEP = v_cdProcessobep
           AND NUPARCELA = (SELECT MIN(PARCELA.NUPARCELA)  FROM EPAGPROCESSOBEPPARCELAS PARCELA WHERE PARCELA.CDPROCESSOBEP = v_cdProcessobep
                   AND PARCELA.INSITUACAOPARCELA = 1);

           
    END IF;
	



EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;  
 
  
END gerarLanctoParcela;

PROCEDURE excluirIndividual(pCDPROCESSAMENTOBEPDETALHE IN INTEGER)
  
  IS
 
  CURSOR c_detalheprocessobep IS
  
       SELECT PD.*, PARC.NUPARCELA, PARC.CDPROCESSOBEP 
        FROM  EPAGPROCESSAMENTOBEPDETALHE PD 
              INNER JOIN EPAGPROCESSOBEPPARCELAS PARC ON PARC.CDPROCESSOBEPPARCELAS = PD.CDPROCESSOBEPPARCELAS
        WHERE PD.CDPROCESSAMENTOBEPDETALHE = pCDPROCESSAMENTOBEPDETALHE;
        
   rec_detalheprocessobep c_detalheprocessobep%ROWTYPE;
  
  BEGIN
    
       OPEN c_detalheprocessobep;
  
       FETCH c_detalheprocessobep INTO rec_detalheprocessobep;
      
        IF c_detalheprocessobep%FOUND THEN
       
       
       --DELETA O DETALHE DO PROCESSAMENTO BEP
       DELETE FROM EPAGPROCESSAMENTOBEPDETALHE PD WHERE PD.CDPROCESSAMENTOBEPDETALHE = rec_detalheprocessobep.cdprocessamentobepdetalhe and PD.CDPROCESSAMENTOBEP = rec_detalheprocessobep.cdprocessamentobep;  
 
       --DELETA OS LANCAMENTOS FINANCEIROS PARCELA
       DELETE FROM EPAGLANCAMENTOFINANCEIRO LF 
              WHERE LF.CDLANCAMENTOFINANCEIRO = rec_detalheprocessobep.cdlancamentofinanceiroparcela
                    AND LF.CDPROCESSOBEPPARCELAS = rec_detalheprocessobep.cdprocessobepparcelas;  
                                      
       --DELETA OS LANCAMENTOS FINANCEIROS JUROS
       DELETE FROM EPAGLANCAMENTOFINANCEIRO LF 
              WHERE LF.CDLANCAMENTOFINANCEIRO = rec_detalheprocessobep.cdlancamentofinanceirojuros
                    AND LF.CDPROCESSOBEPPARCELAS = rec_detalheprocessobep.cdprocessobepparcelas;                        
  
      --ATUALIZA SITUACAO PARCELA DO BENEFICIO
      -- PKGPAG_BEP.recuperaParcelaProcessamento(pCDPROCESSAMENTOBEP,v_parcelaAtual,v_parcelaProxima);
        UPDATE EPAGPROCESSOBEPPARCELAS PBP SET PBP.INSITUACAOPARCELA = 2 
               WHERE PBP.CDPROCESSOBEPPARCELAS = rec_detalheprocessobep.cdprocessobepparcelas;
               
        IF rec_detalheprocessobep.Nuparcela < 60 THEN
         UPDATE EPAGPROCESSOBEPPARCELAS P SET P.INSITUACAOPARCELA = 1 WHERE  P.CDPROCESSOBEP = rec_detalheprocessobep.Cdprocessobep AND P.NUPARCELA = (rec_detalheprocessobep.Nuparcela + 1);
         END IF;
        IF rec_detalheprocessobep.Nuparcela = 60 THEN
         UPDATE EPAGPROCESSOBEPPARCELAS P SET P.INSITUACAOPARCELA = 1 WHERE  P.CDPROCESSOBEP = rec_detalheprocessobep.Cdprocessobep AND P.NUPARCELA = 60;
        END IF;

       /* -- SE NAO TIVER MAIS DETALHAMENTO DO PROCESSAMENTO EXCLUI O REGISTRO DO PROCESSAMENTO
        V_NRPROCESSAMENTO:=  PKGPAG_BEP.FContemDetalhamento(c_detalheprocessobep.cdprocessamentobep);
        IF V_NRPROCESSAMENTO <= 0 THEN
          DELETE FROM EPAGPROCESSAMENTOBEP P WHERE P.CDPROCESSAMENTOBEP = c_detalheprocessobep.cdprocessamentobep;
        END IF;*/
                     
       END IF;                    
       
       CLOSE c_detalheprocessobep; 
       
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Nenhum registro encontrado para o processamento informado.');

    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;  
    
  END excluirIndividual;


END PKGPAG_BEP;
/
