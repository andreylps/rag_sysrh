CREATE OR REPLACE PACKAGE PKGPAG_CNS IS

  TYPE rBaseCons IS RECORD(CdBaseConsignacao     INTEGER,
                           CdRubricaAgrupamento  INTEGER,
                           NuParcelas            INTEGER,
                           NuSufixo              INTEGER,
                           FlFormulaCalculo      CHAR(1),
                           FlDescontoParcial     CHAR(1),
                           FlEmprestimo          CHAR(1),
                           FlCartaoCredito       CHAR(1),
                           VlMensalContratado    NUMBER(13,2),
                           NuOrdem               INTEGER,
                           VlMinDescontoFolha    NUMBER(13,2),
                           VlTotal               NUMBER(13,2),
                           VlTAC                 NUMBER(13,2),
                           VlIOF                 NUMBER(13,2),
                           DtInclusao            DATE,
                           VlIndice              NUMBER(7,4),
                           vlPago                NUMBER(13,2),
                           vlResidual            NUMBER(13,2),
                           NuParcelasPagas       INTEGER,
                           FlVerificacaoPost     CHAR(1),
                           CdBaseConsignacaoAnterior INTEGER,
                           cdtiposervico          INTEGER);

PROCEDURE PProcessaBaseConsig(pFolha               IN PKGPAG_TIPO.rFolha,
                              pCdVinculo           IN INTEGER,
                              pFlCalculoDefinitivo IN CHAR,
                              pDtCalculo           IN DATE,
                              pFlCartaoCredito     IN CHAR);

FUNCTION FPercDecJudMargem (pCdVinculo           IN INTEGER,
                           pNuAnoReferencia     IN INTEGER,
                           pNuMesReferencia     IN INTEGER) RETURN NUMBER;

FUNCTION FRetornaMargemConsig(pFolha               IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo           IN INTEGER,
                              pCdRubricaBaseConsig IN INTEGER) RETURN NUMBER;

PROCEDURE PTratarFinalizacaoConsig(pFolha            IN PKGPAG_TIPO.rFolha,
                                   pVlAbatido        IN NUMBER,
                                   pVlSaldo          IN NUMBER,
                                   pVlResidual       IN NUMBER,
                                   pFlFormulaCalculo IN CHAR,
                                   pNuParcelas       IN INTEGER,
                                   pNuParcelasPagas  IN INTEGER,
                                   pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE);

PROCEDURE PFinalizarConsignacao(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                                pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                                pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE);

FUNCTION FConsigDeveSerFinalizada(pFolha            IN PKGPAG_TIPO.rFolha,
                                  pVlAbatido        IN NUMBER,
                                  pVlSaldo          IN NUMBER,
                                  pVlResidual       IN NUMBER,
                                  pFlFormulaCalculo IN CHAR,
                                  pNuParcelas       IN INTEGER,
                                  pNuParcelasPagas  IN INTEGER) RETURN BOOLEAN;

PROCEDURE PAbrirConsignacao(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                            pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                            pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE);

PROCEDURE PExcluirParcelasPagasConsig(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                                      pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                                      pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE);

FUNCTION FObterInfoPagamentoConsig(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                                   pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                                   pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE) RETURN rBaseCons;

FUNCTION FObterValorTotalLiquidacoes(pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE,
                                     pDataReferencia    IN EpagBaseHistoricoLiquidacao.Dtliquidacao%TYPE) RETURN EpagBaseHistoricoLiquidacao.Vlliquidado%TYPE;

PROCEDURE PRetonaArquivoAntecipSal (p_CDRETORNOANTECIPSAL IN NUMBER, p_resultado OUT types.ref_cursor);

PROCEDURE PGerarMargemAntecipSal (pCdarquivomargemantecipsal IN NUMBER,p_resultado OUT types.ref_cursor);

