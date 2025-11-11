CREATE OR REPLACE PACKAGE PKGPAG_PARAM IS

  PROCEDURE PArmazenaInfoFolha (pCdFolhaPagamento IN INTEGER); -- simplificada, dados de folha apenas

  PROCEDURE PArmazenaInfoFolhaAuxiliar (pCdFolhaPagamento IN INTEGER);

  PROCEDURE PArmazenaInfoFolhaNormalAnt (pCdFolhaPagamento IN INTEGER);

  PROCEDURE PArmazenaInfoProc(pcdFolhaPagamento IN INTEGER,
                              pDtCalculo        IN DATE,
                              pCdOrgaoVinc      IN INTEGER DEFAULT NULL);

  PROCEDURE PCargaCarreira(pCdAgrupamento IN INTEGER,
                           pCdEstruturaCarreira IN INTEGER DEFAULT NULL);

  FUNCTION FArmazenaParametrosRubrica(pFolha IN PKGPAG_TIPO.rFolha)

  RETURN PKGPAG_TIPO.tRubrica;

  FUNCTION FValorReferencia(pSGValorReferencia IN VARCHAR)

  RETURN EPagHistValorReferencia.VlReferencia%TYPE  ;

  function fCDBName return varchar2;

  FUNCTION FCargaRubTotalizadora (pCdAgrupamento IN INTEGER,
                                  pCdOrgao       IN INTEGER,
                                  pNuAnoReferencia IN INTEGER,
                                  pNuMesReferencia IN INTEGER) RETURN PKGPAG_TIPO.tListaNumber;   
                                                                
END PKGPAG_PARAM;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_PARAM IS

