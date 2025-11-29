create or replace package pkgpag_alimentacao is

   -- Author  : CLAUDIAKZ
   -- Created : 28/10/2015 14:29:50
   -- Purpose :

   -- Public type declarations

   /*
     FUNCTION FAfastamentoDescontaAuxilioAli(pCdAgrupamento                 INTEGER,
                                             pCdMotivoAfastamentoTemporario INTEGER,
                                             pDataAfastamento               DATE) RETURN BOOLEAN;
   
     FUNCTION FRetornaDiasUteis(vdtInicio                IN DATE,
                                vdtFim                   IN DATE,
                                vCdUnidadeOrganizacional IN INTEGER,
                                vFolha                   IN PKGPAG_TIPO.rFolha) RETURN NUMBER;
   
     FUNCTION FCalcularNuDiasUteisSemRelacao(pCdAgrupamento           INTEGER,
                                             pCdOrgao                 INTEGER,
                                             pCdUnidadeOrganizacional INTEGER,
                                             pDtInicioRelacao         DATE,
                                             pDtFimRelacao            DATE,
                                             pDtInicioMesFolha        DATE,
                                             pDtFimMesFolha           DATE,
                                             pCdVinculo               INTEGER) RETURN INTEGER;
   
     FUNCTION FObterValorFixoAuxilioAli(pNuAnoReferencia INTEGER, pNuMesReferencia INTEGER, pCdOrgao INTEGER, pCdRelacaoVinculo INTEGER) RETURN NUMBER;
   
     FUNCTION FObterValorDiarioAuxilioAli(pNuAnoReferencia  INTEGER,
                                          pNuMesReferencia  INTEGER,
                                          pCdOrgao          INTEGER,
                                          pCdRelacaoVinculo INTEGER) RETURN NUMBER;
   
     FUNCTION FContarDiasEntreDatasExcluiFDS(pDataInicial DATE, pDataFinal DATE) RETURN INTEGER;
   
     FUNCTION FObterCdLocalidadeVigenteUO(pCdUO INTEGER, pDataVigencia DATE) RETURN INTEGER;
   
     FUNCTION FFinalDeSemana(pData DATE) RETURN BOOLEAN;
   
     FUNCTION FObterCdAgrupamentoUO(pCdUO INTEGER) RETURN INTEGER;
   
     FUNCTION FUnidadeOrganizacionalDPE(pCdUO INTEGER) RETURN BOOLEAN;
   
     FUNCTION FObterInfoFaltasInjust(pCdOrgao          IN INTEGER,
                                     pCdRelacaoVinculo IN INTEGER,
                                     pCdAgrupamento    IN INTEGER,
                                     pDtInicioMesFolha IN DATE,
                                     pDtFimMesFolha    IN DATE,
                                     pDtIniCHO         IN DATE,
                                     pDtFinalCHO       IN DATE) RETURN tblFaltas;
   
     FUNCTION FObterVlDescFaltasInjust(pFaltas IN tblFaltas) RETURN NUMBER;
   
     FUNCTION FObterDescricaoFaltasInjust(pFaltas IN tblFaltas) RETURN VARCHAR2;
   
     FUNCTION FObterVlAuxilioAliOutrosVinc(pCdVinculo           IN INTEGER,
                                           pNuAno               IN INTEGER,
                                           pNuMes               IN INTEGER,
                                           pFlCalculoDefinitivo IN CHAR) RETURN NUMBER;
   
     FUNCTION FObterIndiceProporcao(pRubrica      IN PKGPAG_TIPO.rRubrica,
                                    pNuCHOPadraoCEF        IN NUMBER,
                                    pNuCargaHoraria        IN NUMBER,
                                    pMediaCHOHoraAtividade IN NUMBER) RETURN NUMBER;
   
   */
   PROCEDURE P040AuxilioAliDecisaoJudicial(pFolha     IN PKGPAG_TIPO.rFolha,
                                           pCdVinculo IN INTEGER,
                                           pRubrica   IN PKGPAG_TIPO.rRubrica);

   PROCEDURE P041AuxilioAlimentacao(pCdVinculo IN INTEGER,
                                    pFolha     IN PKGPAG_TIPO.rFolha,
                                    pRubrica   IN PKGPAG_TIPO.rRubrica,
                                    pCEF       IN PKGPAG_TIPO.tCEF,
                                    pCCO       IN PKGPAG_TIPO.tCCO,
                                    pCCOSubst  IN PKGPAG_TIPO.tCCO);

   PROCEDURE PDescontoDiasAuxAlimEmpresas(pCdVinculo in integer);

end pkgpag_alimentacao;
/
create or replace package body pkgpag_alimentacao is

   TYPE rFalta IS RECORD(
      dtFalta                 DATE,
      nuIndiceFalta           NUMBER,
      vlValeAlimentacaoDiario NUMBER);

   TYPE tblFaltas IS TABLE OF rFalta INDEX BY PLS_INTEGER;

   bDecJudAfastADisposicaoComOnus BOOLEAN;
   bPagouAuxilioDecJud            BOOLEAN;
   vlIndiceAuxAliDecJud           NUMBER(10, 4);
   vCdMotAfastADisposicaoComOnus  INTEGER := 2587; -- AGPE
   vDtFimDisposicao               DATE;
   vtDiaUtilOutrosVinculos        pkgpag_tipo.tDiaUtil;
   vCdVinculo1                    INTEGER;
   vCdVinculo2                    INTEGER;
   vCdVinculo3                    INTEGER;
   vVlIndiceRetroativo            INTEGER := 0;

   cnEvAfProrrogLicencaPremio     CONSTANT INTEGER := 4; --  04 Prorrogação do período aquisitivo de licença prêmio
   cnEvAfPerdaLicencaPremio       CONSTANT INTEGER := 5; --  05 Perda do período aquisitivo de licença prêmio
   cnEvAfProrrogPremioAssiduidade CONSTANT INTEGER := 13; --  13 Prorrogação do período aquisitivo de prêmio assiduidade
   cnEvAfPerdaPremioAssiduidade   CONSTANT INTEGER := 14; --  14 Perda do período aquisitivo de prêmio assiduidade

   TYPE tAfast is record(
      nudiasafastretroanulado NUMBER := 0,
      nudiasafastretro        NUMBER := 0,
      nudiasafastmes          NUMBER := 0,
      nudiassemrelacao        number := 0,
      vltotaldescauxaliretro  NUMBER := 0);

   type recAfastamento is record(
      cdAfastamento INTEGER,
      dtInicio      DATE,
      dtFim         DATE);
   type listaAfastamentos is table of recAfastamento index by pls_integer;

PROCEDURE P_____________DexAuxEmpresas IS
BEGIN
   NULL;
END;

PROCEDURE PDescontoDiasAuxAlimEmpresas(pCdVinculo in integer) is
   
   vNuDiasDesconto INTEGER;
   vNuDiasUteisMes INTEGER;
   vNuDiasCarencia INTEGER;
   
begin
   
   vNuDiasUteisMes := pkgmov.fqtdiautil(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                        PKGPAG_VAR.vgFolha.CdOrgao,
                                        NULL,
                                        PKGPAG_VAR.vgFolha.DtInicioMes,
                                        PKGPAG_VAR.vgFolha.DtFimMes,
                                        0,
                                        'N',
                                        PKGPAG_VAR.vgCalculo.flgeral);
   vNuDiasDesconto := 0;
   
   if PKGPAG_VAR.vgNuDiasAfastDefinitivo > 0 then
      
      for i in PKGPAG_VAR.vgAfastDefinitivo.first .. PKGPAG_VAR.vgAfastDefinitivo.last loop
         
         if trunc(PKGPAG_VAR.vgAfastDefinitivo(i).DtInicioAfa) >=
            trunc(PKGPAG_VAR.vgFolha.DtInicioMes) or
            trunc(PKGPAG_VAR.vgAfastDefinitivo(i).DtFimAfa) <
            trunc(PKGPAG_VAR.vgFolha.DtFimMes) then
            
            vNuDiasDesconto := vNuDiasDesconto +
                               pkgmov.fqtdiautil(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                 PKGPAG_VAR.vgFolha.CdOrgao,
                                                 NULL,
                                                 PKGPAG_VAR.vgAfastDefinitivo    (i).DtInicioAfaNoMes,
                                                 PKGPAG_VAR.vgAfastDefinitivo    (i).DtFimAfaNoMes,
                                                 0,
                                                 'N',
                                                 PKGPAG_VAR.vgCalculo.flgeral);
         else
            
            vNuDiasDesconto := PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite;
            
         end if;
      end loop;
      
   end if;
   
   if PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis > 0 then
      vNuDiasDesconto := vNuDiasDesconto +
                         PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis;
   end if;
   
   if PKGPAG_VAR.vgAfastAuxAlimentacao.count > 0 then
      
      for i in PKGPAG_VAR.vgAfastAuxAlimentacao.first .. PKGPAG_VAR.vgAfastAuxAlimentacao.last loop
         
         vNuDiasCarencia := 0;
         
         begin
            select prz.nudias
              into vNuDiasCarencia
              from eafaeventomotivoafast mm
             inner join eafahisteventomotafast mt
                on mm.cdeventomotivoafast = mt.cdeventomotivoafast
             inner join eafaeventomotivo mot
                on mot.cdhisteventomotafast = mt.cdhisteventomotafast
             inner join eafaeventoprazocarencia prz
                on prz.cdhisteventomotafast = mot.cdhisteventomotafast
             where mm.cdagrupamento = PKGPAG_VAR.vgFolha.CdAgrupamento
               and mm.cdeventoafastamento = 11
               and mot.flcarencia = 'S'
               and mot.cdmotivoafasttemporario = PKGPAG_VAR.vgAfastAuxAlimentacao(i).CdMotivoAfastamento;
         exception
            when no_data_found then
               vNuDiasCarencia := 0;
               
            when others then
               vNuDiasCarencia := 0;
               
         end;
         
         if vNuDiasCarencia = 0 or ((nvl(PKGPAG_VAR.vgAfastAuxAlimentacao(i).DtFimAfa,
                                         PKGPAG_VAR.vgFolha.DtInicioMes) - PKGPAG_VAR.vgAfastAuxAlimentacao(i).DtInicioAfa + 1) >
            vNuDiasCarencia) then
            
            vNuDiasDesconto := vNuDiasDesconto +
                               pkgmov.fqtdiautil(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                 PKGPAG_VAR.vgFolha.CdOrgao,
                                                 NULL,
                                                 PKGPAG_VAR.vgAfastAuxAlimentacao(i).DtInicioAfaNoMes,
                                                 PKGPAG_VAR.vgAfastAuxAlimentacao(i).DtFimAfaNoMes,
                                                 0,
                                                 'N',
                                                 PKGPAG_VAR.vgCalculo.flgeral);
            
         end if;
      end loop;
      
   end if;
   
   if vNuDiasDesconto = vNuDiasUteisMes then
      
      vNuDiasDesconto := PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite;
      
   elsif vNuDiasDesconto > PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite then
      
      vNuDiasDesconto := PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite;
      
   else
      null;
   end if;
   
   if vNuDiasDesconto < PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite AND
      PKGPAG_VAR.vgVinculo.dtdesligamento IS NULL then
      
      PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                            pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                            pCdExpressaoFormCalc  => NULL,
                                            pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                  9,
                                                                                                  582),
                                            pNuSufixoRubrica      => 1,
                                            pVlPagamento          => ((PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite -
                                                                      vNuDiasDesconto) * PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).VlAuxilioCEF),
                                            pVlIndice             => (PKGPAG_VAR.vgAuxilioAli(PKGPAG_VAR.vgFolha.CdOrgao).NuDiasLimite -
                                                                      vNuDiasDesconto),
                                            pCdTipoOrigemRubrica  => 1);
   end if;
   
END;


PROCEDURE P_____________AuxDecisaoJudicial IS
BEGIN
   NULL;
END;


PROCEDURE P040AuxilioAliDecisaoJudicial(pFolha     IN PKGPAG_TIPO.rFolha,
                                        pCdVinculo IN INTEGER,
                                        pRubrica   IN PKGPAG_TIPO.rRubrica) IS
   
   vCdHistDecisaoJudicialAuxAlim INTEGER;
   vvlAuxilio                    NUMBER(13, 2);
   vvlIndice                     NUMBER(10, 4);
   
BEGIN
   
   bPagouAuxilioDecJud := FALSE;
   
   bDecJudAfastADisposicaoComOnus := FALSE;
   
   vlIndiceAuxAliDecJud := 0;
   
   PKGPAG_VAR.vgListaAfastDecJudAlim := NULL;
   
   -- Pode haver mais de uma decisao
   FOR vDecJudAuxAlim IN (SELECT hdj.cdhistdecisaojudicialauxalim,
                                 hdj.vlauxilio,
                                 hdj.vlindice
                            FROM ealidecisaojudicialauxalim dj
                           INNER JOIN ealihistdecisaojudicialauxalim hdj
                              ON dj.cddecisaojudicialauxalim =
                                 hdj.cddecisaojudicialauxalim
                           WHERE dj.cdvinculo = pcdvinculo
                             AND (hdj.nuanoiniciovigencia <
                                 pfolha.nuanoreferencia OR
                                 (hdj.nuanoiniciovigencia =
                                 pfolha.nuanoreferencia AND
                                 hdj.numesiniciovigencia <=
                                 pfolha.numesreferencia))
                             AND (hdj.nuanofimvigencia >
                                 pfolha.nuanoreferencia OR
                                 (hdj.nuanofimvigencia =
                                 pfolha.nuanoreferencia AND
                                 hdj.numesfimvigencia >=
                                 pfolha.numesreferencia) OR
                                 hdj.numesfimvigencia IS NULL)) LOOP
      
      --------------------------------------------------------
      
      vCdHistDecisaoJudicialAuxAlim := vDecJudAuxAlim.CdHistDecisaoJudicialAuxAlim;
      vvlAuxilio                    := vDecJudAuxAlim.VlAuxilio;
      vvlIndice                     := vDecJudAuxAlim.VlIndice;
      
      -- Caso o valor do auxilio seja informado ira pagar a rubrica (01-0153)
      IF NVL(vvlAuxilio, 0) > 0 THEN
         
         bPagouAuxilioDecJud := TRUE;
         
         PKGPAG_EVENTO.PGeraRegistroPagamento(pTipoRegistro        => 1,
                                              pFolha               => pFolha,
                                              pCdVinculo           => pCdVinculo,
                                              pRubrica             => pRubrica,
                                              pFormExpr            => PKGPAG_VAR.vgFormExpr,
                                              pFlPrincipal         => PKGPAG_TIPO.cnS,
                                              pCEF                 => PKGPAG_VAR.vgCEF,
                                              pCCO                 => PKGPAG_VAR.vgCCO,
                                              pCCOSubst            => PKGPAG_VAR.vgCCOSubst,
                                              pFUC                 => PKGPAG_VAR.vgFUC,
                                              pBOL                 => PKGPAG_VAR.vgBOL,
                                              pAPO                 => PKGPAG_VAR.vgAPO,
                                              pVlIndice            => 0,
                                              pValorIntegral       => vvlAuxilio,
                                              pDtCalculo           => PKGPAG_VAR.vDtCalculo,
                                              pCdTipoOrigemRubrica => 3);
         
      ELSE
         
         IF NVL(vvlIndice, 0) > 0 AND
            NVL(vvlIndice, 0) > NVL(vlIndiceAuxAliDecJud, 0) THEN
            vlIndiceAuxAliDecJud := vvlIndice;
         END IF;
         
         FOR vMot IN (SELECT A.CdMotivoAfastTemporario
                        FROM EAliMotAfastHistDecJudicialAux A
                       WHERE A.CdHistDecisaoJudicialAuxAlim =
                             vCdHistDecisaoJudicialAuxAlim) LOOP
            
            PKGPAG_VAR.vgListaAfastDecJudAlim := PKGPAG_VAR.vgListaAfastDecJudAlim || ';' ||
                                                 vMot.CdMotivoAfastTemporario;
            
            IF vMot.Cdmotivoafasttemporario =
               vCdMotAfastADisposicaoComOnus THEN
               bDecJudAfastADisposicaoComOnus := TRUE;
            END IF;
            
         END LOOP;
         
      END IF;
      
   --------------------------------------------------------
      
   END LOOP;
   
   IF PKGPAG_VAR.vgListaAfastDecJudAlim IS NOT NULL THEN
      
      PKGPAG_VAR.vgListaAfastDecJudAlim := PKGPAG_VAR.vgListaAfastDecJudAlim || ';';
      
   END IF;
   
EXCEPTION
   
   WHEN NO_DATA_FOUND THEN
      
      NULL;
      
END;

PROCEDURE P_____________AuxAlimentacao IS
BEGIN
   NULL;
END;


FUNCTION FObterValorDiarioAuxilioAli(pNuAnoReferencia  INTEGER,
                                     pNuMesReferencia  INTEGER,
                                     pCdOrgao          INTEGER,
                                     pCdRelacaoVinculo INTEGER)
   RETURN NUMBER IS
   vValorDiario NUMBER(13, 2) := 0;
BEGIN
   
   SELECT CASE pCdRelacaoVinculo
             WHEN 1 THEN
              NVL(ali.vlauxiliocef, 0)
             WHEN 2 THEN
              NVL(ali.vlauxiliocco, 0)
             ELSE
              0
          END
     INTO vValorDiario
     FROM ealivalorauxilio ali
    WHERE ali.cdorgao = pCdOrgao
      AND ali.nuanoinicio * 100 + ali.numesinicio <=
          pNuAnoReferencia * 100 + pNuMesReferencia
      AND (ali.nuanofim * 100 + ali.numesfim >=
          pNuAnoReferencia * 100 + pNuMesReferencia OR
          ali.nuanofim is NULL)
      AND rownum <= 1;
   RETURN vValorDiario;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
   WHEN OTHERS THEN
      RETURN NULL;
END;

FUNCTION FObterValorFixoAuxilioAli(pNuAnoReferencia  INTEGER,
                                   pNuMesReferencia  INTEGER,
                                   pCdOrgao          INTEGER,
                                   pCdRelacaoVinculo INTEGER) RETURN NUMBER IS
   vValorFixo NUMBER(13, 2) := 0;
BEGIN
   
   SELECT CASE pCdRelacaoVinculo
             WHEN 1 THEN
              NVL(ali.vlfixoauxiliocef, 0)
             WHEN 2 THEN
              NVL(ali.vlfixoauxiliocco, 0)
             ELSE
              0
          END
     INTO vValorFixo
     FROM ealivalorauxilio ali
    WHERE ali.cdorgao = pCdOrgao
      AND ali.nuanoinicio * 100 + ali.numesinicio <=
          pNuAnoReferencia * 100 + pNuMesReferencia
      AND (ali.nuanofim * 100 + ali.numesfim >=
          pNuAnoReferencia * 100 + pNuMesReferencia OR
          ali.nuanofim is NULL)
      AND rownum <= 1;
   RETURN vValorFixo;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
   WHEN OTHERS THEN
      RETURN NULL;
END;

FUNCTION FFinalDeSemana(pData DATE) RETURN BOOLEAN IS
   vFds BOOLEAN := FALSE;
BEGIN
   
   IF (to_char(pData, 'D') IN ('1', '7')) THEN
      vFds := true;
   END IF;
   RETURN vFds;
END;

FUNCTION FContarDiasEntreDatasExcluiFDS(pDataInicial DATE,
                                        pDataFinal   DATE) RETURN INTEGER IS
   vDiasUteis INTEGER;
   vDataLoop  DATE;
BEGIN
   
   vDiasUteis := 0;
   vDataLoop  := pDataInicial;
   WHILE vDataLoop <= pDataFinal LOOP
      IF NOT FFinalDeSemana(vDataLoop) THEN
         vDiasUteis := vDiasUteis + 1;
      END IF;
      vDataLoop := vDataLoop + 1;
   END LOOP;
   RETURN vDiasUteis;
END;


FUNCTION FObterCdLocalidadeVigenteUO(pCdUO INTEGER, pDataVigencia DATE)
   RETURN INTEGER IS
   vCdLocalidadeVigente INTEGER;
BEGIN
   
   SELECT ende.cdlocalidade
     INTO vCdLocalidadeVigente
     FROM ecadhistunidadeorganizacional huo, ecadendereco ende
    WHERE ende.cdendereco = huo.cdendereco
      AND huo.cdunidadeorganizacional = pCdUO
      AND pDataVigencia BETWEEN huo.dtiniciovigencia AND
          nvl(huo.dtfimvigencia, pDataVigencia)
      AND rownum <= 1;
   RETURN vCdLocalidadeVigente;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NULL;
END;


FUNCTION FUnidadeOrganizacionalDPE(pCdUO INTEGER) RETURN BOOLEAN IS
   vDPE           BOOLEAN := FALSE;
   vCdAgrupamento INTEGER;
   
   FUNCTION FObterCdAgrupamentoUO(pCdUO INTEGER) RETURN INTEGER IS
      vCdAgrupamento INTEGER;
   BEGIN
      
      select agr.cdagrupamento
        into vCdAgrupamento
        from ecadunidadeorganizacional uni
       inner join ecadorgao org
          on uni.cdorgao = org.cdorgao
       inner join ecadagrupamento agr
          on org.cdagrupamento = agr.cdagrupamento
       where uni.cdunidadeorganizacional = pCdUO;
      
      RETURN vCdAgrupamento;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         RETURN NULL;
   END;  
   
   
BEGIN
   
   vCdAgrupamento := FObterCdAgrupamentoUO(pCdUO);
   vDPE           := (vCdAgrupamento = 176);
   RETURN vDPE;
END;


FUNCTION FParamOrgaoAuxAlimDecJudicial(pfolha                   IN pkgpag_tipo.rfolha,
                                       pcdvinculo               IN INTEGER,
                                       pcdmotivoafasttemporario IN INTEGER,
                                       pcdunidadeorganizacional IN INTEGER,
                                       pcdestruturacarreira     IN INTEGER,
                                       pcdlocalidade            IN INTEGER,
                                       pDataAfastamento         IN DATE)
   RETURN BOOLEAN IS
   vcdhisteventomotafast    INTEGER := 0;
   vnugruposervidorporagrup INTEGER := 0;
   vcdgruposervidorvinculo  INTEGER := 0;
   
   FUNCTION fverificaexcecao(pcdmotivoafasttemporario IN INTEGER,
                             pcdgruposervidorvinculo  IN INTEGER,
                             pcdlocalidade            IN INTEGER,
                             pcdorgao                 IN INTEGER,
                             pcdunidadeorganizacional IN INTEGER,
                             pcdestruturacarreira     IN INTEGER)
      RETURN BOOLEAN IS
      
      --cdmotivoafasttemporario INTEGER;
      
   BEGIN
      
      -- Verifica as Exceções
      FOR afast IN (SELECT COUNT(*) num
                      FROM eafaeventomotivo em
                     INNER JOIN eafaeventomotivoexcecao ex
                        ON ex.cdeventomotivo = em.cdeventomotivo
                     WHERE em.cdmotivoafasttemporario =
                           pcdmotivoafasttemporario
                       AND (NOT EXISTS
                            (SELECT 1
                               FROM eafaeventomotivogruposervidor egptodos
                              WHERE egptodos.cdeventomotivo =
                                    ex.cdeventomotivo) OR EXISTS
                            (SELECT 1
                               FROM eafaeventomotivogruposervidor egpint
                              WHERE egpint.cdeventomotivo =
                                    ex.cdeventomotivo
                                AND egpint.cdeventogruposervidor =
                                    pcdgruposervidorvinculo))
                       AND (ex.cdorgao is null or ex.cdorgao = pcdorgao)
                       AND (ex.cdlocalidade IS NULL OR
                           ex.cdlocalidade = pcdlocalidade)
                       AND (ex.cdunidadeorganizacional IS NULL OR
                           ex.cdunidadeorganizacional IN
                           (SELECT vxuo.cdunidadeorganizacional
                               FROM vcadunidadeorganizacional vxuo
                              START WITH vxuo.cdunidadeorganizacional =
                                         pcdunidadeorganizacional
                             CONNECT BY PRIOR vxuo.cduosuphierarq =
                                         vxuo.cdunidadeorganizacional))
                       AND (ex.cdestruturacarreira IS NULL OR
                           ex.cdestruturacarreira IN
                           (SELECT e.cdestruturacarreira
                               FROM ecadestruturacarreira e
                              WHERE e.flanulado = 'N'
                              START WITH e.cdestruturacarreira =
                                         pcdestruturacarreira
                             CONNECT BY PRIOR e.cdestruturacarreirapai =
                                         e.cdestruturacarreira))) LOOP
         
         IF afast.num > 0 THEN
            RETURN TRUE;
         ELSE
            RETURN FALSE;
         END IF;
      END LOOP;
   END;
   