END PKGPAG_CNS;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_CNS IS

  CURSOR cBaseConsig(pCdAgrupamento   INTEGER,
                     pCdVinculo       INTEGER,
                     pNuAno           INTEGER,
                     pNuMes           INTEGER,
                     pCdOrdem         INTEGER,
                     pDtCalculo       DATE,
                     pFlCartaoCredito CHAR) IS
    SELECT BC.CdBaseConsignacao
          ,RA.CdRubricaAgrupamento
          ,BC.NuParcelas
          ,BC.NuSufixo
          ,HC.FlFormulaCalculo
          ,HC.FlDescontoParcial
          ,HTS.FlEmprestimo
          ,HTS.FlCartaoCredito
          ,BC.VlMensalContratado
          ,HTS.NuOrdem
          ,NVL(HC.VlMinDescontoFolha, 0) as VlMinDescontoFolha
          ,BC.NuParcelas * BC.VlMensalContratado + NVL(BC.VlTAC, 0) + NVL(BC.VlIOF, 0) as VlTotal
          ,NVL(BC.VlTAC, 0) as VlTAC
          ,NVL(BC.VlIOF, 0) as VlIOF
          ,BC.DtInclusao
          ,BC.VlIndice
          ,0 as vlPago
          ,0 as vlResidual
          ,0 as NuParcelasPagas
          ,'N' as FlVerificacaoPost
          ,BC.Cdbaseconsignacaoanterior
          ,TS.Cdtiposervico
      FROM EPagBaseConsignacao BC
     inner join EPagConsignacao C on BC.CdConsignacao = C.CdConsignacao
     inner join EPagHistConsignacao HC on C.CdConsignacao = HC.CdConsignacao
     inner join EPagRubricaAgrupamento RA on C.CdRubrica = RA.CdRubrica
                                         AND RA.CdAgrupamento = pCdAgrupamento
     inner join EPagTipoServico TS on TS.CdTipoServico = C.CdTipoServico
     inner join EPagHistTipoServico HTS on TS.CdTipoServico = HTS.CdTipoServico
     WHERE CdVinculo = pcdVinculo
       AND ((BC.NuAnoReferenciaInicial < pNuAno or (BC.NuAnoReferenciaInicial = pNuAno AND (BC.NuMesReferenciaInicial <= pNuMes))) and
           ((BC.NuAnoReferenciaFinal > pNuAno or (BC.NuAnoReferenciaFinal = pNuAno AND BC.NuMesReferenciaFinal >= pNuMes) or
           BC.NuMesReferenciaFinal is null)))
       AND BC.DtCancelamento is null
       AND (HTS.FlCartaoCredito = pFlCartaoCredito)
       AND (HC.DtInicioVigencia <= pDtCalculo AND (HC.DtFimVigencia >= pDtCalculo or HC.DtFimVigencia is null))
       AND (HTS.DtInicioVigencia <= pDtCalculo AND (HTS.DtFimVigencia >= pDtCalculo or HTS.Dtfimvigencia is null))
       AND BC.FlRegistroAtual = PKGPAG_TIPO.cnS
       AND not EXISTS ( SELECT 1
                          FROM epaghistrubricaagrupamento hra
                         WHERE hra.cdrubricaagrupamento = ra.cdrubricaagrupamento
                           AND hra.flsuspensa = 'S'
                           AND hra.nuanoiniciovigencia * 100 + hra.numesiniciovigencia <= pkgpag_var.vgFolha.NuAnoReferencia * 100 + pkgpag_var.vgFolha.NuMesReferencia
                           AND NVL(hra.nuanofimvigencia, 3000) * 100 + NVL(hra.numesfimvigencia, 12) >= pkgpag_var.vgFolha.NuAnoReferencia * 100 + pkgpag_var.vgFolha.NuMesReferencia)
       order by
       case when ra.cdrubricaagrupamento = 66816 THEN 0 ELSE HTS.NuOrdem end asc,
       --HTS.NuOrdem asc,
       DECODE(pCdOrdem, 1, C.DtInclusao, BC.DtInclusao) asc,
       BC.VlMensalContratado desc;

    --
    -- SIG-4657 ordem de calculo consignacoes facultativas (Na unha)
    -- rubrica 05-0101 ORG SOC ABEPOM e ela deve ter prioridade de desconto (66816)
    --
    TYPE tBaseCons IS TABLE OF cBaseConsig%ROWTYPE;

    PROCEDURE pInsereParcela( pCdBaseConsignacao IN INTEGER,
                              pNuAnoReferencia   IN INTEGER,
                              pNuMesReferencia   IN INTEGER,
                              pNuParcelaPaga     IN INTEGER,
                              pFlPagaResiduo     IN CHAR,
                              pVlPago            IN NUMBER,
                              pVlResidual        IN NUMBER)
      IS

   BEGIN


     INSERT
       INTO EPagBaseHistoricoPagamento(CdBaseHistoricoPagamento,
                                       CdBaseConsignacao,
                                       NuAnoReferencia,
                                       NuMesReferencia,
                                       NuParcelaPaga,
                                       FlPagamentoResiduo,
                                       VlPago,
                                       VlResidual)
    VALUES   (sPagBaseHistoricoPagamento.Nextval,
              pCdBaseConsignacao,
              pNuAnoReferencia,
              pNuMesReferencia,
              pNuParcelaPaga,
              pFlPagaResiduo,
              pVlPago,
              pVlResidual);

   EXCEPTION

     WHEN OTHERS THEN

       PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Erro ao inserir histórico de pagamento de consignação: '|| SQLERRM,
                               PKGPAG_VAR.vgCdVinculo);

   END;

    ------------------------------------------------------------
    -- Atualiza variavel global PKGPAG_VAR.vgPercDecJudMargem
    -- para alimentar FMnePercDecJud
    ------------------------------------------------------------
    FUNCTION  FPercDecJudMargem (pCdVinculo           IN INTEGER,
                                            pNuAnoReferencia     IN INTEGER,
                                            pNuMesReferencia     IN INTEGER)
    RETURN NUMBER IS

      vPercDecJudMargem NUMBER;

    BEGIN
      

      SELECT A.VLINDICE
        INTO vPercDecJudMargem
        FROM (SELECT e.vlindice
                FROM EPagEventoPagAgrupDecisao E
               WHERE E.CdVinculo = pCdVinculo
                 AND E.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseConsig
                 AND E.Flanulado = 'N'
                 AND ((pNuAnoReferencia * 100) + pNuMesReferencia)  BETWEEN ((E.NuAnoInicioDireito * 100) + E.NuMesInicioDireito) AND
                     (NVL(E.NuAnoFimDireito, 9999) * 100 + NVL(E.NuMesFimDireito, 99))
               ORDER BY E.DTINICIODIREITO DESC ) A
       WHERE ROWNUM < 2;

       RETURN vPercDecJudMargem;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

         RETURN 100;

       WHEN OTHERS THEN

         RETURN 100;

    END;

    FUNCTION  FValorDecJudMargem (pCdVinculo           IN INTEGER,
                                  pNuAnoReferencia     IN INTEGER,
                                  pNuMesReferencia     IN INTEGER)
    RETURN NUMBER IS

      vValorDecJudMargem NUMBER(13,2);

    BEGIN
      

      SELECT A.VlDeterminado
      INTO vValorDecJudMargem
      FROM (SELECT e.vldeterminado
              FROM EPagEventoPagAgrupDecisao E
             WHERE E.CdVinculo = pCdVinculo
               AND E.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubricaBaseConsig
               AND E.Flanulado = 'N'
               AND ((pNuAnoReferencia * 100) + pNuMesReferencia)  BETWEEN ((E.NuAnoInicioDireito * 100) + E.NuMesInicioDireito) AND
                   (NVL(E.NuAnoFimDireito, 9999) * 100 + NVL(E.NuMesFimDireito, 99))
              ORDER BY E.DTINICIODIREITO DESC ) A
      WHERE ROWNUM < 2;

      RETURN vValorDecJudMargem;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

       RETURN 0;

      WHEN OTHERS THEN

        RETURN 0;

    END;

    FUNCTION FRetornaMargemConsig(pFolha               IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo           IN INTEGER,
                                  pCdRubricaBaseConsig IN INTEGER)

      RETURN NUMBER IS

      vVlBaseConsignacao NUMBER(13,2);

      --vPercDecJudMargem NUMBER;

      vCont             INTEGER;

    BEGIN
        

      IF PKGPAG_GERAL.FGeraRubrica(pCdRubricaBaseConsig) THEN
        --
        -- Solicitacao de Sustentacao #74632
        -- 9893/2017 - FOLHA - MARGEM CONSIGNAVEL JUDICIAL
        -- Implementacao para verificar se tem valor de base de decisao judicial.
        --
        vVlBaseConsignacao := FValorDecJudMargem(pCdVinculo, pkgpag_var.vgfolha.NuAnoReferencia, pkgpag_var.vgfolha.NuMesReferencia);

        IF NVL(vVlBaseConsignacao,0) > 0 THEN

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => pCdRubricaBaseConsig,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => vVlBaseConsignacao,
                                                pVlIndice             => 100,
                                                pCdTipoOrigemRubrica  => 10);

        ELSE

          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => pCdRubricaBaseConsig,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 10);

          PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                           pCdVinculo       => pCdVinculo,
                                           pCdRubrica       => pCdRubricaBaseConsig,
                                           pTpProcessamento => 2,
                                           pTpLocal         => 2);

          ---------------------------------------------------
          -- Base consignavel liquida
          ---------------------------------------------------
         /* IF NVL(PKGPAG_VAR.vgCdRubricaBaseCsgLiq,0) > 0 THEN

            BEGIN

              vCont := 0;

              SELECT 1
                INTO vCont
                FROM EPAGHISTORICORUBRICAVINCULO HRV
               WHERE HRV.CDVINCULO = pCdVinculo
                 AND HRV.Cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseCsgLiq
                 AND HRV.CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento;

            EXCEPTION
                
              WHEN NO_DATA_FOUND THEN
                  
                vCont := 0;

              WHEN OTHERS THEN
                  
                vCont := 0;
                  
            END;

            IF vCont = 0 THEN

              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseCsgLiq,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 1);
            END IF;

            PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                             pCdVinculo       => pCdVinculo,
                                             pCdRubrica       => PKGPAG_VAR.vgCdRubricaBaseCsgLiq,
                                             pTpProcessamento => 2,
                                             pTpLocal         => 2);

           END IF;*/

          BEGIN

            SELECT HRV.vlPagamento
              INTO vVlBaseConsignacao
              FROM EPagHistoricoRubricaVinculo HRV
              WHERE HRV.CdVinculo = pCdVinculo AND
                    HRV.CdRubricaAgrupamento = pCdRubricaBaseConsig AND
                    HRV.Cdfolhapagamento = pFolha.CdFolhaPagamento;

          EXCEPTION

            WHEN NO_DATA_FOUND THEN

              vVlBaseConsignacao := 0;

            WHEN TOO_MANY_ROWS THEN

               PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                   PKGPAG_VAR.vCdHistParamCalc,
                                   PKGPAG_VAR.vCdPessoa,
                                   'Consignação :  Base da margem consignável duplicada.',
                                    PKGPAG_VAR.vgCdVinculo);

            WHEN OTHERS THEN

               vVlBaseConsignacao := 0;

            END;

         END IF;

       END IF;

      RETURN vVlBaseConsignacao;

   END;

   FUNCTION fPossuiSuspensaoConsig(pCdBaseConsignacao IN INTEGER,
                                   pNuMesReferencia   IN INTEGER,
                                   pNuAnoReferencia   IN INTEGER)
     RETURN BOOLEAN IS

     vPossuiSuspensaoConsig INTEGER;

   BEGIN

       SELECT 1
         INTO vPossuiSuspensaoConsig
         FROM epagbasesuspensao bs
        WHERE bs.cdbaseconsignacao = pCdBaseConsignacao
          AND ((bs.nuanoiniciosuspensao*100)+bs.numesiniciosuspensao <= (pNuAnoReferencia*100)+pNuMesReferencia)
          AND ((bs.nuanofimsuspensao IS NULL AND bs.numesfimsuspensao IS NULL) OR ((bs.nuanofimsuspensao*100)+bs.numesfimsuspensao >= (pNuAnoReferencia*100)+pNuMesReferencia));

       RETURN TRUE;
       
     EXCEPTION
       
       WHEN NO_DATA_FOUND THEN
         
         RETURN FALSE;

       WHEN OTHERS THEN

         RETURN FALSE;


   END;

   PROCEDURE pinsereconsignacao(pfolha               IN pkgpag_tipo.rfolha,
                                pcdvinculo           IN INTEGER,
                                pvlabatido           IN NUMBER,
                                pvlresiduo           IN NUMBER,
                                pbasecons            IN rbasecons,
                                ptabcons             IN tbasecons,
                                pflcalculodefinitivo IN CHAR,
                                pflverificalista     IN CHAR) IS

     vvlpagamento NUMBER(13, 2) := 0;
     vnuparcela   INTEGER := 0;

   BEGIN

     SELECT NVL(SUM(rv.vlpagamento), 0)
       INTO vvlpagamento
       FROM epaghistoricorubricavinculo rv
      WHERE rv.cdfolhapagamento = pfolha.cdfolhapagamento
        AND rv.cdvinculo = pcdvinculo
        AND rv.cdbaseconsignacao = pbasecons.cdbaseconsignacao
        AND rv.cdrubricaagrupamento = pbasecons.cdrubricaagrupamento;

     IF pvlabatido > 0 THEN

       vnuparcela := CASE
                       WHEN (pbasecons.nuparcelas > pbasecons.nuparcelaspagas OR
                            pbasecons.nuparcelas IS NULL) THEN
                        pbasecons.nuparcelaspagas + 1
                       ELSE
                        NULL
                     END;

       --algumas consignações são calculadas no pacote de tributação, por isso, quando encontrado valor, não são inseridas novamente
       IF NVL(vvlpagamento, 0) > 0 THEN

         UPDATE epaghistoricorubricavinculo hrv
            SET hrv.cdrubricaagrupamento = pbasecons.cdrubricaagrupamento,
                hrv.vlpagamento          = pvlabatido,
                hrv.vlindicerubrica      = pbasecons.vlmensalcontratado,
                hrv.qtparcelas           = vnuparcela,
                hrv.cdtiporubricaorigem  = 14,
                hrv.nusufixorubrica      = pbasecons.nusufixo
          WHERE hrv.cdfolhapagamento = pfolha.cdfolhapagamento
            AND hrv.cdvinculo = pcdvinculo
            AND hrv.cdbaseconsignacao = pbasecons.cdbaseconsignacao;

       ELSE
         
         PKGPAG_GERAL.pinserelancamentovinculo(pcdfolhapagamento     => pfolha.cdfolhapagamento,
                                               pcdvinculo            => pcdvinculo,
                                               pcdexpressaoformcalc  => NULL,
                                               pcdrubricaagrupamento => pbasecons.cdrubricaagrupamento,
                                               pnusufixorubrica      => pbasecons.nusufixo,
                                               pvlpagamento          => pvlabatido,
                                               pvlindice             => pbasecons.vlmensalcontratado,
                                               pnuparcelas           => vnuparcela,
                                               pcdbaseconsignacao    => pbasecons.cdbaseconsignacao,
                                               pcdtipoorigemrubrica  => 14);

       END IF;

       /*Caso seja calculo definitivo e nao esteja na lista para verificacao posterior */
       IF pflcalculodefinitivo = 'S' AND NVL(pvlabatido,0) > 0 AND
          /*(pfolha.cdtipofolha = pkgpag_tipo.cntpfolhanormal OR
          pfolha.cdtipofolha = pkgpag_tipo.cntpfolharesidente OR
          pfolha.cdtipofolha = pkgpag_tipo.cntpfolhafunebre) AND
          pfolha.cdtipocalculo = pkgpag_tipo.cntpcalculonormal AND*/
          (NOT ptabcons.EXISTS(pbasecons.cdbaseconsignacao) OR pflverificalista = 'N') THEN

         pinsereparcela(pcdbaseconsignacao => pbasecons.cdbaseconsignacao,
                        pnuanoreferencia   => pfolha.nuanoreferencia,
                        pnumesreferencia   => pfolha.numesreferencia,
                        pnuparcelapaga     => vnuparcela,
                        pflpagaresiduo     => CASE
                                                WHEN (pbasecons.nuparcelas > pbasecons.nuparcelaspagas OR pbasecons.nuparcelas IS NULL) THEN
                                                 'N'
                                                ELSE
                                                 'S'
                                              END,
                        pvlpago            => pvlabatido,
                        pvlresidual        => CASE
                                                WHEN (pbasecons.nuparcelas > pbasecons.nuparcelaspagas OR pbasecons.nuparcelas IS NULL) THEN
                                                 pvlresiduo
                                                ELSE
                                                 0
                                              END);

       END IF;

     END IF;

  EXCEPTION
    
    WHEN OTHERS THEN
      
      vVlPagamento := 0;

   END;

    PROCEDURE PProcessaBaseConsig(pFolha               IN PKGPAG_TIPO.rFolha,
                                  pCdVinculo           IN INTEGER,
                                  pFlCalculoDefinitivo IN CHAR,
                                  pDtCalculo           IN DATE,
                                  pFlCartaoCredito     IN CHAR) IS

      vvlAbatido                  NUMBER(13,2);
      vvlResiduo                  NUMBER(13,2);
      vvlLiquidado                NUMBER(13,2);
      vVlMargemConsignavel        NUMBER(13,2);
      vvlSaldo                    NUMBER(13,2);
      vvlProcessado               NUMBER(13,2);
      vvlNaoProcessado            NUMBER(13,2);
      vCdExpressaoFormCalc        INTEGER;
      vtBaseConsig                tBaseCons;
      vtBaseConsigAtual           rBaseCons;
      vtBaseConsigAnterior        rBaseCons;
      bConsigPosterior            BOOLEAN DEFAULT FALSE;
      vCdHistoricoRubricaVinculo  INTEGER;
      vCdEstruturaCarreira        INTEGER;
      vCdRubBaseConsigUtilizada   INTEGER;
      vVlDescontoContraCheque     NUMBER(13,2);
      vInserirConsignacao         BOOLEAN;
      vVlpgtoRubBaseCsgLiq        NUMBER(13,2);
      vExisteRubContraCheque      INTEGER;
      vVlConsigsFuturas           NUMBER(13,2);
      vPossuiRubCsgReservaFut     INTEGER;
      vExisteLancFinanCsgLiq      INTEGER;
      vVLmargem011007             INTEGER;
      VCdrubricaBase              INTEGER;
      vVlMinConsig                number(13,2);
      vNuParcelasOrigem           integer;

    FUNCTION Fretornavalor011007 (pCdAgrupamento INTEGER,
                                  pCdBaseconsignacao INTEGER )
      RETURN NUMBER IS

      vVLmargem011007 INTEGER;
      vlmansalcon     number(17,2);

    BEGIN
      

      VCdrubricaBase  := 22917;

      SELECT VlMensalContratado
        INTO vlmansalcon
        FROM EPagBaseConsignacao ec
       WHERE CdBaseConsignacao =PCdBaseconsignacao
         AND PKGPAG_VAR.vgCdRubricaBaseCsgLiq = VCdrubricaBase
         AND EXISTS ( SELECT 1
                    FROM epagbasesuspensao bs
                    WHERE bs.cdbaseconsignacao = ec.cdbaseconsignacao);

       IF pCdAgrupamento = 1 THEN
         
         vVlMargemConsignavel := vVlMargemConsignavel - vlmansalcon;
         RETURN (vVLmargem011007);
         
       END IF;

     EXCEPTION 
       
       WHEN OTHERS THEN
         
         RETURN NULL;
         
     END;
     
 Procedure pEmiteAvisoValorMinimo (pRubrica in pkgpag_tipo.rRubrica,
                                   pValorConsig in number) is
      
   BEGIN
   
      IF pValorConsig > 0 THEN

      PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                              pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                              pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                              pDeLog                   => 'Consignação com valor menor que o minimo e não descontada!' || 
                                                          ' Rubrica: ' || 
                                                          lpad(prubrica.cdtiporubrica,2,0) || '-' ||
                                                          lpad(prubrica.nurubrica,4,0) ||
                                                          ' R$ ' || pValorConsig,
                              pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                              pCdTipoOcorrencia        => 2, -- Ocorrencia
                              pCdMotivoOcorrencia      => 2);

 
     END IF;
     
     EXCEPTION WHEN OTHERS THEN
 
         NULL;
         
    END;     
     
  
    BEGIN

      IF pFlCartaoCredito = 'S' THEN
        vCdRubBaseConsigUtilizada := PKGPAG_VAR.vgCdRubricaBaseCSG_CC;
      ELSE
        vCdRubBaseConsigUtilizada := PKGPAG_VAR.vgCdRubricaBaseConsig;
      END IF;

      vVlMargemConsignavel := FRetornaMargemConsig(pFolha => pFolha,
                                                   pCdVinculo => pCdVinculo,
                                                   pCdRubricaBaseConsig => vCdRubBaseConsigUtilizada);

      vVlMinConsig := NVL(PKGPAG_PARAM.FValorReferencia('CONSIG MIN'),0);
      
      IF pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal OR
         pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaResidente OR
         pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFunebre OR
         pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaRescisao THEN

        OPEN cBaseConsig(pFolha.CdAgrupamento,
                         pCdVinculo,
                         pFolha.NuAnoReferencia,
                         pFolha.NuMesReferencia,
                         PKGPAG_VAR.vgOrdemDescConsig,
                         pDtCalculo,
                         pFlCartaoCredito);

        FETCH cBaseConsig BULK COLLECT INTO vtBaseConsig;

        CLOSE cBaseConsig;

        IF vtBaseConsig.COUNT > 0 THEN

          vvlNaoProcessado := 0;

          vvlProcessado := 0;

          IF vVlMargemConsignavel > 0 THEN

            FOR i IN vtBaseConsig.FIRST .. vtBaseConsig.LAST

            LOOP

              IF PKGPAG_GERAL.FGeraRubrica(vtBaseConsig(i).CdRubricaAgrupamento) AND
                NOT (fPossuiSuspensaoConsig(vtBaseConsig(i).CdBaseConsignacao, pFolha.NuMesReferencia, pFolha.NuAnoReferencia)) THEN -- se consig está suspensa, não gera o desconto

                IF pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                   pFolha.CdTipoFolha <> PKGPAG_TIPO.cnTpFolhaFunebre THEN
                  PAbrirConsignacao(pNuAnoReferencia => pFolha.NuAnoReferencia,
                                    pNuMesReferencia => pFolha.NuMesReferencia,
                                    pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacao);

                  PExcluirParcelasPagasConsig(pNuAnoReferencia => pFolha.NuAnoReferencia,
                                              pNuMesReferencia => pFolha.NuMesReferencia,
                                              pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacao);
                END IF;

                vvlAbatido       := 0;

                vvlResiduo       := 0;

                vtBaseConsigAnterior.vlPago := 0;
                vtBaseConsigAnterior.vlResidual := 0;
                vtBaseConsigAnterior.NuParcelasPagas := 0;


                IF vtBaseConsig(i).NuParcelas IS NOT NULL AND  vtBaseConsig(i).VlMensalContratado > 0 THEN

                  vNuParcelasOrigem :=  vtBaseConsig(i).NuParcelas;
                  -- SIG-149
                  -- GEREF - 12720/2018 - Consignatarias nao descontadas
                  -- Saldo baseado em novo valor apos decisao judcicial.
                  -- Implementado para considerar o saldo e numero de parcelas na nova vigencia
                  IF vtBaseConsig(i).CdBaseConsignacaoAnterior is not null THEN

                    vtBaseConsigAnterior := FObterInfoPagamentoConsig(pNuAnoReferencia => PFolha.NuAnoreferencia,
                                                                      pNuMesReferencia => PFolha.NuMesReferencia,
                                                                      pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacaoAnterior);

                    vtBaseConsig(i).NuParcelas := vtBaseConsig(i).NuParcelas - vtBaseConsigAnterior.NuParcelasPagas;
                    vtBaseConsig(i).VlTotal := vtBaseConsig(i).VlMensalContratado * vtBaseConsig(i).NuParcelas;

                  END IF;

                  vtBaseConsigAtual := FObterInfoPagamentoConsig(pNuAnoReferencia => PFolha.NuAnoreferencia,
                                                                 pNuMesReferencia => PFolha.NuMesReferencia,
                                                                 pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacao);

                  vtBaseConsig(i).vlPago :=  vtBaseConsigAtual.vlPago - NVL(vtBaseConsigAnterior.vlPago,0);
                  vtBaseConsig(i).vlResidual := vtBaseConsigAtual.vlResidual - NVL(vtBaseConsigAnterior.vlResidual,0);
                  vtBaseConsig(i).NuParcelasPagas := vtBaseConsigAtual.NuParcelasPagas - NVL(vtBaseConsigAnterior.NuParcelasPagas,0);

                 
                  
                  -- Descobre o montante de liquidacoes efetuadas caso seja emprestimo

                  vVlLiquidado := 0;
                  IF vtBaseConsig(i).FlEmprestimo = 'S' THEN
                    vVlLiquidado:= FObterValorTotalLiquidacoes(pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacao,
                                                               pDataReferencia => pFolha.dtInicioMes);

                    -- Se for a primeira parcela adiciona os valores de TAC e IOF
                    -- Caso a TAC e/ou IOF o nao forem financiados o valor e 0

                    IF vtBaseConsig(i).NuParcelasPagas = 0 THEN
                      vtBaseConsig(i).VlMensalContratado := vtBaseConsig(i).VlMensalContratado +
                                                             vtBaseConsig(i).VlTAC +
                                                             vtBaseConsig(i).VlIOF;
                    END IF;
                  END IF;

                  IF vvlLiquidado > 0 THEN

                     vvlSaldo := vtBaseConsig(i).VlTotal + vvlResiduo - (vtBaseConsig(i).vlPago + vvlLiquidado);

                  ELSE
                       
                    IF vtBaseConsigAtual.NuParcelasPagas = vNuParcelasOrigem THEN

                      -- vvlSaldo := (vtBaseConsig(i).vlMensalContratado * vtBaseConsigAtual.NuParcelasPagas) - vtBaseConsigAtual.vlPago;
                      vvlSaldo := vtBaseConsig(i).vlResidual;
                      
                    ELSE
                      
                      vvlSaldo := vtBaseConsig(i).vlMensalContratado;

                    END IF;
                      
                  END IF;
                  
                  -- SC PARCERIAS - Se e diretor nao tem limitacao pela margem consignavel
                  IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 13 AND PKGPAG_VAR.vgFolha.CdAgrupamento in (136) THEN
                  
                    vVlMargemConsignavel := vtBaseConsig(i).VlMensalContratado;
                     
                  END IF;

                  IF vvlSaldo > 0 THEN

                    CASE
                      -- Se o valor da margem for maior que o valor mensal
                      WHEN vtBaseConsig(i).VlMensalContratado <= vVlMargemConsignavel THEN

                        -- Gera historico de pagamento com nova parcela com:
                        --  o menor valor entre mensal contratado e o saldo

                        vvlAbatido := LEAST(vtBaseConsig(i).VlMensalContratado, vvlSaldo);

                        vvlResiduo := 0;
                        
                        IF vvlminconsig > 0 AND vvlabatido < vvlminconsig THEN
                          
                           pEmiteAvisoValorMinimo(pkgpag_var.vgrubrica(vtBaseConsig(i).CdRubricaAgrupamento),
                                                  vvlAbatido);
                           
                           vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado;                         
                                                  
                           vvlabatido := 0;                       
                           
                        END IF; 

                        vvlProcessado := vvlProcessado + vvlAbatido;

                       --  SIG-481 12796/2018 - ORDEM DE PRIORIZACAO DE DESCONTO DE EMPRESTIMO
                       when vtBaseConsig(i).VlMensalContratado > vVlMargemConsignavel and
                            vtBaseConsig(i).FlDescontoParcial = 'S' AND vtBaseConsig(i).FlEmprestimo = 'S' THEN

                         IF pkgpag_var.vgTblRubCNSAlim.EXISTS(vtBaseConsig(i).CdBaseConsignacao)
                           AND pkgpag_var.vgTblRubCNSAlim(vtBaseConsig(i).CdBaseConsignacao).vlBase is not null
                           AND pkgpag_var.vgTblRubCNSAlim(vtBaseConsig(i).CdBaseConsignacao).vlBase <= vVlAbatido THEN
                            vvlAbatido := pkgpag_var.vgTblRubCNSAlim(vtBaseConsig(i).CdBaseConsignacao).vlBase;
                         ELSE
                           IF vvlSaldo > 0 THEN
                             vvlAbatido := least(vVlMargemConsignavel, vvlSaldo);
                           ELSE
                             vvlAbatido := vVlMargemConsignavel;
                           END IF;
                         END IF;

                         vvlResiduo := 0;
                         
                        IF vvlminconsig > 0 AND vvlabatido < vvlminconsig THEN
                          
                          pEmiteAvisoValorMinimo(pkgpag_var.vgrubrica(vtBaseConsig(i).CdRubricaAgrupamento),
                                                 vvlAbatido);
                                                                            
                          vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado;

                          vvlabatido := 0; 

                        ELSE
                          
                          vvlProcessado := vvlProcessado + vvlAbatido;

                          vvlResiduo := vtBaseConsig(i).VlMensalContratado - vvlAbatido;

                          PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                                  pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                                  pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                                  pDeLog                   => 'Resíduo de consignação gerado. Rubrica: '||
                                                                              LPAD(PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).CdTipoRubrica,2,'0') ||
                                                                              LPAD(PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).NuRubrica,4,'0') || '.' ||
                                                                              ' Valor: R$ ' || vtBaseConsig(i).VlMensalContratado,
                                                  pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                  pCdTipoOcorrencia        => 2, -- Ocorrencia
                                                  pCdMotivoOcorrencia      => 2);-- Residuo de consignacao

                         vvlNaoProcessado := vvlNaoProcessado + vvlResiduo;
                         
                        END IF;

                        -- Se o valor da margem for menor que o valor mensal
                       WHEN vtBaseConsig(i).VlMensalContratado > vVlMargemConsignavel AND vtBaseConsig(i).FlEmprestimo = 'S' THEN

                         -- Se permite desconto parcial ou se o valor do saldo for menor que o valor
                         -- da margem consignavel

                         IF (vvlSaldo <= vVlMargemConsignavel) THEN

                           vvlAbatido := vvlSaldo;

                           vvlResiduo := 0;

                         ELSIF vtBaseConsig(i).FlDescontoParcial = 'S' THEN

                           vvlAbatido := 0;

                           vvlResiduo := 0;

                           bConsigPosterior := TRUE;

                           vtBaseConsig(i).FlVerificacaoPost := 'S';

                         ELSIF vvlSaldo =  vtBaseConsig(i).vlResidual THEN -- Pagamento de residuo pois nao tem mais parcelas a pagar

                           IF vvlSaldo > vtBaseConsig(i).VlMensalContratado THEN

                             vvlAbatido  := vtBaseConsig(i).VlMensalContratado;

                             vvlResiduo := 0;

                           ELSE

                             vvlAbatido := vvlSaldo;

                             vvlResiduo := 0;

                           END IF;

                         ELSE

                           vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado;

                           PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                                   pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                                   pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                                   pDeLog                   => 'Sem margem consignável. Rubrica: '||
                                                                                LPAD(PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).CdTipoRubrica,2,'0') ||
                                                                                LPAD(PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).NuRubrica,4,'0') || '.' ||
                                                                                ' Valor: R$ ' || vtBaseConsig(i).VlMensalContratado,
                                                   pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                                   pCdTipoOcorrencia        => 2, -- Ocorrencia
                                                   pCdMotivoOcorrencia      => 2);-- Residuo de consignacao

                         END IF;

                          IF vvlminconsig > 0 AND vvlabatido < vvlminconsig THEN
                            
                             pEmiteAvisoValorMinimo(pkgpag_var.vgrubrica(vtBaseConsig(i).CdRubricaAgrupamento),
                                                    vvlAbatido);
                                                    
                             vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado;                        
                                                  
                             vvlabatido := 0; 
                             
                          ELSE            
                                        
                             vvlProcessado := vvlProcessado + vvlAbatido;
                             
                          END IF;

                       WHEN vtBaseConsig(i).VlMensalContratado > vVlMargemConsignavel AND
                            vtBaseConsig(i).FlEmprestimo = 'N' AND
                            vtBaseConsig(i).FlDescontoParcial = 'S' AND
                            vtBaseConsig(i).cdtiposervico = 183 THEN --SAQUE CARTAO BENEFICIO

                         vvlAbatido       := LEAST(vVlMargemConsignavel, vvlSaldo);
                         
                         IF vvlminconsig > 0 AND vvlabatido < vvlminconsig THEN
                           
                            pEmiteAvisoValorMinimo(pkgpag_var.vgrubrica(vtBaseConsig(i).CdRubricaAgrupamento),
                                                   vvlAbatido);
                             
                            vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado; 
                                                 
                            vvlabatido := 0; 
                            
                         ELSE  
                            vvlResiduo       := vtBaseConsig(i).VlMensalContratado - vvlAbatido;
                            vvlProcessado    := vvlProcessado + vvlAbatido;
                            vvlNaoProcessado := vvlNaoProcessado + vvlResiduo;
                         END IF;

                       WHEN vtBaseConsig(i).VlMensalContratado > vVlMargemConsignavel THEN

                         vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado;

                       END CASE;
                       
                       vVlMargemConsignavel := vVlMargemConsignavel - vvlAbatido;

                       IF vvlAbatido > 0 THEN
                         
                         vtBaseConsig(i).NuParcelasPagas := vtBaseConsig(i).NuParcelasPagas + NVL(vtBaseConsigAnterior.NuParcelasPagas,0);
                         vtBaseConsig(i).NuParcelas := vtBaseConsig(i).NuParcelas + NVL(vtBaseConsigAnterior.NuParcelasPagas,0);

                         PInsereConsignacao( pFolha               => pFolha,
                                             pCdVinculo           => pCdVinculo,
                                             pVlAbatido           => vvlAbatido,
                                             pVlResiduo           => vvlResiduo,
                                             pBaseCons            => vtBaseConsig(i),
                                             pTabCons             => vtBaseConsig,
                                             pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                             pFlVerificaLista     => 'S');

                         PTratarFinalizacaoConsig(pFolha => pFolha,
                                                  pVlAbatido         => vvlAbatido,
                                                  pVlSaldo           => vvlSaldo,
                                                  pVlResidual        => vtBaseConsig(i).VlResidual,
                                                  pFlFormulaCalculo  => vtBaseConsig(i).FlFormulaCalculo,
                                                  pNuParcelas        => vtBaseConsig(i).NuParcelas,
                                                  pNuParcelasPagas   => vtBaseConsig(i).NuParcelasPagas,
                                                  pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacao);
                       END IF;

                  END IF;

                ELSIF vtBaseConsig(i).NuParcelas IS NULL AND vtBaseConsig(i).VlMensalContratado > 0 THEN

                   IF vvlminconsig > 0 AND vtBaseConsig(i).VlMensalContratado < vvlminconsig THEN
                       
                      pEmiteAvisoValorMinimo(pkgpag_var.vgrubrica(vtBaseConsig(i).CdRubricaAgrupamento),
                                             vtBaseConsig(i).VlMensalContratado);
                     
                   ELSE
                     
                     vInserirConsignacao := TRUE;
                     IF vVlMargemConsignavel >= vtBaseConsig(i).VlMensalContratado THEN
                        vVlDescontoContraCheque:= vtBaseConsig(i).VlMensalContratado;
                        vVlMargemConsignavel := vVlMargemConsignavel - vVlDescontoContraCheque;
                        vvlProcessado := vvlProcessado + vVlDescontoContraCheque;
                     ELSE
                      IF vtBaseConsig(i).FlDescontoParcial = 'S' THEN
                        IF vVlMargemConsignavel >= vtBaseConsig(i).VlMinDescontoFolha THEN
                           vVlDescontoContraCheque := vVlMargemConsignavel;
                           vVlMargemConsignavel := 0;
                           vvlProcessado := vvlProcessado + vVlDescontoContraCheque;
                           vvlNaoProcessado := vvlNaoProcessado + (vtBaseConsig(i).VlMensalContratado - vVlDescontoContraCheque);
                        ELSE
                          vInserirConsignacao := FALSE;
                          vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado;
                        END IF;
                      ELSE
                        vInserirConsignacao := FALSE;
                        vvlNaoProcessado := vvlNaoProcessado + vtBaseConsig(i).VlMensalContratado;
                      END IF;
                     END IF;

                     IF vInserirConsignacao THEN
                       
                        PInsereConsignacao(pFolha               => pFolha,
                                           pCdVinculo           => pCdVinculo,
                                           pVlAbatido           => vVlDescontoContraCheque,
                                           pVlResiduo           => vvlResiduo,
                                           pBaseCons            => vtBaseConsig(i),
                                           pTabCons             => vtBaseConsig,
                                           pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                           pFlVerificaLista     => 'N');
                      END IF;
                   
                 END IF;
                 
                ELSIF vtBaseConsig(i).FlFormulaCalculo = 'S' THEN
                  --
                  -- Chamado 7220/2015
                  -- Consignacoes por formula e com parcelas nao estavam sendo finalizadas
                  --
                  IF vtBaseConsig(i).NuParcelas IS NOT NULL THEN
                     vtBaseConsigAtual := FObterInfoPagamentoConsig(pNuAnoReferencia => PFolha.NuAnoreferencia,
                                                                    pNuMesReferencia => PFolha.NuMesReferencia,
                                                                    pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacao);

                     vtBaseConsig(i).vlPago := vtBaseConsigAtual.vlPago;
                     vtBaseConsig(i).vlResidual := vtBaseConsigAtual.vlResidual;
                     vtBaseConsig(i).NuParcelasPagas := vtBaseConsigAtual.NuParcelasPagas;

                    IF vtBaseConsig(i).NuParcelasPagas >=  vtBaseConsig(i).NuParcelas
                      AND vtBaseConsig(i).NuParcelas IS NOT NULL THEN
                      CONTINUE;
                    END IF;

                  END IF;

                  -- Se o vinculo possuir cargo efetivo, busca formula por Carreira

                  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN
                    vCdEstruturaCarreira := PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira;
                  END IF;

                  IF PKGPAG_VAR.vgAPO.COUNT > 0 THEN
                    vCdEstruturaCarreira := PKGPAG_VAR.vgAPO(1).CdEstruturaCarreira;
                  END IF;

                   vCdExpressaoFormCalc :=

                    PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                 pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                 pCdRubricaAgrupamento     => vtBaseConsig(i).CdRubricaAgrupamento,
                                 pCdRelacaoVinculo         => 0,
                                 pCdEstruturaCarreira      => vCdEstruturaCarreira);

                  IF PKGPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                       pCdVinculo,
                                                       vtBaseConsig(i).CdRubricaAgrupamento,
                                                       vtBaseConsig(i).NuSufixo,
                                                       14) > 0 THEN
                      --caso a rub tenha sido calculada em outro pacote
                      UPDATE epagHistoricoRubricaVinculo HRV
                         SET HRV.VLPAGAMENTO = 0,
                             HRV.Vlindicerubrica = NVL(vtBaseConsig(i).VlIndice,0),
                             HRV.CDEXPRESSAOFORMCALC = vCdExpressaoFormCalc
                       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                             HRV.CdVinculo = pCdVinculo AND
                             HRV.CdRubricaAgrupamento = vtBaseConsig(i).CdRubricaAgrupamento AND
                             HRV.CDBASECONSIGNACAO = vtBaseConsig(i).CdBaseConsignacao AND
                             HRV.Nusufixorubrica = vtBaseConsig(i).NuSufixo;
                  ELSE

                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pCdVinculo,
                                                        pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento => vtBaseConsig(i).CdRubricaAgrupamento,
                                                        pNuSufixoRubrica      => vtBaseConsig(i).NuSufixo,
                                                        pVlPagamento          => 0,
                                                        pVlIndice             => NVL(vtBaseConsig(i).VlIndice,0),
                                                        pCdBaseConsignacao    => vtBaseConsig(i).CdBaseConsignacao,
                                                        pCdTipoOrigemRubrica  => 14);

                  END IF;

                  PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                   pCdVinculo       => pCdVinculo,
                                                   pCdRubrica       => vtBaseConsig(i).CdRubricaAgrupamento,
                                                   pTpProcessamento => 1,
                                                   pTpLocal         => 2); /*Vinculo*/

                  BEGIN

                    BEGIN

                    SELECT HRV.CdHistoricoRubricaVinculo,
                           HRV.vlPagamento
                      INTO vCdHistoricoRubricaVinculo,
                           vvlAbatido
                      FROM EPagHistoricoRubricaVinculo HRV
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                           HRV.CdVinculo = pCdVinculo AND
                           HRV.CdRubricaAgrupamento =  vtBaseConsig(i).CdRubricaAgrupamento AND
                           HRV.NuSufixoRubrica = vtBaseConsig(i).NuSufixo;

                    EXCEPTION
                      
                      WHEN OTHERS THEN

                        vCdHistoricoRubricaVinculo := null;
                        vvlAbatido := 0;

                    END;

                    IF (vVlMargemConsignavel < vvlAbatido) OR (vvlminconsig > 0 AND vvlabatido < vvlminconsig)  THEN

                      vvlNaoProcessado := vvlNaoProcessado + vvlAbatido;

                      DELETE
                        FROM EPagHistoricoRubricaVinculo HRV
                       WHERE HRV.CdHistoricoRubricaVinculo = vCdHistoricoRubricaVinculo;

                      IF (vvlminconsig > 0 AND vvlabatido < vvlminconsig) THEN
                           
                         pEmiteAvisoValorMinimo(pkgpag_var.vgrubrica(vtBaseConsig(i).CdRubricaAgrupamento),
                                                 vvlAbatido);
                         vvlAbatido := 0;                      
                           
                      END IF;  
                      
                    ELSE

                      vVlMargemConsignavel := vVlMargemConsignavel - vvlAbatido;

                      vvlProcessado := vvlProcessado + vvlAbatido;

                      --
                      -- Chamado 7220/2015
                      -- Consignacoes por formula e com parcelas nao estavam sendo finalizadas
                      --
                      IF vtBaseConsig(i).NuParcelas IS NOT NULL THEN
                        pInsereParcela(vtBaseConsig(i).CdBaseConsignacao,
                                       pFolha.NuAnoReferencia,
                                       pFolha.NuMesReferencia,
                                       vtBaseConsig(i).NuParcelasPagas + 1,
                                       'N',
                                       vvlAbatido,
                                       0);

                        PTratarFinalizacaoConsig (pFolha             => pFolha,
                                                  pVlAbatido         => vvlAbatido,
                                                  pVlSaldo           => vvlSaldo,
                                                  pVlResidual        => 0,
                                                  pFlFormulaCalculo  => vtBaseConsig(i).FlFormulaCalculo,
                                                  pNuParcelas        => vtBaseConsig(i).NuParcelas,
                                                  pNuParcelasPagas   => vtBaseConsig(i).NuParcelasPagas,
                                                  pCdBaseConsignacao => vtBaseConsig(i).CdBaseConsignacao);
                      END IF;

                    END IF;

                    EXCEPTION

                      WHEN NO_DATA_FOUND THEN

                        vvlAbatido := 0;

                      WHEN TOO_MANY_ROWS THEN

                         vvlAbatido := 0;

                         PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                             PKGPAG_VAR.vCdHistParamCalc,
                                             PKGPAG_VAR.vCdPessoa,
                                             'Consignação - Rubrica com o mesmo sufixo encontrada: '
                                             || PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).CdTipoRubrica
                                             || '-' || PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).NuRubrica,
                                             PKGPAG_VAR.vgCdVinculo);

                    END;

                ELSE
                  null;
                END IF;

              END IF;

            END LOOP;

            IF bConsigPosterior THEN

              FOR i IN vtBaseConsig.FIRST.. vtBaseConsig.LAST
              LOOP

                IF vtBaseConsig(i).FlVerificacaoPost = 'S' AND
                   PKGPAG_GERAL.FGeraRubrica(vtBaseConsig(i).CdRubricaAgrupamento) THEN

                  IF NVL(vtBaseConsig(i).VlMinDescontoFolha,0) <= vVlMargemConsignavel THEN

                    vvlAbatido := vVlMargemConsignavel;

                    vVlMargemConsignavel := vVlMargemConsignavel - vvlAbatido;

                    vvlResiduo := vtBaseConsig(i).VlMensalContratado - vvlAbatido;

                    PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                            pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                            pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                            pDeLog                   => 'Resíduo de consignação gerado. Rubrica: '||
                                                                         LPAD(PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).CdTipoRubrica,2,'0') ||
                                                                         LPAD(PKGPAG_VAR.vgRubrica(vtBaseConsig(i).CdRubricaAgrupamento).NuRubrica,4,'0') || '.' ||
                                                                         ' Valor: R$ ' || vtBaseConsig(i).VlMensalContratado,
                                             pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                             pCdTipoOcorrencia        => 2, -- Ocorrencia
                                             pCdMotivoOcorrencia      => 2);-- Residuo de consignacao

                    vvlNaoProcessado := vvlNaoProcessado + vvlResiduo;

                    vvlProcessado := vvlProcessado + vvlAbatido;

                    PInsereConsignacao( pFolha               => pFolha,
                                        pCdVinculo           => pCdVinculo,
                                        pVlAbatido           => vvlAbatido,
                                        pVlResiduo           => vvlResiduo,
                                        pBaseCons            => vtBaseConsig(i),
                                        pTabCons             => vtBaseConsig,
                                        pFlCalculoDefinitivo => pFlCalculoDefinitivo,
                                        pFlVerificaLista     => 'N');

                  END IF;

                END IF;

              END LOOP;

           END IF;

           IF pFlCartaoCredito = 'N' THEN

             IF NVL(PKGPAG_VAR.vgCdRubricaBaseCsgLiq,0) <> 0 THEN
               
              /* BEGIN
                 
                  SELECT 1
                    INTO vExisteRubContraCheque
                    FROM epaghistoricorubricavinculo hrv
                   WHERE hrv.cdfolhapagamento = pFolha.CdFolhaPagamento
                     AND hrv.cdvinculo = pCdVinculo
                     AND hrv.cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseCsgLiq
                     AND hrv.nusufixorubrica = 1
                     AND hrv.cdtipoorigemrubrica = 1;
                     
                EXCEPTION

                  WHEN NO_DATA_FOUND THEN*/

                    BEGIN
                      -- Verifica se existe LF para a rubrica, caso exista, não insere
                      SELECT 1
                        INTO vExisteLancFinanCsgLiq
                        FROM epaglancamentofinanceiro lf
                       WHERE lf.cdvinculo = pCdVinculo
                         AND lf.cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseCsgLiq
                         AND lf.dtiniciodireito <= pFolha.DtFimMes
                         AND (lf.dtfimdireito IS NULL OR lf.dtfimdireito >= pFolha.DtInicioMes);

                    EXCEPTION

                       WHEN NO_DATA_FOUND THEN

                         vExisteLancFinanCsgLiq := 0;

                         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                               pCdVinculo            => pCdVinculo,
                                                               pCdExpressaoFormCalc  => NULL,
                                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseCsgLiq,
                                                               pNuSufixoRubrica      => 1,
                                                               pVlPagamento          => NVL(vVlMargemConsignavel,0),
                                                               pVlIndice             => NULL,
                                                               pCdTipoOrigemRubrica  => 1);
                                                               
                     WHEN OTHERS THEN
                   
                        NULL;     
                                                             
                   END;

                /* WHEN OTHERS THEN
                   
                   NULL;

                END;*/
                
                --Se existe LF, não faz update
                IF NVL(vExisteLancFinanCsgLiq,0) = 0 THEN
                  
                  FOR i IN vtBaseConsig.FIRST.. vtBaseConsig.LAST

                  LOOP

                    vVLmargem011007:= Fretornavalor011007(PKGPAG_VAR.vgFolha.CdAgrupamento,vtBaseConsig(i).CdBaseConsignacao);
                    
                    IF NVL(vVLmargem011007,0) > 0 THEN

                      UPDATE epaghistoricorubricavinculo hrv
                             SET hrv.vlpagamento = vVlMargemConsignavel - NVL(vVLmargem011007,0) 
                       WHERE hrv.cdfolhapagamento = pFolha.CdFolhaPagamento
                         AND hrv.cdvinculo = pCdVinculo
                         AND hrv.cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseCsgLiq
                         AND hrv.cdtipoorigemrubrica = 1
                         AND hrv.nusufixorubrica = 1;
                       
                    END IF;   

                   END LOOP;
                   

               END IF;
               
             END IF;

             IF NVL(PKGPAG_VAR.vgCdRubricaCSGProc,0) <> 0  THEN

              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaCSGProc,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => NVL(vvlProcessado,0), -- + NVL(pkgpag_var.vgValorAcumulado_CC,0),
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 1);

             END IF;

             IF NVL(PKGPAG_VAR.vgCdRubricaCSGNaoProc,0) <> 0  THEN

               PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                     pCdVinculo            => pCdVinculo,
                                                     pCdExpressaoFormCalc  => NULL,
                                                     pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaCSGNaoProc,
                                                     pNuSufixoRubrica      => 1,
                                                     pVlPagamento          => NVL(vvlNaoProcessado,0),
                                                     pVlIndice             => NULL,
                                                     pCdTipoOrigemRubrica  => 1);

             END IF;

           ELSE
             --
             -- 10107/2017 - FOLHA - EN: FWD: EN: INADIMPLENCIA CARTAO DE CREDITO - LIMITE EMPREST.
             --
             IF NVL(PKGPAG_VAR.vgCdRubricaCSGProcCC,0) <> 0  THEN

               PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pCdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaCSGProcCC,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => NVL(vvlProcessado,0),
                                                      pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 1);

                pkgpag_var.vgValorAcumulado_CC := NVL(vvlProcessado,0);

              END IF;

              --
              -- Base consignavel liquida Cartao de credito
              --

              IF NVL(PKGPAG_VAR.vgCdRubricaBaseCsgLiq_CC,0) > 0 THEN

                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pCdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseCsgLiq_CC,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => 0,
                                                      pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 10);

                 PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                                  pCdVinculo       => pCdVinculo,
                                                  pCdRubrica       => PKGPAG_VAR.vgCdRubricaBaseCsgLiq_CC,
                                                  pTpProcessamento => 2,
                                                  pTpLocal         => 2);

              END IF;

           END IF;

            IF PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                        pcdvinculo => pCdVinculo,
                                                        pcdrubrica => PKGPAG_VAR.vgCdRubricaBaseCSG_CC) = 0 and
               PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                        pcdvinculo => pCdVinculo,
                                                        pcdrubrica => PKGPAG_VAR.vgCdRubricaBaseConsig) > 0 THEN

                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pCdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseCSG_CC,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => PKGPAG_GERAL.fretornavalorrubrica
                                                                                 (pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                                  pcdvinculo => pCdVinculo,
                                                                                  pcdrubrica => PKGPAG_VAR.vgCdRubricaBaseConsig) / 4,
                                                       pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 12);


            END IF;

          END IF;

        ELSE
          
            IF NVL(PKGPAG_VAR.vgCdRubricaBaseCsgLiq,0) <> 0 
               AND pFlCartaoCredito = 'N' THEN
              
              PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseCsgLiq,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => NVL(vVlMargemConsignavel,0),
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 1);
            END IF;
            
        END IF;

       IF NVL(PKGPAG_VAR.vgCdRubricaBaseCsgLiq,0) <> 0  
          AND pFlCartaoCredito <> 'S' 
          AND pFolha.CdAgrupamento in (1, 132, 134, 176)  THEN

         -- Calcula a 09-1002 (reserva consig futura), para depois subtrair o valor dela no valor da margem consig.líquida
         BEGIN
           
           SELECT  SUM(bc.vlmensalcontratado)
             INTO vVlConsigsFuturas
             FROM epagbaseconsignacao bc
            WHERE bc.cdvinculo = pCdVinculo
              AND (bc.nuanoreferenciainicial*100)+bc.numesreferenciainicial > (pFolha.NuAnoReferencia || lpad(pFolha.NuMesReferencia,2,0))
              AND (bc.numesreferenciafinal is null or (bc.nuanoreferenciafinal*100)+bc.numesreferenciafinal > pFolha.NuAnoReferencia || lpad(pFolha.NuMesReferencia,2,0))
              AND bc.dtinclusao <= pFolha.DtCalculo;

          /* WHERE bc.cdvinculo = pcdvinculo
             AND (bc.nuanoreferenciainicial = pFolha.NuAnoReferencia and
                  bc.numesreferenciainicial > pFolha.NuMesReferencia and
                  bc.nuanoreferenciainicial >= NVL(bc.nuanoreferenciafinal,pFolha.NuAnoReferencia) and
                  (NVL(bc.numesreferenciafinal,bc.numesreferenciainicial) >= NVL(bc.numesreferenciainicial,bc.numesreferenciainicial) or
                  (bc.nuanoreferenciainicial > pFolha.NuAnoReferencia
                   AND (bc.nuanoreferenciafinal > pFolha.NuAnoReferencia or bc.nuanoreferenciafinal is null)))
                  AND (bc.nuanoreferenciafinal is null or ((bc.nuanoreferenciafinal*100)+bc.numesreferenciafinal >= (bc.nuanoreferenciainicial*100)+bc.numesreferenciainicial))
                 );*/

         EXCEPTION
           
           WHEN NO_DATA_FOUND THEN
             
             vVlConsigsFuturas := 0;

          WHEN OTHERS THEN
            
            vVlConsigsFuturas := 0;

         END;

         IF NVL(vVlConsigsFuturas,0) <> 0 THEN
           
           BEGIN
             
             SELECT 1
               INTO vPossuiRubCsgReservaFut
               FROM epaghistoricorubricavinculo hrv
              WHERE hrv.cdfolhapagamento = pFolha.CdFolhaPagamento
                AND hrv.cdvinculo = pCdVinculo
                AND hrv.cdrubricaagrupamento = pkgpag_var.vgCdRubBaseCsgMargFut
                AND hrv.nusufixorubrica = 1
                AND hrv.cdtipoorigemrubrica = 1;
                
           EXCEPTION
             
             WHEN NO_DATA_FOUND THEN
               
               PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                     pCdVinculo            => pCdVinculo,
                                                     pCdExpressaoFormCalc  => NULL,
                                                     pCdRubricaAgrupamento => pkgpag_var.vgCdRubBaseCsgMargFut,
                                                     pNuSufixoRubrica      => 1,
                                                     pVlPagamento          => vVlConsigsFuturas,
                                                     pVlIndice             => NULL,
                                                     pCdTipoOrigemRubrica  => 1);

            WHEN OTHERS THEN

              vPossuiRubCsgReservaFut := null;

          END;

         END IF;


         BEGIN
           
           SELECT SUM(hrv.vlpagamento)
             INTO vVlpgtoRubBaseCsgLiq
             FROM epaghistoricorubricavinculo hrv
            WHERE hrv.cdfolhapagamento = pFolha.CdFolhaPagamento
              AND hrv.cdvinculo = pCdVinculo
              AND hrv.cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseCsgLiq
              AND hrv.nusufixorubrica = 1
              AND hrv.cdtipoorigemrubrica = 1;
              
         EXCEPTION
           
           WHEN NO_DATA_FOUND THEN
             
             -- Caso o servidor não possua consignação, deve setar o valor da margem consignável na 09-1007
             -- a rub 09-1007 não deve ser gerada para contracheques anteriores a competência junho/2020
             PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                   pCdVinculo            => pCdVinculo,
                                                   pCdExpressaoFormCalc  => NULL,
                                                   pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaBaseCsgLiq,
                                                   pNuSufixoRubrica      => 1,
                                                   pVlPagamento          => NVL(vVlMargemConsignavel,0),
                                                   pVlIndice             => NULL,
                                                   pCdTipoOrigemRubrica  => 1);

           WHEN OTHERS THEN

             vVlpgtoRubBaseCsgLiq := null;

         END;

         IF vVlpgtoRubBaseCsgLiq IS NOT NULL  THEN
           --
           -- SIG-4625
           -- 15035/2020 - problemas na margem consignavel liquida - 09-1007
           -- Incluido desconto do valor nao processado
           --
           UPDATE epaghistoricorubricavinculo hrv
              SET hrv.vlpagamento = vVlMargemConsignavel - NVL(vVlConsigsFuturas,0) - NVL(vvlNaoProcessado,0)
            WHERE hrv.cdfolhapagamento = pFolha.CdFolhaPagamento
              AND hrv.cdvinculo = pCdVinculo
              AND hrv.cdrubricaagrupamento = PKGPAG_VAR.vgCdRubricaBaseCsgLiq
              AND hrv.cdtipoorigemrubrica = 1
              AND hrv.nusufixorubrica = 1;

         END IF;

        END IF;
        
      END IF;
      
      /*09-1951*/
      IF NVL(PKGPAG_VAR.vgCdRubBaseCsgBrutaOutros,0) > 0 THEN
        
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseCsgBrutaOutros,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
                                                   
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseCsgBrutaOutros,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2);                                                   
        
      END IF;
      
      /*09-1952*/
      IF NVL(PKGPAG_VAR.vgCdRubBaseCsgLiqOutros,0) > 0 THEN
        
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseCsgLiqOutros,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);
                                                   
         PKGPAG_FB.PProcessaFormulasBases(pFolha           => PKGPAG_VAR.vgFolha,
                                          pCdVinculo       => pCdVinculo,
                                          pCdRubrica       => PKGPAG_VAR.vgCdRubBaseCsgLiqOutros,
                                          pTpProcessamento => 2,
                                          pTpLocal         => 2);                                                   
                
      END IF;

    EXCEPTION

    WHEN OTHERS THEN

       PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Erro ao processar Consignações:' || SQLERRM,
                                PKGPAG_VAR.vgCdVinculo);

    END;

