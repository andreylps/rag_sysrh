CREATE OR REPLACE PACKAGE PKGPAG_PC IS

  EImpossivelGerarUltPA EXCEPTION;

  ENaoExistePAConquistado EXCEPTION;

  FUNCTION FAbaixoLimiteIdade (pDtNascimento IN DATE, pDtReferencia IN DATE) return boolean;

  PROCEDURE PGeraPerAquisFerias(pVinculo       IN PKGPAG_TIPO.rVinculo,
                                pCdAgrupamento IN INTEGER,
                                pCdOrgao       IN INTEGER,
                                pDtInicioMes   IN DATE,
                                pDtFimMes      IN DATE);

  PROCEDURE PGeraPerAquisTempServ(pVinculo           IN PKGPAG_TIPO.rVinculo,
                                  pCdOrgao           IN INTEGER,
                                  pDtInicioMes       IN DATE,
                                  pDtFimMes          IN DATE,
                                  pTpOrigemChamada   IN INTEGER DEFAULT 1, -- 1 Processamento de folha, 2 via aplicacao
                                  pFlFazRollback     IN CHAR DEFAULT 'S',
                                  pFlReGerarUltimoPA IN CHAR DEFAULT 'N',
                                  pNuCpfCadastrador  IN CHAR DEFAULT NULL,
                                  pCdRetorno         OUT INTEGER);

  PROCEDURE PGeraPerAquisLicPre(pVinculo             IN PKGPAG_TIPO.rVinculo,
                                pDtFimMes            IN DATE,
                                pTpOrigemChamada     IN INTEGER DEFAULT 1,
                                pCdTipoLicencaPremio IN INTEGER DEFAULT 1,
                                pFlReGerarUltimoPA   IN CHAR DEFAULT 'N');

  PROCEDURE PGeraPerAquisTSViaAplic(pCdAgrupamento     IN INTEGER,
                                    pCdPessoa          IN INTEGER,
                                    pCdVinculo         IN INTEGER,
                                    pTpOrigemChamada   IN INTEGER DEFAULT 1,
                                    pFlFazRollback     IN CHAR DEFAULT 'S',
                                    pFlReGerarUltimoPA IN CHAR DEFAULT 'N',
                                    pNuCpfCadastrador  IN CHAR DEFAULT NULL,
                                    pCdRetorno         OUT INTEGER);

  PROCEDURE PParamAdcLicPre(pCdOrgao         IN INTEGER,
                            pCdTipoAdicional IN INTEGER,
                            pDtCalculo       IN DATE);

  PROCEDURE PParamAdcTempServ(pCdAgrupamento   IN INTEGER,
                              pCdOrgao         IN INTEGER,
                              pNuAnoReferencia IN INTEGER,
                              pNuMesReferencia IN INTEGER);

  PROCEDURE PParamPerAquisFerias(pCdOrgao IN INTEGER, pDtFimMes IN DATE);

  PROCEDURE PAtualizaSituacaoErario(pCdVinculo IN INTEGER,
                                    pFolha     IN PKGPAG_TIPO.rFolha);

  PROCEDURE PAtualizaSituacaoRetro(pCdVinculo IN INTEGER,
                                   pFolha     IN PKGPAG_TIPO.rFolha);

  PROCEDURE PAtualizaSituacaoCompensacao(pCdVinculo IN INTEGER,
                                         pFolha     IN PKGPAG_TIPO.rFolha);

  PROCEDURE PGeraLicPreViaAplic(pCdAgrupamento     IN INTEGER,
                                pCdPessoa          IN INTEGER,
                                pCdVinculo         IN INTEGER,
                                pFlReGerarUltimoPA IN CHAR DEFAULT 'N',
                                pCdRetorno         OUT INTEGER);

  --PROCEDURE PGeraPerAquisFeriasPLSQL(pCdOrgao IN INTEGER, pNuMatricula IN INTEGER, pNuSeqMatricula IN INTEGER);

  PROCEDURE PGeraPerAquisFeriasPLSQL(pCdOrgao        IN INTEGER,
                                     pNuMatricula    IN INTEGER,
                                     pNuSeqMatricula IN INTEGER,
                                     pDtInicioMes    IN DATE,
                                     pDtFimMes       IN DATE);

  Procedure pAtualizarConcessaoPosAfastDef(pTpOrigemChamada INTEGER, -- Indica a origem da chamada {1:Calculo; 2:Recalculo; 3: Afastamento Def}
                                           pCdAgrupamento   INTEGER, -- Codigo do Agrupamento
                                           pCdOrgao         INTEGER, -- Codigo do orgao folha ou logado pelo usuario na aplicacao.
                                           pCdVinculo       INTEGER, -- Codigo do vinculo
                                           pCdAfastamento   INTEGER, -- Codigo do Afastamento definitivo que sera avaliado,
                                           -- obrigatorio para opcao 3
                                           pCdRetorno OUT INTEGER);

  FUNCTION Versao RETURN VARCHAR2;