BEGIN
   
   SELECT hfm.cdhisteventomotafast cdhisteventomotafast
     INTO vcdhisteventomotafast
     FROM eafaeventomotivoafast fma
    INNER JOIN eafahisteventomotafast hfm
       ON fma.cdeventomotivoafast = hfm.cdeventomotivoafast
    WHERE fma.cdagrupamento = pfolha.cdagrupamento
      AND fma.cdeventoafastamento = 11 -- aux alimentacao
      AND hfm.flanulado = 'N'
      AND hfm.dtiniciovigencia <= pDataAfastamento
      AND (hfm.dtfimvigencia IS NULL OR
          hfm.dtfimvigencia >= pDataAfastamento);
   
   FOR vgrupmotiafast IN (SELECT DISTINCT gm.cdgrupomotivoafastamento cdgrupomotivoafastamento,
                                          gm.nmgrupomotivoafastamento nmgrupomotivoafastamento,
                                          m.cdhisteventomotafast      cdhisteventomotafast,
                                          m.cdmotivoafasttemporario   cdmotivoafasttemporario,
                                          mt.flconfirmaretorno        flconfirmaretorno,
                                          mt.demotivoafasttemporario  demotivoafasttemporario,
                                          m.cdeventomotivo            cdeventomotivo
                          --   'T' fltipoafastamento
                            FROM eafaeventomotivo m
                           INNER JOIN eafahistmotivoafasttemp mt
                              ON m.cdmotivoafasttemporario =
                                 mt.cdmotivoafasttemporario
                           INNER JOIN eafagrupomotivoafastamento gm
                              ON mt.cdgrupomotivoafastamento =
                                 gm.cdgrupomotivoafastamento
                          -- NmEventoAfasta: Apuração de dias para auxílio alimentação
                           WHERE m.cdhisteventomotafast =
                                 vcdhisteventomotafast --1401 para AGPE
                             AND mt.flanulado LIKE 'N'
                             AND mt.dtiniciovigencia <= pDataAfastamento
                             AND (mt.dtfimvigencia IS NULL OR
                                 mt.dtfimvigencia >= pDataAfastamento)
                             
                          ) LOOP
      
      -- Caso o valor do auxilio seja informado ira pagar a rubrica (01-0153)
      IF vgrupmotiafast.cdmotivoafasttemporario =
         pcdmotivoafasttemporario THEN
         
         BEGIN
            SELECT COUNT(*)
              INTO vnugruposervidorporagrup
              FROM eafaeventogruposervidor egs
             INNER JOIN ecadorgao org
                ON (org.cdagrupamento = egs.cdagrupamento)
             WHERE org.cdorgao = pfolha.cdorgao
               AND egs.cdeventoafastamento = 11; --aux alim
            
         EXCEPTION
            WHEN no_data_found THEN
               vnugruposervidorporagrup := 0;
         END;
         
         IF vnugruposervidorporagrup > 0 THEN
            -- Encontra o Evento de Grupo do Servidor
            SELECT CASE 11
                      WHEN cnevafprorroglicencapremio THEN
                       v.cdeventogruposervprorrlp
                      WHEN cnevafprorrogpremioassiduidade THEN
                       v.cdeventogruposervprorrpa
                      WHEN cnevafperdalicencapremio THEN
                       v.cdeventogruposervperdalp
                      WHEN cnevafperdapremioassiduidade THEN
                       v.cdeventogruposervperdapa
                      ELSE
                       NULL
                   END
              INTO vcdgruposervidorvinculo
              FROM ecadvinculo v
             WHERE v.cdvinculo = pcdvinculo;
            
            vcdgruposervidorvinculo := nvl(vcdgruposervidorvinculo, 0);
         ELSE
            
            vcdgruposervidorvinculo := 0;
         END IF;
         
         RETURN fverificaexcecao(pcdmotivoafasttemporario,
                                 vcdgruposervidorvinculo,
                                 pcdlocalidade,
                                 pfolha.CdOrgao,
                                 pcdunidadeorganizacional,
                                 pcdestruturacarreira);
      END IF;
      
   END LOOP;
   
EXCEPTION
   
   WHEN no_data_found THEN
      RETURN FALSE;
      
END;


FUNCTION FCalculadiasafastamentomes(pcdvinculo               IN INTEGER,
                                    pfolha                   IN pkgpag_tipo.rfolha,
                                    pcdunidadeorganizacional IN INTEGER,
                                    pCdEstruturaCarreira     IN INTEGER default null,
                                    pnucargahoraria          IN NUMBER,
                                    pnucargahorariatotal     IN NUMBER,
                                    pDtInicioRelacao         IN DATE,
                                    pDtFimRelacao            IN DATE,
                                    pNuDiasSemRelacao        out NUMBER,
                                    pNuDiasAfastMes          out NUMBER,
                                    pNuTotalMaximoVales      in integer,
                                    pFlAfastadoMesTodo       in out CHAR)
   
 RETURN number IS
   
   vnudiasuteis  NUMBER;
   vCdLocalidade INTEGER := 0;
   --cdAgrupamento INTEGER;
   unidadeOrganizacionalDPE BOOLEAN;
   bAdicionou               BOOLEAN := FALSE;
   
BEGIN
   
   --inicializar variavel
   vnudiasuteis             := 0;
   pNuDiasAfastMes          := 0;
   pNuDiasSemRelacao        := 0;
   unidadeOrganizacionalDPE := pkgpag_alimentacao.FUnidadeOrganizacionalDPE(pcdunidadeorganizacional);
   
   if pDtInicioRelacao > pFolha.DtInicioMes then
      pnudiassemrelacao := pDtInicioRelacao - pFolha.DtInicioMes;
   end if;
   
   if pDtFimRelacao < pFolha.DtFimMes then
      pnudiassemrelacao := pnudiassemrelacao + pFolha.DtFimMes -
                           pDtFimRelacao + 1;
   end if;
   
   vcdlocalidade := pkgpag_alimentacao.FObterCdLocalidadeVigenteUO(pcdunidadeorganizacional,
                                                                   pfolha.DtFimMes);
   
   FOR vafast IN (WITH afast_datas AS
                      (
                         
                      SELECT av.cdvinculo cdvinculo,
                              av.cdferiasprogramacaousufruto cdferiasprogramacaousufruto,
                              av.cdmotivoafasttemporario cdmotivoafastamento,
                              greatest(av.dtinicio, pFolha.DtInicioMes) dtinicio,
                              least(pFolha.DtFimMes,
                                    nvl(av.dtfim, pFolha.DtFimMes)) dtfim,
                              av.flanulado flanulado,
                              av.dtinclusao dtinclusao,
                              av.dtanulado dtanulado,
                              nvl(hmat.vlpercentreducaoauxalim, 100) percreduc,
                              CASE
                                 WHEN nvl(hmat.vlpercentreducaoauxalim, 100) <> 0 THEN
                                  (nvl(hmat.vlpercentreducaoauxalim, 100) / 100)
                                 ELSE
                                  1
                              END vlpercreduc
                        FROM eafaafastamentovinculo av
                       INNER JOIN eafamotivoafasttemporario mat
                          ON av.cdmotivoafasttemporario =
                             mat.cdmotivoafasttemporario
                       INNER JOIN eafahistmotivoafasttemp hmat
                          ON mat.cdmotivoafasttemporario =
                             hmat.cdmotivoafasttemporario
                       WHERE av.cdvinculo = pcdvinculo
                         AND hmat.dtiniciovigencia <= pfolha.dtcalculo
                         AND (hmat.dtfimvigencia IS NULL OR
                             hmat.dtfimvigencia >= pfolha.dtiniciomes)
                         AND hmat.flanulado = pkgpag_tipo.cnn
                         AND av.dtinicio <= pfolha.dtfimmes
                         AND (av.dtfim >= pfolha.dtiniciomes or
                             av.dtfim is null)
                         and av.flanulado = 'N'),
                     dias_mes as
                      (select level n from dual connect by level <= 31),
                     afast_por_mes as
                      (select distinct a.*, level - 1 as n
                        from afast_datas a
                      connect by level <=
                                 months_between(trunc(a.dtfim, 'mm'),
                                                trunc(a.dtinicio, 'mm')) + 1),
                     afast_por_dia as
                      (select afast_por_mes.*,
                             trunc(add_months(afast_por_mes.dtinicio,
                                              afast_por_mes.n),
                                   'MM') + dias_mes.n - 1 as diaafast
                        from afast_por_mes
                       inner join dias_mes
                          on trunc(add_months(afast_por_mes.dtinicio,
                                              afast_por_mes.n),
                                   'MM') + dias_mes.n - 1 >=
                             trunc(afast_por_mes.dtinicio)
                         and trunc(add_months(afast_por_mes.dtinicio,
                                              afast_por_mes.n),
                                   'MM') + dias_mes.n - 1 <=
                             trunc(afast_por_mes.dtfim))
                        
                     select a.flanulado,
                            a.diaafast,
                            a.cdmotivoafastamento,
                            a.percreduc,
                            a.vlpercreduc,
                            max(a.dtanulado) as dtanulado,
                            a.dtinicio,
                            a.dtfim
                       from afast_por_dia a
                      group by a.flanulado,
                               a.cdmotivoafastamento,
                               a.diaafast,
                               percreduc,
                               vlpercreduc,
                               a.dtinicio,
                               a.dtfim
                      order by a.flanulado,
                               a.cdmotivoafastamento,
                               a.diaafast
                        
                  ) LOOP
      
      if PKGPAG_VAR.vglistaeventoafast11.exists(vafast.cdmotivoafastamento) then
         
         IF (PKGPAG_VAR.vglistaafastdecjudalim IS NOT NULL AND
            NOT nvl(instr(PKGPAG_VAR.vglistaafastdecjudalim,
                           ';' || vafast.cdmotivoafastamento || ';'),
                     0) = 0) OR
            (fparamorgaoauxalimdecjudicial(pfolha,
                                           pcdvinculo,
                                           vafast.cdmotivoafastamento,
                                           pcdunidadeorganizacional,
                                           pCdEstruturaCarreira,
                                           vCdLocalidade,
                                           vafast.diaafast)) THEN
            
            continue;
            
         ELSE
            
            if trunc(vAfast.DtInicio) <= trunc(pFolha.DtInicioMes) and
               trunc(vAfast.DtFim) >= trunc(pFolha.DtFimMes) then
               
               pFlAfastadoMesTodo := 'S';
               
               if PKGPAG_VAR.vgAuxilioAli(pFolha.CdOrgao).NuDias is not null then
                  
                  IF NVL(vafast.vlpercreduc, 0) > 0 then
                     pnudiasafastmes := (PKGPAG_VAR.vgAuxilioAli(pFolha.CdOrgao)
                                        .NuDias * vafast.vlpercreduc) *
                                        (pnucargahoraria /
                                        pnucargahorariatotal);
                  ELSE
                     pnudiasafastmes := PKGPAG_VAR.vgAuxilioAli(pFolha.CdOrgao).NuDias;
                  END IF;
                  
                  return 0;
               else
                  return pNuTotalMaximoVales;
               end if;
               
            end if;
            
            if (unidadeOrganizacionalDPE) then
               if pkgpag_alimentacao.FFinalDeSemana(vAfast.DiaAfast) then
                  vnudiasuteis := 0;
               else
                  vnudiasuteis := 1;
               end if;
            else
               /*vnudiasuteis := pkgmov.fqtdiautil(pcdagrupamento          => pfolha.cdagrupamento,
               pcdorgao                 => pfolha.cdorgao,
               pcdunidadeorganizacional => pcdunidadeorganizacional, -- pcef(i).cdunidadeorganizacional,
               pdtinicio                => vAfast.DiaAfast,
               pdtfim                   => vAfast.DiaAfast,
               peventoauxilioalim       => 'S',
               pflcalculogeral          => PKGPAG_VAR.vgCalculo.flgeral);*/
               
               vnudiasuteis := 1;
               
            end if;
            
            IF pFolha.CdAgrupamento = 1 THEN
               
               IF TO_CHAR(vAfast.DtFim, 'MM') = 2 THEN
                  
                  IF TO_CHAR(vAfast.DtFim, 'DD') = 28 AND NOT bAdicionou THEN
                     
                     bAdicionou := TRUE;
                     
                     vNuDiasUteis := vNuDiasUteis + 2;
                     
                  ELSIF TO_CHAR(vAfast.DtFim, 'DD') = 29 AND
                        NOT bAdicionou THEN
                     
                     bAdicionou := TRUE;
                     
                     vNuDiasUteis := vNuDiasUteis + 1;
                     
                  END IF;
                  
               END IF;
               
            END IF;
            
            pnudiasafastmes := nvl(pnudiasafastmes, 0) +
                               ((vNuDiasUteis * vafast.vlpercreduc) *
                                (pnucargahoraria / pnucargahorariatotal));
            
            continue;
            
         END IF;
         
      end if;
      
   END LOOP;
   
   RETURN pnudiasafastmes;
   
exception
   when no_data_found then
      return 0;
      
   when others then
      return 0;
END;


FUNCTION FRetornaDiasUteisExt (vdtInicio                IN DATE,
                               vdtFim                   IN DATE,
                               vCdUnidadeOrganizacional IN INTEGER,
                               vFolha                   IN PKGPAG_TIPO.rFolha)
   
 RETURN NUMBER IS
   
   vNudias NUMBER := 0;
   
BEGIN
   
   vNudias := PKGMOV.FQTDIAUTIL(pcdagrupamento           => vfolha.cdagrupamento,
                                pcdorgao                 => vfolha.cdorgao,
                                pcdunidadeorganizacional => vcdunidadeorganizacional,
                                pdtinicio                => vdtinicio,
                                pdtfim                   => vdtfim,
                                peventoauxilioalim       => 'S',
                                pflcalculogeral          => PKGPAG_VAR.vgCalculo.flgeral);
   
   RETURN nvl(vNudias, 0);
   
EXCEPTION
   
   WHEN NO_DATA_FOUND THEN
      RETURN 0;
      
   WHEN OTHERS THEN
      RETURN 0;
      
END;


FUNCTION FAfastamentoDescontaAuxilioAli(pCdAgrupamento                 INTEGER,
                                        pCdMotivoAfastamentoTemporario INTEGER,
                                        pDataAfastamento               DATE)
   RETURN BOOLEAN IS
   vQtd INTEGER := 0;
BEGIN
   
   select count(*) as qtd
     into vQtd
     from eafahisteventomotafast hmot
    inner join eafaeventomotivoafast emt
       on hmot.cdeventomotivoafast = emt.cdeventomotivoafast
      AND hmot.dtiniciovigencia <= pDataAfastamento
      AND (hmot.dtfimvigencia >= pDataAfastamento OR
          hmot.dtfimvigencia IS NULL)
      AND emt.cdeventoafastamento = 11
      AND hmot.flanulado = 'N'
    inner join eafaeventomotivo emm
       on emm.cdhisteventomotafast = hmot.cdhisteventomotafast
    WHERE emt.cdagrupamento = pCdAgrupamento
      AND emm.cdmotivoafasttemporario = pCdMotivoAfastamentoTemporario
      AND rownum <= 1;
   
   RETURN vQtd > 0;
END;

FUNCTION FHouvePagamento(pcdvinculo        IN INTEGER,
                         pfolha            IN pkgpag_tipo.rfolha,
                         pAfastAuxilioAlim pkgpag_alimentacao.listaAfastamentos,
                         pafastanulado     IN CHAR DEFAULT 'N')
   RETURN BOOLEAN IS
   j                  INTEGER;
   vvlvalorretroativo INTEGER := 0;
BEGIN
   
   --Seleciona o período do Afastamento incluído entre a data calculo anterior e calculo do mês
   j := pAfastAuxilioAlim.FIRST;
   WHILE j IS NOT NULL LOOP
      --Para afastamentos retroativos apenas
      IF pAfastAuxilioAlim(j).dtinicio < pfolha.dtiniciomes THEN
         
         FOR folha IN (SELECT p.cdfolhapagamento AS cdfolhapagamento
                         FROM epagfolhapagamento p
                        WHERE p.flcalculodefinitivo = 'S'
                          AND p.nuanomesreferencia BETWEEN
                              to_number(to_char(pAfastAuxilioAlim(j).dtinicio,
                                                'YYYYMM')) AND
                              to_number(to_char(pAfastAuxilioAlim(j).dtfim,
                                                'YYYYMM'))
                          AND p.cdorgao = pfolha.cdorgao
                        ORDER BY cdfolhapagamento) LOOP
            --Verifica se houve pagamento
            FOR dados IN (SELECT rv.vlproporcional  AS vlpagamento,
                                 rv.vlindicerubrica vlindice
                            FROM epaghistoricorubricarelvinc rv
                           INNER JOIN vpagrubricaagrupamento v
                              ON v.cdrubricaagrupamento =
                                 rv.cdrubricaagrupamento
                             AND v.nurubrica = 157
                             AND v.cdtiporubrica = CASE
                                    WHEN pafastanulado = 'N' THEN
                                     1
                                    ELSE
                                     5
                                 END
                             AND v.cdagrupamento = pfolha.cdagrupamento
                           WHERE rv.cdvinculo = pcdvinculo
                             AND rv.cdfolhapagamento IN
                                 folha.cdfolhapagamento) LOOP
               
               --Soma os valores pagos
               vvlvalorretroativo  := vvlvalorretroativo +
                                      dados.vlpagamento;
               vvlindiceretroativo := dados.vlindice;
            END LOOP;
         END LOOP;
         
      END IF;
      j := pAfastAuxilioAlim.NEXT(j);
   END LOOP;
   
   --Se não houve pagamento no período determinado não gera o desconto
   --Se o afastamento foi incluído agora referente
   IF vvlvalorretroativo > 0 THEN
      RETURN TRUE;
   ELSE
      RETURN FALSE;
   END IF;
END;


FUNCTION FCalculadiasafastamentoretro(pcdvinculo               IN INTEGER,
                                      pfolha                   IN pkgpag_tipo.rfolha,
                                      pcdunidadeorganizacional IN INTEGER,
                                      pCdEstruturaCarreira     IN INTEGER default null,
                                      pnucargahoraria          IN NUMBER,
                                      pnucargahorariatotal     IN NUMBER,
                                      pDtInicioRelacao         IN DATE,
                                      pDtFimRelacao            IN DATE,
                                      pCdRubAgrupAuxAlim       IN INTEGER)
   
 RETURN tafast IS
   i                            INTEGER := 0;
   tafastvinc                   tafast;
   vnudiasuteisretro            NUMBER;
   vCdLocalidade                INTEGER := 0;
   vListaAfastamentos           listaAfastamentos;
   vRecAfastamento              recAfastamento;
   vSomaValorAuxilioAlimentacao NUMBER;
   vDtInicio                    DATE;
   vDtFim                       DATE;
   vDtControle                  DATE;
   vNuValesRecebidos            number(5, 2);
   vNuValesPossiveis            number(5, 2);
   vVlAuxilioAliDia             NUMBER;
   
BEGIN
   
   --inicializar variavel
   tafastvinc.nudiasafastretro        := 0;
   tafastvinc.nudiasafastretroanulado := 0;
   tafastvinc.vltotaldescauxaliretro  := 0;
   vnudiasuteisretro                  := 0;
   vcdlocalidade                      := pkgpag_alimentacao.FObterCdLocalidadeVigenteUO(pcdunidadeorganizacional,
                                                                                        pfolha.DtFimMes);
   
   FOR vafast IN (WITH afast_datas AS
                      (
                         
                      SELECT av.cdvinculo cdvinculo,
                              av.cdafastamento cdafastamento,
                              av.cdferiasprogramacaousufruto cdferiasprogramacaousufruto,
                              av.cdmotivoafasttemporario cdmotivoafastamento,
                              least(pFolha.DtFimMes,
                                    nvl(av.dtfim, pFolha.DtFimMes)) dtfim,
                              av.flanulado flanulado,
                              av.dtinicio,
                              av.dtfim dtfimafast,
                              av.dtinclusao dtinclusao,
                              av.dtanulado dtanulado,
                              nvl(hmat.vlpercentreducaoauxalim, 100) percreduc,
                              CASE
                                 WHEN nvl(hmat.vlpercentreducaoauxalim, 100) <> 0 THEN
                                  (nvl(hmat.vlpercentreducaoauxalim, 100) / 100)
                                 ELSE
                                  1
                              END vlpercreduc
                        FROM eafaafastamentovinculo av
                       INNER JOIN eafamotivoafasttemporario mat
                          ON av.cdmotivoafasttemporario =
                             mat.cdmotivoafasttemporario
                       INNER JOIN eafahistmotivoafasttemp hmat
                          ON mat.cdmotivoafasttemporario =
                             hmat.cdmotivoafasttemporario
                       WHERE av.cdvinculo = pcdvinculo
                         AND ((av.flanulado = 'N' AND
                             trunc(av.dtinclusao) BETWEEN
                             trunc(pfolha.dtcalculoant + 1) AND
                             pfolha.dtcalculo) OR (av.flanulado = 'S' AND
                             trunc(av.dtanulado) BETWEEN
                             trunc(pfolha.dtcalculoant + 1) AND
                             pfolha.dtcalculo))
                         AND hmat.dtiniciovigencia <= pfolha.dtcalculo
                         AND (hmat.dtfimvigencia IS NULL OR
                             hmat.dtfimvigencia >= pfolha.dtiniciomes)
                         AND hmat.flanulado = pkgpag_tipo.cnn
                         AND av.dtinicio <= pfolha.dtfimmes
                         AND av.dtinicio >=
                             add_months(pfolha.dtiniciomes, -4)
                       ORDER BY av.dtinclusao ASC),
                     dias_mes as
                      (select level n from dual connect by level <= 31),
                     afast_por_mes as
                      (select distinct a.*, level - 1 as n
                        from afast_datas a
                      connect by level <=
                                 months_between(trunc(a.dtfim, 'mm'),
                                                trunc(a.dtinicio, 'mm')) + 1),
                     afast_por_dia as
                      (select afast_por_mes.*,
                             trunc(add_months(afast_por_mes.dtinicio,
                                              afast_por_mes.n),
                                   'MM') + dias_mes.n - 1 as diaafast
                        from afast_por_mes
                       inner join dias_mes
                          on trunc(add_months(afast_por_mes.dtinicio,
                                              afast_por_mes.n),
                                   'MM') + dias_mes.n - 1 >=
                             trunc(afast_por_mes.dtinicio)
                         and trunc(add_months(afast_por_mes.dtinicio,
                                              afast_por_mes.n),
                                   'MM') + dias_mes.n - 1 <=
                             trunc(afast_por_mes.dtfim))
                        
                     select a.cdafastamento,
                            a.flanulado,
                            a.diaafast,
                            a.cdmotivoafastamento,
                            a.percreduc,
                            a.vlpercreduc,
                            max(a.dtanulado) as dtanulado,
                            max(a.dtinclusao) as dtinclusao,
                            max(a.dtinicio) as dtinicio,
                            max(a.dtfimafast) dtfimafast
                       from afast_por_dia a
                      where a.diaafast < pFolha.DtInicioMes
                      group by a.cdafastamento,
                               a.flanulado,
                               a.cdmotivoafastamento,
                               a.diaafast,
                               percreduc,
                               vlpercreduc
                      order by a.flanulado,
                               a.cdmotivoafastamento,
                               a.diaafast
                        
                  ) loop
      
      if FAfastamentoDescontaAuxilioAli(pCdAgrupamento                 => pfolha.cdagrupamento,
                                        pCdMotivoAfastamentoTemporario => vafast.cdmotivoafastamento,
                                        pDataAfastamento               => vafast.diaafast) THEN
         
         vDtInicio                    := last_day(add_months(vAfast.DiaAfast,
                                                             -1)) + 1;
         vDtFim                       := last_day(vAfast.DiaAfast);
         vSomaValorAuxilioAlimentacao := pkgpag_geral.fretornasomavalorrubrica(vDtInicio,
                                                                               vDtFim,
                                                                               pcdvinculo,
                                                                               pCdRubAgrupAuxAlim,
                                                                               pfolha.CdTipoFolha,
                                                                               pfolha.CdTipoCalculo);
         if vSomaValorAuxilioAlimentacao = 0 then
            continue;
         end if;
         
         vRecAfastamento := null;
         vRecAfastamento.cdAfastamento := vafast.cdafastamento;
         vRecAfastamento.dtInicio := vafast.dtinicio;
         vRecAfastamento.dtFim := vafast.dtfimafast;
         vListaAfastamentos(vafast.cdafastamento) := vRecAfastamento;
         
         vnudiasuteisretro := pkgmov.fqtdiautil(pcdagrupamento           => pfolha.cdagrupamento,
                                                pcdorgao                 => pfolha.cdorgao,
                                                pcdunidadeorganizacional => pcdunidadeorganizacional, -- pcef(i).cdunidadeorganizacional,
                                                pdtinicio                => greatest(vafast.diaafast,
                                                                                     to_date('01/' ||
                                                                                             to_char(vafast.diaafast,
                                                                                                     'mm/yyyy'),
                                                                                             'dd/mm/yyyy')),
                                                pdtfim                   => least(vafast.diaafast,
                                                                                  last_day(pfolha.dtcalculoant)),
                                                peventoauxilioalim       => 'S',
                                                pflcalculogeral          => PKGPAG_VAR.vgCalculo.flgeral);
         
         -- Trata afastamentos que foram anulados após a folha anterior
         case
            when (vafast.flanulado = 'S' AND
                 vafast.dtanulado BETWEEN
                 trunc(pfolha.dtcalculoant + 1) AND pfolha.dtcalculo) THEN
               
               i := i + 1;
               if i = 1 then
                  vDtControle := vafast.diaafast;
               end if;
               
               -- Verificar se quantidade de vales recebidos foi igual aos vales possiveis e descontar estornos indevidos
               if pkgpag_geral.fretornaindicerubrica(pFolha.CdFolhaPagamento,
                                                     pcdvinculo,
                                                     pCdRubAgrupAuxAlim,
                                                     null,
                                                     null,
                                                     vafast.diaafast) =
                  FRetornaDiasUteisExt(vDtInicio,
                                       vDtFim,
                                       PKGPAG_VAR.vgcef(1).CdUnidadeOrganizacional,
                                       pKGPAG_VAR.vgFolha) and
               pFolha.CdAgrupamento <> 176 then
                  continue;
               end if;
               
               if (PKGPAG_VAR.vglistaafastdecjudalim IS NOT NULL AND
                  NOT nvl(instr(PKGPAG_VAR.vglistaafastdecjudalim,
                                 ';' || vafast.cdmotivoafastamento || ';'),
                           0) = 0) OR
                  (fparamorgaoauxalimdecjudicial(pfolha,
                                                 pcdvinculo,
                                                 vafast.cdmotivoafastamento,
                                                 pcdunidadeorganizacional,
                                                 pCdEstruturaCarreira,
                                                 vCdLocalidade,
                                                 vafast.diaafast)) then
                  continue;
               else
                  if i = 1 or vafast.diaafast > vDtControle then
                     -- aplica o percentual de reducao, quando houver
                     tafastvinc.nudiasafastretroanulado := nvl(tafastvinc.nudiasafastretroanulado,
                                                               0) +
                                                           (vnudiasuteisretro *
                                                            vafast.vlpercreduc) *
                                                           (pnucargahoraria /
                                                            pnucargahorariatotal);
                  end if;
               end if;
               
               vDtControle := vafast.diaafast;
               
            when vafast.flanulado = 'N' then
               
               if (PKGPAG_VAR.vglistaafastdecjudalim IS NOT NULL AND
                  NOT nvl(instr(PKGPAG_VAR.vglistaafastdecjudalim,
                                 ';' || vafast.cdmotivoafastamento || ';'),
                           0) = 0) OR
                  (fparamorgaoauxalimdecjudicial(pfolha,
                                                 pcdvinculo,
                                                 vafast.cdmotivoafastamento,
                                                 pcdunidadeorganizacional,
                                                 pCdEstruturaCarreira,
                                                 vCdLocalidade,
                                                 vafast.diaafast)) then
                  
                  continue;
                  
               else
                  
                  --soma o numero de dias que foram usufruidos
                  tafastvinc.nudiasafastretro := nvl(tafastvinc.nudiasafastretro,
                                                     0) +
                                                 ((vnudiasuteisretro *
                                                  vafast.vlpercreduc) *
                                                  (pnucargahoraria /
                                                  pnucargahorariatotal));
                  
                  vVlAuxilioAliDia := FObterValorDiarioAuxilioAli(pNuAnoReferencia  => EXTRACT(YEAR FROM
                                                                                               vafast.diaafast),
                                                                  pNuMesReferencia  => EXTRACT(MONTH FROM
                                                                                               vafast.diaafast),
                                                                  pCdOrgao          => pFolha.CdOrgao,
                                                                  pCdRelacaoVinculo => PKGPAG_VAR.vgRelVincPrincipal.Tipo);
                  
                  tafastvinc.vltotaldescauxaliretro := tafastvinc.vltotaldescauxaliretro +
                                                       (vVlAuxilioAliDia *
                                                       ((vnudiasuteisretro *
                                                       vafast.vlpercreduc) *
                                                       (pnucargahoraria /
                                                       pnucargahorariatotal)));
                  
                  if nvl(tafastvinc.nudiasafastretroanulado, 0) >
                     nvl(tafastvinc.nudiasafastretro, 0) THEN
                     
                     tafastvinc.nudiasafastretroanulado := nvl(tafastvinc.nudiasafastretroanulado,
                                                               0) -
                                                           tafastvinc.nudiasafastretro;
                     tafastvinc.nudiasafastretro        := 0;
                     
                  end if;
                  
               end if;
               
            else
               
               null;
               
         end case;
         
      end if;
      
   end loop;
   
   IF tafastvinc.nudiasafastretro >= tafastvinc.nudiasafastretroanulado THEN
      
      tafastvinc.nudiasafastretro        := tafastvinc.nudiasafastretro -
                                            tafastvinc.nudiasafastretroanulado;
      tafastvinc.nudiasafastretroanulado := 0;
   ELSIF tafastvinc.nudiasafastretroanulado >=
         tafastvinc.nudiasafastretro THEN
      
      tafastvinc.nudiasafastretroanulado := tafastvinc.nudiasafastretroanulado -
                                            tafastvinc.nudiasafastretro;
      tafastvinc.nudiasafastretro        := 0;
   END IF;
   
   IF nvl(tafastvinc.nudiasafastretro, 0) > 0 AND
      NOT FHouvePagamento(pcdvinculo, pfolha, vListaAfastamentos, 'N') THEN
      tafastvinc.nudiasafastretro := 0;
   END IF;
   
   RETURN tafastvinc;
   
