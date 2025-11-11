CREATE OR REPLACE PACKAGE PKGPAG_VP IS

/*---------------------------------------------------------------------------------------------*/
--  Procedimento : PProcessaVantagemPecuniaria
--      Objetivo : Processar as vantagens pecuniarias nas relacoes de vinculo
--
--   Regras implementadas baseadas na forma de recebimento:
--
--     07) Valor gerado pelas regras de negocio de um tipo de evento;
--     09) Valor depende da faixa de enquadramento de uma base de calculo
--         (para abonos e outras vantagens correlatas);
--     11) Valor depende do indice de uma gratificacao de produtividade;

--     Regras 07, 09 sao calculadas posteriormente em ProcessaVantagemBase
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PProcessaVantagemPecuniaria(pFolha      IN PKGPAG_TIPO.rFolha,
                                      pCdVinculo  IN INTEGER,
                                      pRubrica    IN PKGPAG_TIPO.tRubrica,
                                      pVantagem   IN PKGPAG_TIPO.tVantagemPecuniaria,
                                      pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo,
                                      pDtCalculo  IN DATE);

END PKGPAG_VP;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_VP IS

 TYPE rValor IS RECORD
    (vlIntegral  NUMBER(13,2),
     vlIndice    NUMBER(13,4));

 vBpossuiCTISP BOOLEAN := FALSE;

 vVlIndiceTotal NUMBER;

FUNCTION FDiasAfastamento(pDtInicioMes IN DATE,
                          pDtFimMes    IN DATE,
                          pCdHistVantagemPecuniaria IN INTEGER,
                          pCdVinculo IN INTEGER)

    RETURN INTEGER IS

    vNuDiasAfast INTEGER;

BEGIN

   vNuDiasAfast := 0;

    FOR rec IN (SELECT (DtFim - DtInicio) + 1 as NuDiasAfast
                  FROM
                (SELECT CASE
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
                 INNER JOIN EBpcMotAfaTempVPFormaPag FP
                    ON AF.CdMotivoAfastTemporario = FP.CdMotivoAfastTemporario
                 WHERE AF.CdVinculo = pCdVinculo AND
                       FP.CdHistVantagemPecuniaria = pCdHistVantagemPecuniaria AND
                       AF.DtInicio <= pDtFimMes AND
                       (AF.DtFim >= pDtInicioMes OR AF.DtFim IS NULL) AND
                       AF.FlAnulado = 'N') )
     LOOP

       vNuDiasAfast := vNuDiasAfast + rec.NuDiasAfast;

     END LOOP;

     RETURN LEAST(vNuDiasAfast,30);

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;

    WHEN OTHERS THEN

      RETURN 0;

  END;

 /*---------------------------------------------------------------------------------------------*/
