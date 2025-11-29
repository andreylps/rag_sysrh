CREATE OR REPLACE PACKAGE pkgpag_evfucpnp IS

  /*

       Tratamento de Eventos da Folha de Pagamento

       Relacao de Vinculo Comissionado/Bolsista

  */

  PROCEDURE pprocessaeventosfuc(pvinculo   IN pkgpag_tipo.rvinculo,
                                pfolha     IN pkgpag_tipo.rfolha,
                                pevento    IN pkgpag_tipo.revento,
                                prubrica   IN pkgpag_tipo.trubrica,
                                pformexpr  IN pkgpag_tipo.tformulacalculo,
                                pfuc       IN pkgpag_tipo.tfuc,
                                pdtcalculo IN DATE);

  PROCEDURE pprocessaeventosfucsubst(pvinculo  IN pkgpag_tipo.rvinculo,
                                     pfolha    IN pkgpag_tipo.rfolha,
                                     pevento   IN pkgpag_tipo.revento,
                                     prubrica  IN pkgpag_tipo.trubrica,
                                     pformexpr IN pkgpag_tipo.tformulacalculo,
                                     pfucsubst IN pkgpag_tipo.tfuc);

  PROCEDURE pprocessaeventospnp(pvinculo       IN pkgpag_tipo.rvinculo,
                                pfolha         IN pkgpag_tipo.rfolha,
                                pevento        IN pkgpag_tipo.revento,
                                prubrica       IN pkgpag_tipo.trubrica,
                                ppensaonaoprev IN pkgpag_tipo.tpensaonaoprev,
                                pdtcalculo     IN DATE);

  FUNCTION FSubsmesmafucmesmoperio(pcdfolhapagamento     IN NUMBER,
                                   Pcdvinculo            IN NUMBER,
                                   pcdrubricaagrupamento IN NUMBER,
                                   pdtinicio             IN DATE,
                                   pdtfim                IN DATE DEFAULT NULL)
    RETURN BOOLEAN;