PROCEDURE PFinalizarConsignacao(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                                pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                                pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE) IS
BEGIN

  UPDATE EpagBaseConsignacao BC
     SET BC.NuAnoReferenciaFinal = pNuAnoReferencia,
         BC.NuMesReferenciaFinal = pNuMesReferencia,
         BC.DtUltAlteracao       = SYSTIMESTAMP,
         BC.flfechadaprocfolha   = 'S'
   WHERE BC.CdBaseConsignacao = pCdBaseConsignacao;
END;

FUNCTION FConsigDeveSerFinalizada(pFolha            IN PKGPAG_TIPO.rFolha,
                                  pVlAbatido        IN NUMBER,
                                  pVlSaldo          IN NUMBER,
                                  pVlResidual       IN NUMBER,
                                  pFlFormulaCalculo IN CHAR,
                                  pNuParcelas       IN INTEGER,
                                  pNuParcelasPagas  IN INTEGER) RETURN BOOLEAN IS
  vDeveSerFinalizada BOOLEAN := FALSE;
BEGIN

   IF (pNuParcelasPagas + 1) >= pNuParcelas AND pVlResidual = 0 AND
       pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaNormal,PKGPAG_TIPO.cnTpFolhaRescisao) AND
       pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
       pFolha.FlCalculoDefinitivo = 'S' THEN
       vDeveSerFinalizada := TRUE;
   END IF;

   RETURN vDeveSerFinalizada;
