CREATE OR REPLACE PACKAGE PKGPAG_RT IS

TYPE rLancRetroativo IS RECORD
    (CdRubricaAgrupamento         INTEGER,
     CdLancamentoFinanceiro       INTEGER,
     NuSufixoRubrica              INTEGER,
     VlLancamentoFinanceiro       NUMBER(13,2),
     FlPagaAfastDefinitivo        CHAR(1),
     DtInicio                     DATE,
     DtFim                        DATE,
     VlIndice                     NUMBER(7,4),
     QtParcelasPagas              INTEGER,
     VlPago                       NUMBER(13,2),
     FlObservaLimRetroativoErario CHAR(1),
     NuOrdem                      INTEGER,
     NuRubrica                    INTEGER);

   TYPE tLancRetroativo IS TABLE OF rLancRetroativo INDEX BY PLS_INTEGER;

  TYPE rProcessoRetroativo IS RECORD
    (CdProcessoPagRetroativo      INTEGER,
     CdLancamentoFinanceiro       integer,
     NuSeqRubrica                 INTEGER,
     DeProcessoRetroativo         VARCHAR2(20),
     NuMeses                      INTEGER,
     VlIndiceNMRRA                NUMBER(5,2),
     NuAnoInicioRestituicao       NUMBER(4),
     NuMesInicioRestituicao       NUMBER(2),
     NuAnoFimRestituicao          NUMBER(4),
     NuMesFimRestituicao          NUMBER(2),
     DtAtivacaoProcesso           DATE,
     VlMontante                   NUMBER(13,2),
     VlRestituir                  NUMBER(13,2),
     VlRetroativoMigrado          NUMBER(13,2),
     FlObservaLimite              CHAR(1),
     NuAnoInicioDevolucao         NUMBER(4),
     VlPago                       NUMBER(13,2),
     QtParcelasPagas              INTEGER,
     LsLanc                       tLancRetroativo);

  TYPE tProcessoRetroativo IS TABLE OF rProcessoRetroativo INDEX BY PLS_INTEGER;

  TYPE rDecJudRetro IS RECORD
    (CdProcessoPagRetroativo        INTEGER,
     FlIsentaIRRF                   CHAR(1),
     FlIsentaIprev                  CHAR(1),
     FlDevolverTributosDescontados  CHAR(1),
     DtConcessaoIsencao             DATE,
     DtInclusao                     DATE);

  TYPE tDecJudRetro IS TABLE OF rDecJudRetro INDEX BY PLS_INTEGER;

  eValLimRet                    EXCEPTION;

  vCdRubAgpIPREVFundFinDifDesc  INTEGER; -- Codigo da 06-0915

  vCdRubAgpIPREVFundPrevDifDesc INTEGER; -- Codigo da 06-0926

  vCdRubAgpIprevLC66215DifDesc  integer; -- Codigo da 06-1328

  vCdRubAgpRessarcCPSM          integer; -- Codigo 06-0385 - RESSARCIMENTO CPSM

  vCdRubrAgpDifAbonoPerm        INTEGER; -- Codigo da 02-0914

  vCdRubrAgpDifAbonoPerm10      INTEGER; -- Codigo da 10-0914

  vCdRubrAgpDifAbonoPerm12      INTEGER; -- Codigo da 12-0914

  vgProcessoRetroativo          tProcessoRetroativo;

  vgDecJudRetro                 tDecJudRetro;

  FUNCTION FDecJudIsencaoTributacao(pFolha     IN PKGPAG_TIPO.rFolha,
                                   pCdVinculo IN INTEGER)
   RETURN tDecJudRetro;

  PROCEDURE SetaRubDifDescIPREV(pcdAgrupamento IN INTEGER);

  PROCEDURE pajustaparcelanaocomputadaRET(pCdProcessoPagRetroativo in integer,
                                        pcdlancamentofinanceiro  IN INTEGER,
                                        pcdvinculo               IN INTEGER);

  PROCEDURE PAtualizaParcelaRetroativo(pFolha      IN  PKGPAG_TIPO.rFolha,
                                       pCdVinculo IN INTEGER);

  PROCEDURE PExcluiHistoricoRetroSupl(pFolha     IN PKGPAG_TIPO.rFolha,
                                      pCdVinculo IN INTEGER);

  PROCEDURE PRetroativos(pFolha               IN PKGPAG_TIPO.rFolha,
                         pCdVinculo           IN INTEGER,
                         pFlCalculoDefinitivo IN CHAR DEFAULT 'N');

  FUNCTION FNuMesesRRA(pCdProcessoPagRetroativo IN INTEGER,
                       pNuAnoReferencia IN INTEGER) RETURN INTEGER;

END PKGPAG_RT;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_RT IS

 FUNCTION FNuMesesRRA(pCdProcessoPagRetroativo IN INTEGER,
                      pNuAnoReferencia IN INTEGER) RETURN INTEGER
 IS

   vNuMesesRRA INTEGER;

 BEGIN

    SELECT COUNT(CASE WHEN NUMESES > 0 THEN 1 END)+
           COUNT(CASE WHEN NUMESES13 > 0 THEN 1 END)
    INTO vNuMesesRRA
    FROM (
        SELECT RD.NUANOCOMPETENCIA, RD.NUMESCOMPETENCIA,
               COUNT(CASE WHEN R.NuRubrica <> 23 THEN 1 END ) AS NUMESES,
               COUNT(CASE WHEN R.NuRubrica = 23 THEN 1 END ) AS NUMESES13
        FROM eretprocessopagretroativo PR
        INNER JOIN eretprocessorestituicoesdevida RD
         ON RD.cdprocessopagretroativo = PR.cdprocessopagretroativo
         AND RD.VLRESTITUIRCOMINCIDENCIA+RD.VLRESTITUIRSEMINCIDENCIA > 0
         AND RD.FLAUTOMATICO = 'N'
        INNER JOIN EPagRubricaAgrupamento RA
         ON RA.CdRubricaAgrupamento = RD.CdRubricaAgrupamento
        INNER JOIN EPagRubrica R
         ON R.CdRubrica = RA.CdRubrica
        WHERE (
                (EXISTS (SELECT 1
                        FROM EPagBaseCalcBlocoExprRubAgrup RX
                        INNER JOIN EPagBaseCalculoBlocoExpressao EX
                         ON RX.CdBaseCalculoBlocoExpressao = EX.CdBaseCalculoBlocoExpressao
                        INNER JOIN EPagBaseCalculoBloco BCB
                         ON BCB.CdBaseCalculoBloco = EX.CdBaseCalculoBloco
                        INNER JOIN EPagHistBaseCalculo HBC
                         ON BCB.CdHistBaseCalculo = HBC.CdHistBaseCalculo
                        INNER JOIN vpagrubricaagrupamento vp
                         ON vp.cdrubricaagrupamento = rx.cdrubricaagrupamento
                         AND vp.cdtiporubrica in (2,10,12)
                        WHERE RX.CdRubricaAgrupamento = RD.CdRubricaAgrupamento
                         AND HBC.CdHistBaseCalculo = (
                              select hbc.cdhistbasecalculo
                              from epaghistbasecalculo hbc
                              inner join epagbasecalculoversao bcv
                              on bcv.cdversaobasecalculo = hbc.cdversaobasecalculo
                              inner join epagbasecalculo bc
                              on bc.cdbasecalculo = bcv.cdbasecalculo
                              where bc.SGBASECALCULO = 'BIRRF' -- BASE DO IMPOSTO DE RENDA
                              and hbc.nuanofimvigencia is null
                              and bcv.nuversao = 1
                              and bc.cdagrupamento = vp.cdagrupamento
                              and rownum < 2)
                        )
                 )
                 OR
                 ( R.NuRubrica in (23, 56) )
          )
          AND PR.CDPROCESSOPAGRETROATIVO = pCdProcessoPagRetroativo
          AND RD.NUANOCOMPETENCIA < pNuAnoReferencia
          GROUP BY RD.NUANOCOMPETENCIA, RD.NUMESCOMPETENCIA
      );

      IF vNuMesesRRA <= 0 THEN
        vNuMesesRRA := 1;
      END IF;

      RETURN vNuMesesRRA;

 EXCEPTION
   WHEN OTHERS THEN
     RETURN 0;

 END FNuMesesRRA;

 --
 -- Verificar se a rubrica incluida no retroativo faz parte de alguma formula de calculo e reprocessar
 --
  procedure pRecalcularRubricas (pCdRubricaAgrupamento in integer) is

    vHistRubRelVinc epaghistoricorubricarelvinc%rowtype;

    vCdRub integer;

    vvlCalculadoRubrica pkgpag_tipo.rValorPagamento;

  begin
      for form in (select efh.cdformulaversao
                     from epagformcalcblocoexprubagrup efg
                     inner join epagformulacalcblocoexpressao efe
                             on (efe.cdformulacalcblocoexpressao = efg.cdformulacalcblocoexpressao)
                     inner join epagformulacalculobloco efb
                             on (efb.cdformulacalculobloco = efe.cdformulacalculobloco)
                     inner join epagexpressaoformcalc  eex
                             on (eex.cdexpressaoformcalc = efb.cdexpressaoformcalc)
                     inner join epaghistformulacalculo efh
                             on (efh.cdhistformulacalculo = eex.cdhistformulacalculo and
                                 efh.nuanofim is null)
                     where efg.cdrubricaagrupamento = pCdRubricaAgrupamento)

        loop
           begin

           select epf.cdrubricaagrupamento
             into vCdRub
             from  epagformulaversao efv
             inner join epagformulacalculo epf
                     on (epf.cdformulacalculo = efv.cdformulacalculo)
             where efv.cdformulaversao = form.cdformulaversao;

          if pkgpag_var.vgValorCalculoRubrica.Count > 0 and pkgpag_var.vgValorCalculoRubrica.exists(vCdRub)
             then
              begin

              vHistRubRelVinc.Vlreal := null;

              select *
                into vHistRubRelVinc
                 from epaghistoricorubricarelvinc hrv
               where hrv.cdrubricaagrupamento = vCdRub
                 and hrv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
                 and hrv.cdvinculo = pkgpag_var.vgVinculo.CdVinculo
                 and rownum < 2;

              exception
                when no_data_found
                  then
                    vHistRubRelVinc.Vlreal := null;

                when others
                   then
                    vHistRubRelVinc.Vlreal := null;

              end;

              if vHistRubRelVinc.Vlreal is not null
                 then

                 begin
                   select hv.vlpagamento
                     into vvlCalculadoRubrica.vlReal
                     from epaghistoricorubricavinculo hv
                    where hv.cdrubricaagrupamento = vCdRub
                      and hv.cdfolhapagamento = pkgpag_var.vgFolha.Cdfolhapagamento
                      and hv.cdvinculo = pkgpag_var.vgVinculo.CdVinculo;

                 exception
                   when no_data_found then
                     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento    => vHistRubRelVinc.CdFolhaPagamento,
                                                      pCdVinculo                 => vHistRubRelVinc.CdVinculo,
                                                      pCdExpressaoFormCalc       => vHistRubRelVinc.Cdexpressaoformcalc,
                                                      pCdRubricaAgrupamento      => vHistRubRelVinc.CdRubricaAgrupamento,
                                                      pNuSufixoRubrica           => vHistRubRelVinc.NuSufixoRubrica,
                                                      pVlPagamento               => 0,
                                                      pVlIndice                  => vHistRubRelVinc.Vlindicerubrica,
                                                      pCdLancamentoFinanceiro    => null,
                                                      pCdTipoOrigemRubrica       => vHistRubRelVinc.Cdtipoorigemrubrica,
                                                      pCdTipoIndice              => vHistRubRelVinc.Cdtipoindice );
                 end;
                 PKGPAG_FB.PProcessaFormulasBases(pFolha           => pkgpag_var.vgFolha,
                                                  pCdVinculo       => pkgpag_var.VgVinculo.CdVinculo,
                                                  pCdRubrica       => vCdRub,
                                                  pTpProcessamento => 1, --formula de calculo
                                                  pTpLocal         => 2);

              end if;

           end if;

           exception
             when no_data_found then
               null;
             when others then
               null;
           end;

        end loop;

 end;

 FUNCTION fRetornaSaldoErario(pCdProcessoRestituicaoErario IN INTEGER,
                              pTipoSaldo IN CHAR DEFAULT NULL) -- P = Pago

    RETURN NUMBER IS

    vVlSaldo NUMBER(13,2);
    vVlPago NUMBER(13,2);

 BEGIN

    vVlSaldo := 0;
    vVlPago  := 0;

    --
    -- Se o tipo de retorno solicitado nao for so os pagos, verifica a inclusao
    --
    IF pTipoSaldo <> 'P'
      THEN

        SELECT SUM(MR.VlRestituir) vlRestituir
           INTO vVlSaldo
           FROM Erepprocessorestituicaoerario RE
           INNER JOIN ERepProcessoMontanteRestituir MR
           ON MR.Cdprocessorestituicaoerario =
              RE.Cdprocessorestituicaoerario
           WHERE RE.CdProcessoRestituicaoErario = pCdProcessoRestituicaoErario;

    END IF;

    SELECT SUM(LP.VlParcela)
      INTO vVlPago
      FROM EPagLancamentoFinanceiro LF
      INNER JOIN Epagpagamentolancamento LP
         ON LP.CdLancamentoFinanceiro =
            LF.CdLancamentoFinanceiro
      WHERE LF.CdProcessoRestituicaoErario = pCdProcessoRestituicaoErario;

    RETURN NVL(vVlSaldo,0) - NVL(vVlPago,0);

    EXCEPTION
      WHEN NO_DATA_FOUND
        THEN
          Return vVlSaldo;

      WHEN OTHERS
        THEN
          RETURN vVlSaldo;
  END;

  function fIsencaoParteContribuicao (pCdVinculo in integer)
   return boolean is

   vCont integer := 0;

  begin

   SELECT 1
     into vCont
     FROM ETrbIsencaoParteContribuicao IC
    INNER JOIN Etrbhistisencaopartecontrib HIC
       ON IC.Cdisencaopartecontribuicao = HIC.Cdisencaopartecontribuicao
    WHERE IC.Cdvinculo = pCdVinculo
      AND HIC.Flanulado = PKGPAG_TIPO.cnN
      AND ((HIC.nuAnoInicioVigencia < pkgpag_var.vgFolha.NuAnoReferencia OR
           (HIC.nuAnoInicioVigencia = pkgpag_var.vgFolha.NuAnoReferencia AND
           HIC.nuMesInicioVigencia <= pkgpag_var.vgFolha.NuMesReferencia))
      AND (HIC.nuAnoFimVigencia > pkgpag_var.vgFolha.NuAnoReferencia OR
          (HIC.nuAnoFimVigencia = pkgpag_var.vgFolha.NuAnoReferencia AND
           HIC.nuMesFimVigencia >= pkgpag_var.vgFolha.NuMesReferencia) OR
           HIC.nuAnoFimVigencia IS NULL))
      and rownum < 2;

    if vCont = 1
      then
        return true;
    else
      return false;
    end if;

    exception
      when no_data_found
        then
          return false;
      when others
        then
          return false;