FUNCTION FRetiraIgualFormula (pExpressao IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN

  IF pExpressao IS NULL THEN
     RETURN NULL;
  ELSIF LENGTH(pExpressao) = 1 THEN
    
    RETURN REPLACE(pExpressao,'=',''); 
  ELSE
    
    RETURN REPLACE(SUBSTR(pExpressao,1,1),'=','')
        || SUBSTR( pExpressao,2)  ;   
  END IF;                    
END;   

PROCEDURE PCargaCarreira(pCdAgrupamento IN INTEGER,
                         pCdEstruturaCarreira IN INTEGER DEFAULT NULL) IS

BEGIN
 
      PKGPAG_VAR.vgCarreira.DELETE;

      IF pCdEstruturaCarreira IS NOT NULL THEN

        FOR rec IN ( SELECT CdEstruturaCarreira, CdEstruturaCarreiraPai
                       FROM ECadEstruturaCarreira C
                    CONNECT BY PRIOR CdEstruturaCarreiraPai = CdEstruturaCarreira
                      START WITH CdEstruturaCarreira = pCdEstruturaCarreira)
        LOOP

          PKGPAG_VAR.vgCarreira (rec.CdEstruturaCarreira).CdEstruturaCarreira    := rec.CdEstruturaCarreira;
          PKGPAG_VAR.vgCarreira (rec.CdEstruturaCarreira).CdEstruturaCarreiraPai := rec.CdEstruturaCarreiraPai;
          PKGPAG_VAR.vgCarreira (rec.CdEstruturaCarreira).NuCargaHoraria         := NULL;

        END LOOP;

      ELSE

        FOR rec IN ( SELECT CdEstruturaCarreira, CdEstruturaCarreiraPai
                       FROM ECadEstruturaCarreira C
                      WHERE C.CdAgrupamento = pCdAgrupamento)
        LOOP

           PKGPAG_VAR.vgCarreira (rec.CdEstruturaCarreira).CdEstruturaCarreira    := rec.CdEstruturaCarreira;
           PKGPAG_VAR.vgCarreira (rec.CdEstruturaCarreira).CdEstruturaCarreiraPai := rec.CdEstruturaCarreiraPai;
           PKGPAG_VAR.vgCarreira (rec.CdEstruturaCarreira).NuCargaHoraria         := NULL;

        END LOOP;

      END IF;

   END;

FUNCTION FRetornaRegraSalFam(pCdAgrupamento   IN INTEGER,
                             pNuAnoReferencia IN INTEGER,
                             pNuMesReferencia IN INTEGER)

  RETURN PKGPAG_TIPO.tSalFamilia IS

  CURSOR cSalFamilia IS
    SELECT RCS.CdRegimeTrabalho,
           HRCS.CdHistRegraConcPagSalFamilia,
           HRCS.CdRubricaAgrupamento
      FROM Epagregraconcpagsalfamilia RCS
     INNER JOIN epagHistRegraConcPagSalFamilia HRCS
        ON RCS.CdRegraConPagSalFamilia = HRCS.CdRegraConPagSalFamilia
     WHERE RCS.CdAgrupamento = pCdAgrupamento AND
           ((HRCS.NuAnoInicioVigencia < pNuAnoReferencia OR
           (HRCS.NuAnoInicioVigencia = pNuAnoReferencia AND
            HRCS.NumesInicioVigencia <= pNuMesReferencia))
           AND
           (HRCS.NuAnoFimVigencia > pNuAnoReferencia OR
           (HRCS.NuAnoFimVigencia = pNuAnoReferencia AND
           HRCS.NuMesFimVigencia >= pNuMesReferencia) OR
           HRCS.NuMesFimVigencia IS NULL));

  vSalFamilia PKGPAG_TIPO.tSalFamilia;

BEGIN
 
  FOR vSF IN cSalFamilia
  LOOP

    vSalFamilia(vSF.CdRegimeTrabalho).CdRegimeTrabalho := vSF.CdRegimeTrabalho;

    vSalFamilia(vSF.CdRegimeTrabalho).CdRubricaAgrupamento := vSF.CdRubricaAgrupamento;

  END LOOP;

  RETURN vSalFamilia;

END;

FUNCTION FRetornaVantagensPecuniarias(pCdAgrupamento   IN INTEGER,
                                      pCdOrgao         IN INTEGER,
                                      pNuAnoReferencia IN INTEGER,
                                      pNuMesReferencia IN INTEGER)

   RETURN PKGPAG_TIPO.tVantagemPecuniaria IS

  CURSOR cVantagem IS
   SELECT VP.CdVantagemPecuniaria,
          VP.CdRubricaAgrupamento,
          HVP.CdHistVantagemPecuniaria,
          HVP.CdFormaPagVantPecuniaria,
          HVP.CdTipoGratificacaoProd,
          HVP.NuValorDeterminado,
          HVP.NuIndiceGeralAplicado,
          HVP.CdRubricaAgrupamento AS CdRubricaTotalizadoraVantagem,
          HVP.NuPeriodoApuracaoFormaPag,
          HVP.FlContabilizaNaoAfastado,
          HVP.Incontabilizamotivosafastament,
          HVP.CdOutraRubricaCondPag,
          HVP.NuMeses,
          HVP.FlAplicaTodoAgrupamento,
          HVP.Flpagavincdecisaojudicial,
          VP.CdOrgao
     FROM EbpcVantagempecuniaria VP
    INNER JOIN Ebpchistvantagempecuniaria HVP
       ON VP.Cdvantagempecuniaria = HVP.Cdvantagempecuniaria
    INNER JOIN EPagHistRubricaAgrupamento HRA
       ON HRA.CdRubricaAgrupamento = VP.CdRubricaAgrupamento
    WHERE VP.CdOrgao = pCdOrgao AND
          (HVP.NuAnoInicio < pNuAnoReferencia OR
          (HVP.NuAnoInicio = pNuAnoReferencia AND
           HVP.NuMesInicio <= pNuMesReferencia))
           AND
           (HVP.NuAnoFim > pNuAnoReferencia OR
           (HVP.NuAnoFim = pNuAnoReferencia AND
           HVP.NuMesFim >= pNuMesReferencia) OR
           HVP.NuMesFim IS NULL)
           AND
           ((HRA.NuAnoInicioVigencia <pNuAnoReferencia OR
           (HRA.NuAnoInicioVigencia = pNuAnoReferencia AND
           HRA.NuMesInicioVigencia <= pNuMesReferencia))
           AND
           (HRA.NuAnoFimVigencia > pNuAnoReferencia OR
           (HRA.NuAnoFimVigencia = pNuAnoReferencia AND
           HRA.NuMesFimVigencia >= pNuMesReferencia) OR
           HRA.NuMesFimVigencia IS NULL))

    UNION ALL

    SELECT VP.CdVantagemPecuniaria,
           VP.CdRubricaAgrupamento,
           HVP.CdHistVantagemPecuniaria,
           HVP.CdFormaPagVantPecuniaria,
           HVP.CdTipoGratificacaoProd,
           HVP.NuValorDeterminado,
           HVP.NuIndiceGeralAplicado,
           HVP.CdRubricaAgrupamento AS CdRubricaTotalizadoraVantagem,
           HVP.NuPeriodoApuracaoFormaPag,
           HVP.FlContabilizaNaoAfastado,
           HVP.Incontabilizamotivosafastament,
           HVP.CdOutraRubricaCondPag,
           HVP.NuMeses,
           HVP.FlAplicaTodoAgrupamento,
           HVP.Flpagavincdecisaojudicial,
           VP.CdOrgao
       FROM Ebpcvantagempecuniaria VP
      INNER JOIN Ebpchistvantagempecuniaria HVP
         ON VP.Cdvantagempecuniaria = HVP.Cdvantagempecuniaria
      INNER JOIN EPagHistRubricaAgrupamento HRA
         ON HRA.CdRubricaAgrupamento = VP.CdRubricaAgrupamento
      WHERE Vp.Cdagrupamento = pCdAgrupamento AND
            (HVP.NuAnoInicio < pNuAnoReferencia OR
            (HVP.NuAnoInicio = pNuAnoReferencia AND
            HVP.NuMesInicio <= pNuMesReferencia))
            AND
            (HVP.NuAnoFim > pNuAnoReferencia OR
            (HVP.NuAnoFim = pNuAnoReferencia AND
            HVP.NuMesFim >= pNuMesReferencia) OR
            HVP.NuMesFim IS NULL)
            AND
            ((HRA.NuAnoInicioVigencia < pNuAnoReferencia OR
            (HRA.NuAnoInicioVigencia = pNuAnoReferencia AND
            HRA.NuMesInicioVigencia <= pNuMesReferencia))
            AND
            (HRA.NuAnoFimVigencia > pNuAnoReferencia OR
            (HRA.NuAnoFimVigencia = pNuAnoReferencia AND
            HRA.NuMesFimVigencia >= pNuMesReferencia) OR
            HRA.NuMesFimVigencia IS NULL))
            AND
            VP.CdRubricaAgrupamento NOT IN (SELECT VP.CdRubricaAgrupamento
                                              FROM EBpcVantagemPecuniaria VP
                                             INNER JOIN Ebpchistvantagempecuniaria HVP
                                                ON VP.CdVantagemPecuniaria = HVP.CdVantagemPecuniaria
                                             WHERE VP.CdOrgao = pCdOrgao AND
                                                   (HVP.NuAnoInicio < pNuAnoReferencia OR
                                                   (HVP.NuAnoInicio = pNuAnoReferencia AND
                                                    HVP.NuMesInicio <= pNuMesReferencia))
                                                    AND
                                                   (HVP.NuAnoFim > pNuAnoReferencia OR
                                                   (HVP.NuAnoFim = pNuAnoReferencia AND
                                                    HVP.NuMesFim >= pNuMesReferencia) OR
                                                    HVP.NuMesFim IS NULL));

  cursor cVantagemOrgaos (pCdHistVantagemPecuniaria IN INTEGER) IS
    select CdOrgao
    from ebpcvantagempecregraconcorgao
    WHERE CdHistVantagemPecuniaria = pCdHistVantagemPecuniaria;

  tVantagem PKGPAG_TIPO.tVantagemPecuniaria;

BEGIN
 
  FOR vVantagem IN cVantagem
  LOOP

     tVantagem(vVantagem.CdVantagemPecuniaria).CdVantagemPecuniaria           := vVantagem.CdVantagemPecuniaria;
     tVantagem(vVantagem.CdVantagemPecuniaria).CdRubricaAgrupamento           := vVantagem.CdRubricaAgrupamento;
     tVantagem(vVantagem.CdVantagemPecuniaria).CdHistVantagemPecuniaria       := vVantagem.CdHistVantagemPecuniaria;
     tVantagem(vVantagem.CdVantagemPecuniaria).CdFormaPagVantPecuniaria       := vVantagem.CdFormaPagVantPecuniaria;
     tVantagem(vVantagem.CdVantagemPecuniaria).CdTipoGratificacaoProd         := vVantagem.CdTipoGratificacaoProd;
     tVantagem(vVantagem.CdVantagemPecuniaria).NuValorDeterminado             := vVantagem.NuValorDeterminado;
     tVantagem(vVantagem.CdVantagemPecuniaria).NuIndiceGeralAplicado         := vVantagem.NuIndiceGeralAplicado;
     tVantagem(vVantagem.CdVantagemPecuniaria).CdRubricaTotalizadoraVantagem  := vVantagem.CdRubricaTotalizadoraVantagem;
     tVantagem(vVantagem.CdVantagemPecuniaria).NuPeriodoApuracaoFormaPag      := vVantagem.NuPeriodoApuracaoFormaPag;
     tVantagem(vVantagem.CdVantagemPecuniaria).FlContabilizaNaoAfastado       := vVantagem.FlContabilizaNaoAfastado;
     tVantagem(vVantagem.CdVantagemPecuniaria).Incontabilizamotivosafastament := vVantagem.Incontabilizamotivosafastament;
     tVantagem(vVantagem.CdVantagemPecuniaria).CdOutraRubricaCondPag         := vVantagem.CdOutraRubricaCondPag;
     tVantagem(vVantagem.CdVantagemPecuniaria).NuMeses                     := vVantagem.NuMeses;
     tVantagem(vVantagem.CdVantagemPecuniaria).FlAplicaTodoAgrupamento       := vVantagem.FlAplicaTodoAgrupamento;
     tVantagem(vVantagem.Cdvantagempecuniaria).FlDecisaoJudicial             := vVantagem.Flpagavincdecisaojudicial;

     IF tVantagem(vVantagem.CdVantagemPecuniaria).FlAplicaTodoAgrupamento = 'N' THEN

        IF vVantagem.CdOrgao IS NOT NULL THEN

           tVantagem(vVantagem.CdVantagemPecuniaria).tabOrgaosPermitidos (vVantagem.CdOrgao) := vVantagem.CdOrgao;

        END IF;

        FOR vOrgao IN cVantagemOrgaos (vVantagem.CdHistVantagemPecuniaria) LOOP

           tVantagem(vVantagem.CdVantagemPecuniaria).tabOrgaosPermitidos (vOrgao.CdOrgao) := vOrgao.CdOrgao;

        END LOOP;

     END IF;

     IF tVantagem(vVantagem.CdVantagemPecuniaria).CdOutraRubricaCondPag is not null
       THEN

         PKGPAG_VAR.vgListaOutraRubCondPag(tVantagem(vVantagem.CdVantagemPecuniaria).CdOutraRubricaCondPag) := tVantagem(vVantagem.CdVantagemPecuniaria).CdOutraRubricaCondPag;

     END IF;

  END LOOP;

  RETURN tVantagem;

END;

FUNCTION FRetornaRubricasPermitidas(pCdTipoFolhaPagamento IN INTEGER,
                                    pNuAnoReferencia      IN INTEGER,
                                    pNuMesReferencia      IN INTEGER)

  RETURN PKGPAG_TIPO.tLista IS

  vLista PKGPAG_TIPO.tLista;

BEGIN
 
  FOR vRub IN (SELECT FR.CdRubricaAgrupamento
                 FROM EPagHistTipoFolhaPagamento HTFP
                INNER JOIN EPagTipoFolhaRubrica FR
                   ON HTFP.CdHistTipoFolhaPagamento = FR.CdHistTipoFolhaPagamento
                WHERE HTFP.CdTipoFolhaPagamento = pCdTipoFolhaPagamento AND
                      ((HTFP.NuAnoInicioVigencia < pNuAnoReferencia OR
                      (HTFP.NuAnoInicioVigencia = pNuAnoReferencia AND
                      HTFP.NumesInicioVigencia <= pNuMesReferencia))
                      AND
                      (HTFP.NuAnoFimVigencia > pNuAnoReferencia OR
                      (HTFP.NuAnoFimVigencia = pNuAnoReferencia AND
                      HTFP.NumesFimVigencia >= pNuMesReferencia) OR
                      HTFP.NuAnoFimVigencia IS NULL)))

  LOOP

     vLista(vRub.CdRubricaAgrupamento):= vRub.CdRubricaAgrupamento;

  END LOOP;

  RETURN vLista;

END;

----------------------------------------------------------------------------
--  FRetornaParamATS - Retorna o parametros
--
----------------------------------------------------------------------------

FUNCTION FRetornaParamATS(pCdAgrupamento   IN INTEGER,
                          pCdOrgao         IN INTEGER,
                          pNuAnoReferencia IN INTEGER,
                          pNuMesReferencia IN INTEGER)

  RETURN PKGPAG_TIPO.tRegraAdicTempServAcum IS

  vTabRegra PKGPAG_TIPO.tRegraAdicTempServAcum;

  i         INTEGER;

BEGIN
 
   i := 0;

   PKGPAG_VAR.vgPercentAcumATS.DELETE;

   FOR vRegra IN (SELECT RT.CdTipoAdicionalTempServ,
                         RT.CdRegraTipoAdicionalTempServ,
                         RA.VlPercentMaxAcum,
                         RA.DtConquista
                    FROM EBpcAdicTempServPercentAcum RA
                   INNER JOIN EBpcHistRegraTipoAdicTempServ HTS
                      ON RA.CdHistRegraTipoAdicTempServ = HTS.CdHistRegraTipoAdicTempServ
                   INNER JOIN EBpcRegraTipoAdicionalTempServ RT
                      ON RT.CdRegraTipoAdicionalTempServ = HTS.CdRegraTipoAdicionalTempServ
                   WHERE ((HTS.NuAnoInicioVigencia < pNuAnoReferencia OR
                         (HTS.NuAnoInicioVigencia = pNuAnoReferencia AND
                          HTS.NuMesInicioVigencia <= pNuMesReferencia))
                          AND
                         (HTS.NuAnoFimVigencia > pNuAnoReferencia OR
                         (HTS.NuAnoFimVigencia = pNuAnoReferencia AND
                          HTS.NuMesFimVigencia >= pNuMesReferencia) OR
                          HTS.NuAnoFimVigencia IS NULL)) AND
                          RT.CdAgrupamento = pCdAgrupamento
                    ORDER BY RT.CdTipoAdicionalTempServ,
                             RT.CdRegraTipoAdicionalTempServ,
                             RA.DtConquista DESC)
   LOOP

     i            := i + 1;

     vTabRegra(i) := vRegra;

     PKGPAG_VAR.vgPercentAcumATS(vRegra.CdTipoAdicionalTempServ) := 0;

   END LOOP;

   RETURN vTabRegra;

END;

/*--------------------------------------------------------------------------
   Func?o: FRetornaEventos

 Objetivo: Seleciona as rubricas associadas aos eventos a serem processados
           pela folha de pagamento

           Tipo de Folha Normal

              - FlPagaTodasRubricas = 'S' retorna cEventoTodasRubricas;
              - InPagamentoRubrica = '1' retorna cEventoPagaRubrica:
              - InPagamentoRubrica = '2' retorna cEventoNaoPagaRubrica

           Outros tipos de folha

              - Se n?o existem rubricas assiciadas a folha de pagamento (EpagFolhaPagRubrica)
                Retorna cEventoTodasRubricas
              - Sen?o
                Retorna cEventoFolhaRubrica

----------------------------------------------------------------------------*/

FUNCTION FRetornaEventos(pFolha IN PKGPAG_TIPO.rFolha)

  RETURN PKGPAG_TIPO.tEvento IS

  vEvento PKGPAG_TIPO.tEvento;

/*---------------------------------------------------------------------------
     Cursor cEventoTodasRubricas
   Objetivo: Seleciona todos os eventos vigentes do agrupamento.
----------------------------------------------------------------------------*/
 CURSOR cEventoTodasRubricas(pCdAgrupamento   INTEGER,
                             pCdOrgao         INTEGER,
                             pNuAnoReferencia INTEGER,
                             pNuMesReferencia INTEGER) IS

      SELECT EPA.CdEventoPagAgrup,
             HEP.CdHistEventoPagAgrup,
             EPA.CdAgrupamento,
             EPA.CdRubricaAgrupamento,
             EPA.CdRubAgrupOpRecebCCO, -- CdRubAgrupAlternativa1
             EPA.CdRubricaAgrupAlternativa2,
             EPA.CdRubricaAgrupAlternativa3,
             EPA.CdTipoEventoPagamento,
             EPA.Deevento,
             R.CdTipoRubrica,
             R.NuRubrica,
             HEP.CdTipoFuncaoChefia,
             HEP.CdRelacaoTrabalho,
             HEP.CdTipoRisco,
             HEP.CdTipoGratAtivFazendaria,
             HEP.CdTipoTempoServico,
             HEP.DtInicioConquistaPerAquis,
             HEP.DtFimConquistaPerAquis,
             HEP.NuMesPagamento,
             HEP.CdTipoComConselhoGrupo,
             HEP.NuFormulaEspecifica,
             HEP.InAcaoCarreira,
             HEP.FlUtilizaFormulaCalculo,
             HEP.CdTipoFalta,
             HEP.CdTipoPensaoNaoPrev,
             HEP.CdGrauEscolaridade
        FROM EpagRubrica R
       INNER JOIN EPagRubricaAgrupamento RA
          ON RA.Cdrubrica = R.Cdrubrica
       INNER JOIN EPagEventoPagAgrup EPA
          ON RA.cdRubricaAgrupamento = EPA.cdRubricaAgrupamento
       INNER JOIN EPagHistEventoPagAgrup HEP
          ON EPA.CdEventoPagAgrup = HEP.CdEventoPagAgrup
       INNER JOIN EPagHistRubricaAgrupamento HRA
          ON HRA.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
       WHERE ((HEP.NuAnoRefInicial < pNuAnoReferencia OR
             (HEP.NuAnoRefInicial = pNuAnoReferencia AND
              HEP.NumesRefInicial <= pNuMesReferencia))
              AND
             (HEP.NuAnoRefFinal > pNuAnoReferencia OR
             (HEP.NuAnoRefFinal = pNuAnoReferencia AND
              HEP.NuMesRefFinal >= pNuMesReferencia) OR
              HEP.NuMesRefFinal IS NULL)) AND
             ((HRA.NuAnoInicioVigencia < pNuAnoReferencia OR
             (HRA.NuAnoInicioVigencia = pNuAnoReferencia AND
              HRA.NuMesInicioVigencia <= pNuMesReferencia))
              AND
             (HRA.NuAnoFimVigencia > pNuAnoReferencia OR
             (HRA.NuAnoFimVigencia = pNuAnoReferencia AND
              HRA.NuMesFimVigencia >= pNuMesReferencia) OR
              HRA.NuMesFimVigencia IS NULL)) AND
            ((pCdOrgao IN (SELECT CdOrgao
                             FROM EPagEventoPagAgrupOrgao EPO
                            WHERE EPO.CdHistEventoPagAgrup = HEP.CdHistEventoPagAgrup)) OR
             HEP.FlAbrangeTodosOrgaos = PKGPAG_TIPO.cnS) AND
             (HEP.NuMesPagamentoInicio IS NULL OR
              (pNuMesReferencia BETWEEN HEP.NuMesPagamentoInicio AND HEP.NuMesPagamentoFim) OR
              EPA.CdTipoEventoPagamento = 51) AND
             RA.CdAgrupamento = pCdAgrupamento
        ORDER BY EPA.cdTipoEventoPagamento, HEP.DtInicioConquistaPerAquis;

 /*---------------------------------------------------------------------------
     Cursor: cEventoPagaRubrica
   Objetivo: Seleciona todos os eventos cujas rubricas est?o definidas
             no tipo de folha que esta sendo processada (EpagTipoFolhaRubrica).
----------------------------------------------------------------------------*/
   CURSOR cEventoPagaRubrica(pCdAgrupamento    INTEGER,
                             pCdOrgao          INTEGER,
                             pNuAnoReferencia  INTEGER,
                             pNuMesReferencia  INTEGER,
                             pcdFolhaPagamento INTEGER) IS

      SELECT EPA.cdEventoPagAgrup,
             HEP.CdHistEventoPagAgrup,
             EPA.CdAgrupamento,
             EPA.CdRubricaAgrupamento,
             EPA.CdRubAgrupOpRecebCCO,
             EPA.CdRubricaAgrupAlternativa2,
             EPA.CdRubricaAgrupAlternativa3,
             EPA.CdTipoEventoPagamento,
             EPA.Deevento,
             R.CdTipoRubrica,
             R.NuRubrica,
             HEP.CdTipoFuncaoChefia,
             HEP.CdRelacaoTrabalho,
             HEP.CdTipoRisco,
             HEP.CdTipoGratAtivFazendaria,
             HEP.CdTipoTempoServico,
             HEP.DtInicioConquistaPerAquis,
             HEP.DtFimConquistaPerAquis,
             HEP.NuMesPagamento,
             HEP.CdTipoComConselhoGrupo,
             HEP.NuFormulaEspecifica,
             HEP.InAcaoCarreira,
             HEP.FlUtilizaFormulaCalculo,
             HEP.CdTipoFalta,
             HEP.CdTipoPensaoNaoPrev,
             HEP.CdGrauEscolaridade
        FROM Epagfolhapagamento FP
       INNER JOIN Epaghisttipofolhapagamento HTFP
          ON FP.Cdtipofolhapagamento = HTFP.Cdtipofolhapagamento
       INNER JOIN EPagTipoFolhaRubrica FR
          ON HTFP.CdHistTipoFolhaPagamento = FR.cdHistTipoFolhaPagamento
       INNER JOIN Epagrubricaagrupamento RA
          ON FR.cdRubricaAgrupamento = RA.cdRubricaAgrupamento
       INNER JOIN EPagHistRubricaAgrupamento HRA
          ON RA.CdRubricaAgrupamento = HRA.CdRubricaAgrupamento
       INNER JOIN EPagRubrica R
          ON RA.CdRubrica = R.CdRubrica
       INNER JOIN Epageventopagagrup EPA
          ON RA.cdRubricaAgrupamento = EPA.cdRubricaAgrupamento
       INNER JOIN Epaghisteventopagagrup HEP
          ON EPA.cdEventoPagAgrup = HEP.cdEventoPagAgrup
       WHERE HTFP.flPagaTodasRubricas = PKGPAG_TIPO.cnN AND
             HTFP.InPagamentoRubrica = 1 AND
          ((HTFP.NuAnoInicioVigencia < FP.NUANOREFERENCIA OR
           (HTFP.NuAnoInicioVigencia = FP.NUANOREFERENCIA AND
            HTFP.NumesInicioVigencia <= FP.NUMESREFERENCIA))
            AND
           (HTFP.NuAnoFimVigencia > FP.NUANOREFERENCIA OR
           (HTFP.NuAnoFimVigencia = FP.NUANOREFERENCIA AND
            HTFP.NumesFimVigencia >= FP.NUMESREFERENCIA) OR
            HTFP.NuAnoFimVigencia IS NULL)) AND
           ((HRA.NuAnoInicioVigencia < FP.NUANOREFERENCIA OR
            (HRA.NuAnoInicioVigencia = FP.NUANOREFERENCIA AND
            HRA.NuMesInicioVigencia <= FP.NUMESREFERENCIA))
            AND
           (HRA.NuAnoFimVigencia >  FP.NUANOREFERENCIA OR
           (HRA.NuAnoFimVigencia =  FP.NUANOREFERENCIA AND
            HRA.NuMesFimVigencia >= FP.NUMESREFERENCIA) OR
            HRA.NuMesFimVigencia IS NULL))
           AND
          ((HEP.nuanorefinicial < FP.NUANOREFERENCIA OR
           (HEP.nuanorefinicial = FP.NUANOREFERENCIA AND
            HEP.numesrefinicial <= FP.NUMESREFERENCIA))
            AND
           (HEP.nuanoreffinal > FP.NUANOREFERENCIA OR
           (HEP.nuanoreffinal = FP.NUANOREFERENCIA AND
            HEP.numesreffinal >= FP.NUMESREFERENCIA) OR
            HEP.nuanoreffinal IS NULL)) AND

          ((FP.CdOrgao IN (SELECT CdOrgao
                             FROM EPagEventoPagAgrupOrgao EPO
                            WHERE EPO.CdHistEventoPagAgrup = HEP.CdHistEventoPagAgrup)) OR
           HEP.FlAbrangeTodosOrgaos = PKGPAG_TIPO.cnS) AND
          (HEP.NuMesPagamentoInicio IS NULL OR
           (pNuMesReferencia BETWEEN HEP.NuMesPagamentoInicio AND HEP.NuMesPagamentoFim)) AND
           FP.CdFolhaPagamento = pCdFolhaPagamento
     ORDER BY EPA.cdTipoEventoPagamento, HEP.DtInicioConquistaPerAquis;

 /*---------------------------------------------------------------------------
     Cursor: cEventoNaoPagaRubrica
   Objetivo: Seleciona todos os eventos vigentes do agrupamento excluindo
             aqueles cujas rubricas est?o definidas no tipo de folha que esta
             sendo processada (EpagTipoFolhaRubrica).
----------------------------------------------------------------------------*/
  CURSOR cEventoNaoPagaRubrica(pCdAgrupamento    INTEGER,
                               pCdOrgao          INTEGER,
                               pNuAnoReferencia  INTEGER,
                               pNuMesReferencia  INTEGER,
                               pcdFolhaPagamento INTEGER) IS

    SELECT EPA.CdEventoPagAgrup,
           HEP.CdHistEventoPagAgrup,
           EPA.CdAgrupamento,
           EPA.CdRubricaAgrupamento,
           EPA.CdRubAgrupOpRecebCCO,
           EPA.CdRubricaAgrupAlternativa2,
           EPA.CdRubricaAgrupAlternativa3,
           EPA.CdTipoEventoPagamento,
           EPA.Deevento,
           R.CdTipoRubrica,
           R.NuRubrica,
           HEP.CdTipoFuncaoChefia,
           HEP.CdRelacaoTrabalho,
           HEP.CdTipoRisco,
           HEP.CdTipoGratAtivFazendaria,
           HEP.CdTipoTempoServico,
           HEP.DtInicioConquistaPerAquis,
           HEP.DtFimConquistaPerAquis,
           HEP.NuMesPagamento,
           HEP.CdTipoComConselhoGrupo,
           HEP.NuFormulaEspecifica,
           HEP.InAcaoCarreira,
           HEP.FlUtilizaFormulaCalculo,
           HEP.CdTipoFalta,
           HEP.CdTipoPensaoNaoPrev,
           HEP.CdGrauEscolaridade
      FROM EpagRubrica R
     INNER JOIN Epagrubricaagrupamento RA
        ON RA.Cdrubrica = R.Cdrubrica
     INNER JOIN EPagHistRubricaAgrupamento HRA
        ON RA.CdRubricaAgrupamento = HRA.CdRubricaAgrupamento
     INNER JOIN EPagEventoPagAgrup EPA
        ON RA.CdRubricaAgrupamento = EPA.cdRubricaAgrupamento
     INNER JOIN EPagHistEventoPagAgrup HEP
        ON EPA.cdEventoPagAgrup = HEP.cdEventoPagAgrup
     WHERE ((HEP.NuAnoRefInicial < pNuAnoReferencia OR
           (HEP.NuAnoRefInicial = pNuAnoReferencia AND
            HEP.NuMesRefInicial <= pNuMesReferencia))
            AND
           (HEP.NuAnoRefFinal > pNuAnoReferencia OR
           (HEP.NuAnoRefFinal = pNuAnoReferencia AND
            HEP.NuMesRefFinal >= pNuMesReferencia) OR
            HEP.NuAnoRefFinal IS NULL)) AND
           ((HRA.NuAnoInicioVigencia < pNuAnoReferencia OR
           (HRA.NuAnoInicioVigencia = pNuAnoReferencia AND
           HRA.NuMesInicioVigencia <= pNuMesReferencia))
           AND
           (HRA.NuAnoFimVigencia > pNuAnoReferencia OR
           (HRA.NuAnoFimVigencia = pNuAnoReferencia AND
            HRA.NuMesFimVigencia >= pNuMesReferencia) OR
            HRA.NuMesFimVigencia IS NULL)) AND
          ((pCdorgao IN (SELECT CdOrgao
                             FROM EPagEventoPagAgrupOrgao EPO
                            WHERE EPO.CdHistEventoPagAgrup = HEP.CdHistEventoPagAgrup)) OR
           HEP.FlAbrangeTodosOrgaos = PKGPAG_TIPO.cnS) AND
           (HEP.NuMesPagamentoInicio IS NULL OR
           (pNuMesReferencia BETWEEN HEP.NuMesPagamentoInicio AND HEP.NuMesPagamentoFim)) AND
           RA.CdAgrupamento = pCdAgrupamento AND
           EPA.CdRubricaAgrupamento NOT IN
             (SELECT CdRubricaAgrupamento
                FROM EPagFolhaPagamento FP
               INNER JOIN EPagHistTipoFolhapagamento HTFP
                  ON FP.CdTipoFolhaPagamento = HTFP.CdTipoFolhaPagamento
               INNER JOIN EPagTipoFolhaRubrica FR
                  ON HTFP.CdHistTipoFolhaPagamento = FR.CdHistTipoFolhaPagamento
               WHERE FP.CdFolhaPagamento = pCdFolhaPagamento AND
                      ((HTFP.NuAnoInicioVigencia < FP.NuAnoReferencia OR
                      (HTFP.NuAnoInicioVigencia = FP.NuAnoReferencia AND
                       HTFP.NuMesInicioVigencia <= FP.NuMesReferencia))
                     AND
                     (HTFP.NuAnoFimVigencia > FP.NuAnoReferencia OR
                     (HTFP.NuAnoFimVigencia = FP.NuAnoReferencia AND
                      HTFP.NuMesFimVigencia >= FP.NuMesReferencia) OR
                      HTFP.NuAnoFimVigencia IS NULL)))
             ORDER BY EPA.cdTipoEventoPagamento, HEP.DtInicioConquistaPerAquis;

BEGIN
 
    -- Caso o tipo de folha indique que devem ser pagas todas as rubricas ou
    -- o tipo de folha seja diferente de Normal ou Bolsista:
    -- Regra: para as folhas de 13º calcula todas as rubricas e no final sao expurgadas

    IF pFolha.FlPagaTodasRubricas = 'S' OR
       (pFolha.CdTipoFolha
           NOT IN (PKGPAG_TIPO.cnTpFolhaNormal,
                   PKGPAG_TIPO.cnTpFolhaBolsista,
                   PKGPAG_TIPO.cnTpFolhaResidente,
                   PKGPAG_TIPO.cnTpFolhaOutras,
                   --PKGPAG_TIPO.cnTpFolhaBEP,
                   PKGPAG_TIPO.cnTpFolhaFunebre,
                   PKGPAG_TIPO.cnTpFolhaServAfast,
                   PKGPAG_TIPO.cnTpFolhaInstPensao,
                   PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                   pkgpag_tipo.cntpfolharescisaopesquisador )) THEN

       -- Paga todas as rubricas associadas aos eventos

      OPEN cEventoTodasRubricas(pFolha.CdAgrupamento,
                                pFolha.CdOrgao,
                                pFolha.NuAnoReferencia,
                                pFolha.NuMesReferencia);

      FETCH cEventoTodasRubricas BULK COLLECT INTO vEvento;

      CLOSE cEventoTodasRubricas;

    ELSIF pFolha.InPagamentoRubrica = '1' THEN -- As rubricas associadas devem ser pagas

      OPEN cEventoPagaRubrica(pFolha.CdAgrupamento,
                              pFolha.CdOrgao,
                              pFolha.NuAnoReferencia,
                              pFolha.NuMesReferencia,
                              pFolha.CdFolhaPagamento);

      FETCH cEventoPagaRubrica BULK COLLECT INTO vEvento;

      CLOSE cEventoPagaRubrica;

    ELSIF pFolha.InPagamentoRubrica = '2' THEN -- As rubricas associadas nao devem ser pagas

      OPEN cEventoNaoPagaRubrica(pFolha.CdAgrupamento,
                                 pFolha.CdOrgao,
                                 pFolha.NuAnoReferencia,
                                 pFolha.NuMesReferencia,
                                 pFolha.CdFolhaPagamento);

      FETCH cEventoNaoPagaRubrica BULK COLLECT INTO vEvento;

      CLOSE cEventoNaoPagaRubrica;

    else
      null;
    END IF;

    RETURN vEvento;

END;

FUNCTION FTipoPensaoNaoPrevRecad (pCdEventoRecadastramento IN INTEGER)

  RETURN PKGPAG_TIPO.tLista IS

  vLista PKGPAG_TIPO.tLista;

BEGIN
 
  FOR vRec IN (SELECT HTP.CdTipoPensaoNaoPrev
                 FROM EPvdHistEvRecadTpPensaoNaoPrev HER
                INNER JOIN EPvdHistTipoPensaoNaoPrev HTP
                   ON HTP.CdHistTipoPensaoNaoPrev = HER.CdHistTipoPensaoNaoPrev
                INNER JOIN EPvdTipoPensaoNaoPrev PNP
                   ON HTP.CdTipoPensaoNaoPrev = PNP.CdTipoPensaoNaoPrev
                WHERE HER.CdHistEventoRecadastramento = pCdEventoRecadastramento)
  LOOP

     vLista(vRec.CdTipoPensaoNaoPrev) := vRec.CdTipoPensaoNaoPrev;

  END LOOP;

  RETURN vLista;

EXCEPTION

  WHEN OTHERS THEN

    RETURN vLista;

END;

FUNCTION FEventoAfastamento (pCdEventoAfastamento IN INTEGER)

  RETURN PKGPAG_TIPO.tLista IS

  vLista PKGPAG_TIPO.tLista;

BEGIN
 
  FOR RM in (SELECT EMM.CDMOTIVOAFASTTEMPORARIO
               from eafahisteventomotafast hmot
               inner join eafaeventomotivoafast emt on hmot.cdeventomotivoafast = emt.cdeventomotivoafast
                      AND hmot.dtiniciovigencia <= pkgpag_var.vgFolha.DtInicioMes
                      AND (hmot.dtfimvigencia >= pkgpag_var.vgFolha.DtInicioMes OR
                           hmot.dtfimvigencia IS NULL)
                      AND emt.cdeventoafastamento = pCdEventoAfastamento
               inner join eafaeventomotivo emm on emm.cdhisteventomotafast = hmot.cdhisteventomotafast
               WHERE emt.cdagrupamento = pkgpag_var.vgfolha.cdagrupamento)

  LOOP
        IF RM.CDMOTIVOAFASTTEMPORARIO IS NOT NULL THEN

           vLista(RM.CDMOTIVOAFASTTEMPORARIO) := RM.CDMOTIVOAFASTTEMPORARIO;

        END IF;

  END LOOP;

  RETURN vLista;

EXCEPTION

  WHEN OTHERS THEN

    RETURN vLista;

END;

FUNCTION FListaRubFuncaoPrivativa (pCdAgrupamento IN INTEGER)

  RETURN PKGPAG_TIPO.tLista IS

  vLista PKGPAG_TIPO.tLista;

BEGIN
 
  FOR RB in (SELECT rub.cdrubricaagrupamento
               from epagrubricaagrupamento rub
               inner join epagrubrica err on err.cdrubrica = rub.cdrubrica
               WHERE rub.cdagrupamento = pCdAgrupamento
                 AND err.nurubrica in (433,720,721)
                 AND err.cdtiporubrica = 1)

  LOOP
        vLista(RB.cdrubricaagrupamento) := rb.cdrubricaagrupamento;

  END LOOP;

  RETURN vLista;

EXCEPTION

  WHEN OTHERS THEN

    RETURN vLista;

END;

PROCEDURE PArmazenaCarreiraEvento IS

BEGIN
 
   IF PKGPAG_VAR.vgEvento.COUNT > 0 THEN

      FOR i IN PKGPAG_VAR.vgEvento.FIRST .. PKGPAG_VAR.vgEvento.LAST
      LOOP

        FOR vCarr IN (SELECT HEC.CdEstruturaCarreira
                        FROM EPagHistEventoPagAgrupCarreira HEC
                       WHERE HEC.CdHistEventoPagAgrup = PKGPAG_VAR.vgEvento(i).CdHistEventoPagAgrup)
        LOOP

          PKGPAG_VAR.vgEventoCarreira(PKGPAG_VAR.vgEvento(i).CdEventoPagAgrup).Carreira(vCarr.CdEstruturaCarreira) :=

            vCarr.CdEstruturaCarreira;

        END LOOP;

     END LOOP;

  END IF;

END;

FUNCTION FRetornaRubricasExcludentes (pCdOrgao         IN INTEGER,
                                      pNuAnoReferencia IN INTEGER,
                                      pNuMesReferencia IN INTEGER)

  RETURN PKGPAG_TIPO.tRubExcludente IS

  vRubExcludente PKGPAG_TIPO.tRubExcludente;

BEGIN
 
  FOR vRE IN (SELECT RE.CdRubricaExcludente,
                     RE.CdRubricaAgrupamentoExcludente,
                     RE.CdRubricaAgrupamentoOutraRubEx,
                     RE.CdRubricaAgrupamentoPagDif,
                     RE.InTipoRegraRubExcludente,
                     RE.InRubricaPermanece
                FROM EPagRubricaExcludente RE
               WHERE RE.CdOrgao = pCdOrgao AND
                     (RE.NuAnoInicio < pNuAnoReferencia OR
                     (RE.NuAnoInicio = pNuAnoReferencia AND
                     RE.NuMesInicio <= pNuMesReferencia))
                     AND
                     (RE.NuAnoFim > pNuAnoReferencia OR
                     (RE.NuAnoFim = pNuAnoReferencia AND
                     RE.NuMesFim >= pNuMesReferencia) OR
                     RE.NuAnoFim IS NULL))
  LOOP

    vRubExcludente(vRE.CdRubricaExcludente) := vRE;

  END LOOP;

  RETURN vRubExcludente;

END;

/*----------------------------------------------------------------------------
   Funcao: FOrgaoParam
 Objetivo: Retorna os parametros de pagamento do agrupamento com base
           no ano/mes de processamento da folha
/*--------------------------------------------------------------------------*/

FUNCTION FOrgaoParam(pCdOrgao         IN INTEGER,
                     pNuAnoReferencia IN INTEGER,
                     pNuMesReferencia IN INTEGER)
  RETURN EPagOrgaoParametro%ROWTYPE IS

  vParamPagamento EPagOrgaoParametro%ROWTYPE;

BEGIN
 
  SELECT *
    INTO vParamPagamento
    FROM EPagOrgaoParametro A
   WHERE A.CdOrgao = pCdOrgao AND
         ((A.NuAnoInicioVigencia < pNuAnoReferencia OR
          (A.NuAnoInicioVigencia = pNuAnoReferencia AND
           A.NuMesInicioVigencia <= pNuMesReferencia))
          AND
          (A.NuAnoFimVigencia > pNuAnoReferencia OR
          (A.NuAnoFimVigencia = pNuAnoReferencia AND
           A.NuMesFimVigencia >= pNuMesReferencia) OR
           A.NuAnoFimVigencia IS NULL));

  RETURN vParamPagamento;

EXCEPTION

  WHEN OTHERS THEN

    RETURN NULL;

END;

FUNCTION FOrgaoFeriasParam(pCdOrgao         IN INTEGER,
                           pDtCalculo       IN DATE)

  RETURN EMovOrgaoFerias%ROWTYPE IS

  vParamFerias EMovOrgaoFerias%ROWTYPE;

BEGIN
 
  SELECT *
    INTO vParamFerias
    FROM EMovOrgaoFerias A
   WHERE A.CdOrgao = pCdOrgao AND
         A.DtInicioVigencia <= pdtCalculo AND
         (A.DtFimVigencia >= pDtCalculo OR A.DtFimVigencia IS NULL);

  RETURN vParamFerias;

EXCEPTION

  WHEN OTHERS THEN

    RETURN NULL;

END;

FUNCTION FOrgaoFrequenciaParam(pCdOrgao         IN INTEGER,
                               pDtCalculo       IN DATE)

  RETURN EMovOrgaoFrequencia%ROWTYPE IS

  vParamFerias EmovOrgaoFrequencia%ROWTYPE;

BEGIN
 
  SELECT *
    INTO vParamFerias
    FROM EMovOrgaoFrequencia A
   WHERE A.CdOrgao = pCdOrgao;

  RETURN vParamFerias;

EXCEPTION

  WHEN OTHERS THEN

    RETURN NULL;

END;

/*----------------------------------------------------------------------------
   Funcao: FEventoRecadastramento
 Objetivo: Retorna os parametros do evento de recadastramento
/*--------------------------------------------------------------------------*/

FUNCTION FEventoRecadastramento(pNuAno IN INTEGER)

  RETURN EPvdHistEventoRecadastramento%ROWTYPE IS

  vEvento EPvdHistEventoRecadastramento%ROWTYPE;

BEGIN
 
  SELECT HER.*
    INTO vEvento
    FROM EPvdHistEventoRecadastramento HER
   INNER JOIN Epvdhistevrecadtiposervidor HETS
      ON HER.CdHistEventoRecadastramento = HETS.CdHistEventoRecadastramento
   WHERE HETS.CdTipoServidor = case when pkgpag_var.vgfolha.cdorgao = 33 then 9 else 2 end AND
         HER.FlAnulado = 'N' AND
         pNuAno BETWEEN HER.NuAnoInicioEvRecadastramento AND NVL(her.NuAnoFinalEvRecadastramento,4000) AND
         ROWNUM < 2;

  RETURN vEvento;

EXCEPTION

  WHEN NO_DATA_FOUND THEN

    RETURN NULL;

END;

PROCEDURE PCargaRubParamAgrupamento (pCdAgrupamento   IN INTEGER,
                                     pNuAnoReferencia IN INTEGER,
                                     pNuMesReferencia IN INTEGER,
                                     pFlCargaTabela   IN INTEGER,
                                     pTotRub      IN OUT NOCOPY PKGPAG_TIPO.tListaNumber) IS
                                 
   vIdentRubrica   PKGPAG_TIPO.rIdentRubrica;
   vIdent          INTEGER;

   PROCEDURE PAdicionar (pIdent IN INTEGER, pCdRubricaAgrupamento IN INTEGER) IS
      
   BEGIN
      IF pCdRubricaAgrupamento IS NOT NULL THEN
         IF NOT pTotRub.EXISTS (pIdent) THEN
             pTotRub(pIdent) := TYPENUMBER();
         END IF;
         
         pTotRub(pIdent).EXTEND;
         pTotRub(pIdent)(pTotRub(pIdent).LAST) := pCdRubricaAgrupamento;
      END IF;
   END;
   
BEGIN

   IF pFlCargaTabela = 0 THEN -- Apenas preencher a global 
      PKGPAG_VAR.vgParamPagamento := NULL;
   END IF;
      
   FOR rec IN (SELECT *
                 FROM EPagAgrupamentoParametro A
                WHERE (pCdAgrupamento IS NULL OR A.CdAgrupamento = pCdAgrupamento) AND
                      ((A.NuAnoInicioVigencia < pNuAnoReferencia OR
                       (A.NuAnoInicioVigencia = pNuAnoReferencia AND
                        A.NuMesInicioVigencia <= pNuMesReferencia))
                       AND
                       (A.NuAnoFimVigencia > pNuAnoReferencia OR
                       (A.NuAnoFimVigencia = pNuAnoReferencia AND
                        A.NuMesFimVigencia >= pNuMesReferencia) OR
                        A.NuAnoFimVigencia IS NULL)) )LOOP
 
      IF pFlCargaTabela = 0 THEN -- Apenas preencher a global 

         IF nvl(rec.VlLimitepagretroativo,0) IS NULL THEN

            RAISE PKGPAG_VAR.ePercErarioIncorreto;

         END IF;

         PKGPAG_VAR.vgParamPagamento := rec;
         EXIT;
      END IF;
   
      PAdicionar (pIdent => vIdentRubrica.cnIndAjustesaldodevedor           , pCdRubricaAgrupamento => rec.CdRubAgrupAjustesaldodevedor);
      PAdicionar (pIdent => vIdentRubrica.cnIndAjustesaldodevedor13         , pCdRubricaAgrupamento => rec.CdRubAgrupAjustesaldodevedor13);
      PAdicionar (pIdent => vIdentRubrica.cnIndBloqexercfind13sal           , pCdRubricaAgrupamento => rec.CdRubAgrupBloqexercfind13sal);
      PAdicionar (pIdent => vIdentRubrica.cnIndBloqret                      , pCdRubricaAgrupamento => rec.CdRubAgrupBloqret);
      PAdicionar (pIdent => vIdentRubrica.cnIndBloqret13sal                 , pCdRubricaAgrupamento => rec.CdRubAgrupBloqret13sal);
      PAdicionar (pIdent => vIdentRubrica.cnIndBloqretexercfind             , pCdRubricaAgrupamento => rec.CdRubAgrupBloqretexercfind);
      PAdicionar (pIdent => vIdentRubrica.cnIndCorbep                       , pCdRubricaAgrupamento => rec.CdRubAgrupCorbep);
      PAdicionar (pIdent => vIdentRubrica.cnIndDesccpsmretera               , pCdRubricaAgrupamento => rec.CdRubAgrupDesccpsmretera);
      PAdicionar (pIdent => vIdentRubrica.cnIndDesccpsmretera13             , pCdRubricaAgrupamento => rec.CdRubAgrupDesccpsmretera13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDesccpsmsobre13              , pCdRubricaAgrupamento => rec.CdRubAgrupDesccpsmsobre13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescinss                     , pCdRubricaAgrupamento => rec.CdRubAgrupDescinss);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescinsssobre13              , pCdRubricaAgrupamento => rec.CdRubAgrupDescinsssobre13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescipescjul200813           , pCdRubricaAgrupamento => rec.CdRubAgrupDescipescjul200813);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescipescsobre13             , pCdRubricaAgrupamento => rec.CdRubAgrupDescipescsobre13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDesciprevantes2008           , pCdRubricaAgrupamento => rec.CdRubAgrupDesciprevantes2008);
      PAdicionar (pIdent => vIdentRubrica.cnIndDesciprevdepois2008          , pCdRubricaAgrupamento => rec.CdRubAgrupDesciprevdepois2008);
      PAdicionar (pIdent => vIdentRubrica.cnIndDesciprevliminar             , pCdRubricaAgrupamento => rec.CdRubAgrupDesciprevliminar);
      PAdicionar (pIdent => vIdentRubrica.cnIndDesciprevliminar13           , pCdRubricaAgrupamento => rec.CdRubAgrupDesciprevliminar13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescirrf                     , pCdRubricaAgrupamento => rec.CdRubAgrupDescirrf);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescirrfsobre13              , pCdRubricaAgrupamento => rec.CdRubAgrupDescirrfsobre13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescirrfsobreferias          , pCdRubricaAgrupamento => rec.CdRubAgrupDescirrfsobreferias);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescscfuturo                 , pCdRubricaAgrupamento => rec.CdRubAgrupDescscfuturo);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescscfuturo13               , pCdRubricaAgrupamento => rec.CdRubAgrupDescscfuturo13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescscfuturoret              , pCdRubricaAgrupamento => rec.CdRubAgrupDescscfuturoret);
      PAdicionar (pIdent => vIdentRubrica.cnIndDescscfuturoret13            , pCdRubricaAgrupamento => rec.CdRubAgrupDescscfuturoret13);
      PAdicionar (pIdent => vIdentRubrica.cnIndDevajustesaldodev13          , pCdRubricaAgrupamento => rec.CdRubAgrupDevajustesaldodev13);
      PAdicionar (pIdent => vIdentRubrica.cnIndIprevfundfinanc              , pCdRubricaAgrupamento => rec.CdRubAgrupIprevfundfinanc);
      PAdicionar (pIdent => vIdentRubrica.cnIndIprevfundfinanc13            , pCdRubricaAgrupamento => rec.CdRubAgrupIprevfundfinanc13);
      PAdicionar (pIdent => vIdentRubrica.cnIndIprevfundlc662               , pCdRubricaAgrupamento => rec.CdRubAgrupIprevfundlc662);
      PAdicionar (pIdent => vIdentRubrica.cnIndIprevfundlc66213             , pCdRubricaAgrupamento => rec.CdRubAgrupIprevfundlc66213);
      PAdicionar (pIdent => vIdentRubrica.cnIndIprevfundprev                , pCdRubricaAgrupamento => rec.CdRubAgrupIprevfundprev);
      PAdicionar (pIdent => vIdentRubrica.cnIndIprevjudretera               , pCdRubricaAgrupamento => rec.CdRubAgrupIprevjudretera);
      PAdicionar (pIdent => vIdentRubrica.cnIndIprevjudretera13             , pCdRubricaAgrupamento => rec.CdRubAgrupIprevjudretera13);
      PAdicionar (pIdent => vIdentRubrica.cnIndPensao13                     , pCdRubricaAgrupamento => rec.CdRubAgrupPensao13);
      PAdicionar (pIdent => vIdentRubrica.cnIndPensaoalirra                 , pCdRubricaAgrupamento => rec.CdRubAgrupPensaoalirra);
      PAdicionar (pIdent => vIdentRubrica.cnIndPgtobep                      , pCdRubricaAgrupamento => rec.CdRubAgrupPgtobep);
      PAdicionar (pIdent => vIdentRubrica.cnIndRubricaAdiant13pensao        , pCdRubricaAgrupamento => rec.CdRubricaAdiant13pensao);
      PAdicionar (pIdent => vIdentRubrica.cnIndRubricaAgrupdesccpsm         , pCdRubricaAgrupamento => rec.CdRubricaAgrupdesccpsm);
      PAdicionar (pIdent => vIdentRubrica.cnIndRubricaAgrupdescipesc        , pCdRubricaAgrupamento => rec.CdRubricaAgrupdescipesc);
      PAdicionar (pIdent => vIdentRubrica.cnIndRubricaAgrupdescipescjul2008 , pCdRubricaAgrupamento => rec.CdRubricaAgrupdescipescjul2008);
      PAdicionar (pIdent => vIdentRubrica.cnIndRubricaAgrupdesciprevjun1613 , pCdRubricaAgrupamento => rec.CdRubricaAgrupdesciprevjun1613);
      PAdicionar (pIdent => vIdentRubrica.cnIndRubricaAgrupdesciprevjun2016 , pCdRubricaAgrupamento => rec.CdRubricaAgrupdesciprevjun2016);
      PAdicionar (pIdent => vIdentRubrica.cnIndRubricaAgrupdescrra          , pCdRubricaAgrupamento => rec.CdRubricaAgrupdescrra);
      
   END LOOP;

END;

/*----------------------------------------------------------------------------
   Procedure: PParamPagamento
 Objetivo: Preenche os parametros de pagamento do agrupamento com base
           no ano/mes de processamento da folha
/*--------------------------------------------------------------------------*/

PROCEDURE PParamPagamento(pCdAgrupamento   IN INTEGER,
                          pNuAnoReferencia IN INTEGER,
                          pNuMesReferencia IN INTEGER) IS

   vTotRub         PKGPAG_TIPO.tListaNumber;
BEGIN
   
   PCargaRubParamAgrupamento (pCdAgrupamento   => pCdAgrupamento,
                              pNuAnoReferencia => pNuAnoReferencia,
                              pNuMesReferencia => pNuMesReferencia,
                              pFlCargaTabela   => 0,
                              pTotRub          => vTotRub);

