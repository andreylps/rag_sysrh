create or replace package PKGPAG_PENSAOPREVIDENCIARIA is

  -- Author  : RVFURTADO
  -- Created : 28/06/2017 13:41:49
  -- Purpose : Pensao Previdenciaria

  ----------------------------------------------------------------------- TIPOS

  type rValorPeriodo is record(
    dtInicio date,
    dtFim    date,
   nuValor  number
  );

  TYPE tValorPeriodo IS TABLE OF rValorPeriodo INDEX BY PLS_INTEGER;

  ----------------------------------------------------------------------- CURSORES

  -- busca informacoes sobre a pensao
  cursor cPensaoPrevidenciaria(pCdVinculoPensionista integer,
                               pAnoMesReferencia     integer) is

    select p.*
      from epvdhistpensaoprevidenciaria p
     where p.cdvinculo = pCdVinculoPensionista
        and   p.dtinicio <= trunc(last_day(to_date(pAnoMesReferencia || '01','YYYYMMDD')))
        and   (( p.dtfim >= to_date(pAnoMesReferencia || '01','YYYYMMDD') or p.dtfim is null)
               or (TO_CHAR(p.dtfim,'MMYYYY') = to_char(pkgpag_var.vgFolha.DtCalculoAnt,'MMYYYY')
                   and (PKGPAG_VAR.vMotAfast.InTipoAfastamento = 'D'
                   AND  PKGPAG_VAR.vMotAfast.DtInclusao > pkgpag_var.vgFolha.DtCalculoAnt
                   AND  to_char(PKGPAG_VAR.vMotAfast.DtInicio,'mmyyyy') =
                        to_char(pkgpag_var.vgFolha.DtCalculoAnt,'mmyyyy')))
                    )
       and p.flanulado = 'N'
     order by p.dtinicio;

  -- busca informacoes sobre a cota da pensao
  cursor cPensaoCota(pCdVinculoPensionista integer,
                     pAnoMesReferencia     integer) is
    select c.*
      from epvdhistpensaoprevidenciaria p
     inner join epvdhistpensaocota c
        on c.cdhistpensaoprevidenciaria = p.cdhistpensaoprevidenciaria
     where p.cdvinculo = pCdVinculoPensionista
       and p.flanulado = 'N'
        and   c.dtinicio <= trunc(last_day(to_date(pAnoMesReferencia || '01','YYYYMMDD')))
        and   (c.dtfim >= to_date(pAnoMesReferencia || '01','YYYYMMDD') or c.dtfim is null)
       and c.flanulado = 'N'
     order by c.dtinicio desc;

  -- busca informacoes sobre instituidor de pensao
  cursor cInstituidorPensaoPrev(pCdVinculoPensionista integer) is
    select i.*
      from epvdinstituidorpensaoprev i
     inner join epvdhistpensaoprevidenciaria p
        on p.cdhistpensaoprevidenciaria = i.cdhistpensaoprevidenciaria
       and p.flanulado = 'N'
        inner join ecadvinculo v on v.cdvinculo = i.cdvinculo
     where i.flanulado = 'N'
       and p.cdvinculo = pCdVinculoPensionista
     order by p.dtinicio desc;

  -- busca informacoes sobre base de calculo da pensao
  cursor cBaseCalculoPensao(pCdVinculoInstituidor integer,
                            pAnoMesReferencia     integer) is
    select bc.*
      from epvdhistvalorbasecalcpensao bc
     where bc.cdvinculo = pCdVinculoInstituidor
        and   bc.dtiniciovigencia <= trunc(last_day(to_date(pAnoMesReferencia || '01','YYYYMMDD')))
        and   ( bc.dtfimvigencia >= to_date(pAnoMesReferencia || '01','YYYYMMDD') or bc.dtfimvigencia is null)
       and bc.flanulado = 'N'
     order by bc.dtiniciovigencia desc;

  -- busca valor referencia
  cursor cValorReferencia(pAnoMesReferencia  integer,
                          pCdValorReferencia integer) is

    select * -- VLREFERENCIA NUMBER(16,6)
      from epaghistvalorreferencia hvr
        inner join epagvalorreferenciaversao vrv on vrv.cdvalorreferenciaversao = hvr.cdvalorreferenciaversao
        inner join epagvalorreferencia vr on vr.cdvalorreferencia = vrv.cdvalorreferencia
     where vr.cdvalorreferencia = pCdValorReferencia
        and   hvr.nuanoiniciovigencia*100 + hvr.numesiniciovigencia <= pAnoMesReferencia
        and   (hvr.nuanofimvigencia is null or hvr.nuanofimvigencia*100+hvr.numesfimvigencia >= pAnoMesReferencia )
       and vrv.nuversao = 1
       and vr.cdagrupamento = 132
        and   hvr.nuanoiniciovigencia*100 + hvr.numesiniciovigencia <= pAnoMesReferencia
        and   (hvr.nuanofimvigencia is null or hvr.nuanofimvigencia*100+hvr.numesfimvigencia >= pAnoMesReferencia );

  -- busca contracheque na folha do instituidor
  cursor cContrachequeInstituidor(pCdVinculoInstituidor integer,
                                  pAnoMesReferencia     integer,
                                  pCdTipoCalculo        integer default 1) is

          with vinculo as (
               select *
               from ecadvinculo v
               where v.cdvinculo = pCdVinculoInstituidor
          ),
          tipofolhainstituidor as (
            select *
        from epagtipofolhapagamento tfp
       where tfp.cdtipofolha = 6 -- Instituidores de pensao
      ),
          folha as (
            select *
        from epagfolhapagamento fp
            inner join tipofolhainstituidor on tipofolhainstituidor.cdtipofolhapagamento = fp.cdtipofolhapagamento
       where fp.nuanomesreferencia = pAnoMesReferencia
            and   fp.cdtipocalculo = case when pkgpag_var.vgFolha.CdTipoCalculo = pkgpag_tipo.cnTpCalculoRecalculoMes
                                               and pkgpag_var.vgFolha.NuSequencialFolha = 2
                                          then pkgpag_tipo.cnTpCalculoNormal
                                          else pCdTipoCalculo
                                     end
          )
    select *
      from epaghistoricorubricavinculo hrv
          inner join folha on folha.cdfolhapagamento = hrv.cdfolhapagamento
     where hrv.cdvinculo = pCdVinculoInstituidor;

  ----------------------------------------------------------------------- MNEMONICOS

  -- VLBASEPREVINSTITUIDOR:
  -- SE O PENSIONISTA E COM PARIDADE, BUSCA VALOR DA RUBRICA 09-0916 DO CONTRA-CHEQUE DO VINCULO INSTITUIDOR DA PENSAO;
  -- SE SEM PARIDADE BUSCA NA TABELA EPVDHISTVALORBASECALCPENSAO.VLBASECALCULO.
  function fVlBasePrevInstituidor(pCdVinculoPensionista integer,
                                  pAnoMesReferencia     integer,
                                  pCdTipoCalculo integer) return number;

  -- VlBaseInstMilita:
  -- nos moldes do já existente "VlBasePrevInst", e que seja considerado como base a rubrica 09-9916.
  -- Esclareço que estamos parametrizando a rubrica 01-0623 nos moldes da 01-0610 para o caso dos novos pensionistas Militares
  function fVlBaseMilitarInstituidor(pCdVinculoPensionista integer,
                                     pAnoMesReferencia     integer,
                                     pCdTipoCalculo integer) return number;

  -- VLTETOINSTITUIDOR:
  -- VALOR DA RUBRICA 09-1012 NO CONTRA-CHEQUE DO VINCULO INSTITUIDOR DA PENSAO.
  function fVlTetoInstituidor(pCdVinculoPensionista integer,
                              pAnoMesReferencia     integer,
                              pCdTipoCalculo        integer) return number;

  -- VLPERCPENSAO:
  -- PERCENTUAL REFERENTE A COTA DO PENSIONISTA.
  -- BUSCAR NA TABELA EPVDHISTPENSAOCOTA.NUPERCENTUAL (QUANDO NAO TIVER VALOR NA COLUNA CDVALORREFERENCIA).
  -- CASO NAO ENCONTRE, RETORNA 0.
  function fVlPercPensao(pCdVinculoPensionista integer,
                         pAnoMesReferencia     integer,
                            pFlIntegral boolean default false) return number;

  -- VLPERCPENSAOBASE:
  -- Percentual da cota de pensao para integralizar bases de calculo.
  -- Quando o mneumonico VlPercPensao retorna 0 (zero) o VlPercPensaoBase deve retornar 100.
  -- Os demais valores de retorno sao iguais entre os dois mneumonicos.
  function fVlPercPensaoBase(pCdVinculoPensionista integer,
                             pAnoMesReferencia     INTEGER,
                             pFlIntegral           BOOLEAN DEFAULT FALSE) --adicionado sig-7062
   return NUMBER;


  -- VLPENSAOPREV:
  -- SE TIVER CDVALORREFERENCIA, CALCULAR VALOR OU SE TIVER VLCOTA, E O PROPRIO.
  -- CASO NAO ENCONTRE, RETORNA 0.
  function fVlPensaoPrev(pCdVinculoPensionista integer,
                         pAnoMesReferencia     integer,
                         pFlIntegral boolean default false) return number;

  -- VLPERCPENSAOPREV:
  -- PERCENTUAL REFERENTE A COTA DO PENSIONISTA.
  -- BUSCAR NA TABELA EPVDHISTPENSAOCOTA.NUPERCENTUAL (SE NAO TIVER VALOR NAS COLUNAS CDVALORREFERENCIA E VLCOTA).
  -- SE TIVER CDVALORREFERENCIA, CALCULAR VALOR E IDENTIFICAR PERCENTUAL DE ACORDO COM O VLBASEPREVINSTITUIDOR LIMITADO AO VLTETOINSTITUIDOR.
  -- SE TIVER VLCOTA, IDENTIFICAR PERCENTUAL DE ACORDO COM O VLBASEPREVINSTITUIDOR LIMITADO AO VLTETOINSTITUIDOR.
  function fVlPercPensaoPrev(pCdVinculoPensionista integer,
                             pAnoMesReferencia     integer,
                             pCdTipoCalculo        integer) return number;

  -- VLPERCINTEGRALIDADE
  -- PERCENTUAL PROPORCIONAL DE INTEGRALIDADE DO VALOR DA SUA BASE PREVIDENCIARIA.
  -- EPVDHISTVALORBASECALCPENSAO.NUPERCENTUAL
  -- SE NAO TIVER VALOR RETORNA 100.
  function fVlPercIntegralidade(pCdVinculoPensionista integer,
                                pAnoMesReferencia     integer) return number;

  ---------------------------------------------------------------------- FUNCOES AUXILIARES

  -- Busca Valor base do instituidor limitado ao teto
  function fVlBaseInstituidorLimitadoTeto(pCdVinculoPensionista integer,
                                          pAnoMesReferencia     integer,
                                          pCdTipoCalculo integer) return number;

  -- Busca valor pago em determinada rubrica no contracheque do instituidor
  function fVlRubContrachequeInstituidor(pCdVinculoInstituidor integer,
                                         pAnoMesReferencia     integer,
                                         pCdTipoCalculo        integer,
                                         pCdtipoRubrica        integer,
                                  pNuRubrica integer) return number;

  -- Busca cdagrupamento do instituidor
  function fCdAgrupamentoInstituidor(pCdVinculoInstituidor integer) return integer;

  -- Busca cdorgao do instituidor
  function fCdOrgaoInstituidor(pCdVinculoInstituidor integer) return integer;

  -- Busca cdorgao do instituidor para empenho
  function fCdOrgaoOrigemPensionista(pCdVinculoPensionista integer) return integer;

  -- Verifica abrangencia
  function fVerificaAbrangenciaPensaoPrev(pCdVinculoPensionista integer,
                                          pCdRubricaAgrupamento integer,
                                          pDataReferencia date) return boolean;

  -- Retorna Media de Valores no AnoMesReferencia baseado no mes comercial
  function fMediaValorPeriodoMesComercial(pValorPeriodo     tValorPeriodo,
                                          pAnoMesReferencia integer,
                                          pFlIntegral boolean default false) return number;