--     Funcao : FRetornaMediaHoraPlantao
--   Objetivo :
--
/*---------------------------------------------------------------------------------------------*/

  FUNCTION FRetornaMediaHoraPlantao(pFolha                    IN PKGPAG_TIPO.rFolha,
                                    pCdVinculo                IN INTEGER,
                                    pDtAdmissao               IN DATE,
                                    pCdHistVantagemPecuniaria IN INTEGER,
                                    pCdOutraRubrica           IN INTEGER,
                                    pFlContMesNaoAfastado     IN CHAR,
                                    pNuPeriodo                IN INTEGER)
    RETURN NUMBER IS

    vNuMes             INTEGER;
    vNuAno             INTEGER;
    vDtMesInicioAnt    DATE;
    vDtMesFimAnt       DATE;
    vVlIndice          NUMBER;
    vVlIndiceAcumulado NUMBER;
    vVlIndiceAcumHora  NUMBER;
    vVlIndiceAcumMin   NUMBER;
    vNuMesesAcumulado  INTEGER;
    vVlMinuto          INTEGER;
    vVlHora            INTEGER;
    vDiasAfastado      INTEGER;
    vVlIndiceOutraRub  NUMBER;
    vCdRubSobreaviso   INTEGER;
    vNuMaxMesesVinculo INTEGER;
    vAnoMesFim         CHAR(6);

    FUNCTION fIndiceOutraRubrica(pFolha          IN PKGPAG_TIPO.rFolha,
                                 pCdVinculo      IN INTEGER,
                                 pCdOutraRubrica IN INTEGER)

     RETURN NUMBER IS

      vIndice NUMBER(13, 2);

    BEGIN

      SELECT sum(f.vlindice)
        INTO vIndice
        FROM epaglancamentofinanceiro f
       WHERE F.CdVinculo = pCdVinculo
         AND F.DtInicioDireito <= pFolha.dtFimMes
         AND (F.DtFimdireito >= pFolha.DtInicioMes OR
             F.DtFimDireito IS NULL)
         AND F.FlAnulado = PKGPAG_TIPO.cnN
         AND F.Cdrubricaagrupamento = pCdOutraRubrica;

      RETURN vIndice;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN
        RETURN 0;

    END;
    --
    -- Retorna o numero maximo de meses a retroagir do vinculo para o calculo da media
    --
    FUNCTION fMaxMesesVinculo(pCdVinculo                IN INTEGER,
                              pCdRubrica                IN INTEGER,
                              pAnoMesFim                IN CHAR,
                              pFlContMesNaoAfastado     IN CHAR,
                              pCdHistVantagemPecuniaria IN INTEGER,
                              pNuPeriodo                IN INTEGER)

     RETURN NUMBER IS

      vNumVezes INTEGER := 0;

      vDtIni DATE;

      vDtFim DATE;

      vVlIndiceAcumulado NUMBER := 0;

      vVlMinuto INTEGER := 0;

      vVlHora INTEGER := 0;

      --vVlHoraOutra       INTEGER := 0;

      --vVlMinutoOutra     INTEGER := 0;

      --vVlIndiceOutra     NUMBER := 0;

      vVlIndiceMaximo NUMBER := 0;

      vListaAfast pkgpag_tipo.tLista;

      vListaNull pkgpag_tipo.tLista;

      vDtIniAfa date;

      vDtFimAfa date;

      vNuMesesAfast integer := 0;

    BEGIN

      vVlIndiceOutraRub := NVL(fIndiceOutraRubrica(pkgpag_var.vgFolha,
                                                   pCdVinculo,
                                                   pCdRubrica),
                               0);

      CASE
      --
      -- Limitar em 40hs a soma de horas extras + media
      --
        WHEN pkgpag_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                          pcdtiporubrica => 1,
                                          pNuRubrica     => 1035) =
             pCdOutraRubrica

         THEN

          IF vVlIndiceOutraRub >= 4000 THEN

            RETURN 0;

          ELSE

            vVlIndiceMaximo := 4000;

          END IF;

        WHEN pkgpag_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                          pcdtiporubrica => 1,
                                          pNuRubrica     => 1078) =
             pCdOutraRubrica

         THEN

          IF vVlIndiceOutraRub >= 7200 THEN

            RETURN 0;

          ELSE

            vVlIndiceMaximo := 7200;

          END IF;

      END CASE;

      -- Verificar se tem afastamentos dentro do periodo e que nao estao na lista dos permitidos

      if pFlContMesNaoAfastado = pkgpag_tipo.cnS and
         pkgpag_var.vgAfastTempRemun.Count > 0 then

        vListaAfast := vListaNull;

        vNuMesesAfast := 0;

        for afa in (select fp.cdmotivoafasttemporario
                      from EBpcMotAfaTempVPFormaPag FP
                     WHERE FP.CdHistVantagemPecuniaria =
                           pCdHistVantagemPecuniaria) loop

          vListaAfast(afa.cdmotivoafasttemporario) := afa.cdmotivoafasttemporario;

        end loop;

        vDtIniAfa := add_months(pkgpag_var.vgFolha.DtInicioMes, -pNuPeriodo);

        vDtFimAfa := add_months(pkgpag_var.vgFolha.DtFimMes, -1);

        for i IN pkgpag_var.vgAfastTempRemun.FIRST .. pkgpag_var.vgAfastTempRemun.LAST

         loop

          if not
              vListaAfast.EXISTS(pkgpag_var.vgAfastTempRemun(i).CdMotivoAfastamento) then

            select vNuMesesAfast +
                   months_between(least(vDtFimAfa,
                                        nvl(pkgpag_var.vgAfastTempRemun(i).DtFimAfa,
                                            vDtFimAfa)),
                                  greatest(vDtIniAfa,
                                           pkgpag_var.vgAfastTempRemun(i).DtInicioAfa))
              into vNuMesesAfast
              from dual;

            vDtFimAfa := pkgpag_var.vgAfastTempRemun(i).DtFimAfa;

          end if;

        end loop;

        if vNuMesesAfast >= pNuPeriodo then
          return 0;
        end if;

      end if;

      FOR Meses IN (SELECT DISTINCT Ev.Nuanomesreferencia, Ev.Vlindice
                      FROM EPagEventoVinculo EV
                     WHERE EV.CdVinculo = pCdVinculo
                       AND EV.NuAnoMesReferencia <= pAnoMesFim
                       AND EV.CdTipoEventoVinculo = 2
                       AND NVL(EV.CdRubricaAgrupamento, 0) = pCdRubrica
                       AND EV.VLINDICE IS NOT NULL
                     ORDER BY ev.nuanomesreferencia DESC) LOOP

        IF vNumVezes >= pNuPeriodo THEN
          EXIT;
        END IF;

        --vDtIni := '01' || substr(Meses.Nuanomesreferencia,5,2) || substr(Meses.Nuanomesreferencia,1,4); -- que gambiarra
        vDtIni := to_date(to_char(Meses.Nuanomesreferencia) || '01',
                          'YYYYMMDD');

        vDtFim := last_day(vDtIni);

        IF pFlContMesNaoAfastado = 'N' OR
           fDiasAfastamento(vDtIni,
                            vDtFim,
                            pCdHistVantagemPecuniaria,
                            pCdVinculo) = 0 THEN

          vNumVezes := vNumVezes + 1;

          IF NVL(Meses.Vlindice, 0) <> 0 THEN

            IF vDiasAfastado < 30

             THEN

              Meses.Vlindice := TRUNC(Meses.Vlindice / 30 * vDiasAfastado,
                                      0);

              IF (Meses.Vlindice + vVlIndiceOutraRub) > vVlIndiceMaximo THEN

                Meses.VlIndice := vVlIndiceMaximo - vVlIndiceOutraRub;

              END IF;

            ELSE

              Meses.VlIndice := Meses.VlIndice - vVlIndiceOutraRub;

            END IF;

            vVlHora := NVL(SUBSTR(TRUNC(Meses.VlIndice),
                                  -LENGTH(TRUNC(Meses.VlIndice)),
                                  LENGTH(TRUNC(Meses.VlIndice)) - 2),
                           0) * 60;

            vVlMinuto := NVL((SUBSTR(TRUNC(Meses.VlIndice),
                                     LENGTH(TRUNC(Meses.VlIndice)) - 1,
                                     2)),
                             0);

            vVlIndiceAcumulado := vVlIndiceAcumulado + vVlHora + vVlMinuto;

            --DBMS_OUTPUT.put_line('Ano/Mes: '|| vNuAno||'/'|| vNuMes || '  -  ' || trunc(vVlHora/60)||':'||vVlMinuto);

          END IF;

        END IF;

      END LOOP;

      vVlIndiceTotal := vVlIndiceAcumulado;

      RETURN vNumVezes;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN

        RETURN 0;

    END;

  BEGIN

    vCdRubSobreaviso := pkgpag_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                     pcdtiporubrica => 1,
                                                     pNuRubrica     => 0069);
  /*
     IF pCdOutraRubrica = vCdRubSobreaviso
        AND PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                              pcdvinculo => pcdvinculo,
                                              pcdrubrica => vCdRubSobreaviso) = 0 THEN
        RETURN 0;
    END IF;*/

    vDtMesInicioAnt := ADD_MONTHS(pFolha.DtInicioMes, -1);
    vDtMesFimAnt    := LAST_DAY(vDtMesInicioAnt);

    vNuMes := TO_NUMBER(TO_CHAR(vDtMesInicioAnt, 'MM'));
    vNuAno := TO_NUMBER(TO_CHAR(vDtMesInicioAnt, 'YYYY'));

    vNuMesesAcumulado  := 0;
    vVlIndiceAcumulado := 0;
    vVlIndiceOutraRub  := 0;

    -- Caso esteja afastado por motivo parametrizado na vantagem no mes anterior,
    -- entra na rotina para gerar o indice

    vDiasAfastado := FDiasAfastamento(vDtMesInicioAnt,
                                      vDtMesFimAnt,
                                      pCdHistVantagemPecuniaria,
                                      pCdVinculo);

    IF vDiasAfastado > 0 THEN

      IF pCdOutraRubrica IN
         (pkgpag_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                       pcdtiporubrica => 1,
                                       pNuRubrica     => 1078),
          pkgpag_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                       pcdtiporubrica => 1,
                                       pNuRubrica     => 1035))

       THEN

        vAnoMesFim := to_char(vDtMesInicioAnt - 1, 'YYYYMM');

        vNuMaxMesesVinculo := fMaxMesesVinculo(pCdVinculo,
                                               pCdOutraRubrica,
                                               vAnoMesFim,
                                               pFlContMesNaoAfastado,
                                               pCdHistVantagemPecuniaria,
                                               pNuPeriodo);

        vVlIndiceAcumulado := NVL(vVlIndiceTotal, 0);

      ELSE

        vNuMaxMesesVinculo := pNuPeriodo;

        WHILE (vNuMesesAcumulado < pNuPeriodo) AND
              pDtAdmissao <= vDtMesInicioAnt LOOP

          -- Caso no mes anterior NAO esteja afastado por motivo parametrizado
          --  ou o parametro indique que deve contabilizar qualquer mes independente de afastamento

          vNuMes := TO_CHAR(vDtMesInicioAnt, 'MM');

          vNuAno := TO_CHAR(vDtMesInicioAnt, 'YYYY');

          vDtMesInicioAnt := ADD_MONTHS(vDtMesInicioAnt, -1);

          vDtMesFimAnt := LAST_DAY(vDtMesInicioAnt);

          vVlHora := 0;

          vVlMinuto := 0;

          IF vCdRubSobreaviso = pCdOutraRubrica
            AND vNuMes = TO_CHAR(ADD_MONTHS(pFolha.DtCalculoAnt, -12), 'MM')
            AND vNuAno = TO_CHAR(ADD_MONTHS(pFolha.DtCalculoAnt, -12), 'YYYY')
            AND vVlIndiceAcumulado = 0
            THEN
              --para o pagamento da média de sobreaviso deverá ter recebido sobreaviso nos ultimos 12 meses
              RETURN 0;
          END IF;

          IF pFlContMesNaoAfastado = 'N' OR
             FDiasAfastamento(vDtMesInicioAnt,
                              vDtMesFimAnt,
                              pCdHistVantagemPecuniaria,
                              pCdVinculo) = 0 THEN

            BEGIN

              SELECT SUM(VlIndice)
                INTO vVlIndice
                FROM EPagEventoVinculo EV
               WHERE EV.CdVinculo = pCdVinculo
                 AND EV.NuAnoMesReferencia = (vNuAno * 100 + vNuMes)
                 AND EV.CdTipoEventoVinculo = 2
                 AND EV.CdRubricaAgrupamento = pCdOutraRubrica;

              /*IF (vVlIndice > 0 AND vCdRubSobreaviso = pCdOutraRubrica) OR
                 vCdRubSobreaviso <> pCdOutraRubrica THEN
                vNuMesesAcumulado := vNuMesesAcumulado + 1;
              END IF;*/
              vNuMesesAcumulado := vNuMesesAcumulado + 1;

              vVlHora := NVL(SUBSTR(TRUNC(vVlIndice),
                                    -LENGTH(TRUNC(vVlIndice)),
                                    LENGTH(TRUNC(vVlIndice)) - 2),
                             0) * 60;

              vVlMinuto := NVL((SUBSTR(TRUNC(vVlIndice),
                                       LENGTH(TRUNC(vVlIndice)) - 1,
                                       2)),
                               0);

              vVlIndiceAcumulado := vVlIndiceAcumulado + vVlHora +
                                    vVlMinuto;

             /* DBMS_OUTPUT.put_line('Ano/Mes: ' || vNuAno || '/' || vNuMes ||
                                   '  -  ' || trunc(vVlHora / 60) || ':' ||
                                   vVlMinuto);*/

            EXCEPTION

              WHEN NO_DATA_FOUND THEN
                vNuMesesAcumulado := vNuMesesAcumulado + 1;
               /* IF (vVlIndice > 0 AND vCdRubSobreaviso = pCdOutraRubrica) OR
                   vCdRubSobreaviso <> pCdOutraRubrica THEN
                  vNuMesesAcumulado := vNuMesesAcumulado + 1;
                END IF;*/

            END;

          END IF;

        END LOOP;

        IF vDiasAfastado < 30 THEN

          vVlIndiceAcumulado := TRUNC(vVlIndiceAcumulado * vDiasAfastado / 30);

        END IF;

        /*IF (vNuMesesAcumulado < pNuPeriodo) THEN
          vVlIndiceAcumulado := 0;
        END IF;*/
      END IF;

    END IF;

    IF vVlIndiceAcumulado > 0 THEN

      vVlIndiceAcumulado := TRUNC(vVlIndiceAcumulado / vNuMaxMesesVinculo); --pNuPeriodo); --12);

      vVlIndiceAcumHora := TRUNC(vVlIndiceAcumulado / 60);

      vVlIndiceAcumMin := vVlIndiceAcumulado MOD 60;

    END IF;

    RETURN TRUNC(vVlIndiceAcumHora) || LPAD(vVlIndiceAcumMin, 2, '0');

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;

  END;

/*---------------------------------------------------------------------------------------------*/
--     Funcao : FRetornaValorIndiceGP
--   Objetivo : Retorna o valor da gratificacao de produtividade e respectivo indice
--
/*---------------------------------------------------------------------------------------------*/

FUNCTION FRetornaValorIndiceGP(pNuAnoReferencia IN INTEGER,
                  pNuMesReferencia IN INTEGER,
                  pCdVinculo       IN INTEGER,
                  pCdTipoGratProd  IN INTEGER)

  RETURN rValor IS

  vIndGrat rValor;

BEGIN

   SELECT IP.VlBaseCalculo*GP.VlIndice,
          GP.VlIndice
     INTO vIndGrat.vlIntegral,
          vIndGrat.vlIndice
     FROM EBpcGratificacaoProdIndApurado GP
    INNER JOIN EBpcGratProdindapuradoVinculo IP
       ON IP.CdGratificacaoProdIndApurado = GP.CdGratificacaoProdIndApurado
    WHERE  GP.NuAnoReferencia = pNuAnoReferencia AND
           GP.NuMesReferencia = pNuMesReferencia AND
           GP.CdTipoGratificacaoProd = pCdTipoGratProd AND
           IP.CdVinculo = pCdVinculo;

   RETURN vIndGrat;

EXCEPTION

  WHEN OTHERS THEN

    vIndGrat.vlIntegral := NULL;

     RETURN vIndGrat;

END;

FUNCTION FRetornaIndiceNivelRef(pCdHistVantagemPecuniaria IN INTEGER,
                                pNuIndiceGeralAplicado    IN NUMBER,
                                pNuNivel                  IN VARCHAR2,
                                pNuReferencia             IN VARCHAR2)
  RETURN NUMBER IS

  vNuIndiceAplicado NUMBER;