END;

/*PROCEDURE PArmazenaCarreiraParametro(pCdAgrupamentoParametro IN INTEGER) IS

BEGIN
 
   FOR vParamCarreira IN (SELECT PC.CdEstruturaCarreira,
                                 PC.CdRubricaAgrupamento,
                                 PC.VlPercentual
                            FROM EPagAgrupParamCarreira PC
                           WHERE PC.CdAgrupamentoParametro = pCdAgrupamentoParametro)
   LOOP

     PKGPAG_VAR.vgParamCarreira(vParamCarreira.CdEstruturaCarreira) := vParamCarreira;

   END LOOP;
END;*/

PROCEDURE PArmazenaCCOParametro(pCdAgrupamentoParametro IN INTEGER) IS

BEGIN
 
   FOR vParamCCO IN (SELECT PC.CdCargoComissionado,
                            PC.CdRubricaAgrupamento,
                            PC.VlPercentual
                            FROM EPagAgrupParamCargoCom PC
                           WHERE PC.CdAgrupamentoParametro = pCdAgrupamentoParametro)
   LOOP

     PKGPAG_VAR.vgParamCCO(vParamCCO.CdCargoComissionado) := vParamCCO;

   END LOOP;

END;

/*----------------------------------------------------------------------------------------/*
    Funcao: FRetornaParametroFrequencia
  Objetivo: Retorna os parametros da apuracao da frequencia

/*-----------------------------------------------------------------------------------------*/

FUNCTION FRetornaParametroValeTransp(pCdOrgao              IN INTEGER,
                                     pNuAnoReferencia      IN INTEGER,
                                     pNuMesReferencia      IN INTEGER)

  RETURN EVtrHistOrgaoIndicadorVale%ROWTYPE IS

  vIndicadorVale EVtrHistOrgaoIndicadorVale%ROWTYPE;

BEGIN
 
 SELECT HIV.*
   INTO vIndicadorVale
   FROM EVtrOrgaoIndicadorVale IV
  INNER JOIN Evtrhistorgaoindicadorvale HIV
     ON IV.CdOrgaoIndicadorVale = HIV.CdOrgaoIndicadorVale
  WHERE IV.CdOrgao = pCdOrgao AND
        ((HIV.NuAnoInicioVigencia < pNuAnoReferencia OR
        (HIV.NuAnoInicioVigencia = pNuAnoReferencia AND
         HIV.NuMesInicioVigencia <= pNuMesReferencia))
         AND
        (HIV.NuAnoFimVigencia > pNuAnoReferencia OR
        (HIV.NuAnoFimVigencia = pNuAnoReferencia AND
        HIV.NuMesFimVigencia >= pNuMesReferencia) OR
        HIV.NuAnoFimVigencia IS NULL));

  RETURN vIndicadorVale;

EXCEPTION

  WHEN OTHERS THEN

    RETURN NULL;

END;

/*----------------------------------------------------------------------------------------/*
    Funcao: FRetornaParametroFrequencia
  Objetivo: Retorna os parametros da apuracao da frequencia

/*-----------------------------------------------------------------------------------------*/

FUNCTION FRetornaParametroFrequencia(pCdOrgao              IN INTEGER,
                                     pNuAnoReferencia      IN INTEGER,
                                     pNuMesReferencia      IN INTEGER)
  RETURN EMovApuracaoFrequencia%ROWTYPE IS

  vApuracaoFreq EMovApuracaoFrequencia%ROWTYPE;

BEGIN
 
  SELECT *
    INTO vApuracaoFreq
    FROM EMovApuracaoFrequencia F
   WHERE F.CdOrgao = pCdOrgao AND
         F.NuAnoRefPagamento = pNuAnoReferencia AND
         F.NuMesRefPagamento = pNuMesReferencia;

  RETURN vApuracaoFreq;

EXCEPTION

  WHEN OTHERS THEN

    RETURN NULL;

END;

FUNCTION FValorReferencia(pSGValorReferencia IN VARCHAR)

 RETURN EPagHistValorReferencia.VlReferencia%TYPE IS

 vCdValorReferencia EPagValorReferencia.CdValorReferencia%TYPE;

BEGIN
 
    vCdValorReferencia := PKGPAG_VAR.vgValorReferencia.FIRST;

    WHILE vCdValorReferencia IS NOT NULL LOOP

      IF PKGPAG_VAR.vgValorReferencia(vCdValorReferencia).SGValorReferencia = pSGValorReferencia THEN

        RETURN PKGPAG_VAR.vgValorReferencia(vCdValorReferencia).VlReferencia;

      END IF;

      vCdValorReferencia := PKGPAG_VAR.vgValorReferencia.next(vCdValorReferencia);

    END LOOP;

    pkgpag_geral.pinserelog(pkgpag_var.blog,
                            pkgpag_var.vcdhistparamcalc,
                            pkgpag_var.vcdpessoa,
                            'Valor de referência ' || pSGValorReferencia || ' não encontrado',
                            pkgpag_var.vgcdvinculo,
                            2);

    RETURN NULL;

END;

FUNCTION FRetornaValorReferencia(pFolha IN PKGPAG_TIPO.rFolha)

  RETURN PKGPAG_TIPO.tValorReferencia IS

  tValRef PKGPAG_TIPO.tValorReferencia;

