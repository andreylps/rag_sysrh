CREATE OR REPLACE PACKAGE pkgpag_fb IS

  TYPE rInfoRelVinc IS RECORD(
    cdChave          INTEGER,
    cdRelacaoVinculo INTEGER);

  FUNCTION fmneuqtmesestrabano(pfolha             IN pkgpag_tipo.rfolha,
                               pcdvinculo         IN INTEGER,
                               pdtiniciorelacao   IN DATE,
                               pdtfimrelacao      IN DATE,
                               pdtcalculo         IN DATE,
                               pflatemesatual     IN CHAR DEFAULT 'N',
                               pflanoadmissao     IN CHAR DEFAULT 'N',
                               pFlPeriodoFerias   IN CHAR DEFAULT 'N',
                               pFlValidaAuxDoenca IN CHAR DEFAULT 'N')
    RETURN INTEGER;

  FUNCTION fMneSomaOutrasFolhasMes(pcdvinculo            IN INTEGER,
                                   pcdrubricaagrupamento IN INTEGER,
                                   pfolha                in pkgpag_tipo.rFolha,
                                   pFlMesAnterior        in char default null)
    return number;

  FUNCTION fMneSomaRubMes(pcdvinculo            IN INTEGER,
                          pcdrubricaagrupamento IN INTEGER,
                          pfolha                in pkgpag_tipo.rFolha)
    return number;  

  FUNCTION fmnevlanooutrosvinculos(pcdpessoa        IN INTEGER,
                                   pcdvinculo       IN INTEGER,
                                   pcdrubrica       IN INTEGER,
                                   pnuanoreferencia IN INTEGER)

   RETURN NUMBER;

  FUNCTION fmneqtdiasproxmes(pfolha          IN pkgpag_tipo.rfolha,
                             pcdunidorg      IN INTEGER,
                             pdtinicio       IN DATE,
                             pdtfim          IN DATE,
                             pdtdesligamento IN DATE DEFAULT NULL)

   RETURN NUMBER;


  FUNCTION FMneVlRubTodosVinculos(pcdpessoa             IN INTEGER,
                                  pcdfolhapagamento     IN INTEGER,
                                  pcdrubricaagrupamento IN INTEGER,
                                  pnuanoreferencia      IN INTEGER)

  RETURN NUMBER;

  FUNCTION fretornavalorbasecalculo(pfolha            IN pkgpag_tipo.rfolha,
                                    pcdvinculo        IN INTEGER,
                                    pcdtipohistorico  IN INTEGER,
                                    pcdrelacaovinculo IN INTEGER,
                                    pcdbasecalculo    IN INTEGER,
                                    pcdchave          IN INTEGER,
                                    ptptributacao     IN INTEGER DEFAULT NULL,
                                    pCdFolhaAnt       IN INTEGER DEFAULT NULL)

   RETURN pkgpag_tipo.rvalorpagamento;

  FUNCTION fCalculaFormula(pcdvinculo            IN INTEGER,
                           pAnoMes               IN integer,
                           pcdrubricaagrupamento IN INTEGER,
                           pVlIndice             in integer default null,
                           pDeFormula            out char,
                           pFlCalculoDefinitivo  char default 'S')

   RETURN NUMBER;

  FUNCTION fmneref(pcdvalorreferencia IN INTEGER) RETURN NUMBER;

  FUNCTION fQtTipoDiasPeriodo(P_DATA_INICIAL     IN DATE,
                              P_DATA_FINAL       IN DATE,
                              p_dia_final_semama IN NUMBER DEFAULT 0,
                              p_tipo_retorno     IN NUMBER,
                              p_cdunid IN NUMBER DEFAULT NULL) RETURN NUMBER;

  FUNCTION fmnechomedio(pcdrelacaovinculo IN INTEGER,
                        pcdchave          IN INTEGER,
                        pdtinicio         IN DATE,
                        pdtfim            IN DATE) RETURN NUMBER;

  FUNCTION fmneqtdiasremimpedsuteisret(pfolha        IN pkgpag_tipo.rfolha,
                                       pcdvinculo    IN INTEGER,
                                       prubrica      IN pkgpag_tipo.rRubrica,
                                       pdtfimrelacao IN DATE,
                                       pdtcalculo    IN DATE)

  RETURN INTEGER;

  PROCEDURE pprocformulacalculo(pfolha        IN pkgpag_tipo.rfolha,
                                ppagcalc      IN pkgpag_tipo.rpagcalc,
                                pexprform     IN pkgpag_tipo.rformulacalculo,
                                ptptributacao IN INTEGER DEFAULT NULL,
                                pcdmnemonico  IN INTEGER DEFAULT NULL,
                                pRetornaValor IN CHAR DEFAULT NULL,
                                pCdFolhaAnt   IN INTEGER DEFAULT NULL);

  PROCEDURE pprocessaformulasbases(pfolha           IN pkgpag_tipo.rfolha,
                                   pcdvinculo       IN INTEGER,
                                   pcdrubrica       IN INTEGER,
                                   ptpprocessamento IN INTEGER DEFAULT 1,
                                   ptplocal         IN INTEGER DEFAULT 1,
                                   ptptributacao    IN INTEGER DEFAULT NULL,
                                   pindprocretro    IN INTEGER DEFAULT NULL,
                                   pcdmnemonico     IN INTEGER DEFAULT NULL,
                                   pNuSufixoRubrica IN INTEGER DEFAULT NULL);
 
  PROCEDURE pprocessaformulasbasesTotal (pfolha           IN pkgpag_tipo.rfolha,
                                         pcdvinculo       IN INTEGER,
                                         ptpprocessamento IN INTEGER DEFAULT 1,
                                         ptplocal         IN INTEGER DEFAULT 1,
                                         ptptributacao    IN INTEGER DEFAULT NULL,
                                         pindprocretro    IN INTEGER DEFAULT NULL,
                                         pcdmnemonico     IN INTEGER DEFAULT NULL,
                                         pNuSufixoRubrica IN INTEGER DEFAULT NULL);                                  
                                   

  FUNCTION FMneSomaRubMesOutrosVinculos(pcdpessoa             IN INTEGER,
                                        pcdrubricaagrupamento IN INTEGER,
                                        pfolha                in pkgpag_tipo.rFolha) return number;

  PROCEDURE patualizabasecalculo(pcdvinculo        IN INTEGER,
                                 pcdfolhapagamento IN INTEGER,
                                 pcdrubrica        IN INTEGER);

  FUNCTION fMneRubrica13FolhaNormal(pCdVinculo            IN INTEGER,
                                    pCdRubricaAgrupamento IN INTEGER,
                                    pNuAnoReferencia      IN INTEGER,
                                    pNuMesReferencia      IN INTEGER) RETURN NUMBER;

  FUNCTION fmnepossuidecjudicial(pcdvinculo            IN INTEGER,
                                 pcdrubricaagrupamento IN INTEGER,
                                 pnumesreferencia      IN INTEGER,
                                 pnuanoreferencia      IN INTEGER) RETURN INTEGER;

  FUNCTION fMneQtdDiasMesAnterior(pDataReferencia IN DATE,
                                  pLimite         IN INTEGER) RETURN INTEGER;

  FUNCTION fMnePercentAdiantFerias(pCdVinculo IN INTEGER,
                                   pNuAno     IN INTEGER,
                                   pNuMes     IN INTEGER) RETURN NUMBER;                                 

END pkgpag_fb;
/
CREATE OR REPLACE PACKAGE BODY pkgpag_fb IS

  SUBTYPE tdescformula IS VARCHAR2(2000);

  vVlFormula pkgpag_tipo.rvalorpagamento;

  vdeformulaCalculada pkgpag_tipo.rexprpagamento;

  vgindprocretro INTEGER;

  bcalcindvt BOOLEAN DEFAULT FALSE;

  vvlvaltransporte NUMBER(9, 4);

  bcalcmestrab BOOLEAN DEFAULT FALSE;

  vnumestrab INTEGER;

  vvlindiceoutrarubrica INTEGER;

  vVlSubst pkgpag_tipo.rvalorpagamento := NULL;

  CURSOR cpagrelvinccalc(pcdfolhapagamento IN INTEGER,
                         pcdvinculo        IN INTEGER) IS
    SELECT hrv.cdhistoricorubricarelvinc     AS cdhistpagamento,
           hrv.cdvinculo,
           hrv.cdrubricaagrupamento,
           hrv.cdexpressaoformcalc,
           hrv.cdvantagempecuniaria,
           hrv.cdrubricatotalizadoravantagem,
           hrv.cdincorporacaoativo,
           hrv.vlminrecebincorp,
           hrv.flatualizacaoconstante,
           hrv.flvigenciapagamento,
           hrv.nuordemcalculo,
           hrv.cdrelacaovinculo,
           hrv.cdchave,
           hrv.vlindicerubrica,
           1                                 AS cdtipohistorico, -- Se ? Rela??o de vinculo
           hrv.cdhistcargoefetivo,
           hrv.cdhistfuncaochefia,
           hrv.cdhistcargocom,
           hrv.cdconcessaoaposentadoria,
           hrv.cdhistestagio,
           hrv.cdhistpensaoprevidenciaria,
           hrv.cdhistpensaonaoprev,
           hrv.cdhistpensaoexparlamentar,
           hrv.cdhistauxilioreclusao,
           hrv.dtiniciorelacao,
           hrv.dtdesligamento,
           hrv.cdunidadeorganizacional,
           hrv.cdlancamentofinanceiro,
           hrv.dtinicio,
           hrv.dtfim,
           hrv.nusufixorubrica,
           hrv.vlindicereal
      FROM epaghistoricorubricarelvinc hrv
     WHERE HRV.CdVinculo = pCdVinculo AND
           HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           HRV.VlProporcional IS NULL
     ORDER BY nuordemcalculo;

  CURSOR cpagvinccalc(pcdfolhapagamento IN INTEGER,
                      pcdvinculo        IN INTEGER,
                      pcdrubrica        IN INTEGER) IS
    SELECT hrv.cdhistoricorubricavinculo AS cdhistpagamento,
           hrv.cdvinculo,
           hrv.cdrubricaagrupamento,
           hrv.cdexpressaoformcalc,
           hrv.cdvantagempecuniaria,
           hrv.cdrubricatotalizadoravantagem,
           hrv.cdincorporacaoativo,
           hrv.vlminrecebincorp,
           hrv.flatualizacaoconstante,
           hrv.flvigenciapagamento,
           hrv.nuordemcalculo,
           0,
           --0 as CdChave,
           hrv.cdvinculo                       AS cdchave,
           hrv.vlindicerubrica,
           2                                   AS cdtipohistorico, -- No Vinculo
           0                                   AS cdhistcargoefetivo,
           0                                   AS cdhistfuncaochefia,
           0                                   AS cdhistcargocom,
           0                                   AS cdconcessaoaposentadoria,
           0                                   AS cdhistestagio,
           0                                   AS cdhistpensaoprevidenciaria,
           0                                   AS cdhistpensaonaoprev,
           0                                   AS cdhistpensaoexparlamentar,
           0                                   AS cdhistauxilioreclusao,
           PKGPAG_VAR.vgvinculo.dtadmissao     AS dtiniciorelacao,
           PKGPAG_VAR.vgvinculo.dtdesligamento AS dtdesligamento,
           0                                   AS cdunidadeorganizacional,
           hrv.cdlancamentofinanceiro,
           PKGPAG_VAR.vgvinculo.dtadmissao     AS dtinicio,
           PKGPAG_VAR.vgvinculo.dtdesligamento AS dtfim,
           hrv.nusufixorubrica,
           hrv.vlindicerubrica                 AS vlindicereal
      FROM epaghistoricorubricavinculo hrv
      WHERE HRV.CdVinculo = pCdVinculo AND
            HRV.CdFolhaPagamento = pCdFolhaPagamento AND
           (hrv.cdrubricaagrupamento = pcdrubrica OR pcdrubrica IS NULL)
      ORDER BY nuordemcalculo     
           ;

  /*----------------------------------------------------------------------------
       Funcao: FCalcExpressao
     Objetivo:

   Argumentos:

         Nota:

 /-----------------------------------------------------------------------------*/


  PROCEDURE PVerificarFolPag (pNuAnoMesIni IN INTEGER) IS
     
  BEGIN
   
     PKGPAG_GERAL.PCarregarFolhaVinculo (pCdCalculo       => PKGPAG_VAR.vgCalculo.CdCalculo,
                                         pCdPessoa        => PKGPAG_VAR.vCdPessoa,
                                         pNuAnoMesIni     => pNuAnoMesIni);
  END;


  FUNCTION fcalcexpressao(pexpressao IN VARCHAR2, pCdRubrica in integer default null)

   RETURN NUMBER IS

    vexpressao tdescformula;
    vretorno   NUMBER;

  BEGIN
 
    vexpressao := REPLACE(pexpressao, ',', '.');

    /*

     DBMS_SQL.PARSE(vCursor,
                   'BEGIN :ret_val := ' ||
                   REPLACE(vExpressao,'in_variable',':in_variable') || '; END;',
                    DBMS_SQL.NATIVE );

      DBMS_SQL.BIND_VARIABLE(vCursor,':ret_val',vRetorno );

      vLinhaProc := DBMS_SQL.EXECUTE(vCursor);

      DBMS_SQL.VARIABLE_VALUE( vCursor, ':ret_val', vRetorno );

    */
    if pCdRubrica is not null then

      PKGPAG_VAR.vgValorCalculoRubrica(pCdRubrica).DeFormulaExpressao := vexpressao;

    end if;

    vretorno := pkgmath.fcalcular(vexpressao);

    IF vretorno < 0 THEN

      RETURN 0;

    ELSE

      RETURN nvl(vretorno, 0);

    END IF;

  END;

  /*----------------------------------------------------------------------------
    Avalia o valor de duas express?es
  /-----------------------------------------------------------------------------*/

  FUNCTION favaliaexpressao(pexpr IN pkgpag_tipo.rexprpagamento, pCdRubrica in integer default null)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vvlexpr pkgpag_tipo.rvalorpagamento;

  BEGIN
 
    vvlexpr.vlproporcional := fcalcexpressao(pexpr.deexprproporcional, pCdRubrica);

    IF pexpr.deexprintegral = pexpr.deexprproporcional THEN
      vvlexpr.vlintegral := vvlexpr.vlproporcional;
    ELSE
      vvlexpr.vlintegral := fcalcexpressao(pexpr.deexprintegral, pCdRubrica);
    END IF;

    IF pexpr.deexprreal = pexpr.deexprproporcional THEN
      vvlexpr.vlreal := vvlexpr.vlproporcional;
    ELSE
      vvlexpr.vlreal := fcalcexpressao(pexpr.deexprreal, pCdRubrica);
    END IF;

    RETURN vvlexpr;
  END;


FUNCTION fIndicaFeriado(pCdAgrupamento IN integer, pCdOrgao in integer, pDia in date, pCdUnid in integer, pCdLocal in integer)

   RETURN integer IS
    vCount integer := 0;

  BEGIN
     begin
      SELECT 1
        into vCount
        from EMOVCALENDARIOORGAO CO
       where CO.DTCALENDARIO = pDia
      and  CO.CDORGAO = pcdORGAO AND pcdORGAO IS NOT NULL
         and CO.CDTIPOFERIADO <> 3
         AND ROWNUM < 2;

    exception
     when no_data_found
       then
        begin
          SELECT 1
            into vCount
            FROM EMOVCALENDARIOAGRUPAMENTO CA
           WHERE CA.CDAGRUPAMENTO = pcdAGRUPAMENTO
             AND ca.dtcalendario = pDia
             AND ca.CDTIPOFERIADO <> 3
             AND ROWNUM < 2;

        exception
          when no_data_found then

            begin
              SELECT 1
                into vCount
                FROM ECADHISTUNIDADEORGANIZACIONAL H
               INNER JOIN EMOVCALENDARIOORGAO CO
                  ON H.CDORGAO = CO.CDORGAO
               INNER JOIN ECADHISTENDERECO E
                  ON H.CDENDERECO = E.CDENDERECO
               INNER JOIN EMOVCALENDARIOORGAOMUNICIPIO COM
                  ON CO.CDCALENDARIOORGAO = COM.CDCALENDARIO
                 AND E.CDLOCALIDADE = COM.CDLOCALIDADE
               WHERE H.CDUNIDADEORGANIZACIONAL = pCdUnid
                 AND pcdORGAO IS NOT NULL
                 AND H.DTINICIOVIGENCIA <= CO.DTCALENDARIO
               AND (H.DTFIMVIGENCIA >= CO.DTCALENDARIO OR H.DTFIMVIGENCIA IS NULL)
                 AND E.DTINICIOVALIDADE <= CO.DTCALENDARIO
               AND (E.DTFIMVALIDADE >= CO.DTCALENDARIO OR E.DTFIMVALIDADE IS NULL)
                 AND CO.CDTIPOFERIADO = 3
                 AND co.dtcalendario = pDia
                 AND ROWNUM < 2;

            exception
              when no_data_found then

                begin
                  SELECT 1
                    into vCount
                    FROM ECADHISTUNIDADEORGANIZACIONAL H
                   INNER JOIN ECADORGAO O
                      ON H.CDORGAO = O.CDORGAO
                   INNER JOIN EMOVCALENDARIOAGRUPAMENTO CA
                      ON O.CDAGRUPAMENTO = CA.CDAGRUPAMENTO
                   INNER JOIN ECADHISTENDERECO E
                      ON H.CDENDERECO = E.CDENDERECO
                   INNER JOIN EMOVCALENDARIOAGRUPMUNICIPIO CAM
                      ON CA.CDCALENDARIOAGRUPAMENTO = CAM.CDCALENDARIO
                     AND E.CDLOCALIDADE = CAM.CDLOCALIDADE
                   WHERE H.CDUNIDADEORGANIZACIONAL = pcdUNID
                     AND pcdAGRUPAMENTO IS NOT NULL
                     AND H.DTINICIOVIGENCIA <= CA.DTCALENDARIO
                     AND (H.DTFIMVIGENCIA >= CA.DTCALENDARIO OR H.DTFIMVIGENCIA IS NULL)
                     AND E.DTINICIOVALIDADE <= CA.DTCALENDARIO
                     AND (E.DTFIMVALIDADE >= CA.DTCALENDARIO OR E.DTFIMVALIDADE IS NULL)
                     AND CA.CDTIPOFERIADO = 3
                     AND CA.Dtcalendario = pDia
                     AND ROWNUM < 2;

                exception
                  when no_data_found then
                    begin

                      SELECT 1
                        into vCount
                        FROM EMOVCALENDARIOORGAO CO
                       INNER JOIN EMOVCALENDARIOORGAOMUNICIPIO COM
                          ON CO.CDCALENDARIOORGAO = COM.CDCALENDARIO
                       WHERE CO.CDORGAO = pcdORGAO
                         AND COM.CDLOCALIDADE = pcdLOCAL
                         AND CO.CDTIPOFERIADO = 3
                         AND CO.DTCALENDARIO = pDia
                         AND ROWNUM < 2;

                    exception
                      when no_data_found then
                        begin
                          SELECT 1
                            into vCount
                            FROM EMOVCALENDARIOAGRUPAMENTO CA
                           INNER JOIN EMOVCALENDARIOAGRUPMUNICIPIO CAM
                            ON CA.CDCALENDARIOAGRUPAMENTO = CAM.CDCALENDARIO
                           WHERE CA.CDAGRUPAMENTO = pcdAGRUPAMENTO
                             AND CAM.CDLOCALIDADE = pcdLOCAL
                             AND CA.CDTIPOFERIADO = 3
                             AND ca.dtcalendario = pDia
                             AND ROWNUM < 2;

                        exception
                          when no_data_found then
                            return 0;
                        end;
                    end;
                end;
            end;
        end;
    end;

    RETURN vCount;

  END;

  --------------------------------------------------------------------------------
  -- Retorna a quantidade de meses trabalhados at? a data fim da rela??o ou at?
  -- o m?s de dezembro
  -- pFlAteMesAtual - calcula o n?mero de meses trabalhados do ano corrente at? o m?s atual
  -- pFlAnoAdmissao - calcula o n?mero de meses trabalhados no ano de admiss?o
  ---------------------------------------------------------------------------------

  FUNCTION fmneqtmesestrabano(pfolha             IN pkgpag_tipo.rfolha,
                              pcdvinculo         IN INTEGER,
                              pdtiniciorelacao   IN DATE,
                              pdtfimrelacao      IN DATE,
                              pdtcalculo         IN DATE,
                              pflatemesatual     IN CHAR DEFAULT 'N',
                              pflanoadmissao     IN CHAR DEFAULT 'N',
                              pFlPeriodoFerias   IN CHAR DEFAULT 'N',
                              pFlValidaAuxDoenca IN CHAR DEFAULT 'N')


   RETURN INTEGER IS

    vdtinicioano DATE;

    vdtfimano DATE;

    vnumeses INTEGER;

    vdtinimes DATE;

    vdtfimmes DATE;

    vqtfalta NUMBER;

    vrecadastro NUMBER := 0;

    vnudiastotal INTEGER;

    vdtiniaquisitivoaberto DATE;

    vMantemFimAno CHAR := 'N';

    vnumdiasobito number := 0;

    /* Retorna a quantidade de meses entre o afastamento e o período aquisitivo */
    FUNCTION FValidaMesesAfastAuxDoenca(pNuMeses IN INTEGER) RETURN INTEGER IS
      
      vDtInicioAfast DATE;
      vDtFimAfast DATE;
      
    BEGIN
      
      BEGIN
        
       SELECT * 
         INTO vDtInicioAfast,
              vDtFimAfast
         FROM (SELECT MIN(b.dtinicio) as dtInicio, 
                      MAX(b.antfim) as dtFim                 
                FROM (SELECT a.cdvinculo,
                             a.dtinicio,
                             nvl(a.dtfim, pFolha.DtFimMes) as dtfim,
                             lag(a.dtinicio, 1, NULL) over(PARTITION BY a.cdvinculo ORDER BY a.dtinicio DESC) antini,
                             lag(a.dtfim, 1, NULL) over(PARTITION BY a.cdvinculo ORDER BY a.dtinicio DESC) antfim
                        FROM eafaafastamentovinculo a
                       WHERE a.cdvinculo = pCdVinculo
                         AND a.cdmotivoafasttemporario = 1873 /* AUXILIO DOENCA RGPS - SUPERIOR A 15 DIAS */
                         AND a.flTipoAfastamento = PKGPAG_TIPO.cnT
                         AND a.flAnulado = PKGPAG_TIPO.cnN) b
                WHERE b.dtfim = b.antini - 1) c
                WHERE c.DtInicio <= pDtFimRelacao
                 AND (c.DtFim >= pDtInicioRelacao OR c.DtFim IS NULL);     
     
       EXCEPTION
         
          WHEN NO_DATA_FOUND THEN
            
            SELECT MIN(A.Dtinicio)
              INTO vDtInicioAfast
              FROM EAfaAfastamentoVinculo A
             WHERE A.cdVinculo = pCdVinculo
               AND A.flTipoAfastamento = PKGPAG_TIPO.cnT
               AND A.cdMotivoAfastTemporario = 1873 /*AUXILIO DOENCA RGPS - SUPERIOR A 15 DIAS*/
               AND A.DtInicio <= pDtFimRelacao
               AND (A.DtFim >= pDtInicioRelacao OR A.DtFim IS NULL)
               AND A.flAnulado = PKGPAG_TIPO.cnN;
               
          WHEN OTHERS THEN
        
            RETURN 0;         
               
       END;         
      
       IF vDtInicioAfast IS NOT NULL THEN
         
         -- Se já passaram 24 meses, não tem direito a indenização de férias
         IF MONTHS_BETWEEN(pDtInicioRelacao , vDtInicioAfast) > 24 THEN
          
           RETURN 0;
          
         ELSE   
          
           IF MONTHS_BETWEEN(pDtInicioRelacao , vDtInicioAfast) + pNuMeses + 1 <= 24 THEN
             
             RETURN 1;
             
           ELSE
             
             RETURN 0;
             
           END IF;
          
         END IF;
        
       ELSE
         
         RETURN 0;
         
       END IF;
      
    EXCEPTION
      
      WHEN OTHERS THEN
        
        RETURN 0;  
        
    END;
 
  BEGIN
 
    bcalcmestrab := TRUE;

    IF pflanoadmissao = 'N' AND pFlPeriodoFerias = 'N' THEN

      vdtinicioano := trunc(to_date(pfolha.nuanoreferencia, 'YYYY'), 'YYYY');

      IF pdtiniciorelacao > vdtinicioano THEN

        vdtinicioano := pdtiniciorelacao;

      END IF;

      ------------------------------------------------------------------------
      -- FCEE - ACTs -> Contratos iniciado no ano anterior e prorrogados devido
      -- a licen?a maternidade podem ter usufruto de f?rias do primeiro aquisitivo.
      -- Neste caso, deve contar a quantidade de meses a partir do in?cio do
      -- per?odo aquisitivo em aberto e n?o a partir do in?cio do ano.
      -- Ajuste implementado para evitar o pagto de indeniza??o de f?rias em
      -- nova rubrica apenas para estes casos de licen?a maternidade com prorro
      -- ga??o de contrato
      ------------------------------------------------------------------------
      BEGIN
        SELECT pa.dtinicio
          INTO vdtiniaquisitivoaberto
          FROM emovperiodoaquisitivoferias pa
         WHERE pa.cdvinculo = pcdvinculo
           AND TO_CHAR(PA.DTINICIO,'YYYY') = TO_CHAR(pFolha.NuAnoReferencia)
           AND pa.nudiasferiasconcedido = 0;

      EXCEPTION
        WHEN no_data_found THEN
          vdtiniaquisitivoaberto := NULL;

        WHEN OTHERS THEN
          vdtiniaquisitivoaberto := NULL;

      END;

      /*if  vdtiniaquisitivoaberto is null and PKGPAG_VAR.vgcdrubcalculada = 37561
          then
            return 0;
      end if; */

      if  vdtiniaquisitivoaberto is not null and PKGPAG_VAR.vgcdrubcalculada in (37561,54270)
        then
        -- Incluido trecho abaixo apos a Solicitacao de Sustentação #79256
        -- 11825/2018 - FOLHA - RUBRICA 01-0332 FCEE - SUPLEMENTAR
        begin
          select max(pa1.dtfim)
            into vdtfimano
            from emovperiodoaquisitivoferias pa1
           WHERE pa1.cdvinculo = pcdvinculo
             AND TO_CHAR(pa1.dtfim,'YYYY') = TO_CHAR(pFolha.NuAnoReferencia)
             AND PA1.CDSITUACAOPERIODOAQFERIAS = 2
             AND NOT EXISTS (SELECT 1
                    FROM emovferiasfruicaopagamento fp
                               WHERE FP.CDPERIODOAQUISITIVOFERIAS = PA1.CDPERIODOAQUISITIVOFERIAS);

          vdtiniaquisitivoaberto := vdtinicioano;
          -- Verificar afastamentos que prorrogam o contrato e usar data fim como limite de contagem dos meses
          -- alterando a data final que foi alterada acima
          for i in PKGPAG_VAR.vgAfastTempRemun.First .. PKGPAG_VAR.vgAfastTempRemun.Last
            loop
              if PKGPAG_VAR.vgAfastTempRemun(i).CdMotivoAfastamento in (2667,3647,4387,3627)
               --2667  SALARIO MATERNIDADE - CONCESSAO APOS O NASCIMENTO - 120 DIAS
               --3647  SALARIO MATERNIDADE - CONCESSAO APOS O NASCIMENTO / RGPS 60 DIAS
               --4387  8709 ESTABILIDADE PROVISORIA ACT - GRAVIDEZ/ACIDENTE DE TRABALHO
               --3627  SALARIO MATERNIDADE - CONCESSAO ANTES DO NASCIMENTO / RGPS 60 DIAS
                and PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfa > vDtFimAno
                then
              vDtFimAno := PKGPAG_VAR.vgAfastTempRemun(i).DtFimAfa;
            end if;
          end loop;
          vMantemFimAno := 'S';
        exception
            when others
              then null;
        end;
          if vDtFimAno is null
            then
              vDtFimAno := to_date('31/12/' || pFolha.NuAnoReferencia, 'DD/MM/YYYY');
        end if;

      end if;

      --
      -- Defensoria publica
      --
      IF pFolha.CdAgrupamento = 176  and PKGPAG_VAR.vgcdrubcalculada = 49370
        THEN
        FOR fer IN (SELECT PA.CDPERIODOAQUISITIVOFERIAS, pa.dtinicio
                      FROM emovperiodoaquisitivoferias pa
                         inner join emovferiasfruicaousufruto pu on pu.cdperiodoaquisitivoferias = pa.cdperiodoaquisitivoferias
                     WHERE pa.cdvinculo = pcdvinculo
                       AND pkgmov.FCALCULARSALDOFERIAS(P_CDPERIODOAQUISITIVOFERIAS => pa.cdperiodoaquisitivoferias,
                                                       P_TIPOCALCULO               => 'R',
                                                       P_DATAINICIAL               => pFolha.DtInicioMes,
                                                       P_DATAFINAL                 => pFolha.DtFimMes,
                                                       P_CDUNIDADEORGANIZACIONAL   => NULL) > 0
                       AND pa.dtinicio < pFolha.DtInicioMes
                       AND pu.insituacao in (1, -- Programado
                                             2, -- Reprogramado
                                             3, -- Programado retroativamente
                                             11, -- Alterado
                                             12, -- Suspenso nao pago
                                             5, -- Suspenso com estorno dos beneficios
                                             6, -- Suspenso motivo de movimentacao
                                             7, -- Interrompido definitivamente
                                             8 -- Interrompido temporariamente
                           ) order by pa.dtinicio DESC)

         LOOP

          vdtinicioano := fer.dtinicio;

        END LOOP;

      ELSIF pFolha.CdOrgao = 42 AND
            pDtInicioRelacao < vDtInicioAno     AND
            PKGPAG_VAR.vgcdrubcalculada = 37561 AND
            vdtiniaquisitivoaberto IS NOT NULL THEN

        vdtinicioano := vdtiniaquisitivoaberto;

      else
        null;
      END IF;

      ------------------------------------------------------------------------

      IF vMantemFimAno = 'N'
       then

        IF pflatemesatual = 'N' THEN

          vDtFimAno := TRUNC(TO_DATE(to_char(pFolha.NuAnoReferencia + 1),'YYYY'),'YYYY') - 1;

        ELSE

          vdtfimano := pfolha.dtfimmes;

        END IF;

      end if;

      IF pdtfimrelacao < vdtfimano THEN

        vdtfimano := pdtfimrelacao;

        -- AJUSTAR DATA INICIO QUANDO FICA EM ANO MAIOR QUE DATA FIM PARA A RUBRICA 01-0332
        -- CASOS DA UDESC COM ACT QUE FOI AFASTADO EM JANEIRO COM DATA DE DEZEMBRO(FINAL)
      IF TO_CHAR(vDtFimAno,'YYYY') < TO_CHAR(vDtInicioAno,'YYYY')
         AND PKGPAG_VAR.vgCdRubCalculada = 37561 AND TO_CHAR(pDtFimRelacao,'MM') = '12'
       THEN
         vDtInicioAno := to_date(TO_CHAR(vDtInicioAno,'DDMM') || TO_CHAR(vDtFimAno,'YYYY'), 'DDMMYYYY');

         IF vDtInicioAno < pDtInicioRelacao
            THEN
            vdtinicioano := pdtiniciorelacao;
          END IF;

        END IF;

      END IF;

      --
      -- Mnemonico MesesTrabPeriodoFerias
      --
    ELSIF pFlPeriodoFerias = 'S'
      THEN

      vDtInicioAno := pdtiniciorelacao;

      vDtFimAno := pDtFimRelacao;

    ELSE

      vdtinicioano := pdtiniciorelacao;

      vDtFimAno    := TO_DATE('3112'||TO_CHAR(vDtInicioAno,'YYYY'), 'DDMMYYYY');

    END IF;

    vnumeses := 0;

    vnudiastotal := 0;

    FOR rec IN (
      select Y.Mes, y.nudiasmes, nvl(z.nudiasafast, 0) as nudiasafast
        from (select TO_CHAR(dtDia, 'YYYYMM') as Mes, count(*) as NuDiasMes
                          from (select vdtinicioano + (level - 1) as dtdia
                                  from dual
                      connect by vDtInicioAno + (level - 1) between vDtInicioAno and vDtFimAno) X
                         group by to_char(dtdia, 'YYYYMM')) y
        left join (select Mes, nvl(sum(DiaAfastado), 0) as NuDiasAfast
                     from (select TO_CHAR(dtDia, 'YYYYMM') as Mes, dtDia as DtDiaAfastado, 1 as DiaAfastado
                                      from (select vdtinicioano + (level - 1) as dtdia
                                              from dual
                                   connect by vDtInicioAno + (level - 1) between vDtInicioAno and vDtFimAno) D
                            inner join (select GREATEST(AV.dtInicio, vDtInicioAno) dtInicio
                                             , LEAST(NVL(AV.dtFim,
                                                                 (case
                                                           when (MAT.CdMotivoAfastTemporario = 2627 and pfolha.nuanoreferencia = 2012 and
                                                                        pfolha.numesreferencia = 11) then
                                                                    pfolha.dtfimmes -- Provavel fim da greve
                                                                   else
                                                                    vdtfimano
                                                                 end)),
                                                             vdtfimano) as dtfim
                                                  from eafaafastamentovinculo av
                                         inner join eafamotivoafasttemporario mat on AV.CdMotivoAfastTemporario = MAT.CdMotivoAfastTemporario
                                         inner join eafahistmotivoafasttemp hmat on MAT.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
                                         where AV.CdVinculo = pCdVinculo
                                           and HMAT.FlRemunerado = pkgpag_tipo.cnN
                                           and AV.DtInicio <= vDtFimAno
                                           and (AV.DtFim >= vDtInicioAno or AV.DtFim is null)
                                           and not (PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cnTpFolhaAdiant13
                                                and av.dtinicio > PKGPAG_VAR.vgfolha.dtFimMes
                                                and hmat.flremunerado = pkgpag_tipo.cnN
                                                and mat.cdmotivoafasttemporario in (1609, 1915, 2029, 2143, 2257, 2371, 4045) -- Motivos dos grupos 'TEMPORARIO - ATUALIZACAO CADASTRAL/RECADASTRAMENTO'
                                                        )
                                           and HMAT.DtInicioVigencia <= pDtCalculo
                                           and (HMAT.DtFimVigencia >= pDtCalculo or HMAT.DtFimVigencia is null)
                                           and HMAT.FlAnulado = pkgpag_tipo.cnN
                                           and AV.FlAnulado = pkgpag_tipo.cnN) B
                                    on (B.DtInicio <= D.DtDia) and (B.DtFim >= D.DtDia)) A
                 group by mes) z on Z.Mes = Y.Mes
    ) LOOP

      vdtinimes := to_date(rec.mes, 'YYYYMM');

      vdtfimmes := add_months(vdtinimes, 1) - 1;

      if to_char(vDtIniMes,'MM') = 2 and
         (vdtfimano - vDtIniMes + 1) >= 15
        then
        rec.nudiasmes := rec.nudiasmes + (30 - to_char(vDtFimMes, 'dd'));
      end if;

      vdtinimes := greatest(vdtinimes, vdtinicioano);

      vdtfimmes := least(vdtfimmes, vdtfimano);

      pkgmovfre.pcalcularfaltas(pcdvinculo             => pcdvinculo,
                                pdtiniapuracao         => vdtinimes,
                                pdtfimapuracao         => vdtfimmes,
                                pflsomentejornada      => 'S',
                                pflsomenteenturmacao   => 'S',
                                pCdEventoDesconsiderar => 1); -- Solicitacao de Sustentacao #63810
      -- AS FALTAS SINALIZADAS COM O EMOVFREQUENCIAJORNADA
      -- WHERE CDEVENTOFREQUENCIA = 1 NAO DEVEM SER CONSIDERADAS NO CALCULO DO 13.

      vqtfalta := pkgmovfre.findicefalta;

      --Salva os vinculos que tiveram desconto de faltas na folha de 13 salario.
      IF vqtfalta >= 15 THEN

        INSERT INTO EPagEventoVinculo
          (CdEventoVinculo,
           CdVinculo,
           CdTipoEventoVinculo,
           NuAnoMesReferencia,
           VlEvento,
           VlIndice,
           CdRubricaAgrupamento,
           NuCpfCadastrador,
           NuCpfUltimaAlteracao,
           DtInclusao,
           DtUltAlteracao,
           CdChave)
        VALUES
          (SPagEventoVinculo.nextval,
           pcdvinculo,
           5, --Desconto Faltas 13 Salario
           to_char(vdtinimes, 'YYYYMM'),
           NULL,
           vqtfalta,
           NULL,
           '00000000000',
           NULL,
           SYSDATE,
           SYSTIMESTAMP,
           pfolha.CdFolhaPagamento);

      END IF;

      vNuDiasTotal :=  vNuDiasTotal + (rec.NuDiasMes - rec. NuDiasAfast - vQtFalta);

      -- Caso a quantidade de dias trabalhados seja >= 15 o m?s ? considerado trabalhado
      IF rec.nudiasmes - rec.nudiasafast - vqtfalta >= 15 THEN

        vnumeses := vnumeses + 1;

      -- Para AGPE, auxílio doença até 24 meses não deve ser considerado como afastamento na indenização de férias
      ELSIF pFlValidaAuxDoenca = 'S' AND pFolha.cdAgrupamento = 1 THEN
        
        IF FValidaMesesAfastAuxDoenca(vnumeses) > 0 THEN
        
          vnumeses := vnumeses + 1; 
          
        END IF;
         
      ELSE
        --
        -- Verificar se o motivo de afastamento temporario eh por recadastramento
        -- e se foi recadastrado no ANO, conta este m?s.
        -- Para casos em que por um determinado periodo do ano ficou sem pagamentos
        -- por falta de cadastramento mas regularizou a situa??o
        --
        BEGIN

          SELECT 1
            INTO vrecadastro
            FROM eafaafastamentovinculo av
           WHERE av.cdvinculo = pcdvinculo
             AND av.cdmotivoafasttemporario in (1609, 4587)
             AND av.flanulado = 'N'
             AND vdtinimes BETWEEN av.dtinicio AND av.dtfim
             AND av.dtfim < vdtfimano
             AND rownum < 2;

        EXCEPTION

          WHEN NO_DATA_FOUND
           THEN
            vrecadastro := 0;

        END;

        --Verificar se fez o recadastramento no ANO
        IF vrecadastro = 1 THEN

          BEGIN

            SELECT 1
              INTO vrecadastro
              FROM epvdhistrecadastramento ep
             WHERE ep.cdpessoa = PKGPAG_VAR.vgvinculo.cdpessoa
                   AND (ep.nuanorecadastramento = to_number(to_char(vdtfimano, 'YYYY')) or
                        to_char(ep.dtrecadastramento,'YYYY') = to_char(vdtfimano, 'YYYY'))
               AND ep.flanulado = 'N'
               AND rownum < 2;

          EXCEPTION

             WHEN NO_DATA_FOUND
               THEN
              vrecadastro := 0;

          END;

          IF vrecadastro = 1 THEN

            vnumeses := vnumeses + 1;

          END IF;

        END IF;

      END IF;

    END LOOP;

    -------  Tratar a afastamento definitivo (óbito)

    BEGIN

      SELECT to_char(pfolha.DtFimMes, 'mm') - to_char(vdtinicioano, 'mm')
        INTO vnumdiasobito
          FROM   eafaafastamentovinculo afv,
                 eafahistmotivoafastdef afvh
       WHERE afv.cdvinculo = pcdvinculo
         AND afv.cdmotivoafastdefinitivo = afvh.cdmotivoafastdefinitivo
         AND afvh.cdmotivoafastdefinitivo = 293; ----Falecimento
    EXCEPTION
            WHEN OTHERS
              THEN
        vnumdiasobito := null;
    END;

    IF vnumdiasobito > 0 and pfolha.CdOrgao = 34 and pcdvinculo = 944880 then
      vnumeses := vnumdiasobito;
    END IF;

    ------------------------------------------------------------------------
    -- 16/05/2014 - Valida??o para pagar pelo menos um m?s quando a
    -- quantidade  demeses ? ZERO, mas o servidor trabalhou mais de 15 dias
    ------------------------------------------------------------------------
    IF vnudiastotal >= 15 AND vnudiastotal < 30 AND vnumeses = 0 THEN

      vnumeses := vnumeses + 1;

    END IF;

    RETURN vnumeses;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;
  
  
  FUNCTION ffolha13saldezembro(pfolha IN pkgpag_tipo.rfolha)

   RETURN INTEGER IS

  BEGIN
 
    IF pfolha.cdtipofolha = pkgpag_tipo.cntpfolha13 AND
       pfolha.numesreferencia = 12 THEN

      RETURN 1;

    ELSE

      RETURN 0;

    END IF;

  END;


  --
  -- Quantidade de dias afastados sem remuneracao no mes. Origem PKGPAG_CAL
  -- para descontar os dias apos retorno do auxilio doenca EPAGRI
  --
  FUNCTION fmneqtdiasafastsemrem

   RETURN INTEGER IS

  BEGIN
 
   IF PKGPAG_VAR.vMotAfast.FlAuxilioDoenca = PKGPAG_TIPO.cnS
     AND PKGPAG_VAR.vgParamOrgao.FlAuxilioDoenca = PKGPAG_TIPO.cnS
     AND PKGPAG_VAR.vMotAfast.InAfastado = PKGPAG_TIPO.cnAfastadoParcial
     THEN
      RETURN nvl(PKGPAG_VAR.vgNuDiasAfastSemRemun, 0);
    ELSE
      RETURN 0;
    END IF;
  END;

  FUNCTION fmneqtmesestrabanox(pfolha           IN pkgpag_tipo.rfolha,
                               pcdvinculo       IN INTEGER,
                               pdtiniciorelacao IN DATE,
                               pdtfimrelacao    IN DATE,
                               pdtcalculo       IN DATE,
                               pflatemesatual   IN CHAR DEFAULT 'N',
                               pflanoadmissao   IN CHAR DEFAULT 'N')

   RETURN INTEGER IS

    vdtinicioano DATE;

    vdtfimano DATE;

    vnumeses INTEGER;

  BEGIN
 
    bcalcmestrab := TRUE;

    IF pflanoadmissao = 'N' THEN

      vdtinicioano := trunc(to_date(pfolha.nuanoreferencia, 'YYYY'), 'YYYY');

      IF pdtiniciorelacao > vdtinicioano THEN

        vdtinicioano := pdtiniciorelacao;

      END IF;

      IF pflatemesatual = 'N' THEN

      vDtFimAno := TRUNC(TO_DATE(pFolha.NuAnoReferencia + 1,'YYYY'),'YYYY') - 1;

      ELSE

        vdtfimano := pfolha.dtfimmes;

      END IF;

      IF pdtfimrelacao < vdtfimano THEN

        vdtfimano := pdtfimrelacao;

      END IF;

    ELSE

      vdtinicioano := pdtiniciorelacao;

    vDtFimAno    := TO_DATE('3112'||TO_CHAR(vDtInicioAno,'YYYY'), 'DDMMYYYY');

    END IF;

    SELECT COUNT(*)
      INTO vnumeses
      FROM (SELECT to_char(dtdia, 'YYYYMM') AS mes, COUNT(*) AS nudias
              FROM (SELECT vdtinicioano + (LEVEL - 1) AS dtdia
                      FROM dual
                 CONNECT BY vDtInicioAno + (LEVEL - 1)
                 BETWEEN vDtInicioAno AND vDtFimAno) X
             GROUP BY to_char(dtdia, 'YYYYMM')) y
      LEFT JOIN (SELECT mes, nvl(SUM(diaafastado), 0) AS nudiasafast
                 FROM ( SELECT CdVinculo, TO_CHAR(dtDia, 'YYYYMM') AS Mes, dtDia AS DtDiaAfastado, 1 AS DiaAfastado
                           FROM (SELECT vdtinicioano + (LEVEL - 1) AS dtdia
                                   FROM dual
                               CONNECT BY vDtInicioAno + (LEVEL - 1)
                               BETWEEN vDtInicioAno AND vDtFimAno) D
                          INNER JOIN (SELECT cdvinculo,
                                            CASE
                                              WHEN av.dtinicio < vdtinicioano THEN
                                               vdtinicioano
                                              ELSE
                                               av.dtinicio
                                            END AS dtinicio,
                                            CASE
                                              WHEN (AV.dtFim > vDtFimAno OR AV.DtFim IS NULL) THEN
                                               vdtfimano
                                              ELSE
                                               av.dtfim
                                            END AS dtfim
                                       FROM eafaafastamentovinculo av
                                      INNER JOIN eafamotivoafasttemporario mat
                                         ON AV.CdMotivoAfastTemporario = MAT.CdMotivoAfastTemporario
                                      INNER JOIN eafahistmotivoafasttemp hmat
                                         ON MAT.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
                                     WHERE  AV.CdVinculo = pCdVinculo AND
                                           HMAT.FlRemunerado = PKGPAG_TIPO.cnN AND
                                           AV.DtInicio <= vDtFimAno AND
                                           (AV.DtFim >= vDtInicioAno OR AV.DtFim IS NULL) AND
                                           HMAT.DtInicioVigencia <= pDtCalculo AND
                                           (HMAT.DtFimVigencia >= pDtCalculo OR HMAT.DtFimVigencia IS NULL) AND
                                           HMAT.FlAnulado = PKGPAG_TIPO.cnN AND AV.FlAnulado = PKGPAG_TIPO.cnN) B
                              ON (B.DtInicio <= D.DtDia) AND (B.DtFim >= D.DtDia)) A
                  GROUP BY mes) z
        ON z.mes = y.mes
       WHERE CASE WHEN (Y.Mes - pFolha.NuAnoReferencia*100 ) = 2 THEN -- ROGERIO
              (y.nudias + 2)
             ELSE
              y.nudias
           END - nvl(z.nudiasafast, 0) >= 15;

    IF PKGPAG_VAR.vgqtfaltas >= 15 THEN

      vnumeses := vnumeses - trunc(PKGPAG_VAR.vgqtfaltas / 15);

    END IF;

    RETURN vnumeses;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
      Funcao: FMneuQtMesesTrabAno
    Objetivo: Chamada externamente
  ------------------------------------------------------------------------------*/

  FUNCTION fmneuqtmesestrabano(pfolha             IN pkgpag_tipo.rfolha,
                               pcdvinculo         IN INTEGER,
                               pdtiniciorelacao   IN DATE,
                               pdtfimrelacao      IN DATE,
                               pdtcalculo         IN DATE,
                               pflatemesatual     IN CHAR DEFAULT 'N',
                               pflanoadmissao     IN CHAR DEFAULT 'N',
                               pFlPeriodoFerias   IN CHAR DEFAULT 'N',
                               pFlValidaAuxDoenca IN CHAR DEFAULT 'N')

   RETURN INTEGER IS

  BEGIN
 
    RETURN FMneQtMesesTrabAno(pFolha             => pFolha,
                              pCdVinculo         => pCdVinculo,
                              pdtiniciorelacao   => pdtiniciorelacao,
                              pdtfimrelacao      => pdtfimrelacao,
                              pdtcalculo         => pdtcalculo,
                              pflatemesatual     => pflatemesatual,
                              pflanoadmissao     => pflanoadmissao,
                              pFlPeriodoFerias   => pFlPeriodoFerias,
                              pFlValidaAuxDoenca => pFlValidaAuxDoenca);


  END;

  FUNCTION fmneqtmesestrabatemesref(pfolha           IN pkgpag_tipo.rfolha,
                                    pcdvinculo       IN INTEGER,
                                    pdtiniciorelacao IN DATE,
                                    pdtfimrelacao    IN DATE,
                                    pdtcalculo       IN DATE)

   RETURN INTEGER IS

  BEGIN
 
    RETURN fmneqtmesestrabano(pfolha => pfolha,

                              pcdvinculo       => pcdvinculo,
                              pdtiniciorelacao => pdtiniciorelacao,
                              pdtfimrelacao    => pdtfimrelacao,
                              pdtcalculo       => pdtcalculo,
                              pflatemesatual   => 'S');

  END;

  FUNCTION fmneqtmesestrabaperiodoferias(pfolha           IN pkgpag_tipo.rfolha,
                                         pcdvinculo       IN INTEGER,
                                         pdtiniciorelacao IN DATE,
                                         pdtfimrelacao    IN DATE,
                                         pdtcalculo       IN DATE)

   RETURN INTEGER IS

  BEGIN
 
    RETURN fmneqtmesestrabano(pfolha           => pfolha,
                              pcdvinculo       => pcdvinculo,
                              pdtiniciorelacao => pdtiniciorelacao,
                              pdtfimrelacao    => pdtfimrelacao,
                              pdtcalculo       => pdtcalculo,
                              pFlPeriodoFerias => 'S');

  END;

  FUNCTION fmneRetornaValorRub(PCdFolhaPagamento     INTEGER, 
                               PCdVinculo            INTEGER, 
                               pCdRubricaAgrupamento INTEGER) RETURN NUMBER IS
                               
    vVlPagamento NUMBER(13,2);
    
  BEGIN
    
    SELECT SUM(hrv.vlintegral)
      INTO vVlPagamento
      FROM Epaghistoricorubricarelvinc hrv
      WHERE hrv.cdfolhapagamento = pcdfolhapagamento
        AND hrv.cdvinculo = PCdVinculo
        AND hrv.cdrubricaagrupamento = PcdRubricaAgrupamento;
        
    RETURN NVL(vVLPagamento,0);
    
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;    
  END;  
  
  FUNCTION fmneOpc70(PCdFolhaPagamento INTEGER, 
                     PCdVinculo        INTEGER) RETURN NUMBER IS
                               
     vVlOpc70    NUMBER(13,2);
     vVlIprevCCO NUMBER(13,2);
    
  BEGIN
    
     vVLOpc70 := 0;
     
     IF pkgpag_var.bPossuiIprevCCO AND (PKGPAG_VAR.vgCCO.count > 0 OR PKGPAG_VAR.vgFUC.count > 0) THEN
        
            SELECT nvl(SUM(HRV.VlIntegral), 0) as vlIntegral
              INTO vVLOpc70
              FROM EPagHistoricoRubricaRelVinc   HRV,
                   EPagBaseCalcBlocoExprRubAgrup B,
                   Epagbasecalculoblocoexpressao E,
                   Epaghistbasecalculo HB,
                   Epagbasecalculobloco BL,
                   Epagbasecalculoversao V,
                   Epagbasecalculo C
             WHERE HRV.CdFolhaPagamento = PCdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND B.CdBaseCalculoBlocoExpressao = E.CdBaseCalculoBlocoExpressao
               AND BL.CdBaseCalculoBloco = E.CdBaseCalculoBloco
               AND HB.CdHistBaseCalculo = BL.CdHistBaseCalculo
               AND V.CdVersaoBaseCalculo = HB.CdVersaoBaseCalculo
               AND C.CdBaseCalculo = V.CdBaseCalculo
               AND C.SgBaseCalculo = 'OPC70'
               AND HB.NuAnoFimVigencia IS NULL
               AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
               AND HRV.CdRelacaoVinculo = 1;

            vVlIprevCCO     := 0;
            
            -- Valores pagos no total das rubricas que compoe a base
            SELECT nvl(SUM(HRV.vlProporcional), 0) as vlProporcional
              INTO vVlIprevCCO
              FROM EPagHistoricoRubricaRelVinc   HRV,
                   EPagBaseCalcBlocoExprRubAgrup B,
                   Epagbasecalculoblocoexpressao E,
                   Epaghistbasecalculo HB,
                   Epagbasecalculobloco BL,
                   Epagbasecalculoversao V,
                   Epagbasecalculo C
             WHERE HRV.CdFolhaPagamento = PCdFolhaPagamento
               AND HRV.CdVinculo = pCdVinculo
               AND B.CdBaseCalculoBlocoExpressao = E.CdBaseCalculoBlocoExpressao
               AND BL.CdBaseCalculoBloco = E.CdBaseCalculoBloco
               AND HB.CdHistBaseCalculo = BL.CdHistBaseCalculo
               AND V.CdVersaoBaseCalculo = HB.CdVersaoBaseCalculo
               AND C.CdBaseCalculo = V.CdBaseCalculo
               AND C.SgBaseCalculo = 'OPC70'
               AND HB.NuAnoFimVigencia IS NULL
               AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento;

            IF NVL(vVlIprevCCO,0) > NVL(vVLOpc70,0) THEN

                vVLOpc70 := vVlIprevCCO - vVLOpc70 ;

            END IF;
            
      END IF;      
            
      RETURN vVLOpc70;
            
  EXCEPTION          
     
    WHEN OTHERS THEN
      
     RETURN 0;
     
  END;
  
  FUNCTION fmneCCOPuro(pCCO IN PKGPAG_TIPO.tCCO,
                       pCEF IN PKGPAG_TIPO.tCEF ) RETURN INTEGER IS
                                  
    
  BEGIN
    
    IF pCCO.count > 0 AND pCEF.count = 0 THEN
      
       RETURN 1;
       
    ELSE
      
       RETURN 0;      
       
    END IF;
    
  EXCEPTION
    
    WHEN OTHERS THEN
      
      RETURN 0;  
        
  END;  
  
  FUNCTION fmneiprev13sal(pcdvinculo        IN INTEGER,
                          pfolha            IN pkgpag_tipo.rfolha,
                          pcdfolhareplicada IN INTEGER)

   RETURN NUMBER IS

    vvlbaseipev13sal      NUMBER(13, 2);
    --vvlBaseIprev13SalResc pkgpag_tipo.rvalorpagamento;

    FUNCTION fvalorbaseipesccef(pFlAposentadoDuranteMes IN CHAR)

     RETURN NUMBER IS

      vvlbase             NUMBER(15, 4);
      vvlbaseProporcional NUMBER(15, 4);
      vvlbaseIntegralCef      NUMBER(15, 4);
      vNuDiasTrab         INTEGER;
      vNuDiasMes          INTEGER;

    BEGIN
 
      SELECT SUM(pag.vlproporcional),
             SUM(pag.vlintegral)
        INTO vvlbaseProporcional,
             vvlbaseIntegralCef
        FROM epaghistoricorubricarelvinc pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
      -------- descobre rubricas que incidem na base do IPREV
       INNER JOIN (SELECT DISTINCT rubex.cdrubricaagrupamento
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
                    WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC )  A
          ON a.cdrubricaagrupamento = pag.cdrubricaagrupamento
         AND pag.cdrubricaagrupamento <> PKGPAG_GERAL.fretornarubrica(1,1,1252)
      -------- descobre rubricas que incidem na base do 13 salario
       INNER JOIN (SELECT DISTINCT rubex2.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rubm2
                    INNER JOIN epagbasecalculo base2
                       ON base2.cdbasecalculo = rubm2.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                        ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb2
                        ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl2
                       ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao ex2
                       ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubex2
                        ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                      WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal) B
          ON b.cdrubricaagrupamento = pag.cdrubricaagrupamento
          AND pag.cdrubricaagrupamento <> PKGPAG_GERAL.fretornarubrica(1,1,1252)
          WHERE PAG.CdVinculo = pCdVinculo 
            AND (PAG.CdHistCargoEfetivo IS NOT NULL OR (PAG.Cdconcessaoaposentadoria IS NOT NULL AND pFlAposentadoDuranteMes = 'S'))
            AND PAG.CdFolhaPagamento = pCdFolhaReplicada;

      IF pFlAposentadoDuranteMes = 'S' THEN
        
        vvlbase := vvlbaseProporcional;
        
      ELSE
        
        vvlbase := vvlbaseIntegralCef;
        
        IF PKGPAG_VAR.vgVinculo.DtAdmissao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes OR
           PKGPAG_VAR.vgVinculo.DtDesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes THEN
           
          vNuDiasTrab := (to_number(TO_CHAR(LEAST(PKGPAG_VAR.vgFolha.DtFimMes, NVL(PKGPAG_VAR.vgVinculo.DtDesligamento,PKGPAG_VAR.vgFolha.DtFimMes)),'DD'))) - 
                         (to_number(TO_CHAR(GREATEST(pFolha.DtInicioMes,PKGPAG_VAR.vgVinculo.DtAdmissao),'DD'))) + 1;
                         
          vNuDiasMes  := to_number(TO_CHAR(PKGPAG_VAR.vgFolha.DtFimMes, 'DD')); 

          IF vNuDiasTrab > 30 THEN
            
            vNuDiasTrab := 30;
            
          END IF;

          IF vNuDiasMes > 30 THEN
            
            vNuDiasMes := 30;
            
          END IF;

          vvlbase := (vvlbase / vNuDiasTrab * vNuDiasMes);
           
        END IF; 
        
      END IF;  

      RETURN vvlbase;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

    FUNCTION fvalorbaseipescapo

     RETURN NUMBER IS

      vvlbase NUMBER(15, 4);

    BEGIN
 
      SELECT SUM(pag.vlintegral)
        INTO vvlbase
        FROM epaghistoricorubricarelvinc pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
        ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
      -------- descobre rubricas que incidem na base do IPREV
       INNER JOIN (SELECT rubex.cdrubricaagrupamento
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
                  WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC ) A
          ON a.cdrubricaagrupamento = pag.cdrubricaagrupamento
      -------- descobre rubricas que incidem na base do 13 salario
       INNER JOIN (SELECT rubex2.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rubm2
                    INNER JOIN epagbasecalculo base2
                       ON base2.cdbasecalculo = rubm2.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                      ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb2
                      ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl2
                       ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao ex2
                       ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubex2
                      ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                    WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal) B
          ON b.cdrubricaagrupamento = pag.cdrubricaagrupamento
        WHERE PAG.cdVinculo = pCdVinculo AND
              PAG.CdConcessaoAposentadoria IS NOT NULL AND
              PAG.CdFolhaPagamento = PKGPAG_VAR.vgCdFolhaNormal;

      RETURN vvlbase;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

    FUNCTION fvalorbaseipescdesligado

     RETURN NUMBER IS

      vvlbase NUMBER(15, 4);

    BEGIN
 
      SELECT SUM(pag.vlintegral)
        INTO vvlbase
        FROM epaghistoricorubricarelvinc pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
      -------- descobre rubricas que incidem na base do IPREV
       INNER JOIN (SELECT DISTINCT rubex.cdrubricaagrupamento
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
                    WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC ) A
          ON a.cdrubricaagrupamento = pag.cdrubricaagrupamento
      -------- descobre rubricas que incidem na base do 13 salario
       INNER JOIN (SELECT DISTINCT rubex2.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rubm2
                    INNER JOIN epagbasecalculo base2
                       ON base2.cdbasecalculo = rubm2.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                        ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb2
                        ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl2
                       ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao ex2
                       ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubex2
                        ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                      WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal) B
          ON b.cdrubricaagrupamento = pag.cdrubricaagrupamento
          WHERE PAG.CdVinculo = pCdVinculo AND
                PAG.CdHistCargoEfetivo IS NOT NULL AND
                PAG.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt;



      RETURN vvlbase;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

  BEGIN
 
    vvlbaseipev13sal := 0;

    /*vvlBaseIprev13SalResc := PKGPAG_GERAL.fretornavaloroutrasrv(pcdfolhapagamento     => pFolha.CdFolhaPagamento,
                                                                pcdvinculo            => pcdvinculo,
                                                                pcdrubricaagrupamento => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                                                                                      pcdtiporubrica => 1,
                                                                                                                      pNuRubrica     => 1023));

    IF NVL(vvlBaseIprev13SalResc.vlProporcional, 0) = 0 THEN
      vvlBaseIprev13SalResc.vlProporcional := PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                pcdvinculo        => pcdvinculo,
                                                                                pcdrubrica        => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                                                  pcdtiporubrica => 1,
                                                                                                                                  pNuRubrica     => 1023));
    END IF;

    -- Solicitacao de Sustentacao #77583
    -- Para a Defensoria Publica, Caso haja a rubrica 01-1023, esta assume a base do BASE-IPESC-13 09-0920
    IF nvl(vvlBaseIprev13SalResc.vlProporcional,0) > 0 AND pFolha.CdAgrupamento = 176 THEN
      RETURN vvlBaseIprev13SalResc.vlProporcional;
    END IF;*/

    IF PKGPAG_VAR.vgcef.count > 0 AND 
       ((PKGPAG_VAR.vgapo.count > 0 AND 
         PKGPAG_VAR.vgApo(1).DtInicioRelacao > pFolha.DtInicioMes AND 
         PKGPAG_VAR.vgApo(1).DtInicioRelacao <= pFolha.DtFimMes)
        OR
        (PKGPAG_VAR.vgaposemparidade.count > 0 AND 
         PKGPAG_VAR.vgaposemparidade(1).DtInicioRelacao > pFolha.DtInicioMes AND 
         PKGPAG_VAR.vgaposemparidade(1).DtInicioRelacao <= pFolha.DtFimMes)) THEN
       
      vvlbaseipev13sal := fvalorbaseipesccef(pFlAposentadoDuranteMes => 'S'); 
       
    ELSIF PKGPAG_VAR.vgcef.count > 0 THEN

      vvlbaseipev13sal := fvalorbaseipesccef(pFlAposentadoDuranteMes => 'N');

    ELSIF PKGPAG_VAR.vgapo.count > 0 THEN

      IF (PKGPAG_VAR.vgApo(1).DtInicioRelacao < pFolha.DtInicioMes OR
         (PKGPAG_VAR.vgApo(1).DtInicioRelacao >= pFolha.DtInicioMes AND
          PKGPAG_VAR.vgApo(1).DtInicioRelacao <= pFolha.DtFimMes)) THEN

        vvlbaseipev13sal := fvalorbaseipescapo;

      END IF;

    ELSIF PKGPAG_VAR.vgaposemparidade.count > 0 THEN

      IF (PKGPAG_VAR.vgAPOSemParidade(1).DtInicioRelacao < pFolha.DtInicioMes OR
         (PKGPAG_VAR.vgAPOSemParidade(1).DtInicioRelacao > pFolha.DtInicioMes AND
          PKGPAG_VAR.vgAPOSemParidade(1).DtInicioRelacao <= pFolha.DtFimMes)) THEN

        vvlbaseipev13sal := fvalorbaseipescapo;

      END IF;

    ELSIF PKGPAG_VAR.vgvinculo.dtdesligamento < pfolha.dtiniciomes THEN

      IF PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento    => pFolha.CdFolhaPagamento,
                                           pcdvinculo           => pcdvinculo,
                                           pcdrubrica           => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                                                                pcdtiporubrica => 1,
                                                                                                pNuRubrica     => 1023))  > 0 THEN
                                          

         vvlbaseipev13sal := fvalorbaseipescdesligado;
      
      ELSE
         vvlbaseipev13sal := 0;
      END IF;  

    else
      null;
    END IF;

    RETURN vvlbaseipev13sal;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fmneiprev13salnew(pcdvinculo        IN INTEGER,
                             pfolha            IN pkgpag_tipo.rfolha,
                             pcdfolhareplicada IN INTEGER)

   RETURN NUMBER IS

    vvlbaseipev13sal      NUMBER(13, 2);
    vvlBaseIprev13SalResc pkgpag_tipo.rvalorpagamento;
    vVlPercentualATS      NUMBER(13, 2);
    vSgbasecalculo        VARCHAR2(10);

    vMesFolhaAnterior INTEGER;
    vAnoFolhaAnterior INTEGER;

    vdtdeslig   DATE;
    vSitPrev    INTEGER;
    vDtAdmissao DATE;

    FUNCTION fretornapercentacumats(pcdvinculo     IN INTEGER,
                                    pcdagrupamento IN INTEGER,
                                    pdtiniciomes   IN DATE,
                                    pdtfimmes      IN DATE)

     RETURN NUMBER IS

      vvlpercentats NUMBER(7, 4);

      vcdrubtrienio3 INTEGER;

      vcdrubtrienio6 INTEGER;

    BEGIN
 
      IF PKGPAG_VAR.vgpercentacumats.count > 0 THEN

      RETURN NVL(PKGPAG_VAR.vgpercentacumats(PKGPAG_VAR.vgpercentacumats.first),0);

      ELSE

        BEGIN

        vcdrubtrienio3 := PKGPAG_GERAL.fretornarubrica(pcdagrupamento, 1, 18);

        vcdrubtrienio6 := PKGPAG_GERAL.fretornarubrica(pcdagrupamento, 1, 84);

        IF PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubTrienio3) OR PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubTrienio6) THEN
            select sum(vlindice)
              into vvlpercentats
              from epaglancamentofinanceiro lf
             where LF.CdVinculo = pCdVinculo
             and LF.CdRubricaAgrupamento in (vCdRubTrienio3, vCdRubTrienio6)
               and LF.DtInicioDireito <= pdtFimMes
             and (LF.DtFimDireito >= pdtInicioMes or LF.DtFimDireito is null)
             and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                      from vpagrubricaagrupamento ra
                     where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                       and ra.flsuspensa = PKGPAG_TIPO.cnN);
          END IF;

          RETURN nvl(vvlpercentats, 0);

        EXCEPTION

          WHEN OTHERS THEN

            RETURN 0;

        END;

      END IF;

    END;

    FUNCTION fvalorbaseipesccef

     RETURN NUMBER IS

      vvlbase                  NUMBER(15, 4);
      vvlbaseProporcional      NUMBER(15, 4);
      vvlbaseProporcionalMenos NUMBER(15, 4);
      vvlbaseIntegral          NUMBER(15, 4);
      vvlbaseIntegralMenos     NUMBER(15, 4);
      vNuDiasTrab              INTEGER;
      vNuDiasMes               INTEGER;
      vVlBaseIprev             pkgpag_tipo.rValorPagamento;

    BEGIN
 
      pkgpag_param.PArmazenaInfoFolhaAuxiliar(pCdFolhaReplicada);

      vVlBaseIprev.vlIntegral := 0;

      vVlBaseIprev.vlReal := 0;

      vVlBaseIprev.vlProporcional := 0;

      begin

        select sum(case
                     when r.cdtiporubrica = 9 and r.nurubrica = 916 then -- soma
                      hrv.vlpagamento
                     when r.cdtiporubrica = 1 and r.nurubrica in (108, 180) then -- subtrai
                      -hrv.vlpagamento
                     else
                      0
                   end)
          into vVlBaseIprev.vlProporcional
          from epaghistoricorubricavinculo hrv
         inner join vpagrubricaagrupamento r
            on r.cdrubricaagrupamento = hrv.cdrubricaagrupamento
          and   (
                  (r.cdtiporubrica = 9 and  r.nurubrica = 916) or
                  (r.cdtiporubrica = 1 and  r.nurubrica in (108,180))
                )
         where hrv.cdfolhapagamento = pCdFolhaReplicada
           and hrv.cdvinculo = pCdVinculo;

        vVlBaseIprev.vlIntegral := vVlBaseIprev.vlProporcional;
        vVlBaseIprev.vlReal     := vVlBaseIprev.vlProporcional;

      exception
        when others then
          vVlBaseIprev := FRetornaValorBaseCalculo(pfolha            => PKGPAG_VAR.vgFolhaAuxiliar,
                                                   pcdvinculo        => pCDVINCULO,
                                                   pcdtipohistorico  => 2,
                                                   pcdrelacaovinculo => PKGPAG_VAR.vgRelVincPrincipal.Tipo,
                                                   pcdbasecalculo    => PKGPAG_VAR.vgrubrica(PKGPAG_VAR.vgCdRubBaseIPESC).cdbasecalculo, --vcdbasecalculo,
                                                   pcdchave          => PKGPAG_VAR.vgRelVincPrincipal.CdHist,
                                                   pCdFolhaAnt       => pCdFolhaReplicada);

      end;

      SELECT SUM(pag.vlpagamento), SUM(pag.vlpagamento)
        INTO vvlbaseProporcional, vvlbaseIntegral
        FROM epaghistoricorubricavinculo pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON R.CdRubrica = RUB.CdRubrica
         AND R.CdTipoRubrica IN (1, 2, 3, 4, 10, 12)

      -------- descobre rubricas que incidem na base do 13 salario POSITIVAMENTE
       INNER JOIN (SELECT DISTINCT rubexp.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rub
                    INNER JOIN epagbasecalculo base
                       ON base.cdbasecalculo = rub.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                       ON bv2.cdbasecalculo = base.cdbasecalculo
                      AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb
                       ON hb.cdversaobasecalculo = bv2.cdversaobasecalculo
                      and hb.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl
                       ON bl.cdhistbasecalculo = hb.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao exp
                       ON exp.cdbasecalculobloco = bl.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubexp
                       ON RUBexp.cdbasecalculoblocoexpressao =
                          exp.cdbasecalculoblocoexpressao
                    where rub.cdrubricaagrupamento =
                          PKGPAG_VAR.vgCdRubBase13Sal
                      AND (substr(deformula,
                                  instr(deformula, bl.sgbloco) - 1,
                                  1) in ('+', '=') --estão somando
                          or substr(deformula,
                                     instr(deformula, bl.sgbloco) - 2,
                                     2) in ('+(', '=('))) B
          ON B.cdrubricaagrupamento = pag.cdrubricaagrupamento
       WHERE PAG.CdVinculo = pCdVinculo
         AND PAG.CdFolhaPagamento = pFolha.CdFolhaPagamento; -- pCdFolhaReplicada;

      -------- descobre rubricas que incidem na base do 13 salario NEGATIVAMENTE
      SELECT SUM(pag.vlpagamento), SUM(pag.vlpagamento)
        INTO vvlbaseProporcionalMenos, vvlbaseIntegralMenos
        FROM epaghistoricorubricavinculo pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON R.CdRubrica = RUB.CdRubrica
         AND R.CdTipoRubrica IN (1, 2, 3, 4, 10, 12)
       INNER JOIN (SELECT DISTINCT rubexp.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rub
                    INNER JOIN epagbasecalculo base
                       ON base.cdbasecalculo = rub.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                       ON bv2.cdbasecalculo = base.cdbasecalculo
                      AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb
                       ON hb.cdversaobasecalculo = bv2.cdversaobasecalculo
                      and hb.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl
                       ON bl.cdhistbasecalculo = hb.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao exp
                       ON exp.cdbasecalculobloco = bl.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubexp
                       ON RUBexp.cdbasecalculoblocoexpressao =
                          exp.cdbasecalculoblocoexpressao
                    where rub.cdrubricaagrupamento =
                          PKGPAG_VAR.vgCdRubBase13Sal
                      AND (substr(deformula,
                                  instr(deformula, bl.sgbloco) - 1,
                                  1) in ('-', '=') --estão diminuindo
                          or substr(deformula,
                                     instr(deformula, bl.sgbloco) - 2,
                                     2) in ('-(', '=('))) B
          ON B.cdrubricaagrupamento = pag.cdrubricaagrupamento
       WHERE PAG.CdVinculo = pCdVinculo
         AND PAG.CdFolhaPagamento = pFolha.CdFolhaPagamento;

          vvlbaseProporcional := vVlBaseIprev.vlProporcional + nvl(vvlbaseProporcional,0) - nvl(vvlbaseProporcionalMenos,0);

          vvlbaseIntegral := vVlBaseIprev.vlIntegral + nvl(vvlbaseIntegral,0) - nvl(vvlbaseIntegralMenos,0);

      -- Tratar casos de admitidos no mes com direito ao 13 para integralizar o valor.
          IF PKGPAG_VAR.vgVinculo.DtAdmissao BETWEEN PKGPAG_VAR.vgFolha.DtInicioMes AND  PKGPAG_VAR.vgFolha.DtFimMes
             THEN

                 vNuDiasTrab := (to_number(TO_CHAR(PKGPAG_VAR.vgFolha.DtFimMes,'DD')) - to_number(TO_CHAR(PKGPAG_VAR.vgVinculo.DtAdmissao,'DD'))) + 1;
        vNuDiasMes  := to_number(TO_CHAR(PKGPAG_VAR.vgFolha.DtFimMes, 'DD'));

        IF vNuDiasTrab > 30 THEN
          vNuDiasTrab := 30;
        END IF;

        IF vNuDiasMes > 30 THEN
          vNuDiasMes := 30;
        END IF;

        vvlbase := (vvlbaseProporcional / vNuDiasTrab * vNuDiasMes);
      ELSE

        vvlbase := vvlbaseIntegral;

      END IF;

      RETURN vvlbase;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

    FUNCTION fvalorbaseipescapo

     RETURN NUMBER IS

      vvlbase NUMBER(15, 4);

    BEGIN
 
      SELECT SUM(pag.vlintegral)
        INTO vvlbase
        FROM epaghistoricorubricarelvinc pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
        ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
      -------- descobre rubricas que incidem na base do IPREV
       INNER JOIN (SELECT rubex.cdrubricaagrupamento
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
                  WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC ) A
          ON a.cdrubricaagrupamento = pag.cdrubricaagrupamento
      -------- descobre rubricas que incidem na base do 13 salario
       INNER JOIN (SELECT rubex2.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rubm2
                    INNER JOIN epagbasecalculo base2
                       ON base2.cdbasecalculo = rubm2.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                      ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb2
                      ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl2
                       ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao ex2
                       ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubex2
                      ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                    WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal) B
          ON b.cdrubricaagrupamento = pag.cdrubricaagrupamento
        WHERE PAG.cdVinculo = pCdVinculo AND
              PAG.CdConcessaoAposentadoria IS NOT NULL AND
              PAG.CdFolhaPagamento = PKGPAG_VAR.vgCdFolhaNormal;

      RETURN vvlbase;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

    FUNCTION fvalorbaseipescdesligado

     RETURN NUMBER IS

      vvlbaseMais     NUMBER(15, 4);
      vvlbaseMenosATS NUMBER(15, 4);

    BEGIN
 
      SELECT SUM(pag.vlintegral)
        INTO vvlbaseMais
        FROM epaghistoricorubricarelvinc pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
      -------- descobre rubricas que incidem na base do IPREV
       INNER JOIN (SELECT DISTINCT rubex.cdrubricaagrupamento
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
                    WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC13--PKGPAG_VAR.vgCdRubBaseIPESC
                      AND (substr(deformula,
                                  instr(deformula, bl.sgbloco) - 1,
                                  1) in ('+', '=') --estão Somando
                          or substr(deformula,
                                     instr(deformula, bl.sgbloco) - 2,
                                     2) in ('+(', '=('))) A
          ON a.cdrubricaagrupamento = pag.cdrubricaagrupamento
      -------- descobre rubricas que incidem na base do 13 salario
       INNER JOIN (SELECT DISTINCT rubex2.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rubm2
                    INNER JOIN epagbasecalculo base2
                       ON base2.cdbasecalculo = rubm2.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                        ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb2
                        ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl2
                       ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao ex2
                       ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubex2
                        ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                      WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal
                      AND (substr(deformula,
                                  instr(deformula, bl2.sgbloco) - 1,
                                  1) in ('+', '=') --estão Somando
                          or substr(deformula,
                                     instr(deformula, bl2.sgbloco) - 2,
                                     2) in ('+(', '=('))) B
          ON b.cdrubricaagrupamento = pag.cdrubricaagrupamento
          WHERE PAG.CdVinculo = pCdVinculo AND
                PAG.CdHistCargoEfetivo IS NOT NULL AND
                PAG.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt;


      SELECT SUM(pag.vlintegral)
        INTO vvlbaseMenosATS
        FROM epaghistoricorubricarelvinc pag
       INNER JOIN epagrubricaagrupamento rub
          ON rub.cdrubricaagrupamento = pag.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON R.CdRubrica = RUB.CdRubrica AND R.CdTipoRubrica IN (1,2,3,4,10,12)
         AND r.nurubrica IN (1252, 287)
      -------- descobre rubricas que incidem na base do IPREV
       INNER JOIN (SELECT DISTINCT rubex.cdrubricaagrupamento
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
                    WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC13 --PKGPAG_VAR.vgCdRubBaseIPESC
                      AND (substr(deformula,
                                  instr(deformula, bl.sgbloco) - 1,
                                  1) in ('-', '=') --estão Diminuindo
                          or substr(deformula,
                                     instr(deformula, bl.sgbloco) - 2,
                                     2) in ('-(', '=('))) A
          ON a.cdrubricaagrupamento = pag.cdrubricaagrupamento
      -------- descobre rubricas que incidem na base do 13 salario
       INNER JOIN (SELECT DISTINCT rubex2.cdrubricaagrupamento
                     FROM epagrubricaagrupamento rubm2
                    INNER JOIN epagbasecalculo base2
                       ON base2.cdbasecalculo = rubm2.cdbasecalculo
                    INNER JOIN epagbasecalculoversao bv2
                        ON bv2.cdbasecalculo = base2.cdbasecalculo AND bv2.nuversao = 1
                    INNER JOIN epaghistbasecalculo hb2
                        ON hb2.cdversaobasecalculo = bv2.cdversaobasecalculo and hb2.nuanofimvigencia IS NULL
                    INNER JOIN epagbasecalculobloco bl2
                       ON bl2.cdhistbasecalculo = hb2.cdhistbasecalculo
                    INNER JOIN epagbasecalculoblocoexpressao ex2
                       ON ex2.cdbasecalculobloco = bl2.cdbasecalculobloco
                    INNER JOIN epagbasecalcblocoexprrubagrup rubex2
                        ON RUBEX2.cdbasecalculoblocoexpressao = ex2.cdbasecalculoblocoexpressao
                      WHERE RUBM2.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBase13Sal
                      AND (substr(deformula,
                                  instr(deformula, bl2.sgbloco) - 1,
                                  1) in ('-', '=') --estão Diminuindo
                          or substr(deformula,
                                     instr(deformula, bl2.sgbloco) - 2,
                                     2) in ('-(', '=('))) B
          ON b.cdrubricaagrupamento = pag.cdrubricaagrupamento
          WHERE PAG.CdVinculo = pCdVinculo AND
                PAG.CdHistCargoEfetivo IS NOT NULL AND
                PAG.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt;

      vVlPercentualATS := fretornapercentacumats(pcdvinculo     => pcdvinculo,
                                                 pcdagrupamento => pfolha.cdagrupamento,
                                                 pdtiniciomes   => pfolha.dtiniciomes,
                                                 pdtfimmes      => pfolha.dtfimmes);

      RETURN vvlbaseMais - nvl((vVlPercentualATS*vvlbaseMenosATS/100),0);

    EXCEPTION

      WHEN OTHERS THEN

        RETURN 0;

    END;

  BEGIN
 
    vvlbaseipev13sal := 0;

      vvlBaseIprev13SalResc := PKGPAG_GERAL.fretornavaloroutrasrv(pcdfolhapagamento     => pFolha.CdFolhaPagamento,
                                                                  pcdvinculo            => pcdvinculo,
                                                                  pcdrubricaagrupamento => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => pFolha.CdAgrupamento,
                                                                                                                        pcdtiporubrica => 1,
                                                                                                                        pNuRubrica     => 1023));

      IF NVL(vvlBaseIprev13SalResc.vlProporcional, 0) = 0 THEN
        vvlBaseIprev13SalResc.vlProporcional := PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                                  pcdvinculo        => pcdvinculo,
                                                                                  pcdrubrica        => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                                                    pcdtiporubrica => 1,
                                                                                                                                    pNuRubrica     => 1023));
      END IF;

    -- Solicitacao de Sustentacao #77583
    -- Para a Defensoria Publica, Caso haja a rubrica 01-1023, esta assume a base do BASE-IPESC-13 09-0920
    IF nvl(vvlBaseIprev13SalResc.vlProporcional,0) > 0 AND pFolha.CdAgrupamento = 176 THEN
      RETURN vvlBaseIprev13SalResc.vlProporcional;
    END IF;

    IF PKGPAG_VAR.vgcef.count > 0 and PKGPAG_VAR.vgvinculo.dtdesligamento is null or
       PKGPAG_VAR.vgvinculo.dtdesligamento > pFolha.DtFimMes OR
       (PKGPAG_VAR.vgFolha.CdAgrupamento = 1 AND
       (pfolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoNormal AND PKGPAG_VAR.vgvinculo.dtdesligamento > pFolha.DtCalculoAnt))
        THEN

      vvlbaseipev13sal := fvalorbaseipesccef;

      --Para serv com rescisao/exoneracao no mes, na folha normal, calcula base iprev
      IF NVL(vvlbaseipev13sal, 0) = 0
        AND vvlBaseIprev13SalResc.vlProporcional > 0 -- caso possua 01-1023
        AND (pfolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoNormal AND PKGPAG_VAR.vgvinculo.dtdesligamento > pFolha.DtCalculoAnt)
         THEN

        vvlbaseipev13sal := PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamentoNormalAnt,
                                                              pcdvinculo        => pcdvinculo,
                                                              pcdrubrica        => PKGPAG_GERAL.fretornarubrica(pcdagrupamento => PKGPAG_VAR.vgFolha.CdAgrupamento,
                                                                                                                pcdtiporubrica => 9,
                                                                                                                pNuRubrica     => 916));
      END IF;

    ELSIF PKGPAG_VAR.vgapo.count > 0 THEN

      IF (PKGPAG_VAR.vgApo(1).DtInicioRelacao < pFolha.DtInicioMes OR
         (PKGPAG_VAR.vgApo(1).DtInicioRelacao >= pFolha.DtInicioMes AND
          PKGPAG_VAR.vgApo(1).DtInicioRelacao <= pFolha.DtFimMes)) THEN

        vvlbaseipev13sal := fvalorbaseipescapo;

      END IF;

    ELSIF PKGPAG_VAR.vgaposemparidade.count > 0 THEN

      IF (PKGPAG_VAR.vgAPOSemParidade(1).DtInicioRelacao < pFolha.DtInicioMes OR
         (PKGPAG_VAR.vgAPOSemParidade(1).DtInicioRelacao > pFolha.DtInicioMes AND
          PKGPAG_VAR.vgAPOSemParidade(1).DtInicioRelacao <= pFolha.DtFimMes)) THEN

        vvlbaseipev13sal := fvalorbaseipescapo;

      END IF;

    ELSIF PKGPAG_VAR.vgvinculo.dtdesligamento <= pfolha.dtfimmes THEN

      vvlbaseipev13sal := fvalorbaseipescdesligado;

    else
      null;
    END IF;

    /* necessário para zerar o valor deste mnemonico na base B0920 - INÍCIO*/
    IF PKGPAG_VAR.vgrubrica(PKGPAG_VAR.vgCdRubBaseIPESC13).cdbasecalculo is not null THEN
      SELECT bc.sgbasecalculo
        INTO vSgBaseCalculo
        FROM epagbasecalculo bc
       WHERE bc.cdbasecalculo = PKGPAG_VAR.vgrubrica(PKGPAG_VAR.vgCdRubBaseIPESC13).cdbasecalculo
         AND bc.cdagrupamento = pFolha.CdAgrupamento;
    END IF;

    vMesFolhaAnterior := CASE
                           WHEN pFolha.NuMesReferencia = 1 THEN
                            12
                           ELSE
                            pFolha.NuMesReferencia - 1
                         END;
    vAnoFolhaAnterior := CASE
                           WHEN pFolha.NuMesReferencia = 1 THEN
                            pFolha.NuAnoReferencia - 1
                           ELSE
                            pFolha.NuAnoReferencia
                         END;


    IF vSgBaseCalculo = 'B0920' AND
      ((PKGPAG_VAR.vgvinculo.dtdesligamento IS NOT NULL
      OR (PKGPAG_VAR.vgAPO.COUNT > 0 AND (PKGPAG_VAR.vgAPO(1).DtInicioRelacao >= pkgutil.PRIMEIRO_DIA_MES(pFolha.NuMesReferencia,pFolha.NuAnoReferencia) AND
      PKGPAG_VAR.vgAPO(1).DtInicioRelacao <= pkgutil.ULTIMO_DIA_MES(pFolha.NuMesReferencia,pFolha.NuAnoReferencia)))
      OR (PKGPAG_VAR.vgAPO.COUNT > 0 AND (PKGPAG_VAR.vgAPO(1).DtInicioRelacao >= pkgutil.PRIMEIRO_DIA_MES(vMesFolhaAnterior, vAnoFolhaAnterior) AND
      PKGPAG_VAR.vgAPO(1).DtInicioRelacao <= pkgutil.ULTIMO_DIA_MES(vMesFolhaAnterior, vAnoFolhaAnterior))))) THEN
      vvlbaseipev13sal := 0;
    END IF;
    /* necessário para zerar o valor deste mnemonico na base B0920 - FIM */
    RETURN vvlbaseipev13sal;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fBaseIprev13EexoMesFolha(pcdvinculo IN INTEGER,
                                    pfolha     IN pkgpag_tipo.rfolha)

   RETURN NUMBER IS

    vvlbaseiprev13sal NUMBER(13, 2) DEFAULT 0;
    vqtdiastrabmes    INTEGER DEFAULT 0;
    vDtDesligamento   DATE;

  BEGIN
 
      IF PKGPAG_VAR.vgvinculo.cdregimeprevidenciario = 2 THEN -- somente executa para regime próprio
        IF pfolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoNormal AND (PKGPAG_VAR.vgvinculo.dtdesligamento IS NOT NULL OR
          (PKGPAG_VAR.vgAPO.COUNT > 0 AND (PKGPAG_VAR.vgAPO(1).DtInicioRelacao >= pkgutil.PRIMEIRO_DIA_MES(pFolha.NuMesReferencia,pFolha.NuAnoReferencia) AND
          PKGPAG_VAR.vgAPO(1).DtInicioRelacao <= pkgutil.ULTIMO_DIA_MES(pFolha.NuMesReferencia,pFolha.NuAnoReferencia)))) THEN

        -- busca a base de iprev da folha que está sendo calculada.
        BEGIN
          SELECT SUM(HRV.VLPAGAMENTO)
            INTO vvlbaseiprev13sal
            FROM EPAGHISTORICORUBRICAVINCULO HRV
           INNER JOIN ECalFolhaPag FP
              ON FP.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
             AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
             AND FP.NUANOREFERENCIA = pfolha.NuAnoReferencia
             AND FP.NUMESREFERENCIA = pfolha.NuMesReferencia
             AND FP.FLCALCULODEFINITIVO = pfolha.FlCalculoDefinitivo
             AND FP.CDTIPOCALCULO = 1
           INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
              ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
             AND TFP.CDTIPOFOLHA = 1
           WHERE HRV.CDVINCULO = PCDVINCULO
             AND HRV.CDRUBRICAAGRUPAMENTO = PKGPAG_VAR.vgCdRubBaseIPESC;
        EXCEPTION
          WHEN no_data_found THEN
            vvlbaseiprev13sal := 0;

        END;

        -- o valor da rubrica 09-0916 é proporcional aos dias trabalhados no mês e  precisa ser transformado para valor integral
        vDtDesligamento := CASE
                                WHEN PKGPAG_VAR.vgApo.Count > 0 and
                                     PKGPAG_VAR.vgAPO(1).DtInicioRelacao IS NOT NULL THEN
                              PKGPAG_VAR.vgAPO(1).DtInicioRelacao - 1
                             ELSE
                              PKGPAG_VAR.vgvinculo.dtdesligamento
                           END;

          vqtdiastrabmes := vDtDesligamento - pkgutil.PRIMEIRO_DIA_MES(pfolha.NuMesReferencia, pfolha.NuAnoReferencia) + 1;

        IF vqtdiastrabmes > 0 THEN
          vvlbaseiprev13sal := vvlbaseiprev13sal / vqtdiastrabmes * 30;
        ELSE
          vvlbaseiprev13sal := 0;
        END IF;
      ELSE
        vvlbaseiprev13sal := 0;
      END IF;

    ELSE
      vvlbaseiprev13sal := 0;
    END IF;

    RETURN vvlbaseiprev13sal;

  EXCEPTION
    WHEN OTHERS THEN
      PKGPAG_GERAL.pinserelog(PKGPAG_VAR.blog,
                              PKGPAG_VAR.vcdhistparamcalc,
                              PKGPAG_VAR.vcdpessoa,
                                    '001 - Erro ao processar fórmula no vínculo - Rubrica: ' ||  pcdvinculo || ' - ' ||
                                  '09-0920');

  END;

  -- Servidores ativos ou aposentados(caso de óbito) exonerados em meses anteriores ao da Folha que está sendo calculada
  FUNCTION fBaseIprev13ExonMesAntFolha(pcdvinculo IN INTEGER,
                                       pfolha     IN pkgpag_tipo.rfolha)

   RETURN NUMBER IS

    vvlbaseiprev13sal NUMBER(13, 2) DEFAULT 0;
    vqtmesestrabano   INTEGER DEFAULT 0;
    vMesFolhaAnterior INTEGER;
    vAnoFolhaAnterior INTEGER;

  BEGIN
 
    IF PKGPAG_VAR.vgvinculo.cdregimeprevidenciario = 2 THEN
      -- somente executa para regime próprio
      vMesFolhaAnterior := CASE
                             WHEN pFolha.NuMesReferencia = 1 THEN
                              12
                             ELSE
                              pFolha.NuMesReferencia - 1
                           END;
      vAnoFolhaAnterior := CASE
                             WHEN pFolha.NuMesReferencia = 1 THEN
                              pFolha.NuAnoReferencia - 1
                             ELSE
                              pFolha.NuAnoReferencia
                           END;

      IF pfolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoNormal AND
         (PKGPAG_VAR.vgvinculo.dtdesligamento IS NOT NULL AND
         PKGPAG_VAR.vgvinculo.dtdesligamento < pFolha.dtiniciomes) OR
         (PKGPAG_VAR.vgAPO.COUNT > 0 AND
         (PKGPAG_VAR.vgAPO(1).DtFimRelacao IS NOT NULL OR
          (PKGPAG_VAR.vgAPO(1).DtInicioRelacao >= pkgutil.PRIMEIRO_DIA_MES(vMesFolhaAnterior, vAnoFolhaAnterior)
           AND PKGPAG_VAR.vgAPO(1).DtInicioRelacao <= pkgutil.ULTIMO_DIA_MES(vMesFolhaAnterior, vAnoFolhaAnterior))
         )) THEN

        BEGIN
          --quando for calculo de 13 sal procura na folha normal do mes, caso não encontre
          --procura na folha do mes anterior
          IF pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolha13
          AND (PKGPAG_VAR.vgAPO(1).DtInicioRelacao <= pkgutil.ULTIMO_DIA_MES(pFolha.NuMesReferencia, pFolha.NuAnoReferencia))
           THEN
            BEGIN
              SELECT SUM(HRV.VLPAGAMENTO)
                INTO vvlbaseiprev13sal
                FROM EPAGHISTORICORUBRICAVINCULO HRV
               INNER JOIN ECalFolhaPag FP
                  ON FP.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
                 AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                 AND FP.NUANOREFERENCIA = CASE
                       WHEN (pfolha.NuMesReferencia = 1) THEN
                        pfolha.NuAnoReferencia - 1
                       ELSE
                        pfolha.NuAnoReferencia
                     END
                 AND FP.NUMESREFERENCIA = CASE
                       WHEN (pfolha.NuMesReferencia = 1) THEN
                        12
                       ELSE
                        pfolha.NuMesReferencia
                     END
                 AND ((pFolha.FlCalculoDefinitivo = pkgpag_tipo.cnS AND FP.FLCALCULODEFINITIVO = pkgpag_tipo.cnS)
                      OR FP.FLCALCULODEFINITIVO IN (pkgpag_tipo.cnS, pkgpag_tipo.cnN))
                 AND FP.CDTIPOCALCULO = 1
               INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
                  ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
                 AND TFP.CDTIPOFOLHA = 1
               WHERE HRV.CDVINCULO = PCDVINCULO
                 AND HRV.CDRUBRICAAGRUPAMENTO = PKGPAG_VAR.vgCdRubBaseIPESC;

            EXCEPTION
              WHEN OTHERS THEN
                BEGIN
                  SELECT SUM(HRV.VLPAGAMENTO)
                    INTO vvlbaseiprev13sal
                    FROM EPAGHISTORICORUBRICAVINCULO HRV
                   INNER JOIN ECalFolhaPag FP
                      ON FP.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
                     AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                     AND FP.NUANOREFERENCIA = CASE
                           WHEN (pfolha.NuMesReferencia = 1) THEN
                            pfolha.NuAnoReferencia - 1
                           ELSE
                            pfolha.NuAnoReferencia
                         END
                     AND FP.NUMESREFERENCIA = CASE
                           WHEN (pfolha.NuMesReferencia = 1) THEN
                            12
                           ELSE
                            pfolha.NuMesReferencia - 1
                         END
                     AND FP.FLCALCULODEFINITIVO = pkgpag_tipo.cnS
                     AND FP.CDTIPOCALCULO = 1
                   INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
                      ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
                     AND TFP.CDTIPOFOLHA = 1
                   WHERE HRV.CDVINCULO = PCDVINCULO
                     AND HRV.CDRUBRICAAGRUPAMENTO =
                         PKGPAG_VAR.vgCdRubBaseIPESC;
                EXCEPTION
                  WHEN no_data_found THEN
                    vvlbaseiprev13sal := 0;
                END;
            END;
          ELSE
            SELECT SUM(HRV.VLPAGAMENTO)
              INTO vvlbaseiprev13sal
              FROM EPAGHISTORICORUBRICAVINCULO HRV
             INNER JOIN ECalFolhaPag FP
                ON FP.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
               AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
               AND FP.NUANOREFERENCIA = CASE
                     WHEN (pfolha.NuMesReferencia = 1) THEN
                      pfolha.NuAnoReferencia - 1
                     ELSE
                      pfolha.NuAnoReferencia
                   END
               AND FP.NUMESREFERENCIA = CASE
                     WHEN (pfolha.NuMesReferencia = 1) THEN
                      12
                     ELSE
                      pfolha.NuMesReferencia - 1
                   END
               AND FP.FLCALCULODEFINITIVO = pkgpag_tipo.cnS
               AND FP.CDTIPOCALCULO = 1
             INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
                ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
               AND TFP.CDTIPOFOLHA = 1
             WHERE HRV.CDVINCULO = PCDVINCULO
               AND HRV.CDRUBRICAAGRUPAMENTO = PKGPAG_VAR.vgCdRubBaseIPESC;
          END IF;
        EXCEPTION
          WHEN no_data_found THEN
            vvlbaseiprev13sal := 0;

        END;

      ELSE
        vvlbaseiprev13sal := 0;
      END IF;
    ELSE
      vvlbaseiprev13sal := 0;
    END IF;

    RETURN vvlbaseiprev13sal;

  EXCEPTION
    WHEN OTHERS THEN
      PKGPAG_GERAL.pinserelog(PKGPAG_VAR.blog,
                              PKGPAG_VAR.vcdhistparamcalc,
                              PKGPAG_VAR.vcdpessoa,
                                '002 - Erro ao processar fórmula no vínculo - Rubrica: ' ||  pcdvinculo || ' - ' ||
                                '09-0920');


  END;

  FUNCTION fconvBaseIprev13pIntegral(pcdvinculo IN INTEGER,
                                     pfolha     IN pkgpag_tipo.rfolha)
    RETURN NUMBER IS

    --cAfastamento types.ref_cursor;
    --vNmTabela    VARCHAR2(50);
    --vNmColuna    VARCHAR2(50);
    --vChaves      VARCHAR2(500);

    --vqtdiastrabmes INTEGER;
    vqtmesestrabano   INTEGER;
    vvlFatorConversao number(15, 2);
    vqtddiasafames    INTEGER;

    --vSql VARCHAR2(500);
    --vDtInicioAfast DATE;
    --vDtFimAfast DATE;

  BEGIN
 
    vqtddiasafames := 0;

    -- Tratar afastados no mês, onde o valor da base 09-0916 deve ser desproporcionalizado
    -- SIG-2825
    -- Verifica se ha afastamentos vigentes no periodo, ligados a acidente de trabalho

    BEGIN
      FOR vAfa IN (
                  SELECT av.dtinicio, av.dtfim
                     FROM eafaafastamentovinculo av
                    INNER JOIN eafahistmotivoafasttemp HMAT
                         ON hmat.CDMOTIVOAFASTTEMPORARIO = av.CDMOTIVOAFASTTEMPORARIO
                      and hmat.FLREMUNERADO = 'N'
                      and hmat.flanulado = 'N'
                    WHERE av.cdvinculo = pcdvinculo
                     AND av.flanulado = 'N' )
          LOOP

        IF vAfa.Dtinicio < PKGPAG_VAR.vgFolha.DtInicioMes THEN
          vAfa.Dtinicio := PKGPAG_VAR.vgFolha.DtInicioMes;
        END IF;

        vqtddiasafames := vqtddiasafames + (vAfa.Dtfim - vAfa.Dtinicio + 1);

      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        vqtddiasafames := 0;
    END;

    IF vqtddiasafames > 0 THEN
      /*vqtdiastrabmes := CASE
                        WHEN PKGPAG_VAR.vgFolha.NuMesReferencia = 2 THEN
                          to_char(PKGPAG_VAR.vgFolha.DtFimMes,'DD') - vqtddiasafames  -- substituir por valor obtido pela busca de afastamento no mês
                        ELSE
                          30 - vqtddiasafames -- substituir por valor obtido pela busca de afastamento no mês
                        END  ;
      */
      vqtmesestrabano := fmneqtmesestrabano(pfolha,
                                            pcdvinculo,
                                            PKGPAG_VAR.vgvinculo.DtAdmissao,
                                            PKGPAG_VAR.vgvinculo.DtDesligamento,
                                            pfolha.DtCalculo,
                                            'N',
                                            'N',
                                            'N');


      vvlFatorConversao :=  /*30 / vqtdiastrabmes  / 12 * */ vqtmesestrabano;
    ELSE
      vvlFatorConversao := 1;
    END IF;

    RETURN vvlFatorConversao;

  END;

  -- N?mero de meses transcorridos no periodo aquisitivo previsto

  FUNCTION fmesestransperaquisprev(pcdvinculo           IN INTEGER,
                                   pdtiniciomes         IN DATE,
                                   pdtfimmes            IN DATE,
                                   pcdmodalidaderubrica IN INTEGER)

   RETURN INTEGER IS

    vnumesaux INTEGER;

    vdtfimmes DATE;

    vdtinicioperiodo DATE;

  BEGIN
 
    IF pcdmodalidaderubrica = 53 THEN

      vdtfimmes := pdtfimmes;

    ELSIF pcdmodalidaderubrica = 54 THEN

      vdtfimmes := last_day(trunc(pdtiniciomes - 1, 'MM'));

    else
      null;
    END IF;

    -- Per?odos previstos

    SELECT pf.dtinicio
      INTO vdtinicioperiodo
      FROM emovperiodoaquisitivoferias pf
     WHERE PF.CdVinculo = pCdVinculo AND
           PF.DtFim > vDtFimMes AND PF.DtInicio < vDtFimMes;

    SELECT COUNT(*)
      INTO vnumesaux
      FROM (SELECT to_char(dtdia, 'YYYYMM') AS mes, COUNT(*) AS nudias
              FROM (SELECT vdtinicioperiodo + (LEVEL - 1) AS dtdia
                      FROM dual
                   CONNECT BY vDtInicioPeriodo + (LEVEL - 1)
                   BETWEEN vDtInicioPeriodo AND vDtFimMes) X
             GROUP BY to_char(dtdia, 'YYYYMM')) a
     WHERE nudias >= 15;

    RETURN vnumesaux;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fmnechoproporcional(prubrica          IN pkgpag_tipo.rrubrica,
                               pcdrelacaovinculo IN INTEGER,
                               pcdchave          IN INTEGER)

   RETURN NUMBER IS

  BEGIN
 
    IF PKGPAG_VAR.vgvalorfixocef.nucargahoraria > 0 THEN

     IF pCdRelacaoVinculo = 1 THEN -- Efetivo

        IF PKGPAG_VAR.vgcef.first IS NOT NULL THEN

         FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
         LOOP

            IF PKGPAG_VAR.vgcef(i).cdhistrelvinc = pcdchave THEN

              IF prubrica.lsloccho.first IS NOT NULL THEN

                IF pRubrica.lsLocCHO.EXISTS(PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional) THEN

                  RETURN 1;

                END IF;

              END IF;

             IF PKGPAG_VAR.vgCEF(i).NuCargaHoraria > PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

                RETURN 1;

              END IF;

              RETURN PKGPAG_VAR.vgcef(i).nucargahoraria / PKGPAG_VAR.vgvalorfixocef.nucargahoraria;

            END IF;

          END LOOP;

        END IF;

     ELSIF pCdRelacaoVinculo = 4 THEN -- Aposentado

        IF PKGPAG_VAR.vgapo.first IS NOT NULL THEN

         FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
         LOOP

            IF PKGPAG_VAR.vgapo(i).cdhistrelvinc = pcdchave THEN

              IF prubrica.lsloccho.first IS NOT NULL THEN

                IF pRubrica.lsLocCHO.EXISTS(PKGPAG_VAR.vgAPO(i).CdUnidadeOrganizacional) THEN

                  RETURN 1;

                END IF;

              END IF;

            END IF;

            IF PKGPAG_VAR.vgAPO(i).NuCargaHoraria > PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria THEN

              RETURN 1;

            END IF;

            RETURN PKGPAG_VAR.vgapo(i).nucargahoraria / PKGPAG_VAR.vgvalorfixocef.nucargahoraria;

          END LOOP;

        END IF;

      else
        null;
      END IF;

    END IF;

    RETURN 0;

  END;

  -- Dias n?o usufruidos dos per?odos conquistados

  FUNCTION fdiasnaousufridosperconqat(pcdvinculo   IN INTEGER,
                                      pdtiniciomes IN DATE,
                                      pdtfimmes    IN DATE)

   RETURN INTEGER IS

    vnusaldodias INTEGER;

    vnudiasabonado INTEGER;

  BEGIN
 
    vnusaldodias := 0;

    FOR vperiodo IN (SELECT pf.cdperiodoaquisitivoferias,
                            pf.nudiasferiasconcedido,
                            pf.nudiasferiasabonado,
                            pf.dtinicio
                       FROM emovperiodoaquisitivoferias pf
                   WHERE PF.CdVinculo = pCdVinculo AND
                         PF.CdSituacaoPeriodoAqFerias = PKGPAG_TIPO.cn2 AND -- conquistado
                           -- O per?odo conquistado no mes n?o deve ser considerado na contagem
                         PF.DtFim <= pDtFimMes AND
                         NOT EXISTS (SELECT 1
                               FROM emovferiasfruicaousufruto ffu
                                      WHERE FFU.CdPeriodoAquisitivoFerias = PF.CdPeriodoAquisitivoFerias AND
                                            FFU.FlAnulado = PKGPAG_TIPO.cnN AND
                                            FFU.DtInicial < pDtInicioMes))
  LOOP

      vnusaldodias := vnusaldodias + vperiodo.nudiasferiasconcedido;

      vnudiasabonado := vperiodo.nudiasferiasabonado;

      FOR vperaquis IN (SELECT ffu.insituacao,
                               SUM(ffu.dtfinal - ffu.dtinicial + 1) AS nudiasusufruidos
                          FROM emovferiasfruicaousufruto ffu
                        WHERE FFU.CdPeriodoAquisitivoFerias = vPeriodo.CdPeriodoAquisitivoFerias AND
                              FFU.FlAnulado = 'N' AND
                              FFU.InSituacao IN (1, 2, 7, 8, 11) AND -- 1 - Normal / Interrompido 7 - definitivamente - 8 Temporariamente
                               ffu.dtinicial < pdtiniciomes
                         GROUP BY ffu.insituacao)

       LOOP

      vNuSaldoDias := vNuSaldoDias - vPerAquis.NuDiasUsufruidos  - vNuDiasAbonado;

        vnudiasabonado := 0;

      END LOOP;

    END LOOP;

    RETURN vnusaldodias;

  END;

  FUNCTION fdiasnaousufridosperconqan(pcdvinculo       IN INTEGER,
                                      pnuanoreferencia IN INTEGER,
                                      pnumesreferencia IN INTEGER)

   RETURN INTEGER IS

    vnuanoreferencia INTEGER;

    vnumesreferencia INTEGER;

    vdtiniciomes DATE;

    vdtfimmes DATE;

    vdiasusu NUMBER(5, 2);

    vnusaldodias NUMBER(5, 2);

  BEGIN
 
    vnusaldodias := 0;

    IF pnumesreferencia = 1 THEN

      vnumesreferencia := 12;

      vnuanoreferencia := pnuanoreferencia - 1;

    ELSE

      vnumesreferencia := pnumesreferencia - 1;

      vnuanoreferencia := pnuanoreferencia;

    END IF;

   vDtInicioMes := TO_DATE(vNuAnoReferencia || LPAD(vNuMesReferencia, 2,'0')||'01','YYYYMMDD');

    vdtfimmes := last_day(vdtiniciomes);

    FOR vperaquisferias IN (SELECT pf.cdperiodoaquisitivoferias, pf.NuDiasFeriasAbonado, pf.NuDiasFeriasConcedido
                              FROM emovperiodoaquisitivoferias pf
                            WHERE PF.CdVinculo = pCdVinculo AND
                                  PF.CdSituacaoPeriodoAqFerias = PKGPAG_TIPO.cn2 AND
                                  PF.DtFim <= vDtFimMes
                            ORDER BY PF.DtInicio DESC)
   LOOP

      vdiasusu := 0;

      --> Conquistado antes do in?cio do mes anterior

      FOR vfruicao IN (SELECT ffu.insituacao,
                              SUM(ffu.dtfinal - ffu.dtinicial + 1) AS nudias
                         FROM emovferiasfruicaousufruto ffu
                          WHERE FFU.CdPeriodoAquisitivoFerias = vPerAquisFerias.CdPeriodoAquisitivoFerias AND
                                FFU.FlAnulado = PKGPAG_TIPO.cnN AND
                                FFU.InSituacao IN (1, 2, 3, 7, 8, 11) AND
                             -- 1 - Normal / Interrompido 7 - definitivamente - 8 Temporariamente - 11 Alterado
                              ffu.dtinicial < vdtiniciomes
                        GROUP BY ffu.insituacao)

       LOOP

        vdiasusu := vdiasusu + nvl(vfruicao.nudias, 0);

      END LOOP;

      --

      vDiasUsu := vDiasUsu + (CASE WHEN vDiasUsu > 0 THEN NVL(vPerAquisFerias.NuDiasFeriasAbonado,0) ELSE 0 END);

      IF vdiasusu > 30 THEN

        vdiasusu := 30;

      END IF;

      vnusaldodias := vnusaldodias +

          (NVL(vPerAquisFerias.NuDiasFeriasConcedido,0) - vDiasUsu);

      --

      IF nvl(vnusaldodias, 0) > 0 THEN

        NULL;

      ELSE

        RETURN vnusaldodias;

      END IF;

    END LOOP;

    RETURN vnusaldodias;

  END;

  FUNCTION fqtdiasferiasnomes(pcdvinculo   IN INTEGER,
                              pdtiniciomes IN DATE,
                              pdtfimmes    IN DATE)

   RETURN INTEGER IS

    vnudias INTEGER;

    vnudiasabonado INTEGER;

    vcdperiodoaquisitivoferias INTEGER;

  BEGIN
 
    SELECT pf.cdperiodoaquisitivoferias,
           pf.nudiasferiasabonado,
           SUM(ffu.dtfinal - ffu.dtinicial + 1)
      INTO vCdPeriodoAquisitivoFerias,
           vNuDiasAbonado,
           vNuDias
      FROM emovferiasfruicaousufruto ffu
     INNER JOIN emovperiodoaquisitivoferias pf
        ON ffu.cdperiodoaquisitivoferias = pf.cdperiodoaquisitivoferias
     WHERE FFU.InSituacao IN (1,7,8,11) AND
           PF.CdVinculo = pCdVinculo AND
           PF.CdSituacaoPeriodoAqFerias = 2 AND
           FFU.DtInicial BETWEEN pdtInicioMes AND pdtFimMes
     GROUP BY pf.cdperiodoaquisitivoferias, pf.nudiasferiasabonado;

    IF NOT PKGPAG_GERAL.FPossuiInterrupcaoUsufruto(vCdPeriodoAquisitivoFerias,
                                                   pDtInicioMes,
                                                   pDtFimMes) THEN

      RETURN nvl(vnudias, 0) + nvl(vnudiasabonado, 0);

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  --
  -- Contar dias uteis de um periodo.
  -- Na passagem de parametros informar o dia do final de semana a desconsiderar. NULL = sabado e domingo
  -- 1-Domingo; 7-Sabado
  -- O tipo de retorno e definido na chamada

  FUNCTION fQtTipoDiasPeriodo(P_DATA_INICIAL     IN DATE,
                              P_DATA_FINAL       IN DATE,
                              p_dia_final_semama IN NUMBER DEFAULT 0, -- Quando NULL considera sabado e domingo, 1=Domingo, 7=Sabado
                              p_tipo_retorno     IN NUMBER,
                              p_cdunid           IN NUMBER DEFAULT NULL) -- 1-Dias uteis; 2-Feriados; 3-Domingos; 4-Sabados

   RETURN NUMBER

   IS

    v_dia_semana NUMBER(10) := 0;
    v_dias_uteis NUMBER(10) := 0;
    v_sabado     NUMBER(10) := 0;
    v_domingo    NUMBER(10) := 0;
    v_feriado    NUMBER(10) := 0;
    v_dia        DATE := p_data_inicial;
    v_tipo_dia   CHAR;
    v_conta      NUMBER;
    v_cdlocal    NUMBER;

  BEGIN
 
     IF p_cdunid is not null
       THEN
      SELECT lo.CdLocalidade
        INTO v_cdlocal
        FROM VCADUNIDADEORGANIZACIONAL UO
        LEFT JOIN ECADENDERECO E
          ON UO.CDENDERECO = E.CDENDERECO
        LEFT JOIN ecadLocalidade lo
          on e.cdLocalidade = lo.cdLocalidade
       WHERE UO.CDUNIDADEORGANIZACIONAL = p_cdunid;
    END IF;

     WHILE (v_dia <= P_DATA_FINAL)
     LOOP

      v_dia_Semana := to_number(TO_char(v_dia, 'D'));

      v_tipo_dia := pkgmov.FTIPODIA(PCDORGAO  => PKGPAG_VAR.vgFolha.CdOrgao,
                                    PDTDIA    => v_dia,
                                    PFLREGIME => 'J');

        IF v_tipo_dia not in ('S','D')
          then

        v_conta := PKGMOV.FQtDiaUtilLocalidade(PKGPAG_VAR.vgFolha.CdAgrupamento,
                                               PKGPAG_VAR.vgfolha.CdOrgao,
                                               p_cdunid,
                                               v_dia,
                                               v_dia,
                                                 0,'N', v_cdlocal);
             IF v_conta = 0
               THEN

          v_tipo_dia := 'F';

        END IF;
      END IF;

        IF v_tipo_dia = 'S'
          THEN
        v_sabado := v_sabado + 1;

              v_conta := fIndicaFeriado(PKGPAG_VAR.vgFolha.CdAgrupamento,PKGPAG_VAR.vgfolha.CdOrgao,v_dia, p_cdunid, v_cdlocal);

              IF v_conta = 1
               THEN

          v_feriado := v_feriado + 1;

        END IF;

        ELSIF v_tipo_dia = 'D'
          THEN
        v_domingo := v_domingo + 1;

        ELSIF v_tipo_dia = 'F'
          THEN
        v_feriado := v_feriado + 1;
      ELSE

        v_dias_uteis := v_dias_uteis + 1;

      END IF;

      v_dia := v_dia + 1;

    END LOOP;

    --
    -- Soma feriados aos dias uteis para separar na formula
    --
    v_dias_uteis := v_dias_uteis + v_feriado;

    IF p_tipo_retorno = 1

     THEN

         IF p_dia_final_semama <> 0
           THEN

        IF p_dia_final_semama = 1 -- Domingo
         THEN
          v_dias_uteis := v_dias_uteis + v_sabado;
        ELSE
          v_dias_uteis := v_dias_uteis + v_domingo;
        END IF;

      END IF;

      RETURN v_dias_uteis;

    ELSIF p_tipo_retorno = 2

     THEN

      RETURN v_feriado;

    ELSIF p_tipo_retorno = 3

     THEN

      RETURN v_domingo;

    ELSIF p_tipo_retorno = 4

     THEN

      RETURN v_sabado;

    else
      null;
    END IF;

  END;

  FUNCTION fmnealiquotafgts

   RETURN NUMBER IS

  BEGIN
 
  IF PKGPAG_VAR.vgCEF.COUNT > 0 AND
    PKGPAG_VAR.vgCEF(1).CdRelacaoTrabalho = 18 AND
       PKGPAG_VAR.vgFgtsJa IS NOT NULL THEN

      RETURN PKGPAG_VAR.vgfgtsja;

    ELSE

      RETURN PKGPAG_VAR.vgparampagamento.vlpercsobrebasefgts;

    END IF;

  END;

  FUNCTION fmneinsssobreferias

   RETURN NUMBER IS

  BEGIN
 
    RETURN PKGPAG_VAR.vgparamorgao.vlpercentualinsspatronal +

           (PKGPAG_VAR.vgParamOrgao.NuAliquotaRAT*PKGPAG_VAR.vgParamOrgao.VlAliquotaFAP) +
           NVL(PKGPAG_VAR.vgParamOrgao.VlAliquotaTerceiros,0);

  END;

   FUNCTION fmneAliquotaProgressivaINSS(lFaixa      IN PKGPAG_TIPO.tFaixaAliquota,
                                        lVlBaseINSS in number,
                                        lVlContribuicao out number)
     return number is

     vVlAliquota number(10, 4);

     vVlBaseProgressiva number := 0;

     vVlBaseInss number;

     ind integer;

   begin
 
        vVlBaseInss := NVL(PKGPAG_GERAL.fretornavalorrubrica(PKGPAG_VAR.vgFolha.CdFolhapagamento,
                                                             PKGPAG_VAR.vgVinculo.CdVinculo,
                                                             lVlBaseINSS),0);

        vVlBaseINSS := least(vVlBaseINSS, PKGPAG_VAR.vAliqINSS.vlTeto);

        lVlContribuicao := 0;

        for i in lFaixa.First .. lFaixa.Last

         LOOP

          if vVlBaseINSS >= lFaixa(i).vlInicial THEN

            if vVlBaseINSS > lFaixa(i).vlFinal then

              if i > lFaixa.First then

                vVlBaseProgressiva := lFaixa(i).vlFinal - lFaixa(i - 1).vlFinal;

              else

                vVlBaseProgressiva := lFaixa(i).vlFinal;

              end if;

            else
              if i > 1 then
                vVlBaseProgressiva := vVlBaseINSS - lFaixa(i - 1).vlFinal;

              else
                vVlBaseProgressiva := vVlBaseINSS;
              end if;

            end if;

            if vVlBaseProgressiva > lFaixa(lFaixa.LAST).VlFinal then

              vVlBaseProgressiva := lFaixa(lFaixa.LAST).VlFinal - lFaixa(lFaixa.LAST - 1).VlFinal;

            end if;

            lvlContribuicao := lVlContribuicao + trunc((vVlBaseProgressiva * lFaixa(i).VlAliquota / 100),
                                                       2);

          end if;

          if i = lFaixa.Last then

             vVlAliquota := round(lVlContribuicao /
                             least(vVlBaseINSS, lFaixa(lFaixa.LAST).VlFinal) * 100,4);

             return vVlAliquota;

          end if;

        END LOOP;

     exception
       when others
         then PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                      PKGPAG_VAR.vCdHistParamCalc,
                                      PKGPAG_VAR.vCdPessoa,
                                      'Erro ao processar MNEMONICO PKGPAG_FB.FMNEALIQUOTRAPROGRESSIVAINSS: ' ||
                                      SQLERRM,
                                      PKGPAG_VAR.vgCdVinculo);
         return 0;

  END;

  --------------------------------------------------------------------------------------------------------------
  -- Mnemonico que retorne o percentual de INSS Patronal, dado o tipo de relacao de trabalho e o risco associado
  -- a atividade exercida pelo servidor, quando este existir.
  --------------------------------------------------------------------------------------------------------------

  FUNCTION fmneinsspatronal(pCdUnidadeOrganizacional IN INTEGER DEFAULT NULL)

   RETURN NUMBER IS

    vVlPercentualINSSPatronalUo NUMBER(7, 4);
    vVlAliquotaTerceirosUo      NUMBER(6, 4);
    vNuAliqotaRatUo             NUMBER(3, 1);
    vVlAliquotaFapUo            NUMBER(6, 4);

  BEGIN
 
    IF pCdUnidadeOrganizacional IS NOT NULL
      THEN

      BEGIN

        SELECT nualiquotarat,
               vlpercentualinsspatronal,
               vlaliquotafap,
               vlaliquotaterceiros
          INTO vNuAliqotaRatUo,
               vVlPercentualINSSPatronalUo,
               vVlAliquotaFapUo,
               vVlAliquotaTerceirosUo
          FROM (SELECT nvl(huo.nualiquotarat, connect_by_root(huo.nualiquotarat)) nualiquotarat,
                       nvl(huo.vlpercentualinsspatronal, connect_by_root(huo.vlpercentualinsspatronal)) vlpercentualinsspatronal,
                       nvl(huo.vlaliquotafap, connect_by_root(huo.vlaliquotafap)) vlaliquotafap,
                       nvl(huo.vlaliquotaterceiros, connect_by_root(huo.vlaliquotaterceiros)) vlaliquotaterceiros,
                       ROWNUM AS o_num,
                       ROW_NUMBER() OVER(PARTITION BY huo.cdunidadeorganizacional ORDER BY ROWNUM) AS r_num,
                       huo.cdunidadeorganizacional
                  FROM (select huo.cdunidadeorganizacional, huo.nucnpj, huo.cduosuphierarq, huo.nualiquotarat
                             , huo.vlpercentualinsspatronal, huo.vlaliquotafap, huo.vlaliquotaterceiros
                          from ECADHISTUNIDADEORGANIZACIONAL HUO
                         where HUO.CDORGAO = PKGPAG_VAR.vgFolha.CdOrgao
                           and HUO.DTINICIOVIGENCIA <= PKGPAG_VAR.vgFolha.DtCalculo
                           and (HUO.DTFIMVIGENCIA is null or HUO.DTFIMVIGENCIA >= PKGPAG_VAR.vgFolha.DtCalculo)) huo
                 START WITH huo.nucnpj IS NOT NULL
                CONNECT BY PRIOR huo.cdunidadeorganizacional = huo.cduosuphierarq)
         WHERE r_num = 1
           AND cdunidadeorganizacional = pCdUnidadeOrganizacional
         ORDER BY o_num;

      EXCEPTION

          WHEN NO_DATA_FOUND
            THEN
          vNuAliqotaRatUo             := NULL;
          vVlPercentualINSSPatronalUo := NULL;
          vVlAliquotaFapUo            := NULL;
          vVlAliquotaTerceirosUo      := NULL;

          WHEN OTHERS
             THEN
          vNuAliqotaRatUo             := NULL;
          vVlPercentualINSSPatronalUo := NULL;
          vVlAliquotaFapUo            := NULL;
          vVlAliquotaTerceirosUo      := NULL;

      END;

    END IF;
    --
    -- Solicitacao de Sustentacao #70248
    -- 8804/2016 - FOLHA - - BASE DO INSS DO JETON -- Regime de trabalho - Contribuinte individual
    --
    IF PKGPAG_VAR.vgVinculo.CdRegimeTrabalho = 6 OR
     (PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento in (13,15)
      AND PKGPAG_VAR.vgFolha.CdTipoOrgao in (1,5))
    THEN
      RETURN nvl(vVlPercentualINSSPatronalUo, nvl(PKGPAG_VAR.vgparamorgao.vlpercentualinsspatronal, 0));

    ELSE
     RETURN nvl(vVlPercentualINSSPatronalUo, NVL(PKGPAG_VAR.vgParamOrgao.VlPercentualINSSPatronal,0)) +
            nvl(vVlAliquotaTerceirosUo, NVL(PKGPAG_VAR.vgParamOrgao.VlAliquotaTerceiros,0)) +
            (nvl(vNuAliqotaRatUo, NVL(PKGPAG_VAR.vgParamOrgao.NuAliquotaRAT,0)) * NVL(PKGPAG_VAR.vgParamOrgao.VlAliquotaFAP,0));
    END IF;
  END;

  FUNCTION FQtDiasRelVinc( pDtInicio IN DATE,
                         pDtFim    IN DATE)
  RETURN INTEGER IS

  BEGIN
 
    IF to_char(pdtinicio, 'MM') <> 2 THEN

      IF trunc(pdtfim - pdtinicio) + 1 > 30 THEN

        RETURN 30;

      ELSE

        RETURN trunc(pdtfim - pdtinicio) + 1;

      END IF;

    ELSE

    IF (pDtInicio > TRUNC(pdtInicio,'MM') OR pDtFim < LAST_DAY(pDtInicio)) THEN

        IF pdtfim = last_day(pdtinicio) THEN

          RETURN TRUNC(pdtFim - pDtInicio) + 1
              +  (30 - TO_NUMBER(TO_CHAR(LAST_DAY(pDtInicio),'DD') ) )  ;
        ELSE

          RETURN trunc(pdtfim - pdtinicio) + 1;

        END IF;

      ELSE

        RETURN 30;

      END IF;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fmneref(pcdvalorreferencia IN INTEGER)

   RETURN NUMBER IS

    vVlTetoRemExe NUMBER;

    FUNCTION fvalorreferenciacarreira(pcdestruturacarreira IN INTEGER)

     RETURN NUMBER IS

      vcdestrutura INTEGER;
    BEGIN
 
      vcdestrutura := PKGPAG_GERAL.fexistecarreira(pcdestruturacarreira);

      WHILE vcdestrutura IS NOT NULL LOOP

        IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).lsValRefCarreira.EXISTS(vCdEstrutura) THEN

          RETURN PKGPAG_VAR.vgvalorreferencia(pcdvalorreferencia).lsvalrefcarreira(vcdestrutura);

        END IF;

        vcdestrutura := PKGPAG_GERAL.fproxcarreira(vcdestrutura);

      END LOOP;

      RETURN PKGPAG_VAR.vgvalorreferencia(pcdvalorreferencia).vlreferencia;

    END;

  BEGIN
 
    -- SIG-6849
    -- Rubrica 01-1327 COMPLEMENTO PISO MAGISTERIO - 2021
    IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).SGvalorreferencia = 'CR PEC N1'
      THEN
      BEGIN
        IF PKGPAG_VAR.vgCEF.COUNT > 0 THEN
          RETURN PKGPAG_VAR.vgVlCRPECN(PKGPAG_VAR.vgCEF(1).NuNivelPagamento);

        ELSE
          RETURN PKGPAG_VAR.vgVlCRPECN(PKGPAG_VAR.VGAPO(1).NuNivelPagamento);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          RETURN 0;
      END;
    END IF;

    IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).FlValeTransporte = 'S' THEN

      bcalcindvt := TRUE;

      vvlValTransporte := PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).VlReferencia;

    ELSE

      --- Busca o valor do Bloqueio de Remunerac?o - Teto

      IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).FlBloqueioRemuneracao = 'S' THEN

        IF PKGPAG_VAR.vgvlreftetodecjud IS NOT NULL THEN

          RETURN PKGPAG_VAR.vgvlreftetodecjud;

        ELSIF PKGPAG_VAR.vgcdvalreftetodecjud IS NOT NULL THEN

          RETURN PKGPAG_VAR.vgvalorreferencia(PKGPAG_VAR.vgcdvalreftetodecjud).vlreferencia;

        else
          null;
        END IF;

      END IF;

    END IF;

    IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).lsValRefCarreira.COUNT > 0 THEN

      IF PKGPAG_VAR.vgcef.count > 0 THEN

        RETURN FValorReferenciaCarreira(pCdEstruturaCarreira => PKGPAG_VAR.vgCEF(1).CdEstruturaCarreira);

      ELSIF PKGPAG_VAR.vgapo.count > 0 THEN

        RETURN FValorReferenciaCarreira(pCdEstruturaCarreira => PKGPAG_VAR.vgAPO(1).CdEstruturaCarreira);

      else
        null;
      END IF;

    END IF;

    IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).lsValRefPrograma.COUNT > 0 THEN

      IF PKGPAG_VAR.vgbol.count > 0 THEN

        IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).lsValRefPrograma.EXISTS(PKGPAG_VAR.vgBOL(1).CdPrograma) THEN

          vvlValTransporte := PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).lsValRefPrograma(PKGPAG_VAR.vgBOL(1).CdPrograma);

          RETURN PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).lsValRefPrograma(PKGPAG_VAR.vgBOL(1).CdPrograma);

        END IF;

      END IF;

    END IF;

    -- 10548/2017 - PENSAO - ADAPTAR O MNEUMONICO VLTETOINSTITUIDOR
    -- ADAPTAR O MNEUMONICO VLTETOINSTITUIDOR PARA A ROTINA DE VALOR DE REFERENCIA TETOREMEXE.
    IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).SGvalorreferencia = 'TETOREMEXE' AND
       PKGPAG_VAR.vgFolha.CdAgrupamento = 132
      THEN

      vVlTetoRemExe := pkgpag_pensaoprevidenciaria.fvltetoinstituidor(pcdvinculopensionista => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                              panomesreferencia => PKGPAG_VAR.vgFolha.nuanoreferencia*100+PKGPAG_VAR.vgfolha.numesreferencia,
                                                                      pcdtipocalculo        => PKGPAG_VAR.vgFolha.cdtipocalculo);
      IF vVlTetoRemExe > 0 THEN
        RETURN vVlTetoRemExe;
      END IF;

    END IF;

    -- TETO DE ABATIMENTO SCPREV 12%
    IF PKGPAG_VAR.vgValorReferencia(pCdValorReferencia).SGvalorreferencia = 'TETOIR12' THEN

       if PKGPAG_VAR.vgFolha.CdTipoFolha in (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaAdiant13) then

        RETURN PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.cdfolhapagamento,
                                                 pcdvinculo        => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                   pcdrubrica => PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,9909))*
                                                                 PKGPAG_VAR.vgvalorreferencia(pcdvalorreferencia).vlreferencia/100;
      else

        RETURN PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.cdfolhapagamento,
                                                 pcdvinculo        => PKGPAG_VAR.vgVinculo.cdvinculo,
                                                   pcdrubrica => PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,9908))*
                                                                 PKGPAG_VAR.vgvalorreferencia(pcdvalorreferencia).vlreferencia/100;

      end if;

    END IF;

    RETURN PKGPAG_VAR.vgvalorreferencia(pcdvalorreferencia).vlreferencia;

  END;

  FUNCTION fretornavalorlimite(pcdvalorrefliminf IN INTEGER,
                               pnuqtdelimiteinf  IN NUMBER,
                               pcdvalorreflimsup IN INTEGER,
                               pnuqtdelimitesup  IN NUMBER,
                               pVlExpressao      IN NUMBER)
  RETURN NUMBER IS

    vvlinferior NUMBER;
    vvlsuperior NUMBER;

  BEGIN
 
    IF pnuqtdelimiteinf IS NOT NULL THEN

      IF pcdvalorrefliminf IS NOT NULL THEN

        vvlinferior := fmneref(pcdvalorrefliminf) * pnuqtdelimiteinf;

      ELSE

        vvlinferior := pnuqtdelimiteinf;

      END IF;

      IF pvlexpressao < vvlinferior AND pvlexpressao > 0 THEN

        RETURN vvlinferior;

      END IF;

     -- END IF;

    END IF;

    IF pnuqtdelimitesup IS NOT NULL THEN

      IF pcdvalorreflimsup IS NOT NULL THEN

        vvlsuperior := fmneref(pcdvalorreflimsup) * pnuqtdelimitesup;

        IF PKGPAG_VAR.vgValorReferencia(pCdValorRefLimSup).FlBloqueioRemuneracao = 'S' THEN

          ------------------------------------------------------------------
          -- Se a rubrica de desconto do teto do governador estiver em
          -- decis?o judicial/lan?amento financeiro
          ------------------------------------------------------------------

        IF NOT PKGPAG_GERAL.FGeraRubrica(PKGPAG_VAR.vgCdRubDescTetoGovernador) THEN

            RETURN pvlexpressao;

          END IF;

        END IF;

      ELSE

        vvlsuperior := pnuqtdelimitesup;

      END IF;

      IF pvlexpressao > vvlsuperior THEN

        RETURN vvlsuperior;

      END IF;

    END IF;

    RETURN pvlexpressao;

  END;

  FUNCTION fmnepercdecjud

   RETURN NUMBER IS

  BEGIN
 
    RETURN PKGPAG_VAR.vgpercdecjudmargem;

  END;

  FUNCTION fretornavalorlimitefinal(pformexpr    IN pkgpag_tipo.rformulacalculo DEFAULT NULL,
                                    pbaseexpr    IN pkgpag_tipo.rbasecalculo DEFAULT NULL,
                                    pVlExpressao IN NUMBER)
  RETURN NUMBER IS

    --vVlExpressao pkgpag_tipo.rvalorpagamento;

  BEGIN
 
    CASE

      WHEN pformexpr.cdformulacalculo IS NOT NULL THEN

        RETURN fretornavalorlimite(pformexpr.cdvalorrefliminffinal,
                                   pformexpr.nuqtdelimiteinffinal,
                                   pformexpr.cdvalorreflimsupfinal,
                                   pformexpr.nuqtdelimitesupfinal,
                                   pvlexpressao);

      WHEN pbaseexpr.cdbasecalculo IS NOT NULL THEN

        RETURN fretornavalorlimite(pbaseexpr.cdvalorreferenciainferior,
                                   pbaseexpr.nuqtdevalreferenciainferior,
                                   pbaseexpr.cdvalorreferenciasuperior,
                                   pbaseexpr.nuqtdevalreferenciasuperior,
                                   pvlexpressao);

      ELSE

        RETURN 0;

    END CASE;

  END;

  FUNCTION fmnechomedio(pcdrelacaovinculo IN INTEGER,
                        pcdchave          IN INTEGER,
                        pdtinicio         IN DATE,
                        pdtfim            IN DATE) RETURN NUMBER IS

    vIndice               NUMBER;
    vNuDiasTrabalhadosMes INTEGER;
    vCHOMensal            NUMBER;
    vNuCHOUltimoDia       NUMBER(13,2);
    vNuchave              INTEGER := 1752306;

  BEGIN
 
    vindice := 0;

    CASE pcdrelacaovinculo

    WHEN 1 THEN -- Efetivo

        IF PKGPAG_VAR.vgcef.first IS NOT NULL THEN

        FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
        LOOP

            IF PKGPAG_VAR.vgcef(i).cdhistrelvinc = pcdchave THEN
              -- Com a implantac?o da SED, fez-se necessario que a media
              -- considere a soma diaria das cargas horarias do servidor,
              -- dividido pelo numero de dias trabalhados
                SELECT
                       NuDiasTrabalhadosMes,
                       CHOMensal,
                       NuCHOUltimoDia
                INTO
                      vNuDiasTrabalhadosMes,
                      vCHOMensal,
                      vNuCHOUltimoDia
                FROM (
                      -- Soma a carga horaria mensal,
                      -- e descobre o numero de dias trabalhados
                  SELECT sum(case when Dias = 31
                                  then case when to_char(to_date(day),'dd') = 31
                                       then 0
                                       else CHODiaria end
                                  else CHODiaria end)  as CHOMensal,
                         sum(case when CHODiaria > 0
                                  then case when Dias = 31
                                            then case when to_char(To_date(day),'dd') = 31
                                                 then 0 else 1 end
                                            else 1 end
                                   else 0 end) as NuDiasTrabalhadosMes,
                              -- Salva a carga horaria do ultimo dia do mes
                       sum(case when day = last_day(day)
                               then CHODiaria
                                else 0 end) as NuCHOUltimoDia
                        FROM (
                               -- Soma a carga horaria diariamente,
                               -- considerando o periodo (ecadhistcargahoraria)
                               SELECT day,
                                 sum(
                                   case
                                             when day between dtIni and dtFim then
                                              nucargahoraria
                                             else
                                              0
                                   end
                                 ) as CHODiaria,
                                       max(DtFim) - min(DtIni) + 1 as DIAS
                                 FROM (
                                        -- Seleciona periodos de carga horaria
                                        -- multiplicando pelos dias do mes
                                        SELECT day,
                                                greatest(DtInicial, pdtinicio) as dtIni,
                                                least(nvl(dtFim, pdtFim), pdtFim) as dtFim,
                                                nucargahoraria
                                          FROM ecadhistcargahoraria hcho,
                                     (select trunc(pdtFim-dayincrement+1, 'DD') as day
                                                   from (select level as dayincrement
                                             from dual connect by level <= 31))
                                         WHERE cdhistcargoefetivo = pcdchave
                                           AND dtinicial <= pdtFim
                                           AND (dtfim >= pdtinicio OR dtfim IS NULL)
                                     AND flanulado = 'N'
                          )
                          GROUP BY day
                      )
                  );

              -- Trata mes de fevereiro
             IF to_number(to_char(To_date(pdtinicio),'mm')) = 2 AND NVL(vNuCHOUltimoDia,0)>0 THEN
                -- Acerta a carga horaria
                IF to_char(To_date(PKGPAG_VAR.vgFolha.dtfimmes), 'dd') = '28' THEN
                  vCHOMensal            := vCHOMensal + 2 * vNuCHOUltimoDia;
                  vNuDiasTrabalhadosMes := vNuDiasTrabalhadosMes + 2;
                ELSE
                  vCHOMensal            := vCHOMensal + vNuCHOUltimoDia;
                  vNuDiasTrabalhadosMes := vNuDiasTrabalhadosMes + 1;
                END IF;

              END IF;

              IF vNuDiasTrabalhadosMes = 31 THEN
                vNuDiasTrabalhadosMes := 30;
              END IF;

              vIndice := vCHOMensal / vNuDiasTrabalhadosMes;

               IF PKGPAG_VAR.vgcef(i).cdhistrelvinc = vNuchave then
                vIndice := NULL;
              END IF;

              IF vindice IS NULL THEN

                vindice := PKGPAG_VAR.vgCef(i).nucargahoraria;

              END IF;

              PKGPAG_VAR.vgCargaHoraria(i).NuDiasTrabalhados := vNuDiasTrabalhadosMes;
             PKGPAG_VAR.vgCargaHoraria(i).NuChoMensal := vCHOMensal/ vNuDiasTrabalhadosMes;

            END IF;

          END LOOP;

        END IF;

    WHEN 2 THEN -- CCO

        IF PKGPAG_VAR.vgcco.first IS NOT NULL THEN

        FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST
        LOOP

            IF PKGPAG_VAR.vgcco(i).cdhistcargocom = pcdchave THEN

              SELECT SUM(nudias * nucargahoraria) / SUM(nudias) AS indcho
                INTO vindice
              FROM ( SELECT least (nvl(dtFim,pdtFim),pdtFim)  - greatest (DtInicial,pdtinicio) + 1 as nuDias,
                             nucargahoraria
                        FROM ecadhistcargahoraria hcho
                       WHERE cdhistcargocom = pcdchave
                         AND dtinicial <= pdtfim
                         AND (dtfim >= pdtinicio OR dtfim IS NULL)
                         AND flanulado = 'N');

            END IF;

          END LOOP;

        END IF;

    WHEN 3 THEN -- Funcao de Chefia - Retornar do 1o CEF se existir, sen?o retornar zero

        IF PKGPAG_VAR.vgfuc.first IS NOT NULL THEN

        FOR i IN PKGPAG_VAR.vgFUC.FIRST .. PKGPAG_VAR.vgFUC.LAST
        LOOP

            IF PKGPAG_VAR.vgfuc(i).cdhistfuncaochefia = pcdchave THEN

              SELECT SUM(nudias * nucargahoraria) / SUM(nudias) AS indcho
                INTO vindice
              FROM ( SELECT least (nvl(dtFim,pdtFim),pdtFim)  - greatest (DtInicial,pdtinicio) + 1 as nuDias,
                             nucargahoraria
                        FROM ecadhistcargahoraria hcho
                       WHERE hcho.cdhistfuncaochefia = pcdchave
                         AND dtinicial <= pdtfim
                         AND (dtfim >= pdtinicio OR dtfim IS NULL)
                         AND flanulado = 'N');

            END IF;

          END LOOP;

        END IF;

      WHEN 4 THEN

        IF PKGPAG_VAR.vgapo.count > 0 THEN

          -- PRIORIZA CARGA HORARIA DO
        FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
        LOOP

            IF PKGPAG_VAR.vgapo(i).cdhistrelvinc = pcdchave THEN

              SELECT SUM(nudias * nucargahoraria) / SUM(nudias) AS indcho
                INTO vindice
              FROM ( SELECT least (nvl(dtFim,pdtFim),pdtFim)  - greatest (DtInicial,pdtinicio) + 1 as nuDias,
                             nucargahoraria
                        FROM ecadhistcargahoraria hcho
                       WHERE cdconcessaoaposentadoria = pcdchave
                         AND dtinicial <= pdtfim
                         AND (dtfim >= pdtinicio OR dtfim IS NULL)
                         AND flanulado = 'N');

              IF vindice IS NULL THEN

                vindice := PKGPAG_VAR.vgapo(i).nucargahoraria;

              END IF;

            END IF;

          END LOOP;

        END IF;

      ELSE

        RETURN 0;

    END CASE;

    RETURN trunc(vindice, 4);

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fmnecho(pcdagrupamento    IN INTEGER,
                   prubrica          IN pkgpag_tipo.rrubrica,
                   pcdrelacaovinculo IN INTEGER,
                   pcdchave          IN INTEGER,
                   ptipo             IN INTEGER DEFAULT 1) -- 1- Mensal 2- Semanal

   RETURN NUMBER IS

    FUNCTION fcho(pcdunidadeorganizacional INTEGER,
                  pnucargahoraria          NUMBER,
                  pnucargahorariacarreira  NUMBER)

     RETURN NUMBER IS

      vnucho NUMBER(7, 4);

    BEGIN
 
      --IF pcdagrupamento <> 2 THEN

      IF prubrica.lsloccho.first IS NOT NULL THEN

        IF prubrica.lsloccho.exists(pcdunidadeorganizacional) THEN

          IF pNuCargaHorariaCarreira > pRubrica.lsLocCHO(pCdUnidadeOrganizacional) AND
             pNuCargaHoraria > pRubrica.lsLocCHO(pCdUnidadeOrganizacional) THEN

            vnucho := prubrica.lsloccho(pcdunidadeorganizacional);

          END IF;

        END IF;

      END IF;

      IF vnucho IS NULL THEN

        vnucho := pnucargahoraria;

      END IF;

        CASE WHEN pTipo = 1

         THEN

          RETURN vnucho * 5;

        ELSE

          RETURN vnucho;

      END CASE;

      /*ELSIF pnucargahoraria = 40 THEN

      CASE WHEN pTipo = 1 THEN

            RETURN 220;

          ELSE

            RETURN 40;

        END CASE;     */

      IF pnucargahoraria = 36 AND pcdagrupamento = 2

       THEN

        CASE WHEN pTipo = 1 THEN

            RETURN 180;

          ELSE

            RETURN 36;

        END CASE;

      END IF;

    END;

  BEGIN
 
    CASE pcdrelacaovinculo

    WHEN 1 THEN -- Efetivo

        IF PKGPAG_VAR.vgcef.first IS NOT NULL THEN

        FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
        LOOP

            IF PKGPAG_VAR.vgcef(i).cdhistrelvinc = pcdchave THEN

              RETURN FCHO(pCdUnidadeOrganizacional => PKGPAG_VAR.vgCEF(i).CdUnidadeOrganizacional,
                          pNuCargaHoraria          => PKGPAG_VAR.vgCEF(i).NuCargaHoraria,
                          pnucargahorariacarreira  => PKGPAG_VAR.vgvalorfixocef.nucargahoraria);

            END IF;

          END LOOP;

        END IF;

    WHEN 2 THEN -- CCO

        IF PKGPAG_VAR.vgcef.first IS NOT NULL THEN

          RETURN FCHO(pCdUnidadeOrganizacional => PKGPAG_VAR.vgCEF(1).CdUnidadeOrganizacional,
                      pnucargahoraria          => PKGPAG_VAR.vgcef(1).nucargahoraria,
                      pnucargahorariacarreira  => PKGPAG_VAR.vgvalorfixocef.nucargahoraria);

        END IF;

    WHEN 3 THEN -- Funcao de Chefia - Retornar do 1o CEF se existir, sen?o retornar zero

        IF PKGPAG_VAR.vgfuc.count > 0 THEN

          RETURN FCHO(pCdUnidadeOrganizacional => PKGPAG_VAR.vgCEF(1).CdUnidadeOrganizacional,
                      pnucargahoraria          => PKGPAG_VAR.vgcef(1).nucargahoraria,
                      pnucargahorariacarreira  => PKGPAG_VAR.vgvalorfixocef.nucargahoraria);

        END IF;

      WHEN 4 THEN

        IF PKGPAG_VAR.vgapo.count > 0 THEN

        FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
        LOOP

            IF PKGPAG_VAR.vgapo(i).cdhistrelvinc = pcdchave THEN

              RETURN FCHO(pCdUnidadeOrganizacional => PKGPAG_VAR.vgAPO(i).CdUnidadeOrganizacional,
                          pNuCargaHoraria          => PKGPAG_VAR.vgAPO(i).NuCargaHoraria,
                          pnucargahorariacarreira  => PKGPAG_VAR.vgvalorfixocef.nucargahoraria);

            END IF;

          END LOOP;

        END IF;

      WHEN 0 THEN

        RETURN fcho(pcdunidadeorganizacional => PKGPAG_VAR.vgrelvincprincipal.cdunidadeorganizacional,
                    pnucargahoraria          => PKGPAG_VAR.vgrelvincprincipal.nuchorelacao,
                    pnucargahorariacarreira  => PKGPAG_VAR.vgrelvincprincipal.nucho);

      ELSE

        RETURN 0;

    END CASE;

    RETURN 0;

  END;

  FUNCTION fmneQtDiasChoZero

   RETURN NUMBER IS

  BEGIN
 
    RETURN nvl(PKGPAG_VAR.vgNuDiasCargaHorariaZero, 0);

  END;

  FUNCTION fretornavalorlimiteparcial(pformexpr    IN pkgpag_tipo.rformulacalculo,
                                      pvlexpressao IN NUMBER)

   RETURN NUMBER IS

  BEGIN
 
    RETURN fretornavalorlimite(pformexpr.cdvalorrefliminfparcial,
                               pformexpr.nuqtdeliminfparcial,
                               pformexpr.cdvalorreflimsupparcial,
                               pformexpr.nuqtdelimitesupparcial,
                               pvlexpressao);

  END;

  FUNCTION fVlrBaseSalFamOutraFolha(pCdPessoa  IN INTEGER,
                                    pCdVinculo IN INTEGER)

   RETURN NUMBER IS

    vVlTotalBase NUMBER(13, 2) := 0;

    vVlBase pkgpag_tipo.rValorPagamento;

  BEGIN
      FOR BASE IN (
       WITH VIN AS (SELECT v.cdvinculo
                      FROM ECADVINCULO V
                     WHERE V.CDPESSOA = pCdPessoa
                       AND V.Cdvinculo <> pCdVinculo
                       AND (v.Dtdesligamento is null or
                             v.DtDesligamento >= PKGPAG_VAR.vgfolha.DtInicioMes)),
             FOL AS (SELECT f.cdfolhapagamento
                      FROM ECalFolhaPag F
                     WHERE F.CdTipoCalculo = pkgpag_tipo.cnTpCalculoNormal
                        AND F.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                        AND F.Cdtipofolhapagamento = PKGPAG_VAR.vgfolha.CdTipoFolhaPagamento
                        AND F.NUANOMESREFERENCIA = to_char(ADD_MONTHS(PKGPAG_VAR.vgFolha.DtInicioMes,-1),'YYYYMM')
                       AND F.Flcalculodefinitivo = 'S')
                   SELECT CAPA.CDVINCULO, CAPA.CDFOLHAPAGAMENTO
                     FROM EPAGCAPAHISTRUBRICAVINCULO CAPA
          INNER JOIN FOL F ON F.CDFOLHAPAGAMENTO = CAPA.CDFOLHAPAGAMENTO
          INNER JOIN VIN V ON V.CDVINCULO = CAPA.CDVINCULO
           )

     LOOP

      pkgpag_param.PArmazenaInfoFolhaAuxiliar(BASE.CDFOLHAPAGAMENTO);

      vvlBase.vlIntegral := 0;

      vvlBase := FRetornaValorBaseCalculo(pfolha            => PKGPAG_VAR.vgFolhaAuxiliar,
                                          pcdvinculo        => BASE.CDVINCULO,
                                          pcdtipohistorico  => 2,
                                          pcdrelacaovinculo => 0,
                                          pcdbasecalculo    => PKGPAG_VAR.vgrubrica(PKGPAG_GERAL.fretornarubrica(1, 9, 1000)).cdbasecalculo, --vcdbasecalculo,
                                          pcdchave          => BASE.CDVINCULO,
                                          pCdFolhaAnt       => base.cdfolhapagamento);

      vVlTotalBase := vVlTotalBase + NVL(vvlBase.vlIntegral, 0);

    END LOOP;

    RETURN NVL(vVlBase.vlIntegral, 0);

  exception
         when no_data_found
           then
      return 0;

         when others
           then
      return 0;

  END;

  FUNCTION fmnenaopossuicco

   RETURN INTEGER IS

  BEGIN
 
    IF PKGPAG_VAR.vgcco.count > 0 THEN

      RETURN 0;

    ELSIF PKGPAG_VAR.vgccosubst.count > 0 THEN

      RETURN 0;

    ELSIF PKGPAG_VAR.vgcef.count > 0 THEN

      IF PKGPAG_VAR.vgcef(1).cdestruturacarreira = 59983 THEN

        RETURN 0;

      END IF;

    ELSIF PKGPAG_VAR.vgapo.count > 0 THEN

      IF PKGPAG_VAR.vgapo(1).cdestruturacarreira = 59983 THEN

        RETURN 0;

      END IF;

    else
      null;
    END IF;

    RETURN 1;

  END;

  FUNCTION fmnevalorbaserateiocco

   RETURN NUMBER IS

  BEGIN
 
    IF PKGPAG_VAR.vgcco.count > 0 THEN

    FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST
    LOOP

        IF PKGPAG_VAR.vgcco(i).cdgrupoocupacional = 106 THEN

          RETURN 1006.68;

        ELSE

          RETURN 1484.47;

        END IF;

      END LOOP;

    ELSIF PKGPAG_VAR.vgccosubst.count > 0 THEN

    FOR i IN PKGPAG_VAR.vgCCOSubst.FIRST .. PKGPAG_VAR.vgCCOSubst.LAST
    LOOP

        IF PKGPAG_VAR.vgccosubst(i).cdgrupoocupacional = 106 THEN

          RETURN 1006.68;

        ELSE

          RETURN 1484.47;

        END IF;

      END LOOP;

    ELSIF PKGPAG_VAR.vgcef.count > 0 THEN

      IF PKGPAG_VAR.vgcef(1).cdestruturacarreira = 59983 THEN

        RETURN 1200;

      END IF;

    ELSIF PKGPAG_VAR.vgapo.count > 0 THEN

      IF PKGPAG_VAR.vgapo(1).cdestruturacarreira = 59983 THEN

        RETURN 1200;

      END IF;

    else
      null;
    END IF;

    RETURN 0;

  END;

  FUNCTION fmnepossuicc(pfolha     IN pkgpag_tipo.rfolha,
                       pCdVinculo       IN INTEGER)
  RETURN INTEGER IS

    vpossuiconsignacaocc INTEGER;

  BEGIN
 
    SELECT 1
      INTO vpossuiconsignacaocc
      FROM epagbaseconsignacao bc
     INNER JOIN epagconsignacao c
        ON bc.cdconsignacao = c.cdconsignacao
     INNER JOIN epaghistconsignacao hc
        ON c.cdconsignacao = hc.cdconsignacao
     INNER JOIN epagtiposervico ts
        ON ts.cdtiposervico = c.cdtiposervico
     INNER JOIN epaghisttiposervico hts
        ON ts.cdtiposervico = hts.cdtiposervico
      WHERE CdVinculo = pCdVinculo AND
            ((BC.NuAnoReferenciaInicial < pFolha.NuAnoReferencia OR
           (bc.nuanoreferenciainicial = pfolha.nuanoreferencia AND
           (bc.numesreferenciainicial <= pfolha.numesreferencia))) AND
           ((bc.nuanoreferenciafinal > pfolha.nuanoreferencia OR
           (bc.nuanoreferenciafinal = pfolha.nuanoreferencia AND
           bc.numesreferenciafinal >= pfolha.numesreferencia) OR
            BC.NuMesReferenciaFinal IS NULL))) AND
            BC.DtCancelamento IS NULL AND
            (HTS.FlCartaoCredito = PKGPAG_TIPO.cnS) AND
            (HC.DtInicioVigencia <= PKGPAG_VAR.vDtCalculo AND
            (HC.DtFimVigencia >= PKGPAG_VAR.vDtCalculo OR HC.DtFimVigencia IS NULL)) AND
            (HTS.DtInicioVigencia <= PKGPAG_VAR.vDtCalculo AND
            (HTS.DtFimVigencia >= PKGPAG_VAR.vDtCalculo OR HTS.DtFimVigencia IS NULL));

    RETURN vpossuiconsignacaocc;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

    WHEN too_many_rows THEN

      RETURN 1;

  END;

  FUNCTION fmnepossuiproventos(pfolha     IN pkgpag_tipo.rfolha,
                              pCdVinculo       IN INTEGER)
  RETURN INTEGER IS

    vpossuiproventos INTEGER;

  BEGIN
 
    SELECT 1
      INTO vpossuiproventos
      FROM epaghistoricorubricavinculo hrv
     INNER JOIN epagrubricaagrupamento ra
        ON hrv.cdrubricaagrupamento = ra.cdrubricaagrupamento
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
   WHERE HRV.CdFolhaPagamento = pFolha.CdFolhaPagamento AND
         HRV.CdVinculo = pCdVinculo AND
         R.CdTipoRubrica IN (1,2,4,10,12) AND
         ROWNUM < 2;

    RETURN vpossuiproventos;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fmnevalordecisaojudicial(pfolha                IN pkgpag_tipo.rfolha,
                                    pcdvinculo            IN INTEGER,
                                    pcdrubricaagrupamento IN INTEGER,
                                    pnusufixorubrica      IN INTEGER)
    RETURN NUMBER IS

  BEGIN
 
    FOR vpagdecjud IN pkgpag_lf.cpagdecisaojudicial(pcdvinculo,
                                                    pfolha.nuanoreferencia,
                                                  pFolha.NuMesReferencia)
  LOOP

      IF vpagdecjud.cdrubricaagrupamento = pcdrubricaagrupamento AND
         vpagdecjud.nusufixorubrica = pnusufixorubrica THEN

        RETURN pkgpag_lf.fvalordecisaojudicial(pfolha              => pfolha,
                                               ppagdecisaojudicial => vpagdecjud);

      END IF;

    END LOOP;

    RETURN 0;

  END;

  FUNCTION fmnepossuidecjudicial(pcdvinculo            IN INTEGER,
                                 pcdrubricaagrupamento IN INTEGER,
                                 pnumesreferencia      IN INTEGER,
                                 pnuanoreferencia      IN INTEGER)

   RETURN INTEGER IS

    vpossuidecjudicial INTEGER;

  BEGIN
 
    SELECT 1
      INTO vpossuidecjudicial
      FROM epageventopagagrupdecisao e
   WHERE E.CdVinculo = pCdVinculo AND
         E.flAnulado = 'N' AND
         E.InTipoValor = 4 AND -- Autoriza pagamento
         E.CdRubricaAgrupamento = pCdRubricaAgrupamento AND
         ((pNuAnoReferencia * 100) + pNuMesReferencia)
             BETWEEN ((E.NuAnoInicioDireito * 100) + E.NuMesInicioDireito) AND
         (NVL(E.NuAnoFimDireito, 9999) * 100 + NVL(E.NuMesFimDireito, 99)) AND
         ROWNUM < 2;

    RETURN vpossuidecjudicial;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fsomarano(pcdvinculo            IN INTEGER,
                     pnuanoreferencia      IN INTEGER,
                     pnumesreferencia      IN INTEGER,
                     pcdtipohistorico      IN INTEGER,
                     pcdrelacaovinculo     IN INTEGER,
                     pcdchave              IN INTEGER,
                     pcdagrupamento        IN INTEGER,
                     pcdrubricaagrupamento IN INTEGER,
                     pflfolha13sal         IN CHAR)

   RETURN NUMBER IS

    vnumesinicio INTEGER;

    vsql VARCHAR2(2000);

    vvlpagamento NUMBER(13, 2);

    vCdRubricaAgr_01_0024 INTEGER;

  BEGIN
 
    IF (pcdtipohistorico = 1 AND
       pcdrelacaovinculo = PKGPAG_VAR.vgrelvincprincipal.tipo AND
       pcdchave = PKGPAG_VAR.vgrelvincprincipal.cdhist) OR
       (pcdtipohistorico = 2) THEN

     IF pNuMesReferencia >= 1 OR pCdAgrupamento in (2,4,5,6) THEN      -- CIASC, CIDASC, EPAGRI E SANTUR

       IF to_number(TO_CHAR(PKGPAG_VAR.vgVinculo.DtAdmissao,'YYYY')) < pNuAnoReferencia THEN

          vnumesinicio := 1;

        ELSIF pnumesreferencia > 1 THEN

          vnumesinicio := to_number(to_char(PKGPAG_VAR.vgvinculo.dtadmissao, 'MM'));

        else
          null;
        END IF;

        --------------------------------------------------------------------
        -- Senhor, tende piedade de n?s - 20/05/2014
        --------------------------------------------------------------------

       IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT THEN

         IF to_number(TO_CHAR(PKGPAG_VAR.vgRelVincPrincipal.DtInicioRelacao,'YYYY')) = pNuAnoReferencia THEN

           vNuMesInicio := to_number(TO_CHAR(PKGPAG_VAR.vgRelVincPrincipal.DtInicioRelacao,'MM'));

          END IF;

        END IF;

        vsql := 'SELECT SUM(vlPagamento) ' ||
                'FROM ePagHistoricoRubricaVinculo HRV ' ||
                'INNER JOIN ECalFolhaPag FP ' ||
                'ON HRV.CdFolhaPagamento = FP.CdFolhaPagamento ' ||
                ' AND FP.CdCalculo =  :pCdCalculo ' ||
                'INNER JOIN EPagTipoFolhaPagamento TFP ' ||
                'ON FP.CdTipoFolhaPagamento = TFP.CdTipoFolhaPagamento ' ||
                'WHERE HRV.CdVinculo = :pCdVinculo AND ' ||
                'FP.CdTipoCalculo IN (:pTpCalcNormal, :pTpCalcSupl) AND ' ||
                'FP.NuAnoReferencia = :pNuAnoReferencia AND ';

        IF (PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cntpfolha13)
          OR (PKGPAG_VAR.vgfolha.cdtipofolha IN (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13))
          THEN

          -- Hora plantao/ Media Hora plantao apura os valores da folha normal (mesmo quando não é definitiva)
          IF PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica in (108, 180)
            THEN
              vSQL := vSQL || '((FP.NuMesReferencia BETWEEN :pNuMesInicio AND :pNuMesFim AND ' ||
                    ' FP.FlCalculoDefinitivo = ''S'')' ||
                    ' OR (FP.NuAnoReferencia = :pNuAnoReferencia AND ' ||
                    ' FP.NuMesReferencia = :pNuMesReferencia AND TFP.CdTipoFolha IN (' ||
                      pkgpag_tipo.cnTpFolhaNormal || ', ' || PKGPAG_VAR.vgfolha.cdtipofolha || ')' ||
                     -- POG: N?O DEVE SOMAR A 06-0524 QUANDO CALCULANDO FOLHA DE 13
                     --      E BUSCANDO NA FOLHA NORMAL ABERTA DO M?S
                    ' AND HRV.CdRubricaAgrupamento NOT IN (8812))) AND ';

          ELSE
            vSQL := vSQL || '((FP.NuMesReferencia BETWEEN :pNuMesInicio AND :pNuMesFim AND ' ||
                    ' FP.FlCalculoDefinitivo = ''S'')' ||
                    ' OR (FP.NuAnoReferencia = :pNuAnoReferencia AND ' ||
                    ' FP.NuMesReferencia = :pNuMesReferencia AND TFP.CdTipoFolha = ' || PKGPAG_VAR.vgfolha.cdtipofolha ||
                     -- POG: N?O DEVE SOMAR A 06-0524 QUANDO CALCULANDO FOLHA DE 13
                     --      E BUSCANDO NA FOLHA NORMAL ABERTA DO M?S
                    ' AND HRV.CdRubricaAgrupamento NOT IN (8812))) AND ';
          END IF;
          -- rubrica 09-0015 considerando o abatimento da diferença do INSS 13 salário em duplicidade.
         IF pcdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 9, 15)
           AND (PKGPAG_VAR.vgfolha.numesreferencia = 12 AND pcdagrupamento = 1)
           THEN
            vSQL := vSQL || ' ((HRV.CdRubricaAgrupamento <> 10833 AND TFP.CdTipoFolha = 1) OR TFP.CdTipoFolha <> 1) AND ';
          END IF;

        ELSE

          vsql := vsql || '((FP.NuMesReferencia BETWEEN :pNuMesInicio AND :pNuMesFim AND ' ||
                  'FP.FlCalculoDefinitivo = ''S'')) AND ';

        END IF;

        vCdRubricaAgr_01_0024 := PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 1, 24);

        -- Se folha de adiantamento de 13?, ent?o desconsidera folhas de d?cimo e adiantamento
        IF PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cntpfolhaadiant13 THEN

          vSQL := vSQL || ' TFP.CdTipoFolha not in (:pCdTipoFolha,:pCdTipoFolhaAdiant) AND ';

        elsif PKGPAG_VAR.vgfolha.cdtipofolha in (pkgpag_tipo.cnTpFolhaCtisp, pkgpag_tipo.cnTpFolhaCtisp13)
          and pflfolha13sal = 'S' then

          IF PKGPAG_VAR.vgfolha.nuMesReferencia = 12
            and PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cnTpFolhaCtisp13
            THEN
            -- para 13, desconsidera os valores da folha definitiva 13 de novembro
             vSQL := vSQL || ' TFP.CDTIPOFOLHA IN (:pCdTipoFolha,:pCdTipoFolhaAdiant) ' ||
                    ' AND NOT(TFP.CdTipoFolha = 20 AND FP.NuMesReferencia = 11) AND ';
          ELSE
             vSQL := vSQL || ' TFP.CdTipoFolha in (:pCdTipoFolha,:pCdTipoFolhaAdiant) AND ';
          END IF;

          -- Se folha n?o for de 13?, ent?o desconsidera folha de d?cimo
        ELSIF pflfolha13sal = 'N' THEN

          vsql := vsql || ' TFP.CdTipoFolha <> :pCdTipoFolha AND ';

       ELSIF pflfolha13sal = 'S'
         AND pcdrubricaagrupamento = vCdRubricaAgr_01_0024
         THEN
            vsql := vsql || ' TFP.CdTipoFolha in (:pCdTipoFolha, 1, 4, 5) AND ';

        ELSIF pcdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(PKGPAG_VAR.vgFolha.CdAgrupamento, 5, 524)
          AND PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cntpfolha13
          AND PKGPAG_VAR.vgFolha.numesreferencia = 12
          THEN

          vsql := vsql || ' TFP.CdTipoFolha = :pCdTipoFolha AND ' ||
                  ' AND fp.cdfolhapagamento NOT IN ' ||
                  ' (SELECT CDFOLHAPAGAMENTO ' ||
                  ' FROM ECalFolhaPag FP ' ||
                  ' INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF ' ||
                  '  ON TF.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO ' ||
                           ' WHERE TF.CDTIPOFOLHA = ' || PKGPAG_VAR.vgfolha.cdtipofolha ||
                           ' AND FP.NUANOREFERENCIA = ' || PKGPAG_VAR.vgfolha.nuanoreferencia ||
                  ' AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo ' ||
                  ' AND FP.FLCALCULODEFINITIVO = ''S'') AND ';

        ELSE

          vsql := vsql || ' TFP.CdTipoFolha = :pCdTipoFolha AND ';

        END IF;

        -- Senhor, perdoai as nossa ofensas
        -- Se for folha de decimo, desconsiderar somar adiantamento de decimo
        -- proveniente de retroativo
        IF PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cntpfolha13
           AND pcdrubricaagrupamento = vCdRubricaAgr_01_0024 THEN

          vsql := vsql || ' HRV.cdprocessopagretroativo IS NULL AND ';

        END IF;

       vSQL := vSQL || 'HRV.CdRubricaAgrupamento IN (SELECT CdRubricaAgrupamento '||
                'FROM EPagRubricaAgrupamento RA ' ||
                'INNER JOIN EPagRubrica R ' ||
                'ON RA.CdRubrica = R.CdRubrica ';

        IF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 1 THEN

          vsql := vsql || ' WHERE R.CdTipoRubrica IN (1,2,3) AND ';

        ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 5 THEN

          vsql := vsql || ' WHERE R.CdTipoRubrica IN (5,6,7) AND ';

        ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 8 THEN

          vsql := vsql || ' WHERE R.CdTipoRubrica IN (8) AND ';

        ELSE

          vsql := vsql || ' WHERE 1=2 AND ';

        END IF;

       vSQL := vSQL || ' R.NuRubrica = :pNuRubrica AND RA.CdAgrupamento = :pCdAgrupamento)';

        -- Se adiantamento de decimo terceiro...
        IF PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cntpfolhaadiant13 THEN

          EXECUTE IMMEDIATE vSQL
            INTO vvlpagamento
              USING PKGPAG_VAR.vgCalculo.CdCalculo,
                    pCdVinculo,
                    PKGPAG_TIPO.cnTpCalculoNormal,
                    PKGPAG_TIPO.cnTpCalculoSupl,
                    pNuAnoReferencia,
                    vNuMesInicio,
                    pNuMesReferencia,                   
                    PKGPAG_TIPO.cnTpFolha13,
                    PKGPAG_TIPO.cnTpFolhaAdiant13,
                    
                    PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,
                    pCdAgrupamento;

          -- Se folha de decimo...
        ELSIF PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cntpfolha13 THEN

          EXECUTE IMMEDIATE vSQL
            INTO vvlpagamento
                USING PKGPAG_VAR.vgCalculo.CdCalculo,
                      pCdVinculo,
                      PKGPAG_TIPO.cnTpCalculoNormal,
                      PKGPAG_TIPO.cnTpCalculoSupl,
                      pNuAnoReferencia,
                      vNuMesInicio,
                      pNuMesReferencia,
                      pNuAnoReferencia,
                      pNuMesReferencia,                     
                      PKGPAG_TIPO.cnTpFolha13,
                      PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,
                      pCdAgrupamento;

          -- SIG-7368
          -- não retorna valores para as rubricas pois estas não existem na folha de 13 sal
          -- 01-1035 GRAT HORA EXTRAORDINARIA SJC ART 55 LC 675/2016
          -- 01-1078 ADICIONAL NOTURNO SJC ART 57 LC 675/2016
          -- 01-1350 MEDIA GRATIFICACAO POR HORA EXTRAORDINARIA SJC
          -- 01-1780 MEDIA ADICIONAL NOTURNO SJC
          IF --NVL(vvlpagamento, 0) = 0 AND
               PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica IN (1035,1078,1350,1780)
               THEN
            EXECUTE IMMEDIATE vSQL
              INTO vvlpagamento
                USING PKGPAG_VAR.vgCalculo.CdCalculo,
                      pCdVinculo,
                      PKGPAG_TIPO.cnTpCalculoNormal,
                      PKGPAG_TIPO.cnTpCalculoSupl,
                      pNuAnoReferencia,
                      vNuMesInicio,
                      pNuMesReferencia,
                      pNuAnoReferencia,
                      pNuMesReferencia,
                      PKGPAG_TIPO.cnTpFolhaNormal,
                      PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,
                      pCdAgrupamento;

          END IF;

          -- Adiantamento 13 Ctisp
        ELSIF PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cnTpFolhaAdiant13Ctisp THEN

          EXECUTE IMMEDIATE vSQL
            INTO vvlpagamento
              USING PKGPAG_VAR.vgCalculo.CdCalculo,
                    pCdVinculo,
                    PKGPAG_TIPO.cnTpCalculoNormal,
                    PKGPAG_TIPO.cnTpCalculoSupl,
                    pNuAnoReferencia,
                    vNuMesInicio,
                    pNuMesReferencia,
                    PKGPAG_TIPO.cnTpFolhaCtisp13,
                    PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp,
                    PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,
                    pCdAgrupamento;

          -- Se folha de decimo Ctisp
        ELSIF PKGPAG_VAR.vgfolha.cdtipofolha in (pkgpag_tipo.cnTpFolhaCtisp, pkgpag_tipo.cnTpFolhaCtisp13) and pflfolha13sal = 'S' THEN

          EXECUTE IMMEDIATE vSQL
            INTO vvlpagamento
              USING PKGPAG_VAR.vgCalculo.CdCalculo,
                    pCdVinculo,
                    PKGPAG_TIPO.cnTpCalculoNormal,
                    PKGPAG_TIPO.cnTpCalculoSupl,
                    pNuAnoReferencia,
                    vNuMesInicio,
                    pNuMesReferencia,
                    PKGPAG_TIPO.cnTpFolhaCtisp13,
                    PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp,
                    PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,
                    pCdAgrupamento;
          -- Folha Ctisp
        elsif PKGPAG_VAR.vgfolha.cdtipofolha = pkgpag_tipo.cnTpFolhaCtisp then

          EXECUTE IMMEDIATE vSQL
            INTO vvlpagamento
               USING PKGPAG_VAR.vgCalculo.CdCalculo,
                     pCdVinculo,
                     PKGPAG_TIPO.cnTpCalculoNormal,
                     PKGPAG_TIPO.cnTpCalculoSupl,
                     pNuAnoReferencia,
                     vNuMesInicio,
                     pNuMesReferencia,
                     PKGPAG_TIPO.cnTpFolhaCtisp13,
                     PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp,
                     PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,
                     pCdAgrupamento;

          -- Se outro tipo de folha...
        ELSE

          EXECUTE IMMEDIATE vSQL
            INTO vvlpagamento
               USING PKGPAG_VAR.vgCalculo.CdCalculo,
                     pCdVinculo,
                     PKGPAG_TIPO.cnTpCalculoNormal,
                     PKGPAG_TIPO.cnTpCalculoSupl,
                     pNuAnoReferencia,
                     vNuMesInicio,
                     pNuMesReferencia,
                     PKGPAG_TIPO.cnTpFolha13,
                     PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,
                     pCdAgrupamento;

        END IF;

        RETURN nvl(vvlpagamento, 0.0);

      ELSE

        RETURN 0;

      END IF;

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN

      RETURN 0;
      
    WHEN TOO_MANY_ROWS THEN

      RETURN 0;

  END;

  FUNCTION fmnePossuiValorAno(pcdvinculo            IN INTEGER,
                              pnuanoreferencia      IN INTEGER,
                              pnumesreferencia      IN INTEGER,
                              pcdtipohistorico      IN INTEGER,
                              pcdrelacaovinculo     IN INTEGER,
                              pcdchave              IN INTEGER,
                              pcdagrupamento        IN INTEGER,
                              pcdrubricaagrupamento IN INTEGER)
     return number is

    vValor number(13, 2) := 0;

  begin
 
    vValor := fsomarano(pcdvinculo            => pcdvinculo,
                        pnuanoreferencia      => pnuanoreferencia,
                        pnumesreferencia      => pnumesreferencia,
                        pcdtipohistorico      => pcdtipohistorico,
                        pcdrelacaovinculo     => pcdrelacaovinculo,
                        pCdChave              => pCdChave,
                        pCdAgrupamento        => pCdAgrupamento,
                        pcdrubricaagrupamento => pcdrubricaagrupamento,
                        pflfolha13sal         => 'N');

    if vValor > 0 then

      vValor := 1;

    end if;

    return vvalor;

  end;

  FUNCTION fmnesomaano(pcdvinculo            IN INTEGER,
                       pnuanoreferencia      IN INTEGER,
                       pnumesreferencia      IN INTEGER,
                       pcdtipohistorico      IN INTEGER,
                       pcdrelacaovinculo     IN INTEGER,
                       pcdchave              IN INTEGER,
                       pcdagrupamento        IN INTEGER,
                       pcdrubricaagrupamento IN INTEGER,
                       pflfolha13sal         IN CHAR DEFAULT 'N')

   RETURN NUMBER IS

  BEGIN
 
    RETURN fsomarano(pcdvinculo            => pcdvinculo,
                     pnuanoreferencia      => pnuanoreferencia,
                     pnumesreferencia      => pnumesreferencia,
                     pcdtipohistorico      => pcdtipohistorico,
                     pcdrelacaovinculo     => pcdrelacaovinculo,
                     pCdChave              => pCdChave,
                     pCdAgrupamento        => pCdAgrupamento,
                     pcdrubricaagrupamento => pcdrubricaagrupamento,
                     pflfolha13sal         => pflfolha13sal);

  END;

  FUNCTION fmnesomaano13(pcdvinculo            IN INTEGER,
                         pnuanoreferencia      IN INTEGER,
                         pnumesreferencia      IN INTEGER,
                         pcdtipohistorico      IN INTEGER,
                         pcdrelacaovinculo     IN INTEGER,
                         pcdchave              IN INTEGER,
                         pcdagrupamento        IN INTEGER,
                         pcdrubricaagrupamento IN INTEGER)

   RETURN NUMBER IS

  BEGIN
 
    RETURN fsomarano(pcdvinculo            => pcdvinculo,
                     pnuanoreferencia      => pnuanoreferencia,
                     pnumesreferencia      => pnumesreferencia,
                     pcdtipohistorico      => pcdtipohistorico,
                     pcdrelacaovinculo     => pcdrelacaovinculo,
                     pCdChave              => pCdChave,
                     pCdAgrupamento        => pCdAgrupamento,
                     pcdrubricaagrupamento => pcdrubricaagrupamento,
                     pflfolha13sal         => 'S');

  END;
  ------------------------------------------------------------------
  --
  ------------------------------------------------------------------

  FUNCTION fmnemediaano(pcdvinculo            IN INTEGER,
                        pnuanoreferencia      IN INTEGER,
                        pnumesreferencia      IN INTEGER,
                        pcdtipohistorico      IN INTEGER,
                        pcdrelacaovinculo     IN INTEGER,
                        pcdchave              IN INTEGER,
                        pcdagrupamento        IN INTEGER,
                        pcdrubricaagrupamento IN INTEGER)

   RETURN NUMBER IS

    vvlpagamento NUMBER(13, 2);

    vnurubrica INTEGER;

    v1 INTEGER;

    v2 INTEGER;

  BEGIN
 
    vnurubrica := PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).nurubrica;

    IF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 1 THEN

     v1:= 1; v2:= 2;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 5 THEN

     v1:= 5; v2:= 6;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 9 THEN

     v1:= 9;  v2:= 9;

    else
      null;
    END IF;

    -- A leitura est? sendo feita no vinculo pois n?o exitem
    -- registros de rela??o de v?nculo em org?os implantados durante o ano 2011 (vide SSP)
    -- Pela mesma raz?o a leitura ? feita apenas na rela??o de v?nculo principal

    IF (pcdtipohistorico = 1 AND
       pcdrelacaovinculo = PKGPAG_VAR.vgrelvincprincipal.tipo AND
       pcdchave = PKGPAG_VAR.vgrelvincprincipal.cdhist) OR
       (pcdtipohistorico = 2) THEN

      SELECT SUM(hrv.vlpagamento) AS vlpagamento
        INTO vvlpagamento
        FROM epaghistoricorubricavinculo hrv
       INNER JOIN ECalFolhaPag fp
          ON hrv.cdfolhapagamento = fp.cdfolhapagamento
         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
       INNER JOIN epagtipofolhapagamento tfp
          ON fp.cdtipofolhapagamento = tfp.cdtipofolhapagamento
       INNER JOIN epagrubricaagrupamento ra
          ON ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
       WHERE HRV.CdVinculo = pCdVinculo AND
             FP.CdTipoCalculo IN (1, 5) AND
             FP.NuAnoReferencia = pNuAnoReferencia AND
             (FP.FlCalculoDefinitivo = 'S' OR
             FP.NuMesReferencia = pNuMesReferencia)
         AND TFP.CdTipoFolha = 1
             AND
             HRV.CdRubricaAgrupamento  IN (SELECT CdRubricaAgrupamento
                FROM epagrubricaagrupamento ra
               INNER JOIN epagrubrica r
                  ON ra.cdrubrica = r.cdrubrica
                                            WHERE R.NuRubrica = vNuRubrica AND
                                            R.CdTipoRubrica IN (v1, v2) AND
                                            RA.CdAgrupamento = pCdAgrupamento);

    END IF;

    RETURN trunc(nvl(vvlpagamento, 0.0) / 12, 4);

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fCalculaFormula(pcdvinculo            IN INTEGER,
                           pAnoMes               IN integer,
                           pcdrubricaagrupamento IN INTEGER,
                           pVlIndice             in integer default null,
                           pDeFormula            out char,
                           pFlCalculoDefinitivo  char default 'S')

   RETURN NUMBER IS

    --vnurubrica INTEGER;

    vValorSoma NUMBER(13, 4);

    vFolha pkgpag_tipo.rFolha;

    vPagCalc pkgpag_tipo.rPagCalc;

    vCdFolhaPagamento integer;

    vCdExpressaoFormCalc integer;

    vformexpr pkgpag_tipo.rformulacalculo;

  BEGIN
     vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                                   pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                                   pCdRelacaoVinculo     => 1); --formula nao especifica

    vformexpr := PKGPAG_VAR.vgformexpr(vCdExpressaoFormCalc);

    select f.cdfolhapagamento
      into vCdFolhaPagamento
      from EpagFolhaPagamento f
     where f.cdorgao = PKGPAG_VAR.vgFolha.CdOrgao
       and f.nuanomesreferencia = pAnoMes
       and f.flcalculodefinitivo = pFlCalculoDefinitivo
       and f.Cdtipocalculo = 1
       and f.Cdtipofolhapagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento;

    FOR RUB IN
        (SELECT hrv.*
                  FROM epaghistoricorubricarelvinc hrv
                 WHERE HRV.CdVinculo = pCdVinculo
             AND HRV.cdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                   AND HRV.CdRubricaAgrupamento = pcdrubricaagrupamento
                   AND ROWNUM < 2)

     LOOP
      vPagCalc.cdvinculo                     := RUB.Cdvinculo;
      vPagCalc.cdrubricaagrupamento          := RUB.cdrubricaagrupamento;
      vPagCalc.cdexpressaoformcalc           := vFormExpr.cdexpressaoformcalc;
      vPagCalc.cdvantagempecuniaria          := RUB.cdvantagempecuniaria;
      vPagCalc.cdrubricatotalizadoravantagem := RUB.cdrubricatotalizadoravantagem;
      vPagCalc.cdincorporacaoativo           := RUB.cdincorporacaoativo;
      vPagCalc.vlminrecebincorp              := RUB.vlminrecebincorp;
      vPagCalc.cdrelacaovinculo              := RUB.cdrelacaovinculo;
      vPagCalc.cdchave                       := RUB.cdchave;
         vPagCalc.vlindicerubrica := nvl(pVlIndice, rub.vlindicerubrica);
      vPagCalc.cdtipohistorico               := 2;
      vPagCalc.cdhistcargoefetivo            := RUB.cdhistcargoefetivo;
      vPagCalc.cdhistfuncaochefia            := RUB.cdhistfuncaochefia;
      vPagCalc.cdhistcargocom                := RUB.cdhistcargocom;
      vPagCalc.cdconcessaoaposentadoria      := RUB.cdconcessaoaposentadoria;
      vPagCalc.cdhistestagio                 := RUB.cdhistestagio;
      vPagCalc.cdhistpensaoprevidenciaria    := RUB.cdhistpensaoprevidenciaria;
      vPagCalc.cdhistpensaonaoprev           := RUB.cdhistpensaonaoprev;
      vPagCalc.cdhistpensaoexparlamentar     := RUB.cdhistpensaoexparlamentar;
      vPagCalc.dtiniciorelacao               := RUB.dtiniciorelacao;
      vPagCalc.dtdesligamento                := RUB.dtdesligamento;
      vPagCalc.cdunidadeorganizacional       := RUB.cdunidadeorganizacional;
      vPagCalc.cdlancamentofinanceiro        := NULL;
      vPagCalc.dtinicio                      := RUB.dtinicio;
      vPagCalc.dtfim                         := RUB.dtfim;
      vPagCalc.nusufixorubrica               := 1;
         vPagCalc.vlindicereal := nvl(pVlIndice, rub.vlindicereal);

      vFolha := PKGPAG_VAR.vgFolhaAuxiliar;

      pkgpag_param.PArmazenaInfoFolhaAuxiliar(vCdFolhaPagamento);

      vDeformulaCalculada.DeExprProporcional := null;

      pkgpag_fb.pprocformulacalculo(pfolha        => PKGPAG_VAR.vgFolhaAuxiliar,
                                    ppagcalc      => vPagCalc,
                                    pexprform     => vFormExpr,
                                    pRetornaValor => 'S',
                                    pCdFolhaAnt   => vCdFolhaPagamento);

         vValorSoma := nvl(vValorSoma,0) + NVL(vVlFormula.vlProporcional,0);
      PKGPAG_VAR.vgFolhaAuxiliar := vFolha;
      pDeFormula                 := vDeformulaCalculada.DeExprProporcional;

    END LOOP;

    RETURN NVL(vValorSoma, 0);

  EXCEPTION

    WHEN NO_DATA_FOUND

     THEN
      RETURN 0;

    WHEN OTHERS
       THEN
      RETURN 0;

  END;

  --
  -- Calcular a media de 12 meses para rubricas com indice como horas extras e sobreaviso
  -- atualizando os valores calculados conforme alteracoes em tabelas salariais e bases
  --
  FUNCTION fmnemediaindiceano(pcdvinculo            IN INTEGER,
                              pcdtipohistorico      IN INTEGER,
                              pcdrelacaovinculo     IN INTEGER,
                              pcdchave              IN INTEGER,
                              pcdrubricaagrupamento IN INTEGER,
                              pfolha                in pkgpag_tipo.rFolha)

   RETURN NUMBER IS

    vnurubrica INTEGER;

    vValorSoma NUMBER(13, 4);

    vCdExpressaoFormCalc INTEGER;

    vAnoMesIni CHAR(6);

    vAnoMesFim CHAR(6);

    vPagCalc pkgpag_tipo.rPagCalc;

    vformexpr pkgpag_tipo.rformulacalculo;

    pCdFolhaPagamento13Normal INTEGER;

  BEGIN
 
    -- Sempre seleciona o início e fim do ano
    vAnoMesFim := to_char(pFolha.NuAnoReferencia) || '12';
    vAnoMesIni := to_char(pFolha.NuAnoReferencia) || '01';

    vnurubrica := PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).nurubrica;

    vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                                   pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                                   pCdRelacaoVinculo     => PKGPAG_VAR.vgCEF(1).CdRelacaoVinculo);

    vformexpr := PKGPAG_VAR.vgformexpr(vCdExpressaoFormCalc);

    BEGIN

      select p.cdfolhapagamento
        into pCdFolhaPagamento13Normal
        from ECalFolhaPag p
       inner join epagtipofolhapagamento pp
          on p.cdtipofolhapagamento = pp.cdtipofolhapagamento
       where p.nuanomesreferencia = pfolha.NuAnoReferencia * 100 + pFolha.NuMesReferencia
         and p.cdorgao = pfolha.cdorgao
         AND p.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
         and p.cdagrupamento = pfolha.cdagrupamento
         and pp.cdtipofolha = 1 -- normal
         and p.cdtipocalculo = 1; -- normal

      vValorSoma := 0;

      FOR RUB IN
        (SELECT *
                    FROM epaghistoricorubricarelvinc hrv
                   INNER JOIN ECalFolhaPag fp
                      ON hrv.cdfolhapagamento = fp.cdfolhapagamento
                     AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                   INNER JOIN epagtipofolhapagamento tfp
                      ON fp.cdtipofolhapagamento = tfp.cdtipofolhapagamento
                   WHERE HRV.CdVinculo = pCdVinculo
                     AND FP.CdTipoCalculo IN (1, 5)
                     AND HRV.Vlindicerubrica IS NOT NULL
             AND FP.Nuanomesreferencia between vAnoMesIni and vAnoMesFim
                     AND FP.FlCalculoDefinitivo = 'S'
                     AND TFP.CdTipoFolha = 1 -- normal
                        --OR (FP.NuMesReferencia = pFolha.NuMesReferencia AND TFP.CdTipoFolha = 1))
                     AND HRV.CdRubricaAgrupamento = pcdrubricaagrupamento)

       LOOP

        vPagCalc.cdvinculo                     := RUB.Cdvinculo;
        vPagCalc.cdrubricaagrupamento          := RUB.cdrubricaagrupamento;
        vPagCalc.cdexpressaoformcalc           := vcdexpressaoformcalc;
        vPagCalc.cdvantagempecuniaria          := RUB.cdvantagempecuniaria;
        vPagCalc.cdrubricatotalizadoravantagem := RUB.cdrubricatotalizadoravantagem;
        vPagCalc.cdincorporacaoativo           := RUB.cdincorporacaoativo;
        vPagCalc.vlminrecebincorp              := RUB.vlminrecebincorp;
        vPagCalc.cdrelacaovinculo              := RUB.cdrelacaovinculo;
        vPagCalc.cdchave                       := RUB.cdchave;
        vPagCalc.vlindicerubrica               := RUB.vlindicerubrica;
        vPagCalc.cdtipohistorico               := 1;
        vPagCalc.cdhistcargoefetivo            := RUB.cdhistcargoefetivo;
        vPagCalc.cdhistfuncaochefia            := RUB.cdhistfuncaochefia;
        vPagCalc.cdhistcargocom                := RUB.cdhistcargocom;
        vPagCalc.cdconcessaoaposentadoria      := RUB.cdconcessaoaposentadoria;
        vPagCalc.cdhistestagio                 := RUB.cdhistestagio;
        vPagCalc.cdhistpensaoprevidenciaria    := RUB.cdhistpensaoprevidenciaria;
        vPagCalc.cdhistpensaonaoprev           := RUB.cdhistpensaonaoprev;
        vPagCalc.cdhistpensaoexparlamentar     := RUB.cdhistpensaoexparlamentar;
        vPagCalc.dtiniciorelacao               := RUB.dtiniciorelacao;
        vPagCalc.dtdesligamento                := RUB.dtdesligamento;
        vPagCalc.cdunidadeorganizacional       := RUB.cdunidadeorganizacional;
        vPagCalc.cdlancamentofinanceiro        := NULL;
        vPagCalc.dtinicio                      := RUB.dtinicio;
        vPagCalc.dtfim                         := RUB.dtfim;
        vPagCalc.nusufixorubrica               := RUB.Numesreferencia;
        vPagCalc.vlindicereal                  := RUB.vlindicereal;

        pkgpag_fb.pprocformulacalculo(pfolha        => pFolha,
                                      ppagcalc      => vPagCalc,
                                      pexprform     => vFormExpr,
                                      pRetornaValor => 'S',
                                      pCdFolhaAnt   => pCdFolhaPagamento13Normal);

        vValorSoma := vValorSoma + NVL(vVlFormula.vlProporcional, 0);

      END LOOP;

    END;

    RETURN NVL(vValorSoma / 12, 0);

  EXCEPTION

    WHEN NO_DATA_FOUND

     THEN
      RETURN 0;

    WHEN OTHERS
       THEN
      RETURN 0;

  END;

  --
  -- Calcular o valor medio da rubrica com base na media do indice e com base no periodo aquisitivo de ferias
  --

  --
  -- Calcular a Soma de uma Rubrica no periodo de 12 meses
  --
  FUNCTION fMneSoma12Meses(pcdvinculo            IN INTEGER,
                           pcdrubricaagrupamento IN INTEGER,
                           pfolha                in pkgpag_tipo.rFolha)

   RETURN NUMBER IS

    vValorSoma NUMBER(13, 4);

    vAnoMesIni CHAR(6);

    vAnoMesFim CHAR(6);

    vNuRubrica INTEGER;

    v1 INTEGER;

    v2 INTEGER;

    v3 INTEGER;

  BEGIN
 
    IF  PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 1
      THEN

      v1 := 1;
      v2 := 2;
      v3 := 3;

      ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 5
         THEN

      v1 := 5;
      v2 := 6;
      v3 := 7;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 8 THEN

      v1 := 8;
      v2 := 8;
      v3 := 8;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 9 THEN

      v1 := 9;
      v2 := 9;
      v3 := 9;

    else
      null;
    END IF;

    vAnoMesFim := to_char(add_months(pFolha.DtCalculo, -1), 'YYYYMM');

    vAnoMesIni := to_char(add_months(pFolha.DtCalculo, -12), 'YYYYMM');

    vNuRubrica := PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).nurubrica;

    BEGIN

      WITH FOLHA AS
      -- Folhas definitivas de 12 meses do orgao
       (select paga20.cdfolhapagamento
          FROM ECalFolhaPag PAGA20
         WHERE PAGA20.Cdorgao = pFolha.CdOrgao
           AND paga20.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
           AND paga20.nuanomesreferencia between vAnoMesIni and vAnoMesFim
           AND paga20.flcalculodefinitivo = 'S'
            AND paga20.cdtipocalculo in (PKGPAG_TIPO.cnTpCalculoNormal,PKGPAG_TIPO.cnTpCalculoSupl)
           AND paga20.Cdtipofolhapagamento = 2),

      RUB AS
       (SELECT ra.CdRubricaAgrupamento
          FROM epagrubricaagrupamento ra
            INNER JOIN epagrubrica r ON RA.CDRUBRICA = r.cdrubrica
         WHERE R.NuRubrica = vNuRubrica
           AND R.CdTipoRubrica IN (v1, v2, v3)
           AND RA.CdAgrupamento = pFolha.CdAgrupamento)

      SELECT SUM(hrv.vlpagamento) AS vlpagamento
        INTO vValorSoma
        FROM epaghistoricorubricavinculo hrv
          INNER JOIN FOLHA F ON hrv.cdfolhapagamento = f.cdfolhapagamento
          INNER JOIN RUB R on hrv.cdrubricaagrupamento = R.cdrubricaagrupamento
       WHERE HRV.CdVinculo = pCdVinculo;

    END;

    RETURN NVL(vValorSoma, 0);

  EXCEPTION

    WHEN NO_DATA_FOUND

     THEN
      RETURN 0;

    WHEN OTHERS
       THEN
      RETURN 0;

  END;

  -- Soma Ano real somente da rubrica informada para o vinculo no mesmo orgao
  FUNCTION fMneSomaAnoRubrica(pcdvinculo            IN INTEGER,
                              pcdrubricaagrupamento IN INTEGER,
                              pfolha                in pkgpag_tipo.rFolha)

   RETURN NUMBER IS

    vValorSoma NUMBER(13, 4);

    vAnoMesIni CHAR(6);

    vAnoMesFim CHAR(6);

  BEGIN
 
    vAnoMesFim := pFolha.NuAnoReferencia || '12';

    vAnoMesIni := pFolha.NuAnoReferencia || '01';

    WITH FOLHA AS
    -- Folhas definitivas do ano no mesmo orgao
     (select paga20.cdfolhapagamento, PAGA20.Numesreferencia
        FROM ECalFolhaPag PAGA20
           INNER JOIN epagtipofolhapagamento etp on paga20.cdtipofolhapagamento = etp.cdtipofolhapagamento
       WHERE PAGA20.Cdorgao = pFolha.CdOrgao
         AND paga20.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
         AND paga20.nuanomesreferencia between vAnoMesIni and vAnoMesFim
            AND ETP.CDTIPOFOLHA in (pkgpag_tipo.cnTpFolhaNormal, pkgpag_tipo.cnTpFolhaCtisp)
            AND paga20.cdtipocalculo in (PKGPAG_TIPO.cnTpCalculoNormal,PKGPAG_TIPO.cnTpCalculoSupl)
         AND paga20.flcalculodefinitivo = 'S')

    SELECT SUM(hrv.vlpagamento) AS vlpagamento
      INTO vValorSoma
      FROM epaghistoricorubricavinculo hrv
          INNER JOIN FOLHA F ON hrv.cdfolhapagamento = f.cdfolhapagamento
     WHERE HRV.CdVinculo = pCdVinculo
       and hrv.cdrubricaagrupamento = pcdrubricaagrupamento
       and hrv.cdfolhapagamento <> pfolha.CdFolhaPagamento
            and ((pFolha.CdTipoFolha IN (PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolha13) and numesreferencia <> pFolha.NuMesReferencia) or
           (pFolha.CdTipoFolha NOT IN (PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolha13)));

    RETURN NVL(vValorSoma, 0);

  EXCEPTION

    WHEN NO_DATA_FOUND

     THEN
      RETURN 0;

    WHEN OTHERS
       THEN
      RETURN 0;

  END;

  FUNCTION fMneSomaOutrasFolhasMes(pcdvinculo            IN INTEGER,
                                   pcdrubricaagrupamento IN INTEGER,
                                   pfolha                in pkgpag_tipo.rFolha,
                                   pFlMesAnterior        in char default null)

   RETURN NUMBER IS

    vValorSoma NUMBER(13, 4);

    vNuRubrica INTEGER;

    v1 INTEGER;

    v2 INTEGER;

    v3 INTEGER;

  BEGIN
     vNuRubrica := PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).nurubrica;

    IF  PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 1
      THEN

      v1 := 1;
      v2 := 2;
      v3 := 3;

      ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 5
         THEN

      v1 := 5;
      v2 := 6;
      v3 := 7;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 8 THEN

      v1 := 8;
      v2 := 8;
      v3 := 8;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 9 THEN

      v1 := 9;
      v2 := 9;
      v3 := 9;

    else
      null;
    END IF;

    if pFlMesAnterior = 'S' then

      BEGIN

          WITH
            FOLHAANT as
            (select paga20.cdfolhapagamento, paga20.cdorgao, paga20.nuanoreferencia, paga20.numesreferencia
            FROM ECalFolhaPag PAGA20
           WHERE paga20.cdfolhapagamento = pFolha.CdFolhaPagamentoNormalAnt
             AND paga20.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
           ),
        FOLHA AS
         (select paga20.cdfolhapagamento, paga20.cdorgao
            FROM ECalFolhaPag PAGA20
               inner join FolhaAnt fa on fa.cdorgao = paga20.cdorgao
           WHERE paga20.nuanoreferencia = fa.NuAnoReferencia
             AND paga20.numesreferencia = fa.NuMesReferencia
             AND paga20.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
             AND paga20.flcalculodefinitivo = 'S'
                AND paga20.cdtipocalculo in (PKGPAG_TIPO.cnTpCalculoNormal,PKGPAG_TIPO.cnTpCalculoSupl)),

        RUB AS
         (SELECT CdRubricaAgrupamento
            FROM epagrubricaagrupamento ra
                INNER JOIN epagrubrica r ON RA.CDRUBRICA = r.cdrubrica
           WHERE R.NuRubrica = vNuRubrica
             AND R.CdTipoRubrica IN (v1, v2, v3)
             AND RA.CdAgrupamento = pFolha.CdAgrupamento)
        SELECT SUM(hrv.vlpagamento) AS vlpagamento
          INTO vValorSoma
          FROM epaghistoricorubricavinculo hrv
              INNER JOIN FOLHA F ON hrv.cdfolhapagamento = f.cdfolhapagamento
              INNER JOIN RUB R on hrv.cdrubricaagrupamento = R.cdrubricaagrupamento
         WHERE HRV.CdVinculo = pCdVinculo;

      END;

    else

      BEGIN

        WITH FOLHA AS
         (select paga20.cdfolhapagamento
            FROM ECalFolhaPag PAGA20
           WHERE PAGA20.Cdorgao = pFolha.CdOrgao
             AND paga20.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
             AND paga20.nuanoreferencia = pfolha.NuAnoReferencia
             AND paga20.numesreferencia = pfolha.NuMesReferencia
             AND paga20.flcalculodefinitivo = 'S'
                AND paga20.cdtipocalculo in (PKGPAG_TIPO.cnTpCalculoNormal,PKGPAG_TIPO.cnTpCalculoSupl)
             AND paga20.Cdtipofolhapagamento <> pfolha.CdTipoFolhaPagamento),

        RUB AS
         (SELECT ra.CdRubricaAgrupamento
            FROM epagrubricaagrupamento ra
                INNER JOIN epagrubrica r ON RA.CDRUBRICA = r.cdrubrica
           WHERE R.NuRubrica = vNuRubrica
             AND R.CdTipoRubrica IN (v1, v2, v3)
             AND RA.CdAgrupamento = pFolha.CdAgrupamento)

        SELECT SUM(hrv.vlpagamento) AS vlpagamento
          INTO vValorSoma
          FROM epaghistoricorubricavinculo hrv
              INNER JOIN FOLHA F ON hrv.cdfolhapagamento = f.cdfolhapagamento
              INNER JOIN RUB R on hrv.cdrubricaagrupamento = R.cdrubricaagrupamento
         WHERE HRV.CdVinculo = pCdVinculo;

      END;

    end if;

    RETURN NVL(vValorSoma, 0);

  EXCEPTION

    WHEN NO_DATA_FOUND

     THEN
      RETURN 0;

    WHEN OTHERS
       THEN
      RETURN 0;

  END;

  FUNCTION fMneSomaRubMes(pcdvinculo            IN INTEGER,
                          pcdrubricaagrupamento IN INTEGER,
                          pfolha                in pkgpag_tipo.rFolha)

   RETURN NUMBER IS

    vValorSoma NUMBER(13, 4);

    vNuRubrica INTEGER;

    v1 INTEGER;

    v2 INTEGER;

    v3 INTEGER;

  BEGIN
     vNuRubrica := PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).nurubrica;

    IF  PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 1
      THEN

      v1 := 1;
      v2 := 2;
      v3 := 3;

      ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 5
         THEN

      v1 := 5;
      v2 := 6;
      v3 := 7;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 8 THEN

      v1 := 8;
      v2 := 8;
      v3 := 8;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 9 THEN

      v1 := 9;
      v2 := 9;
      v3 := 9;

    else
      null;
    END IF;

    BEGIN

      WITH FOLHA AS
       (select paga20.cdfolhapagamento
          FROM ECalFolhaPag PAGA20
         WHERE PAGA20.Cdorgao = pFolha.CdOrgao
           AND paga20.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
           AND paga20.nuanoreferencia = pfolha.NuAnoReferencia
           AND paga20.numesreferencia = pfolha.NuMesReferencia
           AND paga20.flcalculodefinitivo = pfolha.FlCalculoDefinitivo
              AND paga20.cdtipocalculo in (PKGPAG_TIPO.cnTpCalculoNormal,PKGPAG_TIPO.cnTpCalculoSupl)
           AND paga20.Cdtipofolhapagamento = pfolha.CdTipoFolhaPagamento),

      RUB AS
       (SELECT ra.CdRubricaAgrupamento
          FROM epagrubricaagrupamento ra
              INNER JOIN epagrubrica r ON RA.CDRUBRICA = r.cdrubrica
         WHERE R.NuRubrica = vNuRubrica
           AND R.CdTipoRubrica IN (v1, v2, v3)
           AND RA.CdAgrupamento = pFolha.CdAgrupamento)

      SELECT SUM(hrv.vlpagamento) AS vlpagamento
        INTO vValorSoma
        FROM epaghistoricorubricavinculo hrv
            INNER JOIN FOLHA F ON hrv.cdfolhapagamento = f.cdfolhapagamento
            INNER JOIN RUB R on hrv.cdrubricaagrupamento = R.cdrubricaagrupamento
       WHERE HRV.CdVinculo = pCdVinculo;

    END;

    

    RETURN NVL(vValorSoma, 0);

  EXCEPTION

    WHEN NO_DATA_FOUND

     THEN
      RETURN 0;

    WHEN OTHERS
       THEN
      RETURN 0;

  END;

  -- Media dos valores recebidos nas rubricas 01-ll5 e 10-1015
  -- nas ultimas 12 folhas, contando a partir da folha anterior
  -- ao afastamento do servidor, ha 2 meses atras
  FUNCTION FMneMediaGratEspecSaude(pcdvinculo          IN INTEGER,
                                   pnuanomesreferencia IN INTEGER)
    RETURN NUMBER IS
    vvlmedia NUMBER(13, 2);

  BEGIN
 
    with folha as (
      select fp.cdfolhapagamento
        from ECalFolhaPag fp
      inner join ecadorgao o on o.cdorgao = fp.cdorgao
       where o.cdagrupamento = 1
      and fp.nuanomesreferencia
          between to_number(TO_CHAR(ADD_MONTHS(TO_DATE(pnuanomesreferencia,'YYYYMM'),-14),'YYYYMM'))
          and     to_number(TO_CHAR(ADD_MONTHS(TO_DATE(pnuanomesreferencia,'YYYYMM'),-3),'YYYYMM'))
      AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
      and fp.flcalculodefinitivo = 'S'
    ),
    rubrica as (
      select r.cdrubricaagrupamento
        from vpagrubricaagrupamento r
       where r.cdtiporubrica in (1, 10)
         and r.nurubrica = 1015
      and   r.cdagrupamento = 1
    ),
    contracheque as (
      select hrv.vlpagamento
        from epaghistoricorubricavinculo hrv
       where hrv.cdvinculo = pcdvinculo
      and   hrv.cdfolhapagamento in (select folha.cdfolhapagamento from folha)
      and   hrv.cdrubricaagrupamento in (select rubrica.cdrubricaagrupamento from rubrica)
    )
    select sum(contracheque.vlpagamento) / 12 as "media"
      into vvlmedia
      from contracheque;

    RETURN vvlmedia;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  ----------------------------------------------------------------
  -- pTpRetorno       pTpIndice
  -- 1 - Valor        1 - Valor
  -- 2 - Indice       2 - Hora/Minuto
  ----------------------------------------------------------------

  FUNCTION fmnemediatempo(pcdvinculo            IN INTEGER,
                          pnuanoreferencia      IN INTEGER,
                          pnumesreferencia      IN INTEGER,
                          pcdtipohistorico      IN INTEGER,
                          pcdrelacaovinculo     IN INTEGER,
                          pcdchave              IN INTEGER,
                          pcdagrupamento        IN INTEGER,
                          pcdrubricaagrupamento IN INTEGER,
                          pnumesesretroativos   IN INTEGER,
                          ptpretorno            IN INTEGER DEFAULT 1,
                          pflhoraminuto         IN CHAR DEFAULT 'N',
                          pRetornaMinutos       IN CHAR DEFAULT 'N')

   RETURN NUMBER IS

    vvlpagamento NUMBER(13, 2);

    vvlindice NUMBER(13, 4);

    vVlHora INTEGER := 0;

    vVlMinuto INTEGER := 0;

    vnurubrica INTEGER;

    v1 INTEGER;

    v2 INTEGER;

    vnuanomesinicio INTEGER;

    vnuanomesfim INTEGER;

  BEGIN
 
    vnurubrica := PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).nurubrica;

    IF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 1 THEN

      -- Caso o tipo de retorno seja por valor (1), soma os iniciais 1 e 2
      IF ptpretorno = 1 THEN

       v1:= 1; v2:= 2;

      ELSE

        -- Caso o tipo de retorno seja por ?ndice (2), soma apenas o inicial 1

      v1:= 1; v2:= 1;

      END IF;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 2
         and PKGPAG_VAR.vgFolha.CdAgrupamento = 4 THEN

      v1:= 2; v2 :=2;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 5 THEN

      -- Caso o tipo de retorno seja por valor (1), soma os iniciais 5 e 6
      IF ptpretorno = 1 THEN

      v1:= 5; v2:= 6;

      ELSE

        -- Caso o tipo de retorno seja por ?ndice (2), soma apenas o inicial 5

      v1:= 5; v2:= 5;

      END IF;

    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 9 THEN

     v1:= 9;  v2:= 9;
     
    ELSIF PKGPAG_VAR.vgrubrica(pcdrubricaagrupamento).cdtiporubrica = 8 THEN

     v1:= 8;  v2:= 8; 
      
    ELSE
      
      NULL;
      
    END IF;

    ----------------------------------------------------------------------------
    -- Alimenta as vari?veis vNuAnoMesInicio e vNuAnoMesFim
    -- vNuAnoMesFim recebe o ano/mes anterior ao mes de processamento
    -----------------------------------------------------------------------------

    IF pnumesesretroativos > 1 THEN

      vNuAnoMesInicio := to_number(TO_CHAR(ADD_MONTHS(TO_DATE(to_char(pNuAnoReferencia * 100 + pNuMesReferencia),'YYYYMM'), -(pNuMesesRetroativos-1)),'YYYYMM'));

      --Ajuste periodo aquisitivo CIDASC
      IF pcdagrupamento = 4 THEN
        
        vNuAnoMesFim := to_number(TO_CHAR(TO_DATE(to_char(pNuAnoReferencia * 100 + pNuMesReferencia),'YYYYMM'),'YYYYMM'));

      ELSE
        
        vNuAnoMesFim := to_number(TO_CHAR(ADD_MONTHS(TO_DATE(to_char(pNuAnoReferencia * 100 + pNuMesReferencia),'YYYYMM'), -1),'YYYYMM'));
        
      END IF;

    ELSE

      vNuAnoMesInicio := to_number(TO_CHAR(to_char(pNuAnoReferencia * 100 + pNuMesReferencia),'YYYYMM'));

      vNuAnoMesFim := to_number(TO_CHAR(to_char(pNuAnoReferencia * 100 + pNuMesReferencia),'YYYYMM'));

    END IF;
    
    PVerificarFolPag (pNuAnoMesIni => vNuAnoMesInicio);

    --------------------------------------------------------------------------------------
    -- A leitura est? sendo feita no vinculo pois n?o exitem
    -- registros de rela??o de v?nculo em org?os implantados durante o ano 2011 (vide SSP)
    -- Pela mesma raz?o a leitura ? feita apenas na rela??o de v?nculo principal quando o tipo
    -- de retorno ? valor. Quando o valor for retorno ?ndice l? para todas
    --------------------------------------------------------------------------------------

    IF (pcdtipohistorico = 1 AND ptpretorno = 1 AND pcdrelacaovinculo = PKGPAG_VAR.vgrelvincprincipal.tipo AND pCdChave = PKGPAG_VAR.vgRelVincPrincipal.CdHist) 
       OR
       pTpRetorno = 2 
       OR
       pcdtipohistorico = 2 THEN

      IF pRetornaMinutos = 'S' THEN

        SELECT SUM(trunc(hrv.vlindicerubrica / 100, 0) * 60),
               SUM (MOD(vlIndicerubrica, trunc(hrv.vlindicerubrica / 100,0) * 100)),
               SUM(hrv.vlpagamento) AS vlpagamento
          INTO vVlHora,
               vVlMinuto,
               vvlpagamento
          FROM epaghistoricorubricavinculo hrv
         INNER JOIN ECalFolhaPag fp
            ON hrv.cdfolhapagamento = fp.cdfolhapagamento
           AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
         INNER JOIN epagtipofolhapagamento tfp
            ON fp.cdtipofolhapagamento = tfp.cdtipofolhapagamento
         INNER JOIN epagrubricaagrupamento ra
            ON ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
         INNER JOIN ecadorgao o
            ON o.cdorgao = fp.cdorgao
         WHERE HRV.CdVinculo = pCdVinculo AND
               FP.CdTipoCalculo IN (1, 5) AND
               ((FP.FlCalculoDefinitivo = 'S' AND
               FP.NuAnoMesReferencia BETWEEN vNuAnoMesInicio AND vNuAnoMesFim) OR
               (FP.NuAnoReferencia = pNuAnoReferencia AND
               FP.NuMesReferencia = pNuMesReferencia AND TFP.CdTipoFolha = 1)) AND
               HRV.CdRubricaAgrupamento  IN (SELECT CdRubricaAgrupamento
                  FROM epagrubricaagrupamento ra
                 INNER JOIN epagrubrica r
                    ON ra.cdrubrica = r.cdrubrica
                                              WHERE R.NuRubrica = vNuRubrica AND
                                              R.CdTipoRubrica IN (v1, v2) AND
                                              RA.CdAgrupamento = pCdAgrupamento);

        vvlindice := vVlHora + vVlMinuto;

      ELSE
        
        SELECT SUM(hrv.vlpagamento) AS vlpagamento,
               SUM(
               CASE pFlHoraMinuto
                     WHEN 'N' THEN
                      hrv.vlindicerubrica
                     ELSE
                      CASE
                        WHEN o.nuanomesimplantacao <= fp.nuanomesreferencia THEN
                     TO_NUMBER(TRUNC((HRV.VlIndiceRubrica/POWER(10,LENGTH(LPAD(HRV.VlIndiceRubrica,4,'0'))-2)))||'.'||
                               LPAD(TRUNC((HRV.VlIndiceRubrica-TRUNC(HRV.VlIndiceRubrica,-2))/60*100),2,'0'))
                 ELSE
                      TO_NUMBER(TRUNC((HRV.VlIndiceRubrica*100/POWER(10,LENGTH(LPAD(HRV.VlIndiceRubrica*100,4,'0'))-2)))||'.'||
                               LPAD(TRUNC((HRV.VlIndiceRubrica*100-TRUNC(HRV.VlIndiceRubrica*100,-2))/60*100),2,'0'))
                      END
                   END) AS vlindice
          INTO vVlPagamento,
               vVlIndice
          FROM epaghistoricorubricavinculo hrv
         INNER JOIN ECalFolhaPag fp
            ON hrv.cdfolhapagamento = fp.cdfolhapagamento
           AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
         INNER JOIN epagtipofolhapagamento tfp
            ON fp.cdtipofolhapagamento = tfp.cdtipofolhapagamento
         INNER JOIN epagrubricaagrupamento ra
            ON ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
         INNER JOIN ecadorgao o
            ON o.cdorgao = fp.cdorgao
         WHERE HRV.CdVinculo = pCdVinculo AND
               FP.CdTipoCalculo IN (1, 5) AND
               ((FP.FlCalculoDefinitivo = 'S' AND
               FP.NuAnoMesReferencia BETWEEN vNuAnoMesInicio AND vNuAnoMesFim) OR
               (FP.NuAnoReferencia = pNuAnoReferencia AND
               FP.NuMesReferencia = pNuMesReferencia AND TFP.CdTipoFolha = 1)) AND
               HRV.CdRubricaAgrupamento  IN (SELECT CdRubricaAgrupamento
                  FROM epagrubricaagrupamento ra
                 INNER JOIN epagrubrica r
                    ON ra.cdrubrica = r.cdrubrica
                                              WHERE R.NuRubrica = vNuRubrica AND
                                              R.CdTipoRubrica IN (v1, v2) AND
                                              RA.CdAgrupamento = pCdAgrupamento);

      END IF;

    END IF;

    IF ptpretorno = 1 THEN

      RETURN nvl(vvlpagamento, 0.0) / pnumesesretroativos;

    ELSE
      
      -- Implantacao da CIDASC - Rubrica 01-0373
      IF pCdAgrupamento = 4 AND vNuRubrica = 373 THEN
        
        RETURN nvl(vvlpagamento, 0.0) / pnumesesretroativos;
        
      END IF;

      RETURN nvl(vvlindice, 0.0) / pnumesesretroativos;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  -----------------------------------------------------------------
  --
  -----------------------------------------------------------------

  FUNCTION fmnemediaferiasatual(pcdvinculo            IN INTEGER,
                                pcdtipohistorico      IN INTEGER,
                                pcdrelacaovinculo     IN INTEGER,
                                pcdchave              IN INTEGER,
                                pcdagrupamento        IN INTEGER,
                                pcdrubricaagrupamento IN INTEGER)

   RETURN NUMBER IS

    vnuano INTEGER;

    vnumes INTEGER;

    vnumeses INTEGER;

    vvlcalculado NUMBER(13, 2);

  BEGIN
 
    vvlcalculado := 0;

    SELECT to_number(to_char(paf.dtfim, 'YYYY')),
           to_number(to_char(paf.dtfim, 'MM')),
           months_between(trunc(dtfim, 'MM'), trunc(dtinicio, 'MM'))
      INTO vNuAno,
           vNuMes,
           vNuMeses
      FROM emovperiodoaquisitivoferias paf
     WHERE PAF.CdVinculo =  pCdVinculo AND
           PAF.CdSituacaoPeriodoAqFerias = 1 AND -- Conquistado
           rownum < 2;

    IF vnumeses > 0 THEN

      vvlcalculado := fmnemediatempo(pcdvinculo            => pcdvinculo,
                                     pnuanoreferencia      => vnuano,
                                     pnumesreferencia      => vnumes,
                                     pcdtipohistorico      => pcdtipohistorico,
                                     pcdrelacaovinculo     => pcdrelacaovinculo,
                                     pcdchave              => pcdchave,
                                     pcdagrupamento        => pcdagrupamento,
                                     pcdrubricaagrupamento => pcdrubricaagrupamento,
                                     pnumesesretroativos   => vnumeses,
                                     pTpRetorno            => 2,
                                     pFlHoraMinuto         => 'S');

    END IF;

    RETURN vvlcalculado;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  -----------------------------------------------------------------
  --
  -----------------------------------------------------------------

  FUNCTION fmnemediaferiasanterior(pcdvinculo            IN INTEGER,
                                   pcdtipohistorico      IN INTEGER,
                                   pcdrelacaovinculo     IN INTEGER,
                                   pcdchave              IN INTEGER,
                                   pcdagrupamento        IN INTEGER,
                                   pcdrubricaagrupamento IN INTEGER,
                                   pnuomes               IN INTEGER,
                                   pnuano                IN INTEGER,
                                   pRetornaMinutos       IN CHAR DEFAULT 'N')

   RETURN NUMBER IS

    vnuano       INTEGER;
    vnumes       INTEGER;
    vnumeses     INTEGER;
    vvlcalculado NUMBER(13, 2);
    vdtfim       DATE;

  BEGIN
 
    vvlcalculado := 0;

    SELECT paf.dtfim,
           months_between(trunc(dtfim, 'MM'), trunc(dtinicio, 'MM'))
      INTO vdtfim, vNuMeses
      FROM (SELECT PA.DtFim, PA.DtInicio
              FROM emovperiodoaquisitivoferias pa
             INNER JOIN emovferiasfruicaopagamento ffp
                on ffp.cdperiodoaquisitivoferias =
                   pa.cdperiodoaquisitivoferias
             INNER JOIN emovferiasfruicaousufruto usu
                ON PA.CdPeriodoAquisitivoFerias =
                   USU.CdPeriodoAquisitivoFerias
             WHERE PA.CdVinculo = pCdVinculo
               AND USU.FlAnulado = PKGPAG_TIPO.cnN
               AND
                  --USU.DtInicial BETWEEN  pfolha.dtiniciomes AND  pfolha.DtFimMes AND
                   ffp.nuanoreferencia = pnuano
               AND ffp.numesreferencia = pnuomes
               AND ROWNUM < 2) PAF
     WHERE rownum < 2;

    vNuAno := to_number(to_char(trunc(vdtfim, 'MM'), 'YYYY'));
    vNuMes := to_number(to_char(trunc(vdtfim, 'MM'), 'MM'));

    IF vnumeses > 0 THEN

      IF pRetornaMinutos = 'S'
       THEN
        vNuMeses := 12;
      END IF;

      -- pTpRetorno
      -- 1 - Valor
      -- 2 - Indice

      vvlcalculado := fmnemediatempo(pcdvinculo            => pcdvinculo,
                                     pnuanoreferencia      => vnuano,
                                     pnumesreferencia      => vnumes,
                                     pcdtipohistorico      => pcdtipohistorico,
                                     pcdrelacaovinculo     => pcdrelacaovinculo,
                                     pcdchave              => pcdchave,
                                     pcdagrupamento        => pcdagrupamento,
                                     pcdrubricaagrupamento => pcdrubricaagrupamento,
                                     pnumesesretroativos   => vnumeses,
                                     pTpRetorno            => 2,
                                     pFlHoraMinuto         => 'S',
                                     pRetornaMinutos       => pRetornaMinutos); -- ?ndice

    END IF;

    RETURN vvlcalculado;

  EXCEPTION

    WHEN no_data_found THEN

      RETURN 0;

  END;

  FUNCTION fMneMediaFerias(pcdvinculo            IN INTEGER,
                           pcdtipohistorico      IN INTEGER,
                           pcdrelacaovinculo     IN INTEGER,
                           pcdchave              IN INTEGER,
                           pcdrubricaagrupamento IN INTEGER,
                           pfolha                in pkgpag_tipo.rFolha)

   RETURN NUMBER IS

    --vnurubrica INTEGER;

    vVlCalculado pkgpag_tipo.rValorPagamento;

    vCdExpressaoFormCalc INTEGER;

    vPagCalc pkgpag_tipo.rPagCalc;

    vformexpr pkgpag_tipo.rformulacalculo;

    vVlIndice NUMBER(13, 2);

    --vVlHora INTEGER;

    --vVlMinuto NUMBER (13,2);

    --vInteiro INTEGER;

  BEGIN
 
    pkgpag_param.PArmazenaInfoFolhaAuxiliar(pFolha.CdFolhaPagamentoNormalAnt);

    vVlCalculado.vlProporcional :=
                pkgpag_fb.FMneMediaFeriasAnterior(pCdVinculo,
                                                                     pcdtipohistorico,
                                                                     pcdrelacaovinculo,
                                                                     pcdchave,
                                                                     pfolha.cdagrupamento,
                                                                     pCdRubricaAgrupamento,
                                                                     pfolha.NuMesReferencia,
                                                                     pfolha.NuAnoReferencia,
                                                                     'S');

    IF vVlCalculado.vlProporcional = 0
      THEN
      RETURN 0;
    END IF;

    -- Implantacao da CIDASC - Rubrica 01-0373
    IF pFOlha.CdAgrupamento = 4 AND PKGPAG_VAR.vgrubrica(pCdRubricaAgrupamento).nurubrica = 373
      THEN
      RETURN TRUNC(vVlCalculado.vlProporcional, 2);
    END IF;
    --
    -- Ajustar horas e minutos da media
    --

    vVlIndice := TRUNC(vVlCalculado.vlProporcional / 60, 2);

    vCdExpressaoFormCalc := PKGPAG_GERAL.FIdentificaFormulaCalculo(
                                    pFormExpr                 => PKGPAG_VAR.vgFormExpr,
                                                                   pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                                   pCdRelacaoVinculo     => PKGPAG_VAR.vgCEF(1).CdRelacaoVinculo);

    vformexpr := PKGPAG_VAR.vgformexpr(vCdExpressaoFormCalc);

    FOR RUB IN
        (SELECT *
                  FROM epaghistoricorubricarelvinc hrv
                 INNER JOIN ECalFolhaPag fp
                    ON hrv.cdfolhapagamento = fp.cdfolhapagamento
                   AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                 WHERE HRV.CdVinculo = pCdVinculo
                   AND HRV.CDFOlhapagamento = pFolha.CdFolhaPagamento
                   AND ROWNUM < 2)

     LOOP

      vPagCalc.cdvinculo                     := RUB.Cdvinculo;
      vPagCalc.cdrubricaagrupamento          := pcdrubricaagrupamento;
      vPagCalc.cdexpressaoformcalc           := vcdexpressaoformcalc;
      vPagCalc.cdvantagempecuniaria          := RUB.cdvantagempecuniaria;
      vPagCalc.cdrubricatotalizadoravantagem := RUB.cdrubricatotalizadoravantagem;
      vPagCalc.cdincorporacaoativo           := RUB.cdincorporacaoativo;
      vPagCalc.vlminrecebincorp              := RUB.vlminrecebincorp;
      vPagCalc.cdrelacaovinculo              := RUB.cdrelacaovinculo;
      vPagCalc.cdchave                       := RUB.cdchave;
      vPagCalc.vlindicerubrica               := vVlIndice;
      vPagCalc.cdtipohistorico               := 1;
      vPagCalc.cdhistcargoefetivo            := RUB.cdhistcargoefetivo;
      vPagCalc.cdhistfuncaochefia            := RUB.cdhistfuncaochefia;
      vPagCalc.cdhistcargocom                := RUB.cdhistcargocom;
      vPagCalc.cdconcessaoaposentadoria      := RUB.cdconcessaoaposentadoria;
      vPagCalc.cdhistestagio                 := RUB.cdhistestagio;
      vPagCalc.cdhistpensaoprevidenciaria    := RUB.cdhistpensaoprevidenciaria;
      vPagCalc.cdhistpensaonaoprev           := RUB.cdhistpensaonaoprev;
      vPagCalc.cdhistpensaoexparlamentar     := RUB.cdhistpensaoexparlamentar;
      vPagCalc.dtiniciorelacao               := RUB.dtiniciorelacao;
      vPagCalc.dtdesligamento                := RUB.dtdesligamento;
      vPagCalc.cdunidadeorganizacional       := RUB.cdunidadeorganizacional;
      vPagCalc.cdlancamentofinanceiro        := NULL;
      vPagCalc.dtinicio                      := RUB.dtinicio;
      vPagCalc.dtfim                         := RUB.dtfim;
      vPagCalc.nusufixorubrica               := RUB.Numesreferencia;
      vPagCalc.vlindicereal                  := vVlIndice;

      pkgpag_fb.pprocformulacalculo(pfolha        => PKGPAG_VAR.vgFolhaAuxiliar,
                                    ppagcalc      => vPagCalc,
                                    pexprform     => vFormExpr,
                                    pRetornaValor => 'S',
                                    pCdMnemonico  => 9);

    END LOOP;

    return nvl(vVlFormula.vlProporcional, 0);

  END;

  FUNCTION fMneVlRubMediaFerias(pcdvinculo            IN INTEGER,
                                pcdtipohistorico      IN INTEGER,
                                pcdrelacaovinculo     IN INTEGER,
                                pcdchave              IN INTEGER,
                                pcdrubricaagrupamento IN INTEGER,
                                pfolha                in pkgpag_tipo.rFolha,
                                pflhoraminuto         IN CHAR DEFAULT 'N')

   RETURN NUMBER IS

    vCdExpressaoFormCalc INTEGER;
    vPagCalc             pkgpag_tipo.rPagCalc;
    vformexpr            pkgpag_tipo.rformulacalculo;
    vVlIndice            NUMBER(13, 2);
    vnuano               INTEGER;
    vnumes               INTEGER;
    vnumeses             INTEGER;
    vvlcalculado         NUMBER(13, 2) := 0;
    vdtfim               DATE;

  BEGIN
 
    pkgpag_param.PArmazenaInfoFolhaAuxiliar(pFolha.CdFolhaPagamentoNormalAnt);

    SELECT paf.dtfim,
           months_between(trunc(dtfim, 'MM'), trunc(dtinicio, 'MM'))
      INTO vdtfim, vNuMeses
      FROM (SELECT PA.DtFim, PA.DtInicio
              FROM emovperiodoaquisitivoferias pa
             INNER JOIN emovferiasfruicaopagamento ffp
                on ffp.cdperiodoaquisitivoferias =
                   pa.cdperiodoaquisitivoferias
             INNER JOIN emovferiasfruicaousufruto usu
                ON PA.CdPeriodoAquisitivoFerias =
                   USU.CdPeriodoAquisitivoFerias
             WHERE PA.CdVinculo = pCdVinculo
               AND USU.FlAnulado = PKGPAG_TIPO.cnN
               AND
                  --USU.DtInicial BETWEEN  pfolha.dtiniciomes AND  pfolha.DtFimMes AND
                   ffp.nuanoreferencia = pFolha.NuAnoReferencia
               AND ffp.numesreferencia = pFolha.NuMesReferencia
               AND ROWNUM < 2) PAF
     WHERE rownum < 2;

    vNuAno := to_number(to_char(trunc(vdtfim, 'MM'), 'YYYY'));
    vNuMes := to_number(to_char(trunc(vdtfim, 'MM'), 'MM'));

    IF vnumeses > 0 THEN

      -- pTpRetorno
      -- 1 - Valor
      -- 2 - Indice

      vVlCalculado := fmnemediatempo(pcdvinculo            => pcdvinculo,
                                     pnuanoreferencia      => vnuano,
                                     pnumesreferencia      => vnumes,
                                     pcdtipohistorico      => pcdtipohistorico,
                                     pcdrelacaovinculo     => pcdrelacaovinculo,
                                     pcdchave              => pcdchave,
                                     pcdagrupamento        => pfolha.cdagrupamento,
                                     pcdrubricaagrupamento => pcdrubricaagrupamento,
                                     pnumesesretroativos   => vnumeses,
                                     pTpRetorno            => 1,
                                     pFlHoraMinuto         => 'N',
                                     pRetornaMinutos       => 'N');

    END IF;

    return nvl(vVlCalculado, 0);

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;
  END;

  -----------------------------------------------------------------
  --
  -----------------------------------------------------------------

  FUNCTION fmneapo

   RETURN NUMBER IS

  BEGIN
 
    IF PKGPAG_VAR.vgapo.count > 0 THEN

    RETURN CASE
             WHEN PKGPAG_VAR.vgApo(PKGPAG_VAR.vgApo.FIRST).VlPercentPropAPO  > 0 THEN
               PKGPAG_VAR.vgApo(PKGPAG_VAR.vgApo.FIRST).VlPercentPropAPO
             ELSE
               100
           END;

    ELSE

      RETURN 100;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 100;

  END;

  -----------------------------------------------------------------
  --
  -----------------------------------------------------------------

  FUNCTION FMneValorAPOSemParid(pCdVinculo IN INTEGER,
                               pDtFimMes  IN DATE)

   RETURN NUMBER IS

    vvlfinalaposentadoria NUMBER(13, 2);

  BEGIN
 
    SELECT vlfinalaposentadoria
      INTO vvlfinalaposentadoria
    FROM (SELECT NVL(DECODE(VASP.VlProporcional,0,NULL, VASP.VlProporcional),VASP.VlFinalAposentadoria) AS VlFinalAposentadoria
              FROM epagvaloraposemparidade vasp
           WHERE VASP.CdVinculo = pCdVinculo AND
                 VASP.DtInicioValidade <= pDtFimMes
             ORDER BY vasp.dtiniciovalidade DESC)
     WHERE rownum < 2;

    RETURN vvlfinalaposentadoria;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fmneindicerubrica(pCdVinculo            in integer,
                             pCdRubricaAgrupamento IN INTEGER)
    RETURN NUMBER IS

    vVlIndice NUMBER(13, 2);

  begin
 
    select nvl(hrv.vlindicerubrica, 0)
      into vVlIndice
      from epaghistoricorubricavinculo hrv
     where hrv.cdvinculo = pCdVinculo
       and hrv.cdrubricaagrupamento = pCdRubricaAgrupamento
       and hrv.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
       and rownum < 2;

    if nvl(vVlIndice, 0) = 0 then

      select nvl(hr.vlindicerubrica, 0)
        into vVlIndice
        from epaghistoricorubricarelvinc hr
       where hr.cdvinculo = pCdVinculo
         and hr.cdrubricaagrupamento = pCdRubricaAgrupamento
         and hr.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
         and rownum < 2;

    end if;

    return vVlIndice;

  exception

    when others then
      begin
        select nvl(hr.vlindicerubrica, 0)
          into vVlIndice
          from epaghistoricorubricarelvinc hr
         where hr.cdvinculo = pCdVinculo
           and hr.cdrubricaagrupamento = pCdRubricaAgrupamento
           and hr.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
           and rownum < 2;

        return vVlIndice;

      exception

            when others
              then
          return 0;

      end;

  END fmneindicerubrica;

  FUNCTION fmneidadepessoa(pfolha    IN pkgpag_tipo.rfolha,
                         pCdPessoa IN INTEGER)
  RETURN NUMBER IS

    vidade NUMBER;

  BEGIN
 
   SELECT trunc(MONTHS_BETWEEN(pFolha.DtFimMes,PKGPAG_VAR.vgVinculo.DtNascimento )/12)
      INTO vidade
      FROM dual;

    RETURN vidade;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN - 1;

  END fmneidadepessoa;

  FUNCTION fmneind(pcdvinculo                    IN INTEGER,
                   pcdrubricaagrupamento         IN INTEGER,
                   pcdoutrarubrica               IN INTEGER,
                   pflvalorhoraminuto            IN CHAR,
                   pvlindicerubrica              IN NUMBER,
                   pvlindiceliminferiormensal    IN NUMBER DEFAULT NULL,
                   pvlindicelimsuperiormensal    IN NUMBER DEFAULT NULL,
                   pvlindicelimsuperiorsemestral IN NUMBER DEFAULT NULL,
                   pvlindicelimsuperioranual     IN NUMBER DEFAULT NULL,
                   pdeindiceexpressao            IN VARCHAR2 DEFAULT NULL,
                   pcdrelacaovinculo             IN INTEGER DEFAULT NULL,
                   pcdchave                      IN INTEGER DEFAULT NULL,
                   pvlindicereal                 IN NUMBER DEFAULT NULL)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vvlindice pkgpag_tipo.rvalorpagamento;

    vdeindice VARCHAR2(100);

  FUNCTION FLimite(pNuMeses IN INTEGER,
                   pFlIndiceReal IN BOOLEAN)

     RETURN NUMBER IS

      vvllimitesuperiorp NUMBER;
      vvllimitesuperiorr NUMBER;

    BEGIN
 
    SELECT nvl(SUM(vlIndiceRubrica),0),
           nvl(SUM(vlIndiceReal),0)
       INTO vvlLimiteSuperiorP,
            vvlLimiteSuperiorR
        FROM (SELECT CASE
                       WHEN pflvalorhoraminuto = pkgpag_tipo.cns THEN
                        to_number(substr(vlindicerubrica, 1, 2))
                       ELSE
                        vlindicerubrica
                     END AS vlindicerubrica,
                     CASE
                       WHEN pflvalorhoraminuto = pkgpag_tipo.cns THEN
                        to_number(substr(vlindicereal, 1, 2))
                       ELSE
                        vlindicereal
                     END AS vlindicereal
                FROM (SELECT VlIndiceRubrica,
                             VlIndiceRubrica AS VlIndiceReal
                        FROM epaghistoricorubricavinculo hrv
                       INNER JOIN ECalFolhaPag fp
                          ON fp.cdfolhapagamento = hrv.cdfolhapagamento
                         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                       WHERE HRV.CdVinculo = pCdVinculo AND
                             HRV.CdRubricaAgrupamento = pCdRubricaAgrupamento AND
                             FP.CdOrgao = PKGPAG_VAR.vgFolha.CdOrgao AND
                             FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal AND
                             FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                             FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
                       ORDER BY fp.cdfolhapagamento DESC)
               WHERE rownum < pnumeses);

      IF pflindicereal THEN

        RETURN vvllimitesuperiorr;

      ELSE

        RETURN vvllimitesuperiorp;

      END IF;

    END;

    FUNCTION fretornalimiteindice(pvlindicerubrica IN pkgpag_tipo.rvalorpagamento)

     RETURN pkgpag_tipo.rvalorpagamento IS

      vvlindicerubrica pkgpag_tipo.rvalorpagamento;

      vllimsupsem NUMBER;

      vllimsupanual NUMBER;

      PROCEDURE ptratalimite(pvlindice     IN OUT NUMBER,
                             pflindicereal IN BOOLEAN) IS

      BEGIN
 
        IF pvlindiceliminferiormensal > pvlindicerubrica.vlproporcional THEN

          pvlindice := pvlindiceliminferiormensal;

        ELSIF pvlindicelimsuperiormensal < pvlindicerubrica.vlproporcional THEN

          pvlindice := pvlindicelimsuperiormensal;

          IF pvlindicelimsuperiorsemestral IS NOT NULL THEN

            vllimsupsem := flimite(5, pflindicereal) + pvlindice;

            IF vllimsupsem > pvlindicelimsuperiorsemestral THEN

              pvlindice := CASE
                                 WHEN pVlIndice - (vlLimSupSem - pVlIndiceLimSuperiorSemestral) > 0 THEN
                              pvlindice - (vllimsupsem - pvlindicelimsuperiorsemestral)
                             ELSE
                              0
                           END;
            END IF;

            IF pvlindicelimsuperioranual IS NOT NULL THEN

              vllimsupanual := flimite(11, pflindicereal) + pvlindice;

              IF vllimsupanual > pvlindicelimsuperioranual THEN

              pVlIndice :=
                 CASE
                   WHEN pVlIndice - (vlLimSupAnual - pVlIndiceLimSuperiorAnual) > 0 THEN
                                pvlindice - (vllimsupanual - pvlindicelimsuperioranual)
                               ELSE
                                0
                             END;

              END IF;

            END IF;

            IF pdeindiceexpressao IS NOT NULL THEN

            vDeIndice := REPLACE(pDeIndiceExpressao,
                                '=',
                                '');

            vDeIndice := REPLACE(vDeIndice,
                                '[IND]',
                                pVlIndice);

              pvlindice := fcalcexpressao(vdeindice);

            END IF;

          END IF;

        else
          null;
        END IF;

      END;

    BEGIN
 
      vvlindicerubrica := pvlindicerubrica;

    PTrataLimite(pVlIndice => vVlIndiceRubrica.VlProporcional, pFlIndiceReal => FALSE);

    PTrataLimite(pVlIndice => vVlIndiceRubrica.VlReal, pFlIndiceReal => TRUE);

      RETURN vvlindicerubrica;

    END;

    FUNCTION findiceoutrarubrica RETURN pkgpag_tipo.rvalorpagamento IS

      vsql VARCHAR2(400);

      vvlindicerubrica pkgpag_tipo.rvalorpagamento;

      vCdVinculo ecadvinculo.cdvinculo%type;

    BEGIN
 
      vvlindicerubrica.vlproporcional := 0;

      vvlindicerubrica.vlreal := 0;

      vCdVinculo := 0;

      IF pcdrelacaovinculo = 0 THEN

        vsql := 'SELECT VlIndiceRubrica' ||
                '  FROM EPAGHISTORICORUBRICAVINCULO ';

      ELSE

        vsql := 'SELECT VlIndiceRubrica,' ||
                '       NVL( VlIndiceReal,VlIndiceRubrica)' ||
                '  FROM EPAGHISTORICORUBRICARELVINC ';

      END IF;

      CASE pcdrelacaovinculo

        WHEN 0 THEN

          vsql := vsql || '  WHERE CdVinculo = :pCdChave AND ';

        WHEN 1 THEN

          vsql := vsql || '  WHERE CdHistCargoEfetivo = :pCdChave AND ';

          begin
            select rv.cdvinculo
              into vCdVinculo
              from ecadhistcargoefetivo rv
             where rv.cdhistcargoefetivo = pCdChave;
          exception
            when others then
              vCdVinculo := 0;
          end;

        WHEN 2 THEN

          vsql := vsql || '  WHERE CdHistCargoCom = :pCdChave AND ';

          begin
            select rv.cdvinculo
              into vCdVinculo
              from ecadhistcargocom rv
             where rv.cdhistcargocom = pCdChave;
          exception
            when others then
              vCdVinculo := 0;
          end;

        WHEN 3 THEN

          vsql := vsql || '  WHERE CdHistFuncaoChefia = :pCdChave AND ';

          begin
            select rv.cdvinculo
              into vCdVinculo
              from ecadhistfuncaochefia rv
             where rv.cdhistfuncaochefia = pCdChave;
          exception
            when others then
              vCdVinculo := 0;
          end;

        WHEN 4 THEN

          vSQL := vSQL || '  WHERE CdConcessaoAposentadoria = :pCdChave AND ';

          begin
            select rv.cdvinculo
              into vCdVinculo
              from epvdconcessaoaposentadoria rv
             where rv.cdconcessaoaposentadoria = pCdChave;
          exception
            when others then
              vCdVinculo := 0;
          end;

        WHEN 5 THEN

          vsql := vsql || '  WHERE CdHistEstagio = :pCdChave AND ';

          begin
            select rv.cdvinculoestagio
              into vCdVinculo
              from ecadhistestagio rv
             where rv.cdhistestagio = pCdChave;
          exception
            when others then
              vCdVinculo := 0;
          end;

        WHEN 6 THEN

          vSQL := vSQL ||  ' WHERE CdHistPensaoPrevidenciaria = :pCdChave AND ';

        WHEN 7 THEN

          vsql := vsql || ' WHERE  CdHistPensaoNaoPrev = :pCdChave AND ';

        WHEN 8 THEN

        vSQL := vSQL ||  ' WHERE CdHistPensaoExParlamentar = :pCdChave AND ';

        WHEN 9 THEN

          vsql := vsql || ' WHERE CdAuxilioReclusao = :pCdChave AND ';

        ELSE

          NULL;

      END CASE;

      if vCdVinculo > 0 then
        -- para usar IDXCAPARUBRELVINC / melhoria de performance
        vsql := vsql || '    CdVinculo = :pCdChaveVinc AND ';
      end if;
      vsql := vsql || ' CdRubricaAgrupamento = :pCdRubricaAgrupamento AND ';
      vsql := vsql || ' CdFolhaPagamento = :pCdFolhaPagamento AND ';
      vsql := vsql || ' ROWNUM < 2 ';

      IF pcdrelacaovinculo = 0 THEN
        EXECUTE IMMEDIATE vSQL INTO vvlIndiceRubrica.vlProporcional

        USING pCdChave,
              pCdOutraRubrica,
              PKGPAG_VAR.vgFolha.CdFolhaPagamento;
      elsif pcdrelacaovinculo >= 1 and vCdVinculo > 0 then
        EXECUTE IMMEDIATE vSQL INTO vvlIndiceRubrica.vlProporcional,
                                   vvlIndiceRubrica.vlReal

        USING pCdChave,
          vCdVinculo,
          pCdOutraRubrica,
          PKGPAG_VAR.vgFolha.CdFolhaPagamento;
      ELSE
        EXECUTE IMMEDIATE vSQL INTO vvlIndiceRubrica.vlProporcional,
                                    vvlIndiceRubrica.vlReal

        USING pCdChave,
           pCdOutraRubrica,
           PKGPAG_VAR.vgFolha.CdFolhaPagamento;
      END IF;

      -- Utilizar o indice correto nas incorporacoes quando na formula tem mais de um indice.
      -- Rubricas da SED 01-0372, 01-0472.
    IF vVlIndiceRubrica.vlReal > 0
      THEN
        vvlindiceoutrarubrica := vvlindicerubrica.vlreal;
      END IF;

      RETURN vvlindicerubrica;

    EXCEPTION

      WHEN OTHERS THEN

        --DBMS_OUTPUT.PUT_LINE('ERRO: ' || SQLERRM || ' - ' || pCdChave || ' - ' || pCdOutraRubrica  );
        RETURN vvlindicerubrica;

    END;

    FUNCTION fhhmmtodec(phhmm IN NUMBER)

     RETURN NUMBER IS

      vvlhora NUMBER(5);

      vvlminuto NUMBER(2);

      vvlhoraminuto NUMBER(5, 2);

    BEGIN
 
    vVlMinuto := (NVL((SUBSTR(TRUNC(pHHMM),
                        LENGTH(TRUNC(pHHMM))-1,
                        2)),0)/60)*100;

      vVlHora := NVL(SUBSTR(TRUNC(pHHMM),
                            -LENGTH(TRUNC(pHHMM)),
                            length(trunc(phhmm)) - 2), 0);

      vvlhoraminuto := vvlhora || '.' || lpad(vvlminuto, 2, '0');

      RETURN vvlhoraminuto;

    END;

  BEGIN
 
    vvlindice.vlproporcional := pvlindicerubrica;
    vvlindice.vlreal         := nvl(pvlindicereal, pvlindicerubrica);

    IF pcdoutrarubrica IS NOT NULL THEN

      vvlindice := findiceoutrarubrica;
      --
      -- Emitir mensagem de erro quando n?o encontra o ?ndice da outra rubrica
      --
      IF (vvlindice.vlreal = 0) THEN
        RETURN vvlindice;

        --PKGPAG_GERAL.p90Log(PKGPAG_VAR.bLog,
        --                       PKGPAG_VAR.vCdHistParamCalc,
        --                      PKGPAG_VAR.vCdPessoa,
        --                     'Erro ao processar formula - Indice nao encontrado. Rubrica: ' ||
        --                    LPAD(PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).CdTipoRubrica,2,'0') ||'-'||
        --                   LPAD(PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).NuRubrica,4,'0'),
        --                  PKGPAG_VAR.vgCdVinculo);

      END IF;

    END IF;

    IF NOT (pflvalorhoraminuto = pkgpag_tipo.cnn) THEN

      vvlindice.vlproporcional := fhhmmtodec(vvlindice.vlproporcional);
      vvlindice.vlreal         := fhhmmtodec(vvlindice.vlreal);

    END IF;

    RETURN fretornalimiteindice(vvlindice);

  END;

  FUNCTION fretornapercentacumats(pcdvinculo     IN INTEGER,
                                  pcdagrupamento IN INTEGER,
                                  pdtiniciomes   IN DATE,
                                  pdtfimmes      IN DATE)

   RETURN NUMBER IS

    vvlpercentats NUMBER(7, 4);

    vcdrubtrienio3 INTEGER;

    vcdrubtrienio6 INTEGER;

  BEGIN
 
    IF PKGPAG_VAR.vgpercentacumats.count > 0
      AND NVL(PKGPAG_VAR.vgpercentacumats(PKGPAG_VAR.vgpercentacumats.first),0) > 0
      THEN
      RETURN NVL(PKGPAG_VAR.vgpercentacumats(PKGPAG_VAR.vgpercentacumats.first),0);

    ELSE

      BEGIN

        vcdrubtrienio3 := PKGPAG_GERAL.fretornarubrica(pcdagrupamento, 1, 18);

        vcdrubtrienio6 := PKGPAG_GERAL.fretornarubrica(pcdagrupamento, 1, 84);

        IF PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubTrienio3) OR PKGPAG_VAR.vListaRubricas.EXISTS(vCdRubTrienio6) THEN

          select sum(vlindice)
            into vvlpercentats
            from epaglancamentofinanceiro lf
           where LF.CdVinculo = pCdVinculo
             and LF.CdRubricaAgrupamento in (vCdRubTrienio3, vCdRubTrienio6)
             and LF.DtInicioDireito <= pdtFimMes
             and (LF.DtFimDireito >= pdtInicioMes or LF.DtFimDireito is null)
             and lf.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                    from vpagrubricaagrupamento ra
                   where ra.cdrubricaagrupamento = lf.cdrubricaagrupamento
                     and ra.flsuspensa = PKGPAG_TIPO.cnN);
        END IF;

        RETURN nvl(vvlpercentats, 0);

      EXCEPTION

        WHEN OTHERS THEN

          RETURN 0;

      END;

    END IF;

  END;

  FUNCTION FMneCCO(pFolha IN PKGPAG_TIPO.rFolha,
                  pCCO   IN PKGPAG_TIPO.rCCO)

   RETURN NUMBER IS

    vvlintegral NUMBER(13, 2);

  BEGIN
 
    vvlintegral := PKGPAG_GERAL.fretornavalorfixocco(pcco.nunivel,
                                                     pcco.nureferencia,
                                                     pcco.cdrelacaotrabalho,
                                                     pfolha.cdagrupamento,
                                                     pfolha.cdorgao,
                                                     pfolha.nuversaotabcco,
                                                     pfolha.nuanoreferencia,
                                                     pfolha.numesreferencia);

    RETURN vvlintegral;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneFUC
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/
  FUNCTION FMneFUC(pFolha IN PKGPAG_TIPO.rFolha,
                  pFUC   IN PKGPAG_TIPO.rFUC)

   RETURN NUMBER IS

    vvlintegral NUMBER(13, 2);

  BEGIN
 
    vvlintegral := PKGPAG_GERAL.fretornavalorfixofuc(pfuc.cdpadraofucagrup,
                                                     pfolha.cdagrupamento,
                                                     pfolha.cdorgao,
                                                     pfolha.nuversaotabfuc,
                                                     pfolha.nuanoreferencia,
                                                     pfolha.numesreferencia);

    RETURN vvlintegral;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FMneSubsidioPrivativoFC(pFolha IN PKGPAG_TIPO.rFolha,
                                   pFUC   IN PKGPAG_TIPO.rFUC)

   RETURN NUMBER IS

    vvlintegral pkgpag_tipo.rValorFixo;

    vCdEstruturaCarreira INTEGER;

    vCdEstruturaCarreiraCarreira INTEGER;

    vNuNivel ecadevolucaofucitemcarreira.nunivel%type;

    vNuReferencia ecadevolucaofucitemcarreira.nureferencia%type;

  BEGIN
 
    select edf.cdestruturacarreira, edf.nunivel, edf.nureferencia, etc.cdestruturacarreiracarreira
      into vCdEstruturaCarreira, vNuNivel, vNuReferencia, vCdEstruturaCarreiraCarreira
      from ecadevolucaofucitemcarreira edf
      inner join ecadestruturacarreira etc on edf.cdestruturacarreira = etc.cdestruturacarreira
     where CdEvolucaoFuncaoChefia = pFuc.CdEvolucaoFuncaoChefia
       and flproprio = 'S';

    vvlintegral := PKGPAG_GERAL.FRetonaValorFixoCEF(pFolha.CdAgrupamento,
                                                    pFolha.CdOrgao,
                                                    pFolha.NuVersaoTabcef,
                                                    pFolha.NuAnoReferencia,
                                                    pFolha.NuMesReferencia,
                                                    vCdEstruturaCarreira,
                                                    vCdEstruturaCarreiraCarreira,
                                                    vNuNivel,
                                                    vNuReferencia);

    RETURN vvlintegral.VlFixo;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fMneVlBasePrevInstituidor(pCdVinculo        INTEGER,
                                     pAnoMesReferencia INTEGER,
                                     pCdTipoCalculo    INTEGER)

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlBasePrevInstituidor(pCdVinculoPensionista => pCdVinculo,
                                                              pAnoMesReferencia     => pAnoMesReferencia,
                                                              pCdTipoCalculo        => pCdTipoCalculo);

  END;

  FUNCTION fMneVlBaseMilitarInstituidor(pCdVinculo        INTEGER,
                                        pAnoMesReferencia INTEGER,
                                        pCdTipoCalculo    INTEGER)

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlBaseMilitarInstituidor(pCdVinculoPensionista => pCdVinculo,
                                                                 pAnoMesReferencia     => pAnoMesReferencia,
                                                                 pCdTipoCalculo        => pCdTipoCalculo);

  END;

  FUNCTION fMneVlTetoInstituidor(pCdVinculo        INTEGER,
                                 pAnoMesReferencia INTEGER,
                                 pCdTipoCalculo    INTEGER)

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlTetoInstituidor(pCdVinculoPensionista => pCdVinculo,
                                                          pAnoMesReferencia     => pAnoMesReferencia,
                                                          pCdTipoCalculo        => pCdTipoCalculo);

  END;

  FUNCTION fMneVlPercPensao(pCdVinculo        INTEGER,
                            pAnoMesReferencia INTEGER,
                            pFlIntegral       BOOLEAN DEFAULT FALSE)

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlPercPensao(pCdVinculoPensionista => pCdVinculo,
                                                     pAnoMesReferencia     => pAnoMesReferencia,
                                                     pFlIntegral           => pFlIntegral);

  END;

  FUNCTION fMneVlPercPensaoPrev(pCdVinculo        INTEGER,
                                pAnoMesReferencia INTEGER,
                                pCdTipoCalculo    INTEGER)

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlPercPensaoPrev(pCdVinculoPensionista => pCdVinculo,
                                                         pAnoMesReferencia     => pAnoMesReferencia,
                                                         pCdTipoCalculo        => pCdTipoCalculo);

  END;

  FUNCTION fMneVlPensaoPrev(pCdVinculo        INTEGER,
                            pAnoMesReferencia INTEGER,
                            pFlIntegral       BOOLEAN DEFAULT FALSE)

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlPensaoPrev(pCdVinculoPensionista => pCdVinculo,
                                                     pAnoMesReferencia     => pAnoMesReferencia,
                                                     pFlIntegral           => pFlIntegral);

  END;

  FUNCTION fMneVlPercPensaoBase(pCdVinculo        INTEGER,
                                pAnoMesReferencia INTEGER,
                                pFlIntegral       BOOLEAN DEFAULT FALSE) --  <--sg-7062

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlPercPensaoBase(pCdVinculoPensionista => pCdVinculo,
                                                         pAnoMesReferencia     => pAnoMesReferencia,
                                                         pFlIntegral           => pFlIntegral); -- <--sig-7062

  END;

  FUNCTION fMneVlPercIntegralidade(pCdVinculo        INTEGER,
                                   pAnoMesReferencia INTEGER)

   RETURN NUMBER IS

  BEGIN
 
    RETURN pkgpag_pensaoprevidenciaria.fVlPercIntegralidade(pCdVinculoPensionista => pCdVinculo,
                                                            pAnoMesReferencia     => pAnoMesReferencia);

  END;
  /*----------------------------------------------------------------------------
       Funcao: FMneCEF
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/

  FUNCTION fmnecef

   RETURN NUMBER IS

  BEGIN
 
    RETURN PKGPAG_VAR.vgvalorfixocef.vlfixo;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneVlOutrosVinculos
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/
  FUNCTION fmnevloutrosvinculos(pcdpessoa        IN INTEGER,
                                pcdvinculo       IN INTEGER,
                                pcdrubrica       IN INTEGER,
                                pnuanoreferencia IN INTEGER,
                                pnumesreferencia IN INTEGER)

   RETURN NUMBER IS

    vvlpago NUMBER(15, 4);

  BEGIN
 
      IF pCdRubrica IN (PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,837),
                        PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,937),
                        PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,847)) or
      -- Somar base bloqueio de remuneracao para CTISP
      -- SIG-8266 Bloqueio remuneratorio CTISP
         (pCdRubrica =  PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,983) and
       PKGPAG_VAR.vgFolha.CdAgrupamento = 134 and
       PKGPAG_VAR.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaCtisp)

     THEN

         WITH RUB AS (SELECT R1.CDRUBRICAAGRUPAMENTO
          FROM EPAGRUBRICAAGRUPAMENTO R1
                       INNER JOIN EPAGRUBRICA R2 ON R2.CDRUBRICA = R1.CDRUBRICA
           AND R2.CDTIPORUBRICA = PKGPAG_VAR.vgRubrica(pCdRubrica).CdTipoRubrica
           AND R2.NURUBRICA = PKGPAG_VAR.vgRubrica(pCdRubrica).NuRubrica),

         VINC AS (SELECT CDVINCULO
                    FROM ECADVINCULO
                   WHERE CDPESSOA = pCdPessoa)

      SELECT nvl(SUM(rv.vlpagamento), 0) AS vlpago
        INTO vvlpago
        FROM epaghistoricorubricavinculo rv
       INNER JOIN ECalFolhaPag fp
          ON fp.cdfolhapagamento = rv.cdfolhapagamento
         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
       INNER JOIN VINC v
          ON v.cdvinculo = rv.cdvinculo
         AND v.cdvinculo <> pcdvinculo
           INNER JOIN RUB R3 ON R3.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO
          WHERE FP.NuAnoReferencia = pNuAnoReferencia AND
                FP.NuMesReferencia = pNuMesReferencia AND
                ((PKGPAG_VAR.vgfolha.Flcalculodefinitivo = 'S' AND FP.Flcalculodefinitivo = 'S')
                 OR (PKGPAG_VAR.vgfolha.Flcalculodefinitivo = 'N' AND FP.Flcalculodefinitivo IN ('S', 'N'))) AND
                FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl);

    ELSE

      SELECT nvl(SUM(rv.vlpagamento), 0) AS vlpago
        INTO vvlpago
        FROM epaghistoricorubricavinculo rv
       INNER JOIN ECalFolhaPag fp
          ON fp.cdfolhapagamento = rv.cdfolhapagamento
         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
       INNER JOIN ecadvinculo v
          ON v.cdvinculo = rv.cdvinculo
                WHERE RV.CdRubricaAgrupamento = pCdRubrica AND
                      FP.NuAnoReferencia = pNuAnoReferencia AND
                      FP.NuMesReferencia = pNuMesReferencia AND
                      FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl) AND
                      FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
                      V.CdPessoa = pCdPessoa AND V.CdVinculo <> pCdVinculo;

    END IF;

    RETURN vvlpago;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

 
  FUNCTION fMnePossuiIsencaoIRRFRub(pCdVinculo            IN INTEGER,
                                    pCdRubricaAgrupamento IN INTEGER,
                                    pNuAnoReferencia      IN INTEGER,
                                    pNuMesReferencia      IN INTEGER) 
   RETURN INTEGER IS
    
    vIsento INTEGER;
     
   BEGIN  
     
    vIsento := 0;
    
    SELECT 1
      INTO vIsento
      FROM ETrbIsencaoRubrica tr
     INNER JOIN ETrbHistIsencaoRubrica htr
         ON htr.CdIsencaoRubrica = TR.CdIsencaoRubrica
      WHERE tr.CdVinculo = pCdVinculo 
        AND tr.cdRubricaAgrupamento = pCdRubricaAgrupamento 
        AND tr.flrubricaisentairrf = 'S'
        AND ((htr.NuAnoInicioVigencia < pNuAnoReferencia OR
             (htr.NuAnoInicioVigencia = pNuAnoReferencia AND
             htr.NuMesInicioVigencia <= pNuMesReferencia))
             AND
             (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
             (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
             HTR.NuMesFimVigencia >= pNuMesReferencia) OR
             htr.numesfimvigencia IS NULL));
          
    RETURN vIsento;
           
  EXCEPTION    
    WHEN OTHERS THEN
      RETURN 0;
                 
  END;
                                     
  FUNCTION fmnevlanooutrosvinculos(pcdpessoa        IN INTEGER,
                                   pcdvinculo       IN INTEGER,
                                   pcdrubrica       IN INTEGER,
                                   pnuanoreferencia IN INTEGER)

   RETURN NUMBER IS

    vvlpago  NUMBER(15, 4) := 0;
    vvltotal NUMBER(15, 4) := 0;

    v1 integer;
    v2 integer;
    v3 integer;

  BEGIN
 
    if PKGPAG_VAR.vgRubrica(pCdRubrica).CdTipoRubrica = 1 then

      v1 := 1;
      v2 := 2;
      v3 := 3;

    elsif PKGPAG_VAR.vgRubrica(pCdRubrica).CdTipoRubrica = 5 then

      v1 := 5;
      v2 := 6;
      v3 := 7;

    else

      v1 := 9;
      v2 := 9;
      v3 := 9;

    end if;

    IF PKGPAG_VAR.vgFolha.CdTipoFolha IN (pkgpag_tipo.cnTpFolha13, pkgpag_tipo.cnTpFolhaCtisp13, pkgpag_tipo.cnTpFolhaProdex13
                                        , pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13) THEN

      FOR dados IN (SELECT cdvinculo
                      FROM ecadvinculo
                     WHERE cdpessoa = pcdpessoa
                       AND cdvinculo <> pcdvinculo) LOOP

        WITH RUB AS
         (SELECT R1.CDRUBRICAAGRUPAMENTO
            FROM EPAGRUBRICAAGRUPAMENTO R1
           INNER JOIN EPAGRUBRICA R2
              ON R2.CDRUBRICA = R1.CDRUBRICA
             AND R2.CDTIPORUBRICA IN (v1, v2, v3)
             AND R2.NURUBRICA = PKGPAG_VAR.vgRubrica(pCdRubrica).NuRubrica
           WHERE R1.CDAGRUPAMENTO = PKGPAG_VAR.vgFolha.cdAgrupamento)
        SELECT nvl(SUM(rv.vlpagamento), 0) AS vlpago
          INTO vvlpago
          FROM epaghistoricorubricavinculo rv
         INNER JOIN ECalFolhaPag fp
            ON fp.cdfolhapagamento = rv.cdfolhapagamento
           AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
           AND fP.CDTIPOCALCULO = 1
         INNER JOIN RUB R3
            ON R3.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO
         INNER JOIN EPAGTIPOFOLHAPAGAMENTO TF
            ON TF.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
         WHERE FP.NuAnoReferencia = pNuAnoReferencia
           AND rV.CdVinculo = dados.cdvinculo
           AND NOT (PKGPAG_VAR.vgRubrica(pCdRubrica).NuRubrica = 23 
           AND EXISTS
                 (SELECT 1
                    FROM ETrbIsencaoIRRF IR
                   INNER JOIN ETrbHistIsencaoIRRF HIR
                      ON IR.CdIsencaoIRRF = HIR.CdIsencaoIRRF
                   WHERE IR.CdVinculo = rV.CdVinculo
                     AND HIR.FlAnulado = PKGPAG_TIPO.cnN
                     AND (HIR.NuAnoInicioVigencia <= pNuAnoReferencia)
                     AND (HIR.NuAnoFimVigencia >= pNuAnoReferencia OR
                         HIR.NuAnoFimVigencia IS NULL)))
            AND ((FLCALCULODEFINITIVO = PKGPAG_TIPO.cnS AND
                  FP.NUMESREFERENCIA < PKGPAG_VAR.vgFolha.numesreferencia)
                  OR
                 (FP.NUMESREFERENCIA = PKGPAG_VAR.vgFolha.numesreferencia AND
                  TF.CDTIPOFOLHA IN (pkgpag_tipo.cnTpFolha13,pkgpag_tipo.cnTpFolhaNormal)));

        vvltotal := vvltotal + vvlpago;

      END LOOP;

    ELSE

      FOR dados IN (SELECT cdvinculo
                      FROM ecadvinculo
                     WHERE cdpessoa = pcdpessoa
                       AND cdvinculo <> pcdvinculo) LOOP
        WITH RUB AS
         (SELECT R1.CDRUBRICAAGRUPAMENTO
            FROM EPAGRUBRICAAGRUPAMENTO R1
           INNER JOIN EPAGRUBRICA R2
              ON R2.CDRUBRICA = R1.CDRUBRICA
             AND R2.CDTIPORUBRICA in (v1, v2, v3)
             AND R2.NURUBRICA = PKGPAG_VAR.vgRubrica(pCdRubrica).NuRubrica
           WHERE R1.CDAGRUPAMENTO = PKGPAG_VAR.vgFolha.cdAgrupamento)
        SELECT nvl(SUM(rv.vlpagamento), 0) AS vlpago
          INTO vvlpago
          FROM epaghistoricorubricavinculo rv
         INNER JOIN ECalFolhaPag fp
            ON fp.cdfolhapagamento = rv.cdfolhapagamento
           AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
         INNER JOIN RUB R3
            ON R3.CDRUBRICAAGRUPAMENTO = RV.CDRUBRICAAGRUPAMENTO
         WHERE FP.NuAnoReferencia = pNuAnoReferencia
           AND rV.CdVinculo = dados.cdvinculo
             AND ((PKGPAG_VAR.vgFolha.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS) OR
               ((PKGPAG_VAR.vgFolha.FlCalculoDefinitivo = PKGPAG_TIPO.cnN AND
               FP.Cdtipocalculo = PKGPAG_VAR.vgFolha.CdtipoCalculo AND
               FP.NUMESREFERENCIA = PKGPAG_VAR.vgFolha.numesreferencia AND
                  FP.Cdtipofolhapagamento = PKGPAG_VAR.vgFolha.Cdtipofolhapagamento) OR FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS));

        vvltotal := vvltotal + vvlpago;

      END LOOP;

    END IF;

    RETURN vvltotal;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN NVL(vvltotal, 0);

  END;

  FUNCTION FMneVlRubTodosVinculos(pcdpessoa             IN INTEGER,
                                  pcdfolhapagamento     IN INTEGER,
                                  pcdrubricaagrupamento IN INTEGER,
                                  pnuanoreferencia      IN INTEGER)

   RETURN NUMBER IS

    vvlpago NUMBER(15, 4) := 0;

  BEGIN
 
    SELECT nvl(SUM(rv.vlpagamento), 0) AS vlpago
      INTO vvlpago
      FROM epaghistoricorubricavinculo rv
     INNER JOIN ECalFolhaPag fp
        ON fp.cdfolhapagamento = rv.cdfolhapagamento
       AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
       AND (fp.flcalculodefinitivo = 'S') --OR fp.cdfolhapagamento = pcdfolhapagamento)
     INNER JOIN ecadvinculo v
        ON v.cdvinculo = rv.cdvinculo
     INNER JOIN vpagrubricaagrupamento r
        ON r.cdrubricaagrupamento = rv.cdrubricaagrupamento
     WHERE v.cdpessoa = pcdpessoa
       AND fp.nuanoreferencia = pnuanoreferencia
       AND r.cdrubrica IN
           (SELECT cdrubrica
              FROM vpagrubricaagrupamento
             WHERE cdrubricaagrupamento = pcdrubricaagrupamento);

    RETURN vvlpago;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FMneSomaAnoRubTodosVinculosINSS(pcdpessoa             IN INTEGER,
                                           pcdfolhapagamento     IN INTEGER,
                                           pcdrubricaagrupamento IN INTEGER,
                                           pnuanoreferencia      IN INTEGER)

   RETURN NUMBER IS

    vvlpago NUMBER(15, 4) := 0;

  BEGIN
 
    SELECT nvl(SUM(rv.vlpagamento), 0) AS vlpago
      INTO vvlpago
      FROM epaghistoricorubricavinculo rv
     INNER JOIN ECalFolhaPag fp
        ON fp.cdfolhapagamento = rv.cdfolhapagamento
       AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
     inner join epagtipofolhapagamento tf on tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
     INNER JOIN ecadvinculo v
        ON v.cdvinculo = rv.cdvinculo
     INNER JOIN vpagrubricaagrupamento r
        ON r.cdrubricaagrupamento = rv.cdrubricaagrupamento
     WHERE v.cdpessoa = pcdpessoa
       AND fp.nuanoreferencia = pnuanoreferencia
       AND rv.cdrubricaagrupamento = pcdrubricaagrupamento
       and v.CdRegimeprevidenciario=pkgpag_tipo.cn1
       -- Folhas definitivas do Ano desconsiderando as de 13 do mesmo vinculo
       and ((fp.flcalculodefinitivo = 'S'
            and not (tf.cdtipofolha = pkgpag_tipo.cnTpFolha13
                     and rv.cdvinculo = PKGPAG_VAR.vgvinculo.cdvinculo
                     and fp.nuanomesreferencia <> to_char(PKGPAG_VAR.vgFolha.DtInicioMes,'YYYYMM'))
            and not (PKGPAG_VAR.vgFolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoRecalculoMes
                     and fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoNormal -- normal
                     and rv.cdvinculo =  PKGPAG_VAR.vgvinculo.cdvinculo 
                     and fp.nuanomesreferencia =  to_char(PKGPAG_VAR.vgFolha.DtInicioMes,'YYYYMM'))     
                     
             or
       -- Folha nao definitiva do mesmo mes e do mesmo tipo para os demais vinculos
             (fp.flcalculodefinitivo = 'N'
              and tf.cdtipofolha = PKGPAG_VAR.vgFolha.CdTipoFolha
              and rv.cdvinculo <> PKGPAG_VAR.vgvinculo.cdvinculo
              and fp.nuanomesreferencia = to_char(PKGPAG_VAR.vgFolha.DtInicioMes,'YYYYMM')
              and fp.cdtipocalculo = PKGPAG_VAR.vgFolha.CdTipoCalculo))
              
       -- A propria folha
            or fp.cdfolhapagamento = pcdfolhapagamento);

    RETURN vvlpago;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION FMneSomaRubMesOutrosVinculos(pcdpessoa             IN INTEGER,
                                        pcdrubricaagrupamento IN INTEGER,
                                        pfolha                in pkgpag_tipo.rFolha)

   RETURN NUMBER IS

    vvlpago NUMBER(15, 4) := 0;

  BEGIN
 

    with fol as
    (select fp.cdfolhapagamento, tf.cdtipofolhapagamento from ECalFolhaPag fp
       inner join epagtipofolhapagamento tf on tf.cdtipofolhapagamento = fp.cdtipofolhapagamento
       where fp.nuanoreferencia = pFolha.NuAnoReferencia
         and fp.numesreferencia = pfolha.NuMesReferencia
         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
         -- Folhas de 13 somente verificam folhas do mesmo tipo
         and ((tf.CdTipoFolha not in (3, 8, 14, 18, 20, 26, 27, 28) and
               pFolha.CdTipoFolha not in (3, 8, 14, 18, 20, 26, 27, 28)) or
             ((tf.CdTipoFolha in (3, 8, 14, 18, 20, 26, 27, 28) and
               pFolha.CdTipoFolha in (3, 8, 14, 18, 20, 26, 27, 28))))
         and ((pFolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoRecalculoMes AND fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoRecalculoMes)
             or 
              (pFolha.CdTipoCalculo <> pkgpag_tipo.cnTpCalculoRecalculoMes AND fp.cdtipocalculo in (pFolha.CdTipoCalculo, pkgpag_tipo.cnTpCalculoNormal)))     
        -- and fp.cdtipocalculo in (pFolha.CdTipoCalculo, pkgpag_tipo.cnTpCalculoNormal)
         and fp.flcalculodefinitivo = case when pFolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoRecalculoMes
                                           then fp.flcalculodefinitivo else pfolha.FlCalculoDefinitivo end )

    SELECT nvl(SUM(rv.vlpagamento), 0) AS vlpago
      INTO vvlpago
      FROM epaghistoricorubricavinculo rv
     INNER JOIN fol fp
        ON fp.cdfolhapagamento = rv.cdfolhapagamento
     INNER JOIN ecadvinculo v
        ON v.cdvinculo = rv.cdvinculo
     INNER JOIN vpagrubricaagrupamento r
        ON r.cdrubricaagrupamento = rv.cdrubricaagrupamento
     WHERE v.cdpessoa = pcdpessoa
       AND rv.cdrubricaagrupamento = pcdrubricaagrupamento
       and ((rv.cdvinculo <> PKGPAG_VAR.vgvinculo.cdvinculo) or
            (rv.cdvinculo = PKGPAG_VAR.vgvinculo.cdvinculo and fp.cdtipofolhapagamento <> pFolha.CdTipoFolhaPagamento));

    RETURN vvlpago;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneCELG
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/

  FUNCTION fmnecelg(pcdvalorgeralcefagrup IN INTEGER,
                    pnuversao             IN INTEGER,
                    pnuano                IN INTEGER,
                    pnumes                IN INTEGER,
                    pnunivel              IN VARCHAR2,
                    pnureferencia         IN VARCHAR2)

   RETURN NUMBER IS

    vvlfixo NUMBER(13, 2);

  BEGIN
 
    SELECT vlfixo
      INTO vvlfixo
      FROM (SELECT ve.vlfixo, nvga.nuversao
              FROM epagvalorgeralcefagrup vga
             INNER JOIN epagvalorgeralcefagrupversao nvga
                ON vga.cdvalorgeralcefagrup = nvga.cdvalorgeralcefagrup
             INNER JOIN epaghistvalorgeralcefagrup hvga
               ON NVGA.CdValorGeralCEFAgrupVersao= HVGA.CdValorGeralCEFAgrupVersao
             INNER JOIN epagvalorespeccefagrup ve
               ON HVGA.CdHistValorGeralCEFAgrup = VE.CdHistValorGeralCEFAgrup
            WHERE NVGA.NuVersao IN (pNuVersao,PKGPAG_TIPO.cn1) AND
                  NVGA.CdValorGeralCEFAgrup = pCdValorGeralCEFAgrup AND
                  VE.NuNivel = pNuNivel AND
                  VE.NuReferencia = pNuReferencia AND
                 ((HVGA.NuAnoInicioVigencia < pNuAno OR
                   (hvga.nuanoiniciovigencia = pnuano AND
                  HVGA.NuMesInicioVigencia <= pNuMes))
                 AND
                   (hvga.nuanofimvigencia > pnuano OR
                   (hvga.nuanofimvigencia = pnuano AND
                   hvga.numesfimvigencia >= pnumes) OR
                   hvga.nuanofimvigencia IS NULL))
             ORDER BY nvga.nuversao DESC)
     WHERE rownum < 2;

    RETURN vvlfixo;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fmneRemunBaseOutraEsfera(pCdVinculo in INTEGER)

   RETURN NUMBER IS

    vvlfixo NUMBER(13, 2) := 0;

  BEGIN
     with esfera as (select *
        from epaghistvaloroutraesferavinc ehv
       where ehv.cdvinculo = pCdVinculo
         and ehv.flanulado = pkgpag_tipo.cnN
       order by ehv.dtinicio desc)
    SELECT esf.vlvencimento
      INTO vvlfixo
      FROM esfera esf
     where rownum < 2;

    RETURN vvlfixo;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fmnecel(pcdestruturacarreira IN INTEGER,
                   pnuversao            IN INTEGER,
                   pnuano               IN INTEGER,
                   pnumes               IN INTEGER,
                   pnureferencia        IN VARCHAR2,
                   pnunivel             IN VARCHAR2)

   RETURN NUMBER IS

    vvlfixo NUMBER(13, 2);

  BEGIN
 
    SELECT vlfixo
      INTO vvlfixo
      FROM (SELECT v.vlfixo, nrav.nuversao
              FROM epaghistnivelrefcarrcefagrup h
             INNER JOIN epaghistnivelrefcefagrup hnra
                ON h.cdhistnivelrefcefagrup = hnra.cdhistnivelrefcefagrup
             INNER JOIN epagnivelrefcefagrupversao nrav
                ON NRAV.CdNivelRefCEFAgrupVersao =
                   HNRA.cdNivelRefCEFAgrupVersao
             INNER JOIN epagvalorcarreiracefagrup v
                ON h.cdhistnivelrefcarrcefagrup =
                   v.cdhistnivelrefcarrcefagrup
             WHERE v.nunivel = pnunivel
               AND v.nureferencia = pnureferencia
               AND h.cdestruturacarreira = pcdestruturacarreira
               AND ((hnra.nuanoiniciovigencia < pnuano OR
                   (hnra.nuanoiniciovigencia = pnuano AND
                   hnra.numesiniciovigencia <= pnumes)) AND
                   (hnra.nuanofimvigencia > pnuano OR
                   (hnra.nuanofimvigencia = pnuano AND
                   hnra.numesfimvigencia >= pnumes) OR
                   hnra.nuanofimvigencia IS NULL))
             ORDER BY nrav.nuversao DESC)
     WHERE rownum < 2;

    RETURN vvlfixo;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;
  /*----------------------------------------------------------------------------
       Funcao: FMneBaseInc
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/
  FUNCTION fmnebaseinc(pcdincorporacao IN INTEGER,
                       pfolha          IN pkgpag_tipo.rfolha)

   RETURN NUMBER IS

    vvlfixo           NUMBER(13, 2);
    vcdpadraofucagrup INTEGER;
    vvlreferencia     NUMBER(13, 2);

  BEGIN
 
    FOR vincorp IN (SELECT ia.cdtipoincorporacaoativo,
                           ia.cdvalorreferencia,
                           ia.nunivelcef,
                           ia.nureferenciacef,
                           ia.cdvalorgeralcefagrup,
                           ia.flutilizabaseniverefcef,
                           ia.decodigocomissionado,
                           ia.nunivelcomissionado,
                           ia.flutilizatabpropria,
                           ia.depadraofuc,
                           ia.qtvalorreferencia,
                           ia.vlminimorecebimento,
                           ia.flatualizacaoconstante,
                           ia.cdbaseincorporacaoativo,
                         CASE WHEN IA.CdRelacaoTrabalho IS NULL THEN
                              6
                             ELSE
                              ia.cdrelacaotrabalho
                           END cdrelacaotrabalho,
                           ia.vlfixo
                      FROM ebpcincorporacaoativo ia
                   WHERE IA.CdIncorporacaoAtivo = pCdIncorporacao)
   LOOP

      CASE vincorp.cdbaseincorporacaoativo

       WHEN 1 THEN -- Exige o n?vel/refer?ncia do cargo efetivo

          RETURN fmnecelg(vincorp.cdvalorgeralcefagrup,
                          pFolha.NuVersaoTabCEF,
                          pFolha.NuAnoReferencia,
                          pFolha.NuMesReferencia,
                          vIncorp.NuNivelCEF,
                          vincorp.nureferenciacef);

       WHEN 2 THEN -- Exige o c?digo/n?vel do cargo comissionado

          IF vincorp.flutilizatabpropria = pkgpag_tipo.cnn THEN

           RETURN PKGPAG_GERAL.FRetornaValorFixoCCO(
                                       vIncorp.DeCodigoComissionado,
                                                     vincorp.nunivelcomissionado,
                                                     vIncorp.CdRelacaoTrabalho, -- Comissionado
                                                     pfolha.cdagrupamento,
                                                     pfolha.cdorgao,
                                                     pfolha.nuversaotabcco,
                                                     pfolha.nuanoreferencia,
                                                     pfolha.numesreferencia);
          ELSE

            BEGIN

              SELECT vci.vlfixo
                INTO vvlfixo
                FROM ebpccargocomincorp cci
               INNER JOIN ebpcvalorcargocomincorp vci
                  ON cci.cdcargocomincorp = vci.cdcargocomincorp
              WHERE VCI.NmCodigo = vIncorp.DeCodigoComissionado AND
                    CCI.CdAgrupamento = pFolha.CdAgrupamento AND
                    VCI.CdNivel = vIncorp.NuNivelComissionado AND
                    ((CCI.NuAnoInicio < pFolha.NuAnoReferencia OR
                     (cci.nuanoinicio = pfolha.nuanoreferencia AND
                     CCI.NuMesInicio <= pFolha.NuMesReferencia))
                    AND
                     (cci.nuanofim > pfolha.nuanoreferencia OR
                     (cci.nuanofim = pfolha.nuanoreferencia AND
                     cci.numesfim >= pfolha.numesreferencia) OR
                     cci.nuanofim IS NULL));

              RETURN vvlfixo;

            EXCEPTION

              WHEN no_data_found THEN

                RETURN 0;

            END;

          END IF;

       WHEN 3 THEN -- Exige o padr?o da fun??o de chefia

          BEGIN

            SELECT pfa.cdpadraofucagrup
              INTO vcdpadraofucagrup
              FROM epagpadraofucagrup pfa
            WHERE PFA.NmPadrao = vIncorp.DePadraoFUC AND
                  PFA.CdAgrupamento = pFolha.CdAgrupamento;

          EXCEPTION

            WHEN no_data_found THEN

              RETURN 0;

          END;

          IF vincorp.flutilizatabpropria = pkgpag_tipo.cnn THEN

            RETURN PKGPAG_GERAL.fretornavalorfixofuc(vcdpadraofucagrup,
                                                     pfolha.cdagrupamento,
                                                     pfolha.cdorgao,
                                                     pfolha.nuversaotabfuc,
                                                     pfolha.nuanoreferencia,
                                                     pfolha.numesreferencia);

          ELSE

            BEGIN

              SELECT vfi.vlfixo
                INTO vvlfixo
                FROM ebpcfuncaochefiaincorp fci
               INNER JOIN ebpcvalorfuncaochefiaincorp vfi
                  ON fci.cdfuncaochefiaincorp = vfi.cdfuncaochefiaincorp
              WHERE FCI.CdAgrupamento = pFolha.CdAgrupamento AND
                    VFI.CdPadraoFUCAgrup = vCdPadraoFUCAgrup AND
                    ((FCI.NuAnoInicio < pFolha.NuAnoReferencia OR
                     (fci.nuanoinicio = pfolha.nuanoreferencia AND
                     FCI.NuMesInicio <= pFolha.NuMesReferencia))
                    AND
                     (fci.nuanofim > pfolha.nuanoreferencia OR
                     (fci.nuanofim = pfolha.nuanoreferencia AND
                     fci.numesfim >= pfolha.numesreferencia) OR
                     fci.nuanofim IS NULL));

              RETURN vvlfixo;

            EXCEPTION

              WHEN no_data_found THEN

                RETURN 0;

            END;

          END IF;

       WHEN 4 THEN -- Exige um valor de refer?ncia

          IF vincorp.cdvalorreferencia IS NOT NULL THEN

            BEGIN

              vVlReferencia := PKGPAG_VAR.vgValorReferencia(vIncorp.CdValorReferencia).VlReferencia;

              RETURN vvlreferencia * vincorp.qtvalorreferencia;

            EXCEPTION

              WHEN no_data_found THEN

                RETURN 0;

            END;

          END IF;

       WHEN 5 THEN -- Considera o valor do n?vel/refer?ncia do cargo efetivo atual do servidor

          IF PKGPAG_VAR.vgvalorfixocef.vlfixo IS NOT NULL THEN

            RETURN PKGPAG_VAR.vgvalorfixocef.vlfixo;

          END IF;
          -- Inclus?o EPAGRI
       WHEN 6
         THEN

           IF pFolha.CdAgrupamento = 5
             THEN
            RETURN vincorp.vlfixo;
          ELSE
            RETURN 0;

          END IF;

        ELSE

          RETURN 0;

      END CASE;

    END LOOP;

    RETURN 0;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneSubstCCO
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/

  FUNCTION fmnesubstcco(pcdrelacaovinculo IN INTEGER,
                        pcdhistcargocom   IN INTEGER,
                        pfolha            IN pkgpag_tipo.rfolha,
                        pccosubst         IN pkgpag_tipo.tcco,
                        pdtcalculo        IN DATE)

   RETURN NUMBER IS

    vvlfixo NUMBER(13, 2) DEFAULT 0;

  BEGIN
 
    IF pccosubst.count > 0 THEN

      IF pccosubst.count = 1 THEN

        vvlfixo := PKGPAG_GERAL.fretornavalorfixocco(pccosubst             (1).nunivel,
                                                     pCCOSubst             (1).NuReferencia,
                                                     pCCOSubst             (1).CdRelacaoTrabalho,
                                                     pfolha.cdagrupamento,
                                                     pfolha.cdorgao,
                                                     pfolha.nuversaotabcco,
                                                     pfolha.nuanoreferencia,
                                                     pfolha.numesreferencia);

      ELSIF pcdrelacaovinculo = 2 THEN

       FOR i IN pCCOSubst.FIRST .. pCCOSubst.LAST
       LOOP

          IF pccosubst(i).cdhistcargocom = pcdhistcargocom THEN

            vVlFixo := PKGPAG_GERAL.FRetornaValorFixoCCO(pCCOSubst             (i).NuNivel,
                                                         pCCOSubst             (i).NuReferencia,
                                                         pCCOSubst             (i).CdRelacaoTrabalho,
                                                         pfolha.cdagrupamento,
                                                         pfolha.cdorgao,
                                                         pfolha.nuversaotabcco,
                                                         pfolha.nuanoreferencia,
                                                         pfolha.numesreferencia);
          END IF;

        END LOOP;

      ELSE

        FOR i IN pCCOSubst.FIRST .. pCCOSubst.LAST
        LOOP

          IF pdtcalculo >= pccosubst(i).dtinicio AND
             (pDtCalculo <= pCCOSubst(i).DtFim OR pCCOSubst(i).DtFim IS NULL) THEN

            vVlFixo := PKGPAG_GERAL.FRetornaValorFixoCCO(pCCOSubst             (i).NuNivel,
                                                         pCCOSubst             (i).NuReferencia,
                                                         pCCOSubst             (i).CdRelacaoTrabalho,
                                                         pfolha.cdagrupamento,
                                                         pfolha.cdorgao,
                                                         pfolha.nuversaotabcco,
                                                         pfolha.nuanoreferencia,
                                                         pfolha.numesreferencia);
          END IF;

        END LOOP;

      END IF;

      RETURN vvlfixo;

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneSubstFUC
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/

  FUNCTION fmnesubstfuc(pcdrelacaovinculo   IN INTEGER,
                        pcdhistfuncaochefia IN INTEGER,
                        pfolha              IN pkgpag_tipo.rfolha,
                        pfucsubst           IN pkgpag_tipo.tfuc,
                        pdtcalculo          IN DATE)

   RETURN NUMBER IS

    vvlpadrao NUMBER(13, 2) DEFAULT 0;

  BEGIN
 
    IF pfucsubst.count > 0 THEN

      IF pfucsubst.count = 1 THEN

        vvlPadrao := PKGPAG_GERAL.FRetornaValorFixoFUC(pFUCSubst(1).CdPadraoFucAgrup,
                                                       pfolha.cdagrupamento,
                                                       pfolha.cdorgao,
                                                       pfolha.nuversaotabfuc,
                                                       pfolha.nuanoreferencia,
                                                       pfolha.numesreferencia);

      ELSIF pcdrelacaovinculo = 3 THEN

      FOR i IN pFUCSubst.FIRST .. pFUCSubst.LAST
      LOOP

          IF pfucsubst(i).cdhistfuncaochefia = pcdhistfuncaochefia THEN

            CASE

              WHEN pfucsubst(i).cdpadraofucagrup IS NOT NULL THEN

                vvlPadrao := PKGPAG_GERAL.FRetornaValorFixoFUC(pFUCSubst(i).CdPadraoFucAgrup,
                                                               pfolha.cdagrupamento,
                                                               pfolha.cdorgao,
                                                               pfolha.nuversaotabfuc,
                                                               pfolha.nuanoreferencia,
                                                               pfolha.numesreferencia);

              WHEN pfucsubst(i).cdpadraofucagrup IS NULL THEN

                vvlpadrao := 0;

              ELSE

                vvlpadrao := 0;

            END CASE;

          END IF;

        END LOOP;

      ELSE

      FOR i IN pFUCSubst.FIRST .. pFUCSubst.LAST
      LOOP

          IF pdtcalculo >= pfucsubst(i).dtinicio AND
             (pDtCalculo <= pFUCSubst(i).DtFim OR pFUCSubst(i).DtFim IS NULL) THEN

            vvlPadrao := PKGPAG_GERAL.FRetornaValorFixoFUC(pFUCSubst(i).CdPadraoFucAgrup,
                                                           pfolha.cdagrupamento,
                                                           pfolha.cdorgao,
                                                           pfolha.nuversaotabfuc,
                                                           pfolha.nuanoreferencia,
                                                           pfolha.numesreferencia);
          END IF;

        END LOOP;

      END IF;

      RETURN vvlpadrao;

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fmnerub(pcdvinculo            IN INTEGER,
                   pcdblocoexpressao     IN INTEGER,
                   pcdfolhahistatu       IN INTEGER,
                   pcdfolhahistalt       IN INTEGER,
                   pinrelacaorubrica     IN CHAR,
                   pintiporubrica        IN CHAR,
                   pinmes                IN CHAR,
                   pnumesrub             IN INTEGER,
                   pnuanorub             IN INTEGER,
                   pcdtipohistorico      IN INTEGER,
                   pcdrelacaovinculo     IN INTEGER,
                   pflbasecalculo        IN BOOLEAN,
                   pcdchave              IN INTEGER,
                   pcdrubricaagrupamento IN INTEGER, -- Rubrica da F?rmula
                   pnuanoreferencia      IN INTEGER,
                   pnumesreferencia      IN INTEGER,
                   ptptributacao         IN INTEGER,
                   pCdBaseCalculo        IN INTEGER,
                   pCdAgrupamento        IN INTEGER,
                   pCdMnemonico          IN INTEGER DEFAULT NULL)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vvlrub pkgpag_tipo.rvalorpagamento;

    vnuanoant         NUMBER(4);

    vnumesant         NUMBER(2);
    
    vNuDiasAfast      INTEGER;

    vCdFolhaRecalculo INTEGER;

    --vCdRelacaoVinculo INTEGER;

    --vCdTipoHistorico INTEGER;

    --vCdBlocoExpressao INTEGER;

    ----------------

  FUNCTION FObterInfoRelVinc(pCdFolhaHistorico IN INTEGER,
                             pCdVinculo        IN INTEGER, 
                             pCdChave          IN INTEGER,
                             pCdRelacaoVinculo IN INTEGER) RETURN rInfoRelVinc IS
                             
    vInfoRelVinc rInfoRelVinc;                         
  BEGIN
    vInfoRelVinc.cdChave := pCdChave;
    vInfoRelVinc.cdRelacaoVinculo := pCdRelacaoVinculo;
    
    SELECT DISTINCT CDCHAVE, CDRELACAOVINCULO
      INTO vInfoRelVinc.cdChave, vInfoRelVinc.cdRelacaoVinculo
      FROM EPAGHISTORICORUBRICARELVINC HRV
     WHERE HRV.CDFOLHAPAGAMENTO = pCdFolhaHistorico
       AND HRV.CDVINCULO = pCdVinculo;       
  
    RETURN vInfoRelVinc;
    
    EXCEPTION    
      WHEN OTHERS THEN
        RETURN vInfoRelVinc;      
  END;                             

  FUNCTION FObtemValores
     (PFlBaseCalculo          IN BOOLEAN,
                           pcdfolhahistorico     IN INTEGER,
                           pcdtipohistorico      IN INTEGER,
                           pdescrubisentaformula IN BOOLEAN,
                           pnuanoreferencia      IN INTEGER,
                           pnumesreferencia      IN INTEGER,
                           ptptributacao         IN INTEGER,
      pFlValorZero          IN BOOLEAN DEFAULT FALSE) RETURN PKGPAG_TIPO.rValorPagamento IS

      vvlrubrica         pkgpag_tipo.rvalorpagamento;
      vVlRubricaIprevCco PKGPAG_TIPO.rValorPagamento;
      vVlRubricaFerias   PKGPAG_TIPO.rValorPagamento;
      vSgBaseCalculo     VARCHAR2(10);
      vDataAux           CHAR(10);
      vcharaux           varchar2(40);
      vcdblocoexpressao  INTEGER := 0;
      vVlSuplementar     number(13, 2);
      vInfoRelVinc       rInfoRelVinc;
      vVlPgtoBlocoRRA    pkgpag_tipo.rvalorpagamento;

      FUNCTION FObterValorBloco(pInMes              IN CHAR,
                                pNuAnoRub           IN INTEGER,
                                pNuMesRub           IN INTEGER,
                                pNuAnoReferencia    IN INTEGER,
                                pNuMesReferencia    IN INTEGER,
                                pCdVinculo          IN INTEGER,
                                pCdFolhaHistorico   IN INTEGER,
                                pCdFormCalcBlocoExp IN INTEGER,
                                pCdChave            IN INTEGER,
                                pCdRelacaoVinculo   IN INTEGER,
                            pCdTipoFolha        IN INTEGER) RETURN pkgpag_tipo.rvalorpagamento IS
        vvlrubrica           pkgpag_tipo.rvalorpagamento;
        vCdFolhasHistorico   sys.odcinumberlist := sys.odcinumberlist(pCdFolhaHistorico);
        vNuAno               INTEGER := pNuAnoReferencia;
        vNuMes               INTEGER := pNuMesReferencia;
        vFlCalculoDefinitivo CHAR := 'S';
      BEGIN
 
        IF (pInMes = 'RI') THEN
          if (pCdTipoFolha = PKGPAG_TIPO.cnTpFolhaInstPensao) then
            vFlCalculoDefinitivo := 'N';
          end if;
          vNuAno             := pNuAnoRub;
          vNuMes             := pNuMesRub;
          vCdFolhasHistorico := PKGPAG_GERAL.FObterFolhasPagamentoCapa(pcdvinculo           => pcdvinculo,
                                                                       pNuAno               => vNuAno,
                                                                       pNuMes               => vNuMes,
                                                                       pFlCalculoDefinitivo => vFlCalculoDefinitivo);
        END IF;

        SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
               nvl(SUM(v.vlintegral), 0) AS vlintegral,
               CASE pintiporubrica
                 WHEN 'I' THEN
                  nvl(SUM(v.vlintegral), 0)
                 WHEN 'R' THEN
                  nvl(SUM(v.vlreal), 0)
                 ELSE
                  nvl(SUM(v.vlproporcional), 0)
               END AS,
               nvl(SUM(v.vlindicerubrica), 0) AS vlindicerubrica
    INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional, vVlRubrica.vlIndice
          FROM (SELECT hrv.cdvinculo,
                       SUM(hrv.vlintegral) AS vlintegral,
                       SUM(hrv.vlproporcional) AS vlproporcional,
                       SUM(hrv.vlreal) AS vlreal,
                       SUM(hrv.vlindicerubrica) AS vlindicerubrica
                  FROM epaghistoricorubricarelvinc hrv
          WHERE HRV.CdFolhaPagamento IN (SELECT column_value FROM TABLE (vCdFolhasHistorico)) AND
                HRV.CdVinculo = pCdVinculo AND
                ((pInMes = 'RI' AND pCdRelacaoVinculo = 4) OR DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave) AND
                ((pInMes = 'RI' AND pCdRelacaoVinculo = 4) OR DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo) AND
                EXISTS
           (SELECT 1
                          FROM epagformcalcblocoexprubagrup b
                 WHERE B.CdFormulaCalcBlocoExpressao = pCdFormCalcBlocoExp AND
                       B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento)
                 GROUP BY hrv.cdvinculo) v;

        RETURN vvlrubrica;

      EXCEPTION

        WHEN OTHERS THEN

          RETURN vvlrubrica;
      END;

      
    FUNCTION FObterValorBlocoRRA(pCdVinculo                     IN INTEGER,
                                 pCdFolhaHistorico              IN INTEGER,
                                 pCdProcessoPagRetroativo       IN INTEGER,
                                 pCdBlocoExpressao              IN INTEGER,
                                 pCdRubAgrupBloqRetExercFind    IN INTEGER,
                                 pCdRubAgrupBloqExercFind13Sal  IN INTEGER) RETURN pkgpag_tipo.rvalorpagamento IS
      vVlPagamento pkgpag_tipo.rvalorpagamento;    
    BEGIN
      vVlPagamento.vlIntegral     := NULL;
      vVlPagamento.vlProporcional := NULL;
      vVlPagamento.vlReal         := NULL;
      
      SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
             nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
             nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
      INTO vVlPagamento.vlReal, vVlPagamento.vlIntegral, vVlPagamento.vlProporcional
        FROM epaghistoricorubricavinculo hv
     WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
           HV.CdVinculo = pCdVinculo AND
           HV.CdProcessoPagRetroativo = pCdProcessoPagRetroativo AND
           EXISTS
       (SELECT b.cdrubricaagrupamento
                FROM epagbasecalcblocoexprrubagrup b
               INNER JOIN epagrubricaagrupamento ra
                ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
               INNER JOIN epagrubrica r
                  ON r.cdrubrica = ra.cdrubrica
             WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                   B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                   (R.CdTipoRubrica IN (10,12) OR (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915, 926)) OR
                   (R.CdTipoRubrica = 9 AND R.NuRubrica = 1908) OR 
                   (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95) OR
                     (ra.flpensaoalimenticia = 'S') OR
                   B.CdRubricaAgrupamento IN (nvl(pCdRubAgrupBloqRetExercFind,0),
                       nvl(pCdRubAgrupBloqExercFind13Sal,0)))) ;

      RETURN vVlPagamento; 
                       
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RETURN vVlPagamento;
            
        WHEN TOO_MANY_ROWS THEN
          RETURN vVlPagamento;  
          
        WHEN OTHERS THEN
          RETURN vVlPagamento;
    END;  

    BEGIN
 
      vVlRubricaIprevCco.vlReal         := 0;
      vVlRubricaIprevCco.vlIntegral     := 0;
      vVlRubricaIprevCco.vlProporcional := 0;
      vVlRubricaFerias.vlReal           := 0;
      vVlRubricaFerias.vlIntegral       := 0;
      vVlRubricaFerias.vlProporcional   := 0;

  vDataAux := to_char('01' || '/' || pNuMesReferencia || '/' || pNuAnoReferencia);

  vcharaux := pCdBlocoExpressao || ' - ' || pInRelacaoRubrica || ' - ' ||  pCdChave ;

      IF pCdBaseCalculo is not null THEN
        SELECT bc.sgbasecalculo
          INTO vSgBaseCalculo
          FROM epagbasecalculo bc
         WHERE bc.cdbasecalculo = pCdBaseCalculo
           AND bc.cdagrupamento = pCdAgrupamento;
      END IF;

      --
      -- Base tributacao exclusiva IPREV sobre remuneracao de comissionado
      --

    IF (vSgBaseCalculo = 'OPC70'
        AND PKGPAG_VAR.bPossuiIprevCCO = FALSE)
    OR (vSgBaseCalculo = 'SCPRE'
        AND pkgpag_geral.FRetornaRegimeProprioPrev(pCdVinculo) not in (3,4))
        --
        -- Solicitacao de Sustentacao #76173
        -- PGTC - Problemas na implantacao de desconto para o SCPREV - Nao gerar para relacao de comissionado
        --
    OR (vSgBaseCalculo = 'SCPRE'
        AND pCdRelacaoVinculo = 2 AND PKGPAG_VAR.vgFolha.CdOrgao = 46)
    OR (vSgBaseCalculo = 'ESTSC'
        AND (PKGPAG_VAR.vgVinculo.CdRegimePrevidenciario = 1 OR
         PKGPAG_VAR.vgcef.Count = 0 OR
             ((PKGPAG_VAR.vgcef.Count > 0 and
               PKGPAG_VAR.vgfuc.count = 0 AND PKGPAG_VAR.vgcco.count = 0))))

       THEN

        vVlRubrica.vlReal         := 0;
        vVlRubrica.vlIntegral     := 0;
        vVlRubrica.vlProporcional := 0;
        RETURN vVlRubrica;

      END IF;

    IF pFlBaseCalculo THEN -- Se est? calculando BASE

        IF pCdTipoHistorico = 1 AND NOT
           -- Implantacao CIDASC
            (PKGPAG_VAR.vgFolha.FlOrgaoImplantado = 'N' and
            PKGPAG_VAR.vgfolha.CdAgrupamento = 4 AND
            vSgBaseCalculo = 'BFERM')

          THEN  -- Rela??o de v?nculo

          IF NOT pdescrubisentaformula THEN

            IF NOT pflvalorzero THEN

              -- fluxo normal. Nao e iprev ou e iprev e nao tem incidencia sobre cco
        IF vSgBaseCalculo not in ('OPC70')

               THEN

                SELECT nvl(SUM(hrv.vlreal), 0) AS vlreal,
                       nvl(SUM(hrv.vlintegral), 0) AS vlintegral,
                       nvl(SUM(CASE pintiporubrica
                                 WHEN 'I' THEN
                                  hrv.vlintegral
                                 WHEN 'R' THEN
                                  hrv.vlreal
                                 ELSE
                                  hrv.vlproporcional
                END), 0) AS vlproporcional
              INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricarelvinc   hrv,
                       epagbasecalcblocoexprrubagrup b
              WHERE HRV.CdFolhaPagamento = pCdFolhaHistorico AND
                   HRV.CdVinculo = pCdVinculo AND
                 B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                 B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento AND
                (pInRelacaoRubrica <> 'R' OR HRV.CdChave = pCdChave) AND
                (pInRelacaoRubrica <> 'R' OR HRV.CdRelacaoVinculo = pCdRelacaoVinculo);

            IF PKGPAG_VAR.vgFolha.CdAgrupamento = 4
              AND vSgBaseCalculo = 'B0930'
                THEN
                  vVlRubrica.VlReal               := 0;
                  vVlRubrica.vlIntegral           := 0;
                  vVlRubrica.vlProporcional       := 0;
                  vVlRubricaFerias.VlReal         := 0;
                  vVlRubricaFerias.vlIntegral     := 0;
                  vVlRubricaFerias.vlProporcional := 0;

                  IF pCdRelacaoVinculo = 1
                    THEN

                  with RubExp as (SELECT b.Cdrubricaagrupamento
                        FROM epagbasecalcblocoexprrubagrup b
                                   WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao)
                    SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                           nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                           nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                      INTO vVlRubricaFerias.vlReal, vVlRubricaFerias.vlIntegral, vVlRubricaFerias.vlProporcional
                      FROM epaghistoricorubricavinculo hv
                      INNER JOIN RUBEXP R on r.cdrubricaagrupamento = hv.cdrubricaagrupamento
                     WHERE hv.cdvinculo = pcdvinculo
                       AND hv.cdfolhapagamento = PKGPAG_VAR.vgCdFolhaFerias;

                  END IF;

                  SELECT nvl(SUM(hrv.vlreal), 0) AS vlreal,
                         nvl(SUM(hrv.vlintegral), 0) AS vlintegral,
                         nvl(SUM(CASE pintiporubrica
                                   WHEN 'I' THEN
                                    hrv.vlintegral
                                   WHEN 'R' THEN
                                    hrv.vlreal
                                   ELSE
                                    hrv.vlproporcional
                         END), 0) AS vlproporcional
                        INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricarelvinc   hrv,
                         epagbasecalcblocoexprrubagrup b
                       WHERE HRV.CdFolhaPagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                     AND HRV.CdVinculo = pCdVinculo
                     AND B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao
                     AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
                         AND (pInRelacaoRubrica <> 'R' OR HRV.CdChave = pCdChave)
                         AND (pInRelacaoRubrica <> 'R' OR HRV.CdRelacaoVinculo = pCdRelacaoVinculo);

                   vVlRubrica.vlReal := vVlRubrica.vlReal + NVL(vVlRubricaFerias.vlReal,0);
                   vVlRubrica.vlIntegral := vVlRubrica.vlIntegral + NVL(vVlRubricaFerias.vlIntegral,0);
                   vVlRubrica.vlProporcional := vVlRubrica.vlProporcional + NVL(vVlRubricaFerias.vlProporcional,0);

                END IF;

       ELSIF vSgBaseCalculo = 'OPC70'
         THEN
                --
                -- Base OPC70 - Atribuir valor 1, calcular posteriormente.
                --
        IF (PKGPAG_VAR.bPossuiIprevCCO = FALSE)
          THEN
                  vVlRubrica.vlReal         := 1;
                  vVlRubrica.vlIntegral     := 1;
                  vVlRubrica.vlProporcional := 1;
                END IF;

                vVlRubricaIprevCco.vlReal         := 0;
                vVlRubricaIprevCco.vlIntegral     := 0;
                vVlRubricaIprevCco.vlProporcional := 0;

              else
                null;
              END IF;

      ELSIF vSgBaseCalculo = 'BFER' AND pInRelacaoRubrica = 'I'
            and (PKGPAG_VAR.vgNuDiasAfastSemRemun > 0 OR PKGPAG_VAR.vgNuDiasAfastDefinitivo > 0) then

              IF PKGPAG_VAR.vgNuDiasAfastSemRemun > 0 THEN
              
                 vNuDiasAfast := PKGPAG_VAR.vgNuDiasAfastSemRemun;
                             
              ELSE  
                            
                 vNuDiasAfast := PKGPAG_VAR.vgNuDiasAfastDefinitivo;
            
              END IF;
            

              SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                     nvl(SUM(v.vlintegral), 0) AS vlintegral,
                     nvl(SUM(v.vlproporcional), 0) AS vlproporcional
                INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM (SELECT hrv.cdvinculo,
                    trunc(nvl(SUM(hrv.vlintegral / (30 - vNuDiasAfast) * 30), 0),2) AS vlintegral,
                    trunc(nvl(SUM(hrv.vlproporcional / (30 - vNuDiasAfast) * 30),0),2) AS vlproporcional,
                             SUM(hrv.vlreal) AS vlreal
                        FROM epaghistoricorubricarelvinc hrv
                       WHERE HRV.CdVinculo = pCdVinculo
                    and hrv.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                    and DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave
                    and DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo
                         and EXISTS
                       (SELECT 1
                                FROM epagbasecalcblocoexprrubagrup b
                         WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao
                           AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento)
                       GROUP BY hrv.cdvinculo) v;

      ELSE

              SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                     nvl(SUM(v.vlintegral), 0) AS vlintegral,
                     CASE pintiporubrica
                       WHEN 'I' THEN
                        nvl(SUM(v.vlintegral), 0)
                       WHEN 'R' THEN
                        nvl(SUM(v.vlreal), 0)
                       ELSE
                        nvl(SUM(v.vlproporcional), 0)
                     END AS vlproporcional
         INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM (SELECT hrv.cdvinculo,
                             SUM(hrv.vlintegral) AS vlintegral,
                             SUM(hrv.vlproporcional) AS vlproporcional,
                             SUM(hrv.vlreal) AS vlreal
                        FROM epaghistoricorubricarelvinc hrv
                       INNER JOIN ECalFolhaPag fp
                          ON hrv.cdfolhapagamento = fp.cdfolhapagamento
                         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
            WHERE HRV.CdVinculo = pCdVinculo AND
               FP.NuAnoReferencia = pNuAnoReferencia AND
               FP.NuMesReferencia = pNuMesReferencia AND
               FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
               FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl)  AND
               FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
               DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave AND
               DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo AND
               EXISTS
                       (SELECT 1
                                FROM epagbasecalcblocoexprrubagrup b
                WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                   B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento)
                       GROUP BY hrv.cdvinculo) v;

            END IF;

          ELSE

            IF NOT pflvalorzero THEN

              SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                     nvl(SUM(v.vlintegral), 0) AS vlintegral,
                     CASE pintiporubrica
                       WHEN 'I' THEN
                        nvl(SUM(v.vlintegral), 0)
                       WHEN 'R' THEN
                        nvl(SUM(v.vlreal), 0)
                       ELSE
                        nvl(SUM(v.vlproporcional), 0)
                     END AS vlproporcional
                 INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM (SELECT hrv.cdvinculo,
                             SUM(hrv.vlintegral) AS vlintegral,
                             SUM(hrv.vlproporcional) AS vlproporcional,
                             SUM(hrv.vlreal) AS vlreal
                        FROM epaghistoricorubricarelvinc hrv
                         WHERE HRV.CdFolhaPagamento = pCdFolhaHistorico AND
                               HRV.CdVinculo = pCdVinculo AND
                               DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave AND
                               DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo AND
                               EXISTS
                       (SELECT 1
                                FROM epagbasecalcblocoexprrubagrup b
                                WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                      B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento AND
                                     b.cdrubricaagrupamento NOT IN
                                     (SELECT tr.cdrubricaagrupamento
                                        FROM etrbisencaorubrica tr
                                       INNER JOIN etrbhistisencaorubrica htr
                                             ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                       INNER JOIN etrbrubricaisentaformula tif
                                             ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                          WHERE TR.CdVinculo = pCdVinculo AND
                                                TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                                ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                                (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                                HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                                AND
                                                (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                                (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                                HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                             htr.numesfimvigencia IS NULL))))
                       GROUP BY hrv.cdvinculo) v;

                IF vSgBaseCalculo = 'B0040'
                  AND vVlRubrica.vlReal = 0
                  AND vVlRubrica.vlIntegral = 0
                  AND vVlRubrica.vlProporcional = 0
                  AND PKGPAG_VAR.vgcef.count > 0
                  AND PKGPAG_VAR.vgapo.count > 0
                  AND PKGPAG_VAR.vgapo(1).DtInicio > PKGPAG_VAR.vgFolha.DtInicioMes

               THEN

                SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                       nvl(SUM(v.vlintegral), 0) AS vlintegral,
                       CASE pintiporubrica
                         WHEN 'I' THEN
                          nvl(SUM(v.vlintegral), 0)
                         WHEN 'R' THEN
                          nvl(SUM(v.vlreal), 0)
                         ELSE
                          nvl(SUM(v.vlproporcional), 0)
                       END AS vlproporcional
                 INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM (SELECT hrv.cdvinculo,
                               SUM(hrv.vlintegral) AS vlintegral,
                               SUM(hrv.vlproporcional) AS vlproporcional,
                               SUM(hrv.vlreal) AS vlreal
                          FROM epaghistoricorubricarelvinc hrv
                         WHERE HRV.CdFolhaPagamento = pCdFolhaHistorico AND
                               HRV.CdVinculo = pCdVinculo AND
                               DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = 1 AND
                               EXISTS
                         (SELECT 1
                                  FROM epagbasecalcblocoexprrubagrup b
                                WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                      B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento AND
                                     b.cdrubricaagrupamento NOT IN
                                       (SELECT tr.cdrubricaagrupamento
                                          FROM etrbisencaorubrica tr
                                         INNER JOIN etrbhistisencaorubrica htr
                                             ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                         INNER JOIN etrbrubricaisentaformula tif
                                             ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                          WHERE TR.CdVinculo = pCdVinculo AND
                                                TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                                ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                                (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                                HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                                AND
                                                (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                                (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                                HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                               htr.numesfimvigencia IS NULL))))
                         GROUP BY hrv.cdvinculo) v;

              END IF;

            ELSE

              SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                     nvl(SUM(v.vlintegral), 0) AS vlintegral,
                     CASE pintiporubrica
                       WHEN 'I' THEN
                        nvl(SUM(v.vlintegral), 0)
                       WHEN 'R' THEN
                        nvl(SUM(v.vlreal), 0)
                       ELSE
                        nvl(SUM(v.vlproporcional), 0)
                     END AS vlproporcional
               INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM (SELECT hrv.cdvinculo,
                             SUM(hrv.vlintegral) AS vlintegral,
                             SUM(hrv.vlproporcional) AS vlproporcional,
                             SUM(hrv.vlreal) AS vlreal
                        FROM epaghistoricorubricarelvinc hrv
                       INNER JOIN ECalFolhaPag fp
                          ON hrv.cdfolhapagamento = fp.cdfolhapagamento
                         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                       WHERE HRV.CdVinculo = pCdVinculo AND
                             FP.NuAnoReferencia = pNuAnoReferencia AND
                             FP.NuMesReferencia = pNuMesReferencia AND
                             FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                             FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl)  AND
                             FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
                             DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave AND
                             DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo AND
                             EXISTS
                       (SELECT 1
                                FROM epagbasecalcblocoexprrubagrup b
                              WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                    B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento AND
                                     b.cdrubricaagrupamento NOT IN
                                     (SELECT tr.cdrubricaagrupamento
                                        FROM etrbisencaorubrica tr
                                       INNER JOIN etrbhistisencaorubrica htr
                                           ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                       INNER JOIN etrbrubricaisentaformula tif
                                           ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                        WHERE TR.CdVinculo = pCdVinculo AND
                                              TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                              ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                              (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                              HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                              AND
                                              (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                              (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                              HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                             htr.numesfimvigencia IS NULL))))
                       GROUP BY hrv.cdvinculo) v;

            END IF;

          END IF;

        ELSIF pCdTipoHistorico = 2 OR
             -- Implantacao CIDASC
              (PKGPAG_VAR.vgFolha.FlOrgaoImplantado = 'N' and
              PKGPAG_VAR.vgfolha.CdAgrupamento = 4 AND
          vSgBaseCalculo = 'BFERM') THEN -- Vinculo
          --
          -- 8623/2016 - TRIBUTACAO PREVIDENCIARIA SOBRE CARGO COMISSIONADO E FUNCAO GRATIFICADA (IPREV)
          --
          IF  vSgBaseCalculo in ('OPC70','ESTSC')
             THEN
            --
            -- Valores da relacao de vinculo efetivo das rubricas que compoe a base
            --

              if vSgBaseCalculo = 'OPC70' and
                 PKGPAG_VAR.vgCco.Count > 0 and
                 PKGPAG_VAR.vgCco(1).CdOpcaoRemuneracao = 3 then
              --
              -- SIG-779 13185/2019 - Incluir a incidencia do IPREV no comissionado
              --
              SELECT nvl(SUM(HRV.VlReal), 0) as vlReal,
                     nvl(SUM(HRV.VlIntegral), 0) as vlIntegral,
                     nvl(SUM(CASE pInTipoRubrica
                               WHEN 'I' THEN
                                HRV.VlIntegral
                               WHEN 'R' THEN
                                HRV.VlReal
                               ELSE
                                HRV.VlProporcional
                         END),0) AS vlProporcional
                  INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM EPagHistoricoRubricaRelVinc HRV
               WHERE HRV.CdFolhaPagamento = pCdFolhaHistorico
                 AND HRV.CdVinculo = pCdVinculo
                 AND HRV.CdRelacaoVinculo = 1
                   and exists (SELECT 1
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
                                WHERE RUBM.CdRubricaAgrupamento = PKGPAG_VAR.vgCdRubBaseIPESC
                                  and rubex.cdrubricaagrupamento = hrv.cdrubricaagrupamento
                                  AND ((HB.NuAnoInicioVigencia < PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                                       (HB.NuAnoInicioVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                                        HB.NuMesInicioVigencia <= PKGPAG_VAR.vgFolha.NuMesReferencia))
                                  AND (HB.NuAnoFimVigencia > PKGPAG_VAR.vgFolha.NuAnoReferencia OR
                                      (HB.NuAnoFimVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia AND
                                       HB.NuMesFimVigencia >= PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                             HB.NuAnoFimVigencia IS NULL)));

            else

              SELECT nvl(SUM(HRV.VlReal), 0) as vlReal,
                     nvl(SUM(HRV.VlIntegral), 0) as vlIntegral,
                     nvl(SUM(CASE pInTipoRubrica
                               WHEN 'I' THEN
                                HRV.VlIntegral
                               WHEN 'R' THEN
                                HRV.VlReal
                               ELSE
                                HRV.VlProporcional
                           END),0) AS vlProporcional
                  INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM EPagHistoricoRubricaRelVinc   HRV,
                     EPagBaseCalcBlocoExprRubAgrup B
               WHERE HRV.CdFolhaPagamento = pCdFolhaHistorico
                 AND HRV.CdVinculo = pCdVinculo
                 AND B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao
                 AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento
                 AND HRV.CdRelacaoVinculo = 1;

            end if;

            vVlRubricaIprevCco.vlReal         := 0;
            vVlRubricaIprevCco.vlIntegral     := 0;
            vVlRubricaIprevCco.vlProporcional := 0;
            --
            -- Valores pagos no total das rubricas que compoe a base
            --
            SELECT nvl(SUM(HRV.VlPagamento), 0) as vlReal,
                   nvl(SUM(HRV.VlPagamento), 0) as vlIntegral,
                   nvl(SUM(CASE pInTipoRubrica
                             WHEN 'I' THEN
                              HRV.VlPagamento
                             WHEN 'R' THEN
                              HRV.VlPagamento
                             ELSE
                              HRV.VlPagamento
                         END),0) AS vlProporcional
                INTO vVlRubricaIprevCco.vlReal, vVlRubricaIprevCco.vlIntegral, vVlRubricaIprevCco.vlProporcional
              FROM EPagHistoricoRubricaVinculo   HRV,
                   EPagBaseCalcBlocoExprRubAgrup B
             WHERE HRV.CdFolhaPagamento = pCdFolhaHistorico
               AND HRV.CdVinculo = pCdVinculo
               AND B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao
               AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento;

              IF NVL(vVlRubricaIprevCco.VlReal,0) > NVL(vVlRubrica.vlReal,0) OR
                 NVL(vVlRubricaIprevCco.vlProporcional,0) > NVL(vVlRubrica.vlProporcional,0)
                THEN

                  vVlRubrica.vlReal := vVlRubricaIprevCco.vlReal - vVlRubrica.vlReal;
                  vVlRubrica.vlIntegral := vVlRubricaIprevCco.vlIntegral - vVlRubrica.vlIntegral ;
                  vVlRubrica.vlProporcional := vVlRubricaIprevCco.vlProporcional - vVlRubrica.vlProporcional;

            END IF;

          ELSIF vSgBaseCalculo in ('B0920')
            AND pinmes = 'AN'
            AND PKGPAG_VAR.vgVinculo.dtdesligamento IS NOT NULL
            AND ((PKGPAG_VAR.vgVinculo.dtdesligamento
                  BETWEEN PKGPAG_VAR.vgFolha.dtcalculoant AND PKGPAG_VAR.vgFolha.dtcalculo)
                 OR (PKGPAG_VAR.vgVinculo.dtdesligamento < PKGPAG_VAR.vgFolha.dtiniciomes
                  AND PKGPAG_VAR.bPossuiObito))
            THEN
            -- Este IF - ELSE é necessário porque esta base quando a folha não é de 13o. salário, precisa buscar as rubricas
            -- na folha anterior do mesmo tipo.  Já quando é 13o. salário, precisa buscar na folha anterior de tipo diferente de 13o. salário
              IF PKGPAG_VAR.vgFolha.CdTipoFolha NOT IN (3, 5, 8, 9, 14, 18, 20, 21) THEN -- Não é folha de 13o. Salário
              SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                     nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                     nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM epaghistoricorubricavinculo hv
               INNER JOIN ECalFolhaPag fp
                  ON hv.cdfolhapagamento = fp.cdfolhapagamento
                 AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
               WHERE HV.CdVinculo = pCdVinculo
                  AND FP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia
                  AND FP.NuMesReferencia = PKGPAG_VAR.vgFolha.NuMesReferencia
                 AND fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoNormal
                  AND fp.cdtipofolhapagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento
                  AND (hv.cdrubricaagrupamento <> 10672 AND PKGPAG_VAR.vgFolha.cdagrupamento = 1)
                  AND EXISTS (SELECT 1
                        FROM epagbasecalcblocoexprrubagrup b
                              WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                    B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                                 b.cdrubricaagrupamento NOT IN
                             (SELECT tr.cdrubricaagrupamento
                                FROM etrbisencaorubrica tr
                               INNER JOIN etrbhistisencaorubrica htr
                                            ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                               INNER JOIN etrbrubricaisentaformula tif
                                            ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                         WHERE TR.CdVinculo = pCdVinculo AND
                                               TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                               ((HTR.NuAnoInicioVigencia < PKGPAG_VAR.vgFolha.NuAnoReferencia  OR
                                               (HTR.NuAnoInicioVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia  AND
                                               HTR.NuMesInicioVigencia <=  PKGPAG_VAR.vgFolha.NuMesReferencia))
                                               AND
                                               (HTR.NuAnoFimVigencia > PKGPAG_VAR.vgFolha.NuAnoReferencia  OR
                                               (HTR.NuAnoFimVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia  AND
                                               HTR.NuMesFimVigencia >=  PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                                     htr.numesfimvigencia IS NULL))));

              ELSE -- Folhas de décimo terceiro salário
              SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                     nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                     nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM epaghistoricorubricavinculo hv
               INNER JOIN ECalFolhaPag fp
                  ON hv.cdfolhapagamento = fp.cdfolhapagamento
                 AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
               WHERE HV.CdVinculo = pCdVinculo
                  AND FP.NuAnoReferencia = PKGPAG_VAR.vgFolha.NuAnoReferencia
                  AND FP.NuMesReferencia = PKGPAG_VAR.vgFolha.NuMesReferencia
                 AND fp.cdtipocalculo = pkgpag_tipo.cnTpCalculoNormal
                  AND fp.cdtipofolhapagamento <> PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento
                  AND EXISTS (SELECT 1
                        FROM epagbasecalcblocoexprrubagrup b
                              WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                    B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                                 b.cdrubricaagrupamento NOT IN
                             (SELECT tr.cdrubricaagrupamento
                                FROM etrbisencaorubrica tr
                               INNER JOIN etrbhistisencaorubrica htr
                                            ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                               INNER JOIN etrbrubricaisentaformula tif
                                            ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                         WHERE TR.CdVinculo = pCdVinculo AND
                                               TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                               ((HTR.NuAnoInicioVigencia < PKGPAG_VAR.vgFolha.NuAnoReferencia  OR
                                               (HTR.NuAnoInicioVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia  AND
                                               HTR.NuMesInicioVigencia <=  PKGPAG_VAR.vgFolha.NuMesReferencia))
                                               AND
                                               (HTR.NuAnoFimVigencia > PKGPAG_VAR.vgFolha.NuAnoReferencia  OR
                                               (HTR.NuAnoFimVigencia = PKGPAG_VAR.vgFolha.NuAnoReferencia  AND
                                               HTR.NuMesFimVigencia >=  PKGPAG_VAR.vgFolha.NuMesReferencia) OR
                                     htr.numesfimvigencia IS NULL))));
            END IF;

         ELSIF vSgBaseCalculo = 'BFER' AND pInRelacaoRubrica = 'I' 
               and (PKGPAG_VAR.vgNuDiasAfastSemRemun > 0 OR PKGPAG_VAR.vgNuDiasAfastDefinitivo > 0) then

            -- Tipo I para valor integral e P para valor pago
            -- Integralizar valor da base de cálculo se foi proporcionalizado


            IF PKGPAG_VAR.vgNuDiasAfastSemRemun > 0 THEN
              
               vNuDiasAfast := PKGPAG_VAR.vgNuDiasAfastSemRemun;
                             
            ELSE  
                            
               vNuDiasAfast := PKGPAG_VAR.vgNuDiasAfastDefinitivo;
            
            END IF;


            SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                    trunc(nvl(SUM(v.vlintegral / (30 - vNuDiasAfast) * 30), 0),2) AS vlintegral,
                    trunc(nvl(SUM(v.vlproporcional / (30 - vNuDiasAfast) * 30),0),2) AS vlproporcional
               INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
              FROM (SELECT hrv.cdvinculo,
                           SUM(hrv.vlintegral) AS vlintegral,
                           SUM(hrv.vlproporcional) AS vlproporcional,
                           SUM(hrv.vlreal) AS vlreal
                      FROM epaghistoricorubricarelvinc hrv
                     WHERE HRV.CdVinculo = pCdVinculo
                        and hrv.cdfolhapagamento = PKGPAG_VAR.vgFolha.CdFolhaPagamento
                        and DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave
                        and DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo
                       and EXISTS
                     (SELECT 1
                              FROM epagbasecalcblocoexprrubagrup b
                             WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao
                               AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento)
                     GROUP BY hrv.cdvinculo) v;

          ELSIF NOT pdescrubisentaformula THEN

            IF NOT pflvalorzero THEN

              IF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                 ptptributacao = 1 THEN

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                 INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                      HV.CdVinculo = pCdVinculo AND
                      EXISTS
                 (SELECT b.cdrubricaagrupamento
                          FROM epagbasecalcblocoexprrubagrup b
                         INNER JOIN epagrubricaagrupamento ra
                           ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
                         INNER JOIN epagrubrica r
                            ON r.cdrubrica = ra.cdrubrica
                        WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                              B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                               (r.cdtiporubrica NOT IN (10, 12) AND
                              NOT (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95) AND
                              NOT (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915,926)) AND
                              NOT (R.CdTipoRubrica = 5 AND R.NuRubrica = 976) AND
                               b.cdrubricaagrupamento NOT IN
                               (nvl(PKGPAG_VAR.vgparampagamento.cdrubagrupbloqretexercfind,0),
                                nvl(PKGPAG_VAR.vgparampagamento.cdrubagrupbloqexercfind13sal,0))));

              ELSIF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                    ptptributacao = 4 AND
                    vSgBaseCalculo <> 'BFER' THEN
                BEGIN 
                  vVlPgtoBlocoRRA := FObterValorBlocoRRA(pCdVinculo                    => pCdVinculo,
                                                         pCdFolhaHistorico             => pCdFolhaHistorico,
                                                         pCdProcessoPagRetroativo      => PKGPAG_RT.vgProcessoRetroativo(vgIndProcRetro).CdProcessoPagRetroativo,
                                                         pCdBlocoExpressao             => pCdBlocoExpressao,
                                                         pCdRubAgrupBloqRetExercFind   => PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,
                                                         pCdRubAgrupBloqExercFind13Sal => PKGPAG_VAR.vgparampagamento.cdrubagrupbloqexercfind13sal); 
                                                         
                  vVlRubrica.vlReal         := vVlPgtoBlocoRRA.vlReal;
                  vVlRubrica.vlIntegral     := vVlPgtoBlocoRRA.vlIntegral;
                  vVlRubrica.vlProporcional := vVlPgtoBlocoRRA.vlProporcional;
                END;                                      

              ELSIF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                    ptptributacao = 4 AND
                    vSgBaseCalculo = 'BFER' THEN

                WITH rub1 as
                 (select r.nurubrica
                    from epagbasecalcblocoexprrubagrup b
                   inner join vpagrubricaagrupamento r
                      on r.cdrubricaagrupamento = b.cdrubricaagrupamento
                     and r.cdagrupamento = PKGPAG_VAR.vgFolha.cdagrupamento
                   where b.cdbasecalculoblocoexpressao = pCdBlocoExpressao),

                rub2 as
                 (select r.cdrubricaagrupamento
                    from vpagrubricaagrupamento r
                   inner join rub1 n
                      on n.nurubrica = r.nurubrica
                     and r.cdtiporubrica in (10, 12)
                     and r.cdagrupamento = PKGPAG_VAR.vgFolha.cdagrupamento)

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                       INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                 INNER JOIN RUB2 r
                    on r.cdrubricaagrupamento = hv.cdrubricaagrupamento
                 WHERE HV.CdFolhaPagamento = pCdFolhaHistorico
                   AND HV.CdVinculo = pCdVinculo
                   AND HV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(vgIndProcRetro).CdProcessoPagRetroativo;

              ELSE

                ----------------------------------------------------------------------
                -- Se a f?rmula ? de pensao aliment?cia e o ?rg?o
                -- n?o gera a pens?o na folha de f?rias, o RUB ir? somar tamb?m
                -- os valores presentes na folha de f?rias
                ----------------------------------------------------------------------

              IF PKGPAG_VAR.vgFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast) AND
                 PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).FlPensaoAlimenticia = 'S' AND
                   PKGPAG_VAR.vgparampagamento.flgerapensaofolhaferias = 'N' AND
                   PKGPAG_VAR.vgcdfolhaferias > 0 THEN

                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                    INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                   WHERE HV.CdFolhaPagamento IN (pCdFolhaHistorico, PKGPAG_VAR.vgCdFolhaFerias) AND
                         HV.CdVinculo = pCdVinculo AND
                         EXISTS
                   (SELECT cdrubricaagrupamento
                            FROM epagbasecalcblocoexprrubagrup b
                           WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                 B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento);

                ELSIF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                      PKGPAG_VAR.vgfolha.cdagrupamento = 176 AND
                      NVL(PKGPAG_VAR.vgNuDiasSubst, 0) > 0 AND
                      vSgBaseCalculo = 'BFER' THEN

                  vcdblocoexpressao := pCdBlocoExpressao;

                  WITH RUBEXP AS
                   (SELECT cdrubricaagrupamento
                      FROM epagbasecalcblocoexprrubagrup b
                     WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao)

                  SELECT nvl(SUM(hv.vlreal), 0),
                         nvl(SUM(hv.vlintegral), 0),
                         nvl(SUM(hv.vlproporcional), 0)
                    INTO vVlRubrica.vlReal,
                         vVlRubrica.vlIntegral,
                         vVlRubrica.vlProporcional
                    FROM epaghistoricorubricarelvinc hv
                   INNER JOIN RUBEXP R
                      on R.CdRubricaAgrupamento = hv.Cdrubricaagrupamento
                   WHERE HV.CdFolhaPagamento IN (pCdFolhaHistorico)
                     AND HV.CdVinculo = pCdVinculo;
               ---     AND NVL(hv.Cdhistcargocom, 0) <> PKGPAG_var.vgCCOSubst(1).cdhistcargocom;


                ELSIF PKGPAG_VAR.bPossuiDuploVinculoAno = TRUE
                  AND vSgBaseCalculo = 'BIN13' --13 salário
                --cascula base 09-1005 para vpessoas  q tiveram mais de um vinculo no ano
                 THEN

                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                             INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                   INNER JOIN ecadvinculo v
                      ON v.cdvinculo = hv.cdvinculo
                     AND v.cdpessoa = PKGPAG_VAR.vgVinculo.cdpessoa
                   INNER JOIN epagbasecalcblocoexprrubagrup b
                      ON b.cdrubricaagrupamento = hv.cdrubricaagrupamento
                   INNER JOIN ECalFolhaPag fp
                      ON fp.cdfolhapagamento = hv.cdfolhapagamento
                     AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                     AND fp.nuanoreferencia = PKGPAG_VAR.vgFolha.nuanoreferencia
                     AND fp.cdtipocalculo = 1
                     AND fp.flcalculodefinitivo = 'S'
                   WHERE b.cdbasecalculoblocoexpressao = pCdBlocoExpressao;

                ELSIF vSgBaseCalculo IN ('BFERM', 'BFER') and PKGPAG_VAR.vgfolha.cdagrupamento = 4
                  THEN

                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                        INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                       WHERE HV.CdFolhaPagamento IN (
                          SELECT cdfolhapagamento
                            FROM ECalFolhaPag
                           WHERE flcalculodefinitivo = 'S'
                             AND cdorgao = PKGPAG_VAR.vgFolha.cdorgao
                             AND CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                             AND nuanomesreferencia =
                                 (SELECT nuanomesreferencia
                                    FROM ECalFolhaPag
                                   WHERE cdfolhapagamento = pCdFolhaHistorico
                                     AND CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                                  ) ) AND
                        --= pCdFolhaHistorico AND
                             HV.CdVinculo = pCdVinculo AND
                             EXISTS
                   (SELECT cdrubricaagrupamento
                            FROM epagbasecalcblocoexprrubagrup b
                               WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                     B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento);
                ELSE

                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                        INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                       WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                             HV.CdVinculo = pCdVinculo AND
                             EXISTS
                   (SELECT cdrubricaagrupamento
                            FROM epagbasecalcblocoexprrubagrup b
                               WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                     B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento);

                  --END IF;

                END IF;

              END IF;

            ELSE

              SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                     nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                     nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
             INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM epaghistoricorubricavinculo hv
               INNER JOIN ECalFolhaPag fp
                  ON hv.cdfolhapagamento = fp.cdfolhapagamento
                 AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
             WHERE HV.CdVinculo = pCdVinculo AND
                   FP.NuAnoReferencia = pNuAnoReferencia AND
                   FP.NuMesReferencia = pNuMesReferencia AND
                   FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                   FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl) AND
                   FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
                    EXISTS
               (SELECT cdrubricaagrupamento
                        FROM epagbasecalcblocoexprrubagrup b
                     WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                           B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento);

            END IF;

          ELSE

            IF NOT pflvalorzero THEN

              IF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                 ptptributacao = 1 THEN

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
               WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                     HV.CdVinculo = pCdVinculo AND
                      EXISTS (SELECT B.CdRubricaAgrupamento
                          FROM epagbasecalcblocoexprrubagrup b
                         INNER JOIN epagrubricaagrupamento ra
                                  ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
                         INNER JOIN epagrubrica r
                            ON r.cdrubrica = ra.cdrubrica
                               WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                     B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                               (r.cdtiporubrica NOT IN (10, 12) AND
                                     NOT (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95) AND
                                     NOT (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915, 926)) AND
                                     NOT (R.CdTipoRubrica = 5 AND R.NuRubrica = 976) AND
                                     B.CdRubricaAgrupamento NOT IN (nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,0),
                                                                    nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqExercFind13Sal,0))) AND
                                     B.CdRubricaAgrupamento NOT IN (SELECT TR.CdRubricaAgrupamento
                                  FROM etrbisencaorubrica tr
                                 INNER JOIN etrbhistisencaorubrica htr
                                                                        ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                 INNER JOIN etrbrubricaisentaformula tif
                                                                        ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                                                     WHERE TR.CdVinculo = pCdVinculo AND
                                                                           TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                                                           ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                                                           (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                                                           HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                                                           AND
                                                                           (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                                                           (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                                                           HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                       htr.numesfimvigencia IS NULL))));

              ELSIF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                    ptptributacao = 4 AND
                    vSgBaseCalculo <> 'BFER' THEN

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
               INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
              WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                    HV.CdVinculo = pCdVinculo AND
                    HV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(vgIndProcRetro).CdProcessoPagRetroativo AND
                     EXISTS (SELECT B.CdRubricaAgrupamento
                          FROM epagbasecalcblocoexprrubagrup b
                         INNER JOIN epagrubricaagrupamento ra
                                 ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
                         INNER JOIN epagrubrica r
                            ON r.cdrubrica = ra.cdrubrica
                              WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                    B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                                    (R.CdTipoRubrica IN (10,12) OR (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915, 926)) OR
                                    (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95) OR
                               (ra.flpensaoalimenticia = 'S') OR
                                     B.CdRubricaAgrupamento  IN (nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,0),
                                                                 nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqExercFind13Sal,0))) AND
                               b.cdrubricaagrupamento NOT IN
                               (SELECT tr.cdrubricaagrupamento
                                  FROM etrbisencaorubrica tr
                                 INNER JOIN etrbhistisencaorubrica htr
                                            ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                 INNER JOIN etrbrubricaisentaformula tif
                                            ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                         WHERE TR.CdVinculo = pCdVinculo AND
                                               TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                               ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                               (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                               HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                               AND
                                               (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                               (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                               HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                       htr.numesfimvigencia IS NULL))));

              ELSIF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                    ptptributacao = 4 AND
                    vSgBaseCalculo = 'BFER' THEN

                WITH rub1 as
                 (select r.nurubrica
                    from epagbasecalcblocoexprrubagrup b
                   inner join vpagrubricaagrupamento r
                      on r.cdrubricaagrupamento = b.cdrubricaagrupamento
                     and r.cdagrupamento = PKGPAG_VAR.vgFolha.cdagrupamento
                   where b.cdbasecalculoblocoexpressao = pCdBlocoExpressao),

                rub2 as
                 (select r.cdrubricaagrupamento
                    from vpagrubricaagrupamento r
                   inner join rub1 n
                      on n.nurubrica = r.nurubrica
                     and r.cdtiporubrica in (10, 12)
                     and r.cdagrupamento = PKGPAG_VAR.vgFolha.cdagrupamento)

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                       INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                 INNER JOIN RUB2 r
                    on r.cdrubricaagrupamento = hv.cdrubricaagrupamento
                 WHERE HV.CdFolhaPagamento = pCdFolhaHistorico
                   AND HV.CdVinculo = pCdVinculo
                   AND HV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(vgIndProcRetro).CdProcessoPagRetroativo;

              ELSE

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
             INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
            WHERE  HV.CdFolhaPagamento = pCdFolhaHistorico AND
                   HV.CdVinculo = pCdVinculo AND
                   EXISTS (SELECT 1
                          FROM epagbasecalcblocoexprrubagrup b
                            WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                  B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                               b.cdrubricaagrupamento NOT IN
                               (SELECT tr.cdrubricaagrupamento
                                  FROM etrbisencaorubrica tr
                                 INNER JOIN etrbhistisencaorubrica htr
                                          ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                 INNER JOIN etrbrubricaisentaformula tif
                                          ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                       WHERE TR.CdVinculo = pCdVinculo AND
                                             TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                             ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                             (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                             HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                             AND
                                             (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                             (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                             HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                       htr.numesfimvigencia IS NULL))));

              END IF;

            ELSE

              SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                     nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                     nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
            INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM epaghistoricorubricavinculo hv
               INNER JOIN ECalFolhaPag fp
                  ON hv.cdfolhapagamento = fp.cdfolhapagamento
                 AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
           WHERE HV.CdVinculo = pCdVinculo AND
                 FP.NuAnoReferencia = pNuAnoReferencia AND
                 FP.NuMesReferencia = pNuMesReferencia AND
                 FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                 FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl) AND
                 FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
                 EXISTS (SELECT 1
                        FROM epagbasecalcblocoexprrubagrup b
                          WHERE B.CdBaseCalculoBlocoExpressao = pCdBlocoExpressao AND
                                B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                             b.cdrubricaagrupamento NOT IN
                             (SELECT tr.cdrubricaagrupamento
                                FROM etrbisencaorubrica tr
                               INNER JOIN etrbhistisencaorubrica htr
                                        ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                               INNER JOIN etrbrubricaisentaformula tif
                                        ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                     WHERE TR.CdVinculo = pCdVinculo AND
                                           TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                           ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                           (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                           HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                           AND
                                           (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                           (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                           HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                     htr.numesfimvigencia IS NULL))));

            END IF;

          END IF;

        else
          null;
        END IF;

    ELSE -- F?rmulas de c?lculo

      IF pCdTipoHistorico = 1 and pCdMnemonico IS NULL THEN -- Na rela??o de v?nculo

          IF NOT pdescrubisentaformula THEN

            IF NOT pflvalorzero THEN
              vVlRubrica := FObterValorBloco(pInMes              => pInMes,
                                             pNuAnoRub           => pNuAnoRub,
                                             pNuMesRub           => pNuMesRub,
                                             pNuAnoReferencia    => pNuAnoReferencia,
                                             pNuMesReferencia    => pNuMesReferencia,
                                             pCdVinculo          => pCdVinculo,
                                             pCdFolhaHistorico   => pCdFolhaHistorico,
                                             pCdFormCalcBlocoExp => pCdBlocoExpressao,
                                             pCdChave            => pCdChave,
                                             pCdRelacaoVinculo   => pCdRelacaoVinculo,
                                             pCdTipoFolha        => PKGPAG_VAR.vgFolha.CdTipoFolha);
              --
              -- Solicitacao de Sustentacao #70512
              -- CIDASC - Considerar rubrica da folha de ferias na folha normal
              --
               IF PKGPAG_VAR.vgFolha.CdAgrupamento in (3, 4)
                 AND  PKGPAG_VAR.vgFolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal
                 THEN

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                             INTO vVlRubricaFerias.vlReal, vVlRubricaFerias.vlIntegral, vVlRubricaFerias.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                 INNER JOIN ECalFolhaPag fp
                    ON hv.cdfolhapagamento = fp.cdfolhapagamento
                   AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                 INNER JOIN epagtipofolhapagamento etp on fp.cdtipofolhapagamento = etp.cdtipofolhapagamento
                 WHERE hv.cdvinculo = pcdvinculo
                   AND fp.nuanoreferencia = pnuanoreferencia
                   AND fp.numesreferencia = pnumesreferencia
                   AND FP.CdTipoCalculo = PKGPAG_TIPO.cnTpCalculoNormal
                   AND ETP.CDTIPOFOLHA = PKGPAG_TIPO.cnTpFolhaFerias
                   AND fp.flcalculodefinitivo = pkgpag_tipo.cns
                           AND EXISTS
                     (SELECT cdrubricaagrupamento
                          FROM epagformcalcblocoexprubagrup b
                               WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                     B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento);

                    vVlRubrica.vlReal := vVlRubrica.vlReal + NVL(vVlRubricaFerias.vlReal,0);
                    vVlRubrica.vlIntegral := vVlRubrica.vlIntegral + NVL(vVlRubricaFerias.vlIntegral,0);
                    vVlRubrica.vlProporcional := vVlRubrica.vlProporcional + NVL(vVlRubricaFerias.vlProporcional,0);

              END IF;

            ELSE

              SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                     nvl(SUM(v.vlintegral), 0) AS vlintegral,
                     CASE pintiporubrica
                       WHEN 'I' THEN
                        nvl(SUM(v.vlintegral), 0)
                       WHEN 'R' THEN
                        nvl(SUM(v.vlreal), 0)
                       ELSE
                        nvl(SUM(v.vlproporcional), 0)
                     END AS vlproporcional
               INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM (SELECT hrv.cdvinculo,
                             SUM(hrv.vlintegral) AS vlintegral,
                             SUM(hrv.vlproporcional) AS vlproporcional,
                             SUM(hrv.vlreal) AS vlreal
                        FROM epaghistoricorubricarelvinc hrv
                       INNER JOIN ECalFolhaPag fp
                          ON hrv.cdfolhapagamento = fp.cdfolhapagamento
                         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                      WHERE HRV.CdVinculo = pCdVinculo AND
                            FP.NuAnoReferencia = pNuAnoReferencia AND
                            FP.NuMesReferencia = pNuMesReferencia AND
                            FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                            FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl) AND
                            FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
                            DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave AND
                            DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo AND
                            EXISTS
                       (SELECT 1
                                FROM epagformcalcblocoexprubagrup b
                             WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                   B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento)
                       GROUP BY hrv.cdvinculo) v;

              --
              -- Exce??o para a rubrica 05-1983 que na formula busca a rubrica 05-0983 do mes
              -- anterior que n?o tem valores na tabela historicorubricarelvinc
              --
              -- 42932 - EPAGRI 01-0002, deixar enquanto n?o for folha definitiva
              --
              IF vVlRubrica.vlReal = 0 and (
                 pCdRubricaAgrupamento in (37156, 42932) or
                 -- Implantacao CIDASC
                 (PKGPAG_VAR.vgFolha.FlOrgaoImplantado = 'N' and PKGPAG_VAR.vgfolha.CdAgrupamento = 4))
                THEN

                if  PKGPAG_VAR.vgfolha.cdtipofolha = 4 and PKGPAG_VAR.vgfolha.CdAgrupamento = 4
                then

                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                             INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                   INNER JOIN ECalFolhaPag fp
                      ON hv.cdfolhapagamento = fp.cdfolhapagamento
                     AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                   WHERE hv.cdvinculo = pcdvinculo
                     AND fp.nuanoreferencia = pnuanoreferencia
                     AND fp.numesreferencia = pnumesreferencia
                             AND FP.CdTipoFolhaPagamento <> PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento
                             AND FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl)
                     AND fp.flcalculodefinitivo = pkgpag_tipo.cns
                     AND EXISTS
                   (SELECT cdrubricaagrupamento
                            FROM epagformcalcblocoexprubagrup b
                               WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                     B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento);
                else

                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                               INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                   INNER JOIN ECalFolhaPag fp
                      ON hv.cdfolhapagamento = fp.cdfolhapagamento
                     AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                   WHERE hv.cdvinculo = pcdvinculo
                     AND fp.nuanoreferencia = pnuanoreferencia
                     AND fp.numesreferencia = pnumesreferencia
                               AND FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento
                               AND FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl)
                     AND fp.flcalculodefinitivo = pkgpag_tipo.cns
                     AND EXISTS
                   (SELECT cdrubricaagrupamento
                            FROM epagformcalcblocoexprubagrup b
                                 WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                       B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento);
                end if;

              else
                null;
              END IF;

            END IF;

          ELSE

            IF NOT pflvalorzero THEN

              vInfoRelVinc := FObterInfoRelVinc(pCdFolhaHistorico => pCdFolhaHistorico,
                                                pCdVinculo        => pCdVinculo, 
                                                pCdChave          => pCdChave,
                                                pCdRelacaoVinculo => pCdRelacaoVinculo);
      
              SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                     nvl(SUM(v.vlintegral), 0) AS vlintegral,
                     CASE pintiporubrica
                       WHEN 'I' THEN
                        nvl(SUM(v.vlintegral), 0)
                       WHEN 'R' THEN
                        nvl(SUM(v.vlreal), 0)
                       ELSE
                        nvl(SUM(v.vlproporcional), 0)
                     END AS vlproporcional
             INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM (SELECT hrv.cdvinculo,
                             SUM(hrv.vlintegral) AS vlintegral,
                             SUM(hrv.vlproporcional) AS vlproporcional,
                             SUM(hrv.vlreal) AS vlreal
                        FROM epaghistoricorubricarelvinc hrv
                    WHERE HRV.CdFolhaPagamento = pCdFolhaHistorico AND
                          HRV.CdVinculo = pCdVinculo AND
                          DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, vInfoRelVinc.cdChave) = vInfoRelVinc.cdChave AND
                          DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, vInfoRelVinc.cdRelacaoVinculo) = vInfoRelVinc.cdRelacaoVinculo AND
                          EXISTS (SELECT 1
                                FROM epagformcalcblocoexprubagrup b
                                   WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                         B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento AND
                                     b.cdrubricaagrupamento NOT IN
                                     (SELECT tr.cdrubricaagrupamento
                                        FROM etrbisencaorubrica tr
                                       INNER JOIN etrbhistisencaorubrica htr
                                             ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                       INNER JOIN etrbrubricaisentaformula tif
                                             ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                          WHERE TR.CdVinculo = pCdVinculo AND
                                                TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                                ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                                (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                                HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                                AND
                                                (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                                (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                                HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                             htr.numesfimvigencia IS NULL))))
                       GROUP BY hrv.cdvinculo) v;

            ELSE

              SELECT nvl(SUM(v.vlreal), 0) AS vlreal,
                     nvl(SUM(v.vlintegral), 0) AS vlintegral,
                     CASE pintiporubrica
                       WHEN 'I' THEN
                        nvl(SUM(v.vlintegral), 0)
                       WHEN 'R' THEN
                        nvl(SUM(v.vlreal), 0)
                       ELSE
                        nvl(SUM(v.vlproporcional), 0)
                     END AS vlproporcional
             INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM (SELECT hrv.cdvinculo,
                             SUM(hrv.vlintegral) AS vlintegral,
                             SUM(hrv.vlproporcional) AS vlproporcional,
                             SUM(hrv.vlreal) AS vlreal
                        FROM epaghistoricorubricarelvinc hrv
                       INNER JOIN ECalFolhaPag fp
                          ON hrv.cdfolhapagamento = fp.cdfolhapagamento
                         AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                    WHERE HRV.CdVinculo = pCdVinculo AND
                          FP.NuAnoReferencia = pNuAnoReferencia AND
                          FP.NuMesReferencia = pNuMesReferencia AND
                          FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                          FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl) AND
                          FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
                          DECODE(pInRelacaoRubrica, 'R', HRV.CdChave, pCdChave) = pCdChave AND
                          DECODE(pInRelacaoRubrica, 'R', HRV.CdRelacaoVinculo, pCdRelacaoVinculo) = pCdRelacaoVinculo AND
                          EXISTS (SELECT 1
                                FROM epagformcalcblocoexprubagrup b
                                   WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                         B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento AND
                                     b.cdrubricaagrupamento NOT IN
                                     (SELECT tr.cdrubricaagrupamento
                                        FROM etrbisencaorubrica tr
                                       INNER JOIN etrbhistisencaorubrica htr
                                             ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                       INNER JOIN etrbrubricaisentaformula tif
                                             ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                          WHERE TR.CdVinculo = pCdVinculo AND
                                                TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                                ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                                (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                                HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                                AND
                                                (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                                (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                                HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                             htr.numesfimvigencia IS NULL))))
                       GROUP BY hrv.cdvinculo) v;

            END IF;

          END IF;

      ELSIF pCdTipoHistorico = 2 or pCdMnemonico IS NOT NULL  THEN -- V?nculo

          IF NOT pdescrubisentaformula THEN

            IF NOT pflvalorzero THEN

              IF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                 ptptributacao = 1 THEN

                WITH RUBEXP AS (SELECT b.cdrubricaagrupamento
                    FROM epagformcalcblocoexprubagrup b
                   INNER JOIN epagrubricaagrupamento ra
                      ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
                   INNER JOIN epagrubrica r
                      ON r.cdrubrica = ra.cdrubrica
                   WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao
                                    AND (r.cdtiporubrica NOT IN (10, 12)
                                    AND NOT (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95)
                                    AND NOT (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915,926))
                                    AND NOT (R.CdTipoRubrica = 5 AND R.NuRubrica = 976)
                                    AND NOT (R.CdTipoRubrica = 5 AND R.NuRubrica = 946)
                                    AND (B.CdRubricaAgrupamento <> nvl(PKGPAG_VAR.vgParamPagamento.CDRUBAGRUPBLOQEXERCFIND13SAL,0))
                                    AND (B.CdRubricaAgrupamento <> nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,0))))
                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                  INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                 INNER JOIN RUBEXP R1 on R1.CdRubricaAgrupamento = hv.cdrubricaagrupamento
                 WHERE HV.CdFolhaPagamento = pCdFolhaHistorico
                   AND HV.CdVinculo = pCdVinculo;

              ELSIF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                    ptptributacao = 4 THEN

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                  INTO vVlRubrica.vlReal,
                       vVlRubrica.vlIntegral,
                       vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                 INNER JOIN epagrubricaagrupamento ragr
                    ON hv.cdrubricaagrupamento = ragr.cdrubricaagrupamento
                 INNER JOIN epagrubrica rub ON rub.cdrubrica = ragr.cdrubrica  
                 WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                       HV.CdVinculo = pCdVinculo AND
                       RAGR.cdagrupamento = PKGPAG_VAR.vgfolha.cdagrupamento AND
                       HV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(vgIndProcRetro).CdProcessoPagRetroativo AND
                       EXISTS
                 (SELECT b.cdrubricaagrupamento
                          FROM epagformcalcblocoexprubagrup b
                         INNER JOIN epagrubricaagrupamento ra
                            ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
                         INNER JOIN epagrubrica r
                            ON r.cdrubrica = ra.cdrubrica
                         WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                               B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                               (R.CdTipoRubrica IN (10,12) OR (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915, 926)) OR
                               (R.CdTipoRubrica = 5 AND R.NuRubrica = 946) OR
                               (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95) OR
                               (R.CdTipoRubrica = 5 AND R.NuRubrica = 516) OR
                               (ra.flpensaoalimenticia = 'S') OR
                (B.CdRubricaAgrupamento = nvl(PKGPAG_VAR.vgParamPagamento.CDRUBAGRUPBLOQEXERCFIND13SAL,0)) OR
                               (B.CdRubricaAgrupamento = nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,0))));

              ELSE

                ----------------------------------------------------------------------
                -- Se a f?rmula ? de pensao aliment?cia e o ?rg?o
                -- n?o gera a pens?o na folha de f?rias, o RUB ir? somar tamb?m
                -- os valores presentes na folha de f?rias
                -- Regra aplic?vel apenas ? folha NORMAL
                ----------------------------------------------------------------------

                IF PKGPAG_VAR.vgFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast) AND
                   PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).FlPensaoAlimenticia = 'S' AND
                   PKGPAG_VAR.vgparampagamento.flgerapensaofolhaferias = 'N' AND
                   PKGPAG_VAR.vgcdfolhaferias > 0 THEN

                  WITH RUBEXP AS (SELECT cdrubricaagrupamento
                      FROM epagformcalcblocoexprubagrup b
                     WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao)
                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                      INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                    INNER JOIN RUBEXP R on R.CdRubricaAgrupamento = hv.Cdrubricaagrupamento
                     WHERE HV.CdFolhaPagamento IN (pCdFolhaHistorico, PKGPAG_VAR.vgCdFolhaFerias) AND
                           HV.CdVinculo = pCdVinculo;

                  --
                  -- Solicitacao de Sustentacao #75950
                  -- CIDASC - problema pensao sob ferias
                  -- #79093: Problema semelhante na SCPAR, calculo da pensao soma valor da folha do mes anterior (cdorgao: 383)
                ELSIF PKGPAG_VAR.vgparampagamento.flgerapensaofolhaferias = 'S'
                  AND PKGPAG_VAR.vgFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaFerias
                  AND PKGPAG_VAR.vgRubrica(pCdRubricaAgrupamento).FlPensaoAlimenticia = 'S'
                  AND PKGPAG_VAR.vgFolha.CdOrgao in (25,37,383)
                  THEN

                    WITH RUBEXP AS (SELECT cdrubricaagrupamento
                      FROM epagformcalcblocoexprubagrup b
                     WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao)
                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                      INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                    INNER JOIN RUBEXP R on R.CdRubricaAgrupamento = hv.Cdrubricaagrupamento
                     WHERE HV.CdFolhaPagamento = PKGPAG_VAR.vgfolha.cdfolhapagamento AND
                           HV.CdVinculo = pCdVinculo;

                ELSE

                   IF pCdRubricaAgrupamento in (PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1925),
                                                PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1926),
                                                PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1927),
                                                PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,1928))
                     AND NOT PKGPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,PKGPAG_VAR.vgFolha,
                                     PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,962))
                     THEN

                       WITH RUBEXP AS (SELECT cdrubricaagrupamento
                        FROM epagformcalcblocoexprubagrup b
                                      WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao
                                        AND B.Cdrubricaagrupamento <> PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,9,962))
                    SELECT nvl(SUM(rv.vlreal), 0) AS vlreal,
                           nvl(SUM(rv.vlintegral), 0) AS vlintegral,
                           nvl(SUM(rv.vlproporcional), 0) AS vlproporcional
                         INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                      FROM epaghistoricorubricarelvinc rv
                        INNER JOIN RUBEXP R on R.CdRubricaAgrupamento = Rv.Cdrubricaagrupamento
                     WHERE rv.cdvinculo = pCdVinculo
                       AND rv.cdfolhapagamento = pCdFolhaHistorico;

                  ELSE

                    begin

                       WITH RUBEXP AS (SELECT cdrubricaagrupamento
                          FROM epagformcalcblocoexprubagrup b
                                      WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao)
                      SELECT nvl(SUM(rv.vlreal), 0) AS vlreal,
                             nvl(SUM(rv.vlintegral), 0) AS vlintegral,
                             nvl(SUM(rv.vlproporcional), 0) AS vlproporcional
                         INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                        FROM epaghistoricorubricarelvinc rv
                        INNER JOIN RUBEXP R on R.CdRubricaAgrupamento = Rv.Cdrubricaagrupamento
                       WHERE rv.cdvinculo = pCdVinculo
                         AND rv.cdfolhapagamento = pCdFolhaHistorico;

                    exception
                      when others then

                        vVlRubrica.vlReal         := 0;
                        vVlRubrica.vlIntegral     := 0;
                        vVlRubrica.vlProporcional := 0;

                    end;


                    if PKGPAG_VAR.vgCdFolhaSuplementarVinculo is not null
                       and pCdRubricaAgrupamento = 10095

                     then
                      vVlSuplementar := 0;

                      begin

                         WITH RUBEXP AS (SELECT cdrubricaagrupamento
                            FROM epagformcalcblocoexprubagrup b
                                      WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao)
                        SELECT nvl(sum(hrv.vlpagamento), 0)
                          INTO vVlSuplementar
                          FROM epaghistoricorubricavinculo hrv
                          INNER JOIN RUBEXP R on R.CdRubricaAgrupamento = hRv.Cdrubricaagrupamento
                         WHERE hrv.cdvinculo = pCdVinculo
                            AND hrv.cdfolhapagamento = PKGPAG_VAR.vgCdFolhaSuplementarVinculo;

                        vVlRubrica.vlReal := nvl(vvlrubrica.vlreal,0) + nvl(vVlSuplementar,0);
                        vVlRubrica.vlIntegral := nvl(vvlrubrica.vlIntegral,0) + nvl(vVlSuplementar,0);
                        vVlRubrica.vlProporcional := nvl(vvlrubrica.vlProporcional,0) + nvl(vVlSuplementar,0);

                      exception
                        when others then
                          null;

                      end;

                    end if;

                  END IF;

                  -- Caso nao encontre dados na tabela epaghistoricorubricarelvinc (implantacao)
                  -- busca dados na tabela epaghistoricorubricavinculo.
                  -- Consignacoes   9896/2017 - FOLHA - DESCONTO CONSIGNACAO 05-0711
                    IF NVL(vVlRubrica.vlProporcional, 0) = 0
                      OR NVL(pCdRubricaAgrupamento,0) = 48204
                      OR PKGPAG_VAR.vgrubrica(pCdRubricaAgrupamento).FlConsignacao = 'S'

                   THEN
                          WITH RUBEXP AS (SELECT cdrubricaagrupamento
                        FROM epagformcalcblocoexprubagrup b
                                           WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao)
                    SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                           nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                           nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                      INTO vVlRubrica.vlReal,
                           vVlRubrica.vlIntegral,
                           vVlRubrica.vlProporcional
                      FROM epaghistoricorubricavinculo hv
                            INNER JOIN RUBEXP R ON R.CdRubricaAgrupamento = Hv.Cdrubricaagrupamento
                     WHERE HV.CdFolhaPagamento = pCdFolhaHistorico
                       AND HV.Cdvinculo = pCdVinculo;

                  else
                    null;
                  END IF;

                END IF;

              END IF;

            ELSE

              --
              -- 7720/2015 - FOLHA - CALCULO 13º RESCISAO
              -- A RUBRICA 01-1023 ESTA GERANDO A MENOR. A FORMULA DE CALCULO DEVE PEGAR O VALOR REAL DA ULTIMO CONTRACHEQUE,
              --
              IF pCdRubricaAgrupamento IN (PKGPAG_VAR.vgCdRubricaRecisao13, 37561) --01-0322
               THEN

                 WITH RUBEXP AS (SELECT cdrubricaagrupamento
                    FROM epagformcalcblocoexprubagrup b
                   WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao),
                      RUBEXPSUPL AS (
                                  SELECT R2.CDTIPORUBRICA, RA2.CDRUBRICAAGRUPAMENTO
                    FROM RUBEXP
                                  INNER JOIN EPAGRUBRICAAGRUPAMENTO RA ON RA.CDRUBRICAAGRUPAMENTO = RUBEXP.CDRUBRICAAGRUPAMENTO
                                  INNER JOIN EPAGRUBRICA R ON R.CDRUBRICA = RA.CDRUBRICA
                                  INNER JOIN EPAGRUBRICA R2 ON R2.CDTIPORUBRICA IN (1,5,2,8) AND R2.NURUBRICA = R.NURUBRICA AND R.CDTIPORUBRICA = 1
                                  INNER JOIN  EPAGRUBRICAAGRUPAMENTO RA2 ON RA2.CDRUBRICA =  R2.CDRUBRICA AND RA2.CDAGRUPAMENTO = RA.CDAGRUPAMENTO
                      )

                SELECT nvl(SUM(vlreal), 0) AS vlreal,
                       nvl(SUM(vlreal), 0) AS vlintegral,
                       nvl(SUM(vlreal), 0) AS vlproporcional
                 INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM (

                        SELECT nvl(SUM(hrv.vlreal), 0) AS vlreal
                          FROM epaghistoricorubricarelvinc hrv
                         INNER JOIN ECalFolhaPag fp
                            ON hrv.cdfolhapagamento = fp.cdfolhapagamento
                           AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                    INNER JOIN RUBEXP R ON R.CdRubricaAgrupamento = Hrv.Cdrubricaagrupamento
                    WHERE HrV.CdVinculo = pCdVinculo AND
                          FP.NuAnoReferencia = pNuAnoReferencia AND
                          FP.NuMesReferencia = pNuMesReferencia AND
                          FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                          FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal)  AND
                          FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS
                        UNION ALL
                        SELECT nvl(SUM(CASE
                                          WHEN R.CDTIPORUBRICA IN (1, 2) THEN
                                           hv.vlpagamento
                                          WHEN R.CDTIPORUBRICA IN (5, 8) THEN
                                           (-1) * hv.vlpagamento
                                     ELSE 0
                                   END
                               ), 0) AS vlreal
                          FROM epaghistoricorubricavinculo hv
                         INNER JOIN ECalFolhaPag fp
                            ON hv.cdfolhapagamento = fp.cdfolhapagamento
                           AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                         INNER JOIN epagtipofolhapagamento tfp
                              ON fp.cdtipofolhapagamento = tfp.cdtipofolhapagamento
                           AND TFP.CdTipoFolha = pkgpag_tipo.cnTpFolhaNormal
                            INNER JOIN RUBEXPSUPL R ON R.CdRubricaAgrupamento = Hv.Cdrubricaagrupamento
                         WHERE HV.CdVinculo = pCdVinculo
                           AND HV.CDPROCESSOPAGRETROATIVO IS NULL
                           AND HV.CDPROCESSORESTITUICAOERARIO IS NULL
                           AND FP.NuAnoReferencia = pNuAnoReferencia
                           AND FP.NuMesReferencia = pNuMesReferencia
                              AND FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoSupl)
                           AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS

                        );

              ELSE
                --
                -- Para folha funebre calcular da folha normal anterior. Alem da solicitacao foi estendida
                -- as demais rubricas que tem como base a folha anterior
                -- Solicitacao de Sustentacao #77318
                -- SEA - Solicitacao nº 10.693/2017 - Erro de calculo na folha funebre causado pelo
                -- reprocessamento da rubrica 01-0156
                --
                  IF PKGPAG_VAR.vgfolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre
                     and pinmes = 'AN'
                    THEN

                        WITH RUBEXP AS (SELECT cdrubricaagrupamento
                      FROM epagformcalcblocoexprubagrup b
                     WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao)
                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                           INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                   INNER JOIN ECalFolhaPag fp
                      ON hv.cdfolhapagamento = fp.cdfolhapagamento
                     AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                   INNER JOIN epagtipofolhapagamento tfp
                      ON fp.cdtipofolhapagamento = tfp.cdtipofolhapagamento
                     AND TFP.CdTipoFolha = pkgpag_tipo.cnTpFolhaNormal
                          INNER JOIN RUBEXP R ON R.CdRubricaAgrupamento = Hv.Cdrubricaagrupamento
                   WHERE HV.CdVinculo = pCdVinculo
                     AND FP.NuAnoReferencia = pNuAnoReferencia
                     AND FP.NuMesReferencia = pNuMesReferencia
                            AND FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl)
                     AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS;

                ELSE

                      WITH RUBEXP AS (SELECT cdrubricaagrupamento
                      FROM epagformcalcblocoexprubagrup b
                     WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao)
                  SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                         nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                         nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                        INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                    FROM epaghistoricorubricavinculo hv
                   INNER JOIN ECalFolhaPag fp
                      ON hv.cdfolhapagamento = fp.cdfolhapagamento
                     AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                   INNER JOIN RUBEXP R ON R.CdRubricaAgrupamento = Hv.Cdrubricaagrupamento
                   WHERE HV.CdVinculo = pCdVinculo
                     AND FP.NuAnoReferencia = pNuAnoReferencia
                     AND FP.NuMesReferencia = pNuMesReferencia
                        AND FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento
                        AND FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl)
                     AND FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS;

                END IF;

              END IF;

            END IF;

          ELSE

            IF NOT pflvalorzero THEN

              IF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                 ptptributacao = 1 THEN

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                   INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                  WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                        HV.CdVinculo = pCdVinculo AND
                         EXISTS (SELECT B.CdRubricaAgrupamento
                          FROM epagformcalcblocoexprubagrup b
                         INNER JOIN epagrubricaagrupamento ra
                                     ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
                         INNER JOIN epagrubrica r
                            ON r.cdrubrica = ra.cdrubrica
                                  WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                        B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                               (r.cdtiporubrica NOT IN (10, 12) AND
                                        NOT (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95) AND
                                        NOT (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915,926)) AND
                                        NOT (R.CdTipoRubrica = 5 AND R.NuRubrica = 976) AND
                                        B.CdRubricaAgrupamento NOT IN (nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,0),
                    nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqExercFind13Sal,0))) AND
                               B.CdRubricaAgrupamento NOT IN
                               (SELECT tr.cdrubricaagrupamento
                                  FROM etrbisencaorubrica tr
                                 INNER JOIN etrbhistisencaorubrica htr
                                            ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                 INNER JOIN etrbrubricaisentaformula tif
                                            ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                         WHERE TR.CdVinculo = pCdVinculo AND
                                               TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                               ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                               (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                               HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                               AND
                                               (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                               (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                               HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                       htr.numesfimvigencia IS NULL))));

              ELSIF PKGPAG_VAR.vgparampagamento.fltributarraseparado = 'S' AND
                    ptptributacao = 4 THEN

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                    INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                   WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                         HV.Cdvinculo = pCdVinculo AND
                         HV.CdProcessoPagRetroativo = PKGPAG_RT.vgProcessoRetroativo(vgIndProcRetro).CdProcessoPagRetroativo AND
                          EXISTS (SELECT B.CdRubricaAgrupamento
                          FROM epagformcalcblocoexprubagrup b
                         INNER JOIN epagrubricaagrupamento ra
                                      ON RA.CdRubricaAgrupamento = B.CdRubricaAgrupamento
                         INNER JOIN epagrubrica r
                            ON r.cdrubrica = ra.cdrubrica
                                   WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                         B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                                         (R.CdTipoRubrica IN (10,12) OR (R.CdTipoRubrica = 6 AND R.NuRubrica IN (915, 926)) OR
                                         (R.CdTipoRubrica IN (1,2) AND R.NuRubrica = 95) OR
                               (ra.flpensaoalimenticia = 'S') OR
                                         B.CdRubricaAgrupamento = nvl(PKGPAG_VAR.vgParamPagamento.CdRubAgrupBloqRetExercFind,0)) AND
                               b.cdrubricaagrupamento NOT IN
                               (SELECT tr.cdrubricaagrupamento
                                  FROM etrbisencaorubrica tr
                                 INNER JOIN etrbhistisencaorubrica htr
                                             ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                 INNER JOIN etrbrubricaisentaformula tif
                                             ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                          WHERE TR.CdVinculo = pCdVinculo AND
                                                TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                                ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                                (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                                HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                                AND
                                                (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                                (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                                HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                       htr.numesfimvigencia IS NULL))));

              ELSE

                SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                       nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                       nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                  INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                  FROM epaghistoricorubricavinculo hv
                 WHERE HV.CdFolhaPagamento = pCdFolhaHistorico AND
                       HV.Cdvinculo = pCdVinculo AND
                        EXISTS (SELECT CdRubricaAgrupamento
                          FROM epagformcalcblocoexprubagrup b
                                 WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                       B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                               b.cdrubricaagrupamento NOT IN
                               (SELECT tr.cdrubricaagrupamento
                                  FROM etrbisencaorubrica tr
                                 INNER JOIN etrbhistisencaorubrica htr
                                           ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                                 INNER JOIN etrbrubricaisentaformula tif
                                           ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                        WHERE TR.CdVinculo = pCdVinculo AND
                                              TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                              ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                              (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                              HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                              AND
                                              (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                              (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                              HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                       htr.numesfimvigencia IS NULL))));

              END IF;

            ELSE

              SELECT nvl(SUM(hv.vlpagamento), 0) AS vlreal,
                     nvl(SUM(hv.vlpagamento), 0) AS vlintegral,
                     nvl(SUM(hv.vlpagamento), 0) AS vlproporcional
                INTO vVlRubrica.vlReal, vVlRubrica.vlIntegral, vVlRubrica.vlProporcional
                FROM epaghistoricorubricavinculo hv
               INNER JOIN ECalFolhaPag fp
                  ON hv.cdfolhapagamento = fp.cdfolhapagamento
                 AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                WHERE HV.CdVinculo = pCdVinculo AND
                      FP.NuAnoReferencia = pNuAnoReferencia AND
                      FP.NuMesReferencia = pNuMesReferencia AND
                      FP.CdTipoFolhaPagamento = PKGPAG_VAR.vgFolha.CdTipoFolhaPagamento AND
                      FP.CdTipoCalculo IN (PKGPAG_TIPO.cnTpCalculoNormal, PKGPAG_TIPO.cnTpCalculoSupl) AND
                      FP.FlCalculoDefinitivo = PKGPAG_TIPO.cnS AND
                      EXISTS (SELECT CdRubricaAgrupamento
                        FROM epagformcalcblocoexprubagrup b
                               WHERE B.CdFormulaCalcBlocoExpressao = pCdBlocoExpressao AND
                                     B.CdRubricaAgrupamento = HV.CdRubricaAgrupamento AND
                             b.cdrubricaagrupamento NOT IN
                             (SELECT tr.cdrubricaagrupamento
                                FROM etrbisencaorubrica tr
                               INNER JOIN etrbhistisencaorubrica htr
                                         ON HTR.CdIsencaoRubrica = TR.CdIsencaoRubrica
                               INNER JOIN etrbrubricaisentaformula tif
                                         ON TIF.CdHistIsencaoRubrica = HTR.CdHistIsencaoRubrica
                                      WHERE TR.CdVinculo = pCdVinculo AND
                                            TIF.CdRubricaAgrupFormula = pCdRubricaAgrupamento AND
                                            ((HTR.NuAnoInicioVigencia < pNuAnoReferencia OR
                                            (HTR.NuAnoInicioVigencia = pNuAnoReferencia AND
                                            HTR.NuMesInicioVigencia <= pNuMesReferencia))
                                            AND
                                            (HTR.NuAnoFimVigencia > pNuAnoReferencia OR
                                            (HTR.NuAnoFimVigencia = pNuAnoReferencia AND
                                            HTR.NuMesFimVigencia >= pNuMesReferencia) OR
                                     htr.numesfimvigencia IS NULL))));

            END IF;

          END IF;

        else
          null;
        END IF;

      END IF;

      RETURN vvlrubrica;

    EXCEPTION

      WHEN OTHERS THEN

        RETURN vvlrubrica;

    END;

    FUNCTION FObterCdFolhaRecalculoGeradoraSuplementar(pCdOrgao         IN INTEGER,
                                                       pNuAnoReferencia IN INTEGER,
                                                     pNuMesReferencia IN INTEGER) RETURN INTEGER IS
      vCdFolhaRecalculo INTEGER;
    BEGIN
       select cdfolhavincsupl
        into vCdFolhaRecalculo
        from (select fpg.cdfolhavincsupl
                from ECalFolhaPag fpg
               inner join epagtipofolhapagamento tfp
                  on fpg.cdtipofolhapagamento = tfp.cdtipofolhapagamento
               where fpg.cdorgao = pCdOrgao
                 AND FPG.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                 and fpg.nuanoreferencia = pNuAnoReferencia
                 and fpg.numesreferencia = pNuMesReferencia
                 and tfp.cdtipofolha = 1
                 and fpg.cdtipocalculo = 5 --suplementar
                 and fpg.flcalculodefinitivo = 'S'
                 and fpg.flfolhafechada = 'S'
               order by fpg.nusequencialfolha desc)
       where rownum = 1;

      RETURN vCdFolhaRecalculo;

    EXCEPTION
      WHEN no_data_found THEN
        RETURN null;
      WHEN OTHERS THEN
        RETURN null;
    END;
   
    PROCEDURE PPossuiApenasSuplementar(pNuAnoReferencia  IN  INTEGER,
                                       pNuMesReferencia  IN  INTEGER,
                                       pcdvinculo        IN  INTEGER,
                                       pCdFolhaRecalculo OUT INTEGER) IS
      
      
    BEGIN
      
        SELECT cdfolhavincsupl
          INTO pCdFolhaRecalculo
          FROM (SELECT fpg.cdfolhavincsupl
                  FROM ECalFolhaPag fpg
                 INNER JOIN epagcapahistrubricavinculo c
                    ON C.cdfolhapagamento = fpg.cdfolhapagamento                            
                 WHERE fpg.cdorgao = PKGPAG_VAR.vgFolha.CdOrgao
                   AND FPG.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                   AND fpg.nuanoreferencia = pNuAnoReferencia
                   AND fpg.numesreferencia = pNuMesReferencia 
                   AND fpg.cdtipofolhapagamento = PKGPAG_VAR.vgFolha.cdtipofolhapagamento
                   AND fpg.cdtipocalculo = PKGPAG_TIPO.cnTpCalculoSupl 
                   AND fpg.flcalculodefinitivo = 'S'
                   AND fpg.flfolhafechada = 'S'
                   AND c.cdvinculo = pcdvinculo
                   AND c.vlproventos > 0
                   AND NOT EXISTS (SELECT 1
                                    FROM ECalFolhaPag fnormal
                              INNER JOIN epagcapahistrubricavinculo hrv
                                 ON hrv.cdfolhapagamento = fnormal.cdfolhapagamento                            
                              WHERE fnormal.cdorgao = fpg.cdorgao
                                AND fnormal.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                                AND fnormal.nuanoreferencia = fpg.nuanoreferencia
                                AND fnormal.numesreferencia = fpg.numesreferencia 
                                AND fnormal.cdtipofolhapagamento = fpg.cdtipofolhapagamento
                                AND fnormal.cdtipocalculo = PKGPAG_TIPO.cnTpCalculoNormal
                                AND fnormal.flcalculodefinitivo = 'S'
                                AND fnormal.flfolhafechada = 'S'
                                AND hrv.cdvinculo = c.cdvinculo
                                AND hrv.vlproventos > 0)
                 ORDER BY fpg.nusequencialfolha DESC)
          WHERE ROWNUM = 1;
          
    EXCEPTION
      
       WHEN OTHERS THEN
         
         pCdFolhaRecalculo := NULL; 
        
    END;
    
  BEGIN
 
    IF pnumesreferencia = 1 THEN

      vnumesant := 12;
      vnuanoant := pnuanoreferencia - 1;

    ELSE

      vnumesant := pnumesreferencia - 1;
      vnuanoant := pnuanoreferencia;

    END IF;

    vvlRub := FObtemValores
       (pFlBaseCalculo => pFlBaseCalculo,
                            pcdfolhahistorico     => pcdfolhahistatu,
                            pcdtipohistorico      => pcdtipohistorico,
                            pdescrubisentaformula => PKGPAG_VAR.bdescrubisentaformula,
                            pnuanoreferencia      => pnuanoreferencia,
                            pnumesreferencia      => pnumesreferencia,
                            ptptributacao         => ptptributacao);

    IF vvlrub.vlintegral = 0 AND pinmes = 'AN' THEN

    vvlRub := FObtemValores
       (PFlBaseCalculo          => pFlBaseCalculo,
                              pcdfolhahistorico     => pcdfolhahistatu,
                              pcdtipohistorico      => pcdtipohistorico,
                              pdescrubisentaformula => PKGPAG_VAR.bdescrubisentaformula,
                              pnuanoreferencia      => vnuanoant,
                              pnumesreferencia      => vnumesant,
                              ptptributacao         => ptptributacao,
                              pflvalorzero          => TRUE);

    ELSIF pinmes = 'UL' THEN
      
     /* Para o RUB utilizado com o UL, se não existir folha normal da competência anterior mas existir uma suplementar paga,
       serão buscados os valores do recálculo que originou essa suplementar */
      PPossuiApenasSuplementar(vnuanoant,
                               vnumesant,
                               pcdvinculo,
                               vCdFolhaRecalculo);
      
      IF vCdFolhaRecalculo IS NOT NULL THEN
        
         BEGIN
           
           SELECT NVL(SUM(hrv.vlreal),0) AS vlintegral,
                  NVL(SUM(hrv.vlreal),0) AS vlproporcional,
                  NVL(SUM(hrv.vlreal),0) AS vlreal,
                  NVL(SUM(hrv.vlindicerubrica),0) AS vlindicerubrica,
                  NULL 
              INTO vvlRub    
              FROM epaghistoricorubricarelvinc hrv
             WHERE HRV.CdFolhaPagamento = vCdFolhaRecalculo 
               AND HRV.CdVinculo = pCdVinculo
               AND EXISTS (SELECT 1
                             FROM epagformcalcblocoexprubagrup b
                            WHERE B.CdFormulaCalcBlocoExpressao = pcdblocoexpressao
                              AND B.CdRubricaAgrupamento = HRV.CdRubricaAgrupamento);
         EXCEPTION
           
           WHEN OTHERS THEN
             
             vvlRub.vlIntegral := 0;
             vvlRub.vlProporcional := 0;
             vvlRub.vlReal := 0;
             vvlRub.vlIndice := 0;
             vvlRub.deexpressao := NULL;
             
         END;                     
                 
                       
      ELSIF PKGPAG_VAR.vgVinculo.DtDesligamento < PKGPAG_VAR.vgFolha.DtInicioMes AND
         PKGPAG_VAR.vgvinculo.dtinclusao < PKGPAG_VAR.vgfolha.dtiniciomes THEN

         vvlRub := FObtemValores
           (PFlBaseCalculo          => pFlBaseCalculo,
                                pcdfolhahistorico     => pcdfolhahistatu,
                                pcdtipohistorico      => pcdtipohistorico,
                                pdescrubisentaformula => PKGPAG_VAR.bdescrubisentaformula,
                                pnuanoreferencia      => vnuanoant,
                                pnumesreferencia      => vnumesant,
                                ptptributacao         => ptptributacao,
                                pflvalorzero          => TRUE);

      ELSIF vvlrub.vlintegral = 0 THEN

        IF PKGPAG_VAR.vgVinculo.DtDesligamento < PKGPAG_VAR.vgFolha.DtInicioMes AND
           PKGPAG_VAR.vgVinculo.DtInclusao >= PKGPAG_VAR.vgFolha.DtInicioMes THEN

           vvlRub := FObtemValores
             (PFlBaseCalculo          => pFlBaseCalculo,
                                  pcdfolhahistorico     => pcdfolhahistatu,
                                  pcdtipohistorico      => pcdtipohistorico,
                                  pdescrubisentaformula => PKGPAG_VAR.bdescrubisentaformula,
                                  pnuanoreferencia      => pnuanoreferencia,
                                  pnumesreferencia      => pnumesreferencia,
                                  ptptributacao         => ptptributacao,
                                  pflvalorzero          => TRUE);
        ELSE

          vvlRub := FObtemValores
           (pFlBaseCalculo          => pFlBaseCalculo,
                                  pcdfolhahistorico     => pcdfolhahistalt,
                                  pcdtipohistorico      => pcdtipohistorico,
                                  pdescrubisentaformula => PKGPAG_VAR.bdescrubisentaformula,
                                  pnuanoreferencia      => pnuanoreferencia,
                                  pnumesreferencia      => pnumesreferencia,
                                  ptptributacao         => ptptributacao);

          IF vvlRub.vlIntegral = 0 THEN
            vCdFolhaRecalculo := FObterCdFolhaRecalculoGeradoraSuplementar(pCdOrgao         => PKGPAG_VAR.vgFolha.CdOrgao,
                                                                           pNuAnoReferencia => pnuanoreferencia,
                                                                           pNuMesReferencia => pnumesreferencia);

            IF vCdFolhaRecalculo IS NOT NULL THEN
              vvlRub := FObtemValores(pFlBaseCalculo        => pFlBaseCalculo,
                                      pcdfolhahistorico     => vCdFolhaRecalculo,
                                      pcdtipohistorico      => pcdtipohistorico,
                                      pdescrubisentaformula => PKGPAG_VAR.bdescrubisentaformula,
                                      pnuanoreferencia      => pnuanoreferencia,
                                      pnumesreferencia      => pnumesreferencia,
                                      ptptributacao         => ptptributacao);

            END IF;

          END IF;

        END IF;

        IF vvlrub.vlintegral = 0 THEN

           vvlRub := FObtemValores
            (pFlBaseCalculo    => pFlBaseCalculo,
                                  pcdfolhahistorico     => pcdfolhahistalt,
                                  pcdtipohistorico      => pcdtipohistorico,
                                  pdescrubisentaformula => PKGPAG_VAR.bdescrubisentaformula,
                                  pnuanoreferencia      => vnuanoant,
                                  pnumesreferencia      => vnumesant,
                                  ptptributacao         => ptptributacao,
                                  pflvalorzero          => TRUE);

        END IF;

      else
        null;
      END IF;
    else
      null;
    END IF;

    RETURN vvlrub;

  END;

  FUNCTION fmneNaoAfastDefinNoMes(pcdvinculo       IN INTEGER,
                                  pnumesreferencia IN INTEGER,
                                  pnuanoreferencia IN INTEGER)
    RETURN INTEGER IS

    vNaoAfastDefinMes      INTEGER;
    vAbonoPermanencia10914 INTEGER;

  BEGIN
     vAbonoPermanencia10914 := PKGPAG_GERAL.fretornarubrica(1, 1, 0914);

    IF vAbonoPermanencia10914 = 8738 THEN

      SELECT 0
        INTO vNaoAfastDefinMes
        FROM epvdconcessaoaposentadoria apo
       WHERE apo.cdvinculo = pcdvinculo
             AND apo.dtinicioaposentadoria > pkgutil.PRIMEIRO_DIA_MES(pnumesreferencia,pnuanoreferencia)
             AND apo.dtinicioaposentadoria <= pkgutil.ULTIMO_DIA_MES(pnumesreferencia,pnuanoreferencia)
         AND apo.flativa = 'S';

      RETURN vNaoAfastDefinMes;

    ELSE

      SELECT 0
        INTO vNaoAfastDefinMes
        FROM epvdconcessaoaposentadoria apo
       WHERE apo.cdvinculo = pcdvinculo
             AND apo.dtinicioaposentadoria > pkgutil.PRIMEIRO_DIA_MES(pnumesreferencia,pnuanoreferencia)
             AND apo.dtinicioaposentadoria <= pkgutil.ULTIMO_DIA_MES(pnumesreferencia,pnuanoreferencia);

      RETURN vNaoAfastDefinMes;
    END IF;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN 1;

  END;

  FUNCTION fmneVlConsigsFuturas(pcdvinculo       IN INTEGER,
                                pnumesreferencia IN INTEGER,
                                pnuanoreferencia IN INTEGER)
      RETURN NUMBER IS

    vVlConsigsFuturas NUMBER(13, 2);

  BEGIN
 
    SELECT SUM(bc.vlmensalcontratado)
      INTO vVlConsigsFuturas
      FROM epagbaseconsignacao bc
     WHERE bc.cdvinculo = pcdvinculo
       AND bc.nuanoreferenciainicial >= pnuanoreferencia
       AND bc.numesreferenciainicial >= pnumesreferencia + 1;

    RETURN vVlConsigsFuturas;

  EXCEPTION
    WHEN no_data_found THEN
      RETURN 0;

  END;

  FUNCTION fretornavalorbasecalculo(pfolha            IN pkgpag_tipo.rfolha,
                                    pcdvinculo        IN INTEGER,
                                    pcdtipohistorico  IN INTEGER,
                                    pcdrelacaovinculo IN INTEGER,
                                    pcdbasecalculo    IN INTEGER,
                                    pcdchave          IN INTEGER,
                                    ptptributacao     IN INTEGER DEFAULT NULL,
                                    pCdFolhaAnt       IN INTEGER DEFAULT NULL)

   RETURN pkgpag_tipo.rvalorpagamento IS

    vvlcalculado pkgpag_tipo.rvalorpagamento;

    vvlexpressao pkgpag_tipo.rvalorpagamento;

    vdeexpressao pkgpag_tipo.rexprpagamento;

    vdeformula pkgpag_tipo.rexprpagamento;

    vrubrica pkgpag_tipo.rrubrica;

    vbaseexpr pkgpag_tipo.rbasecalculo;

    --vCdBaseCalculo NUMBER;

    --vVlBase9052 pkgpag_tipo.rValorPagamento;

    vSgBaseCalculo VARCHAR2(10);

    vVlBaseIprevDisposicao number;

    VnuDiasI number;

    VnudiasF number;

    vVlContribuicao number;

  BEGIN
 
    PKGPAG_VAR.vgDeExpressaoBaseIRRF := NULL;

    BEGIN
      SELECT bc.sgbasecalculo
        INTO vSgBaseCalculo
        FROM epagbasecalculo bc
       WHERE bc.cdbasecalculo = pCdBaseCalculo
         AND bc.cdagrupamento = pFolha.CdAgrupamento;

    EXCEPTION
        WHEN OTHERS
          THEN

        PKGPAG_VAR.vgDeExpressaoBaseIRRF := NULL;
    END;

    vvlcalculado.vlproporcional := NULL;
    vvlcalculado.vlintegral     := NULL;
    vvlcalculado.vlreal         := NULL;

    IF NOT PKGPAG_VAR.vgbaseexpr.exists(pcdbasecalculo) THEN
      RETURN vvlcalculado;
    END IF;

    vbaseexpr := PKGPAG_VAR.vgbaseexpr(pcdbasecalculo);

    IF vbaseexpr.lbloco.count = 0 THEN
      RETURN vvlcalculado;
    END IF;

    vdeformula.deexprproporcional := vbaseexpr.deformula;
    vdeformula.deexprintegral     := vbaseexpr.deformula;
    vdeformula.deexprreal         := vbaseexpr.deformula;

  FOR j IN vBaseExpr.lBloco.FIRST .. vBaseExpr.lBloco.LAST
  LOOP

      vdeexpressao.deexprproporcional := '';
      vdeexpressao.deexprintegral     := '';
      vdeexpressao.deexprreal         := '';

      IF vbaseexpr.lbloco(j).lexpressao.count > 0 THEN

      FOR k IN vBaseExpr.lBloco(j).lExpressao.FIRST .. vBaseExpr.lBloco(j).lExpressao.LAST
      LOOP

          vvlcalculado.vlproporcional := NULL;
          vvlcalculado.vlintegral     := NULL;
          vvlcalculado.vlreal         := NULL;

          CASE vbaseexpr.lbloco(j).lexpressao(k).cdtipomneumonico

            WHEN 1 THEN -- REF

               vVlCalculado.vlProporcional :=

                     FMneREF(vBaseExpr.lBloco(j).lExpressao(k).CdValorReferencia);

           WHEN 4 THEN -- RUB

            vVlCalculado :=

              FMneRUB(pCdVinculo,
                                      vBaseExpr.lBloco(j).lExpressao(k).CdExpressao,
                       case when pCdFolhaAnt is not null THEN pCdFolhaAnt
                            else vBaseExpr.lBloco(j).lExpressao(k).CdFolhaHistorico end,
                                      vBaseExpr.lBloco(j).lExpressao(k).CdFolhaHistAlt,
                                      vBaseExpr.lBloco(j).lExpressao(k).InRelacaoRubrica,
                                      vBaseExpr.lBloco(j).lExpressao(k).InTipoRubrica,
                                      vbaseexpr.lbloco(j).lexpressao(k).inmes,
                                      NULL,
                                      NULL,
                                      pCdTipoHistorico,
                                      pCdRelacaoVinculo,
                                      TRUE,
                                      pCdChave,
                                      vbaseexpr.cdrubricaagrupamento,
                                      pfolha.nuanoreferencia,
                                      pFolha.NuMesReferencia,
                                      pTpTributacao,
                                      pCdBaseCalculo,
                                      pFolha.CdAgrupamento);

          WHEN 5 THEN -- CHO mensal

             IF pCdRelacaoVinculo IN (0,1,2,3,4) THEN -- Efetivo/ Comissionado / Fun??o de Chefia

                vrubrica := PKGPAG_VAR.vgrubrica(vbaseexpr.cdrubricaagrupamento);

                vvlcalculado.vlproporcional := fmnecho(pfolha.cdagrupamento,
                                                       vrubrica,
                                                       pcdrelacaovinculo,
                                                       pcdchave);

              END IF;

            WHEN 8 THEN -- CEF

              vvlcalculado.vlproporcional := fmnecef;

           WHEN 9 THEN -- CELG

             vVlCalculado.vlProporcional :=

               FMneCELG(vBaseExpr.lBloco(j).lExpressao(k).CdValorGeralCEFAgrup,
                                                      pfolha.nuversaotabcef,
                                                      pfolha.nuanoreferencia,
                                                      pfolha.numesreferencia,
                                                      vBaseExpr.lBloco      (j).lExpressao(k).DeNivel,
                                                      vBaseExpr.lBloco      (j).lExpressao(k).DeReferencia);

           WHEN 15 THEN -- FUC

              IF vbaseexpr.lbloco(j).lexpressao(k).cdfuncaochefia IS NULL THEN

                IF PKGPAG_VAR.vgfuc.count > 0 THEN

                  vVlCalculado.vlProporcional :=

                     FMneFUC(pFolha => pFolha,
                                                         pfuc   => PKGPAG_VAR.vgfuc(1));

                ELSIF PKGPAG_VAR.vgfucsubst.count > 0 THEN

                  vVlCalculado.vlProporcional :=

                     FMneFUC(pFolha => pFolha,
                                                         pfuc   => PKGPAG_VAR.vgfucsubst(1));

                ELSE

                  vvlcalculado.vlproporcional := 0;

                END IF;

              END IF;

           WHEN 17 THEN  -- MediaANO

             vVlCalculado.vlProporcional :=

                FMneMediaAno(pCdVinculo,
                                                          pfolha.nuanoreferencia,
                                                          pfolha.numesreferencia,
                                                          pcdtipohistorico,
                                                          pcdrelacaovinculo,
                                                          pcdchave,
                                                          pfolha.cdagrupamento,
                                                          vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

           WHEN 18 THEN -- FMneMediaFeriasAtual

             vVlCalculado.vlProporcional :=

                FMneMediaFeriasAtual(pCdVinculo,
                                                                  pcdtipohistorico,
                                                                  pcdrelacaovinculo,
                                                                  pcdchave,
                                                                  pfolha.cdagrupamento,
                                                                  vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

           WHEN 19 THEN -- FMneMediaFeriasAnterior

             vVlCalculado.vlProporcional :=

                FMneMediaFeriasAnterior(pCdVinculo,
                                                                     pcdtipohistorico,
                                                                     pcdrelacaovinculo,
                                                                     pcdchave,
                                                                     pfolha.cdagrupamento,
                                                                     vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                     pfolha.NuMesReferencia,
                                                                     pfolha.NuAnoReferencia);

           WHEN 20 THEN -- MediaTempo

             vVlCalculado.vlProporcional :=

                FMneMediaTempo(pCdVinculo,
                                                            pfolha.nuanoreferencia,
                                                            pfolha.numesreferencia,
                                                            pcdtipohistorico,
                                                            pcdrelacaovinculo,
                                                            pcdchave,
                                                            pfolha.cdagrupamento,
                                                            vBaseExpr.lBloco      (j).lExpressao(k).CdRubricaAgrupamento,
                                                            vBaseExpr.lBloco      (j).lExpressao(k).NuMeses,
                                                            vBaseExpr.lBloco      (j).lExpressao(k).InTipoRetorno,
                                                            vBaseExpr.lBloco      (j).lExpressao(k).FlValorHoraMinuto);

           WHEN 21 THEN -- Somano

             vVlCalculado.vlProporcional :=

               FMneSomaAno(pCdVinculo,
                                                         pfolha.nuanoreferencia,
                                                         CASE
                                                            WHEN pfolha.cdagrupamento IN (2, 5, 6, 136) OR pfolha.cdtipofolha IN (3, 5) THEN
                                                            pfolha.numesreferencia
                                                           ELSE
                              CASE WHEN pFolha.NuMesReferencia > 1 THEN
                                                               pfolha.numesreferencia - 1
                                                              ELSE
                                                               1
                                                            END
                                                         END,
                                                         pcdtipohistorico,
                                                         pcdrelacaovinculo,
                                                         pcdchave,
                                                         pfolha.cdagrupamento,
                                                         vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

            WHEN 37 THEN

              PKGPAG_VAR.vgCdRubCalculada := vbaseexpr.cdrubricaagrupamento;

             vVlCalculado.vlProporcional :=

               FMneQtMesesTrabAno (pFolha           => pFolha,
                                                                pcdvinculo       => pcdvinculo,
                                                                pdtiniciorelacao => PKGPAG_VAR.vgvinculo.dtadmissao,
                                                                pdtfimrelacao    => PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                pdtcalculo       => PKGPAG_VAR.vdtcalculo);

           WHEN 38 THEN -- CELG

            vVlCalculado.vlProporcional :=

               FMnePercDecJud;

            WHEN 39 THEN

             vVlCalculado.vlProporcional :=

               FMnePossuiCC(pFolha           => pFolha,
                                                          pcdvinculo => pcdvinculo);

            WHEN 40 THEN

             vVlCalculado.vlProporcional :=

                FMneVlOutrosVinculos(pCdPessoa        => PKGPAG_VAR.vCdPessoa,
                                                                  pcdvinculo       => pcdvinculo,
                                                                  pCdRubrica       => vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                  pnuanoreferencia => pfolha.nuanoreferencia,
                                                                  pnumesreferencia => pfolha.numesreferencia);

            WHEN 42 THEN

              vvlcalculado.vlproporcional := fretornapercentacumats(pcdvinculo     => pcdvinculo,
                                                                    pcdagrupamento => pfolha.cdagrupamento,
                                                                    pdtiniciomes   => pfolha.dtiniciomes,
                                                                    pdtfimmes      => pfolha.dtfimmes);

            WHEN 43 THEN

              vvlcalculado.vlproporcional := fmnenaopossuicco;

            WHEN 44 THEN

              vvlcalculado.vlproporcional := fmnevalorbaserateiocco;
              
            WHEN 45 THEN

              vvlcalculado.vlproporcional := ffolha13saldezembro(pfolha => pfolha);  

            WHEN 49 THEN

              BEGIN

                vrubrica := PKGPAG_VAR.vgrubrica(vbaseexpr.cdrubricaagrupamento);

              EXCEPTION

                WHEN no_data_found THEN

                  vrubrica := NULL;

                WHEN OTHERS THEN

                  NULL;

              END;

             vVlCalculado.vlProporcional :=
                            FMesesTransPerAquisPrev(pCdVinculo           => pCdVinculo,
                                                                     pdtiniciomes         => pfolha.dtiniciomes,
                                                                     pdtfimmes            => pfolha.dtfimmes,
                                                                     pcdmodalidaderubrica => vrubrica.cdmodalidaderubrica);

            WHEN 50 THEN

             vVlCalculado.vlProporcional :=

                  FDiasNaoUsufridosPerConqAT(pCdVinculo        => pCdVinculo,
                                                                        pdtiniciomes => pfolha.dtiniciomes,
                                                                        pdtfimmes    => pfolha.dtfimmes);

            WHEN 51 THEN

             vVlCalculado.vlProporcional :=

              FDiasNaoUsufridosPerConqAN(pCdVinculo            => pCdVinculo,
                                                                        pnuanoreferencia => pfolha.nuanoreferencia,
                                                                        pnumesreferencia => pfolha.numesreferencia);

            WHEN 52 THEN

              vvlcalculado.vlproporcional := fmnealiquotafgts;

            WHEN 53 THEN

              vvlcalculado.vlproporcional := fmneinsssobreferias;

            WHEN 54 THEN

              vvlcalculado.vlproporcional := fqtdiasferiasnomes(pcdvinculo,
                                                                pfolha.dtiniciomes,
                                                                pfolha.dtfimmes);

            WHEN 57 THEN

              vVlCalculado.vlProporcional :=

               FMnePossuiDecJudicial( pCdVinculo    => pCdVinculo,
                                                                   pCdRubricaAgrupamento => vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                   pnuanoreferencia      => pfolha.nuanoreferencia,
                                                                   pnumesreferencia      => pfolha.numesreferencia);

            WHEN 58 THEN

              vvlcalculado.vlproporcional := pfolha.numesreferencia;

            WHEN 59 THEN

             vVlCalculado.vlProporcional :=
                              FMneQtMesesTrabAteMesRef (pFolha           => pFolha,
                                                                      pcdvinculo       => pcdvinculo,
                                                                      pdtiniciorelacao => PKGPAG_VAR.vgvinculo.dtadmissao,
                                                                      pdtfimrelacao    => PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                      pdtcalculo       => PKGPAG_VAR.vdtcalculo);

            WHEN 60 THEN

              vvlcalculado.vlproporcional := fmnechoproporcional(pcdrelacaovinculo => pcdrelacaovinculo,
                                                                 pcdchave          => pcdchave,
                                                                 prubrica          => vrubrica);

            WHEN 64 THEN

              vvlcalculado.vlproporcional := fmneiprev13sal(pcdvinculo        => pcdvinculo,
                                                            pfolha            => pfolha,
                                                            pCdFolhaReplicada => NVL(PKGPAG_VAR.vgCdFolhaReplicada13,pFolha.CdFolhaPagamento));

           WHEN 65 THEN -- Somano13

             vVlCalculado.vlProporcional :=

               FMneSomaAno13(pCdVinculo,
                                                           pfolha.nuanoreferencia,
                                                           CASE
                                                             WHEN pfolha.cdagrupamento IN (2, 5, 136) OR pfolha.cdtipofolha IN (3, 5) THEN
                                                              pfolha.numesreferencia
                                                             ELSE
                               CASE WHEN pFolha.NuMesReferencia > 1 THEN
                                                                 pfolha.numesreferencia - 1
                                                                ELSE
                                                                 1
                                                              END
                                                           END,
                                                           pcdtipohistorico,
                                                           pcdrelacaovinculo,
                                                           pcdchave,
                                                           pfolha.cdagrupamento,
                                                           vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

           WHEN 67 THEN -- Idade da pessoa na data do c?lculo

              vvlcalculado.vlproporcional := fmneidadepessoa(pfolha    => pfolha,
                                                             pcdpessoa => PKGPAG_VAR.vcdpessoa);

           WHEN 68 THEN -- CHO M?dio

              vvlcalculado.vlproporcional := fmnechomedio(pcdrelacaovinculo => pcdrelacaovinculo,
                                                          pcdchave          => pcdchave,
                                                          pdtinicio         => pfolha.dtiniciomes,
                                                          pdtfim            => pfolha.dtfimmes);

            WHEN 71 THEN

              vvlcalculado.vlproporcional := fmneinsspatronal(PKGPAG_VAR.vgRelVincPrincipal.CdUnidadeOrganizacional);

            WHEN 72 THEN -- VlPercentReducaoSal

              vvlcalculado.vlproporcional := PKGPAG_VAR.vgVlPercentReducao;

          -- EPAGRI - Media em horas anual
            WHEN 74 THEN

              vvlcalculado.vlproporcional := nvl(fmnemediaindiceano(pCdVinculo,
                                                                    pcdtipohistorico,
                                                                    pcdrelacaovinculo,
                                                                    pcdchave,
                                                                    vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                  pFolha),0);

            WHEN 75 THEN -- Outros - MediaGratEspecSaude: Media Gratificacao Especia ART 15 MP 196/2014

              vvlcalculado.vlproporcional := FMneMediaGratEspecSaude(pCdVinculo,
                                                                       pfolha.NuAnoReferencia||LPAD(pfolha.NuMesReferencia,2,'0'));

            WHEN 77 THEN  -- Retorna valor medio recalculado

              vvlcalculado.vlproporcional := nvl(fMneMediaFerias(pCdVinculo,
                                                                 pcdtipohistorico,
                                                                 pcdrelacaovinculo,
                                                                 pcdchave,
                                                                 vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                   pFolha),0);

            WHEN 78 THEN -- Quantidade de dias do Mes

                vvlcalculado.VlProporcional := pFolha.DtFimMes - pFolha.DtInicioMes + 1;

            WHEN 79 THEN -- Dias uteis do mes anterior

                vVlCalculado.vlProporcional :=

                  fmneqtdiasproxmes(pFolha,
                                                               PKGPAG_VAR.vgRelVincPrincipal.CdUnidadeOrganizacional,
                                    CASE WHEN PKGPAG_VAR.vgvinculo.dtadmissao BETWEEN add_months(pFolha.DtInicioMes,-1)
                                                                       AND add_months(pFolha.DtFimMes,-1)
                                         THEN PKGPAG_VAR.vgvinculo.dtadmissao
                                         ELSE add_months(pFolha.DtInicioMes,-1) END,
                                                               pFolha.DtInicioMes - 1);

            WHEN 80 THEN -- PossuiEnsinoMedico  Grau de escolaridade = Esino medio
              -- 3 REGULAR
              -- 4 PROFISSIONALIZANTE

              IF PKGPAG_VAR.vgNuGrauEscolaridade IN (3, 4) THEN
                vVlCalculado.vlProporcional := 1;
              ELSE
                vVlCalculado.vlProporcional := 0;
              END IF;

            WHEN 81 THEN --  PossuiEnsinoSuperior  Grau de escolaridade = Esino superior
              -- 5 GRADUACAO
              -- 6 GRADUACAO TECNOLOGICA

              IF PKGPAG_VAR.vgNuGrauEscolaridade IN (5, 6) THEN
                vVlCalculado.vlProporcional := 1;
              ELSE
                vVlCalculado.vlProporcional := 0;
              END IF;

            WHEN 82 THEN --  PossuiEspecializacao  Grau de escolaridade = Pos-graduacao e nivel de formacao Especializacao
              -- 7 ESPECIALIZACAO

              IF PKGPAG_VAR.vgNuGrauEscolaridade IN (7) THEN
                vVlCalculado.vlProporcional := 1;
              ELSE
                vVlCalculado.vlProporcional := 0;
              END IF;

            WHEN 83 THEN --  PossuiMestrado  Grau de escolaridade = Pos-graduacao e nivel de formacao Mestrado
              -- 8 MESTRADO

              IF PKGPAG_VAR.vgNuGrauEscolaridade IN (8) THEN
                vVlCalculado.vlProporcional := 1;
              ELSE
                vVlCalculado.vlProporcional := 0;
              END IF;

            WHEN 84 THEN --  PossuiDoutorado Grau de escolaridade = Pos-graduacao e nivel de formacao Doutorado
              -- 9 DOUTORADO
              -- 10  POS DOUTORADO

              IF PKGPAG_VAR.vgNuGrauEscolaridade IN (9, 10) THEN
                vVlCalculado.vlProporcional := 1;
              ELSE
                vVlCalculado.vlProporcional := 0;
              END IF;

          --
          -- Numero de dias uteis do mes anterior, descontando feriados
          --
            WHEN 85 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                p_tipo_retorno => 1);

          --
          -- Numero de feriados no mes anterior.
          --
            WHEN 86 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                p_tipo_retorno => 2);

          --
          -- Numero de sabados no mes anterior.
          --
            WHEN 87 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                p_tipo_retorno => 4);

          --
          -- Numero de domingos no mes anterior
          --
            WHEN 88 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                p_tipo_retorno => 3);

          --
          -- Valor Subsidio Privativo da Funcao de Chefia
          --
            WHEN 89 THEN

              IF PKGPAG_VAR.vgfucsubst.count > 0 -- and ppagcalc.nusufixorubrica = 2
               THEN

                vvlcalculado.vlproporcional := FMneSubsidioPrivativoFC(pfolha => pfolha,
                                                                       pfuc   => PKGPAG_VAR.vgfucsubst(1));

              ELSIF PKGPAG_VAR.vgfuc.count > 0 --and ppagcalc.nusufixorubrica = 1
               THEN

                vvlcalculado.vlproporcional := FMneSubsidioPrivativoFC(pfolha => pfolha,
                                                                       pfuc   => PKGPAG_VAR.vgfuc(1));

              ELSE

                vvlcalculado.vlproporcional := 0;

              END IF;

            WHEN 90 THEN

              IF PKGPAG_GERAL.fretornavalorrubrica(pFolha.CdFolhaPagamento,
                                                   pCdVinculo,
                                                     vbaseexpr.cdrubricaagrupamento) = 0
                  THEN

                PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento     => pFolha.CdFolhaPagamento,
                                                      pCdVinculo            => pCdVinculo,
                                                      pCdExpressaoFormCalc  => pCdBaseCalculo,
                                                      pCdRubricaAgrupamento => vbaseexpr.cdrubricaagrupamento,
                                                      pNuSufixoRubrica      => 1,
                                                      pVlPagamento          => 1,
                                                      pCdTipoOrigemRubrica  => 10,
                                                      pCdtipoindice         => 1);
              END IF;

          -- MneVlBasePrevInstituidor
            WHEN 92 THEN

              vVlCalculado.vlProporcional := fMneVlBasePrevInstituidor(pCdVinculo        => pCdVinculo,
                                                                       pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                       pCdTipoCalculo    => pFolha.CdTipoCalculo);
              -- MneVlTetoInstituidor
            WHEN 93 THEN

              vVlCalculado.vlProporcional := fMneVlTetoInstituidor(pCdVinculo        => pCdVinculo,
                                                                   pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                   pCdTipoCalculo    => pFolha.CdTipoCalculo);

          -- VlPercPensao
            WHEN 94 THEN

              vVlCalculado.vlProporcional := fMneVlPercPensao(pCdVinculo        => pCdVinculo,
                                                              pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia));

              vVlCalculado.vlIntegral := fMneVlPercPensao(pCdVinculo        => pCdVinculo,
                                                          pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                          pFlIntegral       => true);

          -- VlPensaoPrev
            WHEN 95 THEN

              vVlCalculado.vlProporcional := fMneVlPensaoPrev(pCdVinculo        => pCdVinculo,
                                                              pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia));

              vVlCalculado.vlIntegral := fMneVlPensaoPrev(pCdVinculo        => pCdVinculo,
                                                          pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                          pFlIntegral       => true);

          -- VlPercPensaoPrev
            WHEN 96 THEN

              vVlCalculado.vlProporcional := fMneVlPercPensaoPrev(pCdVinculo        => pCdVinculo,
                                                                  pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                  pCdTipoCalculo    => pFolha.CdTipoCalculo);
              -- VlPercPensaoBase
            WHEN 97 THEN

              IF PKGPAG_VAR.VGFOLHA.CDORGAO = 33 AND -- sig 7062
                 PKGPAG_GERAL.fpossuiregistroobito(PKGPAG_VAR.vCdPessoa,
                                                   PKGPAG_VAR.vgFolha.cdAgrupamento,
                                                   'S') or
                 (PKGPAG_VAR.vgVinculo.dtdesligamento <
                 PKGPAG_VAR.vgFolha.DtFimMes) AND vSgBaseCalculo = 'B920' OR
                 (pCdbaseCalculo = 6090 AND pfolha.cdagrupamento = 132) THEN

                vVlCalculado.vlProporcional := fMneVlPercPensaoBase(pCdVinculo        => pCdVinculo,
                                                                    pAnoMesReferencia => (pFolha.NuAnoReferencia * 100 +
                                                                                         pFolha.nuMesReferencia),
                                                                    pFlIntegral       => TRUE);
              ELSE

                vVlCalculado.vlProporcional := fMneVlPercPensaoBase(pCdVinculo        => pCdVinculo,
                                                                    pAnoMesReferencia => (pFolha.NuAnoReferencia * 100 +
                                                                                         pFolha.nuMesReferencia));
              END IF;

          -- VlPercIntegralidade
            WHEN 98 THEN
              vvlcalculado.vlProporcional := fMneVlPercIntegralidade(pCdVinculo        => pCdVinculo,
                                                              pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia));

            WHEN 99 THEN
              vvlcalculado.vlProporcional := fmneqtdiasafastsemrem;

             WHEN 102 THEN -- Outros - SomaOutrasFolhasMes

              vvlcalculado.vlproporcional := nvl(fMneSomaOutrasFolhasMes(pCdVinculo,
                                                                         vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                  pFolha),0);

             WHEN 103 THEN -- Outros - SomaFolhasMesAnt

              vvlcalculado.vlproporcional := nvl(fMneSomaOutrasFolhasMes(pCdVinculo,
                                                                         vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                  pFolha,'S'),0);


             when 104 then -- Indice Rubrica Outros MNEMONICOS

              vvlcalculado.vlProporcional := fmneindicerubrica(pCdVinculo,
                                                               vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

            when 105 then

                if pCdRelacaoVinculo = 1 then-- Remuneracao base de outras esferas

                vvlcalculado.vlProporcional := fmneRemunBaseOutraEsfera(pcdvinculo);

              else

                vvlcalculado.vlProporcional := 0;

              end if;

             when 106 then -- É equivalente ao SomaAno porém, somando de todos os vínculos do ano.
              -- *Todos os Vínculos do ano.
              IF PKGPAG_VAR.vgVinculo.dtdesligamento IS NOT NULL AND
                      PKGPAG_VAR.vgVinculo.dtdesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes
                      THEN

                       vVlCalculado.vlProporcional :=
                          FMneVlRubTodosVinculos(pCdPessoa        => PKGPAG_VAR.vCdPessoa,
                                                                      pcdfolhapagamento     => pFolha.CdFolhaPagamento,
                                                                      pCdRubricaAgrupamento => vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                      pnuanoreferencia      => pfolha.nuanoreferencia);
              END IF;

             WHEN 107 THEN -- Calcula a base do iprev 13o.sal para servidor que foi exonerado no mês da folha que está sendo calculada

              vVlCalculado.vlProporcional := nvl(fBaseIprev13EexoMesFolha(pCdVinculo,
                                                                   pfolha), 0);



              WHEN 108 THEN -- Calcula a base do iprev 13o.sal para servidor que foi exonerado em mês anterior ao da folha que está sendo calculada
              vVlCalculado.vlProporcional := fBaseIprev13ExonMesAntFolha(pCdVinculo,
                                                                         pfolha);

            WHEN 109 THEN
              vVlCalculado.vlProporcional := fconvBaseIprev13pIntegral(pCdVinculo,
                                                                       pfolha);

            WHEN 110 THEN
              vVlCalculado.vlProporcional := fMneRubrica13FolhaNormal(pCdVinculo            => pCdVinculo,
                                                                      pCdRubricaAgrupamento => vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                      pNuAnoReferencia      => pFolha.NuAnoReferencia,
                                                                      pNuMesReferencia      => pFolha.NuMesReferencia);

              when 111 then  -- Soma valor da rubrica no Ano, sem as rubricas adjacentes
              vVlCalculado.vlProporcional := fMneSomaAnoRubrica(pcdvinculo            => pCdVinculo,
                                                                pCdRubricaAgrupamento => vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                pfolha                => pFolha);

          -- MneVlBaseMilitarInstituidor
            WHEN 112 THEN

              vVlCalculado.vlProporcional := fMneVlBaseMilitarInstituidor(pCdVinculo        => pCdVinculo,
                                                                          pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                          pCdTipoCalculo    => pFolha.CdTipoCalculo);

            when 113 then

              if vSgBaseCalculo = 'BIR13' and
                /* (PKGPAG_VAR.vgRubrica(vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento).NuRubrica = 23 and
                                                                                                                    fmnevlanooutrosvinculos(PKGPAG_VAR.vgvinculo.cdpessoa,
                                                                                                                                           pcdvinculo,
                                                                                                                                           PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,5,546),
                                                                                                                                           pFolha.NuAnoReferencia) = 0) or*/
                   (PKGPAG_VAR.vgRubrica(vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento).NuRubrica not in (23,944,586,513,584,546) and
                  fmnevlanooutrosvinculos(PKGPAG_VAR.vgvinculo.cdpessoa,
                                          pcdvinculo,
                                           PKGPAG_GERAL.fretornarubrica(pFolha.CdAgrupamento,1,1023),
                                          pFolha.NuAnoReferencia) = 0) then

                vvlcalculado.vlProporcional := 0;

              else

                  vVlCalculado.vlProporcional :=
                      fmnevlanooutrosvinculos(PKGPAG_VAR.vgvinculo.cdpessoa,
                                                                       pcdvinculo,
                                                                       vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                       pFolha.NuAnoReferencia);

              end if;

            WHEN 114 THEN

              vvlcalculado.vlproporcional := CASE
                                               WHEN pCdFolhaAnt IS NULL THEN
                                                fmneNaoAfastDefinNoMes(pcdvinculo,
                                                                       pFolha.NuMesReferencia,
                                                                       pFolha.NuAnoReferencia)
                                               ELSE
                                                1
                                             END;
              /*
              WHEN 115 THEN

                vvlcalculado.vlproporcional := fmneVlConsigsFuturas(pcdvinculo,
                                                                    pFolha.NuMesReferencia,
                                                                    pFolha.NuAnoReferencia);
               */

            WHEN 116 THEN
              -- ValorRubMediaFerias
              -- Retorna media do valor no período de férias

              vvlcalculado.vlproporcional := nvl(fMneVlRubMediaFerias(pCdVinculo,
                                                                      pcdtipohistorico,
                                                                      pcdrelacaovinculo,
                                                                      pcdchave,
                                                                      vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                      pFolha,
                                                                      'N'),0);

            WHEN 117 THEN -- Quantidade de dias corridos do mes anterior ao processamento da folha, limitado ao parametro passado

                vvlcalculado.VlProporcional := PKGPAG_FB.fMneQtdDiasMesAnterior(pFolha.DtCalculo, 30);


            when 119 THEN

                vvlcalculado.VlProporcional :=FMneSomaAnoRubTodosVinculosINSS(PKGPAG_VAR.vgVinculo.CdPessoa,
                                                                              pFolha.CdFolhapagamento,
                                                                              vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                              pFolha.NuAnoReferencia);

            when 120 then

                vVlContribuicao := 0;

                vvlcalculado.VlProporcional := fmneAliquotaProgressivaINSS(PKGPAG_VAR.vAliqINSS.lFaixa,
                                                                           vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                           vVlContribuicao);

            WHEN 123 then

              vvlcalculado.vlproporcional :=

              FMneSomaRubMesOutrosVinculos(PKGPAG_VAR.vgVinculo.CdPessoa,
                                           vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                           pFolha);

            WHEN 124 then

              vvlcalculado.vlproporcional := fMnePercentAdiantFerias(pCdVinculo => pCdVinculo,
                                                                     pNuAno => pFolha.NuAnoReferencia,
                                                                     pNuMes => pFolha.NuMesReferencia);                                                                                  

            WHEN 125 THEN
              
              vvlcalculado.vlproporcional := fMnePossuiIsencaoIRRFRub(pCdVinculo            => pCdVinculo,
                                                                      pCdRubricaAgrupamento => vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                      pNuAnoReferencia      => pFolha.NuAnoReferencia,
                                                                      pNuMesReferencia      => pFolha.NuMesReferencia);
            WHEN 126 THEN
              
              vvlcalculado.vlproporcional := fmneRetornaValorRub(pFolha.CdFolhaPagamento, 
                                                                 PCdVinculo, 
                                                                 vBaseExpr.lBloco(j).lExpressao(k).CdRubricaAgrupamento);
            
            WHEN 127 THEN --CCOPuro
              
              vvlcalculado.vlproporcional := fmneCCOPuro(PKGPAG_VAR.vgcco,
                                                         PKGPAG_VAR.vgcef);
            
            WHEN 128 THEN --Opc70
              
              vvlcalculado.vlproporcional := fmneOPC70(pFolha.CdFolhaPagamento, 
                                                       PCdVinculo);  
                                                                   
            ELSE

              NULL;

          END CASE;

          IF vvlcalculado.vlintegral IS NULL THEN
            vvlcalculado.vlintegral := vvlcalculado.vlproporcional;
          END IF;

          IF vvlcalculado.vlreal IS NULL THEN
            vvlcalculado.vlreal := vvlcalculado.vlproporcional;
          END IF;

        vDeExpressao.DeExprProporcional :=
                vDeExpressao.DeExprProporcional ||
                vBaseExpr.lBloco(j).lExpressao(k).DeOperacao||
                                             round(vvlcalculado.vlproporcional, 4);

        vDeExpressao.DeExprIntegral :=
                vDeExpressao.DeExprIntegral ||
                vBaseExpr.lBloco(j).lExpressao(k).DeOperacao||
                                         round(vvlcalculado.vlintegral, 4);

        vDeExpressao.DeExprReal :=
                vDeExpressao.DeExprReal ||
                vBaseExpr.lBloco(j).lExpressao(k).DeOperacao||
                                     round(vVlCalculado.vlReal, 4);

        END LOOP;

        vdeformula.deexprproporcional := REPLACE(vdeformula.deexprproporcional,
                                                 vbaseexpr.lbloco(j).sgbloco,
                                                 vdeexpressao.deexprproporcional);

        vdeformula.deexprintegral := REPLACE(vdeformula.deexprintegral,
                                             vbaseexpr.lbloco(j).sgbloco,
                                             vdeexpressao.deexprintegral);

        vdeformula.deexprreal := REPLACE(vdeformula.deexprreal,
                                         vbaseexpr.lbloco(j).sgbloco,
                                         vdeexpressao.deexprreal);

      END IF;
      
    END LOOP;

    IF vSgBaseCalculo = 'BIRRF'
      THEN

      PKGPAG_VAR.vgDeExpressaoBaseIRRF := vDeFormula.DeExprReal;

    END IF;

    vvlcalculado := favaliaexpressao(vdeformula);

    --
    --  SIG-2541 14137/2019 - REGRA DE ARREDONDAMENTO - DESCONTO E PATRONAL SCPREV
    --
    if vSgBaseCalculo in ('BSCPR', 'BSC13', 'B0920') then

      vvlcalculado.vlIntegral := trunc(vvlcalculado.vlIntegral, 2);

      vvlcalculado.vlProporcional := trunc(vvlcalculado.vlProporcional, 2);

      vvlcalculado.vlReal := trunc(vvlcalculado.vlReal, 2);

    end if;

    IF vBaseExpr.CdRubricaAgrupamento in (49205) THEN

      PKGPAG_VAR.vgValorCalculoRubrica(vBaseExpr.CdRubricaAgrupamento).VlLimiteInferior := vbaseexpr.NuQtdeValReferenciaInferior;

    ELSE

      if vSgBaseCalculo = 'DLEG' THEN
         vvlcalculado.vlproporcional := vvlcalculado.vlintegral;
         vvlcalculado.vlreal := vvlcalculado.vlintegral;
         --vdeformula.deexprreal := vvlcalculado.vlreal;
      ELSIF vSgBaseCalculo = 'DLE13' THEN 
          vvlcalculado.vlproporcional := vvlcalculado.vlintegral;
          vvlcalculado.vlreal := vvlcalculado.vlintegral;
          --vdeformula.deexprreal := vvlcalculado.vlreal;

      else

         vvlcalculado.vlintegral := fretornavalorlimitefinal(pbaseexpr    => vbaseexpr,
                                                             pvlexpressao => vvlcalculado.vlintegral);

         vvlcalculado.vlproporcional := fretornavalorlimitefinal(pbaseexpr    => vbaseexpr,
                                                                 pvlexpressao => vvlcalculado.vlproporcional);

         vvlcalculado.vlreal := fretornavalorlimitefinal(pbaseexpr    => vbaseexpr,
                                                         pvlexpressao => vvlcalculado.vlreal);
                                                       
         --vdeformula.deexprreal := vvlcalculado.vlreal;  

      end if;

      -- somente gerar se sera utilizado o desconto simplificado, ou seja, se a somatoria das deducoes legais for
      -- menor ou igual ao valor do desconto simplificado
      if vSgBaseCalculo = 'DSIMP' AND (((fMneSomaRubMes(PKGPAG_VAR.vgVinculo.cdvinculo,
                                        PKGPAG_VAR.vgCdRubBaseDeducoesIRRF, pfolha)+
                                        FMneSomaRubMesOutrosVinculos(PKGPAG_VAR.vgVinculo.CdPessoa,
                                                                     PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,pFolha))) <= 
                                      PKGPAG_PARAM.FValorReferencia('DESCSIMPL')) THEN
        
        vvlcalculado.vlintegral := PKGPAG_PARAM.FValorReferencia('DESCSIMPL');
        vvlcalculado.vlProporcional := vvlcalculado.vlintegral;
        vvlcalculado.vlReal := vvlcalculado.vlintegral;
      ELSIF vSgBaseCalculo = 'DSIMP' AND (((fMneSomaRubMes(PKGPAG_VAR.vgVinculo.cdvinculo,
                                        PKGPAG_VAR.vgCdRubBaseDeducoesIRRF, pfolha)+
                                        FMneSomaRubMesOutrosVinculos(PKGPAG_VAR.vgVinculo.CdPessoa,
                                                                     PKGPAG_VAR.vgCdRubBaseDeducoesIRRF,pFolha))) > 
                                      PKGPAG_PARAM.FValorReferencia('DESCSIMPL')) THEN
        vvlcalculado.vlintegral := 0;   
        vvlcalculado.vlProporcional := 0;
        vvlcalculado.vlReal := 0;

      END IF;   

      if vSgBaseCalculo = 'DSI13' AND (((fMneSomaRubMes(PKGPAG_VAR.vgVinculo.cdvinculo,
                                        PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13, pfolha)+
                                        fmnevlanooutrosvinculos(PKGPAG_VAR.vgVinculo.CdPessoa,
                                                                PKGPAG_VAR.vgVinculo.cdvinculo,  
                                                                PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,pFolha.NuAnoReferencia))) <= 
                                      PKGPAG_PARAM.FValorReferencia('DESCSIMPL')) THEN
        
        vvlcalculado.vlintegral := PKGPAG_PARAM.FValorReferencia('DESCSIMPL');
        vvlcalculado.vlProporcional := vvlcalculado.vlintegral;
        vvlcalculado.vlReal := vvlcalculado.vlintegral;
      ELSIF vSgBaseCalculo = 'DSI13' AND (((fMneSomaRubMes(PKGPAG_VAR.vgVinculo.cdvinculo,
                                        PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13, pfolha)+
                                        fmnevlanooutrosvinculos(PKGPAG_VAR.vgVinculo.CdPessoa,
                                                                PKGPAG_VAR.vgVinculo.cdvinculo,  
                                                                PKGPAG_VAR.vgCdRubBaseTotDeducoesIRRF13,pFolha.NuAnoReferencia))) > 
                                      PKGPAG_PARAM.FValorReferencia('DESCSIMPL')) THEN
        vvlcalculado.vlintegral := 0;   
        vvlcalculado.vlProporcional := 0;
        vvlcalculado.vlReal := 0;

      END IF;    

    END IF;
    --
    -- Tratamento EPAGRI Base 09-0930 que tem limite e deve considerar todas as relacoes de vinculo.
    --                   Rubricas: 05-0719; 05-0698; 05-0722; 05-0800;
    --
    -- Tratamento CIDASC Rubricas - 05-0802 e Base 09-0930
    --
    IF vBaseExpr.CdRubricaAgrupamento in (44574,43415,43422,45430,48192,48295,43441)
      and vvlcalculado.vlIntegral > 0
      THEN

      vvlexpressao := PKGPAG_GERAL.fretornavaloroutrasrv(PKGPAG_VAR.vgfolha.cdfolhapagamento,
                                                         PKGPAG_VAR.vgvinculo.cdvinculo,
                                                         vBaseExpr.CdRubricaAgrupamento);

        if nvl(vvlexpressao.vlIntegral,0) > 0
          then

        if (nvl(vvlexpressao.vlIntegral, 0) + vvlcalculado.vlIntegral) >
           vBaseExpr.NuQtdeValReferenciaSuperior

         then

                vvlcalculado.vlIntegral := vBaseExpr.NuQtdeValReferenciaSuperior - vvlexpressao.vlIntegral;
                vvlcalculado.vlProporcional := vBaseExpr.NuQtdeValReferenciaSuperior - vvlexpressao.vlProporcional;
                vvlcalculado.vlReal := vBaseExpr.NuQtdeValReferenciaSuperior - vvlexpressao.vlReal;

        end if;

      end if;

    END IF;

    IF PKGPAG_VAR.vgFolha.cdAgrupamento = 5
      AND vBaseExpr.CdRubricaAgrupamento = 44594
      AND pCdRelacaoVinculo = 3
      AND vSgBaseCalculo = 'BTETO' THEN

      vvlcalculado.vlReal         := 0;
      vvlcalculado.vlIntegral     := 0;
      vvlcalculado.vlProporcional := 0;

    END IF;

    IF vSgBaseCalculo = 'IPREV'
      AND NVL(PKGPAG_VAR.vgVlIntegralIPREV, 0) > 0
      THEN

      IF pCdRelacaoVinculo = PKGPAG_TIPO.cnTpRelacaoComissionado
        THEN

        vVlBaseIprevDisposicao := PKGPAG_GERAL.fVlBaseIPREVComissionadoADisp(PKGPAG_VAR.vgFolha,PKGPAG_VAR.vgVinculo.CdVinculo);

        if vVlBaseIprevDisposicao = 0 then

          vvlcalculado.vlReal         := vVlBaseIprevDisposicao; --PKGPAG_VAR.vgVlIntegralIPREV;
          vvlcalculado.vlIntegral     := vVlBaseIprevDisposicao; --PKGPAG_VAR.vgVlIntegralIPREV;
          vvlcalculado.vlProporcional := vVlBaseIprevDisposicao; --PKGPAG_VAR.vgVlIntegralIPREV;

        end if;
      ELSIF PKGPAG_VAR.vgFolha.cdAgrupamento = 176 --DPE
        AND pCdRelacaoVinculo = PKGPAG_TIPO.cnTpRelacaoEfetivo
        THEN

        vvlcalculado.vlReal         := PKGPAG_VAR.vgVlIntegralIPREV; --PKGPAG_VAR.vgVlIntegralIPREV;
        vvlcalculado.vlIntegral     := PKGPAG_VAR.vgVlIntegralIPREV; --PKGPAG_VAR.vgVlIntegralIPREV;
        vvlcalculado.vlProporcional := PKGPAG_VAR.vgVlIntegralIPREV; --PKGPAG_VAR.vgVlIntegralIPREV;

      END IF;
    end if;

    --- Proporcionaliza a rubrica 09-1066

    IF vSgBaseCalculo = 'VAPIN'
     AND vdeformula.deexprreal > 0
     AND vBaseExpr.CdRubricaAgrupamento = 49225
     AND PKGPAG_VAR.vgFolha.cdAgrupamento = 1  THEN

      BEGIN
              Select  dtinicio - trunc(pfolha.DtInicioMes,'MM'),trunc(LAST_DAY(pfolha.DtFimMes)) - dtfim
          INTO VnuDiasI, VnudiasF
          FROM EAFAAfastamentoVinculo eefa
         where eefa.cdvinculo = PKGPAG_VAR.vgVinculo.CdVinculo
                and  (trunc(eefa.dtinicio) between trunc(pfolha.DtFimMes,'MM') and trunc(LAST_DAY(pfolha.DtFimMes))
                 or trunc(eefa.dtfim) between trunc(pfolha.DtFimMes,'MM') and  trunc(LAST_DAY(pfolha.DtFimMes)))
                 and eefa.cdmotivoafasttemporario IN (3627, 3647,8607) and eefa.cdvinculo not in (757155) ;

        IF VnuDiasI > 0 then
                     vvlcalculado.vlReal :=  vdeformula.deexprreal / 30 * VnudiasI;
          vvlcalculado.vlIntegral     := vvlcalculado.vlReal;
          vvlcalculado.vlProporcional := vvlcalculado.vlReal;
          vvlcalculado.deexpressao    := VnudiasI;
        ELSE
                     vvlcalculado.vlReal :=  vdeformula.deexprreal / 30 * VnudiasF;
          vvlcalculado.vlIntegral     := vvlcalculado.vlReal;
          vvlcalculado.vlProporcional := vvlcalculado.vlReal;
          vvlcalculado.deexpressao    := VnudiasF;
        END IF;
         EXCEPTION WHEN OTHERS THEN
          vvlcalculado.vlReal         := 0;
          vvlcalculado.vlIntegral     := 0;
          vvlcalculado.vlProporcional := 0;
      END;

    END IF;

    vvlcalculado.deexpressao := vdeformula.deexprreal;

    RETURN vvlcalculado;

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneBase
     Objetivo:

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/
  FUNCTION fmnebase(pfolha            IN pkgpag_tipo.rfolha,
                    pcdvinculo        IN INTEGER,
                    pcdbasecalculo    IN INTEGER,
                    pcdtipohistorico  IN INTEGER,
                    pcdrelacaovinculo IN INTEGER,
                    pcdchave          IN INTEGER,
                    ptptributacao     IN INTEGER DEFAULT NULL)

   RETURN pkgpag_tipo.rvalorpagamento IS

  BEGIN
 
    --  SE A RUBRICA QUE EST? CALCULANDO FOR UMA INCORPORA??O DO SERVIDOR
    --  COM TIPO DE INCORPORA??O = 1, 2, 3 , 4 OU 5 E A OPERA??O FOR DE ADI??O,
    --  DESCONSIDERA ESTE MENUMONICO

    RETURN fretornavalorbasecalculo(pfolha            => pfolha,
                                    pcdvinculo        => pcdvinculo,
                                    pcdtipohistorico  => pcdtipohistorico,
                                    pcdrelacaovinculo => pcdrelacaovinculo,
                                    pcdbasecalculo    => pcdbasecalculo,
                                    pcdchave          => pcdchave,
                                    ptptributacao     => ptptributacao);

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneQtDiasUtMes
     Objetivo: Retorna o n?mero de dias ?teis no mes de acordo com o calend?rio
               do ?rg?o/agrupamento, levando em considera??o os feriados nacionais,
               estaduais e municipais.

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/
  FUNCTION fmneqtdiasutmes(pfolha           IN pkgpag_tipo.rfolha,
                           pcdunidorg       IN INTEGER,
                           pdtiniciorelacao IN DATE,
                           pdtdesligamento  IN DATE)

   RETURN NUMBER IS

    vdtinicio DATE;

    vdtfim DATE;

  BEGIN
 
    IF pdtiniciorelacao BETWEEN pfolha.dtiniciomes AND pfolha.dtfimmes THEN

      vdtinicio := pdtiniciorelacao;

    ELSE

      vdtinicio := pfolha.dtiniciomes;

    END IF;

    -- IF pDtDesligamento >= pFolha.DtInicioMes AND pDtDesligamento <= pFolha.DtFimMes THEN
    IF pdtdesligamento BETWEEN pfolha.dtiniciomes AND pfolha.dtfimmes THEN

      vdtfim := pdtdesligamento;

    ELSE

      vdtfim := pfolha.dtfimmes;

    END IF;

    RETURN PKGMOV.FQtDiaUtil(pFolha.CdAgrupamento,
                             pFolha.CdOrgao,
                             pCdUnidOrg,
                             vDtInicio,
                             vDtFim, 0, 'N', PKGPAG_VAR.vgCalculo.flgeral);
  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneQtDiasPerApu
     Objetivo: Retorna o n?mero de dias ?teis no mes de acordo com o periodo de
               apura??o da frequencia, levando em considera??o os feriados nacionais,
               estaduais e municipais.

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/

  FUNCTION fmneqtdiasperapu(pfolha          IN pkgpag_tipo.rfolha,
                            pcdunidorg      IN INTEGER,
                            pdtinicio       IN DATE,
                            pdtfim          IN DATE,
                            pdtdesligamento IN DATE)

   RETURN NUMBER IS

    --vNuDiasUteis INTEGER;

    vdtfim DATE;

  BEGIN
 
    IF pdtdesligamento >= pdtinicio AND pdtdesligamento <= pdtfim THEN

      vdtfim := pdtdesligamento;

    ELSE

      vdtfim := pdtfim;

    END IF;

    RETURN PKGMOV.FQtDiaUtil(pFolha.CdAgrupamento,
                             pFolha.CdOrgao,
                             pCdUnidOrg,
                             pDtInicio,
                             vDtFim, 0, 'N', PKGPAG_VAR.vgCalculo.flgeral);

  END;

  /*----------------------------------------------------------------------------
       Funcao: FMneQtDiasProxMes
     Objetivo: Retorna o n?mero de dias ?teis no pr?ximo mes de acordo com o periodo de
               apura??o da frequencia, levando em considera??o os feriados nacionais,
               estaduais e municipais.

   Argumentos:

         Nota:
  /-----------------------------------------------------------------------------*/

  FUNCTION fmneqtdiasproxmes(pfolha          IN pkgpag_tipo.rfolha,
                             pcdunidorg      IN INTEGER,
                             pdtinicio       IN DATE,
                             pdtfim          IN DATE,
                             pdtdesligamento IN DATE)

   RETURN NUMBER IS

    vdtfim DATE;

  BEGIN
 
    IF pdtdesligamento BETWEEN pdtinicio AND pdtfim THEN

      vdtfim := pdtdesligamento;

    ELSE

      vdtfim := pdtfim;

    END IF;

    RETURN PKGMOV.FQtDiaUtil(pFolha.CdAgrupamento,
                             pFolha.CdOrgao,
                             pCdUnidOrg,
                             pDtInicio,
                             vDtFim, 0, 'N', PKGPAG_VAR.vgCalculo.flgeral);

  END;

  FUNCTION ffolhanormaldezembrorec13sal(pcdvinculo IN INTEGER)

   RETURN INTEGER IS

    vpossuipagamento INTEGER;

  BEGIN
 
    -- Caso seja folha normal e haja folha de 13 sal no m?s anterior
    -- e folha de d?cimo terceiro no m?s da folha

    IF PKGPAG_VAR.vgfolha.cdtipofolha IN ( pkgpag_tipo.cntpfolhanormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast ) THEN

      IF PKGPAG_VAR.vgcdfolha13ant > 0 AND PKGPAG_VAR.vgcdfolha13 > 0 THEN

        BEGIN

          -- Realiza busca para saber se o servidor recebeu 13 sal?rio

          SELECT 0
            INTO vpossuipagamento
            FROM epaghistoricorubricavinculo hrv
           INNER JOIN ECalFolhaPag fp
              ON fp.cdfolhapagamento = hrv.cdfolhapagamento
             AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
           INNER JOIN (SELECT fpa.nuanoreferencia,
                              fpa.numesreferencia,
                              fpa.cdtipofolhapagamento,
                              fpa.cdtipocalculo
                         FROM ECalFolhaPag fpa
                      WHERE FPA.CdFolhaPagamento = PKGPAG_VAR.vgCdFolha13Ant
                        AND FPA.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                      ) FPA
            ON FP.NuAnoReferencia = FPA.NuAnoReferencia AND
               FP.NuMesReferencia = FPA.NuMesReferencia AND
               FP.CdTipoFolhaPagamento = FPA.CdTipoFolhaPagamento AND
               FP.CdTipoCalculo = FPA.CdTipoCalculo
         WHERE HRV.CdVinculo = pCdVinculo AND
               FP.FlCalculoDefinitivo = 'S' AND
               ROWNUM < 2;

          RETURN 0;

        EXCEPTION

          WHEN no_data_found THEN

            RETURN 1;

        END;

      ELSE

        RETURN 1;

      END IF;

    ELSE

      RETURN 1;

    END IF;

  END;

  FUNCTION fmneqtdiasafastmaternidade(pfolha           IN pkgpag_tipo.rfolha,
                                      pcdvinculo       IN INTEGER,
                                      pdtiniciorelacao IN DATE,
                                      pdtfimrelacao    IN DATE,
                                      pdtcalculo       IN DATE)

   RETURN INTEGER IS

    vdtinicioano DATE;

    vdtfimano DATE;

    vnudias INTEGER;

  BEGIN
 
    vdtinicioano := trunc(to_date(pfolha.nuanoreferencia, 'YYYY'), 'YYYY');

    IF pdtiniciorelacao > vdtinicioano THEN

      vdtinicioano := pdtiniciorelacao;

    END IF;

    vdtfimano := trunc(to_date(pfolha.nuanoreferencia + 1, 'YYYY'), 'YYYY') - 1;

    IF pdtfimrelacao < vdtfimano THEN

      vdtfimano := pdtfimrelacao;

    END IF;

    SELECT SUM(nudiasafast)
      INTO vnudias
      FROM (SELECT mes, nvl(SUM(diaafastado), 0) AS nudiasafast
             FROM
               ( SELECT CdVinculo, TO_CHAR(dtDia, 'YYYYMM') AS Mes,
                        dtDia AS DtDiaAfastado, 1 AS DiaAfastado
                      FROM (SELECT vdtinicioano + (LEVEL - 1) AS dtdia
                              FROM dual
                        CONNECT BY vDtInicioAno + (LEVEL - 1)
                        BETWEEN vDtInicioAno AND vdtFimAno) D
                     INNER JOIN (SELECT cdvinculo,
                                       CASE
                                         WHEN av.dtinicio < vdtinicioano THEN
                                          vdtinicioano
                                         ELSE
                                          av.dtinicio
                                       END AS dtinicio,
                                       CASE
                                       WHEN (AV.dtFim > vdtFimAno OR AV.DtFim IS NULL) THEN
                                          vdtfimano
                                         ELSE
                                          av.dtfim
                                       END AS dtfim
                                  FROM eafaafastamentovinculo av
                                 INNER JOIN eafamotivoafasttemporario mat
                                  ON AV.CdMotivoAfastTemporario = MAT.CdMotivoAfastTemporario
                                 INNER JOIN eafahistmotivoafasttemp hmat
                                  ON MAT.CdMotivoAfastTemporario = HMAT.CdMotivoAfastTemporario
                              WHERE  AV.CdVinculo = pCdVinculo AND
                                    HMAT.FlGravidez = 'S' AND
                                    AV.DtInicio <= vdtFimAno AND
                                    (AV.DtFim >= vDtInicioAno OR AV.DtFim IS NULL) AND
                                    HMAT.DtInicioVigencia <= pDtCalculo AND
                                    (HMAT.DtFimVigencia >= pDtCalculo OR HMAT.DtFimVigencia IS NULL) AND
                                    HMAT.FlAnulado = 'N' AND AV.FlAnulado = 'N') B
                       ON (B.DtInicio <= D.DtDia) AND (B.DtFim >= D.DtDia)) A
             GROUP BY mes) z;

    RETURN least(vnudias, 120);

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  --
  -- Retornar numero de dias afastados no mes pelos motivos de afastamento
  -- exigidos para a geracao da rubrica
  --
  FUNCTION fmneqtdiasafastacidente(pfolha        IN pkgpag_tipo.rfolha,
                                   pcdvinculo    IN INTEGER,
                                   prubrica      IN pkgpag_tipo.rRubrica,
                                   pdtfimrelacao IN DATE,
                                   pdtcalculo    IN DATE)

   RETURN INTEGER IS

    vnudias INTEGER;

  BEGIN
 
    vNuDias := 0;

    IF pRubrica.lsMotAfastTempEx.COUNT > 0
      THEN
       FOR i IN pRubrica.lsMotAfastTempEx.FIRST .. pRubrica.lsMotAfastTempEx.LAST
         LOOP

        vNuDias := vNuDias +
                   PKGPAG_GERAL.fdiasafasttemp(pcdvinculo,
                                               pFolha.DtInicioMes,
                                               pFolha.DtFimMes,
                                               pFolha.DtCalculo,
                                               pRubrica.lsMotAfastTempEx(i).CdmotivoAfastTemporario);
      END LOOP;

      IF vNuDias > 30
        THEN
        vNuDias := 30;
      END IF;

      RETURN vNuDias;

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  --
  -- Retornar numero de dias afastados no mes pelos motivos de afastamento
  -- remunerados impeditivos para a geracao da rubrica
  --
  FUNCTION fmneqtdiasremimpeditivos(pfolha        IN pkgpag_tipo.rfolha,
                                    pcdvinculo    IN INTEGER,
                                    prubrica      IN pkgpag_tipo.rRubrica,
                                    pdtfimrelacao IN DATE,
                                    pdtcalculo    IN DATE)

   RETURN INTEGER IS

    vnudias INTEGER;

    vCodigo integer;

    vListaCodigo pkgpag_tipo.tLista;

  BEGIN
 
    vNuDias := 0;

    if PKGPAG_VAR.vgAfastTempRemun.count > 0 then

      for s in (select imp.cdmotivoafasttemporario
                  from EPAGRUBAGRUPMOTAFASTTEMPIMP imp
                 where imp.cdhistrubricaagrupamento = pRubrica.CdHistRubrica)

       loop

        FOR j IN PKGPAG_VAR.vgAfastTempRemun.FIRST .. PKGPAG_VAR.vgAfastTempRemun.LAST

         LOOP

           IF PKGPAG_VAR.vgAfastTempRemun(j).CdMotivoAfastamento = s.cdmotivoafasttemporario then -- pRubrica.lsMotAfastTempImp(i).cdmotivoafasttemporario then

             vNuDias := vNuDias + PKGPAG_VAR.vgAfastTempRemun(j).NuDiasAfastMes;
            
             IF PKGPAG_VAR.vgAfastTempRemun(j).FlUltimoDiaMes = 'S' AND pFolha.nuMesReferencia = 2 THEN
              
               IF TO_CHAR(pFolha.DtFimMes,'DD') = 28 THEN
                
                 vNuDias := vNuDias + 2;
                 
               ELSE
                
                 vNuDias := vNuDias + 1;
                 
               END IF;
               
            END IF;

          end if;

        END LOOP;


      END LOOP;

      IF vNuDias > 30
        THEN
        vNuDias := 30;
      END IF;

      RETURN vNuDias;

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  --
  -- Retornar numero de dias afastados no mes pelos motivos de afastamento
  -- remunerados impeditivos para a geracao da rubrica, somente dias uteis
  --
  FUNCTION fmneqtdiasremimpeditivosuteis(pfolha        IN pkgpag_tipo.rfolha,
                                         pcdvinculo    IN INTEGER,
                                         prubrica      IN pkgpag_tipo.rRubrica,
                                         pdtfimrelacao IN DATE,
                                         pdtcalculo    IN DATE)

   RETURN INTEGER IS

    vnudiasdireito INTEGER;

    vnudias INTEGER;

    vCodigo integer;

    vListaCodigo pkgpag_tipo.tLista;

  BEGIN
 
    vNuDias := 0;

    -- Desligados no mes
    if pdtfimrelacao < pFolha.DtFimMes then

       vNudias :=  fQtTipoDiasPeriodo(P_DATA_INICIAL => pDtFimRelacao+1,
                                      P_DATA_FINAL => pFolha.DtFimMes,
                                      p_tipo_retorno => 1);
    end if;

    -- Admitidos no mes
    if PKGPAG_VAR.vgvinculo.dtadmissao > pFolha.DtInicioMes then

       vNuDias := nvl(vNuDias,0) + fQtTipoDiasPeriodo(P_DATA_INICIAL => pFolha.DtInicioMes,
                                                      P_DATA_FINAL => PKGPAG_VAR.vgvinculo.dtadmissao-1,
                                                      p_tipo_retorno => 1);

    end if;

    if PKGPAG_VAR.vgAfastTempRemun.count > 0 then

      for s in (select imp.cdmotivoafasttemporario
                  from EPAGRUBAGRUPMOTAFASTTEMPIMP imp
                 where imp.cdhistrubricaagrupamento = pRubrica.CdHistRubrica)

       loop

        begin

        FOR j IN PKGPAG_VAR.vgAfastTempRemun.FIRST .. PKGPAG_VAR.vgAfastTempRemun.LAST

         LOOP

             if PKGPAG_VAR.vgAfastTempRemun(j).CdMotivoAfastamento = s.cdmotivoafasttemporario then -- pRubrica.lsMotAfastTempImp(i).cdmotivoafasttemporario then

               -- Dias uteis do periodo de afastamento
               vNuDias := vNuDias + fQtTipoDiasPeriodo(P_DATA_INICIAL => PKGPAG_VAR.vgAfastTempRemun(j).DtInicioAfaNoMes,
                                                       P_DATA_FINAL => PKGPAG_VAR.vgAfastTempRemun(j).DtFimAfaNoMes,
                                                       p_tipo_retorno => 1);
            end if;

        end loop;

        exception
          when others
            then null;

        end;

      END LOOP;

      IF vNuDias > 30
        THEN
        vNuDias := 30;
      END IF;

      RETURN vNuDias;

    ELSE
 
       IF pfolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaBolsista 
        AND pfolha.CdAgrupamento = 176 then
     
         RETURN vNuDias + nvl(PKGPAG_VAR.vgIndiceFaltasMesAtual,0);
    
       ELSE
    
         RETURN vNuDias;
    
       END IF; 
     
    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  --
  -- Retornar numero de dias afastados no mes pelos motivos de afastamento
  -- remunerados impeditivos para a geracao da rubrica, somente dias uteis
  -- referente a meses anteriores e lancados apos o calculo definitivo anterior
  FUNCTION fmneqtdiasremimpedsuteisret(pfolha        IN pkgpag_tipo.rfolha,
                                       pcdvinculo    IN INTEGER,
                                       prubrica      IN pkgpag_tipo.rRubrica,
                                       pdtfimrelacao IN DATE,
                                       pdtcalculo    IN DATE)

   RETURN INTEGER IS

    vnudias INTEGER;

    vCodigo integer;

    vListaCodigo pkgpag_tipo.tLista;

  BEGIN
 
    vNuDias := 0;

    if PKGPAG_VAR.vgAfastTempRemunMesAnt.count > 0 then

      for s in (select imp.cdmotivoafasttemporario
                  from EPAGRUBAGRUPMOTAFASTTEMPIMP imp
                 where imp.cdhistrubricaagrupamento = pRubrica.CdHistRubrica)

       loop


        begin

        FOR j IN PKGPAG_VAR.vgAfastTempRemunMesAnt.FIRST .. PKGPAG_VAR.vgAfastTempRemunMesAnt.LAST

         LOOP

             if PKGPAG_VAR.vgAfastTempRemunMesAnt(j).CdMotivoAfastamento = s.cdmotivoafasttemporario
                and PKGPAG_VAR.vgAfastTempRemunMesAnt(j).DtInclusao BETWEEN (trunc(PKGPAG_VAR.vDtCalculoAnt) + 1) AND trunc(pDtCalculo)
                then
               -- Dias uteis do periodo de afastamento
               vNuDias := vNuDias + fQtTipoDiasPeriodo(P_DATA_INICIAL => PKGPAG_VAR.vgAfastTempRemunMesAnt(j).DtInicioAfa,
                                                       P_DATA_FINAL => least(PKGPAG_VAR.vgAfastTempRemunMesAnt(j).DtFimAfa,pFolha.DtInicioMes-1),
                                                       p_tipo_retorno => 1);
          end if;

        end loop;

        exception
          when others
            then null;

        end;

      END LOOP;

      IF vNuDias > 30
        THEN
        vNuDias := 30;
      END IF;

      RETURN vNuDias;

    ELSE

      RETURN 0;

    END IF;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*----------------------------------------------------------------------------
   Funcao: FMneFaltasPerApu
   Objetivo: Retorna a apura??o de faltas no per?odo.

   Alterado em 11/02/2015. Retornava a vari?vel vgIndiceFaltas que a partir do m?s
   de setembro/2014 em consequencia de altera??o na PKGPAG_CAL deixou de receber
   valores.
  /-----------------------------------------------------------------------------*/
  FUNCTION fmnefaltasperapu

   RETURN NUMBER IS

  BEGIN
 
    RETURN nvl(PKGPAG_VAR.vgindicefaltasmesanterior, 0);

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*-----------------------------------------------------------------------------------------
  --
  -- Para a verifica??o da quantidade de dias ?teis afastados, o m?todo considera a data de
  -- inclus?o: Se o afastamento foi lan?ado antes da data do ?ltimo c?lculo
  --
  --
  /*------------------------------------------------------------------------------------------*/
  FUNCTION fmneaftemp(pfolha            IN pkgpag_tipo.rfolha,
                      pcdvinculo        IN INTEGER,
                      pnutipodianaoutil IN INTEGER DEFAULT 0)

   RETURN INTEGER IS

    vdiasafast INTEGER;

    bprimeiro BOOLEAN;

    vdtinicio DATE;

    vdtfim DATE;

    vdtminafastamento DATE;

    vdtmaxafastamento DATE;

    vdtatual DATE;

    cdiasafast types.ref_cursor;

  BEGIN
 
    vdiasafast := 0;

    bprimeiro := TRUE;

    /* Seleciona a menor data inicio e a maior data fim dos
    afastamentos inclu?dos entre o c?culo anterior e atual*/

   SELECT MIN(AV.DtInicio),
          MAX(Av.Dtfim)
     INTO vDtMINAfastamento,
          vDtMAXAfastamento
      FROM eafaafastamentovinculo av
    WHERE Av.CdVinculo = pCdVinculo AND
          Av.CdMotivoAfastTemporario IS NOT NULL AND
          (TRUNC(Av.DtInclusao) BETWEEN PKGPAG_VAR.vDtCalculoAnt + 1 AND PKGPAG_VAR.vDtCalculo) AND
          Av.DtInicio <= pFolha.DtFimMes;

    /* Caso sejam encontrados afastamentos no SQL anterior */

    IF vdtminafastamento IS NOT NULL THEN

      IF vdtfim > pfolha.dtfimmes THEN

        vdtfim := pfolha.dtfimmes;

      END IF;

      /*Retornam os dias afastados cuja data de inclus?o est?
      entre a data de calculo da folha anterior e a atual*/

      OPEN cDiasAfast FOR SELECT DISTINCT DtDia
          FROM (SELECT vdtminafastamento + (LEVEL - 1) AS dtdia
                  FROM dual
             CONNECT BY vDtMINAfastamento + (LEVEL - 1)
             BETWEEN vDtMINAfastamento AND vDtMAXAfastamento) D
         INNER JOIN (SELECT av.dtinicio AS dtinicio,
                            CASE
                            WHEN Av.DtFim IS NULL OR Av.DtFim > pFolha.DtFimMes THEN
                               pfolha.dtfimmes
                              ELSE
                               av.dtfim
                            END AS dtfim
                       FROM eafaafastamentovinculo av
                   WHERE Av.CdVinculo = pCdVinculo AND
                         Av.CdMotivoafastTemporario IS NOT NULL AND
                         (TRUNC(Av.DtInclusao) BETWEEN PKGPAG_VAR.vDtCalculoAnt AND PKGPAG_VAR.vDtCalculo) AND
                         Av.DtInicio <= pFolha.DtFimMes AND
                         Av.FlAnulado = PKGPAG_TIPO.cnN ORDER BY AV.DtInicio) A
                      ON D.DtDia >= A.DtInicio AND D.DtDia <= A.dtFim
        UNION
        SELECT DISTINCT dtdia
          FROM (SELECT pfolha.dtiniciomes + (LEVEL - 1) AS dtdia
                  FROM dual
             CONNECT BY pFolha.DtInicioMes + (LEVEL - 1)
             BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) D
          INNER JOIN (SELECT
                        CASE
                              WHEN av.dtinicio < pfolha.dtiniciomes THEN
                               pfolha.dtiniciomes
                              ELSE
                               av.dtinicio
                            END AS dtinicio,
                            CASE
                          WHEN Av.DtFim IS NULL OR Av.DtFim > pFolha.DtFimMes THEN
                               pfolha.dtfimmes
                              ELSE
                               av.dtfim
                            END AS dtfim
                       FROM eafaafastamentovinculo av
                      WHERE Av.CdVinculo = pCdVinculo AND
                            Av.CdMotivoafastTemporario IS NOT NULL AND
                            Av.DtInclusao < PKGPAG_VAR.vDtCalculoAnt AND
                           (Av.DtInicio <= pFolha.DtFimMes AND (Av.dtfim >= pFolha.DtInicioMes OR Av.dtfim IS NULL))
                        AND av.flanulado = pkgpag_tipo.cnn) a
          ON D.DtDia >= A.dtInicio AND D.DtDia <= A.dtFim
         ORDER BY dtdia;

    ELSE

      /*Cursor que retornam os dias afastados cuja data de inclus?o ?
      anteriror ? data de calculo da folha anterior */

      OPEN cdiasafast FOR
        SELECT DISTINCT dtdia
           FROM
           (SELECT pFolha.DtInicioMes + (LEVEL - 1) AS dtDia
                  FROM dual
           CONNECT BY pFolha.DtInicioMes + (LEVEL - 1)
           BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) D
         INNER JOIN (SELECT
                       CASE
                              WHEN av.dtinicio < pfolha.dtiniciomes THEN
                               pfolha.dtiniciomes
                              ELSE
                               av.dtinicio
                            END AS dtinicio,
                            CASE
                         WHEN Av.DtFim IS NULL OR Av.DtFim > pFolha.DtFimMes THEN
                               pfolha.dtfimmes
                              ELSE
                               av.dtfim
                            END AS dtfim
                       FROM eafaafastamentovinculo av
                     WHERE Av.CdVinculo = pCdVinculo AND
                           Av.CdMotivoAfastTemporario IS NOT NULL AND
                           TRUNC(AV.DtInclusao) < PKGPAG_VAR.vDtCalculoAnt AND
                           (Av.DtInicio <= pFolha.DtFimMes AND (Av.dtfim >= pFolha.DtInicioMes OR Av.dtfim IS NULL))
                        AND av.flanulado = pkgpag_tipo.cnn) a
                        ON D.DtDia >= A.dtInicio AND D.DtDia <= A.dtFim
         ORDER BY dtdia;

    END IF;

    -- Retornam os dias em que o servidor esteve afastado por motivo
    -- de afastamento tempor?rio.
    -- Varre os dias para encontrar os per?odos em que esteve afastado e
    -- submete ? fun??o PKGMOV.FQtDiasUteis

    LOOP

    FETCH cDiasAfast INTO vDtAtual;

      EXIT WHEN cdiasafast%NOTFOUND;

      IF bprimeiro THEN

        vdtinicio := vdtatual;

        vdtfim := vdtatual;

        bprimeiro := FALSE;

      ELSE

        IF (vdtatual > vdtfim + 1) THEN

        vDiasAfast := vDiasAfast + PKGMOV.FQtDiaUtil(pFolha.CdAgrupamento,
                                          pFolha.CdOrgao,
                                          NULL,
                                          vDtInicio,
                                          vDtFim,
                                                     pNuTipoDiaNaoUtil, 'N', PKGPAG_VAR.vgCalculo.flgeral);
          vdtinicio  := vdtatual;

          vdtfim := vdtatual;

        ELSE

          vdtfim := vdtatual;

        END IF;

      END IF;

    END LOOP;

    CLOSE cdiasafast;

    IF vdtinicio IS NOT NULL THEN

    vDiasAfast := vDiasAfast + PKGMOV.FQtDiaUtil(pFolha.CdAgrupamento,
                                      pFolha.CdOrgao,
                                      NULL,
                                      vDtInicio,
                                      vDtFim,
                                                 pnutipodianaoutil, 'N', PKGPAG_VAR.vgCalculo.flgeral);

    END IF;

    RETURN vdiasafast;

  END;

  /*-----------------------------------------------------------------------------------------
  --
  -- Para a verifica??o da quantidade de dias ?teis afastados, o m?todo considera a data de
  -- inclus?o: Se o afastamento foi lan?ado antes da data do ?ltimo c?lculo
  --
  --
  /*------------------------------------------------------------------------------------------*/
  FUNCTION fmneafdiascorridos(pfolha     IN pkgpag_tipo.rfolha,
                              pcdvinculo IN INTEGER)

   RETURN INTEGER IS

    vDtInicio  DATE;
    vDtFim     DATE;
    vnudias    INTEGER;
    vultimodia INTEGER;
    vsomadias  INTEGER;
    --cdiasafast types.ref_cursor;

    CURSOR CAfastamento IS
      SELECT av.dtinicio AS dtinicio,
             CASE
               WHEN av.dtfim IS NULL OR av.dtfim > pfolha.dtfimmes THEN
                pfolha.dtfimmes
               ELSE
                av.dtfim
             END AS dtfim
        FROM eafaafastamentovinculo av
       WHERE Av.CdVinculo = pCdVinculo
         AND Av.CdMotivoafastTemporario IS NOT NULL
         AND Av.Flremunerado = 'N'
         AND (Av.DtFim >= pFolha.DtInicioMes OR AV.DtFim IS NULL)
         and Av.DtInicio <= pFolha.DtFimMes
         AND Av.FlAnulado = 'N'
       ORDER BY AV.DtInicio;

    RAfastamento CAfastamento%ROWTYPE;
  BEGIN
 
    vnudias    := 0;
    vultimodia := 0;
    vsomadias  := 0;

    OPEN CAfastamento;
    LOOP
       fetch cAfastamento into rAfastamento;
      exit when cAfastamento%notfound;

      vDtInicio := rAfastamento.dtinicio;
      vDtFim    := rAfastamento.dtfim;

       SELECT COUNT(DtDia), sum (case when  vDtFim = pFolha.DtFimMes then 1 else 0 end)
        INTO vnudias, vultimodia
        FROM (SELECT pfolha.dtiniciomes + (LEVEL - 1) AS dtdia
                FROM dual
              CONNECT BY pFolha.DtInicioMes + (LEVEL - 1)
              BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) D
         WHERE D.DtDia >= vDtInicio AND D.DtDia <= vdtFim;

      -- Caso tem afastamento no ultimo dia e ser de mes de 31 dias desconsidera o dia 31 do afastamento
        IF NVL(vUltimoDia,0) > 0 and to_char(pFolha.DtFimMes,'DD') = 31
          THEN
        vnudias := vnudias - 1;
      END IF;
      -- Caso seja o mes de fevereiro
        IF pfolha.NuMesReferencia = 2 AND to_char(vDtFim,'DD') IN ('28', '29')
          THEN
             IF to_char(pFolha.DtFimMes,'DD') = '29'
              THEN
          vnudias := vnudias + 1;
              ELSIF to_char(pFolha.DtFimMes,'DD') = '28'
              THEN
          vnudias := vnudias + 2;
        else
          null;
        END IF;
      END IF;

      vsomadias := vsomadias + vnudias;
    END LOOP;
    RETURN vsomadias;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  FUNCTION fmnediasvt(pfolha     IN pkgpag_tipo.rfolha,
                      pcdvinculo IN INTEGER,
                      pdtinicio  IN DATE,
                      pdtfim     IN DATE)

   RETURN INTEGER IS

    vnudiasafastatual INTEGER;

    vnudiasafastretro INTEGER;

    vqtvales INTEGER;

  BEGIN
 
    vnudiasafastatual := 0;

    vnudiasafastretro := 0;

    vqtvales := greatest(to_number(to_char(pdtfim, 'DD')), 30);

    IF pdtfim < last_day(pdtinicio) THEN

      vqtvales := pdtfim - pdtinicio + 1;

    ELSIF pdtinicio > pfolha.dtiniciomes THEN

      vqtvales := vqtvales - to_number(to_char(pdtinicio, 'DD')) + 1;

    else
      null;
    END IF;

    pkgafa.pcalculardiasevento(pcdvinculo               => pcdvinculo,
                               pcdestruturacarreira     => NULL,
                               pdtinicio                => PKGPAG_VAR.vdtcalculoant + 1,
                               pdtfim                   => CASE
                                            WHEN pdtfim < pfolha.dtcalculo THEN
                                                              pfolha.dtcalculo
                                                             ELSE
                                                              pdtfim
                                                           END,
                               pCdEventoAfastamento     => 12,
                               pcdagrupamento           => pfolha.cdagrupamento,
                               pflverificaperiodopa     => 'S',
                               pcdorgao                 => pfolha.cdorgao,
                               pcdunidadeorganizacional => NULL,
                               pnutipodianaoutil        => NULL,
                               pflconsideradatainclusao => pkgpag_tipo.cns,
                               pdtreferencia            => PKGPAG_VAR.vdtcalculo,
                               pdtinilimite             => add_months(pfolha.dtiniciomes,
                               - 1 * PKGMOVFRE.cn_Qt_Mes_Retro_Falta),
                               pFlCalculoGeral          => PKGPAG_VAR.vgCalculo.flgeral);

    vnudiasafastatual := pkgafa.fqtdiasatual;
    vnudiasafastretro := pkgafa.fqtdiasretroativo;

   RETURN CASE
            WHEN (vQtVales - NVL(vNuDiasAfastAtual,0) + NVL(vNuDiasAfastRetro,0)) < 0 THEN
              0
          ELSE
            (vQtVales - (NVL(vNuDiasAfastAtual,0) + NVL(vNuDiasAfastRetro,0)))
          END ;

  END;

  /*---------------------------------------------------------------------------------------------*/
  -- Executa a proporcionalidade de acordo com a rela??o de v?nculo para
  -- pagamentos de vantagens pecuni?rias e eventos que podem estar associados a
  -- uma base de c?lculo
  /*---------------------------------------------------------------------------------------------*/
  PROCEDURE pexecutaproporcionalidade(pfolha         IN pkgpag_tipo.rfolha,
                                      ppagcalc       IN pkgpag_tipo.rpagcalc,
                                      pvalorintegral IN NUMBER,
                                      pindiceespec   IN NUMBER) IS

    vproporcional pkgpag_tipo.rvalorpagamento;

    vvalorintegral NUMBER;

    PROCEDURE patualizavalor(pcdfolhapagamento IN INTEGER,
                             pcdvinculo        IN INTEGER,
                             pcdrelacaovinculo IN INTEGER,
                             pcdhistrelvinc    IN INTEGER,
                             pcdrubrica        IN INTEGER,
                             pvlintegral       IN NUMBER,
                             pvlproporcional   IN NUMBER,
                             pvlreal           IN NUMBER,
                             pvlindice         IN NUMBER) IS

    BEGIN
 
      CASE pcdrelacaovinculo

        WHEN 1 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
               HRV.CdHistCargoEfetivo   = pCdHistRelVinc;

        WHEN 2 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
               HRV.CdHistCargoCom       = pCdHistRelVinc;

        WHEN 3 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
               HRV.CdHistFuncaoChefia   = pCdHistRelVinc;

        WHEN 4 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
               HRV.CdConcessaoAposentadoria = pCdHistRelVinc;

        WHEN 5 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
               HRV.CdHistEstagio = pCdHistRelVinc;

        WHEN 6 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
              HRV.CdHistPensaoPrevidenciaria = pCdHistRelVinc;

        WHEN 7 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
               HRV.CdHistPensaoNaoPrev =  pCdHistRelVinc;

        WHEN 8 THEN
          UPDATE epaghistoricorubricarelvinc hrv
             SET vlintegral      = pvlintegral,
                 vlproporcional  = pvlproporcional,
                 vlreal          = pvlreal,
                 vlindicerubrica = pvlindice
         WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
               HRV.CdVinculo            = pCdVinculo AND
               HRV.CdRubricaAgrupamento = pCdRubrica AND
               HRV.CdHistPensaoExParlamentar = pCdHistRelVinc;

      /*
                                                                  WHEN 9 THEN
                                                                    UPDATE epagHistoricoRubricaRelVinc HRV
                                                                       SET vlIntegral      = pvlIntegral,
                                                                           vlProporcional  = pvlProporcional,
                                                                           vlReal          = pvlReal,
                                                                           vlIndiceRubrica = pvlIndice
                                                                     WHERE HRV.CdFolhaPagamento     = pCdFolhaPagamento AND
                                                                           HRV.CdVinculo            = pCdVinculo AND
                                                                           HRV.CdRubricaAgrupamento = pCdRubrica AND
                                                                           HRV.CdAuxilioReclusao    = pCdHistRelVinc;
                                                            */

        ELSE

          NULL;

      END CASE;

    END;

  BEGIN
 
    vvalorintegral := pvalorintegral;

    CASE ppagcalc.cdrelacaovinculo

      WHEN 1 THEN

        IF PKGPAG_VAR.vgcef.count > 0 THEN

       FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
       LOOP

         IF PKGPAG_VAR.vgCEF(i).CdHistRelVinc = pPagCalc.CdHistCargoEfetivo THEN

           vProporcional :=

             PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                      prubrica       => PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento),
                                                                      pvalorintegral => vvalorintegral,
                                                                      pnucho         => PKGPAG_VAR.vgvalorfixocef.nucargahoraria,
                                                                      pcef           => PKGPAG_VAR.vgcef(i),
                                                                      pdtcalculo     => PKGPAG_VAR.vdtcalculo);

              PAtualizaValor(pFolha.CdFolhaPagamento,
                             pPagCalc.CdVinculo,
                             ppagcalc.cdrelacaovinculo,
                             ppagcalc.cdhistcargoefetivo,
                             ppagcalc.cdrubricaagrupamento,
                             vproporcional.vlintegral,
                             vproporcional.vlproporcional,
                             vproporcional.vlreal,
                             CASE WHEN pindiceespec IS NULL THEN
                            vProporcional.vlIndice
                          ELSE
                            pIndiceEspec
                          END);

            END IF;

          END LOOP;

        END IF;

      WHEN 2 THEN

        IF PKGPAG_VAR.vgcco.count > 0 THEN

       FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST
       LOOP

            IF PKGPAG_VAR.vgcco(i).cdhistcargocom = ppagcalc.cdhistcargocom THEN

           vProporcional :=

             PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                      prubrica       => PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento),
                                                                      pvalorintegral => vvalorintegral,
                                                                      pcco           => PKGPAG_VAR.vgcco(i),
                                                                      pdtcalculo     => PKGPAG_VAR.vdtcalculo);

              PAtualizaValor(pFolha.CdFolhaPagamento,
                             pPagCalc.CdVinculo,
                             ppagcalc.cdrelacaovinculo,
                             ppagcalc.cdhistcargocom,
                             ppagcalc.cdrubricaagrupamento,
                             vproporcional.vlintegral,
                             vproporcional.vlproporcional,
                             vproporcional.vlreal,
                             CASE WHEN pindiceespec IS NULL THEN
                            vProporcional.vlIndice
                          ELSE
                            pIndiceEspec
                          END);

            END IF;

          END LOOP;

        END IF;

      WHEN 4 THEN

        IF PKGPAG_VAR.vgapo.count > 0 THEN

       FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
       LOOP

            vvalorintegral := pvalorintegral;

         IF PKGPAG_VAR.vgAPO(i).CdHistRelVinc = pPagCalc.CdConcessaoAposentadoria THEN

           vProporcional :=

             PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                      prubrica       => PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento),
                                                                      pvalorintegral => vvalorintegral,
                                                                      papo           => PKGPAG_VAR.vgapo(i),
                                                                      pdtcalculo     => PKGPAG_VAR.vdtcalculo);

              PAtualizaValor(pFolha.CdFolhaPagamento,
                             pPagCalc.CdVinculo,
                             ppagcalc.cdrelacaovinculo,
                             ppagcalc.cdconcessaoaposentadoria,
                             ppagcalc.cdrubricaagrupamento,
                             vproporcional.vlintegral,
                             vproporcional.vlproporcional,
                             vproporcional.vlreal,
                             CASE WHEN pindiceespec IS NULL THEN
                            vProporcional.vlIndice
                          ELSE
                            pIndiceEspec
                          END);
            END IF;

          END LOOP;

        END IF;

      WHEN 7 THEN

        IF PKGPAG_VAR.vgpensaonaoprev.count > 0 THEN

       FOR i IN PKGPAG_VAR.vgPensaoNaoPrev.FIRST .. PKGPAG_VAR.vgPensaoNaoPrev.LAST
       LOOP

            vvalorintegral := pvalorintegral;

         IF PKGPAG_VAR.vgPensaoNaoPrev(i).CdHistPensaoNaoPrev = pPagCalc.CdHistPensaoNaoPrev THEN

           vProporcional :=

             PKGPAG_GERAL.FCalculaProporcionalidade(pFolha         => pFolha,
                                                                      prubrica       => PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento),
                                                                      pvalorintegral => vvalorintegral,
                                                                      ppnp           => PKGPAG_VAR.vgpensaonaoprev(i),
                                                                      pdtcalculo     => PKGPAG_VAR.vdtcalculo);

              PAtualizaValor(pFolha.CdFolhaPagamento,
                             pPagCalc.CdVinculo,
                             ppagcalc.cdrelacaovinculo,
                             ppagcalc.cdhistpensaonaoprev,
                             ppagcalc.cdrubricaagrupamento,
                             vproporcional.vlintegral,
                             vproporcional.vlproporcional,
                             vproporcional.vlreal,
                             CASE WHEN pindiceespec IS NULL THEN
                            vProporcional.vlIndice
                          ELSE
                            pIndiceEspec
                          END);
            END IF;

          END LOOP;

        END IF;

    END CASE;

  END;

  /*---------------------------------------------------------------------------------------------*/
  -- Retorna o valor integral no registro que possui a rubrica totalizadora
  /*---------------------------------------------------------------------------------------------*/

  FUNCTION fretornavalorrubtot(pcdfolhapagamento IN INTEGER,
                               ppagcalc          IN pkgpag_tipo.rpagcalc,
                               ptpvalor          IN CHAR DEFAULT 'I',
                               pinrelacaorubrica IN CHAR DEFAULT 'R') -- R(ela??o) ou S(oma)

   RETURN NUMBER IS

    vvlintegral    NUMBER(13, 2);
    vsql           VARCHAR2(2000);
    vcdhistrelvinc INTEGER;

  BEGIN
 
    IF pinrelacaorubrica = 'R' THEN

      IF ptpvalor = 'I' THEN

        vsql := 'SELECT vlIntegral ';

      ELSIF ptpvalor = 'P' THEN

        vsql := 'SELECT vlProporcional ';

      ELSE

        vsql := 'SELECT vlReal ';

      END IF;

    vSQL := vSQL ||
            '  FROM EPagHistoricoRubricaRelVinc HRV ' ||
              ' WHERE HRV.CdVinculo = :pCdVinculo AND ' ||
              '       HRV.CdFolhaPagamento = :pCdFolhaPagamento AND ' ||
              '       HRV.CdRubricaAgrupamento = :pCdRubTotalizadora AND ';

      CASE ppagcalc.cdrelacaovinculo

        WHEN 1 THEN

          vsql := vsql || 'HRV.CdHistCargoEfetivo = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdhistcargoefetivo;

        WHEN 2 THEN

          vsql := vsql || 'HRV.CdHistCargoCom  = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdhistcargocom;

        WHEN 3 THEN

          vsql := vsql || 'HRV.CdHistFuncaoChefia  = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdhistfuncaochefia;

        WHEN 4 THEN

          vsql := vsql || 'HRV.CdConcessaoAposentadoria = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdconcessaoaposentadoria;

        WHEN 5 THEN

          vsql := vsql || 'HRV.CdHistEstagio = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdhistestagio;

        WHEN 6 THEN

        vSQL := vSQL || 'HRV.CdHistPensaoPrevidenciaria = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdhistpensaoprevidenciaria;

        WHEN 7 THEN

          vsql := vsql || 'HRV.CdHistPensaoNaoPrev = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdhistpensaonaoprev;

        WHEN 8 THEN

          vsql := vsql || 'HRV.CdHistPensaoExParlamentar = :pCdHistRelVinc';

          vcdhistrelvinc := ppagcalc.cdhistpensaoexparlamentar;

        ELSE

          vsql := vsql || 'HRV.CdHistAuxilioReclusao = :pCdHistRelVInc';

          vcdhistrelvinc := ppagcalc.cdhistauxilioreclusao;

      END CASE;

      EXECUTE IMMEDIATE vsql
        INTO vvlintegral
      USING pPagCalc.CdVinculo,
            pCdFolhaPagamento,
            pPagCalc.CdRubricaTotalizadoraVantagem,
            vCdHistRelVinc;

    ELSE

      IF ptpvalor = 'I' THEN

        vsql := 'SELECT SUM(vlIntegral) ';

      ELSIF ptpvalor = 'P' THEN

        vsql := 'SELECT SUM(vlProporcional) ';

      ELSE

        vsql := 'SELECT SUM(vlReal) ';

      END IF;

    vSQL := vSQL ||
            '  FROM EPagHistoricoRubricaRelVinc HRV ' ||
              '  WHERE HRV.CdVinculo = :pCdVinculo AND ' ||
              '       HRV.CdFolhaPagamento = :pCdFolhaPagamento AND ' ||
              '       HRV.CdRubricaAgrupamento = :pCdRubTotalizadora ';

      EXECUTE IMMEDIATE vsql
        INTO vvlintegral
      USING pPagCalc.CdVinculo,
            pCdFolhaPagamento,
            pPagCalc.CdRubricaTotalizadoraVantagem;

    END IF;

    RETURN vvlintegral;

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*-----------------------------------------------------------------------------------------------*/

  /*-----------------------------------------------------------------------------------------------*/

  FUNCTION fretornadescontos(pcdfolhapagamento IN INTEGER,
                             pcdvinculo        IN INTEGER,
                             pcdbasecalculo    IN INTEGER) RETURN NUMBER IS

    vlista VARCHAR2(400);

    vvldesconto NUMBER(13, 2);

    vbasecalculo pkgpag_tipo.rbasecalculo;

  BEGIN
 
    IF NOT PKGPAG_VAR.vgbaseexpr.exists(pcdbasecalculo) THEN
      RETURN 0;
    END IF;

    vbasecalculo := PKGPAG_VAR.vgbaseexpr(pcdbasecalculo);

    vlista := '';

    IF vbasecalculo.lbloco.count > 0 THEN

     FOR i IN vBaseCalculo.lBloco.First .. vBaseCalculo.lBloco.LAST
     LOOP

        IF vbasecalculo.lbloco(i).lexpressao.count > 0 THEN

         FOR j IN vBaseCalculo.lBloco(i).lExpressao.FIRST ..  vBaseCalculo.lBloco(i).lExpressao.LAST
         LOOP

            IF vbasecalculo.lbloco(i).lexpressao(j).cdtipomneumonico = 4 THEN

              vLista := vLista || vBaseCalculo.lBloco(i).lExpressao(j).CdExpressao || ',';

            END IF;

          END LOOP;

        END IF;

      END LOOP;

    END IF;

    IF length(vlista) > 0 THEN

      vlista := substr(vlista, 1, length(vlista) - 1);

      SELECT SUM(vlpagamento)
        INTO vvldesconto
        FROM epaghistoricorubricavinculo hrv
       INNER JOIN epagrubricaagrupamento ra
          ON ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
       INNER JOIN epagrubrica r
          ON r.cdrubrica = ra.cdrubrica
       INNER JOIN epagbasecalcblocoexprrubagrup br
          ON br.cdrubricaagrupamento = ra.cdrubricaagrupamento
      WHERE R.CdTipoRubrica =  8 AND
            HRV.CdFolhaPagamento = pCdFolhaPagamento AND
            HRV.CdVinculo = pCdVinculo AND
            BR.CdBaseCalculoBlocoExpressao IN (SELECT to_number(column_value) FROM TABLE(FSPLIT(vLista)));

    END IF;

    RETURN nvl(vvldesconto, 0);

  EXCEPTION

    WHEN OTHERS THEN

      RETURN 0;

  END;

  /*-----------------------------------------------------------------------------------------*/
  -- Procedure criada para atualizar o valor da base de c?lculo, descontando rubricas do tipo
  -- 8 que foram calculadas posteriormente.
  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE patualizabasecalculo(pcdvinculo        IN INTEGER,
                                 pcdfolhapagamento IN INTEGER,
                                 pcdrubrica        IN INTEGER) IS

    vvldesconto NUMBER(13, 2);

    vvlnovabase NUMBER(13, 2);

    vcdbasecalculo INTEGER;

  BEGIN
 
    vcdbasecalculo := PKGPAG_VAR.vgrubrica(pcdrubrica).cdbasecalculo;

    vvldesconto := fretornadescontos(pcdfolhapagamento => pcdfolhapagamento,
                                     pcdvinculo        => pcdvinculo,
                                     pcdbasecalculo    => vcdbasecalculo);

    vvlnovabase := PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => pcdfolhapagamento,
                                                     pcdvinculo        => pcdvinculo,
                                                   pCdRubrica         => pCdRubrica)
                                        - vVlDesconto;

    IF vvldesconto > 0 THEN

      UPDATE epaghistoricorubricavinculo hrv
         SET hrv.vlpagamento = greatest(vvlnovabase, 0)
      WHERE HRV.CdFolhaPagamento = pCdFolhaPagamento AND
            HRV.CdVinculo = pCdVinculo AND
            HRV.CdRubricaAgrupamento = pCdRubrica;

    END IF;

    IF pcdrubrica = PKGPAG_VAR.vgcdrubricabaseplanosaude THEN

      PKGPAG_VAR.vgvalorbaseplanosaude := vvlnovabase;

    END IF;

  END;

  /*---------------------------------------------------------------------------------------------*/
  --  Procedimento : ProcessaVantagemBase
  --      Objetivo : Processar as vantagens pecuni?rias cujo valor depende do valor depende
  --
  --   Regras implementadas:
  --     07) Valor gerado pelas regras de neg?cio de um tipo de evento;
  --           Sal?rio Fam?lia
  --     09) Valor depende da faixa de enquadramento de uma base de c?lculo
  --           Abono
  /*---------------------------------------------------------------------------------------------*/

  PROCEDURE pprocvantagembase(pfolha   IN pkgpag_tipo.rfolha,
                              ppagcalc IN pkgpag_tipo.rpagcalc) IS

    vvlproporcional NUMBER(13, 2);

    vnuvalorfixovantagem NUMBER(13, 2);

    vvlsalariofamilia NUMBER(13, 2);

    vvlindice INTEGER;

    vnudiasprop INTEGER := 30;

    vVlBaseSalFamOutroVinc NUMBER(13, 2);

  BEGIN
 
    /*---------------------------------------------------------------------------------------------*/
    -- Abono
    /*---------------------------------------------------------------------------------------------*/
    IF PKGPAG_VAR.vgVantagem(pPagCalc.CdVantagemPecuniaria).CdFormaPagVantPecuniaria = 9 THEN

      BEGIN

        /*Seleciona o valor proporcional do registro associado ?
        rubrica totalizadora */

        -- Passar parametro para valor proporcional se for referente a op??es de remunera??o
        -- exclusivas pelo cargo comissionado para que considere somente o valor proporcional
        -- chamado 6985/2015
        --
        IF PKGPAG_VAR.vgCCo.Count > 0 AND PKGPAG_VAR.vgCCO(1).CdOpcaoRemuneracao in (3,6)
         THEN

          --
          -- 10150/2017 - PAGAMENTO DO ABONO 01-0087 - Pagamento indevido
          -- Correcao para quem teve afastamento sem remuneracao retornar o valor real da base
          --
          IF PKGPAG_VAR.vgNuDiasAfastSemRemun = 0
            THEN

            vvlproporcional := fretornavalorrubtot(pcdfolhapagamento => pfolha.cdfolhapagamento,
                                                   ppagcalc          => ppagcalc,
                                                   ptpvalor          => 'P',
                                                   pinrelacaorubrica => 'S');
          ELSE
            vvlproporcional := fretornavalorrubtot(pcdfolhapagamento => pfolha.cdfolhapagamento,
                                                   ppagcalc          => ppagcalc,
                                                   ptpvalor          => 'R',
                                                   pinrelacaorubrica => 'S');
          END IF;

        ELSE

          vvlproporcional := fretornavalorrubtot(pcdfolhapagamento => pfolha.cdfolhapagamento,
                                                 ppagcalc          => ppagcalc,
                                                 pinrelacaorubrica => 'S');
        END IF;

        IF vvlproporcional > 0

         THEN

          --
          -- Proporcionalizar o limite para desligados ou admitidos no mes.
          -- SOLICITA??O 6232/2014 - FOLHA - FOLHA IPREV
          --
        IF (PKGPAG_VAR.vgVinculo.DtDesligamento between pFolha.DtInicioMes and pFolha.DtFimMes) or
           (PKGPAG_VAR.vgVinculo.DtAdmissao between pFolha.DtInicioMes and pFolha.DtFimMes)

           THEN

             IF (PKGPAG_VAR.vgVinculo.dtdesligamento is not null)
               THEN
              -- Se foi admitido e demitido no mes
                 IF (PKGPAG_VAR.vgVinculo.DtAdmissao > pFolha.DtInicioMes)
                   THEN

                      vNuDiasProp := PKGPAG_VAR.vgVinculo.dtdesligamento - PKGPAG_VAR.vgVinculo.DtAdmissao + 1;

              ELSE

                      vNuDiasProp := to_number(to_char(PKGPAG_VAR.vgVinculo.DtDesligamento, 'DD'));

              END IF;

            ELSE

                 vNuDiasProp := pFolha.DtFimMes - PKGPAG_VAR.vgVinculo.DtAdmissao + 1;

            END IF;

             IF vNuDiasProp > 30
               THEN
              vnudiasprop := 30;

            END IF;

          END IF;

          SELECT nuvalorfixovantagem
            INTO vnuvalorfixovantagem
            FROM ebpcfaixavalorvpformapag fv
         WHERE FV.Cdhistvantagempecuniaria = PKGPAG_VAR.vgVantagem(pPagCalc.CdVantagemPecuniaria).Cdhistvantagempecuniaria AND
               ((vVlProporcional BETWEEN FV.NuValorBaseInicio AND (FV.NuValorBaseFim / 30 * vNuDiasProp) ) OR
               (vVlProporcional >= FV.NuValorBaseInicio AND FV.NuValorBaseFim IS NULL));
        END IF;

      EXCEPTION

        WHEN OTHERS THEN

          vnuvalorfixovantagem := NULL;

      END;

      IF vnuvalorfixovantagem IS NOT NULL THEN

        IF PKGPAG_VAR.vgvlpercentreducao > 0 THEN

        vNuValorFixoVantagem:= vNuValorFixoVantagem*(100-PKGPAG_VAR.vgVlPercentReducao)/100;

        END IF;

        PExecutaProporcionalidade(pFolha,
                                  pPagCalc,
                                  vNuValorFixoVantagem,
                                  NULL);

      END IF;

      /*---------------------------------------------------------------------------------------------*/
      -- Valor gerado pelas regras de neg?cio de um tipo de evento
      /*---------------------------------------------------------------------------------------------*/
    ELSIF PKGPAG_VAR.vgVantagem(pPagCalc.CdVantagemPecuniaria).CdFormaPagVantPecuniaria = 7 THEN

      BEGIN

      vVlProporcional := FRetornaValorRubTot(pFolha.CdFolhaPagamento, pPagCalc,'R');

        -- Nao calcular salario familia se nao encontrou valor para a base 09-1000
        if nvl(vVlProporcional, 0) <= 0 then
          return;
        end if;

        --
        -- Soma base de calculo de outros vinculos
        --
        vVlBaseSalFamOutroVinc := fVlrBaseSalFamOutraFolha(PKGPAG_VAR.vgVinculo.CdPessoa,
                                                           pPagCalc.CdVinculo);

      IF vVlBaseSalFamOutroVinc > 0
        THEN

          vVlProporcional := vVlProporcional + vVlBaseSalFamOutroVinc;

        END IF;

      SELECT SUM(DECODE(D.FlInvalidez,'N',
                          FV.NuValorDependenteValido,
                          fv.nuvalordependenteinvalido)),
               COUNT(*) AS vlindice
        INTO vvlSalarioFamilia,
             vvlIndice
          FROM ecadpessoadependente pd
         INNER JOIN ecaddependente d
            ON d.cddependente = pd.cddependente
         INNER JOIN ecadvinculo v
            ON pd.cdresponsavel = v.cdpessoa
         INNER JOIN epagregraconcpagsalfamgraupar rcgp
            ON pd.cdgrauparentescoprevfin = rcgp.cdgrauparentescoprevfin
         INNER JOIN epaghistregraconcpagsalfamilia hrc
          ON RCGP.CdHistRegraConcPagSalFamilia = HRC.CdHistRegraConcPagSalFamilia
         INNER JOIN epagregraconcpagsalfamilia rc
            ON hrc.cdregraconpagsalfamilia = rc.cdregraconpagsalfamilia
         INNER JOIN epagregraconcpagsalfamfaixaval fv
          ON HRC.CdHistRegraConcPagSalFamilia = FV.CdHistRegraConcPagSalFamilia
       WHERE V.CdVinculo = pPagCalc.CdVinculo AND
             RC.Cdagrupamento = pFolha.CdAgrupamento AND
             V.CdRegimeTrabalho = RC.CdRegimeTrabalho AND
             MONTHS_BETWEEN(pFolha.DtInicioMes, D.DtNascimento) <= DECODE(D.FlInvalidez,'N',
                      nvl(rcgp.nulimiteidadedepvalido, 1000) * 12,
                                                                    nvl(RCGP.NuLimiteIdadeDepInvalido,1000)*12) AND
            (vVlProporcional BETWEEN FV.NuValorInicialBaseCalc AND FV.NuValorFinalBaseCalc) AND
            ((HRC.NuAnoInicioVigencia < pFolha.NuAnoReferencia OR
               (hrc.nuanoiniciovigencia = pfolha.nuanoreferencia AND
             HRC.NumesInicioVigencia <= pFolha.NuMesReferencia))
            AND
               (hrc.nuanofimvigencia > pfolha.nuanoreferencia OR
               (hrc.nuanofimvigencia = pfolha.nuanoreferencia AND
               hrc.numesfimvigencia >= pfolha.numesreferencia) OR
               hrc.numesfimvigencia IS NULL));

        IF nvl(vvlsalariofamilia, 0) > 0 THEN

          PExecutaProporcionalidade(pFolha,
                                    pPagCalc,
                                    vvlSalarioFamilia,
                                    vvlindice);

        ELSE
          --
          -- Excluir base de calculo do Salario Familia para os que nao tem direito ao beneficio
          --
          PKGPAG_GERAL.pexcluirubrica(pcdfolhapagamento => pFolha.CdFolhaPagamento,
                                      pcdvinculo        => pPagCalc.CdVinculo,
                                      pcdrubrica        => pPagCalc.cdrubricatotalizadoravantagem,
                                      pflexcluiambos    => 'S');

        END IF;

      EXCEPTION

        WHEN OTHERS THEN

          --dbms_output.put_line(SQLERRM);

          NULL;

      END;

    else
      null;
    END IF;

  END;

  /*-----------------------------------------------------------------------------------------
  -- Procedure: ProcessaEventoBase
  --  Objetivo: Processa eventos com rubricas associadas a uma base.

  -- Ex: Aux?lio Alimenta??o
  /*-----------------------------------------------------------------------------------------*/
  PROCEDURE pproceventobase(pfolha   IN pkgpag_tipo.rfolha,
                            ppagcalc IN pkgpag_tipo.rpagcalc) IS

    vvlbase NUMBER(13, 2);

    vvldiario NUMBER(13, 2);

    vvlintegral NUMBER(13, 2);

  BEGIN
 
    vvlbase := fretornavalorrubtot(pfolha.cdfolhapagamento, ppagcalc);
    IF vvlbase > 0 THEN

      BEGIN

        SELECT va.vldiario
          INTO vvldiario
          FROM ealifaixavalorauxilio va
       WHERE VA.CdValorAuxilio = PKGPAG_VAR.vgAuxilioAli(pFolha.CdOrgao).CdValorAuxilio AND
             vvlBase BETWEEN VA.VlInicialBaseCalculo AND VA.VlFinalBaseCalculo;

        vvlintegral := ppagcalc.vlindicerubrica * vvldiario;

        IF vvlintegral > 0 THEN

          PExecutaProporcionalidade(pFolha,
                                    pPagCalc,
                                    vvlIntegral,
                                    ppagcalc.vlindicerubrica);

        END IF;

      EXCEPTION

        WHEN OTHERS THEN

          -- N?o encontrou valor di?rio para a base selecionada
          NULL;
      END;

    END IF;

  END;

  /*-----------------------------------------------------------------------------------------*/

  /*-----------------------------------------------------------------------------------------*/

  PROCEDURE pprocrubricatotalizadora(pfolha         IN pkgpag_tipo.rfolha,
                                     ppagcalc       IN pkgpag_tipo.rpagcalc,
                                     pcdbasecalculo IN INTEGER,
                                     ptptributacao  IN INTEGER) IS

    vvlcalculado pkgpag_tipo.rvalorpagamento;

  BEGIN
 
  vVlCalculado :=
         FRetornaValorBaseCalculo (pFolha,
                                             pPagCalc.CdVinculo,
                                             ppagcalc.cdtipohistorico,
                                             ppagcalc.cdrelacaovinculo,
                                             pCdBaseCalculo,
                                             pPagCalc.CdChave,
                                             ptptributacao);

    IF vvlcalculado.vlproporcional IS NULL THEN

      vvlcalculado.vlintegral     := 0;
      vvlcalculado.vlproporcional := 0;
      vvlcalculado.vlreal         := 0;

    ELSE

    IF pPagCalc.cdTipoHistorico = 1 THEN -- Rela??o de Vinculo

        UPDATE epaghistoricorubricarelvinc
           SET vlintegral     = vvlcalculado.vlintegral,
               vlproporcional = vvlcalculado.vlproporcional,
               vlreal         = vvlcalculado.vlreal
         WHERE cdhistoricorubricarelvinc = ppagcalc.cdhistpagamento;

    ELSE -- cdTipoHistorico = 2, Vinculo

        UPDATE epaghistoricorubricavinculo
           SET vlpagamento = nvl(vvlcalculado.vlproporcional, 0),
               deexpressao = vvlcalculado.deexpressao
         WHERE cdhistoricorubricavinculo = ppagcalc.cdhistpagamento;

      END IF;

    END IF;

  END;

  FUNCTION fcalculaproporcao(pfolha            IN pkgpag_tipo.rfolha,
                             prubrica          IN pkgpag_tipo.rrubrica,
                             pcef              IN pkgpag_tipo.rcef DEFAULT NULL,
                             pfuc              IN pkgpag_tipo.rfuc DEFAULT NULL,
                             pcco              IN pkgpag_tipo.rcco DEFAULT NULL,
                             papo              IN pkgpag_tipo.rcef DEFAULT NULL,
                             pbol              IN pkgpag_tipo.rbol DEFAULT NULL,
                             ppnp              IN pkgpag_tipo.rpensaonaoprev DEFAULT NULL,
                             pvlcalculado      IN pkgpag_tipo.rvalorpagamento,
                             pflexprigualinteg IN BOOLEAN,
                             pflexprigualreal  IN BOOLEAN,
                             pnucho            IN NUMBER DEFAULT NULL,
                            pDtCalculo         IN DATE DEFAULT NULL
                             ) RETURN PKGPAG_TIPO.rValorPagamento IS

    vvlexpr pkgpag_tipo.rvalorpagamento;

    vvaloraux pkgpag_tipo.rvalorpagamento;

    vvalorpagamento pkgpag_tipo.rvalorpagamento;

    vVPNI1576 number;

        VNaogera integer;

  BEGIN
 
    -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria

    -- Proporcional


    IF PKGPAG_GERAL.FRetornaRubrica(pfolha.CdAgrupamento,1,0594) = pRubrica.CdRubricaAgrupamento AND
       PKGPAG_VAR.bVinculoComCEF AND
       PKGPAG_VAR.bVinculoComCCO AND
       pCef.CdVinculo IS NOT NULL AND
       PKGPAG_VAR.vgValorCalculoRubrica(pRubrica.CdRubricaAgrupamento).DeFormulaExpressao IS NOT NULL AND
       prubrica.flaplicarubricaorgaos = 'N'
       THEN
       IF NOT prubrica.lsorgao.exists(PKGPAG_VAR.vgCdOrgaoVinculo) THEN
            RETURN vvlexpr;
       END IF;
    END IF;

     ----regra do chamando SIG-11472 - SIG-11689 se paga a 01.0594 não paga a 01-1468.

     /*IF PKGPAG_GERAL.FRetornaRubrica(pfolha.CdAgrupamento,1,1468) = pRubrica.CdRubricaAgrupamento AND
              PKGPAG_VAR.bVinculoComCCO AND
              PKGPAG_VAR.vgRelVincPrincipal.Tipo = 1 AND
              PKGPAG_VAR.vgFolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaNormal AND
              PKGPAG_VAR.vgValorCalculoRubrica(pRubrica.CdRubricaAgrupamento).DeFormulaExpressao IS NOT NULL AND
              PKGPAG_VAR.bVinculoComCEF ---- and (pcef.CdOrgaoExercicio = 643 or pcco.CdOrgaoExercicio = 805)
              THEN

              begin
              select 1
              into VNaogera
              from epaghistoricorubricarelvinc hrv
              where hrv.cdvinculo= pcef.CdVinculo
              and hrv.cdfolhapagamento=pfolha.CdFolhaPagamento
              and hrv.cdrubricaagrupamento = PKGPAG_GERAL.FRetornaRubrica(pfolha.CdAgrupamento,1,0594)
              and hrv.vlproporcional > 0
              and rownum = 1;
              exception when others then
                VNaogera:= null;
            end;
        IF prubrica.lsorgao.exists(NVL(pcco.CdOrgaoExercicio,pcef.CdOrgaoExercicio)) and nvl(vnaogera,0) = 1 THEN

          RETURN vvlexpr;
          
        ELSIF not prubrica.lsorgao.exists(NVL(pcco.CdOrgaoExercicio,pcef.CdOrgaoExercicio))
          and pcef.CdOrgaoExercicio <>  pfolha.CdOrgao  AND nvl(vnaogera,0) = 1 and pcco.CdOrgaoExercicio is null THEN
          
          RETURN vvlexpr;
          
        ELSE
          NULL; 

        END IF;
     END IF;*/

    vVPNI1576 := PKGPAG_GERAL.fretornarubrica(1, 1, 1576);

     vValorPagamento :=

     PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                              prubrica       => prubrica,
                                                              pvalorintegral => pvlcalculado.vlproporcional,
                                                              pnucho         => pnucho,
                                                              pdtcalculo     => pdtcalculo,
                                                              pcef           => pcef,
                                                              pfuc           => pfuc,
                                                              pcco           => pcco,
                                                              papo           => papo,
                                                              pbol           => pbol,
                                                              ppnp           => ppnp);

    vvlexpr.vlproporcional := vvalorpagamento.vlproporcional;

    vvlexpr.vlreal := vvalorpagamento.vlreal;

    vvlexpr.vlindice := vvalorpagamento.vlindice;

    IF pRubrica.CdRubricaAgrupamento = vVPNI1576 THEN
        IF (pcef.cdrelacaovinculo = pkgpag_tipo.cnTpRelacaoEfetivo
          OR pApo.CdSituacaoPrevidenciaria = pkgpag_tipo.cnSitPrevAposentado) THEN
        IF PKGPAG_VAR.vCdRelacaoTrabalhoCCO IS NOT NULL THEN
          vvlexpr.vlintegral     := vvlexpr.vlreal;
          vvlexpr.vlproporcional := 0;
        ELSE

          IF pflexprigualinteg THEN

            vvlexpr.vlintegral := vvalorpagamento.vlintegral;

                ELSE -- Integral

                 vValorAux :=

                   PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                prubrica       => prubrica,
                                                                pvalorintegral => pvlcalculado.vlintegral,
                                                                pnucho         => pnucho,
                                                                pdtcalculo     => pdtcalculo,
                                                                pcef           => pcef,
                                                                pfuc           => pfuc,
                                                                pcco           => pcco,
                                                                papo           => papo,
                                                                pbol           => pbol,
                                                                ppnp           => ppnp);

            vvlexpr.vlintegral := vvaloraux.vlintegral;

          END IF;

          IF pflexprigualreal THEN

            vvlexpr.vlreal := vvalorpagamento.vlreal;

                ELSE -- Real

                 vValorAux :=

                   PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                                prubrica       => prubrica,
                                                                pvalorintegral => pvlcalculado.vlreal,
                                                                pnucho         => pnucho,
                                                                pdtcalculo     => pdtcalculo,
                                                                pcef           => pcef,
                                                                pfuc           => pfuc,
                                                                pcco           => pcco,
                                                                papo           => papo,
                                                                pbol           => pbol,
                                                                ppnp           => ppnp);

            vvlexpr.vlreal := vvaloraux.vlreal;

          END IF;

        END IF;
      END IF;

        IF pcef.CdVinculo = 445285 THEN-- SIG-8239
        vvlexpr.vlproporcional := vvlexpr.vlintegral;
      END IF;
    ELSE

      IF pflexprigualinteg THEN

        vvlexpr.vlintegral := vvalorpagamento.vlintegral;

      ELSE -- Integral

       vValorAux :=

         PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                            prubrica       => prubrica,
                                                            pvalorintegral => pvlcalculado.vlintegral,
                                                            pnucho         => pnucho,
                                                            pdtcalculo     => pdtcalculo,
                                                            pcef           => pcef,
                                                            pfuc           => pfuc,
                                                            pcco           => pcco,
                                                            papo           => papo,
                                                            pbol           => pbol,
                                                            ppnp           => ppnp);

        vvlexpr.vlintegral := vvaloraux.vlintegral;

      END IF;

      IF pflexprigualreal THEN

        vvlexpr.vlreal := vvalorpagamento.vlreal;

      ELSE -- Real

       vValorAux :=

         PKGPAG_GERAL.FCalculaProporcionalidade(pFolha             => pFolha,
                                                            prubrica       => prubrica,
                                                            pvalorintegral => pvlcalculado.vlreal,
                                                            pnucho         => pnucho,
                                                            pdtcalculo     => pdtcalculo,
                                                            pcef           => pcef,
                                                            pfuc           => pfuc,
                                                            pcco           => pcco,
                                                            papo           => papo,
                                                            pbol           => pbol,
                                                            ppnp           => ppnp);

        vvlexpr.vlreal := vvaloraux.vlreal;

      END IF;

    END IF;

    RETURN vvlexpr;

  END;

  /*-----------------------------------------------------------------------------------------/
    PROCEDURE PProcessaFormulaCalculo

  /*---------------------------------------------------------------------------------------*/

  PROCEDURE pprocformulacalculo(pfolha        IN pkgpag_tipo.rfolha,
                                ppagcalc      IN pkgpag_tipo.rpagcalc,
                                pexprform     IN pkgpag_tipo.rformulacalculo,
                                ptptributacao IN INTEGER DEFAULT NULL,
                                pcdmnemonico  IN INTEGER DEFAULT NULL,
                                pRetornaValor IN CHAR DEFAULT NULL,
                                pCdFolhaAnt   IN INTEGER DEFAULT NULL) IS
    lnvlpagamento number(17, 2);
    Vvinculorub1327 integer := 641376;
    VtetoInss PKGPAG_TIPO.rAliquotaINSS;
    VvalorLancamento08193 number(17,2):=0;
    Vcdlancamento08193 integer;
    vVlContribuicao number;

  TYPE rVin IS RECORD
    (CdHistPagamento          INTEGER,
      cdvinculo                INTEGER,
      cdtipohistorico          INTEGER,
      cdrelacaovinculo         INTEGER,
      cdchave                  INTEGER,
      cdhistcargoefetivo       INTEGER,
      cdhistfuncaochefia       INTEGER,
      cdhistcargocom           INTEGER,
      cdhistestagio            INTEGER,
      cdconcessaoaposentadoria INTEGER,
      cdhistpensaonaoprev      INTEGER,
      dtiniciorelacao          DATE,
      dtdesligamento           DATE,
      cdunidadeorganizacional  INTEGER,
      cdlancamentofinanceiro   INTEGER,
      dtinicio                 DATE,
      dtfim                    DATE,
      lformcalculo             pkgpag_tipo.rformulacalculo);

    vvlexpr pkgpag_tipo.rvalorpagamento;

    vvlcalculado pkgpag_tipo.rvalorpagamento;

    vvin rvin;

    vrubrica pkgpag_tipo.rrubrica;

    vbaseexpr pkgpag_tipo.rbasecalculo;

    vcdtipoincorporacaoativo INTEGER;

    vvlindicerubrica NUMBER(9, 4);

    vdeindicerubrica VARCHAR2(10);

    --vVlPropBaseIncorpCef NUMBER(13,2);

    --vVlPropBaseIncorpApo NUMBER(13,2);

    -- Vari?veis utilizadas para a proporcionalidade do valor da fun??o

    vvalorpagamento pkgpag_tipo.rvalorpagamento;

    vcdrubricaagrupamento INTEGER;

    vcdbaseincorporacaoativo INTEGER;

    vvlminrecebincorp NUMBER;

    bvlexprigualintegral BOOLEAN;

    bvlexprigualreal BOOLEAN;

    vdeexpressao pkgpag_tipo.rexprpagamento;

    vdeformula pkgpag_tipo.rexprpagamento;

    --vVlExpressao pkgpag_tipo.rvalorpagamento;

    vVlIndice050802 NUMBER(9, 4);

    vVlBase930 pkgpag_tipo.rvalorpagamento;

    vSgBaseCalculo VARCHAR2(10);

    vRubPercent PKGPAG_TIPO.rRubPercent;

    vFlFolha13 CHAR;

    PROCEDURE PProporcionalizarRubrica01_1070(pCdVinculo            IN INTEGER,
                                              pCdRubricaAgrupamento IN INTEGER,
                                              pFolha                IN pkgpag_tipo.rfolha,
                                              pVlExpr               IN OUT pkgpag_tipo.rvalorpagamento) IS
      vListaMotivos       sys.odcinumberlist;
      vDiasAfastamentoMes INTEGER;
      vProporcao          NUMBER;
      vNuDiasMes          INTEGER;
    BEGIN
       vListaMotivos := PKGPAG_GERAL.FListaMotivosAfastTempExigidos(pCdRubricaAgrupamento => pCdRubricaAgrupamento,
                                                                   pdataVigencia         => pFolha.DtCalculo);

      vDiasAfastamentoMes := PKGPAG_GERAL.FObterDiasAfastamentoTemporario(pDtInicioMes       => pFolha.DtInicioMes,
                                                                          pDtFimMes          => pFolha.DtFimMes,
                                                                          pCdVinculo         => pCdVinculo,
                                                                          pListaMotAfastTemp => vListaMotivos);

      vProporcao             := PKGPAG_GERAL.FObterProporcaoDiasAReceberMes(pQualquerDiaDoMes => pFolha.DtCalculo,
                                                                            pDiasAReceber     => vDiasAfastamentoMes);
      pVlExpr.vlProporcional := pVlExpr.vlIntegral * vProporcao;
      pVlExpr.vlIndice       := vDiasAfastamentoMes;
    END;

  BEGIN
 
    IF pfolha.CdTipoFolha in (3,20) THEN
      vFlFolha13 := 'S';
    ELSE
      vFlFolha13 := 'N';
    END IF;

    vVlSubst := null;

    vvin.cdhistpagamento := ppagcalc.cdhistpagamento;

    vvin.cdvinculo := ppagcalc.cdvinculo;

    vvin.cdtipohistorico := ppagcalc.cdtipohistorico;

    vvin.cdrelacaovinculo := ppagcalc.cdrelacaovinculo;

    vvin.cdchave := ppagcalc.cdchave;

    vvin.cdhistcargoefetivo := ppagcalc.cdhistcargoefetivo;

    vvin.cdhistfuncaochefia := ppagcalc.cdhistfuncaochefia;

    vvin.cdhistcargocom := ppagcalc.cdhistcargocom;

    vvin.cdconcessaoaposentadoria := ppagcalc.cdconcessaoaposentadoria;

    vvin.cdhistpensaonaoprev := ppagcalc.cdhistpensaonaoprev;

    vvin.cdhistestagio := ppagcalc.cdhistestagio;

    vvin.dtiniciorelacao := ppagcalc.dtiniciorelacao;

    vvin.dtdesligamento := ppagcalc.dtdesligamento;

    vvin.cdunidadeorganizacional := ppagcalc.cdunidadeorganizacional;

    vvin.cdlancamentofinanceiro := ppagcalc.cdlancamentofinanceiro;

    vvin.dtinicio := ppagcalc.dtinicio;

    vvin.dtfim := ppagcalc.dtfim;

    vvin.lformcalculo := pexprform;

    vvlindiceoutrarubrica := 0;

    vrubrica := PKGPAG_VAR.vgrubrica(vvin.lformcalculo.cdrubricaagrupamento);

    PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).CdVinculo := vvin.cdvinculo;

    PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).CdRubricaAgrupamento := vrubrica.CdRubricaAgrupamento;

    PKGPAG_VAR.vgPagCalc := ppagcalc;

    IF vvin.lformcalculo.lbloco.count > 0 THEN

      vdeformula.deexprproporcional := vvin.lformcalculo.deformulaexpressao;
      vdeformula.deexprintegral     := vvin.lformcalculo.deformulaexpressao;
      vdeformula.deexprreal         := vvin.lformcalculo.deformulaexpressao;

    FOR j IN vVin.lFormCalculo.lBloco.FIRST .. vVin.lFormCalculo.lBloco.LAST
    LOOP

        vdeexpressao.deexprproporcional := '';
        vdeexpressao.deexprintegral     := '';
        vdeexpressao.deexprreal         := '';

        IF vvin.lformcalculo.lbloco(j).lexpressao.count > 0 THEN

          BEGIN

        FOR k IN vVin.lFormCalculo.lBloco(j).lExpressao.FIRST .. vVin.lFormCalculo.lBloco(j).lExpressao.LAST
        LOOP

              vVlCalculado.vlProporcional := vVin.lFormCalculo.lBloco(j).lExpressao(k).VlResultado.vlProporcional;
              vvlcalculado.vlintegral     := NULL;
              vvlcalculado.vlreal         := NULL;

              CASE vvin.lformcalculo.lbloco(j).lexpressao(k).cdtipomneumonico

            WHEN 1 THEN -- REF

               vVlCalculado.vlProporcional :=

                     FMneREF(vVin.lFormCalculo.lBloco(j).lExpressao(k).CdValorReferencia);

              if vRubrica.CdRubricaAgrupamento = 68975 AND nvl(PKGPAG_VAR.vgNuDiasAfastSemRemun, 0) >= 30 then
                    vVlCalculado.vlProporcional := 0;
              end if;

              -- Tratamento Rubrica 01-0327 COMPL PISO MAGISTERIO
              -- Descontar os dias que o servidor esteve afastado
              /*IF vRubrica.CdRubricaAgrupamento = 36637 AND nvl(PKGPAG_VAR.vgNuDiasAfastSemRemun, 0) > 0 THEN
                                                                                                        vVlCalculado.vlProporcional := vVlCalculado.vlProporcional * (30-PKGPAG_VAR.vgNuDiasAfastSemRemun) / 30;
                                                                                                  END IF;*/

            WHEN 2 THEN -- BAS

                  SELECT bc.sgbasecalculo
                    INTO vSgBaseCalculo
                    FROM epagbasecalculo bc
                   WHERE bc.cdbasecalculo = vVin.lFormCalculo.lBloco(j).lExpressao(k).CdBaseCalculo
                     AND bc.cdagrupamento = pFolha.CdAgrupamento;

                  vBaseExpr := PKGPAG_VAR.vgBaseExpr(vVin.lFormCalculo.lBloco(j).lExpressao(k).CdBaseCalculo);

              IF (vVin.CdTipoHistorico = 2 AND NVL(ptptributacao,0) <> 4) or
                 (trunc(PKGPAG_VAR.vgVinculo.DtDesligamento) < trunc(pFolha.DtInicioMes) and
                     vSgBaseCalculo in ('BFER', 'FEJUD'))

                  THEN -- Se est? calculando f?rmula no v?nculo

                    BEGIN

                      -- dbms_output.put_line('----------------------------');
                      -- dbms_output.put_line(vRubrica.CdRubricaAgrupamento);
                      -- dbms_output.put_line(vVin.lFormCalculo.lBloco(j).lExpressao(k).CdBaseCalculo);

                      SELECT cdrubricaagrupamento
                        INTO vcdrubricaagrupamento
                        FROM epagrubricaagrupamento ra
                       INNER JOIN epagrubrica r
                          ON ra.cdrubrica = r.cdrubrica
                   WHERE RA.CdAgrupamento = pFolha.CdAgrupamento AND
                         RA.CdBaseCalculo = vVin.lFormCalculo.lBloco(j).lExpressao(k).CdBaseCalculo AND
                         R.CdTipoRubrica = PKGPAG_TIPO.cnTpRubTotalizadora;

                    if trunc(PKGPAG_VAR.vgVinculo.DtDesligamento) < trunc(pFolha.DtInicioMes) and
                         vSgBaseCalculo in ('BFER', 'FEJUD') then

                       vVlCalculado.vlProporcional :=
                       PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                                                                         pcdvinculo        => vvin.cdvinculo,
                                                                                         pcdrubrica        => vcdrubricaagrupamento);

                      else
                       vVlCalculado.vlProporcional :=
                       PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamento,
                                                                                         pcdvinculo        => vvin.cdvinculo,
                                                                                         pcdrubrica        => vcdrubricaagrupamento);

                      end if;

                   if vVlCalculado.vlProporcional = 0 AND vSgBaseCalculo = 'B13SA' then

                      vVlCalculado.vlProporcional :=

                      PKGPAG_GERAL.FRetornaValorRubrica(pCdFolhaPagamento => pFolha.CdFolhaPagamentoNormalAnt,
                                                                                         pcdvinculo        => vvin.cdvinculo,
                                                                                         pcdrubrica        => vcdrubricaagrupamento);
                      end if;

                      ---------------------------------------------------------------------------------
                      -- Caso trate-se de f?rmula de c?lculo de pens?o aliment?cia e o ?rg?o
                      -- est? parametrizado para n?o pagar pens?o na folha de f?rias, recupera os
                      -- valores da folha de f?rias
                      ---------------------------------------------------------------------------------

                  IF PKGPAG_VAR.vgFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolhaNormal, PKGPAG_TIPO.cnTpFolhaFunebre, PKGPAG_TIPO.cnTpFolhaServAfast ) AND
                         vrubrica.flpensaoalimenticia = 'S' AND
                         PKGPAG_VAR.vgparampagamento.flgerapensaofolhaferias = 'N' AND
                         PKGPAG_VAR.vgcdfolhaferias > 0 THEN

                        vvlcalculado.vlproporcional := vvlcalculado.vlproporcional +

                                                       PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgcdfolhaferias,
                                                                                         pcdvinculo        => vvin.cdvinculo,
                                                                                         pcdrubrica        => vcdrubricaagrupamento);
                      END IF;

                    EXCEPTION

                      WHEN no_data_found THEN

                        vvlcalculado.vlproporcional := NULL;

                    END;

                  END IF;

                  --
                  -- Cidasc BASE FLEX CERES, excecao para nao recalcular a base. 09-0930
                  --

                IF pFolha.CdAgrupamento = 4 AND PKGPAG_VAR.vgRubrica(48295).CdBaseCalculo =
                   vVin.lFormCalculo.lBloco(j).lExpressao(k).CdBaseCalculo

                   THEN

                    vvlcalculado := PKGPAG_GERAL.fretornavaloroutrasrv(PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                                                       ppagcalc.cdvinculo,
                                                                       48295);
                    IF vvlcalculado.vlProporcional = 0
                      THEN
                      vvlcalculado := null;
                    END IF;

                  END IF;

                  IF vvlcalculado.vlproporcional IS NULL THEN

                    IF ppagcalc.cdincorporacaoativo IS NOT NULL THEN

                      SELECT ia.cdbaseincorporacaoativo
                        INTO vcdtipoincorporacaoativo
                        FROM ebpcincorporacaoativo ia
                   WHERE IA.CdIncorporacaoAtivo = pPagCalc.CdIncorporacaoAtivo;

                      IF vcdtipoincorporacaoativo IN (1, 2, 3, 4, 5) THEN

                        vvlcalculado.vlproporcional := 0;

                      ELSE

                     vVlCalculado :=

                       FMneBase (pFolha            => pFolha,
                                                 pcdvinculo        => ppagcalc.cdvinculo,
                                                 pCdBaseCalculo    => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdBaseCalculo,
                                                 pcdtipohistorico  => vvin.cdtipohistorico,
                                                 pcdrelacaovinculo => vvin.cdrelacaovinculo,
                                                 pcdchave          => vvin.cdchave,
                                                 ptptributacao     => ptptributacao);

                      END IF;

                    ELSE


                    vVlCalculado :=

                       FMneBase (pFolha            => pFolha,
                                               pcdvinculo        => ppagcalc.cdvinculo,
                                               pCdBaseCalculo    => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdBaseCalculo,
                                               pcdtipohistorico  => vvin.cdtipohistorico,
                                               pcdrelacaovinculo => vvin.cdrelacaovinculo,
                                               pcdchave          => vvin.cdchave,
                                               ptptributacao     => ptptributacao);

                    END IF;

                  END IF;

            WHEN 3 THEN -- BASEINC

                  vvlcalculado.vlproporcional := fmnebaseinc(ppagcalc.cdincorporacaoativo,
                                                             pfolha);

                  vvlcalculado.vlreal := vvlcalculado.vlproporcional;

              IF NOT (NVL(PKGPAG_VAR.vgVinculo.DtDesligamento, PKGPAG_TIPO.cnDtMax) BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)
                 THEN

                IF NOT (NVL(PKGPAG_VAR.vgAPO.COUNT,0) > 0 AND
                        PKGPAG_VAR.vgAPO(1).DTINICIO > pFolha.DtInicioMes AND
                        vrubrica.CdRubricaAgrupamento = 10730) THEN --01-0085

                      CASE vvin.cdrelacaovinculo

                        WHEN 1 THEN

                    FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
                    LOOP

                      IF PKGPAG_VAR.vgCEF(i).CdHistRelVinc = vVin.CdHistCargoEfetivo THEN

                        IF ((PKGPAG_VAR.vgCEF(i).DtInicioRelacao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
                           (PKGPAG_VAR.vgCEF(i).DtFimRelacao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)) AND
                                 vrubrica.cdrubproporcionalidadecho <> 2 THEN

                         vVlCalculado.vlProporcional :=

                           vVlCalculado.vlProporcional/30*(PKGPAG_VAR.vgCEF(i).DtFim - PKGPAG_VAR.vgCEF(i).DtInicio + 1);

                           PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef :=
                           NVL(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef,0) + TRUNC(vVlCalculado.vlProporcional,2);

                              END IF;

                            END IF;

                          END LOOP;

                        WHEN 4 THEN

                    FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
                    LOOP

                      IF PKGPAG_VAR.vgAPO(i).CdHistRelVinc = vVin.CdConcessaoAposentadoria THEN

                        IF ((PKGPAG_VAR.vgAPO(i).DtInicioRelacao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes) OR
                           (PKGPAG_VAR.vgAPO(i).DtFimRelacao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes)) AND
                                 vrubrica.cdrubproporcionalidadecho <> 2 THEN

                         vVlCalculado.vlProporcional :=

                          vVlCalculado.vlProporcional/30*(PKGPAG_VAR.vgAPO(i).DtFim - PKGPAG_VAR.vgAPO(i).DtInicio + 1);

                                -- PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef,0
                          PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlApo :=
                           NVL(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlApo,0) + TRUNC(vVlCalculado.vlProporcional,2);

                              END IF;

                            END IF;

                          END LOOP;

                      END CASE;

                    END IF;
                  END IF;

            WHEN 4 THEN -- RUB

              vVlCalculado :=

                FMneRUB(pPagCalc.CdVinculo,
                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).CdExpressao,
                         case when pCdFolhaAnt is not null then pCdFolhaAnt
                              else vVin.lFormCalculo.lBloco(j).lExpressao(k).CdFolhaHistorico end,
                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).CdFolhaHistAlt,
                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).InRelacaoRubrica,
                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).InTipoRubrica,
                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).InMes,
                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).NuMesRubrica,
                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).NuAnoRubrica,
                                          vVin.CdTipoHistorico,
                                          vVin.CdRelacaoVinculo,
                                          FALSE,
                                          vvin.cdchave,
                                          vvin.lformcalculo.cdrubricaagrupamento,
                                          pfolha.nuanoreferencia,
                                          pFolha.NuMesReferencia,
                                          pTpTributacao,
                                          null,
                                          pFolha.CdAgrupamento,
                                          pCdMnemonico);

                  -- Solicitacao de Sustentacao #71729
                  -- 2102-DEFENSORIA PUBLICA DO ESTADO DE SANTA CATARINA
                  -- Para a rubrica 01-0332, utilizar o valor real para o calculo
                  IF vvin.lformcalculo.cdrubricaagrupamento = 49370 THEN

                    vVlCalculado.vlProporcional := vVlCalculado.vlReal;
                    vVlCalculado.vlIntegral     := vVlCalculado.vlReal;

                  END IF;

                  -- Para a rubrica 01-1327, utilizar o valor real para o calculo

                  IF vvin.lformcalculo.cdrubricaagrupamento = 68975 and vvin.cdvinculo = Vvinculorub1327
                     and  vVlCalculado.vlProporcional < vVlCalculado.vlReal
                    THEN

                    vVlCalculado.vlProporcional := vVlCalculado.vlReal;

                  END IF;

                  -- Ajuste para o calculo da 01-0617
                  IF vvin.lformcalculo.cdrubricaagrupamento = 49530 THEN

                    vVlCalculado.vlIntegral := vVlCalculado.vlReal;

                  END IF;

                  -- Ajuste para o calculo da 08-0802
            IF vvin.lformcalculo.cdrubricaagrupamento = 48192
              AND NVL(vVlBase930.vlProporcional, 0) > 0 THEN

                  vVlCalculado.vlProporcional := LEAST(vVlCalculado.vlReal, vVlBase930.vlIntegral);
                    vVlCalculado.vlIntegral     := vVlCalculado.vlProporcional;

                  END IF;

                  -- RUB 01-1575
            IF vvin.lformcalculo.cdrubricaagrupamento = 69358
              THEN
                IF vVlCalculado.vlIntegral = (vVlCalculado.vlProporcional*2) THEN
                      vVlCalculado.vlIntegral := vVlCalculado.vlProporcional;
                    END IF;
                  END IF;

            IF vvin.lformcalculo.cdrubricaagrupamento = PKGPAG_GERAL.fretornarubrica(pcdagrupamento => 1,
                                                  pcdtiporubrica => 5,
                                                                                     pNuRubrica => 519)
               AND vVin.lFormCalculo.lBloco(j).lExpressao(k).InTipoRubrica = 'I'
               AND pFolha.CdTipoFolha = pkgpag_tipo.cnTpFolhaBolsista THEN

                    vVlCalculado.vlProporcional := vVlCalculado.vlIntegral;
                  END IF;

            WHEN 5 THEN -- CHO mensal

             IF vVin.CdRelacaoVinculo IN (0,1,2,3,4) THEN -- Efetivo/ Comissionado / Fun??o de Chefia

               vVlCalculado.vlProporcional :=

                 FMneCHO(pFolha.CdAgrupamento,
                                                           vrubrica,
                                                           vvin.cdrelacaovinculo,
                                                           vvin.cdchave);

                    -- Comentado em 24/07/2012
                    /* ELSIF vVin.CdRelacaoVinculo = 4 THEN -- Aposentado

                    vVlCalculado.vlProporcional := PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria*5;*/

                  ELSE

                    vvlcalculado.vlproporcional := 0;

                  END IF;

            WHEN 7 THEN -- APO

                  vvlcalculado.vlproporcional := fmneapo();

            WHEN 8 THEN -- CEF

                  vvlcalculado.vlproporcional := fmnecef;

            WHEN 9 THEN -- CELG

              vVlCalculado.vlProporcional :=

                 FMneCELG(vVin.lFormCalculo.lBloco(j).lExpressao(k).CdValorGeralCEFAgrup,
                                                          pfolha.nuversaotabcef,
                                                          pfolha.nuanoreferencia,
                                                          pfolha.numesreferencia,
                                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).DeNivel,
                                                          vVin.lFormCalculo.lBloco(j).lExpressao(k).DeReferencia);

            WHEN 10 THEN -- CEL

               vVlCalculado.vlProporcional :=

                 FMneCEL(vVin.lFormCalculo.lBloco(j).lExpressao(k).cdestruturacarreira,
                                                         pfolha.nuversaotabcef,
                                                         pfolha.nuanoreferencia,
                                                         pfolha.numesreferencia,
                                                         vVin.lFormCalculo.lBloco(j).lExpressao(k).DeNivel,
                                                         vVin.lFormCalculo.lBloco(j).lExpressao(k).DeReferencia);

            WHEN 13 THEN -- CCO

                  IF PKGPAG_VAR.vgcco.count > 0 THEN

                    vvlcalculado.vlproporcional := fmnecco(pfolha => pfolha,
                                                           pcco   => PKGPAG_VAR.vgcco(1));

                  END IF;

            WHEN 15 THEN -- FUC

                  IF vVin.lFormCalculo.lBloco(j).lExpressao(k).CdFuncaoChefia IS NULL THEN

                    IF PKGPAG_VAR.vgfuc.count > 0 THEN

                      vvlcalculado.vlproporcional := fmnefuc(pfolha => pfolha,
                                                             pfuc   => PKGPAG_VAR.vgfuc(1));

                    ELSIF PKGPAG_VAR.vgfucsubst.count > 0 THEN

                      vvlcalculado.vlproporcional := fmnefuc(pfolha => pfolha,
                                                             pfuc   => PKGPAG_VAR.vgfucsubst(1));

                    ELSE

                      vvlcalculado.vlproporcional := 0;

                    END IF;

                  END IF;

            WHEN 17 THEN -- MEDIAANO

             vVlCalculado.vlProporcional :=

               FMneMediaAno(vVin.CdVinculo,
                                                              pfolha.nuanoreferencia,
                                                              pfolha.numesreferencia,
                                                              vvin.cdtipohistorico,
                                                              vvin.cdrelacaovinculo,
                                                              vvin.cdchave,
                                                              pfolha.cdagrupamento,
                                                              vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

            WHEN 21 THEN -- SOMAANO

             vVlCalculado.vlProporcional :=

               FMneSomaAno(vVin.CdVinculo,
                                                             pfolha.nuanoreferencia,
                                                             CASE
                                                              WHEN pfolha.cdagrupamento IN (2, 4, 5, 6, 136) OR pfolha.cdtipofolha IN (3, 5) THEN
                                                                pfolha.numesreferencia
                                                               ELSE
                             CASE WHEN pFolha.NuMesReferencia > 1 THEN
                                                                   pfolha.numesreferencia - 1
                                                                  ELSE
                                                                   1
                                                                END
                                                             END,
                                                             vvin.cdtipohistorico,
                                                             vvin.cdrelacaovinculo,
                                                             vvin.cdchave,
                                                             pfolha.cdagrupamento,
                                                             vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                             vFlFolha13);

            WHEN 22 THEN  -- VALOR

              vVlCalculado.vlProporcional :=

                vVin.lFormCalculo.lBloco(j).lExpressao(k).nuValor;

            WHEN 25 THEN -- IND

                  --
                  -- Excecao para a rubrica 01-0472 ja que a formula foi criada como uma soma de
                  -- indices e para evitar que se ja achou o indice desconsidere os proximos.
                  --
              IF NVL(vVlIndiceOutraRubrica,0) > 0 and pPagCalc.CdRubricaAgrupamento = 9888
                 THEN
                    vvlcalculado.vlintegral     := 0;
                    vvlcalculado.vlproporcional := 0;
                    vvlcalculado.vlreal         := 0;
                    vvlcalculado.vlindice       := 0;
                    -- Salario Maternidade Santur
              ELSIF pPagCalc.cdrubricaagrupamento in (39156, 39059)
                 THEN
                    vvlcalculado.vlintegral     := PKGPAG_VAR.vgAfastGravidez.NuDias;
                    vvlcalculado.vlproporcional := PKGPAG_VAR.vgAfastGravidez.NuDias;
                    vvlcalculado.vlreal         := PKGPAG_VAR.vgAfastGravidez.NuDias;
                    vvlcalculado.vlindice       := PKGPAG_VAR.vgAfastGravidez.NuDias;

              ELSIF NVL(pCdMnemonico,0) = 9
                 THEN

                    vvlcalculado.vlintegral     := ppagcalc.vlindicereal;
                    vvlcalculado.vlproporcional := ppagcalc.vlindicereal;
                    vvlcalculado.vlreal         := ppagcalc.vlindicereal;
                    vvlcalculado.vlindice       := ppagcalc.vlindicereal;

                  ELSE

                    vvlindicerubrica := NULL;

                    vdeindicerubrica := NULL;

               vVlCalculado :=

               FMneIND(vVin.CdVinculo,
                                            ppagcalc.cdrubricaagrupamento,
                                            vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                            vVin.lFormCalculo.lBloco(j).lExpressao(k).FlValorHoraMinuto,
                                            ppagcalc.vlindicerubrica,
                                            vvin.lformcalculo.vlindiceliminferiormensal,
                                            vvin.lformcalculo.vlindicelimsuperiormensal,
                                            vvin.lformcalculo.vlindicelimsuperiorsemestral,
                                            vvin.lformcalculo.vlindicelimsuperioranual,
                                            vvin.lformcalculo.deindiceexpressao,
                       case when PKGPAG_VAR.vgCef.Count > 0 and PKGPAG_VAR.vgApo.Count > 0
                            and pPagCalc.CdRubricaAgrupamento = 9888 THEN 4
                            else vVin.CdRelacaoVinculo end,
                       case when PKGPAG_VAR.vgCef.Count > 0 and PKGPAG_VAR.vgApo.Count > 0
                            and pPagCalc.CdRubricaAgrupamento = 9888 THEN
                            PKGPAG_VAR.vgApo(1).CdHistRelVinc else vVin.CdChave end,
                                            ppagcalc.vlindicereal);

               IF vVin.lFormCalculo.lBloco(j).lExpressao(k).FlValorHoraMinuto = 'S'
                     THEN

                      vvlindicerubrica := vvlcalculado.vlproporcional * 100;

                      vdeindicerubrica := lpad(trunc(ppagcalc.vlindicerubrica),
                                         GREATEST(LENGTH(TRUNC(pPagCalc.VlIndiceRubrica)),4),'0');

                  vDeIndiceRubrica :=  SUBSTR(vDeIndiceRubrica, - LENGTH(vDeIndiceRubrica), LENGTH(vDeIndiceRubrica)-2) ||':'||
                                    SUBSTR(vDeIndiceRubrica, LENGTH(vDeIndiceRubrica)-1,2);

                    ELSE

                      vvlindicerubrica := vvlcalculado.vlproporcional;

                    END IF;

                    IF ppagcalc.cdrubricaagrupamento = 58037 AND ppagcalc.vlindicerubrica = 10
                      AND pfolha.CdTipoFolhaPagamento = 2 AND vvin.cdvinculo = 927227 THEN
                          vvlindicerubrica := vvlindicerubrica + 1;
                          vvlcalculado.vlproporcional := vvlindicerubrica;
                    END IF;

                  END IF;

            WHEN 30 THEN -- SubstCCO

              vVlCalculado.vlProporcional :=

                 FMneSubstCCO(vVin.CdRelacaoVinculo,
                                                              vvin.cdhistcargocom,
                                                              pfolha,
                                                              PKGPAG_VAR.vgccosubst,
                                                              PKGPAG_VAR.vdtcalculo);

            WHEN 31 THEN -- SubstFUC

             vVlCalculado.vlProporcional :=

                FMneSubstFUC(vVin.CdRelacaoVinculo,
                                                              vvin.cdhistfuncaochefia,
                                                              pfolha,
                                                              PKGPAG_VAR.vgfucsubst,
                                                              PKGPAG_VAR.vdtcalculo);

            WHEN 32 THEN -- Outras - QtDiasUtNoMes

                  BEGIN

               vVlCalculado.vlProporcional :=

                  FMneQtDiasUtMes(pFolha,
                                                                   vvin.cdunidadeorganizacional,
                                                                   vvin.dtiniciorelacao,
                                                                   vvin.dtdesligamento);

                  EXCEPTION

                    WHEN OTHERS THEN

                      vvlcalculado.vlproporcional := 0;

                    -- Logar
                  END;

            WHEN 33 THEN -- Outras - QtDiasUtPerApu

                  BEGIN

               vVlCalculado.vlProporcional :=

                  FMneQtDiasPerApu(pFolha,
                                                                    vvin.cdunidadeorganizacional,
                                                                    PKGPAG_VAR.vgapuracaofrequencia.dtinicialapuracao,
                                                                    PKGPAG_VAR.vgapuracaofrequencia.dtfinalapuracao,
                                                                    vvin.dtdesligamento);

                  EXCEPTION

                    WHEN OTHERS THEN

                      vvlcalculado.vlproporcional := 0;

                    -- Logar
                  END;

            WHEN 34 THEN -- Outras - QtDiasUtProxMes

             IF vVin.DtDesligamento >= pFolha.DtInicioMes AND vVin.DtDesligamento <= pFolha.DtFimMes THEN

                    vvlcalculado.vlproporcional := 0;

                  ELSE

               vVlCalculado.vlProporcional :=

                  FMneQtDiasProxMes(pFolha,
                                                                     vvin.cdunidadeorganizacional,
                                                                     CASE
                                       WHEN vVin.DtInicioRelacao BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes THEN
                                                                        vvin.dtiniciorelacao
                                                                       ELSE
                                                                        pfolha.dtfimmes + 1

                                                                     END,
                                                                     last_day(pfolha.dtfimmes + 1),
                                                                     vvin.dtdesligamento);

                    -- Retirar - Ultra mega pog by SEA - N?o definiram o calend?rio a tempo.

               IF pFolha.NuAnoReferencia = 2009 AND pFolha.NuMesReferencia = 12 THEN

                 IF vVin.DtInicioRelacao BETWEEN pFolha.DtInicioMes and pFolha.DtFimMes THEN

                        NULL;

                      ELSE

                        vvlcalculado.vlproporcional := vvlcalculado.vlproporcional - 4;

                      END IF;

                    END IF;

                  END IF;

            WHEN 35 THEN -- Outras - QtFaltasPerApu

                  vvlcalculado.vlproporcional := fmnefaltasperapu;

                WHEN 36 THEN

                  vvlcalculado.vlproporcional := fmneaftemp(pfolha,
                                                            vvin.cdvinculo);

                WHEN 37 THEN

                  if vRubrica.NuRubrica = 392  then

                    vVlCalculado.vlProporcional := ppagcalc.vlindicerubrica;

                  else

                    PKGPAG_VAR.vgCdRubCalculada := vrubrica.CdRubricaAgrupamento;

                  IF PKGPAG_VAR.vgRelVincPrincipal.CdRelTrabPagamento = PKGPAG_TIPO.cnRelACT AND
                       PKGPAG_VAR.vgfolha.cdorgao <> 43 THEN

                    vVlCalculado.vlProporcional :=

                      FMneQtMesesTrabAno (pFolha  => pFolha,
                                                                        pcdvinculo       => vvin.cdvinculo,
                                                                        pdtiniciorelacao => PKGPAG_VAR.vgrelvincprincipal.dtiniciorelacao,
                                                                        pdtfimrelacao    => PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                        pdtcalculo       => PKGPAG_VAR.vdtcalculo);

                    ELSE

                    vVlCalculado.vlProporcional :=

                      FMneQtMesesTrabAno (pFolha           => pFolha,
                                                                        pcdvinculo       => vvin.cdvinculo,
                                                                        pdtiniciorelacao => PKGPAG_VAR.vgvinculo.dtadmissao,
                                                                        pdtfimrelacao    => PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                        pdtcalculo       => PKGPAG_VAR.vdtcalculo);

                    END IF;

                  end if;

                  vnumestrab := vvlcalculado.vlproporcional;

                WHEN 38 THEN

                  vvlcalculado.vlproporcional := fmnepercdecjud;

                WHEN 39 THEN

             vVlCalculado.vlProporcional :=

               FMnePossuiCC(pFolha           => pFolha,
                                                              pcdvinculo => vvin.cdvinculo);

                WHEN 40 THEN

             vVlCalculado.vlProporcional :=

                FMneVlOutrosVinculos(pCdPessoa        => PKGPAG_VAR.vCdPessoa,
                                                                      pcdvinculo       => vvin.cdvinculo,
                                                                      pCdRubrica       => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                      pnuanoreferencia => pfolha.nuanoreferencia,
                                                                      pnumesreferencia => pfolha.numesreferencia);

                WHEN 41 THEN

             vVlCalculado.vlProporcional :=

                FMnePossuiProventos(pFolha      => pFolha,
                                                                     pcdvinculo => vvin.cdvinculo);

                WHEN 42 THEN

             vVlCalculado.vlProporcional :=

              FRetornaPercentAcumATS(pCdVinculo        => vVin.CdVinculo,
                                                                        pcdagrupamento => pfolha.cdagrupamento,
                                                                        pdtiniciomes   => pfolha.dtiniciomes,
                                                                        pdtfimmes      => pfolha.dtfimmes);

                WHEN 43 THEN

                  vvlcalculado.vlproporcional := fmnenaopossuicco;

                WHEN 44 THEN

                  vvlcalculado.vlproporcional := fmnevalorbaserateiocco;

                WHEN 45 THEN

                  vvlcalculado.vlproporcional := ffolha13saldezembro(pfolha => pfolha);

                WHEN 46 THEN

                  vvlcalculado.vlproporcional := ffolhanormaldezembrorec13sal(vvin.cdvinculo);

                WHEN 47 THEN

                  vvlcalculado.vlproporcional := fqtdiasrelvinc(pdtinicio => vvin.dtinicio,
                                                                pdtfim    => vvin.dtfim);

                  -- Atribuido ao VlReal = 30 quando foi desligado no mes para que as rubricas
                  -- rescis?rias sejam calculadas corretamente. Em alguns casos o resultado
                  -- da f?rmula estava menor ou ate negativo.
                  -- chamado 7040/2015

              IF vVin.DtFim <= pFolha.DtFimMes
                THEN

                    vvlcalculado.vlreal := 30;

                  END IF;

                WHEN 48 THEN

                  vvlcalculado.vlproporcional := fmnediasvt(pfolha,
                                                            vvin.cdvinculo,
                                                            vvin.dtinicio,
                                                            vvin.dtfim);

                WHEN 49 THEN

              vVlCalculado.vlProporcional :=

               FMesesTransPerAquisPrev(pCdVinculo               => vVin.CdVinculo,
                                                                         pdtiniciomes         => pfolha.dtiniciomes,
                                                                         pdtfimmes            => pfolha.dtfimmes,
                                                                         pcdmodalidaderubrica => vrubrica.cdmodalidaderubrica);

                WHEN 50 THEN

              vVlCalculado.vlProporcional :=

              FDiasNaoUsufridosPerConqAT(pCdVinculo        => vVin.CdVinculo,
                                                                            pdtiniciomes => pfolha.dtiniciomes,
                                                                            pdtfimmes    => pfolha.dtfimmes);

                WHEN 51 THEN

              vVlCalculado.vlProporcional :=

              FDiasNaoUsufridosPerConqAN(pCdVinculo          => vVin.CdVinculo,
                                                                            pnuanoreferencia => pfolha.nuanoreferencia,
                                                                            pnumesreferencia => pfolha.numesreferencia);

                WHEN 52 THEN

                  vvlcalculado.vlproporcional := fmnealiquotafgts;

                WHEN 53 THEN

                  vvlcalculado.vlproporcional := fmneinsssobreferias;

                WHEN 54 THEN

              vVlCalculado.vlProporcional :=

              FQtDiasFeriasNoMes(vVin.CdVinculo,
                                                                    pfolha.dtiniciomes,
                                                                    pfolha.dtfimmes);

                WHEN 55 THEN

              vVlCalculado.vlProporcional :=

               FMneQtDiasAfastMaternidade (pFolha           => pFolha,
                                                                            pcdvinculo       => vvin.cdvinculo,
                                                                            pdtiniciorelacao => PKGPAG_VAR.vgvinculo.dtadmissao,
                                                                            pdtfimrelacao    => PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                            pdtcalculo       => PKGPAG_VAR.vdtcalculo);

                WHEN 56 THEN

                  vvlcalculado.vlproporcional := 0;

                  -- SIG-28770
                  -- Chamado 14275/2019 - erro 13 CTISP em renovacao de contrato
                  for CONVAPO in (SELECT *
                                    FROM epvdconvocacaoaposentado conv
                                   WHERE conv.cdvinculo = vvin.cdvinculo
                                     AND conv.flgerarpagamento = 'S'
                                     AND conv.flanulado = 'N'
                                    AND ( to_char(conv.dtfimconvocacao,'yyyy') >= pFolha.NuAnoReferencia) OR
                                          conv.dtfimconvocacao IS NULL
                                    )

                   loop

                    vvlcalculado.vlProporcional := vvlcalculado.vlProporcional +
                                                   FMneQtMesesTrabAno(pFolha           => pFolha,
                                                                      pcdvinculo       => vvin.cdvinculo,
                                                                      pDtInicioRelacao => convapo.dtinicioconvocacao,
                                                                      pDtFimRelacao    => convapo.dtfimconvocacao,
                                                                      pdtcalculo       => PKGPAG_VAR.vdtcalculo);

                  end loop;

                  vvlcalculado.vlproporcional := LEAST(vvlcalculado.vlproporcional,12);
                  
                WHEN 57 THEN

              vVlCalculado.vlProporcional :=

               FMnePossuiDecJudicial( pCdVinculo            => vVin.CdVinculo,
                                                                       pCdRubricaAgrupamento => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                       pnuanoreferencia      => pfolha.nuanoreferencia,
                                                                       pnumesreferencia      => pfolha.numesreferencia);

                WHEN 58 THEN

                  vvlcalculado.vlproporcional := pfolha.numesreferencia;

                WHEN 59 THEN

              vVlCalculado.vlProporcional :=

              FMneQtMesesTrabAteMesRef (pFolha           => pFolha,
                                                                          pcdvinculo       => vvin.cdvinculo,
                                                                          pdtiniciorelacao => PKGPAG_VAR.vgvinculo.dtadmissao,
                                                                          pdtfimrelacao    => PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                          pdtcalculo       => PKGPAG_VAR.vdtcalculo);

                WHEN 60 THEN

                  vvlcalculado.vlproporcional := fmnechoproporcional(prubrica          => vrubrica,
                                                                     pcdrelacaovinculo => vvin.cdrelacaovinculo,
                                                                     pcdchave          => vvin.cdchave);

            WHEN 61 THEN -- CHO Semanal

              IF vVin.CdRelacaoVinculo IN (0,1,2,3,4) THEN -- Efetivo/ Comissionado / Fun??o de Chefia/ Apo

                    vvlcalculado.vlproporcional := fmnecho(pfolha.cdagrupamento,
                                                           vrubrica,
                                                           vvin.cdrelacaovinculo,
                                                           vVin.CdChave,
                                                           2);

                  ELSE

                    vvlcalculado.vlproporcional := 0;

                  END IF;

            WHEN 62 THEN -- Meses trabalhados no primeiro ano de contrato

               vVlCalculado.vlProporcional :=

                 FMneQtMesesTrabAno (pFolha           => pFolha,
                                                                    pcdvinculo       => vvin.cdvinculo,
                                                pdtiniciorelacao => CASE WHEN (PKGPAG_VAR.vgFolha.cdOrgao = 34
                                                                          AND PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 4
                                                                          AND PKGPAG_VAR.vgrelvincprincipal.dtiniciorelacao IS NULL) THEN
                                                                                 CASE WHEN PKGPAG_VAR.vgvinculo.dtAdmissao < TRUNC(PKGPAG_VAR.vgFolha.dtCalculo, 'YYYY')
                                                                                   THEN TRUNC(PKGPAG_VAR.vgFolha.dtCalculo, 'YYYY')
                                                                                  ELSE PKGPAG_VAR.vgvinculo.dtAdmissao END
                                                                         ELSE PKGPAG_VAR.vgrelvincprincipal.dtiniciorelacao END,
                                                                    pdtfimrelacao    => PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                    pdtcalculo       => PKGPAG_VAR.vdtcalculo,
                                                pflanoadmissao => CASE WHEN (PKGPAG_VAR.vgFolha.cdOrgao = 34
                                                                            AND PKGPAG_VAR.vgVinculo.CdSituacaoPrevidenciaria = 4
                                                                            AND PKGPAG_VAR.vgrelvincprincipal.dtiniciorelacao IS NULL
                                                                            AND PKGPAG_VAR.vgvinculo.dtAdmissao < TRUNC(PKGPAG_VAR.vgFolha.dtCalculo, 'YYYY'))
                                                                                    THEN 'N' -- Caso a data de inicio de relação seja em ano anterior retorna Ano admissao = 'N'
                                                                           ELSE 'S' END);

                  vnumestrab := vvlcalculado.vlproporcional;

            WHEN 63 THEN -- Valor APO Sem Paridade

                  vvlcalculado.vlproporcional := fmnevaloraposemparid(pcdvinculo => vvin.cdvinculo,
                                                                      pdtfimmes  => pfolha.dtfimmes);

                WHEN 64 THEN

                  vvlcalculado.vlproporcional := fmneiprev13sal(pcdvinculo        => vvin.cdvinculo,
                                                                pfolha            => pfolha,
                                                                pcdfolhareplicada => PKGPAG_VAR.vgcdfolhareplicada13);

            WHEN 65 THEN -- SOMAANO13

             vVlCalculado.vlProporcional :=

               FMneSomaAno13(vVin.CdVinculo,
                                                               pfolha.nuanoreferencia,
                                                               CASE
                                                                WHEN pfolha.cdagrupamento IN (2, 4, 5, 136) OR pfolha.cdtipofolha IN (3, 5) THEN
                                                                  pfolha.numesreferencia
                                                                 ELSE
                               CASE WHEN pFolha.NuMesReferencia > 1 THEN
                                                                     pfolha.numesreferencia - 1
                                                                    ELSE
                                                                     1
                                                                  END
                                                               END,
                                                               vvin.cdtipohistorico,
                                                               vvin.cdrelacaovinculo,
                                                               vvin.cdchave,
                                                               pfolha.cdagrupamento,
                                                               vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

                  WHEN 66 THEN -- Valor da Decis?o Judicial (quando esta indica que deve ser executada por f?rmula)

                  vvlcalculado.vlproporcional := fmnevalordecisaojudicial(pfolha                => pfolha,
                                                                          pcdvinculo            => vvin.cdvinculo,
                                                                          pcdrubricaagrupamento => ppagcalc.cdrubricaagrupamento,
                                                                          pnusufixorubrica      => ppagcalc.nusufixorubrica);
                  WHEN 67 THEN -- Idade da pessoa na data do c?lculo

                  vvlcalculado.vlproporcional := fmneidadepessoa(pfolha    => pfolha,
                                                                 pcdpessoa => PKGPAG_VAR.vcdpessoa);

                   WHEN 68 THEN -- CHO M?dio

                  vvlcalculado.vlproporcional := fmnechomedio(pcdrelacaovinculo => vvin.cdrelacaovinculo,
                                                              pcdchave          => vvin.cdchave,
                                                              pdtinicio         => pfolha.dtiniciomes,
                                                              pdtfim            => pfolha.dtfimmes);

                WHEN 69 THEN

                  vvlcalculado.vlproporcional := fmneafdiascorridos(pfolha,
                                                                    vvin.cdvinculo);

                  if vRubrica.NuRubrica in (327,1327) and pFolha.CdAgrupamento = 1 then
                    vVlCalculado.vlReal := 0;
                  end if;

                WHEN 71 THEN

                  vvlcalculado.vlproporcional := fmneinsspatronal(vvin.cdunidadeorganizacional);

              WHEN 72 THEN -- VlPercentReducaoSal

                  vvlcalculado.vlproporcional := PKGPAG_VAR.vgVlPercentReducao;

                WHEN 73 THEN

                  vvlcalculado.vlproporcional := fmneqtdiasafastacidente(pfolha,
                                                                         vvin.cdvinculo,
                                                                         vrubrica,
                                                                         PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                         PKGPAG_VAR.vdtcalculo);

                  vvlcalculado.vlIndice := vvlcalculado.vlProporcional;

                  vvlcalculado.vlIntegral := 30;

                  PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlIndice := vvlcalculado.vlProporcional;

              WHEN 74 THEN  -- Retorna valor medio recalculado

                  vvlcalculado.vlproporcional := nvl(fmnemediaindiceano(vvin.CdVinculo,
                                                                        vvin.cdtipohistorico,
                                                                        vvin.cdrelacaovinculo,
                                                                        vvin.cdchave,
                                                                        vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                      pFolha),0);

              WHEN 75 THEN -- Outros - MediaGratEspecSaude: Media Gratificacao Especia ART 15 MP 196/2014

                  vvlcalculado.vlproporcional := FMneMediaGratEspecSaude(vvin.cdvinculo,
                                                                       pfolha.NuAnoReferencia||LPAD(pfolha.NuMesReferencia,2,'0'));

                                                                               WHEN 76 THEN  -- Retorna valor medio recalculado

                  vvlcalculado.vlproporcional := nvl(fMneSoma12Meses(vvin.CdVinculo,
                                                                     vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                   pFolha),0);

                WHEN 77 THEN
                  -- valorMedioFerias
                  -- Retorna media do índice do período aquisitivo de férias
                  -- recalculando o valor com base na folha referencia

                  vvlcalculado.vlproporcional := nvl(fMneMediaFerias(vvin.CdVinculo,
                                                                     vvin.cdtipohistorico,
                                                                     vvin.cdrelacaovinculo,
                                                                     vvin.cdchave,
                                                                     vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                   pFolha),0);

              WHEN 78 THEN -- Quantidade de dias do Mes

                vvlcalculado.VlProporcional := pFolha.DtFimMes - pFolha.DtInicioMes + 1;

             WHEN 79 THEN -- Dias uteis do mes anterior

                vVlCalculado.vlProporcional :=

                  FMneQtDiasProxMes(pFolha,
                                                                   vvin.cdunidadeorganizacional,
                                    CASE WHEN vVin.DtInicioRelacao BETWEEN add_months(pFolha.DtInicioMes,-1)
                                                                       AND add_months(pFolha.DtFimMes,-1)
                                         THEN vvin.dtiniciorelacao
                                         ELSE add_months(pfolha.dtiniciomes,-1) END,
                                    add_months(pfolha.dtfimmes,-1));

            WHEN 80 THEN -- PossuiEnsinoMedico  Grau de escolaridade = Esino medio
                  -- 3 REGULAR
                  -- 4 PROFISSIONALIZANTE

                  IF PKGPAG_VAR.vgNuGrauEscolaridade IN (3, 4) THEN
                    vVlCalculado.vlProporcional := 1;
                    vVlCalculado.vlindice       := 1;
                  ELSE
                    vVlCalculado.vlProporcional := 0;
                  END IF;

            WHEN 81 THEN --  PossuiEnsinoSuperior  Grau de escolaridade = Esino superior
                  -- 5 GRADUACAO
                  -- 6 GRADUACAO TECNOLOGICA

                  IF PKGPAG_VAR.vgNuGrauEscolaridade IN (5, 6) THEN
                    vVlCalculado.vlProporcional := 1;
                    vVlCalculado.vlindice       := 1;
                  ELSE
                    vVlCalculado.vlProporcional := 0;
                  END IF;

            WHEN 82 THEN --  PossuiEspecializacao  Grau de escolaridade = Pos-graduacao e nivel de formacao Especializacao
                  -- 7 ESPECIALIZACAO

                  IF PKGPAG_VAR.vgNuGrauEscolaridade IN (7) THEN
                    vVlCalculado.vlProporcional := 1;
                    vVlCalculado.vlindice       := 1;
                  ELSE
                    vVlCalculado.vlProporcional := 0;
                  END IF;

            WHEN 83 THEN --  PossuiMestrado  Grau de escolaridade = Pos-graduacao e nivel de formacao Mestrado
                  -- 8 MESTRADO

                  IF PKGPAG_VAR.vgNuGrauEscolaridade IN (8) THEN
                    vVlCalculado.vlProporcional := 1;
                  ELSE
                    vVlCalculado.vlProporcional := 0;
                  END IF;

            WHEN 84 THEN --   PossuiDoutorado Grau de escolaridade = Pos-graduacao e nivel de formacao Doutorado
                  -- 9 DOUTORADO
                  -- 10  POS DOUTORADO

                  IF PKGPAG_VAR.vgNuGrauEscolaridade IN (9, 10) THEN
                    vVlCalculado.vlProporcional := 1;
                    vVlCalculado.vlindice       := 1;
                  ELSE
                    vVlCalculado.vlProporcional := 0;
                  END IF;

              --
              -- Numero de dias uteis do mes anterior, descontando feriados
              --
                WHEN 85 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                    p_tipo_retorno => 1);

              --
              -- Numero de feriados no mes anterior.
              --
                WHEN 86 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                    p_tipo_retorno => 2,
                                                                    p_cdunid       => PKGPAG_VAR.vgRelVincPrincipal.CdUnidadeOrganizacional);

              --
              -- Numero de sabados no mes anterior.
              --
                WHEN 87 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                    p_tipo_retorno => 4);

              --
              -- Numero de domingos no mes anterior
              --
                WHEN 88 THEN

               vVlCalculado.vlProporcional :=
               fQtTipoDiasPeriodo (P_DATA_INICIAL => add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1),
                                    P_DATA_FINAL => last_day( add_months(PKGPAG_VAR.vgfolha.DtInicioMes,-1)),
                                                                    p_tipo_retorno => 3);

              --
              -- Valor Subsidio Privativo da Funcao de Chefia
              --
                WHEN 89 THEN

              IF PKGPAG_VAR.vgfucsubst.count > 0 and ppagcalc.nusufixorubrica = 2 THEN

                    FOR i IN PKGPAG_VAR.vgfucsubst.FIRST .. PKGPAG_VAR.vgfucsubst.LAST
                     LOOP

                         IF PKGPAG_VAR.vgfucsubst(i).CdHistFuncaoChefia = vVin.CdHistFuncaoChefia THEN

                        vvlcalculado.vlproporcional := FMneSubsidioPrivativoFC(pfolha => pfolha,
                                                                               pfuc   => PKGPAG_VAR.vgfucsubst(i));

                      END IF;
                    END LOOP;

              ELSIF PKGPAG_VAR.vgfuc.count > 0 and ppagcalc.nusufixorubrica = 1 THEN

                     FOR i IN PKGPAG_VAR.vgFUC.FIRST .. PKGPAG_VAR.vgFUC.LAST
                     LOOP

                         IF PKGPAG_VAR.vgFUC(i).CdHistFuncaoChefia = vVin.CdHistFuncaoChefia THEN

                        vvlcalculado.vlproporcional := FMneSubsidioPrivativoFC(pfolha => pfolha,
                                                                               pfuc   => PKGPAG_VAR.vgfuc(i));

                      END IF;
                    END LOOP;

                  ELSE

                    vvlcalculado.vlproporcional := 0;

                  END IF;

              --
              -- Valor da rubrica utilizada como base limitadora maxima associada ao indice da rubrica calculada
              --
                WHEN 91 THEN

                  vVlBase930 := PKGPAG_GERAL.fretornavaloroutrasrv(pFolha.cdfolhapagamento,
                                                                   pPagCalc.CdVinculo,
                                                                   vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

                  vVlBase930.vlIndice := pPagCalc.vlindicerubrica;

              vVlBase930.vlProporcional := vVlBase930.vlProporcional * vVlBase930.vlIndice / 100;

                  vvlcalculado.vlProporcional := 1;

              -- MneVlBasePrevInstituidor
                WHEN 92 THEN

                  vVlCalculado.vlProporcional := fMneVlBasePrevInstituidor(pCdVinculo        => vvin.cdvinculo,
                                                                       pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                           pCdTipoCalculo    => pFolha.CdTipoCalculo);
                  -- MneVlTetoInstituidor
                WHEN 93 THEN

                  vVlCalculado.vlProporcional := fMneVlTetoInstituidor(pCdVinculo        => vvin.cdvinculo,
                                                                   pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                       pCdTipoCalculo    => pFolha.CdTipoCalculo);

              -- VlPercPensao
                WHEN 94 THEN

                  vVlCalculado.vlProporcional := fMneVlPercPensao(pCdVinculo        => vvin.cdvinculo,
                                                              pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia));

                  vVlCalculado.vlIntegral := fMneVlPercPensao(pCdVinculo        => vvin.cdvinculo,
                                                           pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                              pFlIntegral       => true);

              -- VlPensaoPrev
                WHEN 95 THEN

                  vVlCalculado.vlProporcional := fMneVlPensaoPrev(pCdVinculo        => vvin.cdvinculo,
                                                              pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia));

                  vVlCalculado.vlIntegral := fMneVlPensaoPrev(pCdVinculo        => vvin.cdvinculo,
                                                          pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                              pFlIntegral       => true);

              -- VlPercPensaoPrev
                WHEN 96 THEN

                  vVlCalculado.vlProporcional := fMneVlPercPensaoPrev(pCdVinculo        => vvin.cdvinculo,
                                                                  pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                      pCdTipoCalculo    => pFolha.CdTipoCalculo);

              -- VlPercIntegralidade
                WHEN 98 THEN
                  vvlcalculado.vlProporcional := fMneVlPercIntegralidade(pCdVinculo        => vvin.cdvinculo,
                                                              pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia));

              -- Quantidade de dias com carga horaria zerada.
                WHEN 100 THEN
                  vvlcalculado.vlProporcional := fmneQtDiasChoZero;

              -- Retorna 0 ou 1 se possui valor no mnemmonico SOMAANO
                WHEN 101 THEN
               vVlCalculado.vlProporcional :=

               fmnePossuiValorAno(vVin.CdVinculo,
                                                                    pfolha.nuanoreferencia,
                                                                    CASE
                                     WHEN pfolha.cdagrupamento IN (2, 4, 5, 6, 136) OR pfolha.cdtipofolha IN (3, 5) THEN
                                                                       pfolha.numesreferencia
                                                                      ELSE
                                        CASE WHEN pFolha.NuMesReferencia > 1 THEN
                                                                          pfolha.numesreferencia - 1
                                                                         ELSE
                                                                          1
                                                                       END
                                                                    END,
                                                                    vvin.cdtipohistorico,
                                                                    vvin.cdrelacaovinculo,
                                                                    vvin.cdchave,
                                                                    pfolha.cdagrupamento,
                                                                    vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

             WHEN 103 THEN -- Outros - SomaFolhasMesAnt

                  vvlcalculado.vlproporcional := nvl(fMneSomaOutrasFolhasMes(vvin.CdVinculo,
                                                                             vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                          pFolha,'S'),0);

            when 104 then -- Indice Rubrica Outros MNEMONICOS

                  vvlcalculado.vlProporcional := fmneindicerubrica(vvin.CdVinculo,
                                                                   vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento);

                when 105 then

              if vvin.cdrelacaovinculo = 1 then-- Remuneracao base de outras esferas

                    vvlcalculado.vlProporcional := fmneRemunBaseOutraEsfera(vVin.cdvinculo);

                  else

                    vvlcalculado.vlProporcional := 0;

                  end if;

              when 106 then -- E equivalente ao SomaAno porem, somando de todos os vinculos do ano.
                  -- *Todos os Vinculos do ano.
                  IF PKGPAG_VAR.vgVinculo.dtdesligamento IS NOT NULL AND
                      PKGPAG_VAR.vgVinculo.dtdesligamento BETWEEN pFolha.DtInicioMes AND pFolha.DtFimMes
                      THEN

                       vVlCalculado.vlProporcional :=
                          FMneVlRubTodosVinculos(pCdPessoa        => PKGPAG_VAR.vCdPessoa,
                                                                          pcdfolhapagamento     => pFolha.CdFolhaPagamento,
                                                                          pCdRubricaAgrupamento => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                          pnuanoreferencia      => pfolha.nuanoreferencia);
                  END IF;

                WHEN 110 THEN
                  vVlCalculado.vlProporcional := fMneRubrica13FolhaNormal(pCdVinculo            => vvin.cdvinculo,
                                                                          pCdRubricaAgrupamento => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                          pNuAnoReferencia      => pFolha.NuAnoReferencia,
                                                                          pNuMesReferencia      => pFolha.NuMesReferencia);

                when 111 then
                  vVlCalculado.vlProporcional := fMneSomaAnoRubrica(pCdVinculo            => vvin.cdvinculo,
                                                                    pCdRubricaAgrupamento => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                    pFolha                => pFolha);

              -- MneVlBaseMilitarInstituidor
                WHEN 112 THEN

                  vVlCalculado.vlProporcional := fMneVlBaseMilitarInstituidor(pCdVinculo        => vvin.cdvinculo,
                                                                          pAnoMesReferencia => (pFolha.NuAnoReferencia*100 + pFolha.nuMesReferencia),
                                                                              pCdTipoCalculo    => pFolha.CdTipoCalculo);

                when 113 then


                vVlCalculado.vlProporcional :=
                    fmnevlanooutrosvinculos(PKGPAG_VAR.vgvinculo.cdpessoa,
                                                                         PKGPAG_VAR.vgvinculo.cdvinculo,
                                                                         vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                         pFolha.NuAnoReferencia);

                WHEN 114 THEN

                  vvlcalculado.vlproporcional := fmneNaoAfastDefinNoMes(PKGPAG_VAR.vgvinculo.cdvinculo,
                                                                        pFolha.NuMesReferencia,
                                                                        pFolha.NuAnoReferencia);
                  /*
                  WHEN 115 THEN

                      vvlcalculado.vlproporcional := fmneVlConsigsFuturas(PKGPAG_VAR.vgvinculo.cdvinculo,
                                                                          pFolha.NuMesReferencia,
                                                                          pFolha.NuAnoReferencia);
                   */

                WHEN 116 THEN
                  -- ValorRubMediaFerias
                  -- Retorna media do valor no período de férias

                  vvlcalculado.vlproporcional := nvl(fMneMediaFerias(vvin.CdVinculo,
                                                                     vvin.cdtipohistorico,
                                                                     vvin.cdrelacaovinculo,
                                                                     vvin.cdchave,
                                                                     vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                   pFolha),0);

             WHEN 117 THEN -- Quantidade de dias corridos do mes anterior ao processamento da folha, limitado ao parametro passado

                vvlcalculado.VlProporcional := PKGPAG_FB.fMneQtdDiasMesAnterior(pFolha.DtCalculo, 30);

             WHEN 118 THEN

                vvlcalculado.vlproporcional := fmneqtdiasremimpeditivos(pfolha,
                                                                        vvin.cdvinculo,
                                                                        vrubrica,
                                                                        PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                        PKGPAG_VAR.vdtcalculo);

                vvlcalculado.vlIndice := vvlcalculado.vlProporcional;
               
            when 119 THEN

                vvlcalculado.VlProporcional :=FMneSomaAnoRubTodosVinculosINSS(PKGPAG_VAR.vgVinculo.CdPessoa,
                                                                              pFolha.CdFolhapagamento,
                                                                              vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                              pFolha.NuAnoReferencia);

            when 120 then

                vVlContribuicao := 0;

                vvlcalculado.VlProporcional := fmneAliquotaProgressivaINSS(PKGPAG_VAR.vAliqINSS.lFaixa,
                                                                           vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                           vVlContribuicao);


             WHEN 121 THEN -- DiasUtAfastRemImp

                vvlcalculado.vlproporcional := fmneqtdiasremimpeditivosuteis(pfolha,
                                                                             vvin.cdvinculo,
                                                                             vrubrica,
                                                                             PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                             PKGPAG_VAR.vdtcalculo);

                vvlcalculado.vlIndice := vvlcalculado.vlProporcional;

                vvlcalculado.vlIntegral := 30;

            WHEN 122 THEN -- DiasUtAfaRemImpRet

                vvlcalculado.vlproporcional := fmneqtdiasremimpedsuteisret(pfolha,
                                                                           vvin.cdvinculo,
                                                                           vrubrica,
                                                                           PKGPAG_VAR.vgvinculo.dtdesligamento,
                                                                           PKGPAG_VAR.vdtcalculo);

                vvlcalculado.vlIndice := vvlcalculado.vlProporcional;

                vvlcalculado.vlIntegral := 30;

            WHEN 123 Then

              vvlcalculado.vlproporcional :=

              FMneSomaRubMesOutrosVinculos(PKGPAG_VAR.vgVinculo.CdPessoa,
                                           vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                           pFolha);

              vvlcalculado.vlIndice := vvlcalculado.vlProporcional;

              vvlcalculado.vlIntegral := 30;

            WHEN 124 then

              vvlcalculado.vlproporcional := fMnePercentAdiantFerias(pCdVinculo => vvin.cdvinculo,
                                                                     pNuAno => pFolha.NuAnoReferencia,
                                                                     pNuMes => pFolha.NuMesReferencia);                                                                                  

            WHEN 125 THEN
              
              vvlcalculado.vlproporcional := fMnePossuiIsencaoIRRFRub(pCdVinculo            => vvin.cdvinculo,
                                                                      pCdRubricaAgrupamento => vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento,
                                                                      pNuAnoReferencia      => pFolha.NuAnoReferencia,
                                                                      pNuMesReferencia      => pFolha.NuMesReferencia);
            
            WHEN 126 THEN
              
              vvlcalculado.vlproporcional := fmneRetornaValorRub(pFolha.CdFolhaPagamento, 
                                                                 vvin.cdvinculo, 
                                                                 vVin.lFormCalculo.lBloco(j).lExpressao(k).CdRubricaAgrupamento);                                                           
                                                                 
            WHEN 127 THEN --CCOPuro
              
              vvlcalculado.vlproporcional := fmneCCOPuro(PKGPAG_VAR.vgcco,
                                                         PKGPAG_VAR.vgcef);  
            WHEN 128 THEN --Opc70
              
              vvlcalculado.vlproporcional := fmneOPC70(pFolha.CdFolhaPagamento, 
                                                       vvin.cdvinculo);                                                                  
            ELSE

                NULL;

            END CASE;

            IF vvlcalculado.vlintegral IS NULL THEN
                vvlcalculado.vlintegral := vvlcalculado.vlproporcional;
            END IF;

              IF vvlcalculado.vlreal IS NULL THEN
                vvlcalculado.vlreal := vvlcalculado.vlIntegral;
              END IF;

              vvin.lformcalculo.lbloco(j).lexpressao(k).vlresultado := vvlcalculado;

          vDeExpressao.DeExprProporcional :=
                  vDeExpressao.DeExprProporcional ||
                  vVin.lFormCalculo.lBloco(j).lExpressao(k).DeOperacao||
                                                 vvlcalculado.vlproporcional;

          vDeExpressao.DeExprIntegral :=
                  vDeExpressao.DeExprIntegral ||
                  vVin.lFormCalculo.lBloco(j).lExpressao(k).DeOperacao||
                                             vvlcalculado.vlintegral;

          vDeExpressao.DeExprReal :=
                  vDeExpressao.DeExprReal ||
                  vVin.lFormCalculo.lBloco(j).lExpressao(k).DeOperacao||
                                         vVlCalculado.vlReal;

            END LOOP;

          EXCEPTION

            WHEN OTHERS THEN

              PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                                      PKGPAG_VAR.vCdHistParamCalc,
                                      PKGPAG_VAR.vcdpessoa,
                                      'Erro ao processar formulas de calculo da rubrica ' ||
                                      LPAD(vRubrica.CdTipoRubrica,2,'0') || '-' || LPAD(vRubrica.NuRubrica,4,'0') ||
                                      ' Express?o: ' || vDeFormula.DeExprProporcional,
                                      PKGPAG_VAR.vgcdvinculo);

          END;
          -----SIG-10443
          IF pPagCalc.CdRubricaAgrupamento = PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,0571)
             AND
             PKGPAG_LF.FPossuiLancamentoFinanceiro(PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,8,0193))
             AND
             PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                               pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                               pCdRubrica => PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,8,0193)) = 0
          THEN
                      BEGIN
                        select ss.vllancamentofinanceiro,ss.cdlancamentofinanceiro
                          into VvalorLancamento08193, Vcdlancamento08193
                         from   epaglancamentofinanceiro  ss
                         where cdvinculo = PKGPAG_VAR.vgCdVinculo
                           and ss.dtiniciodireito >= pfolha.DtInicioMes
                           and (ss.dtfimdireito <= pfolha.DtFimMes or ss.dtfimdireito is null)
                           and PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.Cdagrupamento,8,0193) = ss.cdrubricaagrupamento;
                      EXCEPTION when others then
                          VvalorLancamento08193 := 0;
                      END;

                     PKGPAG_GERAL.PInsereLancamentoVinculo(pCdFolhaPagamento      => pFolha.CdFolhaPagamento,
                                                          pCdVinculo              => PKGPAG_VAR.vgcdvinculo,
                                                          pCdExpressaoFormCalc    => NULL,
                                                          pCdRubricaAgrupamento   => PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,8,0193),
                                                          pNuSufixoRubrica        => 1,
                                                          pVlPagamento            => VvalorLancamento08193,
                                                          pVlIndice               => VvalorLancamento08193,
                                                          pCdLancamentoFinanceiro => Vcdlancamento08193,
                                                          pCdTipoOrigemRubrica    => 11);
         END IF;

          if vRubrica.CdRubricaAgrupamento = PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,0914) and
             PKGPAG_VAR.vgcef.count > 0 and
             PKGPAG_VAR.vgcef(1).CdRegimePrevidenciario = 2 and
             PKGPAG_VAR.vgcef(1).CdSituacaoPrevidenciaria = 1 and
             pkgpag_geral.FRetornaRegimeProprioPrev(vvin.cdvinculo) in (3,4) and
             pfolha.CdTipoFolha = PKGPAG_TIPO.cnTpFolhaNormal then

              VtetoInss := pkgpag_geral.FRetornaAliquotaINSS(pFolha.NuAnoReferencia,pFolha.NuMesReferencia);

                if vVlCalculado.vlProporcional > VtetoInss.vlteto then
                   vDeExpressao.DeExprProporcional:= VtetoInss.vlteto;
                end if;

          end if;

          IF vvin.lformcalculo.lbloco(j).fllimiteparcial = 'S'
            THEN
            -- 10001/2017 - FOLHA - GRATIFICACAO 01-0022 FCEE -- MARRETACO
              IF vRubrica.CdRubricaAgrupamento = 10267
                AND PKGPAG_VAR.vgCef.Count > 0 AND PKGPAG_VAR.vgApo.Count > 0
                AND PKGPAG_VAR.vgApo(1).DtInicio > PKGPAG_VAR.vgFolha.DtInicioMes

             THEN
                  IF vvin.cdrelacaovinculo = 1
                    THEN

                vDeExpressao.DeExprProporcional := PKGPAG_VAR.vgValorCalculoRubrica(10267).VlCef;

                  ELSIF vvin.cdrelacaovinculo = 4
                     THEN

                vDeExpressao.DeExprProporcional := PKGPAG_VAR.vgValorCalculoRubrica(10267).VlApo;

              else
                null;
              END IF;

            ELSE

                  vDeExpressao.DeExprProporcional :=
                    FRetornaValorLimiteParcial(vVin.lFormCalculo,fcalcexpressao(vdeexpressao.deexprproporcional));

                  vDeExpressao.DeExprReal :=
                    FRetornaValorLimiteParcial(vVin.lFormCalculo,fcalcexpressao(vdeexpressao.deexprreal));

                  vDeExpressao.DeExprIntegral :=
                    FRetornaValorLimiteParcial(vVin.lFormCalculo,fcalcexpressao(vdeexpressao.deexprintegral));

            END IF;

          END IF;

          vDeFormula.DeExprProporcional := '(' || REPLACE(vDeFormula.DeExprProporcional ,
                                                   vVin.lFormCalculo.lBloco(j).SgBloco,
                                                   vdeexpressao.deexprproporcional) || ')';

          vDeFormula.DeExprIntegral     := '(' || REPLACE(vDeFormula.DeExprIntegral,
                                               vVin.lFormCalculo.lBloco(j).SgBloco,
                                               vdeexpressao.deexprintegral) || ')';

          vDeFormula.DeExprReal         := '(' || REPLACE(vDeFormula.DeExprReal,
                                           vVin.lFormCalculo.lBloco(j).SgBloco,
                                           vDeExpressao.DeExprReal) || ')';

        END IF;

      END LOOP;

    END IF;
    -----SIG-10443
    IF pPagCalc.CdRubricaAgrupamento = PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,5,0571)
       AND
       PKGPAG_LF.FPossuiLancamentoFinanceiro(PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,8,0193))
       AND
       PKGPAG_GERAL.fretornavalorrubrica(pcdfolhapagamento => PKGPAG_VAR.vgFolha.CdFolhaPagamento,
                                         pCdVinculo => PKGPAG_VAR.vgCdVinculo,
                                         pCdRubrica => PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,8,0193)) > 0
    THEN
       DELETE epaghistoricorubricavinculo hv
        WHERE hv.cdvinculo = PKGPAG_VAR.vgcdvinculo
          AND hv.cdfolhapagamento =  PKGPAG_VAR.vgfolha.cdfolhapagamento
          AND hv.cdrubricaagrupamento = PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,8,0193)
          AND hv.cdlancamentofinanceiro =nvl(Vcdlancamento08193,0);

    END IF;

    -- Folha funebre: algumas rubricas devem considerar valores reias
    IF PKGPAG_VAR.vgFolha.cdtipofolha = PKGPAG_TIPO.cnTpFolhaFunebre AND
     vRubrica.CdRubricaAgrupamento in ( 10730, -- 01-0085
        37575) THEN

      vDeFormula.DeExprProporcional := vDeFormula.DeExprReal;
      vDeFormula.DeExprIntegral     := vDeFormula.DeExprReal;

    END IF;

    IF vRubrica.CdRubricaAgrupamento in (43020, 45413) AND
       PKGPAG_VAR.vgFolha.cdtipofolhapagamento = 786 AND
       vvin.cdvinculo In (613241, 613962) then
      vDeFormula.DeExprReal         := 0;
      vDeFormula.DeExprProporcional := 0;
      vDeFormula.DeExprIntegral     := 0;

    END IF;

    -- 01-0023 e 01-0027 não devem ser geradas na folha Honorarios PGE
  IF (PKGPAG_VAR.vgFolha.cdtipofolhapagamento in (1505,1525,1526)
     or PKGPAG_VAR.vgFolha.cdTipoFolha in (pkgpag_tipo.cnTpFolhaProdex13, pkgpag_tipo.cnTpFolhaHonorarios13, pkgpag_tipo.cnTpFolhaHonorarProcuradores13))
     AND vRubrica.CdRubricaAgrupamento IN (10339,8469)
  THEN
      vDeFormula.DeExprReal         := 0;
      vDeFormula.DeExprProporcional := 0;
      vDeFormula.DeExprIntegral     := 0;
    END IF;


  IF vVin.cdTipoHistorico = 1 THEN -- Na rela??o de vinculo, integral e proporcional

      IF vvin.lformcalculo.fldesprezapropchorubrica = pkgpag_tipo.cns THEN

        vrubrica.cdrubproporcionalidadecho := 1;

        vrubrica.flpropservrelvinc := 'N';

      END IF;

      -- Calcula Expressao matem?tica

      vvlcalculado := favaliaexpressao(vdeformula, vRubrica.CdRubricaAgrupamento);
      --
      --  SIG-2541 14137/2019 - REGRA DE ARREDONDAMENTO - DESCONTO E PATRONAL SCPREV
      --

      if vRubrica.NuRubrica = 1925 and vRubrica.CdTipoRubrica = 5 then

        vvlcalculado.vlIntegral := trunc(vvlcalculado.vlIntegral, 2);

        vvlcalculado.vlProporcional := trunc(vvlcalculado.vlProporcional, 2);

        vvlcalculado.vlReal := trunc(vvlcalculado.vlReal, 2);

      end if;

      vVlIndice050802 := vvlcalculado.vlindice;

      vvlcalculado.vlindice := NULL;

      -- Verifica se os valores divergem

      bVlExprIgualIntegral := (vVlCalculado.vlProporcional = vVlCalculado.vlIntegral);

      bVlExprIgualReal     := (vVlCalculado.vlProporcional = vVlCalculado.vlReal);

      vvlexpr.vlintegral     := NULL;
      vvlexpr.vlproporcional := NULL;
      vvlexpr.vlindice       := NULL;

      -- Trata Relacoes

      CASE vvin.cdrelacaovinculo

      WHEN 1 THEN -- Cargo Efetivo

          IF PKGPAG_VAR.vgcef.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
          LOOP

              IF vVin.CdHistCargoEfetivo = PKGPAG_VAR.vgCEF(i).CdHistRelVinc THEN

                -- 10001/2017 - FOLHA - GRATIFICACAO 01-0022 FCEE
                IF vRubrica.CdRubricaAgrupamento in (8864,10267)
                   AND PKGPAG_VAR.vgCef.Count > 0 AND PKGPAG_VAR.vgApo.Count > 0
                   AND PKGPAG_VAR.vgApo(1).DtInicio > PKGPAG_VAR.vgFolha.DtInicioMes

                 THEN
                  vvlexpr := vvlcalculado;
                ELSE
                  -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria
                  vvlexpr := fcalculaproporcao(pfolha            => pfolha,
                                               prubrica          => vrubrica,
                                               pcef              => PKGPAG_VAR.vgcef(i),
                                               pvlcalculado      => vvlcalculado,
                                               pflexprigualinteg => bvlexprigualintegral,
                                               pflexprigualreal  => bvlexprigualreal,
                                               pnucho            => PKGPAG_VAR.vgvalorfixocef.nucargahoraria,
                                               pdtcalculo        => PKGPAG_VAR.vdtcalculo);

                  --  SIG-449 12948/2018 - CALCULO AUTOMATICO DO IPREV NA APOSENTADORIA - 01-0505
                  --  SIG-448 12947/2018 CALCULO AUTOMATICO DO IPREV NA APOSENTADORIA - RUBRICAS 01-0108 E 01-0180
                   if vVlExpr.vlIntegral < vvlexpr.vlProporcional
                      AND PKGPAG_VAR.vgCef.Count > 0 AND PKGPAG_VAR.vgApo.Count > 0
                      AND PKGPAG_VAR.vgApo(1).DtInicio > PKGPAG_VAR.vgFolha.DtInicioMes
                      and vRubrica.NuRubrica in (108, 180, 505)
                      and vRubrica.CdTipoRubrica = 1 then

                    vVlExpr.vlIntegral := vvlexpr.vlProporcional;

                  end if;

                END IF;
              END IF;
            END LOOP;
            --
            -- Correcao para quando calcula pela relacao mas tem desligamento no mes anterior
            -- para rubricas que utilizam o valor real como as rescisorias.
            -- Rubrica 01-0332
            --
          ELSIF vvin.cdhistcargoefetivo is not null
            and PKGPAG_VAR.vgvinculo.dtdesligamento < PKGPAG_VAR.vgfolha.dtiniciomes
            and ppagcalc.cdrubricaagrupamento = 37561
            THEN

            vvlexpr := vvlcalculado;

          else
            null;
          END IF;

      WHEN 2 THEN -- Cargo comissionado

          IF PKGPAG_VAR.vgcco.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgCCO.FIRST .. PKGPAG_VAR.vgCCO.LAST
          LOOP

              IF PKGPAG_VAR.vgcco(i).cdhistcargocom = vvin.cdhistcargocom
                THEN

                -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria
                vvlexpr := fcalculaproporcao(pfolha            => pfolha,
                                             prubrica          => vrubrica,
                                             pcco              => PKGPAG_VAR.vgcco(i),
                                             pvlcalculado      => vvlcalculado,
                                             pflexprigualinteg => bvlexprigualintegral,
                                             pflexprigualreal  => bvlexprigualreal);

                 IF NVL(vVlSubst.vlProporcional, 0) > 0
                   AND ppagcalc.cdrubricaagrupamento = 37847 --(01-0279 2101 Defensoria)
                 THEN

                   IF vvlexpr.vlIndice = 30
                     THEN

                     vvlexpr.vlProporcional := vvlexpr.vlProporcional * (vvlexpr.vlIndice - vVlSubst.vlIndice)/30;
                     vvlexpr.vlIndice := vvlexpr.vlIndice - vVlSubst.vlIndice;
                  END IF;

                END IF;

              END IF;

            END LOOP;

          END IF;

          IF PKGPAG_VAR.vgccosubst.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgCCOSubst.FIRST .. PKGPAG_VAR.vgCCOSubst.LAST
          LOOP

            IF PKGPAG_VAR.vgCCOSubst(i).CdHistCargoCom = vVin.CdHistCargoCom THEN

                -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria

                vvlexpr := fcalculaproporcao(pfolha            => pfolha,
                                             prubrica          => vrubrica,
                                             pcco              => PKGPAG_VAR.vgccosubst(i),
                                             pvlcalculado      => vvlcalculado,
                                             pflexprigualinteg => bvlexprigualintegral,
                                             pflexprigualreal  => bvlexprigualreal);

                vVlSubst := vvlexpr;

              END IF;

            END LOOP;

          END IF;

      WHEN 3 THEN -- Fun??o de chefia

          IF PKGPAG_VAR.vgfuc.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgFUC.FIRST .. PKGPAG_VAR.vgFUC.LAST
          LOOP

            IF PKGPAG_VAR.vgFUC(i).CdHistFuncaoChefia = vVin.CdHistFuncaoChefia THEN

                -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria

                vvlexpr := fcalculaproporcao(pfolha            => pfolha,
                                             prubrica          => vrubrica,
                                             pfuc              => PKGPAG_VAR.vgfuc(i),
                                             pvlcalculado      => vvlcalculado,
                                             pflexprigualinteg => bvlexprigualintegral,
                                             pflexprigualreal  => bvlexprigualreal);

              END IF;

            END LOOP;

          END IF;

          IF PKGPAG_VAR.vgfucsubst.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgFUCSubst.FIRST .. PKGPAG_VAR.vgFUCSubst.LAST
          LOOP

            IF PKGPAG_VAR.vgFUCSubst(i).CdHistFuncaoChefia = vVin.CdHistFuncaoChefia THEN

                -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria

                vvlexpr := fcalculaproporcao(pfolha            => pfolha,
                                             prubrica          => vrubrica,
                                             pfuc              => PKGPAG_VAR.vgfucsubst(i),
                                             pvlcalculado      => vvlcalculado,
                                             pflexprigualinteg => bvlexprigualintegral,
                                             pflexprigualreal  => bvlexprigualreal);

              END IF;

            END LOOP;

          END IF;

      WHEN 4 THEN -- Aposentado

          -- Aposentado com paridade

          IF PKGPAG_VAR.vgapo.count > 0 THEN

          FOR i IN PKGPAG_VAR.vgAPO.FIRST .. PKGPAG_VAR.vgAPO.LAST
          LOOP

            IF PKGPAG_VAR.vgAPO(i).CdHistRelVinc = vVin.CdConcessaoAposentadoria THEN

                vcdbaseincorporacaoativo := 0;

                IF ppagcalc.cdincorporacaoativo IS NOT NULL THEN

                  SELECT ia.cdbaseincorporacaoativo
                    INTO vcdbaseincorporacaoativo
                    FROM ebpcincorporacaoativo ia
                 WHERE IA.CdIncorporacaoAtivo = pPagCalc.CdIncorporacaoAtivo;

                END IF;

                IF  vcdbaseincorporacaoativo <> 7
                    OR (vcdbaseincorporacaoativo = 7
                    AND PKGPAG_VAR.vgapo.count > 0
                    AND PKGPAG_VAR.vgapo(1).dtinicio > PKGPAG_VAR.vgfolha.dtiniciomes
                    AND ppagcalc.cdrubricaagrupamento = 10363)

                 THEN

                  -- 10001/2017 - FOLHA - GRATIFICACAO 01-0022 FCEE
                   IF vRubrica.CdRubricaAgrupamento in (8864,10267)
                     AND PKGPAG_VAR.vgCef.Count > 0 AND PKGPAG_VAR.vgApo.Count > 0
                     AND PKGPAG_VAR.vgApo(1).DtInicio > PKGPAG_VAR.vgFolha.DtInicioMes

                   THEN
                    vvlexpr := vvlcalculado;

                    -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria
                  ELSE
                    vvlexpr := fcalculaproporcao(pfolha            => pfolha,
                                                 prubrica          => vrubrica,
                                                 papo              => PKGPAG_VAR.vgapo(i),
                                                 pvlcalculado      => vvlcalculado,
                                                 pflexprigualinteg => bvlexprigualintegral,
                                                 pflexprigualreal  => bvlexprigualreal);
                  END IF;

                ELSE

                  vvlexpr.vlintegral := vvlcalculado.vlintegral;

                  vvlexpr.vlreal := vvalorpagamento.vlreal;

                  vvlexpr.vlproporcional := vvlcalculado.vlproporcional;

                END IF;

              END IF;

            END LOOP;

          END IF;

          -- Aposentado sem paridade

          IF PKGPAG_VAR.vgaposemparidade.count > 0 THEN

            IF vrubrica.flpagaaposemparidade = 'N' THEN

              vvlexpr.vlintegral     := 0;
              vvlexpr.vlproporcional := 0;
              vvlexpr.vlreal         := 0;
              vvlexpr.vlindice       := 0;
            ELSE
              vvlexpr := vvlcalculado;
            END IF;

          END IF;

        WHEN 5 THEN

          vvlexpr := vvlcalculado; -- Vale o Calculado

        WHEN 6 THEN  -- Pensao Previdenciaria

          vVlExpr.vlIndice := PKGPAG_GERAL.fretornaindice('S',pFolha.DtInicioMes,pFolha.DtFimMes,vVin.dtinicio,vVin.dtfim);

          /*IF vvlexpr.VlIndice < 30
            THEN
              vVlExpr.vlProporcional := vvlcalculado.vlIntegral / 30 * vVlExpr.vlIndice;
              vVlExpr.vlReal := vvlcalculado.vlReal;
              vVlExpr.vlIntegral := vVlExpr.vlProporcional;
          ELSE*/
          vvlexpr := vvlcalculado; -- Vale o Calculado
      --END IF;

        WHEN 7 THEN

          -- Aposentado com paridade

          IF PKGPAG_VAR.vgpensaonaoprev.count > 0 THEN

           FOR i IN PKGPAG_VAR.vgPensaoNaoPrev.FIRST .. PKGPAG_VAR.vgPensaoNaoPrev.LAST
           LOOP

             IF PKGPAG_VAR.vgPensaoNaoPrev(i).CdHistPensaoNaoPrev = vVin.CdHistPensaoNaoPrev THEN

                -- Executa a fun??o para realizar a proporcionalidade da carga hor?ria

                vvlexpr := fcalculaproporcao(pfolha            => pfolha,
                                             prubrica          => vrubrica,
                                             ppnp              => PKGPAG_VAR.vgpensaonaoprev(i),
                                             pvlcalculado      => vvlcalculado,
                                             pflexprigualinteg => bvlexprigualintegral,
                                             pflexprigualreal  => bvlexprigualreal);

              END IF;

            END LOOP;

          END IF;

      END CASE;

     if vRubrica.CdRubricaAgrupamento = PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,0914) and
        PKGPAG_VAR.vgDtInicioConcessaoAbonoPerm > pFolha.DtInicioMes then

         vvlexpr.vlProporcional := trunc(vvlexpr.vlProporcional / 30 *
                                  (30 - to_char(PKGPAG_VAR.vgDtInicioConcessaoAbonoPerm-1,'dd')),2);

         vvlexpr.vlIndice := (30 - to_char(PKGPAG_VAR.vgDtInicioConcessaoAbonoPerm-1,'dd')) ;

     end if;


    IF pPagCalc.CdIncorporacaoAtivo IS NOT NULL /*AND vVin.CdTipoValor = 2*/ THEN -- Comentado em 09/07/2009

       IF PKGPAG_VAR.vgRubrica(pPagCalc.CdRubricaAgrupamento).FlConsolidaRubrica = PKGPAG_TIPO.cnN THEN

          vvlminrecebincorp := ppagcalc.vlminrecebincorp;

          -- Proporcionaliza a carga hor?ria caso seja CEF

          IF PKGPAG_VAR.vgcef.count > 0 THEN

           FOR i IN PKGPAG_VAR.vgCEF.FIRST .. PKGPAG_VAR.vgCEF.LAST
           LOOP

              IF PKGPAG_VAR.vgcef(i).cdhistrelvinc = vvin.cdhistcargoefetivo THEN

               IF PKGPAG_VAR.vgCEF(i).NuCargaHoraria <> PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria AND
                  PKGPAG_VAR.vgRubrica(pPagCalc.CdRubricaAgrupamento).FlCargaHorariaLimitada = 'N' THEN

                 vVlMinRecebIncorp :=

                    vVlMinRecebIncorp / PKGPAG_VAR.vgValorFixoCEF.NuCargaHoraria * PKGPAG_VAR.vgCEF(i).NuCargaHoraria;

                END IF;

              END IF;

            END LOOP;

          END IF;

          --Caso o servidor teNha mais de uma relacao de vinculo ativo no mes, permite proporcionalizar.
          IF PKGPAG_VAR.vgcef.count > 0 and PKGPAG_VAR.vgapo.count > 0 THEN

            vvlexpr.vlproporcional := vvlexpr.vlproporcional;
            vvlexpr.vlintegral     := vvlexpr.vlproporcional;
            vvlindicerubrica       := vvlexpr.vlindice;

            --Atualiza a formula
            vdeformula.deexprproporcional := REPLACE(vDeFormula.DeExprProporcional,
                                          vvlminrecebincorp,  TRUNC(vvlexpr.vlproporcional, 2));

          ELSIF vvlminrecebincorp > vvlexpr.vlproporcional THEN

            vvlexpr.vlproporcional := vvlminrecebincorp;

          else
            null;
          END IF;

          IF vvlminrecebincorp > vvlexpr.vlreal THEN

            vvlexpr.vlreal := vvlminrecebincorp;

          END IF;

          IF vvlminrecebincorp > vvlexpr.vlintegral THEN

            vvlexpr.vlintegral := vvlminrecebincorp;

          END IF;

          pkgpag_ia.patualizavalorincorporacao(ppagcalc.cdvinculo,
                                               pfolha.nuanoreferencia,
                                               pfolha.numesreferencia,
                                               ppagcalc.cdincorporacaoativo,
                                               ppagcalc.flatualizacaoconstante,
                                               ppagcalc.flvigenciapagamento,
                                               case when vvlminrecebincorp > vvlexpr.vlproporcional then  vvlexpr.vlproporcional
                                                 else vvlminrecebincorp end,
                                               vvlexpr.vlintegral);

        END IF;

      END IF;

      -----------------------------------------------------------------------------------------
      -- PROPORCIONALIZA O LANCAMENTO FINANCEIRO que n?o possui valor de ?ndice
      -- Caso o registro advenha de lan?amento financeiro e indique que paga valor proporcional
      -- (quando inicia ou finaliza no mes)
      ----------------------------------------------------------------------------------------
      IF ppagcalc.cdlancamentofinanceiro IS NOT NULL THEN

      IF PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).FlValorProporcional = 'S' AND
         PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).VlIndice IS NULL AND
         (
           NOT (PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtInicio = pFolha.DtInicioMes AND
                PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtFim  = pFolha.DtFimMes )
         )  THEN

         vVlExpr.vlProporcional :=  vVlExpr.vlProporcional
                          * (  PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtFim
                              - PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtInicio + 1)/30;

         vVlExpr.vlIntegral :=  vVlExpr.vlIntegral
                          * (  PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtFim
                              - PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtInicio + 1)/30;

         vVlExpr.Vlindice :=  PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtFim
                              - PKGPAG_VAR.vgLancFinanceiro(pPagCalc.CdLancamentoFinanceiro).DtInicio + 1;

        END IF;

      END IF;

      --
      -- Tratamento EPAGRI Base 09-0930 que tem limite e deve considerar todas as relacoes de vinculo.
      --                   Rubricas: 05-0719; 05-0698; 05-0722; 05-0800;
      --
      IF vrubrica.CdRubricaAgrupamento in (44574,43415,43422,45430,48193,48295,43441)
         and vvlexpr.vlIntegral > 0 and nvl(pExprForm.NuQtDelimiteSupFinal,0) > 0
         and PKGPAG_VAR.vgcef.count > 0 and PKGPAG_VAR.vgfuc.count > 0

       THEN

          if vvlexpr.vlIntegral > nvl(pExprForm.NuQtDelimiteSupFinal,0)
            then
          vvlexpr.vlIntegral := nvl(pExprForm.NuQtDelimiteSupFinal, 0);
        end if;

          if vvin.cdchave = PKGPAG_VAR.vgcef(1).cdhistcargoefetivo and
            PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef Is Null
          then
          PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef := vvlexpr.vlIntegral;
        end if;

          if nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef,0) > 0
             and PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlFuc Is Null
             and vvin.cdchave = PKGPAG_VAR.vgfuc(1).cdhistfuncaochefia
            then

             if (PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef + vvlexpr.vlIntegral) >
             (pExprForm.NuQtDelimiteSupFinal)

           then
                  if PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef <
                     (pExprForm.NuQtDelimiteSupFinal)
                    then
              vvlexpr.vlIntegral     := (pExprForm.NuQtDelimiteSupFinal) - PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef;
              vvlexpr.vlReal         := (pExprForm.NuQtDelimiteSupFinal) - PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef;
              vvlexpr.vlProporcional := (pExprForm.NuQtDelimiteSupFinal) - PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef;
            else
              vvlexpr.vlIntegral     := 0;
              vvlexpr.vlReal         := 0;
              vvlexpr.vlProporcional := 0;
            end if;

          end if;

        else

             vvlexpr.vlreal := case when vvin.cdchave = PKGPAG_VAR.vgfuc(1).cdhistfuncaochefia
                                    then PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlFuc
                                    else PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef
                            end;

          vvlexpr.vlintegral := vvlexpr.vlreal;

          vvlexpr.vlproporcional := vvlexpr.vlreal;

        end if;

      ELSIF vVlBase930.VlProporcional > 0
         THEN

        --
        -- Calculando Funcao de Chefia
        --
         IF PKGPAG_VAR.vgFuc.Count > 0
           AND vvin.cdchave = PKGPAG_VAR.vgfuc(1).cdhistfuncaochefia
           AND nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef,0) > 0

         THEN

          vVlExpr.vlIntegral := trunc(vVlExpr.vlIntegral, 2);
           PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef := trunc(nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef,0),2);
          vVlBase930.VlProporcional := trunc(vVlBase930.VlProporcional, 2);

           IF  PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef +
                vVlExpr.vlIntegral > vVlBase930.VlProporcional
             THEN
                vVlExpr.vlIntegral := GREATEST(vVlBase930.VlProporcional, nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef,0)) -
                                            LEAST(vVlBase930.VlProporcional, nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef,0));
            vVlExpr.vlProporcional := vvlexpr.vlIntegral;
            vvlexpr.vlReal         := vVlExpr.vlIntegral;
          END IF;

        END IF;

        --
        -- Calculando Cargo Efetivo
        --
         IF vvin.cdchave = PKGPAG_VAR.vgcef(1).cdhistcargoefetivo
           THEN

           IF nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlFuc,0) > 0

           THEN

                 IF  (nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlFuc,0) +
                      vVlExpr.vlIntegral) > vVlBase930.VlProporcional
                   THEN
                      vVlExpr.vlIntegral := GREATEST(vVlBase930.VlProporcional, nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlFuc,0)) -
                                            LEAST(vVlBase930.VlProporcional, nvl(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlFuc,0));
              vVlExpr.vlProporcional := vvlexpr.vlIntegral;
              vvlexpr.vlReal         := vVlExpr.vlIntegral;
            END IF;

          END IF;

          --
          -- So possui CEF
          --
           IF PKGPAG_VAR.vgFUC.Count = 0
             AND vVlExpr.vlIntegral > vVlBase930.VlProporcional
             THEN
            vVlExpr.vlIntegral     := vVlBase930.VlProporcional;
            vVlExpr.vlProporcional := vvlexpr.vlIntegral;
            vvlexpr.vlReal         := vVlExpr.vlIntegral;
          END IF;

        END IF;

      ELSE

        vvlexpr.vlreal := trunc(fretornavalorlimitefinal(pformexpr    => vvin.lformcalculo,
                                                            pVlExpressao => vVlExpr.vlReal),2);

        vvlexpr.vlintegral := trunc(fretornavalorlimitefinal(pformexpr    => vvin.lformcalculo,
                                                            pVlExpressao => vVlExpr.vlIntegral),2);

        vvlexpr.vlproporcional := trunc(fretornavalorlimitefinal(pformexpr    => vvin.lformcalculo,
                                                            pVlExpressao => vVlExpr.vlProporcional),2);

      END IF;

      IF vvlexpr.vlindice IS NOT NULL AND vvlexpr.vlproporcional  <> vvlexpr.vlreal THEN

        IF NOT (vRubrica.NuRubrica = 75
          AND PKGPAG_VAR.vgFolha.CdAgrupamento = 5
          AND (ppagcalc.dtfim <>  PKGPAG_VAR.vgFolha.dtfimmes OR ppagcalc.dtinicio <> PKGPAG_VAR.vgFolha.dtiniciomes))
          THEN

        vdeformula.deexprproporcional :=  vdeformula.deexprproporcional || ' * ' ||  vvlexpr.vlindice || 'dias / 30';
        END IF;

      END IF;
      
      --SIG-11903 Defensoria para mais de um vinculo ctisp corrigir indice
       
      if vRubrica.CdRubricaAgrupamento = PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,229) 
        and PKGPAG_VAR.bPossuiCtisp 
        and pFolha.CdAgrupamento = 176 
        and PKGPAG_VAR.vgcef.count > 1 
         and nvl(PKGPAG_VAR.vgNuDiasCtisp,0) > 0 then
         vvlexpr.vlIndice := PKGPAG_VAR.vgNuDiasCtisp ;
      end if;

      IF bcalcindvt THEN
        vvlexpr.vlindice := vvlexpr.vlproporcional / vvlvaltransporte;
      ELSIF bcalcmestrab THEN
        vvlexpr.vlindice := vnumestrab;
      ELSIF pPagCalc.CdIncorporacaoAtivo IS NOT NULL
      AND NVL(vVlIndiceOutraRubrica,0) > 0 THEN
        vvlexpr.vlindice := vvlindiceoutrarubrica;
      ELSIF NVL(PKGPAG_VAR.vgNuDiasSubst,0) > 0 and vvin.cdrelacaovinculo in (2,3) and PKGPAG_VAR.vgFolha.CdAgrupamento = 176 THEN
        vvlexpr.vlindice := NVL(PKGPAG_VAR.vgNuDiasSubst, 0);
      ELSIF ppagcalc.cdrubricaagrupamento =58861 THEN --proporcionaliza o indice da rubrica 01-0431
        vvlexpr.vlindice := PKGPAG_VAR.vgIndiceRub010431;
      ELSIF ppagcalc.cdrubricaagrupamento = 10011 THEN --proporcionaliza o indice da rubrica 01-0550
        vvlexpr.vlindice := trunc((vvlexpr.vlindice *
                                  ppagcalc.vlindicerubrica) / 30, 2);
        --
        -- 4 = indice em dias.
        --
      ELSIF PKGPAG_VAR.vgRubrica(pPagCalc.cdrubricaagrupamento).CdTipoIndice = 4 THEN
        --
        -- Usar o indice referente aos dias de afastamento
        --
        IF PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).nurubrica = 568 THEN
          vvlexpr.vlindice := PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlIndice;
        ELSIF NVL(ppagcalc.vlindicerubrica, 0) > 30 THEN
          vvlexpr.vlindice := vvlexpr.vlindice;
        ELSif PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).nurubrica in (518,519)
           and PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).cdtiporubrica = 5 then
          vvlexpr.vlindice := NVL(ppagcalc.vlindicerubrica, 0);
          -- Sal Maternidade Santur
        elsif ppagcalc.cdrubricaagrupamento in (39156, 39059) then
          vvlexpr.vlindice := ppagcalc.vlindicerubrica;
        ELSIF (PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).cdtiporubrica=5
              AND PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).nurubrica=989)
          THEN
          vvlexpr.vlindice := ppagcalc.vlindicerubrica;
        ELSE
          null;
        END IF;
      ELSIF ppagcalc.vlindicerubrica IS NOT NULL THEN
        IF (PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).cdtiporubrica=1
              AND PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).nurubrica=433)
              AND pfolha.CdAgrupamento = 134
              AND ppagcalc.vlindicerubrica < 30
              AND vVin.cdhistfuncaochefia = 207377 THEN
          vvlexpr.vlindice := 30;
        ELSE
          vvlexpr.vlindice := ppagcalc.vlindicerubrica;
        END IF;
      ELSE
        NULL; -- Manter valor que j? est? resultado dos c?lculos
      END IF;

      -- pog chamado #60378: zerar valor integral da rub 01-0363 quando valor real for zero
      IF vrubrica.CdTipoRubrica = 1 AND
         vrubrica.NuRubrica = 363   AND
         vvlexpr.vlreal = 0         AND
         vvlexpr.vlintegral > 0 THEN

        vvlexpr.vlintegral := 0;

      END IF;

      IF vRubrica.CdTipoRubrica = 1 AND vRubrica.NuRubrica in (1070, 1037) THEN
        PProporcionalizarRubrica01_1070(pCdVinculo            => ppagcalc.cdvinculo,
                                        pCdRubricaAgrupamento => vrubrica.CdRubricaAgrupamento,
                                        pFolha                => pFolha,
                                        pVlExpr               => vvlexpr);
      END IF;

      IF pRetornaValor IS NULL
        THEN
        --
        -- 10271/2017 - CTISP - BOMBEIRO
        --
          IF pPagCalc.cdrubricaagrupamento = 20570
            AND (NVL(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlIndice,0) +
                 vvlexpr.vlindice) > 30
             THEN

          vvlexpr.vlindice := 30 - PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlIndice;

        END IF;
        --
        -- SIG-9406,SIGRH - 9637 - SEA - MILITARES
        --
        IF PKGPAG_VAR.vgFolha.CdOrgao = 49 and
          pPagCalc.cdrubricaagrupamento = PKGPAG_GERAL.fretornarubrica(PKGPAG_VAR.vgFolha.CdAgrupamento,1,433) and
          nvl(vvlexpr.vlintegral,0) <= 0 and
          nvl(vvlexpr.vlproporcional,0)  <= 0 and
          vvlexpr.vlreal  > 0 and
          ppagcalc.dtdesligamento is null
           THEN
          vvlexpr.vlintegral:= vvlexpr.vlreal;
          vvlexpr.vlproporcional :=  vvlexpr.vlreal;
        END IF;

        UPDATE epaghistoricorubricarelvinc
           SET vlintegral           = vvlexpr.vlintegral,
               vlproporcional       = vvlexpr.vlproporcional,
               vlreal               = vvlexpr.vlreal,
               vlindicerubrica      = vvlexpr.vlindice,
               deexpressao          = SUBSTR(vdeformula.deexprproporcional,1,200),
               deindicecontracheque = vdeindicerubrica
         WHERE cdhistoricorubricarelvinc = vvin.cdhistpagamento;
           IF PKGPAG_VAR.vgcef.Count > 0 and vvin.cdchave = PKGPAG_VAR.vgcef(1).cdhistcargoefetivo
             THEN
          PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCef := vvlexpr.vlProporcional;
           ELSIF PKGPAG_VAR.vgfuc.Count > 0 and vvin.cdchave = PKGPAG_VAR.vgfuc(1).cdhistfuncaochefia
             THEN
          PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlFuc := vvlexpr.vlProporcional;
        else
          null;
        END IF;
        PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlCCo := 0;
        PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlApo := 0;
        PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlIndice := 0;

        --
        -- Para rubrica com indices em dias gravar o total de dias.
        --
           IF PKGPAG_VAR.vgRubrica(pPagCalc.cdrubricaagrupamento).CdTipoIndice = 4
             THEN
               PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlIndice :=
                                NVL(PKGPAG_VAR.vgValorCalculoRubrica(vrubrica.CdRubricaAgrupamento).VlIndice,0) +
                                                                                      vvlexpr.vlIndice;
        END IF;
      ELSE

        vVlFormula          := vVlExpr;
        vdeformulaCalculada := vDeFormula;

      END IF;

  ELSE -- No Vinculo, calcular somente Proporcional

      vvlexpr.vlproporcional := fcalcexpressao(vdeformula.deexprproporcional,vrubrica.CdRubricaAgrupamento );

      vvlexpr.vlproporcional := trunc(fretornavalorlimitefinal(pformexpr    => vvin.lformcalculo,
                                                              pVlExpressao => vVlExpr.vlProporcional),2);

      IF bcalcindvt THEN
        vvlexpr.vlindice := vvlexpr.vlproporcional / vvlvaltransporte;
      ELSIF bcalcmestrab THEN
        vvlexpr.vlindice := vnumestrab;
      ELSIF vvlindicerubrica IS NOT NULL THEN
        vvlexpr.vlindice := vvlindicerubrica;
      ELSE
        vvlexpr.vlindice := NULL;
      END IF;

      IF pRetornaValor IS NULL
        THEN
        IF vvlexpr.vlproporcional > 0.01 THEN

          UPDATE epaghistoricorubricavinculo

             SET vlpagamento          = vvlexpr.vlproporcional,
                 vlindicerubrica      = vvlexpr.vlindice,
                 deexpressao          = SUBSTR(vdeformula.deexprproporcional,1,200),
                 deindicecontracheque = vdeindicerubrica
           WHERE cdhistoricorubricavinculo = vvin.cdhistpagamento;

              IF PKGPAG_VAR.vgFolha.cdOrgao = 34
                AND PKGPAG_VAR.vgrubrica(vrubrica.CdRubricaAgrupamento).cdtiporubrica=1
                AND PKGPAG_VAR.vgrubrica(ppagcalc.cdrubricaagrupamento).nurubrica=3323 THEN

            UPDATE epaghistoricorubricavinculo
               SET vlpagamento = 0
             WHERE cdhistoricorubricavinculo = vvin.cdhistpagamento;

          END IF;

          IF vrubrica.CdRubricaAgrupamento in (56601, 56658) -- EXCECAO PARA RUBRICA 05-0260 e 05-0370
           THEN
            UPDATE epaghistoricorubricarelvinc
               SET vlintegral           = vvlexpr.vlproporcional,
                   vlproporcional       = vvlexpr.vlproporcional,
                   vlreal               = vvlexpr.vlproporcional,
                   vlindicerubrica      = vvlexpr.vlindice,
                   deexpressao          = SUBSTR(vdeformula.deexprproporcional,1,200),
                   deindicecontracheque = vdeindicerubrica
             WHERE cdhistoricorubricarelvinc = vvin.cdhistpagamento;

          END IF;

        ELSE

           DELETE
             FROM EPagHistoricoRubricaVinculo HRV
           WHERE hrv.cdhistoricorubricavinculo = vvin.cdhistpagamento;

        END IF;

      ELSE

        vVlFormula          := vVlExpr;
        vdeformulaCalculada := vDeFormula;

      END IF;

    END IF;
  IF vrubrica.CdRubricaAgrupamento = 23157 THEN  ---01-1023
      select sum(vlpagamento)
        into lnvlpagamento
        from epaghistoricorubricavinculo hrv
       where hrv.cdrubricaagrupamento in (22919) -- BASE DO 13 SALARIO
         and hrv.cdvinculo = vvin.cdvinculo
           and hrv.cdfolhapagamento in (select fpg.cdfolhapagamento
                from ECalFolhaPag fpg
               inner join epagtipofolhapagamento tfp
                  on fpg.cdtipofolhapagamento = tfp.cdtipofolhapagamento
               where fpg.cdorgao = PKGPAG_VAR.vgFolha.CdOrgao
                                         and fpg.nuanoreferencia=PKGPAG_VAR.vgFolha.NuAnoreferencia
                 and fpg.numesreferencia = 11
                 AND fpg.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
                 and tfp.cdtipofolha = 3 --- folha de 13º
                 and fpg.cdtipocalculo = 1
                 and fpg.flcalculodefinitivo = 'S');

  END IF;

  EXCEPTION

    WHEN OTHERS THEN

      PKGPAG_GERAL.PInsereLog(PKGPAG_VAR.bLog,
                              PKGPAG_VAR.vCdHistParamCalc,
                              PKGPAG_VAR.vcdpessoa,
                              'Erro ao processar formulas de calculo da rubrica ' ||
                            LPAD(vRubrica.CdTipoRubrica,2,'0') || '-' || LPAD(vRubrica.NuRubrica,4,'0') ||
                            ' Express?o: ' || vDeFormula.DeExprProporcional,
                              PKGPAG_VAR.vgcdvinculo);

  END;

  -- pTpProcessamento : 1 - Formulas e Bases
  --                    2 - Apenas bases

  -- pTpLocal      1 - Rela??o de vinculo
  --               2 - Vinculo

  PROCEDURE pprocessaformulasbases(pfolha           IN pkgpag_tipo.rfolha,
                                   pcdvinculo       IN INTEGER,
                                   pcdrubrica       IN INTEGER,
                                   ptpprocessamento IN INTEGER DEFAULT 1,
                                   ptplocal         IN INTEGER DEFAULT 1,
                                   ptptributacao    IN INTEGER DEFAULT NULL,
                                   pindprocretro    IN INTEGER DEFAULT NULL,
                                   pcdmnemonico     IN INTEGER DEFAULT NULL,
                                   pNuSufixoRubrica IN INTEGER DEFAULT NULL) IS

    PROCEDURE aplicaformulabase(ppagcalc      IN pkgpag_tipo.rpagcalc,
                                ptptributacao IN INTEGER DEFAULT NULL) IS

      --vrubexpr pkgpag_tipo.rbasecalculo;

      vformexpr pkgpag_tipo.rformulacalculo;

      vcdbasecalculo INTEGER;

      -- EXCLUI PATRONAL DA ASSICIACAO DA CIDASC
      -- PARA QUEM TEM LANCAMENTO FINANCEIRO ZERADO
      -- alterado para só executar a formula de base se o vínculo possuir LF
      FUNCTION fExcluiPatronalAssocCIDASC RETURN BOOLEAN IS

        vCountLF090992 INTEGER := 0;

      BEGIN
 
        IF pFolha.CdAgrupamento = 4 AND -- CIDASC
            PKGPAG_VAR.vgRubrica(pPagCalc.CdRubricaAgrupamento).cdtiporubrica = 9 AND
            PKGPAG_VAR.vgRubrica(pPagCalc.CdRubricaAgrupamento).nurubrica = 992 THEN

          SELECT COUNT(f.Vllancamentofinanceiro)
            INTO vCountLF090992
            FROM epaglancamentofinanceiro f
           WHERE F.CdVinculo = pCdVinculo
             AND F.DtInicioDireito <= pFolha.dtFimMes
                 AND (F.DtFimdireito >= pFolha.DtInicioMes OR F.DtFimDireito IS NULL)
             AND F.FlAnulado = PKGPAG_TIPO.cnN
             AND F.Cdrubricaagrupamento = pPagCalc.CdRubricaAgrupamento
                --AND F.Vllancamentofinanceiro = 0
                 and f.cdrubricaagrupamento in (select ra.cdrubricaagrupamento
                    from vpagrubricaagrupamento ra
                   where ra.cdrubricaagrupamento = f.cdrubricaagrupamento
                     and ra.flsuspensa = PKGPAG_TIPO.cnN);

          IF nvl(vCountLF090992, 0) = 0 THEN
            DELETE FROM epaghistoricorubricarelvinc
             WHERE cdhistoricorubricarelvinc = ppagcalc.cdhistpagamento;
            RETURN TRUE;
          END IF;

        END IF;

        RETURN FALSE;

      END;

    BEGIN
 
      PKGPAG_VAR.vgtminicio := PKGPAG_GERAL.fgettime;

      PKGPAG_VAR.vgPagCalc := ppagcalc;

      IF fExcluiPatronalAssocCIDASC THEN
        RETURN;
      END IF;

      /*----------------------------------------------
        -- Inicializa vari?veis para c?lculo do ?ndice
        -- do vale transporte em pec?nia
      /*----------------------------------------------*/

      bcalcindvt := FALSE;

      bcalcmestrab := FALSE;

      vvlvaltransporte := 0.0;

      vnumestrab := 0;

      IF ptpprocessamento = 1 THEN

        -- EXECUTA EXPRESSAO DE FORMULA DE C?LCULO

        IF ppagcalc.cdexpressaoformcalc IS NOT NULL THEN

          vformexpr := PKGPAG_VAR.vgformexpr(ppagcalc.cdexpressaoformcalc);

          PProcFormulaCalculo(pFolha,
                              pPagCalc,
                              vFormExpr,
                              pTpTributacao,
                              pCdMnemonico);

          -- EXECUTA REGRA DE NEG?CIO DE VANTAGEM PECUNI?RIA

        ELSIF ppagcalc.cdvantagempecuniaria IS NOT NULL THEN

          pprocvantagembase(pfolha, ppagcalc);

          -- EXECUTA REGRA DE NEG?CIO DE UMA RUBRICA N?O TOTALIZADORA

        ELSIF PKGPAG_VAR.vgRubrica(pPagCalc.CdRubricaAgrupamento).CdTipoRubrica <> 9 THEN

          pproceventobase(pfolha, ppagcalc);

          -- EXECUTA EXPRESSAO DE BASE DE C?LCULO

        ELSE

          IF ppagcalc.cdexpressaoformcalc IS NULL AND
             ppagcalc.cdvantagempecuniaria IS NULL THEN

            IF PKGPAG_VAR.vgrubrica.exists(ppagcalc.cdrubricaagrupamento) THEN

              vCdBaseCalculo := PKGPAG_VAR.vgRubrica(pPagCalc.CdRubricaAgrupamento).CdBaseCalculo;

              PProcRubricaTotalizadora(pFolha,
                                       pPagCalc,
                                       vCdBaseCalculo,
                                       ptptributacao);
            END IF;

          END IF;

        END IF;

      ELSE

        IF ppagcalc.cdexpressaoformcalc IS NOT NULL AND
           ppagcalc.dtdesligamento < pfolha.dtiniciomes THEN

          vformexpr := PKGPAG_VAR.vgformexpr(ppagcalc.cdexpressaoformcalc);

        PProcFormulaCalculo (pFolha,
                             pPagCalc,
                             vFormExpr,
                             pTpTributacao);

          -- EXECUTA AS BASES DE CALCULO

        ELSIF ppagcalc.cdrubricaagrupamento IS NOT NULL AND
              ppagcalc.cdexpressaoformcalc IS NULL AND
              ppagcalc.cdvantagempecuniaria IS NULL THEN

          -- Solicitacao de Sustentacao #64112
          -- 7901/2015 - FOLHA - LANCAMENTO FINANCEIRO COMPLEMENTAR
          -- Rubricas de bases terem o mesmo comportamento das demais
          -- em folhas de decimo terceiro via lancamento complementar.
          IF PKGPAG_VAR.vgFolha.CdTipoFolha IN ( PKGPAG_TIPO.cnTpFolha13,
                                                 PKGPAG_TIPO.cnTpFolhaResidente13)
             AND PKGPAG_GERAL.fpossuilanccomplementar(pcdrubricaagrupamento => pPagCalc.CdRubricaAgrupamento,
                                                      pnusufixorubrica      => 1)

           THEN

            vcdbasecalculo := 0;

          ELSIF PKGPAG_VAR.vgrubrica.exists(ppagcalc.cdrubricaagrupamento) AND 
                NOT PKGPAG_GERAL.fpossuilancfinanceiro(pCdVinculo,
                                                       pFolha,
                                                       pPagCalc.CdRubricaAgrupamento) THEN

            vCdBaseCalculo := PKGPAG_VAR.vgRubrica(pPagCalc.CdRubricaAgrupamento).CdBaseCalculo;

            IF vcdbasecalculo IS NOT NULL THEN

              PProcRubricaTotalizadora(pFolha,
                                       pPagCalc,
                                       vCdBaseCalculo,
                                       ptptributacao);
            END IF;

          else
            null;
          END IF;

        else
          null;
        END IF;

      END IF;

    END;

  BEGIN
    
 
    -- PKGPAG_VAR.vgDtInicio := SYSTIMESTAMP;

    -- Inicio da leitura dos pagamentos do vinculo para
    -- execu??o de f?rmulas e bases de calculo

    vgindprocretro := pindprocretro;

    IF ptplocal = 1 THEN

      FOR vpagvinccalc IN cpagrelvinccalc(pfolha.cdfolhapagamento,
                                        pCdVinculo)
      LOOP

        BEGIN

          aplicaformulabase(vpagvinccalc);

        EXCEPTION

          WHEN OTHERS THEN

            PKGPAG_GERAL.pinserelog(PKGPAG_VAR.blog,
                                    PKGPAG_VAR.vcdhistparamcalc,
                                    PKGPAG_VAR.vcdpessoa,
                                    'Erro ao processar f?rmula na rela??o de v?nculo - Rubrica: ' ||
                                  LPAD(PKGPAG_VAR.vgRubrica(vPagVincCalc.CdRubricaAgrupamento).CdTipoRubrica,2,'0') ||'-'||
                                  LPAD(PKGPAG_VAR.vgRubrica(vPagVincCalc.CdRubricaAgrupamento).NuRubrica,4,'0') || ' - Expressao: ' || vPagVincCalc.Cdexpressaoformcalc,
                                    PKGPAG_VAR.vgcdvinculo);

        END;

      END LOOP;

    ELSE

      FOR vPagVincCalc IN cPagVincCalc(pFolha.CdFolhaPagamento,
                                       pCdVinculo,
                                      pCdRubrica)
      LOOP

        BEGIN

          IF pNuSufixoRubrica IS NULL OR pNuSufixoRubrica = vPagVincCalc.NuSufixoRubrica THEN

            AplicaFormulaBase(vPagVincCalc,
                          pTpTributacao);

          END IF;

        EXCEPTION

          WHEN OTHERS THEN

            PKGPAG_GERAL.pinserelog(PKGPAG_VAR.blog,
                                    PKGPAG_VAR.vcdhistparamcalc,
                                    PKGPAG_VAR.vcdpessoa,
                                    'Erro ao processar f?rmula no v?nculo- Rubrica: ' ||
                                    LPAD(PKGPAG_VAR.vgRubrica(vPagVincCalc.CdRubricaAgrupamento).CdTipoRubrica,2,'0') ||'-'||
                                    LPAD(PKGPAG_VAR.vgRubrica(vPagVincCalc.CdRubricaAgrupamento).NuRubrica,4,'0') || ' - Expressao: ' || vPagVincCalc.Cdexpressaoformcalc,
                                    PKGPAG_VAR.vgcdvinculo);

        END;

      END LOOP;

    END IF;

   PKGPAG_GERAL.PLogTrace ('FB - Processa F?rmulas Bases',null, PKGPAG_VAR.vgTmInicio);

  EXCEPTION

    WHEN OTHERS THEN

      --dbms_output.put_line('Erro ao processar formulas das bases' || SQLERRM || SQLCODE);
      null;

  END;


  PROCEDURE pprocessaformulasbasesTotal (pfolha           IN pkgpag_tipo.rfolha,
                                         pcdvinculo       IN INTEGER,
                                         ptpprocessamento IN INTEGER DEFAULT 1,
                                         ptplocal         IN INTEGER DEFAULT 1,
                                         ptptributacao    IN INTEGER DEFAULT NULL,
                                         pindprocretro    IN INTEGER DEFAULT NULL,
                                         pcdmnemonico     IN INTEGER DEFAULT NULL,
                                         pNuSufixoRubrica IN INTEGER DEFAULT NULL) IS
 
  BEGIN
 
      pprocessaformulasbases (pfolha           => pfolha,
                              pcdvinculo       => pcdvinculo,
                              pcdrubrica       => null,
                              ptpprocessamento => ptpprocessamento,
                              ptplocal         => ptplocal,
                              ptptributacao    => ptptributacao,
                              pindprocretro    => pindprocretro,
                              pcdmnemonico     => pcdmnemonico,
                              pNuSufixoRubrica => pNuSufixoRubrica);
                               
  END;                                                                     
                                   
  FUNCTION fMneRubrica13FolhaNormal(pCdVinculo            IN INTEGER,
                                    pCdRubricaAgrupamento IN INTEGER,
                                    pNuAnoReferencia      IN INTEGER,
                                    pNuMesReferencia      IN INTEGER) RETURN NUMBER IS
    vValorBase NUMBER;
  BEGIN
 
    SELECT HRV.VLPAGAMENTO
      INTO vValorBase
      FROM EPAGHISTORICORUBRICAVINCULO HRV
     INNER JOIN ECalFolhaPag FP
        ON FP.CDFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
       AND FP.CdCalculo = PKGPAG_VAR.vgCalculo.CdCalculo 
       AND FP.CDTIPOCALCULO = 1
       AND FP.NUANOREFERENCIA = pNuAnoReferencia
       AND FP.NUMESREFERENCIA = pNuMesReferencia
     INNER JOIN EPAGTIPOFOLHAPAGAMENTO TFP
        ON TFP.CDTIPOFOLHAPAGAMENTO = FP.CDTIPOFOLHAPAGAMENTO
       AND TFP.CDTIPOFOLHA = 1
     WHERE HRV.CDVINCULO = pCdVinculo
       AND HRV.CDRUBRICAAGRUPAMENTO = pCdRubricaAgrupamento;

    RETURN vValorBase;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0;
    WHEN OTHERS THEN
      RETURN 0;
  END;

  FUNCTION fMneQtdDiasMesAnterior(pDataReferencia IN DATE,
                                  pLimite         IN INTEGER) RETURN INTEGER IS
    vQtdDias INTEGER;
  BEGIN
 
    vQtdDias := PKGPAG_GERAL.FQuantidadeDiasMes(add_months(pDataReferencia, -1));
    IF vQtdDias > pLimite THEN
      vQtdDias := pLimite;
    END IF;

    RETURN vQtdDias;
  END;
  
  FUNCTION fMnePercentAdiantFerias(pCdVinculo IN INTEGER,
                                   pNuAno     IN INTEGER,
                                   pNuMes     IN INTEGER) RETURN NUMBER IS
    vFlAdiantFerias      CHAR   := NULL;
    vPercentAdiantFerias NUMBER := NULL;                               
  BEGIN
    SELECT FFP.FLADIANTAMENTOFERIAS, NVL(FFP.NUPERCENTUALADIANTAMENTO, 0)
      INTO vFlAdiantFerias, vPercentAdiantFerias
      FROM EMOVPERIODOAQUISITIVOFERIAS PAF
     INNER JOIN EMOVFERIASFRUICAOPAGAMENTO FFP
        ON PAF.CDPERIODOAQUISITIVOFERIAS = FFP.CDPERIODOAQUISITIVOFERIAS
     WHERE FFP.FLANULADO = PKGPAG_TIPO.cnN
       AND PAF.CDVINCULO = pCdVinculo
       AND FFP.NUANOREFERENCIA = pNuAno
       AND FFP.NUMESREFERENCIA = pNuMes;
         
    IF vFlAdiantFerias = PKGPAG_TIPO.cnN THEN
      vPercentAdiantFerias := 0;  
    END IF;    
    
    RETURN vPercentAdiantFerias;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 0;
      
    WHEN TOO_MANY_ROWS THEN
      RETURN 0;  
    
    WHEN OTHERS THEN
      RETURN 0;      
  END;

END pkgpag_fb;
/