exception
   when no_data_found then
      RETURN tafastvinc;
      
   when others then
      RETURN tafastvinc;
      
END;


FUNCTION FCalcularNuDiasUteisSemRelacao(pCdAgrupamento           INTEGER,
                                        pCdOrgao                 INTEGER,
                                        pCdUnidadeOrganizacional INTEGER,
                                        pDtInicioRelacao         DATE,
                                        pDtFimRelacao            DATE,
                                        pDtInicioMesFolha        DATE,
                                        pDtFimMesFolha           DATE,
                                        pCdVinculo               INTEGER)
   RETURN INTEGER IS
   vNuDias              INTEGER := 0;
   vNuDiasOutroOrgaoMes INTEGER := 0;
BEGIN
   
   /* BEGIN
       SELECT pDtInicioRelacao - cco.dtfim
         INTO vNuDiasOutroOrgaoMes
         FROM ecadhistcargocom cco
        WHERE cco.cdvinculo = pCdVinculo
          AND (cco.dtinicio < pDtInicioRelacao AND cco.dtfim >= pDtInicioMesFolha);
     EXCEPTION
       WHEN OTHERS THEN
         vNuDiasOutroOrgaoMes := 0;
     END;
   */
   IF (pDtInicioRelacao > pDtInicioMesFolha) THEN
      IF pCdAgrupamento IN (1, 134) THEN
         vNuDias := vNuDias - vNuDiasOutroOrgaoMes +
                    PKGMOV.FQTDIAUTIL(pcdagrupamento           => pCdAgrupamento,
                                      pcdorgao                 => pCdOrgao,
                                      pcdunidadeorganizacional => pCdUnidadeOrganizacional,
                                      pdtinicio                => pDtInicioRelacao,
                                      pdtfim                   => pDtFimMesFolha,
                                      pflcalculogeral          => PKGPAG_VAR.vgCalculo.flgeral);
      ELSE
         vNuDias := vNuDias +
                    PKGMOV.FQTDIAUTIL(pcdagrupamento           => pCdAgrupamento,
                                      pcdorgao                 => pCdOrgao,
                                      pcdunidadeorganizacional => pCdUnidadeOrganizacional,
                                      pdtinicio                => pDtInicioMesFolha,
                                      pdtfim                   => pDtInicioRelacao - 1,
                                      pflcalculogeral          => PKGPAG_VAR.vgCalculo.flgeral);
      END IF;
      
   END IF;
   
   IF (pDtFimRelacao < pDtFimMesFolha) THEN
      
      IF pCdAgrupamento IN (1, 134) THEN
         
         vNuDias := vNuDias +
                    PKGMOV.FQTDIAUTIL(pcdagrupamento           => pCdAgrupamento,
                                      pcdorgao                 => pCdOrgao,
                                      pcdunidadeorganizacional => pCdUnidadeOrganizacional,
                                      pdtinicio                => pDtInicioMesFolha,
                                      pdtfim                   => pDtFimRelacao,
                                      pflcalculogeral          => PKGPAG_VAR.vgCalculo.flgeral);
      ELSE
         
         vNuDias := vNuDias +
                    PKGMOV.FQTDIAUTIL(pcdagrupamento           => pCdAgrupamento,
                                      pcdorgao                 => pCdOrgao,
                                      pcdunidadeorganizacional => pCdUnidadeOrganizacional,
                                      pdtinicio                => pDtFimRelacao + 1,
                                      pdtfim                   => pDtFimMesFolha,
                                      pflcalculogeral          => PKGPAG_VAR.vgCalculo.flgeral);
         
      END IF;
      
   END IF;
   
   RETURN vNuDias;
END;


FUNCTION FObterInfoFaltasInjust(pCdOrgao          IN INTEGER,
                                pCdRelacaoVinculo IN INTEGER,
                                pCdAgrupamento    IN INTEGER,
                                pDtInicioMesFolha IN DATE,
                                pDtFimMesFolha    IN DATE,
                                pDtIniCHO         IN DATE,
                                pDtFinalCHO       IN DATE) RETURN tblFaltas IS
   tblInfoFaltas tblFaltas;
   vDataFalta    DATE;
   i             INTEGER := 0;
   
BEGIN
   
   IF PKGPAG_VAR.vgFaltas.Count > 0 THEN
      FOR i IN PKGPAG_VAR.vgFaltas.first .. PKGPAG_VAR.vgFaltas.last LOOP
         -- esta implementação foi suspensa pela SEA (SIG-11145). Essa lógica não foi retirada para facilitar caso
         -- seja necessária implementação futura. Trata-se de servidor com duas cargas horárias vigentes no mês
         -- e onde somente devem ser consideradas as faltas ocorridas nas datas que estão dentro da vigência da CHO
         /* IF pCdAgrupamento IN (1,134) THEN -- considerar apenas as faltas dentro da vigência da CHO
           vDataFalta :=  CASE
                           WHEN PKGPAG_VAR.vgFaltas(i).DtFrequencia >= pDtIniCHO AND
                                PKGPAG_VAR.vgFaltas(i).DtFrequencia <= pDtFinalCHO  THEN
                             PKGPAG_VAR.vgFaltas(i).DtFrequencia
                           ELSE
                             NULL
                          END;
            
         ELSE*/
         vDataFalta := PKGPAG_VAR.vgFaltas(i).DtFrequencia;
         /* END IF;*/
         
         tblInfoFaltas(i).dtFalta := vDataFalta;
         tblInfoFaltas(i).nuIndiceFalta := PKGPAG_VAR.vgFaltas(i).NuIndiceFalta;
         tblInfoFaltas(i).vlValeAlimentacaoDiario := FObterValorDiarioAuxilioAli(pNuAnoReferencia  => EXTRACT(YEAR FROM
                                                                                                              vDataFalta),
                                                                                 pNuMesReferencia  => EXTRACT(MONTH FROM
                                                                                                              vDataFalta),
                                                                                 pCdOrgao          => pCdOrgao,
                                                                                 pCdRelacaoVinculo => pCdRelacaoVinculo);
      END LOOP;
   END IF;
   
   RETURN tblInfoFaltas;
END;


FUNCTION FObterVlDescFaltasInjust(pFaltas IN tblFaltas) RETURN NUMBER IS
   vValorDescontoTotal NUMBER := 0;
   i                   INTEGER;
BEGIN
   IF pFaltas.count > 0 THEN
      FOR i IN pFaltas.first .. pFaltas.last LOOP
         vValorDescontoTotal := vValorDescontoTotal +
                                (pFaltas(i).vlValeAlimentacaoDiario * pFaltas(i).nuIndiceFalta);
      END LOOP;
   END IF;
   
   RETURN round(vValorDescontoTotal, 2);
END;

FUNCTION FObterDescricaoFaltasInjust(pFaltas IN tblFaltas) RETURN VARCHAR2 IS
   vDescricao           VARCHAR2(500);
   i                    INTEGER;
   vListaValoresDiarios sys.odcinumberlist := sys.odcinumberlist();
BEGIN
   --vDescricao := pFaltas.count ||'Falta(s)';
   vDescricao := pFaltas.count || 'Falta';
   /*IF pFaltas.count >0 THEN
     vDescricao := vDescricao || ' (';
      
     FOR i IN pFaltas.first .. pFaltas.last
     LOOP
       vDescricao := vDescricao || '(1 * R$' || pFaltas(i).vlValeAlimentacaoDiario || ')+';
     END LOOP;
      
      
     vDescricao := SUBSTR(vDescricao, 1, (LENGTH(vDescricao)-1));
      
     vDescricao := vDescricao || ')';
   END IF;*/
   
   RETURN vDescricao;
END;

FUNCTION FObterVlAuxilioAliOutrosVinc(pCdVinculo           IN INTEGER,
                                      pNuAnoMes            IN INTEGER,
                                      pDeOrdemExecucao     IN VARCHAR2,
                                      pCdRubricaAuxAlim    IN INTEGER,
                                      pFlCalculoDefinitivo IN CHAR)
   RETURN NUMBER IS
   
   vVlAuxilioAli NUMBER := 0;
   
BEGIN
   
   select sum(vlpagamento) as vlTotalAuxiliAli
     into vVlAuxilioAli
     from epaghistoricorubricavinculo hrv
     
    inner join epagfolhapagamento fpg
       on hrv.cdfolhapagamento = fpg.cdfolhapagamento
      
    where fpg.cdagrupamento in (1, 134)
      and fpg.nuanomesreferencia = pNuAnoMes
      and fpg.cdtipocalculo = 1
      and fpg.flcalculodefinitivo = pFlCalculoDefinitivo
      and fpg.DeOrdemExecucao <= pDeOrdemExecucao
      and hrv.cdvinculo <> pCdVinculo
             
      and hrv.cdvinculo in
          (select cdvinculo
             from ecadvinculo
            where cdpessoa = PKGPAG_VAR.vCdPessoa
           )
            
      and hrv.cdrubricaagrupamento in
          (select ragr.cdrubricaagrupamento
             from epagrubricaagrupamento ragr
            where ragr.cdrubrica = pCdRubricaAuxAlim);
 
   RETURN nvl(vVlAuxilioAli, 0);
END;

FUNCTION FObterIndiceProporcao(pRubrica               IN PKGPAG_TIPO.rRubrica,
                               pNuCHOPadraoCEF        IN NUMBER,
                               pNuCargaHoraria        IN NUMBER,
                               pMediaCHOHoraAtividade IN NUMBER)
   RETURN NUMBER IS
   vIndiceProporcao NUMBER;
   vNuCHOPadrao     NUMBER;
   
BEGIN
   
   vIndiceProporcao := 1;
   
   IF pRubrica.CdRubProporcionalidadeCHO = 2 THEN
      
      IF pRubrica.FlCargaHorariaPadrao = 'S' THEN
         vNuCHOPadrao := pNuCHOPadraoCEF;
      ELSE
         vNuCHOPadrao := pRubrica.NuCargaHorariaSemanal;
      END IF;
      
      IF vNuCHOPadrao > 0 THEN
         
         IF pMediaCHOHoraAtividade IS NULL THEN
            
            IF pRubrica.FlCargaHorariaLimitada = 'N' THEN
               vIndiceProporcao := pNuCargaHoraria / vNuCHOPadrao;
            ELSE
               vIndiceProporcao := CASE
                                      WHEN pNuCargaHoraria > vNuCHOPadrao THEN
                                       1
                                      ELSE
                                       (pNuCargaHoraria / vNuCHOPadrao)
                                   END;
            END IF;
            
         ELSE
            vIndiceProporcao := (pMediaCHOHoraAtividade / vNuCHOPadrao);
            
         END IF;
      END IF;
   END IF;
   
   RETURN vIndiceProporcao;
END;