end PKGPAG_PENSAOPREVIDENCIARIA;
/
create or replace package body PKGPAG_PENSAOPREVIDENCIARIA is

  function fTipoPensaoPrev(pCdVinculoPensionista integer,
                           pAnoMesReferencia     integer) return char is

  begin

    for pensao in cPensaoCota(pCdVinculoPensionista => pCdVinculoPensionista,
                                 pAnoMesReferencia => pAnoMesReferencia)
       loop

      return pensao.flcomparidade;

    end loop;

    return 'N';

  exception
    when others then
      return 'N';

  end;

  function fVlBasePrevInstituidor(pCdVinculoPensionista integer,
                                  pAnoMesReferencia     integer,
                                    pCdTipoCalculo integer) return number is

    vVlBasePrevInstituidor number := 0;

    vCdVinculoInstituidor integer;

    vFlComParidade char(1) := 'N';


  begin

    -- busca vinculos do instituidor
       for instituidor in cInstituidorPensaoPrev(pCdVinculoPensionista)
       loop

         vFlComParidade := fTipoPensaoPrev (pCdVinculoPensionista, pAnoMesReferencia);

      vCdVinculoInstituidor := instituidor.cdvinculo;
      -- para cada vinculo de instituidor, busca a base de calculo
         for baseCalculo in cBaseCalculoPensao(instituidor.Cdvinculo, pAnoMesReferencia)
         loop

        -- SE O PENSIONISTA E COM PARIDADE,
        -- BUSCA VALOR DA RUBRICA 09-0916 DO CONTRA-CHEQUE DO VINCULO INSTITUIDOR DA PENSAO;
        if vFlcomparidade = 'S' then

          vVlBasePrevInstituidor := vVlBasePrevInstituidor +
                                    fVlRubContrachequeInstituidor(pCdVinculoInstituidor => instituidor.Cdvinculo,
                                                                  pAnoMesReferencia     => pAnoMesReferencia,
                                                                  pCdTipoCalculo        => pCdTipoCalculo,
                                                                  pCdtipoRubrica        => 9,
                                                                  pNuRubrica            => 916) +
                                    fVlRubContrachequeInstituidor(pCdVinculoInstituidor => instituidor.Cdvinculo,
                                                                  pAnoMesReferencia     => pAnoMesReferencia,
                                                                  pCdTipoCalculo        => pCdTipoCalculo,
                                                                  pCdtipoRubrica        => 9,
                                                                  pNuRubrica            => 9916);

          --
          -- 10941/2017 - ALTERACAO DE MNEMONICO
          --
                if  vVlBasePrevInstituidor = 0
                  then

            vVlBasePrevInstituidor := 0.01;

          end if;
          -- SE SEM PARIDADE BUSCA NA TABELA EPVDHISTVALORBASECALCPENSAO.VLBASECALCULO.
        else

                vVlBasePrevInstituidor := vVlBasePrevInstituidor + baseCalculo.Vlbasecalculo;

        end if;

        exit;

      end loop;

    end loop;

    return vVlBasePrevInstituidor;

  exception
    when others then
      return 0;

  end fVlBasePrevInstituidor;

  function fVlBaseMilitarInstituidor(pCdVinculoPensionista integer,
                                     pAnoMesReferencia     integer,
                                       pCdTipoCalculo integer) return number is

    vVlBasePrevInstituidor number := 0;

    vCdVinculoInstituidor integer;

    vFlComParidade char(1) := 'N';

  begin

    -- busca vinculos do instituidor
       for instituidor in cInstituidorPensaoPrev(pCdVinculoPensionista)
       loop

         vFlComParidade := fTipoPensaoPrev (pCdVinculoPensionista, pAnoMesReferencia);

      vCdVinculoInstituidor := instituidor.cdvinculo;
      -- para cada vinculo de instituidor, busca a base de calculo
         for baseCalculo in cBaseCalculoPensao(instituidor.Cdvinculo, pAnoMesReferencia)
         loop

        -- SE O PENSIONISTA E COM PARIDADE,
        -- BUSCA VALOR DA RUBRICA 09-9916 DO CONTRA-CHEQUE DO VINCULO INSTITUIDOR DA PENSAO;
        if vFlcomparidade = 'S' then

                vVlBasePrevInstituidor := vVlBasePrevInstituidor + fVlRubContrachequeInstituidor(
                                                                                          pCdVinculoInstituidor => instituidor.Cdvinculo,
                                                                  pAnoMesReferencia     => pAnoMesReferencia,
                                                                  pCdTipoCalculo        => pCdTipoCalculo,
                                                                  pCdtipoRubrica        => 9,
                                                                  pNuRubrica            => 9916);


                if  vVlBasePrevInstituidor = 0
                  then

            vVlBasePrevInstituidor := 0.01;

          end if;


          -- SE SEM PARIDADE BUSCA NA TABELA EPVDHISTVALORBASECALCPENSAO.VLBASECALCULO.
        else

                vVlBasePrevInstituidor := vVlBasePrevInstituidor + baseCalculo.Vlbasecalculo;

        end if;

        exit;

      end loop;

    end loop;

    return vVlBasePrevInstituidor;

  exception
    when others then
      return 0;

  end fVlBaseMilitarInstituidor;

  function fVlTetoInstituidor(pCdVinculoPensionista integer,
                              pAnoMesReferencia     integer,
                              pCdTipoCalculo        integer) return number is

    vVlTetoInstituidor number := 0;
    vVlRub091012       number := 0;

  begin

    -- busca vinculos do instituidor
       for instituidor in cInstituidorPensaoPrev(pCdVinculoPensionista)
       loop

      vVlRub091012 := fVlRubContrachequeInstituidor(pCdVinculoInstituidor => instituidor.Cdvinculo,
                                                    pAnoMesReferencia     => pAnoMesReferencia,
                                                    pCdTipoCalculo        => pCdTipoCalculo,
                                                    pCdtipoRubrica        => 9,
                                                    pNuRubrica            => 1012);

      vVlTetoInstituidor := greatest(vVlRub091012, vVlTetoInstituidor);

    end loop;

    return vVlTetoInstituidor;

  exception
    when others then
      return 0;

  end fVlTetoInstituidor;

  -- Busca Valor base do instituidor limitado ao teto
  function fVlBaseInstituidorLimitadoTeto(pCdVinculoPensionista integer,
                                          pAnoMesReferencia     integer,
                                            pCdTipoCalculo integer) return number is

    vVlBase number;
    vVlTeto number;

  begin

    vVlBase := fVlBasePrevInstituidor(pCdVinculoPensionista => pCdVinculoPensionista,
                                      pAnoMesReferencia     => pAnoMesReferencia,
                                      pCdTipoCalculo        => pCdTipoCalculo);

    vVlTeto := fVlTetoInstituidor(pCdVinculoPensionista => pCdVinculoPensionista,
                                  pAnoMesReferencia     => pAnoMesReferencia,
                                  pCdTipoCalculo        => pCdTipoCalculo);

    return least(vVlBase, vVlTeto);

  exception
    when others then
      return 0;

  end fVlBaseInstituidorLimitadoTeto;

  function fMediaValorPeriodoMesComercial(pValorPeriodo     tValorPeriodo,
                                          pAnoMesReferencia integer,
                                pFlIntegral boolean default false) return number is

    -- Variaveis relativas ao mes de referencia
      vDtInicioMesReferencia date := to_date(pAnoMesReferencia || '01','YYYYMMDD');
      vDtFimMesReferencia    date := last_day(to_date(pAnoMesReferencia || '01','YYYYMMDD'));
      vNuDiasMesReferencia   integer := vDtFimMesReferencia - vDtInicioMesReferencia + 1 ;

    -- Data de inicio de cada periodo a ser analisado
    vDtInicioPeriodo date;
    vDtFimPeriodo    date;

    -- Vetor de valores por dia do mes (do dia 1 ao dia 31)
    type tValorPorDia is varray(31) of number;
      vValorPorDia tValorPorDia := tValorPorDia(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

    -- Somatorio de valores no mes contidos no vetor vValorPorDia
    vSomaValor number := 0;

    -- Somatorio da quantidade de dias com media
    vQtdeDias number := 0;

  begin

    -- Percorre os periodos
      for i in pValorPeriodo.first .. pValorPeriodo.last
      loop

      -- Descarta periodos com datas invalidas
        if pValorPeriodo(i).dtInicio > pValorPeriodo(i).dtFim or
           pValorPeriodo(i).dtInicio > vDtFimMesReferencia then
        continue;
      end if;

      -- Ajusta data inicio e fim dos periodos para datas dentro do mes de referenicia
      vDtInicioPeriodo := pValorPeriodo(i).dtInicio;
      if pValorPeriodo(i).dtInicio < vDtInicioMesReferencia then
        vDtInicioPeriodo := vDtInicioMesReferencia;
      end if;

      vDtFimPeriodo := pValorPeriodo(i).dtFim;
        if pValorPeriodo(i).dtFim is null or pValorPeriodo(i).dtFim > vDtFimMesReferencia then
        vDtFimPeriodo := vDtFimMesReferencia;
      end if;

      -- Preenche vetor de dias com o valor do periodo dia a dia
        for dia in 1..31
        loop

        if dia >= extract(day from vDtInicioPeriodo) and
           dia <= extract(day from vDtFimPeriodo) then

          vValorPorDia(dia) := pValorPeriodo(i).nuValor;
          vQtdeDias := vQtdeDias + 1;

        end if;

          if pFlIntegral and
             i = pValorPeriodo.last and
           dia > extract(day from vDtFimPeriodo) then

          vValorPorDia(dia) := pValorPeriodo(i).nuValor;
          vQtdeDias := vQtdeDias + 1;

        end if;

      end loop;

    end loop;

    -- Em mes de 31 dias, descarta valor do dia 31
    -- se tem valor o mes todo
      if vQtdeDias = 31
        then
      vValorPorDia(31) := 0;
    end if;

    -- Em mes com menos de 30 dias (fevereiro),
    -- completa valores ate o dia 30
    if vNuDiasMesReferencia < 30 then

        for dia in vNuDiasMesReferencia+1..30
        loop
        vValorPorDia(dia) := vValorPorDia(vNuDiasMesReferencia);
      end loop;

    end if;

    -- Soma os valores do mes dia a dia, apos ajustes
      for dia in 1..31
      loop
      vSomaValor := vSomaValor + vValorPorDia(dia);
    end loop;

    -- Faz a media de valores por 30 dias
    return trunc(vSomaValor / 30, 4);

  end;

  function fVlPercPensao(pCdVinculoPensionista integer,
                         pAnoMesReferencia     integer,
                           pFlIntegral boolean default false) return number is

    vValorPeriodo tValorPeriodo;
    i             integer := 0;

  begin

    for pensao in cPensaoCota(pCdVinculoPensionista => pCdVinculoPensionista,
                                 pAnoMesReferencia => pAnoMesReferencia)
       loop

      -- BUSCAR NA TABELA EPVDHISTPENSAOCOTA.NUPERCENTUAL (QUANDO NAO TIVER VALOR NA COLUNA CDVALORREFERENCIA).
      -- CASO NAO ENCONTRE, RETORNA 0.
      if pensao.nupercentual is not null and
         pensao.cdvalorreferencia is null then

        i := i + 1;

        vValorPeriodo(i).dtInicio := pensao.dtinicio;
        vValorPeriodo(i).dtFim := pensao.dtfim;
        vValorPeriodo(i).nuValor := pensao.nupercentual;

      end if;

    end loop;

    return fMediaValorPeriodoMesComercial(pValorPeriodo     => vValorPeriodo,
                                          pAnoMesReferencia => pAnoMesReferencia,
                                          pFlIntegral       => pFlIntegral);

  exception
    when others then
      return 0;

  end fVlPercPensao;

    function fVlPercPensaoBase(pCdVinculoPensionista integer,
                             pAnoMesReferencia     INTEGER,
                             pFlIntegral           BOOLEAN DEFAULT FALSE) -- novo parametro  sig-7062
   RETURN NUMBER IS


    vVlPercPensaoBase number;
    vValorPeriodo     tValorPeriodo;
    i                 integer := 0;

  BEGIN

    if PKGPAG_VAR.VGFOLHA.CDORGAO = 33 AND -- sig 7062 -- complemenmto:sig-9045,9057
       (pkgpag_geral.fpossuiregistroobito(pkgpag_var.vCdPessoa,
                                          pkgpag_var.vgFolha.cdAgrupamento,
                                          'S')) or
       (pkgpag_var.vgVinculo.dtdesligamento < pkgpag_var.vgFolha.DtFimMes) -- AND       pFlIntegral
     THEN

      for pensao in cPensaoCota(pCdVinculoPensionista => pCdVinculoPensionista,
                                pAnoMesReferencia     => pAnoMesReferencia) loop

        -- BUSCAR NA TABELA EPVDHISTPENSAOCOTA.NUPERCENTUAL (QUANDO NAO TIVER VALOR NA COLUNA CDVALORREFERENCIA).
        -- CASO NAO ENCONTRE, RETORNA 0.
        if pensao.nupercentual is not null and
           pensao.cdvalorreferencia is null then

          i := i + 1;

          vValorPeriodo(i).dtInicio := pensao.dtinicio;
          vValorPeriodo(i).dtFim := pensao.dtfim;
          vValorPeriodo(i).nuValor := pensao.nupercentual;

        end if;

      end loop;

      vVlPercPensaoBase := vValorPeriodo(i).nuValor;
      RETURN vVlPercPensaoBase;
    END IF;

    vVlPercPensaoBase := fVlPercPensao(pCdVinculoPensionista => pCdVinculoPensionista,
                                       pAnoMesReferencia     => pAnoMesReferencia);

    -- Quando o mnemonico VlPercPensao retorna 0 (zero) o
    -- VlPercPensaoBase deve retornar 100.
    IF vVlPercPensaoBase = 0 THEN
      RETURN 100;
    ELSE
      RETURN vVlPercPensaoBase;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;

  END;

  function fVlPensaoPrev(pCdVinculoPensionista integer,
                         pAnoMesReferencia     integer,
                           pFlIntegral boolean default false) return number is

    vValorPeriodo tValorPeriodo;
    i             integer := 0;

  begin

    for pensao in cPensaoCota(pCdVinculoPensionista => pCdVinculoPensionista,
                                 pAnoMesReferencia => pAnoMesReferencia)
       loop

      i := i + 1;
      vValorPeriodo(i).dtInicio := pensao.dtinicio;
      vValorPeriodo(i).dtFim := pensao.dtfim;

      -- SE TIVER CDVALORREFERENCIA, CALCULAR VALOR
      if pensao.cdvalorreferencia is not null then

                for vr in cValorReferencia(
                          pAnoMesReferencia => pAnoMesReferencia,
                          pCdValorReferencia => pensao.cdvalorreferencia)
                loop

          if pensao.nupercentual is not null then
                      vValorPeriodo(i).nuValor := vr.vlreferencia*pensao.nupercentual/100;
          else
            vValorPeriodo(i).nuValor := vr.vlreferencia;
          end if;

        end loop;

        -- SE TIVER VLCOTA, E O PROPRIO
      elsif pensao.vlcota is not null then

        vValorPeriodo(i).nuValor := pensao.vlcota;

      else

        vValorPeriodo(i).nuValor := 0;

      end if;

    end loop;

    return fMediaValorPeriodoMesComercial(pValorPeriodo     => vValorPeriodo,
                                          pAnoMesReferencia => pAnoMesReferencia,
                                          pFlIntegral       => pFlIntegral);

  exception
    when others then
      return 0;

  end;

  -- PERCENTUAL REFERENTE A COTA DO PENSIONISTA.
  function fVlPercPensaoPrev(pCdVinculoPensionista integer,
                             pAnoMesReferencia     integer,
                             pCdTipoCalculo        integer) return number is

    vVlPercPensao       number := 0;
    vVlBaseLimitadoTeto number := 0;
    vVlPensaoPrev       number := 0;

  begin

    -- Busca percentual na tabela EPVDHISTPENSAOCOTA.NUPERCENTUAL
    vVlPercPensao := fVlPercPensao(pCdVinculoPensionista => pCdVinculoPensionista,
                                   pAnoMesReferencia     => pAnoMesReferencia);

    -- Se encontrou percentual fixo na tabela, retorna
    if vVlPercPensao > 0 then

      return vVlPercPensao;

      -- Se nao encontrou, calcula percentual do valor da pensao em relacao a base da pensao limitada ao teto.
    else

      vVlBaseLimitadoTeto := fVlBaseInstituidorLimitadoTeto(pCdVinculoPensionista => pCdVinculoPensionista,
                                                            pAnoMesReferencia     => pAnoMesReferencia,
                                                            pCdTipoCalculo        => pCdTipoCalculo);

      vVlPensaoPrev := fVlPensaoPrev(pCdVinculoPensionista => pCdVinculoPensionista,
                                     pAnoMesReferencia     => pAnoMesReferencia);

      return(vVlPensaoPrev / vVlBaseLimitadoTeto) * 100;

    end if;

    -- Se nao encontrou, retorna zero.
    return 0;

  exception
    when others then
      return 0;

  end;

  -- PERCENTUAL PROPORCIONAL DE INTEGRALIDADE DO VALOR DA SUA BASE PREVIDENCIARIA.
  function fVlPercIntegralidade(pCdVinculoPensionista integer,
                                  pAnoMesReferencia     integer)
      return number is

  begin

    -- busca vinculos do instituidor
       for instituidor in cInstituidorPensaoPrev(pCdVinculoPensionista)
       loop

      -- Busca percentual na tabela EPVDHISTPENSAOCOTA.NUPERCENTUAL
      for percentual in cBaseCalculoPensao(instituidor.cdvinculo,
                                           pAnoMesReferencia) loop

        -- Se encontrou percentual fixo na tabela, retorna
        if percentual.nupercentual > 0 then
          return percentual.nupercentual;

          -- Se nao encontrou, retorna cem.
        else
          return 100;

        end if;
      end loop;

    end loop;

    -- Se nao encontrou, retorna 100.
    return 100;

  exception
    when others then
      return 100;
  end;

    function fCdAgrupamentoInstituidor(pCdVinculoInstituidor integer) return integer is
    vCdAgrupamentoInstituidor integer;
  begin

          with vinculo as (
               select v.cdorgao
        from ecadvinculo v
               where v.cdvinculo = pCdVinculoInstituidor
          ),
          orgao as (
                select o.cdagrupamento
        from vcadorgao o
                inner join vinculo on vinculo.cdorgao = o.cdorgao
          )
          select orgao.cdagrupamento
          into   vCdAgrupamentoInstituidor
          from orgao;

    return vCdAgrupamentoInstituidor;

  end;

  function fCdOrgaoInstituidor(pCdVinculoInstituidor integer) return integer is
    vCdOrgaoInstituidor integer;
  begin

    select v.cdorgao
      into vCdOrgaoInstituidor
      from ecadvinculo v
     where v.cdvinculo = pCdVinculoInstituidor;

    return vCdOrgaoInstituidor;

  exception
    when others then
      return 0;

  end;

    function fCdOrgaoOrigemPensionista(pCdVinculoPensionista integer) return integer is

  begin

    -- busca vinculos do instituidor
       for instituidor in cInstituidorPensaoPrev(pCdVinculoPensionista)
       loop

      return fCdOrgaoInstituidor(instituidor.cdvinculo);

    end loop;

    -- se nao encontrou, retorna zero;
    return 0;

  exception
    when others then
      return 0;

  end;

  function fVlRubContrachequeInstituidor(pCdVinculoInstituidor integer,
                                         pAnoMesReferencia     integer,
                                         pCdTipoCalculo        integer,
                                         pCdtipoRubrica        integer,
                                    pNuRubrica integer) return number is

    vCdAgrupamento        integer;
    vCdRubricaAgrupamento integer;
    vVlpagamento          number := 0;

  begin

    vCdAgrupamento := fCdAgrupamentoInstituidor(pCdVinculoInstituidor);

    vCdRubricaAgrupamento := pkgpag_geral.fretornarubrica(pcdagrupamento => vCdAgrupamento,
                                                          pcdtiporubrica => pCdtipoRubrica,
                                                          pNuRubrica     => pNuRubrica);

    for contracheque in cContrachequeInstituidor(pCdVinculoInstituidor => pCdVinculoInstituidor,
                                                 pAnoMesReferencia     => pAnoMesReferencia,
                                                     pCdTipoCalculo => pCdTipoCalculo)
        loop

      if contracheque.cdrubricaagrupamento = vCdRubricaAgrupamento then
        vVlpagamento := vVlpagamento + contracheque.vlpagamento;
      end if;

    end loop;

    return vVlpagamento;

  exception
    when others then
      return 0;

  end fVlRubContrachequeInstituidor;

  function fVerificaAbrangenciaPensaoPrev(pCdVinculoPensionista integer,
                                          pCdRubricaAgrupamento integer,
                                            pDataReferencia date) return boolean is
  begin

    for pensao in cPensaoCota(pCdVinculoPensionista => pCdVinculoPensionista,
                                  pAnoMesReferencia => to_number(to_char(pDataReferencia,'YYYYMM')))
        loop

      if pensao.cdRubricaAgrupamento = pCdRubricaAgrupamento then
        return true;
      end if;

    end loop;

    return false;

  end fVerificaAbrangenciaPensaoPrev;

end PKGPAG_PENSAOPREVIDENCIARIA;
/
