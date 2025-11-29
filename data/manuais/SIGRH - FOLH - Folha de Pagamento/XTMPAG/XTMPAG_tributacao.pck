CREATE OR REPLACE PACKAGE XTMPAG_TRIBUTACAO IS

  --------------------------------------------------------------------------------
  -- Variaveis que identificam as insencoes do vinculo
  ---------------------------------------------------------------------------------

  bDescRubIsentaINSS BOOLEAN;

  bDescRubIsentaIRRF BOOLEAN;

  bDescRubIsentaIPREV BOOLEAN;

  bDescRubIsentaFormula BOOLEAN;

  bDescRubIsentaDescIRRF BOOLEAN;
  
  bIsencaoPercialIPREV BOOLEAN; -- Varável utilizada para indicar se o servidor possui descisão judicial da rubrica 05-0924

  ---
  -- Variavel para controle das rubricas de consignacao
  ---

  vListaRubConsig VARCHAR2(600);


  TYPE rAdesaoDescSimplificado IS RECORD (
    CdAgrupamento  INTEGER,
    NuAnoMesAdesao INTEGER
  );

  TYPE tblAdesaoDescSimplificado IS TABLE OF rAdesaoDescSimplificado INDEX BY PLS_INTEGER;

  -----------------------------------------------------------------------------------------
  --  Procedure  : PAssociaRubricaPensao
  --
  --    Objetivo :
  --
  -----------------------------------------------------------------------------------------

  PROCEDURE PAssociaRubricaPensao(pCdVinculo        IN INTEGER,
                                  pFolha            IN XTMPAG_TIPO.rFolha,
                                  pFlAdiant13Pensao IN CHAR DEFAULT 'N',
                                  pFlPensao13       IN CHAR DEFAULT 'N');

  -----------------------------------------------------------------------------------------
  --  Procedure  : PProcessaTributacao
  --
  --    Objetivo : Realizar a tributacao a ser paga pelo vinculo que esta processado. As
  --             tributacoes envolvidas sao a de INSS, IRRF (RRA) e IPREV/IPESC
  --
  -----------------------------------------------------------------------------------------

  PROCEDURE PProcessaTributacaoEPensao(pFolha          IN XTMPAG_TIPO.rFolha,
                                       pCdPessoa       IN INTEGER,
                                       pCdVinculo      IN INTEGER,
                                       pParamPagamento IN ePagAgrupamentoParametro%ROWTYPE,
                                       pDtInicioMes    IN DATE,
                                       pDtFimMes       IN DATE,
                                       pTpCalculo      IN INTEGER DEFAULT 1,
                                       pbPrima         IN BOOLEAN DEFAULT FALSE);

  FUNCTION FRetornaAliquotaIPESC(pCdTpTributacaoIPESC IN INTEGER,
                                 pNuAnoReferencia     IN INTEGER,
                                 pNuMesReferencia     IN INTEGER)
    RETURN XTMPAG_TIPO.rAliquotaIPESC;

  FUNCTION FRetornaAliquotaCPSM(pCdTpTributacaoCPSM IN INTEGER,
                                pNuAnoReferencia    IN INTEGER,
                                pNuMesReferencia    IN INTEGER)
    RETURN XTMPAG_TIPO.rAliquotaCPSM;

  FUNCTION FRetornaRegimeProprioPrev(pCdVinculo IN INTEGER) RETURN INTEGER;

  -- 23654/2025 - GEREF - TRIBUTACAO IRRF SERVIDOR RESIDENTE NO EXTERIOR
  FUNCTION FRetornaAliquotaIRRFExterior(pNuAnoReferencia IN INTEGER,
                                        pNuMesReferencia IN INTEGER,
                                        pCdTipoAliquota  IN INTEGER DEFAULT 1)
    RETURN XTMPAG_TIPO.rAliquotaIRRF;

  FUNCTION FRetornaAliquotaIRRF(pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER,
                                pCdTipoAliquota  IN INTEGER DEFAULT 1)
    RETURN XTMPAG_TIPO.rAliquotaIRRF;

  FUNCTION FRetornaAliquotaINSS(pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER)
    RETURN XTMPAG_TIPO.rAliquotaINSS;

  FUNCTION FNumeroDependentes(pCdPessoa    IN INTEGER,
                              pCdVinculo   IN INTEGER,
                              pDtInicioMes IN DATE,
                              pDtFimMes    IN DATE) RETURN INTEGER;

  FUNCTION FAplicaDeducaoInativo(pCdPessoa    IN INTEGER,
                                 pDtInicioMes IN DATE,
                                 pDtFimMes    IN DATE) RETURN BOOLEAN;

  /*----------------------------------------------------------------------------
       Funcao: FRetornaRubricaAgrup
     Objetivo: Retorna o codigo da rubrica vigente no agrupamento, com base nos
               parametros informados.

   Argumentos: pCdAgrupamento   - Codigo do agrupamento
               pNuAnoReferencia - Ano de referencia
               pNuMesReferencia - Mes de referencia
               pTipoRubrica     - Codigo do tipo de rubrica

         Nota: Caso nao seja encontrada a rubrica, ou exista mais de uma
               rubrica que atenda aos parametros informados e retornado o
               valor '0'
  /-----------------------------------------------------------------------------*/

  FUNCTION FRetornaRubricaAgrup(pCdAgrupamento   IN INTEGER,
                                pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER,
                                pCdRubrica       IN INTEGER,
                                pCdTipoRubrica   IN INTEGER) RETURN INTEGER;

  FUNCTION FIsentoIRRF(pCdVinculo IN INTEGER, pFolha IN XTMPAG_TIPO.rFolha)
    RETURN BOOLEAN;

  PROCEDURE PSetaRurbicasIsentas(pFolha     IN XTMPAG_TIPO.rFolha,
                                 pCdVinculo IN INTEGER);

  PROCEDURE PExcluirRubricaDoContraCheque(pCdVinculo            IN INTEGER,
                                          pCdFolhaPagamento     IN INTEGER,
                                          pCdRubricaAgrupamento IN INTEGER);

  PROCEDURE PAtualizarValorPgtoRubrica(pCdVinculo            IN INTEGER,
                                       pCdFolhaPagamento     IN INTEGER,
                                       pCdRubricaAgrupamento IN INTEGER,
                                       pValorPagamento       IN NUMBER);

  PROCEDURE PProcessarRubricaSCPREV13(pFolha                         IN XTMPAG_TIPO.rFolha,
                                      pFormExpr                      IN XTMPAG_TIPO.tFormulaCalculo,
                                      pCdVinculo                     IN INTEGER,
                                      pCdFolhaPagamento              IN INTEGER,
                                      pCdAgrupamento                 IN INTEGER,
                                      pCdTipoRubrica                 IN INTEGER,
                                      pNuRubrica                     IN INTEGER,
                                      pTpProcessamento               IN INTEGER,
                                      pValorIndiceRubrica            IN NUMBER,
                                      pValorMinimoContribuicaoSCPREV IN NUMBER,
                                      pCdTipoOrigemRubrica           IN INTEGER DEFAULT 1);

  FUNCTION FObterValorIndiceRubrica(pCdVinculo     IN INTEGER,
                                    pCdRubrica     IN INTEGER,
                                    pDataInicioMes IN DATE,
                                    pDataFimMes    IN DATE,
                                    pFlAnulado     IN CHAR) RETURN NUMBER;

  PROCEDURE PProcessarBase13SCPrev(pCdRegimeProprioPrev           IN INTEGER,
                                   pFolha                         IN XTMPAG_TIPO.rFolha,
                                   pFormExpr                      IN XTMPAG_TIPO.tFormulaCalculo,
                                   pCdVinculo                     IN INTEGER,
                                   pCdFolhaPagamento              IN INTEGER,
                                   pCdAgrupamento                 IN INTEGER,
                                   pValorMinimoContribuicaoSCPREV IN NUMBER,
                                   pValorTetoINSS                 IN NUMBER,
                                   pValorRubrica9_920             IN NUMBER);

  PROCEDURE PAtualizarDeducoesLegaisIRRF(pfolha      IN XTMPAG_tipo.rfolha,
                                         pCdVinculo  IN INTEGER,
                                         pCdRubBase    IN INTEGER,
                                         pTpTributacao IN INTEGER DEFAULT 2,
                                         pIndProcRetro IN INTEGER DEFAULT NULL);

  PROCEDURE PInserirDescDependentesIRRF(pfolha      IN XTMPAG_tipo.rfolha,
                                        pCdVinculo  IN INTEGER);

  PROCEDURE PExcluirRubricaDescDepIRRF(pCdFolhaPagamento IN INTEGER,
                                       pCdVinculo        IN INTEGER,
                                       pValorBaseIRRF    IN NUMBER,
                                       pValorBaseIRRF13  IN NUMBER);

  PROCEDURE PReprocessarFormulaRubrica(pFolha                IN XTMPAG_tipo.rfolha,
                                       pCdVinculo            IN INTEGER,
                                       pCdRubricaAgrupamento IN INTEGER,
                                       pTpTributacao         IN INTEGER DEFAULT 2,
                                       pIndProcRetro         IN INTEGER DEFAULT NULL);

  PROCEDURE PAjustaIPREV(pFolha     IN XTMPAG_TIPO.rFolha,
                         pCdVinculo IN Ecadvinculo.Cdvinculo%TYPE,
                         pCdRubricaGerada IN Epagrubricaagrupamento.Cdrubricaagrupamento%TYPE);

  FUNCTION fFolha13MesAnt (pCdFolhaNormalAnt IN INTEGER) RETURN INTEGER;

  FUNCTION FObterInfoAdesaoDescSimp RETURN tblAdesaoDescSimplificado;

  FUNCTION FAgrupUtilizaDescSimp(pCdAgrupamento IN INTEGER,
                                 pNuAnoMesFolha IN INTEGER) RETURN BOOLEAN;

END XTMPAG_TRIBUTACAO;
/
CREATE OR REPLACE PACKAGE BODY XTMPAG_TRIBUTACAO IS

  vPassagens INTEGER DEFAULT 0;

  vvlDeducaoInativoReal NUMBER(13, 2);

  vControlaMsg BOOLEAN := FALSE;

  vCdEventoVinculo integer;

  bPossuiOutroVinculo boolean := false;

  vVlRecolhimentoAvulso number(15, 2);

  vVlBaseRecolhimentoAvulso number(15, 2);

  bReprocessaPensao boolean := false;

  TYPE rBaseConsignacao IS RECORD(
    CdBase   INTEGER,
    NuSufixo INTEGER,
    VlIndice NUMBER(13, 2),
    VlMensal NUMBER(13, 2));

  TYPE tblBaseConsignacao IS TABLE OF rBaseConsignacao INDEX BY PLS_INTEGER;

  FUNCTION FPossuiRUB(pCdExpressaoFormCalc IN INTEGER)

   RETURN BOOLEAN IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF XTMPAG_VAR.vgFormExpr.COUNT > 0 THEN

      IF XTMPAG_VAR.vgFormExpr.EXISTS(pCdExpressaoFormCalc) THEN

        FOR i IN XTMPAG_VAR.vgFormExpr(pCdExpressaoFormCalc).lBloco.FIRST .. XTMPAG_VAR.vgFormExpr(pCdExpressaoFormCalc).lBloco.LAST LOOP

          FOR j IN XTMPAG_VAR.vgFormExpr(pCdExpressaoFormCalc).lBloco(i).lExpressao.FIRST .. XTMPAG_VAR.vgFormExpr(pCdExpressaoFormCalc).lBloco(i).lExpressao.LAST LOOP

            IF XTMPAG_VAR.vgFormExpr(pCdExpressaoFormCalc).lBloco(i).lExpressao(j).CdTipoMneumonico = 4 THEN

              RETURN TRUE;

            END IF;

          END LOOP;

        END LOOP;

      END IF;

    END IF;

    RETURN FALSE;

  END;

  /*-----------------------------------------------------------------------------------------/
     Objetivo: Retorna o numero de dependentes que nao possuem
               registro de obito e finaliza as dependencias de
               imposto de Renda

  /*-----------------------------------------------------------------------------------------*/
  FUNCTION FNumeroDependentes(pCdPessoa    IN INTEGER,
                              pCdVinculo   IN INTEGER,
                              pDtInicioMes IN DATE,
                              pDtFimMes    IN DATE) RETURN INTEGER IS

    vCont         INTEGER DEFAULT 0;
    vCdDependente INTEGER DEFAULT 0;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    FOR vDependente IN (SELECT DI.CdDependenteVinculoIRRF,
                               D.CdDependente,
                               D.NmDependente,
                               DtNascimento,
                               DI.DtFimDependencia,
                               DI.FlEstudante,
                               D.FlInvalidez,
                               GP.FlFinalizaDependenciaIRRF,
                               GP.FlPensaoVitalicia
                          FROM ECadDependenteVinculo DV
                         INNER JOIN ECadDependenteVinculoIRRF DI
                            ON DV.CdDependenteVinculo =
                               DI.CdDependenteVinculo
                         INNER JOIN ECadPessoaDependente PD
                            ON PD.CdDependente = DV.CdDependente
                         INNER JOIN ECadDependente D
                            ON D.CdDependente = PD.CdDependente
                         INNER JOIN ECadGrauParentescoprevfin GP
                            ON GP.CdGrauParentescoPrevFin =
                               PD.CdGrauParentescoPrevFin

                         INNER JOIN ECadVinculo V
                            ON V.CdVinculo = dv.CdVinculo

                         WHERE PD.CdResponsavel = pCdPessoa
                           AND DI.DtInicioDependencia <= pDtFimMes
                           AND (DI.DtFimdependencia >= pDtInicioMes OR
                               DI.DtFimDependencia IS NULL)
                           AND V.Cdvinculo = pCdVinculo
                           AND V.CdPessoa = PD.CdResponsavel
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM EAfaRegistroObito RO
                                 WHERE RO.CdDependente = DV.CdDependente
                                   AND RO.FlAnulado = XTMPAG_TIPO.cnN)
                           AND EXISTS
                         (SELECT 1
                                  FROM ecadvinculo v
                                 INNER JOIN ecadorgao o
                                    ON v.cdorgao = o.cdorgao
                                 WHERE v.cdvinculo = DV.CdVinculo
                                   AND (v.dtDesligamento >= pDtInicioMes OR
                                       v.dtdesligamento IS NULL)
                                   AND o.cdagrupamento =
                                       XTMPAG_VAR.vgFolha.CdAgrupamento)

                         ORDER BY D.CdDependente

                        )

     LOOP

      IF vCdDependente <> vDependente.Cddependente THEN
        vCont         := vCont + 1;
        vCdDependente := vDependente.Cddependente;
      END IF;

      IF vDependente.FlInvalidez = 'N' THEN

        IF vDependente.FlFinalizaDependenciaIRRF = 'S' AND
           vDependente.FlPensaoVitalicia = 'N' AND
           ((MONTHS_BETWEEN(pDtFimMes, vDependente.DtNascimento) > 21 * 12 AND -- 21 anos NAO estudante
           vDependente.FlEstudante = 'N') OR
           ((MONTHS_BETWEEN(pDtFimMes, vDependente.DtNascimento) > 25 * 12 AND -- 25 anos estudante
           vDependente.FlEstudante = 'S'))) AND
           vDependente.DtFimDependencia IS NULL THEN

          UPDATE ECadDependenteVinculoIRRF DV
             SET DV.DtFimDependencia = pDtFimMes,
                 DV.DtUltAlteracao   = SYSTIMESTAMP
           WHERE DV.CdDependenteVinculoIRRF =
                 vDependente.CdDependenteVinculoIRRF;

          XTMPAG_GERAL.PInsereLog(pInsere                  => XTMPAG_VAR.bLog,
                                  pCdHistoricoParamCalculo => XTMPAG_VAR.vCdHistParamCalc,
                                  pCdPessoa                => XTMPAG_VAR.vCdPessoa,
                                  pDeLog                   => 'Finalização de dependência de IRRF : ' ||
                                                              vDependente.NmDependente,
                                  pCdVinculo               => XTMPAG_VAR.vgVinculo.CdVinculo,
                                  pCdTipoOcorrencia        => 2, -- Ocorrencia
                                  pCdMotivoOcorrencia      => 7); -- Finalizacao de dependencia de IRRF

        END IF;

      END IF;

    END LOOP;

    RETURN vCont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FDuploVinculoVigente(pCdPessoa IN INTEGER, pDtInicioMes IN DATE)
    RETURN INTEGER IS

    vcont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT COUNT(*)
      INTO vcont
      FROM ecadvinculo v
     inner join ecadhistorgao ho
        on v.cdorgao = ho.cdorgao
       and ho.dtfimvigencia is null
       and --  ho.CdTipoOrgao not in (1,5)
           XTMPAG_var.vgvinculo.cdregimeprevidenciario = 1
     WHERE CdPessoa = pCdPessoa
       AND (DtDesligamento IS NULL OR DtDesligamento >= pDtInicioMes);

    RETURN vcont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FDuploVinculoVigenteOutroAgrup(pCdPessoa      IN INTEGER,
                                          pCdAgrupamento IN INTEGER)
    RETURN INTEGER IS

    vcont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT COUNT(*)
      INTO vcont
      FROM ecadvinculo v
     inner join ecadhistorgao ho
        on v.cdorgao = ho.cdorgao
       and ho.dtfimvigencia is null
       and v.cdregimeprevidenciario = 1 ------SIG 9978
       and ho.cdagrupamento <> pCdAgrupamento
     WHERE CdPessoa = pCdPessoa
       AND (DtDesligamento IS NULL OR
           DtDesligamento >= XTMPAG_var.vgFolha.dtcalculoant);

    RETURN vcont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FDuploVinculoVigenteAno(pCdVinculo in integer)

   RETURN boolean is

    vCont integer := 0;

  begin
    -- xtmpag_util.pGravaLogCallStack;

    SELECT count(v.cdpessoa)
      INTO vCont
      FROM epaghistoricorubricavinculo rv
     INNER JOIN ecadvinculo v
        ON v.cdvinculo = rv.cdvinculo
       AND v.cdvinculo <> pcdvinculo
     INNER JOIN epagfolhapagamento fp
        ON fp.cdfolhapagamento = rv.cdfolhapagamento
       AND fp.nuanoreferencia = XTMPAG_var.vgFolha.NuAnoReferencia
       AND fp.flcalculodefinitivo = 'S'
     WHERE v.cdpessoa = XTMPAG_var.vgVinculo.cdpessoa
       AND rv.cdrubricaagrupamento = XTMPAG_var.vgCdRubBaseINSS13;

    if nvl(vCont, 0) > 0 then

      return true;

    else

      return false;

    end if;

  exception
    when no_data_found then
      return false;

    when others then
      return false;

  end;

  FUNCTION FDuploVinculoVigenteEmp(pCdPessoa    IN INTEGER,
                                   pDtInicioMes IN DATE) RETURN boolean is

    vcont         INTEGER;
    vefetivo      integer;
    vcomissionado integer;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCont         := 0;
    vEfetivo      := 0;
    vComissionado := 0;

    for vinc in (SELECT *
                   FROM ecadvinculo v
                  WHERE CdPessoa = pCdPessoa
                    AND (DtDesligamento IS NULL OR
                        DtDesligamento >= pDtInicioMes)
                    and v.cdorgao = XTMPAG_var.vgFolha.cdorgao)

     loop
      -- Efetivo
      if vEfetivo = 0 then

        begin
          select count(*)
            into vEfetivo
            from ecadhistcargoefetivo cef
           where cef.cdvinculo = vinc.cdvinculo
             and cef.cdrelacaotrabalho = 5
             and cef.flanulado = 'N';
        exception
          when others then
            vEfetivo := 0;
        end;

      end if;

      -- Comissionado
      if vComissionado = 0 then

        begin
          select count(*)
            into vcomissionado
            from ecadhistcargocom com
           where com.cdvinculo = vinc.cdvinculo
             and com.cdrelacaotrabalho = 15
             and com.flanulado = 'N';
        exception
          when others then
            vcomissionado := 0;
        end;

      end if;

    end loop;

    if vEfetivo + vcomissionado >= 1
        then

      if XTMPAG_var.vgCalculo.FlGeral <> 'I' then

        begin
          INSERT INTO tmppagcalculocoletivo
            SELECT XTMPAG_var.vgFolha.CdFolhapagamento,
                   v.CdVinculo,
                   to_char(SYSDATE, 'ddmmyyhh24mi'),
                   'J',
                   XTMPAG_var.vgfolha.cdagrupamento,
                   SYSDATE
              FROM ecadvinculo v
             WHERE CdPessoa = pCdPessoa
               AND (DtDesligamento IS NULL OR
                   DtDesligamento >= pDtInicioMes)
               and v.cdorgao = XTMPAG_var.vgFolha.cdorgao
               and not exists (select 1
                      from tmppagcalculocoletivo t
                     where t.cdfolhapagamento =
                           XTMPAG_var.vgFolha.CdFolhapagamento
                       and t.cdvinculo = v.cdvinculo
                       and t.flcalculado = 'J');

        exception
          when others then
            null;

        end;

      end if;

    else

      return false;

    end if;

    return true;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN false;

  END;

  /*-----------------------------------------------------------------------------------------/
       Objetivo: Retorna o numero de vinculos vigentes, ou com pagamento
  /*-----------------------------------------------------------------------------------------*/
  FUNCTION FVinculosVigentes(pCdPessoa in integer) RETURN INTEGER IS

    vCont INTEGER DEFAULT 0;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    with fol AS
     (SELECT f.cdfolhapagamento
        FROM EPAGFOLHAPAGAMENTO F
       INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
          ON F.CDTIPOFOLHAPAGAMENTO = TF.CDTIPOFOLHAPAGAMENTO
       inner join ecadhistorgao ho
          on f.cdorgao = ho.cdorgao
         and ho.dtfimvigencia is null
         and ho.cdtipoorgao not in (1, 5)
       INNER JOIN EPAGTIPOFOLHA TP
          ON TP.CDTIPOFOLHA = TF.CDTIPOFOLHA
         AND TF.CDTIPOFOLHA IN
             (XTMPAG_TIPO.CNTPFOLHANORMAL, XTMPAG_tipo.cnTpFolhaResidente,XTMPAG_TIPO.cnTpFolhaConvenio )
         AND F.CDTIPOCALCULO IN
             (XTMPAG_TIPO.CNTPCALCULONORMAL,
              XTMPAG_TIPO.CNTPCALCULOSUPL,
              XTMPAG_TIPO.cnTpCalculoAnterior)
         AND F.NUANOMESREFERENCIA =
             to_number(TO_CHAR(XTMPAG_var.vgFolha.dtcalculo, 'YYYYMM'))),
    rub as
     (SELECT r.cdrubricaagrupamento
        FROM VPAGRUBRICAAGRUPAMENTO R
       WHERE R.NURUBRICA IN (903)
         AND R.CDTIPORUBRICA = 9)
    select count(distinct v.cdvinculo)
      into vCont
      from epaghistoricorubricavinculo hv
     inner join fol fp
        on fp.cdfolhapagamento = hv.cdfolhapagamento
     inner join ECadVinculo V
        ON V.CdVinculo = hv.CdVinculo
       and v.cdregimeprevidenciario = 1
     inner join rub r
        on r.cdrubricaagrupamento = hv.cdrubricaagrupamento
     where V.CdPessoa = pCdPessoa
       and not exists
     (SELECT 1
              FROM eTrbRecolhimentoAvulso T
             WHERE T.CdPessoa = pCdPessoa
               AND (T.CdVinculo IS NULL OR T.CdVinculo = v.CdVinculo)
               AND T.FlAnulado = 'N'
               AND T.CdObjetoRecolhimento = 1
               AND (T.FlRecolhimentoTeto = 'S')
               AND ((T.NuAnoInicio < XTMPAG_var.vgFolha.NuAnoReferencia OR
                   (T.NuAnoInicio = XTMPAG_var.vgFolha.NuAnoReferencia AND
                   T.NuMesInicio <= XTMPAG_var.vgFolha.NuMesReferencia)) AND
                   (T.NuAnoFim > XTMPAG_var.vgFolha.NuAnoReferencia OR
                   (T.NuAnoFim = XTMPAG_var.vgFolha.NuAnoReferencia AND
                   T.NuMesFim >= XTMPAG_var.vgFolha.NuAnoReferencia) OR
                   T.NuAnoFim IS NULL)));

    RETURN vCont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*-----------------------------------------------------------------------------------------/
     Objetivo: Retorna o numero de dependentes que nao possuem
               registro de obito e finaliza as dependencias de
               imposto de Renda

  /*-----------------------------------------------------------------------------------------*/
  FUNCTION FDependenteOutroVinculo(pCdPessoa    IN INTEGER,
                                   pCdVinculo   IN INTEGER,
                                   pDtInicioMes IN DATE,
                                   pDtFimMes    IN DATE) RETURN INTEGER IS

    vCont         INTEGER DEFAULT 0;
    vCdDependente INTEGER DEFAULT 0;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    FOR vDependente IN (SELECT DI.CdDependenteVinculoIRRF,
                               D.CdDependente,
                               D.NmDependente,
                               DtNascimento,
                               DI.DtFimDependencia,
                               DI.FlEstudante,
                               D.FlInvalidez,
                               GP.FlFinalizaDependenciaIRRF,
                               GP.FlPensaoVitalicia
                          FROM ECadDependenteVinculo DV
                         INNER JOIN ECadDependenteVinculoIRRF DI
                            ON DV.CdDependenteVinculo =
                               DI.CdDependenteVinculo
                         INNER JOIN ECadPessoaDependente PD
                            ON PD.CdDependente = DV.CdDependente
                         INNER JOIN ECadDependente D
                            ON D.CdDependente = PD.CdDependente
                         INNER JOIN ECadGrauParentescoprevfin GP
                            ON GP.CdGrauParentescoPrevFin =
                               PD.CdGrauParentescoPrevFin

                         INNER JOIN ECadVinculo V
                            ON V.CdVinculo = dv.CdVinculo

                         WHERE PD.CdResponsavel = pCdPessoa
                           AND DI.DtInicioDependencia <= pDtFimMes
                           AND (DI.DtFimdependencia >= pDtInicioMes OR
                               DI.DtFimDependencia IS NULL)
                           AND V.Cdvinculo <> pCdVinculo
                           AND V.CdPessoa = PD.CdResponsavel
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM EAfaRegistroObito RO
                                 WHERE RO.CdDependente = DV.CdDependente
                                   AND RO.FlAnulado = XTMPAG_TIPO.cnN)
                           AND EXISTS
                         (SELECT 1
                                  FROM ecadvinculo v
                                 INNER JOIN ecadorgao o
                                    ON v.cdorgao = o.cdorgao
                                 WHERE v.cdvinculo = DV.CdVinculo
                                   AND (v.dtDesligamento >= pDtInicioMes OR
                                       v.dtdesligamento IS NULL)
                                   AND o.cdagrupamento =
                                       XTMPAG_VAR.vgFolha.CdAgrupamento)

                         ORDER BY D.CdDependente

                        )

     LOOP

      IF vCdDependente <> vDependente.Cddependente THEN
        vCont         := vCont + 1;
        vCdDependente := vDependente.Cddependente;
      END IF;

      IF vDependente.FlInvalidez = 'N' THEN

        IF vDependente.FlFinalizaDependenciaIRRF = 'S' AND
           vDependente.FlPensaoVitalicia = 'N' AND
           ((MONTHS_BETWEEN(pDtFimMes, vDependente.DtNascimento) > 21 * 12 AND -- 21 anos NAO estudante
           vDependente.FlEstudante = 'N') OR
           ((MONTHS_BETWEEN(pDtFimMes, vDependente.DtNascimento) > 25 * 12 AND -- 25 anos estudante
           vDependente.FlEstudante = 'S'))) AND
           vDependente.DtFimDependencia IS NULL THEN

          UPDATE ECadDependenteVinculoIRRF DV
             SET DV.DtFimDependencia = pDtFimMes,
                 DV.DtUltAlteracao   = SYSTIMESTAMP
           WHERE DV.CdDependenteVinculoIRRF =
                 vDependente.CdDependenteVinculoIRRF;

          XTMPAG_GERAL.PInsereLog(pInsere                  => XTMPAG_VAR.bLog,
                                  pCdHistoricoParamCalculo => XTMPAG_VAR.vCdHistParamCalc,
                                  pCdPessoa                => XTMPAG_VAR.vCdPessoa,
                                  pDeLog                   => 'Finalização de dependência de IRRF : ' ||
                                                              vDependente.NmDependente,
                                  pCdVinculo               => XTMPAG_VAR.vgVinculo.CdVinculo,
                                  pCdTipoOcorrencia        => 2, -- Ocorrencia
                                  pCdMotivoOcorrencia      => 7); -- Finalizacao de dependencia de IRRF

        END IF;

      END IF;

    END LOOP;

    RETURN vCont;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  PROCEDURE PGeraPatronalParaAfastado(pVinculo IN XTMPAG_TIPO.rVinculo,
                                      pFolha   IN XTMPAG_TIPO.rFolha) IS

    vCdTipoRegimeProprioPrev INTEGER;

    vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF (NVL(pVinculo.DtDesligamento, XTMPAG_TIPO.cnDtMax) <
       pFolha.DtInicioMes) OR
       (XTMPAG_VAR.vMotAfast.InAfastado = XTMPAG_TIPO.cnAfastadoMesTodo) THEN

      IF pVinculo.CdSituacaoPrevidenciaria <>
         XTMPAG_TIPO.cnSitPrevAposentado THEN

        IF pVinculo.CdRegimePrevidenciario = 2 THEN

          SELECT V.CdTipoRegimeProprioPrev
            INTO vCdTipoRegimeProprioPrev
            FROM ECadVinculo V
           WHERE CdVInculo = pVinculo.CdVinculo;

          IF vCdTipoRegimeProprioPrev = 1 THEN
            --FF

            BEGIN

              SELECT 1
                INTO vCont
                FROM EPagHistoricoRubricaVinculo HRV
               WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND HRV.CdVinculo = pVinculo.CdVinculo
                 AND HRV.CdRubricaAgrupamento =
                     XTMPAG_VAR.vgCdRubBaseIPREVFF
                 AND ROWNUM < 2;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pVinculo.CdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIPREVFF,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => 0,
                                                      pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 10);

            END;

          ELSE

            BEGIN

              SELECT 1
                INTO vCont
                FROM EPagHistoricoRubricaVinculo HRV
               WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND HRV.CdVinculo = pVinculo.CdVinculo
                 AND HRV.CdRubricaAgrupamento =
                     XTMPAG_VAR.vgCdRubBaseIPREVFP
                 AND ROWNUM < 2;

            EXCEPTION

              WHEN NO_DATA_FOUND THEN

                XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pVinculo.CdVinculo,
                                                      pCdExpressaoFormCalc  => NULL,
                                                      pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIPREVFP,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => 0,
                                                      pVlIndice             => NULL,
                                                      pCdTipoOrigemRubrica  => 10);

            END;

          END IF;

        END IF;

      END IF;

    END IF;

  END;

  -----------------------------------------------------------------------
  -- Soma as rubricas de retroativos de 13 salario e Ferias pois estes
  -- nao estao presentes na base de IR normal

  -- Este valor e somado a base de IRRF quando e tributacao de RRA
  -----------------------------------------------------------------------

  FUNCTION FRetornaOutrosValoresRRA(pFolha                   IN XTMPAG_TIPO.rFolha,
                                    pCdVinculo               IN INTEGER,
                                    pCdProcessoPagRetroativo IN INTEGER)
    RETURN NUMBER IS

    vvlRubrica NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vvlRubrica := 0;

    IF NOT XTMPAG_RT.vgDecJudRetro.EXISTS(pCdProcessoPagRetroativo) OR
       (XTMPAG_RT.vgDecJudRetro.EXISTS(pCdProcessoPagRetroativo) AND XTMPAG_RT.vgDecJudRetro(pCdProcessoPagRetroativo).FlIsentaIRRF = 'N') THEN

      --
      -- Solicitacao de Sustentacao #78208
      -- 11146/2017 - FOLHA - - INCLUSAO DO 12-1914 E 10-1914 NA BASE DE IRRF DE RRA
      -- 10613/2017 - FOLHA - - BLOQUEIO 13º (02-0984) CONSIDERAR COMO MONTANTE PARA RRA
      --
      SELECT NVL(SUM(HV.VlPagamento * case
                       when r.cdtiporubrica = 5 then
                        -1
                       else
                        1
                     end),
                 0) AS VlProporcional
        INTO vvlRubrica
        FROM EpagHistoricoRubricaVinculo HV
       INNER JOIN EPagRubricaAgrupamento RA
          ON RA.CdRubricaAgrupamento = HV.CdRubricaAgrupamento
       INNER JOIN EPagRubrica R
          ON R.CdRubrica = RA.CdRubrica
       WHERE HV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HV.CdVinculo = pCdVinculo
         AND HV.Cdprocessopagretroativo = pCdProcessoPagRetroativo
         AND
            -- 13 sal e ferias
             ((R.CdTipoRubrica IN (10, 12) AND
             R.NuRubrica IN (23, 56, 156, 1914, 984))
             -- bloqueio
             OR R.Cdtiporubrica = 5 and R.Nurubrica in (1984, 2984));

    END IF;

    RETURN vvlRubrica;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;

  END;

  -----------------------------------------------------------------------
  -- Soma as rubricas de Iprev (06-0915 e 06-0926)

  -- Este valor e somado a base de IRRF de RRA para calculo do NM
  -----------------------------------------------------------------------

  FUNCTION FRetornaIprevRRA(pFolha                   IN XTMPAG_TIPO.rFolha,
                            pCdVinculo               IN INTEGER,
                            pCdProcessoPagRetroativo IN INTEGER)
    RETURN NUMBER IS

    vvlRubrica NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT NVL(SUM(HV.VlPagamento), 0) AS VlProporcional
      INTO vvlRubrica
      FROM EpagHistoricoRubricaVinculo HV
     INNER JOIN EPagRubricaAgrupamento RA
        ON RA.CdRubricaAgrupamento = HV.CdRubricaAgrupamento
     INNER JOIN EPagRubrica R
        ON R.CdRubrica = RA.CdRubrica
     WHERE HV.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND HV.CdVinculo = pCdVinculo
       AND HV.CdProcessoPagRetroativo = pCdProcessoPagRetroativo
       AND (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915, 926));

    RETURN vvlRubrica;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;

  END;

  PROCEDURE PRegistroRecolhimentoAvulso13(pCdPessoa        IN INTEGER,
                                            pCdVinculo       IN INTEGER,
                                            pNuAnoReferencia IN INTEGER,
                                            pNuMesReferencia IN INTEGER) IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

          SELECT cdrecolhimentoavulso13,
                 cdpessoa,
                 cdobjetorecolhimento,
                 nuano,
                 1,
                 nuano,
                 12,
                 flrecolhimentoteto,
                 vlbaserecolhimento,
                 vlrecolhimento,
                 nucnpj,
                 nmempresa,
                 dtultalteracao,
                 NULL,
                 'N',
                 NULL,
                 nucpfcadastrador,
                 dtinclusao,
                 NULL,
                 pCdVinculo,
                 NULL,
                 cdcategoriaesocial
            INTO XTMPAG_VAR.vgRecolhimentoAvulso
            FROM eTrbRecolhimentoAvulso13 T
           WHERE T.CdPessoa = pCdPessoa
             AND T.CdObjetoRecolhimento = XTMPAG_TIPO.cn1
             AND (T.FlRecolhimentoTeto = XTMPAG_TIPO.cnS OR
                 NVL(T.VlRecolhimento, 0) > 0)
             AND T.NuAno = pNuAnoReferencia;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            XTMPAG_VAR.vgRecolhimentoAvulso := NULL;

     END;

  PROCEDURE PRegistroRecolhimentoPrev(pCdTipoFolha     IN INTEGER,
                                      pCdPessoa        IN INTEGER,
                                      pCdVinculo       IN INTEGER,
                                      pNuAnoReferencia IN INTEGER,
                                      pNuMesReferencia IN INTEGER) IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT cdrecolhimentoavulso,
           cdpessoa,
           cdobjetorecolhimento,
           nuanoinicio,
           numesinicio,
           nuanofim,
           numesfim,
           flrecolhimentoteto,
           vlbaserecolhimento,
           vlrecolhimento,
           nucnpj,
           nmempresa,
           dtultalteracao,
           dejustificativa,
           flanulado,
           dtanulado,
           nucpfcadastrador,
           dtinclusao,
           vlaliquotaunica,
           cdvinculo,
           cdAfastamento,
           cdcategoriaesocial
      INTO XTMPAG_VAR.vgRecolhimentoAvulso
      FROM eTrbRecolhimentoAvulso T
     WHERE T.CdPessoa = pCdPessoa
       AND (T.CdVinculo IS NULL OR T.CdVinculo = pCdVinculo)
       AND T.FlAnulado = XTMPAG_TIPO.cnN
       AND T.CdObjetoRecolhimento = XTMPAG_TIPO.cn1
       AND (T.FlRecolhimentoTeto = XTMPAG_TIPO.cnS OR
           NVL(T.VlRecolhimento, 0) > 0 OR T.VlAliquotaUnica IS NOT NULL)
       AND ((T.NuAnoInicio < pNuAnoReferencia OR
           (T.NuAnoInicio = pNuAnoReferencia AND
           T.NuMesInicio <= pNuMesReferencia)) AND
           (T.NuAnoFim > pNuAnoReferencia OR
           (T.NuAnoFim = pNuAnoReferencia AND
           T.NuMesFim >= pNuMesReferencia) OR T.NuAnoFim IS NULL));

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      IF pCdTipoFolha = XTMPAG_TIPO.cnTpFolha13 THEN

        BEGIN

          SELECT cdrecolhimentoavulso13,
                 cdpessoa,
                 cdobjetorecolhimento,
                 nuano,
                 1,
                 nuano,
                 12,
                 flrecolhimentoteto,
                 vlbaserecolhimento,
                 vlrecolhimento,
                 nucnpj,
                 nmempresa,
                 dtultalteracao,
                 NULL,
                 'N',
                 NULL,
                 nucpfcadastrador,
                 dtinclusao,
                 NULL,
                 pCdVinculo,
                 NULL,
                 cdcategoriaesocial
            INTO XTMPAG_VAR.vgRecolhimentoAvulso
            FROM eTrbRecolhimentoAvulso13 T
           WHERE T.CdPessoa = pCdPessoa
             AND T.CdObjetoRecolhimento = XTMPAG_TIPO.cn1
             AND (T.FlRecolhimentoTeto = XTMPAG_TIPO.cnS OR
                 NVL(T.VlRecolhimento, 0) > 0)
             AND T.NuAno = pNuAnoReferencia;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            XTMPAG_VAR.vgRecolhimentoAvulso := NULL;

        END;

      END IF;

  END;

  PROCEDURE PGeraAbonoPermanencia13(pCdVinculo          IN INTEGER,
                                    pFolha              IN XTMPAG_TIPO.rFolha,
                                    pCdRubricaAbonoPerm IN INTEGER,
                                    pVlIPESC            IN NUMBER) IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF pFolha.CdTipoFolha in
       (XTMPAG_TIPO.cnTpFolha13, XTMPAG_tipo.cnTpFolhaFunebre13) and
       not XTMPAG_geral.fpossuilanccomplementar(XTMPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                             1,
                                                                             1914),
                                                null) THEN

      IF pCdRubricaAbonoPerm > 0 AND pVlIPESC > 0.0 THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                    1,
                                                                                                    1914),
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => pVlIPESC,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);
      END IF;

    END IF;

  END;

  ---------------------------------------------------------
  -- Exclui abono permanência se não há desconto do IPREV
  ---------------------------------------------------------
  PROCEDURE PExcluiAbonoPermanencia(pCdVinculo IN INTEGER,
                                    pFolha     IN XTMPAG_TIPO.rFolha,
                                    pVlIPESC   IN NUMBER) IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF pFolha.CdAgrupamento = 1 AND pVlIPESC = 0 THEN

      XTMPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pcdrubrica        => XTMPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                    1,
                                                                                    914));

    END IF;

  END;

  PROCEDURE PInsereDepositoEmJuizo(pFolha     IN XTMPAG_TIPO.rFolha,
                                   pCdPessoa  IN INTEGER,
                                   pCdVinculo IN INTEGER,
                                   pVlBase    IN INTEGER,
                                   pVlLiquido IN INTEGER) IS

    vVlBase    NUMBER(13, 2);
    vVlLiquido NUMBER(13, 2);
    vVlIndice  NUMBER(13, 2);
    i          NUMERIC;
    vSufixo    NUMERIC := 1;
    vCdRubrica INTEGER;
    vDeRubrica VARCHAR(25);
    vNmRubrica VARCHAR(150);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCdRubrica := XTMPAG_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                               pcdtiporubrica => 5,
                                               pNuRubrica     => 5516);

    vDeRubrica := 'Dep. Juízo Ref. Rubrica ';

    FOR Juizo IN (SELECT HRV.CDRUBRICAAGRUPAMENTO,
                         HRV.Nusufixorubrica,
                         HRV.Vlpagamento,
                         0,
                         HRV.Vlindicerubrica,
                         HTR.Cdhistisencaorubrica
                    FROM EPagHistoricoRubricaVinculo HRV
                   INNER JOIN ETrbIsencaoRubrica TR
                      ON TR.CdVinculo = HRV.CdVinculo
                     AND TR.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
                   INNER JOIN ETrbHistIsencaoRubrica HTR
                      ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                   WHERE TR.CdVinculo = pCdVinculo
                     AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                     AND TR.FlRubricaIsentaIRRF = 'S'
                     AND ((HTR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                         (HTR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                         HTR.NuMesInicioVigencia <=
                         pFolha.NuMesReferencia)) AND
                         (HTR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
                         (HTR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
                         HTR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
                         HTR.NuMesFimVigencia IS NULL) AND
                         TR.FLDEPOSITOEMJUIZO = 'S'))

     LOOP

      vVlLiquido := 0;
      vVlBase    := pVlBase + Juizo.VlPagamento;
      i          := 0;

      WHILE i < (XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT) LOOP

        i := i + 1;

        IF vVlBase BETWEEN XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).vlInicial AND XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).vlFinal THEN

          vVlLiquido := vvlBase * XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota / 100;

          vvlLiquido := vvlLiquido - NVL(XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlParcelaDeducao,
                                         0);

          vvlIndice := XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota;

          i := XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT + 1;

        END IF;

      END LOOP;

      SELECT lpad(vp.cdtiporubrica, 2, 0) || '-' ||
             lpad(vp.nurubrica, 4, 0) || ' ' ||
             substr(vp.derubricaagrupamento, 1, 100)
        INTO vNmRubrica
        FROM vPagRubrica vp
       WHERE vp.cdrubricaagrupamento = Juizo.Cdrubricaagrupamento;

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.Nusufixorubrica = vSufixo
         AND HRV.CdRubricaAgrupamento = vCdRubrica
         AND HRV.Cdhistsentencajudicial = Juizo.Cdhistisencaorubrica;

      XTMPAG_GERAL.pinserelancamentovinculo(pcdfolhapagamento       => pFolha.CdFolhaPagamento,
                                            pcdvinculo              => pCdVinculo,
                                            pcdexpressaoformcalc    => NULL,
                                            pcdrubricaagrupamento   => vCdRubrica,
                                            pnusufixorubrica        => vSufixo,
                                            pvlpagamento            => vvlLiquido -
                                                                       pVlLiquido,
                                            pvlindice               => vVlIndice,
                                            pcdtipoorigemrubrica    => 3,
                                            pcdtipoindice           => XTMPAG_VAR.vgRubrica(vCdRubrica).CdTipoIndice,
                                            pcdhistsentencajudicial => Juizo.Cdhistisencaorubrica,
                                            pDeexpressao            => vDeRubrica ||
                                                                       vNmRubrica);

      vSufixo := vSufixo + 1;

    END LOOP;

  END;

  PROCEDURE PAssociaRubricaPensao(pCdVinculo        IN INTEGER,
                                  pFolha            IN XTMPAG_TIPO.rFolha,
                                  pFlAdiant13Pensao IN CHAR DEFAULT 'N',
                                  pFlPensao13       IN CHAR DEFAULT 'N') IS

    vCdHistTipoPensaoRubrica INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    FOR vHistSentenca IN (SELECT SR.CdHistSentencaJudicial, COUNT(*)
                            FROM ePenSentencaJudicial SJ
                           INNER JOIN EPenHistSentencaJudicial HSJ
                              ON SJ.CdSentencaJudicial =
                                 HSJ.CdSentencaJudicial
                           INNER JOIN EPenSentencaRubrica SR
                              ON SR.CdHistSentencaJudicial =
                                 HSJ.CdHistSentencaJudicial
                           INNER JOIN EPenHistTipoPensaoRubrica TPR
                              ON SR.CdHistTipoPensaoRubrica =
                                 TPR.CdHistTipoPensaoRubrica
                           WHERE SJ.CdVinculo = pCdVinculo
                             AND HSJ.DtInicioVigencia <= pFolha.DtInicioMes
                             AND (HSJ.DtFimVigencia >= pFolha.DtFimMes OR
                                 HSJ.DtFimVigencia IS NULL)
                           GROUP BY SR.CdHistSentencaJudicial) LOOP

      BEGIN

        SELECT TPR.CdHistTipoPensaoRubrica
          INTO vCdHistTipoPensaoRubrica
          FROM EPenHistSentencaJudicial HSJ
         INNER JOIN EPenSentencaRubrica SR
            ON SR.CdHistSentencaJudicial = HSJ.cdhistsentencajudicial
         INNER JOIN EPenHistTipoPensaoRubrica TPR
            ON SR.CdHistTipoPensaoRubrica = TPR.CdHistTipoPensaoRubrica
         INNER JOIN EPagRubricaAgrupamento RA
            ON RA.CdRubricaAgrupamento = TPR.CdRubricaAgrupamento
         WHERE HSJ.CdHistSentencaJudicial =
               vHistSentenca.CdHistSentencaJudicial
           AND RA.FlAdiant13Pensao = pFlAdiant13Pensao
           AND RA.Fl13SalPensao = pFlPensao13
           AND ROWNUM < 2;

      EXCEPTION

        WHEN NO_DATA_FOUND THEN

          BEGIN

            SELECT TPR.CdHistTipoPensaoRubrica
              INTO vCdHistTipoPensaoRubrica
              FROM EPenHistTipoPensaoRubrica TPR
             INNER Join EPenHistTipoPensao HTP
                ON HTP.CdHistTipoPensao = TPR.cdhisttipopensao
             INNER JOIN EPagRubricaAgrupamento RA
                ON RA.CdRubricaAgrupamento = TPR.CdRubricaAgrupamento
             WHERE RA.CdAgrupamento = pFolha.CdAgrupamento
               AND RA.FlAdiant13Pensao = pFlAdiant13Pensao
               AND RA.Fl13SalPensao = pFlPensao13
               AND ((HTP.NuAnoInicio < pFolha.NuAnoReferencia OR
                   (HTP.NuAnoInicio = pFolha.NuAnoReferencia AND
                   HTP.NuMesInicio <= pFolha.NuMesReferencia)) AND
                   (HTP.NuAnoFim > pFolha.NuAnoReferencia OR
                   (HTP.NuAnoFim = pFolha.NuAnoReferencia AND
                   HTP.NuMesFim >= pFolha.NuMesReferencia) OR
                   HTP.NuAnoFim IS NULL))
               AND ROWNUM < 2;

            INSERT INTO EPenSentencaRubrica
              (cdsentencarubrica,
               cdhistsentencajudicial,
               cdhisttipopensaorubrica,
               cdoutrarubrica,
               fldescanterioraplicpercent,
               vlpercentpensao,
               vlfixo,
               dtultalteracao)
            VALUES
              (SPenSentencaRubrica.NEXTVAL,
               vHistSentenca.CdHistSentencaJudicial,
               vCdHistTipoPensaoRubrica,
               NULL,
               'N',
               100,
               NULL,
               SYSTIMESTAMP);

          EXCEPTION

            WHEN NO_DATA_FOUND THEN

              NULL;

          END;

      END;

    END LOOP;

  END;

  /*-----------------------------------------------------------------------------------------/
     Objetivo: Retorna TRUE caso a pessoa possua relacao de vinculo de
               pensao previdenciaria, pensao nao previdenciaria ou
               auxilio reclusao, seja aposentado e possua mais de 65 anos no dia 1 do
               mes de processamento.

  /*-----------------------------------------------------------------------------------------*/
  FUNCTION FAplicaDeducaoInativo(pcdPessoa    IN INTEGER,
                                 pDtInicioMes IN DATE,
                                 pDtFimMes    IN DATE) RETURN BOOLEAN IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF MONTHS_BETWEEN(pDtFimMes, XTMPAG_VAR.vgVinculo.DtNascimento) >=
       XTMPAG_TIPO.cnMesesIdadeApo AND
       XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria IN (2, 4, 9) THEN

      RETURN TRUE;

    ELSE

      RETURN FALSE;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN FALSE;

  END;

  /*-----------------------------------------------------------------------------------------/

  /-----------------------------------------------------------------------------------------*/

  FUNCTION FRetornaAliquotaINSS(pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER)
    RETURN XTMPAG_TIPO.rAliquotaINSS IS

    CURSOR cFaixa(pCdHistAliquotaINSS IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             F.Flaliquotaprogressiva,
             hai.Vlaliqcontribindividual,
             hai.VLTETOCONTRIBINDIVIDUAL
        FROM EtrbaliquotafaixaINSS F
       INNER JOIN etrbhistaliquotainss hai
          ON hai.cdhistaliquotainss = f.cdhistaliquotainss
       WHERE F.CdHistAliquotaINSS = pCdHistAliquotaINSS
       ORDER BY F.VlInicial;

    vAliquotaINSS XTMPAG_TIPO.rAliquotaINSS;
    vFaixa        XTMPAG_TIPO.tFaixaAliquota;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT A.CdHistAliquotaINSS
      INTO vAliquotaINSS.CdHistAliquotaINSS
      FROM EtrbHistAliquotaINSS A
     WHERE ((A.nuAnoInicio < pNuAnoReferencia OR
           (A.nuAnoInicio = pNuAnoReferencia AND
           A.nuMesInicio <= pNuMesReferencia)) AND
           (A.nuAnoFinal > pNuAnoReferencia OR
           (A.nuAnoFinal = pNuAnoReferencia AND
           A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));

    OPEN cFaixa(vAliquotaINSS.CdHistAliquotaINSS);

    FETCH cFaixa BULK COLLECT
      INTO vFaixa;

    CLOSE cFaixa;

    IF vFaixa.COUNT > 0 THEN

      vAliquotaINSS.VlTeto := 0;

      FOR i IN vFaixa.FIRST .. vFaixa.LAST

       LOOP

        IF vAliquotaINSS.VlTeto < vFaixa(i).VlFinal THEN

          vAliquotaINSS.VlTeto := vFaixa(i).VlFinal;

        END IF;

      END LOOP;

      vAliquotaINSS.lFaixa := vFaixa;

      RETURN vAliquotaINSS;

    ELSE

      RETURN NULL;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  --23654/2025 - GEREF - TRIBUTACAO IRRF SERVIDOR RESIDENTE NO EXTERIOR
  --CLAUDEMIR GOMES - 18/08/2025
  FUNCTION FVerificaResidenteExterior 
    RETURN BOOLEAN IS
    
    vResitenteExterior VARCHAR2(1);
    
  BEGIN
    
    SELECT 'S' INTO vResitenteExterior
      FROM ecadvinculo v
     INNER JOIN ecadpessoa p
        ON p.cdpessoa = v.cdpessoa
     INNER JOIN ecadendereco e
        ON e.cdendereco = p.cdendereco
     WHERE flenderecoexterior = 'S'
       AND v.dtdesligamento IS NULL
       AND v.cdpessoa = XTMPAG_VAR.vCdPessoa
       AND ROWNUM = 1;
    
    RETURN TRUE;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      
      RETURN FALSE;
      
  END;

  FUNCTION FRetornaAliquotaIRRFExterior(pNuAnoReferencia IN INTEGER,
                                        pNuMesReferencia IN INTEGER,
                                        pCdTipoAliquota  IN INTEGER DEFAULT 1)
    RETURN XTMPAG_TIPO.rAliquotaIRRF IS
  
    CURSOR cFaixa IS
      SELECT 0.01           as VlInicial,
             99999999999.99 as VlFinal,
             vlparametro    as VlAliquota,
             0.00           as VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM esegparametro
       WHERE cdparametro = 372;--Código Indice de tributação IRRF para residente no exterior
  
    vAliquotaIRRF XTMPAG_TIPO.rAliquotaIRRF;
    vFaixa        XTMPAG_TIPO.tFaixaAliquota;
  
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
  
    vAliquotaIRRF.CdHistAliquotaIRRF := 0;
    vAliquotaIRRF.VlDeducaoDependente := 0;
    vAliquotaIRRF.VlDeducaoInativo := 0;

    OPEN cFaixa;
  
    FETCH cFaixa BULK COLLECT
      INTO vFaixa;
  
    CLOSE cFaixa;
  
    vAliquotaIRRF.lFaixa := vFaixa;
  
    RETURN vAliquotaIRRF;
  
  EXCEPTION
  
    WHEN OTHERS THEN
    
      RETURN NULL;
    
  END;
  --FIM 23654/2025
  
  FUNCTION FRetornaAliquotaIRRF(pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER,
                                pCdTipoAliquota  IN INTEGER DEFAULT 1)
    RETURN XTMPAG_TIPO.rAliquotaIRRF IS

    CURSOR cFaixa(pCdHistAliquotaIRRF IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM Etrbaliquotafaixairrf F
       WHERE F.CdHistAliquotaIRRF = pCdHistAliquotaIRRF
       ORDER BY F.VlInicial;

    vAliquotaIRRF XTMPAG_TIPO.rAliquotaIRRF;
    vFaixa        XTMPAG_TIPO.tFaixaAliquota;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT A.CdHistAliquotaIRRF, A.VlDeducaoDependente, A.VlDeducaoInativo
      INTO vAliquotaIRRF.CdHistAliquotaIRRF,
           vAliquotaIRRF.VlDeducaoDependente,
           vAliquotaIRRF.VlDeducaoInativo
      FROM ETrbHistAliquotaIRRF A
     WHERE A.CdTipoAliquotaIRRF = pCdTipoAliquota
       AND ((A.nuAnoInicio < pNuAnoReferencia OR
           (A.nuAnoInicio = pNuAnoReferencia AND
           A.nuMesInicio <= pNuMesReferencia)) AND
           (A.nuAnoFinal > pNuAnoReferencia OR
           (A.nuAnoFinal = pNuAnoReferencia AND
           A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));

    OPEN cFaixa(vAliquotaIRRF.CdHistAliquotaIRRF);

    FETCH cFaixa BULK COLLECT
      INTO vFaixa;

    CLOSE cFaixa;

    IF vFaixa.COUNT > 0 THEN

      vAliquotaIRRF.lFaixa := vFaixa;

      RETURN vAliquotaIRRF;

    ELSE

      RETURN NULL;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  FUNCTION FRetornaAliquotaIPESC(pCdTpTributacaoIPESC IN INTEGER,
                                 pNuAnoReferencia     IN INTEGER,
                                 pNuMesReferencia     IN INTEGER)
    RETURN XTMPAG_TIPO.rAliquotaIPESC IS

    CURSOR cFaixa(pCdHistAliquotaIPESC IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM EtrbaliquotafaixaIPESC F
       WHERE F.CdHistAliquotaIPESC = pCdHistAliquotaIPESC
       ORDER BY F.VlInicial;

    vAliquotaIPESC XTMPAG_TIPO.rAliquotaIPESC;
    vFaixa         XTMPAG_TIPO.tFaixaAliquota;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT A.CdHistAliquotaIPESC, A.VlAliquotaUnica
      INTO vAliquotaIPESC.CdHistAliquotaIPESC,
           vAliquotaIPESC.VlAliquotaUnica
      FROM ETrbHistAliquotaIPESC A
     WHERE A.CdTipoAliquota = pCdTpTributacaoIPESC
       AND ((A.nuAnoInicio < pNuAnoReferencia OR
           (A.nuAnoInicio = pNuAnoReferencia AND
           A.nuMesInicio <= pNuMesReferencia)) AND
           (A.nuAnoFinal > pNuAnoReferencia OR
           (A.nuAnoFinal = pNuAnoReferencia AND
           A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));

    OPEN cFaixa(vAliquotaIPESC.CdHistAliquotaIPESC);

    FETCH cFaixa BULK COLLECT
      INTO vFaixa;

    CLOSE cFaixa;

    vAliquotaIPESC.lFaixa := vFaixa;

    RETURN vAliquotaIPESC;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  FUNCTION FRetornaAliquotaIPESCRescisao(pCdTpTributacaoIPESC IN INTEGER,
                                         pNuAnoReferencia     IN INTEGER,
                                         pNuMesReferencia     IN INTEGER)
    RETURN XTMPAG_TIPO.rAliquotaIPESC IS

    CURSOR cFaixa(pCdHistAliquotaIPESC IN INTEGER,
                  pVlIndiceRescisao    IN NUMBER) IS
      SELECT (F.VlInicial * pVlIndiceRescisao / 12) VlInicial,
             (F.VlFinal * pVlIndiceRescisao / 12) VlFinal,
             F.VlAliquota,
             (F.VlParcelaDeducao * pVlIndiceRescisao / 12) VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM EtrbaliquotafaixaIPESC F
       WHERE F.CdHistAliquotaIPESC = pCdHistAliquotaIPESC
       ORDER BY F.VlInicial;

    vAliquotaIPESCRescisao XTMPAG_TIPO.rAliquotaIPESC;
    vFaixaRescisao         XTMPAG_TIPO.tFaixaAliquota;
    vIndiceRescisao        NUMBER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT A.CdHistAliquotaIPESC, A.VlAliquotaUnica
      INTO vAliquotaIPESCRescisao.CdHistAliquotaIPESC,
           vAliquotaIPESCRescisao.VlAliquotaUnica
      FROM ETrbHistAliquotaIPESC A
     WHERE A.CdTipoAliquota = pCdTpTributacaoIPESC
       AND ((A.nuAnoInicio < pNuAnoReferencia OR
           (A.nuAnoInicio = pNuAnoReferencia AND
           A.nuMesInicio <= pNuMesReferencia)) AND
           (A.nuAnoFinal > pNuAnoReferencia OR
           (A.nuAnoFinal = pNuAnoReferencia AND
           A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));

    vIndiceRescisao := XTMPAG_geral.fretornaindicerubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                          XTMPAG_VAR.VGVINCULO.cdvinculo,
                                                          XTMPAG_VAR.vgCdRubricaRecisao13);

    OPEN cFaixa(vAliquotaIPESCRescisao.CdHistAliquotaIPESC,
                vIndiceRescisao);

    FETCH cFaixa BULK COLLECT
      INTO vFaixaRescisao;

    CLOSE cFaixa;

    vAliquotaIPESCRescisao.lFaixa := vFaixaRescisao;

    RETURN vAliquotaIPESCRescisao;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  FUNCTION FRetornaAliquotaCPSM(pCdTpTributacaoCPSM IN INTEGER,
                                pNuAnoReferencia    IN INTEGER,
                                pNuMesReferencia    IN INTEGER)
    RETURN XTMPAG_TIPO.rAliquotaCPSM IS

    CURSOR cFaixa(pCdHistAliquotaCPSM IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             'N',
             NULL,
             NULL
        FROM EtrbaliquotafaixaCPSM F
       WHERE F.CdHistAliquotaCPSM = pCdHistAliquotaCPSM
       ORDER BY F.VlInicial;

    vAliquotaCPSM XTMPAG_TIPO.rAliquotaCPSM;
    vFaixa        XTMPAG_TIPO.tFaixaAliquota;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT A.CdHistAliquotaCPSM, A.VlAliquotaUnica
      INTO vAliquotaCPSM.CdHistAliquotaCPSM, vAliquotaCPSM.VlAliquotaUnica
      FROM ETrbHistAliquotaCPSM A
     WHERE A.CdTipoAliquota = pCdTpTributacaoCPSM
       AND ((A.nuAnoInicio < pNuAnoReferencia OR
           (A.nuAnoInicio = pNuAnoReferencia AND
           A.nuMesInicio <= pNuMesReferencia)) AND
           (A.nuAnoFinal > pNuAnoReferencia OR
           (A.nuAnoFinal = pNuAnoReferencia AND
           A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));

    OPEN cFaixa(vAliquotaCPSM.CdHistAliquotaCPSM);

    FETCH cFaixa BULK COLLECT
      INTO vFaixa;

    CLOSE cFaixa;

    vAliquotaCPSM.lFaixa := vFaixa;

    RETURN vAliquotaCPSM;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NULL;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FRetornaRubricaAgrup
     Objetivo: Retorna o codigo da rubrica vigente no agrupamento, com base nos
               parametros informados.

   Argumentos: pCdAgrupamento   - Codigo do agrupamento
               pNuAnoReferencia - Ano de referencia
               pNuMesReferencia - Mes de referencia
               pCdRubrica       - Codigo da rubrica do agrupamento,
               pTipoRubrica     - Codigo do tipo de rubrica da qual se deseja obter
                                  o codigo da rubrica no agrupamento

         Nota: Caso nao seja encontrada a rubrica, ou exista mais de uma
               rubrica que atenda aos parametros informados e retornado o
               valor '0'
  /-----------------------------------------------------------------------------*/
  FUNCTION FRetornaRubricaAgrup(pCdAgrupamento   IN INTEGER,
                                pNuAnoReferencia IN INTEGER,
                                pNuMesReferencia IN INTEGER,
                                pCdRubrica       IN INTEGER,
                                pCdTipoRubrica   IN INTEGER) RETURN INTEGER IS

    vCdRubricaAgrupamento INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT RA.CdRubricaAgrupamento
      INTO vCdRubricaAgrupamento
      FROM EpagRubricaAgrupamento RA
     INNER JOIN EPagRubrica R
        ON R.CdRubrica = RA.CdRubrica
     INNER JOIN EPagHistRubricaAgrupamento HRA
        ON HRA.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
     WHERE RA.CdAgrupamento = pCdAgrupamento
       AND R.CdTipoRubrica = pCdTipoRubrica
       AND ((HRA.Nuanoiniciovigencia < pNuAnoReferencia OR
           (HRA.Nuanoiniciovigencia = pNuAnoReferencia AND
           HRA.Numesiniciovigencia <= pNuMesReferencia)) AND
           (HRA.NuAnoFimVigencia > pNuAnoReferencia OR
           (HRA.NuAnoFimVigencia = pNuAnoReferencia AND
           HRA.NuMesFimVigencia >= pNuMesReferencia) OR
           HRA.NuAnoFimVigencia IS NULL))
       AND R.NuRubrica =
           (SELECT NuRubrica
              FROM epagRubrica R1
             INNER JOIN EPagRubricaAgrupamento RA1
                ON R1.CdRubrica = RA1.CdRubrica
             WHERE RA1.CdRubricaAgrupamento = pCdRubrica);

    RETURN vCdRubricaAgrupamento;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FRetornaRegimeProprioPrev(pCdVinculo IN INTEGER) RETURN INTEGER IS

    vCdRegimeProprioPrev INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT NVL(EV.Cdtiporegimeproprioprev, 0)
      INTO vCdRegimeProprioPrev
      FROM ECadVinculo EV
     WHERE EV.Cdvinculo = pCdVinculo;

    RETURN vCdRegimeProprioPrev;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  ------------------------------------------------------------------------------
  --     Funcao: FValorIsentoRetIRRF
  --   Objetivo: Retorna o valor das rubricas do tipo 2 que devem ser abatidos do
  --             valor da base de imposto de renda normal
  ------------------------------------------------------------------------------

  FUNCTION FValorIsentoRetIRRF(pFolha         IN XTMPAG_TIPO.rFolha,
                               pCdVinculo     IN INTEGER,
                               pCdRubBaseIRRF IN INTEGER)

   RETURN NUMBER IS

    vVlResultado NUMBER(13, 2);

    vVlRetroativo NUMBER(13, 2);

    i INTEGER;

    vCdHistBase INTEGER;
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vVlResultado := 0;

    IF XTMPAG_RT.vgDecJudRetro.COUNT > 0 THEN

      i := XTMPAG_RT.vgDecJudRetro.FIRST;

      vCdHistBase := XTMPAG_VAR.vgBaseExpr(XTMPAG_VAR.vgRubrica(pCdRubBaseIRRF).CdBaseCalculo).CdHistBaseCalculo;

      WHILE i IS NOT NULL LOOP

        IF XTMPAG_RT.vgDecJudRetro(i).FlIsentaIRRF = 'S' THEN

          SELECT SUM(VlPagamento)
            INTO vVlRetroativo
            FROM EPagHistoricoRubricaVinculo HRV
           INNER JOIN (SELECT EXRA.CdRubricaAgrupamento
                         FROM EPagBaseCalcBlocoExprRubAgrup EXRA
                        INNER JOIN EPagBaseCalculoBlocoExpressao BCE
                           ON BCE.CdBaseCalculoBlocoExpressao =
                              EXRA.CdBaseCalculoBlocoExpressao
                        INNER JOIN EPagBaseCalculoBloco BCB
                           ON BCB.CdBaseCalculoBloco =
                              BCE.CdBaseCalculoBloco
                        WHERE BCB.CdHistBaseCalculo = vCdHistBase) BASE
              ON BASE.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
           INNER JOIN EPagRubricaAgrupamento RA
              ON RA.CdRubricaAgrupamento = BASE.CdRubricaAgrupamento
           INNER JOIN EPagRubrica R
              ON R.CdRubrica = RA.CdRubrica
           WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND HRV.CdProcessoPagRetroativo = XTMPAG_RT.vgDecJudRetro(i).CdProcessoPagRetroativo
             AND R.CdTipoRubrica = 2;

          vVlResultado := NVL(vVlResultado, 0) + NVL(vVlRetroativo, 0);

        END IF;

        i := XTMPAG_RT.vgDecJudRetro.NEXT(i);

      END LOOP;

    END IF;

    RETURN vVlResultado;

  END;

  ------------------------------------------------------------------------------
  --     Funcao: FValorIsentoRetIRRFRRA
  --   Objetivo: Retorna o valor das rubricas do tipo 10 e 12 que devem ser abatidos do
  --             valor da base de imposto de renda de RRA
  ------------------------------------------------------------------------------
  FUNCTION FValorIsentoRetIRRFRRA(pFolha                   IN XTMPAG_TIPO.rFolha,
                                  pCdVinculo               IN INTEGER,
                                  pCdProcessoPagRetroativo IN INTEGER,
                                  pCdRubBaseIRRF           IN INTEGER)
    RETURN NUMBER IS

    vVlResultado NUMBER(13, 2);

    vVlResultOutros NUMBER(13, 2);

    vCdHistBase INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vVlResultado := 0;

    vVlResultOutros := 0;

    IF XTMPAG_RT.vgDecJudRetro.EXISTS(pCdProcessoPagRetroativo) THEN

      IF XTMPAG_RT.vgDecJudRetro(pCdProcessoPagRetroativo).FlIsentaIRRF = 'S' THEN

        vCdHistBase := XTMPAG_VAR.vgBaseExpr(XTMPAG_VAR.vgRubrica(pCdRubBaseIRRF).CdBaseCalculo).CdHistBaseCalculo;

        SELECT SUM(VlPagamento)
          INTO vVlResultado
          FROM EPagHistoricoRubricaVinculo HRV
         INNER JOIN (SELECT EXRA.CdRubricaAgrupamento
                       FROM EPagBaseCalcBlocoExprRubAgrup EXRA
                      INNER JOIN EPagBaseCalculoBlocoExpressao BCE
                         ON BCE.CdBaseCalculoBlocoExpressao =
                            EXRA.CdBaseCalculoBlocoExpressao
                      INNER JOIN EPagBaseCalculoBloco BCB
                         ON BCB.CdBaseCalculoBloco = BCE.CdBaseCalculoBloco
                      WHERE BCB.CdHistBaseCalculo = vCdHistBase) BASE
            ON BASE.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
         INNER JOIN EPagRubricaAgrupamento RA
            ON RA.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
         INNER JOIN EPagRubrica R
            ON R.CdRubrica = RA.CdRubrica
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdProcessoPagRetroativo = pCdProcessoPagRetroativo
           AND R.CdTipoRubrica IN (10, 12);

        SELECT NVL(SUM(HV.VlPagamento), 0) AS VlProporcional
          INTO vVlResultOutros
          FROM EpagHistoricoRubricaVinculo HV
         INNER JOIN EPagRubricaAgrupamento RA
            ON RA.CdRubricaAgrupamento = HV.CdRubricaAgrupamento
         INNER JOIN EPagRubrica R
            ON R.CdRubrica = RA.CdRubrica
         WHERE HV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HV.CdVinculo = pCdVinculo
           AND HV.Cdprocessopagretroativo = pCdProcessoPagRetroativo
           AND (R.CdTipoRubrica IN (10, 12) AND
               R.NuRubrica IN (23, 56, 156, 1914, 984));

        vVlResultado := NVL(vVlResultado, 0) + NVL(vVlResultOutros, 0);

      END IF;

    END IF;

    RETURN vVlResultado;

  END;

  /*-----------------------------------------------------------------------------------------/

  /-----------------------------------------------------------------------------------------*/

  FUNCTION FRetornaValorRubIsentas(pCdVinculo         IN INTEGER,
                                   pFolha             IN XTMPAG_TIPO.rFolha,
                                   pCdTipoDesconto    IN INTEGER,
                                   pFlDepositoEmJuizo IN CHAR DEFAULT 'N')

   RETURN NUMBER IS

    vvlRubIsentas NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT SUM(HRV.VlPagamento)
      INTO vvlRubIsentas
      FROM EPagHistoricoRubricaVinculo HRV
     INNER JOIN ETrbIsencaoRubrica TR
        ON TR.CdVinculo = HRV.CdVinculo
       AND TR.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
     INNER JOIN ETrbHistIsencaoRubrica HTR
        ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
     WHERE TR.CdVinculo = pCdVinculo
       AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
       AND CASE pCdTipoDesconto
             WHEN 1 THEN
              TR.FlRubricaIsentaINSS
             WHEN 2 THEN
              TR.FlRubricaIsentaIRRF
             WHEN 3 THEN
              TR.FlRubricaIsentaIPESC
           END = XTMPAG_TIPO.cnS
       AND ((HTR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
           (HTR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
           HTR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
           (HTR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
           (HTR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
           HTR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
           HTR.NuMesFimVigencia IS NULL) AND TR.FLDEPOSITOEMJUIZO = CASE
             WHEN pFlDepositoEmJuizo = 'S' THEN
              pFlDepositoEmJuizo
             ELSE
              TR.FLDEPOSITOEMJUIZO
           END);

    RETURN NVL(vvlRubIsentas, 0);

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FIsentoIRRF(pCdVinculo IN INTEGER, pFolha IN XTMPAG_TIPO.rFolha)

   RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento =
       XTMPAG_TIPO.cnRelPesquisador THEN

      RETURN TRUE;

    ELSE

      SELECT 1
        INTO vCont
        FROM ETrbIsencaoIRRF IR
       INNER JOIN ETrbHistIsencaoIRRF HIR
          ON IR.CdIsencaoIRRF = HIR.CdIsencaoIRRF
       WHERE IR.CdVinculo = pCdVinculo
         AND HIR.FlAnulado = XTMPAG_TIPO.cnN
         AND ((HIR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
             (HIR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
             HIR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
             (HIR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
             (HIR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
             HIR.NuMesFimVigencia > pFolha.NuMesReferencia) OR
             HIR.NuAnoFimVigencia IS NULL));

      RETURN TRUE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    WHEN TOO_MANY_ROWS THEN

      RETURN TRUE;

  END;
  
   FUNCTION FIsentoIRRFVinculoApo(pCdVinculo IN INTEGER, pFolha IN XTMPAG_TIPO.rFolha)

   RETURN BOOLEAN IS

    vCont INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    
    SELECT 1
      INTO vCont
      FROM ETrbIsencaoIRRF IR
     INNER JOIN ETrbHistIsencaoIRRF HIR
        ON IR.CdIsencaoIRRF = HIR.CdIsencaoIRRF   
     INNER JOIN ECadVinculo V2         
        ON V2.CdVinculo = IR.CdVinculo             
     WHERE V2.CdPessoa = (SELECT V.CdPessoa
                            FROM ECadVinculo V
                           WHERE V.CdVinculo = pCdVinculo)
       AND V2.Cdvinculo <> pCdVinculo
       AND V2.CdSituacaoPrevidenciaria = 2 -- Inativo/Aposentado
       AND (V2.DtDesligamento IS NULL OR V2.DtDesligamento >= pFolha.DtInicioMes)
       AND HIR.FlAnulado = XTMPAG_TIPO.cnN
       AND ((HIR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
           (HIR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
           HIR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
           (HIR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
           (HIR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
           HIR.NuMesFimVigencia > pFolha.NuMesReferencia) OR
           HIR.NuAnoFimVigencia IS NULL));

    RETURN TRUE;



  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN FALSE;

    WHEN TOO_MANY_ROWS THEN

      RETURN TRUE;

  END;


  PROCEDURE PPossuiLancFinanceiroPensao(pCdVinculo IN INTEGER,
                                        pFolha     IN XTMPAG_TIPO.rFolha) IS

    vCdRubricaAgrupamento INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    FOR RUB IN (SELECT TPR.CdRubricaAgrupamento,
                       LF.Vlindice,
                       LF.Vllancamentofinanceiro,
                       LF.Nusufixorubrica,
                       LF.Nuparcelas,
                       LF.Cdlancamentofinanceiro,
                       LF.Cdprocessopagretroativo
                  FROM ePenSentencaJudicial SJ
                 INNER JOIN EPenHistSentencaJudicial HSJ
                    ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
                 INNER JOIN EPenTipoPensaoAlimenticia TPA
                    ON HSJ.CdTipoPensaoAlimenticia =
                       TPA.CdTipoPensaoAlimenticia
                 INNER JOIN EPenHistTipoPensao HTP
                    ON TPA.CdTipoPensaoAlimenticia =
                       HTP.CdTipoPensaoAlimenticia
                 INNER JOIN EPenHistTipoPensaoRubrica TPR
                    ON TPR.CdHistTipoPensao = HTP.CdHistTipoPensao
                 INNER JOIN epaghistoricorubricavinculo HRV
                    ON HRV.Cdrubricaagrupamento = TPR.Cdrubricaagrupamento
                   AND HRV.Cdfolhapagamento = pFolha.CdFolhaPagamento
                 INNER JOIN Epaglancamentofinanceiro LF
                    ON LF.Cdrubricaagrupamento = TPR.Cdrubricaagrupamento
                   AND LF.NuSufixoRubrica = SJ.Nusequencial
                   AND LF.Flanulado = 'N'
                   AND LF.DtInicioDireito <= pFolha.DtFimMes
                   AND (LF.DtFimDireito >= pFolha.DtInicioMes OR
                       LF.DtFimDireito IS NULL)
                   AND LF.Cdvinculo = pCdVinculo
                 WHERE SJ.CdVinculo = pCdVinculo
                   AND HSJ.FlAnulado = XTMPAG_TIPO.cnN
                   AND HSJ.Dtiniciovigencia <= pFolha.DtFimMes
                   AND ((HSJ.DtFimVigencia >= case
                         when pFolha.CdTipoFolha IN
                              (XTMPAG_TIPO.cnTpFolha13,
                               XTMPAG_tipo.cnTpFolhaCtisp13) then
                          to_date('01/12/' || pFolha.NuAnoReferencia,
                                  'DD/MM/YYYY')
                         else
                          pFolha.DtInicioMes
                       end) OR HSJ.DtFimVigencia IS NULL)
                   AND ((HTP.NuAnoInicio < pFolha.NuAnoReferencia OR
                       (HTP.NuAnoInicio = pFolha.NuAnoReferencia AND
                       HTP.NuMesInicio <= pFolha.NuMesReferencia)) AND
                       (HTP.NuAnoFim > pFolha.NuAnoReferencia OR
                       (HTP.NuAnoFim = pFolha.NuAnoReferencia AND
                       HTP.NuMesFim >= pFolha.NuMesReferencia) OR
                       HTP.NuAnoFim IS NULL))
                 GROUP BY TPR.CdRubricaAgrupamento,
                          LF.Vlindice,
                          LF.Vllancamentofinanceiro,
                          LF.Nusufixorubrica,
                          LF.Nuparcelas,
                          LF.Cdlancamentofinanceiro,
                          LF.Cdprocessopagretroativo) LOOP

      DELETE FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = RUB.CdRubricaAgrupamento
         AND HRV.Cdlancamentofinanceiro IS NULL;

    END LOOP;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;

  END;

  PROCEDURE PSetaRurbicasIsentas(pFolha     IN XTMPAG_TIPO.rFolha,
                                 pCdVinculo IN INTEGER) IS

    vCdIsencaoRubrica INTEGER;

    vNuIsentaRubIRRF NUMBER(13, 2);

    vNuIsentaRubINSS NUMBER(13, 2);

    vNuIsentaRubIPREV NUMBER(13, 2);

    vNuIsentaRubFormula NUMBER(13, 2);

    -- Solicitacao de Sustentacao #65575
    -- Solicitacao 8130/2016 - SEA - Servidores com decisao judicial para isencao total de IRRF,
    -- porem sem laudo de molestia grave X Geracao da rubrica 09-0943 - DEDUCAO PARA O IRRF
    -- Quando a isencao for na rubrica 05-0516

    vNuIsentaRubDescIRRF NUMBER(13, 2) := 0;
    
    vNuIsencaoPercialIPREV NUMBER(13,2) := 0;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    bDescRubIsentaDescIRRF   := FALSE;
    bDescRubIsentaFormula    := FALSE;
    bIsencaoPercialIPREV     := FALSE;
    /* Verifica se o vinculo possui registros na tabela de rubricas isentas para o vinculo */

    SELECT TR.CdIsencaoRubrica
      INTO vCdIsencaoRubrica
      FROM ETrbIsencaoRubrica TR
     WHERE TR.CdVinculo = pCdVinculo
       AND ROWNUM < 2;

    -- Caso possua seta as variaveis  bDescRubIsentaIRRF, bDescRubIsentaINSS, bDescRubIsentaIPREV que
    -- indicarao se e necessario somar os valores destas rubricas para descontar das bases

    SELECT SUM(CASE
                 WHEN TR.FlRubricaIsentaIRRF = 'S' THEN
                  1
                 ELSE
                  0
               END),
           SUM(CASE
                 WHEN TR.FlRubricaIsentaINSS = 'S' THEN
                  1
                 ELSE
                  0
               END),
           SUM(CASE
                 WHEN TR.FlRubricaIsentaIPESC = 'S' THEN
                  1
                 ELSE
                  0
               END),
           SUM(CASE
                 WHEN TR.FlRubricaIsentaFormula = 'S' THEN
                  1
                 ELSE
                  0
               END),
           SUM(CASE
                 WHEN tr.cdrubricaagrupamento =
                      XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF AND
                      TR.FlRubricaIsentaIRRF = 'S' THEN
                  1
                 ELSE
                  0
               END),
            SUM(CASE
                 WHEN tr.cdrubricaagrupamento =
                      XTMPAG_VAR.vgParamPagamento.CdRubricaAgrupDescIPESC AND
                      TR.FlRubricaIsentaIPESC = 'S' THEN
                  1
                 ELSE
                  0
               END)    
      INTO vNuIsentaRubIRRF,
           vNuIsentaRubINSS,
           vNuIsentaRubIPREV,
           vNuIsentaRubFormula,
           vNuIsentaRubDescIRRF,
           vNuIsencaoPercialIPREV
      FROM ETrbIsencaoRubrica TR
     INNER JOIN ETrbHistIsencaoRubrica HTR
        ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
     WHERE TR.CdVinculo = pCdVinculo
       AND ((HTR.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
           (HTR.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
           HTR.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
           (HTR.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
           (HTR.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
           HTR.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
           HTR.NuMesFimVigencia IS NULL));

    IF vNuIsentaRubIRRF > 0 THEN

      bDescRubIsentaIRRF := TRUE;

    END IF;

    IF vNuIsentaRubINSS > 0 THEN

      bDescRubIsentaINSS := TRUE;

    END IF;

    IF vNuIsentaRubIPREV > 0 THEN

      bDescRubIsentaIPREV := TRUE;

    END IF;

    IF vNuIsentaRubFormula > 0 THEN

      bDescRubIsentaFormula := TRUE;

    END IF;

    IF vNuIsentaRubDescIRRF > 0 THEN

      bDescRubIsentaDescIRRF := TRUE;

    END IF;
    
    IF vNuIsencaoPercialIPREV > 0 THEN

      bIsencaoPercialIPREV := TRUE;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      bDescRubIsentaINSS := FALSE;

      bDescRubIsentaIRRF := FALSE;

      bDescRubIsentaIPREV := FALSE;

      bDescRubIsentaFormula := FALSE;

      bDescRubIsentaDescIRRF := FALSE;
      
      bIsencaoPercialIPREV := FALSE;

    WHEN OTHERS THEN

      bDescRubIsentaINSS := FALSE;

      bDescRubIsentaIRRF := FALSE;

      bDescRubIsentaIPREV := FALSE;

      bDescRubIsentaFormula := FALSE;

      bDescRubIsentaDescIRRF := FALSE;
      
      bIsencaoPercialIPREV := FALSE;

  END;

  --
  -- Monta variavel para executar formula de uma rubrica e retornar o valor calculado
  --

  Procedure pExecutaFormulaRegimePrev(pCdVinculo            IN INTEGER,
                                      pCdRubricaAgrupamento IN INTEGER,
                                      pCdFolhaPagamento     IN INTEGER,
                                      pCalculaBasePatronal  IN BOOLEAN DEFAULT FALSE) IS

    vCdExpressaoFormCalc INTEGER;
    --vPagCalc XTMPAG_tipo.rPagCalc;
    vValor NUMBER(13, 2);
    --vformexpr XTMPAG_tipo.rformulacalculo;
    vVlIndiceRub      Number(13, 4);
    vVlLancFinanceiro Number(13, 4) := 0;
    vVMPSCPREV        NUMBER(13, 4);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                   pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                                   pCdRelacaoVinculo     => XTMPAG_var.vgCEF(1).CdRelacaoVinculo);

    IF nvl(vCdExpressaoFormCalc, 0) > 0 THEN

      vVlIndiceRub := 0;

      SELECT vlindice, vllancamentofinanceiro
        INTO vvlindicerub, vvllancfinanceiro
        FROM (SELECT lf.vlindice, lf.vllancamentofinanceiro
                FROM epaglancamentofinanceiro lf
               WHERE lf.cdvinculo = pcdvinculo
                 AND lf.cdrubricaagrupamento = pcdrubricaagrupamento
                 AND lf.nusufixorubrica = 1
               ORDER BY lf.dtiniciodireito DESC)
       WHERE rownum < 2;

      DELETE epaghistoricorubricarelvinc hrv1
       WHERE hrv1.cdvinculo = pcdvinculo
         AND hrv1.cdfolhapagamento = XTMPAG_var.vgfolha.cdfolhapagamento
         AND hrv1.cdrubricaagrupamento = pcdrubricaagrupamento;

      DELETE epaghistoricorubricavinculo hrv
       WHERE hrv.cdvinculo = pcdvinculo
         AND hrv.cdfolhapagamento = XTMPAG_var.vgfolha.cdfolhapagamento
         AND hrv.cdrubricaagrupamento = pcdrubricaagrupamento;

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                            pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 1,
                                            pVlIndice             => vVlIndiceRub,
                                            pCdTipoOrigemRubrica  => 1);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => pCdRubricaAgrupamento,
                                       pTpProcessamento => 1,
                                       pTpLocal         => 2);

      vVMPSCPREV := XTMPAG_PARAM.FValorReferencia('VMP SCPREV');

      -- Caso não possua lançamento financeiro calcula o SCPREV
      IF NOT
          XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                             XTMPAG_VAR.vgFolha,
                                             XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                          5,
                                                                          1925)) and
         XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                      5,
                                      1925) = pCdRubricaAgrupamento THEN
        IF pCalculaBasePatronal THEN

          vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                         pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                                                               9,
                                                                                                                               1925),
                                                                         pCdRelacaoVinculo     => XTMPAG_var.vgCEF(1).CdRelacaoVinculo);

          DELETE EPAGHISTORICORUBRICARELVINC HRV1
           WHERE HRV1.CdVinculo = pCdVinculo
             AND HRV1.CdFolhaPagamento =
                 XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV1.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                              9,
                                              1925);

          DELETE EPAGHISTORICORUBRICAVINCULO HRV
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                              9,
                                              1925);

          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                                      9,
                                                                                                      1925),
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 10);

          XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                           pCdVinculo       => pCdVinculo,
                                           pCdRubrica       => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                            9,
                                                                                            1925),
                                           pTpProcessamento => 2, -- Processa base de c?lculo
                                           pTpLocal         => 2);

        ELSE

          DELETE EPAGHISTORICORUBRICAVINCULO HRV
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                              9,
                                              1925);

          DELETE EPAGHISTORICORUBRICARELVINC HRV1
           WHERE HRV1.CdVinculo = pCdVinculo
             AND HRV1.CdFolhaPagamento =
                 XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV1.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                              9,
                                              1925);

        END IF;

      ELSIF NVL(vVlLancFinanceiro, 0) > 0 THEN

        UPDATE EPAGHISTORICORUBRICAVINCULO HRV
           SET HRV.Vlpagamento = vVlLancFinanceiro
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento in
               (pCdRubricaAgrupamento,
                XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                             9,
                                             1925));

        UPDATE EPAGHISTORICORUBRICARELVINC HRV1
           SET HRV1.vlProporcional = vVlLancFinanceiro,
               HRV1.vlReal         = vVlLancFinanceiro,
               HRV1.vlIntegral     = vVlLancFinanceiro
         WHERE HRV1.CdVinculo = pCdVinculo
           AND HRV1.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
           AND HRV1.CdRubricaAgrupamento in
               (pCdRubricaAgrupamento,
                XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                             9,
                                             1925));

        UPDATE EPAGHISTORICORUBRICAVINCULO HRV
           SET HRV.Vlpagamento = vVlLancFinanceiro,
               HRV.deexpressao = vVlLancFinanceiro * 100 / vVlIndiceRub ||
                                 ' * ' || vVlIndiceRub || ' /100'
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento in
               (pCdRubricaAgrupamento,
                XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                             5,
                                             1925));

        UPDATE EPAGHISTORICORUBRICARELVINC HRV1
           SET HRV1.vlProporcional = vVlLancFinanceiro,
               HRV1.vlReal         = vVlLancFinanceiro,
               HRV1.vlIntegral     = vVlLancFinanceiro
         WHERE HRV1.CdVinculo = pCdVinculo
           AND HRV1.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
           AND HRV1.CdRubricaAgrupamento in
               (pCdRubricaAgrupamento,
                XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                             5,
                                             1925));
      else
        null;
      END IF;
      -- APLICA VALOR MINIMO SCPREV

      vValor := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                  pcdvinculo        => pcdvinculo,
                                                  pcdrubrica        => pCdRubricaAgrupamento);
      IF vVMPSCPREV IS NOT NULL THEN

        if vValor > 0 and vValor < vVMPSCPREV then

          UPDATE EPAGHISTORICORUBRICAVINCULO HRV
             SET HRV.Vlpagamento = vVMPSCPREV
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento;

          UPDATE EPAGHISTORICORUBRICARELVINC HRV1
             SET HRV1.VLPROPORCIONAL = vVMPSCPREV
           WHERE HRV1.CdVinculo = pCdVinculo
             AND HRV1.CdFolhaPagamento =
                 XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV1.CdRubricaAgrupamento = pCdRubricaAgrupamento;

        end if;

        if NOT
            XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                               XTMPAG_VAR.vgFolha,
                                               XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                            9,
                                                                            1925)) and
           (XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                              pcdvinculo        => pcdvinculo,
                                              pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                                9,
                                                                                                1925)) <
           vVMPSCPREV) then
          UPDATE EPAGHISTORICORUBRICAVINCULO HRV
             SET HRV.Vlpagamento = vVMPSCPREV
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                              9,
                                              1925);

          UPDATE EPAGHISTORICORUBRICARELVINC HRV1
             SET HRV1.VLPROPORCIONAL = vVMPSCPREV
           WHERE HRV1.CdVinculo = pCdVinculo
             AND HRV1.CdFolhaPagamento =
                 XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV1.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                              9,
                                              1925);

        end if;

      END IF;

      IF NOT
          XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                             XTMPAG_VAR.vgFolha,
                                             XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                          9,
                                                                          1925)) THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                          9,
                                                                                          1925),
                                         pTpProcessamento => 2, -- Processa base de c?lculo
                                         pTpLocal         => 2);

      END IF;

    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      NULL;

  END;

  PROCEDURE PCalculaBaseDeducaoIRRFSCPREV(pCdVinculo IN INTEGER) IS

    vCdRubricaAgrupamento INTEGER;
    --vCdExpressaoFormCalc  INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCdRubricaAgrupamento := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                          9,
                                                          9908);

    IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
    END IF;

    if (XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                        5,
                                                                        1925)) or
       XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                        5,
                                                                        1926)) or
       XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                        5,
                                                                        1927)) or
       XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                        5,
                                                                        1928)) or
       (XTMPAG_var.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13) and
       (XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                            pcdvinculo        => pcdvinculo,
                                            pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                              5,
                                                                                              1931)) > 0 or
       XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                            pcdvinculo        => pcdvinculo,
                                            pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                              5,
                                                                                              1932)) > 0))) then

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.cdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 1);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => vCdRubricaAgrupamento,
                                       ptplocal         => 2,
                                       ptpprocessamento => 2);

    else
      return;

    end if;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN;

  END;

  PROCEDURE PCalculaPatronalSCPREV(pCdVinculo IN INTEGER) IS

    vCdRubricaAgrupamento INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCdRubricaAgrupamento := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,1925);

    IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
    END IF;

    if XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                         pcdvinculo        => pcdvinculo,
                                         pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                                5,
                                                                                                1925)) > 0 then

    --if XTMPAG_geral.fretornavalorrubrica(XTMPAG_var.vgFolha.CdFolhaPagamento,pcdvinculo,
   --                                      XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,5,1925)) > 0 then
      /*                                                                   or
       XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                        5,
                                                                        1926)) or
       XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                        5,
                                                                        1927)) or
       XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                        5,
                                                                        1928)) or
       (XTMPAG_var.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13) and
       (XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                            pcdvinculo        => pcdvinculo,
                                            pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                              5,
                                                                                              1931)) > 0 or
       XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                            pcdvinculo        => pcdvinculo,
                                            pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                              5,
                                                                                              1932)) > 0))) then
    */

      if XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                           pcdvinculo        => pcdvinculo,
                                           pcdrubrica        => vCdRubricaAgrupamento) = 0 then

         XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.cdFolhaPagamento,
                                               pCdVinculo            => pCdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => 0,
                                               pVlIndice             => NULL,
                                               pCdTipoOrigemRubrica  => 1);

      end if;

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => vCdRubricaAgrupamento,
                                       ptplocal         => 2,
                                       ptpprocessamento => 2);

    else
      return;

    end if;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN;

  END;

  PROCEDURE PCalculaDeducaoIRRFSCPREV(pCdVinculo IN INTEGER) IS

    vCdRubricaAgrupamento INTEGER;
    --vCdExpressaoFormCalc  INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIRRF13,
                                     pTpProcessamento => 2,
                                     pTpLocal         => 2);

    -- Verifica se gerou Base Deducao IRRF SCPREV: somEnte gera a 09-1025 se gerou a 09-9908
    IF NVL(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo,
                                             XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                          9,
                                                                          9908)),
           0) <= 0 THEN
      RETURN;
    END IF;

    -- Gera a 09-1025
    vCdRubricaAgrupamento := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                          9,
                                                          1025);

    IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
    END IF;

    delete epaghistoricorubricavinculo hv
     where hv.cdvinculo = pCdVinculo
       and hv.cdfolhapagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
       and hv.cdrubricaagrupamento =
           XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                        9,
                                        1025);

    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.cdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => 0,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

    XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => vCdRubricaAgrupamento,
                                     ptplocal         => 2,
                                     ptpprocessamento => 2);

  EXCEPTION
    WHEN OTHERS THEN
      RETURN;

  END;

  PROCEDURE PCalculaBaseDeducIRRFSCPREV13(pCdVinculo IN INTEGER) IS

    vCdRubricaAgrupamento INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCdRubricaAgrupamento := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                          9,
                                                          9909);

    IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
    END IF;

    IF (XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                          pcdvinculo        => pcdvinculo,
                                          pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                            5,
                                                                                            1931)) > 0 OR
       XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                          pcdvinculo        => pcdvinculo,
                                          pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                            5,
                                                                                            1932)) > 0) THEN

      IF XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                           pcdvinculo        => pcdvinculo,
                                           pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                             9,
                                                                                             9909)) = 0 THEN
                                                                                             
          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.cdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

          XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                           pCdVinculo       => pCdVinculo,
                                           pCdRubrica       => vCdRubricaAgrupamento,
                                           ptplocal         => 2,
                                           ptpprocessamento => 2);
      END IF;
      
    ELSE
      
     
      XTMPAG_TRIBUTACAO.PExcluirRubricaDoContraCheque(pCdVinculo,
                                                      XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                      XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                   9,
                                                                                   9909));                                                                                   
  
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN;

  END;

  PROCEDURE PCalculaDeducaoIRRFSCPREV13(pCdVinculo IN INTEGER) IS

    vCdRubricaAgrupamento INTEGER;

    vVlBase XTMPAG_tipo.rValorPagamento;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIRRF13,
                                     pTpProcessamento => 2,
                                     pTpLocal         => 2);

    -- Verifica se gerou Base Deducao IRRF SCPREV: somEnte gera a 09-1045 se gerou a 09-9909
    IF NVL(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                             pCdVinculo,
                                             XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                          9,
                                                                          9909)),
           0) <= 0 THEN
      RETURN;
    END IF;

    -- Gera a 09-1045
    vCdRubricaAgrupamento := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                          9,
                                                          1045);

    IF NVL(vCdRubricaAgrupamento, 0) = 0 THEN
      RETURN;
    END IF;

    vvlBase := XTMPAG_FB.FRetornaValorBaseCalculo(pfolha            => XTMPAG_VAR.vgFolha,
                                                  pcdvinculo        => pCdVinculo,
                                                  pcdtipohistorico  => 2,
                                                  pcdrelacaovinculo => 0,
                                                  pcdbasecalculo    => XTMPAG_var.vgrubrica(vCdRubricaAgrupamento).cdbasecalculo,
                                                  pcdchave          => pCdVinculo);

    delete epaghistoricorubricavinculo hv
     where hv.cdvinculo = pCdVinculo
       and hv.cdfolhapagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
       and hv.cdrubricaagrupamento =
           XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                        9,
                                        1045);

    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.cdFolhaPagamento,
                                          pCdVinculo            => pCdVinculo,
                                          pCdExpressaoFormCalc  => NULL,
                                          pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                          pNuSufixoRubrica      => 1,
                                          pVlPagamento          => 0,
                                          pVlIndice             => NULL,
                                          pCdTipoOrigemRubrica  => 1);

    XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => vCdRubricaAgrupamento,
                                     ptplocal         => 2,
                                     ptpprocessamento => 2);

  EXCEPTION
    WHEN OTHERS THEN
      RETURN;

  END;

  PROCEDURE PCalculaSCPREV13(pCdVinculo IN INTEGER) IS

    vCdRubBaseScprev13 INTEGER;
    --vCdExpressaoFormula integer;
    vVlIndiceRub number(10, 4) := 0;
    vVMPSCPREV   number(13, 4) := XTMPAG_PARAM.FValorReferencia('VMP SCPREV');

    vCdRubricaAgrupamento9_1925 integer;
    vCdRubricaAgrupamento5_1925 integer;
    vCdRubricaAgrupamento5_1927 integer;
    vCdRubricaAgrupamento9_920  integer;
    vValorRubrica9_920          number;
    vCdRegimeProprioPrev        integer;
    vAliquotaINSS               XTMPAG_tipo.rAliquotaINSS;
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    --
    -- Verificar optantes do SCPREV
    --
    -- Fundo Financeiro LC 662/15
    --
    vCdRegimeProprioPrev := XTMPAG_tributacao.FRetornaRegimeProprioPrev(pCdVinculo);
    vAliquotaINSS        := XTMPAG_VAR.vAliqINSS;

    vCdRubricaAgrupamento9_920 := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                               9,
                                                               920);
    vValorRubrica9_920         := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                                    pcdvinculo        => pCdVinculo,
                                                                    pcdrubrica        => vCdRubricaAgrupamento9_920);
    IF (vCdRegimeProprioPrev = 3 AND
       vValorRubrica9_920 > vAliquotaINSS.VlTeto) THEN
      vValorRubrica9_920 := vAliquotaINSS.VlTeto;
      XTMPAG_TRIBUTACAO.PAtualizarValorPgtoRubrica(pCdVinculo            => pCdVinculo,
                                                   pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                   pCdRubricaAgrupamento => vCdRubricaAgrupamento9_920,
                                                   pValorPagamento       => vValorRubrica9_920);
    END IF;

    vCdRubBaseScprev13 := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                       9,
                                                       963);
    XTMPAG_TRIBUTACAO.PProcessarBase13SCPrev(pCdRegimeProprioPrev           => vCdRegimeProprioPrev,
                                             pFolha                         => XTMPAG_var.vgFolha,
                                             pFormExpr                      => XTMPAG_var.vgFormExpr,
                                             pCdVinculo                     => pCdVinculo,
                                             pCdFolhaPagamento              => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                             pCdAgrupamento                 => XTMPAG_var.vgFolha.CdAgrupamento,
                                             pValorMinimoContribuicaoSCPREV => vVMPSCPREV,
                                             pValorTetoINSS                 => vAliquotaINSS.VlTeto,
                                             pValorRubrica9_920             => vValorRubrica9_920);

    --Não entendi o motivo da exclusão
    vCdRubricaAgrupamento9_1925 := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                9,
                                                                1925);
    XTMPAG_TRIBUTACAO.PExcluirRubricaDoContraCheque(pCdVinculo,
                                                    XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                    vCdRubricaAgrupamento9_1925);

    case
      when vCdRegimeProprioPrev in (1, 3, 4) then
        vCdRubricaAgrupamento5_1925 := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                    5,
                                                                    1925);

        vVlIndiceRub := XTMPAG_TRIBUTACAO.FObterValorIndiceRubrica(pCdVinculo,
                                                                   vCdRubricaAgrupamento5_1925,
                                                                   XTMPAG_var.vgFolha.DtInicioMes,
                                                                   XTMPAG_var.vgFolha.dtFimMes,
                                                                   XTMPAG_TIPO.cnN);

        IF nvl(vCdRubBaseScprev13, 0) > 0 AND nvl(vVlIndiceRub, 0) > 0 THEN
          XTMPAG_TRIBUTACAO.PProcessarRubricaSCPREV13(pFolha                         => XTMPAG_var.vgFolha,
                                                      pFormExpr                      => XTMPAG_var.vgFormExpr,
                                                      pCdVinculo                     => pCdVinculo,
                                                      pCdFolhaPagamento              => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                      pCdAgrupamento                 => XTMPAG_var.vgFolha.CdAgrupamento,
                                                      pCdTipoRubrica                 => 5,
                                                      pNuRubrica                     => 1931,
                                                      pTpProcessamento               => 1,
                                                      pValorIndiceRubrica            => vVlIndiceRub,
                                                      pValorMinimoContribuicaoSCPREV => vVMPSCPREV);

          XTMPAG_TRIBUTACAO.PProcessarRubricaSCPREV13(pFolha                         => XTMPAG_var.vgFolha,
                                                      pFormExpr                      => XTMPAG_var.vgFormExpr,
                                                      pCdVinculo                     => pCdVinculo,
                                                      pCdFolhaPagamento              => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                      pCdAgrupamento                 => XTMPAG_var.vgFolha.CdAgrupamento,
                                                      pCdTipoRubrica                 => 9,
                                                      pNuRubrica                     => 1935,
                                                      pTpProcessamento               => 2,
                                                      pValorIndiceRubrica            => null,
                                                      pValorMinimoContribuicaoSCPREV => vVMPSCPREV,
                                                      pCdTipoOrigemRubrica           => 10);
        END IF;

        vCdRubricaAgrupamento5_1927 := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                    5,
                                                                    1927);
        vVlIndiceRub                := XTMPAG_TRIBUTACAO.FObterValorIndiceRubrica(pCdVinculo,
                                                                                  vCdRubricaAgrupamento5_1927,
                                                                                  XTMPAG_var.vgFolha.DtInicioMes,
                                                                                  XTMPAG_var.vgFolha.dtFimMes,
                                                                                  XTMPAG_TIPO.cnN);

        IF nvl(vCdRubBaseScprev13, 0) > 0 AND nvl(vVlIndiceRub, 0) > 0 THEN
          XTMPAG_TRIBUTACAO.PProcessarRubricaSCPREV13(pFolha                         => XTMPAG_var.vgFolha,
                                                      pFormExpr                      => XTMPAG_var.vgFormExpr,
                                                      pCdVinculo                     => pCdVinculo,
                                                      pCdFolhaPagamento              => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                      pCdAgrupamento                 => XTMPAG_var.vgFolha.CdAgrupamento,
                                                      pCdTipoRubrica                 => 5,
                                                      pNuRubrica                     => 1932,
                                                      pTpProcessamento               => 1,
                                                      pValorIndiceRubrica            => vVlIndiceRub,
                                                      pValorMinimoContribuicaoSCPREV => vVMPSCPREV);
        END IF;

        IF (vCdRegimeProprioPrev = 1) THEN
          XTMPAG_TRIBUTACAO.PExcluirRubricaDoContraCheque(pCdVinculo,
                                                          XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                          vCdRubBaseScprev13);
        END IF;
    end case;

    PCalculaDeducaoIRRFSCPREV(pCdVinculo);

  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  PROCEDURE PCalculaBaseEstendidaSCPREV(pCdVinculo IN INTEGER) IS

    vCdRubBaseScprev       INTEGER;
    vvlBaseEstendidaScPrev XTMPAG_tipo.rvalorpagamento;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    --------------------------------------------------------------------------------------------------------------
    -- SIG-7952 INCONSISTENCIA NO CALCULO DA RUBRICA 05-1925
    -- Base estendida so deve ser gerada para quem tem lancamento financeiro da rubrica 09-0962
    -- caso contrario nao inclui a base estendida do SCPREV

    vCdRubBaseScprev := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                     9,
                                                     962);

    --------------------------------------------------------------------------------------------------------------

    IF (XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                           XTMPAG_VAR.vgFolha,
                                           vCdRubBaseScprev) and
       to_char(XTMPAG_var.vgfolha.DtCalculo, 'yyyymm') >= 202203) or
       to_char(XTMPAG_var.vgfolha.DtCalculo, 'yyyymm') < 202203 THEN

      --
      -- Verificar optantes do SCPREV
      --

      IF NVL(vCdRubBaseScprev, 0) > 0 AND
         (XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                             XTMPAG_VAR.vgFolha,
                                             vCdRubBaseScprev) OR
          XTMPAG_var.vgcef.Count > 0) THEN

        IF XTMPAG_var.vgcco.Count = 0 AND XTMPAG_var.vgfuc.count = 0

         THEN

          DELETE EPAGHISTORICORUBRICAVINCULO HRV
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento = vCdRubBaseScprev;

          DELETE EPAGHISTORICORUBRICARELVINC HRV1
           WHERE HRV1.CdVinculo = pCdVinculo
             AND HRV1.CdFolhaPagamento =
                 XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev;

        ELSE

          vvlBaseEstendidaScPrev.vlProporcional := 0;

          vvlBaseEstendidaScPrev.vlIntegral := 0;

          vvlBaseEstendidaScPrev := XTMPAG_FB.FRetornaValorBaseCalculo(pfolha            => XTMPAG_VAR.vgFolha,
                                                                       pcdvinculo        => pCdVinculo,
                                                                       pcdtipohistorico  => 2,
                                                                       pcdrelacaovinculo => 0,
                                                                       pcdbasecalculo    => XTMPAG_var.vgrubrica(vCdRubBaseScprev).cdbasecalculo, --vcdbasecalculo,
                                                                       pcdchave          => pCdVinculo);

          IF vvlBaseEstendidaScPrev.vlIntegral > 0 -- vvlBaseEstendidaScPrev.vlProporcional > 0
           THEN

            UPDATE EPagHistoricoRubricaVinculo HRV
               SET HRV.vlPagamento = vvlBaseEstendidaScPrev.vlIntegral
             WHERE HRV.CdVinculo = pCdVinculo
               AND HRV.CdFolhaPagamento =
                   XTMPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento = vCdRubBaseScprev;

            UPDATE EPAGHISTORICORUBRICARELVINC HRV1
               SET HRV1.vlProporcional     = vvlBaseEstendidaScPrev.vlIntegral,
                   HRV1.vlReal             = vvlBaseEstendidaScPrev.vlIntegral,
                   HRV1.vlIntegral         = vvlBaseEstendidaScPrev.vlintegral,
                   HRV1.Cdhistcargoefetivo = XTMPAG_var.vgcef(1).CdHistCargoEfetivo,
                   HRV1.CdChave            = hrv1.cdhistcargocom
             WHERE HRV1.CdVinculo = pCdVinculo
               AND HRV1.CdFolhaPagamento =
                   XTMPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev
               AND HRV1.Cdhistcargocom IS NOT NULL;

            DELETE EPAGHISTORICORUBRICARELVINC HRV1
             WHERE HRV1.CdVinculo = pCdVinculo
               AND HRV1.CdFolhaPagamento =
                   XTMPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev
               AND HRV1.CDHISTCARGOEFETIVO IS NOT NULL
               AND HRV1.Cdhistcargocom IS NULL;

          END IF;

        END IF;

      END IF;
    else

      DELETE EPAGHISTORICORUBRICAVINCULO HRV
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = vCdRubBaseScprev;

      DELETE EPAGHISTORICORUBRICARELVINC HRV1
       WHERE HRV1.CdVinculo = pCdVinculo
         AND HRV1.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
         AND HRV1.CdRubricaAgrupamento = vCdRubBaseScprev;

    end if;

  END;

  -- Verifica se está passou a receber acima do teto no mês
  FUNCTION FUltrapassouTetoRGPSnoMes(pCdVinculo IN INTEGER,
                                     pfolha     IN XTMPAG_tipo.rfolha)
    RETURN BOOLEAN IS

    vCdRubBase            INTEGER := 0;
    vCdBaseCalculo        INTEGER := 0;
    vVlBase               XTMPAG_tipo.rvalorpagamento;
    vRecebeuRubricaMesAnt NUMBER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vCdRubBase := XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                               9,
                                               0961);

    -- Se gerou rubrica 09-0961 no mês anterior, siginifica que já estava acima do teto,
    -- então não deve considerar
    vRecebeuRubricaMesAnt := XTMPAG_geral.frecebeurubrica(pcdvinculo    => pCdVinculo,
                                                          pcdrubrica    => vCdRubBase,
                                                          pnuanomes     => pfolha.NuAnoReferencia * 100 +
                                                                           pfolha.NuMesReferencia,
                                                          pnumeses      => 1,
                                                          pcdfolhaatual => pfolha.CdFolhaPagamento);
    IF vRecebeuRubricaMesAnt > 0 THEN
      RETURN FALSE;
    END IF;

    -- Verifica
    vCdBaseCalculo := XTMPAG_var.vgrubrica(vCdRubBase).cdbasecalculo;

    vVlBase := XTMPAG_FB.FRetornaValorBaseCalculo(pfolha            => pfolha,
                                                  pcdvinculo        => pCdVinculo,
                                                  pcdtipohistorico  => 2,
                                                  pcdrelacaovinculo => 0,
                                                  pcdbasecalculo    => vCdBaseCalculo,
                                                  pcdchave          => pCdVinculo);

    IF NVL(vVlBase.vlProporcional, 0) > 0 THEN
      RETURN TRUE;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END;

  PROCEDURE PFundoFinanceiroAutomatico(pCdVinculo IN INTEGER,
                                       pfolha     IN XTMPAG_tipo.rfolha) IS

    vCdRubricaAgrupagmento INTEGER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    -- Implementa fundo financeiro acima do teto apenas para ingressantes
    -- ou para servidores que ultrapassaram teto no mês

    -- Só implementa regra quando rodar folha NORMAL
    IF NOT (pfolha.CdTipoFolha = 1 AND pfolha.cdtipocalculo = 1) THEN
      RETURN;
    END IF;

    -- Se não possui remuneração acima do teto, retorna
    IF NOT
        FUltrapassouTetoRGPSnoMes(pCdVinculo => pCdVinculo, pfolha => pfolha) THEN
      RETURN;
    END IF;

    vCdRubricaAgrupagmento := XTMPAG_geral.fretornarubrica(pfolha.CdAgrupamento,
                                                           5,
                                                           1925);

    -- Se já tem a rubrica lançada em financeiro, retorna
    IF XTMPAG_geral.fpossuilancfinanceiro(pcdvinculo        => pCdVinculo,
                                          pfolha            => pfolha,
                                          pcdrubrica        => vCdRubricaAgrupagmento,
                                          pIncluiFinalizado => 'S') THEN
      RETURN;
    END IF;

    -- Insere rubrica em financeiro
    INSERT INTO epaglancamentofinanceiro
      (CDLANCAMENTOFINANCEIRO,
       CDVINCULO,
       NUSUFIXORUBRICA,
       DTINICIODIREITO,
       FLVALORPROPORCIONAL,
       FLPAGAAFASTDEFINITIVO,
       NUCPFCADASTRADOR,
       DTINCLUSAO,
       DTULTALTERACAO,
       FLDECISAOJUDICIAL,
       FLFOLHASUPLEMENTAR,
       VLINDICE,
       FLANULADO,
       CDRUBRICAAGRUPAMENTO,
       INPERIODICIDADE,
       FLACERTOAUTO13SAL,
       FLPROPDEMITIDONOMES,
       FLPAGAAFASTTEMPSEMREMUN,
       FLAUTOMATICO)
    VALUES
      (spaglancamentofinanceiro.nextval,
       pCdVinculo,
       1,
       trunc(pfolha.DtCalculo, 'MM'),
       'N',
       'N',
       '11111111111',
       trunc(sysdate),
       trunc(sysdate),
       'N',
       'N',
       8,
       'N',
       vCdRubricaAgrupagmento,
       'Q',
       'N',
       'N',
       'N',
       'N');

    -- Finalizar rubrica 05-1927 do financeiro
    vCdRubricaAgrupagmento := XTMPAG_geral.fretornarubrica(pfolha.CdAgrupamento,
                                                           5,
                                                           1927);

    UPDATE EPAGLANCAMENTOFINANCEIRO LF
       SET LF.DTFIMDIREITO   = TRUNC(pfolha.DtCalculo, 'MM') - 1,
           LF.DTULTALTERACAO = TRUNC(SYSDATE)
     WHERE LF.CDVINCULO = pCdVinculo
       AND LF.CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupagmento;

    DELETE EPAGHISTORICORUBRICARELVINC HRV1
     WHERE HRV1.CdVinculo = pCdVinculo
       AND HRV1.CdFolhaPagamento = pfolha.CdFolhaPagamento
       AND HRV1.CdRubricaAgrupamento = vCdRubricaAgrupagmento;

    DELETE EPAGHISTORICORUBRICAVINCULO HRV
     WHERE HRV.CdVinculo = pCdVinculo
       AND HRV.CdFolhaPagamento = pfolha.CdFolhaPagamento
       AND HRV.CdRubricaAgrupamento = vCdRubricaAgrupagmento;

    -- Finalizar rubrica 05-1928 do financeiro
    vCdRubricaAgrupagmento := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                           5,
                                                           1928);

    UPDATE EPAGLANCAMENTOFINANCEIRO LF
       SET LF.DTFIMDIREITO   = trunc(pfolha.DtCalculo, 'MM') - 1,
           LF.DTULTALTERACAO = TRUNC(SYSDATE)
     WHERE LF.CDVINCULO = pCdVinculo
       AND LF.CDRUBRICAAGRUPAMENTO = vCdRubricaAgrupagmento;

    DELETE EPAGHISTORICORUBRICARELVINC HRV1
     WHERE HRV1.CdVinculo = pCdVinculo
       AND HRV1.CdFolhaPagamento = pfolha.CdFolhaPagamento
       AND HRV1.CdRubricaAgrupamento = vCdRubricaAgrupagmento;

    DELETE EPAGHISTORICORUBRICAVINCULO HRV
     WHERE HRV.CdVinculo = pCdVinculo
       AND HRV.CdFolhaPagamento = pfolha.CdFolhaPagamento
       AND HRV.CdRubricaAgrupamento = vCdRubricaAgrupagmento;

  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  PROCEDURE PCalculaFundoFinanceiro(pCdVinculo IN INTEGER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    CASE
    --
    -- Fundo Financeiro LC 662/15
    --
      WHEN XTMPAG_tributacao.FRetornaRegimeProprioPrev(pCdVinculo) in (3,4)

       THEN

        PFundoFinanceiroAutomatico(pCdVinculo => pCdVinculo,
                                   pFolha     => XTMPAG_VAR.vgFolha);

        IF XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                              XTMPAG_VAR.vgFolha,
                                              XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           9,
                                                                           1925)) then

          DELETE EPAGHISTORICORUBRICARELVINC HRV1
           WHERE HRV1.CdVinculo = pCdVinculo
             AND HRV1.CdFolhaPagamento =
                 XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV1.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                              9,
                                              1925)
             AND HRV1.Cdtipoorigemrubrica <> 2;

          DELETE EPAGHISTORICORUBRICAVINCULO HRV
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                              9,
                                              1925)
             AND HRV.Cdtipoorigemrubrica <> 2;

        END IF;

        IF XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                              XTMPAG_VAR.vgFolha,
                                              XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           5,
                                                                           1925)) THEN

          pExecutaFormulaRegimePrev(pCdVinculo,
                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                 5,
                                                                 1925),
                                    XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                    TRUE);

        END IF;

        IF XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                              XTMPAG_VAR.vgFolha,
                                              XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           5,
                                                                           1926)) THEN

          pExecutaFormulaRegimePrev(pCdVinculo,
                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                 5,
                                                                 1926),
                                    XTMPAG_VAR.vgFolha.CdFolhaPagamento);

        END IF;

        IF XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                              XTMPAG_VAR.vgFolha,
                                              XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           5,
                                                                           1927)) THEN

          pExecutaFormulaRegimePrev(pCdVinculo,
                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                 5,
                                                                 1927),
                                    XTMPAG_VAR.vgFolha.CdFolhaPagamento);

        END IF;

        IF XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                              XTMPAG_VAR.vgFolha,
                                              XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           5,
                                                                           1928)) THEN

          pExecutaFormulaRegimePrev(pCdVinculo,
                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                 5,
                                                                 1928),
                                    XTMPAG_VAR.vgFolha.CdFolhaPagamento);

        END IF;

    --
    -- Fundo Financeiro
    --
      WHEN XTMPAG_tributacao.FRetornaRegimeProprioPrev(pCdVinculo) = 1

       THEN

        IF XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                              XTMPAG_VAR.vgFolha,
                                              XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           5,
                                                                           1927)) THEN

          pExecutaFormulaRegimePrev(pCdVinculo,
                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                 5,
                                                                 1927),
                                    XTMPAG_VAR.vgFolha.CdFolhaPagamento);

        END IF;

        IF XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                              XTMPAG_VAR.vgFolha,
                                              XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           5,
                                                                           1928)) THEN

          pExecutaFormulaRegimePrev(pCdVinculo,
                                    XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                 5,
                                                                 1928),
                                    XTMPAG_VAR.vgFolha.CdFolhaPagamento);

        END IF;

        DELETE EPAGHISTORICORUBRICARELVINC HRV1
         WHERE HRV1.CdVinculo = pCdVinculo
           AND HRV1.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
           AND HRV1.CdRubricaAgrupamento in
               (XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                             5,
                                             1925),
                XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                             5,
                                             1926));

        DELETE EPAGHISTORICORUBRICAVINCULO HRV
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = XTMPAG_VAR.vgFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento in
               (XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                             5,
                                             1925),
                XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                             5,
                                             1926));

      ELSE

        NULL;

    END CASE;

  END;

  /*-----------------------------------------------------------------------------------------/
    Procedure  : PCalculaFGTS

      Objetivo : Separar o FGTS do INSS, antes dentro da rotina do INSS era feito o FGTS
                 sao independentes visto que alguem que ja tenha recolhido o INSS pelo teto
                 em um outro agrupamento pode ter direito ao FGTS em outro.
      Solicitacao de Sustentacao #69392
      8654/2016 - GFIP - - SERVIDOR CELETISTA SEM FGTS NO 1056
  /-----------------------------------------------------------------------------------------*/

  PROCEDURE pCalculaFGTS(pFolha     IN XTMPAG_TIPO.rFolha,
                         pCdVinculo IN INTEGER) IS

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    -- CALCULA FGTS
    IF ((XTMPAG_VAR.vgVinculo.CdRegimeTrabalho = XTMPAG_TIPO.cnRegTrabCLT) or
       -- Excecao CIDASC Presidente SIG-5839
       (XTMPAG_VAR.vgVinculo.CdRegimeTrabalho = 6 and pFolha.CdORgao = 25)) AND
       XTMPAG_VAR.vgDtOpcaoFGTS IS NOT NULL THEN

      if XTMPAG_VAR.vgVinculo.CdRegimeTrabalho = 6 and pFolha.CdORgao = 25
        and ((pfolha.cdtipofolha = XTMPAG_TIPO.cnTpFolhaRescisao and vPassagens = 0 )
         or pFolha.cdtipofolha <> XTMPAG_TIPO.cnTpFolhaRescisao) then

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseFGTS,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubVlFGTS,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

      end if;

      IF XTMPAG_VAR.vgCdRubBaseFGTS IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseFGTS,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseFGTS13 IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseFGTS13,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/
      END IF;

      IF XTMPAG_VAR.vgCdRubVlFGTS IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubVlFGTS,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseProv13VlFGTS IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

      IF XTMPAG_VAR.vgCdRubVlFGTS13 IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubVlFGTS13,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/
      END IF;

      IF NOT (XTMPAG_VAR.vgFolha.CdOrgao = 27 AND
          XTMPAG_VAR.bVinculoComCCO = TRUE) THEN

        XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                    pCdVinculo        => pCdVinculo,
                                    pCdRubrica        => XTMPAG_VAR.vgCdRubricaBaseINSSPat,
                                    pFlExcluiAmbos    => 'S');
      END IF;

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                  pFlExcluiAmbos    => 'S');

      -- EXCLUI BASES DE FGTS
    ELSE

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseFGTS,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseFGTS13,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubVlFGTS,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubVlFGTS13,
                                  pFlExcluiAmbos    => 'S');

    END IF;

  END;

  FUNCTION FretornaVlSomaAnoRubrica(pCdVinculo IN INTEGER,
                                    pFolha     IN XTMPAG_TIPO.rFolha,
                                    pNuTipoRub IN INTEGER,
                                    pNuRubrica IN INTEGER) RETURN NUMBER IS
    VVL050546 NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT SUM(RV.VLPAGAMENTO)
      INTO VVL050546
      FROM EPAGHISTORICORUBRICAVINCULO RV
     INNER JOIN EPAGFOLHAPAGAMENTO FP
        ON FP.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
       AND FP.NUANOREFERENCIA = pFOlha.NuAnoReferencia
       AND FP.cdAgrupamento = pFolha.CdAgrupamento
       AND ((fp.cdtipofolhapagamento =
           XTMPAG_var.vgFolha.cdtipofolhapagamento AND
           fp.cdtipocalculo = XTMPAG_var.vgFolha.cdtipocalculo AND
           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'N' AND
           fp.flcalculodefinitivo IN ('S', 'N')) OR
           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S' AND
           fp.flcalculodefinitivo = 'S')) OR fp.flcalculodefinitivo = 'S')
       AND (/*FP.NUANOMESREFERENCIA =
           pfolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia OR*/
           (FP.CDTIPOFOLHAPAGAMENTO <>
           (SELECT TF.CDTIPOFOLHAPAGAMENTO
                FROM EPAGTIPOFOLHAPAGAMENTO TF
               WHERE TF.CDTIPOFOLHA = 3 --FOLHA DE 13
                 AND TF.CDAGRUPAMENTO = FP.CDAGRUPAMENTO))/* OR
           FP.NUANOMESREFERENCIA <>
           pfolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia*/)
     INNER JOIN VPAGRUBRICAAGRUPAMENTO RUB
        ON RUB.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO
       AND RUB.NURUBRICA IN (pNuRubrica)
       AND RUB.CDTIPORUBRICA = pNuTipoRub
     INNER JOIN ECADVINCULO V
        ON V.CDVINCULO = RV.CDVINCULO
       AND V.CDPESSOA IN (SELECT P.CDPESSOA
                            FROM SIGRH.ECADVINCULO V
                           INNER JOIN ECADPESSOA P
                              ON P.CDPESSOA = V.CDPESSOA
                           WHERE CDVINCULO = pCdVinculo)
     WHERE ((V.CDVINCULO <> pCdVinculo AND
           FP.CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento) OR
           FP.CDFOLHAPAGAMENTO <> pFolha.CdFolhaPagamento)
     ORDER BY FP.NUANOMESREFERENCIA DESC;

    RETURN NVL(VVL050546, 0);
  END;

  FUNCTION FretornaVlSomaAnoRubrica2(pCdVinculo IN INTEGER,
                                     pFolha     IN XTMPAG_TIPO.rFolha,
                                     pNuTipoRub IN INTEGER,
                                     pNuRubrica IN INTEGER) RETURN NUMBER IS
    VVL050546 NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT SUM(RV.VLPAGAMENTO)
      INTO VVL050546
      FROM EPAGHISTORICORUBRICAVINCULO RV
     INNER JOIN EPAGFOLHAPAGAMENTO FP
        ON FP.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
       AND FP.NUANOREFERENCIA = pFOlha.NuAnoReferencia
       AND FP.cdAgrupamento = pFolha.CdAgrupamento
       AND (/*(fp.cdtipofolhapagamento = XTMPAG_var.vgFolha.cdtipofolhapagamento AND fp.cdtipocalculo = XTMPAG_var.vgFolha.cdtipocalculo AND (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'N' AND
           fp.flcalculodefinitivo IN ('S', 'N')) OR
           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S' AND
           fp.flcalculodefinitivo = 'S')) OR*/ fp.flcalculodefinitivo = 'S' OR (fp.flcalculodefinitivo='N' AND fp.cdtipocalculo=1 AND (FP.NUANOMESREFERENCIA = pfolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia)))
     INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
        ON FP.CDTIPOFOLHAPAGAMENTO = TFP.CDTIPOFOLHAPAGAMENTO

     INNER JOIN VPAGRUBRICAAGRUPAMENTO RUB
        ON RUB.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO
       AND RUB.NURUBRICA IN (pNuRubrica)
       AND RUB.CDTIPORUBRICA = pNuTipoRub
     INNER JOIN ECADVINCULO V
        ON V.CDVINCULO = RV.CDVINCULO
       AND V.CDPESSOA IN (SELECT P.CDPESSOA
                            FROM SIGRH.ECADVINCULO V
                           INNER JOIN ECADPESSOA P
                              ON P.CDPESSOA = V.CDPESSOA
                           WHERE CDVINCULO = pCdVinculo)
     WHERE ((V.CDVINCULO <> pCdVinculo AND
           FP.CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento) OR
           FP.CDFOLHAPAGAMENTO <> pFolha.CdFolhaPagamento 
            and not (pFolha.CdTipoCalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes
                     and fp.cdtipocalculo = XTMPAG_tipo.cnTpCalculoNormal -- normal
                     and rv.cdvinculo =  pCdVinculo
                     and fp.nuanomesreferencia =  to_char(pFolha.DtInicioMes,'YYYYMM'))     )

           --Se folha definitiva, busca apenas outras definitivas.
           --Se folha normal, busca definitivas ou normais.
           AND
           ((FP.FLCALCULODEFINITIVO = 'S' AND pFolha.FlCalculoDefinitivo ='S') OR ((FP.FLCALCULODEFINITIVO IN ('N', 'S') AND pFolha.FlCalculoDefinitivo='N')))

           AND
           --Folhas de 13o
           (((pFolha.CdTipoFolha IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13) /*AND pFolha.NuMesReferencia <> 12*/)
            OR
             --Se folha 13o Dezembro, não pega folha 13o Novembro
           (pFolha.CdTipoFolha IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13)
              AND pFolha.NuMesReferencia = 12
              AND (FP.NUMESREFERENCIA <> 11 OR (FP.NUMESREFERENCIA = 11 AND TFP.Cdtipofolha NOT IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13))))
            )
             OR
           --Se folha diferente de 13o, não pega 13o do mesmo mês
            (pFolha.CdTipoFolha NOT IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13)
             AND
             (TFP.CDTIPOFOLHA NOT IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13)
              OR (TFP.CDTIPOFOLHA IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13)
                  AND FP.NUANOMESREFERENCIA = (pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia))))


     ORDER BY FP.NUANOMESREFERENCIA DESC;

    RETURN NVL(VVL050546, 0);
  END;

  FUNCTION fRetornaBaseOutraFolAberta(pCdVinculo IN INTEGER,
                                      pFolha     IN XTMPAG_TIPO.rFolha,
                                      pCdRubrica in integer) RETURN NUMBER IS

    vVlBase NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    SELECT SUM(RV.VLPAGAMENTO)
      INTO vVlBase
      FROM EPAGHISTORICORUBRICAVINCULO RV
     INNER JOIN EPAGFOLHAPAGAMENTO FP
        ON FP.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
       AND FP.cdAgrupamento = pFolha.CdAgrupamento
       AND fp.flcalculodefinitivo='N'
       AND fp.cdtipocalculo=1
       AND FP.NUANOMESREFERENCIA = pfolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
     INNER JOIN ECADVINCULO V
        ON V.CDVINCULO = RV.CDVINCULO
       AND V.CDPESSOA IN (SELECT P.CDPESSOA
                            FROM SIGRH.ECADVINCULO V
                           INNER JOIN ECADPESSOA P
                              ON P.CDPESSOA = V.CDPESSOA
                           WHERE CDVINCULO = pCdVinculo)
     WHERE V.CDVINCULO <> pCdVinculo
       AND rv.cdrubricaagrupamento = pCdRubrica
     ORDER BY FP.NUANOMESREFERENCIA DESC;

    RETURN NVL(vVlBase, 0);
  END;

  FUNCTION FretornaVlSomaAnoRubricaCalc13(pCdVinculo IN INTEGER,
                                          pFolha     IN XTMPAG_TIPO.rFolha,
                                          pNuTipoRub IN INTEGER,
                                          pNuRubrica IN INTEGER)
    RETURN NUMBER IS
    VVL050546 NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    WITH FOLHA13 AS
     (SELECT CDFOLHAPAGAMENTO
        FROM EPAGFOLHAPAGAMENTO FP
       INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
          ON TF.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
       WHERE TF.CDTIPOFOLHA IN (3, 20) -- 13SAL e 13 SAL CTISP
         AND FP.NUANOREFERENCIA = pFolha.NuAnoReferencia
         AND FP.FLCALCULODEFINITIVO = 'S'),

    FOLHA AS
     (SELECT CDFOLHAPAGAMENTO, FP.NUANOMESREFERENCIA, TF.CDTIPOFOLHA
        FROM EPAGFOLHAPAGAMENTO FP
       INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
          ON TF.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
       WHERE FP.NUANOREFERENCIA = pFolha.NuAnoReferencia
         AND FP.CDAGRUPAMENTO = pFolha.CdAgrupamento
         AND ((FP.FLCALCULODEFINITIVO = 'S') OR
             (pFolha.FlCalculoDefinitivo = 'N' AND
             FP.FLCALCULODEFINITIVO IN ('S', 'N') AND
             FP.NUMESREFERENCIA = 12) AND
             FP.CDTIPOCALCULO = PFOLHA.CDTIPOCALCULO)
         AND NOT
              (pFolha.NuMesReferencia = 12 AND
              FP.CDFOLHAPAGAMENTO IN (SELECT CDFOLHAPAGAMENTO FROM FOLHA13))),

    VINCULO AS
     (SELECT CDVINCULO,
             PKGUTIL.FFORMATAMATRICULA(NUMATRICULA,
                                       NUDVMATRICULA,
                                       NUSEQMATRICULA) MATRICULA
        FROM ECADVINCULO
       WHERE CDPESSOA IN
             (SELECT CDPESSOA FROM ECADVINCULO WHERE CDVINCULO = pCdVinculo))

    SELECT --F.NUANOMESREFERENCIA, F.CDTIPOFOLHA, RV.VLPAGAMENTO, MATRICULA
     SUM(NVL(RV.VLPAGAMENTO, 0))
      INTO VVL050546
      FROM EPAGHISTORICORUBRICAVINCULO RV
     INNER JOIN FOLHA F
        ON F.CDFOLHAPAGAMENTO = RV.CDFOLHAPAGAMENTO
     INNER JOIN VPAGRUBRICAAGRUPAMENTO RUB
        ON RUB.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO
       AND RUB.NURUBRICA IN (pNuRubrica)
       AND RUB.CDTIPORUBRICA = pNuTipoRub
     INNER JOIN VINCULO V
        ON V.CDVINCULO = RV.CDVINCULO
     WHERE ((V.CDVINCULO <> pCdVinculo AND
           F.CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento) OR
           (F.CDTIPOFOLHA = pFolha.CdTipoFolha AND
           F.CDFOLHAPAGAMENTO <> pFolha.CdFolhaPagamento));

    RETURN NVL(VVL050546, 0);

  END;

  /*-----------------------------------------------------------------------------------------/
    Procedure  : PCalculaINSS

      Objetivo : Realizar o calculo de contribuicao do INSS

  /-----------------------------------------------------------------------------------------*/

  PROCEDURE PCalculaINSS(pFolha              IN XTMPAG_TIPO.rFolha,
                         pCdPessoa           IN INTEGER,
                         pCdVinculo          IN INTEGER,
                         pCdRubAgrupDescINSS IN INTEGER,
                         pCdRubBaseINSS      IN INTEGER,
                         pCdRubAgrupDifDesc  IN INTEGER,
                         pCdRubAgrupDevDesc  IN INTEGER,
                         pVlINSS             OUT NUMBER) IS

    vvlContribuicao NUMBER(15, 4);
    --vlTetoINSS               NUMBER(15,4);
    --vCdRubrica               INTEGER;
    vvlDescRubIsentaINSS NUMBER(15, 4);
    vVlInssAnt           NUMBER(13, 2) := 0;
    vVlTeto              NUMBER(13, 2) := 0;
    vVlBaseAnt           NUMBER(13, 2) := 0;
    vSgOrgao             VARCHAR2(15) := '';
    vCdAgrupDuploVinc    INTEGER;
    vVlBaseTotal         NUMBER(13, 2) := 0;
    vVlBaseINSS          number;
    vVlIndiceOV          number(13, 4);
    vVlBaseOV            number(13, 2);
    vVlPagoOV            number(13, 2);
    vVlferias            number(13, 2);
    --vConta integer;
    vNumVinc             integer;
    vCdRubAgr05_0512     INTEGER;

    CURSOR cBase(pCdTipoCalculo      IN INTEGER,
                 pCdRubAgrupDescINSS IN INTEGER,
                 pCdRubAgrupDifDesc  IN INTEGER,
                 pCdRubAgrupDevDesc  IN INTEGER) IS
      SELECT pCdVinculo AS CdVinculo,
             (B.VlBase - vvlDescRubIsentaINSS) AS VlBase,
             B.VlDeduzido
        FROM (Select sum(NVL(vlBase, 0)) vlBase,
                     sum(NVL(vldesc, 0)) VlDeduzido,
                     max(vlindice) vlindice
              -- Busca dados de folhas associadas ao calculo geral (cdcalcPai)
              -- para o vinculo
                from (with folhas as (select fp.cdfolhapagamento,
                                             fp.cdtipocalculo,
                                             tfp.cdtipofolha,
                                             fp.flcalculodefinitivo,
                                             fp.NuAnoReferencia,
                                             fp.numesreferencia,
                                             fp.cdagrupamento

                                       from   epagfolhapagamento fp
                                              inner join epagtipofolhapagamento tfp on fp.cdtipofolhapagamento=tfp.cdtipofolhapagamento
                                              inner join epagtipofolha tf on tfp.cdtipofolha=tf.cdtipofolha
                                              where
                                              fp.nuanoreferencia=XTMPAG_var.vgFolha.nuanoreferencia
                                              and fp.numesreferencia=XTMPAG_var.vgFolha.numesreferencia
                                              and fp.cdtipocalculo in (1, 5, 3)
                                              and ((fp.cdorgao in (7, 27, 25, 383 ,3) and tfp.cdtipofolha in (15, 11, 12, 1, 4))
                                                  or (fp.cdorgao <> 7 and tfp.cdtipofolha in (15, 11, 12,1 ,29))
                                                  or (tfp.Cdtipofolha = 2 AND fp.cdfolhapagamento = pFolha.CdFolhaPagamento))

                                        /*from eCalFolhaTrib FP
                                       WHERE FP.SGTRIBUTO =
                                             XTMPAG_TIPO.cnSgTribINSS
                                         AND FP.TPMES =
                                             XTMPAG_TIPO.cnTpMesTribAtual
                                         AND FP.CdCalculoPai =
                                             XTMPAG_VAR.vgCalculo.CdCalculoPai*/

                                             ),

                     folhaNormal as (select rv.cdfolhapagamento
                                       from epaghistoricorubricavinculo rv
                                      inner join folhas FP
                                         ON fp.cdfolhapagamento = rv.cdfolhapagamento
                                        and fp.cdtipocalculo = 1
                                      inner join ecadvinculo v
                                         on v.cdvinculo = rv.cdvinculo
                                      where v.cdvinculo = pCdVinculo),

                     RubBaseINSS as (select nurubrica,
                                            cdrubricaagrupamento,
                                            cdagrupamento
                                       from vpagrubricaagrupamento
                                      where nurubrica = 903
                                        and cdtiporubrica = 9),

                     RubAgrupDescINSS as (select nurubrica,
                                                 cdrubricaagrupamento,
                                                 cdagrupamento
                                            from vpagrubricaagrupamento
                                           where nurubrica = 512
                                             and cdtiporubrica = 5),

                     dados as (select rv.cdfolhapagamento,
                                      rv.vlpagamento,
                                      rv.cdrubricaagrupamento,
                                      rv.cdvinculo,
                                      rv.vlindicerubrica,
                                      fp.cdtipocalculo,
                                      fp.cdtipofolha,
                                      fp.flcalculodefinitivo,
                                      fp.cdagrupamento
                                 from epaghistoricorubricavinculo rv
                                inner join folhas FP
                                   ON fp.cdfolhapagamento =
                                      rv.cdfolhapagamento
                                inner join ecadvinculo v
                                   on v.cdvinculo = rv.cdvinculo
                                where v.cdpessoa = pCdPessoa
                                  and (rv.cdrubricaagrupamento in
                                      (SELECT cdrubricaagrupamento
                                          FROM RubBaseINSS) or
                                      rv.cdrubricaagrupamento in
                                      (SELECT cdrubricaagrupamento
                                          FROM RubAgrupDescINSS))
                                  AND (XTMPAG_VAR.vgRecolhimentoAvulso.FlRecolhimentoTeto =
                                      XTMPAG_TIPO.cnN OR
                                      XTMPAG_VAR.vgRecolhimentoAvulso.CdRecolhimentoAvulso IS NULL)
                                  AND NOT (fp.cdtipofolha =
                                       XTMPAG_tipo.cnTpFolhaFerias AND
                                       v.cdvinculo <> pCdVinculo)
                                     -- Nao incluir na base lancamentos de vinculos com recolhimento avulso pelo teto
                                  AND NOT EXISTS
                                (SELECT 1
                                         FROM eTrbRecolhimentoAvulso T
                                        WHERE T.CdPessoa = v.CdPessoa
                                          AND (T.CdVinculo IS NULL OR
                                              T.CdVinculo = RV.CdVinculo)
                                          AND T.FlAnulado = XTMPAG_TIPO.cnN
                                          AND T.CdObjetoRecolhimento = 1
                                          AND (T.FlRecolhimentoTeto = 'S')
                                          AND ((T.NuAnoInicio <
                                              fp.NuAnoReferencia OR
                                              (T.NuAnoInicio =
                                              fp.NuAnoReferencia AND
                                              T.NuMesInicio <=
                                              fp.NuMesReferencia)) AND
                                              (T.NuAnoFim > fp.NuAnoReferencia OR
                                              (T.NuAnoFim =
                                              fp.NuAnoReferencia AND
                                              T.NuMesFim >=
                                              fp.NuMesReferencia) OR
                                              T.NuAnoFim IS NULL))))

                       select case
                                when d.cdrubricaagrupamento in
                                     (select cdrubricaagrupamento
                                        from RubBaseINSS) then
                                 d.vlpagamento
                                else
                                 0
                              end vlBase,
                              case
                                when d.cdrubricaagrupamento in
                                     (select cdrubricaagrupamento
                                        from RubAgrupDescINSS) then
                                 d.vlpagamento
                                else
                                 0
                              end vlDesc,
                              d.vlindicerubrica vlindice
                         from dados d
                        where d.cdvinculo = pCdVinculo
                          and not (XTMPAG_var.vgFolha.cdtipocalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes and
                                   d.cdfolhapagamento in (select cdfolhapagamento from folhaNormal))

                          --se for uma folha de recálculo, não devem ser consideradas as bases/descontos da folha suplementar dessa recálculo
                          and ((XTMPAG_var.vgFolha.cdtipocalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes
                               and d.cdfolhapagamento not in (select f.cdfolhapagamento
                               from epagfolhapagamento f
                               where f.cdfolhavincsupl = XTMPAG_var.vgFolha.cdfolhapagamento)) or XTMPAG_var.vgFolha.cdtipocalculo <> XTMPAG_tipo.cnTpCalculoRecalculoMes)

                       --traz os valores do calc definitivo para outros vinculos
                       union all

                       select case
                                when d.cdrubricaagrupamento in
                                     (select cdrubricaagrupamento
                                        from RubBaseINSS) then
                                 d.vlpagamento
                                else
                                 0
                              end vlBase,
                              case
                                when d.cdrubricaagrupamento in
                                     (select cdrubricaagrupamento
                                        from RubAgrupDescINSS) then
                                 d.vlpagamento
                                else
                                 0
                              end vlDesc,
                              d.vlindicerubrica vlindice
                         from dados d
                        where d.cdvinculo <> pCdVinculo
                          and ((XTMPAG_var.vgFolha.flCalculoDefinitivo =
                              XTMPAG_TIPO.cnS and
                              d.flcalculodefinitivo = XTMPAG_TIPO.cnS) or
                              (XTMPAG_var.vgFolha.cdtipocalculo =
                              XTMPAG_tipo.cnTpCalculoRecalculoMes and
                              d.flcalculodefinitivo = XTMPAG_TIPO.cnS) or
                              XTMPAG_var.vgFolha.flCalculoDefinitivo =
                              XTMPAG_TIPO.cnN)

                           and ((XTMPAG_var.vgFolha.cdtipocalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes and
                                 d.cdfolhapagamento = XTMPAG_var.vgFolha.cdfolhapagamento /*not in (select fp.cdfolhavincsupl from epagfolhapagamento fp
                                                            where fp.cdfolhaorigem in (select f.cdfolhaorigem
                                                                                         from epagfolhapagamento f
                                                                                        where f.cdfolhavincsupl = XTMPAG_var.vgFolha.cdfolhapagamento)
                                                            )*/ 
                                                            
                                 and
                                 d.cdfolhapagamento <> pFolha.CdFolhaPagamentoNormal                           
                                 ) or XTMPAG_var.vgFolha.cdtipocalculo <> XTMPAG_tipo.cnTpCalculoRecalculoMes)
                              )
              ) B;

    PROCEDURE PAtualizaBaseINSS(pvlBase IN NUMBER) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF vvlDescRubIsentaINSS > 0 THEN

        UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.Vlpagamento = pvlBase
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento = pCdRubBaseINSS;

      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                XTMPAG_VAR.vCdHistParamCalc,
                                XTMPAG_VAR.vCdPessoa,
                                'XTMPAG_TRIBUTACAO.PAtualizaBaseINSS',
                                XTMPAG_VAR.vgCdVinculo);

    END;

    FUNCTION FRubricaGerada(pCdTipoCalculo IN INTEGER,
                            pvlDeduzido    IN NUMBER,
                            pvlLiquido     IN NUMBER) RETURN INTEGER IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      CASE

        WHEN pvlDeduzido > 0 THEN

          CASE

            WHEN pvlLiquido > 0 THEN

              CASE

                WHEN XTMPAG_VAR.vgFaseCalculo =
                     XTMPAG_TIPO.cnFaseCalculoIntegral THEN

                  RETURN pCdRubAgrupDescINSS;

                ELSE

                  RETURN pCdRubAgrupDifDesc; --  gera rubrica do tipo 6

              END CASE;

            WHEN pvlLiquido < 0 THEN

              -- O Estado nao arca com devolucao de INNS para o servidor --

              RETURN 0;

            ELSE

              RETURN 0;

          END CASE;

        WHEN pvlDeduzido = 0 THEN

          CASE

            WHEN pvlLiquido > 0 THEN

              RETURN pCdRubAgrupDescINSS;

            ELSE

              RETURN 0;

          END CASE;

        ELSE

          RETURN 0;

      END CASE;

    END;

    function fRetornaAliquota(pVlBase in number,
                              lFaixa  IN XTMPAG_TIPO.tFaixaAliquota)
      return number is

      --vVlIndice number;
      i integer := 0;

    begin
      -- xtmpag_util.pGravaLogCallStack;

      WHILE i < (lFaixa.COUNT)

       LOOP

        i := i + 1;

        if (pVlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal) then

          return lFaixa(i).VlAliquota;

          i := lFaixa.COUNT + 1;

        end if;

      end loop;

    exception
      when others then
        return 0;
    end;

    PROCEDURE InsereRubricaINSS(pCdVinculo        IN INTEGER,
                                pCdRubricaGerada  IN INTEGER,
                                pCdFolhaPagamento IN INTEGER,
                                pVlRubrica        IN INTEGER,
                                pNuSufixo         IN INTEGER,
                                pVlIndice         IN NUMBER,
                                pDeExpressao      IN CHAR default null) IS

    vvlRubrica NUMBER(15, 4);

    vCdExpressaoFormCalc INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF XTMPAG_GERAL.FGeraRubrica(pRubrica => pCdRubricaGerada) THEN

        IF pCdRubricaGerada IN (pCdRubAgrupDifDesc, pCdRubAgrupDevDesc) THEN

          vvlRubrica := ABS(pVlRubrica);

        ELSE

          vvlRubrica := pVlRubrica;

        END IF;

        BEGIN

          IF pCdRubricaGerada > 0 AND vvlRubrica >= 0.01 THEN
            IF pFolha.CdOrgao in (383, 3, 4, 5) THEN
              -- SC PARCERIAS e CIASC SOLICITARAM CALCULAR TETO DESCONTO INSS IGUAL A 482,92, COMO NO PROGRAMA SEFIP DA C.E.F.

              INSERT INTO EpagHistoricoRubricaVinculo
                (CdHistoricoRubricaVinculo,
                 CdFolhaPagamento,
                 CdRubricaAgrupamento,
                 CdVinculo,
                 NuSufixoRubrica,
                 CdLancamentoFinanceiro,
                 VlPagamento,
                 QtParcelas,
                 VlIndiceRubrica,
                 DtUltAlteracao,
                 CdTipoOrigemRubrica,
                 CdTipoIndice,
                 DeExpressao)
              VALUES
                (Spaghistoricorubricavinculo.NEXTVAL,
                 pCdFolhaPagamento,
                 pCdRubricaGerada,
                 pCdVinculo,
                 1,
                 NULL,
                 round(vvlRubrica, 2),
                 1,
                 pvlIndice,
                 systimestamp,
                 10,
                 XTMPAG_VAR.vgRubrica(pCdRubricaGerada).CdTipoIndice,
                 pDeExpressao);

              pvlINSS := vvlRubrica;

            ELSE
              --
              -- SIG-945 13288/2019 - LIMITE DE DESCONTO DO INSS
              --
              INSERT INTO EpagHistoricoRubricaVinculo
                (CdHistoricoRubricaVinculo,
                 CdFolhaPagamento,
                 CdRubricaAgrupamento,
                 CdVinculo,
                 NuSufixoRubrica,
                 CdLancamentoFinanceiro,
                 VlPagamento,
                 QtParcelas,
                 VlIndiceRubrica,
                 DtUltAlteracao,
                 CdTipoOrigemRubrica,
                 CdTipoIndice,
                 DeExpressao,
                 CdExpressaoFormCalc)
              VALUES
                (Spaghistoricorubricavinculo.NEXTVAL,
                 pCdFolhaPagamento,
                 pCdRubricaGerada,
                 pCdVinculo,
                 1,
                 NULL,
                 case when XTMPAG_var.vgValorReferenciaMAXINSS > 0 and
                 XTMPAG_var.vgValorReferenciaMAXINSS < vvlRubrica then
                 XTMPAG_var.vgValorReferenciaMAXINSS else
                 ROUND(vvlRubrica, 4) end,
                 1,
                 pvlIndice,
                 systimestamp,
                 10,
                 XTMPAG_VAR.vgRubrica(pCdRubricaGerada).CdTipoIndice,
                 pDeExpressao,
                 vCdExpressaoFormCalc);

              pvlINSS := vvlRubrica;

            END IF;

          ELSE

            pvlINSS := 0.0;

          END IF;

          begin
          -- SE A RUBRICA FOR EXECUTADA POR FORMULA
          if pCdRubricaGerada = XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13 then
            -- Verifica se tem formula
            vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr       => XTMPAG_VAR.vgFormExpr,
                                                                     pCdRubricaAgrupamento => pCdRubricaGerada,
                                                                     pCdRelacaoVinculo     => XTMPAG_var.vgCEF(1).CdRelacaoVinculo);

             IF nvl(vCdExpressaoFormCalc, 0) > 0 THEN

                XTMPAG_FB.PProcessaFormulasBases(pFolha       => XTMPAG_var.vgFolha,
                                             pCdVinculo       => XTMPAG_var.vgVinculo.CdVinculo,
                                             pCdRubrica       => pCdRubricaGerada,
                                             pTpProcessamento => 1,
                                             pTpLocal         => 2);

             end if;

         end if;

         exception
            when others then
               null;
         end;

        EXCEPTION
          WHEN OTHERS THEN

            XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                    XTMPAG_VAR.vCdHistParamCalc,
                                    XTMPAG_VAR.vCdPessoa,
                                    'Erro ao processar valor INSS: ' ||
                                    SQLERRM,
                                    XTMPAG_VAR.vgCdVinculo);

        END;

      ELSE

        pvlINSS := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pCdFolhaPagamento,
                                                     pCdVinculo        => pCdVinculo,
                                                     pCdRubrica        => pCdRubricaGerada);

      END IF;

    END;

    FUNCTION FDeduzAliqDuploVinc(pCdAgrupDuploVinc INTEGER,
                                 pVlBase           NUMBER DEFAULT 0,
                                 pVlBaseAnt        NUMBER DEFAULT 0)
      RETURN BOOLEAN IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      /*
      1    AGPE
      133  PGTC
      134  PMSC
      176  DPSC
      */

      IF pCdAgrupDuploVinc IN (1, 133, 134, 176) OR
         (pCdAgrupDuploVinc NOT IN (1, 133, 134, 176) AND
         pVlBase > pVlBaseAnt) THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    END;

    PROCEDURE pAplicaAliquotaINSS13Rescisao(lFaixa IN XTMPAG_TIPO.tFaixaAliquota) IS

      vVlBase13Folha            NUMBER(15, 4) := 0;
      vVlBase13DuploVincMes     NUMBER(15, 4) := 0;
      vVlDesconto13DuploVincMes NUMBER(15, 4) := 0;
      vVlBaseRescisaoAno        NUMBER(10, 4) := 0;
      vVlDesconto13RescisaoAno  NUMBER(15, 4) := 0;

      vVlContribuicao      NUMBER(15, 4);
      i                    INTEGER := 0;
      vAliquotaProgressiva NUMBER(15, 4);

      PROCEDURE PAtualizaBaseINSS13Rescisao(pvlBase     IN NUMBER,
                                            pVlBaseSoma in number) IS

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.Vlpagamento = pvlBase,
               hrv.deexpressao = pVlBase || ' + ' || pVlBaseSoma
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento = XTMPAG_var.vgCdRubBaseINSS13;

      EXCEPTION
        WHEN OTHERS THEN
          XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                  XTMPAG_VAR.vCdHistParamCalc,
                                  XTMPAG_VAR.vCdPessoa,
                                  'XTMPAG_TRIBUTACAO.PAtualizaBaseINSS13Rescisao',
                                  XTMPAG_VAR.vgCdVinculo);
      END;

      -- Soma rubrica de desconto de INSS13 das folhas Normal e Suplementar definitivas ou recalculo diferentes de folha de 13
      -- de todos os vinculos
      FUNCTION FVlPagamentoINSS13Rescisao(pCdOrgao   INTEGER,
                                          pCdVinculo INTEGER,
                                          pNuAno     INTEGER,
                                          pNuMes     INTEGER) RETURN NUMBER IS

        vvlPagamento NUMBER(15, 4) := 0;

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        select sum(hrv.vlpagamento)
          into vvlPagamento
          from epagfolhapagamento fp
         inner join ecadorgao o
            on o.cdorgao = fp.cdorgao
         inner join epagtipofolhapagamento tfp
            on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
         inner join epaghistoricorubricavinculo hrv
            on hrv.cdfolhapagamento = fp.cdfolhapagamento
         where fp.nuanoreferencia = pNuAno
           and hrv.cdvinculo in
               (select v.cdvinculo
                  from ecadvinculo v
                 where v.cdpessoa = XTMPAG_var.vgVinculo.cdpessoa)
           and hrv.cdrubricaagrupamento =
               XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13

           and ((pFolha.CdTipoCalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes and
               fp.cdtipocalculo in
               (XTMPAG_tipo.cnTpCalculoNormal,
                  XTMPAG_tipo.cnTpCalculoSupl) and
               fp.numesreferencia < pNuMes) OR
               (pFolha.CdTipoCalculo <>
               XTMPAG_tipo.cnTpCalculoRecalculoMes and
               fp.cdtipocalculo in
               (XTMPAG_tipo.cnTpCalculoNormal,
                  XTMPAG_tipo.cnTpCalculoSupl)))
           and fp.flcalculodefinitivo = 'S'
           and tfp.cdtipofolha <> XTMPAG_tipo.cnTpFolha13;

        RETURN nvl(vvlPagamento, 0);

      EXCEPTION
        WHEN OTHERS THEN
          RETURN 0;

      END;
      FUNCTION FVlPagamentoINSS13(pCdOrgao   INTEGER,
                                  pCdVinculo INTEGER,
                                  pNuAno     INTEGER,
                                  pNuMes     INTEGER) RETURN NUMBER IS

        vvlPagamento NUMBER(15, 4) := 0;

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        select sum(hrv.vlpagamento)
          into vvlPagamento
          from epagfolhapagamento fp
         inner join ecadorgao o
            on o.cdorgao = fp.cdorgao
         inner join epagtipofolhapagamento tfp
            on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
         inner join epaghistoricorubricavinculo hrv
            on hrv.cdfolhapagamento = fp.cdfolhapagamento
         where fp.nuanoreferencia = pNuAno
           and hrv.cdvinculo in
               (select v.cdvinculo
                  from ecadvinculo v
                 where v.cdpessoa = XTMPAG_var.vgVinculo.cdpessoa
                   and v.cdvinculo <> XTMPAG_var.vgvinculo.cdvinculo)
           and hrv.cdrubricaagrupamento =
               XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13
           and fp.cdtipocalculo = XTMPAG_tipo.cnTpCalculoNormal
           and fp.numesreferencia = pNuMes
           and tfp.cdtipofolha = XTMPAG_tipo.cnTpFolha13;

        RETURN nvl(vvlPagamento, 0);

      EXCEPTION
        WHEN OTHERS THEN
          RETURN 0;

      END;

      FUNCTION FVlBaseINSS13Rescisao(pCdOrgao   INTEGER,
                                     pCdVinculo INTEGER,
                                     pNuAno     INTEGER) RETURN NUMBER IS

        vvlBaseFolha13      NUMBER(15, 4) := 0;
        vvlBaseOutrasFolhas NUMBER(15, 4) := 0;
        nuMesFolha          INTEGER := pFolha.NuMesReferencia;

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        -- Soma base de INSS13 das demais folhas de pagamentos de meses anteriores desconsiderando o mes 12
        -- de outros vinculos
        select sum(hrv.vlpagamento)
          into vvlBaseFolha13
          from epagfolhapagamento fp
         inner join epaghistoricorubricavinculo hrv
            on hrv.cdfolhapagamento = fp.cdfolhapagamento
         inner join epagtipofolhapagamento tfp
            on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
         where fp.nuanoreferencia = pNuAno
           and fp.numesreferencia < nuMesFolha
           and tfp.cdtipofolha = XTMPAG_tipo.cnTpFolha13
           and fp.cdtipocalculo = 1
           and hrv.cdrubricaagrupamento = XTMPAG_var.vgCdRubBaseINSS13
           and fp.flcalculodefinitivo = 'S'
           and ((XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S' and fp.flcalculodefinitivo = 'S')
            or (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'N'))
           and not (nuMesFolha = 12 and
                fp.cdfolhapagamento in
                (select cdfolhapagamento
                       from epagfolhapagamento fp
                      inner join epagtipofolhapagamento tf
                         on tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
                      where tf.cdtipofolha in (3, 20) -- 13sal e 13 sal ctisp
                        and fp.nuanoreferencia = pfolha.nuanoreferencia
                        and fp.flcalculodefinitivo = 'S'))
           and hrv.cdvinculo in
               (select v.cdvinculo
                  from ecadvinculo v
                 where v.cdpessoa = XTMPAG_var.vgVinculo.cdpessoa
                   and v.cdregimeprevidenciario = 1
                   and v.cdvinculo <> XTMPAG_var.vgVinculo.cdvinculo); -- Regime geral


       -- Soma valor da rubrica 01-1023 ou 02-1023 das folhas definitivas do ano para os demais vinculos
       -- incluindo folhas Normal e Suplementar e Recalculo do Mes para o regime previdenciario = 1
       -- para os casos que nao existem as rubricas
       -- XTMPAG_var.vgParamPagamento.cdrubagrupiprevfundlc66213,
       -- XTMPAG_var.vgParamPagamento.cdrubagrupdescipescsobre13,
       -- XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,5,1923)

        with rub as
         (select vr.cdrubricaagrupamento
            from vpagrubricaagrupamento vr
           where vr.nurubrica = 1023
             and vr.cdtiporubrica in (1, 2)
             and vr.cdagrupamento = pFolha.CdAgrupamento)
        select sum(hrv.vlpagamento)
          into vvlBaseOutrasFolhas
          from epagfolhapagamento fp
         inner join epaghistoricorubricavinculo hrv
            on hrv.cdfolhapagamento = fp.cdfolhapagamento
         inner join rub r
            on r.cdrubricaagrupamento = hrv.cdrubricaagrupamento
         inner join epagtipofolhapagamento tfp
            on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
         where fp.nuanoreferencia = pNuAno
           and fp.numesreferencia <= nuMesFolha
           and fp.flcalculodefinitivo = 'S'
           and ((pFolha.CdTipoCalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes and
               ((fp.cdtipocalculo in
               (XTMPAG_tipo.cnTpCalculoNormal,
                    XTMPAG_tipo.cnTpCalculoSupl) and
               fp.numesreferencia <> nuMesFolha) OR
               (fp.cdtipocalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes and
               fp.numesreferencia = nuMesFolha))) OR
               (pFolha.CdTipoCalculo <>
               XTMPAG_tipo.cnTpCalculoRecalculoMes and
               fp.cdtipocalculo in
               (XTMPAG_tipo.cnTpCalculoNormal,
                  XTMPAG_tipo.cnTpCalculoSupl)))
           and hrv.cdvinculo in
               (select v.cdvinculo
                  from ecadvinculo v
                 where v.cdpessoa = XTMPAG_var.vgVinculo.cdpessoa
                   and v.cdregimeprevidenciario = 1
                   and v.cdvinculo <> case
                         when fp.cdfolhapagamento =
                              XTMPAG_var.vgFolha.CdFolhaPagamento then
                          XTMPAG_var.vgVinculo.cdvinculo
                         else
                          0
                       end) -- Regime geral
           and not exists
         (select 1
                  from epaghistoricorubricavinculo hv
                 where hv.cdvinculo = hrv.cdvinculo
                   and hv.cdfolhapagamento = hrv.cdfolhapagamento
                   and hv.cdrubricaagrupamento in
                       (XTMPAG_var.vgParamPagamento.cdrubagrupiprevfundlc66213,
                        XTMPAG_var.vgParamPagamento.cdrubagrupdescipescsobre13,
                        XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                     5,
                                                     1923)));

        RETURN nvl(vvlBaseFolha13, 0) + nvl(vvlBaseOutrasFolhas, 0);

      EXCEPTION
        WHEN OTHERS THEN
          RETURN 0;

      END;
      -- Base do INSS13 do mesmo ano e mes de outros vinculos
      FUNCTION FVlBaseINSS13(pCdOrgao   INTEGER,
                             pCdVinculo INTEGER,
                             pNuAno     INTEGER) RETURN NUMBER IS

        vvlBaseFolha13 NUMBER(15, 4) := 0;
        nuMesFolha     INTEGER := pFolha.NuMesReferencia;

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        select sum(hrv.vlpagamento)
          into vvlBaseFolha13
          from epagfolhapagamento fp
         inner join epaghistoricorubricavinculo hrv
            on hrv.cdfolhapagamento = fp.cdfolhapagamento
         inner join epagtipofolhapagamento tfp
            on tfp.cdtipofolhapagamento = fp.cdtipofolhapagamento
         where fp.nuanoreferencia = pNuAno
           and fp.numesreferencia <= nuMesFolha
           and tfp.cdtipofolha = XTMPAG_tipo.cnTpFolha13
           and fp.cdtipocalculo = 1
           and hrv.cdrubricaagrupamento = XTMPAG_var.vgCdRubBaseINSS13
           and fp.numesreferencia = nuMesFolha
           and hrv.cdvinculo in
               (select v.cdvinculo
                  from ecadvinculo v
                 where v.cdpessoa = XTMPAG_var.vgVinculo.cdpessoa
                   and v.cdregimeprevidenciario = 1
                   and v.cdvinculo <> XTMPAG_var.vgVinculo.cdvinculo); -- Regime geral

        RETURN nvl(vvlBaseFolha13, 0);

      EXCEPTION
        WHEN OTHERS THEN
          RETURN 0;

      END;

      function fAplicaAliquotaProgressiva(lFaixa      IN XTMPAG_TIPO.tFaixaAliquota,
                                          lVlBaseINSS in number)
        return number is

        vVlAliquota number(10, 4);

        vVlBaseProgressiva number := 0;

        ind integer;

      begin
        -- xtmpag_util.pGravaLogCallStack;

        vVlContribuicao := 0;

        ind := 0;

        WHILE ind < lFaixa.COUNT

         LOOP

          ind := ind + 1;

          if lVlBaseINSS >= lFaixa(ind).vlInicial THEN

            if lVlBaseINSS > lFaixa(ind).vlFinal then

              if ind > lFaixa.First then

                vVlBaseProgressiva := lFaixa(ind).vlFinal - lFaixa(ind - 1).vlFinal;

              else

                vVlBaseProgressiva := lFaixa(ind).vlFinal;

              end if;

            else
              if ind > 1 then
                vVlBaseProgressiva := lVlBaseINSS - lFaixa(ind - 1).vlFinal;

              else
                vVlBaseProgressiva := lVlBaseINSS;
              end if;

            end if;

            if vVlBaseProgressiva > lFaixa(lFaixa.LAST).VlFinal then

              vVlBaseProgressiva := lFaixa(lFaixa.LAST).VlFinal - lFaixa(lFaixa.LAST - 1).VlFinal;

            end if;

            vvlContribuicao := vVlContribuicao + trunc((vVlBaseProgressiva * lFaixa(ind).VlAliquota / 100),
                                                       2);

          end if;

        END LOOP;

        vVlAliquota := round(vVlContribuicao /
                             least(lVlBaseINSS, lFaixa(lFaixa.LAST).VlFinal) * 100,
                             4);

        return vVlAliquota;

      end;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_VAR.vgRecolhimentoAvulso :=null;

    PRegistroRecolhimentoAvulso13(XTMPAG_var.vgvinculo.cdpessoa,pCdVinculo,
                                  XTMPAG_VAR.vgFolha.NuAnoReferencia, XTMPAG_VAR.vgFolha.NuMesReferencia);

    -- Verifica recolhimento avulso pelo TETO
    if XTMPAG_VAR.vgRecolhimentoAvulso.FlRecolhimentoTeto is not null and
       XTMPAG_VAR.vgRecolhimentoAvulso.FlRecolhimentoTeto = 'S' then

       return;

    end if;

    IF XTMPAG_var.vgFolha.CdAgrupamento = 1 THEN

    -- Base INSS 13 do vinculo
    -- 09-2114  TOTAL BASE DESCONTO INSS 13 DO ANO TODOS VINCULOS
     XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_VAR.vgCdRubBaseINSS13,
                                 pFlExcluiAmbos => 'S');

     XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                           pCdVinculo            => pCdVinculo,
                                           pCdExpressaoFormCalc  => NULL,
                                           pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseINSS13,
                                           pNuSufixoRubrica      => 1,
                                           pVlPagamento          => 0,
                                           pVlIndice             => NULL,
                                           pCdTipoOrigemRubrica  => 10);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseINSS13,
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

     -- 09-2114  TOTAL BASE DESCONTO INSS 13 DO ANO TODOS VINCULOS
     XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2114),
                                 pFlExcluiAmbos => 'S');

     XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                           pCdVinculo            => pCdVinculo,
                                           pCdExpressaoFormCalc  => NULL,
                                           pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2114),
                                           pNuSufixoRubrica      => 1,
                                           pVlPagamento          => 0,
                                           pVlIndice             => NULL,
                                           pCdTipoOrigemRubrica  => 10);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2114),
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- 09-2113  TOTAL BASES INSS 13 DO ANO DE TODOS OS VINCULOS

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                     pCdVinculo => XTMPAG_VAR.vgVinculo.CdVinculo,
                                     pCdRubrica => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2113),
                                 pFlExcluiAmbos => 'S');

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                           pCdVinculo            => pCdVinculo,
                                           pCdExpressaoFormCalc  => NULL,
                                           pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2113),
                                           pNuSufixoRubrica      => 1,
                                           pVlPagamento          => 0,
                                           pVlIndice             => NULL,
                                           pCdTipoOrigemRubrica  => 10);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2113),
                                       pTpProcessamento => 2, -- Processa base de c?lculo
                                       pTpLocal         => 2);

      -- Valor da Rubrica 09-2113
      vVlBase13Folha := NVL(XTMPAG_geral.fretornavalorrubrica(XTMPAG_var.vgFolha.CdFolhapagamento,
                                                              XTMPAG_VAR.vgVinculo.CdVinculo,
                                                              XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2113)),0);

      vVlDesconto13RescisaoAno := NVL(XTMPAG_geral.fretornavalorrubrica(XTMPAG_var.vgFolha.CdFolhapagamento,
                                                              XTMPAG_VAR.vgVinculo.CdVinculo,
                                                              XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,9,2114)),0);
      -- Base do INSS13 09-1005 do mesmo ano e mes de outros vinculos
     /* vVlBase13DuploVincMes := NVL(FVlBaseINSS13(XTMPAG_VAR.vgFolha.CdOrgao,
                                                 XTMPAG_VAR.vgCdVinculo,
                                                 XTMPAG_VAR.vgFolha.NuAnoReferencia),
                                   0);*/

      -- Soma dos descontos de INNS 13 dos outros vinculos paras as folhas de 13º do mes definitivas ou nao
      /*vVlDesconto13DuploVincMes := NVL(FVlPagamentoINSS13(XTMPAG_VAR.vgFolha.CdOrgao,
                                                          XTMPAG_VAR.vgCdVinculo,
                                                          XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                          XTMPAG_VAR.vgFolha.NumESReferencia),
                                       0);*/

      -- Soma base de INSS13 das demais folhas de pagamentos de meses anteriores desconsiderando o mes 12
      -- de outros vinculos
      -- Soma valor da rubrica 01-1023 ou 02-1023 das folhas definitivas do ano para os demais vinculos
      -- incluindo folhas Normal e Suplementar e Recalculo do Mes para o regime previdenciario = 1
      -- para os casos que nao existem as rubricas
      -- XTMPAG_var.vgParamPagamento.cdrubagrupiprevfundlc66213,
      -- XTMPAG_var.vgParamPagamento.cdrubagrupdescipescsobre13,
      -- XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,5,1923)
      /*vVlBaseRescisaoAno := NVL(FVlBaseINSS13Rescisao(XTMPAG_VAR.vgFolha.CdOrgao,
                                                      XTMPAG_VAR.vgCdVinculo,
                                                      XTMPAG_VAR.vgFolha.NuAnoReferencia),
                                0);*/


      -- Soma rubrica de desconto de INSS13 das folhas Normal e Suplementar definitivas ou recalculo diferentes de folha de 13
      -- de todos os vinculos
      /*vVlDesconto13RescisaoAno := NVL(FVlPagamentoINSS13Rescisao(XTMPAG_VAR.vgFolha.CdOrgao,
                                                       XTMPAG_VAR.vgCdVinculo,
                                                                 XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                 XTMPAG_VAR.vgFolha.NumESReferencia),0);*/

    /*    PAtualizaBaseINSS13Rescisao(vVlBase13Folha,
                                    nvl(vVlBaseRescisaoAno, 0) +
                                    nvl(vVlBase13DuploVincMes, 0));

        vVlBase13Folha := vVlBase13Folha + nvl(vVlBaseRescisaoAno, 0) +
                          nvl(vVlBase13DuploVincMes, 0);*/

      -- Verifica se tem base de recolhimento avulso
      IF XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento IS NOT NULL THEN

         vVlBase13Folha := vVlBase13Folha + XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento;

      end if;

        vVlBase13Folha := least(vVlBase13Folha, XTMPAG_VAR.vAliqINSS.vlTeto);

      if XTMPAG_var.vAliqINSS.lFaixa(1).FlAliquotaProgressiva = 'S' and vVlBase13Folha > 0 then

        -- Verifica se possui Aliquota Unica para recolhimento avulso
        if XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica IS NOT NULL then

          vAliquotaProgressiva := lFaixa(lFaixa.LAST).Vlaliqcontribindividual;

        else

          vAliquotaProgressiva := fAplicaAliquotaProgressiva(lFaixa,vVlBase13Folha);

        end if;

        vvlContribuicao := vVlBase13Folha * vAliquotaProgressiva / 100;

        vvlContribuicao := vvlContribuicao - vVlDesconto13RescisaoAno;

        IF NOT
            XTMPAG_LF.FPossuiLancamentoFinanceiro(XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13) THEN

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                                      pFlExcluiAmbos    => 'S');
        END IF;

        InsereRubricaINSS(pCdVinculo,
                          XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                          pFolha.CdFolhaPagamento,
                          vvlContribuicao,
                          1,
                          vAliquotaProgressiva,
                          '(BaseINSS13Ano * Aliquota/100) - (DescOutrosVinculos) => ' ||
                          '(' || vVlBase13Folha || '*' || vAliquotaProgressiva || '/100)-' ||
                          '(' || nvl(vVlDesconto13RescisaoAno,0) ||')');


      else

        i := 0;
        WHILE i < (lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF (vVlBase13Folha BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal) THEN

            -- Aplica indice sobre base
            vvlContribuicao := vVlBase13Folha * lFaixa(i).VlAliquota / 100;

            -- Deduz o que ja foi descontado
            vvlContribuicao := vvlContribuicao - vVlDesconto13RescisaoAno;

            InsereRubricaINSS(pCdVinculo,
                              XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                              pFolha.CdFolhaPagamento,
                              vvlContribuicao,
                              1,
                              lFaixa(i).VlAliquota);

            i := lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      end if;

      ELSE

        vVlBase13Folha := NVL(XTMPAG_geral.fretornavalorrubrica(XTMPAG_var.vgFolha.CdFolhapagamento,
                                                                XTMPAG_VAR.vgVinculo.CdVinculo,
                                                                XTMPAG_var.vgCdRubBaseINSS13),
                              0);

        vVlBase13DuploVincMes := NVL(FVlBaseINSS13(XTMPAG_VAR.vgFolha.CdOrgao,
                                                   XTMPAG_VAR.vgCdVinculo,
                                                   XTMPAG_VAR.vgFolha.NuAnoReferencia),
                                     0);

        vVlDesconto13DuploVincMes := NVL(FVlPagamentoINSS13(XTMPAG_VAR.vgFolha.CdOrgao,
                                                            XTMPAG_VAR.vgCdVinculo,
                                                            XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                            XTMPAG_VAR.vgFolha.NumESReferencia),
                                         0);

        vVlBaseRescisaoAno := NVL(FVlBaseINSS13Rescisao(XTMPAG_VAR.vgFolha.CdOrgao,
                                                        XTMPAG_VAR.vgCdVinculo,
                                                        XTMPAG_VAR.vgFolha.NuAnoReferencia),
                                  0);

        vVlDesconto13RescisaoAno := NVL(FVlPagamentoINSS13Rescisao(XTMPAG_VAR.vgFolha.CdOrgao,
                                                         XTMPAG_VAR.vgCdVinculo,
                                                                   XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                   XTMPAG_VAR.vgFolha.NumESReferencia),
                                        0);

        begin

          if nvl(vVlBaseRescisaoAno, 0) = 0 then

            vVlBaseRescisaoAno := FVlBaseINSS13Rescisao(XTMPAG_VAR.vgFolha.CdOrgao,
                                                        XTMPAG_VAR.vgCdVinculo,
                                                        XTMPAG_VAR.vgFolha.NuAnoReferencia);

            delete epageventovinculo ev
             where ev.cdtipoeventovinculo = 7
               and ev.cdchave = XTMPAG_var.vgvinculo.cdpessoa
               and ev.cdvinculo = pcdvinculo
               and ev.nuanomesreferencia = pFolha.NuAnoReferencia ||
                   lpad(pFolha.NuMesReferencia, 2, 0)
               and ev.cdrubricaagrupamento = XTMPAG_VAR.vgCdRubBaseINSS13;

            insert into EPagEventoVinculo evv
              (cdeventovinculo,
               cdvinculo,
               cdtipoeventovinculo,
               nuanomesreferencia,
               vlevento,
               vlindice,
               cdrubricaagrupamento,
               nucpfcadastrador,
               nucpfultimaalteracao,
               dtinclusao,
               dtultalteracao,
               cdchave,
               vlpagamento,
               cdfolhapagamento)
            VALUES
              (Spageventovinculo.NEXTVAL,
               pCdVinculo,
               7,
               pFolha.NuAnoReferencia || lpad(pFolha.NuMesReferencia, 2, 0),
               vVlBaseRescisaoAno,
               0,
               XTMPAG_VAR.vgCdRubBaseINSS13,
               11111111111,
               11111111111,
               sysdate,
               sysdate,
               XTMPAG_var.vgvinculo.cdpessoa,
               0,
               pFolha.CdFolhaPagamento);

          end if;

        end;

          PAtualizaBaseINSS13Rescisao(vVlBase13Folha,
                                      nvl(vVlBaseRescisaoAno, 0) +
                                      nvl(vVlBase13DuploVincMes, 0));

          vVlBase13Folha := vVlBase13Folha + nvl(vVlBaseRescisaoAno, 0) +
                            nvl(vVlBase13DuploVincMes, 0);

          vVlBase13Folha := least(vVlBase13Folha, XTMPAG_VAR.vAliqINSS.vlTeto);

        if XTMPAG_var.vAliqINSS.lFaixa(1)
         .FlAliquotaProgressiva = 'S' and vVlBase13Folha > 0 then

          vAliquotaProgressiva := fAplicaAliquotaProgressiva(lFaixa,
                                                             vVlBase13Folha);

          vvlContribuicao := vVlBase13Folha * vAliquotaProgressiva / 100;

          vvlContribuicao := vvlContribuicao - vVlDesconto13RescisaoAno -
                             nvl(vVlDesconto13DuploVincMes, 0);

          IF NOT
              XTMPAG_LF.FPossuiLancamentoFinanceiro(XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13) THEN

            XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                                        pFlExcluiAmbos    => 'S');
          END IF;

          InsereRubricaINSS(pCdVinculo,
                            XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                            pFolha.CdFolhaPagamento,
                            vvlContribuicao,
                            1,
                            vAliquotaProgressiva);

          if XTMPAG_var.vgCalculo.FlGeral <> 'I' and bPossuiOutroVinculo then
            -- Reprocessar Duplo vinculo

            INSERT INTO tmppagcalculocoletivo
            values
              (pFolha.CdFolhaPagamento,
               pCdvinculo,
               to_char(SYSDATE, 'ddmmyyhh24mi'),
               'J',
               XTMPAG_var.vgfolha.cdagrupamento,
               SYSDATE);

          end if;

        else

          i := 0;
          WHILE i < (lFaixa.COUNT)

           LOOP

            i := i + 1;

            IF (vVlBase13Folha BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal) THEN

              -- Aplica indice sobre base
              vvlContribuicao := vVlBase13Folha * lFaixa(i).VlAliquota / 100;

              -- Deduz o que ja foi descontado
              vvlContribuicao := vvlContribuicao - vVlDesconto13RescisaoAno -
                                 vVlDesconto13DuploVincMes;

              InsereRubricaINSS(pCdVinculo,
                                XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13,
                                pFolha.CdFolhaPagamento,
                                vvlContribuicao,
                                1,
                                lFaixa(i).VlAliquota);

              i := lFaixa.COUNT + 1;

            END IF;

          END LOOP;

        end if;

      END IF;
    END;

    PROCEDURE pAplicaAliquota(lFaixa IN XTMPAG_TIPO.tFaixaAliquota) IS

      i                        INTEGER;
      u                        integer;
      vCdRubricaGerada         INTEGER;
      vVlBase                  NUMBER(15, 2);
      vVlBaseVinculo           NUMBER(15, 2);
      vVlAliquotaOutroVinculo  NUMBER(10, 4);
      vVlBaseOutroVinculo      NUMBER(15, 2);
      vVlBaseOutrasFolhas      number(15, 2);
      vVlDescOutrasFolhas      number(15, 2);
      vVlefetivadoOutrasFolhas number(15, 2);
      vVlDescTotal             number(15, 2);
      vVlDescOutroVinculo      NUMBER(13, 2);
      vCdFolhaOutroVinculo     integer;
      --vRetorno                XTMPAG_cal.rCalculoRetorno;
      vCdOrgaoOutroVinculo integer;
      --vFlCalculoDefinitivo    char(1) default 'N';

      procedure pProcessaParalelo(pCdFolha             in integer,
                                  pCdVinculo           in integer,
                                  pFlCalculoDefinitivo in Char) is

        pragma autonomous_transaction;

      begin
        -- xtmpag_util.pGravaLogCallStack;

        insert into tmppagcalculocoletivo
          (cdfolhapagamento,
           cdvinculo,
           matricula,
           flcalculado,
           nusegmento,
           dtultalteracao)
        values
          (pCdFolha,
           pCdVinculo,
           null,
           'J', -- Paralelo
           pCdVinculo,
           sysdate);
        commit;

      exception
        when others then
          null;
      end;

      function fPossuiFolhaFerias(pCdVinculo IN INTEGER)

       return boolean is

        vPossui integer := 0;

      begin
        -- xtmpag_util.pGravaLogCallStack;

        with fol as
         (select ff.cdfolhapagamento
            from epagfolhapagamento ff
           inner join epagtipofolhapagamento tf
              on tf.cdtipofolhapagamento = ff.cdtipofolhapagamento
             and tf.cdtipofolha = XTMPAG_TIPO.cnTpFolhaFerias
           where ff.cdagrupamento = XTMPAG_var.vgFolha.CdAgrupamento
             and ff.cdorgao = XTMPAG_var.vgFolha.cdorgao
             and ff.nuanoreferencia = XTMPAG_var.vgFolha.nuanoreferencia
             and ff.numesreferencia = XTMPAG_var.vgFolha.numesreferencia
             and ff.flcalculodefinitivo = XTMPAG_tipo.cnS)
        select 1
          into vPossui
          from EpagHistoricoRubricaVinculo HV
         inner join fol f
            on hv.cdfolhapagamento = f.cdfolhapagamento
         where hv.cdvinculo = pCdVinculo
           and rownum < 2;

        if nvl(vPossui, 0) = 1 then
          return true;
        else
          return false;
        end if;

      exception
        when no_data_found then
          return false;

        when others then
          return false;

      end;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      -- Tratamento para multiplos vinculos
      vVlAliquotaOutroVinculo := 0;
      vVlBaseOutroVinculo     := 0;
      vVlDescOutroVinculo     := 0;

      if XTMPAG_VAR.vgCdRubBaseINSS <> pCdRubBaseINSS then
        bPossuiOutroVinculo := False;
      end if;

      if bPossuiOutroVinculo then

        XTMPAG_var.bPossuiDuploVinculoAno := TRUE;
        vVlBaseVinculo                    := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhapagamento,
                                                                               pcdvinculo        => pCdVinculo,
                                                                               pcdrubrica        => pCdRubBaseINSS);

        IF vVlBaseVinculo <= 0 THEN
          begin
            update epageventovinculo evv
               set evv.vlevento         = 0,
                   evv.vlpagamento      = 0,
                   evv.dtultalteracao   = sysdate,
                   evv.cdfolhapagamento = XTMPAG_var.vgFolha.CdFolhapagamento
             where evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
               and evv.cdvinculo = XTMPAG_VAR.vgCdVinculo
               and evv.cdtipoeventovinculo = 6
               and evv.nuanomesreferencia =
                   XTMPAG_var.vgFolha.NuAnoReferencia * 100 +
                   XTMPAG_var.vgFolha.NuMesReferencia
               and evv.cdfolhapagamento in
                   (select ff.cdfolhapagamento
                      from epagfolhapagamento ff
                     where ff.nuanoreferencia =
                           XTMPAG_var.vgFolha.NuAnoReferencia
                       and ff.numesreferencia =
                           XTMPAG_var.vgFolha.NuMesReferencia
                       and ff.cdagrupamento =
                           XTMPAG_var.vgFolha.CdAgrupamento
                       and ff.cdtipofolhapagamento =
                           XTMPAG_var.vgFolha.cdtipofolhapagamento);

          exception
            when no_data_found then
              null;

            when others then
              null;
          end;

        END IF;

        begin
          select nvl(max(evv.vlindice), 0),
                 nvl(sum(evv.vlevento), 0),
                 nvl(sum(evv.vlpagamento), 0)
            into vVlAliquotaOutroVinculo,
                 vVlBaseOutroVinculo,
                 vVlDescOutroVinculo
            from epageventovinculo evv
           where evv.cdvinculo <> pCdVinculo
             and evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
             and evv.cdtipoeventovinculo = 6
             and evv.nuanomesreferencia =
                 XTMPAG_var.vgFolha.NuAnoReferencia * 100 +
                 XTMPAG_var.vgFolha.NuMesReferencia
             and evv.vlevento > 0;
        exception
          when no_data_found then
            vVlAliquotaOutroVinculo := 0;
            vVlBaseOutroVinculo     := 0;
          when others then
            vVlAliquotaOutroVinculo := 0;
            vVlBaseOutroVinculo     := 0;
        end;

        -- Para folha definitiva descontar somente os valores das outras definitivas
        if XTMPAG_var.vgFolha.FlCalculoDefinitivo = XTMPAG_tipo.cnS then
          begin

            vVlDescOutroVinculo := 0;

            select nvl(sum(evv.vlpagamento), 0)
              into vVlDescOutroVinculo
              from epageventovinculo evv
             where evv.cdvinculo <> pCdVinculo
               and evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
               and evv.cdtipoeventovinculo = 6
               and evv.nuanomesreferencia =
                   XTMPAG_var.vgFolha.NuAnoReferencia * 100 +
                   XTMPAG_var.vgFolha.NuMesReferencia
               and evv.vlevento > 0
               and evv.cdfolhapagamento in
                   (select ff.cdfolhapagamento
                      from epagfolhapagamento ff
                     where ff.flcalculodefinitivo = XTMPAG_tipo.cnS
                       and ff.nuanoreferencia =
                           XTMPAG_var.vgFolha.NuAnoReferencia
                       and ff.numesreferencia =
                           XTMPAG_var.vgFolha.NuMesReferencia
                       and ff.cdtipocalculo IN
                           (XTMPAG_TIPO.CNTPCALCULONORMAL,
                            XTMPAG_TIPO.CNTPCALCULOSUPL));

          exception
            when no_data_found then
              vVlDescOutroVinculo := 0;
            when others then
              vVlDescOutroVinculo := 0;

          end;

        end if;

        /*
        IF pFolha.CdTipoFolha IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13)
           OR (XTMPAG_VAR.vgCdRubBaseINSS <> pCdRubBaseINSS
               AND pFolha.NuMesReferencia = 12
               AND pFolha.CdTipoFolha IN(XTMPAG_tipo.cnTpFolhaNormal, XTMPAG_tipo.cnTpFolhaCtisp))
           THEN
             IF XTMPAG_VAR.vgCdRubBaseINSS <> pCdRubBaseINSS
                THEN

                vVlDescOutroVinculo := FretornaVlSomaAnoRubricaCalc13(pCdVinculo, pFolha, 5, 513);
                vVlBaseOutroVinculo := FretornaVlSomaAnoRubricaCalc13(pCdVinculo, pFolha, 9, 1005);

               ELSE

                vVlDescOutroVinculo := FretornaVlSomaAnoRubrica(pCdVinculo, pFolha, 5, 523);
                vVlBaseOutroVinculo := FretornaVlSomaAnoRubrica(pCdVinculo, pFolha, 9, 1005);

            END IF;
         END IF;
        */
        -- Verifica a aliquota com base no somatorio dos vinculos
        i := 0;
        u := lFaixa.Count;
        WHILE i < (lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF ((vVlBaseVinculo + vVlBaseOutroVinculo) BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal) or
             ((vVlBaseVinculo + vVlBaseOutroVinculo) > lFaixa(u).vlFinal and lFaixa(i).VlAliquota = lFaixa(u).VlAliquota) THEN

            if XTMPAG_var.vgCalculo.FlGeral <> 'I' then

              begin

                insert into tmppagcalculocoletivo
                  select evv.cdfolhapagamento,
                         evv.cdvinculo,
                         to_char(sysdate, 'ddmmyyhh24mi'),
                         'J',
                         XTMPAG_var.vgFolha.CdAgrupamento,
                         sysdate
                    from epageventovinculo evv
                   where evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
                     and evv.cdtipoeventovinculo = 6
                     and evv.nuanomesreferencia =
                         XTMPAG_var.vgFolha.NuAnoReferencia * 100 +
                         XTMPAG_var.vgFolha.NuMesReferencia
                     and exists
                   (select 1
                            from epagfolhapagamento ff
                           where ff.cdfolhapagamento = evv.cdfolhapagamento
                             and ff.cdagrupamento =
                                 XTMPAG_var.vgFolha.CdAgrupamento
                             and ff.cdtipofolhapagamento =
                                 XTMPAG_var.vgFolha.CdTipoFolhaPagamento
                             and ff.cdtipocalculo =
                                 XTMPAG_var.vgFolha.CdTipoCalculo
                             and ff.nuanoreferencia =
                                 XTMPAG_var.vgFolha.NuAnoReferencia
                             and ff.numesreferencia =
                                 XTMPAG_var.vgFolha.NuMesReferencia
                             and ff.flfolhafechada = 'N');

                for recalc in (select *
                                 from tmppagcalculocoletivo tt
                                where tt.nusegmento =
                                      XTMPAG_var.vgvinculo.cdpessoa
                                  and tt.flcalculado = 'J')

                 loop
                  select fol.cdorgao
                    into vCdOrgaoOutroVinculo
                    from epagfolhapagamento fol
                   where fol.cdfolhapagamento = recalc.cdfolhapagamento;

                  select fol.cdfolhapagamento
                    into vCdFolhaOutroVinculo
                    from epagfolhapagamento fol
                   where fol.cdorgao = vCdOrgaoOutroVinculo
                     and fol.cdtipofolhapagamento =
                         XTMPAG_var.vgFolha.CdTipoFolhaPagamento
                     and fol.cdtipocalculo =
                         XTMPAG_var.vgFolha.CdTipoCalculo
                     and fol.nuanoreferencia =
                         XTMPAG_var.vgFolha.NuAnoReferencia
                     and fol.numesreferencia =
                         XTMPAG_var.vgFolha.NuMesReferencia
                     and fol.cdagrupamento =
                         XTMPAG_var.vgFolha.CdAgrupamento
                     and fol.flfolhafechada = 'N';

                  update tmppagcalculocoletivo tt
                     set tt.cdfolhapagamento = vCdFolhaOutroVinculo
                   where tt.cdvinculo = recalc.cdvinculo
                     and tt.flcalculado = 'J';

                -- commit;

                end loop;

              exception
                when no_data_found then
                  null;

                when others then
                  null;
              end;

            end if;

            vVlAliquotaOutroVinculo := lFaixa(i).VlAliquota;

            i := lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      end if;

      FOR c IN cBase(pFolha.CdTipoCalculo,
                     pCdRubAgrupDescINSS,
                     pCdRubAgrupDifDesc,
                     pCdRubAgrupDevDesc) LOOP

        i := 0;

        vVlBaseOutrasFolhas := c.vlBase - vVlBaseVinculo;

        vVlefetivadoOutrasFolhas := c.vldeduzido;

        -- Para apuração do índice, soma base de outro agrupamento
        vVlBaseTotal := c.vlBase; -- + NVL(vVlBaseAnt,0);

        -- Limita base ao teto
        IF vVlBaseTotal > XTMPAG_VAR.vAliqINSS.vlTeto THEN

          vVlBase := XTMPAG_VAR.vAliqINSS.vlTeto;

        ELSE

          vVlBase := vVlBaseTotal;

        END IF;

        PAtualizaBaseINSS(pvlBase => c.vlBase);

        IF (XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
           XTMPAG_TIPO.cnRelResidente) OR
           XTMPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes OR
           bPossuiOutroVinculo THEN

          -- CIASC SIG-2169 Aliquota de INSS de conselheiros
          -- CIASC SIG-8752 Contribuicao Previdenciaria Diretor (individual) Relacao trabalho = 13
          if (XTMPAG_VAR.vgRecolhimentoAvulso.CdRecolhimentoAvulso IS NULL and
             XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento in (13, 15) and
             XTMPAG_var.vgFolha.CdOrgao = 3) OR
             XTMPAG_VAR.vgVinculo.cdregimetrabalho = 6 THEN
            -- contribuinte individual (diretores não empregados do regime previdenciário 1 - regime geral(INSS)

            vvlContribuicao := vVlBase * lFaixa(lFaixa.Last).Vlaliqcontribindividual / 100;

            if bPossuiOutroVinculo then

              vvlContribuicao := least((vvlContribuicao -
                                       NVL(lFaixa(lFaixa.Last).VlParcelaDeducao,
                                            0) - vVlDescOutroVinculo),
                                       lFaixa(lFaixa.Last).VLTETOCONTRIBINDIVIDUAL);

            else

              vvlContribuicao := least((vvlContribuicao -
                                       NVL(lFaixa(lFaixa.Last).VlParcelaDeducao,
                                            0)),
                                       lFaixa(lFaixa.Last).VLTETOCONTRIBINDIVIDUAL);

            end if;

            vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                               nvl(c.vlDeduzido, 0),
                                               vvlContribuicao);

            InsereRubricaINSS(c.CdVinculo,
                              vCdRubricaGerada,
                              pFolha.CdFolhaPagamento,
                              vvlContribuicao,
                              1,
                              lFaixa(lFaixa.Last).Vlaliqcontribindividual);

            -- Caso nao possua recolhimento avulso de previdencia aplica as faixas
          elsif (XTMPAG_VAR.vgRecolhimentoAvulso.CdRecolhimentoAvulso IS NULL) AND
                XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> 19 THEN

            if bPossuiOutroVinculo then

              -- Altera aliquota de todos os vinculos
              begin
                update epageventovinculo evv
                   set evv.vlindice       = vVlAliquotaOutroVinculo,
                       evv.dtultalteracao = sysdate
                 where evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
                   and evv.cdtipoeventovinculo = 6
                   and evv.nuanomesreferencia =
                       XTMPAG_var.vgFolha.NuAnoReferencia * 100 +
                       XTMPAG_var.vgFolha.NuMesReferencia;

                -- commit;

              exception
                when no_data_found then
                  vVlAliquotaOutroVinculo := 0;
                  vVlBaseOutroVinculo     := 0;

                when others then
                  vVlAliquotaOutroVinculo := 0;
                  vVlBaseOutroVinculo     := 0;

              end;
              --
              -- Duplo vinculo com folha de ferias que inss gera somente na NORMAL, usar a base do cursor - base de outros vinculos
              --
              if XTMPAG_var.vgParamPagamento.flgerainssfolhaferias =
                 XTMPAG_tipo.cnN and fPossuiFolhaFerias(pCdVinculo) then

                vVlBaseVinculo := c.VlBase - vVlBaseOutroVinculo;

              end if;

              vVlBaseTotal := vVlBaseVinculo + vVlBaseOutrasFolhas +
                              vVlBaseOutroVinculo;

              vVlAliquotaOutroVinculo := fRetornaAliquota(vVlBaseTotal,
                                                          lFaixa);

              vVlDescTotal := vVlBaseTotal *
                              (vVlAliquotaOutroVinculo / 100);

              vVlDescOutrasFolhas := vVlBaseOutrasFolhas *
                                     (vVlAliquotaOutroVinculo / 100);

              if vVlDescOutrasFolhas > 0 then
                vVlDescOutrasFolhas := vVlDescOutrasFolhas - c.Vldeduzido;
              end if;

              vVlContribuicao := vVlBaseVinculo *
                                 (vVlAliquotaOutroVinculo / 100);

              if vVlDescTotal > (vVlContribuicao + vVlDescOutrasFolhas +
                 vVlDescOutroVinculo) then

                vVlContribuicao := vVlContribuicao + vVlDescOutrasFolhas;

              end if;

              if vVlContribuicao + vVlDescOutroVinculo +
                 vVlDescOutrasFolhas > XTMPAG_var.vgValorReferenciaMAXINSS then

                vVlContribuicao := XTMPAG_var.vgValorReferenciaMAXINSS -
                                   (vVlDescOutroVinculo + c.VlDeduzido);

              end if;

              if XTMPAG_var.vgFolha.cdtipoCalculo =
                 XTMPAG_tipo.cnTpCalculoRecalculoMes then
                vVlContribuicao := least(vVlContribuicao,
                                         XTMPAG_var.vgValorReferenciaMAXINSS) -
                                   vVlefetivadoOutrasFolhas;

                If vVlContribuicao < 0 then
                  vVlContribuicao := 0;
                end if;
              end if;

              begin

                update epageventovinculo evv
                   set evv.vlevento         = vVlBaseVinculo,
                       evv.vlindice         = vVlAliquotaOutroVinculo,
                       evv.vlpagamento = case
                                           when vVlContribuicao < 0.02 then
                                            0
                                           else
                                            vvlContribuicao
                                         end,
                       evv.cdfolhapagamento = pFolha.CdFolhaPagamento,
                       evv.dtultalteracao   = sysdate
                 where evv.cdeventovinculo = vCdEventoVinculo
                   and evv.cdfolhapagamento in
                       (select ff.cdfolhapagamento
                          from epagfolhapagamento ff
                         where ff.nuanoreferencia = pFolha.NuAnoReferencia
                           and ff.numesreferencia = pFolha.NuMesReferencia
                           and ff.cdagrupamento = pFolha.CdAgrupamento
                           and ff.cdtipofolhapagamento =
                               pFolha.cdtipofolhapagamento);

              exception
                when no_data_found then
                  null;

                when others then
                  null;
              end;

              vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                 nvl(c.vlDeduzido, 0),
                                                 vvlContribuicao);

              InsereRubricaINSS(pCdVinculo,
                                vCdRubricaGerada,
                                pFolha.CdFolhaPagamento,
                                case when vVlContribuicao < 0.02 then 0 else
                                vvlContribuicao end,
                                1,
                                vVlAliquotaOutroVinculo);

              if XTMPAG_var.vgFolha.FlCalculoDefinitivo = XTMPAG_tipo.cnS then

                -- Atualizar valores descontados dos outros vinculos abatendo o valor do vinculo calculado de outros agrupamentos
                begin

                  update epageventovinculo evv
                     set evv.vlpagamento    = abs(least((evv.vlevento *
                                                        (evv.vlindice / 100)),
                                                        XTMPAG_var.vgValorReferenciaMAXINSS) -
                                                  vVlContribuicao),
                         evv.dtultalteracao = sysdate
                   where evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
                     and evv.cdvinculo <> pCdVinculo
                     and evv.cdtipoeventovinculo = 6
                     and evv.nuanomesreferencia =
                         XTMPAG_var.vgFolha.NuAnoReferencia * 100 +
                         XTMPAG_var.vgFolha.NuMesReferencia
                     and evv.cdfolhapagamento in
                         (select ff.cdfolhapagamento
                            from epagfolhapagamento ff
                           where ff.flcalculodefinitivo = XTMPAG_tipo.cnN
                             and ff.cdagrupamento <>
                                 XTMPAG_var.vgFolha.CdAgrupamento
                             and ff.nuanoreferencia =
                                 XTMPAG_var.vgFolha.NuAnoReferencia
                             and ff.numesreferencia =
                                 XTMPAG_var.vgFolha.NuMesReferencia
                             and ff.cdtipocalculo IN
                                 (XTMPAG_TIPO.CNTPCALCULONORMAL,
                                  XTMPAG_TIPO.CNTPCALCULOSUPL));

                exception
                  when no_data_found then
                    null;

                  when others then
                    null;
                end;

              end if;

            else

              WHILE i < (lFaixa.COUNT)

               LOOP

                i := i + 1;

                IF (vVlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal) THEN

                  vvlContribuicao := (LEAST(vVlBaseTotal,
                                            XTMPAG_VAR.vAliqINSS.vlTeto)) * lFaixa(i).VlAliquota / 100;
                  if nvl(vCdAgrupDuploVinc, 0) <> 0 and
                     nvl(vCdAgrupDuploVinc, 0) <> pFolha.CdAgrupamento then

                    vvlContribuicao := vvlContribuicao -
                                       NVL(lFaixa(i).VlParcelaDeducao, 0) -
                                       nvl(vvlinssant, 0);

                  ELSE

                    vvlinssant := 0;

                    IF XTMPAG_var.bPossuiDuploVinculoAno THEN
                      -- Neste caso, aplica-se o desconto do valor abatido de 13 noutro vinculo que foi encerrado.
                      SELECT nvl(SUM(rv.vlpagamento), 0)
                        INTO vvlinssant
                        FROM epaghistoricorubricavinculo rv
                       INNER JOIN ecadvinculo v
                          ON v.cdvinculo = rv.cdvinculo
                         AND v.cdvinculo <> pcdvinculo
                       INNER JOIN epagfolhapagamento fp
                          ON fp.cdfolhapagamento = rv.cdfolhapagamento
                         AND fp.nuanomesreferencia BETWEEN
                             pFolha.NuAnoReferencia * 100 + 01 AND
                             pFolha.NuAnoReferencia * 100 +
                             pfolha.NuMesReferencia
                         AND fp.flcalculodefinitivo = 'S'
                       WHERE v.cdpessoa = XTMPAG_var.vgVinculo.cdpessoa
                         AND rv.cdrubricaagrupamento = pCdRubAgrupDescINSS; -- 05-0513

                    END IF;

                    vvlContribuicao := vvlContribuicao -
                                       NVL(lFaixa(i).VlParcelaDeducao, 0) -
                                       NVL(c.vlDeduzido, 0) -
                                       NVL(vvlinssant, 0);

                  end if;

                  vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                     nvl(c.vlDeduzido, 0),
                                                     vvlContribuicao);

                  InsereRubricaINSS(c.CdVinculo,
                                    vCdRubricaGerada,
                                    pFolha.CdFolhaPagamento,
                                    vvlContribuicao,
                                    1,
                                    lFaixa(i).VlAliquota);

                  i := lFaixa.COUNT + 1;

                END IF;

              END LOOP;

            end if;
            --
            -- Solicitacao de Sustentacao #74943
            -- SEA - 7912/2015 - FIXAR ALIQUOTA UNICA PARA A RELACAO DE VINCULO CONSELHEIRO JETON
            -- CdRelTrabPagamento = 19
            --
          ELSIF XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica IS NOT NULL OR
                XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 19

           THEN

            IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 19 THEN
              XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica := lFaixa(lFaixa.Last).Vlaliqcontribindividual;
            END IF;

            IF FDeduzAliqDuploVinc(vCdAgrupDuploVinc, c.vlBase, vVlBaseAnt) THEN

              -- Aplica indice sobre base total
              vvlContribuicao := least((vVlBase * lFaixa(lFaixa.Last).Vlaliqcontribindividual / 100),
                                       lFaixa(lFaixa.Last).VLTETOCONTRIBINDIVIDUAL);

              -- Deduz o que ja foi descontado noutro agrupamento.
              vvlContribuicao := vvlContribuicao - NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao,
                                                       0) -
                                 NVL(c.vlDeduzido, 0) - NVL(vVlInssAnt, 0);

            ELSE

              -- Aplica indice sobre base no agrupamento
              vvlContribuicao := LEAST((c.vlBase * lFaixa(lFaixa.Last).Vlaliqcontribindividual / 100),
                                       lFaixa(lFaixa.Last).VLTETOCONTRIBINDIVIDUAL);

              -- Deduz o que ja foi descontado no agrupamento
              vvlContribuicao := vvlContribuicao - NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao,
                                                       0) -
                                 NVL(c.vlDeduzido, 0);

            END IF;

            vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                               nvl(c.vlDeduzido, 0),
                                               vvlContribuicao);

            InsereRubricaINSS(c.CdVinculo,
                              vCdRubricaGerada,
                              pFolha.CdFolhaPagamento,
                              vvlContribuicao,
                              1,
                              lFaixa(lFaixa.Last).Vlaliqcontribindividual);

          ELSIF XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento IS NOT NULL THEN

            vVlBase := vVlBase +
                       XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento;

            IF vVlBase > XTMPAG_VAR.vAliqINSS.vlTeto THEN

              vVlBase := XTMPAG_VAR.vAliqINSS.vlTeto;

            END IF;

            WHILE i < (lFaixa.COUNT)

             LOOP

              i := i + 1;

              IF (vVlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal) THEN

                vvlContribuicao := vVlBase * lFaixa(i).VlAliquota / 100;

                vvlContribuicao := vvlContribuicao -
                                   NVL(lFaixa(i).VlParcelaDeducao, 0) -
                                   nvl(c.vlDeduzido, 0) -
                                   NVL(XTMPAG_VAR.vgRecolhimentoAvulso.VlRecolhimento,
                                       0);

                vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                   nvl(c.vlDeduzido, 0),
                                                   vvlContribuicao);

                InsereRubricaINSS(c.CdVinculo,
                                  vCdRubricaGerada,
                                  pFolha.CdFolhaPagamento,
                                  vvlContribuicao,
                                  1,
                                  lFaixa(i).VlAliquota);

                i := lFaixa.COUNT + 1;

              END IF;

            END LOOP;

          else
            null;
          END IF;

        ELSE
          -- residentes

          vvlContribuicao := least((vVlBase * lFaixa(lFaixa.Last).Vlaliqcontribindividual / 100),
                                   lFaixa(lFaixa.Last).VLTETOCONTRIBINDIVIDUAL);

          vvlContribuicao := vvlContribuicao -
                             NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao, 0) -
                             nvl(c.vlDeduzido, 0);

          vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                             nvl(c.vlDeduzido, 0),
                                             vvlContribuicao);

          InsereRubricaINSS(c.CdVinculo,
                            vCdRubricaGerada,
                            pFolha.CdFolhaPagamento,
                            vvlContribuicao,
                            1,
                            lFaixa(lFaixa.Last).Vlaliqcontribindividual);

        END IF;

      END LOOP;

    END;

    PROCEDURE pAplicaAliquotaProgressiva(lFaixa IN XTMPAG_TIPO.tFaixaAliquota) IS

      i                       INTEGER := 0;
      vCdRubricaGerada        INTEGER;
      vVlBase                 NUMBER(15, 4);
      vVlBaseVinculo          NUMBER(15, 4);
      vVlAliquotaOutroVinculo NUMBER(10, 4) := 0;
      vVlAliquotaVinculo      number(10, 4);
      vAliquotaEfetiva        number(10, 4);
      vVlBaseOutroVinculo     NUMBER(15, 4) := 0;
      vVlDescOutroVinculo     NUMBER(13, 2) := 0;

      vvlBaseOutroVincOutroAgrup        NUMBER(13, 2) := 0;
      vvlDescOutroVincOutroAgrup        NUMBER(13, 2) := 0;
      vVlAliquotaOutroVinculoOutroAgrup NUMBER(10, 4) := 0;

      vVlBaseOutrasFolhas number(15, 2) := 0;
      vVlDescOutrasFolhas number(15, 2) := 0;
      vVlDescTotal        number(15, 2) := 0;

      procedure pProcessaParalelo(pCdFolha             in integer,
                                  pCdVinculo           in integer,
                                  pFlCalculoDefinitivo in Char) is

      begin
        -- xtmpag_util.pGravaLogCallStack;
        INSERT INTO tmppagcalculocoletivo
          SELECT pCdFolha,
                 pCdVinculo,
                 to_char(SYSDATE, 'ddmmyyhh24mi'),
                 'J',
                 XTMPAG_var.vgfolha.cdagrupamento,
                 SYSDATE
            FROM dual;
      exception
        when others then
          null;

      end;

      procedure pProcessaParalelo2(pCdFolha             in integer,
                                   pCdVinculo           in integer,
                                   pFlCalculoDefinitivo in Char) is

      begin
        -- xtmpag_util.pGravaLogCallStack;
        INSERT INTO tmppagcalculocoletivo
          SELECT evv.cdfolhapagamento,
                 evv.cdvinculo,
                 to_char(SYSDATE, 'ddmmyyhh24mi'),
                 'J',
                 XTMPAG_var.vgfolha.cdagrupamento,
                 SYSDATE
            FROM epageventovinculo evv
           WHERE evv.cdvinculo = pCdVinculo
             AND evv.cdtipoeventovinculo = 6
             AND evv.nuanomesreferencia =
                 XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                 XTMPAG_var.vgfolha.numesreferencia
             AND EXISTS
           (SELECT 1
                    FROM epagfolhapagamento ff
                   WHERE ff.cdfolhapagamento = evv.cdfolhapagamento
                     AND ff.cdagrupamento = XTMPAG_var.vgfolha.cdagrupamento
                     AND ff.cdtipofolhapagamento =
                         XTMPAG_var.vgfolha.cdtipofolhapagamento
                     AND ff.cdtipocalculo = XTMPAG_var.vgfolha.cdtipocalculo
                     AND ff.nuanoreferencia =
                         XTMPAG_var.vgfolha.nuanoreferencia
                     AND ff.numesreferencia =
                         XTMPAG_var.vgfolha.numesreferencia
                     AND ff.flfolhafechada = 'N')
             and not exists
           (select 1
                    from tmppagcalculocoletivo tc
                   where tc.cdvinculo = pcdvinculo
                     and tc.flcalculado = 'J'
                     and tc.cdfolhapagamento = evv.cdfolhapagamento);

      exception
        when others then
          null;
      end;

      FUNCTION fpossuirecolhimentoavulso(pcdpessoa  IN INTEGER,
                                         pcdvinculo IN INTEGER) RETURN CHAR IS

        vflrecolhimentoteto CHAR(1);

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        vvlbaserecolhimentoavulso := 0;

        vvlrecolhimentoavulso := 0;

        SELECT t.flrecolhimentoteto, t.vlbaserecolhimento, t.vlrecolhimento
          INTO vflrecolhimentoteto,
               vvlbaserecolhimentoavulso,
               vvlrecolhimentoavulso
          FROM etrbrecolhimentoavulso t
         WHERE t.cdpessoa = pcdpessoa
           AND (t.cdvinculo IS NULL OR t.cdvinculo = pcdvinculo)
           AND t.flanulado = 'N'
           AND t.cdobjetorecolhimento = 1
           AND (t.flrecolhimentoteto = 'S')
           AND ((t.nuanoinicio < XTMPAG_var.vgfolha.nuanoreferencia OR
               (t.nuanoinicio = XTMPAG_var.vgfolha.nuanoreferencia AND
               t.numesinicio <= XTMPAG_var.vgfolha.numesreferencia)) AND
               (t.nuanofim > XTMPAG_var.vgfolha.nuanoreferencia OR
               (t.nuanofim = XTMPAG_var.vgfolha.nuanoreferencia AND
               t.numesfim >= XTMPAG_var.vgfolha.numesreferencia) OR
               t.nuanofim IS NULL));

        RETURN vflrecolhimentoteto;

      EXCEPTION
        WHEN OTHERS THEN
          RETURN 'N';

      END;

      FUNCTION fpossuifolhaferias(pcdvinculo IN INTEGER)

       RETURN BOOLEAN IS

        vpossui INTEGER := 0;

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        WITH fol AS
         (SELECT ff.cdfolhapagamento
            FROM epagfolhapagamento ff
           INNER JOIN epagtipofolhapagamento tf
              ON tf.cdtipofolhapagamento = ff.cdtipofolhapagamento
             AND tf.cdtipofolha = XTMPAG_tipo.cntpfolhaferias
           WHERE ff.cdagrupamento = XTMPAG_var.vgfolha.cdagrupamento
             AND ff.cdorgao = XTMPAG_var.vgfolha.cdorgao
             AND ff.nuanoreferencia = XTMPAG_var.vgfolha.nuanoreferencia
             AND ff.numesreferencia = XTMPAG_var.vgfolha.numesreferencia
             AND ff.flcalculodefinitivo = XTMPAG_tipo.cns)
        SELECT 1
          INTO vpossui
          FROM epaghistoricorubricavinculo hv
         INNER JOIN fol f
            ON hv.cdfolhapagamento = f.cdfolhapagamento
         WHERE hv.cdvinculo = pcdvinculo
           AND rownum < 2;

        IF nvl(vpossui, 0) = 1 THEN
          RETURN TRUE;
        ELSE
          RETURN FALSE;
        END IF;

      EXCEPTION
        WHEN no_data_found THEN
          RETURN FALSE;

        WHEN OTHERS THEN
          RETURN FALSE;

      END;

      FUNCTION faplicaaliquotaprogressiva(lfaixa      IN XTMPAG_tipo.tfaixaaliquota,
                                          lvlbaseinss IN NUMBER)
        RETURN NUMBER IS

        vvlaliquota NUMBER(10, 4);

        vvlbaseprogressiva NUMBER := 0;

        ind INTEGER;

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        if lvlbaseinss <= 0 then
          return 0;
        end if;

        vvlcontribuicao := 0;

        ind := 0;

        WHILE ind < lfaixa.count

         LOOP

          ind := ind + 1;

          IF lvlbaseinss >= lfaixa(ind).vlinicial THEN

            IF lvlbaseinss > lfaixa(ind).vlfinal THEN

              IF ind > lfaixa.first THEN

                vvlbaseprogressiva := lfaixa(ind).vlfinal - lfaixa(ind - 1).vlfinal;

              ELSE

                vvlbaseprogressiva := lfaixa(ind).vlfinal;

              END IF;

            ELSE
              IF ind > 1 THEN
                vvlbaseprogressiva := lvlbaseinss - lfaixa(ind - 1).vlfinal;

              ELSE
                vvlbaseprogressiva := lvlbaseinss;
              END IF;

            END IF;

            IF vvlbaseprogressiva > lfaixa(lfaixa.last).vlfinal THEN

              vvlbaseprogressiva := lfaixa(lfaixa.last).vlfinal - lfaixa(lfaixa.last - 1).vlfinal;

            END IF;

            vvlcontribuicao := vvlcontribuicao + trunc((vvlbaseprogressiva * lfaixa(ind).vlaliquota / 100),
                                                       2);

          END IF;

        END LOOP;

        vvlaliquota     := round(vvlcontribuicao /
                                 least(lvlbaseinss,
                                       lfaixa(lfaixa.last).vlfinal) * 100,
                                 4);
        --vvlcontribuicao := round(vvlBaseVinculo * vvlaliquota / 100, 2);

        IF XTMPAG_var.vgFolha.CdOrgao = 7 and nvl(vVlBaseVinculo, 0) = 0 THEN
          --COHAB
          vVlContribuicao := round(vVlBaseTotal * (vvlaliquota / 100), 2);
        END IF;

        RETURN vvlaliquota;

      exception
        when others then
          return 0;

      END;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vVlBaseVinculo := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhapagamento,
                                                          pcdvinculo        => pCdVinculo,
                                                          pcdrubrica        => pCdRubBaseINSS);

      if fPossuiRecolhimentoAvulso(XTMPAG_var.vgVinculo.CdPessoa,
                                   XTMPAG_var.vgVinculo.CdVinculo) = 'S' then
        return;
      end if;

      -- Tratamento para multiplos vinculos
      vVlAliquotaOutroVinculo := 0;
      vVlBaseOutroVinculo     := 0;
      vVlDescOutroVinculo     := 0;
      vVlAliquotaVinculo      := 0;

      if XTMPAG_VAR.vgCdRubBaseINSS <> pCdRubBaseINSS and
         pFolha.CdTipoFolha <> XTMPAG_tipo.cnTpFolha13 then
        bPossuiOutroVinculo := False;
      end if;

      if XTMPAG_VAR.vgCdRubBaseINSS13 = pCdRubBaseInss and
         vVlBaseVinculo = 0 then
        return;
      end if;

      if vVlBaseVinculo = 0 and XTMPAG_VAR.vgNuDiasAfastSemRemun >= 30 then
        return;
      end if;

      if bPossuiOutroVinculo then

        IF vVlBaseVinculo <= 0 THEN
          BEGIN
            UPDATE epageventovinculo evv
               SET evv.vlevento         = 0,
                   evv.vlpagamento      = 0,
                   evv.dtultalteracao   = SYSDATE,
                   evv.cdfolhapagamento = XTMPAG_var.vgfolha.cdfolhapagamento
             WHERE evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
               AND evv.cdvinculo = XTMPAG_var.vgcdvinculo
               AND evv.cdtipoeventovinculo = 6
               AND evv.nuanomesreferencia =
                   XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                   XTMPAG_var.vgfolha.numesreferencia
               AND evv.cdfolhapagamento IN
                   (SELECT ff.cdfolhapagamento
                      FROM epagfolhapagamento ff
                     WHERE ff.nuanoreferencia =
                           XTMPAG_var.vgfolha.nuanoreferencia
                       AND ff.numesreferencia =
                           XTMPAG_var.vgfolha.numesreferencia
                       AND ff.cdagrupamento =
                           XTMPAG_var.vgfolha.cdagrupamento
                       AND ff.cdtipofolhapagamento =
                           XTMPAG_var.vgfolha.cdtipofolhapagamento);

          EXCEPTION
            WHEN no_data_found THEN
              NULL;

            WHEN OTHERS THEN
              NULL;
          END;

        end if;

        BEGIN

          IF XTMPAG_var.bpossuiduplovinculoano THEN
            /*  SELECT nvl(MAX(evv.vlindice), 0),
                  nvl(SUM(evv.vlevento), 0),
                  nvl(SUM(evv.vlpagamento), 0)
             INTO vvlaliquotaoutrovinculo,
                  vvlbaseoutrovinculo,
                  vvldescoutrovinculo
             FROM epageventovinculo evv
            WHERE evv.cdvinculo <> pcdvinculo
              AND evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
              AND evv.cdtipoeventovinculo = 6
              AND evv.nuanomesreferencia BETWEEN
                  XTMPAG_var.vgfolha.nuanoreferencia * 100 + 01 AND
                  XTMPAG_var.vgfolha.nuanoreferencia * 100 + 12
              AND evv.vlevento > 0;*/

            SELECT NVL(SUM(VLBASE), 0),
                   NVL(SUM(VLDESCONTO), 0),
                   NVL(SUM(VLINDICERUBRICA), 0)
              INTO vvlbaseoutrovinculo,
                   vvldescoutrovinculo,
                   vvlaliquotaoutrovinculo
              FROM (SELECT CASE
                             WHEN RV.CDRUBRICAAGRUPAMENTO = pCdRubBaseInss THEN
                              NVL(SUM(RV.VLPAGAMENTO), 0)
                             ELSE
                              0
                           END VLBASE,
                           CASE
                             WHEN RV.CDRUBRICAAGRUPAMENTO =
                                  pCdRubAgrupDescINSS THEN
                              NVL(SUM(RV.VLPAGAMENTO), 0)
                             ELSE
                              0
                           END VLDESCONTO,
                           MAX(RV.VLINDICERUBRICA) VLINDICERUBRICA
                      FROM epaghistoricorubricavinculo rv
                     INNER JOIN ecadvinculo v
                        ON rv.cdvinculo = v.cdvinculo
                       AND v.flanulado = 'N'
                     INNER JOIN epagfolhapagamento fp
                        ON fp.cdfolhapagamento = rv.cdfolhapagamento
                          --AND (fp.cdtipofolhapagamento = XTMPAG_var.vgFolha.cdtipofolhapagamento
                       AND (fp.cdtipocalculo =
                           XTMPAG_var.vgFolha.cdtipocalculo AND
                           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'N' AND
                           fp.flcalculodefinitivo IN ('S', 'N')) OR
                           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S' AND
                           fp.flcalculodefinitivo = 'S'))
                     WHERE rv.cdvinculo <> pcdvinculo
                       AND v.cdpessoa = XTMPAG_var.vgvinculo.cdpessoa
                       AND rv.cdrubricaagrupamento IN
                           (pCdRubAgrupDescINSS, pCdRubBaseInss)
                       AND fp.nuanomesreferencia BETWEEN
                           XTMPAG_var.vgfolha.nuanoreferencia * 100 + 01 AND
                           XTMPAG_var.vgfolha.nuanoreferencia * 100 + 12
                       AND rv.vlpagamento > 0
                     GROUP BY RV.CDRUBRICAAGRUPAMENTO);

          ELSE
            /*  SELECT nvl(MAX(evv.vlindice), 0),
                  nvl(SUM(evv.vlevento), 0),
                  nvl(SUM(evv.vlpagamento), 0)
             INTO vvlaliquotaoutrovinculo,
                  vvlbaseoutrovinculo,
                  vvldescoutrovinculo
             FROM epageventovinculo evv
            WHERE evv.cdvinculo <> pcdvinculo
              AND evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
              AND evv.cdtipoeventovinculo = 6
              AND evv.nuanomesreferencia =
                  XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                  XTMPAG_var.vgfolha.numesreferencia
              AND evv.vlevento > 0;*/

            SELECT NVL(SUM(VLBASE), 0),
                   NVL(SUM(VLDESCONTO), 0),
                   NVL(SUM(VLINDICERUBRICA), 0)
              INTO vvlbaseoutrovinculo,
                   vvldescoutrovinculo,
                   vvlaliquotaoutrovinculo
              FROM (SELECT CASE
                             WHEN RV.CDRUBRICAAGRUPAMENTO = pCdRubBaseInss THEN
                              NVL(SUM(RV.VLPAGAMENTO), 0)
                             ELSE
                              0
                           END VLBASE,
                           CASE
                             WHEN RV.CDRUBRICAAGRUPAMENTO =
                                  pCdRubAgrupDescINSS THEN
                              NVL(SUM(RV.VLPAGAMENTO), 0)
                             ELSE
                              0
                           END VLDESCONTO,
                           MAX(RV.VLINDICERUBRICA) VLINDICERUBRICA
                      FROM epaghistoricorubricavinculo rv
                     INNER JOIN ecadvinculo v
                        ON rv.cdvinculo = v.cdvinculo
                       AND v.flanulado = 'N'
                     INNER JOIN epagfolhapagamento fp
                        ON fp.cdfolhapagamento = rv.cdfolhapagamento
                          --AND (fp.cdtipofolhapagamento = XTMPAG_var.vgFolha.cdtipofolhapagamento
                       AND (fp.cdtipocalculo =
                           XTMPAG_var.vgFolha.cdtipocalculo AND
                           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'N' AND
                           fp.flcalculodefinitivo IN ('S', 'N')) OR
                           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S' AND
                           fp.flcalculodefinitivo = 'S'))
                     WHERE rv.cdvinculo <> pcdvinculo
                       AND v.cdpessoa = XTMPAG_var.vgvinculo.cdpessoa
                       AND rv.cdrubricaagrupamento IN
                           (pCdRubAgrupDescINSS, pCdRubBaseInss)
                       AND fp.nuanomesreferencia =
                           XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                           XTMPAG_var.vgfolha.numesreferencia
                       AND rv.vlpagamento > 0
                     GROUP BY RV.CDRUBRICAAGRUPAMENTO);
          END IF;

        EXCEPTION
          WHEN no_data_found THEN
            vvlaliquotaoutrovinculo := 0;
            vvlbaseoutrovinculo     := 0;
            vvldescoutrovinculo     := 0;
          WHEN OTHERS THEN
            vvlaliquotaoutrovinculo := 0;
            vvlbaseoutrovinculo     := 0;
            vvldescoutrovinculo     := 0;
        END;

        IF XTMPAG_var.vgFolha.FlCalculoDefinitivo = XTMPAG_tipo.cnS THEN

          BEGIN
            SELECT NVL(SUM(VLBASE), 0),
                   NVL(SUM(VLDESCONTO), 0),
                   NVL(SUM(VLINDICERUBRICA), 0)
              INTO vvlBaseOutroVincOutroAgrup,
                   vvlDescOutroVincOutroAgrup,
                   vvlaliquotaoutrovinculoOutroAgrup
              FROM (WITH TIPOFOLHA AS (SELECT CDTIPOFOLHAPAGAMENTO
                                         FROM EPAGTIPOFOLHAPAGAMENTO C
                                        WHERE C.CDTIPOFOLHA =
                                              XTMPAG_var.vgFolha.CDTIPOFOLHA), --1: NORMAL/ 3: 13SAL

                   DADOSVINCULO AS (SELECT CAPA.CDVINCULO,
                                           CAPA.CDFOLHAPAGAMENTO
                                      FROM EPAGCAPAHISTRUBRICAVINCULO CAPA
                                     INNER JOIN EPAGFOLHAPAGAMENTO FP
                                        ON FP.CDFOLHAPAGAMENTO =
                                           CAPA.CDFOLHAPAGAMENTO
                                       AND FP.NUANOMESREFERENCIA =
                                           XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                                           XTMPAG_var.vgfolha.numesreferencia
                                       AND ((XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'N' AND
                                           FP.FLCALCULODEFINITIVO IN
                                           ('S', 'N') AND
                                           FP.CDTIPOCALCULO =
                                           XTMPAG_var.vgFolha.CDTIPOCALCULO) OR
                                           (XTMPAG_var.vgFolha.FlCalculoDefinitivo = 'S' AND
                                           FP.FLCALCULODEFINITIVO = 'S'))
                                     INNER JOIN TIPOFOLHA T
                                        ON T.CDTIPOFOLHAPAGAMENTO =
                                           FP.CDTIPOFOLHAPAGAMENTO
                                     INNER JOIN ECADVINCULO V
                                        ON V.CDVINCULO = CAPA.CDVINCULO
                                     WHERE FP.CDAGRUPAMENTO <>
                                           XTMPAG_var.vgFolha.CdAgrupamento
                                       AND V.CDPESSOA =
                                           XTMPAG_var.vgvinculo.cdpessoa
                                     GROUP BY CAPA.CDVINCULO,
                                              CAPA.CDFOLHAPAGAMENTO)

                     SELECT CASE
                              WHEN RUB.NURUBRICA IN (903) THEN
                               NVL(SUM(HRV.VLPAGAMENTO), 0)
                              ELSE
                               0
                            END VLBASE,
                            CASE
                              WHEN RUB.NURUBRICA IN (512) THEN
                               NVL(SUM(HRV.VLPAGAMENTO), 0)
                              ELSE
                               0
                            END VLDESCONTO,
                            MAX(HRV.VLINDICERUBRICA) VLINDICERUBRICA
                       FROM EPAGHISTORICORUBRICAVINCULO HRV
                      INNER JOIN DADOSVINCULO D
                         ON D.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
                        AND D.CDVINCULO = HRV.CDVINCULO
                      INNER JOIN VPAGRUBRICAAGRUPAMENTO RUB
                         ON HRV.CDRUBRICAAGRUPAMENTO =
                            RUB.CDRUBRICAAGRUPAMENTO
                        AND RUB.CDRUBRICA IN
                            (SELECT CDRUBRICA
                               FROM VPAGRUBRICAAGRUPAMENTO
                              WHERE CDRUBRICAAGRUPAMENTO IN
                                    (pCdRubAgrupDescINSS, pCdRubBaseInss)));


          EXCEPTION
            WHEN no_data_found THEN
              vvlBaseOutroVincOutroAgrup        := 0;
              vvlDescOutroVincOutroAgrup        := 0;
              vvlaliquotaoutrovinculoOutroAgrup := 0;
            WHEN OTHERS THEN
              vvlBaseOutroVincOutroAgrup        := 0;
              vvlDescOutroVincOutroAgrup        := 0;
              vvlaliquotaoutrovinculoOutroAgrup := 0;
          END;
        END IF;

        if nvl(vVlAliquotaVinculo, 0) = 0 then
          vVlAliquotaVinculo := fAplicaAliquotaProgressiva(lFaixa,
                                                           vVlBaseVinculo);
        end if;

        vAliquotaEfetiva := fAplicaAliquotaProgressiva(lFaixa,
                                                       vVlBaseVinculo +
                                                       vVlBaseOutroVinculo);

        if XTMPAG_var.vgCalculo.FlGeral <> 'I' and
           XTMPAG_var.vgfolha.cdtipofolha <> XTMPAG_tipo.cntpfolha13 then

          pProcessaParalelo2(pFolha.CdFolhaPagamento,
                             pCdVinculo,
                             pFolha.FlCalculoDefinitivo);

        end if;

        -- Altera aliquota de todos os vinculos
        -- pAlteraAliquota
        BEGIN
          UPDATE epageventovinculo evv
             SET evv.vlindice       = valiquotaefetiva,
                 evv.dtultalteracao = SYSDATE
           WHERE evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
             AND evv.cdtipoeventovinculo = 6
             and evv.nucpfultimaalteracao = '22222222222'
             AND evv.nuanomesreferencia =
                 XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                 XTMPAG_var.vgfolha.numesreferencia;

        EXCEPTION
          WHEN no_data_found THEN
            valiquotaefetiva    := 0;
            vvlbaseoutrovinculo := 0;

          WHEN OTHERS THEN
            valiquotaefetiva    := 0;
            vvlbaseoutrovinculo := 0;

        END;

      end if;

      FOR c IN cBase(pFolha.CdTipoCalculo,
                     pCdRubAgrupDescINSS,
                     pCdRubAgrupDifDesc,
                     pCdRubAgrupDevDesc) LOOP

        i := 0;

        ----Implementação para capturar o valor da folha de ferias quando a folha de ferias não gera a 05-0512
        ----caso do orgão 25  - SIG--9949

         if XTMPAG_var.vgfolha.cdagrupamento IN (4,5)
            and XTMPAG_var.vgFolha.cdtipocalculo = XTMPAG_tipo.cnTpCalculoRecalculoMes then

             select sum(hrv.vlpagamento)
             into  vVlferias
             from  epaghistoricorubricavinculo hrv
             where hrv.cdvinculo=pCdVinculo
             and   hrv.cdrubricaagrupamento in (select XTMPAG_GERAL.FRetornaRubrica(XTMPAG_var.vgfolha.cdagrupamento,9,903) from dual)
             and   hrv.cdfolhapagamento in ( select fpg.cdfolhapagamento from
                                             epagfolhapagamento fpg
                                             inner join epagtipofolhapagamento tfp on fpg.cdtipofolhapagamento=tfp.cdtipofolhapagamento
                                             where fpg.cdorgao=XTMPAG_var.vgfolha.cdorgao
                                             and   fpg.nuanoreferencia=XTMPAG_var.vgfolha.nuanoreferencia
                                             and   fpg.numesreferencia=XTMPAG_var.vgfolha.numesreferencia
                                             and   tfp.cdtipofolha=XTMPAG_TIPO.cnTpFolhaFerias
                                             and   fpg.cdtipocalculo=1);

            c.vlBase := c.vlBase + nvl(vVlferias, 0);

         end if;

        -- Para apuração do índice, soma base de outro agrupamento
        vVlBaseTotal := nvl(c.vlBase, 0); -- + NVL(vVlBaseAnt,0);

        vVlBaseOutrasFolhas := nvl(nvl(c.vlBase, 0) - vVlBaseVinculo, 0);

        -- Limita base ao teto
        IF vVlBaseTotal > XTMPAG_VAR.vAliqINSS.vlTeto THEN
          vVlBase := XTMPAG_VAR.vAliqINSS.vlTeto;
        ELSE
          vVlBase := vVlBaseTotal;
        END IF;

        -- Valor deduzido no outro vinculo
        vVlDescOutroVinculo := c.Vldeduzido;

        PAtualizaBaseINSS(pvlBase => nvl(c.vlBase, 0));

        IF (XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <>
           XTMPAG_TIPO.cnRelResidente) OR
           (XTMPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes AND
            XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> XTMPAG_TIPO.cnRelResidente) OR
           (bPossuiOutroVinculo AND XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> XTMPAG_TIPO.cnRelResidente) THEN

          -- CIASC SIG-2169 Aliquota de INSS de conselheiros
          -- CIASC SIG-8752 Contribuicao Previdenciaria Diretor (individual) Relacao trabalho = 13
          if (XTMPAG_VAR.vgRecolhimentoAvulso.CdRecolhimentoAvulso IS NULL AND
             XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento in (15, 13) AND
             XTMPAG_var.vgFolha.CdOrgao IN (3)) OR
             (XTMPAG_VAR.vgVinculo.cdregimetrabalho = 6 AND
             XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento <> 19)
            -- contribuinte individual (diretores não empregados do regime previdenciário 1 - regime geral(INSS)
             OR (XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 15 AND
             XTMPAG_var.vgFolha.CdOrgao IN (7)) --  COHAB SIG-4742
           THEN

            if XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 15 then

              vVlContribuicao := vVlBaseVinculo * lFaixa(lFaixa.LAST).Vlaliqcontribindividual / 100;
              -- SIG-4413
              -- SEA - 14953/2020 - ERRO NA APURACAO DA TRIBUTACAO (INSS E IRRF) MULTIPLOS VINCULOS
              if FDuploVinculoVigenteEmp(XTMPAG_var.vgvinculo.cdpessoa,
                                         pFolha.DtInicioMes) and
                 pFolha.CdTipoOrgao in (1, 5) then

                if c.Vldeduzido >= XTMPAG_var.vgValorReferenciaVLDCI then

                  vVlContribuicao := 0;

                elsif c.Vldeduzido > 0 then

                  vVlContribuicao := vVlContribuicao - nvl(c.Vldeduzido,0);

                end if;

              end if;

            else

              vvlContribuicao := vVlBase * lFaixa(lFaixa.LAST).Vlaliqcontribindividual / 100;

              -- SIG-11196 Correcao no calculo de duplo vinculo onde ambos sao cargos comissionados
              vVlContribuicao := vVlContribuicao - nvl(c.Vldeduzido,0);

            end if;

            vvlContribuicao := vvlContribuicao -
                               NVL(lFaixa(lFaixa.Last).VlParcelaDeducao, 0);

            vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                               nvl(c.vlDeduzido, 0),
                                               vvlContribuicao);

            InsereRubricaINSS(c.CdVinculo,
                              vCdRubricaGerada,
                              pFolha.CdFolhaPagamento,
                              vvlContribuicao,
                              1,
                              lFaixa(lFaixa.LAST).Vlaliqcontribindividual);

            -- Caso nao possua recolhimento avulso de previdencia aplica as faixas
          elsif (XTMPAG_VAR.vgRecolhimentoAvulso.CdRecolhimentoAvulso IS NULL) AND
                XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento NOT IN
                (15, 19) THEN

            if bPossuiOutroVinculo then

              --
              -- Duplo vinculo com folha de ferias que inss gera somente na NORMAL, usar a base do cursor - base de outros vinculos
              --
              if XTMPAG_var.vgParamPagamento.flgerainssfolhaferias =
                 XTMPAG_tipo.cnN and fPossuiFolhaFerias(pCdVinculo) then

                vVlBaseVinculo := nvl(c.VlBase, 0) - vVlBaseOutroVinculo;

              end if;

              IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento =
                 XTMPAG_TIPO.cnRelResidente OR
                 XTMPAG_VAR.vgVinculo.cdregimetrabalho = 6 THEN
                --no caso dos residentes ou contribuinte individual, deve 1 calcular esta folha e aplicar a liquota de 11% apenas na base do vinculo,
                --desconsiderando outros vinculos ativos
                vVlBaseTotal        := vvlBase; -- vVlBaseVinculo;
               -- vVlDescOutroVinculo := 0;
               -- vVlBaseOutroVinculo := 0;
               -- vVlBaseOutrasFolhas := 0;

              ELSE

                vVlBaseTotal := vvlBase;
                --vVlBaseVinculo + vVlBaseOutrasFolhas + vVlBaseOutroVinculo;
              END IF;

              vAliquotaEfetiva := CASE -- é residente(mesma regra de contribuinte individual)
                                    WHEN XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento =
                                         XTMPAG_TIPO.cnRelResidente THEN
                                    -- alíquota é única para contribuinte individual
                                     lFaixa(lFaixa.LAST).Vlaliqcontribindividual
                                    ELSE
                                     fAplicaAliquotaProgressiva(lFaixa, vVlBaseTotal)
                                  END;

              vVlDescTotal := vVlBaseTotal * (vAliquotaEfetiva / 100);

              if vVlDescTotal > XTMPAG_var.vgValorReferenciaMAXINSS then

                vVlDescTotal := XTMPAG_var.vgValorReferenciaMAXINSS;

              end if;

              vVlContribuicao := least(round(vVlBaseVinculo *
                                             (vAliquotaEfetiva / 100),
                                             2),
                                       XTMPAG_var.vgValorReferenciaMAXINSS);

              if vVlDescTotal > (vVlContribuicao + vVlDescOutroVinculo) then

                if vVlDescOutroVinculo > 0 and vVlContribuicao > 0 then

                  vVlContribuicao := vVlContribuicao + vVlDescOutroVinculo;

                  vVlContribuicao := vVlDescTotal - vVlDescOutroVinculo;

                  IF XTMPAG_TIPO.cnRelResidente =
                     XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento AND
                     vVlContribuicao > lFaixa(lFaixa.LAST).Vltetocontribindividual THEN
                    -- para residentes limita ao teto da contribuição individual
                    vVlContribuicao := lFaixa(lFaixa.LAST).Vltetocontribindividual;
                  END IF;

                end if;

              elsif vVlContribuicao + vVlDescOutroVinculo >
                    least(vVlDescTotal, XTMPAG_var.vgValorReferenciaMAXINSS) then

                IF pFolha.FlCalculoDefinitivo = 'N' THEN

                  IF pFolha.CdAgrupamento = 1
                    --verifica o numero de vinculos do agrupamento
                     AND
                     FDuploVinculoVigenteOutroAgrup(pCdPessoa      => XTMPAG_var.vgvinculo.cdpessoa,
                                                    pCdAgrupamento => pFolha.CdAgrupamento) = 1
                  --AND vVlDescOutroVinculo > least(round(vVlBaseOutrasFolhas * (vAliquotaEfetiva / 100),2), XTMPAG_var.vgValorReferenciaMAXINSS)
                   THEN
                    --Se estiver calculando a folha da AGPE e o outro vinculo nao for da AGPE,
                    --prioriza o desc calculado
                    vVlContribuicao := LEAST(vVlContribuicao,
                                             XTMPAG_var.vgValorReferenciaMAXINSS);

                  ELSE
                    --senão, calcula o valor e desconta o que já foi calculado
                    vVlContribuicao := LEAST(vVlDescTotal,
                                             XTMPAG_var.vgValorReferenciaMAXINSS) -
                                       vVlDescOutroVinculo;
                  END IF;

                ELSE
                  vVlContribuicao := least(vVlDescTotal,
                                           XTMPAG_var.vgValorReferenciaMAXINSS) -
                                     vVlDescOutroVinculo;
                END IF;
              end if;

              if vVlDescOutroVinculo > 0 and
                 pFolha.CdTipoCalculo = XTMPAG_TIPO.cntpcalculorecalculomes and
                 vVlDescTotal > vVlContribuicao + vVlDescOutroVinculo then
                vVlContribuicao := vVlDescTotal - vVlDescOutroVinculo;

              end if;

              BEGIN

                UPDATE epageventovinculo evv
                   SET evv.vlevento         = vvlbasevinculo,
                       evv.vlindice         = valiquotaefetiva,
                       evv.vlpagamento = CASE
                                           WHEN vvlcontribuicao < 0.02 THEN
                                            0
                                           ELSE
                                            vvlcontribuicao
                                         END,
                       evv.cdfolhapagamento = pfolha.cdfolhapagamento,
                       evv.dtultalteracao   = SYSDATE
                 WHERE evv.cdeventovinculo = vcdeventovinculo
                   AND evv.cdfolhapagamento IN
                       (SELECT ff.cdfolhapagamento
                          FROM epagfolhapagamento ff
                         WHERE ff.nuanoreferencia = pfolha.nuanoreferencia
                           AND ff.numesreferencia = pfolha.numesreferencia
                           AND ff.cdagrupamento = pfolha.cdagrupamento
                           AND ff.cdtipofolhapagamento =
                               pfolha.cdtipofolhapagamento);

              EXCEPTION
                WHEN no_data_found THEN
                  NULL;

                WHEN OTHERS THEN
                  NULL;
              END;

              vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                 nvl(c.vlDeduzido, 0),
                                                 vvlContribuicao);

              InsereRubricaINSS(pCdVinculo,
                                vCdRubricaGerada,
                                pFolha.CdFolhaPagamento,
                                case when vVlContribuicao < 0.02 then 0 else
                                vvlContribuicao end,
                                1,
                                vAliquotaEfetiva);

              if XTMPAG_var.vgFolha.FlCalculoDefinitivo = XTMPAG_tipo.cnS then

                -- Atualizar valores descontados dos outros vinculos abatendo o valor do vinculo calculado de outros agrupamentos
                BEGIN

                  UPDATE epageventovinculo evv
                     SET evv.vlpagamento    = abs(least((evv.vlevento *
                                                        (evv.vlindice / 100)),
                                                        XTMPAG_var.vgvalorreferenciamaxinss) -
                                                  vvlcontribuicao),
                         evv.dtultalteracao = SYSDATE
                   WHERE evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
                     AND evv.cdvinculo <> pcdvinculo
                     AND evv.cdtipoeventovinculo = 6
                     and evv.nucpfultimaalteracao <> '22222222222'
                     AND evv.nuanomesreferencia =
                         XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                         XTMPAG_var.vgfolha.numesreferencia
                     AND evv.cdfolhapagamento IN
                         (SELECT ff.cdfolhapagamento
                            FROM epagfolhapagamento ff
                           WHERE ff.flcalculodefinitivo = XTMPAG_tipo.cnn
                             AND ff.cdagrupamento <>
                                 XTMPAG_var.vgfolha.cdagrupamento
                             AND ff.nuanoreferencia =
                                 XTMPAG_var.vgfolha.nuanoreferencia
                             AND ff.numesreferencia =
                                 XTMPAG_var.vgfolha.numesreferencia
                             AND ff.cdtipocalculo IN
                                 (XTMPAG_tipo.cntpcalculonormal,
                                  XTMPAG_tipo.cntpcalculosupl));

                EXCEPTION
                  WHEN no_data_found THEN
                    NULL;

                  WHEN OTHERS THEN
                    NULL;
                END;

              end if;

            else

              -- para o calculo da alíquota efetiva, contribuinte individual,
              -- consedera-se apenas o valor da base do vinculo em questão
              IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento =
                 XTMPAG_TIPO.cnRelResidente OR
                 XTMPAG_VAR.vgVinculo.cdregimetrabalho = 6 THEN
                vAliquotaEfetiva := fAplicaAliquotaProgressiva(lFaixa,
                                                               nvl(c.vlbase,
                                                                   0));
              ELSE
                vAliquotaEfetiva := fAplicaAliquotaProgressiva(lFaixa,
                                                               vvlbase
                                                               );
                -- SIG-6088 inss acima do teto - Desconsiderou base de ferias na SCPAR
                if pFolha.CdOrgao = 383 then
                  vVlBaseVinculo := vVlBase;
                end if;

              END IF;

              -- SIG-4199
              -- SEA - 14867/2020 - CALCULO INSS - EMPRESAS PUBLICAS
              if pFolha.CdTipoOrgao in (1, 5) OR
                 (pFolha.CdTipoOrgao not in (1, 5) and
                 XTMPAG_var.vgvinculo.cdregimeprevidenciario = 1) OR
                 pFolha.CdTipoFolhaPagamento IN (1505, 1525, 1526) THEN
                -- Folha Honorários PGE - O mesmo vínculo possui no mês dois tipos diferentes de folha

                if pFolha.cdagrupamento in (4, 5) and
                   (XTMPAG_var.vgParamPagamento.flgerainssfolhaferias =
                   XTMPAG_tipo.cnN and fPossuiFolhaFerias(pCdVinculo)) then

                  vVlBaseVinculo  := c.VlBase;
                  vVlContribuicao := round(vVlBaseVinculo * (vAliquotaEfetiva / 100),2);

                end if;

                vVlDescOutroVinculo := nvl(c.vldeduzido, 0);
                --vVlInssAnt

                if vVlContribuicao + vVlDescOutroVinculo >
                   XTMPAG_var.vgValorReferenciaMAXINSS then

                  vVlContribuicao := XTMPAG_var.vgValorReferenciaMAXINSS -
                                     nvl(vVlInssAnt, 0);

                elsif vVlContribuicao + vVlDescOutroVinculo >
                      round(vvlbase * (vAliquotaEfetiva / 100), 2) then

                  vVlContribuicao := round(vvlbase *
                                           (vAliquotaEfetiva / 100),
                                           2) - vVlDescOutroVinculo;
                end if;

                -- SIG-4413
                -- SEA - 14953/2020 - ERRO NA APURACAO DA TRIBUTACAO (INSS E IRRF) MULTIPLOS VINCULOS

                -- Priorizar vinculo efetivo quando possui outro vinculo de conselheiro
                if FDuploVinculoVigente(pCdPessoa    => XTMPAG_var.vgvinculo.cdpessoa,
                                        pDtInicioMes => pFolha.DtCalculoAnt + 1) > 1
                -- FDuploVinculoVigenteEmp(XTMPAG_var.vgvinculo.cdpessoa, pFolha.DtInicioMes)
                -- and XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 5
                 then
                  vVlContribuicao := vVlBaseVinculo * vAliquotaEfetiva / 100;

                  if vVlContribuicao > XTMPAG_var.vgValorReferenciaMAXINSS then

                    vVlContribuicao := XTMPAG_var.vgValorReferenciaMAXINSS;

                  end if;

                  vVlContribuicao := vVlContribuicao - nvl(c.vldeduzido, 0);

                end if;

              end if;
              ----SIG-9392
              if pfolha.CdOrgao = 383 and vVlDescOutroVinculo > 0
                 and vVlContribuicao + vVlDescOutroVinculo > XTMPAG_var.vgValorReferenciaMAXINSS and
                fPossuiFolhaFerias(pCdVinculo) and pfolha.CdTipoFolha = 1  then
                 vVlContribuicao :=  XTMPAG_var.vgValorReferenciaMAXINSS - vVlDescOutroVinculo;
              end if;


              if vVlContribuicao > 0 then

                vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                   nvl(vVlInssAnt, 0),
                                                   vvlContribuicao);

                InsereRubricaINSS(c.CdVinculo,
                                  vCdRubricaGerada,
                                  pFolha.CdFolhaPagamento,
                                  vvlContribuicao,
                                  1,
                                  vAliquotaEfetiva);

                BEGIN

                  UPDATE epageventovinculo evv
                     SET evv.vlevento         = vvlbasevinculo,
                         evv.vlindice         = valiquotaefetiva,
                         evv.vlpagamento = CASE
                                             WHEN vvlcontribuicao < 0.02 THEN
                                              0
                                             ELSE
                                              vvlcontribuicao
                                           END,
                         evv.cdfolhapagamento = pfolha.cdfolhapagamento,
                         evv.dtultalteracao   = SYSDATE
                   WHERE evv.cdeventovinculo = vcdeventovinculo
                     AND evv.cdfolhapagamento IN
                         (SELECT ff.cdfolhapagamento
                            FROM epagfolhapagamento ff
                           WHERE ff.nuanoreferencia = pfolha.nuanoreferencia
                             AND ff.numesreferencia = pfolha.numesreferencia
                             AND ff.cdagrupamento = pfolha.cdagrupamento
                             AND ff.cdtipofolhapagamento =
                                 pfolha.cdtipofolhapagamento);

                EXCEPTION
                  WHEN no_data_found THEN
                    NULL;

                  WHEN OTHERS THEN
                    NULL;
                END;
              end if;

            end if;
            --
            -- Solicitacao de Sustentacao #74943
            -- SEA - 7912/2015 - FIXAR ALIQUOTA UNICA PARA A RELACAO DE VINCULO CONSELHEIRO JETON
            -- CdRelTrabPagamento = 19
            --
          ELSIF XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica IS NOT NULL OR
                XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento IN
                (15, 19)

           THEN

            IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento IN (15, 19) THEN
              XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica := lFaixa(lFaixa.LAST).Vlaliqcontribindividual;

            END IF;

            if bPossuiOutroVinculo and
               XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = 19 then

              vVlContribuicao := vVlBaseVinculo *
                                 XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica / 100;

              if vVlContribuicao > XTMPAG_var.vgValorReferenciaVLDCI then

                vVlContribuicao := XTMPAG_var.vgValorReferenciaVLDCI;

              end if;

              UPDATE epageventovinculo evv
                 SET evv.vlevento             = vvlbasevinculo,
                     evv.vlindice             = XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica,
                     evv.vlpagamento = CASE
                                         WHEN vvlcontribuicao < 0.02 THEN
                                          0
                                         ELSE
                                          vvlcontribuicao
                                       END,
                     evv.cdfolhapagamento     = pfolha.cdfolhapagamento,
                     evv.dtultalteracao       = SYSDATE,
                     evv.nucpfultimaalteracao = '22222222222'
               WHERE evv.cdeventovinculo = vcdeventovinculo;

            else

              IF FDeduzAliqDuploVinc(vCdAgrupDuploVinc,
                                     nvl(c.vlBase, 0),
                                     vVlBaseAnt) AND vVlBaseAnt > 0 THEN

                -- Aplica indice sobre base total
                vvlContribuicao := vVlBase * lFaixa(lFaixa.LAST).Vlaliqcontribindividual / 100;

                -- Deduz o que ja foi descontado noutro agrupamento.
                vvlContribuicao := vvlContribuicao -
                                   NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao,
                                       0) - NVL(c.vlDeduzido, 0) -
                                   NVL(vVlInssAnt, 0);

              ELSE

                IF NVL(XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento,
                       0) > 0 THEN
                  -- Aplica indice sobre base no agrupamento
                  vvlContribuicao := (LEAST(nvl(c.vlBase, 0) +
                                            XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento,
                                            XTMPAG_VAR.vAliqINSS.vlTeto)) * lFaixa(lFaixa.LAST).Vlaliqcontribindividual / 100;

                  -- Deduz o que ja foi descontado no agrupamento
                  vvlContribuicao := vvlContribuicao -
                                     NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao,
                                         0) - NVL(c.vlDeduzido, 0) -
                                     NVL(XTMPAG_VAR.vgRecolhimentoAvulso.VlRecolhimento,
                                         0);
                ELSE

                  -- Aplica indice sobre base no agrupamento
                  vvlContribuicao := (LEAST(nvl(c.vlBase, 0),
                                            XTMPAG_VAR.vAliqINSS.vlTeto)) * lFaixa(lFaixa.LAST).Vlaliqcontribindividual / 100;

                  -- Deduz o que ja foi descontado no agrupamento
                  vvlContribuicao := vvlContribuicao -
                                     NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao,
                                         0) - NVL(c.vlDeduzido, 0);

                END IF;
              end if;

            end if;

            vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                               nvl(c.vlDeduzido, 0),
                                               vvlContribuicao);

            InsereRubricaINSS(c.CdVinculo,
                              vCdRubricaGerada,
                              pFolha.CdFolhaPagamento,
                              vvlContribuicao,
                              1,
                              XTMPAG_VAR.vgRecolhimentoAvulso.VlAliquotaUnica);

          ELSIF XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento IS NOT NULL THEN

            vVlBase := vVlBase +
                       XTMPAG_VAR.vgRecolhimentoAvulso.VlBaseRecolhimento;

            IF vVlBase > XTMPAG_VAR.vAliqINSS.vlTeto THEN

              vVlBase := XTMPAG_VAR.vAliqINSS.vlTeto;

            END IF;

            vAliquotaEfetiva := fAplicaAliquotaProgressiva(lFaixa, vVlBase);

            vvlContribuicao := round(vVlBase * vAliquotaEfetiva / 100, 2);

            if vVlContribuicao > XTMPAG_var.vgValorReferenciaMAXINSS then
              vVlContribuicao := XTMPAG_var.vgValorReferenciaMAXINSS;
            end if;

            vvlContribuicao := vvlContribuicao - nvl(c.vlDeduzido, 0) -
                               NVL(XTMPAG_VAR.vgRecolhimentoAvulso.VlRecolhimento,
                                   0);

            vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                               nvl(c.vlDeduzido, 0),
                                               vvlContribuicao);

            InsereRubricaINSS(c.CdVinculo,
                              vCdRubricaGerada,
                              pFolha.CdFolhaPagamento,
                              vvlContribuicao,
                              1,
                              vAliquotaEfetiva);

          else
            null;
          END IF;

        ELSE

           -- Contribuinte individual
          IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento =
             XTMPAG_TIPO.cnRelResidente THEN

            vAliquotaEfetiva := lFaixa(lFaixa.Last).Vlaliqcontribindividual / 100;

            if vAliquotaEfetiva is null then
                XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                    XTMPAG_VAR.vCdHistParamCalc,
                                    XTMPAG_VAR.vCdPessoa,
                                    'Erro ao processar valor INSS: Alíquota não encontrada para a relação de trabalho residente.',
                                    XTMPAG_VAR.vgCdVinculo);
                return;
            end if;

            vvlContribuicao := vVlBase * vAliquotaEfetiva;

            vvlContribuicao := vvlContribuicao -
                               NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao, 0) -
                               nvl(c.vlDeduzido, 0);

            if vVlContribuicao > lFaixa(lFaixa.Last).VLTETOCONTRIBINDIVIDUAL then

              vVlContribuicao := lFaixa(lFaixa.Last).VLTETOCONTRIBINDIVIDUAL;

            end if;

          ELSE

            vAliquotaEfetiva := round(XTMPAG_var.vgValorReferenciaVLDCI / lFaixa(lFaixa.LAST).VlFinal,
                                      2);

            vvlContribuicao := vVlBase * vAliquotaEfetiva;

            vvlContribuicao := vvlContribuicao -
                               NVL(lFaixa(lFaixa.LAST).VlParcelaDeducao, 0) -
                               nvl(c.vlDeduzido, 0);

            if vVlContribuicao > XTMPAG_var.vgValorReferenciaVLDCI then

              vVlContribuicao := XTMPAG_var.vgValorReferenciaVLDCI;

            end if;
          END IF;

          BEGIN

                UPDATE epageventovinculo evv
                   SET evv.vlevento         = vvlbaseoutrovinculo, --vvlbasevinculo,
                       evv.vlindice         = valiquotaefetiva,
                       evv.vlpagamento = vvldescoutrovinculo,
                       evv.cdfolhapagamento = pfolha.cdfolhapagamento,
                       evv.dtultalteracao   = SYSDATE
                 WHERE evv.cdeventovinculo = vcdeventovinculo
                   AND evv.cdfolhapagamento IN
                       (SELECT ff.cdfolhapagamento
                          FROM epagfolhapagamento ff
                         WHERE ff.nuanoreferencia = pfolha.nuanoreferencia
                           AND ff.numesreferencia = pfolha.numesreferencia
                           AND ff.cdagrupamento = pfolha.cdagrupamento
                           AND ff.cdtipofolhapagamento =
                               pfolha.cdtipofolhapagamento);

          EXCEPTION
            WHEN no_data_found THEN
              NULL;

            WHEN OTHERS THEN
              NULL;
          END;

          vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                             nvl(c.vlDeduzido, 0),
                                             vvlContribuicao);

          InsereRubricaINSS(c.CdVinculo,
                            vCdRubricaGerada,
                            pFolha.CdFolhaPagamento,
                            vvlContribuicao,
                            1,
                            vAliquotaEfetiva * 100);

        END IF;
      END LOOP;

    END;

    FUNCTION FCalculaINSS(pCdVinculo IN INTEGER)

     RETURN BOOLEAN IS

      vCont INTEGER;

      vCdPessoa INTEGER := XTMPAG_VAR.vgVinculo.CdPessoa;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF --pFolha.CdAgrupamento in (1,2)
       XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario =
       XTMPAG_TIPO.cnRegPrevGeral AND vControlaMsg = FALSE

       THEN
        --
        -- Solicitacao de Sustentacao #67586
        -- 8385/2016 - FOLHA-PARA OS SERVIDORES VINCULADOS AO REGIME GERAL DE PREVIDENCIA SOCIAL (RGPS),
        -- ISENTAR DA CONTRIBUICAO AO RGPS, CASO ELE TENHA RECOLHIDO O TETO
        --
        -- Solicitacao de Sustentacao #70102
        -- CIASC - Sincronizacao de folha de pagamentos para efeitos de comprovacao de contribuicao
        -- INSS de Conselheiros
        --

        -- 0748/2017 - ISENCAO PREVIDENCIARIA INSS EM FOLHA DO SERVIDOR
        -- VERIFICAR A DATA DE PROCESSAMENTO DA FOLHA EM TODOS OS AGRUPAMENTOS DO SIGRH,
        --PRIORIZAR O DESCONTO DO RGPS (INSS) NO AGRUPAMENTO QUE PROCESSAR PRIMEIRO, CONCEDENDO A ISENCAO OU COMPLEMENTACAO DO DESCONTO NO AGRUPAMENTO QUE PROCESSAR POSTERIORMENTE.
        -- CONSIDERAR SEMPRE A MESMA COMPETENCIA DE PROCESSAMENTO.
        --

        BEGIN

          -- PARA FOLHA DE 13 SALARIO
          IF XTMPAG_var.vgfolha.cdtipofolha = XTMPAG_tipo.cntpfolha13 THEN

            WITH VIN AS
             (SELECT v.cdvinculo
                FROM ECADVINCULO V
               WHERE V.CDPESSOA = VCDPESSOA
                 AND V.CDREGIMEPREVIDENCIARIO = XTMPAG_TIPO.CNREGPREVGERAL),
            FOL AS
             (SELECT f.cdfolhapagamento, eo.sgorgao
                FROM EPAGFOLHAPAGAMENTO F
               INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
                  ON F.CDTIPOFOLHAPAGAMENTO = TF.CDTIPOFOLHAPAGAMENTO
               INNER JOIN EPAGTIPOFOLHA TP
                  ON TP.CDTIPOFOLHA = TF.CDTIPOFOLHA
                 AND TF.CDTIPOFOLHA IN (XTMPAG_TIPO.CNTPFOLHA13)
               INNER JOIN ECADHISTORGAO EO
                  ON EO.CDORGAO = F.CDORGAO
                 AND EO.DTFIMVIGENCIA IS NULL
                 AND EO.CDAGRUPAMENTO = F.CDAGRUPAMENTO
               WHERE F.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO
                    /*AND F.FLCALCULODEFINITIVO = XTMPAG_VAR.VGFOLHA.FLCALCULODEFINITIVO*/
                 AND F.CDTIPOCALCULO IN
                     (XTMPAG_TIPO.CNTPCALCULONORMAL,
                      XTMPAG_TIPO.CNTPCALCULOSUPL)
                 AND F.NUMESREFERENCIA IN (11, 12) -- MESES DE NOV E DEZ
                 AND F.NUANOREFERENCIA =
                     to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYY'))),
            RUB AS
             (SELECT r.cdrubricaagrupamento, r.cdagrupamento
                FROM VPAGRUBRICAAGRUPAMENTO R
               WHERE R.NURUBRICA IN (513)
                 AND R.CDTIPORUBRICA = 5
                 AND R.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO)
            SELECT EV.VLPAGAMENTO, FL.SGORGAO, R.CDAGRUPAMENTO
              INTO VVLINSSANT, VSGORGAO, VCDAGRUPDUPLOVINC
              FROM EPAGHISTORICORUBRICAVINCULO EV
             INNER JOIN VIN V
                ON V.CDVINCULO = EV.CDVINCULO
             INNER JOIN FOL FL
                ON FL.CDFOLHAPAGAMENTO = EV.CDFOLHAPAGAMENTO
             INNER JOIN RUB R
                ON R.CDRUBRICAAGRUPAMENTO = EV.CDRUBRICAAGRUPAMENTO;

            WITH VINB AS
             (SELECT v.cdvinculo
                FROM ECADVINCULO V
               WHERE V.CDPESSOA = VCDPESSOA
                 AND V.CDREGIMEPREVIDENCIARIO = XTMPAG_TIPO.CNREGPREVGERAL),
            FOL AS
             (SELECT f.cdfolhapagamento
                FROM EPAGFOLHAPAGAMENTO F
               INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
                  ON F.CDTIPOFOLHAPAGAMENTO = TF.CDTIPOFOLHAPAGAMENTO
               INNER JOIN EPAGTIPOFOLHA TP
                  ON TP.CDTIPOFOLHA = TF.CDTIPOFOLHA
                 AND TF.CDTIPOFOLHA IN (XTMPAG_TIPO.CNTPFOLHA13)
               INNER JOIN ECADHISTORGAO EO
                  ON EO.CDORGAO = F.CDORGAO
                 AND EO.DTFIMVIGENCIA IS NULL
                 AND EO.CDAGRUPAMENTO = F.CDAGRUPAMENTO
               WHERE F.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO
                    /* AND F.FLCALCULODEFINITIVO = XTMPAG_VAR.VGFOLHA.FLCALCULODEFINITIVO*/
                 AND F.CDTIPOCALCULO IN
                     (XTMPAG_TIPO.CNTPCALCULONORMAL,
                      XTMPAG_TIPO.CNTPCALCULOSUPL)
                 AND F.NUMESREFERENCIA IN (11, 12) --TO_CHAR(PFOLHA.DTCALCULO, 'MM')
                 AND F.NUANOREFERENCIA =
                     to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYY'))),
            BASE AS
             (SELECT r.cdrubricaagrupamento -- SALARIO CONTR.INSS
                FROM VPAGRUBRICAAGRUPAMENTO R
               WHERE R.NURUBRICA = 1005
                 AND R.CDTIPORUBRICA = 9
                 AND R.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO)
            SELECT EV.VLPAGAMENTO
              INTO VVLBASEANT
              FROM EPAGHISTORICORUBRICAVINCULO EV
             INNER JOIN VINB V
                ON V.CDVINCULO = EV.CDVINCULO
             INNER JOIN FOL F
                ON F.CDFOLHAPAGAMENTO = EV.CDFOLHAPAGAMENTO
             INNER JOIN BASE B
                ON B.CDRUBRICAAGRUPAMENTO = EV.CDRUBRICAAGRUPAMENTO;

            SELECT MAX(AA.VLFINAL)
              INTO VVLTETO
              FROM ETRBHISTALIQUOTAINSS AH
             INNER JOIN ETRBALIQUOTAFAIXAINSS AA
                ON AA.CDHISTALIQUOTAINSS = AH.CDHISTALIQUOTAINSS
             WHERE AA.VLALIQUOTA = 11
               AND to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYY')) BETWEEN
                   AH.NUANOINICIO AND
                   NVL(AH.NUANOFINAL,
                       to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYY')))
               AND to_number(TO_CHAR(PFOLHA.DTCALCULO, 'MM')) BETWEEN
                   AH.NUMESINICIO AND
                   NVL(AH.NUMESFINAL,
                       to_number(TO_CHAR(PFOLHA.DTCALCULO, 'MM')));

          ELSE
            -- FOLHA NORMAL

            ---------------------------------------------------------------------------------------------
            --                                                           ~                               --
            --     xxx     xxxxxxx     xxxx      xx  x       xxxxx      xxx        xxxxx                 --
            --    x   x      xxx      x         x x  x      xx         x   x      xx   xx                --
            --    xxxxxx      x       xxxx      x  x x      x          xxxxxx     x     x                --
            --    x   xx      x       x         x  x x      xx         x   xx     xx   xx                --
            --    x   xx      x       xxxxx     x   xx       xxxxx     x   xx      xxxxx                 --
            --                                                 /                                         --
            --                                                                                           --
            --  A QUERY ABAIXO FOI AJUSTADA PELO DBA PARA TER MELHOR PERFORMANCE                         --
            --     QUALQUER ALTERAÇÃO PRECISA SER PASSADA PRA ELE AJUSTAR NOVAMENTE                      --
            with VIN as --
             (select v.cdvinculo --
                from ECADVINCULO V --
               where V.CDPESSOA = VCDPESSOA --
                 and V.CDREGIMEPREVIDENCIARIO = XTMPAG_TIPO.CNREGPREVGERAL), --
            FOL as --
             (select f.cdfolhapagamento, eo.sgorgao --
                from EPAGFOLHAPAGAMENTO F --
               inner join EPAGTIPOFOLHAPAGAMENTO TF
                  on F.CDTIPOFOLHAPAGAMENTO = TF.CDTIPOFOLHAPAGAMENTO --
               inner join EPAGTIPOFOLHA TP
                  on TP.CDTIPOFOLHA = TF.CDTIPOFOLHA --
                 and TF.CDTIPOFOLHA in (XTMPAG_TIPO.CNTPFOLHANORMAL, XTMPAG_TIPO.cnTpFolhaConvenio) --
               inner join ECADHISTORGAO EO
                  on EO.CDORGAO = F.CDORGAO --
                 and EO.DTFIMVIGENCIA is null --
                 and EO.CDAGRUPAMENTO = F.CDAGRUPAMENTO --
               where F.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO --
                    /*AND F.FLCALCULODEFINITIVO = XTMPAG_VAR.VGFOLHA.FLCALCULODEFINITIVO*/ --
                 and F.CDTIPOCALCULO in
                     (XTMPAG_TIPO.CNTPCALCULONORMAL,
                      XTMPAG_TIPO.CNTPCALCULOSUPL) --
                 and F.NUANOMESREFERENCIA =
                     to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYYMM'))), --
            RUB as --
             (select r.cdrubricaagrupamento, r.cdagrupamento --
                from VPAGRUBRICAAGRUPAMENTO R --
               where R.NURUBRICA in (512)
                 and R.CDTIPORUBRICA = 5 --
                 and R.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO) --
            select EV.VLPAGAMENTO, F.SGORGAO, R.CDAGRUPAMENTO --
              into VVLINSSANT, VSGORGAO, VCDAGRUPDUPLOVINC --
              from EPAGHISTORICORUBRICAVINCULO EV --
             inner join VIN V
                on V.CDVINCULO = EV.CDVINCULO --
             inner join FOL F
                on F.CDFOLHAPAGAMENTO = EV.CDFOLHAPAGAMENTO --
             inner join RUB R
                on R.CDRUBRICAAGRUPAMENTO = EV.CDRUBRICAAGRUPAMENTO; --
            ----------------------------------------------------------------------------------------------
            -------------------------------------------------------------------------------------------

            WITH VINB AS
             (SELECT v.cdvinculo
                FROM ECADVINCULO V
               WHERE V.CDPESSOA = VCDPESSOA
                 AND V.CDREGIMEPREVIDENCIARIO = XTMPAG_TIPO.CNREGPREVGERAL),
            FOL AS
             (SELECT f.cdfolhapagamento
                FROM EPAGFOLHAPAGAMENTO F
               INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
                  ON F.CDTIPOFOLHAPAGAMENTO = TF.CDTIPOFOLHAPAGAMENTO
               INNER JOIN EPAGTIPOFOLHA TP
                  ON TP.CDTIPOFOLHA = TF.CDTIPOFOLHA
                 AND TF.CDTIPOFOLHA IN (XTMPAG_TIPO.CNTPFOLHANORMAL, XTMPAG_TIPO.cnTpFolhaConvenio)
               INNER JOIN ECADHISTORGAO EO
                  ON EO.CDORGAO = F.CDORGAO
                 AND EO.DTFIMVIGENCIA IS NULL
                 AND EO.CDAGRUPAMENTO = F.CDAGRUPAMENTO
               WHERE F.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO
                    /*AND F.FLCALCULODEFINITIVO = XTMPAG_VAR.VGFOLHA.FLCALCULODEFINITIVO*/
                 AND F.CDTIPOCALCULO IN
                     (XTMPAG_TIPO.CNTPCALCULONORMAL,
                      XTMPAG_TIPO.CNTPCALCULOSUPL)
                 AND F.NUANOMESREFERENCIA =
                     to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYYMM'))),
            BASE AS
             (SELECT r.cdrubricaagrupamento -- SALARIO CONTR.INSS
                FROM VPAGRUBRICAAGRUPAMENTO R
               WHERE R.NURUBRICA = 903
                 AND R.CDTIPORUBRICA = 9
                 AND R.CDAGRUPAMENTO <> PFOLHA.CDAGRUPAMENTO
                 AND R.CDAGRUPAMENTO NOT IN
                     (SELECT CDAGRUPAMENTO
                        FROM ECADHISTORGAO
                       WHERE CDTIPOORGAO IN (1, 5)))
            SELECT EV.VLPAGAMENTO
              INTO VVLBASEANT
              FROM EPAGHISTORICORUBRICAVINCULO EV
             INNER JOIN VINB V
                ON V.CDVINCULO = EV.CDVINCULO
             INNER JOIN FOL F
                ON F.CDFOLHAPAGAMENTO = EV.CDFOLHAPAGAMENTO
             INNER JOIN BASE B
                ON B.CDRUBRICAAGRUPAMENTO = EV.CDRUBRICAAGRUPAMENTO;

            SELECT MAX(AA.VLFINAL)
              INTO VVLTETO
              FROM ETRBHISTALIQUOTAINSS AH
             INNER JOIN ETRBALIQUOTAFAIXAINSS AA
                ON AA.CDHISTALIQUOTAINSS = AH.CDHISTALIQUOTAINSS
             WHERE AA.VLALIQUOTA = 11
               AND to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYY')) BETWEEN
                   AH.NUANOINICIO AND
                   NVL(AH.NUANOFINAL,
                       to_number(TO_CHAR(PFOLHA.DTCALCULO, 'YYYY')))
               AND to_number(TO_CHAR(PFOLHA.DTCALCULO, 'MM')) BETWEEN
                   AH.NUMESINICIO AND
                   NVL(AH.NUMESFINAL,
                       to_number(TO_CHAR(PFOLHA.DTCALCULO, 'MM')));

          END IF;

        EXCEPTION
          WHEN NO_DATA_FOUND

           THEN

            vControlaMsg := FALSE;

          WHEN OTHERS THEN
            Null;

        END;

      ELSIF vControlaMsg = TRUE THEN

        RETURN FALSE;

      else
        null;
      END IF;

      IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento =
         XTMPAG_TIPO.cnRelResidente THEN

        RETURN TRUE;

      ELSE

        SELECT COUNT(*)
          INTO vCont
          FROM ECadVinculo V
         WHERE V.CdVinculo = pCdVinculo
           AND (V.CdRegimePrevidenciario = XTMPAG_TIPO.cnRegPrevGeral);

        IF vCont > 0 THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;

      END IF;

    END;

    PROCEDURE PReprocessaBaseINSS(pFolha     IN XTMPAG_TIPO.rFolha,
                                  pCdVinculo IN INTEGER) IS

      vvlBaseINSS NUMBER(13, 2);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF FCalculaINSS(pCdVinculo) THEN
        -- DESCOBRE SE BASE INSS ESTA GERADA NO CONTRACHEQUE
        BEGIN

          IF XTMPAG_var.vgfolha.cdtipofolha in (XTMPAG_tipo.cnTpFolhaAdiant13,XTMPAG_tipo.cntpfolha13) THEN
            SELECT vlpagamento
              INTO vvlBaseINSS
              FROM epaghistoricorubricavinculo hrv
             WHERE HRV.CdFolhaPagamento = pFolha.cdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseINSS13
               AND HRV.NuSufixoRubrica = 1
               AND ROWNUM < 2;
          ELSE
            SELECT vlpagamento
              INTO vvlBaseINSS
              FROM epaghistoricorubricavinculo hrv
             WHERE HRV.CdFolhaPagamento = pFolha.cdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseINSS
               AND HRV.NuSufixoRubrica = 1
               AND ROWNUM < 2;

          END IF;

          -- SE BASE INSS NAO EXISTIR NO CONTRACHEQUE, INSERE LANCAMENTO PARA QUE SEJA REPROCESSADA
        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.cdFolhaPagamento,
                                                  pCdVinculo            => pCdVinculo,
                                                  pCdExpressaoFormCalc  => NULL,
                                                  pCdRubricaAgrupamento => case when XTMPAG_var.vgfolha.cdtipofolha in
                                                                                    (XTMPAG_tipo.cnTpFolhaAdiant13,XTMPAG_tipo.cntpfolha13)
                                                                                then XTMPAG_VAR.vgCdRubBaseINSS13
                                                                                else XTMPAG_VAR.vgCdRubBaseINSS end,
                                                  pNuSufixoRubrica      => 1,
                                                  pVlPagamento          => 0,
                                                  pVlIndice             => NULL,
                                                  pCdTipoOrigemRubrica  => 1);
        END;

      END IF;

      -- REPROCESSA BASE INSS
      XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => pCdRubBaseINSS,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2);

--- marcelo

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubVlINSSPatronalBruto,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2);
                                       


    EXCEPTION
      WHEN OTHERS THEN

        NULL;

    END;   
    
    PROCEDURE PNormalizaINSS (pCdPessoa  IN INTEGER,
                              pCdVinculo IN INTEGER,
                              pFolha     IN XTMPAG_TIPO.rFolha)  IS
                              
       vVlDeduzido NUMBER(13,2);
       vVlDeduzidoNorm NUMBER(13,2);
                                       
    BEGIN
      
     IF pFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoRecalculoMes THEN
      
       SELECT SUM(HRV.vlpagamento)
         INTO vVlDeduzido
         FROM Epaghistoricorubricavinculo HRV
        INNER JOIN Epagfolhapagamento F
           ON F.cdfolhapagamento = HRV.Cdfolhapagamento
        INNER JOIN Ecadvinculo V
           ON V.cdvinculo = HRV.Cdvinculo 
        WHERE  F.Nuanomesreferencia = pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
          AND HRV.Cdrubricaagrupamento = pCdRubAgrupDescINSS 
          AND F.Flcalculodefinitivo = 'S'            
          AND V.cdpessoa = pCdPessoa;
               
      IF vvlDeduzido >= 951.62 THEN
        
      BEGIN
         SELECT SUM(HRV.vlpagamento)
         INTO vVlDeduzidoNorm
         FROM Epaghistoricorubricavinculo HRV
        INNER JOIN Epagfolhapagamento F
           ON F.cdfolhapagamento = HRV.Cdfolhapagamento
        INNER JOIN Ecadvinculo V
           ON V.cdvinculo = HRV.Cdvinculo 
        WHERE  F.Nuanomesreferencia = pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
          AND HRV.Cdrubricaagrupamento = pCdRubAgrupDescINSS 
          AND F.Flcalculodefinitivo = 'S' 
          AND F.Cdtipofolhapagamento = pFolha.CdTipoFolhaPagamento 
          AND F.Cdtipocalculo = 1        
          AND V.CdVinculo = pCdVinculo;
          
          IF NVL(vvlDeduzidoNorm,0) > 0 THEN
            
              UPDATE Epaghistoricorubricavinculo H set vlPagamento = vVlDeduzidoNorm
               WHERE H.Cdfolhapagamento = pFolha.cdFolhaPAgamento AND
                H.cdVinculo = pCdVinculo AND
                H.Cdrubricaagrupamento = pCdRubAgrupDescINSS;
                
          ELSE
            
            DElETE FROM  Epaghistoricorubricavinculo H
          WHERE H.Cdfolhapagamento = pFolha.cdFolhaPAgamento AND
                H.cdVinculo = pCdVinculo AND
                H.Cdrubricaagrupamento = pCdRubAgrupDescINSS;
            
          END IF;      
          
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
            
            DElETE FROM  Epaghistoricorubricavinculo H
          WHERE H.Cdfolhapagamento = pFolha.cdFolhaPAgamento AND
                H.cdVinculo = pCdVinculo AND
                H.Cdrubricaagrupamento = pCdRubAgrupDescINSS;
      END;    
        
                
       END IF;    
        
      END IF; 
      
        
    EXCEPTION
      
      WHEN OTHERS THEN
        
        NULL;        
        
    END;
       
    
    PROCEDURE PProcessaTotalizadoraDuploVinc(pFolha     IN XTMPAG_TIPO.rFolha,
                                             pCdVinculo IN INTEGER) IS

      cd091027 INTEGER := 0;
      cd091028 INTEGER := 0;
      --vVl091027 NUMBER := 0;
      --vVl091028 NUMBER := 0;
      vNuMatricula VARCHAR2(7) := 0;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT r.cdrubricaagrupamento
        INTO cd091027
        FROM vpagrubricaagrupamento r
       WHERE r.nurubrica = 1027
         AND r.cdtiporubrica = 9
         AND r.cdagrupamento = pfolha.cdagrupamento;

      SELECT r.cdrubricaagrupamento
        INTO cd091028
        FROM vpagrubricaagrupamento r
       WHERE r.nurubrica = 1028
         AND r.cdtiporubrica = 9
         AND r.cdagrupamento = pfolha.cdagrupamento;

      SELECT v.numatricula, v.nuseqmatricula
        INTO vnumatricula, XTMPAG_var.vgvinculo.nuseqmatricula
        FROM ecadvinculo v
       WHERE v.cdvinculo = pcdvinculo;

      DELETE epaghistoricorubricavinculo hv
       WHERE hv.cdvinculo = pcdvinculo
         AND hv.cdfolhapagamento = pfolha.cdfolhapagamento
         AND hv.cdrubricaagrupamento = cd091027;

      -- Valor do INSS outros vinculos
      DELETE epaghistoricorubricavinculo hv
       WHERE hv.cdvinculo = pcdvinculo
         AND hv.cdfolhapagamento = pfolha.cdfolhapagamento
         AND hv.cdrubricaagrupamento = cd091028;

      IF (XTMPAG_VAR.vgFolha.CdTipoFolha <> XTMPAG_TIPO.cnTpFolha13) THEN

        --BASE DO INSS VARIOS VINCULOS
        INSERT INTO epaghistoricorubricavinculo
          (cdhistoricorubricavinculo,
           cdfolhapagamento,
           cdrubricaagrupamento,
           cdvinculo,
           nusufixorubrica,
           cdlancamentofinanceiro,
           vlpagamento,
           qtparcelas,
           vlindicerubrica,
           dtultalteracao,
           cdtipoorigemrubrica,
           cdtipoindice)
          SELECT spaghistoricorubricavinculo.nextval AS cdhistoricorubricavinculo,
                 pfolha.cdfolhapagamento AS cdfolhapagamento,
                 cd091027 AS cdrubricaagrupamento,
                 pcdvinculo AS cdvinculo,
                 CASE
                   WHEN (v.numatricula <> vnumatricula AND
                        v.nuseqmatricula =
                        XTMPAG_var.vgvinculo.nuseqmatricula) THEN
                    0
                   ELSE
                    v.nuseqmatricula
                 END AS nusufixorubrica,
                 NULL AS cdlancamentofinanceiro,
                 evv.vlevento AS vlpagamento,
                 1 AS qtparcelas,
                 evv.vlindice AS vlindicerubrica,
                 SYSDATE AS dtultalteracao,
                 10 AS cdtipoorigemrubrica,
                 XTMPAG_var.vgrubrica(cd091027).cdtipoindice AS cdtipoindice
            FROM sigrh.epageventovinculo evv
           INNER JOIN sigrh.ecadvinculo v
              ON v.cdvinculo = evv.cdvinculo
             AND v.flanulado = 'N'
           WHERE/* (v.nuseqmatricula <> XTMPAG_var.vgvinculo.nuseqmatricula OR
                 (v.numatricula <> vnumatricula AND
                 v.nuseqmatricula = XTMPAG_var.vgvinculo.nuseqmatricula))
             AND */ evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
             AND evv.cdtipoeventovinculo = 6
           --  AND evv.cdvinculo <> pcdvinculo
             AND evv.nuanomesreferencia =
                 XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                 XTMPAG_var.vgfolha.numesreferencia
             AND evv.vlevento > 0;

        INSERT INTO epaghistoricorubricavinculo
          (cdhistoricorubricavinculo,
           cdfolhapagamento,
           cdrubricaagrupamento,
           cdvinculo,
           nusufixorubrica,
           cdlancamentofinanceiro,
           vlpagamento,
           qtparcelas,
           vlindicerubrica,
           dtultalteracao,
           cdtipoorigemrubrica,
           cdtipoindice)

          SELECT spaghistoricorubricavinculo.nextval AS cdhistoricorubricavinculo,
                 pfolha.cdfolhapagamento AS cdfolhapagamento,
                 cd091028 AS cdrubricaagrupamento,
                 pcdvinculo AS cdvinculo,
                 CASE
                   WHEN (v.numatricula <> vnumatricula AND
                        v.nuseqmatricula =
                        XTMPAG_var.vgvinculo.nuseqmatricula) THEN
                    0
                   ELSE
                    v.nuseqmatricula
                 END AS nusufixorubrica,
                 NULL AS cdlancamentofinanceiro,
                 evv.vlpagamento AS vlpagamento,
                 1 AS qtparcelas,
                 evv.vlindice AS vlindicerubrica,
                 SYSDATE AS dtultalteracao,
                 10 AS cdtipoorigemrubrica,
                 XTMPAG_var.vgrubrica(cd091028).cdtipoindice AS cdtipoindice
            FROM sigrh.epageventovinculo evv
           INNER JOIN sigrh.ecadvinculo v
              ON v.cdvinculo = evv.cdvinculo
             AND v.flanulado = 'N'
           WHERE /* (v.nuseqmatricula <> XTMPAG_var.vgvinculo.nuseqmatricula OR
                 (v.numatricula <> vnumatricula AND
                 v.nuseqmatricula = XTMPAG_var.vgvinculo.nuseqmatricula))
             AND */ evv.cdchave = XTMPAG_var.vgvinculo.cdpessoa
             AND evv.cdtipoeventovinculo = 6
        --     AND evv.cdvinculo <> pcdvinculo
             AND evv.nuanomesreferencia =
                 XTMPAG_var.vgfolha.nuanoreferencia * 100 +
                 XTMPAG_var.vgfolha.numesreferencia
             AND evv.vlpagamento > 0;



      ELSE

        INSERT INTO epaghistoricorubricavinculo
          (cdhistoricorubricavinculo,
           cdfolhapagamento,
           cdrubricaagrupamento,
           cdvinculo,
           nusufixorubrica,
           cdlancamentofinanceiro,
           vlpagamento,
           qtparcelas,
           vlindicerubrica,
           dtultalteracao,
           cdtipoorigemrubrica,
           cdtipoindice)
          SELECT spaghistoricorubricavinculo.nextval AS cdhistoricorubricavinculo,
                 pfolha.cdfolhapagamento AS cdfolhapagamento,
                 cd091027 AS cdrubricaagrupamento,
                 pcdvinculo AS cdvinculo,
                 CASE
                   WHEN (v.numatricula <> vnumatricula AND
                        v.nuseqmatricula =
                        XTMPAG_var.vgvinculo.nuseqmatricula) THEN
                    0
                   ELSE
                    v.nuseqmatricula
                 END AS nusufixorubrica,
                 NULL AS cdlancamentofinanceiro,
                 RV.VLPAGAMENTO AS vlpagamento,
                 1 AS qtparcelas,
                 RV.Vlindicerubrica AS vlindicerubrica,
                 SYSDATE AS dtultalteracao,
                 10 AS cdtipoorigemrubrica,
                 XTMPAG_var.vgrubrica(cd091027).cdtipoindice AS cdtipoindice
            FROM epaghistoricorubricavinculo rv
           INNER JOIN ecadvinculo v
              ON rv.cdvinculo = v.cdvinculo
             AND v.flanulado = 'N'
           INNER JOIN epagfolhapagamento fp
              ON fp.cdfolhapagamento = rv.cdfolhapagamento
           INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
              ON TF.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
             AND (fp.cdtipocalculo = XTMPAG_var.vgFolha.cdtipocalculo AND
                 (XTMPAG_var.vgFolha.flcalculodefinitivo = 'N' AND
                 ((fp.flcalculodefinitivo = 'N' AND
                 fp.numesreferencia = 12 AND
                 TF.CDTIPOFOLHA = XTMPAG_var.vgFolha.cdTipoFolha) OR
                 fp.flcalculodefinitivo = 'S')) OR
                 (XTMPAG_var.vgFolha.flcalculodefinitivo = 'S' AND
                 fp.flcalculodefinitivo = 'S'))
             AND NOT
                  (XTMPAG_var.vgFolha.numesreferencia = 12 and
                  fp.cdfolhapagamento in
                  (select cdfolhapagamento
                      from epagfolhapagamento fp
                     inner join epagtipofolhapagamento tf
                        on tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
                     where tf.cdtipofolha in (3, 20) -- 13sal e 13 sal ctisp
                       and fp.nuanoreferencia =
                           XTMPAG_var.vgFolha.nuanoreferencia
                       and fp.flcalculodefinitivo = 'S'))
           WHERE rv.cdvinculo <> pcdvinculo
             AND v.cdpessoa = XTMPAG_var.vgvinculo.cdpessoa
             AND rv.cdrubricaagrupamento IN (pCdRubBaseINSS)
             AND FP.NUANOREFERENCIA = XTMPAG_var.vgfolha.nuanoreferencia
             AND rv.vlpagamento > 0;

        INSERT INTO epaghistoricorubricavinculo
          (cdhistoricorubricavinculo,
           cdfolhapagamento,
           cdrubricaagrupamento,
           cdvinculo,
           nusufixorubrica,
           cdlancamentofinanceiro,
           vlpagamento,
           qtparcelas,
           vlindicerubrica,
           dtultalteracao,
           cdtipoorigemrubrica,
           cdtipoindice)
          SELECT spaghistoricorubricavinculo.nextval AS cdhistoricorubricavinculo,
                 pfolha.cdfolhapagamento AS cdfolhapagamento,
                 cd091028 AS cdrubricaagrupamento,
                 pcdvinculo AS cdvinculo,
                 CASE
                   WHEN (v.numatricula <> vnumatricula AND
                        v.nuseqmatricula =
                        XTMPAG_var.vgvinculo.nuseqmatricula) THEN
                    0
                   ELSE
                    v.nuseqmatricula
                 END AS nusufixorubrica,
                 NULL AS cdlancamentofinanceiro,
                 RV.VLPAGAMENTO AS vlpagamento,
                 1 AS qtparcelas,
                 RV.Vlindicerubrica AS vlindicerubrica,
                 SYSDATE AS dtultalteracao,
                 10 AS cdtipoorigemrubrica,
                 XTMPAG_var.vgrubrica(cd091028).cdtipoindice AS cdtipoindice
            FROM epaghistoricorubricavinculo rv
           INNER JOIN ecadvinculo v
              ON rv.cdvinculo = v.cdvinculo
             AND v.flanulado = 'N'
           INNER JOIN epagfolhapagamento fp
              ON fp.cdfolhapagamento = rv.cdfolhapagamento
           INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
              ON TF.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
             AND (fp.cdtipocalculo = XTMPAG_var.vgFolha.cdtipocalculo AND
                 (XTMPAG_var.vgFolha.flcalculodefinitivo = 'N' AND
                 ((fp.flcalculodefinitivo = 'N' AND
                 fp.numesreferencia = 12 AND
                 TF.CDTIPOFOLHA = XTMPAG_var.vgFolha.cdTipoFolha) OR
                 fp.flcalculodefinitivo = 'S')) OR
                 (XTMPAG_var.vgFolha.flcalculodefinitivo = 'S' AND
                 fp.flcalculodefinitivo = 'S'))
             AND NOT
                  (XTMPAG_var.vgFolha.numesreferencia = 12 and
                  fp.cdfolhapagamento in
                  (select cdfolhapagamento
                      from epagfolhapagamento fp
                     inner join epagtipofolhapagamento tf
                        on tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
                     where tf.cdtipofolha in (3, 20) -- 13sal e 13 sal ctisp
                       and fp.nuanoreferencia =
                           XTMPAG_var.vgFolha.nuanoreferencia
                       and fp.flcalculodefinitivo = 'S'))
           WHERE rv.cdvinculo <> pcdvinculo
             AND v.cdpessoa = XTMPAG_var.vgvinculo.cdpessoa
             AND rv.cdrubricaagrupamento IN (pCdRubAgrupDescINSS)
             AND FP.NUANOREFERENCIA = XTMPAG_var.vgfolha.nuanoreferencia
             AND rv.vlpagamento > 0;


      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        XTMPAG_geral.pinserelog(XTMPAG_var.blog,
                                XTMPAG_var.vcdhistparamcalc,
                                XTMPAG_var.vcdpessoa,
                                'XTMPAG_TRIBUTACAO.PProcessaDuploVinculo. Erro ao inserir as totalizadoras 09-1027 ou 09-1028',
                                XTMPAG_var.vgcdvinculo);
    END;

    FUNCTION fpossuiduplovinculoano(pcdpessoa        IN INTEGER,
                                    pnuanoreferencia IN INTEGER,
                                    pcdagrupamento   IN INTEGER)

     RETURN BOOLEAN IS

      vcount INTEGER := 0;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT COUNT(DISTINCT capa.cdvinculo)
        INTO vcount
        FROM epagcapahistrubricavinculo capa
       INNER JOIN epagfolhapagamento p
          ON p.cdfolhapagamento = capa.cdfolhapagamento
         AND p.nuanoreferencia = pnuanoreferencia
         AND p.flcalculodefinitivo = 'S'
         AND p.cdagrupamento = pcdagrupamento
       INNER JOIN ecadvinculo v
          ON v.cdvinculo = capa.cdvinculo
       WHERE v.cdpessoa = pcdpessoa;

      IF nvl(vcount, 0) > 1 THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;

    EXCEPTION
      WHEN no_data_found THEN
        RETURN FALSE;

      WHEN OTHERS THEN
        RETURN FALSE;

    END;

    PROCEDURE PDescontoAuxAlimBaseINSS(pCdFolhapagamento IN integer,
                                       pCdVinculo        IN INTEGER,
                                       pCdRubBaseINSS    IN INTEGER) IS

      vValorRubrica010157 XTMPAG_tipo.rValorPagamento;
      vVlBaseVinculo      NUMBER(13, 2);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vVlBaseVinculo := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pCdFolhapagamento,
                                                          pcdvinculo        => pCdVinculo,
                                                          pcdrubrica        => pCdRubBaseINSS);

      -- TRECHO ABAIXO COMENTADO CONFORME SOLICITACAO
      -- SIG-11783 Base INSS divergente quando erario 08-0157  
      -- CONCLUSAO CLIENTE: Nao deve haver esse abatimento da 01-0157 por 
      --                    tras como vem ocorrendo.
      --                    O resultado da fórmula deve bater com o resultado apresentado.    
      /* -- **** COMENTADO INICIO ****
      IF NVL(XTMPAG_var.vvlSaldoAuxAlimNaoDesc, 0) > 0 THEN

        vValorRubrica010157 := XTMPAG_GERAL.fretornavalorrubricarv(pCdFolhaPagamento     => XTMPAG_var.vgfolha.CdFolhaPagamento,
                                                                   pCdVinculo            => XTMPAG_var.vgVinculo.CdVinculo,
                                                                   pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                         1,
                                                                                                                         157),
                                                                   pcdrelacaovinculo     => 1);

        --Desconta o valor da rubrica 08-0157 da base do vinculo limitando, se houver, 01-0157
        IF vValorRubrica010157.vlProporcional > 0 AND
           XTMPAG_var.vvlSaldoAuxAlimNaoDesc >=
           vValorRubrica010157.vlProporcional THEN
          --se houver pagamento de aux alimentação, limita o desconto pelo valor
          XTMPAG_var.vvlSaldoAuxAlimNaoDesc := vValorRubrica010157.vlProporcional;
        END IF;

        vVlBaseVinculo := vVlBaseVinculo -
                          XTMPAG_var.vvlSaldoAuxAlimNaoDesc;

        IF vVlBaseVinculo <= 0 THEN
          vVlBaseVinculo := 0;
        END IF;

        UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.Vlpagamento = vVlBaseVinculo
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = pcdFolhaPagamento
           AND HRV.CdRubricaAgrupamento = pCdRubBaseINSS;

      END IF; 
      */ -- **** FIM COMENTADO
      
    END;

    PROCEDURE PAjustaDadosEventoDuploVinc(pCdPessoa           IN INTEGER,
                                          pFolha              IN XTMPAG_TIPO.rFolha,
                                          pCdRubBaseINSS      IN INTEGER,
                                          pCdRubAgrupDescINSS IN INTEGER) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      DELETE FROM epageventovinculo
       WHERE cdeventovinculo IN
             (SELECT ev.cdeventovinculo
                FROM epaghistoricorubricavinculo rv
               INNER JOIN epageventovinculo ev
                  ON ev.cdfolhapagamento = rv.cdfolhapagamento
                 AND ev.cdrubricaagrupamento = rv.cdrubricaagrupamento
                 AND ev.cdvinculo = rv.cdvinculo
               INNER JOIN epagfolhapagamento fp
                  ON fp.cdfolhapagamento = rv.cdfolhapagamento
                 AND fp.flcalculodefinitivo = 'N'
               WHERE ev.cdchave = pCdPessoa
                 AND ev.nuanomesreferencia =
                     pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia);

      FOR valor IN (select cdfolhapagamento,
                           cdvinculo,
                           cdrubricaagrupamento,
                           vlpagamento,
                           vlindicerubrica
                      from (select rv.cdfolhapagamento,
                                   rv.cdvinculo,
                                   rv.cdrubricaagrupamento,
                                   rv.vlpagamento,
                                   rv.vlindicerubrica
                              from epaghistoricorubricavinculo rv
                             inner join epagfolhapagamento fp
                                on fp.cdfolhapagamento = rv.cdfolhapagamento
                               and fp.flcalculodefinitivo = 'S'
                               and fp.nuanomesreferencia =
                                   pFolha.NuAnoReferencia * 100 +
                                   pFolha.NuMesReferencia
                               and fp.cdfolhapagamento <>
                                   pFolha.CdFolhaPagamento
                               and (FP.CDFOLHAVINCSUPL is null OR
                                   FP.CDFOLHAVINCSUPL <>
                                   pFolha.CdFolhaPagamento)
                             inner join ecadvinculo vinc
                                on vinc.cdvinculo = rv.cdvinculo
                             where vinc.cdpessoa = pCdPessoa
                               and rv.cdrubricaagrupamento in
                                   (pCdRubBaseINSS, pCdRubAgrupDescINSS)
                            --group by rv.cdfolhapagamento, rv.cdvinculo
                            ) x
                    /*where not exists
                    (select 1
                             from epageventovinculo ev
                            where ev.cdfolhapagamento = x.cdfolhapagamento
                              and ev.cdvinculo = x.cdvinculo
                              and ev.cdrubricaagrupamento =
                                  x.cdrubricaagrupamento)*/
                    ) LOOP

        begin

          update EPagEventoVinculo evv
             set evv.vlevento = case
                                  when valor.cdrubricaagrupamento =
                                       pCdRubBaseINSS then
                                   valor.vlpagamento
                                  else
                                   evv.vlevento
                                end,
                 evv.vlpagamento = case
                                     when valor.cdrubricaagrupamento =
                                          pCdRubAgrupDescINSS then
                                      valor.vlpagamento
                                     else
                                      evv.vlpagamento
                                   end,
                 evv.vlindice             = valor.vlindicerubrica,
                 evv.cdrubricaagrupamento = pCdRubBaseINSS
           where evv.cdchave = pcdpessoa
             and evv.cdvinculo = valor.cdvinculo
             and evv.nuanomesreferencia =
                 pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
             and evv.cdtipoeventovinculo = 6;

        exception
          when others then

            insert into EPagEventoVinculo evv
              (cdeventovinculo,
               cdvinculo,
               cdtipoeventovinculo,
               nuanomesreferencia,
               vlevento,
               vlindice,
               cdrubricaagrupamento,
               nucpfcadastrador,
               nucpfultimaalteracao,
               dtinclusao,
               dtultalteracao,
               cdchave,
               vlpagamento,
               cdfolhapagamento)
            VALUES
              (Spageventovinculo.NEXTVAL,
               VALOR.CDVINCULO,
               6,
               pFolha.NuAnoReferencia || lpad(pFolha.NuMesReferencia, 2, 0),
               case when valor.cdrubricaagrupamento = pCdRubBaseINSS then
               valor.vlpagamento else 0 end,
               valor.vlindicerubrica,
               pCdRubBaseINSS,
               11111111111,
               11111111111,
               sysdate,
               sysdate,
               pCdPessoa,
               case when valor.cdrubricaagrupamento = pCdRubAgrupDescINSS then
               valor.vlpagamento else 0 end,
               valor.CdFolhaPagamento);
        end;
      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

     if pFolha.CdTipoFolha in (XTMPAG_tipo.cnTpFolhaProdex13, XTMPAG_tipo.cnTpFolhaHonorarios13, XTMPAG_tipo.cnTpFolhaHonorarProcuradores13)
       or pFolha.CdTipoFolhaPagamento in (1526, 1505, 1525)
       then
      return;
    end if;

    IF pFolha.CdTipoCalculo = XTMPAG_TIPO.cntpcalculorecalculomes
      --AND XTMPAG_var.vgVinculo.dtadmissao > pFolha.DtCalculoAnt
       AND FDuploVinculoVigente(pCdPessoa    => XTMPAG_var.vgvinculo.cdpessoa,
                                pDtInicioMes => pFolha.DtCalculoAnt + 1) > 1 OR
       FVinculosVigentes(XTMPAG_var.vgvinculo.cdpessoa) > 1 THEN

      PAjustaDadosEventoDUploVinc(XTMPAG_var.vgvinculo.cdpessoa,
                                  pFolha,
                                  pCdRubBaseINSS,
                                  pCdRubAgrupDescINSS);

    END IF;

    XTMPAG_GERAL.PLogProcIni('4-4-1-2-1.Processa Trib INSS');

    vCdEventoVinculo := 0;

    IF NOT
        XTMPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pCdRubAgrupDescINSS,
                                             pNuSufixoRubrica      => 1) THEN

      PReprocessaBaseINSS(pFolha => pFolha, pCdVinculo => pCdVinculo);

      -- Desconta do valor da base o saldo de aux alimentação (08-0157)
      PDescontoAuxAlimBaseINSS(pFolha.CdFolhaPagamento,
                               pCdVinculo,
                               pCdRubBaseINSS);

      /*------------------------------------------------------------------------------------------------*/
      -- Atualiza as bases de patronais de INSS (CLT e Estatutario) pois as ferias
      -- incidem sobre estas bases
      /*------------------------------------------------------------------------------------------------*/

      IF XTMPAG_VAR.vgCdRubricaBaseINSSPat IS NOT NULL
        -- EPAGRI - Excecao
         AND NOT (XTMPAG_VAR.vgFolha.CdOrgao = 27 AND
          XTMPAG_VAR.bVinculoComCCO = FALSE)

       THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubricaBaseINSSPat,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseINSSCLT IS NOT NULL AND
         NOT (XTMPAG_VAR.vgFolha.CdOrgao = 27 AND
          XTMPAG_VAR.bVinculoComCCO = TRUE)
      -- EPAGRI somente para efetivos

       THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseINSSCLT,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

      END IF;

      -- 09-1666
      IF XTMPAG_VAR.vgFolha.cdorgao = 563 THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                                                                    pcdtiporubrica => 9,
                                                                                                    pNuRubrica     => 1666),
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                                                          pcdtiporubrica => 9,
                                                                                          pNuRubrica     => 1666),
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseProv13PatINSS IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseProv13PatINSS,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseProv13PatINSSCLT IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

      END IF;

      IF (pFolha.CdTipoFolha <> XTMPAG_TIPO.cnTpFolhaFerias) OR
         (pFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaFerias AND
         XTMPAG_VAR.vgParamPagamento.FlGeraINSSFolhaFerias =
         XTMPAG_TIPO.cnS) THEN

        IF FCalculaINSS(pCdVinculo) THEN

          PRegistroRecolhimentoPrev(pCdTipoFolha     => pFolha.CdTipoFolha,
                                    pCdPessoa        => pCdPessoa,
                                    pCdVinculo       => pCdVinculo,
                                    pNuAnoReferencia => pFolha.NuAnoReferencia,
                                    pNuMesReferencia => pFolha.NuMesReferencia);

          -- Exclui bases de IPESC

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseIPESC,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseIPESC13,
                                      pFlExcluiAmbos    => 'S');

          -- Caso possua rubricas que devem ser descontadas da base do INSS, soma o valor
          -- das rubricas e desconta (ver cursor)

          vvlDescRubIsentaINSS := 0;

          IF bDescRubIsentaINSS THEN

            vvlDescRubIsentaINSS := FRetornaValorRubIsentas(pCdVinculo      => pCdVinculo,
                                                            pFolha          => pFolha,
                                                            pCdTipoDesconto => 1);
          END IF;

          -- Verifica se possui outro vinculo com INSS no mesmo agrupamento
          -- Inserir registro na tabela epageventovinculo para controle do valor da base de calculo

          bPossuiOutroVinculo               := FALSE;
          XTMPAG_var.bPossuiDuploVinculoAno := FALSE;

          if FDuploVinculoVigente(pCdPessoa    => XTMPAG_var.vgvinculo.cdpessoa,
                                  pDtInicioMes => pFolha.DtCalculoAnt + 1) > 1 or
             FVinculosVigentes(XTMPAG_var.vgvinculo.cdpessoa) > 1 then

            vCdEventoVinculo    := 0;
            bPossuiOutroVinculo := true;
            begin
              select evv.cdeventovinculo
                into vCdEventoVinculo
                from epageventovinculo evv
               where evv.cdvinculo = pCdVinculo
                 and evv.nuanomesreferencia =
                     pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
                 and evv.cdtipoeventovinculo = 6
                 and evv.cdrubricaagrupamento = XTMPAG_VAR.vgCdRubBaseINSS
                 and rownum = 1;
            exception
              when no_data_found then
                insert into EPagEventoVinculo evv
                  (cdeventovinculo,
                   cdvinculo,
                   cdtipoeventovinculo,
                   nuanomesreferencia,
                   vlevento,
                   vlindice,
                   cdrubricaagrupamento,
                   nucpfcadastrador,
                   nucpfultimaalteracao,
                   dtinclusao,
                   dtultalteracao,
                   cdchave,
                   vlpagamento,
                   cdfolhapagamento)
                VALUES
                  (Spageventovinculo.NEXTVAL,
                   pCdVinculo,
                   6,
                   pFolha.NuAnoReferencia ||
                   lpad(pFolha.NuMesReferencia, 2, 0),
                   0,
                   0,
                   XTMPAG_VAR.vgCdRubBaseINSS,
                   11111111111,
                   11111111111,
                   sysdate,
                   sysdate,
                   XTMPAG_var.vgvinculo.cdpessoa,
                   0,
                   pFolha.CdFolhaPagamento);

                select evv.cdeventovinculo
                  into vCdEventoVinculo
                  from epageventovinculo evv
                 where evv.cdvinculo = pCdVinculo
                   and evv.nuanomesreferencia = pFolha.NuAnoReferencia * 100 +
                       pFolha.NuMesReferencia
                   and evv.cdtipoeventovinculo = 6
                   and evv.cdrubricaagrupamento =
                       XTMPAG_VAR.vgCdRubBaseINSS;


            end;
            -- Atualizar outros vinculos
            if pFolha.CdTipoCalculo = XTMPAG_TIPO.cntpcalculorecalculomes then

              for pes in (with vin as
                             (select *
                               from ecadvinculo v
                              where v.cdpessoa =
                                    XTMPAG_var.vgvinculo.cdpessoa
                                and v.cdvinculo <> pCdVinculo)
                            select capa.cdvinculo, capa.cdfolhapagamento
                              from epagcapahistrubricavinculo capa
                             inner join vin vv
                                on vv.cdvinculo = capa.cdvinculo
                             where capa.cdfolhapagamento = pFolha.CdFolhaPagamento)
                                  -- pFolha.CdFolhaPagamentoNormal)

               loop

                vVlPagoOV := XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamentoNormal,
                                                               pes.cdvinculo,
                                                               pCdRubAgrupDescINSS);

                vVlIndiceOV := XTMPAG_geral.fretornaindicerubrica(pFolha.CdFolhaPagamentoNormal,
                                                                  pes.cdvinculo,
                                                                  pCdRubAgrupDescINSS);

                vVlBaseOV := XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamentoNormal,
                                                               pes.cdvinculo,
                                                               XTMPAG_VAR.vgCdRubBaseINSS);

                begin

                  select 1
                    into vNumVinc
                    from epageventovinculo evv
                   where evv.cdvinculo = pes.cdvinculo
                     and evv.nuanomesreferencia = pFolha.NuAnoReferencia * 100 +
                         pFolha.NuMesReferencia
                     and evv.cdtipoeventovinculo = 6
                     and evv.cdrubricaagrupamento =
                         XTMPAG_VAR.vgCdRubBaseINSS;

                  update epageventovinculo evv
                     set evv.vlevento    = vVlBaseOV,
                         evv.vlindice    = vVlIndiceOV,
                         evv.vlpagamento = vVlPagoOV
                   where evv.cdvinculo = pes.cdvinculo
                     and evv.nuanomesreferencia = pFolha.NuAnoReferencia * 100 +
                         pFolha.NuMesReferencia
                     and evv.cdtipoeventovinculo = 6
                     and evv.cdrubricaagrupamento =
                         XTMPAG_VAR.vgCdRubBaseINSS;

                exception
                  when no_data_found then
                    insert into EPagEventoVinculo evv
                      (cdeventovinculo,
                       cdvinculo,
                       cdtipoeventovinculo,
                       nuanomesreferencia,
                       vlevento,
                       vlindice,
                       cdrubricaagrupamento,
                       nucpfcadastrador,
                       nucpfultimaalteracao,
                       dtinclusao,
                       dtultalteracao,
                       cdchave,
                       vlpagamento,
                       cdfolhapagamento)
                    VALUES
                      (Spageventovinculo.NEXTVAL,
                       pes.cdvinculo,
                       6,
                       pFolha.NuAnoReferencia ||
                       lpad(pFolha.NuMesReferencia, 2, 0),
                       vVlBaseOV,
                       vVlIndiceOV,
                       XTMPAG_VAR.vgCdRubBaseINSS,
                       11111111111,
                       11111111111,
                       sysdate,
                       sysdate,
                       XTMPAG_var.vgvinculo.cdpessoa,
                       vVlPagoOV,
                       pes.cdfolhapagamento);

                end;

              end loop;

            end if;

            -- Atualizar codigo folha de pagamento, corrigir registros com folhas excluidas
            update epageventovinculo
               set cdfolhapagamento = pFolha.CdFolhaPagamento
             where cdeventovinculo = vCdEventoVinculo;

          end if;

          -- Parametro para que!
          IF pCdRubBaseINSS = XTMPAG_VAR.vgCdRubBaseINSS13
           then
             -- NAO CALCULAR EM PROCESSAMENTO DUPLO VINCULO
             if XTMPAG_var.bProcessandoDuploVinculo then
                return;
             end if;

            pAplicaAliquotaINSS13Rescisao(XTMPAG_VAR.vAliqINSS.lFaixa);

          -- Nao gerar INSS folha adiantamento 13°
          ELSIF XTMPAG_var.vgFolha.CdTipoFolha <> XTMPAG_tipo.cnTpFolhaAdiant13 then

            if XTMPAG_var.vAliqINSS.lFaixa(1).FlAliquotaProgressiva = 'S' then
              -- SEA - 14787/2020 - INSS COM MULTIPLOS VINCULOS
              if not (XTMPAG_var.vMotAfast.inTipoAfastamento = 'D' and
                  XTMPAG_var.vMotAfast.InAfastado = 'M' and
                  pCdRubBaseINSS = XTMPAG_VAR.vgCdRubBaseINSS13) then

                pAplicaAliquotaProgressiva(XTMPAG_VAR.vAliqINSS.lFaixa);

              end if;

            ELSIF pCdRubBaseINSS = XTMPAG_VAR.vgCdRubBaseINSS13 AND
                  fpossuiduplovinculoano(pCdPessoa,
                                         pFolha.NuAnoReferencia,
                                         pFolha.CdAgrupamento) THEN

              XTMPAG_var.bPossuiDuploVinculoAno := TRUE;

              XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                               pCdVinculo       => pCdVinculo,
                                               pCdRubrica       => XTMPAG_VAR.vgCdRubBaseINSS13,
                                               pTpProcessamento => 2,
                                               pTpLocal         => 2);

              IF XTMPAG_var.vAliqINSS.lFaixa(1).FlAliquotaProgressiva = 'S' THEN
                pAplicaAliquotaProgressiva(XTMPAG_VAR.vAliqINSS.lFaixa);
              ELSE

                pAplicaAliquota(XTMPAG_VAR.vAliqINSS.lFaixa);
              END IF;
            else

              pAplicaAliquota(XTMPAG_VAR.vAliqINSS.lFaixa);

            end if;
          END IF;

          -- COHAB - INSS de ferias ficticio
          IF pFolha.CdAgrupamento = 3 AND
             XTMPAG_var.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaFerias AND
             XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                               pcdvinculo        => XTMPAG_VAR.vgVinculo.CdVinculo,
                                               pcdrubrica        => XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescInss) > 0 THEN

            UPDATE epaghistoricorubricavinculo hrv
               SET hrv.cdrubricaagrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           5,
                                                                           216)
             WHERE hrv.cdrubricaagrupamento =
                   XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescInss
               AND hrv.cdvinculo = XTMPAG_VAR.vgVinculo.CdVinculo
               AND hrv.cdfolhapagamento =
                   XTMPAG_var.vgFolha.CdFolhaPagamento;

          END IF;

        END IF;

        IF (XTMPAG_VAR.vgVinculo.CdRegimeTrabalho <>
           XTMPAG_TIPO.cnRegTrabCLT) THEN

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSSCLT,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13PatINSS,
                                      pFlExcluiAmbos    => 'S');

        ELSIF (XTMPAG_VAR.vgVinculo.CdRegimeTrabalho =
              XTMPAG_TIPO.cnRegTrabCLT) THEN

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubricaBaseINSSPat,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                      pFlExcluiAmbos    => 'S');

        else
          null;
        END IF;

        IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario IN (3, 4) OR
           pFolha.CdTipoFolha IN
           (XTMPAG_TIPO.cnTpFolhaResidente,
            XTMPAG_TIPO.cnTpFolhaResidente13) THEN
          -- SEM CONTRIBUICAO OU REGIME PROPRIO DE OUTROS ESTADOS

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseFGTS,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseFGTS13,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubVlFGTS,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubVlFGTS13,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSSCLT,
                                      pFlExcluiAmbos    => 'S');

          XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13PatINSS,
                                      pFlExcluiAmbos    => 'S');

          -- NAO DEVE GERAR 09-1005 PARA APOSENTADO NA FOLHA DE 13 SALARIO
          -- #78490
          IF XTMPAG_VAR.vgFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolha13 AND
             XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria =
             XTMPAG_TIPO.cnSitPrevAposentado AND
             XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = 3 -- SEM CONTRIBUICAO PREVIDENCIARIA
           THEN

            XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSS13,
                                        pFlExcluiAmbos    => 'S');

          END IF;

          IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = 4 THEN

            XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => XTMPAG_VAR.vgCdRubricaBaseINSSPat,
                                        pFlExcluiAmbos    => 'S');

            XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSS,
                                        pFlExcluiAmbos    => 'S');

            XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSS13,
                                        pFlExcluiAmbos    => 'S');

          END IF;

        END IF;

      END IF;

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_VAR.vgFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => 49205,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2);
                                       
     
    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    
    PNormalizaINSS (pCdPessoa        => XTMPAG_var.vgvinculo.cdpessoa,
                    pFolha           => XTMPAG_VAR.vgFolha,
                    pCdVinculo       => pCdVinculo);                                  

      -- Verifica se possui outro vinculo com INSS no mesmo agrupamento
      IF XTMPAG_geral.FVinculosVigentes(pCdPessoa    => XTMPAG_var.vgvinculo.cdpessoa,
                                        pDtInicioMes => pFolha.DtInicioMes) > 1 or
         FVinculosVigentes(XTMPAG_var.vgvinculo.cdpessoa) > 1 THEN

        -- Insere dados nas totalizadorass
        PProcessaTotalizadoraDuploVinc(XTMPAG_VAR.vgFolha, pCdVinculo);
      END IF;

    END IF;

    IF pFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolha13 THEN
      vCdRubAgr05_0512 := XTMPAG_geral.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                       pcdtiporubrica => 5,
                                                       pNuRubrica     => 512);

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => vCdRubAgr05_0512,
                                  pFlExcluiAmbos    => 'S');
    END IF;

    XTMPAG_GERAL.PLogProcFim('4-4-1-2-1.Processa Trib INSS');

  END;

  /*-----------------------------------------------------------------------------------------/
    Procedure  : PCalculaIRRF

      Objetivo : Realizar o calculo de contribuicao do IRRF

  /-----------------------------------------------------------------------------------------*/

  PROCEDURE PCalculaIRRF(pTpTributacao            IN INTEGER,
                         pFolha                   IN XTMPAG_TIPO.rFolha,
                         pCdPessoa                IN INTEGER,
                         pCdVinculo               IN INTEGER,
                         pCdRubAgrupDescIRRF      IN INTEGER,
                         pCdRubBaseIRRF           IN INTEGER,
                         pCdRubAgrupDifDesc       IN INTEGER,
                         pCdRubAgrupDevDesc       IN INTEGER,
                         pCdRubBaseDeducaoInativo IN INTEGER,
                         pCdTipoTributacaoIRRF    IN INTEGER,
                         pDtInicioMes             IN DATE,
                         pDtFimMes                IN DATE,
                         pVlINSS                  IN NUMBER,
                         pVlIPESC                 IN NUMBER,
                         pVlDeducaoInativo        IN NUMBER DEFAULT 0,
                         pbPrima                  IN BOOLEAN DEFAULT FALSE,
                         pIndProcRetro            IN INTEGER DEFAULT NULL) IS

    i  INTEGER;
    c  INTEGER;
    i1 INTEGER;
    --vVlDeducaoDependente    NUMBER(13,2);
    vVlLiquido          NUMBER(13, 2);
    VVlLiquidoAux       NUMBER(13, 2);
    vvlDescSimp         NUMBER(13, 2);
    vvlrubDescSimp      NUMBER(13, 2);
    vVlIndiceRubrica    NUMBER(13, 2);
    vVlBaseOutros       NUMBER(13, 2);
    vVlDeduzidoOutros   NUMBER(13, 2);

    vCdRubricaGerada INTEGER;
    --vCdRubrica              INTEGER;
    vVlDescRubIsentaIRRF NUMBER(13, 2);
    vVlDescRubDepJuizo   NUMBER(13, 2);
    --vtDepositoEmJuizo       XTMPAG_TIPO.tLancComplementar;
    vVlOutrosRRA          NUMBER(13, 2);
    vVlIprevRRA           NUMBER(13, 2);
    vVlNM                 NUMBER(4, 1);
    vVlNmReal             NUMBER(13, 3);
    vVlNmRealDec          NUMBER(13, 3);
    vTpMes                CHAR(1);
    vVlIsentoRetroIRRF    NUMBER(13, 2);
    vVlIsentoRetroIRRFRRA NUMBER(13, 2);
    vVlLiquido9052        NUMBER(13, 2);
    vCdRubBaseIrrfPensao  INTEGER := 0;
    vCdBaseCalculo        INTEGER;
    vVlBase9052           XTMPAG_tipo.rValorPagamento;
    vDeFormula            VARCHAR2(200);
    vRetorno              NUMBER;
    vVlBloqueioNormal     NUMBER(13, 2);
    vVlBloqueio13         NUMBER(13, 2);
    vVlRub50216           NUMBER(13, 2) := 0;
    vvlLimiteDescIR       NUMBER(13, 2) := 0;
    vCdProcPagRetro       INTEGER;

    /* 
    23654/2025 - GEREF - TRIBUTACAO IRRF SERVIDOR RESIDENTE NO EXTERIOR
    A variável global XTMPAG_VAR.vAliquotaIRRF 
    será substituida pela variavel local vAliquotaIRRF      
    */
    vAliquotaIRRF         XTMPAG_TIPO.rAliquotaIRRF;

    CURSOR cBaseIsolada IS
      SELECT pCdVinculo AS CdVinculo,
             B.CdPessoa,
             (B.VlBase - vvlDescRubIsentaIRRF) AS VlBase
        FROM (SELECT V.CdPessoa, SUM(RV.vlPagamento) AS vlBase
                FROM EpagHistoricoRubricaVinculo RV
               INNER JOIN ECadVinculo V
                  ON V.CdVinculo = RV.Cdvinculo
               WHERE RV.CdRubricaAgrupamento = pCdRubBaseIRRF
                 AND RV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND V.CdVinculo = pCdVinculo
               GROUP BY V.CdPessoa) B;


    PROCEDURE PAtualizaBaseIRRF(pvlBase IN NUMBER,
                                pVlNm   IN NUMBER DEFAULT NULL) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF vvlDescRubIsentaIRRF > 0 OR vVlOutrosRRA > 0 OR
         vVlIsentoRetroIRRF > 0 OR vVlIsentoRetroIRRFRRA > 0 THEN

        UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.VlPagamento   = GREATEST(pvlBase, 0),
               HRV.VlIndiceNMRRA = NVL(pVlNm, HRV.VlIndiceNMRRA)
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento = pCdRubBaseIRRF;

      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                XTMPAG_VAR.vCdHistParamCalc,
                                XTMPAG_VAR.vCdPessoa,
                                'XTMPAG_TRIBUTACAO.PAtualizaBaseIRRF',
                                XTMPAG_VAR.vgCdVinculo);

    END;

    /*-----------------------------------------------------------------------------------------/
       Objetivo: Retorna o codigo da rubrica a ser gerada em virtude do tipo de calculo e
                 valores de imposto pagos

    /*-----------------------------------------------------------------------------------------*/
    FUNCTION FRetornaRubrica(pCdTipoCalculo IN INTEGER,
                             pvlDeduzido    IN NUMBER,
                             pvlLiquido     IN NUMBER) RETURN INTEGER IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      CASE

        WHEN pvlDeduzido > 0 THEN

          CASE

            WHEN vvlLiquido > 0 THEN

              RETURN pCdRubAgrupDescIRRF; --  gera rubrica do tipo 5

            WHEN vvlLiquido < 0 THEN

              RETURN 0; -- Nao pode haver devolucao de IRRF na folha

            ELSE

              RETURN 0;

          END CASE;

        WHEN pvlDeduzido = 0 THEN

          CASE

            WHEN vvlLiquido > 0 THEN

              RETURN pCdRubAgrupDescIRRF;

            ELSE

              RETURN 0;

          END CASE;

        ELSE

          RETURN 0;

      END CASE;

    END;


    FUNCTION FEhFolha13(pCdTipoFolha INTEGER) RETURN BOOLEAN IS
      vEhFolha13 BOOLEAN := FALSE;
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;
      IF pCdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13,
                          XTMPAG_TIPO.cnTpFolhaCtisp13,
                          XTMPAG_TIPO.cnTpFolhaProdex13,
                          XTMPAG_TIPO.cnTpFolhaHonorarios13,
                          XTMPAG_TIPO.cnTpFolhaHonorarProcuradores13) THEN
        vEhFolha13 := TRUE;
      END IF;
      RETURN vEhFolha13;
    END;

    FUNCTION FRetornaVlDeduzidoOutros (pCdPessoa  IN INTEGER,
                                       pCdVinculo IN INTEGER,
                                       pFolha     IN XTMPAG_TIPO.rFolha) RETURN NUMBER IS
       vVlDeduzido NUMBER(13,2);
                                       
    BEGIN
      
       SELECT SUM(HRV.vlpagamento)
         INTO vVlDeduzido
         FROM Epaghistoricorubricavinculo HRV
        INNER JOIN Epagfolhapagamento F
           ON F.cdfolhapagamento = HRV.Cdfolhapagamento
        INNER JOIN Ecadvinculo V
           ON V.cdvinculo = HRV.Cdvinculo 
        WHERE F.Cdfolhapagamento = pFolha.CdFolhaPagamento
        --  AND F.Nuanomesreferencia = pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
          AND HRV.Cdrubricaagrupamento = pCdRubAgrupDescIRRF             
          AND V.cdpessoa = pCdPessoa            
          AND HRV.cdvinculo <> pCdVinculo;
               
        RETURN NVL(vVlDeduzido,0);  
        
    EXCEPTION
      
      WHEN OTHERS THEN
        
        RETURN 0;        
        
    END;
    
    FUNCTION FRetornaVlBaseOutros (pCdPessoa  IN INTEGER,
                                   pCdVinculo IN INTEGER,
                                   pFolha     IN XTMPAG_TIPO.rFolha) RETURN NUMBER IS
       vVlDeduzido NUMBER(13,2);
                                       
    BEGIN
      
       SELECT SUM(HRV.vlpagamento)
         INTO vVlDeduzido
         FROM Epaghistoricorubricavinculo HRV
        INNER JOIN Epagfolhapagamento F
           ON F.cdfolhapagamento = HRV.Cdfolhapagamento
        INNER JOIN Ecadvinculo V
           ON V.cdvinculo = HRV.Cdvinculo 
        WHERE F.Cdfolhapagamento = pFolha.CdFolhaPagamento
        --  AND F.Nuanomesreferencia = pFolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
          AND HRV.Cdrubricaagrupamento = pCdRubBaseIRRF             
          AND V.cdpessoa = pCdPessoa            
          AND HRV.cdvinculo <> pCdVinculo;
               
        RETURN NVL(vVlDeduzido,0);  
        
    EXCEPTION
      
      WHEN OTHERS THEN
        
        RETURN 0;        
        
    END;
    
                                       
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_GERAL.PLogProcIni('4-4-1-2-3.Processa Trib IRRF');

    --23654/2025 - GEREF - TRIBUTACAO IRRF SERVIDOR RESIDENTE NO EXTERIOR
    --CLAUDEMIR GOMES - 17/09/2025
    IF NOT FVerificaResidenteExterior THEN
   
      if XTMPAG_fb.FMneSomaRubMesOutrosVinculos(XTMPAG_var.vgVinculo.cdpessoa,
                                                XTMPAG_VAR.vgCdRubricaDescDepIRRF,
                                                pfolha) = 0  then
	  
        PInserirDescDependentesIRRF(pFolha     => pFolha,
                                    pCdVinculo => pCdVinculo);
	  
      end if;
	  
      IF XTMPAG_TRIBUTACAO.FAplicaDeducaoInativo(pCdPessoa,
                                                 pFolha.DtInicioMes,
                                                 pFolha.DtFimMes) AND
	  
           NOT FIsentoIRRF(pCdVinculo, pFolha) AND
           NOT FIsentoIRRFVinculoApo(pCdVinculo, pFolha) AND
           to_char(pFolha.DtInicioMes,'YYYYMM') > '202403' AND
           XTMPAG_fb.FMneSomaRubMesOutrosVinculos(XTMPAG_var.vgVinculo.cdpessoa,
                                                  XTMPAG_VAR.vgCdRubBaseDeducaoInativo,
                                                  pfolha) = 0 THEN
	  
          XTMPAG_GERAL.PExcluiRubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                    pcdvinculo        => pCdVinculo,
                                    pcdrubrica        => XTMPAG_VAR.vgCdRubBaseDeducaoInativo,
                                    pflexcluiambos    => 'S');
	  
	  
          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDeducaoInativo,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => pvlDeducaoInativo,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 10);
      end if;
	  
      PAtualizarDeducoesLegaisIRRF(pFolha     => pFolha,
                                   pCdVinculo => pCdVinculo,
                                   pCdRubBase    => pCdRubBaseIRRF,
                                   pTpTributacao => pTpTributacao,
                                   pIndProcRetro => pIndProcRetro);
	  
      
      IF pIndProcRetro IS NOT NULL THEN    
        vCdProcPagRetro := XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo;
      END IF;
	  
      IF bDescRubIsentaDescIRRF THEN
	  
        if XTMPAG_VAR.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13, XTMPAG_TIPO.cnTpFolhaAdiant13) and
           ((XTMPAG_VAR.vgCdRubExigibilidadeSusp13 is not null AND pFolha.CdAgrupamento = 1) OR
            (XTMPAG_VAR.vgCdRubExigibilidadeSusp is not null AND pFolha.CdAgrupamento <> 1))then
	  
          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.Cdrubricaagrupamento = NVL(XTMPAG_VAR.vgCdRubExigibilidadeSusp13, XTMPAG_VAR.vgCdRubExigibilidadeSusp)
           WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseIRRF13;
	  
          RETURN;
	  
        else
          --
          -- Solicitacao de Sustentacao #65575
          -- Solicitacao 8130/2016 - SEA - Servidores com decisao judicial para isencao total de IRRF,
          -- porem sem laudo de molestia grave X Geracao da rubrica 09-0943 - DEDUCAO PARA O IRRF
          -- Para quem tem isencao na rubrica 05-0516 altera a base do IRRF para a base 09-0943
          --
	  
          XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                           pCdVinculo       => pCdVinculo,
                                           pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIRRF,
                                           pTpProcessamento => 2,
                                           pTpLocal         => 2);
	  
          IF XTMPAG_var.vgDeExpressaoBaseIRRF IS NOT NULL AND
             XTMPAG_VAR.vgCdRubExigibilidadeSusp IS NOT NULL THEN
	  
            c := length(XTMPAG_var.vgDeExpressaoBaseIRRF);
	  
            vDeFormula := '';
	  
            i1 := 0;
	  
            for z in 1 .. c loop
	  
              if substr(XTMPAG_var.vgDeExpressaoBaseIRRF, z, 1) = '-' then
                i1 := 1;
              elsif substr(XTMPAG_var.vgDeExpressaoBaseIRRF, z, 1) = '+' then
                i1 := 0;
              else
                null;
              end if;
	  
              if i1 = 0 then
                vDeFormula := vDeFormula ||
                              substr(XTMPAG_var.vgDeExpressaoBaseIRRF, z, 1);
              end if;
	  
            end loop;
	  
            vRetorno := nvl(pkgmath.fcalcular(vDeFormula), 0);
	  
            vVlBloqueioNormal := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                   pCdVinculo,
                                                                   XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                5,
                                                                                                983));
	  
            vVlBloqueio13 := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                               pCdVinculo,
                                                               XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                            5,
                                                                                            984));
	  
            UPDATE EPagHistoricoRubricaVinculo HRV
               SET HRV.Cdrubricaagrupamento = XTMPAG_VAR.vgCdRubExigibilidadeSusp,
                   HRV.Vlpagamento          = vRetorno -
                                              (NVL(vVlBloqueioNormal, 0) +
                                              NVL(vVlBloqueio13, 0))
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseIRRF;
	  
            RETURN;
	  
          END IF;
        END IF;
      END IF;
	  
      IF NOT FIsentoIRRF(pCdVinculo, pFolha) /*OR pTpTributacao = 4*/ THEN
	  
        vCdRubricaGerada := 0;
	  
        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => pCdRubBaseIRRF,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2,
                                         pTpTributacao    => pTpTributacao,
                                         pIndProcRetro    => pIndProcRetro); /*Vinculo*/
                                         
        IF NVL(XTMPAG_geral.fretornavalorrubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                 pCdVinculo,
                                                 pCdRubBaseIRRF), 0) > 0 THEN                                
	  
          ----------------------------------------------------------------------------------
          -- Caso possua rubricas que devem ser descontadas da base do IRRF, soma o valor
          -- das rubricas e desconta (ver cursor)
          ----------------------------------------------------------------------------------
	  
          vvlDescRubIsentaIRRF := 0;
	  
          vVlOutrosRRA := 0;
	  
          vVlIprevRRA := 0;
	  
          vVlDescRubDepJuizo := 0;
	  
          XTMPAG_VAR.vgVlDeducaoDependOutroVinc := 0;
	  
          IF bDescRubIsentaIRRF THEN
	  
            IF pTpTributacao <> 3 THEN
	  
              vvlDescRubIsentaIRRF := FRetornaValorRubIsentas(pCdVinculo      => pCdVinculo,
                                                              pFolha          => pFolha,
                                                              pCdTipoDesconto => 2);
	  
              vvlDescRubDepJuizo := FRetornaValorRubIsentas(pCdVinculo         => pCdVinculo,
                                                            pFolha             => pFolha,
                                                            pCdTipoDesconto    => 2,
                                                            pFlDepositoEmJuizo => 'S');
            ELSE
	  
              vvlDescRubIsentaIRRF := 0;
	  
            END IF;
	  
            IF vvlDescRubIsentaIRRF > 0 AND pbPrima THEN
	  
              XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubExigibilidadeSusp,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => vvlDescRubIsentaIRRF,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 10);
	  
            END IF;
	  
          END IF;
	  
          ----------------------------------------------------------------------------------
          -- 1. Regime de caixa ou 2. Regime de competencia
          ----------------------------------------------------------------------------------
	  
          IF pCdTipoTributacaoIRRF IN (1, 2) THEN
	  
            IF pCdTipoTributacaoIRRF = 1 THEN
              vTpMes := XTMPAG_TIPO.cnTpMesTribCaixa;
            ELSE
              vTpMes := XTMPAG_TIPO.cnTpMesTribAtual;
            END IF;
	  
            --
            -- Solicitacao de Sustentacao #72799
            -- 9375/2016 - FOLHA - - CALCULO DO IRRF DA PENSAO ALIMENTICIA SOMENTE DO 126
            --
            vVlLiquido9052 := XTMPAG_geral.fretornavalorrubrica(pFolha.Cdfolhapagamento,
                                                                pcdvinculo,
                                                                XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                             9,
                                                                                             9052));
	  
            IF vVlLiquido9052 > 0 THEN
	  
              vCdRubBaseIrrfPensao := XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                   9,
                                                                   9052);
	  
              vCdBaseCalculo := XTMPAG_var.vgrubrica(vCdRubBaseIrrfPensao).cdbasecalculo;
	  
              vVlBase9052 := XTMPAG_FB.FRetornaValorBaseCalculo(pfolha            => pFolha,
                                                                pcdvinculo        => XTMPAG_VAR.vgCdVinculo,
                                                                pcdtipohistorico  => 2,
                                                                pcdrelacaovinculo => 0,
                                                                pcdbasecalculo    => vcdbasecalculo,
                                                                pcdchave          => pcdvinculo);
	  
            END IF;
	  
            FOR vBase IN (
	  
                          SELECT pCdVinculo AS CdVinculo,
                                  max(case
                                        when v.cdvinculo <> pCdVinculo then
                                         v.cdvinculo
                                        else
                                         0
                                      end) AS CdOutroVinculo,
                                  MAX(CdPessoa) as CdPessoa,
	  
                                  NVL(SUM(CASE
                                            WHEN CdRubricaAgrupamento = pCdRubBaseIRRF AND
                                                 FP.CdFolhaPagamento =
                                                 pFolha.CdFolhaPagamento AND
                                                 V.cdVinculo = pCdVinculo THEN
                                             RV.vlPagamento
                                          END) - vvlDescRubIsentaIRRF,
                                      0) AS VlBaseAtual,
	  
                                  NVL(SUM(CASE
                                            WHEN CdRubricaAgrupamento = pCdRubBaseIRRF AND
                                                 FP.CdFolhaPagamento =
                                                 pFolha.CdFolhaPagamento AND
                                                 V.cdVinculo = pCdVinculo THEN
                                             RV.vlPagamento
                                          END) - vVlDescRubDepJuizo,
                                      0) AS VlBaseAtualSemDepJuizo,
	  
                                  NVL(SUM(CASE
                                            WHEN FP.CdFolhaPagamento =
                                                 pFolha.CdFolhaPagamento AND
                                                 V.CdVinculo = pCdVinculo THEN
                                             CASE
                                               WHEN CdRubricaAgrupamento IN
                                                    (pCdRubAgrupDescIRRF) THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS VlDeduzidoAtual,
	  
                                  NVL(SUM(CASE
                                            WHEN CdRubricaAgrupamento = pCdRubBaseIRRF AND
                                                 FP.CdFolhaPagamento <>
                                                 pFolha.CdFolhaPagamento AND
                                                 flImplantado = 'N' THEN
                                             RV.vlPagamento
                                          END),
                                      0) AS vlBaseOutrosForaSIGRH,
	  
                                  NVL(SUM(CASE
                                            WHEN V.CdVinculo <> pCdVinculo AND
                                                 flImplantado = 'S' THEN
                                             CASE
                                               WHEN CdRubricaAgrupamento IN
                                                    (pCdRubBaseDeducaoInativo) THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS vlAbat65AnosOutrosSIGRH,
                                  NVL(SUM(CASE
                                            WHEN V.CdVinculo <> pCdVinculo AND
                                                 flImplantado = 'N' THEN
                                             CASE
                                               WHEN CdRubricaAgrupamento IN
                                                    (pCdRubBaseDeducaoInativo) THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS vlAbat65AnosOutrosSIRH,
	  
                                  /*NVL(SUM(CASE
                                  WHEN CdRubricaAgrupamento = pCdRubBaseIRRF
                                       AND (FP.CdFolhaPagamento <> pFolha.CdFolhaPagamento OR V.CdVinculo <> pCdVinculo)
                                       AND (FP.CdTipoFolha = pFolha.CdTipoFolha AND FP.CdTipoCalculo = pFolha.CdTipoCalculo) THEN
                                    RV.vlPagamento
                                  END),0) AS vlBaseOutroVincMesmaFol,*/
	  
                                  NVL(SUM(CASE
                                            WHEN (FP.CdFolhaPagamento <>
                                                 pFolha.CdFolhaPagamento OR
                                                 V.CdVinculo <> pCdVinculo) AND
                                                 (FP.CdTipoFolha = pFolha.CdTipoFolha AND
                                                 FP.CdTipoCalculo = pFolha.CdTipoCalculo) THEN
                                             CASE
                                               WHEN CdRubricaAgrupamento IN (pCdRubBaseIRRF) THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS vlBaseOutroVincMesmaFol,
                                  NVL(SUM(CASE
                                            WHEN CdRubricaAgrupamento = pCdRubBaseIRRF AND
                                                 (FP.CdFolhaPagamento <>
                                                 pFolha.CdFolhaPagamento OR
                                                 V.CdVinculo <> pCdVinculo) AND
                                                 (FP.CdTipoFolha <> pFolha.CdTipoFolha OR
                                                 FP.CdTipoCalculo <> pFolha.CdTipoCalculo) THEN
                                             RV.vlPagamento
                                          END),
                                      0) AS vlBaseOutroVincOutraFol,
                                  NVL(SUM(CASE
                                            WHEN CdRubricaAgrupamento = pCdRubBaseIRRF AND
                                                 (FP.CdFolhaPagamento <>
                                                 pFolha.CdFolhaPagamento AND
                                                 V.CdVinculo = pCdVinculo) AND
                                                 (FP.CdTipoFolha <> pFolha.CdTipoFolha OR
                                                 FP.CdTipoCalculo <> pFolha.CdTipoCalculo) AND
                                                 pfolha.cdagrupamento <> 132 THEN -- sig-8230 estava causando erro suplementar agrupamento 132
                                             RV.vlPagamento
                                          END),
                                      0) AS vlBaseMesmoVincOutraFol, -- necessário devido a folha de Honorários PGE
	  
                                  NVL(SUM(CASE
                                            WHEN (FP.CdFolhaPagamento <>
                                                 pFolha.CdFolhaPagamento OR
                                                 V.CdVinculo <> pCdVinculo) AND
                                                 (FP.CdTipoFolha = pFolha.CdTipoFolha AND
                                                 FP.CdTipoCalculo = pFolha.CdTipoCalculo) THEN
                                             CASE
                                               WHEN CdRubricaAgrupamento IN
                                                    (pCdRubAgrupDescIRRF) THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS vlDeduzOutroVincMesmaFol,
	  
                                  NVL(SUM(CASE
                                            WHEN (FP.CdFolhaPagamento <>
                                                 pFolha.CdFolhaPagamento OR
                                                 V.CdVinculo <> pCdVinculo) AND
                                                 (FP.CdTipoFolha <> pFolha.CdTipoFolha OR
                                                 FP.CdTipoCalculo <> pFolha.CdTipoCalculo) THEN
                                             CASE
                                               WHEN CdRubricaAgrupamento IN
                                                    (pCdRubAgrupDescIRRF) THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS vlDeduzOutroVincOutraFol,
                                  NVL(SUM(CASE
                                            WHEN (FP.CdFolhaPagamento <>
                                                 pFolha.CdFolhaPagamento AND
                                                 V.CdVinculo = pCdVinculo) AND
                                                 (FP.CdTipoFolha <> pFolha.CdTipoFolha OR
                                                 FP.CdTipoCalculo <> pFolha.CdTipoCalculo) AND
                                                 pfolha.cdagrupamento <> 132 -- sig-8230 estava causando erro suplementar agrupamento 132
                                             THEN
                                             CASE
                                               WHEN CdRubricaAgrupamento IN
                                                    (pCdRubAgrupDescIRRF) THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS vlDeduzMesmoVincOutraFol, -- necessário devido a folha de Honorários PGE
	  
                                  NVL(SUM(CASE
                                            WHEN (V.CdVinculo <> pCdVinculo) then
                                             CASE
                                               WHEN CdRubricaAgrupamento =
                                                    XTMPAG_VAR.vgCdRubricaDescDepIRRF THEN
                                                RV.vlPagamento
                                             END
                                          END),
                                      0) AS VlDeducaoDependOutroVinc
	  
                            FROM ECadVinculo V
                           INNER JOIN ECalFolhaTrib FP
                              ON FP.SGTRIBUTO = XTMPAG_TIPO.cnSgTribIRRF
                             AND FP.TPMES = vTpMes
                             AND FP.CdCalculoPai =
                                 XTMPAG_VAR.vgCalculo.CdCalculoPai
                             AND ((FP.Cdtipofolha =
                                 XTMPAG_var.vgFolha.Cdtipofolha AND
                                 FP.NUMESREFERENCIA =
                                 XTMPAG_var.vgFolha.NUMESREFERENCIA) OR
                                 (XTMPAG_var.vgFolha.Cdtipofolhapagamento in
                                 (1505, 1525, 1526, 1606, 1607, 1608) AND
                                 (fp.cdtipofolhapagamento <>
                                 XTMPAG_var.vgFolha.Cdtipofolhapagamento)) OR
                                 FP.NUMESREFERENCIA <> XTMPAG_var.vgFolha.NUMESREFERENCIA OR
                                 (pFolha.CdTipoFolha IN
                                 (XTMPAG_tipo.cnTpFolhaCtisp13,
                                    XTMPAG_tipo.cnTpFolhaCtisp) AND
                                 FP.NUMESREFERENCIA =
                                 XTMPAG_var.vgFolha.NUMESREFERENCIA))
                           INNER JOIN EPagHistoricoRubricaVinculo RV
                              ON V.CdVinculo = RV.CdVinculo
                             AND FP.CdFolhaPagamento = RV.CdFolhaPagamento
                           WHERE V.CdPessoa = pCdPessoa
                             AND FP.NUMESREFERENCIA = XTMPAG_var.vgFolha.NUMESREFERENCIA
                             AND RV.CdRubricaAgrupamento IN
                                 (pCdRubBaseIRRF,
                                  pCdRubAgrupDescIRRF,
                                  XTMPAG_VAR.vgCdRubricaDescDepIRRF,
                                  pCdRubBaseDeducaoInativo,
                                  pCdRubAgrupDevDesc)
                             AND -- Desconsiderar a folha normal do orgao quando fazendo recalculo
                                 (NOT
                                  (pFolha.CdTipoCalculo in
                                  (XTMPAG_TIPO.cnTpCalculoRecalculoMes) -- Fazendo Recalculo
                                  AND
                                  ((RV.CdVinculo = pCdVinculo AND
                                  (FP.CdFolhaPagamento =
                                  XTMPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                  (FP.CdFolhaPagamento <>
                                  pFolha.CdFolhaPagamento AND
                                  FP.CdTipoCalculo in
                                  (XTMPAG_TIPO.cnTpCalculoRecalculoMes)))) OR
                                  (RV.CdVinculo <> pCdVinculo AND
                                  FP.CdTipoCalculo in
                                  (XTMPAG_TIPO.cnTpCalculoRecalculoMes)))))
	  
                             AND (NOT (pFolha.CdTipoCalculo =
                                  XTMPAG_TIPO.cnTpCalculoDifMes AND
                                  XTMPAG_VAR.vgFaseCalculo =
                                  XTMPAG_TIPO.cnFaseCalculoIntegral AND
                                  ((RV.CdVinculo = pCdVinculo AND
                                  (FP.CdFolhaPagamento =
                                  XTMPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                  (FP.CdFolhaPagamento <>
                                  pFolha.CdFolhaPagamento AND
                                  FP.CdTipoCalculo =
                                  XTMPAG_TIPO.cnTpCalculoDifMes))) OR
                                  (RV.CdVinculo <> pCdVinculo AND
                                  FP.CdTipoCalculo =
                                  XTMPAG_TIPO.cnTpCalculoDifMes))))
	  
                          ) LOOP
	  
              BEGIN
	  
                IF vBase.CdVinculo <> vBase.CdOutroVinculo and
                   vBase.CdOutroVinculo <> 0 and
                   XTMPAG_VAR.vgVlDeducaoDependente = 0 and
                   not FAgrupUtilizaDescSimp(pCdAgrupamento => pFolha.CdAgrupamento,
                                             pNuAnoMesFolha => (pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia)  THEN
	  
                  XTMPAG_VAR.vgVlDeducaoDependOutroVinc := XTMPAG_TRIBUTACAO.FDependenteOutroVinculo(pCdPessoa,
                                                                                                     vBase.CdVinculo,
                                                                                                     pFolha.DtInicioMes,
                                                                                                     pFolha.DtFimMes) *
                                                           XTMPAG_VAR.vAliquotaIRRF.VlDeducaoDependente;
	  
                END IF;
	  
                IF vBase.vlBaseOutroVincMesmaFol <> 0 THEN
	  
                  IF --A base BIR13 já soma os valores dos outros vinculos
                     pCdRubBaseIRRF = XTMPAG_VAR.vgCdRubBaseIRRF13
                     THEN
                    vVlBaseOutros := 0;
                  ELSE
                    vVlBaseOutros := vBase.vlBaseOutroVincMesmaFol;
                  END IF;
	  
                  vVlDeduzidoOutros := vBase.vlDeduzOutroVincMesmaFol;
                  --XTMPAG_VAR.vgVlDeducaoDependOutroVinc := vBase.VlDeducaoDependOutroVinc;
	  
                ELSIF vBase.CdOutroVinculo <> 0 THEN
	  
                  vVlBaseOutros     := vBase.vlBaseOutroVincOutraFol;
                  vVlDeduzidoOutros := vBase.vlDeduzOutroVincOutraFol;
                  --XTMPAG_VAR.vgVlDeducaoDependOutroVinc := vBase.VlDeducaoDependOutroVinc;
	  
                ELSIF vBase.vlBaseMesmoVincOutraFol <> 0 THEN
                  -- necessário devido a folha de honorários PGE
                  vVlBaseOutros     := vBase.vlBaseMesmoVincOutraFol;
                  vVlDeduzidoOutros := vBase.vlDeduzMesmoVincOutraFol;
	  
                ELSE
	  
                  vVlBaseOutros     := 0;
                  vVlDeduzidoOutros := 0;
	  
                END IF;
                
                IF pFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoRecalculoMes THEN
                    
                                     
                    vVlBaseOutros := FRetornaVlBaseOutros(pCdPessoa,
                                                          pCdVinculo,
                                                          pFolha);                                                                                              
                   
                END IF;
	  
	  
                IF pTpTributacao <> 4 THEN
                  --- = a Normal, 13º, Ferias
	  
                  vVlNM := 1;
	  
                  XTMPAG_VAR.vgValorBaseIRRF := (vBase.VlBaseAtual + vVlBaseOutros);
	  
                  IF not FAgrupUtilizaDescSimp(pCdAgrupamento => pFolha.CdAgrupamento,
                                               pNuAnoMesFolha => (pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia)  then
                     vvlDeducaoInativoReal := pvlDeducaoInativo;
	  
                  else
	  
                     vBase.vlAbat65AnosOutrosSIGRH := 0;
                     vvlDeducaoInativoReal := 0;
	  
                  end if;
                  ----------------------------------------------------------------------
                  -- Se tem mais de 1 vinculo no SIRH como inativo
                  -- No SIRH a base ja e Liquida, nao deve deduzir o Abat Maior 65 anos
                  ----------------------------------------------------------------------
	  
                  IF vBase.vlBaseOutrosForaSIGRH > 0 AND
                     vBase.vlAbat65AnosOutrosSIRH > 0 THEN
	  
                    IF vBase.vlAbat65AnosOutrosSIRH <= pvlDeducaoInativo THEN
	  
                      vvlDeducaoInativoReal := pvlDeducaoInativo -
                                               vBase.vlAbat65AnosOutrosSIRH;
	  
                    END IF;
	  
                    vVlBaseOutros := fRetornaBaseOutraFolAberta(pCdVinculo,pFolha,pCdRubBaseIRRF);
	  
                    vvlLiquido := (vBase.VlBaseAtual + vVlBaseOutros) -
                                  (XTMPAG_VAR.vgvlDeducaoDependente +
                                  vvlDeducaoInativoReal);
	  
                    vVlBase9052.vlReal := (nvl(vVlBase9052.VlReal, 0) +
                                          vVlBaseOutros) -
                                          (XTMPAG_VAR.vgvlDeducaoDependente +
                                          vvlDeducaoInativoReal);
	  
                  ELSIF vBase.vlAbat65AnosOutrosSIGRH > 0 THEN
	  
                    IF vBase.vlAbat65AnosOutrosSIGRH <= pvlDeducaoInativo THEN
	  
                      vvlDeducaoInativoReal := pvlDeducaoInativo -
                                               vBase.vlAbat65AnosOutrosSIGRH;
	  
                    END IF;
	  
                    vvlLiquido := (vBase.VlBaseAtual + vVlBaseOutros) -
                                  (XTMPAG_VAR.vgvlDeducaoDependente +
                                  XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                  vBase.vlAbat65AnosOutrosSIGRH +
                                  vvlDeducaoInativoReal);
	  
                    vVlBase9052.vlReal := (nvl(vVlBase9052.VlReal, 0) +
                                          vVlBaseOutros) -
                                          (XTMPAG_VAR.vgvlDeducaoDependente +
                                          XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                          vBase.vlAbat65AnosOutrosSIGRH +
                                          vvlDeducaoInativoReal);
	  
                  ELSE
	  
                    IF pFolha.CdTipoFolha = XTMPAG_tipo.cnTpFolha13 THEN 
                      
                      IF FAgrupUtilizaDescSimp(pCdAgrupamento => pFolha.CdAgrupamento,
                                               pNuAnoMesFolha => (pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia) THEN
                        
                       
                          vvlDescSimp := XTMPAG_PARAM.FValorReferencia('DESCSIMPL');
                          
                          IF (XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                pCdVinculo,
                                                                XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                                                1,
                                                                NULL) +
                              XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                pCdVinculo,
                                                                XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                                                1,
                                                                NULL))  > vvlDescSimp THEN
                                                                
                                 vvlrubDescSimp := (XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                                      pCdVinculo,
                                                                                      XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                                                                      1,
                                                                                      NULL) +
                                                    XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                                      pCdVinculo,
                                                                                      XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                                                                      1,
                                                                                      NULL));                             
                          ELSE
                            
                                 vvlrubDescSimp := vvlDescSimp;
                                 
                                 ------------------------------------------------------
                                 -- BASE DESCONTO SIMPLIFICADO IRRF 13 SAL 09-1913   --
                                 ------------------------------------------------------
                                  IF XTMPAG_VAR.vgCdRubBaseDescSimplif13 IS NOT NULL AND
                                     XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                       pCdVinculo,
                                                                       XTMPAG_VAR.vgCdRubBaseDescSimplif13,
                                                                       1,
                                                                       NULL) = 0 THEN
                                           
                                    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                          pCdVinculo            => pCdVinculo,
                                                                          pCdExpressaoFormCalc  => NULL,
                                                                          pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDescSimplif13,
                                                                          pNuSufixoRubrica      => 1,
                                                                          pVlPagamento          => 0,
                                                                          pVlIndice             => NULL,
                                                                          pCdTipoOrigemRubrica  => 10);
                                                                      
                                   
                                    XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                                     pCdVinculo       => pCdVinculo,
                                                                     pCdRubrica       => XTMPAG_VAR.vgCdRubBaseDescSimplif13,
                                                                     pTpProcessamento => 2, -- Processa base de calculo
                                                                     pTpLocal         => 2);                                         
                                    
                                                                                                                                             
                                 END IF; 
                                        
                          END IF;                                                                                                                  
                                                       
                          vvlLiquido := (vBase.VlBaseAtual + vVlBaseOutros) - vvlrubDescSimp;
                        
	  
                          vVlBase9052.vlReal := (nvl(vVlBase9052.VlReal, 0) +
                                                 vVlBaseOutros);
                      ELSE
                        
                        --sig-5337
                        --Para folha de 13 salário, não considera a base de outros vinculos pois o calc da
                        --09-0015 já considera o somaAno das rubricas
	  
                  /*      IF pFolha.CdAgrupamento IN (4, 5) THEN
                          
                          vvlLiquido := vBase.VlBaseAtual - (--XTMPAG_VAR.vgvlDeducaoDependente +
                                        XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                        vvlDeducaoInativoReal);
	  
                          vVlBase9052.vlReal := vBase.VlBaseAtual -
                                                (--XTMPAG_VAR.vgvlDeducaoDependente +
                                                XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                                vvlDeducaoInativoReal);*/
                                                
                        IF pFolha.CdAgrupamento = 134 THEN
                          
                          vvlLiquido := vBase.VlBaseAtual - (XTMPAG_VAR.vgvlDeducaoDependente + 
                                        XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                        vvlDeducaoInativoReal);
	  
                          vVlBase9052.vlReal := vBase.VlBaseAtual -
                                                (XTMPAG_VAR.vgvlDeducaoDependente +
                                                XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                                vvlDeducaoInativoReal);
                        ELSE
	  
                          vvlLiquido := vBase.VlBaseAtual - (/*XTMPAG_VAR.vgvlDeducaoDependente + */
                                        XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                        vvlDeducaoInativoReal);
	  
                          vVlBase9052.vlReal := vBase.VlBaseAtual -
                                              (/*XTMPAG_VAR.vgvlDeducaoDependente +*/
                                              XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                              vvlDeducaoInativoReal);
                        END IF;
                        
                      END IF;
                                        
                    ELSE                 
                      
                      IF FAgrupUtilizaDescSimp(pCdAgrupamento => pFolha.CdAgrupamento,
                                               pNuAnoMesFolha => (pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia)
                        AND pFolha.CdTipoFolha <> XTMPAG_TIPO.cnTpFolhaFerias
                        AND pTpTributacao <> 3 THEN
                        
                        IF ((pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia) >= 202408 
                        AND NOT FVerificaResidenteExterior--23654/2025 - CLAUDEMIR GOMES - 26/08/2025
                        THEN
                          
                          vvlDescSimp := XTMPAG_PARAM.FValorReferencia('DESCSIMPL');
                          
                          IF pTpTributacao = 2 THEN
                            
                            IF (XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                  pCdVinculo,
                                                                  XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                                                  1,
                                                                  NULL) +
                                XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                  pCdVinculo,
                                                                  XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                                                  1,
                                                                  NULL))  > vvlDescSimp THEN
                                                                  
                                   vvlrubDescSimp := (XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                                        pCdVinculo,
                                                                                        XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                                                                        1,
                                                                                        NULL) +
                                                      XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,                                                                               
                                                                                        pCdVinculo,
                                                                                        XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                                                                        1,
                                                                                        NULL));                             
                            ELSE
                              
                                   vvlrubDescSimp := vvlDescSimp;
                                   
                                   -------------------------------------------------------------
                                   -- INSERE BASE DESCONTO SIMPLIFICADO IRRF 13 SAL 09-1913   --
                                   -------------------------------------------------------------
                                    IF XTMPAG_VAR.vgCdRubBaseDescSimplif13 IS NOT NULL AND
                                       XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                         pCdVinculo,
                                                                         XTMPAG_VAR.vgCdRubBaseDescSimplif13,
                                                                         1,
                                                                         NULL) = 0 THEN
                                             
                                      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                            pCdVinculo            => pCdVinculo,
                                                                            pCdExpressaoFormCalc  => NULL,
                                                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDescSimplif13,
                                                                            pNuSufixoRubrica      => 1,
                                                                            pVlPagamento          => 0,
                                                                            pVlIndice             => NULL,
                                                                            pCdTipoOrigemRubrica  => 10);
                                                                        
                                     
                                      XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                                       pCdVinculo       => pCdVinculo,
                                                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseDescSimplif13,
                                                                       pTpProcessamento => 2, -- Processa base de calculo
                                                                       pTpLocal         => 2);                                         
                                      
                                                                                                                                               
                                   END IF; 
                                          
                            END IF;                                      
                                                 
                              
                          ELSIF pTpTributacao = 1 THEN 
                            
                            IF (XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                                  pCdVinculo,
                                                                  XTMPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                                                  1,
                                                                  NULL) + 
                                XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                                  pCdVinculo,
                                                                  XTMPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                                                  1,
                                                                  NULL)) > vvlDescSimp  THEN
                                                                                      
                               vvlrubDescSimp := XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                                                   pCdVinculo,
                                                                                   XTMPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                                                                   1,
                                                                                   NULL) + 
                                                 XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                                                   pCdVinculo,
                                                                                   XTMPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                                                                   1,
                                                                                   NULL);                                                       
                            ELSE
                              
                              vvlrubDescSimp := vvlDescSimp;
                              
                              -------------------------------------------------------
                              -- INSERE BASE DESCONTO SIMPLIFICADO IRRF  09-1910   --
                              -------------------------------------------------------
                              IF XTMPAG_VAR.vgCdRubBaseDescSimplifIRRF IS NOT NULL AND
                                 XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                   pCdVinculo,
                                                                   XTMPAG_VAR.vgCdRubBaseDescSimplifIRRF,
                                                                   1,
                                                                   NULL) = 0 THEN
                                       
                                    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                          pCdVinculo            => pCdVinculo,
                                                                          pCdExpressaoFormCalc  => NULL,
                                                                          pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDescSimplifIRRF,
                                                                          pNuSufixoRubrica      => 1,
                                                                          pVlPagamento          => 0,
                                                                          pVlIndice             => NULL,
                                                                          pCdTipoOrigemRubrica  => 10);
                                                                          
                                    XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                                     pCdVinculo       => pCdVinculo,
                                                                     pCdRubrica       => XTMPAG_VAR.vgCdRubBaseDescSimplifIRRF,
                                                                     pTpProcessamento => 2, -- Processa base de calculo
                                                                     pTpLocal         => 2);                                  
                                      
                                                                                                                                               
                              END IF; 
                                   
                            END IF;                                                                                  
	  
                          END IF;
                                                                                                                                                              
                        ELSE
                          
                          vvlrubDescSimp := 0;
                          
                        END IF;                                                  
                        
                        vvlLiquido := (vBase.VlBaseAtual + vVlBaseOutros) - vvlrubDescSimp;
                        
	  
                        vVlBase9052.vlReal := (nvl(vVlBase9052.VlReal, 0) +
                                              vVlBaseOutros);
                      ELSE
                        
                        vvlLiquido := (vBase.VlBaseAtual + vVlBaseOutros) -
                                      (XTMPAG_VAR.vgvlDeducaoDependente +
                                      XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                      vvlDeducaoInativoReal);
	  
                        vVlBase9052.vlReal := (nvl(vVlBase9052.VlReal, 0) +
                                              vVlBaseOutros) -
                                              (XTMPAG_VAR.vgvlDeducaoDependente +
                                              XTMPAG_VAR.vgVlDeducaoDependOutroVinc +
                                              vvlDeducaoInativoReal);
                      END IF;
                    END IF;
                  END IF;
	  
                  -------------------------------------------------------------------
                  -- Caso existam processos de retroativos isentos do IRRF,
                  -- os valores destes serao abatidos da base liquida
                  -------------------------------------------------------------------
	  
                  vVlIsentoRetroIRRF := FValorIsentoRetIRRF(pFolha         => pFolha,
                                                            pCdVinculo     => pCdVinculo,
                                                            pCdRubBaseIRRF => pCdRubBaseIRRF);
	  
                  IF pbPrima THEN
	  
                    IF vVlIsentoRetroIRRF > 0 THEN
	  
                      BEGIN
	  
                        IF vvlDescRubIsentaIRRF > 0 THEN
	  
                          UPDATE EPagHistoricoRubricaVinculo HRV
                             SET HRV.VlPagamento = HRV.vlPagamento +
                                                   vVlIsentoRetroIRRF
                           WHERE HRV.CdVinculo = pCdVinculo
                             AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                             AND HRV.CdRubricaAgrupamento =
                                 XTMPAG_VAR.vgCdRubExigibilidadeSusp;
	  
                        ELSE
	  
                          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                pCdVinculo            => pCdVinculo,
                                                                pCdExpressaoFormCalc  => NULL,
                                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubExigibilidadeSusp,
                                                                pNuSufixoRubrica      => 1,
                                                                pVlPagamento          => vVlIsentoRetroIRRF,
                                                                pVlIndice             => NULL,
                                                                pCdTipoOrigemRubrica  => 10);
	  
                        END IF;
	  
                      EXCEPTION
                        WHEN OTHERS THEN
                          XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                                  XTMPAG_VAR.vCdHistParamCalc,
                                                  XTMPAG_VAR.vCdPessoa,
                                                  'XTMPAG_TRIBUTACAO.vvlDescRubIsentaIRRF',
                                                  XTMPAG_VAR.vgCdVinculo);
                      END;
	  
                    END IF;
	  
                  END IF;
	  
                  vVlLiquido := vVlLiquido - vVlIsentoRetroIRRF;
	  
                  vVlBase9052.vlReal := vVlBase9052.vlReal - vVlIsentoRetroIRRF;
	  
                  ----------------------------------------------------------------
                  -- Abate o valor isento das rubricas de retroativo da base bruta
                  ----------------------------------------------------------------
	  
                  vBase.VlBaseAtual := vBase.VlBaseAtual - vVlIsentoRetroIRRF;
	  
                ELSE
                  -- RRA
	  
                  -- Valor uriundo das rubricas de retroativos de exercicios findos, isentas por decisao judicial
                  -- e que incidem para na base de IRRF a ser subitraido desta base.
	  
                  vVlIsentoRetroIRRFRRA := FValorIsentoRetIRRFRRA(pFolha                   => pFolha,
                                                                  pCdVinculo               => pCdVinculo,
                                                                  pCdProcessoPagRetroativo => XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo,
                                                                  pCdRubBaseIRRF           => pCdRubBaseIRRF);
	  
                  -- Como a base de IRRF nao soma as rubrias de ferias e 13º, soma estes valores para integralizar
                  -- a base que sera transformada em base de IRRF de RRA
	  
                  vVlOutrosRRA := vVlOutrosRRA +
                                  FRetornaOutrosValoresRRA(pFolha                   => pFolha,
                                                           pCdVinculo               => pCdVinculo,
                                                           pCdProcessoPagRetroativo => XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo);
	  
                  -- Gera a rubrica de Exigibilidade suspensa de RRA caso o valor da variavel
                  -- vVlIsentoRetroIRRFRRA seja maior que zero.
	  
                  IF vVlIsentoRetroIRRFRRA > 0 THEN
	  
                    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                          pCdVinculo               => pCdVinculo,
                                                          pCdExpressaoFormCalc     => NULL,
                                                          pCdRubricaAgrupamento    => XTMPAG_VAR.vgCdRubExigibilidadeSuspRRA,
                                                          pNuSufixoRubrica         => pIndProcRetro,
                                                          pVlPagamento             => vVlIsentoRetroIRRFRRA,
                                                          pCdProcessoPagRetroativo => XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo,
                                                          pVlIndice                => NULL,
                                                          pCdTipoOrigemRubrica     => 10);
	  
                  END IF;
	  
                  vVlIprevRRA := vVlIprevRRA +
                                 FRetornaIprevRRA(pFolha                   => pFolha,
                                                  pCdVinculo               => pCdVinculo,
                                                  pCdProcessoPagRetroativo => XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo);
	  
                  -- Somente somar se ja tiver base (por cause de bases negativas que geram totalizadoras com valor zero
	  
                  IF vBase.VlBaseAtual >= 0 THEN
	  
                    vBase.VlBaseAtual := vBase.VlBaseAtual + vVlOutrosRRA -
                                         vVlIsentoRetroIRRFRRA;
	  
                  END IF;
	  
                  IF NVL(XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).VlMontante,
                         0) <=
                     XTMPAG_VAR.vgParamPagamento.VlLimitePagRetroativo THEN
	  
                    vVlNM := XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).NuMeses;
	  
	  
                    If pfolha.CdOrgao = 25 and
	  
                       XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).NuMeses = 49 then
	  
                    vVlNM := 1;
	  
                    end if;
	  
                  ELSE
	  
                    -- Para calculo do NM deve utilizar a base bruta (por isso soma o valor do IPREV de RRA)
                    vVlNmReal := trunc(XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro)
                                       .NuMeses *
                                        ((vBase.VlBaseAtual + vVlIprevRRA) / XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).VlMontante),
                                       3);
	  
                    vVlNmRealDec := vVlNmReal - trunc(vVlNmReal);
	  
                    if substr(vVlNmRealDec, 3, 1) = 5 and
                       substr(vVlNmRealDec, 4, 1) < 5 then
                      vVlNmReal := vVlNmReal - 0.0100;
                    end if;
	  
                    vVlNM := ROUND(vVlNmReal, 1);
	  
                  END IF;
	  
                  vvlLiquido := vBase.VlBaseAtual;
	  
                  XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).VlIndiceNMRRA := vVlNM;
	  
                END IF;
	  
                PAtualizaBaseIRRF(pvlBase => vBase.VlBaseAtual,
                                  pVlNM   => CASE
                                               WHEN pTpTributacao <> 4 THEN
                                                NULL
                                               ELSE
                                                vVlNM
                                             END);
	  
                -- AJUSTA O VALOR PARA O ABATIMENTO MAIOR 65 IRRF.
                -- SE A BASE IRRF FOR MAIOR QUE O ABATIMENTO, MANTEM O VALOR TOTAL DO ABATIMENTO CONFORME TABELA IR
                -- SE A BASE IRRF FOR MENOR QUE O ABATIMENTO, SETA O VALOR DA BASE IRRF
	  
                -- 9816/2017 - MILITARES - FOLHA - - CALCULO DO 09-0910 -ABAT 65 ANOS
                IF pFolha.CdAgrupamento = 134 AND pTpTributacao <> 1 AND
                   (XTMPAG_geral.fretornavalorrubrica(pFolha.Cdfolhapagamento,
                                                      pcdvinculo,
                                                      XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                   1,
                                                                                   356)) > 0 OR
                   XTMPAG_geral.fretornavalorrubrica(pFolha.Cdfolhapagamento,
                                                      pcdvinculo,
                                                      XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                   1,
                                                                                   323)) > 0) AND
                   XTMPAG_geral.fretornavalorrubrica(pFolha.Cdfolhapagamento,
                                                     pCdVinculo,
                                                     XTMPAG_var.vgCdRubBaseIRRF) = 0 AND
                   vBase.VlBaseAtual < vvlDeducaoInativoReal THEN
	  
                  vvlDeducaoInativoReal := vBase.VlBaseAtual;
	  
                ELSIF vBase.VlBaseAtual < vvlDeducaoInativoReal THEN
	  
                  vvlDeducaoInativoReal := vBase.VlBaseAtual;
	  
                else
                  null;
                END IF;
	  
                -- COHAB - INSS de ferias ficticio
                -- Para a COHAB, deduz o valor da rubrica 05-0216 DESCONTO 216 da base de IRRF
                IF pFolha.CdAgrupamento = 3 AND vBase.VlBaseAtual > 0 THEN
                  vVlRub50216 := NVL(XTMPAG_geral.fretornavalorrubrica(pFolha.Cdfolhapagamento,
                                                                       pcdvinculo,
                                                                       XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                    5,
                                                                                                    216)),
                                     0);
	  
                  IF vVlRub50216 > 0 THEN
                    vvlLiquido := vvlLiquido - vVlRub50216;
                  END IF;
                END IF;
	  
                IF vBase.VlBaseAtual > 0 THEN
                  IF (pFolha.CdTipoFolha IN (XTMPAG_tipo.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13))
                     OR (pCdRubBaseIRRF = XTMPAG_VAR.vgCdRubBaseIRRF13 AND pFolha.CdTipoFolha IN (XTMPAG_tipo.cnTpFolhaNormal, XTMPAG_tipo.cnTpFolhaCtisp, XTMPAG_TIPO.cnTpFolhaConvenio))
                  THEN
                    vvlDeduzidoOutros := FretornaVlSomaAnoRubrica2(pCdVinculo,
                                                                      pFolha,
                                                                      5,
                                                                      546);
                                                                      
                  ELSIF pFolha.CdTipoCalculo = XTMPAG_TIPO.cnTpCalculoRecalculoMes THEN
                    
                    vvlDeduzidoOutros := FRetornaVlDeduzidoOutros(pCdPessoa,
                                                                  pCdVinculo,
                                                                  pFolha);     
                                                                   
                  END IF;
	  
                  i := 0;
	  
                  IF ((pFolha.NuAnoReferencia*100)+pFolha.NuMesReferencia) >= 202408 AND pTpTributacao = 4 THEN                               
                    vvlLiquido := vvlLiquido - XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                                                 pCdVinculo,
                                                                                 XTMPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                                                                 1,
                                                                                 NULL);  
                  END IF;              
	  
                  WHILE i < (XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT) LOOP
	  
                    i := i + 1;
	  
                    IF vvlLiquido BETWEEN XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                      .vlInicial * vVlNM AND XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                      .vlFinal * vVlNM THEN
	  
                      vvlLiquido      := vvlLiquido * XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota / 100;
                      vvlLimiteDescIR := XTMPAG_VAR.vgVlTotalProventos * XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota / 100;
	  
                      IF pTpTributacao <> 4 THEN
	  
                        vvlLiquido := vvlLiquido - NVL(XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                                                       .VlParcelaDeducao * vVlNM,
                                                       0) -
                                      vBase.vlDeduzidoAtual - NVL(vvlDeduzidoOutros, 0);
	  
                        IF pFolha.CdTipoFolha IN (XTMPAG_tipo.cnTpFolhaCtisp13,
                                                  XTMPAG_tipo.cnTpFolhaProdex13,
                                                  XTMPAG_tipo.cnTpFolhaHonorarios13,
                                                  XTMPAG_tipo.cnTpFolhaHonorarProcuradores13) THEN
	  
                          IF vvlLiquido > vvlLimiteDescIR AND NVL(XTMPAG_VAR.vgVlTotalProventos, 0) > 0 THEN
                          vvlLiquido := vvlLimiteDescIR;
                        END IF;
	  
                        END IF;
	  
                      ELSE
	  
                        vvlLiquido := vvlLiquido - NVL(XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                                                       .VlParcelaDeducao * vVlNM,
                                                       0);
	  
                      END IF;
	  
                      vCdRubricaGerada := FRetornaRubrica(pFolha.CdTipoCalculo,
                                                          NVL(vBase.vlDeduzidoAtual,
                                                              0) +
                                                          NVL(vvlDeduzidoOutros,
                                                              0),
                                                          vvlLiquido);
	  
                      vvlIndiceRubrica := XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota;
	  
                      i := XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT + 1;
	  
                    END IF;
	  
                  END LOOP;
	  
                  -----------------------------------------------------------------------------
                  -- Caso seja Tributacao Normal, gera registros para rubricas automaticas
                  -- das modalidades 39 e 40
                  -----------------------------------------------------------------------------
	  
                  IF pTpTributacao IN (1, 2) THEN
	  
                    -- Insere rubrica automatica (Modalidade 39)
	  
                    IF vVlBaseOutros > 0 AND vBase.VlBaseAtual > 0 AND pbPrima THEN
	  
                      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                            pCdVinculo            => pCdVinculo,
                                                            pCdExpressaoFormCalc  => NULL,
                                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIRRFOutros,
                                                            pNuSufixoRubrica      => 1,
                                                            pVlPagamento          => vVlBaseOutros,
                                                            pVlIndice             => NULL,
                                                            pCdTipoOrigemRubrica  => 10);
                    END IF;
	  
                    -- Insere rubrica automatica (Modalidade 40)
	  
                    IF vVlDeduzidoOutros > 0 AND vBase.VlBaseAtual > 0 AND
                       NOT NVL(XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                                 pcdvinculo,
                                                             XTMPAG_VAR.vgCdRubDeducaoIRRFOutros), 0) = vVlDeduzidoOutros THEN
	  
                      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                            pCdVinculo            => pCdVinculo,
                                                            pCdExpressaoFormCalc  => NULL,
                                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubDeducaoIRRFOutros,
                                                            pNuSufixoRubrica      => 1,
                                                            pVlPagamento          => vVlDeduzidoOutros,
                                                            pVlIndice             => NULL,
                                                            pCdTipoOrigemRubrica  => 10);
                    END IF;
	  
                  END IF;
	  
                END IF;
	  
                --
                -- Se possui valor de IR sobre pensao
                --
	  
                IF vVlBase9052.vlReal > 0 and XTMPAG_VAR.bPossuiPensao THEN
	  
                  i := 0;
	  
                  WHILE i < (XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT) LOOP
	  
                    i := i + 1;
	  
                    IF vVlBase9052.vlReal BETWEEN XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                      .vlInicial * vVlNM AND XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                      .vlFinal * vVlNM THEN
	  
                      vVlBase9052.vlReal := vVlBase9052.vlReal * XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota / 100;
	  
                      IF pTpTributacao <> 4 THEN
	  
                        vVlBase9052.vlReal := vVlBase9052.vlReal -
                                              NVL(XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                                                  .VlParcelaDeducao * vVlNM,
                                                  0) - vBase.vlDeduzidoAtual -
                                              vvlDeduzidoOutros;
                      ELSE
	  
                        vVlBase9052.vlReal := vVlBase9052.vlReal -
                                              NVL(XTMPAG_VAR.vAliquotaIRRF.lFaixa(i)
                                                  .VlParcelaDeducao * vVlNM,
                                                  0);
	  
                      END IF;
	  
                      vvlIndiceRubrica := XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota;
	  
                      i := XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT + 1;
	  
                    END IF;
	  
                  END LOOP;
	  
                  --
                  -- Valor do IR sobre a base da pensao
                  --
	  
                  UPDATE EPagHistoricoRubricaVinculo HRV
                     SET HRV.Vlpagamento = vVlBase9052.vlReal
                   WHERE HRV.CdVinculo = pCdVinculo
                     AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                     AND HRV.CdRubricaAgrupamento =
                         XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                      9,
                                                      9053);
	  
                  --
                  -- Base de calculo do IR da pensao
                  --
                  UPDATE EPagHistoricoRubricaVinculo HRV
                     SET HRV.Vlpagamento = vVlBase9052.vlIntegral
                   WHERE HRV.CdVinculo = pCdVinculo
                     AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                     AND HRV.CdRubricaAgrupamento =
                         XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                      9,
                                                      9052);
	  
                END IF;
	  
              END;
	  
            END LOOP;
	  
            -- 3. Isolada
	  
          ELSIF pCdTipoTributacaoIRRF = 3 THEN
	  
            FOR rBase IN cBaseIsolada LOOP
	  
              IF bDescRubIsentaIRRF THEN
	  
                vvlDescRubIsentaIRRF := FRetornaValorRubIsentas(pCdVinculo      => pCdVinculo,
                                                                pFolha          => pFolha,
                                                                pCdTipoDesconto => 2);
              END IF;
	  
              vvlLiquido := rBase.VlBase - XTMPAG_VAR.vgVlDeducaoDependente -
                            XTMPAG_VAR.vgVlDeducaoDependOutroVinc -
                            pvlDeducaoInativo;
	  
              PAtualizaBaseIRRF(pvlBase => rBase.VlBase);
	  
              XTMPAG_VAR.vgValorBaseIRRF := rBase.VlBase;
	  
              i := 0;
	  
              WHILE i < (XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT) LOOP
	  
                i := i + 1;
	  
                IF vvlLiquido BETWEEN XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).vlInicial AND XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).vlFinal THEN
	  
                  vvlLiquido := vvlLiquido * XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota / 100;
	  
                  vvlLiquido := vvlLiquido - nvl(XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlParcelaDeducao,
                                                 0);
	  
                  vCdRubricaGerada := pCdRubAgrupDescIRRF;
	  
                  vvlIndiceRubrica := XTMPAG_VAR.vAliquotaIRRF.lFaixa(i).VlAliquota;
	  
                  i := XTMPAG_VAR.vAliquotaIRRF.lFaixa.COUNT + 1;
	  
                END IF;
	  
              END LOOP;
	  
            END LOOP;
	  
          else
            null;
          END IF;
	  
          IF vCdRubricaGerada IN (pCdRubAgrupDifDesc, pCdRubAgrupDevDesc) THEN
	  
            vvlLiquido := ABS(vvlLiquido);
	  
          END IF;
	  
          if XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                               pCdVinculo,XTMPAG_var.vgCdRubBaseIRRF) = 0 then
	  
           DELETE FROM EPagHistoricoRubricaVinculo HRV
           WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseDeducoesIRRF;
	  
          end if;
	  
          if XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                               pCdVinculo,XTMPAG_var.vgCdRubBaseIRRF13) = 0 then
          DELETE FROM EPagHistoricoRubricaVinculo HRV
           WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13;
	  
         end if;
          -- Ate 15/06/2011 -> vvlLiquido > 10.00
       
          IF vCdRubricaGerada > 0 AND vvlLiquido > 0 THEN
	  
            IF XTMPAG_GERAL.FGeraRubrica(pRubrica => vCdRubricaGerada) THEN
	  
              DELETE FROM EPagHistoricoRubricaVinculo HRV
               WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND HRV.CdVinculo = pCdVinculo
                 AND HRV.CdRubricaAgrupamento = vCdRubricaGerada;
	  
              INSERT INTO EPagHistoricoRubricaVinculo
                (CdHistoricoRubricaVinculo,
                 CdFolhaPagamento,
                 CdRubricaAgrupamento,
                 CdVinculo,
                 NuSufixoRubrica,
                 CdLancamentoFinanceiro,
                 VlPagamento,
                 QtParcelas,
                 VlIndiceRubrica,
                 DtUltAlteracao,
                 CdTipoOrigemRubrica,
                 CdTipoIndice,
                 cdprocessopagretroativo)
              VALUES
                (Spaghistoricorubricavinculo.NEXTVAL,
                 pFolha.CdFolhaPagamento,
                 vCdRubricaGerada,
                 pCdVinculo,
                 1,
                 NULL,
                 vvlLiquido,
                 1,
                 vvlIndiceRubrica,
                 systimestamp,
                 10,
                 XTMPAG_VAR.vgRubrica(vCdRubricaGerada).CdTipoIndice,
                 vCdProcPagRetro);
	  
              IF vVlDescRubDepJuizo > 0 THEN
	  
                pInsereDepositoEmJuizo(pFolha,
                                       pCdPessoa,
                                       pCdVinculo,
                                       XTMPAG_VAR.vgValorBaseIRRF,
                                       vVlLiquido);
	  
              END IF;
	  
            END IF;
	  
          END IF;
	  
        END IF;
        
      ELSE
	  
        DELETE FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdRubricaAgrupamento = pCdRubBaseIRRF;
	  
	  
	  
      END IF;

    ELSE
      --23654/2025 - GEREF - TRIBUTACAO IRRF SERVIDOR RESIDENTE NO EXTERIOR
      --CLAUDEMIR GOMES - 17/09/2025
      vAliquotaIRRF := XTMPAG_VAR.vAliquotaIRRFExterior;
      
      IF pFolha.CdAgrupamento = 1 THEN
        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIRRF,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);
        XTMPAG_VAR.vgValorBaseIRRF := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                        pcdvinculo        => pcdvinculo,
                                                                        pcdrubrica        => pCdRubBaseIRRF);
                                                                                                       
      ELSE                           
       
       XTMPAG_GERAL.PAtualizaTotalizadoras(pFolha.CdFolhaPagamento,pCdVinculo);
       
       XTMPAG_VAR.vgValorBaseIRRF := XTMPAG_VAR.vgVlTotalProventos;
       
      END IF;    
      
     
      IF XTMPAG_VAR.vgValorBaseIRRF > 0 THEN
        
       XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdExpressaoFormCalc  => NULL,
                                             pCdRubricaAgrupamento => pCdRubAgrupDescIRRF,
                                             pNuSufixoRubrica      => 1,
                                             pVlPagamento          => vAliquotaIRRF.lFaixa(1).vlAliquota*XTMPAG_VAR.vgValorBaseIRRF/100,
                                             pVlIndice             => vAliquotaIRRF.lFaixa(1).vlAliquota,
                                             pCdTipoOrigemRubrica  => 10);
      END IF;
    END IF;

    XTMPAG_GERAL.PLogProcFim('4-4-1-2-3.Processa Trib IRRF');

  END;

  /*-----------------------------------------------------------------------------------------/
    Procedure  : PCalculaIPREV

      Objetivo : Realizar o calculo de contribuicao do IPESC/IPREV

  /-----------------------------------------------------------------------------------------*/
  PROCEDURE PCalculaIPREV(pFolha                      IN XTMPAG_TIPO.rFolha,
                          pCdPessoa                   IN INTEGER,
                          pCdVinculo                  IN INTEGER,
                          pCdRubAgrupDescIPESC        IN INTEGER,
                          pCdRubAgrupDescIPESC2008    IN INTEGER,
                          pCdRubAgrupDifDesc          IN INTEGER,
                          pCdRubAgrupDifDesc2008      IN INTEGER,
                          pCdRubAgrupDevDesc          IN INTEGER,
                          pCdRubAgrupDevDesc2008      IN INTEGER,
                          pCdRubBaseIPESC             IN INTEGER,
                          pVlIPESC                    OUT NUMBER,
                          pbPrima                     IN BOOLEAN DEFAULT FALSE,
                          pCdrubagrupdesciprevliminar IN INTEGER,
                          pCdRubAgrupDescSCFuturo13   IN INTEGER,
                          pCdRubAgrupDifSCFuturo13    IN INTEGER,
                          pCdRubAgrupDevSCFuturo13    IN INTEGER,
                          pPossuiLiminarCPSMpIPREV    IN INTEGER) IS

    vvlContribuicao       NUMBER(15, 4);
    vvlDescRubIsentaIPREV NUMBER(15, 4);
    vvlBase               NUMBER(15, 4);
    vCdIsencaoParteContr  INTEGER;
    --vCdRubrica               INTEGER;
    vvlTetoGovernador NUMBER(15, 4);
    --vIndice                  INTEGER;
    vAliquotaINSS       XTMPAG_TIPO.rAliquotaINSS;
    vNuDiasApo          INTEGER;
    vCont               INTEGER;
    vCdRubricaIPREV     integer;
    vVlBaseIprevEfetivo XTMPAG_tipo.rValorPagamento;
    vAliqIPESCRescisao  XTMPAG_TIPO.rAliquotaIPESC;
    vIgnoraFinanceiro   boolean := false;
    vCdRubAgrupDescIPESC Epagrubricaagrupamento.Cdrubricaagrupamento%TYPE;

    CURSOR cBase(pCdTipoCalculo            IN INTEGER,
                 pCdSituacaoPrevidenciaria IN INTEGER,
                 pCdRubAgrupDescIPESC      IN INTEGER,
                 pCdRubAgrupDescIPESC2008  IN INTEGER,
                 pCdRubAgrupDifDesc        IN INTEGER,
                 pCdRubAgrupDifDesc2008    IN INTEGER,
                 pCdRubAgrupDevDesc        IN INTEGER,
                 pCdRubAgrupDevDesc2008    IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (B.VlBase - vvlDescRubIsentaIPREV) AS vlBase,
             B.VlDeduzido,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT cdPessoa,
                     SUM(vlBase) AS VlBase,
                     SUM(vlDeduzido) AS vlDeduzido
                FROM (SELECT CdPessoa,
                             CASE
                               WHEN CdRubricaAgrupamento = pCdRubBaseIPESC THEN
                                nvl(vlPago, 0)
                             END AS vlBase,
                             CASE
                               WHEN CdRubricaAgrupamento IN
                                    (pCdRubAgrupDescIPESC,
                                     pCdRubAgrupDifDesc,
                                     pCdRubAgrupDescIPESC2008,
                                     pCdRubAgrupDifDesc2008) THEN
                                nvl(vlPago, 0)
                               WHEN CdRubricaAgrupamento IN
                                    (pCdRubAgrupDevDesc,
                                     pCdRubAgrupDevDesc2008) THEN
                                nvl(vlPago, 0) * -1
                             END AS vlDeduzido
                        FROM (SELECT V.CdPessoa,
                                     RV.CdRubricaAgrupamento,
                                     SUM(RV.vlPagamento) AS vlPago
                                FROM EPagHistoricoRubricaVinculo RV

                               INNER JOIN ECalFolhaTrib FP
                              ---  INNER JOIN ECalFolhaMes FP
                                  ON FP.SGTRIBUTO = XTMPAG_TIPO.cnSgTribIPRV
                                 AND FP.TPMES = XTMPAG_TIPO.cnTpMesTribAtual
                                 AND FP.CdCalculoPai =
                                     XTMPAG_VAR.vgCalculo.CdCalculoPai
                                 AND FP.CdFolhaPagamento = RV.CdFolhaPagamento
                               INNER JOIN ECadVinculo V
                                  ON V.CdVinculo = RV.CdVinculo
                               WHERE V.CdPessoa = pCdPessoa
                                 AND (RV.CdRubricaAgrupamento IN
                                     (pCdRubBaseIPESC,
                                       pCdRubAgrupDescIPESC,
                                       pCdRubAgrupDifDesc,
                                       pCdRubAgrupDevDesc,
                                       pCdRubAgrupDescIPESC2008,
                                       pCdRubAgrupDifDesc2008,
                                       pCdRubAgrupDevDesc2008))
                                 AND -- Desconsiderar a folha normal do orgao quando fazendo recalculo
                                     (NOT
                                      (pFolha.CdTipoCalculo in
                                      (XTMPAG_TIPO.cnTpCalculoRecalculoMes) -- Fazendo Recalculo
                                      AND
                                      ((RV.CdVinculo = pCdVinculo AND
                                      (FP.CdFolhaPagamento =
                                      XTMPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                      (FP.CdFolhaPagamento <>
                                      pFolha.CdFolhaPagamento AND
                                      FP.CdTipoCalculo in
                                      (XTMPAG_TIPO.cnTpCalculoRecalculoMes)))) OR
                                      (RV.CdVinculo <> pCdVinculo AND
                                      FP.CdTipoCalculo in
                                      (XTMPAG_TIPO.cnTpCalculoRecalculoMes)))))

                                 AND (NOT (pFolha.CdTipoCalculo =
                                      XTMPAG_TIPO.cnTpCalculoDifMes AND
                                      XTMPAG_VAR.vgFaseCalculo =
                                      XTMPAG_TIPO.cnFaseCalculoIntegral AND
                                      ((RV.CdVinculo = pCdVinculo AND
                                      (FP.CdFolhaPagamento =
                                      XTMPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                      (FP.CdFolhaPagamento <>
                                      pFolha.CdFolhaPagamento AND
                                      FP.CdTipoCalculo =
                                      XTMPAG_TIPO.cnTpCalculoDifMes))) OR
                                      (RV.CdVinculo <> pCdVinculo AND
                                      FP.CdTipoCalculo =
                                      XTMPAG_TIPO.cnTpCalculoDifMes))))

                                 AND
                                    /*    (FP.CdFolhaPagamentoNormal <> XTMPAG_VAR.vgVinculo.CdFolhaPagamentoNormal OR
                                    FP.CdFolhaPagamentoEspec = pFolha.CdFolhaPagamento) AND */
                                     NOT EXISTS
                               (SELECT 1
                                        FROM ETrbRecolhimentoAvulso T
                                       WHERE T.CdPessoa = V.CdPessoa
                                         AND T.CdObjetoRecolhimento = 2
                                         AND T.FlAnulado = XTMPAG_TIPO.cnN
                                         AND ((T.NuAnoInicio <
                                             pFolha.NuAnoReferencia OR
                                             (T.NuAnoInicio =
                                             pFolha.NuAnoReferencia AND
                                             T.NuMesInicio <=
                                             pFolha.NuMesReferencia)) AND
                                             (T.nuAnoFim >
                                             pFolha.NuAnoReferencia OR
                                             (T.nuAnoFim =
                                             pFolha.NuAnoReferencia AND
                                             T.nuMesFim >=
                                             pFolha.NuMesReferencia) OR
                                             T.nuAnoFim IS NULL)))
                               GROUP BY V.CdPessoa, RV.CdRubricaAgrupamento))
               GROUP BY CdPessoa) B
       INNER JOIN ecadVinculo V
          ON V.CdPessoa = B.CdPessoa
       WHERE V.CdVinculo = pCdVinculo;

    CURSOR cBaseAliqUnica(pCdSituacaoPrevidenciaria IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (A.VlBase - vvlDescRubIsentaIPREV) AS VlBase,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT RV.CdVinculo, SUM(RV.vlPagamento) AS vlBase
                FROM Epaghistoricorubricavinculo RV
               WHERE RV.CdRubricaAgrupamento = pCdRubBaseIPESC
                 AND RV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND RV.cdVinculo = pCdVinculo
               GROUP BY RV.CdVinculo) A
       INNER JOIN ECadVinculo V
          ON V.CdVinculo = A.CdVinculo
       WHERE V.CdVinculo = pCdVinculo
         AND NOT EXISTS
       (SELECT 1
                FROM ETrbIsencaoParteContribuicao IC
               INNER JOIN Etrbhistisencaopartecontrib HIC
                  ON IC.Cdisencaopartecontribuicao =
                     HIC.Cdisencaopartecontribuicao
               WHERE V.CdVinculo = IC.Cdvinculo
                 AND HIC.Flanulado = XTMPAG_TIPO.cnN
                 AND ((HIC.nuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                     (HIC.nuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                     HIC.nuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
                     (HIC.nuAnoFimVigencia > pFolha.NuAnoReferencia OR
                     (HIC.nuAnoFimVigencia = pFolha.NuAnoReferencia AND
                     HIC.nuMesFimVigencia > pFolha.NuMesReferencia) OR
                     HIC.nuAnoFimVigencia IS NULL)));

    -- A verificação da isenção é feita antes. Por conta da forma de trabalho adotada
    -- o servidor pode ter isenção parcial desde que tenha decisão judicial de tributação e bloqueio 
    -- na rubrica 05-0924
    CURSOR cBaseAliqUnicaIsencao(pCdSituacaoPrevidenciaria IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (A.VlBase - vvlDescRubIsentaIPREV) AS VlBase,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT RV.CdVinculo, SUM(RV.vlPagamento) AS vlBase
                FROM EPagHistoricoRubricaVinculo RV
               WHERE RV.Cdrubricaagrupamento = pCdRubBaseIPESC
                 AND RV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND RV.cdVinculo = pCdVinculo
               GROUP BY RV.CdVinculo) A
       INNER JOIN ECadVinculo V
          ON V.CdVinculo = A.CdVinculo
     /*  INNER JOIN ETrbIsencaoParteContribuicao IC
          ON V.CdVinculo = IC.Cdvinculo
       INNER JOIN Etrbhistisencaopartecontrib HIC
          ON IC.Cdisencaopartecontribuicao = HIC.Cdisencaopartecontribuicao
         AND HIC.FlAnulado = XTMPAG_TIPO.cnN
         AND ((HIC.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
             (HIC.NuAnoInicioVigencia = pFolha.NuAnoReferencia AND
             HIC.NuMesInicioVigencia <= pFolha.NuMesReferencia)) AND
             (HIC.NuAnoFimVigencia > pFolha.NuAnoReferencia OR
             (HIC.NuAnoFimVigencia = pFolha.NuAnoReferencia AND
             HIC.NuMesFimVigencia >= pFolha.NuMesReferencia) OR
             HIC.NuAnoFimVigencia IS NULL))*/
       WHERE V.CdVinculo = pCdVinculo
         AND V.CdSituacaoPrevidenciaria = case
               when XTMPAG_VAR.vgFolha.CdTipoFolha =
                    XTMPAG_TIPO.cnTpFolhaFunebre then
                v.Cdsituacaoprevidenciaria
               else
                pCdSituacaoPrevidenciaria
             end
         AND ROWNUM < 2;

    CURSOR cBasePNPDecJudRem(pCdSituacaoPrevidenciaria IN INTEGER) IS
      SELECT V.CdVinculo,
             V.DtAdmissao,
             V.CdTipoRegimeProprioPrev,
             (A.VlBase - vvlDescRubIsentaIPREV) AS VlBase,
             V.CdSituacaoPrevidenciaria
        FROM (SELECT RV.CdVinculo, SUM(RV.vlPagamento) AS vlBase
                FROM EPagHistoricoRubricaVinculo RV
               WHERE RV.Cdrubricaagrupamento = pCdRubBaseIPESC
                 AND RV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND RV.cdVinculo = pCdVinculo
               GROUP BY RV.CdVinculo) A
       INNER JOIN ECadVinculo V
          ON V.CdVinculo = A.CdVinculo
       WHERE V.CdVinculo = pCdVinculo
         AND V.CdSituacaoPrevidenciaria = pCdSituacaoPrevidenciaria
         AND ROWNUM < 2;

    PROCEDURE PReGeraBasesIPREV(pCdTipoRegimeProprioPrev INTEGER) IS

      --vCdEstruturaCarreira     INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria NOT IN
         (XTMPAG_TIPO.cnSitPrevAposentado, XTMPAG_TIPO.cnSitPrevPensaoPrev) AND
         pbPrima THEN

        IF pCdTipoRegimeProprioPrev in (1, 3) THEN

          BEGIN

            SELECT 1
              INTO vCont
              FROM EPagHistoricoRubricaVinculo HRV
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseIPREVFF
               AND ROWNUM < 2;

          EXCEPTION

            WHEN NO_DATA_FOUND THEN

              XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIPREVFF,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 1);

          END;

          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseProv13PatFF, --321
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

        ELSIF pCdTipoRegimeProprioPrev = 4 THEN

          BEGIN

            SELECT 1
              INTO vCont
              FROM EPagHistoricoRubricaVinculo HRV
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseIPREVFT
               AND ROWNUM < 2;

          EXCEPTION

            WHEN NO_DATA_FOUND THEN

              XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => XTMPAG_var.vgCdRubBaseIPREVFT,
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 1);

              XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => XTMPAG_var.vgCdRubBaseProv13FT, --341
                                                    pNuSufixoRubrica      => 1,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => NULL,
                                                    pCdTipoOrigemRubrica  => 1);
          END;

        ELSE

          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIPREVFP,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseProv13PatFP, --79
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => NULL,
                                                pCdTipoOrigemRubrica  => 1);

        END IF;

      END IF;

    END;

    PROCEDURE PAtualizaBaseIPESC(pvlBase    IN NUMBER,
                                 pbCCO      IN BOOLEAN DEFAULT FALSE,
                                 pbAtualiza IN BOOLEAN DEFAULT FALSE) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF vvlDescRubIsentaIPREV > 0 OR pbCCO or pbAtualiza THEN

        UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.Vlpagamento = pvlBase
         WHERE HRV.CdVinculo = pCdVinculo
           AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento = pCdRubBaseIPESC;

        IF pbCCO THEN

          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.Vlpagamento = 0
           WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdRubricaAgrupamento =
                 XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                              9,
                                              932);

        END IF;

        if pbAtualiza then

          UPDATE EPagHistoricoRubricaRelVinc HRVI
             SET HRVI.Vlproporcional = pvlBase,
                 HRVI.VlReal         = pvlBase,
                 HRVI.Dtinicio       = XTMPAG_var.vgRelVinc(1).DtInicio,
                 HRVI.Dtfim          = XTMPAG_var.vgRelVinc(1).DtFim
           WHERE HRVI.CdVinculo = pCdVinculo
             AND HRVI.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRVI.CdRubricaAgrupamento = pCdRubBaseIPESC;

        end if;

      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                XTMPAG_VAR.vCdHistParamCalc,
                                XTMPAG_VAR.vCdPessoa,
                                'XTMPAG_TRIBUTACAO.PAtualizaBaseIPESC',
                                XTMPAG_VAR.vgCdVinculo);

    END;

    PROCEDURE PAtualizaValorIPESC(pvlContribuicao IN NUMBER,
                                  pCdRubricaIpesc INTEGER) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.Vlpagamento = pvlContribuicao
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;

    EXCEPTION
      WHEN OTHERS THEN
        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                XTMPAG_VAR.vCdHistParamCalc,
                                XTMPAG_VAR.vCdPessoa,
                                'XTMPAG_TRIBUTACAO.PAtualizaValorIPESC',
                                XTMPAG_VAR.vgCdVinculo);

    END;

    PROCEDURE PAtualizaValorCPSM(pFolha          IN XTMPAG_TIPO.rFolha,
                                 pCdVinculo      IN INTEGER,
                                 pvlContribuicao IN NUMBER,
                                 pCdRubricaIpesc IN INTEGER,
                                 pCdRubricaCPSM  IN INTEGER) IS

      vCdExpressaoFormCalc integer;
      vValorContribCPSM    number;
      vPossuiLFRubricaCPSM boolean;
      vVlIprevProp         number := 0;
      vVlCPSMProp          number := 0;
      vVlBase              number := 0;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vPossuiLFRubricacpsm := XTMPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                                                 pFolha,
                                                                 pCdRubricacpsm);

      IF NOT vPossuiLFRubricacpsm THEN

        vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                       pCdRubricaAgrupamento => pCdRubricacpsm,
                                                                       pCdRelacaoVinculo     => 0);
        IF vCdExpressaoFormCalc <> 0 THEN
          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                pCdVinculo            => XTMPAG_var.vgVinculo.CdVinculo,
                                                pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                pCdRubricaAgrupamento => pCdRubricacpsm,
                                                pNuSufixoRubrica      => 1,
                                                pVlPagamento          => 0,
                                                pVlIndice             => null,
                                                pCdTipoOrigemRubrica  => 10);

          XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                           pCdVinculo       => XTMPAG_var.vgVinculo.CdVinculo,
                                           pCdRubrica       => pCdRubricacpsm,
                                           pTpProcessamento => 1,
                                           pTpLocal         => 2);

        END IF;

        vValorContribcpsm := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                               pcdvinculo        => XTMPAG_var.vgVinculo.CdVinculo,
                                                               pcdrubrica        => pCdRubricacpsm,
                                                               pnusufixo         => 1);

        vVlBase := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                     pcdvinculo        => XTMPAG_var.vgVinculo.CdVinculo,
                                                     pcdrubrica        => XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                                                       9,
                                                                                                       916));

        if vValorContribcpsm > pvlContribuicao THEN

          if pFolha.NuAnoReferencia = 2020 and pFolha.NuMesReferencia = 3 then

            vVlIprevProp := trunc(pVlContribuicao / 30 * 16, 2);

            vVlCPSMProp := vVlIprevProp;

            vValorContribCPSM := vValorContribCPSM / 30 * 14;

          else

            vValorContribcpsm := trunc(pVlContribuicao, 2);

          end if;

        end if;

      end if;

      if vVlCPSMProp > 0 then

        XTMPAG_geral.pinserelancamentovinculo(pcdfolhapagamento     => pFolha.CdFolhaPagamento,
                                              pcdvinculo            => XTMPAG_var.vgVinculo.CdVinculo,
                                              pcdexpressaoformcalc  => null,
                                              pcdrubricaagrupamento => pCdRubricacpsm,
                                              pnusufixorubrica      => 2,
                                              pvlpagamento          => vValorContribCPSM,
                                              pcdtipoorigemrubrica  => 10,
                                              pDeExpressao          => vVlBase ||
                                                                       '* 0.095 / 30 * 14');

      else

        vVlCPSMProp := vValorContribCPSM;

      end if;

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.Vlpagamento = 0
       WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;

      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET HRV.Vlintegral = 0, HRV.VlReal = 0, HRV.Vlproporcional = 0
       WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET HRV.Vlpagamento = vVlCPSMProp
       WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdRubricacpsm
         AND HRV.Nusufixorubrica = 1;

      -- Trocar codigo da base

      DELETE EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento =
             XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                          9,
                                          9916)
         AND HRV.Nusufixorubrica = 1;

      DELETE EPagHistoricoRubricaRelVinc HRV
       WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento =
             XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                          9,
                                          9916)
         AND HRV.Nusufixorubrica = 1;

      UPDATE EPagHistoricoRubricaVinculo HRV
         SET hrv.cdrubricaagrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                     9,
                                                                     9916)
       WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento =
             XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                          9,
                                          916);

      UPDATE EPagHistoricoRubricaRelVinc HRV
         SET hrv.cdrubricaagrupamento = XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                     9,
                                                                     9916)
       WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
         AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento =
             XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                          9,
                                          916);

    EXCEPTION

      WHEN OTHERS THEN
        null;
    END;

    FUNCTION FCalculaIPESC

     RETURN BOOLEAN IS

      vCont INTEGER;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF XTMPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = XTMPAG_TIPO.cnRelResidente THEN

        RETURN FALSE;

      /*ELSE

        SELECT COUNT(*)
          INTO vCont
          FROM ECadVinculo V
         WHERE V.CdVinculo = pCdVinculo
           AND V.CdRegimePrevidenciario in
               (XTMPAG_TIPO.cnRegPrevProprio, XTMPAG_tipo.cnRegPrevCPSM);

        IF vCont > 0 THEN

          RETURN TRUE;

        ELSE

          RETURN FALSE;

        END IF;*/

      END IF;
      
      RETURN TRUE;

    END;

    FUNCTION FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev IN INTEGER,
                                      pcdRubrica1              IN INTEGER,
                                      pcdRubrica2              IN INTEGER,
                                      pcdRubricaDescSCFuturo13 IN INTEGER) RETURN INTEGER IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      IF pCdTipoRegimeProprioPrev = 1 THEN

        RETURN pcdRubrica1;

      ELSIF pCdTipoRegimeProprioPrev = 4 AND pcdRubricaDescSCFuturo13 IS NOT NULL THEN
        
        RETURN pcdRubricaDescSCFuturo13;
        
      ELSE

        RETURN pcdRubrica2;

      END IF;

    END;

    FUNCTION FRubricaGerada(pCdTipoCalculo           IN INTEGER,
                            pCdTipoRegimeProprioPrev IN INTEGER,
                            pvlDeduzido              IN NUMBER,
                            pvlContribuicao          IN NUMBER)
      RETURN INTEGER IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      CASE

        WHEN pvlDeduzido > 0 THEN

          CASE

            WHEN pvlContribuicao > 0 THEN

              CASE

                WHEN XTMPAG_VAR.vgFaseCalculo =
                     XTMPAG_TIPO.cnFaseCalculoIntegral THEN

                  RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                                  pCdRubAgrupDescIPESC,
                                                  pCdRubAgrupDescIPESC2008,
                                                  pCdRubAgrupDescSCFuturo13);

                ELSE

                  RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                                  pCdRubAgrupDifDesc,
                                                  pCdRubAgrupDifDesc2008,
                                                  pCdRubAgrupDifSCFuturo13); --  gera rubrica do tipo 6

              END CASE;

            WHEN pvlContribuicao < 0 THEN

              RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                              pCdRubAgrupDevDesc,
                                              pCdRubAgrupDevDesc2008,
                                              pCdRubAgrupDevSCFuturo13); --  gera rubrica do tipo 4

          END CASE;

        WHEN pvlDeduzido = 0 THEN

          CASE

            WHEN pvlContribuicao > 0 THEN

              RETURN FRetornaRubricaDescIPESC(pCdTipoRegimeProprioPrev,
                                              pCdRubAgrupDescIPESC,
                                              pCdRubAgrupDescIPESC2008,
                                              pCdRubAgrupDescSCFuturo13);

            ELSE

              RETURN 0;

          END CASE;

      END CASE;

    END;

    PROCEDURE InsereRubricaIPESC(pCdVinculo        IN INTEGER,
                                 pCdRubricaGerada  IN INTEGER,
                                 pCdFolhaPagamento IN INTEGER,
                                 pVlRubrica        IN INTEGER,
                                 pNuSufixo         IN INTEGER,
                                 pVlIndice         IN NUMBER) IS

      vvlRubrica NUMBER(15, 4);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vCdRubricaIprev := pCdRubricaGerada;

      IF pCdRubricaGerada IN (pCdRubAgrupDifDesc,
                              pCdRubAgrupDevDesc,
                              pCdRubAgrupDifDesc2008,
                              pCdRubAgrupDevDesc2008) THEN

        vvlRubrica := ABS(pVlRubrica);

      ELSE

        vvlRubrica := pVlRubrica;

      END IF;

      IF pCdRubricaGerada > 0 AND vvlRubrica >= 0.01 THEN

        INSERT INTO EpagHistoricoRubricaVinculo
          (CdHistoricoRubricaVinculo,
           CdFolhaPagamento,
           CdRubricaAgrupamento,
           CdVinculo,
           NuSufixoRubrica,
           CdLancamentoFinanceiro,
           VlPagamento,
           QtParcelas,
           VlIndiceRubrica,
           DtUltAlteracao,
           CdTipoOrigemRubrica,
           CdTipoIndice)
        VALUES
          (Spaghistoricorubricavinculo.NEXTVAL,
           pCdFolhaPagamento,
           pCdRubricaGerada,
           pCdVinculo,
           1,
           NULL,
           TRUNC(vvlRubrica, 2),
           1,
           pvlIndice,
           systimestamp,
           10,
           XTMPAG_VAR.vgRubrica(pCdRubricaGerada).CdTipoIndice);

        pVlIPESC := TRUNC(vvlRubrica, 2);

      ELSE

        pVlIPESC := 0.0;

      END IF;

    END;

    PROCEDURE pAplicaAliquotaIsolada(lFaixa IN XTMPAG_TIPO.tFaixaAliquota) IS

      i                INTEGER;
      vCdRubricaGerada INTEGER;
      vvlBase          NUMBER(15, 4);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      FOR c IN cBaseAliqUnica(pCdSituacaoPrevidenciaria => XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP

        i := 0;

        IF nvl(c.vlBase, 0) > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN

          vvlBase := vvlTetoGovernador;

        ELSE

          vvlBase := c.vlBase;

        END IF;

        WHILE i < (lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN

            PAtualizaBaseIPESC(pvlBase    => vvlBase,
                               pbAtualiza => case
                                               when XTMPAG_var.vgNuDiasApo > 0 then
                                                TRUE
                                               else
                                                FALSE
                                             end);

            vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;

            vvlContribuicao := vvlContribuicao -
                               nvl(lFaixa(i).VlParcelaDeducao, 0);

            IF XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN

              IF XTMPAG_VAR.VGFOLHA.CDORGAO = 33 AND -- sig 7062
                 XTMPAG_geral.fpossuiregistroobito(XTMPAG_var.vCdPessoa,
                                                   XTMPAG_var.vgFolha.cdAgrupamento,
                                                   'S') THEN

                vvlContribuicao := vvlContribuicao *
                                   XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => XTMPAG_VAR.vgVinculo.cdvinculo,
                                                                                 pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                          pFolha.NuMesReferencia,
                                                                                 pFlIntegral           => TRUE) /
                                   XTMPAG_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pCdVinculo,
                                                                                    pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                             pFolha.NuMesReferencia);
              ELSE
                vvlContribuicao := vvlContribuicao *
                                   XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => XTMPAG_VAR.vgVinculo.cdvinculo,
                                                                                 pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                          pFolha.NuMesReferencia) /
                                   XTMPAG_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pCdVinculo,
                                                                                    pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                             pFolha.NuMesReferencia);
              END IF;
              /*              vvlContribuicao *
                                              XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => XTMPAG_VAR.vgVinculo.cdvinculo,
                                                                                            pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                                     pFolha.NuMesReferencia) / 100;
              */
            END IF;

            IF vvlContribuicao = 0 AND vvlBase * lFaixa(i).VlAliquota = 0 THEN
              RETURN;
            END IF;

            IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevCPSM AND pPossuiLiminarCPSMpIPREV = 1 THEN
              
              vCdRubricaGerada := pCdRubAgrupDescIPESC;
              
            ELSE

              vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                 c.CdTipoRegimeProprioPrev,
                                                 0,
                                                 vvlContribuicao);
            END IF;

            -- SIG-7288
            -- SIGRH - [Chamado 16784/2021] - PROPORCIONALIZAR PARA 20 DIAS VALORES DA RUBRICA 05-0924-01 SERVIDORES INATIVOS DO AGPE
            if XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 2 and
               (XTMPAG_var.vgFolha.nuanoreferencia = 2021 and
               XTMPAG_var.vgFolha.numesreferencia = 11) and XTMPAG_var.vgrubrica(vCdRubricaGerada).NuRubrica = 924 and XTMPAG_var.vgrubrica(vCdRubricaGerada).CdTipoRubrica = 5 and
               pFolha.CdAgrupamento in (1, 132, 133) then

              vvlContribuicao := vvlContribuicao / 30 * 20;

            end if;

            InsereRubricaIPESC(c.CdVinculo,
                               vCdRubricaGerada,
                               pFolha.CdFolhaPagamento,
                               vvlContribuicao,
                               1,
                               lFaixa(i).VlAliquota);

            PAjustaIPREV(pFolha => pFolha,
                         pCdVinculo => pCdVinculo,
                         pCdRubricaGerada => vCdRubricaGerada);

            PRegeraBasesIPREV(c.cdtiporegimeproprioprev);

            i := lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      END LOOP;

    END;

    PROCEDURE pAplicaAliquotaIsenPNP(lFaixa IN XTMPAG_TIPO.tFaixaAliquota) IS

      i INTEGER;

      vCdRubricaGerada INTEGER;

      vvlBase NUMBER(15, 4);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      FOR c IN cBasePNPDecJudRem(pCdSituacaoPrevidenciaria => XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP

        i       := 0;
        vvlBase := c.vlBase;

        WHILE i < (lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN

            vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;

            vvlContribuicao := vvlContribuicao -
                               nvl(lFaixa(i).VlParcelaDeducao, 0);

                vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                 c.CdTipoRegimeProprioPrev,
                                                 0,
                                                 vvlContribuicao);

            InsereRubricaIPESC(c.CdVinculo,
                               vCdRubricaGerada,
                               pFolha.CdFolhaPagamento,
                               vvlContribuicao,
                               1,
                               lFaixa(i).VlAliquota);

            PRegeraBasesIPREV(c.cdtiporegimeproprioprev);

            i := lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      END LOOP;

    END;

    PROCEDURE pAplicaAliquotaIsoladaIsen(lFaixa IN XTMPAG_TIPO.tFaixaAliquota) IS

      i INTEGER;

      vCdRubricaGerada INTEGER;

      vvlBase NUMBER(15, 4);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      FOR c IN cBaseAliqUnicaIsencao(pCdSituacaoPrevidenciaria => XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP

        i := 0;

        IF c.vlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN

          vvlBase := vvlTetoGovernador;

        ELSE

          vvlBase := c.vlBase;

        END IF;

        WHILE i < (lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN

            PAtualizaBaseIPESC(pvlBase    => vvlBase,
                               pbAtualiza => case
                                               when XTMPAG_var.vgNuDiasApo > 0 then
                                                TRUE
                                               else
                                                FALSE
                                             end);

            vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;

            vvlContribuicao := vvlContribuicao -
                               nvl(lFaixa(i).VlParcelaDeducao, 0);

            IF XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
              vvlContribuicao := vvlContribuicao * XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(
                                                 pCdVinculoPensionista => XTMPAG_VAR.vgVinculo.cdvinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia)
                                                  /
                                                 XTMPAG_pensaoprevidenciaria.fVlPercIntegralidade(
                                                 pCdVinculoPensionista => pCdVinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia);
              /*

                            vvlContribuicao *
                                               XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => pCdVinculo,
                                                                                             pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                                      pFolha.NuMesReferencia) / 100;
              */
            END IF;

              vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                                 c.CdTipoRegimeProprioPrev,
                                                 0,
                                                 vvlContribuicao);

            InsereRubricaIPESC(c.CdVinculo,
                               vCdRubricaGerada,
                               pFolha.CdFolhaPagamento,
                               vvlContribuicao,
                               1,
                               lFaixa(i).VlAliquota);

            PAjustaIPREV(pFolha => pFolha,
                         pCdVinculo => pCdVinculo,
                         pCdRubricaGerada => vCdRubricaGerada);

            PRegeraBasesIPREV(c.cdtiporegimeproprioprev);

            i := lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      END LOOP;

    END;

    PROCEDURE PAplicaAliquotaApoMesAnt IS

      i INTEGER;

      vCdRubricaGerada INTEGER := XTMPAG_GERAL.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                               5,
                                                               924); -- 05-0924;

      vvlBase NUMBER(15, 4);

      vVlBaseRealAnt XTMPAG_tipo.rvalorpagamento;

      lFaixa XTMPAG_TIPO.tFaixaAliquota := XTMPAG_VAR.vAliqIPESCInativo.lFaixa;

      vCdBaseCalculo INTEGER;

      --vVlBloqueio             NUMBER(15,4);

      vNuDias INTEGER := 0;

      vNuDiasPropApo INTEGER := 0;

      --vVlIndice               number(10,4);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      -- Se data da aposentadoria NAO foi no mes anterior, entao nao gera aliquota
      IF NOT (XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 2 AND
          XTMPAG_VAR.vgApo.count > 0 AND XTMPAG_VAR.vgApo(1)
          .DtInicioRelacao > trunc(XTMPAG_VAR.vgFolha.DtCalculoAnt, 'mm') AND XTMPAG_VAR.vgApo(1)
          .DtInicioRelacao < XTMPAG_VAR.vgFolha.dtInicioMes) THEN

        RETURN;

      END IF;

      XTMPAG_param.PArmazenaInfoFolhaNormalAnt(XTMPAG_VAR.vgFolha.cdFolhaPagamentoNormalAnt);

      --
      -- Para retroativos que possuem processos de compensacao associados
      --

      vCdBaseCalculo := XTMPAG_var.vgrubrica(XTMPAG_GERAL.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento, 9, 916)).cdbasecalculo;

      vVlBaseRealAnt := XTMPAG_fb.fretornavalorbasecalculo(pFolha            => XTMPAG_var.vgFolhaNormalAnt,
                                                           pCdVinculo        => pcdvinculo,
                                                           pCdTipoHistorico  => 2,
                                                           pCdRelacaoVinculo => 0,
                                                           pCdBaseCalculo    => vcdbasecalculo,
                                                           pCdChave          => pcdvinculo,
                                                           pCdFolhaAnt       => XTMPAG_VAR.vgFolha.cdFolhaPagamentoNormalAnt);

      select hrv.vlproporcional as vlBase, (hrv.dtfim - hrv.dtinicio + 1)
        into vvlBase, vNuDias
        from epaghistoricorubricarelvinc hrv
       where hrv.cdfolhapagamento =
             XTMPAG_VAR.vgFolha.cdFolhaPagamentoNormalAnt -- FOLHA MES APOSENTADORIA
         and hrv.cdrubricaagrupamento =
             XTMPAG_GERAL.fretornarubrica(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                          9,
                                          916) -- 09-0916-01 BASE CAL-IPREV
         and hrv.cdvinculo = pCdVinculo
         and hrv.cdhistcargoefetivo is not null;

      if vVlBaseRealAnt.vlProporcional > vvlTetoGovernador AND
         vvlTetoGovernador > 0 then
        vvlBaseRealAnt.vlProporcional := vvlTetoGovernador;

        vVlBase := vVlBaseRealAnt.VlProporcional / 30 * vNuDias;

      else

        vVlBase := vVlBaseRealAnt.vlProporcional - vVlBase;

        IF vvlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN

          vvlBase := vvlTetoGovernador;

        END IF;

        ---------------------
      end if;

      i := 0;

      if vCdIsencaoParteContr is not null then

        lFaixa := XTMPAG_VAR.vAliqIPESCParcial.lFaixa;

      end if;

      vNuDiasPropApo := 30 - nvl(vNuDias, 0);

      WHILE i < (lFaixa.COUNT)

       LOOP

        i := i + 1;

        IF vvlBase BETWEEN case when lFaixa(i).vlInicial > 0
         then(lFaixa(i).vlInicial / 30 * vNuDiasPropApo) else lFaixa(i).vlInicial
         end AND case when lFaixa(i).vlFinal < 9999999
         then(lFaixa(i).vlFinal / 30 * vNuDiasPropApo) else lFaixa(i).vlFinal end then

          vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;

          vvlContribuicao := vvlContribuicao -
                             (nvl(lFaixa(i).VlParcelaDeducao, 0) / 30 *
                             vNuDiasPropApo);

          IF vvlContribuicao >= 0.01 THEN

            INSERT INTO EpagHistoricoRubricaVinculo
              (CdHistoricoRubricaVinculo,
               CdFolhaPagamento,
               CdRubricaAgrupamento,
               CdVinculo,
               NuSufixoRubrica,
               CdLancamentoFinanceiro,
               VlPagamento,
               QtParcelas,
               VlIndiceRubrica,
               DtUltAlteracao,
               CdTipoOrigemRubrica,
               CdTipoIndice)
            VALUES
              (Spaghistoricorubricavinculo.NEXTVAL,
               XTMPAG_VAR.vgFolha.cdfolhapagamento,
               vCdRubricaGerada,
               pCdVinculo,
               2,
               NULL,
               TRUNC(vvlContribuicao, 2),
               1,
               lFaixa(i).VlAliquota,
               systimestamp,
               10,
               XTMPAG_VAR.vgRubrica(vCdRubricaGerada).CdTipoIndice);

          END IF;

          exit;

        END IF;
        ---------------------

      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;

    END;

    PROCEDURE pAplicaAliquota(lFaixa IN XTMPAG_TIPO.tFaixaAliquota) IS

      i INTEGER;

      vCdRubricaGerada INTEGER;

      vvlBase NUMBER(15, 4);

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      FOR c IN cBase(pFolha.CdTipoCalculo,
                     XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria,
                     pCdRubAgrupDescIPESC,
                     pCdRubAgrupDescIPESC2008,
                     pCdRubAgrupDifDesc,
                     pCdRubAgrupDifDesc2008,
                     pCdRubAgrupDevDesc,
                     pCdRubAgrupDevDesc2008) LOOP

        i := 0;

        IF c.vlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN

          vvlBase := vvlTetoGovernador;

        ELSE

          vvlBase := c.vlBase;

        END IF;

        WHILE i < (lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF vvlBase BETWEEN lFaixa(i).vlInicial AND lFaixa(i).vlFinal THEN

            PAtualizaBaseIPESC(pvlBase    => vvlBase,
                               pbAtualiza => case
                                               when XTMPAG_var.vgNuDiasApo > 0 then
                                                TRUE
                                               else
                                                FALSE
                                             end);

            vvlContribuicao := vvlBase * lFaixa(i).VlAliquota / 100;

            vvlContribuicao := vvlContribuicao -
                               nvl(lFaixa(i).VlParcelaDeducao, 0) -
                               nvl(c.vlDeduzido, 0);

            vCdRubricaGerada := FRubricaGerada(pFolha.CdTipoCalculo,
                                               c.CdTipoRegimeProprioPrev,
                                               nvl(c.vlDeduzido, 0),
                                               vvlContribuicao);

            InsereRubricaIPESC(c.CdVinculo,
                               vCdRubricaGerada,
                               pFolha.CdFolhaPagamento,
                               vvlContribuicao,
                               1,
                               lFaixa(i).VlAliquota);

            PRegeraBasesIPREV(c.cdtiporegimeproprioprev);

            i := lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      END LOOP;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

     if pFolha.CdTipoFolha in (XTMPAG_tipo.cnTpFolhaProdex13, XTMPAG_tipo.cnTpFolhaHonorarios13, XTMPAG_tipo.cnTpFolhaHonorarProcuradores13)
       or pFolha.CdTipoFolhaPagamento in (1526, 1505, 1525)
       then
      return;
    end if;

    ------------------------------------------------------------------------------------------------------
    -- Calcula o IPESC
    ------------------------------------------------------------------------------------------------------

    XTMPAG_GERAL.PLogProcIni('4-4-1-2-2.Processa Trib IPRV');

    IF FCalculaIPESC OR
       (XTMPAG_var.vgPensaoNaoPrev.count > 0 AND XTMPAG_var.vgPensaoNaoPrev(1).CdTipoPensaoNaoPrev = 83) THEN

      -- Exclui bases de INSS

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSS,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubVlINSSPatronalBruto,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSS13,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseFGTS,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseFGTS13,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubVlFGTS,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                  pCdVinculo        => pCdVinculo,
                                  pCdRubrica        => XTMPAG_VAR.vgCdRubVlFGTS13,
                                  pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => nvl(XTMPAG_VAR.vgCdRubBaseCPSM,
                                                                 XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                              9,
                                                                                              9916)),
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => nvl(XTMPAG_VAR.vgCdRubBaseCPSM13,
                                                                 XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                              9,
                                                                                              9920)),
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');

      IF XTMPAG_GERAL.FGeraRubrica(XTMPAG_VAR.vgCdRubDescTetoGovernador) THEN

        vvlTetoGovernador := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                               pCdVinculo,
                                                               XTMPAG_VAR.vgCdRubricaTetoGov);

        vNuDiasApo := 0;

        IF XTMPAG_VAR.vgApo.count > 0 AND XTMPAG_VAR.vgApo(1)
          .DtInicioRelacao > PFolha.DtInicioMes AND XTMPAG_VAR.vgApo(1)
          .DtInicioRelacao < PFolha.DtFimMes then

          if XTMPAG_VAR.vgApo(1).DtFimRelacao is null then

            vNuDiasApo := 30 -
                          to_char(XTMPAG_VAR.vgApo(1).DtInicioRelacao, 'dd') + 1;

          else

            vNuDiasApo := nvl(XTMPAG_VAR.vgApo(1).DtFimRelacao,
                              pFolha.DtFimMes) - XTMPAG_VAR.vgApo(1).DtInicioRelacao + 1;

          end if;

          if XTMPAG_var.vgNuDiasApo < 30 then

            vvlTetoGovernador := vvlTetoGovernador / 30 *
                                 (30 - XTMPAG_var.vgNuDiasApo);

          end if;
        END IF;

      ELSE

        vvlTetoGovernador := 0;

      END IF;
      ----------------------------------------------------------------------------------------------------------

      vvlDescRubIsentaIPREV := 0;

      IF bDescRubIsentaIPREV THEN

        vvlDescRubIsentaIPREV := NVL(FRetornaValorRubIsentas(pCdVinculo      => pCdVinculo,
                                                             pFolha          => pFolha,
                                                             pCdTipoDesconto => 3),0);
      END IF;

     
      IF (XTMPAG_GERAL.FGeraRubrica(pRubrica => pCdRubAgrupDescIPESC) AND
          XTMPAG_GERAL.FGeraRubrica(pRubrica => pCdRubAgrupDescIPESC2008) AND 
          NOT XTMPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pCdRubAgrupDescIPESC, pNuSufixoRubrica => 1) AND 
          NOT XTMPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => pCdRubAgrupDescIPESC2008, pNuSufixoRubrica => 1))  THEN

        IF bIsencaoPercialIPREV THEN
          
          vCdIsencaoParteContr := 1;
          
        ELSE
            
          BEGIN

            SELECT IC.CdIsencaoParteContribuicao
              INTO vCdIsencaoParteContr
              FROM (SELECT IC.CdVinculo, IC.CdIsencaoParteContribuicao
                      FROM EtrbIsencaoParteContribuicao IC
                     INNER JOIN Etrbhistisencaopartecontrib HIC
                        ON IC.Cdisencaopartecontribuicao =
                           HIC.Cdisencaopartecontribuicao
                       AND HIC.FlAnulado = XTMPAG_TIPO.cnN
                       AND ((HIC.nuAnoInicioVigencia < pFolha.NuAnoReferencia OR
                           (HIC.nuAnoInicioVigencia = pFolha.NuAnoReferencia AND
                           HIC.nuMesInicioVigencia <=
                           pFolha.NuMesReferencia)) AND
                           (HIC.nuAnoFimVigencia > pFolha.NuAnoReferencia OR
                           (HIC.nuAnoFimVigencia = pFolha.NuAnoReferencia AND
                           HIC.nuMesFimVigencia > pFolha.NuMesReferencia) OR
                           HIC.nuAnoFimVigencia IS NULL))) IC
             WHERE IC.CdVinculo = pCdVinculo
               AND ROWNUM < 2;

          EXCEPTION

            WHEN NO_DATA_FOUND THEN

              vCdIsencaoParteContr := NULL;

          END;
        
        END IF;

        ----------------------------------------------------------------------------------------------------------
        -- TRIBUTA APOSENTADORIA MES ANTERIOR
        ----------------------------------------------------------------------------------------------------------
        PAplicaAliquotaApoMesAnt;
        ----------------------------------------------------------------------------------------------------------

        -- SIG-4924
        -- SIG-4746 DPE - Folha de setembro - comissionados
        if XTMPAG_var.vgVlIntegralIPREV > 0 and
           XTMPAG_var.vgVlIntegralIPREV <> XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                                             XTMPAG_VAR.vgVinculo.CdVinculo,
                                                                             XTMPAG_var.vgCdRubBaseIPESC) and
           pFolha.CdOrgao = 443 and 
           XTMPAG_var.vgCef.Count > 0 then

          -- Retorna valor da base da relacao de efetivo
          vVlBaseIprevEfetivo := XTMPAG_fb.fretornavalorbasecalculo(pFolha,
                                                                    XTMPAG_VAR.vgVinculo.CdVinculo,
                                                                    1,
                                                                    1,
                                                                    XTMPAG_var.vgRubrica(XTMPAG_var.vgCdRubBaseIPESC).cdbasecalculo,
                                                                    XTMPAG_var.vgCef(1).cdhistcargoefetivo);
          -- Se contem valor na base, excluir os demais das outras relacoes

          if nvl(vVlBaseIprevEfetivo.vlIntegral, 0) > 0 then

            begin

              delete epaghistoricorubricarelvinc rv
               where rv.cdvinculo = XTMPAG_VAR.vgVinculo.CdVinculo
                 and rv.cdfolhapagamento = pFolha.CdFolhaPagamento
                 and rv.cdrubricaagrupamento = XTMPAG_var.vgCdRubBaseIPESC
                 and rv.cdhistcargoefetivo is null;

            exception
              when others then
                null;
            end;

            PAtualizaBaseIPESC(pVlBase    => vVlBaseIprevEfetivo.vlIntegral,
                               pbCCO      => false,
                               pbAtualiza => true);
          end if;

        end if;

        CASE

          WHEN XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 1
              --
              --  Solicitacao de Sustentacao #71742
              --  9142/2016 - FOLHA - - NAO ESTA CALCULANDO IPREV QUANDO VOLTA DE APOSENTADORIA NO MES.
              --
               OR (XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 2 AND
               NVL(XTMPAG_VAR.vgCdSitPrevidenciariaAtual, 0) = 1)
              --
              --  Solicitacao de Sustentacao 15720/2021
              --  base 09-0920 – Base IPREV 13
              --
               OR (XTMPAG_GERAL.FSituacaoPrevVigente(pCdVinculo   => XTMPAG_VAR.vgVinculo.CdVinculo,
                                                     pDtInicioMes => TRUNC((XTMPAG_VAR.vgFolha.dtcalculoant),
                                                                           'MM'),
                                                     pDtFimMes    => last_day(XTMPAG_VAR.vgFolha.dtcalculoant)) in (1) AND
               XTMPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
               XTMPAG_VAR.vgVinculo.DtDesligamento <
               XTMPAG_VAR.vgFolha.DtInicioMes AND
               NVL(XTMPAG_VAR.vgCdRubricaRecisao13, 0) > 0) THEN

            CASE

              WHEN XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica IS NOT NULL THEN

                FOR c IN cBaseAliqUnica(XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP

                  IF c.vlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN

                    vvlBase := vvlTetoGovernador;

                  ELSE

                    vvlBase := c.vlBase;

                  END IF;

                  PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                     pbAtualiza => case
                                                     when XTMPAG_var.vgNuDiasApo > 0 then
                                                      TRUE
                                                     else
                                                      FALSE
                                                   end);

                  --
                  -- Solicitacao de Sustentacao #68791
                  -- 8554/2016 - FOLHA - - CALCULO DO IPREV (PREVIDENCIA COMPLEMENTAR)
                  --
                  IF NVL(FRetornaRegimeProprioPrev(XTMPAG_VAR.vgVinculo.CdVinculo),
                         0) in (3,4) THEN

                    vAliquotaINSS := FRetornaAliquotaINSS(pFolha.NuAnoReferencia,
                                                          pFolha.NuMesReferencia);

                    IF vVlBase > vAliquotaINSS.vlTeto THEN
                      vVlBase := vAliquotaINSS.vlTeto;
                      IF NVL(vvlDescRubIsentaIPREV, 0) = 0 THEN
                        vvlDescRubIsentaIPREV := 0.01;
                      END IF;
                      --
                      -- Ajustar a base pelo Teto do INSS
                      --
                      PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                         pbAtualiza => CASE
                                                         WHEN XTMPAG_var.vgNuDiasApo > 0 THEN
                                                          TRUE
                                                         ELSE
                                                          FALSE
                                                       END);

                    END IF;

                  END IF;

                  vvlContribuicao := vvlBase *
                                     XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100;

                  vCdRubAgrupDescIPESC := FRetornaRubricaDescIPESC(c.CdTipoRegimeProprioPrev,
                                                                   pCdRubAgrupDescIPESC,
                                                                   pCdRubAgrupDescIPESC2008,
                                                                   pCdRubAgrupDescSCFuturo13);

                  InsereRubricaIPESC(pCdVinculo,
                                     vCdRubAgrupDescIPESC,
                                     pFolha.CdFolhaPagamento,
                                     vvlContribuicao,
                                     1,
                                     XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica);

                  PAjustaIPREV(pFolha => pFolha,
                               pCdVinculo => pCdVinculo,
                               pCdRubricaGerada => vCdRubAgrupDescIPESC);

                  PReGeraBasesIPREV(c.CdTipoRegimeProprioPrev);

                END LOOP;
                --
                -- 8623/2016 - TRIBUTACAO PREVIDENCIARIA SOBRE CARGO COMISSIONADO E FUNCAO GRATIFICADA (IPREV)
                --
                IF XTMPAG_var.bPossuiIprevCCO THEN

                  IF pFolha.CdTipoFolha <> XTMPAG_tipo.cnTpFolha13 THEN

                    IF NVL(XTMPAG_geral.fretornaindicerubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                              XTMPAG_VAR.VGVINCULO.cdvinculo,
                                                              XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                           9,
                                                                                           932)),
                           0) = 0 THEN

                      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                            pCdVinculo            => pCdVinculo,
                                                            pCdExpressaoFormCalc  => NULL,
                                                            pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                  9,
                                                                                                                  932),
                                                            pNuSufixoRubrica      => 1,
                                                            pVlPagamento          => 0,
                                                            pVlIndice             => NULL,
                                                            pCdTipoOrigemRubrica  => 1);
                    END IF;

                    IF NVL(XTMPAG_geral.fretornaindicerubrica(XTMPAG_VAR.vgFolha.CdFolhaPagamento,
                                                              XTMPAG_VAR.VGVINCULO.cdvinculo,
                                                              XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                           9,
                                                                                           962)),
                           0) = 0 THEN

                      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                            pCdVinculo            => pCdVinculo,
                                                            pCdExpressaoFormCalc  => NULL,
                                                            pCdRubricaAgrupamento => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                  9,
                                                                                                                  962),
                                                            pNuSufixoRubrica      => 1,
                                                            pVlPagamento          => 0,
                                                            pVlIndice             => NULL,
                                                            pCdTipoOrigemRubrica  => 1);
                    END IF;

                    XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                     pCdVinculo       => pCdVinculo,
                                                     pCdRubrica       => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                      9,
                                                                                                      932),
                                                     pTpProcessamento => 2,
                                                     pTpLocal         => 2);

                    XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                     pCdVinculo       => pCdVinculo,
                                                     pCdRubrica       => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                      9,
                                                                                                      962),
                                                     pTpProcessamento => 2,
                                                     pTpLocal         => 2);
                  END IF;

                  --
                  -- Excecao PGTC, manter na mesma rubrica
                  --
                  IF pFolha.CdAgrupamento = 133 THEN

                    -- PGTC - Problema com contribuicao previdenciaria de servidor
                    -- Conforme sugestao da AGPE substituir o valor da Base Iprev pelo valor da 09-0962 para os comissionados
                    if XTMPAG_var.vgCco.Count > 0 then

                      vvlBase := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                   pcdvinculo        => pCdVinculo,
                                                                   pcdrubrica        => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                     9,
                                                                                                                     962));

                    else

                      vvlBase := vVlBase +
                                 XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                   pcdvinculo        => pCdVinculo,
                                                                   pcdrubrica        => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                     9,
                                                                                                                     932));

                    end if;
                    -- SIG-2725
                    --
                    -- Solicitacao de Sustentacao #76721
                    -- PGJTC - Problema com limitacao da contribuicao previdenciaria de servidora
                    --
                    IF vvlBase > vvlTetoGovernador AND
                       vvlTetoGovernador > 0 THEN

                      vvlBase := vvlTetoGovernador;

                    END IF;

                    PAtualizaBaseIPESC(pvlBase => vvlBase, pbCCO => TRUE);

                    vvlContribuicao := vvlBase *
                                       XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100;

                    PAtualizaValorIPESC(vVlContribuicao,
                                        FRetornaRubricaDescIPESC(1,
                                                                 pCdRubAgrupDescIPESC,
                                                                 pCdRubAgrupDescIPESC2008,
                                                                 pCdRubAgrupDescSCFuturo13));

                    --
                    -- Ajuste para quem tem Abono Permanencia
                    --
                    IF XTMPAG_geral.fpossuilancfinanceiro(pcdvinculo => pCdVinculo,
                                                          pfolha     => pFolha,
                                                          pcdrubrica => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                     1,
                                                                                                     914))

                     THEN

                      PAtualizaValorIPESC(vVlContribuicao,
                                          XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                       1,
                                                                       914));

                    END IF;

                  ELSE

                    IF pFolha.CdTipoFolha = XTMPAG_tipo.cnTpFolha13 AND
                       XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                         pcdvinculo        => pCdVinculo,
                                                         pcdrubrica        => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                           5,
                                                                                                           1923)) = 0 THEN
                      InsereRubricaIPESC(pCdVinculo,
                                         XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                      5,
                                                                      1923),
                                         pFolha.CdFolhaPagamento,
                                         XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                           pcdvinculo        => pCdVinculo,
                                                                           pcdrubrica        => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                             9,
                                                                                                                             932)) *
                                         XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100,
                                         1,
                                         XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica);

                    ELSIF pFolha.CdTipoFolha <> XTMPAG_tipo.cnTpFolha13

                     THEN
                      InsereRubricaIPESC(pCdVinculo,
                                         XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                      5,
                                                                      1924),
                                         pFolha.CdFolhaPagamento,
                                         XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                           pcdvinculo        => pCdVinculo,
                                                                           pcdrubrica        => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                             9,
                                                                                                                             932)) *
                                         XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica / 100,
                                         1,
                                         XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica);
                    else
                      null;
                    END IF;
                  END IF;
                END IF;

              WHEN XTMPAG_VAR.vAliqIPESCAtivo.VlAliquotaUnica IS NULL THEN

                pAplicaAliquotaIsolada(XTMPAG_VAR.vAliqIPESCAtivo.lFaixa);

            END CASE;

          WHEN XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria in (2, 9) AND
               vCdIsencaoParteContr IS NULL
              --
              --  Solicitacao de Sustentacao 15720/2021
              --  base 09-0920 – Base IPREV 13
              --
               OR
               (XTMPAG_GERAL.FSituacaoPrevVigente(pCdVinculo   => XTMPAG_VAR.vgVinculo.CdVinculo,
                                                  pDtInicioMes => TRUNC((XTMPAG_VAR.vgFolha.dtcalculoant),
                                                                        'MM'),
                                                  pDtFimMes    => last_day(XTMPAG_VAR.vgFolha.dtcalculoant)) in
               (2, 9) AND XTMPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
               XTMPAG_VAR.vgVinculo.DtDesligamento <
               XTMPAG_VAR.vgFolha.DtInicioMes AND
               NVL(XTMPAG_VAR.vgCdRubricaRecisao13, 0) > 0) THEN

            CASE

              WHEN XTMPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica IS NOT NULL THEN

                FOR c IN cBaseAliqUnica(XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP

                  IF c.vlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN

                    vvlBase := vvlTetoGovernador;

                  ELSE

                    vvlBase := c.vlBase;

                  END IF;

                  PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                     pbAtualiza => case
                                                     when XTMPAG_var.vgNuDiasApo > 0 then
                                                      TRUE
                                                     else
                                                      FALSE
                                                   end);

                  vvlContribuicao := vvlBase *
                                     XTMPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica / 100;

                  IF XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                    vvlContribuicao := vvlContribuicao * XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(
                                                 pCdVinculoPensionista => XTMPAG_VAR.vgVinculo.cdvinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia)
                                                  /
                                                 XTMPAG_pensaoprevidenciaria.fVlPercIntegralidade(
                                                 pCdVinculoPensionista => pCdVinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia);
/*

                    vvlContribuicao *
                         XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => pcdvinculo,
                                                                       pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                              pFolha.NuMesReferencia) / 100;
*/
                    END IF;

                     InsereRubricaIPESC(pCdVinculo,
                                       FRetornaRubricaDescIPESC(c.CdTipoRegimeProprioPrev,
                                                                pCdRubAgrupDescIPESC,
                                                                pCdRubAgrupDescIPESC2008,
                                                                pCdRubAgrupDescSCFuturo13),
                                       pFolha.CdFolhaPagamento,
                                       vvlContribuicao,
                                       1,
                                       XTMPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica);

                  PReGeraBasesIPREV(c.CdTipoRegimeProprioPrev);

                END LOOP;

              WHEN XTMPAG_VAR.vAliqIPESCInativo.VlAliquotaUnica IS NULL THEN

                IF XTMPAG_VAR.vgVinculo.DtDesligamento IS NOT NULL AND
                   XTMPAG_VAR.vgVinculo.DtDesligamento <
                   XTMPAG_VAR.vgFolha.DtInicioMes AND
                   NVL(XTMPAG_VAR.vgCdRubricaRecisao13, 0) > 0 THEN

                  vAliqIPESCRescisao := FRetornaAliquotaIPESCRescisao(XTMPAG_TIPO.cnTpTrbInativo,
                                                                      XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                      XTMPAG_VAR.vgFolha.NuMesReferencia);

                  IF XTMPAG_VAR.VGFOLHA.CDORGAO = 33 AND -- sig 7062
                     XTMPAG_geral.fpossuiregistroobito(XTMPAG_var.vCdPessoa,
                                                       XTMPAG_var.vgFolha.cdAgrupamento,
                                                       'S')  THEN
                    -- pAplicaAliquotaIsolada(vAliqIPESCRescisao.lFaixa);
                    pAplicaAliquotaIsolada(XTMPAG_VAR.vAliqIPESCInativo.lFaixa);
                  ELSE
                    pAplicaAliquotaIsolada(vAliqIPESCRescisao.lFaixa);
                  END IF;
                ELSE

                  pAplicaAliquotaIsolada(XTMPAG_VAR.vAliqIPESCInativo.lFaixa);
                END IF;
                --fim modificacao sig-7062
                IF XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                  vvlContribuicao := vvlContribuicao * XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(
                                                 pCdVinculoPensionista => XTMPAG_VAR.vgVinculo.cdvinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia)
                                                  /
                                                 XTMPAG_pensaoprevidenciaria.fVlPercIntegralidade(
                                                 pCdVinculoPensionista => pCdVinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia);
                  /*
                                    vvlContribuicao *
                                                       XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => pCdVinculo,
                                                                                                     pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                                              pFolha.NuMesReferencia) / 100;
                  */
                END IF;

            END CASE;

        -- Situação Não Previdenciária
          WHEN XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria in (4)
              --
              --#80348
              -- TipoPensaoNaoPrev: Decisão Judicial com remuneração
              -- Ocorre o abatimento do teto do RGPS
              --
               AND
               (XTMPAG_var.vgPensaoNaoPrev.count > 0 AND XTMPAG_var.vgPensaoNaoPrev(1).CdTipoPensaoNaoPrev = 83) THEN

            pAplicaAliquotaIsenPNP(XTMPAG_VAR.vAliqIPESCInativo.lFaixa);

          WHEN XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria in (2, 9) AND
               vCdIsencaoParteContr IS NOT NULL THEN

            CASE

              WHEN XTMPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica IS NOT NULL THEN

                FOR c IN cBaseAliqUnicaIsencao(XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria) LOOP

                  IF c.vlBase > vvlTetoGovernador AND vvlTetoGovernador > 0 THEN

                    vvlBase := vvlTetoGovernador;

                  ELSE

                    vvlBase := c.vlBase;

                  END IF;

                  PAtualizaBaseIPESC(pvlBase    => vvlBase,
                                     pbAtualiza => case
                                                     when XTMPAG_var.vgNuDiasApo > 0 then
                                                      TRUE
                                                     else
                                                      FALSE
                                                   end);

                  vvlContribuicao := vvlBase *
                                     XTMPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica / 100;

                  IF XTMPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 9 THEN
                    vvlContribuicao := vvlContribuicao *
                      XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(
                                                 pCdVinculoPensionista => XTMPAG_VAR.vgVinculo.cdvinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia)
                                                  /
                                                 XTMPAG_pensaoprevidenciaria.fVlPercIntegralidade(
                                                 pCdVinculoPensionista => pCdVinculo,
                                                 pAnoMesReferencia => pFolha.NuAnoReferencia*100+pFolha.NuMesReferencia);

                    /*
                                         vvlContribuicao *
                                                           XTMPAG_PENSAOPREVIDENCIARIA.fVlPercPensaoBase(pCdVinculoPensionista => pCdVinculo,
                                                                                                         pAnoMesReferencia     => pFolha.NuAnoReferencia * 100 +
                                                                                                                                  pFolha.NuMesReferencia) / 100;
                    */
                  END IF;

                  InsereRubricaIPESC(pCdVinculo,
                                     FRetornaRubricaDescIPESC(c.CdTipoRegimeProprioPrev,
                                                              pCdRubAgrupDescIPESC,
                                                              pCdRubAgrupDescIPESC2008,
                                                              pCdRubAgrupDescSCFuturo13),
                                     pFolha.CdFolhaPagamento,
                                     vvlContribuicao,
                                     1,
                                     XTMPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica);

                  PReGeraBasesIPREV(c.CdTipoRegimeProprioPrev);

                END LOOP;

              WHEN XTMPAG_VAR.vAliqIPESCParcial.VlAliquotaUnica IS NULL THEN

                pAplicaAliquotaIsoladaIsen(XTMPAG_VAR.vAliqIPESCParcial.lFaixa);

            END CASE;

          ELSE

            vvlContribuicao := 0;

        END CASE;


        IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevCPSM AND NVL(pPossuiLiminarCPSMpIPREV,0) <> 1 THEN
          
          PAtualizaValorCPSM(pfolha,
                             pCdVinculo,
                             vVlContribuicao,
                             vCdRubricaIPREV,
                             XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                          5,
                                                          380));
        END IF;

      END IF;

    END IF;

    XTMPAG_GERAL.PLogProcFim('4-4-1-2-2.Processa Trib IPRV');
  END;

  /*-----------------------------------------------------------------------------------------/
    Procedure  : PCalculacpsm

      Objetivo : Realizar o calculo de contribuicao do IPESC/IPREV

  /-----------------------------------------------------------------------------------------*/

  PROCEDURE PCalculaCPSM(pFolha     IN XTMPAG_TIPO.rFolha,
                         pCdPessoa  IN INTEGER,
                         pCdVinculo IN INTEGER) IS

    --vvlContribuicao      NUMBER(15,4);
    vVlTetoGovernador number;
    vVlBase           number;
    vVlCPSM           number;
    vAliquota         number;

    PROCEDURE pRetornaBaseCPSM(pVlBase out number) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT hrv.vlpagamento
        INTO pVlBase
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseCPSM
         AND ROWNUM < 2;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseCPSM,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseCPSM,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

        pVlBase := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                     pCdVinculo,
                                                     XTMPAG_VAR.vgCdRubBaseCPSM);

    END;

    PROCEDURE PAtualizaValorcpsm(pvlContribuicao IN NUMBER,
                                 pCdRubricaIpesc in INTEGER) IS

      vCdExpressaoFormCalc integer;
      vValorContribcpsm    number;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                     pCdRubricaAgrupamento => XTMPAG_var.vgCdRubDescCPSM,
                                                                     pCdRelacaoVinculo     => 0);

      if vCdExpressaoFormCalc <> 0 then

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => XTMPAG_var.vgVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => XTMPAG_var.vgCdRubDescCPSM,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => null,
                                              pCdTipoOrigemRubrica  => 10);

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                         pCdVinculo       => XTMPAG_var.vgVinculo.CdVinculo,
                                         pCdRubrica       => XTMPAG_var.vgCdRubDescCPSM,
                                         pTpProcessamento => 1,
                                         pTpLocal         => 2);

        vValorContribcpsm := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                               pcdvinculo        => XTMPAG_var.vgVinculo.CdVinculo,
                                                               pcdrubrica        => XTMPAG_var.vgCdRubDescCPSM);

        if vValorContribcpsm > pvlContribuicao then

          vValorContribcpsm := trunc(pVlContribuicao, 2);

        end if;

        /*UPDATE EPagHistoricoRubricaVinculo HRV
          SET HRV.Vlpagamento = 0
        WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
          AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
          AND HRV.CdRubricaAgrupamento = pCdRubricaIPESC;*/

        UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.Vlpagamento = vValorContribcpsm
         WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
           AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento = XTMPAG_var.vgCdRubDescCPSM;

      end if;

    EXCEPTION

      WHEN OTHERS THEN
        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                XTMPAG_VAR.vCdHistParamCalc,
                                XTMPAG_VAR.vCdPessoa,
                                'XTMPAG_TRIBUTACAO.PAtualizaValorCPSM',
                                XTMPAG_VAR.vgCdVinculo);
    END;

    PROCEDURE pInsereRubricaCPSM(pCdVinculo        IN INTEGER,
                                 pCdFolhaPagamento IN INTEGER,
                                 pVlRubrica        IN INTEGER,
                                 pNuSufixo         IN INTEGER,
                                 pVlIndice         IN NUMBER) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      XTMPAG_geral.pexcluirubrica(pCdFolhaPagamento,
                                  pCdVinculo,
                                  XTMPAG_var.vgCdRubDescCPSM,
                                  'S',
                                  'N');

      IF pvlRubrica >= 0.01 THEN

        BEGIN

          INSERT INTO EpagHistoricoRubricaVinculo
            (CdHistoricoRubricaVinculo,
             CdFolhaPagamento,
             CdRubricaAgrupamento,
             CdVinculo,
             NuSufixoRubrica,
             CdLancamentoFinanceiro,
             VlPagamento,
             QtParcelas,
             VlIndiceRubrica,
             DtUltAlteracao,
             CdTipoOrigemRubrica,
             CdTipoIndice)
          VALUES
            (Spaghistoricorubricavinculo.NEXTVAL,
             pCdFolhaPagamento,
             nvl(XTMPAG_var.vgCdRubDescCPSM,
                 XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento, 5, 380)),
             pCdVinculo,
             1,
             NULL,
             TRUNC(pvlRubrica, 2),
             1,
             pvlIndice,
             systimestamp,
             10,
             5);

        EXCEPTION
          WHEN OTHERS THEN
            XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                    XTMPAG_VAR.vCdHistParamCalc,
                                    XTMPAG_VAR.vCdPessoa,
                                    'XTMPAG_TRIBUTACAO.PAtualizaValorCPSM',
                                    XTMPAG_VAR.vgCdVinculo);
        END;
      end if;

    END;

    PROCEDURE pAplicaAliquotaCPSM(pVlBase   in number,
                                  pVlCPMS   out number,
                                  pVlIndice out number) IS

      i integer := 0;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      if XTMPAG_var.vAliqCPSM.lFaixa.COUNT > 0 then

        WHILE i < (XTMPAG_var.vAliqCPSM.lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF pvlBase BETWEEN XTMPAG_var.vAliqCPSM.lFaixa(i).vlInicial AND XTMPAG_var.vAliqCPSM.lFaixa(i).vlFinal THEN

            pVlCPMS := pvlBase * XTMPAG_var.vAliqCPSM.lFaixa(i).VlAliquota / 100;

            pVlCPMS := pVlCPMS - nvl(XTMPAG_var.vAliqCPSM.lFaixa(i).VlParcelaDeducao,
                                     0);

            IF pVlCPMS = 0 AND
               pvlBase * XTMPAG_var.vAliqCPSM.lFaixa(i).VlAliquota = 0 THEN
              RETURN;
            END IF;

            pVlIndice := XTMPAG_var.vAliqCPSM.lFaixa(i).VlAliquota;

            i := XTMPAG_var.vAliqCPSM.lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      elsif XTMPAG_var.vAliqCPSM.VlAliquotaUnica is not null then

        pVlCPMS := pvlBase * XTMPAG_var.vAliqCPSM.VlAliquotaUnica / 100;

        IF pVlCPMS = 0 THEN
          RETURN;
        END IF;

        pVlIndice := XTMPAG_var.vAliqCPSM.VlAliquotaUnica;

      end if;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    ------------------------------------------------------------------------------------------------------
    -- Calcula o CPSM
    ------------------------------------------------------------------------------------------------------

    XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => nvl(XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                            5,
                                                                                            380),
                                                               0),
                                      pnusufixo         => 1,
                                      pFlExcluiAmbos    => 'S');

    XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => nvl(XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                            5,
                                                                                            1934),
                                                               0),
                                      pnusufixo         => 1,
                                      pFlExcluiAmbos    => 'S');

    XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => nvl(XTMPAG_var.vgCdRubBaseIPESC,
                                                               0),
                                      pnusufixo         => 1,
                                      pFlExcluiAmbos    => 'S');

    XTMPAG_GERAL.PLogProcIni('4-4-1-2-2.Processa Trib cpsm');

    IF XTMPAG_GERAL.FGeraRubrica(XTMPAG_VAR.vgCdRubDescTetoGovernador) THEN

      vvlTetoGovernador := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                             pCdVinculo,
                                                             XTMPAG_VAR.vgCdRubricaTetoGov);
    ELSE

      vvlTetoGovernador := 0;

    END IF;
    ----------------------------------------------------------------------------------------------------------

    if XTMPAG_var.vgCdRubDescCPSM is null then
      XTMPAG_var.vgCdRubDescCPSM := XTMPAG_var.vgParamPagamento.CdRubricaAgrupDescCPSM;
    end if;

    pRetornaBaseCPSM(vVlBase);
    if vVlBase > 0 then
      pAplicaAliquotaCPSM(vVlBase, vVlCPSM, vAliquota);
      pInsereRubricaCPSM(pCdVinculo,
                         pFolha.CdFolhaPagamento,
                         vVlCPSM,
                         1,
                         vAliquota);
    end if;
    /*PAtualizaValorCPSM(vVlContribuicao,
    vCdRubricaIPREV);*/
    XTMPAG_GERAL.PLogProcFim('4-4-1-2-2.Processa Trib CPSM');
  END;

  PROCEDURE PCalculaCPSM13(pFolha     IN XTMPAG_TIPO.rFolha,
                           pCdPessoa  IN INTEGER,
                           pCdVinculo IN INTEGER) IS

    --vvlContribuicao      NUMBER(15,4);
    vVlTetoGovernador number;
    vVlBase           number;
    vVlCPSM           number;
    vAliquota         number;

    PROCEDURE pRetornaBaseCPSM(pVlBase out number) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT hrv.vlpagamento
        INTO pVlBase
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = XTMPAG_var.vgCdRubBaseIPESC13
         and ROWNUM < 2;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_var.vgCdRubBaseIPESC13,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_var.vgCdRubBaseIPESC13,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

        pVlBase := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                     pCdVinculo,
                                                     XTMPAG_var.vgCdRubBaseIPESC13);

    END;

    PROCEDURE pRetornaBaseCPSM13(pVlBase out number) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT hrv.vlpagamento
        INTO pVlBase
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdVinculo = pCdVinculo
         AND HRV.CdRubricaAgrupamento = XTMPAG_var.vgCdRubBaseCPSM13
         and ROWNUM < 2;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_var.vgCdRubBaseCPSM13,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_var.vgCdRubBaseCPSM13,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2);

        pVlBase := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                     pCdVinculo,
                                                     XTMPAG_var.vgCdRubBaseCPSM13);

    END;

    PROCEDURE PAtualizaValorcpsm(pvlContribuicao IN NUMBER,
                                 pCdRubricaIpesc in INTEGER) IS

      vCdExpressaoFormCalc integer;
      vValorContribcpsm    number;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                     pCdRubricaAgrupamento => XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                                                     pCdRelacaoVinculo     => 0);

      if vCdExpressaoFormCalc <> 0 then

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                              pCdVinculo            => XTMPAG_var.vgVinculo.CdVinculo,
                                              pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                              pCdRubricaAgrupamento => XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => null,
                                              pCdTipoOrigemRubrica  => 10);

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => XTMPAG_var.vgFolha,
                                         pCdVinculo       => XTMPAG_var.vgVinculo.CdVinculo,
                                         pCdRubrica       => XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                         pTpProcessamento => 1,
                                         pTpLocal         => 2);

        vValorContribcpsm := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                               pcdvinculo        => XTMPAG_var.vgVinculo.CdVinculo,
                                                               pcdrubrica        => XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13);

        if vValorContribcpsm > pvlContribuicao then

          vValorContribcpsm := trunc(pVlContribuicao, 2);

        end if;

        UPDATE EPagHistoricoRubricaVinculo HRV
           SET HRV.Vlpagamento = vValorContribcpsm
         WHERE HRV.CdVinculo = XTMPAG_var.vgVinculo.CdVinculo
           AND HRV.CdFolhaPagamento = XTMPAG_var.vgFolha.CdFolhaPagamento
           AND HRV.CdRubricaAgrupamento =
               XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13;

      end if;

    EXCEPTION

      WHEN OTHERS THEN
        XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                XTMPAG_VAR.vCdHistParamCalc,
                                XTMPAG_VAR.vCdPessoa,
                                'XTMPAG_TRIBUTACAO.PAtualizaValorCPSM13',
                                XTMPAG_VAR.vgCdVinculo);
    END;

    PROCEDURE pInsereRubricaCPSM(pCdVinculo        IN INTEGER,
                                 pCdFolhaPagamento IN INTEGER,
                                 pVlRubrica        IN INTEGER,
                                 pNuSufixo         IN INTEGER,
                                 pVlIndice         IN NUMBER) IS

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      XTMPAG_geral.pexcluirubrica(pCdFolhaPagamento,
                                  pCdVinculo,
                                  XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
                                  'S',
                                  'N');

      IF pvlRubrica >= 0.01 THEN

        INSERT INTO EpagHistoricoRubricaVinculo
          (CdHistoricoRubricaVinculo,
           CdFolhaPagamento,
           CdRubricaAgrupamento,
           CdVinculo,
           NuSufixoRubrica,
           CdLancamentoFinanceiro,
           VlPagamento,
           QtParcelas,
           VlIndiceRubrica,
           DtUltAlteracao,
           CdTipoOrigemRubrica,
           CdTipoIndice)
        VALUES
          (Spaghistoricorubricavinculo.NEXTVAL,
           pCdFolhaPagamento,
           XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13,
           pCdVinculo,
           1,
           NULL,
           TRUNC(pvlRubrica, 2),
           1,
           pvlIndice,
           systimestamp,
           10,
           XTMPAG_VAR.vgRubrica(XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13).CdTipoIndice);

      end if;

    END;

    PROCEDURE pAplicaAliquotaCPSM(pVlBase   in number,
                                  pVlCPMS   out number,
                                  pVlIndice out number) IS

      i integer := 0;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      if XTMPAG_var.vAliqCPSM.lFaixa.COUNT > 0 then

        WHILE i < (XTMPAG_var.vAliqCPSM.lFaixa.COUNT)

         LOOP

          i := i + 1;

          IF pvlBase BETWEEN XTMPAG_var.vAliqCPSM.lFaixa(i).vlInicial AND XTMPAG_var.vAliqCPSM.lFaixa(i).vlFinal THEN

            pVlCPMS := pvlBase * XTMPAG_var.vAliqCPSM.lFaixa(i).VlAliquota / 100;

            pVlCPMS := pVlCPMS - nvl(XTMPAG_var.vAliqCPSM.lFaixa(i).VlParcelaDeducao,
                                     0);

            IF pVlCPMS = 0 AND
               pvlBase * XTMPAG_var.vAliqCPSM.lFaixa(i).VlAliquota = 0 THEN
              RETURN;
            END IF;

            pVlIndice := XTMPAG_var.vAliqCPSM.lFaixa(i).VlAliquota;

            i := XTMPAG_var.vAliqCPSM.lFaixa.COUNT + 1;

          END IF;

        END LOOP;

      elsif XTMPAG_var.vAliqCPSM.VlAliquotaUnica is not null then

        pVlCPMS := pvlBase * XTMPAG_var.vAliqCPSM.VlAliquotaUnica / 100;

        IF pVlCPMS = 0 THEN
          RETURN;
        END IF;

        pVlIndice := XTMPAG_var.vAliqCPSM.VlAliquotaUnica;

      end if;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF pFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13) AND
       XTMPAG_VAR.vgFolha.Cdorgao = 33 THEN

      XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                          5,
                                                                                          380),
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');

      XTMPAG_GERAL.pexcluirubricasufixo(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                        pCdVinculo        => pCdVinculo,
                                        pCdRubrica        => XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                          9,
                                                                                          920),
                                        pnusufixo         => 1,
                                        pFlExcluiAmbos    => 'S');

    END IF;

    XTMPAG_GERAL.PExcluiRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                pCdVinculo        => pCdVinculo,
                                pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSS13,
                                pFlExcluiAmbos    => 'S');
    ------------------------------------------------------------------------------------------------------
    -- Calcula o CPSM 13
    ------------------------------------------------------------------------------------------------------

    XTMPAG_GERAL.PLogProcIni('4-4-1-2-2.Processa Trib cpsm');

    IF XTMPAG_GERAL.FGeraRubrica(XTMPAG_VAR.vgCdRubDescTetoGovernador) THEN

      vvlTetoGovernador := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                             pCdVinculo,
                                                             XTMPAG_VAR.vgCdRubricaTetoGov);
    ELSE

      vvlTetoGovernador := 0;

    END IF;
    ----------------------------------------------------------------------------------------------------------

    if XTMPAG_var.vgParamPagamento.CDRUBAGRUPDESCCPSMSOBRE13 is null then
      return;
    end if;

    IF pFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13, XTMPAG_tipo.cnTpFolhaAdiant13) AND
       XTMPAG_VAR.vgFolha.Cdorgao = 33 THEN
      pRetornaBaseCPSM13(vVlBase);
    ELSE

      pRetornaBaseCPSM(vVlBase);
    END IF;

      if vVlBase > 0 then
      pAplicaAliquotaCPSM(vVlBase, vVlCPSM, vAliquota);
      pInsereRubricaCPSM(pCdVinculo,
                         pFolha.CdFolhaPagamento,
                         vVlCPSM,
                         1,
                         vAliquota);
      end if;
    XTMPAG_GERAL.PLogProcFim('4-4-1-2-2.Processa Trib CPSM 13');
  END;

  PROCEDURE PProcessaSCPREV(pCdVinculo IN INTEGER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF XTMPAG_var.vgFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolha13) AND
       XTMPAG_tributacao.FRetornaRegimeProprioPrev(pCdVinculo) IN (1, 3, 4) THEN

       PCalculaSCPREV13(pCdVinculo);
       PCalculaBaseDeducIRRFSCPREV13(pCdVinculo);
       PCalculaDeducaoIRRFSCPREV13(pCdVinculo);

    ELSE

       PCalculaBaseEstendidaSCPREV(pCdVinculo);
       PCalculaFundoFinanceiro(pCdVinculo);
       PCalculaBaseDeducaoIRRFSCPREV(pCdVinculo);
       PCalculaDeducaoIRRFSCPREV(pCdVinculo);

    END IF;

    PCalculaPatronalSCPREV(pCdVinculo);


  END;

  /*-----------------------------------------------------------------------------------------/
    Procedure  : PProcessaTributacao

      Objetivo : Realizar a tributacao a ser paga pelo vinculo que esta processado. As
                 tributacoes envolvidas sao as de INSS, IRRF e IPREV/IPESC

     Nota: parametro pTpCalculo adicionado em 14/07/2009

           1 - Todas as tributacoes
           2 - Apenas IRRF

           parametro pTpTributacao

           1 - Tributacao Normal
           2 - Tributacao de 13
           3 - Tributacao de ferias
           4 - RRA
  /-----------------------------------------------------------------------------------------*/
  PROCEDURE PProcessaTributacao(pFolha            IN XTMPAG_TIPO.rFolha,
                                pCdPessoa         IN INTEGER,
                                pCdVinculo        IN INTEGER,
                                pParamPagamento   IN ePagAgrupamentoParametro%ROWTYPE,
                                pDtInicioMes      IN DATE,
                                pDtFimMes         IN DATE,
                                pTpTributacao     IN INTEGER,
                                pTpCalculo        IN INTEGER DEFAULT 1,
                                pvlDeducaoInativo IN NUMBER DEFAULT 0,
                                pbPrima           IN BOOLEAN DEFAULT FALSE,
                                pIndProcRetro     IN INTEGER DEFAULT NULL) IS

    vVlINSS NUMBER(15, 4) DEFAULT 0;

    vVlIPESC NUMBER(15, 4) DEFAULT 0;

    vCdRubAgrupDescIPESC INTEGER;

    vCdRubAgrupDescIPESCAlterada INTEGER;

    vCdRubIprevJudicial INTEGER;

    vCdRubAgrupDescIPESCJul2008 INTEGER;

    vCdRubAgrupDifDescIPESC INTEGER;

    vCdRubAgrupDifDescIPESC2008 INTEGER;

    vCdRubAgrupDevDescIPESC INTEGER;

    vCdRubAgrupDevDescIPESC2008 INTEGER;

    vCdRubSalBaseIPESC INTEGER;

    vCdRubAgrupDescINSS INTEGER;

    vCdRubSalBaseINSS INTEGER;

    vCdRubAgrupDescIRRF INTEGER;

    vCdRubSalBaseIRRF INTEGER;

    vCdRubAgrupDifDescIRRF INTEGER;

    vCdRubAgrupDevDescIRRF INTEGER;

    vCdRubAgrupDifDescINSS INTEGER;

    vCdRubAgrupDevDescINSS INTEGER;

    vCdRubBaseDeducaoInativo INTEGER;

    vPossuiLiminarCpsmParaIprev INTEGER;
    
    vCdRubAgrupDescSCFuturo13 INTEGER;

    vCdRubAgrupDifSCFuturo13 INTEGER;
    
    vCdRubAgrupDevSCFuturo13 INTEGER;
    
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vPossuiLiminarCpsmParaIprev := XTMPAG_fb.fmnepossuidecjudicial(XTMPAG_VAR.vgVinculo.CdVinculo,
                                                                   pParamPagamento.Cdrubagrupdesciprevliminar,
                                                                   pFolha.NuMesReferencia,
                                                                   pFolha.NuAnoReferencia);

    XTMPAG_GERAL.PLogProcIni('4-4-1-2.Processa Tributação');

    XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

    -- Prepara os parametros da parametrizacao conforme tipo de tributacao a ser realizada

    CASE

      WHEN pTpTributacao IN (1, 4) THEN
        -- Tributacao normal e RRA

        -- Parametros do IPESC

        -- Solicitacao de Sustentacao #68791
        -- 8554/2016 - FOLHA - - CALCULO DO IPREV (PREVIDENCIA COMPLEMENTAR)
        --
        IF NVL(FRetornaRegimeProprioPrev(pCdVinculo), 0) = 3 THEN

          vCdRubAgrupDescIPESCJul2008 := pParamPagamento.CdRubricaAgrupDescIprevJun2016;

          vCdRubAgrupDescIPESC := pParamPagamento.CdRubricaAgrupDescIprevJun2016;

          vCdRubAgrupDifDescIPESC := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                            XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                            XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                            pParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                                            XTMPAG_TIPO.cnTpRubDifDesc);

          vCdRubAgrupDifDescIPESC2008 := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                                XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                                pParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                                                XTMPAG_TIPO.cnTpRubDifDesc);

          vCdRubAgrupDevDescIPESC := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                            XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                            XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                            pParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                                            XTMPAG_TIPO.cnTpRubDevDesc);

          vCdRubAgrupDevDescIPESC2008 := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                                XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                                pParamPagamento.CdRubricaAgrupDescIprevJun2016,
                                                                                XTMPAG_TIPO.cnTpRubDevDesc);

        ELSIF NVL(FRetornaRegimeProprioPrev(pCdVinculo), 0) = 4 THEN

          vCdRubAgrupDescIPESCJul2008 := pParamPagamento.Cdrubagrupdescscfuturo;

          vCdRubAgrupDescIPESC := pParamPagamento.Cdrubagrupdescscfuturo;

          vCdRubAgrupDifDescIPESC := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                            XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                            XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                            pParamPagamento.Cdrubagrupdescscfuturo,
                                                                            XTMPAG_TIPO.cnTpRubDifDesc);

          vCdRubAgrupDifDescIPESC2008 := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                                XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                                pParamPagamento.Cdrubagrupdescscfuturo,
                                                                                XTMPAG_TIPO.cnTpRubDifDesc);

          vCdRubAgrupDevDescIPESC := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                            XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                            XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                            pParamPagamento.Cdrubagrupdescscfuturo,
                                                                            XTMPAG_TIPO.cnTpRubDevDesc);

          vCdRubAgrupDevDescIPESC2008 := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                                XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                                XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                                pParamPagamento.Cdrubagrupdescscfuturo,
                                                                                XTMPAG_TIPO.cnTpRubDevDesc);


        ELSE

          vCdRubAgrupDescIPESCJul2008 := pParamPagamento.CdRubricaAgrupDescIPESCJul2008;

          vCdRubAgrupDescIPESC := pParamPagamento.CdRubricaAgrupDescIPESC;

          vCdRubAgrupDifDescIPESC := XTMPAG_VAR.vgCdRubAgrupDifDescIPESC;

          vCdRubAgrupDifDescIPESC2008 := XTMPAG_VAR.vgCdRubAgrupDifDescIPESC2008;

          vCdRubAgrupDevDescIPESC := XTMPAG_VAR.vgCdRubAgrupDevDescIPESC;

          vCdRubAgrupDevDescIPESC2008 := XTMPAG_VAR.vgCdRubAgrupDevDescIPESC2008;

        END IF;

        vCdRubSalBaseIPESC := XTMPAG_VAR.vgCdRubBaseIPESC;

        -- Parametros do INSS

        vCdRubAgrupDescINSS := pParamPagamento.CdRubAgrupDescINSS;

        vCdRubSalBaseINSS := XTMPAG_VAR.vgCdRubBaseINSS;

        vCdRubAgrupDifDescINSS := XTMPAG_VAR.vgCdRubAgrupDifDescINSS;

        vCdRubAgrupDevDescINSS := XTMPAG_VAR.vgCdRubAgrupDevDescINSS;

        -- Parametros para IRRF

        vCdRubAgrupDescIRRF := pParamPagamento.CdRubAgrupDescIRRF;

        vCdRubSalBaseIRRF := XTMPAG_VAR.vgCdRubBaseIRRF;

        vCdRubAgrupDifDescIRRF := XTMPAG_VAR.vgCdRubAgrupDifDescIRRF;

        vCdRubAgrupDevDescIRRF := XTMPAG_VAR.vgCdRubAgrupDevDescIRRF;

        vCdRubBaseDeducaoInativo := XTMPAG_VAR.vgCdRubBaseDeducaoInativo;

      WHEN pTpTributacao = 2 THEN
        -- Sobre 13

        -- Parametros do IPESC

        --
        -- Solicitacao de Sustentacao #68791
        -- 8554/2016 - FOLHA - - CALCULO DO IPREV (PREVIDENCIA COMPLEMENTAR)
        --
        IF NVL(FRetornaRegimeProprioPrev(pCdVinculo), 0) = 3 THEN

          vCdRubAgrupDescIPESCJul2008 := pParamPagamento.CdRubricaAgrupDescIprevJun1613;

          vCdRubAgrupDescIPESC := pParamPagamento.CdRubricaAgrupDescIprevJun1613;
        ELSE

          vCdRubAgrupDescIPESCJul2008 := pParamPagamento.CdRubAgrupDescIPESCJul200813;

          vCdRubAgrupDescIPESC := pParamPagamento.CdRubAgrupDescIPESCSobre13;

        END IF;

        vCdRubSalBaseIPESC := XTMPAG_VAR.vgCdRubBaseIPESC13;
                
        vCdRubAgrupDescSCFuturo13 := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                            XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                            XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                            XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescSCFuturo13,
                                                                            XTMPAG_TIPO.cnTpRubDesconto);
                                                                            
        vCdRubAgrupDifSCFuturo13 := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                           XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                           XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescSCFuturo13,
                                                                           XTMPAG_TIPO.cnTpRubDifDesc);
                                                                            
        vCdRubAgrupDevSCFuturo13 := XTMPAG_TRIBUTACAO.FRetornaRubricaAgrup(XTMPAG_VAR.vgFolha.CdAgrupamento,
                                                                           XTMPAG_VAR.vgFolha.NuAnoReferencia,
                                                                           XTMPAG_VAR.vgFolha.NuMesReferencia,
                                                                           XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescSCFuturo13,
                                                                           XTMPAG_TIPO.cnTpRubDevDesc);                                                                                                                                                        

        -- Parametros do INSS

        vCdRubAgrupDescINSS := pParamPagamento.CdRubAgrupDescINSSSobre13;

        vCdRubSalBaseINSS := XTMPAG_VAR.vgCdRubBaseINSS13;

        vCdRubAgrupDifDescINSS := XTMPAG_VAR.vgCdRubAgrupDifDescINSS13;

        vCdRubAgrupDevDescINSS := XTMPAG_VAR.vgCdRubAgrupDevDescINSS13;

        -- Parametros para IRRF

        vCdRubAgrupDescIRRF := pParamPagamento.CdRubAgrupDescIRRFSobre13;

        vCdRubSalBaseIRRF := XTMPAG_VAR.vgCdRubBaseIRRF13;

        vCdRubAgrupDifDescIRRF := XTMPAG_VAR.vgCdRubAgrupDifDescIRRF13;

        vCdRubAgrupDevDescIRRF := XTMPAG_VAR.vgCdRubAgrupDevDescIRRF13;

        vCdRubBaseDeducaoInativo := XTMPAG_VAR.vgCdRubBaseDeducaoInativo;
        
      WHEN pTpTributacao = 3 THEN
        -- Sobre Ferias

        -- Parametros para IRRF

        vCdRubAgrupDescIRRF := pParamPagamento.CdRubAgrupDescIRRFSobreFerias;

        vCdRubSalBaseIRRF := XTMPAG_VAR.vgCdRubBaseIRRFFerias;

        vCdRubAgrupDifDescIRRF := XTMPAG_VAR.vgCdRubAgrupDifDescIRRFFerias;

        vCdRubAgrupDevDescIRRF := XTMPAG_VAR.vgCdRubAgrupDevDescIRRFFerias;

        vCdRubBaseDeducaoInativo := XTMPAG_VAR.vgCdRubBaseDeducaoInativo;

    END CASE;

    --  pTpCalculo = Todas as Trib  AND pTpTributacao IN (Normal, 13 sal)
    IF pTpCalculo = 1 AND pTpTributacao IN (1, 2) THEN

      IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = XTMPAG_TIPO.cnRegPrevProprio THEN
        
          PCalculaIPREV(pFolha,
                        pCdPessoa,
                        pCdVinculo,
                        vCdRubAgrupDescIPESC,
                        vCdRubAgrupDescIPESCJul2008,
                        vCdRubAgrupDifDescIPESC,
                        vCdRubAgrupDifDescIPESC2008,
                        vCdRubAgrupDevDescIPESC,
                        vCdRubAgrupDevDescIPESC2008,
                        vCdRubSalBaseIPESC,
                        vVlIPESC,
                        pbPrima,
                        NULL,
                        vCdRubAgrupDescSCFuturo13,
                        vCdRubAgrupDifSCFuturo13,
                        vCdRubAgrupDevSCFuturo13,
                        '0');
                        
      ELSIF (XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = XTMPAG_TIPO.cnRegPrevCPSM AND vPossuiLiminarCPSMParaIprev = 1) THEN
        -- Possui liminar revertendo CPSM para IPREV

        IF vPossuiLiminarCPSMParaIprev = 1 THEN
          
          IF pTpTributacao = 1 THEN

            vCdRubAgrupDescIPESCAlterada := pParamPagamento.CdRubAgrupDescIprevLiminar;
          
          ELSE
            
            vCdRubAgrupDescIPESCAlterada := pParamPagamento.CdRubAgrupDescIprevLiminar13;
            
          END IF;

          PCalculaIPREV(pFolha,
                        pCdPessoa,
                        pCdVinculo,
                        vCdRubAgrupDescIPESCAlterada,
                        vCdRubAgrupDescIPESCJul2008,
                        vCdRubAgrupDifDescIPESC,
                        vCdRubAgrupDifDescIPESC2008,
                        vCdRubAgrupDevDescIPESC,
                        vCdRubAgrupDevDescIPESC2008,
                        vCdRubSalBaseIPESC,
                        vVlIPESC,
                        pbPrima,
                        NULL,
                        vCdRubAgrupDescSCFuturo13,
                        vCdRubAgrupDifSCFuturo13,
                        vCdRubAgrupDevSCFuturo13,
                        vPossuiLiminarCpsmParaIprev);
                                                 
          END IF;
        
      END IF;
        

      ---------------------------------------------------------------------------------
      -- Gera Abono de permanencia na folha de 13 salario com o mesmo valor do IPESC
      -- caso a rubrica exista na folha normal/definitiva
      ---------------------------------------------------------------------------------

      PGeraAbonoPermanencia13(pCdVinculo          => pCdVinculo,
                              pFolha              => pFolha,
                              pCdRubricaAbonoPerm => XTMPAG_VAR.vgCdRubricaAbonoPerm,
                              pVlIPESC            => vVlIPESC);

      PExcluiAbonoPermanencia(pCdVinculo => pCdVinculo,
                              pFolha     => pFolha,
                              pVlIPESC   => vVlIPESC);

      PCalculaINSS(pFolha,
                   pCdPessoa,
                   pCdVinculo,
                   vCdRubAgrupDescINSS,
                   vCdRubSalBaseINSS,
                   vCdRubAgrupDifDescINSS,
                   vCdRubAgrupDevDescINSS,
                   vVlINSS);

      PCalculaFGTS(pFolha, pCdVinculo);

    END IF;

    if XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = XTMPAG_tipo.cnRegPrevCPSM AND vPossuiLiminarCpsmParaIprev <> 1 THEN
       -- Não gerar desconto CPSM se o servidor possuir decisão judicial liminar para a rubrica 05-1934, revertendo previdência para IPREV

       IF pTpTributacao = 1 THEN
        
        pCalculaCPSM(pFolha,
                     XTMPAG_VAR.vgVinculo.CdPessoa,
                     XTMPAG_VAR.vgVinculo.CdVinculo);
                     
       ELSIF pTpTributacao = 2 AND (pFolha.CdTipoFolha IN ( XTMPAG_TIPO.cnTpFolha13, XTMPAG_TIPO.cnTpFolhaAdiant13) OR 
          (pFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaNormal AND XTMPAG_GERAL.FRetornaValorRubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                                                                                  pcdvinculo        => pCdVinculo,
                                                                                                  pcdrubrica        => XTMPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                                                                    1,
                                                                                                                                                    1023)) > 0)) THEN           
          pCalculaCPSM13(pFolha,
                         XTMPAG_VAR.vgVinculo.CdPessoa,
                         XTMPAG_VAR.vgVinculo.CdVinculo);

       END IF;
     
    end if;

    IF pTpCalculo IN (1, 2) THEN

      PCalculaIRRF(pTpTributacao            => pTpTributacao,
                   pFolha                   => pFolha,
                   pCdPessoa                => pCdPessoa,
                   pCdVinculo               => pCdVinculo,
                   pCdRubAgrupDescIRRF      => vCdRubAgrupDescIRRF,
                   pCdRubBaseIRRF           => vCdRubSalBaseIRRF,
                   pCdRubAgrupDifDesc       => vCdRubAgrupDifDescIRRF,
                   pCdRubAgrupDevDesc       => vCdRubAgrupDevDescIRRF,
                   pCdRubBaseDeducaoInativo => vCdRubBaseDeducaoInativo,
                   pCdTipoTributacaoIRRF    => pParamPagamento.CdTipoTributacaoIRRF,
                   pDtInicioMes             => pDtInicioMes,
                   pDtFimMes                => pDtFimMes,
                   pVlINSS                  => NVL(vVlINSS, 0),
                   pVlIPESC                 => NVL(vVlIPESC, 0),
                   pVlDeducaoInativo        => pVlDeducaoInativo,
                   pbPrima                  => pbPrima,
                   pIndProcRetro            => pIndProcRetro);



      /*ELSIF pTpCalculo = 3 THEN

      PCalculaIRRF(pTpTributacao,
                   pFolha,
                   pCdPessoa,
                   pCdVinculo,
                   vCdRubAgrupDescIRRF,
                   vCdRubSalBaseIRRF,
                   vCdRubAgrupDifDescIRRF,
                   vCdRubAgrupDevDescIRRF,
                   vCdRubBaseDeducaoInativo,
                   pParamPagamento.CdTipoTributacaoIRRF,
                   pDtInicioMes,
                   pDtFimMes,
                   NVL(vVlINSS,0),
                   NVL(vVlIPESC,0),
                   pVlDeducaoInativo,
                   pbPrima); */

    END IF;

    XTMPAG_GERAL.PLogTrace('TRIBUTACAO - Processa Tributação',
                           null,
                           XTMPAG_VAR.vgTmInicio);

    XTMPAG_GERAL.PLogProcFim('4-4-1-2.Processa Tributação');

  END;

  PROCEDURE PPensaoAlimenticia(pFolha              IN XTMPAG_TIPO.rFolha,
                               pCdPessoa           IN INTEGER,
                               pCdVinculo          IN INTEGER,
                               pCdRubBaseIRRF      IN INTEGER,
                               pCdRubAgrupDescIRRF IN INTEGER,
                               pTpTributacao       IN INTEGER,
                               pvlDeducaoInativo   IN NUMBER DEFAULT 0,
                               pIndProcRetro       IN INTEGER DEFAULT NULL) IS

    vCdExpressaoFormCalc      INTEGER;
    vCont                     INTEGER;
    vListaRubPensao           VARCHAR2(100);
    vListaExpressao           VARCHAR2(100);
    vVlPensao                 NUMBER(13, 2);
    vvlIRRF                   NUMBER(13, 2);
    vCdEstruturaCarreira      INTEGER;
    vCdBaseCalculo            INTEGER;
    vBasesConsignacao         tblBaseConsignacao;
    vDtInicioPensao13         date := '01/12/' || pFolha.NuAnoReferencia;
    vCdRubBaseConsigUtilizada INTEGER;
    vVlMargemConsignavel      NUMBER(13, 2);
    vVlMargemConsignavelTotal NUMBER(13, 2);
    vTblRubPensaoAlim         XTMPAG_TIPO.tPensaoAlim;
    vCdRubPensao              INTEGER;

    CURSOR cSentenca IS
      SELECT SJ.CdSentencaJudicial,
             HSJ.CdTipoPensaoAlimenticia,
             SJ.NuSequencial,
             HSJ.FlPagamento13,
             HTP.FlPagamentoValorFixo,
             TPR.CdRubricaAgrupamento,
             TPR.CdHistTipoPensaoRubrica,
             R.NuRubrica,
             SR.CdOutraRubrica,
             SR.FlDescAnteriorAplicPercent,
             SR.VlPercentPensao,
             SR.VlFixo,
             HSJ.CdHistSentencaJudicial,
             HSJ.Flpagamentoferias,
             HSJ.FlpagaRetroativo
        FROM ePenSentencaJudicial SJ
       INNER JOIN EPenHistSentencaJudicial HSJ
          ON SJ.CdSentencaJudicial = HSJ.CdSentencaJudicial
       INNER JOIN EPenTipoPensaoAlimenticia TPA
          ON HSJ.CdTipoPensaoAlimenticia = TPA.CdTipoPensaoAlimenticia
       INNER JOIN EPenHistTipoPensao HTP
          ON TPA.CdTipoPensaoAlimenticia = HTP.CdTipoPensaoAlimenticia
       INNER JOIN EPenHistTipoPensaoRubrica TPR
          ON TPR.CdHistTipoPensao = HTP.CdHistTipoPensao
       INNER JOIN EPenSentencaRubrica SR
          ON SR.CdHistSentencaJudicial = HSJ.CdHistSentencaJudicial
         AND SR.CdHistTipoPensaoRubrica = TPR.CdHistTipoPensaoRubrica
       INNER JOIN EPagRubricaAgrupamento RA
          ON TPR.CdRubricaAgrupamento = RA.CdRubricaAgrupamento
       INNER JOIN EPagRubrica R
          ON R.CdRubrica = RA.CdRubrica
       WHERE SJ.CdVinculo = pCdVinculo
         AND HSJ.FlAnulado = XTMPAG_TIPO.cnN
         AND HSJ.Dtiniciovigencia <= pFolha.DtFimMes
         AND ((HSJ.DtFimVigencia >= case
               when pFolha.CdTipoFolha IN
                    (XTMPAG_TIPO.cnTpFolha13, XTMPAG_tipo.cnTpFolhaCtisp13) then
                vDtInicioPensao13
               else
                pFolha.DtInicioMes
             end) OR HSJ.DtFimVigencia IS NULL)
         AND ((HTP.NuAnoInicio < pFolha.NuAnoReferencia OR
             (HTP.NuAnoInicio = pFolha.NuAnoReferencia AND
             HTP.NuMesInicio <= pFolha.NuMesReferencia)) AND
             (HTP.NuAnoFim > pFolha.NuAnoReferencia OR
             (HTP.NuAnoFim = pFolha.NuAnoReferencia AND
             HTP.NuMesFim >= pFolha.NuMesReferencia) OR
             HTP.NuAnoFim IS NULL)) /*AND
                                                                       (TPR.CdRubricaAgrupamento,SJ.NuSequencial) NOT IN
                                                                       (SELECT LF.CdRubricaAgrupamento, LF.NuSufixoRubrica
                                                                          FROM EPagLancamentoFinanceiro LF
                                                                         WHERE LF.CdVinculo = pCdVinculo AND
                                                                               LF.DtInicioDireito <= pFolha.DtFimMes AND
                                                                               (LF.DtFimDireito >= pFolha.DtInicioMes OR LF.DtFimDireito IS NULL))*/
       GROUP BY SJ.CdSentencaJudicial,
                HSJ.CdTipoPensaoAlimenticia,
                SJ.NuSequencial,
                HSJ.FlPagamento13,
                HTP.FlPagamentoValorFixo,
                TPR.CdRubricaAgrupamento,
                TPR.CdHistTipoPensaoRubrica,
                R.NuRubrica,
                SR.CdOutraRubrica,
                SR.FlDescAnteriorAplicPercent,
                SR.VlPercentPensao,
                SR.VlFixo,
                HSJ.Flpagamentoferias,
                HSJ.FlPagaRetroativo,
                hsj.cdhistsentencajudicial
       ORDER BY R.NuRubrica;

    FUNCTION FSentencaSuspensa(pCdSentencaJudicial IN INTEGER)

     RETURN BOOLEAN IS

      vCont INTEGER DEFAULT 0;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT 1
        INTO vCont
        FROM EPenSuspensaoSentenca SS
       WHERE SS.CdSentencaJudicial = pCdSentencaJudicial
         AND ((SS.NuAnoInicio < pFolha.NuAnoReferencia OR
             (SS.NuAnoInicio = pFolha.NuAnoReferencia AND
             SS.NuMesInicio <= pFolha.NuMesReferencia)) AND
             (SS.NuAnoFim > pFolha.NuAnoReferencia OR
             (SS.NuAnoFim = pFolha.NuAnoReferencia AND
             SS.NuMesFim >= pFolha.NuMesReferencia) OR
             SS.NuAnoFim IS NULL));

      IF vCont > 0 THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    EXCEPTION

      WHEN NO_DATA_FOUND THEN

        RETURN FALSE;

      WHEN TOO_MANY_ROWS THEN

        RETURN TRUE;

    END;

    FUNCTION FExistePagamentoRubrica(pCdOutraRubrica IN INTEGER)

     RETURN BOOLEAN IS

      vCont INTEGER DEFAULT 0;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      SELECT COUNT(*)
        INTO vCont
        FROM EPagHistoricoRubricaVinculo HRV
       WHERE HRV.CdVinculo = pCdVinculo
         AND HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
         AND HRV.CdRubricaAgrupamento = pCdOutraRubrica;

      IF vCont > 0 THEN

        RETURN TRUE;

      ELSE

        RETURN FALSE;

      END IF;

    END;

    FUNCTION FTrataExigidas(pCdFolhaPagamento     IN INTEGER,
                            pCdVinculo            IN INTEGER,
                            pCdRubricaAgrupamento IN INTEGER)

     RETURN BOOLEAN IS

      vRubrica XTMPAG_TIPO.rRubrica;

      ------------------------------------------------------------------

      ------------------------------------------------------------------

      FUNCTION FCumpreExigencia(pCdFolhaPagamento IN INTEGER,
                                pCdVinculo        IN INTEGER,
                                pRubrica          IN XTMPAG_TIPO.rRubrica)
        RETURN BOOLEAN IS

        vCont INTEGER;

      BEGIN
        -- xtmpag_util.pGravaLogCallStack;

        IF pRubrica.InRubricasExigidas = '1' THEN

          /*Verifica se existem rubricas no conjunto de rubricas que
          exigem o recebimento desta que n¿o tenham sido pagas ao vinculo.

          Se (vCont = 0) ent¿o exclui o(s) pagamentos da rubrica            */

          SELECT COUNT(*)
            INTO vCont
            FROM EpagHistRubricaAgrupExigida E
           WHERE E.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica
             AND NOT EXISTS
           (SELECT 1
                    FROM EPagHistoricoRubricaVinculo HRV
                   WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
                     AND HRV.CdVinculo = pCdVinculo
                     AND HRV.CdRubricaAgrupamento = E.CdRubricaAgrupamento
                     AND (HRV.VlPagamento > 0 OR
                         NVL(HRV.VlMinRecebIncorp, 0) > 0 OR
                         HRV.CdLancamentoFinanceiro IS NOT NULL));

          IF vCont = 0 THEN

            RETURN TRUE;

          ELSE

            RETURN FALSE;

          END IF;

        ELSIF pRubrica.InRubricasExigidas = '2' THEN

          /*Verifica se pelo menos uma rubrica no conjunto de rubricas exigidas
          o recebimento desta que tenha sido pagas ao vinculo (vCont > 0)*/

          SELECT COUNT(*)
            INTO vCont
            FROM EPagHistRubricaAgrupExigida E
           WHERE E.CdHistRubricaAgrupamento = pRubrica.CdHistRubrica
             AND EXISTS
           (SELECT 1
                    FROM EPagHistoricoRubricaVinculo HRV
                   WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento
                     AND HRV.CdVinculo = pCdVinculo
                     AND HRV.CdRubricaAgrupamento = E.CdRubricaAgrupamento
                     AND (HRV.VlPagamento > 0 OR
                         NVL(HRV.VlMinRecebIncorp, 0) > 0 OR
                         HRV.CdLancamentoFinanceiro IS NOT NULL));

          IF vCont > 0 THEN

            RETURN TRUE;

          ELSE

            RETURN FALSE;

          END IF;

        ELSE

          RETURN TRUE;

        END IF;

      END;

    BEGIN
      -- xtmpag_util.pGravaLogCallStack;

      vRubrica := XTMPAG_VAR.vgRubrica(pCdRubricaAgrupamento);

      IF vRubrica.lsRubExigida.COUNT > 0 THEN

        IF NOT FCumpreExigencia(pCdFolhaPagamento, pCdVinculo, vRubrica) THEN

          RETURN TRUE;

        END IF;

      END IF;

      RETURN FALSE;

    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    if pFolha.CdTipoFolha in (XTMPAG_tipo.cnTpFolhaProdex13, XTMPAG_tipo.cnTpFolhaHonorarios13, XTMPAG_tipo.cnTpFolhaHonorarProcuradores13) then
      return;
    end if;

    XTMPAG_GERAL.PLogProcIni('4-4-1-1.Processa Pensao');

    XTMPAG_VAR.vgTmInicio := XTMPAG_GERAL.FGetTime;

    XTMPAG_VAR.vgSentenca.Delete;

    XTMPAG_VAR.bPossuiPensao := FALSE;

    vCont := 0;
    --
    -- Ciasc - Nao desconta pensao RRA nem em Folha de Recalculo Complementar.
    --
    IF (pTpTributacao = 4 or
       pFolha.CdTipoCalculo = XTMPAG_tipo.cnTpCalculoRecalcCompl) and
       pFolha.CdAgrupamento = 2 THEN
      RETURN;
    END IF;

    FOR vSentenca IN cSentenca LOOP
      --
      -- Solicitacao de Sustentacao #69334
      -- CIDASC - Pensao alimenticia - incidencia de ferias
      --
      IF pFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolhaFerias AND
         vSentenca.Flpagamentoferias = 'N' THEN
        CONTINUE;
      END IF;

      --
      -- Trata rubricas exigidas
      --
      BEGIN
        IF FTrataExigidas(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                          pCdVinculo            => pCdVinculo,
                          pCdRubricaAgrupamento => vSentenca.CdRubricaAgrupamento) THEN
          CONTINUE;
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;

      ---
      --- Conforme solicitacao, as rubricas de consignacao que fazer parte da base
      --- da pensao devem ser calculadas antes do processamento da pensao afim de terem
      --- seus valores apurados para a formula.
      ---
      IF (vPassagens = 1 or
         NVL(XTMPAG_VAR.vgParamPagamento.NuAproxIRRFPensao, 1) = 1) and
         pFolha.CdTipoFolha NOT IN
         (XTMPAG_TIPO.cnTpFolha13,
          XTMPAG_TIPO.cnTpFolhaAdiant13,
          XTMPAG_TIPO.cnTpFolhaCtisp13,
          XTMPAG_TIPO.cnTpFolhaAdiant13Ctisp) and vListaRubConsig is null THEN

        vListaRubConsig := '';

        FOR vRub in (SELECT pag133.cdrubricaagrupamento
                       FROM EPAGFORMCALCBLOCOEXPRUBAGRUP PAG126
                      inner join epagrubricaagrupamento pag133
                         on pag126.cdrubricaagrupamento =
                            pag133.cdrubricaagrupamento
                        and pag133.flconsignacao = 'S'
                      inner join epagformulacalcblocoexpressao pag127
                         on pag126.cdformulacalcblocoexpressao =
                            pag127.cdformulacalcblocoexpressao
                      inner join epagformulacalculobloco pag128
                         on pag127.cdformulacalculobloco =
                            pag128.cdformulacalculobloco
                      inner join epagexpressaoformcalc pag129
                         on pag128.cdexpressaoformcalc =
                            pag129.cdexpressaoformcalc
                      inner join epaghistformulacalculo pag130
                         on pag129.cdhistformulacalculo =
                            pag130.cdhistformulacalculo
                      inner join epagformulaversao pag131
                         on pag130.cdformulaversao = pag131.cdformulaversao
                      inner join epagformulacalculo pag132
                         on pag131.cdformulacalculo =
                            pag132.cdformulacalculo
                      where pag130.nuanofim is null
                        and pag132.cdrubricaagrupamento =
                            vSentenca.Cdrubricaagrupamento)

         LOOP

          --Procura as consignacoes associadas a rubrica agrupamento e insere na VbaseConsignacao
          SELECT BC.CdBaseConsignacao,
                 BC.NuSufixo,
                 BC.VlIndice,
                 BC.Vlmensalcontratado
            BULK Collect
            INTO vBasesConsignacao
            FROM EPagBaseConsignacao BC
           INNER JOIN EPagConsignacao C
              ON BC.CdConsignacao = C.CdConsignacao
           INNER JOIN EPAGRUBRICAAGRUPAMENTO EPR
              ON EPR.CDRUBRICA = C.CDRUBRICA
          --AND EPR.CDRUBRICAAGRUPAMENTO = vRub.Cdrubricaagrupamento
           INNER JOIN EPagHistConsignacao HC
              ON C.CdConsignacao = HC.CdConsignacao
           WHERE CdVinculo = pCdVinculo
             AND EPR.CDRUBRICAAGRUPAMENTO = vRub.Cdrubricaagrupamento
             AND ((BC.NuAnoReferenciaInicial < pFolha.NuAnoReferencia OR
                 (BC.NuAnoReferenciaInicial = pFolha.NuAnoReferencia AND
                 (BC.NuMesReferenciaInicial <= pFolha.NuMesReferencia))) AND
                 ((BC.NuAnoReferenciaFinal > pFolha.NuAnoReferencia OR
                 (BC.NuAnoReferenciaFinal = pFolha.NuAnoReferencia AND
                 BC.NuMesReferenciaFinal >= pFolha.NuMesReferencia) OR
                 BC.NuMesReferenciaFinal IS NULL)))
             AND BC.DtCancelamento IS NULL
             AND (HC.DtInicioVigencia <= pFolha.DtCalculo AND
                 (HC.DtFimVigencia >= pFolha.DtCalculo OR
                 HC.DtFimVigencia IS NULL))
             AND BC.FlRegistroAtual = XTMPAG_TIPO.cnS;

          IF vBasesConsignacao.count = 0 THEN
            continue;

          END IF;

          --Para cada cdConsignacao encontrado verifica se ha uma formula associada ou um valor cadastrado.
          --Caso exista, desconta este valor da pensao alimenticia.
          FOR i IN vBasesConsignacao.FIRST .. vBasesConsignacao.LAST

           LOOP

            --- Calcular rubricas de consignac?o que fazem parte da formula da pens?o.
            --- Trecho copiado do pacote XTMPAG_CNS porque n?o da para chamar isoladamente
            --- o calculo de uma rubrica com passagem de parametros.
            --- Se o vinculo possuir cargo efetivo, busca formula por Carreira
            IF XTMPAG_VAR.vgCEF.COUNT > 0 THEN

              vCdEstruturaCarreira := XTMPAG_VAR.vgCEF(1).CdEstruturaCarreira;

            END IF;

            vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                           pCdRubricaAgrupamento => vRub.Cdrubricaagrupamento,
                                                                           pCdRelacaoVinculo     => 0,
                                                                           pCdEstruturaCarreira  => vCdEstruturaCarreira);

            -- if (vCdExpressaoFormCalc <> 0 and vBasesConsignacao(i).VlIndice <> 0 and vBasesConsignacao(i).CdBase <> 0) or
            --   nvl(vBasesConsignacao(i).VlMensal,0) > 0

            --then
            --Desconta a consignacao encontrada da pensao alimenticia
            vListaRubConsig := NVL(vListaRubConsig, '') ||
                               vRub.CdRubricaAgrupamento || ',';

            --adiciona a formula
            begin

              delete epaghistoricorubricavinculo rv
               where rv.cdvinculo = pCdVinculo
                 and rv.cdfolhapagamento = pFolha.CdFolhaPagamento
                 and rv.cdrubricaagrupamento = vRub.CdRubricaAgrupamento
                 and rv.cdbaseconsignacao = vBasesConsignacao(i).CdBase;

            exception

              when others

               then
                null;

            end;

            if vCdExpressaoFormCalc <> 0 then

              XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => vCdExpressaoFormCalc,
                                                    pCdRubricaAgrupamento => vRub.Cdrubricaagrupamento,
                                                    pNuSufixoRubrica      => vBasesConsignacao(i).NuSufixo,
                                                    pVlPagamento          => 0,
                                                    pVlIndice             => vBasesConsignacao(i).VlIndice,
                                                    pCdBaseConsignacao    => vBasesConsignacao(i).CdBase,
                                                    pCdTipoOrigemRubrica  => 14);

              XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                               pCdVinculo       => pCdVinculo,
                                               pCdRubrica       => vRub.Cdrubricaagrupamento,
                                               pTpProcessamento => 1,
                                               pTpLocal         => 2);
              --adiciona o valor
            else

              -- inclui o valor total da consignação pois influencia no calculo da pensao
              -- BUG: há casos que a margem consignável é menor, alterando o valor da pensão
              -- Salva a sentença para recalcular a pensão no final
              IF NOT
                  vTblRubPensaoAlim.exists(vSentenca.CdRubricaAgrupamento) THEN
                vTblRubPensaoAlim(vSentenca.CdRubricaAgrupamento).CdRubricaAgrupamento := vRub.CdRubricaAgrupamento;
                vTblRubPensaoAlim(vSentenca.CdRubricaAgrupamento).CdBase := vBasesConsignacao(i).CdBase;
                vTblRubPensaoAlim(vSentenca.CdRubricaAgrupamento).NuSufixo := vBasesConsignacao(i).NuSufixo;
                vTblRubPensaoAlim(vSentenca.CdRubricaAgrupamento).vlBase := vBasesConsignacao(i).VlMensal;
              END IF;

              XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                    pCdVinculo            => pCdVinculo,
                                                    pCdExpressaoFormCalc  => NULL,
                                                    pCdRubricaAgrupamento => vRub.CdRubricaAgrupamento,
                                                    pNuSufixoRubrica      => vBasesConsignacao(i).NuSufixo,
                                                    pVlPagamento          => vBasesConsignacao(i).VlMensal,
                                                    pVlIndice             => 100,
                                                    pNuParcelas           => NULL,
                                                    pCdBaseConsignacao    => vBasesConsignacao(i).CdBase,
                                                    pCdTipoOrigemRubrica  => 14);
              -- vVlMensal := 0;
            end if;

          -- end if;

          END LOOP;

        END LOOP;

      END IF;

      IF (pFolha.CdTipoFolha NOT IN
         (XTMPAG_TIPO.cnTpFolha13,
           XTMPAG_TIPO.cnTpFolhaAdiant13,
           XTMPAG_TIPO.cnTpFolhaCtisp13,
           XTMPAG_TIPO.cnTpFolhaAdiant13Ctisp)) OR
         (pFolha.CdTipoFolha IN
         (XTMPAG_TIPO.cnTpFolha13, XTMPAG_TIPO.cnTpFolhaCtisp13) AND
         vSentenca.FlPagamento13 = 'S') OR (pFolha.CdTipoFolha IN
         (XTMPAG_TIPO.cnTpFolhaAdiant13,
                                             XTMPAG_TIPO.cnTpFolhaAdiant13Ctisp) AND
         vSentenca.FlPagamento13 = 'S') THEN

        IF (NOT FSentencaSuspensa(vSentenca.CdSentencaJudicial)) AND
           XTMPAG_VAR.vgRubrica.EXISTS(vSentenca.CdRubricaAgrupamento) AND
           XTMPAG_GERAL.FRubricaPermitida(pFolha.FlPagaTodasRubricas,
                                          pFolha.CdTipoFolha,
                                          vSentenca.CdRubricaAgrupamento) AND NOT
            XTMPAG_GERAL.FPossuiLancComplementar(pCdRubricaAgrupamento => vSentenca.CdRubricaAgrupamento,
                                                                                                                    pNuSufixoRubrica      => vSentenca.NuSequencial) THEN

          IF (vSentenca.CdOutraRubrica IS NULL) OR
             FExistePagamentoRubrica(vSentenca.CdOutraRubrica) THEN

            IF vSentenca.FlPagamentoValorFixo = 'S' AND
               vSentenca.CdRubricaAgrupamento NOT IN
               (XTMPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao,
                XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensao13) AND
               pTpTributacao IN (1, 2) THEN

              vCont := vCont + 1;

              XTMPAG_VAR.vgSentenca(vCont) := vSentenca;

              vListaRubPensao := vListaRubPensao ||
                                 vSentenca.CdRubricaAgrupamento || ',';

              IF XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                   pCdVinculo,
                                                   vSentenca.CdRubricaAgrupamento,
                                                   vSentenca.NuSequencial) > 0 THEN

                UPDATE EPagHistoricoRubricaVinculo HRV
                   SET HRV.VlPagamento            = vSentenca.VlFixo,
                       HRV.Cdhistsentencajudicial = vSentenca.Cdhistsentencajudicial
                 WHERE HRV.CdFolhapagamento = pFolha.CdFolhaPagamento
                   AND HRV.CdVinculo = pCdVinculo
                   AND HRV.CdRubricaAgrupamento =
                       vSentenca.CdRubricaAgrupamento
                   AND HRV.Nusufixorubrica = vSentenca.NuSequencial
                   and hrv.cdtipoorigemrubrica != 2; -- nao atualiza se a rubrica for de LF;
              ELSE

                XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento       => pFolha.CdFolhaPagamento,
                                                      pCdVinculo              => pCdVinculo,
                                                      pCdExpressaoFormCalc    => NULL,
                                                      pCdRubricaAgrupamento   => vSentenca.CdRubricaAgrupamento,
                                                      pNuSufixoRubrica        => vSentenca.NuSequencial,
                                                      pVlPagamento            => vSentenca.VlFixo,
                                                      pVlIndice               => NULL,
                                                      pCdTipoOrigemRubrica    => CASE
                                                                                   WHEN pTpTributacao IN (1,
                                                                                                          2) THEN
                                                                                    8
                                                                                   WHEN pTpTributacao = 4 THEN
                                                                                    18
                                                                                   ELSE
                                                                                    1
                                                                                 END,
                                                      pcdhistsentencajudicial => vSentenca.Cdhistsentencajudicial);
              END IF;

            ELSIF vSentenca.VlPercentPensao IS NOT NULL THEN

              --
              -- Indica se permite pensao RRA. Excecao rubrica percentual sobre salario minimo
              --
              IF pTpTributacao = 4 AND
                 (vSentenca.FlPagaRetroativo = 'N' OR
                 vSentenca.Cdrubricaagrupamento =
                 XTMPAG_geral.fretornarubrica(pFolha.CdAgrupamento, 5, 574)) THEN
                continue;
              END IF;

              -- Alteracao em 02/07/2012
              -- As rubricas de adiantamento de 13 de pensao e pensao de 13 nao devem ser
              -- calculadas, pois elas sao produto das rubricas de pensao normais

              IF vSentenca.CdRubricaAgrupamento NOT IN
                 (XTMPAG_VAR.vgParamPagamento.CdRubricaAdiant13Pensao,
                  XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensao13) THEN

                vCdExpressaoFormCalc := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => XTMPAG_VAR.vgFormExpr,
                                                                               pCdRubricaAgrupamento => vSentenca.CdRubricaAgrupamento,
                                                                               pCdRelacaoVinculo     => 0); -- Vinculo

                IF vCdExpressaoFormCalc > 0 THEN
                  --
                  -- Solicitacao de Sustentacao #74439
                  -- FOLHA - 9839/2017 - Pensao Alimenticia tipo "Valor" descontado em RRA
                  -- Comentada condicao abaixo referente a solicitacao acima.
                  -- Cliente nao encontrou logica
                  --IF pTpTributacao <> 4 OR (pTpTributacao = 4 AND FPossuiRUB(vCdExpressaoFormCalc)) THEN

                  vCont := vCont + 1;

                  XTMPAG_VAR.vgSentenca(vCont) := vSentenca;

                  vListaRubPensao := vListaRubPensao ||
                                     vSentenca.CdRubricaAgrupamento || ',';

                  XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                        pCdVinculo               => pCdVinculo,
                                                        pCdExpressaoFormCalc     => vCdExpressaoFormCalc,
                                                        pCdRubricaAgrupamento    => vSentenca.CdRubricaAgrupamento,
                                                        pNuSufixoRubrica         => vSentenca.NuSequencial,
                                                        pVlPagamento             => 0,
                                                        pVlIndice                => vSentenca.VlPercentPensao,
                                                        pCdTipoOrigemRubrica     => CASE
                                                                                      WHEN pTpTributacao IN (1,
                                                                                                             2) THEN
                                                                                       8
                                                                                      WHEN pTpTributacao = 4 THEN
                                                                                       18
                                                                                      ELSE
                                                                                       1
                                                                                    END,
                                                        pCdProcessoPagRetroativo => CASE
                                                                                      WHEN pTpTributacao <> 4 THEN
                                                                                       NULL
                                                                                      ELSE
                                                                                       XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo
                                                                                    END,
                                                        pcdhistsentencajudicial  => vSentenca.Cdhistsentencajudicial);

                  -- Processa a pensao inserida acima
                  XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                                   pCdVinculo       => pCdVinculo,
                                                   pCdRubrica       => vSentenca.CdRubricaAgrupamento,
                                                   pTpProcessamento => 1, -- Processa formulas de calculo
                                                   pTpLocal         => 2, -- no vinculo
                                                   pTpTributacao    => pTpTributacao,
                                                   pIndProcRetro    => pIndProcRetro);

                  IF pFolha.CdTipoFolha IN
                     (XTMPAG_TIPO.cnTpFolha13,
                      XTMPAG_TIPO.cnTpFolhaAdiant13,
                      XTMPAG_TIPO.cnTpFolhaCtisp13,
                      XTMPAG_TIPO.cnTpFolhaAdiant13Ctisp) THEN

                    -- Se o valor da rubrica da pensao for <= que 0 e
                    -- o valor da rubrica de 13 salario  for > 0, busca o valor da pensao
                    -- da folha que foi tomada como base para o calculo da folha de 13 salario
                    -- Ocorre com a rubrica de pensao 05-0922

                    IF XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                         pCdVinculo,
                                                         vSentenca.CdRubricaAgrupamento,
                                                         vSentenca.NuSequencial) <= 0 AND
                       XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                         pCdVinculo,
                                                         XTMPAG_VAR.vgCdRubAgrup13) > 0 THEN

                      IF NVL(XTMPAG_VAR.vgCdFolhaReplicada13, 0) > 0 THEN

                        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                              pCdVinculo            => pCdVinculo,
                                                              pCdExpressaoFormCalc  => NULL,
                                                              pCdRubricaAgrupamento => vSentenca.CdRubricaAgrupamento,
                                                              pNuSufixoRubrica      => vSentenca.NuSequencial,
                                                              pVlPagamento          => -- POG Solicitacao de Sustentacao #73185
                                                               CASE
                                                                 WHEN pCdVinculo = 479565 AND
                                                                      pFolha.NuAnoReferencia = 2016 AND
                                                                      pFolha.NuMesReferencia = 12 AND
                                                                      pFolha.CdTipoFolha = 3 -- 13°
                                                                  THEN

                                                                  (XTMPAG_GERAL.FRetornaValorRubrica(XTMPAG_VAR.vgCdFolhaReplicada13,
                                                                                                     pCdVinculo,
                                                                                                     vSentenca.CdRubricaAgrupamento,
                                                                                                     vSentenca.NuSequencial) * 5 / 12)

                                                                 ELSE
                                                                  XTMPAG_GERAL.FRetornaValorRubrica(XTMPAG_VAR.vgCdFolhaReplicada13,
                                                                                                    pCdVinculo,
                                                                                                    vSentenca.CdRubricaAgrupamento,
                                                                                                    vSentenca.NuSequencial)
                                                               END

                                                             ,
                                                              pVlIndice               => NULL,
                                                              pCdTipoOrigemRubrica    => CASE
                                                                                           WHEN pTpTributacao IN (1,
                                                                                                                  2) THEN
                                                                                            8
                                                                                           WHEN pTpTributacao = 4 THEN
                                                                                            18
                                                                                           ELSE
                                                                                            1
                                                                                         END,
                                                              pcdhistsentencajudicial => vSentenca.Cdhistsentencajudicial);

                      END IF;

                    END IF;

                  END IF;

                  --END IF;

                ELSE

                  XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                          XTMPAG_VAR.vCdHistParamCalc,
                                          XTMPAG_VAR.vCdPessoa,
                                          'Rubrica de pensão sem fórmula cadastrada:' ||
                                          LPAD(XTMPAG_VAR.vgRubrica(vSentenca.CdRubricaAgrupamento).CdTipoRubrica,
                                               2,
                                               '0') || '-' ||
                                          LPAD(XTMPAG_VAR.vgRubrica(vSentenca.CdRubricaAgrupamento).NuRubrica,
                                               4,
                                               '0'),
                                          XTMPAG_VAR.vgCdVinculo);

                END IF;

              END IF;

            else
              null;
            END IF;

          END IF;

        END IF;

      END IF;

    END LOOP;

    -- Caso alguma rubrica de pensao tenha sido paga, verifica se alguma delas
    -- esta contida dentro da formula da base de calculo associada ao IRRF

    IF LENGTH(vListaRubPensao) > 1 THEN

      vListaRubPensao := SUBSTR(vListaRubPensao,
                                1,
                                LENGTH(vListaRubPensao) - 1);

      -- Busca Base da Rubrica de Pensao

      vCdBaseCalculo := XTMPAG_VAR.vgRubrica(pCdRubBaseIRRF).CdBaseCalculo;

      XTMPAG_VAR.bPossuiPensao := TRUE;

      FOR i IN XTMPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco.FIRST .. XTMPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco.LAST LOOP

        FOR j IN XTMPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao.FIRST .. XTMPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao.LAST LOOP

          CASE
           XTMPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao(j).CdTipoMneumonico

            WHEN 4 THEN

              vListaExpressao := vListaExpressao || XTMPAG_VAR.vgBaseExpr(vCdBaseCalculo).lBloco(i).lExpressao(j).CdExpressao || ',';

            ELSE

              NULL;

          END CASE;

        END LOOP;

      END LOOP;

      IF LENGTH(vListaExpressao) > 1 THEN

        XTMPAG_VAR.vgValorIRRFAnterior := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                                            pCdVinculo,
                                                                            pCdRubAgrupDescIRRF);

        vListaExpressao := SUBSTR(vListaExpressao,
                                  1,
                                  LENGTH(vListaExpressao) - 1);

        SELECT SUM(VlPagamento)
          INTO vvlPensao
          FROM EPagHistoricoRubricaVinculo HRV
         INNER JOIN EPagBaseCalcBlocoExprRubAgrup BER
            ON HRV.CdRubricaAgrupamento = BER.CdRubricaAgrupamento
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdRubricaAgrupamento IN
               (SELECT to_number(column_value)
                  FROM TABLE(FSPLIT(vListaRubPensao)))
           AND BER.CdBaseCalculoBlocoExpressao IN
               (SELECT to_number(column_value)
                  FROM TABLE(FSPLIT(vListaExpressao)));

        /*  UPDATE EPagHistoricoRubricaVinculo HRV
          SET VlPagamento = vlPagamento - (NVL(vvlPensao,0) - XTMPAG_VAR.vgValorPensaoAnterior)
        WHERE HRV.CdFolhapagamento = pFolha.CdFolhaPagamento AND
              HRV.CdVinculo = pCdVinculo AND
              HRV.CdRubricaAgrupamento = pCdRubBaseIRRF;     */

        DELETE FROM epagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdRubricaAgrupamento = pCdRubAgrupDescIRRF;

        PProcessaTributacao(pFolha            => pFolha,
                            pCdPessoa         => pCdPessoa,
                            pCdVinculo        => pCdVinculo,
                            pParamPagamento   => XTMPAG_VAR.vgParamPagamento,
                            pDtInicioMes      => pFolha.DtInicioMes,
                            pDtFimMes         => pFolha.DtFimMes,
                            pTpTributacao     => pTpTributacao,
                            pTpCalculo        => 2,
                            pVlDeducaoInativo => pvlDeducaoInativo,
                            pIndProcRetro     => pIndProcRetro);

        vvlIRRF := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                     pCdVinculo,
                                                     pCdRubAgrupDescIRRF);

        IF (vvlPensao <> XTMPAG_VAR.vgValorPensaoAnterior OR
           vvlIRRF <> XTMPAG_VAR.vgValorIRRFAnterior) AND

           vPassagens <
           NVL(XTMPAG_VAR.vgParamPagamento.NuAproxIRRFPensao, 1) THEN

          vPassagens := vPassagens + 1;

          XTMPAG_VAR.vgValorPensaoAnterior := nvl(vvlPensao, 0);

          XTMPAG_VAR.vgValorIRRFAnterior := vvlIRRF;

          DELETE FROM EPagHistoricoRubricaVinculo HRV
           WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND HRV.CdRubricaAgrupamento IN
                 (SELECT to_number(column_value)
                    FROM TABLE(FSPLIT(vListaRubPensao)))
             AND HRV.CdLancamentoFinanceiro IS NULL;

          PPensaoAlimenticia(pFolha,
                             pCdPessoa,
                             pCdVinculo,
                             pCdRubBaseIRRF,
                             pCdRubAgrupDescIRRF,
                             pTpTributacao,
                             pvlDeducaoInativo,
                             pIndProcRetro);
        ELSE

          IF LENGTH(vListaRubConsig) > 1

           THEN

            vListaRubConsig := SUBSTR(vListaRubConsig,
                                      1,
                                      LENGTH(vListaRubConsig) - 1);
            ---
            --- Terminou entao exclui as rubricas de consignacoes incluidas anteriormente
            ---
            DELETE FROM EPagHistoricoRubricaVinculo HRV
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento IN
                   (SELECT to_number(column_value)
                      FROM TABLE(FSPLIT(vListaRubConsig)))
               AND HRV.CdLancamentoFinanceiro IS NULL;

            vListaRubConsig := '';

          END IF;

        END IF;

      END IF;

      vCdRubPensao := vTblRubPensaoAlim.first;

      IF LENGTH(vListaRubConsig) > 1

       THEN

        vListaRubConsig := SUBSTR(vListaRubConsig,
                                  1,
                                  LENGTH(vListaRubConsig) - 1);

        for cns in (select *
                      from EPagHistoricoRubricaVinculo HRV
                     WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                       AND HRV.CdVinculo = pCdVinculo
                       AND HRV.CdRubricaAgrupamento IN
                           (SELECT to_number(column_value)
                              FROM TABLE(FSPLIT(SUBSTR(vListaRubConsig,
                                                       1,
                                                       LENGTH(vListaRubConsig) - 1))))
                       AND HRV.CdLancamentoFinanceiro IS NULL)

         loop

          vVlMargemConsignavel := vVlMargemConsignavel;

        end loop;

      END IF;

      while vCdRubPensao is not null loop

        vVlMargemConsignavel := XTMPAG_CNS.FRetornaMargemConsig(pFolha=> pFolha,
                                                                pCdVinculo => pCdVinculo,
                                                                pCdRubricaBaseConsig => XTMPAG_VAR.vgCdRubricaBaseConsig);

        -- Salva na variavel os dados para manter os valores calculados no recalculo das consignações
        XTMPAG_var.vgTblRubCNSAlim(vTblRubPensaoAlim(vCdRubPensao).cdbase).cdRubricaAgrupamento := vTblRubPensaoAlim(vCdRubPensao).CdRubricaAgrupamento;
        XTMPAG_var.vgTblRubCNSAlim(vTblRubPensaoAlim(vCdRubPensao).cdbase).cdbase := vTblRubPensaoAlim(vCdRubPensao).cdbase;
        XTMPAG_var.vgTblRubCNSAlim(vTblRubPensaoAlim(vCdRubPensao).cdbase).nusufixo := vTblRubPensaoAlim(vCdRubPensao).NuSufixo;
        XTMPAG_var.vgTblRubCNSAlim(vTblRubPensaoAlim(vCdRubPensao).cdbase).vlBase := vVlMargemConsignavel;

        vVlMargemConsignavelTotal := vVlMargemConsignavelTotal + vTblRubPensaoAlim(vCdRubPensao).vlBase;

        IF vVlMargemConsignavelTotal < NVL(vVlMargemConsignavel, 0) THEN

          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                pCdVinculo            => pCdVinculo,
                                                pCdExpressaoFormCalc  => NULL,
                                                pCdRubricaAgrupamento => vTblRubPensaoAlim(vCdRubPensao).CdRubricaAgrupamento,
                                                pNuSufixoRubrica      => vTblRubPensaoAlim(vCdRubPensao).nusufixo,
                                                pVlPagamento          => vVlMargemConsignavel,
                                                pVlIndice             => 100,
                                                pNuParcelas           => NULL,
                                                pCdBaseConsignacao    => vTblRubPensaoAlim(vCdRubPensao).cdbase,
                                                pCdTipoOrigemRubrica  => 14);

          -- Processa a pensao inserida acima
          XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                           pCdVinculo       => pCdVinculo,
                                           pCdRubrica       => vCdRubPensao,
                                           pTpProcessamento => 1, -- Processa formulas de calculo
                                           pTpLocal         => 2, -- no vinculo
                                           pTpTributacao    => pTpTributacao,
                                           pIndProcRetro    => pIndProcRetro);
        END IF;

        DELETE FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdRubricaAgrupamento IN
               (vTblRubPensaoAlim(vCdRubPensao).CdRubricaAgrupamento,
                XTMPAG_VAR.vgCdRubricaBaseConsig)
           AND HRV.CdLancamentoFinanceiro IS NULL;

        vTblRubPensaoAlim.delete(vCdRubPensao);
        vCdRubPensao := vTblRubPensaoAlim.next(vCdRubPensao);
      end loop;
    ELSE

      IF LENGTH(vListaRubConsig) > 1

       THEN

        vListaRubConsig := SUBSTR(vListaRubConsig,
                                  1,
                                  LENGTH(vListaRubConsig) - 1);
        ---
        --- Terminou ent?o exclui as rubricas de consignac?es incluidas anteriormente
        ---
        DELETE FROM EPagHistoricoRubricaVinculo HRV
         WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
           AND HRV.CdVinculo = pCdVinculo
           AND HRV.CdRubricaAgrupamento IN
               (SELECT to_number(column_value)
                  FROM TABLE(FSPLIT(vListaRubConsig)))
           AND HRV.CdLancamentoFinanceiro IS NULL;

        vListaRubConsig := '';

      END IF;

    END IF;

    XTMPAG_GERAL.PLogTrace('TRIBUTACAO - Processa Pensão',
                           null,
                           XTMPAG_VAR.vgTmInicio);

    XTMPAG_GERAL.PLogProcFim('4-4-1-1.Processa Pensao');

  END;

  PROCEDURE PInsereBasesTributacao(pFolha     IN XTMPAG_TIPO.rFolha,
                                   pCdVinculo IN INTEGER) IS

    vVlTotalProventos13 NUMBER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    vVlTotalProventos13 := XTMPAG_geral.fVlTotalProventos13(pFolha.CdFolhaPagamento,
                                                            pcdvinculo);

    IF XTMPAG_VAR.vgCdRubBaseIRRF IS NOT NULL THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIRRF,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);

    END IF;

    ------------------------------------------------------------------------------------------------
    -- Calcula a base de IRRF de 13 para futura verificacao se deve realizar este tipo de tributacao
    ------------------------------------------------------------------------------------------------

    IF XTMPAG_VAR.vgCdRubBaseIRRF13 IS NOT NULL AND
       NOT XTMPAG_VAR.bReprocessou13Sal AND vVlTotalProventos13 > 0 THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIRRF13,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIRRF13,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/

    END IF;

    ------------------------------------------------------------------------------------------------------
    -- Calcula a base de IRRF de Ferias para futura verificacao se deve realizar este tipo de tributacao
    ------------------------------------------------------------------------------------------------------

    IF XTMPAG_VAR.vgCdRubBaseIRRFFerias IS NOT NULL THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseIRRFFerias,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIRRFFerias,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/

    END IF;

    IF XTMPAG_VAR.vgCdRubBaseINSS13 IS NOT NULL AND
       NOT XTMPAG_VAR.bReprocessou13Sal AND vVlTotalProventos13 > 0 THEN

      XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                            pCdVinculo            => pCdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseINSS13,
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => 0,
                                            pVlIndice             => NULL,
                                            pCdTipoOrigemRubrica  => 10);

      XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                       pCdVinculo       => pCdVinculo,
                                       pCdRubrica       => XTMPAG_VAR.vgCdRubBaseINSS13,
                                       pTpProcessamento => 2,
                                       pTpLocal         => 2); /*Vinculo*/

    END IF;

    ---------------------------------------------------------------------
    -- Se for regime geral gera as Patronais do INSS CLT e Estatutario
    ---------------------------------------------------------------------

    IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario =
       XTMPAG_TIPO.cnRegPrevGeral THEN

      IF XTMPAG_VAR.vgCdRubricaBaseINSSPat IS NOT NULL
        -- EPAGRI - Excecao Gerar somente para comissionados
         AND NOT (XTMPAG_VAR.vgFolha.CdOrgao = 27 AND
          XTMPAG_VAR.bVinculoComCCO = FALSE)

       THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaBaseINSSPat,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseINSSCLT IS NOT NULL AND
         NOT (XTMPAG_VAR.vgFolha.CdOrgao = 27 AND
          XTMPAG_VAR.bVinculoComCCO = TRUE)
      -- EPAGRI somente para efetivos
       THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseINSSCLT,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseProv13PatINSS IS NOT NULL THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseProv13PatINSS,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseProv13PatINSSCLT IS NOT NULL THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseProv13PatINSSCLT,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseProv13VlFGTS IS NOT NULL THEN

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseProv13VlFGTS,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);

      END IF;

    END IF;
    
    ------------------------------------------------------
    -- DEDUCOES LEGAIS PARA IRRF 09-1908                --
    ------------------------------------------------------
    IF XTMPAG_VAR.vgCdRubBaseDeducoesIRRF IS NOT NULL AND
       XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                         pCdVinculo,
                                         XTMPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                         1,
                                         NULL) = 0 THEN
                                         
        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);
                                                                                          
    END IF; 
    
    ------------------------------------------------------
    -- TOTAL DEDUCOES LEGAIS DO IRRF 13 09-1909         --
    ------------------------------------------------------
    IF XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13 IS NOT NULL AND
       XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                         pCdVinculo,
                                         XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                         1,
                                         NULL) = 0 THEN
                                         
        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);
                                                                                      
    END IF; 
    
    
    
    --------------------------------------------------------
    -- DEDUCOES LEGAIS PARA IRRF OUTROS VINCULOS 09-1911  --
    --------------------------------------------------------
    -- Usada no cálculo simplificado de IRRF
    IF XTMPAG_VAR.vgCdRubBaseDeducoesIRRFOutros IS NOT NULL AND
       XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                         pCdVinculo,
                                         XTMPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                         1,
                                         NULL) = 0 THEN
                                         
        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);
                                              
        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseDeducoesIRRFOutros,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/                                              
    END IF; 
    
    -------------------------------------------------------------
    -- DEDUCOES LEGAIS PARA IRRF 13 - OUTROS VINCULOS 09-1912  --
    -------------------------------------------------------------
     IF XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13 IS NOT NULL AND
        XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                          pCdVinculo,
                                          XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                          1,
                                          NULL) = 0 AND 
       (pFolha.CdTipoFolha = XTMPAG_TIPO.cnTpFolha13 OR 
        XTMPAG_GERAL.fRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                          pCdVinculo,
                                          XTMPAG_GERAL.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                                       pcdtiporubrica => 1,
                                                                       pNuRubrica     => 1023),
                                          1,
                                          NULL) > 0) THEN
                                         
        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => 0,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);
                                              
        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseDedIRRFOutros13,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/                                              
    END IF;       

  END;

  PROCEDURE PProcessaTributacaoRRA(pFolha          IN XTMPAG_TIPO.rFolha,
                                   pCdPessoa       IN INTEGER,
                                   pCdVinculo      IN INTEGER,
                                   pParamPagamento IN ePagAgrupamentoParametro%ROWTYPE,
                                   pDtInicioMes    IN DATE,
                                   pDtFimMes       IN DATE,
                                   pTpCalculo      IN INTEGER) IS

    vvlBaseRRA NUMBER(13, 2);

    FUNCTION FExistePensaoVigenteNoPeriodo(pCdVinculo    IN INTEGER,
                                           pNuAnoInicio  IN INTEGER,
                                           pNuMesInicio  IN INTEGER,
                                           pNuAnoFim     IN INTEGER,
                                           pNuMesFim     IN INTEGER) RETURN BOOLEAN IS
      vQtdPensoesVigentes INTEGER := 0;
      vExiste BOOLEAN := FALSE;
      vDtInicioPeriodo DATE;
      vDtFimPeriodo DATE;
    BEGIN
      -- xtmpag_util.pGravaLogCallStack;
      vDtInicioPeriodo := TO_DATE('01/'||pNuMesInicio||'/'||pNuAnoInicio, 'dd/mm/yyyy');
      vDtFimPeriodo    := TO_DATE('01/'||pNuMesFim||'/'||pNuAnoFim, 'dd/mm/yyyy');
      vDtFimPeriodo    := LAST_DAY(vDtFimPeriodo);

      select count(*) as qtd
      into vQtdPensoesVigentes
      from epenhistsentencajudicial
      where
      flanulado='N'
      and cdtipopensaoalimenticia is not null
      and cdsentencajudicial in (select cdsentencajudicial from epensentencajudicial where cdvinculo=pCdVinculo)
      and ((dtiniciovigencia >= vDtInicioPeriodo and dtiniciovigencia<= vDtFimPeriodo) or
           (dtfimvigencia>= vDtInicioPeriodo and dtfimvigencia<= vDtFimPeriodo));

      vExiste := vQtdPensoesVigentes>0;

      RETURN vExiste;
    END;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    FOR iProc IN XTMPAG_RT.vgProcessoRetroativo.FIRST .. XTMPAG_RT.vgProcessoRetroativo.LAST LOOP

      IF XTMPAG_RT.vgProcessoRetroativo(iProc).VlRestituir > 0 THEN

        XTMPAG_VAR.vgVlDeducaoDependente := 0;

        vvlBaseRRA := 0;

        UPDATE EPAGHISTORICORUBRICAVINCULO
           SET CDPROCESSOPAGRETROATIVO = XTMPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo
         WHERE CDVINCULO = pCdVinculo
           AND CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento
           AND CDRUBRICAAGRUPAMENTO = XTMPAG_VAR.vgCdRubBaseDeducoesIRRF;
        

        PProcessaTributacao(pFolha            => pFolha,
                            pCdPessoa         => pCdPessoa,
                            pCdVinculo        => pCdVinculo,
                            pParamPagamento   => pParamPagamento,
                            pDtInicioMes      => pFolha.DtInicioMes,
                            pDtFimMes         => pFolha.DtFimMes,
                            pTpTributacao     => 4, -- RRA
                            pTpCalculo        => 2, -- Apenas IRRF
                            pVlDeducaoInativo => 0,
                            pbPrima           => FALSE,
                            pIndProcRetro     => iProc);

        XTMPAG_VAR.vgValorPensaoAnterior := 0;

        vPassagens := 1;

        vListaRubConsig := null;
   
        PPensaoAlimenticia(pFolha              => pFolha,
                           pCdPessoa           => pCdPessoa,
                           pCdVinculo          => pCdVinculo,
                           pCdRubBaseIRRF      => XTMPAG_VAR.vgCdRubBaseIRRF,
                           pCdRubAgrupDescIRRF => XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF,
                           pTpTributacao       => 4,
                           pvlDeducaoInativo   => 0,
                           pIndProcRetro       => iProc);


        UPDATE EPAGHISTORICORUBRICAVINCULO
           SET CDPROCESSOPAGRETROATIVO = NULL
         WHERE CDVINCULO = pCdVinculo
           AND CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento
           AND CDRUBRICAAGRUPAMENTO IN (XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF); 

        -- Busca o valor da base calculado de IR para gerar a rubrica da BASE do RRA

        vvlBaseRRA := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                        pCdVinculo        => pCdVinculo,
                                                        pCdRubrica        => XTMPAG_VAR.vgCdRubBaseIRRF);

        IF vvlBaseRRA > 0 THEN

          -----------------------------------------------------------------------------------------------
          -- Insere base do RRA
          -----------------------------------------------------------------------------------------------
          XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento        => pFolha.CdFolhaPagamento,
                                                pCdVinculo               => pCdVinculo,
                                                pCdExpressaoFormCalc     => NULL,
                                                pCdRubricaAgrupamento    => XTMPAG_VAR.vgCdRubBaseRRA,
                                                pNuSufixoRubrica         => XTMPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                                                pVlPagamento             => vvlBaseRRA,
                                                pCdProcessoPagRetroativo => XTMPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo,
                                                pDeProcessoRetroativo    => XTMPAG_RT.vgProcessoRetroativo(iProc).DeProcessoRetroativo,
                                                pVlIndice                => XTMPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                                                pVlRestituir             => XTMPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                                                pCdTipoOrigemRubrica     => 18,
                                                pVlIndiceNMRRA           => XTMPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA);

          BEGIN
            -----------------------------------------------------------------------------------------------
            -- Atualiza informacoes do processo de retroativo na rubrica de desconto de IRRF de RRA
            -----------------------------------------------------------------------------------------------
            UPDATE EPagHistoricoRubricaVinculo HRV
               SET HRV.CdRubricaagrupamento    = XTMPAG_VAR.vgParamPagamento.CdRubricaAgrupDescRRA,
                   HRV.NuSufixorubrica         = XTMPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                   HRV.VlIndicerubrica         = XTMPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                   HRV.CdTipoOrigemRubrica     = 18,
                   HRV.CdProcessoPagRetroativo = XTMPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo,
                   HRV.DeProcessoRetroativo    = XTMPAG_RT.vgProcessoRetroativo(iProc).DeProcessoRetroativo,
                   HRV.VlMontanteRetroativo    = XTMPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                   HRV.VlIndiceNMRRA           = XTMPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA
             WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND HRV.CdRubricaAgrupamento =
                   XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF;

          EXCEPTION
            WHEN OTHERS THEN
              XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                      XTMPAG_VAR.vCdHistParamCalc,
                                      XTMPAG_VAR.vCdPessoa,
                                      'XTMPAG_TRIBUTACAO - Insere Base RRA',
                                      XTMPAG_VAR.vgCdVinculo);
          END;

        END IF;
        
        BEGIN
          -----------------------------------------------------------------------------------------------
          -- Atualiza as informacoes das rubricas de pensao alimenticia de RRA
          -----------------------------------------------------------------------------------------------

          IF (pFolha.CdAgrupamento <> 176) OR
             (pFolha.CdAgrupamento = 176 AND
              FExistePensaoVigenteNoPeriodo(pCdVinculo => pCdVinculo,
                                            pNuAnoInicio => XTMPAG_RT.vgProcessoRetroativo(iProc).NuAnoInicioRestituicao,
                                            pNuMesInicio => XTMPAG_RT.vgProcessoRetroativo(iProc).NuMesInicioRestituicao,
                                            pNuAnoFim => XTMPAG_RT.vgProcessoRetroativo(iProc).NuAnoFimRestituicao,
                                            pNuMesFim => XTMPAG_RT.vgProcessoRetroativo(iProc).NuMesFimRestituicao)) THEN

             UPDATE EPagHistoricoRubricaVinculo HRV
                 SET HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensaoAliRRA,
                     -- Comentado por deve manter o mesmo sufixo (o da sentenca)
                     -- HRV.NuSufixorubrica = XTMPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                     HRV.VlIndicerubrica         = XTMPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                     HRV.CdTipoOrigemRubrica     = 18,
                     HRV.CdProcessoPagRetroativo = XTMPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo,
                     HRV.DeProcessoRetroativo    = XTMPAG_RT.vgProcessoRetroativo(iProc).DeProcessoRetroativo,
                     HRV.VlMontanteRetroativo    = XTMPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                     HRV.VlIndiceNMRRA           = XTMPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA
               WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
                 AND HRV.CdVinculo = pCdVinculo
                 AND HRV.CdProcessoPagRetroativo = XTMPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo
                 AND HRV.CdRubricaAgrupamento IN
                     (SELECT RA.CdRubricaAgrupamento
                        FROM EPagRubricaAgrupamento RA
                       WHERE RA.FlPensaoAlimenticia = XTMPAG_TIPO.cnS
                         AND RA.CdAgrupamento = pFolha.CdAgrupamento)

                    /* AND (HRV.CdRubricaAgrupamento,HRV.NuSufixoRubrica)
                    NOT IN
                      -- Nao alterar quando tiver lancamento financeiro para a rubrica de pensao
                      -- afim de que este prevaleca, desde que nao seja oriundo de retroativo.
                           (SELECT LF.CdRubricaAgrupamento, LF.NuSufixoRubrica
                              FROM EPagLancamentoFinanceiro LF
                             WHERE LF.CdVinculo = pCdVinculo AND
                                   LF.DtInicioDireito <= pFolha.DtFimMes
                               AND (LF.DtFimDireito >= pFolha.DtInicioMes OR LF.DtFimDireito IS NULL)
                               AND (   LF.CdProcessoPagRetroativo IS NULL
                                    OR LF.CdProcessoPagRetroativo = XTMPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo)
                               )*/
                 AND HRV.DeProcessoRetroativo IS NULL;

          END IF;

        EXCEPTION
          WHEN OTHERS THEN
            XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                    XTMPAG_VAR.vCdHistParamCalc,
                                    XTMPAG_VAR.vCdPessoa,
                                    'XTMPAG_TRIBUTACAO - Atualiza informações rubrica pensão RRA',
                                    XTMPAG_VAR.vgCdVinculo);
        END;

        -----------------------------------------------------------------------------------------------
        -- Atualiza as informacoes das rubricas de IPREV de exercicios findos (06-0915 e 06-0926
        -----------------------------------------------------------------------------------------------
        BEGIN
          UPDATE EPagHistoricoRubricaVinculo HRV
             SET HRV.NuSufixorubrica      = XTMPAG_RT.vgProcessoRetroativo(iProc).NuSeqRubrica,
                 HRV.VlIndicerubrica      = XTMPAG_RT.vgProcessoRetroativo(iProc).NuMeses,
                 HRV.CdTipoOrigemRubrica  = 18,
                 HRV.VlMontanteRetroativo = XTMPAG_RT.vgProcessoRetroativo(iProc).VlMontante,
                 HRV.VlIndiceNMRRA        = XTMPAG_RT.vgProcessoRetroativo(iProc).VlIndiceNMRRA
           WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND HRV.CdProcessoPagRetroativo = XTMPAG_RT.vgProcessoRetroativo(iProc).CdProcessoPagRetroativo
             AND HRV.CdRubricaAgrupamento IN
                 (XTMPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 6, 926),
                  XTMPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento, 6, 915));
        EXCEPTION
          WHEN OTHERS THEN
            XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                    XTMPAG_VAR.vCdHistParamCalc,
                                    XTMPAG_VAR.vCdPessoa,
                                    'XTMPAG_TRIBUTACAO - Atualiza IPREV RRA',
                                    XTMPAG_VAR.vgCdVinculo);
        END;

      END IF;

    END LOOP;

  END;

  PROCEDURE PProcessaTributacaoEPensao(pFolha          IN XTMPAG_TIPO.rFolha,
                                       pCdPessoa       IN INTEGER,
                                       pCdVinculo      IN INTEGER,
                                       pParamPagamento IN ePagAgrupamentoParametro%ROWTYPE,
                                       pDtInicioMes    IN DATE,
                                       pDtFimMes       IN DATE,
                                       pTpCalculo      IN INTEGER DEFAULT 1,
                                       pbPrima         IN BOOLEAN DEFAULT FALSE) IS

    vvlDeducaoInativo NUMBER(13, 2);
    --vvlBaseRRA           NUMBER(13,2);
    --vVlPensao             NUMBER(13,2);
    vvlIRRF13 NUMBER(13, 2);
    vVlINSS13 NUMBER(13, 2);
    vCont     INTEGER;
    vVlBaseIRRF13 NUMBER(13, 2);

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    XTMPAG_FB.PProcessaFormulasBases(pfolha           => pFolha,
                                     pcdvinculo       => pCdVinculo,
                                     pcdrubrica       => XTMPAG_VAR.vgCdRubBaseINSS,
                                     ptpprocessamento => 2,
                                     ptplocal         => 2);

    XTMPAG_FB.PProcessaFormulasBases(pfolha           => pFolha,
                                     pcdvinculo       => pCdVinculo,
                                     pcdrubrica       => XTMPAG_VAR.vgCdRubBaseINSS13,
                                     ptpprocessamento => 2,
                                     ptplocal         => 2);      

    XTMPAG_geral.PAtualizaTotalizadoras(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                        pcdvinculo        => pcdvinculo);

    IF XTMPAG_VAR.vgVlTotalProventos <= 0 THEN
      RETURN;
    END IF;

    IF (XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario NOT IN
       (XTMPAG_TIPO.cnRegPrevGeral, XTMPAG_tipo.cnRegPrevNaoPossui) OR
       XTMPAG_VAR.vgfolha.cdagrupamento <> 134) AND -- militares
       XTMPAG_VAR.vgfolha.cdTipoFolha NOT IN (XTMPAG_TIPO.cnTpFolhaBEP)  THEN

      PProcessaSCPREV(pCdVinculo);

    END IF;

    PInsereBasesTributacao(pFolha => pFolha, pCdVinculo => pCdVinculo);

    IF XTMPAG_TRIBUTACAO.FAplicaDeducaoInativo(pCdPessoa,
                                               pFolha.DtInicioMes,
                                               pFolha.DtFimMes) THEN

      vvlDeducaoInativo := XTMPAG_VAR.vAliquotaIRRF.VlDeducaoInativo;

    ELSE

      vvlDeducaoInativo := 0;

    END IF;

    ----------------------------------------------------------------------------------
    -- Caso o parametro do agrupamento indique que deve tributar o RRA separadamente
    ----------------------------------------------------------------------------------

    IF XTMPAG_VAR.vgParamPagamento.FlTributaRRASeparado = 'S' AND
       XTMPAG_RT.vgProcessoRetroativo.COUNT > 0 THEN

      PProcessaTributacaoRRA(pFolha          => pFolha,
                             pCdPessoa       => pCdPessoa,
                             pCdVinculo      => pCdVinculo,
                             pParamPagamento => pParamPagamento,
                             pDtInicioMes    => pDtInicioMes,
                             pDtFimMes       => pDtFimMes,
                             pTpCalculo      => pTpCalculo);

    END IF;

    ----------------------------------------------------------------------------------
    -- Tributacao Normal
    ----------------------------------------------------------------------------------

    XTMPAG_VAR.vgVlDeducaoDependente := XTMPAG_TRIBUTACAO.FNumeroDependentes(pCdPessoa,
                                                                             pCdVinculo,
                                                                             pFolha.DtInicioMes,
                                                                             pFolha.DtFimMes) *
                                        XTMPAG_VAR.vAliquotaIRRF.VlDeducaoDependente;

    PProcessaTributacao(pFolha            => pFolha,
                        pCdPessoa         => pCdPessoa,
                        pCdVinculo        => pCdVinculo,
                        pParamPagamento   => pParamPagamento,
                        pTpTributacao     => 1,
                        pDtInicioMes      => pFolha.DtInicioMes,
                        pDtFimMes         => pFolha.DtFimMes,
                        pVlDeducaoInativo => vvlDeducaoInativo,
                        pbPrima           => TRUE);

    ----------------------------------------------------------------------------------
    -- Tributacao de 13 salario
    ----------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------
    -- Caso o valor da base para o IRRF/INSS de 13 seja maior que 0,
    -- ira processar a tributacao correspondente e reprocessar as pensoes
    ---------------------------------------------------------------------------------

    IF ((XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                           pCdVinculo        => pCdVinculo,
                                           pCdRubrica        => XTMPAG_VAR.vgCdRubBaseIRRF13) > 0) OR
       ((XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                            pCdVinculo        => pCdVinculo,
                                            pCdRubrica        => XTMPAG_VAR.vgCdRubExigibilidadeSusp) > 0 OR
         (XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                            pCdVinculo        => pCdVinculo,
                                            pCdRubrica        => XTMPAG_VAR.vgCdRubExigibilidadeSusp13) > 0)) AND
       XTMPAG_VAR.vgFolha.CdTipoFolha IN
       (XTMPAG_TIPO.cnTpFolha13,
          XTMPAG_TIPO.cnTpFolhaAdiant13,
          XTMPAG_TIPO.cnTpFolhaCtisp13,
          XTMPAG_TIPO.cnTpFolhaAdiant13Ctisp)) OR
       (XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                           pCdVinculo        => pCdVinculo,
                                           pCdRubrica        => XTMPAG_VAR.vgCdRubBaseINSS13) > 0) OR
       XTMPAG_var.vgVinculo.dtdesligamento <= pfolha.DtFimMes) AND
       NOT XTMPAG_VAR.bReprocessou13Sal THEN

      XTMPAG_VAR.vgValorPensaoAnterior := 0;

      vPassagens := 1;

      PProcessaTributacao(pFolha,
                          pCdPessoa,
                          pCdVinculo,
                          pParamPagamento,
                          pFolha.DtInicioMes,
                          pFolha.DtFimMes,
                          2, -- tpTributacao
                          1, -- tpCalculo
                          vvlDeducaoInativo,
                          CASE WHEN pFolha.CdTipoFolha = 3 THEN TRUE ELSE
                          FALSE END);

      /*IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario not in (XTMPAG_TIPO.cnRegPrevGeral, XTMPAG_tipo.cnRegPrevNaoPossui) then
          PCalculaSCPREV13(pCdVinculo);
          PCalculaBaseDeducIRRFSCPREV13(pCdVinculo);
          PCalculaDeducaoIRRFSCPREV13(pCdVinculo);
      end if;*/

      IF pFolha.CdTipoFolha IN
         (XTMPAG_TIPO.cnTpFolha13,
          XTMPAG_TIPO.cnTpFolhaAdiant13,
          XTMPAG_TIPO.cnTpFolhaResidente13,
          XTMPAG_TIPO.cnTpFolhaCtisp13,
          XTMPAG_TIPO.cnTpFolhaAdiant13Ctisp) THEN

        -- A condicao acima deve ser retirada quando existir rubrica propria para pagamento de pensao sobre 13 salario
        -- a ser gerada automaticamente quando em folha normal que possuir rescisao de 13 salario

        vListaRubConsig := null;

        PPensaoAlimenticia(pFolha              => pFolha,
                           pCdPessoa           => pCdPessoa,
                           pCdVinculo          => pCdVinculo,
                           pCdRubBaseIRRF      => XTMPAG_VAR.vgCdRubBaseIRRF13,
                           pCdRubAgrupDescIRRF => XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobre13,
                           pTpTributacao       => 2,
                           pvlDeducaoInativo   => vvlDeducaoInativo);

        -------------------------------------------------------------------------------------------------
        -- Transforma as rubricas de 13o sal?rio de pens?es aliment?cias, caso seja folha de 13 sal?rio
        -------------------------------------------------------------------------------------------------

        IF pFolha.CdTipoFolha IN
           (XTMPAG_TIPO.cnTpFolha13,
            XTMPAG_TIPO.cnTpFolhaResidente13,
            XTMPAG_TIPO.cnTpFolhaCtisp13) THEN

          BEGIN

            -- Apenas para o agrupamento dos militares (134)
            --  PARA FOLHA DE 13:
            --  ABATE O VALOR DESCONTADO NO ADIANTAMENTO NA RUBRICA 06-0586
            IF XTMPAG_VAR.vgFolha.CdAgrupamento = 134 THEN

              UPDATE epagHistoricoRubricaVinculo HRV
                 SET HRV.CdRubricaAgrupamento =
                     (SELECT VAG.cdrubricaagrupamento -- retorna o valor do tipo rubrica 06
                        FROM VPAGRUBRICAAGRUPAMENTO VAG
                       WHERE VAG.cdagrupamento =
                             XTMPAG_VAR.vgFolha.CdAgrupamento
                         AND VAG.cdtiporubrica = 6
                         AND VAG.nurubrica =
                             (SELECT VA.nurubrica
                                FROM VPAGRUBRICAAGRUPAMENTO VA
                               WHERE VA.CDRUBRICAAGRUPAMENTO =
                                     XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensao13))
               WHERE HRV.CdVinculo = XTMPAG_VAR.vgVinculo.CdVinculo
                 AND HRV.CdFolhaPagamento =
                     XTMPAG_VAR.vgFolha.CdFolhaPagamento
                 AND HRV.CdRubricaAgrupamento IN
                     (SELECT RA.CdRubricaAgrupamento
                        FROM EPagRubricaAgrupamento RA
                       INNER JOIN EPagRubrica R
                          ON R.CdRubrica = RA.CdRubrica
                       WHERE RA.CdAgrupamento =
                             XTMPAG_VAR.vgFolha.CdAgrupamento
                         AND R.CdTipoRubrica = 6
                         AND RA.FlPensaoAlimenticia = XTMPAG_TIPO.cnS);

            END IF;

            UPDATE epagHistoricoRubricaVinculo HRV
               SET HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgParamPagamento.CdRubAgrupPensao13
             WHERE HRV.CdVinculo = XTMPAG_VAR.vgVinculo.CdVinculo
               AND HRV.CdFolhaPagamento =
                   XTMPAG_VAR.vgFolha.CdFolhaPagamento
               AND HRV.CdRubricaAgrupamento IN
                   (SELECT RA.CdRubricaAgrupamento
                      FROM EPagRubricaAgrupamento RA
                     INNER JOIN EPagRubrica R
                        ON R.CdRubrica = RA.CdRubrica
                     WHERE RA.CdAgrupamento =
                           XTMPAG_VAR.vgFolha.CdAgrupamento
                       AND R.CdTipoRubrica = 5
                       AND RA.FlPensaoAlimenticia = XTMPAG_TIPO.cnS);

            -----------------------------------------------------------------------
            -- Verifica se existe pensoes vigentes e caso a sentenca nao possua
            -- a rubrica associada ao 13 de pensao, ela e incluida
            -----------------------------------------------------------------------

          EXCEPTION
            WHEN OTHERS THEN
              XTMPAG_GERAL.PInsereLog(XTMPAG_VAR.bLog,
                                      XTMPAG_VAR.vCdHistParamCalc,
                                      XTMPAG_VAR.vCdPessoa,
                                      'XTMPAG_TRIBUTACAO - Transforma rubricas 13° de pensões',
                                      XTMPAG_VAR.vgCdVinculo);
          END;

          --PAssociaRubricaPensao(pCdVinculo        => XTMPAG_VAR.vgVinculo.CdVinculo,
          --                      pFolha            => XTMPAG_VAR.vgFolha,
          --                      pFlAdiant13Pensao => 'N',
          --                      pFlPensao13       => 'S');

        END IF;

      END IF;

    END IF;

    ----------------------------------------------------------------------------------
    -- Tributacao de Ferias
    ----------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------
    -- Caso o valor da base para o IRRF de ferias seja maior que 0,
    -- ira processar a tributacao correspondente e reprocessar as pensoes
    ---------------------------------------------------------------------------------

    IF XTMPAG_VAR.vgCdRubBaseIRRFFerias > 0 AND
       XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                         pCdVinculo        => pCdVinculo,
                                         pCdRubrica        => XTMPAG_VAR.vgCdRubBaseIRRFFerias) > 0 THEN

      XTMPAG_VAR.vgValorPensaoAnterior := 0;

      vPassagens := 1;

      PProcessaTributacao(pFolha,
                          pCdPessoa,
                          pCdVinculo,
                          pParamPagamento,
                          pFolha.DtInicioMes,
                          pFolha.DtFimMes,
                          3,
                          2,
                          vvlDeducaoInativo);

      IF pFolha.CdTipoFolha IN (XTMPAG_TIPO.cnTpFolhaFerias) AND
         XTMPAG_VAR.vgParamPagamento.FlGeraPensaoFolhaFerias = 'S' THEN

        vListaRubConsig := null;

        PPensaoAlimenticia(pFolha              => XTMPAG_VAR.vgFolha,
                           pCdPessoa           => pCdPessoa,
                           pCdVinculo          => pCdVinculo,
                           pCdRubBaseIRRF      => XTMPAG_VAR.vgCdRubBaseIRRFFerias,
                           pCdRubAgrupDescIRRF => XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias,
                           pTpTributacao       => 3,
                           pvlDeducaoInativo   => vvlDeducaoInativo);

      END IF;

    ELSE

      XTMPAG_GERAL.PExcluiRubrica(pFolha.CdFolhaPagamento,
                                  pCdVinculo,
                                  XTMPAG_VAR.vgCdRubBaseIRRFFerias,
                                  'S');

    END IF;

    /*-------------------------------------------------------------------------------
     -- Inicializa as variaveis para controle do recalculo do IRRF
     -- em virtude de pensoes alimenticias contidas dentro da formula do IRRF
    ---------------------------------------------------------------------------------*/

    XTMPAG_VAR.vgValorPensaoAnterior := 0;

    vPassagens := 1;

    vControlaMsg := FALSE;

    IF pFolha.CdTipoFolha NOT IN
       (XTMPAG_TIPO.cnTpFolha13,
        XTMPAG_TIPO.cnTpFolhaAdiant13,
        XTMPAG_TIPO.cnTpFolhaResidente13,
        XTMPAG_TIPO.cnTpFolhaFerias,
        XTMPAG_TIPO.cnTpFolhaCtisp13,
        XTMPAG_TIPO.cnTpFolhaAdiant13Ctisp) THEN

      vListaRubConsig := null;

      PPensaoAlimenticia(pFolha              => pFolha,
                         pCdPessoa           => pCdPessoa,
                         pCdVinculo          => pCdVinculo,
                         pCdRubBaseIRRF      => XTMPAG_VAR.vgCdRubBaseIRRF,
                         pCdRubAgrupDescIRRF => XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRF,
                         pTpTributacao       => 1,
                         pvlDeducaoInativo   => vvlDeducaoInativo);
      -- Para as pensões alimentícias que possuem LF por valor, só atualiza valor após o cálculo de pensões
      -- uma vez que a rotina de calculo das pensões normal e RRA é a mesma.
      PPossuiLancFinanceiroPensao(pCdVinculo, pFolha);
    END IF;

    -------------------------------------------------------------------------------------------------
    --  Se variavel vgValorBaseIRRF e setada na Tributacao
    -------------------------------------------------------------------------------------------------

    IF XTMPAG_VAR.vgValorBaseIRRF > 0 OR
       XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                         pCdVinculo        => pCdVinculo,
                                         pCdRubrica        => XTMPAG_VAR.vgCdRubBaseIRRF13) > 0 THEN

      ------------------------------------------------------------------------------------
      -- Insere rubrica automatica (Modalidade 38)
      -- Desde que tenha mais de 65 anos e seja inativo e nao esteja isento de IRRF
      ------------------------------------------------------------------------------------
      IF NVL(vvlDeducaoInativoReal, 0) > 0 AND
         XTMPAG_TRIBUTACAO.FAplicaDeducaoInativo(pCdPessoa,
                                                 pFolha.DtInicioMes,
                                                 pFolha.DtFimMes) AND
         NOT FIsentoIRRF(pCdVinculo, pFolha) THEN

        XTMPAG_geral.pexcluirubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                    pCdVinculo            => pCdVinculo,
                                    pcdrubrica => XTMPAG_VAR.vgCdRubBaseDeducaoInativo,
                                    pflexcluiambos => 'S');

        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDeducaoInativo,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => vvlDeducaoInativoReal,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 10);
      END IF;

    END IF;

    vVlIRRF13 := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                   pCdVinculo,
                                                   XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescIRRFSobreFerias);

    vVlINSS13 := XTMPAG_GERAL.FRetornaValorRubrica(pFolha.CdFolhaPagamento,
                                                   pCdVinculo,
                                                   XTMPAG_VAR.vgParamPagamento.CdRubAgrupDescINSSSobre13);

    PGeraPatronalParaAfastado(pFolha   => pFolha,
                              pVinculo => XTMPAG_VAR.vgVinculo);

    IF XTMPAG_VAR.vgVinculo.CdRegimePrevidenciario = 2 THEN

      -- SÓ calcula se não tiver valor
      IF XTMPAG_VAR.vgCdRubBaseIPREVFF IS NOT NULL THEN

        BEGIN
          SELECT 1
            INTO vCont
            FROM EPagHistoricoRubricaVinculo HRV
           WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento
             AND HRV.CdVinculo = pCdVinculo
             AND HRV.CdRubricaAgrupamento = XTMPAG_VAR.vgCdRubBaseIPREVFF
             AND HRV.Vlpagamento > 0
             AND ROWNUM < 2;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

            XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                             pCdVinculo       => pCdVinculo,
                                             pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIPREVFF,
                                             pTpProcessamento => 2,
                                             pTpLocal         => 2); /*Vinculo*/

        END;

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseProv13PatFF,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseIPREVFP IS NOT NULL THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIPREVFP,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseProv13PatFP,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

      IF XTMPAG_VAR.vgCdRubBaseIPREVFT IS NOT NULL and XTMPAG_tributacao.FRetornaRegimeProprioPrev(pCdVinculo) = 4  THEN

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseIPREVFT,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

        XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                         pCdVinculo       => pCdVinculo,
                                         pCdRubrica       => XTMPAG_VAR.vgCdRubBaseProv13FT,
                                         pTpProcessamento => 2,
                                         pTpLocal         => 2); /*Vinculo*/

      END IF;

    END IF;

    vVlBaseIRRF13 := XTMPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                       pCdVinculo        => pCdVinculo,
                                                       pCdRubrica        => XTMPAG_VAR.vgCdRubBaseIRRF13);

    PExcluirRubricaDescDepIRRF(pCdFolhaPagamento => pFolha.cdFolhaPagamento,
                               pCdVinculo        => pCdVinculo,
                               pValorBaseIRRF    => XTMPAG_VAR.vgValorBaseIRRF,
                               pValorBaseIRRF13  => vVlBaseIRRF13);                               
                                                                

  END;

  PROCEDURE PExcluirRubricaDoContraCheque(pCdVinculo            IN INTEGER,
                                          pCdFolhaPagamento     IN INTEGER,
                                          pCdRubricaAgrupamento IN INTEGER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
    delete from epaghistoricorubricavinculo
     where cdvinculo = pCdVinculo
       and cdfolhapagamento = pCdFolhaPagamento
       and cdrubricaagrupamento = pCdRubricaAgrupamento
       and cdtipoorigemrubrica <> 17; -- exceto lancamento complementar
  END;

  PROCEDURE PExcluiRubContraChequeLancComp(pCdVinculo            IN INTEGER,
                                           pCdFolhaPagamento     IN INTEGER,
                                           pCdRubricaAgrupamento IN INTEGER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
    delete from epaghistoricorubricavinculo
     where cdvinculo = pCdVinculo
       and cdfolhapagamento = pCdFolhaPagamento
       and cdrubricaagrupamento = pCdRubricaAgrupamento;
  END;

  PROCEDURE PAtualizarValorPgtoRubrica(pCdVinculo            IN INTEGER,
                                       pCdFolhaPagamento     IN INTEGER,
                                       pCdRubricaAgrupamento IN INTEGER,
                                       pValorPagamento       IN NUMBER) IS
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
    UPDATE epaghistoricorubricavinculo
       SET vlpagamento = pValorPagamento
     WHERE cdVinculo = pCdVinculo
       AND cdfolhapagamento = pCdFolhaPagamento
       AND cdrubricaagrupamento = pCdRubricaAgrupamento;
  END;

  PROCEDURE PProcessarRubricaSCPREV13(pFolha                         IN XTMPAG_TIPO.rFolha,
                                      pFormExpr                      IN XTMPAG_TIPO.tFormulaCalculo,
                                      pCdVinculo                     IN INTEGER,
                                      pCdFolhaPagamento              IN INTEGER,
                                      pCdAgrupamento                 IN INTEGER,
                                      pCdTipoRubrica                 IN INTEGER,
                                      pNuRubrica                     IN INTEGER,
                                      pTpProcessamento               IN INTEGER,
                                      pValorIndiceRubrica            IN NUMBER,
                                      pValorMinimoContribuicaoSCPREV IN NUMBER,
                                      pCdTipoOrigemRubrica           IN INTEGER DEFAULT 1) IS

    vCdRubricaAgrupamento INTEGER;
    vCdExpressaoFormula   INTEGER := NULL;
    vValorRubrica         NUMBER;

  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
    vCdRubricaAgrupamento := XTMPAG_geral.fretornarubrica(pCdAgrupamento,
                                                          pCdTipoRubrica,
                                                          pNuRubrica);
    XTMPAG_TRIBUTACAO.PExcluirRubricaDoContraCheque(pCdVinculo,
                                                    pCdFolhaPagamento,
                                                    vCdRubricaAgrupamento);

    IF pCdTipoRubrica = 9 AND pNuRubrica IN (963, 1935) THEN
      vValorRubrica := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pCdFolhaPagamento,
                                                         pcdvinculo        => pCdVinculo,
                                                         pcdrubrica        => vCdRubricaAgrupamento);
      IF vValorRubrica > 0 THEN
        RETURN;
      END IF;

    END IF;

    IF (pCdTipoRubrica <> 9) THEN
      vCdExpressaoFormula := XTMPAG_GERAL.FIdentificaFormulaCalculo(pFormExpr             => pFormExpr,
                                                                    pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                                                    pCdRelacaoVinculo     => 0);
    END IF;

    XTMPAG_geral.pinserelancamentovinculo(pcdfolhapagamento     => pCdFolhaPagamento,
                                          pcdvinculo            => pCdvinculo,
                                          pcdexpressaoformcalc  => vCdExpressaoFormula,
                                          pcdrubricaagrupamento => vCdRubricaAgrupamento,
                                          pnusufixorubrica      => 1,
                                          pvlpagamento          => 0,
                                          pvlindice             => pValorIndiceRubrica,
                                          pcdtipoorigemrubrica  => pCdTipoOrigemRubrica);

    XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => vCdRubricaAgrupamento,
                                     pTpProcessamento => pTpProcessamento, -- 1 Processa fÓrmulas de calculo, 2 Processa base de cálculo
                                     pTpLocal         => 2); -- no vinculo

    IF (pCdTipoRubrica = 5) THEN
      vValorRubrica := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pCdFolhaPagamento,
                                                         pcdvinculo        => pCdVinculo,
                                                         pcdrubrica        => vCdRubricaAgrupamento);

      IF (pValorMinimoContribuicaoSCPREV IS NOT NULL) AND
         (vValorRubrica < pValorMinimoContribuicaoSCPREV) THEN
        XTMPAG_TRIBUTACAO.PAtualizarValorPgtoRubrica(pCdVinculo            => pCdVinculo,
                                                     pCdFolhaPagamento     => pCdFolhaPagamento,
                                                     pCdRubricaAgrupamento => vCdRubricaAgrupamento,
                                                     pValorPagamento       => pValorMinimoContribuicaoSCPREV);
      END IF;
    END IF;

  END;

  FUNCTION FObterValorIndiceRubrica(pCdVinculo     IN INTEGER,
                                    pCdRubrica     IN INTEGER,
                                    pDataInicioMes IN DATE,
                                    pDataFimMes    IN DATE,
                                    pFlAnulado     IN CHAR) RETURN NUMBER IS
    vValorIndiceRubrica NUMBER(10, 4) := 0;
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
    select f.vlindice
      into vValorIndiceRubrica
      from epaglancamentofinanceiro f
     where F.CdVinculo = pCdVinculo
       and F.DtInicioDireito <= pDataFimMes
       and (F.DtFimdireito >= pDataInicioMes or F.DtFimDireito is null)
       and F.FlAnulado = pFlAnulado
       and F.Cdrubricaagrupamento = pCdRubrica
       and ROWNUM < 2;

    RETURN nvl(vValorIndiceRubrica, 0);
  exception
    when no_data_found then
      return 0;
    when others then
      return 0;
  END;

  PROCEDURE PProcessarBase13SCPrev(pCdRegimeProprioPrev           IN INTEGER,
                                   pFolha                         IN XTMPAG_TIPO.rFolha,
                                   pFormExpr                      IN XTMPAG_TIPO.tFormulaCalculo,
                                   pCdVinculo                     IN INTEGER,
                                   pCdFolhaPagamento              IN INTEGER,
                                   pCdAgrupamento                 IN INTEGER,
                                   pValorMinimoContribuicaoSCPREV IN NUMBER,
                                   pValorTetoINSS                 IN NUMBER,
                                   pValorRubrica9_920             IN NUMBER) IS

    vCdRubricaAgrupamento9_963  INTEGER;
    vCdRubricaAgrupamento1_0023 INTEGER;
    vValorRubrica1_0023         NUMBER;
    vValorRubrica9_963          NUMBER;
    vValorMaximoRubrica9_963    NUMBER;
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
    vCdRubricaAgrupamento9_963 := XTMPAG_geral.fretornarubrica(pCdAgrupamento,
                                                               9,
                                                               963);
    XTMPAG_TRIBUTACAO.PProcessarRubricaSCPREV13(pFolha                         => pFolha,
                                                pFormExpr                      => pFormExpr,
                                                pCdVinculo                     => pCdVinculo,
                                                pCdFolhaPagamento              => pCdFolhaPagamento,
                                                pCdAgrupamento                 => pCdAgrupamento,
                                                pCdTipoRubrica                 => 9,
                                                pNuRubrica                     => 963,
                                                pTpProcessamento               => 2,
                                                pValorIndiceRubrica            => null,
                                                pValorMinimoContribuicaoSCPREV => pValorMinimoContribuicaoSCPREV,
                                                pCdTipoOrigemRubrica           => 10);

    vValorRubrica9_963 := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => pCdFolhaPagamento,
                                                            pcdvinculo        => pCdVinculo,
                                                            pcdrubrica        => vCdRubricaAgrupamento9_963);

    vCdRubricaAgrupamento1_0023 := XTMPAG_geral.fretornarubrica(XTMPAG_var.vgFolha.CdAgrupamento,
                                                                1,
                                                                23);
    vValorRubrica1_0023         := XTMPAG_geral.fretornavalorrubrica(pcdfolhapagamento => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                                     pcdvinculo        => pCdVinculo,
                                                                     pcdrubrica        => vCdRubricaAgrupamento1_0023);

    vValorMaximoRubrica9_963 := vValorRubrica1_0023 - pValorRubrica9_920;
    IF (pCdRegimeProprioPrev = 3) AND
       (vValorRubrica9_963 > vValorMaximoRubrica9_963) THEN
      XTMPAG_TRIBUTACAO.PAtualizarValorPgtoRubrica(pCdVinculo            => pCdVinculo,
                                                   pCdFolhaPagamento     => XTMPAG_var.vgFolha.CdFolhaPagamento,
                                                   pCdRubricaAgrupamento => vCdRubricaAgrupamento9_963,
                                                   pValorPagamento       => vValorMaximoRubrica9_963);
    END IF;
  END;

  PROCEDURE PAtualizarDeducoesLegaisIRRF(pfolha      IN XTMPAG_tipo.rfolha,
                                         pCdVinculo  IN INTEGER,
                                         pCdRubBase    IN INTEGER,
                                         pTpTributacao IN INTEGER DEFAULT 2,
                                         pIndProcRetro IN INTEGER DEFAULT NULL) IS
    
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;

    IF NOT FIsentoIRRF(pCdVinculo, pFolha) THEN 
      
      IF XTMPAG_VAR.vgCdRubBaseDeducoesIRRF IS NOT NULL THEN
        PReprocessarFormulaRubrica(pFolha         => pFolha,
                                   pCdVinculo     => pCdVinculo,
                                   pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                   pTpTributacao         => pTpTributacao,
                                   pIndProcRetro         => pIndProcRetro);

        IF pFolha.CdTipoFolha = XTMPAG_tipo.cnTpFolha13 THEN
          XTMPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                      pCdVinculo        => pCdVinculo,
                                      pCdRubrica        => XTMPAG_VAR.vgCdRubBaseDeducoesIRRF,
                                      pFlExcluiAmbos    => 'S');
        END IF;
      END IF;
      
    END IF;
    
    IF XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13 IS NOT NULL THEN
      XTMPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                    pCdVinculo        => pCdVinculo,
                                    pCdRubrica        => XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                    pFlExcluiAmbos    => 'S');

      if pCdRubBase = XTMPAG_var.vgCdRubBaseIRRF13 and
         XTMPAG_geral.fretornavalorrubrica(pFolha.CdFolhaPagamento, pcdvinculo, XTMPAG_var.vgCdRubBaseIRRF13) > 0  then

         PReprocessarFormulaRubrica(pFolha                => pFolha,
                                   pCdVinculo            => pCdVinculo,
                                   pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,
                                   pTpTributacao         => pTpTributacao,
                                   pIndProcRetro         => pIndProcRetro);

      end if;
   END IF;
  END;

  PROCEDURE PInserirDescDependentesIRRF(pfolha      IN XTMPAG_tipo.rfolha,
                                        pCdVinculo  IN INTEGER) IS
    vRubricaPresenteCC BOOLEAN := FALSE;
  BEGIN
    -- xtmpag_util.pGravaLogCallStack;
    vRubricaPresenteCC:= XTMPAG_GERAL.FRubricaPresenteNoContracheque(pCdVinculo            => pCdVinculo,
                                                                     pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaDescDepIRRF,
                                                                     pCdFolhaPagamento     => pFolha.CdFolhaPagamento);
   IF vRubricaPresenteCC THEN
     
     UPDATE EPAGHISTORICORUBRICAVINCULO
        SET VLPAGAMENTO = CASE 
                           WHEN pFolha.CdTipoFolhaPagamento IN (1505, 1525, 1526) THEN 
                             0
                           ELSE 
                             XTMPAG_VAR.vgVlDeducaoDependente end
      WHERE CDFOLHAPAGAMENTO = pFolha.CdFolhaPagamento
        AND CDVINCULO = pCdVinculo
        AND CDRUBRICAAGRUPAMENTO = XTMPAG_VAR.vgCdRubricaDescDepIRRF;
        
   ELSE
      -- Solicitacao de Sustentacao #65870
      -- 8178/2016 - PROCESSAMENTO DO 09-0907 INDEVIDAMENTE PARA ISENTOS DO IRRF
      IF NOT FIsentoIRRF(pCdVinculo, pFolha) AND
         pFolha.CdTipoFolhaPagamento NOT IN (1505, 1525, 1526) THEN
         
        XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                              pCdVinculo            => pCdVinculo,
                                              pCdExpressaoFormCalc  => NULL,
                                              pCdRubricaAgrupamento => XTMPAG_VAR.vgCdRubricaDescDepIRRF,
                                              pNuSufixoRubrica      => 1,
                                              pVlPagamento          => XTMPAG_VAR.vgVlDeducaoDependente,
                                              pVlIndice             => NULL,
                                              pCdTipoOrigemRubrica  => 1);
      END IF;
   END IF;
  END;

  PROCEDURE PExcluirRubricaDescDepIRRF(pCdFolhaPagamento IN INTEGER,
                                       pCdVinculo        IN INTEGER,
                                       pValorBaseIRRF    IN NUMBER,
                                       pValorBaseIRRF13  IN NUMBER) IS
  BEGIN
    
    -- xtmpag_util.pGravaLogCallStack;
    
    IF NVL(pValorBaseIRRF, 0) = 0 AND NVL(pValorBaseIRRF13, 0) = 0 THEN
      
      XTMPAG_GERAL.PExcluiRubrica(pcdfolhapagamento => pCdFolhaPagamento,
                                  pcdvinculo        => pCdVinculo,
                                  pcdrubrica        => XTMPAG_VAR.vgCdRubricaDescDepIRRF,
                                  pflexcluiambos    => 'S');
                                  
    END IF;
    
  END;

  PROCEDURE PReprocessarFormulaRubrica(pFolha                IN XTMPAG_tipo.rfolha,
                                       pCdVinculo            IN INTEGER,
                                       pCdRubricaAgrupamento IN INTEGER,
                                       pTpTributacao         IN INTEGER DEFAULT 2,
                                       pIndProcRetro         IN INTEGER DEFAULT NULL) IS
                                       
    vCdProcessoPagRetroativo INTEGER := NULL;
    
  BEGIN
    
    -- xtmpag_util.pGravaLogCallStack;

    IF pIndProcRetro IS NOT NULL THEN
      vCdProcessoPagRetroativo := XTMPAG_RT.vgProcessoRetroativo(pIndProcRetro).CdProcessoPagRetroativo;
    END IF;

    XTMPAG_GERAL.PExcluiRubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                  pcdvinculo        => pCdVinculo,
                                  pcdrubrica        => pCdRubricaAgrupamento,
                                  pflexcluiambos    => 'S');

    XTMPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                         pCdVinculo            => pCdVinculo,
                                         pCdExpressaoFormCalc  => NULL,
                                         pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                         pNuSufixoRubrica      => 1,
                                         pVlPagamento          => 0,
                                         pVlIndice             => NULL,
                                         pCdTipoOrigemRubrica     => 1,
                                         pcdprocessopagretroativo => vCdProcessoPagRetroativo);

    XTMPAG_FB.PProcessaFormulasBases(pFolha           => pFolha,
                                     pCdVinculo       => pCdVinculo,
                                     pCdRubrica       => pCdRubricaAgrupamento,
                                     pTpProcessamento => 2,
                                     pTpLocal         => 2,
                                     pTpTributacao    => pTpTributacao,
                                     pindprocretro    => pIndProcRetro);

  END;

PROCEDURE PAjustaIPREV(pFolha           IN XTMPAG_TIPO.rFolha,
                       pCdVinculo       IN Ecadvinculo.Cdvinculo%TYPE,
                       pCdRubricaGerada IN Epagrubricaagrupamento.Cdrubricaagrupamento%TYPE) IS
                       
  vVl080023           Epaghistoricorubricavinculo.Vlpagamento%TYPE;
  vVl080024           Epaghistoricorubricavinculo.Vlpagamento%TYPE;
  --vVl050944         Epaghistoricorubricavinculo.Vlpagamento%TYPE;
  vCdFolha13Ant       Epagfolhapagamento.Cdfolhapagamento%TYPE;
  vCdRubricaDescIpesc Epagrubricaagrupamento.Cdrubricaagrupamento%TYPE;
  
BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  vCdRubricaDescIpesc := XTMPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento, 5, 944);

  vVl080023:= XTMPAG_GERAL.fretornavalorrubrica(pcdvinculo => pCdVinculo,
                                                pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                pcdrubrica => XTMPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,
                                                                                           8,
                                                                                           23));

  vVl080024:= XTMPAG_GERAL.fretornavalorrubrica(pcdvinculo => pCdVinculo,
                                                pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                pcdrubrica => XTMPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,
                                                                                           8,
                                                                                           24));

  vCdFolha13Ant := fFolha13MesAnt(pFolha.CdFolhaPagamentoNormalAnt);

  /*vVl050944 := XTMPAG_GERAL.fretornavalorrubrica(pcdvinculo => pCdVinculo,
                                                 pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                 pcdrubrica => XTMPAG_VAR.vgParamPagamento.CDRUBAGRUPDESCIPESCSOBRE13);*/

  IF (nvl(vVl080023, 0)>0 OR nvl(vVl080024, 0)>0) AND (vCdRubricaDescIpesc = pCdRubricaGerada) /*(nvl(vVl050944, 0) > 0)*/ THEN
    XTMPAG_DT.PReprocessa13Salario(pCdVinculo        => pCdVinculo,
                                   pCdAgrupamento    => pFolha.CdAgrupamento,
                                   pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                   pCdFolha13Ant     => vCdFolha13Ant,
                                   pCdFolha13        => pFolha.CdFolhaPagamento);

    XTMPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                pcdvinculo        => pCdVinculo,
                                pcdrubrica        => XTMPAG_VAR.vgParamPagamento.CDRUBAGRUPDESCIPESCSOBRE13,
                                pflexcluiambos    => 'S');
  END IF;
END;

FUNCTION fFolha13MesAnt (pCdFolhaNormalAnt IN INTEGER)
  return integer is

  vCdFolha13Ant integer;

begin
  -- xtmpag_util.pGravaLogCallStack;

    with fol as (select f.cdorgao, f.nuanomesreferencia
                   from epagfolhapagamento f
                  where f.cdfolhapagamento = pCdFolhaNormalAnt)
    select ff.cdFolhaPagamento
      into vCdFolha13Ant
      from Epagfolhapagamento ff
      INNER JOIN epagtipofolhapagamento tfp
          ON ff.cdtipofolhapagamento = tfp.cdtipofolhapagamento
     inner join fol f on f.cdorgao = ff.cdorgao
                     and f.nuanomesreferencia = ff.nuanomesreferencia
     where ff.flcalculodefinitivo = 'S'
       and tfp.cdtipofolha = XTMPAG_tipo.cnTpFolha13;

    return vCdFolha13Ant;

    exception
      when no_data_found
        then return 0;
      when others
        then return 0;

end;

FUNCTION FObterInfoAdesaoDescSimp RETURN tblAdesaoDescSimplificado IS
  tblInfo tblAdesaoDescSimplificado;
BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  --CIDASC
  tblInfo(0).CdAgrupamento  := 4;
  tblInfo(0).NuAnoMesAdesao := 202306;

  --EPAGRI
  tblInfo(1).CdAgrupamento  := 5;
  tblInfo(1).NuAnoMesAdesao := 202306;

  --PGTC
  tblInfo(2).CdAgrupamento  := 133;
  tblInfo(2).NuAnoMesAdesao := 202306;

  --DPSC
  tblInfo(3).CdAgrupamento  := 176;
  tblInfo(3).NuAnoMesAdesao := 202403;

  -- AGPE
  tblInfo(4).CdAgrupamento  := 1;
  tblInfo(4).NuAnoMesAdesao := 202404;

  RETURN tblInfo;
END;

FUNCTION FAgrupUtilizaDescSimp(pCdAgrupamento IN INTEGER,
                               pNuAnoMesFolha IN INTEGER) RETURN BOOLEAN IS
  vUtiliza BOOLEAN := FALSE;
  i INTEGER;
  tblInfo tblAdesaoDescSimplificado := FObterInfoAdesaoDescSimp();
BEGIN
  -- xtmpag_util.pGravaLogCallStack;

  FOR i IN tblInfo.FIRST .. tblInfo.LAST
  LOOP
    IF tblInfo(i).CdAgrupamento = pCdAgrupamento AND
       tblInfo(i).NuAnoMesAdesao <= pNuAnoMesFolha THEN
      vUtiliza := TRUE;
    END IF;
  END LOOP;

  RETURN vUtiliza;
END;

END XTMPAG_TRIBUTACAO;
/