BEGIN

  SELECT B.NuIndiceAplicado
    INTO vNuIndiceAplicado
    FROM EBpcIndNivelRefVPFormaPag B
   WHERE B.CdHistVantagemPecuniaria = pCdHistVantagemPecuniaria AND
         B.DeNivel = pNuNivel AND
         B.DeReferencia = pNuReferencia;

  RETURN vNuIndiceAplicado;

EXCEPTION

  WHEN OTHERS THEN

      RETURN pNuIndiceGeralAplicado;

END;

/*---------------------------------------------------------------------------------------------*/
--   Procedimento : PValorCEF
--       Objetivo : Gera os registros de pagamento das vantagens pecuniarias para a relacao de
--                  vinculo de cargo efetivo
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PValorCEF(pFolha      IN PKGPAG_TIPO.rFolha,
                    pCdVinculo  IN INTEGER,
                    pRubrica    IN PKGPAG_TIPO.rRubrica,
                    pVantagem   IN PKGPAG_TIPO.rVantagemPecuniaria DEFAULT NULL,
                    pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo,
                    pDtCalculo  IN DATE) IS

  vProporcional         PKGPAG_TIPO.rValorPagamento;
  vIntegral             rValor;
  vvlIndice             NUMBER;
  vCdExpressaoFormCalc  INTEGER;
  vCdGrupoOcupacional   INTEGER;
  vCdCargoComissionado  INTEGER;
  bEventoGerado         BOOLEAN;
  vpflexercicioorigem CHAR(1);

BEGIN

  IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN

    FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
    LOOP

      IF pkgpag_var.vgcef(i).cdrelacaotrabalho = pkgpag_tipo.cnrelctisp THEN

         vBpossuiCTISP := TRUE;

      END IF;

      vCdCargoComissionado := NULL;

      vCdGrupoOcupacional  := NULL;

      -- VERIFICAR ABRANGENCIA PARA COMISSIONADO
      IF PKGPAG_VAR.vgCCO.COUNT > 0 AND
         -- EXCECAO: PARA A RUBRICA -- 01-0575
         -- NAO DEVE GERAR OS DIAS RELATIVOS AO EFETIVO, SE TIVER COMISSIONADO
         pRubrica.CdRubricaAgrupamento NOT IN (42721,69358) AND
         prubrica.lsRelTrab.exists(PKGPAG_VAR.vgCCO(1).CdRelacaoTrabalho)
      THEN

        vCdCargoComissionado := PKGPAG_VAR.vgCCO(1).CdCargoComissionado;

        vCdGrupoOcupacional := PKGPAG_VAR.vgCCO(1).CdGrupoOcupacional;

      END IF;

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdOrgaoExercicio         => PKGPAG_VAR.vgCEF(i).CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => PKGPAG_VAR.vgCEF(i).CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => PKGPAG_VAR.vgCEF(i).CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => PKGPAG_VAR.vgCEF(i).CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => PKGPAG_VAR.vgCEF(i).CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => case
                                                                  when (PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao
                                                                        and pRUbrica.CdRubricaAgrupamento = 24577)
                                                                    then PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria
                                                                  else PKGPAG_VAR.vgCEF(i).CdSituacaoPrevidenciaria end,
                                   pCdEstruturaCarreira      => PKGPAG_VAR.vgCEF(i).CdEstruturaCarreira,
                                   pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional,
                                   pFlTipoProvimento         => PKGPAG_VAR.vgCEF(i).FlEfetivacao,
                                   pCdMotivoMovimentacao     => PKGPAG_VAR.vgCEF(i).CdMotivoMovimentacao,
                                   pCdInstitutoMovimentacao  => PKGPAG_VAR.vgCEF(i).CdInstitutoMovimentacao,
                                   pCdCargoComissionado      => vCdCargoComissionado,
                                   pCdGrupoOcupacional       => vCdGrupoOcupacional,
                                   pCdTipoRelacaoVinculo     => 1) THEN

         CASE pVantagem.CdFormaPagVantPecuniaria

           --Valor pode ser o resultado da media do valor recebido por outra rubrica dentro
           -- de um periodo de apuracao ou desde um mes/ano especifico

           WHEN 2 THEN

             vvlIndice := FRetornaMediaHoraPlantao(pFolha                    => pFolha,
                                                   pCdVinculo                => pCdVinculo,
                                                   pCdHistVantagemPecuniaria => pVantagem.CdHistVantagemPecuniaria,
                                                   pDtAdmissao               => PKGPAG_VAR.vgVinculo.DtAdmissao,
                                                   pCdOutraRubrica           => pVantagem.CdOutraRubricaCondPag,
                                                   pFlContMesNaoAfastado     => pVantagem.FlContabilizaNaoAfastado,
                                                   pNuPeriodo                => pVantagem.NuMeses);

             vCdExpressaoFormCalc :=

               PKGPAG_GERAL.FIdentificaFormulaCalculo(
                            pFormExpr                 => pFormExpr,
                            pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                            pCdRelacaoVinculo         => 1,
                            pCdEstruturaCarreira      => PKGPAG_VAR.vgCEF(i).CdEstruturaCarreira,
                            pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional);

             IF vCdExpressaoFormCalc > 0 AND vVlIndice <> 0 THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                                                     pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                     pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => NULL,
                                                     pVlProporcional         => NULL,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => NVL(vvlIndice,0),
                                                     pCdTipoOrigemRubrica    => 5,
                                                     pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                                                     pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim);

             END IF;

           WHEN 6 THEN

             IF pVantagem.NuValorDeterminado IS NOT NULL THEN

               vProporcional :=

                 PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                        pRubrica           => pRubrica ,
                                                        pValorIntegral     => pVantagem.NuValorDeterminado,
                                                        pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                        pCEF               => PKGPAG_VAR.vgCEF(i),
                                                         pDtCalculo         => pDtCalculo);



                 PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                       pCdVinculo              => pCdVinculo,
                                                       pCdRelacaoVinculo       => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                                                       pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                       pCdExpressaoFormCalc    => NULL,
                                                       pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                       pVlIntegral             => vProporcional.vlIntegral,
                                                       pVlProporcional         => vProporcional.vlProporcional,
                                                       pVlReal                 => vProporcional.vlReal,
                                                       pNuSufixoRubrica        => 1,
                                                       pNuParcelas             => NULL,
                                                       pVlIndice               => vProporcional.vlIndice,
                                                       pCdTipoOrigemRubrica    => 5,
                                                       pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                                                       pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim);


             END IF;

           WHEN 5 THEN
             --
             -- Implementacao para quando for por formula de calculo condicionada ao recebimento de
             -- uma outra rubrica numa determinada quantidade de meses, se o parametro for zero
             -- procurar numa folha fechada no proprio mes (Ex. Ferias)
             --
             IF pVantagem.CdOutraRubricaCondPag IS NOT NULL
                AND PKGPAG_GERAL.FRecebeuRubrica(pCdVinculo,
                                                 pVantagem.CdOutraRubricaCondPag,
                                                 pFolha.NuAnoReferencia || lPad(pFolha.NuMesReferencia,2,0),
                                                 pVantagem.NuMeses,
                                                 pCdFolhaAtual => pFolha.CdFolhaPagamento) < pVantagem.NuMeses
             THEN

               CONTINUE;

             END IF;

             IF pFolha.CdAgrupamento = 4 -- Dias Cidasc
               AND pRubrica.CdTipoIndice = 4
               THEN

                  vvlIndice := (PKGPAG_VAR.vgCEF(i).DtFim - PKGPAG_VAR.vgCEF(i).DtInicio +1);

             ELSE

                 vvlIndice := FRetornaIndiceNivelRef(pVantagem.CdHistVantagemPecuniaria,
                                                     pVantagem.NuIndiceGeralAplicado,
                                                     PKGPAG_VAR.vgCEF(i).NuNivelPagamento,
                                                     PKGPAG_VAR.vgCEF(i).NuReferenciaPagamento);
             END IF;

             vCdExpressaoFormCalc :=

               PKGPAG_GERAL.FIdentificaFormulaCalculo(
                            pFormExpr                 => pFormExpr,
                            pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                            pCdRelacaoVinculo         => 1,
                            pCdEstruturaCarreira      => PKGPAG_VAR.vgCEF(i).CdEstruturaCarreira,
                            pCdUnidadeOrganizacional  => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional);

             IF vCdExpressaoFormCalc > 0 THEN

               -- POG PARA 01-0279-01 SUBSIDIO - CARGO COMISSIONADO QUE DEVE PROPORCIONALIZAR PELA
               -- RELACAO DE VINCULO DE FUNCAO DE CHEFIA
               IF pRubrica.CdRubricaAgrupamento = 31577 AND
                  PKGPAG_VAR.vgFUC.count > 0 THEN

                  PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                       pCdVinculo              => pCdVinculo,
                                                       pCdRelacaoVinculo       => 3,
                                                       pCdHistRelacaoVinculo   => PKGPAG_VAR.vgFUC(i).CdHistFuncaoChefia,
                                                       pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                       pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                       pVlIntegral             => NULL,
                                                       pVlProporcional         => NULL,
                                                       pNuSufixoRubrica        => 1,
                                                       pNuParcelas             => NULL,
                                                       pVlIndice               => NVL(vvlIndice,0),
                                                       pCdTipoOrigemRubrica    => 5,
                                                       pDtInicio               => PKGPAG_VAR.vgFUC(i).DtInicio,
                                                       pDtFim                  => PKGPAG_VAR.vgFUC(i).DtFim);

               ELSE

                 PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                       pCdVinculo              => pCdVinculo,
                                                       pCdRelacaoVinculo       => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                                                       pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                       pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                       pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                       pVlIntegral             => NULL,
                                                       pVlProporcional         => NULL,
                                                       pNuSufixoRubrica        => 1,
                                                       pNuParcelas             => NULL,
                                                       pVlIndice               => NVL(vvlIndice,0),
                                                       pCdTipoOrigemRubrica    => 5,
                                                       pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                                                       pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim);

               END IF;

             END IF;

           WHEN 7 THEN

             IF PKGPAG_VAR.vgRegraSalFamilia.EXISTS(PKGPAG_VAR.vgCEF(i).CdRegimeTrabalho)
               AND PKGPAG_VAR.vMotAfast.InAfastado <> PKGPAG_TIPO.cnAfastadoMesTodo
               THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                     pCdVinculo               => pCdVinculo,
                                                     pCdRelacaoVinculo        => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                                                     pCdHistRelacaoVinculo    => PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                     pCdExpressaoFormCalc     => NULL,
                                                     pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral              => null,
                                                     pVlProporcional          => null,
                                                     pNuSufixoRubrica         => 1,
                                                     pNuParcelas              => NULL,
                                                     pVlIndice                => NULL,
                                                     pDtInicioRelacao         => PKGPAG_VAR.vgCEF(i).DtInicioRelacao,
                                                     pDtDesligamento          => PKGPAG_VAR.vgCEF(i).DtFimRelacao,
                                                     pCdUnidadeOrganizacional => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional,
                                                     pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                     pCdRubTotVantagem        => PKGPAG_VAR.vgRegraSalFamilia(PKGPAG_VAR.vgCEF(i).CdRegimeTrabalho).CdRubricaAgrupamento,
                                                     pCdTipoOrigemRubrica     => 6,
                                                     pDtInicio                => PKGPAG_VAR.vgCEF(i).DtInicio,
                                                     pDtFim                   => PKGPAG_VAR.vgCEF(i).DtFim);

            END IF;

          WHEN 9 THEN

             PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pCdVinculo,
                                                  pCdRelacaoVinculo        => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                                                  pCdHistRelacaoVinculo    => PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                  pCdExpressaoFormCalc     => NULL,
                                                  pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral              => NULL,
                                                  pVlProporcional          => NULL,
                                                  pNuSufixoRubrica         => 1,
                                                  pNuParcelas              => NULL,
                                                  pVlIndice                => NULL,
                                                  pDtInicioRelacao         => PKGPAG_VAR.vgCEF(i).DtInicioRelacao,
                                                  pDtDesligamento          => PKGPAG_VAR.vgCEF(i).DtFimRelacao,
                                                  pCdUnidadeOrganizacional => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional,
                                                  pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                  pCdRubTotVantagem        => pVantagem.CdRubricaTotalizadoraVantagem,
                                                  pCdTipoOrigemRubrica     => 6,
                                                  pDtInicio                => PKGPAG_VAR.vgCEF(i).DtInicio,
                                                  pDtFim                   => PKGPAG_VAR.vgCEF(i).DtFim);

           WHEN 11 THEN

             vIntegral := FRetornaValorIndiceGP(pFolha.NuAnoReferencia,
                                                pFolha.NuMesReferencia,
                                                pCdVinculo,
                                                pVantagem.CdTipoGratificacaoProd);

             IF vIntegral.vlIntegral IS NOT NULL THEN

               IF vIntegral.vlIntegral > PKGPAG_VAR.vgVlBase1467 AND PKGPAG_VAR.vgVlBase1467 > 0 THEN

                  vIntegral.vlIntegral := PKGPAG_VAR.vgVlBase1467;

               END IF;

               vProporcional :=

                 PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                        pRubrica           => pRubrica ,
                                                        pValorIntegral     => vIntegral.vlIntegral,
                                                        pNuCHO             => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                        pCEF               => PKGPAG_VAR.vgCEF(i),
                                                        pDtCalculo         => pDtCalculo);

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => PKGPAG_VAR.vgCEF(i).CdRelacaoVinculo,
                                                     pCdHistRelacaoVinculo   => PKGPAG_VAR.vgCEF(i).CdHistRelVinc,
                                                     pCdExpressaoFormCalc    => NULL,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => vIntegral.vlIntegral,
                                                     pVlProporcional         => vProporcional.vlProporcional,
                                                     pVlReal                 => vProporcional.vlReal,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => vIntegral.vlIndice,
                                                     pCdTipoOrigemRubrica    => 6,
                                                     pDtInicio               => PKGPAG_VAR.vgCEF(i).DtInicio,
                                                     pDtFim                  => PKGPAG_VAR.vgCEF(i).DtFim);
             END IF;

        ELSE

          NULL;

        END CASE;

         IF pRubrica.NuRubrica = 151 and pFolha.CdAgrupamento in (1, 176)
            then

            pkgpag_evvinc.P085DevolucaoRemAtivEspecial(pFolha   => pkgpag_var.vgFolha,
                                                       pRubrica => pRubrica,
                                                       pCEF      => PKGPAG_VAR.vgCEF,
                                                       pCdVinculo => pCdVinculo,
                                                       pEventoGerado => bEventoGerado);

         end if;

      END IF;

    END LOOP;

  END IF;