END;

PROCEDURE PAbrirConsignacao(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                            pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                            pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE) IS
BEGIN

  UPDATE EPagBaseConsignacao BC
     SET BC.NuAnoreferenciaFinal = NULL,
         BC.NuMesReferenciaFinal = NULL
   WHERE BC.CdBaseConsignacao = pCdBaseConsignacao AND
         BC.NuAnoReferenciaFinal = pNuAnoReferencia AND
         BC.NuMesReferenciaFinal = pNuMesReferencia AND
         BC.NuParcelas IS NOT NULL AND
         BC.flfechadaprocfolha = 'S';
END;

PROCEDURE PExcluirParcelasPagasConsig(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                                      pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                                      pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE) IS
BEGIN

  DELETE
    FROM EPagBaseHistoricoPagamento BHP
   WHERE BHP.CdBaseConsignacao = pCdBaseConsignacao AND
         BHP.NuAnoReferencia = pNuAnoReferencia AND
         BHP.NuMesReferencia = pNuMesReferencia;
END;

FUNCTION FObterInfoPagamentoConsig(pNuAnoReferencia   IN Epagbaseconsignacao.Nuanoreferenciafinal%TYPE,
                                   pNuMesReferencia   IN Epagbaseconsignacao.Numesreferenciafinal%TYPE,
                                   pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE) RETURN rBaseCons IS
   vtBaseConsig     rBaseCons;
   vVlResidualPago  NUMBER(13,2);

