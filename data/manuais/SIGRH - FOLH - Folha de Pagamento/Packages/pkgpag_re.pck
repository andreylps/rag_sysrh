CREATE OR REPLACE PACKAGE PKGPAG_RE IS

PROCEDURE PRestituicaoErario(pFolha               IN PKGPAG_TIPO.rFolha,
                             pCdVinculo           IN INTEGER,
                             pFlCalculoDefinitivo IN CHAR DEFAULT 'N',
                             pflobservalimite     IN CHAR,
                             pFlObsTributacao     IN CHAR DEFAULT 'N');

FUNCTION FRetornaValorMargem(pCdFolhaPagamento IN INTEGER,
                             pCdTipoFolha      IN INTEGER,
                             pCdVinculo        IN INTEGER,
                             pCdRubrica        IN INTEGER,
                             pvllimitepercentualmensal IN INTEGER DEFAULT NULL,
                             pFlObservaLimite  IN CHAR)
     RETURN NUMBER;

END PKGPAG_RE;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_RE IS

  vPossuiObito char default 'N';
  -- Seleciona os lancamentos financeiros referentes ao erario
  -- Caso seja recalculo ou calculo retroativo, despreza os pagamentos
  -- realizados no mes ou posteriores

  CURSOR cLancamentoErario(pCdVinculo IN INTEGER,
                           pFolha     IN PKGPAG_TIPO.rFolha,
                           pflobservalimite IN CHAR) IS
         SELECT lf.cdrubricaagrupamento,
                lf.cdlancamentofinanceiro,
                lf.nusufixorubrica,
                lf.vllancamentofinanceiro,
                lf.flpagaafastdefinitivo,
                CASE
                  WHEN lf.dtiniciodireito > pFolha.Dtiniciomes THEN
                   lf.dtiniciodireito
                  ELSE
                   pFolha.Dtiniciomes
                END dtinicio,
                CASE
                  WHEN (lf.dtfimdireito > pFolha.Dtfimmes OR lf.dtfimdireito IS NULL) THEN
                   pFolha.Dtfimmes
                  ELSE
                   lf.dtfimdireito
                END dtfim,
                lf.vlindice,
                NVL(p.qtparcelaspagas, 0) AS qtparcelaspagas,
                NVL(p.vlpago, 0) AS vlpago,
                NVL(rv.vlpago, 0) AS vlpago_nao_computado,
                NVL(rv.qtparcelaspagas, 0) AS qtparcelas_nao_computada,
                lf.cdprocessorestituicaoerario,
                lf.flobservalimretroativoerario,
                r.cdtiporubrica,
                r.nurubrica,
                lf.cdcompensacaoretroerario,
                nuanoiniciorestituicao,
                numesiniciorestituicao,
                TRUNC(dtativacaoprocesso) as DtAtivacaoProcesso,
                re.flobservalimite,
                re.vllimitepercentualmensal
       FROM epaglancamentofinanceiro lf
          INNER JOIN (SELECT cdprocessorestituicaoerario,
                             nuanoiniciorestituicao,
                             numesiniciorestituicao,
                             dtativacaoprocesso,
                             flobservalimite,
                             vllimitepercentualmensal
                        FROM (SELECT rep.cdprocessorestituicaoerario,
                                     rep.nuanoiniciorestituicao,
                                     rep.numesiniciorestituicao,
                                     rep.dtativacaoprocesso,
                                     rep.flobservalimite,
                                     rep.vllimitepercentualmensal
                                FROM erepprocessorestituicaoerario rep
                               WHERE
                                 ((pFolha.CdTipoCalculo=PKGPAG_TIPO.cnTpCalculoRecalculoMes  AND  rep.cdprocessorestituicaoerario in
                                 (SELECT  distinct lfn.cdprocessorestituicaoerario FROM
                                 (SELECT  cdlancamentofinanceiro FROM EPAGHISTORICORUBRICAVINCULO WHERE cdvinculo=pcdvinculo AND cdfolhapagamento in(
                                  SELECT  fpg.cdfolhapagamento FROM
                                  epagfolhapagamento fpg
                                  INNER JOIN epagtipofolhapagamento tfp ON fpg.cdtipofolhapagamento=tfp.cdtipofolhapagamento
                                  WHERE
                                  fpg.cdorgao=pFolha.CdOrgao
                                  AND fpg.nuanoreferencia=pFolha.NuAnoReferencia
                                  AND fpg.numesreferencia=pFolha.NuMesReferencia
                                  AND tfp.cdtipofolha=PKGPAG_TIPO.cnTpFolhaNormal
                                  AND fpg.cdtipocalculo=PKGPAG_TIPO.cnTpCalculoNormal
                                  AND fpg.flcalculodefinitivo='S'
                                 )) hrv
                                 INNER JOIN epaglancamentofinanceiro lfn ON hrv.cdlancamentofinanceiro=lfn.cdlancamentofinanceiro
                                 WHERE lfn.cdprocessorestituicaoerario is NOT null))
                                 or rep.cdsituacaoprocesso = 2)
                                 AND rep.flanulado = PKGPAG_TIPO.cnn
                                 AND rep.cdvinculo = pcdvinculo
                               ORDER BY rep.dtativacaoprocesso)
                       --WHERE rownum < 2
                       ) re
             ON re.cdprocessorestituicaoerario = lf.cdprocessorestituicaoerario
           LEFT JOIN (SELECT pl.cdlancamentofinanceiro,
                             COUNT(*) AS qtparcelaspagas,
                             SUM(pl.vlparcela) AS vlpago
                        FROM epagpagamentolancamento pl
                       WHERE ((pl.nuanoreferencia =
                             PKGPAG_VAR.vgfolha.nuanoreferencia AND
                             pl.numesreferencia <
                             PKGPAG_VAR.vgfolha.numesreferencia) OR
                             pl.nuanoreferencia <
                             PKGPAG_VAR.vgfolha.nuanoreferencia)
                       GROUP BY pl.cdlancamentofinanceiro) p
             ON lf.cdlancamentofinanceiro = p.cdlancamentofinanceiro
           LEFT JOIN (SELECT hrv.cdlancamentofinanceiro,
                             hrv.cdvinculo,
                             COUNT(hrv.cdhistoricorubricavinculo) AS qtparcelaspagas,
                             SUM(hrv.vlpagamento) AS vlpago
                        FROM epaghistoricorubricavinculo hrv
                       INNER JOIN epagfolhapagamento fp
                          ON fp.cdfolhapagamento = hrv.cdfolhapagamento
                         AND fp.flcalculodefinitivo = 'S'
                       GROUP BY hrv.cdlancamentofinanceiro, hrv.cdvinculo) rv
             ON rv.cdlancamentofinanceiro = lf.cdlancamentofinanceiro
            AND rv.cdvinculo = lf.cdvinculo
          INNER JOIN epagrubricaagrupamento ra
             ON lf.cdrubricaagrupamento = ra.cdrubricaagrupamento
          INNER JOIN epagrubrica r
             ON r.cdrubrica = ra.cdrubrica
          WHERE lf.cdvinculo = pcdvinculo
            AND lf.flanulado = PKGPAG_TIPO.cnn
            AND lf.vllancamentofinanceiro > 0
            AND (lf.dtiniciodireito <= pFolha.Dtfimmes
            AND (lf.dtfimdireito >= pFolha.Dtiniciomes OR lf.dtfimdireito IS NULL))
            AND re.flobservalimite = Pflobservalimite
            AND ((PKGPAG_VAR.vgfolha.cdtipocalculo <>
                PKGPAG_TIPO.cntpcalculorecalccompl AND
                NVL(lf.cdtipofolhapagamento, 0) IN
                (0, PKGPAG_VAR.vgfolha.cdtipofolhapagamento) AND
                NVL(lf.cdtipocalculo, 0) IN
                (0, PKGPAG_VAR.vgfolha.cdtipocalculo) AND
                NVL(lf.nusequencialfolha, 0) IN
                (0, PKGPAG_VAR.vgfolha.nusequencialfolha)) OR
                (PKGPAG_VAR.vgfolha.cdtipocalculo =
                PKGPAG_TIPO.cntpcalculorecalccompl AND
                lf.cdtipofolhapagamento =
                PKGPAG_VAR.vgfolha.cdtipofolhapagamento AND
                lf.cdtipocalculo = PKGPAG_VAR.vgfolha.cdtipocalculo AND
                lf.nusequencialfolha = PKGPAG_VAR.vgfolha.nusequencialfolha))
            AND lf.cdrubricaagrupamento IN
                (SELECT hra.cdrubricaagrupamento
                    FROM epaghistrubricaagrupamento hra
                   WHERE hra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                     AND hra.flsuspensaretroativoerario = PKGPAG_TIPO.cnn
                     AND ((hra.nuanoiniciovigencia < pfolha.nuanoreferencia OR
                         (hra.nuanoiniciovigencia = pfolha.nuanoreferencia AND
                         hra.numesiniciovigencia <= pfolha.numesreferencia)) AND
                         (hra.nuanofimvigencia > pfolha.nuanoreferencia OR
                         (hra.nuanofimvigencia = pfolha.nuanoreferencia AND
                         hra.numesfimvigencia >= pfolha.numesreferencia) OR
                         hra.nuanofimvigencia IS NULL)))


         UNION ALL
         SELECT lf.cdrubricaagrupamento,
                lf.cdlancamentofinanceiro,
                lf.nusufixorubrica,
                lf.vllancamentofinanceiro,
                lf.flpagaafastdefinitivo,
                CASE
                  WHEN lf.dtiniciodireito > pFolha.Dtiniciomes THEN
                   lf.dtiniciodireito
                  ELSE
                   pFolha.Dtiniciomes
                END dtinicio,
                CASE
                  WHEN (lf.dtfimdireito > pFolha.Dtfimmes OR lf.dtfimdireito IS NULL) THEN
                   pFolha.Dtfimmes
                  ELSE
                   lf.dtfimdireito
                END dtfim,
                lf.vlindice,
                NVL(p.qtparcelaspagas, 0) AS qtparcelaspagas,
                NVL(p.vlpago, 0) AS vlpago,
                NVL(rv.vlpago, 0) AS vlpago_nao_computado,
                NVL(rv.qtparcelaspagas, 0) AS qtparcelas_nao_computada,
                lf.cdprocessorestituicaoerario,
                lf.flobservalimretroativoerario,
                r.cdtiporubrica,
                r.nurubrica,
                lf.cdcompensacaoretroerario,
                TO_NUMBER(TO_CHAR(lf.dtiniciodireito,'yyyy')) as nuanoiniciorestituicao,
                TO_NUMBER(TO_CHAR(lf.dtiniciodireito,'mm')) as numesiniciorestituicao,
                lf.dtinclusao as dtativacaoprocesso,
                'S' flobservalimite,
                null as limitepercentualmensal
           FROM epaglancamentofinanceiro lf
           LEFT JOIN (SELECT pl.cdlancamentofinanceiro,
                             COUNT(*) AS qtparcelaspagas,
                             SUM(pl.vlparcela) AS vlpago
                        FROM epagpagamentolancamento pl
                       WHERE ((pl.nuanoreferencia =
                             PKGPAG_VAR.vgfolha.nuanoreferencia AND
                             pl.numesreferencia <
                             PKGPAG_VAR.vgfolha.numesreferencia) OR
                             pl.nuanoreferencia <
                             PKGPAG_VAR.vgfolha.nuanoreferencia)
                       GROUP BY pl.cdlancamentofinanceiro) p
             ON lf.cdlancamentofinanceiro = p.cdlancamentofinanceiro
           LEFT JOIN (SELECT hrv.cdlancamentofinanceiro,
                             hrv.cdvinculo,
                             COUNT(hrv.cdhistoricorubricavinculo) AS qtparcelaspagas,
                             SUM(hrv.vlpagamento) AS vlpago
                        FROM epaghistoricorubricavinculo hrv
                       INNER JOIN epagfolhapagamento fp
                          ON fp.cdfolhapagamento = hrv.cdfolhapagamento
                         AND fp.flcalculodefinitivo = 'S'
                       GROUP BY hrv.cdlancamentofinanceiro, hrv.cdvinculo) rv
             ON rv.cdlancamentofinanceiro = lf.cdlancamentofinanceiro
            AND rv.cdvinculo = lf.cdvinculo
          INNER JOIN epagrubricaagrupamento ra
             ON lf.cdrubricaagrupamento = ra.cdrubricaagrupamento
          INNER JOIN epagrubrica r
             ON r.cdrubrica = ra.cdrubrica
          WHERE lf.cdvinculo = pcdvinculo
            AND lf.flanulado = PKGPAG_TIPO.cnn
            AND lf.vllancamentofinanceiro > 0
            AND (lf.dtiniciodireito <= pFolha.Dtfimmes
            AND (lf.dtfimdireito >= pFolha.Dtiniciomes OR lf.dtfimdireito IS NULL))
            AND lf.flacertoauto13sal = CASE WHEN PKGPAG_VAR.vgfolha.cdorgao = 33 AND vPossuiObito = PKGPAG_TIPO.cns
                                            THEN lf.flacertoauto13sal
                                            ELSE PKGPAG_TIPO.cns  END
            AND ((PKGPAG_VAR.vgfolha.cdtipocalculo <>
                PKGPAG_TIPO.cntpcalculorecalccompl AND
                NVL(lf.cdtipofolhapagamento, 0) IN
                (0, PKGPAG_VAR.vgfolha.cdtipofolhapagamento) AND
                NVL(lf.cdtipocalculo, 0) IN
                (0, PKGPAG_VAR.vgfolha.cdtipocalculo) AND
                NVL(lf.nusequencialfolha, 0) IN
                (0, PKGPAG_VAR.vgfolha.nusequencialfolha)) OR
                (PKGPAG_VAR.vgfolha.cdtipocalculo =
                PKGPAG_TIPO.cntpcalculorecalccompl AND
                lf.cdtipofolhapagamento =
                PKGPAG_VAR.vgfolha.cdtipofolhapagamento AND
                lf.cdtipocalculo = PKGPAG_VAR.vgfolha.cdtipocalculo AND
                lf.nusequencialfolha = PKGPAG_VAR.vgfolha.nusequencialfolha))
            AND lf.cdrubricaagrupamento IN
                (SELECT hra.cdrubricaagrupamento
                    FROM epaghistrubricaagrupamento hra
                   WHERE hra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                     AND hra.flsuspensaretroativoerario = PKGPAG_TIPO.cnn
                     AND ((hra.nuanoiniciovigencia < pfolha.nuanoreferencia OR
                         (hra.nuanoiniciovigencia = pfolha.nuanoreferencia AND
                         hra.numesiniciovigencia <= pfolha.numesreferencia)) AND
                         (hra.nuanofimvigencia > pfolha.nuanoreferencia OR
                         (hra.nuanofimvigencia = pfolha.nuanoreferencia AND
                         hra.numesfimvigencia >= pfolha.numesreferencia) OR
                         hra.nuanofimvigencia IS NULL)))

          ORDER BY flobservalimretroativoerario,
                   cdtiporubrica DESC,
                   nurubrica,
                   nusufixorubrica;

  CURSOR cLancamentoErarioObservaLimite(pCdVinculo IN INTEGER,
                           pFolha     IN PKGPAG_TIPO.rFolha,
                           pflobservalimite IN CHAR) IS
         SELECT lf.cdrubricaagrupamento,
                lf.cdlancamentofinanceiro,
                lf.nusufixorubrica,
                lf.vllancamentofinanceiro,
                lf.flpagaafastdefinitivo,
                CASE
                  WHEN lf.dtiniciodireito > pFolha.Dtiniciomes THEN
                   lf.dtiniciodireito
                  ELSE
                   pFolha.Dtiniciomes
                END dtinicio,
                CASE
                  WHEN (lf.dtfimdireito > pFolha.Dtfimmes OR lf.dtfimdireito IS NULL) THEN
                   pFolha.Dtfimmes
                  ELSE
                   lf.dtfimdireito
                END dtfim,
                lf.vlindice,
                NVL(p.qtparcelaspagas, 0) AS qtparcelaspagas,
                NVL(p.vlpago, 0) AS vlpago,
                NVL(rv.vlpago, 0) AS vlpago_nao_computado,
                NVL(rv.qtparcelaspagas, 0) AS qtparcelas_nao_computada,
                lf.cdprocessorestituicaoerario,
                lf.flobservalimretroativoerario,
                r.cdtiporubrica,
                r.nurubrica,
                lf.cdcompensacaoretroerario,
                nuanoiniciorestituicao,
                numesiniciorestituicao,
                TRUNC(dtativacaoprocesso) as DtAtivacaoProcesso,
                re.flobservalimite,
                re.vllimitepercentualmensal
           FROM epaglancamentofinanceiro lf
          INNER JOIN (SELECT cdprocessorestituicaoerario,
                             nuanoiniciorestituicao,
                             numesiniciorestituicao,
                             dtativacaoprocesso,
                             flobservalimite,
                             vllimitepercentualmensal
                        FROM (SELECT rep.cdprocessorestituicaoerario,
                                     rep.nuanoiniciorestituicao,
                                     rep.numesiniciorestituicao,
                                     rep.dtativacaoprocesso,
                                     rep.flobservalimite,
                                     rep.vllimitepercentualmensal
                                FROM erepprocessorestituicaoerario rep
                               WHERE
                                 ((pFolha.CdTipoCalculo=PKGPAG_TIPO.cnTpCalculoRecalculoMes  AND  rep.cdprocessorestituicaoerario in
                                 (SELECT  distinct lfn.cdprocessorestituicaoerario FROM
                                 (SELECT  cdlancamentofinanceiro FROM EPAGHISTORICORUBRICAVINCULO WHERE cdvinculo=pcdvinculo AND cdfolhapagamento in(
                                  SELECT  fpg.cdfolhapagamento FROM
                                  epagfolhapagamento fpg
                                  INNER JOIN epagtipofolhapagamento tfp ON fpg.cdtipofolhapagamento=tfp.cdtipofolhapagamento
                                  WHERE
                                  fpg.cdorgao=pFolha.CdOrgao
                                  AND fpg.nuanoreferencia=pFolha.NuAnoReferencia
                                  AND fpg.numesreferencia=pFolha.NuMesReferencia
                                  AND tfp.cdtipofolha=PKGPAG_TIPO.cnTpFolhaNormal
                                  AND fpg.cdtipocalculo=PKGPAG_TIPO.cnTpCalculoNormal
                                  AND fpg.flcalculodefinitivo='S'
                                 )) hrv
                                 INNER JOIN epaglancamentofinanceiro lfn ON hrv.cdlancamentofinanceiro=lfn.cdlancamentofinanceiro
                                 WHERE lfn.cdprocessorestituicaoerario is NOT null))
                                 or rep.cdsituacaoprocesso = 2)
                                 AND rep.flanulado = PKGPAG_TIPO.cnn
                                 AND rep.cdvinculo = pcdvinculo
                               ORDER BY rep.dtativacaoprocesso)
                       --WHERE rownum < 2
                       ) re
             ON re.cdprocessorestituicaoerario = lf.cdprocessorestituicaoerario
           LEFT JOIN (SELECT pl.cdlancamentofinanceiro,
                             COUNT(*) AS qtparcelaspagas,
                             SUM(pl.vlparcela) AS vlpago
                        FROM epagpagamentolancamento pl
                       WHERE ((pl.nuanoreferencia = PKGPAG_VAR.vgfolha.nuanoreferencia AND
                             pl.numesreferencia < PKGPAG_VAR.vgfolha.numesreferencia) OR
                             pl.nuanoreferencia < PKGPAG_VAR.vgfolha.nuanoreferencia)
                       GROUP BY pl.cdlancamentofinanceiro) p
             ON lf.cdlancamentofinanceiro = p.cdlancamentofinanceiro
           LEFT JOIN (SELECT hrv.cdlancamentofinanceiro,
                             hrv.cdvinculo,
                             COUNT(hrv.cdhistoricorubricavinculo) AS qtparcelaspagas,
                             SUM(hrv.vlpagamento) AS vlpago
                        FROM epaghistoricorubricavinculo hrv
                       INNER JOIN epagfolhapagamento fp
                          ON fp.cdfolhapagamento = hrv.cdfolhapagamento
                         AND fp.flcalculodefinitivo = 'S'
                       GROUP BY hrv.cdlancamentofinanceiro, hrv.cdvinculo) rv
             ON rv.cdlancamentofinanceiro = lf.cdlancamentofinanceiro
            AND rv.cdvinculo = lf.cdvinculo
          INNER JOIN epagrubricaagrupamento ra
             ON lf.cdrubricaagrupamento = ra.cdrubricaagrupamento
          INNER JOIN epagrubrica r
             ON r.cdrubrica = ra.cdrubrica
          WHERE lf.cdvinculo = pcdvinculo
            AND lf.flanulado = PKGPAG_TIPO.cnn
            AND lf.vllancamentofinanceiro > 0
            AND (lf.dtiniciodireito <= pFolha.Dtfimmes
            AND (lf.dtfimdireito >= pFolha.Dtiniciomes OR lf.dtfimdireito IS NULL))
            AND re.flobservalimite = Pflobservalimite
            AND ((PKGPAG_VAR.vgfolha.cdtipocalculo <>
                PKGPAG_TIPO.cntpcalculorecalccompl AND
                NVL(lf.cdtipofolhapagamento, 0) IN
                (0, PKGPAG_VAR.vgfolha.cdtipofolhapagamento) AND
                NVL(lf.cdtipocalculo, 0) IN
                (0, PKGPAG_VAR.vgfolha.cdtipocalculo) AND
                NVL(lf.nusequencialfolha, 0) IN
                (0, PKGPAG_VAR.vgfolha.nusequencialfolha)) OR
                (PKGPAG_VAR.vgfolha.cdtipocalculo =
                PKGPAG_TIPO.cntpcalculorecalccompl AND
                lf.cdtipofolhapagamento =
                PKGPAG_VAR.vgfolha.cdtipofolhapagamento AND
                lf.cdtipocalculo = PKGPAG_VAR.vgfolha.cdtipocalculo AND
                lf.nusequencialfolha = PKGPAG_VAR.vgfolha.nusequencialfolha))
            AND lf.cdrubricaagrupamento IN
                (SELECT hra.cdrubricaagrupamento
                    FROM epaghistrubricaagrupamento hra
                   WHERE hra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                     AND hra.flsuspensaretroativoerario = PKGPAG_TIPO.cnn
                     AND ((hra.nuanoiniciovigencia < pfolha.nuanoreferencia OR
                         (hra.nuanoiniciovigencia = pfolha.nuanoreferencia AND
                         hra.numesiniciovigencia <= pfolha.numesreferencia)) AND
                         (hra.nuanofimvigencia > pfolha.nuanoreferencia OR
                         (hra.nuanofimvigencia = pfolha.nuanoreferencia AND
                         hra.numesfimvigencia >= pfolha.numesreferencia) OR
                         hra.nuanofimvigencia IS NULL)))

          ORDER BY flobservalimretroativoerario,
                   cdtiporubrica,
                   nurubrica,
                   nusufixorubrica;

   PROCEDURE PExcluiHistoricoErario(pFolha     IN PKGPAG_TIPO.rFolha,
                                    pCdVinculo IN INTEGER,
                                    pFlObservaLimite in char default 'S') IS

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
              WHERE LF.FlObservaLimRetroativoErario = pFlObservaLimite AND
                    LF.CdVinculo = pCdVinculo AND
                    (LF.CdProcessoRestituicaoErario IS NOT NULL OR LF.FlAcertoAuto13Sal = 'S')
                --AUDITORIA: nao excluir parcela de meses que ja foram empenhados
                AND NOT EXISTS
                  (SELECT 1
                     FROM epaghistoricorubricavinculo rv
                    INNER JOIN epagfolhapagamento fp
                       ON rv.cdfolhapagamento = fp.cdfolhapagamento
                    WHERE rv.cdvinculo = pCdVinculo
                      AND fp.flcalculodefinitivo = PKGPAG_TIPO.cnS
                      AND fp.flfolhafechada = PKGPAG_TIPO.cnS
                      AND fp.nuanoreferencia = PL.nuanoreferencia
                      AND fp.numesreferencia = PL.numesreferencia
                      AND rv.cdlancamentofinanceiro = LF.cdlancamentofinanceiro));

     UPDATE EPagLancamentoFinanceiro LF
        SET DtFimDireito = NULL
      WHERE LF.CdVinculo = pCdVinculo AND
            LF.DtFimDireito = pFolha.DtFimMes AND
            LF.FlObservaLimretroativoerario = pFlObservaLimite AND
           (LF.CdProcessoRestituicaoErario IS NOT NULL OR LF.FlAcertoAuto13Sal = 'S') AND
            LF.CdLancamentoFinanceiro IN
            (SELECT  cdlancamentofinanceiro
               FROM (SELECT  fin.cdprocessopagretroativo CdProcessoPagRetroativo,
                            fin.vllancamentofinanceiro VlRestituir, --Valor restituir
                            sum(pag.vlparcela) vlPago,
                            fin.cdlancamentofinanceiro cdlancamentofinanceiro,
                            hrv.cdrubricaagrupamento
                       FROM epaghistoricorubricavinculo hrv -- CONTRA-CHEQUE
                      INNER JOIN epagfolhapagamento fp
                         ON fp.cdfolhapagamento = hrv.cdfolhapagamento
                        AND fp.flfolhafechada = 'N'
                      INNER JOIN epaglancamentofinanceiro fin
                         ON hrv.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro
                       LEFT JOIN epagpagamentolancamento pag
                         ON pag.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro
                      WHERE hrv.cdvinculo = pCdVinculo
                        AND (hrv.cdlancamentofinanceiro is NOT null AND
                            hrv.cdlancamentofinanceiro =
                            fin.cdlancamentofinanceiro)
                      group by fin.cdprocessopagretroativo,
                               fin.vllancamentofinanceiro,
                               hrv.cdrubricaagrupamento,
                               fin.cdlancamentofinanceiro) A
              WHERE a.vlrestituir > a.vlpago);

     -- Abre os processos de Compensacao que tenham processos de
     -- retroativos finalizados na referencia do calculo

     UPDATE ERetCompensaRetroErario CR
        SET CR.CdSituacaoProcesso = 2
      WHERE CR.CdProcessoPagRetroativo IN
            (SELECT RE.CdProcessoRestituicaoErario
               FROM ERepProcessoRestituicaoErario RE
              WHERE RE.CdVinculo = pCdVinculo AND
                    RE.CdSituacaoProcesso = 3 AND
                    RE.NuAnoMesFinalizacao = vNuAnoMes);

      UPDATE ERepProcessoRestituicaoErario RE
         SET RE.CdSituacaoProcesso = 2
       WHERE RE.CdVinculo = pCdVinculo AND
             RE.CdSituacaoProcesso = 3 AND
             RE.NuAnoMesFinalizacao = vNuAnoMes;

   END;

   --
   -- Incluir automaticamente processo de restituicao ao erario com base nos afastamentos retroativos apurados
   -- lancados apos a ultima folha calculada
   --
   PROCEDURE PIncluiProcessoErario(pFolha     IN PKGPAG_TIPO.rFolha,
                                   pCdVinculo IN INTEGER) IS

     vCdProcesso             INTEGER;
     vCdCorrecao             INTEGER;
     vExiste                 CHAR(1) := 'N';
     vCdRubrica              INTEGER;
     vVlPagamento            NUMBER(13,2);
     vCdLancamento           INTEGER;
     vCdFolha                INTEGER;
     vAnoMes                 CHAR(6);
     vAnoMesFim              char(6);
     vNuDiasAfast            INTEGER;
     vCdRubAuxAlim           INTEGER;
     vNuDiasAfastAuxAlim     INTEGER := 0;
     vNuDiasAuxAlimMes       INTEGER := 0;
     vListaRubBaseIprev      PKGPAG_TIPO.tLista;
     vVlComIncidencia        NUMBER(13,2) :=0;
     vVlSemIncidencia        NUMBER(13,2) :=0;
     vVlTotalComIncidencia   NUMBER(13,2) :=0;
     vCdRubFerias            NUMBER(13,2);
     vCdRubJeton             INTEGER;
     vCdRub1035              INTEGER;
     vCdRub1078              INTEGER;
     vCdRub1003              INTEGER;
     TYPE tDiasAfast is VARRAY(12) of NUMBER;
     vNuDiasAfastMes         tDiasAfast;
     vRecebeu                INTEGER;
     vVlDesconto             number(13,2);
     vCdSituacaoProcesso     INTEGER;

   BEGIN

     SELECT EPV.Cdvalorreferencia
       INTO vCdCorrecao
       FROM EPAGValorReferencia EPV
      WHERE flcorrecaomonetaria='S'
        AND cdagrupamento = pFolha.CdAgrupamento
        AND ROWNUM < 2
      ORDER BY 1 DESC;

     --
     --  Lista das rubricas que fazem parte da base de calculo do IPREV
     --
     IF PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = 2 THEN

       FOR RBASE IN (SELECT DISTINCT rubex.cdrubricaagrupamento
                 --  bulk collect INTO vListaRubBaseIprev
                       FROM epagrubricaagrupamento rubm
                      INNER JOIN epagbasecalculo bc
                         ON bc.cdbasecalculo = rubm.cdbasecalculo
                      INNER JOIN epagbasecalculoversao bv
                         ON BV.CdBaseCalculo = BC.CdBaseCalculo AND
                            BV.NuVersao = 1
                      INNER JOIN epaghistbasecalculo hb
                         ON HB.CdVersaoBaseCalculo = BV.CdVersaoBaseCalculo AND
                            HB.NuAnoFimVigencia IS NULL
                      INNER JOIN epagbasecalculobloco bl
                         ON bl.cdhistbasecalculo = hb.cdhistbasecalculo
                      INNER JOIN epagbasecalculoblocoexpressao ex
                         ON ex.cdbasecalculobloco = bl.cdbasecalculobloco
                      INNER JOIN epagbasecalcblocoexprrubagrup rubex
                         ON RUBEX.cdbasecalculoblocoexpressao = EX.cdbasecalculoblocoexpressao
                      WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC)

       LOOP

          vListaRubBaseIprev(RBASE.Cdrubricaagrupamento) := RBASE.Cdrubricaagrupamento;

       END LOOP;

     END IF;

     --
     -- Rubricas que sao excluidas da geracao automatica do erario
     --
     -- Auxilio alimentacao
     vCdRubAuxAlim := PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,157);

     -- Pagamento de ferias
     vCdRubFerias :=  NVL(PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,56),0);

     -- SIG-2964
     -- Chamado 14318/2019 - Desconto automatico devido suspensao
     -- GRATIFICACAO DE HORA-PLANTAO SJC
     vCdRub1035   := NVL(PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,1035),0);

     -- CONVOCACAO LC 472 ART61
     vCdRub1003   := NVL(PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,1003),0);

     --  ADICIONAL DE PLANTAO NOTURNO SJC
     vCdRub1078   := NVL(PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,1078),0);

     --
     -- Solicitacao de Sustentacao #77379
     -- SEA - FOLHA - 10725/2017 - Alteracoes na regra do erario automatico. Excluir rubrica 01-0494
     --
     vCdRubJeton := PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,494);

     DELETE tmp_niquel WHERE cdvinculo = pCdVinculo;

     FOR i IN PKGPAG_VAR.vgAfastTempNaoRemun.FIRST .. PKGPAG_VAR.vgAfastTempNaoRemun.LAST

     LOOP

     -- #71603 9100/2016 - FOLHA - - ROTINA DE DEVOLUCAO AO ERARIO PARA AFASTAMENTOS NAO REMUNERADOS
     -- RETIRAR DO ROL DE AFASTAMENTOS DA ROTINA DE DEVOLUCAO AO ERARIO AUTOMATICA PARA AFASTAMENTOS NAO REMUNERADOS
     -- OS AFASTAMENTOS DA LISTA ABAIXO:
     --IF PKGPAG_VAR.vgListaEventoAfastDevErario.EXISTS(PKGPAG_VAR.vgAfastTempNaoRemun(i).cdmotivoAfastamento) THEN
     --   CONTINUE;
     -- END IF;

     --
     -- Pesquisar codigo da folha de pagamento do mes do inicio do afastamento
     -- para procurar os valores da epoca do afastamento
     --

     vAnoMes := TO_NUMBER(TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,'YYYYMM'));

     vAnoMesFim := TO_NUMBER(TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'YYYYMM'));

     IF vAnoMesFim = TO_CHAR(pFolha.DtInicioMes,'yyyymm') THEN
       
        vAnoMesFim := TO_CHAR(pFolha.DtInicioMes-1,'yyyymm');
     
     END IF;

     vNuDiasAfastAuxAlim := 0;

     vNuDiasAfastMes:= tDiasAfast();

     vNuDiasAfastMes.Extend(12);

     IF vAnoMes = TO_NUMBER(TO_CHAR((pFolha.DtInicioMes - 1), 'YYYYMM')) AND
        vAnoMesFim = TO_NUMBER(TO_CHAR((pFolha.DtInicioMes - 1), 'YYYYMM')) THEN

       vNuDiasAfastMes(TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'mm')) :=
                      LEAST(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,pFolha.DtInicioMes - 1) -
                      PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa + 1;

       IF vNuDiasAfastMes(TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'mm')) > 30 THEN

          vNuDiasAfastMes(TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'mm')) := 30;

       END IF;

       delete tmp_niquel t
              WHERE t.cdvinculo = pCdVinculo
                AND t.cdfolhapagamento = pFolha.cdfolhapagamentoNormalAnt;

       insert INTO tmp_niquel
              (cdfolhapagamento, cdvinculo, dtinicio, dtfim, vlvalor1, vlvalor2)
               values (pFolha.CdFolhaPagamentoNormalAnt, pcdvinculo,
                       PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,
                       PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,
                       vNuDiasAfastMes(TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'mm')),1);

      ELSE

         for fol in (SELECT FP.Cdfolhapagamento, fp.numesreferencia, fp.nuanomesreferencia, fp.dtcalculo,
                            fp.cdtipocalculo
                       FROM EpagFolhaPagamento FP
                      INNER JOIN EpagtipofolhaPagamento TF 
                         ON TF.Cdtipofolhapagamento = FP.Cdtipofolhapagamento AND
                            TF.Cdtipofolha = PKGPAG_TIPO.cnTpFolhaNormal
                      WHERE FP.Cdtipocalculo in (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl)
                        AND FP.Flcalculodefinitivo = 'S'
                        AND FP.Nuanomesreferencia between vAnoMes AND vAnoMesFim
                        AND FP.Cdorgao = pFolha.CdOrgao
                        AND FP.Cdagrupamento = pFolha.CdAgrupamento)

             loop

               BEGIN

               vRecebeu := 0;

               SELECT  1
                 INTO vRecebeu
                 FROM epagcapahistrubricavinculo cp
                WHERE cp.cdvinculo = pCdVinculo
                  AND cp.cdfolhapagamento = fol.cdfolhapagamento;

               delete tmp_niquel t
                WHERE t.cdvinculo = pCdVinculo
                  AND t.cdfolhapagamento = fol.cdfolhapagamento;

               vNuDiasAfastMes(fol.numesreferencia) :=
                   CASE WHEN fol.nuanomesreferencia =
                             TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,'yyyymm')
                        AND  fol.nuanomesreferencia =
                             TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'yyyymm')

                        THEN PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa -
                             PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa + 1

                        WHEN fol.nuanomesreferencia =
                             TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,'yyyymm')
                        AND  fol.nuanomesreferencia <>
                             TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'yyyymm')

                        THEN last_day(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa) -
                             PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa + 1

                        WHEN fol.nuanomesreferencia <>
                             TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,'yyyymm') AND
                             fol.nuanomesreferencia <>
                             TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'yyyymm')

                        THEN last_day(fol.dtcalculo) -
                             last_day(add_months(fol.dtcalculo,-1)) + 1

                       WHEN fol.nuanomesreferencia =
                             TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'yyyymm')

                        THEN TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,'dd')

                   END;

                IF vNuDiasAfastMes(fol.numesreferencia) > 30 THEN
                   vNuDiasAfastMes(fol.numesreferencia) := 30;
                END IF;

                IF NOT (vNuDiasAfastMes(fol.numesreferencia) = 1 AND
                   TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,'yyyymm') = fol.nuanomesreferencia AND
                   TO_CHAR(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,'dd') = 31) THEN

                  insert INTO tmp_niquel
                          (cdfolhapagamento, cdvinculo, dtinicio, dtfim, vlvalor1, vlvalor2)
                           values (fol.cdfolhapagamento, pcdvinculo,
                                   PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,
                                   PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa,
                                   vNuDiasAfastMes(fol.numesreferencia),fol.cdtipocalculo);
                END IF;

               EXCEPTION
                  WHEN OTHERS THEN
                      NULL;
               END;

             END loop;


     END IF;

     vNuDiasAfast := CASE 
                       WHEN NVL(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa + 1, PKGPAG_VAR.vgfolha.DtInicioMes + 1) > PKGPAG_VAR.vgfolha.DtInicioMes THEN 
                         PKGPAG_VAR.vgfolha.DtInicioMes
                     ELSE PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa + 1 END - PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa;

     IF PKGPAG_VAR.vgListaEventoAfast11.EXISTS(PKGPAG_VAR.vgAfastTempNaoRemun(i).cdmotivoAfastamento) THEN
       
        vNuDiasAfastAuxAlim := 0;

      ELSIF pFolha.CdAgrupamento = 133 THEN
        -- Para a PGTC, considerar o pagamento referente ao numero de dias do mes, limitado a 30.
        vNuDiasAfastAuxAlim := (CASE WHEN NVL(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa, PKGPAG_VAR.vgfolha.DtInicioMes) >=
                                                           PKGPAG_VAR.vgfolha.DtInicioMes
                                                      THEN PKGPAG_VAR.vgfolha.DtInicioMes -1
                                                      ELSE PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa
                                                  END) - PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa +1;

        vNuDiasAuxAlimMes := 30;

      ELSE
        
        vNuDiasAfastAuxAlim := pkgmov.FQTDIAUTIL (PCDAGRUPAMENTO           => pFolha.CdAgrupamento,
                                                  PCDORGAO                 => pFolha.CdOrgao,
                                                  PCDUNIDADEORGANIZACIONAL => PKGPAG_VAR.vgRelVincPrincipal.CdUnidadeOrganizacional,
                                                  PDTINICIO                => PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,
                                                  PDTFIM                   => (CASE 
                                                                                 WHEN NVL(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa, PKGPAG_VAR.vgfolha.DtInicioMes) >=
                                                                                     PKGPAG_VAR.vgfolha.DtInicioMes THEN 
                                                                                   PKGPAG_VAR.vgfolha.DtInicioMes -1
                                                                                ELSE PKGPAG_VAR.vgAfastTempNaoRemun(i).DtFimAfa
                                                                                END),
                                                  PEVENTOAUXILIOALIM       => 'S',
                                                  PFLCALCULOGERAL          => PKGPAG_VAR.vgCalculo.flgeral);

        vNuDiasAuxAlimMes := pkgmov.FQTDIAUTIL (PCDAGRUPAMENTO           => pFolha.CdAgrupamento,
                                                PCDORGAO                 => pFolha.CdOrgao,
                                                PCDUNIDADEORGANIZACIONAL => PKGPAG_VAR.vgRelVincPrincipal.CdUnidadeOrganizacional,
                                                PDTINICIO                => last_day(add_months(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa,-1)) + 1,
                                                PDTFIM                   => last_day(PKGPAG_VAR.vgAfastTempNaoRemun(i).DtInicioAfa),
                                                PEVENTOAUXILIOALIM       => 'S',
                                                PFLCALCULOGERAL          => PKGPAG_VAR.vgCalculo.flgeral);

       IF vNuDiasAuxAlimMes > PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite THEN

         vNuDiasAuxAlimMes := PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite;

       END IF;

     END IF;

     --
     -- Verificar se ja existe processo incluido pelo calculo e fazer update
     --

     BEGIN

       SELECT RE.Cdprocessorestituicaoerario,
              RE.Cdsituacaoprocesso
         INTO vCdProcesso,
              vCdSituacaoProcesso
         FROM EREPPROCESSORESTITUICAOERARIO RE
        WHERE RE.Deprocesso = 'PROCESSO AUTOMATICO REF. AFASTAMENTOS NAO REMUNERADOS RETROATIVOS'
          AND RE.Cdvinculo = pCdVinculo
          AND RE.Nuanoiniciorestituicao = substr(vAnoMes,1,4)
          AND RE.Numesiniciorestituicao = substr(vAnoMes,5,2)
          AND RE.Flanulado = 'N'
          AND RE.FlAutomatico = 'S'
          AND RE.deobservacao = PKGPAG_VAR.vgAfastTempNaoRemun(i).cdmotivoAfastamento;

       vExiste := 'S';

     EXCEPTION
         
         WHEN NO_DATA_FOUND THEN

           vCdSituacaoProcesso := 0;
           
           SELECT Srepprocessorestituicaoerario.Nextval
             INTO vCdProcesso
             FROM Dual;

         WHEN OTHERS THEN
           
           vCdSituacaoProcesso := 0;
           
           SELECT Srepprocessorestituicaoerario.Nextval
             INTO vCdProcesso
             FROM Dual;
             
     END;

     -- O Processo pode ser cancelado pelo usuário. Se esta ação ocorrer, o processo não deve ser regerado
     
     IF NVL(vCdSituacaoProcesso,0) IN (0,2) THEN
       
       -- #71603 9100/2016 - FOLHA - - ROTINA DE DEVOLUCAO AO ERARIO PARA AFASTAMENTOS NAO REMUNERADOS
       -- RETIRAR DO ROL DE AFASTAMENTOS DA ROTINA DE DEVOLUCAO AO ERARIO AUTOMATICA PARA AFASTAMENTOS NAO REMUNERADOS
       -- OS AFASTAMENTOS DA LISTA ABAIXO:
       IF PKGPAG_VAR.vgListaEventoAfastDevErario.EXISTS(PKGPAG_VAR.vgAfastTempNaoRemun(i).cdmotivoAfastamento) THEN

          -- SE PROCESSO JA EXISTE, ANULA-O
          IF vExiste = 'S' AND NVL(vCdSituacaoProcesso,0) <> 6 THEN

           -- PROCESSO
           UPDATE ERepProcessoRestituicaoErario RE
              SET RE.DtUltAlteracao = SYSDATE,
                  RE.Flanulado = 'S',
                  RE.Dtanulado = SYSDATE
            WHERE RE.CDPROCESSORESTITUICAOERARIO = vCdProcesso;

          END IF;

          -- PASSA AO PROXIMO AFASTAMENTO
          CONTINUE;

       END IF;
         

       IF vExiste = 'S'   THEN

           -- PROCESSO
           UPDATE ERepProcessoRestituicaoErario RE
              SET RE.DtUltAlteracao = SYSDATE,
                  RE.Dtativacaoprocesso = SYSDATE,
                  re.Nuanoiniciorestituicao = substr(vAnoMes,1,4),
                  re.Numesiniciorestituicao =  substr(vAnoMes,5,2),
                  re.Nuanofinalrestituicao = substr(vAnoMesFim,1,4),
                  re.Numesfinalrestituicao = substr(vAnoMesFim,5,2)
            WHERE RE.CDPROCESSORESTITUICAOERARIO = vCdProcesso;

           -- RUBRICAS

           vVlTotalComIncidencia := 0;

           FOR rub IN (SELECT ERM.CDPROCESSOMONTANTERESTITUIR, ERM.Cdrubricaagrupamento, EPR.NURUBRICA
                         FROM EREPPROCESSOMONTANTERESTITUIR ERM
                         INNER JOIN ePagRubricaAgrupamento ERA ON ERA.CdRubricaAgrupamento = ERM.CdRubricaAgrupamento
                         INNER JOIN ePagRubrica EPR ON EPR.CdRubrica = ERA.CdRubrica
                                                   AND NOT (EPR.Cdtiporubrica = 4 AND EPR.NuRubrica = 915)
                        WHERE ERM.Cdprocessorestituicaoerario = vCdProcesso)
           LOOP

              vCdRubrica := PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,RUB.NuRubrica);

              vVlPagamento := 0;

              IF vCdRubrica = vCdRubAuxAlim AND vNuDiasAfastAuxAlim > 0 THEN

                  SELECT TRUNC(ERV.VlPagamento / vNuDiasAuxAlimMes *
                               vNuDiasAfastAuxAlim,
                               2)
                    INTO vVlPagamento
                    FROM EPAGHISTORICORUBRICAVINCULO ERV
                   INNER JOIN tmp_niquel t
                      ON t.cdvinculo = erv.cdvinculo
                     AND t.cdfolhapagamento = erv.cdfolhapagamento
                   WHERE ERV.CDVINCULO = pCdVinculo
                     AND ERV.Cdrubricaagrupamento = vCdRubrica
                     AND rownum < 2;

              ELSE

                  SELECT  sum(x.valor) as VLR
                    INTO vVlPagamento
                    FROM (SELECT  TRUNC(ERV.VlPagamento / 30 * vlValor1, 2) as VALOR
                            FROM EPAGHISTORICORUBRICAVINCULO ERV
                           INNER JOIN tmp_niquel t
                              ON t.cdvinculo = erv.cdvinculo
                             AND t.cdfolhapagamento = erv.cdfolhapagamento
                          
                           WHERE ERV.CDVINCULO = pCdVinculo
                             AND ERV.CdRubricaAgrupamento = vCdRubrica
                             AND t.vlvalor2 = 1) X;

                  vVlDesconto := 0;

                  vCdRubrica := PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,8,RUB.NuRubrica);

                  BEGIN

                  SELECT  sum(x.valor) as VLR
                    INTO vVlDesconto
                    FROM (SELECT  TRUNC(ERV.VlPagamento / 30 * vlValor1, 2) as VALOR
                            FROM EPAGHISTORICORUBRICAVINCULO ERV
                           INNER JOIN tmp_niquel t
                              ON t.cdvinculo = erv.cdvinculo
                             AND t.cdfolhapagamento = erv.cdfolhapagamento
                          
                           WHERE ERV.CDVINCULO = pCdVinculo
                             AND ERV.CdRubricaAgrupamento = vCdRubrica
                             AND t.vlvalor2 = 5) X;

                    EXCEPTION
                      WHEN OTHERS THEN
                        vVlDesconto := 0;

                    END;

                    vVlPagamento := vVlPagamento - NVL(vVlDesconto,0);

                    IF vVlPagamento <  0 THEN

                       vVlPagamento := 0;

                    END IF;

               END IF;

               IF vListaRubBaseIprev.EXISTS(vCdRubrica)
                  THEN

                    vVlSemIncidencia := 0;
                    vVlComIncidencia := vVlPagamento;
                    vVlTotalComIncidencia := vVlTotalComIncidencia + vVlComIncidencia;

                  ELSE

                    vVlSemIncidencia := vVlPagamento;
                    vVlComIncidencia :=  0;

                END IF;

              -- RUBRICAS VALOR TOTAL--
              UPDATE EREPPROCESSOMONTANTERESTITUIR ERM
                 SET ERM.VLRESTITUIR = vVlPagamento
               WHERE ERM.CDPROCESSOMONTANTERESTITUIR = RUB.CDPROCESSOMONTANTERESTITUIR
                 AND ERM.Cdrubricaagrupamento = RUB.Cdrubricaagrupamento;

              -- RUBRICAS VALOR MENSAL UMA COMO FATO GERADOR
              UPDATE EREPPROCESSORESTITUICOESDEVIDA ERD
                 SET ERD.Vlrestituircomincidencia = vVlComIncidencia,
                     ERD.Vlrestituirsemincidencia = vVlSemIncidencia,
                     ERD.DtUltAlteracao = SYSDATE
               WHERE ERD.CDPROCESSORESTITUICAOERARIO = vCdProcesso
                 AND ERD.CDRUBRICAAGRUPAMENTO = RUB.CDRUBRICAAGRUPAMENTO;

              -- LANCAMENTOS FINANCEIROS
              SELECT LF.Cdlancamentofinanceiro
                INTO vCdLancamento
                FROM EPAGLANCAMENTOFINANCEIRO LF
               WHERE LF.CDVINCULO = pCdVinculo
                 AND LF.CDRUBRICAAGRUPAMENTO = RUB.Cdrubricaagrupamento
                 AND LF.Cdprocessorestituicaoerario = vCdProcesso;

              UPDATE EPAGLANCAMENTOFINANCEIRO LF
                 SET LF.VLLANCAMENTOFINANCEIRO = vVlPagamento,
                     LF.Dtultalteracao = SYSDATE
               WHERE LF.Cdlancamentofinanceiro = vCdLancamento;

              UPDATE EPAGLANCAMENTOCOMPETENCIA LC
                 SET LC.Vllancamento = vVlPagamento,
                     LC.Vlfinal = vVlPagamento,
                     LC.Dtultalteracao = SYSDATE
               WHERE LC.Cdlancamentofinanceiro = vCdLancamento;

           END LOOP;

            -- CORRECAO MONETARIA DO PROCESSO
           UPDATE EREPPROCESSOCORRECAOMONETARIA CM
              SET CM.VLDEBITOSERVIDOR = (SELECT SUM(VlRestituir)
                                           FROM EREPPROCESSOMONTANTERESTITUIR ERM
                                          WHERE ERM.CdProcessoRestituicaoErario = vCdProcesso),
                  CM.VLCREDITOSERVIDOR = vVlTotalComIncidencia *
                                         TRUNC(NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2)
              WHERE CM.CDPROCESSORESTITUICAOERARIO = vCdProcesso;

           IF vVlTotalComIncidencia > 0 THEN

               -- RUBRICAS VALOR TOTAL--
              UPDATE EREPPROCESSOMONTANTERESTITUIR ERM
                 SET ERM.VLRESTITUIR = TRUNC (vVlTotalComIncidencia *
                                              NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2)
               WHERE ERM.Cdprocessorestituicaoerario = vCdProcesso
                 AND ERM.Cdrubricaagrupamento = PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,4,915);

              -- RUBRICAS VALOR MENSAL UMA COMO FATO GERADOR
              UPDATE EREPPROCESSORESTITUICOESDEVIDA ERD
                 SET ERD.Vlrestituircomincidencia = 0,
                     ERD.Vlrestituirsemincidencia = TRUNC (vVlTotalComIncidencia *
                                                      NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2),
                     ERD.DtUltAlteracao = SYSDATE
               WHERE ERD.CDPROCESSORESTITUICAOERARIO = vCdProcesso
                 AND ERD.CDRUBRICAAGRUPAMENTO = PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,4,915);

              -- LANCAMENTOS FINANCEIROS
              SELECT LF.Cdlancamentofinanceiro
                INTO vCdLancamento
                FROM EPAGLANCAMENTOFINANCEIRO LF
               WHERE LF.CDVINCULO = pCdVinculo
                 AND LF.CDRUBRICAAGRUPAMENTO = PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,4,915)
                 AND LF.Cdprocessorestituicaoerario = vCdProcesso;

              UPDATE EPAGLANCAMENTOFINANCEIRO LF
                 SET LF.VLLANCAMENTOFINANCEIRO = TRUNC(vVlTotalComIncidencia *
                                                   NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2),
                     LF.Dtultalteracao = SYSDATE
               WHERE LF.Cdlancamentofinanceiro = vCdLancamento;

              UPDATE EPAGLANCAMENTOCOMPETENCIA LC
                 SET LC.Vllancamento = TRUNC(vVlTotalComIncidencia *
                                                   NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2),
                     LC.Vlfinal = TRUNC(vVlTotalComIncidencia *
                                                   NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2),
                     LC.Dtultalteracao = SYSDATE
               WHERE LC.Cdlancamentofinanceiro = vCdLancamento;

           END IF;

           PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                   pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                   pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                   pDeLog                   => 'Atualizado processo automático de restituição ao erário referente a afastamentos retroativos!',
                                   pCdVinculo               => pCdVinculo,
                                   pCdTipoOcorrencia        => 2,
                                   pcdmotivoocorrencia      => 26);

       ELSE

           -- PROCESSO
           INSERT
             INTO ERepProcessoRestituicaoErario RE
                  (CdProcessoRestituicaoErario,
                   CdVinculo,
                   NuProcesso,
                   DeProcesso,
                   CdSituacaoProcesso,
                   NuAnoInicioRestituicao,
                   NuMesInicioRestituicao,
                   NuAnoFinalRestituicao,
                   NuMesFinalRestituicao,
                   DtProcesso,
                   CdValorReferencia,
                   NuAnoRefAplicCorrecao,
                   NuMesRefAplicCorrecao,
                   NuCpfCadastrador,
                   DtInclusao,
                   FlAnulado,
                   DtUltAlteracao,
                   DtAtivacaoProcesso,
                   FlMigrado,
                   DeObservacao,
                   FlAutomatico)
            VALUES (vCdProcesso,
                    pCdVinculo,
                    vCdFolha,
                    'PROCESSO AUTOMATICO REF. AFASTAMENTOS NAO REMUNERADOS RETROATIVOS',
                    2, -- Ativo
                    substr(vAnoMes,1,4),
                    substr(vAnoMes,5,2),
                    substr(vAnoMesFim,1,4),
                    substr(vAnoMesFim,5,2),
                    SYSDATE,
                    vCdCorrecao,
                    pFolha.NuAnoReferencia,
                    pFolha.NuMesReferencia,
                    11111111111,
                    SYSDATE,
                    'N',
                    SYSDATE,
                    SYSDATE,
                    'N',
                    PKGPAG_VAR.vgAfastTempNaoRemun(i).cdmotivoAfastamento,
                    'S');

            PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                    pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                    pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                    pDeLog                   => 'Incluído processo automático de restituição ao erário referente a afastamentos retroativos!',
                                    pCdVinculo               => pCdVinculo,
                                    pCdTipoOcorrencia        => 2,
                                    pcdmotivoocorrencia      => 26);
             -- RUBRICAS VALOR TOTAL

             INSERT INTO EREPPROCESSOMONTANTERESTITUIR ERM
               (CdProcessoMontanteRestituir,
                CdProcessoRestituicaoErario,
                CdRubricaAgrupamento,
                VlRestituir,
                FlRestituicaoCompleta,
                NuAnoInicioDevolucao,
                NuMesInicioDevolucao)
               (SELECT Srepprocessomontanterestituir.nextval,
                       vCdProcesso,
                       PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,
                                                    8,
                                                    y.Rub),
                       y.vlr,
                       'N',
                       pFolha.NuAnoReferencia,
                       pFolha.NuMesReferencia
                  FROM (SELECT  sum(x.valor - x.desconto) as VLR,
                               x.nurubrica AS RUB
                          FROM (SELECT  TRUNC(ERV.VlPagamento / 30 *
                                             t.vlvalor1,
                                             2) as VALOR,
                                       0 as DESCONTO,
                                       epr.nurubrica as NURUBRICA
                                  FROM EPAGHISTORICORUBRICAVINCULO ERV
                                 INNER JOIN tmp_niquel t
                                    ON t.cdvinculo = erv.cdvinculo
                                   AND t.cdfolhapagamento =
                                       erv.cdfolhapagamento
                                   AND t.vlvalor2 = 1
                                 INNER JOIN ePagRubricaAgrupamento ERA
                                    ON ERA.CdRubricaAgrupamento =
                                       ERV.CdRubricaAgrupamento
                                 INNER JOIN ePagRubrica EPR
                                    ON EPR.CdRubrica = ERA.CdRubrica
                                   AND EPR.CdTipoRubrica = 1
                                 WHERE ERV.CDVINCULO = pCdVinculo
                                   AND ERV.CdRubricaAgrupamento NOT in
                                       (vCdRubAuxAlim,
                                        vCdRubFerias,
                                        vCdRubJeton,
                                        vCdRub1003,
                                        vCdRub1035,
                                        vCdRub1078)
                                union all
                                  
                                SELECT  0 as VALOR,
                                       TRUNC(ERV.VlPagamento / 30 *
                                             t.vlvalor1,
                                             2) as DESCONTO,
                                       epr.nurubrica as NURUBRICA
                                  FROM EPAGHISTORICORUBRICAVINCULO ERV
                                 INNER JOIN tmp_niquel t
                                    ON t.cdvinculo = erv.cdvinculo
                                   AND t.cdfolhapagamento =
                                       erv.cdfolhapagamento
                                   AND t.vlvalor2 = 5
                                 INNER JOIN ePagRubricaAgrupamento ERA
                                    ON ERA.CdRubricaAgrupamento =
                                       ERV.CdRubricaAgrupamento
                                 INNER JOIN ePagRubrica EPR
                                    ON EPR.CdRubrica = ERA.CdRubrica
                                   AND EPR.CdTipoRubrica = 8
                                 WHERE ERV.CDVINCULO = pCdVinculo
                                   AND ERV.CdRubricaAgrupamento NOT in
                                       (vCdRubAuxAlim,
                                        vCdRubFerias,
                                        vCdRubJeton,
                                        vCdRub1003,
                                        vCdRub1035,
                                        vCdRub1078)
                                  
                                ) X
                         group by x.nurubrica) y
                 WHERE y.vlr > 0);

             IF vNuDiasAfastAuxAlim > 0 THEN
                 
               INSERT INTO EREPPROCESSOMONTANTERESTITUIR ERM
                 (CdProcessoMontanteRestituir,
                  CdProcessoRestituicaoErario,
                  CdRubricaAgrupamento,
                  VlRestituir,
                  FlRestituicaoCompleta,
                  NuAnoInicioDevolucao,
                  NuMesInicioDevolucao)
                 (SELECT Srepprocessomontanterestituir.nextval,
                         vCdProcesso,
                         PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,
                                                      8,
                                                      vp.NuRubrica),
                         TRUNC(ERV.VlPagamento / vNuDiasAuxAlimMes *
                               vNuDiasAfastAuxAlim,
                               2),
                         'N',
                         pFolha.NuAnoReferencia,
                         pFolha.NuMesReferencia
                    FROM EPAGHISTORICORUBRICAVINCULO ERV
                   INNER JOIN tmp_niquel tt
                      ON tt.cdvinculo = pCdVinculo
                     AND tt.CdFolhaPagamento = erv.cdfolhapagamento
                   INNER JOIN vpagrubrica vp
                      ON erv.cdrubricaagrupamento =
                         vp.cdrubricaagrupamento
                   WHERE ERV.CDVINCULO = pCdVinculo
                     AND ERV.CdRubricaAgrupamento = vCdRubAuxAlim
                     AND rownum < 2);
                              
             END IF;

             -- RUBRICAS VALOR MENSAL UMA COMO FATO GERADOR

             vVlTotalComIncidencia := 0;

             FOR REST IN (SELECT ERM.CDPROCESSOMONTANTERESTITUIR, ERM.Cdrubricaagrupamento, EPR.NURUBRICA, ERM.Vlrestituir,
                                 ROWNUM AS NUMERO
                            FROM EREPPROCESSOMONTANTERESTITUIR ERM
                            INNER JOIN ePagRubricaAgrupamento ERA 
                               ON ERA.CdRubricaAgrupamento = ERM.CdRubricaAgrupamento
                            INNER JOIN ePagRubrica EPR 
                               ON EPR.CdRubrica = ERA.CdRubrica
                            WHERE ERM.CdProcessoRestituicaoErario = vCdProcesso
                            ORDER BY EPR.NURUBRICA)

             LOOP

                IF vListaRubBaseIprev.EXISTS(PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,REST.NuRubrica)) THEN

                    vVlSemIncidencia := 0;
                    vVlComIncidencia := REST.VLRESTITUIR;
                    vVlTotalComIncidencia := vVlTotalComIncidencia + vVlComIncidencia;

                ELSE

                    vVlSemIncidencia := REST.VLRESTITUIR;
                    vVlComIncidencia :=  0;

                END IF;

               INSERT
                 INTO EREPPROCESSORESTITUICOESDEVIDA ERD
                      (CdProcessoRestituicoesDevidas,
                       CdProcessoRestituicaoErario,
                       NuAnoCompetencia,
                       NuMesCompetencia,
                       CdRubricaAgrupamento,
                       FlFatoGerador,
                       VlRestituirComIncidencia,
                       VlRestituirSemIncidencia,
                       NuCpfCadastrador,
                       DtInclusao,
                       DtUltAlteracao,
                       FlAutomatico) -- Se for S nao aparecem na aplicacao
                VALUES (Srepprocessorestituicoesdevida.nextval,
                         vCdProcesso,
                         pFolha.NuAnoReferencia,
                         pFolha.NuMesReferencia,
                         REST.CDRUBRICAAGRUPAMENTO,
                         CASE WHEN REST.NUMERO = 1 THEN 'S' ELSE 'N' END,
                         vVlComIncidencia,
                         vVlSemIncidencia,
                         11111111111,
                         SYSDATE,
                         SYSDATE,
                        'N' );

               END LOOP;

               IF vVlTotalComIncidencia > 0 THEN
                   --
                   -- Ressarcimento IPREV sobre devolucoes
                   --
                   INSERT
                     INTO EREPPROCESSORESTITUICOESDEVIDA ERD
                          (CdProcessoRestituicoesDevidas,
                           CdProcessoRestituicaoErario,
                           NuAnoCompetencia,
                           NuMesCompetencia,
                           CdRubricaAgrupamento,
                           FlFatoGerador,
                           VlRestituirComIncidencia,
                           VlRestituirSemIncidencia,
                           NuCpfCadastrador,
                           DtInclusao,
                           DtUltAlteracao,
                           FlAutomatico) -- Se for S nao aparecem na aplicacao
                   VALUES  (Srepprocessorestituicoesdevida.nextval,
                             vCdProcesso,
                             pFolha.NuAnoReferencia,
                             pFolha.NuMesReferencia,
                             PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,4,915),
                             'N',
                             0,
                             TRUNC(vVlTotalComIncidencia * NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2),
                             11111111111,
                             SYSDATE,
                             SYSDATE,
                            'N' );

                   INSERT
                     INTO EREPPROCESSOMONTANTERESTITUIR ERM
                          (CdProcessoMontanteRestituir,
                           CdProcessoRestituicaoErario,
                           CdRubricaAgrupamento,
                           VlRestituir,
                           FlRestituicaoCompleta,
                           NuAnoInicioDevolucao,
                           NuMesInicioDevolucao)
                   VALUES (Srepprocessomontanterestituir.nextval,
                           vCdProcesso,
                           PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,4,915),
                           TRUNC(vVlTotalComIncidencia * NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2),
                           'N',
                           pFolha.NuAnoReferencia,
                           pFolha.NuMesReferencia);

               END IF;

                -- CORRECAO MONETARIA DO PROCESSO
              INSERT
                INTO EREPPROCESSOCORRECAOMONETARIA CM
                    (CdProcessoCorrecaoMonetaria,
                     CdProcessoRestituicaoErario,
                     NuAnoCompetencia,
                     NuMesCompetencia,
                     VlDebitoServidor,
                     VlCreditoServidor)
              (SELECT SREPPROCESSOCORRECAOMONETARIA.nextval,
                     vCdProcesso,
                     pFolha.NuAnoReferencia,
                     pFolha.NuMesReferencia,
                     (SELECT SUM(VlRestituir)
                             FROM EREPPROCESSOMONTANTERESTITUIR ERM
                             WHERE ERM.CdProcessoRestituicaoErario = vCdProcesso),
                     NVL(TRUNC(vVlTotalComIncidencia * NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0),2),0)
                FROM DUAL);

               -- LANCAMENTOS FINANCEIROS

               INSERT
                INTO EPAGLANCAMENTOFINANCEIRO LF
                     (CdLancamentoFinanceiro,
                      CdVinculo,
                      NuSufixoRubrica,
                      DtInicioDireito,
                      FlValorProporcional,
                      FlPagaAfastDefinitivo,
                      NuCpfCadastrador,
                      DtInclusao,
                      DtUltAlteracao,
                      FlDecisaoJudicial,
                      FlFolhaSuplementar,
                      VlLancamentoFinanceiro,
                      FlAnulado,
                      CdRubricaAgrupamento,
                      InPeriodicidade,
                      CdProcessoRestituicaoErario,
                      FlAutomatico,
                      FlObservaLimRetroativoErario)
                (SELECT SPAGLANCAMENTOFINANCEIRO.Nextval,
                        pCdVinculo,
                        1,
                        pFolha.DtInicioMes,
                        'N',
                        'N',
                        11111111111,
                        SYSDATE,
                        SYSDATE,
                        'N',
                        'N',
                        ERM.VlRestituir,
                        'N',
                        ERM.CDRUBRICAAGRUPAMENTO,
                        'Q',
                        vCdProcesso,
                        'S',
                        'S'
                  FROM EREPPROCESSOMONTANTERESTITUIR ERM
                  WHERE ERM.CdProcessoRestituicaoErario = vCdProcesso); --pFolha.CdFolhaPagamentoNormalAnt);

                INSERT
                  INTO EPAGLANCAMENTOCOMPETENCIA LC
                       (CdLancamentoCompetencia,
                        CdLancamentoFinanceiro,
                        NuAnoReferencia,
                        NuMesReferencia,
                        VlLancamento,
                        VlFinal,
                        DtUltAlteracao)
                  (SELECT sPagLancamentoCompetencia.Nextval,
                          Lf.CdLancamentoFinanceiro,
                          pFolha.NuAnoReferencia,
                          pFolha.NuMesReferencia,
                          Lf.VlLancamentoFinanceiro,
                          Lf.VlLancamentoFinanceiro,
                          SYSDATE
                          FROM EPAGLANCAMENTOFINANCEIRO LF
                         WHERE CdProcessoRestituicaoErario = vCdProcesso);

           END IF;
           
       END IF;
       
     END LOOP;

   END;