PROCEDURE P041AuxilioAlimentacao(pCdVinculo IN INTEGER,
                                 pFolha     IN PKGPAG_TIPO.rFolha,
                                 pRubrica   IN PKGPAG_TIPO.rRubrica,
                                 pCEF       IN PKGPAG_TIPO.tCEF,
                                 pCCO       IN PKGPAG_TIPO.tCCO,
                                 pCCOSubst  IN PKGPAG_TIPO.tCCO) IS
   /*------------------------------------------------------------------------------------*/
   
   vNuDiasUteis             NUMBER(13, 0);
   vNuDiasAfastAtual        NUMBER DEFAULT 0;
   vNuDiasAfastRetro        NUMBER DEFAULT 0;
   vNuDiasAfastRetroAnulado NUMBER DEFAULT 0;
   vNuVales                 NUMBER DEFAULT 0;
   vNuFaltasNaoDesc         number default 0;
   vvlAuxilio               NUMBER;
   vvlIntegral              NUMBER := 0;
   vProporcional            PKGPAG_TIPO.rValorPagamento;
   vNuCHOPadrao             NUMBER(7, 4);
   vNuDiasMes               INTEGER;
   vCdOrgaoAuxilio          INTEGER;
   vDtFim                   DATE;
   vDtInicio                DATE;
   vCdRubrica020157         INTEGER;
   vCdRubrica080157         INTEGER;
   vGerouRubrica080157      BOOLEAN;
   vVlAuxilioPago           NUMBER(13, 2);
   vNuCHOPago               NUMBER(7, 4);
   vNuCHOAPagar             NUMBER(7, 4);
   vDescritivoRetro         VARCHAR2(500);
   vDescritivo              VARCHAR2(500);
   vValorLimite             NUMBER(13, 2);
   vDifValor                NUMBER(13, 2) := 0;
   vValorAuxAlimRetroDesc   NUMBER(13, 2) := 0;
   vValorFaltasNaoDesc      NUMBER(13, 2) := 0;
   vtotalvales              NUMBER := 0;
   contadisp                INTEGER := 0;
   vCdRelacaoVinculo        INTEGER;
   vUtilizaNumeroFixoVA     BOOLEAN;
   vNuDiasMesTodosVinc      INTEGER := 0;
   vIndiceProporcao         NUMBER := 1;
   
   vCdRubAgrup_01_0157      INTEGER;
   vCdRubrica_01_0157       INTEGER;   
   
   FUNCTION FObterCargaHorariaTotalCEF(pCargaHoraria      IN PKGPAG_TIPO.tCargaHoraria,
                                       pCdHistCargoEfeivo IN INTEGER,
                                       pDtInicio          IN DATE,
                                       pDtFim             IN DATE)
      RETURN NUMBER IS
      vCHTotalCEF NUMBER := 0;
   BEGIN
      FOR k IN pCargaHoraria.FIRST .. pCargaHoraria.LAST LOOP
         IF pCargaHoraria(k)
          .CdHistCargoEfetivo = pCdHistCargoEfeivo AND pCargaHoraria(k)
            .DtInicio >= pDtInicio AND pCargaHoraria(k).DtFim <= pDtFim THEN
            vCHTotalCEF := vCHTotalCEF + pCargaHoraria(k).NuCargaHoraria;
         END IF;
      END LOOP;
      
      RETURN vCHTotalCEF;
   END;
   
   /*********************************************************************
   **  DEFENSORIA PUBLICA POSSUI VALOR FIXO DE VALE EQUIVALENTE A 22 DIAS
   *********************************************************************/
   
   PROCEDURE PAjusteNuDiasFixo(pCdAgrupamento           INTEGER,
                               pCdOrgao                 INTEGER,
                               pCdUnidadeOrganizacional INTEGER,
                               pCdRelacaoVinculo        INTEGER,
                               pDtInicioRelacao         DATE,
                               pDtFimRelacao            DATE,
                               pDtInicioMesFolha        DATE,
                               pDtFimMesFolha           DATE,
                               pNuDiasAfastamentoMes    NUMBER,
                               pCdVinculo               INTEGER,
                               pDtIniCHO                DATE,
                               pDtFinalCHO              DATE,
                               pIndiceProporcao         NUMBER,
                               pVlAuxilioAliCHOAcum     IN OUT NUMBER) IS
      
      vVlAuxilioAliFixoDia        NUMBER;
      vVlAuxilioAliFixoMes        NUMBER;
      vNuDiasFixoMes              NUMBER;
      vVlDescFaltasInjustificadas NUMBER;
      vVlDescTotal                NUMBER;
      tblFaltasInjustificadas     tblFaltas;
      vDescricaoFaltasInjust      VARCHAR2(500);
      indiceAfastamentos          NUMBER := 0;
      nuDiasMesExcluindoFDS       INTEGER := FContarDiasEntreDatasExcluiFDS(pDtInicioMesFolha,
                                                                            pDtFimMesFolha);
      vValorFixo                  NUMBER(13, 2) := FObterValorFixoAuxilioAli(PKGPAG_VAR.vgFolha.nuanoreferencia,
                                                                             PKGPAG_VAR.vgFolha.numesreferencia,
                                                                             pCdOrgao,
                                                                             pCdRelacaoVinculo);
      vNuDiasUteisSemRelacao      INTEGER := 0;
      vNuFaltasNaoJustificadasMes NUMBER := PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis;
      vVlAuxilioAliOutrosVinc     NUMBER := 0;
      vVlAuxilioAliTotal          NUMBER;
      vVlAuxilioProporcional      NUMBER;
      vSaldo                      NUMBER;
      
      
   BEGIN
      
      vVlAuxilioAliOutrosVinc := FObterVlAuxilioAliOutrosVinc(pCdVinculo           => pCdVinculo,
                                                              pNuAnoMes            => pFolha.NuAnoMesReferencia,
                                                              pDeOrdemExecucao     => pFolha.DeOrdemExecucao,
                                                              pCdRubricaAuxAlim    => vCdRubrica_01_0157,
                                                              pFlCalculoDefinitivo => pFolha.FlCalculoDefinitivo);
      
      vNuDiasFixoMes := PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias;
      
      vVlAuxilioAliFixoDia := FObterValorDiarioAuxilioAli(pNuAnoReferencia  => EXTRACT(YEAR FROM
                                                                                       pFolha.DtCalculo),
                                                          pNuMesReferencia  => EXTRACT(MONTH FROM
                                                                                       pFolha.DtCalculo),
                                                          pCdOrgao          => vCdOrgaoAuxilio,
                                                          pCdRelacaoVinculo => vCdRelacaoVinculo);
      
      vVlAuxilioAliFixoMes := FObterValorFixoAuxilioAli(pNuAnoReferencia  => pFolha.nuanoreferencia,
                                                        pNuMesReferencia  => pFolha.numesreferencia,
                                                        pCdOrgao          => vCdOrgaoAuxilio,
                                                        pCdRelacaoVinculo => vCdRelacaoVinculo);
      
      vNuDiasUteisSemRelacao := FCalcularNuDiasUteisSemRelacao(pCdAgrupamento           => pCdAgrupamento,
                                                               pCdOrgao                 => pfolha.CdOrgao,
                                                               pCdUnidadeOrganizacional => pCdUnidadeOrganizacional,
                                                               pDtInicioRelacao         => pDtInicioRelacao,
                                                               pDtFimRelacao            => pDtFimRelacao,
                                                               pDtInicioMesFolha        => pfolha.DtInicioMes,
                                                               pDtFimMesFolha           => pfolha.DtFimMes,
                                                               pCdVinculo               => pCdVinculo);
      
      tblFaltasInjustificadas := FObterInfoFaltasInjust(pCdOrgao          => vCdOrgaoAuxilio,
                                                        pCdRelacaoVinculo => vCdRelacaoVinculo,
                                                        pCdAgrupamento    => pCdAgrupamento,
                                                        pDtInicioMesFolha => pfolha.DtInicioMes,
                                                        pDtFimMesFolha    => pfolha.DtFimMes,
                                                        pDtIniCHO         => pDtIniCHO,
                                                        pDtFinalCHO       => pDtFinalCHO);
      
      vVlDescFaltasInjustificadas := NVL(FObterVlDescFaltasInjust(pFaltas => tblFaltasInjustificadas),
                                         0);
      
      vDescricaoFaltasInjust := FObterDescricaoFaltasInjust(pFaltas => tblFaltasInjustificadas);
      
      IF pCdAgrupamento IN (1, 134) THEN
         
         indiceAfastamentos := (pNuDiasAfastamentoMes /*+ vNuDiasUteisSemRelacao*/
                                +PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis +
                                vNuFaltasNaoJustificadasMes);
         
         IF pNuDiasAfastamentoMes +
            PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis >= 30 THEN
            -- Para ajustar erro de arredondamento
            vVlDescTotal := vVlAuxilioAliFixoMes +
                            vVlDescFaltasInjustificadas;
            
         ELSE
            
            vVlDescTotal := ((pNuDiasAfastamentoMes /*+ vNuDiasUteisSemRelacao*/
                             +PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis) *
                            vVlAuxilioAliFixoDia) +
                            vVlDescFaltasInjustificadas;
            
         END IF;
         
      ELSE
         
         indiceAfastamentos := (pNuDiasAfastamentoMes +
                               vNuDiasUteisSemRelacao +
                               PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis +
                               vNuFaltasNaoJustificadasMes);
         
         IF pNuDiasAfastamentoMes + vNuDiasUteisSemRelacao +
            PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis >= 30 THEN
            -- Para ajustar erro de arredondamento
            vVlDescTotal := vVlAuxilioAliFixoMes +
                            vVlDescFaltasInjustificadas;
         ELSE
            vVlDescTotal := ((pNuDiasAfastamentoMes +
                            vNuDiasUteisSemRelacao +
                            PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis) *
                            vVlAuxilioAliFixoDia) +
                            vVlDescFaltasInjustificadas;
         END IF;
         
      END IF;
      
      /* Cargos comissionados puros para os quais houve mudança de órgão durante o mês, não deverão descontar os dias não trabalhados no órgão atual,
      mas sim considerar todos os dias com relação de vínculo naquele mês, independente do órgão */
      
      BEGIN
         SELECT 1
           INTO contadisp
           FROM emovdisposicaoservidor hce, eafaafastamentovinculo efa
          WHERE HCE.CdVinculo in pCdVinculo
            AND HCE.DTDISPOSICAO < pfolha.DtCalculo
            AND HCE.FlAnulado = 'N'
            AND hce.cdorgaodestino <> PKGPAG_VAR.vgFolha.CdOrgao
            AND hce.flpagamento = 'O'
            and efa.cdvinculo = hce.cdvinculo
            and efa.dtfim is null
            and efa.flanulado <> 'S'
            and efa.cdmotivoafasttemporario = 2609
            and hce.dtfimdisposicao is null
            AND not exists
          (select 1
                   from ecadorgaoexterno ox
                  where ox.cdorgaoexterno = hce.cdorgaoexterno)
            AND ROWNUM < 2;
      exception
         when others then
            contadisp := 0;
      END;
      
      IF indiceAfastamentos > 0 AND
         pfolha.CdTipoCalculo = PKGPAG_TIPO.cnTpFolhaNormal and
         NVL(contadisp, 0) > 0 then
         indiceAfastamentos := 0;
      END IF;
      
      IF (indiceAfastamentos = nuDiasMesExcluindoFDS) THEN
         -- afastado mês todo
         vNuVales           := 0;
         indiceAfastamentos := vNuDiasFixoMes;
      ELSE
         vNuVales := vNuDiasFixoMes - indiceAfastamentos;
      END IF;
      
      -- ASSUME NUDIASUTEIS FIXO PARA O ORGAO
      
      -- REGRA: VALOR VALE = LIMITE - AFASTAMENTOS
      IF pCdAgrupamento IN (1, 134) THEN
         vVlIntegral              := (vVlAuxilioAliFixoMes * vNuDiasMes / 30) -
                                     vVlDescTotal;
         vProporcional.vlIntegral := vvlIntegral;
         
         vVlAuxilioProporcional       := vVlIntegral * pIndiceProporcao;
         vProporcional.vlProporcional := vVlAuxilioProporcional;
         
         vVlAuxilioAliTotal := vVlAuxilioProporcional +
                               vVlAuxilioAliOutrosVinc +
                               pVlAuxilioAliCHOAcum;
         
         IF vVlAuxilioAliTotal > vVlAuxilioAliFixoMes THEN
            
            vSaldo := 0;
            
            vVlIntegral := vVlAuxilioAliFixoMes -
                           vVlAuxilioAliOutrosVinc;
            
            IF vVlIntegral > 0 THEN
               
               vSaldo      := vVlIntegral;
               vVlIntegral := vVlIntegral - pVlAuxilioAliCHOAcum;
               
               IF vVlIntegral < 0 THEN
                  
                  vVlIntegral := vSaldo;
                  
               END IF;
               
            END IF;
            
            vProporcional.vlProporcional := vVlIntegral;
            
         END IF;
         
         IF pCCO.Count > 0 THEN
            vValorLimite := vVlIntegral;
         END IF;
         
         IF pCEF.Count > 0 THEN
            vValorLimite := vVlAuxilioAliFixoMes;
         END IF;
         
         -- DESCRITIVO CEF
         IF pCEF.Count > 0 THEN
            vDescritivo := 'R$' || vVlAuxilioAliFixoMes || '*' ||
                           vNuDiasMes || '/30' || ' - R$' ||
                           vVlDescTotal || '(' ||
                           (indiceAfastamentos -
                           vNuFaltasNaoJustificadasMes) || 'Afast + ' ||
                           vNuFaltasNaoJustificadasMes || 'Falta' || ') ' || '*' ||
                           vVlAuxilioAliFixoDia || 'unit';
         END IF;
         -- DESCRITIVO CCO
         IF pCCO.Count > 0 THEN
            vDescritivo := 'R$' || vVlAuxilioAliFixoMes || '*' ||
                           vNuDiasMes || '/30' || ' - R$' ||
                           vVlDescTotal || '(' ||
                           (indiceAfastamentos -
                           vNuFaltasNaoJustificadasMes) || 'Afast + ' ||
                           vNuFaltasNaoJustificadasMes || 'Falta' || ') ' || '*' ||
                           vVlAuxilioAliFixoDia || 'unit' /*|| '->R$ ' || vVlIntegral*/
             ;
         END IF;
      ELSE
         vVlIntegral := vVlAuxilioAliFixoMes - vVlDescTotal;
         
         vValorLimite := vVlIntegral;
         
         vProporcional.vlIntegral     := vvlIntegral;
         vProporcional.vlProporcional := vIndiceProporcao * vvlIntegral;
         
         -- DESCRITIVO
         vDescritivo := 'R$' || vVlAuxilioAliFixoMes || ' - R$' ||
                        vVlDescTotal || '(' ||
                        (indiceAfastamentos -
                        vNuFaltasNaoJustificadasMes) || 'Afast + ' ||
                        vNuFaltasNaoJustificadasMes || 'Falta' || ')';
      END IF;
      
   END;
   
   PROCEDURE PObtemAuxilioPago IS
      
      vNuCHOPagoAux NUMBER(7, 4);
      
      vNuCHORelacaoAux NUMBER(7, 4);
      
      vNuCHOAux NUMBER(7, 4);
      
      vContVinc INTEGER := 0;
      
      vtDiaUtil pkgpag_tipo.tDiaUtil;
      
   BEGIN
      
      vGerouRubrica080157 := FALSE;
      
      vVlAuxilioPago := 0;
      
      vNuCHOPago := 0;
      
      vNuCHOPagoAux := 0;
      
      vtDiaUtilOutrosVinculos := vtDiaUtil;
      
      vCdVinculo1 := null;
      
      vCdVinculo2 := null;
      
      vCdVinculo3 := null;
      
      IF PKGPAG_VAR.vgVinculo.FlOutroVincCalculado = 'S' OR
         PKGPAG_VAR.vgVinculo.FlOutroVincACalcular = 'S' THEN
         
         -- 01-0157
         
         ----------------------------------------------------------------------------------------------------------------------------------------------------
         --                                                           ~                                                                                      --
         --     xxx     xxxxxxx     xxxx      xx  x       xxxxx      xxx        xxxxx                                                                        --
         --    x   x      xxx      x         x x  x      xx         x   x      xx   xx                                                                       --
         --    xxxxxx      x       xxxx      x  x x      x          xxxxxx     x     x                                                                       --
         --    x   xx      x       x         x  x x      xx         x   xx     xx   xx                                                                       --
         --    x   xx      x       xxxxx     x   xx       xxxxx     x   xx      xxxxx                                                                        --
         --                                                 /                                                                                                --
         --                                                                                                                                                  --
         --  A QUERY ABAIXO FOI AJUSTADA PELO DBA PARA TER MELHOR PERFORMANCE                                                                                --
         --     QUALQUER ALTERAÇÃO PRECISA SER PASSADA PRA ELE AJUSTAR NOVAMENTE                                                                             --
         FOR vHistRub IN (select V.CdVinculo,
                                 FP.CdAgrupamento,
                                 FP.CdOrgao,
                                 FP.CdFolhaPagamento,
                                 HRV.VlPagamento,
                                 capa.cdunidadeorganizacional --
                            from EPagHistoricoRubricaVinculo HRV --
                           inner join ECadVinculo V
                              on V.CdVinculo = HRV.CdVinculo --
                           inner join EPagFolhaPagamento FP
                              on HRV.CdFolhaPagamento =
                                 FP.CdFolhaPagamento --
                           inner join EPagTipoFolhaPagamento TFP
                              on TFP.CdTipoFolhaPagamento =
                                 FP.CdTipoFolhaPagamento --
                           inner join EPagRubricaAgrupamento RA
                              on RA.CdRubricaAgrupamento =
                                 HRV.CdRubricaAgrupamento --
                           inner join EPagRubrica R
                              on R.CdRubrica = RA.CdRubrica
                             and R.CdTipoRubrica = 1
                             and R.NuRubrica = 157 --
                            left join Epagcapahistrubricavinculo capa
                              on capa.cdfolhapagamento =
                                 hrv.cdfolhapagamento --
                             and capa.cdvinculo = hrv.cdvinculo --
                           where V.CdPessoa =
                                 PKGPAG_VAR.vgVinculo.CdPessoa --
                             and V.CdVinculo <> pCdVinculo --
                                -- INCLUSAO ABAIXO PARA NAO DESCONTAR DO VINCULO O VALOR DE UM VINCULO ENCERRADO ANTES DA DATA DE ADMISSAO DELE              --
                             AND FP.DeOrdemExecucao <= pFolha.DeOrdemExecucao
                             and (V.DTDESLIGAMENTO is null or
                                 V.DTDESLIGAMENTO >
                                 PKGPAG_VAR.vgVinculo.DtAdmissao) --
                             and (HRV.cdFolhaPagamento <>
                                 pFolha.CdFolhaPagamento or --
                                 (HRV.CdFolhaPagamento =
                                 pFolha.CdFolhaPagamento and
                                 V.NuSeqMatricula <
                                 PKGPAG_VAR.vgVinculo.NuSeqMatricula)) --
                             and FP.NuAnoReferencia =
                                 pFolha.NuAnoReferencia --
                             and FP.NuMesReferencia =
                                 pFolha.NuMesReferencia --
                             and ((FP.CdFolhaPagamento =
                                 pFolha.CdFolhaPagamento) or --
                                 (FP.CdTipoCalculo =
                                 PKGPAG_TIPO.cnTpCalculoNormal and
                                 FP.CdOrgao <> pFolha.CdOrgao and --
                                 FP.FlCalculoDefinitivo = --
                                 DECODE(PKGPAG_GERAL.FVisaoCalculo(pFolha.CdTipoCalculo,
                                                                     pFolha.FlCalculoDefinitivo),
                                          'S',
                                          'S',
                                          FP.FlCalculoDefinitivo)) --
                                 or (FP.CdTipoCalculo =
                                 PKGPAG_TIPO.cnTpCalculoSupl and
                                 FP.FlCalculoDefinitivo =
                                 PKGPAG_TIPO.cnS) --
                                 -- Solicitacao de Sustentacao #76751                                                                                      --
                                 -- 10512/2017 - FOLHA - FOLHA APURACAO DIF NO MES                                                                         --
                                 or (pFolha.CdTipoCalculo =
                                 PKGPAG_TIPO.cnTpCalculoDifMes and
                                 FP.Flcalculodefinitivo =
                                 PKGPAG_TIPO.cnS)) --
                          -----------------------------------------------------------------------------------------------------------------------------------------------------
                          ---------------------------------------------------------------------------------------------------------------------------------------------------
                          ) LOOP
            
            vVlAuxilioPago := vVlAuxilioPago + vHistRub.VlPagamento;
            
            vContVinc := vContVinc + 1;
            
            vtDiaUtilOutrosVinculos(vContVinc).CdVinculo := vHistRub.Cdvinculo;
            vtDiaUtilOutrosVinculos(vContVinc).CdOrgao := vHistRub.Cdorgao;
            vtDiaUtilOutrosVinculos(vContVinc).CdAgrupamento := vHistRub.CdAgrupamento;
            vtDiaUtilOutrosVinculos(vContVinc).CdUnidadeOrganizacional := vHistRub.Cdunidadeorganizacional;
            
            BEGIN
               
               vtDiaUtilOutrosVinculos(vContVinc).vQtdeVale := vHistRub.vlPagamento / PKGPAG_VAR.vgAuxilioAliAnt(pFolha.Cdorgao).VlAuxilioCEF;
               vtDiaUtilOutrosVinculos(vContVinc).vlValeDia := PKGPAG_VAR.vgAuxilioAliAnt(pFolha.CdOrgao).VlAuxilioCEF;
               
            EXCEPTION
               
               WHEN OTHERS THEN
                  vtDiaUtilOutrosVinculos(vContVinc).vQtdeVale := vHistRub.vlPagamento / PKGPAG_VAR.vgAuxilioAli(pFolha.Cdorgao).VlAuxilioCEF;
                  vtDiaUtilOutrosVinculos(vContVinc).vlValeDia := PKGPAG_VAR.vgAuxilioAli(pFolha.CdOrgao).VlAuxilioCEF;
                  
            END;
            
            --Busca o valor da carga horaria nos contra-cheques do SIRH
            
            vNuCHOPagoAux := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => vHistRub.CdFolhaPagamento,
                                                               pCdVinculo        => vHistRub.CdVinculo,
                                                               pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(vHistRub.CdAgrupamento,
                                                                                                                 9,
                                                                                                                 257));
            
            -- Caso nao encontre, procura a capa de pagamento que e gerada pelo SIGRH
            
            IF vNuCHOPagoAux = 0 THEN
               
               vNuCHORelacaoAux := 0;
               
               vNuCHOAux := 0;
               
               BEGIN
                  
                  SELECT CH.NuCHORelacao, CH.NuCHO
                    INTO vNuCHORelacaoAux, vNuCHOAux
                    FROM EPagCapaHistrubricaVinculo CH
                   WHERE CH.CdFolhaPagamento = vHistRub.CdFolhaPagamento
                     AND CH.Cdvinculo = vHistRub.CdVinculo;
                  
               EXCEPTION
                  
                  WHEN NO_DATA_FOUND THEN
                     
                     NULL;
                     
               END;
               
               -- CHO completa
               
               IF vNuCHOAux <> 0 THEN
                  
                  IF vNuCHORelacaoAux >= vNuCHOAux THEN
                     
                     vNuCHOPagoAux := 40;
                     
                  ELSE
                     
                     vNuCHOPagoAux := vNuCHORelacaoAux;
                     
                  END IF;
                  
               END IF;
               
            END IF;
            
            vNuCHOPago := vNuCHOPago + vNuCHOPagoAux;
            
         END LOOP;
         
         -- 08-0157
         FOR vHistRub080157 IN (SELECT V.CdVinculo,
                                       FP.CdAgrupamento,
                                       FP.CdOrgao,
                                       FP.CdFolhaPagamento,
                                       HRV.VlPagamento
                                  FROM EPagHistoricoRubricaVinculo HRV
                                 INNER JOIN ECadVinculo V
                                    ON V.CdVinculo = HRV.CdVinculo
                                 INNER JOIN EPagFolhaPagamento FP
                                    ON HRV.CdFolhaPagamento =
                                       FP.CdFolhaPagamento
                                 INNER JOIN EPagTipoFolhaPagamento TFP
                                    ON TFP.CdTipoFolhaPagamento =
                                       FP.CdTipoFolhaPagamento
                                 INNER JOIN EPagRubricaAgrupamento RA
                                    ON RA.CdRubricaAgrupamento =
                                       HRV.CdRubricaAgrupamento
                                 INNER JOIN EPagRubrica R
                                    ON R.CdRubrica = RA.CdRubrica
                                   AND R.CdTipoRubrica = 8
                                   AND R.NuRubrica = 157
                                 WHERE V.CdPessoa =
                                       PKGPAG_VAR.vgVinculo.CdPessoa
                                   AND FP.DeOrdemExecucao <= pFolha.DeOrdemExecucao    
                                   AND V.CdVinculo <> pCdVinculo
                                   AND (V.DTDESLIGAMENTO is NULL OR
                                       V.DTDESLIGAMENTO >
                                       PKGPAG_VAR.vgVinculo.DtAdmissao)
                                   AND (HRV.cdFolhaPagamento <>
                                       pFolha.CdFolhaPagamento OR
                                       (HRV.CdFolhaPagamento =
                                       pFolha.CdFolhaPagamento AND
                                       V.NuSeqMatricula <
                                       PKGPAG_VAR.vgVinculo.NuSeqMatricula))
                                   AND FP.NuAnoReferencia =
                                       pFolha.NuAnoReferencia
                                   AND FP.NuMesReferencia =
                                       pFolha.NuMesReferencia
                                   AND ((FP.CdFolhaPagamento =
                                       pFolha.CdFolhaPagamento) OR
                                       (FP.CdTipoCalculo =
                                       PKGPAG_TIPO.cnTpCalculoNormal AND
                                       FP.CdOrgao <> pFolha.CdOrgao AND
                                       FP.FlCalculoDefinitivo =
                                       DECODE(PKGPAG_GERAL.FVisaoCalculo(pFolha.CdTipoCalculo,
                                                                           pFolha.FlCalculoDefinitivo),
                                                'S',
                                                'S',
                                                FP.FlCalculoDefinitivo)) OR
                                       (FP.CdTipoCalculo =
                                       PKGPAG_TIPO.cnTpCalculoSupl AND
                                       FP.FlCalculoDefinitivo =
                                       PKGPAG_TIPO.cnS))) LOOP
            IF vHistRub080157.Vlpagamento > 0 THEN
               vGerouRubrica080157 := TRUE;
            END IF;
         END LOOP;
      END IF;
      
      IF vVlAuxilioPago <> 0 OR vNuCHOPago <> 0 THEN
         
         PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim',
                                'Valor/CHO ja Pago: ' || vVlAuxilioPago || '/' ||
                                vNuCHOPago);
         
      END IF;
      
   END;
   
   FUNCTION FObtemAuxilioPagoRelVinc(pCdVinculo IN INTEGER,
                                     pFolha     IN PKGPAG_TIPO.rFolha)
      
    RETURN NUMBER IS
      
      vVlPagamentoCEF NUMBER(13, 2);
      
   BEGIN
      
      SELECT SUM(Vlproporcional)
        INTO vVlPagamentoCEF
        FROM (SELECT HRV.Vlproporcional
                FROM epaghistoricorubricarelvinc hrv
               INNER JOIN ECadVinculo V
                  ON V.CdVinculo = HRV.CdVinculo
               INNER JOIN EPagFolhaPagamento FP
                  ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento
               INNER JOIN EPagTipoFolhaPagamento TFP
                  ON TFP.CdTipoFolhaPagamento = FP.CdTipoFolhaPagamento
               INNER JOIN EPagRubricaAgrupamento RA
                  ON RA.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
               INNER JOIN EPagRubrica R
                  ON R.CdRubrica = RA.CdRubrica
                 AND R.CdTipoRubrica = 1
                 AND R.NuRubrica = 157
               WHERE v.cdvinculo = pCdVinculo
                 AND fp.cdfolhapagamento = pfolha.CdFolhaPagamento);
      
      RETURN vVlPagamentoCEF;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
         
      WHEN OTHERS THEN
         RETURN 0;
         
   END;
   
   FUNCTION FRecebidoComPagtoNaOrigem(pCdVinculo         IN INTEGER,
                                      pCdRelacaoTrabalho IN INTEGER,
                                      pFlPrincipal       IN CHAR)
      
    RETURN BOOLEAN IS
      
      vFlPagamento               CHAR(1);
      vPossuiDisposicaoForaAgrup NUMBER;
      
   BEGIN
      
      vDtFimDisposicao := null;
      
      --
      -- Se possui decisao judicial de auxilio alimentacao ignora os testes abaixo.
      --
      IF bDecJudAfastADisposicaoComOnus = TRUE THEN
         RETURN FALSE;
      END IF;
      
      IF pCdRelacaoTrabalho = 10 AND pFlPrincipal = 'S' THEN
         
         SELECT SR.FlPagamento
           INTO vFlPagamento
           FROM EMovServidorRecebido SR
          WHERE CdVinculo = pCdVinculo
            AND ROWNUM < 2;
         
         IF vFlPagamento = 'O' THEN
            
            RETURN TRUE;
            
         ELSE
            
            RETURN FALSE;
            
         END IF;
         
      ELSE
         
         SELECT COUNT(*), MAX(DS.DTFIMDISPOSICAO)
           INTO vPossuiDisposicaoForaAgrup, vDtFimDisposicao
           FROM EMovDisposicaoServidor DS
          INNER JOIN ECadVinculo V
             on V.CdVinculo = DS.CdVinculo
          WHERE DS.cdvinculo = pCdVinculo
            AND (DS.DtFimDisposicao IS NULL OR
                (DS.DtFimDisposicao BETWEEN pFolha.DtInicioMes AND
                pFolha.DtFimMes))
            AND DS.FLANULADO = 'N'
               --Servidores da Agricultura que vao para CIDASC ou EPAGRI OU servidores a disposicao do TRE
               --tem direito de receber o vale alimentacao
            AND NOT (((DS.CdOrgaoExterno IN (182, 162) OR
                 DS.CdOrgaoDestino IN (25, 27)) AND V.CdOrgao = 24) OR
                 DS.CdOrgaoExterno = 26);
         
         IF vPossuiDisposicaoForaAgrup > 0 and
            (PKGPAG_VAR.vgvinculo.CdOrgao = PKGPAG_VAR.vgFolha.CdOrgao and
            PKGPAG_VAR.vgvinculo.CdOpcaoAuxilioAli = 2) THEN
            
            RETURN TRUE;
            
         ELSE
            
            RETURN FALSE;
            
         END IF;
         
      END IF;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         RETURN FALSE;
         
   END;
   
   FUNCTION FVinculoSemAuxilio(pCdParametroOrgao IN INTEGER,
                               pCdVinculo        IN INTEGER)
      
    RETURN BOOLEAN IS
      
      vCont INTEGER;
      
   BEGIN
      
      SELECT COUNT(*)
        INTO vCont
        FROM EAliVinculoSemAuxilio A
       WHERE A.CdVinculo = pCdVinculo
         AND A.CdParametroOrgao = pCdParametroOrgao;
      
      IF vCont > 0 THEN
         
         RETURN TRUE;
         
      ELSE
         
         RETURN FALSE;
         
      END IF;
      
   END;
   
   FUNCTION FCarreiraSemAuxilio(pCdParametroOrgao    IN INTEGER,
                                pCdEstruturaCarreira IN INTEGER)
      
    RETURN BOOLEAN IS
      
      vCont INTEGER;
      
   BEGIN
      
      SELECT COUNT(*)
        INTO vCont
        FROM EAliCarreiraSemAuxilio CAS
       INNER JOIN (SELECT EC.CdEstruturaCarreira
                     FROM eCadEstruturaCarreira EC
                    START WITH EC.CdEstruturaCarreira =
                               pCdEstruturaCarreira
                   CONNECT BY PRIOR EC.CdEstruturaCarreiraPai =
                               EC.CdEstruturaCarreira) E
          ON E.CdEstruturaCarreira = CAS.CdEstruturaCarreira
       WHERE CAS.CdParametroOrgao = pCdParametroOrgao;
      
      IF vCont > 0 THEN
         
         RETURN TRUE;
         
      ELSE
         
         RETURN FALSE;
         
      END IF;
      
   END;
   
   FUNCTION FUOSemAuxilio(pCdParametroOrgao        IN INTEGER,
                          pCdUnidadeOrganizacional IN INTEGER)
      
    RETURN BOOLEAN IS
      
      vNuUoSemAuxilio INTEGER;
      
   BEGIN
      
      SELECT NuUoSemAuxilio
        INTO vNuUoSemAuxilio
        FROM (SELECT COUNT(*) AS NuUoSemAuxilio
                FROM EAliUOSemAuxilio A
               WHERE A.CdUnidadeOrganizacional = pCdUnidadeOrganizacional
                 AND A.CdParametroOrgao = pCdParametroOrgao
                 
              UNION
                 
              SELECT COUNT(*) AS NuUoSemAuxilio
                FROM EAliUOSemAuxilio A
               INNER JOIN (SELECT CdUnidadeOrganizacional
                            FROM ECadHistUnidadeOrganizacional UO
                          CONNECT BY PRIOR UO.CdUOSupHierarq =
                                      UO.CdUnidadeOrganizacional
                           START WITH UO.CdUnidadeOrganizacional =
                                      pCdUnidadeOrganizacional) U
                  ON A.CdUnidadeOrganizacional =
                     U.Cdunidadeorganizacional
               WHERE A.CdParametroOrgao = pCdParametroOrgao
                 AND A.FlIncluirSubordinadas = PKGPAG_TIPO.cnS);
      
      IF vNuUoSemAuxilio > 0 THEN
         
         RETURN TRUE;
         
      ELSE
         
         RETURN FALSE;
         
      END IF;
      
   END;
   
   FUNCTION FGeraAuxilioAlimentacao(pCdOrgao     IN INTEGER,
                                    pCdVinculo   IN INTEGER,
                                    pCdSitPrev   IN INTEGER,
                                    pCdRelTrab   IN INTEGER,
                                    pCdUnidOrg   IN INTEGER,
                                    pCdEstrutura IN INTEGER DEFAULT NULL,
                                    pCdOpcao     IN INTEGER DEFAULT NULL)
      RETURN BOOLEAN IS
      
   BEGIN
      
      IF PKGPAG_VAR.vgAuxilioAli(pCdOrgao).CdParametroOrgao IS NOT NULL THEN
         
         IF PKGPAG_VAR.vgAuxilioAli(pCdOrgao).lsRelTrab.EXISTS(pCdRelTrab) THEN
            
            RETURN FALSE;
            
         END IF;
         
         IF PKGPAG_VAR.vgAuxilioAli(pCdOrgao).lsSitPrev.EXISTS(pCdSitPrev) THEN
            
            RETURN FALSE;
            
         END IF;
         
         IF PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlVerificaVinculo = TRUE THEN
            
            IF FVinculoSemAuxilio(PKGPAG_VAR.vgAuxilioAli(pCdOrgao).CdParametroOrgao,
                                  pCdVinculo) THEN
               
               RETURN FALSE;
               
            END IF;
            
         END IF;
         
         IF PKGPAG_VAR.vgAuxilioAli(pCdOrgao)
          .FlVerificaCarreira = TRUE AND pCdEstrutura IS NOT NULL THEN
            
            IF FCarreiraSemAuxilio(PKGPAG_VAR.vgAuxilioAli(pCdOrgao).CdParametroOrgao,
                                   pCdEstrutura) THEN
               
               RETURN FALSE;
               
            END IF;
            
         END IF;
         
         IF PKGPAG_VAR.vgAuxilioAli(pCdOrgao).FlVerificaUO = TRUE THEN
            
            IF FUOSemAuxilio(PKGPAG_VAR.vgAuxilioAli(pCdOrgao).CdParametroOrgao,
                             pCdUnidOrg) THEN
               
               RETURN FALSE;
               
            END IF;
            
         END IF;
         
         IF pCdOpcao IS NOT NULL AND PKGPAG_VAR.vgAuxilioAli(pCdOrgao).lsOpcaoRemuneracao.EXISTS(pCdOpcao) THEN
            
            RETURN FALSE;
            
         END IF;
         
         -- E efetivo mas tem opcao de pelo comissionado ou FT/FTG, nao recebe auxilio alim. no efetivo
         IF pCdRelTrab in (5, 10) AND PKGPAG_VAR.vgCCO.count > 0 AND PKGPAG_VAR.vgCCO(1)
           .cdopcaoremuneracao IN (3, 6) AND
            PKGPAG_VAR.vgNuDiasCCO >= to_char(pfolha.DtFimMes, 'DD')
            
          THEN
            
            RETURN FALSE;
            
         END IF;
         
      END IF;
      
      RETURN TRUE;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         RETURN FALSE;
         
   END;
   
   FUNCTION FRetornaDiasUteis(pCdUnidadeOrganizacional IN INTEGER,
                              pDtInicio                IN DATE,
                              pDtFim                   IN DATE,
                              pNuTipoDiaNaoUtil        IN INTEGER)
      
    RETURN INTEGER IS
      
   BEGIN
      
      RETURN PKGMOV.FQtDiaUtil(pCdAgrupamento           => pFolha.CdAgrupamento,
                               pCdOrgao                 => pFolha.CdOrgao,
                               pCdUnidadeOrganizacional => pCdUnidadeOrganizacional,
                               pDtInicio                => CASE
                                                            PKGPAG_VAR.vgAuxilioAli(pFolha.CdOrgao).InCompetenciaApuracaoDias
                                                              WHEN 1 THEN
                                                               pDtInicio
                                                              ELSE
                                                               pFolha.DtFimMes + 1
                                                           END,
                               pDtFim                   => CASE
                                                            PKGPAG_VAR.vgAuxilioAli(pFolha.CdOrgao).InCompetenciaApuracaoDias
                                                              WHEN 1 THEN
                                                               pDtFim
                                                              ELSE
                                                               LAST_DAY(pFolha.DtFimMes + 1)
                                                           END,
                               pNuTipoDiaNaoUtil        => pNuTipoDiaNaoUtil,
                               pEventoAuxilioAlim       => 'S',
                               pFlCalculoGeral          => PKGPAG_VAR.vgCalculo.flgeral);
      
   END;
   
   FUNCTION FRetornaValorAuxilioCEF(pCdValorAuxilio      IN INTEGER,
                                    pCdEstruturaCarreira IN INTEGER,
                                    pVlAuxilio           IN NUMBER,
                                    pNuNivel             IN VARCHAR2 DEFAULT NULL,
                                    pNuCargaHoraria      IN NUMBER DEFAULT NULL)
      RETURN NUMBER IS
      
      vVlAuxilioAlimentacao NUMBER(13, 2);
      
   BEGIN
      
      SELECT VlAuxilioAlimentacao
        INTO vVlAuxilioAlimentacao
        FROM (SELECT Nivel,
                     A.CdEstruturaCarreira,
                     CASE
                        WHEN (pNuNivel BETWEEN VC.DeNivelSalarialInicial AND
                             VC.DeNivelSalarialFinal) AND
                             pNuCargaHoraria = VC.NuCargaHoraria THEN
                         1
                        WHEN (pNuNivel BETWEEN VC.DeNivelSalarialInicial AND
                             VC.DeNivelSalarialFinal) AND
                             VC.Nucargahoraria IS NULL THEN
                         2
                        WHEN (pNuNivel >= VC.DeNivelSalarialInicial AND
                             VC.DeNivelSalarialFinal IS NULL) AND
                             pNuCargaHoraria = VC.NuCargaHoraria THEN
                         3
                        WHEN (pNuNivel <= VC.DeNivelSalarialInicial AND
                             VC.DeNivelSalarialInicial IS NULL) AND
                             pNuCargaHoraria = VC.NuCargaHoraria THEN
                         4
                        WHEN (pNuNivel >= VC.DeNivelSalarialInicial AND
                             VC.DeNivelSalarialFinal IS NULL) AND
                             VC.NuCargaHoraria IS NULL THEN
                         5
                        WHEN (pNuNivel <= VC.DeNivelSalarialFinal AND
                             VC.DeNivelSalarialInicial IS NULL) AND
                             pNuCargaHoraria = VC.NuCargaHoraria THEN
                         6
                        WHEN (VC.DeNivelSalarialFinal IS NULL AND
                             VC.DeNivelSalarialInicial IS NULL AND
                             pNuCargaHoraria = VC.NuCargaHoraria) THEN
                         7
                        ELSE
                         8
                     END AS NuOrdem,
                     VlAuxilioAlimentacao
                FROM EAliValorAuxilio VA
               INNER JOIN EAliValorauxilioCarreira VC
                  ON VC.CdValorAuxilio = VA.CdValorAuxilio
               INNER JOIN (SELECT CdEstruturaCarreira, LEVEL AS Nivel
                            FROM ecadEstruturaCarreira C
                          CONNECT BY PRIOR C.CdEstruturacarreiraPai =
                                      C.CdEstruturaCarreira
                           START WITH C.CdEstruturacarreira =
                                      pCdEstruturaCarreira) A
                  ON VC.CdEstruturaCarreira = A.CdEstruturaCarreira
               WHERE VA.CdValorAuxilio = pCdValorAuxilio
                 AND
                       
                     (((pNuNivel BETWEEN VC.DeNivelSalarialInicial AND
                     VC.DeNivelSalarialFinal) AND
                     pNuCargaHoraria = VC.NuCargaHoraria) OR
                        
                     ((pNuNivel BETWEEN VC.DeNivelSalarialInicial AND
                     VC.DeNivelSalarialFinal) AND
                     VC.NuCargahoraria IS NULL) OR
                        
                     ((pNuNivel >= VC.DeNivelSalarialInicial AND
                     VC.DeNivelSalarialFinal IS NULL) AND
                     pNuCargaHoraria = VC.NuCargaHoraria) OR
                        
                     ((pNuNivel <= VC.DeNivelSalarialFinal AND
                     VC.DeNivelSalarialInicial IS NULL) AND
                     pNuCargaHoraria = VC.NuCargaHoraria) OR
                        
                     ((pNuNivel >= VC.DeNivelSalarialInicial AND
                     VC.DeNivelSalarialFinal IS NULL) AND
                     VC.NuCargaHoraria IS NULL) OR
                        
                     ((pNuNivel <= VC.DeNivelSalarialFinal AND
                     VC.DeNivelSalarialInicial IS NULL) AND
                     pNuCargaHoraria = VC.NuCargaHoraria) OR
                        
                     (VC.DeNivelSalarialFinal IS NULL AND
                     VC.DeNivelSalarialInicial IS NULL AND
                     pNuCargaHoraria = VC.NuCargaHoraria) OR
                        
                     (VC.DeNivelSalarialFinal IS NULL AND
                     VC.DeNivelSalarialInicial IS NULL AND
                     VC.NuCargaHoraria IS NULL))
               ORDER BY NIVEL, NUORDEM)
       WHERE ROWNUM < 2;
      
      RETURN vVlAuxilioAlimentacao;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         RETURN pVlAuxilio;
         
   END;
   
   FUNCTION FTrataValoresRecebidos(pValorCalculado IN NUMBER,
                                   pNuDiasAfast    in number default 0)
      RETURN NUMBER IS
      
      vVlRetorno   NUMBER;
      vAfastVinc   PKGPAG_TIPO.tAfastamento;
      vNuDiasAfast integer;
      
   BEGIN
      
      IF NVL(vValorLimite, 0) = 0 THEN
         vValorLimite := vVlIntegral;
      END IF;
      
      IF /*vVlAuxilioPago +*/
       pValorCalculado > vValorLimite THEN
         --vVlRetorno := least(vvalorlimite - vVlAuxilioPago, pValorCalculado);
         vVlRetorno  := vValorLimite;
         vDescritivo := vDescritivo || '->Abate R$' || vVlAuxilioPago ||
                        ' OutVinc->R$' || vVlRetorno;
         
      ELSE
         vVlRetorno := pValorCalculado;
      END IF;
      
      -- Procurar se os valores recebidos de outros vinculos estao descontando afastamentos pelo mesmos motivos do atual
      -- Solicitação de Sustentação #79137
      -- 11758/2018 - AUXILIO ALIMENTACAO - DOIS VINCULOS
      if pNuDiasAfast > 0 and PKGPAG_VAR.vgAfastAuxAlimentacao.COUNT > 0 then
         
         if vtDiaUtilOutrosVinculos.Count > 0
            
          then
            
            for k in vtDiaUtilOutrosVinculos.first .. vtDiaUtilOutrosVinculos.last loop
               
               vAfastVinc := pkgpag_cal.FAfastamentoVinculo(pCdVinculo => vtDiaUtilOutrosVinculos(k).CdVinculo,
                                                            pDtInicio  => PKGPAG_VAR.vgFolha.DtInicioMes,
                                                            pDtFim     => PKGPAG_VAR.vgFolha.DtFimMes,
                                                            pdtCalculo => PKGPAG_VAR.vDtCalculo,
                                                            pTipoAfa   => 'R',
                                                            pAuxAlim   => 'S');
               
               if vAfastVinc.Count > 0 then
                  
                  for i in vAfastVinc.FIRST .. vAfastVinc.LAST loop
                     for j in PKGPAG_VAR.vgAfastAuxAlimentacao.FIRST .. PKGPAG_VAR.vgAfastAuxAlimentacao.LAST loop
                        if PKGPAG_VAR.vgAfastAuxAlimentacao(j).CdMotivoAfastamento = vAfastVinc(i).CdMotivoAfastamento and PKGPAG_VAR.vgAfastAuxAlimentacao(j).DtInicioAfaNoMes = vAfastVinc(i).DtInicioAfaNoMes and PKGPAG_VAR.vgAfastAuxAlimentacao(j).DtFimAfaNoMes = vAfastVinc(i).DtFimAfaNoMes then
                           
                           vNuDiasAfast := pkgmov.FQTDIAUTIL(PCDAGRUPAMENTO           => vtDiaUtilOutrosVinculos(k).CdAgrupamento,
                                                             PCDORGAO                 => vtDiaUtilOutrosVinculos(k).CdOrgao,
                                                             PCDUNIDADEORGANIZACIONAL => vtDiaUtilOutrosVinculos(k).CdUnidadeOrganizacional,
                                                             PDTINICIO                => PKGPAG_VAR.vgAfastAuxAlimentacao(j).DtInicioAfaNoMes,
                                                             PDTFIM                   => PKGPAG_VAR.vgAfastAuxAlimentacao(j).DtFimAfaNoMes,
                                                             PEVENTOAUXILIOALIM       => 'S',
                                                             PFLCALCULOGERAL          => PKGPAG_VAR.vgCalculo.flgeral);
                           
                           vVlRetorno := pValorCalculado -
                                         (vNuDiasAfast * vtDiaUtilOutrosVinculos(k).vlValeDia);
                           
                        end if;
                        
                     end loop;
                     
                  end loop;
                  
               end if;
               
            end loop;
            
         end if;
         
      end if;
      
      vVlAuxilioPago := vVlAuxilioPago + vVlRetorno;
      
      RETURN vVlRetorno;
      
   END;
   
   FUNCTION FRetornaValorAuxilioCCO(pCdValorAuxilio      IN INTEGER,
                                    pCdGrupoOcupacional  IN INTEGER,
                                    pCdCargoComissionado IN INTEGER,
                                    pNuCodigo            IN VARCHAR2,
                                    pNuReferencia        IN VARCHAR2,
                                    pNuCargaHoraria      IN NUMBER,
                                    pVlAuxilio           IN NUMBER)
      RETURN NUMBER IS
      
      vVlAuxilioAlimentacao NUMBER(13, 2);
      
   BEGIN
      
      SELECT vlAuxilioAlimentacao
        INTO vVlAuxilioAlimentacao
        FROM (SELECT VlAuxilioAlimentacao
                FROM (SELECT CASE
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado =
                                     pCdCargoComissionado AND
                                     VC.NuCargaHoraria = pNuCargaHoraria AND
                                     VC.NuCodigo = pNuCodigo AND
                                     VC.NuReferencia = pNuReferencia) THEN
                                 1
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado =
                                     pCdCargoComissionado AND
                                     VC.NuCargaHoraria = pNuCargaHoraria AND
                                     VC.NuCodigo = pNuCodigo AND
                                     VC.NuReferencia IS NULL) THEN
                                 2
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado =
                                     pCdCargoComissionado AND
                                     VC.NuCargaHoraria = pNuCargaHoraria AND
                                     VC.NuCodigo IS NULL AND
                                     VC.NuReferencia = pNuReferencia) THEN
                                 3
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado =
                                     pCdCargoComissionado AND
                                     VC.NuCargaHoraria IS NULL AND
                                     VC.NuCodigo = pNuCodigo AND
                                     VC.NuReferencia = pNuReferencia) THEN
                                 4
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado =
                                     pCdCargoComissionado AND
                                     VC.NuCargaHoraria IS NULL AND
                                     VC.NuCodigo = pNuCodigo AND
                                     VC.NuReferencia IS NULL) THEN
                                 5
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado =
                                     pCdCargoComissionado AND
                                     VC.NuCargaHoraria IS NULL AND
                                     VC.NuCodigo IS NULL AND
                                     VC.NuReferencia = pNuReferencia) THEN
                                 6
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado IS NULL AND
                                     VC.NuCargaHoraria IS NULL AND
                                     VC.NuCodigo IS NULL AND
                                     VC.NuReferencia = pNuReferencia) THEN
                                 7
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado IS NULL AND
                                     VC.NuCargaHoraria IS NULL AND
                                     VC.NuCodigo = pNuCodigo AND
                                     VC.NuReferencia IS NULL) THEN
                                 8
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.CdCargoComissionado =
                                     pCdCargoComissionado) THEN
                                 9
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional AND
                                     VC.NuCargaHoraria = pNuCargaHoraria) THEN
                                 10
                                WHEN (VC.CdGrupoOcupacional =
                                     pCdGrupoOcupacional) THEN
                                 11
                             END AS NuOrdem,
                             VC.VlAuxilioAlimentacao
                        FROM EAliValorAuxilio VA
                       INNER JOIN EAliValorAuxilioCargoCom VC
                          ON VC.CdValorAuxilio = VA.CdValorAuxilio
                       WHERE VA.CdValorAuxilio = pCdValorAuxilio
                         AND ((VC.CdGrupoOcupacional = pCdGrupoOcupacional AND
                             VC.CdCargoComissionado =
                             pCdCargoComissionado AND
                             VC.NuCargaHoraria = pNuCargaHoraria) OR
                             (VC.CdGrupoOcupacional = pCdGrupoOcupacional AND
                             VC.CdCargoComissionado =
                             pCdCargoComissionado) OR
                             (VC.CdGrupoOcupacional = pCdGrupoOcupacional AND
                             VC.NuCargaHoraria = pNuCargaHoraria) OR
                             (VC.CdGrupoOcupacional = pCdGrupoOcupacional)))
               ORDER BY NuOrdem)
       WHERE ROWNUM < 2;
      
      RETURN vVlAuxilioAlimentacao;
      
   EXCEPTION
      
      WHEN NO_DATA_FOUND THEN
         
         RETURN pvlAuxilio;
         
   END;
   
   FUNCTION FCalculaValorIntegralCEF(pNuVales NUMBER, pVlAuxilio NUMBER)
      RETURN NUMBER IS
      
      vvlIntegralCEF    NUMBER(13, 2);
      vvlFixoAuxilioCEF NUMBER(13, 2);
      
   BEGIN
      
      vvlIntegralCEF    := vNuVales * vvlAuxilio;
      vvlFixoAuxilioCEF := FObterValorFixoAuxilioAli(PKGPAG_VAR.vgFolha.nuanoreferencia,
                                                     PKGPAG_VAR.vgFolha.nuanoreferencia, /*PKGPAG_VAR.vgFolha.cdorgao*/
                                                     vCdOrgaoAuxilio,
                                                     1);
      
      IF vvlFixoAuxilioCEF > 0 THEN
         vvlIntegralCEF := least(vvlIntegralCEF, vvlFixoAuxilioCEF);
      END IF;
      
      vDescritivo := vDescritivo || '*' || vvlAuxilio || 'unit->' ||
                     vvlIntegralCEF;
      
      RETURN vvlIntegralCEF;
   END;
   
   PROCEDURE PGeraAuxilioCEF(pCEF IN PKGPAG_TIPO.tCEF) IS
      
      vValorAuxAlimAtual        NUMBER(13, 2) := 0;
      vNuValesAuxAlimAtual      NUMBER;
      vValorAuxAlimRetro        NUMBER(13, 2);
      vValorAuxAlimRetroAnulado NUMBER(13, 2);
      vValorSaldoAuxAlimRetro   NUMBER(13, 2);
      vIndiceProporcao          NUMBER;
      vSomaTotalVlAuxAli        NUMBER(13, 2) := 0;
      vNuIndice                 NUMBER(13, 2);
      --vNuDiasAfastMesAntAnulado NUMBER := 0;
      --vNuDiasAfastMesAnt NUMBER := 0;
      vContCargaHoraria        INTEGER;
      vRetorno                 NUMBER;
      vAfastVinc               tAfast;
      vnudiasafastretroanulado NUMBER := 0;
      vnudiasafastretro        NUMBER := 0;
      vNuDiasAbonoRetro        NUMBER := 0;
      vCHTotalCEF              NUMBER := 0;
      vVlAuxilioAliCHOAcum     NUMBER;
      vAfastadoUltDiaMes       CHAR(1);
      vFlAfastadoMesTodo       CHAR(1);
      vCdRubrica080157         INTEGER;
      vValorRubrica080157      number(13, 2);
      vValorRubrica010157      pkgpag_tipo.rValorPagamento;
      
      CURSOR cOutroVinculo IS
         SELECT cdVinculo
           FROM ecadvinculo
          WHERE CdPessoa = PKGPAG_VAR.vgVinculo.cdPessoa
            AND CdVinculo <> PKGPAG_VAR.vgVinculo.Cdvinculo
            AND (DtDesligamento IS NULL OR
                DtDesligamento >= pFolha.DtInicioMes);
      
   BEGIN
      
      IF (pCEF.COUNT > 0) THEN
         
         vNuValesAuxAlimAtual := 0;
         vIndiceProporcao     := 1;
         vNuVales             := 0;
         vNuIndice            := 0;
         vNuDiasUteis         := 0;
         
         -- Todo servidor recebido a disposicao com pagamento na origem nao recebe auxilio alimentacao
         FOR i IN pCEF.FIRST .. pCEF.LAST LOOP
            
            IF pCEF(i)
             .CdRelacaoTrabalho = PKGPAG_TIPO.cnRegTrabAdmEspecial OR
                (pCEF(i)
                 .CdRelacaoTrabalho <> PKGPAG_TIPO.cnRegTrabAdmEspecial AND
                  TRUNC(MONTHS_BETWEEN(pFolha.DtFimMes,
                                       PKGPAG_VAR.vgVinculo.DtNascimento)) <= 900) THEN
               
               IF (PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                          pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                          pCdOrgaoExercicio         => pCEF(i).CdOrgaoExercicio,
                                                          pCdNaturezaVinculo        => pCEF(i).CdNaturezaVinculo,
                                                          pCdRelacaoTrabalho        => pCEF(i).CdRelacaoTrabalho,
                                                          pCdRegimeTrabalho         => pCEF(i).CdRegimeTrabalho,
                                                          pCdRegimePrevidenciario   => pCEF(i).CdRegimePrevidenciario,
                                                          pCdSituacaoPrevidenciaria => pCEF(i).CdSituacaoPrevidenciaria,
                                                          pCdUnidadeOrganizacional  => pCEF(i).CdUnidadeOrganizacional,
                                                          pCdEstruturaCarreira      => pCEF(i).CdEstruturaCarreira,
                                                          pFlTipoProvimento         => pCEF(i).FlEfetivacao,
                                                          pCdMotivoMovimentacao     => pCEF(i).CdMotivoMovimentacao,
                                                          pCdInstitutoMovimentacao  => pCEF(i).CdInstitutoMovimentacao) OR pCEF(i)
                  .CdRelacaoTrabalho = PKGPAG_TIPO.cnRelCTISP) AND
                  NOT (FRecebidoComPagtoNaOrigem(pCEF(i).CdVinculo,
                                                 pCEF(i).CdRelacaoTrabalho,
                                                 pCEF(i).FlPrincipal) AND
                   vDtFimDisposicao > pFolha.DtCalculo) THEN
                  
                  IF FGeraAuxilioAlimentacao(pCdOrgao     => vCdOrgaoAuxilio,
                                             pCdVinculo   => pCEF(i).CdVinculo,
                                             pCdSitPrev   => pCEF(i).CdSituacaoPrevidenciaria,
                                             pCdRelTrab   => pCEF(i).CdRelacaoTrabalho,
                                             pCdUnidOrg   => pCEF(i).CdUnidadeOrganizacional,
                                             pCdEstrutura => pCEF(i).CdEstruturaCarreira) THEN
                     
                     -- Caso o servidor possua mais de uma carga horaria/mes para o mesmo CEF
                     
                     vContCargaHoraria    := 0;
                     vVlAuxilioAliCHOAcum := 0;
                     
                     FOR j IN PKGPAG_VAR.vgCargaHoraria.FIRST .. PKGPAG_VAR.vgCargaHoraria.LAST LOOP
                        
                        vDescritivo := NULL;
                        
                        vCHTotalCEF := FObterCargaHorariaTotalCEF(pCargaHoraria      => PKGPAG_VAR.vgcargahoraria,
                                                                  pCdHistCargoEfeivo => pCEF(i).CdHistCargoEfetivo,
                                                                  pDtInicio          => PKGPAG_VAR.vgcargahoraria(j).DtInicio,
                                                                  pDtFim             => PKGPAG_VAR.vgcargahoraria(j).DtFim);
                        
                        IF PKGPAG_VAR.vgcargahoraria(j).CdHistCargoEfetivo <> pCEF(i).CdHistCargoEfetivo THEN
                           
                           CONTINUE;
                           
                        END IF;
                        
                        vContCargaHoraria := PKGPAG_VAR.vgCargaHoraria.Count;
                        
                        -- Trata valores nulos
                        IF PKGPAG_VAR.vgCargaHoraria(j).dtInicio IS NULL THEN
                           
                           PKGPAG_VAR.vgCargaHoraria(j).dtInicio := pFolha.DtInicioMes;
                           
                        END IF;
                        
                        IF PKGPAG_VAR.vgCargaHoraria(j).dtFim IS NULL THEN
                           
                           PKGPAG_VAR.vgCargaHoraria(j).dtFim := pFolha.DtFimMes;
                           
                        END IF;
                        
                        -- Caso o servidor esteja afastado o mes todo, nao possua decisao judicial ou o motivo de afastamento
                        -- nao esta na decisao judicial nao permite gerar auxilio alimentacao
                        --  SO CALCULA AUXILIOPARA OS SERVIDORES QUE NAO ESTAO AFASTADOS O MES TODO
                        -- OU QUE POSSUEM DECISAO JUDICIAL
                        IF PKGPAG_VAR.vMotAfast.InAfastado =
                           PKGPAG_TIPO.cnAfastadoMesTodo THEN
                           
                           IF PKGPAG_VAR.vgListaAfastDecJudAlim IS NOT NULL AND
                              PKGPAG_VAR.vgAfastTempNaoRemun.Count > 0 THEN
                              
                              FOR I IN PKGPAG_VAR.vgAfastTempNaoRemun.First .. PKGPAG_VAR.vgAfastTempNaoRemun.Last LOOP
                                 
                                 -- Verifica se o cdmotivoafastamento esta na lista dos motivos de afastamentos da decisao judicial
                                 -- se NAO estiver, nao permite calcular o auxilio
                                 IF NVL(INSTR(PKGPAG_VAR.vgListaAfastDecJudAlim,
                                              ';' || PKGPAG_VAR.vgAfastTempNaoRemun(I).CdMotivoAfastamento || ';'),
                                        0) = 0 THEN
                                    
                                    PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim',
                                                           'Afastado o mês todo - Não tem direito ao auxílio alimentação');
                                    
                                    RETURN;
                                    
                                 ELSE
                                    
                                    EXIT;
                                    
                                 END IF;
                                 
                              END LOOP;
                              
                           ELSE
                              -- se estiver afastado o mes todo e nao possuir decisao judicial nao calcula auxilio alimentacao
                              PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim',
                                                     'Afastado o mês todo - Não tem direito ao auxílio alimentação');
                              RETURN;
                              
                           END IF;
                        END IF;
                        
                        IF (pCEF(i).CdRelacaoTrabalho <> 10) OR -- a disposicao
                           (pCEF(i)
                           .CdRelacaoTrabalho = 10 AND PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN
                            pFolha.DtInicioMes AND pFolha.DtFimMes) OR (NOT
                            PKGPAG_GERAL.FDisposicaoParcialNoMes(pCEF(i),
                                                                                                              pFolha)) THEN
                           
                           vNuDiasMes := PKGPAG_VAR.vgCargaHoraria(j).dtFim - PKGPAG_VAR.vgCargaHoraria(j).dtInicio + 1;
                           --Caso o servidor tenha voltado da disposicao em outro agrupamento, considera a data inicial a data da disposicao
                           vDtInicio := CASE
                                           WHEN j = 1 AND vDtFimDisposicao IS NOT NULL THEN
                                            vDtFimDisposicao + 1
                                           ELSE
                                            PKGPAG_VAR.vgCargaHoraria(j).dtInicio
                                        END;
                           
                           -- Caso o servidor tenha mais de 70 anos nao tem direito
                           IF TRUNC(MONTHS_BETWEEN(pFolha.DtFimMes,
                                                   PKGPAG_VAR.vgVinculo.DtNascimento)) >= 900 AND pCEF(i)
                             .CdRelacaoTrabalho <> PKGPAG_TIPO.cnRelACT THEN
                              
                              vDtFim := ADD_MONTHS(PKGPAG_VAR.vgVinculo.DtNascimento,
                                                   900);
                              
                           ELSE
                              
                              IF PKGPAG_VAR.bSemIntersticio AND
                                 TO_CHAR(PKGPAG_VAR.vgCargaHoraria(j).dtFim,
                                         'DD') = 31 THEN
                                 
                                 --Desconta o dia 31
                                 vDtFim := PKGPAG_VAR.vgCargaHoraria(j).dtFim - 1;
                                 
                              ELSE
                                 
                                 vDtFim := PKGPAG_VAR.vgCargaHoraria(j).dtFim;
                                 
                              END IF;
                              
                           END IF;
                           
                        ELSE
                           
                           vNuDiasMes := TO_CHAR(PKGPAG_VAR.vgCargaHoraria(j).DtFim,
                                                 'DD');
                           
                           -- A disposicao com onus na origem
                           IF pcef(I).cdrelacaotrabalho = 10 AND
                               PKGPAG_VAR.vpagasitdisposicao <>
                               'PAG-DISP-ONUS-ORIGEM' THEN
                              
                              vDtInicio := CASE
                                              WHEN PCEF(i).dtinicioVinculo < pFolha.DtInicioMes THEN
                                               pFolha.DtInicioMes
                                              ELSE
                                               PCEF(i).dtinicioVinculo
                                           END;
                           ELSE
                              
                              vDtInicio := PKGPAG_VAR.vgCargaHoraria(j).DtInicio + 1;
                              
                           END IF;
                           
                           IF TRUNC(MONTHS_BETWEEN(pFolha.DtFimMes,
                                                   PKGPAG_VAR.vgVinculo.DtNascimento)) >= 900 THEN
                              
                              vDtFim := ADD_MONTHS(PKGPAG_VAR.vgVinculo.DtNascimento,
                                                   900);
                              
                           ELSE
                              
                              vDtFim := PKGPAG_VAR.vgCargaHoraria(j).dtFim;
                              
                           END IF;
                           
                        END IF;
                        
                        PKGAFA.PCalcularDiasEvento(pCdVinculo               => pCEF(i).CdVinculo,
                                                   pCdEstruturaCarreira     => pCEF(i).CdEstruturaCarreira,
                                                   pDtInicio                => case
                                                                                  when j = 1 then --primeiro loop pega a data do calculo anterior
                                                                                   PKGPAG_VAR.vDtCalculoAnt + 1
                                                                                  else
                                                                                   PKGPAG_VAR.vgCargaHoraria(j).dtInicio
                                                                               end,
                                                   pDtFim                   => case
                                                                                  when PKGPAG_VAR.vgCargaHoraria(j).dtFim <
                                                                                        PKGPAG_VAR.vDtCalculo then
                                                                                   PKGPAG_VAR.vgCargaHoraria(j).dtFim
                                                                                  else
                                                                                   PKGPAG_VAR.vDtCalculo
                                                                               end,
                                                   pCdEventoAfastamento     => 11,
                                                   pFlVerificaPeriodoPA     => 'S',
                                                   pCdAgrupamento           => pFolha.CdAgrupamento,
                                                   pCdOrgao                 => pFolha.CdOrgao,
                                                   pCdUnidadeOrganizacional => pCEF(i).CdUnidadeOrganizacional,
                                                   pNuTipoDiaNaoUtil        => case
                                                                                  when PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias is not null then
                                                                                   7 -- Para DPE, considerar dias nao uteis apenas sábados e domingos
                                                                                  else
                                                                                   PKGPAG_VAR.vgNuTipoDiaNaoUtil
                                                                               end,
                                                      
                                                   pFlConsideraDataInclusao => case
                                                                                  when PKGPAG_VAR.vgFolha.CdTipoFolha =
                                                                                       PKGPAG_TIPO.cnTpFolhaFunebre then
                                                                                   PKGPAG_TIPO.cnN
                                                                                  else
                                                                                   PKGPAG_TIPO.cnS
                                                                               end,
                                                   pCdOpcaoAuxilioAli       => PKGPAG_VAR.vgVinculo.CdOpcaoAuxilioAli,
                                                   pDtReferencia            => PKGPAG_VAR.vDtCalculo,
                                                   pListaAfastDecJudAlim    => PKGPAG_VAR.vgListaAfastDecJudAlim,
                                                   pDtFimRelacao            => pCEF(i).DtFim,
                                                   pDtIniLimite             => ADD_MONTHS(pFolha.DtInicioMes,
                                                                                          -1 *
                                                                                          PKGMOVFRE.cn_Qt_Mes_Retro_Falta),
                                                   pFlCalculoGeral          => PKGPAG_VAR.vgCalculo.flgeral);
                        
                        vNuDiasAfastAtual := PKGAFA.FQtDiasAtual;
                        
                        --Retorna o valor: vNuDiasAfastRetro
                        begin
                           
                           vAfastVinc := fCalculaDiasAfastamentoRetro(pCEF                     (i).CdVinculo,
                                                                      pFolha,
                                                                      pCEF                     (i).CdUnidadeOrganizacional,
                                                                      pCEF                     (i).CdEstruturaCarreira,
                                                                      PKGPAG_VAR.vgcargahoraria(j).nucargahoraria,
                                                                      PKGPAG_VAR.vgCargaHoraria(vContCargaHoraria).nucargahorariatotal,
                                                                      pCef                     (i).DtInicio,
                                                                      pCef                     (i).DtFim,
                                                                      vCdRubAgrup_01_0157);
                           
                        exception
                           
                           when others then
                              
                              vAfastVinc.nudiasafastretroanulado := 0;
                              vAfastVinc.nudiasafastretro        := 0;
                              vAfastVinc.nudiasafastmes          := 0;
                              vAfastVinc.nudiassemrelacao        := 0;
                              
                        end;
                        
                        -- Retorna o numero de dias uteis
                        vNuDiasUteis := FRetornaDiasUteis(pCEF(i).CdUnidadeOrganizacional,
                                                          pFolha.DtInicioMes,
                                                          pFolha.DtFimMes,
                                                          PKGPAG_VAR.vgNuTipoDiaNaoUtil);
                        
                        -- retorna o numero de vales
                        vNuVales := FRetornaDiasUteis(pCEF(i).CdUnidadeOrganizacional,
                                                      vDtInicio,
                                                      vDtFim,
                                                      PKGPAG_VAR.vgNuTipoDiaNaoUtil);
                        
                        IF vNuVales > vNuDiasUteis THEN
                           
                           vNuVales := vNuDiasUteis;
                           
                        END IF;
                        
                        vFlAfastadoMesTodo := 'N';
                        begin
                           
                           vRetorno := fCalculaDiasAfastamentoMes(pCEF                       (i).CdVinculo,
                                                                  pFolha,
                                                                  pCEF                       (i).CdUnidadeOrganizacional,
                                                                  pCEF                       (i).CdEstruturaCarreira,
                                                                  PKGPAG_VAR.vgcargahoraria  (j).nucargahoraria,
                                                                  PKGPAG_VAR.vgCargaHoraria  (vContCargaHoraria).nucargahorariatotal,
                                                                  pCef                       (i).DtInicio,
                                                                  pCef                       (i).DtFim,
                                                                  vAfastVinc.nudiassemrelacao,
                                                                  vAfastVinc.nudiasafastmes,
                                                                  vNuVales,
                                                                  vFlAfastadoMesTodo);
                           
                        exception
                           when others then
                              vRetorno := 0;
                        end;
                        
                        -- Tratamento para afastamentos em meses de 31 dias
                        IF vAfastVinc.nudiasafastmes > 0 AND
                           vFlAfastadoMesTodo = 'N' AND
                           PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes,
                                                          'N') = 31 THEN
                           
                           vAfastadoUltDiaMes := 'N';
                           
                           IF PKGPAG_VAR.vgAfastTempRemun.FIRST > 0 THEN
                              
                              FOR cAfastRemun in PKGPAG_VAR.vgAfastTempRemun.FIRST .. PKGPAG_VAR.vgAfastTempRemun.LAST LOOP
                                 
                                 IF PKGPAG_VAR.vgAfastTempRemun(cAfastRemun).FlUltimoDiaMes = 'S' THEN
                                    
                                    vAfastadoUltDiaMes := 'S';
                                    EXIT;
                                    
                                 END IF;
                                 
                              END LOOP;
                              
                           END IF;
                           
                           IF vAfastadoUltDiaMes = 'N' THEN
                              
                              IF PKGPAG_VAR.vgAfastTempNaoRemun.FIRST > 0 THEN
                                 
                                 FOR cAfastNaoRemun in PKGPAG_VAR.vgAfastTempNaoRemun.FIRST .. PKGPAG_VAR.vgAfastTempNaoRemun.LAST LOOP
                                    
                                    IF PKGPAG_VAR.vgAfastTempNaoRemun(cAfastNaoRemun).FlUltimoDiaMes = 'S' THEN
                                       
                                       vAfastadoUltDiaMes := 'S';
                                       EXIT;
                                       
                                    END IF;
                                    
                                 END LOOP;
                                 
                              END IF;
                              
                           END IF;
                           
                           IF vAfastadoUltDiaMes = 'S' THEN
                              
                              vAfastVinc.nudiasafastmes := vAfastVinc.nudiasafastmes - 1;
                              
                           END IF;
                           
                        END IF;
                        
                        vNuDiasAfastRetro := vAfastVinc.nudiasafastretro;
                        
                        --
                        -- Verificar se faltas estornadas retroativas devem gerar rubrica 02-0157
                        -- Ver se recebeu vale no mes, falta ver o numero de dias estornados ou se tinha direito ao vale
                        -- talvez se recebeu
                        
                        vNuDiasAbonoRetro := 0;
                        
                        if PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis > 0 then
                           
                           vNuDiasAbonoRetro := PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis;
                           -- Verificar se teve faltas abonadas e o estorno e devido por ter recebido no mes ou nao
                           if PKGPAG_VAR.vgFaltas.Count > 0 then
                              
                              for j in PKGPAG_VAR.vgFaltas.first .. PKGPAG_VAR.vgFaltas.last
                                 
                               loop
                                 
                                 if pkgpag_geral.frecebeurubrica(pcdvinculo     => pCEF(i).CdVinculo,
                                                                 pcdrubrica     => pRubrica.CdRubricaAgrupamento,
                                                                 pnuanomes      => to_char(PKGPAG_VAR.vgFaltas(j).DtFrequencia,
                                                                                           'yyyymm'),
                                                                 pnumeses       => 0,
                                                                 pcdtipocalculo => 1,
                                                                 pcdtipofolha   => null,
                                                                 pcdfolhaatual  => null) < 0 and
                                    vNuDiasAbonoRetro < PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite then
                                    
                                    vNuDiasAbonoRetro := vNuDiasAbonoRetro - 1;
                                    
                                 end if;
                                 
                              end loop;
                              
                              if vNuDiasAbonoRetro < 0 then
                                 
                                 vNuDiasAbonoRetro := 0;
                                 
                              end if;
                              
                           end if;
                           
                        end if;
                        
                        vNuDiasAfastRetroAnulado := vAfastVinc.nudiasafastretroanulado +
                                                    vNuDiasAbonoRetro; --PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis;
                        
                        -- retorna o valor diario do vale
                        vvlAuxilio := FRetornaValorAuxilioCEF(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdValorAuxilio,
                                                              pCdEstruturaCarreira => pCEF(i).CdEstruturaCarreira,
                                                              pVlAuxilio           => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).VlAuxilioCEF,
                                                              pNuNivel             => pCEF(i).NuNivelPagamento,
                                                              pNuCargaHoraria      => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria);
                        
                        -- Retorna o numero de dias uteis
                        vNuDiasUteis := FRetornaDiasUteis(pCEF(i).CdUnidadeOrganizacional,
                                                          pFolha.DtInicioMes,
                                                          pFolha.DtFimMes,
                                                          PKGPAG_VAR.vgNuTipoDiaNaoUtil);
                        
                        -- retorna o numero de vales
                        vNuVales := FRetornaDiasUteis(pCEF(i).CdUnidadeOrganizacional,
                                                      vDtInicio,
                                                      vDtFim,
                                                      PKGPAG_VAR.vgNuTipoDiaNaoUtil);
                        
                        IF NOT vUtilizaNumeroFixoVA THEN
                           
                           -- Nao permite pagar mais que o numero de dias uteis do mes corrente
                           --Salva o valor maximo permitido pago num mes
                           IF (vNuVales > vNuDiasUteis OR
                              vNuVales > PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite) THEN
                              
                              vNuVales := vNuDiasUteis;
                              
                           END IF;
                           
                           -- 10006/2017 - FOLHA - AUXILIO ALIMENTACAO
                           vValorLimite := vvlAuxilio *
                                           (LEAST(vNuDiasUteis,
                                                  PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite));
                           -- - vNuDiasAfastAtual));
                           
                           IF PKGPAG_VAR.vgFolha.CdTipoCalculo =
                              PKGPAG_TIPO.cnTpCalculoRecalculoMes THEN
                              
                              FOR rVlOutroVinculo IN (SELECT SUM(nvl(rv.vlpagamento,
                                                                     0)) vlpagamento
                                                        INTO vValorAuxAlimAtual
                                                        FROM epaghistoricorubricavinculo rv
                                                       INNER JOIN epagfolhapagamento fp
                                                          ON fp.cdfolhapagamento =
                                                             rv.cdfolhapagamento
                                                         AND fp.flcalculodefinitivo = 'S'
                                                         AND fp.cdfolhapagamento <>
                                                             pfolha.CdFolhaPagamento
                                                       WHERE rv.cdvinculo IN
                                                             (SELECT cdvinculo
                                                                FROM ecadvinculo
                                                               WHERE CdPessoa =
                                                                     PKGPAG_VAR.vgVinculo.cdPessoa
                                                                 AND CdVinculo <> pCEF(i).CdVinculo
                                                                 AND (DtDesligamento IS NULL OR
                                                                     DtDesligamento >=
                                                                     pFolha.DtInicioMes))
                                                         AND fp.cdagrupamento =
                                                             pfolha.CdAgrupamento
                                                         AND fp.nuanoreferencia =
                                                             pfolha.NuAnoReferencia
                                                         AND fp.numesreferencia =
                                                             pfolha.NuMesReferencia
                                                         AND rv.cdrubricaagrupamento =
                                                             PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                          1,
                                                                                          157)) LOOP
                                 
                                 -- Soma o valor descontado de Aux Alimentacao  nos outros vinculos
                                 vValorAuxAlimAtual := nvl(vValorAuxAlimAtual,
                                                           0) +
                                                       rVlOutroVinculo.Vlpagamento;
                                 
                                 IF vValorAuxAlimAtual >= vValorLimite THEN
                                    
                                    RETURN;
                                    
                                 ELSE
                                    
                                    vValorLimite := vValorLimite -
                                                    vValorAuxAlimAtual;
                                    
                                 END IF;
                                 
                              END LOOP;
                              
                           END IF;
                           
                           PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim',
                                                  'CEF ' || i ||
                                                  ' - Dias AfastAtual/AfastRetro/noMes/Uteis/Faltas/AfastRetroAnul :' ||
                                                  vNuDiasAfastAtual || '/' ||
                                                  vNuDiasMes || '/' ||
                                                  vNuDiasUteis || '/' ||
                                                  PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis || '/' ||
                                                  vNuDiasAfastRetroAnulado);
                           
                           vDescritivo := vDescritivo || '(' || vNuVales || '-' ||
                                          vNuDiasAfastAtual ||
                                          'Afast - ' ||
                                          PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis ||
                                          'Falta';
                           
                           --Numero de Vales descontando as faltas
                           vNuVales := vNuVales - vNuDiasAfastAtual -
                                       PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis;
                           
                           IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 1 THEN
                              
                              vNuVales := vNuVales - vNuDiasAfastRetro;
                              
                              vDescritivo := vDescritivo || '-' ||
                                             vNuDiasAfastRetro ||
                                             'AfaRetro';
                              
                           END IF;
                           
                           vDescritivo := vDescritivo || ')->' ||
                                          vNuVales;
                           
                           IF vNuVales < 0 THEN
                              --
                              -- Calcular saldo de faltas para gerar rubrica 08-0157 na pkgpag_pos
                              --
                              if pKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis > 0 then
                                 
                                 vNuFaltasNaoDesc := vNuVales;
                                 
                                 vValorFaltasNaoDesc := abs(vVlAuxilio *
                                                            vNuVales);
                                 
                              end if;
                              
                              vNuVales := 0;
                              
                           END IF;
                           
                           -- Se a relacao do vinculo principal for o comissionado
                           IF pCCO.count > 0 AND PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).FlPriorizaCCO = 'S' AND
                              PKGPAG_VAR.vgRelVincPrincipal.Tipo = 2 THEN
                              
                              --Verifica o numero de dias de afastamento
                              FOR vDia IN (SELECT A.DtDia
                                             FROM (SELECT vDtInicio +
                                                          (LEVEL - 1) AS dtdia
                                                     FROM dual
                                                   CONNECT BY vDtInicio +
                                                              (LEVEL - 1) BETWEEN
                                                              vDtInicio AND
                                                              vDtFim) A
                                            INNER JOIN (SELECT CASE
                                                                 WHEN Av.DtInicio <=
                                                                      vDtInicio THEN
                                                                  vDtInicio
                                                                 ELSE
                                                                  Av.DtInicio
                                                              END AS DtInicio,
                                                              CASE
                                                                 WHEN Av.DtFim >=
                                                                      pFolha.dtFimMes OR
                                                                      Av.DtFim IS NULL THEN
                                                                  pFolha.dtFimMes
                                                                 ELSE
                                                                  Av.DtFim
                                                              END AS DtFim
                                                         FROM EAfaAfastamentoRelVinc AV
                                                        WHERE AV.CdHistCargoEfetivo = pCEF(i).CdHistRelVinc
                                                          AND AV.CdHistCargoComGerador IS NOT NULL
                                                          AND ((AV.DtInicio <=
                                                              pFolha.dtFimMes AND
                                                              (AV.DtFim >=
                                                              pFolha.dtInicioMes OR
                                                              AV.DtFim IS NULL)) OR
                                                              (AV.DtInclusao BETWEEN
                                                              pFolha.dtInicioMes AND
                                                              pFolha.dtFimMes))
                                                          AND EXISTS
                                                        (SELECT 1
                                                                 FROM ECadHistCargoCom HCC
                                                                WHERE HCC.CdHistCargoCom =
                                                                      AV.CdHistCargoComGerador
                                                                  AND HCC.FlTipoProvimento IN
                                                                      ('D',
                                                                       'N')
                                                                  AND HCC.CdOpcaoRemuneracao <> 7)
                                                          AND AV.FlAnulado = 'N') B
                                               ON A.DtDia >= B.DtInicio
                                              AND A.DtDia <= B.DtFim) LOOP
                                 
                                 vNuVales := vNuVales -
                                             FRetornaDiasUteis(pCEF(i).CdUnidadeOrganizacional,
                                                               vDia.DtDia,
                                                               vDia.DtDia,
                                                               PKGPAG_VAR.vgNuTipoDiaNaoUtil);
                                 
                                 vNuDiasAfastRetroAnulado := 0;
                                 
                              END LOOP;
                              
                              IF vNuVales < 0 THEN
                                 
                                 vNuVales := 0;
                                 
                              END IF;
                              
                              vDescritivo := vDescritivo ||
                                             '-> PriorCCO =' || vNuVales;
                              
                           END IF;
                           
                           IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 1AND
                             vNuDiasAfastRetroAnulado > 0 THEN
                              
                              vNuVales := vNuVales +
                                          vNuDiasAfastRetroAnulado;
                              
                              vDescritivo := vDescritivo || '-' ||
                                             vNuDiasAfastRetroAnulado ||
                                             'AfaRetroAnul ->' ||
                                             vNuVales;
                              
                           END IF;
                           
                           -- Aplica limite de numero de vales
                           IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite IS NOT NULL THEN
                              
                              vNuVales := LEAST(vNuVales,
                                                PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite);
                              
                           END IF;
                           
                        ELSE
                           
                           vCdRelacaoVinculo := PKGPAG_TIPO.cnTpRelacaoEfetivo;
                           
                           vIndiceProporcao := FObterIndiceProporcao(pRubrica               => pRubrica,
                                                                     pNuCHOPadraoCEF        => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria,
                                                                     pNuCargaHoraria        => vCHTotalCEF,
                                                                     pMediaCHOHoraAtividade => PKGPAG_VAR.vgMediaCHOHoraAtividade);
                           
                           /* somatório de dias mês das relações não pode ser superior a 30 */
                           IF vNuDiasMes > 30 OR
                              vNuDiasMes =
                              TO_CHAR(pFolha.DtFimMes, 'DD') THEN
                              
                              vNuDiasMes := 30;
                              
                           END IF;
                           
                           IF pFolha.CdAgrupamento IN (1, 134) THEN
                              
                              vNuDiasMesTodosVinc := vNuDiasMesTodosVinc +
                                                     vNuDiasMes;
                              
                              IF vNuDiasMesTodosVinc > 30 THEN
                                 
                                 vNuDiasMes := vNuDiasMes -
                                               (LEAST(vNuDiasMesTodosVinc,
                                                      60) - 30);
                                 
                              END IF;
                              
                           END IF;
                           
                           /*********************************************************************
                           **  DEFENSORIA PUBLICA POSSUI VALOR FIXO DE VALE EQUIVALENTE A 22 DIAS
                           *********************************************************************/
                           PAjusteNuDiasFixo(pCdAgrupamento           => pFolha.CdAgrupamento,
                                             pCdOrgao                 => vCdOrgaoAuxilio, ---pFolha.CdOrgao,
                                             pCdUnidadeOrganizacional => pCEF(i).CdUnidadeOrganizacional,
                                             pCdRelacaoVinculo        => vCdRelacaoVinculo,
                                             pDtInicioRelacao         => pCEF(i).DtInicioRelacao,
                                             pDtFimRelacao            => pCEF(i).DtFimRelacao,
                                             pDtInicioMesFolha        => pFolha.DtInicioMes,
                                             pDtFimMesFolha           => pFolha.DtFimMes,
                                             pNuDiasAfastamentoMes    => vAfastVinc.nudiasafastmes,
                                             pCdVinculo               => pCdVinculo,
                                             pDtIniCHO                => PKGPAG_VAR.vgcargahoraria(j).dtInicio,
                                             pDtFinalCHO              => PKGPAG_VAR.vgcargahoraria(j).dtFim,
                                             pIndiceProporcao         => vIndiceProporcao,
                                             pVlAuxilioAliCHOAcum     => vVlAuxilioAliCHOAcum);
                           
                        END IF;
                        
                        /***********************************************************************/
                        
                        IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdBaseCalculo IS NULL THEN
                           
                           IF NOT vUtilizaNumeroFixoVA THEN
                              
                              vvlIntegral := FCalculaValorIntegralCEF(vNuVales,
                                                                      vvlAuxilio);
                              
                              --Inicia o indice de proporcao
                              vIndiceProporcao := 1;
                              
                              IF pRubrica.CdRubProporcionalidadeCHO = 2 THEN
                                 
                                 IF pRubrica.FlCargaHorariaPadrao = 'S' THEN
                                    
                                    vNuCHOPadrao := PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria;
                                    
                                 ELSE
                                    
                                    vNuCHOPadrao := pRubrica.NuCargaHorariaSemanal;
                                    
                                 END IF;
                                 
                                 IF vNuCHOPadrao > 0 THEN
                                    
                                    ---------------------------------------------------------------------
                                    -- A variavel global PKGPAG_VAR.vgMediaCHOHoraAtividade = NULL,
                                    -- indica que este servidor nao possui o evento Hora Atividade
                                    ---------------------------------------------------------------------
                                    IF PKGPAG_VAR.vgMediaCHOHoraAtividade IS NULL THEN
                                       
                                       IF pRubrica.FlCargaHorariaLimitada = 'N' THEN
                                          
                                          vIndiceProporcao := PKGPAG_VAR.vgCargaHoraria(j).NuCargaHoraria /
                                                               vNuCHOPadrao;
                                          
                                       ELSE
                                          
                                          vIndiceProporcao := CASE
                                                                 WHEN PKGPAG_VAR.vgCargaHoraria(j)
                                                                  .NuCargaHoraria > vNuCHOPadrao THEN
                                                                  1
                                                                 ELSE
                                                                  PKGPAG_VAR.vgCargaHoraria(j)
                                                                  .NuCargaHoraria / vNuCHOPadrao
                                                              END;
                                       END IF;
                                       
                                       vProporcional.vlProporcional := TRUNC(vvlIntegral *
                                                                             vIndiceProporcao,
                                                                             2);
                                       vProporcional.vlIntegral     := vProporcional.vlProporcional;
                                       
                                    ELSE
                                       
                                       vIndiceProporcao             := (PKGPAG_VAR.vgMediaCHOHoraAtividade /
                                                                       vNuCHOPadrao);
                                       vProporcional.vlProporcional := vvlIntegral *
                                                                       vIndiceProporcao;
                                       vProporcional.vlIntegral     := vProporcional.vlProporcional;
                                       
                                    END IF;
                                    
                                 ELSE
                                    
                                    vProporcional.vlIntegral     := vvlIntegral;
                                    vProporcional.vlProporcional := vvlIntegral;
                                    
                                 END IF;
                                 
                              END IF;
                              
                           END IF;
                           
                           vValorAuxAlimAtual   := vProporcional.vlProporcional;
                           vNuValesAuxAlimAtual := vNuVales;
                           
                           IF pFolha.CdAgrupamento IN (1, 134) THEN
                              
                              vDescritivo := vDescritivo || '->R$ ' ||
                                             vvlIntegral || ' ->Prop ' ||
                                             vIndiceProporcao || '->R$ ' ||
                                             vValorAuxAlimAtual;
                              
                           ELSE
                              
                              vDescritivo := vDescritivo || '->Prop ' ||
                                             vIndiceProporcao || '->R$' ||
                                             vProporcional.vlProporcional ||
                                             ' p/ ' || vNuVales ||
                                             ' vales';
                           END IF;
                           
                           ------------------------------------------------------------------------------
                           -- Aplica indice de decisao judicial
                           ------------------------------------------------------------------------------
                           IF NVL(vlIndiceAuxAliDecJud, 0) > 0 THEN
                              
                              vIndiceProporcao             := (vlIndiceAuxAliDecJud / 100);
                              vProporcional.vlProporcional := vvlIntegral *
                                                              vIndiceProporcao;
                              vProporcional.vlIntegral     := vProporcional.vlProporcional;
                              vValorAuxAlimAtual           := vProporcional.vlProporcional;
                              
                              vDescritivo := vDescritivo || '->DecJud->' ||
                                             vvlIntegral || '*' ||
                                             vlIndiceAuxAliDecJud || '%' ||
                                             '->R$' ||
                                             vProporcional.vlProporcional;
                              
                           END IF;
                           
                           ------------------------------------------------------------------------------
                           -- Retorna o valor do saldo devedor
                           ------------------------------------------------------------------------------
                           PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                                                                                      pCdVinculo        => pCdVinculo,
                                                                                                      pCdRubrica        => PKGPAG_VAR.vgCdRubBaseAlimRetroNaoDesc);
                           
                           PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim',
                                                  'CEF ' || i ||
                                                  ' - NuVales/ValorVales/SaldoDevedor :' ||
                                                  vNuValesAuxAlimAtual || '/' ||
                                                  vValorAuxAlimAtual || '/' ||
                                                  PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc);
                           
                           -----------------------------------------------------------------------------
                           --  Dias retroativos devem ser descontados em rubrica separada
                           -----------------------------------------------------------------------------
                           
                           vvlAuxilio := NULL;
                           
                           IF vNuDiasAfastRetro > 0 AND PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 2 THEN
                              
                              begin
                                 
                                 vvlAuxilio := FRetornaValorAuxilioCEF(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                       pCdEstruturaCarreira => pCEF(i).CdEstruturaCarreira,
                                                                       pVlAuxilio           => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).VlAuxilioCEF,
                                                                       pNuNivel             => pCEF(i).NuNivelPagamento,
                                                                       pNuCargaHoraria      => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria);
                                 
                              exception
                                 
                                 when others then
                                    
                                    vvlAuxilio := FRetornaValorAuxilioCEF(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                          pCdEstruturaCarreira => pCEF(i).CdEstruturaCarreira,
                                                                          pVlAuxilio           => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).VlAuxilioCEF,
                                                                          pNuNivel             => pCEF(i).NuNivelPagamento,
                                                                          pNuCargaHoraria      => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria);
                                    
                              end;
                              -- SIG-9026 0157 nao proporcional em desconto automatico
                              vValorAuxAlimRetro := vAfastVinc.vltotaldescauxaliretro;
                              
                           ELSE
                              vValorAuxAlimRetro := 0;
                           END IF;
                           
                           -- Caso possua mais de um vinculo ativo
                           IF vNuDiasAfastRetro > 0 AND
                              (PKGPAG_GERAL.FVinculosVigentes(pCdPessoa    => PKGPAG_VAR.vgVinculo.cdpessoa,
                                                              pDtInicioMes => pFolha.DtInicioMes) > 1) THEN
                              
                              FOR rOutroVinculo IN cOutroVinculo LOOP
                                 
                                 -- Soma o valor descontado de Aux Alimentacao Retroativo nos outros vinculos
                                 vValorAuxAlimRetroDesc := vValorAuxAlimRetroDesc +
                                                             
                                                           PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                                                             pCdVinculo        => rOutroVinculo.CdVinculo,
                                                                                             pCdRubrica        => PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                                                                                               8,
                                                                                                                                               157));
                              END LOOP;
                              
                              -- Se o valor calculado do retroativo e maior que o valor descontado,
                              -- desconta o valor da diferenca.
                              IF vValorAuxAlimRetro >=
                                 vValorAuxAlimRetroDesc THEN
                                 vValorAuxAlimRetro := vValorAuxAlimRetro -
                                                       vValorAuxAlimRetroDesc;
                              ELSE
                                 vValorAuxAlimRetro := 0;
                              END IF;
                              
                           END IF;
                           
                           IF vNuDiasAfastRetro > 0 OR
                              PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc > 0 THEN
                              vValorSaldoAuxAlimRetro := nvl(vValorAuxAlimRetro,
                                                             0) +
                                                         nvl(PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc,
                                                             0);
                              
                              vDescritivoRetro := 'RETRO(R$' ||
                                                  nvl(vValorAuxAlimRetro,
                                                      0) ||
                                                  ' AfaRetro + R$ ' ||
                                                  nvl(PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc,
                                                      0) ||
                                                  ') Saldo-> R$ ' ||
                                                  vValorSaldoAuxAlimRetro;
                              
                              vValorAuxAlimRetro := vValorSaldoAuxAlimRetro;
                              
                              PKGPAG_VAR.vNuDiasAuxAlimNaoDesc := vNuDiasAfastRetro;
                              
                              PKGPAG_VAR.vDescAuxAlimNaoDesc := vDescritivoRetro;
                              
                           END IF;
                           
                           IF vValorAuxAlimRetro > 0 AND PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 2 AND
                              (NOT vGerouRubrica080157) THEN
                              
                              IF vValorAuxAlimRetro > 0 THEN
                                 
                                 PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := vValorAuxAlimRetro;
                                 
                                 PKGPAG_VAR.vNuDiasAuxAlimNaoDesc := vNuDiasAfastRetro;
                                 
                                 PKGPAG_VAR.vDescAuxAlimNaoDesc := vDescritivoRetro;
                                 
                              ELSE
                                 
                                 PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
                                 
                              END IF;
                              
                           END IF;
                           
                           if vValorFaltasNaoDesc > 0 then
                              
                              PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc +
                                                                   vValorFaltasNaoDesc;
                              
                           end if;
                           
                           IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 2 AND
                               (PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).FlPriorizaCCO = 'N' OR PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).FlPriorizaCCO = 'S' AND
                                 PKGPAG_VAR.vgCCO.COUNT = 0) AND
                               PKGPAG_VAR.vgRelVincPrincipal.Tipo = 1 AND
                               pFolha.CdTipoFolha <>
                               pkgpag_tipo.cnTpFolhaFunebre THEN
                              
                              vCdRubrica020157 := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                               2,
                                                                               157);
                              
                              IF vNuDiasAfastRetroAnulado > 0 AND
                                 PKGPAG_GERAL.FGeraRubrica(vCdRubrica020157) AND
                                 NOT NVL(bPagouAuxilioDecJud, FALSE) THEN
                                 
                                 if vNuDiasAfastRetroAnulado < 0 then
                                    
                                    vNuDiasAfastRetroAnulado := 0;
                                    
                                 end if;
                                 
                                 IF vvlAuxilio IS NULL THEN
                                    
                                    BEGIN
                                       
                                       vvlAuxilio := FRetornaValorAuxilioCEF(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                             pCdEstruturaCarreira => pCEF(i).CdEstruturaCarreira,
                                                                             pVlAuxilio           => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).VlAuxilioCEF,
                                                                             pNuNivel             => pCEF(i).NuNivelPagamento,
                                                                             pNuCargaHoraria      => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria);
                                       
                                    EXCEPTION
                                       
                                       WHEN OTHERS THEN
                                          
                                          vvlAuxilio := FRetornaValorAuxilioCEF(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                                pCdEstruturaCarreira => pCEF(i).CdEstruturaCarreira,
                                                                                pVlAuxilio           => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).VlAuxilioCEF,
                                                                                pNuNivel             => pCEF(i).NuNivelPagamento,
                                                                                pNuCargaHoraria      => PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria);
                                    END;
                                    
                                 END IF;
                                 
                                 vValorAuxAlimRetroAnulado := vIndiceProporcao *
                                                              vNuDiasAfastRetroAnulado *
                                                              vvlAuxilio;
                                 
                                 IF PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc >=
                                    vValorAuxAlimRetroAnulado THEN
                                    
                                    PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc -
                                                                         vValorAuxAlimRetroAnulado;
                                    vValorAuxAlimRetroAnulado         := 0;
                                    
                                 ELSE
                                    
                                    vValorAuxAlimRetroAnulado         := vValorAuxAlimRetroAnulado -
                                                                         PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc;
                                    PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
                                    
                                 END IF;
                                 
                                 IF vValorAuxAlimRetroAnulado > 0 THEN
                                    
                                    PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                          pCdVinculo            => pCdVinculo,
                                                                          pCdRelacaoVinculo     => pCEF(i).CdRelacaoVinculo,
                                                                          pCdHistRelacaoVinculo => pCEF(i).CdHistCargoEfetivo,
                                                                          pCdExpressaoFormCalc  => NULL,
                                                                          pCdRubricaAgrupamento => vCdRubrica020157,
                                                                          pVlIntegral           => vValorAuxAlimRetroAnulado,
                                                                          pVlProporcional       => vValorAuxAlimRetroAnulado,
                                                                          pNuSufixoRubrica      => 1,
                                                                          pNuParcelas           => NULL,
                                                                          pVlIndice             => vNuDiasAfastRetroAnulado,
                                                                          pCdTipoOrigemRubrica  => 1,
                                                                          pDtInicio             => pCEF(i).DtInicio,
                                                                          pDtFim                => pCEF(i).DtFim);
                                    
                                 END IF;
                                 
                              END IF;
                              
                           END IF;
                           
                        END IF;
                        
                        --Salva o numero de dias de auxilio alimentacao pagos
                        vSomaTotalVlAuxAli := vSomaTotalVlAuxAli +
                                              vValorAuxAlimAtual;
                        
                        IF vSomaTotalVlAuxAli > vValorLimite THEN
                           
                           IF vSomaTotalVlAuxAli - vValorAuxAlimAtual <
                              vValorLimite THEN
                              
                              vDifValor          := vSomaTotalVlAuxAli -
                                                    vValorAuxAlimAtual;
                              vValorAuxAlimAtual := vValorLimite -
                                                    (vSomaTotalVlAuxAli -
                                                    vValorAuxAlimAtual);
                              vDescritivo        := vDescritivo ||
                                                    '->Abate R$' ||
                                                    vDifValor ||
                                                    ' OutRelVinc->R$' ||
                                                    vValorAuxAlimAtual;
                              
                           ELSE
                              
                              vValorAuxAlimAtual := 0;
                              
                           END IF;
                        END IF;
                        
                        IF vValorAuxAlimAtual > 0 AND vVlAuxilioPago > 0 THEN
                           
                           vValorAuxAlimAtual := FTrataValoresRecebidos(vValorAuxAlimAtual,
                                                                        vNuDiasAfastAtual);
                           
                        END IF;
                        
                        IF PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc = 0 AND
                           vValorAuxAlimAtual < 0 THEN
                           
                           PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := abs(vValorAuxAlimAtual);
                           
                           PKGPAG_VAR.vNuDiasAuxAlimNaoDesc := abs(vNuValesAuxAlimAtual);
                           
                        END IF;
                        
                        IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdBaseCalculo IS NOT NULL THEN
                           
                           PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                 pCdVinculo            => pCEF(i).CdVinculo,
                                                                 pCdRelacaoVinculo     => pCEF(i).CdRelacaoVinculo,
                                                                 pCdHistRelacaoVinculo => pCEF(i).CdHistCargoEfetivo,
                                                                 pCdExpressaoFormCalc  => NULL,
                                                                 pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                                 pVlIntegral           => NULL,
                                                                 pVlProporcional       => NULL,
                                                                 pNuSufixoRubrica      => 1,
                                                                 pNuParcelas           => NULL,
                                                                 pVlIndice             => vNuVales,
                                                                 pCdRubTotVantagem     => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdRubricaAgrupamento,
                                                                 pCdTipoOrigemRubrica  => 1,
                                                                 pDtInicio             => pCEF(i).DtInicio,
                                                                 pDtFim                => pCEF(i).DtFim,
                                                                 pDescritivo           => vDescritivo);
                        ELSE
                           
                           IF vValorAuxAlimAtual > 0 THEN
                              
                              PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                    pCdVinculo            => pCdVinculo,
                                                                    pCdRelacaoVinculo     => pCEF(i).CdRelacaoVinculo,
                                                                    pCdHistRelacaoVinculo => pCEF(i).CdHistCargoEfetivo,
                                                                    pCdExpressaoFormCalc  => NULL,
                                                                    pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                                    pVlIntegral           => vValorAuxAlimAtual,
                                                                    pVlProporcional       => vValorAuxAlimAtual,
                                                                    pNuSufixoRubrica      => 1,
                                                                    pNuParcelas           => NULL,
                                                                    pVlIndice             => vNuVales,
                                                                    pCdTipoOrigemRubrica  => 1,
                                                                    pDtInicio             => pCEF(i).DtInicio,
                                                                    pDtFim                => pCEF(i).DtFim,
                                                                    pDescritivo           => vDescritivo);
                              
                              vVlAuxilioAliCHOAcum := vVlAuxilioAliCHOAcum +
                                                      vValorAuxAlimAtual;
                              
                           END IF;
                           
                        END IF;
                        
                     END LOOP;
                     
                     -- Loop carga horaria
                     
                     -- Insere desconto de auxilio alimentacao retroativo (08-0157)
                     --
                     -- 9807/2017 - FOLHA - AUXILIO ALIMENTACAO EM CASO DE DUPLO VINCULO
                     -- O DESCONTO SO PODE OCORRER NO VINCULO EM QUE OCORRE O PAGAMENTO DA 01-0157.
                     --
                     if pFolha.CdAgrupamento = 176 and
                        vValorAuxAlimRetro > 0 and
                        PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc = 0 and
                        vValorAuxAlimAtual = 0 then
                        
                        PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := vValorAuxAlimRetro;
                        
                        PKGPAG_VAR.vNuDiasAuxAlimNaoDesc := vNuDiasAfastRetro;
                        
                        PKGPAG_VAR.vDescAuxAlimNaoDesc := vDescritivoRetro;
                        
                     end if;
                     
                  END IF;
               END IF;
               
            END IF;
            
         END LOOP;
         
         vNuDiasMesTodosVinc := 0;
         
         -- Se não gerou a rubrica 09-9157 na folha anterior, deve setar o valor afast retro na base saldo não descontado
         IF nvl(PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc, 0) = 0 THEN
            PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc +
                                                     vValorAuxAlimRetro;
         END IF;
         
         -- Gera a 08-0157, se possível
         PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := 0; --??
         
         vCdRubrica080157 := pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                          8,
                                                          157);
         -- Nao gerar se tem lancamento financeiro
         --
         if pkgpag_geral.fpossuilancfinanceiro(pcdvinculo,
                                               pFolha,
                                               vCdRubrica080157) then
            
            PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
            
         end if;
         
         IF PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc > 0 THEN
            
            PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc;
            
            if PKGPAG_VAR.vgRubrica(vCdRubrica080157).lsRubImpeditiva.count > 0 and
                pkgpag_cal.FTrataImpeditivas(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdRubricaAgrupamento => vCdRubrica080157,
                                             pFlTotalizadora       => 'N') then
               
               PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
               
            else
               
               vValorRubrica010157 := PKGPAG_GERAL.fretornavalorrubricarv(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                          pCdVinculo            => pCdVinculo,
                                                                          pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                                1,
                                                                                                                                157),
                                                                          pcdrelacaovinculo     => 1);
               
               vValorRubrica080157 := 0;
               
               -- se exitsir valor na 01-0157 o valor de desconto é limitado a ele.
               -- senão, descontará integral.
               IF vValorRubrica010157.vlProporcional > 0 AND
                  PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc >=
                  vValorRubrica010157.vlProporcional THEN
                  
                  PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc -
                                                       vValorRubrica010157.vlProporcional;
                  vValorRubrica080157               := vValorRubrica010157.vlProporcional;
                  PKGPAG_VAR.vNuDiasAuxAlimNaoDesc  := vValorRubrica010157.vlIndice;
                  
               ELSE
                  
                  vValorRubrica080157               := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc;
                  PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
               END IF;
               
               -- limita o desconto no valor total liquido
               /* IF vValorRubrica080157 > PKGPAG_VAR.vgVlBaseTotalLiquida
                                THEN
                                 PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := vValorRubrica080157 - PKGPAG_VAR.vgVlBaseTotalLiquida;
                                 vValorRubrica080157 := PKGPAG_VAR.vgVlBaseTotalLiquida;
                  
                              END IF;
               */
               
               IF vValorRubrica080157 > 0 THEN
                  
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pCdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                              8,
                                                                                                              157),
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => vValorRubrica080157,
                                                        pVlIndice             => PKGPAG_VAR.vNuDiasAuxAlimNaoDesc,
                                                        pDeExpressao          => PKGPAG_VAR.vDescAuxAlimNaoDesc,
                                                        pCdTipoOrigemRubrica  => 1);
                  
               END IF;
               
               -- subtrai da base saldo não descontado o valor do desconto 08-0157 desta folha
               PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc -
                                                        vValorRubrica080157;
               
               IF PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc > 0 THEN
                  
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pCdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseAlimRetroNaoDesc,
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc,
                                                        pVlIndice             => NULL,
                                                        pCdTipoOrigemRubrica  => 1);
                  
                  PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                          pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                          pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                          pDeLog                   => 'Saldo devedor de auxílio alimentação gerado',
                                          pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                          pCdTipoOcorrencia        => 2, -- Ocorrencia
                                          pCdMotivoOcorrencia      => 14);
               END IF;
               
            END IF;
            
         END IF;
         ------
      END IF;
      
   EXCEPTION
      WHEN OTHERS THEN
         
         PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim Não gerado', '');
         
   END;
   
   procedure PGeraDescontoFaltasMesAnt IS
      
      vVlAuxAlimAtual NUMBER(13, 2) := 0;
      
   begin
      
      vVlAuxAlimAtual := PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).VlAuxilioCEF;
      
      vVlAuxAlimAtual := vVlAuxAlimAtual *
                         PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis;
      
      if nvl(vVlAuxAlimAtual, 0) > 0 then
         
         PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                               pCdVinculo            => PKGPAG_VAR.vgVinculo.CdVinculo,
                                               pCdExpressaoFormCalc  => NULL,
                                               pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                     9,
                                                                                                     9157),
                                               pNuSufixoRubrica      => 1,
                                               pVlPagamento          => vVlAuxAlimAtual,
                                               pVlIndice             => PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis,
                                               pCdTipoOrigemRubrica  => 1);
         
      end if;
      
   exception
      when others then
         
         null;
         
   end;
   
   FUNCTION FCalculaValorIntegralCCO(pNuVales NUMBER, pVlAuxilio NUMBER)
      RETURN NUMBER IS
      
      vvlIntegralCCO    NUMBER(13, 2);
      vvlFixoAuxilioCCO NUMBER(13, 2);
      vvlNuDiasOrgao    INTEGER := PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias;
      REMTEST           NUMBER;
      
   BEGIN
      
      vvlFixoAuxilioCCO := FObterValorFixoAuxilioAli(PKGPAG_VAR.vgFolha.nuanoreferencia,
                                                     PKGPAG_VAR.vgFolha.nuanoreferencia,
                                                     vCdOrgaoAuxilio, ----PKGPAG_VAR.vgFolha.cdorgao,
                                                     2);
      
      SELECT REMAINDER(vvlNuDiasOrgao, pNuVales) INTO REMTEST FROM DUAL;
      
      IF REMTEST = 0 AND vvlFixoAuxilioCCO > 0 THEN
         vvlIntegralCCO := vvlFixoAuxilioCCO * pNuVales / vvlNuDiasOrgao;
      ELSE
         vvlIntegralCCO := vNuVales * vvlAuxilio;
      END IF;
      
      IF vvlFixoAuxilioCCO > 0 THEN
         vvlIntegralCCO := least(vvlIntegralCCO, vvlFixoAuxilioCCO);
      END IF;
      
      vDescritivo := vDescritivo || '*' || vvlAuxilio || 'unit->' ||
                     vvlIntegralCCO;
      
      RETURN vvlIntegralCCO;
      
   END;
   
   PROCEDURE PGeraAuxilioCCO(pCCO IN PKGPAG_TIPO.tCCO) IS
      
      vValorAuxAlimAtual        NUMBER(13, 2);
      vNuValesAuxAlimAtual      NUMBER;
      vValorAuxAlimRetro        NUMBER(13, 2);
      vNuValesAuxAlimRetro      NUMBER;
      vNuDiasAfastRetroAnulado  NUMBER;
      vValorAuxAlimRetroAnulado NUMBER(13, 2);
      vVlPagoAuxAliCEF          NUMBER(13, 2);
      vNuDiasTotalOutroVinc     INTEGER := 0;
      vAfastVinc                tAfast;
      vRetorno                  NUMBER := 0;
      vNuValesTotal             NUMBER := 0;
      vTratarDPE                boolean := false;
      vIndiceProporcao          NUMBER := 1;
      vVlAuxilioAliCHOAcum      NUMBER := 0;
      vAfastadoUltDiaMes        CHAR(1);
      vFlAfastadoMesTodo        CHAR(1);
      vCdRubrica080157          INTEGER;
      vValorRubrica080157       number(13, 2);
      vValorRubrica010157       pkgpag_tipo.rValorPagamento;
      
   BEGIN
      
      IF pCCO.COUNT > 0 AND (MONTHS_BETWEEN(pFolha.DtFimMes,
                                            PKGPAG_VAR.vgVinculo.DtNascimento) < 900 OR
         pCEF.COUNT = 0) THEN
         
         FOR i IN pCCO.FIRST .. pCCO.LAST LOOP
            
            IF PKGPAG_GERAL.FPossuiAbrangenciaRubrica(pRubrica                  => pRubrica,
                                                      pCdOrgao                  => PKGPAG_VAR.vgCdOrgaoVinculo,
                                                      pCdOrgaoExercicio         => pCCO(i).CdOrgaoExercicio,
                                                      pCdNaturezaVinculo        => pCCO(i).CdNaturezaVinculo,
                                                      pCdRelacaoTrabalho        => pCCO(i).CdRelacaoTrabalho,
                                                      pCdRegimeTrabalho         => pCCO(i).CdRegimeTrabalho,
                                                      pCdRegimePrevidenciario   => pCCO(i).CdRegimePrevidenciario,
                                                      pCdSituacaoPrevidenciaria => pCCO(i).CdSituacaoPrevidenciaria,
                                                      pCdCargoComissionado      => pCCO(i).CdCargoComissionado,
                                                      pCdGrupoOcupacional       => pCCO(i).CdGrupoOcupacional,
                                                      pCdUnidadeOrganizacional  => pCCO(i).CdUnidadeOrganizacional,
                                                      pFlTipoProvimento         => pCCO(i).FlTipoProvimento,
                                                      pCdOpcaoRemuneracao       => pCCO(i).CdOpcaoRemuneracao) OR
               PKGPAG_VAR.vgVinculo.CdOpcaoAuxilioAli = 2 THEN
               
               IF pCCO(i).DtFimRelacao IS NOT NULL THEN
                  vNuDiasMes := pCCO(i).DtFimRelacao - pFolha.DtInicioMes + 1;
               ELSE
                  vNuDiasMes := pFolha.DtFimMes - pCCO(i).DtInicioRelacao + 1;
               END IF;
               
               IF FGeraAuxilioAlimentacao(pCdOrgao   => vCdOrgaoAuxilio,
                                          pCdVinculo => pCCO(i).CdVinculo,
                                          pCdSitPrev => pCCO(i).CdSituacaoPrevidenciaria,
                                          pCdRelTrab => pCCO(i).CdRelacaoTrabalho,
                                          pCdUnidOrg => pCCO(i).CdUnidadeOrganizacional,
                                          pCdOpcao   => pCCO(i).CdOpcaoRemuneracao) THEN
                  
                  IF pCCO(i).DtInicioRelacao BETWEEN pFolha.DtInicioMes AND
                      pFolha.DtFimMes THEN
                     
                     vDtInicio := pCCO(i).dtInicio;
                     
                  ELSE
                     
                     vDtInicio := PKGPAG_VAR.vDtCalculoAnt + 1;
                     
                  END IF;
                  
                  vDtFim := PKGPAG_VAR.vDtCalculo;
                  
                  PKGAFA.PCalcularDiasEvento(pCdVinculo               => pCCO(i).CdVinculo,
                                             pCdEstruturaCarreira     => CASE
                                                                            WHEN pCEF.EXISTS(1) THEN
                                                                             pCEF(1).CdEstruturaCarreira
                                                                            ELSE
                                                                             NULL
                                                                         END,
                                             pDtInicio                => vDtInicio,
                                             pDtFim                   => vDtFim,
                                             pCdEventoAfastamento     => 11,
                                             pFlVerificaPeriodoPA     => 'S',
                                             pCdAgrupamento           => pFolha.CdAgrupamento,
                                             pCdOrgao                 => pFolha.CdOrgao,
                                             pCdUnidadeOrganizacional => pCCO(i).CdUnidadeOrganizacional,
                                             pNuTipoDiaNaoUtil        => case
                                                                            when PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias is not null then
                                                                             7 -- Para DPE, considerar dias nao uteis apenas sábados e domingos
                                                                            else
                                                                             PKGPAG_VAR.vgNuTipoDiaNaoUtil
                                                                         end,
                                             pFlConsideraDataInclusao => PKGPAG_TIPO.cnS,
                                             pDtFimRelacao            => pCCO(i).DtFim,
                                             pDtIniLimite             => ADD_MONTHS(pFolha.DtInicioMes,
                                                                                    -1 *
                                                                                    PKGMOVFRE.cn_Qt_Mes_Retro_Falta),
                                             pListaAfastDecJudAlim    => PKGPAG_VAR.vgListaAfastDecJudAlim,
                                             pFlCalculoGeral          => PKGPAG_VAR.vgCalculo.flgeral);
                  
                  vNuDiasAfastAtual        := PKGAFA.FQtDiasAtual;
                  vNuDiasAfastRetro        := PKGAFA.FQtDiasRetroativo;
                  vNuDiasAfastRetroAnulado := PKGAFA.FQtDiasRetroAnulado +
                                              PKGPAG_VAR.vgIndiceAbonoRetroDiasUteis;
                  
                  vNuDiasUteis := FRetornaDiasUteis(pCCO(i).CdUnidadeOrganizacional,
                                                    pCCO(i).DtInicio,
                                                    CASE
                                                       WHEN TO_CHAR(pCCO(i).DtFim, 'DD') = 30 AND
                                                            NVL(pCCO(i).DtFimRelacao, pFolha.DtFimMes) >=
                                                            pFolha.DtFimMes THEN
                                                        pFolha.DtFimMes
                                                       ELSE
                                                        pCCO(i).DtFim
                                                    END,
                                                    PKGPAG_VAR.vgNuTipoDiaNaoUtil);
                  
                  begin
                     
                     vAfastVinc := fCalculaDiasAfastamentoRetro(pCco  (i).CdVinculo,
                                                                pFolha,
                                                                pCCO  (i).CdUnidadeOrganizacional,
                                                                null,
                                                                pcco  (i).nucargahoraria,
                                                                pcco  (i).nucargahoraria,
                                                                pCco  (i).DtInicio,
                                                                pCco  (i).DtFim,
                                                                vCdRubAgrup_01_0157);
                     
                  exception
                     when others then
                        vAfastVinc.nudiasafastretroanulado := 0;
                        vAfastVinc.nudiasafastretro        := 0;
                        vAfastVinc.nudiasafastmes          := 0;
                        vAfastVinc.nudiassemrelacao        := 0;
                  end;
                  
                  begin
                     
                     vRetorno := fCalculaDiasAfastamentoMes(pCco                       (i).CdVinculo,
                                                            pFolha,
                                                            pCCO                       (i).CdUnidadeOrganizacional,
                                                            null,
                                                            pcco                       (i).nucargahoraria,
                                                            pcco                       (i).nucargahoraria,
                                                            pCco                       (i).DtInicio,
                                                            pCco                       (i).DtFim,
                                                            vAfastVinc.nudiassemrelacao,
                                                            vAfastVinc.nudiasafastmes,
                                                            vNuVales,
                                                            vFlAfastadoMesTodo);
                     
                  exception
                     when others then
                        vRetorno := 0;
                  end;
                  
                  -- Tratamento para afastamentos em meses de 31 dias
                  IF vAfastVinc.nudiasafastmes > 0 AND
                     vFlAfastadoMesTodo = 'N' AND
                     PKGPAG_GERAL.FRetornaDiasDoMes(pFolha.DtFimMes, 'N') = 31 THEN
                     
                     vAfastadoUltDiaMes := 'N';
                     
                     IF PKGPAG_VAR.vgAfastTempRemun.FIRST > 0 THEN
                        
                        FOR cAfastRemun in PKGPAG_VAR.vgAfastTempRemun.FIRST .. PKGPAG_VAR.vgAfastTempRemun.LAST LOOP
                           
                           IF PKGPAG_VAR.vgAfastTempRemun(cAfastRemun).FlUltimoDiaMes = 'S' THEN
                              
                              vAfastadoUltDiaMes := 'S';
                              EXIT;
                              
                           END IF;
                           
                        END LOOP;
                        
                     END IF;
                     
                     IF vAfastadoUltDiaMes = 'N' THEN
                        
                        IF PKGPAG_VAR.vgAfastTempNaoRemun.FIRST > 0 THEN
                           
                           FOR cAfastNaoRemun in PKGPAG_VAR.vgAfastTempNaoRemun.FIRST .. PKGPAG_VAR.vgAfastTempNaoRemun.LAST LOOP
                              
                              IF PKGPAG_VAR.vgAfastTempNaoRemun(cAfastNaoRemun).FlUltimoDiaMes = 'S' THEN
                                 
                                 vAfastadoUltDiaMes := 'S';
                                 EXIT;
                                 
                              END IF;
                              
                           END LOOP;
                           
                        END IF;
                        
                     END IF;
                     
                     IF vAfastadoUltDiaMes = 'S' THEN
                        
                        vAfastVinc.nudiasafastmes := vAfastVinc.nudiasafastmes - 1;
                        
                     END IF;
                     
                  END IF;
                  
                  vNuVales := vNuDiasUteis - vNuDiasAfastAtual -
                              PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis;
                  
                  IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias IS NULL THEN
                     
                     IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite IS NOT NULL THEN
                        
                        vNuVales := LEAST(vNuVales,
                                          PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite);
                        
                     END IF;
                     
                     PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim',
                                            'CCO ' || i ||
                                            ' - Dias AfastAtual/AfastRetro/noMes/Uteis/Faltas/AfastRetroAnul :' ||
                                            vNuDiasAfastAtual || '/' ||
                                            vNuDiasAfastRetro || '/' ||
                                            vNuDiasMes || '/' ||
                                            vNuDiasUteis || '/' ||
                                            PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis || '/' ||
                                            vNuDiasAfastRetroAnulado);
                     
                     vDescritivo := vDescritivo || '(' || vNuVales || '-' ||
                                    vNuDiasAfastAtual || 'Afa-' ||
                                    PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis ||
                                    'Falt';
                     
                     IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 1 THEN
                        -- ABATE DO CREDITO
                        
                        vNuVales := vNuVales - vNuDiasAfastRetro +
                                    vNuDiasAfastRetroAnulado;
                        
                        vDescritivo := vDescritivo || '-' ||
                                       vNuDiasAfastRetro || 'AfaRetro+' ||
                                       vNuDiasAfastRetroAnulado ||
                                       'AfaRetroAnul';
                        
                     END IF;
                     
                     vDescritivo := vDescritivo || ')->' || vNuVales;
                     
                     vNuVales := CASE
                                    WHEN (vNuVales < 0) THEN
                                     0
                                    ELSE
                                     vNuVales
                                 END;
                  ELSE
                     
                     /*********************************************************************
                     **  DEFENSORIA PUBLICA POSSUI VALOR FIXO DE VALE EQUIVALENTE A 22 DIAS
                     *********************************************************************/
                     vTratarDPE := true;
                     
                  END IF;
                  
                  /***********************************************************************/
                  
                  IF pCCO.count > 1 THEN
                     -- Caso haja outro vínculo, salva o número de dias nesta variável.
                     IF vNuDiasTotalOutroVinc + vNuVales >
                        NVL(PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias,
                            vNuDiasMes) THEN
                        
                        vNuVales              := PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias -
                                                  vNuDiasTotalOutroVinc;
                        vNuDiasTotalOutroVinc := PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias;
                        
                     ELSE
                        
                        vNuDiasTotalOutroVinc := vNuDiasTotalOutroVinc +
                                                 vNuVales;
                        
                     END IF;
                     
                  END IF;
                  
                  IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdBaseCalculo IS NOT NULL THEN
                     
                     PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                           pCdVinculo            => pCCO(i).CdVinculo,
                                                           pCdRelacaoVinculo     => 2,
                                                           pCdHistRelacaoVinculo => pCCO(i).CdHistCargoCom,
                                                           pCdExpressaoFormCalc  => NULL,
                                                           pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                           pVlIntegral           => NULL,
                                                           pVlProporcional       => NULL,
                                                           pNuSufixoRubrica      => 1,
                                                           pNuParcelas           => NULL,
                                                           pVlIndice             => vNuVales,
                                                           pCdRubTotVantagem     => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdRubricaAgrupamento,
                                                           pCdTipoOrigemRubrica  => 1,
                                                           pDtInicio             => pCCO(i).DtInicio,
                                                           pDtFim                => pCCO(i).DtFim,
                                                           pDescritivo           => vDescritivo);
                     
                  ELSE
                     
                     vvlAuxilio := FRetornaValorAuxilioCCO(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdValorAuxilio,
                                                           pCdGrupoOcupacional  => pCCO(i).CdGrupoOcupacional,
                                                           pCdCargoComissionado => pCCO(i).CdCargoComissionado,
                                                           pNuCargaHoraria      => pCCO(i).NuCargaHorariaPadrao,
                                                           pNuCodigo            => pCCO(i).NuNivel,
                                                           pNuReferencia        => pCCO(i).NuReferencia,
                                                           pVlAuxilio           => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).VlAuxilioCCO);
                     
                     --Salva o valor maximo permitido pago num mes
                     IF pCCO.count > 1 THEN
                        
                        vValorLimite := vvlAuxilio *
                                        vNuDiasTotalOutroVinc;
                        
                     ELSE
                        
                        vValorLimite := vvlAuxilio *
                                        LEAST(vNuDiasUteis,
                                              PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDiasLimite);
                        
                     END IF;
                     
                     if vTratarDPE then
                        
                        vCdRelacaoVinculo := 2;
                        
                        /*********************************************************************
                        **  DEFENSORIA PUBLICA POSSUI VALOR FIXO DE VALE EQUIVALENTE A 22 DIAS
                        *********************************************************************/
                        
                        /* somatório de dias mês das relações não pode ser superior a 30 */
                        IF vNuDiasMes > 30 OR
                           vNuDiasMes = TO_CHAR(pFolha.DtFimMes, 'DD') THEN
                           
                           vNuDiasMes := 30;
                           
                        END IF;
                        
                        IF pFolha.CdAgrupamento IN (1, 134) THEN
                           
                           vNuDiasMesTodosVinc := vNuDiasMesTodosVinc +
                                                  vNuDiasMes;
                           
                           IF vNuDiasMesTodosVinc > 30 THEN
                              
                              vNuDiasMes := vNuDiasMes -
                                            (LEAST(vNuDiasMesTodosVinc,
                                                   60) - 30);
                              
                           END IF;
                           
                        END IF;
                        
                        PAjusteNuDiasFixo(pCdAgrupamento           => pFolha.CdAgrupamento,
                                          pCdOrgao                 => vCdOrgaoAuxilio, ---pFolha.CdOrgao,
                                          pCdUnidadeOrganizacional => pCCO(i).CdUnidadeOrganizacional,
                                          pCdRelacaoVinculo        => vCdRelacaoVinculo,
                                          pDtInicioRelacao         => pCCO(i).DtInicioRelacao,
                                          pDtFimRelacao            => pCCO(i).DtFimRelacao,
                                          pDtInicioMesFolha        => pFolha.DtInicioMes,
                                          pDtFimMesFolha           => pFolha.DtFimMes,
                                          pNuDiasAfastamentoMes    => vAfastVinc.nudiasafastmes,
                                          pCdVinculo               => pCdVinculo,
                                          pDtIniCHO                => NULL,
                                          pDtFinalCHO              => NULL,
                                          pIndiceProporcao         => 1,
                                          pVlAuxilioAliCHOAcum     => vVlAuxilioAliCHOAcum);
                        
                        vvlIntegral := vValorLimite;
                     else
                        vvlIntegral := FCalculaValorIntegralCCO(vNuVales,
                                                                vvlAuxilio);
                     end if;
                     
                     vValorAuxAlimAtual   := vvlIntegral;
                     vNuValesAuxAlimAtual := vNuVales;
                     
                     vDescritivo := vDescritivo || ' ->Prop ' ||
                                    vIndiceProporcao || '->R$ ' ||
                                    vValorAuxAlimAtual;
                     
                     IF vValorAuxAlimAtual > 0 THEN
                        
                        vValorAuxAlimAtual := FTrataValoresRecebidos(pValorCalculado => vValorAuxAlimAtual);
                        
                        -- Solicitacao de Sustentacao #77386
                        -- SEA - FOLHA - 10729/2017 - Indice dos dias do Aux. Alimentacao
                        vNuValesAuxAlimAtual := ROUND(vValorAuxAlimAtual /
                                                      vVlAuxilio,
                                                      1);
                        
                     END IF;
                     
                     ------------------------------------------------------------------------------
                     -- Retorna o valor do saldo devedor (somando o saldo que ficou do efetivo)
                     ------------------------------------------------------------------------------
                     
                     PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                                                                            pCdVinculo        => pCdVinculo,
                                                                                            pCdRubrica        => PKGPAG_VAR.vgCdRubBaseAlimRetroNaoDesc);
                     
                     PKGPAG_GERAL.PLogTrace('EVVINC - Aux Alim',
                                            'CCO ' || i ||
                                            ' - NuVales/ValorVales/SaldoDevedor :' ||
                                            vNuValesAuxAlimAtual || '/' ||
                                            vValorAuxAlimAtual || '/' ||
                                            PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc);
                     
                     -- Valores retroativos de auxilio alimentacao
                     
                     vvlAuxilio := NULL;
                     
                     IF vNuDiasAfastRetro > 0 AND PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 2 THEN
                        
                        begin
                           
                           vvlAuxilio := FRetornaValorAuxilioCCO(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                 pCdGrupoOcupacional  => pCCO(i).CdGrupoOcupacional,
                                                                 pCdCargoComissionado => pCCO(i).CdCargoComissionado,
                                                                 pNuCargaHoraria      => pCCO(i).NuCargaHorariaPadrao,
                                                                 pNuCodigo            => pCCO(i).NuNivel,
                                                                 pNuReferencia        => pCCO(i).NuReferencia,
                                                                 pVlAuxilio           => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).VlAuxilioCCO);
                           
                        exception
                           
                           when others then
                              
                              vvlAuxilio := FRetornaValorAuxilioCCO(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                    pCdGrupoOcupacional  => pCCO(i).CdGrupoOcupacional,
                                                                    pCdCargoComissionado => pCCO(i).CdCargoComissionado,
                                                                    pNuCargaHoraria      => pCCO(i).NuCargaHorariaPadrao,
                                                                    pNuCodigo            => pCCO(i).NuNivel,
                                                                    pNuReferencia        => pCCO(i).NuReferencia,
                                                                    pVlAuxilio           => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).VlAuxilioCCO);
                              
                        end;
                        
                        vValorAuxAlimRetro := vAfastVinc.vltotaldescauxaliretro;
                        
                     ELSE
                        
                        vValorAuxAlimRetro := 0;
                        
                        vNuValesAuxAlimRetro := 0;
                        
                     END IF;
                     
                     vValorAuxAlimRetro := vValorAuxAlimRetro +
                                           PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc;
                     
                     vDescritivoRetro := 'RETRO(' || 'unit*' ||
                                         vNuDiasAfastRetro ||
                                         'AfaRetro+' ||
                                         PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc ||
                                         'Saldo->' || vValorAuxAlimRetro || ')';
                     
                     PKGPAG_VAR.vNuDiasAuxAlimNaoDesc := vNuDiasAfastRetro;
                     
                     PKGPAG_VAR.vDescAuxAlimNaoDesc := vDescritivoRetro;
                     
                     IF vValorAuxAlimRetro > 0 AND PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 2 AND
                        (NOT vGerouRubrica080157) THEN
                        
                        PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := vValorAuxAlimRetro;
                        
                        PKGPAG_VAR.vNuDiasAuxAlimNaoDesc := vNuDiasAfastRetro;
                        
                        PKGPAG_VAR.vDescAuxAlimNaoDesc := vDescritivoRetro;
                        
                     ELSE
                        
                        PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
                        
                     END IF;
                     
                     IF vNuDiasAfastRetroAnulado > 0 AND PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdOperacaoAbatimento = 2 THEN
                        
                        IF vvlAuxilio IS NULL THEN
                           
                           begin
                              
                              vvlAuxilio := FRetornaValorAuxilioCCO(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                    pCdGrupoOcupacional  => pCCO(i).CdGrupoOcupacional,
                                                                    pCdCargoComissionado => pCCO(i).CdCargoComissionado,
                                                                    pNuCargaHoraria      => pCCO(i).NuCargaHorariaPadrao,
                                                                    pNuCodigo            => pCCO(i).NuNivel,
                                                                    pNuReferencia        => pCCO(i).NuReferencia,
                                                                    pVlAuxilio           => PKGPAG_VAR.vgAuxilioAliAnt(vCdOrgaoAuxilio).VlAuxilioCCO);
                              
                           exception
                              when others then
                                 
                                 vvlAuxilio := FRetornaValorAuxilioCCO(pCdValorAuxilio      => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).CdValorAuxilio,
                                                                       pCdGrupoOcupacional  => pCCO(i).CdGrupoOcupacional,
                                                                       pCdCargoComissionado => pCCO(i).CdCargoComissionado,
                                                                       pNuCargaHoraria      => pCCO(i).NuCargaHorariaPadrao,
                                                                       pNuCodigo            => pCCO(i).NuNivel,
                                                                       pNuReferencia        => pCCO(i).NuReferencia,
                                                                       pVlAuxilio           => PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).VlAuxilioCCO);
                                 
                           end;
                           
                        END IF;
                        
                        vValorAuxAlimRetroAnulado := vvlAuxilio *
                                                     vNuDiasAfastRetroAnulado;
                        
                        IF PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc >=
                           vValorAuxAlimRetroAnulado THEN
                           
                           PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc -
                                                                vValorAuxAlimRetroAnulado;
                           
                           vNuDiasAfastRetroAnulado := 0;
                           
                        ELSE
                           
                           vValorAuxAlimRetroAnulado := vValorAuxAlimRetroAnulado -
                                                        PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc;
                           
                           PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
                           
                        END IF;
                        
                        vCdRubrica020157 := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,
                                                                         2,
                                                                         157);
                        
                        IF vNuDiasAfastRetroAnulado > 0 AND
                           PKGPAG_GERAL.FGeraRubrica(vCdRubrica020157) AND
                           NOT NVL(bPagouAuxilioDecJud, FALSE) THEN
                           
                           PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                 pCdVinculo            => pCdVinculo,
                                                                 pCdRelacaoVinculo     => 2,
                                                                 pCdHistRelacaoVinculo => pCCO(i).CdHistCargoCom,
                                                                 pCdExpressaoFormCalc  => NULL,
                                                                 pCdRubricaAgrupamento => vCdRubrica020157,
                                                                 pVlIntegral           => vValorAuxAlimRetroAnulado,
                                                                 pVlProporcional       => vValorAuxAlimRetroAnulado,
                                                                 pNuSufixoRubrica      => 1,
                                                                 pNuParcelas           => NULL,
                                                                 pVlIndice             => vNuDiasAfastRetroAnulado,
                                                                 pCdTipoOrigemRubrica  => 1,
                                                                 pDtInicio             => pCCO(i).DtInicio,
                                                                 pDtFim                => pCCO(i).DtFim);
                        END IF;
                        
                     END IF;
                     
                     IF vNuValesAuxAlimAtual < vNuDiasUteis THEN
                        --IF (pkgpag_alimentacao.FUnidadeOrganizacionalDPE(pCCO(i).CdUnidadeOrganizacional)) THEN
                        --   vValorLimite := FObterValorFixoAuxilioAli(PKGPAG_VAR.vgFolha.nuanoreferencia, PKGPAG_VAR.vgFolha.nuanoreferencia, PKGPAG_VAR.vgFolha.cdorgao, 2);
                        --ELSE
                        vValorLimite := vValorLimite *
                                        vNuValesAuxAlimAtual /
                                        vNuDiasUteis;
                        --END IF;
                     END IF;
                     
                     IF pCEF.COUNT > 0 AND vValorLimite > 0 THEN
                        vVlPagoAuxAliCEF := FObtemAuxilioPagoRelVinc(pCdVinculo,
                                                                     pFolha);
                        IF vVlPagoAuxAliCEF >= vValorLimite THEN
                           RETURN;
                           
                        ELSE
                           IF vVlPagoAuxAliCEF + vValorAuxAlimAtual >
                              vValorLimite THEN
                              vValorAuxAlimAtual := vValorLimite -
                                                    vValorAuxAlimAtual;
                           END IF;
                        END IF;
                     END IF;
                     
                     IF PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc = 0 AND
                        vValorAuxAlimAtual < 0 THEN
                        
                        PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := abs(vValorAuxAlimAtual);
                        
                        PKGPAG_VAR.vNuDiasAuxAlimNaoDesc := abs(vNuValesAuxAlimAtual);
                        
                     END IF;
                     
                     IF vValorAuxAlimAtual > 0 THEN
                        
                        PKGPAG_GERAL.PInsereLancamentoRelacao(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                              pCdVinculo            => pCdVinculo,
                                                              pCdRelacaoVinculo     => 2,
                                                              pCdHistRelacaoVinculo => pCCO(i).CdHistCargoCom,
                                                              pCdExpressaoFormCalc  => NULL,
                                                              pCdRubricaAgrupamento => pRubrica.CdRubricaAgrupamento,
                                                              pVlIntegral           => vValorAuxAlimAtual,
                                                              pVlProporcional       => vValorAuxAlimAtual,
                                                              pNuSufixoRubrica      => 1,
                                                              pNuParcelas           => NULL,
                                                              pVlIndice             => vNuValesAuxAlimAtual,
                                                              pCdTipoOrigemRubrica  => 1,
                                                              pDtInicio             => pCCO(i).DtInicio,
                                                              pDtFim                => pCCO(i).DtFim,
                                                              pDescritivo           => vDescritivo);
                        
                        vNuValesTotal := vNuValesTotal +
                                         vNuValesAuxAlimAtual;
                     END IF;
                     
                  END IF;
                  
               END IF;
               
            END IF;
            
         END LOOP;
         
         vNuDiasMesTodosVinc := 0;
         
         -- Gera a 08-0157, se possível
         PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := 0; --??
         
         vCdRubrica080157 := pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                          8,
                                                          157);
         -- Nao gerar se tem lancamento financeiro
         --
         if pkgpag_geral.fpossuilancfinanceiro(pcdvinculo,
                                               pFolha,
                                               vCdRubrica080157) then
            
            PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
            
         end if;
         
         IF PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc > 0 THEN
            
            PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc;
            
            if PKGPAG_VAR.vgRubrica(vCdRubrica080157).lsRubImpeditiva.count > 0 and
                pkgpag_cal.FTrataImpeditivas(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                             pCdVinculo            => pCdVinculo,
                                             pCdRubricaAgrupamento => vCdRubrica080157,
                                             pFlTotalizadora       => 'N') then
               
               PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
               
            else
               
               vValorRubrica010157 := PKGPAG_GERAL.fretornavalorrubricarv(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                                          pCdVinculo            => pCdVinculo,
                                                                          pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(pFolha.CdAgrupamento,
                                                                                                                                1,
                                                                                                                                157),
                                                                          pcdrelacaovinculo     => 1);
               
               vValorRubrica080157 := 0;
               
               -- se exitsir valor na 01-0157 o valor de desconto é limitado a ele.
               -- senão, descontará integral.
               IF vValorRubrica010157.vlProporcional > 0 AND
                  PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc >=
                  vValorRubrica010157.vlProporcional THEN
                  
                  PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc -
                                                       vValorRubrica010157.vlProporcional;
                  vValorRubrica080157               := vValorRubrica010157.vlProporcional;
                  PKGPAG_VAR.vNuDiasAuxAlimNaoDesc  := vValorRubrica010157.vlIndice;
                  
               ELSE
                  
                  vValorRubrica080157               := PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc;
                  PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := 0;
               END IF;
               
               -- limita o desconto no valor total liquido
               /* IF vValorRubrica080157 > PKGPAG_VAR.vgVlBaseTotalLiquida
                                THEN
                                 PKGPAG_VAR.vvlSaldoAuxAlimNaoDesc := vValorRubrica080157 - PKGPAG_VAR.vgVlBaseTotalLiquida;
                                 vValorRubrica080157 := PKGPAG_VAR.vgVlBaseTotalLiquida;
                  
                              END IF;
               */
               
               IF vValorRubrica080157 > 0 THEN
                  
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pCdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => pkgpag_geral.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                              8,
                                                                                                              157),
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => vValorRubrica080157,
                                                        pVlIndice             => PKGPAG_VAR.vNuDiasAuxAlimNaoDesc,
                                                        pDeExpressao          => PKGPAG_VAR.vDescAuxAlimNaoDesc,
                                                        pCdTipoOrigemRubrica  => 1);
                  
               END IF;
               
               -- subtrai da base saldo não descontado o valor do desconto 08-0157 desta folha
               PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc := PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc -
                                                        vValorRubrica080157;
               
               IF PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc > 0 THEN
                  
                  PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                        pCdVinculo            => pCdVinculo,
                                                        pCdExpressaoFormCalc  => NULL,
                                                        pCdRubricaAgrupamento => PKGPAG_VAR.vgCdRubBaseAlimRetroNaoDesc,
                                                        pNuSufixoRubrica      => 1,
                                                        pVlPagamento          => PKGPAG_VAR.vvlBaseSaldoAuxAlimNaoDesc,
                                                        pVlIndice             => NULL,
                                                        pCdTipoOrigemRubrica  => 1);
                  
                  PKGPAG_GERAL.PInsereLog(pInsere                  => PKGPAG_VAR.bLog,
                                          pCdHistoricoParamCalculo => PKGPAG_VAR.vCdHistParamCalc,
                                          pCdPessoa                => PKGPAG_VAR.vCdPessoa,
                                          pDeLog                   => 'Saldo devedor de auxílio alimentação gerado',
                                          pCdVinculo               => PKGPAG_VAR.vgVinculo.CdVinculo,
                                          pCdTipoOcorrencia        => 2, -- Ocorrencia
                                          pCdMotivoOcorrencia      => 14);
               END IF;
               
            END IF;
            
         END IF;
         
      END IF;
      
   END;
   