BEGIN

  BEGIN
    SELECT NVL(SUM(vlPago), 0),
           NVL(SUM(vlResidual), 0),
           NVL(SUM(CASE
                     WHEN BHP.FlPagamentoResiduo = 'N' THEN
                      1
                     ELSE
                      0
                   END),
               0),
           NVL(SUM(CASE
                     WHEN BHP.FlPagamentoResiduo = 'S' THEN
                       VlPago
                   ELSE
                     0
                   END),                                      
               0)
      INTO vtBaseConsig.vlPago,
           vtBaseConsig.vlResidual,
           vtBaseConsig.NuParcelasPagas,
           vVlResidualPago
      FROM EpagBaseHistoricoPagamento BHP
     WHERE BHP.CdBaseConsignacao = pCdBaseConsignacao
       AND ((BHP.NuAnoReferencia = pNuAnoReferencia AND
           BHP.NuMesReferencia < pNuMesReferencia) OR
           BHP.NuAnoReferencia < pNuAnoReferencia);

      vtBaseConsig.vlResidual := vtBaseConsig.vlResidual - NVL(vVlResidualPago,0);      

  EXCEPTION
    WHEN OTHERS THEN
      vtBaseConsig.vlPago := 0;
      vtBaseConsig.vlResidual := 0;
      vtBaseConsig.NuParcelasPagas := 0;
  END;

  RETURN vtBaseConsig;