PROCEDURE pajustaparcelanaocomputadaERA(pcdprocessorestituicaoerario IN INTEGER,
                                        pcdlancamentofinanceiro      IN INTEGER,
                                        pcdvinculo                   IN INTEGER) IS

  bInclusao boolean := FALSE;

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
                 AND NOT EXISTS (SELECT  1 
                                   FROM epagpagamentolancamento pag
                                  WHERE pag.cdlancamentofinanceiro = pcdlancamentofinanceiro
                                    AND pag.nuanoreferencia = fp.nuanoreferencia
                                    AND pag.numesreferencia = fp.numesreferencia)) LOOP

      PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => pcdlancamentofinanceiro,
                                          pNuAnoReferencia => rec.nuanoreferencia,
                                          pNuMesreferencia => rec.numesreferencia,
                                          pNuParcela => 1,
                                          pValorParcela => rec.vlpagamento);

      binclusao := TRUE;

      PKGPAG_GERAL.pinserelog(pinsere                  => PKGPAG_VAR.blog,
                              pcdhistoricoparamcalculo => PKGPAG_VAR.vcdhistparamcalc,
                              pcdpessoa                => PKGPAG_VAR.vcdpessoa,
                              pdelog                   => 'Incluído parcela de erário não computada referente ao ano de ' ||
                                                          rec.nuanoreferencia || ' mês ' || rec.numesreferencia,
                              pcdvinculo               => pcdvinculo,
                              pcdtipoocorrencia        => 2);

  END LOOP;

  IF bInclusao THEN

     MERGE INTO epagpagamentolancamento epl
        USING (SELECT  pag.cdpagamentolancamento,
                      rank() over (order by pag.nuanoreferencia, pag.numesreferencia) parcela
                 FROM epagpagamentolancamento pag
                WHERE pag.cdlancamentofinanceiro = pcdlancamentofinanceiro) xx
           ON (xx.cdpagamentolancamento = epl.cdpagamentolancamento)
           WHEN MATCHED THEN
           UPDATE SET epl.nuparcela = xx.parcela;

  END IF;