BEGIN
   
   vCdRubAgrup_01_0157 := PKGPAG_GERAL.FRetornaRubrica(pFolha.CdAgrupamento,1, 157);
   vCdRubrica_01_0157  := PKGPAG_GERAL.FRetornaCdRubrica(1, 157);
 
   PKGPAG_GERAL.PArmazenaCHO;
   
   vCdRubrica020157    := NULL;
   vCdRubrica080157    := NULL;
   vValorFaltasNaoDesc := 0;
   vNuFaltasNaoDesc    := 0;
   PObtemAuxilioPago;
   
   vValorLimite := 0;
   
   IF PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao >=
      PKGPAG_VAR.vgRelVincPrincipal.NuCHO THEN
      
      vNuCHOAPagar := 40;
      
   ELSE
      
      vNuCHOAPagar := PKGPAG_VAR.vgRelVincPrincipal.NuCHORelacao;
      
   END IF;
   
   vCdOrgaoAuxilio := CASE PKGPAG_VAR.vgVinculo.CdOpcaoAuxilioAli
                         WHEN 1 THEN
                          PKGPAG_VAR.vgVinculo.CdOrgao
                         ELSE
                          pFolha.CdOrgao
                      END;
   
   vDescritivo      := '';
   vDescritivoRetro := '';
   
   IF PKGPAG_VAR.vgAuxilioAli(vCdOrgaoAuxilio).NuDias IS NULL THEN
      
      vUtilizaNumeroFixoVA := FALSE;
      
   ELSE
      
      vUtilizaNumeroFixoVA := TRUE;
      
   END IF;
   
   PGeraAuxilioCEF(pCEF);
   
   vDescritivo      := '';
   vDescritivoRetro := '';
   
   PGeraAuxilioCCO(pCCO);
   
   vDescritivo      := '';
   vDescritivoRetro := '';
   
   PGeraAuxilioCCO(pCCOSubst);
   
   if PKGPAG_VAR.vgIndiceFaltasSomenteDiasUteis > 0 and pCef.Count = 0 and
      PKGPAG_VAR.vgVinculo.DtDesligamento < pFolha.DtInicioMes then
      
      pGeraDescontoFaltasMesAnt;
      
   end if;
   
END;

end pkgpag_alimentacao;
/