BEGIN
 
  FOR vValorReferencia IN (SELECT VR.CdValorReferencia,
                                  HVR.CdHistValorReferencia,
                                  HVR.VlReferencia,
                                  VR.FlValeTransporte,
                                  VR.FlBloqueioRemuneracao,
                                  SGVALORREFERENCIA
                             FROM EPagValorReferencia VR
                            INNER JOIN EPagValorReferenciaVersao VRV
                               ON VR.CdValorReferencia = VRV.CdValorReferencia
                            INNER JOIN EPagHistValorReferencia HVR
                               ON VRV.CdValorReferenciaVersao = HVR.CdValorReferenciaVersao
                            WHERE VR.CdAgrupamento = pFolha.CdAgrupamento AND
                                  VRV.NuVersao = pFolha.NuVersaoTabValorReferencia AND
                                  (HVR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                                  (HVR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                                  HVR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
                                  (HVR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                                  (HVR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                                  HVR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                                  HVR.NuAnoFimVigencia IS NULL)
                            UNION ALL
                            SELECT VR.CdValorReferencia,
                                   HVR.CdHistValorReferencia,
                                   HVR.VlReferencia,
                                   VR.FlValeTransporte,
                                   VR.FlBloqueioRemuneracao,
                                   SGVALORREFERENCIA
                              FROM EPagValorReferencia VR
                             INNER JOIN EPagValorReferenciaVersao VRV
                                ON VR.CdValorReferencia = VRV.CdValorReferencia
                             INNER JOIN EPagHistValorReferencia HVR
                                ON VRV.CdValorReferenciaVersao = HVR.CdValorReferenciaVersao
                             WHERE VR.CdAgrupamento = pFolha.CdAgrupamento AND
                                   VRV.NuVersao = PKGPAG_TIPO.cn1 AND
                                   (HVR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                                   (HVR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                                   HVR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
                                   (HVR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                                   (HVR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                                   HVR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                                   HVR.NuAnoFimVigencia IS NULL) AND
                                   VR.CdValorReferencia NOT IN  (SELECT VR.CdValorReferencia
                                                                   FROM EPagValorReferencia VR
                                                                  INNER JOIN EPagValorReferenciaVersao VRV
                                                                     ON VR.CdValorReferencia = VRV.CdValorReferencia
                                                                  INNER JOIN EPagHistValorReferencia HVR
                                                                     ON VRV.CdValorReferenciaVersao = HVR.CdValorReferenciaVersao
                                                                  WHERE VR.CdAgrupamento = pFolha.CdAgrupamento AND
                                                                        VRV.NuVersao = pFolha.NuVersaoTabValorReferencia AND
                                                                        (HVR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                                                                        (HVR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                                                                        HVR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
                                                                        (HVR.NuAnoFimVigencia > pFolha.NuAnoReferencia  OR
                                                                        (HVR.NuAnoFimVigencia = pFolha.NuAnoReferencia  AND
                                                                        HVR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                                                                        HVR.NuAnoFimVigencia IS NULL)))
  LOOP

    tValRef(vValorReferencia.CdValorReferencia).CdValorReferencia := vValorReferencia.CdValorReferencia;

    tValRef(vValorReferencia.CdValorReferencia).VlReferencia := vValorReferencia.VlReferencia;

    tValRef(vValorReferencia.CdValorReferencia).FlValeTransporte := vValorReferencia.FlValeTransporte;

    tValRef(vValorReferencia.CdValorReferencia).FlBloqueioRemuneracao := vValorReferencia.FlBloqueioRemuneracao;

    tValRef(vValorReferencia.CdValorReferencia).Sgvalorreferencia :=  vValorReferencia.Sgvalorreferencia;

    IF vValorReferencia.SGvalorreferencia = 'BONUS100' THEN
           PKGPAG_VAR.vgCdValorReferencia100 := vValorReferencia.CdValorReferencia;

    ELSIF  vValorReferencia.SGvalorreferencia = 'BONUS300' THEN
           PKGPAG_VAR.vgCdValorReferencia300 := vValorReferencia.CdValorReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'FGTSJA' THEN
        PKGPAG_VAR.vgFgtsJa := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'ERACTISP' THEN
        PKGPAG_VAR.vgVlEraCTISP := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'CR PEC N1' THEN
        pkgpag_var.vgVlCRPECN(1) := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'CR PEC N2' THEN
        pkgpag_var.vgVlCRPECN(2) := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'CR PEC N3' THEN
        pkgpag_var.vgVlCRPECN(3) := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'CR PEC N4' THEN
        pkgpag_var.vgVlCRPECN(4) := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'CR PEC N5' THEN
        pkgpag_var.vgVlCRPECN(5) := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'CR PEC N6' THEN
        pkgpag_var.vgVlCRPECN(6) := vValorReferencia.VlReferencia;

    ELSIF vValorReferencia.SGvalorreferencia = 'IND UNIF' THEN
        pkgpag_var.vgVlIndUniforme := vValorReferencia.VlReferencia;
        
    else
      null;
    END IF;

    FOR vValRefCarr IN (SELECT VRC.CdEstruturaCarreira,
                               VRC.VlReferencia
                          FROM EPagHistValorRefCarreira VRC
                         WHERE VRC.CdHistValorReferencia = vValorReferencia.CdHistValorReferencia)
    LOOP

      tValRef(vValorReferencia.CdValorReferencia).lsValRefCarreira(vValRefCarr.CdEstruturaCarreira) :=

         vValRefCarr.VlReferencia;

    END LOOP;

    FOR vValRefPrograma IN (SELECT VRP.CdPrograma,
                                   VRP.VlReferencia
                              FROM EPagHistValorRefPrograma VRP
                             WHERE VRP.CdHistValorReferencia = vValorReferencia.CdHistValorReferencia)
    LOOP

      tValRef(vValorReferencia.CdValorReferencia).lsValRefPrograma(vValRefPrograma.CdPrograma) :=

         vValRefPrograma.VlReferencia;

    END LOOP;

  END LOOP;

  -- Excecao (VALOR LIMITE DE DESCONTO DO RGPS), considerar do agrupamento 1 GERAL para todos os demais

  pkgpag_var.vgValorReferenciaMAXINSS := 0;

  begin
    SELECT HVR.VlReferencia
      INTO pkgpag_var.vgValorReferenciaMAXINSS
      FROM EPagValorReferencia VR
      INNER JOIN EPagValorReferenciaVersao VRV
              ON VR.CdValorReferencia = VRV.CdValorReferencia
      INNER JOIN EPagHistValorReferencia HVR
              ON VRV.CdValorReferenciaVersao = HVR.CdValorReferenciaVersao
     WHERE VR.CdAgrupamento = 1
       AND VRV.NuVersao = pFolha.NuVersaoTabValorReferencia
       AND (HVR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
            (HVR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
             HVR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
             (HVR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
              (HVR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
               HVR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
               HVR.NuAnoFimVigencia IS NULL)
       AND Vr.Sgvalorreferencia = 'VTRGPS';

     exception
       when no_data_found then
         pkgpag_var.vgValorReferenciaMAXINSS := 0;
       when others then
         pkgpag_var.vgValorReferenciaMAXINSS := 0;

   end;

   pkgpag_var.vgValorReferenciaVLDCI := 0;

  begin
    SELECT HVR.VlReferencia
      INTO pkgpag_var.vgValorReferenciaVLDCI
      FROM EPagValorReferencia VR
      INNER JOIN EPagValorReferenciaVersao VRV
              ON VR.CdValorReferencia = VRV.CdValorReferencia
      INNER JOIN EPagHistValorReferencia HVR
              ON VRV.CdValorReferenciaVersao = HVR.CdValorReferenciaVersao
     WHERE VR.CdAgrupamento = 1
       AND VRV.NuVersao = pFolha.NuVersaoTabValorReferencia
       AND (HVR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
            (HVR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
             HVR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
             (HVR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
              (HVR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
               HVR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
               HVR.NuAnoFimVigencia IS NULL)
       AND Vr.Sgvalorreferencia = 'VLDCI';

     exception
       when no_data_found then
         pkgpag_var.vgValorReferenciaVLDCI := 0;
       when others then
         pkgpag_var.vgValorReferenciaVLDCI := 0;

   end;

    pkgpag_var.vgVlRefRetroObito := 0;
    -- Valor limite retroativo para servidores com OBITO
    begin
    SELECT HVR.VlReferencia
      INTO pkgpag_var.vgVlRefRetroObito
      FROM EPagValorReferencia VR
      INNER JOIN EPagValorReferenciaVersao VRV
              ON VR.CdValorReferencia = VRV.CdValorReferencia
      INNER JOIN EPagHistValorReferencia HVR
              ON VRV.CdValorReferenciaVersao = HVR.CdValorReferenciaVersao
     WHERE VR.CdAgrupamento = 1
       AND VRV.NuVersao = pFolha.NuVersaoTabValorReferencia
       AND (HVR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
            (HVR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
             HVR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
             (HVR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
              (HVR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
               HVR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
               HVR.NuAnoFimVigencia IS NULL)
       AND Vr.Sgvalorreferencia = 'RETROOBIT';

     exception
       when no_data_found then
         pkgpag_var.vgVlRefRetroObito := 0;
       when others then
         pkgpag_var.vgVlRefRetroObito := 0;

   end;

  RETURN tValRef;

END;

/*----------------------------------------------------------------------------------------/*
    Funcao: FRetornaParametroRubrica
  Objetivo: Retorna os parametros da rubrica.

      Nota: Busca inicialmente se existe parametrizacao de rubrica no Orgao. Caso
            nao encontre, retorna a parametrizacao da rubrica no agrupamento. A
            aplicacao deve garantir que exista pelo menos a parametrizacao no
            agrupamento.

/*-----------------------------------------------------------------------------------------*/

FUNCTION FRetornaParametroRubrica (pNuAnoReferencia    IN INTEGER,
                                   pNuMesReferencia    IN INTEGER,
                                   pRubrica            IN PKGPAG_TIPO.rRubrica)
  RETURN PKGPAG_TIPO.rRubrica IS

  vCdHistRubricaAgrupamento INTEGER;

  i                         INTEGER;

  VRubrica                  PKGPAG_TIPO.rRubrica;

BEGIN
 
  vRubrica := pRubrica;

   -- Lista de naturezas de vinculo permitidas
   FOR vHNV IN (SELECT HNV.CdNaturezaVinculo
                  FROM EpagHistRubricaAgrupNatVinc HNV
                 WHERE HNV.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsNatVinc(vHNV.CdNaturezaVinculo) := vHNV.CdNaturezaVinculo;

   END LOOP;

   -- Lista de regimes previdenciarios permitidos
   FOR vHRP IN (SELECT HRP.CdRegimePrevidenciario
                  FROM EpagHistRubricaAgrupRegPrev HRP
                 WHERE HRP.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsRegPrev(vHRP.CdRegimePrevidenciario) := vHRP.CdRegimePrevidenciario;

   END LOOP;

   -- Lista de regimes de trabalhos permitidos
   FOR vHRT IN (SELECT HRT.CdRegimeTrabalho
                  FROM EpagHistRubricaAgrupRegTrab HRT
                 WHERE HRT.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsRegTrab(vHRT.CdRegimeTrabalho) := vHRT.CdRegimeTrabalho;

   END LOOP;

   -- Lista de situacoes previdenciarias permitidas
   FOR vHST IN (SELECT HST.CdSituacaoPrevidenciaria
                  FROM EpagHistRubricaAgrupSitPrev HST
                 WHERE HST.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsSitPrev(vHST.CdSituacaoPrevidenciaria) := vHST.CdSituacaoPrevidenciaria;

   END LOOP;

   -- Lista de relacoes de trabalho permitidas
   FOR vHRT IN (SELECT HRT.CdRelacaoTrabalho
                  FROM EpagHistRubricaAgrupRelTrab HRT
                 WHERE HRT.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsRelTrab(vHRT.CdRelacaoTrabalho) := vHRT.CdRelacaoTrabalho;

   END LOOP;

   -- Lista de funcoes de chefia
   FOR vFUC IN (SELECT HFC.CdFuncaoChefia
                  FROM EpagHistRubricaAgrupFUC HFC
                 WHERE HFC.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsFUC(vFUC.CdFuncaoChefia) := vFUC.CdFuncaoChefia;

   END LOOP;

    -- Lista de funcoes de cargos comissionados
   FOR vCCO IN (SELECT CCO.CdCargoComissionado,
                       CCO.CdGrupoOcupacional
                  FROM EPagHistRubricaAgrupCCO CCO
                 WHERE CCO.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     IF vCCO.CdCargoComissionado IS NOT NULL THEN

       vRubrica.lsCCO(vCCO.CdCargoComissionado) := vCCO.CdCargoComissionado;

     END IF;

     IF vCCO.CdGrupoOcupacional IS NOT NULL THEN

       IF NOT vRubrica.lsGrupoOcupacional.EXISTS(vCCO.CdGrupoOcupacional) THEN

         vRubrica.lsGrupoOcupacional(vCCO.CdGrupoOcupacional) := vCCO.CdGrupoOcupacional;

       END IF;

     END IF;

   END LOOP;

   -- Lista de carreiras
   -- Obs: Verificar se e mais performatico realizar o "connect  by" e trazer toda a
   --      estrutura neste ponto
   FOR vCarreira IN (SELECT C.CdEstruturaCarreira
                       FROM EPagHistRubricaAgrupCarreira C
                      WHERE C.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsCarreira(vCarreira.CdEstruturaCarreira) := vCarreira.CdEstruturaCarreira;

   END LOOP;

   -- Lista de UO

   FOR vUO IN (SELECT UO.CdUnidadeOrganizacional, UO.FlSubordinadas
                 FROM EPagHistRubricaAgrupUO UO
                WHERE UO.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     IF vUO.FlSubordinadas = PKGPAG_TIPO.cnS THEN

       FOR vSubUO IN (SELECT CdUnidadeOrganizacional
                        FROM ECadHistunidadeOrganizacional HO
                     /*  WHERE HO.dtiniciovigencia <= pdtInicioMes AND (HO.Dtfimvigencia >= pdtInicioMes OR HO.DtFimVigencia Is NULL)*/
                     CONNECT BY PRIOR HO.CdUnidadeOrganizacional = HO.CdUOSupHierarq
                       START WITH HO.CdUnidadeOrganizacional = vUO.CdUnidadeOrganizacional)
       LOOP

         vRubrica.lsUO(vSubUO.CdUnidadeOrganizacional) := vSubUO.CdUnidadeOrganizacional;

       END LOOP;

     ELSE

       vRubrica.lsUO(vUO.CdUnidadeOrganizacional) := vUO.CdUnidadeOrganizacional;

     END IF;

   END LOOP;

   -- Lista de Motivos de Movimentacao
   -- Observacao: No valor da lista grava o valor do outro campo
   -- Ex: Na lista lsMotivoMov na posicao do CdMotivoMovimentacao,
   -- grava o valor do campo CdInstitutoMovimentacao

   i := 0;

   FOR vMot IN (SELECT MM.CdMotivoMovimentacao,
                       MM.CdInstitutoMovimentacao
                 FROM EPagHistRubricaAgrupMotMovi MM
                WHERE MM.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     i := i + 1;

     vRubrica.lsMovInstituto(i) := vMot;

   END LOOP;

   --
   -- Lista de Motivos de Afastamentos Exigidos para a geracao da rubrica
   --

   i := 0;

   FOR vMAF IN (SELECT MAF.CDHISTRUBRICAAGRUPAMENTO,
                       MAF.CDMOTIVOAFASTTEMPORARIO,
                       MAF.NUPERIODO,
                       MAF.Cdperiodoafastamento
                  FROM EPAGRUBAGRUPMOTAFASTTEMPEX MAF
                 WHERE MAF.CDHISTRUBRICAAGRUPAMENTO = vRubrica.CdHistRubrica)

   LOOP

     i := i + 1;

     vRubrica.lsMotAfastTempEx(i) := vMAF;

   END LOOP;

   --
   -- Lista de Motivos de Afastamentos Impeditivos para a gerac?o da rubrica
   --

   i := 0;

   FOR vMAFI IN (SELECT MAFI.CDHISTRUBRICAAGRUPAMENTO,
                        MAFI.CDMOTIVOAFASTTEMPORARIO
                   FROM EPAGRUBAGRUPMOTAFASTTEMPIMP MAFI
                  WHERE MAFI.CDHISTRUBRICAAGRUPAMENTO = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsMotAfastTempImp(vMAFI.CDMOTIVOAFASTTEMPORARIO) := vMAFI.CDMOTIVOAFASTTEMPORARIO;

   END LOOP;

   -- Lista de programas

   FOR vProg IN (SELECT P.CdPrograma
                 FROM EPagHistRubricaAgrupPrograma P
                WHERE P.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     vRubrica.lsPrograma(vProg.CdPrograma) := vProg.CdPrograma;

   END LOOP;

   -- Busca informacoes que estao disponiveis nas parametrizacoes do agrupamento

   IF vRubrica.CdOrgao IS NOT NULL THEN

     -- Caso a parametrizacao seja por orgao, busca as informacoes no
     -- historico da rubrica no agrupamento

     SELECT RA.FlEmpenhadaFilial,
            RA.FlIncorporacao,
            RA.FlPensaoAlimenticia,
            RA.FlTributacao,
            RA.FlConsignacao,
            HRA.CdHistRubricaAgrupamento,
            HRA.FlAplicaRubricaOrgaos
       INTO vRubrica.FlEmpenhadaFilial,
            vRubrica.FlIncorporacao,
            vRubrica.FlPensaoAlimenticia,
            vRubrica.FlTributacao,
            vRubrica.FlConsignacao,
            vCdHistRubricaAgrupamento,
            vRubrica.FlAplicaRubricaOrgaos
       FROM EpagHistRubricaAgrupamento HRA
      INNER JOIN EPagRubricaAgrupamento RA
         ON HRA.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
      WHERE HRA.CdRubricaAgrupamento = vRubrica.CdRubricaAgrupamento AND
            RA.CdOrgao IS NULL AND
            ((HRA.NuAnoInicioVigencia < pNuAnoReferencia OR
            (HRA.NuanoInicioVigencia = pNuAnoReferencia AND
             HRA.NumesInicioVigencia <= pNuMesReferencia))
            AND
            (HRA.NuAnoFimVigencia > pNuAnoReferencia OR
            (HRA.NuAnoFimVigencia = pNuAnoReferencia AND
             HRA.NuMesFimVigencia >= pNuMesReferencia) OR
             HRA.NuAnoFimVigencia IS NULL));

   ELSE

     vCdHistRubricaAgrupamento := vRubrica.CdHistRubrica;

   END IF;

   -- Lista dos orgaos permitidos.
   IF vRubrica.FlAplicaRubricaOrgaos = 'N' THEN

     FOR vOrgao IN (SELECT RO.CdOrgao,
                           RO.InLotadoExercicio
                      FROM EPagHistRubricaAgrupOrgao RO
                     WHERE RO.CdHistRubricaAgrupamento = vCdHistRubricaAgrupamento)

     LOOP

       vRubrica.lsOrgao(vOrgao.CdOrgao) := vOrgao;

     END LOOP;

   END IF;

   -- Lista de rubricas exigidas para o recebimento desta

   FOR vRubExigida IN (SELECT CdRubricaAgrupamento
                         FROM Epaghistrubricaagrupexigida RE
                        WHERE RE.CdHistRubricaAgrupamento =  vRubrica.CdHistRubrica)
   LOOP

     vRubrica.lsRubExigida(vRubExigida.CdRubricaAgrupamento) := vRubExigida.CdRubricaAgrupamento;

   END LOOP;

   -- Lista de rubricas que impedem o recebimento desta

   FOR vRubImpeditiva IN (SELECT CdRubricaAgrupamento
                            FROM EPaghistrubricaagrupimpeditiva RI
                           WHERE RI.CdHistRubricaAgrupamento =  vRubrica.CdHistRubrica)
   LOOP

     vRubrica.lsRubImpeditiva( vRubImpeditiva.CdRubricaAgrupamento) :=  vRubImpeditiva.CdRubricaAgrupamento;

   END LOOP;

    -- Lista de UO e respectivas Cargas Horarias
    -- Utilizado para a saude

   FOR vUO IN (SELECT UO.CdUnidadeOrganizacional,
                      UO.FlSubordinadas,
                      UO.NuCargaHoraria
                 FROM EPagHistRubAgrupLocCHO UO
                WHERE UO.CdHistRubricaAgrupamento = vRubrica.CdHistRubrica)

   LOOP

     IF vUO.FlSubordinadas = PKGPAG_TIPO.cnS THEN

       FOR vSubUO IN (SELECT CdUnidadeOrganizacional
                        FROM ECadHistunidadeOrganizacional HO
                     CONNECT BY PRIOR HO.CdUnidadeOrganizacional = HO.CdUOSupHierarq
                       START WITH HO.CdUnidadeOrganizacional = vUO.CdUnidadeOrganizacional)
       LOOP

         vRubrica.lsLocCHO(vSubUO.CdUnidadeOrganizacional) := vUO.NuCargaHoraria;

       END LOOP;

     ELSE

       vRubrica.lsLocCHO(vUO.CdUnidadeOrganizacional) := vUO.NuCargaHoraria;

     END IF;

   END LOOP;

   -- Lista de modelos de aposentadoria permitidas
   FOR vHMA IN (SELECT HMA.Cdmodeloaposentadoria
                  FROM Epaghistrubricaagrupmodeloapo HMA
                 WHERE  HMA.Cdhistrubricaagrupamento = vRubrica.Cdhistrubrica)

   LOOP

     vRubrica.lsModeloApo(vHMA.Cdmodeloaposentadoria) := vHMA.Cdmodeloaposentadoria;

   END LOOP;

   -- Lista de motivos de convocacao
   FOR vHMC IN (SELECT HMC.Cdmotivoconvocacao
                  FROM EPAGHISTRUBRICAAGRUPMOTCONV HMC
                 WHERE HMC.Cdhistrubricaagrupamento = vRubrica.Cdhistrubrica)

   LOOP

     vRubrica.lsMotivoConvocacao(vHMC.Cdmotivoconvocacao) := vHMC.Cdmotivoconvocacao;

   END LOOP;

  RETURN vRubrica;

END;

FUNCTION FArmazenaParametrosRubrica (pFolha IN PKGPAG_TIPO.rFolha)
  RETURN PKGPAG_TIPO.tRubrica IS

  vTabRubrica                PKGPAG_TIPO.tRubrica;
  vRegRubrica                PKGPAG_TIPO.rRubrica;
  vRegRubricaParam           PKGPAG_TIPO.rRubrica;
  vCdRubricaAgrupamentoParam INTEGER;

  CURSOR cRubAgrup IS
              SELECT RA.CdRubricaAgrupamento,
                     R.CdTipoRubrica,
                     RAP.CdRubricaAgrupamento as CdRubricaAgrupamentoParam,
                     R.NuRubrica,
                     HR.CdBaseCalculo,
                     HR.CdOrgao,
                     HR.CdHistRubricaAgrupamento,
                     HR.FlEmpenhadaFilial,
                     HR.FlIncorporacao,
                     HR.FlPensaoAlimenticia,
                     HR.FlTributacao,
                     HR.FlConsignacao,
                     HR.FlPermiteAfastAcidente,
                     HR.FlBloqLancFinanc,
                     HR.InLancPropRelVinc,
                     HR.InPossuiValorInformado,
                     HR.CdRelacaoTrabalho,
                     HR.CdRubProporcionalidadeCHO,
                     HR.FlCargaHorariaPadrao,
                     HR.NuCargaHorariaSemanal,
                     HR.NuMesesApuracao,
                     HR.FlPropMesComercial,
                     HR.FlPropAposParidade,
                     HR.FlPropServRelVinc,
                     HR.FlPropAfastTempNaoRemun,
                     HR.InImpedimentoRubrica,
                     HR.InRubricasExigidas,
                     HR.CdModalidadeRubrica,
                     HR.InGeraRubricaCarreira,
                     HR.InGeraRubricaFUC,
                     HR.InGeraRubricaCCO,
                     HR.InGeraRubricaUO,
                     HR.InGeraRubricaAfastTemp,
                     HR.FlAplicaRubricaOrgaos,
                     HR.FlPermiteAPOOriginadoCCO,
                     HR.FlPermiteFGFTG,
                     HR.FlPagaSubstituicao,
                     HR.FlPagaRespondendo,
                     HR.FlConsolidaRubrica,
                     HR.FlPropAfaFgFtg,
                     HR.FlCargaHorariaLimitada,
                     HR.FlPropAfaComissionado,
                     HR.FlPropAfaComOpcPercCEF,
                     HR.FlPreservaValorIntegral,
                     HR.FlPagaApoSemParidade,
                     HR.InGeraRubricaMotMovi,
                     HR.FlPercentLimitado100,
                     HR.InGeraRubricaPrograma,
                     HR.FlPropAfaCCOSubst,
                     HR.FlImpedeIdadeCompulsoria,
                     HR.FlGeraRubricaCarreiraIncideCCO,
                     HR.FlGeraRubricaCarreiraIncideAPO,
                     HR.FlGeraRubricaCCOIncideCEF,
                     HR.FlGeraRubricaFUCIncideCEF,
                     HR.FlSuspensa,
                     HR.FlPercentReducaoAfastRemun,
                     HR.FlPagaMaiorRV,
                     HR.CdTipoIndice,
                     HR.FLPagaEfetivoOrgao,
                     HR.flignoraafastcefagpolitico,
                     HR.flRubAntecipSal

                FROM EPagRubricaAgrupamento RAP
               INNER JOIN EPagRubrica RP
                  ON RP.CdRubrica = RAP.CdRubrica
               INNER JOIN EPagRubrica R
                  ON R.NuRubrica = RP.NuRubrica
                  AND RP.CdTipoRubrica = CASE
                                           WHEN R.CdTipoRubrica IN (1,2,3,8,10,12) THEN
                                               1
                                           WHEN R.CdTipoRubrica IN (4,5,6,7,11,13) THEN
                                               5
                                           WHEN R.CdTipoRubrica = 9 THEN
                                               9
                                         END
               INNER JOIN EPagRubricaAgrupamento RA
                  ON R.CdRubrica = RA.CdRubrica
                 AND RA.CdAgrupamento = RAP.CdAgrupamento

               LEFT JOIN ( SELECT
                               ROW_NUMBER() OVER ( PARTITION BY nvl(RI.cdRubricaAgrupamentoOrigem,RI.CdRubricaAgrupamento) ORDER BY CDORGAO) as Ordem,
                               NVL(RI.CdRubricaAgrupamentoOrigem, RI.CdRubricaAgrupamento) CdRubricaAgrupamento,
                               RI.CdOrgao,
                               HRA.CdHistRubricaAgrupamento,
                               RI.CdBaseCalculo,
                               RI.FlEmpenhadaFilial,
                               RI.FlIncorporacao,
                               RI.FlPensaoAlimenticia,
                               RI.FlTributacao,
                               RI.FlConsignacao,
                               HRA.FlPermiteAfastAcidente,
                               HRA.FlBloqLancFinanc,
                               HRA.InLancPropRelVinc,
                               HRA.InPossuiValorInformado,
                               HRA.CdRelacaoTrabalho,
                               HRA.CdRubProporcionalidadeCHO,
                               HRA.FlCargaHorariaPadrao,
                               HRA.NuCargaHorariaSemanal,
                               HRA.NuMesesApuracao,
                               HRA.FlPropMesComercial,
                               HRA.FlPropAposParidade,
                               HRA.FlPropServRelVinc,
                               HRA.FlPropAfastTempNaoRemun,
                               HRA.InImpedimentoRubrica,
                               HRA.InRubricasExigidas,
                               RI.CdModalidadeRubrica,
                               HRA.InGeraRubricaCarreira,
                               HRA.InGeraRubricaFUC,
                               HRA.InGeraRubricaCCO,
                               HRA.InGeraRubricaUO,
                               HRA.InGeraRubricaAfastTemp,
                               HRA.FlAplicaRubricaOrgaos,
                               HRA.FlPermiteAPOOriginadoCCO,
                               HRA.FlPermiteFGFTG,
                               HRA.FlPagaSubstituicao,
                               HRA.FlPagaRespondendo,
                               HRA.FlConsolidaRubrica,
                               HRA.FlPropAfaFgFtg,
                               HRA.FlCargaHorariaLimitada,
                               HRA.FlPropAfaComissionado,
                               HRA.FlPropAfaComOpcPercCEF,
                               HRA.FlPreservaValorIntegral,
                               HRA.FlPagaApoSemParidade,
                               HRA.InGeraRubricaMotMovi,
                               HRA.FlPercentLimitado100,
                               HRA.InGeraRubricaPrograma,
                               HRA.FlPropAfaCCOSubst,
                               HRA.FlImpedeIdadeCompulsoria,
                               HRA.FlGeraRubricaCarreiraIncideCCO,
                               HRA.FlGeraRubricaCarreiraIncideAPO,
                               HRA.FlGeraRubricaCCOIncideCEF,
                               HRA.FlGeraRubricaFUCIncideCEF,
                               HRA.FlSuspensa,
                               HRA.FlPercentReducaoAfastRemun,
                               HRA.FlPagaMaiorRV,
                               HRA.CdTipoIndice,
                               HRA.FLPagaEfetivoOrgao,
                               hra.flignoraafastcefagpolitico,
                               RI.flRubAntecipSal
                            FROM Epagrubricaagrupamento RI

                            INNER JOIN EPagHistRubricaAgrupamento HRA
                              ON RI.CdRubricaAgrupamento = HRA.CdRubricaAgrupamento

                             AND (HRA.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                                 (HRA.NuanoInicioVigencia = pFolha.NuAnoReferencia AND
                                 HRA.NumesInicioVigencia <= pFolha.NuMesReferencia))
                             AND (HRA.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                                 (HRA.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                                 HRA.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                                 HRA.NuAnoFimVigencia IS NULL)

                            WHERE ( RI.CdOrgao = pFolha.CdOrgao
                                 OR RI.cdAgrupamento = pFolha.CdAgrupamento)

                          ) HR
                  ON HR.CdRubricaAgrupamento = RAP.CdRubricaAgrupamento
                  AND HR.Ordem = 1

               WHERE RAP.CdAgrupamento = pFolha.CdAgrupamento
               ORDER BY RAP.CdRubricaAgrupamento;

 TYPE tTabRubAgrup IS TABLE OF cRubAgrup%ROWTYPE;

 vTabRubAgrup  tTabRubAgrup;

BEGIN
 
  -- Carrega cursor de rubricas

  OPEN cRubAgrup;

  FETCH cRubAgrup BULK COLLECT INTO vTabRubAgrup;

  CLOSE cRubAgrup;

  -- Percorre tabela armazenada

  vCdRubricaAgrupamentoParam := 0;

  IF vTabRubAgrup.FIRST IS NULL THEN
     RETURN vTabRubrica;
  END IF;

  FOR i IN vTabRubAgrup.FIRST .. vTabRubAgrup.LAST

  LOOP

     vRegRubrica := NULL;
     -- Preenche dados parciais da rubrica

     vRegRubrica.CdRubricaAgrupamento           := vTabRubAgrup(i).CdRubricaAgrupamento;
     vRegRubrica.CdTipoRubrica                  := vTabRubAgrup(i).CdTipoRubrica;
     vRegRubrica.NuRubrica                      := vTabRubAgrup(i).NuRubrica;
     vRegRubrica.CdBaseCalculo                  := vTabRubAgrup(i).CdBaseCalculo;
     vRegRubrica.CdOrgao                        := vTabRubAgrup(i).CdOrgao;
     vRegRubrica.CdHistRubrica                  := vTabRubAgrup(i).CdHistRubricaAgrupamento;
     vRegRubrica.FlEmpenhadaFilial              := vTabRubAgrup(i).FlEmpenhadaFilial;
     vRegRubrica.FlIncorporacao                 := vTabRubAgrup(i).FlIncorporacao;
     vRegRubrica.FlPensaoAlimenticia            := vTabRubAgrup(i).FlPensaoAlimenticia;
     vRegRubrica.FlTributacao                   := vTabRubAgrup(i).FlTributacao;
     vRegRubrica.FlConsignacao                  := vTabRubAgrup(i).FlConsignacao;
     vRegRubrica.FlPermiteAfastAcidente         := vTabRubAgrup(i).FlPermiteAfastAcidente;
     vRegRubrica.FlBloqLancFinanc               := vTabRubAgrup(i).FlBloqLancFinanc;
     vRegRubrica.InLancPropRelVinc              := vTabRubAgrup(i).InLancPropRelVinc;
     vRegRubrica.InPossuiValorInformado         := vTabRubAgrup(i).InPossuiValorInformado;
     vRegRubrica.CdRelacaoTrabalho              := vTabRubAgrup(i).CdRelacaoTrabalho;
     vRegRubrica.CdRubProporcionalidadeCHO      := vTabRubAgrup(i).CdRubProporcionalidadeCHO;
     vRegRubrica.FlCargaHorariaPadrao           := vTabRubAgrup(i).FlCargaHorariaPadrao;
     vRegRubrica.NuCargaHorariaSemanal          := vTabRubAgrup(i).NuCargaHorariaSemanal;
     vRegRubrica.NuMesesApuracao                := vTabRubAgrup(i).NuMesesApuracao;
     vRegRubrica.FlPropMesComercial             := vTabRubAgrup(i).FlPropMesComercial;
     vRegRubrica.FlPropAposParidade              := vTabRubAgrup(i).FlPropAposParidade;
     vRegRubrica.FlPropServRelVinc               := vTabRubAgrup(i).FlPropServRelVinc;
     vRegRubrica.FlPropAfastTempNaoRemun         := vTabRubAgrup(i).FlPropAfastTempNaoRemun;
     vRegRubrica.InImpedimentoRubrica            := vTabRubAgrup(i).InImpedimentoRubrica;
     vRegRubrica.InRubricasExigidas              := vTabRubAgrup(i).InRubricasExigidas;
     vRegRubrica.CdModalidadeRubrica             := vTabRubAgrup(i).CdModalidadeRubrica;
     vRegRubrica.InGeraRubricaCarreira           := vTabRubAgrup(i).InGeraRubricaCarreira;
     vRegRubrica.InGeraRubricaFUC                := vTabRubAgrup(i).InGeraRubricaFUC;
     vRegRubrica.InGeraRubricaCCO                := vTabRubAgrup(i).InGeraRubricaCCO;
     vRegRubrica.InGeraRubricaUO                 := vTabRubAgrup(i).InGeraRubricaUO;
     vRegRubrica.InGeraRubricaAfastTemp          := vTabRubAgrup(i).InGeraRubricaAfastTemp;
     vRegRubrica.FlAplicaRubricaOrgaos           := vTabRubAgrup(i).FlAplicaRubricaOrgaos;
     vRegRubrica.FlPermiteAPOOriginadoCCO        := vTabRubAgrup(i).FlPermiteAPOOriginadoCCO;
     vRegRubrica.FlPermiteFGFTG                  := vTabRubAgrup(i).FlPermiteFGFTG;
     vRegRubrica.FlPagaSubstituicao              := vTabRubAgrup(i).FlPagaSubstituicao;
     vRegRubrica.FlPagaRespondendo               := vTabRubAgrup(i).FlPagaRespondendo;
     vRegRubrica.FlConsolidaRubrica              := vTabRubAgrup(i).FlConsolidaRubrica;
     vRegRubrica.FlPropAfaFgFtg                  := vTabRubAgrup(i).FlPropAfaFgFtg;
     vRegRubrica.FlCargaHorariaLimitada          := vTabRubAgrup(i).FlCargaHorariaLimitada;
     vRegRubrica.FlPropAfaComissionado           := vTabRubAgrup(i).FlPropAfaComissionado;
     vRegRubrica.FlPropAfaComOpcPercCEF          := vTabRubAgrup(i).FlPropAfaComOpcPercCEF;
     vRegRubrica.FlPreservaValorIntegral         := vTabRubAgrup(i).FlPreservaValorIntegral;
     vRegRubrica.FlPagaApoSemParidade            := vTabRubAgrup(i).FlPagaApoSemParidade;
     vRegRubrica.InGeraRubricaMotMovi            := vTabRubAgrup(i).InGeraRubricaMotMovi;
     vRegRubrica.FlPercentLimitado100            := vTabRubAgrup(i).FlPercentLimitado100;
     vRegRubrica.InGeraRubricaPrograma           := vTabRubAgrup(i).InGeraRubricaPrograma;
     vRegRubrica.FlPropAfaCCOSubst               := vTabRubAgrup(i).FlPropAfaCCOSubst;
     vRegRubrica.FlImpedeIdadeCompulsoria        := vTabRubAgrup(i).FlImpedeIdadeCompulsoria;
     vRegRubrica.FlGeraRubricaCarreiraIncideCCO  := vTabRubAgrup(i).FlGeraRubricaCarreiraIncideCCO;
     vRegRubrica.FlGeraRubricaCarreiraIncideAPO  := vTabRubAgrup(i).FlGeraRubricaCarreiraIncideAPO;
     vRegRubrica.FlGeraRubricaCCOIncideCEF       := vTabRubAgrup(i).FlGeraRubricaCCOIncideCEF;
     vRegRubrica.FlGeraRubricaFUCIncideCEF       := vTabRubAgrup(i).FlGeraRubricaFUCIncideCEF;
     vRegRubrica.FlSuspensa                      := vTabRubAgrup(i).FlSuspensa;
     vRegRubrica.FlPercentReducaoAfastRemun      := vTabRubAgrup(i).FlPercentReducaoAfastRemun;
     vRegRubrica.FlPagaMaiorRV                   := vTabRubAgrup(i).FlPagaMaiorRV;
     vRegRubrica.CdTipoIndice                    := vTabRubAgrup(i).CdTipoIndice;
     vRegRubrica.FLPagaEfetivoOrgao              := vTabRubAgrup(i).FLPagaEfetivoOrgao;
     vRegRubrica.FLIGNORAAFASTCEFAGPOLITICO      := vTabRubAgrup(i).FLIGNORAAFASTCEFAGPOLITICO;
     vRegRubrica.flRubAntecipSal                 := vTabRubAgrup(i).flRubAntecipSal;
     
     -- Preenche restante dos dados da rubrica

     IF vCdRubricaAgrupamentoParam <> vTabRubAgrup(i).CdRubricaAgrupamentoParam THEN
        vRegRubrica := FRetornaParametroRubrica (pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                 pNuMesReferencia => pFolha.NuMesReferencia,
                                                 pRubrica         => vRegRubrica);

        vRegRubricaParam := vRegRubrica;

        vCdRubricaAgrupamentoParam := vTabRubAgrup(i).CdRubricaAgrupamentoParam;

     ELSE

        vRegRubrica.lsNatVinc             := vRegRubricaParam.lsNatVinc;
        vRegRubrica.lsRegPrev             := vRegRubricaParam.lsRegPrev;
        vRegRubrica.lsRegTrab             := vRegRubricaParam.lsRegTrab;
        vRegRubrica.lsSitPrev             := vRegRubricaParam.lsSitPrev;
        vRegRubrica.lsRelTrab             := vRegRubricaParam.lsRelTrab;
        vRegRubrica.lsFUC                 := vRegRubricaParam.lsFUC;
        vRegRubrica.lsCCO                 := vRegRubricaParam.lsCCO;
        vRegRubrica.lsGrupoOcupacional    := vRegRubricaParam.lsGrupoOcupacional;
        vRegRubrica.lsCarreira            := vRegRubricaParam.lsCarreira;
        vRegRubrica.lsUO                  := vRegRubricaParam.lsUO;
        vRegRubrica.lsMovInstituto        := vRegRubricaParam.lsMovInstituto;
        vRegRubrica.lsPrograma            := vRegRubricaParam.lsPrograma;
        vRegRubrica.FlEmpenhadaFilial     := vRegRubricaParam.FlEmpenhadaFilial;
        vRegRubrica.FlIncorporacao        := vRegRubricaParam.FlIncorporacao;
        vRegRubrica.FlPensaoAlimenticia   := vRegRubricaParam.FlPensaoAlimenticia;
        vRegRubrica.FlTributacao          := vRegRubricaParam.FlTributacao;
        vRegRubrica.FlConsignacao         := vRegRubricaParam.FlConsignacao;
        vRegRubrica.FlAplicaRubricaOrgaos := vRegRubricaParam.FlAplicaRubricaOrgaos;
        vRegRubrica.lsOrgao               := vRegRubricaParam.lsOrgao;
        vRegRubrica.lsRubExigida          := vRegRubricaParam.lsRubExigida;
        vRegRubrica.lsRubImpeditiva       := vRegRubricaParam.lsRubImpeditiva;
        vRegRubrica.lsLocCHO              := vRegRubricaParam.lsLocCHO;
        vRegRubrica.lsMotAfastTempEx      := vRegRubricaParam.lsMotAfastTempEx;
        vRegRubrica.lsMotAfastTempImp     := vRegRubricaParam.lsMotAfastTempImp;
        vRegRubrica.lsModeloApo           := vRegRubricaParam.lsModeloApo;
        vRegRubrica.lsMotivoConvocacao    := vRegRubricaParam.lsMotivoConvocacao;


     END IF;

     vTabRubrica(vTabRubAgrup(i).CdRubricaAgrupamento) := vRegRubrica;

  END LOOP;

  RETURN vTabRubrica;

END;

FUNCTION FArmazenaParametroAuxAli(pCdAgrupamento IN INTEGER,
                                  pDtCalculo     IN DATE)

  RETURN PKGPAG_TIPO.tAuxilioAli IS

  vAuxilioAli PKGPAG_TIPO.tAuxilioAli;

  FUNCTION FVerificaVinculo(pCdOrgao IN INTEGER,
                            pCdParametroOrgao IN INTEGER)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vCont
      FROM EAliVinculoSemAuxilio VS
     INNER JOIN ECadVinculo V
        ON VS.CdVinculo = V.CdVinculo
     WHERE V.CdOrgao = pCdOrgao AND
           VS.CdParametroOrgao = pCdParametroOrgao AND
           ROWNUM < 2;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

         RETURN FALSE;

  END;

  FUNCTION FVerificaUO(pCdOrgao          IN INTEGER,
                       pCdParametroOrgao IN INTEGER)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vCont
      FROM EAliUOSemAuxilio US
     INNER JOIN ECadUnidadeOrganizacional UO
        ON US.CdUnidadeOrganizacional = UO.CdUnidadeOrganizacional
     WHERE UO.CdOrgao = pCdOrgao AND
           US.CdParametroOrgao = pCdParametroOrgao AND
           ROWNUM < 2;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

       RETURN FALSE;

  END;

  FUNCTION FVerificaCarreira(pCdParametroOrgao IN INTEGER)

    RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
 
    SELECT 1
      INTO vCont
      FROM EAliCarreiraSemAuxilio CS
     WHERE CS.CdParametroOrgao = pCdParametroOrgao AND
           ROWNUM < 2;

    IF vCont > 0 THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

         RETURN FALSE;

  END;

BEGIN
 
  FOR vParamAli IN (SELECT PO.CdParametroOrgao,
                           PO.CdOrgao,
                           PO.FlPecunia,
                           PO.NuDiaInicioApuracao,
                           PO.NuDias,
                           PO.NuDiasLimite,
                           PO.FlDescontaFeriado,
                           PO.FlDescontaPontoFacul,
                           PO.FlDescontaPontoFaculComp,
                           PO.FlDescontaFalta,
                           PO.CdOperacaoAbatimento,
                           PO.InCompetenciaApuracaoDias,
                           PO.FlPriorizaCCO
                      FROM EAliParametroOrgao PO
                     INNER JOIN ECadOrgao O
                        ON PO.CdOrgao = O.CdOrgao
                     WHERE O.CdAgrupamento = pCdAgrupamento AND
                          (PO.NuAnoInicio < to_number(TO_CHAR(pDtCalculo, 'YYYY')) OR
                          (PO.NuAnoInicio = to_number(TO_CHAR(pDtCalculo, 'YYYY')) AND
                          PO.NuMesInicio <= to_number(TO_CHAR(pDtCalculo, 'MM')))) AND
                          (PO.NuAnoFim > to_number(TO_CHAR(pDtCalculo, 'YYYY')) OR
                          (PO.NuAnoFim = to_number(TO_CHAR(pDtCalculo, 'YYYY')) AND
                          PO.NuMesFim >= to_number(TO_CHAR(pDtCalculo, 'MM'))) OR
                          PO.NuAnoFim IS NULL))
   LOOP

     vAuxilioAli(vParamAli.CdOrgao).CdParametroOrgao := vParamAli.CdParametroOrgao;

     vAuxilioAli(vParamAli.CdOrgao).FlPecunia                 := vParamAli.FlPecunia;

     vAuxilioAli(vParamAli.CdOrgao).NuDiaInicioApuracao       := vParamAli.NuDiaInicioApuracao;

     vAuxilioAli(vParamAli.CdOrgao).NuDias                    := vParamAli.NuDias;

     vAuxilioAli(vParamAli.CdOrgao).NuDiasLimite              := vParamAli.NuDiasLimite;

     vAuxilioAli(vParamAli.CdOrgao).FlDescontaFeriado         := vParamAli.FlDescontaFeriado;

     vAuxilioAli(vParamAli.CdOrgao).FlDescontaPontoFacul      := vParamAli.FlDescontaPontoFacul;

     vAuxilioAli(vParamAli.CdOrgao).FlDescontaPontoFaculComp  := vParamAli.FlDescontaPontoFaculComp;

     vAuxilioAli(vParamAli.CdOrgao).FlDescontaFalta           := vParamAli.FlDescontaFalta;

     vAuxilioAli(vParamAli.CdOrgao).CdOperacaoAbatimento      := vParamAli.CdOperacaoAbatimento;

     vAuxilioAli(vParamAli.CdOrgao).InCompetenciaApuracaoDias := vParamAli.InCompetenciaApuracaoDias;

     vAuxilioAli(vParamAli.CdOrgao).FlPriorizaCCO             := vParamAli.FlPriorizaCCO;

     -- Opcao de remuneracao sem direito

     FOR vOpcaoRemuneracao IN (SELECT CdOpcaoRemuneracao
                                 FROM EAliOpcaoRemuneracaoSemAuxilio A
                                WHERE A.CdParametroOrgao = vParamAli.CdParametroOrgao)
     LOOP

       vAuxilioAli(vParamAli.CdOrgao).lsOpcaoRemuneracao(vOpcaoRemuneracao.CdOpcaoRemuneracao) := vOpcaoRemuneracao.CdOpcaoRemuneracao;

     END LOOP;

     -- Relacoes de trabalho sem direito

     FOR vRelTrab IN (SELECT ORT.CdRelacaoTrabalho
                        FROM EAliRelTrabSemAuxilio RT
                       INNER JOIN ECadOrgaoRelTrabalho ORT
                          ON ORT.CdOrgaoRelTrabalho = RT.CdOrgaoRelTrabalho
                       WHERE RT.CdParametroOrgao = vParamAli.CdParametroOrgao AND
                             ORT.CdOrgao = vParamAli.CdOrgao)
     LOOP

       vAuxilioAli(vParamAli.CdOrgao).lsRelTrab(vRelTrab.CdRelacaoTrabalho) := vRelTrab.CdRelacaoTrabalho;

     END LOOP;

    -- Situacoes previdenciarias sem direito

     FOR vSitPrev IN (SELECT SP.CdSituacaoPrevidenciaria
                        FROM EAliSitPrevSemAuxilio SP
                       WHERE SP.CdParametroOrgao = vParamAli.CdParametroOrgao)
     LOOP

       vAuxilioAli(vParamAli.CdOrgao).lsSitPrev(vSitPrev.CdSituacaoPrevidenciaria) := vSitPrev.CdSituacaoPrevidenciaria;

     END LOOP;

     -- Indica se existe algum vinculo cadastrado nos parametros do orgao

     vAuxilioAli(vParamAli.CdOrgao).FlVerificaVinculo := FVerificaVinculo(vParamAli.CdOrgao,
                                                                          vParamAli.CdParametroOrgao);

     -- Indica se existe alguma UO cadastrada nos parametros do orgao

     vAuxilioAli(vParamAli.CdOrgao).FlVerificaUO := FVerificaUO(vParamAli.CdOrgao,
                                                                vParamAli.CdParametroOrgao);

     -- Indica se existe alguma carreira cadastradas nos parametros do orgao

     vAuxilioAli(vParamAli.CdOrgao).FlVerificaCarreira := FVerificaCarreira(vParamAli.CdParametroOrgao);

     -- Armazena os valores EAliValorAuxilio

     BEGIN

       SELECT VA.CdValorAuxilio,
              VA.VlAuxilioCEF,
              VA.VlAuxilioCCO,
              VA.CdBaseCalculo,
              RA.CdRubricaAgrupamento
         INTO vAuxilioAli(vParamAli.CdOrgao).CdValorAuxilio,
              vAuxilioAli(vParamAli.CdOrgao).VlAuxilioCEF,
              vAuxilioAli(vParamAli.CdOrgao).VlAuxilioCCO,
              vAuxilioAli(vParamAli.CdOrgao).CdBaseCalculo,
              vAuxilioAli(vParamAli.CdOrgao).CdRubricaAgrupamento
         FROM EAliValorAuxilio VA
        LEFT JOIN EPagBaseCalculo BC
           ON VA.CdBaseCalculo = BC.CdBaseCalculo
        LEFT JOIN EPagRubricaAgrupamento RA
           ON BC.CdBaseCalculo = RA.CdBaseCalculo
        WHERE VA.CdOrgao = vParamAli.CdOrgao AND
              (VA.NuAnoInicio < to_number(TO_CHAR(pDtCalculo, 'YYYY')) OR
              (VA.NuAnoInicio = to_number(TO_CHAR(pDtCalculo, 'YYYY')) AND
              VA.NuMesInicio <= to_number(TO_CHAR(pDtCalculo, 'MM')))) AND
              (VA.NuAnoFim > to_number(TO_CHAR(pDtCalculo, 'YYYY')) OR
              (VA.NuAnoFim = to_number(TO_CHAR(pDtCalculo, 'YYYY')) AND
              VA.NuMesFim >= to_number(TO_CHAR(pDtCalculo, 'MM'))) OR
              VA.NuAnoFim IS NULL);

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

         NULL;

      END;

   END LOOP;

   RETURN vAuxilioAli;

END;

PROCEDURE PArmazenarContribPSAgregado (pAnoRef IN INTEGER, PMesRef IN INTEGER) IS

CURSOR cContribPSAgregado (pAnoRef INTEGER, PMesRef INTEGER) IS
      SELECT
        pa.vlminimo,
        pa.vlmaximo,
        pa.vlagregado
      FROM epagcontribuicaoplanosaude ps
      INNER JOIN epagcontribplanosaudeagregado pa
            ON pa.cdcontribuicaoplanosaude = ps.cdcontribuicaoplanosaude
            WHERE
            ( ps.nuanoiniciovigencia < pAnoRef
              OR ( ps.nuanoiniciovigencia = pAnoRef and ps.numesiniciovigencia <= pMesRef) )
            AND
            ( ps.nuanofimvigencia IS NULL
              OR ps.nuanofimvigencia > pAnoRef
              OR ( ps.nuanofimvigencia = pAnoRef and ps.numesfimvigencia >= pMesRef) );

BEGIN
 
      OPEN cContribPSAgregado (pAnoRef, pMesRef);

      FETCH cContribPSAgregado BULK COLLECT INTO PKGPAG_VAR.vgContribPlanoSaudeAgregado;

      CLOSE cContribPSAgregado;

END;

/*-----------------------------------------------------------------------------------------
    Function: FExprFormulaCalculo

    Objetivo: Retorna as expressoes as formulas de calculo
              associadas as rubricas

  Argumentos: pFolha - registro contendo informacoes da folha que esta sendo processada
              pCdVinculo - codigo do vinculo cuja folha esta sendo calculada

        Nota:
/*-----------------------------------------------------------------------------------------*/

FUNCTION FExprFormulaCalculo(pFolha IN PKGPAG_TIPO.rFolha)
  RETURN PKGPAG_TIPO.tFormulaCalculo IS

  CURSOR cRubFormula IS
    SELECT DISTINCT
          FC.CdRubricaAgrupamento
     FROM EPagFormulaCalculo FC
    INNER JOIN EpagFormulaVersao FCV
       ON FC.CdFormulaCalculo = FCV.CdFormulaCalculo
    INNER JOIN EpagHistFormulaCalculo HFC
       ON FCV.CdFormulaVersao = HFC.CdFormulaVersao
    INNER JOIN EPagHistRubricaAgrupamento HRA
       ON HRA.CdRubricaAgrupamento = FC.CdRubricaAgrupamento
    WHERE FCV.NuFormulaVersao IN (pFolha.NuVersaoFormulaCalculo, PKGPAG_TIPO.cn1) AND
          (FC.CdAgrupamento = pFolha.CdAgrupamento OR
          FC.CdOrgao = pFolha.CdOrgao) AND
          ((HFC.NuAnoInicio < pFolha.NuAnoReferencia OR
          (HFC.NuAnoInicio = pFolha.NuAnoReferencia AND
           HFC.NuMesInicio <= pFolha.NuMesReferencia))
           AND
          (HFC.NuAnoFim > pFolha.NuAnoReferencia OR
          (HFC.NuAnoFim = pFolha.NuAnoReferencia AND
           HFC.NuMesFim >= pFolha.NuMesReferencia) OR
           HFC.NuAnoFim IS NULL)) AND
          ((HRA.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
          (HRA.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
           HRA.NuMesInicioVigencia <= pFolha.NuMesReferencia))
           AND
          (HRA.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
          (HRA.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
           HRA.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
           HRA.NuMesFimVigencia IS NULL));

  CURSOR cFormulaCalculo(pCdRubricaAgrupamento IN INTEGER) IS
    SELECT *
      FROM (SELECT FC.CdRubricaAgrupamento,
                   FC.CdFormulaCalculo,
                   HFC.CdHistFormulaCalculo
              FROM EpagFormulaCalculo FC
             INNER JOIN EpagFormulaVersao FCV
                ON FC.CdFormulaCalculo = FCV.CdFormulaCalculo
             INNER JOIN EPagHistFormulaCalculo HFC
                ON FCV.CdFormulaVersao = HFC.CdFormulaVersao
             WHERE FC.CdRubricaAgrupamento = pCdRubricaAgrupamento AND
                   FCV.NuFormulaVersao IN (pFolha.NuVersaoFormulaCalculo, PKGPAG_TIPO.cn1)  AND
                   ((HFC.NuAnoInicio < pFolha.NuAnoReferencia OR
                   (HFC.NuAnoInicio = pFolha.NuAnoReferencia AND
                   HFC.NuMesInicio <= pFolha.NuMesReferencia))
                   AND
                   (HFC.NuAnoFim > pFolha.NuAnoReferencia OR
                   (HFC.NuAnoFim = pFolha.NuAnoReferencia AND
                   HFC.NuMesFim >= pFolha.NuMesReferencia) OR
                   HFC.NuAnoFim IS NULL)) AND
                  (FC.CdAgrupamento = pFolha.CdAgrupamento OR
                   FC.CdOrgao = pFolha.CdOrgao)
             ORDER BY FCV.NuFormulaVersao DESC, FC.CdOrgao ASC , FC.CdAgrupamento ASC)
      WHERE ROWNUM < 2;

   CURSOR cFormExp(pCdHistFormulaCalculo IN INTEGER) IS
     SELECT EFC.CdExpressaoFormCalc,
            EFC.CdEstruturaCarreira,
            EFC.CdUnidadeOrganizacional,
            EFC.CdCargoComissionado,
            EFC.FlExpGeral,
            EFC.NuFormulaEspecifica,
            EFC.DeFormulaExpressao,
            EFC.FlValorHoraMinuto,
            EFC.CdValorRefLimInfParcial,
            EFC.NuQtDelimInfParcial,
            EFC.CdValorRefLimSupParcial,
            EFC.NuQtDelimiteSupParcial,
            EFC.CdValorRefLimInfFinal,
            EFC.NuQtDelimiteInfFinal,
            EFC.CdValorRefLimSupFinal,
            EFC.NuQtDelimiteSupFinal,
            EFC.VlIndiceLimInferiorMensal,
            EFC.VlIndiceLimSuperiorMensal,
            EFC.VlIndiceLimSuperiorSemestral,
            EFC.VlIndiceLimSuperiorAnual,
            EFC.DeIndiceExpressao,
            EFC.FlDesprezaPropCHORubrica
      FROM EPagExpressaoFormCalc EFC
     WHERE EFC.CdHistFormulaCalculo = pCdHistFormulaCalculo;

   CURSOR cBlocoExpressao(pCdExpressaoFormCalc IN INTEGER) IS
     SELECT FCB.CdFormulaCalculoBloco,
            FCB.SgBloco,
            FCB.FlLimiteParcial
       FROM EpagFormulaCalculoBloco FCB
      WHERE FCB.CdExpressaoFormCalc = pCdExpressaoFormCalc
      ORDER BY LENGTH(FCB.SgBloco),FCB.SgBloco;

   CURSOR cExpressaoCalculo(pCdFormulaCalculoBloco IN INTEGER) IS
     SELECT FCE.CdFormulaCalcBlocoExpressao,
            FCE.CdRubricaAgrupamento,
            TRIM (FCE.DeOperacao) AS DeOperacao,
            FCE.CdTipoMneumonico,
            FCE.InTipoRubrica,
            FCE.InRelacaoRubrica,
            FCE.InMes,
            FCE.CdValorReferencia,
            FCE.CdBaseCalculo,
            FCE.CdTipoAdicionalTempServ,
            FCE.CdValorGeralCEFAgrup,
            FCE.DeNivel,
            FCE.DeCodigoCCO,
            FCE.CdEstruturaCarreira,
            FCE.DeReferencia,
            FCE.CdFuncaoChefia,
            FCE.NuMeses,
            FCE.NuValor,
            FCE.NUMESRUBRICA,
            FCE.Nuanorubrica
       FROM EPagFormulaCalcBlocoExpressao FCE
      WHERE FCE.CdFormulaCalculoBloco = pCdFormulaCalculoBloco
   ORDER BY FCE.CdFormulaCalcBlocoExpressao;

  rFormCalc cFormulaCalculo%ROWTYPE;

  tFormCalc PKGPAG_TIPO.tFormulaCalculo;

  j         INTEGER;

  type tExpressaoFC   IS TABLE OF cExpressaoCalculo%ROWTYPE;

  vTabExpressaoFC     tExpressaoFC;

  vRecExpressaoFC     PKGPAG_TIPO.rExpressao;

  vNuAnoRubrica     INTEGER;
  vNuMesRubrica     INTEGER;

 -----------------------------------------------------------------------------
  -- Seleciona o codigo da folha de recalculo anterior associado ao calculo
  -- definitivo de folha suplementar
  -- Data: 12/04/2010
 -----------------------------------------------------------------------------

  FUNCTION FFolhaRecalculoAnterior(pCdOrgao              IN INTEGER,
                                   pCdTipoFolhaPagamento IN INTEGER,
                                   pTpCalculo            IN INTEGER,
                                   pNuAnoReferencia      IN INTEGER,
                                   pNuMesReferencia      IN INTEGER)
  RETURN INTEGER IS

  vCdFolhaPagamento INTEGER;
  vNuMesReferencia  INTEGER;
  vNuANoReferencia  INTEGER;

BEGIN
 
  IF pNuMesReferencia = 1 THEN

    vNuMesReferencia := 12;

    vNuANoReferencia := pNuAnoReferencia - 1;

  ELSE

    vNuMesReferencia := pNuMesReferencia - 1;

    vNuANoReferencia := pNuAnoReferencia;

  END IF;

  -- Caso haja suplementar definitiva, seleciona o codigo da folha de recalculo.

  SELECT F.CdFolhaVincSupl
    INTO vCdFolhaPagamento
    FROM EPagFolhaPagamento F
    WHERE F.CdOrgao = pCdOrgao AND
          F.CdTipoFolhaPagamento = pCdTipoFolhaPagamento AND
          F.CdTipoCalculo = pTpCalculo AND
          F.FlCalculoDefinitivo = 'S' AND
          F.NuMesReferencia = vNuMesReferencia AND
          F.NuANoReferencia = vNuAnoReferencia AND
          ROWNUM < 2;

  RETURN vCdFolhaPagamento;

EXCEPTION

  WHEN OTHERS THEN

    RETURN 0;

END;

BEGIN
 
  FOR rRubFormula IN cRubFormula

  LOOP

    BEGIN

      OPEN cFormulaCalculo(rRubFormula.CdRubricaAgrupamento);

      FETCH cFormulaCalculo INTO rFormCalc;

      CLOSE cFormulaCalculo;

      FOR rFormExp IN cFormExp(rFormCalc.CdHistFormulaCalculo)
      LOOP

        j := 0;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdRubricaAgrupamento      := rFormCalc.CdRubricaAgrupamento;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdFormulaCalculo          := rFormCalc.CdFormulaCalculo;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdHistFormulaCalculo      := rFormCalc.CdHistFormulaCalculo;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdExpressaoFormCalc       := rFormExp.CdExpressaoFormCalc;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdEstruturaCarreira       := rFormExp.CdEstruturaCarreira;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdUnidadeOrganizacional   := rFormExp.CdUnidadeOrganizacional;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdCargoComissionado       := rFormExp.CdCargoComissionado;

        tFormCalc(rFormExp.CdExpressaoFormCalc).FlExpGeral                := rFormExp.FlExpGeral;

        tFormCalc(rFormExp.CdExpressaoFormCalc).NuFormulaEspecifica       := rFormExp.NuFormulaEspecifica;

        tFormCalc(rFormExp.CdExpressaoFormCalc).DeFormulaExpressao        := FRetiraIgualFormula(rFormExp.DeFormulaExpressao);

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdValorRefLimInfParcial   := rFormExp.CdValorRefLimInfParcial;

        tFormCalc(rFormExp.CdExpressaoFormCalc).NuQtDelimInfParcial       := rFormExp.NuQtDelimInfParcial;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdValorRefLimSupParcial   := rFormExp.CdValorRefLimSupParcial;

        tFormCalc(rFormExp.CdExpressaoFormCalc).NuQtDelimiteSupParcial    := rFormExp.NuQtDelimiteSupParcial;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdValorRefLimInfFinal     := rFormExp.CdValorRefLimInfFinal;

        tFormCalc(rFormExp.CdExpressaoFormCalc).NuQtDelimiteInfFinal      := rFormExp.NuQtDelimiteInfFinal;

        tFormCalc(rFormExp.CdExpressaoFormCalc).CdValorRefLimSupFinal     := rFormExp.CdValorRefLimSupFinal;

        tFormCalc(rFormExp.CdExpressaoFormCalc).NuQtDelimiteSupFinal      := rFormExp.NuQtDelimiteSupFinal;

        tFormCalc(rFormExp.CdExpressaoFormCalc).VlIndiceLimInferiorMensal := rFormExp.VlIndiceLimInferiorMensal;

        tFormCalc(rFormExp.CdExpressaoFormCalc).VlIndiceLimSuperiorMensal := rFormExp.VlIndiceLimSuperiorMensal;

        tFormCalc(rFormExp.CdExpressaoFormCalc).VlIndiceLimSuperiorSemestral := rFormExp.VlIndiceLimSuperiorSemestral;

        tFormCalc(rFormExp.CdExpressaoFormCalc).VlIndiceLimSuperiorAnual := rFormExp.VlIndiceLimSuperiorAnual;

        tFormCalc(rFormExp.CdExpressaoFormCalc).DeIndiceExpressao        := rFormExp.DeIndiceExpressao;

        tFormCalc(rFormExp.CdExpressaoFormCalc).FlDesprezaPropCHORubrica := rFormExp.FlDesprezaPropCHORubrica;

        FOR rBlocExp IN cBlocoExpressao(rFormExp.CdExpressaoFormCalc)

        LOOP

          j := j + 1;

          tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).CdBlocoExpressao := rBlocExp.CdFormulaCalculoBloco;

          tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).SgBloco := rBlocExp.SgBloco;

          tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).FlLimiteParcial := rBlocExp.FlLimiteParcial;

          OPEN cExpressaoCalculo(tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).CdBlocoExpressao);

          FETCH cExpressaoCalculo BULK COLLECT INTO vTabExpressaoFC;

          CLOSE cExpressaoCalculo;

          IF vTabExpressaoFC.FIRST IS NOT NULL THEN
             FOR z in vTabExpressaoFC.FIRST .. vTabExpressaoFC.LAST LOOP

                vRecExpressaoFC.CdExpressao                := vTabExpressaoFC(z).CdFormulaCalcBlocoExpressao;
                vRecExpressaoFC.CdRubricaAgrupamento       := vTabExpressaoFC(z).CdRubricaAgrupamento;
                vRecExpressaoFC.DeOperacao                 := vTabExpressaoFC(z).DeOperacao;
                vRecExpressaoFC.CdTipoMneumonico           := vTabExpressaoFC(z).CdTipoMneumonico;
                vRecExpressaoFC.InTipoRubrica              := vTabExpressaoFC(z).InTipoRubrica;
                vRecExpressaoFC.InRelacaoRubrica           := vTabExpressaoFC(z).InRelacaoRubrica;
                vRecExpressaoFC.InMes                      := vTabExpressaoFC(z).InMes;
                vRecExpressaoFC.CdValorReferencia          := vTabExpressaoFC(z).CdValorReferencia;
                vRecExpressaoFC.CdBaseCalculo              := vTabExpressaoFC(z).CdBaseCalculo;
                vRecExpressaoFC.CdTipoAdicionalTempServ    := vTabExpressaoFC(z).CdTipoAdicionalTempServ;
                vRecExpressaoFC.CdValorGeralCEFAgrup       := vTabExpressaoFC(z).CdValorGeralCEFAgrup;
                vRecExpressaoFC.DeNivel                    := vTabExpressaoFC(z).DeNivel;
                vRecExpressaoFC.DeCodigoCCO                := vTabExpressaoFC(z).DeCodigoCCO;
                vRecExpressaoFC.CdEstruturaCarreira        := vTabExpressaoFC(z).CdEstruturaCarreira;
                vRecExpressaoFC.DeReferencia               := vTabExpressaoFC(z).DeReferencia;
                vRecExpressaoFC.CdFuncaoChefia             := vTabExpressaoFC(z).CdFuncaoChefia;
                vRecExpressaoFC.NuMeses                    := vTabExpressaoFC(z).NuMeses;
                vRecExpressaoFC.NuValor                    := vTabExpressaoFC(z).NuValor;
                vRecExpressaoFC.InTipoRetorno              := NULL;
                vRecExpressaoFC.FlValorHoraMinuto          := NULL;
                vRecExpressaoFC.CdFolhaHistorico           := NULL;
                vRecExpressaoFC.CdFolhaHistAlt             := NULL;
                vRecExpressaoFC.VlResultado                := NULL;
                --SIG-7497
                vRecExpressaoFC.NuMesRubrica               := vTabExpressaoFC(z).NuMesRubrica;
                vRecExpressaoFC.NuAnoRubrica               := vTabExpressaoFC(z).NuAnoRubrica;
                tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(z) := vRecExpressaoFC;

             END LOOP;
          END IF;

          FOR k IN tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao.FIRST .. tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao.LAST

          LOOP

            tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).FlValorHoraMinuto :=  rFormExp.FlValorHoraMinuto;

            tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistAlt := 0;

            IF tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).InMes = 'AN' THEN

              tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico := PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt;

            ELSIF tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).InMes = 'UL' THEN

              tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico := pFolha.CdFolhaPagamento;

              tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistAlt   := PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt;
            ELSIF tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).InMes = 'RI' THEN
              -- SIG-7497 - Implementado para buscar a folha do mesmo tipo da que está sendo calculada.
              --            Verificar se é necessário buscar sempre da folha normal. Neste caso, a busca
              --            deverá ser ajustada.

              vNuAnoRubrica := tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).NuAnoRubrica;
              vNuMesRubrica := tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).NuMesRubrica;

              begin

               if (pFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao) then

                   if (pFolha.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoRecalculoMes, PKGPAG_TIPO.cnTpCalculoPrevia))
                     then
                     SELECT cdfolhapagamento
                       INTO tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico
                       FROM epagfolhapagamento fp
                      WHERE fp.cdorgao = pFolha.CdOrgao
                        AND fp.cdtipocalculo = PKGPAG_TIPO.cnTpCalculoNormal
                        AND fp.cdtipofolhapagamento = pFolha.CdTipoFolhaPagamento
                        AND fp.nuanoreferencia = vNuAnoRubrica
                        AND fp.numesreferencia = vNuMesRubrica
                        AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnN;

                  else
                    SELECT cdfolhapagamento
                      INTO tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico
                      FROM epagfolhapagamento fp
                     WHERE fp.cdorgao = pFolha.CdOrgao
                       AND fp.cdtipocalculo = pFolha.CdTipoCalculo
                       AND fp.cdtipofolhapagamento = pFolha.CdTipoFolhaPagamento
                       AND fp.nuanoreferencia = vNuAnoRubrica
                       AND fp.numesreferencia = vNuMesRubrica
                       AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnN;

                  end if;

                else
                   if (pFolha.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoRecalculoMes, PKGPAG_TIPO.cnTpCalculoPrevia))
                     then
                     SELECT cdfolhapagamento
                       INTO tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico
                       FROM epagfolhapagamento fp
                      WHERE fp.cdorgao = pFolha.CdOrgao
                        AND fp.cdtipocalculo = PKGPAG_TIPO.cnTpCalculoNormal
                        AND fp.cdtipofolhapagamento = pFolha.CdTipoFolhaPagamento
                        AND fp.nuanoreferencia = vNuAnoRubrica
                        AND fp.numesreferencia = vNuMesRubrica
                        AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS;

                  else
                    SELECT cdfolhapagamento
                      INTO tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico
                      FROM epagfolhapagamento fp
                     WHERE fp.cdorgao = pFolha.CdOrgao
                       AND fp.cdtipocalculo = pFolha.CdTipoCalculo
                       AND fp.cdtipofolhapagamento = pFolha.CdTipoFolhaPagamento
                       AND fp.nuanoreferencia = vNuAnoRubrica
                       AND fp.numesreferencia = vNuMesRubrica
                       AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS;
                  end if;

                end if;

              exception
                when no_data_found then
                  tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico := NULL;
                when others then
                  tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico := NULL;
              end;

            ELSE

              tFormCalc(rFormExp.CdExpressaoFormCalc).lBloco(j).lExpressao(k).CdFolhaHistorico := pFolha.CdFolhaPagamento;

            END IF;

          END LOOP;

        END LOOP;

      END LOOP;

   /* EXCEPTION

      WHEN OTHERS THEN

        DBMS_OUTPUT.put_line('Erro na leitura da Formula de calculo:' || SQLERRM);*/

    END;

  END LOOP;

  RETURN tFormCalc;

/*EXCEPTION

  WHEN OTHERS THEN

   DBMS_OUTPUT.put_line('Erro na leitura da Formula de calculo:' || SQLERRM) ;  */

END;

/*-----------------------------------------------------------------------------------------
    Function: FExprBaseCalculo

    Objetivo: Retorna as expressoes de base de calculo nao associadas as rubricas totalizadoras

  Argumentos: pFolha - registro contendo informac?es da folha que esta sendo processada
              pCdVinculo - codigo do vinculo cuja folha esta sendo calculada

        Nota: Busca as informacoes da base de calculo no agrupamento, verificando se existe
              a mesma base definida no orgao. Existindo as duas, prevalece a do orgao.

/*-----------------------------------------------------------------------------------------*/

FUNCTION FExprBaseCalculo(pFolha IN PKGPAG_TIPO.rFolha)
  RETURN PKGPAG_TIPO.tBaseCalculo IS

  CURSOR cBaseCalculo IS
    SELECT B.NuVersao,
           B.CdAgrupamento,
           RA.CdRubricaAgrupamento,
           B.CdBaseCalculo,
           B.SgBaseCalculo,
           B.CdHistBaseCalculo,
           B.DeFormula,
           B.CdValorReferenciaInferior,
           B.NuQtdeValReferenciaInferior,
           B.CdValorReferenciaSuperior,
           B.NuQtdeValReferenciaSuperior
      FROM (SELECT BC.SgBaseCalculo, MAX(NuVersao) AS NuVersao
              FROM EPagBaseCalculo BC
             INNER JOIN EPagBaseCalculoVersao BCV
                ON BC.CdBaseCalculo = BCV.CdBaseCalculo
             INNER JOIN EPagHistBaseCalculo HBC
                ON BCV.CdVersaoBaseCalculo = HBC.CdVersaoBaseCalculo
             WHERE BCV.NuVersao IN (pFolha.NuVersaoBaseCalculo, PKGPAG_TIPO.cn1) AND
                   ((HBC.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                   (HBC.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                   HBC.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                   AND
                   (HBC.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                   (HBC.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                   HBC.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                   HBC.NuAnoFimVigencia IS NULL)) AND
                   BC.CdAgrupamento = pFolha.CdAgrupamento
              GROUP BY BC.SgBaseCalculo) A
          INNER JOIN
            (SELECT NuVersao,
                   CdAgrupamento,
                   CdBaseCalculo,
                   SgBaseCalculo,
                   CdHistBaseCalculo,
                   DeFormula,
                   CdValorReferenciaInferior,
                   NuQtdeValReferenciaInferior,
                   CdValorReferenciaSuperior,
                   NuQtdeValReferenciaSuperior
             FROM (SELECT BCV.NuVersao,
                          BC.CdAgrupamento,
                          BC.CdBaseCalculo,
                          BC.SgBaseCalculo,
                          HBC.CdHistBaseCalculo,
                          HBC.DeFormula,
                          HBC.CdValorReferenciaInferior,
                          HBC.NuQtdeValReferenciaInferior,
                          HBC.CdValorReferenciaSuperior,
                          HBC.NuQtdeValReferenciaSuperior
                     FROM EPagBaseCalculo BC
                    INNER JOIN EPagBaseCalculoVersao BCV
                       ON BC.CdBaseCalculo = BCV.CdBaseCalculo
                    INNER JOIN EpagHistBaseCalculo HBC
                       ON BCV.CdVersaoBaseCalculo = HBC.CdVersaoBaseCalculo
                    WHERE BCV.NuVersao IN (pFolha.NuVersaoBaseCalculo, PKGPAG_TIPO.cn1) AND
                          ((HBC.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                          (HBC.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                          HBC.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                          AND
                          (HBC.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                          (HBC.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                          HBC.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                          HBC.NuAnoFimVigencia IS NULL)) AND
                          BC.CdAgrupamento = pFolha.CdAgrupamento
                    ORDER BY BCV.NuVersao DESC) ) B
      ON A.SgBaseCalculo = B.SgBaseCalculo AND
         A.NuVersao = B.NuVersao
    LEFT JOIN EPagRubricaAgrupamento RA
        ON RA.CdBaseCalculo = B.CdBaseCalculo
        AND RA.Cdagrupamento = pFolha.CdAgrupamento
         ;

   CURSOR cBlocoExpressao(bCdHistBaseCalculo IN INTEGER) IS
     SELECT BCB.CdBaseCalculoBloco,
            BCB.SgBloco
       FROM EpagBaseCalculoBloco BCB
      WHERE BCB.CdHistBaseCalculo = bCdHistBaseCalculo
      ORDER BY LENGTH(BCB.SgBloco);

   CURSOR cExpressaoCalculo(pCdBaseCalculoBloco IN INTEGER) IS
     SELECT BCE.CdBaseCalculoBlocoExpressao,
            BCE.CdRubricaAgrupamento,
            TRIM (BCE.DeOperacao) AS DeOperacao,
            BCE.CdTipoMneumonico,
            BCE.InTipoRubrica,
            BCE.InRelacaoRubrica,
            BCE.InMes,
            BCE.CdValorReferencia,
            BCE.CdBaseCalculo,
            BCE.CdTipoAdicionalTempServ,
            BCE.CdValorGeralCEFAgrup,
            BCE.DeNivel,
            BCE.DeCodigoCCO,
            BCE.CdEstruturaCarreira,
            BCE.DeReferencia,
            BCE.CdFuncaoChefia,
            BCE.NuMeses,
            BCE.NuValor,
            BCE.InTipoRetorno,
            BCE.InValorHoraMinuto
       FROM EPagBaseCalculoBlocoExpressao BCE
      WHERE BCE.CdBaseCalculoBloco = pCdBaseCalculoBloco
   ORDER BY BCE.CdBaseCalculoBlocoExpressao;

  tBaseCalc      PKGPAG_TIPO.tBaseCalculo;

  j              INTEGER;

  type tExpressaoBC   IS TABLE OF cExpressaoCalculo%ROWTYPE;

  vTabExpressaoBC     tExpressaoBC;

  vRecExpressaoBC     PKGPAG_TIPO.rExpressao;

BEGIN
 
    FOR rBaseCalc IN cBaseCalculo

    LOOP

      j := 0;

      tBaseCalc(rBaseCalc.CdBaseCalculo).CdBaseCalculo := rBaseCalc.CdBaseCalculo;

      tBaseCalc(rBaseCalc.CdBaseCalculo).CdRubricaAgrupamento := rBaseCalc.CdRubricaAgrupamento;

      tBaseCalc(rBaseCalc.CdBaseCalculo).NuVersao := rBaseCalc.NuVersao;

      /* Verifica se existe a mesma base definida no Orgao com a versao especificada*/

      BEGIN

        SELECT NuVersao,
               CdHistBaseCalculo,
               REPLACE(DeFormula, '=', ''),
               CdValorReferenciaInferior,
               NuQtdeValReferenciaInferior,
               CdValorReferenciaSuperior,
               NuQtdeValReferenciaSuperior
          INTO tBaseCalc(rBaseCalc.CdBaseCalculo).NuVersao,
               tBaseCalc(rBaseCalc.CdBaseCalculo).CdHistBaseCalculo,
               tBaseCalc(rBaseCalc.CdBaseCalculo).DeFormula,
               tBaseCalc(rBaseCalc.CdBaseCalculo).CdValorReferenciaInferior,
               tBaseCalc(rBaseCalc.CdBaseCalculo).NuQtdeValReferenciaInferior,
               tBaseCalc(rBaseCalc.CdBaseCalculo).CdValorReferenciaSuperior,
               tBaseCalc(rBaseCalc.CdBaseCalculo).NuQtdeValReferenciaSuperior
          FROM (SELECT BCV.NuVersao,
                       HBC.CdHistBaseCalculo,
                       REPLACE(HBC.DeFormula, '=', '') DeFormula,
                       HBC.CdValorReferenciaInferior,
                       HBC.NuQtdeValReferenciaInferior,
                       HBC.CdValorReferenciaSuperior,
                       HBC.NuQtdeValReferenciaSuperior
                  FROM epagBaseCalculo BC
                 INNER JOIN EPagBaseCalculoVersao BCV
                    ON BC.CdBaseCalculo = BCV.CdBaseCalculo
                 INNER JOIN EPagHistBaseCalculo HBC
                    ON BCV.CdVersaoBaseCalculo = HBC.CdVersaoBaseCalculo
                 WHERE BCV.NuVersao IN (pFolha.NuVersaoBaseCalculo, PKGPAG_TIPO.cn1) AND
                       BC.CdOrgao = pFolha.CdOrgao AND
                       BC.SgBaseCalculo = rBaseCalc.SgBaseCalculo AND
                       ((HBC.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                       (HBC.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                       HBC.NuMesInicioVigencia <= pFolha.NuMesReferencia))
                       AND
                       (HBC.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                       (HBC.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                       HBC.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                       HBC.NuAnoFimVigencia IS NULL))
                 ORDER BY BCV.NuVersao DESC)
            WHERE ROWNUM < 2;

            IF (tBaseCalc(rBaseCalc.CdBaseCalculo).NuVersao <> pFolha.NuVersaoBaseCalculo AND
                tBaseCalc(rBaseCalc.CdBaseCalculo).NuVersao <> rBaseCalc.NuVersao) THEN

              tBaseCalc(rBaseCalc.CdBaseCalculo).NuVersao := rBaseCalc.NuVersao;

              tBaseCalc(rBaseCalc.CdBaseCalculo).CdHistBaseCalculo:= rBaseCalc.CdHistBaseCalculo;

              tBaseCalc(rBaseCalc.CdBaseCalculo).DeFormula:= REPLACE(rBaseCalc.DeFormula, '=', '');

              tBaseCalc(rBaseCalc.CdBaseCalculo).CdValorReferenciaInferior := rBaseCalc.CdValorReferenciaInferior;

              tBaseCalc(rBaseCalc.CdBaseCalculo).NuQtdeValReferenciaInferior := rBaseCalc.NuQtdeValReferenciaInferior;

              tBaseCalc(rBaseCalc.CdBaseCalculo).CdValorReferenciaSuperior := rBaseCalc.CdValorReferenciaSuperior;

              tBaseCalc(rBaseCalc.CdBaseCalculo).NuQtdeValReferenciaSuperior := rBaseCalc.NuQtdeValReferenciaSuperior;

            END IF;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          tBaseCalc(rBaseCalc.CdBaseCalculo).NuVersao := rBaseCalc.NuVersao;

          tBaseCalc(rBaseCalc.CdBaseCalculo).CdHistBaseCalculo:= rBaseCalc.CdHistBaseCalculo;

          tBaseCalc(rBaseCalc.CdBaseCalculo).DeFormula:= FRetiraIgualFormula(rBaseCalc.DeFormula);

          tBaseCalc(rBaseCalc.CdBaseCalculo).CdValorReferenciaInferior := rBaseCalc.CdValorReferenciaInferior;

          tBaseCalc(rBaseCalc.CdBaseCalculo).NuQtdeValReferenciaInferior := rBaseCalc.NuQtdeValReferenciaInferior;

          tBaseCalc(rBaseCalc.CdBaseCalculo).CdValorReferenciaSuperior := rBaseCalc.CdValorReferenciaSuperior;

          tBaseCalc(rBaseCalc.CdBaseCalculo).NuQtdeValReferenciaSuperior := rBaseCalc.NuQtdeValReferenciaSuperior;

      END;

      FOR rBlocExp IN cBlocoExpressao(rBaseCalc.CdHistBaseCalculo)

      LOOP

        j := j + 1;

        tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).CdBlocoExpressao := rBlocExp.CdBaseCalculoBloco;

        tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).SgBloco := rBlocExp.SgBloco;

        OPEN cExpressaoCalculo(tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).CdBlocoExpressao);

        FETCH cExpressaoCalculo BULK COLLECT INTO vTabExpressaoBC;

        CLOSE cExpressaoCalculo;

        IF vTabExpressaoBC.FIRST IS NOT NULL THEN
           FOR z in vTabExpressaoBC.FIRST .. vTabExpressaoBC.LAST LOOP

              vRecExpressaoBC.CdExpressao                := vTabExpressaoBC(z).CdBaseCalculoBlocoExpressao;
              vRecExpressaoBC.CdRubricaAgrupamento       := vTabExpressaoBC(z).CdRubricaAgrupamento;
              vRecExpressaoBC.DeOperacao                 := vTabExpressaoBC(z).DeOperacao;
              vRecExpressaoBC.CdTipoMneumonico           := vTabExpressaoBC(z).CdTipoMneumonico;
              vRecExpressaoBC.InTipoRubrica              := vTabExpressaoBC(z).InTipoRubrica;
              vRecExpressaoBC.InRelacaoRubrica           := vTabExpressaoBC(z).InRelacaoRubrica;
              vRecExpressaoBC.InMes                      := vTabExpressaoBC(z).InMes;
              vRecExpressaoBC.CdValorReferencia          := vTabExpressaoBC(z).CdValorReferencia;
              vRecExpressaoBC.CdBaseCalculo              := vTabExpressaoBC(z).CdBaseCalculo;
              vRecExpressaoBC.CdTipoAdicionalTempServ    := vTabExpressaoBC(z).CdTipoAdicionalTempServ;
              vRecExpressaoBC.CdValorGeralCEFAgrup       := vTabExpressaoBC(z).CdValorGeralCEFAgrup;
              vRecExpressaoBC.DeNivel                    := vTabExpressaoBC(z).DeNivel;
              vRecExpressaoBC.DeCodigoCCO                := vTabExpressaoBC(z).DeCodigoCCO;
              vRecExpressaoBC.CdEstruturaCarreira        := vTabExpressaoBC(z).CdEstruturaCarreira;
              vRecExpressaoBC.DeReferencia               := vTabExpressaoBC(z).DeReferencia;
              vRecExpressaoBC.CdFuncaoChefia             := vTabExpressaoBC(z).CdFuncaoChefia;
              vRecExpressaoBC.NuMeses                    := vTabExpressaoBC(z).NuMeses;
              vRecExpressaoBC.NuValor                    := vTabExpressaoBC(z).NuValor;
              vRecExpressaoBC.InTipoRetorno              := vTabExpressaoBC(z).InTipoRetorno;

              IF vTabExpressaoBC(z).InValorHoraMinuto = 2 THEN
                 vRecExpressaoBC.FlValorHoraMinuto       := 'S';
              ELSE
                 vRecExpressaoBC.FlValorHoraMinuto       := 'N';
              END IF;
              vRecExpressaoBC.CdFolhaHistorico           := NULL;
              vRecExpressaoBC.CdFolhaHistAlt             := NULL;
              vRecExpressaoBC.VlResultado                := NULL;

              tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(z) := vRecExpressaoBC;

           END LOOP;
        END IF;

        FOR k IN tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao.FIRST .. tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao.LAST

        LOOP

          tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(k).CdFolhaHistAlt   := 0;

          IF tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(k).InMes = 'AN' THEN

            tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(k).CdFolhaHistorico := PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt;

          ELSIF tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(k).InMes = 'UL' THEN

            tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(k).CdFolhaHistorico := pFolha.CdFolhaPagamento;

            tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(k).CdFolhaHistAlt   := PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt;

          ELSE

            tBaseCalc(rBaseCalc.CdBaseCalculo).lBloco(j).lExpressao(k).CdFolhaHistorico := pFolha.CdFolhaPagamento;

          END IF;

        END LOOP;

      END LOOP;

    END LOOP;

  RETURN tBaseCalc;

/*EXCEPTION

  WHEN OTHERS THEN

    NULL;  */

END;

PROCEDURE PArmazenaInfoFolha (pCdFolhaPagamento IN INTEGER) IS

  vCdFolhaPagamento INTEGER;

BEGIN
 
    OPEN PKGPAG_VAR.cFolha(pcdFolhaPagamento);

    FETCH PKGPAG_VAR.cFolha INTO PKGPAG_VAR.vgFolha;

    CLOSE PKGPAG_VAR.cFolha;

    -----------------------------------------------------------------------------------------
    -- Data: 16/09/2010
    -- Alteracao: Caso o tipo de calculo seja 7 (1º Calculo do mes),8 (2º Calculo do mes) ou
    -- 9 (Previa), o codigo da folha selecionada sera a do tipo de calculo normal
    -- Objetivo: Atender solicitacao do cliente para poder comaprar versoes de folha
    -- A copia dos dados e realizada no final
    -----------------------------------------------------------------------------------------

    IF PKGPAG_VAR.vgFolha.CdTipoCalculo IN (7,8,9) THEN

      PKGPAG_VAR.vgFolhaOrigem := PKGPAG_VAR.vgFolha;

      -- Seleciona a folha do tipo normal

      SELECT F.CdFolhaPagamento
        INTO vCdFolhaPagamento
        FROM EPagFolhaPagamento F
       WHERE F.CdOrgao = PKGPAG_VAR.vgFolha.CdOrgao AND
             F.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
             F.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
             F.NuANoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
             F.NuMesReferencia = PKGPAG_VAR.vgFolha.NuMesReferencia;

      OPEN PKGPAG_VAR.cFolha(vcdFolhaPagamento);

      FETCH PKGPAG_VAR.cFolha INTO PKGPAG_VAR.vgFolha;

      CLOSE PKGPAG_VAR.cFolha;

    END IF;

END;

PROCEDURE PArmazenaInfoFolhaAuxiliar (pCdFolhaPagamento IN INTEGER) IS

  --vCdFolhaPagamento INTEGER;

BEGIN
 
    OPEN PKGPAG_VAR.cFolha(pcdFolhaPagamento);

    FETCH PKGPAG_VAR.cFolha INTO PKGPAG_VAR.vgFolhaAuxiliar;

    CLOSE PKGPAG_VAR.cFolha;

END;

PROCEDURE PArmazenaInfoFolhaNormalAnt (pCdFolhaPagamento IN INTEGER) IS

  --vCdFolhaPagamento INTEGER;

BEGIN
 
    OPEN PKGPAG_VAR.cFolha(pcdFolhaPagamento);

    FETCH PKGPAG_VAR.cFolha INTO PKGPAG_VAR.vgFolhaNormalAnt;

    CLOSE PKGPAG_VAR.cFolha;

END;

FUNCTION FCargaRubModalidade (pCdAgrupamento IN INTEGER,
                              pCdOrgao       IN INTEGER) RETURN  PKGPAG_TIPO.tListaNumber IS
                                 
   vTotRub         PKGPAG_TIPO.tListaNumber;
   vIdentRubrica   PKGPAG_TIPO.rIdentRubrica;
   vIdent          INTEGER;
        
BEGIN

   vTotRub.DELETE;

   FOR rec IN (SELECT RA.CdModalidadeRubrica,
                      RA.CdRubricaAgrupamento
                 FROM EPagRubricaAgrupamento RA
                WHERE RA.CdModalidadeRubrica IS NOT NULL
                  AND (pCdAgrupamento IS NULL
                       OR RA.CdAgrupamento = pCdAgrupamento
                       OR RA.CdOrgao = pCdOrgao)
                      ) LOOP
      vIdent := NULL;

       CASE rec.CdModalidadeRubrica

          WHEN PKGPAG_TIPO.cnModRubSalIPESC THEN
            vIdent := vIdentRubrica.cnIndRubBaseIPESC;

          WHEN PKGPAG_TIPO.cnModRubSalBaseIPESC13 THEN

            vIdent := vIdentRubrica.cnIndRubBaseIPESC13;

          WHEN PKGPAG_TIPO.cnModRubSalBaseINSS THEN

            vIdent := vIdentRubrica.cnIndRubBaseINSS;

          WHEN PKGPAG_TIPO.cnModRubSalBaseINSS13 THEN

            vIdent := vIdentRubrica.cnIndRubBaseINSS13;

          /* Carrega o codigo da rubrica associada a base do IRRF  */

          WHEN PKGPAG_TIPO.cnModRubBaseIRRF THEN

            vIdent := vIdentRubrica.cnIndRubBaseIRRF;

          /* Carrega o codigo da rubrica associada a base do IRRF sobre ferias */

          WHEN PKGPAG_TIPO.cnModRubBaseIRRFFerias THEN

            vIdent := vIdentRubrica.cnIndRubBaseIRRFFerias;

          WHEN PKGPAG_TIPO.cnModRubSalBaseINSSPat THEN

            vIdent := vIdentRubrica.cnIndRubricaBaseINSSPat;

          WHEN PKGPAG_TIPO.cnModRubBaseINSSCLT THEN

            vIdent := vIdentRubrica.cnIndRubBaseINSSCLT;

           /* Carrega o codigo da rubrica associada a base do IRRF sobre 13 */

          WHEN PKGPAG_TIPO.cnModRubSalBaseIRRF13 THEN

            vIdent := vIdentRubrica.cnIndRubBaseIRRF13;

          WHEN PKGPAG_TIPO.cnModRubBaseValeTransp THEN

            vIdent := vIdentRubrica.cnIndRubBaseVP;

          WHEN PKGPAG_TIPO.cnModRubBaseCSGProcCC THEN

            vIdent := vIdentRubrica.cnIndRubricaCSGProcCC;

          WHEN PKGPAG_TIPO.cnModRubBaseCSGProcCC THEN

            vIdent := vIdentRubrica.cnIndRubricaCSGProcCC;

          WHEN PKGPAG_TIPO.cnModRubBaseFGTS THEN

            vIdent := vIdentRubrica.cnIndRubBaseFGTS;

          WHEN PKGPAG_TIPO.cnModRubBaseFGTS13 THEN

            vIdent := vIdentRubrica.cnIndRubBaseFGTS13;

          WHEN PKGPAG_TIPO.cnModRubVlFGTS THEN

            vIdent := vIdentRubrica.cnIndRubVlFGTS;

          WHEN PKGPAG_TIPO.cnModRubVlFGTS13 THEN

            vIdent := vIdentRubrica.cnIndRubVlFGTS13;

          WHEN PKGPAG_TIPO.cnModRubBaseIPREVFP THEN

            vIdent := vIdentRubrica.cnIndRubBaseIPREVFP;

          WHEN PKGPAG_TIPO.cnModRubBaseIPREVFF THEN

            vIdent := vIdentRubrica.cnIndRubBaseIPREVFF;

          WHEN 10 THEN

            vIdent := vIdentRubrica.cnIndRubricaBaseConsig;

           WHEN 14 THEN

             vIdent := vIdentRubrica.cnIndRubricaErario;

           WHEN 16 THEN

             vIdent := vIdentRubrica.cnIndRubricaBaseCsgLiq;

           WHEN 17 THEN

             vIdent := vIdentRubrica.cnIndRubricaBaseTotPrv;

           WHEN 18 THEN

             vIdent := vIdentRubrica.cnIndRubricaBaseTotDsc;

           WHEN 19 THEN

             vIdent := vIdentRubrica.cnIndRubricaBaseTotLiq;

           WHEN 20 THEN

             vIdent := vIdentRubrica.cnIndRubricaCSGNaoProc;

           WHEN 21 THEN

             vIdent := vIdentRubrica.cnIndRubricaBasePlanoSaude;

           WHEN 22 THEN

             vIdent := vIdentRubrica.cnIndRubricaBaseCoParticip;

           WHEN 23 THEN

             vIdent := vIdentRubrica.cnIndRubricaCSGProc;

           WHEN 24 THEN

             vIdent := vIdentRubrica.cnIndRubricaDescDepIRRF;

           WHEN 26 THEN

             vIdent := vIdentRubrica.cnIndRubricaTetoGov;

           WHEN 27 THEN

             vIdent := vIdentRubrica.cnIndRubricaBaseTetoGov;

          WHEN 28 THEN

            vIdent := vIdentRubrica.cnIndRubricaBaseCSG_CC;

          WHEN 29 THEN

            vIdent := vIdentRubrica.cnIndRubricaBaseFerias;

          WHEN 36 THEN

            vIdent := vIdentRubrica.cnIndRubricaBasePSPatronal;

          WHEN 38 THEN

            vIdent := vIdentRubrica.cnIndRubBaseDeducaoInativo;

          WHEN 39 THEN

            vIdent := vIdentRubrica.cnIndRubBaseIRRFOutros;

          WHEN 40 THEN

            vIdent := vIdentRubrica.cnIndRubDeducaoIRRFOutros;

          WHEN 41 THEN

            vIdent := vIdentRubrica.cnIndRubBaseSCSAUDEOutros;

          WHEN 42 THEN

            vIdent := vIdentRubrica.cnIndRubDeducaoSCSAUDEOutros;

          WHEN 43 THEN

            vIdent := vIdentRubrica.cnIndRubBaseDescFacultativos;

          WHEN 44 THEN

            vIdent := vIdentRubrica.cnIndRubBloqRetroativo;

          WHEN 45 THEN

            vIdent := vIdentRubrica.cnIndRubDepositoJud;

          WHEN 46 THEN

            vIdent := vIdentRubrica.cnIndRubricaBaseTetoGov13;

          WHEN 48 THEN

            IF PKGPAG_VAR.vgFolha.CdTipoFolha NOT IN (pkgpag_tipo.cnTpFolhaCtisp13,
                                                      pkgpag_tipo.cnTpFolhaAdiant13Ctisp,
                                                      pkgpag_tipo.cnTpFolhaCtisp) THEN

               vIdent := vIdentRubrica.cnIndRubDevAnt13NaoEfetuado;

            END IF;

          WHEN 221 THEN

               IF PKGPAG_VAR.vgFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolhaCtisp13,
                                                     pkgpag_tipo.cnTpFolhaAdiant13Ctisp,
                                                     pkgpag_tipo.cnTpFolhaCtisp) THEN

                  vIdent := vIdentRubrica.cnIndRubDevAnt13NaoEfetuado;

               END IF;

          WHEN 49 THEN

            vIdent := vIdentRubrica.cnIndRubBaseRateio;

          WHEN 50 THEN

            vIdent := vIdentRubrica.cnIndRubBase13Sal;

          WHEN 51 THEN

            vIdent := vIdentRubrica.cnIndRubExigibilidadeSusp;

          WHEN 52 THEN

            vIdent := vIdentRubrica.cnIndRubBaseBaixa;

          WHEN 56 THEN

            vIdent := vIdentRubrica.cnIndRubFeriasFGTS;

          WHEN 58 THEN

            vIdent := vIdentRubrica.cnIndRubBaseAbonoSeguranca;
    
          WHEN 59 THEN

            vIdent := vIdentRubrica.cnIndRubBaseRRA;

          WHEN 68 THEN

            vIdent := vIdentRubrica.cnIndBaseSalMaternidade;

          WHEN 70 THEN

            vIdent := vIdentRubrica.cnIndRubBaseFaltaRetroNaoDesc;
    
          WHEN 71 THEN

            vIdent := vIdentRubrica.cnIndRubBaseAlimRetroNaoDesc;
          
          WHEN 72 THEN

            vIdent := vIdentRubrica.cnIndRubBasePensaoNaoDesc;
        
          WHEN 73 THEN

            vIdent := vIdentRubrica.cnIndRubBaseDevAd13NaoEfet;
       
          WHEN 74 THEN

            vIdent := vIdentRubrica.cnIndRubBase080023DescParcial;
       
          WHEN 75 THEN

            vIdent := vIdentRubrica.cnIndRubBase080024DescParcial;
        
          WHEN 79 THEN

            vIdent := vIdentRubrica.cnIndRubBaseProv13PatFP;
       
           WHEN 80 THEN

            vIdent := vIdentRubrica.cnIndRubBaseProv13PatFF;
         
           WHEN 81 THEN

            vIdent := vIdentRubrica.cnIndRubBaseProv13PatINSS;
         
           WHEN 82 THEN

            vIdent := vIdentRubrica.cnIndRubBaseProv13PatINSSCLT;
      
           WHEN 83 THEN

            vIdent := vIdentRubrica.cnIndRubBaseProv13VlFGTS;

          WHEN 84 THEN

            vIdent := vIdentRubrica.cnIndRubExigibilidadeSuspRRA;

          WHEN 88 THEN

            vIdent := vIdentRubrica.cnIndRubBaseValorPatINSS;

          WHEN 89 THEN

            vIdent := vIdentRubrica.cnIndRubBaseCeres;

          when 111 then

            vIdent := vIdentRubrica.cnIndRubBaseCPSM;

          when 112 then

            vIdent := vIdentRubrica.cnIndRubBaseCPSM13;
            
          WHEN 115 THEN
            
            vIdent := vIdentRubrica.cnIndRubBaseDeducoesIRRFOutros;
            
          WHEN 116 THEN
            
            vIdent := vIdentRubrica.cnIndRubBaseDeducoesIRRF;
         
          WHEN 117 THEN
            
            vIdent := vIdentRubrica.cnIndRubBaseTotDeducoesIRRF13;
            
          WHEN 118 THEN
            
            vIdent := vIdentRubrica.cnIndRubBaseDescSimplifIRRF;
    
          WHEN 119 THEN
            
            vIdent := vIdentRubrica.cnIndRubBaseDedIRRFOutros13;
    
          WHEN 120 THEN
            
            vIdent := vIdentRubrica.cnIndRubBaseDescSimplif13;

          WHEN 181 THEN

            vIdent := vIdentRubrica.cnIndRubricaBaseCsgLiq_CC;

          WHEN 241 THEN

            vIdent := vIdentRubrica.cnIndRubBaseCsgMargFut;
            
          WHEN 281 THEN

            vIdent := vIdentRubrica.cnIndRubExigibilidadeSusp13;

          WHEN 321 THEN

            vIdent := vIdentRubrica.cnIndRubBaseIPREVFT;

          WHEN 341 THEN

            vIdent := vIdentRubrica.cnIndRubBaseProv13FT;
            
          WHEN 342 THEN

            vIdent := vIdentRubrica.cnIndRubBaseCsgLiqOutros;
            
          WHEN 343 THEN

            vIdent := vIdentRubrica.cnIndRubBaseCsgBrutaOutros;

          ELSE

            NULL;

          END CASE;

       IF vIdent IS NOT NULL THEN

          IF NOT vTotRub.EXISTS (vIdent) THEN
             vTotRub(vIdent) := TYPENUMBER(); 
          END IF; 

          vTotRub(vIdent).EXTEND;         
          vTotRub(vIdent)(vTotRub(vIdent).LAST) := rec.CdRubricaAgrupamento; 

       END IF;
      
   END LOOP;

   RETURN vTotRub;

END;

FUNCTION FCargaRubTotalizadora (pCdAgrupamento IN INTEGER,
                                pCdOrgao       IN INTEGER,
                                pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER) RETURN PKGPAG_TIPO.tListaNumber IS
                                 
   vTotRub         PKGPAG_TIPO.tListaNumber;
   vIdentRubrica   PKGPAG_TIPO.rIdentRubrica;
      
BEGIN
   
   vTotRub := FCargaRubModalidade (pCdAgrupamento => pCdAgrupamento,
                                   pCdOrgao       => pCdOrgao);
   
   PCargaRubParamAgrupamento (pCdAgrupamento   => pCdAgrupamento,
                              pNuAnoReferencia => pNuAnoReferencia,
                              pNuMesReferencia => pNuMesReferencia,
                              pFlCargaTabela   => 1,
                              pTotRub          => vTotRub);

   vTotRub (vIdentRubrica.cnIndDifDescINSS) := 
        PKGPAG_GERAL.FRetornaRubricaOutroTipo (pTabRubrica      => vTotRub (vIdentRubrica.cnIndDescINSS),
                                               pNuAnoReferencia => pNuAnoReferencia,
                                               pNuMesReferencia => pNuMesReferencia,
                                               pCdTipoRubrica   => PKGPAG_TIPO.cnTpRubDifDesc);

   vTotRub (vIdentRubrica.cnIndDevDescINSS) := 
        PKGPAG_GERAL.FRetornaRubricaOutroTipo (pTabRubrica      => vTotRub (vIdentRubrica.cnIndDescINSS),
                                               pNuAnoReferencia => pNuAnoReferencia,
                                               pNuMesReferencia => pNuMesReferencia,
                                               pCdTipoRubrica   => PKGPAG_TIPO.cnTpRubDevDesc);


   vTotRub (vIdentRubrica.cnIndDevDescINSS13) := 
        PKGPAG_GERAL.FRetornaRubricaOutroTipo (pTabRubrica      => vTotRub (vIdentRubrica.cnIndDescINSSSobre13),
                                               pNuAnoReferencia => pNuAnoReferencia,
                                               pNuMesReferencia => pNuMesReferencia,
                                               pCdTipoRubrica   => PKGPAG_TIPO.cnTpRubDevDesc);
                                               
   vTotRub (vIdentRubrica.cnIndDevDescINSS13) := 
        PKGPAG_GERAL.FRetornaRubricaOutroTipo (pTabRubrica      => vTotRub (vIdentRubrica.cnIndDescINSSSobre13),
                                               pNuAnoReferencia => pNuAnoReferencia,
                                               pNuMesReferencia => pNuMesReferencia,
                                               pCdTipoRubrica   => PKGPAG_TIPO.cnTpRubDevDesc);
                                                                                             
                                            
   RETURN vTotRub;
                                        
END;

PROCEDURE PAtribuiCodigoTotalizadoras(pCdAgrupamento IN INTEGER,
                                      pCdOrgao       IN INTEGER) IS
   
   vTotRub         PKGPAG_TIPO.tListaNumber;
   vIdentRubrica   PKGPAG_TIPO.rIdentRubrica;
   
   FUNCTION FValor (pIdent IN INTEGER) RETURN INTEGER IS
      
   BEGIN
      IF vTotRub.EXISTS (pIdent) THEN
         IF vTotRub(pIdent).COUNT > 1 THEN
            PKGPAG_GERAL.PErroFatal (pMsgErro => 'Mais de uma rubrica para uma modalidade');
         ELSE      
            RETURN vTotRub(pIdent)(vTotRub(pIdent).FIRST);
         END IF;  
      ELSE
         RETURN NULL;
      END IF;
   END;
      
BEGIN

   vTotRub := FCargaRubModalidade (pCdAgrupamento => pCdAgrupamento,
                                   pCdOrgao       => pCdOrgao);
                                      
   PKGPAG_VAR.vgCdRubBaseIPESC              := FValor(vIdentRubrica.cnIndRubBaseIPESC);
   PKGPAG_VAR.vgCdRubBaseIPESC13            := FValor(vIdentRubrica.cnIndRubBaseIPESC13);
   PKGPAG_VAR.vgCdRubBaseINSS               := FValor(vIdentRubrica.cnIndRubBaseINSS);
   PKGPAG_VAR.vgCdRubBaseINSS13             := FValor(vIdentRubrica.cnIndRubBaseINSS13);
   PKGPAG_VAR.vgCdRubBaseIRRF               := FValor(vIdentRubrica.cnIndRubBaseIRRF);
   PKGPAG_VAR.vgCdRubBaseIRRFFerias         := FValor(vIdentRubrica.cnIndRubBaseIRRFFerias);
   PKGPAG_VAR.vgCdRubricaBaseINSSPat        := FValor(vIdentRubrica.cnIndRubricaBaseINSSPat);
   PKGPAG_VAR.vgCdRubBaseINSSCLT            := FValor(vIdentRubrica.cnIndRubBaseINSSCLT);
   PKGPAG_VAR.vgCdRubBaseIRRF13             := FValor(vIdentRubrica.cnIndRubBaseIRRF13);
   PKGPAG_VAR.vgCdRubBaseVP                 := FValor(vIdentRubrica.cnIndRubBaseVP);
   PKGPAG_VAR.vgCdRubricaCSGProcCC          := FValor(vIdentRubrica.cnIndRubricaCSGProcCC);
   PKGPAG_VAR.vgCdRubBaseFGTS               := FValor(vIdentRubrica.cnIndRubBaseFGTS);
   PKGPAG_VAR.vgCdRubBaseFGTS13             := FValor(vIdentRubrica.cnIndRubBaseFGTS13);
   PKGPAG_VAR.vgCdRubBaseCsgBrutaOutros     := FValor(vIdentRubrica.cnIndRubBaseCsgBrutaOutros);
   PKGPAG_VAR.vgCdRubBaseCsgLiqOutros       := FValor(vIdentRubrica.cnIndRubBaseCsgLiqOutros);
   PKGPAG_VAR.vgCdRubVlFGTS                 := FValor(vIdentRubrica.cnIndRubVlFGTS);
   PKGPAG_VAR.vgCdRubVlFGTS13               := FValor(vIdentRubrica.cnIndRubVlFGTS13);
   PKGPAG_VAR.vgCdRubBaseIPREVFP            := FValor(vIdentRubrica.cnIndRubBaseIPREVFP);
   PKGPAG_VAR.vgCdRubBaseIPREVFF            := FValor(vIdentRubrica.cnIndRubBaseIPREVFF);
   PKGPAG_VAR.vgCdRubBaseIPREVFT            := FValor(vIdentRubrica.cnIndRubBaseIPREVFT);
   PKGPAG_VAR.vgCdRubBaseProv13FT           := FValor(vIdentRubrica.cnIndRubBaseProv13FT);
   PKGPAG_VAR.vgCdRubricaBaseConsig         := FValor(vIdentRubrica.cnIndRubricaBaseConsig);
   PKGPAG_VAR.vgCdRubricaErario             := FValor(vIdentRubrica.cnIndRubricaErario);
   PKGPAG_VAR.vgCdRubricaBaseCsgLiq         := FValor(vIdentRubrica.cnIndRubricaBaseCsgLiq);
   PKGPAG_VAR.vgCdRubricaBaseTotPrv         := FValor(vIdentRubrica.cnIndRubricaBaseTotPrv);
   PKGPAG_VAR.vgCdRubricaBaseTotDsc         := FValor(vIdentRubrica.cnIndRubricaBaseTotDsc);
   PKGPAG_VAR.vgCdRubricaBaseTotLiq         := FValor(vIdentRubrica.cnIndRubricaBaseTotLiq);
   PKGPAG_VAR.vgCdRubricaCSGNaoProc         := FValor(vIdentRubrica.cnIndRubricaCSGNaoProc);
   PKGPAG_VAR.vgCdRubricaBasePlanoSaude     := FValor(vIdentRubrica.cnIndRubricaBasePlanoSaude);
   PKGPAG_VAR.vgCdRubricaBaseCoParticip     := FValor(vIdentRubrica.cnIndRubricaBaseCoParticip);
   PKGPAG_VAR.vgCdRubricaCSGProc            := FValor(vIdentRubrica.cnIndRubricaCSGProc);
   PKGPAG_VAR.vgCdRubricaDescDepIRRF        := FValor(vIdentRubrica.cnIndRubricaDescDepIRRF);
   PKGPAG_VAR.vgCdRubricaTetoGov            := FValor(vIdentRubrica.cnIndRubricaTetoGov);
   PKGPAG_VAR.vgCdRubricaBaseTetoGov        := FValor(vIdentRubrica.cnIndRubricaBaseTetoGov);
   PKGPAG_VAR.vgCdRubricaBaseCSG_CC         := FValor(vIdentRubrica.cnIndRubricaBaseCSG_CC);
   PKGPAG_VAR.vgCdRubricaBaseFerias         := FValor(vIdentRubrica.cnIndRubricaBaseFerias);
   PKGPAG_VAR.vgCdRubricaBasePSPatronal     := FValor(vIdentRubrica.cnIndRubricaBasePSPatronal);
   PKGPAG_VAR.vgCdRubBaseDeducaoInativo     := FValor(vIdentRubrica.cnIndRubBaseDeducaoInativo);
   PKGPAG_VAR.vgCdRubBaseIRRFOutros         := FValor(vIdentRubrica.cnIndRubBaseIRRFOutros);
   PKGPAG_VAR.vgCdRubDeducaoIRRFOutros      := FValor(vIdentRubrica.cnIndRubDeducaoIRRFOutros);
   PKGPAG_VAR.vgCdRubBaseSCSAUDEOutros      := FValor(vIdentRubrica.cnIndRubBaseSCSAUDEOutros);
   PKGPAG_VAR.vgCdRubDeducaoSCSAUDEOutros   := FValor(vIdentRubrica.cnIndRubDeducaoSCSAUDEOutros);
   PKGPAG_VAR.vgCdRubBaseDescFacultativos   := FValor(vIdentRubrica.cnIndRubBaseDescFacultativos);
   PKGPAG_VAR.vgCdRubBloqRetroativo         := FValor(vIdentRubrica.cnIndRubBloqRetroativo);
   PKGPAG_VAR.vgCdRubDepositoJud            := FValor(vIdentRubrica.cnIndRubDepositoJud);
   PKGPAG_VAR.vgCdRubricaBaseTetoGov13      := FValor(vIdentRubrica.cnIndRubricaBaseTetoGov13);
   PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado    := FValor(vIdentRubrica.cnIndRubDevAnt13NaoEfetuado);
   PKGPAG_VAR.vgCdRubDevAnt13NaoEfetuado    := FValor(vIdentRubrica.cnIndRubDevAnt13NaoEfetuado);
   PKGPAG_VAR.vgCdRubBaseRateio             := FValor(vIdentRubrica.cnIndRubBaseRateio);
   PKGPAG_VAR.vgCdRubBase13Sal              := FValor(vIdentRubrica.cnIndRubBase13Sal);
   PKGPAG_VAR.vgCdRubExigibilidadeSusp      := FValor(vIdentRubrica.cnIndRubExigibilidadeSusp);
   PKGPAG_VAR.vgCdRubExigibilidadeSusp13    := FValor(vIdentRubrica.cnIndRubExigibilidadeSusp13);
   PKGPAG_VAR.vgCdRubBaseBaixa              := FValor(vIdentRubrica.cnIndRubBaseBaixa);
   PKGPAG_VAR.vgCdRubFeriasFGTS             := FValor(vIdentRubrica.cnIndRubFeriasFGTS);
   PKGPAG_VAR.vgCdRubBaseAbonoSeguranca     := FValor(vIdentRubrica.cnIndRubBaseAbonoSeguranca);
   PKGPAG_VAR.vgCdRubBaseRRA                := FValor(vIdentRubrica.cnIndRubBaseRRA);
   PKGPAG_VAR.vgCdBaseSalMaternidade        := FValor(vIdentRubrica.cnIndBaseSalMaternidade);
   PKGPAG_VAR.vgCdRubBaseFaltaRetroNaoDesc  := FValor(vIdentRubrica.cnIndRubBaseFaltaRetroNaoDesc);
   PKGPAG_VAR.vgCdRubBaseAlimRetroNaoDesc   := FValor(vIdentRubrica.cnIndRubBaseAlimRetroNaoDesc);
   PKGPAG_VAR.vgCdRubBasePensaoNaoDesc      := FValor(vIdentRubrica.cnIndRubBasePensaoNaoDesc);
   PKGPAG_VAR.vgCdRubBaseDevAd13NaoEfet     := FValor(vIdentRubrica.cnIndRubBaseDevAd13NaoEfet);
   PKGPAG_VAR.vgCdRubBase080023DescParcial  := FValor(vIdentRubrica.cnIndRubBase080023DescParcial);
   PKGPAG_VAR.vgCdRubBase080024DescParcial  := FValor(vIdentRubrica.cnIndRubBase080024DescParcial);
   PKGPAG_VAR.vgCdRubBaseProv13PatFP        := FValor(vIdentRubrica.cnIndRubBaseProv13PatFP);
   PKGPAG_VAR.vgCdRubBaseProv13PatFF        := FValor(vIdentRubrica.cnIndRubBaseProv13PatFF);
   PKGPAG_VAR.vgCdRubBaseProv13PatINSS      := FValor(vIdentRubrica.cnIndRubBaseProv13PatINSS);
   PKGPAG_VAR.vgCdRubBaseProv13PatINSSCLT   := FValor(vIdentRubrica.cnIndRubBaseProv13PatINSSCLT);
   PKGPAG_VAR.vgCdRubBaseProv13VlFGTS       := FValor(vIdentRubrica.cnIndRubBaseProv13VlFGTS);
   PKGPAG_VAR.vgCdRubExigibilidadeSuspRRA   := FValor(vIdentRubrica.cnIndRubExigibilidadeSuspRRA);
   PKGPAG_VAR.vgCdRubBaseValorPatINSS       := FValor(vIdentRubrica.cnIndRubBaseValorPatINSS);
   PKGPAG_VAR.vgCdRubBaseCeres              := FValor(vIdentRubrica.cnIndRubBaseCeres);
   PKGPAG_VAR.vgCdRubBaseCPSM               := FValor(vIdentRubrica.cnIndRubBaseCPSM);
   PKGPAG_VAR.vgCdRubBaseCPSM13             := FValor(vIdentRubrica.cnIndRubBaseCPSM13);
   PKGPAG_VAR.vgCdRubricaBaseCsgLiq_CC      := FValor(vIdentRubrica.cnIndRubricaBaseCsgLiq_CC);
   PKGPAG_VAR.vgCdRubBaseCsgMargFut         := FValor(vIdentRubrica.cnIndRubBaseCsgMargFut);
   PKGPAG_VAR.vgCdRubBaseDeducoesIRRFOutros := FValor(vIdentRubrica.cnIndRubBaseDeducoesIRRFOutros);
   PKGPAG_VAR.vgCdRubBaseDeducoesIRRF       := FValor(vIdentRubrica.cnIndRubBaseDeducoesIRRF);
   PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13  := FValor(vIdentRubrica.cnIndRubBaseTotDeducoesIRRF13);
   PKGPAG_VAR.vgCdRubBaseDescSimplifIRRF    := FValor(vIdentRubrica.cnIndRubBaseDescSimplifIRRF);
   PKGPAG_VAR.vgCdRubBaseDedIRRFOutros13    := FValor(vIdentRubrica.cnIndRubBaseDedIRRFOutros13);
   PKGPAG_VAR.vgCdRubBaseDescSimplif13      := FValor(vIdentRubrica.cnIndRubBaseDescSimplif13);
                                 
END;

PROCEDURE PArmazenaInfoProc(pCdFolhaPagamento IN INTEGER,
                            pDtCalculo        IN DATE,
                            pCdOrgaoVinc      IN INTEGER DEFAULT NULL) IS

  vCont             INTEGER;
  vCdTipoFolhaPagamento epagtipofolhapagamento.cdtipofolhapagamento%type;

  FUNCTION FRetornaRubricaBase(pCdAgrupamento IN INTEGER,
                               pcnModRubBase  IN INTEGER)
    RETURN INTEGER IS

    vCdRubBase INTEGER;

  BEGIN
 
    SELECT RA.CdRubricaAgrupamento
      INTO vCdRubBase
      FROM EPagRubricaAgrupamento RA
     WHERE RA.CdAgrupamento = pCdAgrupamento AND
           RA.CdModalidadeRubrica = pcnModRubBase;

    RETURN vCdRubBase;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;

  END;

  FUNCTION FRetornaFolhaPagamento(pCdOrgao       IN INTEGER,
                                  pCdTipoCalculo IN INTEGER,
                                  pCdTipoFolha   IN INTEGER,
                                  pNuAno         IN INTEGER,
                                  pNuMes         IN INTEGER,
                                  pFlDefinitivo  IN VARCHAR2 DEFAULT NULL,
                                  pCdTipoFolhaPagamento   IN INTEGER DEFAULT NULL)
     RETURN INTEGER IS

     vCdFolha INTEGER;

  BEGIN
 
    SELECT F.CdFolhaPagamento
      INTO vCdFolha
      FROM (SELECT CdFolhaPagamento,
                   LPAD(FP.NuAnoReferencia,4,'0') ||LPAD(FP.NuMesReferencia,2,'0') AS NuAnoMes
              FROM EPagFolhaPagamento FP
             INNER JOIN EPagTipoFolhaPagamento TFP
                ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento
             WHERE FP.CdOrgao = pCdOrgao AND
                   FP.NuAnoReferencia = pNuAno AND
                   FP.NuMesReferencia = pNuMes AND
                   FP.CdTipoCalculo = pCdTipoCalculo AND
                   TFP.CdTipoFolha = pCdTipoFolha AND
                   (FP.FlCalculoDefinitivo = pFlDefinitivo OR pFlDefinitivo IS NULL) AND
                   TFP.cdtipofolhapagamento = NVL(pCdTipoFolhaPagamento, tfp.cdtipofolhapagamento)) F;

    RETURN vCdFolha;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

   FUNCTION FRetornaCodigoFolha(pCdOrgao       IN INTEGER,
                                pCdFolha       IN INTEGER,
                                pCdTipoCalculo IN INTEGER,
                                pCdTipoFolha   IN INTEGER,
                                pFlDefinitiva  IN CHAR DEFAULT NULL,
                                pCdTipoFolhaPagamento IN INTEGER DEFAULT NULL)
     RETURN INTEGER IS

     vCdFolha INTEGER;

   BEGIN
 
     IF pFlDefinitiva IS NULL THEN

       SELECT CdFolhaPagamento
            INTO vCdFolha
           FROM (SELECT CdFolhaPagamento
                   FROM EPagFolhaPagamento FP
                  INNER JOIN EPagTipoFolhaPagamento TFP
                     ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento
                  INNER JOIN (SELECT CdOrgao, NuAnoReferencia, NuMesReferencia
                                FROM EPagFolhaPagamento FP
                               WHERE CdFolhaPagamento = pCdFolha) FN
                     ON FN.CdOrgao = FP.CdOrgao AND
                        FN.NuAnoReferencia = FP.NuAnoReferencia AND
                        FN.NuMesReferencia = FP.NuMesReferencia
                  WHERE FP.CdOrgao = pCdOrgao AND
                        FP.CdTipoCalculo = pCdTipoCalculo AND
                        TFP.CdTipoFolha = pCdTipoFolha AND
                        tfp.cdtipofolhapagamento = nvl(pCdTipoFolhaPagamento, tfp.cdtipofolhapagamento)
                  ORDER BY FP.NuSequencialFolha)
                 WHERE ROWNUM < 2;

     ELSE

        SELECT CdFolhaPagamento
          INTO vCdFolha
          FROM (SELECT CdFolhaPagamento
                  FROM EPagFolhaPagamento FP
                 INNER JOIN EPagTipoFolhaPagamento TFP
                    ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento
                 INNER JOIN (SELECT CdOrgao, NuAnoReferencia, NuMesReferencia
                               FROM EPagFolhaPagamento FP
                               WHERE CdFolhaPagamento = pCdFolha) FN
                     ON FN.CdOrgao = FP.CdOrgao AND
                        FN.NuAnoReferencia = FP.NuAnoReferencia AND
                        FN.NuMesReferencia = FP.NuMesReferencia
                  WHERE FP.CdOrgao = pCdOrgao AND
                        FP.CdTipoCalculo = pCdTipoCalculo AND
                        TFP.CdTipoFolha = pCdTipoFolha AND
                        (pCdTipoFolhaPagamento IS NULL OR TFP.cdtipofolhapagamento = pCdTipoFolhaPagamento) AND
                        FP.FlCalculoDefinitivo = pFlDefinitiva
                  ORDER BY FP.NuSequencialFolha)
                 WHERE ROWNUM < 2;

     END IF;

     RETURN vCdFolha;

   EXCEPTION

     WHEN OTHERS THEN

       RETURN 0;

   END;

   FUNCTION FPossuiFolhaSuplDef(pCdOrgao               IN INTEGER,
                                pNuAnoReferencia       IN INTEGER,
                                pNuMesReferencia       IN INTEGER,
                                pCdTipoFolhaPagamento  IN INTEGER)
     RETURN BOOLEAN IS

     vCdFolha INTEGER;

   BEGIN
 
     SELECT FP.CdFolhaVincSupl
       INTO vCdFolha
       FROM EPagFolhaPagamento FP
      WHERE FP.CdOrgao = pCdOrgao AND
            FP.NuAnoReferencia = pNuAnoReferencia  AND
            FP.NuMesReferencia = pNuMesReferencia AND
            FP.CdTipoFolhaPagamento = pCdTipoFolhaPagamento AND
            FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl AND
            FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
            ROWNUM < 2;

     RETURN TRUE;

   EXCEPTION

     WHEN NO_DATA_FOUND THEN

       RETURN FALSE;

   END;

BEGIN
 
  PArmazenaInfoFolha (pCdFolhaPagamento);

  SELECT global_name
    INTO PKGPAG_VAR.vgGlobal_Name
    FROM global_name;

  IF PKGPAG_VAR.vgFolha.CdTipoFolha = 1 AND PKGPAG_VAR.vgFolha.CdTipoCalculo = 1 AND
     PKGPAG_VAR.vgGlobal_Name IN ('SIGRH.UNSEF07.INTRANET.CIASC.GOV.BR', 'SIGRHHOM.UNSEF04DES.INTRANET.CIASC.GOV.BR') AND
     NVL(PKGPAG_VAR.vgFolha.NuAnoMesImplantacao,'400001') > (PKGPAG_VAR.vgFolha.NuAnoReferencia || LPAD(PKGPAG_VAR.vgFolha.NuMesReferencia,2,'0')) THEN

    RAISE PKGPAG_VAR.eNaoRodaFolhaNormal;

  END IF;

  -------------------------------------------------------------------------
  -- Verifica se dados do SC Saude foram importados
  -------------------------------------------------------------------------

  BEGIN

    SELECT 1
      INTO vCont
      FROM ESauImpSistemaExterno A
     WHERE A.NuAnoCompetencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
           A.NuMesCompetencia = PKGPAG_VAR.vgFolha.NuMesReferencia AND ROWNUM = 1;

    PKGPAG_VAR.bTemPlanoSaudeSaudeNoMes := TRUE;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_VAR.bTemPlanoSaudeSaudeNoMes := FALSE;

  END;

  ----------------------------------------------------------------------------
  -- Seleciona o codigo da folha de tipo de calculo NORMAL
  -- Variavel utilizada na Tributacao
  ----------------------------------------------------------------------------

  BEGIN

   SELECT CdFolhaPagamento
     INTO PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormal
     FROM (SELECT CdFolhaPagamento
             FROM EPagFolhaPagamento FP
            WHERE FP.CdOrgao = PKGPAG_VAR.vgFolha.CdOrgao AND
                  FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                  FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                  FP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                  FP.NuMesReferencia =PKGPAG_VAR.vgFolha.NuMesReferencia
            ORDER BY FP.NuAnoReferencia DESC, FP.NuMesReferencia DESC , FP.DtCalculo DESC)
    WHERE ROWNUM < 2;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormal := 0;

  END;

  PKGPAG_VAR.vDtCalculo        := pDtCalculo;

  --------------------------------------------------------------------------------------------
  -- Seleciona a data do calculo anterior, caso nao seja encontrada
  -- assume-se o primeiro dia do mes anterior
  --------------------------------------------------------------------------------------------

  BEGIN

    SELECT CdFolhaPagamento,
           DtCalculo
      INTO PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt,
           PKGPAG_VAR.vDtCalculoAnt
      FROM ( SELECT CdFolhaPagamento,
                    DtCalculo
               FROM EPagFolhaPagamento FP
              WHERE FP.CdOrgao = PKGPAG_VAR.vgFolha.CdOrgao AND
                    FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                    FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                    FP.DtCalculo < pDtCalculo AND
                    ((FP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                    FP.NuMesReferencia < PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                    FP.NuAnoReferencia < PKGPAG_VAR.vgFolha.NuAnoReferencia)
             ORDER BY FP.NuAnoReferencia DESC, FP.NuMesReferencia DESC , FP.DtCalculo DESC)
    WHERE ROWNUM < 2;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

     PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt := 0;

  END;

  ----------------------------------------------------------------------------
  -- Trata Excecao no caso de folha de ferias
  ----------------------------------------------------------------------------

  IF PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaFerias THEN

    BEGIN

     SELECT CdFolhaPagamento
       INTO PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt
       FROM ( SELECT CdFolhaPagamento
                FROM EPagFolhaPagamento FP
                INNER JOIN EPagTipoFolhaPagamento TFP
                   ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
               WHERE FP.CdOrgao = PKGPAG_VAR.vgFolha.CdOrgao AND
                     FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                     TFP.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal AND
                     FP.DtCalculo < pDtCalculo AND
                     ((FP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                     FP.NuMesReferencia < PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                     FP.NuAnoReferencia < PKGPAG_VAR.vgFolha.NuAnoReferencia)
              ORDER BY FP.NuAnoReferencia DESC, FP.NuMesReferencia DESC , FP.DtCalculo DESC)
      WHERE ROWNUM < 2;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt := 0;

    END;

  END IF;

  IF PKGPAG_VAR.vDtCalculoAnt IS NULL  THEN

     PKGPAG_VAR.vDtCalculoAnt := TRUNC(PKGPAG_VAR.vgFolha.DtInicioMes -1,'MM');

  END IF;

  PKGPAG_VAR.vgFolha.DtCalculo    := PKGPAG_VAR.vDtCalculo;

  PKGPAG_VAR.vgFolha.DtCalculoAnt := PKGPAG_VAR.vDtCalculoAnt;

  /* Carrega a estrutura de carreira na variavel global vgCarreira                     */

  PCargaCarreira(pCdAgrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento);

  /* Carrega a parametrizacao da rubrica na variavel global vgRubrica                  */

  PKGPAG_VAR.vgRubrica  := FArmazenaParametrosRubrica(PKGPAG_VAR.vgFolha);

  /* Carrega as expressoes das formulas de calculo na variavel global vgFormExpr         */

  PKGPAG_VAR.vgFormExpr := FExprFormulaCalculo(PKGPAG_VAR.vgFolha);

  /* Carrega os valores de referencia */

  PKGPAG_VAR.vgValorReferencia := FRetornaValorReferencia(PKGPAG_VAR.vgFolha);

  /*Carrega as tabelas de aliquotas do IPESC*/

  PKGPAG_VAR.vAliqIPESCAtivo   := PKGPAG_GERAL.FRetornaAliquotaIPESC(PKGPAG_TIPO.cnTpTrbAtivo,
                                              PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                              PKGPAG_VAR.vgFolha.NuMesReferencia);

  PKGPAG_VAR.vAliqIPESCInativo := PKGPAG_GERAL.FRetornaAliquotaIPESC(PKGPAG_TIPO.cnTpTrbInativo,
                                              PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                              PKGPAG_VAR.vgFolha.NuMesReferencia);

  PKGPAG_VAR.vAliqIPESCParcial := PKGPAG_GERAL.FRetornaAliquotaIPESC(PKGPAG_TIPO.cnTpTrbParcial,
                                              PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                              PKGPAG_VAR.vgFolha.NuMesReferencia);

  /*Carrega as tabelas de aliquotas do CPSM*/

  pkgpag_var.vAliqCPSM := PKGPAG_GERAL.FRetornaAliquotaCPSM(pkgpag_tipo.cnTpTrbAtivo,
                                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                            PKGPAG_VAR.vgFolha.NuMesReferencia);

  /*Carrega a tabela de aliquota do IRRF*/

  PKGPAG_VAR.vAliquotaIRRF      := PKGPAG_GERAL.FRetornaAliquotaIRRF( PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                      PKGPAG_VAR.vgFolha.NuMesReferencia);

  PKGPAG_VAR.vAliqINSS         := PKGPAG_GERAL.FRetornaAliquotaINSS( PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                     PKGPAG_VAR.vgFolha.NuMesReferencia);

  /*Carrega a alíquota única para contribuintes individuais */

  PKGPAG_VAR.vAliqInssContribIndiv := 0.1100;

  /*Carrega parametros de acumulacao de ATS */

  PKGPAG_VAR.vgParamATSAcum := FRetornaParamATS (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                 PKGPAG_VAR.vgFolha.CdOrgao,
                                                 PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                 PKGPAG_VAR.vgFolha.NuMesReferencia);

  PAtribuiCodigoTotalizadoras(pCdAgrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                              pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao);

  /* Carrega os parametros de pagamento do agrupamento variavel global vgParamPagamento   */

  PParamPagamento(PKGPAG_VAR.vgFolha.CdAgrupamento,
                  PKGPAG_VAR.vgFolha.NuAnoReferencia,
                  PKGPAG_VAR.vgFolha.NuMesReferencia);

  /* Carrega os parametros do orgao  */

  PKGPAG_VAR.vgParamOrgao := FOrgaoParam(PKGPAG_VAR.vgFolha.CdOrgao,
                                         PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                         PKGPAG_VAR.vgFolha.NuMesReferencia);

  -- Variaveis de rubricas utilizadas na TRIBUTACAO

  /* Retorna o codigo da rubrica de diferenca de desconto no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDifDescIRRF :=

    PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                           PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                           PKGPAG_VAR.vgFolha.NuMesReferencia,
                                           PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF,
                                           PKGPAG_TIPO.cnTpRubDifDesc);

  /* Retorna o codigo da rubrica de devolucao de desconto no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDevDescIRRF :=

     PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                            PKGPAG_VAR.vgFolha.NuMesReferencia,
                                            PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF,
                                            PKGPAG_TIPO.cnTpRubDevDesc);

  /* Retorna o codigo da rubrica de diferenca de desconto sobre 13no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDifDescIRRF13 :=

    PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                           PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                           PKGPAG_VAR.vgFolha.NuMesReferencia,
                                           PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobre13,
                                           PKGPAG_TIPO.cnTpRubDifDesc);

  /* Retorna o codigo da rubrica de devolucao de desconto sobre 13 no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDevDescIRRF13 :=

     PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                            PKGPAG_VAR.vgFolha.NuMesReferencia,
                                            PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobre13,
                                            PKGPAG_TIPO.cnTpRubDevDesc);

  /* Retorna o codigo da rubrica de diferenca de desconto sobre ferias no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDifDescIRRFFerias :=

    PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                           PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                           PKGPAG_VAR.vgFolha.NuMesReferencia,
                                           PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias,
                                           PKGPAG_TIPO.cnTpRubDifDesc);

  /* Retorna o codigo da rubrica de devolucao de desconto sobre de IRRF ferias no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDevDescIRRFFerias :=

     PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                            PKGPAG_VAR.vgFolha.NuMesReferencia,
                                            PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias,
                                            PKGPAG_TIPO.cnTpRubDevDesc);

  /*  Retorna o codigo da rubrica de diferenca de desconto de INSS no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDifDescINSS :=

     PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                            PKGPAG_VAR.vgFolha.NuMesReferencia,
                                            PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescINSS,
                                            PKGPAG_TIPO.cnTpRubDifDesc);

  /* Retorna o codigo da rubrica de devolucao de desconto de INSS no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDevDescINSS :=

    PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                           PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                           PKGPAG_VAR.vgFolha.NuMesReferencia,
                                           PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescINSS,
                                           PKGPAG_TIPO.cnTpRubDevDesc);

  /*  Retorna o codigo da rubrica de diferenca de desconto de INSS no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDifDescINSS13 :=

     PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                            PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                            PKGPAG_VAR.vgFolha.NuMesReferencia,
                                            PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                                            PKGPAG_TIPO.cnTpRubDifDesc);

  /* Retorna o codigo da rubrica de devolucao de desconto de INSS no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDevDescINSS13 :=

    PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                           PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                           PKGPAG_VAR.vgFolha.NuMesReferencia,
                                           PKGPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                                           PKGPAG_TIPO.cnTpRubDevDesc);

  IF PKGPAG_VAR.vgParamPagamento.CdAgrupamentoParametro IS NOT NULL THEN

    PArmazenaCCOParametro(pCdAgrupamentoParametro =>PKGPAG_VAR.vgParamPagamento.CdAgrupamentoParametro);

  END IF;

  /* Retorna o codigo da rubrica de diferenca de desconto do IPESC no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDifDescIPESC := PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                              PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                              PKGPAG_VAR.vgFolha.NuMesReferencia,
                                                              PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIPESC,
                                                              PKGPAG_TIPO.cnTpRubDifDesc);

  /* Retorna o codigo da rubrica de devolucao de desconto do IPESC no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDevDescIPESC := PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                           PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                           PKGPAG_VAR.vgFolha.NuMesReferencia,
                                           PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIPESC,
                                           PKGPAG_TIPO.cnTpRubDevDesc);

  /* Retorna o codigo da rubrica de diferenca de desconto do IPESC 2008 no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDifDescIPESC2008 := PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                PKGPAG_VAR.vgFolha.NuMesReferencia,
                                                PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIPESCJul2008,
                                                PKGPAG_TIPO.cnTpRubDifDesc);

  /* Retorna o codigo da rubrica de devolucao de desconto do IPESC 2008 no Agrupamento */

  PKGPAG_VAR.vgCdRubAgrupDevDescIPESC2008 := PKGPAG_GERAL.FRetornaRubricaOutroTipo (PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                 PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                 PKGPAG_VAR.vgFolha.NuMesReferencia,
                                                 PKGPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIPESCJul2008,
                                                 PKGPAG_TIPO.cnTpRubDevDesc);

  /* Carrega as expressoes das bases de calculo na variavel global vgBaseExpr              */

  PKGPAG_VAR.vgBaseExpr := FExprBaseCalculo(PKGPAG_VAR.vgFolha);

  IF PKGPAG_VAR.vgFolha.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal,
                                          PKGPAG_TIPO.cnTpCalculoRecalculoMes,
                                          PKGPAG_TIPO.cnTpCalculoSimulacao,
                                          PKGPAG_TIPO.cnTpCalculoRetroativo,
                                          PKGPAG_TIPO.cnTpCalculoDifMes -- Calcula Integral e Suplementar
                                          ) THEN

    PKGPAG_VAR.vgOrgaoFeriasParam := FOrgaoFeriasParam(PKGPAG_VAR.vgFolha.CdOrgao,
                                                       pDtCalculo);

    PKGPAG_VAR.vgOrgaoFrequenciaParam := FOrgaoFrequenciaParam(PKGPAG_VAR.vgFolha.CdOrgao,
                                                               pDtCalculo);

    PKGPAG_VAR.vgIndicadorValeTransp := FRetornaParametroValeTransp(PKGPAG_VAR.vgFolha.CdOrgao,
                                                                    PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                    PKGPAG_VAR.vgFolha.NuMesReferencia);

    /* Carrega as faixas de contribuicao de Plano de Saude de Agregado */

    PArmazenarContribPSAgregado (PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                 PKGPAG_VAR.vgFolha.NuMesReferencia);

    /* Carrega os eventos na variavel global vgEvento */

    PKGPAG_VAR.vgEvento := FRetornaEventos(PKGPAG_VAR.vgFolha);

    -- Incializa variaveis que indicam a existencia de eventos

    PKGPAG_VAR.vgCdEventoDescCoPart  := NULL;

    PKGPAG_VAR.vgCdEventoRescisaoACT := NULL;

     -- Implementacao para atender a UDESC: 18/06/2012
     -- Verifica se foram parametrizados os eventos Pagamento de Hora Aula no Orgao OU Hora Atividade

    PKGPAG_VAR.bPossuiEventoHoraAulaAtiv := FALSE;

    IF PKGPAG_VAR.vgEvento.COUNT > 0 THEN

      FOR i IN PKGPAG_VAR.vgEvento.FIRST .. PKGPAG_VAR.vgEvento.LAST
      LOOP

        IF PKGPAG_VAR.vgEvento(i).CdTipoEventoPagamento IN (65,66) THEN

          PKGPAG_VAR.bPossuiEventoHoraAulaAtiv := TRUE;

        END IF;

      END LOOP;

    END IF;

    /* Carrega a lista de rubricas permitidas na folha */

    IF PKGPAG_VAR.vgFolha.FlPagaTodasRubricas = 'N' THEN

      PKGPAG_VAR.vgRubPermitidasTpFolha := FRetornaRubricasPermitidas(PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento,
                                                                      PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                      PKGPAG_VAR.vgFolha.NuMesReferencia);

    END IF;

    /* Carrega as carreiras associadas aos eventos */

    PArmazenaCarreiraEvento;

    /* Carrega as vantagens pecuniarias na variavel global vgVantagem                       */

    PKGPAG_VAR.vgVantagem := FRetornaVantagensPecuniarias(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                          PKGPAG_VAR.vgFolha.CdOrgao,
                                                          PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                          PKGPAG_VAR.vgFolha.NuMesReferencia);

    /* Carrega as regras do salario familia na variavel global vgRegraSalFamilia            */

    PKGPAG_VAR.vgRegraSalFamilia := FRetornaRegraSalFam(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                        PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                        PKGPAG_VAR.vgFolha.NuMesReferencia);

     /* Carrega registro com o periodo de apuracao de frequencia */

     PKGPAG_VAR.vgApuracaoFrequencia :=  FRetornaParametroFrequencia(PKGPAG_VAR.vgFolha.CdOrgao,
                                                                     PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                                     PKGPAG_VAR.vgFolha.NuMesReferencia);

     /* Carrega registro com parametros do auxilio alimentacao */

     PKGPAG_VAR.vgAuxilioAli := FArmazenaParametroAuxAli(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                         pDtCalculo);

     /* Carrega registro com parametros do auxilio alimentacao anterior*/

     PKGPAG_VAR.vgAuxilioAliAnt := FArmazenaParametroAuxAli(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                            PKGPAG_VAR.vDtCalculoAnt);

     /* Define o parametro dos dias uteis que devem ser considerados para o auxilio alimentacao */

     PKGPAG_VAR.vgNuTipoDiaNaoUtil := PKGPAG_GERAL.FRetornaTipoDiaNaoUtil(PKGPAG_VAR.vgFolha.CdOrgao);

     /* Recadastramento */

     PKGPAG_VAR.vgEventoRecadastramento :=  FEventoRecadastramento(PKGPAG_VAR.vgFolha.NuAnoReferencia);

     PKGPAG_VAR.vgListaTipoPNPRecad     := FTipoPensaoNaoPrevRecad(PKGPAG_VAR.vgEventoRecadastramento.CdHistEventoRecadastramento);

     --------------------------------------------------------------------------------------------
     -- Retorna o codigo da folha de 13 salario do mes anterior -> 0 se nao existe
     --------------------------------------------------------------------------------------------

     PKGPAG_VAR.vgCdFolha13Ant := FRetornaFolhaPagamento(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                         pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                         pCdTipoFolha   => PKGPAG_TIPO.cnTpFolha13,
                                                         pNuAno         => CASE PKGPAG_VAR.vgFolha.NuMesReferencia
                                                                             WHEN 1 THEN
                                                                               PKGPAG_VAR.vgFolha.NuAnoReferencia - 1
                                                                           ELSE
                                                                             PKGPAG_VAR.vgFolha.NuAnoReferencia
                                                                           END,
                                                         pNuMes         => CASE PKGPAG_VAR.vgFolha.NuMesReferencia
                                                                             WHEN 1 THEN
                                                                               12
                                                                           ELSE
                                                                             PKGPAG_VAR.vgFolha.NuMesReferencia - 1
                                                                           END,
                                                         pFlDefinitivo => 'S');

     --------------------------------------------------------------------------------------------
     --  Retorna o codigo da folha de 13 salario do mes atual 0 se nao existe
     --------------------------------------------------------------------------------------------
     PKGPAG_VAR.vgCdFolha13 := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                   pCdFolha       => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                   pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                   pCdTipoFolha   => PKGPAG_TIPO.cnTpFolha13);

     --------------------------------------------------------------------------------------------
     --  Retorna o codigo da folha de ferias
     --
     -- InPagBeneficioFerias = 1 - pagamento do usufruto no mes
     --                      = 2 - pagamento do usufruto no mes anterior
     --------------------------------------------------------------------------------------------

     IF PKGPAG_VAR.vgOrgaoFeriasParam.InPagBeneficioFerias = 1 THEN

       PKGPAG_VAR.vgCdFolhaFerias := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                         pCdFolha       => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                         pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                         pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaFerias);

     ELSE

       PKGPAG_VAR.vgCdFolhaFerias := FRetornaFolhaPagamento(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                            pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                            pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaFerias,
                                                            pNuAno         => CASE PKGPAG_VAR.vgFolha.NuMesReferencia
                                                                                WHEN 1 THEN
                                                                                  PKGPAG_VAR.vgFolha.NuAnoReferencia - 1
                                                                              ELSE
                                                                                PKGPAG_VAR.vgFolha.NuAnoReferencia
                                                                              END,
                                                            pNuMes         => CASE PKGPAG_VAR.vgFolha.NuMesReferencia
                                                                                WHEN 1 THEN
                                                                                  12
                                                                              ELSE
                                                                                PKGPAG_VAR.vgFolha.NuMesReferencia - 1
                                                                              END);
     END IF;

     ------------------------------------------
     -- Retorna o código da folha indenizatória
     -------------------------------------------
     IF PKGPAG_VAR.vgFolha.cdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal THEN
       
       PKGPAG_VAR.vgCdFolhaIndenizatoria := FRetornaFolhaPagamento(pCdOrgao              => pCdOrgaoVinc,                                                               
                                                                   pCdTipoCalculo        => PKGPAG_TIPO.cnTpCalculoNormal,
                                                                   pCdTipoFolha          => PKGPAG_TIPO.cnTpFolhaOutras,
                                                                   pNuAno                => PKGPAG_VAR.vgFolha.nuAnoReferencia,
                                                                   pNuMes                => PKGPAG_VAR.vgFolha.nuMesReferencia,
                                                                   pFlDefinitivo         => (CASE 
                                                                                           WHEN PKGPAG_VAR.vgFolha.flCalculoDefinitivo = 'S' THEN
                                                                                             'S'
                                                                                           ELSE
                                                                                             NULL
                                                                                         END),
                                                                   pCdTipoFolhaPagamento => 1766);
       
     END IF;

  END IF;

  IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoSupl OR
     PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes THEN -- Calcula Integral e Suplementar

     /* Busca dados da folha origem */

     IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes THEN

        PKGPAG_VAR.vgFolha.CdFolhaOrigem   := PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormal;

      END IF;

     OPEN PKGPAG_VAR.cFolha(PKGPAG_VAR.vgFolha.CdFolhaOrigem);

     FETCH PKGPAG_VAR.cFolha INTO PKGPAG_VAR.vgFolhaOrigem;

     CLOSE PKGPAG_VAR.cFolha;

     PKGPAG_VAR.vgFolhaOrigemAux := PKGPAG_VAR.vgFolhaOrigem;

     /* Busca dados da folha de recalculo */

     IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoDifMes THEN -- a folha de Recalculo e a mesma folha do calculo

        PKGPAG_VAR.vgFolhaRecalculo := PKGPAG_VAR.vgFolha;

        -- A parametrizacao de rubrica ja foi feita, entao nao precisa alimentar a vgRubrica

     ELSE

        OPEN PKGPAG_VAR.cFolha(PKGPAG_VAR.vgFolha.CdFolhaVincSupl);

        FETCH PKGPAG_VAR.cFolha INTO PKGPAG_VAR.vgFolhaRecalculo;

        CLOSE PKGPAG_VAR.cFolha;

        /* Carrega a parametrizacao da rubrica na variavel global vgRubrica                     */

        PKGPAG_VAR.vgRubrica  := FArmazenaParametrosRubrica(PKGPAG_VAR.vgFolhaOrigem);

     END IF;

     -- Caso existam folhas suplementares em definitivo a variavel abaixo e setada com TRUE e
     -- utilizada na rotina PKGPAG_CAL.FRetornaFolhaComPagamento

     PKGPAG_VAR.bPossuiFolhaSuplDef := FPossuiFolhaSuplDef(PKGPAG_VAR.vgFolhaRecalculo.CdOrgao,
                                                           PKGPAG_VAR.vgFolhaRecalculo.NuAnoReferencia,
                                                           PKGPAG_VAR.vgFolhaRecalculo.NuMesReferencia,
                                                           PKGPAG_VAR.vgFolhaRecalculo.CdTipoFolhaPagamento);

  END IF;

  PKGPAG_VAR.vgRubricaExcludente :=

                       FRetornaRubricasExcludentes (PKGPAG_VAR.vgFolha.CdOrgao,
                                                    PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                    PKGPAG_VAR.vgFolha.NuMesReferencia);

  IF PKGPAG_VAR.vgCdRubDepositoJud = 0 THEN

     PKGPAG_VAR.vgCdRubDepositoJud := 0;

  END IF;

  PKGPAG_RT.SetaRubDifDescIPREV(PKGPAG_VAR.vgFolha.CdAgrupamento);

  BEGIN

    -- Descobre a ordem de desconto

    SELECT PC.CdOrdemDesconto
      INTO PKGPAG_VAR.vgOrdemDescConsig
      FROM Epagparametrobaseconsignacao PC
     INNER JOIN Epagparametrobaseconsigagrup PCA
        ON PC.Cdparametrobaseconsignacao = PCA.Cdparametrobaseconsignacao
     WHERE PCA.CdAgrupamento = PKGPAG_VAR.vgFolha.CdAgrupamento;

  EXCEPTION

   WHEN NO_DATA_FOUND THEN

      PKGPAG_VAR.vgOrdemDescConsig := 0;

  END;

  /*----------------------------------------------------------------*/
  -- Leitura dos parametros de aquisicao de tempos de servico
  /*----------------------------------------------------------------*/

  PKGPAG_PC.PParamAdcTempServ( pCdAgrupamento     => PKGPAG_VAR.vgFolha.CdAgrupamento,
                               pCdOrgao           => PKGPAG_VAR.vgFolha.CdOrgao,
                               pNuAnoReferencia   => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                               pNuMesReferencia   => PKGPAG_VAR.vgFolha.NuMesReferencia);

  /*----------------------------------------------------------------*/
   -- Leitura dos parametros de licenca premio
  /*----------------------------------------------------------------*/

  PKGPAG_PC.PParamAdcLicPre( pCdOrgao           => PKGPAG_VAR.vgFolha.CdOrgao,
                             pCdTipoAdicional   => 1,
                             pDtCalculo         => pDtCalculo);

  /*----------------------------------------------------------------*/
   -- Leitura dos parametros de premio assiduidade
  /*----------------------------------------------------------------*/

  PKGPAG_PC.PParamAdcLicPre( pCdOrgao           => PKGPAG_VAR.vgFolha.CdOrgao,
                             pCdTipoAdicional   => 2,
                             pDtCalculo         => pDtCalculo);

  /*----------------------------------------------------------------*/
   -- Leitura dos parametros de ferias
  /*----------------------------------------------------------------*/

  PKGPAG_PC.PParamPerAquisFerias(pCdOrgao  => PKGPAG_VAR.vgFolha.CdOrgao,
                                 pDtFimMes => PKGPAG_VAR.vgFolha.DtFimMes);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de 1 salario
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrup1001 := PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                              1,
                                                              1);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de 13 salario associado ao evento 46
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrup13 := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,46);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de 13 salario de CTISP associado ao evento 67
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrup13CTISP := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,67);


  ----------------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de adiantamento 13 salario de CTISP associado ao evento 68
  ----------------------------------------------------------------------------------------

  pkgpag_var.vgCdRubAdiant13CTISP := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,68);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica alternativa de 13 salario
  -- Utilizada na SC Parcerias quando a relacao de trabalho e DIRETOR/PRESIDENTE
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrup13Alt := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                     46,
                                                                     PKGPAG_TIPO.cnS);

  ----------------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de devolucao de 13 salario associado ao evento 47, 91 Ctisp
  ----------------------------------------------------------------------------------------
  begin
  if  PKGPAG_VAR.vgFolha.CdTipoFolha in (pkgpag_tipo.cnTpFolhaCtisp13,
                                         pkgpag_tipo.cnTpFolhaAdiant13Ctisp,
                                         pkgpag_tipo.cnTpFolhaCtisp) then

      PKGPAG_VAR.vgCdRubricaDevAnt13 := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,91);

  else

      PKGPAG_VAR.vgCdRubricaDevAnt13 := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,47);
  end if;
    exception
      when others
        then
          PKGPAG_VAR.vgCdRubricaDevAnt13 := null;
  end;


  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de antecipacao de 13 salario
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrupAntecip13 := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                         51);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de 13 salario de CTISP associado ao evento 68
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrupAntecip13CTISP := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                              68);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de Desc. Dias Afastados
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrupDescDiasAfast := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                             11);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica alternativa de antecipacao de 13 salario
  -- Utilizada na SC Parcerias quando a relacao de trabalho e DIRETOR/PRESIDENTE
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgCdRubAgrupAntecip13Alt := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                            51,
                                                                            PKGPAG_TIPO.cnS);

   ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de Desc. Faltas Mes Atual
  ----------------------------------------------------------------------------------

 PKGPAG_VAR.vgCdRubEvento82 := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                             82);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica de Desc. Faltas Mes Anterior
  ----------------------------------------------------------------------------------

 PKGPAG_VAR.vgCdRubEvento81 := PKGPAG_GERAL.FRetornaCodigoRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                             81);

  ----------------------------------------------------------------------------------
  -- Busca o codigo da rubrica VALOR INSS PATRONAL BRUTO
  ----------------------------------------------------------------------------------

 PKGPAG_VAR.vgCdRubVlINSSPatronalBruto := PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                              9,
                                                              1666);

  ----------------------------------------------------------------------------------
  -- Carrega dados para calculo de Auxilio Creche
  ----------------------------------------------------------------------------------

  PKGPAG_VAR.vgAuxCreche.DELETE;

  FOR rec in PKGPAG_VAR.cAuxCreche (pNuAnoReferencia => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                    pNuMesReferencia => PKGPAG_VAR.vgFolha.NuMesReferencia) LOOP

      PKGPAG_VAR.vgAuxCreche (rec.CdOrgao).CdOrgao              := rec.CdOrgao;
      PKGPAG_VAR.vgAuxCreche (rec.CdOrgao).CdBaseCalculo        := rec.cdBaseCalculo;
      PKGPAG_VAR.vgAuxCreche (rec.CdOrgao).CdValorRefLimite     := rec.CdValorRefLimite;
      PKGPAG_VAR.vgAuxCreche (rec.CdOrgao).QtUnidValorRefLimite := rec.QtUnidValorRefLimite;
      PKGPAG_VAR.vgAuxCreche (rec.CdOrgao).NuIdadeMaxDependente := rec.NuIdadeMaxDependente;

      OPEN PKGPAG_VAR.cAuxCrecheFaixa (pNuAnoReferencia => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                       pNuMesReferencia => PKGPAG_VAR.vgFolha.NuMesReferencia,
                                       pCdOrgao         => rec.CdOrgao);

      FETCH PKGPAG_VAR.cAuxCrecheFaixa BULK COLLECT INTO PKGPAG_VAR.vgAuxCreche (rec.CdOrgao).faixa;

      CLOSE PKGPAG_VAR.cAuxCrecheFaixa;

  END LOOP;

  /*----------------------------------------------------------------*/
  -- Leitura dos parametros para tipos de folha de 13
  /*----------------------------------------------------------------*/

  IF PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13,
                                        PKGPAG_TIPO.cnTpFolhaAdiant13,
                                        PKGPAG_TIPO.cnTpFolhaResidente13,
                                        pkgpag_tipo.cnTpFolhaCtisp13,
                                        pkgpag_tipo.cnTpFolhaAdiant13Ctisp,
                                        pkgpag_tipo.cnTpFolhaProdex13,
                                        pkgpag_tipo.cnTpFolhaHonorarios13,
                                        pkgpag_tipo.cnTpFolhaHonorarProcuradores13) THEN

     IF PKGPAG_VAR.vgFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolha13,
                                           PKGPAG_TIPO.cnTpFolhaAdiant13) THEN

       ----------------------------------------------------------------------------------
       -- Seleciona o codigo da folha do tipo normal/residente, calculo normal
       -- do ano/mes de competencia
       ----------------------------------------------------------------------------------

       PKGPAG_VAR.vgCdFolhaNormal := FRetornaFolhaPagamento(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                            pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                            pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaNormal,
                                                            pNuAno         => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                            pNuMes         => PKGPAG_VAR.vgFolha.NuMesReferencia);

       ----------------------------------------------------------------------------------
       -- Seleciona o codigo da folha suplementar e caso exista,
       -- seleciona o codigo da folha de recalculo
       ----------------------------------------------------------------------------------

       PKGPAG_VAR.vgCdFolhaRecalculo := 0;

       PKGPAG_VAR.vgCdFolhaSuplementar := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                              pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                              pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoSupl,
                                                              pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaNormal,
                                                              pFlDefinitiva  => 'S');

       IF PKGPAG_VAR.vgCdFolhaSuplementar > 0 THEN

        PKGPAG_VAR.vgCdFolhaRecalculo := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                             pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                             pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoRecalculoMes,
                                                             pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaNormal,
                                                             pFlDefinitiva  => 'N');

      END IF;

      ----------------------------------------------------------------------------------
      -- Seleciona o codigo da maior folha do tipo normal, calculo de 13
      ----------------------------------------------------------------------------------

      PKGPAG_VAR.vgCdFolha13 := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                    pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                    pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                    pCdTipoFolha   => PKGPAG_TIPO.cnTpFolha13);

    elsif  PKGPAG_VAR.vgFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolhaCtisp13,pkgpag_tipo.cnTpFolhaAdiant13Ctisp) then

       PKGPAG_VAR.vgCdFolhaNormal := FRetornaFolhaPagamento(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                            pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                            pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaCtisp,
                                                            pNuAno         => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                            pNuMes         => PKGPAG_VAR.vgFolha.NuMesReferencia);

       ----------------------------------------------------------------------------------
       -- Seleciona o codigo da folha suplementar e caso exista,
       -- seleciona o codigo da folha de recalculo
       ----------------------------------------------------------------------------------

       PKGPAG_VAR.vgCdFolhaRecalculo := 0;

       PKGPAG_VAR.vgCdFolhaSuplementar := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                              pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                              pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoSupl,
                                                              pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaCtisp,
                                                              pFlDefinitiva  => 'S');

       IF PKGPAG_VAR.vgCdFolhaSuplementar > 0 THEN

        PKGPAG_VAR.vgCdFolhaRecalculo := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                             pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                             pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoRecalculoMes,
                                                             pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaCtisp,
                                                             pFlDefinitiva  => 'N');

      END IF;

      ----------------------------------------------------------------------------------
      -- Seleciona o codigo da maior folha do tipo normal, calculo de 13
      ----------------------------------------------------------------------------------

      PKGPAG_VAR.vgCdFolha13 := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                    pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                    pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                    pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaCtisp13);

    elsif  PKGPAG_VAR.vgFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13) then

      if PKGPAG_VAR.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaProdex13 then
        vCdTipoFolhaPagamento := 1526;
      elsif PKGPAG_VAR.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaHonorarios13 then
        vCdTipoFolhaPagamento := 1505;
      elsif PKGPAG_VAR.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaHonorarProcuradores13 then
        vCdTipoFolhaPagamento := 1525;
      end if;

       PKGPAG_VAR.vgCdFolhaNormal := FRetornaFolhaPagamento(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                            pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                            pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaOutras,
                                                            pNuAno         => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                            pNuMes         => PKGPAG_VAR.vgFolha.NuMesReferencia,
                                                            pCdTipoFolhaPagamento => vCdTipoFolhaPagamento);

       ----------------------------------------------------------------------------------
       -- Seleciona o codigo da folha suplementar e caso exista,
       -- seleciona o codigo da folha de recalculo
       ----------------------------------------------------------------------------------

       PKGPAG_VAR.vgCdFolhaRecalculo := 0;

       PKGPAG_VAR.vgCdFolhaSuplementar := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                              pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                              pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoSupl,
                                                              pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaCtisp,
                                                              pFlDefinitiva  => 'S');

       IF PKGPAG_VAR.vgCdFolhaSuplementar > 0 THEN

        PKGPAG_VAR.vgCdFolhaRecalculo := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                             pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                             pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoRecalculoMes,
                                                             pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaCtisp,
                                                             pFlDefinitiva  => 'N');

      END IF;
      PKGPAG_VAR.vgCdFolhaSuplementar := 0;
      PKGPAG_VAR.vgCdFolhaRecalculo := 0;

      ----------------------------------------------------------------------------------
      -- Seleciona o codigo da maior folha do tipo normal, calculo de 13
      ----------------------------------------------------------------------------------

      PKGPAG_VAR.vgCdFolha13 := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                    pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                    pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                    pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaOutras,
                                                    pCdTipoFolhaPagamento => vCdTipoFolhaPagamento);

    ELSE

      PKGPAG_VAR.vgCdFolhaNormal := FRetornaFolhaPagamento(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                           pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                           pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaResidente,
                                                           pNuAno         => PKGPAG_VAR.vgFolha.NuAnoReferencia,
                                                           pNuMes         => PKGPAG_VAR.vgFolha.NuMesReferencia);

      ----------------------------------------------------------------------------------
      -- Seleciona o codigo da folha suplementar e caso exista,
      -- seleciona o codigo da folha de recalculo
      ----------------------------------------------------------------------------------

      PKGPAG_VAR.vgCdFolhaSuplementar := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                             pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                             pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoSupl,
                                                             pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaResidente);

      IF PKGPAG_VAR.vgCdFolhaSuplementar > 0 THEN

        PKGPAG_VAR.vgCdFolhaRecalculo := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                             pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                             pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoRecalculoMes,
                                                             pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaResidente,
                                                             pFlDefinitiva  => 'N');

      END IF;

      ----------------------------------------------------------------------------------
      -- Seleciona o codigo da maior folha do tipo normal, calculo de 13
      ----------------------------------------------------------------------------------

      PKGPAG_VAR.vgCdFolha13 := FRetornaCodigoFolha(pCdOrgao       => PKGPAG_VAR.vgFolha.CdOrgao,
                                                    pCdFolha       => PKGPAG_VAR.vgCdFolhaNormal,
                                                    pCdTipoCalculo => PKGPAG_TIPO.cnTpCalculoNormal,
                                                    pCdTipoFolha   => PKGPAG_TIPO.cnTpFolhaResidente);

    END IF;

  END IF;

  --
  -- Motivos de afastamento dos Eventos para Auxilio Alimentacao.
  --
  pkgpag_var.vgListaEventoAfast11 := FEventoAfastamento(11);

  --
  -- Motivos de afastamento dos Eventos para Rotina automatica de devolucao ao erario.
  -- Os motivos inseridos nesta lista deverao ser desprezados pela rotina
  --
  pkgpag_var.vgListaEventoAfastDevErario := FEventoAfastamento(15);

  --
  -- Lista de Rubricas de Funcao de Chefia Privativa PM
  --
  IF pkgpag_var.vgFolha.CdOrgao = 49
    THEN

    pkgpag_var.vgListaRubFuncaoPrivativa := FListaRubFuncaoPrivativa(pkgpag_var.vgFolha.CdAgrupamento);

  END IF;

END PArmazenaInfoProc;

function fCDBName return varchar2 is
  vDBName varchar2(30);
begin
   select upper(decode(sys_context('USERENV', 'CDB_NAME'), null, sys_context('USERENV','DB_UNIQUE_NAME'), sys_context('USERENV','CON_NAME')))
    into vDBName
    from dual;
  return vDBName;
end;

END PKGPAG_PARAM;
/