EXCEPTION

  WHEN OTHERS THEN

    PKGPAG_GERAL.pinserelog(PKGPAG_VAR.blog,
                            PKGPAG_VAR.vcdhistparamcalc,
                            PKGPAG_VAR.vcdpessoa,
                            'Erro ao inserir parcela de erário não computada: Código do lançamento: ' ||
                            pcdlancamentofinanceiro ||
                            '. Código do processo de restituição ao Erário: ' ||
                            pcdprocessorestituicaoerario,
                            PKGPAG_VAR.vgcdvinculo);
END;

   FUNCTION FRetornaValorMargem(pCdFolhaPagamento IN INTEGER,
                                pCdTipoFolha      IN INTEGER,
                                pCdVinculo        IN INTEGER,
                                pCdRubrica        IN INTEGER,
                                pvllimitepercentualmensal IN INTEGER DEFAULT NULL,
                                pFlObservaLimite  IN CHAR)

     RETURN NUMBER IS

     vvlPagamento  NUMBER(13,2);

   BEGIN

     SELECT vlPagamento
       INTO vvlPagamento
       FROM EPagHistoricoRubricaVinculo HRV
      WHERE HRV.CdVinculo = pCdVinculo AND
            HRV.CdFolhaPagamento = pCdFolhaPagamento AND
            HRV.CdRubricaAgrupamento = pCdRubrica;


     PKGPAG_GERAL.PAtualizaTotalizadoras(pCdFolhaPagamento => pCdFolhaPagamento,
                                          pCdVinculo       => pCdVinculo);

     IF pFlObservaLimite = 'N' THEN

         IF PKGPAG_VAR.vgVlBaseTotalLiquida < vVlPagamento THEN
            return PKGPAG_VAR.vgVlBaseTotalLiquida;
         ELSE
            RETURN vvlPagamento;
         END IF;

     END IF;

     IF NVL(pvllimitepercentualmensal,0) > 0 THEN

       RETURN vvlPagamento*pvllimitepercentualmensal/100;

     ELSIF pCdTipoFolha = PKGPAG_TIPO.cnTpFolhaCtisp
       AND NVL(PKGPAG_VAR.vgVlEraCTISP,0) > 0  THEN

       RETURN vvlPagamento*PKGPAG_VAR.vgVlEraCTISP/100;

     ELSIF pCdTipoFolha <> 11 THEN

       RETURN vvlPagamento*PKGPAG_VAR.vgParamPagamento.VlPercRestituicao/100;

     ELSE

       RETURN vvlPagamento*PKGPAG_VAR.vgParamPagamento.VlPercRestituicaoBolsista/100;

     END IF;

   EXCEPTION

     WHEN OTHERS THEN

       RETURN 0;

   END;

   FUNCTION FConsultaLancamentosPagos(pCdRubrica IN INTEGER,
                                      pCdProcesso IN INTEGER)

     RETURN BOOLEAN IS


     vCont INTEGER :=0;


   BEGIN

     SELECT count(fin.cdrubricaagrupamento)
       INTO vCont
       FROM EPagLancamentoFinanceiro FIN
      WHERE fin.cdprocessorestituicaoerario = pCdProcesso
        AND fin.CdRubricaAgrupamento <> pCdRubrica
        AND TRUNC(fin.dtfimdireito) < TRUNC(PKGPAG_VAR.vgFolha.DtInicioMes);

     IF vCont > 0 THEN
       return TRUE;
     ELSE
       return FALSE;
     END IF;

     EXCEPTION

     WHEN NO_DATA_FOUND THEN
       return FALSE;

     WHEN OTHERS THEN
       return FALSE;

   END;

   PROCEDURE PRestituicaoErario(pFolha               IN PKGPAG_TIPO.rFolha,
                                pCdVinculo           IN INTEGER,
                                pFlCalculoDefinitivo IN CHAR DEFAULT 'N',
                                pflobservalimite     IN CHAR,
                                pFlObsTributacao     IN CHAR DEFAULT 'N') IS

     vvlAbatimento         NUMBER(13,2);
     vvlAbatimentoPrev     NUMBER(13,2);
     vvlPagamento          NUMBER(13,2);
     vVlTotalErario        NUMBER(13,2);
     vVlTotalPago          NUMBER(13,2);
     vVlPagoNoMes          NUMBER(13,2);
     bPrimeiraVez          BOOLEAN DEFAULT TRUE;
     vVlRecebidoRetroativo NUMBER(13,2);
     vCdProcRetroativo     INTEGER;
     vNuAnoMesInicioProc   CHAR(6);
     vVlTotalQuitado       NUMBER(13,2);
     vCdBaseCalculo        INTEGER;
     vBaseCalcIRRF         PKGPAG_TIPO.rBaseCalculo;
     vBaseCalcINSS         PKGPAG_TIPO.rBaseCalculo;

   FUNCTION FRubricaBaseTributacao (pCdRubricaAgrupamento INTEGER) RETURN CHAR IS
     
     vFlRubricaBaseTributacao CHAR(1);
     
   BEGIN
     
     vFlRubricaBaseTributacao := 'N';
     
    
     -- Verifica na base do IRRF
     BEGIN
       SELECT 'S'
         INTO vFlRubricaBaseTributacao
         FROM EPagBaseCalcBlocoExprRubAgrup RX
        INNER JOIN EPagBaseCalculoBlocoExpressao EX
           ON RX.CdBaseCalculoBlocoExpressao = EX.CdBaseCalculoBlocoExpressao
        INNER JOIN EPagBaseCalculoBloco BCB
           ON BCB.CdBaseCalculoBloco = EX.CdBaseCalculoBloco
        INNER JOIN EPagHistBaseCalculo HBC
           ON BCB.CdHistBaseCalculo = HBC.CdHistBaseCalculo
        WHERE HBC.CdHistBaseCalculo = vBaseCalcIRRF.CdHistBaseCalculo AND
              RX.CdRubricaAgrupamento = pCdRubricaAgrupamento;            
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         vFlRubricaBaseTributacao := 'N';         
     END;
     
     IF vFlRubricaBaseTributacao = 'N' AND PKGPAG_VAR.vgVinculo.cdregimeprevidenciario IN (1,2,5) THEN
       
       -- Verifica na base no INSS, CPSM ou IPREV
       BEGIN
         SELECT 'S'
           INTO vFlRubricaBaseTributacao
           FROM EPagBaseCalcBlocoExprRubAgrup RX
          INNER JOIN EPagBaseCalculoBlocoExpressao EX
             ON RX.CdBaseCalculoBlocoExpressao = EX.CdBaseCalculoBlocoExpressao
          INNER JOIN EPagBaseCalculoBloco BCB
             ON BCB.CdBaseCalculoBloco = EX.CdBaseCalculoBloco
          INNER JOIN EPagHistBaseCalculo HBC
             ON BCB.CdHistBaseCalculo = HBC.CdHistBaseCalculo
          WHERE HBC.CdHistBaseCalculo = vBaseCalcINSS.CdHistBaseCalculo AND
                RX.CdRubricaAgrupamento = pCdRubricaAgrupamento;            
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vFlRubricaBaseTributacao := 'N';         
       END;
       
     END IF;
     
     RETURN vFlRubricaBaseTributacao;
     
   END;
   
   BEGIN
     
     -----------------------------------------------------------------------------------------------------------
     -- Chamado 22410/2025
     -- Regra para evitar de descontar erário no vínculo que não está recebendo pagamento (casos de disposição)
     -- Não foi possível identificar a razão pela qual o vínculo com pagamento em outro órgão precisa pelas 
     -- passar pelas rotinas do cálculo
     ----------------------------------------------------------------------------------------------------------
     IF PKGPAG_VAR.vPagaSitDisposicao IN ('PAG-DEST-CALCULO-ORIGEM', 'PAG-ORIGEM-CALCULO-DEST', 'NAO-DISPOSICAO') THEN
       
       RETURN;
       
     END IF;      
            

     IF PKGPAG_VAR.vgFolha.CdTipoFolha IN  (PKGPAG_TIPO.cnTpFolhaNormal,
                                            PKGPAG_TIPO.cnTpFolhaBolsista,
                                            PKGPAG_TIPO.cnTpFolhaResidente,
                                            PKGPAG_TIPO.cnTpFolhaPesquisador,
                                            PKGPAG_TIPO.cnTpFolhaConvenio,
                                            PKGPAG_TIPO.cnTpFolhaFunebre,
                                            PKGPAG_TIPO.cnTpFolhaServAfast,
                                            PKGPAG_TIPO.cnTpFolhaCtisp) THEN

       IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal THEN

         PExcluiHistoricoErario(pFolha,
                                pCdVinculo,
                                pflobservalimite);

       END IF;

       vVlTotalErario := 0;

       vVlTotalPago   := 0;

       vVlPagoNoMes   := 0;

       vVlTotalQuitado := 0;

       PKGPAG_VAR.vgVlTotalDescErarioMes := 0;

       vPossuiObito := 'N';

       IF PKGPAG_VAR.bPossuiObito  THEN
           vPossuiObito := 'S';
       END IF;

       --
       -- 6754/2015 - SEA-DESCONTO AUTOMATICO DE LICENCA DE INTERESSE PARTICULAR INCLUIDAS APOS A FOLHA
       -- INCLUIR AUTOMATICAMENTE PROCESSO DE ERARIO COM BASE NAS RUBRICAS DA FOLHA ANTERIOR
       --
       IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal
         AND PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal
         AND PKGPAG_VAR.vgNuDiasAfastRetroativo > 0
         AND PKGPAG_VAR.vgFolha.cdAgrupamento <> 5 /*Epagri*/ THEN


            pIncluiProcessoErario(pFolha, pCdVinculo);

       END IF;
       
       IF pflobservalimite = 'S' THEN
          FOR vLancRestituicao IN cLancamentoErario( pCdVinculo,
                                                     pFolha,
                                                     'S')
          LOOP

            -- Verificar se existem parcelas pagas e nao registradas na tabela EPAGPAGAMENTOLANCAMENTO

            BEGIN

            vNuAnoMesInicioProc := vLancRestituicao.NuAnoInicioRestituicao || lpad(vLancRestituicao.NuMesInicioRestituicao,2,0);

            IF  vNuAnoMesInicioProc < TO_CHAR(pFolha.DtInicioMes,'yyyymm')
                AND TRUNC(vLancRestituicao.DtAtivacaoProcesso)  < TRUNC(pFolha.DtInicioMes)
                THEN

              pajustaparcelanaocomputadaERA(vLancRestituicao.cdprocessorestituicaoerario,
                                            vLancRestituicao.cdlancamentofinanceiro,
                                            pCdVinculo);
              -- Atualizar total pago e numero de parcelas
              BEGIN
                CASE
                  WHEN pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes
                    THEN

                     SELECT  NVL(sum(pag.vlparcela),0), NVL(max(pag.nuparcela),0)
                       INTO vLancRestituicao.vlpago, vLancRestituicao.qtparcelaspagas
                       FROM epagpagamentolancamento pag
                     WHERE pag.cdlancamentofinanceiro = vLancRestituicao.cdlancamentofinanceiro
                       AND pag.nuanoreferencia || lpad(pag.numesreferencia,2,0) <
                           pFolha.NuAnoReferencia || lpad(pFolha.NuMesReferencia,2,0);

                   ELSE

                     SELECT  NVL(sum(pag.vlparcela),0), NVL(max(pag.nuparcela),0)
                       INTO vLancRestituicao.vlpago, vLancRestituicao.qtparcelaspagas
                       FROM epagpagamentolancamento pag
                      WHERE pag.cdlancamentofinanceiro = vLancRestituicao.cdlancamentofinanceiro;

                   END CASE;

                 EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
              END;

            END IF;

            EXCEPTION
              WHEN OTHERS THEN
                NULL;
            END;

            IF bPrimeiraVez THEN

              bPrimeiraVez := FALSE;

              IF PKGPAG_GERAL.FretornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                   pCdVinculo        => pCdVinculo,
                                                   pCdRubrica        => PKGPAG_VAR.vgCdRubricaErario) = 0 THEN
                                                   
                -- Insere e calcula a base do erario no vinculo
                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pCdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaErario,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => 0,
                                                      pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 11);

                -- Recalcula a base do erario no vinculo
                PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                 pCdVinculo       => pCdVinculo,
                                                 pCdRubrica       => PKGPAG_VAR.vgCdRubricaErario,
                                                 pTpProcessamento => 2,
                                                 pTpLocal         => 2);
                                                 
              END IF;
                                                 
              /* Retornam os valores da base de restituicao do erario e
                 a base do IPESC para os lancamentos com e sem limite de valor
                 respectivamente */

              /* Para processos que nao observam o limite, o valor do abatimento e o valor
                 total da base do erario. */

              IF vLancRestituicao.flobservalimite = 'N' OR 
                ((vLancRestituicao.cdtiporubrica = 8 AND vLancRestituicao.nurubrica = 44) AND PKGPAG_VAR.vgAfastDefinitivo.count > 0) THEN
                
                 vvlAbatimento := FRetornaValorMargem(pFolha.CdFolhaPagamento,
                                                   pFolha.CdTipoFolha,
                                                   pCdVinculo,
                                                   PKGPAG_VAR.vgCdRubricaErario,
                                                   vLancRestituicao.vllimitepercentualmensal,
                                                   vLancRestituicao.flobservalimite);

              ELSE
                
                 vvlAbatimento := FRetornaValorMargem(pFolha.CdFolhaPagamento,
                                                   pFolha.CdTipoFolha,
                                                   pCdVinculo,
                                                   PKGPAG_VAR.vgCdRubricaErario,
                                                   vLancRestituicao.vllimitepercentualmensal,
                                                   vLancRestituicao.FlObservaLimRetroativoErario);
              END IF;

              --
              -- Solicitacao de Sustentacao #76134
              -- SIGRH - [Chamado 10392/2017] - FOLHA - PROCESSOS DE COMPENSACAO
              -- Se tem processo de compensacao, considerar o limite igual ao recebido no retroativo
              --
              IF vLancRestituicao.CdCompensacaoRetroErario IS NOT NULL THEN
                
                BEGIN
                  SELECT erc.cdprocessopagretroativo
                    INTO vcdprocretroativo
                    FROM eretcompensaretroerario erc
                   WHERE erc.cdcompensaretroerario =
                         vlancrestituicao.cdcompensacaoretroerario;

                  vvlrecebidoretroativo := 0;

                  SELECT SUM(vlpagamento)
                    INTO vvlrecebidoretroativo
                    FROM epaghistoricorubricavinculo erv
                   INNER JOIN epagrubricaagrupamento eru
                      ON eru.cdrubricaagrupamento = erv.cdrubricaagrupamento
                   INNER JOIN epagrubrica epr
                      ON epr.cdrubrica = eru.cdrubrica
                     AND epr.cdtiporubrica IN (2, 4, 10, 12)
                   WHERE erv.cdfolhapagamento = pfolha.cdfolhapagamento
                     AND erv.cdvinculo = pcdvinculo
                     AND erv.cdprocessopagretroativo = vcdprocretroativo;

                  IF vvlrecebidoretroativo > 0 THEN

                    vvlabatimento := vvlrecebidoretroativo;

                  END IF;

                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    vvlrecebidoretroativo := 0;

                  WHEN OTHERS THEN

                    vvlrecebidoretroativo := 0;

                END;

              END IF;

              vvlAbatimentoPrev := 0;

            END IF;

            -- Sera retirado no futuro
            IF PKGPAG_VAR.vgCdRubricaErario = 0 THEN

              RAISE PKGPAG_VAR.eRubErarioInexistente;

            END IF;

            IF NVL(PKGPAG_VAR.vgParamPagamento.VlPercRestituicao,0) = 0 THEN

              RAISE PKGPAG_VAR.ePercErarioIncorreto;

            END IF;
            --

            vvlPagamento := 0;

            IF vLancRestituicao.FlObservaLimRetroativoErario in ('S','N') AND
               PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).CdTipoRubrica = 8 THEN

              IF vvlAbatimento > 0

                THEN

                IF (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0)) > vvlAbatimento THEN

                  vvlPagamento := vvlAbatimento;

                  vvlAbatimento := 0;

                ELSE

                  vvlPagamento := (vLancRestituicao.VlLancamentoFinanceiro -  NVL(vLancRestituicao.VlPago,0));

                  vvlAbatimento := vvlAbatimento - (vLancRestituicao.VlLancamentoFinanceiro -  NVL(vLancRestituicao.VlPago,0));

                  IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                     pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                     UPDATE EPagLancamentoFinanceiro LF
                        SET LF.DtFimDireito = pFolha.DtFimMes
                      WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                  END IF;

                END IF;

              END IF;

              -- Soma para obeter o montante total devido
              vvlTotalErario := vvlTotalErario + vLancRestituicao.VlLancamentoFinanceiro;

              -- Soma o total ja devolvido
              vvlTotalPago   := vvlTotalPago + NVL(vLancRestituicao.VlPago,0) + vvlPagamento;

              -- Soma dos valores pagos no mes
              vvlPagoNoMes   := vvlPagoNoMes + vvlPagamento;

              vVlTotalQuitado := vVlTotalQuitado + NVL(vLancRestituicao.VlPago,0);

              -- Obetem o valor a ser creditado referente a devolucao do IPREV
              vvlAbatimentoPrev := vvlAbatimentoPrev + vvlPagamento*NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0);

            ELSIF vLancRestituicao.FlObservaLimRetroativoErario IN ('S','N') AND
               PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).CdTipoRubrica = 4 AND
               PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).NuRubrica IN ( 385,915, 1328) THEN

             IF vvlAbatimentoPrev > 0 THEN

                IF (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0)) > vvlAbatimentoPrev THEN

                  vvlPagamento := vvlAbatimentoPrev;

                  vvlAbatimentoPrev := 0;

                ELSE

                  vvlPagamento := (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                  vvlAbatimentoPrev := vvlAbatimentoPrev - (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                  IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                     pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                     UPDATE EPagLancamentoFinanceiro LF
                        SET LF.DtFimDireito = pFolha.DtFimMes
                      WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                  END IF;

                END IF;

             ELSIF vLancRestituicao.CdCompensacaoRetroErario IS NOT NULL THEN

                vvlPagamento :=(vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                     pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                     UPDATE EPagLancamentoFinanceiro LF
                        SET LF.DtFimDireito = pFolha.DtFimMes
                      WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                  END IF;
              --
              -- Solicitacao de Sustentacao #72994
              -- 9431/2016 - FOLHA - PROCESSO DE RESTITUICAO AO ERARIO. INCLUIDA EXCECAO MUITO PERTO DO CALCULO
              -- ESTUDAR SITUACAO
              --
              -- SIG-443 12944/2018 - Processo ao erario paralisado
              --
              ELSIF  vvlAbatimentoPrev = 0
                AND FConsultaLancamentosPagos(vLancRestituicao.CdRubricaAgrupamento, vLancRestituicao.CdProcessoRestituicaoErario)
                THEN

                vvlPagamento :=(vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                IF vvlPagamento > PKGPAG_VAR.vgParamPagamento.VlLimitePagRetroativo AND vLancRestituicao.flobservalimite = 'S' THEN

                   vvlPagamento := PKGPAG_VAR.vgParamPagamento.VlLimitePagRetroativo;
                   
                END IF;

                IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                       UPDATE EPagLancamentoFinanceiro LF
                          SET LF.DtFimDireito = pFolha.DtFimMes
                        WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                END IF;

              ELSE
                NULL;
              END IF;

            ELSIF vLancRestituicao.FlObservaLimRetroativoErario = 'S' AND
                  PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).CdTipoRubrica = 4 AND
                  PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).NuRubrica in (983,984) THEN

              -- Se o valor do total do bloqueio mais o total pago dos retroativos for > que o
              -- montante a ser restituido
              IF (vLancRestituicao.VlLancamentoFinanceiro + vvlTotalPago) > vvlTotalErario THEN

                vvlPagamento := LEAST(vLancRestituicao.VlLancamentoFinanceiro + vvlTotalPago - vvlTotalErario, vvlPagoNoMes);

              END IF;

              -- SIG-1218 Chamado 13456/2019 - Restituição ao erario SEF
              -- Situacao que restou credito na rubrica 04-0984
              IF PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).NuRubrica = 984 AND
                 vVlTotalErario = 0 AND vVlTotalPago = 0 THEN

                 vvlPagamento := vLancRestituicao.VlLancamentoFinanceiro;

                 IF vVlPagamento > vvlAbatimento THEN
                   vvlPagamento := vvlAbatimento;
                 END IF;

              END IF;

              IF vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0) - vvlPagamento <= 0 THEN

                IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                   pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                  UPDATE EPagLancamentoFinanceiro LF
                     SET LF.DtFimDireito = pFolha.DtFimMes
                   WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                END IF;

              END IF;

            ELSE
              NULL;
            END IF;

            IF vvlPagamento > 0 THEN

              PKGPAG_LF.PGeracaoLancamentoValor(pFolha                  => pFolha,
                                                pCdVinculo              => pCdVinculo,
                                                pInPossuiValorInformado => '0',
                                                pCdRubricaAgrupamento   => vLancRestituicao.CdRubricaAgrupamento,
                                                pNuSufixoRubrica        => vLancRestituicao.NuSufixoRubrica,
                                                pVlLancamento           => vvlPagamento,
                                                pVlIndice               => (NVL(vLancRestituicao.VlLancamentoFinanceiro,0) - NVL(vLancRestituicao.VlPago,0)),
                                                pCdLancamentoFinanceiro => vLancRestituicao.CdLancamentoFinanceiro,
                                                pFlProcessoRestErario   => 'S',
                                                pCdTipoOrigemRubrica    => 11);

              IF pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                  BEGIN
                    PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => vLancRestituicao.CdLancamentoFinanceiro,
                                                        pNuAnoReferencia        => pFolha.NuAnoReferencia,
                                                        pNuMesreferencia        => pFolha.NuMesReferencia,
                                                        pNuParcela              => vLancRestituicao.qtParcelasPagas + 1,
                                                        pValorParcela           => vvlPagamento);

                EXCEPTION

                   WHEN OTHERS THEN

                     PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                                  PKGPAG_VAR.vCdHistParamCalc,
                                  PKGPAG_VAR.vCdPessoa,
                                  'Erro ao gerar parcela de erário: Código do lançamento: ' || vLancRestituicao.CdLancamentoFinanceiro,
                                   PKGPAG_VAR.vgCdVinculo);

                END;

              END IF;

            END IF;

          END LOOP;

       ELSE
         
         vCdBaseCalculo := PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubBaseIRRF).CdBaseCalculo;
         vBaseCalcIRRF := PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo);
         
         IF PKGPAG_VAR.vgVinculo.cdregimeprevidenciario = 1 THEN
           
            vCdBaseCalculo := PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubBaseINSS).CdBaseCalculo;
            
         ELSIF PKGPAG_VAR.vgVinculo.cdregimeprevidenciario = 2 THEN
           
            vCdBaseCalculo := PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubBaseIPESC).CdBaseCalculo;
            
         ELSIF PKGPAG_VAR.vgVinculo.cdregimeprevidenciario = 5 THEN
           
            vCdBaseCalculo := PKGPAG_VAR.vgRubrica(PKGPAG_VAR.vgCdRubBaseCPSM).CdBaseCalculo;
         
         ELSE
           
            vCdBaseCalculo := 0;   
            
         END IF;
            
         IF vCdBaseCalculo > 0 THEN 
           
            vBaseCalcINSS := PKGPAG_VAR.vgBaseExpr(vCdBaseCalculo);
            
         END IF;   
        
         FOR vLancRestituicao IN cLancamentoErarioObservaLimite(pCdVinculo,
                                                                pFolha,
                                                                'N') LOOP

           IF (pFlObsTributacao = 'S' AND FRubricaBaseTributacao(vLancRestituicao.CdRubricaAgrupamento) = 'S') OR
              (pFlObsTributacao = 'N' AND FRubricaBaseTributacao(vLancRestituicao.CdRubricaAgrupamento) = 'N') THEN
              
               -- Verificar se existem parcelas pagas e nao registradas na tabela EPAGPAGAMENTOLANCAMENTO
               BEGIN

                 vNuAnoMesInicioProc := vLancRestituicao.NuAnoInicioRestituicao || lpad(vLancRestituicao.NuMesInicioRestituicao,2,0);

                 IF  vNuAnoMesInicioProc < TO_CHAR(pFolha.DtInicioMes,'yyyymm')
                     AND TRUNC(vLancRestituicao.DtAtivacaoProcesso)  < TRUNC(pFolha.DtInicioMes)
                     THEN

                   pajustaparcelanaocomputadaERA(vLancRestituicao.cdprocessorestituicaoerario,
                                                 vLancRestituicao.cdlancamentofinanceiro,
                                                 pCdVinculo);
                   -- Atualizar total pago e numero de parcelas
                   BEGIN
                     
                     CASE
                       
                       WHEN pFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoRecalculoMes THEN

                          SELECT  NVL(sum(pag.vlparcela),0), NVL(max(pag.nuparcela),0)
                            INTO vLancRestituicao.vlpago, vLancRestituicao.qtparcelaspagas
                            FROM epagpagamentolancamento pag
                           WHERE pag.cdlancamentofinanceiro = vLancRestituicao.cdlancamentofinanceiro
                             AND pag.nuanoreferencia || lpad(pag.numesreferencia,2,0) <
                                 pFolha.NuAnoReferencia || lpad(pFolha.NuMesReferencia,2,0);

                        ELSE

                          SELECT  NVL(sum(pag.vlparcela),0), NVL(max(pag.nuparcela),0)
                            INTO vLancRestituicao.vlpago, vLancRestituicao.qtparcelaspagas
                            FROM epagpagamentolancamento pag
                           WHERE pag.cdlancamentofinanceiro = vLancRestituicao.cdlancamentofinanceiro;

                        END CASE;

                      EXCEPTION
                        
                       WHEN OTHERS THEN
                         
                         NULL;
                   END;

                 END IF;

               EXCEPTION
                 WHEN OTHERS THEN
                   NULL;
               END;

               IF bPrimeiraVez THEN

                 bPrimeiraVez := FALSE;

                 IF PKGPAG_GERAL.FretornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                      pCdVinculo        => pCdVinculo,
                                                      pCdRubrica        => PKGPAG_VAR.vgCdRubricaErario) = 0 THEN
                                                      
                   -- Insere e calcula a base do erario no vinculo
                   PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                         pCdVinculo            => pCdVinculo,
                                                         pCdExpressaoFormCalc  => NULL,
                                                         pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubricaErario,
                                                         pNuSufixoRubrica      => 1,
                                                         pVlPagamento          => 0,
                                                         pVlIndice             => NULL,
                                                         pCdTipoOrigemRubrica  => 11);

                   -- Recalcula a base do erario no vinculo
                   PKGPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                    pCdVinculo       => pCdVinculo,
                                                    pCdRubrica       => PKGPAG_VAR.vgCdRubricaErario,
                                                    pTpProcessamento => 2,
                                                    pTpLocal         => 2);
                                                    
                 END IF;                            
                        
                 /* Retornam os valores da base de restituicao do erario e
                    a base do IPESC para os lancamentos com e sem limite de valor
                    respectivamente */

                 /* Para processos que nao observam o limite, o valor do abatimento e o valor
                    total da base do erario. */

                 IF vLancRestituicao.flobservalimite = 'N' OR 
                   ((vLancRestituicao.cdtiporubrica = 8 AND vLancRestituicao.nurubrica = 44) AND PKGPAG_VAR.vgAfastDefinitivo.count > 0) THEN
                   
                    vvlAbatimento := FRetornaValorMargem(pFolha.CdFolhaPagamento,
                                                        pFolha.CdTipoFolha,
                                                        pCdVinculo,
                                                        PKGPAG_VAR.vgCdRubricaErario,
                                                        vLancRestituicao.vllimitepercentualmensal,
                                                        vLancRestituicao.flobservalimite);

                 ELSE
                   
                    vvlAbatimento := FRetornaValorMargem(pFolha.CdFolhaPagamento,
                                                        pFolha.CdTipoFolha,
                                                        pCdVinculo,
                                                        PKGPAG_VAR.vgCdRubricaErario,
                                                        vLancRestituicao.vllimitepercentualmensal,
                                                        vLancRestituicao.FlObservaLimRetroativoErario);
                 END IF;

                 --
                 -- Solicitacao de Sustentacao #76134
                 -- SIGRH - [Chamado 10392/2017] - FOLHA - PROCESSOS DE COMPENSACAO
                 -- Se tem processo de compensacao, considerar o limite igual ao recebido no retroativo
                 --
                 IF vLancRestituicao.CdCompensacaoRetroErario IS NOT NULL THEN
                   
                   BEGIN
                     SELECT erc.cdprocessopagretroativo
                       INTO vcdprocretroativo
                       FROM eretcompensaretroerario erc
                      WHERE erc.cdcompensaretroerario =
                            vlancrestituicao.cdcompensacaoretroerario;

                     vvlrecebidoretroativo := 0;

                     SELECT SUM(vlpagamento)
                       INTO vvlrecebidoretroativo
                       FROM epaghistoricorubricavinculo erv
                      INNER JOIN epagrubricaagrupamento eru
                         ON eru.cdrubricaagrupamento = erv.cdrubricaagrupamento
                      INNER JOIN epagrubrica epr
                         ON epr.cdrubrica = eru.cdrubrica
                        AND epr.cdtiporubrica IN (2, 4, 10, 12)
                      WHERE erv.cdfolhapagamento = pfolha.cdfolhapagamento
                        AND erv.cdvinculo = pcdvinculo
                        AND erv.cdprocessopagretroativo = vcdprocretroativo;

                     IF vvlrecebidoretroativo > 0 THEN

                       vvlabatimento := vvlrecebidoretroativo;

                     END IF;

                   EXCEPTION
                     
                     WHEN NO_DATA_FOUND THEN
                       
                       vvlrecebidoretroativo := 0;

                     WHEN OTHERS THEN

                       vvlrecebidoretroativo := 0;

                   END;

                 END IF;

                 vvlAbatimentoPrev := 0;

               END IF;

               -- Sera retirado no futuro
               IF PKGPAG_VAR.vgCdRubricaErario = 0 THEN

                 RAISE PKGPAG_VAR.eRubErarioInexistente;

               END IF;

               IF NVL(PKGPAG_VAR.vgParamPagamento.VlPercRestituicao,0) = 0 THEN

                 RAISE PKGPAG_VAR.ePercErarioIncorreto;

               END IF;
               --

               vvlPagamento := 0;

               IF vLancRestituicao.FlObservaLimRetroativoErario in ('S','N') AND
                  PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).CdTipoRubrica = 8 THEN

                 IF vvlAbatimento > 0 THEN

                   IF (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0)) > vvlAbatimento THEN

                     vvlPagamento := vvlAbatimento;

                     vvlAbatimento := 0;

                   ELSE

                     vvlPagamento := (vLancRestituicao.VlLancamentoFinanceiro -  NVL(vLancRestituicao.VlPago,0));

                     vvlAbatimento := vvlAbatimento - (vLancRestituicao.VlLancamentoFinanceiro -  NVL(vLancRestituicao.VlPago,0));

                     IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                        pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                        UPDATE EPagLancamentoFinanceiro LF
                           SET LF.DtFimDireito = pFolha.DtFimMes
                         WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                     END IF;

                   END IF;

                 END IF;

                 -- Soma para obeter o montante total devido
                 vvlTotalErario := vvlTotalErario + vLancRestituicao.VlLancamentoFinanceiro;

                 -- Soma o total ja devolvido
                 vvlTotalPago   := vvlTotalPago + NVL(vLancRestituicao.VlPago,0) + vvlPagamento;

                 -- Soma dos valores pagos no mes
                 vvlPagoNoMes   := vvlPagoNoMes + vvlPagamento;

                 vVlTotalQuitado := vVlTotalQuitado + NVL(vLancRestituicao.VlPago,0);

                 -- Obetem o valor a ser creditado referente a devolucao do IPREV
                 vvlAbatimentoPrev := vvlAbatimentoPrev + vvlPagamento*NVL(PKGPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica/100,0);


               ELSIF vLancRestituicao.FlObservaLimRetroativoErario IN ('S','N') AND
                  PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).CdTipoRubrica = 4 AND
                  PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).NuRubrica IN ( 385,915, 1328, 3329) THEN

                IF vvlAbatimentoPrev > 0 THEN

                   IF (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0)) > vvlAbatimentoPrev THEN

                     vvlPagamento := vvlAbatimentoPrev;

                     vvlAbatimentoPrev := 0;

                   ELSE

                     vvlPagamento := (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                     vvlAbatimentoPrev := vvlAbatimentoPrev - (vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                     IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                        UPDATE EPagLancamentoFinanceiro LF
                           SET LF.DtFimDireito = pFolha.DtFimMes
                         WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                     END IF;

                   END IF;

                ELSIF vLancRestituicao.CdCompensacaoRetroErario IS NOT NULL THEN

                   vvlPagamento :=(vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                   IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                        UPDATE EPagLancamentoFinanceiro LF
                           SET LF.DtFimDireito = pFolha.DtFimMes
                         WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                     END IF;
                 --
                 -- Solicitacao de Sustentacao #72994
                 -- 9431/2016 - FOLHA - PROCESSO DE RESTITUICAO AO ERARIO. INCLUIDA EXCECAO MUITO PERTO DO CALCULO
                 -- ESTUDAR SITUACAO
                 --
                 -- SIG-443 12944/2018 - Processo ao erario paralisado
                 --
                 ELSIF vvlAbatimentoPrev = 0  THEN

                   vvlPagamento :=(vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0));

                   IF vvlPagamento > PKGPAG_VAR.vgParamPagamento.VlLimitePagRetroativo
                     AND vLancRestituicao.flobservalimite = 'S' THEN

                      vvlPagamento := PKGPAG_VAR.vgParamPagamento.VlLimitePagRetroativo;
                   END IF;

                   IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                          pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                          UPDATE EPagLancamentoFinanceiro LF
                             SET LF.DtFimDireito = pFolha.DtFimMes
                           WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                   END IF;

                   IF vLancRestituicao.cdTipoRubrica = 4 AND
                      vLancRestituicao. NuRubrica IN (1328) THEN

                      vvlAbatimento := vvlAbatimento + vvlPagamento;
                   END IF;

                 ELSE
                   NULL;
                 END IF;

               ELSIF vLancRestituicao.FlObservaLimRetroativoErario IN ('S') AND
                     PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).CdTipoRubrica = 4 AND
                     PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).NuRubrica in (983,984) THEN

                 -- Se o valor do total do bloqueio mais o total pago dos retroativos for > que o
                 -- montante a ser restituido
                 IF (vLancRestituicao.VlLancamentoFinanceiro + vvlTotalPago) > vvlTotalErario THEN

                   vvlPagamento := LEAST(vLancRestituicao.VlLancamentoFinanceiro + vvlTotalPago - vvlTotalErario, vvlPagoNoMes);

                 END IF;

                 -- SIG-1218 Chamado 13456/2019 - Restituição ao erario SEF
                 -- Situacao que restou credito na rubrica 04-0984
                 IF PKGPAG_VAR.vgRubrica(vLancRestituicao.CdRubricaAgrupamento).NuRubrica = 984 AND
                    vVlTotalErario = 0 AND vVlTotalPago = 0 THEN

                    vvlPagamento := vLancRestituicao.VlLancamentoFinanceiro;

                    IF vVlPagamento > vvlAbatimento THEN
                      vvlPagamento := vvlAbatimento;
                    END IF;

                 END IF;

                 IF vLancRestituicao.VlLancamentoFinanceiro - NVL(vLancRestituicao.VlPago,0) - vvlPagamento <= 0 THEN

                   IF PKGPAG_VAR.vgFolha.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                     UPDATE EPagLancamentoFinanceiro LF
                        SET LF.DtFimDireito = pFolha.DtFimMes
                      WHERE LF.CdLancamentoFinanceiro = vLancRestituicao.CdLancamentoFinanceiro;

                   END IF;

                 END IF;

               ELSE
                 NULL;
               END IF;

               IF vvlPagamento > 0 THEN

                 PKGPAG_LF.PGeracaoLancamentoValor(pFolha                  => pFolha,
                                                   pCdVinculo              => pCdVinculo,
                                                   pInPossuiValorInformado => '0',
                                                   pCdRubricaAgrupamento   => vLancRestituicao.CdRubricaAgrupamento,
                                                   pNuSufixoRubrica        => vLancRestituicao.NuSufixoRubrica,
                                                   pVlLancamento           => vvlPagamento,
                                                   pVlIndice               => (NVL(vLancRestituicao.VlLancamentoFinanceiro,0) - NVL(vLancRestituicao.VlPago,0)),
                                                   pCdLancamentoFinanceiro => vLancRestituicao.CdLancamentoFinanceiro,
                                                   pFlProcessoRestErario   => 'S',
                                                   pCdTipoOrigemRubrica    => 11);

                 IF pFlCalculoDefinitivo = PKGPAG_TIPO.cnS THEN

                   BEGIN
                     
                     PKGPAG_LF.PRegistarPagamentoParcela(pCdLancamentoFinanceiro => vLancRestituicao.CdLancamentoFinanceiro,
                                                         pNuAnoReferencia        => pFolha.NuAnoReferencia,
                                                         pNuMesreferencia        => pFolha.NuMesReferencia,
                                                         pNuParcela              => vLancRestituicao.qtParcelasPagas + 1,
                                                         pValorParcela           => vvlPagamento);

                   EXCEPTION

                      WHEN OTHERS THEN

                        PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                                     PKGPAG_VAR.vCdHistParamCalc,
                                     PKGPAG_VAR.vCdPessoa,
                                     'Erro ao gerar parcela de erário: Código do lançamento: ' || vLancRestituicao.CdLancamentoFinanceiro,
                                      PKGPAG_VAR.vgCdVinculo);

                   END;

                 END IF;

               END IF;
               
           END IF; 
            
       END LOOP;
       
       END IF;
       
       PKGPAG_VAR.vgVlTotalDescErarioMes := vVlPagoNoMes;

       IF vVlTotalErario - (vVlPagoNoMes + vVlTotalQuitado) > 0 AND
          PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 9, 9001) > 0 THEN

          -- Insere 09-9001 SALDO DE ERARIO NAO DESCONTADO
          PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 9, 9001),
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => vVlTotalErario - (vVlPagoNoMes + vVlTotalQuitado),
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 11);

       END IF;

     END IF;

   EXCEPTION

     WHEN PKGPAG_VAR.ePercErarioIncorreto THEN

       PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Percentual limite para restituição do erário não definido. Cálculo do erário não realizado.',
                                PKGPAG_VAR.vgCdVinculo);

     WHEN PKGPAG_VAR.eRubErarioInexistente THEN

       PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Rubrica de devolução do erário inexistente. Cálculo interrompido.',
                               PKGPAG_VAR.vgCdVinculo);

     WHEN OTHERS THEN

       PKGPAG_GERAL.pInsereLog(PKGPAG_VAR.bLog,
                               PKGPAG_VAR.vCdHistParamCalc,
                               PKGPAG_VAR.vCdPessoa,
                               'Erro ao calcular erário.',
                               PKGPAG_VAR.vgCdVinculo);

   END;

END PKGPAG_RE;
/