END;

/*---------------------------------------------------------------------------------------------*/
--   Procedimento : PValorAPO
--       Objetivo : Gera os registros de pagamento das vantagens pecuniarias para a relacao de
--                  vinculo de aposentado com paridade
/*---------------------------------------------------------------------------------------------*/

PROCEDURE PValorAPO(pFolha            IN PKGPAG_TIPO.rFolha,
                    pCdVinculo        IN INTEGER,
                    pAPO              IN PKGPAG_TIPO.tCEF,
                    pRubrica          IN PKGPAG_TIPO.rRubrica,
                    pVantagem         IN PKGPAG_TIPO.rVantagemPecuniaria DEFAULT NULL,
                    pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                    pDtCalculo        IN DATE,
                    pFlApoSemParidade IN CHAR DEFAULT NULL) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;

  vIntegral            rValor;

  vCdExpressaoFormCalc INTEGER;

  --vCdRelacaoTrabalho   INTEGER;

  vvlIndice             NUMBER;

BEGIN

 IF pAPO.COUNT > 0 THEN

     --
     -- Para quem possui CTISP e a relacao esta na abrangencia da rubrica, pagar somente para a relacao CTISP (CEF)
     --

     IF vBPossuiCTISP AND pRubrica.lsRelTrab.EXISTS(PKGPAG_TIPO.cnRelCTISP) THEN

        RETURN;

    END IF;

    FOR i IN pAPO.FIRST .. pAPO.LAST
    LOOP

       IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                    pRubrica                  => pRubrica,
                                    pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                    pCdOrgaoExercicio         => pAPO(i).CdOrgaoExercicio,
                                    pCdSituacaoPrevidenciaria => pAPO(i).CdSituacaoPrevidenciaria,
                                    pCdUnidadeOrganizacional  => pAPO(i).CdUnidadeOrganizacional,
                                    pCdEstruturaCarreira      => pAPO(i).CdEstruturaCarreira,
                                    pFlAPOOrigemCCO           => pAPO(i).FlOrigemCCO,
                                    pFlApoSemParidade         => pFlApoSemParidade,
                                    pCdTipoRelacaoVinculo     => 4) THEN

         CASE pVantagem.CdFormaPagVantPecuniaria

           WHEN 2 THEN

             IF MONTHS_BETWEEN(pFolha.DtInicioMes,TRUNC(pAPO(i).DtInicioRelacao)) < 3 THEN

               vvlIndice := FRetornaMediaHoraPlantao(pFolha                    => pFolha,
                                                     pCdVinculo                => pCdVinculo,
                                                     pCdHistVantagemPecuniaria => pVantagem.CdHistVantagemPecuniaria,
                                                     pDtAdmissao               => PKGPAG_VAR.vgVinculo.DtAdmissao,
                                                     pCdOutraRubrica           => pVantagem.CdOutraRubricaCondPag,
                                                     pFlContMesNaoAfastado     => pVantagem.FlContabilizaNaoAfastado,
                                                     pNuPeriodo                => pVantagem.NuMeses);

               vCdExpressaoFormCalc :=

                 PKGPAG_GERAL.FIdentificaFormulaCalculo(
                              pFormExpr                 => pFormExpr,
                              pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                              pCdRelacaoVinculo         => 1,
                              pCdEstruturaCarreira      => pAPO(i).CdEstruturaCarreira,
                              pCdUnidadeOrganizacional  => pAPO(i).CdUnidadeOrganizacional);

               IF vCdExpressaoFormCalc > 0 THEN

                 PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                       pCdVinculo              => pCdVinculo,
                                                       pCdRelacaoVinculo       => pAPO(i).CdRelacaoVinculo,
                                                       pCdHistRelacaoVinculo   => pAPO(i).CdHistRelVinc,
                                                       pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                       pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                       pVlIntegral             => NULL,
                                                       pVlProporcional         => NULL,
                                                       pNuSufixoRubrica        => 1,
                                                       pNuParcelas             => NULL,
                                                       pVlIndice               => vvlIndice,
                                                       pCdTipoOrigemRubrica    => 5,
                                                       pDtInicio               => pAPO(i).DtInicio,
                                                       pDtFim                  => pAPO(i).DtFim);

               END IF;

             END IF;

           WHEN 6 THEN

             IF pVantagem.NuValorDeterminado IS NOT NULL THEN

               vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica ,
                                                         pAPO               => pAPO(i),
                                                         pValorIntegral     => pVantagem.NuValorDeterminado);

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => pAPO(i).CdRelacaoVinculo,
                                                     pCdHistRelacaoVinculo   => pAPO(i).CdHistRelVinc,
                                                     pCdExpressaoFormCalc    => NULL,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => vProporcional.vlIntegral,
                                                     pVlProporcional         => vProporcional.vlProporcional,
                                                     pVlReal                 => vProporcional.vlReal,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => pAPO(i).VlPercentPropAPO/100,
                                                     pCdTipoOrigemRubrica    => 5,
                                                     pDtInicio               => pAPO(i).DtInicio,
                                                     pDtFim                  => pAPO(i).DtFim);

             END IF;

          WHEN 5 THEN

             vCdExpressaoFormCalc :=

               PKGPAG_GERAL.FIdentificaFormulaCalculo(
                            pFormExpr                 => pFormExpr,
                            pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                            pCdRelacaoVinculo         => 1,
                            pCdEstruturaCarreira      => pAPO(i).CdEstruturaCarreira,
                            pCdUnidadeOrganizacional  => pAPO(i).CdUnidadeOrganizacional);

             IF vCdExpressaoFormCalc > 0 THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => pAPO(i).CdRelacaoVinculo,
                                                     pCdHistRelacaoVinculo   => pAPO(i).CdHistRelVinc,
                                                     pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => NULL,
                                                     pVlProporcional         => NULL,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => NVL(pVantagem.NuIndiceGeralAplicado,0),
                                                     pCdTipoOrigemRubrica    => 5,
                                                     pDtInicio               => pAPO(i).DtInicio,
                                                     pDtFim                  => pAPO(i).DtFim);

             END IF;

          WHEN 7 THEN

            IF PKGPAG_VAR.vgRegraSalFamilia.EXISTS(pAPO(i).CdRegimeTrabalho) THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => pAPO(i).CdRelacaoVinculo,
                                                    pCdHistRelacaoVinculo    => pAPO(i).CdHistRelVinc,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral              => 0,
                                                    pVlProporcional          => 0,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => NULL,
                                                    pVlIndice                => NULL,
                                                    pDtInicioRelacao         => pAPO(i).DtInicioRelacao,
                                                    pDtDesligamento          => pAPO(i).DtFimRelacao,
                                                    pCdUnidadeOrganizacional => pAPO(i).CdUnidadeOrganizacional,
                                                    pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                    pCdRubTotVantagem        => PKGPAG_VAR.vgRegraSalFamilia(pAPO(i).CdRegimeTrabalho).CdRubricaAgrupamento,
                                                    pCdTipoOrigemRubrica     => 6,
                                                    pDtInicio                => pAPO(i).DtInicio,
                                                    pDtFim                   => pAPO(i).DtFim);

            END IF;

          WHEN 9 THEN

            PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pCdVinculo,
                                                  pCdRelacaoVinculo        => pAPO(i).CdRelacaoVinculo,
                                                  pCdHistRelacaoVinculo    => pAPO(i).CdHistRelVinc,
                                                  pCdExpressaoFormCalc     => NULL,
                                                  pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                  pVlIntegral              => NULL,
                                                  pVlProporcional          => NULL,
                                                  pNuSufixoRubrica         => 1,
                                                  pNuParcelas              => NULL,
                                                  pVlIndice                => NULL,
                                                  pDtInicioRelacao         => pAPO(i).DtInicioRelacao,
                                                  pDtDesligamento          => pAPO(i).DtFimRelacao,
                                                  pCdUnidadeOrganizacional => pAPO(i).CdUnidadeOrganizacional,
                                                  pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                  pCdRubTotVantagem        => pVantagem.CdRubricaTotalizadoraVantagem,
                                                  pCdTipoOrigemRubrica     => 6,
                                                  pDtInicio                => pAPO(i).DtInicio,
                                                  pDtFim                   => pAPO(i).DtFim);

           WHEN 11 THEN

              vIntegral := FRetornaValorIndiceGP(pFolha.NuAnoReferencia,
                                                 pFolha.NuMesReferencia,
                                                 pCdVinculo,
                                                 pVantagem.CdTipoGratificacaoProd);

              IF pAPO(i).CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelTrabDisposicao AND
                 vIntegral.vlIntegral IS NOT NULL THEN

                IF vIntegral.vlIntegral > PKGPAG_VAR.vgVlBase1467 AND PKGPAG_VAR.vgVlBase1467 > 0 THEN

                  vIntegral.vlIntegral := PKGPAG_VAR.vgVlBase1467;

                END IF;

                vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica ,
                                                         pAPO               => pAPO(i),
                                                         pValorIntegral     => vIntegral.vlIntegral);

                PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento      => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => pAPO(i).CdRelacaoVinculo,
                                                     pCdHistRelacaoVinculo   => pAPO(i).CdHistRelVinc,
                                                     pCdExpressaoFormCalc    => NULL,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => vIntegral.vlIntegral,
                                                     pVlProporcional         => vProporcional.vlProporcional,
                                                     pVlReal                 => vProporcional.vlReal,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => vIntegral.vlIndice,
                                                     pCdTipoOrigemRubrica    => 6,
                                                     pDtInicio               => pAPO(i).DtInicio,
                                                     pDtFim                  => pAPO(i).DtFim);

          END IF;

         ELSE

           NULL;

       END CASE;

     END IF;

   END LOOP;

  END IF;