END;

FUNCTION FObterValorTotalLiquidacoes(pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE,
                                     pDataReferencia    IN EpagBaseHistoricoLiquidacao.Dtliquidacao%TYPE) RETURN EpagBaseHistoricoLiquidacao.Vlliquidado%TYPE IS
  vVlTotalLiquidado EpagBaseHistoricoLiquidacao.Vlliquidado%TYPE := 0;
BEGIN

  BEGIN
    SELECT NVL(SUM(BHL.vlLiquidado), 0)
      INTO vVlTotalLiquidado
      FROM EpagBaseHistoricoLiquidacao BHL
     WHERE BHL.CdBaseConsignacao = pCdBaseConsignacao
       AND BHL.CdTipoLiquidacao = 5
       AND
          /*BHL.FlPagamentoViaBoleto = 'S' AND*/
           BHL.DtLiquidacao <= pDataReferencia;

    EXCEPTION
      WHEN OTHERS THEN
        vVlTotalLiquidado := 0;
  END;

  RETURN vVlTotalLiquidado;
END;

PROCEDURE PTratarFinalizacaoConsig(pFolha             IN PKGPAG_TIPO.rFolha,
                                   pVlAbatido         IN NUMBER,
                                   pVlSaldo           IN NUMBER,
                                   pVlResidual        IN NUMBER,
                                   pFlFormulaCalculo  IN CHAR,
                                   pNuParcelas        IN INTEGER,
                                   pNuParcelasPagas   IN INTEGER,
                                   pCdBaseConsignacao IN Epagbaseconsignacao.Cdbaseconsignacao%TYPE) IS