END PKGPAG_PC;
/
CREATE OR REPLACE PACKAGE BODY PKGPAG_PC IS

  FUNCTION FAbaixoLimiteIdade (pDtNascimento IN DATE, pDtReferencia IN DATE) return boolean
  IS
  BEGIN

    RETURN PKGAFAUTL.FAbaixoLimiteIdade (pDtNascimento => pDtNascimento,
                                         pDtReferencia => pDtReferencia);
  END;

  FUNCTION fRetornaSaldoErario(pCdProcessoRestituicaoErario IN INTEGER)

    RETURN NUMBER IS

    vVlSaldo NUMBER(13,2);
    vVlPago NUMBER(13,2);

  BEGIN

    vVlSaldo := 0;
    vVlPago  := 0;

    SELECT SUM(MR.VlRestituir) vlRestituir
      INTO vVlSaldo
      FROM Erepprocessorestituicaoerario RE
      INNER JOIN ERepProcessoMontanteRestituir MR
      ON MR.Cdprocessorestituicaoerario =
         RE.Cdprocessorestituicaoerario
      INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = MR.Cdrubricaagrupamento
      INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA = 8 AND RU.NURUBRICA <> 120 AND RU.Cdrubrica = ER.CDRUBRICA
      WHERE RE.CdProcessoRestituicaoErario = pCdProcessoRestituicaoErario;

    SELECT SUM(LP.VlParcela)
      INTO vVlPago
      FROM EPagLancamentoFinanceiro LF
      INNER JOIN Epagpagamentolancamento LP
         ON LP.CdLancamentoFinanceiro =
            LF.CdLancamentoFinanceiro
      INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
      INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA = 8 AND RU.NURUBRICA <> 120 AND RU.Cdrubrica = ER.CDRUBRICA
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
      INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = MR.Cdrubricaagrupamento
      INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA IN (2,10,12) AND RU.Cdrubrica = ER.CDRUBRICA
      WHERE RT.Cdprocessopagretroativo = pCdProcessoPagRetroativo;

    SELECT SUM(LP.VlParcela)
      INTO vVlPago
      FROM EPagLancamentoFinanceiro LF
      INNER JOIN Epagpagamentolancamento LP
         ON LP.CdLancamentoFinanceiro =
            LF.CdLancamentoFinanceiro
      INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
      INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA IN (2,10,12) AND RU.Cdrubrica = ER.CDRUBRICA
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


  FUNCTION fVerificaQuitacaoRetroativo(pCdProcessoPagRetroativo IN INTEGER)

    RETURN NUMBER IS

    vVlPago NUMBER(13,2);
    vFlExisteLanc CHAR(1);

  BEGIN

    vVlPago  := 0;

    with fin as (select sum(lf.vllancamentofinanceiro) as SOMA
                   FROM EPagLancamentoFinanceiro LF
                  INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
                  INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA IN (2,10,12,5) AND RU.Cdrubrica = ER.CDRUBRICA
                  WHERE LF.Cdprocessopagretroativo = pCdProcessoPagRetroativo)
        select f.soma
          into vVlPago from fin f
        where f.soma = (SELECT SUM(lp.vlparcela) as parc
                   FROM EPagLancamentoFinanceiro LF
                   INNER JOIN Epagpagamentolancamento LP
                   ON LP.CdLancamentoFinanceiro = LF.CdLancamentoFinanceiro
                   INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
                   INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA IN (2,10,12,5) AND RU.Cdrubrica = ER.CDRUBRICA
                   WHERE LF.Cdprocessopagretroativo = pCdProcessoPagRetroativo);

    RETURN vVlPago;

    EXCEPTION
       
      WHEN NO_DATA_FOUND THEN
        
        BEGIN
          SELECT 'S'
            INTO vFlExisteLanc
            FROM EPagLancamentoFinanceiro LF
           INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
           INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA IN (2,10,12,5) AND RU.Cdrubrica = ER.CDRUBRICA
           WHERE LF.Cdprocessopagretroativo = pCdProcessoPagRetroativo;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN 1; -- se nem existe o lançamento, não existe o que quitar
        END; 
        
        Return 0;

      WHEN OTHERS
        THEN
          RETURN 0;
  END;

  FUNCTION fVerificaQuitacaoErario(pCdProcessoRestituicaoErario IN INTEGER)

    RETURN NUMBER IS

    vVlPago NUMBER(13,2);
    vFlExisteLanc CHAR(1);    

  BEGIN

    vVlPago  := 0;

    with fin as (select sum(lf.vllancamentofinanceiro) as SOMA
                   FROM EPagLancamentoFinanceiro LF
                   INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
                   INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA = 8 AND RU.NURUBRICA <> 120 AND RU.Cdrubrica = ER.CDRUBRICA
                   WHERE LF.CdProcessoRestituicaoErario = pCdProcessoRestituicaoErario)
        select f.soma
          into vVlPago from fin f
        where f.soma = (SELECT SUM(lp.vlparcela) as parc
                          FROM EPagLancamentoFinanceiro LF
                          INNER JOIN Epagpagamentolancamento LP ON LP.CdLancamentoFinanceiro = LF.CdLancamentoFinanceiro
                          INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
                          INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA = 8 AND RU.NURUBRICA <> 120 AND RU.Cdrubrica = ER.CDRUBRICA
                          WHERE LF.CdProcessoRestituicaoErario = pCdProcessoRestituicaoErario);

    RETURN vVlPago;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        
        BEGIN
          SELECT 'S'
            INTO vFlExisteLanc
            FROM EPagLancamentoFinanceiro LF
            INNER JOIN EPAGRUBRICAAGRUPAMENTO ER ON ER.Cdrubricaagrupamento = LF.Cdrubricaagrupamento
            INNER JOIN EPAGRUBRICA RU ON RU.CDTIPORUBRICA = 8 AND RU.NURUBRICA <> 120 AND RU.Cdrubrica = ER.CDRUBRICA
            WHERE LF.CdProcessoRestituicaoErario = pCdProcessoRestituicaoErario;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN 1; -- se nem existe o lançamento, não existe o que quitar
        END; 
        
        Return 0;

      WHEN OTHERS
        THEN
          RETURN 0;
  END;

  PROCEDURE PGeraPerAquisFerias(pVinculo       IN PKGPAG_TIPO.rVinculo,
                                pCdAgrupamento IN INTEGER,
                                pCdOrgao       IN INTEGER,
                                pDtInicioMes   IN DATE,
                                pDtFimMes      IN DATE) IS
  BEGIN

   PKGAFAFER.PGeraPerAquisFerias(pVinculo       => pVinculo,
                                 pCdAgrupamento => pCdAgrupamento,
                                 pCdOrgao       => pCdOrgao,
                                 pDtInicioMes   => pDtInicioMes,
                                 pDtFimMes      => pDtFimMes);

  END;

  PROCEDURE PGeraPerAquisTempServ(pVinculo           IN PKGPAG_TIPO.rVinculo,
                                  pCdOrgao           IN INTEGER,
                                  pDtInicioMes       IN DATE,
                                  pDtFimMes          IN DATE,
                                  pTpOrigemChamada   IN INTEGER DEFAULT 1, -- 1 Processamento de folha, 2 via aplicacao
                                  pFlFazRollback     IN CHAR DEFAULT 'S',
                                  pFlReGerarUltimoPA IN CHAR DEFAULT 'N',
                                  pNuCpfCadastrador  IN CHAR DEFAULT NULL,
                                  pCdRetorno         OUT INTEGER) IS
  BEGIN

    PKGBPCATS.PGeraPerAquisTempServ(pVinculo           => pVinculo,
                                    pCdOrgao           => pCdOrgao,
                                    pDtInicioMes       => pDtInicioMes,
                                    pDtFimMes          => pDtFimMes,
                                    pTpOrigemChamada   => pTpOrigemChamada,
                                    pFlFazRollback     => pFlFazRollback,
                                    pFlReGerarUltimoPA => pFlReGerarUltimoPA,
                                    pNuCpfCadastrador  => pNuCpfCadastrador,
                                    pCdRetorno         => pCdRetorno);

  END;

  PROCEDURE PGeraPerAquisLicPre(pVinculo             IN PKGPAG_TIPO.rVinculo,
                                pDtFimMes            IN DATE,
                                pTpOrigemChamada     IN INTEGER DEFAULT 1,
                                pCdTipoLicencaPremio IN INTEGER DEFAULT 1,
                                pFlReGerarUltimoPA   IN CHAR DEFAULT 'N') IS
  BEGIN

    PKGAFALP.PGeraPerAquisLicPre(pVinculo             => pVinculo,
                                 pDtFimMes            => pDtFimMes,
                                 pTpOrigemChamada     => pTpOrigemChamada,
                                 pCdTipoLicencaPremio => pCdTipoLicencaPremio,
                                 pFlReGerarUltimoPA   => pFlReGerarUltimoPA);

  END;

  PROCEDURE PGeraPerAquisTSViaAplic(pCdAgrupamento     IN INTEGER,
                                    pCdPessoa          IN INTEGER,
                                    pCdVinculo         IN INTEGER,
                                    pTpOrigemChamada   IN INTEGER DEFAULT 1,
                                    pFlFazRollback     IN CHAR DEFAULT 'S',
                                    pFlReGerarUltimoPA IN CHAR DEFAULT 'N',
                                    pNuCpfCadastrador  IN CHAR DEFAULT NULL,
                                    pCdRetorno         OUT INTEGER) IS
  BEGIN

    PKGBPCATS.PGeraPerAquisTSViaAplic(pCdVinculo         => pCdVinculo,
                                      pTpOrigemChamada   => pTpOrigemChamada,
                                      pFlFazRollback     => pFlFazRollback,
                                      pFlReGerarUltimoPA => pFlReGerarUltimoPA,
                                      pNuCpfCadastrador  => pNuCpfCadastrador,
                                      pCdRetorno         => pCdRetorno);

  END;

  PROCEDURE PParamAdcLicPre(pCdOrgao         IN INTEGER,
                            pCdTipoAdicional IN INTEGER,
                            pDtCalculo       IN DATE) IS
  BEGIN

    PKGAFALP.PParamAdcLicPre(pCdOrgao         => pCdOrgao,
                             pCdTipoAdicional => pCdTipoAdicional,
                             pDtCalculo       => pDtCalculo);

  END;

  PROCEDURE PParamAdcTempServ(pCdAgrupamento   IN INTEGER,
                              pCdOrgao         IN INTEGER,
                              pNuAnoReferencia IN INTEGER,
                              pNuMesReferencia IN INTEGER) IS
  BEGIN

    PKGBPCATS.PParamAdcTempServ(pCdAgrupamento   => pCdAgrupamento,
                                pCdOrgao         => pCdOrgao,
                                pNuAnoReferencia => pNuAnoReferencia,
                                pNuMesReferencia => pNuMesReferencia);

  END;

  PROCEDURE PParamPerAquisFerias(pCdOrgao IN INTEGER, pDtFimMes IN DATE) IS
  BEGIN

    PKGAFAFER.PParamPerAquisFerias(pCdOrgao  => pCdOrgao,
                                   pDtFimMes => pDtFimMes);

  END;

  PROCEDURE PAtualizaSituacaoErario(pCdVinculo IN INTEGER,
                                    pFolha     IN PKGPAG_TIPO.rFolha) IS
  BEGIN

    PKGAFAUTL.PAtualizaSituacaoErario(pCdVinculo => pCdVinculo,
                                      pFolha     => pFolha);

  END;

  PROCEDURE PAtualizaSituacaoRetro(pCdVinculo IN INTEGER,
                                   pFolha     IN PKGPAG_TIPO.rFolha) IS
  BEGIN

    PKGAFAUTL.PAtualizaSituacaoRetro(pCdVinculo => pCdVinculo,
                                     pFolha     => pFolha);

  END;

  PROCEDURE PAtualizaSituacaoCompensacao(pCdVinculo IN INTEGER,
                                         pFolha     IN PKGPAG_TIPO.rFolha) IS

  vNuAnoMes            INTEGER;

  bFinalizaRet         boolean := false;

  bFinalizaEra         boolean := false;

  function fFinalizaRet (pCdprocessopagretroativo in integer)
  return boolean is

    b integer;

  begin

    b:=0;
    select 1
        into b
        from ERetProcessoPagRetroativo RT
       where RT.CdProcessoPagRetroativo = pCdProcessoPagRetroativo
         and RT.CdSituacaoProcesso  = 3;

    if nvl(b,0) = 1
   then
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

  function fFinalizaEra (pCdProcessoRestituicaoErario in integer)
    return boolean is

    b integer;

  begin

      b:=0;
      select 1
        into b
        from ERepProcessoRestituicaoErario RE
       where RE.CdProcessoRestituicaoErario =  pCdProcessoRestituicaoErario
         and RE.CdSituacaoProcesso  = 3;

    if nvl(b,0) = 1
      then
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

    vNuAnoMes := to_number(LPAD(pFolha.NuAnoReferencia, 4, '0') || LPAD(pFolha.NuMesReferencia, 2, '0'));

    FOR vREC IN (SELECT C.CdCompensaRetroErario,
                        C.CdProcessoPagRetroativo,
                        C.CdProcessoRestituicaoErario,
                        RT.CdSituacaoProcesso         CdSituacaoRetro,
                        RE.CdSituacaoProcesso         CdSitucaoErario
                   FROM ERetCompensaRetroErario C
                  INNER JOIN ERetProcessoPagRetroativo RT
                     ON RT.CdProcessoPagRetroativo =
                        C.CdProcessoPagRetroativo
                  INNER JOIN ERepProcessoRestituicaoErario RE
                     ON RE.CdProcessoRestituicaoErario =
                        C.CdProcessoRestituicaoErario
                  WHERE RT.CdVinculo = pCdVinculo
                    AND C.CdSituacaoProcesso = 2
                    AND C.FlAnulado = PKGPAG_TIPO.cnN) LOOP

      IF fRetornaSaldoRetroativo(vRec.Cdprocessopagretroativo) - fRetornaSaldoErario(vRec.Cdprocessorestituicaoerario) = 0

        THEN
          UPDATE ERetCompensaRetroErario C
             SET C.CdSituacaoProcesso = 3, C.Dtultalteracao = systimestamp
           WHERE C.CdCompensaRetroErario = vRec.CdCompensaRetroErario;

          UPDATE ERetProcessoPagRetroativo RT
             SET RT.CdSituacaoProcesso  = 3,
                 RT.DtUltAlteracao      = systimestamp,
                 RT.NuAnoMesFinalizacao = vNuAnoMes
           WHERE RT.CdProcessoPagRetroativo = vRec.CdProcessoPagRetroativo;

          UPDATE ERepProcessoRestituicaoErario RE
             SET RE.CdSituacaoProcesso  = 3,
                 RE.DtUltAlteracao      = systimestamp,
                 RE.NuAnoMesFinalizacao = vNuAnoMes
           WHERE RE.CdProcessoRestituicaoErario =
                 vRec.CdProcessoRestituicaoErario;

      else
     if fVerificaQuitacaoRetroativo(vRec.Cdprocessopagretroativo) > 0 then

            UPDATE ERetProcessoPagRetroativo RT
             SET RT.CdSituacaoProcesso  = 3,
                 RT.DtUltAlteracao      = systimestamp,
                 RT.NuAnoMesFinalizacao = vNuAnoMes
             WHERE RT.CdProcessoPagRetroativo = vRec.CdProcessoPagRetroativo;

         end if;

         if fVerificaQuitacaoErario(vRec.Cdprocessorestituicaoerario) > 0 then

            UPDATE ERepProcessoRestituicaoErario RE
             SET RE.CdSituacaoProcesso  = 3,
                 RE.DtUltAlteracao      = systimestamp,
                 RE.NuAnoMesFinalizacao = vNuAnoMes
           WHERE RE.CdProcessoRestituicaoErario =  vRec.CdProcessoRestituicaoErario;

         end if;

         bFinalizaEra := fFinalizaEra (vRec.CdProcessoRestituicaoErario);

         bFinalizaRet := fFinalizaRet (vRec.CdProcessoPagRetroativo);

         if bFinalizaEra = true and bFinalizaRet = true then

            UPDATE ERetCompensaRetroErario C
               SET C.CdSituacaoProcesso = 3, C.Dtultalteracao = systimestamp
             WHERE C.CdCompensaRetroErario = vRec.CdCompensaRetroErario;

         end if;

      END IF;

    END LOOP;

  END;

  PROCEDURE PGeraLicPreViaAplic(pCdAgrupamento     IN INTEGER,
                                pCdPessoa          IN INTEGER,
                                pCdVinculo         IN INTEGER,
                                pFlReGerarUltimoPA IN CHAR DEFAULT 'N',
                                pCdRetorno         OUT INTEGER) IS
  BEGIN

    PKGAFALP.PGeraLicPreViaAplic(pCdAgrupamento     => pCdAgrupamento,
                                 pCdPessoa          => pCdPessoa,
                                 pCdVinculo         => pCdVinculo,
                                 pFlReGerarUltimoPA => pFlReGerarUltimoPA,
                                 pCdRetorno         => pCdRetorno);

  END;

  PROCEDURE PGeraPerAquisFeriasPLSQL(pCdOrgao        IN INTEGER,
                                     pNuMatricula    IN INTEGER,
                                     pNuSeqMatricula IN INTEGER,
                                     pDtInicioMes    IN DATE,
                                     pDtFimMes       IN DATE) IS
  BEGIN

    PKGAFAFER.PGeraPerAquisFeriasPLSQL(pCdOrgao        => pCdOrgao,
                                       pNuMatricula    => pNuMatricula,
                                       pNuSeqMatricula => pNuSeqMatricula,
                                       pDtInicioMes    => pDtInicioMes,
                                       pDtFimMes       => pDtFimMes);

  END;

  Procedure pAtualizarConcessaoPosAfastDef(pTpOrigemChamada INTEGER, -- Indica a origem da chamada {1:Calculo; 2:Recalculo; 3: Afastamento Def}
                                           pCdAgrupamento   INTEGER, -- Codigo do Agrupamento
                                           pCdOrgao         INTEGER, -- Codigo do orgao folha ou logado pelo usuario na aplicacao.
                                           pCdVinculo       INTEGER, -- Codigo do vinculo
                                           pCdAfastamento   INTEGER, -- Codigo do Afastamento definitivo que sera avaliado,
                                           -- obrigatorio para opcao 3
                                           pCdRetorno OUT INTEGER) IS
  BEGIN

    PKGAFAUTL.pAtualizarConcessaoPosAfastDef(pTpOrigemChamada => pTpOrigemChamada,
                                             pCdAgrupamento   => pCdAgrupamento,
                                             pCdOrgao         => pCdOrgao,
                                             pCdVinculo       => pCdVinculo,
                                             pCdAfastamento   => pCdAfastamento,
                                             pCdRetorno       => pCdRetorno);

  END;

  FUNCTION Versao RETURN VARCHAR2 IS

  BEGIN
    /*
      $Author: intranet\tiagopc $
      $Date: 2024-06-28 18:47:30 -0300 (sex, 28 jun 2024) $
      $Id: pkgpag_pc.pck 206822 2024-06-28 21:47:30Z intranet\tiagopc $
      $Revision: 206822 $
      $URL: http://10.111.2.21:8080/SIGRH-VS2008/SIGRH_DB/branches/prd/pkgpag_pc.pck $
      $Header: http://10.111.2.21:8080/SIGRH-VS2008/SIGRH_DB/branches/prd/pkgpag_pc.pck 206822 2024-06-28 21:47:30Z intranet\tiagopc $
    */

      RETURN  ('$Revision: 206822 $');

  END;

END PKGPAG_PC;
/