END;

PROCEDURE PValorFUC(pFolha            IN PKGPAG_TIPO.rFolha,
                    pCdVinculo        IN INTEGER,
                    pFUC              IN PKGPAG_TIPO.tFUC,
                    pRubrica          IN PKGPAG_TIPO.rRubrica,
                    pVantagem         IN PKGPAG_TIPO.rVantagemPecuniaria DEFAULT NULL,
                    pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                    pDtCalculo        IN DATE) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;

  vIntegral            rValor;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF pFUC.COUNT > 0 THEN

    FOR i IN pFUC.FIRST .. pFUC.LAST

    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdOrgaoExercicio         => pFUC(i).CdOrgaoExercicio,
                                   pCdTipoRelacaoVinculo     => 3/*,
                                   pCdRegimePrevidenciario   => pFUC(i).CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => pFUC(i).CdSituacaoPrevidenciaria,
                                   pCdCargoComissionado      => pFUC(i).CdCargoComissionado,
                                   pCdGrupoOcupacional       => pFUC(i).CdGrupoOcupacional,
                                   pCdOpcaoRemuneracao       => pFUC(i).CdOpcaoRemuneracao,
                                   pCdUnidadeOrganizacional  => pFUC(i).CdUnidadeOrganizacional,
                                   pCdEstruturaCarreira      => PKGPAG_VAR.vgCdEstruturaCarreira,
                                   pFlTipoProvimento         => pFUC(i).FlTipoProvimento,

                                   */) THEN

        CASE pVantagem.CdFormaPagVantPecuniaria

          WHEN 6 THEN

             IF pVantagem.NuValorDeterminado IS NOT NULL THEN

               vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pFUC               => pFUC(i),
                                                         pValorIntegral     => pVantagem.NuValorDeterminado,
                                                         pDtCalculo         => pDtCalculo,
                                                         pNuDiasCCOSubst    => PKGPAG_VAR.vgNuDiasSubst);

                PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                      pCdVinculo              => pCdVinculo,
                                                      pCdRelacaoVinculo       => 3,
                                                      pCdHistRelacaoVinculo   => pFUC(i).CdHistFuncaoChefia,
                                                      pCdExpressaoFormCalc    => NULL,
                                                      pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                      pVlIntegral             => vProporcional.vlIntegral,--pVantagem.NuValorDeterminado,
                                                      pVlProporcional         => vProporcional.vlProporcional,
                                                      pVlReal                 => vProporcional.vlReal,
                                                      pNuSufixoRubrica        => 1,
                                                      pNuParcelas             => NULL,
                                                      pVlIndice               => vProporcional.vlIndice,
                                                      pCdTipoOrigemRubrica    => 5,
                                                      pDtInicio               => pFUC(i).DtInicio,
                                                      pDtFim                  => pFUC(i).DtFim);

             END IF;

          WHEN 5 THEN

            IF pVantagem.CdOutraRubricaCondPag IS NOT NULL
                AND PKGPAG_GERAL.FRecebeuRubrica(pCdVinculo,
                                                 pVantagem.CdOutraRubricaCondPag,
                                                 pFolha.NuAnoReferencia || lPad(pFolha.NuMesReferencia,2,0),
                                                 pVantagem.NuMeses,
                                                 pCdFolhaAtual => pFolha.CdFolhaPagamento) < pVantagem.NuMeses
             THEN

               CONTINUE;

             END IF;

            vCdExpressaoFormCalc :=

              PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                      pFormExpr                 => pFormExpr,
                                      pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                      pCdRelacaoVinculo         => 3,
                                      pCdCargoComissionado      => pFUC(i).CdHistFuncaoChefia,
                                      pCdUnidadeOrganizacional  => pFUC(i).CdUnidadeOrganizacional);

             IF vCdExpressaoFormCalc > 0 THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => 3,
                                                     pCdHistRelacaoVinculo   => pFUC(i).CdHistFuncaoChefia,
                                                     pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => NULL,
                                                     pVlProporcional         => NULL,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => NVL(pVantagem.NuIndiceGeralAplicado,0),
                                                     pCdTipoOrigemRubrica    => 5,
                                                      pDtInicio              => pFUC(i).DtInicio,
                                                      pDtFim                 => pFUC(i).DtFim);

             END IF;

          WHEN 11 THEN

             vIntegral := FRetornaValorIndiceGP(pFolha.NuAnoReferencia,
                                                pFolha.NuMesReferencia,
                                                pCdVinculo,
                                                pVantagem.CdTipoGratificacaoProd);

             IF vIntegral.vlIntegral IS NOT NULL THEN

               IF vIntegral.vlIntegral > PKGPAG_VAR.vgVlBase1467 AND PKGPAG_VAR.vgVlBase1467 > 0 THEN

                  vIntegral.vlIntegral := PKGPAG_VAR.vgVlBase1467;

               END IF;

               vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pFUC               => pFUC(i),
                                                         pValorIntegral     => vIntegral.vlIntegral,
                                                         pDtCalculo         => pDtCalculo,
                                                         pNuDiasCCOSubst    => PKGPAG_VAR.vgNuDiasSubst);

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => 3,
                                                     pCdHistRelacaoVinculo   => pFUC(i).CdHistFuncaoChefia,
                                                     pCdExpressaoFormCalc    => NULL,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => vIntegral.vlIntegral,
                                                     pVlProporcional         => vProporcional.vlProporcional,
                                                     pVlReal                 => vProporcional.vlReal,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => vIntegral.vlIndice,
                                                     pCdTipoOrigemRubrica    => 6,
                                                     pDtInicio               => pFUC(i).DtInicio,
                                                     pDtFim                  => pFUC(i).DtFim);

             END IF;

           /*WHEN 9 THEN

            IF pFUC(i).CdOpcaoRemuneracao <> 2 THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => 2,
                                                    pCdHistRelacaoVinculo    => pFUC(i).CdHistFuncaoChefia,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral              => NULL,
                                                    pVlProporcional          => NULL,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => NULL,
                                                    pVlIndice                => NULL,
                                                    pDtInicioRelacao         => pFUC(i).DtInicioRelacao,
                                                    pDtDesligamento          => pFUC(i).DtFimRelacao,
                                                    pCdUnidadeOrganizacional => pFUC(i).CdUnidadeOrganizacional,
                                                    pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                    pCdRubTotVantagem        => pVantagem.CdRubricaTotalizadoraVantagem,
                                                    pCdTipoOrigemRubrica     => 6,
                                                    pDtInicio                => pFUC(i).DtInicio,
                                                    pDtFim                   => pFUC(i).DtFim);
            END IF;*/

          /*WHEN 7 THEN

            IF PKGPAG_VAR.vgRegraSalFamilia.EXISTS(pFUC(i).CdRegimeTrabalho) THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => 2,
                                                    pCdHistRelacaoVinculo    => pFUC(i).CdHistFuncaoChefia,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral              => 0,
                                                    pVlProporcional          => 0,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => NULL,
                                                    pVlIndice                => NULL,
                                                    pDtInicioRelacao         => pFUC(i).DtInicioRelacao,
                                                    pDtDesligamento          => pFUC(i).DtFimRelacao,
                                                    pCdUnidadeOrganizacional => pFUC(i).CdUnidadeOrganizacional,
                                                    pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                    pCdRubTotVantagem        => PKGPAG_VAR.vgRegraSalFamilia(pFUC(i).CdRegimeTrabalho).CdRubricaAgrupamento,
                                                    pCdTipoOrigemRubrica     => 6,
                                                    pDtInicio                => pFUC(i).DtInicio,
                                                    pDtFim                   => pFUC(i).DtFim);

            END IF;*/

          ELSE

             NULL;

         END CASE;
      END IF;

   END LOOP;

 END IF;