END pkgpag_evfucpnp;
/
CREATE OR REPLACE PACKAGE BODY pkgpag_evfucpnp IS

  /*-----------------------------------------------------------------------------------------
  -- Procedure : P03RemuneracaoFixaFUC
  --  Objetivo : Gera a remuneracao fixa de funcao de chefia
  --
  /*-----------------------------------------------------------------------------------------*/

  FUNCTION fproporcionalidade(pvalorintegral IN NUMBER,
                              pdtinicio      IN DATE,
                              pdtfim         IN DATE DEFAULT NULL)

   RETURN NUMBER IS

    vnudiasmes INTEGER;
    vdtfim     DATE;

  BEGIN

    IF pdtfim IS NULL THEN
      vdtfim := last_day(pdtinicio);
    ELSE
      vdtfim := pdtfim;
    END IF;

    vnudiasmes := (vdtfim - pdtinicio) + 1;

    -- acerta os dias que serao pagos para max 30 dias/mes
    IF to_char(vdtfim, 'DD') = 31 THEN
      vnudiasmes := vnudiasmes - 1;
    ELSIF to_char(vdtfim, 'DD') = 29 THEN
      --ano bisexto
      vnudiasmes := vnudiasmes + 1;
    ELSIF to_char(vdtfim, 'DD') = 28 THEN
      --fevereiro
      vnudiasmes := vnudiasmes + 2;
    ELSE
      NULL;
    END IF;

    RETURN(vnudiasmes * pvalorintegral) / 30;

  END;

  PROCEDURE p003remuneracaofixafuc(pfolha                   IN pkgpag_tipo.rfolha,
                                   pfuc                     IN pkgpag_tipo.rfuc,
                                   prubrica                 IN pkgpag_tipo.rrubrica,
                                   pflutilizaformulacalculo IN CHAR,
                                   pdtcalculo               IN DATE) IS

    vproporcional pkgpag_tipo.rvalorpagamento;

    vvlpadrao NUMBER(13, 2);

    vcdexpressaoformcalc INTEGER;

    vcdpadraofucagrup INTEGER;

    vqtdeunidades INTEGER;
  BEGIN

    vcdpadraofucagrup := NULL;

    IF pflutilizaformulacalculo = 'N' THEN

      CASE

        WHEN pfuc.cdpadraofucagrup IS NOT NULL THEN
          vcdpadraofucagrup := pfuc.cdpadraofucagrup;

        WHEN pfuc.cdtipounidorg IS NOT NULL THEN

          -- Procura Faixa de Unidades de um Tipo para encontrar valor padrao da Funcao

          -- Contar Subordinados do tipo da unidade NO ULTIMO DIA DO MES

          vqtdeunidades := 0;

          BEGIN

            SELECT SUM(decode(cdtipounidorg, pfuc.cdtipounidorg, 1, 0))
              INTO vqtdeunidades
              FROM ecadhistunidadeorganizacional
             START WITH cduosuphierarq = pfuc.cdunidadeorganizacional
                    AND DtInicioVigencia <= pFolha.DtFimMes
                    and (DtFimVigencia >= pFolha.DtFimMes or
                        DtFimVigencia IS NULL)
            CONNECT BY cduosuphierarq = PRIOR cdunidadeorganizacional
                   AND cdorgao = PRIOR cdorgao
                   and DtInicioVigencia <= pFolha.DtFimMes
                   and (DtFimVigencia >= pFolha.DtFimMes or
                       DtFimVigencia IS NULL);
          EXCEPTION
            WHEN no_data_found THEN
              vqtdeunidades := 0;
          END;

          -- Encontra Valor Padrao

          BEGIN

            SELECT cdpadraofucagrup
              INTO vcdpadraofucagrup
              FROM (SELECT CdPadraoFUCAgrup,
                           ROW_NUMBER() OVER(ORDER BY QtUnidade) as Menor
                      FROM ecadevolucaofucvalorref evr
                     where CdEvolucaoFuncaoChefia =
                           pFUC.CdEvolucaoFuncaoChefia
                       and QtUnidade >= vQtdeUnidades)
             WHERE menor = 1;

          EXCEPTION
            WHEN no_data_found THEN
              NULL;
          END;

        ELSE

          vvlpadrao := 0;

      END CASE;

      IF vcdpadraofucagrup IS NOT NULL THEN

        vvlpadrao := pkgpag_geral.fretornavalorfixofuc(vcdpadraofucagrup,
                                                       pfolha.cdagrupamento,
                                                       pfolha.cdorgao,
                                                       nvl(pfolha.nuversaotabfuc,
                                                           1),
                                                       pfolha.nuanoreferencia,
                                                       pfolha.numesreferencia);

      END IF;

      IF vvlpadrao IS NOT NULL THEN

        --  vvlIntegral := vvlPadrao;

        vProporcional := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                prubrica       => prubrica,
                                                                pfuc           => pfuc,
                                                                pvalorintegral => vvlpadrao,
                                                                pdtcalculo     => pdtcalculo);

        PKGPAG_GERAL.PAtualizaHistFUC(pFolha,

                                      pRubrica,

                                      pFUC,

                                      vproporcional.vlintegral,
                                      vproporcional.vlproporcional,
                                      vproporcional.vlreal,
                                      vproporcional.vlindice);

      ELSE

        pkgpag_geral.pinserelog(pkgpag_var.blog,
                                pkgpag_var.vcdhistparamcalc,
                                pkgpag_var.vcdpessoa,
                                'Não foi encontrado o valor fixo de FUC.',
                                pkgpag_var.vgcdvinculo);

      END IF;

    ELSE
      
      -- Validar abrangencia funcao de chefia
      -- SIG-11912 
      if pFolha.CdAgrupamento = 134 -- Militares
         and to_char(pFolha.DtInicioMes,'yyyymm') > '202408'
         and not pkgpag_geral.fpossuiabrangenciarubrica(prubrica => prubrica,
                                                        pcdorgao => pFuc.CdOrgaoExercicio,
                                                        pCdOrgaoExercicio => pFuc.CdOrgaoExercicio,
                                                        pcdfuncaochefia => pFuc.CdFuncaoChefia) then 
                                                 
         return;
         
      end if;
      
      vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                     pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                                                     pcdrelacaovinculo     => 3);

      IF vcdexpressaoformcalc > 0 THEN

        pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento => pfolha.cdfolhapagamento,
                                              pcdvinculo        => pfuc.cdvinculo,
                                              pCdRelacaoVinculo => 3, -- Funcao de chefia

                                              pcdhistrelacaovinculo    => pfuc.cdhistfuncaochefia,
                                              pcdexpressaoformcalc     => vcdexpressaoformcalc,
                                              pcdrubricaagrupamento    => prubrica.cdrubricaagrupamento,
                                              pvlintegral              => NULL,
                                              pvlproporcional          => NULL,
                                              pnusufixorubrica         => 1,
                                              pnuparcelas              => 0,
                                              pvlindice                => NULL,
                                              pdtiniciorelacao         => pfuc.dtiniciorelacao,
                                              pdtdesligamento          => pfuc.dtfimrelacao,
                                              pcdunidadeorganizacional => pfuc.cdunidadeorganizacional,
                                              pcdtipoorigemrubrica     => 1,
                                              pdtinicio                => pfuc.dtinicio,
                                              pdtfim                   => pfuc.dtfim);

      END IF;

    END IF;

  END;

  /* -------------------- TESTES REAJUSTE UDESC --------------------------------*/
  PROCEDURE p003remuneracaofixafucudesc(pfolha                   IN pkgpag_tipo.rfolha,
                                        pfuc                     IN pkgpag_tipo.rfuc,
                                        prubrica                 IN pkgpag_tipo.rrubrica,
                                        pflutilizaformulacalculo IN CHAR,
                                        pdtcalculo               IN DATE) IS

    vproporcional pkgpag_tipo.rvalorpagamento;

    vvlpadrao NUMBER(13, 2);

    vcdexpressaoformcalc INTEGER;

    vcdpadraofucagrup INTEGER;

    vqtdeunidades INTEGER;

    /* FABIO */
    vfucudesc pkgpag_tipo.rfuc;

  BEGIN

    vcdpadraofucagrup := NULL;

    /* FABIO */
    vfucudesc := pfuc;

    IF pflutilizaformulacalculo = 'N' THEN

      CASE

        WHEN pfuc.cdpadraofucagrup IS NOT NULL THEN
          vcdpadraofucagrup := pfuc.cdpadraofucagrup;

        WHEN pfuc.cdtipounidorg IS NOT NULL THEN

          -- Procura Faixa de Unidades de um Tipo para encontrar valor padrao da Funcao

          -- Contar Subordinados do tipo da unidade NO ULTIMO DIA DO MES

          vqtdeunidades := 0;

          BEGIN

            SELECT SUM(decode(cdtipounidorg, pfuc.cdtipounidorg, 1, 0))
              INTO vqtdeunidades
              FROM ecadhistunidadeorganizacional
             START WITH cduosuphierarq = pfuc.cdunidadeorganizacional
                    AND DtInicioVigencia <= pFolha.DtFimMes
                    and (DtFimVigencia >= pFolha.DtFimMes or
                        DtFimVigencia IS NULL)
            CONNECT BY cduosuphierarq = PRIOR cdunidadeorganizacional
                   AND cdorgao = PRIOR cdorgao
                   and DtInicioVigencia <= pFolha.DtFimMes
                   and (DtFimVigencia >= pFolha.DtFimMes or
                       DtFimVigencia IS NULL);
          EXCEPTION
            WHEN no_data_found THEN
              vqtdeunidades := 0;
          END;

          -- Encontra Valor Padrao

          BEGIN

            SELECT cdpadraofucagrup
              INTO vcdpadraofucagrup
              FROM (SELECT CdPadraoFUCAgrup,
                           ROW_NUMBER() OVER(ORDER BY QtUnidade) as Menor
                      FROM ecadevolucaofucvalorref evr
                     where CdEvolucaoFuncaoChefia =
                           pFUC.CdEvolucaoFuncaoChefia
                       and QtUnidade >= vQtdeUnidades)
             WHERE menor = 1;

          EXCEPTION
            WHEN no_data_found THEN
              NULL;
          END;

        ELSE

          vvlpadrao := 0;

      END CASE;
      /* FABIO */
      FOR vINDEX IN 1 .. 2 LOOP
        IF vcdpadraofucagrup IS NOT NULL THEN
          IF vindex = 1 THEN
            vvlpadrao := pkgpag_geral.fretornavalorfixofuc(vcdpadraofucagrup,
                                                           pfolha.cdagrupamento,
                                                           pfolha.cdorgao,
                                                           nvl(pfolha.nuversaotabfuc,
                                                               1),
                                                           pfolha.nuanoreferencia,
                                                           pfolha.numesreferencia - 1); /*FABIO - tem que tratar dezembro do ano anterior */
          ELSE
            vvlpadrao := pkgpag_geral.fretornavalorfixofuc(vcdpadraofucagrup,
                                                           pfolha.cdagrupamento,
                                                           pfolha.cdorgao,
                                                           nvl(pfolha.nuversaotabfuc,
                                                               1),
                                                           pfolha.nuanoreferencia,
                                                           pfolha.numesreferencia);

          END IF;

        END IF;

        IF vvlpadrao IS NOT NULL THEN

          --  vvlIntegral := vvlPadrao;
          /* FABIO */

          IF vindex = 1 THEN
            IF vfucudesc.dtfim > to_date('06/04/2014', 'DD/MM/YYYY') THEN
              vfucudesc.dtfim := to_date('06/04/2014', 'DD/MM/YYYY');
            END IF;
          ELSE
            IF vfucudesc.dtinicio < to_date('07/04/2014', 'DD/MM/YYYY') THEN
              vfucudesc.dtinicio := to_date('07/04/2014', 'DD/MM/YYYY');
            END IF;
            vfucudesc.dtfim := pfuc.dtfim;
          END IF;

          vProporcional := PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                  prubrica       => prubrica,
                                                                  pfuc           => vfucudesc,
                                                                  pvalorintegral => vvlpadrao,
                                                                  pdtcalculo     => pdtcalculo);

          PKGPAG_GERAL.PAtualizaHistFUC(pFolha,

                                        pRubrica,

                                        pFUC,

                                        vproporcional.vlintegral,
                                        vproporcional.vlproporcional,
                                        vproporcional.vlreal,
                                        vproporcional.vlindice);

        ELSE

          pkgpag_geral.pinserelog(pkgpag_var.blog,
                                  pkgpag_var.vcdhistparamcalc,
                                  pkgpag_var.vcdpessoa,
                                  'Não foi encontrado o valor fixo de FUC.',
                                  pkgpag_var.vgcdvinculo);

        END IF;
      END LOOP;

    ELSE

      vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                     pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                                                     pcdrelacaovinculo     => 3);

      IF vcdexpressaoformcalc > 0 THEN

        pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento => pfolha.cdfolhapagamento,
                                              pcdvinculo        => pfuc.cdvinculo,
                                              pCdRelacaoVinculo => 3, -- Funcao de chefia

                                              pcdhistrelacaovinculo    => pfuc.cdhistfuncaochefia,
                                              pcdexpressaoformcalc     => vcdexpressaoformcalc,
                                              pcdrubricaagrupamento    => prubrica.cdrubricaagrupamento,
                                              pvlintegral              => NULL,
                                              pvlproporcional          => NULL,
                                              pnusufixorubrica         => 1,
                                              pnuparcelas              => 0,
                                              pvlindice                => NULL,
                                              pdtiniciorelacao         => pfuc.dtiniciorelacao,
                                              pdtdesligamento          => pfuc.dtfimrelacao,
                                              pcdunidadeorganizacional => pfuc.cdunidadeorganizacional,
                                              pcdtipoorigemrubrica     => 1,
                                              pdtinicio                => pfuc.dtinicio,
                                              pdtfim                   => pfuc.dtfim);

      END IF;

    END IF;

  END;

  PROCEDURE P006AdicionalTempoServicoDPE(pCdVinculo                 IN INTEGER,
                                         pCdFolha                   in integer,
                                         pDtInicioMes               in date,
                                         pDtFimMes                  in date,
                                         pDtInicioConquistaPerAquis in date,
                                         pDtFimConquistaPerAquis    in date,
                                         pCdTipoTempoServico        in integer,
                                         pCdRubrica                 IN integer,
                                         pcdhistfuncaochefia        in integer,
                                         pdtiniciorelacao           in date,
                                         pdtfimrelacao              in date,
                                         pcdunidadeorganizacional   in integer,
                                         pdtinicio                  in date,
                                         pdtfim                     in date,
                                         pFormExpr                  pkgpag_tipo.tFormulaCalculo) IS

    vVlindiceATSAnt      NUMBER(7, 4);
    vVlindiceATSMes      NUMBER(7, 4);
    vVlPecentMaxAcum     NUMBER(7, 4);
    vNuDiasATSAnt        NUMBER(7, 4);
    vNuDiasATSMes        NUMBER(7, 4);
    vDtfimconquista      DATE;
    vCdExpressaoFormCalc integer;

    i INTEGER;
    j INTEGER;

  BEGIN

    vVlindiceATSAnt := 0;
    vVlindiceATSMes := 0;
    vDtfimconquista := NULL;
    vNuDiasATSAnt   := 0;
    vNuDiasATSMes   := 0;

    j := 0;

    IF PKGPAG_VAR.vgParamATSAcum.COUNT > 0 THEN

      -- Busca no parametro de acumulacao o percentual maximo permitido de
      -- acordo com a data da conquista
      i := PKGPAG_VAR.vgParamATSAcum.FIRST;

      WHILE i <= PKGPAG_VAR.vgParamATSAcum.LAST LOOP

        vVlPecentMaxAcum := PKGPAG_VAR.vgParamATSAcum(i).VlPercentMaxAcum;
        i                := PKGPAG_VAR.vgParamATSAcum.NEXT(i);

      END LOOP;

      /*Conta os periodos aquisitivos conquistados  e sumariza os percentuais de direito */
      FOR vTS IN (SELECT PA.CdRegraTipoAdicionalTempServ,
                         PA.VlPercentualDireito,
                         PA.DtFimConquista
                    FROM EPagPeriodoAquistempServ PA
                   INNER JOIN EBpcRegraTipoAdicionalTempServ RTS
                      ON PA.CdRegraTipoAdicionalTempServ =
                         RTS.CdRegraTipoAdicionalTempServ
                   WHERE PA.CdVinculo = pCdVinculo
                     AND PA.DtFimConquista <= pDtFimMes
                     AND (PA.DtFimConquista >= pDtInicioConquistaPerAquis AND
                         (PA.DtFimConquista <= pDtFimConquistaPerAquis OR
                         pDtFimConquistaPerAquis IS NULL))
                     AND RTS.CdTipoAdicionalTempServ = pCdTipoTempoServico
                     AND PA.CdSituacaoPerAquisitivo = 2
                     AND PA.FlPago = PKGPAG_TIPO.cnS
                   ORDER BY PA.Dtfimconquista)

       LOOP

        -- Busca no parametro de acumulacao o percentual maximo permitido de
        -- acordo com a data da conquista
        i := PKGPAG_VAR.vgParamATSAcum.FIRST;

        WHILE i <= PKGPAG_VAR.vgParamATSAcum.LAST LOOP

          IF pCdTipoTempoServico = PKGPAG_VAR.vgParamATSAcum(i).CdTipoAdicionalTempServ AND
             vTS.DtFimConquista >= PKGPAG_VAR.vgParamATSAcum(i).DtConquista THEN

            vVlPecentMaxAcum := PKGPAG_VAR.vgParamATSAcum(i).VlPercentMaxAcum;

            EXIT;

          END IF;

          i := PKGPAG_VAR.vgParamATSAcum.NEXT(i);

        END LOOP;

        -- Soma os índices conquistados antes do mes da folha
        IF vTS.Dtfimconquista < pDtInicioMes THEN

          vVlindiceATSAnt := vVlindiceATSAnt + vTS.Vlpercentualdireito;

        ELSIF vTS.Dtfimconquista BETWEEN trunc(pDtInicioMes) AND
              trunc(pDtFimMes) THEN

          vVlindiceATSMes := vVlindiceATSAnt + vTS.Vlpercentualdireito;
          vDtfimconquista := vTS.Dtfimconquista;

          vNuDiasATSMes := LEAST((TO_CHAR(pDtFimMes, 'DD')), 30) -
                           LEAST((TO_CHAR(vDtFimConquista, 'DD')), 30) + 1;
          vNuDiasATSAnt := 30 - vNuDiasATSMes;

        else
          null;
        END IF;

      END LOOP;

      IF vVlindiceATSAnt > 0 THEN

        j := j + 1;
        pkgpag_var.vgPercentATS(j).cdrubricaagrupamento := pCdRubrica;
        pkgpag_var.vgPercentATS(j).vlindiceATS := vVlindiceATSAnt;

        IF vDtfimconquista BETWEEN trunc(pDtInicioMes) AND trunc(pDtFimMes) THEN

          vVlindiceATSAnt := (vVlindiceATSAnt / 30) * vNuDiasATSAnt;

        END IF;

        PKGPAG_VAR.vgPercentAcumATS(pCdTipoTempoServico) := PKGPAG_VAR.vgPercentAcumATS(pCdTipoTempoServico) +
                                                            vVlindiceATSAnt;

        vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => pFormExpr,
                                                                       pcdrubricaagrupamento => pcdrubrica,
                                                                       pCdRelacaoVinculo     => 3);

        IF vcdexpressaoformcalc > 0 THEN

          pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento        => pcdfolha,
                                                pcdvinculo               => pcdvinculo,
                                                pcdrelacaovinculo        => 3,
                                                pcdhistrelacaovinculo    => pcdhistfuncaochefia,
                                                pcdexpressaoformcalc     => vcdexpressaoformcalc,
                                                pcdrubricaagrupamento    => pcdrubrica,
                                                pvlintegral              => NULL,
                                                pvlproporcional          => NULL,
                                                pnusufixorubrica         => 1,
                                                pvlindice                => vVlindiceATSAnt,
                                                pdtiniciorelacao         => pdtiniciorelacao,
                                                pdtdesligamento          => pdtfimrelacao,
                                                pcdunidadeorganizacional => pcdunidadeorganizacional,
                                                pcdtipoorigemrubrica     => 6,
                                                pdtinicio                => pdtinicio,
                                                pdtfim                   => pdtfim);
        end if;

      END IF;

      IF vVlindiceATSMes > 0 THEN

        j := j + 1;
        pkgpag_var.vgPercentATS(j).cdrubricaagrupamento := pcdRUbrica;
        pkgpag_var.vgPercentATS(j).vlIndiceATS := vVlindiceATSMes;

        IF vDtfimconquista BETWEEN pDtInicioMes AND pDtFimMes THEN

          vVlindiceATSMes := (vVlindiceATSMes / 30) * vNuDiasATSMes;

        END IF;

        PKGPAG_VAR.vgPercentAcumATS(pCdTipoTempoServico) := PKGPAG_VAR.vgPercentAcumATS(pCdTipoTempoServico) +
                                                            vVlindiceATSMes;

        pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento        => pcdfolha,
                                              pcdvinculo               => pcdvinculo,
                                              pcdrelacaovinculo        => 3,
                                              pcdhistrelacaovinculo    => pcdhistfuncaochefia,
                                              pcdexpressaoformcalc     => vcdexpressaoformcalc,
                                              pcdrubricaagrupamento    => pCdrubrica,
                                              pvlintegral              => NULL,
                                              pvlproporcional          => NULL,
                                              pnusufixorubrica         => 1,
                                              pvlindice                => vVlindiceATSMes,
                                              pdtiniciorelacao         => pdtiniciorelacao,
                                              pdtdesligamento          => pdtfimrelacao,
                                              pcdunidadeorganizacional => pcdunidadeorganizacional,
                                              pcdtipoorigemrubrica     => 6,
                                              pdtinicio                => pdtinicio,
                                              pdtfim                   => pdtfim);

      END IF;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vCdPessoa,
                              'Erro ao processar Adicional de Tempo de Serviço.',
                              PKGPAG_VAR.vgCdVinculo);

  END;

  /*-----------------------------------------------------------------------------------------/
  --     Procedure : P014SubstituicaoFUC
  --      Objetivo : Gerar a remuneracao fixa para a relacao de vinculo de cargo comissionado
  --                 de substituicao
  --

  --          Nota :

  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE p014substituicaofuc(pfolha    IN pkgpag_tipo.rfolha,
                                pfuc      IN pkgpag_tipo.rfuc,
                                prubrica  IN pkgpag_tipo.rrubrica,
                                pformexpr IN pkgpag_tipo.tformulacalculo) IS

    vcdexpressaoformcalc INTEGER DEFAULT NULL;
    vNuSufixoRubrica     INTEGER := 1;
    vPagaRubrica         BOOLEAN := TRUE;

    FUNCTION fPossuiFuCTitularPeriodo(pcdVinculo IN INTEGER,
                                      pDtInicio  IN DATE,
                                      pDtFim     IN DATE) RETURN BOOLEAN IS
         vQtdFucTitularPeriodo INTEGER;
    BEGIN

      select count(*) as qtd
      into vQtdFucTitularPeriodo
      from ecadhistfuncaochefia
     where flanulado = 'N'
       and cdvinculo = pcdVinculo
       and dtinicio <= pDtInicio
       and (dtfim >= pDtFim or dtfim is null)
       and flefetivacao = 'S';

      RETURN vQtdFucTitularPeriodo>0;
    END;

    FUNCTION fpossuisubstituicaohistfuc(pCdFolhaPagamento     IN INTEGER,
                                        pcdVinculo            IN INTEGER,
                                        pCdRubricaAgrupamento IN INTEGER)

     RETURN BOOLEAN IS
      vvlindicerubrica INTEGER;

    BEGIN

      SELECT rrv.vlindicerubrica
        INTO vvlindicerubrica
        FROM EPagHistoricoRubricaRelVinc rrv
       WHERE rrv.cdvinculo = pcdVinculo
         AND rrv.cdrubricaagrupamento = pCdRubricaAgrupamento
         AND rrv.cdfolhapagamento = pCdFolhaPagamento;

      IF vvlindicerubrica >= 30 THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        RETURN FALSE;
    END;

  BEGIN

    IF pkgpag_var.bpagacef THEN

      vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => pFormExpr,
                                                                     pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                                                     pCdRelacaoVinculo     => 3, -- Funcao Chefia
                                                                     pcdfuncaochefia       => pfuc.cdfuncaochefia);

      IF vcdexpressaoformcalc > 0 THEN
        --
        -- Rubricas especificas orgao 2801, para substituicao privativa
        --
        IF nvl(pkgpag_var.vgNuDiasSubstFUC, 0) > 0 AND
           pkgpag_var.vgListaRubFuncaoPrivativa.COUNT > 0 AND
           pkgpag_var.vgListaRubFuncaoPrivativa.EXISTS(prubrica.cdrubricaagrupamento) AND
           pkgpag_var.vgNuDiasSubstFuc < to_char(pFolha.DtFimMes, 'DD')

         THEN

          vNuSufixoRubrica := 2;

        END IF;

        pkgpag_var.vgNuDiasSubstFUC := least(pkgpag_var.vgNuDiasSubstFUC,
                                             30);

        IF (pRubrica.NuRubrica = 433) THEN
            IF (vNuSufixoRubrica = 2 and fPossuiFuCTitularPeriodo(pfuc.CdVinculo, pFolha.DtInicioMes, pFolha.DtInicioMes)) THEN
              vPagaRubrica := FALSE;
            END IF;
            ----SIGRH - 9637
            IF (vNuSufixoRubrica = 2 and fPossuiFuCTitularPeriodo(pfuc.CdVinculo, pFolha.DtInicioMes, pFolha.DtInicioMes))
               and pfolha.CdOrgao = 49 THEN
               vPagaRubrica := TRUE;
            END IF;
        END IF;

        IF (vPagaRubrica) THEN

          PKGPAG_GERAL.PAtualizaHistFUC(pFolha,
                                        pRubrica,
                                        pFUC,
                                        NULL,
                                        NULL,
                                        NULL,
                                        pkgpag_var.vgNuDiasSubstFUC,
                                        vCdExpressaoFormCalc,
                                        7,
                                        vNuSufixoRubrica);
        END IF;

      END IF;

    END IF;

  END;

  /*-----------------------------------------------------------------------------------------/
  --     Procedure : P061RemuneracaoPensaoNaoPrev
  --      Objetivo : Gerar a remuneracao de pensao nao previdenciaria
  --

  --         Nota :

  /*-----------------------------------------------------------------------------------------*/
  PROCEDURE p061remuneracaopensaonaoprev(ppensaonaoprev IN pkgpag_tipo.rpensaonaoprev,
                                         pfolha         IN pkgpag_tipo.rfolha,
                                         prubrica       IN pkgpag_tipo.rrubrica,
                                         pdtcalculo     IN DATE) IS

    vcdhisttabgeral INTEGER;

    vvlpensaonaoprev NUMBER(13, 2);

    vvlpercentpensaonaoprev NUMBER(7, 4);

    vnunivel VARCHAR2(3);

    vnureferencia VARCHAR2(3);

    vcdvalorgeralcefagrup INTEGER;

    vcdvalorreferencia INTEGER;

    vproporcional pkgpag_tipo.rvalorpagamento;

  BEGIN

    BEGIN

      SELECT pnp.vlpensaonaoprev,
             pnp.vlpercentpensaonaoprev,
             pnp.nunivel,
             pnp.nureferencia,
             pnp.cdvalorgeralcefagrup,
             pnp.cdvalorreferencia
        INTO vvlpensaonaoprev,
             vvlpercentpensaonaoprev,
             vnunivel,
             vnureferencia,
             vcdvalorgeralcefagrup,
             vcdvalorreferencia
        FROM epvdvalorpensaonaoprev pnp
       WHERE PNP.CdPensaoNaoPrevidenciaria =
             pPensaoNaoPrev.CdHistPensaoNaoPrev
         AND (PNP.NuAnoInicioReferencia < pFolha.NuAnoReferencia OR
             (pnp.nuanoinicioreferencia = pfolha.nuanoreferencia AND
             PNP.NuMesInicioReferencia <= pFolha.NuMesReferencia))
         AND (PNP.NuAnoFimReferencia > pFolha.NuAnoReferencia OR
             (PNP.NuAnoFimReferencia = pFolha.NuAnoReferencia AND
             PNP.NuMesFimReferencia >= pFolha.NuMesReferencia) OR
             pnp.nuanofimreferencia IS NULL);

      pkgpag_var.vgpercentpensaonaoprev := nvl(vvlpercentpensaonaoprev, 100);

      IF vvlpensaonaoprev IS NOT NULL AND vcdvalorreferencia IS NOT NULL THEN

        vProporcional.VlIntegral := vVlPensaoNaoPrev * PKGPAG_VAR.vgValorReferencia(vCdValorReferencia).VlReferencia;

      ELSIF vcdvalorgeralcefagrup IS NOT NULL THEN

        vcdhisttabgeral := pkgpag_geral.ftabelavalorgeral(pcdtabgeral => vcdvalorgeralcefagrup,
                                                          pnuversao   => pfolha.nuversaotabcef,
                                                          pnuano      => pfolha.nuanoreferencia,
                                                          pnumes      => pfolha.numesreferencia);

        IF vcdhisttabgeral IS NOT NULL THEN

          vproporcional.vlintegral := pkgpag_geral.fretornavalornivrefgeral(vcdhisttabgeral,
                                                                            vnunivel,
                                                                            vnureferencia);

        END IF;

      ELSIF vvlpensaonaoprev IS NOT NULL THEN

        vproporcional.vlintegral := vvlpensaonaoprev;

      else
        null;
      END IF;

      vproporcional := pkgpag_geral.fcalculaproporcionalidade(pfolha         => pfolha,
                                                              prubrica       => prubrica,
                                                              ppnp           => ppensaonaoprev,
                                                              pvalorintegral => vproporcional.vlintegral,
                                                              pdtcalculo     => pdtcalculo);

      IF vproporcional.vlintegral > 0 THEN

        pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento     => pfolha.cdfolhapagamento,
                                              pcdvinculo            => ppensaonaoprev.cdvinculobeneficiario,
                                              pCdRelacaoVinculo     => 7, -- Pensao nao previdenciaria
                                              pcdhistrelacaovinculo => ppensaonaoprev.cdhistpensaonaoprev,
                                              pcdexpressaoformcalc  => NULL,
                                              pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                              pvlintegral           => vproporcional.vlintegral,
                                              pvlproporcional       => vproporcional.vlproporcional,
                                              pvlreal               => vproporcional.vlreal,
                                              pnusufixorubrica      => 1,
                                              pnuparcelas           => 0,
                                              pvlindice             => vproporcional.vlindice,
                                              pdtiniciorelacao      => ppensaonaoprev.dtiniciorelacao,
                                              pdtdesligamento       => ppensaonaoprev.dtfimrelacao,
                                              pcdtipoorigemrubrica  => 1,
                                              pdtinicio             => ppensaonaoprev.dtinicio,
                                              pdtfim                => ppensaonaoprev.dtfim);

      END IF;

    EXCEPTION

      WHEN no_data_found THEN

        pkgpag_geral.pinserelog(pinsere                  => pkgpag_var.blog,
                                pcdhistoricoparamcalculo => pkgpag_var.vcdhistparamcalc,
                                pcdpessoa                => pkgpag_var.vcdpessoa,
                                pdelog                   => 'Valor da pensão não cadsatrada.',
                                pcdvinculo               => pkgpag_var.vgvinculo.cdvinculo,
                                pcdtipoocorrencia        => 1);

    END;

  END;

  PROCEDURE p084dedicexclusivamagisterio(pfolha     IN pkgpag_tipo.rfolha,
                                         pfuc       IN pkgpag_tipo.rfuc,
                                         prubrica   IN pkgpag_tipo.rrubrica,
                                         pformexpr  IN pkgpag_tipo.tformulacalculo,
                                         pdtcalculo IN DATE) IS

    vlpercdedicacaoexclusiva NUMBER;

    vcdexpressaoformcalc INTEGER;

    vvalorproporcional NUMBER;

  BEGIN

    -- Verifica abrangencia; aborta execucao se nao possui abrangencia
    IF NOT
        PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica => pRubrica,

                                               pcdorgao                  => pkgpag_var.vgcdorgaovinculo,
                                               pcdorgaoexercicio         => pfuc.cdorgaoexercicio,
                                               pcdsituacaoprevidenciaria => pfuc.cdsituacaoprevidenciaria,
                                               pcdunidadeorganizacional  => pfuc.cdunidadeorganizacional) THEN

      RETURN;

    END IF;

    -- descobre valor percentual da dedicacao exclusiva

    SELECT efc.vlpercdedicacaoexclusiva
      INTO vlpercdedicacaoexclusiva
      FROM ecadevolucaofuncaochefia efc
     WHERE efc.cdfuncaochefia = pfuc.cdfuncaochefia;

    -- aborta execucao se nao encontrou valor

    IF vlpercdedicacaoexclusiva IS NULL THEN
      RETURN;
    END IF;

    -- gerar a rubrica sem valor para aplicacao de formula de calculo

    -- utilizando o indice como o percentual em referencia

    vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => pFormExpr,
                                                                   pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                                                   pCdRelacaoVinculo     => 3, -- Funcao Chefia
                                                                   pcdfuncaochefia       => pfuc.cdfuncaochefia);

    IF vcdexpressaoformcalc > 0 THEN

      /* IF pkgpag_var.vgfuc.count > 1 THEN
        vvalorproporcional := fproporcionalidade(vlpercdedicacaoexclusiva,
                                                 pfuc.dtinicio, pfuc.dtfim);
      ELSE*/
      vvalorproporcional := vlpercdedicacaoexclusiva;
      /*   END IF;*/

      pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento     => pfolha.cdfolhapagamento,
                                            pcdvinculo            => pfuc.cdvinculo,
                                            pcdrelacaovinculo     => 3,
                                            pcdhistrelacaovinculo => pfuc.cdhistfuncaochefia,
                                            pcdexpressaoformcalc  => vcdexpressaoformcalc,
                                            pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                            pvlintegral           => NULL,
                                            pvlproporcional       => NULL,
                                            pnusufixorubrica      => 1,
                                            --pNuParcelas              => 1,

                                            pvlindice                => vvalorproporcional,
                                            pdtiniciorelacao         => pfuc.dtiniciorelacao,
                                            pdtdesligamento          => pfuc.dtfimrelacao,
                                            pcdunidadeorganizacional => pfuc.cdunidadeorganizacional,
                                            pcdtipoorigemrubrica     => 7,
                                            pdtinicio                => pfuc.dtinicio,
                                            pdtfim                   => pfuc.dtfim);

    END IF;

  END;

  /*-----------------------------------------------------------------------------------------/
  --  Procedure : p129FeriasJudiciais
  --  Objetivo : 23662/2025 - GPENP - CRIAR EVENTO DE PAGAMENTO PARA FERIAS JUDICIAIS
  /*-----------------------------------------------------------------------------------------*/
  PROCEDURE p129FeriasJudiciais(ppensaonaoprev IN pkgpag_tipo.rpensaonaoprev,
                                pfolha         IN pkgpag_tipo.rfolha,
                                prubrica       IN pkgpag_tipo.rrubrica,
                                pdtcalculo     IN DATE) IS
    
    vdtinicio            DATE;    
    vflabonoferias       VARCHAR2(1);
    vcdexpressaoformcalc INTEGER;
    
  BEGIN
    
    SELECT flabonoferias, dtinicio
      INTO vflabonoferias, vdtinicio
      FROM epvdhistpensaonaoprev
     WHERE cdvinculobeneficiario = ppensaonaoprev.CdVinculoBeneficiario
       AND (dtfim is null or dtfim > trunc(sysdate));
       
    IF vflabonoferias = 'S' THEN
      
      IF TRUNC(MONTHS_BETWEEN(pdtcalculo, vdtinicio)) >= 12 AND
         TO_CHAR(pdtcalculo, 'MM') = TO_CHAR(vdtinicio, 'MM') THEN
        
        vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => PKGPAG_VAR.vgFormExpr,
                                                                       pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                                                       pCdRelacaoVinculo     => 0);
      
        IF vcdexpressaoformcalc > 0 THEN
        
          pkgpag_geral.pinserelancamentorelacao(pcdfolhapagamento     => pfolha.cdfolhapagamento,
                                                pcdvinculo            => ppensaonaoprev.CdVinculoBeneficiario,
                                                pcdrelacaovinculo     => 7,
                                                pcdhistrelacaovinculo => ppensaonaoprev.CdHistPensaoNaoPrev,
                                                pcdexpressaoformcalc  => vcdexpressaoformcalc,
                                                pcdrubricaagrupamento => prubrica.cdrubricaagrupamento,
                                                pvlintegral           => NULL,
                                                pvlproporcional       => NULL,
                                                pnusufixorubrica      => 1,
                                                pvlindice                => 30,
                                                pdtiniciorelacao         => ppensaonaoprev.dtiniciorelacao,
                                                pdtdesligamento          => ppensaonaoprev.dtfimrelacao,
                                                pcdunidadeorganizacional => ppensaonaoprev.cdunidadeorganizacional,
                                                pcdtipoorigemrubrica     => 7,
                                                pdtinicio                => ppensaonaoprev.dtinicio,
                                                pdtfim                   => ppensaonaoprev.dtfim);
        
        END IF;
        
      END IF;
      
    END IF;
    
  END;
  ------------------------------------------------------------------------

  PROCEDURE pprocessaeventosfuc(pvinculo   IN pkgpag_tipo.rvinculo,
                                pfolha     IN pkgpag_tipo.rfolha,
                                pevento    IN pkgpag_tipo.revento,
                                prubrica   IN pkgpag_tipo.trubrica,
                                pformexpr  IN pkgpag_tipo.tformulacalculo,
                                pfuc       IN pkgpag_tipo.tfuc,
                                pdtcalculo IN DATE) IS

    beventogerado BOOLEAN;

  BEGIN

    FOR j IN pFUC.FIRST .. pFUC.LAST LOOP

      beventogerado         := FALSE;
      pkgpag_var.vgtminicio := pkgpag_geral.fgettime;

      CASE

      -- 003 - Remuneracao fixa da funcao de chefia

        WHEN pevento.cdtipoeventopagamento = 3 THEN

          IF pevento.cdtipofuncaochefia = pfuc(j).cdtipofuncaochefia
            or  pfuc(j).cdtipofuncaochefia = 484 THEN

            IF pFolha.CdAgrupamento <> 134 -- Agrupamento Militar

             THEN

              beventogerado := TRUE;
              P003RemuneracaoFixaFUC(pFolha,
                                     pFUC(j),

                                     prubrica(pevento.cdrubricaagrupamento),
                                     pevento.flutilizaformulacalculo,
                                     pdtcalculo);
            ELSIF pevento.CdTipoFuncaoChefia = pfuc(j).cdtipofuncaochefiaprivativa

             THEN

              beventogerado := TRUE;
              P003RemuneracaoFixaFUC(pFolha,
                                     pFUC(j),

                                     prubrica(pevento.cdrubricaagrupamento),
                                     pevento.flutilizaformulacalculo,
                                     pdtcalculo);
            else
              null;
            END IF;

          END IF;

      --- Pagamento da dedicacao exclusiva do magisterio

        WHEN pevento.cdtipoeventopagamento = 84 THEN

          P084DedicExclusivaMagisterio(pFolha,
                                       pFUC(j),

                                       prubrica(pevento.cdrubricaagrupamento),
                                       pformexpr,

                                       pdtcalculo);

        ELSE
          NULL;
      END CASE;

      IF beventogerado THEN

        PKGPAG_GERAL.PLogTrace('EVFUCPNP - Evento Gerado ' ||
                               pEvento.CdTipoEventoPagamento,
                               pEvento.DeEvento || ' - FUC ' || j,
                               PKGPAG_VAR.vgTmInicio);

      ELSE

        PKGPAG_GERAL.PLogTrace('EVFUCPNP - Evento Não Gerado ' ||
                               pEvento.CdTipoEventoPagamento,
                               pEvento.DeEvento || ' - FUC ' || j,
                               PKGPAG_VAR.vgTmInicio);

      END IF;

    END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,

                              PKGPAG_VAR.vCdHistParamCalc,

                              PKGPAG_VAR.vCdPessoa,

                              'EVFUCPNP - Erro ao processar Evento (' ||
                              pEvento.CdTipoEventoPagamento || ') - ' ||
                              pEvento.DeEvento,

                              PKGPAG_VAR.vgCdVinculo);

  END;

  PROCEDURE pprocessaeventosfucsubst(pvinculo  IN pkgpag_tipo.rvinculo,
                                     pfolha    IN pkgpag_tipo.rfolha,
                                     pevento   IN pkgpag_tipo.revento,
                                     prubrica  IN pkgpag_tipo.trubrica,
                                     pformexpr IN pkgpag_tipo.tformulacalculo,
                                     pfucsubst IN pkgpag_tipo.tfuc) IS

    beventogerado BOOLEAN;
    pCdFolha      integer;

  BEGIN

    FOR j IN pFUCSubst.FIRST .. pFUCSubst.LAST LOOP

      beventogerado         := FALSE;
      pkgpag_var.vgtminicio := pkgpag_geral.fgettime;

      CASE

      -- 006 - Pagamento de adicional de tempo de servico

        WHEN pEvento.CdTipoEventoPagamento = 6 and
             pFolha.CdAgrupamento = 176 THEN

          bEventoGerado := TRUE;

          -----------------------------------------------------------------------------
          -- Inicializa os percentuais totais a acumular
          -----------------------------------------------------------------------------

          IF NOT
              PKGPAG_VAR.vPercentualTotalATS.EXISTS(pEvento.CdTipoTempoServico) THEN

            PKGPAG_VAR.vPercentualTotalATS(pEvento.CdTipoTempoServico) := 0;

          END IF;

          pCdFolha := pkgpag_var.vgFolha.CdFolhaPagamento;

          P006AdicionalTempoServicoDPE(pCdVinculo                 => pVinculo.CdVinculo,
                                       pCdFolha                   => pCdFolha,
                                       pDtInicioMes               => pFolha.DtInicioMes,
                                       pDtFimMes                  => pFolha.DtFimMes,
                                       pDtInicioConquistaPerAquis => pEvento.DtInicioConquistaPerAquis,
                                       pDtFimConquistaPerAquis    => pEvento.DtFimConquistaPerAquis,
                                       pCdTipoTempoServico        => pEvento.CdTipoTempoServico,
                                       pCdRubrica                 => pEvento.CdRubricaAgrupamento,
                                       pCdHistFuncaoChefia        => pfucsubst(j).CdHistFuncaoChefia,
                                       pDtInicioRelacao           => pfucsubst(j).DtInicioRelacao,
                                       pDtFimRelacao              => pfucsubst(j).DtFimRelacao,
                                       pCdUnidadeOrganizacional   => pfucsubst(j).CdUnidadeOrganizacional,
                                       pDtInicio                  => pfucsubst(j).DtInicio,
                                       pDtFim                     => pfucsubst(j).DtFim,
                                       pFormExpr                  => pFormExpr);

      -- 014 - Remuneracao fixa da substituicao da funcao de chefia

        WHEN pevento.cdtipoeventopagamento = 14

             AND
             pevento.cdtipofuncaochefia = pfucSubst(j).cdtipofuncaochefia

         THEN

          IF pFolha.CdAgrupamento <> 134 -- Agrupamento Militar

           THEN

            beventogerado := TRUE;

            P014SubstituicaoFUC(pFolha,
                                pFUCSubst(j),
                                prubrica(pevento.cdrubricaagrupamento),
                                pformexpr);

          ELSIF pevento.CdTipoFuncaoChefia = pfucSubst(j).cdtipofuncaochefiaprivativa THEN

            beventogerado := TRUE;

            P014SubstituicaoFUC(pFolha,
                                pFUCSubst(j),
                                prubrica(pevento.cdrubricaagrupamento),
                                pformexpr);
          else
            null;
          END IF;

        ELSE
          NULL;
      END CASE;

      IF beventogerado THEN

        PKGPAG_GERAL.PLogTrace('EVFUCPNP - Evento Gerado ' ||
                               pEvento.CdTipoEventoPagamento,
                               pEvento.DeEvento || ' - FUCSubst ' || j,
                               PKGPAG_VAR.vgTmInicio);

      ELSE

        PKGPAG_GERAL.PLogTrace('EVFUCPNP - Evento Não Gerado ' ||
                               pEvento.CdTipoEventoPagamento,
                               pEvento.DeEvento || ' - FUCSubst ' || j,
                               PKGPAG_VAR.vgTmInicio);

      END IF;

    END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,

                              PKGPAG_VAR.vCdHistParamCalc,

                              PKGPAG_VAR.vCdPessoa,

                              'EVFUCSUBST - Erro ao processar Evento (' ||
                              pEvento.CdTipoEventoPagamento || ') - ' ||
                              pEvento.DeEvento,

                              PKGPAG_VAR.vgCdVinculo);

  END;

  PROCEDURE pprocessaeventospnp(pvinculo       IN pkgpag_tipo.rvinculo,
                                pfolha         IN pkgpag_tipo.rfolha,
                                pevento        IN pkgpag_tipo.revento,
                                prubrica       IN pkgpag_tipo.trubrica,
                                ppensaonaoprev IN pkgpag_tipo.tpensaonaoprev,
                                pdtcalculo     IN DATE) IS

    beventogerado BOOLEAN;

  BEGIN

    FOR j IN pPensaoNaoPrev.FIRST .. pPensaoNaoPrev.LAST LOOP

      beventogerado         := FALSE;
      pkgpag_var.vgtminicio := pkgpag_geral.fgettime;

      CASE

      -- 061 - Remuneracao fixa de pensao nao previdenciaria

        WHEN pevento.cdtipoeventopagamento = 61 THEN

          beventogerado := TRUE;

          IF pEvento.CdTipoPensaoNaoPrev = pPensaoNaoPrev(j).CdTipoPensaoNaoPrev THEN

            p061remuneracaopensaonaoprev(ppensaonaoprev => ppensaonaoprev(j),
                                         pfolha         => pfolha,
                                         prubrica       => prubrica(pevento.cdrubricaagrupamento),
                                         pdtcalculo     => pdtcalculo);
          END IF;
          
 

      -- 129 - Pagamento Férias Judiciais
      
        WHEN pevento.cdtipoeventopagamento = 129 THEN
	       
          --23662/2025 - GPENP - CRIAR EVENTO DE PAGAMENTO PARA FERIAS JUDICIAIS
         
          beventogerado := TRUE;

          p129FeriasJudiciais(ppensaonaoprev => ppensaonaoprev(j),
                              pfolha         => pfolha,
                              prubrica       => prubrica(pevento.cdrubricaagrupamento),
                              pdtcalculo     => pdtcalculo);        
          
        ELSE
          NULL;
      END CASE;

      IF beventogerado THEN

        PKGPAG_GERAL.PLogTrace('EVFUCPNP - Evento Gerado ' ||
                               pEvento.CdTipoEventoPagamento,
                               pEvento.DeEvento || ' - PNP ' || j,
                               PKGPAG_VAR.vgTmInicio);

      ELSE

        PKGPAG_GERAL.PLogTrace('EVFUCPNP - Evento Não Gerado ' ||
                               pEvento.CdTipoEventoPagamento,
                               pEvento.DeEvento || ' - PNP ' || j,
                               PKGPAG_VAR.vgTmInicio);

      END IF;

    END LOOP;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,

                              PKGPAG_VAR.vCdHistParamCalc,

                              PKGPAG_VAR.vCdPessoa,

                              'EVFUCPNP - Erro ao processar Evento (' ||
                              pEvento.CdTipoEventoPagamento || ') - ' ||
                              pEvento.DeEvento,

                              PKGPAG_VAR.vgCdVinculo);

  END;
  ---
  FUNCTION FSubsmesmafucmesmoperio(pcdfolhapagamento     IN NUMBER,
                                   Pcdvinculo            IN NUMBER,
                                   pcdrubricaagrupamento IN NUMBER,
                                   pdtinicio             IN DATE,
                                   pdtfim                IN DATE DEFAULT NULL)

   RETURN boolean IS

    vnusmes INTEGER;

  BEGIN

    select count(*)
      into vnusmes
      from epaghistoricorubricarelvinc hrv
     where hrv.cdfolhapagamento = pcdfolhapagamento
       and hrv.cdvinculo = Pcdvinculo
       and hrv.cdrubricaagrupamento = pcdrubricaagrupamento
       and hrv.dtinicio >= pdtinicio
       and hrv.dtfim <= pdtfim;

    IF vnusmes > 0 THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END;

END pkgpag_evfucpnp;
/