BEGIN

  IF FConsigDeveSerFinalizada(pFolha             => pFolha,
                              pVlAbatido         => pVlAbatido,
                              pVlSaldo           => pVlSaldo,
                              pVlResidual        => pVlResidual,
                              pFlFormulaCalculo  => pFlFormulaCalculo,
                              pNuParcelas        => pNuParcelas,
                              pNuParcelasPagas   => pNuParcelasPagas) THEN

    PFinalizarConsignacao(pNuAnoReferencia => pFolha.NuAnoReferencia,
                          pNuMesReferencia => pFolha.NuMesReferencia,
                          pCdBaseConsignacao => pCdBaseConsignacao);
  END IF;
END;


/*inicio PRetonaArquivoAntecipSal*/
PROCEDURE PRetonaArquivoAntecipSal (
    p_CDRETORNOANTECIPSAL IN NUMBER,
    p_resultado OUT types.ref_cursor
)
IS
BEGIN
    OPEN p_resultado FOR
   SELECT 
        LPAD(P.NUCPF,11,'0') ||
        LPAD(V.NUMATRICULA,7,'0') || V.NUDVMATRICULA || LPAD(V.NUSEQMATRICULA,2,'0') ||
        RET.NUANOCOMPETENCIA || LPAD(RET.NUMESCOMPETENCIA,2,'0') ||
        LPAD(TO_CHAR(ROUND(NVL(LF.VLLANCAMENTOFINANCEIRO, 0) * 100), 'FM0000000000000'), 13, '0') ||
        LPAD(TO_CHAR(ROUND(NVL(PAG.VLPARCELA, 0) * 100), 'FM0000000000000'), 13, '0') ||
        CASE 
            WHEN NVL(PAG.VLPARCELA,0) = 0 THEN 'N' 
            WHEN LF.VLLANCAMENTOFINANCEIRO = PAG.VLPARCELA THEN 'T'
            WHEN LF.VLLANCAMENTOFINANCEIRO > PAG.VLPARCELA THEN 'P' 
        END

    FROM EPAGRETORNOANTECIPSAL RET
        INNER JOIN EPAGCONSIGNATARIA C ON C.CDCONSIGNATARIA = RET.CDCONSIGNATARIA AND C.FLANTECIPASAL = 'S'
        INNER JOIN VPAGRUBRICAAGRUPAMENTO RA ON RA.CDCONSIGNATARIA = C.CDCONSIGNATARIA AND RA.FLRUBANTECIPSAL = 'S' AND RA.CDTIPORUBRICA = 5
        INNER JOIN EPAGLANCAMENTOFINANCEIRO LF ON LF.CDRUBRICAAGRUPAMENTO = RA.CDRUBRICAAGRUPAMENTO
              AND LF.DTINICIODIREITO = '01/' || LPAD(RET.NUMESCOMPETENCIA,2) ||'/'||RET.NUANOCOMPETENCIA
        LEFT JOIN EPAGPAGAMENTOLANCAMENTO PAG ON PAG.CDLANCAMENTOFINANCEIRO = LF.CDLANCAMENTOFINANCEIRO 
            AND PAG.NUANOREFERENCIA = RET.NUANOCOMPETENCIA 
            AND PAG.NUMESREFERENCIA = RET.NUMESCOMPETENCIA
        INNER JOIN ECADVINCULO V ON V.CDVINCULO = LF.CDVINCULO 
        INNER JOIN ECADPESSOA P ON P.CDPESSOA = V.CDPESSOA    
    WHERE RET.CDRETORNOANTECIPSAL = p_CDRETORNOANTECIPSAL;
END;

/*fim PRetonaArquivoAntecipSal*/