END;
/*---------------------------------------------------------------------------------------------*/
--   Procedimento : PValorCCO
--       Objetivo : Gera os registros de pagamento das vantagens pecuniarias para a relacao de
--                  vinculo de cargo comissionado
/*---------------------------------------------------------------------------------------------*/
PROCEDURE PValorCCO(pFolha            IN PKGPAG_TIPO.rFolha,
                    pCdVinculo        IN INTEGER,
                    pCCO              IN PKGPAG_TIPO.tCCO,
                    pRubrica          IN PKGPAG_TIPO.rRubrica,
                    pVantagem         IN PKGPAG_TIPO.rVantagemPecuniaria DEFAULT NULL,
                    pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                    pDtCalculo        IN DATE) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;

  vIntegral            rValor;

  vCdExpressaoFormCalc INTEGER;
  
  vvl011023            number :=0;

BEGIN

  IF pCCO.COUNT > 0 THEN

    FOR i IN pCCO.FIRST .. pCCO.LAST

    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                   pRubrica                  => pRubrica,
                                   pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                   pCdOrgaoExercicio         => pCCO(i).CdOrgaoExercicio,
                                   pCdNaturezaVinculo        => pCCO(i).CdNaturezaVinculo,
                                   pCdRelacaoTrabalho        => pCCO(i).CdRelacaoTrabalho,
                                   pCdRegimeTrabalho         => pCCO(i).CdRegimeTrabalho,
                                   pCdRegimePrevidenciario   => pCCO(i).CdRegimePrevidenciario,
                                   pCdSituacaoPrevidenciaria => pCCO(i).CdSituacaoPrevidenciaria,
                                   pCdCargoComissionado      => pCCO(i).CdCargoComissionado,
                                   pCdGrupoOcupacional       => pCCO(i).CdGrupoOcupacional,
                                   pCdOpcaoRemuneracao       => pCCO(i).CdOpcaoRemuneracao,
                                   pCdUnidadeOrganizacional  => pCCO(i).CdUnidadeOrganizacional,
                                   pCdEstruturaCarreira      => PKGPAG_VAR.vgCdEstruturaCarreira,
                                   pFlTipoProvimento         => pCCO(i).FlTipoProvimento,
                                   pCdTipoRelacaoVinculo     => 2
                                   ) THEN

        CASE pVantagem.CdFormaPagVantPecuniaria

          WHEN 6 THEN

             IF pVantagem.NuValorDeterminado IS NOT NULL THEN

               vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pCCO               => pCCO(i),
                                                         pValorIntegral     => pVantagem.NuValorDeterminado,
                                                         pDtCalculo         => pDtCalculo,
                                                         pNuDiasCCOSubst    => PKGPAG_VAR.vgNuDiasSubst);

                PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                      pCdVinculo              => pCdVinculo,
                                                      pCdRelacaoVinculo       => 2,
                                                      pCdHistRelacaoVinculo   => pCCO(i).CdHistCargoCom,
                                                      pCdExpressaoFormCalc    => NULL,
                                                      pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                      pVlIntegral             => vProporcional.vlIntegral,--pVantagem.NuValorDeterminado,
                                                      pVlProporcional         => vProporcional.vlProporcional,
                                                      pVlReal                 => vProporcional.vlReal,
                                                      pNuSufixoRubrica        => 1,
                                                      pNuParcelas             => NULL,
                                                      pVlIndice               => vProporcional.vlIndice,
                                                      pCdTipoOrigemRubrica    => 5,
                                                      pDtInicio               => pCCO(i).DtInicio,
                                                      pDtFim                  => pCCO(i).DtFim);

             END IF;

          WHEN 5 THEN

           if  NOT PKGPAG_VAR.bVinculoComCEF  and 
             PKGPAG_GERAL.FRetornaRubrica(pfolha.CdAgrupamento,1,1468) = pRubrica.CdRubricaAgrupamento AND
              PKGPAG_VAR.bVinculoComCCO AND
              PKGPAG_VAR.vgRelVincPrincipal.Tipo = 2 AND
              PKGPAG_VAR.vgFolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaNormal then
              
              SELECT count(*)
              INTO vvl011023
              FROM epaghistoricorubricarelvinc hrv
              WHERE HRV.CdFolhaPagamento = pfolha.CdFolhaPagamento
                 AND HRV.CdVinculo = pCdVinculo
                 AND HRV.CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pfolha.CdAgrupamento,1,1023) 
                 AND ROWNUM < 2;

              if vvl011023 > 0 then
                 return;
              end if;
           end if;

            vCdExpressaoFormCalc :=

              PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                      pFormExpr                 => pFormExpr,
                                      pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                      pCdRelacaoVinculo         => 2,
                                      pCdCargoComissionado      => pCCO(i).CdCargoComissionado,
                                      pCdUnidadeOrganizacional  => pCCO(i).CdUnidadeOrganizacional);

             IF vCdExpressaoFormCalc > 0 THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => 2,
                                                     pCdHistRelacaoVinculo   => pCCO(i).CdHistCargoCom,
                                                     pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => NULL,
                                                     pVlProporcional         => NULL,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => NVL(pVantagem.NuIndiceGeralAplicado,0),
                                                     pCdTipoOrigemRubrica    => 5,
                                                      pDtInicio              => pCCO(i).DtInicio,
                                                      pDtFim                 => pCCO(i).DtFim);

             END IF;

          WHEN 11 THEN

             vIntegral := FRetornaValorIndiceGP(pFolha.NuAnoReferencia,
                                                pFolha.NuMesReferencia,
                                                pCdVinculo,
                                                pVantagem.CdTipoGratificacaoProd);

             IF vIntegral.vlIntegral IS NOT NULL THEN

               IF vIntegral.vlIntegral > PKGPAG_VAR.vgVlBase1467 AND PKGPAG_VAR.vgVlBase1467 > 0 THEN

                  vIntegral.vlIntegral := PKGPAG_VAR.vgVlBase1467;

               END IF;

               vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pCCO               => pCCO(i),
                                                         pValorIntegral     => vIntegral.vlIntegral,
                                                         pDtCalculo         => pDtCalculo,
                                                         pNuDiasCCOSubst    => PKGPAG_VAR.vgNuDiasSubst);

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => 2,
                                                     pCdHistRelacaoVinculo   => pCCO(i).CdHistCargoCom,
                                                     pCdExpressaoFormCalc    => NULL,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => vIntegral.vlIntegral,
                                                     pVlProporcional         => vProporcional.vlProporcional,
                                                     pVlReal                 => vProporcional.vlReal,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => vIntegral.vlIndice,
                                                     pCdTipoOrigemRubrica    => 6,
                                                     pDtInicio               => pCCO(i).DtInicio,
                                                     pDtFim                  => pCCO(i).DtFim);

             END IF;

           WHEN 9 THEN

            IF pCCO(i).CdOpcaoRemuneracao <> 2 THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => 2,
                                                    pCdHistRelacaoVinculo    => pCCO(i).CdHistCargoCom,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral              => NULL,
                                                    pVlProporcional          => NULL,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => NULL,
                                                    pVlIndice                => NULL,
                                                    pDtInicioRelacao         => pCCO(i).DtInicioRelacao,
                                                    pDtDesligamento          => pCCO(i).DtFimRelacao,
                                                    pCdUnidadeOrganizacional => pCCO(i).CdUnidadeOrganizacional,
                                                    pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                    pCdRubTotVantagem        => pVantagem.CdRubricaTotalizadoraVantagem,
                                                    pCdTipoOrigemRubrica     => 6,
                                                    pDtInicio                => pCCO(i).DtInicio,
                                                    pDtFim                   => pCCO(i).DtFim);
            END IF;

          WHEN 7 THEN

            IF PKGPAG_VAR.vgRegraSalFamilia.EXISTS(pCCO(i).CdRegimeTrabalho) THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => 2,
                                                    pCdHistRelacaoVinculo    => pCCO(i).CdHistCargoCom,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral              => 0,
                                                    pVlProporcional          => 0,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => NULL,
                                                    pVlIndice                => NULL,
                                                    pDtInicioRelacao         => pCCO(i).DtInicioRelacao,
                                                    pDtDesligamento          => pCCO(i).DtFimRelacao,
                                                    pCdUnidadeOrganizacional => pCCO(i).CdUnidadeOrganizacional,
                                                    pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                    pCdRubTotVantagem        => PKGPAG_VAR.vgRegraSalFamilia(pCCO(i).CdRegimeTrabalho).CdRubricaAgrupamento,
                                                    pCdTipoOrigemRubrica     => 6,
                                                    pDtInicio                => pCCO(i).DtInicio,
                                                    pDtFim                   => pCCO(i).DtFim);

            END IF;

          ELSE

             NULL;

         END CASE;
      END IF;

   END LOOP;

 END IF;