end;

PROCEDURE pajustaparcelanaocomputadaRET(pCdProcessoPagRetroativo in integer,
                                        pcdlancamentofinanceiro  IN INTEGER,
                                        pcdvinculo               IN INTEGER) IS

  bInclusao boolean := false;

BEGIN

  FOR rec IN (SELECT hrv.cdhistoricorubricavinculo,
                     hrv.vlpagamento,
                     fp.nuanoreferencia,
                     fp.numesreferencia
                FROM epaghistoricorubricavinculo hrv
                INNER JOIN epagfolhapagamento fp
                        ON fp.cdfolhapagamento = hrv.cdfolhapagamento
                 AND fp.flcalculodefinitivo = 'S'
               WHERE hrv.cdvinculo = pCdVinculo
                 AND hrv.cdlancamentofinanceiro = pcdlancamentofinanceiro
                 and not exists (select 1 from epagpagamentolancamento pag
                                  where pag.cdlancamentofinanceiro = pcdlancamentofinanceiro
                                    and pag.nuanoreferencia = fp.nuanoreferencia
                                    and pag.numesreferencia = fp.numesreferencia)) LOOP

      PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => pcdlancamentofinanceiro,
                                          pNuAnoReferencia => rec.nuanoreferencia,
                                          pNuMesreferencia => rec.numesreferencia,
                                          pNuParcela => 1,
                                          pValorParcela => rec.vlpagamento);

      binclusao := true;

      pkgpag_geral.pinserelog(pinsere                  => pkgpag_var.blog,
                              pcdhistoricoparamcalculo => pkgpag_var.vcdhistparamcalc,
                              pcdpessoa                => pkgpag_var.vcdpessoa,
                              pdelog                   => 'Incluído parcela de retroativo não computada referente ao ano de ' ||
                                                          rec.nuanoreferencia || ' mês ' || rec.numesreferencia,
                              pcdvinculo               => pcdvinculo,
                              pcdtipoocorrencia        => 2);

  END LOOP;

  if bInclusao then

     MERGE INTO epagpagamentolancamento epl
        USING (select pag.cdpagamentolancamento,
                      rank() over (order by pag.nuanoreferencia, pag.numesreferencia) parcela
                 from epagpagamentolancamento pag
                where pag.cdlancamentofinanceiro = pcdlancamentofinanceiro)  xx
           ON (xx.cdpagamentolancamento = epl.cdpagamentolancamento)
           WHEN MATCHED THEN
           UPDATE SET epl.nuparcela = xx.parcela;

  end if;

EXCEPTION

  WHEN OTHERS THEN

    pkgpag_geral.pinserelog(pkgpag_var.blog,
                            pkgpag_var.vcdhistparamcalc,
                            pkgpag_var.vcdpessoa,
                            'Erro ao inserir parcela de retroativo não computada: Código do lançamento: ' ||
                            pcdlancamentofinanceiro ||
                            '. Código do processo de retroativo: ' ||
                            pCdProcessoPagRetroativo,
                            pkgpag_var.vgcdvinculo);