/*inicio PGerarMargemAntecipSal*/
PROCEDURE PGerarMargemAntecipSal (pCdarquivomargemantecipsal IN NUMBER, p_resultado OUT types.ref_cursor)
IS
  vNUANOREFERENCIA     NUMBER(4);
  vNUMESREFERENCIA     NUMBER(2);
  vNuCPFCadastrador    EPAGARQUIVOMARGEMANTECIPSAL.NUCPFCADASTRADOR%TYPE;
  vQtde                EPAGARQUIVOMARGEMANTECIPSAL.NUQTDE%TYPE := 0;
  v_count              NUMBER := 0;
  v_start_time         TIMESTAMP := SYSTIMESTAMP;
  v_resultado          VARCHAR2(4000):= '';

  CURSOR c_dados IS
    SELECT 
      CDVINCULO, CNPJ, CPF, NUMATRICULA, NUDVMATRICULA, NUSEQMATRICULA,
      RMBANCO, MARGEMBANCO, REGISTRO, TELEFONE
    FROM (

      WITH CONTRATOS AS (
        SELECT BC.CDVINCULO, SUM(BC.VLMENSALCONTRATADO) AS SOMA
        FROM EPAGBASECONSIGNACAO BC
        INNER JOIN EPAGCONSIGNACAO C ON BC.CDCONSIGNACAO = C.CDCONSIGNACAO
        WHERE BC.FLREGISTROATUAL = 'S'
          AND BC.VLMENSALCONTRATADO IS NOT NULL
          AND BC.NUANOREFERENCIAFINAL IS NULL
          AND C.CDTIPOSERVICO NOT IN (4,11,183)
        GROUP BY BC.CDVINCULO
      )
      SELECT 
        REFFOLHA, CNPJ, CPF, CDVINCULO, NUMATRICULA, NUDVMATRICULA, NUSEQMATRICULA,
        RMBANCO, MARGEMBANCO, TELEFONE,
        REFFOLHA || LPAD(CNPJ,14,0) || LPAD(CPF,11,0) || MATRICULA ||
        LPAD(TELEFONE,14,0) ||
        LPAD(REPLACE(REPLACE(TO_CHAR(REMUNERACAO_BRUTA),'.',''),',',''),13,0) ||
        LPAD(REPLACE(REPLACE(TO_CHAR(MARGEM_ANTECIPACAO),'.',''),',',''),13,0) AS REGISTRO
      FROM (
        SELECT 
          O.NUCNPJ AS CNPJ, D.CDORGAO, CPF, CDVINCULO, NUMATRICULA, NUDVMATRICULA, NUSEQMATRICULA,
          MATRICULA, TELEFONE, REFFOLHA,
          FFORMATANUMERO(REMUNERACAO_BRUTA,2,0) AS REMUNERACAO_BRUTA,
          REMUNERACAO_BRUTA AS RMBANCO,
          FFORMATANUMERO(
            ((MARGEM_BRUTA * 100 / 40) - NVL((SELECT SOMA FROM CONTRATOS CTR WHERE CTR.CDVINCULO = D.CDVINCULO),0)) / 3,
            2, 0
          ) AS MARGEM_ANTECIPACAO,
          (((MARGEM_BRUTA * 100 / 40) - NVL((SELECT SOMA FROM CONTRATOS CTR WHERE CTR.CDVINCULO = D.CDVINCULO),0)) / 3) AS MARGEMBANCO
        FROM (
          SELECT 
            HRV.CDVINCULO, V.NUMATRICULA, V.NUDVMATRICULA, V.NUSEQMATRICULA,
            PAGA16.CDORGAO,
            LPAD(V.NUMATRICULA,7,0) || V.NUDVMATRICULA || LPAD(V.NUSEQMATRICULA,2,0) AS MATRICULA,
            CASE 
              WHEN P.NUTELEFONERES IS NOT NULL THEN P.NUDDDRES || P.NUTELEFONERES
              WHEN P.NUDDDCEL IS NOT NULL THEN P.NUDDDCEL || P.NUCELULAR
              WHEN P.NUTELEFONECONT IS NOT NULL THEN P.NUDDDCONT || P.NUTELEFONECONT
              ELSE NULL
            END AS TELEFONE,
            PAGA16.NUANOMESREFERENCIA AS REFFOLHA,
            P.NUCPF AS CPF,
            SUM(CASE WHEN RA.CDMODALIDADERUBRICA = 10 THEN HRV.VLPAGAMENTO ELSE 0 END) AS MARGEM_BRUTA,
            SUM(CASE WHEN RA.CDMODALIDADERUBRICA = 17 THEN HRV.VLPAGAMENTO ELSE 0 END) AS REMUNERACAO_BRUTA
          FROM EPAGHISTORICORUBRICAVINCULO HRV
          INNER JOIN EPAGCAPAHISTRUBRICAVINCULO CAPA ON HRV.CDFOLHAPAGAMENTO = CAPA.CDFOLHAPAGAMENTO AND HRV.CDVINCULO = CAPA.CDVINCULO
          INNER JOIN VPAGRUBRICAAGRUPAMENTO RA ON HRV.CDRUBRICAAGRUPAMENTO = RA.CDRUBRICAAGRUPAMENTO AND RA.CDMODALIDADERUBRICA IN (10,17)
          INNER JOIN EPAGFOLHAPAGAMENTO PAGA16 ON PAGA16.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO AND PAGA16.CDTIPOCALCULO = 1
          INNER JOIN EPAGTIPOFOLHAPAGAMENTO PAGA18 ON PAGA18.CDTIPOFOLHAPAGAMENTO = PAGA16.CDTIPOFOLHAPAGAMENTO AND PAGA18.CDTIPOFOLHA = 1
          INNER JOIN ECADVINCULO V ON HRV.CDVINCULO = V.CDVINCULO
          INNER JOIN ECADPESSOA P ON V.CDPESSOA = P.CDPESSOA
          WHERE PAGA16.NUANOMESREFERENCIA = vNUANOREFERENCIA * 100 + vNUMESREFERENCIA
            AND PAGA16.CDAGRUPAMENTO IN (1, 132, 134 , 176)
            AND PAGA16.CDORGAO <> 34
            AND NOT EXISTS (
              SELECT 1 FROM ECADHISTCARGOEFETIVO
              WHERE CDVINCULO = HRV.CDVINCULO AND CDRELACAOTRABALHO = 3
            )
          GROUP BY HRV.CDVINCULO, V.NUMATRICULA, V.NUDVMATRICULA, V.NUSEQMATRICULA,
                   PAGA16.CDAGRUPAMENTO, PAGA16.CDORGAO,
                   LPAD(V.NUMATRICULA,7,0) || V.NUDVMATRICULA || LPAD(V.NUSEQMATRICULA,2,0),
                   P.NMPESSOA, P.NUCPF, V.CDREGIMETRABALHO, CAPA.FLATIVO, PAGA16.NUANOMESREFERENCIA,
                   P.NUTELEFONERES, P.NUDDDRES, P.NUDDDCEL, P.NUCELULAR, P.NUTELEFONECONT, P.NUDDDCONT
        ) D
        INNER JOIN VCADORGAO O ON D.CDORGAO = O.CDORGAO
        WHERE MARGEM_BRUTA > 0
      )
    );

BEGIN
  -- Buscar dados de referência e cadastrador
  SELECT NUANOREFERENCIA, NUMESREFERENCIA, NUCPFCADASTRADOR
  INTO vNUANOREFERENCIA, vNUMESREFERENCIA, vNuCPFCadastrador
  FROM EPAGARQUIVOMARGEMANTECIPSAL
  WHERE CDARQUIVOMARGEMANTECIPSAL = pCdarquivomargemantecipsal;

  -- Loop de inserção com commit a cada 500 registros
  FOR rec IN c_dados LOOP
      
  IF v_count = 0 THEN
    UPDATE EPAGARQUIVOMARGEMANTECIPSAL AM SET AM.NUQTDE = vQtde, AM.INSITUACAO = '2', AM.DESITUACAO = to_char(sysdate,'DD/MM/YYYY - hh24:mi:ss') || ' - Execução iniciada!', AM.DTULTALTERACAO = SYSDATE WHERE AM.CDARQUIVOMARGEMANTECIPSAL = pCdarquivomargemantecipsal; 
    commit;
    END IF;
  
    INSERT INTO EPAGARQUIVOMARGEMANTECIPSALDET (
      CDARQUIVOMARGEMANTECIPSALDET,
      CDARQUIVOMARGEMANTECIPSAL,
      CDVINCULO,
      NUCNPJ,
      NUCPF,
      NUMATRICULA,
      NUDVMATRICULA,
      NUSEQMATRICULA,
      VLBRUTO,
      VLMARGEM,
      DEREGISTRO,
      NUTELEFONE,
      NUCPFCADASTRADOR,
      DTULTALTERACAO
    )
    VALUES (
      SPAGARQUIVODESCANTECIPSALDET.NEXTVAL,
      pCdarquivomargemantecipsal,
      rec.CDVINCULO,
      rec.CNPJ,
      rec.CPF,
      rec.NUMATRICULA,
      rec.NUDVMATRICULA,
      rec.NUSEQMATRICULA,
      rec.RMBANCO,
      rec.MARGEMBANCO,
      rec.REGISTRO,
      rec.TELEFONE,
      vNuCPFCadastrador,
      SYSDATE
    );

    v_count := v_count + 1;

    IF MOD(v_count, 5000) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Commit em ' || v_count || ' registros. Tempo: ' || (SYSTIMESTAMP - v_start_time));
      COMMIT;
      v_start_time := SYSTIMESTAMP;
    END IF;
  END LOOP;

  v_resultado := 'Concluída com sucesso as ' || to_char(sysdate,'DD/MM/YYYY - hh24:mi:ss') || ' - Total de registros: ' || v_count;
  SELECT COUNT(*) INTO vQtde FROM EPAGARQUIVOMARGEMANTECIPSALDET AMDET WHERE AMDET.CDARQUIVOMARGEMANTECIPSAL = pCdarquivomargemantecipsal;
  UPDATE EPAGARQUIVOMARGEMANTECIPSAL AM SET AM.NUQTDE = vQtde, AM.INSITUACAO = '3', AM.DESITUACAO = v_resultado, AM.DTULTALTERACAO = SYSDATE WHERE AM.CDARQUIVOMARGEMANTECIPSAL = pCdarquivomargemantecipsal; 
  v_resultado := '1';
  COMMIT;

OPEN p_resultado FOR
  SELECT v_resultado as resultado FROM DUAL;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_resultado := to_char(sysdate,'DD/MM/YYYY - hh24:mi:ss') || ' - Erro: sem dados para processamento.';
  WHEN TOO_MANY_ROWS THEN
    v_resultado := to_char(sysdate,'DD/MM/YYYY - hh24:mi:ss') || ' - Erro: registros em duplicidade.';
  WHEN OTHERS THEN
    v_resultado := to_char(sysdate,'DD/MM/YYYY - hh24:mi:ss') || ' - Erro inesperado: ' || SQLERRM;  
    
      UPDATE EPAGARQUIVOMARGEMANTECIPSAL AM SET AM.NUQTDE = vQtde, AM.INSITUACAO = '4', AM.DESITUACAO = v_resultado, AM.DTULTALTERACAO = SYSDATE WHERE AM.CDARQUIVOMARGEMANTECIPSAL = pCdarquivomargemantecipsal;
COMMIT;
     v_resultado := '0';   


OPEN p_resultado FOR
  SELECT v_resultado as resultado FROM DUAL;

   END;
/*fim PGerarMargemAntecipSal*/
END PKGPAG_CNS;
/