END;

PROCEDURE PValorPNP(pFolha            IN PKGPAG_TIPO.rFolha,
                    pCdVinculo        IN INTEGER,
                    pPNP              IN PKGPAG_TIPO.tPensaoNaoPrev,
                    pRubrica          IN PKGPAG_TIPO.rRubrica,
                    pVantagem         IN PKGPAG_TIPO.rVantagemPecuniaria DEFAULT NULL,
                    pFormExpr         IN PKGPAG_TIPO.tFormulaCalculo,
                    pDtCalculo        IN DATE) IS

  vProporcional        PKGPAG_TIPO.rValorPagamento;

  vIntegral            rValor;

  vCdExpressaoFormCalc INTEGER;

BEGIN

  IF pPNP.COUNT > 0 THEN

    FOR i IN pPNP.FIRST .. pPNP.LAST

    LOOP

      IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(
                                    pRubrica                  => pRubrica,
                                    pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                    pCdOrgaoExercicio         => pPNP(i).CdOrgaoExercicio,
                                    pCdRegimeTrabalho         => pPNP(i).CdRegimeTrabalho,
                                    pCdRegimePrevidenciario   => pPNP(i).CdRegimePrevidenciario,
                                    pCdSituacaoPrevidenciaria => pPNP(i).CdSituacaoPrevidenciaria,
                                    pCdUnidadeOrganizacional  => pPNP(i).CdUnidadeOrganizacional) THEN

        CASE pVantagem.CdFormaPagVantPecuniaria

          WHEN 6 THEN

             IF pVantagem.NuValorDeterminado IS NOT NULL THEN

               vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pPNP               => pPNP(i),
                                                         pValorIntegral     => pVantagem.NuValorDeterminado,
                                                         pDtCalculo         => pDtCalculo);

                PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                      pCdVinculo              => pCdVinculo,
                                                      pCdRelacaoVinculo       => 7,
                                                      pCdHistRelacaoVinculo   => pPNP(i).CdHistPensaoNaoPrev,
                                                      pCdExpressaoFormCalc    => NULL,
                                                      pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                      pVlIntegral             => vProporcional.vlIntegral,--pVantagem.NuValorDeterminado,
                                                      pVlProporcional         => vProporcional.vlProporcional,
                                                      pVlReal                 => vProporcional.vlReal,
                                                      pNuSufixoRubrica        => 1,
                                                      pNuParcelas             => NULL,
                                                      pVlIndice               => vProporcional.vlIndice,
                                                      pCdTipoOrigemRubrica    => 5,
                                                      pDtInicio               => pPNP(i).DtInicio,
                                                      pDtFim                  => pPNP(i).DtFim);

             END IF;

          WHEN 5 THEN

            vCdExpressaoFormCalc :=

              PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                      pFormExpr                 => pFormExpr,
                                      pCdRubricaAgrupamento     => pRubrica.CdRubricaAgrupamento,
                                      pCdRelacaoVinculo         => 7);

             IF vCdExpressaoFormCalc > 0 THEN

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => 7,
                                                     pCdHistRelacaoVinculo   => pPNP(i).CdHistPensaoNaoPrev,
                                                     pCdExpressaoFormCalc    => vCdExpressaoFormCalc,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => NULL,
                                                     pVlProporcional         => NULL,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => NVL(pVantagem.NuIndiceGeralAplicado,0),
                                                     pCdTipoOrigemRubrica    => 5,
                                                     pDtInicio               => pPNP(i).DtInicio,
                                                     pDtFim                  => pPNP(i).DtFim);

             END IF;

          WHEN 11 THEN

             vIntegral := FRetornaValorIndiceGP(pFolha.NuAnoReferencia,
                                                pFolha.NuMesReferencia,
                                                pCdVinculo,
                                                pVantagem.CdTipoGratificacaoProd);

             IF vIntegral.vlIntegral IS NOT NULL THEN

               IF vIntegral.vlIntegral > PKGPAG_VAR.vgVlBase1467 AND PKGPAG_VAR.vgVlBase1467 > 0 THEN

                  vIntegral.vlIntegral := PKGPAG_VAR.vgVlBase1467;

               END IF;

               vProporcional :=

                  PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                         pRubrica           => pRubrica,
                                                         pPNP               => pPNP(i),
                                                         pValorIntegral     => vIntegral.vlIntegral,
                                                         pDtCalculo         => pDtCalculo);

               PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                     pCdVinculo              => pCdVinculo,
                                                     pCdRelacaoVinculo       => 7,
                                                     pCdHistRelacaoVinculo   => pPNP(i).CdHistPensaoNaoPrev,
                                                     pCdExpressaoFormCalc    => NULL,
                                                     pCdRubricaAgrupamento   => pRubrica.CdRubricaAgrupamento,
                                                     pVlIntegral             => vIntegral.vlIntegral,
                                                     pVlProporcional         => vProporcional.vlProporcional,
                                                     pVlReal                 => vProporcional.vlReal,
                                                     pNuSufixoRubrica        => 1,
                                                     pNuParcelas             => NULL,
                                                     pVlIndice               => vIntegral.vlIndice,
                                                     pCdTipoOrigemRubrica    => 6,
                                                     pDtInicio               => pPNP(i).DtInicio,
                                                     pDtFim                  => pPNP(i).DtFim);

             END IF;

           WHEN 9 THEN

             PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento         => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => 7,
                                                    pCdHistRelacaoVinculo    => pPNP(i).CdHistPensaoNaoPrev,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral              => NULL,
                                                    pVlProporcional          => NULL,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => NULL,
                                                    pVlIndice                => NULL,
                                                    pDtInicioRelacao         => pPNP(i).DtInicioRelacao,
                                                    pDtDesligamento          => pPNP(i).DtFimRelacao,
                                                    pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                    pCdRubTotVantagem        => pVantagem.CdRubricaTotalizadoraVantagem,
                                                    pCdTipoOrigemRubrica     => 6,
                                                    pDtInicio                => pPNP(i).DtInicio,
                                                    pDtFim                   => pPNP(i).DtFim);

          WHEN 7 THEN

            IF PKGPAG_VAR.vgRegraSalFamilia.EXISTS(pPNP(i).CdRegimeTrabalho) THEN

              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                    pCdVinculo               => pCdVinculo,
                                                    pCdRelacaoVinculo        => 7,
                                                    pCdHistRelacaoVinculo    => pPNP(i).CdHistPensaoNaoPrev,
                                                    pCdExpressaoFormCalc     => NULL,
                                                    pCdRubricaAgrupamento    => pRubrica.CdRubricaAgrupamento,
                                                    pVlIntegral              => 0,
                                                    pVlProporcional          => 0,
                                                    pNuSufixoRubrica         => 1,
                                                    pNuParcelas              => NULL,
                                                    pVlIndice                => NULL,
                                                    pDtInicioRelacao         => pPNP(i).DtInicioRelacao,
                                                    pDtDesligamento          => pPNP(i).DtFimRelacao,
                                                    pCdUnidadeOrganizacional => pPNP(i).CdUnidadeOrganizacional,
                                                    pCdVantagemPecuniaria    => pVantagem.CdVantagemPecuniaria,
                                                    pCdRubTotVantagem        => PKGPAG_VAR.vgRegraSalFamilia(pPNP(i).CdRegimeTrabalho).CdRubricaAgrupamento,
                                                    pCdTipoOrigemRubrica     => 6,
                                                    pDtInicio                => pPNP(i).DtInicio,
                                                    pDtFim                   => pPNP(i).DtFim);

            END IF;

          ELSE

             NULL;

         END CASE;
      END IF;

   END LOOP;

 END IF;