END;

  FUNCTION fRetornaSaldoRetroativo(pCdProcessoPagRetroativo IN INTEGER)

    RETURN NUMBER IS

    vVlSaldo NUMBER(13,2);
    vVlPago NUMBER(13,2);

  BEGIN

    vVlSaldo := 0;
    vVlPago  := 0;

    SELECT SUM(MR.VlRestituir) vlRestituir
      INTO vVlSaldo
      FROM ERetProcessopagretroativo RT
      INNER JOIN ERetProcessoMontanteRestituir MR
         ON MR.CdProcessoPagRetroativo =
            RT.CdProcessoPagRetroativo
      WHERE RT.Cdprocessopagretroativo = pCdProcessoPagRetroativo;

    SELECT SUM(LP.VlParcela)
      INTO vVlPago
      FROM EPagLancamentoFinanceiro LF
      INNER JOIN Epagpagamentolancamento LP
         ON LP.CdLancamentoFinanceiro =
            LF.CdLancamentoFinanceiro
      WHERE LF.Cdprocessopagretroativo = pCdProcessoPagRetroativo;

    RETURN NVL(vVlSaldo,0) - NVL(vVlPago,0);

    EXCEPTION
      WHEN NO_DATA_FOUND
        THEN
          Return vVlSaldo;

      WHEN OTHERS
        THEN
          RETURN vVlSaldo;
  END;

  FUNCTION FRetornaRetroativos(pFolha       IN PKGPAG_TIPO.rFolha,
                               pCdVinculo   IN INTEGER,
                               pDtInicioMes IN DATE,
                               pDtFimMes    IN DATE)

    RETURN tProcessoRetroativo IS

    --cCursor         TYPES.ref_cursor;

    tabResultado    tProcessoRetroativo;

    iProc           INTEGER;

    iLanc           INTEGER;

    vCdBaseCalculo  INTEGER;

    vBaseCalcIRRF   PKGPAG_TIPO.rBaseCalculo;

    vNuAnoMes       INTEGER;

    vProcAnt        INTEGER;

    vProcAceito     BOOLEAN;

    vFlSuspensa                    char(1) := 'N';

    CURSOR  cCursorRRAJunto IS
       SELECT *
         FROM
       (SELECT LF.CdRubricaAgrupamento,
               LF.CdLancamentoFinanceiro,
               LF.NuSufixoRubrica,
               LF.VlLancamentoFinanceiro,
               LF.FlPagaAfastDefinitivo,
               CASE
                 WHEN LF.DtInicioDireito > pDtInicioMes THEN
                   LF.DtInicioDireito
                 ELSE
                   pDtInicioMes
               END DtInicio,
               CASE
                 WHEN (LF.DtFimDireito > pDtFimMes OR LF.DtFimDireito IS NULL) THEN
                   pDtFimMes
                 ELSE
                   LF.DtFimDireito
               END DtFim,
               LF.VlIndice,
               NVL(P.QtParcelasPagas,0) AS QtParcelasPagas,
               NVL(P.VlPago,0) AS VlPago,
               LF.CdProcessoPagRetroativo,
               RT.NuProcesso as DeProcessoRetroativo,
               LF.FlObservaLimRetroativoErario,
               CASE R.CdTipoRubrica
                  WHEN 10 THEN
                    1
                  WHEN 12 THEN
                    2
                  WHEN 6 THEN
                    3
                  WHEN 5 THEN
                    4
                  WHEN 2 THEN
                    CASE R.NuRubrica
                      WHEN 95 THEN
                        5
                      WHEN 53 THEN
                        6
                    ELSE
                      7
                    END
               ELSE
                 7
               END AS NuOrdem,
               R.NuRubrica,
               RT.NuAnoInicioRestituicao,
               RT.NuMesInicioRestituicao,
               RT.NuAnoFinalRestituicao,
               RT.NuMesFinalRestituicao,
               RT.DtAtivacaoProcesso,
               0 AS VlMontante,
               0 AS VlRestituir,
               0 AS VlRetroativoMigrado,
               0 AS NuAnoInicioDevolucao,
               RT.FlObservaLimite
          FROM EPagLancamentoFinanceiro LF
          INNER JOIN ERetProcessoPagRetroativo RT
             ON RT.CdProcessoPagRetroativo = LF.CdProcessoPagRetroativo
          LEFT JOIN (SELECT PL.CdLancamentoFinanceiro,
                            COUNT(*) AS qtParcelasPagas,
                            SUM(PL.VlParcela) AS vlPago
                       FROM EPagPagamentoLancamento PL
                      WHERE ((PL.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                             PL.NuMesReferencia < PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                             PL.NuAnoReferencia < PKGPAG_VAR.vgFolha.NuAnoReferencia)
                      GROUP BY PL.CdLancamentoFinanceiro) P
            ON LF.CdLancamentoFinanceiro = P.CdLancamentoFinanceiro
         INNER JOIN EPagRubricaAgrupamento RA
            ON LF.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
         INNER JOIN EPagRubrica R
            ON R.CdRubrica = RA.CdRubrica
         WHERE LF.CdVinculo = pCdVinculo AND
               ( RT.CdSituacaoProcesso = 2
                 OR ( RT.CdSituacaoProcesso = 3 AND
                      RT.NuAnoMesFinalizacao >= vNuAnoMes )
               ) AND
               LF.FlAnulado = PKGPAG_TIPO.cnN AND
               LF.VlLancamentoFinanceiro > 0 AND
               LF.DtInicioDireito <= pDtFimMes AND
               (LF.DtFimDireito >= pDtInicioMes OR LF.DtFimDireito IS NULL) AND
               RT.FlAnulado = PKGPAG_TIPO.cnN AND
               LF.FlObservaLimRetroativoErario = 'S'
           /*and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                             from vpagrubricaagrupamento ra
                                            where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                              and ra.flsuspensa = PKGPAG_TIPO.cnN)*/
          -- and r.cdtiporubrica not in (10, 12)
        UNION ALL
         SELECT LF.CdRubricaAgrupamento,
                LF.CdLancamentoFinanceiro,
                LF.NuSufixoRubrica,
                LF.VlLancamentoFinanceiro,
                LF.FlPagaAfastDefinitivo,
                CASE
                  WHEN LF.DtInicioDireito > pDtInicioMes THEN
                    LF.DtInicioDireito
                  ELSE
                    pDtInicioMes
                END DtInicio,
               CASE
                 WHEN (LF.DtFimDireito > pDtFimMes OR LF.DtFimDireito IS NULL) THEN
                   pDtFimMes
                 ELSE
                   LF.DtFimDireito
               END DtFim,
               LF.VlIndice,
               NVL(P.QtParcelasPagas,0) AS QtParcelasPagas,
               NVL(P.VlPago,0) AS VlPago,
               LF.CdProcessoPagRetroativo,
               '' as DeProcessoRetroativo,
               LF.FlObservaLimRetroativoErario,
                CASE R.CdTipoRubrica
                  WHEN 10 THEN
                    1
                  WHEN 12 THEN
                    2
                  WHEN 6 THEN
                    3
                  WHEN 5 THEN
                    4
                  WHEN 2 THEN
                    CASE R.NuRubrica
                      WHEN 95 THEN
                        5
                      WHEN 53 THEN
                        6
                    ELSE
                      7
                    END
                  ELSE
                    7
                  END AS NuOrdem,
               R.NuRubrica,
               NULL AS NuAnoInicioRestituicao,
               NULL AS NuMesInicioRestituicao,
               NULL AS NuAnoFimRestituicao,
               NULL AS NuMesFimRestituicao,
               TO_DATE('01/01/1900', 'DD/MM/YYYY') AS DtAtivacaoProcesso,
               0 AS VlMontante,
               0 AS VlRestituir,
               0 AS VlRetroativoMigrado,
               0 AS NuAnoInicioDevolucao,
               'S' AS FlObservaLimite
          FROM EpagLancamentoFinanceiro LF
          LEFT JOIN (SELECT PL.CdLancamentoFinanceiro,
                            COUNT(*) AS qtParcelasPagas,
                            SUM(PL.VlParcela) AS vlPago
                       FROM EPagPagamentoLancamento PL
                      WHERE ((PL.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                             PL.NuMesReferencia < PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                             PL.NuAnoReferencia < PKGPAG_VAR.vgFolha.NuAnoReferencia)
                      GROUP BY PL.CdLancamentoFinanceiro) P
            ON LF.CdLancamentoFinanceiro = P.CdLancamentoFinanceiro
         INNER JOIN EPagRubricaAgrupamento RA
            ON LF.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
         INNER JOIN EPagRubrica R
            ON R.CdRubrica = RA.CdRubrica
         WHERE LF.CdVinculo = pCdVinculo AND
               LF.FlAnulado = PKGPAG_TIPO.cnN AND
               ((R.CdTipoRubrica IN (10,12) AND
               LF.FlFolhaSuplementar = PKGPAG_TIPO.cnS) OR
               (R.CdTipoRubrica IN (1,2) AND R.NuRubrica IN (53,95))) AND
               LF.VlLancamentoFinanceiro > 0 AND
               LF.DtInicioDireito <= pDtFimMes AND
               (LF.DtFimDireito >= pDtInicioMes OR LF.DtFimDireito IS NULL)
           --and r.cdtiporubrica not in (10, 12)
           /*and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                             from vpagrubricaagrupamento ra
                                            where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                              and ra.flsuspensa = PKGPAG_TIPO.cnN)*/
               )
         ORDER BY NuOrdem,NuRubrica,NuSufixoRubrica ;

    CURSOR cCursorRRASep IS

     SELECT *
       FROM
     (SELECT LF.CdRubricaAgrupamento,
             LF.CdLancamentoFinanceiro,
             LF.NuSufixoRubrica,
             LF.VlLancamentoFinanceiro,
             LF.FlPagaAfastDefinitivo,
             CASE
               WHEN LF.DtInicioDireito > pDtInicioMes THEN
                 LF.DtInicioDireito
               ELSE
                 pDtInicioMes
             END DtInicio,
             CASE
               WHEN (LF.DtFimDireito > pDtFimMes OR LF.DtFimDireito IS NULL) THEN
                 pDtFimMes
               ELSE
                 LF.DtFimDireito
             END DtFim,
             LF.VlIndice,
             NVL(P.QtParcelasPagas,0) AS QtParcelasPagas,
             NVL(P.VlPago,0) AS VlPago,
             LF.CdProcessoPagRetroativo,
             RT.DeProcessoRetroativo,
             LF.FlObservaLimRetroativoErario,
             CASE R.CdTipoRubrica
               WHEN 10 THEN
                 1
               WHEN 12 THEN
                 2
               WHEN 6 THEN
                 3
               WHEN 5 THEN
                 4
               WHEN 2 THEN
                 CASE R.NuRubrica
                   WHEN 95 THEN
                     5
                   WHEN 53 THEN
                     6
                 ELSE
                   7
                 END
               ELSE
                 7
               END AS NuOrdem,
             R.NuRubrica,
             RT.NuAnoInicioRestituicao,
             RT.NuMesInicioRestituicao,
             RT.NuAnoFinalRestituicao,
             RT.NuMesFinalRestituicao,
             NVL(RT.DtAtivacaoProcesso,TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS DtAtivacaoProcesso,
             RT.VlMontante,
             LF.VlLancamentoFinanceiro - NVL(P.VlPago,0) as VlRestituir,
             CASE
               WHEN LF.NuCPFCadastrador = '11111111111' THEN
                 CASE WHEN R.CdTipoRubrica IN (1,2) AND R.NuRubrica IN (53,95) THEN
                   VlLancamentoFinanceiro
               ELSE
                 0
               END
             ELSE
               NULL
             END AS VlRetroativoMigrado,
             NuAnoInicioDevolucao,
             FlObservaLimite
        FROM EPagLancamentoFinanceiro LF
        ---- AQUI ESTOU CONHECENDO O MONTANTE DE EXERCICIOS FINDOS DO PROCESSO DE RETROATIVO
       INNER JOIN (SELECT RT.CdProcessoPagRetroativo,
                          RT.DeProcessoRetroativo,
                          RT.NuAnoInicioRestituicao,
                          RT.NuMesInicioRestituicao,
                          RT.NuAnoFinalRestituicao,
                          RT.NuMesFinalRestituicao,
                          RT.DtAtivacaoProcesso,
                          RT.VlMontante,
                          RT.NuAnoInicioDevolucao,
                          RT.FlObservaLimite
                     FROM (SELECT RET.CdProcessoPagRetroativo,
                                  RET.NuProcesso as DeProcessoRetroativo,
                                  RET.NuAnoInicioRestituicao,
                                  RET.NuMesInicioRestituicao,
                                  RET.NuAnoFinalRestituicao,
                                  RET.NuMesFinalRestituicao,
                                  RET.FlRetroativoComplementar,
                                  RET.DtAtivacaoProcesso,
                                  MR.VlMontante,
                                  MR.NuAnoInicioDevolucao,
                                  RET.FlObservaLimite
                             FROM ERetProcessoPagRetroativo RET
                             LEFT JOIN (SELECT MR.CdProcessoPagRetroativo,
                                               MIN(MR.NuAnoInicioDevolucao) AS NuAnoInicioDevolucao,
                                               SUM(MR.VlRestituir) AS VlMontante
                                          FROM ERetProcessoMontanteRestituir MR
                                         INNER JOIN EPagRubricaAgrupamento RA
                                            ON RA.CdRubricaAgrupamento = MR.CdRubricaAgrupamento
                                         INNER JOIN EPagRubrica R
                                            ON R.CdRubrica = RA.CdRubrica
                                         WHERE (R.CdTipoRubrica IN (10,12) AND
                                               (EXISTS
                                                  (SELECT 1
                                                     FROM EPagBaseCalcBlocoExprRubAgrup RX
                                                    INNER JOIN EPagBaseCalculoBlocoExpressao EX
                                                       ON RX.CdBaseCalculoBlocoExpressao = EX.CdBaseCalculoBlocoExpressao
                                                    INNER JOIN EPagBaseCalculoBloco BCB
                                                       ON BCB.CdBaseCalculoBloco = EX.CdBaseCalculoBloco
                                                    INNER JOIN EPagHistBaseCalculo HBC
                                                       ON BCB.CdHistBaseCalculo = HBC.CdHistBaseCalculo
                                                    WHERE HBC.CdHistBaseCalculo = vBaseCalcIRRF.CdHistBaseCalculo AND
                                                          RX.CdRubricaAgrupamento = RA.CdRubricaAgrupamento)
                                            OR R.NuRubrica in (23,56,156,1914,984))) OR
                                              (R.CdTipoRubrica IN (1,2) AND R.NuRubrica IN (53,95))
                                         GROUP BY MR.CdProcessoPagRetroativo) MR
                               ON MR.CdProcessoPagRetroativo = RET.CdProcessoPagRetroativo
                            WHERE
                                  ( RET.CdSituacaoProcesso = 2
                                    OR ( RET.CdSituacaoProcesso = 3 AND
                                         RET.NuAnoMesFinalizacao >= vNuAnoMes )
                                  ) AND

                                  RET.FlAnulado = PKGPAG_TIPO.cnN AND
                                  RET.CdVinculo = pCdVinculo AND
                                  (pFolha.CdTipoCalculo <> PKGPAG_TIPO.cnTpCalculoRecalcCompl OR
                                  (pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalcCompl AND
                                  RET.FlRetroativoComplementar = PKGPAG_TIPO.cnS))
                            ORDER BY RET.DtAtivacaoProcesso,
                       RET.NuAnoInicioRestituicao,
                                     RET.NuMesInicioRestituicao) RT
                  /* WHERE ROWNUM < 2*/) RT
          ON RT.CdProcessoPagRetroativo = LF.CdProcessoPagRetroativo
          ----- FIM
        LEFT JOIN (SELECT PL.CdLancamentoFinanceiro,
                          COUNT(*) AS qtParcelasPagas,
                          SUM(PL.VlParcela) AS vlPago
                     FROM EPagPagamentoLancamento PL
                    WHERE ((PL.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                           PL.NuMesReferencia < PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                           PL.NuAnoReferencia < PKGPAG_VAR.vgFolha.NuAnoReferencia)
                    GROUP BY PL.CdLancamentoFinanceiro) P
          ON LF.CdLancamentoFinanceiro = P.CdLancamentoFinanceiro
       INNER JOIN EPagRubricaAgrupamento RA
          ON LF.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
       INNER JOIN EPagRubrica R
          ON R.CdRubrica = RA.CdRubrica
       WHERE LF.CdVinculo = pCdVinculo AND
             LF.FlAnulado = PKGPAG_TIPO.cnN AND
             LF.VlLancamentoFinanceiro > 0 AND
             LF.DtInicioDireito <= pDtFimMes AND
             (LF.DtFimDireito >= pDtInicioMes OR LF.DtFimDireito IS NULL) AND
             LF.FlObservaLimRetroativoErario = 'S'
         --and r.cdtiporubrica not in (10, 12)
         /*and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                                           from vpagrubricaagrupamento ra
                                          where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                                            and ra.flsuspensa = PKGPAG_TIPO.cnN)*/
       ORDER BY FlObservaLimite desc, -- S deve vir primeiro
             DtAtivacaoProcesso,
                NuAnoInicioRestituicao,
                NuMesInicioRestituicao,
                DtAtivacaoProcesso,
                CdProcessoPagRetroativo,
                NuOrdem);

    vProc       cCursorRRASep%ROWTYPE;

    -----------------------------------------------------------------------------
    -- FGeraLancamento: Verifica se existe decisao judicial isentando o IPREV.
    -- Caso exista e esteja vigente na data do calculo, nao ira carregar os
    -- lancamentos financeiros das rubricas 05-0915,06-0915, 05-0926, 06-0926 e 02-0914
    -----------------------------------------------------------------------------
    FUNCTION FGeraLancamento (pCdRubricaAgrupamento IN INTEGER)

       RETURN BOOLEAN IS

    BEGIN

       IF vgDecJudRetro.EXISTS(vProc.CdProcessoPagRetroativo) THEN

         IF vgDecJudRetro(vProc.CdProcessoPagRetroativo).FlIsentaIprev = 'S' THEN

           IF (NVL(vgDecJudRetro(vProc.CdProcessoPagRetroativo).DtConcessaoIsencao,
                   vgDecJudRetro(vProc.CdProcessoPagRetroativo).DtInclusao) <= pFolha.DtCalculo) THEN

             IF pCdRubricaAgrupamento IN (PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundFinanc,
                                          PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundPrev,
                                          vCdRubAgpIPREVFundFinDifDesc,
                                          vCdRubAgpIPREVFundPrevDifDesc,
                                          vCdRubAgpIprevLC66215DifDesc,
                                          vCdRubrAgpDifAbonoPerm,
                                          vCdRubrAgpDifAbonoPerm10,
                                          vCdRubrAgpDifAbonoPerm12) THEN

               RETURN FALSE;

             END IF;

           END IF;

         END IF;

       END IF;

       --
       -- Solicitacao de Sustentacao #78878
       -- 11598/2018 - MODULO RETROATIVO. Retiradas rubricas de Abono de permanencia
       --
     /*  if fIsencaoParteContribuicao(pkgpag_var.vgVinculo.CdVinculo)
          and pCdRubricaAgrupamento IN (PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundFinanc,
                                        PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundPrev,
                                        vCdRubAgpIPREVFundFinDifDesc,
                                        vCdRubAgpIPREVFundPrevDifDesc)
         then
           return false;
       end if;*/

       /*
       -- Não gerar rubricas 10 2 12 até o final de 2018, exceto para ACTs e decisão judicial
       BEGIN

       IF PKGPAG_VAR.vgFolha.cdagrupamento in (1,134,176) AND -- AGPE, Militares e Defensoria
          pkgpag_var.vgFolha.cdorgao NOT IN (34) AND -- exceção: 1506-ADMINISTRACAO DOS PENSIONISTAS DO ESTADO
          pkgpag_var.vgrubrica(pcdrubricaagrupamento).cdtiporubrica IN (10,12) AND
          NOT vgDecJudRetro.EXISTS(vProc.CdProcessoPagRetroativo) AND -- exceção: decisões judiciais
          (
              (PKGPAG_VAR.vgCEF.COUNT > 0 AND NOT PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho = PKGPAG_TIPO.cnRelACT) OR -- exceção: acts
              (PKGPAG_VAR.vgCEF.COUNT = 0)

          ) AND
          NOT ( pkgpag_var.vgFolha.cdorgao = 17 AND pkgpag_var.vgrubrica(pcdrubricaagrupamento).nurubrica IN (0914, 1914)  ) -- exceção:  Abono de Permanência para o órgão SSP (1001)
       THEN

          RETURN FALSE;

       END IF;

       EXCEPTION
         WHEN OTHERS THEN
           NULL;

       END;
       */

       RETURN TRUE;

    END;

  BEGIN

   vNuAnoMes := pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia;

   -----------------------------------------------------------------------------------------
   -- Seleciona os lancamentos financeiros referentes ao retroativo de exercicios findos
   -- Caso seja recalculo ou calculo retroativo, despreza os pagamentos
   -- realizados no mes ou posteriores.
   -----------------------------------------------------------------------------------------
   IF PKGPAG_VAR.vgParamPagamento.FlTributaRRASeparado = PKGPAG_TIPO.cnN THEN

     -----------------------------------------------------------------------------------------
     -- SQL de Retroativos quando o agrupamento nao tributa o RRA separado
     -----------------------------------------------------------------------------------------
     OPEN cCursorRRAJunto;

   ELSE

     -----------------------------------------------------------------------------------------
     -- SQL de Retroativos quando o agrupamento tributa o RRA separado
     -----------------------------------------------------------------------------------------
     vCdBaseCalculo := PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubBaseIRRF).CdBaseCalculo;

     vBaseCalcIRRF := PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo);

     OPEN cCursorRRASep;

   END IF;

   iProc := 0;

   vProcAnt := 0;

   LOOP

     IF PKGPAG_VAR.vgParamPagamento.FlTributaRRASeparado = PKGPAG_TIPO.cnN THEN

        FETCH cCursorRRAJunto INTO vProc;

        EXIT WHEN cCursorRRAJunto%NOTFOUND;

     ELSE

        FETCH cCursorRRASep INTO vProc;

        EXIT WHEN cCursorRRASep%NOTFOUND;

     END IF;

     begin

        vFlSuspensa := 'N';

        select rb.flsuspensa
          into vFlSuspensa
          from epaghistrubricaagrupamento rb
         where rb.cdrubricaagrupamento = vProc.CdRubricaAgrupamento
           and vproc.NuAnoInicioRestituicao * 100 + vProc.NuMesInicioRestituicao <=
               --nvl(rb.nuanofimvigencia || lpad(rb.numesfimvigencia,2,0), to_char(pFolha.DtInicioMes,'yyyymm')) -- que gambiarra from hell!!!
               (case when rb.nuanofimvigencia is null or rb.numesfimvigencia is null then to_number(to_char(pFolha.DtInicioMes, 'yyyymm'))
                     else rb.nuanofimvigencia * 100 + rb.numesfimvigencia end)
           and vProc.NuAnoFinalRestituicao * 100 + vProc.NuMesFinalRestituicao >= rb.nuanoiniciovigencia * 100 + rb.numesiniciovigencia
         and rownum < 2;

         if vFlSuspensa = 'S'
           then
             continue;
         end if;

         exception
           when others
             then
               vFlSuspensa := 'N';

     end;

     IF vProcAnt <> vProc.CdProcessoPagRetroativo THEN

       vProcAnt := vProc.CdProcessoPagRetroativo;

       vProcAceito := FALSE;

       IF iProc = 0 THEN

          vProcAceito := TRUE;

       ELSIF vProc.FlObservaLimite = 'N' THEN

         vProcAceito := TRUE;

       else
         null;
       END IF;

       IF vProcAceito THEN

         iProc := iProc + 1;

         iLanc := 0;

         tabResultado(iProc).CdProcessoPagRetroativo   := vProc.CdProcessoPagRetroativo;
         tabResultado(iProc).NuSeqRubrica              := iProc;
         tabResultado(iProc).DeProcessoRetroativo      := vProc.DeProcessoRetroativo;
         tabResultado(iProc).VlIndiceNMRRA             := NULL;
         tabResultado(iProc).NuAnoInicioRestituicao    := vProc.NuAnoInicioRestituicao;
         tabResultado(iProc).NuMesInicioRestituicao    := vProc.NuMesInicioRestituicao;
         tabResultado(iProc).NuAnoFimRestituicao       := vProc.NuAnoFinalRestituicao;
         tabResultado(iProc).NuMesFimRestituicao       := vProc.NuMesFinalRestituicao;
         tabResultado(iProc).DtAtivacaoProcesso        := vProc.DtAtivacaoProcesso;

         tabResultado(iProc).VlRestituir               := vProc.VlRestituir;
         tabResultado(iProc).VlRetroativoMigrado       := vProc.VlRetroativoMigrado;
         tabResultado(iProc).FlObservaLimite           := vProc.FlObservaLimite;
         tabResultado(iProc).NuAnoInicioDevolucao      := vProc.NuAnoInicioDevolucao;

         IF vProc.VlRetroativoMigrado IS NOT NULL THEN

           tabResultado(iProc).VlMontante             := 0;

         ELSE

           tabResultado(iProc).VlMontante             := vProc.VlMontante;

         END IF;

         tabResultado(iProc).NuMeses := FNuMesesRRA(tabResultado(iProc).CdProcessoPagRetroativo,
                                                    pFolha.NuAnoReferencia);

       END IF;

     END IF;

     IF vProcAceito THEN

       IF FGeraLancamento(vProc.CdRubricaAgrupamento) THEN

         iLanc := iLanc + 1;

         tabResultado(iProc).LsLanc(iLanc).CdRubricaAgrupamento         := vProc.CdRubricaAgrupamento;
         tabResultado(iProc).LsLanc(iLanc).CdLancamentoFinanceiro       := vProc.CdLancamentoFinanceiro;
         tabResultado(iProc).LsLanc(iLanc).NuSufixoRubrica              := vProc.NuSufixoRubrica;
         tabResultado(iProc).LsLanc(iLanc).VlLancamentoFinanceiro       := vProc.VlLancamentoFinanceiro;
         tabResultado(iProc).LsLanc(iLanc).FlPagaAfastDefinitivo        := vProc.FlPagaAfastDefinitivo;
         tabResultado(iProc).LsLanc(iLanc).DtInicio                     := vProc.DtInicio;
         tabResultado(iProc).LsLanc(iLanc).DtFim                        := vProc.DtFim;
         tabResultado(iProc).LsLanc(iLanc).VlIndice                     := vProc.VlIndice;
         tabResultado(iProc).LsLanc(iLanc).QtParcelasPagas              := vProc.QtParcelasPagas;
         tabResultado(iProc).LsLanc(iLanc).VlPago                       := vProc.VlPago;
         tabResultado(iProc).LsLanc(iLanc).FlObservaLimRetroativoErario := vProc.FlObservaLimRetroativoErario;
         tabResultado(iProc).LsLanc(iLanc).NuOrdem                      := vProc.NuOrdem;
         tabResultado(iProc).LsLanc(iLanc).NuRubrica                    := vProc.NuRubrica;

         IF tabResultado(iProc).VlRestituir < vProc.VlRestituir THEN

           tabResultado(iProc).VlRestituir := vProc.VlRestituir;

         END IF;

         IF vProc.VlRetroativoMigrado IS NOT NULL THEN

           tabResultado(iProc).VlMontante := tabResultado(iProc).VlMontante + vProc.VlRetroativoMigrado;

         END IF;

       END IF;

     END IF;

  END LOOP;

  IF PKGPAG_VAR.vgParamPagamento.FlTributaRRASeparado = PKGPAG_TIPO.cnN THEN

    CLOSE cCursorRRAJunto;

  ELSE

    CLOSE cCursorRRASep;

  END IF;

  RETURN tabResultado;

 END;

 FUNCTION FDecJudIsencaoTributacao(pFolha     IN PKGPAG_TIPO.rFolha,
                                   pCdVinculo IN INTEGER)
   RETURN tDecJudRetro IS

   vDecJudRetro tDecJudRetro;

 BEGIN

   FOR vRec IN ( SELECT IP.CdProcessoPagRetroativo,
                        IP.FlIsentaIRRF,
                        IP.FlIsentaIprev,
                        IP.FlDevolverTributosDescontados,
                        IP.DtConcessaoIsencao,
                        IP.DtInclusao
                   FROM ETrbIsencaoProcesso IP
                  WHERE IP.CdVinculo = pCdVinculo AND
                        (IP.NuAnoInicioVigencia*100+ IP.NuMesInicioVigencia) <=
                        (pFolha.NuAnoReferencia*100+ pFolha.NuMesReferencia) AND
                        IP.FlAnulado = 'N')
   LOOP

       vDecJudRetro(vRec.CdProcessoPagRetroativo) := vRec;

   END LOOP;

   RETURN vDecJudRetro;

 END;

--
-- Retorna o codigo do processo de restituicao ao erario se houver processo de compensacao.
--
FUNCTION FPossuiCompensacaoErario(pCdProcessoPagRetroativo IN INTEGER)

   RETURN INTEGER IS

   vCdProcessoRestituicaoErario INTEGER;

BEGIN

   SELECT CR.Cdprocessorestituicaoerario
     INTO vCdProcessoRestituicaoErario
     FROM ERetCompensaRetroErario CR
     WHERE CR.CdProcessoPagRetroativo  = pCdProcessoPagRetroativo
       AND CR.Flanulado = 'N'
       AND CR.Cdprocessorestituicaoerario IS NOT NULL
       AND CR.Cdsituacaoprocesso = 2; -- Ativos

   RETURN vCdProcessoRestituicaoErario;

   EXCEPTION
     WHEN OTHERS
       THEN
         RETURN 0;

 END;

 PROCEDURE PExcluiHistoricoRetroSupl(pFolha     IN PKGPAG_TIPO.rFolha,
                                     pCdVinculo IN INTEGER) IS

     vNuAnoMes INTEGER;

 BEGIN

      vNuAnoMes := pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia;

     DELETE
       FROM EPagPagamentoLancamento PL
      WHERE PL.NuAnoReferencia = pFolha.NuAnoReferencia AND
            PL.NuMesReferencia = pFolha.NuMesReferencia AND
            PL.CdLancamentoFinanceiro IN
            (SELECT CdLancamentoFinanceiro
               FROM EPagLancamentoFinanceiro LF
              WHERE --LF.FlObservaLimretroativoerario = PKGPAG_TIPO.cnS AND
                    LF.CdVinculo = pCdVinculo AND
                    LF.CdProcessoPagRetroativo IS NOT NULL AND
                    LF.DtInclusao >= pFolha.DtAbertura )
         --AUDITORIA: nao excluir parcela de meses que ja foram empenhados
         AND NOT EXISTS
            (SELECT 1
               FROM epaghistoricorubricavinculo rv
              INNER JOIN epagfolhapagamento fp
                 ON rv.cdfolhapagamento = fp.cdfolhapagamento
              WHERE rv.cdvinculo = pCdVinculo
                AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS
                AND fp.flfolhafechada = PKGPAG_TIPO.cnS
                AND fp.nuanoreferencia = pl.nuanoreferencia
                AND fp.numesreferencia = pl.numesreferencia
                AND rv.cdlancamentofinanceiro = pl.cdlancamentofinanceiro);

     UPDATE EPagLancamentoFinanceiro LF
        SET DtFimDireito = NULL
      WHERE LF.CdVinculo = pCdVinculo AND
            LF.DtFimDireito = pFolha.DtFimMes AND
            --LF.FlObservaLimRetroativoErario = PKGPAG_TIPO.cnS AND
            LF.CdProcessoPagRetroativo IS NOT NULL  AND
            LF.DtInclusao >= pFolha.DtAbertura;

     UPDATE ERetProcessoPagRetroativo RT
        SET RT.CdSituacaoProcesso = 2
     WHERE  RT.CdVinculo = pCdVinculo AND
            RT.CdSituacaoProcesso = 3 AND
            RT.NuAnoMesFinalizacao = vNuAnoMes AND
            ((RT.DtInclusao >= pFolha.DtAbertura AND RT.DtAtivacaoProcesso IS NULL) OR
             (RT.DtAtivacaoProcesso >= pFolha.DtAbertura));

   END;

   PROCEDURE PExcluiHistoricoRetro(pFolha     IN PKGPAG_TIPO.rFolha,
                                   pCdVinculo IN INTEGER) IS

     vNuAnoMes INTEGER;

   BEGIN

      vNuAnoMes := pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia;

     DELETE
       FROM EpagPagamentoLancamento PL
      WHERE PL.NuAnoReferencia = pFolha.NuAnoReferencia AND
            PL.NuMesReferencia = pFolha.NuMesReferencia AND
            PL.CdLancamentoFinanceiro IN
            (SELECT CdLancamentoFinanceiro
               FROM EPagLancamentoFinanceiro LF
              WHERE LF.FlObservaLimretRoativoErario = PKGPAG_TIPO.cnS AND
                    LF.CdVinculo = pCdVinculo AND
                    LF.CdProcessoPagRetroativo IS NOT NULL)
         --AUDITORIA: nao excluir parcela de meses que ja foram empenhados
         AND NOT EXISTS
            (SELECT 1
               FROM epaghistoricorubricavinculo rv
              INNER JOIN epagfolhapagamento fp
                 ON rv.cdfolhapagamento = fp.cdfolhapagamento
              WHERE rv.cdvinculo = pCdVinculo
                AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS
                AND fp.flfolhafechada = PKGPAG_TIPO.cnS
                AND fp.nuanoreferencia = pl.nuanoreferencia
                AND fp.numesreferencia = pl.numesreferencia
                AND rv.cdlancamentofinanceiro = pl.cdlancamentofinanceiro);

     UPDATE EPagLancamentoFinanceiro LF
        SET DtFimDireito = NULL
      WHERE LF.CdVinculo = pCdVinculo
        AND LF.DtFimDireito = pFolha.DtFimMes
        AND LF.FlObservaLimRetroativoErario = PKGPAG_TIPO.cnS
        AND LF.CdProcessoPagRetroativo IS NOT NULL
        AND LF.CdLancamentoFinanceiro IN
            (select cdlancamentofinanceiro
               from (select fin.cdprocessopagretroativo CdProcessoPagRetroativo,
                            fin.vllancamentofinanceiro VlRestituir, --Valor restituir
                            sum(pag.vlparcela) vlPago,
                            fin.cdlancamentofinanceiro cdlancamentofinanceiro,
                            hrv.cdrubricaagrupamento
                       from epaghistoricorubricavinculo hrv -- CONTRA-CHEQUE
                      inner join epagfolhapagamento fp
                         on fp.cdfolhapagamento = hrv.cdfolhapagamento
                        and fp.flfolhafechada = 'N'
                      inner join epaglancamentofinanceiro fin
                         on hrv.cdlancamentofinanceiro = fin.cdlancamentofinanceiro
                        and hrv.cdvinculo = fin.cdvinculo
                       left join epagpagamentolancamento pag
                         on pag.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro
                      where hrv.cdvinculo = pCdVinculo
                        and (hrv.cdlancamentofinanceiro is not null and
                            hrv.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro)
                      group by fin.cdprocessopagretroativo,
                               fin.vllancamentofinanceiro,
                               hrv.cdrubricaagrupamento,
                               fin.cdlancamentofinanceiro) A
              where a.vlrestituir > a.vlpago);

     -- Abre os processos de Compensacao que tenham processos de
     -- retroativos finalizados na referencia do calculo

     UPDATE ERetCompensaRetroErario CR
        SET CR.CdSituacaoProcesso = 2
      WHERE CR.CdProcessoPagRetroativo IN
            (SELECT RT.CdProcessoPagRetroativo
               FROM ERetProcessoPagRetroativo RT
              WHERE RT.CdVinculo = pCdVinculo AND
                    RT.CdSituacaoProcesso = 3 AND
                    RT.NuAnoMesFinalizacao = vNuAnoMes);

     -- Abre os processos de retroativos que tenham
     -- sido finalizados na referencia do calculo

     UPDATE ERetProcessoPagRetroativo RT
        SET RT.CdSituacaoProcesso = 2
     WHERE  RT.CdVinculo = pCdVinculo AND
            RT.CdSituacaoProcesso = 3 AND
            RT.NuAnoMesFinalizacao = vNuAnoMes;
   END;

   PROCEDURE SetaRubDifDescIPREV(pcdAgrupamento IN INTEGER) IS

     vNuRubrica INTEGER;

   BEGIN

     BEGIN

       SELECT nuRubrica
        INTO vNuRubrica
        FROM ePagRubrica R
       WHERE R.CdRubrica = (SELECT CdRubrica
                              FROM ePagRubricaAgrupamento
                             WHERE CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupIPREVFundFinanc);

      vCdRubAgpIPREVFundFinDifDesc := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pcdAgrupamento,
                                                                   pCdTipoRubrica => 6,
                                                                   pNuRubrica => vNuRubrica);
     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         vCdRubAgpIPREVFundFinDifDesc := 0;

     END;

     BEGIN

       SELECT nuRubrica
        INTO vNuRubrica
        FROM ePagRubrica R
       WHERE R.CdRubrica = (SELECT CdRubrica
                              FROM ePagRubricaAgrupamento
                             WHERE CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.cdrubagrupdesccpsmretera);

       vCdRubAgpRessarcCPSM := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pcdAgrupamento,
                                                                   pCdTipoRubrica => 6,
                                                                   pNuRubrica => vNuRubrica);
     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         vCdRubAgpRessarcCPSM := 0;

     END;

     BEGIN

       SELECT nuRubrica
        INTO vNuRubrica
        FROM ePagRubrica R
       WHERE R.CdRubrica = (SELECT CdRubrica
                              FROM ePagRubricaAgrupamento
                             WHERE CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupIPREVFundPrev);

      vCdRubAgpIPREVFundPrevDifDesc := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pcdAgrupamento,
                                                                    pCdTipoRubrica => 6,
                                                                    pNuRubrica => vNuRubrica);


     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         vCdRubAgpIPREVFundFinDifDesc := 0;

     END;

     BEGIN

       SELECT nuRubrica
        INTO vNuRubrica
        FROM ePagRubrica R
       WHERE R.CdRubrica = (SELECT CdRubrica
                              FROM ePagRubricaAgrupamento
                             WHERE CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupIPREVFundLC662);

      vCdRubAgpIprevLC66215DifDesc := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pcdAgrupamento,
                                                                   pCdTipoRubrica => 6,
                                                                   pNuRubrica => vNuRubrica);


     EXCEPTION

       WHEN NO_DATA_FOUND THEN

         vCdRubAgpIprevLC66215DifDesc := 0;

     END;

     vCdRubrAgpDifAbonoPerm := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pcdAgrupamento,
                                                            pCdTipoRubrica => 2,
                                                            pNuRubrica     => 914);

     vCdRubrAgpDifAbonoPerm10 := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pcdAgrupamento,
                                                              pCdTipoRubrica => 10,
                                                              pNuRubrica     => 914);

     vCdRubrAgpDifAbonoPerm12 := PKGPAG_GERAL.FRetornaRubrica(pCdAgrupamento => pcdAgrupamento,
                                                              pCdTipoRubrica => 12,
                                                              pNuRubrica     => 914);

   END;

   PROCEDURE PAtualizaParcelaRetroativo(pFolha     IN  PKGPAG_TIPO.rFolha,
                                        pCdVinculo IN INTEGER) IS

   BEGIN

     FOR vRec IN (SELECT LF.CdLancamentoFinanceiro,
                         LF.VlLancamentoFinanceiro,
                         NVL(qtParcelasPagas,0) + 1 AS qtParcelasPagas,
                         NVL(vlPago,0) AS vlPago,
                         HRV.VlPagamento
                    FROM EPagLancamentoFinanceiro LF
                   INNER JOIN ERetProcessoPagRetroativo RT
                      ON RT.CdProcessoPagRetroativo = LF.CdProcessoPagRetroativo
                    LEFT JOIN (SELECT PL.CdLancamentoFinanceiro,
                                      COUNT(*) AS qtParcelasPagas,
                                      SUM(PL.VlParcela) AS vlPago
                                 FROM EPagPagamentoLancamento PL
                                WHERE ((PL.NuAnoReferencia = pFolha.NuAnoReferencia AND
                                       PL.NuMesReferencia < pFolha.NuMesReferencia) OR
                                       PL.NuAnoReferencia < pFolha.NuAnoReferencia)
                                GROUP BY PL.CdLancamentoFinanceiro) P
                                ON LF.CdLancamentoFinanceiro = P.CdLancamentoFinanceiro
                  INNER JOIN EPagHistoricoRubricaVinculo HRV
                     ON LF.CdLancamentoFinanceiro = HRV.CdLancamentoFinanceiro
                  WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
                        HRV.CdVinculo = pCdVinculo)
     LOOP

     pkgpag_lf.PExcluirPagamentoParcela(pCdLancamentoFinanceiro => vRec.CdLancamentoFinanceiro,
                                               pNuAnoReferencia => pFolha.NuAnoReferencia,
                                               pNuMesreferencia => pFolha.NuMesReferencia);

     PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => vRec.CdLancamentoFinanceiro,
                                         pNuAnoReferencia => pFolha.NuAnoReferencia,
                                         pNuMesreferencia => pFolha.NuMesReferencia,
                                         pNuParcela => vRec.QtParcelasPagas,
                                         pValorParcela => vRec.VlPagamento);

       IF vRec.VlPagamento + vRec.VlPago >= vRec.VlLancamentoFinanceiro THEN

         UPDATE EPagLancamentoFinanceiro LF
            SET LF.DtFimDireito = pFolha.DtFimMes
          WHERE LF.CdLancamentoFinanceiro = vRec.CdLancamentoFinanceiro;

       END IF;

     END LOOP;

   END;

   PROCEDURE PRetroativos(pFolha               IN PKGPAG_TIPO.rFolha,
                          pCdVinculo           IN INTEGER,
                          pFlCalculoDefinitivo IN CHAR DEFAULT 'N') IS

     vLancRetro                    rLancRetroativo;

     vProcRetro                    rProcessoRetroativo;

     vvlAbatimento                 NUMBER(13,2);

     vvlAbatimentoIPREV            NUMBER(13,2);

     vVlAbatimentoCPSM             number(13,2);

     vvlDescontoIPREV              NUMBER(13,2);

     vVlDescontoCPSM               NUMBER(13,2);

     vvlAbatimentoExercFindo       NUMBER(13,2);

     vvlAbatimentoExercFindo13     NUMBER(13,2);

     vVlExercFindoFaltaReceberNor  NUMBER(13,2);

     vvlPagamento                  NUMBER(13,2);

     vvlAbatimento13                NUMBER(13,2);

     vVlExercFindoFaltaReceber13    NUMBER(13,2);

     vvlPagamento13                 NUMBER(13,2);

     vVlPagamento13Total            NUMBER(13,2);

     vVlPagamentoNormalTotal        NUMBER(13,2);

     vVlAbonoPermRetr               NUMBER(13,2);

     vVlAbonoPermRetrExeFindo       NUMBER(13,2);

     vvlPagamentoBloqueio13         NUMBER(13,2);

     vTemExecFindo13SalNadaRecebido BOOLEAN;

     vTemExecFindo13SalaRecebendo   BOOLEAN;

     vFinalizaLanc                  BOOLEAN;

     vCdProcessoRestituicaoErario   INTEGER;

     vvlBaseErario                  pkgpag_tipo.rvalorpagamento;

     vCdBaseCalculo                 INTEGER;

     vVlRecebidoRetroativo          NUMBER(13,2);

     vVlPagoErario                  NUMBER(13,2);

     --vListaRubRecalcular            pkgpag_tipo.tlista;

     vVlLimitePagRetroativo         NUMBER(13,2);

     --vCntProcRet pls_integer;

 BEGIN

   IF PKGPAG_VAR.vgParamPagamento.VlLimitePagRetroativo IS NULL THEN

    RAISE eValLimRet;

   END IF;

   if pkgpag_var.bPossuiObito and nvl(pkgpag_var.vgVlRefRetroObito,0) > 0 then

      vVlLimitePagRetroativo := pkgpag_var.vgVlRefRetroObito;

   else

       vVlLimitePagRetroativo := PKGPAG_VAR.vgParamPagamento.VlLimitePagRetroativo;

   end if;

   IF pFolha.CdTipoFolha NOT IN (PKGPAG_TIPO.cnTpFolhaNormal,
                                 PKGPAG_TIPO.cnTpFolhaBolsista,
                                 PKGPAG_TIPO.cnTpFolhaResidente,
                                 PKGPAG_TIPO.cnTpFolhaPesquisador,
                                 PKGPAG_TIPO.cnTpFolhaConvenio,
                                 PKGPAG_TIPO.cnTpFolhaFunebre,
                                 PKGPAG_TIPO.cnTpFolhaServAfast,
                                 PKGPAG_TIPO.cnTpFolhaCtisp) THEN

     RETURN;

   END IF;

   IF pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal THEN

     PExcluiHistoricoRetro(pFolha,
                           pCdVinculo);
   END IF;

   PKGPAG_RT.vgProcessoRetroativo := FRetornaRetroativos( pFolha,
                                                          pCdVinculo,
                                                          pFolha.DtInicioMes,
                                                          pFolha.DtFimMes);

   IF PKGPAG_RT.vgProcessoRetroativo.COUNT = 0 THEN

     RETURN;

   END IF;

   -----------------------------------------------------------------------------------------
   ------  VARIAVEIS PARA CONSIDERACAO DO EXERC.FINDOS NORMAL
   -----------------------------------------------------------------------------------------

   vvlAbatimento                := vVlLimitePagRetroativo;

   vvlAbatimentoIPREV           := vVlLimitePagRetroativo*0.14;

   vVlAbatimentoCPSM            := vvlAbatimentoIPREV;

   vvlAbatimentoExercFindo      := vVlLimitePagRetroativo;

   vvlAbatimentoExercFindo13    := vVlLimitePagRetroativo;

   vvlDescontoIPREV             := 0;

   vVlDescontoCPSM              := 0;

   vVlExercFindoFaltaReceberNor := 0;

   -----------------------------------------------------------------------------------------
   ------  VARIAVEIS PARA CONSIDERACAO DO EXERC.FINDOS DE 13 SALARIO
   -----------------------------------------------------------------------------------------

   vvlAbatimento13                 := vVlLimitePagRetroativo;

   vVlExercFindoFaltaReceber13     := 0;

   vvlPagamentoBloqueio13          := 0;

   vTemExecFindo13SalNadaRecebido  := FALSE;

   vTemExecFindo13SalaRecebendo    := FALSE;

   FOR iProc IN PKGPAG_RT.vgProcessoRetroativo.FIRST .. PKGPAG_RT.vgProcessoRetroativo.LAST
   LOOP

     -- Verificar se existem parcelas pagas e nao registradas na tabela EPAGPAGAMENTOLANCAMENTO
     begin

     IF ((PKGPAG_RT.vgProcessoRetroativo(iProc).NuAnoInicioRestituicao = pFolha.NuAnoReferencia and
          PKGPAG_RT.vgProcessoRetroativo(iProc).NuMesInicioRestituicao < pFolha.NuMesReferencia) or
         (PKGPAG_RT.vgProcessoRetroativo(iProc).NuAnoInicioRestituicao < pFolha.NuAnoReferencia))
         and trunc(PKGPAG_RT.vgProcessoRetroativo(iProc).DtAtivacaoProcesso,'dd/mm/yyyy') < trunc(pFolha.DtInicioMes,'dd/mm/yyyy') then

       pajustaparcelanaocomputadaRET(PKGPAG_RT.vgProcessoRetroativo(iProc).cdprocessoPagRetroativo,
                                     PKGPAG_RT.vgProcessoRetroativo(iProc).cdlancamentofinanceiro,
                                     pCdVinculo);
       -- Atualizar total pago e numero de parcelas
       begin
          select sum(nvl(pag.vlparcela,0)), max(nvl(pag.nuparcela,0))
            into PKGPAG_RT.vgProcessoRetroativo(iProc).vlpago, PKGPAG_RT.vgProcessoRetroativo(iProc).qtparcelaspagas
            from epagpagamentolancamento pag
          where pag.cdlancamentofinanceiro = PKGPAG_RT.vgProcessoRetroativo(iProc).cdlancamentofinanceiro;

          exception
           when others then
             null;
       end;

     END IF;

     exception
       when others then
         null;
     end;

     -----------------------------------------------------------------------------------------
     ------  VARIAVEIS PARA CONSIDERACAO DO EXERC.FINDOS DE 13 SALARIO e NORMAL
     -----------------------------------------------------------------------------------------

     vVlAbonoPermRetr              := 0;

     vVlAbonoPermRetrExeFindo      := 0;

     vVlRecebidoRetroativo         := 0;

     vProcRetro                    := PKGPAG_RT.vgProcessoRetroativo(iProc);

     vCdProcessoRestituicaoErario := 0;

     vCdBaseCalculo := pkgpag_var.vgrubrica(PKGPAG_VAR.vgCdRubricaErario).cdbasecalculo;

     vVlBaseErario.vlIntegral := 0;

     --
     -- Para retroativos que possuem processos de compensacao associados
     --

     IF FPossuiCompensacaoErario(PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo) >0
        THEN

        vCdProcessoRestituicaoErario := FPossuiCompensacaoErario(PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo);

        vVlBaseErario :=
         PKGPAG_FB.FRetornaValorBaseCalculo(pfolha => pFolha,
                                        pcdvinculo => pCdVinculo,
                                        pcdtipohistorico => 2,
                                        pcdrelacaovinculo => 0,
                                        pcdbasecalculo => vcdbasecalculo,
                                        pcdchave => pcdvinculo);

         IF PKGPAG_RT.vgProcessoRetroativo(iProc).FlObservaLimite = 'S'
           THEN

             vVlPagoErario := 0;

             vVlPagoErario := fRetornaSaldoErario(vCdProcessoRestituicaoErario,'P');

             IF vVlPagoErario > 0
               THEN

               IF pFolha.CdTipoFolha <> 11
                 THEN

                   vVlBaseErario.vlIntegral := vVlBaseErario.vlIntegral *PKGPAG_VAR.vgParamPagamento.VlPercRestituicao /100;

                 ELSE

                   vVlBaseErario.vlIntegral := vVlBaseErario.vlIntegral*PKGPAG_VAR.vgParamPagamento.VlPercRestituicaoBolsista/100;

               END IF;

             ELSE

                vvlBaseErario.vlIntegral := 0;

             END IF;

          END IF;
          --
          -- Nº da solicitacao: 9703/2017
          -- E outras para manter o abatimento se a base do erario for ZERO
          --
          IF vVlBaseErario.vlIntegral > 0
            THEN

             vVlAbatimento := vVlBaseErario.vlIntegral;

          END IF;

     END IF;

     IF vProcRetro.LsLanc.COUNT > 0 THEN

       FOR iLanc in vProcRetro.LsLanc.FIRST .. vProcRetro.LsLanc.LAST
       LOOP
         --
         -- Variavel vFinalizaLanc nao estava sendo inicializada aqui causando encerramento indevido
         -- de retroativos com saldo quando uma das rubricas do retroativo era finalizado, finalizando
         -- as demais. Alterado em 01/07/2014
         -- Solicitacao de Sustentacao #43074 - REDMINE
         --
         vFinalizaLanc := FALSE;

         vvlPagamento13 := 0;

         vVlRecebidoRetroativo := 0;

         --
         -- Verificar se para o mesmo processo teve algum credito.
         --
         IF vVlBaseErario.vlIntegral > 0

           THEN

             BEGIN
                SELECT sum(VlPagamento)
                  INTO vVlRecebidoRetroativo
                  FROM EPAGHISTORICORUBRICAVINCULO ERV
                  INNER JOIN EPAGRUBRICAAGRUPAMENTO ERU ON ERU.CDRUBRICAAGRUPAMENTO = ERV.CDRUBRICAAGRUPAMENTO
                  INNER JOIN EPAGRUBRICA EPR ON EPR.CDRUBRICA = ERU.CDRUBRICA
                                            AND EPR.CDTIPORUBRICA IN (2,4,10,12)
                 WHERE ERV.Cdfolhapagamento = pFolha.CdFolhaPagamento
                   AND ERV.Cdvinculo = pCdVinculo
                   AND ERV.Cdprocessopagretroativo = PKGPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo
                   AND ERV.Cdrubricaagrupamento <> vProcRetro.LsLanc(iLanc).CdRubricaAgrupamento;

              vVlAbatimento := vVlAbatimento - vVlRecebidoRetroativo;

              IF vVlAbatimento < 0
                THEN

                  vVlAbatimento := 0;

              END IF;

              vVlAbatimento13 := vVlAbatimento;

             EXCEPTION
               WHEN OTHERS
                 THEN

                   vVlRecebidoRetroativo := 0;

             END;

         END IF;

         vLancRetro     := vProcRetro.LsLanc (iLanc);

         vvlPagamento   := (vLancRetro.VlLancamentoFinanceiro - vLancRetro.VlPago);

         IF vProcRetro.FlObservaLimite = PKGPAG_TIPO.cnN THEN

            vFinalizaLanc := TRUE;

         ELSE

           --------------------------------------------------------------------
           -- IPREV de Exercicios Findos - Normal e de 13 salario
           --------------------------------------------------------------------

           IF vLancRetro.CdRubricaAgrupamento IN  (vCdRubAgpIPREVFundFinDifDesc, vCdRubAgpIPREVFundPrevDifDesc, vCdRubAgpIprevLC66215DifDesc ) AND
              vvlAbatimentoIPREV > 0 THEN

             IF vvlPagamento > vvlAbatimentoIPREV  THEN

               vvlPagamento := vvlAbatimentoIPREV;

             ELSE

               vFinalizaLanc := TRUE;

             END IF;

             vvlAbatimentoIPREV := vvlAbatimentoIPREV - vvlPagamento;

             vvlDescontoIPREV   := vvlDescontoIPREV   + vvlPagamento;


           --------------------------------------------------------------------
           -- CPSM - Normal
           --------------------------------------------------------------------
           elsif vLancRetro.CdRubricaAgrupamento = vCdRubAgpRessarcCPSM and vVlAbatimentoCPSM > 0 then

             IF vvlPagamento > vvlAbatimentoCPSM  THEN

               vvlPagamento := vvlAbatimentoCPSM;

             ELSE

               vFinalizaLanc := TRUE;

             END IF;

             vvlAbatimentoCPSM := vvlAbatimentoCPSM - vvlPagamento;

             vvlDescontoCPSM   := vvlDescontoCPSM   + vvlPagamento;
           --------------------------------------------------------------------
           -- Bloqueio de Exercicios Findos - Normal
           --------------------------------------------------------------------

           ELSIF vLancRetro.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind then

            IF vVlPagamentoNormalTotal > 0
              then

             IF (vVlExercFindoFaltaReceberNor - vvlPagamento) <= vVlLimitePagRetroativo THEN

               IF vvlPagamento > (vvlAbatimentoExercFindo - vvlDescontoIPREV)  THEN

                 IF vVlExercFindoFaltaReceberNor > vvlPagamento THEN

                    vvlPagamento := vVlLimitePagRetroativo -
                                    (vVlExercFindoFaltaReceberNor - vvlPagamento + vvlDescontoIPREV + vvlPagamentoBloqueio13) ;

                    vvlAbatimentoExercFindo := 0;

                 ELSE

                   vvlPagamento := vVlPagamentoNormalTotal; --vvlAbatimentoExercFindo;

                   vvlAbatimentoExercFindo := 0;

                 END IF;

               ELSE

                 vvlAbatimentoExercFindo := vvlAbatimentoExercFindo - vvlDescontoIPREV
                                            - vvlPagamentoBloqueio13
                                            - vvlPagamento;

                 vvlDescontoIPREV := 0;

                 vFinalizaLanc := TRUE;

               END IF;

             ELSE

               vVlPagamento := 0;

             END IF;

             else

               vvlAbatimentoExercFindo := 0;

               vVlPagamento := 0;

             end if;

           --------------------------------------------------------------------
           -- Bloqueio de Exercicios Findos - 13 salario
           --------------------------------------------------------------------

           ELSIF vLancRetro.CdRubricaAgrupamento = PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqExercFind13Sal AND
                 vvlAbatimentoExercFindo13 > 0 then

            if vVlPagamento13Total > 0 then

             IF vvlPagamento > (vvlAbatimentoExercFindo - vvlDescontoIPREV)  THEN

                 vvlPagamento := (vvlAbatimentoExercFindo - vvlDescontoIPREV);

                 vvlAbatimentoExercFindo13 := 0;

             ELSE

                 vvlAbatimentoExercFindo13 := vvlAbatimentoExercFindo13 - vvlDescontoIPREV - vvlPagamento;

                 vvlDescontoIPREV := 0;

                 vFinalizaLanc := TRUE;

              END IF;

              IF vVlPagamento13Total <= vVlPagamento THEN

                vvlPagamento := vVlPagamento13Total;

              end if;

           else

              vvlAbatimentoExercFindo13 := 0;
              vVlPagamento := 0;

           end if;
           --------------------------------------------------------------------------------------
           -- 10 e 12 (e demais rubricas) - Normal e de 13 salario
           --------------------------------------------------------------------------------------

           ELSIF vLancRetro.CdRubricaAgrupamento NOT IN (NVL(vCdRubAgpIPREVFundFinDifDesc,0),
                                                         NVL(vCdRubAgpIprevLC66215DifDesc,0),
                                                            NVL(vCdRubAgpIPREVFundPrevDifDesc,0),
                                                            NVL(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,0),
                                                            NVL(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqExercFind13Sal,0)) THEN

             if vLancRetro.NuRubrica in (23,1914) then

              IF vVlAbatimento13 > 0 THEN -- 13salario

                vVlExercFindoFaltaReceber13 := vVlExercFindoFaltaReceber13 + vvlPagamento;

                if vLancRetro.VlPago = 0 THEN

                   vTemExecFindo13SalNadaRecebido := TRUE;

                end if;

                vTemExecFindo13SalaRecebendo := TRUE;

                vvlPagamento13 := vVlPagamento;

                if vVlPagamento13 > vvlAbatimento13 THEN

                    vvlPagamento13 := vvlAbatimento13;

                    vvlAbatimento13 := 0;

                else
                    vvlAbatimento13 := vvlAbatimento13 - vVlPagamento13;

                    vFinalizaLanc := TRUE;

                end if;

                vVlPagamento :=  vVlPagamento13;

                vVlPagamento13Total := nvl(vVlPagamento13Total,0) + vVlPagamento13;

              else

                 vVlPagamento := 0;

              end if;

              vvlAbatimento := vvlAbatimento - vvlPagamento;

             else -- Normal

               vVlExercFindoFaltaReceberNor := vVlExercFindoFaltaReceberNor + vvlPagamento;

               IF vvlAbatimento > 0 THEN

                 IF vvlPagamento > vvlAbatimento THEN

                     vvlPagamento := vvlAbatimento;

                     vvlAbatimento := 0;

                     vVlAbatimento13 := 0;

                 ELSE

                     vvlAbatimento := vvlAbatimento - vvlPagamento;

                     vVlAbatimento13 := vVlAbatimento;

                     vFinalizaLanc := TRUE;

                 END IF;

               ELSE

                    vVlPagamento := 0;

               END IF;

               vVlPagamentoNormalTotal := nvl(vVlPagamentoNormalTotal,0) + vvlPagamento;

           end if;

         else
           null;
         end if;

         end if;

         IF vvlPagamento > 0 THEN

           IF vFinalizaLanc THEN

             IF pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaNormal,
                                       PKGPAG_TIPO.cnTpFolhaBolsista,
                                       PKGPAG_TIPO.cnTpFolhaResidente,
                                       PKGPAG_TIPO.cnTpFolhaPesquisador,
                                       PKGPAG_TIPO.cnTpFolhaConvenio,                                       
                                       PKGPAG_TIPO.cnTpFolhaFunebre,
                                       PKGPAG_TIPO.cnTpFolhaServAfast,
                                       pkgpag_tipo.cnTpFolhaCtisp) AND
                pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                UPDATE EPagLancamentoFinanceiro LF
                   SET LF.DtFimDireito = pFolha.DtFimMes
                 WHERE LF.CdLancamentoFinanceiro = vLancRetro.CdLancamentoFinanceiro;

             END IF;

           END IF;

           --------------------------------------------------------------------------------
           -- Solicitacao: 5240/2013
           -- Processos com data de ativacao posterior a 24/10/2013 tem o abono calculado
           -- na inclusao do processo
           ---------------------------------------------------------------------------------

           IF vProcRetro.DtAtivacaoProcesso < TO_DATE('24/10/2013','DD/MM/YYYY') THEN

              -- Rubricas 05-0926, 05-0915
             IF vLancRetro.CdRubricaAgrupamento IN (PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundFinanc,
                                                    PKGPAG_VAR.vgParamPagamento.CdRubAgrupIprevFundPrev) THEN

               vVlAbonoPermRetr := vVlAbonoPermRetr + vvlPagamento;

             -- Rubricas 06-0926, 06-0915
             ELSIF vLancRetro.CdRubricaAgrupamento IN (vCdRubAgpIPREVFundFinDifDesc,
                                                       vCdRubAgpIprevLC66215DifDesc,
                                                       vCdRubAgpIPREVFundPrevDifDesc) THEN

               vVlAbonoPermRetrExeFindo := vVlAbonoPermRetrExeFindo + vvlPagamento;

             else
               null;
             END IF;

           END IF;

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento           => pFolha.CdFolhaPagamento,
                                                  pCdVinculo                 => pCdVinculo,
                                                  pCdExpressaoFormCalc       => NULL,
                                                  pCdRubricaAgrupamento      => vLancRetro.CdRubricaAgrupamento,
                                                  pNuSufixoRubrica           => vLancRetro.NuSufixoRubrica,
                                                  pCdProcessoPagRetroativo   => vProcRetro.CdProcessoPagRetroativo,
                                                  pDeProcessoRetroativo      => vProcRetro.DeProcessoRetroativo,
                                                  pVlPagamento               => vvlPagamento,
                                                  pVlIndice                  => vProcRetro.NuMeses,
                                                  pCdLancamentoFinanceiro    => vLancRetro.CdLancamentoFinanceiro,
                                                  pCdTipoOrigemRubrica       => CASE
                                                                                  WHEN PKGPAG_RT.vgDecJudRetro.FIRST IS NULL THEN
                                                                                    12 -- RET
                                                                                  WHEN PKGPAG_RT.vgDecJudRetro.EXISTS(vProcRetro.CdProcessoPagRetroativo) THEN
                                                                                    22 -- RJD
                                                                                  ELSE
                                                                                    12
                                                                                END,
                                                  pVlRestituir               => vProcRetro.VlRestituir,
                                                  pCdTipoIndice => 10 ); -- Meses

           --
           -- Para cada rubrica gerada no retroativo verificar se fazem parte de formula de alguma rubrica
           -- e reprocessar atraves da procedure pRecalcularRubricas
           -- 12288/2018 - O CODIGO 05-0405 NAO ESTA PROPORCIONALIZANDO SOBRE AS RUBRICAS DE VALORES ATRASADOS DO ABONO DE PERMANENCIA
           --
           pRecalcularRubricas (vLancRetro.CdRubricaAgrupamento);

           IF NVL(vvlPagamento,0) > 0 AND
              pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

             BEGIN

             PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => vLancRetro.CdLancamentoFinanceiro,
                                                 pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                 pNuMesreferencia => pFolha.NuMesReferencia,
                                                 pNuParcela => vLancRetro.qtParcelasPagas + 1,
                                                 pValorParcela => vvlPagamento);

             EXCEPTION

                WHEN OTHERS THEN

                  PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Erro ao gerar parcela de retroativo: Código do lançamento: ' || vLancRetro.CdLancamentoFinanceiro,
                                PKGPAG_VAR.vgCdVinculo);

             END;

           END IF;

         END IF;

       END LOOP;

     END IF;

     -- GERAR NO PAGAMENTO O 2-914

     IF vVlAbonoPermRetr > 0 THEN

        IF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                             pCdVinculo         => pCdVinculo,
                                             pCdRubrica         => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                   1,
                                                                   914)) > 0 THEN

          IF PKGPAG_GERAL.FGeraRubrica( PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                     2,
                                                                     914)) THEN

            PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                  pCdVinculo               => pCdVinculo,
                                                  pCdExpressaoFormCalc     => NULL,
                                                  pCdRubricaAgrupamento    => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                           2,
                                                                           914),
                                                  pNuSufixoRubrica         => vProcRetro.NuSeqRubrica,
                                                  pCdProcessoPagRetroativo => vProcRetro.CdProcessoPagRetroativo,
                                                  pDeProcessoRetroativo    => vProcRetro.DeProcessoRetroativo,
                                                  pVlPagamento             => vVlAbonoPermRetr,
                                                  pVlIndice                => NULL,
                                                  pCdTipoOrigemRubrica     => 1);

             IF NVL(vVlAbonoPermRetr,0) > 0 AND
              pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

               BEGIN

               PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => vLancRetro.CdLancamentoFinanceiro,
                                                   pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                   pNuMesreferencia => pFolha.NuMesReferencia,
                                                   pNuParcela => vLancRetro.qtParcelasPagas + 1,
                                                   pValorParcela => vvlPagamento);

               EXCEPTION

                  WHEN OTHERS THEN

                    PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'Erro ao gerar parcela de retroativo: Código do lançamento: ' || vLancRetro.CdLancamentoFinanceiro,
                                  PKGPAG_VAR.vgCdVinculo);

               END;

              END IF;

          END IF;

        END IF;

     END IF;

     -- GERAR NO PAGAMENTO O 10-914

     IF vVlAbonoPermRetrExeFindo > 0 THEN

       IF PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento  => pFolha.CdFolhaPagamento,
                                             pCdVinculo        => pCdVinculo,
                                             pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                  1,
                                                                  914)) > 0 THEN

         IF PKGPAG_GERAL.FGeraRubrica(PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                   10,
                                                                   914)) THEN

           PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                 pCdVinculo               => pCdVinculo,
                                                 pCdExpressaoFormCalc     => NULL,
                                                 pCdRubricaAgrupamento    => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                          10,
                                                                          914),
                                                 pNuSufixoRubrica         => vProcRetro.NuSeqRubrica,
                                                 pCdProcessoPagRetroativo => vProcRetro.CdProcessoPagRetroativo,
                                                 pDeProcessoRetroativo    => vProcRetro.DeProcessoRetroativo,
                                                 pVlPagamento             => vVlAbonoPermRetrExeFindo,
                                                 pVlIndice                => NULL,
                                                 pCdTipoOrigemRubrica     => 1);


           IF NVL(vVlAbonoPermRetrExeFindo,0) > 0 AND
              pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

               BEGIN

               PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => vLancRetro.CdLancamentoFinanceiro,
                                                   pNuAnoReferencia => pFolha.NuAnoReferencia,
                                                   pNuMesreferencia => pFolha.NuMesReferencia,
                                                   pNuParcela => vLancRetro.qtParcelasPagas + 1,
                                                   pValorParcela => vVlAbonoPermRetrExeFindo);

               EXCEPTION

                  WHEN OTHERS THEN

                    PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                                 PKGPAG_VAR.vCdHistParamCalc,
                                 PKGPAG_VAR.vCdPessoa,
                                 'Erro ao gerar parcela de retroativo: Código do lançamento: ' || vLancRetro.CdLancamentoFinanceiro,
                                  PKGPAG_VAR.vgCdVinculo);

               END;

              END IF;

         END IF;

       END IF;

     END IF;

   END LOOP;

   EXCEPTION

   WHEN eValLimRet THEN

       PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Valor limite para pagamento de retroativos não informado. Retroativo não calculado.',
                               PKGPAG_VAR.vgCdVinculo);

    WHEN OTHERS THEN

       PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Erro ao calcular retroativos.',
                               PKGPAG_VAR.vgCdVinculo);

 END;

END PKGPAG_RT;
/