END;

/*---------------------------------------------------------------------------------------------*/
--  Procedimento : PProcessaVantagemPecuniaria
--      Objetivo : Processar as vantagens pecuniarias nas relacoes de vinculo
--
--   Regras implementadas:
--     07) Valor gerado pelas regras de negocio de um tipo de evento;
--     09) Valor depende da faixa de enquadramento de uma base de calculo
--         (para abonos e outras vantagens correlatas);
--     11) Valor depende do indice de uma gratificacao de produtividade;

--     Regras 07, 09 sao calculadas posteriormente em ProcessaVantagemBase
/*---------------------------------------------------------------------------------------------*/
PROCEDURE PProcessaVantagemPecuniaria(pFolha      IN PKGPAG_TIPO.rFolha,
                                      pCdVinculo  IN INTEGER,
                                      pRubrica    IN PKGPAG_TIPO.tRubrica,
                                      pVantagem   IN PKGPAG_TIPO.tVantagemPecuniaria,
                                      pFormExpr   IN PKGPAG_TIPO.tFormulaCalculo,
                                      pDtCalculo  IN DATE) IS

  vFlPermitido    BOOLEAN;
  pCount   INTEGER;
  vvlRub6006 pkgpag_tipo.rvalorpagamento := NULL;
  vPossuiLancamentoFinanceiro  BOOLEAN := FALSE;
  vCdRubricaAgrupamento01_1070 INTEGER;

BEGIN

  PKGPAG_VAR.vgTmInicio := PKGPAG_GERAL.FGetTime;

  PKGPAG_VAR.vglindice010229 := 0;

  IF pVantagem.COUNT > 0 THEN

    FOR i IN pVantagem.FIRST .. pVantagem.LAST
    LOOP

     IF PKGPAG_VAR.vgFolha.InPagamentoRubrica = 2
      THEN

      BEGIN

        SELECT count(ra.cdrubricaagrupamento)
          INTO pCount
          FROM epagfolhapagamento fp
         INNER JOIN epaghisttipofolhapagamento htfp
            ON fp.cdtipofolhapagamento = htfp.cdtipofolhapagamento
         INNER JOIN epagtipofolharubrica fr
            ON HTFP.CdHistTipoFolhaPagamento = FR.cdHistTipoFolhaPagamento
         INNER JOIN epagrubricaagrupamento ra
            ON fr.cdrubricaagrupamento = ra.cdrubricaagrupamento
         WHERE HTFP.InPagamentoRubrica = 2
           AND ra.cdrubricaagrupamento = pVantagem(i).CdRubricaAgrupamento
           AND ((HTFP.NuAnoInicioVigencia < FP.NuAnoReferencia OR
               (htfp.nuanoiniciovigencia = fp.nuanoreferencia AND
               HTFP.NuMesInicioVigencia <= FP.NuMesReferencia)) AND
               (htfp.nuanofimvigencia > fp.nuanoreferencia OR
               (htfp.nuanofimvigencia = fp.nuanoreferencia AND
               htfp.numesfimvigencia >= fp.numesreferencia) OR
               htfp.nuanofimvigencia IS NULL))
           AND FP.CdFolhaPagamento = pFolha.cdFolhaPagamento;

      -- #77825  RUBRICAS QUE NAO DEVEM SER CALCULADAS TAMBEM NAO INCIDAM NA BASE DE CALCULO DE OUTRAS RUBRICAS.
      IF NVL(pCount,0) > 0
        THEN
          CONTINUE;
      END IF;

      EXCEPTION WHEN OTHERS THEN
        NULL;

    END;
  END IF;

      vFlPermitido := false;

      -- Paga vantagem pecuniaria se:
      IF pVantagem.EXISTS(i) THEN

         -- 1. decisao judicial OU
         IF  pVantagem(i).FlDecisaoJudicial = 'S' OR
             (
                PKGPAG_GERAL.FGeraRubrica(pVantagem(i).CdRubricaAgrupamento) AND
                PKGPAG_GERAL.FRubricaPermitida(pFlPagaTodasRubricas  => pFolha.FlPagaTodasRubricas,
                                              pCdTipoFolha          => pFolha.CdTipoFolha,
                                              pCdRubricaAgrupamento => pVantagem(i).CdRubricaAgrupamento) AND
                ( -- 2. aplica a todo o agrupamento OU
                  pVantagem(i).FlAplicaTodoAgrupamento = 'S' OR
                  -- 3. aplica ao orgao da folha
                  pVantagem(i).TabOrgaosPermitidos.EXISTS (pFolha.CdOrgao)
                )
             )
         THEN

             vFlPermitido := true;

         END IF;

         --Exceção incluída apenas para a folha definitiva de Agosto/2021.
         --O IF abaixo deve ser retirado após o processamento dessa folha, e a verificação se possui LF deve ser mantida para todas as rubricas.
         vCdRubricaAgrupamento01_1070 := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 1, 1070);
         IF pVantagem(i).CdRubricaAgrupamento = vCdRubricaAgrupamento01_1070 THEN

           vPossuiLancamentoFinanceiro := PKGPAG_GERAL.fpossuilancfinanceiro(pcdvinculo => PKGPAG_VAR.vgCdVinculo,
                                                                             pfolha     => pFolha,
                                                                             pcdrubrica => pVantagem(i).CdRubricaAgrupamento);
           IF vPossuiLancamentoFinanceiro THEN
             vFlPermitido := FALSE;
           END IF;
         END IF;

      END IF;

      --
      -- Solicitacao de Sustentacao #75858
      -- FOLHA - 10297/2017 - PM-PARAMETRO PARA PAGTO DE CTISP
      --
      BEGIN

      IF NVL(pVantagem(i).CdRubricaAgrupamento,0) > 0  --THEN
          THEN
            IF pkgpag_var.bGeraPagamentoCTISP = FALSE
             AND pkgpag_var.bPossuiCtisp = TRUE
             THEN
               vFlPermitido := false;
          END IF;
      END IF;

      --
      --  #80299 12573/2018 - RUBRICA 01-0093 PARA ORGAO 1506
      -- PRECISAMOS QUE A RUBRICA 01-0093 COMPLEMENTO DE SALÁRIO MÍNIMO
      -- GERE PARA OS PENSIONISTAS DO ÓRGÃO 1506, MAIS SOMENTE PARA OS QUE RECEBEM A RUBRICA 01-6006.
      --
      IF pFolha.CdOrgao = 34
        AND pVantagem(i).CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                   1,
                                                                                                   93) THEN

          vvlRub6006 := PKGPAG_GERAL.fretornavaloroutrasrv(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                                pcdvinculo => pCdVinculo,
                                                                                pcdrubricaagrupamento => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                                                                                  1,
                                                                                                                                                                  6006));
          IF NVL(vvlRub6006.vlProporcional, 0) > 0
            THEN
              vFlPermitido := true;
          ELSE

              vFlPermitido := false;
          END IF;
        END IF;

         IF pVantagem(i).CdRubricaAgrupamento = PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 1, 201)
             AND pkgpag_cal.fPossuiPagamentoMediaFerias(PKGPAG_VAR.vgCdVinculo,
                                                       PKGPAG_VAR.vgFolha.dtInicioMes,
                                                       PKGPAG_VAR.vgFolha.cdOrgao,
                                                       PKGPAG_VAR.vgFolha.CdAgrupamento)
                                                       THEN

              vFlPermitido := FALSE;
        END IF;

      EXCEPTION

       WHEN OTHERS THEN

          vFlPermitido := vFlPermitido;

      END;

      IF vFlPermitido THEN

        begin

        pValorCEF(pFolha,
                  pCdVinculo,
                  pRubrica(pVantagem(i).CdRubricaAgrupamento),
                  pVantagem(i),
                  pFormExpr,
                  pDtCalculo);

        PValorCCO(pFolha,
                  pCdVinculo,
                  PKGPAG_VAR.vgCCOSubst,
                  pRubrica(pVantagem(i).CdRubricaAgrupamento),
                  pVantagem(i),
                  pFormExpr,
                  pDtCalculo);

        PValorCCO(pFolha,
                  pCdVinculo,
                  PKGPAG_VAR.vgCCO,
                  pRubrica(pVantagem(i).CdRubricaAgrupamento),
                  pVantagem(i),
                  pFormExpr,
                  pDtCalculo);

        pValorAPO(pFolha,
                  pCdVinculo,
                  PKGPAG_VAR.vgAPO,
                  pRubrica(pVantagem(i).CdRubricaAgrupamento),
                  pVantagem(i),
                  pFormExpr,
                  pDtCalculo);

        pValorAPO(pFolha,
                  pCdVinculo,
                  PKGPAG_VAR.vgAPOSemParidade,
                  pRubrica(pVantagem(i).CdRubricaAgrupamento),
                  pVantagem(i),
                  pFormExpr,
                  pDtCalculo,
                  'S');

        pValorPNP(pFolha,
                  pCdVinculo,
                  PKGPAG_VAR.vgPensaoNaoPrev,
                  pRubrica(pVantagem(i).CdRubricaAgrupamento),
                  pVantagem(i),
                  pFormExpr,
                  pDtCalculo);

        if pkgpag_var.vgFolha.cdagrupamento = 5 then

           PValorFUC(pFolha,
                     pCdVinculo,
                     PKGPAG_VAR.vgFUC,
                     pRubrica(pVantagem(i).CdRubricaAgrupamento),
                     pVantagem(i),
                     pFormExpr,
                     pDtCalculo);

        end if;

        exception
          when others then
            null;
        end;

      end if;

    END LOOP;

    PKGPAG_GERAL.PLogTrace ('VP - Processa Vantagem Pecuniária',null, PKGPAG_VAR.vgTmInicio);

  END IF;

END;

END PKGPAG_VP;
/
